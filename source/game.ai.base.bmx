SuperStrict
?threaded
Import Brl.Threads
?
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.luaengine.bmx"
Import "Dig/base.util.luaengine.bmx"

Const THREADED_AI_DISABLED:int = True


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


	Method GetLuaEngine:TLuaEngine()
		'register engine
		if not _luaEngine then _luaEngine = TLuaEngine.Create("")
		return _luaEngine
	End Method


	Method AddEvent(name:string, data:object[])
		local aiEvent:TAIEvent = new TAIEvent
		aiEvent.name = name
		aiEvent.AddDataSet(data)
		AddEventObj(aiEvent)
	End Method


	Method AddEventObj(aiEvent:TAIEvent)
		if THREADED_AI_DISABLED then return
		'TODO: optimize queue structure / use a pool?

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
		print "Starting AI " + playerID

		scriptFileName = "res/ai/DefaultAIPlayer/DefaultAIPlayer.lua"

		'load lua file
		LoadScript(scriptFileName)

		'register source and available objects
		GetLuaEngine().RegisterToLua()

		'kick off new thread
?threaded
		If not THREADED_AI_DISABLED
			_updateThread = CreateThread( UpdateThread, self )
		EndIf
?
	End Method


	Method Stop()
		print "Stopping AI " + playerID
?threaded
		If not THREADED_AI_DISABLED
			_updateThreadExit = True
			WaitThread(_updateThread)
			print "stopped thread for AI " + playerID

			'reset
			_updateThreadExit = False
			DetachThread(_updateThread)
			_updateThread = Null
		EndIf
?

'		scriptEnv.ShutDown()
'		KI_EventManager.unregisterKI(Self)
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
			delay(250)

			'received command to exit the thread
			if aiBase._updateThreadExit then exit
		Forever
	End Function
?

	Method Update()
		if not IsActive() then return

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

	Method CallAddEvent(eventName:string, args:object[]) abstract
	Method CallGetEventCount:Int() abstract
	Method CallUpdate() abstract

	Method ConditionalCallOnTick() abstract
	Method CallOnLoadState() abstract
	Method CallOnSaveState() abstract
	Method CallOnLoad() abstract
	Method CallOnSave() abstract
	Method CallOnRealtimeSecond(millisecondsGone:Int=0) abstract
	Method CallOnMinute(minute:Int=0) abstract
	Method CallOnChat(fromID:int=0, text:String = "", chatType:int = 0, channels:int = 0) abstract
	Method CallOnProgrammeLicenceAuctionGetOutbid(licence:object, bid:int, bidderID:int) abstract
	Method CallOnProgrammeLicenceAuctionWin(licence:object, bid:int) abstract
	Method CallOnBossCalls(latestWorldTime:Double=0) abstract
	Method CallOnBossCallsForced() abstract
	Method CallOnPublicAuthoritiesStopXRatedBroadcast() abstract
	Method CallOnPublicAuthoritiesConfiscateProgrammeLicence(confiscatedLicence:object, targetLicence:object) abstract
	Method CallOnAchievementCompleted(achievement:object) abstract
	Method CallOnWonAward(award:object) abstract
	Method CallOnLeaveRoom(roomId:int) abstract
	Method CallOnReachTarget(target:object) abstract
	'	Method CallOnReachTarget() abstract
	Method CallOnReachRoom(roomId:Int) abstract
	Method CallOnBeginEnterRoom(roomId:int, result:int) abstract
	Method CallOnEnterRoom(roomId:int) abstract
	Method CallOnDayBegins() abstract
	Method CallOnGameBegins() abstract
	Method CallOnInit() abstract
	Method CallOnMoneyChanged(value:int, reason:int, reference:object) abstract
	Method CallOnMalfunction() abstract

	Method CallOnPlayerGoesBankrupt(playerID:int) abstract
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
	Field name:string
	Field data:object[]

	Method SetName:TAIEvent(name:string)
		self.name = name
		return self
	End Method


	Method AddInt:TAIEvent(i:int)
		data :+ [object(string(i))]
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

	Method AddDataSet:TAIEvent(o:object[])
		data :+ o
		return self
	End Method
End Type