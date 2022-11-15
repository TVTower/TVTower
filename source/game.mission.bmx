SuperStrict
Import "game.betty.bmx"
Import "game.gameeventkeys.bmx"
Import "game.mission.base.bmx"
Import "game.mission.highscore.bmx"
Import "game.stationmap.bmx"
Import "game.player.programmeplan.bmx"
Import "game.player.bmx"


Global AllMissions:TMissions = new TMissions()

Type TMissions
	Field missions:TMap = null {noSave}
	Field missionIDs:TList {noSave}

	Method getCategories:String[]()
		If Not missions Then _initMissions()
		Local categories:String[] = new String[0]
		For local k:string = EachIn missions.Keys()
				categories :+ [k]
			Next
		Return categories
	End Method

	Method getMissions:TMission[](category:String)
		If Not missions Then _initMissions()
		Local result:Object = missions.ValueForKey(category)
		return TMission[](result)
	End Method


	'STARTING PRIVATE METHODS
	private

	'utility method for inserting a mission into the correct category checking for duplicates
	Method _addMission(mission:TMission)
		If Not missions
			missions = CreateMap()
			missionIDs = new TList()
		EndIf
		Local list:TMission[]
		Local value:Object = missions.ValueForKey(mission.GetCategory())
		If Not value
			list = new TMission[1]
		Else
			Local currentList:TMission[] = TMission[](value)
			If currentList
				list = currentList
			Else
				DebugStop
				throw "TMissions._addMission: map value type error"
			EndIf
			list = list[..list.length+1]
		EndIf
		list[list.length-1] = mission
		Local missionId:String = mission.GetMissionId()
		If missionIDs.contains(missionId)
			throw "TMissions._addMission: duplicate mission id "+ missionId
		Else
			missionIDs.addLast(missionId)
		EndIf
		missions.insert(mission.GetCategory(), list)
	End Method

	Method _initMissions()
		If Not missions

			_addMission(TSimpleMission.createMoney(100000000))
			_addMission(TSimpleMission.createMoney(-1,20))
			_addMission(TSimpleMission.createMoney(-1,40))
			_addMission(TSimpleMission.createMoney(50000000,40))

			_addMission(TSimpleMission.createReach(80))
			_addMission(TSimpleMission.createReach(-1,20))
			_addMission(TSimpleMission.createReach(-1,40))
			_addMission(TSimpleMission.createReach(50,40))

			_addMission(TSimpleMission.createImage(95))
			_addMission(TSimpleMission.createImage(-1,20))
			_addMission(TSimpleMission.createImage(-1,40))
			_addMission(TSimpleMission.createImage(50,40))

			_addMission(TSimpleMission.createBetty(100))
			_addMission(TSimpleMission.createBetty(-1,20))
			_addMission(TSimpleMission.createBetty(-1,40))
			_addMission(TSimpleMission.createBetty(50,40))

			rem test mission for failing
			_addMission(TSimpleMission.createReach(50,1))
			_addMission(TSimpleMission.createImage(1,-1))
			endrem
		EndIf
	End Method

End Type

Type TSimpleMission extends TMission
	Field category:String
	Field targetValue:Int = -1
	Field currentPlayerFinance:TPlayerFinance {noSave}
	Field currentPlayerMap:TStationMap {noSave}
	Field currentImage:TPublicImage {noSave}
	Field currentBettyEvent:TEventBase {noSave}

	Function create:TSimpleMission(category:String, targetValue:Int=-1, days:Int=-1)
		Local result:TSimpleMission=new TSimpleMission
		result.category = category
		result.targetValue = targetValue
		result.daysForAchieving = days
		return result
	End Function

	Function createMoney:TSimpleMission(targetMoney:Int=-1, days:Int=-1)
		return create("MONEY", targetMoney, days)
	End Function

	Function createReach:TSimpleMission(targetReach:Int=-1, days:Int=-1)
		return create("REACH", targetReach, days)
	End Function

	Function createImage:TSimpleMission(targetImage:Int=-1, days:Int=-1)
		return create("IMAGE", targetImage, days)
	End Function

	Function createBetty:TSimpleMission(targetImage:Int=-1, days:Int=-1)
		return create("BETTY", targetImage*100, days)
	End Function

	Method getCheckListener:TEventListenerBase()
		If category = "MONEY" and targetValue > 0 Then Return EventManager.registerListenerMethod(GameEventKeys.PlayerFinance_OnChangeMoney, Self, "OnMoneyChange")
		If category = "REACH" and targetValue > 0 Then Return EventManager.registerListenerMethod(GameEventKeys.StationMap_OnRecalculateAudienceSum, Self, "OnReachChange")
		If category = "IMAGE" and targetValue > 0 Then Return EventManager.registerListenerMethod(GameEventKeys.PublicImage_OnChange, Self, "OnImageChange")
		If category = "BETTY" and targetValue > 0 Then Return EventManager.registerListenerMethod(GameEventKeys.Betty_OnAdjustLove, Self, "OnBettyChange")
	EndMethod

	Method getCategory:String()
		return category
	End Method

	Method getIdSuffix:String() override
		Local mapName:String = GetStationMapCollection().GetMapName()
		Local suffix:String = mapName
		If targetValue > 0 Then suffix:+("_"+targetValue)
		Return suffix
	End Method

	Method formatValue:String(value:Int)
		Select category
			case "MONEY"
				return TFunctions.convertValue(value, 2)
			case "REACH"
				return value +"%"
			case "IMAGE"
				return value +"%"
			case "BETTY"
				return value/100 +"%"
		End Select
		throw "TSimpleMission.formatValue(): unknown category "+category
	End Method

	Method getDescription:String()
		Local desc:String
		If targetValue < 0
			desc="Maximierung "+ getCategory()
		Else
			desc= getCategory() +" " + formatValue(targetValue)
		EndIf
		If daysForAchieving > 0
			If targetValue < 0
				desc:+ " nach "+daysForAchieving+" Tagen"
			Else
				desc:+ " innerhalb von "+daysForAchieving+" Tagen"
			EndIf
		EndIf
		Return desc
	EndMethod


	Method OnMoneyChange:Int(triggerEvent:TEventBase)
		currentPlayerFinance:TPlayerFinance = TPlayerFinance(triggerEvent.GetSender())
		If Not currentPlayerFinance Then throw "TSimpleMission.OnMoneyChange: no finance in event"
		checkMissionResult(False)
	End Method

	Method OnReachChange:Int(triggerEvent:TEventBase)
		currentPlayerMap = TStationMap(triggerEvent.GetSender())
		If Not currentPlayerMap Then throw "TSimpleMission.OnReachChange: no Map in event"
		checkMissionResult(False)
	End Method

	Method OnImageChange:Int(triggerEvent:TEventBase)
		currentImage:TPublicImage = TPublicImage(triggerEvent.GetSender())
		If Not currentImage Then throw "TSimpleMission.OnImageChange: no Image"
		checkMissionResult(False)
	End Method

	Method OnBettyChange:Int(triggerEvent:TEventBase)
		Local betty:TBetty=TBetty(triggerEvent.GetSender())
		If Not betty Then throw "TSimpleMission.OnBettyChange: no Betty-Event"
		currentBettyEvent = triggerEvent
		checkMissionResult(False)
	End Method

	Method checkMissionResult(forceFinish:Int=False)
		Local currentValue:Int
		Local currentValueRaw:Float
		Local currentPlayer:Int = -1
		Select category
			case "MONEY"
				If not currentPlayerFinance Then currentPlayerFinance = GetPlayerFinanceCollection().Get(playerID, -1)
				currentValue = currentPlayerFinance.GetMoney()
				currentValueRaw = currentValue
				currentPlayer = currentPlayerFinance.playerID
			case "REACH"
				If not currentPlayerMap Then currentPlayerMap = GetStationMapCollection().GetMap(playerID, True)
				Local coverage:Float = currentPlayerMap.GetCoverage()
				currentValue = Int(coverage*100)
				currentValueRaw = coverage
				currentPlayer = currentPlayerMap.GetOwner()
			case "IMAGE"
				If not currentImage Then currentImage = GetPlayer(playerID).GetPublicImage()
				Local image:Float = currentImage.GetAverageImage()
				currentValue = Int(image)
				currentValueRaw = image
				currentPlayer = currentImage.playerID
			case "BETTY"
				Local betty:TBetty = GetBetty()
				If currentBettyEvent
					currentPlayer = currentBettyEvent.GetData().GetInt("player")
				Else
					currentPlayer = playerID
				EndIf
				currentValue = betty.GetInLove(currentPlayer)
				currentValueRaw = currentValue
		End Select

		Local data:TData = New TData
		Local key:TEventKey = GameEventKeys.Mission_Achieved
		Local fireEvent:Int = False
		If targetValue > 0
			If currentValue >= targetValue
				If playerID = currentPlayer
					'player wins
					fireEvent = True
				Else
					data.addString("text", "~nEin anderer Spieler war schneller")
					'other player wins
					fireEvent = True
					key = GameEventKeys.Mission_Failed
				EndIf
			ElseIf forceFinish
				'no player wins
				'data.addInt("player", -1)'do not put this into highscore; 
				fireEvent = True
				key = GameEventKeys.Mission_Failed
			EndIf
		ElseIf forceFinish
			'maximized value after x days
			Local txt:String = "~n"+ getCategory() +" "+formatValue(currentValue)
			data.addString("text", txt )
			fireEvent = True
		EndIf

		If fireEvent
			data.addFloat("value", currentValue)
			data.addFloat("valueRaw", currentValueRaw)

			Local score:TMissionHighscore = new TMissionHighscore
			Local playerForScore:TPlayer = GetPlayer(playerID)
			score.playerID = playerID
			score.playerName = playerForScore.Name
			score.channelName = playerForScore.channelname
			score.missionAccomplished = True
			If Not playerForScore.IsHuman() Then score.aiPlayer = True
			score.playerDifficulty = playerForScore.GetDifficulty().GetGUID()
			score.gameMinutes = GetWorldTime().GetTimeGoneAsMinute(True)
			score.value = data
			'TODO no entry for free game?
			'for free game store start year,playerdifficulties
			If key = GameEventKeys.Mission_Achieved
				'TODO for "maximize value mission" an AI value might have performed better
				'ignore those for now
				If playerID <> currentPlayer
					score = null
					'TODO throw error? should not happen; achieve by other player = fail
				EndIf
			Else
				If currentPlayer = playerID
					score.missionAccomplished = False
				Else
					'TODO create AI score entry?
					score = null
				EndIf
			EndIf
			If score
				'print "adding highscore " + playerID
				TAllHighscores.addEntry(getMissionId(), difficulty, score)
			EndIf
			data=data.copy()
			data.add("type", category)
			data.addInt("days", daysRun)
			data.addInt("player", currentPlayer)'may be misleading if there is no winner
			data.add("highscore", score)
			TriggerBaseEvent(key, data, Self)
		EndIf
		currentPlayerFinance = null
		currentPlayerMap = null
		currentImage = null
		currentBettyEvent = null
	EndMethod
End Type