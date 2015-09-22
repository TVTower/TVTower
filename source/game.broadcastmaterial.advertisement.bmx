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


	'override - return PAID-Flag as genre
	Method GetGenreDefinition:TGenreDefinitionBase()
		Return GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.PAID)
	End Method


	'override - lower interest again (added to genre-interest)
	Method GetMiscMod:TAudience(hour:Int)
		Local result:TAudience = TAudience.CreateAndInitValue(0)
		local flagDefinitions:TMovieFlagDefinition[]

		'infomercials could be "trendy" ... so we check all flags of the
		'infomercials for trends later on
		
		local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.PAID)
		if definition
			flagDefinitions :+ [definition]
		else
			'really less interest in paid programming
			'use a really high value until audience flow is corrected
			'for such programmes
			result.Add(TAudience.CreateAndInit(-0.5, -0.5, -0.3, -0.5, -0.3, -0.7, -0.3, -0.5, -0.5))
		endif


		if flagDefinitions.length > 0
			local flagAudienceMod:TAudience = new TAudience.CreateAndInitValue(0.0)
			for local definition:TMovieFlagDefinition = Eachin flagDefinitions
				flagAudienceMod.AddFloat( flagPopularityMod(definition) )
				flagAudienceMod.Add( flagTargetGroupMod(definition).MultiplyFloat(1.0 + GetTimeMod(definition, hour)) )
			Next
			flagAudienceMod.DivideFloat(flagDefinitions.length)

			result.Add(flagAudienceMod)
		endif
		
		Return result
	End Method


	'override
	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.FinishBroadcasting(day,hour,minute, audienceData)

		'inform contract that it got broadcasted by a player
		contract.doFinishBroadcast(owner, usedAsType)

		if usedAsType = TVTBroadcastMaterialType.PROGRAMME
			FinishBroadcastingAsProgramme(day, hour, minute, audienceData)
'			GetBroadcastInformationProvider().SetInfomercialAired(licence.owner, GetBroadcastInformationProvider().GetInfomercialAired(licence.owner) + 1, GetWorldTime.MakeTime(0,day,hour,minute) )

			'inform others
			EventManager.triggerEvent(TEventSimple.Create("broadcast.advertisement.FinishBroadcastingAsProgramme", New TData.addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute).add("audienceData", audienceData), Self))
		elseif usedAsType = TVTBroadcastMaterialType.ADVERTISEMENT
			'nothing happening - ads get paid on "beginBroadcasting"

			'inform others
			EventManager.triggerEvent(TEventSimple.Create("broadcast.advertisement.FinishBroadcasting", New TData.addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute).add("audienceData", audienceData), Self))

			contract.base.SetTimesBroadcasted( contract.base.GetTimesBroadcasted(owner) + 1, owner )
		endif

		return TRUE
	End Method


	'ad got send as infomercial
	Method FinishBroadcastingAsProgramme:int(day:int, hour:int, minute:int, audienceData:object)
		self.SetState(self.STATE_OK)
		
		'give money
		local audienceResult:TAudienceResult = TAudienceResult(audienceData)
		Local earn:Int = audienceResult.Audience.GetSum() * contract.GetPerViewerRevenue()
		if earn > 0
			TLogger.Log("TAdvertisement.FinishBroadcastingAsProgramme", "Infomercial ~q"+GetTitle()+"~q sent by player "+owner+", earned "+earn+CURRENCYSIGN+" with an audience of " + audienceResult.Audience.GetSum(), LOG_DEBUG)
			GetPlayerFinance(owner).EarnInfomercialRevenue(earn, contract)
		elseif earn = 0
			TLogger.Log("TAdvertisement.FinishBroadcastingAsProgramme", "Infomercial ~q"+GetTitle()+"~q sent by player "+owner+", earned nothing with an audience of " + audienceResult.Audience.GetSum(), LOG_DEBUG)
			'also "earn" 0 Euro - so it is listed in the financial history
			GetPlayerFinance(owner).EarnInfomercialRevenue(earn, contract)
		else
			Notify "FinishBroadcastingAsProgramme: earn value is negative: "+earn+". Ad: "+GetTitle()+" (player: "+owner+")."
		endif
		'adjust topicality relative to possible audience 
		contract.base.CutInfomercialTopicality(GetInfomercialTopicalityCutModifier( audienceResult.GetWholeMarketAudienceQuotePercentage()))


		contract.base.SetTimesBroadcastedAsInfomercial( contract.base.GetTimesBroadcastedAsInfomercial(owner) + 1, owner )
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
			contract.spotsSent:+1
			'TLogger.Log("TAdvertisement.BeginBroadcasting", "Player "+contract.owner+" sent SUCCESSFUL spot "+contract.spotsSent+"/"+contract.GetSpotCount()+". Title: "+contract.GetTitle()+". Time: day "+(day-GetWorldTime().GetStartDay())+", "+hour+":"+minute+".", LOG_DEBUG)
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
			ElseIf audienceResult.Audience.GetSum() < contract.GetMinAudience()
				return "SUM"
			'limited to a specific target group - and not fulfilled
			ElseIf contract.GetLimitedToTargetGroup() > 0 and audienceResult.Audience.GetValue(contract.GetLimitedToTargetGroup()) < contract.GetMinAudience()
				return "TARGETGROUP"
			EndIf
		EndIf

		'limited to a specific genre - and not fulfilled
		If contract.GetLimitedToGenre() >= 0 or contract.GetLimitedToProgrammeFlag() > 0
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
				if contract.GetLimitedToGenre() >= 0
					if genreDefinition and genreDefinition.referenceId <> contract.GetLimitedToGenre()
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
		'but instead of a linear growth, we use the logistical influence
		'to grow fast at the beginning (near 0%), and
		'to grow slower at the end (near 100%)
		return 1.0 - THelper.LogisticalInfluence_Euler(audienceQuote, 1)
	End Method


	Method GetQuality:Float() {_exposeToLua}
		return contract.GetQuality()
	End Method


	Method ShowSheet:int(x:int,y:int,align:int)
		self.contract.ShowSheet(x, y, align, self.usedAsType)
	End Method
End Type