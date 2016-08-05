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
	Field initialized:int = False

	'Referenzen
	Field newsGenreDefinitions:TNewsGenreDefinition[]		'TODO: Gehört woanders hin

	Field audienceResults:TAudienceResult[]

	'the current broadcast of each player, split by type
	Field currentAdvertisementBroadcastMaterial:TBroadcastMaterial[]
	Field currentProgrammeBroadcastMaterial:TBroadcastMaterial[]
	Field currentNewsShowBroadcastMaterial:TBroadcastMaterial[]

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


	Method GetCurrentProgrammeBroadcastMaterial:TBroadcastMaterial(playerID:int)
		if playerID <= 0 or playerID > currentProgrammeBroadcastMaterial.length then return Null

		return currentProgrammeBroadcastMaterial[playerID-1]
	End Method


	Method SetCurrentProgrammeBroadcastMaterial:int(playerID:int, material:TBroadcastMaterial)
		if playerID <= 0 then return False

		if playerID > currentProgrammeBroadcastMaterial.length then currentProgrammeBroadcastMaterial = currentProgrammeBroadcastMaterial[..playerID]
		currentProgrammeBroadcastMaterial[playerID-1] = material
		return True
	End Method	


	Method GetCurrentNewsShowBroadcastMaterial:TBroadcastMaterial(playerID:int)
		if playerID <= 0 or playerID > currentNewsShowBroadcastMaterial.length then return Null

		return currentNewsShowBroadcastMaterial[playerID-1]
	End Method


	Method SetCurrentNewsShowBroadcastMaterial:int(playerID:int, material:TBroadcastMaterial)
		if playerID <= 0 then return False

		if playerID > currentNewsShowBroadcastMaterial.length then currentNewsShowBroadcastMaterial = currentNewsShowBroadcastMaterial[..playerID]
		currentNewsShowBroadcastMaterial[playerID-1] = material
		return True
	End Method	


	Method GetCurrentAdvertisementBroadcastMaterial:TBroadcastMaterial(playerID:int)
		if playerID <= 0 or playerID > currentAdvertisementBroadcastMaterial.length then return Null

		return currentAdvertisementBroadcastMaterial[playerID-1]
	End Method


	Method SetCurrentAdvertisementBroadcastMaterial:int(playerID:int, material:TBroadcastMaterial)
		if playerID <= 0 then return False

		if playerID > currentAdvertisementBroadcastMaterial.length then currentAdvertisementBroadcastMaterial = currentAdvertisementBroadcastMaterial[..playerID]
		currentAdvertisementBroadcastMaterial[playerID-1] = material
		return True
	End Method	


	Method GetCurrentBroadcastMaterial:TBroadcastMaterial[](broadcastedAsType:int)
		Select broadcastedAsType
			case TVTBroadcastMaterialType.NEWSSHOW
				return currentNewsShowBroadcastMaterial
			case TVTBroadcastMaterialType.ADVERTISEMENT
				return currentAdvertisementBroadcastMaterial
			default
				return currentProgrammeBroadcastMaterial
		End Select
	End Method


	Method SetCurrentBroadcastMaterial:int(playerID:int, material:TBroadcastMaterial, broadcastedAsType:int)
		if playerID <= 0 then return False

		Select broadcastedAsType
			case TVTBroadcastMaterialType.NEWSSHOW
				return SetCurrentNewsShowBroadcastMaterial(playerID, material)
			case TVTBroadcastMaterialType.ADVERTISEMENT
				return SetCurrentAdvertisementBroadcastMaterial(playerID, material)
			default
				return SetCurrentProgrammeBroadcastMaterial(playerID, material)
		End Select

		return True
	End Method	

	'===== Manipulationen =====

	'sets the current broadcast as malfunction
	Method SetBroadcastMalfunction:int(playerID:int, broadcastType:int = -1)
		'adjust what is broadcasted now
		'to do this we need to know what kind of broadcast this was
		if broadcastType = -1 then broadcastType = TVTBroadcastMaterialType.PROGRAMME
		SetCurrentBroadcastMaterial(playerID, null, broadcastType)

		GetCurrentBroadcast().PlayersBroadcasts = GetCurrentBroadcastMaterial(broadcastType)
		'recalculate the players audience
		ReComputePlayerAudience(playerID)

		'inform audienceresult that this is a outage
		local result:TAudienceResult = GetCurrentBroadcast().GetAudienceResult(playerID)
		if result
			result.broadcastOutage = True
			GetCurrentBroadcast().SetAudienceResult(playerID, result)
		endif
	End Method	


	'recalculates the audience of the given player
	'other players DO NOT get adjusted (audience is "lost", not transferred) 
	Method ReComputePlayerAudience:int(playerID:int)
		GetCurrentBroadcast().ReComputeAudienceOnlyForPlayer(playerID, Sequence.GetBeforeProgrammeBroadcast(), Sequence.GetBeforeNewsShowBroadcast())
		SetAudienceResult(playerID, GetCurrentBroadcast().GetAudienceResult(playerID))
	End Method


	'===== Hilfsmethoden =====

	Method GetAudienceResult:TAudienceResult(playerID:int)
		if playerID <= 0 or playerID > audienceResults.length then return Null
		return audienceResults[playerID-1]
	End Method


	Method SetAudienceResult:int(playerID:int, audienceResult:TAudienceResult)
		if playerID <= 0 then return False

		if playerID > audienceResults.length then audienceResults = audienceResults[..playerID]

		If audienceResult.AudienceAttraction
			audienceResult.AudienceAttraction.SetPlayerId(playerID)
		EndIf

		audienceResult.playerId = playerID

		audienceResults[playerID-1] = audienceResult
	End Method


	'Der Ablauf des Broadcasts, verallgemeinert für Programme und News.
	Method BroadcastCommon:TBroadcast(day:int, hour:Int, broadcastType:Int, recompute:Int, bc:TBroadcast = null )
		If bc = Null Then bc = New TBroadcast
		bc.BroadcastType = broadcastType

		if day < 0 then day = GetWorldTime().GetDay()
		bc.Time = GetWorldTime().MakeTime(0, day, hour, 0, 0)

		Sequence.SetCurrentBroadcast(bc)

		'setup markets to compete for
		'only do this, if not done already or if enforced to do so
		'(this allows unittesting without StationMap)
		if recompute or bc.AudienceMarkets.Count() = 0
			bc.AscertainPlayerMarkets()
		endif
		
		'Die Programmwahl der Spieler "einloggen"
		if broadcastType = TVTBroadcastMaterialType.NEWSSHOW
			bc.PlayersBroadcasts = currentNewsShowBroadcastMaterial
		else
			bc.PlayersBroadcasts = currentProgrammeBroadcastMaterial
		endif
		'even if currentBroadcastMaterialdd is empty - fill
		'playersBroadcasts to a length of 4
		'-> access to playersBroadcast[0-3] is valid
		bc.PlayersBroadcasts = bc.PlayersBroadcasts[..4]

		'compute the audience for the given broadcasts
		bc.ComputeAudience(Sequence.GetBeforeProgrammeBroadcast(), Sequence.GetBeforeNewsShowBroadcast())

		For local playerID:int = 1 to 4
			Local audienceResult:TAudienceResult = bc.GetAudienceResult(playerID)
			'add to current set of results
			SetAudienceResult(playerID, audienceResult)

			If audienceResult.AudienceAttraction			
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
		If (bc.GetTopAudience() > 1000) 'Nur etwas ändern, wenn auch ein paar Zuschauer einschalten und nicht alle Sendeausfall haben.
			Local modification:TAudience = TBroadcast.GetPotentialAudienceModifier(bc.time)

			'If (broadcastType = 0) Then 'Movies
				Local map:TMap = CreateMap()

				Local attrList:TList = CreateList()
				For Local i:Int = 1 To 4 'TODO: Was passiert wenn ein Spieler ausscheidet?
					map.Insert(string.FromInt(i), new TAudience.InitValue(0, 0))
					If bc.GetAudienceResult(i).AudienceAttraction Then
						attrList.AddLast(bc.GetAudienceResult(i).AudienceAttraction.PublicImageAttraction)
					EndIf
				Next

				TPublicImage.ChangeForTargetGroup(map, TVTTargetGroup.CHILDREN, attrList, TAudience.ChildrenSort)
				TPublicImage.ChangeForTargetGroup(map, TVTTargetGroup.TEENAGERS, attrList, TAudience.TeenagersSort)
				TPublicImage.ChangeForTargetGroup(map, TVTTargetGroup.HOUSEWIVES, attrList, TAudience.HouseWivesSort)
				TPublicImage.ChangeForTargetGroup(map, TVTTargetGroup.EMPLOYEES, attrList, TAudience.EmployeesSort)
				TPublicImage.ChangeForTargetGroup(map, TVTTargetGroup.UNEMPLOYED, attrList, TAudience.UnemployedSort)
				TPublicImage.ChangeForTargetGroup(map, TVTTargetGroup.MANAGER, attrList, TAudience.ManagerSort)
				TPublicImage.ChangeForTargetGroup(map, TVTTargetGroup.PENSIONERS, attrList, TAudience.PensionersSort)

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
	Method ComputeAudience( lastMovieBroadcast:TBroadcast,lastNewsShowBroadcast:TBroadcast )
		AudienceResults[0] = New TAudienceResult
		AudienceResults[1] = New TAudienceResult
		AudienceResults[2] = New TAudienceResult
		AudienceResults[3] = New TAudienceResult

		ComputeAndSetPlayersProgrammeAttraction(lastMovieBroadcast, lastNewsShowBroadcast)

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

		ComputeAndSetPlayersProgrammeAttractionForPlayer(playerId, lastMovieBroadcast, lastNewsShowBroadcast)

		'Ronny: when a player gets a manually set malfunction, the
		'       audience attraction is missing - and then bugging out
		'       a lot of things
		'store attaction id audience result (eg. on outages)
		local ad:TAudienceResult = GetAudienceResult(playerId)
		if not ad.audienceAttraction then ad.audienceAttraction = Attractions[playerId - 1]	

		For Local market:TAudienceMarketCalculation = EachIn AudienceMarkets
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


	Method GetTopAudience:int()
		if _TopAudience < 0 then FindTopValues()
		return _TopAudience
	End Method


	Method GetTopAudienceRate:Float()
		if _TopAudienceRate < 0 then FindTopValues()
		return _TopAudienceRate
	End Method


	Method GetTopAttraction:Float()
		if _TopAttraction < 0 then FindTopValues()
		return _TopAttraction
	End Method


	Method GetTopQuality:Float()
		if _TopQuality < 0 then FindTopValues()
		return _TopQuality
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
			GetAudienceResult(playerId).broadcastMaterial = broadcastedMaterial
			'3. Qualität meines Programmes
			Attractions[playerId-1] = broadcastedMaterial.GetAudienceAttraction(GetWorldTime().GetDayHour(), broadcastedMaterial.currentBlockBroadcasting, lastMovieAttraction, lastNewsShowAttraction, True, true)
		Else 'dann Sendeausfall! TODO: Chef muss böse werden!
			TLogger.Log("TBroadcast.ComputeAndSetPlayersProgrammeAttraction()", "Player '" + playerId + "': Malfunction!", LOG_DEBUG)
			'outage
			GetAudienceResult(playerId).Title = "Malfunction!"
			GetAudienceResult(playerId).broadcastOutage = True
			Attractions[playerId - 1] = CalculateMalfunction(lastMovieAttraction)
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
	End Method


	Method AddMarket(playerIDs:Int[])
		'create array of players not existing in "playerIDs"
		Local withoutPlayerIDs:Int[]
		For Local i:Int = 1 To 4
			If MathHelper.InIntArray(i, playerIDs) then continue
			withoutPlayerIDs :+ [i]
		Next

		Local audience:Int = GetStationMapCollection().GetShareAudience(playerIDs, withoutPlayerIDs)
		If audience > 0
			Local market:TAudienceMarketCalculation = New TAudienceMarketCalculation
			market.maxAudience = new TAudience.InitWithBreakdown(audience)
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


	'returns how many percent of the target group are possibly watching
	'TV at the given hour 
	Function GetPotentialAudiencePercentage_TimeMod:TAudience(time:Double = -1)
		If time < 0 Then time = GetWorldTime().GetTimeGone()

		local result:TAudience

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
			Case 0  result = new TAudience.Init(-1,   2,   6,  16,  11,  21,  19,  23)
			Case 1  result = new TAudience.Init(-1, 0.5,   4,   7,   7,  15,   9,  13)
			Case 2  result = new TAudience.Init(-1, 0.2,   1,   4,   4,  10,   3,   8)
			Case 3  result = new TAudience.Init(-1, 0.1,   1,   3,   3,   7,   2,   5)
			Case 4  result = new TAudience.Init(-1, 0.1, 0.5,   2,   3,   4,   1,   3)
			Case 5  result = new TAudience.Init(-1, 0.2,   1,   2,   4,   3,   3,   3)
			Case 6  result = new TAudience.Init(-1,   1,   2,   3,   6,   3,   5,   4)
			Case 7  result = new TAudience.Init(-1,   4,   7,   6,   8,   4,   8,   5)
			Case 8  result = new TAudience.Init(-1,   5,   2,   8,   5,   7,  11,   8)
			Case 9  result = new TAudience.Init(-1,   6,   2,   9,   3,  12,   7,  10)
			Case 10 result = new TAudience.Init(-1,   5,   2,   9,   3,  14,   3,  11)
			Case 11 result = new TAudience.Init(-1,   5,   3,   9,   4,  15,   4,  12)
			Case 12 result = new TAudience.Init(-1,   7,   9,  11,   8,  15,   8,  13)
			Case 13 result = new TAudience.Init(-1,   8,  12,  14,   7,  24,   6,  19)
			Case 14 result = new TAudience.Init(-1,  10,  13,  15,   6,  31,   2,  21)
			Case 15 result = new TAudience.Init(-1,  11,  14,  16,   6,  29,   2,  22)
			Case 16 result = new TAudience.Init(-1,  11,  15,  21,   6,  35,   2,  24)
			Case 17 result = new TAudience.Init(-1,  12,  16,  22,  11,  36,   3,  25)
			Case 18 result = new TAudience.Init(-1,  16,  21,  24,  18,  39,   5,  34)
			Case 19 result = new TAudience.Init(-1,  24,  33,  28,  28,  46,  12,  49)
			Case 20 result = new TAudience.Init(-1,  16,  36,  33,  37,  56,  23,  60)
			Case 21 result = new TAudience.Init(-1,  11,  32,  31,  36,  53,  25,  62)
			Case 22 result = new TAudience.Init(-1,   5,  23,  30,  30,  46,  35,  49)
			Case 23 result = new TAudience.Init(-1,   3,  14,  24,  20,  34,  33,  35)
		EndSelect

		'convert to 0-1.0 percentage
		return result.multiplyFloat(0.01)
	End Function

rem
	'returns how many percent of the people watch TV depending on the
	'world weather (rain = better audience)
	Function GetPotentialAudiencePercentage_WeatherMod:TAudience(time:Double = -1)
		If time < 0 Then time = GetWorldTime().GetTimeGone()

		local result:TAudience

		'create a result value describing how big the influence of the
		'weather is.
		'  0 =   0% influence (no modification)
		'100 = 100% influence (sun = no watcher, rain = 100% watcher)
		Select GetWorldTime().GetDayHour(time)
			'during night times, people do not do things outside
			Case 0,1,2,3,4,5,6,7
				result = new TAudience.InitValue(0, 0)
			Case 8   result = new TAudience.InitValue( 5,  5)
			Case 9   result = new TAudience.InitValue(10, 10)
			Case 10  result = new TAudience.InitValue(12, 12)
			Case 11  result = new TAudience.InitValue(13, 13)
			Case 12  result = new TAudience.InitValue(14, 14)
			'midday and afternoon people love doing things outside
			Case 13,14,15,16,17
			  result = new TAudience.InitValue(15, 15)
			Case 18  result = new TAudience.InitValue(14, 14)
			Case 19  result = new TAudience.InitValue(13, 13)
			Case 20  result = new TAudience.InitValue(12, 12)
			Case 21  result = new TAudience.InitValue(11, 11)
			Case 22  result = new TAudience.InitValue(10, 10)
			Case 23  result = new TAudience.InitValue( 5,  5)
		EndSelect

		'fetch the current weather
		GetWorldWeather()

		'convert to 0-1.0 percentage
		return result.multiplyFloat(0.01)
	End Function
endrem	

	Function GetPotentialAudienceModifier:TAudience(time:Double = -1)
		local modifier:TAudience = new TAudience.InitValue(1, 1)

		'modify according to current hour
		modifier.Multiply( GetPotentialAudiencePercentage_TimeMod(time) )

		'modify according to weather 
		'modifier.Multiply( GetPotentialAudiencePercentage_WeatherMod(time) )

		return modifier
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


	Method CalculateAudienceInterestForAllowed(attr:TAudienceAttraction, maxAudience:TAudience, plausibility:TAudience, minAttraction:Float)
		'plausibility: Wer schaut wahrscheinlich zu:
		'0 = auf keinen Fall
		'1 = möglich, aber nicht wahrscheinlich
		'2 = wahrscheinlich
		Local averageAttraction:Float = attr.GetTotalAverage()

		Local allowedTemp:TAudience = plausibility
		Local sortMap:TNumberSortMap = attr.ToNumberSortMap()
		sortMap.Sort(False)
		Local highestKVAllowedAdults:TKeyValueNumber = GetFirstAllowed(sortMap, new TAudience.Init(-1,  0, 1, 1, 1, 1, 1, 1))

		If highestKVAllowedAdults.Value >= 0.9 And attr.Quality > 0.8 Then 'Top-Programm
			allowedTemp = new TAudience.InitValue(1, 1)
			allowedTemp.SetTotalValue(TVTTargetGroup.Children, plausibility.GetTotalValue(TVTTargetGroup.Children))
		EndIf

		Local highestKVAllowed:TKeyValueNumber = GetFirstAllowed(sortMap, allowedTemp)

		If (averageAttraction > minAttraction) Then
			Local attrPerMember:Float = 0.9 / allowedTemp.GetTotalSum()
			Local familyMemberCount:Int = Int((averageAttraction - (averageAttraction Mod attrPerMember)) / attrPerMember)

			For local kv:TKeyValueNumber = eachin sortMap.Content
				If allowedTemp.GetTotalValue(TVTTargetGroup.Children) >= 1 And kv.Key = "0" Then
					AudienceInterest.SetTotalValue(TVTTargetGroup.Children, AttractionToInterest(attr.GetTotalValue(TVTTargetGroup.Children), maxAudience.GetTotalValue(TVTTargetGroup.Children), int(allowedTemp.GetTotalValue(TVTTargetGroup.Children) - 1)))
					If AudienceInterest.GetTotalValue(TVTTargetGroup.Children) > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.GetTotalValue(TVTTargetGroup.Teenagers) >= 1 And kv.Key = "1" Then
					AudienceInterest.SetTotalValue(TVTTargetGroup.Teenagers, AttractionToInterest(attr.GetTotalValue(TVTTargetGroup.Teenagers), maxAudience.GetTotalValue(TVTTargetGroup.Teenagers), int(allowedTemp.GetTotalValue(TVTTargetGroup.Teenagers) - 1)))
					If AudienceInterest.GetTotalValue(TVTTargetGroup.Teenagers) > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.GetTotalValue(TVTTargetGroup.HouseWives) >= 1 And kv.Key = "2" Then
					AudienceInterest.SetTotalValue(TVTTargetGroup.HouseWives, AttractionToInterest(attr.GetTotalValue(TVTTargetGroup.HouseWives), maxAudience.GetTotalValue(TVTTargetGroup.HouseWives), int(allowedTemp.GetTotalValue(TVTTargetGroup.HouseWives) - 1)))
					If AudienceInterest.GetTotalValue(TVTTargetGroup.HouseWives) > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.GetTotalValue(TVTTargetGroup.Employees) >= 1 And kv.Key = "3" Then
					AudienceInterest.SetTotalValue(TVTTargetGroup.Employees, AttractionToInterest(attr.GetTotalValue(TVTTargetGroup.Employees), maxAudience.GetTotalValue(TVTTargetGroup.Employees), int(allowedTemp.GetTotalValue(TVTTargetGroup.Employees) - 1)))
					If AudienceInterest.GetTotalValue(TVTTargetGroup.Employees) > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.GetTotalValue(TVTTargetGroup.Unemployed) >= 1 And kv.Key = "4" Then
					AudienceInterest.SetTotalValue(TVTTargetGroup.Unemployed, AttractionToInterest(attr.GetTotalValue(TVTTargetGroup.Unemployed), maxAudience.GetTotalValue(TVTTargetGroup.Unemployed), int(allowedTemp.GetTotalValue(TVTTargetGroup.Unemployed) - 1)))
					If AudienceInterest.GetTotalValue(TVTTargetGroup.Unemployed) > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.GetTotalValue(TVTTargetGroup.Manager) >= 1 And kv.Key = "5" Then
					AudienceInterest.SetTotalValue(TVTTargetGroup.Manager, AttractionToInterest(attr.GetTotalValue(TVTTargetGroup.Manager), maxAudience.GetTotalValue(TVTTargetGroup.Manager), int(allowedTemp.GetTotalValue(TVTTargetGroup.Manager) - 1)))
					If AudienceInterest.GetTotalValue(TVTTargetGroup.Manager) > 0 Then familyMemberCount :- 1
				ElseIf allowedTemp.GetTotalValue(TVTTargetGroup.Pensioners) >= 1 And kv.Key = "6" Then
					AudienceInterest.SetTotalValue(TVTTargetGroup.Pensioners, AttractionToInterest(attr.GetTotalValue(TVTTargetGroup.Pensioners), maxAudience.GetTotalValue(TVTTargetGroup.Pensioners), int(allowedTemp.GetTotalValue(TVTTargetGroup.Pensioners) - 1)))
					If AudienceInterest.GetTotalValue(TVTTargetGroup.Pensioners) > 0 Then familyMemberCount :- 1
				EndIf

				If familyMemberCount = 0 Then Return
			Next
		Else
			If highestKVAllowed.Value >= (minAttraction * 2) Then
				'-1 = set for both
				AudienceInterest.SetTotalValue(highestKVAllowed.Key.ToInt(), 1)
			EndIf
		EndIf
	End Method


	Method CalculateAudienceInterest(bc:TBroadcast, attr:TAudienceAttraction)
		Local maxAudienceMod:TAudience = TBroadcast.GetPotentialAudienceModifier(bc.Time)

		AudienceInterest = New TAudience

		local hour:int = GetWorldTime().GetDayHour(bc.time)

		If (hour >= 0 And hour <= 1)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, new TAudience.Init(-1,  0, 1, 2, 1, 2, 1, 2), 0.10)
		Elseif (hour >= 2 And hour <= 5)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, new TAudience.Init(-1,  0, 0, 1, 0, 2, 0, 2), 0.225)
		Elseif (hour = 6)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, new TAudience.Init(-1,  1, 1, 1, 1, 0, 1, 1), 0.20)
		Elseif (hour >= 7 And hour <= 8)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, new TAudience.Init(-1,  1, 1, 1, 1, 0, 1, 1), 0.125)
		Elseif (hour >= 9 And hour <= 11)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, new TAudience.Init(-1,  0, 0, 2, 0, 1, 0, 2), 0.125)
		ElseIf (hour >= 13 And hour <= 16)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, new TAudience.Init(-1,  2, 2, 2, 0, 2, 0, 2), 0.05)
		ElseIf (hour >= 22 And hour <= 23)
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, new TAudience.Init(-1,  0, 1, 2, 2, 2, 2, 2), 0.05)
		Else
			CalculateAudienceInterestForAllowed(attr, maxAudienceMod, new TAudience.Init(-1,  1, 2, 2, 2, 2, 1, 2), 0.05)
		EndIf
	End Method
	

	Method GetFirstAllowed:TKeyValueNumber(sortMap:TNumberSortMap, allowed:TAudience)
		For local kv:TKeyValueNumber = eachin sortMap.Content
			if allowed.GetTotalValue(TVTTargetGroup.Children) >= 1 And kv.Key = "0" Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Teenagers) >= 1 And kv.Key = TVTTargetGroup.Children Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.HouseWives) >= 1 And kv.Key = TVTTargetGroup.Teenagers Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Employees) >= 1 And kv.Key = TVTTargetGroup.HouseWives Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Unemployed) >= 1 And kv.Key = TVTTargetGroup.Employees Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Manager) >= 1 And kv.Key = TVTTargetGroup.Unemployed Then Return kv
			If allowed.GetTotalValue(TVTTargetGroup.Pensioners) >= 1 And kv.Key = TVTTargetGroup.Manager Then Return kv
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
		return "TAudienceMarketCalculation: players=["+result.trim()+"], population: m="+maxAudience.GetGenderSum(TVTPersonGender.MALE)+" w="+maxAudience.GetGenderSum(TVTPersonGender.FEMALE)
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


	Method ComputeAudience(time:Double = -1)
		If time <= 0 Then time = GetWorldTime().GetTimeGone()

		CalculatePotentialChannelSurfer(time)

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
				AudienceResults[currKeyInt-1].Time = Time

				AudienceResults[currKeyInt-1].WholeMarket = MaxAudience
				AudienceResults[currKeyInt-1].PotentialMaxAudience = ChannelSurferToShare 'die 100% der Quote
				AudienceResults[currKeyInt-1].Audience = channelSurfer 'Die tatsächliche Zuschauerzahl

				'Keine ChannelSurferSum, dafür
				AudienceResults[currKeyInt-1].ChannelSurferToShare = ChannelSurferToShare
				AudienceResults[currKeyInt-1].AudienceAttraction = TAudienceAttraction(MapValueForKey(AudienceAttractions, currKey))
				AudienceResults[currKeyInt-1].EffectiveAudienceAttraction	= effectiveAttraction

				'Print "Attraction für " + currKey + ": " + attraction.ToString()
				'Print "ReduceFactor für " + currKey + ": " + GetReduceFactor().ToString()
				'Print "Effektive Quote für " + currKey + ": " + effectiveAttraction.ToString()
				'Print "Zuschauer fuer " + currKey + ": " + AudienceResults[currKeyInt-1].ToString()
			Next
		End If
	End Method


	Method CalculatePotentialChannelSurfer(time:Double)
		MaxAudience.Round()

		'Die Anzahl der potentiellen/üblichen Zuschauer um diese Zeit
		PotentialChannelSurfer = MaxAudience.Copy()
		PotentialChannelSurfer.Multiply(TBroadcast.GetPotentialAudienceModifier(time))

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
				For local i:int = 1 to TVTTargetGroup.baseGroupCount
					local groupKey:int = TVTTargetGroup.GetAtIndex(i)
					For local genderIndex:int = 0 to 1
						local gender:int = TVTPersonGender.FEMALE
						if genderIndex = 1 then gender = TVTPersonGender.MALE

						local rangeValue:Float = attrRange.GetGenderValue(groupKey, gender)
						attrRange.SetGenderValue(groupKey, rangeValue + (1 - rangeValue) * attraction.GetGenderValue(groupKey, gender), gender)
					Next
				Next
			EndIf
		Next

		Local result:TAudience

		If attrSum Then
			result = attrRange.Copy()

			For local genderIndex:int = 0 to 1
				local gender:int = TVTPersonGender.FEMALE
				if genderIndex = 1 then gender = TVTPersonGender.MALE

				If result.GetGenderSum(gender) > 0 And attrSum.getGenderSum(gender) > 0
					'attention: attrSum could contain "0" values (div/0 !)
					'so a blind "result.Divide(attrSum)" is no solution!
					'-> check all values for 0 and handle them!

					For local i:int = 1 to TVTTargetGroup.baseGroupCount
						local groupKey:int = TVTTargetGroup.GetAtIndex(i)

						'one of the targetgroups is not attracted at all
						'-> reduce to 0 (just set the same value so
						'   result/attr = 1.0 )
						if attrSum.GetGenderValue(groupKey, gender) = 0
							if result.GetGenderValue(groupKey, gender) <> 0
								attrSum.SetGenderValue( groupKey, result.GetGenderValue(groupKey, gender), gender)
							else
								'does not matter what value we set, it will
								'be the divisor of "0" (0/1 = 0)
								attrSum.SetGenderValue( groupKey, 1, gender )
							endif
						endif
					Next
				EndIf
			Next
			if attrSum.GetTotalSum() > 0 then result.Divide(attrSum)
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
		'iterate over copy to allow modification of the original list
		For local curr:TBroadcast = eachin sequence.Copy()
			if curr.BroadcastType = TVTBroadcastMaterialType.PROGRAMME
				if foundProgramme < amountOfEntriesToKeep
					foundProgramme :+ 1
				else
					sequence.Remove(curr)

					'also remove no longer needed "special data"
					curr.Attractions = new TAudienceAttraction[4]
					For local i:int = 0 to 3
						'keep potential - for history analysis (market share)
						'curr.AudienceResults[i].PotentialMaxAudience = null
						curr.AudienceResults[i].ChannelSurferToShare = null
						curr.AudienceResults[i].AudienceAttraction = null
						curr.AudienceResults[i].EffectiveAudienceAttraction = null
					Next
				endif
			endif
			if curr.BroadcastType = TVTBroadcastMaterialType.NEWSSHOW
				if foundNewsShow < amountOfEntriesToKeep
					foundNewsShow :+ 1
				else
					sequence.Remove(curr)

					'also remove no longer needed "special data"
					curr.Attractions = new TAudienceAttraction[4]
					For local i:int = 0 to 3
						'curr.AudienceResults[i].PotentialMaxAudience = null
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
		Return GetFirst(TVTBroadcastMaterialType.PROGRAMME, false)
	End Method

	Method GetBeforeNewsShowBroadcast:TBroadcast()
		Return GetFirst(TVTBroadcastMaterialType.NEWSSHOW, false)
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





Type TGameModifierAudience extends TGameModifier_TimeLimited
	Field audienceMod:Float = 0.5
	global className:string = "ModifierAudience"

	
	Method ToString:string()
		if timeFrame
			return className + ": "+timeFrame.timeBegin +" - " +timeFrame.timeEnd
		else
			return className + ": expired"
		endif
	End Method


	Method ModifierFunc:int(params:TData)
		local audience:TAudience = TAudience(params.Get("audience"))
		if not audience then Throw(className + " failed. Param misses 'audience'.")

		audience.MultiplyFloat(audienceMod)
		return True
	End Method
End Type



'common weather modifier (_not_ used for special weather phenomens!)
Type TGameModifierAudience_Weather extends TGameModifierAudience
	global className:string = "ModifierAudience:Weather"

	
	Method ToString:string()
		'override to use this types global
		return Super.ToString()
	End Method


	Method ModifierFunc:int(params:TData)
		local audience:TAudience = TAudience(params.Get("audience"))
		if not audience then Throw(className + " failed. Param misses 'audience'.")

'		hier das wetter holen und Effekte drauf abstellen

'		GetWorldWeather()

'		wenn regen, dann mod :+ 0.05 usw.

'		audience.MultiplyFloat(audienceMod)
		return True
	End Method
End Type


GameModifierCreator.RegisterModifier("ModifyAudience", new TGameModifierAudience)