SuperStrict
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.luaengine.bmx"
Import "Dig/base.util.luaengine.bmx"


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

	Field _luaEngine:TLuaEngine {nosave}

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


rem
	'currently unused

	Method OnCreate()
		Local args:Object[1]
		args[0] = String(playerID)
		if (AiRunning) then LuaEngine.CallLuaFunction("OnCreate", args)
	End Method
endrem


	Method Start()
		'stay compatible for some versions...
		if scriptFileName = "res/ai/DefaultAIPlayer.lua"
			scriptFileName = "res/ai/DefaultAIPlayer/DefaultAIPlayer.lua"
		endif

		'load lua file
		LoadScript(scriptFileName)

		'register source and available objects
		GetLuaEngine().RegisterToLua()
	End Method


	Method Stop()
'		scriptEnv.ShutDown()
'		KI_EventManager.unregisterKI(Self)
	End Method


	'loads a .lua-file and registers needed objects
	Method LoadScript:int(luaScriptFileName:string)
		if luaScriptFileName <> "" then scriptFileName = luaScriptFileName
		if scriptFileName = "" then return FALSE

		Local loadingStopWatch:TStopWatch = new TStopWatch.Init()
		'load content
		GetLuaEngine().SetSource(LoadText(scriptFileName))

		'if there is content set, print it
		If GetLuaEngine().GetSource() <> ""
			AddLog("KI.LoadScript", "ReLoaded LUA AI for player "+playerID+". Loading Time: " + loadingStopWatch.GetTime() + "ms", LOG_DEBUG | LOG_LOADING)
		else
			AddLog("KI.LoadScript", "Loaded LUA AI for player "+playerID+". Loading Time: " + loadingStopWatch.GetTime() + "ms", LOG_DEBUG | LOG_LOADING)
		endif
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
'	    Try
			return GetLuaEngine().CallLuaFunction(name, args)
'		Catch ex:Object
'			print "ex: "+ex.ToString()
'			TLogger.log("Ai.CallLuaFunction", "Script "+scriptFileName+" does not contain function ~q"+name+"~q. Or the function resulted in an error.", LOG_ERROR | LOG_AI)
'		End Try

'		return Null
	End Method


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