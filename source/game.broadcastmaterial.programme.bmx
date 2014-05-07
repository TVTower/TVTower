SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.base.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.player.finance.bmx"
Import "game.publicimage.bmx"



'parent of movies, series and so on
Type TProgramme Extends TBroadcastMaterial {_exposeToLua="selected"}
	Field licence:TProgrammeLicence			{_exposeToLua}
	Field data:TProgrammeData				{_exposeToLua}


	Function Create:TProgramme(licence:TProgrammeLicence)
		Local obj:TProgramme = New TProgramme
		obj.licence = licence

		obj.owner = licence.owner
		obj.data = licence.getData()

		obj.setMaterialType(TYPE_PROGRAMME)
		'by default a freshly created programme is of its own type
		obj.setUsedAsType(TYPE_PROGRAMME)

		'someone just gave collection or series header
		if not obj.data then return Null

		Return obj
	End Function


	Method CheckHourlyBroadcastingRevenue:int(audienceResult:TAudienceResult)
		if not audienceResult then return False

		'callin-shows earn for each sent block... so BREAKs and FINISHs
		'same for "sponsored" programmes
		if self.usedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			'fetch the rounded revenue for broadcasting this programme
			Local revenue:Int = audienceResult.Audience.GetSum() * Max(0, data.GetPerViewerRevenue())

			if revenue > 0
				'earn revenue for callin-shows
				If data.GetGenre() = TProgrammeData.GENRE_CALLINSHOW
					GetPlayerFinanceCollection().Get(owner).EarnCallerRevenue(revenue, self)
				'all others programmes get "sponsored"
				Else
					GetPlayerFinanceCollection().Get(owner).EarnSponsorshipRevenue(revenue, self)
				EndIf
			endif
		endif
	End Method


	'override
	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		Super.FinishBroadcasting(day, hour, minute, audienceResult)
		if owner <= 0 then return False

		if usedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			FinishBroadcastingAsProgramme(day, hour, minute, audienceResult)
		elseif usedAsType = TBroadcastMaterial.TYPE_ADVERTISEMENT
			FinishBroadcastingAsTrailer(day, hour, minute, audienceResult)
		endif

		return TRUE
	End Method


	'override
	Method BreakBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		Super.BreakBroadcasting:int(day, hour, minute, audienceResult)

		'check if revenues have to get paid (call-in-shows, sponsorships)
		CheckHourlyBroadcastingRevenue(audienceResult)
	End Method


	Method FinishBroadcastingAsTrailer:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		self.SetState(self.STATE_OK)
		data.CutTrailerTopicality(GetTrailerTopicalityCutToFactor())
		data.trailerAired:+1
		data.trailerAiredSinceShown:+1
	End Method


	Method FinishBroadcastingAsProgramme:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		self.SetState(self.STATE_OK)

		If self.owner > 0 Then 'MÃ¶glichkeit fÃ¼r Unit-Tests. UnschÃ¶n...
			'check if revenues have to get paid (call-in-shows, sponsorships)
			CheckHourlyBroadcastingRevenue(audienceResult)

			'adjust trend/popularity
			Local popularity:TGenrePopularity = data.GetGenreDefinition().Popularity
			local data:TData = new TData
			data.AddNumber("attractionQuality", audienceResult.AudienceAttraction.Quality)
			data.AddNumber("audienceSum", audienceResult.Audience.GetSum())
			data.AddNumber("broadcastTopAudience", GetBroadcastManager().GetCurrentBroadcast().TopAudience)

			popularity.FinishBroadcastingProgramme(data, GetBlocks())
		Endif

		'adjust topicality
		data.CutTopicality(GetTopicalityCutModifier())

		'if someone can watch that movie, increase the aired amount
		data.timesAired:+1
		'reset trailer count
		data.trailerAiredSinceShown = 0
		'now the trailer is for the next broadcast...
		data.trailerTopicality = 1.0
		'print "aired programme "+GetTitle()+" "+data.timesAired+"x."
	End Method


	Method GetQuality:Float() {_exposeToLua}
		return data.GetQuality()
	End Method


	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		Local result:TAudienceAttraction = New TAudienceAttraction
		result.BroadcastType = 1
		result.Genre = licence.GetGenre()
		Local genreDefinition:TMovieGenreDefinition = TMovieGenreDefinition(GetGenreDefinition())
		result.GenreDefinition = genreDefinition

		if owner = 0 Then Throw TNullObjectExceptionExt.Create("The programme '" + licence.GetTitle() + "' has no owner.")
		
		If block = 1 Or Not lastMovieBlockAttraction Then
			'1 - QualitÃ¤t des Programms
			result.Quality = GetQuality()

			'2 - Mod: Genre-PopularitÃ¤t / Trend
			result.GenrePopularityMod = Max(-0.5, Min(0.5, genreDefinition.Popularity.Popularity / 100)) 'Popularity => Wert zwischen -50 und +50

			'3 - Genre <> Zielgruppe
			result.GenreTargetGroupMod = genreDefinition.AudienceAttraction.Copy()
			result.GenreTargetGroupMod.MultiplyFloat(1.2)
			result.GenreTargetGroupMod.SubtractFloat(0.6)
			result.GenreTargetGroupMod.CutBordersFloat(-0.6, 0.6)

			'4 - Trailer
			result.TrailerMod = data.GetTrailerMod()
			result.TrailerMod.SubtractFloat(1)

			'5 - Flags und anderes
			result.MiscMod = TAudience.CreateAndInit(1, 1, 1, 1, 1, 1, 1, 1, 1)
			result.MiscMod.SubtractFloat(1)

			'6 - Image
			local pubImage:TPublicImage = GetPublicImageCollection().Get(owner)
			If not pubImage Then Throw TNullObjectExceptionExt.Create("The programme '" + licence.GetTitle() + "' has an owner without publicimage.")

			result.PublicImageMod = pubImage.GetAttractionMods() '0 bis 2
			result.PublicImageMod.MultiplyFloat(0.35)
			result.PublicImageMod.SubtractFloat(0.35)
			result.PublicImageMod.CutBordersFloat(-0.35, 0.35)
		Else
			result.CopyBaseAttractionFrom(lastMovieBlockAttraction)
		Endif

		'7 - Stetige Auswirkungen der Film-Quali. Gute Filme bekommen mehr AttraktivitÃ¤t, schlechte Filme animieren eher zum Umschalten
		If (result.Quality < 0.5)
			result.QualityOverTimeEffectMod = Max(-0.2, Min(0.1, ((result.Quality - 0.5)/3) * (block - 1)))
		Else
			result.QualityOverTimeEffectMod = Max(-0.2, Min(0.1, ((result.Quality - 0.5)/6) * (block - 1)))
		EndIf

		'8 - Genres <> Sendezeit
		result.GenreTimeMod = genreDefinition.TimeMods[hour] - 1 'Genre/Zeit-Mod

		'9 - Zufall
		If withLuckEffect Then
			result.LuckMod = TAudience.CreateAndInitValue(0)
		EndIf

		result.Recalculate()

		'10 - Audience Flow
		If block = 1 And lastMovieBlockAttraction Then 'AudienceFlow
			result.AudienceFlowBonus = GetAudienceFlowBonus(lastMovieBlockAttraction, result, lastNewsBlockAttraction)
		ElseIf lastMovieBlockAttraction And lastMovieBlockAttraction.AudienceFlowBonus Then
			result.AudienceFlowBonus = lastMovieBlockAttraction.AudienceFlowBonus.Copy().MultiplyFloat(0.25)
		EndIf

		result.Recalculate()

		'11 - Sequence
		If withSequenceEffect Then
			Local seqCal:TSequenceCalculation = New TSequenceCalculation
			seqCal.Predecessor = lastNewsBlockAttraction
			seqCal.Successor = result

			If block = 1 And lastMovieBlockAttraction Then 'AudienceFlow
				seqCal.PredecessorShareOnShrink  = TAudience.CreateAndInitValue(0.3)
				seqCal.PredecessorShareOnRise = TAudience.CreateAndInitValue(0.2)
			Else
				seqCal.PredecessorShareOnShrink  = TAudience.CreateAndInitValue(0.4)
				seqCal.PredecessorShareOnRise = TAudience.CreateAndInitValue(0.2)
			End If

			Local seqMod:TAudience = genreDefinition.AudienceAttraction.Copy().DivideFloat(1.3).MultiplyFloat(0.4).AddFloat(0.75) '0.75 - 1.15
			result.SequenceEffect = seqCal.GetSequenceDefault(seqMod, seqMod)

			Local borderMax:TAudience = genreDefinition.AudienceAttraction.Copy().DivideFloat(10).AddFloat(0.1).CutBordersFloat(0.1, 0.2)
			Local borderMin:TAudience = TAudience.CreateAndInitValue(-0.2)
			borderMin.Add(genreDefinition.AudienceAttraction.Copy().DivideFloat(10)) '-2 - -0.7

			result.SequenceEffect.CutBorders(borderMin, borderMax)
		EndIf

		result.Recalculate()

		Return result
	End Method

	Function GetAudienceFlowBonus:TAudience(lastMovieBlockAttraction:TAudienceAttraction, currentAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction )
		Local flowModBase:TAudience = new TAudience
		Local flowModBaseTemp:Float

		'AudienceFlow anhand der Differenz und ob steigend oder sinkend. Nur sinkend gibt richtig AudienceFlow
		For Local i:Int = 1 To 9 'FÃ¼r jede Zielgruppe
			Local predecessorValue:Float = Min(lastMovieBlockAttraction.FinalAttraction.GetValue(i), lastNewsBlockAttraction.FinalAttraction.GetValue(i))
			Local successorValue:Float = currentAttraction.BaseAttraction.GetValue(i) 'FinalAttraction ist noch nicht verfÃ¼gbar. BaseAttraction ist also akzeptabel.

			If (predecessorValue < successorValue) 'Steigende Quote = kaum AudienceFlow
				flowModBaseTemp = predecessorValue * 0.05
			Else 'Sinkende Quote
				flowModBaseTemp = (predecessorValue - successorValue) * 0.75
			Endif

			flowModBase.SetValue(i, Max(0.05, flowModBaseTemp))
		Next

		'Wie gut ist der Follower? Gleiche Genre passen perfekt zusammen, aber es gibt auch gute und schlechte Followerer anderer genre
		Local flowMod:TAudience
		If lastMovieBlockAttraction.GenreDefinition Then
			flowMod = lastMovieBlockAttraction.GenreDefinition.GetAudienceFlowMod(currentAttraction.GenreDefinition)
		Else
			flowMod = TAudience.CreateAndInitValue(0) 'Ganze schlechter Follower
		EndIf

		'Ermittlung des Maximalwertes fÃ¼r den Bonus. Wird am Schluss gebraucht
		Local flowMaximum:TAudience = currentAttraction.BaseAttraction.Copy()
		flowMaximum.DivideFloat(2)
		flowMaximum.CutMaximum( lastNewsBlockAttraction.FinalAttraction.Copy().DivideFloat(2)) 'Die letzte News-Show gibt an, wie viel Ã¼berhaupt noch dran sind um in den Flow zu kommen.
		flowMaximum.CutBordersFloat(0.1, 0.35)


		'Der Flow hÃ¤ngt nicht nur von den zuvorigen Zuschauern ab, sondern zum Teil auch von der QualitÃ¤t des Nachfolgeprogrammes.
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


	Method GetTopicalityCutModifier:float(hour:int=-1) {_exposeToLua}
		if hour = -1 then hour = GetGameTime().getNextHour()
		'during nighttimes 0-5, the cut should be lower
		'so we increase the cutFactor to 1.35
		if hour-1 <= 5
			return 1.35
		elseif hour-1 <= 12
			return 1.2
		else
			return 1.0
		endif
	End Method


	Method GetTrailerTopicalityCutToFactor:float(hour:int=-1) {_exposeToLua}
		if hour = -1 then hour = GetGameTime().getNextHour()
		'during nighttimes 0-5, the cut should be lower
		'so we increase the cutFactor to 1.5
		if hour-1 <= 5
			return 0.99
		elseif hour-1 <= 12
			return 0.95
		else
			return 0.90
		endif
	End Method


	'override default to use blocksamount of programme instead
	Method GetBlocks:int(broadcastType:int=0) {_exposeToLua}
		'nothing special requested? use the currently used type
		if broadcastType = 0 then broadcastType = usedAsType
		if broadcastType & TBroadcastMaterial.TYPE_PROGRAMME
			Return data.GetBlocks()
		'trailers are 1 block long
		elseif broadcastType & TBroadcastMaterial.TYPE_ADVERTISEMENT
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
		if not licence.parentLicence then return 1
		return licence.parentLicence.GetSubLicencePosition(licence)
	End Method


	Method GetEpisodeCount:int() {_exposeToLua}
		if not licence.parentLicence then return 1
		return licence.parentLicence.GetSubLicenceCount()
	End Method


	Method IsSeries:int()
		return self.licence.isEpisode()
	End Method


	Method ShowSheet:int(x:int,y:int,align:int)
		self.licence.ShowSheet(x,y,align, self.usedAsType)
	End Method

	Method GetGenreDefinition:TGenreDefinitionBase()
		Return data.GetGenreDefinition()
	End Method
End Type