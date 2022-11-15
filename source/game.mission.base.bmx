SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameeventkeys.bmx"
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"

Enum MissionDifficulty
	NONE = 0
	EASY = 1
	NORMAL = 2
	HARD = 3
	HARDER = 4
	HARDEST = 5
End Enum

Type TMission
	Global _eventListeners:TEventListenerBase[]
	Field difficulty:MissionDifficulty
	Field daysForAchieving:Int = -1
	Field playerID:Int = -1
	Field daysRun:Int = -1

	Method getTitle:String() abstract

	Method getCategory:String() abstract

	'for overriding
	Method getIdSuffix:String()
		Return ""
	End Method

	Method getMissionId:String()
		Local id:String = getCategory() + "_diff"+difficulty
		If daysForAchieving > 0 Then id:+ ("_days"+daysForAchieving)
		Local idSuffix:String = getIdSuffix()
		If idSuffix Then id:+ ("_"+getIdSuffix())
		return id.toUpper()
	End Method

	Method initialize()
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
	Method getSupportedDifficulties:Int[]()
		return [ MissionDifficulty.EASY.ordinal(), MissionDifficulty.NORMAL.ordinal(), MissionDifficulty.HARD.ordinal(), MissionDifficulty.HARDER.ordinal(), MissionDifficulty.HARDEST.ordinal(), MissionDifficulty.NONE.ordinal()]
	End Method

	Method getHumanPlayerPosition:Int(difficulty:MissionDifficulty)
		Return -1
		rem
		'a mission difficulty level might define a specific floor for the player
		Select difficulty
			case MissionDifficulty.NONE
				return -1
			case MissionDifficulty.EASY
				return 3
			case MissionDifficulty.NORMAL
				return 2
			case MissionDifficulty.HARD
				return 4
			case MissionDifficulty.HARDER
				return 4
			case MissionDifficulty.HARDEST
				return 4
		End Select
		throw "TMission:illegal difficulty "+ difficulty
		endrem
	End Method

	Method getHumanPlayerDifficulty:String(difficulty:MissionDifficulty)
		Select difficulty
			case MissionDifficulty.NONE
				return ""
			case MissionDifficulty.EASY
				return "easy"
			case MissionDifficulty.NORMAL
				return "normal"
			case MissionDifficulty.HARD
				return "normal"
			case MissionDifficulty.HARDER
				return "hard"
			case MissionDifficulty.HARDEST
				return "hard"
		End Select
		throw "TMission:illegal difficulty "+ difficulty
	End Method

	Method getAiPlayerDifficulty:String(difficulty:MissionDifficulty)
		Select difficulty
			case MissionDifficulty.NONE
				return ""
			case MissionDifficulty.EASY
				return "normal"
			case MissionDifficulty.NORMAL
				return "normal"
			case MissionDifficulty.HARD
				return "easy"
			case MissionDifficulty.HARDER
				return "normal"
			case MissionDifficulty.HARDEST
				return "easy"
		End Select
		throw "TMission:illegal difficulty "+ difficulty
	End Method

	Method getStartYear:Int(difficulty:MissionDifficulty)
		Select difficulty
			case MissionDifficulty.NONE
				return -1
			case MissionDifficulty.EASY
				return 1990
			case MissionDifficulty.NORMAL
				return 1985
			case MissionDifficulty.HARD
				return 1995
			case MissionDifficulty.HARDER
				return 1995
			case MissionDifficulty.HARDEST
				return 1995
		End Select
		throw "TMission:illegal difficulty "+ difficulty
	End Method
End Type