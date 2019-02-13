SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.audienceresult.bmx"



Type TDailyBroadcastStatisticCollection
	Field statistics:TMap = CreateMap()
	Field minShowDay:int = 0
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
		minShowDay = 0

		return self
	End Method


	Method Add:int(statistic:TDailyBroadcastStatistic, day:int)
		statistics.Insert(string(day), statistic)
	End Method


	Method RemoveBeforeDay:int(day:int)
		'adjust the earliest day to show
		minShowDay = day

		'avoid concurrent map modification (remove while iterating)
		'and store to-remove-objects in an extra array
		local removed:string[]
		For local key:string = Eachin statistics.Keys()
			if int(key) < day then removed :+ [key]
		Next

		For local key:string = EachIn removed
			statistics.Remove(key)
		Next

		return removed.length
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

	Field allAdAudienceResults:TAudienceResultBase[][4]

	Field bestNewsBroadcast:TBroadcastMaterial
	Field bestNewsAudienceResult:TAudienceResultBase
	Field allNewsAudienceResults:TAudienceResultBase[][4]

	'only stores ONE rank-setup at a time, to save processing time
	Global _cachedRanks:int[] {nosave}
	Global _cachedRanksChannelNumber:int = -1 {nosave}
	Global _cachedRanksHour:int = -1 {nosave}
	Global _cachedNewsRanks:int[] {nosave}
	Global _cachedNewsRanksChannelNumber:int = -1 {nosave}
	Global _cachedNewsRanksHour:int = -1 {nosave}


	Method GetAudienceArrayToUse:TAudienceResultBase[][](broadcastedAsType:int)
		if broadcastedAsType = TVTBroadcastMaterialType.NEWSSHOW
			return allNewsAudienceResults
		elseif broadcastedAsType = TVTBroadcastMaterialType.ADVERTISEMENT
			return allAdAudienceResults
		else
			return allAudienceResults
		endif
	End Method



	Method _SetBroadcastResult:Int(broadcast:TBroadcastMaterial, channelNumber:int, hour:int, audienceResult:TAudienceResultBase, broadcastedAsType:int = 0)
		if hour < 0 then return False
		if channelNumber <= 0 then return False

		'if no audience result was given (outage or something)
		if not audienceResult
			print "DailyBroadcastStaticic: _SetBroadcastResult without valid audienceResult."
			audienceResult = New TAudienceResultBase
		endif

		'do not rely on "broadcast.usedAsType" - broadcast could be "null"
		'in the case of an outage
		local useAllAudiences:TAudienceResultBase[][] = GetAudienceArrayToUse(broadcastedAsType)

		'if no audiences were stored for this channelNumber yet, create a array first
		if not useAllAudiences[channelNumber-1] then useAllAudiences[channelNumber-1] = new TAudienceResultBase[1]
		'resize array if needed
		if useAllAudiences[channelNumber-1].length <= hour then useAllAudiences[channelNumber-1] = useAllAudiences[channelNumber-1][.. hour+1]
		'assign audience
		useAllAudiences[channelNumber-1][hour] = audienceResult

		'store this hours audience as "best audience" if it is higher
		'than previous best-audience. Ignore "no broadcast"-audiences
		'(eg. some sleeping people...)
		if broadcast
			if broadcastedAsType = TVTBroadcastMaterialType.NEWSSHOW
				if not bestNewsAudienceResult then bestNewsAudienceResult = new TAudienceResultBase
				if bestNewsAudienceResult.audience.GetTotalSum() < audienceResult.audience.GetTotalSum()
					bestNewsAudienceResult = audienceResult
					bestNewsBroadcast = broadcast
				endif
			elseif broadcastedAsType = TVTBroadcastMaterialType.PROGRAMME
				if not bestAudienceResult then bestAudienceResult = new TAudienceResultBase
				if bestAudienceResult.audience.GetTotalSum() < audienceResult.audience.GetTotalSum()
					bestAudienceResult = audienceResult
					bestBroadcast = broadcast
				endif
			endif
		endif

		return True
	End Method


	Method _GetAudience:TAudience(channelNumber:int, hour:int, createIfMissing:int = False, broadcastedAsType:int = 0)
		local result:TAudienceResultBase = _GetAudienceResult(channelNumber, hour, False, broadcastedAsType)
		if not result
			if createIfMissing then return new TAudience
			return null
		else
			return result.audience
		endif
	End Method


	Method _GetAudienceResult:TAudienceResultBase(channelNumber:int, hour:int, createIfMissing:int = False, broadcastedAsType:int = 0)
		local useAllAudiences:TAudienceResultBase[][] = GetAudienceArrayToUse(broadcastedAsType)

		if channelNumber <= 0 or channelNumber > useAllAudiences.length or hour > 23 or hour < 0
			if createIfMissing then return new TAudienceResultBase
			return Null
		elseif not useAllAudiences[channelNumber-1] or useAllAudiences[channelNumber-1].length <= hour
			if createIfMissing then return new TAudienceResultBase
			return Null
		endif

		if useAllAudiences[channelNumber-1].length > hour
			return useAllAudiences[channelNumber-1][hour]
		else
			return Null
		endif
	End Method


	'returns the average of that days broadcasts audienceresults for the
	'given player - or all
	Method _GetAverageAudience:TAudience(channelNumber:int = -1, broadcastedAsType:int = 0, hours:int[], hoursMode:int = 1)
		'hoursMode = 1: skip all non-given hours
		'hoursMode = 0: skip the given hours

		local checkPlayers:int[]
		if channelNumber <= 0
			checkPlayers = [0,1,2,3]
		else
			checkPlayers = [channelNumber-1]
		endif

		local result:TAudience = new TAudience
		local count:int = 0
		local useAllAudiences:TAudienceResultBase[][] = GetAudienceArrayToUse(broadcastedAsType)
		For local i:int = EachIn checkPlayers
			local hour:int = 0
			For local audienceResult:TAudienceResultBase = EachIn useAllAudiences[i]
				'skip if hour IS given in the array
				if hoursMode = 0
					if InIntArray(hour, hours)
						hour :+ 1
						continue
					endif
				'skip if hour is NOT given in the array
				elseif hoursMode = 1
					if not InIntArray(hour, hours)
						hour :+ 1
						continue
					endif
				endif


				result.Add(audienceResult.audience)
				count :+1
				hour :+1
			Next
		Next
		if count > 0 then result.DivideFloat(count)
		return result
	End Method


	Function InIntArray:int(number:int, arr:int[])
		if not arr or arr.length = 0 then return False

		For local i:int = EachIn arr
			if i = number then return True
		Next
		return False
	End Function


	'returns the best audience result of a specific channelNumber/player
	Method _GetBestAudience:TAudience(channelNumber:Int, broadcastedAsType:int = 0, hours:int[], hoursMode:int = 1)
		if channelNumber <= 0 then return New TAudience

		local result:TAudienceResultBase = _GetBestAudienceResult(channelNumber, broadcastedAsType, hours, hoursMode)
		if result then return result.audience

		return new TAudience
	End Method


	'returns the best audience result of a specific channelNumber/player
	Method _GetBestAudienceResult:TAudienceResultBase(channelNumber:Int, broadcastedAsType:int = 0, hours:int[], hoursMode:int = 1)
		if channelNumber <= 0 then return New TAudienceResultBase

		local result:TAudienceResultBase
		local useAllAudiences:TAudienceResultBase[][] = GetAudienceArrayToUse(broadcastedAsType)
		local hour:int = 0
		For local bestAudienceResult:TAudienceResultBase = EachIn useAllAudiences[channelNumber-1]
			if hoursMode = 0
				if InIntArray(hour, hours)
					continue
				endif
			'skip if hour is NOT given in the array
			elseif hoursMode = 1
				if not InIntArray(hour, hours)
					continue
				endif
			endif

			if not result
				result = bestAudienceResult
			elseif bestAudienceResult.audience.GetTotalSum() > result.audience.GetTotalSum()
				result = bestAudienceResult
			endif

			hour :+ 1
		Next
		return result
	End Method


	'returns an int array containing the "rank" (1-4) for each target
	'group in the given hour for the given type
	Method _GetAudienceRanking:int[](channelNumber:int, hour:int, broadcastedAsType:int = 0)
		'return cached values if possible
		if broadcastedAsType = TVTBroadcastMaterialType.PROGRAMME
			if _cachedRanksHour = hour and _cachedRanksChannelNumber = channelNumber
				return _cachedRanks
			endif
		'ads could use ranks of programmes
		elseif broadcastedAsType = TVTBroadcastMaterialType.ADVERTISEMENT
			if _cachedRanksHour = hour and _cachedRanksChannelNumber = channelNumber
				return _cachedRanks
			endif
		else
			if _cachedNewsRanksHour = hour and _cachedNewsRanksChannelNumber = channelNumber
				return _cachedNewsRanks
			endif
		endif



		local result:int[]
		result = result[..TVTTargetGroup.Count + 1]

		'store all available audiences in one list for a later sort
		local availableAudiences:TList = CreateList()
		For local i:int = 1 to allAudienceResults.length
			local audience:TAudience = _GetAudience(i, hour, false, broadcastedAsType)
			if not audience then audience = new TAudience
			'fill with channelNumber for identification
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
				if audience.id = channelNumber then result[i] = rank
				rank :+1
			Next
		Next

		'cache values
		if broadcastedAsType = TVTBroadcastMaterialType.PROGRAMME or ..
		   broadcastedAsType = TVTBroadcastMaterialType.ADVERTISEMENT
			_cachedRanksHour = hour
			_cachedRanksChannelNumber = channelNumber
			_cachedRanks = result
		elseif broadcastedAsType = TVTBroadcastMaterialType.NEWSSHOW
			_cachedNewsRanksHour = hour
			_cachedNewsRanksChannelNumber = channelNumber
			_cachedNewsRanks = result
		endif

		return result
	End Method


	Method SetBroadcastResult:Int(broadcast:TBroadcastMaterial, channelNumber:int, hour:int, audienceResult:TAudienceResultBase)
		_SetBroadcastResult(broadcast, channelNumber, hour, audienceResult, TVTBroadcastMaterialType.PROGRAMME)
	End Method


	Method SetNewsBroadcastResult:Int(broadcast:TBroadcastMaterial, channelNumber:int, hour:int, audienceResult:TAudienceResultBase)
		_SetBroadcastResult(broadcast, channelNumber, hour, audienceResult, TVTBroadcastMaterialType.NEWSSHOW)
	End Method


	Method SetAdBroadcastResult:Int(broadcast:TBroadcastMaterial, channelNumber:int, hour:int, audienceResult:TAudienceResultBase)
		_SetBroadcastResult(broadcast, channelNumber, hour, audienceResult, TVTBroadcastMaterialType.ADVERTISEMENT)
	End Method


	Method GetAudience:TAudience(channelNumber:int, hour:int, createIfMissing:int = False)
		return _GetAudience(channelNumber, hour, createIfMissing, TVTBroadcastMaterialType.PROGRAMME)
	End Method


	Method GetAudienceResult:TAudienceResultBase(channelNumber:int, hour:int, createIfMissing:int = False)
		return _GetAudienceResult(channelNumber, hour, createIfMissing, TVTBroadcastMaterialType.PROGRAMME)
	End Method


	Method GetNewsAudience:TAudience(channelNumber:int, hour:int, createIfMissing:int = False)
		return _GetAudience(channelNumber, hour, createIfMissing, TVTBroadcastMaterialType.NEWSSHOW)
	End Method


	Method GetNewsAudienceResult:TAudienceResultBase(channelNumber:int, hour:int, createIfMissing:int = False)
		return _GetAudienceResult(channelNumber, hour, createIfMissing, TVTBroadcastMaterialType.NEWSSHOW)
	End Method


	Method GetAdAudience:TAudience(channelNumber:int, hour:int, createIfMissing:int = False)
		return _GetAudience(channelNumber, hour, createIfMissing, TVTBroadcastMaterialType.ADVERTISEMENT)
	End Method


	Method GetAdAudienceResult:TAudienceResultBase(channelNumber:int, hour:int, createIfMissing:int = False)
		return _GetAudienceResult(channelNumber, hour, createIfMissing, TVTBroadcastMaterialType.ADVERTISEMENT)
	End Method


	Method GetBestAudience:TAudience(channelNumber:Int)
		return _GetBestAudience(channelNumber, TVTBroadcastMaterialType.PROGRAMME, null, 0)
	End Method


	Method GetBestAudienceForHours:TAudience(channelNumber:Int, skipHours:int[])
		return _GetBestAudience(channelNumber, TVTBroadcastMaterialType.PROGRAMME, skipHours, 0)
	End Method


	Method GetBestAudienceResult:TAudienceResultBase(channelNumber:Int)
		return _GetBestAudienceResult(channelNumber, TVTBroadcastMaterialType.PROGRAMME, null, 0)
	End Method


	Method GetBestNewsAudience:TAudience(channelNumber:Int)
		return _GetBestAudience(channelNumber, TVTBroadcastMaterialType.NEWSSHOW, null, 0)
	End Method


	Method GetBestNewsAudienceForHours:TAudience(channelNumber:Int, skipHours:int[])
		return _GetBestAudience(channelNumber, TVTBroadcastMaterialType.NEWSSHOW, skipHours, 0)
	End Method


	Method GetBestNewsAudienceResult:TAudienceResultBase(channelNumber:Int)
		return _GetBestAudienceResult(channelNumber, TVTBroadcastMaterialType.NEWSSHOW, null, 0)
	End Method


	Method GetBestAdAudience:TAudience(channelNumber:Int)
		return _GetBestAudience(channelNumber, TVTBroadcastMaterialType.ADVERTISEMENT, null, 0)
	End Method


	Method GetBestAdAudienceForHours:TAudience(channelNumber:Int, skipHours:int[])
		return _GetBestAudience(channelNumber, TVTBroadcastMaterialType.ADVERTISEMENT, skipHours, 0)
	End Method


	Method GetBestAdAudienceResult:TAudienceResultBase(channelNumber:Int)
		return _GetBestAudienceResult(channelNumber, TVTBroadcastMaterialType.ADVERTISEMENT, null, 0)
	End Method


	Method GetAverageAudience:TAudience(channelNumber:int = -1)
		return _GetAverageAudience(channelNumber, TVTBroadcastMaterialType.PROGRAMME, null, 0)
	End Method


	Method GetAverageAudienceForHours:TAudience(channelNumber:int = -1, hours:int[], skipMode:int = 1)
		return _GetAverageAudience(channelNumber, TVTBroadcastMaterialType.PROGRAMME, hours, skipMode)
	End Method


	Method GetAverageNewsAudience:TAudience(channelNumber:int = -1)
		return _GetAverageAudience(channelNumber, TVTBroadcastMaterialType.NEWSSHOW, null, 0)
	End Method


	Method GetAverageNewsAudienceForHours:TAudience(channelNumber:int = -1, hours:int[], skipMode:int = 1)
		return _GetAverageAudience(channelNumber, TVTBroadcastMaterialType.NEWSSHOW, hours, skipMode)
	End Method


	Method GetAverageAdAudience:TAudience(channelNumber:int = -1)
		return _GetAverageAudience(channelNumber, TVTBroadcastMaterialType.ADVERTISEMENT, null, 0)
	End Method


	Method GetAverageAdAudienceForHours:TAudience(channelNumber:int = -1, hours:int[], skipMode:int = 1)
		return _GetAverageAudience(channelNumber, TVTBroadcastMaterialType.ADVERTISEMENT, hours, skipMode)
	End Method


	Method GetAudienceRanking:int[](channelNumber:Int, hour:int)
		return _GetAudienceRanking(channelNumber, hour, TVTBroadcastMaterialType.PROGRAMME)
	End Method


	Method GetNewsAudienceRanking:int[](channelNumber:Int, hour:int)
		return _GetAudienceRanking(channelNumber, hour, TVTBroadcastMaterialType.NEWSSHOW)
	End Method


	Method GetAdAudienceRanking:int[](channelNumber:Int, hour:int)
		return _GetAudienceRanking(channelNumber, hour, TVTBroadcastMaterialType.ADVERTISEMENT)
	End Method
End Type
