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
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx"
Import "game.world.worldtime.bmx"




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
		For local newsEvent:TNewsEvent = eachin allNewsEvents.Values()
			if abs(GetWorldTime().GetDay(newsEvent.happenedTime) - GetWorldTime().GetDay()) >= minAgeInDays
				'not happened yet
				if newsEvent.happenedTime = -1 then continue
				
				'if the news event cannot get used again remove them
				'from all lists
				If not newsEvent.IsReuseable() then Remove(newsEvent)

				'reset happenedTime so it is available again
				newsEvent.happenedTime = -1

				'reset caches, so lists get filled correctly
				_InvalidateCaches()
			endif
		Next
	End Method


	'resets already used news events of the past so they can get used again
	Method ResetReuseableNewsEvents(minAgeInDays:int=5)
		For local newsEvent:TNewsEvent = eachin allNewsEvents.Values()
			if abs(GetWorldTime().GetDay(newsEvent.happenedTime) - GetWorldTime().GetDay()) >= minAgeInDays
				'not happened yet
				if newsEvent.happenedTime = -1 then continue
				'not reuseable
				If not newsEvent.IsReuseable() then continue

				'reset happenedTime so it is available again
				newsEvent.happenedTime = -1

				'reset caches, so lists get filled correctly
				_InvalidateCaches()
			endif
		Next
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



Type TNewsEvent extends TGameObject {_exposeToLua="selected"}
	Field title:TLocalizedString
	Field description:TLocalizedString
	Field genre:Int = 0
	Field quality:Float = -1.0 'none
	Field priceModifier:Float = 1.0
	'time when something happened or will happen. "-1" = not happened
	Field happenedTime:Double = -1
	Field happenEffects:TNewsEffect[]
	'effects which get triggered on "doBroadcast"
	Field broadcastEffects:TNewsEffect[]
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
	
	Const GENRE_POLITICS:Int = 0	{_exposeToLua}
	Const GENRE_SHOWBIZ:Int  = 1	{_exposeToLua}
	Const GENRE_SPORT:Int    = 2	{_exposeToLua}
	Const GENRE_TECHNICS:Int = 3	{_exposeToLua}
	Const GENRE_CURRENTS:Int = 4	{_exposeToLua}


	Method Init:TNewsEvent(GUID:string, title:TLocalizedString, description:TLocalizedString, Genre:Int, quality:Float=-1, priceModifier:Float=-1, newsType:int=0)
		self.SetGUID(GUID)
		self.title       = title
		self.description = description
		self.genre       = Genre
		if quality >= 0 then SetQuality(quality)
		if priceModifier >= 0 then SetPriceModifier(priceModifier)
		self.newsType	 = newsType

		Return self
	End Method


	Method ToString:String()
		return "newsEvent: title=" + GetTitle() + "  quality=" + quality + "  priceModifier=" + priceModifier + "  broadcastEffects=" + broadcastEffects.length + "  happenEffects="+happenEffects.length
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


	Method SetPriceModifier:Int(priceModifier:Float)
		'avoid negative modifiers
		self.priceModifier = Max(0.0, priceModifier)
	End Method


	Function GetGenreString:String(Genre:Int)
		return GetLocale("NEWS_"+ TVTNewsGenre.GetasString(Genre).toUpper())
	End Function


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
				AddHappenEffect(..
					new TNewsEffect_TriggerNews.Init( ..
						triggerGUID, happenTimeType, happenTimeData ..
				))
				return True
		End Select
		return False
	End Method

	
	'checks if an certain effect type is existent
	Method HasBroadcastEffectType:int(effectType:int) {_exposeToLua}
		For local effect:TNewsEffect = eachin happenEffects
			if effect.HasEffectType(effectType) then return True
		Next
		return False
	End Method
	

	'checks if an effect was already added before
	Method HasBroadcastEffect:int(effect:TNewsEffect)
		if not effect then return True

		For local existingEffect:TNewsEffect = eachin broadcastEffects
			if effect = existingEffect then return True
		Next
		return False
	End Method


	Method AddBroadcastEffect:int(effect:TNewsEffect)
		'skip if already added
		If HasBroadcastEffect(effect) then return False

		'add effect
		broadcastEffects :+ [effect]
		return True
	End Method


	Method RemoveBroadcastEffect:int(effect:TNewsEffect)
		'to make the array "truncate", create a new one - and just
		'skip adding the effect which should get removed.
		local newEffects:TNewsEffect[]
		For Local existingEffect:TNewsEffect = eachIn broadcastEffects
			if existingEffect = effect then continue
			newEffects :+ [existingEffect]
		Next
		
		'set new array
		broadcastEffects = newEffects
		return True
	End Method


	'checks if an certain effect type is existent
	Method HasHappenEffectType:int(effectType:int) {_exposeToLua}
		For local effect:TNewsEffect = eachin happenEffects
			if effect.HasEffectType(effectType) then return True
		Next
		return False
	End Method


	'checks if an effect was already added before
	Method HasHappenEffect:int(effect:TNewsEffect)
		if not effect then return True

		For local existingEffect:TNewsEffect = eachin happenEffects
			if effect = existingEffect then return True
		Next
		return False
	End Method


	Method AddHappenEffect:int(effect:TNewsEffect)
		'skip if already added
		If HasHappenEffect(effect) then return False

		'add effect
		happenEffects :+ [effect]
		return True
	End Method


	Method RemoveHappenEffect:int(effect:TNewsEffect)
		'to make the array "truncate", create a new one - and just
		'skip adding the effect which should get removed.
		local newEffects:TNewsEffect[]
		For Local existingEffect:TNewsEffect = eachIn happenEffects
			if existingEffect = effect then continue
			newEffects :+ [existingEffect]
		Next
		
		'set new array
		happenEffects = newEffects
		return True
	End Method


	Method doHappen(time:int = 0)
		'set happened time, add to collection list...
		GetNewsEventCollection().setNewsHappened(self, time)

		'trigger happenEffects
		local effectParams:TData = new TData.Add("newsEvent", self)
		For local eff:TNewsEffect = eachin happenEffects
			eff.Trigger(effectParams)
		Next
	End Method


	'call this as soon as a news containing this newsEvent is
	'broadcasted. If playerID = -1 then this effect might target
	'"all players" (depends on implementation)
	Method doBroadcast(playerID:int = -1)
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("newsEvent", self).AddNumber("playerID", playerID)
		For local eff:TNewsEffect = eachin broadcastEffects
			eff.Trigger(effectParams)
		Next
	End Method
	

	Method IsSkippable:int()
		'cannot skip events with "happeneffects"
		return skippable and happenEffects.length = 0
	End Method


	Method IsReuseable:int()
		return reuseable
	End Method


	Method ComputeTopicality:Float()
		'the older the less ppl want to watch - 1hr = 0.95%, 2hr = 0.90%...
		'means: after 20 hrs, the topicality is 0
		local ageHours:int = floor( float(GetWorldTime().GetTimeGone() - self.happenedTime)/3600.0 )
		Local age:float = 0.01 * Max(0,100-5*Max(0, ageHours) )
		'value 0-1.0
		return age
	End Method


	Method GetAttractiveness:Float() {_exposeToLua}
		return 0.35*quality + 0.6*ComputeTopicality() + 0.05
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
		Return  Max(500, 100 * ceil(100 * GetAttractiveness() * priceModifier))
	End Method
End Type




Type TNewsEffect
	Field data:TData
	'constant value of TVTNewsEffect (CHANGETREND, TERRORISTATTACK, ...)
	Field effectTypes:int = 0
	Field _customEffectFunc:int(data:TData, params:TData)


	Method ToString:string()
		local name:string = data.GetString("name", "default")
		return "TNewsEffect ("+name+")"
	End Method


	Method SetEffectType:TNewsEffect(effectType :Int, enable:Int=True)
		If enable
			effectTypes :| effectType
		Else
			effectTypes :& ~effectType
		EndIf
		return self
	End Method


	Method HasEffectType:Int(effectType:Int)
		Return effectTypes & effectType
	End Method


	Method SetData(data:TData)
		self.data = data
	End Method


	Method GetData:TData()
		if not data then data = new TData
		return data
	End Method

	
	'call to handle/emit the effect
	Method Trigger:int(params:TData)
		if _customEffectFunc then return _customEffectFunc(GetData(), params)

		return EffectFunc(params)
	End Method


	'override this function in custom types
	Method EffectFunc:int(params:TData)
		print ToString()
		print "data: "+GetData().ToString()
		print "params: "+params.ToString()
	
		return True
	End Method
End Type



Type TNewsEffect_TriggerNews extends TNewsEffect
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