Rem
	====================================================================
	code for advertisement-objects in programme planning
	====================================================================

	As we have to know broadcast states (eg. "this spot failed/run OK"),
	we have to create individual "TAdvertisement"/spots.
	This way these objects can store that states.

	Another benefit is: TAdvertisement is "TBroadcastMaterial" which would
	make it exchangeable with other material... This could be eg. used
	to make them placeable as "programme" - which creates shoppingprogramme
	or other things. (while programme as advertisement could generate Trailers)
End Rem
SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.programme.adcontract.bmx"
Import "game.publicimage.bmx"
Import "game.broadcast.genredefinition.movie.bmx"
Import "game.broadcast.base.bmx"


'ad spot
Type TAdvertisement Extends TBroadcastMaterialDefaultImpl {_exposeToLua="selected"}
	Field contract:TAdContract	= Null
	'Eventuell den "state" hier als reine visuelle Hilfe nehmen.
	'Dinge wie "Spot X von Y" koennen auch dynamisch erfragt werden
	'
	'Auch sollte ein AdContract einen Event aussenden, wenn erfolgreich
	'gesendet worden ist ... dann koennen die "GUI"-Bloecke darauf reagieren
	'und ihre Werte aktualisieren

	Method GenerateGUID:string()
		return "broadcastmaterial-advertisement-"+id
	End Method


	Method Create:TAdvertisement(contract:TAdContract)
		self.contract = contract

		self.setMaterialType(TVTBroadcastMaterialType.ADVERTISEMENT)
		'by default a freshly created programme is of its own type
		self.setUsedAsType(TVTBroadcastMaterialType.ADVERTISEMENT)

		self.owner = self.contract.owner

		Return self
	End Method


	'override default getter to make contract id the reference id
	Method GetReferenceID:int() {_exposeToLua}
		return self.contract.id
	End Method


	Method HasSource:int(obj:object) {_exposeToLua}
		if TAdContract(obj)
			return TAdContract(obj) = self.contract
		endif
		return Super.HasSource(obj)
	End Method


	Method GetSource:TBroadcastMaterialSource() {_exposeToLua}
		return self.contract
	End Method


	'override default getter
	Method GetDescription:string() {_exposeToLua}
		Return contract.GetDescription()
	End Method


	'override
	Method SourceHasBroadcastFlag:int(flag:Int) {_exposeToLua}
		return contract.HasBroadcastFlag(flag)
	End Method


	'get the title
	Method GetTitle:string() {_exposeToLua}
		Return contract.GetTitle()
	End Method


	Method GetBlocks:int(broadcastType:int=0) {_exposeToLua}
		Return contract.GetBlocks()
	End Method


	Method IsControllable:int() {_exposeToLua}
		return contract.IsControllable()
	End Method


	'override - return INFOMERCIAL genre
	Method GetGenreDefinition:TGenreDefinitionBase()
		Return GetMovieGenreDefinitionCollection().Get([TVTProgrammeGenre.INFOMERCIAL])
	End Method


	'override
	'add PAID-Flag as set flag
	Method GetFlagsTargetGroupMod:SAudience() override
		local audienceMod:SAudience = New SAudience(1, 1)
		local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.PAID)
		if not definition then return audienceMod

		audienceMod.Multiply( GetFlagTargetGroupMod(definition) )
		audienceMod.CutBorders(0.0, 2.0)

		return audienceMod
	End Method



	'ueberschrieben
	'default implementation
	'limited to 0 - 2.0, 1.0 means "no change"
	Method GetGenreTargetGroupMod:SAudience(definition:TGenreDefinitionBase) override
		'multiply with 0.5 to scale "-2 to +2" down to "-1 to +1"
		'add 1 to get a value between 0 - 2
		Return Super.GetGenreTargetGroupMod(definition)
	End Method


	'add targetgroup bonus so an infomercial based on a contract with
	'"please women" gets a bonus for women
	Method GetTargetGroupAttractivityMod:SAudience() override
		Local result:SAudience = Super.GetTargetGroupAttractivityMod()

		if contract.base.limitedToTargetGroup > 0
			Local tgAudience:SAudience = New SAudience(1, 1)
			'for women/men this only is run for the
			'female/male portion of the audience
			tgAudience.ModifyTotalValue(contract.base.limitedToTargetGroup, 0.5)

			result.Multiply(tgAudience)
		EndIf

		Return result
	End Method


	'override
	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.FinishBroadcasting(day,hour,minute, audienceData)

		'inform contract that it got broadcasted by a player
		contract.doFinishBroadcast(owner, usedAsType)
		if usedAsType = TVTBroadcastMaterialType.PROGRAMME
			FinishBroadcastingAsProgramme(day, hour, minute, audienceData)
'			GetBroadcastInformationProvider().SetInfomercialAired(licence.owner, GetBroadcastInformationProvider().GetInfomercialAired(licence.owner) + 1, GetWorldTime.GetTimeGoneForGameTime(0,day,hour,minute) )

			'inform others
			TriggerBaseEvent(GameEventKeys.Broadcast_Advertisement_FinishBroadcastingAsProgramme, New TData.AddInt("day", day).AddInt("hour", hour).AddInt("minute", minute).Add("audienceData", audienceData), Self)
		elseif usedAsType = TVTBroadcastMaterialType.ADVERTISEMENT
			'nothing happening - ads get paid on "beginBroadcasting"

			'inform others
			TriggerBaseEvent(GameEventKeys.Broadcast_Advertisement_FinishBroadcasting, New TData.AddInt("day", day).AddInt("hour", hour).AddInt("minute", minute).Add("audienceData", audienceData), Self)

			contract.base.SetTimesBroadcasted( contract.base.GetTimesBroadcasted(owner) + 1, owner )
		endif

		return TRUE
	End Method


	'ad got send as infomercial
	Method FinishBroadcastingAsProgramme:int(day:int, hour:int, minute:int, audienceData:object)
		self.SetState(self.STATE_OK)

		'give money
		local audienceResult:TAudienceResult = TAudienceResult(audienceData)
		Local earn:Int = audienceResult.Audience.GetTotalSum() * contract.GetPerViewerRevenue()
		if earn > 0
			TLogger.Log("TAdvertisement.FinishBroadcastingAsProgramme", "Infomercial ~q"+GetTitle()+"~q sent by player "+owner+", earned "+GetFormattedCurrency(earn)+" with an audience of " + audienceResult.Audience.GetTotalSum() +". CPV="+contract.GetPerViewerRevenue() , LOG_DEBUG)
			GetPlayerFinance(owner).EarnInfomercialRevenue(earn, contract)
		elseif earn = 0
			TLogger.Log("TAdvertisement.FinishBroadcastingAsProgramme", "Infomercial ~q"+GetTitle()+"~q sent by player "+owner+", earned nothing with an audience of " + audienceResult.Audience.GetTotalSum() +". CPV="+contract.GetPerViewerRevenue(), LOG_DEBUG)
			'also "earn" 0 Euro - so it is listed in the financial history
			GetPlayerFinance(owner).EarnInfomercialRevenue(earn, contract)
		else
			DebugStop
			Notify "FinishBroadcastingAsProgramme: earn value is negative: "+earn+". Ad: "+GetTitle()+" (player: "+owner+"). audienceTotalSum=" + audienceResult.Audience.GetTotalSum() +"  perVieweRevenue="+contract.GetPerViewerRevenue()
			TLogger.Log("TAdvertisement.FinishBroadcastingAsProgramme", "earn value is negative: "+earn+". Ad: "+GetTitle()+" (player: "+owner+"). audienceTotalSum=" + audienceResult.Audience.GetTotalSum() +"  perVieweRevenue="+contract.GetPerViewerRevenue(), LOG_DEBUG)
		endif
		'adjust topicality relative to possible audience
		contract.base.CutInfomercialTopicality(GetInfomercialTopicalityCutModifier( audienceResult.GetWholeMarketAudienceQuotePercentage()))

		contract.base.SetTimesBroadcastedAsInfomercial( contract.base.GetTimesBroadcastedAsInfomercial(owner) + 1, owner )

		'=== ADJUST CHANNEL IMAGE ===
		'Image-Penalty
		'-1 = for both genders
		TLogger.Log("ChangePublicImage()", "Player #"+owner+": image change for infomercial.", LOG_DEBUG)
		Local penalty:SAudience = New SAudience(-1,  -0.25, -0.25, -0.15, -0.35, -0.15, -0.55, -0.15)
		GetPublicImage(owner).ChangeImage(penalty)
	End Method


	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.BeginBroadcasting(day,hour,minute, audienceData)

		'inform contract that it gets broadcasted by a player
		contract.doBeginBroadcast(owner, self.usedAsType)


		'run as infomercial
		if self.usedAsType = TVTBroadcastMaterialType.PROGRAMME
			'no need to do further checks
			return TRUE
		endif

		local audienceResult:TAudienceResult = TAudienceResult(audienceData)
		if not audienceResult
			print "BeginBroadcasting: audienceResult is null!"
			return False
		endif

		'check if the ad satisfies all requirements
		local successful:int = False
		if "OK" = IsPassingRequirements(audienceResult, GetBroadcastManager().GetCurrentProgrammeBroadcastMaterial(owner))
			successful = True
		endif


		if not successful
			setState(STATE_FAILED)
		Else
			setState(STATE_OK)
			'successful sent - so increase the value the contract
			contract.SetSpotsSent(contract.spotsSent + 1)
			'TLogger.Log("TAdvertisement.BeginBroadcasting", "Player "+contract.owner+" sent SUCCESSFUL spot "+contract.spotsSent+"/"+contract.GetSpotCount()+". Title: "+contract.GetTitle()+". Time: day "+(day-GetWorldTime().GetStartDay())+", "+hour+":"+minute+".", LOG_DEBUG)
		EndIf

		'inform others
		If usedAsType = TVTBroadcastMaterialType.ADVERTISEMENT
			TriggerBaseEvent(GameEventKeys.Broadcast_Advertisement_BeginBroadcasting, New TData.AddInt("day", day).AddInt("hour", hour).AddInt("minute", minute).Add("audienceData", audienceData), Self)
		ElseIf usedAsType = TVTBroadcastMaterialType.PROGRAMME
			TriggerBaseEvent(GameEventKeys.Broadcast_Advertisement_BeginBroadcastingAsProgramme, New TData.AddInt("day", day).AddInt("hour", hour).AddInt("minute", minute).Add("audienceData", audienceData), Self)
		EndIf
		return TRUE
	End Method


	'checks if the contract/ad passes specific requirements
	'-> min audience, target groups, ...
	'returns "OK" when passing, or another String with the reason for failing
	Method IsPassingRequirements:String(audienceResult:TAudienceResult, previouslyRunningBroadcastMaterial:TBroadcastMaterial = Null)
		'checks against audience
		If audienceResult
			'programme broadcasting outage = ad fails too!
			If audienceResult.broadcastOutage
				return "OUTAGE"
			'condition not fulfilled
			ElseIf audienceResult.Audience.GetTotalSum() < contract.GetMinAudience()
				return "SUM"
			'limited to a specific target group - and not fulfilled
			ElseIf contract.GetLimitedToTargetGroup() > 0 and audienceResult.Audience.GetTotalValue(contract.GetLimitedToTargetGroup()) < contract.GetMinAudience()
				return "TARGETGROUP"
			EndIf
		EndIf

		'limited to a specific genre - and not fulfilled
		If contract.GetLimitedToProgrammeGenre() >= 0 or contract.GetLimitedToProgrammeFlag() > 0
			'check current programme of the owner
			'TODO: check if that has flaws playing with high speed
			'      (check if current broadcast is correctly set at this
			'      time)
			'if no previous material was given, use the currently running one
			if not previouslyRunningBroadcastMaterial then previouslyRunningBroadcastMaterial = GetBroadcastManager().GetCurrentProgrammeBroadcastMaterial(owner)

			'should not happen - as it else is a broadcastOutage
			if not previouslyRunningBroadcastMaterial
				Return "OUTAGE"
			else
				local genreDefinition:TGenreDefinitionBase = previouslyRunningBroadcastMaterial.GetGenreDefinition()
				if contract.GetLimitedToProgrammeGenre() >= 0
					if genreDefinition and genreDefinition.referenceId <> contract.GetLimitedToProgrammeGenre()
						Return "GENRE"
					endif
				endif
				if contract.GetLimitedToProgrammeFlag() > 0
					if not (contract.GetLimitedToProgrammeFlag() & previouslyRunningBroadcastMaterial.GetProgrammeFlags())
						Return "FLAGS"
					endif
				endif
			endif
		EndIf

		return "OK"
	End Method


	Method GetInfomercialTopicalityCutModifier:float( audienceQuote:float = 0.5 ) {_exposeToLua}
		'by default, all infomercials would cut their topicality by
		'100% when broadcasted on 100% audience watching
		'but instead of a linear growth, we use the non-linear influence

		'we do want to know what to keep, not what to cut (-> 1.0-x)
		return 1.0 - THelper.ATanFunction(audienceQuote, 3)
	End Method


	'quality when send as programme (infomercial)
	Method GetQuality:Float() {_exposeToLua}
		'a 100% quality compares to a 100% quality movie
		return 1.0 * contract.GetQuality()
	End Method


	Method ShowSheet:int(x:int, y:int, align:Float = 0.5) override
		local minAudienceHightlightType:Int = 0
		If (programmedDay=-1 and programmedHour=-1) or (programmedDay=GetWorldTime().GetDay() and programmedHour=GetWorldTime().GetDayHour())
			local audienceResult:TAudienceResultBase = GetBroadcastManager().GetAudienceResult( owner )
			If audienceResult
				minAudienceHightlightType = +1
				
				If audienceResult.broadcastOutage
					minAudienceHightlightType = -1
				'condition not fulfilled
				ElseIf audienceResult.Audience.GetTotalSum() < contract.GetMinAudience()
					minAudienceHightlightType = -1
				'limited to a specific target group - and not fulfilled
				ElseIf contract.GetLimitedToTargetGroup() > 0 and audienceResult.Audience.GetTotalValue(contract.GetLimitedToTargetGroup()) < contract.GetMinAudience()
					minAudienceHightlightType = -1
				EndIf
			Else
				minAudienceHightlightType = -1
			EndIf
		EndIf



		self.contract.ShowSheet(x, y, align, self.usedAsType, 0, minAudienceHightlightType)
	End Method
End Type