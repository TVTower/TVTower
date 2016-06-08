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




Type TNewsEventCollection
	'contains news just happened
	Field newsEventsHistory:TNewsEvent[]
	Field newsEventsHistoryIndex:int=0
	'holding all existent news events (also triggered news, but not
	'non-reuseable ones or happened one-time-events)
	Field managedNewsEvents:TMap = CreateMap()
	'holding all news event ever created (including non-reuseable ones)
	Field allNewsEvents:TMap = CreateMap()
	
	'holding a number of "sethappened"-newsevents (for ordering)
	Field nextNewsNumber:Long = 0

	
	'factor by what a newsevents topicality DECREASES by sending it
	'(with whole audience, so 100%, watching)
	'a value > 1.0 means, it decreases to 0 with less than 100% watching
	'ex.: 0.9 = 10% cut, 0.85 = 15% cut
	Field wearoffFactor:float = 0.4
	'=== CACHE ===
	'cache for faster access

	'holding already announced news
	Field _usedNewsEvents:TList[] {nosave}
	'holding news coming in a defined future
	Field _upcomingNewsEvents:TList[] {nosave}
	'holding all (initial) news events available to "happen"
	Field _availableNewsEvents:TList[] {nosave}
	Field _initialNewsEvents:TList[] {nosave}
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
		
		managedNewsEvents.Clear()
		allNewsEvents.Clear()
		_InvalidateCaches()

		nextNewsNumber = 0

		return self
	End Method
	

	Method _InvalidateCaches()
		_InvalidateUsedNewsEvents()
		_InvalidateUpcomingNewsEvents()
		_InvalidateAvailableNewsEvents()
		_InvalidateInitialNewsEvents()
		_InvalidateFollowingNewsEvents()
	End Method


	Method _InvalidateUsedNewsEvents()
		_usedNewsEvents = New TList[TVTNewsGenre.count + 1]
	End Method


	Method _InvalidateAvailableNewsEvents()
		_availableNewsEvents = New TList[TVTNewsGenre.count + 1]
	End Method


	Method _InvalidateInitialNewsEvents()
		_initialNewsEvents = New TList[TVTNewsGenre.count + 1]
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
		managedNewsEvents.Insert(obj.GetGUID(), obj)
		allNewsEvents.Insert(obj.GetGUID(), obj)

		_InvalidateCaches()

		return TRUE
	End Method


	Method AddOneTimeEvent:int(obj:TNewsEvent)
		obj.reuseable = False
		obj.skippable = False
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
		allNewsEvents.Remove(obj.GetGUID())

		_InvalidateCaches()

		return TRUE
	End Method


	Method RemoveManaged:int(obj:TNewsEvent)
		managedNewsEvents.Remove(obj.GetGUID())

		_InvalidateCaches()

		return TRUE
	End Method


	'helper for external callers so they do not need to know
	'the internal structure of the collection
	Method RefreshAvailable:int()
		_InvalidateAvailableNewsEvents()

		GetAvailableNewsList()
	End Method
	

	Method GetByGUID:TNewsEvent(GUID:String)
		Return TNewsEvent(managedNewsEvents.ValueForKey(GUID))
	End Method


	Method RemoveOutdatedNewsEvents(minAgeInDays:int=5, genre:int=-1)
		local somethingDeleted:int = False
		local toRemove:TNewsEvent[]
		local toReuse:TNewsEvent[]
		
		For local newsEvent:TNewsEvent = eachin managedNewsEvents.Values()
			'not happened yet - should not happen
			if not newsEvent.HasHappened() then continue
			'only interested in a specific genre?
			if genre <> -1 and newsEvent.genre <> genre then continue 

			if abs(GetWorldTime().GetDay(newsEvent.happenedTime) - GetWorldTime().GetDay()) >= minAgeInDays
				'if the news event cannot get used again remove them
				'from all lists
				if not newsEvent.IsReuseable()
					toRemove :+ [newsEvent]
				else
					toReuse :+ [newsEvent]
				endif

				somethingDeleted = true
			endif
		Next

		'to deletion/modification in an extra step - this avoids
		'to create a map-copy just to avoid concurrent modification
		For local n:TNewsEvent = Eachin toRemove
			RemoveManaged(n)
		Next
		For local n:TNewsEvent = Eachin toReuse
			n.Reuse()
		Next
		
		'reset caches, so lists get filled correctly
		if somethingDeleted then _InvalidateCaches()
	End Method


	'remove news events which no longer "happen" (eg. thunderstorm warnings) 
	Method RemoveEndedNewsEvents(genre:int=-1)
		local somethingDeleted:int = False
		local toRemove:TNewsEvent[]
		local toReuse:TNewsEvent[]

		For local newsEvent:TNewsEvent = eachin managedNewsEvents.Values()
			'only interested in a specific genre?
			if genre <> -1 and newsEvent.genre <> genre then continue 

			if newsEvent.HasHappened() and newsEvent.HasEnded()
				'if the news event cannot get used again remove them
				'from all lists
				if not newsEvent.IsReuseable()
					toRemove :+ [newsEvent]
				else
					toReuse :+ [newsEvent]
				endif
				
				somethingDeleted = true
			endif
		Next

		'to deletion/modification in an extra step - this avoids
		'to create a map-copy just to avoid concurrent modification
		For local n:TNewsEvent = Eachin toRemove
			RemoveManaged(n)
		Next
		For local n:TNewsEvent = Eachin toReuse
			n.Reuse()
		Next
		

		'reset caches, so lists get filled correctly
		if somethingDeleted then _InvalidateCaches()
	End Method


	'resets already used news events of the past so they can get used again
	Method ResetReuseableNewsEvents(minAgeInDays:int=5, genre:int=-1)
		local somethingReset:int = False
		local toReuse:TNewsEvent[]

		For local newsEvent:TNewsEvent = eachin managedNewsEvents.Values()
			'not happened yet
			if newsEvent.HasHappened() then continue
			'only interested in a specific genre?
			if genre <> -1 and newsEvent.genre <> genre then continue 

			if abs(GetWorldTime().GetDay(newsEvent.happenedTime) - GetWorldTime().GetDay()) >= minAgeInDays
				'not reuseable
				If not newsEvent.IsReuseable() then continue

				toReuse :+ [newsEvent]

				somethingReset = True
			endif
		Next

		For local n:TNewsEvent = Eachin toReuse
			n.Reuse()
		Next

		'reset caches, so lists get filled correctly
		if somethingReset then _InvalidateCaches()
	End Method


	Method GetRandomAvailable:TNewsEvent(genre:int=-1)

		'loaded old savegame?
		'-> managedNewsEvents not yet used?!
		if GetAvailableNewsList(genre).Count() = 0
			local c:int = 0
			for local e:TNewsEvent = EachIn managedNewsEvents.Values()
				if e.IsReuseable() then c :+ 1
			Next
			if c = 0
				for local e:TNewsEvent = EachIn allNewsEvents.Values()
					if e.IsReuseable()
						managedNewsEvents.insert(e.GetGUID(), e)
					endif
				Next
				_InvalidateAvailableNewsEvents()
			endif
		endif


		'if no news is available, make older ones available again
		'start with 5 days ago and lower until we got a news
		local days:int = 5
		While GetAvailableNewsList(genre).Count() = 0 and days >= 0
			RemoveOutdatedNewsEvents(days, genre)
			days :- 1
		Wend

		'maybe we could auto-reuse some news ?
		if GetAvailableNewsList(genre).Count() = 0
			GetNewsEventCollection().RemoveEndedNewsEvents(genre)
		endif
		
		if GetAvailableNewsList(genre).Count() = 0
			'This should only happen if no news events were found in the database
			TLogger.Log("TNewsEventCollection.GetRandom("+genre+")", "no unused news events found.", LOG_ERROR)
			Throw "TNewsEventCollection.GetRandom("+genre+"): no unused news events found."
		endif
		
		'fetch a random news
		return TNewsEvent(GetAvailableNewsList(genre).ValueAtIndex(randRange(0, GetAvailableNewsList(genre).Count() - 1)))
	End Method


	Method GetNewsHistory:TNewsEvent[](limit:int=-1)
		if limit = -1
			return newsEventsHistory[.. newsEventsHistoryIndex]
		else
			return newsEventsHistory[Max(0,newsEventsHistoryIndex-limit) .. newsEventsHistoryIndex]
		endif
	End Method
	

	'returns (and creates if needed) a list containing only available news
	Method GetAvailableNewsList:TList(genre:int=-1)
		'create if missing
		if not _availableNewsEvents then _InvalidateAvailableNewsEvents()

		if not _availableNewsEvents[genre+1]
			_availableNewsEvents[genre+1] = CreateList()
			'GetInitialNewsList() does NOT contain "initialInGameNews",
			'use "managedNewsEvents.Values()" to have them included too.
			'But skip "followingNews" then!
			For local event:TNewsEvent = EachIn GetInitialNewsList(genre)
				'skip news happened somewhen (past or future)
				if event.happenedTime <> -1 then continue
				'skip news not available to "happen" (eg. wrong year)
				if not event.CanHappen() then continue
				
				'skip news which cannot happen now
				_availableNewsEvents[genre+1].AddLast(event)
			Next
		endif
		return _availableNewsEvents[genre+1]
	End Method


	'returns (and creates if needed) a list containing only already used
	'news (which are reuseable!)
	Method GetUsedNewsList:TList(genre:int=-1)
		'create if missing
		if not _usedNewsEvents then _InvalidateUsedNewsEvents()

		if not _usedNewsEvents[genre+1]
			_usedNewsEvents[genre+1] = CreateList()
			For local event:TNewsEvent = EachIn managedNewsEvents.Values()
				'skip not happened events - or upcoming events
				if not event.HasHappened() then continue
				'only interested in a specific genre?
				if genre <> -1 and event.genre <> genre then continue 

				_usedNewsEvents[genre+1].AddLast(event)
			Next
		endif
		return _usedNewsEvents[genre+1]
	End Method	


	'returns (and creates if needed) a list containing only initial news
	Method GetInitialNewsList:TList(genre:int=-1)
		'create if missing
		if not _initialNewsEvents then _InvalidateInitialNewsEvents()

		if not _initialNewsEvents[genre+1]
			_initialNewsEvents[genre+1] = CreateList()
			For local event:TNewsEvent = EachIn managedNewsEvents.Values()
				if event.newsType <> TVTNewsType.InitialNews then continue
				'only interested in a specific genre?
				if genre <> -1 and event.genre <> genre then continue 

				_initialNewsEvents[genre+1].AddLast(event)
			Next
		endif
		return _initialNewsEvents[genre+1]
	End Method


	'returns (and creates if needed) a list containing only follow up news
	Method GetFollowingNewsList:TList(genre:int=-1)
		'create if missing
		if not _followingNewsEvents then _InvalidateFollowingNewsEvents()

		if not _followingNewsEvents[genre+1]
			_followingNewsEvents[genre+1] = CreateList()
			For local event:TNewsEvent = EachIn managedNewsEvents.Values()
				if event.newsType <> TVTNewsType.FollowingNews then continue
				'only interested in a specific genre?
				if genre <> -1 and event.genre <> genre then continue 

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
			For local event:TNewsEvent = EachIn managedNewsEvents.Values()
				'skip events already happened or not happened at all (-> "-1")
				if event.HasHappened() or event.happenedTime = -1 then continue
				'only interested in a specific genre?
				if genre <> -1 and event.genre <> genre then continue 

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
			if news.HasHappened() then AddHappenedEvent(news)
		endif

		'reset only specific caches, so news gets in the correct list
		'- no need to invalidate newstype-specific caches
		_InvalidateUsedNewsEvents()
		_InvalidateUpcomingNewsEvents()
		_InvalidateAvailableNewsEvents()

		'remove the news if it cannot happen again
		if not news.IsReuseable() then RemoveManaged(news)
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



Type TNewsEvent extends TBroadcastMaterialSourceBase {_exposeToLua="selected"}
	Field title:TLocalizedString
	Field description:TLocalizedString
	Field genre:Int = 0
	Field qualityRaw:Float = -1.0 'none
	'time when something happened or will happen. "-1" = not happened
	Field happenedTime:Long = -1
	'number of the news since begin of game (for potential ordering)
	Field newsNumber:Long = 0
	'time when a news gets invalid (eg. thunderstorm warning)
	Field eventDuration:Int = -1
	'type of the news event according to TVTNewsType
	Field newsType:int = 0 'initialNews
	Field availableYearRangeFrom:int = -1
	Field availableYearRangeTo:int = -1
	'can the "happening" get skipped ("happens later")
	'eg. if no player listens to the genre
	'news like "terrorist will attack" happen in all cases => NOT skippable
	Field skippable:int = True
	'can the event happen again - or only once?
	'eg. dynamically created weather news should set this to FALSE
	Field reuseable:int = True
	Field _handledFirstTimeBroadcast:int = False
	Field _genreDefinitionCache:TNewsGenreDefinition = Null {nosave}
	

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


	Method Reuse()
		'reset happenedTime so it is available again
		happenedTime = -1
		topicality = 1.0
		'reset helper so it can "premiere" again
		_handledFirstTimeBroadcast = False
	End Method


	Method ToString:String()
		return "newsEvent: title=" + GetTitle() + "  quality=" + GetQualityRaw() + "  priceMod=" + GetModifier("price")
	End Method


	Method GetTitle:string() {_exposeToLua}
		if title then return title.Get()
	End Method


	Method GetDescription:string() {_exposeToLua}
		if description then return description.Get()
		return ""
	End Method

	
	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "generic-newsevent-"+id
		self.GUID = GUID
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

		'age influence

		'the older the less ppl want to watch - 1hr = 0.95%, 2hr = 0.90%...
		'means: after 20 hrs, the topicality is 0
		local ageHours:int = floor( float(GetWorldTime().GetTimeGone() - self.happenedTime)/3600.0 )
		Local ageInfluence:Float = 1.0 - 0.01 * Max(0, 100 - 5 * Max(0, ageHours) )
		ageInfluence :* GetModifier("topicality::age")
		'the lower the quality of an newsevent, the higher the age influences
		'the max topicality, up to 80% is possible
		ageInfluence :* 1 + 0.8 * (1 - GetQualityRaw() )

		'the first 12 broadcasts do decrease maxTopicality
		Local timesBroadcastedInfluence:Float = 0.01 * Min(12, GetTimesBroadcasted() )
		timesBroadcastedInfluence :* GetModifier("topicality::timesBroadcasted")

		'subtract various influences (with individual weights)
		maxTopicality :- 1.0 * ageInfluence
		maxTopicality :- 0.5 * timesBroadcastedInfluence

		return MathHelper.Clamp(maxTopicality, 0.0, 1.0)
	End Method


	Method HasHappened:Int()
		'avoid that "-1" (the default for "unset") is fetched in the
		'next check ("time gone?")
		If happenedTime = -1 Then Return False
		'check if the time is gone already
		If happenedTime > GetWorldTime().GetTimeGone() Then Return False

		return True
	End Method


	Method CanHappen:int()
		local result:int = True
		if availableYearRangeFrom >= 0 and availableYearRangeTo >= 0
			if GetWorldTime().GetYear() < availableYearRangeFrom or GetWorldTime().GetYear() > availableYearRangeTo
				result = False
			endif
		endif

		return result
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

			'trigger happenEffects
			local effectParams:TData = new TData.Add("source", self)
			effects.Run("happen", effectParams)
		endif
	End Method


	'call this as soon as a news containing this newsEvent is
	'broadcasted. If playerID = -1 then this effects might target
	'"all players" (depends on implementation)
	Method doBeginBroadcast(playerID:int = -1, broadcastType:int = 0)
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("source", self).AddNumber("playerID", playerID)

		'if nobody broadcasted till now (times are adjusted on
		'finishBroadcast while this is called on beginBroadcast)
		if GetTimesBroadcasted() = 0
			if not _handledFirstTimeBroadcast
				effects.Run("broadcastFirstTime", effectParams)
				_handledFirstTimeBroadcast = True
			endif
		endif

		effects.Run("broadcast", effectParams)
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

print GetTitle()+"   "+cutModifier+"  toCut="+toCut

		'take care of minimumCut and switch back to "what to cut"
		cutModifier = 1.0 - MathHelper.Clamp(toCut, minimumAbsoluteCut, 1.0)

		topicality = MathHelper.Clamp(topicality * cutModifier, 0.0, 1.0)

		Return topicality
	End Method	


	Method GetGenreWearoffModifier:float(genre:int=-1)
		if genre = -1 then genre = self.genre
		return GetNewsEventCollection().GetGenreWearoffModifier(genre)
	End Method


	Method GetWearoffModifier:float()
		return GetModifier("topicality::wearoff")
	End Method


	Method IsSkippable:int()
		'cannot skip events with "happen"-effects
		return skippable and (not effects.GetList("happen") or effects.GetList("happen").count() = 0)
	End Method


	Method IsReuseable:int()
		return reuseable
	End Method


	'AI/LUA-helper
	Method GetAttractiveness:Float() {_exposeToLua}
		return 0.35*GetQualityRaw() + 0.6*GetTopicality() + 0.05
	End Method


	Method GetGenreDefinition:TNewsGenreDefinition()
		If Not _genreDefinitionCache
			_genreDefinitionCache = GetNewsGenreDefinitionCollection().Get(Genre)

			If Not _genreDefinitionCache
				TLogger.Log("GetGenreDefinition()", "NewsEvent ~q"+GetTitle()+"~q: Genre #"+Genre+" misses a genreDefinition. Creating BASIC definition-", LOG_ERROR)
				_genreDefinitionCache = new TNewsGenreDefinition.InitBasic(Genre, null)
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
		Local quality:Float = GetQualityRaw() * GetTopicality() ^ 2

		Return Max(0, quality)
	End Method


	Method ComputeBasePrice:Int() {_exposeToLua}
		'price ranges from 500-10.000
		Return Max(500, 100 * ceil(100 * GetAttractiveness() * GetModifier("price") ) )
	End Method
End Type





Type TGameModifierNews_TriggerNews extends TGameModifierBase
	Field triggerNewsGUID:string
	Field happenTimeType:int = 1
	Field happenTimeData:int[] = [8,16,0,0]
	'% chance to trigger the news when "RunFunc()" is called
	Field triggerProbability:Int = 100
	

	Function CreateFromData:TGameModifierNews_TriggerNews(data:TData, index:string="")
		if not data then return null

		'local source:TNewsEvent = TNewsEvent(data.get("source"))
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
	End Function
	
	
	Method ToString:string()
		local name:string = data.GetString("name", "default")
		return "TGameModifier_TriggerNews ("+name+")"
	End Method



	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		'skip if probability is missed
		if triggerProbability <> 100 and RandRange(0, 100) > triggerProbability then return False

		'set the happenedTime of the defined news to somewhere in the future
		local news:TNewsEvent = GetNewsEventCollection().GetByGUID(triggerNewsGUID)
		if not news
			TLogger.Log("TGameModifierNews_TriggerNews", "cannot find news to trigger: "+triggerNewsGUID, LOG_ERROR)
			return false
		endif
		local triggerTime:Long = TGameModifierTimeFrame.CalcTime_Auto(happenTimeType, happenTimeData)
		GetNewsEventCollection().setNewsHappened(news, triggerTime)

		return True
	End Method
End Type




'grouping various news triggers and triggering "all" or "one"
'of them
Type TGameModifierNews_TriggerNewsChoice extends TGameModifierChoice
	'% chance to trigger the news when "RunFunc()" is called
	Field triggerProbability:Int = 100


	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierNews_TriggerNewsChoice()
		return new TGameModifierNews_TriggerNewsChoice
	End Function
	

	'override to care for triggerProbability
	Method CustomCreateFromData(data:TData, index:string)
		Super.CustomCreateFromData(data, index)

		'load defaults
		local template:TGameModifierNews_TriggerNews = TGameModifierNews_TriggerNews.CreateFromData(data)
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

	Function CreateFromData:TGameModifierNews_ModifyAvailability(data:TData, index:string="")
		if not data then return null

		'local source:TNewsEvent = TNewsEvent(data.get("source"))
		local modifier:TGameModifierNews_ModifyAvailability = new TGameModifierNews_ModifyAvailability 
		modifier.newsGUID = data.GetString("news", "")
		modifier.enable = data.GetBool("enable", True)

		return modifier
	End Function


	'override
	Method UndoFunc:int()
		local newsEvent:TNewsEvent = TNewsEvent(GetNewsEventCollection().GetByGUID( newsGUID ))
		if not newsEvent
			print "TGameModifierNews_ModifyAvailability: Undo failed, newsEvent ~q"+newsGUID+"~q not found."
		endif

		newsEvent.available = enableBackup
	End Method


	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		local newsEvent:TNewsEvent = TNewsEvent(GetNewsEventCollection().GetByGUID( newsGUID ))
		if not newsEvent
			print "TGameModifierNews_ModifyAvailability: Run failed, newsEvent ~q"+newsGUID+"~q not found."
		endif

		enableBackup = newsEvent.available
		
		newsEvent.available = enable
	End Method
End Type
	

GameModifierCreator.RegisterModifier("TriggerNews", new TGameModifierNews_TriggerNews)
GameModifierCreator.RegisterModifier("TriggerNewsChoice", new TGameModifierNews_TriggerNewsChoice)
GameModifierCreator.RegisterModifier("ModifyNewsAvailability", new TGameModifierNews_ModifyAvailability)
