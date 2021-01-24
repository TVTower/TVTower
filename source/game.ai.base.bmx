SuperStrict
?threaded
Import Brl.Threads
?
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.luaengine.bmx"
Import "Dig/base.util.luaengine.bmx"

Const THREADED_AI_DISABLED:int = False


Type TAiBase
	Field playerID:int
	Field scriptFileName:String
	'contains the code used to reinitialize the AI
	Field scriptSaveState:string
	'time in milliseconds of the last "onTick"-call
	Field LastTickTime:Long
	'game minute of the last "onTick"-call
	Field LastTickMinute:int
	Field Ticks:Long
	'stores blitzmax objects used in the LUA scripts to ease serialisation
	'when saving a gamestate
	Field objectsUsedInLua:object[]
	Field objectsUsedInLuaCount:int
	Field started:int = False
	Field eventQueue:TAIEvent[]

	Field _luaEngine:TLuaEngine {nosave}
	?threaded
	Field _callLuaFunctionMutex:TMutex = CreateMutex() {nosave}
	Field _eventQueueMutex:TMutex = CreateMutex() {nosave}
	Field _updateThread:TThread {nosave}
	Field _updateThreadExit:int = False {nosave}
	?
	Field paused:int = False

	Global AiRunning:Int = true


	Method Create:TAiBase(playerID:Int, luaScriptFileName:String)
		self.playerID = playerID
		self.scriptFileName = luaScriptFileName
		Return self
	End Method


	Method Delete()
		If _luaEngine
			TLuaEngine.RemoveEngine(_luaEngine)
			_luaEngine = Null
		EndIf
	End Method


	Method GetLuaEngine:TLuaEngine()
		'register engine
		if not _luaEngine then _luaEngine = TLuaEngine.Create("")
		return _luaEngine
	End Method


	'handle all currently queued Events
	Method HandleQueuedEvents()
		?threaded
			LockMutex(_eventQueueMutex)
		?

		For local aiEvent:TAIEvent = EachIn eventQueue
			HandleAIEvent(aiEvent)
		Next
		eventQueue = new TAIEvent[0]

		?threaded
			UnlockMutex(_eventQueueMutex)
		?
	End Method


	Method HandleAIEvent(event:TAIEvent)
		Select event.id
			case TAIEvent.OnMinute
				CallLuaFunction("OnMinute", event.data)
			case TAIEvent.OnConditionalCallOnTick
				ConditionalCallOnTick()
			case TAIEvent.OnRealTimeSecond
				CallLuaFunction("OnRealTimeSecond", event.data)
			case TAIEvent.OnLoad
				CallOnLoad()
			case TAIEvent.OnSave
				CallOnSave()
			case TAIEvent.OnSaveState
				CallOnSaveState
			case TAIEvent.OnLoadState
				CallOnLoadState()
			case TAIEvent.OnChat
				CallLuaFunction("OnChat", event.data)
			case TAIEvent.OnProgrammeLicenceAuctionGetOutbid
				CallLuaFunction("OnProgrammeLicenceAuctionGetOutbid", event.data)
			case TAIEvent.OnProgrammeLicenceAuctionWin
				CallLuaFunction("OnProgrammeLicenceAuctionWin", event.data)
			case TAIEvent.OnBossCalls
				CallLuaFunction("OnBossCalls", event.data)
			case TAIEvent.OnBossCallsForced
				CallLuaFunction("OnBossCallsForced", event.data)
			case TAIEvent.OnPublicAuthoritiesStopXRatedBroadcast
				CallLuaFunction("OnPublicAuthoritiesStopXRatedBroadcast", event.data)
			case TAIEvent.OnPublicAuthoritiesConfiscateProgrammeLicence
				CallLuaFunction("OnPublicAuthoritiesConfiscateProgrammeLicence", event.data)
			case TAIEvent.OnAchievementCompleted
				CallLuaFunction("OnAchievementCompleted", event.data)
			case TAIEvent.OnWonAward
				CallLuaFunction("OnWonAward", event.data)
			case TAIEvent.OnLeaveRoom
				CallLuaFunction("OnLeaveRoom", event.data)
			case TAIEvent.OnReachRoom
				CallLuaFunction("OnReachRoom", event.data)
			case TAIEvent.OnBeginEnterRoom
				CallLuaFunction("OnBeginEnterRoom", event.data)
			case TAIEvent.OnEnterRoom
				CallLuaFunction("OnEnterRoom", event.data)
			case TAIEvent.OnReachTarget
				CallLuaFunction("OnReachTarget", event.data)
			case TAIEvent.OnDayBegins
				CallLuaFunction("OnDayBegins", Null)
			case TAIEvent.OnGameBegins
				CallLuaFunction("OnGameBegins", Null)
			case TAIEvent.OnInit
				CallLuaFunction("OnInit", Null)
			case TAIEvent.OnMoneyChanged
				CallLuaFunction("OnMoneyChanged", event.data)
			case TAIEvent.OnMalfunction
				CallLuaFunction("OnMalfunction", Null)
			case TAIEvent.OnPlayerGoesBankrupt
				CallLuaFunction("OnPlayerGoesBankrupt", event.data)

			default
				print "Unhandled AIEvent: " + event.id
		End Select
	End Method


	Method AddEvent(id:Int, data:object[], handleNow:Int = False)
		local aiEvent:TAIEvent = new TAIEvent
		aiEvent.SetID(id)
		aiEvent.AddDataSet(data)
		AddEventObj(aiEvent, handleNow)
	End Method


	Method AddEventObj(aiEvent:TAIEvent, handleNow:Int = False)
		'non threaded AI just handles the event now
		if THREADED_AI_DISABLED or handleNow
			HandleAIEvent(aiEvent)
			return
		endif

		?threaded
			LockMutex(_eventQueueMutex)
			eventQueue :+ [aiEvent]
			UnlockMutex(_eventQueueMutex)
		?not threaded
			eventQueue :+ [aiEvent]
		?
	End Method


	Method PopNextEvent:TAIEvent()
		if THREADED_AI_DISABLED then return Null

		if not eventQueue or eventQueue.length = 0 then return Null
		local event:TAIEvent = eventQueue[0]
		?threaded
			LockMutex(_eventQueueMutex)
			eventQueue = eventQueue [1 ..]
			UnlockMutex(_eventQueueMutex)
		?not threaded
			eventQueue = eventQueue [1 ..]
		?
		return event
	End Method


	Method GetNextEventCount:Int()
		if THREADED_AI_DISABLED then return 0
		return eventQueue.length
	End Method


rem
	'currently unused

	Method OnCreate()
		Local args:Object[1]
		args[0] = String(playerID)
		if (AiRunning) then LuaEngine.CallLuaFunction("OnCreate", args)
	End Method
endrem


	Method Start()
		TLogger.Log("TAiBase", "Starting AI " + playerID, LOG_DEBUG)

		scriptFileName = "res/ai/DefaultAIPlayer/DefaultAIPlayer.lua"

		'load lua file
		LoadScript(scriptFileName)

		started = True

		'register source and available objects
		'-> done in TLuaEngine.Create()
'		GetLuaEngine().RegisterToLua()
'		print "Registered base objects"

		'kick off new thread
?threaded
		If not THREADED_AI_DISABLED
			_updateThread = CreateThread( UpdateThread, self )
			TLogger.Log("TAiBase", "Created AI " + playerID + " Update Thread", LOG_DEBUG)
		EndIf
?
	End Method


	Method Stop()
		TLogger.Log("TAiBase", "Stopping AI " + playerID, LOG_DEBUG)
		started = False
?threaded
		If not THREADED_AI_DISABLED and _updateThread
			_updateThreadExit = True
			WaitThread(_updateThread)

			'reset
			_updateThreadExit = False
			DetachThread(_updateThread)
			_updateThread = Null

			TLogger.Log("TAiBase", "Removed AI " + playerID + " Update Thread", LOG_DEBUG)
		EndIf
?
	End Method


	'loads a .lua-file and registers needed objects
	Method LoadScript:int(luaScriptFileName:string)
		if luaScriptFileName <> "" then scriptFileName = luaScriptFileName
		if scriptFileName = "" then return FALSE

		Local loadingStopWatch:TStopWatch = new TStopWatch.Init()
		'load content
		GetLuaEngine().SetSource(LoadText(scriptFileName), scriptFileName)

		'if there is content set, print it
		If GetLuaEngine().GetSource() <> ""
			AddLog("KI.LoadScript", "ReLoaded LUA AI for player "+playerID+". Loading Time: " + loadingStopWatch.GetTime() + "ms", LOG_DEBUG | LOG_LOADING)
		else
			AddLog("KI.LoadScript", "Loaded LUA AI for player "+playerID+". Loading Time: " + loadingStopWatch.GetTime() + "ms", LOG_DEBUG | LOG_LOADING)
		endif
	End Method


?threaded
	Function UpdateThread:object( data:object )
		local aiBase:TAiBase = TAiBase(data)

		Repeat
			aiBase.Update()
			delay(100)

			'received command to exit the thread
			if aiBase._updateThreadExit then exit
		Forever
	End Function
?

	Method Update()
		if not IsActive() then return
		'shut down initialized?
		if not started then return

		'print "updating AI " + playerID
		CallUpdate()
	End Method


	Method IsActive:int()
		if not AiRunning then return False
		if paused then return False
		return True
	End Method


	Method AddLog(title:string, text:string, logLevel:int)
		TLogger.log(title, text, logLevel)
	End Method


	'there is no "RemoveObjectUsedInLua" as on Savegame creation things
	'get added and on loading they get retrieved (and then deleted again)
	Method AddObjectUsedInLua:int(o:object)
		objectsUsedInLuaCount :+ 1

		if objectsUsedInLua.length < objectsUsedInLuaCount
			objectsUsedInLua = objectsUsedInLua[.. objectsUsedInLua.length + 10]
		endif
		objectsUsedInLua[ objectsUsedInLuaCount-1] = o
		return objectsUsedInLuaCount-1
	End Method


	Method GetObjectUsedInLua:object(index:int)
		if index < 0 or index >= objectsUsedInLua.length then return null

		return objectsUsedInLua[index]
	End Method


	Method ResetObjectsUsedInLua()
		objectsUsedInLuaCount = 0
		objectsUsedInLua = new object[0]
	End Method


	'loads the current file again
	Method ReloadScript:int()
		if scriptFileName="" then return FALSE

		'save current state
		CallOnSaveState()

		LoadScript(scriptFileName)

		'restore current state
		CallOnLoadState()
	End Method


	Method CallLuaFunction:object(name:string, args:object[])
		?threaded
			LockMutex(_callLuaFunctionMutex)
			local result:object = GetLuaEngine().CallLuaFunction(name, args)
			UnLockMutex(_callLuaFunctionMutex)

			return result
		?not threaded
'	    Try
			return GetLuaEngine().CallLuaFunction(name, args)
'		Catch ex:Object
'			print "ex: "+ex.ToString()
'			TLogger.log("Ai.CallLuaFunction", "Script "+scriptFileName+" does not contain function ~q"+name+"~q. Or the function resulted in an error.", LOG_ERROR | LOG_AI)
'		End Try
		?

	End Method

	Method CallUpdate() abstract

	Method ConditionalCallOnTick() abstract
	Method CallOnLoadState() abstract
	Method CallOnSaveState() abstract
	Method CallOnLoad() abstract
	Method CallOnSave() abstract
	Method CallOnInit() abstract

rem
	Method CallOnRealtimeSecond(millisecondsGone:Int=0) abstract
	Method CallOnMinute(minute:Int=0) abstract
	Method CallOnChat(fromID:int=0, text:String = "", chatType:int = 0, channels:int = 0) abstract
	Method CallOnProgrammeLicenceAuctionGetOutbid(licence:object, bid:int, bidderID:int) abstract
	Method CallOnProgrammeLicenceAuctionWin(licence:object, bid:int) abstract
	Method CallOnBossCalls(latestWorldTime:Long=0) abstract
	Method CallOnBossCallsForced() abstract
	Method CallOnPublicAuthoritiesStopXRatedBroadcast() abstract
	Method CallOnPublicAuthoritiesConfiscateProgrammeLicence(confiscatedLicence:object, targetLicence:object) abstract
	Method CallOnAchievementCompleted(achievement:object) abstract
	Method CallOnWonAward(award:object) abstract
	Method CallOnLeaveRoom(roomId:int) abstract
	Method CallOnReachTarget(target:object) abstract
	Method CallOnReachRoom(roomId:Int) abstract
	Method CallOnBeginEnterRoom(roomId:int, result:int) abstract
	Method CallOnEnterRoom(roomId:int) abstract
	Method CallOnDayBegins() abstract
	Method CallOnGameBegins() abstract
	Method CallOnMoneyChanged(value:int, reason:int, reference:object) abstract
	Method CallOnMalfunction() abstract
	Method CallOnPlayerGoesBankrupt(playerID:int) abstract
endrem
End Type



Type TLuaFunctionsBase {_exposeToLua}
	Const RESULT_OK:int        =   1
	Const RESULT_FAILED:int    =   0
	Const RESULT_WRONGROOM:int =  -2
	Const RESULT_NOKEY:int     =  -4
	Const RESULT_NOTFOUND:int  =  -8
	Const RESULT_NOTALLOWED:int= -16
	Const RESULT_INUSE:int     = -32
	Const RESULT_SKIPPED:int   = -64
End Type



Type TAIEvent {_exposeTolua}
	Field id:int
	Field data:object[]

	Const OnLoadState:Int = 1
	Const OnSaveState:Int = 2
	Const OnLoad:Int = 3
	Const OnSave:Int = 4
	Const OnRealtimeSecond:Int = 5
	Const OnMinute:Int = 6
	Const OnChat:Int = 7
	Const OnProgrammeLicenceAuctionGetOutbid:Int = 8
	Const OnProgrammeLicenceAuctionWin:Int = 9
	Const OnBossCalls:Int = 10
	Const OnBossCallsForced:Int = 11
	Const OnPublicAuthoritiesStopXRatedBroadcast:Int = 12
	Const OnPublicAuthoritiesConfiscateProgrammeLicence:Int = 13
	Const OnAchievementCompleted:Int = 14
	Const OnWonAward:Int = 15
	Const OnLeaveRoom:Int = 16
	Const OnReachTarget:Int = 17
	Const OnReachRoom:Int = 18
	Const OnBeginEnterRoom:Int = 19
	Const OnEnterRoom:Int = 20
	Const OnDayBegins:Int = 21
	Const OnGameBegins:Int = 22
	Const OnInit:Int = 23
	Const OnMoneyChanged:Int = 24
	Const OnMalfunction:Int = 25
	Const OnPlayerGoesBankrupt:Int = 26
	Const OnConditionalCallOnTick:Int = 27


	Method SetID:TAIEvent(evID:int)
		self.id = evID
		return self
	End Method


	Method AddInt:TAIEvent(i:int)
		data :+ [object(string(i))]
		return self
	End Method


	Method AddLong:TAIEvent(l:Long)
		data :+ [object(string(l))]
		return self
	End Method


	Method AddString:TAIEvent(s:string)
		data :+ [object(s)]
		return self
	End Method


	Method AddData:TAIEvent(o:object)
		data :+ [o]
		return self
	End Method


	Method Add:TAIEvent(o:object)
		data :+ [o]
		return self
	End Method


	Method AddDataSet:TAIEvent(o:object[])
		data :+ o
		return self
	End Method
End Type