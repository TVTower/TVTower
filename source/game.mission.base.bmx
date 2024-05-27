SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameconstants.bmx"
Import "game.gameeventkeys.bmx"
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"

Type TMission
	Global _eventListeners:TEventListenerBase[]
	Field difficulty:Int = -1
	Field daysForAchieving:Int = -1
	Field playerID:Int = -1
	Field daysRun:Int = -1
	Field gameId:Int

	Method getTitle:String() abstract

	Method getCategory:String() abstract

	'for overriding
	Method getIdSuffix:String()
		Return ""
	End Method

	Method getMissionId:String()
		Local id:String = getCategory()
		'do not include difficulty in ID! it is available separately in mission and highscore
		If daysForAchieving > 0 Then id:+ ("_days"+daysForAchieving)
		Local idSuffix:String = getIdSuffix()
		If idSuffix Then id:+ ("_"+idSuffix)
		return id.toUpper()
	End Method

	Method initialize(gameId:Int)
		Self.gameId = gameId
		'=== EVENTS ===
		'remove old listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]
		Local missionListeners:TEventListenerBase[] = getCheckListeners()
		If missionListeners Then _eventListeners :+ missionListeners

		If daysForAchieving > 0 Then _eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.Game_OnDay, Self, "OnDay")]
		daysRun = GetWorldTime().GetDaysRun(-1)
		If playerID < 1 Then throw "TMission.initialize(): player id was not set!"
	End Method

	Method done()
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]
	EndMethod

	Method OnDay:Int(triggerEvent:TEventBase)
		Local now:Long = triggerEvent.GetData().GetLong("time",-1)
		daysRun = GetWorldTime().GetDaysRun(now)
		If daysForAchieving > 0 and daysRun >= daysForAchieving
			checkMissionResult(True)
		EndIf
	End Method

	Method getCheckListeners:TEventListenerBase[]() abstract

	Method getDescription:String() abstract

	Method checkMissionResult(forceFinish:Int=False) abstract

	'Array of enum values does not work!! - the values of the array cannot be converted back via "ordinal"
	'enum is also not persisted in xml!
	Method getSupportedDifficulties:Int[]()
		return [ TVTMissionDifficulty.EASY, TVTMissionDifficulty.NORMAL, TVTMissionDifficulty.HARD, TVTMissionDifficulty.HARDER, TVTMissionDifficulty.HARDEST, TVTMissionDifficulty.NONE ]
	End Method

	Method getHumanPlayerPosition:Int(difficulty:Int)
		Return -1
		rem
		'a mission difficulty level might define a specific floor for the player
		Select difficulty
			case TVTMissionDifficulty.NONE
				return -1
			case TVTMissionDifficulty.EASY
				return 3
			case TVTMissionDifficulty.NORMAL
				return 2
			case TVTMissionDifficulty.HARD
				return 4
			case TVTMissionDifficulty.HARDER
				return 4
			case TVTMissionDifficulty.HARDEST
				return 4
		End Select
		throw "TMission:illegal difficulty "+ difficulty
		endrem
	End Method

	Method getHumanPlayerDifficulty:String(difficulty:Int = -1)
		Select difficulty
			case TVTMissionDifficulty.NONE
				return ""
			case TVTMissionDifficulty.EASY
				return "easy"
			case TVTMissionDifficulty.NORMAL
				return "normal"
			case TVTMissionDifficulty.HARD
				return "normal"
			case TVTMissionDifficulty.HARDER
				return "hard"
			case TVTMissionDifficulty.HARDEST
				return "hard"
		End Select
		throw "TMission:illegal difficulty "+ difficulty
	End Method

	Method getAiPlayerDifficulty:String(difficulty:Int = -1)
		Select difficulty
			case TVTMissionDifficulty.NONE
				return ""
			case TVTMissionDifficulty.EASY
				return "normal"
			case TVTMissionDifficulty.NORMAL
				return "normal"
			case TVTMissionDifficulty.HARD
				return "easy"
			case TVTMissionDifficulty.HARDER
				return "normal"
			case TVTMissionDifficulty.HARDEST
				return "easy"
		End Select
		throw "TMission:illegal difficulty "+ difficulty
	End Method

	Method getStartYear:Int(difficulty:Int = -1)
		Select difficulty
			case TVTMissionDifficulty.NONE
				return -1
			case TVTMissionDifficulty.EASY
				return 1990
			case TVTMissionDifficulty.NORMAL
				return 1985
			case TVTMissionDifficulty.HARD
				return 1995
			case TVTMissionDifficulty.HARDER
				return 1995
			case TVTMissionDifficulty.HARDEST
				return 1995
		End Select
		throw "TMission:illegal difficulty "+ difficulty
	End Method
End Type