Rem
	===========================================================
	Diese Klasse ist der Manager der ganzen Broadcast-Thematik.
	===========================================================

	Von diesem Manager aus wird der Broadcast (TBroadcast) angestoßen.
	Der Broadcast führt wiederum die Berechnung der Einschaltquoten für
	alle Spieler durch bzw. deligiert sie an die Unterklasse
	"TAudienceMarketCalculation".
	Zudem bewahrt der TBroadcastManager die GenreDefinitionen auf.
	Eventuell gehören diese aber in eine andere Klasse.
EndRem
SuperStrict
Import "game.broadcast.audience.bmx"
Import "game.broadcast.audienceattraction.bmx"
Import "game.broadcast.audienceresult.bmx"
Import "game.broadcast.genredefinition.movie.bmx"
Import "game.broadcast.genredefinition.news.bmx"
Import "game.modifier.base.bmx"
Import "game.publicimage.bmx"
Import "game.stationmap.bmx"
Import "game.world.worldtime.bmx"


Type TBroadcastManager
	Field initialized:Int = False

	'Referenzen
'hier auf GUID
	Field newsGenreDefinitions:TNewsGenreDefinition[]		'TODO: Gehört woanders hin

	Field audienceResults:TAudienceResult[]

	'the current broadcast of each player, split by type
	Field currentAdvertisementBroadcastMaterial:TBroadcastMaterial[]
	Field currentProgrammeBroadcastMaterial:TBroadcastMaterial[]
	Field currentNewsShowBroadcastMaterial:TBroadcastMaterial[]

	'Für die Manipulationen von außen... funktioniert noch nicht
	Field PotentialAudienceManipulations:TMap = CreateMap()

	Field Sequence:TBroadcastSequence = New TBroadcastSequence

	Global _instance:TBroadcastManager


	Function GetInstance:TBroadcastManager()
		If Not _instance Then _instance = New TBroadcastManager
		Return _instance
	End Function

	'===== Konstrukor, Speichern, Laden =====

	'reinitializes the manager
	Method Reset()
		initialized = False
		Initialize()
	End Method


	Method Initialize()
		If initialized Then Return

		'load and init the genres
'		GetMovieGenreDefinitionCollection().Initialize()
'		GetNewsGenreDefinitionCollection().Initialize()

		initialized = True
	End Method


	'===== Öffentliche Methoden =====

	Method GetCurrentBroadcast:TBroadcast()
		Return Sequence.GetCurrentBroadcast()
	End Method


	'Führt die Berechnung für die Einschaltquoten der Sendeblöcke durch
	Method BroadcastProgramme(day:Int=-1, hour:Int, recompute:Int = 0, bc:TBroadcast = Null)
		BroadcastCommon(day, hour, TVTBroadcastMaterialType.PROGRAMME, recompute, bc)

		'assign current programme broadcastmaterial
		currentProgrammeBroadcastMaterial = GetCurrentBroadcast().PlayersBroadcasts
	End Method


	'Führt die Berechnung für die Nachrichten(-Show)-Ausstrahlungen durch
	Method BroadcastNewsShow(day:Int=-1, hour:Int, recompute:Int = 0)
		BroadcastCommon(day, hour, TVTBroadcastMaterialType.NEWSSHOW, recompute)
	End Method


	Method GetNewsGenreDefinition:TNewsGenreDefinition(genreId:Int)
		Return newsGenreDefinitions[genreId]
	End Method


	Method GetCurrentProgrammeBroadcastMaterial:TBroadcastMaterial(playerID:Int)
		If playerID <= 0 Or playerID > currentProgrammeBroadcastMaterial.length Then Return Null

		Return currentProgrammeBroadcastMaterial[playerID-1]
	End Method


	Method SetCurrentProgrammeBroadcastMaterial:Int(playerID:Int, material:TBroadcastMaterial)
		If playerID <= 0 Then Return False

		If playerID > currentProgrammeBroadcastMaterial.length Then currentProgrammeBroadcastMaterial = currentProgrammeBroadcastMaterial[..playerID]
		currentProgrammeBroadcastMaterial[playerID-1] = material
		Return True
	End Method


	Method GetCurrentNewsShowBroadcastMaterial:TBroadcastMaterial(playerID:Int)
		If playerID <= 0 Or playerID > currentNewsShowBroadcastMaterial.length Then Return Null

		Return currentNewsShowBroadcastMaterial[playerID-1]
	End Method


	Method SetCurrentNewsShowBroadcastMaterial:Int(playerID:Int, material:TBroadcastMaterial)
		If playerID <= 0 Then Return False

		If playerID > currentNewsShowBroadcastMaterial.length Then currentNewsShowBroadcastMaterial = currentNewsShowBroadcastMaterial[..playerID]
		currentNewsShowBroadcastMaterial[playerID-1] = material
		Return True
	End Method


	Method GetCurrentAdvertisementBroadcastMaterial:TBroadcastMaterial(playerID:Int)
		If playerID <= 0 Or playerID > currentAdvertisementBroadcastMaterial.length Then Return Null

		Return currentAdvertisementBroadcastMaterial[playerID-1]
	End Method


	Method SetCurrentAdvertisementBroadcastMaterial:Int(playerID:Int, material:TBroadcastMaterial)
		If playerID <= 0 Then Return False

		If playerID > currentAdvertisementBroadcastMaterial.length Then currentAdvertisementBroadcastMaterial = currentAdvertisementBroadcastMaterial[..playerID]
		currentAdvertisementBroadcastMaterial[playerID-1] = material
		Return True
	End Method


	Method GetCurrentBroadcastMaterial:TBroadcastMaterial[](broadcastedAsType:Int)
		Select broadcastedAsType
			Case TVTBroadcastMaterialType.NEWSSHOW
				Return currentNewsShowBroadcastMaterial
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				Return currentAdvertisementBroadcastMaterial
			Default
				Return currentProgrammeBroadcastMaterial
		End Select
	End Method


	Method SetCurrentBroadcastMaterial:Int(playerID:Int, material:TBroadcastMaterial, broadcastedAsType:Int)
		If playerID <= 0 Then Return False

		Select broadcastedAsType
			Case TVTBroadcastMaterialType.NEWSSHOW
				Return SetCurrentNewsShowBroadcastMaterial(playerID, material)
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				Return SetCurrentAdvertisementBroadcastMaterial(playerID, material)
			Default
				Return SetCurrentProgrammeBroadcastMaterial(playerID, material)
		End Select

		Return True
	End Method

	'===== Manipulationen =====

	'sets the current broadcast as malfunction
	Method SetBroadcastMalfunction:Int(playerID:Int, broadcastType:Int = -1)
		'adjust what is broadcasted now
		'to do this we need to know what kind of broadcast this was
		If broadcastType = -1 Then broadcastType = TVTBroadcastMaterialType.PROGRAMME
		SetCurrentBroadcastMaterial(playerID, Null, broadcastType)

		GetCurrentBroadcast().PlayersBroadcasts = GetCurrentBroadcastMaterial(broadcastType)
		'recalculate the players audience
		ReComputePlayerAudience(playerID)

		'inform audienceresult that this is a outage
		Local result:TAudienceResult = GetCurrentBroadcast().GetAudienceResult(playerID)
		If result
			result.broadcastOutage = True
			GetCurrentBroadcast().SetAudienceResult(playerID, result)
		EndIf
	End Method


	'recalculates the audience of the given player
	'other players DO NOT get adjusted (audience is "lost", not transferred)
	Method ReComputePlayerAudience:Int(playerID:Int)
		GetCurrentBroadcast().ReComputeAudienceOnlyForPlayer(playerID, Sequence.GetBeforeProgrammeBroadcast(), Sequence.GetBeforeNewsShowBroadcast())
		SetAudienceResult(playerID, GetCurrentBroadcast().GetAudienceResult(playerID))
	End Method


	'===== Hilfsmethoden =====

	Method GetAudienceResult:TAudienceResult(playerID:Int)
		If playerID <= 0 Or playerID > audienceResults.length Then Return Null
		Return audienceResults[playerID-1]
	End Method


	Method SetAudienceResult:Int(playerID:Int, audienceResult:TAudienceResult)
		If playerID <= 0 Then Return False

		If playerID > audienceResults.length Then audienceResults = audienceResults[..playerID]

		If audienceResult.AudienceAttraction
			audienceResult.AudienceAttraction.SetPlayerId(playerID)
		EndIf

		audienceResult.playerId = playerID
		audienceResults[playerID-1] = audienceResult
	End Method


	'Der Ablauf des Broadcasts, verallgemeinert für Programme und News.
	Method BroadcastCommon:TBroadcast(day:Int, hour:Int, broadcastType:Int, recompute:Int, bc:TBroadcast = Null )
		If bc = Null Then bc = New TBroadcast
		bc.BroadcastType = broadcastType

		If day < 0 Then day = GetWorldTime().GetDay()
		bc.Time = GetWorldTime().MakeTime(0, day, hour, 0, 0)

		Sequence.SetCurrentBroadcast(bc)

		'setup markets to compete for
		'only do this, if not done already or if enforced to do so
		'(this allows unittesting without StationMap)
		If recompute Or bc.AudienceMarkets.Count() = 0
			bc.AscertainPlayerMarkets()
		EndIf

		'Die Programmwahl der Spieler "einloggen"
		If broadcastType = TVTBroadcastMaterialType.NEWSSHOW
			bc.PlayersBroadcasts = currentNewsShowBroadcastMaterial
		Else
			bc.PlayersBroadcasts = currentProgrammeBroadcastMaterial
		EndIf
		'even if currentBroadcastMaterialdd is empty - fill
		'playersBroadcasts to a length of 4
		'-> access to playersBroadcast[0-3] is valid
		bc.PlayersBroadcasts = bc.PlayersBroadcasts[..4]


		bc.AudienceResults[0] = New TAudienceResult
		bc.AudienceResults[1] = New TAudienceResult
		bc.AudienceResults[2] = New TAudienceResult
		bc.AudienceResults[3] = New TAudienceResult

		'compute attractions for each player's broadcasts
		Local attractions:TAudienceAttraction[4]
		For Local i:Int = 1 To 4
			attractions[i-1] = bc.ComputeAttraction(i, Sequence.GetBeforeProgrammeBroadcast(), Sequence.GetBeforeNewsShowBroadcast())
		Next

		'compute the audience for the given broadcasts
		bc.ComputeAudience( attractions )

		For Local playerID:Int = 1 To 4
			Local audienceResult:TAudienceResult = bc.GetAudienceResult(playerID)
			'add to current set of results
			SetAudienceResult(playerID, audienceResult)
		Next

		bc.FindTopValues()

		ChangeImageCauseOfBroadcast(bc, broadcastType)
		'store current broadcast
		'currentBroadcast = bc
		Return bc
	End Method


	Function ChangeImageCauseOfBroadcast(bc:TBroadcast, broadcastType:Int)
		If (bc.GetTopAudience() > 1000) 'Nur etwas ändern, wenn auch ein paar Zuschauer einschalten und nicht alle Sendeausfall haben.
			Local modification:TAudience = TBroadcast.GetPotentialAudienceModifier(bc.time)

			'If (broadcastType = 0) Then 'Movies
				'allocate a Taudience-object for each channel and fill it
				'with the values to add to the image
				Local channelImageChanges:TAudience[4]
				Local channelAudiences:TAudience[4]

				Local attractionList:TList = CreateList()
				For Local i:Int = 1 To 4
					channelImageChanges[i-1] = New TAudience.InitValue(0, 0)
					channelAudiences[i-1] = bc.GetAudienceResult(i).audience
					'store playerID if not done yet
					If channelAudiences[i-1] And channelAudiences[i-1].id <= 0
						channelAudiences[i-1].id = i
					EndIf
				Next


				Local weight:Float = 1.0
				'for news, give a bit less images (less expensive to
				'get "good ones")
				If broadcastType = TVTBroadcastMaterialType.NEWSSHOW
					weight = 0.5
				EndIf

				Local audience:TAudience = New TAudience 'bc.GetAudienceResult(i).audience
				'the list order gets modified within ChangeForTargetGroup()
				'calls
				Local channelAudiencesList:TList = New TList.FromArray(channelAudiences)

				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.CHILDREN, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.TEENAGERS, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.HOUSEWIVES, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.EMPLOYEES, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.UNEMPLOYED, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.MANAGER, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.PENSIONERS, weight)

				For Local i:Int = 1 To 4 'TODO: Was passiert wenn ein Spieler ausscheidet?
					Local channelImageChange:TAudience = channelImageChanges[i-1]
					channelImageChange.Multiply(modification)
					Local publicImage:TPublicImage = GetPublicImageCollection().Get(i)
					If publicImage Then publicImage.ChangeImage(channelImageChange)
				Next
			'Endif
		End If
	End Function


	'=== AUDIENCE HELPERS ===
	Method GetCurrentAudience:Int(owner:Int)
		Local audienceResult:TAudienceResult = GetAudienceResult(owner)
		If Not audienceResult Then Return 0
		Return audienceResult.Audience.GetTotalSum()
	End Method


	Method GetCurrentAudienceObject:TAudience(owner:Int)
		Local audienceResult:TAudienceResult = GetAudienceResult(owner)
		If Not audienceResult Then Return new TAudience.InitValue(0,0)
		Return audienceResult.Audience
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetBroadcastManager:TBroadcastManager()
	Return TBroadcastManager.GetInstance()
End Function



Type TBroadcastAudiencePrediction {_exposeToLua="selected"}
	Field attractions:TAudienceAttraction[]
	Field broadcastType:Int = 0
	Field bc:TBroadcast
	Field lastProgrammeBroadcast:TBroadcast
	Field lastNewsBroadcast:TBroadcast


	Method SetAttraction(playerID:Int, attraction:TAudienceAttraction) {_exposeToLua}
		If playerID <= 0 Then Return

		If attractions.length < playerID Then attractions = attractions[.. playerID + 1]
		attractions[playerID - 1] = attraction
	End Method


	Method SetBaseAttraction(playerID:Int, audience:TAudience) {_exposeToLua}
		Local attr:TAudienceAttraction = New TAudienceAttraction
		attr.SetValuesFrom(audience)

		SetAttraction(playerID, attr)
	End Method


	Method SetAverageValueAttraction(playerID:Int, avgValue:Float=1.0) {_exposeToLua}
		SetBaseAttraction(playerID, New TAudience.InitValue(avgValue, avgValue))
	End Method


	Method SetBroadcastType(broadcastType:Int) {_exposeToLua}
		Self.broadcastType = broadcastType
	End Method


	Method NeedsToRefreshMarkets:Int() {_exposeToLua}
		if not bc or bc.AudienceMarkets.Count() = 0 then return True
	End Method


	Method RefreshMarkets:Int() {_exposeToLua}
		If bc = Null Then bc = New TBroadcast
		bc.AscertainPlayerMarkets()
	End Method


	Method GetAudienceResult:TAudienceResult(playerID:Int) {_exposeToLua}
		If Not bc Then Return New TAudienceResult
		Return bc.GetAudienceResult(playerID)
	End Method


	Method GetAudience:TAudience(playerID:Int) {_exposeToLua}
		If Not bc Then Return New TAudience
		Return bc.GetAudienceResult(playerID).audience
	End Method


	Method GetEmptyAudience:TAudience() {_exposeToLua}
		Return New TAudience
	End Method


	Method GetAudienceTotalSum:Int(playerID:Int) {_exposeToLua}
		If Not bc Then Return 0
		Return bc.GetAudienceResult(playerID).audience.GetTotalSum()
	End Method


	Method GetMarketCount:int() {_exposeToLua}
		if not bc or not bc.AudienceMarkets then return 0
		return bc.AudienceMarkets.Count()
	End Method


	Method RunPrediction(day:Int, hour:Int) {_exposeToLua}
		If bc = Null Then bc = New TBroadcast
		'it's up to the AI to refresh markets on stationmap visit...
		'If bc.AudienceMarkets.Count() = 0 Then RefreshMarkets()
		if bc.AudienceMarkets.Count() = 0
			print "!!! TBroadcastAudiencePrediction: Calling RunPrediction() without having called ~qRefreshMarkets()~q before!!!"
			TLogger.Log("TBroadcastAudiencePrediction", "Calling RunPrediction() without having called ~qRefreshMarkets()~q before", LOG_ERROR)
		endif

		If day < 0 Then day = GetWorldTime().GetDay()
		bc.Time = GetWorldTime().MakeTime(0, day, hour, 0, 0)

		'even if currentBroadcastMaterialdd is empty - fill
		'playersBroadcasts to a length of 4
		'-> access to playersBroadcast[0-3] is valid
		If attractions.length < 4
			attractions = attractions[..4]
		EndIf

		'create a new audience result set for each player
		For Local i:Int = 1 To attractions.length
			bc.SetAudienceResult(i, New TAudienceResult)
		Next

		'compute the audience for the given broadcasts
		bc.ComputeAudience(attractions)
	End Method
End Type


'In dieser Klasse und in TAudienceMarketCalculation findet die eigentliche
'Quotenberechnung statt und es wird das Ergebnis gecached, so dass man die
'Berechnung einige Zeit aufbewahren kann.
Type TBroadcast
	'time of the Broadcast (since start of the game)
	Field Time:Double = -1
	Field BroadcastType:Int
	'Wie sahen die Märkte zu dieser Zeit aus?
	Field AudienceMarkets:TList = CreateList()
	Field PlayersBroadcasts:TBroadcastMaterial[] = New TBroadcastMaterial[4]
	'Wie Attraktiv ist das Programm für diesen Broadcast
	Field Attractions:TAudienceAttraction[4]
	'Welche Zuschauerzahlen konnten ermittelt werden
	Field AudienceResults:TAudienceResult[4]
	'Cache für das Feedback. Bitte mit GetFeedback zugreifen, ist nämlich
	'nicht immer gefüllt.
	Field Feedback:TBroadcastFeedback[4]

	'Die höchste Zuschauerzahl
	Field _TopAudience:Int = -1 {nosave}
	'Die höchste Zuschauerquote
	Field _TopAudienceRate:Float = -1.0 {nosave}
	'Die Programmattraktivität
	Field _TopAttraction:Float = -1.0 {nosave}
	'Die beste Programmqualität
	Field _TopQuality:Float = -1.0 {nosave}

	'===== Öffentliche Methoden =====

	'Hier werden alle Märkte in denen verschiedene Spieler miteinander
	'konkurrieren initialisiert. Diese Methode wird nur einmal aufgerufen!
	'So legt man fest um wie viel Zuschauer sich Spieler 2 und Spieler 4
	'streiten oder wie viel Zuschauer Spieler 3 alleine bedient
	Method AscertainPlayerMarkets()
		'remove all old markets
		AudienceMarkets = CreateList()

		AddMarket([1]) '1
		AddMarket([2]) '2
		AddMarket([3]) '3
		AddMarket([4]) '4
		AddMarket([1, 2]) '1 & 2
		AddMarket([1, 3]) '1 & 3
		AddMarket([1, 4]) '1 & 4
		AddMarket([2, 3]) '2 & 3
		AddMarket([2, 4]) '2 & 4
		AddMarket([3, 4]) '3 & 4
		AddMarket([1, 2, 3]) '1 & 2 & 3
		AddMarket([1, 2, 4]) '1 & 2 & 4
		AddMarket([1, 3, 4]) '1 & 3 & 4
		AddMarket([2, 3, 4]) '2 & 3 & 4
		AddMarket([1, 2, 3, 4])	'1 & 2 & 3 & 4
	End Method


	'Hiermit wird die eigentliche Zuschauerzahl berechnet (mit allen Features)
	Method ComputeAudience( attractions:TAudienceAttraction[] = Null )
		If Not attractions
			attractions = New TAudienceAttraction[4]
		ElseIf attractions.length < 4
			attractions = attractions[.. 4]
		EndIf

		'Calculate missing attraction of a broadcast per player
		'and assign attraction (also informs markets about the attraction)
		For Local i:Int = 1 To 4
			If Not attractions[i-1] Then attractions[i-1] = TBroadcast.CalculateMalfunction( Null )
			SetAttraction(i, attractions[i-1])
		Next


		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			market.ComputeAudience(Time)
			AssimilateResults(market)
		Next
	End Method


	'recomputes the audience only for a given player
	'other players get ignored in calculations and do not get
	'the lost audience added to them.
	Method ReComputeAudienceOnlyForPlayer(playerId:Int, lastMovieBroadcast:TBroadcast, lastNewsShowBroadcast:TBroadcast)
		'recomposite markets in case of changes
		AscertainPlayerMarkets()

		SetAudienceResult(playerId, New TAudienceResult)
'		GetAudienceResult(playerId).Reset()

		SetAttraction(playerId, ComputeAttraction(playerId, lastMovieBroadcast, lastNewsShowBroadcast))
		rem
		For local i:int = 1 to 4
			if playerId = i
				SetAttraction(playerId, ComputeAttraction(playerId, lastMovieBroadcast, lastNewsShowBroadcast))
			else
				'fill markets with the old attraction values of the
				'other channels
				SetAttraction(playerId, Attractions[i-1])
			endif
		Next
		endrem

		'Ronny: when a player gets a manually set malfunction, the
		'       audience attraction is missing - and then bugging out
		'       a lot of things
		'store attaction id audience result (eg. on outages)
		Local ad:TAudienceResult = GetAudienceResult(playerId)
		If Not ad.audienceAttraction Then ad.audienceAttraction = Attractions[playerId - 1]

		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			'reassign attractions
			For local i:int = 1 to 4
				market.SetPlayersProgrammeAttraction(i, Attractions[i-1])
			Next
			market.ComputeAudience(Time)
			AssimilateResultsForPlayer(playerId, market)
		Next
	End Method


	Method GetMarketById:TAudienceMarketCalculation(id:String)
		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			If market.GetId() = id Then Return market
		Next
		Return Null
	End Method


	Method GetTopAudience:Int()
		If _TopAudience < 0 Then FindTopValues()
		Return _TopAudience
	End Method


	Method GetTopAudienceRate:Float()
		If _TopAudienceRate < 0 Then FindTopValues()
		Return _TopAudienceRate
	End Method


	Method GetTopAttraction:Float()
		If _TopAttraction < 0 Then FindTopValues()
		Return _TopAttraction
	End Method


	Method GetTopQuality:Float()
		If _TopQuality < 0 Then FindTopValues()
		Return _TopQuality
	End Method


	'===== Hilfsmethoden =====

	Method AssimilateResults(market:TAudienceMarketCalculation)
		For Local playerID:Int = EachIn market.playerIDs
			AssimilateResultsForPlayer(playerID, market)
		Next
	End Method


	Method AssimilateResultsForPlayer(playerId:Int, market:TAudienceMarketCalculation)
		Local result:TAudienceResult = market.GetAudienceResultOfPlayer(playerId)
		If result Then GetAudienceResult(playerId).AddResult(result)
	End Method


	Method ComputeAttraction:TAudienceAttraction(playerId:Int, lastProgrammeBroadcast:TBroadcast, lastNewsShowBroadcast:TBroadcast)
		Local broadcastedMaterial:TBroadcastMaterial = PlayersBroadcasts[playerId-1]

		Local lastProgrammeAttraction:TAudienceAttraction = Null
		If lastProgrammeBroadcast Then lastProgrammeAttraction = lastProgrammeBroadcast.Attractions[playerId-1]

		Local lastNewsShowAttraction:TAudienceAttraction = Null
		If lastNewsShowBroadcast Then lastNewsShowAttraction = lastNewsShowBroadcast.Attractions[playerId-1]

		Local attraction:TAudienceAttraction
		If broadcastedMaterial Then
			GetAudienceResult(playerId).broadcastMaterial = broadcastedMaterial
			'3. Qualität meines Programmes
			attraction = broadcastedMaterial.GetAudienceAttraction(GetWorldTime().GetDayHour(), broadcastedMaterial.currentBlockBroadcasting, lastProgrammeAttraction, lastNewsShowAttraction, True, True)
		Else 'dann Sendeausfall! TODO: Chef muss böse werden!
			TLogger.Log("TBroadcast.ComputeAndSetPlayersProgrammeAttraction()", "Player '" + playerId + "': Malfunction!", LOG_DEBUG)
			'outage
			GetAudienceResult(playerId).Title = "Malfunction!"
			GetAudienceResult(playerId).broadcastOutage = True
			attraction = CalculateMalfunction(lastProgrammeAttraction)
		End If
		Return attraction
	End Method


	'Sendeausfall
	Function CalculateMalfunction:TAudienceAttraction(lastMovieAttraction:TAudienceAttraction)
		Local attraction:TAudienceAttraction = New TAudienceAttraction
		attraction.BroadcastType = 0
		If lastMovieAttraction
			attraction.Malfunction = lastMovieAttraction.Malfunction
			attraction.AudienceFlowBonus = lastMovieAttraction.Copy()
			attraction.AudienceFlowBonus.MultiplyFloat(0.02)

			attraction.QualityOverTimeEffectMod = -0.2 * attraction.Malfunction
		Else
			attraction.QualityOverTimeEffectMod = -0.9
		End If
		attraction.Recalculate()
		attraction.Malfunction :+ 1
		Return attraction
	End Function


	Method SetAttraction(playerID:Int, audienceAttraction:TAudienceAttraction)
		Attractions[playerID-1] = audienceAttraction
		If audienceAttraction
			'limit attraction values to 0-1.0
			Attractions[playerID-1].CutBordersFloat(0, 1.0)
		EndIf

		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			If market.GetPlayerIndex(playerID) >= 0
				market.SetPlayersProgrammeAttraction(playerID, Attractions[playerID-1])
			EndIf
		Next
	End Method


	Method AddMarket(playerIDs:Int[])
		'create array of players not existing in "playerIDs"
		Local withoutPlayerIDs:Int[]
		For Local i:Int = 1 To 4
			If MathHelper.InIntArray(i, playerIDs) Then Continue
			withoutPlayerIDs :+ [i]
		Next

		'receipient share = portion of the population share eg. using an antenna
		local audienceAntenna:int = GetStationMapCollection().GetTotalAntennaReceiverShare(playerIDs, withoutPlayerIDs).x
		local audienceSatellite:int = GetStationMapCollection().GetTotalSatelliteReceiverShare(playerIDs, withoutPlayerIDs).x
		local audienceCableNetwork:int = GetStationMapCollection().GetTotalCableNetworkReceiverShare(playerIDs, withoutPlayerIDs).x

'		Local audience:Int = GetStationMapCollection().GetTotalShareAudience(playerIDs, withoutPlayerIDs)
'		If audience > 0
		If audienceAntenna > 0 or audienceSatellite > 0 or audienceCableNetwork > 0
			Local audience:int = audienceAntenna + audienceSatellite + audienceCableNetwork

			Local market:TAudienceMarketCalculation = New TAudienceMarketCalculation
			market.maxAudience = New TAudience.InitWithBreakdown(audience)
			market.shareAntenna = audienceAntenna / float(audience)
			market.shareSatellite = audienceSatellite / float(audience)
			market.shareCableNetwork = audienceCableNetwork / float(audience)
			For Local playerID:Int = EachIn playerIDs
				market.AddPlayer(playerID)
			Next

			AudienceMarkets.AddLast(market)
			'print "AddMarket:  players="+StringHelper.JoinIntArray(",",playerIDs) +"  without="+StringHelper.JoinIntArray(",",withoutPlayerIDs)+"  audience="+audience+"  (maxAudience="+int(market.maxAudience.GetTotalSum())+"  antenna="+audienceAntenna+"  satellite="+audienceSatellite+"  cablenetwork="+audienceCableNetwork+")"
		End If
	End Method


	Method FindTopValues()
		Local currAudience:Int
		Local currAudienceRate:Float
		Local currAttraction:Float
		Local currQuality:Float

		For Local playerId:Int = 1 To 4
			Local audienceResult:TAudienceResult = AudienceResults[playerId-1]
			If audienceResult Then
				currAudience = audienceResult.Audience.GetTotalSum()
				If (currAudience > _TopAudience) Then _TopAudience = currAudience

				currAudienceRate = audienceResult.GetAudienceQuotePercentage()
				If (currAudienceRate > _TopAudienceRate) Then _TopAudienceRate = currAudienceRate

				If audienceResult.AudienceAttraction Then
					currAttraction = audienceResult.AudienceAttraction.GetWeightedAverage()
					If (currAttraction > _TopAttraction) Then _TopAttraction = currAttraction

					currQuality = audienceResult.AudienceAttraction.Quality
					If (currQuality > _TopQuality) Then _TopQuality = currQuality
				EndIf
			EndIf
		Next
	End Method


	Method GetFeedback:TBroadcastFeedback(playerId:Int)
		Local currFeedback:TBroadcastFeedback = Feedback[playerId-1]
		If Not currFeedback Then
			currFeedback = TBroadcastFeedback.CreateFeedback(Self, playerId)
			Feedback[playerId-1] = currFeedback
		End If

		Return currFeedback
	End Method


	Method GetAudienceResult:TAudienceResult(playerID:Int)
		If playerID <= 0 Or playerID > AudienceResults.length Then Return Null
		Return AudienceResults[playerID-1]
	End Method


	Method SetAudienceResult:Int(playerID:Int, audienceResult:TAudienceResult)
		If playerID <= 0 Then Return False

		If playerID > audienceResults.length Then audienceResults = audienceResults[..playerID]

		If audienceResult And audienceResult.AudienceAttraction
			audienceResult.AudienceAttraction.SetPlayerId(playerID)
		EndIf
		audienceResults[playerID-1] = audienceResult
	End Method


	'returns how many percent of the target group are possibly watching
	'TV at the given hour
	Function GetPotentialAudiencePercentage_TimeMod:TAudience(time:Double = -1)
		If time < 0 Then time = GetWorldTime().GetTimeGone()

		Local result:TAudience

		'TODO: Eventuell auch in ein config-File auslagern
		Select GetWorldTime().GetDayHour(time)
			'                                  gender
			'                                    |  children
			'                                    |    |  teenagers
			'                                    |    |    |  housewives
			'                                    |    |    |    |  employees
			'                                    |    |    |    |    |  unemployed
			'                                    |    |    |    |    |    |  manager
			'                                    |    |    |    |    |    |    |  pensioners
			Case 0  result = New TAudience.Init(-1,   2,   6,  16,  11,  21,  19,  23)
			Case 1  result = New TAudience.Init(-1, 0.5,   4,   7,   7,  15,   9,  13)
			Case 2  result = New TAudience.Init(-1, 0.2,   1,   4,   4,  10,   3,   8)
			Case 3  result = New TAudience.Init(-1, 0.1,   1,   3,   3,   7,   2,   5)
			Case 4  result = New TAudience.Init(-1, 0.1, 0.5,   2,   3,   4,   1,   3)
			Case 5  result = New TAudience.Init(-1, 0.2,   1,   2,   4,   3,   3,   3)
			Case 6  result = New TAudience.Init(-1,   1,   2,   3,   6,   3,   5,   4)
			Case 7  result = New TAudience.Init(-1,   4,   7,   6,   8,   4,   8,   5)
			Case 8  result = New TAudience.Init(-1,   5,   2,   8,   5,   7,  11,   8)
			Case 9  result = New TAudience.Init(-1,   6,   2,   9,   3,  12,   7,  10)
			Case 10 result = New TAudience.Init(-1,   5,   2,   9,   3,  14,   3,  11)
			Case 11 result = New TAudience.Init(-1,   5,   3,   9,   4,  15,   4,  12)
			Case 12 result = New TAudience.Init(-1,   7,   9,  11,   8,  15,   8,  13)
			Case 13 result = New TAudience.Init(-1,   8,  12,  14,   7,  24,   6,  19)
			Case 14 result = New TAudience.Init(-1,  10,  13,  15,   6,  31,   2,  21)
			Case 15 result = New TAudience.Init(-1,  11,  14,  16,   6,  29,   2,  22)
			Case 16 result = New TAudience.Init(-1,  11,  15,  21,   6,  35,   2,  24)
			Case 17 result = New TAudience.Init(-1,  12,  16,  22,  11,  36,   3,  25)
			Case 18 result = New TAudience.Init(-1,  16,  21,  24,  18,  39,   5,  34)
			Case 19 result = New TAudience.Init(-1,  24,  33,  28,  28,  46,  12,  49)
			Case 20 result = New TAudience.Init(-1,  16,  36,  33,  37,  56,  23,  60)
			Case 21 result = New TAudience.Init(-1,  11,  32,  31,  36,  53,  25,  62)
			Case 22 result = New TAudience.Init(-1,   5,  23,  30,  30,  46,  35,  49)
			Case 23 result = New TAudience.Init(-1,   3,  14,  24,  20,  34,  33,  35)
		EndSelect
		'MAX is 62% -> modifiers should pay attention
		'-> limit mods to 100/62.0

		'convert to 0-1.0 percentage
		Return result.multiplyFloat(0.01)
	End Function


	'returns how many percent of the people watch TV depending on the
	'world weather (rain = better audience)
	Function GetPotentialAudiencePercentage_WeatherMod:TAudience(time:Double = -1)
		local weatherMod:Float = GameConfig.GetModifier("StationMap.Audience.WeatherMod")
		return New TAudience.InitValue(weatherMod, weatherMod)
	End Function


	Function GetPotentialAudienceModifier:TAudience(time:Double = -1)
		Local modifier:TAudience = New TAudience.InitValue(1, 1)

		'modify according to current hour
		modifier.Multiply( GetPotentialAudiencePercentage_TimeMod(time) )

		'modify according to weather
		'ATTENTION: uses current modificator, not the one at "TIME"
		modifier.Multiply( GetPotentialAudiencePercentage_WeatherMod(time) )

		Return modifier
	End Function
End Type


'Diese Klasse ist dazu da dem UI Feedback über die aktuelle Ausstrahlung
'zu geben. Vor allem für die Zuschauer vor der Mattscheibe (rechts unten
'im Bildschirm)...
'Man kann an dieser Klasse ablesen, welche Personen sichtbar sind und
'wie aktiv. Und man könnte Statements (Sprechblasen) einblenden und
'Feedback zum aktuellen Programm zu geben.
Type TBroadcastFeedback
	Field PlayerId:Int
	'Wie sehr ist das Publikum interessiert.
	'Werte: 0 = kein Interesse,   1 = etwas Interesse,
	'       2 = großes Interesse, 3 = begeistert
	Field AudienceInterest:TAudience
	Field FeedbackStatements:TList = CreateList()

	'a audience mask object with 0 for all disabled audiences and 1 for enabled
	Global audience_AdultOnlyMask:TAudience = New TAudience.Init(-1,  0, 1, 1, 1, 1, 1, 1)

	Const QUALITY:String = "QUALITY"
	Const POPULARITY:String = "POPULARITY"

	Function CreateFeedback:TBroadcastFeedback(bc:TBroadcast, playerId:Int)
		Local fb:TBroadcastFeedback = New TBroadcastFeedback
		fb.PlayerId = playerId
		fb.Calculate(bc)
		Return fb
	End Function

	Method Calculate(bc:TBroadcast)
		Local material:TBroadcastMaterial = bc.PlayersBroadcasts[PlayerId-1]
		Local result:TAudienceResult = bc.GetAudienceResult(PlayerId)
		Local attr:TAudienceAttraction = result.AudienceAttraction

		CalculateAudienceInterest(bc, attr)

		If Not attr.Malfunction Then
			If (attr.Quality < 0.1) Then
				AddFeedbackStatement(8, QUALITY, -2)
			ElseIf (attr.Quality < 0.25) Then
				AddFeedbackStatement(4, QUALITY, -1)
			ElseIf (attr.Quality < 0.55) Then
				AddFeedbackStatement(2, QUALITY, 0)
			ElseIf (attr.Quality < 0.8) Then
				AddFeedbackStatement(6, QUALITY, 1)
			Else
				AddFeedbackStatement(8, QUALITY, 2)
			End If

			If material Then
				Local genreDefinition:TGenreDefinitionBase = material.GetGenreDefinition()
				If genreDefinition Then
					Local popularityValue:Float = genreDefinition.GetPopularity().Popularity
					If (popularityValue < -35) Then
						AddFeedbackStatement(8, POPULARITY, -2)
					ElseIf (popularityValue < -10) Then
						AddFeedbackStatement(5, POPULARITY, -1)
					ElseIf (popularityValue < 10) Then
						AddFeedbackStatement(2, POPULARITY, 0)
					ElseIf (popularityValue < 30) Then
						AddFeedbackStatement(7, POPULARITY, 1)
					Else
						AddFeedbackStatement(8, POPULARITY, 2)
					EndIf
				EndIf
			EndIf
		EndIf

		'Ein erster Test für das Feedback... später ist natürlich ein
		'besseres Feedback geplant

		'Gute Uhrzeit?
		'Kommentare zu Flags
		'AudienceFlow-Kommentare
		'Kommentare zu Schauspielern
		'Kommentare zum Genre
	End Method


	'@minAttraction  defines the minimum attraction for all target groups
	'                to have interest in the programme
	Method CalculateAudienceInterestForAllowed(attr:TAudienceAttraction, maxAudienceMod:TAudience, plausibility:TAudience, minAttraction:Float)
		'plausibility: Wer schaut wahrscheinlich zu:
		'0 = auf keinen Fall
		'1 = möglich, aber nicht wahrscheinlich
		'2 = wahrscheinlich
		Local averageAttraction:Float = attr.GetTotalAverage()
		Local allowedAll:TAudience = plausibility
		Local allowedAdultsOnly:TAudience = audience_AdultOnlyMask

		Local sortMap:TNumberSortMap = attr.ToNumberSortMap()
		sortMap.Sort(False)


		'Top programme ?
		'override allowedAll-Map
		If attr.Quality > 0.8
			'Top programme, add all but children only if at home or "allowed"
			'by plausibility (eg. "erotic movies")
			Local highestAllowedAdult:TKeyValueNumber = GetFirstAllowed(sortMap, allowedAdultsOnly)

			If highestAllowedAdult And highestAllowedAdult.Value >= 0.9 And attr.Quality > 0.8 Then
				allowedAll = New TAudience.InitValue(1, 1)
				allowedAll.SetTotalValue(TVTTargetGroup.Children, plausibility.GetTotalValue(TVTTargetGroup.Children))
			EndIf
		EndIf


		If (averageAttraction > minAttraction)
			'calculate how many family members are shown. The less
			'attractive a programme is, the less members watch (regardless
			'of wether all are (a bit) interested in the programme)
			'ATTENTION: divide by 2 as GetTotalSum() returns both genders
			'summarized! Our family is "genderless" - girl="children"
			Local attrPerMember:Float = 0.9 / (allowedAll.GetTotalSum()/2)
			Local familyMemberCount:Int = int(averageAttraction / attrPerMember)
			'Local familyMemberCountOld:Int = Int((averageAttraction - (averageAttraction Mod attrPerMember)) / attrPerMember)

			'find the first/best #familyMemberCount members and store
			'their interest in #AudienceInterest
			For Local kv:TKeyValueNumber = EachIn sortMap.Content
				Local targetGroupID:Int = kv.Key.ToInt()
				Local targetGroupIndex:Int = TVTTargetGroup.GetIndexes(targetGroupID)[0]
				If targetGroupIndex <= 0 Then Continue 'invalid or "all"

				'at least one of both genders is allowed
				If allowedAll.GetTotalValue(targetGroupID) >= 1
					AudienceInterest.SetTotalValue(targetGroupID, AttractionToInterest(attr.GetTotalValue(targetGroupID), maxAudienceMod.GetTotalValue(targetGroupID), Int(allowedAll.GetTotalValue(targetGroupID) - 1)))
					If AudienceInterest.GetTotalValue(targetGroupID) > 0 Then familyMemberCount :- 1
				EndIf

				If familyMemberCount = 0 Then Return
			Next
		Else
			Local highestAllowed:TKeyValueNumber = GetFirstAllowed(sortMap, allowedAll)
			If highestAllowed And highestAllowed.Value >= (minAttraction * 2)
				'-1 = set for both
				AudienceInterest.SetTotalValue(highestAllowed.Key.ToInt(), 1)
			EndIf
		EndIf
	End Method


	Method CalculateAudienceInterest(bc:TBroadcast, attr:TAudienceAttraction)
		Local maxAudienceMod:TAudience = TBroadcast.GetPotentialAudienceModifier(bc.Time)

		AudienceInterest = New TAudience

		Local hour:Int = GetWorldTime().GetDayHour(bc.time)

		If (hour >= 0 And hour <= 1)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New TAudience.Init(-1,  0, 1, 2, 1, 2, 1, 2), 0.10)
		ElseIf (hour >= 2 And hour <= 5)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New TAudience.Init(-1,  0, 0, 1, 0, 2, 0, 2), 0.225)
		ElseIf (hour = 6)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New TAudience.Init(-1,  1, 1, 1, 1, 0, 1, 1), 0.20)
		ElseIf (hour >= 7 And hour <= 8)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New TAudience.Init(-1,  1, 1, 1, 1, 0, 1, 1), 0.125)
		ElseIf (hour >= 9 And hour <= 11)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New TAudience.Init(-1,  0, 0, 2, 0, 1, 0, 2), 0.125)
		ElseIf (hour >= 13 And hour <= 16)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New TAudience.Init(-1,  2, 2, 2, 0, 2, 0, 2), 0.05)
		ElseIf (hour >= 22 And hour <= 23)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New TAudience.Init(-1,  0, 1, 2, 2, 2, 2, 2), 0.05)
		Else
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New TAudience.Init(-1,  1, 2, 2, 2, 2, 1, 2), 0.05)
		EndIf
	End Method


	Method GetFirstAllowed:TKeyValueNumber(sortMap:TNumberSortMap, allowed:TAudience)
		For Local kv:TKeyValueNumber = EachIn sortMap.Content
			If allowed.GetTotalValue(TVTTargetGroup.Children) >= 1 And kv.Key = "0" Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Teenagers) >= 1 And kv.Key = TVTTargetGroup.Children Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.HouseWives) >= 1 And kv.Key = TVTTargetGroup.Teenagers Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Employees) >= 1 And kv.Key = TVTTargetGroup.HouseWives Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Unemployed) >= 1 And kv.Key = TVTTargetGroup.Employees Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Manager) >= 1 And kv.Key = TVTTargetGroup.Unemployed Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Pensioners) >= 1 And kv.Key = TVTTargetGroup.Manager Then Return kv
		Next
	End Method


	Method AddFeedbackStatement(importance:Int, statementKey:String, rating:Int)
		Local statement:TBroadcastFeedbackStatement = New TBroadcastFeedbackStatement
		statement.Importance = importance
		statement.StatementKey = statementKey
		statement.Rating = rating
		FeedbackStatements.AddLast(statement)
	End Method


	'Diese Methode muss aufgerufen werden, wenn ein Statement angezeigt werden soll.
	Method GetNextAudienceStatement:TBroadcastFeedbackStatement()
		Local ImportanceSum:Int

		For Local statement:TBroadcastFeedbackStatement = EachIn FeedbackStatements
			ImportanceSum :+ statement.Importance
		Next

		Local randomValue:Int = RandRange(1,ImportanceSum)

		Local currCount:Int
		For Local statement:TBroadcastFeedbackStatement = EachIn FeedbackStatements
			currCount :+ statement.Importance
			If randomValue <= currCount Then Return statement
		Next
	End Method


	Method AttractionToInterest:Int(attraction:Float, maxAudienceMod:Float, minValue:Int = 0)
		If maxAudienceMod >= 0.02 Then 'Extrem streng
			If attraction > 0.9 Then
				Return 3
			End If
		ElseIf maxAudienceMod >= 0.07 Then 'Sehr streng
			If attraction > 0.7 Then
				Return 2
			ElseIf attraction > 0.85 Then
				Return 3
			End If
		ElseIf maxAudienceMod >= 0.12 Then 'Verfügbar
			If attraction > 0.5 Then
				Return 1
			ElseIf attraction > 0.6 Then
				Return 2
			ElseIf attraction > 0.85 Then
				Return 3
			End If
		ElseIf maxAudienceMod >= 0.16 Then 'Primetime
			If attraction > 0.3 Then
				Return 1
			ElseIf attraction > 0.6 Then
				Return 2
			ElseIf attraction > 0.85 Then
				Return 3
			End If
		End If
		Return minValue
	End Method
End Type




Type TBroadcastFeedbackStatement
	Field Importance :Int
	Field Rating:Int '-2=schrecklich, -1 = negativ, 0 = neutral, 1 = positiv, 2 = hervorragend
	Field TargetGroup:Int
	Field StatementKey:String
	Field Statement:String

	Method ToString:String()
		Return "Statement: " + Importance + " / " + StatementKey + " = " + Rating
	End Method
End Type




'Diese Klasse repräsentiert einen Markt um den 1 bis 4 Spieler konkurrieren.
Type TAudienceMarketCalculation
	'participating playerIDs
	Field playerIDs:Int[]
	'attractivity of a broadcasts for each target group
	'for each active player there needs to be an entry
	Field audienceAttractions:TAudienceAttraction[]
	'population of this market
	Field maxAudience:TAudience
	'how the audience is shared between the reception types
	Field shareAntenna:Float = 1.0
	Field shareCableNetwork:Float = 0.0
	Field shareSatellite:Float = 0.0

	'results of the calculation
	Field audienceResults:TAudienceResult[]
	Field _id:String = "" {nosave}

	'===== Öffentliche Methoden =====

	Method GetId:String()
		If playerIDs.length > 0 And _id = ""
			For Local playerID:Int = EachIn playerIDs
				_id :+ playerID
			Next
		EndIf
		Return _id
	End Method


	Method ToString:String()
		Local result:String
		For Local playerID:Int = EachIn playerIDs
			result :+ playerID+" "
		Next
		Return "TAudienceMarketCalculation: players=["+result.Trim()+"], population: m="+maxAudience.GetGenderSum(TVTPersonGender.MALE)+" w="+maxAudience.GetGenderSum(TVTPersonGender.FEMALE)
	End Method


	Method AddPlayer(playerID:Int)
		playerIDs :+ [playerID]
		audienceAttractions = audienceAttractions[ .. playerIDs.length]
		audienceResults = audienceResults[ .. playerIDs.length]
	End Method


	Method GetPlayerIndex:Int(playerID:Int)
		For Local i:Int = 0 Until playerIDs.length
			If playerIDs[i] = playerID Then Return i
		Next
		Return -1
	End Method


	Method SetPlayersProgrammeAttraction(playerID:Int, audienceAttraction:TAudienceAttraction)
		Local i:Int = GetPlayerIndex(playerID)
		If i >= 0
			audienceAttractions[i] = audienceAttraction
		EndIf
	End Method


	Method GetAudienceResultOfPlayer:TAudienceResult(playerID:Int)
		Local i:Int = GetPlayerIndex(playerID)
		If i < 0 Then Return Null
		Return AudienceResults[i]
	End Method


	Method ComputeAudience(time:Double = -1)
		If time <= 0 Then time = GetWorldTime().GetTimeGone()

		'Die Zapper, um die noch gekämpft werden kann.
		Local ChannelSurferToShare:TAudience = GetPotentialChannelSurfer(time)

		'Ermittle wie viel ein Attractionpunkt auf Grund der Konkurrenz-
		'situation wert ist bzw. Quote bringt.
		Local competitionAttractionModifier:TAudience = GetCompetitionAttractionModifier()
		If Not competitionAttractionModifier Then Return

		'print "ComputeAudience:   time=" + GetWorldTime().GetFormattedGameDate(time)
		'Print "  maxAudience: " + MaxAudience.ToString()
		'Print "  ChannelSurferToShare: " + ChannelSurferToShare.ToString()

		For Local i:Int = 0 Until playerIDs.length
			'maybe a player just went bankrupt, so create a malfunction for him
			If Not audienceAttractions[i] Then SetPlayersProgrammeAttraction(i, TBroadcast.CalculateMalfunction(Null))
			Local attraction:TAudienceAttraction = audienceAttractions[i]

			'Die effectiveAttraction (wegen Konkurrenz) entspricht der Quote!
			Local effectiveAttraction:TAudience = attraction.Copy().Multiply(competitionAttractionModifier)
			effectiveAttraction.CutBordersFloat(0, 1.0)

			'Anteil an der "erbeuteten" Zapper berechnen
			Local channelSurfer:TAudience = ChannelSurferToShare.Copy().Multiply(effectiveAttraction)
			channelSurfer.Round()


			Local audienceResult:TAudienceResult = New TAudienceResult
			audienceResult.PlayerId = playerIDs[i]
			audienceResult.Time = Time

			audienceResult.WholeMarket = MaxAudience
			'100% of the audience
			audienceResult.PotentialMaxAudience = ChannelSurferToShare
			'actual audience
			audienceResult.Audience = channelSurfer

			audienceResult.AudienceAttraction = attraction
			audienceResult.competitionAttractionModifier = competitionAttractionModifier

			audienceResults[i] = audienceResult

			'print "Player " + (i+1)
			'Print "  Attraction:      " + audienceResult.AudienceAttraction.ToString()
			'Print "  Eff. Attraction: " + effectiveAttraction.ToString()
			'Print "  Audience:        " + audienceResult.Audience.ToString()
		Next
		'Print "competitionAttractionModifier: " + competitionAttractionModifier.ToString()
	End Method


	'returns amount of people zapping through the programmes
	Method GetPotentialChannelSurfer:TAudience(time:Double)
		'reduce the maximum audience to the available audience at that
		'time
		Local potentialChannelSurfer:TAudience
		potentialChannelSurfer = MaxAudience.Copy().Round()
		potentialChannelSurfer.Multiply( TBroadcast.GetPotentialAudienceModifier(time) )


		'reception might be not possible at all (bad weather)
		local weatherMod:Float
		weatherMod :+ shareAntenna * GameConfig.GetModifier("StationMap.Reception.AntennaMod", 1.0)
		weatherMod :+ shareCableNetwork * GameConfig.GetModifier("StationMap.Reception.CableNetworkMod", 1.0)
		weatherMod :+ shareSatellite * GameConfig.GetModifier("StationMap.Reception.SatelliteMod", 1.0)
		potentialChannelSurfer.MultiplyFloat(weatherMod)


		'calculate audience flow
		Local audienceFlowSum:TAudience = New TAudience
		For Local attractionTemp:TAudienceAttraction = EachIn audienceAttractions
			audienceFlowSum.Add(attractionTemp.AudienceFlowBonus)
		Next
		audienceFlowSum.DivideFloat(Float(playerIDs.length))

		potentialChannelSurfer.Add(audienceFlowSum.MultiplyFloat(0.25))


		'round to "complete persons" ;-)
		potentialChannelSurfer.Round()

		Return potentialChannelSurfer
	End Method


	Method GetCompetitionAttractionModifier:TAudience()
		'Die Summe aller Attractionwerte
		Local attrSum:TAudience = Null
		'Wie viel Prozent der Zapper bleibt bei mindestens einem Programm
		Local attrRange:TAudience = Null
		Local result:TAudience

		For Local attraction:TAudienceAttraction = EachIn audienceAttractions
			If attrSum = Null
				attrSum = attraction.Copy()
			Else
				attrSum.Add(attraction)
			EndIf

			If attrRange = Null
				attrRange = attraction.Copy()
			Else
				For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
					Local groupKey:Int = TVTTargetGroup.GetAtIndex(i)
					For Local genderIndex:Int = 0 To 1
						Local gender:Int = TVTPersonGender.FEMALE
						If genderIndex = 1 Then gender = TVTPersonGender.MALE

						Local rangeValue:Float = attrRange.GetGenderValue(groupKey, gender)
						attrRange.SetGenderValue(groupKey, rangeValue + (1 - rangeValue) * attraction.GetGenderValue(groupKey, gender), gender)
					Next
				Next
			EndIf
		Next


		If attrSum
			result = attrRange.Copy()

			For Local genderIndex:Int = 0 To 1
				Local gender:Int = TVTPersonGender.FEMALE
				If genderIndex = 1 Then gender = TVTPersonGender.MALE

				If result.GetGenderSum(gender) > 0 And attrSum.getGenderSum(gender) > 0
					'attention: attrSum could contain "0" values (div/0 !)
					'so a blind "result.Divide(attrSum)" is no solution!
					'-> check all values for 0 and handle them!

					For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
						Local groupKey:Int = TVTTargetGroup.GetAtIndex(i)

						'one of the targetgroups is not attracted at all
						'-> reduce to 0 (just set the same value so
						'   result/attr = 1.0 )
						If attrSum.GetGenderValue(groupKey, gender) = 0
							If result.GetGenderValue(groupKey, gender) <> 0
								attrSum.SetGenderValue( groupKey, result.GetGenderValue(groupKey, gender), gender)
							Else
								'does not matter what value we set, it will
								'be the divisor of "0" (0/1 = 0)
								attrSum.SetGenderValue( groupKey, 1, gender )
							EndIf
						EndIf
					Next
				EndIf
			Next
			If attrSum.GetTotalSum() > 0 Then result.Divide(attrSum)
		EndIf
		Return result
	End Method
End Type




Type TBroadcastSequence
	Field sequence:TList = CreateList()
	Field Current:TBroadcast
	'how many entries should be kept for each type
	'keep all = -1
	Field amountOfEntriesToKeep:Int = 3

	Method SetCurrentBroadcast(broadcast:TBroadcast)
		Current = broadcast
		sequence.AddFirst( Current )

		RemoveOldEntries()
	End Method


	Method RemoveOldEntries()
		'delete nothing if we have to keep all
		If amountOfEntriesToKeep < 0 Then Return

		Local foundProgramme:Int = 0
		Local foundNewsShow:Int = 0
		'iterate over copy to allow modification of the original list
		For Local curr:TBroadcast = EachIn sequence.Copy()
			If curr.BroadcastType = TVTBroadcastMaterialType.PROGRAMME
				If foundProgramme < amountOfEntriesToKeep
					foundProgramme :+ 1
				Else
					sequence.Remove(curr)

					'also remove no longer needed "special data"
					curr.Attractions = New TAudienceAttraction[4]
					For Local i:Int = 0 To 3
						'keep potential - for history analysis (market share)
						'curr.AudienceResults[i].PotentialMaxAudience = null
						curr.AudienceResults[i].AudienceAttraction = Null
						curr.AudienceResults[i].competitionAttractionModifier = Null
					Next
				EndIf
			EndIf
			If curr.BroadcastType = TVTBroadcastMaterialType.NEWSSHOW
				If foundNewsShow < amountOfEntriesToKeep
					foundNewsShow :+ 1
				Else
					sequence.Remove(curr)

					'also remove no longer needed "special data"
					curr.Attractions = New TAudienceAttraction[4]
					For Local i:Int = 0 To 3
						'curr.AudienceResults[i].PotentialMaxAudience = null
						curr.AudienceResults[i].AudienceAttraction = Null
						curr.AudienceResults[i].competitionAttractionModifier = Null
					Next
				EndIf
			EndIf
		Next
	End Method


	Method GetCurrentBroadcast:TBroadcast()
		Return TBroadcast(sequence.First())
	End Method

	Method GetBeforeBroadcast:TBroadcast()
		Return TBroadcast(sequence.ValueAtIndex(1))
	End Method

	Method GetBeforeProgrammeBroadcast:TBroadcast()
		Return GetFirst(TVTBroadcastMaterialType.PROGRAMME, False)
	End Method

	Method GetBeforeNewsShowBroadcast:TBroadcast()
		Return GetFirst(TVTBroadcastMaterialType.NEWSSHOW, False)
	End Method

	Method GetFirst:TBroadcast(broadcastType:Int, withoutCurrent:Int = False)
		For Local curr:TBroadcast = EachIn sequence
			If curr <> Current Or withoutCurrent Then
				If curr.BroadcastType = broadcastType Then Return curr
			EndIf
		Next
		Return Null
	End Method
End Type





Type TGameModifierAudience Extends TGameModifierBase
	Field audienceBaseMod:Float = 0.5
	Field audienceDetailMod:TAudience
	Field modifyProbability:int = 100
	Global className:String = "ModifierAudience"


	Function CreateNewInstance:TGameModifierAudience()
		return new TGameModifierAudience
	End Function


	Method Copy:TGameModifierAudience()
		local clone:TGameModifierAudience = new TGameModifierAudience
		clone.CopyBaseFrom(self)
		clone.audienceBaseMod = self.audienceBaseMod
		clone.audienceDetailMod = self.audienceDetailMod
		return clone
	End Method


	Method Init:TGameModifierAudience(data:TData, extra:TData=null)
		if not data then return null

		'local source:TNewsEvent = TNewsEvent(data.get("source"))
		local index:string = ""
		if extra and extra.GetInt("childIndex") > 0 then index = extra.GetInt("childIndex")
		audienceBaseMod = data.GetFloat("audienceBaseMod"+index, data.GetFloat("audienceBaseMod", 1.0))
		audienceDetailMod = TAudience(data.Get("audienceDetailMod"+index, data.Get("audienceDetailMod")))
		if audienceBaseMod = 1.0 and not audienceDetailMod
			TLogger.Log("TGameModifierAudience", "Init() failed - no baseMod and no detailMod given.", LOG_ERROR)
			return Null
		endif

		modifyProbability = data.GetInt("probability"+index, 100)

		return self
	End Method


	Method ToString:string()
		local name:string = data.GetString("name", "default")
		return className +" ("+name+")"
	End Method


	Method RunFunc:Int(params:TData)
		'hier weitermachen: Audience abgreifen
		'und bei "Undo" wieder entfernen
		Local audience:TAudience = TAudience(params.Get("audience"))
		If Not audience Then Throw(className + " failed. Param misses 'audience'.")

		if audienceBaseMod <> 1.0 then audience.MultiplyFloat(audienceBaseMod)
		if audienceDetailMod then audience.Multiply(audienceDetailMod)
		Return True
	End Method
End Type



'common weather modifier (_not_ used for special weather phenomens!)
Type TGameModifierAudience_Weather Extends TGameModifierAudience
	Global className:String = "ModifierAudience:Weather"


	Function CreateNewInstance:TGameModifierAudience_Weather()
		return new TGameModifierAudience_Weather
	End Function


	Method Copy:TGameModifierAudience_Weather()
		local clone:TGameModifierAudience_Weather = new TGameModifierAudience_Weather
		clone.CopyBaseFrom(self)
		return clone
	End Method


	Method ToString:String()
		'override to use this types global
		Return Super.ToString()
	End Method


	Method ModifierFunc:Int(params:TData)
		Local audience:TAudience = TAudience(params.Get("audience"))
		If Not audience Then Throw(className + " failed. Param misses 'audience'.")

'		hier das wetter holen und Effekte drauf abstellen

'		GetWorldWeather()

'		wenn regen, dann mod :+ 0.05 usw.

'		audience.MultiplyFloat(audienceMod)
		Return True
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("ModifyAudience", TGameModifierAudience.CreateNewInstance)