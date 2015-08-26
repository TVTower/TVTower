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


	Method CheckHourlyBroadcastingRevenue:int(audience:TAudience)
		if not audience then return False

		'callin-shows earn for each sent block... so BREAKs and FINISHs
		'same for "sponsored" programmes
		if self.usedAsType = TVTBroadcastMaterialType.PROGRAMME
			'fetch the rounded revenue for broadcasting this programme
			Local revenue:Int = audience.GetSum() * Max(0, data.GetPerViewerRevenue())

			if revenue > 0
				'earn revenue for callin-shows
				If data.HasFlag(TVTProgrammeFlag.PAID)
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
		data.CutTrailerTopicality(GetTrailerTopicalityCutModifier(audienceResult.GetWholeMarketAudienceQuote().GetAverage()))
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
		Local popularity:TGenrePopularity = data.GetGenreDefinition().Popularity
		local popData:TData = new TData
		popData.AddNumber("attractionQuality", audienceResult.AudienceAttraction.Quality)
		popData.AddNumber("audienceSum", audienceResult.Audience.GetSum())
		popData.AddNumber("broadcastTopAudience", GetBroadcastManager().GetCurrentBroadcast().TopAudience)

		popularity.FinishBroadcastingProgramme(popData, GetBlocks())
		
		'Image-Strafe
		If data.IsPaid()
			Local penalty:TAudience = TAudience.CreateAndInit(-0.25, -0.25, -0.15, -0.35, -0.15, -0.55, -0.15, -0.15, -0.15)
			penalty.MultiplyFloat(data.blocks)
			GetPublicImageCollection().Get(owner).ChangeImage(penalty)			
		ElseIf data.IsTrash()
			Local penalty:TAudience = TAudience.CreateAndInit(0, 0, +0.2, -0.2, +0.2, -0.5, -0.1, 0, 0)
			penalty.MultiplyFloat(data.blocks)			
			GetPublicImageCollection().Get(owner).ChangeImage(penalty)						
		End If

		'adjust topicality relative to possible audience 
		data.CutTopicality(GetTopicalityCutModifier( audienceResult.GetWholeMarketAudienceQuote().GetAverage()))

		'if someone can watch that movie, increase the aired amount
		data.SetTimesAired(data.GetTimesAired(owner)+1, owner)
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
		Return data.GetTrailerMod().SubtractFloat(1)
	End Method
	

	Method GetMiscMod:TAudience(hour:Int)
		Local result:TAudience = TAudience.CreateAndInitValue(0)

		local flagDefinitions:TMovieFlagDefinition[]
	
		'Genereller Quotenbonus!
		if data.IsLive()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeFlag.LIVE)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				If hour >= 18
					result.Add(TAudience.CreateAndInit(2.5, 2, 2, 3, 2, 2, 2, 2, 2))
				Else
					result.Add(TAudience.CreateAndInit(1, 1, 2, 2, 1.5, 1, 1, 1.5, 1.5))
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
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeFlag.CULTURE)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				result.Add(TAudience.CreateAndInit(-0.7, -0.5, -0.3, -0.3, -0.4, 2, 0, 0, 0))
			endif
		EndIf					
	

		'Verringert die Nachteile des Filmalters. Bonus bei Rentnern. 'Höhere Serientreue bei Serien.
		if data.IsCult()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeFlag.CULT)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				result.Add(TAudience.CreateAndInit(-0.3, 0, 0.15, 0.15, 0.15, 0.15, 0.5, 0.15, 0.15))
			endif
		EndIf
		

		'Bonus bei Arbeitslosen und Hausfrauen. Malus bei Arbeitnehmern und Managern. Trash läuft morgens und mittags gut => Bonus!
		if data.IsTrash()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeFlag.TRASH)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				If hour >= 6 and hour <= 17
					result.Add(TAudience.CreateAndInit(-0.2, 0, 0.5, 0.1, 0.4, -0.9, 0.3, 0, 0))
				Else
					result.Add(TAudience.CreateAndInit(-0.5, -0.5, 0, -0.5, -0.5, -0.7, -0.5, -0.5, -0.5))	
				End If
			endif		
		EndIf	

		
		'Nochmal deutlich verringerter Preis. Verringert die Nachteile des Filmalters. Bonus bei Jugendlichen. Malus bei allen anderen Zielgruppen. Bonus in der Nacht!		
		if data.IsBMovie()
			If hour >= 22 or hour <= 6
				result.Add(TAudience.CreateAndInit(0, 0.5, -0.3, -0.1, 0.1, -0.5, -1, 0, 0))
			Else
				result.Add(TAudience.CreateAndInit(0, 0.2, -0.7, -0.6, -0.5, -0.7, -0.7, -1, -0.5))
			EndIf
		EndIf		

			
		'Kleiner Bonus für Jugendliche, Arbeitnehmer, Arbeitslose, (Männer). Kleiner Malus für Kinder, Hausfrauen, Rentner, (Frauen).
		if data.IsXRated()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeFlag.XRATED)
			'complex implementation
			if definition
				flagDefinitions :+ [definition]
			'simple implementation
			else
				result.Add(TAudience.CreateAndInit(-1, 0.5, -0.2, 0.2, 0.2, 0.1, -0.5, -0.2, 0.3))
			endif
		EndIf


		if data.IsScripted()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeFlag.SCRIPTED)
			if definition
				flagDefinitions :+ [definition]
			else
				'really less interest in paid programming
				'use a really high value until audience flow is corrected
				'for such programmes
				result.Add(TAudience.CreateAndInit(-0.2, -0.1, -0.1, -0.4, -0.6, -0.2, -0.1, -0.1, -0.1))
			endif
		EndIf
		

		if data.IsPaid()
			local definition:TMovieFlagDefinition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeFlag.PAID)
			if definition
				flagDefinitions :+ [definition]
			else
				'really less interest in paid programming
				'use a really high value until audience flow is corrected
				'for such programmes
				result.Add(TAudience.CreateAndInit(-0.5, -0.5, -0.3, -0.5, -0.3, -0.7, -0.3, -0.5, -0.5))
			endif
		EndIf


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

	
	Rem - Neue Variante
	Method GetMiscMod:TAudience(hour:Int)
		Local result:TAudience = TAudience.CreateAndInitValue(0)
	
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
		If block = 1 And lastMovieBlockAttraction and lastNewsBlockAttraction Then 'AudienceFlow
			Return GetAudienceFlowBonusIntern(lastMovieBlockAttraction, result, lastNewsBlockAttraction)
		ElseIf lastMovieBlockAttraction And lastMovieBlockAttraction.AudienceFlowBonus Then
			Return lastMovieBlockAttraction.AudienceFlowBonus.Copy().MultiplyFloat(0.25)
		Else
			Return Null
		EndIf		
	End Method
	

	Function GetAudienceFlowBonusIntern:TAudience(lastMovieBlockAttraction:TAudienceAttraction, currentAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction )
		Local flowModBase:TAudience = new TAudience
		Local flowModBaseTemp:Float

		'AudienceFlow anhand der Differenz und ob steigend oder sinkend. Nur sinkend gibt richtig AudienceFlow
		For Local i:Int = 1 To TVTTargetGroup.count
			Local targetGroupID:int = TVTTargetGroup.GetAtIndex(i)
			Local predecessorValue:Float = Min(lastMovieBlockAttraction.FinalAttraction.GetValue(targetGroupID), lastNewsBlockAttraction.FinalAttraction.GetValue(targetGroupID))
			Local successorValue:Float = currentAttraction.BaseAttraction.GetValue(targetGroupID) 'FinalAttraction ist noch nicht verfügbar. BaseAttraction ist also akzeptabel.

			If (predecessorValue < successorValue) 'Steigende Quote = kaum AudienceFlow
				flowModBaseTemp = predecessorValue * 0.05
			Else 'Sinkende Quote
				flowModBaseTemp = (predecessorValue - successorValue) * 0.75
			Endif

			flowModBase.SetValue(targetGroupID, Max(0.05, flowModBaseTemp))
		Next

		'Wie gut ist der Follower? Gleiche Genre passen perfekt zusammen, aber es gibt auch gute und schlechte Followerer anderer genre
		Local flowMod:TAudience
		If lastMovieBlockAttraction.GenreDefinition Then
			flowMod = lastMovieBlockAttraction.GenreDefinition.GetAudienceFlowMod(currentAttraction.GenreDefinition)
		Else
			flowMod = TAudience.CreateAndInitValue(0) 'Ganze schlechter Follower
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


	Method GetTopicalityCutModifier:float( audienceQuote:float = 0.5 ) {_exposeToLua}
		'by default, all broadcasted programmes would cut their topicality by
		'100% when broadcasted on 100% audience watching
		'but instead of a linear growth, we use the logistical influence
		'to grow fast at the beginning (near 0%), and
		'to grow slower at the end (near 100%)

		rem
		"keepRate" for given quote
		Quote  Strength 3  Strength 2  Strength 1 
		0      1.0000      1.0000      1.0000
		0.01                           0.9903
		0.02                           0.9807
		0.04                           0.9619
		0.06                           0.9434
		0.08                           0.9253
		0.1    0.7435      0.8214      0.9075
		0.2    0.5540      0.6755      0.8239
		0.3    0.4138      0.5561      0.7481
		0.4    0.3100      0.4582      0.6791
		0.5    0.2329      0.3776      0.6163
		0.6    0.1753      0.3112      0.5588
		0.7    0.1319      0.2561      0.5061
		0.8    0.0990      0.2102      0.4576
		0.9    0.0737      0.1718      0.4131
		endrem

		'we do want to know what to keep, not what to cut (-> 1.0-x)
		'strength is 1
		return 1.0 - THelper.LogisticalInfluence_Euler(audienceQuote, 1)
	End Method


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


	Method GetGenreDefinition:TGenreDefinitionBase()
		Return data.GetGenreDefinition()
	End Method
End Type