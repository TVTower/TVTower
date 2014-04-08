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
ENDREM


Type TBroadcastManager
	Field initialized:int = False

	'Referenzen
	Field genreDefinitions:TMovieGenreDefinition[]			'TODO: Gehört woanders hin
	Field newsGenreDefinitions:TNewsGenreDefinition[]		'TODO: Gehört woanders hin

	Field currentBroadcast:TBroadcast = Null
	Field currentProgammeBroadcast:TBroadcast = Null
	Field currentNewsShowBroadcast:TBroadcast = Null	
	
	Field lastProgrammeBroadcast:TBroadcast = Null
	Field lastNewsShowBroadcast:TBroadcast = Null	
	
	'Für die Manipulationen von außen... funktioniert noch nicht
	Field PotentialAudienceManipulations:TMap = CreateMap()

	'===== Konstrukor, Speichern, Laden =====

	Function Create:TBroadcastManager()
		Return New TBroadcastManager 
	End Function


	'reinitializes the manager
	Method Reset()
		initialized = False
		Initialize()
	End Method


	Method Initialize()
		if initialized then return

		genreDefinitions = genreDefinitions[..21]
		Local genreMap:TMap = Assets.GetMap("genres")
		For Local asset:TAsset = EachIn genreMap.Values()
			Local definition:TMovieGenreDefinition = New TMovieGenreDefinition
			definition.LoadFromAssert(asset)
			genreDefinitions[definition.GenreId] = definition
		Next

		newsGenreDefinitions = newsGenreDefinitions[..5]
		Local newsGenreMap:TMap = Assets.GetMap("newsgenres")
		For Local asset:TAsset = EachIn newsGenreMap.Values()
			Local definition:TNewsGenreDefinition = New TNewsGenreDefinition
			definition.LoadFromAssert(asset)
			newsGenreDefinitions[definition.GenreId] = definition
		Next

		initialized = TRUE
	End Method


	'===== Öffentliche Methoden =====

	'Führt die Berechnung für die Einschaltquoten der Sendeblöcke durch
	Method BroadcastProgramme(day:Int=-1, hour:Int, recompute:Int = 0)
		self.lastProgrammeBroadcast = currentProgammeBroadcast
		self.lastNewsShowBroadcast = currentNewsShowBroadcast
		Local material:TBroadcastMaterial[] = GetPlayersBroadcastMaterial(TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
		currentProgammeBroadcast = BroadcastCommon(hour, material, recompute)
	End Method


	'Führt die Berechnung für die Nachrichten(-Show)-Ausstrahlungen durch
	Method BroadcastNewsShow(day:Int=-1, hour:Int, recompute:Int = 0)
		self.lastProgrammeBroadcast = currentProgammeBroadcast
		self.lastNewsShowBroadcast = currentNewsShowBroadcast		
		Local material:TBroadcastMaterial[] = GetPlayersBroadcastMaterial(TBroadcastMaterial.TYPE_NEWSSHOW, day, hour)
		currentNewsShowBroadcast = BroadcastCommon(hour, material, recompute)
	End Method


	Method GetMovieGenreDefinition:TMovieGenreDefinition(genreId:Int)
		Return genreDefinitions[genreId]
	End Method


	Method GetNewsGenreDefinition:TNewsGenreDefinition(genreId:Int)
		Return newsGenreDefinitions[genreId]
	End Method

	
	'===== Manipulationen =====
	
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

	'Der Ablauf des Broadcasts, verallgemeinert für Programme und News.
	Method BroadcastCommon:TBroadcast(hour:Int, broadcasts:TBroadcastMaterial[], recompute:Int )
		Local bc:TBroadcast = New TBroadcast
		bc.Hour = hour
		bc.AscertainPlayerMarkets()							'Aktuelle Märkte (um die konkuriert wird) festlegen
		bc.PlayersBroadcasts = broadcasts					'Die Programmwahl der Spieler "einloggen"
		bc.ComputeAudience(self.lastProgrammeBroadcast, self.lastNewsShowBroadcast)	'Zuschauerzahl berechnen

		'set audience for this broadcast
		For Local i:Int = 1 To 4
			Local audienceResult:TAudienceResult = bc.AudienceResults[i]
			audienceResult.AudienceAttraction.SetPlayerId(i)
			Game.GetPlayer(i).audience = audienceResult
			
			'Der KI den möglichen Sendeausfall mitteilen!
			If audienceResult.AudienceAttraction.Malfunction Then
				Local player:TPlayer = Game.GetPlayer(i)
				If Game.isGameLeader() And player.isAI() 
					player.PlayerKI.CallOnMalfunction()
				Endif
			Endif
		Next

		bc.FindTopValues()
		TPublicImage.ChangeImageCauseOfBroadcast(bc)
		'store current broadcast
		currentBroadcast = bc
		Return bc
	End Method


	'Mit dieser Methode werden die aktuellen Programme/NewsShows/Werbespots
	'der Spieler für die Berechnung und die spätere Begutachtung eingeloggt.
	Method GetPlayersBroadcastMaterial:TBroadcastMaterial[](slotType:Int, day:Int=-1, hour:Int=-1)
		Local result:TBroadcastMaterial[] = New TBroadcastMaterial[5]
		For Local player:TPlayer = EachIn Game.Players
			'sets a valid TBroadcastMaterial or Null
			result[player.playerID] = player.ProgrammePlan.GetObject(slotType, day, hour)
		Next
		Return result
	End Method
End Type



'In dieser Klasse und in TAudienceMarketCalculation findet die eigentliche
'Quotenberechnung statt und es wird das Ergebnis gecached, so dass man die
'Berechnung einige Zeit aufbewahren kann.
Type TBroadcast
	Field Hour:Int = -1							'Für welche Stunde gilt dieser Broadcast
	Field AudienceMarkets:TList = CreateList()	'Wie sahen die Märkte zu dieser Zeit aus?
	Field PlayersBroadcasts:TBroadcastMaterial[] = New TBroadcastMaterial[5] '1 bis 4. 0 Wird nicht verwendet
	Field Attractions:TAudienceAttraction[5]	'Wie Attraktiv ist das Programm für diesen Broadcast
	Field AudienceResults:TAudienceResult[5]	'Welche Zuschauerzahlen konnten ermittelt werden
	Field Feedback:TBroadcastFeedback[5]		'Cache für das Feedback. Bitte mit GetFeedback zugreifen, ist nämlich nicht immer gefüllt.
	
	Field TopAudience:Int						'Die höchste Zuschauerzahl
	Field TopAudienceRate:Float					'Die höchste Zuschauerquote
	Field TopAttraction:Float					'Die Programmattraktivität
	Field TopQuality:Float						'Die beste Programmqualität

	'===== Öffentliche Methoden =====

	'Hier werden alle Märkte in denen verschiedene Spieler miteinander
	'konkurrieren initialisiert. Diese Methode wird nur einmal aufgerufen!
	'So legt man fest um wie viel Zuschauer sich Spieler 2 und Spieler 4
	'streiten oder wie viel Zuschauer Spieler 3 alleine bedient
	Method AscertainPlayerMarkets()
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
		AudienceResults[1] = New TAudienceResult
		AudienceResults[2] = New TAudienceResult
		AudienceResults[3] = New TAudienceResult
		AudienceResults[4] = New TAudienceResult

		ComputeAndSetPlayersProgrammeAttraction(lastMovieBroadcast, lastNewsShowBroadcast)

		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			market.ComputeAudience(Hour)
			AssimilateResults(market)
		Next

		AudienceResults[1].Refresh()
		AudienceResults[2].Refresh()
		AudienceResults[3].Refresh()
		AudienceResults[4].Refresh()
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
			Local result:TAudienceResult = market.GetAudienceResultOfPlayer(playerId.ToInt())
			If result Then AudienceResults[playerId.ToInt()].AddResult(result)
		Next
	End Method


	'Berechnet die Attraktivität des Programmes pro Spieler (mit Glücksfaktor) und setzt diese Infos an die Märktkalkulationen (TAudienceMarketCalculation) weiter.
	Method ComputeAndSetPlayersProgrammeAttraction(lastMovieBroadcast:TBroadcast, lastNewsShowBroadcast:TBroadcast)	
		Local broadcastedMaterial:TBroadcastMaterial
		For Local i:Int = 1 To 4
			broadcastedMaterial = PlayersBroadcasts[i]
			
			Local lastMovieAttraction:TAudienceAttraction = null
			If lastMovieBroadcast <> Null lastMovieAttraction = lastMovieBroadcast.Attractions[i] 
			
			Local lastNewsShowAttraction:TAudienceAttraction = null
			If lastNewsShowBroadcast <> Null lastNewsShowAttraction = lastNewsShowBroadcast.Attractions[i] 			
			
			If broadcastedMaterial Then
				AudienceResults[i].Title = broadcastedMaterial.GetTitle()			
				'3. Qualität meines Programmes			
				Attractions[i] = broadcastedMaterial.GetAudienceAttraction(Game.GetHour(), broadcastedMaterial.currentBlockBroadcasting, lastMovieAttraction, lastNewsShowAttraction)			
			Else 'dann Sendeausfall! TODO: Chef muss böse werden!
				TDevHelper.Log("TBroadcast.ComputeAndSetPlayersProgrammeAttraction()", "Player '" + i + "': Malfunction!", LOG_DEBUG)		
				AudienceResults[i].Title = "Malfunction!" 'Sendeausfall
				Attractions[i] = CalculateMalfunction(lastMovieAttraction)
			End If			

			For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
				If market.Players.Contains(String(i)) Then
					market.SetPlayersProgrammeAttraction(i, TAudienceAttraction(Attractions[i]))
				EndIf
			Next
		Next
	End Method

	'Sendeausfall
	Method CalculateMalfunction:TAudienceAttraction(lastMovieAttraction:TAudienceAttraction)		
		Local attraction:TAudienceAttraction = new TAudienceAttraction
		attraction.BroadcastType = 0		
		If lastMovieAttraction Then
			attraction.Malfunction = lastMovieAttraction.Malfunction
			attraction.AudienceFlowBonus = lastMovieAttraction.GetNewInstance()
			attraction.AudienceFlowBonus.MultiplyFactor(0.02) 
			
			attraction.QualityOverTimeEffectMod = -0.2 * attraction.Malfunction
		Else
			attraction.QualityOverTimeEffectMod = -0.9
		End If								
		attraction.CalculateBaseAttraction()
		attraction.CalculateBroadcastAttraction()				
		attraction.CalculateBlockAttraction()
		attraction.CalculatePublicImageAttraction()
		attraction.Malfunction = attraction.Malfunction + 1
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

		Local audience:Int = StationMapCollection.GetShareAudience(playerIDs, withoutPlayerIDs)
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
		
		For Local i:Int = 1 To 4
			Local audienceResult:TAudienceResult = AudienceResults[i]
			If audienceResult Then
				currAudience = audienceResult.Audience.GetSum()
				If (currAudience > TopAudience) Then TopAudience = currAudience
				
				currAudienceRate = audienceResult.AudienceQuote.Average
				If (currAudienceRate > TopAudienceRate) Then TopAudienceRate = currAudienceRate
				
				currAttraction = audienceResult.AudienceAttraction.CalcAverage()
				If (currAttraction > TopAttraction) Then TopAttraction = currAttraction			
				
				currQuality = audienceResult.AudienceAttraction.Quality
				If (currQuality > TopQuality) Then TopQuality = currQuality					
			Endif
		Next	
	End Method		
	
	
	Method GetFeedback:TBroadcastFeedback(playerId:Int)
		Local currFeedback:TBroadcastFeedback = Feedback[playerId]
		If Not currFeedback Then			
			currFeedback = TBroadcastFeedback.CreateFeedback(Self, playerId)
			Feedback[playerId] = currFeedback
		End If		
		
		Return currFeedback
	End Method


	Function GetPotentialAudienceForHour:TAudience(maxAudience:TAudience, forHour:Int = -1)
		If forHour < 0 Then forHour = Game.GetHour()

		Local maxAudienceReturn:TAudience = maxAudience.GetNewInstance()
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

		maxAudienceReturn.Multiply(modi).MultiplyFactor(1.0/100.0)
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
		Local material:TBroadcastMaterial = bc.PlayersBroadcasts[PlayerId]
		Local result:TAudienceResult = bc.AudienceResults[PlayerId]
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
		Local averageAttraction:Float = attr.RecalcAverage()
		
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
	Field AudienceResults:TAudienceResult[5]		'Die Ergebnisse in diesem Markt

	'===== Öffentliche Methoden =====

	Method GetId:String()
		Local result:String
		For Local playerId:String = EachIn Players
			result :+ playerId
		Next
		Return result
	End Method


	Method AddPlayer(playerId:String)
		Players.AddLast(playerId)
	End Method


	Method SetPlayersProgrammeAttraction(playerId:String, audienceAttraction:TAudienceAttraction)
		AudienceAttractions.insert(playerId, audienceAttraction)
	End Method


	Method GetAudienceResultOfPlayer:TAudienceResult(playerId:Int)
		Return AudienceResults[playerId]
	End Method

	
	Method ComputeAudience(forHour:Int = -1)
		If forHour <= 0 Then forHour = Game.GetHour()

		CalculatePotentialChannelSurfer(forHour)			

		'Die Zapper, um die noch gekämpft werden kann.
		Local ChannelSurferToShare:TAudience = PotentialChannelSurfer.GetNewInstance()
		ChannelSurferToShare.Round()

		'Ermittle wie viel ein Attractionpunkt auf Grund der Konkurrenz-
		'situation wert ist bzw. Quote bringt.		
		Local reduceFactor:TAudience = GetReduceFactor()
		If reduceFactor Then
			For Local currKey:String = EachIn AudienceAttractions.Keys()
				Local attraction:TAudience = TAudience(MapValueForKey(AudienceAttractions, currKey)) 'Die außerhalb berechnete Attraction
				Local effectiveAttraction:TAudience = attraction.GetNewInstance().Multiply(reduceFactor) 'Die effectiveAttraction (wegen Konkurrenz) entspricht der Quote!
				Local channelSurfer:TAudience = ChannelSurferToShare.GetNewInstance().Multiply(effectiveAttraction)	'Anteil an der "erbeuteten" Zapper berechnen
				channelSurfer.Round()
				
				'Ergebnis in das AudienceResult schreiben
				Local currKeyInt:Int = currKey.ToInt()
				AudienceResults[currKeyInt] = New TAudienceResult
				AudienceResults[currKeyInt].PlayerId = currKeyInt
				AudienceResults[currKeyInt].Hour = forHour

				AudienceResults[currKeyInt].WholeMarket = MaxAudience
				AudienceResults[currKeyInt].PotentialMaxAudience = ChannelSurferToShare 'die 100% der Quote
				AudienceResults[currKeyInt].Audience = channelSurfer 'Die tatsächliche Zuschauerzahl

				'Keine ChannelSurferSum, dafür
				AudienceResults[currKeyInt].ChannelSurferToShare = ChannelSurferToShare
				AudienceResults[currKeyInt].AudienceAttraction = TAudienceAttraction(MapValueForKey(AudienceAttractions, currKey))
				AudienceResults[currKeyInt].EffectiveAudienceAttraction	= effectiveAttraction

				'Print "Effektive Quote für " + currKey + ": " + effectiveAttraction.ToString()
				'Print "Zuschauer fuer " + currKey + ": " + playerAudienceResult.ToString()
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
		PotentialChannelSurfer.Add(audienceFlowSum.GetNewInstance().MultiplyFactor(0.25))		
	End Method
	
	
	Method GetReduceFactor:TAudience()
		Local attrSum:TAudience = Null		'Die Summe aller Attractionwerte
		Local attrRange:TAudience = Null	'Wie viel Prozent der Zapper bleibt bei mindestens einem Programm

		For Local attraction:TAudienceAttraction = EachIn AudienceAttractions.Values()
			If attrSum = Null Then
				attrSum = attraction.GetNewInstance()
			Else
				attrSum.Add(attraction)
			EndIf

			If attrRange = Null Then
				attrRange = attraction.GetNewInstance()
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
			result = attrRange.GetNewInstance()

			If result.GetSumFloat() > 0 And attrSum.GetSumFloat() > 0 Then
				result.Divide(attrSum)
			EndIf
		EndIf
		Return result			
	End Method	
End Type




'Das TAudienceResult ist sowas wie das zusammengefasste Ergebnis einer
'TBroadcast- und/oder TAudienceMarketCalculation-Berechnung.
Type TAudienceResult
	Field PlayerId:Int										'Optional: Die Id des Spielers zu dem das Result gehört.
	Field Hour:Int											'Zu welcher Stunde gehört das Result
	Field Title:String										'Der Titel des Programmes

	Field WholeMarket:TAudience	= New TAudience				'Der Gesamtmarkt: Also wenn alle die einen TV haben.
	Field PotentialMaxAudience:TAudience = New TAudience	'Die Gesamtzuschauerzahl die in dieser Stunde den TV angeschaltet hat! Also 100%-Quote! Summe aus allen Exklusiven, Flow-Leuten und Zappern
	Field Audience:TAudience = New TAudience				'Die Zahl der Zuschauer die erreicht wurden. Sozusagen das Ergenis das zählt und angezeigt wird.

	Field ChannelSurferToShare:TAudience = New TAudience	'Summe der Zapper die es zu verteilen gilt (ist nicht gleich eines ChannelSurferSum)

	Field AudienceAttraction:TAudienceAttraction			'Die ursprüngliche Attraktivität des Programmes, vor der Kunkurrenzsituation
	Field EffectiveAudienceAttraction:TAudience				'Die effektive Attraktivität des Programmes auf Grund der Konkurrenzsituation

	'Werden beim Refresh berechnet
	Field AudienceQuote:TAudience							'Die Zuschauerquote, relativ zu MaxAudienceThisHour
	Field PotentialMaxAudienceQuote:TAudience				'Die Quote von PotentialMaxAudience. Wie viel Prozent schalten ein und checken das Programm. Basis ist WholeMarket

	'Field MarketShare:Float								'Die reale Zuschauerquote, die aber noch nicht verwendet wird.


	'Das Ergebis des aktuellen Spielers zu aktuellen Zeit
	Function Curr:TAudienceResult(playerID:Int = -1)
		Return Game.GetPlayer(playerID).audience
	End Function


	Method AddResult(res:TAudienceResult)
		WholeMarket.Add(res.WholeMarket)
		PotentialMaxAudience.Add(res.PotentialMaxAudience)
		ChannelSurferToShare.Add(res.ChannelSurferToShare)
		Audience.Add(res.Audience)

		AudienceAttraction = res.AudienceAttraction 'Ist immer gleich, deswegen einfach zuweisen
	End Method


	'Berechnet die Quoten neu. Muss mindestens einmal aufgerufen werden.
	Method Refresh()
		Audience.FixGenderCount()
		AudienceQuote = Audience.GetNewInstance()
		AudienceQuote.Divide(PotentialMaxAudience)

		PotentialMaxAudience.FixGenderCount()
		PotentialMaxAudienceQuote = PotentialMaxAudience.GetNewInstance()
		PotentialMaxAudienceQuote.Divide(WholeMarket)
	End Method


	Method ToString:String()
		Return Audience.GetSum() + " / " + PotentialMaxAudience.GetSum() + " / " + WholeMarket.GetSum() + "      Q: " + AudienceQuote.ToStringAverage()
	End Method
End Type




'Diese Klasse repräsentiert das Publikum, dass die Summe seiner Zielgruppen ist.
'Die Klasse kann sowohl Zuschauerzahlen als auch Faktoren/Quoten beinhalten
'und stellt einige Methoden bereit die Berechnung mit Faktoren und anderen
'TAudience-Klassen ermöglichen.
Type TAudience
	Field PlayerId:Int			'Optional: Die Id des Spielers zu dem das Result gehört. Nur bei Bedarf füllen!
	'job / age group
	Field Children:Float	= 0	'Kinder
	Field Teenagers:Float	= 0	'Teenager
	Field HouseWifes:Float	= 0	'Hausfrauen
	Field Employees:Float	= 0	'Employees
	Field Unemployed:Float	= 0	'Arbeitslose
	Field Manager:Float		= 0	'Manager
	Field Pensioners:Float	= 0	'Rentner
	'gender
	Field Women:Float		= 0	'Frauen
	Field Men:Float			= 0	'Männer

	Field Average:Float


	Function CreateWithBreakdown:TAudience(audience:Int)
		Local obj:TAudience = New TAudience
		obj.Children	= audience * 0.09	'Kinder (9%)
		obj.Teenagers	= audience * 0.1	'Teenager (10%)
		'adults 60%
		obj.HouseWifes	= audience * 0.12	'Hausfrauen (20% von 60% Erwachsenen = 12%)
		obj.Employees	= audience * 0.405	'Arbeitnehmer (67,5% von 60% Erwachsenen = 40,5%)
		obj.Unemployed	= audience * 0.045	'Arbeitslose (7,5% von 60% Erwachsenen = 4,5%)
		obj.Manager		= audience * 0.03	'Manager (5% von 60% Erwachsenen = 3%)
		obj.Pensioners	= audience * 0.21	'Rentner (21%)
		'gender
		obj.Women		= obj.Children * 0.5 + obj.Teenagers * 0.5 + obj.HouseWifes * 0.9 + obj.Employees * 0.4 + obj.Unemployed * 0.4 + obj.Manager * 0.25 + obj.Pensioners * 0.55
		obj.Men			= obj.Children * 0.5 + obj.Teenagers * 0.5 + obj.HouseWifes * 0.1 + obj.Employees * 0.6 + obj.Unemployed * 0.6 + obj.Manager * 0.75 + obj.Pensioners * 0.45
		Return obj
	End Function

	Function CreateAndInitValue:TAudience(defaultValue:Float)
		Local result:TAudience = New TAudience
		result.AddFloat(defaultValue)
		Return result
	End Function	

	Function CreateAndInit:TAudience(children:Float, teenagers:Float, houseWifes:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float, women:Float, men:Float)
		Local result:TAudience = New TAudience
		result.SetValues(children, teenagers, houseWifes, employees, unemployed, manager, pensioners, women, men)
		Return result
	End Function

	Method RecalcAverage:Float()
		Average = (Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners)/7
		Return Average
	End Method
	
	Method GetByTargetID:Float(targetID:Int=0)
		Select targetID
			Case 1	Return Children
			Case 2	Return Teenagers
			Case 3	Return HouseWifes
			Case 4	Return Employees
			Case 5	Return Unemployed
			Case 6	Return Manager
			Case 7	Return Pensioners
			'gender
			Case 8 	Return Women
			Case 9	Return Men
			Default	Return 0
		End Select
	End Method


	Method GetNewInstance:TAudience()
		Return CopyTo(New TAudience)
	End Method


	Method CopyTo:TAudience(audience:TAudience)
		audience.SetValues(Children, Teenagers, HouseWifes, Employees, Unemployed, Manager, Pensioners, Women, Men)
		Return audience
	End Method


	Method SetValues(group0:Float, group1:Float, group2:Float, group3:Float, group4:Float, group5:Float, group6:Float, subgroup0:Float, subgroup1:Float)
		Children	= group0
		Teenagers	= group1
		HouseWifes	= group2
		Employees	= group3
		Unemployed	= group4
		Manager		= group5
		Pensioners	= group6
		'gender
		Women		= subgroup0
		Men			= subgroup1
	End Method
	
	
	Method SetValue(targetGroup:Int, newValue:Float)
		Select targetGroup
			Case 0
				Children = newValue
			Case 1
				Teenagers = newValue
			Case 2
				HouseWifes = newValue
			Case 3
				Employees = newValue
			Case 4
				Unemployed = newValue
			Case 5
				Manager = newValue
			Case 6
				Pensioners = newValue
			Case 7
				Women = newValue
			Case 8
				Men = newValue
		End Select
	End Method
	

	Method GetSum:Int()
		Return Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners
	End Method


	Method GetSumFloat:Float()
		Return Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners
	End Method


	Method Add:TAudience(audience:TAudience)
		'skip adding if the param is "unset"
		If Not audience Then Return Self
		Children	:+ audience.Children
		Teenagers	:+ audience.Teenagers
		HouseWifes	:+ audience.HouseWifes
		Employees	:+ audience.Employees
		Unemployed	:+ audience.Unemployed
		Manager		:+ audience.Manager
		Pensioners	:+ audience.Pensioners
		Women		:+ audience.Women
		Men			:+ audience.Men
		Return Self
	End Method
	
	
	Method AddFloat:TAudience(number:Float)
		Children	:+ number
		Teenagers	:+ number
		HouseWifes	:+ number
		Employees	:+ number
		Unemployed	:+ number
		Manager		:+ number
		Pensioners	:+ number
		Women		:+ number
		Men			:+ number
		Return Self
	End Method	


	Method Subtract:TAudience(audience:TAudience)
		'skip subtracting if the param is "unset"
		If Not audience Then Return Self
		Children	:- audience.Children
		Teenagers	:- audience.Teenagers
		HouseWifes	:- audience.HouseWifes
		Employees	:- audience.Employees
		Unemployed	:- audience.Unemployed
		Manager		:- audience.Manager
		Pensioners	:- audience.Pensioners
		Women		:- audience.Women
		Men			:- audience.Men

		Return Self
	End Method
	
	Method SubtractFloat:TAudience(number:Float)
		Children	:- number
		Teenagers	:- number
		HouseWifes	:- number
		Employees	:- number
		Unemployed	:- number
		Manager		:- number
		Pensioners	:- number
		Women		:- number
		Men			:- number
		Return Self
	End Method	


	Method Multiply:TAudience(audience:TAudience)
		Children	:* audience.Children
		Teenagers	:* audience.Teenagers
		HouseWifes	:* audience.HouseWifes
		Employees	:* audience.Employees
		Unemployed	:* audience.Unemployed
		Manager		:* audience.Manager
		Pensioners	:* audience.Pensioners
		Women		:* audience.Women
		Men			:* audience.Men
		Return Self
	End Method


	Method MultiplyFactor:TAudience(factor:Float)
		Children	:* factor
		Teenagers	:* factor
		HouseWifes	:* factor
		Employees	:* factor
		Unemployed	:* factor
		Manager		:* factor
		Pensioners	:* factor
		Women		:* factor
		Men			:* factor
		Return Self
	End Method


	Method Divide:TAudience(audience:TAudience)
		Local sum:Float = GetSumFloat()

		Children	:/ audience.Children
		Teenagers	:/ audience.Teenagers
		HouseWifes	:/ audience.HouseWifes
		Employees	:/ audience.Employees
		Unemployed	:/ audience.Unemployed
		Manager		:/ audience.Manager
		Pensioners	:/ audience.Pensioners
		Women		:/ audience.Women
		Men			:/ audience.Men
		Average		=  sum / audience.GetSumFloat()
		Return Self
	End Method

	
	Method DivideFloat:TAudience(number:Float)
		Children	:/ number
		Teenagers	:/ number
		HouseWifes	:/ number
		Employees	:/ number
		Unemployed	:/ number
		Manager		:/ number
		Pensioners	:/ number
		Women		:/ number
		Men			:/ number
		Return Self
	End Method	
	

	Method Round:TAudience()
		Children	= Ceil(Children)
		Teenagers	= Ceil(Teenagers)
		HouseWifes	= Ceil(HouseWifes)
		Employees	= Ceil(Employees)
		Unemployed	= Ceil(Unemployed)
		Manager		= Ceil(Manager)
		Pensioners	= Ceil(Pensioners)
		Women		= Ceil(Women)
		Men			= Ceil(Men)
		Return Self
	End Method


	Method FixGenderCount()
		Local GenderSum:Float = Women + Men
		Local AudienceSum:Int = GetSum();

		Women = Ceil(AudienceSum / GenderSum * Women)
		Men = Ceil(AudienceSum / GenderSum * Men)		
		Men :+ AudienceSum - Women - Men 'Den Rest bei den Männern draufrechnen/abziehen		
	End Method

	Method CalcAverage:Float()
		Average = (Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners) / 7
		Return Average
	End Method
	
	Method ToNumberSortMap:TNumberSortMap(withSubGroups:Int=false)
		Local amap:TNumberSortMap = new TNumberSortMap
		amap.Add("0", Children)
		amap.Add("1", Teenagers)
		amap.Add("2", HouseWifes)
		amap.Add("3", Employees)
		amap.Add("4", Unemployed)
		amap.Add("5", Manager)
		amap.Add("6", Pensioners)			
		If withSubGroups Then
			amap.Add("7", Women)
			amap.Add("8", Men)			
		EndIf	
		Return amap
	End Method	

	Method ToStringMinimal:String()
		Local dec:Int = 0
		Return "C:" + TFunctions.shortenFloat(Children,dec) + " / T:" + TFunctions.shortenFloat(Teenagers,dec) + " / H:" + TFunctions.shortenFloat(HouseWifes,dec) + " / E:" + TFunctions.shortenFloat(Employees,dec) + " / U:" + TFunctions.shortenFloat(Unemployed,dec) + " / M:" + TFunctions.shortenFloat(Manager,dec) + " /P:" + TFunctions.shortenFloat(Pensioners,dec)
	End Method	
	
	Method ToString:String()
		Local dec:Int = 4
		Return "Sum: " + Int(Ceil(GetSum())) + "  ( 0: " + TFunctions.shortenFloat(Children,dec) + "  - 1: " + TFunctions.shortenFloat(Teenagers,dec) + "  - 2: " + TFunctions.shortenFloat(HouseWifes,dec) + "  - 3: " + TFunctions.shortenFloat(Employees,dec) + "  - 4: " + TFunctions.shortenFloat(Unemployed,dec) + "  - 5: " + TFunctions.shortenFloat(Manager,dec) + "  - 6: " + TFunctions.shortenFloat(Pensioners,dec) + ")"
	End Method


	Method ToStringAverage:String()
		Return "Avg: " + TFunctions.shortenFloat(Average,3) + "  ( 0: " + TFunctions.shortenFloat(Children,3) + "  - 1: " + TFunctions.shortenFloat(Teenagers,3) + "  - 2: " + TFunctions.shortenFloat(HouseWifes,3) + "  - 3: " + TFunctions.shortenFloat(Employees,3) + "  - 4: " + TFunctions.shortenFloat(Unemployed,3) + "  - 5: " + TFunctions.shortenFloat(Manager,3) + "  - 6: " + TFunctions.shortenFloat(Pensioners,3) + ")"
	End Method
	
	Function ChildrenSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceAttraction = TAudienceAttraction(o1)
		Local s2:TAudienceAttraction = TAudienceAttraction(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.Children*1000)-(s2.Children*1000)
	End Function
	
	Function TeenagersSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceAttraction = TAudienceAttraction(o1)
		Local s2:TAudienceAttraction = TAudienceAttraction(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.Teenagers*1000)-(s2.Teenagers*1000)
	End Function
	
	Function HouseWifesSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceAttraction = TAudienceAttraction(o1)
		Local s2:TAudienceAttraction = TAudienceAttraction(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.HouseWifes*1000)-(s2.HouseWifes*1000)
	End Function
	
	Function EmployeesSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceAttraction = TAudienceAttraction(o1)
		Local s2:TAudienceAttraction = TAudienceAttraction(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.Employees*1000)-(s2.Employees*1000)
	End Function
	
	Function UnemployedSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceAttraction = TAudienceAttraction(o1)
		Local s2:TAudienceAttraction = TAudienceAttraction(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.Unemployed*1000)-(s2.Unemployed*1000)
	End Function
	
	Function ManagerSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceAttraction = TAudienceAttraction(o1)
		Local s2:TAudienceAttraction = TAudienceAttraction(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.Manager*1000)-(s2.Manager*1000)
	End Function
	
	Function PensionersSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceAttraction = TAudienceAttraction(o1)
		Local s2:TAudienceAttraction = TAudienceAttraction(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.Pensioners*1000)-(s2.Pensioners*1000)
	End Function
	
	Function WomenSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceAttraction = TAudienceAttraction(o1)
		Local s2:TAudienceAttraction = TAudienceAttraction(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.Women*1000)-(s2.Women*1000)
	End Function
	
	Function MenSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceAttraction = TAudienceAttraction(o1)
		Local s2:TAudienceAttraction = TAudienceAttraction(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.Men*1000)-(s2.Men*1000)
	End Function	
End Type


'Diese Klasse repräsentiert die Programmattraktivität (Inhalt von TAudience)
'Sie beinhaltet aber zusätzlich die Informationen wie sie berechnet wurde (für Statistiken, Debugging und Nachberechnungen) unf für was sieht steht.
Type TAudienceAttraction Extends TAudience	
	Field BroadcastType:Int '-1 = Sendeausfall; 1 = Film; 2 = News
	Field Quality:Float				'0 - 100
	Field GenrePopularityMod:Float	'
	Field GenreTargetGroupMod:TAudience
	Field PublicImageMod:TAudience
	Field TrailerMod:TAudience
	Field FlagsMod:TAudience
	Field AudienceFlowBonus:TAudience
	
	Field QualityOverTimeEffectMod:Float
	Field GenreTimeMod:Float
	Field NewsShowMod:Float
	
	Field BaseAttraction:TAudience
	Field BroadcastAttraction:TAudience
	Field BlockAttraction:TAudience
	Field PublicImageAttraction:TAudience
	
	Field Genre:Int
	Field Malfunction:Int '1 = Sendeausfall
	
	Function CreateAndInitAttraction:TAudienceAttraction(group0:Float, group1:Float, group2:Float, group3:Float, group4:Float, group5:Float, group6:Float, subgroup0:Float, subgroup1:Float)
		Local result:TAudienceAttraction = New TAudienceAttraction
		result.SetValues(group0, group1, group2, group3, group4, group5, group6, subgroup0, subgroup1)
		Return result
	End Function	
	
	Method SetPlayerId(playerId:Int)
		Self.PlayerId = playerId
		Self.BaseAttraction.PlayerId = playerId
		Self.BroadcastAttraction.PlayerId = playerId
		Self.BlockAttraction.PlayerId = playerId
		Self.PublicImageAttraction.PlayerId = playerId
	End Method	
	
	Method AddAttraction:TAudienceAttraction(audienceAttr:TAudienceAttraction)
		If Not audienceAttr Then Return Self
		Self.Add(audienceAttr)
		
		Quality	:+ audienceAttr.Quality
		GenrePopularityMod	:+ audienceAttr.GenrePopularityMod
		If GenreTargetGroupMod Then GenreTargetGroupMod.Add(audienceAttr.GenreTargetGroupMod)
		If PublicImageMod Then PublicImageMod.Add(audienceAttr.PublicImageMod)
		If TrailerMod Then TrailerMod.Add(audienceAttr.TrailerMod)
		If FlagsMod Then FlagsMod.Add(audienceAttr.FlagsMod)
		If AudienceFlowBonus Then AudienceFlowBonus.Add(audienceAttr.AudienceFlowBonus)
		QualityOverTimeEffectMod :+ audienceAttr.QualityOverTimeEffectMod
		GenreTimeMod :+ audienceAttr.GenreTimeMod
		NewsShowMod :+ audienceAttr.NewsShowMod
		If BaseAttraction Then BaseAttraction.Add(audienceAttr.BaseAttraction)
		If BroadcastAttraction Then BroadcastAttraction.Add(audienceAttr.BroadcastAttraction)
		If BlockAttraction Then BlockAttraction.Add(audienceAttr.BlockAttraction)
		If PublicImageAttraction Then PublicImageAttraction.Add(audienceAttr.PublicImageAttraction)

		Return Self
	End Method
	
	Method MultiplyAttrFactor:TAudienceAttraction(factor:float)
		Self.MultiplyFactor(factor)
		
		Quality	:* factor
		GenrePopularityMod 	:* factor
		If GenreTargetGroupMod Then GenreTargetGroupMod.MultiplyFactor(factor)
		If PublicImageMod Then PublicImageMod.MultiplyFactor(factor)
		If TrailerMod Then TrailerMod.MultiplyFactor(factor)
		If FlagsMod Then FlagsMod.MultiplyFactor(factor)
		If AudienceFlowBonus Then AudienceFlowBonus.MultiplyFactor(factor)
		QualityOverTimeEffectMod :* factor
		GenreTimeMod :* factor
		NewsShowMod :* factor
		If BaseAttraction Then BaseAttraction.MultiplyFactor(factor)
		If BroadcastAttraction Then BroadcastAttraction.MultiplyFactor(factor)
		If BlockAttraction Then BlockAttraction.MultiplyFactor(factor)
		If PublicImageAttraction Then PublicImageAttraction.MultiplyFactor(factor)

		Return Self		
	End Method
	
	Method CalculateBaseAttraction()
		Local Sum:TAudience = new TAudience
		Sum.AddFloat(GenrePopularityMod)
		Sum.Add(GenreTargetGroupMod)
		Sum.Add(PublicImageMod)
		Sum.Add(TrailerMod)
		Sum.Add(FlagsMod)
		Sum.AddFloat(1)
					
		Sum.MultiplyFactor(Quality)	
		Self.BaseAttraction = Sum.GetNewInstance()
		Self.BaseAttraction.PlayerId = Self.PlayerId
		Sum.CopyTo(Self)
	End Method
	
	Method CalculateBroadcastAttraction()	
		Local Sum:TAudience = new TAudience
		Sum.Add(BaseAttraction)
		If AudienceFlowBonus <> Null Then
			Sum.Add(AudienceFlowBonus)
		EndIf
		
		Self.BroadcastAttraction = Sum.GetNewInstance()
		Self.BroadcastAttraction.PlayerId = Self.PlayerId
		Sum.CopyTo(Self)
	End Method
	
	Method CalculateBlockAttraction()
		Local Sum:TAudience = new TAudience
		Sum.AddFloat(QualityOverTimeEffectMod)
		Sum.AddFloat(GenreTimeMod)
		Sum.AddFloat(NewsShowMod)
		Sum.AddFloat(1)
	
		Sum.Multiply(BroadcastAttraction)
		Self.BlockAttraction = Sum.GetNewInstance()
		Self.BlockAttraction.PlayerId = Self.PlayerId
		Sum.CopyTo(Self)				
	End Method
	
	'Die PublicImageAttraction wird dafür verwendet um zu sehen, wie gut das Programm plaziert war und wie die Qualität war.
	'Damit wird das PublicImage beeinflusst.
	Method CalculatePublicImageAttraction()
		Local Sum:TAudience = new TAudience
		Sum.AddFloat(GenrePopularityMod)
		Sum.Add(GenreTargetGroupMod)
		'Sum.Add(PublicImageMod)
		Sum.Add(TrailerMod)
		Sum.Add(FlagsMod)
		Sum.AddFloat(1)		
		
		Sum.MultiplyFactor(Quality)			
					
		If AudienceFlowBonus <> Null Then
			Sum.Add(AudienceFlowBonus)
		EndIf		
		
		Local Sum2:TAudience = new TAudience
		'Sum2.AddFloat(QualityOverTimeEffectMod)
		Sum2.AddFloat(GenreTimeMod)
		'Sum2.AddFloat(NewsShowMod)
		Sum2.AddFloat(1)
		
		Sum2.Multiply(Sum)
		
		Self.PublicImageAttraction = Sum2.GetNewInstance()		
		Self.PublicImageAttraction.PlayerId = Self.PlayerId
	End Method
	
	Method CopyBroadcastAttractionFrom(otherAudienceAttraction:TAudienceAttraction)
		PlayerId = otherAudienceAttraction.PlayerId
		Quality = otherAudienceAttraction.Quality 
		GenrePopularityMod = otherAudienceAttraction.GenrePopularityMod
		GenreTargetGroupMod = otherAudienceAttraction.GenreTargetGroupMod
		PublicImageMod = otherAudienceAttraction.PublicImageMod
		TrailerMod = otherAudienceAttraction.TrailerMod
		FlagsMod = otherAudienceAttraction.FlagsMod
		
		AudienceFlowBonus = otherAudienceAttraction.AudienceFlowBonus
		
		BaseAttraction = otherAudienceAttraction.BaseAttraction
		BlockAttraction = otherAudienceAttraction.BlockAttraction
		BroadcastAttraction = otherAudienceAttraction.BroadcastAttraction
		PublicImageAttraction = otherAudienceAttraction.PublicImageAttraction
		
		otherAudienceAttraction.CopyTo(Self)
	End Method	
End Type
