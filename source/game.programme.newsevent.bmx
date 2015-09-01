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
	'holding all existent news events (also triggered news)
	Field allNewsEvents:TMap = CreateMap()
	'=== CACHE ===
	'cache for faster access

	'holding already announced news
	Field _usedNewsEvents:TList = CreateList() {nosave}
	'holding news coming in a defined future
	Field _upcomingNewsEvents:TList = CreateList() {nosave}
	'holding all (initial) news events available to "happen"
	Field _availableNewsEvents:TList = CreateList() {nosave}
	Field _initialNewsEvents:TList = CreateList() {nosave}
	Field _followingNewsEvents:TList = CreateList() {nosave}
	Global _instance:TNewsEventCollection


	Function GetInstance:TNewsEventCollection()
		if not _instance then _instance = new TNewsEventCollection
		return _instance
	End Function


	Method Initialize:TNewsEventCollection()
		allNewsEvents.Clear()
		_InvalidateCaches()

		return self
	End Method
	

	Method _InvalidateCaches()
		_usedNewsEvents = Null
		_upcomingNewsEvents = Null
		_availableNewsEvents = Null
		_initialNewsEvents = Null
		_followingNewsEvents = Null
	End Method

	
	Method Add:int(obj:TNewsEvent)
		'add to common map
		'special lists get filled when using their Getters
		allNewsEvents.Insert(obj.GetGUID(), obj)

		_InvalidateCaches()

		return TRUE
	End Method


	Method AddOneTimeEvent:int(obj:TNewsEvent)
		obj.reuseable = False
		obj.skippable = False
		Add(obj)
	End Method


	Method Remove:int(obj:TNewsEvent)
		allNewsEvents.Remove(obj.GetGUID())

		_InvalidateCaches()

		return TRUE
	End Method


	'helper for external callers so they do not need to know
	'the internal structure of the collection
	Method RefreshAvailable:int()
		_availableNewsEvents = Null
		GetAvailableNewsList()
	End Method
	

	Method GetByGUID:TNewsEvent(GUID:String)
		Return TNewsEvent(allNewsEvents.ValueForKey(GUID))
	End Method


	Method RemoveOutdatedNewsEvents(minAgeInDays:int=5)
		local somethingDeleted:int = False
		For local newsEvent:TNewsEvent = eachin allNewsEvents.Copy().Values()
			if abs(GetWorldTime().GetDay(newsEvent.happenedTime) - GetWorldTime().GetDay()) >= minAgeInDays
				'not happened yet
				if newsEvent.happenedTime = -1 then continue
				
				'if the news event cannot get used again remove them
				'from all lists
				If not newsEvent.IsReuseable() then Remove(newsEvent)

				newsEvent.Reuse()

				somethingDeleted = true
			endif
		Next

		'reset caches, so lists get filled correctly
		if somethingDeleted then _InvalidateCaches()
	End Method


	'resets already used news events of the past so they can get used again
	Method ResetReuseableNewsEvents(minAgeInDays:int=5)
		local somethingReset:int = False
		For local newsEvent:TNewsEvent = eachin allNewsEvents.Values()
			if abs(GetWorldTime().GetDay(newsEvent.happenedTime) - GetWorldTime().GetDay()) >= minAgeInDays
				'not happened yet
				if newsEvent.happenedTime = -1 then continue
				'not reuseable
				If not newsEvent.IsReuseable() then continue

				'reset happenedTime so it is available again
				newsEvent.happenedTime = -1

				somethingReset = True
			endif
		Next

		'reset caches, so lists get filled correctly
		if somethingReset then _InvalidateCaches()
	End Method


	Method GetRandomAvailable:TNewsEvent()
	
		'if no news is available, make older ones available again
		'start with 5 days ago and lower until we got a news
		local days:int = 5
		While GetAvailableNewsList().Count() = 0 and days >= 0
			RemoveOutdatedNewsEvents(days)
			days :- 1
		Wend
		
		if GetAvailableNewsList().Count() = 0
			'This should only happen if no news events were found in the database
			Throw "TNewsEventCollection.GetRandom(): no unused news events found."
		endif
		
		'fetch a random news
		return TNewsEvent(GetAvailableNewsList().ValueAtIndex(randRange(0, GetAvailableNewsList().Count() - 1)))
	End Method


	'returns (and creates if needed) a list containing only available news
	Method GetAvailableNewsList:TList()
		if not _availableNewsEvents
			_availableNewsEvents = CreateList()
			'GetInitialNewsList() does NOT contain "initialInGameNews",
			'use "allNewsEvents.Values()" to have them included too.
			'But skip "followingNews" then!
			For local event:TNewsEvent = EachIn GetInitialNewsList()
				'skip news happened somewhen (past or future)
				if event.happenedTime <> -1 then continue
				'skip news not available to "happen" (eg. wrong year)
				if not event.CanHappen() then continue
				
				'skip news which cannot happen now
				_availableNewsEvents.AddLast(event)
			Next
		endif
		return _availableNewsEvents
	End Method


	'returns (and creates if needed) a list containing only already used
	'news
	Method GetUsedNewsList:TList()
		if not _usedNewsEvents
			_usedNewsEvents = CreateList()
			For local event:TNewsEvent = EachIn allNewsEvents.Values()
				'skip not happened events - or upcoming events
				if not event.HasHappened() then continue
				_usedNewsEvents.AddLast(event)
			Next
		endif
		return _usedNewsEvents
	End Method	


	'returns (and creates if needed) a list containing only initial news
	Method GetInitialNewsList:TList()
		if not _initialNewsEvents
			_initialNewsEvents = CreateList()
			For local event:TNewsEvent = EachIn allNewsEvents.Values()
				if event.newsType <> TVTNewsType.InitialNews then continue
				_initialNewsEvents.AddLast(event)
			Next
		endif
		return _initialNewsEvents
	End Method


	'returns (and creates if needed) a list containing only follow up news
	Method GetFollowingNewsList:TList()
		if not _followingNewsEvents
			_followingNewsEvents = CreateList()
			For local event:TNewsEvent = EachIn allNewsEvents.Values()
				if event.newsType <> TVTNewsType.FollowingNews then continue
				_followingNewsEvents.AddLast(event)
			Next
		endif
		return _followingNewsEvents
	End Method


	'returns (and creates if needed) a list containing only initial news
	Method GetUpcomingNewsList:TList()
		if not _upcomingNewsEvents
			_upcomingNewsEvents = CreateList()
			For local event:TNewsEvent = EachIn allNewsEvents.Values()
				'skip events already happened or not happened at all (-> "-1")
				if event.HasHappened() or event.happenedTime = -1 then continue
				_upcomingNewsEvents.AddLast(event)
			Next
		endif
		return _upcomingNewsEvents
	End Method


	Method setNewsHappened(news:TNewsEvent, time:Double = 0)
		'nothing set - use "now"
		if time = 0 then time = GetWorldTime().GetTimeGone()
		news.happenedtime = time

		'reset only specific caches, so news gets in the correct list
		'- no need to invalidate newstype-specific caches
		_usedNewsEvents = Null
		_upcomingNewsEvents = Null
		_availableNewsEvents = Null

		'remove the news if it cannot happen again
		if not news.IsReuseable() then Remove(news)
	End Method
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
	Field quality:Float = -1.0 'none
	'time when something happened or will happen. "-1" = not happened
	Field happenedTime:Double = -1
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
	
	Const GENRE_POLITICS:Int = 0	{_exposeToLua}
	Const GENRE_SHOWBIZ:Int  = 1	{_exposeToLua}
	Const GENRE_SPORT:Int    = 2	{_exposeToLua}
	Const GENRE_TECHNICS:Int = 3	{_exposeToLua}
	Const GENRE_CURRENTS:Int = 4	{_exposeToLua}


	Method Init:TNewsEvent(GUID:string, title:TLocalizedString, description:TLocalizedString, Genre:Int, quality:Float=-1, modifiers:TData=null, newsType:int=0)
		self.SetGUID(GUID)
		self.title       = title
		self.description = description
		self.genre       = Genre
		self.topicality  = 1.0
		if quality >= 0 then SetQuality(quality)
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
		return "newsEvent: title=" + GetTitle() + "  quality=" + quality + "  priceMod=" + GetModifier("price")
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


	Method SetQuality:Int(quality:Float)
		'clamp between 0-1.0
		self.quality = MathHelper.Clamp(quality, 0.0, 1.0)
	End Method
	

	Function GetGenreString:String(Genre:Int)
		return GetLocale("NEWS_"+ TVTNewsGenre.GetasString(Genre).toUpper())
	End Function


	Method GetTopicality:Float()
		'refresh topicality (to avoid odd values through external modification)
		topicality = MathHelper.Clamp(topicality, 0.0, 1.0)

		local topicalityMod:Float = 1.0

		'age influence

		'the older the less ppl want to watch - 1hr = 0.95%, 2hr = 0.90%...
		'means: after 20 hrs, the topicality is 0
		local ageHours:int = floor( float(GetWorldTime().GetTimeGone() - self.happenedTime)/3600.0 )
		'value 0-1.0
		Local age:float = 0.01 * Max(0,100-5*Max(0, ageHours) )

		topicalityMod :* age * GetModifier("age")

		

		return topicality * topicalityMod
	End Method


	'override
	Method GetMaxTopicality:Float()
		local maxTopicality:Float = 1.0

		'age influence

		'the older the less ppl want to watch - 1hr = 0.95%, 2hr = 0.90%...
		'means: after 20 hrs, the topicality is 0
		local ageHours:int = floor( float(GetWorldTime().GetTimeGone() - self.happenedTime)/3600.0 )
		Local ageInfluence:float = 1.0 - 0.01 * Max(0, 100 - 5 * Max(0, ageHours))
		ageInfluence :* GetModifier("topicality::age")

		'the first 12 broadcasts do decrease maxTopicality
		Local timesBroadcastedInfluence:Float = 0.01 * Min(12, GetTimesBroadcasted())
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


	Method AddEffectByData:int(effectData:TData)
		if not effectData then return False

		Select effectData.GetString("type").ToLower()
			case "triggernews"
				local triggerGUID:string = effectData.GetString("parameter1", "")
				local happenTimeType:int = effectData.GetInt("parameter2", -1)
				local happenTimeData:int[] = [..
					effectData.GetInt("parameter3", -1), ..
					effectData.GetInt("parameter4", -1), ..
					effectData.GetInt("parameter5", -1), ..
					effectData.GetInt("parameter6", -1) ..
				]
				if triggerGUID = "" then return False
				effects.AddEffect("happen", ..
					new TNewsEffect_TriggerNews.Init( ..
						triggerGUID, happenTimeType, happenTimeData ..
				))
				return True
		End Select
		return False
	End Method


	Method doHappen(time:Double = 0.0)
		if HasHappened() then return

		'set happened time, add to collection list...
		GetNewsEventCollection().setNewsHappened(self, time)

		'set topicality to 100%
		topicality = 1.0

		'trigger happenEffects
		local effectParams:TData = new TData.Add("newsEvent", self)
		effects.RunEffects("happen", effectParams)
	End Method


	'call this as soon as a news containing this newsEvent is
	'broadcasted. If playerID = -1 then this effects might target
	'"all players" (depends on implementation)
	Method doBroadcast(playerID:int = -1)
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("newsEvent", self).AddNumber("playerID", playerID)

		'if nobody broadcasted till now (times are adjusted on
		'finishBroadcast while this is called on beginBroadcast)
		if GetTimesBroadcasted() = 0
			if not _handledFirstTimeBroadcast
				effects.RunEffects("broadcastFirstTime", effectParams)
				_handledFirstTimeBroadcast = True
			endif
		endif

		effects.RunEffects("broadcast", effectParams)
	End Method


	Method CutTopicality:Float(cutModifier:float=1.0) {_private}
		'cutModifier can be used to manipulate the resulting cut
		'ex. for night times, for low audience...
		local changeValue:float = topicality

		'cut by an individual cutoff factor - do not allow values > 1.0
		'(refresh instead of cut)
		'the value : default * invidual * individualGenre
		changeValue :* cutModifier
		changeValue = topicality - changeValue

		'cut by at least 1%, limit to 0-Max
		topicality = MathHelper.Clamp(topicality - Max(0.01, changeValue), 0.0, 1.0)

		Return topicality
	End Method	


	Method IsSkippable:int()
		'cannot skip events with "happen"-effects
		return skippable and (not effects.GetList("happen") or effects.GetList("happen").count() = 0)
	End Method


	Method IsReuseable:int()
		return reuseable
	End Method


	Method GetAttractiveness:Float() {_exposeToLua}
		return 0.35*quality + 0.6*GetTopicality() + 0.05
	End Method


	Method GetQuality:Float(luckFactor:Int = 1) {_exposeToLua}
		if quality >= 0 then return quality
		
		Local qualityTemp:Float = 0.0

		qualityTemp = GetAttractiveness()

		If luckFactor = 1 Then
			qualityTemp = qualityTemp * 0.97 + (Float(RandRange(10, 30)) / 1000.0) '1%-Punkte bis 3%-Punkte Basis-Qualität
		Else
			qualityTemp = qualityTemp * 0.99 + 0.01 'Mindestens 1% Qualität
		EndIf

		'no minus quote
		quality = Max(0, qualityTemp)

		return quality
	End Method


	Method ComputeBasePrice:Int() {_exposeToLua}
		'price ranges from 500-10.000
		Return  Max(500, 100 * ceil(100 * GetAttractiveness() * GetModifier("price")))
	End Method
End Type





Type TNewsEffect_TriggerNews extends TGameObjectEffect
	Field triggerNewsGUID:string
	'params for time generation  [A,B,C,D]
	Field happenTimeData:int[]	= [8,16,0,0]
	'what kind of happen time data do we have?
	'1 = "A" days from now
	'2 = "A" hours from now
	'3 = "A" days from now at "B":00
	'4 = "A"-"B" hours from now
	Field happenTimeType:int = 4

	
	Method ToString:string()
		local name:string = data.GetString("name", "default")
		return "TNewsEffect_TriggerNews ("+name+")"
	End Method


	'default params trigger the news 5 hours after the triggering one
	Method Init:TNewsEffect_TriggerNews(triggerNewsGUID:string, happentimeType:int = -1, happenTimeData:int[] = null)
		self.triggerNewsGUID = triggerNewsGUID
		if happenTimeType > 0
			self.happenTimeType = happenTimeType
		endif
		if happenTimeData and happenTimeData.length = 4
			'only use values defined in the happenTimeData-array
			local happenTimeDataNew:int[] = [self.happenTimeData[0], self.happenTimeData[1], self.happenTimeData[2], self.happenTimeData[3]]
			for local i:int = 0 until happenTimeData.length
				if happenTimeData[i] >= 0 then happenTimeDataNew[i] = happenTimeData[i]
			Next

			self.happenTimeData = happenTimeDataNew
		endif
		return self
	End Method


	Method GetHappenTime:Double()
		Select happenTimeType
			'data is days from now
			case 1
				local happenTime:Double = GetWorldTime().getTimeGone()
				return happenTime + happenTimeData[0]*60*60*24
			'data is hours from now
			case 2
				local happenTime:Double = GetWorldTime().getTimeGone()
				return happenTime + happenTimeData[0]*60*60
			'data is days from now at X:00
			case 3
				return GetWorldTime().MakeTime(GetWorldTime().GetYear(), GetWorldTime().GetDayOfYear() + happenTimeData[0], happenTimeData[1], 0)
			'data is hours "a - b" from now
			case 4
				local happenTime:Double = GetWorldTime().getTimeGone()
				'add starthour "a"
				happenTime :+ happenTimeData[0] * 60*60
				'add random seconds between "a" and "b"
				happenTime :+ randRange(0, (happenTimeData[1] - happenTimeData[0]) *60*60)
				'7-9 = 7:00, 7:01, ... 9:00
				return happenTime
		End Select
		return 0
	End Method
	

	'override to trigger a specific news
	Method EffectFunc:int(params:TData)
		'set the happenedTime of the defined news to somewhere in the future
		local news:TNewsEvent = GetNewsEventCollection().GetByGUID(triggerNewsGUID)
		if not news
			TLogger.Log("TNewsEffect_TriggerNews", "cannot find news to trigger: "+triggerNewsGUID, LOG_ERROR)
			return false
		endif
		GetNewsEventCollection().setNewsHappened(news, GetHappenTime())

		return True
	End Method
End Type