Type TQuotes
	'Referenzen
	Field GenreDefinitions:TGenreDefinition[]	
	
	Field maxAudiencePercentage:Float 	= 0.3	{nosave}	'how many 0.0-1.0 (100%) audience is maximum reachable

	'Konstanten	
	Const FEATURE_AUDIENCE_FLOW:int = 1
	Const FEATURE_GENRE_ATTRIB_CALC:int = 1
	Const FEATURE_GENRE_TIME_MOD:int = 1	
	Const FEATURE_GENRE_TARGETGROUP_MOD:int = 1
	Const FEATURE_TARGETGROUP_TIME_MOD:int = 1

	
	Const MOVIE_GENRE_ACTION:Int = 0
	Const MOVIE_GENRE_THRILLER:Int = 1
	Const MOVIE_GENRE_SCIFI:Int = 2
	Const MOVIE_GENRE_COMEDY:Int = 3
	Const MOVIE_GENRE_HORROR:Int = 4
	Const MOVIE_GENRE_LOVE:Int = 5
	Const MOVIE_GENRE_EROTIC:Int = 6
	Const MOVIE_GENRE_WESTERN:Int = 7
	Const MOVIE_GENRE_LIVE:Int = 8
	Const MOVIE_GENRE_KIDS:Int = 9
	Const MOVIE_GENRE_CARTOON:Int = 10
	Const MOVIE_GENRE_MUSIC:Int = 11
	Const MOVIE_GENRE_SPORT:Int = 12
	Const MOVIE_GENRE_CULTURE:Int = 13
	Const MOVIE_GENRE_FANTASY:Int = 14
	Const MOVIE_GENRE_YELLOWPRESS:Int = 15
	Const MOVIE_GENRE_NEWS:Int = 16
	Const MOVIE_GENRE_SHOW:Int = 17
	Const MOVIE_GENRE_MONUMENTAL:Int = 18
	Const MOVIE_GENRE_FILLER:Int = 19
	Const MOVIE_GENRE_PAIDPROGRAMMING:Int = 20

	'===== Konstrukor, Speichern, Laden =====

	Function Create:TQuotes()
		Local obj:TQuotes = New TQuotes					
		Return obj
	End Function	
	
	Method Initialize()
		GenreDefinitions= GenreDefinitions[..21]
		Local genreMap:TMap = Assets.GetMap("genres")
		For Local asset:TAsset = EachIn genreMap.Values()			
			Local definition:TGenreDefinition = new TGenreDefinition
			definition.LoadFromAssert(asset)
			GenreDefinitions[definition.GenreId] = definition			
		Next		
	End Method	

	Method Save()
		'TODO: Überarbeiten
	End Method

	Method Load(loadfile:TStream)
		'TODO: Überarbeiten
	End Method

	'===== Öffentliche Methoden =====
	
	Method GetPotentialAudienceThisHour:TAudience(maxAudience:TAudience, forHour:Int= -1)
		If forHour <= 0 Then forHour = Game.GetHour()
	
		local maxAudienceReturn:TAudience = maxAudience.GetNewInstance()
		local modi:TAudience = null
		
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
		
		maxAudienceReturn.Multiply(modi, 100)
		Return maxAudienceReturn
	End Method	
	
	
	Method GetPotentialAudienceThisHourFallback:TAudience(maxAudience:TAudience, forHour:Int= -1)
		If forHour <= 0 Then forHour = Game.GetHour()

		Local maxAudienceReturn:TAudience = maxAudience.GetNewInstance()
		Local modi:float

		'based on weekday (thursday) in march 2011 - maybe add weekend
		Select forHour
			Case 0	modi = 11.40
			Case 1	modi =  6.50
			Case 2	modi =  3.80
			Case 3	modi =  3.60
			Case 4	modi =  2.25
			Case 5	modi =  3.45
			Case 6	modi =  3.25
			Case 7	modi =  4.45
			Case 8	modi =  5.05
			Case 9	modi =  5.60
			Case 10	modi =  5.85
			Case 11	modi =  6.70
			Case 12	modi =  7.85
			Case 13	modi =  9.10
			Case 14	modi = 10.20
			Case 15	modi = 10.90
			Case 16	modi = 11.45
			Case 17	modi = 14.10
			Case 18	modi = 22.95
			Case 19	modi = 33.45
			Case 20	modi = 38.70
			Case 21	modi = 37.60
			Case 22	modi = 28.60
			Case 23	modi = 18.80
		EndSelect
		modi :/ 100.0
		
		maxAudienceReturn.MultiplyFactor(modi)
		Return maxAudienceReturn
	End Method	

	Method ComputeAudience(recompute:Int = 0)
		Local block:TProgrammeBlock
		Local competition:TAudienceBroadcastCalculation = new TAudienceBroadcastCalculation
		competition.AscertainPlayerMarkets()
		
		Print "Starte Berechnung"
		For Local player:TPlayer = EachIn TPlayer.List
			block = player.ProgrammePlan.GetCurrentProgrammeBlock()
			
			If block And block.programme			
				Print "=== Spieler " + player.playerID + " ==="
				Local attraction:TAudience = ComputeAudienceAttractionForPlayer(player, block)
				competition.SetPlayersProgrammeAttraction(player.playerID, attraction)
			Endif						
		Next
		
		Print "=== Zuschauer aufteilen ==="
		competition.ComputeAudience(Game.GetHour())
		Print "=== Zuschauer aufgeteilt ==="
		
		For Local player:TPlayer = EachIn TPlayer.List
			block = player.ProgrammePlan.GetCurrentProgrammeBlock()
			
			If block And block.programme							
				player.audience2 = competition.GetAudienceForPlayer(player.playerID)
				Print "Final " + player.playerID + ": " + player.audience2.ToString()

				'AiLog[1].AddLog("BM-Audience : " + player.audience + " = maxaudience (" + player.maxaudience + ") * AudienceQuote (" + block.Programme.getAudienceQuote(player.audience/player.maxaudience)) + ") * 1000"
				'maybe someone sold a station
				If recompute
					Local quote:TAudienceQuotes = TAudienceQuotes.GetAudienceOfDate(player.playerID, Game.GetDay(), Game.GetHour(), Game.GetMinute())
					If quote <> Null
						quote.audience = player.audience2.GetSum()
						quote.audiencepercentage = Int(Floor(player.audience2.GetSum() * 1000 / player.GetMaxAudience()))
					EndIf
				Else
					TAudienceQuotes.Create(block.Programme.title + " (" + GetLocale("BLOCK") + " " + (1 + Game.GetHour() - (block.sendhour - Game.GetDay()*24)) + "/" + block.Programme.blocks, Int(Player.audience2.GetSum()), Game.GetHour(), Game.GetMinute(), Game.GetDay(), Player.playerID)
					'TAudienceQuotes.Create(block.Programme.title + " (" + GetLocale("BLOCK") + " " + (1 + Game.GetHour() - (block.sendhour - Game.GetDay()*24)) + "/" + block.Programme.blocks, Int(player.audience2.GetSum()), Int(Floor(player.audience2.GetSum() * 1000 / player.maxaudience)), Game.GetHour(), Game.GetMinute(), Game.GetDay(), player.playerID)
					'TAudienceQuotes.Create(block.Programme.title + " (" + GetLocale("BLOCK") + " " + (1 + Game.GetHour() - (block.sendhour - Game.GetDay()*24)) + "/" + block.Programme.blocks, Int(player.audience2.GetSum()), Int(Floor(player.audience2.GetSum() * 1000 / player.GetMaxAudience())), Game.GetHour(), Game.GetMinute(), Game.GetDay(), player.playerID)
				EndIf
				If block.sendHour - (Game.GetDay()*24) + block.Programme.blocks <= Game.getNextHour()
					If Not recompute
						block.Programme.CutTopicality()
						block.Programme.getPrice()
					EndIf
				EndIf
			Endif						
		Next		
				
	End Method



	
	'Alle Daten müssen vom vorherigen Film stammen
	Method GetAudienceFlowQuote:TAudience(audienceQuote:TAudience, genreId:int)
		Local audienceFlow:TAudience = audienceQuote.GetNewInstance()
		audienceFlow.MultiplyFactor(0.4) 'Faktor hängt davon ab wie gut die Genre zusammen passen
		Return audienceFlow
	End Method

	Method GetGenreDefinition:TGenreDefinition(genreId:int)
		Return genreDefinitions[genreId]
	End Method
	
	'===== Hilfsmethoden =====

	Method ComputeAudienceAttractionForPlayer:TAudience(player:TPlayer, block:TProgrammeBlock )
		'3. Qualität meines Programmes
		Local genreDefintion:TGenreDefinition = GetGenreDefinition(block.programme.Genre)		
		Local attraction:TAudience = genreDefintion.CalculateAudienceAttraction(block.programme, Game.GetHour())								
		Return attraction		
	End Method

	'===== Events =====

	'===== Netzwerk-Methoden =====

	Method Network_SendRouteChange(floornumber:Int, call:Int=0, who:Int, First:Int=False)
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method

	Method Network_ReceiveRouteChange( obj:TNetworkObject )
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method

	Method Network_SendSynchronize()
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method

	Method Network_ReceiveSynchronize( obj:TNetworkObject )
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method
End Type

'In dieser Klasse und in TAudienceMarketCalculation findet die eigentliche Quotenberechnung statt und es wird das Ergebnis gecached, so dass man die Calculation einige Zeit aufbewahren kann.
Type TAudienceBroadcastCalculation
	Field AudienceMarkets:TList = CreateList()
	
	'===== Öffentliche Methoden =====
	
	Method AscertainPlayerMarkets()	
		'Hier werden alle Märkte in denen verschiedenen Spieler miteinander konkurrieren initialisiert.
		'So legt man fest um wie viel Zuschauer sich Spieler 2 und Spieler 4 streiten oder wie viel Zuschauer Spieler 3 alleine bedient
	
		'TODO Ron: Die einzelnen Märkte aus der Station-Map füllen!
	
		Local player:TPlayer = TPlayer(TPlayer.List.First()) 'Erstmal alle... nachher aus der Stationmap
		
		AddMarket(TAudience.CreateWithBreakdown(player.GetMaxAudience()), true, true, true, true)	'1 & 2 & 3 & 4
		'AddMarket(TAudience.CreateWithBreakdown(1000), true, true, true, false) '1 & 2 & 3
		'AddMarket(TAudience.CreateWithBreakdown(1000), true, true, false, true) '1 & 2 & 4
		'AddMarket(TAudience.CreateWithBreakdown(1000), true, true, false, false) '1 & 2
		
		'AddMarket(TAudience.CreateWithBreakdown(1000), true, false, true, true) '1 & 3 & 4
		'AddMarket(TAudience.CreateWithBreakdown(1000), true, false, true, false) '1 & 3
		'AddMarket(TAudience.CreateWithBreakdown(1000), true, false, false, true) '1 & 4
		'AddMarket(TAudience.CreateWithBreakdown(1000), true, false, false, false) '1
		
		'AddMarket(TAudience.CreateWithBreakdown(1000), false, true, true, true) '2 & 3 & 4
		'AddMarket(TAudience.CreateWithBreakdown(1000), false, true, true, false) '2 & 3
		'AddMarket(TAudience.CreateWithBreakdown(1000), false, true, false, true) '2 & 4
		'AddMarket(TAudience.CreateWithBreakdown(1000), false, true, false, false) '2
		
		'AddMarket(TAudience.CreateWithBreakdown(1000), false, false, true, true) '3 & 4
		'AddMarket(TAudience.CreateWithBreakdown(1000), false, false, true, false) '3
		'AddMarket(TAudience.CreateWithBreakdown(1000), false, false, false, true) '4
		'AddMarket(TAudience.CreateWithBreakdown(1000), false, false, false, false) 'macht keinen Sinn
	End Method
	
	Method SetPlayersProgrammeAttraction(playerId:string, programmeAttraction:TAudience)
		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			If market.Players.Contains(playerId) Then
				market.SetPlayersProgrammeAttraction(playerId, programmeAttraction)
			Endif
		Next		
	End Method
	
	Method ComputeAudience(forHour:int = -1)
		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			market.ComputeAudience(forHour)
		Next
	End Method	
	
	Method GetAudienceForPlayer:TAudience(playerId:string)
		Local result:TAudience = new TAudience
		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			If market.Players.Contains(playerId) Then
				result.Add(market.GetAudienceForPlayer(playerId))
			Endif
		Next
		Return result	
	End Method	
	
	'===== Hilfsmethoden =====
	
	Method AddMarket(maxAudience:TAudience, player1:int, player2:int, player3:int, player4:int)
		Local market:TAudienceMarketCalculation = new TAudienceMarketCalculation
		market.MaxAudience = maxAudience
		If player1 Then market.AddPlayer(1)
		If player2 Then market.AddPlayer(2)
		If player3 Then market.AddPlayer(3)
		If player4 Then market.AddPlayer(4)
		AudienceMarkets.AddLast(market)			
	End Method		
End Type


'Diese Klasse repräsentiert einen Markt um den 1 bis 4 Spieler konkurieren.
'
Type TAudienceMarketCalculation
	Field MaxAudience:TAudience						'Die Einwohnerzahl (max. Zuschauer) in diesem Markt
	Field AudienceAttractions:TMap = CreateMap()	'Die Attraktivität des Programmes nach Zielgruppen. Für jeden Spieler der um diesen Markt mitkämpft gibt's einen Eintrag in der Liste
	Field AudienceResult:TMap = CreateMap()			'Das Ergebnis der Berechnung. Pro Spieler gibt's ein Ergebnis
	Field Players:TList = CreateList()				'Die Liste der Spieler die um diesen Markt kämpfen
	
	'===== Öffentliche Methoden =====
		
	Method AddPlayer(playerId:string)
		Players.AddLast(playerId)
	End Method	
	
	Method SetPlayersProgrammeAttraction(playerId:string, audienceAttraction:TAudience)
		AudienceAttractions.insert(playerId, audienceAttraction)
	End Method
	
	Method GetAudienceForPlayer:TAudience(playerId:string)
		Return TAudience(MapValueForKey(AudienceResult, playerId))
	End Method	
	
	Method ComputeAudience(forHour:int = -1)
		If forHour <= 0 Then forHour = Game.GetHour()		
		Local potentialAudienceThisHour:TAudience
						
		If Game.Quotes.FEATURE_TARGETGROUP_TIME_MOD = 1
			potentialAudienceThisHour = Game.Quotes.GetPotentialAudienceThisHour(MaxAudience, forHour)
		Else
			potentialAudienceThisHour = Game.Quotes.GetPotentialAudienceThisHourFallback(MaxAudience, forHour)
		Endif
		
		Print "Max. erreichbare Zuschauer (Einwohner): " + MaxAudience.ToString()
		Print "TV-Interessierte zu dieser Stunde: " + potentialAudienceThisHour.ToString()
				
		Local sum:TAudience = null
		Local range:TAudience = null

		For Local attraction:TAudience = EachIn AudienceAttractions.Values()			
			If sum = null Then
				sum = attraction.GetNewInstance()
			Else
				sum.Add(attraction)
			EndIf		
		
			If range = null Then
				range = attraction.GetNewInstance()
			Else
				range.Children = range.Children + (1 - range.Children) * attraction.Children
				range.Teenagers = range.Teenagers + (1 - range.Teenagers) * attraction.Teenagers
				range.HouseWifes = range.HouseWifes + (1 - range.HouseWifes) * attraction.HouseWifes
				range.Employees = range.Employees + (1 - range.Employees) * attraction.Employees
				range.Unemployed = range.Unemployed + (1 - range.Unemployed) * attraction.Unemployed
				range.Manager = range.Manager + (1 - range.Manager) * attraction.Manager
				range.Pensioners = range.Pensioners + (1 - range.Pensioners) * attraction.Pensioners
				
				range.Women = range.Women + (1 - range.Women) * attraction.Women
				range.Men = range.Men + (1 - range.Men) * attraction.Men
			Endif
		Next
		
		print "Summe aller Werte: " + sum.ToString()
		print "Quote der Zapper die dranbleiben (diese werden verteilt): " + range.ToString()
		
		Local reduceFactor:TAudience = range.GetNewInstance()
		reduceFactor.Divide(sum)			
		
		For Local key:string = EachIn AudienceAttractions.Keys()			
			Local attraction:TAudience = TAudience(MapValueForKey(AudienceAttractions, key))						
			Local effectiveAttraction:TAudience = attraction.GetNewInstance()
			effectiveAttraction.Multiply(reduceFactor)										
			
			Local playerAudienceResult:TAudience = potentialAudienceThisHour.GetNewInstance()			
			playerAudienceResult.Multiply(effectiveAttraction)		
			playerAudienceResult.Round()
			AudienceResult.insert(key, playerAudienceResult)
			
			print "Effektive Quote für " + key + ": " + effectiveAttraction.ToString()
			print "Zuschauer fuer " + key + ": " + playerAudienceResult.ToString()
		Next
	End Method	
End Type

Type TGenreDefinition
	Field GenreId:int
	Field AudienceAttraction:TAudience
	Field TimeMods:float[]
	Field Popularity:TGenrePopulartity
	
	Field OutcomeMod:float = 0.5
	Field ReviewMod:float = 0.3
	Field SpeedMod:float = 0.2
	
	Method LoadFromAssert(asset:TAsset)	
		local data:TMap = TMap(asset._object)
		GenreId = string(data.ValueForKey("id")).ToInt()
		OutcomeMod = string(data.ValueForKey("outcomeMod")).ToFloat()
		ReviewMod = string(data.ValueForKey("reviewMod")).ToFloat()
		SpeedMod = string(data.ValueForKey("speedMod")).ToFloat()
		
		TimeMods = TimeMods [..24]		
		For Local i:Int = 0 To 23
			TimeMods[i] = string(data.ValueForKey("timeMod_" + i)).ToFloat()
		Next

		AudienceAttraction= new TAudience		
		AudienceAttraction.Children = string(data.ValueForKey("Children")).ToFloat()
		AudienceAttraction.Teenagers = string(data.ValueForKey("Teenagers")).ToFloat()
		AudienceAttraction.HouseWifes = string(data.ValueForKey("HouseWifes")).ToFloat()
		AudienceAttraction.Employees = string(data.ValueForKey("Employees")).ToFloat()
		AudienceAttraction.Unemployed = string(data.ValueForKey("Unemployed")).ToFloat()
		AudienceAttraction.Manager = string(data.ValueForKey("Manager")).ToFloat()
		AudienceAttraction.Pensioners = string(data.ValueForKey("Pensioners")).ToFloat()
		AudienceAttraction.Women = string(data.ValueForKey("Women")).ToFloat()
		AudienceAttraction.Men = string(data.ValueForKey("Men")).ToFloat()	
				
		Popularity = TGenrePopulartity.Create(GenreId, RandRange(-10,10), RandRange(-25,25))
		Game.PopularityManager.AddPopularity(Popularity) 'Zum Manager hinzufügen		
		
		print "Load " + GenreId + ": " + AudienceAttraction.ToString()
		print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod 
	End Method
		
	Method GetProgrammeQuality:float(programme:TProgramme, luckFactor:int = 1)
		Local quality:Float		= 0.0
		
		If OutcomeMod > 0.0 Then
			quality =	Float(programme.Outcome) / 255.0 * OutcomeMod..
						+ Float(programme.review) / 255.0 * ReviewMod..
						+ Float(programme.speed) / 255.0 * SpeedMod
		Else
			quality =	Float(programme.review) / 255.0 * ReviewMod..
						+ Float(programme.speed) / 255.0 * SpeedMod´
		Endif

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0,100-Max(0,game.GetYear() - programme.year))
		quality :* Max(0.10, (age/ 100.0))
		
		'repetitions wont be watched that much
		quality	:*	(programme.ComputeTopicality()/255.0)^2

		If luckFactor = 1 Then
			quality = quality * 0.98 + Float(RandRange(10,20))/1000.0 '1%-Punkte bis 2%-Punkte Basis-Qualität
		Else
			quality = quality * 0.99 + 0.01 'Mindestens 1% Qualität
		Endif
		
		'no minus quote
		quality = Max(0, quality)		
		Return quality 		
	End Method
	
	Method GetProgrammeQualityFallback:float(programme:TProgramme)
		Local quality:Float		= 0.0				
		If programme.outcome > 0
			quality	=	Float(programme.Outcome) / 255.0 * 0.5..
						+Float(programme.review) / 255.0 * 0.3..
						+Float(programme.speed) / 255.0 * 0.2..
		Else 'tv shows
			quality	=	Float(programme.review) / 255.0 * 0.6..
						+Float(programme.speed) / 255.0 * 0.4..
		EndIf					

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0,100-Max(0,game.GetYear() - programme.year))
		quality :* Max(0.10, (age/ 100.0))
		
		'repetitions wont be watched that much
		quality	:*	(programme.ComputeTopicality()/255.0)^2

		'no minus quote
		quality = Max(0, quality)		
		Return quality 		
	End Method	
	

	Method CalculateAudienceAttraction:TAudience(programme:TProgramme, hour:int)
		Local rawQuality:float = 0
		Local quality:float = 0
		Local result:TAudience = null
		
		
		If Game.Quotes.FEATURE_GENRE_ATTRIB_CALC = 1 'Die Gewichtung der Attribute bei der Berechnung der Filmqualität hängt vom Genre ab
			rawQuality = GetProgrammeQuality(programme)
		Else
			rawQuality = GetProgrammeQualityFallback(programme)
		Endif		
		quality = rawQuality		
						
		If Game.Quotes.FEATURE_GENRE_TIME_MOD = 1 'Wie gut passt der Sendeplatz zum Genre		
			quality = quality * TimeMods[hour] 'Genre/Zeit-Mod		
		Endif				
		quality = Max(0, Min(98, quality))
				
		print "G" + GenreId + "   Programm-Qualität: " + quality + " (ohne Zeit-Mod: " + rawQuality + ")"	
		
		If Game.Quotes.FEATURE_GENRE_TARGETGROUP_MOD = 1 'Wie gut kommt das Genre bei den Zielgruppen an
			result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		Else
			result = TAudience.CreateAndInit:TAudience(quality, quality, quality, quality, quality, quality, quality, quality, quality)
		Endif
				
		print "G" + GenreId + "   Quali. nach Zielg.: " + result.ToStringAverage() + " (Einfluss je nach Genre)"
				
		Return result					
	End Method
	
		rem
	Method GeTAudienceMultiplierForProgramme:TAudienceMultiplier(programme:TProgramme)
		Local result:TAudience = AudienceAttraction.GetNewInstance()
		result.MultiplyFactor(GetProgrammeQuality(programme))
		Return result		
	End Method
	endrem
	Method CalculateQuotes:TAudience(quality:float)
		'Zielgruppe / 50 * Qualität
		'Local temp:float = Audience_Children / 50 * quality
		'Local extraAudience = temp/15 * temp/15
		
		Local result:TAudience = new TAudience
		result.Children = CalculateQuoteForGroup(quality, AudienceAttraction.Children)
		result.Teenagers = CalculateQuoteForGroup(quality, AudienceAttraction.Teenagers)
		result.HouseWifes = CalculateQuoteForGroup(quality, AudienceAttraction.HouseWifes)
		result.Employees = CalculateQuoteForGroup(quality, AudienceAttraction.Employees)
		result.Unemployed = CalculateQuoteForGroup(quality, AudienceAttraction.Unemployed)
		result.Manager = CalculateQuoteForGroup(quality, AudienceAttraction.Manager)
		result.Pensioners = CalculateQuoteForGroup(quality, AudienceAttraction.Pensioners)
		result.Women = CalculateQuoteForGroup(quality, AudienceAttraction.Women)
		result.Men = CalculateQuoteForGroup(quality, AudienceAttraction.Men)
		Return result
	End Method
	
	Method CalculateQuoteForGroup:Float(quality:float, targetGroupAttendance:float)
		Local result:float = 0
		
		If (quality <= targetGroupAttendance)
			result = quality + (targetGroupAttendance - quality) * quality
		Else
			result = targetGroupAttendance + (quality - targetGroupAttendance) / 5
		EndIf
		'print "     Gr: " + result + " (quality: " + quality + " / targetGroupAttendance: " + targetGroupAttendance + ")"
		
		Return result
	End Method
End Type


Type TAudience
	Field Children:float 'Kinder 
	Field Teenagers:float 'Teenagers
	Field HouseWifes:float 'Hausfrauen 
	Field Employees:float 'Employees
	Field Unemployed:float 'Unemployed
	Field Manager:float 'Manager
	Field Pensioners:float 'Rentner

	Field Women:float 'Women
	Field Men:float 'Men
	
	Function CreateWithBreakdown:TAudience(audience:int)
		Local obj:TAudience = New TAudience
		obj.Children = audience * 0.1 'Kinder (10%)
		obj.Teenagers = audience * 0.1 'Teenager (10%)
		'Erwachsene 60%
		obj.HouseWifes = audience * 0.12 'Hausfrauen (20% von 60% Erwachsenen = 12%)
		obj.Employees = audience * 0.405 'Arbeitnehmer (67,5% von 60% Erwachsenen = 40,5%)
		obj.Unemployed = audience * 0.045 'Arbeitslose (7,5% von 60% Erwachsenen = 4,5%)
		obj.Manager = audience * 0.03 'Manager (5% von 60% Erwachsenen = 3%)
		obj.Pensioners = audience * 0.2 'Rentner (20%)
		obj.Women = obj.Children * 0.5 + obj.Teenagers * 0.5 + obj.HouseWifes * 0.9 + obj.Employees * 0.4 + obj.Unemployed * 0.4 + obj.Manager * 0.25 + obj.Pensioners * 0.55		
		obj.Men = obj.Children * 0.5 + obj.Teenagers * 0.5 + obj.HouseWifes * 0.1 + obj.Employees * 0.6 + obj.Unemployed * 0.6 + obj.Manager * 0.75 + obj.Pensioners * 0.45
		Return obj
	End Function	
	
	Function CreateAndInit:TAudience(group0:float, group1:float, group2:float, group3:float, group4:float, group5:float, group6:float, subgroup0:float, subgroup1:float)
		Local result:TAudience = new TAudience
		result.SetValues(group0, group1, group2, group3, group4, group5, group6, subgroup0, subgroup1)
		Return result
	End Function		
	
	Method GetNewInstance:TAudience()
		Return CopyTo(new TAudience)
	End Method
	
	Method CopyTo:TAudience(audience:TAudience)
		audience.SetValues(Children, Teenagers, HouseWifes, Employees, Unemployed, Manager, Pensioners, Women, Men)		
		Return audience
	End Method	
	
	Method SetValues(group0:float, group1:float, group2:float, group3:float, group4:float, group5:float, group6:float, subgroup0:float, subgroup1:float)
		Children = group0
		Teenagers = group1
		HouseWifes = group2
		Employees = group3
		Unemployed = group4
		Manager = group5
		Pensioners = group6
		Women = subgroup0
		Men = subgroup1
	End Method
	
	Method GetSum:int()
		Return Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners
	End Method
	
	Method GetSumFloat:float()
		Return Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners
	End Method	
		
	Method Add(audience:TAudience)
		Children :+ audience.Children
		Teenagers :+ audience.Teenagers
		HouseWifes :+ audience.HouseWifes
		Employees :+ audience.Employees
		Unemployed :+ audience.Unemployed
		Manager :+ audience.Manager
		Pensioners :+ audience.Pensioners
		Women :+ audience.Women
		Men :+ audience.Men
	End Method	
	
	Method Multiply(audienceMultiplier:TAudience, dividorBase:float=1)
		Children :* audienceMultiplier.Children / dividorBase
		Teenagers :* audienceMultiplier.Teenagers / dividorBase
		HouseWifes :* audienceMultiplier.HouseWifes / dividorBase
		Employees :* audienceMultiplier.Employees / dividorBase
		Unemployed :* audienceMultiplier.Unemployed / dividorBase
		Manager :* audienceMultiplier.Manager / dividorBase
		Pensioners :* audienceMultiplier.Pensioners / dividorBase
		Women :* audienceMultiplier.Women / dividorBase
		Men :* audienceMultiplier.Men / dividorBase
	End Method
	
	Method MultiplyFactor(factor:float)
		Children :* factor
		Teenagers :* factor
		HouseWifes :* factor
		Employees :* factor
		Unemployed :* factor
		Manager :* factor
		Pensioners :* factor
		Women :* factor
		Men :* factor
	End Method
	
	Method Divide(audienceDividor:TAudience)
		Children :/ audienceDividor.Children
		Teenagers :/ audienceDividor.Teenagers
		HouseWifes :/ audienceDividor.HouseWifes
		Employees :/ audienceDividor.Employees
		Unemployed :/ audienceDividor.Unemployed
		Manager :/ audienceDividor.Manager
		Pensioners :/ audienceDividor.Pensioners
		Women :/ audienceDividor.Women
		Men :/ audienceDividor.Men
	End Method	
	
	Method Round()
		Children = Ceil(Children)
		Teenagers = Ceil(Teenagers)
		HouseWifes = Ceil(HouseWifes)
		Employees = Ceil(Employees)
		Unemployed = Ceil(Unemployed)
		Manager = Ceil(Manager)
		Pensioners = Ceil(Pensioners)
		Women = Ceil(Women)
		Men = Ceil(Men)
	End Method
	
	Method ToString:string()
		Return "Sum: " + Ceil(GetSum()) + "  ( 0: " + Children + "  - 1: " + Teenagers + "  - 2: " + HouseWifes + "  - 3: " + Employees + "  - 4: " + Unemployed + "  - 5: " + Manager + "  - 6: " + Pensioners + ")"
	End Method
	
	Method ToStringAverage:string()
		Return "Ave: " + GetSumFloat()/7 + "  ( 0: " + Children + "  - 1: " + Teenagers + "  - 2: " + HouseWifes + "  - 3: " + Employees + "  - 4: " + Unemployed + "  - 5: " + Manager + "  - 6: " + Pensioners + ")"
	End Method
End Type