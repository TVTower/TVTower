SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.base.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.player.finance.bmx"
Import "game.publicimage.bmx"



'parent of movies, series and so on
Type TProgramme Extends TBroadcastMaterialDefaultImpl {_exposeToLua="selected"}
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
				If data.HasFlag(TProgrammeData.FLAG_PAID)
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
	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		Super.BeginBroadcasting:int(day, hour, minute, audienceResult)

		'remove old "last audience" data to avoid wrong "average values"
		licence.GetBroadcastStatistic().RemoveLastAudienceResult(licence.owner)
		'store audience for this block
		licence.GetBroadcastStatistic().SetAudienceResult(licence.owner, currentBlockBroadcasting, audienceResult)
	End Method


	'override
	Method ContinueBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		Super.ContinueBroadcasting(day, hour, minute, audienceResult)

		'store audience for this block
		licence.GetBroadcastStatistic().SetAudienceResult(licence.owner, currentBlockBroadcasting, audienceResult)
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

		If self.owner > 0 Then 'Möglichkeit für Unit-Tests. Unschön....
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
		'for debug prints:
		'local oldTop:float = data.topicality
		
		'adjust topicality
		data.CutTopicality(GetTopicalityCutModifier())

		'if someone can watch that movie, increase the aired amount
		data.SetTimesAired(data.GetTimesAired(owner)+1, owner)
		'reset trailer count
		data.trailerAiredSinceShown = 0
		'now the trailer is for the next broadcast...
		data.trailerTopicality = 1.0
		'print "aired programme "+GetTitle()+" "+data.GetTimesAired(owner)+"x."

		'print self.GetTitle() + "  finished at day="+day+" hour="+hour+" minute="+minute + " aired="+data.timesAired + " topicality="+data.topicality+" oldTop="+oldTop
	End Method


	Method GetQuality:Float() {_exposeToLua}
		Return data.GetQuality()
	End Method

	'override
	Method GetTrailerMod:TAudience()
		Return data.GetTrailerMod().SubtractFloat(1)
	End Method
	
	Method GetMiscMod:TAudience()
		Return TAudience.CreateAndInitValue(0) 'TODO
	End Method

	Method GetAudienceFlowBonus:TAudience(block:Int, result:TAudienceAttraction, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction)
		If block = 1 And lastMovieBlockAttraction Then 'AudienceFlow
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
		For Local i:Int = 1 To 9 'Für jede Zielgruppe
			Local predecessorValue:Float = Min(lastMovieBlockAttraction.FinalAttraction.GetValue(i), lastNewsBlockAttraction.FinalAttraction.GetValue(i))
			Local successorValue:Float = currentAttraction.BaseAttraction.GetValue(i) 'FinalAttraction ist noch nicht verfügbar. BaseAttraction ist also akzeptabel.

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


	Method GetTopicalityCutModifier:float(hour:int=-1) {_exposeToLua}
		if hour = -1 then hour = GetWorldTime().GetNextHour()
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
		if hour = -1 then hour = GetWorldTime().GetNextHour()
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