Rem
	====================================================================
	NewsEvent data - basic of broadcastable news
	====================================================================
EndRem
SuperStrict
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.math.bmx"
'for TBroadcastSequence
Import "game.broadcast.base.bmx"
Import "game.broadcastmaterialsource.base.bmx"
Import "game.gameconstants.bmx"
Import "game.world.worldtime.bmx"
Import "game.player.base.bmx"

Import "game.programme.newsevent.template.bmx"
Import "game.gamescriptexpression.base.bmx"



Type TNewsEventCollection
	'contains news just happened
	Field newsEventsHistory:TNewsEvent[]
	Field newsEventsHistoryIndex:Int=0
	'holding all currently happening/upcoming news events
	'ID->object
	Field newsEvents:TIntMap = New TIntMap
	'GUID->object
	Field newsEventsGUID:TMap = New TMap
	'holding all ever added news events
	'ID->object
	Field allNewsEvents:TIntMap = New TIntMap
	'GUID->object
	Field allNewsEventsGUID:TMap = New TMap

	'holding a number of "sethappened"-newsevents (for ordering)
	Field nextNewsNumber:Long = 0


	'factor by what a newsevents topicality DECREASES by sending it
	'(with whole audience, so 100%, watching)
	'a value > 1.0 means, it decreases to 0 with less than 100% watching
	'ex.: 0.9 = 10% cut, 0.85 = 15% cut
	Field wearoffFactor:Float = 0.25
	'=== CACHE ===
	'cache for faster access

	'holding news coming in a defined future
	Field _upcomingNewsEvents:TList[] {nosave}
	Field _followingNewsEvents:TList[] {nosave}
	Global _instance:TNewsEventCollection


	Function GetInstance:TNewsEventCollection()
		If Not _instance
			_instance = New TNewsEventCollection
			'create arrays
			_instance._InvalidateCaches()
		EndIf
		Return _instance
	End Function


	Method Initialize:TNewsEventCollection()
		newsEventsHistory = New TNewsEvent[0]
		newsEventsHistoryIndex = 0

		newsEvents.Clear()
		newsEventsGUID.Clear()

		allNewsEvents.Clear()
		allNewsEventsGUID.Clear()

		_InvalidateCaches()

		nextNewsNumber = 0

		Return Self
	End Method


	Method _InvalidateCaches()
		_InvalidateUpcomingNewsEvents()
		_InvalidateFollowingNewsEvents()
	End Method


	Method _InvalidateFollowingNewsEvents()
		_followingNewsEvents = New TList[TVTNewsGenre.count + 1]
	End Method


	Method _InvalidateUpcomingNewsEvents()
		_upcomingNewsEvents = New TList[TVTNewsGenre.count + 1]
	End Method


	Method Add:Int(obj:TNewsEvent)
		If Not obj Then Return False
		
		Local guidLC:String = obj.GetGUID().ToLower()

		'add to common maps
		'special lists get filled when using their Getters
		newsEventsGUID.Insert(guidLC, obj)
		newsEvents.Insert(obj.GetID(), obj)

		allNewsEventsGUID.Insert(guidLC, obj)
		allNewsEvents.Insert(obj.GetID(), obj)

		_InvalidateCaches()

		Return True
	End Method


	Method AddOneTimeEvent:Int(obj:TNewsEvent)
		If Not obj Then Return False

		obj.Setflag(TVTNewsFlag.UNIQUE_EVENT, True)
		obj.Setflag(TVTNewsFlag.UNSKIPPABLE, True)
		Add(obj)
	End Method


	Method AddHappenedEvent:Int(obj:TNewsEvent)
		If Not obj Then Return False

		'max 100 entries
		If newsEventsHistory.length > 100
			newsEventsHistory = newsEventsHistory[50 ..]
		EndIf
		'resize if needed
		If newsEventsHistory.length < newsEventsHistoryIndex+1
			newsEventsHistory = newsEventsHistory[.. newsEventsHistoryIndex + 10]
		EndIf

		newsEventsHistory[newsEventsHistoryIndex] = obj

		newsEventsHistoryIndex :+ 1
	End Method



	'remove from "upcoming/alive" news - but keep the "all"
	Method RemoveActive:Int(obj:TNewsEvent)
		If Not obj Then Return False

		newsEventsGUID.Remove(obj.GetGUID().ToLower())
		newsEvents.Remove(obj.GetID())

		_InvalidateCaches()

		Return True
	End Method


	'remove from "all" - make sure it is not referenced by ID/GUID
	'from any active object
	Method Remove:Int(obj:TNewsEvent)
		If Not obj Then Return False

		RemoveActive(obj)

		allNewsEventsGUID.Remove(obj.GetGUID().ToLower())
		allNewsEvents.Remove(obj.GetID())

		Return True
	End Method


	Method GetByID:TNewsEvent(ID:Int)
		Return TNewsEvent(allNewsEvents.ValueForKey(ID))
	End Method


	Method GetByGUID:TNewsEvent(GUID:String)
		Return TNewsEvent(allNewsEventsGUID.ValueForKey( GUID.ToLower() ))
	End Method


	Global nilNode:TNode = New TNode._parent
	Method SearchByPartialGUID:TNewsEvent(GUID:String)
		'skip searching if there is nothing to search
		If GUID.Trim() = "" Then Return Null

		GUID = GUID.ToLower()

		'find first hit
		Local node:TNode = allNewsEventsGUID._FirstNode()
		While node And node <> nilNode
			If String(node._key).Find(GUID) >= 0
				Return TNewsEvent(node._value)
			EndIf

			'move on to next node
			node = node.NextNode()
		Wend

		Return Null
	End Method
	
	
	Method ScheduleTimedInitialNews()
		Local scheduledCount:int = 0
		Local happenOnStartNews:TNewsEvent[]
		For local n:TNewsEventTemplate = EachIn GetNewsEventTemplateCollection().GetUnusedInitialTemplates()
			If n.happenTime >= 0 and n.IsAvailableAtHappenTime()
				local news:TNewsEvent = New TNewsEvent.InitFromTemplate(n)
				If news
					scheduledCount :+ 1
					Add(news)

					if n.happenTime = 0 'planned to execute right on start
						scheduledCount :- 1
						happenOnStartNews :+ [news]
					EndIf
				EndIf
			EndIf
		Next

		For local n:TNewsEvent = EachIn happenOnStartNews
			n.doHappen(GetWorldTime().GetTimeGone())
		Next

		TLogger.Log("ScheduleTimedInitialNews()", "Pre-Created " + scheduledCount + " news happening at fixed time in the future and " + happenOnStartNews.length + " happening right now.", LOG_DEBUG)
	End Method


	Method RemoveOutdatedNewsEvents(minAgeInDays:Int=5, genre:Int=-1)
		Local somethingDeleted:Int = False
		Local toRemove:TNewsEvent[]
		Local today:Int = GetWorldTime().GetDay()
		For Local newsEvent:TNewsEvent = EachIn allnewsEvents.Values()
			'not happened yet - should not happen
			If Not newsEvent.HasHappened() Then Continue
			'only interested in a specific genre?
			If genre <> -1 And newsEvent.GetGenre() <> genre Then Continue

			If Abs(GetWorldTime().GetDay(newsEvent.happenedTime) - today) >= minAgeInDays
				toRemove :+ [newsEvent]

				somethingDeleted = True
			EndIf
		Next

		'delete/modify in an extra step - this approach skips creation
		'of a map-copy just to avoid concurrent modification
		For Local n:TNewsEvent = EachIn toRemove
			Remove(n)
		Next

		'reset caches, so lists get filled correctly
		If somethingDeleted Then _InvalidateCaches()
	End Method


	'remove news events which no longer "happen" (eg. thunderstorm warnings)
	Method RemoveEndedNewsEvents(genre:Int=-1)
		Local somethingDeleted:Int = False
		Local toRemove:TNewsEvent[]

		For Local newsEvent:TNewsEvent = EachIn newsEvents.Values()
			'only interested in a specific genre?
			If genre <> -1 And newsEvent.GetGenre() <> genre Then Continue

			If newsEvent.HasHappened() And newsEvent.HasEnded()
				toRemove :+ [newsEvent]

				somethingDeleted = True
			EndIf
		Next

		'delete/modify in an extra step - this approach skips creation
		'of a map-copy just to avoid concurrent modification
		For Local n:TNewsEvent = EachIn toRemove
			RemoveActive(n)
		Next


		'reset caches, so lists get filled correctly
		If somethingDeleted Then _InvalidateCaches()
	End Method


	Method CreateRandomAvailable:TNewsEvent(genre:Int=-1)
		Local template:TNewsEventTemplate = GetNewsEventTemplateCollection().GetRandomUnusedAvailableInitial(genre)
		If Not template Then Return Null

		Return New TNewsEvent.InitFromTemplate(template)
	End Method


	Method GetNewsHistory:TNewsEvent[](limit:Int=-1)
		If limit = -1
			Return newsEventsHistory[.. newsEventsHistoryIndex]
		Else
			Return newsEventsHistory[Max(0,newsEventsHistoryIndex-limit) .. newsEventsHistoryIndex]
		EndIf
	End Method


	'returns (and creates if needed) a list containing only follow up news
	Method GetFollowingNewsList:TList(genre:Int=-1)
		'create if missing
		If Not _followingNewsEvents Then _InvalidateFollowingNewsEvents()

		If Not _followingNewsEvents[genre+1]
			_followingNewsEvents[genre+1] = CreateList()
			For Local event:TNewsEvent = EachIn newsEvents.Values()
				If event.newsType <> TVTNewsType.FollowingNews Then Continue
				'only interested in a specific genre?
				If genre <> -1 And event.GetGenre() <> genre Then Continue

				_followingNewsEvents[genre+1].AddLast(event)
			Next
		EndIf
		Return _followingNewsEvents[genre+1]
	End Method


	'returns (and creates if needed) a list containing only initial news
	Method GetUpcomingNewsList:TList(genre:Int=-1)
		'create if missing
		If Not _upcomingNewsEvents Then _InvalidateUpcomingNewsEvents()

		If Not _upcomingNewsEvents[genre+1]
			_upcomingNewsEvents[genre+1] = CreateList()
			For Local event:TNewsEvent = EachIn newsEvents.Values()
				'skip events already happened (and processed) or not
				'happened at all (-> "-1")
				If event.HasFlag(TVTNewsFlag.HAPPENING_PROCESSED) Or event.happenedTime = -1 Then Continue
				'only interested in a specific genre?
				If genre <> -1 And event.GetGenre() <> genre Then Continue

				_upcomingNewsEvents[genre+1].AddLast(event)
			Next
		EndIf
		Return _upcomingNewsEvents[genre+1]
	End Method


	Method setNewsHappened(news:TNewsEvent, time:Long = 0)
		'nothing set - use "now"
		If time = 0 Then time = GetWorldTime().GetTimeGone()

		If news.happenedTime <> time
			news.newsNumber = nextNewsNumber
			nextNewsNumber :+ 1

			news.happenedTime = time

			'protect a thread id until the last news of that thread has happened
			Local collection:TNewsEventTemplateCollection = GetNewsEventTemplateCollection()
			Local template:TNewsEventTemplate = collection.getById(news.templateID)
			If template And template.IsReuseable() And template.threadid
				'print "checking template "+ news.GetTitle()
				Local threadTime:Long = Long(String(collection.threadLastHappened.ValueForKey(template.threadid)))
				If threadTime < news.happenedTime
					collection.threadLastHappened.insert(template.threadid, ""+news.happenedTime)
					'print "UPDATING "+template.threadid +" "+news.happenedTime
				EndIf
			EndIf

			'add to the "happened" list
			If news.HasHappened()
				AddHappenedEvent(news)

				'remove from managed ones
				RemoveActive(news)
			EndIf
		EndIf

		'reset only specific caches, so news gets in the correct list
		'- no need to invalidate newstype-specific caches
		_InvalidateUpcomingNewsEvents()
	End Method


	Method GetGenreWearoffModifier:Float(genre:Int)
		'values get multiplied with the wearOff factor
		'so this means: higher (>1.0) values increase the resulting
		'topicality loss
		Select genre
			Case TVTNewsGenre.POLITICS_ECONOMY
				Return 1.05
			Case TVTNewsGenre.SHOWBIZ
				Return 0.9
			Case TVTNewsGenre.SPORT
				Return 1.0
			Case TVTNewsGenre.TECHNICS_MEDIA
				Return 1.05
			Case TVTNewsGenre.CURRENTAFFAIRS
				Return 1.0
			Case TVTNewsGenre.CULTURE
				Return 1.0
			Default
				Return 1.0
		End Select
	End Method


	Function SortByHappenedTime:Int(o1:Object, o2:Object)
		Local N1:TNewsEvent = TNewsEvent(o1)
		Local N2:TNewsEvent = TNewsEvent(o2)
		If Not N2 Then Return 1
		If Not N1 Then Return -1

		If N1.happenedTime > N2.happenedTime Then Return 1
		If N1.happenedTime < N2.happenedTime Then Return -1
		Return 0
	End Function



	Function SortByNewsNumber:Int(o1:Object, o2:Object)
		Local N1:TNewsEvent = TNewsEvent(o1)
		Local N2:TNewsEvent = TNewsEvent(o2)
		If Not N2 Then Return 1
		If Not N1 Then Return -1

		If N1.newsNumber > N2.newsNumber Then Return 1
		If N1.newsNumber < N2.newsNumber Then Return -1
		'fall back to happened time
		Return SortByHappenedTime(o1, o2)
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetNewsEventCollection:TNewsEventCollection()
	Return TNewsEventCollection.GetInstance()
End Function



Type TNewsEvent Extends TBroadcastMaterialSource {_exposeToLua="selected"}
	Field templateID:Int
	'for passing on substitutions to follow up events
	Field templateVariables:TTemplateVariables

	'time when something happened or will happen. "-1" = not happened
	Field happenedTime:Long = -1
	'number of the news since begin of game (for potential ordering)
	Field newsNumber:Long = 0
	'time when a news gets invalid (eg. thunderstorm warning)
	Field eventDuration:Long = -1

	'fine grained attractivity for target groups (splitted gender)
	Field targetGroupAttractivityMod:TAudience = Null

	'used when not -1 or no template is used
	'type of the news event according to TVTNewsType
	private
	Field genre:Int = -1
	public
	Field quality:Float = -1
	Field qualityRaw:Float = -1
	Field newsType:Int = -1
	Field minSubscriptionLevel:Int = -1
	Field keywords:String = ""


	Field _genreDefinitionCache:TNewsGenreDefinition {nosave}


	Method GenerateGUID:String()
		Return "broadcastmaterialsource-newsevent-"+id
	End Method


	Method Init:TNewsEvent(GUID:String, title:TLocalizedString, description:TLocalizedString, Genre:Int, quality:Float=-1, modifiers:TData=Null, newsType:Int=0)
		Self.SetGUID(GUID)
		Self.title       = title
		Self.description = description
		Self.genre       = Genre
		Self.topicality  = 1.0
		If quality >= 0 Then SetQualityRaw(quality)
		Self.newsType	 = newsType
		'modificators: > 1.0 increases price (1.0 = 100%)
		If modifiers Then Self.modifiers = modifiers.Copy()

		Return Self
	End Method


	Method InitFromTemplate:TNewsEvent(template:TNewsEventTemplate, parentVariables:TTemplateVariables = Null)
		'reset template (random data like template variables)
		If template Then template.ResetRandomData()

		Self.templateID = template.GetID()
		Self.SetGUID( template.GetGUID()+"-instance"+(template.timesUsed+1))

		'mark the template (and increase usage count)
		template.SetUsed(Self.GetGUID())

		ReplacePlaceholdersFromTemplate(template, parentVariables, 0)

		Self.happenedTime = template.happenTime
		If template.targetGroupAttractivityMod
			Self.targetGroupAttractivityMod = template.targetGroupAttractivityMod.copy()
		EndIf

		Self.topicality = template.topicality
		Self.SetQualityRaw( template.GetQuality() )
		Self.newsType = template.newsType
		
'		Self.genre = template.genre
		Self.flags = template.flags

		Self.modifiers = template.CopyModifiers()
		Self.effects = template.CopyEffects()
		
		'set availability according to current template availability
		Self.broadcastFlags = template.broadcastFlags
		SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, not template.IsAvailable())

		If Not HasFlag(TVTNewsFlag.UNIQUE_EVENT)
			Local priceChange:Float = 1.0 + 0.01 * BiasedRandRange(-25, 25, 0.5)
			SetModifier(modKeyPriceLS, GetModifier(modKeyPriceLS) * priceChange)
			Local wearoffChange:Float = 1.0 + 0.01 * BiasedRandRange(-25, 25, 0.5)
			SetModifier(modKeyTopicality_WearoffLS, GetModifier(modKeyTopicality_WearoffLS) * priceChange)
		EndIf
		Return Self
	End Method
	
	
	Method ReplacePlaceholdersFromTemplate:Int(template:TNewsEventTemplate = Null, parentVariables:TTemplateVariables = null, time:Long = 0)
		If not template and not self.templateID Then Return False
		If not template
			template = GetNewsEventTemplateCollection().GetByID(self.templateID)
			If not template Then Return False
		EndIf

		' identify which template variables to use, merge multiple if 
		' required to eg. inherit variables from parent
		Local varToUse:TTemplateVariables
		If templateVariables
			varToUse = templateVariables
		Else
			varToUse = parentVariables
			If Not varToUse And template.templateVariables
				'no stored variables and no parent variables - use a copy from the template
				varToUse = template.templateVariables.Copy()
			ElseIf template.templateVariables
				'both template variables and parent variables exist - check if merging is necessary
				Local mergeNecessary:Int = False
				'TODO nested variables with parent are not yet considered by this check
				For Local key:Object = EachIn parentVariables.variables.keys()
					If Not template.templateVariables.variables.Contains(key)
						'parent contains additional variable
						mergeNecessary = True
						Exit
					EndIf
				Next
				If mergeNecessary
					throw "implement merge of template variables - cause: " + template.GetTitle()
				Else
					'for self triggered news merge will not be necessary - parent variables are ignored
					'for now we assume that the existence of template variables starts a new news thread
					'and hence use the template's variables
					varToUse = template.templateVariables.Copy()
				EndIf
			EndIf
		EndIf

		self.title = _ParseScriptExpressions(template.title, True, varToUse)
		self.description = _ParseScriptExpressions(template.description, True, varToUse)

		'store variables for passing on to potential trigger
		If varToUse And Not templateVariables
			templateVariables = varToUse
			'print "storing templateVariables for " +Self.GetTitle()
		EndIf
	End Method


	Method _ParseScriptExpressions:TLocalizedString(text:TLocalizedString, createCopy:Int = True, templateVariablesToUse:TTemplateVariables = Null)
		Local result:TLocalizedString = text
		If createCopy 
			result = text.copy()
		Else
			result = text
		EndIf
	
		Local sb:TStringBuilder = New TStringBuilder()

		For Local langID:Int = EachIn text.GetLanguageIDs()
			Local value:String = text.Get(langID)
			Local valueNew:String = value
			
			_ParseScriptExpressions(valueNew, langID, sb, templateVariablesToUse)

			if value <> valueNew
				result.Set(valueNew, langID)
			EndIf
		Next
		Return result
	End Method


	Method _ParseScriptExpressions:Int(text:String var, localeID:int, sb:TStringBuilder = Null, templateVariablesToUse:TTemplateVariables = Null)
		if not sb 
			sb = New TStringBuilder(text)
		Else
			sb.SetLength(0)
			sb.Append(text)
		EndIf
		
		if not templateVariablesToUse then templateVariablesToUse = self.templateVariables

		Local context:SScriptExpressionContext = new SScriptExpressionContext(self, localeID, templateVariablesToUse)
		sb = GameScriptExpression.ParseLocalizedText(sb, context)
		If text <> sb.Hash() 'only create new string if required
			text = sb.ToString()
			Return True
		EndIf
		Return False
	End Method



	Method SetTitle(title:TLocalizedString)
		Self.title = title
	End Method


	Method SetDescription(description:TLocalizedString)
		Self.description = description
	End Method


	Method ToString:String()
		Return "newsEvent: title=" + GetTitle() + "  quality=" + GetQualityRaw() + "  priceMod=" + GetModifier("price")
	End Method


	Method GetMinSubscriptionLevel:Int()
		If minSubscriptionLevel = -1 And templateID
			Local t:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByID(templateID)
			If t Then Return t.minSubscriptionLevel
		EndIf
		Return Max(0, minSubscriptionLevel)
	End Method


	Method AddKeyword:Int(keyword:String)
		If HasKeyword(keyword, True) Then Return False

		If keywords Then keywords :+ ","
		keywords :+ keyword.ToLower()
		Return True
	End Method


	Method HasKeyword:Int(keyword:String, exactMode:Int = False)
		If Not keyword Or keyword="," Then Return False

		If exactMode
			Return (keywords+",").Find(( keyword+",").ToLower() ) >= 0
		Else
			Return keywords.Find(keyword.ToLower()) >= 0
		EndIf
	End Method


	Method SetQualityRaw:Int(quality:Float)
		'clamp between 0-1.0
		Self.qualityRaw = MathHelper.Clamp(quality, 0.0, 1.0)
	End Method


	Function GetGenreString:String(Genre:Int)
		Return GetLocale("NEWS_"+ TVTNewsGenre.GetasString(Genre).toUpper())
	End Function


	'override
	Method GetMaxTopicality:Float()
		Local maxTopicality:Float = 1.0

		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG"))
		If not devConfig Then devConfig = New TData
		Local devAgeMod:Float = devConfig.GetFloat("DEV_NEWS_AGE_INFLUENCE", 1.0)
		Local devQualityAgeMod:Float = devConfig.GetFloat("DEV_NEWS_QUALITYAGE_INFLUENCE", 1.0)
		Local devBroadcastedMod:Float = devConfig.GetFloat("DEV_NEWS_BROADCAST_INFLUENCE", 1.0)

		'age influence
		Local qualityAgeMod:Float = 0.8 * devQualityAgeMod

		'the older the less ppl want to watch - 1hr = 0.98%, 2hr = 0.96%...
		'means: after ~50 hrs, the topicality is 0
		Local ageHours:Int = (GetWorldTime().GetTimeGone() - Self.happenedTime) / TWorldTime.HOURLENGTH
		Local ageInfluence:Float = 1.0 - 0.01 * Max(0, 100 - 2 * Max(0, ageHours) )
		ageInfluence :* GetModifier(modKeyTopicality_AgeLS)
		'the lower the quality of an newsevent, the higher the age influences
		'the max topicality, up to 80% is possible
		ageInfluence = (1.0-qualityAgeMod) * ageInfluence + ageInfluence*qualityAgeMod * (1 - GetQualityRaw())
		'print GetTitle() + "  " +agehours +"  influence="+ageInfluence +"   devAgeMod="+devageMod +"   qualityAgeMod="+qualityAgeMod +"  qualityRaw="+GetQualityRaw()

		'the first 12 broadcasts do decrease maxTopicality
		Local timesBroadcastedInfluence:Float = 0.02 * Min(12, GetTimesBroadcasted() )
		timesBroadcastedInfluence :* GetModifier(modKeyTopicality_TimesBroadcastedLS)

		'subtract various influences (with individual weights)
		maxTopicality :- ageInfluence * devAgeMod
		maxTopicality :- timesBroadcastedInfluence * devBroadcastedMod

		Return MathHelper.Clamp(maxTopicality, 0.0, 1.0)
	End Method


	Method GetTargetGroupAttractivityMod:TAudience()
		Return targetGroupAttractivityMod
	End Method


	Method HasHappened:Int()
		'avoid that "-1" (the default for "unset") is fetched in the
		'next check ("time gone?")
		If happenedTime = -1 Then Return False
		'check if the time is gone already
		If happenedTime > GetWorldTime().GetTimeGone() Then Return False

		Return True
	End Method


	Method HasEnded:Int()
		'can only end if already happened
		If Not HasHappened() Then Return False

		'avoid that "-1" (the default for "unset") is fetched in the
		'next check ("time gone?")
		'a "-1"-duration never ends
		If eventDuration < 0 Then Return False

		'check if the time is gone already
		If happenedTime + eventDuration > GetWorldTime().GetTimeGone() Then Return False

		Return True
	End Method


	'ATTENTION:
	'to emit an artificial news, use GetNewsAgency().announceNewsEvent()
	Method doHappen(time:Long = 0)
		if time = 0 then time = GetWorldTime().GetTimeGone()
		
		'set happened time, add to collection list...
		GetNewsEventCollection().setNewsHappened(Self, time)

		If time <= GetWorldTime().GetTimeGone() And Not self.HasFlag(TVTNewsFlag.HAPPENING_PROCESSED)
			'inform a template that it just happens
			If templateID > 0
				local newsTemplate:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByID(templateID)
				if newsTemplate
					newsTemplate.OnHappen()
				EndIf
			Endif

			'replace placeholders with CURRENT information (on creation
			'of the news event the time could differ, or the weather
			'is not so shiny...)
			ReplacePlaceholdersFromTemplate(null, templateVariables, time)

			'set topicality to 100%
			topicality = 1.0

			'If keywords.Find("movie") >= 0 Then DebugStop

			'trigger happenEffects
			Local effectParams:TData = New TData.AddInt("newsEventID", Self.GetID())
			If templateVariables
				effectParams.Add("variables", templateVariables)
			EndIf
			If effects Then effects.Update("happen", effectParams)

			'mark newsevent happening as processed
			self.SetFlag(TVTNewsFlag.HAPPENING_PROCESSED, True)
		EndIf
	End Method


	'override
	'call this as soon as a news containing this newsEvent is
	'broadcasted. If playerID = -1 then this effects might target
	'"all players" (depends on implementation)
	Method doBeginBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		'trigger broadcastEffects
		Local effectParams:TData = New TData.AddInt("newsEventID", Self.GetID()).AddInt("playerID", playerID)

		'if nobody broadcasted till now (times are adjusted on
		'finishBroadcast while this is called on beginBroadcast)
		If GetTimesBroadcasted() = 0
			If Not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME)
				If effects Then effects.Update("broadcastFirstTime", effectParams)
				setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME, True)
			EndIf
		EndIf

		If templateVariables
			effectParams.Add("variables", templateVariables)
		EndIf
		If effects Then effects.Update("broadcast", effectParams)
	End Method


	'override
	Method doFinishBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		'trigger broadcastEffects
		Local effectParams:TData = New TData.AddInt("newsEventID", Self.GetID()).AddInt("playerID", playerID)

		'if nobody broadcasted till now (times are adjusted on
		'finishBroadcast while this is called on beginBroadcast)
		If GetTimesBroadcasted() = 0
			If Not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE)
				If effects Then effects.Update("broadcastFirstTimeDone", effectParams)
				setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE, True)
			EndIf
		EndIf

		If templateVariables
			effectParams.Add("variables", templateVariables)
		EndIf
		If effects Then effects.Update("broadcastDone", effectParams)
	End Method


	Method CutTopicality:Float(cutModifier:Float=1.0) {_private}
		'cutModifier can be used to manipulate the resulting cut
		'ex. for night times, for low audience...

		'for the calculation we need to know what to cut, not what to keep
		Local toCut:Float =  (1.0 - cutModifier)
		Local minimumRelativeCut:Float = 0.02 '2%
		Local minimumAbsoluteCut:Float = 0.02 '2%

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


	Method GetGenreWearoffModifier:Float(genre:Int=-1)
		If genre = -1 Then genre = Self.GetGenre()
		Return GetNewsEventCollection().GetGenreWearoffModifier(genre)
	End Method


	Method GetWearoffModifier:Float()
		Return GetModifier(modKeyTopicality_WearoffLS)
	End Method


	Method IsSkippable:Int()
		'cannot skip unskippable events
		'cannot skip events with "happen"-effects
		Return Not (HasFlag(TVTNewsFlag.UNSKIPPABLE) Or GetEffectsCount("happen") > 0)
	End Method


	Method GetGenre:Int()
		'return default it not overridden
		If genre = -1 And templateID
			Local t:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByID(templateID)
			If t Then Return t.genre
		EndIf
		Return genre
	End Method


	'AI/LUA-helper
	'while "GetPrice()" could change, this function should have some kind
	'of "nearly linear" connection to the really used quality
	Method GetAttractiveness:Float() {_exposeToLua}
		'the AI only sees something like the "price" and not the real
		'quality - this is what the player is able to see too

		'with a higher priceMod price increases while quality stays
		'the same -> less quality for your money
		Return GetQuality() / Max(0.001, GetModifier(modKeyPriceLS))
	End Method


	Method GetGenreDefinition:TNewsGenreDefinition()
		If Not _genreDefinitionCache
			Local g:Int = GetGenre()
			_genreDefinitionCache = GetNewsGenreDefinitionCollection().Get( g )

			If Not _genreDefinitionCache
				TLogger.Log("GetGenreDefinition()", "NewsEvent ~q"+GetTitle()+"~q: Genre #"+g+" misses a genreDefinition. Creating BASIC definition-", LOG_ERROR)
				_genreDefinitionCache = New TNewsGenreDefinition.InitBasic(g, Null)
			EndIf
		EndIf
		Return _genreDefinitionCache
	End Method


	Method GetQualityRaw:Float() {_exposeToLua}
		'already calculated?
		If qualityRaw >= 0 Then Return qualityRaw

		'create a random quality
		qualityRaw = (Float(RandRange(1, 100)) / 100.0) '1%-Punkte bis 3%-Punkte Basis-Qualit�t

		Return qualityRaw
	End Method


	'override
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
		Local t:Float = GetTopicality()
		Local quality:Float = GetQualityRaw() * (0.75 * t + 0.25 * t^2)

		Return Max(0, quality)
	End Method


	'returns price based on a "per 5 million" approach
	Method GetPrice:Int() {_exposeToLua}
		'price ranges from 100 to ~7500
		Return Max(100, 7500 * GetQuality() * GetModifier(modKeyPriceLS) )
	End Method
End Type




'custom class for sport news to provide meta data
Type TNewsEvent_Sport extends TNewsEvent
	Field matchID:Int
	Field leagueID:Int
	Field sportID:Int
End Type




Type TGameModifierNews_TriggerNews Extends TGameModifierBase
	Field triggerNewsGUID:String
	Field happenTimeType:Int = 1
	Field happenTimeData:Int[] = [8,16,0,0]
	'% chance to trigger the news when "RunFunc()" is called
	Field triggerProbability:Int = 100


	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierNews_TriggerNews()
		Return New TGameModifierNews_TriggerNews
	End Function


	Method Copy:TGameModifierNews_TriggerNews()
		Local clone:TGameModifierNews_TriggerNews = New TGameModifierNews_TriggerNews
		clone.CopyBaseFrom(Self)
		clone.triggerNewsGUID = Self.triggerNewsGUID
		clone.happenTimeType = Self.happenTimeType
		For Local i:Int = 0 Until happenTimeData.length
			clone.happenTimedata[i] = Self.happenTimeData[i]
		Next
		clone.triggerProbability = Self.triggerProbability

		Return clone
	End Method


	Method Init:TGameModifierNews_TriggerNews(data:TData, extra:TData=Null)
		If Not data Then Return Null

		Local index:String = ""
		If extra And extra.GetInt("childIndex") > 0 Then index = extra.GetInt("childIndex")
		Local triggerNewsGUID:String = data.GetString("news"+index, data.GetString("news", ""))
		If triggerNewsGUID = "" Then Return Null

		Local happenTimeString:String = data.GetString("time"+index, data.GetString("time", ""))
		Local happenTime:Int[]
		If happenTimeString <> ""
			happenTime = StringHelper.StringToIntArray(happenTimeString, ",")
		Else
			happenTime = [1, 8,16,0,0]
		EndIf
		Local triggerProbability:Int = data.GetInt("probability"+index, 100)

		Local obj:TGameModifierNews_TriggerNews = New TGameModifierNews_TriggerNews
		obj.triggerNewsGUID = triggerNewsGUID
		obj.triggerProbability = triggerProbability


		If happenTime.length > 0 And happenTime[0] <> -1
			obj.happenTimeType = happenTime[0]
			obj.happenTimeData = [-1,-1,-1,-1]
			For Local i:Int = 1 Until happenTime.length
				obj.happenTimeData[i-1] = happenTime[i]
			Next
		EndIf

		Return obj
	End Method


	Method ToString:String()
		Local name:String = "default"
		If data Then name = data.GetString("name", name)

		Return "TGameModifier_TriggerNews ("+name+")"
	End Method



	'override to trigger a specific news
	Method RunFunc:Int(params:TData)
		'skip if probability is missed
		If triggerProbability <> 100 And RandRange(0, 100) > triggerProbability Then Return False

		Local news:TNewsEvent

		'instead of triggering the news DIRECTLY, we check first if we
		'are talking about a template...
		Local template:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByGUID(triggerNewsGUID)
		If template
			If template.IsAvailable()
				Local variables:TTemplateVariables = TTemplateVariables(params.Get("variables"))
'				If variables Then variables=variables.Copy()
				news = New TNewsEvent.InitFromTemplate(template, variables)
				If news
					GetNewsEventCollection().Add(news)
				EndIf
			Else
				TLogger.Log("TGameModifierNews_TriggerNews", "news template to trigger not available (yet): "+triggerNewsGUID, LOG_DEBUG)
				Return False
			EndIf
		Else
			news = GetNewsEventCollection().GetByGUID(triggerNewsGUID)
		EndIf

		If Not news
			TLogger.Log("TGameModifierNews_TriggerNews", "cannot find news to trigger: "+triggerNewsGUID, LOG_ERROR)
			Return False
		EndIf
		If Not news.IsAvailable()
			TLogger.Log("TGameModifierNews_TriggerNews", "news to trigger not available (yet): "+triggerNewsGUID, LOG_ERROR)
			Return False
		EndIf
		Local triggerTime:Long = GetWorldTime().CalcTime_Auto(-1, happenTimeType, happenTimeData)
		GetNewsEventCollection().setNewsHappened(news, triggerTime)

		Return True
	End Method
End Type




'grouping various news triggers and triggering "all" or "one"
'of them
Type TGameModifierNews_TriggerNewsChoice Extends TGameModifierChoice
	'% chance to trigger the news when "RunFunc()" is called
	Field triggerProbability:Int = 100


	Method Copy:TGameModifierNews_TriggerNewsChoice()
		Local clone:TGameModifierNews_TriggerNewsChoice = New TGameModifierNews_TriggerNewsChoice
		clone.CopyFromChoice(Self)

		clone.triggerProbability = Self.triggerProbability

		Return clone
	End Method


	'override
	Method ToString:String()
		Local name:String = "default"
		If data Then name = data.GetString("name", name)

		Return "TGameModifier_TriggerNewsChoice ("+name+")"
	End Method


	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierNews_TriggerNewsChoice()
		Return New TGameModifierNews_TriggerNewsChoice
	End Function


	'override to create this type instead of the generic one
	Function CreateNewChoiceInstance:TGameModifierNews_TriggerNews()
		Return New TGameModifierNews_TriggerNews
	End Function


	'override to care for triggerProbability
	Method Init:TGameModifierNews_TriggerNewsChoice(data:TData, extra:TData=Null)
		Super.Init(data, extra)


		'load defaults
		Local template:TGameModifierNews_TriggerNews = New TGameModifierNews_TriggerNews.Init(data, Null)
		If Not template Then template = New TGameModifierNews_TriggerNews

		triggerProbability = template.triggerProbability
		'correct individual probability of the loaded choices
		If modifiers
			For Local i:Int = 0 Until modifiers.length
				Local triggerModifier:TGameModifierNews_TriggerNews = TGameModifierNews_TriggerNews(modifiers[i])
				If Not triggerModifier Then Continue

				modifiersProbability[i] = triggerModifier.triggerProbability
				'reset individual probability to 100%
				triggerModifier.triggerProbability = 100
			Next
		EndIf

		Return Self
	End Method


	'override to trigger a specific news only if general probability
	'was met
	Method RunFunc:Int(params:TData)
		'skip if probability is missed
		If triggerProbability <> 100 And RandRange(0, 100) > triggerProbability Then Return False

		Return Super.RunFunc(params)
	End Method
End Type




Type TGameModifierNews_ModifyAvailability Extends TGameModifierBase
	'actually this is "newsEventTemplateGUID"
	Field newsGUID:String
	Field enableBackup:Int = True
	Field enable:Int = True


	Function CreateNewInstance:TGameModifierNews_ModifyAvailability()
		Return New TGameModifierNews_ModifyAvailability
	End Function


	Method Copy:TGameModifierNews_ModifyAvailability()
		Local clone:TGameModifierNews_ModifyAvailability = New TGameModifierNews_ModifyAvailability
		clone.CopyBaseFrom(Self)
		clone.newsGUID = Self.newsGUID
		clone.enableBackup = Self.enableBackup
		clone.enable = Self.enable
		Return clone
	End Method


	Method Init:TGameModifierNews_ModifyAvailability(data:TData, extra:TData=Null)
		If Not data Then Return Null

		InitTimeDataIfPresent(data)

		newsGUID = data.GetString("news", "")
		enable = data.GetBool("enable", True)

		Return Self
	End Method


	Method GetNewsEvent:TNewsEvent()
		Return TNewsEvent(GetNewsEventCollection().GetByGUID( newsGUID ))
	End Method


	Method GetNewsEventTemplate:TNewsEventTemplate()
		Return TNewsEventTemplate(GetNewsEventTemplateCollection().GetByGUID( newsGUID ))
	End Method


	'override
	Method UndoFunc:Int(params:TData)
		Local newsEventTemplate:TNewsEventTemplate = GetNewsEventTemplate()
		If newsEventTemplate 
			'reset to backup value
'			newsEventTemplate.available = enableBackup

			'also modify "not yet happened" but existing news 
			For Local newsEvent:TNewsEvent = EachIn GetNewsEventCollection().GetUpcomingNewsList()
				If newsEvent.templateID = newsEventTemplate.GetID()
					newsEvent.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, enableBackup)
					'refresh caches
					GetNewsEventCollection()._InvalidateCaches()
				EndIf
			Next
			
			Return True
		Else
			Local newsEvent:TNewsEvent = GetNewsEvent()
			If newsEvent
				newsEvent.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, enableBackup)
				'refresh caches
				GetNewsEventCollection()._InvalidateCaches()
				Return True
			EndIf
		EndIf

		Print "TGameModifierNews_ModifyAvailability.Undo: Failed to find newsEventTemplate or newsEvent with GUID ~q"+newsGUID+"~q."
		Return False
	End Method


	'override to trigger a specific news
	Method RunFunc:Int(params:TData)
		Local newsEventTemplate:TNewsEventTemplate = GetNewsEventTemplate()
		If newsEventTemplate 
			'backup old value
			enableBackup = newsEventTemplate.HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE)

			'set new value (negated, as flag is NOT_AVAILABLE)
			newsEventTemplate.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not enable)

		
			'also modify "not yet happened" but existing news; already published news remain available
			'ATTENTION: this does not backup potentially "differing" news
			'           availabilities. An individually made available
			'           newsevent would get their availability overridden!
			For Local newsEvent:TNewsEvent = EachIn GetNewsEventCollection().GetUpcomingNewsList()
				If newsEvent.templateID = newsEventTemplate.GetID()
					newsEvent.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not enable)
					'refresh caches
					GetNewsEventCollection()._InvalidateCaches()
				EndIf
			Next

			Return True
		Else
			Local newsEvent:TNewsEvent = GetNewsEvent()
			If newsEvent

				'backup old value
				enableBackup = newsEvent.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE)

				newsEvent.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not enable)
				'refresh caches
				GetNewsEventCollection()._InvalidateCaches()

				Return True
			EndIf
		EndIf

		Print "TGameModifierNews_ModifyAvailability.Run: Failed to find newsEventTemplate or newsEvent with GUID ~q"+newsGUID+"~q."
		Return False
	End Method
End Type


'currently not used
Type TGameModifierNews_ModifyAttribute Extends TGameModifierBase
	Field newsGUID:String
	Field attribute:String
	Field value:String
	Field valueBackup:String = ""


	Function CreateNewInstance:TGameModifierNews_ModifyAttribute()
		Return New TGameModifierNews_ModifyAttribute
	End Function


	Method Copy:TGameModifierNews_ModifyAttribute()
		Local clone:TGameModifierNews_ModifyAttribute = New TGameModifierNews_ModifyAttribute
		clone.CopyBaseFrom(Self)
		clone.newsGUID = Self.newsGUID
		clone.attribute = Self.attribute
		clone.value = Self.value
		clone.valueBackup = Self.valueBackup
		Return clone
	End Method


	Method Init:TGameModifierNews_ModifyAttribute(data:TData, extra:TData=Null)
		If Not data Then Return Null

		newsGUID = data.GetString("news", "")
		attribute = data.GetString("attribute").ToLower()
		value = data.GetString("value")

		Return Self
	End Method


	Method ReadNewsEventValue:String(newsEvent:TNewsEvent = Null)
		If Not newsEvent Then newsEvent = GetNewsEvent()
		If Not newsEvent Then Return False

		Select attribute
			Case "topicality"
				Return String( newsEvent.GetTopicality() )
			Case "quality"
				Return String( newsEvent.GetQualityRaw() )
			Default
				Print "TGameModifierNews_Attribute: Trying to read unhandled property ~q"+attribute+"~q."
				Return ""
		End Select
	End Method


	Method WriteNewsEventValue:Int(v:String, newsEvent:TNewsEvent = Null)
		If Not newsEvent Then newsEvent = GetNewsEvent()
		If Not newsEvent Then Return False

		Select attribute
			Case "topicality"
				newsEvent.SetTopicality( Float(v) )
			Case "quality"
				newsEvent.SetQualityRaw( Float(v) )
			Default
				Print "TGameModifierNews_Attribute: Trying to set unhandled property ~q"+attribute+"~q."
				Return False
		End Select

		Return True
	End Method


	Method GetNewsEvent:TNewsEvent()
		Return TNewsEvent(GetNewsEventCollection().GetByGUID( newsGUID ))
	End Method
	

	Method GetNewsEventTemplate:TNewsEventTemplate()
		Return TNewsEventTemplate(GetNewsEventTemplateCollection().GetByGUID( newsGUID ))
	End Method


	'override
	Method UndoFunc:Int(params:TData)
		Local newsEventTemplate:TNewsEventTemplate = GetNewsEventTemplate()

		If newsEventTemplate
			'modify value for all upcoming news based on this template
			For Local newsEvent:TNewsEvent = EachIn GetNewsEventCollection().GetUpcomingNewsList()
				If newsEvent.templateID = newsEventTemplate.GetID()
					WriteNewsEventValue(valueBackup, newsEvent)
				EndIf
			Next
			
			Return True
		Else
			Local newsEvent:TNewsEvent = GetNewsEvent()
			If newsEvent
				WriteNewsEventValue(valueBackup, newsEvent)
			
				Return True
			EndIf
		EndIf

		Print "TGameModifierNews_ModifyAttribute.Undo: Failed to find newsEventTemplate or newsEvent with GUID ~q"+newsGUID+"~q."
		Return False
	End Method


	'override to trigger a specific news
	Method RunFunc:Int(params:TData)
		Local newsEventTemplate:TNewsEventTemplate = GetNewsEventTemplate()

		If newsEventTemplate
			'modify value for all upcoming news based on this template
			For Local newsEvent:TNewsEvent = EachIn GetNewsEventCollection().GetUpcomingNewsList()
				If newsEvent.templateID = newsEventTemplate.GetID()
					valueBackup = ReadNewsEventValue(newsEvent)

					WriteNewsEventValue(value, newsEvent)
				EndIf
			Next
			
			Return True
		Else
			Local newsEvent:TNewsEvent = GetNewsEvent()
			If newsEvent 
				valueBackup = ReadNewsEventValue(newsEvent)
				WriteNewsEventValue(value, newsEvent)
				
				Return True
			EndIf
		EndIf

		Print "TGameModifierNews_ModifyAttribute.Run: Failed to find newsEventTemplate or newsEvent with GUID ~q"+newsGUID+"~q."
		Return False
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("TriggerNews", TGameModifierNews_TriggerNews.CreateNewInstance)
GetGameModifierManager().RegisterCreateFunction("TriggerNewsChoice", TGameModifierNews_TriggerNewsChoice.CreateNewInstance)
GetGameModifierManager().RegisterCreateFunction("ModifyNewsAvailability", TGameModifierNews_ModifyAvailability.CreateNewInstance)
GetGameModifierManager().RegisterCreateFunction("ModifyNewsAttribute", TGameModifierNews_ModifyAttribute.CreateNewInstance)
