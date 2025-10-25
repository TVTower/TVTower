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


Global modKeyStationMap_Audience_WeatherModLS:TLowerString = New TLowerString.Create("StationMap.Audience.WeatherMod")
Global modKeyStationMap_Reception_AntennaModLS:TLowerString = New TLowerString.Create("StationMap.Reception.AntennaMod")
Global modKeyStationMap_Reception_CableNetworkModLS:TLowerString = New TLowerString.Create("StationMap.Reception.CableNetworkMod")
Global modKeyStationMap_Reception_SatelliteModLS:TLowerString = New TLowerString.Create("StationMap.Reception.SatelliteMod")


Type TBroadcastManager
	'Referenzen
'hier auf GUID
	Field newsGenreDefinitions:TNewsGenreDefinition[]		'TODO: Gehört woanders hin

	Field audienceResults:TAudienceResult[]

	'the current broadcast of each player, split by type
	Field currentAdvertisementBroadcastMaterial:TBroadcastMaterial[]
	Field currentProgrammeBroadcastMaterial:TBroadcastMaterial[]
	Field currentNewsShowBroadcastMaterial:TBroadcastMaterial[]

	Field Sequence:TBroadcastSequence = New TBroadcastSequence

	Global _instance:TBroadcastManager


	Function GetInstance:TBroadcastManager()
		If Not _instance Then _instance = New TBroadcastManager
		Return _instance
	End Function

	'===== Konstrukor, Speichern, Laden =====

	'removes any connection to other objects
	Method Reset()
		newsGenreDefinitions = New TNewsGenreDefinition[0]
		audienceResults = New TAudienceResult[0]
		currentAdvertisementBroadcastMaterial = New TBroadcastMaterial[0]
		currentProgrammeBroadcastMaterial = New TBroadcastMaterial[0]
		currentNewsShowBroadcastMaterial = New TBroadcastMaterial[0]

		Sequence = New TBroadcastSequence
	End Method

	'reinitializes the manager
	Method Initialize()
		Reset()
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
	
	
	'removes the currently "running" broadcast
	'(eg when restarting a player while others still broadcast stuff)
	Method ResetCurrentPlayerBroadcast(playerID:Int)
		'also inform others about the currently happening malfunction
		Local minute:int = GetWorldTime().GetDayMinute()
		if minute >= 5 and minute <= 54
			SetBroadcastMalfunction(playerID, TVTBroadcastMaterialType.PROGRAMME)
		Elseif minute >= 55 and minute <= 59
			SetBroadcastMalfunction(playerID, TVTBroadcastMaterialType.ADVERTISEMENT)
		Else
			SetBroadcastMalfunction(playerID, TVTBroadcastMaterialType.NEWSSHOW)
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
		bc.Time = GetWorldTime().GetTimeGoneForGameTime(0, day, hour, 0, 0)

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
			Local modification:SAudience = TBroadcast.GetPotentialAudienceModifier(bc.time)

			'If (broadcastType = 0) Then 'Movies
				'allocate a Taudience-object for each channel and fill it
				'with the values to add to the image
				Local channelImageChanges:TAudience[4]
				Local channelAudiences:TAudience[4]

				Local attractionList:TList = CreateList()
				For Local i:Int = 1 To 4
					Local r:TAudienceResult = bc.GetAudienceResult(i)
					channelImageChanges[i-1] = New TAudience.Set(0, 0)
					channelAudiences[i-1] = r.GetAudienceQuote()
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

				'Local audience:TAudience = New TAudience 'bc.GetAudienceResult(i).audience
				'the list order gets modified within ChangeForTargetGroup()
				'calls
				Local channelAudiencesList:TList = New TList.FromArray(channelAudiences)

				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.CHILDREN, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.TEENAGERS, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.HOUSEWIVES, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.EMPLOYEES, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.UNEMPLOYED, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.MANAGERS, weight)
				TPublicImage.ChangeForTargetGroup(channelImageChanges, channelAudiencesList, TVTTargetGroup.PENSIONERS, weight)

				For Local i:Int = 1 To 4 'TODO: Was passiert wenn ein Spieler ausscheidet?
					Local channelImageChange:TAudience = channelImageChanges[i-1]
					channelImageChange.Multiply(modification)
					Local publicImage:TPublicImage = GetPublicImageCollection().Get(i)
					If publicImage Then publicImage.ChangeImage(channelImageChange.data)
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
		If Not audienceResult Then Return New TAudience.Set(0,0)
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
		attr.FinalAttraction = new TAudience
		attr.FinalAttraction.Set(audience)

		SetAttraction(playerID, attr)
	End Method


	'required until brl.reflection correctly handles "float parameters" 
	'in debug builds (same as "doubles" for 32 bit builds)
	'GREP-key: "brlreflectionbug"
	Method SetAverageValueAttractionString(playerID:Int, avgValue:String) {_exposeToLua}
		SetAverageValueAttraction(playerID, Float(avgValue))
	End Method

	'expose commented out because of above mentioned brl.reflection bug
	Method SetAverageValueAttraction(playerID:Int, avgValue:Float=1.0) '{_exposeToLua}
		SetBaseAttraction(playerID, New TAudience.Set(avgValue, avgValue))
	End Method


	Method SetBroadcastType(broadcastType:Int) {_exposeToLua}
		Self.broadcastType = broadcastType
	End Method


	Method NeedsToRefreshMarkets:Int() {_exposeToLua}
		If Not bc Or bc.AudienceMarkets.Count() = 0 Then Return True
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


	Method GetAudienceWithPopulation:TAudience(population:Int) {_exposeToLua}
		Return New TAudience.Set(population, AudienceManager.GetTargetGroupBreakdown())
	End Method


	Method GetAudienceTotalSum:Int(playerID:Int) {_exposeToLua}
		If Not bc Then Return 0
		Return bc.GetAudienceResult(playerID).audience.GetTotalSum()
	End Method


	Method GetMarketCount:Int() {_exposeToLua}
		If Not bc Or Not bc.AudienceMarkets Then Return 0
		Return bc.AudienceMarkets.Count()
	End Method


	Method RunPrediction(day:Int, hour:Int) {_exposeToLua}
		If bc = Null Then bc = New TBroadcast
		'it's up to the AI to refresh markets on stationmap visit...
		'If bc.AudienceMarkets.Count() = 0 Then RefreshMarkets()
		If bc.AudienceMarkets.Count() = 0
			Print "!!! TBroadcastAudiencePrediction: Calling RunPrediction() without having called ~qRefreshMarkets()~q before!!!"
			TLogger.Log("TBroadcastAudiencePrediction", "Calling RunPrediction() without having called ~qRefreshMarkets()~q before", LOG_ERROR)
		EndIf

		If day < 0 Then day = GetWorldTime().GetDay()
		bc.Time = GetWorldTime().GetTimeGoneForGameTime(0, day, hour, 0, 0)

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
	Field Time:Long = -1
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
		if AudienceMarkets
			AudienceMarkets.Clear()
		else
			AudienceMarkets = CreateList()
		Endif

		'1 = player 1
		'2 = player 2
		'4 = player 3
		'8 = player 4
		AddMarket(new SChannelMask(1))				'1
		AddMarket(new SChannelMask(2))				'2
		AddMarket(new SChannelMask(4))				'3
		AddMarket(new SChannelMask(8))				'4
		AddMarket(new SChannelMask(1 + 2))			'1 & 2
		AddMarket(new SChannelMask(1 + 4))			'1 & 3
		AddMarket(new SChannelMask(1 + 8))			'1 & 4
		AddMarket(new SChannelMask(2 + 4))			'2 & 3
		AddMarket(new SChannelMask(2 + 8))			'2 & 4
		AddMarket(new SChannelMask(4 + 8))			'3 & 4

		AddMarket(new SChannelMask(1 + 2 + 4))		'1 & 2 & 3
		AddMarket(new SChannelMask(1 + 2 + 8))		'1 & 2 & 4
		AddMarket(new SChannelMask(1 + 4 + 8))		'1 & 3 & 4
		AddMarket(new SChannelMask(2 + 4 + 8))		'2 & 3 & 4

		AddMarket(new SChannelMask(1 + 2 + 4 + 8))	'1 & 2 & 3 & 4
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
		Rem
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
			For Local i:Int = 1 To 4
				market.SetProgrammeAttraction(i, Attractions[i-1])
			Next
			market.ComputeAudience(Time)
			AssimilateResultsForPlayer(playerId, market)
		Next
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
		For Local playerID:Int = 1 to 4
			If not market.HasChannel(playerID) Then continue
			
			AssimilateResultsForPlayer(playerID, market)
		Next
	End Method


	Method AssimilateResultsForPlayer(playerId:Int, market:TAudienceMarketCalculation)
		Local result:TAudienceResult = market.GetAudienceResultOfChannel(playerId)
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
			attraction.AudienceFlowBonus = lastMovieAttraction.FinalAttraction.Copy()
			attraction.AudienceFlowBonus.Multiply(0.02)

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

		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			'player not being part of the market is handled by the market itself
			'If market.HasChannel(playerID)
				market.SetProgrammeAttraction(playerID, Attractions[playerID-1])
			'EndIf
		Next
	End Method


	Method AddMarket(includeChannelMask:SChannelMask)
		'each of our markets is "exclusive" - so every non "included"
		'channel is to "exclude"
		'if the mask only contains channel 1, it is a market without
		'any other channel sharing antenna spots, satellites, cable networks...

		Local excludeChannelMask:SChannelMask = includeChannelMask.Negated()
		
		'receipient share = portion of the receiver share eg. using an antenna
		'receiver = people able to receive the channel, not "whole population"
		Local audienceAntenna:Int = GetStationMapCollection().GetAntennaReceiverShare(includeChannelMask, excludeChannelMask).shared
		Local audienceSatellite:Int = GetStationMapCollection().GetSatelliteUplinkReceiverShare(includeChannelMask, excludeChannelMask).shared
		Local audienceCableNetwork:Int = GetStationMapCollection().GetCableNetworkUplinkReceiverShare(includeChannelMask, excludeChannelMask).shared

'		Local audience:Int = GetStationMapCollection().GetTotalShareAudience(playerIDs, withoutPlayerIDs)
'		If audience > 0
		If audienceAntenna > 0 Or audienceSatellite > 0 Or audienceCableNetwork > 0
			Local audience:Int = audienceAntenna + audienceSatellite + audienceCableNetwork

			Local market:TAudienceMarketCalculation = New TAudienceMarketCalculation(includeChannelMask)
			'TODO: Ronny:
			'      rewrite to not store "maxAudience" but simply
			'      - receiverAntenna, receiverSatellite, receiverCableNetwork
			'      - targetGroupBreakdown:TAudienceBase (so it can share the same reference/refid)
			'      - optional: not "receiverAntenna" but "populationAntenna" etc - AND storage of the share values
			'      - "maxAudience" can be {nosave} then (and recalculated with above's values)
			'      -> final "dataset" should be smaller than now
			market.maxAudience = New TAudience.Set(audience, AudienceManager.GetTargetGroupBreakdown())
			market.shareAntenna = audienceAntenna / Float(audience)
			market.shareSatellite = audienceSatellite / Float(audience)
			market.shareCableNetwork = audienceCableNetwork / Float(audience)

			AudienceMarkets.AddLast(market)
			
			rem
			local withPID:String
			local withoutPID:String
			for local i:int = 1 to 4
				if includeChannelMask.Has(i) 
					if withPID then withPID :+ ","
					withPID :+ i
				EndIf
				if excludeChannelMask.Has(i) 
					if withoutPID then withoutPID :+ ","
					withoutPID :+ i
				EndIf
			Next
			print "AddMarket:  with players="+withPID +"  without="+withoutPID+"  audience="+audience+"  (maxAudience="+int(market.maxAudience.GetTotalSum())+"  antenna="+audienceAntenna+"  satellite="+audienceSatellite+"  cablenetwork="+audienceCableNetwork+")"
			endrem
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
					currAttraction = audienceResult.AudienceAttraction.FinalAttraction.GetWeightedAverage()
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
	Function GetPotentialAudiencePercentage_TimeMod:SAudience(time:Long = -1)
		If time < 0 Then time = GetWorldTime().GetTimeGone()

		Local result:SAudience

		'TODO: Eventuell auch in ein config-File auslagern
		Select GetWorldTime().GetDayHour(time)
			'                             gender
			'                               |  children
			'                               |    |  teenagers
			'                               |    |    |  housewives
			'                               |    |    |    |  employees
			'                               |    |    |    |    |  unemployed
			'                               |    |    |    |    |    |  manager
			'                               |    |    |    |    |    |    |  pensioners
			Case 0  result = New SAudience(-1,   2,   6,  16,  11,  21,  19,  23)
			Case 1  result = New SAudience(-1, 0.5,   4,   7,   7,  15,   9,  13)
			Case 2  result = New SAudience(-1, 0.2,   1,   4,   4,  10,   3,   8)
			Case 3  result = New SAudience(-1, 0.1,   1,   3,   3,   7,   2,   5)
			Case 4  result = New SAudience(-1, 0.1, 0.5,   2,   3,   4,   1,   3)
			Case 5  result = New SAudience(-1, 0.2,   1,   2,   4,   3,   3,   3)
			Case 6  result = New SAudience(-1,   1,   2,   3,   6,   3,   5,   4)
			Case 7  result = New SAudience(-1,   4,   7,   6,   8,   4,   8,   5)
			Case 8  result = New SAudience(-1,   5,   2,   8,   5,   7,  11,   8)
			Case 9  result = New SAudience(-1,   6,   2,   9,   3,  12,   7,  10)
			Case 10 result = New SAudience(-1,   5,   2,   9,   3,  14,   3,  11)
			Case 11 result = New SAudience(-1,   5,   3,   9,   4,  15,   4,  12)
			Case 12 result = New SAudience(-1,   7,   9,  11,   8,  15,   8,  13)
			Case 13 result = New SAudience(-1,   8,  12,  14,   7,  24,   6,  19)
			Case 14 result = New SAudience(-1,  10,  13,  15,   6,  31,   2,  21)
			Case 15 result = New SAudience(-1,  11,  14,  16,   6,  29,   2,  22)
			Case 16 result = New SAudience(-1,  11,  15,  21,   6,  35,   2,  24)
			Case 17 result = New SAudience(-1,  12,  16,  22,  11,  36,   3,  25)
			Case 18 result = New SAudience(-1,  16,  21,  24,  18,  39,   5,  34)
			Case 19 result = New SAudience(-1,  24,  33,  28,  28,  46,  12,  49)
			Case 20 result = New SAudience(-1,  16,  36,  33,  37,  56,  23,  60)
			Case 21 result = New SAudience(-1,  11,  32,  31,  36,  53,  25,  62)
			Case 22 result = New SAudience(-1,   5,  23,  30,  30,  46,  35,  49)
			Case 23 result = New SAudience(-1,   3,  14,  24,  20,  34,  33,  35)
		EndSelect
		'MAX is 62% -> modifiers should pay attention
		'-> limit mods to 100/62.0

		'convert to 0-1.0 percentage
		result.Multiply(0.01)

		Return result
	End Function


	'returns how many percent of the people watch TV depending on the
	'world weather (rain = better audience)
	Function GetPotentialAudiencePercentage_WeatherMod:SAudience(time:Long = -1)
		Local weatherMod:Float = GameConfig.GetModifier(modKeyStationMap_Audience_WeatherModLS)
		Return New SAudience(weatherMod, weatherMod)
	End Function


	Function GetPotentialAudienceModifier:SAudience(time:Long = -1)
		Local modifier:SAudience = New SAudience(1, 1)

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
	Global audience_AdultOnlyMask:SAudience = New SAudience(-1,  0, 1, 1, 1, 1, 1, 1)

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
	Method CalculateAudienceInterestForAllowed(attr:TAudienceAttraction, maxAudienceMod:SAudience, plausibility:SAudience, minAttraction:Float)
		'plausibility: Wer schaut wahrscheinlich zu:
		'0 = auf keinen Fall
		'1 = möglich, aber nicht wahrscheinlich
		'2 = wahrscheinlich
		Local averageAttraction:Float = attr.FinalAttraction.GetTotalAverage()
		Local allowedAll:SAudience = plausibility
		Local allowedAdultsOnly:SAudience = audience_AdultOnlyMask

		Local sortMap:TNumberSortMap = attr.FinalAttraction.ToNumberSortMap()
		sortMap.Sort(False)


		'Top programme ?
		'override allowedAll-Map
		If attr.Quality > 0.8
			'Top programme, add all but children only if at home or "allowed"
			'by plausibility (eg. "erotic movies")
			Local highestAllowedAdult:TKeyValueNumber = GetFirstAllowed(sortMap, allowedAdultsOnly)

			If highestAllowedAdult And highestAllowedAdult.Value >= 0.9 And attr.Quality > 0.8 Then
				allowedAll = New SAudience(1, 1)
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
			Local familyMemberCount:Int = Int(averageAttraction / attrPerMember)
			'Local familyMemberCountOld:Int = Int((averageAttraction - (averageAttraction Mod attrPerMember)) / attrPerMember)

			'find the first/best #familyMemberCount members and store
			'their interest in #AudienceInterest
			For Local kv:TKeyValueNumber = EachIn sortMap.Content
				Local targetGroupID:Int = kv.Key.ToInt()
				Local targetGroupIndex:Int = TVTTargetGroup.GetIndexes(targetGroupID)[0]
				If targetGroupIndex <= 0 Then Continue 'invalid or "all"

				'at least one of both genders is allowed
				If allowedAll.GetTotalValue(targetGroupID) >= 1
					AudienceInterest.SetTotalValue(targetGroupID, AttractionToInterest(attr.FinalAttraction.GetTotalValue(targetGroupID), maxAudienceMod.GetTotalValue(targetGroupID), Int(allowedAll.GetTotalValue(targetGroupID) - 1)))
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
		Local maxAudienceMod:SAudience = TBroadcast.GetPotentialAudienceModifier(bc.Time)

		AudienceInterest = New TAudience

		Local hour:Int = GetWorldTime().GetDayHour(bc.time)

		If (hour >= 0 And hour <= 1)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New SAudience(-1,  0, 1, 2, 1, 2, 1, 2), 0.10)
		ElseIf (hour >= 2 And hour <= 5)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New SAudience(-1,  0, 0, 1, 0, 2, 0, 2), 0.225)
		ElseIf (hour = 6)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New SAudience(-1,  1, 1, 1, 1, 0, 1, 1), 0.20)
		ElseIf (hour >= 7 And hour <= 8)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New SAudience(-1,  1, 1, 1, 1, 0, 1, 1), 0.125)
		ElseIf (hour >= 9 And hour <= 11)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New SAudience(-1,  0, 0, 2, 0, 1, 0, 2), 0.125)
		ElseIf (hour >= 13 And hour <= 16)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New SAudience(-1,  2, 2, 2, 0, 2, 0, 2), 0.05)
		ElseIf (hour >= 22 And hour <= 23)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New SAudience(-1,  0, 1, 2, 2, 2, 2, 2), 0.05)
		Else
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, New SAudience(-1,  1, 2, 2, 2, 2, 1, 2), 0.05)
		EndIf
	End Method


	Method GetFirstAllowed:TKeyValueNumber(sortMap:TNumberSortMap, allowed:SAudience)
		For Local kv:TKeyValueNumber = EachIn sortMap.Content
			If allowed.GetTotalValue(TVTTargetGroup.Children) >= 1 And kv.Key = "0" Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Teenagers) >= 1 And kv.Key = TVTTargetGroup.Children Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.HouseWives) >= 1 And kv.Key = TVTTargetGroup.Teenagers Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Employees) >= 1 And kv.Key = TVTTargetGroup.HouseWives Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Unemployed) >= 1 And kv.Key = TVTTargetGroup.Employees Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Managers) >= 1 And kv.Key = TVTTargetGroup.Unemployed Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Pensioners) >= 1 And kv.Key = TVTTargetGroup.Managers Then Return kv
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
	'participating playerID/channelIDs
	Field channelMaskValue:Int
	'attractivity of a broadcasts for each target group
	'for each active player there needs to be an entry
	Field audienceAttractions:TAudienceAttraction[4]
	'population of this market
	Field maxAudience:TAudience
	'how the audience is shared between the reception types
	Field shareAntenna:Float = 1.0
	Field shareCableNetwork:Float = 0.0
	Field shareSatellite:Float = 0.0

	'results of the calculation
	Field audienceResults:TAudienceResult[4]
	Field _id:String = "" {nosave}


	Method New(channelMask:SChannelMask)
		self.channelMaskValue = channelMask.value
		Local channelCount:Int = channelMask.GetEnabledCount()
		if audienceAttractions.length < channelCount
			audienceAttractions = audienceAttractions[ .. channelCount]
			audienceResults = audienceResults[ .. channelCount]
		endif
	End Method


	Method AddChannel(channelID:Int)
		local mask:SChannelMask = new SChannelMask(channelMaskValue).Set(channelID)
		Local channelCount:Int = mask.GetEnabledCount()

		channelMaskValue = mask.value
		if audienceAttractions.length < channelCount
			audienceAttractions = audienceAttractions[ .. channelCount]
			audienceResults = audienceResults[ .. channelCount]
		endif
	End Method
	
	
	Method HasChannel:Int(channelID:Int)
		Return new SChannelMask(channelMaskValue).Has(channelID)
	End Method


	Method ToString:String()
		Local result:String
		For Local playerID:Int = 1 to 4
			if result then result :+ " "
			If HasChannel(playerID)
				result :+ playerID
			Else
				result :+ " "
			EndIf
		Next
		Return "TAudienceMarketCalculation: players=["+result+"], maxAudience: m="+maxAudience.GetGenderSum(TVTPersonGender.MALE)+" w="+maxAudience.GetGenderSum(TVTPersonGender.FEMALE)
	End Method


	Method SetProgrammeAttraction(channelID:Int, audienceAttraction:TAudienceAttraction)
		'player not being part of the market is handled by the GetCompetitionAttractionModifier
		'if new SChannelMask(channelMaskValue).Has(channelID) and audienceAttractions.length >= channelID
			audienceAttractions[channelID - 1] = audienceAttraction
		'EndIf
	End Method


	Method GetAudienceResultOfChannel:TAudienceResult(channelID:Int)
		If new SChannelMask(channelMaskValue).Has(channelID) and AudienceResults.length >= channelID
			Return AudienceResults[channelID - 1]
		EndIf
	End Method


	Method ComputeAudience(time:Long = -1)
		If time <= 0 Then time = GetWorldTime().GetTimeGone()

		'Die Zapper, um die noch gekämpft werden kann.
		Local ChannelSurferToShare:TAudience = GetPotentialChannelSurfer(time)

		'Ermittle wie viel ein Attractionpunkt auf Grund der Konkurrenz-
		'situation wert ist bzw. Quote bringt.
		Local competitionAttractionModifier:TAudience = GetCompetitionAttractionModifier()

		'print "ComputeAudience:   time=" + GetWorldTime().GetFormattedGameDate(time)
		'Print "  maxAudience: " + MaxAudience.ToString()
		'Print "  ChannelSurferToShare: " + ChannelSurferToShare.ToString()
		
		Local channelMask:SChannelMask = new SChannelMask(channelMaskValue)

		For Local channelID:Int = 1 To 4
			'skip inactive channels
			If Not channelMask.Has(channelID) then Continue
			
			'maybe a player just went bankrupt, so create a malfunction for him
			If Not audienceAttractions[channelID - 1] Then SetProgrammeAttraction(channelID, TBroadcast.CalculateMalfunction(Null))
			Local attraction:TAudienceAttraction = audienceAttractions[channelID - 1]

			'Die effectiveAttraction (wegen Konkurrenz) entspricht der Quote!
			Local effectiveAttraction:SAudience = attraction.FinalAttraction.data 'copy
			effectiveAttraction.Multiply(competitionAttractionModifier)
			effectiveAttraction.CutBorders(0, 1.0)

			'Anteil an der "erbeuteten" Zapper berechnen
			Local channelSurfer:TAudience = ChannelSurferToShare.Copy().Multiply(effectiveAttraction)
			channelSurfer.Round()


			Local audienceResult:TAudienceResult = New TAudienceResult
			audienceResult.PlayerId = channelID
			audienceResult.Time = Time

			audienceResult.WholeMarket = MaxAudience
			'100% of the audience
			audienceResult.PotentialAudience = ChannelSurferToShare
			'actual audience
			audienceResult.Audience = channelSurfer

			audienceResult.AudienceAttraction = attraction
			audienceResult.competitionAttractionModifier = competitionAttractionModifier

			audienceResults[channelID -1] = audienceResult

			'print "Player/Channel " + channelID
			'Print "  Attraction:      " + audienceResult.AudienceAttraction.ToString()
			'Print "  Eff. Attraction: " + effectiveAttraction.ToString()
			'Print "  Audience:        " + audienceResult.Audience.ToString()
		Next
		'Print "competitionAttractionModifier: " + competitionAttractionModifier.ToString()
	End Method


	'returns amount of people zapping through the programmes
	Method GetPotentialChannelSurfer:TAudience(time:Long)
		'reduce the maximum audience to the available audience at that
		'time
		Local potentialChannelSurfer:TAudience
		potentialChannelSurfer = MaxAudience.Copy().Round()
		potentialChannelSurfer.Multiply( TBroadcast.GetPotentialAudienceModifier(time) )

		'reception might be not possible at all (bad weather)
		Local weatherMod:Float
		weatherMod :+ shareAntenna * GameConfig.GetModifier(modKeyStationMap_Reception_AntennaModLS, 1.0)
		weatherMod :+ shareCableNetwork * GameConfig.GetModifier(modKeyStationMap_Reception_CableNetworkModLS, 1.0)
		weatherMod :+ shareSatellite * GameConfig.GetModifier(modKeyStationMap_Reception_SatelliteModLS, 1.0)
		potentialChannelSurfer.Multiply(weatherMod)


		'calculate audience flow
		local channelMask:SChannelMask = new SChannelMask(channelMaskValue)
		Local audienceFlowSum:TAudience = New TAudience
		Local attractionCount:Float
		For Local attractionTemp:TAudienceAttraction = EachIn audienceAttractions
			audienceFlowSum.Add(attractionTemp.AudienceFlowBonus)
			attractionCount :+ 1
		Next
		audienceFlowSum.Divide(attractionCount)

		potentialChannelSurfer.Add(audienceFlowSum.Multiply(0.25))


		'round to "complete persons" ;-)
		potentialChannelSurfer.Round()

		Return potentialChannelSurfer
	End Method


	Method GetCompetitionAttractionModifier:TAudience()
		'Die Summe aller Attractionwerte
		Local attrSum:SAudience
		'Wie viel Prozent der Zapper bleibt bei mindestens einem Programm
		Local attrRange:SAudience
		Local result:TAudience = new TAudience

		Local channelMask:SChannelMask = new SChannelMask(channelMaskValue)
		For Local channelID:Int = 1 To 4
			If audienceAttractions[channelID - 1]
				Local attraction:TAudienceAttraction = audienceAttractions[channelID - 1]
				If channelMask.Has(channelID)
					attrSum.Add(attraction.FinalAttraction)
				Else
					'if a channel is not part of the market, use part of its attraction to
					'simulate existing competition
					'otherwise audience quotes for markets with few players will be unrealistic
					'multiplier 0=no competition, 1=as if all players are part of the market
					attrSum.Add(attraction.FinalAttraction.copy().multiply(0.4))
				EndIf

				For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
					For Local genderIndex:Int = 0 To 1
						Local gender:Int = TVTPersonGender.FEMALE
						If genderIndex = 1 Then gender = TVTPersonGender.MALE

						Local rangeValue:Float = attrRange.GetGenderValue(targetGroupID, gender)
						attrRange.SetGenderValue(targetGroupID, rangeValue + (1 - rangeValue) * attraction.FinalAttraction.GetGenderValue(targetGroupID, gender), gender)
					Next
				Next
			EndIf
		Next


		result.data = attrRange 'copy

		For Local genderIndex:Int = 0 To 1
			Local gender:Int = TVTPersonGender.FEMALE
			If genderIndex = 1 Then gender = TVTPersonGender.MALE

			If result.GetGenderSum(gender) > 0 And attrSum.getGenderSum(gender) > 0
				'attention: attrSum could contain "0" values (div/0 !)
				'so a blind "result.Divide(attrSum)" is no solution!
				'-> check all values for 0 and handle them!

				For local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
					'one of the targetgroups is not attracted at all
					'-> reduce to 0 (just set the same value so
					'   result/attr = 1.0 )
					If attrSum.GetGenderValue(targetGroupID, gender) = 0
						If result.GetGenderValue(targetGroupID, gender) <> 0
							attrSum.SetGenderValue( targetGroupID, result.GetGenderValue(targetGroupID, gender), gender)
						Else
							'does not matter what value we set, it will
							'be the divisor of "0" (0/1 = 0)
							attrSum.SetGenderValue( targetGroupID, 1, gender )
						EndIf
					EndIf
				Next
			EndIf
		Next
		If attrSum.GetTotalSum() > 0 Then result.data.Divide(attrSum)

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
	Field modifyProbability:Int = 100
	Global className:String = "ModifierAudience"


	Function CreateNewInstance:TGameModifierAudience()
		Return New TGameModifierAudience
	End Function


	Method Copy:TGameModifierAudience()
		Local clone:TGameModifierAudience = New TGameModifierAudience
		clone.CopyBaseFrom(Self)
		clone.audienceBaseMod = Self.audienceBaseMod
		clone.audienceDetailMod = Self.audienceDetailMod
		Return clone
	End Method


	Method Init:TGameModifierAudience(data:TData, extra:TData=Null)
		If Not data Then Return Null

		Local index:String = ""
		If extra And extra.GetInt("childIndex") > 0 Then index = extra.GetInt("childIndex")
		audienceBaseMod = data.GetFloat("audienceBaseMod"+index, data.GetFloat("audienceBaseMod", 1.0))
		audienceDetailMod = TAudience(data.Get("audienceDetailMod"+index, data.Get("audienceDetailMod")))
		If audienceBaseMod = 1.0 And Not audienceDetailMod
			TLogger.Log("TGameModifierAudience", "Init() failed - no baseMod and no detailMod given.", LOG_ERROR)
			Return Null
		EndIf

		modifyProbability = data.GetInt("probability"+index, 100)

		Return Self
	End Method


	Method ToString:String()
		Local name:String = data.GetString("name", "default")
		Return className +" ("+name+")"
	End Method


	Method RunFunc:Int(params:TData)
		'hier weitermachen: Audience abgreifen
		'und bei "Undo" wieder entfernen
		Local audience:TAudience = TAudience(params.Get("audience"))
		If Not audience Then Throw(className + " failed. Param misses 'audience'.")

		If audienceBaseMod <> 1.0 Then audience.Multiply(audienceBaseMod)
		If audienceDetailMod Then audience.Multiply(audienceDetailMod)
		Return True
	End Method
End Type



'common weather modifier (_not_ used for special weather phenomens!)
Type TGameModifierAudience_Weather Extends TGameModifierAudience
	Global className:String = "ModifierAudience:Weather"


	Function CreateNewInstance:TGameModifierAudience_Weather()
		Return New TGameModifierAudience_Weather
	End Function


	Method Copy:TGameModifierAudience_Weather()
		Local clone:TGameModifierAudience_Weather = New TGameModifierAudience_Weather
		clone.CopyBaseFrom(Self)
		Return clone
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

'		audience.Multiply(audienceMod)
		Return True
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("ModifyAudience", TGameModifierAudience.CreateNewInstance)
