Type TBroadcastManager
	'Referenzen
	Field genreDefinitions:TGenreDefinition[]
	Field newsGenreDefinitions:TNewsGenreDefinition[]
	
	Field programmeBroadcastHistory:TBroadcast[] = Null
	Field currentProgammeBroadcast:TBroadcast = Null
	Field currentNewsBroadcast:TBroadcast = Null
	Field currentBroadcast:TBroadcast = Null
	
	'Field maxAudiencePercentage2:Float = 0.3	{nosave}	'how many 0.0-1.0 (100%) audience is maximum reachable   'TODO: entfernen			

	'Feature-Konstanten	
	Const FEATURE_AUDIENCE_FLOW:Int = 1
	Const FEATURE_GENRE_ATTRIB_CALC:Int = 1
	Const FEATURE_GENRE_TIME_MOD:Int = 1
	Const FEATURE_GENRE_TARGETGROUP_MOD:Int = 1
	Const FEATURE_TARGETGROUP_TIME_MOD:Int = 1

	'Genre-Konstanten
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

	Function Create:TBroadcastManager()
		Local obj:TBroadcastManager = New TBroadcastManager
		Return obj
	End Function
	
	Method Initialize()
		programmeBroadcastHistory = programmeBroadcastHistory[..24]
	
		genreDefinitions = genreDefinitions[..21]
		Local genreMap:TMap = Assets.GetMap("genres")
		For Local asset:TAsset = EachIn genreMap.Values()
			Local definition:TGenreDefinition = New TGenreDefinition
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

	Method Save()
		'TODO: Überarbeiten
	End Method

	Method Load(loadfile:TStream)
		'TODO: Überarbeiten
	End Method

	'===== Öffentliche Methoden =====
	
	Method GetAudience:TAudienceResult(playerId:Int)
		Return currentBroadcast.AudienceResults[playerId]
	End Method	
		
	Method GetPotentialAudienceForHour:TAudience(maxAudience:TAudience, forHour:Int = -1)
		If forHour <= 0 Then forHour = Game.GetHour()
	
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
		
		maxAudienceReturn.Multiply(modi, 100)
		Return maxAudienceReturn
	End Method


	Method BroadcastProgramme(recompute:Int = 0)
		currentBroadcast = New TBroadcast
		currentProgammeBroadcast = currentBroadcast
		programmeBroadcastHistory[Game.GetHour()] = currentBroadcast
		
		'Aktuelle Märkte (um die konkuriert wird) festlegen
		currentBroadcast.AscertainPlayerMarkets()
		
		'Die Programmwahl der Spieler "einloggen"
		LoginPlayersProgrammes(currentBroadcast)
		
		'TODO: Hier AudienceFlow-Zeug starten!
		
		'Zuschauerzahl berechnen
		currentBroadcast.ComputeAudience()
		
		'Konsequenzen der Ausstrahlung berechnen/aktualisieren
		If Not recompute
			currentBroadcast.BroadcastConsequences()
		EndIf
	End Method
	
	Method BroadcastNews(recompute:Int = 0)
		currentBroadcast = New TBroadcast	
		currentNewsBroadcast = currentBroadcast
		
		'Aktuelle Märkte (um die konkuriert wird) festlegen
		currentBroadcast.AscertainPlayerMarkets()
		
		'Die Programmwahl der Spieler "einloggen"
		LoginPlayersNews(currentBroadcast)

		'TODO: Hier AudienceFlow-Zeug starten!
		
		'Zuschauerzahl berechnen
		currentBroadcast.ComputeAudience()
		
		'Konsequenzen der Ausstrahlung berechnen/aktualisieren
		If Not recompute
			currentBroadcast.BroadcastConsequences()
		EndIf		
	End Method
	
	'Mit dieser Methode werden die aktuellen Programme der Spieler "eingelogt" für die Berechnung und die spätere Begutachtung. 
	Method LoginPlayersProgrammes(theBroadcast:TBroadcast)
		Local block:TProgrammeBlock
		
		For Local player:TPlayer = EachIn TPlayer.List
			block = player.ProgrammePlan.GetCurrentProgrammeBlock()
			If block And block.programme
				theBroadcast.PlayersBroadcastBlocks[player.playerID] = TProgrammeBroadcastAttraction.Create(block)
			EndIf
		Next
	End Method
	
	Method LoginPlayersNews(theBroadcast:TBroadcast)
		For Local player:TPlayer = EachIn TPlayer.List
			theBroadcast.PlayersBroadcastBlocks[player.playerID] = TNewsBroadcastAttraction.Create(player)
		Next	
	End Method
	
	'Alle Daten müssen vom vorherigen Film stammen
	Rem	
	Method GetAudienceFlowQuote:TAudience(audienceQuote:TAudience, genreId:Int)
		Local audienceFlow:TAudience = audienceQuote.GetNewInstance()
		audienceFlow.MultiplyFactor(0.4) 'Faktor hängt davon ab wie gut die Genre zusammen passen
		Return audienceFlow
	End Method
	endrem

	Method GetGenreDefinition:TGenreDefinition(genreId:Int)
		Return genreDefinitions[genreId]
	End Method
	
	Method GetNewsGenreDefinition:TNewsGenreDefinition(genreId:Int)
		Return newsGenreDefinitions[genreId]
	End Method	
	
	'===== Hilfsmethoden =====

	'===== Events =====

	'===== Netzwerk-Methoden =====

	Method Network_SendRouteChange(floornumber:Int, call:Int = 0, who:Int, First:Int = False)
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method

	Method Network_ReceiveRouteChange(obj:TNetworkObject)
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method

	Method Network_SendSynchronize()
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method

	Method Network_ReceiveSynchronize(obj:TNetworkObject)
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method
End Type

Type TAudienceResult
	Field PlayerId:Int									'Die Id des Spielers zu dem das Result gehört
	Field Hour:Int										'Zu welcher Stunde gehört das Result
						
	'Field BroadcastQuality:Float						'Die Qualität der Sendung (Programm oder News)
	Field BroadcastAudienceAttraction:TAudience			'Wie Attraktiv wirkt das Programm auf die einzelnen Zielgruppen
						
	Field WholeMarket:TAudience	= New TAudience			'Der Gesamtmarkt: Also wenn alle einschalten und man 100% erreicht ;)
	Field MaxAudienceThisHour:TAudience = New TAudience	'Die Gesamtzuschauerzahl die in dieser Stunde den TV angeschaltet hat	
	Field MaxAudienceThisHourQuote:TAudience			'Wie viel Prozent schalten ein. Basis ist WholeMarket
	Field Audience:TAudience = New TAudience			'Die absolute Zahl der Zuschauer die erreicht wurden
						
	Field AudienceQuote:TAudience						'Die Zuschauerquote, relativ zu MaxAudienceThisHour	
	Field MarketShare:Float								'Die reale Zuschauerquote, die aber noch nicht verwendet wird.
	
	Function Curr:TAudienceResult(playerId:Int = -1) 'Des aktuellen Spielers zu aktuellen Zeit
		If playerId = -1 Then
			Return TPlayer.Current().audience
		Else
			Return TPlayer.getByID(playerId).audience					
		EndIf
	End Function
	
	Method AddResult(res:TAudienceResult)
		WholeMarket.Add(res.WholeMarket)
		MaxAudienceThisHour.Add(res.MaxAudienceThisHour)
		Audience.Add(res.Audience)		
	End Method
	
	Method Refresh()
		AudienceQuote = Audience.GetNewInstance()
		AudienceQuote.Divide(MaxAudienceThisHour)
		MaxAudienceThisHourQuote = MaxAudienceThisHour.GetNewInstance()
		MaxAudienceThisHourQuote.Divide(WholeMarket)
	End Method
	
	Method ToString:String()
		Return Audience.GetSum() + " / " + MaxAudienceThisHour.GetSum() + " / " + WholeMarket.GetSum() + "      Q: " + AudienceQuote.ToStringAverage() 
	End Method
End Type

'In dieser Klasse und in TAudienceMarketCalculation findet die eigentliche Quotenberechnung statt und es wird das Ergebnis gecached,
'so dass man die Calculation einige Zeit aufbewahren kann.
Type TBroadcast
	Field AudienceMarkets:TList = CreateList()
	Field PlayersBroadcastBlocks:TBroadcastAttraction[] = New TBroadcastAttraction[5] '1 bis 4. 0 Wird nicht verwendet
	
	Field AudienceResults:TAudienceResult[5]
	
	'===== Öffentliche Methoden =====
	
	'Hier werden alle Märkte in denen verschiedene Spieler miteinander konkurrieren initialisiert. Diese Methode wird nur einmal aufgerufen!
	'So legt man fest um wie viel Zuschauer sich Spieler 2 und Spieler 4 streiten oder wie viel Zuschauer Spieler 3 alleine bedient
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
	Method ComputeAudience()
		AudienceResults[1] = New TAudienceResult
		AudienceResults[2] = New TAudienceResult
		AudienceResults[3] = New TAudienceResult
		AudienceResults[4] = New TAudienceResult	
	
		ComputePlayersProgrammeAttraction()
	
		Print "=== Zuschauer aufteilen ==="
		Local hour:Int = Game.GetHour()
		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			market.ComputeAudience(hour)
			AssimilateResults(market)
		Next		
		Print "=== Zuschauer aufgeteilt ==="
		
		AudienceResults[1].Refresh()
		AudienceResults[2].Refresh()
		AudienceResults[3].Refresh()
		AudienceResults[4].Refresh()
	End Method	
	
	'Diese Methode erlaubt es das Ergebnis der Berechnung abzurufen.
	rem
	Method GetAudienceOfPlayer:TAudience(playerId:String)
		Local result:TAudience = New TAudience
		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
			If market.Players.Contains(playerId) Then
				result.Add(market.GetAudienceOfPlayer(playerId))
			EndIf
		Next
		Return result
	End Method
		endrem
	Method BroadcastConsequences()
		Local block:TBroadcastAttraction
		Local player:TPlayer	
		
		'SetMaxAudienceValue()		
		
		For Local i:Int = 1 To 4
			player = TPlayer.getByID(i)
			block = PlayersBroadcastBlocks[i]					
						
			If block
				player.audience = AudienceResults[i]
				block.CheckConsequences(player)
			EndIf
		Next
				
		'SetMaxAudienceValuePercentage()	
	End Method	
	
	'===== Hilfsmethoden =====
	
	Method AssimilateResults(market:TAudienceMarketCalculation)
		Print "AddResults1"
		For Local playerId:String = EachIn market.Players			
			Print "AddResults2: " + playerId
			Local result:TAudienceResult = market.GetAudienceResultOfPlayer(playerId.ToInt())
			If result Then AudienceResults[playerId.ToInt()].AddResult(result)
		Next	
	End Method	
	rem
	Method SetMaxAudienceValue()
		For Local i:Int = 1 To 4
			Local sum:TAudience = New TAudience			
			For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
				If market.Players.Contains(String(i)) Then
					sum.Add(market.MaxAudience)						
				EndIf
			Next		

			MaxAudienceForPlayer[i] = sum
			Print "SetMaxAudienceValue " + String(i) + ": " + sum.ToString()
		Next		
	End Method
	
	Method SetMaxAudienceValuePercentage()
		For Local i:Int = 1 To 4
			Local sum:TAudience = MaxAudienceForPlayer[i]
			
			Local percentage:TAudience = AudienceOfPlayer[i].GetNewInstance()
			percentage.Divide(sum)		

			MaxAudiencePercentageForPlayer[i] = percentage
			Print "SetMaxAudienceValuePercentage " + String(i) + ": " + percentage.ToStringAverage()
		Next		
	End Method	
	endrem
	Method ComputePlayersProgrammeAttraction()		
		Local block:TBroadcastAttraction
		For Local i:Int = 1 To 4
			block = PlayersBroadcastBlocks[i]
			If block
				'3. Qualität meines Programmes							
				Local attraction:TAudience = block.GetAudienceAttraction()

				For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
					If market.Players.Contains(String(i)) Then
						market.SetPlayersProgrammeAttraction(i, attraction)
					EndIf
				Next
			EndIf
		Next
	End Method	
	
	Method AddMarket(playerIDs:Int[])
		'Echt mega beschissener Code. Aber wie geht's mit Arrays in BlitzMax besser? Irgendwas mit Schnittmengen oder Contains?
		'Oder ein Remove eines Elements? ListFromArray geht mit Int-Arrays nicht... usw... Ich hab keinen Plan.
		'Ich brauch nur was wie array1.remove(array2)
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
End Type


'Diese Klasse repräsentiert einen Markt um den 1 bis 4 Spieler konkurieren.
'
Type TAudienceMarketCalculation
	Field MaxAudience:TAudience						'Die Einwohnerzahl (max. Zuschauer) in diesem Markt
	Field AudienceAttractions:TMap = CreateMap()	'Die Attraktivität des Programmes nach Zielgruppen. Für jeden Spieler der um diesen Markt mitkämpft gibt's einen Eintrag in der Liste
	'Field AudienceResult:TMap = CreateMap()			'Das Ergebnis der Berechnung. Pro Spieler gibt's ein Ergebnis
	Field Players:TList = CreateList()				'Die Liste der Spieler die um diesen Markt kämpfen
	
	Field AudienceResults:TAudienceResult[5]
	
	'===== Öffentliche Methoden =====
		
	Method AddPlayer(playerId:String)
		Players.AddLast(playerId)
	End Method
	
	Method SetPlayersProgrammeAttraction(playerId:String, audienceAttraction:TAudience)
		AudienceAttractions.insert(playerId, audienceAttraction)
	End Method
	
	Method GetAudienceResultOfPlayer:TAudienceResult(playerId:Int)
		Return AudienceResults[playerId]		
		'Return TAudience(MapValueForKey(AudienceResult, playerId))
	End Method
	
	Method ComputeAudience(forHour:Int = -1)	
		If forHour <= 0 Then forHour = Game.GetHour()				
				
		Local potentialAudienceThisHour:TAudience
		
		'Targetgroup-Time-Mod-Feature
		If Game.BroadcastManager.FEATURE_TARGETGROUP_TIME_MOD = 1
			potentialAudienceThisHour = Game.BroadcastManager.GetPotentialAudienceForHour(MaxAudience, forHour)
		Else
			potentialAudienceThisHour = MaxAudience.GetNewInstance()
			potentialAudienceThisHour.MultiplyFactor(0.2)
		EndIf
		
		Print "Max. erreichbare Zuschauer (Einwohner): " + MaxAudience.ToString()
		Print "TV-Interessierte zu dieser Stunde: " + potentialAudienceThisHour.ToString()
				
		Local sum:TAudience = Null
		Local range:TAudience = Null

		For Local attraction:TAudience = EachIn AudienceAttractions.Values()
			If sum = Null Then
				sum = attraction.GetNewInstance()
			Else
				sum.Add(attraction)
			EndIf
		
			If range = Null Then
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
			EndIf
		Next
		
		If sum Then				
			Print "Summe aller Werte: " + sum.ToString()
			Print "Quote der Zapper die dranbleiben (diese werden verteilt): " + range.ToString()
			
			Local reduceFactor:TAudience = Range.GetNewInstance()
			
			If reduceFactor.GetSumFloat() > 0 And sum.GetSumFloat() > 0 Then			
				reduceFactor.Divide(sum)
			EndIf
			
			For Local currKey:String = EachIn AudienceAttractions.Keys()
				Local attraction:TAudience = TAudience(MapValueForKey(AudienceAttractions, currKey))
				Local effectiveAttraction:TAudience = attraction.GetNewInstance()
				effectiveAttraction.Multiply(reduceFactor)
				
				Local playerAudienceResult:TAudience = potentialAudienceThisHour.GetNewInstance()
				playerAudienceResult.Multiply(effectiveAttraction)
				playerAudienceResult.Round()
				
				Local currKeyInt:Int = currKey.ToInt()
				'Ergebnis schreiben
				AudienceResults[currKeyInt] = New TAudienceResult
				AudienceResults[currKeyInt].PlayerId = currKeyInt		
				AudienceResults[currKeyInt].Hour = forHour	
				AudienceResults[currKeyInt].WholeMarket = MaxAudience
				AudienceResults[currKeyInt].MaxAudienceThisHour = potentialAudienceThisHour				
				AudienceResults[currKeyInt].BroadcastAudienceAttraction = effectiveAttraction
				AudienceResults[currKeyInt].Audience = playerAudienceResult				
				
				Print "Effektive Quote für " + currKey + ": " + effectiveAttraction.ToString()
				Print "Zuschauer fuer " + currKey + ": " + playerAudienceResult.ToString()
			Next
		End If
	End Method
End Type

Type TGenreDefinitionBase
	Field GenreId:Int
	Field AudienceAttraction:TAudience
	Field Popularity:TGenrePopulartity	

	Method CalculateQuotes:TAudience(quality:Float)
		'Zielgruppe / 50 * Qualität
		'Local temp:float = Audience_Children / 50 * quality
		'Local extraAudience = temp/15 * temp/15
		
		Local result:TAudience = New TAudience
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
	
	Method CalculateQuoteForGroup:Float(quality:Float, targetGroupAttendance:Float)
		Local result:Float = 0
		
		If (quality <= targetGroupAttendance)
			result = quality + (targetGroupAttendance - quality) * quality
		Else
			result = targetGroupAttendance + (quality - targetGroupAttendance) / 5
		EndIf
		'print "     Gr: " + result + " (quality: " + quality + " / targetGroupAttendance: " + targetGroupAttendance + ")"
		
		Return result
	End Method	
End Type

Type TNewsGenreDefinition Extends TGenreDefinitionBase
	Method LoadFromAssert(asset:TAsset)
		Local data:TMap = TMap(asset._object)

		GenreId = String(data.ValueForKey("id")).ToInt()
		'GenreId = String(data.ValueForKey("name"))
		
		AudienceAttraction = New TAudience
		AudienceAttraction.Children = String(data.ValueForKey("Children")).ToFloat()
		AudienceAttraction.Teenagers = String(data.ValueForKey("Teenagers")).ToFloat()
		AudienceAttraction.HouseWifes = String(data.ValueForKey("HouseWifes")).ToFloat()
		AudienceAttraction.Employees = String(data.ValueForKey("Employees")).ToFloat()
		AudienceAttraction.Unemployed = String(data.ValueForKey("Unemployed")).ToFloat()
		AudienceAttraction.Manager = String(data.ValueForKey("Manager")).ToFloat()
		AudienceAttraction.Pensioners = String(data.ValueForKey("Pensioners")).ToFloat()
		AudienceAttraction.Women = String(data.ValueForKey("Women")).ToFloat()
		AudienceAttraction.Men = String(data.ValueForKey("Men")).ToFloat()
				
		Popularity = TGenrePopulartity.Create(GenreId, RandRange(-10, 10), RandRange(-25, 25))
		Game.PopularityManager.AddPopularity(Popularity) 'Zum Manager hinzufügen		
		
		Print "Load newsgenre " + GenreId + ": " + AudienceAttraction.ToString()
		'print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod
	End Method
	
	Method GetNewsQuality:Float(news:TNews, luckFactor:Int = 1)
		Local quality:Float = 0.0
		
		quality = Float(news.ComputeTopicality()) / 255.0 * 0.45 ..
			+ Float(news.quality) / 255.0 * 0.35 ..
			+ Float(news.price) / 255.0 * 0.2
		
		'Zusätzlicher Bonus bei Erstausstrahlung	
		If news.timesAired = 0 Then quality:*0.15

		If luckFactor = 1 Then
			quality = quality * 0.97 + Float(RandRange(10, 30)) / 1000.0 '1%-Punkte bis 3%-Punkte Basis-Qualität
		Else
			quality = quality * 0.99 + 0.01 'Mindestens 1% Qualität
		EndIf
		
		'no minus quote
		Return Max(0, quality)
	End Method
	
	Method CalculateAudienceAttraction:TAudience(news:TNews, hour:Int, luckFactor:Int = 1)
		Local quality:Float = 0
		Local result:TAudience = Null
		
		quality = GetNewsQuality(news, luckFactor)
		quality = Max(0, Min(99, quality))
									
		result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		
		Print "G" + GenreId + "   News-Qualität: " + quality
		Print "G" + GenreId + "   Quali. nach Zielg.: " + result.ToStringAverage() + " (Einfluss je nach Genre)"
				
		Return result
	End Method	
End Type


Type TGenreDefinition Extends TGenreDefinitionBase
	Field TimeMods:Float[]
	
	Field OutcomeMod:Float = 0.5
	Field ReviewMod:Float = 0.3
	Field SpeedMod:Float = 0.2
	
	Method LoadFromAssert(asset:TAsset)
		Local data:TMap = TMap(asset._object)
		GenreId = String(data.ValueForKey("id")).ToInt()
		OutcomeMod = String(data.ValueForKey("outcomeMod")).ToFloat()
		ReviewMod = String(data.ValueForKey("reviewMod")).ToFloat()
		SpeedMod = String(data.ValueForKey("speedMod")).ToFloat()
		
		TimeMods = TimeMods[..24]
		For Local i:Int = 0 To 23
			TimeMods[i] = String(data.ValueForKey("timeMod_" + i)).ToFloat()
		Next

		AudienceAttraction = New TAudience
		AudienceAttraction.Children = String(data.ValueForKey("Children")).ToFloat()
		AudienceAttraction.Teenagers = String(data.ValueForKey("Teenagers")).ToFloat()
		AudienceAttraction.HouseWifes = String(data.ValueForKey("HouseWifes")).ToFloat()
		AudienceAttraction.Employees = String(data.ValueForKey("Employees")).ToFloat()
		AudienceAttraction.Unemployed = String(data.ValueForKey("Unemployed")).ToFloat()
		AudienceAttraction.Manager = String(data.ValueForKey("Manager")).ToFloat()
		AudienceAttraction.Pensioners = String(data.ValueForKey("Pensioners")).ToFloat()
		AudienceAttraction.Women = String(data.ValueForKey("Women")).ToFloat()
		AudienceAttraction.Men = String(data.ValueForKey("Men")).ToFloat()
				
		Popularity = TGenrePopulartity.Create(GenreId, RandRange(-10, 10), RandRange(-25, 25))
		Game.PopularityManager.AddPopularity(Popularity) 'Zum Manager hinzufügen		
		
		'print "Load " + GenreId + ": " + AudienceAttraction.ToString()
		'print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod 
	End Method
		
	Method GetProgrammeQuality:Float(programme:TProgramme, luckFactor:Int = 1)
		Local quality:Float = 0.0
		
		If OutcomeMod > 0.0 Then
			quality = Float(programme.Outcome) / 255.0 * OutcomeMod ..
				+ Float(programme.review) / 255.0 * ReviewMod ..
				+ Float(programme.speed) / 255.0 * SpeedMod
		Else
			quality = Float(programme.review) / 255.0 * ReviewMod ..
				+ Float(programme.speed) / 255.0 * SpeedMod´
		EndIf

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0, 100 - Max(0, game.GetYear() - programme.year))
		quality:*Max(0.10, (age / 100.0))
		
		'repetitions wont be watched that much
		quality:*(programme.ComputeTopicality() / 255.0) ^ 2

		If luckFactor = 1 Then
			quality = quality * 0.98 + Float(RandRange(10, 20)) / 1000.0 '1%-Punkte bis 2%-Punkte Basis-Qualität
		Else
			quality = quality * 0.99 + 0.01 'Mindestens 1% Qualität
		EndIf
		
		'no minus quote
		quality = Max(0, quality)
		Return quality
	End Method
	
	Method GetProgrammeQualityFallback:Float(programme:TProgramme)
		Local quality:Float = 0.0
		If programme.outcome > 0 Then
			quality = Float(programme.Outcome) / 255.0 * 0.5 ..
				+ Float(programme.review) / 255.0 * 0.3 ..
				+ Float(programme.speed) / 255.0 * 0.2
		Else 'tv shows
			quality = Float(programme.review) / 255.0 * 0.6 ..
				+ Float(programme.speed) / 255.0 * 0.4
		EndIf

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0, 100 - Max(0, game.GetYear() - programme.year))
		quality:*Max(0.10, (age / 100.0))
		
		'repetitions wont be watched that much
		quality:*(programme.ComputeTopicality() / 255.0) ^ 2

		'no minus quote
		quality = Max(0, quality)
		Return quality
	End Method
	

	Method CalculateAudienceAttraction:TAudience(programme:TProgramme, hour:Int, luckFactor:Int = 1)
		Local rawQuality:Float = 0
		Local quality:Float = 0
		Local result:TAudience = Null		
		
		If Game.BroadcastManager.FEATURE_GENRE_ATTRIB_CALC = 1 'Die Gewichtung der Attribute bei der Berechnung der Filmqualität hängt vom Genre ab
			rawQuality = GetProgrammeQuality(programme, luckFactor)
		Else
			rawQuality = GetProgrammeQualityFallback(programme)
		EndIf
		quality = rawQuality
						
		If Game.BroadcastManager.FEATURE_GENRE_TIME_MOD = 1 'Wie gut passt der Sendeplatz zum Genre		
			quality = quality * TimeMods[hour] 'Genre/Zeit-Mod		
		EndIf
		quality = Max(0, Min(98, quality))
				
		Print "G" + GenreId + "   Programm-Qualität: " + quality + " (ohne Zeit-Mod: " + rawQuality + ")"
		
		If Game.BroadcastManager.FEATURE_GENRE_TARGETGROUP_MOD = 1 'Wie gut kommt das Genre bei den Zielgruppen an
			result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		Else
			result = TAudience.CreateAndInit:TAudience(quality, quality, quality, quality, quality, quality, quality, quality, quality)
		EndIf
				
		Print "G" + GenreId + "   Quali. nach Zielg.: " + result.ToStringAverage() + " (Einfluss je nach Genre)"
				
		Return result
	End Method
	
	rem
	Method GeTAudienceMultiplierForProgramme:TAudienceMultiplier(programme:TProgramme)
	Local result:TAudience = AudienceAttraction.GetNewInstance()
	result.MultiplyFactor(GetProgrammeQuality(programme))
	Return result		
	End Method
	endrem
End Type


Type TAudience
	Field Children:Float 'Kinder 
	Field Teenagers:Float 'Teenagers
	Field HouseWifes:Float 'Hausfrauen 
	Field Employees:Float 'Employees
	Field Unemployed:Float 'Unemployed
	Field Manager:Float 'Manager
	Field Pensioners:Float 'Rentner

	Field Women:Float 'Women
	Field Men:Float 'Men
	
	Function CreateWithBreakdown:TAudience(audience:Int)
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
	
	Function CreateAndInit:TAudience(group0:Float, group1:Float, group2:Float, group3:Float, group4:Float, group5:Float, group6:Float, subgroup0:Float, subgroup1:Float)
		Local result:TAudience = New TAudience
		result.SetValues(group0, group1, group2, group3, group4, group5, group6, subgroup0, subgroup1)
		Return result
	End Function
	
	Method GetNewInstance:TAudience()
		Return CopyTo(New TAudience)
			End Method
	
	Method CopyTo:TAudience(audience:TAudience)
		audience.SetValues(Children, Teenagers, HouseWifes, Employees, Unemployed, Manager, Pensioners, Women, Men)
		Return audience
	End Method
	
	Method SetValues(group0:Float, group1:Float, group2:Float, group3:Float, group4:Float, group5:Float, group6:Float, subgroup0:Float, subgroup1:Float)
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
	
	Method GetSum:Int()
		Return Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners
	End Method
	
	Method GetSumFloat:Float()
		Return Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners
	End Method
	
	Method GetAverage:Float()
		Local result:Float =	Children * 0.1 + ..
								Teenagers * 0.1 + ..
								HouseWifes * 0.12 + ..
								Employees * 0.405 + ..								
								Unemployed * 0.045 + ..
								Manager * 0.03 + ..
								Pensioners * 0.2
		Return result		
	End Method
		
	Method Add(audience:TAudience)
		Children:+audience.Children
		Teenagers:+audience.Teenagers
		HouseWifes:+audience.HouseWifes
		Employees:+audience.Employees
		Unemployed:+audience.Unemployed
		Manager:+audience.Manager
		Pensioners:+audience.Pensioners
		Women:+audience.Women
		Men:+audience.Men
	End Method
	
	Method Multiply(audienceMultiplier:TAudience, dividorBase:Float = 1)
		Children:*audienceMultiplier.Children / dividorBase
		Teenagers:*audienceMultiplier.Teenagers / dividorBase
		HouseWifes:*audienceMultiplier.HouseWifes / dividorBase
		Employees:*audienceMultiplier.Employees / dividorBase
		Unemployed:*audienceMultiplier.Unemployed / dividorBase
		Manager:*audienceMultiplier.Manager / dividorBase
		Pensioners:*audienceMultiplier.Pensioners / dividorBase
		Women:*audienceMultiplier.Women / dividorBase
		Men:*audienceMultiplier.Men / dividorBase
	End Method
	
	Method MultiplyFactor:TAudience(factor:Float)
		Children:*factor
		Teenagers:*factor
		HouseWifes:*factor
		Employees:*factor
		Unemployed:*factor
		Manager:*factor
		Pensioners:*factor
		Women:*factor
		Men:*factor
		Return Self
	End Method
	
	Method Divide(audienceDividor:TAudience)
		Children:/audienceDividor.Children
		Teenagers:/audienceDividor.Teenagers
		HouseWifes:/audienceDividor.HouseWifes
		Employees:/audienceDividor.Employees
		Unemployed:/audienceDividor.Unemployed
		Manager:/audienceDividor.Manager
		Pensioners:/audienceDividor.Pensioners
		Women:/audienceDividor.Women
		Men:/audienceDividor.Men
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
	
	Method ToString:String()
		Return "Sum: " + Ceil(GetSum()) + "  ( 0: " + Children + "  - 1: " + Teenagers + "  - 2: " + HouseWifes + "  - 3: " + Employees + "  - 4: " + Unemployed + "  - 5: " + Manager + "  - 6: " + Pensioners + ")"
	End Method
	
	Method ToStringAverage:String()
		Return "Ave: " + GetSumFloat() / 7 + "  ( 0: " + Children + "  - 1: " + Teenagers + "  - 2: " + HouseWifes + "  - 3: " + Employees + "  - 4: " + Unemployed + "  - 5: " + Manager + "  - 6: " + Pensioners + ")"
	End Method
End Type

Type TBroadcastAttraction
	Method CheckConsequences(player:TPlayer) Abstract
	Method GetAudienceAttraction:TAudience() Abstract
End Type

Type TProgrammeBroadcastAttraction Extends TBroadcastAttraction
	Field block:TProgrammeBlock = Null

	Function Create:TProgrammeBroadcastAttraction(block:TProgrammeBlock)
		Local obj:TProgrammeBroadcastAttraction = New TProgrammeBroadcastAttraction
		obj.block = block				
		Return obj
	End Function
	
	Method CheckConsequences(player:TPlayer)
		If block.programme Then
			'TODO: Visuelle Darstellung und Historie. Später vereinheitlichen			
			TAudienceQuotes.Create(block.Programme.title + " (" + GetLocale("BLOCK") + " " + (1 + Game.GetHour() - (block.sendhour - Game.GetDay() * 24)) + "/" + block.Programme.blocks, Int(player.audience.Audience.GetSum()), Game.GetHour(), Game.GetMinute(), Game.GetDay(), player.playerID)
		
			'Wenn der letzte Teil des Programmes gesendet wurde, dann werden einige Eigenschaften aktualisiert
			If block.sendHour - (Game.GetDay() * 24) + block.Programme.blocks <= Game.getNextHour()
				'if someone can watch that movie, increase the aired amount	
				block.Programme.timesAired:+1
			
				'during nighttimes 0-5, the cut should be lower
				'so we increase the cutFactor to 1.5
				If Game.getNextHour() - 1 <= 5
					block.Programme.CutTopicality(1.5)
				ElseIf Game.getNextHour() - 1 <= 12
					block.Programme.CutTopicality(1.25)
				Else
					block.Programme.CutTopicality(1.0)
				EndIf				
			EndIf
		EndIf
	End Method
	
	Method GetAudienceAttraction:TAudience()
		Local genreDefintion:TGenreDefinition = Game.BroadcastManager.GetGenreDefinition(block.programme.Genre)
		Return genreDefintion.CalculateAudienceAttraction(block.programme, Game.GetHour())
	End Method
End Type

Type TNewsBroadcastAttraction Extends TBroadcastAttraction
	Field player:TPlayer = Null

	Function Create:TNewsBroadcastAttraction(player:TPlayer)
		Local obj:TNewsBroadcastAttraction = New TNewsBroadcastAttraction
		obj.player = player
		Return obj
	End Function
	
	Method CheckConsequences(player:TPlayer)
		Local block:TNewsBlock				
		TAudienceQuotes.Create("News: "+ Game.GetHour()+":00", Int(player.audience.Audience.GetSum()), Game.GetHour(),Game.GetMinute(),Game.GetDay(), player.playerID)		
		
		For Local i:Int = 1 To 3
			block = player.ProgrammePlan.GetNewsBlockFromSlot(i - 1)
			If block <> Null
				block.news.timesAired:+1				
			EndIf
		Next
	End Method
	
	Method GetAudienceAttraction:TAudience()
		Local genreDefintion:TNewsGenreDefinition
		Local block:TNewsBlock
		Local tempAudienceAttr:TAudience
		Local resultAudienceAttr:TAudience = New TAudience
	
		For Local i:Int = 1 To 3
			block = player.ProgrammePlan.GetNewsBlockFromSlot(i - 1)
			If block <> Null
				genreDefintion = Game.BroadcastManager.GetNewsGenreDefinition(block.news.Genre)
				tempAudienceAttr = genreDefintion.CalculateAudienceAttraction(block.news, Game.GetHour())	
			Else
				tempAudienceAttr = New TAudience				
			EndIf
			
			'different weight for news slots
			If i = 1 Then resultAudienceAttr.Add(tempAudienceAttr.MultiplyFactor(0.5))
			If i = 2 Then resultAudienceAttr.Add(tempAudienceAttr.MultiplyFactor(0.3))
			If i = 3 Then resultAudienceAttr.Add(tempAudienceAttr.MultiplyFactor(0.2))		
		Next
	
		Return resultAudienceAttr
	End Method	
End Type