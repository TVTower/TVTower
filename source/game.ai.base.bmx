SuperStrict
Import Brl.Threads
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.luaengine.bmx"

Const THREADED_AI_DISABLED:int = False


Type TAiBase
	Field playerID:int
	Field scriptFileName:String
	'contains the code used to reinitialize the AI
	Field scriptSaveState:string
	'time in milliseconds for the next "onTick"-call
	Field nextTickTime:Long
	'last processed game minute (since start) (eg via onTick-call)
	Field processedGameMinute:Long = -1
	'ticks the AI received because of AI-created ticks (scheduled ticks by the AI)
	Field internalTicks:Long
	'ticks the AI received because of at least a second passed
	Field realtimeSecondTicks:Long
	'ticks the AI processed (not including the manually scheduled ticks by the AI)
	Field ticks:Long
	'stores blitzmax objects used in the LUA scripts to ease serialisation
	'when saving a gamestate
	Field objectsUsedInLua:object[]
	Field objectsUsedInLuaCount:int
	Field started:int = False
	Field nextEventID:Int
	Field lastEventID:Int
	Field lastEventTime:Int
	Field currentEventStart:Int
	Field currentEventID:Int
	Field toSynchronizeCount:Int = 0
	Field eventQueue:TAIEvent[]

	Field _luaEngine:TLuaEngine {nosave}
	Field _objectsUsedInLuaMutex:TMutex = CreateMutex() {nosave}
	Field _callLuaFunctionMutex:TMutex = CreateMutex() {nosave}
	Field _eventQueueMutex:TMutex = CreateMutex() {nosave}
	Field _updateThreadExit:int = False {nosave}
	Field paused:int = False

	'easier access from outside
	Global _updateThreads:TThread[4] {nosave}

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

rem
	'handle all currently queued Events
	Method HandleQueuedEvents()
		LockMutex(_eventQueueMutex)

		For local aiEvent:TAIEvent = EachIn eventQueue
			HandleAIEvent(aiEvent)
		Next
		eventQueue = new TAIEvent[0]

		UnlockMutex(_eventQueueMutex)
	End Method
endrem

	Method HandleAIEvent(event:TAIEvent)
		currentEventID = event.id
		currentEventStart = Millisecs()

		Select event.id
			case TAIEvent.OnMinute
				CallLuaFunction("OnMinute", event.data)
			case TAIEvent.OnTick
				if event.data.length < 2 then Throw "TAIEvent.OnTick: Invalid AI event data"
				Local realTime:Long = long(string(event.data[0]))
				Local gameTime:Long = long(string(event.data[1]))
				CallOnTick(gameTime)
			case TAIEvent.OnInternalTick
				if event.data.length < 2 then Throw "TAIEvent.OnInternalTick: Invalid AI event data"
				Local realTime:Long = long(string(event.data[0]))
				Local gameTime:Long = long(string(event.data[1]))
				CallOnInternalTick(gameTime)
			case TAIEvent.OnRealtimeSecondTick
				if event.data.length < 2 then Throw "TAIEvent.OnRealtimeSecondTick: Invalid AI event data"
				Local realTime:Long = long(string(event.data[0]))
				Local gameTime:Long = long(string(event.data[1]))
				CallOnRealtimeSecondTick(realTime, gameTime)
			case TAIEvent.OnRealTimeSecond
				'[0] = realTimeGone
				'[1] = time since last realTimeSecond
				CallLuaFunction("OnRealTimeSecond", [event.data[1]])
			case TAIEvent.OnLoad
				CallOnLoad()
			case TAIEvent.OnSave
				CallOnSave()
			case TAIEvent.OnSaveState
				CallOnSaveState()
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

		lastEventID = currentEventID
		lastEventTime = Millisecs() - currentEventStart
		currentEventID = 0 'indicator that we are done
	End Method


	Method AddEvent(id:Int, data:object[], handleNow:Int = False)
		local aiEvent:TAIEvent = new TAIEvent
		aiEvent.SetID(id)
		aiEvent.AddDataSet(data)
		AddEventObj(aiEvent, handleNow)
	End Method


	Method AddEventObj(aiEvent:TAIEvent, handleNow:Int = False)
		'if not running, nothing can be added
		If not started then Return

		'potentially skip "unimportant events" for paused AIs (eg. ticks)
		Select aiEvent.id
			case TAIEvent.OnMinute, ..
			     TAIEvent.OnTick, ..
			     TAIEvent.OnInternalTick, ..
			     TAIEvent.OnRealtimeSecondTick, ..
			     TAIEvent.OnRealtimeSecond
				If Not IsActive() Then Return
		End Select


		'non threaded AI just handles the event now
		if THREADED_AI_DISABLED or handleNow
			HandleAIEvent(aiEvent)
			return
		endif

		LockMutex(_eventQueueMutex)
		eventQueue :+ [aiEvent]
		nextEventID = eventQueue[0].id
		UnlockMutex(_eventQueueMutex)

		if aiEvent.synchronize then toSynchronizeCount :+ 1
	End Method


	Method PopNextEvent:TAIEvent()
		if THREADED_AI_DISABLED then return Null

		if not eventQueue or eventQueue.length = 0 then return Null
		local event:TAIEvent = eventQueue[0]
		LockMutex(_eventQueueMutex)
		eventQueue = eventQueue [1 ..]
		if eventQueue.length > 0
			nextEventID = eventQueue[0].id
		Else
			nextEventID = 0
		EndIf
		UnlockMutex(_eventQueueMutex)

		if event.synchronize then toSynchronizeCount :- 1
		return event
	End Method


	Method GetNextEventCount:Int()
		if THREADED_AI_DISABLED then return 0
		return eventQueue.length
	End Method

	Method GetNextToSynchronizeEventCount:Int()
		if THREADED_AI_DISABLED then return 0
		return toSynchronizeCount
	End Method

	Method GetNextEventID:Int()
		if THREADED_AI_DISABLED then return 0
		return nextEventID
	End Method

	Method GetCurrentEventTime:Int()
		If currentEventID > 0
			Return Millisecs() - currentEventStart
		EndIf
		Return 0
	End Method

	Method GetCurrentEventID:Int()
		Return currentEventID
	End Method

	Method GetLastEventTime:Int()
		Return lastEventTime
	End Method

	Method GetLastEventID:Int()
		Return lastEventID
	End Method

	
	Method SetNextOnTickTime(time:Long)
		nextTickTime = time
	End Method


rem
	'currently unused

	Method OnCreate()
		Local args:Object[1]
		args[0] = String(playerID)
		if (AiRunning) then LuaEngine.CallLuaFunction("OnCreate", args)
	End Method
endrem

	Method IsStarted:Int()
		return started
	End Method


	Method Start()
		TLogger.Log("TAiBase #" + playerID, "Starting.", LOG_DEBUG)
		
		'create the lua engine
		self._luaEngine = New TLuaEngine()
		TLuaEngine.AddEngine(_luaEngine) 'so findEngine() can be used
		

		'load lua file
		LoadLuaScript(scriptFileName)

		started = True

		If not THREADED_AI_DISABLED
			TLogger.Log("TAiBase #" + playerID, "Creating update thread", LOG_DEBUG)
			If _updateThreads.length < playerID
				_updateThreads = _updateThreads[.. playerID]
			EndIf
			_updateThreads[playerID-1] = CreateThread( UpdateThread, self )
		EndIf

		TLogger.Log("TAiBase #" + playerID, "Started.", LOG_DEBUG)
	End Method


	Method Stop()
		TLogger.Log("TAiBase #" + playerID, "Stopping", LOG_DEBUG)
		started = False

		If not THREADED_AI_DISABLED and _updateThreads[playerID-1]
			_updateThreadExit = True
			
			Local startStop:Long = Time.GetTimeGone()
			Repeat
				If _updateThreads[playerID-1] and ThreadRunning(_updateThreads[playerID-1])
					If Time.GetTimeGone() - startStop > 500
						TLogger.Log("TAiBase #" + playerID, "Thread did not stop within 500ms. Detaching thread!", LOG_DEBUG)
						
						'reset
						_updateThreadExit = False
						DetachThread(_updateThreads[playerID-1])
						_updateThreads[playerID-1] = Null
					Else
						Delay(5)
					EndIf
				Else
					exit
				EndIf
			Forever
			
			If not TryLockMutex(_callLuaFunctionMutex)
				TLogger.Log("TAiBase #" + playerID, "-  Mutex _callLuaFunctionMutex still locked!", LOG_DEBUG)
				UnlockMutex(_callLuaFunctionMutex)
				TLogger.Log("TAiBase #" + playerID, "-  Mutex _callLuaFunctionMutex now unlocked!", LOG_DEBUG)
			EndIf
			If not TryLockMutex(_eventQueueMutex)
				TLogger.Log("TAiBase #" + playerID, "-  Mutex _eventQueueMutex still locked!", LOG_DEBUG)
				UnlockMutex(_eventQueueMutex)
				TLogger.Log("TAiBase #" + playerID, "-  Mutex _eventQueueMutex now unlocked!", LOG_DEBUG)
			EndIf

			TLogger.Log("TAiBase #" + playerID, "Removed update thread", LOG_DEBUG)
		EndIf
	End Method


	Method RegisterSharedObjects()
	End Method

	
	'loads a .lua-file and registers needed objects
	Method LoadLuaScript:int(luaScriptFileName:string)
		if luaScriptFileName <> "" then scriptFileName = luaScriptFileName
		if scriptFileName
			Local loadingStopWatch:TStopWatch = new TStopWatch.Init()
			If FileType(scriptFileName) <> FILETYPE_FILE
				AddLog("TAiBase #" + playerID, "Loading Lua-script failed, ~q" + luaScriptFileName + "~q does not exist. Loading default Lua-script.", LOG_ERROR)
				scriptFileName = "res/ai/DefaultAIPlayer/DefaultAIPlayer.lua"

				If FileType(scriptFileName) <> FILETYPE_FILE
					AddLog("TAiBase #" + playerID, "Loading Lua-script failed. Default Lua-script ~q" + scriptFileName+"~q does not exist. Aborting.", LOG_ERROR)
					Return False
				EndIf
			EndIf

			'(re-)load content
			_luaEngine.SetSourceFile(scriptFileName)

			'(re-)assign TVT, TIME, ... to lua
			RegisterSharedObjects()

			'start the engine (and run the code - so functions are known)
			_luaEngine.Start()
			

			AddLog("TAiBase #" + playerID, "Loaded Lua-script ~q" + luaScriptFileName +"~q in " + loadingStopWatch.GetTime() + "ms.", LOG_DEBUG)
			Return True
		Else
			AddLog("TAiBase #" + playerID, "Loading Lua-script failed, No Lua-script path passed.", LOG_ERROR)
			Return False
		EndIf
		
	End Method


	'loads the current file again
	Method ReloadScript:int()
		if scriptFileName="" then return FALSE

		AddLog("TAiBase #" + playerID, "Reloading LUA-script.", LOG_DEBUG)
		
'		Local wasStarted:Int = started

		'stop if running
'		if wasStarted then Stop()

		'save current state
		CallOnSaveState()

		LoadLuaScript(scriptFileName)

		'restore current state
		CallOnLoadState()
		
		'restart it
'		if wasStarted then Start()

		Return True
	End Method


	Function UpdateThread:object( data:object )
		local aiBase:TAiBase = TAiBase(data)

		Repeat
			aiBase.Update()
			'wait up to 5 ms
			If Not aiBase.IsActive() 
				Delay(1)
				if not aiBase.IsActive() then Delay(2)
				if not aiBase.IsActive() then Delay(2)
			Else
				if aiBase.GetNextEventCount() = 0 then Delay(1)
				if aiBase.GetNextEventCount() = 0 then Delay(2)
				if aiBase.GetNextEventCount() = 0 then Delay(2)
			EndIf

			'received command to exit the thread
			if aiBase._updateThreadExit then exit
		Forever
	End Function


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
		LockMutex(_objectsUsedInLuaMutex)

		objectsUsedInLuaCount :+ 1

		if objectsUsedInLua.length < objectsUsedInLuaCount
			objectsUsedInLua = objectsUsedInLua[.. objectsUsedInLua.length + 10]
		endif
		objectsUsedInLua[ objectsUsedInLuaCount-1] = o

		UnLockMutex(_objectsUsedInLuaMutex)
		return objectsUsedInLuaCount-1
	End Method


	Method GetObjectUsedInLua:object(index:int)
		if index < 0 then return null

		LockMutex(_objectsUsedInLuaMutex)

		Local result:object
		If index < objectsUsedInLua.length
			result = objectsUsedInLua[index]
		EndIf

		UnlockMutex(_objectsUsedInLuaMutex)
		Return result
	End Method


	Method ResetObjectsUsedInLua()
		LockMutex(_objectsUsedInLuaMutex)

		objectsUsedInLuaCount = 0
		objectsUsedInLua = new object[0]

		UnlockMutex(_objectsUsedInLuaMutex)
	End Method


	Method CallLuaFunction:object(name:string, args:object[], resetObjectsInUse:Int = False)
		LockMutex(_callLuaFunctionMutex)

		'reset inside the mutex protected function call
		'so it resets only right before calling the function
		'not while a second and parallel lua call is resetting while
		'the first call is actually using it
		if resetObjectsInUse then ResetObjectsUsedInLua()

		local result:object = _luaEngine.CallLuaFunction(name, args)

		UnLockMutex(_callLuaFunctionMutex)

		Return result
	End Method

	Method CallUpdate() abstract

	Method CallOnRealtimeSecondTick(realTimeGone:Long, gameTimeGone:Long) abstract
	Method CallOnInternalTick(gameTimeGone:Long) abstract
	Method CallOnTick(gameTimeGone:Long) abstract
	Method CallOnLoadState() abstract
	Method CallOnSaveState() abstract
	Method CallOnLoad() abstract
	Method CallOnSave() abstract
	Method CallOnInit() abstract
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
	Field synchronize:Int
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
	Const OnRealtimeSecondTick:Int = 27
	Const OnTick:Int = 28
	Const OnInternalTick:Int = 29


	Method SetID:TAIEvent(evID:int)
		self.id = evID
		return self
	End Method


	Method SetToSynchronize:TAIEvent(bool:int = True)
		self.synchronize = bool
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
	
	
	Method GetName:String()
		Return GetNameByID(self.id)
	End Method

	Function GetNameByID:String(id:int)
		Select id
			Case OnLoadState
				Return "OnLoadState"
			Case OnSaveState
				Return "OnSaveState"
			Case OnLoad
				Return "OnLoad"
			Case OnSave
				Return "OnSave"
			Case OnRealtimeSecond
				Return "OnRealtimeSecond"
			Case OnMinute
				Return "OnMinute"
			Case OnChat
				Return "OnChat"
			Case OnProgrammeLicenceAuctionGetOutbid
				Return "OnProgrammeLicenceAuctionGetOutbid"
			Case OnProgrammeLicenceAuctionWin
				Return "OnProgrammeLicenceAuctionWin"
			Case OnBossCalls
				Return "OnBossCalls"
			Case OnBossCallsForced
				Return "OnBossCallsForced"
			Case OnPublicAuthoritiesStopXRatedBroadcast
				Return "OnPublicAuthoritiesStopXRatedBroadcast"
			Case OnPublicAuthoritiesConfiscateProgrammeLicence
				Return "OnPublicAuthoritiesConfiscateProgrammeLicence"
			Case OnAchievementCompleted
				Return "OnAchievementCompleted"
			Case OnWonAward
				Return "OnWonAward"
			Case OnLeaveRoom
				Return "OnLeaveRoom"
			Case OnReachTarget
				Return "OnReachTarget"
			Case OnReachRoom
				Return "OnReachRoom"
			Case OnBeginEnterRoom
				Return "OnBeginEnterRoom"
			Case OnEnterRoom
				Return "OnEnterRoom"
			Case OnDayBegins
				Return "OnDayBegins"
			Case OnGameBegins
				Return "OnGameBegins"
			Case OnInit
				Return "OnInit"
			Case OnMoneyChanged
				Return "OnMoneyChanged"
			Case OnMalfunction
				Return "OnMalfunction"
			Case OnPlayerGoesBankrupt
				Return "OnPlayerGoesBankrupt"
			Case OnRealtimeSecondTick
				Return "OnRealtimeSecondTick"
			Case OnTick
				Return "OnTick"
			Case OnInternalTick
				Return "OnInternalTick"
			Default
				Return "Unknown event"
		End Select
	End Function
End Type
