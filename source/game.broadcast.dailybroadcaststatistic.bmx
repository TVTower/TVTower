SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.audienceresult.bmx"



Type TDailyBroadcastStatisticCollection
	Field statistics:TMap = CreateMap()
	Field time:int = 0
	Global _instance:TDailyBroadcastStatisticCollection

	Function GetInstance:TDailyBroadcastStatisticCollection()
		if not _instance
			_instance = new TDailyBroadcastStatisticCollection
			_instance.Initialize()
		endif
		return _instance
	End Function


	Method Initialize:TDailyBroadcastStatisticCollection()
		statistics.Clear()
		time = MillisecS()

		return self
	End Method


	Method Add:int(statistic:TDailyBroadcastStatistic, day:int)
		statistics.Insert(string(day), statistic)
	End Method


	Method RemoveBeforeDay:int(day:int)
		local removed:int = 0
		For local key:string = Eachin statistics.Keys()
			if int(key) < day
				statistics.Remove(key)
				removed :+ 1
			endif
		Next
		return removed
	End Method


	Method Get:TDailyBroadcastStatistic(day:int, createIfMissing:int = False)
		local stat:TDailyBroadcastStatistic = TDailyBroadcastStatistic(statistics.ValueForKey(string(day)))
		if not stat and createIfMissing
			stat = new TDailyBroadcastStatistic
			Add(stat, day)
		endif
		return stat
	End Method
End Type


Function GetDailyBroadcastStatisticCollection:TDailyBroadcastStatisticCollection()
	Return TDailyBroadcastStatisticCollection.GetInstance()
End Function


Function GetDailyBroadcastStatistic:TDailyBroadcastStatistic(day:int, createIfMissing:int = False)
	Return TDailyBroadcastStatisticCollection.GetInstance().Get(day, createIfMissing)
End Function



Type TDailyBroadcastStatistic
	Field bestBroadcast:TBroadcastMaterial
	Field bestAudience:TAudience
	Field allAudiences:TAudience[][4]

	Field bestNewsBroadcast:TBroadcastMaterial
	Field bestNewsAudience:TAudience
	Field allNewsAudiences:TAudience[][4]


	Method GetAudienceArrayToUse:TAudience[][](broadcastedAsType:int)
		if broadcastedAsType = TBroadcastMaterial.TYPE_NEWSSHOW
			return allNewsAudiences
		else
			return allAudiences
		endif
	End Method



	Method _SetBroadcastResult:Int(broadcast:TBroadcastMaterial, owner:int, hour:int, audience:TAudience, broadcastedAsType:int = 0)
		if hour < 0 then return False
		if owner <= 0 then return False
		'do not rely on "broadcast.usedAsType" - broadcast could be "null"
		'in the case of an outage
		local useAllAudiences:TAudience[][] = GetAudienceArrayToUse(broadcastedAsType)

		'if no audiences were stored for this owner yet, create a array first
		if not useAllAudiences[owner-1] then useAllAudiences[owner-1] = new TAudience[1]
		'resize array if needed
		if useAllAudiences[owner-1].length <= hour then useAllAudiences[owner-1] = useAllAudiences[owner-1][.. hour+1]
		'assign audience
		useAllAudiences[owner-1][hour] = audience

		'store this hours audience as "best audience" if it is higher
		'than previous best-audience
		if broadcast and audience
			if broadcastedAsType = TBroadcastMaterial.TYPE_NEWSSHOW
				if not bestNewsAudience then bestNewsAudience = new TAudience
				if bestNewsAudience.GetSum() < audience.GetSum()
					bestNewsAudience = audience
					bestNewsBroadcast = broadcast
				endif
			else
				if not bestAudience then bestAudience = new TAudience
				if bestAudience.GetSum() < audience.GetSum()
					bestAudience = audience
					bestBroadcast = broadcast
				endif
			endif
		endif
			
		return True
	End Method

	
	Method _GetAudience:TAudience(owner:int, hour:int, createIfMissing:int = False, broadcastedAsType:int = 0)
		local useAllAudiences:TAudience[][] = GetAudienceArrayToUse(broadcastedAsType)

		if owner <= 0 or owner > useAllAudiences.length or hour > 23
			if createIfMissing then return new TAudience
			return Null
		elseif not useAllAudiences[owner-1] or useAllAudiences[owner-1].length <= hour
			if createIfMissing then return new TAudience
			return Null
		endif
		
		return useAllAudiences[owner-1][hour]
	End Method


	'returns the average of that days broadcasts audienceresults for the
	'given player - or all
	Method _GetAverageAudience:TAudience(owner:int = -1, broadcastedAsType:int = 0)
		local checkPlayers:int[]
		if owner <= 0
			checkPlayers = [0,1,2,3]
		else
			checkPlayers = [owner-1]
		endif

		local result:TAudience = new TAudience
		local count:int = 0
		local useAllAudiences:TAudience[][] = GetAudienceArrayToUse(broadcastedAsType)
		For local i:int = EachIn checkPlayers
			For local audience:TAudience = EachIn useAllAudiences[i]
				result.Add(audience)
				count :+1
			Next
		Next
		if count > 0 then result.DivideFloat(count)
		return result
	End Method
	

	'returns the best audience result of a specific owner/player
	Method _GetBestAudience:TAudience(owner:Int, broadcastedAsType:int = 0)
		if owner <= 0 then return New TAudience
		
		local result:TAudience = new TAudience
		local useAllAudiences:TAudience[][] = GetAudienceArrayToUse(broadcastedAsType)
		For local bestAudience:TAudience = EachIn useAllAudiences[owner-1]
			if bestAudience.GetSum() > result.GetSum()
				result = bestAudience
			endif
		Next
		return result
	End Method



	Method SetBroadcastResult:Int(broadcast:TBroadcastMaterial, owner:int, hour:int, audience:TAudience)
		_SetBroadcastResult(broadcast, owner, hour, audience, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method SetNewsBroadcastResult:Int(broadcast:TBroadcastMaterial, owner:int, hour:int, audience:TAudience)
		_SetBroadcastResult(broadcast, owner, hour, audience, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method


	Method GetAudience:TAudience(owner:int, hour:int, createIfMissing:int = False)
		return _GetAudience(owner, hour, createIfMissing, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method GetNewsAudience:TAudience(owner:int, hour:int, createIfMissing:int = False)
		return _GetAudience(owner, hour, createIfMissing, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method


	Method GetBestAudience:TAudience(owner:Int)
		return _GetBestAudience(owner, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method GetBestNewsAudience:TAudience(owner:Int)
		return _GetBestAudience(owner, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method


	Method GetAverageAudience:TAudience(owner:int = -1)
		return _GetAverageAudience(owner, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method GetAverageNewsAudience:TAudience(owner:int = -1)
		return _GetAverageAudience(owner, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method
End Type
