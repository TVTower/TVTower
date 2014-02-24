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
	'Referenzen
	Field genreDefinitions:TMovieGenreDefinition[]
	Field newsGenreDefinitions:TNewsGenreDefinition[]

	Field currentProgammeBroadcast:TBroadcast = Null
	Field currentNewsBroadcast:TBroadcast = Null
	Field lastBroadcast:TBroadcast = Null
	Field currentBroadcast:TBroadcast = Null

	Field TopAudienceCount:Int

	'Feature-Konstanten
	Const FEATURE_AUDIENCE_FLOW:Int = 1
	Const FEATURE_GENRE_ATTRIB_CALC:Int = 1
	Const FEATURE_GENRE_TIME_MOD:Int = 1
	Const FEATURE_GENRE_TARGETGROUP_MOD:Int = 1
	Const FEATURE_TARGETGROUP_TIME_MOD:Int = 1


	'===== Konstrukor, Speichern, Laden =====

	Function Create:TBroadcastManager()
		Local obj:TBroadcastManager = New TBroadcastManager
		Return obj
	End Function


	Method Initialize()
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
	End Method


	'===== Öffentliche Methoden =====

	'Führt die Berechnung für die Einschaltquoten der Sendeblöcke durch
	Method BroadcastProgramme(day:Int=-1, hour:Int, recompute:Int = 0)
		currentProgammeBroadcast = BroadcastCommon(hour, GetPlayersProgrammes(day, hour), recompute)
	End Method


	'Führt die Berechnung für die Nachrichten(-Show)-Ausstrahlungen durch
	Method BroadcastNewsShow(day:Int=-1, hour:Int, recompute:Int = 0)
		currentNewsBroadcast = BroadcastCommon(hour, GetPlayersNewsShow(day, hour), recompute)
	End Method


	Method GetMovieGenreDefinition:TMovieGenreDefinition(genreId:Int)
		Return genreDefinitions[genreId]
	End Method


	Method GetNewsGenreDefinition:TNewsGenreDefinition(genreId:Int)
		Return newsGenreDefinitions[genreId]
	End Method


	'===== Hilfsmethoden =====

	'Der Ablauf des Broadcasts, verallgemeinert für Programme und News.
	Method BroadcastCommon:TBroadcast(hour:Int, broadcasts:TBroadcastMaterial[],recompute:Int )
		'backup current broadcast (for later calculations)
		lastBroadcast = currentBroadcast

		Local bc:TBroadcast = New TBroadcast
		bc.Hour = hour
		bc.AscertainPlayerMarkets()							'Aktuelle Märkte (um die konkuriert wird) festlegen
		bc.PlayersBroadcasts = broadcasts					'Die Programmwahl der Spieler "einloggen"
		bc.ComputeAudience(lastBroadcast)					'Zuschauerzahl berechnen
		'If Not recompute Then bc.BroadcastConsequences()	'Konsequenzen der Ausstrahlung berechnen/aktualisieren

		'set audience for this broadcast
		For Local i:Int = 1 To 4
			'RONNY: Sorgt das Ueberspringen nicht fuer ein "uebernehmen"
			'       der vorherigen Zuschauerzahl bei einem Ausfall?
			'edit : ja macht es, normalerweise sollte "if not .." uebersprungen
			'       werden... aber ich an sich ist die "Berechnung" einfach
			'       nur nicht korrekt
			If Not bc.PlayersBroadcasts[i] Then Continue
			Game.GetPlayer(i).audience = bc.AudienceResults[i]
		Next



		CheckTopAudience(bc)
		'store current broadcast
		currentBroadcast = bc
		Return bc
	End Method


	'Mit dieser Methode werden die aktuellen Programme/NewsShows/Werbespots
	'der Spieler für die Berechnung und die spätere Begutachtung eingeloggt.
	Method GetPlayersBroadcastMaterial:TBroadcastMaterial[](slotType:Int, day:Int=-1, hour:Int=-1)
		Local result:TBroadcastMaterial[] = New TBroadcastMaterial[5]
		Local material:TBroadcastMaterial
		For Local player:TPlayer = EachIn Game.Players
			'sets a valid TBroadcastMaterial or Null
			result[player.playerID] = player.ProgrammePlan.GetObject(slotType, day, hour)
		Next
		Return result
	End Method


	Method GetPlayersProgrammes:TBroadcastMaterial[](forDay:Int, forHour:Int)
		Return GetPlayersBroadcastMaterial(TBroadcastMaterial.TYPE_PROGRAMME, forDay, forHour)
	End Method


	Method GetPlayersNewsShow:TBroadcastMaterial[](forDay:Int, forHour:Int)
		Return GetPlayersBroadcastMaterial(TBroadcastMaterial.TYPE_NEWSSHOW, forDay, forHour)
	End Method


	Method CheckTopAudience(bc:TBroadcast)
		Local currSum:Int
		For Local i:Int = 1 To 4
			currSum = bc.AudienceResults[i].Audience.GetSum()
			If (currSum > TopAudienceCount) Then TopAudienceCount = currSum
		Next
	End Method
End Type



'In dieser Klasse und in TAudienceMarketCalculation findet die eigentliche
'Quotenberechnung statt und es wird das Ergebnis gecached, so dass man die
'Berechnung einige Zeit aufbewahren kann.
Type TBroadcast
	Field Hour:Int = -1
	Field AudienceMarkets:TList = CreateList()
	Field PlayersBroadcasts:TBroadcastMaterial[] = New TBroadcastMaterial[5] '1 bis 4. 0 Wird nicht verwendet
	Field Attractions:TAudience[5]
	Field AudienceResults:TAudienceResult[5]

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
	Method ComputeAudience(lastBroadcast:TBroadcast)
		AudienceResults[1] = New TAudienceResult
		AudienceResults[2] = New TAudienceResult
		AudienceResults[3] = New TAudienceResult
		AudienceResults[4] = New TAudienceResult

		ComputeAndSetPlayersProgrammeAttraction()

		SetFixAudience()
		SetAudienceFlow(lastBroadcast)

		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			market.ComputeAudience(Hour)
			AssimilateResults(market)
		Next

		AudienceResults[1].Refresh()
		AudienceResults[2].Refresh()
		AudienceResults[3].Refresh()
		AudienceResults[4].Refresh()
	End Method

Rem
	'Die Konsequenzen der Ausstrahlung (Aktualitätsverlust usw.) werden durchgeführt
	Method BroadcastConsequences()
		Local broadcastedMaterial:TBroadcastMaterial
		Local player:TPlayer
		Local audienceResult:TAudienceResult

		For Local i:Int = 1 To 4
			player = TPlayer.getByID(i)
			broadcastedMaterial = PlayersBroadcasts[i]
			If not broadcastedMaterial then continue

			player.audience = AudienceResults[i]
			broadcastedMaterial.CheckConsequences(player)
		Next
	End Method
endrem

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
	Method ComputeAndSetPlayersProgrammeAttraction()
		Local broadcastedMaterial:TBroadcastMaterial
		For Local i:Int = 1 To 4
			broadcastedMaterial = PlayersBroadcasts[i]
			If Not broadcastedMaterial Then Continue

			AudienceResults[i].Title = broadcastedMaterial.GetTitle()

			'3. Qualität meines Programmes
			Attractions[i] = broadcastedMaterial.GetAudienceAttraction()

			For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
				If market.Players.Contains(String(i)) Then
					market.SetPlayersProgrammeAttraction(i, TAudienceAttraction(Attractions[i]))
				EndIf
			Next
		Next
	End Method


	Method SetFixAudience()
		'SetPlayersFixAudience
		Rem
		For Local i:Int = 1 To 4
			For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
				If market.Players.Contains(String(i)) Then
					market.SetPlayersFixAudience(i, TAudience.CreateWithBreakdown(1000).Round())
				Endif
			Next
		Next
		endrem
	End Method


	Method SetAudienceFlow(lastBroadcast:TBroadcast)
		Local broadcastedMaterial:TBroadcastMaterial
		If lastBroadcast <> Null Then
			Local timeMod:Float = GetAudienceFlowTimeMod()

			For Local i:Int = 1 To 4
				'Hier Quote ermitteln anhand von Genre usw.
				Local audienceFlowQuoteFactor:Float = 0

				'RONNY @Manuel: sicher dass wir einen FlowFaktor haben
				'               - auch wenn wir evtl nichts senden?
				audienceFlowQuoteFactor:+ 0.1 'Wie gut passen die Genre zusammen: 0.1 = Normal

				broadcastedMaterial = PlayersBroadcasts[i]
				If broadcastedMaterial
					audienceFlowQuoteFactor:+ (broadcastedMaterial.GetAudienceAttraction().Average / 5) 'Wie gut ist das nächste Programm (+0.0 bis +0.2)
				EndIf
				audienceFlowQuoteFactor:+ (RandRange(0, 10) / 100) 'Zufall (+0.0 bis +0.1)
				audienceFlowQuoteFactor:* timeMod 'Time-Mod
				'broadcastedMaterial.GetAudienceAttraction()

				For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
					If market.Players.Contains(String(i)) Then
						Local lastMarket:TAudienceMarketCalculation = lastBroadcast.GetMarketById(market.GetId())
						If lastMarket <> Null Then
							Local lastAudienceResult:TAudienceResult = lastMarket.GetAudienceResultOfPlayer(i)

							If lastAudienceResult <> Null Then
								Local audienceFlow:TAudience = lastAudienceResult.Audience.GetNewInstance()
								audienceFlow.MultiplyFactor(audienceFlowQuoteFactor)
								audienceFlow.Round()
								'Print "SetAudienceFlow - " + i + " Market: " + market.GetId() + " | (" + audienceFlowQuoteFactor + "): " + audienceFlow.ToString()

								market.SetPlayersAudienceFlow(i, audienceFlow.Round())
							Else
								market.SetPlayersAudienceFlow(i, TAudience.CreateWithBreakdown(0).Round())
							EndIf
						EndIf
					EndIf
				Next
			Next
		EndIf
	End Method


	Method GetAudienceFlowTimeMod:Float()
		Local hour:Int = Hour
		Local lastHour:Int = hour - 1
		If lastHour = -1 Then lastHour = 23

		Local compareAudience:TAudience = TAudience.CreateWithBreakdown(1000000)
		Local lastHourPotential:Int = GetPotentialAudienceForHour(compareAudience, lastHour).GetSum()
		Local thisHourPotential:Int = GetPotentialAudienceForHour(compareAudience, hour).GetSum()

		If (lastHourPotential < thisHourPotential)
			Return 1
		Else
			Return Float(thisHourPotential) / Float(lastHourPotential)
		EndIf
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

		Local audience:Int = TStationMap.GetShareAudience(playerIDs, withoutPlayerIDs)
		If audience > 0 Then
			Local market:TAudienceMarketCalculation = New TAudienceMarketCalculation
			market.maxAudience = TAudience.CreateWithBreakdown(audience)
			For Local i:Int = 0 To playerIDs.length - 1
				market.AddPlayer(playerIDs[i])
			Next
			AudienceMarkets.AddLast(market)
		End If
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



'Diese Klasse repräsentiert einen Markt um den 1 bis 4 Spieler konkurieren.
Type TAudienceMarketCalculation
	Field MaxAudience:TAudience						'Die Einwohnerzahl (max. Zuschauer) in diesem Markt
	Field AudienceAttractions:TMap = CreateMap()	'Die Attraktivität des Programmes nach Zielgruppen. Für jeden Spieler der um diesen Markt mitkämpft gibt's einen Eintrag in der Liste
	Field AudienceFlow:TMap = CreateMap()
	Field ExclusiveAudience:TMap = CreateMap()
	'Field AdditionalAudience:TMap = CreateMap()
	'Field AudienceResult:TMap = CreateMap()		'Das Ergebnis der Berechnung. Pro Spieler gibt's ein Ergebnis
	Field Players:TList = CreateList()				'Die Liste der Spieler die um diesen Markt kämpfen

	Field PotentialChannelSurfer:TAudience
	Field ExclusiveAudienceSum:TAudience
	Field AudienceFlowSum:TAudience
	Field ChannelSurferToShare:TAudience

	Field AudienceResults:TAudienceResult[5]

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


	Method SetPlayersExclusiveAudience(playerId:String, exclusiveAudienceValue:TAudience)
		ExclusiveAudience.Insert(playerId, exclusiveAudienceValue)
	End Method


	Method SetPlayersAudienceFlow(playerId:String, audienceFlowValue:TAudience)
		AudienceFlow.Insert(playerId, audienceFlowValue)
	End Method


	Method GetAudienceResultOfPlayer:TAudienceResult(playerId:Int)
		Return AudienceResults[playerId]
		'Return TAudience(MapValueForKey(AudienceResult, playerId))
	End Method


	Method ComputeExklusiveAudience()
		'Kultwerte und Exklusivzuschauer addieren
		For Local playerId:String = EachIn Players
			Local audienceAttractionTemp:TAudienceAttraction = TAudienceAttraction(MapValueForKey(AudienceAttractions, playerId))
			If audienceAttractionTemp <> Null Then

				'Wenn der GenrePopularityMod über 1 ist generiert er zusätzliche exklusive Zuschauer
				If (audienceAttractionTemp.GenrePopularityMod > 1) Then
					Local exclusiveAud:TAudience = PotentialChannelSurfer.GetNewInstance()
					exclusiveAud.MultiplyFactor((audienceAttractionTemp.GenrePopularityMod - 1) / 5)
					ExclusiveAudience.Insert(playerId, exclusiveAud.Round() ) 'TODO... nicht kompatibel mit dem anderen FixAudience von außen (SetPlayersFixAudience)
				EndIf
			EndIf
		Next

		'Leute die Extra für dieses Programm einschalten aufsummieren
		For Local exclusiveAudience:TAudience = EachIn ExclusiveAudience.Values()
			If ExclusiveAudienceSum = Null Then ExclusiveAudienceSum = New TAudience
			ExclusiveAudienceSum.Add(exclusiveAudience)
		Next
	End Method


	Method ComputeAudienceFlow()
		'AudienceFlow aufsummieren -> Wie viele Zuschauer sind bereits
		'an bestimmte Sender gebunden?
		'Diese gehören nicht mehr zur Durchzapper-Masse die es später zu
		'verteilen gilt.
		For Local audienceFlow:TAudience = EachIn AudienceFlow.Values()
			If AudienceFlowSum = Null Then AudienceFlowSum = New TAudience
			AudienceFlowSum.Add(audienceFlow)
		Next
	End Method


	Method ComputeAudience(forHour:Int = -1)
		If forHour <= 0 Then forHour = Game.GetHour()

		MaxAudience.Round()

		'Die Anzahl der potentiellen/üblichen Zuschauer um diese Zeit
		PotentialChannelSurfer = TBroadcast.GetPotentialAudienceForHour(MaxAudience, forHour)

		'Berechne wie viele Leute extra für dieses Programm einschalten
		ComputeExklusiveAudience() 'benötigt ein gefülltes PotentialChannelSurfer

		'Berechne den AudienceFlow
		ComputeAudienceFlow()

		'PotentialChannelSurfer um 1/4 derer aus audienceFlowSum erhöhen.
		'Dies simuliert diejenigen, die eigentlich ausschalten wollten,
		'aber dennoch hängen geblieben sind.
		'Es erhöht sich die Gesamtanzahl der Zuschauer etwas.
		If AudienceFlowSum <> Null Then PotentialChannelSurfer.Add(AudienceFlowSum.GetNewInstance().MultiplyFactor(0.25))

		'AudienceFlowSum vom PotentialChannelSurfer abziehen... dadurch
		'erhält man die übrigen Zapper, um die noch gekämpft werden kann.
		Local ChannelSurferToShare:TAudience = PotentialChannelSurfer.GetNewInstance()
		If AudienceFlowSum <> Null Then ChannelSurferToShare.Subtract(AudienceFlowSum)
		ChannelSurferToShare.Round()

		'Gesamtzuschauerzahl aufsummieren. Entspricht den 100% bei der
		'Einschaltquote.
		'Eigentlich müssten davon noch jene Zapper abgezogen die sich für
		'kein Programm entscheiden, dies wie Spieldesigntechnisch aber erstmal
		'abgelehnt, da ein Spieler sonst in einem Sendegebiet in dem nur
		'er ist 100% Quote hat. Das wäre zwar im Realen korrekt aber nicht
		'in der MadTV-Tradition
		Local potentialMaxAudience:TAudience = New TAudience
		potentialMaxAudience.Add(ChannelSurferToShare)
		potentialMaxAudience.Add(ExclusiveAudienceSum)
		potentialMaxAudience.Add(AudienceFlowSum)


		'Ermittle wie viel ein Attractionpunkt auf Grund der Konkurrenz-
		'situation wert ist bzw. Quote bringt.

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

		If attrSum Then
			Local reduceFactor:TAudience = attrRange.GetNewInstance()

			If reduceFactor.GetSumFloat() > 0 And attrSum.GetSumFloat() > 0 Then
				reduceFactor.Divide(attrSum)
			EndIf

			For Local currKey:String = EachIn AudienceAttractions.Keys()
				Local attraction:TAudience = TAudience(MapValueForKey(AudienceAttractions, currKey)) 'Die außerhalb berechnete Attraction
				Local effectiveAttraction:TAudience = attraction.GetNewInstance().Multiply(reduceFactor) 'Die effectiveAttraction (wegen Konkurrenz) entspricht der Quote!
				Local channelSurfer:TAudience = ChannelSurferToShare.GetNewInstance().Multiply(effectiveAttraction)	'Anteil an der "erbeuteten" Zapper berechnen
				channelSurfer.Round()

				'Zuschauerzahlen für den Spieler summieren
				Local playerAudienceResult:TAudience = New TAudience
				playerAudienceResult.Add(TAudience(MapValueForKey(ExclusiveAudience, currKey))) 'Die festen Zuschauer
				playerAudienceResult.Add(TAudience(MapValueForKey(AudienceFlow, currKey))) 		'Der AudienceFlow
				playerAudienceResult.Add(channelSurfer)											'Die Zapper
				playerAudienceResult.Round()

				'Ergebnis in das AudienceResult schreiben
				Local currKeyInt:Int = currKey.ToInt()
				AudienceResults[currKeyInt] = New TAudienceResult
				AudienceResults[currKeyInt].PlayerId = currKeyInt
				AudienceResults[currKeyInt].Hour = forHour

				AudienceResults[currKeyInt].WholeMarket = MaxAudience
				AudienceResults[currKeyInt].PotentialMaxAudience = potentialMaxAudience 'die 100% der Quote
				AudienceResults[currKeyInt].Audience = playerAudienceResult 'Die tatsächliche Zuschauerzahl

				'Teilmengen der Zuschauerzahl: Exklusive, Audience Flow und Zapper
				AudienceResults[currKeyInt].ExclusiveAudience = TAudience(MapValueForKey(ExclusiveAudience, currKey))
				AudienceResults[currKeyInt].AudienceFlow = TAudience(MapValueForKey(AudienceFlow, currKey))
				AudienceResults[currKeyInt].ChannelSurfer = channelSurfer

				AudienceResults[currKeyInt].ExclusiveAudienceSum = ExclusiveAudienceSum
				AudienceResults[currKeyInt].AudienceFlowSum = audienceFlowSum
				'Keine ChannelSurferSum, dafür
				AudienceResults[currKeyInt].ChannelSurferToShare = ChannelSurferToShare

				AudienceResults[currKeyInt].AudienceAttraction = TAudienceAttraction(MapValueForKey(AudienceAttractions, currKey))
				AudienceResults[currKeyInt].EffectiveAudienceAttraction	= effectiveAttraction

				'Print "Effektive Quote für " + currKey + ": " + effectiveAttraction.ToString()
				'Print "Zuschauer fuer " + currKey + ": " + playerAudienceResult.ToString()
			Next
		End If
	End Method
End Type




'Das TAudienceResult ist sowas wie das zusammengefasste Ergebnis einer
'TBroadcast- und/oder TAudienceMarketCalculation-Berechnung.
Type TAudienceResult
	Field PlayerId:Int										'Die Id des Spielers zu dem das Result gehört
	Field Hour:Int											'Zu welcher Stunde gehört das Result
	Field Title:String										'Der Titel des Programmes

	Field WholeMarket:TAudience	= New TAudience				'Der Gesamtmarkt: Also wenn alle die einen TV haben.
	Field PotentialMaxAudience:TAudience = New TAudience	'Die Gesamtzuschauerzahl die in dieser Stunde den TV angeschaltet hat! Also 100%-Quote! Summe aus allen Exklusiven, Flow-Leuten und Zappern
	Field Audience:TAudience = New TAudience				'Die Zahl der Zuschauer die erreicht wurden. Sozusagen das Ergenis das zählt und angezeigt wird.

	'Das sind die drei Teilmengen von Audience (also der Zuschauerzahl)
	Field ExclusiveAudience:TAudience = New TAudience		'Zuschauer die nur wegen meinem Programm
	Field AudienceFlow:TAudience = New TAudience			'Zuschauer die aus dem vorangegangenen Programmblock drangeblieben sind
	Field ChannelSurfer:TAudience = New TAudience			'Zuschauer die reingezappt haben und hängen geblieben sind.

	'Aufsummierung der Zuschauerwerte ALLER Spieler... nicht nur meiner!
	Field ExclusiveAudienceSum:TAudience = New TAudience	'Summe aller Exklusiven
	Field AudienceFlowSum:TAudience = New TAudience			'Summe aller aus dem Audience Flow
	Field ChannelSurferToShare:TAudience = New TAudience	'Summe der Zapper die es zu verteilen gilt (ist nicht gleich eines ChannelSurferSum)

	Field AudienceAttraction:TAudienceAttraction			'Die ursprüngliche Attraktivität des Programmes
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
		ChannelSurfer.Add(res.ChannelSurfer)
		PotentialMaxAudience.Add(res.PotentialMaxAudience)
		AudienceFlow.Add(res.AudienceFlow)
		ExclusiveAudience.Add(res.ExclusiveAudience)
		AudienceFlowSum.Add(res.AudienceFlowSum)
		ExclusiveAudienceSum.Add(res.ExclusiveAudienceSum)
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


	Function CreateAndInit:TAudience(group0:Float, group1:Float, group2:Float, group3:Float, group4:Float, group5:Float, group6:Float, subgroup0:Float, subgroup1:Float)
		Local result:TAudience = New TAudience
		result.SetValues(group0, group1, group2, group3, group4, group5, group6, subgroup0, subgroup1)
		Return result
	End Function


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


	Method ToString:String()
		Return "Sum: " + Int(Ceil(GetSum())) + "  ( 0: " + TFunctions.shortenFloat(Children,2) + "  - 1: " + TFunctions.shortenFloat(Teenagers,2) + "  - 2: " + TFunctions.shortenFloat(HouseWifes,2) + "  - 3: " + TFunctions.shortenFloat(Employees,2) + "  - 4: " + TFunctions.shortenFloat(Unemployed,2) + "  - 5: " + TFunctions.shortenFloat(Manager,2) + "  - 6: " + TFunctions.shortenFloat(Pensioners,2) + ")"
	End Method


	Method ToStringAverage:String()
		Return "Avg: " + TFunctions.shortenFloat(Average,3) + "  ( 0: " + TFunctions.shortenFloat(Children,3) + "  - 1: " + TFunctions.shortenFloat(Teenagers,3) + "  - 2: " + TFunctions.shortenFloat(HouseWifes,3) + "  - 3: " + TFunctions.shortenFloat(Employees,3) + "  - 4: " + TFunctions.shortenFloat(Unemployed,3) + "  - 5: " + TFunctions.shortenFloat(Manager,3) + "  - 6: " + TFunctions.shortenFloat(Pensioners,3) + ")"
	End Method
End Type




'Diese Ableitung von TAudience ist speziell für die Audience-Attraction.
'Sie hält einige Zusatzinformationen für das Debugging zur Anzeige und
'für die Statistiken.
Type TAudienceAttraction Extends TAudience
	Field RawQuality:Float
	Field GenrePopularityMod:Float
	Field GenrePopularityQuality:Float
	Field GenreTimeMod:Float
	Field GenreTimeQuality:Float
	Field AudienceAttraction:TAudience
	Field Genre:Int
	
	Field TrailerMod:Float
	Field TrailerQuality:Float


	Function CreateAndInitAttraction:TAudienceAttraction(group0:Float, group1:Float, group2:Float, group3:Float, group4:Float, group5:Float, group6:Float, subgroup0:Float, subgroup1:Float)
		Local result:TAudienceAttraction = New TAudienceAttraction
		result.SetValues(group0, group1, group2, group3, group4, group5, group6, subgroup0, subgroup1)
		Return result
	End Function
End Type
