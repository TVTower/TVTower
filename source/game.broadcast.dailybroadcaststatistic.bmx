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
	Field bestAudienceResult:TAudienceResultBase
	Field allAudienceResults:TAudienceResultBase[][4]

	Field bestNewsBroadcast:TBroadcastMaterial
	Field bestNewsAudienceResult:TAudienceResultBase
	Field allNewsAudienceResults:TAudienceResultBase[][4]

	'only stores ONE rank-setup at a time, to save processing time
	Global _cachedRanks:int[] {nosave}
	Global _cachedRanksOwner:int = -1 {nosave}
	Global _cachedRanksHour:int = -1 {nosave}
	Global _cachedNewsRanks:int[] {nosave}
	Global _cachedNewsRanksOwner:int = -1 {nosave}
	Global _cachedNewsRanksHour:int = -1 {nosave}


	Method GetAudienceArrayToUse:TAudienceResultBase[][](broadcastedAsType:int)
		if broadcastedAsType = TBroadcastMaterial.TYPE_NEWSSHOW
			return allNewsAudienceResults
		else
			return allAudienceResults
		endif
	End Method



	Method _SetBroadcastResult:Int(broadcast:TBroadcastMaterial, owner:int, hour:int, audienceResult:TAudienceResultBase, broadcastedAsType:int = 0)
		if hour < 0 then return False
		if owner <= 0 then return False

		'if no audience result was given (outage or something)
		if not audienceResult
			print "DailyBroadcastStaticic: _SetBroadcastResult without valid audienceResult."
			audienceResult = New TAudienceResultBase
		endif

		'do not rely on "broadcast.usedAsType" - broadcast could be "null"
		'in the case of an outage
		local useAllAudiences:TAudienceResultBase[][] = GetAudienceArrayToUse(broadcastedAsType)

		'if no audiences were stored for this owner yet, create a array first
		if not useAllAudiences[owner-1] then useAllAudiences[owner-1] = new TAudienceResultBase[1]
		'resize array if needed
		if useAllAudiences[owner-1].length <= hour then useAllAudiences[owner-1] = useAllAudiences[owner-1][.. hour+1]
		'assign audience
		useAllAudiences[owner-1][hour] = audienceResult

		'store this hours audience as "best audience" if it is higher
		'than previous best-audience. Ignore "no broadcast"-audiences
		'(eg. some sleeping people...)
		if broadcast
			if broadcastedAsType = TBroadcastMaterial.TYPE_NEWSSHOW
				if not bestNewsAudienceResult then bestNewsAudienceResult = new TAudienceResultBase
				if bestNewsAudienceResult.audience.GetSum() < audienceResult.audience.GetSum()
					bestNewsAudienceResult = audienceResult
					bestNewsBroadcast = broadcast
				endif
			else
				if not bestAudienceResult then bestAudienceResult = new TAudienceResultBase
				if bestAudienceResult.audience.GetSum() < audienceResult.audience.GetSum()
					bestAudienceResult = audienceResult
					bestBroadcast = broadcast
				endif
			endif
		endif
			
		return True
	End Method

	
	Method _GetAudience:TAudience(owner:int, hour:int, createIfMissing:int = False, broadcastedAsType:int = 0)
		local result:TAudienceResultBase = _GetAudienceResult(owner, hour, False, broadcastedAsType)
		if not result
			if createIfMissing then return new TAudience
			return null
		else
			return result.audience
		endif
	End Method

	
	Method _GetAudienceResult:TAudienceResultBase(owner:int, hour:int, createIfMissing:int = False, broadcastedAsType:int = 0)
		local useAllAudiences:TAudienceResultBase[][] = GetAudienceArrayToUse(broadcastedAsType)

		if owner <= 0 or owner > useAllAudiences.length or hour > 23 or hour < 0
			if createIfMissing then return new TAudienceResultBase
			return Null
		elseif not useAllAudiences[owner-1] or useAllAudiences[owner-1].length <= hour
			if createIfMissing then return new TAudienceResultBase
			return Null
		endif

		if useAllAudiences[owner-1][hour]
			return useAllAudiences[owner-1][hour]
		else
			return Null
		endif
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
		local useAllAudiences:TAudienceResultBase[][] = GetAudienceArrayToUse(broadcastedAsType)
		For local i:int = EachIn checkPlayers
			For local audienceResult:TAudienceResultBase = EachIn useAllAudiences[i]
				result.Add(audienceResult.audience)
				count :+1
			Next
		Next
		if count > 0 then result.DivideFloat(count)
		return result
	End Method
	

	'returns the best audience result of a specific owner/player
	Method _GetBestAudience:TAudience(owner:Int, broadcastedAsType:int = 0)
		if owner <= 0 then return New TAudience
	
		local result:TAudienceResultBase = _GetBestAudienceResult(owner, broadcastedAsType)
		if result then return result.audience

		return new TAudience
	End Method


	'returns the best audience result of a specific owner/player
	Method _GetBestAudienceResult:TAudienceResultBase(owner:Int, broadcastedAsType:int = 0)
		if owner <= 0 then return New TAudienceResultBase
		
		local result:TAudienceResultBase
		local useAllAudiences:TAudienceResultBase[][] = GetAudienceArrayToUse(broadcastedAsType)
		For local bestAudienceResult:TAudienceResultBase = EachIn useAllAudiences[owner-1]
			if not result
				result = bestAudienceResult
			elseif bestAudienceResult.audience.GetSum() > result.audience.GetSum()
				result = bestAudienceResult
			endif
		Next
		return result
	End Method


	'returns an int array containing the "rank" (1-4) for each target
	'group in the given hour for the given type
	Method _GetAudienceRanking:int[](owner:int, hour:int, broadcastedAsType:int = 0)
		'return cached values if possible
		if broadcastedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			if _cachedRanksHour = hour and _cachedRanksOwner = owner
				return _cachedRanks
			endif
		else
			if _cachedNewsRanksHour = hour and _cachedNewsRanksOwner = owner
				return _cachedNewsRanks
			endif
		endif
		


		local result:int[]
		result = result[..TVTTargetGroup.Count + 1]
	
		'store all available audiences in one list for a later sort
		local availableAudiences:TList = CreateList()
		For local i:int = 1 to 4
			local audience:TAudience = _GetAudience(i, hour, false, broadcastedAsType)
			if not audience then audience = new TAudience
			'fill with player id for identification
			if audience.id <= 0 then audience.id = i

			availableAudiences.AddLast(audience)
		Next

		'sort and store
		For local i:int = 0 to TVTTargetGroup.count
			local groupID:int = TVTTargetGroup.GetAtIndex(i)
			'sort the list descending (biggest value at the top)
			Select groupID
				Case TVTTargetGroup.All
					SortList(availableAudiences, False, TAudience.AllSort)
				Case TVTTargetGroup.Children
					SortList(availableAudiences, False, TAudience.ChildrenSort)
				Case TVTTargetGroup.Teenagers
					SortList(availableAudiences, False, TAudience.TeenagersSort)
				Case TVTTargetGroup.HouseWives
					SortList(availableAudiences, False, TAudience.HouseWivesSort)
				Case TVTTargetGroup.Employees
					SortList(availableAudiences, False, TAudience.EmployeesSort)
				Case TVTTargetGroup.Unemployed
					SortList(availableAudiences, False, TAudience.UnemployedSort)
				Case TVTTargetGroup.Manager
					SortList(availableAudiences, False, TAudience.ManagerSort)
				Case TVTTargetGroup.Pensioners
					SortList(availableAudiences, False, TAudience.PensionersSort)
				Case TVTTargetGroup.Women
					SortList(availableAudiences, False, TAudience.WomenSort)
				Case TVTTargetGroup.Men
					SortList(availableAudiences, False, TAudience.MenSort)
				Default
					Throw "unimplemented audiencegroup: "+ groupID
			EndSelect

			'store the groupID->rank in the result array 
			local rank:int = 1
			For local audience:TAudience = EachIn availableAudiences
				'store rank as the group value
				if audience.id = owner then result[i] = rank
				rank :+1
			Next
		Next

		'cache values
		if broadcastedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			_cachedRanksHour = hour
			_cachedRanksOwner = owner
			_cachedRanks = result
		else
			_cachedNewsRanksHour = hour
			_cachedNewsRanksOwner = owner
			_cachedNewsRanks = result
		endif
		
		return result
	End Method


	Method SetBroadcastResult:Int(broadcast:TBroadcastMaterial, owner:int, hour:int, audienceResult:TAudienceResultBase)
		_SetBroadcastResult(broadcast, owner, hour, audienceResult, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method SetNewsBroadcastResult:Int(broadcast:TBroadcastMaterial, owner:int, hour:int, audienceResult:TAudienceResultBase)
		_SetBroadcastResult(broadcast, owner, hour, audienceResult, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method


	Method GetAudience:TAudience(owner:int, hour:int, createIfMissing:int = False)
		return _GetAudience(owner, hour, createIfMissing, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method GetAudienceResult:TAudienceResultBase(owner:int, hour:int, createIfMissing:int = False)
		return _GetAudienceResult(owner, hour, createIfMissing, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method GetNewsAudience:TAudience(owner:int, hour:int, createIfMissing:int = False)
		return _GetAudience(owner, hour, createIfMissing, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method


	Method GetNewsAudienceResult:TAudienceResultBase(owner:int, hour:int, createIfMissing:int = False)
		return _GetAudienceResult(owner, hour, createIfMissing, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method


	Method GetBestAudience:TAudience(owner:Int)
		return _GetBestAudience(owner, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method GetBestAudienceResult:TAudienceResultBase(owner:Int)
		return _GetBestAudienceResult(owner, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method GetBestNewsAudience:TAudience(owner:Int)
		return _GetBestAudience(owner, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method


	Method GetBestNewsAudienceResult:TAudienceResultBase(owner:Int)
		return _GetBestAudienceResult(owner, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method



	Method GetAverageAudience:TAudience(owner:int = -1)
		return _GetAverageAudience(owner, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method GetAverageNewsAudience:TAudience(owner:int = -1)
		return _GetAverageAudience(owner, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method


	Method GetAudienceRanking:int[](owner:Int, hour:int)
		return _GetAudienceRanking(owner, hour, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method	


	Method GetNewsAudienceRanking:int[](owner:Int, hour:int)
		return _GetAudienceRanking(owner, hour, TBroadcastMaterial.TYPE_NEWSSHOW)
	End Method	
End Type
