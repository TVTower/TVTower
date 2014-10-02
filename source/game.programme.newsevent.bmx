Rem
	====================================================================
	NewsEvent data - basic of broadcastable news
	====================================================================
EndRem
SuperStrict
Import "Dig/base.util.mersenne.bmx"
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


	Method Get:TNewsEvent(GUID:String)
		Return TNewsEvent(allNewsEvents.ValueForKey(GUID))
	End Method


	Method SetOldNewsUnused(daysAgo:int=1)
		For local news:TNewsEvent = eachin allNewsEvents.Values()
			if abs(GetWorldTime().GetDay(news.happenedTime) - GetWorldTime().GetDay()) >= daysAgo
				'reset happenedTime so it is available again
				news.happenedTime = -1
				
				'add it again to the list, this resets the caches
				'and therefore adds it to the available list again
				Add(news)
			endif
		Next
	End Method


	Method GetRandomAvailable:TNewsEvent()
	
		'if no news is available, make older ones available again
		'start with 7 days ago and lower until we got a news
		local days:int = 7
		While GetAvailableNewsList().Count() = 0 and days >= 0
			SetOldNewsUnused(days)
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
				if event.happenedTime = -1 or event.happenedTime >= GetWorldTime().GetTimeGone() then continue
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
				if event.happenedTime < GetWorldTime().GetTimeGone() then continue
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
	Field title:string = ""
	Field description:string = ""
	Field genre:Int = 0
	'TODO: Quality wird nirgends definiert... keine Werte in der DB.
	Field quality:Int = 0
	'TODO: Es muss definiert werden welchen Rahmen price hat. In der DB
	'      sind fast alle Werte 0. Der Höchstwert ist 99.
	Field price:Int	= 0
	'time when something happened or will happen. "-1" = not happened
	Field happenedTime:Double = -1
	Field happenEffects:TNewsEffect[]
	'effects which get triggered on "doBroadcast"
	Field broadcastEffects:TNewsEffect[]
	'type of the news event according to TVTNewsType
	Field newsType:int = 0 'initialNews
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


	Method Init:TNewsEvent(title:String, description:String, Genre:Int, quality:Int=0, price:Int=0, newsType:int=0)
		self.title       = title
		self.description = description
		self.genre       = Genre
		self.quality     = quality
		self.price       = price
		self.newsType	 = newsType

		Return self
	End Method


	Function GetGenreString:String(Genre:Int)
		If Genre = 0 Then Return GetLocale("NEWS_POLITICS_ECONOMY")
		If Genre = 1 Then Return GetLocale("NEWS_SHOWBIZ")
		If Genre = 2 Then Return GetLocale("NEWS_SPORT")
		If Genre = 3 Then Return GetLocale("NEWS_TECHNICS_MEDIA")
		If Genre = 4 Then Return GetLocale("NEWS_CURRENTAFFAIRS")
		Return Genre+ " unbekannt"
	End Function


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
		happenEffects = newEffects
		return True
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
		return skippable
	End Method


	Method IsReuseable:int()
		return reuseable
	End Method


	Method ComputeTopicality:Float()
		'the older the less ppl want to watch - 1hr = 0.95%, 2hr = 0.90%...
		'means: after 20 hrs, the topicality is 0
		local ageHours:int = floor( float(GetWorldTime().GetTimeGone() - self.happenedTime)/3600.0 )
		Local age:float = Max(0,100-5*Max(0, ageHours) )
		return age*2.55 ',max is 255
	End Method


	Method GetAttractiveness:Float() {_exposeToLua}
		Return 0.30*((quality+5)/255) + 0.4*ComputeTopicality()/255 + 0.2*price/255 + 0.1
	End Method


	Method GetQuality:Float(luckFactor:Int = 1) {_exposeToLua}
		Local qualityTemp:Float = 0.0

		qualityTemp = Float(ComputeTopicality()) / 255.0 * 0.45 ..
			+ Float(quality) / 255.0 * 0.35 ..
			+ Float(price) / 255.0 * 0.2

		If luckFactor = 1 Then
			qualityTemp = qualityTemp * 0.97 + (Float(RandRange(10, 30)) / 1000.0) '1%-Punkte bis 3%-Punkte Basis-Qualität
		Else
			qualityTemp = qualityTemp * 0.99 + 0.01 'Mindestens 1% Qualität
		EndIf

		'no minus quote
		Return Max(0, qualityTemp)
	End Method


	Method ComputeBasePrice:Int() {_exposeToLua}
		'price ranges from 0-10.000
		Return 100 * ceil( 100 * float(0.6*quality + 0.3*price + 0.1*self.ComputeTopicality())/255.0 )
		'Return Floor(Float(quality * price / 100 * 2 / 5)) * 100 + 1000  'Teuerstes in etwa 10000+1000
	End Method
End Type




Type TNewsEffect
	Field data:TData
	Field _customEffectFunc:int(data:TData, params:TData)


	Method ToString:string()
		local name:string = data.GetString("name", "default")
		return "TNewsEffect ("+name+")"
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
	Field happenTimeData:int[]	= [5,9,0,0]
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
			self.happenTimeData = happenTimeData
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
		local news:TNewsEvent = GetNewsEventCollection().Get(triggerNewsGUID)
		if not news
			TLogger.Log("TNewsEffect_TriggerNews", "cannot find news to trigger: "+triggerNewsGUID, LOG_ERROR)
			return false
		endif
		GetNewsEventCollection().setNewsHappened(news, GetHappenTime())

		return True
	End Method
End Type