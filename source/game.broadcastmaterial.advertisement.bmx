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
Import "game.broadcastmaterial.base.bmx"
Import "game.programme.adcontract.bmx"
Import "game.publicimage.bmx"
Import "game.broadcast.genredefinition.movie.bmx"


'ad spot
Type TAdvertisement Extends TBroadcastMaterialDefaultImpl {_exposeToLua="selected"}
	Field contract:TAdContract	= Null
	'Eventuell den "state" hier als reine visuelle Hilfe nehmen.
	'Dinge wie "Spot X von Y" koennen auch dynamisch erfragt werden
	'
	'Auch sollte ein AdContract einen Event aussenden, wenn erfolgreich
	'gesendet worden ist ... dann koennen die "GUI"-Bloecke darauf reagieren
	'und ihre Werte aktualisieren

	Global List:TList			= CreateList()


	Method Create:TAdvertisement(contract:TAdContract)
		self.contract = contract

		self.setMaterialType(TYPE_ADVERTISEMENT)
		'by default a freshly created programme is of its own type
		self.setUsedAsType(TYPE_ADVERTISEMENT)

		self.owner = self.contract.owner

		List.AddLast(self)
		Return self
	End Method



	Function GetRandomFromList:TAdvertisement(_list:TList, playerID:Int =-1)
		If _list = Null Then Return Null
		If _list.count() > 0
			Local obj:TAdvertisement = TAdvertisement(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If obj <> Null
				obj.owner = playerID
				Return obj
			EndIf
		EndIf
		Print "TAdvertisement list empty - wrong filter ?"
		Return Null
	End Function


	'override default getter to make contract id the reference id
	Method GetReferenceID:int() {_exposeToLua}
		return self.contract.id
	End Method


	'override default getter
	Method GetDescription:string() {_exposeToLua}
		Return contract.GetDescription()
	End Method


	'get the title
	Method GetTitle:string() {_exposeToLua}
		Return contract.GetTitle()
	End Method


	Method GetBlocks:int(broadcastType:int=0) {_exposeToLua}
		Return contract.GetBlocks()
	End Method


rem
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False )
		'TODO: @Manuel - hier brauchen wir eine geeignete Berechnung :D
		If lastMovieBlockAttraction then return lastMovieBlockAttraction

		Local result:TAudienceAttraction = New TAudienceAttraction
		result.BroadcastType = 1
		result.Genre = 20 'paid programming
		Local genreDefinition:TMovieGenreDefinition = GetMovieGenreDefinitionCollection().Get(result.Genre)

		'copied and adjusted from "programme"
		If block = 1 Then
			'1 - Qualität des Programms
			result.Quality = GetQuality()

			'2 - Mod: Genre-Popularität / Trend
			result.GenrePopularityMod = (genreDefinition.Popularity.Popularity / 100) 'Popularity => Wert zwischen -50 und +50

			'3 - Genre <> Zielgruppe
			result.GenreTargetGroupMod = genreDefinition.AudienceAttraction.Copy()
			result.GenreTargetGroupMod.SubtractFloat(0.5)

			'4 - Image
			result.PublicImageMod = GetPublicImageCollection().Get(owner).GetAttractionMods()
			result.PublicImageMod.SubtractFloat(1)

			'5 - Trailer - gibt es nicht fuer Werbesendungen (die
			'              waeren ja dann wieder Werbung)

			'6 - Flags
			result.MiscMod = TAudience.CreateAndInit(1, 1, 1, 1, 1, 1, 1, 1, 1)
			result.MiscMod.SubtractFloat(1)

			'result.CalculateBaseAttraction()
		Else
			result.CopyBaseAttractionFrom(lastMovieBlockAttraction)
		Endif

		'8 - Stetige Auswirkungen der Film-Quali. Gute Filme bekommen mehr Attraktivität, schlechte Filme animieren eher zum Umschalten
		result.QualityOverTimeEffectMod = ((result.Quality - 0.5)/2.5) * (block - 1)

		'9 - Genres <> Sendezeit
		result.GenreTimeMod = genreDefinition.TimeMods[hour] - 1 'Genre/Zeit-Mod

		'10 - News-Mod
		'result.NewsShowBonus = lastNewsBlockAttraction.Copy().MultiplyFloat(0.2)

		'result.CalculateBlockAttraction()

		'result.SequenceEffect = genreDefinition.GetSequence(lastNewsBlockAttraction, result, 0.1, 0.5)

		result.Recalculate()

		Return result
	End Method
endrem

	'override
	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		Super.FinishBroadcasting(day,hour,minute, audienceResult)

		if usedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			FinishBroadcastingAsProgramme(day, hour, minute, audienceResult)
		elseif usedAsType = TBroadcastMaterial.TYPE_ADVERTISEMENT
			'nothing happening - ads get paid on "beginBroadcasting"
		endif

		return TRUE
	End Method


	'ad got send as infomercial
	Method FinishBroadcastingAsProgramme:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		self.SetState(self.STATE_OK)
		'give money
		Local earn:Int = audienceResult.Audience.GetSum() * contract.GetPerViewerRevenue()
		TLogger.Log("TAdvertisement.FinishBroadcastingAsProgramme", "Infomercial sent, earned "+earn+CURRENCYSIGN+" with an audience of " + audienceResult.Audience.GetSum(), LOG_DEBUG)
		GetPlayerFinanceCollection().Get(owner).EarnInfomercialRevenue(earn, contract)

		'reduce topicality for infomercials
		contract.base.CutInfomercialTopicality(GetInfomercialTopicalityCutModifier())
	End Method


	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		Super.BeginBroadcasting(day,hour,minute, audienceResult)
		'run as infomercial
		if self.usedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			'no need to do further checks
			return TRUE
		endif

		'ad failed (audience lower than needed)
		If audienceResult.Audience.GetSum() < contract.GetMinAudience()
			setState(STATE_FAILED)
			'TLogger.Log("TAdvertisement.BeginBroadcasting", "Player "+contract.owner+" sent FAILED spot "+contract.spotsSent+"/"+contract.GetSpotCount()+". Title: "+contract.GetTitle()+". Time: day "+(day-GetGameTime().GetStartDay())+", "+hour+":"+minute+".", LOG_DEBUG)
		'ad is ok
		Else
			setState(STATE_OK)
			'successful sent - so increase the value the contract
			contract.spotsSent:+1
			'TLogger.Log("TAdvertisement.BeginBroadcasting", "Player "+contract.owner+" sent SUCCESSFUL spot "+contract.spotsSent+"/"+contract.GetSpotCount()+". Title: "+contract.GetTitle()+". Time: day "+(day-GetGameTime().GetStartDay())+", "+hour+":"+minute+".", LOG_DEBUG)

			'successful sent all needed spots?
			If contract.isSuccessful()
				TLogger.Log("TAdvertisement.BeginBroadcasting", "Player "+contract.owner+" finished ad contract, earned "+contract.GetProfit()+CURRENCYSIGN+" with an audience of "+ audienceResult.audience.GetSum(), LOG_DEBUG)
				'give money
				GetPlayerFinanceCollection().Get(owner, day).EarnAdProfit(contract.GetProfit(), contract)
			EndIf
		EndIf
		return TRUE
	End Method


	Method GetInfomercialTopicalityCutModifier:float(hour:int=-1) {_exposeToLua}
		if hour = -1 then hour = GetGameTime().getNextHour()
		'during nighttimes 0-5, the cut should be lower
		'so we increase the cutFactor to 1.35
		if hour-1 <= 5
			return 0.99
		elseif hour-1 <= 12
			return 0.95
		else
			return 0.90
		endif
	End Method



	Method GetQuality:Float() {_exposeToLua}
		return contract.GetQuality()
	End Method


	Method ShowSheet:int(x:int,y:int,align:int)
		self.contract.ShowSheet(x, y, align, self.usedAsType)
	End Method
End Type