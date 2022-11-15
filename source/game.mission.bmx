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
	Field missionCategories:TList {noSave}
	Field missionIDs:TList {noSave}

	Method getCategories:String[]()
		If Not missions Then _initMissions()
		Local categories:String[] = new String[0]
		For local k:string = EachIn missionCategories
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
			missionCategories = new TList()
		EndIf
		Local list:TMission[]
		Local value:Object = missions.ValueForKey(mission.GetCategory())
		If Not value
			list = new TMission[1]
			missionCategories.addLast(mission.GetCategory())
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

			_addMission(TSimpleMission.createImage(95))
			_addMission(new TCombinedMission().WithImage(75).WithReach(-30))
			_addMission(TSimpleMission.createImage(-1,20))
			_addMission(TSimpleMission.createImage(-1,40))
			_addMission(TSimpleMission.createImage(50,40))

			_addMission(TSimpleMission.createBetty(100))
			_addMission(new TCombinedMission().WithBetty(100).WithImage(80))
			_addMission(new TCombinedMission().WithBetty(75).WithImage(50))
			_addMission(TSimpleMission.createBetty(-1,20))
			_addMission(TSimpleMission.createBetty(-1,40))
			_addMission(TSimpleMission.createBetty(50,40))

			_addMission(TSimpleMission.createReach(80))
			_addMission(TSimpleMission.createReach(-1,20))
			_addMission(TSimpleMission.createReach(-1,40))
			_addMission(TSimpleMission.createReach(50,40))

			_addMission(TSimpleMission.createMoney(100000000))
			_addMission(TSimpleMission.createMoney(-1,20))
			_addMission(TSimpleMission.createMoney(-1,40))
			_addMission(TSimpleMission.createMoney(50000000,40))

			rem test mission for achieving/failing
			_addMission(new TCombinedMission().WithImage(75).WithReach(-1))
			_addMission(new TCombinedMission().WithImage(75).WithReach(1))
			_addMission(new TCombinedMission().WithImage(1).WithBetty(1))
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

	Method getCheckListeners:TEventListenerBase[]()
		If category = "MONEY" and targetValue > 0 Then Return [ EventManager.registerListenerMethod(GameEventKeys.PlayerFinance_OnChangeMoney, Self, "OnMoneyChange") ]
		If category = "REACH" and targetValue > 0 Then Return [ EventManager.registerListenerMethod(GameEventKeys.StationMap_OnRecalculateAudienceSum, Self, "OnReachChange") ]
		If category = "IMAGE" and targetValue > 0 Then Return [ EventManager.registerListenerMethod(GameEventKeys.PublicImage_OnChange, Self, "OnImageChange") ]
		If category = "BETTY" and targetValue > 0 Then Return [ EventManager.registerListenerMethod(GameEventKeys.Betty_OnAdjustLove, Self, "OnBettyChange") ]
	EndMethod

	Method getTitle:String()
		Return GetLocale("MISSION_TITLE_"+getCategory())
	End Method

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
				return value
			case "IMAGE"
				return value
			case "BETTY"
				return value/100
		End Select
		throw "TSimpleMission.formatValue(): unknown category "+category
	End Method

	Method getDescription:String()
		Local desc:String
		If targetValue < 0
			desc = GetLocale("MISSION_GOAL_MAXIMIZE").Replace("%GOAL%", getTitle())
		Else
			desc = GetLocale("MISSION_GOAL_"+getCategory()).replace("%VALUE%", formatValue(targetValue))
		EndIf
		If daysForAchieving > 0
			If targetValue < 0
				desc = GetLocale("MISSION_TIME_AFTER").Replace("%GOAL%", desc).replace("%DAYS%",daysForAchieving)
			Else
				desc = GetLocale("MISSION_TIME_WITHIN").Replace("%GOAL%", desc).replace("%DAYS%",daysForAchieving)
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
				currentValue = currentPlayerFinance.GetMoney() - currentPlayerFinance.GetCredit()
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
		Local text:String
		If targetValue > 0
			If currentValue >= targetValue
				If playerID = currentPlayer
					'player wins
					fireEvent = True
				Else
					Local playerName:String = GetPlayer(currentPlayer).Name
					text = "~n"+ GetLocale("MISSION_OTHER_PLAYER").replace("%NAME%", playerName)
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
			text = "~n"+GetLocale("MISSION_GOAL_"+ getCategory()).replace("%VALUE%", formatValue(currentValue))
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
			score.gameMinutes = GetWorldTime().GetTimeGoneAsMinute(True)
			score.startYear = GetWorldTime().GetStartYear()

			'store player difficulties - in particular for free games
			Local diffs:String[0]
			For Local i:Int = 1 To 4
				Local diff:String = GetPlayer(i).GetDifficulty().GetGUID()
				diffs:+ [diff]
			Next
			score.playerDifficulties = diffs

			score.value = data
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
			If text Then data.addString("text", text)
			TriggerBaseEvent(key, data, Self)
		EndIf
		currentPlayerFinance = null
		currentPlayerMap = null
		currentImage = null
		currentBettyEvent = null
	EndMethod
End Type

Type TCombinedMission extends TMission
	Field category:String
	Field money:Int = 0
	Field image:Int = 0
	Field reach:Int = 0
	Field betty:Int = 0

	Method withMoney:TCombinedMission(money:Int)
		Self.money = money
		If Not category Then category = "MONEY"
		return Self
	End Method

	Method withImage:TCombinedMission(image:Int)
		Self.image = image
		If Not category Then category = "IMAGE"
		return Self
	End Method

	Method withReach:TCombinedMission(reach:Int)
		Self.reach = reach
		If Not category Then category = "REACH"
		return Self
	End Method

	Method withBetty:TCombinedMission(betty:Int)
		Self.betty = betty * 100
		If Not category Then category = "BETTY"
		return Self
	End Method

	'TODO mutex - ensure only one event handled at a time
	Method getCheckListeners:TEventListenerBase[]()
		Local result:TEventListenerBase[] = new TEventListenerBase[0]
		If money Then result:+ [ EventManager.registerListenerMethod(GameEventKeys.PlayerFinance_OnChangeMoney, Self, "OnMoneyChange") ]
		If reach Then result:+ [ EventManager.registerListenerMethod(GameEventKeys.StationMap_OnRecalculateAudienceSum, Self, "OnReachChange") ]
		If image Then result:+ [ EventManager.registerListenerMethod(GameEventKeys.PublicImage_OnChange, Self, "OnImageChange") ]
		If betty Then result:+ [ EventManager.registerListenerMethod(GameEventKeys.Betty_OnAdjustLove, Self, "OnBettyChange") ]
		If daysForAchieving > 0 Then throw "TCombinedMission does not support daysForAchieving"
		return result
	EndMethod

	Method getTitle:String()
		Return GetLocale("MISSION_TITLE_"+getCategory())
	End Method

	Method getCategory:String()
		return category
	End Method

	Method getIdSuffix:String() override
		Local mapName:String = GetStationMapCollection().GetMapName()
		Local suffix:String = mapName
		If money Then suffix:+("_M"+money)
		If reach Then suffix:+("_R"+reach)
		If image Then suffix:+("_I"+image)
		If betty Then suffix:+("_B"+betty)
		Return suffix
	End Method

	Method getDescription:String()
		Local descs:String[] = new String[0]
		If betty > 0 Then descs:+ [ GetLocale("MISSION_GOAL_BETTY").replace("%VALUE%", betty/100)]
		If money > 0 Then descs:+ [ GetLocale("MISSION_GOAL_MONEY").replace("%VALUE%", TFunctions.convertValue(money, 2))]
		If reach > 0 Then descs:+ [ GetLocale("MISSION_GOAL_REACH").replace("%VALUE%", reach)]
		If image > 0 Then descs:+ [ GetLocale("MISSION_GOAL_IMAGE").replace("%VALUE%", image)]

		If betty < 0 Then descs:+ [ GetLocale("MISSION_GOAL_LESSTHAN").replace("%GOAL%",GetLocale("MISSION_GOAL_BETTY")).replace("%VALUE%", -betty/100)]
		If money < 0 Then descs:+ [ GetLocale("MISSION_GOAL_LESSTHAN").replace("%GOAL%",GetLocale("MISSION_GOAL_MONEY")).replace("%VALUE%", TFunctions.convertValue(-money, 2))]
		If reach < 0 Then descs:+ [ GetLocale("MISSION_GOAL_LESSTHAN").replace("%GOAL%",GetLocale("MISSION_GOAL_REACH")).replace("%VALUE%", -reach)]
		If image < 0 Then descs:+ [ GetLocale("MISSION_GOAL_LESSTHAN").replace("%GOAL%",GetLocale("MISSION_GOAL_IMAGE")).replace("%VALUE%", -image)]

		Local desc:String
		For Local d:String = EachIn descs
			If desc
				desc:+ (", " + d)
			Else
				desc = d
			EndIf
		Next
		return desc
	EndMethod


	Method OnMoneyChange:Int(triggerEvent:TEventBase)
		Local finance:TPlayerFinance = TPlayerFinance(triggerEvent.GetSender())
		If Not finance Then throw "TSimpleMission.OnMoneyChange: no finance in event"
		checkMissionResult(finance, null, null, null)
	End Method

	Method OnReachChange:Int(triggerEvent:TEventBase)
		Local map:TStationMap = TStationMap(triggerEvent.GetSender())
		If Not map Then throw "TSimpleMission.OnReachChange: no Map in event"
		checkMissionResult(null, map, null, null)
	End Method

	Method OnImageChange:Int(triggerEvent:TEventBase)
		Local img:TPublicImage = TPublicImage(triggerEvent.GetSender())
		If Not img Then throw "TSimpleMission.OnImageChange: no Image"
		checkMissionResult(null, null, img, null)
	End Method

	Method OnBettyChange:Int(triggerEvent:TEventBase)
		Local bettyEvent:TBetty=TBetty(triggerEvent.GetSender())
		If Not bettyEvent Then throw "TSimpleMission.OnBettyChange: no Betty-Event"
		checkMissionResult(null, null, null, triggerEvent)
	End Method

	Method checkMissionResult(forceFinish:Int=False) override
		throw "TCombinedMission.checkMissionResult does not support daysForAchieving - should not be called"
	End Method

	Method checkMissionResult(currentPlayerFinance:TPlayerFinance, currentPlayerMap:TStationMap, currentPublicImage:TPublicImage, currentBettyEvent:TEventBase)
		Local currentPlayer:Int = -1
		Local currentMoney:Int = 0
		Local currentImage:Int = 0
		Local currentImageRaw:Float
		Local currentReach:Int = 0
		Local currentReachRaw:Float
		Local currentBetty:Int = 0
		Local failFast:Int = False

		'evaluate event
		If currentPlayerFinance
			currentMoney = currentPlayerFinance.GetMoney() - currentPlayerFinance.GetCredit()
			currentPlayer = currentPlayerFinance.playerID
			If money < 0 And currentMoney >= abs(money) And currentPlayer <> playerID Then failFast = True
		ElseIf currentPlayerMap
			Local coverage:Float = currentPlayerMap.GetCoverage()
			currentReach = Int(coverage*100)
			currentReachRaw = coverage
			currentPlayer = currentPlayerMap.GetOwner()
			If reach < 0 And currentReach >= abs(reach)  And currentPlayer <> playerID Then failFast = True
		ElseIf currentPublicImage
			Local image:Float = currentPublicImage.GetAverageImage()
			currentImage = Int(image)
			currentImageRaw = image
			currentPlayer = currentPublicImage.playerID
			If image < 0 And currentImage >= abs(image)  And currentPlayer <> playerID Then failFast = True
		ElseIf currentBettyEvent
			Local bettyType:TBetty = GetBetty()
			currentPlayer = currentBettyEvent.GetData().GetInt("player")
			currentBetty = bettyType.GetInLove(currentPlayer)
			If betty < 0 And currentBetty >= abs(betty)  And currentPlayer <> playerID Then failFast = True
		Else
			throw "TCominedMission.checkMissionResult: unexpected invocation without any data"
		EndIf

		If Not failFast
			'fill rest of the needed values
			If money And Not currentMoney
				If not currentPlayerFinance Then currentPlayerFinance = GetPlayerFinanceCollection().Get(currentPlayer, -1)
				currentMoney = currentPlayerFinance.GetMoney() - currentPlayerFinance.GetCredit()
			EndIf
			If image And Not currentImage
				If not currentPublicImage Then currentPublicImage = GetPlayer(currentPlayer).GetPublicImage()
				Local image:Float = currentPublicImage.GetAverageImage()
				currentImage = Int(image)
				currentImageRaw = image
			EndIf
			If reach And not currentReach
				If not currentPlayerMap Then currentPlayerMap = GetStationMapCollection().GetMap(currentPlayer, True)
				Local coverage:Float = currentPlayerMap.GetCoverage()
				currentReach = Int(coverage*100)
				currentReachRaw = coverage
			EndIf
			If betty And not currentBetty
				Local betty:TBetty = GetBetty()
				currentBetty = betty.GetInLove(currentPlayer)
			EndIf

			Local fireEvent:Int = False
			Local key:TEventKey = GameEventKeys.Mission_Achieved
			Local score:TMissionHighscore = new TMissionHighscore
			Local text:String
			If (money < 0 And currentMoney > abs(money)) ..
					Or (reach < 0 And currentReach >= abs(reach)) ..
					Or (image < 0 And currentImage >= abs(image)) ..
					Or (betty < 0 And currentBetty >= abs(betty))
				key = GameEventKeys.Mission_Failed
				fireEvent = True
				score = null
			Else
				Local allSuccess:Int = True
				If (money And currentMoney < money)..
					Or (reach And currentReach < reach)..
					Or (image And currentImage < image)..
					Or (betty And currentBetty < betty)
					allSuccess = False
				EndIf
				If allSuccess Then fireEvent = True
				If currentPlayer <> playerId
					key = GameEventKeys.Mission_Failed
					Local playerName:String = GetPlayer(currentPlayer).Name
					text = "~n"+ GetLocale("MISSION_OTHER_PLAYER").replace("%NAME%", playerName)
					score = null
				EndIf
			EndIf
			If fireEvent
				Local data:TData = New TData
				If score
					Local playerForScore:TPlayer = GetPlayer(playerID)
					score.playerID = playerID
					score.playerName = playerForScore.Name
					score.channelName = playerForScore.channelname
					If key = GameEventKeys.Mission_Achieved
						score.missionAccomplished = True
					Else
						score.missionAccomplished = False
					EndIf
					If Not playerForScore.IsHuman() Then score.aiPlayer = True
					score.gameMinutes = GetWorldTime().GetTimeGoneAsMinute(True)
					score.startYear = GetWorldTime().GetStartYear()
					If money Then data.addInt("money", currentMoney)
					If image Then data.addFloat("image", currentImageRaw)
					If reach Then data.addFloat("reach", currentReachRaw)
					If betty Then data.addInt("betty", currentBetty)

					'store player difficulties - in particular for free games
					Local diffs:String[0]
					For Local i:Int = 1 To 4
						Local diff:String = GetPlayer(i).GetDifficulty().GetGUID()
						diffs:+ [diff]
					Next
					score.playerDifficulties = diffs
					TAllHighscores.addEntry(getMissionId(), difficulty, score)
				EndIf
				data=data.copy()
				If text data.addString("text", text)
				data.add("type", getCategory())
				data.addInt("days", daysRun)
				data.addInt("player", currentPlayer)'may be misleading if there is no winner
				If score Then data.add("highscore", score)
				TriggerBaseEvent(key, data, Self)
			EndIf
		EndIf
	EndMethod
End Type