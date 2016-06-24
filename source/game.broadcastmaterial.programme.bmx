SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.base.bmx"
Import "game.broadcast.audienceresult.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.player.finance.bmx"
Import "game.programme.programmeperson.bmx"
Import "game.publicimage.bmx"
'Import "game.gameevents.bmx"


'parent of movies, series and so on
Type TProgramme Extends TBroadcastMaterialDefaultImpl {_exposeToLua="selected"}
	Field licence:TProgrammeLicence			{_exposeToLua}
	Field data:TProgrammeData				{_exposeToLua}
	Field maxWholeMarketAudiencePercentage:Float = 0.0

	Function Create:TProgramme(licence:TProgrammeLicence)
		Local obj:TProgramme = New TProgramme
		obj.licence = licence

		if not licence.isOwnedByPlayer()
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "Creating programme ~q"+licence.GetTitle()+"~q of licence not owned by a player! Report to developers asap.", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
		endif

		if licence.GetSubLicenceCount() > 0
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "Creating programme ~q"+licence.GetTitle()+"~q of header licence! Report to developers asap.", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
			debugstop
			return null
		endif


		'store the owner in that moment (later on it might differ as
		'the player sold a licence while the broadcast stays forever)
		obj.SetOwner(licence.owner)
		obj.data = licence.getData()
		
		obj.setMaterialType(TVTBroadcastMaterialType.PROGRAMME)
		'by default a freshly created programme is of its own type
		obj.setUsedAsType(TVTBroadcastMaterialType.PROGRAMME)

		'someone just gave collection or series header
		if not obj.data then return Null

		Return obj
	End Function


	'override
	Method SourceHasBroadcastFlag:int(flag:Int) {_exposeToLua}
		'do not ask programmedata but licence
		return licence.HasBroadcastFlag(flag)
	End Method


	Method IsControllable:int() {_exposeToLua}
		return licence.IsControllable()
	End Method
	

	Method CheckHourlyBroadcastingRevenue:int(audience:TAudience)
		if not audience then return False

		'callin-shows earn for each sent block... so BREAKs and FINISHs
		'same for "sponsored" programmes
		if self.usedAsType = TVTBroadcastMaterialType.PROGRAMME
			'fetch the rounded revenue for broadcasting this programme
			Local revenue:Int = audience.GetTotalSum() * Max(0, data.GetPerViewerRevenue())

			if revenue > 0
				'earn revenue for callin-shows
				If data.HasFlag(TVTProgrammeDataFlag.PAID)
					GetPlayerFinance(owner).EarnCallerRevenue(revenue, self)
				'all others programmes get "sponsored"
				Else
					GetPlayerFinance(owner).EarnSponsorshipRevenue(revenue, self)
				EndIf
			endif
		endif
	End Method


	'override
	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.FinishBroadcasting(day, hour, minute, audienceData)

		'inform data that it got broadcasted by a player
		data.doFinishBroadcast(owner, usedAsType)

		local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		'calculate outcome for TV
		if data.IsTVDistribution() and data.GetOutcomeTV() < 0
			Local quote:Float = 0
			if audienceResult then quote = audienceResult.GetWholeMarketAudienceQuotePercentage()
			'base it partially on te production (script) outcome but
			'also on the quote achieved on its first broadcast
			'(this makes it dependend on the managers knowledge on when
			' to best send a specific programme genre)
			data.outcomeTV = 0.4 * quote + 0.6 * data.GetOutcome()
		Endif

		

		if not isOwnedByPlayer()
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "Finishing programme ~q"+GetTitle()+"~q which is not owned by a player! Report to developers asap.", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
			return False
		endif


		'store maximum
		if audienceResult
			maxWholeMarketAudiencePercentage = Max(maxWholeMarketAudiencePercentage, audienceResult.GetWholeMarketAudienceQuotePercentage())
		endif
		

		if usedAsType = TVTBroadcastMaterialType.PROGRAMME
			FinishBroadcastingAsProgramme(day, hour, minute, audienceData)
			'aired count is stored in programmedata for now
			'GetBroadcastInformationProvider().SetProgrammeAired(owner, GetBroadcastInformationProvider().GetTrailerAired(owner) + 1, GetWorldTime.MakeTime(0,day,hour,minute) )

			'inform others
			EventManager.triggerEvent(TEventSimple.Create("broadcast.programme.FinishBroadcasting", New TData.addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute).add("audienceData", audienceData), Self))
		'sent a trailer
		elseif usedAsType = TVTBroadcastMaterialType.ADVERTISEMENT
			FinishBroadcastingAsAdvertisement(day, hour, minute, audienceData)

			'inform others
			EventManager.triggerEvent(TEventSimple.Create("broadcast.programme.FinishBroadcastingAsAdvertisement", New TData.addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute).add("audienceData", audienceData), Self))
'			GetBroadcastInformationProvider().SetTrailerAired(owner, GetBroadcastInformationProvider().GetTrailerAired(owner) + 1, GetWorldTime.MakeTime(0,day,hour,minute) )
		else
			self.SetState(self.STATE_OK)
			TLogger.Log("FinishBroadcasting", "Finishing programme broadcast with unknown usedAsType="+usedAsType, LOG_ERROR)
		endif

		return TRUE
	End Method


	'override
	Method AbortBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.AbortBroadcasting(day, hour, minute, audienceData)

		data.doAbortBroadcast(owner, usedAsType)
	End Method	


	'override
	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.BeginBroadcasting:int(day, hour, minute, audienceData)

		'inform data that it gets broadcasted by a player
		data.doBeginBroadcast(owner, usedAsType)

		'reset stat
		maxWholeMarketAudiencePercentage = 0.0

		local audienceResult:TAudienceResult = TAudienceResult(audienceData)


		'only fetch new audience stats when send as programme (ignore trailer)
		if self.usedAsType = TVTBroadcastMaterialType.PROGRAMME
			'remove old "last audience" data to avoid wrong "average values"
			licence.GetBroadcastStatistic().RemoveLastAudienceResult(owner)
			'store audience for this block
			licence.GetBroadcastStatistic().SetAudienceResult(owner, currentBlockBroadcasting, audienceResult)
		endif
	End Method


	'override
	Method ContinueBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.ContinueBroadcasting(day, hour, minute, audienceData)

		local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		'store audience for this block
		licence.GetBroadcastStatistic().SetAudienceResult(owner, currentBlockBroadcasting, audienceResult)
	End Method


	'override
	Method BreakBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.BreakBroadcasting:int(day, hour, minute, audienceData)

		local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		'store maximum
		maxWholeMarketAudiencePercentage = Max(maxWholeMarketAudiencePercentage, audienceResult.GetWholeMarketAudienceQuotePercentage())

		'check if revenues have to get paid (call-in-shows, sponsorships)
		CheckHourlyBroadcastingRevenue(audienceResult.audience)
	End Method


	Method FinishBroadcastingAsAdvertisement:int(day:int, hour:int, minute:int, audienceData:object)
		self.SetState(self.STATE_OK)
		local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		'adjust topicality relative to possible audience
		'do not use "maxWholeMarketAudiencePercentage" here, as a trailer
		'is only send during one block
		data.CutTrailerTopicality(GetTrailerTopicalityCutModifier( audienceResult.GetWholeMarketAudienceQuotePercentage() ))
		data.trailerAired:+1
		data.trailerAiredSinceShown:+1
	End Method


	Method FinishBroadcastingAsProgramme:int(day:int, hour:int, minute:int, audienceData:object)
		if not isOwnedByPlayer()
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "Finishing a programme not owned by a player! Report to developers asap.", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
		endif

		self.SetState(self.STATE_OK)

		local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		'check if revenues have to get paid (call-in-shows, sponsorships)
		CheckHourlyBroadcastingRevenue(audienceResult.audience)

		'adjust trend/popularity
		Local popularity:TGenrePopularity = data.GetGenreDefinition().GetPopularity()
		local popData:TData = new TData
		popData.AddNumber("attractionQuality", audienceResult.AudienceAttraction.Quality)
		popData.AddNumber("audienceSum", audienceResult.Audience.GetTotalSum())
		popData.AddNumber("audienceWholeMarketQuote", audienceResult.GetWholeMarketAudienceQuotePercentage())
		popData.AddNumber("broadcastTopAudience", GetBroadcastManager().GetCurrentBroadcast().GetTopAudience())

		popularity.FinishBroadcastingProgramme(popData, GetBlocks())

		'adjust popularity of cast too
		For local job:TProgrammePersonJob = EachIn data.cast
			local p:TProgrammePerson = GetProgrammePerson(job.personGUID)
			if not p then continue
			TPersonPopularity(p.GetPopularity()).FinishBroadcastingProgramme(popData)
		Next
		
		
		'Image-Strafe
		If data.IsPaid()
			'-1 = for both genders
			Local penalty:TAudience = new TAudience.Init(-1,  -0.25, -0.25, -0.15, -0.35, -0.15, -0.55, -0.15)
			penalty.MultiplyFloat(data.blocks)
			GetPublicImage(owner).ChangeImage(penalty)			
		ElseIf data.IsTrash()
			Local penalty:TAudience = new TAudience.Init(-1,  0, 0, +0.2, -0.2, +0.2, -0.5, -0.1)
			penalty.MultiplyFloat(data.blocks)			
			GetPublicImage(owner).ChangeImage(penalty)						
		End If


		'adjust topicality relative to possible audience
		'using the maximum of all blocks here (as this is the maximum
		'audience knowing about that movie)
		data.CutTopicality(GetTopicalityCutModifier( maxWholeMarketAudiencePercentage ))


		'if someone can watch that movie, increase the aired amount
		'for data and licence
		data.SetTimesBroadcasted(data.GetTimesBroadcasted(owner)+1, owner)
		licence.SetTimesBroadcasted(licence.GetTimesBroadcasted(owner)+1, owner)

		'reset trailer count
		data.trailerAiredSinceShown = 0
		'now the trailer is for the next broadcast...
		'instead of just setting back topicality, just refresh it "once"
		'data.trailerTopicality = 1.0
		data.RefreshTrailerTopicality()
		
		'print "aired programme "+GetTitle()+" "+data.GetTimesAired(owner)+"x."
		'print self.GetTitle() + "  finished at day="+day+" hour="+hour+" minute="+minute + " aired="+data.timesAired + " topicality="+data.topicality+" oldTop="+oldTop
	End Method


	Method GetProgrammeFlags:int() {_exposeToLua}
		Return data.flags
	End Method
	

	Method GetQuality:Float() {_exposeToLua}
		Return data.GetQuality()
	End Method


	'override
	Method GetCastMod:Float()
		local result:Float = 1.0
		'cast popularity has influence of up to 75%
		result :+ 0.75 * data.GetCastPopularity()
		'cast base fame has an influence too (even if unpopular!)
		result :+ 0.25 * data.GetCastFame()
		
		'print "castmod: "+result +"  pop: "+ data.GetCastPopularity()
		return result
	End Method


	'override
	'add targetgroup bonus (25% attractivity bonus)
	Method GetTargetGroupAttractivityMod:TAudience()
		Local result:TAudience = Super.GetTargetGroupAttractivityMod()

		'for all defined targetgroups, increase interest
		If data.GetTargetGroups() > 0
			Local tgAudience:TAudience = New TAudience.InitValue(1, 1)
			For Local targetGroup:Int = 1 To TVTTargetGroup.count
				Local targetGroupID:Int = TVTTargetGroup.GetAtIndex(targetGroup)
				If data.HasTargetGroup(targetGroupID)
					'print "GetMiscMod: bonus for: "+ TVTTargetGroup.GetAsString(targetGroupID)

					'for women/men this only is run for the
					'female/male portion of the audience
					tgAudience.ModifyTotalValue(targetGroupID, 0.5)
				EndIf
			Next
			result.Multiply(tgAudience)
		EndIf

		Return result
	End Method


	'override
	Method GetTrailerMod:TAudience()
		Return data.GetTrailerMod()
	End Method


	'override
	'generate average of all flags
	Method GetFlagsTargetGroupMod:TAudience()
		local definitions:TGenreDefinitionBase[] = _GetFlagDefinitions()
		local audienceMod:TAudience = new TAudience.InitValue(1, 1)

		if definitions.length > 0
			for local definition:TMovieFlagDefinition = Eachin definitions
				audienceMod.Multiply( GetFlagTargetGroupMod(definition) )
			Next
			audienceMod.DivideFloat(definitions.length)
		endif

		audienceMod.CutBordersFloat(0.0, 2.0)
		return audienceMod
	End Method


	'override
	'generate average of all flags
	Method GetFlagsPopularityMod:Float()
		local definitions:TGenreDefinitionBase[] = _GetFlagDefinitions()
		local valueMod:Float = 1.0

		if definitions.length > 0
			for local definition:TMovieFlagDefinition = Eachin definitions
				valueMod :* GetFlagPopularityMod(definition)
			Next
			valueMod :/ definitions.length
		endif

		MathHelper.Clamp(valueMod, 0.0, 2.0)
		return valueMod
	End Method	


	'helper
	Method _GetFlagDefinitions:TGenreDefinitionBase[]()
		local definitions:TMovieFlagDefinition[]
		local definition:TMovieFlagDefinition
	
		'Genereller Quotenbonus!
		if data.IsLive()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.LIVE)
			if definition then definitions :+ [definition]
		EndIf
				

		'Bonus bei Kindern / Jugendlichen. Malus bei Rentnern / Managern.
		if data.IsAnimation()
			'Da es jetzt doch ein Genre gibt, brauchen wir Animation nicht mehr.
			'Eventuell kann man daraus ein Kids-Genre machen... aber das kann man auch eventuell über Zielgruppen regeln.
			'Dennoch ist Kids wohl besser als Animation. Animation kann nämlich sowohl Southpark als auch Biene Maja sein. Das hat definitiv andere Zielgruppen.
		EndIf		

		
		'Bonus bei Betty und bei Managern
		if data.IsCulture()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.CULTURE)
			if definition then definitions :+ [definition]
		EndIf					
	

		'Verringert die Nachteile des Filmalters. Bonus bei Rentnern.
		'Höhere Serientreue bei Serien.
		if data.IsCult()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.CULT)
			if definition then definitions :+ [definition]
		EndIf
		

		'Bonus bei Arbeitslosen und Hausfrauen. Malus bei Arbeitnehmern
		'und Managern. Trash läuft morgens und mittags gut => Bonus!
		if data.IsTrash()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.TRASH)
			if definition then definitions :+ [definition]
		EndIf	

		
		'Nochmal deutlich verringerter Preis. Verringert die Nachteile
		'des Filmalters. Bonus bei Jugendlichen. Malus bei allen anderen
		'Zielgruppen. Bonus in der Nacht!		
		if data.IsBMovie()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.TRASH)
			if definition then definitions :+ [definition]
		EndIf		

			
		'Kleiner Bonus für Jugendliche, Arbeitnehmer, Arbeitslose, Männer.
		'Kleiner Malus für Kinder, Hausfrauen, Rentner, Frauen.
		if data.IsXRated()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.XRATED)
			if definition then definitions :+ [definition]
		EndIf


		if data.IsScripted()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.SCRIPTED)
			if definition then definitions :+ [definition]
		EndIf
		

		if data.IsPaid()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.PAID)
			If definition Then definitions :+ [definition]
		EndIf

		Return definitions
	End Method



	
	Method GetAudienceFlowBonus:TAudience(block:Int, result:TAudienceAttraction, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction)
		'calculate the audienceflow from one programme to another one
		If block = 1 And lastMovieBlockAttraction and lastNewsBlockAttraction
			Return GetAudienceFlowBonusIntern(lastMovieBlockAttraction, result, lastNewsBlockAttraction)
		ElseIf lastMovieBlockAttraction And lastMovieBlockAttraction.AudienceFlowBonus
			Return lastMovieBlockAttraction.AudienceFlowBonus.Copy().MultiplyFloat(0.25)
		Else
			Return Null
		EndIf		
	End Method
	

	Function GetAudienceFlowBonusIntern:TAudience(lastMovieBlockAttraction:TAudienceAttraction, currentAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction )
		Local flowModBase:TAudience = new TAudience
		Local flowModBaseTemp:Float

		'AudienceFlow anhand der Differenz und ob steigend oder sinkend. Nur sinkend gibt richtig AudienceFlow
		For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
			For local genderIndex:int = 0 to 1
				local gender:int = TVTPersonGender.FEMALE
				if genderIndex = 1 then gender = TVTPersonGender.MALE
				Local targetGroupID:int = TVTTargetGroup.GetAtIndex(i)
				Local predecessorValue:Float = Min(lastMovieBlockAttraction.FinalAttraction.GetGenderValue(targetGroupID, gender), lastNewsBlockAttraction.FinalAttraction.GetGenderValue(targetGroupID, gender))
				'FinalAttraction ist noch nicht verfügbar. BaseAttraction ist also akzeptabel.
				Local successorValue:Float = currentAttraction.BaseAttraction.GetGenderValue(targetGroupID, gender)

				If (predecessorValue < successorValue) 'Steigende Quote = kaum AudienceFlow
					flowModBaseTemp = predecessorValue * 0.05
				Else 'Sinkende Quote
					flowModBaseTemp = (predecessorValue - successorValue) * 0.75
				Endif

				flowModBase.SetGenderValue(targetGroupID, Max(0.05, flowModBaseTemp), gender)
			Next
		Next

		'Wie gut ist der Follower? Gleiche Genre passen perfekt zusammen, aber es gibt auch gute und schlechte Followerer anderer genre
		Local flowMod:TAudience
		If lastMovieBlockAttraction.GenreDefinition
			flowMod = lastMovieBlockAttraction.GenreDefinition.GetAudienceFlowMod(currentAttraction.GenreDefinition)
		Else
			flowMod = new TAudience.InitValue(0, 0) 'Ganze schlechter Follower
		EndIf

		'Ermittlung des Maximalwertes für den Bonus. Wird am Schluss gebraucht
		Local flowMaximum:TAudience = currentAttraction.BaseAttraction.Copy()
		flowMaximum.DivideFloat(2)
		flowMaximum.CutMaximum( lastNewsBlockAttraction.FinalAttraction.Copy().DivideFloat(2)) 'Die letzte News-Show gibt an, wie viel überhaupt noch dran sind um in den Flow zu kommen.
		flowMaximum.CutBordersFloat(0.1, 0.35)


		'Der Flow hängt nicht nur von den zuvorigen Zuschauern ab, sondern zum Teil auch von der Qualität des Nachfolgeprogrammes.
		Local attrMod:TAudience = currentAttraction.BaseAttraction.Copy()
		attrMod.DivideFloat(2)
		attrMod.CutBordersFloat(0, 0.6)
		attrMod.AddFloat(0.6) '0.6 - 1.2

		flowModBase.CutMaximum(flowMaximum)
		flowModBase.Multiply(attrMod) '0.6 - 1.2
		flowModBase.Multiply(flowMod) '0.1 - 1
		flowModBase.CutMaximum(flowMaximum)
		Return flowModBase
	End Function


	'for details check game.broadcastmaterial.base.bmx: GetTopicalityCutModifier()
	Method GetTrailerTopicalityCutModifier:float(audienceQuote:Float = 1.0) {_exposeToLua}
		return GetTopicalityCutModifier( audienceQuote )
	End Method


	'override default to use blocksamount of programme instead
	Method GetBlocks:int(broadcastType:int=0) {_exposeToLua}
		'nothing special requested? use the currently used type
		if broadcastType = 0 then broadcastType = usedAsType
		if broadcastType & TVTBroadcastMaterialType.PROGRAMME
			Return data.GetBlocks()
		'trailers are 1 block long
		elseif broadcastType & TVTBroadcastMaterialType.ADVERTISEMENT
			return 1
		endif

		return data.GetBlocks()
	End Method


	'override default getter
	Method GetDescription:string() {_exposeToLua}
		Return data.GetDescription()
	End Method


	'get the title
	Method GetTitle:string() {_exposeToLua}
		Return data.GetTitle()
	End Method


	'override default
	Method GetReferenceID:int() {_exposeToLua}
		return licence.GetReferenceID()
	End Method


	Method GetEpisodeNumber:int() {_exposeToLua}
		if not licence.parentLicenceGUID then return 1
		return licence.GetParentLicence().GetSubLicencePosition(licence)
	End Method


	Method GetEpisodeCount:int() {_exposeToLua}
		if not licence.parentLicenceGUID then return 1
		return licence.GetParentLicence().GetSubLicenceCount()
	End Method


	Method IsSeries:int()
		return self.licence.isEpisode()
	End Method


	Method ShowSheet:int(x:int,y:int,align:int)
		local extra:TData = new TData
		extra.AddNumber("programmedDay", programmedDay)
		extra.AddNumber("programmedHour", programmedHour)

		'show sheet with stats of the broadcast owner, not the current
		'licence owner
		self.licence.ShowSheet(x,y,align, self.usedAsType, owner, extra)
	End Method


	'override
	Method GetGenreDefinition:TGenreDefinitionBase()
		Return data.GetGenreDefinition()
	End Method
End Type