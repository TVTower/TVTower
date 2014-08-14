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
Import "game.broadcast.genredefinition.movie.bmx"
Import "game.broadcast.genredefinition.news.bmx"
Import "game.publicimage.bmx"
Import "game.stationmap.bmx"
Import "game.world.worldtime.bmx"


Type TBroadcastManager
	Field initialized:int = False

	'Referenzen
	Field newsGenreDefinitions:TNewsGenreDefinition[]		'TODO: Gehört woanders hin

	Field audienceResults:TAudienceResult[]

	'the current broadcast of each player
	Field currentBroadcastMaterial:TBroadcastMaterial[]

	'Field currentBroadcast:TBroadcast = Null
	'Field currentProgammeBroadcast:TBroadcast = Null
	'Field currentNewsShowBroadcast:TBroadcast = Null

	'Field lastProgrammeBroadcast:TBroadcast = Null
	'Field lastNewsShowBroadcast:TBroadcast = Null

	'Für die Manipulationen von außen... funktioniert noch nicht
	Field PotentialAudienceManipulations:TMap = CreateMap()

	Field Sequence:TBroadcastSequence = new TBroadcastSequence

	Global _instance:TBroadcastManager


	Function GetInstance:TBroadcastManager()
		if not _instance then _instance = new TBroadcastManager
		return _instance
	End Function

	'===== Konstrukor, Speichern, Laden =====

	'reinitializes the manager
	Method Reset()
		initialized = False
		Initialize()
	End Method


	Method Initialize()
		if initialized then return

		'load and init the genres
		GetMovieGenreDefinitionCollection().Initialize()
		GetNewsGenreDefinitionCollection().Initialize()

		initialized = TRUE
	End Method


	'===== Öffentliche Methoden =====

	Method GetCurrentBroadcast:TBroadcast()
		Return Sequence.GetCurrentBroadcast()
	End Method

	
	'Führt die Berechnung für die Einschaltquoten der Sendeblöcke durch
	Method BroadcastProgramme(day:Int=-1, hour:Int, recompute:Int = 0, bc:TBroadcast = null)
		BroadcastCommon(hour, TBroadcastMaterial.TYPE_PROGRAMME, recompute, bc)
	End Method


	'Führt die Berechnung für die Nachrichten(-Show)-Ausstrahlungen durch
	Method BroadcastNewsShow(day:Int=-1, hour:Int, recompute:Int = 0)
		BroadcastCommon(hour, TBroadcastMaterial.TYPE_NEWSSHOW, recompute)
	End Method


	Method GetNewsGenreDefinition:TNewsGenreDefinition(genreId:Int)
		Return newsGenreDefinitions[genreId]
	End Method


	Method GetCurrentBroadcastMaterial:TBroadcastMaterial(playerID:int)
		if playerID <= 0 or playerID > currentBroadcastMaterial.length then return Null

		return currentBroadcastMaterial[playerID-1]
	End Method


	Method SetCurrentBroadcastMaterial:int(playerID:int, material:TBroadcastMaterial)
		if playerID <= 0 then return False

		if playerID > currentBroadcastMaterial.length then currentBroadcastMaterial = currentBroadcastMaterial[..playerID]
		currentBroadcastMaterial[playerID-1] = material
		return True
	End Method	

	'===== Manipulationen =====

	'sets the current broadcast as malfunction
	Method SetBroadcastMalfunction:int(playerID:int)
		'adjust what is broadcasted now
		SetCurrentBroadcastMaterial(playerID, null)
		GetCurrentBroadcast().PlayersBroadcasts = currentBroadcastMaterial
		'recalculate the players audience
		ReComputePlayerAudience(playerID)
	End Method	


	'recalculates the audience of the given player
	'other players DO NOT get adjusted (audience is "lost", not transferred) 
	Method ReComputePlayerAudience:int(playerID:int)
		GetCurrentBroadcast().ReComputeAudienceOnlyForPlayer(playerID, Sequence.GetBeforeProgrammeBroadcast(), Sequence.GetBeforeNewsShowBroadcast())
		SetAudienceResult(playerID, GetCurrentBroadcast().GetAudienceResult(playerID))
	End Method

	
	'Ist noch nicht fertig!
	Method ManipulatePotentialAudience(factor:Float, day:Int, hour:Int, followingHours:Int = 0 ) 'factor = -0.1 und +2.0
		Local realDay:Int = day
		Local realHour:Int
		For Local i:Int = 0 to followingHours
			realHour = hour + i
			If realHour > 23
				Local rest:Int = realHour / 24
				realDay = day + (realHour - rest) / 24
				realHour = rest
			Else
				realDay = day
			End If
			'PotentialAudienceManipulations.Insert(realDay + "|" + realHour, factor)
			Throw "Implementiere mich!"
		Next
	End Method


	'===== Hilfsmethoden =====

	Method GetAudienceResult:TAudienceResult(playerID:int)
		if playerID <= 0 or playerID > audienceResults.length then return Null
		return audienceResults[playerID-1]
	End Method


	Method SetAudienceResult:int(playerID:int, audienceResult:TAudienceResult)
		if playerID <= 0 then return False

		if playerID > audienceResults.length then audienceResults = audienceResults[..playerID]
		
		If audienceResult and audienceResult.AudienceAttraction Then
			audienceResult.AudienceAttraction.SetPlayerId(playerID)
		EndIf

		audienceResults[playerID-1] = audienceResult
	End Method


	'Der Ablauf des Broadcasts, verallgemeinert für Programme und News.
	Method BroadcastCommon:TBroadcast(hour:Int, broadcastType:Int, recompute:Int, bc:TBroadcast = null )
		If bc = Null Then bc = New TBroadcast
		bc.BroadcastType = broadcastType
		bc.Hour = hour
		Sequence.SetCurrentBroadcast(bc)

		bc.AscertainPlayerMarkets()							'Aktuelle Märkte (um die konkuriert wird) festlegen
		bc.PlayersBroadcasts = currentBroadcastMaterial		'Die Programmwahl der Spieler "einloggen"
		'even if currentBroadcastMaterial is empty - fill
		'playersBroadcasts to a length of 4
		'-> access to playersBroadcast[0-3] is valid
		bc.PlayersBroadcasts = bc.PlayersBroadcasts[..4]

		'compute the audience for the given broadcasts
		bc.ComputeAudience(Sequence.GetBeforeProgrammeBroadcast(), Sequence.GetBeforeNewsShowBroadcast())

		For local playerID:int = 1 to 4
			Local audienceResult:TAudienceResult = bc.GetAudienceResult(playerID)
			'add to current set of results
			SetAudienceResult(playerID, audienceResult)
			
			If audienceResult.AudienceAttraction Then			
				'if there is a malfunction, inform others
				If audienceResult.AudienceAttraction.Malfunction
					EventManager.triggerEvent(TEventSimple.Create("BroadcastManager.BroadcastMalfunction", new TData.addNumber("playerID", playerID), self))
				Endif
			EndIf
		Next

		bc.FindTopValues()
		ChangeImageCauseOfBroadcast(bc)
		'store current broadcast
		'currentBroadcast = bc
		Return bc
	End Method


	Function ChangeImageCauseOfBroadcast(bc:TBroadcast)
		If (bc.TopAudience > 1000) 'Nur etwas ändern, wenn auch ein paar Zuschauer einschalten und nicht alle Sendeausfall haben.
			Local modification:TAudience = TBroadcast.GetPotentialAudienceForHour(TAudience.CreateAndInitValue(1))

			'If (broadcastType = 0) Then 'Movies
				Local map:TMap = CreateMap()

				Local attrList:TList = CreateList()
				For Local i:Int = 1 To 4 'TODO: Was passiert wenn ein Spieler ausscheidet?
					map.Insert(string.FromInt(i), TAudience.CreateAndInitValue(0))
					If bc.GetAudienceResult(i).AudienceAttraction Then
						attrList.AddLast(bc.GetAudienceResult(i).AudienceAttraction.PublicImageAttraction)
					EndIf
				Next

				TPublicImage.ChangeForTargetGroup(map, 1, attrList, TAudience.ChildrenSort)
				TPublicImage.ChangeForTargetGroup(map, 2, attrList, TAudience.TeenagersSort)
				TPublicImage.ChangeForTargetGroup(map, 3, attrList, TAudience.HouseWifesSort)
				TPublicImage.ChangeForTargetGroup(map, 4, attrList, TAudience.EmployeesSort)
				TPublicImage.ChangeForTargetGroup(map, 5, attrList, TAudience.UnemployedSort)
				TPublicImage.ChangeForTargetGroup(map, 6, attrList, TAudience.ManagerSort)
				TPublicImage.ChangeForTargetGroup(map, 7, attrList, TAudience.PensionersSort)
				TPublicImage.ChangeForTargetGroup(map, 8, attrList, TAudience.WomenSort)
				TPublicImage.ChangeForTargetGroup(map, 9, attrList, TAudience.MenSort)

				For Local i:Int = 1 To 4 'TODO: Was passiert wenn ein Spieler ausscheidet?
					Local audience:TAudience = TAudience(map.ValueForKey(string.FromInt(i)))
					audience.Multiply(modification)
					Local publicImage:TPublicImage = GetPublicImageCollection().Get(i)
					If publicImage Then publicImage.ChangeImage(audience)
				Next
			'Endif
		End If
	End Function



End Type

'===== CONVENIENCE ACCESSOR =====
Function GetBroadcastManager:TBroadcastManager()
	Return TBroadcastManager.GetInstance()
End Function




'In dieser Klasse und in TAudienceMarketCalculation findet die eigentliche
'Quotenberechnung statt und es wird das Ergebnis gecached, so dass man die
'Berechnung einige Zeit aufbewahren kann.
Type TBroadcast
	'Für welche Stunde gilt dieser Broadcast
	Field Hour:Int = -1
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
	Field TopAudience:Int
	'Die höchste Zuschauerquote
	Field TopAudienceRate:Float
	'Die Programmattraktivität
	Field TopAttraction:Float
	'Die beste Programmqualität
	Field TopQuality:Float

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
	Method ComputeAudience( lastMovieBroadcast:TBroadcast,lastNewsShowBroadcast:TBroadcast )
		AudienceResults[0] = New TAudienceResult
		AudienceResults[1] = New TAudienceResult
		AudienceResults[2] = New TAudienceResult
		AudienceResults[3] = New TAudienceResult

		ComputeAndSetPlayersProgrammeAttraction(lastMovieBroadcast, lastNewsShowBroadcast)

		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			market.ComputeAudience(Hour)
			AssimilateResults(market)
		Next

		AudienceResults[0].Refresh()
		AudienceResults[1].Refresh()
		AudienceResults[2].Refresh()
		AudienceResults[3].Refresh()
	End Method


	'recomputes the audience only for a given player
	'other players get ignored in calculations and do not get
	'the lost audience added to them. 
	Method ReComputeAudienceOnlyForPlayer(playerId:Int, lastMovieBroadcast:TBroadcast, lastNewsShowBroadcast:TBroadcast)
		'recomposite markets in case of changes
		AscertainPlayerMarkets()
		
		SetAudienceResult(playerId, New TAudienceResult)
'		GetAudienceResult(playerId).Reset()

		ComputeAndSetPlayersProgrammeAttractionForPlayer(playerId, lastMovieBroadcast, lastNewsShowBroadcast)

		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			market.ComputeAudience(Hour)
			AssimilateResultsForPlayer(playerId, market)
		Next
		GetAudienceResult(playerId).Refresh()
	End Method	


	Method GetMarketById:TAudienceMarketCalculation(id:String)
		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			If market.GetId() = id Then Return market
		Next
		Return Null
	End Method


	'===== Hilfsmethoden =====

	Method AssimilateResults(market:TAudienceMarketCalculation)
		For Local playerId:String = EachIn market.Players
			AssimilateResultsForPlayer(playerId.ToInt(), market)
		Next
	End Method

	
	Method AssimilateResultsForPlayer(playerId:Int, market:TAudienceMarketCalculation)
		Local result:TAudienceResult = market.GetAudienceResultOfPlayer(playerId)
		If result Then GetAudienceResult(playerId).AddResult(result)
	End Method	


	'Berechnet die Attraktivität des Programmes pro Spieler (mit Glücksfaktor) und setzt diese Infos an die Märktkalkulationen (TAudienceMarketCalculation) weiter.
	Method ComputeAndSetPlayersProgrammeAttraction(lastMovieBroadcast:TBroadcast, lastNewsShowBroadcast:TBroadcast)		
		For Local i:Int = 1 To 4
			ComputeAndSetPlayersProgrammeAttractionForPlayer(i, lastMovieBroadcast, lastNewsShowBroadcast)
		Next
	End Method
	
	
	Method ComputeAndSetPlayersProgrammeAttractionForPlayer(playerId:Int, lastMovieBroadcast:TBroadcast, lastNewsShowBroadcast:TBroadcast)
		Local broadcastedMaterial:TBroadcastMaterial = PlayersBroadcasts[playerId-1]

		Local lastMovieAttraction:TAudienceAttraction = null
		If lastMovieBroadcast then lastMovieAttraction = lastMovieBroadcast.Attractions[playerId-1]

		Local lastNewsShowAttraction:TAudienceAttraction = null
		If lastNewsShowBroadcast then lastNewsShowAttraction = lastNewsShowBroadcast.Attractions[playerId-1]

		If broadcastedMaterial Then
			GetAudienceResult(playerId).Title = broadcastedMaterial.GetTitle()
			'3. Qualität meines Programmes
			Attractions[playerId-1] = broadcastedMaterial.GetAudienceAttraction(GetWorldTime().GetDayHour(), broadcastedMaterial.currentBlockBroadcasting, lastMovieAttraction, lastNewsShowAttraction, True, true)
		Else 'dann Sendeausfall! TODO: Chef muss böse werden!
			TLogger.Log("TBroadcast.ComputeAndSetPlayersProgrammeAttraction()", "Player '" + playerId + "': Malfunction!", LOG_DEBUG)
			GetAudienceResult(playerId).Title = "Malfunction!" 'Sendeausfall
			Attractions[playerId-1] = CalculateMalfunction(lastMovieAttraction)
		End If

		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			If market.Players.Contains(String(playerId))
				market.SetPlayersProgrammeAttraction(playerId, Attractions[playerId-1])
			EndIf
		Next
	End Method	


	'Sendeausfall
	Method CalculateMalfunction:TAudienceAttraction(lastMovieAttraction:TAudienceAttraction)
		Local attraction:TAudienceAttraction = new TAudienceAttraction
		attraction.BroadcastType = 0
		If lastMovieAttraction Then
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
	End Method


	Method AddMarket(playerIDs:Int[])
		'Echt mega beschissener Code :( . Aber wie geht's mit Arrays in BlitzMax besser? Irgendwas mit Schnittmengen oder Contains?
		'Oder ein Remove eines Elements? ListFromArray geht mit Int-Arrays nicht... usw... Ich hab bisher keine Lösung.
		'Ich bräuchte sowas wie array1.remove(array2)
		'RONNY @Manuel: dafuer schreibt man Hilfsfunktionen - oder laesst den
		'               Code so wie er jetzt ist
		Local playerIDsList:TList = CreateList()
		Local withoutPlayerIDs:Int[]

		'Liste machen, damit Contains funktioniert
		For Local i:Int = EachIn playerIDs
			playerIDsList.AddLast(String(i))
		Next

		For Local i:Int = 1 To 4
			'Wie geht Contains bei Arrays?
			If Not (playerIDsList.Contains(String(i)))
				withoutPlayerIDs = withoutPlayerIDs[..withoutPlayerIDs.length + 1]
				withoutPlayerIDs[withoutPlayerIDs.length - 1] = i
			End If
		Next

		Local audience:Int = GetStationMapCollection().GetShareAudience(playerIDs, withoutPlayerIDs)
		If audience > 0 Then
			Local market:TAudienceMarketCalculation = New TAudienceMarketCalculation
			market.maxAudience = TAudience.CreateWithBreakdown(audience)
			For Local i:Int = 0 To playerIDs.length - 1
				market.AddPlayer(playerIDs[i])
			Next

			AudienceMarkets.AddLast(market)
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
				currAudience = audienceResult.Audience.GetSum()
				If (currAudience > TopAudience) Then TopAudience = currAudience

				currAudienceRate = audienceResult.GetAudienceQuote().GetAverage()
				If (currAudienceRate > TopAudienceRate) Then TopAudienceRate = currAudienceRate

				If audienceResult.AudienceAttraction Then
					currAttraction = audienceResult.AudienceAttraction.GetAverage()
					If (currAttraction > TopAttraction) Then TopAttraction = currAttraction
	
					currQuality = audienceResult.AudienceAttraction.Quality
					If (currQuality > TopQuality) Then TopQuality = currQuality
				EndIf
			Endif
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


	Method GetAudienceResult:TAudienceResult(playerID:int)
		if playerID <= 0 or playerID > AudienceResults.length then return Null
		return AudienceResults[playerID-1]
	End Method


	Method SetAudienceResult:int(playerID:int, audienceResult:TAudienceResult)
		if playerID <= 0 then return False

		if playerID > audienceResults.length then audienceResults = audienceResults[..playerID]
		
		If audienceResult and audienceResult.AudienceAttraction
			audienceResult.AudienceAttraction.SetPlayerId(playerID)			
		EndIf
		audienceResults[playerID-1] = audienceResult
	End Method




	Function GetPotentialAudienceForHour:TAudience(maxAudience:TAudience, forHour:Int = -1)
		If forHour < 0 Then forHour = GetWorldTime().GetDayHour()

		Local maxAudienceReturn:TAudience = maxAudience.Copy()
		Local modi:TAudience = Null

		'TODO: Eventuell auch in ein config-File auslagern
		Select forHour
			Case 0 modi = TAudience.CreateAndInit(2, 6, 16, 11, 21, 19, 23, 100, 100)
			Case 1 modi = TAudience.CreateAndInit(0.5, 4, 7, 7, 15, 9, 13, 100, 100)
			Case 2 modi = TAudience.CreateAndInit(0.2, 1, 4, 4, 10, 3, 8, 100, 100)
			Case 3 modi = TAudience.CreateAndInit(0.1, 1, 3, 3, 7, 2, 5, 100, 100)
			Case 4 modi = TAudience.CreateAndInit(0.1, 0.5, 2, 3, 4, 1, 3, 100, 100)
			Case 5 modi = TAudience.CreateAndInit(0.2, 1, 2, 4, 3, 3, 3, 100, 100)
			Case 6 modi = TAudience.CreateAndInit(1, 2, 3, 6, 3, 5, 4, 100, 100)
			Case 7 modi = TAudience.CreateAndInit(4, 7, 6, 8, 4, 8, 5, 100, 100)
			Case 8 modi = TAudience.CreateAndInit(5, 2, 8, 5, 7, 11, 8, 100, 100)
			Case 9 modi = TAudience.CreateAndInit(6, 2, 9, 3, 12, 7, 10, 100, 100)
			Case 10 modi = TAudience.CreateAndInit(5, 2, 9, 3, 14, 3, 11, 100, 100)
			Case 11 modi = TAudience.CreateAndInit(5, 3, 9, 4, 15, 4, 12, 100, 100)
			Case 12 modi = TAudience.CreateAndInit(7, 9, 11, 8, 15, 8, 13, 100, 100)
			Case 13 modi = TAudience.CreateAndInit(8, 12, 14, 7, 24, 6, 19, 100, 100)
			Case 14 modi = TAudience.CreateAndInit(10, 13, 15, 6, 31, 2, 21, 100, 100)
			Case 15 modi = TAudience.CreateAndInit(11, 14, 16, 6, 29, 2, 22, 100, 100)
			Case 16 modi = TAudience.CreateAndInit(11, 15, 21, 6, 35, 2, 24, 100, 100)
			Case 17 modi = TAudience.CreateAndInit(12, 16, 22, 11, 36, 3, 25, 100, 100)
			Case 18 modi = TAudience.CreateAndInit(16, 21, 24, 18, 39, 5, 34, 100, 100)
			Case 19 modi = TAudience.CreateAndInit(24, 33, 28, 28, 46, 12, 49, 100, 100)
			Case 20 modi = TAudience.CreateAndInit(16, 36, 33, 37, 56, 23, 60, 100, 100)
			Case 21 modi = TAudience.CreateAndInit(11, 32, 31, 36, 53, 25, 62, 100, 100)
			Case 22 modi = TAudience.CreateAndInit(5, 23, 30, 30, 46, 35, 49, 100, 100)
			Case 23 modi = TAudience.CreateAndInit(3, 14, 24, 20, 34, 33, 35, 100, 100)
		EndSelect

		maxAudienceReturn.Multiply(modi).MultiplyFloat(1.0/100.0)
		Return maxAudienceReturn
	End Function
End Type


'Diese Klasse ist dazu da dem UI Feedback über die aktuelle Ausstrahlung zu geben.
'For allem für die Zuschauer vor der Mattscheibe (rechts unten im Bildschirm)...
'man kann an dieser Klasse ablesen, welche Personen sichtbar sind und wie aktiv.
'Und man könnte Statements (Sprechblasen) einblenden und Feedback zum aktuellen Programm zu geben.
Type TBroadcastFeedback
	Field PlayerId:Int
	Field AudienceInterest:TAudience				'Wie sehr ist das Publikum interessiert. Werte: 0 = kein Interesse, 1 = etwas Interesse, 2 = großes Interesse, 3 = begeistert
	Field FeedbackStatements:TList = CreateList()

	Const QUALITY:String = "QUALITY"
	Const POPULARITY:String = "POPULARITY"

	Function CreateFeedback:TBroadcastFeedback(bc:TBroadcast, playerId:Int)
		Local fb:TBroadcastFeedback = new TBroadcastFeedback
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

			if material Then
				Local genreDefinition:TGenreDefinitionBase = material.GetGenreDefinition()
				If genreDefinition Then
					Local popularityValue:Float = genreDefinition.Popularity.Popularity
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

		'Ein erster Test für das Feedback... später ist natürlich ein besseres Feedback geplatn

		'Gute Uhrzeit?
		'Kommentare zu Flags
		'AudienceFlow-Kommentare
		'Kommentare zu Schauspielern
		'Kommentare zum Genre
	End Method

	Method CalculateAudienceInterestForAllowed(attr:TAudienceAttraction, maxAudience:TAudience, plausibility:TAudience, minAttraction:Float)
		'plausibility: Wer scheit wahrscheinlich zu: 0 = auf keinen Fall; 1 = möglich, aber nicht wahrscheinlich; 2 = wahrscheinlich
		Local averageAttraction:Float = attr.GetAverage()

		Local allowedTemp:TAudience = plausibility
		Local sortMap:TNumberSortMap = attr.ToNumberSortMap()
		sortMap.Sort(False)
		Local highestKVAllowedAdults:TKeyValueNumber = GetFirstAllowed(sortMap, TAudience.CreateAndInit( 0, 1, 1, 1, 1, 1, 1, 0, 0))

		If highestKVAllowedAdults.Value >= 0.9 And attr.Quality > 0.8 Then 'Top-Programm
			allowedTemp = TAudience.CreateAndInitValue(1)
			allowedTemp.Children = plausibility.Children
		EndIf

		Local highestKVAllowed:TKeyValueNumber = GetFirstAllowed(sortMap, allowedTemp)

		If (averageAttraction > minAttraction) Then
			Local attrPerMember:Float = 0.9 / allowedTemp.GetSum()
			Local familyMemberCount:Int = Int((averageAttraction - (averageAttraction Mod attrPerMember)) / attrPerMember)

			For local kv:TKeyValueNumber = eachin sortMap.Content
				If allowedTemp.Children >= 1 And kv.Key = "0" Then
					AudienceInterest.Children = AttractionToInterest(attr.Children, maxAudience.Children, allowedTemp.Children - 1)
					If AudienceInterest.Children > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.Teenagers >= 1 And kv.Key = "1" Then
					AudienceInterest.Teenagers = AttractionToInterest(attr.Teenagers, maxAudience.Teenagers, allowedTemp.Teenagers - 1)
					If AudienceInterest.Teenagers > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.HouseWifes >= 1 And kv.Key = "2" Then
					AudienceInterest.HouseWifes = AttractionToInterest(attr.HouseWifes, maxAudience.HouseWifes, allowedTemp.HouseWifes - 1)
					If AudienceInterest.HouseWifes > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.Employees >= 1 And kv.Key = "3" Then
					AudienceInterest.Employees = AttractionToInterest(attr.Employees, maxAudience.Employees, allowedTemp.Employees - 1)
					If AudienceInterest.Employees > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.Unemployed >= 1 And kv.Key = "4" Then
					AudienceInterest.Unemployed = AttractionToInterest(attr.Unemployed, maxAudience.Unemployed, allowedTemp.Unemployed - 1)
					If AudienceInterest.Unemployed > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.Manager >= 1 And kv.Key = "5" Then
					AudienceInterest.Manager = AttractionToInterest(attr.Manager, maxAudience.Manager, allowedTemp.Manager - 1)
					If AudienceInterest.Manager > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.Pensioners >= 1 And kv.Key = "6" Then
					AudienceInterest.Pensioners = AttractionToInterest(attr.Pensioners, maxAudience.Pensioners, allowedTemp.Pensioners - 1)
					If AudienceInterest.Pensioners > 0 Then familyMemberCount :- 1
				EndIf

				If familyMemberCount = 0 Then Return
			Next
		Else
			If highestKVAllowed.Value >= (minAttraction * 2) Then
				AudienceInterest.SetValue(highestKVAllowed.Key.ToInt(), 1)
			EndIf
		EndIf
	End Method

	Method CalculateAudienceInterest(bc:TBroadcast, attr:TAudienceAttraction)
		Local maxAudience:TAudience = TBroadcast.GetPotentialAudienceForHour(TAudience.CreateAndInitValue(1), bc.Hour)

		AudienceInterest = New TAudience

		If (bc.Hour >= 0 And bc.Hour <= 1)
			CalculateAudienceInterestForAllowed(attr, maxAudience, TAudience.CreateAndInit( 0, 1, 2, 1, 2, 1, 2, 0, 0), 0.2)
		Elseif (bc.Hour >= 2 And bc.Hour <= 5)
			CalculateAudienceInterestForAllowed(attr, maxAudience, TAudience.CreateAndInit( 0, 0, 1, 0, 2, 0, 2, 0, 0), 0.35)
		Elseif (bc.Hour = 6)
			CalculateAudienceInterestForAllowed(attr, maxAudience, TAudience.CreateAndInit( 1, 1, 1, 1, 0, 1, 1, 0, 0), 0.3)
		Elseif (bc.Hour >= 7 And bc.Hour <= 8)
			CalculateAudienceInterestForAllowed(attr, maxAudience, TAudience.CreateAndInit( 1, 1, 1, 1, 0, 1, 1, 0, 0), 0.2)
		Elseif (bc.Hour >= 9 And bc.Hour <= 11)
			CalculateAudienceInterestForAllowed(attr, maxAudience, TAudience.CreateAndInit( 0, 0, 2, 0, 1, 0, 2, 0, 0), 0.2)
		ElseIf (bc.Hour >= 13 And bc.Hour <= 16)
			CalculateAudienceInterestForAllowed(attr, maxAudience, TAudience.CreateAndInit( 2, 2, 2, 0, 2, 0, 2, 0, 0), 0.15)
		ElseIf (bc.Hour >= 22 And bc.Hour <= 23)
			CalculateAudienceInterestForAllowed(attr, maxAudience, TAudience.CreateAndInit( 0, 1, 2, 2, 2, 2, 2, 0, 0), 0.15)
		Else
			CalculateAudienceInterestForAllowed(attr, maxAudience, TAudience.CreateAndInit( 1, 2, 2, 2, 2, 1, 2, 0, 0), 0.15)
		EndIf
	End Method

	Method GetFirstAllowed:TKeyValueNumber(sortMap:TNumberSortMap, allowed:TAudience)
		For local kv:TKeyValueNumber = eachin sortMap.Content
			If allowed.Children >= 1 And kv.Key = "0" Then Return kv
			If allowed.Teenagers >= 1 And kv.Key = "1" Then Return kv
			If allowed.HouseWifes >= 1 And kv.Key = "2" Then Return kv
			If allowed.Employees >= 1 And kv.Key = "3" Then Return kv
			If allowed.Unemployed >= 1 And kv.Key = "4" Then Return kv
			If allowed.Manager >= 1 And kv.Key = "5" Then Return kv
			If allowed.Pensioners >= 1 And kv.Key = "6" Then Return kv
		Next
	End Method

	Method AddFeedbackStatement(importance:Int, statementKey:String, rating:Int)
		Local statement:TBroadcastFeedbackStatement = new TBroadcastFeedbackStatement
		statement.Importance = importance
		statement.StatementKey = statementKey
		statement.Rating = rating
		FeedbackStatements.AddLast(statement)
	End Method

	'Diese Methode muss aufgerufen werden, wenn ein Statement angezeigt werden soll.
	Method GetNextAudienceStatement:TBroadcastFeedbackStatement()
		Local ImportanceSum:Int

		For local statement:TBroadcastFeedbackStatement = eachin FeedbackStatements
			ImportanceSum :+ statement.Importance
		Next

		Local randomValue:Int = Rand(1,ImportanceSum)

		Local currCount:Int
		For local statement:TBroadcastFeedbackStatement = eachin FeedbackStatements
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

'Diese Klasse repräsentiert einen Markt um den 1 bis 4 Spieler konkurieren.
Type TAudienceMarketCalculation
	Field Players:TList = CreateList()				'Die Liste der Spieler die um diesen Markt kämpfen
	Field AudienceAttractions:TMap = CreateMap()	'Die Attraktivität des Programmes nach Zielgruppen. Für jeden Spieler der um diesen Markt mitkämpft gibt's einen Eintrag in der Liste
	Field MaxAudience:TAudience						'Die Einwohnerzahl (max. Zuschauer) in diesem Markt
	Field PotentialChannelSurfer:TAudience			'Die Anzahl der Leute die mal das Programm durchzappen und potentielle Zuschauer sind.
	Field AudienceResults:TAudienceResult[4]		'Die Ergebnisse in diesem Markt

	'===== Öffentliche Methoden =====

	Method GetId:String()
		Local result:String
		For Local playerId:String = EachIn Players
			result :+ playerId
		Next
		Return result
	End Method


	Method ToString:string()
		local result:string
		For Local playerId:String = EachIn Players
			result :+ playerId+" "
		Next
		return "TAudienceMarketCalculation: players=["+result.trim()+"], population="+maxAudience.GetSum()
	End Method


	Method AddPlayer(playerId:String)
		Players.AddLast(playerId)
	End Method


	Method SetPlayersProgrammeAttraction(playerId:String, audienceAttraction:TAudienceAttraction)
		If AudienceAttractions.Contains(playerId) Then AudienceAttractions.Remove(playerId)
		AudienceAttractions.insert(playerId, audienceAttraction)
	End Method


	Method GetAudienceResultOfPlayer:TAudienceResult(playerId:Int)
		Return AudienceResults[playerId-1]
	End Method


	Method ComputeAudience(forHour:Int = -1)
		If forHour <= 0 Then forHour = GetWorldTime().GetDayHour()

		CalculatePotentialChannelSurfer(forHour)

		'Die Zapper, um die noch gekämpft werden kann.
		Local ChannelSurferToShare:TAudience = PotentialChannelSurfer.Copy()
		ChannelSurferToShare.Round()

		'Ermittle wie viel ein Attractionpunkt auf Grund der Konkurrenz-
		'situation wert ist bzw. Quote bringt.
		Local reduceFactor:TAudience = GetReduceFactor()
		If reduceFactor Then
			For Local currKey:String = EachIn AudienceAttractions.Keys()
				'Die außerhalb berechnete Attraction
				Local attraction:TAudience = TAudience(MapValueForKey(AudienceAttractions, currKey))
				'Die effectiveAttraction (wegen Konkurrenz) entspricht der Quote!
				Local effectiveAttraction:TAudience = attraction.Copy().Multiply(reduceFactor)
				'Anteil an der "erbeuteten" Zapper berechnen
				Local channelSurfer:TAudience = ChannelSurferToShare.Copy().Multiply(effectiveAttraction)
				channelSurfer.Round()

				'Ergebnis in das AudienceResult schreiben
				Local currKeyInt:Int = currKey.ToInt()
				AudienceResults[currKeyInt-1] = New TAudienceResult
				AudienceResults[currKeyInt-1].PlayerId = currKeyInt
				AudienceResults[currKeyInt-1].Hour = forHour

				AudienceResults[currKeyInt-1].WholeMarket = MaxAudience
				AudienceResults[currKeyInt-1].PotentialMaxAudience = ChannelSurferToShare 'die 100% der Quote
				AudienceResults[currKeyInt-1].Audience = channelSurfer 'Die tatsächliche Zuschauerzahl

				'Keine ChannelSurferSum, dafür
				AudienceResults[currKeyInt-1].ChannelSurferToShare = ChannelSurferToShare
				AudienceResults[currKeyInt-1].AudienceAttraction = TAudienceAttraction(MapValueForKey(AudienceAttractions, currKey))
				AudienceResults[currKeyInt-1].EffectiveAudienceAttraction	= effectiveAttraction

				'Print "Effektive Quote für " + currKey + ": " + effectiveAttraction.ToString()
				'Print "Zuschauer fuer " + currKey + ": " + AudienceResults[currKeyInt].ToString()
			Next
		End If
	End Method


	Method CalculatePotentialChannelSurfer(forHour:Int)
		MaxAudience.Round()

		'Die Anzahl der potentiellen/üblichen Zuschauer um diese Zeit
		PotentialChannelSurfer = TBroadcast.GetPotentialAudienceForHour(MaxAudience, forHour)

		Local audienceFlowSum:TAudience = new TAudience
		For Local attractionTemp:TAudienceAttraction = EachIn AudienceAttractions.Values()
			audienceFlowSum.Add(attractionTemp.AudienceFlowBonus)
		Next
		audienceFlowSum.DivideFloat(Float(Players.Count()))

		'Es erhöht sich die Gesamtanzahl der Zuschauer etwas.
		PotentialChannelSurfer.Add(audienceFlowSum.Copy().MultiplyFloat(0.25))
	End Method


	Method GetReduceFactor:TAudience()
		Local attrSum:TAudience = Null		'Die Summe aller Attractionwerte
		Local attrRange:TAudience = Null	'Wie viel Prozent der Zapper bleibt bei mindestens einem Programm

		For Local attraction:TAudienceAttraction = EachIn AudienceAttractions.Values()
			If attrSum = Null Then
				attrSum = attraction.Copy()
			Else
				attrSum.Add(attraction)
			EndIf

			If attrRange = Null Then
				attrRange = attraction.Copy()
			Else
				attrRange.Children = attrRange.Children + (1 - attrRange.Children) * attraction.Children
				attrRange.Teenagers = attrRange.Teenagers + (1 - attrRange.Teenagers) * attraction.Teenagers
				attrRange.HouseWifes = attrRange.HouseWifes + (1 - attrRange.HouseWifes) * attraction.HouseWifes
				attrRange.Employees = attrRange.Employees + (1 - attrRange.Employees) * attraction.Employees
				attrRange.Unemployed = attrRange.Unemployed + (1 - attrRange.Unemployed) * attraction.Unemployed
				attrRange.Manager = attrRange.Manager + (1 - attrRange.Manager) * attraction.Manager
				attrRange.Pensioners = attrRange.Pensioners + (1 - attrRange.Pensioners) * attraction.Pensioners

				attrRange.Women = attrRange.Women + (1 - attrRange.Women) * attraction.Women
				attrRange.Men = attrRange.Men + (1 - attrRange.Men) * attraction.Men
			EndIf
		Next

		Local result:TAudience

		If attrSum Then
			result = attrRange.Copy()

			If result.GetSum() > 0 And attrSum.GetSum() > 0 Then
				result.Divide(attrSum)
			EndIf
		EndIf
		Return result
	End Method
End Type




Type TBroadcastSequence
	Field sequence:TList = CreateList()
	Field current:TBroadcast
	'how many entries should be kept for each type
	'keep all = -1
	Field amountOfEntriesToKeep:int = 3

	Method SetCurrentBroadcast(broadcast:TBroadcast)
		current = broadcast
		sequence.AddFirst( current )

		RemoveOldEntries()
	End Method


	Method RemoveOldEntries()
		'delete nothing if we have to keep all
		if amountOfEntriesToKeep < 0 then return

		local foundProgramme:int = 0
		local foundNewsShow:int = 0
		For local curr:TBroadcast = eachin sequence
			if curr.BroadcastType = TBroadcastMaterial.TYPE_PROGRAMME
				if foundProgramme < amountOfEntriesToKeep
					foundProgramme :+ 1
				else
					sequence.Remove(curr)

					'also remove no longer needed "special data"
					curr.Attractions = new TAudienceAttraction[4]
					For local i:int = 0 to 3
						curr.AudienceResults[i].PotentialMaxAudience = null
						curr.AudienceResults[i].ChannelSurferToShare = null
						curr.AudienceResults[i].AudienceAttraction = null
						curr.AudienceResults[i].EffectiveAudienceAttraction = null
					Next
				endif
			endif
			if curr.BroadcastType = TBroadcastMaterial.TYPE_NEWSSHOW
				if foundNewsShow < amountOfEntriesToKeep
					foundNewsShow :+ 1
				else
					sequence.Remove(curr)

					'also remove no longer needed "special data"
					curr.Attractions = new TAudienceAttraction[4]
					For local i:int = 0 to 3
						curr.AudienceResults[i].PotentialMaxAudience = null
						curr.AudienceResults[i].ChannelSurferToShare = null
						curr.AudienceResults[i].AudienceAttraction = null
						curr.AudienceResults[i].EffectiveAudienceAttraction = null
					Next
				endif
			endif
		Next
	End Method


	Method GetCurrentBroadcast:TBroadcast()
		Return TBroadcast(sequence.First())
	End Method

	Method GetBeforeBroadcast:TBroadcast()
		Return TBroadcast(sequence.ValueAtIndex(1))
	End Method

	Method GetBeforeProgrammeBroadcast:TBroadcast()
		Return GetFirst(TBroadcastMaterial.TYPE_PROGRAMME, false)
	End Method

	Method GetBeforeNewsShowBroadcast:TBroadcast()
		Return GetFirst(TBroadcastMaterial.TYPE_NEWSSHOW, false)
	End Method

	Method GetFirst:TBroadcast(broadcastType:int, withoutCurrent:Int = false)
		For local curr:TBroadcast = eachin sequence
			If curr <> current Or withoutCurrent Then
				If curr.BroadcastType = broadcastType Then Return curr
			Endif
		Next
		Return Null
	End Method
End Type

