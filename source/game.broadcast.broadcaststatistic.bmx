SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.audienceresult.bmx"


Type TBroadcastStatistic
	Field previousBroadcast:TBroadcastMaterial

	'store best audience for each player
	Field bestAudienceResult:TAudienceResultBase[][4]
	'store last audience for each player
	Field lastAudienceResult:TAudienceResultBase[][4]
	Field bestAudiencePercantage:Float[4]


	Method SetAudienceResult:Int(channelNumber:int, block:int, audienceResult:TAudienceResult)
		if channelNumber <= 0 then return False
		if block <= 0
			print "TBroadcastStatistic.SetAudienceResult() called with block="+block
			debugstop
		endif

		'create/resize if not existing yet
		GetLastAudienceResult(channelNumber, block)
		'assign last audience
		lastAudienceResult[channelNumber-1][block-1] = audienceResult

		'store this blocks audience as "best audience of for this block"
		'if higher than previous best-audience
		if audienceResult
			local best:TAudienceResultBase = GetBestAudienceResult(channelNumber, block)
			if best.audience.GetTotalSum() < audienceResult.audience.GetTotalSum()
				bestAudienceResult[channelNumber-1][block-1] = audienceResult
			endif
			local percentage:Float = audienceResult.GetAudienceQuotePercentage()
			If Not bestAudiencePercantage[channelNumber-1] Or percentage > bestAudiencePercantage[channelNumber-1]
				bestAudiencePercantage[channelNumber-1] = percentage
			EndIf
		endif
			
		return True
	End Method


	'removes all entries of "lastAudienceResult" for a given channelNumber
	Method RemoveLastAudienceResult:Int(channelNumber:Int)
		if GetLastAudienceResult(channelNumber, 1)
			lastAudienceResult[channelNumber-1] = new TAudienceResultBase[1]
		endif
		return True
	End Method


	Method GetBestAudienceResult:TAudienceResultBase(channelNumber:Int, block:int = 1)
		if channelNumber <= 0 then return New TAudienceResultBase
		'if no bestAudience was stored for this channelNumber, create a array first
		if bestAudienceResult.length < channelNumber then bestAudienceResult = bestAudienceResult[.. channelNumber+1]
		if not bestAudienceResult[channelNumber-1] then bestAudienceResult[channelNumber-1] = new TAudienceResultBase[1]

		'specific block audience
		if block > 0
			if bestAudienceResult[channelNumber-1].length < block then bestAudienceResult[channelNumber-1] = bestAudienceResult[channelNumber-1][..block]
			if not bestAudienceResult[channelNumber-1][block-1] then bestAudienceResult[channelNumber-1][block-1] = new TAudienceResultBase
			return bestAudienceResult[channelNumber-1][block-1]
		'return the best of all available blocks
		else
			local result:TAudienceResultBase = new TAudienceResultBase
			For local bestAudience:TAudienceResultBase = EachIn bestAudienceResult[channelNumber-1]
				if result.audience.GetTotalSum() < bestAudience.audience.GetTotalSum()
					result = bestAudience
				endif
			Next
			return result
'		'average audience for all blocks
'		else
'			return TAudienceResultBase.CreateAverage(bestAudienceResult[channelNumber-1])
		endif
	End Method


	Method GetLastAudienceResult:TAudienceResultBase(channelNumber:Int, block:int = 1)
		if channelNumber <= 0 then return New TAudienceResultBase
		'if no bestAudience was stored for this channelNumber, create a array first
		if lastAudienceResult.length < channelNumber then lastAudienceResult = lastAudienceResult[.. channelNumber+1]
		if not lastAudienceResult[channelNumber-1] then lastAudienceResult[channelNumber-1] = new TAudienceResultBase[1]

		'specific block audience
		if block > 0
			if lastAudienceResult[channelNumber-1].length < block then lastAudienceResult[channelNumber-1] = lastAudienceResult[channelNumber-1][..block]
			if not lastAudienceResult[channelNumber-1][block-1] then lastAudienceResult[channelNumber-1][block-1] = new TAudienceResultBase
			return lastAudienceResult[channelNumber-1][block-1]
		'average audience for all blocks
		else
			return TAudienceResultBase.CreateAverage(lastAudienceResult[channelNumber-1])
		endif
	End Method
End Type