Rem
	====================================================================
	NewsEvent data - basic of broadcastable news
	====================================================================
EndRem
SuperStrict
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.math.bmx"
Import "Dig/base.util.scriptexpression.bmx"
'for TBroadcastSequence
Import "game.broadcast.base.bmx"
Import "game.broadcastmaterialsource.base.bmx"
Import "game.gameconstants.bmx"
Import "game.world.worldtime.bmx"
Import "game.player.base.bmx"

Import "game.programme.newsevent.template.bmx"



Type TNewsEventCollection
	'contains news just happened
	Field newsEventsHistory:TNewsEvent[]
	Field newsEventsHistoryIndex:int=0
	'holding all currently happening/upcoming news events
	'ID->object
	Field newsEvents:TIntMap = new TIntMap
	'GUID->object
	Field newsEventsGUID:TMap = new TMap

	'holding a number of "sethappened"-newsevents (for ordering)
	Field nextNewsNumber:Long = 0


	'factor by what a newsevents topicality DECREASES by sending it
	'(with whole audience, so 100%, watching)
	'a value > 1.0 means, it decreases to 0 with less than 100% watching
	'ex.: 0.9 = 10% cut, 0.85 = 15% cut
	Field wearoffFactor:float = 0.25
	'=== CACHE ===
	'cache for faster access

	'holding news coming in a defined future
	Field _upcomingNewsEvents:TList[] {nosave}
	'holding all (initial) news events available to "happen"
	Field _availableNewsEvents:TList[] {nosave}
	Field _followingNewsEvents:TList[] {nosave}
	Global _instance:TNewsEventCollection


	Function GetInstance:TNewsEventCollection()
		if not _instance
			_instance = new TNewsEventCollection
			'create arrays
			_instance._InvalidateCaches()
		endif
		return _instance
	End Function


	Method Initialize:TNewsEventCollection()
		newsEventsHistory = new TNewsEvent[0]
		newsEventsHistoryIndex = 0

		newsEvents.Clear()
		newsEventsGUID.Clear()
		_InvalidateCaches()

		nextNewsNumber = 0

		return self
	End Method


	Method _InvalidateCaches()
		_InvalidateUpcomingNewsEvents()
		_InvalidateAvailableNewsEvents()
		_InvalidateFollowingNewsEvents()
	End Method


	Method _InvalidateAvailableNewsEvents()
		_availableNewsEvents = New TList[TVTNewsGenre.count + 1]
	End Method


	Method _InvalidateFollowingNewsEvents()
		_followingNewsEvents = New TList[TVTNewsGenre.count + 1]
	End Method


	Method _InvalidateUpcomingNewsEvents()
		_upcomingNewsEvents = New TList[TVTNewsGenre.count + 1]
	End Method


	Method Add:int(obj:TNewsEvent)
		'add to common maps
		'special lists get filled when using their Getters
		newsEventsGUID.Insert(obj.GetGUID().ToLower(), obj)
		newsEvents.Insert(obj.GetID(), obj)

		_InvalidateCaches()

		return TRUE
	End Method


	Method AddOneTimeEvent:int(obj:TNewsEvent)
		obj.Setflag(TVTNewsFlag.UNIQUE_EVENT, True)
		obj.Setflag(TVTNewsFlag.UNSKIPPABLE, True)
		Add(obj)
	End Method


	Method AddHappenedEvent:int(obj:TNewsEvent)
		'max 100 entries
		if newsEventsHistory.length > 100
			newsEventsHistory = newsEventsHistory[50 ..]
		endif
		'resize if needed
		if newsEventsHistory.length < newsEventsHistoryIndex+1
			newsEventsHistory = newsEventsHistory[.. newsEventsHistoryIndex + 10]
		endif

		newsEventsHistory[newsEventsHistoryIndex] = obj

		newsEventsHistoryIndex :+ 1
	End Method



	Method Remove:int(obj:TNewsEvent)
		newsEventsGUID.Remove(obj.GetGUID().ToLower())
		newsEvents.Remove(obj.GetID())

		_InvalidateCaches()

		return TRUE
	End Method


	Method GetByID:TNewsEvent(ID:int)
		Return TNewsEvent(newsEvents.ValueForKey(ID))
	End Method


	Method GetByGUID:TNewsEvent(GUID:String)
		Return TNewsEvent(newsEventsGUID.ValueForKey( GUID.ToLower() ))
	End Method


	Global nilNode:TNode = New TNode._parent
	Method SearchByPartialGUID:TNewsEvent(GUID:String)
		'skip searching if there is nothing to search
		if GUID.trim() = "" then return Null

		GUID = GUID.ToLower()

		'find first hit
		Local node:TNode = newsEventsGUID._FirstNode()
		While node And node <> nilNode
			if string(node._key).Find(GUID) >= 0
				return TNewsEvent(node._value)
			endif

			'move on to next node
			node = node.NextNode()
		Wend

		return Null
	End Method


	Method RemoveOutdatedNewsEvents(minAgeInDays:int=5, genre:int=-1)
		local somethingDeleted:int = False
		local toRemove:TNewsEvent[]

		For local newsEvent:TNewsEvent = eachin newsEvents.Values()
			'not happened yet - should not happen
			if not newsEvent.HasHappened() then continue
			'only interested in a specific genre?
			if genre <> -1 and newsEvent.GetGenre() <> genre then continue

			if abs(GetWorldTime().GetDay(newsEvent.happenedTime) - GetWorldTime().GetDay()) >= minAgeInDays
				toRemove :+ [newsEvent]

				somethingDeleted = true
			endif
		Next

		'delete/modify in an extra step - this approach skips creation
		'of a map-copy just to avoid concurrent modification
		For local n:TNewsEvent = Eachin toRemove
			Remove(n)
		Next

		'reset caches, so lists get filled correctly
		if somethingDeleted then _InvalidateCaches()
	End Method


	'remove news events which no longer "happen" (eg. thunderstorm warnings)
	Method RemoveEndedNewsEvents(genre:int=-1)
		local somethingDeleted:int = False
		local toRemove:TNewsEvent[]

		For local newsEvent:TNewsEvent = eachin newsEvents.Values()
			'only interested in a specific genre?
			if genre <> -1 and newsEvent.GetGenre() <> genre then continue

			if newsEvent.HasHappened() and newsEvent.HasEnded()
				toRemove :+ [newsEvent]

				somethingDeleted = true
			endif
		Next

		'delete/modify in an extra step - this approach skips creation
		'of a map-copy just to avoid concurrent modification
		For local n:TNewsEvent = Eachin toRemove
			Remove(n)
		Next


		'reset caches, so lists get filled correctly
		if somethingDeleted then _InvalidateCaches()
	End Method


	Method CreateRandomAvailable:TNewsEvent(genre:int=-1)
		local template:TNewsEventTemplate = GetNewsEventTemplateCollection().GetRandomUnusedAvailableInitial(genre)
		if not template then return Null

		return new TNewsEvent.InitFromTemplate(template)
	End Method


	Method GetNewsHistory:TNewsEvent[](limit:int=-1)
		if limit = -1
			return newsEventsHistory[.. newsEventsHistoryIndex]
		else
			return newsEventsHistory[Max(0,newsEventsHistoryIndex-limit) .. newsEventsHistoryIndex]
		endif
	End Method


	'returns (and creates if needed) a list containing only follow up news
	Method GetFollowingNewsList:TList(genre:int=-1)
		'create if missing
		if not _followingNewsEvents then _InvalidateFollowingNewsEvents()

		if not _followingNewsEvents[genre+1]
			_followingNewsEvents[genre+1] = CreateList()
			For local event:TNewsEvent = EachIn newsEvents.Values()
				if event.newsType <> TVTNewsType.FollowingNews then continue
				'only interested in a specific genre?
				if genre <> -1 and event.GetGenre() <> genre then continue

				_followingNewsEvents[genre+1].AddLast(event)
			Next
		endif
		return _followingNewsEvents[genre+1]
	End Method


	'returns (and creates if needed) a list containing only initial news
	Method GetUpcomingNewsList:TList(genre:int=-1)
		'create if missing
		if not _upcomingNewsEvents then _InvalidateUpcomingNewsEvents()

		if not _upcomingNewsEvents[genre+1]
			_upcomingNewsEvents[genre+1] = CreateList()
			For local event:TNewsEvent = EachIn newsEvents.Values()
				'skip events already happened or not happened at all (-> "-1")
				if event.HasHappened() or event.happenedTime = -1 then continue
				'only interested in a specific genre?
				if genre <> -1 and event.GetGenre() <> genre then continue

				_upcomingNewsEvents[genre+1].AddLast(event)
			Next
		endif
		return _upcomingNewsEvents[genre+1]
	End Method


	Method setNewsHappened(news:TNewsEvent, time:Double = 0)
		'nothing set - use "now"
		if time = 0 then time = GetWorldTime().GetTimeGone()

		if news.happenedTime <> time
			news.newsNumber = nextNewsNumber
			nextNewsNumber :+ 1

			news.happenedTime = time

			'add to the "happened" list
			if news.HasHappened()
				AddHappenedEvent(news)

				'remove from managed ones
				Remove(news)
			endif
		endif

		'reset only specific caches, so news gets in the correct list
		'- no need to invalidate newstype-specific caches
		_InvalidateUpcomingNewsEvents()
		_InvalidateAvailableNewsEvents()
	End Method


	Method GetGenreWearoffModifier:float(genre:int)
		'values get multiplied with the wearOff factor
		'so this means: higher (>1.0) values increase the resulting
		'topicality loss
		Select genre
			case TVTNewsGenre.POLITICS_ECONOMY
				return 1.05
			case TVTNewsGenre.SHOWBIZ
				return 0.9
			case TVTNewsGenre.SPORT
				return 1.0
			case TVTNewsGenre.TECHNICS_MEDIA
				return 1.05
			case TVTNewsGenre.CURRENTAFFAIRS
				return 1.0
			case TVTNewsGenre.CULTURE
				return 1.0
			default
				return 1.0
		End Select
	End Method


	Function SortByHappenedTime:int(o1:object, o2:object)
		local n1:TNewsEvent = TNewsEvent(o1)
		local n2:TNewsEvent = TNewsEvent(o2)
		if not n2 then return 1
		if not n1 then return -1

		if n1.happenedTime > n2.happenedTime then return 1
		if n1.happenedTime < n2.happenedTime then return -1
		return 0
	End Function



	Function SortByNewsNumber:int(o1:object, o2:object)
		local n1:TNewsEvent = TNewsEvent(o1)
		local n2:TNewsEvent = TNewsEvent(o2)
		if not n2 then return 1
		if not n1 then return -1

		if n1.newsNumber > n2.newsNumber then return 1
		if n1.newsNumber < n2.newsNumber then return -1
		'fall back to happened time
		return SortByHappenedTime(o1, o2)
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetNewsEventCollection:TNewsEventCollection()
	Return TNewsEventCollection.GetInstance()
End Function



Type TNewsEvent extends TBroadcastMaterialSource {_exposeToLua="selected"}
	Field template:TNewsEventTemplate

	'time when something happened or will happen. "-1" = not happened
	Field happenedTime:Long = -1
	'number of the news since begin of game (for potential ordering)
	Field newsNumber:Long = 0
	'time when a news gets invalid (eg. thunderstorm warning)
	Field eventDuration:Int = -1

	'fine grained attractivity for target groups (splitted gender)
	Field targetGroupAttractivityMod:TAudience = null

	'used when not -1 or no template is used
	'type of the news event according to TVTNewsType
	Field genre:int = -1
	Field quality:Float = -1
	Field qualityRaw:Float = -1
	Field newsType:int = -1
	Field minSubscriptionLevel:int = -1
	Field keywords:string = ""
	Field availableYearRangeFrom:int = -1
	Field availableYearRangeTo:int = -1
	'special expression defining whether a contract is available for
	'ad vendor or not (eg. "YEAR > 2000" or "YEARSPLAYED > 2")
	Field availableScript:string = ""


	Field _genreDefinitionCache:TNewsGenreDefinition {nosave}


	Method GenerateGUID:string()
		return "broadcastmaterialsource-newsevent-"+id
	End Method


	Method Init:TNewsEvent(GUID:string, title:TLocalizedString, description:TLocalizedString, Genre:Int, quality:Float=-1, modifiers:TData=null, newsType:int=0)
		self.SetGUID(GUID)
		self.title       = title
		self.description = description
		self.genre       = Genre
		self.topicality  = 1.0
		if quality >= 0 then SetQualityRaw(quality)
		self.newsType	 = newsType
		'modificators: > 1.0 increases price (1.0 = 100%)
		if modifiers then self.modifiers = modifiers.Copy()

		Return self
	End Method


	Method InitFromTemplate:TNewsEvent(template:TNewsEventTemplate)
		'reset template (random data like template variables)
		if template then template.ResetRandomData()

		self.template = template
		self.SetGUID( template.GetGUID()+"-instance"+(template.timesUsed+1))

		'mark the template (and increase usage count)
		template.SetUsed(self.GetGUID())


		'copy text if we intend to replace content
		'(for now only check main language)
		if template.title.Get().Find("%") >= 0
			if template.templateVariables
				self.title = _ReplacePlaceholders( template.templateVariables.ReplacePlaceholders(template.title) )
			else
				self.title = _ReplacePlaceholders(template.title)
			endif
		else
			self.title = template.title
		endif
		if template.description.Get().Find("%") >= 0
			if template.templateVariables
				self.description = _ReplacePlaceholders( template.templateVariables.ReplacePlaceholders(template.description) )
			else
				self.description = _ReplacePlaceholders(template.description)
			endif
		else
			self.description = template.description
		endif

		self.happenedTime = template.happenTime
		if template.targetGroupAttractivityMod
			self.targetGroupAttractivityMod = template.targetGroupAttractivityMod.copy()
		endif

		self.topicality = template.topicality
		self.SetQualityRaw( template.quality )
		self.newsType = template.newsType

		self.flags = template.flags

		self.modifiers = template.CopyModifiers()
		self.effects = template.CopyEffects()

		return self
	End Method


	Method SetTitle(title:TLocalizedString)
		self.title = title
	End Method


	Method SetDescription(description:TLocalizedString)
		self.description = description
	End Method


	Method ToString:String()
		return "newsEvent: title=" + GetTitle() + "  quality=" + GetQualityRaw() + "  priceMod=" + GetModifier("price")
	End Method


	Method GetMinSubscriptionLevel:int()
		if minSubscriptionLevel = -1 and template then return template.minSubscriptionLevel
		return Max(0, minSubscriptionLevel)
	End Method


	Method AddKeyword:int(keyword:string)
		if HasKeyword(keyword, True) then return False

		if keywords then keywords :+ ","
		keywords :+ keyword.ToLower()
		Return True
	End Method


	Method HasKeyword:int(keyword:string, exactMode:int = False)
		if not keyword or keyword="," then return False

		if exactMode
			return (keywords+",").Find(( keyword+",").ToLower() ) >= 0
		else
			return keywords.Find(keyword.ToLower()) >= 0
		endif
	End Method



	Method IsAvailable:int()
		if template and not template.IsAvailable() then return False

		'field "available" = false ?
		if not super.IsAvailable() then return False

		if availableYearRangeFrom > 0 and GetWorldTime().GetYear() < availableYearRangeFrom then return False
		if availableYearRangeTo > 0 and GetWorldTime().GetYear() > availableYearRangeTo then return False

		'a special script expression defines custom rules for adcontracts
		'to be available or not
		if availableScript and not GetScriptExpression().Eval(availableScript)
			return False
		endif

		return True
	End Method


	Method SetQualityRaw:Int(quality:Float)
		'clamp between 0-1.0
		self.qualityRaw = MathHelper.Clamp(quality, 0.0, 1.0)
	End Method


	Function GetGenreString:String(Genre:Int)
		return GetLocale("NEWS_"+ TVTNewsGenre.GetasString(Genre).toUpper())
	End Function


	'override
	Method GetMaxTopicality:Float()
		local maxTopicality:Float = 1.0

		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG", new TData))
		Local devAgeMod:float = devConfig.GetFloat("DEV_NEWS_AGE_INFLUENCE", 1.0)
		Local devQualityAgeMod:float = devConfig.GetFloat("DEV_NEWS_QUALITYAGE_INFLUENCE", 1.0)
		Local devBroadcastedMod:float = devConfig.GetFloat("DEV_NEWS_BROADCAST_INFLUENCE", 1.0)

		'age influence
		local qualityAgeMod:Float = 0.8 * devQualityAgeMod

		'the older the less ppl want to watch - 1hr = 0.98%, 2hr = 0.96%...
		'means: after ~50 hrs, the topicality is 0
		local ageHours:int = floor( float(GetWorldTime().GetTimeGone() - self.happenedTime)/3600.0 )
		Local ageInfluence:Float = 1.0 - 0.01 * Max(0, 100 - 2 * Max(0, ageHours) )
		ageInfluence :* GetModifier("topicality::age")
		'the lower the quality of an newsevent, the higher the age influences
		'the max topicality, up to 80% is possible
		ageInfluence = (1.0-qualityAgeMod) * ageInfluence + ageInfluence*qualityAgeMod * (1 - GetQualityRaw())
		'print GetTitle() + "  " +agehours +"  influence="+ageInfluence +"   devAgeMod="+devageMod +"   qualityAgeMod="+qualityAgeMod +"  qualityRaw="+GetQualityRaw()

		'the first 12 broadcasts do decrease maxTopicality
		Local timesBroadcastedInfluence:Float = 0.02 * Min(12, GetTimesBroadcasted() )
		timesBroadcastedInfluence :* GetModifier("topicality::timesBroadcasted")

		'subtract various influences (with individual weights)
		maxTopicality :- ageInfluence * devAgeMod
		maxTopicality :- timesBroadcastedInfluence * devBroadcastedMod

		return MathHelper.Clamp(maxTopicality, 0.0, 1.0)
	End Method


	Method GetTargetGroupAttractivityMod:TAudience()
		return targetGroupAttractivityMod
	End Method


	Method HasHappened:Int()
		'avoid that "-1" (the default for "unset") is fetched in the
		'next check ("time gone?")
		If happenedTime = -1 Then Return False
		'check if the time is gone already
		If happenedTime > GetWorldTime().GetTimeGone() Then Return False

		return True
	End Method


	Method HasEnded:Int()
		'can only end if already happened
		if not HasHappened() then return False

		'avoid that "-1" (the default for "unset") is fetched in the
		'next check ("time gone?")
		'a "-1"-duration never ends
		If eventDuration < 0 Then Return False

		'check if the time is gone already
		If happenedTime + eventDuration > GetWorldTime().GetTimeGone() Then Return False

		return True
	End Method


	'ATTENTION:
	'to emit an artificial news, use GetNewsAgency().announceNewsEvent()
	Method doHappen(time:Double = 0)
		'set happened time, add to collection list...
		GetNewsEventCollection().setNewsHappened(self, time)

		if time = 0 or time <= GetWorldTime().GetTimeGone()

			'set topicality to 100%
			topicality = 1.0

			if keywords.Find("movie") >= 0 then debugstop

			'trigger happenEffects
			local effectParams:TData = new TData.Add("source", self)
			effects.Update("happen", effectParams)
		endif
	End Method


	'override
	'call this as soon as a news containing this newsEvent is
	'broadcasted. If playerID = -1 then this effects might target
	'"all players" (depends on implementation)
	Method doBeginBroadcast(playerID:int = -1, broadcastType:int = 0)
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("source", self).AddNumber("playerID", playerID)

		'if nobody broadcasted till now (times are adjusted on
		'finishBroadcast while this is called on beginBroadcast)
		if GetTimesBroadcasted() = 0
			If not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME)
				effects.Update("broadcastFirstTime", effectParams)
				setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME, True)
			endif
		endif

		effects.Update("broadcast", effectParams)
	End Method


	'override
	Method doFinishBroadcast(playerID:int = -1, broadcastType:int = 0)
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("source", self).AddNumber("playerID", playerID)

		'if nobody broadcasted till now (times are adjusted on
		'finishBroadcast while this is called on beginBroadcast)
		if GetTimesBroadcasted() = 0
			If not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE)
				effects.Update("broadcastFirstTimeDone", effectParams)
				setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE, True)
			endif
		endif

		effects.Update("broadcastDone", effectParams)
	End Method


	Method CutTopicality:Float(cutModifier:float=1.0) {_private}
		'cutModifier can be used to manipulate the resulting cut
		'ex. for night times, for low audience...

		'for the calculation we need to know what to cut, not what to keep
		local toCut:Float =  (1.0 - cutModifier)
		local minimumRelativeCut:Float = 0.02 '2%
		local minimumAbsoluteCut:Float = 0.02 '2%

		'calculate base value (if mod was "1.0" or 100%)
		toCut :* GetNewsEventCollection().wearoffFactor

		'cutModifier can be used to manipulate the resulting cut
		'ex. for night times, for low audience...
		toCut :* GetWearoffModifier()

		toCut = Max(toCut, minimumRelativeCut)

		'take care of minimumCut and switch back to "what to cut"
		cutModifier = 1.0 - MathHelper.Clamp(toCut, minimumAbsoluteCut, 1.0)

		topicality = MathHelper.Clamp(topicality * cutModifier, 0.0, 1.0)

		Return topicality
	End Method


	Method GetGenreWearoffModifier:float(genre:int=-1)
		if genre = -1 then genre = self.GetGenre()
		return GetNewsEventCollection().GetGenreWearoffModifier(genre)
	End Method


	Method GetWearoffModifier:float()
		return GetModifier("topicality::wearoff")
	End Method


	Method IsSkippable:int()
		'cannot skip events with "happen"-effects
		return not HasFlag(TVTNewsFlag.UNSKIPPABLE) and (not effects.GetList("happen") or effects.GetList("happen").count() = 0)
	End Method


	Method IsReuseable:int()
		return not HasFlag(TVTNewsFlag.UNIQUE_EVENT)
	End Method


	Method GetGenre:int()
		'return default it not overridden
		if template and genre = -1 then return template.genre
		return genre
	End Method


	'AI/LUA-helper
	'while "GetPrice()" could change, this function should have some kind
	'of "nearly linear" connection to the really used quality
	Method GetAttractiveness:Float() {_exposeToLua}
		'the AI only sees something like the "price" and not the real
		'quality - this is what the player is able to see too

		'with a higher priceMod price increases while quality stays
		'the same -> less quality for your money
		return GetQuality() / Max(0.001, GetModifier("price"))
	End Method


	Method GetGenreDefinition:TNewsGenreDefinition()
		If Not _genreDefinitionCache
			local g:int = GetGenre()
			_genreDefinitionCache = GetNewsGenreDefinitionCollection().Get( g )

			If Not _genreDefinitionCache
				TLogger.Log("GetGenreDefinition()", "NewsEvent ~q"+GetTitle()+"~q: Genre #"+g+" misses a genreDefinition. Creating BASIC definition-", LOG_ERROR)
				_genreDefinitionCache = new TNewsGenreDefinition.InitBasic(g, null)
			EndIf
		EndIf
		Return _genreDefinitionCache
	End Method


	Method GetQualityRaw:Float() {_exposeToLua}
		'already calculated?
		if qualityRaw >= 0 then return qualityRaw

		'create a random quality
		qualityRaw = (Float(RandRange(1, 100)) / 100.0) '1%-Punkte bis 3%-Punkte Basis-Qualität

		return qualityRaw
	End Method


	'contains age/topicality decrease
	Method GetQuality:Float() {_exposeToLua}

		'the more the news got repeated, the lower the quality in
		'that moment (^2 increases loss per air)
		'but a "good news" should benefit from being good - so the
		'influence of repetitions gets lower by higher raw quality
		'-> a news with 100% base quality will have at least 5% of
		'   quality no matter how many times it got aired
		'-> a news with 0% base quality will cut to up to 95% of that
		'   resulting in <= 5% quality
'		Local quality:Float = 0.05 * GetQualityRaw() + 0.95 * GetQualityRaw() * GetTopicality() ^ 2

		'topicality also includes "topicality loss" by lower-quality events
		Local quality:Float = GetQualityRaw() * (0.75 * GetTopicality() + 0.25 * GetTopicality() ^ 2)

		Return Max(0, quality)
	End Method


	'returns price based on a "per 5 million" approach
	Method GetPrice:Int() {_exposeToLua}
		'price ranges from 100 to ~7500
		Return Max(100, 7500 * GetQuality() * GetModifier("price") )
	End Method
End Type





Type TGameModifierNews_TriggerNews extends TGameModifierBase
	Field triggerNewsGUID:string
	Field happenTimeType:int = 1
	Field happenTimeData:int[] = [8,16,0,0]
	'% chance to trigger the news when "RunFunc()" is called
	Field triggerProbability:Int = 100


	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierNews_TriggerNews()
		return new TGameModifierNews_TriggerNews
	End Function


	Method Copy:TGameModifierNews_TriggerNews()
		local clone:TGameModifierNews_TriggerNews = new TGameModifierNews_TriggerNews
		clone.CopyBaseFrom(self)
		clone.triggerNewsGUID = self.triggerNewsGUID
		clone.happenTimeType = self.happenTimeType
		for local i:int = 0 until happenTimeData.length
			clone.happenTimedata[i] = self.happenTimeData[i]
		Next
		clone.triggerProbability = self.triggerProbability

		return clone
	End Method


	Method Init:TGameModifierNews_TriggerNews(data:TData, extra:TData=null)
		if not data then return null

		'local source:TNewsEvent = TNewsEvent(data.get("source"))
		local index:string = ""
		if extra and extra.GetInt("childIndex") > 0 then index = extra.GetInt("childIndex")
		local triggerNewsGUID:string = data.GetString("news"+index, data.GetString("news", ""))
		if triggerNewsGUID = "" then return Null

		local happenTimeString:string = data.GetString("time"+index, data.GetString("time", ""))
		local happenTime:int[]
		if happenTimeString <> ""
			happenTime = StringHelper.StringToIntArray(happenTimeString, ",")
		else
			happenTime = [1, 8,16,0,0]
		endif
		local triggerProbability:int = data.GetInt("probability"+index, 100)

		local obj:TGameModifierNews_TriggerNews = new TGameModifierNews_TriggerNews
		obj.triggerNewsGUID = triggerNewsGUID
		obj.triggerProbability = triggerProbability


		if happenTime.length > 0 and happenTime[0] <> -1
			obj.happenTimeType = happenTime[0]
			obj.happenTimeData = [-1,-1,-1,-1]
			for local i:int = 1 until happenTime.length
				obj.happenTimeData[i-1] = happenTime[i]
			Next
		endif

		return obj
	End Method


	Method ToString:string()
		local name:string = "default"
		if data then name = data.GetString("name", name)

		return "TGameModifier_TriggerNews ("+name+")"
	End Method



	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		'skip if probability is missed
		if triggerProbability <> 100 and RandRange(0, 100) > triggerProbability then return False

		local news:TNewsEvent

		'instead of triggering the news DIRECTLY, we check first if we
		'are talking about a template...
		local template:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByGUID(triggerNewsGUID)
		if template
			if template.IsAvailable()
				news = new TNewsEvent.InitFromTemplate(template)
				if news
					GetNewsEventCollection().Add(news)
				endif
			else
				TLogger.Log("TGameModifierNews_TriggerNews", "news template to trigger not available (yet): "+triggerNewsGUID, LOG_DEBUG)
				return false
			endif
		else
			news = GetNewsEventCollection().GetByGUID(triggerNewsGUID)
		endif

		if not news
			TLogger.Log("TGameModifierNews_TriggerNews", "cannot find news to trigger: "+triggerNewsGUID, LOG_ERROR)
			return false
		endif
		if not news.IsAvailable()
			TLogger.Log("TGameModifierNews_TriggerNews", "news to trigger not available (yet): "+triggerNewsGUID, LOG_ERROR)
			return false
		endif
		local triggerTime:Long = GetWorldTime().CalcTime_Auto(happenTimeType, happenTimeData)
		GetNewsEventCollection().setNewsHappened(news, triggerTime)

		return True
	End Method
End Type




'grouping various news triggers and triggering "all" or "one"
'of them
Type TGameModifierNews_TriggerNewsChoice extends TGameModifierChoice
	'% chance to trigger the news when "RunFunc()" is called
	Field triggerProbability:Int = 100


	Method Copy:TGameModifierNews_TriggerNewsChoice()
		local clone:TGameModifierNews_TriggerNewsChoice = new TGameModifierNews_TriggerNewsChoice
		clone.CopyFromChoice(self)

		clone.triggerProbability = self.triggerProbability

		return clone
	End Method


	'override
	Method ToString:string()
		local name:string = "default"
		if data then name = data.GetString("name", name)

		return "TGameModifier_TriggerNewsChoice ("+name+")"
	End Method


	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierNews_TriggerNewsChoice()
		return new TGameModifierNews_TriggerNewsChoice
	End Function


	'override to create this type instead of the generic one
	Function CreateNewChoiceInstance:TGameModifierNews_TriggerNews()
		return new TGameModifierNews_TriggerNews
	End Function


	'override to care for triggerProbability
	Method Init:TGameModifierNews_TriggerNewsChoice(data:TData, extra:TData=null)
		Super.Init(data, extra)


		'load defaults
		local template:TGameModifierNews_TriggerNews = new TGameModifierNews_TriggerNews.Init(data, null)
		if not template then template = new TGameModifierNews_TriggerNews

		triggerProbability = template.triggerProbability
		'correct individual probability of the loaded choices
		for local i:int = 0 until modifiers.length
			local triggerModifier:TGameModifierNews_TriggerNews = TGameModifierNews_TriggerNews(modifiers[i])
			if not triggerModifier then continue

			modifiersProbability[i] = triggerModifier.triggerProbability
			'reset individual probability to 100%
			triggerModifier.triggerProbability = 100
		Next

		return self
	End Method


	'override to trigger a specific news only if general probability
	'was met
	Method RunFunc:int(params:TData)
		'skip if probability is missed
		if triggerProbability <> 100 and RandRange(0, 100) > triggerProbability then return False

		return Super.RunFunc(params)
	End Method
End Type




Type TGameModifierNews_ModifyAvailability extends TGameModifierBase
	Field newsGUID:string
	Field enableBackup:int = True
	Field enable:int = True


	Function CreateNewInstance:TGameModifierNews_ModifyAvailability()
		return new TGameModifierNews_ModifyAvailability
	End Function


	Method Copy:TGameModifierNews_ModifyAvailability()
		local clone:TGameModifierNews_ModifyAvailability = new TGameModifierNews_ModifyAvailability
		clone.CopyBaseFrom(self)
		clone.newsGUID = self.newsGUID
		clone.enableBackup = self.enableBackup
		clone.enable = self.enable
		return clone
	End Method


	Method Init:TGameModifierNews_ModifyAvailability(data:TData, extra:TData=null)
		if not data then return null

		newsGUID = data.GetString("news", "")
		enable = data.GetBool("enable", True)

		return self
	End Method


	'override
	Method UndoFunc:int(params:TData)
		local newsEvent:TNewsEvent = TNewsEvent(GetNewsEventCollection().GetByGUID( newsGUID ))
		if not newsEvent
			print "TGameModifierNews_ModifyAvailability: Undo failed, newsEvent ~q"+newsGUID+"~q not found."
		endif

		if enableBackup then newsEvent.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, False)
	End Method


	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		local newsEvent:TNewsEvent = TNewsEvent(GetNewsEventCollection().GetByGUID( newsGUID ))
		if not newsEvent
			print "TGameModifierNews_ModifyAvailability: Run failed, newsEvent ~q"+newsGUID+"~q not found."
		endif

		'available?
		enableBackup = not newsEvent.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE)

		newsEvent.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, not enable)
	End Method
End Type



Type TGameModifierNews_Attribute extends TGameModifierBase
	Field newsGUID:string
	Field attribute:string
	Field value:string
	Field valueBackup:string = ""


	Function CreateNewInstance:TGameModifierNews_Attribute()
		return new TGameModifierNews_Attribute
	End Function


	Method Copy:TGameModifierNews_Attribute()
		local clone:TGameModifierNews_Attribute = new TGameModifierNews_Attribute
		clone.CopyBaseFrom(self)
		clone.newsGUID = self.newsGUID
		clone.attribute = self.attribute
		clone.value = self.value
		clone.valueBackup = self.valueBackup
		return clone
	End Method


	Method Init:TGameModifierNews_Attribute(data:TData, extra:TData=null)
		if not data then return null

		newsGUID = data.GetString("news", "")
		attribute = data.GetString("attribute").ToLower()
		value = data.GetString("value")

		return self
	End Method


	Method ReadNewsEventValue:string()
		local newsEvent:TNewsEvent = GetNewsEvent()
		if not newsEvent then return False

		Select attribute
			case "topicality"
				return string( newsEvent.GetTopicality() )
			case "quality"
				return string( newsEvent.GetQualityRaw() )
			default
				print "TGameModifierNews_Attribute: Trying to read unhandled property ~q"+attribute+"~q."
				return ""
		End Select
	End Method


	Method WriteNewsEventValue:int(v:string)
		local newsEvent:TNewsEvent = GetNewsEvent()
		if not newsEvent then return False

		Select attribute
			case "topicality"
				newsEvent.SetTopicality( float(v) )
			case "quality"
				newsEvent.SetQualityRaw( float(v) )
			default
				print "TGameModifierNews_Attribute: Trying to set unhandled property ~q"+attribute+"~q."
				return False
		End Select

		return True
	End Method


	Method GetNewsEvent:TNewsEvent()
		local newsEvent:TNewsEvent = TNewsEvent(GetNewsEventCollection().GetByGUID( newsGUID ))
		if not newsEvent
			print "TGameModifierNews_Attribute: Failed to find newsEvent ~q"+newsGUID+"~q."
		endif
		return newsEvent
	End Method


	'override
	Method UndoFunc:int(params:TData)
		local newsEvent:TNewsEvent = GetNewsEvent()
		if not newsEvent then return False

		WriteNewsEventValue(valueBackup)

		return True
	End Method


	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		local newsEvent:TNewsEvent = GetNewsEvent()
		if not newsEvent then return False

		valueBackup = ReadNewsEventValue()
		WriteNewsEventValue(value)

		return True
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("TriggerNews", TGameModifierNews_TriggerNews.CreateNewInstance)
GetGameModifierManager().RegisterCreateFunction("TriggerNewsChoice", TGameModifierNews_TriggerNewsChoice.CreateNewInstance)
GetGameModifierManager().RegisterCreateFunction("ModifyNewsAvailability", TGameModifierNews_ModifyAvailability.CreateNewInstance)
