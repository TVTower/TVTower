'Application: TVGigant/TVTower
'Author: Ronny Otto

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

Include "gamefunctions.bmx" 					'Types: - TError - Errorwindows with handling
												'		- base class For buttons And extension newsbutton
												'		- stationmap-handling, -creation ...

Include "gamefunctions_betty.bmx"
Include "gamefunctions_screens.bmx"


Global VersionDate:String		= LoadText("incbin::source/version.txt")
Global VersionString:String		= "version of " + VersionDate
Global CopyrightString:String	= "by Ronny Otto & Manuel Vögele"
AppTitle = "TVTower: " + VersionString + " " + CopyrightString
TDevHelper.Log("CORE", "Starting TVTower, "+VersionString+".", LOG_INFO )


Global App:TApp = TApp.Create(30,-1, TRUE) 'create with screen refreshrate and vsync
App.LoadResources("config/resources.xml")

'RON: precalc here until we have abilities to use different maps during
'     start settings setup
TStationMap.InitMapData()

Include "gamefunctions_tvprogramme.bmx"  		'contains structures for TV-programme-data/Blocks and dnd-objects
Include "gamefunctions_rooms.bmx"				'basic roomtypes with handling
Include "gamefunctions_ki.bmx"					'LUA connection
Include "gamefunctions_sound.bmx"				'TVTower spezifische Sounddefinitionen
Include "gamefunctions_popularity.bmx"			'Popularitäten und Trends
Include "gamefunctions_genre.bmx"				'Genre-Definitionen
Include "gamefunctions_quotes.bmx"				'Quotenberechnung
Include "gamefunctions_people.bmx"				'Angestellte und Personen
Include "gamefunctions_production.bmx"			'Alles was mit Filmproduktion zu tun hat
Include "gamefunctions_debug.bmx"



'setup what the logger should output
TDevHelper.setLogMode(LOG_ALL)
TDevHelper.setPrintMode(LOG_ALL &~ LOG_AI ) 'all but ai



Global ArchiveProgrammeList:TgfxProgrammelist	= New TgfxProgrammelist.Create(575, 16, 21)

Global SaveError:TError, LoadError:TError
Global NewsAgency:TNewsAgency					= New TNewsAgency.Create()

TTooltip.UseFontBold	= Assets.fonts.baseFontBold
TTooltip.UseFont 		= Assets.fonts.baseFont
TTooltip.ToolTipIcons	= Assets.GetSprite("gfx_building_tooltips")
TTooltip.TooltipHeader	= Assets.GetSprite("gfx_tooltip_header")


'Enthaelt Verbindung zu Einstellungen und Timern, sonst nix
Type TApp
	Field Timer:TDeltaTimer
	Field settings:TApplicationSettings
	Field prepareScreenshot:Int			= 0						'logo for screenshot
	Field g:TGraphics
	Field vsync:int						= TRUE

	Field creationTime:Int 'only used for debug purpose (loadingtime)
	Global lastLoadEvent:TEventSimple	= Null
	Global baseResourcesLoaded:Int		= 0						'able to draw loading screen?
	Global baseResourceXmlUrl:String	= "config/startup.xml"	'holds bg for loading screen and more
	Global currentResourceUrl:String	= ""
	Global maxResourceCount:Int			= 427					'set to <=0 to get a output of loaded resources
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
		EventManager.registerListenerFunction( "XmlLoader.onLoadElement",	TApp.onLoadElement )
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
	End Method


	Method Start()
		EventManager.unregisterListenersByTrigger("App.onDraw")
		AppEvents.Init()

		EventManager.registerListenerFunction("App.onSystemUpdate", AppEvents.onAppSystemUpdate )
		EventManager.registerListenerFunction("App.onUpdate", 		AppEvents.onAppUpdate )
		EventManager.registerListenerFunction("App.onDraw", 		AppEvents.onAppDraw )
		'so we could create special fonts and other things
		EventManager.triggerEvent( TEventSimple.Create("App.onStart") )

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
	Field _Stationmaps:TList = null
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
		_Assign(_Stationmaps, TStationMap.List, "Stationmaps", MODE_LOAD)
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
		_Assign(TStationMap.List, _Stationmaps, "Stationmaps", MODE_SAVE)
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
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginLoad", TData.Create().addString("saveName", saveName)))


		'load savegame data into game object
		saveGame.RestoreGameData()

		'tell everybody we finished loading (eg. for clearing GUI-lists)
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnLoad", TData.Create().addString("saveName", saveName).add("saveGame", saveGame)))

		Return True
	End Function


	Function Save:Int(saveName:String="savegame.xml")
		Local saveGame:TSaveGame = New TSaveGame
		'tell everybody we start saving
		'payload is saveName
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginSave", TData.Create().addString("saveName", saveName)))

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
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnSave", TData.Create().addString("saveName", saveName).add("saveGame", saveGame)))

		Return True
	End Function
End Type


'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame {_exposeToLua="selected"}
	'globals are not saveloaded/exposed
	Global debugMode:Int					= 0						'0=no debug messages; 1=some debugmessages
	Global debugInfos:Int					= 0
	Global debugQuoteInfos:Int				= 0

	'===== GAME STATES =====
	Const STATE_RUNNING:Int					= 0
	Const STATE_MAINMENU:Int				= 1
	Const STATE_NETWORKLOBBY:Int			= 2
	Const STATE_SETTINGSMENU:Int			= 3
	Const STATE_STARTMULTIPLAYER:Int		= 4						'mode when data gets synchronized
	Const STATE_INITIALIZEGAME:Int			= 5						'mode when date needed for game (names,colors) gets loaded

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
	Global _eventsRegistered:int 		= FALSE


	Method New()
		_instance = self

		if not _eventsRegistered
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			EventManager.registerListenerFunction("SaveGame.OnBeginSave", onSaveGameBeginSave)
			_eventsRegistered = TRUE
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
		networkgame		= 0

		SetStartYear(1985)
		title				= "unknown"

		SetRandomizerBase( MilliSecs() )

		PopularityManager	= TPopularityManager.Create()
		BroadcastManager	= TBroadcastManager.Create()

		Return self
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


	Method Initialize()
		Game.PopularityManager.Initialize()
		Game.BroadcastManager.Initialize()

		LoadDatabase(userdb) 'load all movies, news, series and ad-contracts

		CreateInitialPlayers()
	End Method



	'computes daily costs like station or newsagency fees for every player
	Method ComputeDailyCosts(day:Int=-1)
		For Local Player:TPlayer = EachIn Players
			'stationfees
			Player.GetFinance().PayStationFees( Player.GetStationMap().CalculateStationCosts(player.playerID))
			'interest rate for your current credit
			Player.GetFinance().PayCreditInterest( Player.GetFinance().credit * TPlayerFinance.creditInterestRate )

			'newsagencyfees
			Local newsagencyfees:Int =0
			For Local i:Int = 0 To 5
				newsagencyfees:+ Player.newsabonnements[i]*10000 'baseprice for an subscriptionlevel
			Next
			Player.GetFinance(day).PayNewsAgencies((newsagencyfees/2))
		Next
	End Method


	'computes daily income like account interest income
	Method ComputeDailyIncome(day:Int=-1)
		For Local Player:TPlayer = EachIn Players
			Player.GetFinance().EarnBalanceInterest( Player.GetFinance().money * TPlayerFinance.balanceInterestRate )
		Next
	End Method



	'computes penalties for expired ad-contracts
	Method ComputeContractPenalties(day:Int=-1)
		For Local Player:TPlayer = EachIn Players
			For Local Contract:TAdContract = EachIn Player.ProgrammeCollection.adContracts
				If Not contract Then Continue

				'0 days = "today", -1 days = ended
				If contract.GetDaysLeft() < 0
					Player.GetFinance(day).PayPenalty(contract.GetPenalty())
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
					EventManager.registerEvent(TEventSimple.Create("Game.OnMinute", TData.Create().addNumber("minute", game.GetMinute()).addNumber("hour", game.GetHour()).addNumber("day", game.GetDay()) ))
					EventManager.registerEvent(TEventSimple.Create("Game.OnHour", TData.Create().addNumber("minute", game.GetMinute()).addNumber("hour", game.GetHour()).addNumber("day", game.GetDay()) ))
					'so we start at day "1"
					EventManager.registerEvent(TEventSimple.Create("Game.OnDay", TData.Create().addNumber("minute", game.GetMinute()).addNumber("hour", game.GetHour()).addNumber("day", game.GetDay()) ))

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
		EventManager.triggerEvent(TEventSimple.Create("chat.onAddEntry", TData.Create().AddNumber("senderID", -1).AddNumber("channels", CHAT_CHANNEL_SYSTEM).AddString("text", message) ) )
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

			'minute
			EventManager.triggerEvent(TEventSimple.Create("Game.OnMinute", TData.Create().addNumber("minute", GetMinute()).addNumber("hour", GetHour()).addNumber("day", GetDay()) ))

			'hour
			If GetMinute() = 0
				EventManager.triggerEvent(TEventSimple.Create("Game.OnHour", TData.Create().addNumber("minute", GetMinute()).addNumber("hour", GetHour()).addNumber("day", GetDay()) ))
			endif

			'day
			If GetHour() = 0 And GetMinute() = 0
				'increase current day
				daysPlayed :+1
			 	'automatically change current-plan-day on day change
			 	'but do it silently (without affecting the)
			 	RoomHandler_Office.ChangePlanningDay(GetDay())

				EventManager.triggerEvent(TEventSimple.Create("Game.OnDay", TData.Create().addNumber("minute", GetMinute()).addNumber("hour", GetHour()).addNumber("day", GetDay()) ))
			EndIf
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




'class holding name, channelname, infos about the figure, programmeplan, programmecollection and so on - from a player
Type TPlayer {_exposeToLua="selected"}
	Field Name:String 								'playername
	Field channelname:String 						'name of the channel
	Field finances:TPlayerFinance[]					'financial stats about credit, money, payments ...
	Field audience:TAudienceResult

	Field ProgrammeCollection:TPlayerProgrammeCollection	{_exposeToLua}
	Field ProgrammePlan:TPlayerProgrammePlan				{_exposeToLua}
	Field Figure:TFigure									{_exposeToLua}				'actual figure the player uses
	Field playerID:Int 			= 0					'global used ID of the player
	Field color:TColor				 				'the color used to colorize symbols and figures
	Field figurebase:Int 		= 0					'actual number of an array of figure-images
	Field networkstate:Int 		= 0					'1=ready, 0=not set, ...
	Field newsabonnements:Int[6]							{_private}					'abonnementlevels for the newsgenres
	Field PlayerKI:KI			= Null						{_private}
	Field CreditMaximum:Int		= 600000					{_private}


	Method onLoad:int(triggerEvent:TEventBase)
		'reconnect AI engine
		if IsAi() then PlayerKI.Start()

		'load savestate
		if IsAi() then PlayerKI.CallOnLoad()
	End Method


	Method GetPlayerID:Int() {_exposeToLua}
		Return playerID
	End Method


	Method IsAI:Int() {_exposeToLua}
		'return self.playerKI <> null
		Return figure.IsAI()
	End Method


	Method GetStationMap:TStationMap() {_exposeToLua}
		'fetch from StationMap-list
		local map:TStationMap = TStationMap.GetStationmap(playerID)
		'still not existing - create it
		if not map then map = TStationMap.Create(self)
		return map
	End Method


	'returns the financial of the given day
	'if the day is in the future, a new finance object is created
	Method GetFinance:TPlayerFinance(day:Int=-1)
		If day <= 0 Then day = Game.GetDay()
		'subtract start day to get a index starting at 0 and add 1 day again
		Local arrayIndex:Int = day +1 - Game.GetStartDay()

		If arrayIndex < 0 Then Return GetFinance(Game.GetStartDay()-1)
		If (arrayIndex = 0 And Not finances[0]) Or arrayIndex >= finances.length
			TDevHelper.Log("TPlayer.GetFinance()", "Adding a new finance to player "+Self.playerID+" for day "+day+ " at index "+arrayIndex, LOG_DEBUG)
			If arrayIndex >= finances.length
				'resize array
				finances = finances[..arrayIndex+1]
			EndIf
			finances[arrayIndex] = New TPlayerFinance.Create(Self)
			'reuse the money from the day before
			'if arrayIndex 0 - we do not need to take over
			'calling GetFinance(day-1) instead of accessing the array
			'assures that the object is created if needed (recursion)
			If arrayIndex > 0 Then TPlayerFinance.TakeOverFinances(GetFinance(day-1), finances[arrayIndex])
		EndIf
		Return finances[arrayIndex]
	End Method


	Method GetMaxAudience:Int() {_exposeToLua}
		Return GetStationMap().GetReach()
	End Method


	Method isInRoom:Int(roomName:String="", checkFromRoom:Int=False) {_exposeToLua}
		If checkFromRoom
			'from room has to be set AND inroom <> null (no building!)
			Return (Figure.inRoom And Figure.inRoom.Name.toLower() = roomname.toLower()) Or (Figure.inRoom And Figure.fromRoom And Figure.fromRoom.Name.toLower() = roomname.toLower())
		Else
			Return (Figure.inRoom And Figure.inRoom.Name.toLower() = roomname.toLower())
		EndIf
	End Method


	'creates and returns a player
	'-creates the given playercolor and a figure with the given
	' figureimage, a programmecollection and a programmeplan
	Function Create:TPlayer(playerID:int, Name:String, channelname:String = "", sprite:TGW_Sprite, x:Int, onFloor:Int = 13, dx:Int, color:TColor, ControlledByID:Int = 1, FigureName:String = "")
		Local Player:TPlayer		= New TPlayer
		EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Create Player").AddNumber("itemNumber", playerID).AddNumber("maxItemNumber", 4) ) )

		Player.Name					= Name
		Player.playerID				= playerID
		Player.color				= color.AddToList(True).SetOwner(playerID)
		Player.channelname			= channelname
		Player.Figure				= New TFigure.CreateFigure(FigureName, sprite, x, onFloor, dx, ControlledByID)
		Player.Figure.ParentPlayerID= playerID
		Player.ProgrammeCollection	= TPlayerProgrammeCollection.Create(Player)
		Player.ProgrammePlan		= New TPlayerProgrammePlan.Create(Player)

		Player.RecolorFigure(Player.color)

		Player.UpdateFigureBase(1)

		Return Player
	End Function


	Method SetAIControlled(luafile:String="")
		figure.controlledByID = 0
		PlayerKI = new KI.Create(playerID, luafile)
		PlayerKI.Start()
	End Method


	'loads a new figurbase and colorizes it
	Method UpdateFigureBase(newfigurebase:Int)
		Local figureCount:Int = 13
		If newfigurebase > figureCount Then newfigurebase = 1
		If newfigurebase <= 0 Then newfigurebase = figureCount
		figurebase = newfigurebase

		Local figureSprite:TGW_Sprite = Assets.GetSpritePack("figures").GetSprite("Player" + Self.playerID)
		Local figureImageReplacement:TImage = ColorizeImage(Assets.GetSpritePack("figures").GetSpriteByID(figurebase).GetImage(), color)

		'clear occupied area within pixmap
		figureSprite.ClearImageData()
		'draw the new figure at that area
		DrawImageOnImage(figureImageReplacement, Assets.GetSpritePack("figures").image, figureSprite.area.GetX(), figureSprite.area.GetY())
rem
		CLS
		DrawImage(Assets.GetSpritePack("figures").image, 10,10)
		Flip 0
		Delay(500)
endrem
	End Method


	'colorizes a figure and the corresponding sign next to the players doors in the building
	Method RecolorFigure(newColor:TColor = Null)
		If newColor = Null Then newColor = color
		color.ownerID	= 0
		color			= newColor
		color.ownerID	= playerID
		UpdateFigureBase(figurebase)
	End Method


	'nothing up to now
	Method UpdateFinances:Int()
		For Local i:Int = 0 To 6
			'
		Next
	End Method


	Method GetNewsAbonnementPrice:Int(level:Int=0)
		Return Min(5,level) * 10000
	End Method


	Method GetNewsAbonnementDelay:Int(genre:Int) {_exposeToLua}
		Return 60*(3-Self.newsabonnements[genre])
	End Method


	Method GetNewsAbonnement:Int(genre:Int) {_exposeToLua}
		If genre > 5 Then Return 0 'max 6 categories 0-5
		Return Self.newsabonnements[genre]
	End Method


	Method IncreaseNewsAbonnement(genre:Int) {_exposeToLua}
		Self.SetNewsAbonnement( genre, Self.GetNewsAbonnement(genre)+1 )
	End Method


	Method SetNewsAbonnement(genre:Int, level:Int, sendToNetwork:Int = True) {_exposeToLua}
		If level > Game.maxAbonnementLevel Then level = 0 'before: Return
		If genre > 5 Then Return 'max 6 categories 0-5
		If Self.newsabonnements[genre] <> level
			Self.newsabonnements[genre] = level
			If Game.networkgame And Network.IsConnected And sendToNetwork Then NetworkHelper.SendNewsSubscriptionChange(Self.playerID, genre, level)
		EndIf
	End Method


	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetAudiencePercentage:Float() {_exposeToLua}
		Return TAudienceResult.Curr(playerID).AudienceQuote.Average
		'Local audienceResult:TAudienceResult = TAudienceResult.Curr(playerID)
		'Return audienceResult.MaxAudienceThisHour.GetSumFloat() / audienceResult.WholeMarket.GetSumFloat()
	End Method


Rem
	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetRelativeAudiencePercentage:Float(playerID:Int) {_exposeToLua}
		Return TAudienceResult.Curr(playerID).AudienceQuote.GetAverage()
	End Method
endrem


	'returns value chief will give as credit
	Method GetCreditAvailable:Int() {_exposeToLua}
		Return Max(0, CreditMaximum - GetFinance().credit)
	End Method


	'nothing up to now
	Method Update:Int()
		''
	End Method


	'returns formatted value of actual money
	'gibt einen formatierten Wert des aktuellen Geldvermoegens zurueck
	Method GetMoneyFormatted:String(day:Int=-1)
		Return TFunctions.convertValue(GetFinance(day).money, 2)
	End Method


	'attention: when used through LUA without param, the param gets "0"
	'instead of "-1"
	Method GetMoney:Int(day:Int=-1) {_exposeToLua}
		Return GetFinance(day).money
	End Method


	'returns formatted value of actual credit
	Method GetCreditFormatted:String(day:Int=-1)
		Return TFunctions.convertValue(GetFinance(day).credit, 2)
	End Method


	Method GetCredit:Int(day:Int=-1) {_exposeToLua}
		Return GetFinance(day).credit
	End Method


	Method GetAudience:Int() {_exposeToLua}
		If Not Self.audience Then Return 0
		Return Self.audience.Audience.GetSum()
	End Method


	'returns formatted value of actual audience
	'gibt einen formatierten Wert der aktuellen Zuschauer zurueck
	Method GetFormattedAudience:String() {_exposeToLua}
		Return TFunctions.convertValue(GetAudience(), 2)
	End Method

	Method Compare:Int(otherObject:Object)
		Local s:TPlayer = TPlayer(otherObject)
		If Not s Then Return 1
		If s.playerID > Self.playerID Then Return 1
		Return 0
	End Method


	Method isActivePlayer:Int()
		Return (Self.playerID = Game.playerID)
	End Method
End Type


'holds data of WHAT has been bought, which amount of money was used and so on ...
'contains methods for refreshing stats when paying or selling something
Type TPlayerFinance
	Field expense_programmeLicences:Int	= 0
	Field expense_stations:Int 			= 0
	Field expense_scripts:Int 			= 0
	Field expense_productionstuff:Int	= 0
	Field expense_penalty:Int 			= 0
	Field expense_rent:Int 				= 0
	Field expense_news:Int 				= 0
	Field expense_newsagencies:Int 		= 0
	Field expense_stationfees:Int 		= 0
	Field expense_misc:Int 				= 0
	Field expense_creditInterest:int	= 0	'interest to pay for the current credit
	Field expense_total:Int 			= 0

	Field income_programmeLicences:Int	= 0
	Field income_ads:Int				= 0
	Field income_callerRevenue:Int		= 0
	Field income_misc:Int				= 0
	Field income_total:Int				= 0
	Field income_stations:Int			= 0
	Field income_balanceInterest:int	= 0	'interest for money "on the bank"
	Field revenue_before:Int 			= 0
	Field revenue_after:Int 			= 0
	Field money:Int						= 0
	Field credit:Int 					= 0
	Field ListLink:TLink
	Field player:TPlayer				= Null
	Global creditInterestRate:float		= 0.05 '5% a day
	Global balanceInterestRate:float	= 0.01 '1% a day
	Global List:TList					= CreateList()


	Method Create:TPlayerFinance(player:TPlayer, startmoney:Int=500000, startcredit:Int = 500000)
		money			= startmoney
		revenue_before	= startmoney
		revenue_after	= startmoney

		credit			= startcredit
		Self.player		= player
		ListLink		= List.AddLast(Self)
		Return Self
	End Method


	'take the current balance (money and credit) to the next day
	Function TakeOverFinances:Int(fromFinance:TPlayerFinance, toFinance:TPlayerFinance Var)
		If Not toFinance Then Return False
		'if the "fromFinance" does not exist yet just assume the same
		'value than of "toFinance" - so no modification would be needed
		'in all other cases:
		If fromFinance
			'remove current finance from financials.list as we create a new one
			toFinance.ListLink.remove()
			toFinance = Null
			'create the new financial but give the yesterdays money/credit
			toFinance = New TPlayerFinance.Create(fromFinance.player, fromFinance.money, fromFinance.credit)
		EndIf
	End Function


	'returns whether the finances allow the given transaction
	Method CanAfford:Int(price:Int=0)
		Return (money > 0 And money >= price)
	End Method


	Method ChangeMoney(value:Int)
		'TDevHelper.log("TFinancial.ChangeMoney()", "Player "+player.playerID+" changed money by "+value, LOG_DEBUG)
		money			:+ value
		revenue_after	:+ value
		'change to event?
		If Game.isGameLeader() And player.isAI() Then player.PlayerKI.CallOnMoneyChanged()
		If player.isActivePlayer() Then Interface.BottomImgDirty = True
	End Method


	Method AddIncome(value:Int)
		income_total :+ value
		ChangeMoney(value)
	End Method


	Method AddExpense(value:Int)
		expense_total :+ value
		ChangeMoney(-value)
	End Method


	Method RepayCredit:Int(value:Int)
		TDevHelper.Log("TFinancial.RepayCredit()", "Player "+player.playerID+" repays (a part of his) credit of "+value, LOG_DEBUG)
		credit			:- value
		income_misc		:- value
		income_total	:- value
		expense_misc	:- value
		expense_total	:- value
		ChangeMoney(-value)
	End Method


	Method TakeCredit:Int(value:Int)
		TDevHelper.Log("TFinancial.TakeCredit()", "Player "+player.playerID+" took a credit of "+value, LOG_DEBUG)
		credit			:+ value
		income_misc		:+ value
		income_total	:+ value
		expense_misc	:+ value
		expense_total	:+ value
		ChangeMoney(+value)
	End Method


	'refreshs stats about misc sells
	Method SellMisc:Int(price:Int)
		TDevHelper.Log("TFinancial.SellMisc()", "Player "+player.playerID+" sold mics for "+price, LOG_DEBUG)
		income_misc :+ price
		AddIncome(price)
		Return True
	End Method


	Method SellStation:Int(price:Int)
		TDevHelper.Log("TFinancial.SellStation()", "Player "+player.playerID+" sold a station for "+price, LOG_DEBUG)
		income_stations :+ price
		AddIncome(price)
		Return True
	End Method


	'refreshs stats about earned money from adspots
	Method EarnAdProfit:Int(value:Int)
		TDevHelper.Log("TFinancial.EarnAdProfit()", "Player "+player.playerID+" earned "+value+" with ads", LOG_DEBUG)
		income_ads :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from sending ad powered shows or call-in
	Method EarnCallerRevenue:Int(value:Int)
		TDevHelper.Log("TFinancial.EarnCallerRevenue()", "Player "+player.playerID+" earned "+value+" with a call-in-show", LOG_DEBUG)
		income_callerRevenue :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from selling a movie/programme
	Method SellProgrammeLicence:Int(price:Int)
		TDevHelper.Log("TFinancial.SellLicence()", "Player "+player.playerID+" earned "+price+" selling a programme licence", LOG_DEBUG)
		income_programmeLicences :+ price
		AddIncome(price)
	End Method


	'refreshs stats about paid money from paying interest on the current credit
	Method EarnBalanceInterest:Int(value:Int)
		TDevHelper.Log("TFinancial.EarnBalanceInterest()", "Player "+player.playerID+" earned "+value+" on interest of their current balance", LOG_DEBUG)
		income_balanceInterest :+ value
		AddIncome(value)
		Return True
	End Method


	'pay the bid for an auction programme
	Method PayProgrammeBid:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayProgrammeBid()", "Player "+player.playerID+" paid a bid of "+price, LOG_DEBUG)
			expense_programmeLicences	:+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'get the bid paid before another player bid for an auction programme
	'ATTENTION: from a financial view this IS NOT CORRECT ... it should add
	'to "income paid_programmeLicence" ...
	Method PayBackProgrammeBid:Int(price:Int)
		TDevHelper.Log("TFinancial.PayBackProgrammeBid()", "Player "+player.playerID+" received back "+price+" from an auction", LOG_DEBUG)
		expense_programmeLicences	:- price
		expense_total				:- price
		ChangeMoney(+price)
		Return True
	End Method


	'refreshs stats about paid money from buying a movie/programme
	Method PayProgrammeLicence:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayProgrammeLicence()", "Player "+player.playerID+" paid "+price+" for a programmeLicence", LOG_DEBUG)
			expense_programmeLicences :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying a station
	Method PayStation:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayStation()", "Player "+player.playerID+" paid "+price+" for a broadcasting station", LOG_DEBUG)
			expense_stations :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying a script (own production)
	Method PayScript:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayScript()", "Player "+player.playerID+" paid "+price+" for a script", LOG_DEBUG)
			expense_scripts :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying stuff for own production
	Method PayProductionStuff:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayProductionStuff()", "Player "+player.playerID+" paid "+price+" for product stuff", LOG_DEBUG)
			expense_productionstuff :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from paying a penalty fee (not sent the necessary adspots)
	Method PayPenalty:Int(value:Int)
		TDevHelper.Log("TFinancial.PayPenalty()", "Player "+player.playerID+" paid a failed contract penalty of "+value, LOG_DEBUG)
		expense_penalty :+ value
		AddExpense(value)
		Return True
	End Method


	'refreshs stats about paid money from paying the rent of rooms
	Method PayRent:Int(price:Int)
		TDevHelper.Log("TFinancial.PayRent()", "Player "+player.playerID+" paid a room rent of "+price, LOG_DEBUG)
		expense_rent :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying for the sent newsblocks
	Method PayNews:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayNews()", "Player "+player.playerID+" paid "+price+" for a news", LOG_DEBUG)
			expense_news :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from paying the daily costs a newsagency-abonnement
	Method PayNewsAgencies:Int(price:Int)
		TDevHelper.Log("TFinancial.PayNewsAgencies()", "Player "+player.playerID+" paid "+price+" for news abonnements", LOG_DEBUG)
		expense_newsagencies :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying the fees for the owned stations
	Method PayStationFees:Int(price:Int)
		TDevHelper.Log("TFinancial.PayStationFees()", "Player "+player.playerID+" paid "+price+" for station fees", LOG_DEBUG)
		expense_stationfees :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying interest on the current credit
	Method PayCreditInterest:Int(price:Int)
		TDevHelper.Log("TFinancial.PayCreditInterest()", "Player "+player.playerID+" paid "+price+" on interest of their credit", LOG_DEBUG)
		expense_creditInterest :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying misc things
	Method PayMisc:Int(price:Int)
		TDevHelper.Log("TFinancial.PayStationFees()", "Player "+player.playerID+" paid "+price+" for misc", LOG_DEBUG)
		expense_misc :+ price
		AddExpense(price)
		Return True
	End Method
End Type


'Include "gamefunctions_interface.bmx"

Include "gamefunctions_elevator.bmx"
Include "gamefunctions_figures.bmx"

'Summary: Type of building, area around it and doors,...
Type TBuilding Extends TRenderable
	Field pos:TPoint = TPoint.Create(20,0)
	Field buildingDisplaceX:Int = 127			'px at which the building starts (leftside added is the door)
	Field innerLeft:Int			= 127 + 40
	Field innerRight:Int		= 127 + 468
	Field skycolor:Float 		= 0
	Field ufo_normal:TMoveableAnimSprites 			{nosave}
	Field ufo_beaming:TMoveableAnimSprites 			{nosave}
	Field Elevator:TElevator

	Field Moon_Path:TCatmullRomSpline	= New TCatmullRomSpline {nosave}
	Field Moon_PathCurrentDistanceOld:Float= 0.0
	Field Moon_PathCurrentDistance:Float= 0.0
	Field Moon_MovementStarted:Int		= False
	Field Moon_MovementBaseSpeed:Float	= 0.0		'so that the whole path moved within time

	Field UFO_Path:TCatmullRomSpline	= New TCatmullRomSpline {nosave}
	Field UFO_PathCurrentDistanceOld:Float	= 0.0
	Field UFO_PathCurrentDistance:Float		= 0.0
	Field UFO_MovementStarted:Int		= False
	Field UFO_MovementBaseSpeed:Float	= 0.0
	Field UFO_DoBeamAnimation:Int		= False
	Field UFO_BeamAnimationDone:Int		= False

	Field Clouds:TMoveableAnimSprites[7]			{nosave}
	Field CloudsAlpha:Float[7]						{nosave}

	Field TimeColor:Double
	Field DezimalTime:Float
	Field ActHour:Int
	Field initDone:Int					= False
	Field gfx_bgBuildings:TGW_Sprite[6]				{nosave}
	Field gfx_building:TGW_Sprite					{nosave}
	Field gfx_buildingEntrance:TGW_Sprite			{nosave}
	Field gfx_buildingEntranceWall:TGW_Sprite		{nosave}
	Field gfx_buildingFence:TGW_Sprite				{nosave}
	Field gfx_buildingRoof:TGW_Sprite				{nosave}

	Field room:TRooms					= Null		'the room used for the building
	Field roomUsedTooltip:TTooltip		= Null
	Field Stars:TPoint[60]							{nosave}

	Global _instance:TBuilding
	Global _backgroundModified:int		= FALSE
	Global _eventsRegistered:int 		= FALSE


	Method New()
		_instance = self

		if not _eventsRegistered
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)

			EventManager.registerListenerFunction( "hotspot.onClick", onClickHotspot)

			'we want to get information about figures reaching their desired target
			'(this can be "room", "hotspot" ... )
			EventManager.registerListenerFunction( "figure.onReachTarget", onReachTarget)

			_eventsRegistered = TRUE
		Endif
	End Method


	Function GetInstance:TBuilding()
		if not _instance then _instance = new TBuilding.Create()
		return _instance
	End Function


	Method Create:TBuilding()
		EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Create Building").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )

		'call to set graphics, paths for objects and other
		'stuff not gameplay relevant
		InitGraphics()

		pos.y			= 0 - gfx_building.area.GetH() + 5 * 73 + 20	' 20 = interfacetop, 373 = raumhoehe
		Elevator		= new TElevator.Create()
		Elevator.Pos.SetY(GetFloorY(Elevator.CurrentFloor) - Elevator.spriteInner.area.GetH())

		Elevator.RouteLogic = TElevatorSmartLogic.Create(Elevator, 0) 'Die Logik die im Elevator verwendet wird. 1 heißt, dass der PrivilegePlayerMode aktiv ist... mMn macht's nur so wirklich Spaß

		Return self
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TDevHelper.Log("TBuilding", "Savegame loaded - reassign sprites, recreate movement paths for gfx.", LOG_DEBUG | LOG_SAVELOAD)
		GetInstance().InitGraphics()
		'reassign the elevator - should not be needed
		'GetInstance().Elevator = TElevator.GetInstance()

		'reposition hotspots
		GetInstance().Init()
	End Function


	Method InitGraphics()
		'==== MOON ====
		'movement
		Moon_Path = New TCatmullRomSpline
		Moon_Path.addXY( -50, 640 )
		Moon_Path.addXY( -50, 190 )
		Moon_Path.addXY( 400,  10 )
		Moon_Path.addXY( 850, 190 )
		Moon_Path.addXY( 850, 640 )

		'==== UFO ====
		'sprites
		ufo_normal	= New TMoveableAnimSprites.Create(Assets.GetSprite("gfx_building_BG_ufo"), 9, 100).SetupMoveable(0, 100, 0,0)
		ufo_beaming	= New TMoveableAnimSprites.Create(Assets.GetSprite("gfx_building_BG_ufo2"), 9, 100).SetupMoveable(0, 100, 0,0)
		'movement
		Local displaceY:Int = 280, displaceX:Int = 5
		UFO_Path = New TCatmullRomSpline
		UFO_path.addXY( -60 +displaceX, -410 +displaceY)
		UFO_path.addXY( -50 +displaceX, -400 +displaceY)
		UFO_path.addXY(  50 +displaceX, -350 +displaceY)
		UFO_path.addXY(-100 +displaceX, -300 +displaceY)
		UFO_path.addXY( 100 +displaceX, -250 +displaceY)
		UFO_path.addXY(  40 +displaceX, -200 +displaceY)
		UFO_path.addXY(  50 +displaceX, -190 +displaceY)
		UFO_path.addXY(  60 +displaceX, -200 +displaceY)
		UFO_path.addXY(  70 +displaceX, -250 +displaceY)
		UFO_path.addXY( 400 +displaceX, -700 +displaceY)
		UFO_path.addXY( 410 +displaceX, -710 +displaceY)

		'==== CLOUDS ====
		For Local i:Int = 0 To Clouds.length-1
			Clouds[i] = New TMoveableAnimSprites.Create(Assets.GetSprite("gfx_building_BG_clouds"), 1,0).SetupMoveable(- 200 * i + (i + 1) * Rand(0,400), - 30 + Rand(0,30), 2 + Rand(0, 6),0)
			CloudsAlpha[i] = Float(Rand(80,100))/100.0
		Next

		'==== STARS ====
		For Local j:Int = 0 To 29
			Stars[j] = TPoint.Create( 10+Rand(0,150), 20+Rand(0,273), 50+Rand(0,150) )
		Next
		For Local j:Int = 30 To 59
			Stars[j] = TPoint.Create( 650+Rand(0,150), 20+Rand(0,273), 50+Rand(0,150) )
		Next


		'==== BACKGROUND BUILDINGS ====
		gfx_bgBuildings[0] = Assets.GetSprite("gfx_building_BG_Ebene3L")
		gfx_bgBuildings[1] = Assets.GetSprite("gfx_building_BG_Ebene3R")
		gfx_bgBuildings[2] = Assets.GetSprite("gfx_building_BG_Ebene2L")
		gfx_bgBuildings[3] = Assets.GetSprite("gfx_building_BG_Ebene2R")
		gfx_bgBuildings[4] = Assets.GetSprite("gfx_building_BG_Ebene1L")
		gfx_bgBuildings[5] = Assets.GetSprite("gfx_building_BG_Ebene1R")

		'building assets
		gfx_building				= Assets.GetSprite("gfx_building")
		gfx_buildingEntrance		= Assets.GetSprite("gfx_building_Eingang")
		gfx_buildingEntranceWall	= Assets.GetSprite("gfx_building_EingangWand")
		gfx_buildingFence			= Assets.GetSprite("gfx_building_Zaun")
		gfx_buildingRoof			= Assets.GetSprite("gfx_building_Dach")
	End Method


	Method Update(deltaTime:Float=1.0)
		pos.y = Clamp(pos.y, - 637, 88)
		UpdateBackground(deltaTime)


		'update hotspot tooltips
		If room
			For Local hotspot:THotspot = EachIn room.hotspots
				hotspot.update(Self.pos.x, Self.pos.y)
			Next
		EndIf


		If Self.roomUsedTooltip <> Null Then Self.roomUsedTooltip.Update(deltaTime)


		'handle player target changes
		If Not Game.GetPlayer().Figure.inRoom
			If MOUSEMANAGER.isClicked(1) And Not GUIManager.modalActive
				If Not Game.GetPlayer().Figure.isChangingRoom
					If TFunctions.IsIn(MouseManager.x, MouseManager.y, 20, 10, 760, 373)
						Game.GetPlayer().Figure.ChangeTarget(MouseManager.x, MouseManager.y)
						MOUSEMANAGER.resetKey(1)
					EndIf
				EndIf
			EndIf
		EndIf
	End Method

	Method Init:Int()
		If initDone Then Return True

		if not _backgroundModified
			Local locy13:Int	= GetFloorY(13)
			Local locy3:Int		= GetFloorY(3)
			Local locy0:Int		= GetFloorY(0)
			Local locy12:Int	= GetFloorY(12)

			Local Pix:TPixmap = LockImage(gfx_building.parent.image)
			DrawImageOnImage(Assets.GetSprite("gfx_building_Pflanze4").GetImage(), Pix, -buildingDisplaceX + innerleft + 40, locy12 - Assets.GetSprite("gfx_building_Pflanze4").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Pflanze6").GetImage(), Pix, -buildingDisplaceX + innerRight - 95, locy12 - Assets.GetSprite("gfx_building_Pflanze6").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Pflanze2").GetImage(), Pix, -buildingDisplaceX + innerleft + 105, locy13 - Assets.GetSprite("gfx_building_Pflanze2").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Pflanze3").GetImage(), Pix, -buildingDisplaceX + innerRight - 105, locy13 - Assets.GetSprite("gfx_building_Pflanze3").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerleft + 125, locy0 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerRight - 125 - Assets.GetSprite("gfx_building_Wandlampe").area.GetW(), locy0 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerleft + 125, locy13 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerRight - 125 - Assets.GetSprite("gfx_building_Wandlampe").area.GetW(), locy13 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerleft + 125, locy3 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerRight - 125 - Assets.GetSprite("gfx_building_Wandlampe").area.GetW(), locy3 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			UnlockImage(gfx_building.parent.image)
			Pix = Null

			_backgroundModified = TRUE
		endif

		'assign room
		room = TRooms.getRoomByDetails("building",0)

		'move elevatorplan hotspots to the elevator
		For Local hotspot:THotspot = EachIn room.hotspots
			If hotspot.name = "elevatorplan"
				hotspot.area.position.setX( Elevator.pos.getX() )
				hotspot.area.dimension.setXY( Elevator.GetDoorWidth(), 58 )
			EndIf
		Next

		initDone = True
	End Method


	Function onReachTarget:Int( triggerEvent:TEventBase )
		Local figure:TFigure = TFigure( triggerEvent._sender )
		If Not figure Then Return False

		Local hotspot:THotspot = THotspot( triggerEvent.getData().get("hotspot") )
		'we are only interested in hotspots
		If Not hotspot Then Return False


		If hotspot.name = "elevatorplan"
			Print "figure "+figure.name+" reached elevatorplan"

			Local room:TRooms = TRooms.getRoomByDetails("elevatorplan",0)
			If Not room Then Print "[ERROR] room: elevatorplan not not defined. Cannot enter that room.";Return False

			figure.EnterRoom(room)
			Return True
		EndIf

		Return False
	End Function


	Function onClickHotspot:Int( triggerEvent:TEventBase )
		Local hotspot:THotspot = THotspot( triggerEvent._sender )
		If Not hotspot Then Return False 'or hotspot.name <> "elevatorplan" then return FALSE
		'not interested in others
		If not GetInstance().room.hotspots.contains(hotspot) then return False

		Game.getPlayer().figure.changeTarget( GetInstance().pos.x + hotspot.area.getX() + hotspot.area.getW()/2, GetInstance().pos.y + hotspot.area.getY() )
		Game.getPlayer().figure.targetHotspot = hotspot

		MOUSEMANAGER.resetKey(1)
	End Function


	Method Draw(tweenValue:Float=1.0)
		pos.y = Clamp(pos.y, - 637, 88)

		TProfiler.Enter("Draw-Building-Background")
		DrawBackground(tweenValue)
		TProfiler.Leave("Draw-Building-Background")

		'reset drawn for all figures... so they can get drawn
		'correct at their "z-indexes" (behind building, elevator or on floor )
		For Local Figure:TFigure = EachIn FigureCollection.list
			Figure.alreadydrawn = False
		Next

		If Building.GetFloor(Game.Players[Game.playerID].Figure.rect.GetY()) >= 8
			SetColor 255, 255, 255
			SetBlend ALPHABLEND
			Building.gfx_buildingRoof.Draw(pos.x + buildingDisplaceX, pos.y - Building.gfx_buildingRoof.area.GetH())
		EndIf

		SetBlend MASKBLEND
		elevator.DrawFloorDoors()

		Assets.GetSprite("gfx_building").draw(pos.x + buildingDisplaceX, pos.y)

		SetBlend MASKBLEND

		'draw overlay - open doors are drawn over "background-image-doors" etc.
		TRooms.DrawDoors()
		'draw elevator parts
		Elevator.Draw()

		SetBlend ALPHABLEND

		For Local Figure:TFigure = EachIn FigureCollection.list
			'draw figure later if outside of building
			If figure.rect.GetX() < pos.x + buildingDisplaceX Then Continue
			If Not Figure.alreadydrawn Then Figure.Draw()
			Figure.alreadydrawn = True
		Next

		Local pack:TGW_Spritepack = Assets.getSpritePack("gfx_hochhauspack")
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + innerRight - 130, pos.y + GetFloorY(9), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + innerLeft + 150, pos.y + GetFloorY(13), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + innerRight - 110, pos.y + GetFloorY(9), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + innerLeft + 150, pos.y + GetFloorY(6), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze6").Draw(pos.x + innerRight - 85, pos.y + GetFloorY(8), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze3a").Draw(pos.x + innerLeft + 60, pos.y + GetFloorY(1), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze3a").Draw(pos.x + innerLeft + 60, pos.y + GetFloorY(12), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze3b").Draw(pos.x + innerLeft + 150, pos.y + GetFloorY(12), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + innerRight - 70, pos.y + GetFloorY(3), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + innerRight - 75, pos.y + GetFloorY(12), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))

		'draw entrance on top of figures
		If Building.GetFloor(Game.Players[Game.playerID].Figure.rect.GetY()) <= 4
			SetColor Int(205 * timecolor) + 150, Int(205 * timecolor) + 150, Int(205 * timecolor) + 150
			'draw figures outside the wall
			For Local Figure:TFigure = EachIn FigureCollection.list
				If Not Figure.alreadydrawn Then Figure.Draw()
			Next
			Building.gfx_buildingEntrance.Draw(pos.x, pos.y + 1024 - Building.gfx_buildingEntrance.area.GetH() - 3)

			SetColor 255,255,255
			'draw wall
			Building.gfx_buildingEntranceWall.Draw(pos.x + Building.gfx_buildingEntrance.area.GetW(), pos.y + 1024 - Building.gfx_buildingEntranceWall.area.GetH() - 3)
			'draw fence
			Building.gfx_buildingFence.Draw(pos.x + buildingDisplaceX + 507, pos.y + 1024 - Building.gfx_buildingFence.area.GetH() - 3)
		EndIf

		TRooms.DrawDoorToolTips()

		'draw hotspot tooltips
		For Local hotspot:THotspot = EachIn room.hotspots
			hotspot.draw( Self.pos.x, Self.pos.y)
		Next

		If Self.roomUsedTooltip Then Self.roomUsedTooltip.Draw()

	End Method


	Method UpdateBackground(deltaTime:Float)
		ActHour = Game.GetHour()
		DezimalTime = Float(ActHour*60 + Game.GetMinute())/60.0

		If 9 <= ActHour And Acthour < 18 Then TimeColor = 1
		If 5 <= ActHour And Acthour <= 9 		'overlapping to avoid colorjumps
			skycolor = DezimalTime
			TimeColor = (skycolor - 5) / 4
			If TimeColor > 1 Then TimeColor = 1
			If skycolor >= 350 Then skycolor = 350
		EndIf
		If 18 <= ActHour And Acthour <= 23 	'overlapping to avoid colorjumps
			skycolor = DezimalTime
			TimeColor = 1 - (skycolor - 18) / 5
			If TimeColor < 0 Then TimeColor = 0
			If skycolor <= 0 Then skycolor = 0
		EndIf


		'compute moon position
		If ActHour > 18 Or ActHour < 7
			'compute current distance
			If Not Moon_MovementStarted
				'we have 15 hrs to "see the moon" - so we have add them accordingly
				'this means - we have to calculate the hours "gone" since 18:00
				Local minutesPassed:Int = 0
				If ActHour>18
					minutesPassed = (ActHour-18)*60 + Game.GetMinute()
				Else
					minutesPassed = (ActHour+7)*60 + Game.GetMinute()
				EndIf

				'calculate the base speed needed so that the moon would move
				'the whole path within 15 hrs (15*60 minutes)
				'this means: after 15hrs 100% of distance are reached
				Moon_MovementBaseSpeed = 1.0 / (15*60)

				Moon_PathCurrentDistance = minutesPassed * Moon_MovementBaseSpeed

				Moon_MovementStarted = True
			EndIf

			'backup for tweening
			Moon_PathCurrentDistanceOld = Moon_PathCurrentDistance
			Moon_PathCurrentDistance:+ deltaTime * Moon_MovementBaseSpeed * Game.GetGameMinutesPerSecond()
		Else
			Moon_MovementStarted = False
			'set to beginning
			Moon_PathCurrentDistanceOld = 0.0
			Moon_PathCurrentDistance = 0.0
		EndIf


		'compute ufo
		'-----------
		'only happens between...
		If Game.GetDay() Mod 2 = 0 And (DezimalTime > 18 Or DezimalTime < 7)
			UFO_MovementBaseSpeed = 1.0 / 60.0 '30 minutes for whole path

			'only continue moving if not doing the beamanimation
			If Not UFO_DoBeamAnimation Or UFO_BeamAnimationDone
				UFO_PathCurrentDistanceOld = UFO_PathCurrentDistance
				UFO_PathCurrentDistance:+ deltaTime * UFO_MovementBaseSpeed * Game.GetGameMinutesPerSecond()

				'do beaming now
				If UFO_PathCurrentDistance > 0.50 And Not UFO_BeamAnimationDone
					UFO_DoBeamAnimation = True
				EndIf
			EndIf
			If UFO_DoBeamAnimation And Not UFO_BeamAnimationDone
				If ufo_beaming.getCurrentAnimation().isFinished()
					UFO_BeamAnimationDone = True
					UFO_DoBeamAnimation = False
				EndIf
				ufo_beaming.update(deltaTime)
			EndIf

		Else
			'reset beam enabler anyways
			UFO_DoBeamAnimation = False
			UFO_BeamAnimationDone=False
		EndIf

		For Local i:Int = 0 To Building.Clouds.length-1
			Clouds[i].Update(deltaTime)
		Next
	End Method

	'Summary: Draws background of the mainscreen (stars, buildings, moon...)
	Method DrawBackground(tweenValue:Float=1.0)
		Local BuildingHeight:Int = gfx_building.area.GetH() + 56

		If DezimalTime > 18 Or DezimalTime < 7
			If DezimalTime > 18 And DezimalTime < 19 Then SetAlpha (1.0- (19.0 - DezimalTime))
			If DezimalTime > 6 And DezimalTime < 8 Then SetAlpha (4.0 - DezimalTime / 2.0)
			'stars
			SetBlend MASKBLEND
			Local minute:Float = Game.GetMinute()
			For Local i:Int = 0 To 59
				If i Mod 6 = 0 And minute Mod 2 = 0 Then Stars[i].z = Rand(0, Max(1,Stars[i].z) )
				SetColor Stars[i].z , Stars[i].z , Stars[i].z
				Plot(Stars[i].x , Stars[i].y )
			Next

			SetColor 255, 255, 255
'			DezimalTime:+3
			If DezimalTime > 24 Then DezimalTime:-24

			SetBlend ALPHABLEND

			Local tweenDistance:Float = GetTweenResult(Moon_PathCurrentDistance, Moon_PathCurrentDistanceOld, True)
			Local moonPos:TPoint = Moon_Path.GetTweenPoint(tweenDistance, True)
			'draw moon - frame is from +6hrs (so day has already changed at 18:00)
			'Assets.GetSprite("gfx_building_BG_moon").Draw(40, 40, 12 - ( Game.GetDay(Game.GetTimeGone()+6*60) Mod 12) )
			Assets.GetSprite("gfx_building_BG_moon").Draw(moonPos.x, 0.10 * (pos.y) + moonPos.y, 12 - ( Game.GetDay(Game.GetTimeGone()+6*60) Mod 12) )
		EndIf

		For Local i:Int = 0 To Building.Clouds.length - 1
			SetColor Int(205 * timecolor) + 80*CloudsAlpha[i], Int(205 * timecolor) + 80*CloudsAlpha[i], Int(205 * timecolor) + 80*CloudsAlpha[i]
			SetAlpha CloudsAlpha[i]
			Clouds[i].Draw(Null, Clouds[i].rect.position.Y + 0.2*pos.y) 'parallax
		Next
		SetAlpha 1.0

		SetColor Int(205 * timecolor) + 175, Int(205 * timecolor) + 175, Int(205 * timecolor) + 175
		SetBlend ALPHABLEND
		'draw UFO
		If DezimalTime > 18 Or DezimalTime < 7
'			If Game.GetDay() Mod 2 = 0
				'compute and draw Ufo
				Local tweenDistance:Float = GetTweenResult(UFO_PathCurrentDistance, UFO_PathCurrentDistanceOld, True)
				Local UFOPos:TPoint = UFO_Path.GetTweenPoint(tweenDistance, True)
				'print UFO_PathCurrentDistance
				If UFO_DoBeamAnimation And Not UFO_BeamAnimationDone
					ufo_beaming.rect.position.SetXY(UFOPos.x, 0.25 * (pos.y + BuildingHeight - gfx_bgBuildings[0].area.GetH()) + UFOPos.y)
					ufo_beaming.Draw()
				Else
					Assets.GetSprite("gfx_building_BG_ufo").Draw( UFOPos.x, 0.25 * (pos.y + BuildingHeight - gfx_bgBuildings[0].area.GetH()) + UFOPos.y, ufo_normal.GetCurrentFrame())
				EndIf
'			EndIf
		EndIf

		SetBlend MASKBLEND

		Local baseBrightness:Int = 75

		SetColor Int(225 * timecolor) + baseBrightness, Int(225 * timecolor) + baseBrightness, Int(225 * timecolor) + baseBrightness
		gfx_bgBuildings[0].Draw(pos.x		, 105 + 0.25 * (pos.y + 5 + BuildingHeight - gfx_bgBuildings[0].area.GetH()), - 1)
		gfx_bgBuildings[1].Draw(pos.x + 634	, 105 + 0.25 * (pos.y + 5 + BuildingHeight - gfx_bgBuildings[1].area.GetH()), - 1)

		SetColor Int(215 * timecolor) + baseBrightness+15, Int(215 * timecolor) + baseBrightness+15, Int(215 * timecolor) + baseBrightness+15
		gfx_bgBuildings[2].Draw(pos.x		, 120 + 0.35 * (pos.y 		+ BuildingHeight - gfx_bgBuildings[2].area.GetH()), - 1)
		gfx_bgBuildings[3].Draw(pos.x + 636	, 120 + 0.35 * (pos.y + 60	+ BuildingHeight - gfx_bgBuildings[3].area.GetH()), - 1)

		SetColor Int(205 * timecolor) + baseBrightness+30, Int(205 * timecolor) + baseBrightness+30, Int(205 * timecolor) + baseBrightness+30
		gfx_bgBuildings[4].Draw(pos.x		, 45 + 0.80 * (pos.y + BuildingHeight - gfx_bgBuildings[4].area.GetH()), - 1)
		gfx_bgBuildings[5].Draw(pos.x + 634	, 45 + 0.80 * (pos.y + BuildingHeight - gfx_bgBuildings[5].area.GetH()), - 1)

		SetColor 255, 255, 255
		SetAlpha 1.0
	End Method

	Method CreateRoomUsedTooltip:Int(room:TRooms)
		roomUsedTooltip			= TTooltip.Create("Besetzt", "In diesem Raum ist schon jemand", 0,0,-1,-1,2000)
		roomUsedTooltip.area.position.SetY(pos.y + GetFloorY(room.Pos.y))
		roomUsedTooltip.area.position.SetX(room.Pos.x + room.doorDimension.x/2 - roomUsedTooltip.GetWidth()/2)
		roomUsedTooltip.enabled = 1
	End Method

	Method CenterToFloor:Int(floornumber:Int)
		pos.y = ((13 - (floornumber)) * 73) - 115
	End Method

	'Summary: returns y which has to be added to building.y, so its the difference
	Function GetFloorY:Int(floornumber:Int)
		Return (66 + 1 + (13 - floornumber) * 73)		  ' +10 = interface
	End Function

	Method GetFloor:Int(_y:Int)
		Return Clamp(14 - Ceil((_y - pos.y) / 73),0,13) 'TODO/FIXIT mv 10.11.2012 scheint nicht zu funktionieren!!! Liefert immer die gleiche Zahl egal in welchem Stockwerk man ist
	End Method

	Method getFloorByPixelExactPoint:Int(point:TPoint) 'point ist hier NICHT zwischen 0 und 13... sondern pixelgenau... also zwischen 0 und ~ 1000
		For Local i:Int = 0 To 13
			If Building.GetFloorY(i) < point.y Then Return i
		Next
		Return -1
	End Method
End Type


'likely a kind of agency providing news... 'at the moment only a base object
Type TNewsAgency
	Field NextEventTime:Double		= 0
	Field NextChainChecktime:Double	= 0
	Field activeChains:TList		= CreateList() 'holding chained news from the past hours/day

	Method Create:TNewsAgency()
		'maybe do some initialization here

		Return Self
	End Method

	Method GetMovieNewsEvent:TNewsEvent()
		Local licence:TProgrammeLicence = Self._GetAnnouncableProgrammeLicence()
		If Not licence Then Return Null
		If Not licence.getData() Then Return Null

		licence.GetData().releaseAnnounced = True

		Local title:String = getLocale("NEWS_ANNOUNCE_MOVIE_TITLE"+Rand(1,2) )
		Local description:String = getLocale("NEWS_ANNOUNCE_MOVIE_DESCRIPTION"+Rand(1,4) )

		'if same director and main actor...
		If licence.GetData().getActor(1) = licence.GetData().getDirector(1)
			title = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_TITLE")
			description = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_DESCRIPTION")
		EndIf
		'if no actors ...
		If licence.GetData().getActor(1) = ""
			title = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_TITLE")
			description = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_DESCRIPTION")
		EndIf

		'replace data
		title = Self._ReplaceProgrammeData(title, licence.GetData())
		description = Self._ReplaceProgrammeData(description, licence.GetData())

		'quality and price are based on the movies data
		Local NewsEvent:TNewsEvent = TNewsEvent.Create(title, description, 1, licence.GetData().review/2.0, licence.GetData().outcome/3.0)
		'remove news from available list as we do not want to have them repeated :D
		NewsEventCollection.Remove(NewsEvent)

		Return NewsEvent
	End Method

	Method _ReplaceProgrammeData:String(text:String, data:TProgrammeData)
		For Local i:Int = 1 To 2
			text = text.Replace("%ACTORNAME"+i+"%", data.getActor(i))
			text = text.Replace("%DIRECTORNAME"+i+"%", data.getDirector(i))
		Next
		text = text.Replace("%MOVIETITLE%", data.title)

		Return text
	End Method

	'helper to get a movie which can be used for a news
	Method _GetAnnouncableProgrammeLicence:TProgrammeLicence()
		'filter to entries we need
		Local licence:TProgrammeLicence
		Local resultList:TList = CreateList()
		For licence = EachIn TProgrammeLicence.movies
			'ignore collection and episodes (which should not be in that list)
			If Not licence.getData() Then Continue

			'ignore if filtered out
			If licence.owner <> 0 Then Continue
			'ignore already announced movies
			If licence.getData().releaseAnnounced Then Continue
			'ignore unreleased
			If Not licence.ignoreUnreleasedProgrammes And licence.getData().year < licence._filterReleaseDateStart Or licence.getData().year > licence._filterReleaseDateEnd Then Continue
			'only add movies of "next X days" - 14 = 1 year
			Local licenceTime:Int = licence.GetData().year * Game.daysPerYear + licence.getData().releaseDay
			If licenceTime > Game.getDay() And licenceTime - Game.getDay() < 14 Then resultList.addLast(licence)
		Next
		If resultList.count() > 0 Then Return TProgrammeLicence._GetRandomFromList(resultList)

		Return Null
	End Method

	Method GetSpecialNewsEvent:TNewsEvent()
	End Method


	'announces new news chain elements
	Method ProcessNewsEventChains:Int()
		Local announced:Int = 0
		Local newsEvent:TNewsEvent = Null
		For Local chainElement:TNewsEvent = EachIn activeChains
			If Not chainElement.isLastEpisode() Then newsEvent = chainElement.GetNextNewsEventFromChain()
			'remove the "old" one, the new element will get added instead (if existing)
			activeChains.Remove(chainElement)

			'ignore if the chain ended already
			If Not newsEvent Then Continue

			If chainElement.happenedTime + newsEvent.getHappenDelay() < Game.timeGone
				announceNewsEvent(newsEvent)
				announced:+1
			EndIf
		Next

		'check every 10 game minutes
		Self.NextChainCheckTime = Game.timeGone + 10

		Return announced
	End Method

	Method AddNewsEventToPlayer:Int(newsEvent:TNewsEvent, forPlayer:Int=-1, fromNetwork:Int=0)
		'only add news/newsblock if player is Host/Player OR AI
		'If Not Game.isLocalPlayer(forPlayer) And Not Game.isAIPlayer(forPlayer) Then Return 'TODO: Wenn man gerade Spieler 2 ist/verfolgt (Taste 2) dann bekommt Spieler 1 keine News
		If Game.Players[ forPlayer ].newsabonnements[newsEvent.genre] > 0
			'print "[LOCAL] AddNewsToPlayer: creating newsblock, player="+forPlayer
			TNews.Create("", forPlayer, Game.Players[ forPlayer ].GetNewsAbonnementDelay(newsEvent.genre), newsEvent)
		EndIf
	End Method

	Method announceNewsEvent:Int(newsEvent:TNewsEvent, happenedTime:Int=0)
		newsEvent.doHappen(happenedTime)

		For Local i:Int = 1 To 4
			AddNewsEventToPlayer(newsEvent, i)
		Next

		If newsEvent.episodes.count() > 0 Then activeChains.AddLast(newsEvent)
	End Method

	Method AnnounceNewNewsEvent:Int(delayAnnouncement:Int=0)
		'no need to check for gameleader - ALL players
		'will handle it on their own - so the randomizer stays intact
		'if not Game.isGameLeader() then return FALSE
		Local newsEvent:TNewsEvent = Null
		'try to load some movie news ("new movie announced...")
		If Not newsEvent And RandRange(1,100)<35 Then newsEvent = Self.GetMovieNewsEvent()

		If Not newsEvent Then newsEvent = NewsEventCollection.GetRandom()

		If newsEvent
			Local NoOneSubscribed:Int = True
			For Local i:Int = 1 To 4
				If Game.Players[i].newsabonnements[newsEvent.genre] > 0 Then NoOneSubscribed = False
			Next
			'only add news if there are players wanting the news, else save them
			'for later stages
			If Not NoOneSubscribed
				'Print "[LOCAL] AnnounceNewNews: added news title="+news.title+", day="+Game.getDay(news.happenedtime)+", time="+Game.GetFormattedTime(news.happenedtime)
				announceNewsEvent(newsEvent, Game.timeGone + delayAnnouncement)
			EndIf
		EndIf

		If RandRange(0,10) = 1
			NextEventTime = Game.timeGone + Rand(20,50) 'between 20 and 50 minutes until next news
		Else
			NextEventTime = Game.timeGone + Rand(90,250) 'between 90 and 250 minutes until next news
		EndIf
	End Method
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
			Local room:TRooms
			Repeat
				room = TRooms(TRooms.rooms.ValueAtIndex(Rand(TRooms.rooms.Count() - 1)))
			Until room.doortype >0

			TDevHelper.Log("TFigurePostman", "nothing to do -> send to room " + room.name, LOG_DEBUG | LOG_AI, True)
			SendToRoom(room)
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
			If target And (Not Self.targetRoom Or (20 < Abs(targetRoom.pos.x - rect.GetX()) Or targetRoom.pos.y <> GetFloor()))
				If Rand(0,100) < Self.NormalCleanChance Then Self.currentAction = 1
			EndIf
			'if just standing around give a chance to clean
			If Not target And Rand(0,100) < Self.BoredCleanChance Then	Self.currentAction = 1
		EndIf

		If Not useDoors And Self.targetRoom Then Self.targetRoom = Null
	End Method
End Type





'#Region: Globals, Player-Creation
Global Interface:TInterface		= TInterface.Create()
Global Game:TGame	  			= new TGame.Create()
Global Building:TBuilding		= new TBuilding.Create()
'init sound receiver
TSoundManager.GetInstance().SetDefaultReceiver(TPlayerElementPosition.Create())


EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Create Rooms").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )
Init_CreateAllRooms() 				'creates all Rooms - with the names assigned at this moment

Game.Initialize() 'Game.CreateInitialPlayers()

'RON
Local haveNPCs:Int = True
If haveNPCs
	New TFigureJanitor.CreateFigure("Hausmeister", Assets.GetSprite("figure_Hausmeister"), 210, 2, 65)
	New TFigurePostman.CreateFigure("Bote1", Assets.GetSprite("BoteLeer"), 210, 3, 65, 0)
	New TFigurePostman.CreateFigure("Bote2", Assets.GetSprite("BoteLeer"), 410, 1, -65, 0)
EndIf


TDevHelper.Log("Base", "Creating GUIelements", LOG_DEBUG)
Global InGame_Chat:TGUIChat = New TGUIChat.Create(520,418,280,190,"InGame")
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
InGame_Chat.guiInput.maxTextWidth		= gfx_GuiPack.GetSprite("Chat_IngameOverlay").area.GetW() - 20
InGame_Chat.guiInput.spriteName = "Chat_IngameOverlay"
InGame_Chat.guiInput.color.AdjustRGB(255,255,255,True)
InGame_Chat.guiInput.SetValueDisplacement(0,5)


'connect click and change events to the gui objects
TGameEvents.Init()


Include "gamefunctions_network.bmx"

SetColor 255,255,255

Global PlayerDetailsTimer:Int = 0
Global MainMenuJanitor:TFigureJanitor = New TFigureJanitor.CreateFigure("Hausmeister", Assets.GetSprite("figure_Hausmeister"), 250, 2, 65)
MainMenuJanitor.useElevator = False
MainMenuJanitor.useDoors = False
MainMenuJanitor.useAbsolutePosition = True
MainMenuJanitor.BoredCleanChance = 30
MainMenuJanitor.MovementRangeMinX = 0
MainMenuJanitor.MovementRangeMaxX = 800
MainMenuJanitor.rect.position.SetY(600)


'add menu screens
Global ScreenGameSettings:TScreen_GameSettings = New TScreen_GameSettings.Create("GameSettings")
Global GameScreen_Building:TInGameScreen_Building = New TInGameScreen_Building.Create("InGame_Building")
'Menu
ScreenCollection.Add(New TScreen_MainMenu.Create("MainMenu"))
ScreenCollection.Add(ScreenGameSettings)
ScreenCollection.Add(New TScreen_NetworkLobby.Create("NetworkLobby"))
ScreenCollection.Add(New TScreen_StartMultiplayer.Create("StartMultiplayer"))
'Game screens
ScreenCollection.Add(GameScreen_Building)

'===== GAME SCREENS : MENUS =====


Global LogoTargetY:Float = 20
Global LogoCurrY:Float = 100
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
		guiButtonsWindow = New TGUIGameWindow.Create(300, 330, 200, 400, name)
		guiButtonsWindow.SetPadding(TScreen_GameSettings.headerSize, TGUISettings.panelGap, TGUISettings.panelGap, TGUISettings.panelGap)
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
		guiSettingsWindow.SetPadding(headerSize, TGUISettings.panelGap, TGUISettings.panelGap, TGUISettings.panelGap)

		guiPlayersPanel = guiSettingsWindow.AddContentBox(0,0,-1, playerBoxDimension.GetY() + 2 * TGUISettings.panelGap)
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
		guiButtonsWindow.SetPadding(headerSize, TGUISettings.panelGap, TGUISettings.panelGap, TGUISettings.panelGap)
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
		guiChat.SetPadding(headerSize, TGUISettings.panelGap, TGUISettings.panelGap, TGUISettings.panelGap)
		guiChat.SetCaption("Chat")
		guiChat.guiList.Resize(guiChat.guiList.rect.GetW(), guiChat.guiList.rect.GetH()-10)
		guiChat.guiInput.rect.position.MoveXY(TGUISettings.panelGap, -TGUISettings.panelGap)
		guiChat.guiInput.Resize( guiChat.GetContentScreenWidth() - 2* TGUISettings.panelGap, guiStartYear.GetScreenHeight())

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
					If Not Game.networkgame And Not Game.onlinegame
						Game.SetGamestate(TGame.STATE_INITIALIZEGAME)
						If Not Init_Complete
							Init_All()
							Init_Complete = True		'check if rooms/colors/... are initiated
						EndIf
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
		guiButtonsWindow = New TGUIGameWindow.Create(590, 355, 200, 235, name)
		guiButtonsWindow.SetPadding(TScreen_GameSettings.headerSize, TGUISettings.panelGap, TGUISettings.panelGap, TGUISettings.panelGap)
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
		guiGameListWindow.SetPadding(TScreen_GameSettings.headerSize, TGUISettings.panelGap, TGUISettings.panelGap, TGUISettings.panelGap)
		guiGameListWindow.guiBackground.spriteAlpha = 0.5
		guiGameListWindow.SetCaption(GetLocale("AVAILABLE_GAMES"))

		guiGameList	= New TGUIGameList.Create(20,355,520,235,name)
		guiGameList.SetBackground(Null)
		guiGameList.SetPadding(0, 0, 0, 0)

		Local guiGameListPanel:TGUIBackgroundBox = guiGameListWindow.AddContentBox(0,0,-1,-1)
		guiGameListPanel.AddChild(guiGameList)


		'register clicks on TGUIGameEntry-objects -> game list
		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickGameListEntry", "TGUIGameEntry")
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
	Method onClickGameListEntry:Int(triggerEvent:TEventBase)
		Local entry:TGUIGameEntry = TGUIGameEntry(triggerEvent.getSender())
		If Not entry Then Return False

		'we are only interested in doubleclicks
		Local clickType:Int = triggerEvent.getData().getInt("type", 0)
		If clickType = EVENT_GUI_DOUBLECLICK
			JoinSelectedGameEntry()
		EndIf
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





Global headerFont:TGW_BitmapFont

'go into the start menu
Game.SetGamestate(TGame.STATE_MAINMENU)







Function Init_Creation()
	'create base stations
	For Local i:Int = 1 To 4
		Game.GetPlayer(i).GetStationMap().AddStation( TStation.Create( TPoint.Create(310, 260),-1, TStationMap.stationRadius, i ), False )
	Next

	'get names from settings
	For Local i:Int = 1 To 4
		Game.Players[i].Name		= ScreenGameSettings.guiPlayerNames[i-1].Value
		Game.Players[i].channelname	= ScreenGameSettings.guiChannelNames[i-1].Value
	Next


	'disable chat if not networkgaming
	If Not game.networkgame
		InGame_Chat.hide()
	Else
		InGame_Chat.show()
	EndIf

	'Eigentlich gehört das irgendwo in die Game-Klasse... aber ich habe keinen passenden Platz gefunden... und hier werden auch die anderen Events registriert
	EventManager.registerListenerMethod( "Game.OnHour", Game.PopularityManager, "Update" );

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

		playerPlan.AddAdvertisement(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 0 )
		playerPlan.AddAdvertisement(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 1 )
		playerPlan.AddAdvertisement(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 2 )
		playerPlan.AddAdvertisement(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 3 )
		playerPlan.AddAdvertisement(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 4 )
		playerPlan.AddAdvertisement(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), Game.GetStartDay(), 5 )

		Local currentLicence:TProgrammeLicence = Null
		Local currentHour:Int = 0
		For Local i:Int = 0 To 3
			currentLicence = playerCollection.GetMovieLicenceAtIndex(i)
			If Not currentLicence Then Continue
			playerPlan.AddProgramme(TProgramme.Create(currentLicence), Game.GetStartDay(), currentHour )
			currentHour:+ currentLicence.getData().getBlocks()
		Next
	Next
End Function

Function Init_Colorization()
	'colorize the images
	Local gray:TColor = TColor.Create(200, 200, 200)
	Local gray2:TColor = TColor.Create(100, 100, 100)
	Assets.AddImageAsSprite("gfx_financials_barren0", Assets.GetSprite("gfx_officepack_financials_barren").GetColorizedImage(gray))
	Assets.AddImageAsSprite("gfx_building_sign0", Assets.GetSprite("gfx_building_sign_base").GetColorizedImage(gray))
	Assets.AddImageAsSprite("gfx_elevator_sign0", Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage(gray))
	Assets.AddImageAsSprite("gfx_elevator_sign_dragged0", Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage(gray))
	Assets.AddImageAsSprite("gfx_interface_channelbuttons_off0", Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage(gray2))
	Assets.AddImageAsSprite("gfx_interface_channelbuttons_on0", Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage(gray2))

	'colorizing for every player
	For Local i:Int = 1 To 4
		Game.GetPlayer(i).RecolorFigure()
		local color:TColor = Game.GetPlayer(i).color
		Assets.AddImageAsSprite("gfx_financials_barren"+i, Assets.GetSprite("gfx_officepack_financials_barren").GetColorizedImage(color))
		Assets.AddImageAsSprite("gfx_building_sign"+i, Assets.GetSprite("gfx_building_sign_base").GetColorizedImage(color))
		Assets.AddImageAsSprite("gfx_elevator_sign"+i, Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage(color))
		Assets.AddImageAsSprite("gfx_elevator_sign_dragged"+i, Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage(color))
		Assets.AddImageAsSprite("gfx_interface_channelbuttons_off"+i, Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage(color, i))
		Assets.AddImageAsSprite("gfx_interface_channelbuttons_on"+i, Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage(color, i))
	Next
End Function


Function Init_All()
	TDevHelper.Log("Init_All()", "start", LOG_DEBUG)
	Init_Creation()
	TDevHelper.Log("Init_All()", "colorizing images corresponding to playercolors", LOG_DEBUG)
	Init_Colorization()
	'triggering that event also triggers app.timer.loop which triggers update/draw of
	'gamesstates - which runs this again etc.
	EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Create Roomtooltips").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )
	'setzt Raumnamen, erstellt Raum-Tooltips und Raumplaner-Schilder
	Init_CreateRoomDetails()

	EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Fill background of building").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )

	TDevHelper.Log("Init_All()", "drawing door-sprites on the building-sprite", LOG_DEBUG)
	TRooms.DrawDoorsOnBackground()		'draws the door-sprites on the building-sprite

	TDevHelper.Log("Init_All()", "drawing plants and lights on the building-sprite", LOG_DEBUG)
	Building.Init()	'draws additional gfx in the sprite, registers events...

	TDevHelper.Log("Init_All()", "complete", LOG_LOADING)
End Function


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

		'===== CHANGE OFFER OF MOVIEAGENCY AND ADAGENCY =====
		'countdown for the refillers
		Game.refillMovieAgencyTime :-1
		Game.refillAdAgencyTime :-1
		'refill if needed
		If Game.refillMovieAgencyTime <= 0
			'delay if there is one in this room
			If TRooms.GetRoomByDetails("movieagency",0).hasOccupant()
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
			If TRooms.GetRoomByDetails("adagency",0).hasOccupant()
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
		If minute = 5 Or minute = 55 Or minute=0 Then Interface.BottomImgDirty = True
		'begin of all newshows - compute their audience
		If minute = 0
			'if not done yet - produce the newsshow
			For Local i:Int = 1 To 4
				If Game.getPlayer(i) Then Game.getPlayer(i).ProgrammePlan.GetNewsShow(day,hour)
			Next
			Game.BroadcastManager.BroadcastNewsShow(day, hour)
		EndIf
		'begin of all programmeblocks - compute their audience
		If minute = 5 Then Game.BroadcastManager.BroadcastProgramme(day, hour)

		'for individual players
		For Local player:TPlayer = EachIn Game.Players
			'begin of a newshow
			If minute = 0
				'a news show exists - even without news
				player.ProgrammePlan.GetNewsShow().BeginBroadcasting(day, hour, minute)
			'begin of a programme
			ElseIf minute = 5
				Local obj:TBroadcastMaterial = player.ProgrammePlan.GetProgramme(day, hour)
				If obj
					'just starting
					If 1 = player.ProgrammePlan.GetProgrammeBlock(day, hour)
						obj.BeginBroadcasting(day, hour, minute)
					Else
						obj.ContinueBroadcasting(day, hour, minute)
					EndIf
				EndIf
			'call-in shows/quiz - generate income
			ElseIf minute = 54
				Local obj:TBroadcastMaterial = player.ProgrammePlan.GetProgramme(day,hour)
				If obj
					If obj.GetBlocks() = player.ProgrammePlan.GetProgrammeBlock(day, hour)
						obj.FinishBroadcasting(day, hour, minute)
					Else
						obj.BreakBroadcasting(day, hour, minute)
					EndIf
				EndIf
			'ads
			ElseIf minute = 55
				'computes ads - if an ad is botched or run successful
				'if adcontract finishes, earn money
				Local obj:TBroadcastMaterial = Player.ProgrammePlan.GetAdvertisement(day, hour)
				If obj
					'just starting
					If 1 = player.ProgrammePlan.GetAdvertisementBlock(day, hour)
						obj.BeginBroadcasting(day, hour, minute)
					Else
						obj.ContinueBroadcasting(day, hour, minute)
					EndIf
				EndIf				'ads end - so trailers can set their "ok"
			ElseIf minute = 59
				Local obj:TBroadcastMaterial = Player.ProgrammePlan.GetAdvertisement(day, hour)
				If obj
					If obj.GetBlocks() = player.ProgrammePlan.GetAdvertisementBlock(day, hour)
						obj.FinishBroadcasting(day, hour, minute)
					Else
						obj.BreakBroadcasting(day, hour, minute)
					EndIf
				EndIf
			EndIf
		Next
		Return True
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
			TRoomSigns.ResetPositions()

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

			Local shadowSettings:TData = TData.Create().addNumber("size", 1).addNumber("intensity", 0.5)
			Local gradientSettings:TData = TData.Create().addNumber("gradientBottom", 180)
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
		KEYMANAGER.changeStatus()
		MOUSEMANAGER.changeStatus()
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

				If KEYMANAGER.IsHit(KEY_W) Then DEV_switchRoom(TRooms.GetRoomByDetails("adagency", 0) )
				If KEYMANAGER.IsHit(KEY_A) Then DEV_switchRoom(TRooms.GetRoomByDetails("archive", Game.playerID) )
				If KEYMANAGER.IsHit(KEY_B) Then DEV_switchRoom(TRooms.GetRoomByDetails("betty", 0) )
				If KEYMANAGER.IsHit(KEY_F) Then DEV_switchRoom(TRooms.GetRoomByDetails("movieagency", 0))
				If KEYMANAGER.IsHit(KEY_O) Then DEV_switchRoom(TRooms.GetRoomByDetails("office", Game.playerID))
				If KEYMANAGER.IsHit(KEY_C) Then DEV_switchRoom(TRooms.GetRoomByDetails("chief", Game.playerID))
				If KEYMANAGER.IsHit(KEY_N) Then DEV_switchRoom(TRooms.GetRoomByDetails("news", Game.playerID))
				If KEYMANAGER.IsHit(KEY_R) Then DEV_switchRoom(TRooms.GetRoomByDetails("roomboard", -1))

rem
				If KEYMANAGER.IsHit(KEY_W) Then Game.getPlayer().Figure.EnterRoom( TRooms.GetRoomByDetails("adagency", 0), True )
				If KEYMANAGER.IsHit(KEY_A) Then Game.getPlayer().Figure.EnterRoom( TRooms.GetRoomByDetails("archive", Game.playerID), True )
				If KEYMANAGER.IsHit(KEY_B) Then Game.getPlayer().Figure.EnterRoom( TRooms.GetRoomByDetails("betty", 0), True )
				If KEYMANAGER.IsHit(KEY_F) Then Game.getPlayer().Figure.EnterRoom( TRooms.GetRoomByDetails("movieagency", 0), True )
				If KEYMANAGER.IsHit(KEY_O) Then Game.getPlayer().Figure.EnterRoom( TRooms.GetRoomByDetails("office", Game.playerID), True )
				If KEYMANAGER.IsHit(KEY_C) Then Game.getPlayer().Figure.EnterRoom( TRooms.GetRoomByDetails("chief", Game.playerID), True )
				If KEYMANAGER.IsHit(KEY_N) Then Game.getPlayer().Figure.EnterRoom( TRooms.GetRoomByDetails("news", Game.playerID), True )
				If KEYMANAGER.IsHit(KEY_R) Then Game.getPlayer().Figure.EnterRoom( TRooms.GetRoomByDetails("roomboard", -1), True )
endrem
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
			For Local i:Int = 0 To 3
				If Game.Players[i + 1].Figure.inRoom <> Null
					Assets.fonts.baseFont.draw("Player " + (i + 1) + ": " + Game.Players[i + 1].Figure.inRoom.Name, 25, 80 + i * 11)
				Else
					If Game.Players[i + 1].Figure.IsInElevator()
						Assets.fonts.baseFont.draw("Player " + (i + 1) + ": InElevator", 25, 80 + i * 11)
					Else If Game.Players[i + 1].Figure.IsAtElevator()
						Assets.fonts.baseFont.draw("Player " + (i + 1) + ": AtElevator", 25, 80 + i * 11)
					Else
						Assets.fonts.baseFont.draw("Player " + (i + 1) + ": Building", 25, 80 + i * 11)
					EndIf
				EndIf
			Next

			if ScreenCollection.GetCurrentScreen()
				Assets.fonts.baseFont.draw("Showing screen: "+ScreenCollection.GetCurrentScreen().name, 25, 130)
			else
				Assets.fonts.baseFont.draw("Showing screen: Main", 25, 130)
			endif


			Assets.fonts.baseFont.draw("elevator routes:", 25,150)
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
		EndIf
		If Game.DebugQuoteInfos
			TDebugQuoteInfos.Draw()
		EndIf




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


Function DEV_switchRoom:int(room:TRooms)
	if not room then return FALSE
	local figure:TFigure = Game.GetPlayer().figure

	local oldEffects:int = TScreenCollection.useChangeEffects
	local oldSpeed:int = TRooms.ChangeRoomSpeed

	'to avoid seeing too much animation
	TRooms.ChangeRoomSpeed = 0
	TScreenCollection.useChangeEffects = FALSE

	TInGameScreen_Room.shortcutTarget = room 'to skip animation
	figure.EnterRoom(room)

	TRooms.ChangeRoomSpeed = 500
	TScreenCollection.useChangeEffects = TRUE

	return TRUE
End Function


'===== EVENTS =====
EventManager.registerListenerFunction("Game.OnDay", 	GameEvents.OnDay )
EventManager.registerListenerFunction("Game.OnMinute",	GameEvents.OnMinute )
EventManager.registerListenerFunction("Game.OnStart",	TGame.onStart )


'RONKI
Rem
print "ALLE SPIELER DEAKTIVIERT"
print "ALLE SPIELER DEAKTIVIERT"
print "ALLE SPIELER DEAKTIVIERT"
print "ALLE SPIELER DEAKTIVIERT"
print "ALLE SPIELER DEAKTIVIERT"
for local fig:TFigure = eachin FigureCollection.list
	if not fig.isActivePlayer() then fig.moveable = false
Next
KIRunning = False
print "[DEV] AI FIGURES deactivated"
endrem


Global Curves:TNumberCurve = TNumberCurve.Create(1, 200)

Global Init_Complete:Int = 0

'Init EventManager
'could also be done during update ("if not initDone...")
EventManager.Init()
App.Start() 'all resources loaded - switch Events for Update/Draw from Loader to MainEvents

Global RefreshInput:Int = True
?Threaded
Global RefreshInputMutex:TMutex = CreateMutex()
?

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


OnEnd( EndHook )
Function EndHook()
	TProfiler.DumpLog("log.profiler.txt")
	TLogFile.DumpLog(False)
End Function