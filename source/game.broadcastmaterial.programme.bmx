SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.base.bmx"
Import "game.broadcast.audienceresult.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.player.finance.bmx"
Import "game.publicimage.bmx"
'Import "game.gameevents.bmx"


'parent of movies, series and so on
Type TProgramme Extends TBroadcastMaterialDefaultImpl {_exposeToLua="selected"}
	Field licence:TProgrammeLicence			{_exposeToLua}
	Field data:TProgrammeData				{_exposeToLua}


	Function Create:TProgramme(licence:TProgrammeLicence)
		Local obj:TProgramme = New TProgramme
		obj.licence = licence

		if not licence.isOwnedByPlayer()
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "Creating programme ~q"+licence.GetTitle()+"~q of licence not owned by a player! Report to developers asap.", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
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

		if not isOwnedByPlayer()
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "Finishing programme ~q"+GetTitle()+"~q which is not owned by a player! Report to developers asap.", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
			return False
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
	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceData:object)
		Super.BeginBroadcasting:int(day, hour, minute, audienceData)

		'inform data that it gets broadcasted by a player
		data.doBeginBroadcast(owner, usedAsType)

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

		'check if revenues have to get paid (call-in-shows, sponsorships)
		CheckHourlyBroadcastingRevenue(audienceResult.audience)
	End Method


	Method FinishBroadcastingAsAdvertisement:int(day:int, hour:int, minute:int, audienceData:object)
		self.SetState(self.STATE_OK)
		local audienceResult:TAudienceResult = TAudienceResult(audienceData)
		data.CutTrailerTopicality(GetTrailerTopicalityCutModifier(audienceResult.GetWholeMarketAudienceQuotePercentage()))
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
		popData.AddNumber("broadcastTopAudience", GetBroadcastManager().GetCurrentBroadcast().GetTopAudience())

		popularity.FinishBroadcastingProgramme(popData, GetBlocks())
		
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
		data.CutTopicality(GetTopicalityCutModifier( audienceResult.GetWholeMarketAudienceQuotePercentage()))

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
	Method GetTrailerMod:TAudience()
		print data.GetTrailerMod().SubtractFloat(1).ToString()
		Return data.GetTrailerMod().SubtractFloat(1)
	End Method
	

	Method GetMiscMod:TAudience(hour:Int)
		Local result:TAudience = new TAudience.InitValue(0, 0)

		'for all defined targetgroups, increase interest
		if data.GetTargetGroups() > 0
			local tgAudience:TAudience = new TAudience.InitValue(0, 0)
			For local targetGroup:int = 1 to TVTTargetGroup.count
				local targetGroupID:int = TVTTargetGroup.GetAtIndex(targetGroup)
				if data.HasTargetGroup(targetGroupID)
					'print "GetMiscMod: bonus for: "+ TVTTargetGroup.GetAsString(targetGroupID)

					'for women/men this only is run for the
					'female/male portion of the audience
					tgAudience.ModifyTotalValue(targetGroupID, 1.5)
				endif
			Next
			result.Add(tgAudience)
		endif


		local flagDefinitions:TMovieFlagDefinition[]
	
		'Genereller Quotenbonus!
		if data.IsLive()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.LIVE)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				If hour >= 18
					result.Add(new TAudience.Init(-1,  2.5, 2, 2, 3, 2, 2, 2))
				Else
					result.Add(new TAudience.Init(-1,  1, 1, 2, 2, 1.5, 1, 1))
				EndIf
			endif
		EndIf
				

		'Bonus bei Kindern / Jugendlichen. Malus bei Rentnern / Managern.
		if data.IsAnimation()
			'Da es jetzt doch ein Genre gibt, brauchen wir Animation nicht mehr.
			'Eventuell kann man daraus ein Kids-Genre machen... aber das kann man auch eventuell über Zielgruppen regeln.
			'Dennoch ist Kids wohl besser als Animation. Animation kann nämlich sowohl Southpark als auch Biene Maja sein. Das hat definitiv andere Zielgruppen.
		EndIf		

		
		'Bonus bei Betty und bei Managern
		if data.IsCulture()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.CULTURE)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				result.Add(new TAudience.Init(-1,  -0.7, -0.5, -0.3, -0.3, -0.4, 1, 2))
			endif
		EndIf					
	

		'Verringert die Nachteile des Filmalters. Bonus bei Rentnern. 'Höhere Serientreue bei Serien.
		if data.IsCult()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.CULT)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				result.Add(new TAudience.Init(-1,  -0.3, 0, 0.15, 0.15, 0.15, 0.15, 0.5))
			endif
		EndIf
		

		'Bonus bei Arbeitslosen und Hausfrauen. Malus bei Arbeitnehmern und Managern. Trash läuft morgens und mittags gut => Bonus!
		if data.IsTrash()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.TRASH)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				If hour >= 6 and hour <= 17
					result.Add(new TAudience.Init(-1,  -0.2, 0, 0.5, 0.1, 0.4, -0.9, -0.3))
				Else
					result.Add(new TAudience.Init(-1,  -0.5, -0.5, 0, -0.5, -0.5, -0.7, -0.5))	
				End If
			endif		
		EndIf	

		
		'Nochmal deutlich verringerter Preis. Verringert die Nachteile des Filmalters. Bonus bei Jugendlichen. Malus bei allen anderen Zielgruppen. Bonus in der Nacht!		
		if data.IsBMovie()
			If hour >= 22 or hour <= 6
				result.Add(new TAudience.Init(-1,  0, 0.5, -0.3, -0.1, 0.1, -0.5, -1))
			Else
				result.Add(new TAudience.Init(-1,  0, 0.2, -0.7, -0.6, -0.5, -0.7, -0.7))
			EndIf
		EndIf		

			
		'Kleiner Bonus für Jugendliche, Arbeitnehmer, Arbeitslose, (Männer). Kleiner Malus für Kinder, Hausfrauen, Rentner, (Frauen).
		if data.IsXRated()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.XRATED)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				result.Add(new TAudience.Init(-1,  -1, 0.5, -0.2, 0.2, 0.2, 0.1, -0.5))
			endif
		EndIf


		if data.IsScripted()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.SCRIPTED)
			if definition
				flagDefinitions :+ [definition]
			else
				'really less interest in paid programming
				'use a really high value until audience flow is corrected
				'for such programmes
				result.Add(new TAudience.Init(-1,  -0.2, -0.1, -0.1, -0.4, -0.6, -0.2, -0.1))
			endif
		EndIf
		

		if data.IsPaid()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.PAID)
			if definition
				flagDefinitions :+ [definition]
			else
				'really less interest in paid programming
				'use a really high value until audience flow is corrected
				'for such programmes
				result.Add(new TAudience.Init(-1,  -0.5, -0.5, -0.3, -0.5, -0.3, -0.7, -0.3))
			endif
		EndIf


		if flagDefinitions.length > 0
			local flagAudienceMod:TAudience = new new TAudience.InitValue(0, 0)
			for local definition:TMovieFlagDefinition = Eachin flagDefinitions
				flagAudienceMod.AddFloat( flagPopularityMod(definition) )
				flagAudienceMod.Add( flagTargetGroupMod(definition).MultiplyFloat(1.0 + GetTimeMod(definition, hour)) )
			Next
			flagAudienceMod.DivideFloat(flagDefinitions.length)

			result.Add(flagAudienceMod)
		endif

		
		Return result
	End Method

	
	Rem - Neue Variante
	Method GetMiscMod:TAudience(hour:Int)
		Local result:TAudience = new TAudience.InitValue(0)
	
		if data.IsLive() 'Genereller Quotenbonus!
			If hour >= 18
				result.Add(TAudience.CreateAndInit(2, 2, 2, 2, 2, 2, 2, 2, 2))
			Else
				result.Add(TAudience.CreateAndInit(1, 1, 1.2, 1.2, 1.2, 1, 1, 1.2, 1.2))
			EndIf
		EndIf
		
		if data.IsAnimation() 'Bonus bei Kindern / Jugendlichen. Malus bei Rentnern / Managern.
			'Da es jetzt doch ein Genre gibt, brauchen wir Animation nicht mehr.
			'Eventuell kann man daraus ein Kids-Genre machen... aber das kann man auch eventuell über Zielgruppen regeln.
			'Dennoch ist Kinds wohl besser als Animation. Animation kann nähmlich sowohl Southpark als auch Biene Maja sein. Das hat definitiv andere Zielgruppen.
			
			'If genre <> 3	
			'	If hour >= 7 and hour <= 17 'Laufen Morgens und Mittags bei Kindern gut
			'		result.Add(TAudience.CreateAndInit(1, 0.5, -0.2, -0.4, 0, -0.6, -0.6, 0, 0))
			'	ElseIf hour > 0 and hour < 6 'Laufen auch im Nachtprogramm ganz gut: Dann aber nicht so bei Kindern
			'		result.Add(TAudience.CreateAndInit(0.3, 0.5, -0.6, 0.1, 0.1, -0.2, -1, 0, 0))
			'	Else 'Prime-Time-Animationsfilms, können durchaus funktionieren
			'		result.Add(TAudience.CreateAndInit(1, 0.5, -0.2, -0.1, 0, -0.6, -0.6, 0, 0))
			'	EndIf
			'EndIf
		EndIf
		
		if data.IsCulture() 'Bonus bei Betty und bei Managern
			result.Add(TAudience.CreateAndInit(-2, -1.5, -0.8, -1, -1.2, 1.5, 0.5, 0, 0))
		EndIf					
	
		if data.IsCult() 'Verringert die Nachteile des Filmalters. Bonus bei Rentnern. 'Höhere Serientreue bei Serien.
			result.Add(TAudience.CreateAndInit(-0.3, 0, 0.3, 0.3, 0.2, 0.2, 0.7, 0.2, 0.2))
		EndIf
		
		if data.IsTrash() 'Bonus bei Arbeitslosen und Hausfrauen. Malus bei Arbeitnehmern und Managern. Trash läuft morgens und mittags gut => Bonus!
			If hour >= 6 and hour <= 17
				result.Add(TAudience.CreateAndInit(-0.2, 0, 0.5, 0, 0.5, -1.8, 0.2, 0, 0))
			Else
				result.Add(TAudience.CreateAndInit(-1, -0.5, 0, -1, 0, -2, -0.5, -0.5, -0.5))	
			End If			
		EndIf	
		
		'Nochmal deutlich verringerter Preis. Verringert die Nachteile des Filmalters. Bonus bei Jugendlichen. Malus bei allen anderen Zielgruppen. Bonus in der Nacht!		
		if data.IsBMovie()
			If hour >= 22 or hour <= 6
				result.Add(TAudience.CreateAndInit(0, 0.5, -0.7, -0.3, 0.1, -1, -1.7, 0, 0))
			Else
				result.Add(TAudience.CreateAndInit(0, 0.2, -1.5, -1.5, -1, -1.3, -2, -1, -0.5))
			EndIf
		EndIf		
			
		if data.IsXRated() 'Kleiner Bonus für Jugendliche, Arbeitnehmer, Arbeitslose, (Männer). Kleiner Malus für Kinder, Hausfrauen, Rentner, (Frauen).
			result.Add(TAudience.CreateAndInit(-1, 0.5, -0.2, 0.2, 0.2, 0.1, -0.5, -0.2, 0.3))
		EndIf		

		if data.IsPaid()
			'really less interest in paid programming
			'use a really high value until audience flow is corrected
			'for such programmes
			result.Add(TAudience.CreateAndInit(-0.5, -0.5, -0.3, -1, -0.3, -1.5, -0.5, -0.5, -0.5))
		EndIf
		
		Return result
	End Method	
	Endrem

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
		If lastMovieBlockAttraction.GenreDefinition Then
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
		return 1.0 - THelper.LogisticalInfluence_Euler(audienceQuote, 1)
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
		'show sheet with stats of the broadcast owner, not the current
		'licence owner
		self.licence.ShowSheet(x,y,align, self.usedAsType, owner)
	End Method


	'override
	Method GetGenreDefinition:TGenreDefinitionBase()
		Return data.GetGenreDefinition()
	End Method
End Type