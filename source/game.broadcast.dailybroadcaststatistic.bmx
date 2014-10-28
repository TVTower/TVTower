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
			_instance.time = MillisecS()
		endif
		return _instance
	End Function


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


	Method SetBroadcastResult:Int(broadcast:TBroadcastMaterial, owner:int, hour:int, audience:TAudience)
		if hour < 0 then return False
		if owner <= 0 then return False

		'if no audiences were stored for this owner yet, create a array first
		if not allAudiences[owner-1] then allAudiences[owner-1] = new TAudience[1]
		'resize array if needed
		if allAudiences[owner-1].length <= hour then allAudiences[owner-1] = allAudiences[owner-1][.. hour+1]
		'assign audience
		allAudiences[owner-1][hour] = audience

		'store this hours audience as "best audience" if it is higher
		'than previous best-audience
		if broadcast and audience
			if not bestAudience then bestAudience = new TAudience
			if bestAudience.GetSum() < audience.GetSum()
				bestAudience = audience
				bestBroadcast = broadcast
			endif
		endif
			
		return True
	End Method


	'returns the average of that days broadcasts audienceresults for the
	'given player - or all
	Method GetAverageAudience:TAudience(owner:int = -1)
		local checkPlayers:int[]
		if owner <= 0
			checkPlayers = [0,1,2,3]
		else
			checkPlayers = [owner-1]
		endif

		local result:TAudience = new TAudience
		local count:int = 0
		For local i:int = EachIn checkPlayers
			For local audience:TAudience = EachIn allAudiences[i]
				result.Add(audience)
				count :+1
			Next
		Next
		if count > 0 then result.DivideFloat(count)
		return result
	End Method
	

	'returns the best audience result of a specific owner/player
	Method GetBestAudience:TAudience(owner:Int)
		if owner <= 0 then return New TAudience
		
		local bestResult:TAudience = new TAudience
		local result:TAudience = new TAudience
		For local bestAudience:TAudience = EachIn allAudiences[owner-1]
			if result.GetSum() > bestResult.GetSum()
				bestResult = result
			endif
		Next
		return result
	End Method
End Type
