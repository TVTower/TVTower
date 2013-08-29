Type TQuotes
	'Referenzen
	Field GenreDefinitions:TGenreDefinition[]
	Field GenrePopulartities:TGenrePopulartity[]	
	
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

	'===== Konstrukor, Speichern, Laden =====

	Function Create:TQuotes()
		Local obj:TQuotes = New TQuotes					
		Return obj
	End Function	
	
	Method Initialize()
		GenrePopulartities = GenrePopulartities[..19]		
		For Local i:Int = 0 To 18 '18 = Wert des höchsten Genres
			AddGenrePopulartity(i)
		Next		
		
		GenreDefinitions= GenreDefinitions[..19]
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

	Method CalculateMaxAudiencePercentage:Float(forHour:Int= -1)
		If forHour <= 0 Then forHour = Game.GetHour()

		'based on weekday (thursday) in march 2011 - maybe add weekend
		Select forHour
			Case 0	maxAudiencePercentage = 11.40 + Float(RandRange( -6, 6))/ 100.0 'Germany ~9 Mio
			Case 1	maxAudiencePercentage =  6.50 + Float(RandRange( -4, 4))/ 100.0 'Germany ~5 Mio
			Case 2	maxAudiencePercentage =  3.80 + Float(RandRange( -3, 3))/ 100.0
			Case 3	maxAudiencePercentage =  3.60 + Float(RandRange( -3, 3))/ 100.0
			Case 4	maxAudiencePercentage =  2.25 + Float(RandRange( -2, 2))/ 100.0
			Case 5	maxAudiencePercentage =  3.45 + Float(RandRange( -2, 2))/ 100.0 'workers awake
			Case 6	maxAudiencePercentage =  3.25 + Float(RandRange( -2, 2))/ 100.0 'some go to work
			Case 7	maxAudiencePercentage =  4.45 + Float(RandRange( -3, 3))/ 100.0 'more awake
			Case 8	maxAudiencePercentage =  5.05 + Float(RandRange( -4, 4))/ 100.0
			Case 9	maxAudiencePercentage =  5.60 + Float(RandRange( -4, 4))/ 100.0
			Case 10	maxAudiencePercentage =  5.85 + Float(RandRange( -4, 4))/ 100.0
			Case 11	maxAudiencePercentage =  6.70 + Float(RandRange( -4, 4))/ 100.0
			Case 12	maxAudiencePercentage =  7.85 + Float(RandRange( -4, 4))/ 100.0
			Case 13	maxAudiencePercentage =  9.10 + Float(RandRange( -5, 5))/ 100.0
			Case 14	maxAudiencePercentage = 10.20 + Float(RandRange( -5, 5))/ 100.0
			Case 15	maxAudiencePercentage = 10.90 + Float(RandRange( -5, 5))/ 100.0
			Case 16	maxAudiencePercentage = 11.45 + Float(RandRange( -6, 6))/ 100.0
			Case 17	maxAudiencePercentage = 14.10 + Float(RandRange( -7, 7))/ 100.0 'people come home
			Case 18	maxAudiencePercentage = 22.95 + Float(RandRange( -8, 8))/ 100.0 'meal + worker coming home
			Case 19	maxAudiencePercentage = 33.45 + Float(RandRange(-10,10))/ 100.0
			Case 20	maxAudiencePercentage = 38.70 + Float(RandRange(-15,15))/ 100.0
			Case 21	maxAudiencePercentage = 37.60 + Float(RandRange(-15,15))/ 100.0
			Case 22	maxAudiencePercentage = 28.60 + Float(RandRange( -9, 9))/ 100.0 'bed time starts
			Case 23	maxAudiencePercentage = 18.80 + Float(RandRange( -7, 7))/ 100.0
		EndSelect
		maxAudiencePercentage :/ 100.0

		Return maxAudiencePercentage
	End Method
rem
	Method GetMaxAudienceForHour(audience:TAudienceOld, forHour:Int= -1)
		If forHour <= 0 Then forHour = Game.GetHour()

	End Method
endrem
	Method GetMaxAudience:TAudience()
		local audience:TAudience = TAudience.CreateWithBreakdown(100000)
		Return audience
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
	
	Method GetPotentialAudienceThisHour:TAudience(maxAudience:TAudience, forHour:Int= -1)
		If forHour <= 0 Then forHour = Game.GetHour()
	
		local maxAudienceReturn:TAudience = maxAudience.GetNewInstance()
		local modi:TAudience = null
			
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

	Method ComputeAudienceForAllPlayers(recompute:Int = 0)
		Local block:TProgrammeBlock

		For Local player:TPlayer = EachIn TPlayer.List
			block = player.ProgrammePlan.GetCurrentProgrammeBlock()
			
			'Hier AudienceFlow-Zeug
				'Local audienceFlow:TAudience = GetAudienceFlowQuote()			
				'Local lastQuoteForAudienceFlow:float = Player.audience/Player.maxaudience			
			
			'player.audience = 0
			player.audience2 = new TAudience
			
			'1. Alle erreichbaren Zuschauer, wenn alle ihren TV anschalten			
			Local maxAudience:TAudience = TAudience.CreateWithBreakdown(Player.GetMaxAudience())  ''Local maxAudience:TAudience = GetMaxAudience()

			If block And block.programme And maxAudience.GetSum() > 0				
				Local playerAudience:TAudience = ComputeAudienceForPlayer(player, block, maxAudience)
				'player.audience = Floor(playerAudience.GetSum())
				player.audience2 = playerAudience

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
			EndIf
		Next	
	End Method
	
	'Alle Daten müssen vom vorherigen Film stammen
	Method GetAudienceFlowQuote:TAudience(audienceQuote:TAudience, genreId:int)
		Local audienceFlow:TAudience = audienceQuote.GetNewInstance()
		audienceFlow.MultiplyFactor(0.4) 'Faktor hängt davon ab wie gut die Genre zusammen passen
		Return audienceFlow
	End Method
	
	Method ComputeAudienceForPlayer:TAudience(player:TPlayer, block:TProgrammeBlock, maxAudience:TAudience )
		Local potentialAudienceThisHour:TAudience
		
		print "1: " + maxAudience.ToString()
		
		'2. Alle potentiellen Zuschauer / alle TV-Geräte / die gesamte Reichweite
		
		If Game.Quotes.FEATURE_TARGETGROUP_TIME_MOD = 1
			potentialAudienceThisHour = GetPotentialAudienceThisHour(maxAudience, Game.GetHour())
		Else
			potentialAudienceThisHour = GetPotentialAudienceThisHourFallback(maxAudience, Game.GetHour())
		Endif
		print "2: " + potentialAudienceThisHour.ToString()
		
		'3. Qualität meines Programmes
		'Local genreDefintion:TGenreDefinition = GetGenreDefinition(block.programme.Genre)
		Local genreDefintion:TGenreDefinition = GetGenreDefinition(0)
		
		Local attraction:TAudience = genreDefintion.CalculateAudienceAttraction(block.programme, Game.GetHour())
		print "3 - Attr: " + attraction.ToString()
		
						
		potentialAudienceThisHour.Multiply(attraction)		
		
		print "3: " + potentialAudienceThisHour.ToString()
		

'		print "3.1: " + potentialAudienceThisHour.GetSum()
		'player.audience = potentialAudienceThisHour.GetSum()
		'TAudienceQuotes.Create(block.Programme.title + " (" + GetLocale("BLOCK") + " " + (1 + Game.GetHour() - (block.sendhour - Game.GetDay()*24)) + "/" + block.Programme.blocks, Int(Player.audience), Int(Floor(Player.audience * 1000 / Player.maxaudience)), Game.GetHour(), Game.GetMinute(), Game.GetDay(), Player.playerID)
'print "4"

		Return potentialAudienceThisHour		
	End Method

	Method ComputeAudiencePlayerOne:TAudience(recompute:Int = 0)
		Local player:TPlayer = TPlayer(TPlayer.List.First())

		'1. Alle erreichbaren Zuschauer, wenn alle ihren TV anschalten
		'Local maxAudience:TAudience = GetMaxAudience()
		Local maxAudience:TAudience = TAudience.CreateWithBreakdown(Player.GetMaxAudience())
		print "1: " + maxAudience.ToString()

		'2. Alle potentiellen Zuschauer / alle TV-Geräte / die gesamte Reichweite
		Local potentialAudienceThisHour:TAudience = GetPotentialAudienceThisHour(maxAudience, Game.GetHour())
		print "2: " + potentialAudienceThisHour.ToString()
		
		'3. Qualität meines Programmes
		Local block:TProgrammeBlock = player.ProgrammePlan.GetCurrentProgrammeBlock()
		'Local genreDefintion:TGenreDefinition = GetGenreDefinition(block.programme.Genre)
		Local genreDefintion:TGenreDefinition = GetGenreDefinition(0)
		
		Local attraction:TAudience = genreDefintion.CalculateAudienceAttraction(block.programme, Game.GetHour())
		print "3 - Attr: " + attraction.ToString()
		
		potentialAudienceThisHour.Multiply(attraction)		
		
		print "3: " + potentialAudienceThisHour.ToString()
		

'		print "3.1: " + potentialAudienceThisHour.GetSum()
		'player.audience = potentialAudienceThisHour.GetSum()
		'TAudienceQuotes.Create(block.Programme.title + " (" + GetLocale("BLOCK") + " " + (1 + Game.GetHour() - (block.sendhour - Game.GetDay()*24)) + "/" + block.Programme.blocks, Int(Player.audience), Int(Floor(Player.audience * 1000 / Player.maxaudience)), Game.GetHour(), Game.GetMinute(), Game.GetDay(), Player.playerID)
'print "4"

Return potentialAudienceThisHour










	End Method


rem
	Method ComputeAudience2(recompute:Int = 0)
		Local block:TProgrammeBlock
		
		Local audienceAttractions:TMap = CreateMap()

		'Durchlaufe alle Spieler
		For Local player:TPlayer = EachIn TPlayer.List
			block = player.ProgrammePlan.GetCurrentProgrammeBlock()
			If block And block.programme
				'Alle Spieler buhlen um die gleichen Zuschauer
				local defintion:TGenreDefinition = GetGenreDefinition(block.programme.Genre)
				
			
				local audianceAttraction:TAudienceMultiplier = block.programme.GetBaseAudienceAttraction()
				'TODO: Image hinzufügen
				audienceAttractions.insert(player.playerID, audianceAttraction)

				
				
				Player.maxaudience
			Endif
		Next
		

			If block And block.programme And Player.maxaudience <> 0
				Player.audience = Floor(Player.maxaudience * block.Programme.getAudienceQuote(Player.audience/Player.maxaudience) / 1000)*1000
				AiLog[1].AddLog("BM-Audience : " + Player.audience + " = maxaudience (" + Player.maxaudience + ") * AudienceQuote (" + block.Programme.getAudienceQuote(Player.audience/Player.maxaudience)) + ") * 1000"
				'maybe someone sold a station
				If recompute
					Local quote:TAudienceQuotes = TAudienceQuotes.GetAudienceOfDate(Player.playerID, Game.GetDay(), Game.GetHour(), Game.GetMinute())
					If quote <> Null
						quote.audience = Player.audience
						quote.audiencepercentage = Int(Floor(Player.audience * 1000 / Player.maxaudience))
					EndIf
				Else
					TAudienceQuotes.Create(block.Programme.title + " (" + GetLocale("BLOCK") + " " + (1 + Game.GetHour() - (block.sendhour - Game.GetDay()*24)) + "/" + block.Programme.blocks, Int(Player.audience), Int(Floor(Player.audience * 1000 / Player.maxaudience)), Game.GetHour(), Game.GetMinute(), Game.GetDay(), Player.playerID)
				EndIf
				If block.sendHour - (Game.GetDay()*24) + block.Programme.blocks <= Game.getNextHour()
				
						'block.Programme.CutTopicality()
						'block.Programme.getPrice()
			
				EndIf
			EndIf
		Next
	End Method	
	
	Method ComputeAudience()
		Local block:TProgrammeBlock

		For Local Player:TPlayer = EachIn TPlayer.List
			block = Player.ProgrammePlan.GetCurrentProgrammeBlock()
			Player.audience = 0

			If block And block.programme And Player.maxaudience <> 0
				Player.audience = Floor(Player.maxaudience * block.Programme.getAudienceQuote(Player.audience/Player.maxaudience) / 1000)*1000
				AiLog[1].AddLog("BM-Audience : " + Player.audience + " = maxaudience (" + Player.maxaudience + ") * AudienceQuote (" + block.Programme.getAudienceQuote(Player.audience/Player.maxaudience)) + ") * 1000"
				'maybe someone sold a station
				If recompute
					Local quote:TAudienceQuotes = TAudienceQuotes.GetAudienceOfDate(Player.playerID, Game.GetDay(), Game.GetHour(), Game.GetMinute())
					If quote <> Null
						quote.audience = Player.audience
						quote.audiencepercentage = Int(Floor(Player.audience * 1000 / Player.maxaudience))
					EndIf
				Else
					TAudienceQuotes.Create(block.Programme.title + " (" + GetLocale("BLOCK") + " " + (1 + Game.GetHour() - (block.sendhour - Game.GetDay()*24)) + "/" + block.Programme.blocks, Int(Player.audience), Int(Floor(Player.audience * 1000 / Player.maxaudience)), Game.GetHour(), Game.GetMinute(), Game.GetDay(), Player.playerID)
				EndIf
				If block.sendHour - (Game.GetDay()*24) + block.Programme.blocks <= Game.getNextHour()
				
						'block.Programme.CutTopicality()
						'block.Programme.getPrice()
			
				EndIf
			EndIf
		Next
	End Method	
endrem	
	Method GetGenreDefinition:TGenreDefinition(genreId:int)
		Return genreDefinitions[genreId]
	End Method
	
	'===== Hilfsmethoden =====
	
	Method AddGenrePopulartity(genreId:int)
		local popularity:TGenrePopulartity = TGenrePopulartity.Create(genreId, RandRange(-10,10), RandRange(-25,25))
		GenrePopulartities[genreId] = popularity
		Game.PopularityManager.AddPopularity(popularity)
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
rem
Type TAudienceCompetition
	Field Audience:TAudienceOld
	Field AudienceAttractions:TMap = CreateMap()
	
	Function Create:TAudienceCompetition(audience:TAudienceOld)
		Local obj:TAudienceCompetition = New TAudienceCompetition
		obj.Audience = audience
		Return obj
	End Function	
	
	Method AddPlayer(playerId:int, audienceAttraction:TAudienceMultiplier)
		AudienceAttractions.insert(string(playerId), audienceAttraction)
	End Method
	
	Method ComputeAudience()
		Local sum:TAudienceMultiplier = null
						
		For Local attraction:TAudienceMultiplier = EachIn AudienceAttractions.Values()
			If sum = null Then
				sum = attraction
			Else
				sum.AudienceFactorSum(attraction)
			EndIf		
		Next
		
		'TODO!!!!!
			
	End Method
End Type
endrem


Type TGenreDefinition
	Field GenreId:int
	Field AudienceAttraction:TAudience
	Field TimeMods:float[]
	
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
		AudienceAttraction.Group_0 = string(data.ValueForKey("group_0")).ToFloat()
		AudienceAttraction.Group_1 = string(data.ValueForKey("group_1")).ToFloat()
		AudienceAttraction.Group_2 = string(data.ValueForKey("group_2")).ToFloat()
		AudienceAttraction.Group_3 = string(data.ValueForKey("group_3")).ToFloat()
		AudienceAttraction.Group_4 = string(data.ValueForKey("group_4")).ToFloat()
		AudienceAttraction.Group_5 = string(data.ValueForKey("group_5")).ToFloat()
		AudienceAttraction.Group_6 = string(data.ValueForKey("group_6")).ToFloat()
		AudienceAttraction.SubGroup_0 = string(data.ValueForKey("subgroup_1")).ToFloat()
		AudienceAttraction.SubGroup_1 = string(data.ValueForKey("subgroup_2")).ToFloat()		
		
		debugstop
	End Method
		
	Method GetProgrammeQuality:float(programme:TProgramme)
		Local quality:Float		= 0.0				
		quality =	Float(programme.Outcome) / 255.0 * OutcomeMod..
					+ Float(programme.review) / 255.0 * ReviewMod..
					+ Float(programme.speed) / 255.0 * SpeedMod..

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0,100-Max(0,game.GetYear() - programme.year))
		quality :* Max(0.10, (age/ 100.0))
		
		'repetitions wont be watched that much
		quality	:*	(programme.ComputeTopicality()/255.0)^2

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
		Local quality:float = 0
		Local result:TAudience = null
		
		
		If Game.Quotes.FEATURE_GENRE_ATTRIB_CALC = 1 'Die Gewichtung der Attribute bei der Berechnung der Filmqualität hängt vom Genre ab
			quality = GetProgrammeQuality(programme)
		Else
			quality = GetProgrammeQualityFallback(programme)
		Endif
		print "   Quality 1: " + quality
		
		
		If Game.Quotes.FEATURE_GENRE_TIME_MOD = 1 'Wie gut passt der Sendeplatz zum Genre		
			quality = quality * TimeMods[hour] 'Genre/Zeit-Mod		
		Endif
		
		
		quality = Max(0, Min(98, quality))
		print "   Quality 2: " + quality
	
		
		If Game.Quotes.FEATURE_GENRE_TARGETGROUP_MOD = 1 'Wie gut kommt das Genre bei den Zielgruppen an
			result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		Else
			result = TAudience.CreateAndInit:TAudience(quality, quality, quality, quality, quality, quality, quality, quality, quality)
		Endif
				
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
		'Local temp:float = Audience_Group_0 / 50 * quality
		'Local extraAudience = temp/15 * temp/15
		
		Local result:TAudience = new TAudience
		result.Group_0 = CalculateQuoteForGroup(quality, AudienceAttraction.Group_0)
		result.Group_1 = CalculateQuoteForGroup(quality, AudienceAttraction.Group_1)
		result.Group_2 = CalculateQuoteForGroup(quality, AudienceAttraction.Group_2)
		result.Group_3 = CalculateQuoteForGroup(quality, AudienceAttraction.Group_3)
		result.Group_4 = CalculateQuoteForGroup(quality, AudienceAttraction.Group_4)
		result.Group_5 = CalculateQuoteForGroup(quality, AudienceAttraction.Group_5)
		result.Group_6 = CalculateQuoteForGroup(quality, AudienceAttraction.Group_6)
		result.SubGroup_0 = CalculateQuoteForGroup(quality, AudienceAttraction.SubGroup_0)
		result.SubGroup_1 = CalculateQuoteForGroup(quality, AudienceAttraction.SubGroup_1)
		Return result
	End Method
	
	Method CalculateQuoteForGroup:Float(quality:float, targetGroupAttendance:float)
		Local result:float = 0
		
		If (quality <= targetGroupAttendance)
			result = quality + (targetGroupAttendance - quality) * quality
		Else
			result = targetGroupAttendance + (quality - targetGroupAttendance) / 5
		EndIf
		print "     Gr: " + result + " (quality: " + quality + " / targetGroupAttendance: " + targetGroupAttendance + ")"
		
		Return result
	End Method
End Type


Type TAudience
	Field Group_0:float 'Kinder 
	Field Group_1:float 'Teenagers
	Field Group_2:float 'Hausfrauen 
	Field Group_3:float 'Employees
	Field Group_4:float 'Unemployed
	Field Group_5:float 'Manager
	Field Group_6:float 'Rentner

	Field SubGroup_0:float 'Women
	Field SubGroup_1:float 'Men
	
	Function CreateWithBreakdown:TAudience(audience:int)
		Local obj:TAudience = New TAudience
		obj.Group_0 = audience * 0.1 'Kinder (10%)
		obj.Group_1 = audience * 0.1 'Teenager (10%)
		'Erwachsene 60%
		obj.Group_2 = audience * 0.12 'Hausfrauen (20% von 60% Erwachsenen = 12%)
		obj.Group_3 = audience * 0.405 'Arbeitnehmer (67,5% von 60% Erwachsenen = 40,5%)
		obj.Group_4 = audience * 0.045 'Arbeitslose (7,5% von 60% Erwachsenen = 4,5%)
		obj.Group_5 = audience * 0.03 'Manager (5% von 60% Erwachsenen = 3%)
		obj.Group_6 = audience * 0.2 'Rentner (20%)
		obj.SubGroup_0 = obj.Group_0 * 0.5 + obj.Group_1 * 0.5 + obj.Group_2 * 0.9 + obj.Group_3 * 0.4 + obj.Group_4 * 0.4 + obj.Group_5 * 0.25 + obj.Group_6 * 0.55		
		obj.SubGroup_1 = obj.Group_0 * 0.5 + obj.Group_1 * 0.5 + obj.Group_2 * 0.1 + obj.Group_3 * 0.6 + obj.Group_4 * 0.6 + obj.Group_5 * 0.75 + obj.Group_6 * 0.45
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
		audience.SetValues(Group_0, Group_1, Group_2, Group_3, Group_4, Group_5, Group_6, SubGroup_0, SubGroup_1)		
		Return audience
	End Method	
	
	Method SetValues(group0:float, group1:float, group2:float, group3:float, group4:float, group5:float, group6:float, subgroup0:float, subgroup1:float)
		Group_0 = group0
		Group_1 = group1
		Group_2 = group2
		Group_3 = group3
		Group_4 = group4
		Group_5 = group5
		Group_6 = group6
		SubGroup_0 = subgroup0
		SubGroup_1 = subgroup1
	End Method
	
	Method GetSum:int()
		Return Group_0 + Group_1 + Group_2 + Group_3 + Group_4 + Group_5 + Group_6
	End Method
	
	Method Multiply(audienceMultiplier:TAudience, dividorBase:float=1)
		Group_0 :* audienceMultiplier.Group_0 / dividorBase
		Group_1 :* audienceMultiplier.Group_1 / dividorBase
		Group_2 :* audienceMultiplier.Group_2 / dividorBase
		Group_3 :* audienceMultiplier.Group_3 / dividorBase
		Group_4 :* audienceMultiplier.Group_4 / dividorBase
		Group_5 :* audienceMultiplier.Group_5 / dividorBase
		Group_6 :* audienceMultiplier.Group_6 / dividorBase
		SubGroup_0 :* audienceMultiplier.SubGroup_0 / dividorBase
		SubGroup_1 :* audienceMultiplier.SubGroup_1 / dividorBase
	End Method
	
	Method MultiplyFactor(factor:float)
		Group_0 :* factor
		Group_1 :* factor
		Group_2 :* factor
		Group_3 :* factor
		Group_4 :* factor
		Group_5 :* factor
		Group_6 :* factor
		SubGroup_0 :* factor
		SubGroup_1 :* factor
	End Method	
	
	Method ToString:string()
		Return "Sum: " + GetSum() + "  ( 0: " + Group_0 + "  - 1: " + Group_1 + "  - 2: " + Group_2 + "  - 3: " + Group_3 + "  - 4: " + Group_4 + "  - 5: " + Group_5 + "  - 6: " + Group_6 + ")"
	End Method
End Type