SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.audienceresult.bmx"


Type TBroadcastStatistic
	Field previousBroadcast:TBroadcastMaterial

	'store best audience for each player
	Field bestAudienceResult:TAudienceResultBase[][4]
	'store last audience for each player
	Field lastAudienceResult:TAudienceResultBase[][4]


	Method SetAudienceResult:Int(owner:int, block:int, audienceResult:TAudienceResult)
		if owner <= 0 then return False

		'create/resize if not existing yet
		GetLastAudienceResult(owner, block)
		'assign last audience
		lastAudienceResult[owner-1][block-1] = audienceResult

		'store this blocks audience as "best audience of for this block"
		'if higher than previous best-audience
		if audienceResult
			local best:TAudienceResultBase = GetBestAudienceResult(owner, block)
			if best.audience.GetSum() < audienceResult.audience.GetSum()
				bestAudienceResult[owner-1][block-1] = audienceResult
			endif
		endif
			
		return True
	End Method


	'removes all entries of "lastAudienceResult" for a given owner
	Method RemoveLastAudienceResult:Int(owner:Int)
		if GetLastAudienceResult(owner, 1)
			lastAudienceResult[owner-1] = new TAudienceResultBase[1]
		endif
		return True
	End Method


	Method GetBestAudienceResult:TAudienceResultBase(owner:Int, block:int = 1)
		if owner <= 0 then return New TAudienceResultBase
		'if no bestAudience was stored for this owner, create a array first
		if not bestAudienceResult[owner-1] then bestAudienceResult[owner-1] = new TAudienceResultBase[1]

		'specific block audience
		if block > 0
			if bestAudienceResult[owner-1].length < block then bestAudienceResult[owner-1] = bestAudienceResult[owner-1][..block]
			if not bestAudienceResult[owner-1][block-1] then bestAudienceResult[owner-1][block-1] = new TAudienceResultBase
			return bestAudienceResult[owner-1][block-1]
		'return the best of all available blocks
		else
			local result:TAudienceResultBase = new TAudienceResultBase
			For local bestAudience:TAudienceResultBase = EachIn bestAudienceResult[owner-1]
				if result.audience.GetSum() < bestAudience.audience.GetSum()
					result = bestAudience
				endif
			Next
			return result
'		'average audience for all blocks
'		else
'			return TAudienceResultBase.CreateAverage(bestAudienceResult[owner-1])
		endif
	End Method


	Method GetLastAudienceResult:TAudienceResultBase(owner:Int, block:int = 1)
		if owner <= 0 then return New TAudienceResultBase
		'if no bestAudience was stored for this owner, create a array first
		if not lastAudienceResult[owner-1] then lastAudienceResult[owner-1] = new TAudienceResultBase[1]

		'specific block audience
		if block > 0
			if lastAudienceResult[owner-1].length < block then lastAudienceResult[owner-1] = lastAudienceResult[owner-1][..block]
			if not lastAudienceResult[owner-1][block-1] then lastAudienceResult[owner-1][block-1] = new TAudienceResultBase
			return lastAudienceResult[owner-1][block-1]
		'average audience for all blocks
		else
			return TAudienceResultBase.CreateAverage(lastAudienceResult[owner-1])
		endif
	End Method
End Type
