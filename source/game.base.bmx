
'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame {_exposeToLua="selected"}
	Field debugAudienceInfo:TDebugAudienceInfos = new TDebugAudienceInfos

	'===== GAME STATES =====
	Const STATE_RUNNING:Int			= 0
	Const STATE_MAINMENU:Int		= 1
	Const STATE_NETWORKLOBBY:Int	= 2
	Const STATE_SETTINGSMENU:Int	= 3
	'mode when data gets synchronized or initialized
	Const STATE_PREPAREGAMESTART:Int= 4

	'===== GAME SETTINGS =====
	'used so that random values are the same on all computers having the same seed value
	Field randomSeedValue:Int = 0

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
	Global userStartYear:int = 1985
	Global userFallbackIP:String = ""

	'title of the game
	Field title:String = "MyGame"

	'which cursor has to be shown? 0=normal 1=dragging
	Field cursorstate:Int = 0
	'0 = Mainmenu, 1=Running, ...
	Field gamestate:Int = -1

	Field nextXRatedCheckMinute:Int = -1

	'last sync
	Field stateSyncTime:Int	= 0
	'sync every
	Field stateSyncTimer:Int = 2000
	'the last moment a realtime second was gone
	Field lastTimeRealTimeSecondGone:Int = 0
	'last moment a WorlTime-"minute" was gone (for missed minutes)
	Field lastTimeMinuteGone:Double = 0

	'refill movie agency every X Minutes
	Field refillMovieAgencyTimer:Int = 180
	'minutes till movie agency gets refilled again
	Field refillMovieAgencyTime:Int = 180

	'refill ad agency every X Minutes
	Field refillAdAgencyTimer:Int = 240
	'minutes till ad agency gets refilled again
	Field refillAdAgencyTime:Int = 240
	'refill completely on next refill run?
	Field refillAdAgencyPercentage:Float = 0.5
	Field refillAdAgencyOverridePercentage:Float = 0.5


	'--networkgame auf "isNetworkGame()" umbauen
	'are we playing a network game? 0=false, 1=true, 2
	Field networkgame:Int = 0
	'start the game now?
	Field startNetworkGame:Int = 0
	'playing over internet? 0=false
	Field onlinegame:Int = 0

	Field terrorists:TFigureTerrorist[2]
	Field marshals:TFigureMarshal[2]  

	Global _instance:TGame
	Global _initDone:int = FALSE
	'was "PrepareFirstGameStart" run already?
	Global _firstGamePreparationDone:int = FALSE
	Global StartTipWindow:TGUIModalWindow


	Method New()
		if not _initDone
			'handle begin of savegameloading (prepare first game if needed)
			EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			EventManager.registerListenerFunction("SaveGame.OnBeginSave", onSaveGameBeginSave)

			_initDone = TRUE
		Endif
	End Method


	Function GetInstance:TGame()
		if not _instance then _instance = new TGame
		return _instance
	End Function


	'Summary: create a game, every variable is set to Zero
	Method Create:TGame(initializePlayer:Int = true, initializeRoom:Int = true)
		LoadConfig(App.config)

		'load all localizations
		TLocalization.LoadLanguageFiles("res/lang/lang_*.txt")
		'set default language
		TLocalization.SetCurrentLanguage("en")
		'select user language
		TLocalization.SetCurrentLanguage(userlanguage)

		networkgame = 0

		'MAD TV speed:
		'slow:   10 game minutes = 30 seconds  -> 1 sec = 20 ingameseconds
		'middle: 10 game minutes = 20 seconds  -> 1 sec = 30 ingameseconds
		'fast:   10 game minutes = 10 seconds  -> 1 sec = 60 ingameseconds

		'set basic game speed to 30 gameseconds per second
		GetWorldTime().SetTimeFactor(30.0)
		'set start year
		GetWorldTime().SetStartYear(userStartYear)
		title = "unknown"

		SetRandomizerBase( Time.MillisecsLong() )

		If initializePlayer Then CreateInitialPlayers()

		'creates all Rooms - with the names assigned at this moment
'		If initializeRoom Then Init_CreateAllRooms()

		Return self
	End Method



	Method InitWorld()
		local appConfig:TData = GetDataFromRegistry("appConfig", new TData)
		local worldConfig:TData = TData(appConfig.Get("worldConfig", New TData))

		GetWorld().Init(1*3600)
		GetWorld().SetConfiguration(worldConfig)
	End Method


	Method InitWorldWeatherEffects()
		local world:TWorld = GetWorld()

		'we draw them in front of the background buildings
		world.autoRenderSnow = False
		world.autoRenderRain = False
		
		'=== SETUP WORLD ===
		'1. SKY SPRITES
		World.InitSky(..
			GetSpriteFromRegistry("gfx_world_sky_gradient"), ..
			GetSpriteFromRegistry("gfx_world_sky_moon"), ..
			GetSpriteFromRegistry("gfx_world_sky_sun"), ..
			GetSpriteFromRegistry("gfx_world_sky_sunrays") ..
		)
		'2. SETUP RAIN
		World.InitRainEffect(2, GetSpriteGroupFromRegistry("gfx_world_sky_rain"))
		'3. SETUP SNOW
		World.InitSnowEffect(20, GetSpriteGroupFromRegistry("gfx_world_sky_snow"))
		'4. SETUP LIGHTNING
		World.InitLightningEffect(GetSpriteGroupFromRegistry("gfx_world_sky_lightning"), GetSpriteGroupFromRegistry("gfx_world_sky_lightning_side"))
		'5. SETUP CLOUDS
		World.InitCloudEffect(50, GetSpriteGroupFromRegistry("gfx_world_sky_clouds"))
		World.cloudEffect.Start() 'clouds from begin
	End Method
	

	'run this before EACH started game
	Method PrepareStart(startNewGame:int)
		'=== FIRST GAME ===
		'if no game run before : prepare something more
		if not _firstGamePreparationDone then PrepareFirstGameStart()

		'=== ALL GAMES ===
		TLogger.Log("Game.PrepareStart()", "colorizing images corresponding to playercolors", LOG_DEBUG)
		ColorizePlayerExtras()

		TLogger.Log("Game.PrepareStart()", "drawing doors, plants and lights on the building-sprite", LOG_DEBUG)
		'also registers events...
		GetBuilding().Init()

		'(re-)inits weather effects (raindrops, snow flakes etc)
		InitWorldWeatherEffects()

		'=== NEW GAMES ===
		'new games need some initializations (database etc.)
		if startNewGame then PrepareNewGame()
	End Method


	'run this BEFORE the first game is started
	Function PrepareFirstGameStart:int()
		if _firstGamePreparationDone then return False

		Game.InitWorld()

		'create rooms and connect handlers
		Init_CreateAllRooms()

		GetPopularityManager().Initialize()
		GetBroadcastManager().Initialize()


		'=== START TIPS ===
		'maybe show this window each game? or only on game start or ... ?
		local showStartTips:int = FALSE
		if showStartTips then CreateStartTips()


		'=== GUI SETUP ===
		'TLogger.Log("TGame", "Creating ingame GUIelements", LOG_DEBUG)
		InGame_Chat = New TGUIChat.Create(new TVec2D.Init(520, 418), new TVec2D.Init(280,190), "InGame")
		InGame_Chat.setDefaultHideEntryTime(10000)
		InGame_Chat.guiList.backgroundColor = TColor.Create(0,0,0,0.2)
		InGame_Chat.guiList.backgroundColorHovered = TColor.Create(0,0,0,0.7)
		InGame_Chat.setOption(GUI_OBJECT_CLICKABLE, False)
		InGame_Chat.SetDefaultTextColor( TColor.Create(255,255,255) )
		InGame_Chat.guiList.autoHideScroller = True
		'remove unneeded elements
		InGame_Chat.SetBackground(null)


		'reposition input
		InGame_Chat.guiInput.rect.position.setXY( 275, 387)
		InGame_Chat.guiInput.setMaxLength(200)
		InGame_Chat.guiInput.setOption(GUI_OBJECT_POSITIONABSOLUTE, True)
		InGame_Chat.guiInput.maxTextWidth = 200
		InGame_Chat.guiInput.spriteName = "Chat_IngameOverlay"
		InGame_Chat.guiInput.color.AdjustRGB(255,255,255,True)
		InGame_Chat.guiInput.SetValueDisplacement(0,5)


		'===== EVENTS =====
		EventManager.registerListenerFunction("Game.OnDay", 	GameEvents.OnDay )
		EventManager.registerListenerFunction("Game.OnHour", 	GameEvents.OnHour )
		EventManager.registerListenerFunction("Game.OnMinute",	GameEvents.OnMinute )
		EventManager.registerListenerFunction("Game.OnStart",	TGame.onStart )


		'Game screens
		GameScreen_World = New TInGameScreen_World.Create("InGame_World")
		ScreenCollection.Add(GameScreen_World)

		PlayerDetailsTimer = 0

		'=== SETUP TOOLTIPS ===
		TTooltip.UseFontBold = GetBitmapFontManager().baseFontBold
		TTooltip.UseFont = GetBitmapFontManager().baseFont
		TTooltip.ToolTipIcons = GetSpriteFromRegistry("gfx_building_tooltips")
		TTooltip.TooltipHeader = GetSpriteFromRegistry("gfx_tooltip_header")


		'=== REGISTER GENERIC EVENTS ===
		GameEvents.RegisterEventListeners()
		
		'init finished
		_firstGamePreparationDone = True
	End Function


	Function CreateStartTips:int()
		TLogger.Log("TGame", "Creating start tip GUIelement", LOG_DEBUG)
		Local StartTips:TList = CreateList()
		Local tipNumber:int = 1
		'repeat as long there is a localization available
		While GetLocale("STARTHINT_TITLE"+tipNumber) <> "STARTHINT_TITLE"+tipNumber
			StartTips.addLast( [GetLocale("HINT")+ ": "+GetLocale("STARTHINT_TITLE"+tipNumber), GetLocale("STARTHINT_TEXT"+tipNumber)] )
			tipNumber :+ 1
		Wend

		if StartTips.count() > 0
			local tipNumber:int = rand(0, StartTips.count()-1)
			local tip:string[] = string[](StartTips.valueAtIndex(tipNumber))

			StartTipWindow = new TGUIGameModalWindow.Create(new TVec2D, new TVec2D.Init(400,350), "InGame")
			StartTipWindow.screenArea = new TRectangle.Init(0,0,800,385)
			StartTipWindow.DarkenedArea = new TRectangle.Init(0,0,800,385)
			StartTipWindow.SetCaptionAndValue( tip[0], tip[1] )
		endif
	End Function


	Method PrepareNewGame:int()
		'=== RESET VALUES ===
		new TGameState.Initialize()


		'=== LOAD DATABASES ===
		'load all movies, news, series and ad-contracts
		'do this here, as saved games already contain the database
		TLogger.Log("Game.PrepareNewGame()", "loading database", LOG_DEBUG)
		LoadDatabase(userDBDir)


		'=== FIGURES ===
		'set all non human players to AI
		If Game.isGameLeader()
			For Local id:Int = 1 To 4
				If GetPlayer(id).IsLocalAI()
					GetPlayer(id).InitAI("res/ai/DefaultAIPlayer.lua")
				EndIf
			Next
		EndIf


		'move all figures to offscreen, and set their target to their
		'offices (for now just to the "floor", later maybe to the boss)
		For local i:int = 1 to 4
			GetPlayer(i).GetFigure().MoveToOffscreen()
			GetPlayer(i).GetFigure().area.position.x :+ i*3 + (i mod 2)*15
			'forcefully send (no controlling possible until reaching the target)
			'GetPlayer(i).GetFigure().SendToDoor( TRoomDoor.GetByDetails("office", i), True)
			GetPlayer(i).GetFigure().ForceChangeTarget(TRoomDoor.GetByDetails("news", i).area.GetX() + 60, TRoomDoor.GetByDetails("news", i).area.GetY())
		Next
'debug
'		GetPlayer(1).GetFigure().area.position.SetXY(TRoomDoor.GetByDetails("news", 1).area.GetX() + 60, TRoomDoor.GetByDetails("news", 1).area.GetY())

		'also create/move other figures of the building
		'all of them are created at "offscreen position"
		local fig:TFigure = GetFigureCollection().GetByName("Hausmeister")
		if not fig then fig = New TFigureJanitor.Create("Hausmeister", GetSpriteFromRegistry("janitor"), GameRules.offscreenX, 0, 65)
		fig.MoveToOffscreen()
		fig.SetParent(GetBuilding().buildingInner)
		fig.SendToDoor(TRoomDoor.GetByDetails("supermarket",-1), True)

		fig = GetFigureCollection().GetByName("Bote1")
		if not fig then fig = New TFigurePostman.Create("Bote1", GetSpriteFromRegistry("BoteLeer"), GameRules.offscreenX - 90, 0, 65)
		fig.MoveToOffscreen()
		fig.SetParent(GetBuilding().buildingInner)
		fig.SendToDoor(TRoomDoor.GetByDetails("boss", 1), True)

		fig = GetFigureCollection().GetByName("Bote2")
		if not fig then fig = New TFigurePostman.Create("Bote2", GetSpriteFromRegistry("BoteLeer"), GameRules.offscreenX -60, 0, -65)
		fig.MoveToOffscreen()
		fig.SetParent(GetBuilding().buildingInner)
		fig.SendToDoor(TRoomDoor.GetByDetails("boss", 3), True)


		'create 2 terrorists
		For local i:int = 0 to 1
			terrorists[i] = TFigureTerrorist(GetFigureCollection().GetByName("Terrorist"+(i+1)))
			if not terrorists[i]
				terrorists[i] = New TFigureTerrorist
				terrorists[i].Create("Terrorist"+(i+1), GetSpriteFromRegistry("Terrorist"+(i+1)), GameRules.offscreenX, 0, 65)
			endif
			terrorists[i].MoveToOffscreen()
			terrorists[i].SetParent(GetBuilding().buildingInner)
		Next

		'create 2 marshals (to confiscate different things we use
		'multiple marshals)
		For local i:int = 0 to 1
			marshals[i] = TFigureMarshal(GetFigureCollection().GetByName("Marshal"+(i+1)))
			if not marshals[i]
				marshals[i] = New TFigureMarshal
				marshals[i].Create("Marshal"+(i+1), GetSpriteFromRegistry("Marshal"+(i+1)), GameRules.offscreenX, 0, 65)
			endif
			marshals[i].MoveToOffscreen()
			marshals[i].SetParent(GetBuilding().buildingInner)
		Next

		'we want all players to alreay wait in front of the elevator
		'and not only 1 player sending it while all others wait
		'so we move the elevator to a higher floor, so it just
		'reaches floor 0 when all are already waiting
		'floor 9 is just enough for the players
		TElevator._instance.currentFloor = 9


		'=== ADJUST GAME RULES ===
		GameRules.dailyBossVisit = GameRules.devConfig.GetInt("DEV_DAILY_BOSS_VISIT", TRUE)


		'=== STATION MAP ===
		'load the used map
		GetStationMapCollection().LoadMapFromXML("res/maps/germany.xml")

		'create base stations
		For Local i:Int = 1 To 4
			'add new station
			GetPlayerCollection().Get(i).GetStationMap().AddStation( TStation.Create( new TVec2D.Init(310, 260),-1, GetStationMapCollection().stationRadius, i ), False )
		Next

		'update the collection so it contains the audience reach of each player
		GetStationMapCollection().Update()


		'get names from settings
		For Local i:Int = 1 To 4
			GetPlayerCollection().Get(i).Name = ScreenGameSettings.guiPlayerNames[i-1].Value
			GetPlayerCollection().Get(i).channelname = ScreenGameSettings.guiChannelNames[i-1].Value
		Next


		'create series/movies in movie agency
		RoomHandler_MovieAgency.GetInstance().ReFillBlocks()

		'8 auctionable movies/series
		For Local i:Int = 0 To 7
			New TAuctionProgrammeBlocks.Create(i, Null)
		Next


		'give each player some programme
		SpreadStartProgramme()


		'=== SETUP NEWS + ABONNEMENTS ===
		'adjust abonnement for each newsgroup to 1
		For Local playerids:Int = 1 To 4
			'For Local i:Int = 0 To 4 '5 groups
			'	GetPlayerCollection().Get(playerids).SetNewsAbonnement(i, 1)
			'Next

			'only have abonnement for currents
			GetPlayerCollection().Get(playerids).SetNewsAbonnement(4, 1)
		Next

		'create 3 starting news, True = add even without news abonnement
		GetNewsAgency().AnnounceNewNewsEvent(-60, True)
		GetNewsAgency().AnnounceNewNewsEvent(-120, True)
		GetNewsAgency().AnnounceNewNewsEvent(-120, True)
		'adjust news agency to wait some time until next news
		GetNewsAgency().ResetNextEventTime()

		'place them into the players news shows
		local newsToPlace:TNews
		For Local playerID:int = 1 to 4
			For local i:int = 0 to 2
				'attention: instead of using "GetNewsAtIndex(i)" we always
				'use (0) - as each "placed" news is removed from the collection
				'leaving the next on listIndex 0
				newsToPlace = GetPlayerProgrammeCollectionCollection().Get(playerID).GetNewsAtIndex(0)
				if not newsToPlace
					'throw "Game.PrepareNewGame: initial news " + i + " missing."
					continue
				endif
				'set it paid - so money does not change
				newsToPlace.paid = true
				'calculate paid Price of the news
				newsToPlace.Pay()
				'set planned
				GetPlayerProgrammePlanCollection().Get(playerID).SetNews(newsToPlace, i)
			Next
		Next



		'=== SETUP START PROGRAMME PLAN ===

		Local lastblocks:Int=0
		local playerCollection:TPlayerProgrammeCollection
		Local playerPlan:TPlayerProgrammePlan

		'creation of blocks for players rooms
		For Local playerids:Int = 1 To 4
			lastblocks = 0
			playerCollection = GetPlayerProgrammeCollectionCollection().Get(playerids)
			playerPlan = GetPlayerProgrammePlanCollection().Get(playerids)

			SortList(playerCollection.adContracts)

			Local addWidth:Int = GetSpriteFromRegistry("pp_programmeblock1").area.GetW()
			Local addHeight:Int = GetSpriteFromRegistry("pp_adblock1").area.GetH()

			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetWorldTime().GetStartDay(), 0 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetWorldTime().GetStartDay(), 1 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetWorldTime().GetStartDay(), 2 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetWorldTime().GetStartDay(), 3 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetWorldTime().GetStartDay(), 4 )
			playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetWorldTime().GetStartDay(), 5 )

			Local currentLicence:TProgrammeLicence = Null
			Local currentHour:Int = 0
			For Local i:Int = 0 To 3
				currentLicence = playerCollection.GetMovieLicenceAtIndex(i)
				If Not currentLicence Then Continue
				playerPlan.SetProgrammeSlot(TProgramme.Create(currentLicence), GetWorldTime().GetStartDay(), currentHour )
				currentHour:+ currentLicence.getData().getBlocks()
			Next
		Next


		'=== SETUP INTERFACE ===
		
		'switch active TV channel to player
		GetInGameInterface().ShowChannel = GetPlayerCollection().playerID
	End Method


	Method SpreadStartProgramme:int()
		local filterCallIn:TProgrammeLicenceFilter = new TProgrammeLicenceFilter
		filterCallIn.AddFlag(TProgrammeData.FLAG_PAID)

		'all players get the same adContractBase (but of course another
		'contract for each of them)
		local adContractBases:TAdContractBase[]
		local cheapFilter:TAdContractBaseFilter = new TAdContractbaseFilter
		'some easy ones
		cheapFilter.SetAudience(0.0, 0.01)
		'only without image requirements? not needed for start programme
		'you might have luck to get a better paid one :D
		'cheapFilter.SetImage(0.0, 0.0)
		'do not allow limited ones
		cheapFilter.SetSkipLimitedToProgrammeGenre()
		cheapFilter.SetSkipLimitedToTargetGroup()
		For Local i:int = 0 to 1
			adContractBases :+ [GetAdContractBaseCollection().GetRandomByFilter(cheapFilter)]
		Next
		'and one with 0 audience requirement
		cheapFilter.SetAudience(0.0, 0.0)
		adContractBases :+ [GetAdContractBaseCollection().GetRandomByFilter(cheapFilter)]

		
		For Local playerids:Int = 1 To 4
			Local ProgrammeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollectionCollection().Get(playerids)
			For Local i:Int = 0 until GameRules.startMovieAmount
				ProgrammeCollection.AddProgrammeLicence(GetProgrammeLicenceCollection().GetRandom(TProgrammeData.TYPE_MOVIE))
			Next
			'give series to each player
			For Local i:Int = GameRules.startMovieAmount until GameRules.startMovieAmount + GameRules.startSeriesAmount
				ProgrammeCollection.AddProgrammeLicence(GetProgrammeLicenceCollection().GetRandom(TProgrammeData.TYPE_SERIES))
			Next
			'give 1 call in
			ProgrammeCollection.AddProgrammeLicence(GetProgrammeLicenceCollection().GetRandomByFilter(filterCallIn))

			'create contracts out of the preselected adcontractbases
			For local adContractBase:TAdContractBase = EachIn adContractBases
				ProgrammeCollection.AddAdContract(New TAdContract.Create(adContractBase))
			Next
		Next
	End Method


	Method StartNewGame:int()
		_Start(True)
	End Method


	Method StartLoadedSaveGame:int()
		PrepareStart(False)
		_Start(False)
	End Method


	'run when a specific game starts
	Method _Start:int(startNewGame:int = TRUE)
		'disable chat if not networkgaming
		If Not game.networkgame
			InGame_Chat.hide()
		Else
			InGame_Chat.show()
		EndIf


		'set force=true so the gamestate is set even if already in this
		'state (eg. when loaded)
		Game.SetGamestate(TGame.STATE_RUNNING, TRUE)


		if startNewGame
			'Begin Game - fire Events
			EventManager.registerEvent(TEventSimple.Create("Game.OnMinute", new TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().getDay()) ))
			EventManager.registerEvent(TEventSimple.Create("Game.OnHour", new TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().getDay()) ))
			'so we start at day "1"
			EventManager.registerEvent(TEventSimple.Create("Game.OnDay", new TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().getDay()) ))
		EndIf
	End Method


	'run when loading starts
	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'if not done yet: run preparation for first game
		'(eg. if loading is done from mainmenu)
		PrepareFirstGameStart()
	End Function


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Savegame loaded - reinit weather effects.", LOG_DEBUG | LOG_SAVELOAD)
		GetInstance().InitWorldWeatherEffects()


		TLogger.Log("TGame", "Savegame loaded - colorize players.", LOG_DEBUG | LOG_SAVELOAD)
		'reconnect AI and other things
		For local player:TPlayer = eachin GetPlayerCollection().players
			player.onLoad(null)
		Next

		'set active player again (sets correct game screen)
		GetInstance().SetActivePlayer()
	End Function


	'run when starting saving a savegame
	Function onSaveGameBeginSave(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Start saving - inform AI.", LOG_DEBUG | LOG_SAVELOAD)
		'inform player AI that we are saving now
		For local player:TPlayer = eachin GetPlayerCollection().players
			If player.isLocalAI() then player.PlayerAI.CallOnSave()
		Next
	End Function


	Method SetPaused(bool:Int=False)
		GetWorldTime().SetPaused(bool)
	End Method


	Method GetRandomizerBase:Int()
		Return randomSeedValue
	End Method


	Method SetRandomizerBase( value:Int=0 )
		randomSeedValue = value
		'seed the random base for MERSENNE TWISTER (seedrnd for the internal one)
		SeedRand(randomSeedValue)
	End Method


	Method ComputeNextXRatedCheckMinute()
		'do not use the timeslots 50-54 ... maybe thats too late?
		'-9 till 0 are "no check"
		nextXRatedCheckMinute = RandRange(-9, 49)
		if nextXRatedCheckMinute <= 0 then nextXRatedCheckMinute = -1
	End Method


	Method GetNextXRatedCheckMinute:int()
		return nextXRatedCheckMinute
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
			For Local Contract:TAdContract = EachIn Player.GetProgrammeCollection().adContracts
				If Not contract Then Continue

				'0 days = "today", -1 days = ended
				If contract.GetDaysLeft() < 0
					'inform contract
					contract.Fail(GetWorldTime().MakeTime(0, day, 0, 0))
					'remove
					Player.GetProgrammeCollection().RemoveAdContract(contract)
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
			col.AddToList(True) 'true = try to remove them at first
		Next

		'create players, draws playerfigures on figures-image
		'TColor.GetByOwner -> get first unused color,
		'TPlayer.Create sets owner of the color
		SetPlayer(1, TPlayer.Create(1, userName, userChannelName, GetSpriteFromRegistry("Player1"),	150,  2, 90, TColor.getByOwner(0), "Player 1"))
		SetPlayer(2, TPlayer.Create(2, "Sandra", "SunTV", GetSpriteFromRegistry("Player2"),	180,  5, 90, TColor.getByOwner(0), "Player 2"))
		SetPlayer(3, TPlayer.Create(3, "Seidi", "FunTV", GetSpriteFromRegistry("Player3"),	140,  8, 90, TColor.getByOwner(0), "Player 3"))
		SetPlayer(4, TPlayer.Create(4, "Alfi", "RatTV", GetSpriteFromRegistry("Player4"),	190, 13, 90, TColor.getByOwner(0), "Player 4"))

		'set different figures for other players
		GetPlayer(2).UpdateFigureBase(9)
		GetPlayer(3).UpdateFigureBase(2)
		GetPlayer(4).UpdateFigureBase(6)

		'by default all other players are "AI" and handled by local player
		GetPlayer(2).SetLocalAIControlled()
		GetPlayer(3).SetLocalAIControlled()
		GetPlayer(4).SetLocalAIControlled()
	End Method


	'Things to init directly after game started
	Function onStart:Int(triggerEvent:TEventBase)
	End Function


	Method IsGameLeader:Int()
		Return (Game.networkgame And Network.isServer) Or (Not Game.networkgame)
	End Method


	Method IsControllingPlayer:Int(playerID:int)
		if not GetPlayer(playerID) then return False
		
		if not networkgame
			return TRUE
		else
			'it's me
			if GetPlayerCollection().isLocalPlayer(playerID) then return True
			'it's an AI player and I am the master
			if GetPlayer(playerID).IsLocalAI() and IsGameLeader() then return True
			return False
		endif 
	End Method



	Method SetGameState:Int(gamestate:Int, force:int=False )
		If Self.gamestate = gamestate and not force Then Return True

		'switch to screen
		Select gamestate
			Case TGame.STATE_MAINMENU
				ScreenCollection.GoToScreen(Null,"MainMenu")
			Case TGame.STATE_SETTINGSMENU
				ScreenCollection.GoToScreen(Null,"GameSettings")
			Case TGame.STATE_NETWORKLOBBY
				ScreenCollection.GoToScreen(Null,"NetworkLobby")
			Case TGame.STATE_PREPAREGAMESTART
				ScreenCollection.GoToScreen(Null,"PrepareGameStart")
			Case TGame.STATE_RUNNING
				'when a game is loaded we should try set the right screen
				'not just the default building screen
				if GetPlayerCollection().Get().GetFigure().inRoom
					ScreenCollection.GoToScreen(ScreenCollection.GetCurrentScreen())
				else
					ScreenCollection.GoToScreen(GameScreen_world)
				endif
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
		'also set this information for the boss collection (avoids
		'circular references)
		GetPlayerBossCollection().playerID = ID

		'get currently shown screen of that player
		if GetPlayer().GetFigure().inRoom
			ScreenCollection.GoToScreen(TInGameScreen_Room.GetByRoom(GetPlayer().GetFigure().inRoom))
		'go to building
		else
			ScreenCollection.GoToScreen(GameScreen_World)
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


	'Summary: load config from the app config data and set variables
	'depending on it
	Method LoadConfig:int(config:TData)
		username = config.GetString("playername", "Player")
		userchannelname = config.GetString("channelname", "My Channel")
		userlanguage = config.GetString("language", "de")
		userStartYear = config.GetInt("startyear", 1985)
		userport = config.GetInt("onlineport", 4444)
		userDBDir = config.GetString("databaseDir", "res/database/Default")
		title = config.GetString("gamename", "New Game")
		userFallbackIP = config.GetString("fallbacklocalip", "192.168.0.1")
	End Method


	'Summary: Updates Time, Costs, States ...
	Method Update(deltaTime:Float=1.0)
		local worldTime:TWorldTime = GetWorldTime()
		'==== ADJUST TIME ====
		worldTime.Update()

		'==== UPDATE WORLD ===
		'only update weather as it affects news etc.
		'lighting/effects are only updated when figure is outside of a
		'room (updateWeather is skipping processing if done just moments
		'ago)
		GetWorld().UpdateWeather()


		'==== CHECK BOMBS ====
		'this triggers potential bombs
		for local room:TRoom = eachin GetRoomCollection().list
			room.CheckForBomb()
		next

		'send state to clients
		If IsGameLeader() And networkgame And stateSyncTime < Time.GetTimeGone()
			NetworkHelper.SendGameState()
			stateSyncTime = Time.GetTimeGone() + stateSyncTimer
		EndIf


		'=== REALTIME GONE CHECK ===
		'checks if at least 1 second is gone since the last call
		if lastTimeRealTimeSecondGone = 0 then lastTimeRealTimeSecondGone = Time.GetTimeGone()
		if Time.GetTimeGone() - lastTimeRealTimeSecondGone > 1000
			'event passes milliseconds gone since last call
			'so if hickups made the game stop for 4.3 seconds, this value
			'will be about 4300. Maybe AI wants this information.
			EventManager.triggerEvent(TEventSimple.Create("Time.OnSecond", new TData.addNumber("timeGone", Time.GetTimeGone()-lastTimeRealTimeSecondGone)))
			lastTimeRealTimeSecondGone = Time.GetTimeGone()
		endif


		
		'init if not done yet
		if lastTimeMinuteGone = 0 then lastTimeMinuteGone = worldTime.GetTimeGone()

		'==== HANDLE IN GAME TIME ====
		'less than a ingame minute gone? nothing to do YET
		If worldTime.GetTimeGone() - lastTimeMinuteGone < 60.0 Then Return

		'==== HANDLE GONE/SKIPPED MINUTES ====
		'if speed is to high - minutes might get skipped,
		'handle this case so nothing gets lost.
		'missedMinutes is >1 in all cases (else this part isn't run)
		Local missedSeconds:float = (worldTime.GetTimeGone() - lastTimeMinuteGone)
		Local missedMinutes:float = missedSeconds/60.0
		Local daysMissed:Int = Floor(missedMinutes / (24*60))

		'adjust the game time so GetWorldTime().GetDayHour()/Minute/...
		'return the correct value for each loop cycle. So Functions can
		'rely on that functions to get the time they request.
		'as everything can get calculated using "timeGone", no further
		'adjustments have to take place
		worldTime._timeGone:- missedSeconds

		For Local i:Int = 1 to missedMinutes
			'add back another gone minute each loop
			worldTime._timeGone :+ 60
			 
			'day
			If worldTime.GetDayHour() = 0 And worldTime.GetDayMinute() = 0
				'year
				If worldTime.GetDayOfYear() = 0
					EventManager.triggerEvent(TEventSimple.Create("Game.OnYear", new TData.addNumber("minute", worldTime.GetDayMinute()).addNumber("hour", worldTime.GetDayHour()).addNumber("day", worldTime.GetDay()) ))

					'reset availableNewsEventList - maybe this is a year
					'with some more news
					GetNewsEventCollection().RefreshAvailable()
				EndIf

			 	'automatically change current-plan-day on day change
			 	'but do it silently (without affecting the)
			 	RoomHandler_Office.ChangePlanningDay(worldTime.GetDay())

				EventManager.triggerEvent(TEventSimple.Create("Game.OnDay", new TData.addNumber("minute", worldTime.GetDayMinute()).addNumber("hour", worldTime.GetDayHour()).addNumber("day", worldTime.GetDay()) ))
			EndIf

			'hour
			If worldTime.GetDayMinute() = 0
				EventManager.triggerEvent(TEventSimple.Create("Game.OnHour", new TData.addNumber("minute", worldTime.GetDayMinute()).addNumber("hour", worldTime.GetDayHour()).addNumber("day", worldTime.GetDay()) ))
			endif

			'minute
			EventManager.triggerEvent(TEventSimple.Create("Game.OnMinute", new TData.addNumber("minute", worldTime.GetDayMinute()).addNumber("hour", worldTime.GetDayHour()).addNumber("day", worldTime.GetDay()) ))
		Next

		'reset time of lst minute so next update can calculate missed minutes
		lastTimeMinuteGone = worldTime.GetTimeGone()
	End Method
End Type