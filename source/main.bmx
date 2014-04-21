'Application: TVGigant/TVTower
'Author: Ronny Otto & Manuel Vögele

SuperStrict

Import brl.timer
Import brl.Graphics
Import "basefunctions_network.bmx"
Import "basefunctions.bmx"						'Base-functions for Color, Image, Localization, XML ...
Import "basefunctions_sound.bmx"
Import "basefunctions_guielements.bmx"			'Guielements like Input, Listbox, Button...
Import "basefunctions_events.bmx"				'event handler
Import "basefunctions_deltatimer.bmx"
Import "basefunctions_lua.bmx"					'our lua engine
Import "basefunctions_resourcemanager.bmx"
Import "basefunctions_screens.bmx"

?Linux
Import "external/bufferedglmax2d/bufferedglmax2d.bmx"
?Win32
Import brl.D3D9Max2D
Import brl.D3D7Max2D
?Threaded
Import brl.Threads
?

'===== Includes =====
Include "gamefunctions.bmx" 					'Types: - TError - Errorwindows with handling
												'		- base class For buttons And extension newsbutton
												'		- stationmap-handling, -creation ...
Include "game.stationmap.bmx"
Include "gamefunctions_betty.bmx"
Include "gamefunctions_screens.bmx"
Include "gamefunctions_tvprogramme.bmx"  		'contains structures for TV-programme-data/Blocks and dnd-objects
Include "gamefunctions_rooms.bmx"				'basic roomtypes with handling
Include "gamefunctions_ki.bmx"					'LUA connection
Include "gamefunctions_sound.bmx"				'TVTower spezifische Sounddefinitionen
Include "gamefunctions_popularity.bmx"			'Popularitäten und Trends
Include "gamefunctions_genre.bmx"				'Genre-Definitionen
Include "gamefunctions_broadcast.bmx"				'Quotenberechnung
Include "gamefunctions_people.bmx"				'Angestellte und Personen
Include "gamefunctions_publicimage.bmx"			'Das SenderImage
Include "gamefunctions_production.bmx"			'Alles was mit Filmproduktion zu tun hat
Include "gamefunctions_debug.bmx"
Include "gamefunctions_network.bmx"

Include "game.player.bmx"
Include "game.playerfinance.bmx"
Include "gamefunctions_elevator.bmx"
Include "gamefunctions_figures.bmx"
Include "game.building.bmx"
Include "game.newsagency.bmx"

'===== Globals =====
Global VersionDate:String		= LoadText("incbin::source/version.txt")
Global VersionString:String		= "version of " + VersionDate
Global CopyrightString:String	= "by Ronny Otto & Manuel Vögele"
Global App:TApp = null
Global ArchiveProgrammeList:TgfxProgrammelist
Global SaveError:TError
Global LoadError:TError
Global NewsAgency:TNewsAgency
Global Interface:TInterface		= null
Global Game:TGame	  			= null
Global Building:TBuilding		= null
Global InGame_Chat:TGUIChat		= null
Global PlayerDetailsTimer:Int = 0
Global MainMenuJanitor:TFigureJanitor
Global ScreenGameSettings:TScreen_GameSettings = null
Global GameScreen_Building:TInGameScreen_Building = null
Global LogoTargetY:Float = 20
Global LogoCurrY:Float = 100
Global headerFont:TGW_BitmapFont
Global Curves:TNumberCurve = TNumberCurve.Create(1, 200)
Global Init_Complete:Int = 0
Global RefreshInput:Int = True
?Threaded
Global RefreshInputMutex:TMutex = CreateMutex()
?

'==== Initialize ====
AppTitle = "TVTower: " + VersionString + " " + CopyrightString
TDevHelper.Log("CORE", "Starting TVTower, "+VersionString+".", LOG_INFO )

'===== SETUP LOGGER FILTER =====
TDevHelper.setLogMode(LOG_ALL)
TDevHelper.setPrintMode(LOG_ALL ) 'all but ai

'print "ALLE MELDUNGEN AUS"
'TDevHelper.SetPrintMode(0)

'TDevHelper.setPrintMode(LOG_ALL &~ LOG_AI ) 'all but ai
'THIS IS TO REMOVE CLUTTER FOR NON-DEVS
'@MANUEL: comment out when doing DEV to see LOG_DEV-messages
'TDevHelper.changePrintMode(LOG_DEV, FALSE)






'Enthaelt Verbindung zu Einstellungen und Timern, sonst nix
Type TApp
	Field Timer:TDeltaTimer
	Field settings:TApplicationSettings
	Field devConfig:TData				= new TData
	Field prepareScreenshot:Int			= 0						'logo for screenshot
	Field g:TGraphics
	Field vsync:int						= TRUE

	Field creationTime:Int 'only used for debug purpose (loadingtime)
	Global lastLoadEvent:TEventSimple	= Null
	Global OnLoadListener:TLink = null
	Global baseResourcesLoaded:Int		= 0						'able to draw loading screen?
	Global baseResourceXmlUrl:String	= "config/startup.xml"	'holds bg for loading screen and more
	Global currentResourceUrl:String	= ""
	Global maxResourceCount:Int			= 435					'set to <=0 to get a output of loaded resources
	Global loadedResourceCount:Int		= 0						'set to <=0 to get a output of loaded resources

	Global LogoFadeInFirstCall:Int		= 0
	Global LoaderWidth:Int				= 0

	Global ExitApp:Int 						= 0		 			'=1 and the game will exit
	Global ExitAppDialogue:TGUIModalWindow	= Null
	Global ExitAppDialogueTime:Int			= 0					'creation time for "double escape" to abort
	Global ExitAppDialogueEventListeners:TList = CreateList()


	Function Create:TApp(updatesPerSecond:Int = 60, framesPerSecond:Int = 30, vsync:int=TRUE)
		Local obj:TApp = New TApp
		obj.creationTime	= MilliSecs()
		obj.settings		= New TApplicationSettings
		obj.timer			= TDeltaTimer.Create(updatesPerSecond, framesPerSecond)
		obj.vsync			= vsync
		'listen to App-timer
		'-register to draw loading screen
		EventManager.registerListenerFunction( "App.onDraw", 	TApp.drawLoadingScreen )
		'register to quit confirmation dialogue
		EventManager.registerListenerFunction( "guiModalWindow.onClose", 	TApp.onAppConfirmExit )
		'-register for each toLoad-Element from XML files
		obj.OnLoadListener = EventManager.registerListenerFunction( "XmlLoader.onLoadElement",	TApp.onLoadElement )
		EventManager.registerListenerFunction( "XmlLoader.onFinishParsing",	TApp.onFinishParsingXML )
		EventManager.registerListenerFunction( "Loader.onLoadElement",	TApp.onLoadElement )

		obj.LoadSettings("config/settings.xml")
		obj.InitGraphics()
		'load graphics needed for loading screen
		obj.currentResourceUrl = obj.baseResourceXmlUrl
		obj.LoadResources(obj.baseResourceXmlUrl)

		Return obj
	End Function


	Method LoadSettings:Int(path:String="config/settings.xml")
		Local xml:TXmlHelper = TXmlHelper.Create(path)
		Local node:TXmlNode = xml.findRootChild("settings")
		If node = Null Or node.getName() <> "settings" Then	Print "settings.xml fehlt der settings-Bereich"

		settings.fullscreen		= xml.FindValueBool(node, "fullscreen", settings.fullscreen, "settings.xml fehlt 'fullscreen', setze Defaultwert: "+settings.fullscreen)
		settings.directx		= xml.FindValueInt(node, "directx", settings.directx, "settings.xml fehlt 'directx', setze Defaultwert: "+settings.directx+" (OpenGL)")
		settings.colordepth		= xml.FindValueInt(node, "colordepth", settings.colordepth, "settings.xml fehlt 'colordepth', setze Defaultwert: "+settings.colordepth)
		local activateSoundEffects:int	= xml.FindValueBool(node, "sound_effects", TRUE, "settings.xml fehlt 'sound_effects', setze Defaultwert: TRUE")
		local activateSoundMusic:int	= xml.FindValueBool(node, "sound_music", TRUE, "settings.xml fehlt 'sound_music', setze Defaultwert: TRUE")

		TSoundManager.GetInstance().MuteMusic(not activateSoundMusic)
		TSoundManager.GetInstance().MuteSfx(not activateSoundEffects)

		If settings.colordepth <> 16 And settings.colordepth <> 32
			Print "settings.xml enthaelt fehlerhaften Eintrag fuer 'colordepth', setze Defaultwert: 16"
			settings.colordepth = 16
		EndIf
	End Method


	Method LoadResources:Int(path:String="config/resources.xml")
		Local XmlLoader:TXmlLoader = TXmlLoader.Create()
		XmlLoader.Parse(path)
		Assets.AddSet(XmlLoader.Values) 'copy XML-values

		'assign dev config
		devConfig = Assets.GetData("DEV_CONFIG", new TData)
		TFunctions.roundToBeautifulEnabled = devConfig.GetBool("DEV_ROUND_TO_BEAUTIFUL_VALUES", TRUE)
		if TFunctions.roundToBeautifulEnabled
			TDevHelper.Log("TApp.LoadResources()", "DEV RoundToBeautiful is enabled", LOG_DEBUG | LOG_LOADING)
		else
			TDevHelper.Log("TApp.LoadResources()", "DEV RoundToBeautiful is disabled", LOG_DEBUG | LOG_LOADING)
		endif
	End Method


	Method Start()
		EventManager.unregisterListenersByTrigger("App.onDraw")
		AppEvents.Init()

		EventManager.registerListenerFunction("App.onSystemUpdate", AppEvents.onAppSystemUpdate )
		EventManager.registerListenerFunction("App.onUpdate", 		AppEvents.onAppUpdate )
		EventManager.registerListenerFunction("App.onDraw", 		AppEvents.onAppDraw )
		'so we could create special fonts and other things
		EventManager.triggerEvent( TEventSimple.Create("App.onStart") )

		'from now on we are no longer interested in loaded elements
		'as we are no longer in the loading screen (-> silent loading)
		if OnLoadListener then EventManager.unregisterListenerByLink( OnLoadListener )

		TDevHelper.Log("TApp.Start()", "loaded resources: "+loadedResourceCount, LOG_INFO)
		TDevHelper.Log("TApp.Start()", "loading time: "+(MilliSecs() - creationTime) +"ms", LOG_INFO)
	End Method


	Method SaveScreenshot(overlay:TGW_Sprite)
		Local filename:String, padded:String
		Local num:Int = 1

		filename = "screenshot_001.png"

		While FileType(filename) <> 0
			num:+1

			padded = num
			While padded.length < 3
				padded = "0"+padded
			Wend
			filename = "screenshot_"+padded+".png"
		Wend

'		Local img:TPixmap = GrabPixmap(0, 0, GraphicsWidth(), GraphicsHeight())
		Local img:TPixmap = VirtualGrabPixmap(0, 0, GraphicsWidth(), GraphicsHeight())

		'add overlay
		If overlay Then overlay.DrawOnImage(img, settings.GetWidth() - overlay.GetWidth() - 10, 10, TColor.Create(255,255,255,0.5))

		'remove alpha
		SavePixmapPNG(ConvertPixmap(img, PF_RGB888), filename)

		TDevHelper.Log("App.SaveScreenshot", "Screenshot saved as ~q"+filename+"~q", LOG_INFO)
	End Method


	Method InitGraphics:Int()
		'virtual resolution
		InitVirtualGraphics()

		Try
			Select Settings.directx
				?Win32
				Case  1	SetGraphicsDriver D3D7Max2DDriver()
				Case  2	SetGraphicsDriver D3D9Max2DDriver()
				?
				Case -1 SetGraphicsDriver GLMax2DDriver()
				?Linux
				Default SetGraphicsDriver GLMax2DDriver()
'				Default SetGraphicsDriver BufferedGLMax2DDriver()
				?
				?Not Linux
				Default SetGraphicsDriver GLMax2DDriver()
				?
			EndSelect
			g = Graphics(Settings.realWidth, Settings.realHeight, Settings.colordepth*Settings.fullscreen, Settings.Hertz, Settings.flag)
			If g = Null
			?Win32
				Throw "Graphics initiation error! The game will try to open in windowed DirectX 7 mode."
				SetGraphicsDriver D3D7Max2DDriver()
				g = Graphics(Settings.realWidth, Settings.realHeight, 0, Settings.Hertz)
			?Not Win32
				Throw "Graphics initiation error! no OpenGL available."
			?
			EndIf
		EndTry
		SetBlend ALPHABLEND
		SetMaskColor 0, 0, 0
		HideMouse()

		'virtual resolution
		SetVirtualGraphics(settings.designedWidth, settings.designedHeight, False)
	End Method


	Function onFinishParsingXML( triggerEvent:TEventBase )
		Local evt:TEventSimple = TEventSimple(triggerEvent)
		If evt<>Null
			If evt.getData().getString("url") = TApp.baseResourceXmlUrl Then TApp.baseResourcesLoaded = 1
			If TApp.maxResourceCount <= 0 Then Print "loaded items from xml: "+evt.getData().getInt("loaded")
		EndIf
	End Function


	Function onLoadElement( triggerEvent:TEventBase )
		TApp.lastLoadEvent = TEventSimple(triggerEvent)
		loadedResourceCount:+1
		If TApp.baseResourcesLoaded Then App.timer.loop()
	End Function


	Function drawLoadingScreen( triggerEvent:TEventBase )
		Local evt:TEventSimple = TApp.lastLoadEvent
		If evt<>Null
			Local element:String		= evt.getData().getString("element")
			Local text:String			= evt.getData().getString("text")
			Local itemNumber:Int		= evt.getData().getInt("itemNumber")
			Local error:Int				= evt.getData().getInt("error")
			Local maxItemNumber:Int		= 0
			If itemNumber > 0 Then maxItemNumber = evt.getData().getInt("maxItemNumber")

			If element = "XmlFile" Then TApp.currentResourceUrl = text

			SetColor 255, 255, 255
			Assets.GetSprite("gfx_startscreen").Draw(0,0)

			If LogoFadeInFirstCall = 0 Then LogoFadeInFirstCall = MilliSecs()
			SetAlpha Float(Float(MilliSecs() - LogoFadeInFirstCall) / 750.0)
			Assets.GetSprite("gfx_startscreen_logo").Draw( App.settings.getWidth()/2 - Assets.GetSprite("gfx_startscreen_logo").area.GetW() / 2, 100)
			SetAlpha 1.0
			Assets.GetSprite("gfx_startscreen_loadingBar").Draw( 400, 376, 1, TPoint.Create(ALIGN_CENTER, ALIGN_TOP))
			'each run of "draw" incs by "pixels per resource"

'			LoaderWidth = Min(680, LoaderWidth + (680.0 / TApp.maxResourceCount))
			LoaderWidth = Min(670, 670.0 * Float(loadedResourceCount)/Float(TApp.maxResourceCount))
			Assets.GetSprite("gfx_startscreen_loadingBar").TileDraw((400-Assets.GetSprite("gfx_startscreen_loadingBar").framew / 2) ,376,LoaderWidth, Assets.GetSprite("gfx_startscreen_loadingBar").frameh)
			SetColor 0,0,0
			If itemNumber > 0
				SetAlpha 0.25
				DrawText "[" + Replace(RSet(loadedResourceCount, String(TApp.maxResourceCount).length), " ", "0") + "/" + TApp.maxResourceCount + "]", 655, 415
'				DrawText "[" + Replace(RSet(itemNumber, String(maxItemNumber).length), " ", "0") + "/" + maxItemNumber + "]", 670, 415
				DrawText TApp.currentResourceUrl, 80, 402
			EndIf
			SetAlpha 0.5
			DrawText "Loading: "+text, 80, 415
			SetAlpha 1.0
			If error > 0
				SetColor 255, 0 ,0
				DrawText("ERROR: ", 80,440)
				SetAlpha 0.75
				DrawText(text+" not found. (press ESC to exit)", 130,440)
				SetAlpha 1.0
			EndIf
			SetColor 255, 255, 255

			'base cursor
			Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-9, 	MouseManager.y-2	,0)

			Flip 0
		EndIf
	End Function


	Function onAppConfirmExit:Int(triggerEvent:TEventBase)
		Local buttonNumber:Int = triggerEvent.GetData().getInt("closeButton",-1)

		'approve exit
		If buttonNumber = 0 Then TApp.ExitApp = True
		'remove connection to global value (guimanager takes care of fading)
		TApp.ExitAppDialogue = Null

		'in single player: resume game
		If Game And Not Game.networkgame Then Game.SetPaused(False)

		Return True
	End Function


	Function CreateConfirmExitAppDialogue:Int()
		If ExitAppDialogue
			'after 100ms waiting another ESC-Press will close the dialogue
			If MilliSecs() - ExitAppDialogueTime < 100 Then Return False

			ExitAppDialogue.Close(-1)
			ExitAppDialogueTime = MilliSecs()
		Else
			'100ms since last dialogue
			If MilliSecs() - ExitAppDialogueTime < 100 Then Return False

			ExitAppDialogueTime = MilliSecs()
			'in single player: pause game
			If Game And Not Game.networkgame Then Game.SetPaused(True)

			ExitAppDialogue = New TGUIGameModalWindow.Create(0,0,400,150, "SYSTEM")
			ExitAppDialogue.SetDialogueType(2)
			'limit to "screen" area
			If game.gamestate = TGame.STATE_RUNNING
				ExitAppDialogue.darkenedArea = TRectangle.Create(20,10,760,373)
			EndIf

			ExitAppDialogue.SetCaptionAndValue( GetLocale("ALREADY_OVER"), GetLocale("DO_YOU_REALLY_WANT_TO_QUIT_THE_GAME") )
		EndIf
	End Function

End Type


'just an object holding all data which has to get saved
'it is kind of an "DataCollectionCollection" ;D
Type TSaveGame
	Field _Game:TGame = Null
	Field _ProgrammeDataCollection:TProgrammeDataCollection = Null
	Field _NewsEventCollection:TNewsEventCollection = Null
	Field _FigureCollection:TFigureCollection = Null
	Field _EventManagerEvents:TList = null
	Field _StationMapCollection:TStationMapCollection = null
	Field _Building:TBuilding		'includes, sky, moon, ufo, elevator
	Field _RoomHandler_MovieAgency:RoomHandler_MovieAgency
	Field _RoomHandler_AdAgency:RoomHandler_AdAgency
	Const MODE_LOAD:int = 0
	Const MODE_SAVE:int = 1


	Method RestoreGameData:Int()
		_Assign(_FigureCollection, FigureCollection, "FigureCollection", MODE_LOAD)
		_Assign(_ProgrammeDataCollection, ProgrammeDataCollection, "ProgrammeDataCollection", MODE_LOAD)
		_Assign(_NewsEventCollection, NewsEventCollection, "NewsEventCollection", MODE_LOAD)
		_Assign(_Building, Building, "Building", MODE_LOAD)
		_Assign(_EventManagerEvents, EventManager._events, "Events", MODE_LOAD)
		_Assign(_StationMapCollection, StationMapCollection, "StationMapCollection", MODE_LOAD)
		_Assign(_RoomHandler_MovieAgency, RoomHandler_MovieAgency._instance, "MovieAgency", MODE_LOAD)
		_Assign(_RoomHandler_AdAgency, RoomHandler_AdAgency._instance, "AdAgency", MODE_LOAD)

		_Assign(_Game, Game, "Game")
	End Method


	Method BackupGameData:Int()
		_Assign(Game, _Game, "Game", MODE_SAVE)
		_Assign(Building, _Building, "Building", MODE_SAVE)
		_Assign(FigureCollection, _FigureCollection, "FigureCollection", MODE_SAVE)
		_Assign(ProgrammeDataCollection, _ProgrammeDataCollection, "ProgrammeDataCollection", MODE_SAVE)
		_Assign(NewsEventCollection, _NewsEventCollection, "NewsEventCollection", MODE_SAVE)
		_Assign(EventManager._events, _EventManagerEvents, "Events", MODE_SAVE)
		_Assign(StationMapCollection, _StationMapCollection, "StationMapCollection", MODE_SAVE)
		'special room data
		_Assign(RoomHandler_MovieAgency._instance, _RoomHandler_MovieAgency, "MovieAgency", MODE_Save)
		_Assign(RoomHandler_AdAgency._instance, _RoomHandler_AdAgency, "AdAgency", MODE_Save)
	End Method


	Method _Assign(objSource:object var, objTarget:object var, name:string="DATA", mode:int=0)
		if objSource
			objTarget = objSource
			if mode = MODE_LOAD
				TDevHelper.Log("TSaveGame.RestoreGameData()", "Loaded object "+name, LOG_DEBUG | LOG_SAVELOAD)
			else
				TDevHelper.Log("TSaveGame.BackupGameData()", "Saved object "+name, LOG_DEBUG | LOG_SAVELOAD)
			endif
		else
			TDevHelper.Log("TSaveGame", "object "+name+" was NULL - ignored", LOG_DEBUG | LOG_SAVELOAD)
		endif
	End Method


	Method CheckGameData:Int()
		'check if all data is available
		Return True
	End Method


	'merge a source object with a target object, only overwrite
	'things not set to "nosave"
	Function MergeObjects(objectSource:object, objectTarget:object var)
		'
	End Function


	Function Load:Int(saveName:String="savegame.xml")
		TPersist.maxDepth = 4096
		Local persist:TPersist = New TPersist
		Local saveGame:TSaveGame = TSaveGame(persist.DeserializeFromFile(savename))
		If Not saveGame
			Print "savegame file is corrupt or missing."
			Return False
		EndIf

		If Not saveGame.CheckGameData()
			Print "savegame file in bad state."
			Return False
		EndIf

		'tell everybody we start loading (eg. for unregistering objects before)
		'payload is saveName
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginLoad", new TData.addString("saveName", saveName)))

		'load savegame data into game object
		saveGame.RestoreGameData()

		'tell everybody we finished loading (eg. for clearing GUI-lists)
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnLoad", new TData.addString("saveName", saveName).add("saveGame", saveGame)))

		'call game that game continues/starts now
		Game.Start()

		Return True
	End Function


	Function Save:Int(saveName:String="savegame.xml")
		Local saveGame:TSaveGame = New TSaveGame
		'tell everybody we start saving
		'payload is saveName
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginSave", new TData.addString("saveName", saveName)))

		'store game data in savegame
		saveGame.BackupGameData()

		'setup tpersist config
		TPersist.format=True
'during development...
'		TPersist.compressed = True

		TPersist.maxDepth = 4096

		'save the savegame data as xml
		Local persist:TPersist = New TPersist
		persist.SerializeToFile(saveGame, saveName)

		'tell everybody we finished saving
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnSave", new TData.addString("saveName", saveName).add("saveGame", saveGame)))

		Return True
	End Function
End Type


'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame {_exposeToLua="selected"}
	'globals are not saveloaded/exposed
	Global debugMode:Int					= 0						'0=no debug messages; 1=some debugmessages
	Global debugInfos:Int					= 0
	Global debugQuoteInfos:Int				= 0
	Field debugAudienceInfo:TDebugAudienceInfos = new TDebugAudienceInfos

	'===== GAME STATES =====
	Const STATE_RUNNING:Int					= 0
	Const STATE_MAINMENU:Int				= 1
	Const STATE_NETWORKLOBBY:Int			= 2
	Const STATE_SETTINGSMENU:Int			= 3
	Const STATE_STARTMULTIPLAYER:Int		= 4						'mode when data gets synchronized
	Const STATE_INITIALIZEGAME:Int			= 5						'mode when data needed for game (names,colors) gets loaded

	'===== GAME SETTINGS =====
	Const daysPerYear:Int					= 14 	{_exposeToLua}
	Const startMovieAmount:Int 				= 5		{_exposeToLua}	'how many movies does a player get on a new game
	Const startSeriesAmount:Int				= 1		{_exposeToLua}	'how many series does a player get on a new game
	Const startAdAmount:Int					= 3		{_exposeToLua}	'how many contracts a player gets on a new game
	Const maxAbonnementLevel:Int			= 3		{_exposeToLua}
	Const maxContracts:Int			 		= 10	{_exposeToLua}	'how many contracts a player can possess
	Const maxProgrammeLicencesInSuitcase:Int= 12	{_exposeToLua}	'how many movies can be carried in suitcase

	Field BroadcastManager:TBroadcastManager	= Null
	Field PopularityManager:TPopularityManager	= Null

	Field maxAudiencePercentage:Float	 	= 0.3				'how many 0.0-1.0 (100%) audience is maximum reachable
	Field randomSeedValue:Int				= 0					'used so that random values are the same on all computers having the same seed value

	Field userName:String				= ""	{nosave}	'username of the player ->set in config
	Field userPort:Short				= 4544	{nosave}	'userport of the player ->set in config
	Field userChannelName:String		= ""	{nosave}	'channelname the player uses ->set in config
	Field userLanguage:String			= "de"	{nosave}	'language the player uses ->set in config
	Field userDB:String					= ""	{nosave}
	Field userFallbackIP:String			= "" 	{nosave}

	Field Players:TPlayer[5]
	Field playerCount:Int				= 4

	Field paused:Int					= False
	Field speed:Float					= 1.0 				'Speed of the game in "game minutes per real-time second"
	Field timeStart:Double				= 0.0				'time (minutes) used when starting the game
	Field timeGone:Double				= 0.0				'time (minutes) in game, not reset every day
	Field timeGoneLastUpdate:Double		= -1.0				'time (minutes) in game of the last update (enables calculation of missed minutes)
	Field daysPlayed:Int				= 0

	Field title:String 				= "MyGame"				'title of the game

	Field cursorstate:Int		 	= 0 					'which cursor has to be shown? 0=normal 1=dragging
	Field playerID:Int 				= 1						'playerID of player who sits in front of the screen
	Field gamestate:Int 			= -1					'0 = Mainmenu, 1=Running, ...

	Field stateSyncTime:Int			= 0						'last sync
	Field stateSyncTimer:Int		= 2000					'sync every

	Field refillMovieAgencyTimer:Int= 180					'interval
	Field refillMovieAgencyTime:Int = 180					'minutes till happening again
	Field refillAdAgencyTimer:Int	= 240			 		'interval
	Field refillAdAgencyTime:Int	= 240			 		'minutes till happening again


	'--networkgame auf "isNetworkGame()" umbauen
	Field networkgame:Int 			= 0 					'are we playing a network game? 0=false, 1=true, 2
	Field networkgameready:Int 		= 0 					'is the network game ready - all options set? 0=false
	Field onlinegame:Int 			= 0 					'playing over internet? 0=false

	Global _instance:TGame
	Global _initDone:int	 		= FALSE


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
		Localization.AddLanguages("de, en") 'adds German and English to possible language
		Localization.SetLanguage(userlanguage) 'selects language
		Localization.LoadResource("res/lang/lang_"+userlanguage+".txt")
		networkgame = 0

		SetStartYear(1985)
		title = "unknown"

		SetRandomizerBase( MilliSecs() )

		PopularityManager	= TPopularityManager.Create()
		BroadcastManager	= TBroadcastManager.Create()

		Return self
	End Method


	Method InitializeBasics()
		CreateInitialPlayers()
	End Method


	'Initializes "data" needed for a game
	'(maps, databases, managers)
	Method Initialize()
		'managers skip initialization if already done (eg. during loading)
		Game.PopularityManager.Initialize()
		Game.BroadcastManager.Initialize()

		'load all movies, news, series and ad-contracts
		LoadDatabase(userdb)

		'load the used map
		StationMapCollection.LoadMapFromXML("config/maps/germany.xml")
	End Method


	'run when a specific game starts
	Method Start:int()
		'disable chat if not networkgaming
		If Not game.networkgame
			InGame_Chat.hide()
		Else
			InGame_Chat.show()
		EndIf
	End Method

	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TDevHelper.Log("TGame", "Savegame loaded - colorize players.", LOG_DEBUG | LOG_SAVELOAD)
		'reconnect AI and other things
		For local player:TPlayer = eachin GetInstance().Players
			player.onLoad(null)
		Next
		'colorize gfx again
		Init_Colorization()

		'set active player again (sets correct game screen)
		GetInstance().SetActivePlayer()
	End Function


	'run when starting saving a savegame
	Function onSaveGameBeginSave(triggerEvent:TEventBase)
		TDevHelper.Log("TGame", "Start saving - inform AI.", LOG_DEBUG | LOG_SAVELOAD)
		'inform player AI that we are saving now
		For local player:TPlayer = eachin GetInstance().players
			If player.figure.isAI() then player.PlayerKI.CallOnSave()
		Next
	End Function


	Method SetStartYear:Int(year:Int=0)
		If year = 0 Then Return False
		If year < 1930 Then Return False

		timeGone	= MakeTime(year,1,0,0)
		timeStart	= MakeTime(year,1,0,0)
	End Method


	'returns how many game minutes equal to one real time second
	Method GetGameMinutesPerSecond:Float()
		Return speed*(Not paused)
	End Method


	'returns how many seconds pass for one game minute
	Method GetSecondsPerGameMinute:Float()
		If speed*(Not paused) = 0 Then Return 0
		Return 1.0 / (speed *(Not paused))
	End Method


	Method SetPaused(bool:Int=False)
		paused = bool
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
		For Local Player:TPlayer = EachIn Players
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
		For Local Player:TPlayer = EachIn Players
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
		For Local Player:TPlayer = EachIn Players
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


	Method CreateInitialPlayers()
		'Creating PlayerColors - could also be done "automagically"
		Local playerColors:TList = Assets.GetList("playerColors")
		If playerColors = Null Then Throw "no playerColors found in configuration"
		For Local col:TColor = EachIn playerColors
			col.AddToList()
		Next
		'create playerfigures in figures-image
		'TColor.GetByOwner -> get first unused color, TPlayer.Create sets owner of the color
		SetPlayer(1, TPlayer.Create(1,userName	,userChannelName	,Assets.GetSprite("Player1"),	250,  2, 90, TColor.getByOwner(0), 1, "Player 1"))
		SetPlayer(2, TPlayer.Create(2,"Sandra"	,"SunTV"			,Assets.GetSprite("Player2"),	280,  5, 90, TColor.getByOwner(0), 0, "Player 2"))
		SetPlayer(3, TPlayer.Create(3,"Seidi"		,"FunTV"			,Assets.GetSprite("Player3"),	240,  8, 90, TColor.getByOwner(0), 0, "Player 3"))
		SetPlayer(4, TPlayer.Create(4,"Alfi"		,"RatTV"			,Assets.GetSprite("Player4"),	290, 13, 90, TColor.getByOwner(0), 0, "Player 4"))
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


	Method IsPlayer:Int(number:Int)
		Return (number>0 And number<=playerCount And Players[number] <> Null)
	End Method


	Method IsHumanPlayer:Int(number:Int)
		Return (IsPlayer(number) And Not Players[number].figure.IsAI())
	End Method


	'the negative of "isHumanPlayer" - also "no human player" is possible
	Method IsAIPlayer:Int(number:Int)
		Return (IsPlayer(number) And Players[number].figure.IsAI())
	End Method


	Method IsLocalPlayer:Int(number:Int)
		Return number = playerID
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
					EventManager.registerEvent(TEventSimple.Create("Game.OnMinute", new TData.addNumber("minute", game.GetMinute()).addNumber("hour", game.GetHour()).addNumber("day", game.GetDay()) ))
					EventManager.registerEvent(TEventSimple.Create("Game.OnHour", new TData.addNumber("minute", game.GetMinute()).addNumber("hour", game.GetHour()).addNumber("day", game.GetDay()) ))
					'so we start at day "1"
					EventManager.registerEvent(TEventSimple.Create("Game.OnDay", new TData.addNumber("minute", game.GetMinute()).addNumber("hour", game.GetHour()).addNumber("day", game.GetDay()) ))

					'so we could add news etc.
					EventManager.triggerEvent( TEventSimple.Create("Game.OnStart") )

					TSoundManager.GetInstance().PlayMusicPlaylist("default")
			Default
				'
		EndSelect
	End Method


	'sets the player controlled by this client
	Method SetActivePlayer(ID:int=-1)
		if ID = -1 then ID = playerID
		'for debug purposes we need to adjust more than just
		'the playerID.
		playerID = ID

		'get currently shown screen of that player
		if GetPlayer().figure.inRoom
			ScreenCollection.GoToScreen(TInGameScreen_Room.GetByRoom(GetPlayer().figure.inRoom))
		'go to building
		else
			ScreenCollection.GoToScreen(GameScreen_Building)
		endif
	End Method


	Method SetPlayer:TPlayer(playerID:Int=-1, player:TPlayer)
		If playerID=-1 Then playerID = Self.playerID
		If players.length <= playerID Then players = players[..playerID+1]
		players[playerID] = player
	End Method


	Method GetPlayer:TPlayer(playerID:Int=-1)
		If playerID=-1 Then playerID=Self.playerID
		If Not Game.isPlayer(playerID) Then Return Null

		Return Self.players[playerID]
	End Method


	'return the maximum audience of a player
	'if no playerID was given, the average of all players is returned
	Method GetMaxAudience:Int(playerID:Int=-1)
		If Not Game.isPlayer(playerID)
			Local avg:Int = 0
			For Local i:Int = 1 To 4
				avg :+ Players[ i ].GetMaxAudience()
			Next
			avg:/4
			Return avg
		EndIf
		Return Players[ playerID ].GetMaxAudience()
	End Method


	Method GetDayName:String(day:Int, longVersion:Int=0) {_exposeToLua}
		Local versionString:String = "SHORT"
		If longVersion = 1 Then versionString = "LONG"

		Select day
			Case 0	Return GetLocale("WEEK_"+versionString+"_MONDAY")
			Case 1	Return GetLocale("WEEK_"+versionString+"_TUESDAY")
			Case 2	Return GetLocale("WEEK_"+versionString+"_WEDNESDAY")
			Case 3	Return GetLocale("WEEK_"+versionString+"_THURSDAY")
			Case 4	Return GetLocale("WEEK_"+versionString+"_FRIDAY")
			Case 5	Return GetLocale("WEEK_"+versionString+"_SATURDAY")
			Case 6	Return GetLocale("WEEK_"+versionString+"_SUNDAY")
			Default	Return "not a day"
		EndSelect
	End Method


	Function SendSystemMessage(message:String)
		'send out to chats
		EventManager.triggerEvent(TEventSimple.Create("chat.onAddEntry", new TData.AddNumber("senderID", -1).AddNumber("channels", CHAT_CHANNEL_SYSTEM).AddString("text", message) ) )
	End Function


	'Summary: load the config-file and set variables depending on it
	Method LoadConfig:Byte(configfile:String="config/settings.xml")
		Local xml:TxmlHelper = TxmlHelper.Create(configfile)
		If xml <> Null Then TDevHelper.Log("TGame.LoadConfig()", "settings.xml read", LOG_LOADING)
		Local node:TxmlNode = xml.FindRootChild("settings")
		If node = Null Or node.getName() <> "settings"
			TDevHelper.Log("TGame.Loadconfig()", "settings.xml misses a setting-part", LOG_LOADING | LOG_ERROR)
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


	Method GetNextHour:Int() {_exposeToLua}
		Local nextHour:Int = GetHour()+1
		If nextHour > 24 Then Return nextHour - 24
		Return nextHour
	End Method


	'Summary: Updates Time, Costs, States ...
	Method Update(deltaTime:Float=1.0)
		'==== ADJUST TIME ====
		'speed is given as a factor "game-time = x * real-time"
		timeGone :+ deltaTime * GetGameMinutesPerSecond()
		'initialize last update value if still at default value
		if timeGoneLastUpdate < 0 then timeGoneLastUpdate = timeGone

		'==== HANDLE TIMED EVENTS ====
		'time for news ?
		If NewsAgency.NextEventTime < timeGone Then NewsAgency.AnnounceNewNewsEvent()
		If NewsAgency.NextChainCheckTime < timeGone Then NewsAgency.ProcessNewsEventChains()

		'send state to clients
		If IsGameLeader() And networkgame And stateSyncTime < MilliSecs()
			NetworkHelper.SendGameState()
			stateSyncTime = MilliSecs() + stateSyncTimer
		EndIf

		'==== HANDLE IN GAME TIME ====
		'less than a ingame minute gone? nothing to do YET
		If timeGone - timeGoneLastUpdate < 1.0 Then Return

		'==== HANDLE GONE/SKIPPED MINUTES ====
		'if speed is to high - minutes might get skipped,
		'handle this case so nothing gets lost.
		'missedMinutes is >1 in all cases (else this part isn't run)
		Local missedMinutes:float = timeGone - timeGoneLastUpdate
		Local daysMissed:Int = Floor(missedMinutes / (24*60))

		'adjust the game time so Game.GetHour()/GetMinute()/... return
		'the correct value for each loop cycle. So Functions can rely on
		'that functions to get the time they request.
		'as everything can get calculated using "timeGone", no further
		'adjustments have to take place
		timeGone:- missedMinutes
		For Local i:Int = 1 to missedMinutes
			'add back another gone minute each loop
			timeGone:+1

			'day
			If GetHour() = 0 And GetMinute() = 0
				'increase current day
				daysPlayed :+1
			 	'automatically change current-plan-day on day change
			 	'but do it silently (without affecting the)
			 	RoomHandler_Office.ChangePlanningDay(GetDay())

				EventManager.triggerEvent(TEventSimple.Create("Game.OnDay", new TData.addNumber("minute", GetMinute()).addNumber("hour", GetHour()).addNumber("day", GetDay()) ))
			EndIf

			'hour
			If GetMinute() = 0
				EventManager.triggerEvent(TEventSimple.Create("Game.OnHour", new TData.addNumber("minute", GetMinute()).addNumber("hour", GetHour()).addNumber("day", GetDay()) ))
			endif

			'minute
			EventManager.triggerEvent(TEventSimple.Create("Game.OnMinute", new TData.addNumber("minute", GetMinute()).addNumber("hour", GetHour()).addNumber("day", GetDay()) ))
		Next

		'reset gone time so next update can calculate missed minutes
		timeGoneLastUpdate = timeGone
	End Method


	'Summary: returns day of the week including gameday
	Method GetFormattedDay:String(_day:Int = -5) {_exposeToLua}
		Return _day+"."+GetLocale("DAY")+" ("+GetDayName( Max(0,_day-1) Mod 7, 0)+ ")"
	End Method


	Method GetFormattedDayLong:String(_day:Int = -1) {_exposeToLua}
		If _day < 0 Then _day = GetDay()
		Return GetDayName( Max(0,_day-1) Mod 7, 1)
	End Method


	'Summary: returns formatted value of actual gametime
	Method GetFormattedTime:String(time:Double=0) {_exposeToLua}
		Local strHours:String = GetHour(time)
		Local strMinutes:String = GetMinute(time)

		If Int(strHours) < 10 Then strHours = "0"+strHours
		If Int(strMinutes) < 10 Then strMinutes = "0"+strMinutes
		Return strHours+":"+strMinutes
	End Method


	Method GetWeekday:Int(_day:Int = -1) {_exposeToLua}
		If _day < 0 Then _day = Self.GetDay()
		Return Max(0,_day-1) Mod 7
	End Method


	Method MakeTime:Double(year:Int,day:Int,hour:Int,minute:Int) {_exposeToLua}
		'year=1,day=1,hour=0,minute=1 should result in "1*yearInSeconds+1"
		'as it is 1 minute after end of last year - new years eve ;D
		'there is no "day 0" (as there would be no "month 0")

		Return (((day-1) + year*Self.daysPerYear)*24 + hour)*60 + minute
	End Method


	Method GetTimeGone:Double() {_exposeToLua}
		Return Self.timeGone
	End Method


	Method GetTimeStart:Double() {_exposeToLua}
		Return Self.timeStart
	End Method


	Method GetYear:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = timeGone
		_time = Floor(_time / (24 * 60 * daysPerYear))
		Return Int(_time)
	End Method


	Method GetDayOfYear:Int(_time:Double = 0) {_exposeToLua}
		Return (GetDay(_time) - GetYear(_time)*daysPerYear)
	End Method


	'get the amount of days played (completed! - that's why "-1")
	Method GetDaysPlayed:Int() {_exposeToLua}
		Return daysPlayed
'		return self.GetDay(self.timeGone - Self.timeStart) - 1
	End Method


	Method GetStartDay:Int() {_exposeToLua}
		Return GetDay(timeStart)
	End Method


	Method GetDay:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = timeGone
		_time = Floor(_time / (24 * 60))
		'we are ON a day (it is not finished yet)
		'if we "ceil" the time, we would ignore 1.0 as this would
		'not get rounded to 2.0 like 1.01 would do
		Return 1 + Int(_time)
	End Method


	Method GetHour:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = timeGone
		'remove days from time
		_time = _time Mod (24*60)
		'hours = how many times 60 minutes fit into rest time
		Return Int(Floor(_time / 60))
	End Method


	Method GetMinute:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = timeGone
		'remove days from time
		_time = _time Mod (24*60)
		'minutes = rest not fitting into hours
		Return Int(_time) Mod 60
	End Method
End Type


'game specific events - menu handlers etc.
Type TGameEvents
	Global _initDone:Int = False

	'register basic events (menu handlers)
	Function Init:Int()
		'skip if done already
		If _initDone Then Return False

		'===== REGISTER EVENTS =====

		'set init done so we do not do it again
		_initDone = True
	End Function
End Type


Type TFigurePostman Extends TFigure
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500,0,1000)

	'we need to overwrite it to have a custom type - with custom update routine
	Method CreateFigure:TFigurePostman(FigureName:String, sprite:TGW_Sprite, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		Super.CreateFigure(FigureName, sprite, x, onFloor, speed, ControlledByID)
		Return Self
	End Method

	Method UpdateCustom:Int(deltaTime:Float)
		If inRoom And nextActionTimer.isExpired()
			nextActionTimer.Reset()
			'switch "with" and "without" letter
			If sprite.spriteName = "BotePost"
				sprite = Assets.GetSpritePack("figures").GetSprite("BoteLeer")
			Else
				sprite = Assets.GetSpritePack("figures").GetSprite("BotePost")
			EndIf

			'leave that room so we can find a new target
			leaveRoom()
		EndIf

		'figure is in building and without target waiting for orders
		If Not inRoom And Not target
			Local door:TRoomDoor
			Repeat
				door = TRoomDoor.GetRandom()
			Until door.doorType >0

			TDevHelper.Log("TFigurePostman", "nothing to do -> send to door of " + door.room.name, LOG_DEBUG | LOG_AI, True)
			SendToDoor(door)
		EndIf
	End Method
End Type


Type TFigureJanitor Extends TFigure
	Field currentAction:Int	= 0		'0=nothing,1=cleaning,...
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(2500,0, 500) '500ms randomness
	Field useElevator:Int 	= True
	Field useDoors:Int		= True
	Field BoredCleanChance:Int	= 10
	Field NormalCleanChance:Int = 30
	Field MovementRangeMinX:Int	= 220
	Field MovementRangeMaxX:Int	= 580

	'we need to overwrite it to have a custom type - with custom update routine
	Method CreateFigure:TFigureJanitor(FigureName:String, sprite:TGW_Sprite, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		Super.CreateFigure(FigureName, sprite, x, onFloor, speed, ControlledByID)
		Self.rect.dimension.setX(14)

		Self.insertAnimation("cleanRight", TAnimation.Create([ [11,130], [12,130] ], -1, 0) )
		Self.insertAnimation("cleanLeft", TAnimation.Create([ [13,130], [14,130] ], -1, 0) )

		Return Self
	End Method

	'overwrite original method
	Method getAnimationToUse:String()
		Local result:String = Super.getAnimationToUse()

		If currentAction = 1
			If result = "walkRight" Then result = "cleanRight" Else result="cleanLeft"
		EndIf
		Return result
	End Method

	'overwrite basic doMove and stop movement if needed
	Method doMove(deltaTime:Float)
		If currentAction = 1
			Local backupSpeed:Int = vel.getX()
			vel.setX(0)
			Super.doMove(deltaTime)
			vel.setX(backupSpeed)
		Else
			Super.doMove(deltaTime)
		EndIf
	End Method

	Method UpdateCustom:Int(deltaTime:Float)
		'waited to long - change target (returns false while in elevator)
		If hasToChangeFloor() And WaitAtElevatorTimer.isExpired()
			If ChangeTarget(Rand(150, 580), Building.pos.y + Building.GetFloorY(GetFloor()))
				WaitAtElevatorTimer.Reset()
			EndIf
		EndIf

		'sometimes we got stuck in a room ... go out
		If inRoom And Rand(0,100) = 1 '1%
			Local zufallx:Int = 0
			'move to a spot further away than just some pixels
			Repeat
				zufallx = Rand(MovementRangeMinX, MovementRangeMaxX)
			Until Abs(rect.GetX() - zufallx) > 75
			ChangeTarget(zufallx, Building.pos.y + Building.GetFloorY(GetFloor()))
		EndIf

		'reached target - and time to do something
		If Not target And nextActionTimer.isExpired()
			If Not hasToChangeFloor()

				'reset is done later - we want to catch isExpired there too
				'nextActionTimer.Reset()

				Local zufall:Int = Rand(0, 100)	'what to do?
				Local zufallx:Int = 0			'where to go?

				'move to a spot further away than just some pixels
				Repeat
					zufallx = Rand(MovementRangeMinX, MovementRangeMaxX)
				Until Abs(rect.GetX() - zufallx) > 75

				'move to a different floor (only if doing nothing special)
				If useElevator And currentAction=0 And zufall > 80 And Not IsAtElevator()
					Local sendToFloor:Int = GetFloor() + 1
					If sendToFloor > 13 Then sendToFloor = 0
					ChangeTarget(zufallx, Building.pos.y + Building.GetFloorY(sendToFloor))
					WaitAtElevatorTimer.Reset()
				'move to a different X on same floor - if not cleaning now
				Else If currentAction=0
					ChangeTarget(zufallx, Building.pos.y + Building.GetFloorY(GetFloor()))
				EndIf
			EndIf

		EndIf

		If Not inRoom And nextActionTimer.isExpired() And Not hasToChangeFloor()
			nextActionTimer.Reset()
			Self.currentAction = 0

			'chose actions
			'only clean with a chance of 30% when on the way to something
			'and do not clean if target is a room near figure
			If target And (Not Self.targetDoor Or (20 < Abs(targetDoor.pos.x - rect.GetX()) Or targetDoor.pos.y <> GetFloor()))
				If Rand(0,100) < Self.NormalCleanChance Then Self.currentAction = 1
			EndIf
			'if just standing around give a chance to clean
			If Not target And Rand(0,100) < Self.BoredCleanChance Then	Self.currentAction = 1
		EndIf

		If Not useDoors And Self.targetDoor Then Self.targetDoor = Null
	End Method
End Type




'MENU: MAIN MENU SCREEN
Type TScreen_MainMenu Extends TGameScreen
	Field guiButtonStart:TGUIButton
	Field guiButtonNetwork:TGUIButton
	Field guiButtonOnline:TGUIButton
	Field guiButtonSettings:TGUIButton
	Field guiButtonQuit:TGUIButton


Rem
Global StartTips:TList = CreateList()
StartTips.addLast( ["Tipp: Programmplaner", "Mit der STRG+Taste könnt ihr ein Programm mehrfach im Planer platzieren. Die Shift-Taste hingegen versucht nach der Platzierung die darauffolgende Episode bereitzustellen."] )
StartTips.addLast( ["Tipp: Programmplanung", "Programme haben verschiedene Genre. Diese Genre haben natürlich Auswirkungen.~n~nEine Komödie kann häufiger gesendet werden, als eine Live-Übertragung. Kinderfilme sind ebenso mit weniger Abnutzungserscheinungen verknüpft als Programme anderer Genre."] )
StartTips.addLast( ["Tipp: Werbeverträge", "Werbeverträge haben definierte Anforderungen an die zu erreichende Mindestzuschauerzahl. Diese, und natürlich auch die Gewinne/Strafen, sind gekoppelt an die Reichweite die derzeit mit dem eigenen Sender erreicht werden kann.~n~nManchmal ist es deshalb besser, vor dem Sendestationskauf neue Werbeverträge abzuschließen."] )

Global StartTipWindow:TGUIModalWindow = new TGUIModalWindow.Create(0,0,400,250, "InGame")
local tipNumber:int = rand(0, StartTips.count()-1)
local tip:string[] = string[](StartTips.valueAtIndex(tipNumber))
StartTipWindow.background.usefont = Assets.GetFont("Default", 18, BOLDFONT)
StartTipWindow.background.valueColor = TColor.Create(235,235,235)
StartTipWindow.setText( tip[0], tip[1] )
endrem

	Method Create:TScreen_MainMenu(name:String)
		Super.Create(name)
		self.background = background
		self.SetScreenChangeEffects(null,null) 'menus do not get changers

		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		local panelGap:int = GUIManager.config.GetInt("panelGap", 10)
		guiButtonsWindow = New TGUIGameWindow.Create(300, 330, 200, 400, name)
		guiButtonsWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")

		guiButtonsPanel	= guiButtonsWindow.AddContentBox(0,0,-1,-1)

		guiButtonStart		= New TGUIButton.Create(TPoint.Create(0,   0), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_SOLO_GAME"), name, Assets.fonts.baseFontBold)
		guiButtonNetwork	= New TGUIButton.Create(TPoint.Create(0,  40), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_NETWORKGAME"), name, Assets.fonts.baseFontBold)
		guiButtonOnline		= New TGUIButton.Create(TPoint.Create(0,  80), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_ONLINEGAME"), name, Assets.fonts.baseFontBold)
		guiButtonSettings	= New TGUIButton.Create(TPoint.Create(0, 120), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_SETTINGS"), name, Assets.fonts.baseFontBold)
		guiButtonQuit		= New TGUIButton.Create(TPoint.Create(0, 170), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_QUIT"), name, Assets.fonts.baseFontBold)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonNetwork)
		guiButtonsPanel.AddChild(guiButtonOnline)
		guiButtonsPanel.AddChild(guiButtonSettings)
		guiButtonsPanel.AddChild(guiButtonQuit)

		guiButtonSettings.disable()

		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickButtons")

		Return Self
	End Method


	'handle clicks on the buttons
	Method onClickButtons:Int(triggerEvent:TEventBase)
		Local sender:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not sender Then Return False

		Select sender
			Case guiButtonStart
					Game.SetGamestate(TGame.STATE_SETTINGSMENU)

			Case guiButtonNetwork
					Game.SetGamestate(TGame.STATE_NETWORKLOBBY)
					Game.onlinegame = False
					Game.networkgame = True

			Case guiButtonOnline
					Game.SetGamestate(TGame.STATE_NETWORKLOBBY)
					Game.onlinegame = True
					Game.networkgame = True

			Case guiButtonQuit
					App.ExitApp = True
		End Select
	End Method


	'override default draw
	Method Draw:int(tweenValue:float)
		DrawMenuBackground(False)

		'draw the janitor BEHIND the panels
		MainMenuJanitor.Draw(CURRENT_TWEEN_FACTOR)

		GUIManager.Draw(Self.name)
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)
		Super.Update(deltaTime)

		GUIManager.Update(Self.name)

		MainMenuJanitor.Update(deltaTime)
	End Method
End Type



'MENU: GAME SETTINGS SCREEN
Type TScreen_GameSettings Extends TGameScreen
	Field guiSettingsWindow:TGUIGameWindow
	'Field guiAnnounce:TGUICheckBox
	Field gui24HoursDay:TGUICheckBox
	Field guiSpecialFormats:TGUICheckBox
	Field guiFilterUnreleased:TGUICheckBox
	Field guiGameTitleLabel:TGuiLabel
	Field guiGameTitle:TGuiInput
	Field guiStartYearLabel:TGuiLabel
	Field guiStartYear:TGuiInput
	Field guiButtonStart:TGUIButton
	Field guiButtonBack:TGUIButton
	Field guiChat:TGUIChat
	Field guiPlayerNames:TGUIinput[4]
	Field guiChannelNames:TGUIinput[4]
	Field guiFigureArrows:TGUIArrowButton[8]
	Field modifiedPlayers:Int = False
	Global headerSize:Int = 35
	Global guiSettingsPanel:TGUIBackgroundBox
	Global guiPlayersPanel:TGUIBackgroundBox
	Global settingsArea:TRectangle = TRectangle.Create(10,10,780,0) 'position of the panel
	Global playerBoxDimension:TPoint = TPoint.Create(165,150) 'size of each player area
	Global playerColors:Int = 10
	Global playerColorHeight:Int = 10
	Global playerSlotGap:Int = 25
	Global playerSlotInnerGap:Int = 10 'the gap between inner canvas and inputs


	Method Create:TScreen_GameSettings(name:String)
		Super.Create(name)
		self.background = background
		'===== CREATE AND SETUP GUI =====
		guiSettingsWindow = New TGUIGameWindow.Create(settingsArea.GetX(), settingsArea.GetY(), settingsArea.GetW(), settingsArea.GetH(), "GameSettings")
		guiSettingsWindow.SetCaption("Spieler")
		guiSettingsWindow.guiBackground.spriteAlpha = 0.5
		local panelGap:int = GUIManager.config.GetInt("panelGap", 10)
		guiSettingsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)

		guiPlayersPanel = guiSettingsWindow.AddContentBox(0,0,-1, playerBoxDimension.GetY() + 2 * panelGap)
		guiSettingsPanel = guiSettingsWindow.AddContentBox(0,0,-1, 100)

		guiGameTitleLabel	= New TGUILabel.Create(0, 0, "Spieltitel:",TColor.CreateGrey(50),Null, name)
		guiGameTitle		= New TGUIinput.Create(0, 12, 300, -1, Game.title, 32, name)
		guiStartYearLabel	= New TGUILabel.Create(310, 0, "Startjahr:",TColor.CreateGrey(50),Null, name)
		guiStartYear		= New TGUIinput.Create(310, 12, 65, -1, "1985", 4, name)

		Local checkboxHeight:Int = 0
		'guiAnnounce		= New TGUICheckBox.Create(TRectangle.Create(430, 0, 200,20), False, "Spielersuche abgeschlossen", name, Assets.fonts.baseFontBold)

		gui24HoursDay		= New TGUICheckBox.Create(TRectangle.Create(430, 0, 200,20), True, GetLocale("24_HOURS_GAMEDAY"), name, Assets.fonts.baseFontBold)
		checkboxHeight 		= gui24HoursDay.GetScreenHeight()
		gui24HoursDay.disable() 'option not implemented
		guiSpecialFormats	= New TGUICheckBox.Create(TRectangle.Create(430, 0 + 1*checkboxHeight, 200,20), True, GetLocale("ALLOW_TRAILERS_AND_INFOMERCIALS"), name, Assets.fonts.baseFontBold)
		guiSpecialFormats.disable() 'option not implemented
		guiFilterUnreleased = New TGUICheckBox.Create(TRectangle.Create(430, 0 + 2*checkboxHeight, 200,20), True, GetLocale("ALLOW_MOVIES_WITH_YEAR_OF_PRODUCTION_GT_GAMEYEAR"), name, Assets.fonts.baseFontBold)

		'move announce to last
		'guiAnnounce.rect.position.MoveXY(0, 4*checkboxHeight)

		guiSettingsPanel.AddChild(guiGameTitleLabel)
		guiSettingsPanel.AddChild(guiGameTitle)
		guiSettingsPanel.AddChild(guiStartYearLabel)
		guiSettingsPanel.AddChild(guiStartYear)
		'guiSettingsPanel.AddChild(guiAnnounce)
		guiSettingsPanel.AddChild(gui24HoursDay)
		guiSettingsPanel.AddChild(guiSpecialFormats)
		guiSettingsPanel.AddChild(guiFilterUnreleased)


		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		guiButtonsWindow = New TGUIGameWindow.Create(590, 400, 200, 190, "GameSettings")
		guiButtonsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")

		guiButtonsPanel = guiButtonsWindow.AddContentBox(0,0,-1,-1)
		guiButtonStart	= New TGUIButton.Create(TPoint.Create(0, 0), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_START_GAME"), name, Assets.fonts.baseFontBold)
		guiButtonBack	= New TGUIButton.Create(TPoint.Create(0, guiButtonsPanel.GetcontentScreenHeight() - guiButtonStart.GetScreenHeight()), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_BACK"), name, Assets.fonts.baseFontBold)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonBack)


		guiChat	 = New TGUIChat.Create(10,400,540,190, "GameSettings")
		guiChat.guiInput.setMaxLength(200)

		guiChat.guiBackground.spriteAlpha = 0.5
		guiChat.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiChat.SetCaption("Chat")
		guiChat.guiList.Resize(guiChat.guiList.rect.GetW(), guiChat.guiList.rect.GetH()-10)
		guiChat.guiInput.rect.position.MoveXY(panelGap, -panelGap)
		guiChat.guiInput.Resize( guiChat.GetContentScreenWidth() - 2* panelGap, guiStartYear.GetScreenHeight())

		For Local i:Int = 0 To 3
			Local slotX:Int = i * (playerSlotGap + playerBoxDimension.GetIntX())
			Local playerPanel:TGUIBackgroundBox = New TGUIBackgroundBox.Create(slotX, 0, playerBoxDimension.GetIntX(), playerBoxDimension.GetIntY(), "GameSettings")
			playerPanel.sprite = Assets.GetNinePatchSprite("gfx_gui_panel.subContent.bright")
			playerPanel.SetPadding(playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap)
			guiPlayersPanel.AddChild(playerPanel)

			guiPlayerNames[i] = New TGUIinput.Create(0, 0, playerPanel.GetContentScreenWidth(), -1, Game.Players[i + 1].Name, 16, name)
			guiPlayerNames[i].SetOverlay(Assets.GetSprite("gfx_gui_overlay_player"))

			guiChannelNames[i] = New TGUIinput.Create(0, 0,  playerPanel.GetContentScreenWidth(), -1, Game.Players[i + 1].channelname, 16, name)
			guiChannelNames[i].rect.position.SetY(playerPanel.GetContentScreenHeight() - guiChannelNames[i].rect.GetH())
			guiChannelNames[i].SetOverlay(Assets.GetSprite("gfx_gui_overlay_tvchannel"))

			'left arrow
			guiFigureArrows[i*2 + 0] = New TGUIArrowButton.Create(TRectangle.Create(0 + 10, 50, 24,24), "LEFT", name)
			'right arrow
			guiFigureArrows[i*2 + 1] = New TGUIArrowButton.Create(TRectangle.Create(playerPanel.GetContentScreenWidth() - 10, 50, 24,24), "RIGHT", name)
			guiFigureArrows[i*2 + 1].rect.position.MoveXY(-guiFigureArrows[i*2 + 1].GetScreenWidth(),0)

			playerPanel.AddChild(guiPlayerNames[i])
			playerPanel.AddChild(guiChannelNames[i])
			playerPanel.AddChild(guiFigureArrows[i*2 + 0])
			playerPanel.AddChild(guiFigureArrows[i*2 + 1])
		Next


		'===== REGISTER EVENTS =====
		'register changes to GameSettingsStartYear-guiInput
		EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiStartYear)
		'register checkbox changes
		EventManager.registerListenerMethod("guiCheckBox.onSetChecked", Self, "onCheckCheckboxes", "TGUICheckbox")

		'register changes to player or channel name
		For Local i:Int = 0 To 3
			EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiPlayerNames[i])
			EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiChannelNames[i])
		Next

		'handle clicks on the gui objects
		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickButtons", "TGUIButton")
		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickArrows", "TGUIArrowButton")

		Return Self
	End Method


	'handle clicks on the buttons
	Method onClickArrows:Int(triggerEvent:TEventBase)
		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent._sender)
		If Not sender Then Return False

		'left/right arrows to change figure base
		For Local i:Int = 0 To 7
			If sender = guiFigureArrows[i]
				If i Mod 2  = 0 Then Game.Players[1+Ceil(i/2)].UpdateFigureBase(Game.Players[Ceil(1+i/2)].figurebase -1)
				If i Mod 2 <> 0 Then Game.Players[1+Ceil(i/2)].UpdateFigureBase(Game.Players[Ceil(1+i/2)].figurebase +1)
				modifiedPlayers = True
			EndIf
		Next
	End Method


	'handle clicks on the buttons
	Method onClickButtons:Int(triggerEvent:TEventBase)
		Local sender:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not sender Then Return False


		Select sender
			Case guiButtonStart
					'load databases, populationmap, ...
					Game.Initialize()


					If Not Game.networkgame And Not Game.onlinegame
						Game.SetGamestate(TGame.STATE_INITIALIZEGAME)
						If Not Init_Complete
							Init_All()
							Init_Complete = True		'check if rooms/colors/... are initiated
						EndIf
						Game.Start()
						Game.SetGamestate(TGame.STATE_RUNNING)
					Else
						'guiAnnounce.SetChecked(False)
						Network.StopAnnouncing()
						Interface.ShowChannel = Game.playerID

						Game.SetGamestate(TGame.STATE_STARTMULTIPLAYER)
					EndIf

			Case guiButtonBack
					If Game.networkgame
						If Game.networkgame Then Network.DisconnectFromServer()
						Game.playerID = 1
						Game.SetGamestate(TGame.STATE_NETWORKLOBBY)
						'guiAnnounce.SetChecked(FALSE)
						Network.StopAnnouncing()
					Else
						Game.SetGamestate(TGame.STATE_MAINMENU)
					EndIf
		End Select
	End Method


	Method onCheckCheckboxes:Int(triggerEvent:TEventBase)
		Local sender:TGUICheckBox = TGUICheckBox(triggerEvent.GetSender())
		If Not sender Then Return False

		Select sender
			Case guiFilterUnreleased
					'ATTENTION: use "not" as checked means "not ignore"
					'TProgrammeLicence.setIgnoreUnreleasedProgrammes( not sender.isChecked())
		End Select

		If sender.isChecked()
			TGame.SendSystemMessage(GetLocale("OPTION_ON")+": "+sender.GetValue())
		Else
			TGame.SendSystemMessage(GetLocale("OPTION_OFF")+": "+sender.GetValue())
		EndIf
	End Method


	Method onChangeGameSettingsInputs(triggerEvent:TEventBase)
		Local sender:TGUIObject = TGUIObject(triggerEvent.GetSender())
		Local value:String = triggerEvent.GetData().getString("value")

		'name or channel changed?
		For Local i:Int = 0 To 3
			If sender = guiPlayerNames[i] Then Game.Players[i+1].Name = value
			If sender = guiChannelNames[i] Then Game.Players[i+1].channelName = value
		Next

		'start year changed
		If sender = guiStartYear
			Game.setStartYear( Max(1980, Int(value)) )
			TGUIInput(sender).value = Max(1980, Int(value))
		EndIf
	End Method


	Method Draw:int(tweenValue:float)
		DrawMenuBackground(True)

		'background gui items
		GUIManager.Draw("GameSettings", 0, 100)

		Local slotPos:TPoint = TPoint.Create(guiPlayersPanel.GetContentScreenX(),guiPlayersPanel.GetContentScreeny())
		For Local i:Int = 0 To 3
			If Game.networkgame Or Game.playerID=1
				If Game.gamestate <> TGame.STATE_STARTMULTIPLAYER And Game.Players[i+1].Figure.ControlledByID = Game.playerID Or (Game.Players[i+1].Figure.ControlledByID = 0 And Game.playerID=1)
					SetColor 255,255,255
				Else
					SetColor 225,255,150
				EndIf
			EndIf

			'draw colors
			Local colorRect:TRectangle = TRectangle.Create(slotPos.GetIntX()+2, Int(guiChannelNames[i].GetContentScreenY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)
			For Local obj:TColor = EachIn TColor.List
				If obj.ownerID = 0
					colorRect.position.MoveXY(colorRect.GetW(), 0)
					obj.SetRGB()
					DrawRect(colorRect.GetX(), colorRect.GetY(), colorRect.GetW(), colorRect.GetH())
				EndIf
			Next

			'draw player figure
			SetColor 255,255,255
			Game.GetPlayer(i+1).Figure.Sprite.Draw(Int(slotPos.GetX() + playerBoxDimension.GetX()/2 - Game.Players[1].Figure.Sprite.framew / 2), Int(colorRect.GetY() - Game.Players[1].Figure.Sprite.area.GetH()), 8)

			'move to next slot position
			slotPos.MoveXY(playerSlotGap + playerBoxDimension.GetX(), 0)
		Next

		'overlay gui items (higher zindex)
		GUIManager.Draw("GameSettings", 101)
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)


		If Game.networkgame
			If Not Game.isGameLeader()
				guiButtonStart.disable()
			Else
				guiButtonStart.enable()
			EndIf
			'guiChat.setOption(GUI_OBJECT_VISIBLE,True)
			If Not Game.onlinegame
				guiSettingsWindow.SetCaption(GetLocale("MENU_NETWORKGAME"))
			Else
				guiSettingsWindow.SetCaption(GetLocale("MENU_ONLINEGAME"))
			EndIf

			'guiAnnounce.show()
			guiGameTitle.show()
			guiGameTitleLabel.show()

			'If guiAnnounce.isChecked() And Game.isGameLeader()
			If Game.isGameLeader()
				'guiAnnounce.enable()
				guiGameTitle.disable()
				If guiGameTitle.Value = "" Then guiGameTitle.Value = "no title"
				Game.title = guiGameTitle.Value
			Else
				guiGameTitle.enable()
			EndIf
			If Not Game.isGameLeader()
				guiGameTitle.disable()
				'guiAnnounce.disable()
			EndIf

			'disable/enable announcement on lan/online
			'if guiAnnounce.isChecked()
				Network.client.playerName = Game.Players[ Game.playerID ].name
				If Not Network.announceEnabled Then Network.StartAnnouncing(Game.title)
			'else
			'	Network.StopAnnouncing()
			'endif
		Else
			guiSettingsWindow.SetCaption(GetLocale("MENU_SOLO_GAME"))
			'guiChat.setOption(GUI_OBJECT_VISIBLE,False)


			'guiAnnounce.hide()
			guiGameTitle.disable()
		EndIf

		For Local i:Int = 0 To 3
			If Game.networkgame Or Game.isGameLeader()
				If Game.gamestate <> TGame.STATE_STARTMULTIPLAYER And Game.Players[i+1].Figure.ControlledByID = Game.playerID Or (Game.Players[i+1].Figure.ControlledByID = 0 And Game.playerID=1)
					guiPlayerNames[i].enable()
					guiChannelNames[i].enable()
					guiFigureArrows[i*2].enable()
					guiFigureArrows[i*2 +1].enable()
				Else
					guiPlayerNames[i].disable()
					guiChannelNames[i].disable()
					guiFigureArrows[i*2].disable()
					guiFigureArrows[i*2 +1].disable()
				EndIf
			EndIf
		Next

		GUIManager.Update("GameSettings")


		'not final !
		If KEYMANAGER.isDown(KEY_ENTER)
			If Not GUIManager.GetFocus()
				GUIManager.SetFocus(guiChat.guiInput)
				'KEYMANAGER.blockKey(KEY_ENTER, 200) 'block for 100ms
				'KEYMANAGER.resetKey(KEY_ENTER)
			EndIf
		EndIf

		'clicks on color rect
		Local i:Int = 0

	'	rewrite to Assets instead of global list in TColor ?
	'	local colors:TList = Assets.GetList("PlayerColors")

		If MOUSEMANAGER.IsHit(1)
			Local slotPos:TPoint = TPoint.Create(guiPlayersPanel.GetContentScreenX(),guiPlayersPanel.GetContentScreeny())
			For Local i:Int = 0 To 3
				Local colorRect:TRectangle = TRectangle.Create(slotPos.GetIntX() + 2, Int(guiChannelNames[i].GetContentScreenY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)

				For Local obj:TColor = EachIn TColor.List
					'only for unused colors
					If obj.ownerID <> 0 Then Continue

					colorRect.position.MoveXY(colorRect.GetW(), 0)

					'skip if outside of rect
					If Not TFunctions.MouseInRect(colorRect) Then Continue
					If (Game.Players[i+1].Figure.ControlledByID = Game.playerID Or (Game.Players[i+1].Figure.ControlledByID = 0 And Game.playerID = 1))
						modifiedPlayers=True
						Game.Players[i+1].RecolorFigure(obj)
					EndIf
				Next
				'move to next slot position
				slotPos.MoveXY(playerSlotGap + playerBoxDimension.GetX(), 0)
			Next
		EndIf


		If Game.networkgame = 1
			'sync if the player got modified
			If modifiedPlayers
				NetworkHelper.SendPlayerDetails()
				PlayerDetailsTimer = MilliSecs()
			EndIf
			'sync in all cases every 1 second
			If MilliSecs() >= PlayerDetailsTimer + 1000
				NetworkHelper.SendPlayerDetails()
				PlayerDetailsTimer = MilliSecs()
			EndIf
		EndIf
	End Method
End Type




'MENU: NETWORK LOBBY
Type TScreen_NetworkLobby Extends TGameScreen
	Field guiButtonJoin:TGUIButton
	Field guiButtonCreate:TGUIButton
	Field guiButtonBack:TGUIButton
	Field guiGameListWindow:TGUIGameWindow
	Field guiGameList:TGUIGameList			'available games list


	Method Create:TScreen_NetworkLobby(name:String)
		Super.Create(name)
		self.background = background


		'create and setup GUI objects
		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		local panelGap:int = GUIManager.config.GetInt("panelGap", 10)
		guiButtonsWindow = New TGUIGameWindow.Create(590, 355, 200, 235, name)
		guiButtonsWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.SetCaption("")
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsPanel = guiButtonsWindow.AddContentBox(0,0,-1,-1)


		guiButtonJoin	= New TGUIButton.Create(TPoint.Create(0, 0), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_JOIN"), name, Assets.fonts.baseFontBold)
		guiButtonCreate	= New TGUIButton.Create(TPoint.Create(0, 45), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_CREATE_GAME"), name, Assets.fonts.baseFontBold)
		guiButtonBack	= New TGUIButton.Create(TPoint.Create(0, guiButtonsPanel.GetcontentScreenHeight() - guiButtonJoin.GetScreenHeight()), guiButtonsPanel.GetContentScreenWidth(), GetLocale("MENU_BACK"), name, Assets.fonts.baseFontBold)

		guiButtonsPanel.AddChild(guiButtonJoin)
		guiButtonsPanel.AddChild(guiButtonCreate)
		guiButtonsPanel.AddChild(guiButtonBack)

		guiButtonJoin.disable() 'until an entry is clicked


		'GameList
		'contained within a window/panel for styling
		guiGameListWindow = New TGUIGameWindow.Create(20, 355, 520, 235, name)
		guiGameListWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiGameListWindow.guiBackground.spriteAlpha = 0.5
		guiGameListWindow.SetCaption(GetLocale("AVAILABLE_GAMES"))

		guiGameList	= New TGUIGameList.Create(20,355,520,235,name)
		guiGameList.SetBackground(Null)
		guiGameList.SetPadding(0, 0, 0, 0)

		Local guiGameListPanel:TGUIBackgroundBox = guiGameListWindow.AddContentBox(0,0,-1,-1)
		guiGameListPanel.AddChild(guiGameList)


		'register clicks on TGUIGameEntry-objects -> game list
		EventManager.registerListenerMethod("guiobject.onDoubleClick", Self, "onDoubleClickGameListEntry", "TGUIGameEntry")
		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickButtons", "TGUIButton")

		'register to network game announcements
		EventManager.registerListenerMethod("network.onReceiveAnnounceGame", Self, "onReceiveAnnounceGame")

		Return Self
	End Method


	Method onReceiveAnnounceGame:Int(triggerEvent:TEventBase)
		Local evData:TData = triggerEvent.GetData()
		guiGameList.addItem( New TGUIGameEntry.CreateSimple(..
				DottedIP(evData.GetInt("hostIP", 0)),..
				evData.GetInt("hostPort", 0),..
				evData.GetString("hostName", "Mr. X"),..
				evData.GetString("gameTitle", "unknown"),..
				evData.GetInt("slotsUsed", 1),..
				evData.GetInt("slotsMax", 1)..
		) )
	End Method


	'Doubleclick-function for NetGameLobby_GameList
	Method onDoubleClickGameListEntry:Int(triggerEvent:TEventBase)
		Local entry:TGUIGameEntry = TGUIGameEntry(triggerEvent.getSender())
		If Not entry Then Return False

		JoinSelectedGameEntry()
		Return False
	End Method


	'handle clicks on the buttons
	Method onClickButtons:Int(triggerEvent:TEventBase)
		Local sender:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not sender Then Return False

		Select sender
			Case guiButtonCreate
					'guiButtonStart.enable()
					Game.SetGamestate(TGame.STATE_SETTINGSMENU)
					Network.localFallbackIP = HostIp(game.userFallbackIP)
					Network.StartServer()
					Network.ConnectToLocalServer()
					Network.client.playerID	= 1

			Case guiButtonJoin
					JoinSelectedGameEntry()

			Case guiButtonBack
					Game.SetGamestate(TGame.STATE_MAINMENU)
					Game.onlinegame = False
					If Network.infoStream Then Network.infoStream.close()
					Game.networkgame = False
		End Select
	End Method


	Method JoinSelectedGameEntry:Int()
		'try to get information about a clicked item
		Local entry:TGUIGameEntry = TGUIGameEntry(guiGamelist.getSelectedEntry())
		If Not entry Then Return False

		'guiButtonStart.disable()
		Local _hostIP:String = entry.data.getString("hostIP","0.0.0.0")
		Local _hostPort:Int = entry.data.getInt("hostPort",0)
		Local gameTitle:String = entry.data.getString("gameTitle","#unknowngametitle#")

		If Network.ConnectToServer( HostIp(_hostIP), _hostPort )
			Network.isServer = False
			Game.SetGameState(TGame.STATE_SETTINGSMENU)
			ScreenGameSettings.guiGameTitle.Value = gameTitle
		EndIf
	End Method


	Method Draw:int(tweenValue:float)
		DrawMenuBackground(True)

		If Not Game.onlinegame
			guiGameListWindow.SetCaption(Localization.GetString("MENU_NETWORKGAME")+" : "+Localization.GetString("MENU_AVAILABLE_GAMES"))
		Else
			guiGamelistWindow.SetCaption(Localization.GetString("MENU_ONLINEGAME")+" : "+Localization.GetString("MENU_AVAILABLE_GAMES"))
		EndIf

		GUIManager.Draw(Self.name)
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)
		'register for events if not done yet
		NetworkHelper.RegisterEventListeners()

		If Game.onlinegame
			If Network.OnlineIP = ""
				Local Onlinestream:TStream	= ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=MyIP")
				Local timeouttimer:Int		= MilliSecs()+5000 '5 seconds okay?
				Local timeout:Byte			= False
				If Not Onlinestream Then Throw ("Not Online?")
				While Not Eof(Onlinestream) Or timeout
					If timeouttimer < MilliSecs() Then timeout = True
					Local responsestring:String = ReadLine(Onlinestream)
					Local responseArray:String[] = responsestring.split("|")
					If responseArray <> Null
						Network.OnlineIP = responseArray[0]
						Network.intOnlineIP = HostIp(Network.OnlineIP)
						Print "set your onlineIP"+responseArray[0]
					EndIf
				Wend
				CloseStream Onlinestream
			Else
				If Network.LastOnlineRequestTimer + Network.LastOnlineRequestTime < MilliSecs()
	'TODO: [ron] rewrite handling
					Network.LastOnlineRequestTimer = MilliSecs()
					Local Onlinestream:TStream   = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=ListGames")
					Local timeouttimer:Int = MilliSecs()+2500 '2.5 seconds okay?
					Local timeout:Byte = False
					If Not Onlinestream Then Throw ("Not Online?")
					While Not Eof(Onlinestream) Or timeout
						If timeouttimer < MilliSecs() Then timeout = True
						Local responsestring:String = ReadLine(Onlinestream)
						Local responseArray:String[] = responsestring.split("|")
						If responseArray <> Null
							Local gameTitle:String	= "[ONLINE] "+Network.URLDecode(responseArray[0])
							Local slotsUsed:Int		= Int(responseArray[1])
							Local slotsMax:Int		= 4
							Local _hostName:String	= "#unknownplayername#"
							Local _hostIP:String	= responseArray[2]
							Local _hostPort:Int		= Int(responseArray[3])

							guiGamelist.addItem( New TGUIGameEntry.CreateSimple(_hostIP, _hostPort, _hostName, gameTitle, slotsUsed, slotsMax) )
							Print "added "+gameTitle
						EndIf
					Wend
					CloseStream Onlinestream
				EndIf
			EndIf
		EndIf

		GUIManager.Update(Self.name)
	End Method
End Type




'SCREEN: START MULTIPLAYER
Type TScreen_StartMultiplayer Extends TGameScreen
	Field SendGameReadyTimer:Int = 0
	Field StartMultiplayerSyncStarted:Int = 0


	Method Create:TScreen_StartMultiplayer(name:String)
		Super.Create(name)
		self.background = background
		Return Self
	End Method


	Method Draw:int(tweenValue:float)
		'as background the settings screen
		ScreenCollection.GetScreen("GameSettings").Draw(tweenValue)

		SetColor 180,180,200
		SetAlpha 0.5
		DrawRect 200,200,400,200
		SetAlpha 1.0
		SetColor 0,0,0
		Assets.fonts.baseFont.draw(GetLocale("SYNCHRONIZING_START_CONDITIONS")+"...", 220,220)
		Assets.fonts.baseFont.draw(GetLocale("STARTING_NETWORKGAME")+"...", 220,240)


		SetColor 180,180,200
		SetAlpha 1.0
		DrawRect 200,200,400,200
		SetAlpha 1.0
		SetColor 0,0,0
		Assets.fonts.baseFont.draw(GetLocale("SYNCHRONIZING_START_CONDITIONS")+"...", 220,220)
		Assets.fonts.baseFont.draw(GetLocale("STARTING_NETWORKGAME")+"...", 220,240)
		Assets.fonts.baseFont.draw("Player 1..."+Game.Players[1].networkstate+" MovieListCount: "+Game.Players[1].ProgrammeCollection.GetProgrammeLicenceCount(), 220,260)
		Assets.fonts.baseFont.draw("Player 2..."+Game.Players[2].networkstate+" MovieListCount: "+Game.Players[2].ProgrammeCollection.GetProgrammeLicenceCount(), 220,280)
		Assets.fonts.baseFont.draw("Player 3..."+Game.Players[3].networkstate+" MovieListCount: "+Game.Players[3].ProgrammeCollection.GetProgrammeLicenceCount(), 220,300)
		Assets.fonts.baseFont.draw("Player 4..."+Game.Players[4].networkstate+" MovieListCount: "+Game.Players[4].ProgrammeCollection.GetProgrammeLicenceCount(), 220,320)
		If Not Game.networkgameready = 1 Then Assets.fonts.baseFont.draw("not ready!!", 220,360)
		SetColor 255,255,255
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)
		'master should spread startprogramme around
		If Game.isGameLeader() And Not StartMultiplayerSyncStarted
			StartMultiplayerSyncStarted = MilliSecs()

			For Local playerids:Int = 1 To 4
				Local ProgrammeCollection:TPlayerProgrammeCollection = Game.getPlayer(playerids).ProgrammeCollection
				Local ProgrammeArray:TProgramme[Game.startMovieAmount + Game.startSeriesAmount + 1]
				For Local i:Int = 0 To Game.startMovieAmount-1
					ProgrammeCollection.AddProgrammeLicence(TProgrammeLicence.GetRandom(TProgrammeLicence.TYPE_MOVIE))
				Next
				'give series to each player
				For Local i:Int= 0 To Game.startSeriesAmount-1
					ProgrammeCollection.AddProgrammeLicence(TProgrammeLicence.GetRandom(TProgrammeLicence.TYPE_SERIES))
				Next
				'give 1 call in
				ProgrammeCollection.AddProgrammeLicence(TProgrammeLicence.GetRandomWithGenre(20))

				For Local j:Int = 0 To Game.startAdAmount-1
					ProgrammeCollection.AddAdContract(New TAdContract.Create(TAdContractBase.GetRandomWithLimitedAudienceQuote(0.0, 0.15)))
				Next
			Next
		EndIf
		'ask every 500ms
		If Game.isGameLeader() And SendGameReadyTimer < MilliSecs()
			Game.SetGamestate(TGame.STATE_STARTMULTIPLAYER)
			NetworkHelper.SendGameReady(Game.playerID)
			SendGameReadyTimer = MilliSecs() +500
		EndIf

		If Game.networkgameready=1
			'ScreenGameSettings.guiAnnounce.SetChecked(FALSE)
			Game.Players[Game.playerID].networkstate=1

			'we have to set gamestate BEFORE init_all()
			'as init_all sends events which trigger gamestate-update/draw
			Game.SetGamestate(TGame.STATE_INITIALIZEGAME)

			If Not Init_Complete
				Init_All()
				Init_Complete = True		'check if rooms/colors/... are initiated
			EndIf

			'register events and start game
			Game.Start()
			Game.SetGamestate(TGame.STATE_RUNNING)
			'reset randomizer
			Game.SetRandomizerBase( Game.GetRandomizerBase() )

			Return True
		Else
			'go back to game settings if something takes longer than expected
			If MilliSecs() - StartMultiplayerSyncStarted > 10000
				Print "sync timeout"
				StartMultiplayerSyncStarted = 0
				game.SetGamestate(TGame.STATE_SETTINGSMENU)
				Return False
			EndIf
		EndIf
	End Method
End Type



Type GameEvents
	Function PlayersOnMinute:Int(triggerEvent:TEventBase)
		Local minute:Int = triggerEvent.GetData().getInt("minute",-1)
		If minute < 0 Then Return False

		For Local player:TPLayer = EachIn Game.players
			If player.isAI() Then player.PlayerKI.CallOnMinute(minute)
		Next
		Return True
	End Function


	Function PlayersOnDay:Int(triggerEvent:TEventBase)
		Local minute:Int = triggerEvent.GetData().getInt("minute",-1)
		If minute < 0 Then Return False

		For Local player:TPLayer = EachIn Game.players
			If player.isAI() Then player.PlayerKI.CallOnDayBegins()
		Next
		Return True
	End Function


	Function OnMinute:Int(triggerEvent:TEventBase)
		'things happening x:05
		Local minute:Int = triggerEvent.GetData().GetInt("minute",-1)
		Local hour:Int = triggerEvent.GetData().GetInt("hour",-1)
		Local day:Int = triggerEvent.GetData().GetInt("day",-1)
		If hour = -1 Then Return False

		'===== UPDATE POPULARITY MANAGER =====
		'the popularity manager takes care itself whether to do something
		'or not (update intervals)
		Game.PopularityManager.Update(triggerEvent)

		'===== CHANGE OFFER OF MOVIEAGENCY AND ADAGENCY =====
		'countdown for the refillers
		Game.refillMovieAgencyTime :-1
		Game.refillAdAgencyTime :-1
		'refill if needed
		If Game.refillMovieAgencyTime <= 0
			'delay if there is one in this room
			If RoomCollection.GetFirstByDetails("movieagency").hasOccupant()
				Game.refillMovieAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				Game.refillMovieAgencyTime = Game.refillMovieAgencyTimer + randrange(0,20)-10

				TDevHelper.Log("GameEvents.OnMinute", "partly refilling movieagency", LOG_DEBUG)
				RoomHandler_movieagency.GetInstance().ReFillBlocks(True, 0.5)
			EndIf
		EndIf
		If Game.refillAdAgencyTime <= 0
			'delay if there is one in this room
			If RoomCollection.GetFirstByDetails("adagency").hasOccupant()
				Game.refillAdAgencyTime :+ 15
				Game.refillAdAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				Game.refillAdAgencyTime = Game.refillAdAgencyTimer + randrange(0,20)-10

				TDevHelper.Log("GameEvents.OnMinute", "partly refilling adagency", LOG_DEBUG)
				RoomHandler_adagency.GetInstance().ReFillBlocks(True, 0.5)
			EndIf
		EndIf


		'for all
		If minute = 5 Or minute = 55 Or minute = 0 Then Interface.BottomImgDirty = True

		'begin of all newshows - compute their audience
		If minute = 0
			For Local player:TPlayer = EachIn Game.Players
				player.ProgrammePlan.GetNewsShow().BeginBroadcasting(day, hour, minute)
			Next
			Game.BroadcastManager.BroadcastNewsShow(day, hour)
		'begin of a programme
		ElseIf minute = 5
			For Local player:TPlayer = EachIn Game.Players
				Local obj:TBroadcastMaterial = player.ProgrammePlan.GetProgramme(day, hour)
				If obj
					If 1 = player.ProgrammePlan.GetProgrammeBlock(day, hour)
						obj.BeginBroadcasting(day, hour, minute) 'just starting
					Else
						obj.ContinueBroadcasting(day, hour, minute)
					EndIf
				EndIf
			Next
			Game.BroadcastManager.BroadcastProgramme(day, hour)
		'call-in shows/quiz - generate income
		ElseIf minute = 54
			For Local player:TPlayer = EachIn Game.Players
				Local obj:TBroadcastMaterial = player.ProgrammePlan.GetProgramme(day,hour)
				If obj
					If obj.GetBlocks() = player.ProgrammePlan.GetProgrammeBlock(day, hour)
						obj.FinishBroadcasting(day, hour, minute)
					Else
						obj.BreakBroadcasting(day, hour, minute)
					EndIf
				EndIf
			Next
		'ads
		ElseIf minute = 55
			'computes ads - if an ad is botched or run successful
			'if adcontract finishes, earn money
			For Local player:TPlayer = EachIn Game.Players
				Local obj:TBroadcastMaterial = player.ProgrammePlan.GetAdvertisement(day, hour)
				If obj
					If 1 = player.ProgrammePlan.GetAdvertisementBlock(day, hour)
						obj.BeginBroadcasting(day, hour, minute) 'just starting
					Else
						obj.ContinueBroadcasting(day, hour, minute)
					EndIf
				EndIf
			Next
		'ads end - so trailers can set their "ok"
		ElseIf minute = 59
			For Local player:TPlayer = EachIn Game.Players
				Local obj:TBroadcastMaterial = Player.ProgrammePlan.GetAdvertisement(day, hour)
				If obj
					If obj.GetBlocks() = player.ProgrammePlan.GetAdvertisementBlock(day, hour)
						obj.FinishBroadcasting(day, hour, minute)
					Else
						obj.BreakBroadcasting(day, hour, minute)
					EndIf
				EndIf
			Next
		EndIf

		Return True
	End Function


	'things happening each hour
	Function OnHour:Int(triggerEvent:TEventBase)
		'
	End Function


	Function OnDay:Int(triggerEvent:TEventBase)
		Local day:Int = triggerEvent.GetData().GetInt("day", -1)

		TDevHelper.Log("GameEvents.OnDay", "begin of day "+(Game.GetDaysPlayed()+1)+" (real day: "+day+")", LOG_DEBUG)

		'if new day, not start day
		If Game.GetDaysPlayed() >= 1

			'Neuer Award faellig?
			If Betty.GetAwardEnding() < Game.GetDay() - 1
				Betty.GetLastAwardWinner()
				Betty.SetAwardType(RandRange(0, Betty.MaxAwardTypes), True)
			End If

			TProgrammeData.RefreshAllTopicalities()
			Game.ComputeContractPenalties()
			Game.ComputeDailyCosts()	'first pay everything, then earn...
			Game.ComputeDailyIncome()
			TAuctionProgrammeBlocks.EndAllAuctions() 'won auctions moved to programmecollection of player

			'reset room signs each day to their normal position
			TRoomDoorSign.ResetPositions()

			'remove old news from the players (only unset ones)
			For Local i:Int = 1 To 4
				Local news:TNews
				For news = EachIn Game.getPlayer(i).ProgrammeCollection.news
					If day - Game.GetDay(news.newsEvent.happenedtime) >= 2
						Game.getPlayer(i).ProgrammePlan.RemoveNews(news)
					EndIf
				Next
			Next
		EndIf

		Return True
	End Function
End Type




Type AppEvents
	Global InitDone:Int=False
	Global SimpleSoundSource:TSimpleSoundSource = New TSimpleSoundSource

	Function Init:Int()
		If InitDone Then Return True

		EventManager.registerListenerFunction("guiModalWindow.onClose", onGuiModalWindowClose, "TGUIModalWindow")
		EventManager.registerListenerFunction("guiModalWindow.onCreate", onGuiModalWindowCreate)
		EventManager.registerListenerFunction("app.onStart", onAppStart)
	End Function


	Function onGuiModalWindowClose:Int(triggerEvent:TEventBase)
		'play a sound with the default sfxchannel
		SimpleSoundSource.PlayRandomSfx("gui_close_fade_window")
	End Function


	Function onGuiModalWindowCreate:Int(triggerEvent:TEventBase)
		'play a sound with the default sfxchannel
		SimpleSoundSource.PlayRandomSfx("gui_open_window")
	End Function


	'App is ready ...
	'- create special fonts
	Function onAppStart:Int(triggerEvent:TEventBase)
		If Not headerFont
			TGW_FontManager.GetInstance().AddFont("headerFont", "res/fonts/Vera.ttf", 18)
			TGW_FontManager.GetInstance().AddFont("headerFont", "res/fonts/VeraBd.ttf", 18, BOLDFONT)
			TGW_FontManager.GetInstance().AddFont("headerFont", "res/fonts/VeraBI.ttf", 18, BOLDFONT | ITALICFONT)
			TGW_FontManager.GetInstance().AddFont("headerFont", "res/fonts/VeraIt.ttf", 18, ITALICFONT)

			Local shadowSettings:TData = new TData.addNumber("size", 1).addNumber("intensity", 0.5)
			Local gradientSettings:TData = new TData.addNumber("gradientBottom", 180)
			'setup effects for normal and bold
			headerFont = TGW_FontManager.GetInstance().CopyFont("default", "headerFont", 18, BOLDFONT)
			headerFont.SetCharsEffectFunction(1, Font_AddGradient, gradientSettings)
			headerFont.SetCharsEffectFunction(2, Font_AddShadow, shadowSettings)
			headerFont.InitFont()

			headerFont = TGW_FontManager.GetInstance().GetFont("headerFont", 18, ITALICFONT)
			headerFont.SetCharsEffectFunction(1, Font_AddGradient, gradientSettings)
			headerFont.SetCharsEffectFunction(2, Font_AddShadow, shadowSettings)
			headerFont.InitFont()

			headerFont = TGW_FontManager.GetInstance().GetFont("headerFont", 18)
			headerFont.SetCharsEffectFunction(1, Font_AddGradient, gradientSettings)
			headerFont.SetCharsEffectFunction(2, Font_AddShadow, shadowSettings)
			headerFont.InitFont()
		EndIf
	End Function


	'lower priority updates (currently happening every 2 "appUpdates")
	Function onAppSystemUpdate:Int(triggerEvent:TEventBase)
		TProfiler.Enter("SoundUpdate")
		TSoundManager.GetInstance().Update()
		TProfiler.Leave("SoundUpdate")
	End Function

	'wird ausgeloest wenn OnAppUpdate-Event getriggert wird
	Function onAppUpdate:Int(triggerEvent:TEventBase)
		?Threaded
		LockMutex(RefreshInputMutex)
		RefreshInput = True
		UnlockMutex(RefreshInputMutex)
		?
		?Not Threaded
		KEYMANAGER.Update()
		MOUSEMANAGER.Update()
		?
		'fetch and cache mouse and keyboard states for this cycle
		GUIManager.StartUpdates()

		GUIManager.Update("SYSTEM")
		'as long as the exit dialogue is open, do not accept non-gui-clicks to leave rooms
		If App.ExitAppDialogue
			MouseManager.ResetKey(2)
		EndIf

		'ignore shortcuts if a gui object listens to keystrokes
		'eg. the active chat input field
		If Not GUIManager.GetKeystrokeReceiver()
			'keywrapper has "key every milliseconds" functionality
			If KEYWRAPPER.hitKey(KEY_ESCAPE) Then TApp.CreateConfirmExitAppDialogue()

			If App.devConfig.GetBool("DEV_KEYS", FALSE)
				'(un)mute sound
				'M: (un)mute all sounds
				'SHIFT+M: (un)mute all sound effects
				'CTRL+M: (un)mute all music
				If KEYMANAGER.IsHit(KEY_M)
					if KEYMANAGER.IsDown(KEY_LSHIFT) OR KEYMANAGER.IsDown(KEY_RSHIFT)
						TSoundManager.GetInstance().MuteSfx(not TSoundManager.GetInstance().HasMutedSfx())
					elseif KEYMANAGER.IsDown(KEY_LCONTROL) OR KEYMANAGER.IsDown(KEY_RCONTROL)
						TSoundManager.GetInstance().MuteMusic(not TSoundManager.GetInstance().HasMutedMusic())
					else
						TSoundManager.GetInstance().Mute(not TSoundManager.GetInstance().IsMuted())
					endif
				endif

				If Game.gamestate = TGame.STATE_RUNNING
					If KEYMANAGER.IsDown(KEY_UP) Then Game.speed:+0.10
					If KEYMANAGER.IsDown(KEY_DOWN) Then Game.speed = Max( Game.speed - 0.10, 0)

					If KEYMANAGER.IsHit(KEY_1) Game.SetActivePlayer(1)
					If KEYMANAGER.IsHit(KEY_2) Game.SetActivePlayer(2)
					If KEYMANAGER.IsHit(KEY_3) Game.SetActivePlayer(3)
					If KEYMANAGER.IsHit(KEY_4) Game.SetActivePlayer(4)

					If KEYMANAGER.IsHit(KEY_W) Then DEV_switchRoom(RoomCollection.GetFirstByDetails("adagency") )
					If KEYMANAGER.IsHit(KEY_A) Then DEV_switchRoom(RoomCollection.GetFirstByDetails("archive", Game.playerID) )
					If KEYMANAGER.IsHit(KEY_B) Then DEV_switchRoom(RoomCollection.GetFirstByDetails("betty") )
					If KEYMANAGER.IsHit(KEY_F) Then DEV_switchRoom(RoomCollection.GetFirstByDetails("movieagency"))
					If KEYMANAGER.IsHit(KEY_O) Then DEV_switchRoom(RoomCollection.GetFirstByDetails("office", Game.playerID))
					If KEYMANAGER.IsHit(KEY_C) Then DEV_switchRoom(RoomCollection.GetFirstByDetails("chief", Game.playerID))
					'e wie "employees" :D
					If KEYMANAGER.IsHit(KEY_E) Then DEV_switchRoom(RoomCollection.GetFirstByDetails("credits"))
					If KEYMANAGER.IsHit(KEY_N) Then DEV_switchRoom(RoomCollection.GetFirstByDetails("news", Game.playerID))
					If KEYMANAGER.IsHit(KEY_R) Then DEV_switchRoom(RoomCollection.GetFirstByDetails("roomboard"))
				EndIf
				If KEYMANAGER.IsHit(KEY_5) Then game.speed = 120.0	'60 minutes per second
				If KEYMANAGER.IsHit(KEY_6) Then game.speed = 240.0	'120 minutes per second
				If KEYMANAGER.IsHit(KEY_7) Then game.speed = 360.0	'180 minutes per second
				If KEYMANAGER.IsHit(KEY_8) Then game.speed = 480.0	'240 minute per second
				If KEYMANAGER.IsHit(KEY_9) Then game.speed = 1.0	'1 minute per second
				If KEYMANAGER.IsHit(KEY_Q) Then Game.DebugQuoteInfos = 1 - Game.DebugQuoteInfos
				If KEYMANAGER.IsHit(KEY_P) Then Game.getPlayer().ProgrammePlan.printOverview()

				'Save game
				If KEYMANAGER.IsHit(KEY_S) Then TSaveGame.Save("savegame.xml")
				If KEYMANAGER.IsHit(KEY_L) Then TSaveGame.Load("savegame.xml")

				If KEYMANAGER.IsHit(KEY_D) Then Game.DebugInfos = 1 - Game.DebugInfos

				If Game.isGameLeader()
					If KEYMANAGER.Ishit(Key_F1) And Game.Players[1].isAI() Then Game.Players[1].PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F2) And Game.Players[2].isAI() Then Game.Players[2].PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F3) And Game.Players[3].isAI() Then Game.Players[3].PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F4) And Game.Players[4].isAI() Then Game.Players[4].PlayerKI.reloadScript()
				EndIf

				If KEYMANAGER.Ishit(Key_F5) Then NewsAgency.AnnounceNewNewsEvent()
				If KEYMANAGER.Ishit(Key_F6) Then TSoundManager.GetInstance().PlayMusicPlaylist("default")

				If KEYMANAGER.Ishit(Key_F9)
					If (KIRunning)
						TDevHelper.Log("CORE", "AI deactivated", LOG_INFO | LOG_DEV )
						KIRunning = False
					Else
						TDevHelper.Log("CORE", "AI activated", LOG_INFO | LOG_DEV )
						KIRunning = True
					EndIf
				EndIf
				If KEYMANAGER.Ishit(Key_F10)
					If (KIRunning)
						For Local fig:TFigure = EachIn FigureCollection.list
							If Not fig.isActivePlayer() Then fig.moveable = False
						Next
						TDevHelper.Log("CORE", "AI Figures deactivated", LOG_INFO | LOG_DEV )
						KIRunning = False
					Else
						For Local fig:TFigure = EachIn FigureCollection.list
							If Not fig.isActivePlayer() Then fig.moveable = True
						Next
						TDevHelper.Log("CORE", "AI activated", LOG_INFO | LOG_DEV )
						KIRunning = True
					EndIf
				EndIf
			EndIf
		EndIf


		TError.UpdateErrors()
		Game.cursorstate = 0


		ScreenCollection.UpdateCurrent(App.Timer.getDelta())

		If Not GuiManager.GetKeystrokeReceiver() And KEYWRAPPER.hitKey(KEY_ESCAPE)
			TApp.CreateConfirmExitAppDialogue()
		EndIf
		If AppTerminate() Then TApp.ExitApp = True

		'check if we need to make a screenshot
		If KEYMANAGER.IsHit(KEY_F12) Then App.prepareScreenshot = 1

		If Game.networkGame Then Network.Update()

		GUIManager.EndUpdates() 'reset modal window states
	End Function


	Function onAppDraw:Int(triggerEvent:TEventBase)
		'adjust current tweenFactor
		CURRENT_TWEEN_FACTOR = App.timer.GetTween()

		TProfiler.Enter("Draw")
		ScreenCollection.DrawCurrent(App.timer.GetTween())

		if App.devConfig.GetBool("DEV_OSD", FALSE)
			Local textX:Int = 20
			Assets.fonts.baseFont.draw("Speed:" + Int(Game.GetGameMinutesPerSecond() * 100), textX , 0)
			textX:+80
			Assets.fonts.baseFont.draw("FPS: "+App.Timer.currentFps, textX, 0)
			textX:+60
			Assets.fonts.baseFont.draw("UPS: " + Int(App.Timer.currentUps), textX,0)
			textX:+60
			Assets.fonts.baseFont.draw("Loop: "+Int(App.Timer.getLoopTimeAverage())+"ms", textX,0)
			textX:+100

			'RON: debug purpose - see if the managed guielements list increase over time
			If TGUIObject.GetFocusedObject()
				Assets.fonts.baseFont.draw("GUI objects: "+ GUIManager.list.count()+"[d:"+GUIManager.GetDraggedCount()+"] focused: "+TGUIObject.GetFocusedObject()._id, textX,0)
				textX:+160
			Else
				Assets.fonts.baseFont.draw("GUI objects: "+ GUIManager.list.count()+"[d:"+GUIManager.GetDraggedCount()+"]" , textX,0)
				textX:+130
			EndIf

			If game.networkgame And Network.client
				Assets.fonts.baseFont.draw("Ping: "+Int(Network.client.latency)+"ms", textX,0)
				textX:+50
			EndIf

			If Game.DebugInfos
				SetAlpha 0.75
				SetColor 0,0,0
				DrawRect(20,10,160,373)
				SetColor 255, 255, 255
				SetAlpha 1.0
				Assets.fonts.baseFontBold.draw("Debug information:", 25,20)
				If App.settings.directx = -1 Then Assets.fonts.baseFont.draw("Renderer: OpenGL", 25,40)
				If App.settings.directx = 0  Then Assets.fonts.baseFont.draw("Renderer: BufferedOpenGL", 25,40)
				If App.settings.directx = 1  Then Assets.fonts.baseFont.draw("Renderer: DirectX 7", 25, 40)
				If App.settings.directx = 2  Then Assets.fonts.baseFont.draw("Renderer: DirectX 9", 25,40)

		'		GUIManager.Draw("InGame") 'draw ingamechat
		'		Assets.fonts.baseFont.draw(Network.stream.UDPSpeedString(), 662,490)
				Assets.fonts.baseFont.draw("Player positions:", 25,65)
				local roomName:string = ""
				local fig:TFigure
				For Local i:Int = 0 To 3
					fig = Game.GetPlayer(i+1).figure
					roomName = "Building"
					If fig.inRoom
						roomName = fig.inRoom.Name
					elseif fig.IsInElevator()
						roomName = "InElevator"
					elseIf fig.IsAtElevator()
						roomName = "AtElevator"
					endif
					Assets.fonts.baseFont.draw("P " + (i + 1) + ": "+roomName, 25, 80 + i * 11)
				Next

				if ScreenCollection.GetCurrentScreen()
					Assets.fonts.baseFont.draw("onScreen: "+ScreenCollection.GetCurrentScreen().name, 25, 130)
				else
					Assets.fonts.baseFont.draw("onScreen: Main", 25, 130)
				endif


				Assets.fonts.baseFont.draw("Elevator routes:", 25,150)
				Local routepos:Int = 0
				Local startY:Int = 165
				If Game.networkgame Then startY :+ 4*11

				Local callType:String = ""

				Local directionString:String = "up"
				If Building.elevator.Direction = 1 Then directionString = "down"
				Local debugString:String =	"floor:" + Building.elevator.currentFloor +..
											"->" + Building.elevator.targetFloor +..
											" doorState:"+Building.elevator.ElevatorStatus

				Assets.fonts.baseFont.draw(debugString, 25, startY)


				If Building.elevator.RouteLogic.GetSortedRouteList() <> Null
					For Local FloorRoute:TFloorRoute = EachIn Building.elevator.RouteLogic.GetSortedRouteList()
						If floorroute.call = 0 Then callType = " 'send' " Else callType= " 'call' "
						Assets.fonts.baseFont.draw(FloorRoute.floornumber + callType + FloorRoute.who.Name, 25, startY + 15 + routepos * 11)
						routepos:+1
					Next
				Else
					Assets.fonts.baseFont.draw("recalculate", 25, startY + 15)
				EndIf

				'room states: debug fuer sushitv
				local occupants:string = "-"
				if RoomCollection.GetFirstByDetails("adagency").HasOccupant()
					occupants = ""
					for local figure:TFigure = eachin RoomCollection.GetFirstByDetails("adagency").occupants
						occupants :+ figure.name+" "
					next
				Endif
				Assets.fonts.baseFont.draw("AdA. : "+occupants, 25, 350)

				occupants = "-"
				if RoomCollection.GetFirstByDetails("movieagency").HasOccupant()
					occupants = ""
					for local figure:TFigure = eachin RoomCollection.GetFirstByDetails("movieagency").occupants
						occupants :+ figure.name+" "
					next
				Endif
				Assets.fonts.baseFont.draw("MoA. : "+occupants, 25, 365)

			EndIf
			If Game.DebugQuoteInfos
				Game.DebugAudienceInfo.Draw()
			EndIf
		Endif




		'draw system things at last (-> on top)
		GUIManager.Draw("SYSTEM")

		'default pointer
		If Game.cursorstate = 0 Then Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-9, 	MouseManager.y-2	,0)
		'open hand
		If Game.cursorstate = 1 Then Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-11, 	MouseManager.y-8	,1)
		'grabbing hand
		If Game.cursorstate = 2 Then Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-11,	MouseManager.y-16	,2)

		'if a screenshot is generated, draw a logo in
		If App.prepareScreenshot = 1
			App.SaveScreenshot(Assets.GetSprite("gfx_startscreen_logoSmall"))
			App.prepareScreenshot = False
		EndIf


		If Not App.timer.limitedFPS()
			TProfiler.Enter("Draw-Flip")
			if App.vsync then Flip 1 else Flip 0
			TProfiler.Leave("Draw-Flip")
		Else
			if App.vsync then Flip 1 else Flip -1
		EndIf


		TProfiler.Leave("Draw")
		Return True
	End Function
End Type

'Bis wir nen besseren Platz gefunden haben
Type TTVTException Extends TBlitzException
	Field message:String

	Method ToString:String()
		If message = Null
			Return GetDefaultMessage()
		Else
			Return message
		EndIf
	End Method

	Method GetDefaultMessage:String()
		Return "Undefined TTVTException!"
	End Method
End Type

'Bis wir nen besseren Platz gefunden haben
Type TArgumentException Extends TTVTException
	Field argument:String
	Field value:String

	Method ToString:String()
		If argument = Null
			Super.ToString()
		Else
			If value = Null
				Return "The argument '" + argument + "' is not valid."
			Else
				Return "The argument '" + argument + "' with value '" + value + "' is not valid."
			EndIf
		EndIf
	End Method

	Method GetDefaultMessage:String()
		Return "An argument is not valid."
	End Method

	Function Create:TArgumentException( argument:String, value:String = null, message:String = Null )
		Local t:TArgumentException = New TArgumentException
		t.argument = argument
		t.value = value
		t.message = message
		Return t
	End Function
End Type


OnEnd( EndHook )
Function EndHook()
	TProfiler.DumpLog("log.profiler.txt")
	TLogFile.DumpLog(False)
End Function


'===== COMMON FUNCTIONS =====

Function DrawMenuBackground(darkened:Int=False)
	'no cls needed - we render a background
	'Cls
	SetColor 255,255,255
	Assets.GetSprite("gfx_startscreen").Draw(0,0)


	Select game.gamestate
		Case TGame.STATE_NETWORKLOBBY, TGame.STATE_MAINMENU
			If LogoCurrY > LogoTargetY Then LogoCurrY:+- 30.0 * App.Timer.getDelta() Else LogoCurrY = LogoTargetY
			Assets.GetSprite("gfx_startscreen_logo").Draw(400, LogoCurrY, 0, TPoint.Create(ALIGN_CENTER, ALIGN_TOP))
	EndSelect

	If game.gamestate = TGame.STATE_MAINMENU
		SetColor 255,255,255
		Assets.GetFont("Default",11, ITALICFONT).drawBlock(versionstring, 10,575, 500,20, Null,TColor.Create(75,75,140))
		Assets.GetFont("Default",11, ITALICFONT).drawBlock(copyrightstring, 10,585, 500,20, Null,TColor.Create(60,60,120))
	EndIf

	If darkened
		SetColor 190,220,240
		SetAlpha 0.5
		DrawRect(0,0,App.settings.GetWidth(),App.settings.GetHeight())
		SetAlpha 1.0
		SetColor 255, 255, 255
	EndIf
End Function

Function Init_Creation()
	'create base stations
	For Local i:Int = 1 To 4
		Game.GetPlayer(i).GetStationMap().AddStation( TStation.Create( TPoint.Create(310, 260),-1, StationMapCollection.stationRadius, i ), False )
	Next

	'get names from settings
	For Local i:Int = 1 To 4
		Game.Players[i].Name		= ScreenGameSettings.guiPlayerNames[i-1].Value
		Game.Players[i].channelname	= ScreenGameSettings.guiChannelNames[i-1].Value
	Next


	'set all non human players to AI
	If Game.isGameLeader()
		For Local playerids:Int = 1 To 4
			If Game.IsPlayer(playerids) And Not Game.IsHumanPlayer(playerids)
				Game.Players[playerids].SetAIControlled("res/ai/DefaultAIPlayer.lua")
			EndIf
		Next
		'register ai player events - but only for game leader
		EventManager.registerListenerFunction("Game.OnMinute",	GameEvents.PlayersOnMinute)
		EventManager.registerListenerFunction("Game.OnDay", 	GameEvents.PlayersOnDay)
	EndIf

	'create series/movies in movie agency
	RoomHandler_MovieAgency.GetInstance().ReFillBlocks()

	'8 auctionable movies/series
	For Local i:Int = 0 To 7
		New TAuctionProgrammeBlocks.Create(i, Null)
	Next


	'create random programmes and so on - but only if local game
	If Not Game.networkgame
		For Local playerids:Int = 1 To 4
			Local ProgrammeCollection:TPlayerProgrammeCollection = Game.getPlayer(playerids).ProgrammeCollection
			For Local i:Int = 0 To Game.startMovieAmount-1
				ProgrammeCollection.AddProgrammeLicence(TProgrammeLicence.GetRandom(TProgrammeLicence.TYPE_MOVIE))
			Next
			'give series to each player
			For Local i:Int = Game.startMovieAmount To Game.startMovieAmount + Game.startSeriesAmount-1
				ProgrammeCollection.AddProgrammeLicence(TProgrammeLicence.GetRandom(TProgrammeLicence.TYPE_SERIES))
			Next
			'give 1 call in
			ProgrammeCollection.AddProgrammeLicence(TProgrammeLicence.GetRandomWithGenre(20))

			For Local i:Int = 0 To 2
				ProgrammeCollection.AddAdContract(New TAdContract.Create(TAdContractBase.GetRandomWithLimitedAudienceQuote(0, 0.15)) )
			Next
		Next
	EndIf
	'abonnement for each newsgroup = 1

	For Local playerids:Int = 1 To 4
		'5 groups
		For Local i:Int = 0 To 4
			Game.Players[playerids].SetNewsAbonnement(i, 1)
		Next
	Next


	Local lastblocks:Int=0
	'creation of blocks for players rooms
	For Local playerids:Int = 1 To 4
		lastblocks = 0
		SortList(Game.Players[playerids].ProgrammeCollection.adContracts)

		Local addWidth:Int = Assets.GetSprite("pp_programmeblock1").area.GetW()
		Local addHeight:Int = Assets.GetSprite("pp_adblock1").area.GetH()
		Local playerCollection:TPlayerProgrammeCollection = Game.getPlayer(playerids).ProgrammeCollection
		Local playerPlan:TPlayerProgrammePlan = Game.getPlayer(playerids).ProgrammePlan

		playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 0 )
		playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 1 )
		playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 2 )
		playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 3 )
		playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 4 )
		playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 5 )

		Local currentLicence:TProgrammeLicence = Null
		Local currentHour:Int = 0
		For Local i:Int = 0 To 3
			currentLicence = playerCollection.GetMovieLicenceAtIndex(i)
			If Not currentLicence Then Continue
			playerPlan.SetProgrammeSlot(TProgramme.Create(currentLicence), Game.GetStartDay(), currentHour )
			currentHour:+ currentLicence.getData().getBlocks()
		Next
	Next
End Function

Function Init_Colorization()
	'colorize the images
	Local gray:TColor = TColor.Create(200, 200, 200)
	Local gray2:TColor = TColor.Create(100, 100, 100)
	'unused: Assets.AddImageAsSprite("gfx_financials_barren_0", Assets.GetSprite("gfx_officepack_financials_barren").GetColorizedImage(gray))
	Assets.AddImageAsSprite("gfx_building_sign_0", Assets.GetSprite("gfx_building_sign_base").GetColorizedImage(gray))
	Assets.AddImageAsSprite("gfx_elevator_sign_0", Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage(gray))
	Assets.AddImageAsSprite("gfx_elevator_sign_dragged_0", Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage(gray))
	Assets.AddImageAsSprite("gfx_interface_channelbuttons_off_0", Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage(gray2))
	Assets.AddImageAsSprite("gfx_interface_channelbuttons_on_0", Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage(gray2))

	'colorizing for every player
	For Local i:Int = 1 To 4
		Game.GetPlayer(i).RecolorFigure()
		local color:TColor = Game.GetPlayer(i).color
		'unused: Assets.AddImageAsSprite("gfx_financials_barren_"+i, Assets.GetSprite("gfx_officepack_financials_barren").GetColorizedImage(color))
		Assets.AddImageAsSprite("gfx_building_sign_"+i, Assets.GetSprite("gfx_building_sign_base").GetColorizedImage(color))
		Assets.AddImageAsSprite("gfx_elevator_sign_"+i, Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage(color))
		Assets.AddImageAsSprite("gfx_elevator_sign_dragged_"+i, Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage(color))
		Assets.AddImageAsSprite("gfx_interface_channelbuttons_off_"+i, Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage(color, i))
		Assets.AddImageAsSprite("gfx_interface_channelbuttons_on_"+i, Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage(color, i))
	Next
End Function


Function Init_All()
	TDevHelper.Log("Init_All()", "start", LOG_DEBUG)
	Init_Creation()

	TDevHelper.Log("Init_All()", "colorizing images corresponding to playercolors", LOG_DEBUG)
	Init_Colorization()
	'triggering that event also triggers app.timer.loop which triggers update/draw of
	'gamesstates - which runs this again etc.
	EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", new TData.AddString("text", "Create Roomtooltips").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )

	TDevHelper.Log("Init_All()", "drawing door-sprites on the building-sprite", LOG_DEBUG)
	TRoomDoor.DrawDoorsOnBackground()		'draws the door-sprites on the building-sprite

	TDevHelper.Log("Init_All()", "drawing plants and lights on the building-sprite", LOG_DEBUG)
	Building.Init()	'draws additional gfx in the sprite, registers events...

	TDevHelper.Log("Init_All()", "complete", LOG_LOADING)
End Function


Function DEV_switchRoom:int(room:TRoom)
	if not room then return FALSE
	local figure:TFigure = Game.GetPlayer().figure

	local oldEffects:int = TScreenCollection.useChangeEffects
	local oldSpeed:int = TRoom.ChangeRoomSpeed

	'to avoid seeing too much animation
	TRoom.ChangeRoomSpeed = 0
	TScreenCollection.useChangeEffects = FALSE

	TInGameScreen_Room.shortcutTarget = room 'to skip animation
	figure.EnterRoom(null, room)

	TRoom.ChangeRoomSpeed = 500
	TScreenCollection.useChangeEffects = TRUE

	return TRUE
End Function


Function StartTVTower(start:Int=true)
	App = TApp.Create(30, -1, TRUE) 'create with screen refreshrate and vsync
	App.LoadResources("config/resources.xml")

	ArchiveProgrammeList	= New TgfxProgrammelist.Create(575, 16, 21)

	NewsAgency				= New TNewsAgency.Create()

	TTooltip.UseFontBold	= Assets.fonts.baseFontBold
	TTooltip.UseFont 		= Assets.fonts.baseFont
	TTooltip.ToolTipIcons	= Assets.GetSprite("gfx_building_tooltips")
	TTooltip.TooltipHeader	= Assets.GetSprite("gfx_tooltip_header")


	'#Region: Globals, Player-Creation
	Interface		= TInterface.Create()
	Game	  			= new TGame.Create()
	Building		= new TBuilding.Create()
	'init sound receiver
	TSoundManager.GetInstance().SetDefaultReceiver(TPlayerElementPosition.Create())


	EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", new TData.AddString("text", "Create Rooms").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )
	'figures need building (for location) - so create AFTER building
	Game.InitializeBasics()
	'creates all Rooms - with the names assigned at this moment
	Init_CreateAllRooms()

	'RON
	Local haveNPCs:Int = True
	If haveNPCs
		New TFigureJanitor.CreateFigure("Hausmeister", Assets.GetSprite("figure_Hausmeister"), 210, 2, 65)
		New TFigurePostman.CreateFigure("Bote1", Assets.GetSprite("BoteLeer"), 210, 3, 65, 0)
		New TFigurePostman.CreateFigure("Bote2", Assets.GetSprite("BoteLeer"), 410, 1, -65, 0)
	EndIf


	TDevHelper.Log("Base", "Creating GUIelements", LOG_DEBUG)
	InGame_Chat = New TGUIChat.Create(520,418,280,190,"InGame")
	InGame_Chat.setDefaultHideEntryTime(10000)
	InGame_Chat.guiList.backgroundColor = TColor.Create(0,0,0,0.2)
	InGame_Chat.guiList.backgroundColorHovered = TColor.Create(0,0,0,0.7)
	InGame_Chat.setOption(GUI_OBJECT_CLICKABLE, False)
	InGame_Chat.SetDefaultTextColor( TColor.Create(255,255,255) )
	InGame_Chat.guiList.autoHideScroller = True
	'reposition input
	InGame_Chat.guiInput.rect.position.setXY( 275, 387)
	InGame_Chat.guiInput.setMaxLength(200)
	InGame_Chat.guiInput.setOption(GUI_OBJECT_POSITIONABSOLUTE, True)
	InGame_Chat.guiInput.maxTextWidth = gfx_GuiPack.GetSprite("Chat_IngameOverlay").area.GetW() - 20
	InGame_Chat.guiInput.spriteName = "Chat_IngameOverlay"
	InGame_Chat.guiInput.color.AdjustRGB(255,255,255,True)
	InGame_Chat.guiInput.SetValueDisplacement(0,5)


	'connect click and change events to the gui objects
	TGameEvents.Init()

	SetColor 255,255,255

	PlayerDetailsTimer = 0
	MainMenuJanitor = New TFigureJanitor.CreateFigure("Hausmeister", Assets.GetSprite("figure_Hausmeister"), 250, 2, 65)

	MainMenuJanitor.useElevator = False
	MainMenuJanitor.useDoors = False
	MainMenuJanitor.useAbsolutePosition = True
	MainMenuJanitor.BoredCleanChance = 30
	MainMenuJanitor.MovementRangeMinX = 0
	MainMenuJanitor.MovementRangeMaxX = 800
	MainMenuJanitor.rect.position.SetY(600)


	'add menu screens
	ScreenGameSettings = New TScreen_GameSettings.Create("GameSettings")
	GameScreen_Building = New TInGameScreen_Building.Create("InGame_Building")
	'Menu
	ScreenCollection.Add(New TScreen_MainMenu.Create("MainMenu"))
	ScreenCollection.Add(ScreenGameSettings)
	ScreenCollection.Add(New TScreen_NetworkLobby.Create("NetworkLobby"))
	ScreenCollection.Add(New TScreen_StartMultiplayer.Create("StartMultiplayer"))
	'Game screens
	ScreenCollection.Add(GameScreen_Building)

	'go into the start menu
	Game.SetGamestate(TGame.STATE_MAINMENU)

	'===== EVENTS =====
	EventManager.registerListenerFunction("Game.OnDay", 	GameEvents.OnDay )
	EventManager.registerListenerFunction("Game.OnHour", 	GameEvents.OnHour )
	EventManager.registerListenerFunction("Game.OnMinute",	GameEvents.OnMinute )
	EventManager.registerListenerFunction("Game.OnStart",	TGame.onStart )

	'Init EventManager
	'could also be done during update ("if not initDone...")
	EventManager.Init()
	App.Start() 'all resources loaded - switch Events for Update/Draw from Loader to MainEvents

	If Not TApp.ExitApp And Not AppTerminate()
	'	KEYWRAPPER.allowKey(13, KEYWRAP_ALLOW_BOTH, 400, 200)
		Repeat
			App.Timer.loop()

			'we cannot fetch keystats in threads
			'so we have to do it 100% in the main thread - same for mouse
		?Threaded
		If RefreshInput
			LockMutex(RefreshInputMutex)
			KEYMANAGER.changeStatus()
			MOUSEMANAGER.changeStatus()
			RefreshInput = False
			UnlockMutex(RefreshInputMutex)
		EndIf
		?

			'process events not directly triggered
			'process "onMinute" etc. -> App.OnUpdate, App.OnDraw ...
			EventManager.update()

			'If RandRange(0,20) = 20 Then GCCollect()
		Until AppTerminate() Or TApp.ExitApp
		If Game.networkgame Then Network.DisconnectFromServer()
	EndIf 'not exit game
End Function