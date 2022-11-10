SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameeventkeys.bmx"
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"

Type TMission
	Global _eventListeners:TEventListenerBase[]
	Field difficulty:String
	Field daysForAchieving:Int = -1
	Field playerID:Int = -1
	Field daysRun:Int = -1

	Method getTitle:String()
		Return GetLocale("MISSION_"+getCategory())
	End Method

	Method getCategory:String() abstract

	'for overriding
	Method getIdSuffix:String()
		Return ""
	End Method

	Method getMissionId:String()
		Local id:String = getCategory() + "_"+difficulty
		If daysForAchieving > 0 Then id:+ ("_d"+daysForAchieving)
		Local idSuffix:String = getIdSuffix()
		If idSuffix Then id:+ ("_"+getIdSuffix())
		return id.toUpper()
	End Method

	Method initialize()
		'=== EVENTS ===
		'remove old listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		Local missionListener:TEventListenerBase = getCheckListener()
		If missionListener Then _eventListeners :+ [missionListener]

		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.Game_OnDay, Self, "OnDay")]
		daysRun = GetWorldTime().GetDaysRun(-1)
		If playerID < 1 Then throw "TMission.initialize(): player id was not set!"
	End Method

	Method OnDay:Int(triggerEvent:TEventBase)
		Local now:Long = triggerEvent.GetData().GetLong("time",-1)
		daysRun = GetWorldTime().GetDaysRun(now)
		If daysForAchieving > 0 and daysRun >= daysForAchieving
			checkMissionResult(True)
		EndIf
	End Method

	Method getCheckListener:TEventListenerBase() abstract

	Method getDescription:String() abstract

	Method checkMissionResult(forceFinish:Int=False) abstract

	Method getHumanPlayerPosition:Int(difficulty:String)
		Return -1
		rem
		'a mission difficulty level might define a specific floor for the player
		Select difficulty
			case "easy"
				return 3
			case "normal"
				return 2
			case "hard"
				return 4
		End Select
		throw "TMission:illegal difficulty "+ difficulty
		endrem
	End Method

	Method getHumanPlayerDifficulty:String(difficulty:String)
		Select difficulty
			case "easy"
				return "easy"
			case "normal"
				return "normal"
			case "hard"
				return "hard"
		End Select
		throw "TMission:illegal difficulty "+ difficulty
	End Method

	Method getAiPlayerDifficulty:String(difficulty:String)
		Select difficulty
			case "easy"
				return "normal"
			case "normal"
				return "normal"
			case "hard"
				return "easy"
		End Select
		throw "TMission:illegal difficulty "+ difficulty
	End Method

	Method getStartYear:Int(difficulty:String)
		Select difficulty
			case "easy"
				return 1990
			case "normal"
				return 1985
			case "hard"
				return 1995
		End Select
		throw "TMission:illegal difficulty "+ difficulty
	End Method
End Type