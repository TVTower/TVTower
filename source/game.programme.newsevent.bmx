Rem
	====================================================================
	NewsEvent data - basic of broadcastable news
	====================================================================
EndRem
Import "Dig/base.util.mersenne.bmx"
'for TBroadcastSequence
Import "game.broadcast.base.bmx"
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"




Type TNewsEventCollection
	'holding already announced news
	Field usedList:TList = CreateList()
	'holding single news and first/parent of news-chains (start)
	Field List:TList = CreateList()


	Method Add:int(obj:TNewsEvent)
		List.AddLast(obj)
		return TRUE
	End Method


	Method Remove:int(obj:TNewsEvent)
		List.Remove(obj)
		return TRUE
	End Method


	Method Get:TNewsEvent(id:Int)
		Local news:TNewsEvent = Null
		For Local i:Int = 0 To List.Count()-1
			news = TNewsEvent(List.ValueAtIndex(i))
			If news and news.id = id
				news.doHappen()
				Return news
			endif
		Next
		Return Null
	End Method


	Method SetOldNewsUnused(daysAgo:int=1)
		For local news:TNewsEvent = eachin usedList
			if abs(GetWorldTime().GetDay(news.happenedTime) - GetWorldTime().GetDay()) >= daysAgo
				usedList.Remove(news)
				list.addLast(news)
				news.happenedTime = -1
			endif
		Next
	End Method


	Method GetRandom:TNewsEvent()
		'if no news is available, make older ones available again
		'start with 7 days ago and lower until we got a news
		local days:int = 7
		While List.Count() = 0 and days >= 0
			SetOldNewsUnused(days)
			days :- 1
		Wend
		if days < 7
			print "NewsEventCollection.GetRandom(): used=" + usedList.Count() + " unused="+list.Count() + " refreshedDaysAgo="+(days+1)
		endif
		
		if List.Count() = 0
			'This should only happen if no news events were found in the database
			Throw "TNewsEventCollection.GetRandom(): no unused news events found."
		endif
		
		'fetch a random news
		Local news:TNewsEvent = TNewsEvent(List.ValueAtIndex((randRange(0, List.Count() - 1))))

		news.doHappen()

		'Print "get random news: "+news.title + " ("+news.episode+"/"+news.getEpisodesCount()+")"
		Return news
	End Method


	Method setNewsHappened(news:TNewsEvent, time:Double = 0)
		'nothing set - use "now"
		if time = 0 then time = GetWorldTime().GetTimeGone()
		news.happenedtime = time

		if not news.parent
			self.usedList.addLast(news)
			self.list.remove(news)
		endif
	End Method
End Type
Global NewsEventCollection:TNewsEventCollection = new TNewsEventCollection



Type TNewsEvent extends TGameObject {_exposeToLua="selected"}
	Field title:string = ""
	Field description:string = ""
	Field genre:Int = 0
	'TODO: Quality wird nirgends definiert... keine Werte in der DB.
	Field quality:Int = 0
	'TODO: Es muss definiert werden welchen Rahmen price hat. In der DB
	'      sind fast alle Werte 0. Der Höchstwert ist 99.
	Field price:Int	= 0
	Field episode:Int = 0
	Field episodes:TList = CreateList()
	Field happenedTime:Double = -1
	'params for delay generation  [A,B,C,D]
	Field happenDelayData:int[]	= [5,0,0,0]
	'what kind of delay do we have?
	'1 = "A" days from now
	'2 = "A" hours from now
	'3 = "A" days from now at "B":00
	Field happenDelayType:int = 2
	'effects which get triggered on "doHappen"
	Field happenEffects:TNewsEffect[]
	'effects which get triggered on "doBroadcast"
	Field broadcastEffects:TNewsEffect[]
	'is this news a child of a chain?
	Field parent:TNewsEvent = Null
	'can the "happening" get skipped ("happens later")
	'eg. if no player listens to the genre
	'news like "terrorist will attack" happen in all cases => NOT skippable
	Field skippable:int = True

	Const GENRE_POLITICS:Int = 0	{_exposeToLua}
	Const GENRE_SHOWBIZ:Int  = 1	{_exposeToLua}
	Const GENRE_SPORT:Int    = 2	{_exposeToLua}
	Const GENRE_TECHNICS:Int = 3	{_exposeToLua}
	Const GENRE_CURRENTS:Int = 4	{_exposeToLua}


	Function Create:TNewsEvent(title:String, description:String, Genre:Int, quality:Int=0, price:Int=0)
		Local obj:TNewsEvent =New TNewsEvent
		obj.title       = title
		obj.description = description
		obj.genre       = Genre
		obj.episode     = 0
		obj.quality     = quality
		obj.price       = price

		NewsEventCollection.Add(obj)
		Return obj
	End Function


	Method AddEpisode:TNewsEvent(title:String, description:String, Genre:Int, episode:Int=0,quality:Int=0, price:Int=0, id:Int=0)
		Local obj:TNewsEvent =New TNewsEvent
		obj.title       = title
		obj.description = description
		obj.Genre       = Genre
		obj.quality     = quality
		obj.price       = price

	    obj.episode     = episode
		obj.parent		= Self

		obj.happenDelayType		= 2 'data is hours
		obj.happenDelayData[0]	= 5 '5hrs default
		'add to parent
		Self.episodes.AddLast(obj)
		SortList(Self.episodes)

		Return obj
	End Method


	'returns the next news out of a chain
	Method GetNextNewsEventFromChain:TNewsEvent()
		Local news:TNewsEvent=Null
		'if element is an episode of a chain
		If self.parent
			news = TNewsEvent(self.parent.episodes.ValueAtIndex(Max(0,self.episode -1)))
		'if it is the parent of a chain
		elseif self.episodes.count() > 0
			news = TNewsEvent(self.episodes.ValueAtIndex(0))
		endif
		if news
			news.doHappen()
			Return news
		endif
		'if something strange happens - better return self than nothing
		return self
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


	Method getHappenDelay:int()
		'data is days from now
		if self.happenDelayType = 1 then return self.happenDelayData[0]*60*60*24
		'data is hours from now
		if self.happenDelayType = 2 then return self.happenDelayData[0]*60*60
		'data is days from now at X:00
		if self.happenDelayType = 3
			local time:int = GetWorldTime().MakeTime(GetWorldTime().GetYear(), GetWorldTime().GetDayOfYear() + self.happenDelayData[0], self.happenDelayData[1],0)
			return time - GetWorldTime().getTimeGone()
		endif

		return 0
	End Method


	Method doHappen(time:int = 0)
		'set happened time, add to collection list...
		NewsEventCollection.setNewsHappened(self, time)

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
	

	Method getEpisodesCount:int()
		if self.parent then return self.parent.episodes.Count()
		return self.episodes.Count()
	End Method


	Method IsLastEpisode:int()
		return self.parent<>null and self.episode = self.parent.episodes.count()
	End Method


	Method IsSkippable:int()
		return skippable
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
	Field _customEffectFunc:int(params:TData)


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
		if _customEffectFunc then return _customEffectFunc(params)

		return EffectFunc(params)
	End Method


	'override this function in custom types
	Method EffectFunc:int(params:TData)
		print ToString()
		print "params: "+params.ToString()
	
		return True
	End Method
End Type