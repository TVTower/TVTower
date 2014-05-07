
'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame {_exposeToLua="selected"}
	'globals are not saveloaded/exposed
	'0=no debug messages; 1=some debugmessages
	Global debugMode:Int = 0
	Global debugInfos:Int = 0
	Global debugQuoteInfos:Int = 0
	Field debugAudienceInfo:TDebugAudienceInfos = new TDebugAudienceInfos

	'===== GAME STATES =====
	Const STATE_RUNNING:Int			= 0
	Const STATE_MAINMENU:Int		= 1
	Const STATE_NETWORKLOBBY:Int	= 2
	Const STATE_SETTINGSMENU:Int	= 3
	'mode when data gets synchronized
	Const STATE_STARTMULTIPLAYER:Int= 4
	'mode when data needed for game (names,colors) gets loaded
	Const STATE_INITIALIZEGAME:Int	= 5

	'===== GAME SETTINGS =====
	'how many movies does a player get on a new game
	Const startMovieAmount:Int = 5					{_exposeToLua}
	'how many series does a player get on a new game
	Const startSeriesAmount:Int = 1					{_exposeToLua}
	'how many contracts a player gets on a new game
	Const startAdAmount:Int = 3						{_exposeToLua}
	'maximum level a news genre abonnement can have
	Const maxAbonnementLevel:Int = 3				{_exposeToLua}
	'how many contracts a player can possess
	Const maxContracts:Int = 10						{_exposeToLua}
	'how many movies can be carried in suitcase
	Const maxProgrammeLicencesInSuitcase:Int = 12	{_exposeToLua}

	'how many 0.0-1.0 (100%) audience is maximum reachable
	Field maxAudiencePercentage:Float = 0.3
	'used so that random values are the same on all computers having the same seed value
	Field randomSeedValue:Int = 0

	'username of the player ->set in config
	Global userName:String = ""
	'userport of the player ->set in config
	Global userPort:Short = 4544
	'channelname the player uses ->set in config
	Global userChannelName:String = ""
	'language the player uses ->set in config
	Global userLanguage:String = "de"
	Global userDB:String = ""
	Global userFallbackIP:String = ""

	'title of the game
	Field title:String = "MyGame"

	'which cursor has to be shown? 0=normal 1=dragging
	Field cursorstate:Int = 0
	'0 = Mainmenu, 1=Running, ...
	Field gamestate:Int = -1

	field gameTime:TGameTime

	'last sync
	Field stateSyncTime:Int	= 0
	'sync every
	Field stateSyncTimer:Int = 2000

	'refill movie agency every X Minutes
	Field refillMovieAgencyTimer:Int = 180
	'minutes till movie agency gets refilled again
	Field refillMovieAgencyTime:Int = 180

	'refill ad agency every X Minutes
	Field refillAdAgencyTimer:Int = 240
	'minutes till ad agency gets refilled again
	Field refillAdAgencyTime:Int = 240


	'--networkgame auf "isNetworkGame()" umbauen
	'are we playing a network game? 0=false, 1=true, 2
	Field networkgame:Int = 0
	'is the network game ready - all options set? 0=false
	Field networkgameready:Int = 0
	'playing over internet? 0=false
	Field onlinegame:Int = 0

	Global _instance:TGame
	Global _initDone:int = FALSE
	Global _firstGamePreparationDone:int = FALSE


	Method New()
		_instance = self

		if not _initDone
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			EventManager.registerListenerFunction("SaveGame.OnBeginSave", onSaveGameBeginSave)

			_initDone = TRUE
		Endif
	End Method


	Function GetInstance:TGame()
		if not _instance then _instance = new TGame.Create()
		return _instance
	End Function


	'Summary: create a game, every variable is set to Zero
	Method Create:TGame()
		LoadConfig("config/settings.xml")
		'add German and English to possible language
		TLocalization.AddLanguages("de, en")
		'select language
		TLocalization.SetLanguage(userlanguage)
		TLocalization.LoadResource("res/lang/lang_"+userlanguage+".txt")

		networkgame = 0

		GetGametime().SetStartYear(1985)
		title = "unknown"

		SetRandomizerBase( MilliSecs() )

		CreateInitialPlayers()

		'creates all Rooms - with the names assigned at this moment
		Init_CreateAllRooms()

		Return self
	End Method



	'Initializes "data" needed for a game
	'(maps, databases, managers)
	Method Initialize()
		'managers skip initialization if already done (eg. during loading)
		GetPopularityManager().Initialize()
		GetBroadcastManager().Initialize()

		'load all movies, news, series and ad-contracts
		LoadDatabase(userdb)

		'load the used map
		StationMapCollection.LoadMapFromXML("config/maps/germany.xml")
	End Method


	'run when a specific game starts
	Method Start:int()
		gameTime = GetGameTime()

		if not _firstGamePreparationDone
			PrepareFirstGameStart()
			_firstGamePreparationDone = True
		endif
		PrepareGameStart()

		'load databases, populationmap, ...
		Initialize()


		'we have to set gamestate BEFORE init_all()
		'as init_all sends events which trigger gamestate-update/draw
		Game.SetGamestate(TGame.STATE_INITIALIZEGAME)
		If Not Init_Complete
			Init_All()
			Init_Complete = True		'check if rooms/colors/... are initiated
		EndIf

		'disable chat if not networkgaming
		If Not game.networkgame
			InGame_Chat.hide()
		Else
			InGame_Chat.show()
		EndIf

		Game.SetGamestate(TGame.STATE_RUNNING)
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Savegame loaded - colorize players.", LOG_DEBUG | LOG_SAVELOAD)
		'reconnect AI and other things
		For local player:TPlayer = eachin GetPlayerCollection().players
			player.onLoad(null)
		Next
		'colorize gfx again
		Init_Colorization()

		'set active player again (sets correct game screen)
		GetInstance().SetActivePlayer()
	End Function


	'run when starting saving a savegame
	Function onSaveGameBeginSave(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Start saving - inform AI.", LOG_DEBUG | LOG_SAVELOAD)
		'inform player AI that we are saving now
		For local player:TPlayer = eachin GetPlayerCollection().players
			If player.figure.isAI() then player.PlayerKI.CallOnSave()
		Next
	End Function


	Method SetPaused(bool:Int=False)
		gameTime.paused = bool
	End Method


	Method GetRandomizerBase:Int()
		Return randomSeedValue
	End Method


	Method SetRandomizerBase( value:Int=0 )
		randomSeedValue = value
		'seed the random base for MERSENNE TWISTER (seedrnd for the internal one)
		SeedRand(randomSeedValue)
	End Method


	'computes daily costs like station or newsagency fees for every player
	Method ComputeDailyCosts(day:Int=-1)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			'stationfees
			Player.GetFinance().PayStationFees( Player.GetStationMap().CalculateStationCosts())
			'interest rate for your current credit
			Player.GetFinance().PayCreditInterest( Player.GetFinance().credit * TPlayerFinance.creditInterestRate )

			'newsagencyfees
			Local newsagencyfees:Int =0
			For Local i:Int = 0 To 5
				newsagencyfees:+ TNewsAgency.GetNewsAbonnementPrice( Player.newsabonnements[i] )
			Next
			Player.GetFinance(day).PayNewsAgencies((newsagencyfees))
		Next
	End Method


	'computes daily income like account interest income
	Method ComputeDailyIncome(day:Int=-1)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			if Player.GetFinance().money > 0
				Player.GetFinance().EarnBalanceInterest( Player.GetFinance().money * TPlayerFinance.balanceInterestRate )
			Else
				'attention: multiply current money * -1 to make the
				'negative value an "positive one" - a "positive expense"
				Player.GetFinance().PayDrawingCreditInterest( -1 * Player.GetFinance().money * TPlayerFinance.drawingCreditRate )
			EndIf
		Next
	End Method


	'computes penalties for expired ad-contracts
	Method ComputeContractPenalties(day:Int=-1)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			For Local Contract:TAdContract = EachIn Player.ProgrammeCollection.adContracts
				If Not contract Then Continue

				'0 days = "today", -1 days = ended
				If contract.GetDaysLeft() < 0
					Player.GetFinance(day).PayPenalty(contract.GetPenalty(), contract)
					Player.ProgrammeCollection.RemoveAdContract(contract)
				EndIf
			Next
		Next
	End Method


	'creates the default players (as shown in game-settings-screen)
	Method CreateInitialPlayers()
		'Creating PlayerColors - could also be done "automagically"
		Local playerColors:TList = TList(GetRegistry().Get("playerColors"))
		If playerColors = Null Then Throw "no playerColors found in configuration"
		For Local col:TColor = EachIn playerColors
			col.AddToList()
		Next

		'create players, draws playerfigures on figures-image
		'TColor.GetByOwner -> get first unused color,
		'TPlayer.Create sets owner of the color
		SetPlayer(1, TPlayer.Create(1, userName, userChannelName, GetSpriteFromRegistry("Player1"),	250,  2, 90, TColor.getByOwner(0), 1, "Player 1"))
		SetPlayer(2, TPlayer.Create(2, "Sandra", "SunTV", GetSpriteFromRegistry("Player2"),	280,  5, 90, TColor.getByOwner(0), 0, "Player 2"))
		SetPlayer(3, TPlayer.Create(3, "Seidi", "FunTV", GetSpriteFromRegistry("Player3"),	240,  8, 90, TColor.getByOwner(0), 0, "Player 3"))
		SetPlayer(4, TPlayer.Create(4, "Alfi", "RatTV", GetSpriteFromRegistry("Player4"),	290, 13, 90, TColor.getByOwner(0), 0, "Player 4"))
		'set different figures for other players
		GetPlayer(2).UpdateFigureBase(9)
		GetPlayer(3).UpdateFigureBase(2)
		GetPlayer(4).UpdateFigureBase(6)
	End Method


	'Things to init directly after game started
	Function onStart:Int(triggerEvent:TEventBase)
		'create 3 starting news
		If Game.IsGameLeader()
			NewsAgency.AnnounceNewNewsEvent(-60)
			NewsAgency.AnnounceNewNewsEvent(-120)
			NewsAgency.AnnounceNewNewsEvent(-120)
		EndIf
	End Function


	Method IsGameLeader:Int()
		Return (Game.networkgame And Network.isServer) Or (Not Game.networkgame)
	End Method



	Method SetGameState:Int( gamestate:Int )
		If Self.gamestate = gamestate Then Return True

		'switch to screen
		Select gamestate
			Case TGame.STATE_MAINMENU
				ScreenCollection.GoToScreen(Null,"MainMenu")
			Case TGame.STATE_SETTINGSMENU
				ScreenCollection.GoToScreen(Null,"GameSettings")
			Case TGame.STATE_NETWORKLOBBY
				ScreenCollection.GoToScreen(Null,"NetworkLobby")
			Case TGame.STATE_STARTMULTIPLAYER
				ScreenCollection.GoToScreen(Null,"StartMultiplayer")
			Case TGame.STATE_RUNNING
				ScreenCollection.GoToScreen(GameScreen_Building)
		EndSelect


		'remove focus of gui objects
		GuiManager.ResetFocus()
		GuiManager.SetKeystrokeReceiver(Null)

		'reset mouse clicks
		MouseManager.ResetKey(1)
		MouseManager.ResetKey(2)


		Self.gamestate = gamestate
		Select gamestate
			Case TGame.STATE_RUNNING
					'Begin Game - fire Events
					EventManager.registerEvent(TEventSimple.Create("Game.OnMinute", new TData.addNumber("minute", GetGameTime().GetMinute()).addNumber("hour", GetGameTime().GetHour()).addNumber("day", GetGameTime().getDay()) ))
					EventManager.registerEvent(TEventSimple.Create("Game.OnHour", new TData.addNumber("minute", GetGameTime().GetMinute()).addNumber("hour", GetGameTime().GetHour()).addNumber("day", GetGameTime().getDay()) ))
					'so we start at day "1"
					EventManager.registerEvent(TEventSimple.Create("Game.OnDay", new TData.addNumber("minute", GetGameTime().GetMinute()).addNumber("hour", GetGameTime().GetHour()).addNumber("day", GetGameTime().getDay()) ))

					'so we could add news etc.
					EventManager.triggerEvent( TEventSimple.Create("Game.OnStart") )

					TSoundManager.GetInstance().PlayMusicPlaylist("default")
			Default
				'
		EndSelect
	End Method


	'sets the player controlled by this client
	Method SetActivePlayer(ID:int=-1)
		if ID = -1 then ID = GetPlayerCollection().playerID
		'for debug purposes we need to adjust more than just
		'the playerID.
		GetPlayerCollection().playerID = ID

		'get currently shown screen of that player
		if GetPlayer().figure.inRoom
			ScreenCollection.GoToScreen(TInGameScreen_Room.GetByRoom(GetPlayer().figure.inRoom))
		'go to building
		else
			ScreenCollection.GoToScreen(GameScreen_Building)
		endif
	End Method


	Method SetPlayer:TPlayer(playerID:Int=-1, player:TPlayer)
		GetPlayerCollection().Set(playerID, player)
	End Method


	Method GetPlayer:TPlayer(playerID:Int=-1)
		return GetPlayerCollection().Get(playerID)
	End Method


	'return the maximum audience of a player
	'if no playerID was given, the average of all players is returned
	Method GetMaxAudience:Int(playerID:Int=-1)
		If Not GetPlayerCollection().isPlayer(playerID)
			Local avg:Int = 0
			For Local i:Int = 1 To 4
				avg :+ GetPlayerCollection().Get(i).GetMaxAudience()
			Next
			avg:/4
			Return avg
		EndIf
		Return GetPlayerCollection().Get(playerID).GetMaxAudience()
	End Method


	Function SendSystemMessage(message:String)
		'send out to chats
		EventManager.triggerEvent(TEventSimple.Create("chat.onAddEntry", new TData.AddNumber("senderID", -1).AddNumber("channels", CHAT_CHANNEL_SYSTEM).AddString("text", message) ) )
	End Function


	'Summary: load the config-file and set variables depending on it
	Method LoadConfig:Byte(configfile:String="config/settings.xml")
		Local xml:TxmlHelper = TxmlHelper.Create(configfile)
		If xml <> Null Then TLogger.Log("TGame.LoadConfig()", "settings.xml read", LOG_LOADING)
		Local node:TxmlNode = xml.FindRootChild("settings")
		If node = Null Or node.getName() <> "settings"
			TLogger.Log("TGame.Loadconfig()", "settings.xml misses a setting-part", LOG_LOADING | LOG_ERROR)
			Print "settings.xml fehlt der settings-Bereich"
			Return 0
		EndIf
		username			= xml.FindValue(node,"username", "Ano Nymus")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'username' fehlt, setze Defaultwert: 'Ano Nymus'", LOG_LOADING)
		userchannelname		= xml.FindValue(node,"channelname", "SunTV")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'userchannelname' fehlt, setze Defaultwert: 'SunTV'", LOG_LOADING)
		userlanguage		= xml.FindValue(node,"language", "de")			'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'language' fehlt, setze Defaultwert: 'de'", LOG_LOADING)
		userport			= xml.FindValueInt(node,"onlineport", 4444)		'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'onlineport' fehlt, setze Defaultwert: '4444'", LOG_LOADING)
		userdb				= xml.FindValue(node,"database", "res/database.xml")	'Print "settings.xml - missing 'database' - set to default: 'database.xml'"
		title				= xml.FindValue(node,"defaultgamename", "MyGame")		'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'defaultgamename' fehlt, setze Defaultwert: 'MyGame'", LOG_LOADING)
		userFallbackIP		= xml.FindValue(node,"fallbacklocalip", "192.168.0.1")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'fallbacklocalip' fehlt, setze Defaultwert: '192.168.0.1'", LOG_LOADING)
	End Method


	'Summary: Updates Time, Costs, States ...
	Method Update(deltaTime:Float=1.0)
		'==== ADJUST TIME ====
		gameTime.Update()

		'==== HANDLE TIMED EVENTS ====
		'time for news ?
		If NewsAgency.NextEventTime < gameTime.timeGone Then NewsAgency.AnnounceNewNewsEvent()
		If NewsAgency.NextChainCheckTime < gameTime.timeGone Then NewsAgency.ProcessNewsEventChains()

		'send state to clients
		If IsGameLeader() And networkgame And stateSyncTime < MilliSecs()
			NetworkHelper.SendGameState()
			stateSyncTime = MilliSecs() + stateSyncTimer
		EndIf

		'==== HANDLE IN GAME TIME ====
		'less than a ingame minute gone? nothing to do YET
		If gameTime.timeGone - gameTime.timeGoneLastUpdate < 1.0 Then Return

		'==== HANDLE GONE/SKIPPED MINUTES ====
		'if speed is to high - minutes might get skipped,
		'handle this case so nothing gets lost.
		'missedMinutes is >1 in all cases (else this part isn't run)
		Local missedMinutes:float = gameTime.timeGone - gameTime.timeGoneLastUpdate
		Local daysMissed:Int = Floor(missedMinutes / (24*60))

		'adjust the game time so GetGameTime().GetHour()/GetMinute()/... return
		'the correct value for each loop cycle. So Functions can rely on
		'that functions to get the time they request.
		'as everything can get calculated using "timeGone", no further
		'adjustments have to take place
		gameTime.timeGone:- missedMinutes
		For Local i:Int = 1 to missedMinutes
			'add back another gone minute each loop
			gameTime.timeGone:+1

			'day
			If gameTime.GetHour() = 0 And gameTime.GetMinute() = 0
				'increase current day
				gameTime.daysPlayed :+1
			 	'automatically change current-plan-day on day change
			 	'but do it silently (without affecting the)
			 	RoomHandler_Office.ChangePlanningDay(gameTime.GetDay())

				EventManager.triggerEvent(TEventSimple.Create("Game.OnDay", new TData.addNumber("minute", gameTime.GetMinute()).addNumber("hour", gameTime.GetHour()).addNumber("day", gameTime.GetDay()) ))
			EndIf

			'hour
			If gameTime.GetMinute() = 0
				EventManager.triggerEvent(TEventSimple.Create("Game.OnHour", new TData.addNumber("minute", gameTime.GetMinute()).addNumber("hour", gameTime.GetHour()).addNumber("day", gameTime.GetDay()) ))
			endif

			'minute
			EventManager.triggerEvent(TEventSimple.Create("Game.OnMinute", new TData.addNumber("minute", gameTime.GetMinute()).addNumber("hour", gameTime.GetHour()).addNumber("day", gameTime.GetDay()) ))
		Next

		'reset gone time so next update can calculate missed minutes
		gameTime.timeGoneLastUpdate = gameTime.timeGone
	End Method
End Type