SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.award.base.bmx"
Import "game.broadcast.base.bmx"
Import "game.broadcastmaterial.base.bmx"

TAwardBaseCollection.AddAwardCreatorFunction(TVTAwardType.GetAsString(TVTAwardType.AUDIENCE), TAwardAudience.CreateAwardAudience )


'AwardAudience:
'Reach the biggest amount of people in your broadcast area.
'Score is given for:
'- reaching good rate of "people" and "people in your
'  broadcasting area" instead of the absolute "AudienceQuote" (people/map)
'  (so during nighttimes lower scores are reached)
'- news audiences are taken into account too
Type TAwardAudience extends TAwardBase
	'how important are news for the award
	Global newsWeight:float = 0.25
	
	Global _eventListeners:TLink[]
	

	Method New()
		awardType = TVTAwardType.AUDIENCE

		'=== REGISTER EVENTS ===
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'scan news shows for culture news
		_eventListeners :+ [ EventManager.registerListenerFunction( "broadcasting.BeforeFinishAllNewsShowBroadcasts", onBeforeFinishAllNewsShowBroadcasts) ]
		'scan programmes for culture-flag
		_eventListeners :+ [ EventManager.registerListenerFunction( "broadcasting.BeforeFinishAllProgrammeBlockBroadcasts", onBeforeFinishAllProgrammeBlockBroadcasts) ]
	End Method


	Function CreateAwardAudience:TAwardAudience()
		return new TAwardAudience
	End Function


	'override
	Method GenerateGUID:string()
		return "awardaudience-"+id
	End Method


	Function onBeforeFinishAllNewsShowBroadcasts:int(triggerEvent:TEventBase)
		local currentAward:TAwardAudience = TAwardAudience(GetAwardBaseCollection().GetCurrentAward())
		if not currentAward then return False

		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))
		For local broadcast:TBroadcastMaterial = EachIn broadcasts
			if not broadcast or broadcast.owner <= 0 then continue
			'ignoring broadcasts - would give others an bonus
			'(player gets 0, all others get scores)
			'if broadcast.SourceHasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORED_BY_AWARDS) then return 0

			local score:int = CalculateNewsShowAudienceResultScore(GetBroadcastManager().GetAudienceResult(broadcast.owner))
			if score = 0 then continue

			currentAward.AdjustScore(broadcast.owner, score)
		Next
	End Function


	Function onBeforeFinishAllProgrammeBlockBroadcasts:int(triggerEvent:TEventBase)
		local currentAward:TAwardAudience = TAwardAudience(GetAwardBaseCollection().GetCurrentAward())
		if not currentAward then return False

		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))
		For local broadcast:TBroadcastMaterial = EachIn broadcasts
			if not broadcast or broadcast.owner <= 0 then continue
			'if broadcast.SourceHasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORED_BY_AWARDS) then return 0

			local score:int = CalculateProgrammeAudienceResultScore(GetBroadcastManager().GetAudienceResult(broadcast.owner))
			if score = 0 then continue

			currentAward.AdjustScore(broadcast.owner, score)
		Next
	End Function


	Function CalculateAudienceResultScoreRaw:Float(audienceResult:TAudienceResult)
		if not audienceResult then return 0


		'calculate score:
		'a perfect audienceresult would give 1000 points
		'- no up or down rating by time of the day

		'local points:Float = 1000 * audienceResult.GetPotentialMaxAudienceQuotePercentage()
		local points:Float = 1000 * audienceResult.GetWholeMarketAudienceQuotePercentage()
		local pointsMod:Float = 1.0
		'print "TAwardAudience: player #"+audienceResult.playerId+" : " +audienceResult.GetTitle() + "  points:" +points +"  audience:"+audienceResult.GetWholeMarketAudienceQuotePercentage()
	
		'calculate final score
		return Max(0, points * pointsMod)
	End Function

	
	Function CalculateProgrammeAudienceResultScore:int(audienceResult:TAudienceResult)
		return int(ceil(CalculateAudienceResultScoreRaw(audienceResult)))
	End Function


	Function CalculateNewsShowAudienceResultScore:int(audienceResult:TAudienceResult)
		return int(ceil(newsWeight * CalculateAudienceResultScoreRaw(audienceResult)))
	End Function
End Type