SuperStrict
Import "Dig/base.util.mersenne.bmx" 'randrange
Import "game.gameconstants.bmx"
Import "game.mission.base.bmx"
Import "game.figure.base.bmx"
Import "game.world.worldtime.bmx"


'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGameBase {_exposeToLua="selected"}
	Field gameId:Int
	'used so that random values are the same on all computers having
	'the same seed value
	Field randomSeedValue:Int = 0
	'title of the game
	Field title:String = "MyGame"
	'0 = Mainmenu, 1=Running, ...
	Field gamestate:Int = -1
	Field gameOver:int = False
	Field mission:TMission

	Field nextXRatedCheckMinute:Int = -1
	'stores the level of banruptcy for each player
	'0 = everything ok, 1-3 = days with negative balance
	Field playerBankruptLevel:int[]
	'stores the time of when the level was set, this is to avoid
	'increasing the level on a day change while some milliseconds before
	'the daily costs were paid...
	Field playerBankruptLevelTime:Long[]

	'last sync
	Field stateSyncTime:Long	= 0
	'sync every
	Field stateSyncTimer:Int = 2000
	'the last moment a realtime second was gone
	Field lastTimeRealTimeSecondGone:Long = 0
	'last moment a WorlTime-"minute" was gone (for missed minutes)
	Field lastTimeMinuteGone:Long = 0

	'minutes till movie agency gets refilled again
	Field refillMovieAgencyTime:Int = 180

	'minutes till script agency gets refilled again
	Field refillScriptAgencyTime:Int = -1

	'minutes till ad agency gets refilled again
	Field refillAdAgencyTime:Int = 240
	Field refillAdAgencyOverridePercentage:Float = 0.5

	Field playerNames:string[] = ["Ronny", "Sandra", "Seidi", "Alfi"]
	Field channelNames:string[] = ["TowerTV", "SunTV", "FunTV", "RatTV"]

	'--networkgame auf "isNetworkGame()" umbauen
	'are we playing a network game? 0=false, 1=true, 2
	Field networkgame:Int = 0
	'start the game now?
	Field startNetworkGame:Int = 0
	'playing over internet? 0=false
	Field onlinegame:Int = 0

	Field terrorists:TFigureBase[2]
	Field marshals:TFigureBase[2]

	'which cursor has to be shown? 0=normal 1=dragging
	private
	Field cursor:Int = 0 {nosave}
	Field cursorExtra:Int = 0 {nosave}
	Field cursorAlpha:Float = 1.0 {nosave}

	public

	'username of the player ->set in config
	Global userName:String = ""
	'userport of the player ->set in config
	Global userPort:Short = 4544
	'directory containing the movie/news/... databases
	Global userDBDir:String = ""
	'channelname the player uses ->set in config
	Global userChannelName:String = ""
	'language the player uses ->set in config
	Global userLanguage:String = "de"
	Global userStartYear:Int = 1985
	Global userFallbackIP:String = ""

	Global _instance:TGameBase

	Const CURSOR_DEFAULT:Int = 0
	Const CURSOR_PICK:Int = 1
	Const CURSOR_PICK_HORIZONTAL:Int = 2
	Const CURSOR_PICK_VERTICAL:Int = 3
	Const CURSOR_HOLD:Int = 4
	Const CURSOR_STOP:Int = 5
	Const CURSOR_INTERACT:Int = 6
	Const CURSOR_NONE:Int = 7

	Const CURSOR_EXTRA_NONE:Int = 0
	Const CURSOR_EXTRA_FORBIDDEN:Int = 1
	Const CURSOR_EXTRA_SEMITRANSPARENT:Int = 2

	'===== GAME STATES =====
	Const STATE_RUNNING:Int			= 0
	Const STATE_MAINMENU:Int		= 1
	Const STATE_NETWORKLOBBY:Int	= 2
	Const STATE_SETTINGSMENU:Int	= 3
	'mode when data gets synchronized or initialized
	Const STATE_PREPAREGAMESTART:Int= 4


	Function GetInstance:TGameBase()
		if not _instance Then _instance = new TGameBase
		return _instance
	End Function


	'(re)set everything to default values
	Method Initialize()
		SetRandomizerBase(MilliSecs())
		gameId = Rand32()
		SetRandomizerBase(0)
		title = "MyGame"
		SetCursor(TGameBase.CURSOR_DEFAULT)
		gamestate = 1 'mainmenu
		gameOver = False

		nextXRatedCheckMinute = -1
		stateSyncTime = 0
		stateSyncTimer = 2000
		lastTimeRealTimeSecondGone = 0
		lastTimeMinuteGone = 0

		networkgame = 0
		startNetworkGame = 0
		onlinegame = 0

		playerBankruptLevel = new Int[0]
		playerBankruptLevelTime = new Long[0]

		'remove existing figures
		'might be done by GetFigure[Base]Collection().Initialize() already
		For local f:TFigureBase = EachIn terrorists
			GetFigureBaseCollection().Remove(f)
		Next
		For local f:TFigureBase = EachIn marshals
			GetFigureBaseCollection().Remove(f)
		Next
		'reset arrays
		terrorists = new TFigureBase[2]
		marshals = new TFigureBase[2]
	End Method


	Method SetPaused(bool:Int=False)
	End Method


	Method IsPaused:int()
		return False
	End Method


	Method SetGameSpeedPreset(preset:int)
		'stub
	End Method

	Method SetGameSpeed(timeFactor:int = 15)
		'stub
	End Method

	'run this before EACH started game
	Method PrepareStart(startNewGame:Int)
		'stub
	End Method


	'run this BEFORE the first game is started
	Function PrepareFirstGameStart:Int(startNewGame:Int)
		'stub
	End Function


	Method PrepareNewGame:Int()
		'stub
	End Method

	Method StartNewGame:Int()
		'stub
	End Method

	Method StartLoadedSaveGame:Int()
		'stub
	End Method


	Method EndGame:Int()
		'stub
	End Method
	

	Method Update(deltaTime:Float=1.0)
		'stub
	End Method


	Method SetGameOver()
		gameOver = True
	End Method


	Method IsGameOver:int()
		return gameOver = True
	End Method


	Method SetCursorAlpha(alpha:Float)
		self.cursorAlpha = alpha
	End Method


	Method SetCursorExtra(cursorExtra:Int)
		self.cursorExtra = cursorExtra
	End Method


	Method SetCursor(cursor:Int, cursorExtra:Int = 0)
		self.cursor = cursor
		self.cursorExtra = cursorExtra
	End Method


	Method GetCursor:int()
		Return cursor
	End Method
	
	
	Method GetCursorExtra:int()
		Return cursorExtra
	End Method


	Method GetCursorAlpha:Float()
		Return cursorAlpha
	End Method

	
	Method SetPlayerBankruptLevel:int(playerID:int, level:int, time:Long=-1)
		if playerID < 1 then return False

		'resize if needed
		if playerBankruptLevel.length < playerID
			playerBankruptLevel = playerBankruptLevel[.. playerID]
		endif

		if playerBankruptLevelTime.length < playerID
			playerBankruptLevelTime = playerBankruptLevelTime[.. playerID]
		endif

		'value already set
		if playerBankruptLevel[playerID -1] = level then return False

		playerBankruptLevel[playerID -1] = level

		return True
	End Method


	Method GetPlayerBankruptLevel:int(playerID:int)
		if playerID < 1 or playerBankruptLevel.length < playerID then return 0

		return playerBankruptLevel[playerID -1]
	End Method


	Method GetPlayerBankruptLevelTime:Long(playerID:int)
		if playerID < 1 or playerBankruptLevelTime.length < playerID then return 0

		return playerBankruptLevelTime[playerID -1]
	End Method


	Method ComputeNextXRatedCheckMinute()
		'do not use the timeslots 50-54 ... maybe thats too late?
		'-9 till 0 are "no check"
		nextXRatedCheckMinute = RandRange(-9, 49)
		If nextXRatedCheckMinute <= 0 Then nextXRatedCheckMinute = -1
	End Method


	Method GetNextXRatedCheckMinute:Int()
		Return nextXRatedCheckMinute
	End Method


	'computes daily costs like station or newsagency fees for every player
	Method ComputeDailyCosts(day:Int=-1)
		'stub
	End Method


	Method SetGameState:Int(gamestate:Int, force:Int=False )
		If Self.gamestate = gamestate And Not force Then Return True
		Self.gamestate = gamestate
	End Method


	Method IsGameState:Int(gamestate:int)
		return Self.gamestate = gamestate
	End Method


	Method IsGameLeader:Int()
		return True
	End Method


	Method IsControllingPlayer:Int(playerID:Int)
		return True
	End Method


	Function SendSystemMessage:Int(message:String)
		'stub
	End Function


	Method SetStartYear(year:int)
		year = Max(1980, year)
		'set start year
		GetWorldTime().SetStartYear(year)
	End Method


	Method GetStartYear:Int()
		return GetWorldTime().GetStartYear()
	End Method

rem
	Method SwitchPlayer:int(newID:Int, oldID:int=-1)
		return False
	End Method
endrem

	Method SwitchPlayerIdentity:int(ID1:int, ID2:int)
		return False
	End Method


	Method SetLocalPlayer:int(ID:Int=-1)
		return False
	End Method


	Method PlayingAGame:Int()
		If gamestate <> STATE_RUNNING Then Return False

		Return True
	End Method


	Method GetRandomizerBase:Int()
		Return randomSeedValue
	End Method


	Method SetRandomizerBase( value:Int=0 )
		randomSeedValue = Abs(value)
		'seed the random base for MERSENNE TWISTER (seedrnd for the internal one)
		SeedRand(randomSeedValue)
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetGameBase:TGameBase()
	Return TGameBase.GetInstance()
End Function