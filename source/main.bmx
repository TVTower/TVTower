'Application: TVGigant/TVTower
'Author: Ronny Otto & Team

SuperStrict

Import Brl.Stream
Import Brl.Retro

Import brl.timer
Import brl.eventqueue
Import brl.Threads
Import Archive.ZSTD
Import Archive.gzip
Import Archive.RAW

'Import "Dig/external/persistence.mod/persistence_json.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.registry.imageloader.bmx"
Import "Dig/base.util.registry.bitmapfontloader.bmx"
Import "Dig/base.util.registry.soundloader.bmx"
Import "Dig/base.util.registry.spriteentityloader.bmx"

Import "Dig/base.util.deltatimer.bmx"
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.interpolation.bmx"
Import "Dig/base.util.graphicsmanager.bmx"
Import "Dig/base.util.data.xmlstorage.bmx"
Import "Dig/base.util.profiler.bmx"
Import "Dig/base.util.directorytree.bmx"

Import "Dig/base.gfx.sprite.particle.bmx"

Import "Dig/base.framework.entity.bmx"
Import "Dig/base.framework.entity.spriteentity.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"

Import "Dig/base.gfx.gui.bmx"
Import "Dig/base.gfx.gui.list.slotlist.bmx"
Import "Dig/base.gfx.gui.list.selectlist.bmx"
Import "Dig/base.gfx.gui.dropdown.bmx"
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "Dig/base.gfx.gui.input.bmx"
Import "Dig/base.gfx.gui.window.modal.bmx"
Import "Dig/base.gfx.gui.window.modalchain.bmx"
Import "Dig/base.framework.tooltip.bmx"

'actually load the sound implementation (not the stub base class)
Import "Dig/base.sfx.soundmanager.bmx"


Import "basefunctions_network.bmx"
Import "basefunctions.bmx"
Import "common.misc.screen.bmx"
Import "common.misc.dialogue.bmx"
'Import "common.misc.gamegui.bmx"

Import "game.menu.settings.bmx"

'game specific
Import "game.world.bmx"
Import "game.toastmessage.bmx"
Import "game.gameinformation.bmx"
Import "game.registry.loaders.bmx"
Import "game.exceptions.bmx"

'Import "game.gamerules.bmx"

'Import "game.room.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.figure.bmx"
Import "game.figure.customfigures.bmx"
'Import "game.player.finance.bmx"
'Import "game.player.boss.bmx"
'Import "game.player.bmx"
Import "game.ai.bmx"

Import "game.database.bmx"
'Import "game.game.base.bmx"
Import "game.game.bmx"
Import "game.production.bmx"

Import "game.achievements.bmx"

Import "game.betty.bmx"
Import "game.award.bmx"
Import "game.building.bmx"
Import "game.ingameinterface.bmx"
Import "game.newsagency.bmx"
Import "game.roomagency.bmx"

'Import "game.roomhandler.base.bmx"
Import "game.roomhandler.adagency.bmx"
Import "game.roomhandler.archive.bmx"
Import "game.roomhandler.betty.bmx"
Import "game.roomhandler.credits.bmx"
Import "game.roomhandler.elevatorplan.bmx"
Import "game.roomhandler.movieagency.bmx"
Import "game.roomhandler.news.bmx"
Import "game.roomhandler.office.bmx"
Import "game.roomhandler.roomagency.bmx"
Import "game.roomhandler.roomboard.bmx"
Import "game.roomhandler.scriptagency.bmx"
Import "game.roomhandler.studio.bmx"
Import "game.roomhandler.supermarket.bmx"

Import "game.misc.ingamehelp.bmx"
Import "game.gamescriptexpression.bmx"

Import "game.screen.menu.bmx"

Import "gameDebug/game.debug.screen.page.overview.bmx"
Import "gameDebug/game.debug.screen.page.playercommands.bmx"
Import "gameDebug/game.debug.screen.page.playerfinancials.bmx"
Import "gameDebug/game.debug.screen.page.playerbroadcasts.bmx"
Import "gameDebug/game.debug.screen.page.publicimages.bmx"
Import "gameDebug/game.debug.screen.page.stationmap.bmx"
Import "gameDebug/game.debug.screen.page.adagency.bmx"
Import "gameDebug/game.debug.screen.page.movieagency.bmx"
Import "gameDebug/game.debug.screen.page.newsagency.bmx"
Import "gameDebug/game.debug.screen.page.scriptagency.bmx"
Import "gameDebug/game.debug.screen.page.roomagency.bmx"
Import "gameDebug/game.debug.screen.page.politics.bmx"
Import "gameDebug/game.debug.screen.page.customproductions.bmx"
Import "gameDebug/game.debug.screen.page.producers.bmx"
Import "gameDebug/game.debug.screen.page.sports.bmx"
Import "gameDebug/game.debug.screen.page.modifiers.bmx"
Import "gameDebug/game.debug.screen.page.misc.bmx"

Import "game.network.networkhelper.bmx"
Import "game.misc.savegameserializers.bmx"
?bmxng
Import "Dig/base.util.bmxng.objectcountmanager.bmx"
?


?Not bmxng
'notify users when there are XML-errors
Function TVTXmlErrorCallback(data:Object, error:TxmlError)
	Local result:String = "XML-Error~n"
	result :+ "Error: "+ error.getErrorMessage()+"~n"
	result :+ "File:  "+ error.getFileName()+":"+error.getLine()+"@"+error.getColumn()+"~n"
	Notify result

	TLogger.Log("XML-Error", error.getErrorMessage(), LOG_ERROR)
	TLogger.Log("XML-Error", "File:  "+ error.getFileName()+". Line:"+error.getLine()+" Column:"+error.getColumn(), LOG_ERROR)
End Function
xmlSetErrorFunction(TVTXmlErrorCallback, Null)
?

'===== Includes =====

'Types: - TError - Errorwindows with handling
'		- base class For buttons And extension newsbutton
Include "gamefunctions.bmx"

Include "gamefunctions_rooms.bmx"				'basic roomtypes with handling
Include "gamefunctions_sound.bmx"				'TVTower spezifische Sounddefinitionen
Include "gameDebug/gamefunctions_debug.bmx"

Include "game.menu.escapemenu.bmx"


'===== Globals =====
VersionDate = LoadText("incbin::source/version.txt").Trim()
VersionString = "v0.8.2"
CopyrightString = "by Ronny Otto & Team"

Global APP_NAME:String = "TVTower"
Global PROFILER_LOG_NAME:String = "log.profiler.txt"

Global App:TApp = Null
Global MainMenuJanitor:TFigureJanitor
Global ScreenGameSettings:TScreen_GameSettings = Null
Global ScreenMainMenu:TScreen_MainMenu = Null
Global Init_Complete:Int = 0

Global RURC:TRegistryUnloadedResourceCollection = TRegistryUnloadedResourceCollection.GetInstance()

Global debugCreationTime:Int = MilliSecs()
Global printDebugStats:Int = True
Global collectDebugStats:Int = True
OCM.enabled = False & (collectDebugStats = True)
OCM.printEnabled = False & (collectDebugStats = True)

'disable profiler
TProfiler.activated = False

Global _profilerKey_Draw:TLowerString = New TLowerString.Create("Draw")
Global _profilerKey_Update:TLowerString = New TLowerString.Create("Update")
Global _profilerKey_RessourceLoader:TLowerString = New TLowerString.Create("RessourceLoader")
'AI minute key moved to TDebugScreenPage_Overview, so it can be evaluated in the screen
Global _profilerKey_AI_SECOND:TLowerString[] = [New TLowerString.Create("PLAYER_AI1_SECOND"), New TLowerString.Create("PLAYER_AI2_SECOND"), New TLowerString.Create("PLAYER_AI3_SECOND"), New TLowerString.Create("PLAYER_AI4_SECOND")]

DebugProfiler.active = False 'True
DebugProfiler.ObserveCall(_profilerKey_Update)
DebugProfiler.ObserveCall(_profilerKey_Draw)
DebugProfiler.ObserveCall("GameLoop::Draw")
DebugProfiler.ObserveCall("GameLoop::Update")
DebugProfiler.ObserveCall(TDebugScreenPage_Overview._profilerKey_AI_MINUTE[0])
DebugProfiler.ObserveCall(TDebugScreenPage_Overview._profilerKey_AI_MINUTE[1])
DebugProfiler.ObserveCall(TDebugScreenPage_Overview._profilerKey_AI_MINUTE[2])
DebugProfiler.ObserveCall(TDebugScreenPage_Overview._profilerKey_AI_MINUTE[3])


'==== Initialize ====
AppTitle = "TVTower: " + VersionString + " Build ~q" + VersionDate+"~q"
TLogger.Log("CORE", "Starting "+APP_NAME+", "+VersionString + " Build ~q" + VersionDate+"~q.", LOG_INFO )

'===== SETUP LOGGER FILTER =====
TLogger.setLogMode(LOG_ALL )
TLogger.setPrintMode(LOG_ALL ) '(LOG_AI | LOG_ERROR | LOG_SAVELOAD )
'TLogger.SetPrintMode(0) 'all messages off
'TLogger.SetPrintMode(LOG_ALL &~ LOG_AI ) 'all but ai
'THIS IS TO REMOVE CLUTTER FOR NON-DEVS
'TLogger.changePrintMode(LOG_DEV, FALSE)



'Enthaelt Verbindung zu Einstellungen und Timern, sonst nix
Type TApp
	'mobile devices: running in background or foreground?
	Field runningInBackground:Int = False
	'developer/base configuration
	Field configBase:TData = New TData
	'configuration containing base + user
	Field config:TData = New TData
	'draw logo for screenshot ?
	Field prepareScreenshot:Int	= 0

	'only used for debug purpose (loadingtime)
	Field creationTime:Long
	'store listener for music loaded in "startup"
	Field OnLoadMusicListener:TEventListenerBase

	Field settingsWindow:TSettingsWindow

	'bitmask defining what elements set the game to paused (eg. escape
	'menu, ingame help ...)
	Field pausedBy:Int = 0

	Global spriteMouseCursor:TSprite {nosave}

	'able to draw loading screen?
	Global baseResourcesLoaded:Int = 0
	'holds bg for loading screen and more
	Global baseResourceXmlUrl:String = "config/startup.xml"
	'boolean value: 1 and the game will exit
	Global ExitApp:Int = 0
	Global ExitAppDialogue:TGUIModalWindow = Null
	'creation time for "double escape" to abort
	Global ExitAppDialogueTime:Long = 0
	'Global ExitAppDialogueEventListeners:TLink = TLink[]
	Global EscapeMenuWindow:TGUIModalWindowChain = Null
	'creation time for "double escape" to abort
	Global EscapeMenuWindowTime:Long = 0
	'Global EscapeMenuWindowEventListeners:TLink[]

	Global DEV_FastForward:Int = False
	Global DEV_FastForward_TargetReached:Int = True
	Global DEV_FastForward_SpeedFactorBackup:Float = 0.0
	Global DEV_FastForward_TimeFactorBackup:Float = 0.0
	Global DEV_FastForward_BuildingTimeSpeedFactorBackup:Float = 0.0

	Global settingsBasePath:String = "config/settings.xml"
	Global settingsUserPath:String = "config/settings.user.xml"

	Const PAUSED_BY_ESCAPEMENU:Int = 1
	Const PAUSED_BY_EXITDIALOGUE:Int = 2
	Const PAUSED_BY_INGAMEHELP:Int = 4
	Const PAUSED_BY_MODALWINDOW:Int = 8

	Global systemState:TLowerString = TLowerString.Create("SYSTEM")

	Function Create:TApp(updatesPerSecond:Int = 60, framesPerSecond:Int = 30, vsync:Int=True, initializeGUI:Int=True)
		Local obj:TApp = New TApp
		obj.creationTime = Time.MillisecsLong()

		If initializeGUI Then
			'register to:
			'- quit confirmation dialogue
			'- handle saving/applying of settings
			EventManager.registerListenerFunction(GUIEventKeys.GUIModalWindow_OnClose, onCloseModalDialogue )
			EventManager.registerListenerFunction(GUIEventKeys.GUIModalWindowChain_OnClose, onCloseEscapeMenu )
			EventManager.registerListenerFunction(TRegistryLoader.eventKey_OnLoadXmlFromFinished, TApp.onLoadXmlFromFinished )
			obj.OnLoadMusicListener = EventManager.registerListenerFunction(TRegistryLoader.eventKey_OnLoadResource, TApp.onLoadMusicResource )

			?debug
			EventManager.registerListenerFunction(TRegistryLoader.eventKey_OnLoadResource, TApp.onLoadResource )
			EventManager.registerListenerFunction(TRegistryLoader.eventKey_OnBeginLoadResource, TApp.onBeginLoadResource )
			?

			obj.LoadSettings()
			'override default settings with app arguments (params when executing)
			obj.ApplyAppArguments()
			'do not init graphics, this is done some lines later
			obj.ApplySettings(False)

			GetDeltatimer().Init(updatesPerSecond, obj.config.GetInt("fps", framesPerSecond))
			GetDeltaTimer()._funcUpdate = update
			GetDeltaTimer()._funcRender = render

			GetGraphicsManager().SetVsync(obj.config.GetBool("vsync", vsync))
			'GetGraphicsManager().SetResolution(1024,768)
			If GetGraphicsManager().GetFullscreen()
				GetGraphicsManager().SetResolution(800, 600)
			Else
				GetGraphicsManager().SetResolution(obj.config.GetInt("screenW", 800), obj.config.GetInt("screenH", 600))
			EndIf
			GetGraphicsManager().SetDesignedResolution(800,600)
			GetGraphicsManager().InitGraphics()

			GameConfig.InRoomTimeSlowDownMod = obj.config.GetInt("inroomslowdown", 100) / 100.0
			GameConfig.autoSaveIntervalHours = obj.config.GetInt("autosaveInterval", 0)

			MouseManager._minSwipeDistance = obj.config.GetInt("touchClickRadius", 10)
			MouseManager._ignoreFirstClick = obj.config.GetBool("touchInput", False)
			MouseManager._longClickLeadsToRightClick = obj.config.GetBool("rightClickEmulation", False)
			MouseManager.longClickMinTime = obj.config.GetInt("rightClickEmulationTime", 400)

			IngameHelpWindowCollection.showHelp = obj.config.GetBool("showIngameHelp", True)


			TLogger.Log("App.Create()", "Loading base resources.", LOG_DEBUG)
			'load graphics needed for loading screen,
			'load directly (no delayed loading)
			obj.LoadResources(obj.baseResourceXmlUrl, True)


			'connect sprite provider
			TBitmapFont._spriteProvider = BitmapFontSpriteProvider
			
			'load extra game config from base resources

			'targetgroup colors
			GameConfig.targetGroupColors = New SColor8[TVTTargetGroup.count + 1] 'include 0/ALL
			For Local tgIndex:int = 0 until TVTTargetGroup.count
				Local tgColor:TColor = TColor(GetRegistry().Get("targetGroupColors::" + TVTTargetGroup.GetIndexAsString(tgIndex)))
				if tgColor
					GameConfig.targetGroupColors[tgIndex] = new SColor8(tgColor.r, tgColor.g, tgColor.b)
				EndIf
			Next

			'player colors
			Local playerColorList:TList = TList(GetRegistry().Get("playerColors"))
			If not playerColorList Then Throw "no playerColors found in configuration"
			For local color:TColor = EachIn playerColorList
				Local pColor:TPlayerColor = TPlayerColor.Create(color.r,color.g,color.b,color.a)
				pColor.Register()
			Next
		EndIf

		Return obj
	End Function
	
	
	Function BitmapFontSpriteProvider:TSprite(name:String)
		Return GetSpriteFromRegistry(name)
	End Function


	'check for various arguments to the binary (eg. "TVTower -opengl")
	Method ApplyAppArguments:Int()
		Local argNumber:Int = 0
		For Local arg:String = EachIn AppArgs
			'only interested in args starting with "-"
			If arg.Find("-") <> 0 Then Continue

			Select arg.ToLower()
				?Win32
				Case "-directx7", "-directx"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 7", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX7)
					config.AddNumber("renderer", GetGraphicsManager().RENDERER_DIRECTX7)
				Case "-directx9"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 9", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX9)
					config.AddNumber("renderer", GetGraphicsManager().RENDERER_DIRECTX9)
				Case "-directx11"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 11", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX11)
					config.AddNumber("renderer", GetGraphicsManager().RENDERER_DIRECTX11)
				?
				Case "-opengl"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: OpenGL", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_OPENGL)
					config.AddNumber("renderer", GetGraphicsManager().RENDERER_OPENGL)
				Case "-bufferedopengl"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: Buffered OpenGL", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_BUFFEREDOPENGL)
					config.AddNumber("renderer", GetGraphicsManager().RENDERER_BUFFEREDOPENGL)
			End Select
		Next
	End Method


	Function onBeginLoadResource:Int( triggerEvent:TEventBase )
		Local resourceName:String = triggerEvent.GetData().GetString("resourceName")
		Local name:String = triggerEvent.GetData().GetString("name")
		TLogger.Log("App.onLoadResource", "Loading ~q"+name+"~q ["+resourceName+"]", LOG_LOADING)
	End Function


	Function onLoadResource:Int( triggerEvent:TEventBase )
		Local resourceName:String = triggerEvent.GetData().GetString("resourceName")
		Local name:String = triggerEvent.GetData().GetString("name")
		TLogger.Log("App.onLoadResource", "Loaded ~q"+name+"~q ["+resourceName+"]", LOG_LOADING)
	End Function



	'if no startup-music was defined, try to play menu music if some
	'is loaded
	Function onLoadMusicResource:Int( triggerEvent:TEventBase )
		Local resourceName:String = triggerEvent.GetData().GetString("resourceName")
		If resourceName = "MUSIC"
			'if no music is played yet, try to get one from the "menu"-playlist
			If Not GetSoundManager().isPlaying() Then GetSoundManager().PlayMusicPlaylist("menu")
		EndIf
	End Function


	Function onLoadXmlFromFinished:Int( triggerEvent:TEventBase )
		If triggerEvent.getData().getString("uri") = TApp.baseResourceXmlUrl
			TApp.baseResourcesLoaded = 1
		EndIf
	End Function


	Method IsRunningInBackground:Int()
		Return runningInBackground
	End Method


	Method SetRunningInBackground:Int(bool:Int=True)
		runningInBackground = bool
	End Method


	Method ProcessRunningInBackground()
		If Not IsRunningInBackground() Then Return

		While IsRunningInBackground()
			'TODO: store "setRunningInBackground()" time and adjust
			'      delay according to the time being in background
			Delay(250)
			PollEvent()
		Wend
	End Method


	Method CreateSettingsWindow()
		'load config
		LoadSettings()

		If settingsWindow Then settingsWindow.Remove()
		settingsWindow = New TSettingsWindow.Init() '.Create(New TVec2D(), New TVec2D(520,45), "SYSTEM")
		'fill values
		settingsWindow.SetGuiValues(App.config)

	End Method


	Method ApplySettingsWindow:Int()
		'append values stored in gui elements
		ApplyConfigToSettings( settingsWindow.ReadGuiValues() )
	End Method


	Method ApplyConfigToSettings(newConfig:TData)
		Local mixedConfig:TData = App.config.copy()
		'append values stored in gui elements
		mixedConfig.Append(newConfig)

		SaveSettings(mixedConfig)
		'save the new config as current config
		config = mixedConfig
		'and "reinit" settings
		ApplySettings()

		'=== GAME SETTINGS ===
		If Not GetGame().PlayingAGame()
			GetGame().SetStartYear( config.GetInt("startyear", 0) )
		EndIf
	End Method


	Method LoadSettings:Int()
		Local storage:TDataXmlStorage = New TDataXmlStorage
		storage.SetRootNodeKey("config")
		'load default config
		configBase = storage.Load(settingsBasePath)
		If Not configBase Then configBase = New TData

		'load custom config and merge to a useable "total" config
		config = configBase.copy().Append(storage.Load(settingsUserPath))

		'make config available via registry
		GetRegistry().Set("appConfig", config)
	End Method


	Method SaveSettings:Int(newConfig:TData)
		'save the data differing to the default config
		'that "-" sets libxml to output the content instead of writing to
		'a file. Normally you should write to "test.user.xml" to overwrite
		'the users customized settings

		'remove "DEV_" ignore key so they get stored too
		Local storage:TDataXmlStorage = New TDataXmlStorage
		storage.SetRootNodeKey("config")
		storage.SetIgnoreKeysStartingWith("")
		storage.Save(settingsUserPath, newConfig.GetDifferenceTo(Self.configBase))
	End Method


	Method ApplySettings:Int(doInitGraphics:Int = True)
		Local adjusted:Int = False
		If GetGraphicsManager().SetFullscreen(config.GetBool("fullscreen", False), False)
			TLogger.Log("ApplySettings()", "SetFullscreen = "+config.GetBool("fullscreen", False), LOG_DEBUG)
			'until GLSDL works as intended:
			?Not bmxng
			adjusted = True
			?
		EndIf
		If GetGraphicsManager().SetRenderer(config.GetInt("renderer", GetGraphicsManager().GetRenderer()))
			TLogger.Log("ApplySettings()", "SetRenderer = "+config.GetInt("renderer", GetGraphicsManager().GetRenderer()), LOG_DEBUG)
			'until GLSDL works as intended:
			?Not bmxng
			adjusted = True
			?
		EndIf
		If GetGraphicsManager().SetColordepth(config.GetInt("colordepth", 16))
			TLogger.Log("ApplySettings()", "SetColordepth = "+config.GetInt("colordepth", -1), LOG_DEBUG)
			'until GLSDL works as intended:
			?Not bmxng
			adjusted = True
			?
		EndIf
		If GetGraphicsManager().SetVSync(config.GetBool("vsync", True))
			TLogger.Log("ApplySettings()", "SetVSync = "+config.GetBool("vsync", False), LOG_DEBUG)
			'until GLSDL works as intended:
			?Not bmxng
			adjusted = True
			?
		EndIf
		If GetGraphicsManager().SetResolution(config.GetInt("screenW", 800), config.GetInt("screenH", 600))
			TLogger.Log("ApplySettings()", "SetResolution = "+config.GetInt("screenW", 800)+"x"+config.GetInt("screenH", 600), LOG_DEBUG)
			'until GLSDL works as intended:
			?Not bmxng
			adjusted = True
			?
		EndIf
		If GetGraphicsManager().GetFullscreen()
			GetGraphicsManager().SetResolution(800, 600)
		EndIf
		If adjusted And doInitGraphics Then GetGraphicsManager().InitGraphics()


		GameConfig.InRoomTimeSlowDownMod = config.GetInt("inroomslowdown", 100) / 100.0
		GameConfig.autoSaveIntervalHours = config.GetInt("autosaveInterval", 0)

		GetDeltatimer().SetRenderRate(config.GetInt("fps", -1))

		adjusted = False



		If config.GetString("sound_engine").ToLower() = "none"
			TSoundManager.audioEngineEnabled = False
			GetSoundManager()
			TSoundManager.audioEngineEnabled = True
			GetSoundManager().MuteMusic(True)
			GetSoundManager().MuteSfx(True)
			TSoundManager.audioEngineEnabled = False
		Else
			GetSoundManager().ApplyConfig(config.GetString("sound_engine", "AUTOMATIC"), ..
			                                  0.01 * config.GetInt("sound_music_volume", 100), ..
			                                  0.01 * config.GetInt("sound_sfx_volume", 100) ..
			                                 )
		EndIf
		GetSoundManager().MuteMusic(config.GetInt("sound_music_volume", 100) = 0)
		GetSoundManager().MuteSfx(config.GetInt("sound_sfx_volume", 100) = 0)

		If Not GetSoundManager().HasMutedMusic()
			'if no music is played yet, try to get one from the "menu"-playlist
			If Not GetSoundManager().isPlaying()
				GetSoundManager().PlayMusicPlaylist("menu")
			EndIf
		EndIf

		MouseManager._minSwipeDistance = config.GetInt("touchClickRadius", 10)
		MouseManager._ignoreFirstClick = config.GetBool("touchInput", False)
		MouseManager._longClickLeadsToRightClick = config.GetBool("rightClickEmulation", True)
		MouseManager.longClickMinTime = config.GetInt("rightClickEmulationTime", 400)

		IngameHelpWindowCollection.showHelp = config.GetBool("showIngameHelp", True)

		If TGame._instance Then GetGame().LoadConfig(config)
	End Method


	Method LoadResources:Int(path:String="config/resources.xml", directLoad:Int=False)
		?debug
		Local deferred:String = ""
		If Not directLoad Then deferred = "(Deferred) "
		TLogger.Log("App.LoadResources()", deferred+"Loading resources from ~q"+path+"~q.", LOG_DEBUG)
		?

		Local registryLoader:TRegistryLoader = New TRegistryLoader
		registryLoader.LoadFromXML(path, directLoad)

		?debug
		TLogger.Log("App.LoadResources()", deferred+"Loading resources from ~q"+path+"~q finished.", LOG_DEBUG)
		?
	End Method



	Method IsPausedBy:Int(origin:Int)
		Return pausedBy & origin
	End Method


	Method SetPausedBy(origin:Int, enable:Int=True)
		If enable
			pausedBy :| origin
		Else
			pausedBy :& ~origin
		EndIf
	End Method


	Method SetLanguage:Int(languageCode:String="de")
		Local oldLang:String = TLocalization.GetCurrentLanguageCode()
		'select language
		TLocalization.SetCurrentLanguage(languageCode)

		'skip further actions if the same language is already set
		If oldLang = languageCode Then Return False

		'store in config - for auto save of user settings
		config.Add("language", languageCode)

		'inform others - so eg. buttons can re-localize
		TriggerBaseEvent(GameEventKeys.App_OnSetLanguage, New TData.Add("languageCode", languageCode), Self)
		Return True
	End Method


	Method Start()
		AppEvents.Init()

		'systemupdate is called from within "update" (lower priority updates)
		EventManager.registerListenerFunction(GameEventKeys.App_OnLowPriorityUpdate, AppEvents.onLowPriorityUpdate )
		'so we could create special fonts and other things
		TriggerBaseEvent(GameEventKeys.App_OnStart)

		'from now on we are no longer interested in loaded elements
		'as we are no longer in the loading screen (-> silent loading)
		If OnLoadMusicListener Then EventManager.unregisterListener( OnLoadMusicListener )

		TLogger.Log("TApp.Start()", "loading time: "+(Time.MillisecsLong() - creationTime) +"ms", LOG_INFO)
	End Method


	Method SaveScreenshot(overlay:TSprite)
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

		Local img:TPixmap = VirtualGrabPixmap(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())

		'add overlay
		If overlay Then overlay.DrawOnImage(img, GetGraphicsManager().GetWidth() - overlay.GetWidth() - 10, 10, -1, Null, TColor.Create(255,255,255,0.5))

		'remove alpha
		SavePixmapPNG(ConvertPixmap(img, PF_RGB888), filename)

		TLogger.Log("App.SaveScreenshot", "Screenshot saved as ~q"+filename+"~q", LOG_INFO)
	End Method


	Global keyLS_DevOSD:TLowerString = New TLowerString.Create("DEV_OSD")
	Function Update:Int()
		TProfiler.Enter(_profilerKey_Update)
		'every 3rd update do a low priority update
		If GetDeltaTimer().timesUpdated Mod 3 = 0
			TriggerBaseEvent(GameEventKeys.App_OnLowPriorityUpdate)
		EndIf

		TProfiler.Enter(_profilerKey_RessourceLoader)
		'check for new resources to load
		RURC.Update()
		TProfiler.Leave(_profilerKey_RessourceLoader)


		MOUSEMANAGER.Update()
		'needs modified "brl.mod/polledinput.mod" (disabling autopoll)
		SetAutoPoll(False)
		KeyManager.Update()
		SetAutoPoll(True)


		'fetch and cache mouse and keyboard states for this cycle
		GUIManager.StartUpdates()


		'enable reading of clicked states (just for the case of being
		'diabled because of an exitDialogue exists)
		MouseManager.Enable(1)
		MouseManager.Enable(2)

		GUIManager.Update(systemState)


		UpdateDebugControls()


		'=== UPDATE INGAME HELP ===
		IngameHelpWindowCollection.Update()


		'=== UPDATE TOASTMESSAGES ===
		GetToastMessageCollection().Update()


		'as long as the exit dialogue is open, do not accept clicks to
		'non gui elements (eg. to leave rooms)
		If App.ExitAppDialogue Or App.EscapeMenuWindow
			'avoid clicks
			'remove right click - to avoid leaving the room
			MouseManager.SetClickHandled(2)
		EndIf

		'ignore shortcuts if a gui object listens to keystrokes
		'eg. the active chat input field
		'also ignore if there is a modal window opened
		'if an element has "
		If (GetGame().gamestate <> TGame.STATE_RUNNING or (GetCurrentPlayer() AND GetCurrentPlayer().isHotKeysEnabled())) AND ..
			Not GUIManager.GetKeyboardInputReceiver() And ..
			Not (App.ExitAppDialogue Or App.EscapeMenuWindow)

			'hotkeys specific for "Dev" or "Not Dev"
			If GameRules.devMode
				__DevHotKeys()
			Else
				__NonDevHotKeys()
				DebugScreen._enabled = 0
				TVTDebugInfo = 0
			EndIf


			'hotkeys which should exist for dev and non-dev
			'Save game only when in a game
			If GetGame().gamestate = TGame.STATE_RUNNING
				If KeyManager.IsHit(KEY_F5) Then TSaveGame.PrepareAutoSave("savegames/quicksave." + GameConfig.GetSavegameExtension())
			EndIf

			If KeyManager.IsHit(KEY_F8)
				'shift + F8 ignores potential compatibility issues
				If KeyManager.IsDown(KEY_LSHIFT)
					TSaveGame.Load("savegames/quicksave." + GameConfig.GetSavegameExtension(), "", False, True)
				Else
					TSaveGame.Load("savegames/quicksave." + GameConfig.GetSavegameExtension(), "", False, False)
				EndIf
			EndIf

			'show ingame manual
			If KeyManager.IsHit(KEY_F1) ' and not KeyManager.IsDown(KEY_RSHIFT)
				IngameHelpWindowCollection.openHelpWindow()
			EndIf
		EndIf


		TError.UpdateErrors()

		ScreenCollection.UpdateCurrent(GetDeltaTimer().GetDelta())

		Local openEscapeMenu:Int = openEscapeMenuViaInterface Or (Not GuiManager.GetKeyboardInputReceiver() And KeyManager.IsHit(KEY_ESCAPE))
		'no escape menu in start screen or settingsscreen
		If GetGame().gamestate = TGame.STATE_MAINMENU Or GetGame().gamestate = TGame.STATE_SETTINGSMENU
			openEscapeMenu = False
		EndIf

		'force open escape menu (if eg. borked)
		If KeyManager.IsDown(KEY_LCONTROL) And KeyManager.IsHit(KEY_ESCAPE)
			openEscapeMenu = True
			Print "force open escape menu. gamestate="+GetGame().gamestate +"   GetKeyboardInputReceiver: " + (GuiManager.GetKeyboardInputReceiver() <> Null)
		EndIf

		If openEscapeMenu
			'print "should open escape menu. gamestate="+GetGame().gamestate

			'ask to exit to main menu
			'TApp.CreateConfirmExitAppDialogue(True)
			If GetGame().gamestate = TGame.STATE_RUNNING
				'RONNY: debug
				If openEscapeMenuViaInterface
					TLogger.Log("Dialogues", "Open Escape-Menu via button hit.", LOG_DEBUG)
				Else
					TLogger.Log("Dialogues", "Open Escape-Menu via ESC key hit.", LOG_DEBUG)
				EndIf

				'TApp.CreateConfirmExitAppDialogue(True)
				'create escape-menu
				TApp.CreateEscapeMenuwindow()
			Else
				TLogger.Log("Dialogues", "Open Escape menu from a gamestate<>STATE_RUNNING!", LOG_DEBUG)
				'ask to exit the app - from main menu?
				'TApp.CreateConfirmExitAppDialogue(False)
			EndIf
			openEscapeMenuViaInterface = False
		EndIf
		'Force-quit with CTRL+Q (ctrl+C is already "copy"
		If KeyManager.IsDown(KEY_LCONTROL) And KeyManager.IsHit(KEY_Q)
			TApp.ExitApp = True
		EndIf

		If AppTerminate()
			If Not TApp.ExitAppDialogue
				'ask to exit the app
				TApp.CreateConfirmExitAppDialogue(False)
			Else
				TLogger.Log("Dialogues", "Skip opening Exit-dialogue, was opened <100ms before.", LOG_DEBUG)
			EndIf
		EndIf

		'check if we need to make a screenshot
		If KeyManager.IsHit(KEY_F12) Then App.prepareScreenshot = 1

		If GetGame().networkGame Then Network.Update()


		'in single player: pause game
		If Not GetGame().networkgame
			If Not GetGame().IsPaused() And App.pausedBy > 0
				GetGame().SetPaused(True)
			EndIf
		EndIf

		If GetGame().IsPaused() And App.pausedBy = 0
			GetGame().SetPaused(False)
		EndIf


		GUIManager.EndUpdates() 'reset modal window states

		If TSaveGame.toSaveNow
			If TSaveGame.Save(TSaveGame.toSaveUri, "", False) Then TSaveGame.toSaveNow = False
		EndIf

		'set the mouse clicks handled anyways
'		MouseManager.ResetClicked(1)
'		MouseManager.ResetClicked(2)
		'remove clicks done a longer time ago
'		MouseManager.RemoveOutdatedClicks(1000)

		TProfiler.Leave(_profilerKey_Update)
	End Function
	
	
	Function __DevHotKeys:Int()
		if collectDebugStats
			If KeyManager.IsHit(KEY_MINUS) And KeyManager.IsDown(KEY_RCONTROL)
				Rem
				Global gcEnabled:Int = True
				If gcEnabled
					 GCSuspend()
					 gcEnabled = False
					 Print "DISABLED GC"
				Else
					 GCResume()
					 gcEnabled = True
					 Print "ENABLED GC"
				EndIf
				endrem

				If printDebugStats
					printDebugStats = False
					Print "DISABLED DEBUG STATS"
				Else
					printDebugStats = True
					Print "ENABLED DEBUG STATS"
				EndIf
			EndIf
		endif

		'in game and not gameover
		If GetGame().gamestate = TGame.STATE_RUNNING And Not GetGame().IsGameOver()
			If not TGUIListBase(GUIManager.GetFocus()) or not TGUIListBase(GUIManager.GetFocus()).IsHandlingKeyBoardScrolling() 
				'If KeyManager.IsDown(KEY_UP) Then 
				'If KeyManager.IsDown(KEY_DOWN) Then 
			EndIf

			If KeyManager.IsDown(KEY_RIGHT)
				If Not KeyManager.IsDown(KEY_LCONTROL) And Not KeyManager.Isdown(KEY_RCONTROL)
					GetGame().SetGameSpeed( Int(GetWorldTime().GetTimeFactor()) + 5 )
				Else
					__SwitchFastForward(True)
				EndIf
			EndIf


			If KeyManager.IsDown(KEY_LEFT)
				If Not KeyManager.IsDown(KEY_LCONTROL) And Not KeyManager.Isdown(KEY_RCONTROL)
					GetGame().SetGameSpeed( Max(Int(GetWorldTime().GetTimeFactor()) - 5, 0) )
				Else
					DEV_FastForward_TargetReached = True
					__SwitchFastForward(False)
				EndIf
			EndIf


			If KeyManager.IsHit(KEY_Y)
				'your own dev-debug-code
			EndIf


			If KeyManager.isDown(KEY_LCONTROL)
				If KeyManager.IsHit(KEY_O) And Not GameConfig.highSpeedObservation
					GameConfig.observerMode = 1 - GameConfig.observerMode

					KeyManager.ResetKey(KEY_O)
					KeyManager.BlockKey(KEY_O, 150)
				EndIf
			EndIf

			If KeyManager.IsHit(KEY_H)
				If GameConfig.highSpeedObservation
					GameConfig.observerMode = False
					TVTGhostBuildingScrollMode = False
					GameConfig.highSpeedObservation = False
					GetWorld().disableEffectRendering = False
					GetSoundManager().MuteMusic(App.config.GetInt("sound_music_volume", 100) = 0)
					GetSoundManager().MuteSfx(App.config.GetInt("sound_sfx_volume", 100) = 0)
				Else
					GameConfig.observerMode = True
					TVTGhostBuildingScrollMode = True
					GameConfig.SetObservedObject( MainMenuJanitor )
					GameConfig.highSpeedObservation = True
					TInGameInterface.GetInstance().showChannel=0
					GetWorld().disableEffectRendering = True
					GetSoundManager().MuteMusic(True)
					GetSoundManager().MuteSfx(True)
				EndIf
			EndIf


			If KeyManager.IsHit(KEY_U)
				Local currentIndex:Int = 0
				For Local lang:TLocalizationLanguage = EachIn TLocalization.languages
					If lang = TLocalization.currentLanguage Then exit
					currentIndex:+ 1
				Next
				App.SetLanguage(TLocalization.languages[(currentIndex+1) Mod (TLocalization.languages.length)].languageCode)
			EndIf


			If Not GetPlayer().GetFigure().isChangingRoom()
				If GameConfig.highSpeedObservation
					If KeyManager.IsHit(KEY_1) Then GetGame().SetActivePlayer(1)
					If KeyManager.IsHit(KEY_2) Then GetGame().SetActivePlayer(2)
					If KeyManager.IsHit(KEY_3) Then GetGame().SetActivePlayer(3)
					If KeyManager.IsHit(KEY_4) Then GetGame().SetActivePlayer(4)
				ElseIf GameConfig.observerMode
					If KeyManager.IsHit(KEY_1) Then GameConfig.SetObservedObject( GetPlayer(1).GetFigure() )
					If KeyManager.IsHit(KEY_2) Then GameConfig.SetObservedObject( GetPlayer(2).GetFigure() )
					If KeyManager.IsHit(KEY_3) Then GameConfig.SetObservedObject( GetPlayer(3).GetFigure() )
					If KeyManager.IsHit(KEY_4) Then GameConfig.SetObservedObject( GetPlayer(4).GetFigure() )
				Else
					If KeyManager.IsHit(KEY_1) Then GetGame().SetActivePlayer(1); TInGameInterface.GetInstance().showChannel=1
					If KeyManager.IsHit(KEY_2) Then GetGame().SetActivePlayer(2); TInGameInterface.GetInstance().showChannel=2
					If KeyManager.IsHit(KEY_3) Then GetGame().SetActivePlayer(3); TInGameInterface.GetInstance().showChannel=3
					If KeyManager.IsHit(KEY_4) Then GetGame().SetActivePlayer(4); TInGameInterface.GetInstance().showChannel=4
				EndIf


				'Navigation
				Local room:String
				If KeyManager.IsHit(KEY_W)
					If Not KeyManager.IsDown(KEY_LSHIFT) And Not KeyManager.IsDown(KEY_RSHIFT)
						room = "adagency"
					EndIf
				EndIf
				If KeyManager.IsHit(KEY_A) Then room = "archive"
				If KeyManager.IsHit(KEY_B) Then room = "betty"
				If KeyManager.IsHit(KEY_F)
					If Not KeyManager.IsDown(KEY_LSHIFT) And Not KeyManager.IsDown(KEY_RSHIFT)
						room = "movieagency"
					EndIf
				EndIf
				If KeyManager.IsHit(KEY_O) Then room = "office"
				If not (KeyManager.IsDown(KEY_LCONTROL) Or KeyManager.IsDown(KEY_RCONTROL))
					If KeyManager.IsHit(KEY_C) Then room = "boss"
				EndIf
				If KeyManager.isHit(KEY_G) Then TVTGhostBuildingScrollMode = 1 - TVTGhostBuildingScrollMode
Rem
				If KeyManager.isHit(KEY_X)
					print "Player: #" + GetPlayer().GetFigure().playerID + "   time: " + GetWorldTime().GetFormattedTime()
					print "IsControllable: " + GetPlayer().GetFigure().IsControllable()
					print "IsIdling: " + GetPlayer().GetFigure().IsIdling()
					print "IsChangingRoom: " + GetPlayer().GetFigure().IsChangingRoom()
					print "IsAtElevator: " + GetPlayer().GetFigure().IsAtElevator()
					print "IsInElevator: " + GetPlayer().GetFigure().IsInElevator()
					print "IsInBuilding: " + GetPlayer().GetFigure().IsInBuilding()
					print "currentReachStep: " + GetPlayer().GetFigure().currentReachTargetStep
					print "-----------------"
				EndIf
endrem
				If KeyManager.isHit(KEY_S)
					If KeyManager.IsDown(KEY_LCONTROL)
						room = "supermarket"
					ElseIf KeyManager.IsDown(KEY_RCONTROL) Or KeyManager.IsDown(KEY_LALT)
						room = "scriptagency"
					Else
						room = "studio"
					EndIf
				EndIf
				If KeyManager.IsHit(KEY_D) Then room = "scriptagency" 'German "Drehbuchagentur"
				If KeyManager.IsHit(KEY_L) Then room = "supermarket"

				'e wie "employees" :D
				If KeyManager.IsHit(KEY_E) Then room = "credits"
				If KeyManager.IsHit(KEY_N) Then room = "news"
				If KeyManager.IsHit(KEY_R)
					If KeyManager.IsDown(KEY_LCONTROL) Or KeyManager.IsDown(KEY_RCONTROL)
						room = "roomboard"
					Else
						room = "roomagency"
					EndIf
				EndIf
				If KeyManager.IsHit(KEY_P) Then room = "roomboard"
				If room Then __GoToRoom(room)
			EndIf
		EndIf
		If KeyManager.IsHit(KEY_5) Then GetGame().SetGameSpeed( 30 * 60 ) '30 game minutes per realtime second
		If KeyManager.IsHit(KEY_6) Then GetGame().SetGameSpeed( 60 * 60 ) '60 game minutes per realtime second
		If KeyManager.IsHit(KEY_7) And Not (KeyManager.IsDown(KEY_LSHIFT) OR KeyManager.IsDown(KEY_RSHIFT)) Then GetGame().SetGameSpeed( 120 * 60 )
		If KeyManager.IsHit(KEY_8) Then GetGame().SetGameSpeed( 240 * 60 )
		If KeyManager.IsHit(KEY_9) Then GetGame().SetGameSpeedPreset( 1 )
		If KeyManager.IsHit(KEY_0) Then GetGame().SetGameSpeed( 0 ) 'pause
		If KeyManager.IsHit(KEY_Q) Then debugAudienceInfo.Toggle()

		If KeyManager.IsHit(KEY_TAB)
			If Not KeyManager.IsDown(KEY_LCONTROL)
				DebugScreen._enabled = 1 - DebugScreen._enabled
			Else
				TVTDebugInfo = 1 - TVTDebugInfo
			EndIf
		EndIf

		If KeyManager.IsHit(KEY_K)
			TLogger.Log("KickAllFromRooms", "Player kicks all figures out of the rooms.", LOG_DEBUG)
			For Local fig:TFigure = EachIn GetFigureCollection() '.GetEntriesID().Values()
				If fig.GetInRoom()
					fig.KickOutOfRoom()
					'fig.KickOutOfRoom(GetPlayer().GetFigure())
				Else
					Print "fig: "+fig.name+" not in room."
				EndIf
			Next
		EndIf


		If KeyManager.Ishit(Key_F6) Then GetSoundManager().PlayMusicPlaylist("default")

		If KeyManager.Ishit(Key_F11)
			If (TAiBase.AiRunning)
				TLogger.Log("CORE", "AI deactivated", LOG_INFO | LOG_DEV )
				TAiBase.AiRunning = False
			Else
				TLogger.Log("CORE", "AI activated", LOG_INFO | LOG_DEV )
				TAiBase.AiRunning = True
			EndIf
		EndIf
		If KeyManager.Ishit(Key_F10)
			If (TAiBase.AiRunning)
				For Local fig:TFigure = EachIn GetFigureCollection() '.GetEntriesID().Values()
					If GetPlayerBase().GetFigure() <> fig Then fig.moveable = False
				Next
				TLogger.Log("CORE", "AI Figures deactivated", LOG_INFO | LOG_DEV )
				TAiBase.AiRunning = False
			Else
				For Local fig:TFigure = EachIn GetFigureCollection() '.GetEntriesID().Values()
					If GetPlayerBase().GetFigure() <> fig Then fig.moveable = True
				Next
				TLogger.Log("CORE", "AI activated", LOG_INFO | LOG_DEV )
				TAiBase.AiRunning = True
			EndIf
		EndIf
	End Function


	Function __NonDevHotKeys:Int()
		'Navigation
		Local room:String
		If KeyManager.IsHit(KEY_A) Then room="archive"
		If KeyManager.IsHit(KEY_B) Then room="betty"
		If KeyManager.IsHit(KEY_C) Then room="boss" 'Chef
		If KeyManager.IsHit(KEY_D) Then room="scriptagency" 'Drehbuch
		If KeyManager.IsHit(KEY_F) Then room="movieagency" 'Film
		If KeyManager.IsHit(KEY_L) Then room="supermarket" 'Laden
		If KeyManager.IsHit(KEY_N) Then room="news"
		If KeyManager.IsHit(KEY_O) Then room="office"
		If KeyManager.IsHit(KEY_P) Then room="roomboard" 'Panel
		If KeyManager.IsHit(KEY_R) Then room="roomagency"
		If KeyManager.IsHit(KEY_S) Then room="studio"
		If KeyManager.IsHit(KEY_W) Then room="adagency" 'Werbung
		If room Then __GoToRoom(room)

		'Simuliere Rechtsklick (Verlassen eines Screens/Raums, Abbruch einer Aktion, Löschen etc.)
		'If KeyManager.IsHit(KEY_Q) Then MOUSEMANAGER._AddClickEntry(2, 1, New TVec2D(0, 0), 5)
		If KeyManager.IsHit(KEY_Q)
			Local figure:TFigure = GetPlayer().GetFigure()
			If Not figure.IsInRoom() Or Not figure.LeaveRoom() Then figure.KickOutOfRoom()
		EndIf

		'Schnellvorlauf
		If KeyManager.IsDown(KEY_RIGHT)
			__SwitchFastForward(True)
		Else
			__SwitchFastForward(False)
		EndIf

		'Geschwindigkeitslevel
		If KeyManager.IsHit(KEY_1) Then GetGame().SetGameSpeedPreset(0)
		If KeyManager.IsHit(KEY_2) Then GetGame().SetGameSpeedPreset(1)
		If KeyManager.IsHit(KEY_3) Then GetGame().SetGameSpeedPreset(2)

		'Hilfe
		If KeyManager.IsHit(KEY_F1)
			IngameHelpWindowCollection.openHelpWindow()
		EndIf
	End Function


	Function __GotoRoom(room:String)
		Local targetRoom:TRoom
		If room = "studio"
			Local rooms:TRoomBase[] = GetRoomCollection().GetAllByDetails(room, "", GetPlayerCollection().playerID)
	 		If rooms and rooms.length > 0 
				For Local r:TRoomBase = EachIn rooms
					If not r.isBlocked()
						targetRoom = TRoom(r)
						exit
					EndIf
				Next
			EndIf
		EndIf
		If room
			If Not targetRoom Then targetRoom = GetRoomCollection().GetFirstByDetails("", room, GetPlayerCollection().playerID)
			If Not targetRoom Then targetRoom = GetRoomCollection().GetFirstByDetails("", room)
			If Not targetRoom Then targetRoom = GetRoomCollection().GetFirstByDetails(room, "")
			If targetRoom
				Local targetDoor:TRoomDoorBase = GetRoomDoorCollection().GetMainDoorToRoom(targetRoom.id)
				If targetDoor
					'obsolete - no beaming to target
					'If GameRules.devConfig.GetBool(keyLS_DevKeys, False)
						'DEV_switchRoom(targetRoom)
					'EndIf
					If Not GetPlayer().GetFigure().IsInRoom(room)
						DEV_FastForward_TargetReached = False
						__SwitchFastForward(True)
						GetPlayer().GetFigure().SendToDoor(targetDoor)
					EndIf
				EndIf
			EndIf
		EndIf
	End Function


	Function __SwitchFastForward(ff:Int = 0)
		'stop fast forward
		If DEV_FastForward And Not ff And DEV_FastForward_TargetReached
			DEV_FastForward = False
			GameConfig.InRoomTimeSlowDownMod = GameConfig.InRoomTimeSlowDownModBackup
			TEntity.globalWorldSpeedFactor = DEV_FastForward_SpeedFactorBackup
			GetWorldTime()._timeFactor = DEV_FastForward_TimeFactorBackup
			GetBuildingTime()._timeFactor = DEV_FastForward_BuildingTimeSpeedFactorBackup
		EndIf

		If ff And Not DEV_FastForward
			DEV_FastForward = True
			DEV_FastForward_SpeedFactorBackup = TEntity.globalWorldSpeedFactor
			DEV_FastForward_TimeFactorBackup = GetWorldTime()._timeFactor
			DEV_FastForward_BuildingTimeSpeedFactorBackup = GetBuildingTime()._timeFactor

			GameConfig.InRoomTimeSlowDownModBackup = GameConfig.InRoomTimeSlowDownMod
			GameConfig.InRoomTimeSlowDownMod = 1.0
			GetGame().SetGameSpeed( 30 * 60 )
		EndIf
	EndFunction


	Function RenderDevOSD()
		Local bf:TBitmapFont = GetBitmapFontManager().baseFont
		Local textX:Int = 5
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()
		SetAlpha oldA * 0.25
		SetColor 0,0,0
		If GameRules.devConfig.GetBool(keyLS_DevOSD, False)
			DrawRect(0,0, 800, bf.GetMaxCharHeight(true))
		Else
			DrawRect(0,0, 175 + 10, bf.GetMaxCharHeight(true))
		EndIf
		SetColor(oldCol)
		SetAlpha(oldA)

		textX:+ Max(75, bf.DrawSimple("Speed:" + Int(GetWorldTime().GetTimeFactor()), textX , 0).x)
		textX:+ Max(50, bf.DrawSimple("FPS: "+GetDeltaTimer().currentFps, textX, 0).x)
		textX:+ Max(50, bf.DrawSimple("UPS: " + Int(GetDeltaTimer().currentUps), textX,0).x)

rem
		local soloudDriver:TSoloudAudioDriver = TSoloudAudioDriver(GetAudioDriver())
		if soloudDriver
			bf.DrawSimple("SOL: " + soloudDriver._soloud.getActiveVoiceCount() + "/" + soloudDriver._soloud.getMaxActiveVoiceCount() + "/" + soloudDriver._soloud.getVoiceCount() +" voices", textX,0)
			textX:+75
		Else
			bf.DrawSimple("SOL: " + TTypeID.ForObject(GetAudioDriver()).name(), textX,0)
			textX:+75
		endif
endrem
		If GameRules.devConfig.GetBool(keyLS_DevOSD, False)
			textX:+ Max(85, bf.DrawSimple("Loop: "+Int(GetDeltaTimer().getLoopTimeAverage())+"ms", textX,0).x)
			'update time per second
			textX:+ Max(65, bf.DrawSimple("UTPS: " + Int(GetDeltaTimer()._currentUpdateTimePerSecond), textX,0).x)
			'render time per second
			textX:+ Max(65, bf.DrawSimple("RTPS: " + Int(GetDeltaTimer()._currentRenderTimePerSecond), textX,0).x)

			'RON: debug purpose - see if the managed guielements list increase over time
			If GUIManager.GetFocus()
				textX:+ Max(170, bf.DrawSimple("GUI objects: "+ GUIManager.list.count()+" [d:"+GUIManager.GetDraggedCount()+", focusID: "+GUIManager.GetFocus()._id + " ("+TTypeID.ForObject(GUIManager.GetFocus()).name()+")", textX,0).x)
			Else
				textX:+ Max(170, bf.DrawSimple("GUI objects: "+ GUIManager.list.count()+" [d:"+GUIManager.GetDraggedCount()+"]" , textX,0).x)
			EndIf

			If GetGame().networkgame And Network.client
				textX:+ Max(50, bf.DrawSimple("Ping: "+Int(Network.client.latency)+"ms", textX,0).x)
			EndIf
		EndIf
	End Function



	Function UpdateDebugControls()
		GameConfig.mouseHandlingDisabled = False

		If GetGame().gamestate <> TGame.STATE_RUNNING Then Return

		'update regardless of enabled or not
		DebugScreen.UpdateSystem()


		'handle (temporary) fast forward here - saving game not available in screen
		Local fastForwardScreen:TDebugScreenPage_Misc = TDebugScreenPage_Misc.GetInstance()
		If fastForwardScreen.FastForward_Active and fastForwardScreen.FastForward_TargetTime < GetWorldTime().GetTimeGone()
			fastForwardScreen.Dev_StopFastForwardToTime()
		EndIf
		'continuous fast forward: save game and go to the end of the next day
		If fastForwardScreen.FastForward_Continuous_Active and fastForwardScreen.FastForward_TargetTime < GetWorldTime().GetTimeGone()
			Local daysRun:Int = GetWorldTime().GetDaysRun() + 1
			If daysRun mod 5 = 0
				Local savegameName:String = "savegames/AI-day-" + StringHelper.RSetChar(daysRun,3,"0")
				Local savegameURI:String = savegameName + "." + GameConfig.GetSavegameExtension()
				TSaveGame.PrepareAutoSave(savegameURI)
			EndIf
			fastForwardScreen.FastForward_TargetTime = GetWorldTime().CalcTime_DaysFromNowAtHour(-1,1,1,23,23) + 56*TWorldTime.MINUTELENGTH
		EndIf


		If DebugScreen._enabled
			GameConfig.mouseHandlingDisabled = True
			DebugScreen.Update()
		EndIf
	End Function


	Function RenderDebugControls()
		If GetGame().gamestate <> TGame.STATE_RUNNING Then Return


		If DebugScreen._enabled Then DebugScreen.Render()


		If TVTDebugInfo And Not GetPlayer().GetFigure().inRoom
		'show quotes even without "DEV_OSD = true"

		ElseIf debugAudienceInfo.mode > 0
			debugAudienceInfo.Draw()
		EndIf
	End Function


	Function Render:Int()
		'cls only needed if virtual resolution is enabled, else the
		'background covers everything
		If GetGraphicsManager().HasBlackBars()
			SetClsColor 0,0,0
			'use graphicsmanager's cls as it resets virtual resolution
			'first
			GetGraphicsManager().Cls()
		EndIf

		TProfiler.Enter(_profilerKey_Draw)

		'set game cursor to 0/default
		GetGameBase().SetCursor(TGameBase.CURSOR_DEFAULT)
		GetGameBase().SetCursorAlpha(1.0)

		ScreenCollection.DrawCurrent(GetDeltaTimer().GetTween())


		'=== RENDER TOASTMESSAGES ===
		'below everything else of the interface: our toastmessages
		GetToastMessageCollection().Render(0,0)


		'=== RENDER INGAME HELP ===
		IngameHelpWindowCollection.Render()


		RenderDevOSD()

		?bmxng
		If OCM.enabled
			'Display elements currently managed by the GC.
			'Also display changes since last "dump" (a second earlier)
			'This does NOT show temporarily created elements
			SetColor 0,0,0
			DrawRect(5,430, 230, 200)
			SetColor 190,190,190
			
			Local linePos:Int = 432
			GetBitmapFontManager().baseFont.Draw("Managed Obj. (Mem-Leaks detection):", 10 , linePos)
			linePos :+ 12

			'OK: "TRoom", "TRoomDoor"
			For Local s:String = EachIn ["Array", "String", "TLink", "TVec3D", "TVec2D", "TAudience", "TAudienceBase"]
				Local e:TObjectCountDumpEntry = OCM.GetEntry(s)
				GetBitmapFontManager().baseFont.Draw(s+": ", 10 , linePos)
				if not e
					GetBitmapFontManager().baseFont.Draw("0", 110 , linePos)
				Else
					GetBitmapFontManager().baseFont.Draw(e.total, 110 , linePos)
					If e.change > 0
						GetBitmapFontManager().baseFont.Draw("+" + e.change, 150 , linePos)
					ElseIf e.change < 0
						GetBitmapFontManager().baseFont.Draw(e.change, 150 , linePos)
					EndIf
				EndIf
				linePos :+ 12
			Next
			linePos :+ 12
			GetBitmapFontManager().baseFont.Draw("Top Changes:", 10 , linePos)
			linePos :+ 12

			Local dump:TObjectCountDump = OCM.GetLastDump()
			If dump
				For Local e:TObjectCountDumpEntry = EachIn dump.GetMostChanged(3)
					GetBitmapFontManager().baseFont.Draw(OCM.GetKey(e.keyID), 10 , linePos)
					If e.change > 0
						GetBitmapFontManager().baseFont.Draw("+" + e.change, 150 , linePos)
					ElseIf e.change < 0
						GetBitmapFontManager().baseFont.Draw(e.change, 150 , linePos)
					EndIf
					linePos :+ 12
				Next
			EndIf
			
			SetColor 255,255,255
		EndIf
		?

		If GetGame().gamestate = TGame.STATE_RUNNING
			If Not TAiBase.AiRunning
				Local oldCol:SColor8; GetColor(oldCol)
				Local oldA:Float = GetAlpha()
				SetColor 100,40,40
				SetAlpha 0.65 * oldA
				DrawRect(275,0,250,35)
				SetColor(oldCol)
				SetAlpha(oldA)
				GetBitmapFont("default", 16).DrawBox("PLAYER AI DEACTIVATED", 0, 5, GetGraphicsManager().GetWidth(), 355, sALIGN_CENTER_TOP, SColor8.White, EDrawTextEffect.Shadow, -1)
				GetBitmapFont("default", 12).DrawBox("(~qF11~q to reactivate AI)", 0, 20, GetGraphicsManager().GetWidth(), 355, sALIGN_CENTER_TOP, SColor8.White, EDrawTextEffect.Shadow, -1)
			EndIf

			If GameConfig.highSpeedObservation
				GetBitmapFont("default", 20).DrawBox("HIGHSPEED OBSERVATION; active player #"+GetPlayerCollection().playerID, 0, 0, GetGraphicsManager().GetWidth(), 355, sALIGN_CENTER_BOTTOM, SColor8.White, EDrawTextEffect.Shadow, -1)
				GetBitmapFont("default", 14).DrawBox("(~qH~q to deactivate)", 0, 0, GetGraphicsManager().GetWidth(), 375, sALIGN_CENTER_BOTTOM, SColor8.White, EDrawTextEffect.Shadow, -1)
			ElseIf GameConfig.observerMode
				Local playerNum:Int = 0
				For Local i:Int = 1 To 4
					If GameConfig.IsObserved( GetPlayer(i).GetFigure() )
						playerNum = i
						Exit
					EndIf
				Next
				GetBitmapFont("default", 20).DrawBox("OBSERVING PLAYER #"+playerNum, 0, 0, GetGraphicsManager().GetWidth(), 355, sALIGN_CENTER_BOTTOM, SColor8.White, EDrawTextEffect.Shadow, -1)
				GetBitmapFont("default", 14).DrawBox("(~qL-Ctrl + O~q to deactivate)", 0, 0, GetGraphicsManager().GetWidth(), 375, sALIGN_CENTER_BOTTOM, SColor8.White, EDrawTextEffect.Shadow, -1)
			Else
				If Not GetPlayerCollection().IsHuman( GetPlayerCollection().playerID )
					Local oldCol:SColor8; GetColor(oldCol)
					Local oldA:Float = GetAlpha()
					SetColor 60,60,40
					SetAlpha 0.65 * oldA
					DrawRect(275,345,250,35)
					SetColor(oldCol)
					SetAlpha(oldA)


					GetBitmapFont("default", 16).DrawBox("SWITCHED TO AI PLAYER #" +GetPlayerCollection().playerID, 0, 0, GetGraphicsManager().GetWidth(), 365, sALIGN_CENTER_BOTTOM, SColor8.White, EDrawTextEffect.Shadow, -1)

					Local localHumanNum:Int = 0
					For Local i:Int = 1 To 4
						If GetPlayer(i).playerType = TPlayerBase.PLAYERTYPE_LOCAL_HUMAN
							localHumanNum = i
							Exit
						EndIf
					Next

					If localHumanNum > 0
						GetBitmapFont("default", 12).DrawBox("(~q"+localHumanNum+"~q to switch back)", 0, 0, GetGraphicsManager().GetWidth(), 380, sALIGN_CENTER_BOTTOM, SColor8.White, EDrawTextEffect.Shadow, -1)
					Else
						GetBitmapFont("default", 12).DrawBox("(all players are AI controlled)", 0, 0, GetGraphicsManager().GetWidth(), 380, sALIGN_CENTER_BOTTOM, SColor8.White, EDrawTextEffect.Shadow, -1)
					EndIf
				EndIf
			EndIf
		EndIf

		'render debug views and control buttons
		If GameRules.devMode Then RenderDebugControls()

		'draw loading resource information
		RenderLoadingResourcesInformation()


		'draw system things at last (-> on top)
		GUIManager.Draw(systemState)


		'mnouse cursor
'		If Not spriteMouseCursor Then spriteMouseCursor = GetSpriteFromRegistry("gfx_mousecursor")
		local cursorOffsetX:Int
		local cursorOffsetY:Int
		local cursorSprite:TSprite
		
		Select GetGameBase().GetCursor()
			'drag indicator
			Case TGameBase.CURSOR_PICK
				cursorSprite = GetSpriteFromRegistry("gfx_mousecursor_pick")
			Case TGameBase.CURSOR_PICK_VERTICAL
				cursorSprite = GetSpriteFromRegistry("gfx_mousecursor_pick_vertical")
			Case TGameBase.CURSOR_PICK_HORIZONTAL
				cursorSprite = GetSpriteFromRegistry("gfx_mousecursor_pick_horizontal")
			'dragged indicator
			Case TGameBase.CURSOR_HOLD
				cursorSprite = GetSpriteFromRegistry("gfx_mousecursor_hold")
			'drag / interaction blocked
			Case TGameBase.CURSOR_STOP
				cursorSprite = GetSpriteFromRegistry("gfx_mousecursor_stop")
			'interaction indicator
			Case TGameBase.CURSOR_INTERACT
				local frame:Int = int((Millisecs() * 0.005) mod 10)
				if frame < 7
					cursorSprite = GetSpriteFromRegistry("gfx_mousecursor_interact0")
				else
					cursorSprite = GetSpriteFromRegistry("gfx_mousecursor_interact" + (frame-7))
				endif

			'normal and default
			Default
				cursorSprite = GetSpriteFromRegistry("gfx_mousecursor_point")
		End Select

		if cursorSprite
			cursorOffsetX = cursorSprite.offset.GetLeft()
			cursorOffsetY = cursorSprite.offset.GetTop()
			Local oldA:Float = GetAlpha()
			SetAlpha(oldA * GetGameBase().GetCursorAlpha())
			cursorSprite.Draw(MouseManager.x, MouseManager.y)
			SetAlpha(oldA)
		endif

		Select GetGameBase().GetCursorExtra()
			Case TGameBase.CURSOR_EXTRA_FORBIDDEN
				local oldA:Float = GetAlpha()
				SetAlpha oldA * 0.65 + Float(Min(0.15, Max(-0.20, Sin(MilliSecs() / 6) * 0.20)))
				GetSpriteFromRegistry("gfx_mousecursor_extra_forbidden").Draw(MouseManager.x - cursorOffsetX, MouseManager.y - cursorOffsetY)
				SetAlpha oldA
		End Select

'		DrawOval(MouseManager.x-2, MouseManager.y-2, 4,4)


		'if a screenshot is generated, draw a logo in
		If App.prepareScreenshot = 1
			App.SaveScreenshot(GetSpriteFromRegistry("gfx_startscreen_logoSmall"))
			App.prepareScreenshot = False
		EndIf

	'	debugProfiler.Draw(10, 20)

		GetGraphicsManager().Flip(GetDeltaTimer().HasLimitedFPS())

		TProfiler.Leave(_profilerKey_Draw)
		Return True
	End Function


	Function RenderLoadingResourcesInformation:Int()
		'do nothing if there is nothing to load
		If RURC.FinishedLoading() Then Return True

		SetAlpha 0.2
		SetColor 50,0,0
		DrawRect(0, GetGraphicsManager().GetHeight() - 20, GetGraphicsManager().GetWidth(), 20)
		SetAlpha 1.0
		SetColor 255,255,255
		DrawText("Loading: "+RURC.loadedCount+"/"+RURC.toLoadCount+"  "+String(RURC.loadedLog.Last()), 0, 580)
	End Function


	Function onCloseEscapeMenu:Int(triggerEvent:TEventBase)
		Local window:TGUIModalWindowChain = TGUIModalWindowChain(triggerEvent.GetSender())
		If Not window Then Return False

		'store closing time of this modal window (does not matter which
		'one) to skip creating another menu window  within a certain
		'timeframe
		EscapeMenuWindowTime = Time.MilliSecsLong()

		'not interested in other windows
		If window <> EscapeMenuWindow Then Return False

		'remove connection to global value (guimanager takes care of fading)
		TApp.EscapeMenuWindow = Null

		'RONNY: debug
		TLogger.Log("Dialogues", "Closing Escape-Menu, continuing game.", LOG_DEBUG)

		App.SetPausedBy(PAUSED_BY_ESCAPEMENU, False)

		Return True
	End Function



	Function CreateEscapeMenuwindow:Int()
		'100ms since last window
		If Time.MillisecsLong() - EscapeMenuWindowTime < 100 Then Return False

		'remove gui objects in a broken "dragged" state (removal missed
		'somehow)
		For Local obj:TGUIObject = EachIn GuiManager.ListDragged.Copy()
			obj.Remove()
			Print "Removed forgotten dragged element " + obj.GetClassName()
		Next

		EscapeMenuWindowTime = Time.MilliSecsLong()

		App.SetPausedBy(TApp.PAUSED_BY_ESCAPEMENU)

		TGUISavegameListItem.SetTypeFont(GetBitmapFont(""))

		EscapeMenuWindow = New TGUIModalWindowChain.Create(New SVec2I(0,0), New SVec2I(400,130), "SYSTEM")
		EscapeMenuWindow.SetZIndex(99000)
		EscapeMenuWindow.SetCenterLimit(New TRectangle.setTLBR(20,0,0,0))

		'append menu after creation of screen area, so it recenters properly
		'355 = with speed buttons
		'local mainMenu:TGUIModalMainMenu = New TGUIModalMainMenu.Create(New SVec2I(0,0), New SVec2I(300,355), "SYSTEM")
		Local mainMenu:TGUIModalMainMenu = New TGUIModalMainMenu.Create(New SVec2I(0,0), New SVec2I(300,315), "SYSTEM")
		mainMenu.SetCaption(GetLocale("MENU"))

		EscapeMenuWindow.SetContentElement(mainMenu)

		'menu is always ingame...
		EscapeMenuWindow.SetDarkenedArea( GameConfig.nonInterfaceRect.Copy() )
		'center to this area
		EscapeMenuWindow.SetScreenArea( GameConfig.nonInterfaceRect.Copy() )

		EscapeMenuWindow.Open() 'to play sound
	End Function


	Function onCloseModalDialogue:Int(triggerEvent:TEventBase)
'		If App.settingsWindow and dialogue = App.settingsWindow.modalDialogue
		If App.settingsWindow And App.settingsWindow.modalDialogue = triggerEvent.GetSender()
			Return onCloseSettingsWindow(triggerEvent)
		ElseIf ExitAppDialogue = triggerEvent.GetSender()
			Return onAppConfirmExit(triggerEvent)
		EndIf
	End Function


	Function onCloseSettingsWindow:Int(triggerEvent:TEventBase)
		If Not App.settingsWindow Then Return False

		'"apply" button was used...save the whole thing
		If triggerEvent.GetData().GetInt("closeButton", -1) = 0
			App.ApplySettingsWindow()
		EndIf

		'unset variable - allows escape/quit-window again
		'App.settingsWindow.modaldialogue.Remove()
		'App.settingsWindow = Null
	End Function


	Function onAppConfirmExit:Int(triggerEvent:TEventBase)
Rem
'already checked in onCloseModalDialogue()
		Local dialogue:TGUIModalWindow = TGUIModalWindow(triggerEvent.GetSender())
		If Not dialogue Then Return False

		'not interested in other dialogues
		If dialogue <> ExitAppDialogue Then Return False
endrem

		'store closing time of this modal window (does not matter which
		'one) to skip creating another exit dialogue within a certain
		'timeframe
		ExitAppDialogueTime = Time.MilliSecsLong()


		Local buttonNumber:Int = triggerEvent.GetData().getInt("closeButton",-1)


		'approve exit
		If buttonNumber = 0
			Local quitToMainMenu:Int = ExitAppDialogue.data.GetInt("quitToMainMenu", True)
			'if within a game - just return to mainmenu
			If GetGame().gamestate = TGame.STATE_RUNNING And quitToMainMenu
				'adjust darkened Area to fullscreen!
				'but do not set new screenArea to avoid "jumping"
				ExitAppDialogue.darkenedArea = New TRectangle.Init(0,0,800,600)
				'ExitAppDialogue.screenArea = New TRectangle.Init(0,0,800,600)

				GetGame().EndGame()
			Else
				TApp.ExitApp = True
			EndIf
		EndIf
		'remove connection to global value (guimanager takes care of fading)
		TApp.ExitAppDialogue = Null

		App.SetPausedBy(TApp.PAUSED_BY_EXITDIALOGUE, False)

		Return True
	End Function


	Function CreateConfirmExitAppDialogue:Int(quitToMainMenu:Int=True)
		'100ms since last dialogue
		If Time.MilliSecsLong() - ExitAppDialogueTime < 100
			TLogger.Log("Dialogues", "Skip opening Exit-dialogue, was opened <100ms before.", LOG_DEBUG)
			Return False
		EndIf

		TLogger.Log("Dialogues", "User hit [x], create Exit-dialogue.", LOG_DEBUG)


		ExitAppDialogueTime = Time.MilliSecsLong()

		App.SetPausedBy(TApp.PAUSED_BY_EXITDIALOGUE)

		ExitAppDialogue = New TGUIGameModalWindow.Create(New SVec2I(0,0), New SVec2I(400,150), "SYSTEM")
		ExitAppDialogue.SetDialogueType(2)
		ExitAppDialogue.SetZIndex(100000)
		ExitAppDialogue.data.AddNumber("quitToMainMenu", quitToMainMenu)
	'	ExitAppDialogue.Open()

		'limit to "screen" area
		If GetGame().gamestate = TGame.STATE_RUNNING
			ExitAppDialogue.darkenedArea = New TRectangle.Init(0,0,800,385)
			'center to this area
			ExitAppDialogue.screenArea = New TRectangle.Init(0,0,800,385)
		EndIf

		If GetGame().gamestate = TGame.STATE_RUNNING And quitToMainMenu
			ExitAppDialogue.SetCaptionAndValue( GetLocale("ALREADY_OVER"), GetLocale("DO_YOU_REALLY_WANT_TO_QUIT_THE_GAME_AND_RETURN_TO_STARTSCREEN") )
		Else
			ExitAppDialogue.SetCaptionAndValue( GetLocale("ALREADY_OVER"), GetLocale("DO_YOU_REALLY_WANT_TO_QUIT") )
		EndIf
	End Function

End Type


'just an object holding all data which has to get saved
'it is kind of an "DataCollectionCollection" ;D
Type TGameState
	Field _gameSummary:TData = Null
	Field _Game:TGame = Null
	Field _BuildingTime:TBuildingTime = Null
	Field _WorldTime:TWorldTime = Null
	Field _WorldWeather:TWorldWeather = Null
	Field _GameRules:TGamerules = Null
	Field _GameConfig:TGameConfig = Null
	Field _Betty:TBetty = Null
	Field _AwardCollection:TAwardCollection = Null
	Field _NewsEventSportCollection:TNewsEventSportCollection = Null
	
	Field _GameModifierManager:TGameModifierManager = Null
	Field _GameInformationCollection:TGameInformationCollection = Null
	Field _IngameHelpWindowCollection:TIngameHelpWindowCollection = Null

	Field _AudienceManager:TAudienceManager = Null
	Field _AdContractBaseCollection:TAdContractBaseCollection = Null
	Field _AdContractCollection:TAdContractCollection = Null

	Field _ScriptTemplateCollection:TScriptTemplateCollection = Null
	Field _ScriptCollection:TScriptCollection = Null
	Field _ProductionManager:TProductionManager = Null
	Field _ProductionConceptCollection:TProductionConceptCollection = Null
	Field _ProductionCompanyBaseCollection:TProductionCompanyBaseCollection = Null
	Field _ProgrammeRoleCollection:TProgrammeRoleCollection = Null
	Field _ProgrammePersonBaseCollection:TPersonBaseCollection = Null
	Field _ProgrammeDataCollection:TProgrammeDataCollection = Null
	Field _ProgrammeLicenceCollection:TProgrammeLicenceCollection = Null
	Field _ProgrammeProducerCollection:TProgrammeProducerCollection = Null

	Field _NewsEventTemplateCollection:TNewsEventTemplateCollection = Null
	Field _NewsEventCollection:TNewsEventCollection = Null
	Field _AchievementCollection:TAchievementCollection = Null
	Field _ArchivedMessageCollection:TArchivedMessageCollection = Null
	Field _FigureCollection:TFigureCollection = Null
	Field _PlayerCollection:TPlayerCollection = Null
	Field _PlayerFinanceCollection:TPlayerFinanceCollection = Null
	Field _PlayerFinanceHistoryListCollection:TPlayerFinanceHistoryListCollection = Null
	Field _PlayerProgrammePlanCollection:TPlayerProgrammePlanCollection = Null
	Field _PlayerProgrammeCollectionCollection:TPlayerProgrammeCollectionCollection = Null
	Field _PlayerBossCollection:TPlayerBossCollection = Null
	Field _PlayerDifficultyCollection:TPlayerDifficultyCollection = Null
	Field _PublicImageCollection:TPublicImageCollection = Null
	Field _PressureGroupCollection:TPressureGroupCollection = Null
	Field _EventManagerEvents:TList = Null
	Field _PopularityManager:TPopularityManager = Null
	Field _BroadcastManager:TBroadcastManager = Null
	Field _DailyBroadcastStatisticCollection:TDailyBroadcastStatisticCollection = Null
	Field _StationMapCollection:TStationMapCollection = Null
	Field _Elevator:TElevator
	Field _Building:TBuilding 'includes, sky, moon, ufo
	Field _RoomBoard:TRoomBoard 'signs
	Field _NewsAgency:TNewsAgency
	Field _RoomAgency:TRoomAgency
	Field _AuctionProgrammeBlocksList:TList
	Field _RoomHandler_Studio:RoomHandler_Studio
	Field _RoomHandler_MovieAgency:RoomHandler_MovieAgency
	Field _RoomHandler_AdAgency:RoomHandler_AdAgency
	Field _RoomHandler_ScriptAgency:RoomHandler_ScriptAgency
	Field _RoomHandler_News:RoomHandler_News
	Field _RoomDoorBaseCollection:TRoomDoorBaseCollection
	Field _RoomBaseCollection:TRoomBaseCollection
	Field _PlayerColorList:TObjectList
	Field _CurrentScreenName:String
	Field _adAgencySortMode:Int
	Field _officeProgrammeSortMode:Int
	Field _officeProgrammeSortDirection:Int
	Field _officeContractSortMode:Int
	Field _officeContractSortDirection:Int
	Field _supermarketCastSortDirection:Int
	Field _programmeDataIgnoreUnreleasedProgrammes:Int = False
	Field _programmeDataFilterReleaseDateStart:Int = False
	Field _programmeDataFilterReleaseDateEnd:Int = False
	Field _interface_ShowChannel:Int = 0
	Field _interface_ChatWindowMode:Int = 1
	Field _interface_ChatShowHideLocked:Int = 0
	Field _aiBase_AiRunning:Int = False
	Const MODE_LOAD:Int = 0
	Const MODE_SAVE:Int = 1


	Method Initialize:Int()
		TLogger.Log("TGameState.Initialize()", "Reinitialize all game objects", LOG_DEBUG)

		GameConfig.Initialize()

		'reset player colors
		TPlayerColor.Initialize()
		'initialize times before other things, as they might rely
		'on that time (eg. TBuildingIntervalTimer) and they would else
		'init with wrong times
		GetWorldTime().Initialize()
		'adjust time settings accordings to DEV.xml
		GetWorldTime()._daysPerSeason = Min(1000, Max(1, GameRules.devConfig.GetInt("DEV_WORLD_DAYS_PER_SEASON", GetWorldTime()._daysPerSeason)))


		GetBuildingTime().Initialize()
		GetRoomDoorBaseCollection().Initialize()
		GetRoomBaseCollection().Initialize()
		GetStationMapCollection().Initialize()
		GetPopularityManager().Initialize()
		GetNewsGenreDefinitionCollection().Initialize()
		GetMovieGenreDefinitionCollection().Initialize()
		AudienceManager.Initialize()
		GetGameModifierManager().Initialize()

		GetAdContractBaseCollection().Initialize()
		GetAdContractCollection().Initialize()
		GetScriptTemplateCollection().Initialize()
		GetScriptCollection().Initialize()
		GetProductionConceptCollection().Initialize()
		GetProductionCompanyBaseCollection().Initialize()
		GetProductionManager().Initialize()
		GetProgrammeRoleCollection().Initialize()
		GetPersonGenerator().Initialize()
		GetPersonBaseCollection().Initialize()
		GetProgrammeDataCollection().Initialize()
		GetProgrammeLicenceCollection().Initialize()
		TAuctionProgrammeBlocks.Initialize()
		GetNewsEventTemplateCollection().Initialize()
		GetNewsEventCollection().Initialize()
		GetProgrammeProducerCollection().Initialize()

		GetDailyBroadcastStatisticCollection().Initialize()
		GetFigureCollection().Initialize()
		GetAchievementCollection().Initialize()
		GetArchivedMessageCollection().Initialize()
		GetRoomAgency().Initialize()
		GetNewsAgency().Initialize()
		GetNewsEventSportCollection().InitializeAll()
		GetPublicImageCollection().Initialize()
		GetPressureGroupCollection().Initialize()
		GetBroadcastManager().Initialize()

		GetElevator().Initialize()
		GetBuilding().Initialize()
		GetRoomBoard().Initialize()
		GetElevatorRoomBoard().Initialize()
		GetWorld().Initialize()

		GetGame().Initialize()
		're-register event listeners
		GameEvents.Initialize()

		GetPlayerProgrammeCollectionCollection().Initialize()
		GetPlayerProgrammePlanCollection().InitializeAll()
		GetPlayerBossCollection().Initialize()
		GetPlayerCollection().Initialize()
		GetPlayerFinanceCollection().Initialize()
		GetPlayerFinanceHistoryListCollection().Initialize()

		'reset all achievements
		GetAchievementCollection().Reset()

		GetBetty().Initialize()

		GetAwardCollection().Initialize()

		'initialize known room handlers + event registration
		RegisterRoomHandlers()
		GetRoomHandlerCollection().Initialize()


		If TScreenHandler_ProgrammePlanner.PPprogrammeList
			TScreenHandler_ProgrammePlanner.PPprogrammeList.Initialize()
		EndIf
		If TScreenHandler_ProgrammePlanner.PPcontractList
			TScreenHandler_ProgrammePlanner.PPcontractList.Initialize()
		EndIf

		?bmxng
		'OCM.FetchDump("GAMESTATE INITIALIZE")
		'OCM.Dump()
		?
	End Method


	Method RestoreGameData:Int()
		_Assign(_FigureCollection, TFigureCollection._instance, "FigureCollection", MODE_LOAD)
		_Assign(_RoomDoorBaseCollection, TRoomDoorBaseCollection._instance, "RoomDoorBaseCollection", MODE_LOAD)
		_Assign(_RoomBaseCollection, TRoomBaseCollection._instance, "RoomBaseCollection", MODE_LOAD)

		_Assign(_PlayerColorList, TPlayerColor.registeredColors, "PlayerColorList", MODE_LOAD)
		_Assign(_GameInformationCollection, TGameInformationCollection._instance, "GameInformationCollection", MODE_LOAD)
		_Assign(_IngameHelpWindowCollection, IngameHelpWindowCollection, "IngameHelp", MODE_LOAD)

		_Assign(_AudienceManager, AudienceManager, "AudienceManager", MODE_LOAD)
		_Assign(_ProductionManager, TProductionManager._instance, "ProductionManager", MODE_LOAD)
		_Assign(_GameModifierManager, TGameModifierManager._instance, "GameModifierManager", MODE_LOAD)

		_Assign(_AdContractCollection, TAdContractCollection._instance, "AdContractCollection", MODE_LOAD)
		_Assign(_AdContractBaseCollection, TAdContractBaseCollection._instance, "AdContractBaseCollection", MODE_LOAD)


		_Assign(_ScriptTemplateCollection, TScriptTemplateCollection._instance, "ScriptTemplateCollection", MODE_LOAD)
		_Assign(_ScriptCollection, TScriptCollection._instance, "ScriptCollection", MODE_LOAD)
		_Assign(_ProductionConceptCollection, TProductionConceptCollection._instance, "ProductionConceptCollection", MODE_LOAD)
		_Assign(_ProductionCompanyBaseCollection, TProductionCompanyBaseCollection._instance, "ProductionCompanyBaseCollection", MODE_LOAD)
		_Assign(_ProgrammeRoleCollection, TProgrammeRoleCollection._instance, "ProgrammeRoleCollection", MODE_LOAD)
		_Assign(_ProgrammePersonBaseCollection, TPersonBaseCollection._instance, "ProgrammePersonBaseCollection", MODE_LOAD)
		_Assign(_ProgrammeDataCollection, TProgrammeDataCollection._instance, "ProgrammeDataCollection", MODE_LOAD)
		_Assign(_ProgrammeLicenceCollection, TProgrammeLicenceCollection._instance, "ProgrammeLicenceCollection", MODE_LOAD)
		_Assign(_ProgrammeProducerCollection, TProgrammeProducerCollection._instance, "ProgrammeProducerCollection", MODE_LOAD)

		_Assign(_PlayerCollection, TPlayerCollection._instance, "PlayerCollection", MODE_LOAD)
		_Assign(_PlayerDifficultyCollection, TPlayerDifficultyCollection._instance, "PlayerDifficultyCollection", MODE_LOAD)
		_Assign(_PlayerFinanceCollection, TPlayerFinanceCollection._instance, "PlayerFinanceCollection", MODE_LOAD)
		_Assign(_PlayerFinanceHistoryListCollection, TPlayerFinanceHistoryListCollection._instance, "PlayerFinanceHistoryListCollection", MODE_LOAD)
		_Assign(_PlayerProgrammeCollectionCollection, TPlayerProgrammeCollectionCollection._instance, "PlayerProgrammeCollectionCollection", MODE_LOAD)
		_Assign(_PlayerProgrammePlanCollection, TPlayerProgrammePlanCollection._instance, "PlayerProgrammePlanCollection", MODE_LOAD)
		_Assign(_PlayerBossCollection, TPlayerBossCollection._instance, "PlayerBossCollection", MODE_LOAD)
		_Assign(_PublicImageCollection, TPublicImageCollection._instance, "PublicImageCollection", MODE_LOAD)
		_Assign(_PressureGroupCollection, TPressureGroupCollection._instance, "PressureGroupCollection", MODE_LOAD)

		_Assign(_NewsEventTemplateCollection, TNewsEventTemplateCollection._instance, "NewsEventTemplateCollection", MODE_LOAD)
		_Assign(_NewsEventCollection, TNewsEventCollection._instance, "NewsEventCollection", MODE_LOAD)
		_Assign(_NewsAgency, TNewsAgency._instance, "NewsAgency", MODE_LOAD)
		_Assign(_RoomAgency, TRoomAgency._instance, "RoomAgency", MODE_LOAD)
		_Assign(_AchievementCollection, TAchievementCollection._instance, "AchievementCollection", MODE_LOAD)
		_Assign(_ArchivedMessageCollection, TArchivedMessageCollection._instance, "ArchivedMessageCollection", MODE_LOAD)
		_Assign(_Building, TBuilding._instance, "Building", MODE_LOAD)
		_Assign(_Elevator, TElevator._instance, "Elevator", MODE_LOAD)
		_Assign(_RoomBoard, TRoomBoard._instance, "RoomBoard", MODE_LOAD)
		_Assign(_EventManagerEvents, EventManager._events, "Events", MODE_LOAD)
		_Assign(_PopularityManager, TPopularityManager._instance, "PopularityManager", MODE_LOAD)
		_Assign(_BroadcastManager, TBroadcastManager._instance, "BroadcastManager", MODE_LOAD)
		_Assign(_DailyBroadcastStatisticCollection, TDailyBroadcastStatisticCollection._instance, "DailyBroadcastStatisticCollection", MODE_LOAD)
		_Assign(_StationMapCollection, TStationMapCollection._instance, "StationMapCollection", MODE_LOAD)
		_Assign(_NewsEventSportCollection, TNewsEventSportCollection._instance, "NewsEventSportCollection", MODE_LOAD)
		_Assign(_Betty, TBetty._instance, "Betty", MODE_LOAD)
		_Assign(_AwardCollection, TAwardCollection._instance, "AwardCollection", MODE_LOAD)
		_Assign(_WorldWeather, TWorld._instance.weather, "WorldWeather", MODE_LOAD)
		_Assign(_WorldTime, TWorldTime._instance, "WorldTime", MODE_LOAD)
		_Assign(_BuildingTime, TBuildingTime._instance, "BuildingTime", MODE_LOAD)

		Local backup:TData = GameRules.devConfigBackup
		GameRules.Reset()
		_Assign(_GameRules, GameRules, "GameRules", MODE_LOAD)
		If backup Then GameRules.devConfigBackup = backup

		_Assign(_GameConfig, GameConfig, "GameConfig", MODE_LOAD)
		_Assign(_AuctionProgrammeBlocksList, TAuctionProgrammeBlocks.list, "AuctionProgrammeBlocks", MODE_LOAD)

		_Assign(_RoomHandler_Studio, RoomHandler_Studio._instance, "Studios", MODE_LOAD)
		_Assign(_RoomHandler_MovieAgency, RoomHandler_MovieAgency._instance, "MovieAgency", MODE_LOAD)
		_Assign(_RoomHandler_AdAgency, RoomHandler_AdAgency._instance, "AdAgency", MODE_LOAD)
		_Assign(_RoomHandler_ScriptAgency, RoomHandler_ScriptAgency._instance, "ScriptAgency", MODE_LOAD)
		_Assign(_RoomHandler_News, RoomHandler_News._instance, "News", MODE_LOAD)
		_Assign(_Game, TGame._instance, "Game")
		'initialize() sets seed to 0, after assign randomSeedValue is correct, but was not used for setting the actual seed
		GetGame().SetRandomizerBase(GetGame().randomSeedValue)


		RoomHandler_AdAgency.ListSortMode = _adAgencySortMode
		TScreenHandler_ProgrammePlanner.PPprogrammeList.ListSortMode = _officeProgrammeSortMode
		TScreenHandler_ProgrammePlanner.PPprogrammeList.ListSortDirection = _officeProgrammeSortDirection
		TScreenHandler_ProgrammePlanner.PPcontractList.ListSortMode = _officeContractSortMode
		TScreenHandler_ProgrammePlanner.PPcontractList.ListSortDirection = _officeContractSortDirection
		TScreenHandler_SupermarketProduction.castSortType = _supermarketCastSortDirection

		TProgrammeData.ignoreUnreleasedProgrammes = _programmeDataIgnoreUnreleasedProgrammes
		TProgrammeData._filterReleaseDateStart = _programmeDataFilterReleaseDateStart
		TProgrammeData._filterReleaseDateEnd = _programmeDataFilterReleaseDateEnd

		GetInGameInterface().ShowChannel = _interface_ShowChannel
		GetInGameInterface().ChatWindowMode = _interface_ChatWindowMode
		GetInGameInterface().ChatShowHideLocked = _interface_ChatShowHideLocked

		TAiBase.AiRunning = _aiBase_AiRunning
	End Method


	Method BackupGameData:Int()
		'start with the most basic data, so we avoid that these basic
		'objects get serialized in the depths of more complex objects
		'instead of getting an "reference" there.


		'name of the current screen (or base screen)
		_CurrentScreenName = ScreenCollection.GetCurrentScreen().name

		_adAgencySortMode = RoomHandler_AdAgency.ListSortMode
		_officeProgrammeSortMode = TScreenHandler_ProgrammePlanner.PPprogrammeList.ListSortMode
		_officeProgrammeSortDirection = TScreenHandler_ProgrammePlanner.PPprogrammeList.ListSortDirection
		_officeContractSortMode = TScreenHandler_ProgrammePlanner.PPcontractList.ListSortMode
		_officeContractSortDirection = TScreenHandler_ProgrammePlanner.PPcontractList.ListSortDirection
		_supermarketCastSortDirection = TScreenHandler_SupermarketProduction.castSortType

		_programmeDataIgnoreUnreleasedProgrammes = TProgrammeData.ignoreUnreleasedProgrammes
		_programmeDataFilterReleaseDateStart = TProgrammeData._filterReleaseDateStart
		_programmeDataFilterReleaseDateEnd = TProgrammeData._filterReleaseDateEnd

		_interface_ShowChannel = GetInGameInterface().ShowChannel
		_interface_ChatWindowMode = GetInGameInterface().ChatWindowMode
		_interface_ChatShowHideLocked = GetInGameInterface().ChatShowHideLocked

		_aiBase_AiRunning = TAiBase.AiRunning


		_Assign(GameRules, _GameRules, "GameRules", MODE_SAVE)
		_Assign(GameConfig, _GameConfig, "GameConfig", MODE_SAVE)
		_Assign(TWorldTime._instance, _WorldTime, "WorldTime", MODE_SAVE)
		_Assign(TBuildingTime._instance, _BuildingTime, "BuildingTime", MODE_SAVE)

		'database data for contracts
		_Assign(TAdContractBaseCollection._instance, _AdContractBaseCollection, "AdContractBaseCollection", MODE_SAVE)
		_Assign(TAdContractCollection._instance, _AdContractCollection, "AdContractCollection", MODE_SAVE)
		'database data for scripts
		_Assign(TScriptTemplateCollection._instance, _ScriptTemplateCollection, "ScriptTemplateCollection", MODE_SAVE)
		_Assign(TScriptCollection._instance, _ScriptCollection, "ScriptCollection", MODE_SAVE)
		_Assign(TProductionCompanyBaseCollection._instance, _ProductionCompanyBaseCollection, "ProductionCompanyBaseCollection", MODE_SAVE)
		_Assign(TProductionConceptCollection._instance, _ProductionConceptCollection, "ProductionConceptCollection", MODE_SAVE)
		'database data for persons and their roles
		_Assign(TPersonBaseCollection._instance, _ProgrammePersonBaseCollection, "ProgrammePersonBaseCollection", MODE_SAVE)
		_Assign(TProgrammeRoleCollection._instance, _ProgrammeRoleCollection, "ProgrammeRoleCollection", MODE_SAVE)

		'database data for programmes
		_Assign(TProgrammeDataCollection._instance, _ProgrammeDataCollection, "ProgrammeDataCollection", MODE_SAVE)
		_Assign(TProgrammeLicenceCollection._instance, _ProgrammeLicenceCollection, "ProgrammeLicenceCollection", MODE_SAVE)

		_Assign(TProgrammeProducerCollection._instance, _ProgrammeProducerCollection, "ProgrammeProducerCollection", MODE_SAVE)

		_Assign(TPlayerColor.registeredColors, _PlayerColorList, "PlayerColorList", MODE_SAVE)
		_Assign(TGameInformationCollection._instance, _GameInformationCollection, "GameInformationCollection", MODE_SAVE)
		_Assign(IngameHelpWindowCollection, _IngameHelpWindowCollection, "IngameHelp", MODE_SAVE)

		_Assign(AudienceManager, _AudienceManager, "AudienceManager", MODE_SAVE)
		_Assign(TProductionManager._instance, _ProductionManager, "ProductionManager", MODE_SAVE)
		_Assign(TGameModifierManager._instance, _GameModifierManager, "GameModifierManager", MODE_SAVE)

		_Assign(TBuilding._instance, _Building, "Building", MODE_SAVE)
		_Assign(TElevator._instance, _Elevator, "Elevator", MODE_SAVE)
		_Assign(TRoomBoard._instance, _RoomBoard, "RoomBoard", MODE_SAVE)
		_Assign(TRoomBaseCollection._instance, _RoomBaseCollection, "RoomBaseCollection", MODE_SAVE)
		_Assign(TRoomDoorBaseCollection._instance, _RoomDoorBaseCollection, "RoomDoorBaseCollection", MODE_SAVE)
		_Assign(TFigureCollection._instance, _FigureCollection, "FigureCollection", MODE_SAVE)
		_Assign(TPlayerCollection._instance, _PlayerCollection, "PlayerCollection", MODE_SAVE)
		_Assign(TPlayerDifficultyCollection._instance, _PlayerDifficultyCollection, "TPlayerDifficultyCollection", MODE_SAVE)
		_Assign(TPlayerFinanceCollection._instance, _PlayerFinanceCollection, "PlayerFinanceCollection", MODE_SAVE)
		_Assign(TPlayerFinanceHistoryListCollection._instance, _PlayerFinanceHistoryListCollection, "PlayerFinanceHistoryListCollection", MODE_SAVE)
		_Assign(TPlayerProgrammeCollectionCollection._instance, _PlayerProgrammeCollectionCollection, "PlayerProgrammeCollectionCollection", MODE_SAVE)
		_Assign(TPlayerProgrammePlanCollection._instance, _PlayerProgrammePlanCollection, "PlayerProgrammePlanCollection", MODE_SAVE)
		_Assign(TPlayerBossCollection._instance, _PlayerBossCollection, "PlayerBossCollection", MODE_SAVE)
		_Assign(TPublicImageCollection._instance, _PublicImageCollection, "PublicImageCollection", MODE_SAVE)
		_Assign(TPressureGroupCollection._instance, _PressureGroupCollection, "PressureGroupCollection", MODE_SAVE)

		_Assign(TGame._instance, _Game, "Game", MODE_SAVE)


		_Assign(TNewsEventTemplateCollection._instance, _NewsEventTemplateCollection, "NewsEventTemplateCollection", MODE_SAVE)
		_Assign(TNewsEventCollection._instance, _NewsEventCollection, "NewsEventCollection", MODE_SAVE)
		_Assign(TNewsAgency._instance, _NewsAgency, "NewsAgency", MODE_SAVE)
		_Assign(TRoomAgency._instance, _RoomAgency, "RoomAgency", MODE_SAVE)
		_Assign(TAchievementCollection._instance, _AchievementCollection, "AchievementCollection", MODE_SAVE)
		_Assign(TArchivedMessageCollection._instance, _ArchivedMessageCollection, "ArchivedMessageCollection", MODE_SAVE)
		_Assign(EventManager._events, _EventManagerEvents, "Events", MODE_SAVE)
		_Assign(TPopularityManager._instance, _PopularityManager, "PopularityManager", MODE_SAVE)
		_Assign(TBroadcastManager._instance, _BroadcastManager, "BroadcastManager", MODE_SAVE)
		_Assign(TDailyBroadcastStatisticCollection._instance, _DailyBroadcastStatisticCollection, "DailyBroadcastStatisticCollection", MODE_SAVE)
		_Assign(TStationMapCollection._instance, _StationMapCollection, "StationMapCollection", MODE_SAVE)
		_Assign(TNewsEventSportCollection._instance, _NewsEventSportCollection, "NewsEventSportCollection", MODE_SAVE)
		_Assign(TBetty._instance, _Betty, "Betty", MODE_SAVE)
		_Assign(TAwardCollection._instance, _AwardCollection, "AwardCollection", MODE_SAVE)
		_Assign(TWorld._instance.weather, _WorldWeather, "WorldWeather", MODE_SAVE)
		_Assign(TAuctionProgrammeBlocks.list, _AuctionProgrammeBlocksList, "AuctionProgrammeBlocks", MODE_SAVE)
		'special room data
		_Assign(RoomHandler_Studio._instance, _RoomHandler_Studio, "Studios", MODE_SAVE)
		_Assign(RoomHandler_MovieAgency._instance, _RoomHandler_MovieAgency, "MovieAgency", MODE_SAVE)
		_Assign(RoomHandler_AdAgency._instance, _RoomHandler_AdAgency, "AdAgency", MODE_SAVE)
		_Assign(RoomHandler_ScriptAgency._instance, _RoomHandler_ScriptAgency, "ScriptAgency", MODE_SAVE)
		_Assign(RoomHandler_News._instance, _RoomHandler_News, "News", MODE_SAVE)
	End Method


	Method _Assign(objSource:Object Var, objTarget:Object Var, name:String="DATA", Mode:Int=0)
		If objSource
			objTarget = objSource
			If Mode = MODE_LOAD
				TLogger.Log("TGameState.RestoreGameData()", "Restore object "+name, LOG_DEBUG)
			Else
				TLogger.Log("TGameState.BackupGameData()", "Backup object "+name, LOG_DEBUG)
			EndIf
		Else
			TLogger.Log("TGameState", "object "+name+" was NULL - ignored", LOG_DEBUG)
		EndIf
	End Method
End Type



Type TSaveGame Extends TGameState
	'store the time gone since when the app started - timers rely on this
	'and without, times will differ after "loading" (so elevator stops
	'closing doors etc.)
	'this allows to have "realtime" (independend from "logic updates")
	'effects - for visual effects (fading), sound ...
	Field _Time_timeGone:Long = 0
	Field _Entity_globalWorldSpeedFactor:Float =  0
	Field _Entity_globalWorldSpeedFactorMod:Float =  0
	Const SAVEGAME_VERSION:int = 20
	Const MIN_SAVEGAME_VERSION:Int = 13
	Global messageWindow:TGUIModalWindow
	Global messageWindowBackground:TImage
	Global messageWindowLastUpdate:Long
	Global messageWindowUpdatesSkipped:Int = 0
	Global lastSaveTime:Long = 0 {nosave}
	Global autoSaveNow:Int = False {nosave}

	Global toSaveNow:Int = False {nosave}
	Global toSaveUri:String {nosave}

	'override to do nothing
	Method Initialize:Int()
		'
	End Method


	'override to add time adjustment
	Method RestoreGameData:Int()
		'restore basics _before_ normal data restoration
		'eg. entities might get recreated, so we need to make sure
		'that the "lastID" is restored before

		'restore "time gone since start"
		Time.SetTimeGone(_Time_timeGone)
		'set event manager to the ticks of that time
		EventManager._ticks = _Time_timeGone

		'restore entity speed
		TEntity.globalWorldSpeedFactor = _Entity_globalWorldSpeedFactor
		TEntity.globalWorldSpeedFactorMod = _Entity_globalWorldSpeedFactorMod

		'restore game data
		Super.RestoreGameData()
	End Method


	'override to add time storage
	Method BackupGameData:Int()
		'save a short summary of the game at the begin of the file
		_gameSummary = New TData
		_gameSummary.Add("game_version", VersionString)
		_gameSummary.Add("game_builddate", VersionDate)
		_gameSummary.Add("game_initial_builddate", GameConfig.savegame_initialBuildDate)
		_gameSummary.Add("game_initial_version", GameConfig.savegame_initialVersion)
		_gameSummary.Add("game_initial_savegameVersion", GameConfig.savegame_initialSaveGameVersion)
		_gameSummary.AddInt("game_saveCount", GameConfig.savegame_saveCount)
		_gameSummary.Add("game_mode", "singleplayer")
		_gameSummary.AddLong("game_timeGone", GetWorldTime().GetTimeGone())
		_gameSummary.Add("player_name", GetPlayer().name)
		_gameSummary.Add("player_channelName", GetPlayer().channelName)
		_gameSummary.AddLong("player_money", GetPlayer().GetMoney())
		_gameSummary.AddInt("savegame_version", SAVEGAME_VERSION)
		'store last ID of all entities, to avoid duplicates
		'store them in game summary to be able to reset before "restore"
		'takes place
		'- game 1 run till ID 1000 and is saved then
		'- whole game is restarted then, ID is again 0
		'- load in game 1 (having game objects with ID 1 - 1000)
		'- new entities would again get ID 1 - 1000
		'  -> duplicates
		_gameSummary.AddInt("entitybase_lastID", TEntityBase.lastID)
		_gameSummary.AddInt("gameobject_lastID", TGameObject.LastID)

		Super.BackupGameData()

		'store "time gone since start"
		_Time_timeGone = Time.GetTimeGone()
		'store entity speed
		_Entity_globalWorldSpeedFactor = TEntity.globalWorldSpeedFactor
		_Entity_globalWorldSpeedFactorMod = TEntity.globalWorldSpeedFactorMod
	End Method


	'override to output differing log texts
	Method _Assign(objSource:Object Var, objTarget:Object Var, name:String="DATA", Mode:Int=0)
		If objSource
			objTarget = objSource
		Else
			TLogger.Log("TSaveGame", "object "+name+" was NULL - ignored", LOG_DEBUG | LOG_SAVELOAD)
		EndIf
	End Method


	Method CheckGameData:Int()
		'check if all data is available
		Return True
	End Method


	Function UpdateMessage:Int(Load:Int=False, text:String="", progress:Float=0.0, forceUpdate:Int=False)
		'skip update if called too often (as it is still FPS limited ... !)
		If Not forceUpdate And Time.GetAppTimeGone() - messageWindowLastUpdate < 25 And messageWindowUpdatesSkipped < 5
			messageWindowUpdatesSkipped :+ 1
			Return False
		Else
			messageWindowUpdatesSkipped = 0
			messageWindowLastUpdate = Time.GetAppTimeGone()
		EndIf

		If Not messageWindowBackground
			messageWindowBackground = LoadImage(VirtualGrabPixmap(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight() ))
		EndIf

		SetClsColor 0,0,0
		'use graphicsmanager's cls as it resets virtual resolution first
		GetGraphicsManager().Cls()
		
		'before drawing the full screen (which is 100% of the "real" 
		'window dimension) we need to disable the virtual graphics area
		'to disable any resizing
		GetGraphicsManager().ResetVirtualGraphicsArea()
		DrawImage(messageWindowBackground, 0,0)
		GetGraphicsManager().SetupVirtualGraphicsArea()

		If Load = 1
			messageWindow.SetCaptionAndValue(GetLocale("PLEASE_BE_PATIENT"), GetLocale("SAVEGAME_GETS_LOADED") + "~n" + text)
		ElseIf Load = 0
			messageWindow.SetCaptionAndValue(GetLocale("PLEASE_BE_PATIENT"), GetLocale("SAVEGAME_GETS_CREATED") + "~n" + text )
		Else
			messageWindow.SetCaptionAndValue(GetLocale("PLEASE_BE_PATIENT"), text )
		EndIf

		messageWindow.Update()
		messageWindow.Draw()

		Flip 0
	End Function


	Function ShowMessage:Int(Load:Int=False, text:String="", progress:Float=0.0)
		'grab a fresh copy
		messageWindowBackground = LoadImage(VirtualGrabPixmap(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight() ))

		If messageWindow Then messageWindow.Remove()

		'create a new one
		messageWindow = New TGUIGameModalWindow.Create(New SVec2I(0,0), New SVec2I(400, 200), "SYSTEM")
		messageWindow.guiCaptionTextBox.SetFont(headerFont)
		messageWindow._defaultValueColor = TColor.clBlack.copy()
		messageWindow.defaultCaptionColor = TColor.clWhite.copy()
		messageWindow.SetCaptionArea(New TRectangle.Init(-1, 6, -1, 30))
		messageWindow.guiCaptionTextBox.SetValueAlignment( ALIGN_CENTER_TOP )
		'no buttons
		messageWindow.SetDialogueType(0)
		'use a non-button-background
		messageWindow.guiBackground.spriteBaseName = "gfx_gui_window"



		If GetGame().gamestate = TGame.STATE_RUNNING
			messageWindow.darkenedArea = New TRectangle.Init(0,0,800,385)
			messageWindow.screenArea = New TRectangle.Init(0,0,800,385)
		Else
			messageWindow.darkenedArea = Null
			messageWindow.screenArea = Null
		EndIf

		If Load
			messageWindow.SetCaptionAndValue(GetLocale("PLEASE_BE_PATIENT"), getLocale("SAVEGAME_GETS_LOADED") + "~n" + text)
		Else
			messageWindow.SetCaptionAndValue(GetLocale("PLEASE_BE_PATIENT"), getLocale("SAVEGAME_GETS_CREATED") + "~n" + text )
		EndIf

		messageWindow.Open()

		messageWindow.Update()
		messageWindow.Draw()

		Flip 0
	End Function


	Function CheckFileState:Int(fileURI:String, gameSummary:TData = Null, passedGameSummary:Int = False)
		If FileType(fileURI) = 0 'not found
			Return -1
		EndIf

		If Not gameSummary And Not passedGameSummary
			gameSummary = GetGameSummary(fileURI)
		EndIf

		If Not gameSummary
			Return -2
		ElseIf gameSummary.GetInt("savegame_version") < MIN_SAVEGAME_VERSION
			Return -3
		Endif
		
		Return 1
	End Function
	
	
	Function GetGameSummary:TData(stream:TStream, fileURI:String)
		If Not stream
			TLogger.Log("GetGameSummary", "file not found: " + fileURI, LOG_WARNING)
			'Notify "GetGameSummary: file not found: " + fileURI
			Return Null
		EndIf

		Local result:TData
		'as compressed savegame streams report a size of 0 we cannot simply
		'check the size first ...
		Local content:String
		Try 
			'read in first 10000 bytes, should be enough, adjust if 
			'game summary becomes lengthier
			content = stream.ReadString(10000)
		Catch ex:Object
			'TStreamReadException
		End Try

		If content
			'scan bmo version to avoid faulty deserialization
			Local bmoBeginString:String = "<bmo ver=~q"
			Local bmoBegin:Int = content.Find(bmoBeginString)
			Local bmoVersion:int
			if bmoBegin >= 0
				Local bmoEnd:Int = content.Find("~q>", bmoBegin + bmoBeginString.length)
				If bmoEnd >= 0
					bmoVersion = Int(content[bmoBegin + bmoBeginString.length .. bmoEnd])
				endIf
			EndIf

			If bmoVersion >= 8
				Local summaryStart:Int = content.Find("<TData", bmoBegin)
				Local summaryEnd:Int = content.Find("<field name=~q_Game~q type=~qTGame~q>", summaryStart)
				If summaryStart < summaryEnd And summaryStart >= 0 And summaryEnd >= 0
					Local summary:String = content[summaryStart .. summaryEnd]
					'also delete the "</field>"
					'and wrap it again in the "<bmo>" tag
					summaryEnd = summary.FindLast("</field>")
					If summaryEnd >= 0
						summary = "<?xml version=~q1.0~q encoding=~qutf-8~q?>~n<bmo ver=~q" + bmoVersion + "~q>~n" + summary[.. summaryEnd] + "~n</bmo>"
					EndIf
					Local p:TPersist = New TXMLPersistenceBuilder.Build()

					result = TData(p.DeserializeObject(summary))
					p.Free()
				EndIf
			EndIf
		EndIf

		If Not result
			TLogger.Log("GetGameSummary", "Invalid/Unknown savegame format in file: " + fileURI, LOG_WARNING)
			Return Null
		EndIf
		
		Return result
	End Function


	Function GetGameSummary:TData(fileURI:String)
		'Local streamPosBackup:Long
		Local stream:TStream
		'compressed file?
		Local isCompressed:Int = IsCompressedFile(fileURI)
		Local summaryData:TData
		
		If not isCompressed
			stream = ReadStream(fileURI)
			summaryData = GetGameSummary(stream, fileURI )
			
			'rewind stream position
			'stream.Seek(streamPosBackup)
			'we opened the stream? so we also close it here.
			If stream Then stream.Close()
		Else
			Local ra:TReadArchive = New TReadArchive
			ra.SetFormat(EArchiveFormat.RAW)
			ra.AddFilter(EArchivefilter.GZIP)
			ra.AddFilter(EArchivefilter.ZSTD)

			ra.Open(fileURI)

			Local entry:TArchiveEntry = New TArchiveEntry
			Local xmlStream:TStream
			While ra.ReadNextHeader(entry) = ARCHIVE_OK
				summaryData = GetGameSummary(ra.DataStream(), fileURI)
				exit
			Wend
			ra.Free() 'do not wait for GC
		EndIf


		If Not summaryData Then summaryData = New TData
		summaryData.Add("fileURI", fileURI)
		summaryData.Add("fileName", GetSavegameName(fileURI) )
		summaryData.AddNumber("fileTime", FileTime(fileURI))

		Return summaryData
	End Function


	Global _nilNode:TNode = New TNode._parent
	Function RepairData(savegameVersion:Int)
		If savegameVersion < 20
			'repair station coordinates from "pixel based" to "data based"
			Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
			For local pID:Int = 1 to 4
				For local station:TStationBase = EachIn GetStationMap(pID).stations
					station.SetPosition(mapInfo.ScreenXToDataX(station.x), mapInfo.ScreenYToDataY(station.y))

					if TStationAntenna(station)
						'the one which was calculated in earlier versions
						TStationAntenna(station).radius = 31
					EndIf
				Next
			Next
			GetStationMapCollection().antennaStationRadius = 31
			TLogger.Log("RepairData()", "Updated station positions and antennas radius to new stationmap data.", LOG_LOADING)
		EndIf

		If savegameVersion < 18
			'check difficulty object version
			GetPlayerDifficultyCollection().InitializeDefaults()
			For local pID:Int = 1 to 4
				Local playerDifficulty:TPlayerDifficulty = GetPlayerDifficulty(pID)
				If playerDifficulty
					If playerDifficulty.difficultyVersion < 1
						'before introduction of version - replace difficulty object completely
						Local newDifficulty:TPlayerDifficulty = GetPlayerDifficultyCollection().getByGUID(playerDifficulty.GetGUID())
						If not newDifficulty or newDifficulty.difficultyVersion < 1
							throw "replacing difficulty data for player "+pID+" failed"
						Else
							GetPlayerDifficultyCollection().RemoveByID(playerDifficulty.GetID())
							GetPlayerDifficultyCollection().AddToPlayer(pID, newDifficulty)
							TLogger.Log("RepairData", "difficulty data for player " + pID+" - replace with current data for level "+playerDifficulty.GetGUID())
						EndIf
					EndIf
				EndIf
			Next
		EndIf
		If savegameVersion < 18
			TLogger.Log("RepairData", "Removing AI-Events", LOG_SAVELOAD | LOG_DEBUG)
			For Local i:Int = 1 To 4
				Local p:TPlayer = GetPlayer(i)
				If p and p.IsLocalAI() and p.playerAI
					p.playerAI.eventQueue = new TAIEvent[0]
				EndIf
			Next
		EndIf
		If savegameVersion < 16
			'programme producers were not persisted before v16
			If GetProgrammeProducerCollection().GetCount() < 1
				TLogger.Log("RepairData", "Create (new) programme producers (savegame did not contain them)", LOG_SAVELOAD | LOG_DEBUG)
				GetGame().GenerateStartProgrammeProducers()
			EndIf
			For Local person:TPersonBase = EachIn GetPersonBaseCollection().GetCastablesList()
				Local prodData:TPersonProductionBaseData = person.GetProductionData()
				If prodData And prodData.priceModifier < 0.011
					prodData.priceModifier = 1.0
					TLogger.Log("RepairData", "Fix price modifier from 1% to intended 100% for "+person.getFullName(), LOG_SAVELOAD | LOG_DEBUG)
				EndIF
			Next
		EndIf
		if savegameVersion < 15
			'ensure consistent broadcast slots
			For local licence:TProgrammeLicence = EachIn GetProgrammeLicenceCollection().licences.Values()
				If licence.data and licence.broadcastTimeSlotStart >= 0 and licence.broadcastTimeSlotEnd >= 0
					licence.data.broadcastTimeSlotStart = licence.broadcastTimeSlotStart
					licence.data.broadcastTimeSlotEnd = licence.broadcastTimeSlotEnd
					TLogger.Log("RepairData", "licence " + RSet(licence.GetTitle(), 20) +" defined slots  - copy slots to data", LOG_SAVELOAD | LOG_DEBUG)
				EndIf
			Next
			For local script:TScript = EachIn GetScriptCollection().entries.Values()
				'fix potentially missing live time
				If script.isLive() And script.fixedLiveTime < 0
					script.SetProductionBroadcastFlag(TVTBroadcastMaterialSourceFlag.ALWAYS_LIVE, True)
					TLogger.Log("RepairData", "set script to AlwaysLive "+ script.getTitle(), LOG_SAVELOAD | LOG_DEBUG)
				EndIf
				If script.productionTime > 0 And script.productionTime < 200
					script.productionTime =  TWorldTime.MINUTELENGTH * script.productionTime
					TLogger.Log("RepairData", "update script production time minutes "+ script.getGUID(), LOG_SAVELOAD | LOG_DEBUG)
				EndIF
				'ensure live_time_fixed flag is unset, so it can later be reused
				If script.HasProductionBroadcastFlag(16384)
					script.SetProductionBroadcastFlag(16384, False)
					TLogger.Log("RepairData", "remove scripts live time fixed flag "+ script.getTitle(), LOG_SAVELOAD | LOG_DEBUG)
				EndIf
			Next
			'live date code for multiple productions would yield same live date for all
			For local template:TScriptTemplate = EachIn GetScriptTemplateCollection().entries.Values()
				If template.isLive() And template.productionLimit >1 And template.liveDateCode
					template.liveDateCode=""
					TLogger.Log("RepairData", "set template to AlwaysLive "+ template.getGUID(), LOG_SAVELOAD | LOG_DEBUG)
				EndIf
				If template.productionTime > 0 And template.productionTime < 200
					template.productionTime =  TWorldTime.MINUTELENGTH * template.productionTime
					TLogger.Log("RepairData", "update template production time minutes "+ template.getGUID(), LOG_SAVELOAD | LOG_DEBUG)
				EndIF
				For local sub:TScriptTemplate = EachIn template.subScripts
					'because we support 0 episodes, the old default value has to be changed
					If sub.episodesMin <= 0 Then sub.episodesMin = 1
					If sub.episodesMax <= 0 Then sub.episodesMax = 1
				Next
			Next
		endif
		Rem
			would "break" unfinished series productions with re-ordered
			production orders (1,3,2) and missing episodes ([1,null,3])

		'repair broken custom productions
		For local licence:TProgrammeLicence = EachIn GetProgrammeLicenceCollection().series.Values()
			if not licence.subLicences or licence.subLicences.length = 0 then continue

			local hasToFix:int = 0
			For local subIndex:int = 0 until licence.subLicences.length
				if not licence.subLicences[subIndex] then hasToFix :+ 1
			Next

			if hasToFix > 0
				print "Repairing series ~q"+licence.GetTitle()+"~q"
				local newSubLicences:TProgrammeLicence[]
				For local subIndex:int = 0 until licence.subLicences.length
					if licence.subLicences[subIndex] then newSubLicences :+ [ licence.subLicences[subIndex] ]
				Next
				licence.subLicences = newSubLicences
			endif
		Next
		endrem
	End Function


	Function CleanUpData()
		'=== CLEANUP ===
		'only needed until all "old savegames" run the current one
		'or our savegames once get incompatible to older versions...
		'(which happens a lot during dev)
		Local unused:Int
		Local used:Int = GetAdContractCollection().list.count()
		Local adagencyContracts:TList = RoomHandler_AdAgency.GetInstance().GetContractsInStock()
		If Not adagencyContracts Then adagencyContracts = CreateList()
		Local availableContracts:TAdContract[] = TAdContract[](GetAdContractCollection().list.ToArray())
		For Local a:TAdContract = EachIn availableContracts
			If a.owner = a.OWNER_NOBODY Or (a.daySigned = -1 And a.profit = -1 And Not adagencyContracts.Contains(a))
				unused :+1
				GetAdContractCollection().Remove(a)
			EndIf
		Next
		'print "Cleanup: removed "+unused+" unused AdContracts."


		TLogger.Log("Savegame.CleanUpData().", "Scriptcollection:", LOG_SAVELOAD | LOG_DEBUG)
		'used = GetScriptCollection().GetAvailableScriptList().Count()
		'local scriptList:TList = RoomHandler_ScriptAgency.GetInstance().GetScriptsInStock()
		'if not scriptList then scriptList = CreateList()
		Local availableScripts:TScript[] = TScript[](GetScriptCollection().GetAvailableScriptList().ToArray())
		unused = 0
		For Local s:TScript = EachIn availableScripts
			unused :+1
			GetScriptCollection().Remove(s)
			TLogger.Log("Savegame.CleanUpData().", "- removing script: "+s.GetTitle()+"  ["+s.GetGUID()+"]", LOG_SAVELOAD | LOG_DEBUG)
		Next
		TLogger.Log("Savegame.CleanUpData().", "Removed "+unused+" generated but unused scripts from collection.", LOG_SAVELOAD | LOG_DEBUG)
	End Function


	Function Load:Int(savegameURI:String, savegameName:String, setLastUsedName:Int = True, skipCompatibilityCheck:Int = False)
		'Local fileURI:String = GetSavegameURI(saveName)
		If _LoadURI(savegameURI, skipCompatibilityCheck)
			If setLastUsedName
				'also remember as used save name
				GameConfig.savegame_lastUsedName = savegameName
			EndIf
			
			Return True
		EndIf
		
		Return False
	End Function


	Function PrepareAutoSave(savegameURI:String)
		toSaveNow = True
		toSaveUri = savegameURI
	End Function


	Function Save:Int(savegameURI:String, savegameName:String="savegame", setLastUsedName:Int = True)
		'Local fileURI:String = GetSavegameURI(saveName)
		If _SaveURI(savegameURI)
			If setLastUsedName
				GameConfig.savegame_lastUsedName = savegameName
			EndIf
			Return True
		Else
			Return False
		EndIf
	End Function


	Function IsCompressedFile:Int(uri:String)
		Local format:String = IdentifyFileFormat(uri)
		Return (format = "zst" or format = "gzip")	
	End Function

	
	Function IdentifyFileFormat:String(uri:String)
		'read in first up to 100 chars of a file
		Local s:TStream = ReadStream(uri)
		Local readAmount:Int = Min(50, s.Size())
		'zst
		'file signature of ZST compression: 28 B5 2F FD
		If readAmount > 4 And s.ReadByte() = $28 and s.ReadByte() = $B5 and s.ReadByte() = $2F and s.ReadByte() = $FD
			Return "zst"
		EndIf
		'gzip
		If readAmount > 2
			s.Seek(0)
			If s.ReadByte() = $1f and s.ReadByte() = $8b
				Return "gzip"
			EndIf
		EndIf
		'for xml we simply search for "<?xml" but allow some mistakingly
		'added newlines (maybe user modified file a bit ... )
		If readAmount >= 50
			s.Seek(0)
			'if reading ~100 chars we could also identify "bmo"-value,
			'if somewhen needed
			Local chars:String = s.ReadString(readAmount)
			If chars.find("<?xml") >= 0
				Return "xml"
			EndIf
		EndIf
		return "unknown"
	End Function


	'internal/private function
	Function _LoadURI:Int(saveURI:String="savegame.xml", skipCompatibilityCheck:Int = False)
		'stop ai of previous game if some was running
		For Local i:Int = 1 To 4
			If GetPlayer(i) Then GetPlayer(i).StopAI()
		Next

		ShowMessage(True)

		Local savegameSummary:TData = GetGameSummary(saveURI)
		if not savegameSummary then savegameSummary = new TData
		Local loadedSaveGameVersion:Int = savegameSummary.GetInt("savegame_version")

		local fileState:Int = TSaveGame.CheckFileState(saveURI, savegameSummary, True)
		if skipCompatibilityCheck and fileState = -3 then fileState = 1

		'=== CHECK SAVEGAME ===
		If fileState < 0
			if fileState = -1
				TLogger.Log("Savegame.Load()", GetLocale("FILE_NOT_FOUND") + ": ~q"+saveURI+"~q.", LOG_SAVELOAD | LOG_ERROR)
				UpdateMessage(2, "|b|ERROR:|/b|~n" + GetLocale("FILE_NOT_FOUND") + ": ~q"+saveURI+"~q.", 0, True)
			elseif fileState = -2
				TLogger.Log("Savegame.Load()", GetLocale("INVALID_SAVEGAME") + ": ~q"+saveURI+"~q.", LOG_SAVELOAD | LOG_ERROR)
				UpdateMessage(2, "|b|ERROR:|/b|~n" + GetLocale("INVALID_SAVEGAME") + ": ~q"+saveURI+"~q.", 0, True)
			elseif fileState = -3
				TLogger.Log("Savegame.Load()", GetLocale("INCOMPATIBLE_SAVEGAME") + ": ~q"+saveURI+"~q.", LOG_SAVELOAD | LOG_ERROR)
				UpdateMessage(2, "|b|ERROR:|/b|~n" + GetLocale("INCOMPATIBLE_SAVEGAME") + ": ~q"+saveURI+"~q.", 0, True)
			endif
			'wait a second
			Delay(2500)
			'close message window
			If messageWindow Then messageWindow.Close()

			Return False
		EndIf

		TPersist.maxDepth = 4096*4
		Local persist:TPersist = New TXMLPersistenceBuilder.Build()
		'Local persist:TPersist = New TPersist
		persist.serializer = New TSavegameSerializer

		'reset entity ID
		'this avoids duplicate GUIDs
		TEntityBase.lastID = savegameSummary.GetInt("entitybase_lastID", 3000000)
		TGameObject.LastID = savegameSummary.GetInt("gameobject_lastID", 3000000)
		TLogger.Log("Savegame.Load()", "Restored TEntityBase.lastID="+TEntityBase.lastID+", TGameObject.LastID="+TGameObject.LastID+".", LOG_SAVELOAD | LOG_DEBUG)


		'try to repair older savegames
		If savegameSummary.GetString("game_version") <> VersionString Or savegameSummary.GetString("game_builddate") <> VersionDate
			TLogger.Log("Savegame.Load()", "Savegame was created with an older TVTower-build. Enabling basic compatibility mode.", LOG_SAVELOAD | LOG_DEBUG)
			persist.strictMode = False
			persist.converterTypeID = TTypeId.ForObject( New TSavegameConverter )

			'when loading other versions make a copy of the original
			If loadedSaveGameVersion <> SAVEGAME_VERSION
				Local backupFile:String = saveURI+"_v"+loadedSaveGameVersion
				If FileType(backupFile) = 0
					TLogger.Log("Savegame.Load()", "Create backup of ~q"+saveURI+"~q because it was saved with another save game version.", LOG_SAVELOAD | LOG_INFO)
					CopyFile(saveURI, saveURI+"_v"+loadedSaveGameVersion)
				EndIf
			EndIF
		EndIf

		Local loadingStart:Int = MilliSecs()

		'savegame deserialization creates new TGameObjects - and thus
		'increases the ID count!
		Local saveGame:TSaveGame
		Local isCompressed:Int = IsCompressedFile(saveURI)
		If not isCompressed
			saveGame = TSaveGame(persist.DeserializeFromFile(saveURI))
		Else
			'doable once New() is overloaded / corresponding PR merged
			'Local ra:TReadArchive = New TReadArchive(EArchiveFormat.RAW, [EArchivefilter.ZSTD, EArchivefilter.GZIP])
			Local ra:TReadArchive = New TReadArchive
			ra.SetFormat(EArchiveFormat.RAW)
			ra.AddFilter(EArchivefilter.GZIP)
			ra.AddFilter(EArchivefilter.ZSTD)

			ra.Open(saveURI)

			Local entry:TArchiveEntry = New TArchiveEntry
			While ra.ReadNextHeader(entry) = ARCHIVE_OK
				saveGame = TSaveGame(persist.DeserializeFromStream(ra.DataStream()))
				exit
			Wend
			ra.Free() 'do not wait for GC
		EndIf

		persist.Free()

		If Not saveGame
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveURI+"~q is corrupt.", LOG_SAVELOAD | LOG_ERROR)
			Return False
		Else
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveURI+"~q loaded in " + (MilliSecs() - loadingStart)+"ms.", LOG_SAVELOAD | LOG_DEBUG)
		EndIf

		If Not saveGame.CheckGameData()
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveURI+"~q is in bad state.", LOG_SAVELOAD | LOG_ERROR)
			Return False
		EndIf


		'=== RESET CURRENT GAME ===
		'reset game data before loading savegame data
		New TGameState.Initialize()

		Local savegameEventData:TData = new TData
		savegameEventData.AddString("saveName", saveURI)
		savegameEventData.AddInt("saved_savegame_version", loadedSaveGameVersion)
		savegameEventData.AddInt("current_savegame_version", TSaveGame.SAVEGAME_VERSION)

		'=== LOAD SAVED GAME ===
		'tell everybody we start loading (eg. for unregistering objects before)
		'payload is saveName
		TriggerBaseEvent(GameEventKeys.SaveGame_OnBeginLoad, savegameEventData)
		'load savegame data into game object
		saveGame.RestoreGameData()


		'reset "initial" version information (maybe this old savegame 
		'does not contain this information ... so we do not want to take
		'over the one from the current game
		'"Game - New Game" does set them to "null" values, so they
		'are automatically filled when saving. 
		'to avoid "loading old savegames and the saving them" to fill in
		'values, we use some "special" values here.
		If Not GameConfig.savegame_initialBuildDate 
			GameConfig.savegame_initialBuildDate = "unknown"
			GameConfig.savegame_initialVersion = "unknown"
			GameConfig.savegame_initialSaveGameVersion = "-1"
			GameConfig.savegame_saveCount = 0
		EndIf
		GameConfig.InRoomTimeSlowDownMod = App.config.GetInt("inroomslowdown", 100) / 100.0
		GameConfig.autoSaveIntervalHours = App.config.GetInt("autosaveInterval", 0)

		'tell everybody we finished loading (eg. for clearing GUI-lists)
		'payload is saveName and saveGame-object
		TriggerBaseEvent(GameEventKeys.SaveGame_OnLoad, savegameEventData)

		If not GetGame().GetObservedFigure() or GetGame().GetObservedFigure() = GetPlayer().GetFigure()
			'only set the screen if the figure is in this room ... this
			'allows modifying the player in the savegame
			If GetPlayer().GetFigure().inRoom
				Local playerScreen:TScreen = ScreenCollection.GetScreen(saveGame._CurrentScreenName)
				If playerScreen.name = GetPlayer().GetFigure().inRoom.GetScreenName() Or playerScreen.HasParentScreen(GetPlayer().GetFigure().inRoom.GetScreenName())
					'ScreenCollection.GoToScreen(playerScreen)
					'just set the current screen... no animation
					ScreenCollection._SetCurrentScreen(playerScreen)
				EndIf
			EndIf
Rem
			'if saved during screen change, try to recreate the transition
			'without this, the game shows the building while the figure
			'is in.
			If GetPlayer().GetFigure().isChangingRoom()
				ScreenCollection._SetCurrentScreen(GameScreen_World)

				if TRoomDoorBase(GetPlayer().GetFigure().GetTarget())
					local door:TRoomDoorBase = TRoomDoorBase(GetPlayer().GetFigure().GetTarget())
					local room:TRoomBase = GetRoomBaseCollection().Get(door.roomID)
					if room
						ScreenCollection.GoToScreen( ScreenCollection.GetScreen(room.screenName) )
					endif
				endif
			endif
endrem
		EndIf

		CleanUpData()


		RepairData(loadedSaveGameVersion)

		'close message window
		If messageWindow Then messageWindow.Close()

		'call game that game continues/starts now
		GetGame().StartLoadedSaveGame()

		TSaveGame.lastSaveTime = GetWorldTime().GetTimeGone()

		Return True
	End Function
		

	Function _SaveURI:Int(saveURI:String="savegame.xml")
		ShowMessage(False)
		
		'check if variants of the savegame filename exist - and delete them!
		Local fileURI1:String = StripExt(saveURI) + "." + GameConfig.uncompressedSavegameExtension
		Local fileURI2:String = StripExt(saveURI) + "." + GameConfig.compressedSavegameExtension
		If FileType(fileURI1) = FILETYPE_FILE Then DeleteFile(fileURI1)
		If FileType(fileURI2) = FILETYPE_FILE Then DeleteFile(fileURI2)


		'check directories and create them if needed
		Local dirs:String[] = ExtractDir(saveURI.Replace("\", "/")).Split("/")
		Local currDir:String
		For Local dir:String = EachIn dirs
			If currDir Then currDir :+ "/"
			currDir :+ dir
			'if directory does not exist, create it
			If FileType(currDir) <> 2
				TLogger.Log("Savegame.Save()", "Savegame path contains missing directories. Creating ~q"+currDir[.. currDir.length-1]+"~q.", LOG_SAVELOAD)
				CreateDir(currDir)
			EndIf
		Next
		If FileType(currDir) <> 2
			TLogger.Log("Savegame.Save()", "Failed to create directory ~q" + currDir + "~q for ~q"+saveURI+"~q.", LOG_SAVELOAD)
		EndIf

		Local t:Int = MilliSecs()
		Local saveGame:TSaveGame = New TSaveGame
		'tell everybody we start saving
		'payload is saveURI
		Local event:TEventBase = TEventBase.Create(GameEventKeys.SaveGame_OnBeginSave, New TData.addString("saveName", saveURI))
		event.Trigger()
		if event.IsVeto()
'			saveGame.UpdateMessage(False, "Saving: Saving aborted (timeout?).")
			'close message window
			If messageWindow Then messageWindow.Close()
			Local reason:String = event.GetData().GetString("vetoReason")
			if reason then reason = "|b|Reason:|/b| " + reason +"~n"
			TError.Create("Failed to save game", reason + "|i|Might help to wait a moment and then try again.|/i|", False)
			Return False
		EndIf
			

		'assign "initial" version information
		if not GameConfig.savegame_initialBuildDate then GameConfig.savegame_initialBuildDate = VersionDate
		if not GameConfig.savegame_initialVersion then GameConfig.savegame_initialVersion = VersionString
		if not GameConfig.savegame_initialSaveGameVersion then GameConfig.savegame_initialSaveGameVersion = TSaveGame.SAVEGAME_VERSION 
		'raise save count for this game
		GameConfig.savegame_saveCount :+ 1

		'store game data in savegame
		saveGame.BackupGameData()

		'setup tpersist config
		TPersist.format = True
		'XML files stay "pretty", compressed ones can already save
		'a bit processing time (formatting) and on whitespace
		If GameConfig.compressSavegames Then TPersist.format = False

		?debug
		saveGame.UpdateMessage(False, "Saving: Serializing data to savegame file.")
		?
		TPersist.maxDepth = 4096
		Local p:TPersist = New TXMLPersistenceBuilder.Build()
		p.serializer = New TSavegameSerializer

		If GameConfig.compressSavegames
			'compress the TStream of XML-Data into an archive and save it
			Local saveStream:TSTream = WriteStream(saveURI)

'			Local wa:TWriteArchive = New TWriteArchive(EArchiveFormat.RAW, [EArchiveFilter.ZSTD])
			Local wa:TWriteArchive = New TWriteArchive
			wa.SetFormat(EArchiveFormat.RAW)
			wa.AddFilter(EArchiveFilter.ZSTD)
			'wa.AddFilter(EArchiveFilter.gzip)
			wa.SetCompressionLevel(3) 'speed vs size
			wa.Open(saveStream)

			Local entry:TArchiveEntry = New TArchiveEntry
			wa.Header(entry)
			Local xmlArchiveStream:TStream = wa.DataStream()
			'serialize game into a TStream of XML-Data
			p.SerializeToFile(saveGame, xmlArchiveStream)

			wa.FinishEntry()
			entry.Free()

			wa.Close()
			xmlArchiveStream.Close()
			saveStream.Close()
		Else
			p.SerializeToFile(saveGame, saveURI)
		EndIf
		p.Free()

		'tell everybody we finished saving
		'payload is saveURI and saveGame-object
		TriggerBaseEvent(GameEventKeys.SaveGame_OnSave, New TData.addString("saveName", saveURI).add("saveGame", saveGame))

		TLogger.Log("Savegame.SaveURI()", "Savegame file ~q"+saveURI+"~q saved in " + (MilliSecs() - t)+"ms.", LOG_SAVELOAD | LOG_DEBUG)

		'close message window
		If messageWindow Then messageWindow.Close()

		TSaveGame.lastSaveTime = GetWorldTime().GetTimeGone()
		Return True
	End Function


	'strip base folders from the absolute URI
	'subfolders inside the base savegame path are kept
	'Result might be:
	' "testgames\testgame1"
	' "testgames\testgame1.xml" with stripExtension = False
	' "testgames\testgame1.zst" with stripExtension = False and a compressed game
	Function GetSavegameLocalURI:String(fileURI:String)
		'strip savegame path from fileURI
		Local p:String = GetSavegamePath()
		If p.length > 0 And fileURI.Find( p ) = 0
			fileURI = fileURI[ p.length .. ]
		EndIf

		'if no sub-directories are allowed, strip them
		'fileURI = StripDir(fileURI)

		'remove leading "/"
		If fileURI.length > 0 and (fileURI[0] = Asc("/") Or fileURI[0] = Asc("\"))
			fileURI = fileURI[1 ..]
		EndIf
		
		Return fileURI
	End Function


	Function GetSavegameName:String(fileURI:String)
		Return StripExt( GetSavegameLocalURI(fileURI) )
	End Function


	'set compressSavegames to 0 to forcefully disable compression
	'set compressSavegames to 1 to forcefully enable compression
	Function GetSavegameURI:String(fileName:String, compressSavegames:Int = -1)
		Local result:String = GetSavegamePath()
		if result Then result :+ "/"

		Return result + GetSavegameName(fileName) + "." + GameConfig.GetSavegameExtension(compressSavegames)
	End Function


	Function GetSavegamePath:String()
		Return "savegames"
	End Function
End Type


Type TSavegameConverter
	Method GetCurrentFieldName:Object(fieldName:String, parentTypeName:String)
		Select (string(parentTypeName)+":"+string(fieldName)).ToLower()
			'v0.8.3 -> "TAudienceResultBase: "PotentialMaxAudience" renamed to "PotentialAudience"
			case "TAudienceResultBase:PotentialMaxAudience".ToLower()
				Return "PotentialAudience"
			case "TAudienceResult:PotentialMaxAudience".ToLower()
				Return "PotentialAudience"

			'v0.7.4 -> "TAudienceManager: "currentAudienceBreakdown" renamed to "currentTargetGroupBreakdown"
			case "TAudienceManager:currentAudienceBreakdown".ToLower()
				Return "currentTargetGroupBreakdown"
			case "TAudienceManager:defaultAudienceBreakdown".ToLower()
				Return "defaultTargetGroupBreakdown"

			'v0.7 -> v0.7.1
			case "TProduction:startDate".ToLower()
				Return "startTime"
			case "TProduction:endDate".ToLower()
				Return "endTime"
			case "TProduction:status".ToLower()
				Return "productionStep"
		End Select

		Rem
		'example
		Select (string(parentTypeName)+":"+string(fieldName)).ToLower()
			case "TIngameHelpWindowCollection:disabledHelpGUIDs".ToLower()
				'could return new field name for it now
				Return "disabledHelpGUIDsNEW"
		End Select
		EndRem
		Return fieldName
	End Method
	
	
	Method GetCurrentTypeName:Object(typeName:String)
		Select typeName.ToLower()
			Rem
			'example
			Case "TMyClassOld".ToLower()
				Return "TMyClassNew"
			EndRem

			'v0.8.3: StationMap cleanup
			Case "TStation".ToLower()
				Return "TStationAntenna"
			
			Case "TPersonPersonalityAttribute".ToLower()
				Return "TRangedFloat"
			Default
				print "TSavegameConverter.GetCurrentTypeName(): unsupported but no longer known type ~q"+typeName+"~q requested."
				Return typeName
		End Select
	End Method


	'handling fields no longer existing a type (obj.pos:TVec2D -> obj.x, obj.y)
	Method HandleMissingField:Object(parentTypeName:String, fieldName:String, fieldTypeName:String, parent:Object, fieldObject:Object)
		Local handle:String = (parentTypeName+"."+fieldName+":"+fieldTypeName).ToLower()
		Select handle
rem
			'v0.8.3: StationMap cleanup
			case "TStationMap.reach:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "reach: " + reach
				Return parent
			case "TStationMap.reachBefore:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "reachBefore: " + reach
				Return parent
			case "TStationMap.reachMax:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "reachMax: " + reach
				Return parent
			case "TStationMap.cheatedMaxReach:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "cheatedMaxReach: " + reach
				Return parent
			case "TStationAntenna.reach:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "antenna.reach: " + reach
				Return parent
			case "TStationAntenna.reachMax:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "antenna.reachMax: " + reach
				Return parent
			case "TStationAntenna.reachExclusiveMax:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "antenna.reachExclusiveMax: " + reach
				Return parent
			case "TStationBase.reach:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "base.reach: " + reach
				Return parent
			case "TStationBase.reachMax:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "base.reachMax: " + reach
				Return parent
			case "TStationBase.reachExclusiveMax:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "base.reachExclusiveMax: " + reach
				Return parent
			case "TStationSatelliteUplink.reach:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "satellite.reach: " + reach
				Return parent
			case "TStationSatelliteUplink.reachMax:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "satellite.reachMax: " + reach
				Return parent
			case "TStationSatelliteUplink.reachExclusiveMax:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "satellite.reachExclusiveMax: " + reach
				Return parent
			case "TStationCableNetworkUplink.reach:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "cable.reach: " + reach
				Return parent
			case "TStationCableNetworkUplink.reachMax:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "cable.reachMax: " + reach
				Return parent
			case "TStationCableNetworkUplink.reachExclusiveMax:Int".ToLower()
				Local reach:Int = int(string(fieldObject))
				print "cable.reachExclusiveMax: " + reach
				Return parent
endrem
				
			'v0.8.1: TEntityCollection cleanup: TEntityCollection became TLongMap + TStringMap
			case "TFigureCollection.entries:TMap".ToLower()
				Local fc:TFigureCollection = TFigureCollection(parent)
				If fc
					Local map:TMap = TMap(fieldObject)
					For local eb:TEntityBase = EachIn map.Values()
						fc.Add(eb)
					Next
				EndIf

			'v0.7.4 -> "TSpriteFrameAnimationCollection.currentAnimationName" deprecated
			'          in favor of simpler "TSpriteFrameAnimationCollection.currentAnimation" 
			case "TSpriteFrameAnimationCollection.currentAnimationName:String".ToLower()
				Local collection:TSpriteFrameAnimationCollection = TSpriteFrameAnimationCollection(parent)
				If collection Then collection.SetCurrent(String(fieldObject), False, False)

			'v0.7.2 -> "TStation***.pos:TVec2D" became "TStation***.x and .y"
			case "TStation.pos:TVec2D".ToLower(), ..
			     "TStationAntenna.pos:TVec2D".ToLower(), ..
			     "TStationBase.pos:TVec2D".ToLower(), ..
			     "TStationCableNetworkUplink.pos:TVec2D".ToLower(), ..
			     "TStationSatelliteUplink.pos:TVec2D".ToLower()
			
			
				TStationBase(parent).x = TVec2D(fieldObject).x
				TStationBase(parent).y = TVec2D(fieldObject).y
				'Print "[INFORMATION] Handled missing field: " + parentTypeName+"."+fieldName+":"+fieldTypeName+"."
				Return parent
			
			default
				print "NOT handling ... " + handle
		End Select
		
		Return Null
	End Method
	
	
	'handling stuff like different types used in a field ("list:TList -> list:TMap")
	Method DeSerializeUnknownProperty:Object(oldType:String, newType:String, obj:Object, parentObj:Object)
		'Print "DeSerializeUnknownProperty: " + oldType + " > " + newType
		Local convert:String = (oldType+">"+newType).ToLower()
		Select convert
			'v0.7.2 -> "TStationMapSection.uplinkPos:TVec2D to :TVec2I
			case "TVec2D>TVec2I".ToLower()
				'room(base)collection?
				if parentObj and TTypeID.ForObject(parentObj).name().ToLower() = "TStationMapSection".ToLower()
					local old:TVec2D = TVec2D(obj)
					return new TVec2I(int(old.x + 0.5), int(old.y + 0.5))
				EndIf

			'v0.7.2 -> "TStationMapSection.uplinkPos:TVec2D to :TVec2I
			case "TVec2D>TVec2I".ToLower()
				'room(base)collection?
				if parentObj and TTypeID.ForObject(parentObj).name().ToLower() = "TStationMapSection".ToLower()
					local old:TVec2D = TVec2D(obj)
					print "old: " + old.ToString()
					return new TVec2I(int(old.x + 0.5), int(old.y + 0.5))
				EndIf

			'v0.7.1 -> 0.7.2: "TStationMapcollection.sections - TList to TStationMapSection[]"
			Case "TList>TStationMapSection[]".ToLower()
				Local list:TList = TList(obj)
				Local result:TStationMapSection[]
				For local section:TStationMapSection = EachIn list
					result :+ [section]
				Next
				Return result
				
			'v0.7.0 -> "Int to TTriStateIntBitmask"
			Case "Int>TTriStateIntBitmask".ToLower()
				local mask:TTriStateIntBitmask = new TTriStateIntBitmask
				mask.mask = Int(String(obj))
				'mask.SetAllModified()
				Return mask

			'generic
			Case "TList>TObjectList".ToLower()
				Local old:TList = TList(obj)
				If old
					Local res:TObjectList = New TObjectList
					For Local o:object = EachIn old
						res.AddLast(o)
					Next
					Return res
				EndIf

rem
			'v0.6.2 -> BroadcastStatistics from TMap to TIntMap
			Case "TMap>TIntMap".ToLower()
				Local old:TMap = TMap(obj)
				If old
					Local res:TIntMap = New TIntMap
					For Local oldV:String = EachIn old.Keys()
						res.Insert(Int(oldV), old.ValueForKey(oldV))
					Next
					Return res
				EndIf
endrem
			Rem
			Case "TIntervalTimer>TBuildingIntervalTimer".ToLower()
				Local old:TIntervalTimer = TIntervalTimer(obj)
				If old
					Local res:TBuildingIntervalTimer = New TBuildingIntervalTimer
					res.Init(old.interval, 0, old.randomnessMin, old.randomnessMax)

					Return res
				EndIf

			Case "TProgrammeLicenceFilter>TProgrammeLicenceFilterGroup".ToLower()
				If parentObj And TTypeId.ForObject(parentObj).name().ToLower() = "RoomHandler_MovieAgency".ToLower()
					Return RoomHandler_MovieAgency.GetInstance().filterAuction
				EndIf
			Case "TMap>TAudienceAttraction[]".ToLower()
				If parentObj And TTypeId.ForObject(parentObj).name().ToLower() = "TAudienceMarketCalculation".ToLower()
					Local oldMap:TMap = TMap(obj)
					Local newArr:TAudienceAttraction[]
					For Local att:TAudienceAttraction = EachIn oldMap.Values()
						newArr :+ [att]
					Next
					Return newArr
				EndIf

			case "TList>TIntMap".ToLower()
				'room(base)collection?
				if parentObj and TTypeID.ForObject(parentObj).name().ToLower() = "TRoomCollection".ToLower()
					local list:TList = TList(obj)
					if list
						local intMap:TIntMap = new TIntMap
						For local r:TRoomBase = EachIn list
							intMap.Insert(r.id, r)
						Next

						if TRoomBaseCollection(parentObj)
							TRoomBaseCollection(parentObj).count = list.Count()
						endif
						return intMap
					endif
				endif
			endrem
		End Select
		Return Null
	End Method
End Type


Type TSavegameSerializer
	Method SerializeTSpriteToString:String(obj:Object)
		Local sprite:TSprite = TSprite(obj)
		If Not sprite Then Return ""
		'Of sprite data, we only need an identifier and all data, which
		'is differing between games. This works because sprites are
		'the same between games - so we just reassign them on load

		'individual data: nothing
		'identifier: name
		Local res:String = sprite.name

		Return res
	End Method


	Method DeSerializeTSpriteFromString:Object(serialized:String, targetObj:Object)
		'local sprite:TSprite = TSprite(targetObj)
		'if not sprite then return null

		'only consists of name
		Local name:String = serialized
		targetObj = GetSpriteFromRegistry(name)

		Return targetObj
	End Method
End Type


'MENU: MAIN MENU SCREEN
Type TScreen_MainMenu Extends TGameScreen
	Field guiButtonStart:TGUIButton
	Field guiButtonNetwork:TGUIButton
	Field guiButtonOnline:TGUIButton
	Field guiButtonLoadGame:TGUIButton
	Field guiButtonSettings:TGUIButton
	Field guiButtonQuit:TGUIButton
	Field guiLanguageDropDown:TGUISpriteDropDown
	Field loadGameMenuWindow:TGUImodalWindowChain

	Field stateName:TLowerString

	Method Create:TScreen_MainMenu(name:String)
		Super.Create(name)
		SetGroupName("ExGame", "MainMenu")

		Self.SetScreenChangeEffects(Null,Null) 'menus do not get changers

		stateName = TLowerString.Create(name)
		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		Local panelGap:Int = GUIManager.config.GetInt("panelGap", 10)
		guiButtonsWindow = New TGUIGameWindow.Create(New SVec2I(300, 330), New SVec2I(200, 400), name)
		guiButtonsWindow.SetPadding(panelGap, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")

		guiButtonsPanel	= guiButtonsWindow.AddContentBox(0,0,-1,-1)

		TGUIButton.SetTypeFont( GetBitmapFontManager().baseFontBold )
		TGUIButton.SetTypeCaptionColor( new SColor8(75, 75, 75) )

		Local buttonWidth:int = Int(guiButtonsPanel.GetContentScreenRect().w)
		guiButtonStart		= New TGUIButton.Create(New SVec2I(0, 0*38), New SVec2I(buttonWidth, -1), "", name)
		guiButtonNetwork	= New TGUIButton.Create(New SVec2I(0, 1*38), New SVec2I(buttonWidth, -1), "", name)
		guiButtonNetwork.Disable()
		guiButtonOnline		= New TGUIButton.Create(New SVec2I(0, 2*38), New SVec2I(buttonWidth, -1), "", name)
		guiButtonOnline.Disable()
		guiButtonLoadGame	= New TGUIButton.Create(New SVec2I(0, 3*38), New SVec2I(buttonWidth, -1), "", name)
		guiButtonSettings	= New TGUIButton.Create(New SVec2I(0, 4*38), New SVec2I(buttonWidth, -1), "", name)
		guiButtonQuit		= New TGUIButton.Create(New SVec2I(0, 5*38 + 10), New SVec2I(buttonWidth, -1), "", name)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonNetwork)
		guiButtonsPanel.AddChild(guiButtonOnline)
		guiButtonsPanel.AddChild(guiButtonLoadGame)
		guiButtonsPanel.AddChild(guiButtonSettings)
		guiButtonsPanel.AddChild(guiButtonQuit)

		'for main menu janitor
		GetBuildingTime().SetTimeFactor(1.0)

		If TLocalization.languagesCount > 0
			guiLanguageDropDown = New TGUISpriteDropDown.Create(New SVec2I(620, 560), New SVec2I(170,-1), "Sprache", 128, name)
			Local itemHeight:Int = 0
			Local languageCount:Int = 0

			For Local lang:TLocalizationLanguage = EachIn TLocalization.languages
				languageCount :+ 1
				Local item:TGUISpriteDropDownItem = New TGUISpriteDropDownItem.Create(Null, Null, lang.Get("LANGUAGE_NAME_LOCALE"))
				item.SetValueColor(TColor.CreateGrey(100))
				item.data.Add("value", lang.Get("LANGUAGE_NAME_LOCALE"))
				item.data.Add("languageCode", lang.languageCode)
				item.data.add("spriteName", "flag_"+lang.languageCode)
				'item.SetZindex(10000)
				guiLanguageDropDown.AddItem(item)
				If itemHeight = 0 Then itemHeight = item.GetScreenRect().GetH()

				If lang.languageCode = TLocalization.GetCurrentLanguageCode()
					guiLanguageDropDown.SetSelectedEntry(item)
				EndIf
			Next
			GuiManager.SortLists()
			'we want to have max 4 items visible at once
			guiLanguageDropDown.SetListContentHeight(itemHeight * Min(languageCount,4))
			EventManager.registerListenerMethod(GUIEventKeys.GUIDropDown_OnSelectEntry, Self, "onSelectLanguageEntry", guiLanguageDropDown)
		EndIf

		'fill captions with the localized values
		SetLanguage()

		EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnClick, Self, "onClickButtons")

		Return Self
	End Method


	'handle clicks on the buttons
	Method onSelectLanguageEntry:Int(triggerEvent:TEventBase)
		Local languageEntry:TGUIObject = TGUIObject(triggerEvent.GetReceiver())
		If Not languageEntry Then Return False

		App.SetLanguage(languageEntry.data.GetString("languageCode", "en"))
		'auto save to user settings
		App.SaveSettings(App.config)

		'fill captions with the localized values
		SetLanguage()

	End Method


	'handle clicks on the buttons
	Method onClickButtons:Int(triggerEvent:TEventBase)
		Local sender:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not sender Then Return False
		Local game:TGame = GetGame()
		Select sender
			Case guiButtonSettings
					App.CreateSettingsWindow()

			Case guiButtonStart
					PrepareGameObject()
					game.SetGamestate(TGame.STATE_SETTINGSMENU)
					game.onlinegame = False
					game.networkgame = False

			Case guiButtonNetwork
					PrepareGameObject()
					game.SetGamestate(TGame.STATE_NETWORKLOBBY)
					game.onlinegame = False
					game.networkgame = True

			Case guiButtonOnline
					PrepareGameObject()
					game.SetGamestate(TGame.STATE_NETWORKLOBBY)
					game.onlinegame = True
					game.networkgame = False

			Case guiButtonLoadGame
					CreateLoadGameWindow()

			Case guiButtonQuit
					App.ExitApp = True
		End Select
	End Method


	Method PrepareGameObject()
		TLogger.Log("====== PREPARE NEW GAME ======", "", LOG_DEBUG)
		'EventManager.DumpListeners()

		'reset game data collections
		New TGameState.Initialize()
		'load custom configuration (usernames, ports, ...)
		GetGame().LoadConfig(App.config)
		'create player figures so they can get shown in the settings screen
		'does nothing if already done
		GetGame().CreateInitialPlayers()
	End Method



	Method CreateLoadGameWindow()
		'initialize font for the items
		TGUISavegameListItem.SetTypeFont(GetBitmapFont(""))

		'remove a previously created one
		If loadGameMenuWindow Then loadGameMenuWindow.Remove()

		loadGameMenuWindow = New TGUIModalWindowChain.Create(New SVec2I(0,0), New SVec2I(500,150), "SYSTEM")
		loadGameMenuWindow.SetZIndex(99000)
		loadGameMenuWindow.SetCenterLimit(New TRectangle.setTLBR(30,0,0,0))

		'append menu after creation of screen area, so it recenters properly
		Local loadMenu:TGUIModalLoadSavegameMenu = New TGUIModalLoadSavegameMenu.Create(New SVec2I(0,0), New SVec2I(520,356), "SYSTEM")
		loadMenu._defaultValueColor = TColor.clBlack.copy()
		loadMenu.defaultCaptionColor = TColor.clWhite.copy()

		loadGameMenuWindow.SetContentElement(loadMenu)

		'menu is always ingame...
		loadGameMenuWindow.SetDarkenedArea(New TRectangle.Init(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight()))
		'center to this area
		loadGameMenuWindow.SetScreenArea(New TRectangle.Init(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight()))

		loadGameMenuWindow.Open() 'to play a sound

		App.EscapeMenuWindow = loadGameMenuWindow
		loadGameMenuWindow = Null

		'RONNY: debug
		TLogger.Log("Dialogues", "Created LoadGame-Menu.", LOG_DEBUG)
	End Method


	'override default
	Method SetLanguage:Int(languageCode:String = "")
		guiButtonStart.SetCaption(GetLocale("MENU_SOLO_GAME"))
		guiButtonNetwork.SetCaption(GetLocale("MENU_NETWORKGAME"))
		guiButtonOnline.SetCaption(GetLocale("MENU_ONLINEGAME"))
		guiButtonLoadGame.SetCaption(GetLocale("LOAD_GAME"))
		guiButtonSettings.SetCaption(GetLocale("MENU_SETTINGS"))
		guiButtonQuit.SetCaption(GetLocale("MENU_QUIT"))
	End Method


	'override default draw
	Method Draw:Int(tweenValue:Float)
		DrawMenuBackground(False, True)

		'draw the janitor BEHIND the panels
		If MainMenuJanitor Then MainMenuJanitor.Draw(tweenValue)

		GUIManager.Draw(stateName)
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)
		Super.Update(deltaTime)

		'if gamesettings screen is still missing: disable buttons
		'-> resources not finished loading
		If Not ScreenGameSettings
			guiButtonStart.Disable()
			guiButtonNetwork.Disable()
			guiButtonOnline.Disable()
		Else
			guiButtonStart.Enable()
			'guiButtonNetwork.Enable()
			'guiButtonOnline.Enable()
		EndIf

		GUIManager.Update(stateName)

		If MainMenuJanitor
			GetBuildingTime().Update() 'figure uses this timer
			MainMenuJanitor.Update()
		EndIf
	End Method
End Type





'MENU: NETWORK LOBBY
Type TScreen_NetworkLobby Extends TGameScreen
	Field guiButtonJoin:TGUIButton
	Field guiButtonCreate:TGUIButton
	Field guiButtonBack:TGUIButton
	Field guiGameListWindow:TGUIGameWindow
	'available games list
	Field guiGameList:TGUIGameEntryList

	Field stateName:TLowerString

	Method Create:TScreen_NetworkLobby(name:String)
		Super.Create(name)
		SetGroupName("ExGame", "NetworkLobby")

		stateName = TLowerString.Create(name)
		'create and setup GUI objects
		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		Local panelGap:Int = GUIManager.config.GetInt("panelGap", 10)
		guiButtonsWindow = New TGUIGameWindow.Create(New SVec2I(590, 355), New SVec2I(200, 235), name)
		guiButtonsWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.SetCaption("")
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsPanel = guiButtonsWindow.AddContentBox(0,0,-1,-1)


		guiButtonJoin	= New TGUIButton.Create(New SVec2I(0, 0), New SVec2I(Int(guiButtonsPanel.GetContentScreenRect().w),-1), GetLocale("MENU_JOIN"), name)
		guiButtonCreate	= New TGUIButton.Create(New SVec2I(0, 45), New SVec2I(Int(guiButtonsPanel.GetContentScreenRect().w),-1), GetLocale("MENU_CREATE_GAME"), name)
		guiButtonBack	= New TGUIButton.Create(New SVec2I(0, Int(guiButtonsPanel.GetContentScreenRect().h - guiButtonJoin.GetScreenRect().h)), New SVec2I(Int(guiButtonsPanel.GetContentScreenRect().w), -1), GetLocale("MENU_BACK"), name)

		guiButtonsPanel.AddChild(guiButtonJoin)
		guiButtonsPanel.AddChild(guiButtonCreate)
		guiButtonsPanel.AddChild(guiButtonBack)

		guiButtonJoin.disable() 'until an entry is clicked


		'GameList
		'contained within a window/panel for styling
		guiGameListWindow = New TGUIGameWindow.Create(New SVec2I(20, 355), New SVec2I(520, 235), name)
		guiGameListWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiGameListWindow.guiBackground.spriteAlpha = 0.5
		Local guiGameListPanel:TGUIBackgroundBox = guiGameListWindow.AddContentBox(0,0,-1,-1)
		'add list to the panel (which is located in the window
		guiGameList	= New TGUIGameEntryList.Create(New SVec2I(0,0), New SVec2I(Int(guiGameListPanel.GetContentScreenRect().w), Int(guiGameListPanel.GetContentScreenRect().h)), name)
		guiGameList.SetBackground(Null)
		guiGameList.SetPadding(0, 0, 0, 0)

		guiGameListPanel.AddChild(guiGameList)

		'localize gui elements
		SetLanguage()

		'register clicks on TGUIGameEntry-objects -> game list
		EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnDoubleClick, Self, "onDoubleClickGameListEntry", "TGUIGameEntry")
		EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnClick, Self, "onClickButtons", "TGUIButton")

		'register to network game announcements
		EventManager.registerListenerMethod(TDigNetwork.eventKey_OnReceiveAnnounceGame, Self, "onReceiveAnnounceGame")

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
					GetGame().SetGamestate(TGame.STATE_SETTINGSMENU)
					?bmxng
						Network.localFallbackIP = DottedIPToInt(HostIp(GetGame().userFallbackIP))
					?Not bmxng
						Network.localFallbackIP = HostIp(GetGame().userFallbackIP)
					?
					Network.StartServer()
					Network.ConnectToLocalServer()
					Network.client.playerID	= 1

			Case guiButtonJoin
					JoinSelectedGameEntry()

			Case guiButtonBack
					GetGame().SetGamestate(TGame.STATE_MAINMENU)
					GetGame().onlinegame = False
					If Network.infoStream Then Network.infoStream.close()
					GetGame().networkgame = False
		End Select
	End Method


	'override default
	Method SetLanguage:Int(languageCode:String = "")
		guiButtonJoin.SetCaption(GetLocale("MENU_JOIN"))
		guiButtonCreate.SetCaption(GetLocale("MENU_CREATE_GAME"))
		guiButtonBack.SetCaption(GetLocale("MENU_BACK"))
		guiGameListWindow.SetCaption(GetLocale("AVAILABLE_GAMES"))
	End Method


	Method JoinSelectedGameEntry:Int()
		'try to get information about a clicked item
		Local entry:TGUIGameEntry = TGUIGameEntry(guiGamelist.getSelectedEntry())
		If Not entry Then Return False

		'guiButtonStart.disable()
		Local _hostIP:String = entry.data.getString("hostIP","0.0.0.0")
		Local _hostPort:Int = entry.data.getInt("hostPort",0)
		Local gameTitle:String = entry.data.getString("gameTitle","#unknowngametitle#")

		?bmxng
		If Network.ConnectToServer( DottedIPToInt(HostIp(_hostIP)), _hostPort )
		?Not bmxng
		If Network.ConnectToServer( HostIp(_hostIP), _hostPort )
		?
			Network.isServer = False
			GetGame().SetGameState(TGame.STATE_SETTINGSMENU)
			ScreenGameSettings.guiGameTitle.Value = gameTitle
		EndIf
	End Method


	Method Draw:Int(tweenValue:Float)
		DrawMenuBackground(True, False)

		If Not GetGame().onlinegame
			guiGameListWindow.SetCaption(GetLocale("MENU_NETWORKGAME")+" : "+GetLocale("MENU_AVAILABLE_GAMES"))
		Else
			guiGamelistWindow.SetCaption(GetLocale("MENU_ONLINEGAME")+" : "+GetLocale("MENU_AVAILABLE_GAMES"))
		EndIf

		GUIManager.Draw(stateName)
	End Method


	Method GetOnlineIP:Int()
		Local Onlinestream:TStream	= ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=MyIP")
		Local timeouttimer:Long		= Time.MilliSecsLong()+5000 '5 seconds okay?
		Local timeout:Byte			= False
		If Not Onlinestream Then Throw ("Not Online?")
		While Not Eof(Onlinestream) Or timeout
			If timeouttimer < Time.MilliSecsLong() Then timeout = True
			Local responsestring:String = ReadLine(Onlinestream)
			Local responseArray:String[] = responsestring.split("|")
			If responseArray <> Null
				Network.OnlineIP = responseArray[0]
				?bmxng
					Network.intOnlineIP = DottedIPToInt(HostIp(Network.OnlineIP))
				?Not bmxng
					Network.intOnlineIP = HostIp(Network.OnlineIP)
				?
				Print "[NET] set your onlineIP: "+responseArray[0]
			EndIf
		Wend
		CloseStream Onlinestream
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)
		'register for events if not done yet
		GetNetworkHelper().RegisterEventListeners()

		If guiGameList.GetSelectedEntry()
			guiButtonJoin.enable()
		Else
			guiButtonJoin.disable()
		EndIf

		If GetGame().onlinegame
			If Network.OnlineIP = "" Then GetOnlineIP()

			If Network.OnlineIP
				If Network.LastOnlineRequestTimer + Network.LastOnlineRequestTime < Time.MilliSecsLong()
	'TODO: [ron] rewrite handling
					Network.LastOnlineRequestTimer = Time.MilliSecsLong()
					Local Onlinestream:TStream   = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=ListGames")
					Local timeOutTimer:Long = Time.MillisecsLong()+2500 '2.5 seconds okay?
					Local timeOut:Int = False

					If Not Onlinestream Then Throw ("Not Online?")

					While Not Eof(Onlinestream) Or timeout
						If timeouttimer < Time.MilliSecsLong() Then timeout = True

						Local responsestring:String = ReadLine(Onlinestream)
						Local responseArray:String[] = responsestring.split("|")
						If responseArray And responseArray.length > 3
							Local gameTitle:String	= "[ONLINE] "+Network.URLDecode(responseArray[0])
							Local slotsUsed:Int		= Int(responseArray[1])
							Local slotsMax:Int		= 4
							Local _hostName:String	= "#unknownplayername#"
							Local _hostIP:String	= responseArray[2]
							Local _hostPort:Int		= Int(responseArray[3])

							guiGamelist.addItem( New TGUIGameEntry.CreateSimple(_hostIP, _hostPort, _hostName, gameTitle, slotsUsed, slotsMax) )
							Print "[NET] added "+gameTitle
						EndIf
					Wend
					CloseStream Onlinestream
				EndIf
			EndIf
		EndIf

		GUIManager.Update(stateName)
	End Method
End Type




'SCREEN: PREPARATION FOR A GAME START
'(loading savegame, synchronising multiplayer data)
Type TScreen_PrepareGameStart Extends TGameScreen
	Field SendGameReadyTimer:Long = 0
	Field StartMultiplayerSyncStarted:Long = 0
	Field messageWindow:TGUIGameModalWindow

	'Store call states as we try a "Non blocking" approach
	'which means, the update loop gets called multiple time.
	'To avoid multiple calls, we save the states.
	'====
	'was "startGame()" called already?
	Field startGameCalled:Int = False
	'was "prepareGame()" called already?
	Field prepareGameCalled:Int = False
	'was "SpreadConfiguration()" called already?
	Field spreadConfigurationCalled:Int = False
	'was "SpreadStartData()" called already?
	Field spreadStartDataCalled:Int = False
	'can "startGame()" get called?
	Field canStartGame:Int = False
	'we want to ensure the player sees the game-start information
	'at least ONCE
	Field renderedOneFrame:Int = False

	Field stateName:TLowerString

	Method Create:TScreen_PrepareGameStart(name:String)
		Super.Create(name)
		SetGroupName("ExGame", "PrepareGameStart")

		messageWindow = New TGUIGameModalWindow.Create(New SVec2I(0,0), New SVec2I(400,250), name)
		'messageWindow.DarkenedArea = new TRectangle.Init(0,0,800,385)
		messageWindow.SetCaptionAndValue("title", "")
		messageWindow.SetDialogueType(0) 'no buttons

		stateName = TLowerString.Create(name)

		Return Self
	End Method


	Method Draw:Int(tweenValue:Float)
		'draw settings screen as background
		'BESSER: VORHERIGEN BILDSCHIRM zeichnen (fuer Laden)
		ScreenCollection.GetScreen("GameSettings").Draw(tweenValue)

		'draw messageWindow
		GUIManager.Draw(stateName)

		'rect of the message window's content area
		Local messageRect:TRectangle = messageWindow.GetContentScreenRect()
		Local oldAlpha:Float = GetAlpha()
		SetAlpha messageWindow.GetScreenAlpha()
		Local messageDY:Int = 0
		If GetGame().networkgame
			GetBitmapFontManager().baseFont.DrawSimple(GetLocale("SYNCHRONIZING_START_CONDITIONS")+"...", messageRect.GetX(), messageRect.GetY() + messageDY, SColor8.Black)
			messageDY :+ 20
			Local allReady:Int = True
			For Local i:Int = 1 To 4
				If Not GetPlayerCollection().Get(i).networkstate Then allReady = False
				GetBitmapFontManager().baseFont.DrawSimple(GetLocale("PLAYER")+" "+i+"..."+GetPlayerCollection().Get(i).networkstate, messageRect.GetX(), messageRect.GetY() + messageDY, SColor8.Black)
				messageDY :+ 20
			Next
			If Not allReady Then GetBitmapFontManager().baseFont.DrawSimple("not ready!!", messageRect.GetX(), messageRect.GetY() + messageDY, SColor8.Black)
		Else
			GetBitmapFontManager().baseFont.DrawSimple(GetLocale("PREPARING_START_DATA")+"...", messageRect.GetX(), messageRect.GetY() + messageDY, SColor8.Black)
		EndIf
		SetAlpha oldAlpha
		
		
		renderedOneFrame = True
	End Method


	Method Reset:Int()
		startGameCalled = False
		prepareGameCalled = False
		spreadConfigurationCalled = False
		spreadStartDataCalled = False
		canStartGame = False
		renderedOneFrame = False
	End Method


	'override to reset values
	Method Start()
		TLogger.Log("====== START NEW GAME ======", "", LOG_DEBUG)
		Reset()

		If GetGame().networkGame
			messageWindow.SetCaption(GetLocale("STARTING_NETWORKGAME"))
		Else
			messageWindow.SetCaption(GetLocale("STARTING_SINGLEPLAYERGAME"))
		EndIf

		'do not play a sound...
		'messageWindow.Open()
	End Method


	Method BeginEnter:Int(fromScreen:TScreen=Null)
		Super.BeginEnter(fromScreen)

		If wait = 0 Then wait = Time.GetTimeGone()
		Reset()
	End Method


	Global wait:Long = 0

	'override default update
	Method Update:Int(deltaTime:Float)
		'update messagewindow
		GUIManager.Update(stateName)
		
		'skip processing until at least one frame of this screen
		'was also rendered/drawn
		if not renderedOneFrame then return False


		'=== STEPS ===
		'MP = MultiPlayer, SP = SinglePlayer, ALL = all modes
		'1. MP:  Spread configuration (database / name)
		'2. ALL: Prepare Game (load database, colorize things)
		'2. MP:  Check if ready to start game
		'3. ALL: Start game (if ready)


		'=== STEP 1 ===
		If GetGame().networkGame And Not spreadConfigurationCalled
			SpreadConfiguration()
			spreadConfigurationCalled = True
			StartMultiplayerSyncStarted = Time.GetTimeGone()
		EndIf


		If Not prepareGameCalled
			'prepare game data so game could just start (switch
			'to building)
			GetGame().PrepareStart(True)
			prepareGameCalled = True
		EndIf


		'=== STEP 2 ===
		If GetGame().networkGame
			'ask other players if they are ready (ask every 500ms)
			If GetGame().isGameLeader() And SendGameReadyTimer < Time.GetTimeGone()
				GetNetworkHelper().SendGameReady(GetPlayerCollection().playerID)
				SendGameReadyTimer = Time.GetTimeGone() + 500
			EndIf
			'go back to game settings if something takes longer than expected
			If Time.GetTimeGone() - StartMultiplayerSyncStarted > 10000
				Print "[NET] sync timeout"
				StartMultiplayerSyncStarted = 0
				GetGame().SetGamestate(TGame.STATE_SETTINGSMENU)
				Return False
			EndIf
		EndIf

		If Not startGameCalled
			'singleplayer games can always start
			If Not GetGame().networkGame
				canStartGame = True
			'multiplayer games can start if all players are ready
			Else
				Print "game not started..."
				If GetGame().startNetworkGame
					ScreenGameSettings.guiAnnounce.SetChecked(False)
					GetPlayer().networkstate = 1
					canStartGame = True
					'reset flag, no longer needed
					GetGame().startNetworkGame = False
				EndIf
			EndIf
		EndIf


		'=== STEP 3 ===
		If canStartGame And Not startGameCalled
			If GetGame().networkGame Then Print "[NET] StartNewGame"
			'just switch to the game, preparation is done
			GetGame().StartNewGame()
			startGameCalled = True
			TSaveGame.lastSaveTime = GetWorldTime().GetTimeGone()
		EndIf
	End Method


	'spread configuration to other players
	Method SpreadConfiguration:Int()
		If Not GetGame().networkGame Then Return False

		'send which database to use (or send database itself?)
	End Method
End Type




Type GameEvents
	Global _eventListeners:TEventListenerBase[]


	Function Initialize:Int()
		UnRegisterEventListeners()
		RegisterEventListeners()

		Return True
	End Function


	Function UnRegisterEventListeners:Int()
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]
	End Function


	Function RegisterEventListeners:Int()
		'react on right clicks during a rooms update (leave room)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Room_OnUpdateDone, RoomOnUpdate) ]

		'forcefully set current screen (eg. after loading a "currently
		'leaving a screen" savegame, or with a faulty timing between
		'doors and screen-transition-animation)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Figure_SetInRoom, onFigureSetInRoom) ]

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Figure_OnReachTarget, RestoreSpeedOnReachTarget) ]

		'refresh ingame help
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnFinishEnter, OnEnterNewScreen) ]

		'pause on modal windows
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIModalWindow_OnOpen, OnOpenModalWindow) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIModalWindow_OnClose, OnCloseModalWindow) ]
		'pause on ingame help
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.InGameHelp_ShowHelpWindow, OnOpenIngameHelp) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.InGameHelp_CloseHelpWindow, OnCloseIngameHelp) ]

		'=== REGISTER TIME EVENTS ===
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnDay, OnDay) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnHour, OnHour) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnMinute, OnMinute) ]

		'=== REGISTER PLAYER EVENTS ===
		'events get ignored by non-gameleaders
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnMinute, PlayersOnMinute) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnDay, PlayersOnDay) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnBegin, PlayersOnBeginGame) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnRealTimeSecond, PlayersOnRealTimeSecond) ]

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_SetPlayerBankruptBegin, PlayerOnSetBankrupt) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PlayerFinance_OnChangeMoney, PlayerFinanceOnChangeMoney) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PlayerFinance_OnTransactionFailed, PlayerFinanceOnTransactionFailed) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PlayerBoss_OnCallPlayer, PlayerBoss_OnCallPlayer) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PlayerBoss_OnCallPlayerForced, PlayerBoss_OnCallPlayerForced) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PlayerBoss_OnPlayerEnterBossRoom, PlayerBoss_OnPlayerEnterBossRoom) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PlayerBoss_OnPlayerTakesCredit, PlayerBoss_OnTakeOrRepayCredit) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PlayerBoss_OnPlayerRepaysCredit, PlayerBoss_OnTakeOrRepayCredit) ]

		'=== PUBLIC AUTHORITIES ===
		'-> create ingame notifications
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PublicAuthorities_OnStopXRatedBroadcast, publicAuthorities_onStopXRatedBroadcast) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PublicAuthorities_OnConfiscateProgrammeLicence, publicAuthorities_onConfiscateProgrammeLicence) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Achievement_OnComplete, Achievement_OnComplete) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Award_OnFinish, Award_OnFinish) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Mission_Failed, Mission_OnFail) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Mission_Achieved, Mission_OnAchieve) ]

		'visually inform that selling the last station is impossible
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_OnTrySellLastStation, StationMap_OnTrySellLastStation) ]
		'trigger audience recomputation when a station is trashed/sold
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_RemoveStation, StationMap_OnRemoveStation) ]
		'show ingame toastmessage if station is under construction
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_AddStation, StationMap_OnAddStation) ]
		'show ingame toastmessage if your audience reach level changes
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_OnChangeReachLevel, StationMap_OnChangeReachLevel) ]
		'show ingame toastmessage if station is under construction
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Station_OnContractEndsSoon, Station_OnContractEndsSoon) ]
		'show ingame toastmessage if bankruptcy could happen
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_SetPlayerBankruptLevel, Game_OnSetPlayerBankruptLevel) ]

		'listen to failed or successful ending adcontracts to send out
		'ingame toastmessages
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.AdContract_OnFinish, AdContract_OnFinish) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.AdContract_OnFail, AdContract_OnFail) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeLicenceAuction_OnGetOutbid, ProgrammeLicenceAuction_OnGetOutbid) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeLicenceAuction_OnWin, ProgrammeLicenceAuction_OnWin) ]

		'listen to custom programme events to send out toastmessages
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Production_Finalize, Production_OnFinalize) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Production_FinishPreProduction, Production_OnFinishPreProduction) ]

		'reset room signs when a bomb explosion in a room happened
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Room_OnBombExplosion, Room_OnBombExplosion) ]

		'we want to handle "/dev bla"-commands via chat
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Chat_OnAddEntry, onChatAddEntry ) ]
		'relay incoming chat messages to the AI
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Chat_OnAddEntry, onChatAddEntryForAI ) ]
	End Function


	'helper
	Function CreateArchiveMessageFromToastMessage:TArchivedMessage(toastMessage:TGameToastMessage)
		If Not toastMessage Then Return Null

		Local archivedMessage:TArchivedMessage = New TArchivedMessage
		archivedMessage.SetTitle(toastMessage.caption)
		archivedMessage.SetText(toastMessage.text)
		archivedMessage.messageCategory = toastMessage.messageCategory
		archivedMessage.group = toastMessage.messageType 'positive, negative, information ...
		archivedMessage.time = GetWorldTime().GetTimeGone()
		archivedMessage.sourceGUID = toastMessage.GetGUID()
		archivedMessage.SetOwner( toastMessage.GetData().GetInt("playerID", -1) )

		Return archivedMessage
	End Function


	Function OnOpenIngameHelp:Int(triggerEvent:TEventBase)
		App.SetPausedBy(TApp.PAUSED_BY_INGAMEHELP, True)
	End Function


	Function OnCloseIngameHelp:Int(triggerEvent:TEventBase)
		App.SetPausedBy(TApp.PAUSED_BY_INGAMEHELP, False)
	End Function


	Function OnOpenModalWindow:Int(triggerEvent:TEventBase)
		'we either skip elements NOT to pause or we do the opposite
		'If TGUIProductionModalWindow(triggerEvent.GetSender()) Then Return False
		'print "  sender=" + TTypeID.ForObject( triggerEvent.GetSender() ).name()

		If TIngameHelpModalWindow(triggerEvent.GetSender())
			App.SetPausedBy(TApp.PAUSED_BY_MODALWINDOW)
		EndIf
	End Function


	Function OnCloseModalWindow:Int(triggerEvent:TEventBase)
		'we either skip elements NOT to pause or we do the opposite
		'If TGUIProductionModalWindow(triggerEvent.GetSender()) Then Return False
		

		If TIngameHelpModalWindow(triggerEvent.GetSender())
			App.SetPausedBy(TApp.PAUSED_BY_MODALWINDOW, False)
		EndIf
	End Function


	'correct potentially "broken" (eg. savegame inbetween a "leaving" state)
	'screen assignments
	Function onFigureSetInRoom:Int(triggerEvent:TEventBase)
		Local fig:TFigureBase = TFigureBase(triggerEvent.GetSender())

		If GetGame().GetObservedFigure() = fig
			If fig.GetInRoom()
				ScreenCollection._SetCurrentScreen(ScreenCollection.GetCurrentScreen())
			Else
				ScreenCollection._SetCurrentScreen(GetGame().GameScreen_world)
			EndIf
		EndIf
	End Function


	Function RestoreSpeedOnReachTarget:Int(triggerEvent:TEventBase)
		Local fig:TFigureBase = TFigureBase(triggerEvent.GetSender())
		If fig = GetPlayer().GetFigure()
			App.DEV_FastForward_TargetReached = True
			App.__SwitchFastForward(False)
		EndIf
	End Function


	Function OnEnterNewScreen:Int(triggerEvent:TEventBase)
		Local screen:TScreen = TScreen(triggerEvent.GetSender())
		If Not screen Then Return False

		'try to show the ingame help for that screen (if there is any)
		IngameHelpWindowCollection.ShowByHelpGUID( screen.GetName() )
	End Function


	Function onChatAddEntryForAI:Int(triggerEvent:TEventBase)
		Local text:String = triggerEvent.GetData().GetString("text")
		Local senderID:Int = triggerEvent.GetData().GetInt("senderID")
		Local channels:Int = triggerEvent.GetData().GetInt("channels")

		Local commandType:Int = TGUIChat.GetCommandFromText(text)
		Local commandText:String = TGUIChat.GetCommandStringFromText(text)
		'print "SenderID=" + senderID +"   commandType/Text="+commandType + "/"+commandText + "   text="+text

		'=== PRIVATE / WHISPER ===
		'-> send to AI ?
		If commandType = CHAT_COMMAND_WHISPER
			Local message:String = TGUIChat.GetPayloadFromText(text)
			Local receiver:String = message.split(" ")[0]
			Local receiverID:Int = Int(receiver)
			Local playerBase:TPlayerBase
			If String(receiverID) <> receiver > 9 'some odd number containing thing or playername?
				For Local pBase:TPlayerBase = EachIn GetPlayerBaseCollection().players
					If pBase.name.ToLower() = receiver.ToLower()
						message = message[receiver.length+1 ..] 'remove name/id
						receiverID = pBase.playerID
						receiver = pBase.name
						playerBase = pBase
						Exit
					EndIf
				Next
			ElseIf receiverID > 0 And receiverID < 9
				message = message[receiver.length+1 ..] 'remove name/id
				playerBase = GetPlayerBase(receiverID)
				If playerBase
					receiver = playerBase.name
				EndIf
			EndIf
			If playerBase And TPlayer(playerBase).isLocalAI()
				TPlayer(playerBase).PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnChat).AddInt(senderID).AddString(message).AddInt(CHAT_COMMAND_WHISPER))
				'TPlayer(playerBase).PlayerAI.CallOnChat(senderID, message, CHAT_COMMAND_WHISPER)
			EndIf
		EndIf

		'public chat
		If commandType = CHAT_COMMAND_NONE
			'ignore chats starting with a "command" (maybe misspelled a whisper)
			'also ignore system channel messages
			If text.Trim().Find("/") <> 0 And (channels & CHAT_CHANNEL_SYSTEM) = 0 'or text.trim().Find("[DEV]") = 0
				'local channels:int = TGUIChat.GetChannelsFromText(text)
				Local message:String = TGUIChat.GetPayloadFromText(text)

				'inform local AI
				For Local player:TPLayer = EachIn GetPlayerCollection().players
					'also check playerAI as in start settings screen the AI
					'is not there yet
					If player.isLocalAI() And player.playerAI
						player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnChat).AddInt(senderID).AddString(message).AddInt(CHAT_COMMAND_WHISPER).AddInt(channels))
						'player.PlayerAI.CallOnChat(senderID, message, CHAT_COMMAND_NONE, channels)
					EndIf
				Next
			EndIf
			Return True
		EndIf
	End Function


	Function onChatAddEntry:Int(triggerEvent:TEventBase)
		Local text:String = triggerEvent.GetData().GetString("text")

		'=== SYSTEM / DEV Chat ===
		'only interested in system/dev-commands from here on
		If TGUIChat.GetCommandFromText(text) <> CHAT_COMMAND_SYSTEM Then Return False


		'skip "/sys " and only return the payload
		'-> "/sys addmoney 1000" gets "addmoney 1000"
		text = TGUIChat.GetPayloadFromText(text)
		text = text.Trim()

		Local command:String, payload:String
		FillCommandPayload(text, command, payload)

		'try to fetch a player (saves to repeat those lines over and over)
		Local playerS:String, paramS:String
		FillCommandPayload(payload, playerS, paramS)
		Local player:TPlayer = GetPlayer(Int(playerS))

		Local PLAYER_NOT_FOUND:String = "[DEV] player not found."

		'do not support cheat in prod mode
		If Not GameRules.devMode And StringHelper.GetArrayIndex(command, ["devkeys", "reloaddev"]) < 0 Then command = "help"

		Select command.Trim().toLower()
			Case "devkeys"
				Local on:Int = Int(payload) = 1
				
				If on And Not GameRules.devMode
					GameRules.devMode = True
					GetGame().SendSystemMessage("[DEV] Enabled dev keys.")
				ElseIf Not on And GameRules.devMode
					GameRules.devMode = False
					GetGame().SendSystemMessage("[DEV] Disabled dev keys.")
				EndIf
				
			Case "loaddb"
				Local dbName:String = payload.Trim()
				If dbName
					'find all fitting files
					Local dirTree:TDirectoryTree = New TDirectoryTree.SimpleInit("res/database/Default")
					dirTree.SetIncludeFileEndings(["xml"])
					dirTree.ScanDir("", True)
					Local fileURIs:String[] = dirTree.GetFiles("", "", "", "", dbName)

					LoadDB(fileURIs)
					GetGame().SendSystemMessage("[DEV] Loaded the following DBs: "+ ", ".join(fileURIs) +".")
				Else
					LoadDB()
					GetGame().SendSystemMessage("[DEV] Loaded the all DBs in the DB directory.")
				EndIf

				GetNewsEventCollection()._InvalidateCaches()

			Case "maxaudience"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				DebugScreen.Dev_MaxAudience(player.playerID)

			Case "commandai"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				If Not player.IsLocalAI()
					GetGame().SendSystemMessage("[DEV] cannot command non-local AI player.")
				Else
					player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnChat).AddInt(GetPlayer().playerID).AddString("CMD_" + paramS).AddInt(CHAT_COMMAND_WHISPER))
					'player.playerAI.CallOnChat(GetPlayer().playerID, "CMD_" + paramS, CHAT_COMMAND_WHISPER)
				EndIf

			Case "playerai"
				If GetGame().networkGame
					GetGame().SendSystemMessage("[DEV] Cannot adjust AI in network games.")
					Return False
				EndIf

				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				TDebugScreenPage_Misc.GetInstance().Dev_SetPlayerAI(player.playerID, Int(params) = 1)

			Case "bossmood"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local changed:String = ""
				If paramS <> ""
					GetPlayerBoss(player.playerID).ChangeMood(Int(paramS))

					If Int(paramS) > 0 Then paramS = "+"+Int(paramS)
					changed = " ("+paramS+"%)"
				EndIf
				GetGame().SendSystemMessage("[DEV] Mood of boss "+playerS+": "+GetPlayerBoss(player.playerID).GetMood()+"%." + changed)

			Case "money"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local changed:String = ""
				If paramS <> ""
					player.GetFinance().CheatMoney(Int(paramS))

					If Int(paramS) > 0 Then paramS = "+"+Int(paramS)
					changed = " ("+paramS+")"
				EndIf
				GetGame().SendSystemMessage("[DEV] Money of player "+playerS+": "+player.GetFinance().money+"." + changed)

			Case "image"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local changed:String = ""
				If paramS <> ""
					player.GetPublicImage().ChangeImage( New SAudience(Float(paramS), Float(paramS)))

					If Int(paramS) > 0 Then paramS = "+"+Int(paramS)
					changed = " ("+paramS+"%)"
				EndIf
				GetGame().SendSystemMessage("[DEV] Image of player "+playerS+": "+player.GetPublicImage().GetAverageImage()+"%." + changed)

			Case "terrorlvl"
				Local paramArray:String[]
				If paramS <> "" Then paramArray = paramS.Split(" ")

				If Len(paramArray) = 1
					GetNewsAgency().SetTerroristAggressionLevel(Int(playerS), Int(paramArray[0]))
					GetGame().SendSystemMessage("[DEV] Changed terror level of terror group '" + playerS + "' to '" + paramArray[0] + "'!")
				Else
					GetGame().SendSystemMessage("Wrong syntax (/dev help)!")
				EndIf

			Case "setbankrupt"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				GetGame().SetPlayerBankrupt(player.playerID)
				GetGame().SendSystemMessage("[DEV] Set player '" + player.name +"' ["+player.playerID + "] bankrupt!")

			Case "gotoroom"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				Local roomGUID:String = paramS
				Local room:TRoomBase
				If String(Int(roomGUID)) = roomGUID
					room = GetRoomBaseCollection().Get( Int(roomGUID) )
				EndIf
				If Not room
					room = GetRoomBaseCollection().GetByGUID( TLowerString.Create(roomGUID) )
				EndIf
				If Not room
					room = GetRoomBaseCollection().GetFirstByDetails("", roomGUID, player.playerID)
				EndIf
				If room
					DEV_switchRoom(room, player.GetFigure())
				EndIf

			Case "rentroom"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				Local roomGUID:String = paramS
				Local room:TRoomBase
				If String(Int(roomGUID)) = roomGUID
					room = GetRoomBaseCollection().Get( Int(roomGUID) )
				EndIf
				If Not room
					room = GetRoomBaseCollection().GetByGUID( TLowerString.Create(roomGUID) )
				EndIf
				If Not room
					room = GetRoomBaseCollection().GetFirstByDetails("", roomGUID, player.playerID)
				EndIf
				If room
					GetRoomAgency().CancelRoomRental(room, player.playerID)
					GetRoomAgency().BeginRoomRental(room, player.playerID)
					room.SetUsedAsStudio(True)
					GetGame().SendSystemMessage("[DEV] Rented room '" + room.GetDescription() +"' ["+room.GetName() + "] for player '" + player.name +"' ["+player.playerID + "]!")
				Else
					GetGame().SendSystemMessage("[DEV] Cannot rent room '" + roomGUID + "'. Not found!")
				EndIf

			Case "setmasterkey"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				Local bool:Int = Int(paramS)
				DebugScreen.Dev_SetMasterKey(player.playerID, bool)

			Case "reloaddev"
				If FileType("config/DEV.xml") = 1
					Local dataLoader:TDataXmlStorage = New TDataXmlStorage
					Local data:TData = dataLoader.Load("config/DEV.xml")
					If data
						GetRegistry().Set("DEV_CONFIG", data)
						GameRules.devConfig = data
						GameRules.AssignFromData( Gamerules.devConfig )
						GameRules.devConfigBackup = GameRules.devConfig.Copy()

						GetGame().SendSystemMessage("[DEV] Reloaded ~qconfig/DEV.xml~q.")
					Else
						GetGame().SendSystemMessage("[DEV] Failed to reload ~qconfig/DEV.xml~q.")
					EndIf
				Else
					GetGame().SendSystemMessage("[DEV] ~qconfig/DEV.xml~q not found.")
				EndIf

				Local dc:TPlayerDifficultyCollection = GetPlayerDifficultyCollection()
				dc.InitializeDefaults()
				For local pID:Int = 1 to 4
					Local playerDifficulty:TPlayerDifficulty = GetPlayerDifficulty(pID)
					If playerDifficulty
						Local newDifficulty:TPlayerDifficulty = dc.getByGUID(playerDifficulty.GetGUID())
						dc.RemoveByID(playerDifficulty.GetID())
						dc.AddToPlayer(pID, newDifficulty)
					EndIf
				Next
				GetGame().SendSystemMessage("[DEV] Reloaded difficulty values.")

			Case "endauctions"
				Local paramArray:String[]
				If paramS <> "" Then paramArray = playerS.Split(" ")
				If paramArray.length = 0 Or paramArray[0] = "-1" Then paramArray = ["0", "1", "2", "3", "4", "5", "6", "7", "8"]
				For Local indexS:String = EachIn paramArray
					Local block:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks.GetByIndex( Int(indexS)-1 )
					If Not block Then Continue
					Local oldLicence:TProgrammeLicence = block.licence
					Local oldPrice:Int = block.GetNextBidRaw()
					block.EndAuction()

					If Not oldLicence
						GetGame().SendSystemMessage("[DEV] #"+Int(indexS)+". Created new auction '" + block.licence.GetTitle()+"'")
					ElseIf oldLicence <> block.licence And block.licence
						GetGame().SendSystemMessage("[DEV] #"+Int(indexS)+". Ended auction for '" + oldLicence.GetTitle()+"', Created new auction '" + block.licence.GetTitle()+"'")
					ElseIf oldLicence And Not block.licence
						GetGame().SendSystemMessage("[DEV] #"+Int(indexS)+". Ended auction for '" + oldLicence.GetTitle()+"', Created no new auction")
					ElseIf oldLicence = block.licence
						GetGame().SendSystemMessage("[DEV] #"+Int(indexS)+". Reduced auction raw price for '" + oldLicence.GetTitle()+"' from " + MathHelper.DottedValue(oldPrice) + " to " + MathHelper.DottedValue(block.GetNextBidRaw()))
					EndIf
				Next


			Case "sendnews"
				Local newsGUID:String = playerS '(first payload-param)
				Local announceNow:Int = Int(paramS)

				If newsGUID.Trim() = ""
					GetGame().SendSystemMessage("Wrong syntax (/dev help)!")
					Return False
				EndIf

				If newsGUID.Find("devnews") = 0
					'num 1-xxx
					Local num:Int = Max(1, Int(newsGUID.Replace("devnews", "")))
					newsGUID = GameRules.devConfig.GetString("DEV_NEWS_GUID"+num, "")
					If Not newsGUID
						GetGame().SendSystemMessage("Incorrect devnews-syntax (/dev help)!")
						Return False
					EndIf
				EndIf

				'check template first
				Local news:TNewsEvent
				Local template:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByGUID(newsGUID)
				If Not template Then template = GetNewsEventTemplateCollection().SearchByPartialGUID(newsGUID)

				If template
					If template.IsAvailable()
						news = New TNewsEvent.InitFromTemplate(template)
						If news
							GetNewsEventCollection().Add(news)
						EndIf
					Else
						TLogger.Log("DevCheat", "SendNews: news template not available (yet): "+newsGUID, LOG_DEBUG)
						Return False
					EndIf
				Else
					news = GetNewsEventCollection().GetByGUID(newsGUID)
					If Not news Then news = GetNewsEventCollection().SearchByPartialGUID(newsGUID)
				EndIf

				If Not news
					GetGame().SendSystemMessage("No news with GUID ~q"+newsGUID+"~q found.")
					Return False
				EndIf

				'announce that news
				GetNewsAgency().AnnounceNewsEventToPlayers(news, 0, announceNow)
				GetGame().SendSystemMessage("News with GUID ~q"+newsGUID+"~q announced.")

			Case "givelicence"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local licenceGUID:String, hasToPay:String
				FillCommandPayload(paramS, licenceGUID, hasToPay)

				If licenceGUID.Trim() = ""
					GetGame().SendSystemMessage("Wrong syntax (/dev help)!")
					Return False
				EndIf

				If licenceGUID.Find("devlicence") = 0
					'num 1-xxx
					Local num:Int = Max(1, Int(licenceGUID.Replace("devlicence", "")))
					licenceGUID = GameRules.devConfig.GetString("DEV_PROGRAMMELICENCE_GUID"+num, "")
					If Not licenceGUID
						GetGame().SendSystemMessage("Incorrect devlicence-syntax (/dev help)!")
						Return False
					EndIf
				EndIf

				Local licence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(licenceGUID)
				If Not licence Then licence = GetProgrammeLicenceCollection().SearchByPartialGUID(licenceGUID)
				If Not licence
					GetGame().SendSystemMessage("No licence with GUID ~q"+licenceGUID+"~q found.")
					Return False
				EndIf

				'add series not episodes
				If licence.IsEpisode() Then licence = licence.GetParentLicence()
				'add collections, not collection episodes
				If licence.IsCollectionElement() Then licence = licence.GetParentLicence()

				'hand the licence to the player
				If licence.owner <> player.playerID
					If hasToPay = "0" Or hasToPay.ToLower() = "false"
						licence.SetOwner(player.playerID)
					Else
						licence.SetOwner(0)
					EndIf
					'true = skip owner check (needed to be able to skip payment
					RoomHandler_MovieAgency.GetInstance().SellProgrammeLicenceToPlayer(licence, player.playerID, True)
					GetGame().SendSystemMessage("added movie: "+licence.GetTitle()+" ["+licence.GetGUID()+"]")
				Else
					GetGame().SendSystemMessage("already had movie: "+licence.GetTitle()+" ["+licence.GetGUID()+"]")
				EndIf

			Case "givead"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local adGUID:String, checkAvailability:String
				FillCommandPayload(paramS, adGUID, checkAvailability)

				If adGUID.Trim() = ""
					GetGame().SendSystemMessage("Wrong syntax (/dev help)!")
					Return False
				EndIf

				Local adContractBase:TAdContractBase = GetAdContractBaseCollection().GetByGUID(adGUID)
				If Not adContractBase Then adContractBase = GetAdContractBaseCollection().SearchByPartialGUID(adGUID)
				If Not adContractBase
					GetGame().SendSystemMessage("No adcontract with GUID ~q"+adGUID+"~q found.")
					Return False
				EndIf

				If checkAvailability = "0" Or checkAvailability.ToLower() = "false"
					'
				ElseIf Not adContractBase.IsAvailable()
					GetGame().SendSystemMessage("Adcontract with GUID ~q"+adGUID+"~q not available (yet).")
					Return False
				EndIf

				'forcefully add to the collection (skips requirements checks)
				Local adContract:TAdContract = New TAdContract.Create(adContractBase)
				GetPlayerProgrammeCollection(player.playerID).AddAdContract(adContract, True)
				GetGame().SendSystemMessage("added adcontract: "+adContract.GetTitle()+" ["+adContract.GetGUID()+"]")

			Case "givescript"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local scriptGUID:String, hasToPay:String
				FillCommandPayload(paramS, scriptGUID, hasToPay)

				If scriptGUID.Trim() = ""
					GetGame().SendSystemMessage("Wrong syntax (/dev help)!")
					Return False
				EndIf

				Local scriptTemplate:TScriptTemplate = GetScriptTemplateCollection().GetByGUID(scriptGUID)
				If Not scriptTemplate Then scriptTemplate = GetScriptTemplateCollection().SearchByPartialGUID(scriptGUID)
				If Not scriptTemplate
					GetGame().SendSystemMessage("No script template with GUID ~q"+scriptGUID+"~q found.")
					Return False
				EndIf

				'hand the script to the player
				Local script:TScript = GetScriptCollection().GenerateFromTemplate(scriptTemplate)
				If hasToPay = "0" Or hasToPay.ToLower() = "false"
					script.SetOwner(player.playerID)
				Else
					script.SetOwner(0)
				EndIf
				'true = skip owner check (needed to be able to skip payment
				RoomHandler_ScriptAgency.GetInstance().SellScriptToPlayer(script, player.playerID, True)
				GetGame().SendSystemMessage("added script: "+script.GetTitle()+" ["+script.GetScriptTemplate().GetGUID()+"]")

			Case "exec"
				Local fileToLoad:String = payload.Trim()
				If FileType(fileToLoad) = FILETYPE_FILE
					Local content:string = LoadText(fileToLoad)
					For Local line:String = EachIn content.Split(chr(10))
						If line.startsWith("/dev")
							Local event:TEventBase=TEventBase.create("execScript", new TData().add("text", line))
							onChatAddEntry(event)
						End If
					Next
				End If

			Case "help"
				SendHelp()

			Default
				SendHelp()
				'SendSystemMessage("[DEV] unknown command: ~q"+command+"~q")
		End Select

		?not debug
			'dev keys were reactivated
			If GetGame().mission And GameRules.devMode
				Local toast:TGameToastMessage = New TGameToastMessage
				toast.SetLifeTime(10)
				toast.SetMessageType( 1 )
				toast.SetMessageCategory(TVTMessageCategory.MISC)
				toast.SetCaption( GetLocale("MISSION")+": "+GetGame().mission.getTitle() )
				toast.SetText( GetLocale("MISSION_ABORTED"))
				GetToastMessageCollection().AddMessage(toast, "TOPRIGHT")
				GetGame().mission.done()
				GetGame().mission = null
			EndIf
		?

		Function SendHelp()
			GetGame().SendSystemMessage("[DEV] available commands:")
			If GameRules.devMode
				GetGame().SendSystemMessage("|b|money|/b| [player#] [+- money]")
				GetGame().SendSystemMessage("|b|bossmood|/b| [player#] [+- mood %]")
				GetGame().SendSystemMessage("|b|image|/b| [player#] [+- image %]")
				GetGame().SendSystemMessage("|b|endauctions|/b| [-1=all, 1-8=auction#]")
				GetGame().SendSystemMessage("|b|setbankrupt|/b| [player#]")
				GetGame().SendSystemMessage("|b|terrorlvl|/b| [terrorgroup# 0 or 1] [level#]")
				GetGame().SendSystemMessage("|b|givelicence|/b| [player#] [GUID / GUID portion / devlicence#] [oay=1, free=0]")
				GetGame().SendSystemMessage("|b|givescript|/b| [player#] [GUID / GUID portion / devscript#] [pay=1, free=0]")
				GetGame().SendSystemMessage("|b|givead|/b| [player#] [GUID / GUID portion] [checkAvailability=1]")
				GetGame().SendSystemMessage("|b|sendnews|/b| [GUID / GUID portion / devnews#] [now=1, normal=0]")
				GetGame().SendSystemMessage("|b|gotoroom|/b| [roomGUID or roomID]")
				GetGame().SendSystemMessage("|b|rentroom|/b| [roomGUID or roomID]")
				GetGame().SendSystemMessage("|b|setmasterkey|/b| [player#]")
				GetGame().SendSystemMessage("|b|maxaudience|/b|")
				GetGame().SendSystemMessage("|b|commandai|/b| [cmd] [params]")
				GetGame().SendSystemMessage("|b|playerai|/b| [player#] [on=1, off=0]")
				GetGame().SendSystemMessage("|b|loaddb|/b| (dbname)")
				GetGame().SendSystemMessage("|b|exec|/b| (scriptPath)")
			EndIf
			GetGame().SendSystemMessage("|b|reloaddev|/b|")
			GetGame().SendSystemMessage("|b|devkeys|/b| [enable 0 or 1]")
		End Function

		'internal helper function
		Function FillCommandPayload(text:String, command:String Var, payload:String Var)
			Local spacePos:Int = text.Find(" ")
			If spacePos <= 0
				command = text
				payload = ""
			Else
				command = Left(text, spacePos)
				payload = Right(text, text.length - (spacePos+1))
			EndIf
		End Function
	End Function


	Function PlayersOnRealTimeSecond:Int(triggerEvent:TEventBase)
		'only AI handling: only gameleader interested
		If Not GetGame().isGameLeader() Then Return False

		'wait for all to have nothing to do
		If TAIBase.airunning and GameRules.devConfig.GetBool("DEV_SYNC_AI_ON_TIME")	
			Local allReady:Int
			Repeat
				allReady = True
				For Local player:TPLayer = EachIn GetPlayerCollection().players
					If player.isLocalAI() and player.playerAI.GetNextEventCount() > 0
						'print "SYNCWAIT. RTSEC. P" + player.playerID +"  EventQueue: "  + player.PlayerAI.GetNextEventCount() + " (sync=" + player.playerAI.GetNextToSynchronizeEventCount() + ")   Events: last=" + player.playerAI.GetLastEventID() + "/" + TAIEvent.GetNameByID(player.playerAI.GetLastEventID())+"/"+player.playerAI.GetLastEventTime()+"ms  curr=" + player.playerAI.GetCurrentEventID() + "/" + TAIEvent.GetNameByID(player.playerAI.GetCurrentEventID())+"/"+player.playerAI.GetCurrentEventTime()+"ms" + "  next=" + player.playerAI.GetNextEventID() + "/" + TAIEvent.GetNameByID(player.playerAI.GetNextEventID()) + "   " + GetWorldTime().GetFormattedGameDate()

						allReady = False
						exit
					EndIf
				Next
				'if not allReady then Delay(1)
			Until allReady
		EndIf

		'real time when event is created
		Local realTime:Long = Time.GetTimeGone()
		'milliseconds passed since last RealTimeSecond-event
		'value could fit into an integer but for now we keep it as Long
		Local timeGoneSinceLastRTS:Long = triggerEvent.GetData().GetLong("timeGoneSinceLastRTS", 0)
		'time in game now
		Local gameTime:Long = triggerEvent.GetData().GetLong("gameTimeGone", 0)

		'print "playersOnRealTimeSecond:  gameTime="+GetWorldTime().GetFormattedGameDate(gameTime) + "    " + gameTime + " =============================="
		Local localAIPlayerCount:Int
		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isLocalAI()
				localAIPlayerCount :+ 1

				TProfiler.Enter(_profilerKey_AI_SECOND[player.playerID-1], False)
				player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnRealtimeSecondTick).SetToSynchronize().AddLong(realTime).AddLong(gameTime))
				player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnRealTimeSecond).AddLong(realTime).AddLong(timeGoneSinceLastRTS))
				'player.PlayerAI.ConditionalCallOnTick()
				'player.PlayerAI.CallOnRealtimeSecond(timeGone)
				TProfiler.Leave(_profilerKey_AI_SECOND[player.playerID-1], 100, False)
			EndIf
		Next

		'when activating: ensure that all AI players receive hat realtimeSecondTick!
		'if some AI takes longer than the others and so somehow extends "realtime second ticks"...
rem		
		If localAIPlayerCount > 0 And GameRules.devConfig.GetBool("DEV_SYNC_AI_ON_TIME")	
			Local allReady:Int = True
			Local highestCount:Int
			Repeat
				highestCount = 0
				allReady = True

				For Local player:TPLayer = EachIn GetPlayerCollection().players
					If player.isLocalAI() Then highestCount = Max(highestCount, player.PlayerAI.realTimeSecondTicks)
				Next
				For Local player:TPLayer = EachIn GetPlayerCollection().players
					If player.isLocalAI() 
						if player.PlayerAI.realTimeSecondTicks < highestCount
							'print "MIN waiting for " + player.playerID + "  realTimeSecondTicks: " + player.playerAI.realTimeSecondTicks + "/" + highestCount + "  nextEventCount: " + player.PlayerAI.GetNextEventCount()			
							allReady = False
						'Else
						'	print "MIN " + player.playerID + " ready.  realTimeSecondTicks: " + player.playerAI.realTimeSecondTicks + "/" + highestCount + "  nextEventCount: " + player.PlayerAI.GetNextEventCount()			
						EndIf
					EndIf
				Next
				If not allReady Then Delay(1)
			Until allReady
		EndIf
endrem		
		Return True
	End Function


	Function DevAddToastMessage:Int(triggerEvent:TEventBase)
		Local caption:String = triggerEvent.GetData().GetString("caption")
		Local text:String = triggerEvent.GetData().GetString("text")
		Local messageType:Int = triggerEvent.GetData().GetInt("type", 1) '1 = attention
		Local lifetime:Int = triggerEvent.GetData().GetInt("lifetime", 5)

		Local toast:TGameToastMessage = New TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(lifetime)
		toast.SetMessageType( messageType )
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetCaption( caption )
		toast.SetText( text )

		GetToastMessageCollection().AddMessage(toast, "TOPRIGHT")
	End Function


	Function PlayersOnMinute:Int(triggerEvent:TEventBase)
		If Not GetGame().isGameLeader() Then Return False

		'wait for all to have nothing to do
		If TAIBase.airunning and GameRules.devConfig.GetBool("DEV_SYNC_AI_ON_TIME")	
			Local allReady:Int
			Repeat
				allReady = True
				For Local player:TPLayer = EachIn GetPlayerCollection().players
					If player.isLocalAI() and player.playerAI.GetNextEventCount() > 0
						'print "SYNCWAIT. MIN. P" + player.playerID +"  EventQueue: "  + player.PlayerAI.GetNextEventCount() + " (sync=" + player.playerAI.GetNextToSynchronizeEventCount() + ")   Events: last=" + player.playerAI.GetLastEventID() + "/" + TAIEvent.GetNameByID(player.playerAI.GetLastEventID())+"/"+player.playerAI.GetLastEventTime()+"ms  curr=" + player.playerAI.GetCurrentEventID() + "/" + TAIEvent.GetNameByID(player.playerAI.GetCurrentEventID())+"/"+player.playerAI.GetCurrentEventTime()+"ms" + "  next=" + player.playerAI.GetNextEventID() + "/" + TAIEvent.GetNameByID(player.playerAI.GetNextEventID()) + "   " + GetWorldTime().GetFormattedGameDate()

						allReady = False
						exit
					EndIf
				Next
'				if not allReady then Delay(1)
			Until allReady
		EndIf


		'real time when event is created
		Local realTime:Long = Time.GetTimeGone()
		'time in game now
		Local gameTime:Long = triggerEvent.GetData().GetLong("time",-1)
		Local minuteOfHour:Int = GetWorldTime().GetDayMinute(gameTime)
		If minuteOfHour < 0 Then Return False

		'print "playersOnMinute:  gameTime="+GetWorldTime().GetFormattedGameDate(gameTime) + "    " + gameTime + " =============================="
		Local localAIPlayerCount:Int
		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isLocalAI()
				localAIPlayerCount :+ 1
				TProfiler.Enter(TDebugScreenPage_Overview._profilerKey_AI_MINUTE[player.playerID-1], False)
				player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnTick).SetToSynchronize().AddLong(realTime).AddLong(gameTime) )
				player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnMinute).AddInt(minuteOfHour) )
				TProfiler.Leave(TDebugScreenPage_Overview._profilerKey_AI_MINUTE[player.playerID-1], 100, False)
			EndIf
		Next

rem
		If localAIPlayerCount > 0 And GameRules.devConfig.GetBool("DEV_SYNC_AI_ON_TIME")	
			Local allReady:Int = True
			Local highestCount:Int
			Repeat
				highestCount = 0
				allReady = True

				For Local player:TPLayer = EachIn GetPlayerCollection().players
					If player.isLocalAI() Then highestCount = Max(highestCount, player.PlayerAI.ticks)
				Next
				For Local player:TPLayer = EachIn GetPlayerCollection().players
					If player.isLocalAI() 
						If player.PlayerAI.ticks < highestCount
							'print "MIN waiting for " + player.playerID + "  ticks: " + player.playerAI.ticks + "/" + highestCount + "  nextEventCount: " + player.PlayerAI.GetNextEventCount()			
							allReady = False
						'Else
							'print "MIN " + player.playerID + " ready.  ticks: " + player.playerAI.ticks + "/" + highestCount + "  nextEventCount: " + player.PlayerAI.GetNextEventCount()			
						EndIf
					EndIf
				Next
				If not allReady Then Delay(1)
			Until allReady
		EndIf
endrem
		Return True
	End Function


	Function PlayersOnDay:Int(triggerEvent:TEventBase)
		If Not GetGame().isGameLeader() Then Return False

		'time in game now
		Local gameTime:Long = triggerEvent.GetData().GetLong("time",-1)
		Local minuteOfHour:Int = GetWorldTime().GetDayMinute(gameTime)
		If minuteOfHour < 0 Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isLocalAI()
				player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnDayBegins))
				'player.PlayerAI.CallOnDayBegins()
			EndIf
		Next
		Return True
	End Function


	Function PlayersOnBeginGame:Int(triggerEvent:TEventBase)
		If Not GetGame().isGameLeader() Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isLocalAI()
				player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnGameBegins))
				'player.PlayerAI.CallOnGameBegins()
			EndIf
		Next
		Return True
	End Function



	Function PlayerOnSetBankrupt:Int(triggerEvent:TEventBase)
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())


		Local toast:TGameToastMessage = New TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(10)
		toast.SetMessageType(1) 'attention
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetCaption(GetLocale("PLAYER_WENT_BANKRUPT"))

		Local t:String
		t :+ GetRandomLocale("PLAYER_X_FROM_CHANNEL_Y_WENT_BANKRUPT").Replace("%X%", "|b|"+player.name+"|/b|").Replace("%Y%", "|b|"+player.channelName+"|/b|")
		t :+ " "
		If Not player.isHuman()
			t :+ GetLocale("PLAYER_WILL_START_AGAIN")
		Else
			t :+ GetLocale("AI_WILL_TAKE_OVER_THIS_PLAYER")
		EndIf
		toast.SetText(t)

		toast.GetData().AddNumber("playerID", player.playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interest in other players
		If Not player.IsLocalHuman()
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf

		'ensure new color for room signs
		For Local door:TRoomDoor = EachIn GetRoomDoorCollection().list
			door._lastOwner = 1000
		Next
	End Function


	Function PlayerBroadcastMalfunction:Int(triggerEvent:TEventBase)
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		Local player:TPlayer = GetPlayerCollection().Get(playerID)
		If Not player Then Return False

		If player.isLocalAI()
			player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnMalfunction))
			'player.playerAI.CallOnMalfunction()
		EndIf
	End Function


	Function PlayerFinanceOnChangeMoney:Int(triggerEvent:TEventBase)
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		If playerID = 0 Then Return False
		Local player:TPlayer = GetPlayerCollection().Get(playerID)
		If Not player Then Return False
		Local value:Long = triggerEvent.GetData().GetLong("value", 0)
		Local reason:Int = triggerEvent.GetData().GetInt("reason", 0)
		Local reference:TNamedGameObject = TNamedGameObject(triggerEvent.GetData().Get("reference", Null))

		If player.isLocalAI()
			player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnMoneyChanged).AddLong(value).AddInt(reason).AddData(reference))
			'player.playerAI.CallOnMoneyChanged(value, reason, reference)
		EndIf
		If player.isActivePlayer() Then GetInGameInterface().ValuesChanged = True
		
		Return True
	End Function


	'show an error if a transaction was not possible
	Function PlayerFinanceOnTransactionFailed:Int(triggerEvent:TEventBase)
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		If playerID = 0 Then Return False
		Local player:TPlayer = GetPlayerCollection().Get(playerID)
		If Not player Then Return False

		'create an visual error
		If player.isActivePlayer() And Not player.IsLocalAI() Then TError.CreateNotEnoughMoneyError()

		Return True
	End Function


	Function PlayerBoss_OnCallPlayerForced:Int(triggerEvent:TEventBase)
		Local latestTime:Long = triggerEvent.GetData().GetLong("latestTime", Long(GetWorldTime().GetTimeGone() + 2 * TWorldTime.HOURLENGTH))
		Local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		If player.isLocalAI()
			player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnBossCallsForced))
			'player.playerAI.CallOnBossCallsForced()
		EndIf
		'send player to boss now
		player.SendToBoss()
	End Function


	Function PlayerBoss_OnPlayerEnterBossRoom:Int(triggerEvent:TEventBase)
		Local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())
		'only interested in the real player
		If Not player Or Not player.isActivePlayer() Then Return False

		'remove potentially existing toastmessages
		Local toastGUID:String = "toastmessage-playerboss-callplayer"+player.playerID
		Local toast:TToastMessage = GetToastMessageCollection().GetMessageByGUID(toastGUID)
		GetToastMessageCollection().RemoveMessage( toast )
	End Function


	Function PlayerBoss_OnCallPlayer:Int(triggerEvent:TEventBase)
		Local latestTime:Long = triggerEvent.GetData().GetLong("latestTime", Long(GetWorldTime().GetTimeGone() + 2 * TWorldTime.HOURLENGTH))
		Local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai about the request
		If player.isLocalAI()
			player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnBossCalls).AddLong(latestTime))
			'player.playerAI.CallOnBossCalls(latestTime)
		Else
			'send out a toast message
			Local toastGUID:String = "toastmessage-playerboss-callplayer"+player.playerID
			'try to fetch an existing one
			Local toast:TGameToastMessage = TGameToastMessage(GetToastMessageCollection().GetMessageByGUID(toastGUID))
			If Not toast Then toast = New TGameToastMessage

			'until 2 hours
			toast.SetCloseAtWorldTime(latestTime)
			toast.SetCloseAtWorldTimeText("MESSAGE_CLOSES_AT_TIME")
			toast.SetMessageType(1)
			toast.SetMessageCategory(TVTMessageCategory.MISC)
			toast.SetPriority(10)

			toast.SetCaption(GetLocale("YOUR_BOSS_WANTS_TO_SEE_YOU"))
			toast.SetText(GetLocale("YOU_HAVE_GOT_X_HOURS_TO_VISIT_HIM").Replace("%HOURS%", 2))
			toast.SetClickText("|i|"+GetLocale("CLICK_HERE_TO_START_YOUR_VISIT_AHEAD_OF_TIME") + "|/i|")
			toast.SetOnCloseFunction(PlayerBoss_onClosePlayerCallMessage)
			toast.GetData().Add("boss", boss)
			toast.GetData().Add("player", player)
			toast.GetData().AddNumber("playerID", player.playerID)

			'if this was a new message, the guid will differ
			If toast.GetGUID() <> toastGUID
				toast.SetGUID(toastGUID)
				'new messages get added to a list
				GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
			EndIf
		EndIf
	End Function


	'if a player clicks on the toastmessage calling him, he will get
	'sent to the boss in that moment
	Function PlayerBoss_onClosePlayerCallMessage:Int(sender:TToastMessage)
		Local boss:TPlayerBoss = TPlayerBoss(sender.GetData().get("boss"))
		Local player:TPlayer = TPlayer(sender.GetData().get("player"))
		If Not boss Or Not player Then Return False

		player.SendToBoss()
	End Function


	Function PlayerBoss_OnTakeOrRepayCredit:Int(triggerEvent:TEventBase)
		'only show toast message on success
		Local success:Int = triggerEvent.GetData().GetBool("result", False)
		If Not success Then Return False

		Local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		If Not boss Then Return False


		Local value:Int = triggerEvent.GetData().GetInt("value", 0)
		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage

		'show it for some seconds
		toast.SetLifeTime(3)
		toast.SetMessageCategory(TVTMessageCategory.MONEY)

		If triggerEvent.GetEventKey() = GameEventKeys.PlayerBoss_OnPlayerTakesCredit
			toast.SetMessageType(2) 'positive
			toast.SetCaption(StringHelper.UCFirst(GetLocale("CREDIT_TAKEN")))
			toast.SetText(StringHelper.UCFirst(GetLocale("ACCOUNT_BALANCE"))+": |b||color=0,125,0|+ "+ GetFormattedCurrency(value) + "|/color||/b|")
		Else
			toast.SetMessageType(3) 'negative
			toast.SetCaption(StringHelper.UCFirst(GetLocale("CREDIT_REPAID")))
			toast.SetText(StringHelper.UCFirst(GetLocale("ACCOUNT_BALANCE"))+": |b||color=125,0,0|- "+ GetFormattedCurrency(value) + "|/color||/b|")
		EndIf

		'play a special sound instead of the default one
		toast.GetData().AddString("onAddMessageSFX", "positiveMoneyChange")
		toast.GetData().AddNumber("playerID", boss.playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interest in active player's boss-credit-actions
		If boss.playerID = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function PublicAuthorities_onStopXRatedBroadcast:Int(triggerEvent:TEventBase)
		Local programme:TProgramme = TProgramme(triggerEvent.GetSender())
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		If player.isLocalAI()
			player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnPublicAuthoritiesStopXRatedBroadcast))
			'player.playerAI.CallOnPublicAuthoritiesStopXRatedBroadcast()
		EndIf

		Local penalty:int = triggerEvent.getData().getInt("penalty")

		Local toast:TGameToastMessage = New TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(15)
		toast.SetMessageType(1) 'attention
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetCaption(GetLocale("AUTHORITIES_STOPPED_BROADCAST"))
		toast.SetText( ..
			GetLocale("BROADCAST_OF_XRATED_PROGRAMME_X_NOT_ALLOWED_DURING_DAYTIME").Replace("%TITLE%", "|b|"+programme.GetTitle()+"|/b|") + " " + ..
			GetLocale("PENALTY_OF_X_WAS_PAID").Replace("%MONEY%", "|b|"+GetFormattedCurrency(penalty)+"|/b|") ..
		)
		toast.GetData().AddNumber("playerID", programme.owner)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interest in active player's licences
		If programme.owner = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function PublicAuthorities_onConfiscateProgrammeLicence:Int(triggerEvent:TEventBase)
		Local targetProgrammeLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID( triggerEvent.GetData().GetString("targetProgrammeGUID") )
		Local confiscatedProgrammeLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID( triggerEvent.GetData().GetString("confiscatedProgrammeGUID") )
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		If player.isLocalAI()
			player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnPublicAuthoritiesConfiscateProgrammeLicence).AddData(confiscatedProgrammeLicence).AddData(targetProgrammeLicence))
			'player.playerAI.CallOnPublicAuthoritiesConfiscateProgrammeLicence(confiscatedProgrammeLicence, targetProgrammeLicence)
		EndIf

		Local toast:TGameToastMessage = New TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(15)
		toast.SetMessageType(1) 'attention
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetCaption(GetLocale("AUTHORITIES_CONFISCATED_LICENCE"))
		Local text:String = GetLocale("PROGRAMMELICENCE_X_GOT_CONFISCATED").Replace("%TITLE%", "|b|"+confiscatedProgrammeLicence.GetTitle()+"|/b|") + " "
		If confiscatedProgrammeLicence <> targetProgrammeLicence
			text :+ GetLocale("SEEMS_AUTHORITIES_VISITED_THE_WRONG_ROOM")
		Else
			text :+ GetLocale("BETTER_WATCH_OUT_NEXT_TIME")
		EndIf

		toast.SetText(text)
		toast.GetData().AddNumber("playerID", player.playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interest in active player's licences
		If confiscatedProgrammeLicence.owner = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function Achievement_OnComplete:Int(triggerEvent:TEventBase)
		Local achievement:TAchievement = TAchievement(triggerEvent.GetSender())
		If Not achievement Then Return False

		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		If Not GetPlayerCollection().IsPlayer(playerID) Then Return False

		Local player:TPlayer = GetPlayer(playerID)
		If Not player Then Return False


		'inform ai
		If player.isLocalAI()
			player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnAchievementcompleted).AddData(achievement))
			'player.playerAI.CallOnAchievementCompleted(achievement)
		EndIf


		Local rewardText:String
		For Local i:Int = 0 Until achievement.GetRewards().length
			If rewardText <> "" Then rewardText :+ "~n"
			rewardText :+ Chr(9654) + " " +achievement.GetRewards()[i].GetTitle()
		Next

		Rem
			TODO: Bilder fuer toastmessages (+ Pokal)
			 _________
			|[ ] text |
			|    text |
			'---------'
		endrem
		Local text:String = GetLocale("YOU_JUST_COMPLETED_ACHIEVEMENTTITLE").Replace("%ACHIEVEMENTTITLE%", "|b|"+achievement.GetTitle()+"|/b|")
		If rewardText
			text :+ "~n|b|" + GetLocale("REWARD") + ":|/b|~n" + rewardText
		EndIf


		Local toast:TGameToastMessage = New TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(15)
		toast.SetMessageType(2) 'positive
		toast.SetMessageCategory(TVTMessageCategory.ACHIEVEMENTS)
		toast.SetCaption(GetLocale("ACHIEVEMENT_COMPLETED"))
		toast.SetText( text )

		toast.GetData().AddNumber("playerID", player.playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interest in active player
		If player = GetPlayer()
			GetToastMessageCollection().AddMessage(toast, "TOPRIGHT")
		EndIf
	End Function

	Function Mission_OnAchieve:Int(triggerEvent:TEventBase)
		Local mission:TMission=TMission(triggerEvent.GetSender())
		If mission And mission = GetGame().mission
			Local messageSuffix:String = triggerEvent.GetData().getString("text","")
			GetGame().SetGameSpeedPreset(0)

			Local toast:TGameToastMessage = New TGameToastMessage
			toast.SetLifeTime(20)
			toast.SetMessageType( 1 )
			toast.SetMessageCategory(TVTMessageCategory.MISC)
			Local hurray:String =""
			Local score:TMissionHighscore = TMissionHighscore(triggerEvent.GetData().get("highscore"))
			If score
				If score.primaryPlayer = score.winningPlayer 
					hurray = GetRandomLocale2(["MISSION_SUCCESS_TEXT"])+ " "
				Else
					messageSuffix:+ ("~n"+GetRandomLocale2(["MISSION_END_NEUTRAL"]))
				EndIf
			EndIf
			toast.SetCaption( GetLocale("MISSION_SUCCESS").replace("%HURRAY%", hurray).replace("%GOAL%", mission.getTitle()) )
			toast.SetText( "("+GetLocale("MISSION")+": "+mission.GetDescription()+")" + messageSuffix)
			GetToastMessageCollection().AddMessage(toast, "TOPRIGHT")
			'TODO show highscore window + continuing the game possible?
			GetGame().mission.done()
			GetGame().mission = null
		EndIf
	End Function

	Function Mission_OnFail:Int(triggerEvent:TEventBase)
		Local mission:TMission=TMission(triggerEvent.GetSender())
		If mission And mission = GetGame().mission
			Local messageSuffix:String  = triggerEvent.GetData().getString("text","")
			GetGame().SetGameOver()
			'TODO continuing the game possible?
			GetPlayer().GetFigure()._controllable = False
			GetGame().SetGameSpeedPreset(0)

			Local toast:TGameToastMessage = New TGameToastMessage
			toast.SetLifeTime(20)
			toast.SetMessageType( 1 )
			toast.SetMessageCategory(TVTMessageCategory.MISC)
			toast.SetCaption( GetLocale("MISSION_FAILED").replace("%GOAL%", mission.getTitle()) )
			toast.SetText( "("+GetLocale("MISSION")+": "+mission.GetDescription()+")" + messageSuffix )
			GetToastMessageCollection().AddMessage(toast, "TOPRIGHT")
			GetGame().mission.done()
			GetGame().mission = null
			'TODO show highscore window + continuing the game possible?
		EndIf
	End Function

	Function Award_OnFinish:Int(triggerEvent:TEventBase)
		Local award:TAward = TAward(triggerEvent.GetSender())
		If Not award Then Return False

		Local winningPlayerID:Int = triggerEvent.GetData().GetInt("winningPlayerID", 0)
		Local rewardText:String = award.GetRewardText()
		Local winnerName:String
		Local winningPlayer:TPlayer

		If winningPlayerID = 0
			'sammy not awarded
		ElseIf Not GetPlayerCollection().IsPlayer(winningPlayerID) 
			Return False
		Else
			winningPlayer:TPlayer = GetPlayer(winningPlayerID)
		EndIf

		If winningPlayer
			winnerName:String = winningPlayer.name
			'inform ai
			If winningPlayer.isLocalAI()
				winningPlayer.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnWonAward).AddData(award))
				'winningPlayer.playerAI.CallOnWonAward(award)
			EndIf
		EndIf

		'inform all players about a won award (even if another player was the winner)
		For Local i:Int = 1 To 4
			Local caption:String
			Local text:String
			If winningPlayer
				caption = GetLocale("AWARD_WON")
				'current player won and it is his loop cycle?
				If i = winningPlayerID and i = GetPlayer().playerID
					text = GetLocale("YOU_WON_THE_AWARDNAME").Replace("%AWARDNAME%", "|b|"+award.GetTitle()+"|/b|")
				Else
					Local col:TColor = winningPlayer.color
					text = GetLocale("PLAYERNAME_WON_THE_AWARDNAME").Replace("%PLAYERNAME%", "|b||color="+col.r+","+col.g+","+col.b+"|"+Chr(9632)+"|/color|"+winnerName+"|color="+col.r+","+col.g+","+col.b+"|"+Chr(9632)+"|/color||/b|").Replace("%AWARDNAME%", "|b|"+award.GetTitle()+"|/b|")
				EndIf

				If rewardText
					text :+ "~n|b|" + GetLocale("REWARD") + ":|/b|~n" + rewardText
				EndIf
			Else
				caption = award.GetTitle()
				text = GetLocale("NOBODY_WON_THE_AWARDNAME")
			EndIf

			Local toast:TGameToastMessage = New TGameToastMessage
			'show it for some seconds
			toast.SetLifeTime(15)
			toast.SetMessageType(2) 'positive
			toast.SetCaption(caption)
			toast.SetMessageCategory(TVTMessageCategory.AWARDS)
			toast.SetText( text )

			toast.GetData().AddInt("playerID", i)

			'archive it for all players
			GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )

			If i = GetPlayer().playerID
				GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
			EndIf
		Next
	End Function


	Function Room_OnBombExplosion:Int(triggerEvent:TEventBase)
		'ensure janitor will reset signs when next visiting the roomboard
		Local janitor:TFigureJanitor = TFigureJanitor(TFigureCollection.GetInstance().GetByName("Hausmeister"))
		If janitor
			janitor.LastRoomBoardSignResetDay = -1
		EndIf

		Local currentPlayer:int = GetPlayerBase().playerID

		'=== SEND TOASTMESSAGE ===
		'local roomGUID:string = triggerEvent.GetData().GetString("roomGUID")
		'local room:TRoomBase = GetRoomCollection().GetByGUID( TLowerString.Create(roomGUID) )
		Local room:TRoomBase = TRoomBase( triggerEvent.GetSender() )
		If room
			Local caption:String = GetRandomLocale("BOMB_DETONATION_IN_TVTOWER")
			Local text:String = GetRandomLocale("TOASTMESSAGE_BOMB_DETONATION_IN_TVTOWER_TEXT")

			'replace placeholders
			If room.owner > 0
				Local player:TPlayer = GetPlayer(room.owner)
				Local col:TColor = player.color
				text = text.Replace("%ROOM%", "|b||color="+col.r+","+col.g+","+col.b+"|"+Chr(9632)+"|/color|"+room.GetDescription(1, False)+"|/b||color="+col.r+","+col.g+","+col.b+"|"+Chr(9632)+"|/color|")
			Else
				text = text.Replace("%ROOM%", "|b|"+room.GetDescription(1, True)+"|/b|")
			EndIf


			For Local i:Int = 1 To 4
				Local toast:TGameToastMessage = New TGameToastMessage
				'show it for some seconds
				toast.SetLifeTime(15)
				toast.SetMessageType(1) 'attention
				toast.SetMessageCategory(TVTMessageCategory.MISC)

				toast.SetCaption( caption )
				If i = room.owner
					Local player:TPlayer = GetPlayer(room.owner)
					If room.GetNameRaw() = "news"
						player.getProgrammePlan().RemoveNewsBySlot(0)
						player.getProgrammePlan().RemoveNewsBySlot(1)
						player.getProgrammePlan().RemoveNewsBySlot(2)
					EndIf
					Local cost:Int = triggerEvent.GetData().GetInt("renovationBaseCost")
					If cost > 0
						cost = TFunctions.RoundToBeautifulValue(cost * 1.2^ (player.GetChannelReachLevel()-1))
						If i = currentPlayer Then text:+ " "+ GetRandomLocale("TOASTMESSAGE_BOMB_RENOVATION_COST_TEXT").Replace("%COST%", GetFormattedCurrency(cost))
						player.GetFinance().PayMisc(cost)
					EndIf
					If room.GetNameRaw() = "archive"
						Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(room.owner)
						Local licence:TProgrammeLicence = programmeCollection.GetRandomProgrammeLicence()
						If licence and licence.getSubLicenceCount() = 0 and licence.IsTradeable()
							If programmeCollection.RemoveProgrammeLicence(licence)
								If i = currentPlayer Then text:+ "~n"+ GetRandomLocale("TOASTMESSAGE_BOMB_LICENCE_DESTROYED_TEXT").Replace("%TITLE%", licence.GetTitle())
							EndIf
						EndIf
					EndIf
					'destroying a single production concept or licence in an unblocked studio works
					'the interesting case of a production in progress is not yet handled (terrorist does not enter the room)
					If room.IsUsedAsStudio()
						Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(room.owner)
						For Local script:TScript = EachIn programmeCollection.studioScripts
							If room.GetId() = RoomHandler_Studio.GetInstance().GetStudioIDByScript(script)
								Local concepts:TProductionConcept[] = TProductionConceptCollection.GetInstance().GetProductionConceptsByScript(script)
								If concepts And concepts.length > 0
									Local concept:TProductionConcept = concepts[RandRange(0,concepts.length-1)]
									If programmeCollection.DestroyProductionConcept(concept)
										If i = currentPlayer Then text:+ "~n"+ GetRandomLocale("TOASTMESSAGE_BOMB_CONCEPT_DESTROYED_TEXT")
									EndIf
								Else
									If programmeCollection.RemoveScript(script)
										If i = currentPlayer Then text:+ "~n"+ GetRandomLocale("TOASTMESSAGE_BOMB_LICENCE_DESTROYED_TEXT").Replace("%TITLE%", script.GetTitle())
									EndIf
								EndIf
							EndIf
						Next
					EndIf
				EndIf
				toast.SetText( text )

				toast.GetData().AddNumber("playerID", i)


				GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


				'only add if it is the active player
				If i = currentPlayer
					GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
				EndIf
			Next
		EndIf
	End Function


	Function ProgrammeLicenceAuction_OnGetOutbid:Int(triggerEvent:TEventBase)
		'only interested in auctions in which the player got overbid
		Local previousBestBidder:Int = triggerEvent.GetData().GetInt("previousBestBidder")

		Local licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().Get("licence"))
		Local bestBidder:Int = triggerEvent.GetData().GetInt("bestBidder")
		Local bestBid:Int = triggerEvent.GetData().GetInt("bestBidder")
		Local previousBestBid:Int = triggerEvent.GetData().GetInt("previousBestBid")
		If Not licence Or Not GetPlayer(bestBidder) Then Return False


		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage

		'show it for some seconds
		toast.SetLifeTime(6)
		toast.SetMessageType(1) 'attention
		toast.SetCaption(GetLocale("YOU_HAVE_BEEN_OUTBID"))
		toast.SetMessageCategory(TVTMessageCategory.MONEY)

		toast.SetText( ..
			GetLocale("SOMEONE_BID_MORE_THAN_YOU_FOR_X").Replace("%TITLE%", licence.GetTitle()) + " " + ..
			GetLocale("YOUR_PREVIOUS_BID_OF_X_WAS_REFUNDED").Replace("%MONEY%", "|b|"+GetFormattedCurrency(previousBestBid)+"|/b|") ..
		)
		'play a special sound instead of the default one
		toast.GetData().AddString("onAddMessageSFX", "positiveMoneyChange")

		toast.GetData().AddNumber("playerID", previousBestBidder)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If previousBestBidder = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function ProgrammeLicenceAuction_OnWin:Int(triggerEvent:TEventBase)
		'only interested in auctions the player won
		Local bestBidder:Int = triggerEvent.GetData().GetInt("bestBidder")

		Local licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().Get("licence"))
		Local bestBid:Int = triggerEvent.GetData().GetInt("bestBidder")
		If Not licence Or Not GetPlayer(bestBidder) Then Return False


		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage

		'show it for some seconds
		toast.SetLifeTime(8)
		toast.SetMessageType(2) 'positive
		toast.SetMessageCategory(TVTMessageCategory.MONEY)
		toast.SetCaption(GetLocale("YOU_HAVE_WON_AN_AUCTION"))
		toast.SetText(GetLocale("THE_LICENCE_OF_X_IS_NOW_AT_YOUR_DISPOSAL").Replace("%TITLE%", "|b|"+licence.GetTitle()+"|/b|"))

		toast.GetData().AddNumber("playerID", bestBidder)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If bestBidder = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function Production_OnFinalize:Int(triggerEvent:TEventBase)
		'only interested in auctions the player won
		Local production:TProduction = TProduction(triggerEvent.GetSender())
		If Not production Then Return False

		'skip adding the toast message at all when already paid and just
		'finishing the live broadcast of it now
		'just comment out this portion to create a toastmessage for it too
		If GameRules.payLiveProductionInAdvance and production.productionConcept.script.IsLive()
			Return False
		EndIf


		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
		Local title:String = production.productionConcept.GetTitle()
		If production.productionConcept.script.GetEpisodeNumber() > 0
			title = production.productionConcept.script.GetParentScript().GetTitle() + ": "
			title :+ production.productionConcept.script.GetEpisodeNumber() + "/" + production.productionConcept.script.GetParentScript().GetSubScriptCount()+" "
			title :+ production.productionConcept.GetTitle()
		EndIf

		'show it for some seconds
		toast.SetLifeTime(8)
		toast.SetMessageType(2) 'positive
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		If production.productionConcept.script.IsLive()
			'maybe have a different caption too?
			'toast.SetCaption(GetLocale("LIVE_SHOOTING_FINISHED"))
			toast.SetCaption(GetLocale("SHOOTING_FINISHED"))
			If GameRules.payLiveProductionInAdvance
				toast.SetText(GetLocale("THE_LIVE_PRODUCTION_OF_X_JUST_FINISHED").Replace("%TITLE%", "|b|"+title+"|/b|"))
			Else
				toast.SetText((GetLocale("THE_LIVE_PRODUCTION_OF_X_JUST_FINISHED") + "~n" + GetLocale("TOTAL_PRODUCTION_COSTS_WERE_X")).Replace("%TITLE%", "|b|"+title+"|/b|").Replace("%TOTALCOST%", "|b|" + GetFormattedCurrency(production.productionConcept.GetTotalCost()) + "|/b|" ))
			EndIf
		Else
			toast.SetCaption(GetLocale("SHOOTING_FINISHED"))
			toast.SetText((GetLocale("THE_LICENCE_OF_X_IS_NOW_AT_YOUR_DISPOSAL") + "~n" + GetLocale("TOTAL_PRODUCTION_COSTS_WERE_X")).Replace("%TITLE%", "|b|"+title+"|/b|").Replace("%TOTALCOST%", "|b|" + GetFormattedCurrency(production.productionConcept.GetTotalCost()) + "|/b|" ))
		EndIf

		toast.GetData().AddNumber("playerID", production.owner)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If production.owner = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function Production_OnFinishPreProduction:Int(triggerEvent:TEventBase)
		'only interested in auctions the player won
		Local production:TProduction = TProduction(triggerEvent.GetSender())
		If Not production Then Return False


		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
		Local title:String = production.productionConcept.GetTitle()
		If production.productionConcept.script.GetEpisodeNumber() > 0
			title = production.productionConcept.script.GetParentScript().GetTitle() + ": "
			title :+ production.productionConcept.script.GetEpisodeNumber() + "/" + production.productionConcept.script.GetParentScript().GetSubScriptCount()+" "
			title :+ production.productionConcept.GetTitle()
		EndIf

		'show it for some seconds
		toast.SetLifeTime(8)
		toast.SetMessageType(2) 'positive
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetCaption(GetLocale("PREPRODUCTION_FINISHED"))
		If GameRules.payLiveProductionInAdvance
			toast.SetText((GetLocale("THE_LICENCE_OF_X_IS_NOW_AT_YOUR_DISPOSAL") + "~n" + GetLocale("TOTAL_PRODUCTION_COSTS_WERE_X")).Replace("%TITLE%", "|b|"+title+"|/b|").Replace("%TOTALCOST%", "|b|" + GetFormattedCurrency(production.productionConcept.GetTotalCost()) + "|/b|" ))
		Else
			toast.SetText(GetLocale("THE_LICENCE_OF_X_IS_NOW_AT_YOUR_DISPOSAL").Replace("%TITLE%", "|b|"+title+"|/b|"))
		EndIf

		toast.GetData().AddNumber("playerID", production.owner)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If production.owner = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function

	Function Game_OnSetPlayerBankruptLevel:Int(triggerEvent:TEventBase)
		'only interested in levels of the player
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", -1)

		'only interested in the first two days (afterwards player is
		'already gameover)
		If GetGame().GetPlayerBankruptLevel(playerID) > 2 Then Return False

		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
		Local text:String
		If GetGame().GetPlayerBankruptLevel(playerID) = 0
			'show it for some seconds
			toast.SetLifeTime(8)
			toast.SetMessageType(2) 'positive
			text =  GetLocale("YOUR_BALANCE_IS_POSITIVE_AGAIN")
			text :+ "~n"
			text :+ "|color=0,125,0|"+GetLocale("YOU_ARE_NO_LONGER_IN_DANGER_TO_GET_FIRED")+"|/color|"
		ElseIf GetGame().GetPlayerBankruptLevel(playerID) = 1
			'show it for some seconds
			toast.SetLifeTime(8)
			toast.SetMessageType(3) 'warning
			text =  GetLocale("YOUR_BALANCE_IS_NEGATIVE")
			text :+ "~n"
			text :+ GetLocale("YOU_HAVE_X_DAYS_TO_GET_INTO_THE_BLACK").Replace("%DAYS%", 2+GetLocale("DAYS"))
			text :+ "~n"
			text :+ "|color=125,0,0|"+GetLocale("YOU_ARE_IN_DANGER_TO_GET_FIRED")+"|/color|"
		Else
			'make this message a bit more sticky
			Local midnight:Long = GetWorldTime().GetTimeGoneForGameTime(0, GetWorldTime().GetDay(), 23, 59, 59)

			toast.SetCloseAtWorldTime(midnight)
			toast.SetCloseAtWorldTimeText("MESSAGE_CLOSES_AT_TIME")
			'show it for a very long time, but keep it closeable
			toast.SetLifeTime(30)
			toast.SetPriority(10)

			toast.SetMessageType(1) 'negative
			text =  GetLocale("YOUR_BALANCE_IS_NEGATIVE")
			text :+ "~n"
			text :+ GetLocale("YOU_HAVE_ONLY_TODAY_TO_GET_INTO_THE_BLACK")
			text :+ "~n"
			text :+ "|color=125,0,0|"+GetLocale("YOU_ARE_IN_DANGER_TO_GET_FIRED")+"|/color|"
		EndIf
		toast.SetText(text)

		toast.SetCaption(GetLocale("ACCOUNT_BALANCE"))

		toast.SetMessageCategory(TVTMessageCategory.MONEY)

		toast.GetData().AddNumber("playerID", playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If playerID = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function AdContract_OnFinish:Int(triggerEvent:TEventBase)
		Local contract:TAdContract = TAdContract(triggerEvent.GetSender())
		If Not contract Then Return False


		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage

		'show it for some seconds
		toast.SetLifeTime(8)
		toast.SetMessageType(2) 'positive
		toast.SetMessageCategory(TVTMessageCategory.MONEY)
		toast.SetCaption(GetLocale("ADCONTRACT_FINISHED"))
		toast.SetText( ..
			GetLocale("ADCONTRACT_X_SUCCESSFULLY_FINISHED").Replace("%TITLE%", contract.GetTitle()) + " " + ..
			GetLocale("PROFIT_OF_X_GOT_CREDITED").Replace("%MONEY%", "|b|"+GetFormattedCurrency(contract.GetProfit())+"|/b|") ..
		)
		'play a special sound instead of the default one
		toast.GetData().AddString("onAddMessageSFX", "positiveMoneyChange")

		toast.GetData().AddNumber("playerID", contract.owner)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If contract.owner = GetPlayerCollection().playerID And Not GameConfig.highSpeedObservation
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function AdContract_OnFail:Int(triggerEvent:TEventBase)
		Local contract:TAdContract = TAdContract(triggerEvent.GetSender())
		If Not contract Then Return False


		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage

		'show it for some more seconds
		toast.SetLifeTime(12)
		toast.SetMessageType(3) 'negative
		toast.SetMessageCategory(TVTMessageCategory.MONEY)
		toast.SetCaption(GetLocale("ADCONTRACT_FAILED"))
		toast.SetText( ..
			GetLocale("ADCONTRACT_X_FAILED").Replace("%TITLE%", contract.GetTitle()) + " " + ..
			GetLocale("PENALTY_OF_X_WAS_PAID").Replace("%MONEY%", "|b|"+GetFormattedCurrency(contract.GetPenalty())+"|/b|") ..
		)

		toast.GetData().AddNumber("playerID", contract.owner)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If contract.owner = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	'called each time a room (the active player visits) is updated
	Function RoomOnUpdate:Int(triggerEvent:TEventBase)

		If Not GetPlayer().GetFigure().IsChangingRoom()
			'handle right click
			If MOUSEMANAGER.IsClicked(2)
				'check subrooms
				'only leave a room if not in a subscreen
				'if in subscreen, go to parent one
				If ScreenCollection.GetCurrentScreen().parentScreen
					ScreenCollection.GoToParentScreen()

					'handled clicks
					MouseManager.SetClickHandled(2)
				Else
					'leaving allowed - reset button
					If GetPlayer().GetFigure().LeaveRoom()
						'handled clicks
						MouseManager.SetClickHandled(2)
					EndIf
				EndIf
			EndIf
		EndIf
	End Function


	Function StationMap_OnRemoveStation:Int(triggerEvent:TEventBase)
		Local stationMap:TStationMap = TStationMap(triggerEvent.GetSender())
		If Not stationMap Then Return False

		Local player:TPlayer = GetPlayerCollection().Get(stationMap.owner)
		If Not player Then Return False

		TLogger.Log("StationMap_OnRemoveStation", "recomputing audience for player "+player.playerID, LOG_DEBUG)
		GetBroadcastManager().ReComputePlayerAudience(player.playerID)
	End Function


	Function StationMap_OnAddStation:Int(triggerEvent:TEventBase)
		Local stationMap:TStationMap = TStationMap(triggerEvent.GetSender())
		If Not stationMap Then Return False

		Local station:TStationBase = TStationBase(triggerEvent.GetData().Get("station"))
		If Not station Then Return False

		'only interested in the players stations
		Local player:TPlayer = GetPlayer(stationMap.owner)
		If Not player Then Return False

		'in the past?
		If station.GetActivationTime() < GetWorldTime().GetTimeGone() Then Return False



		Local readyTime:String = GetWorldTime().GetFormattedTime(station.GetActivationTime())
		Local closeText:String = "MESSAGE_CLOSES_AT_TIME"
		Local readyText:String = "NEW_STATION_WILL_BE_READY_AT_TIME_X"
		'prepend day if it does not finish today
		If GetWorldTime().GetDay() < GetWorldTime().GetDay(station.GetActivationTime())
			readyTime = GetWorldTime().GetFormattedDay(GetWorldTime().GetDaysRun(station.GetActivationTime()) +1) + " " + readyTime
			closeText = "MESSAGE_CLOSES_AT_DAY"
			readyText = "NEW_STATION_WILL_BE_READY_AT_DAY_X"
		EndIf

		'send out a toast message

		'show only one message of this type?
		'Local toastGUID:String = "toastmessage-stationmap-addstation"+player.playerID
		'try to fetch an existing one
		'Local toast:TGameToastMessage = TGameToastMessage(GetToastMessageCollection().GetMessageByGUID(toastGUID))
		'If Not toast Then toast = New TGameToastMessage

		Local toast:TGameToastMessage = New TGameToastMessage

		toast.SetCloseAtWorldTime( station.GetActivationTime() )
		toast.SetCloseAtWorldTimeText(closeText)
		toast.SetLifeTime(6)
		toast.SetMessageType(0)
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetPriority(2)

		toast.SetCaption( GetLocale("X_UNDER_CONSTRUCTION").Replace("%X%", station.GetTypeName()) )
		toast.SetText( GetLocale(readyText).Replace("%TIME%", readyTime) )

		toast.GetData().AddNumber("playerID", player.playerID)

		Rem - if only 1 instance allowed
		'if this was a new message, the guid will differ
		If toast.GetGUID() <> toastGUID
			toast.SetGUID(toastGUID)
			'new messages get added to a list
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
		endrem



		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If player = GetPlayer()
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function StationMap_OnChangeReachLevel:Int(triggerEvent:TEventBase)
		Local stationMap:TStationMap = TStationMap(triggerEvent.GetSender())
		If Not stationMap Then Return False

		Local reachLevel:Int = triggerEvent.GetData().GetInt("reachLevel")
		Local oldReachLevel:Int = triggerEvent.GetData().GetInt("oldReachLevel")

		'only interested in the players stations
		Local player:TPlayer = GetPlayer(stationMap.owner)
		If Not player Then Return False

		Local caption:String
		Local text:String
		Local text2:String

		If reachLevel > oldReachLevel
			caption = "AUDIENCE_REACH_LEVEL_INCREASED"
			text = "LEVEL_INCREASED_FROM_X_TO_Y"
			text2 = "PRICES_WILL_RISE"
		Else
			caption = "AUDIENCE_REACH_LEVEL_DECREASED"
			text = "LEVEL_DECREASED_FROM_X_TO_Y"
			text2 = "PRICES_WILL_FALL"
		EndIf

		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
		toast.SetLifeTime(6)
		toast.SetMessageType(0)
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetPriority(2)

		toast.SetCaption( GetLocale(caption) )

		Local textJoined:String = GetLocale(text2)
		If textJoined
			textJoined = GetLocale(text) + " " + textJoined
		Else
			textJoined = GetLocale(text)
		EndIf
		toast.SetText( textJoined.Replace("%X%", "|b|"+oldReachLevel+"|/b|").Replace("%Y%", "|b|"+reachLevel+"|/b|") )

		toast.GetData().AddNumber("playerID", player.playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )

		'only interested in active player
		If player = GetPlayer()
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
	End Function


	Function StationMap_OnTrySellLastStation:Int(triggerEvent:TEventBase)
		Local stationMap:TStationMap = TStationMap(triggerEvent.GetSender())
		If Not stationMap Then Return False

		Local player:TPlayer = GetPlayerCollection().Get(stationMap.owner)
		If Not player Then Return False

		'create an visual error
		If player.isActivePlayer() Then TError.Create( getLocale("ERROR_NOT_POSSIBLE"), getLocale("ERROR_NOT_ABLE_TO_SELL_LAST_STATION") )
	End Function


	Function Station_OnContractEndsSoon:Int(triggerEvent:TEventBase)
		Local station:TStationBase = TStationBase(triggerEvent.GetSender())
		If Not station Then Return False

		'only interested in the players stations
		If GetPlayer().playerID <> station.owner Then Return False

		'in the past?
		If station.GetSubscriptionTimeLeft() < 0 Then Return False

		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage

		'toast.SetCloseAtWorldTime( station.GetActivationTime() )
		'toast.SetCloseAtWorldTimeText(closeText)
		toast.SetLifeTime(6)
		toast.SetMessageType(3) 'attention
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetPriority(2)

		toast.SetCaption( GetLocale("CONTRACT_ENDS_SOON") )

		Local subscriptionEndTime:Long = station.GetProvider().GetSubscribedChannelEndTime(station.owner)
		Local t:String
		If TStationCableNetworkUplink(station)
			t = "CABLE_NETWORK_UPLINK_CONTRACT_WITH_COMPANYX_WILL_END_AT_TIMEX_DAYX"
		ElseIf TStationSatelliteUplink(station)
			t = "SATELLITE_UPLINK_CONTRACT_WITH_COMPANYX_WILL_END_AT_TIMEX_DAYX"
		EndIf
		t = GetLocale(t)
		t = t.Replace("%COMPANYX%", station.GetProvider().GetName())
		t = t.Replace("%TIMEX%", GetWorldTime().GetFormattedTime(subscriptionEndTime) )
		If GetWorldTime().GetDay() = GetWorldTime().GetDay(subscriptionEndTime)
			t = t.Replace("%DAYX%", GetLocale("TODAY") )
		ElseIf GetWorldTime().GetDay() + 1 = GetWorldTime().GetDay(subscriptionEndTime)
			t = t.Replace("%DAYX%", GetLocale("TOMORROW") )
		Else
			'(currently not used - notification only one day in advance)
			t = t.Replace("%DAYX%", GetLocale("GAMEDAY") + " " +(GetWorldTime().GetDaysRun(subscriptionEndTime)+1))
		EndIf

		toast.SetText( t )
		toast.GetData().AddNumber("playerID", station.owner)

		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )

		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function


	Function OnMinute:Int(triggerEvent:TEventBase)
		Local now:Long = triggerEvent.GetData().GetLong("time",-1)
		Local minute:Int = GetWorldTime().GetDayMinute(now)
		Local hour:Int = GetWorldTime().GetDayHour(now)
		Local day:Int = GetWorldTime().GetDay(now)
		If hour = -1 Then Return False

		'=== UPDATE GAME MODIFIERS ===
		GetGameModifierManager().Update()


		'=== UPDATE POPULARITY MANAGER ===
		'the popularity manager takes care itself whether to do something
		'or not (update intervals)
		GetPopularityManager().Update(triggerEvent)


		'=== UPDATE SPORTS ===
		'this collection contains sports emitting news events to
		'the news agency (but also for live-programme-creation)
		GetNewsEventSportCollection().UpdateAll()


		'=== UPDATE NEWS AGENCY ===
		'check if it is time for new news
		GetNewsAgency().Update()


		'=== UPDATE STUDIOS ===
		'check if new productions finished (0:00, 0:05, ...)
		If minute Mod 5 = 0
			GetProductionManager().Update()
		EndIf


		'=== CHANGE OFFER OF MOVIEAGENCY AND ADAGENCY ===
		'countdown for the refillers
		Local game:TGame = GetGame()
		game.refillMovieAgencyTime :-1
		game.refillAdAgencyTime :-1
		game.refillScriptAgencyTime :-1
		'refill if needed
		If game.refillMovieAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("", "movieagency").hasOccupant()
				game.refillMovieAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				If GetWorldTime().GetDaysRun() > 0
					game.refillMovieAgencyTime = GameRules.refillMovieAgencyTimer + randrange(0,20)-10
				Else
					game.refillMovieAgencyTime = 90 + randrange(0,20)-10
				EndIf

				TLogger.Log("GameEvents.OnMinute", "partly refilling movieagency (" + GetWorldTime().GetFormattedGameDate() + ")", LOG_DEBUG)
				'Local t:Long = Time.MillisecsLong()
				RoomHandler_movieagency.GetInstance().ReFillBlocks(True, 0.5)
				'TLogger.Log("GameEvents.OnMinute", "... took " + (Time.MillisecsLong() - t)+"ms", LOG_DEBUG)
			EndIf
		EndIf
		If game.refillScriptAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("", "scriptagency").hasOccupant()
				game.refillScriptAgencyTime :+ 15
			Else
				'fix old savegames with "-1" values
				If GameRules.refillScriptAgencyTimer < 0 Then GameRules.refillScriptAgencyTimer = 180
				'reset but with a bit randomness
				game.refillScriptAgencyTime = GameRules.refillScriptAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling scriptagency (" + GetWorldTime().GetFormattedGameDate() + ")", LOG_DEBUG)
				'Local t:Long = Time.MillisecsLong()
				RoomHandler_scriptagency.GetInstance().WriteNewScripts()
				RoomHandler_scriptagency.GetInstance().ReFillBlocks(True, 0.65)
				'TLogger.Log("GameEvents.OnMinute", "... took " + (Time.MillisecsLong() - t)+"ms", LOG_DEBUG)
			EndIf
		EndIf
		If game.refillAdAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("", "adagency").hasOccupant()
				game.refillAdAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				game.refillAdAgencyTime = GameRules.refillAdAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling adagency (" + GetWorldTime().GetFormattedGameDate() + ")", LOG_DEBUG)
				'Local t:Long = Time.MillisecsLong()
				If GetGameBase().refillAdAgencyOverridePercentage <> GameRules.refillAdAgencyPercentage
					RoomHandler_adagency.GetInstance().ReFillBlocks(True, GetGameBase().refillAdAgencyOverridePercentage)
					GetGameBase().refillAdAgencyOverridePercentage = GameRules.refillAdAgencyPercentage
				Else
					RoomHandler_adagency.GetInstance().ReFillBlocks(True, GameRules.refillAdAgencyPercentage)
				EndIf
				'TLogger.Log("GameEvents.OnMinute", "... took " + (Time.MillisecsLong() - t)+"ms", LOG_DEBUG)
			EndIf
		EndIf


		'=== REFRESH INTERFACE IF NEEDED ===
		If minute = 5 Or minute = 55 Or minute = 0 Then GetInGameInterface().ValuesChanged = True


		'=== UPDATE STATIONMAPS ===
		'checks for newly activated stations (which start to broadcast
		'then, not earlier). This avoids getting an audience recalculation
		'after the removal of a station - while other stations were
		'bought AFTER the audience got calculated (aka "cheating").
		GetStationMapCollection().Update()


		'=== ADJUST CURRENT BROADCASTS ===
		'check if an unproduced live programme is to get aired (live shooting)
		'ensures quality data is calculated in time
		If minute = 5
			For Local player:TPlayer = EachIn GetPlayerCollection().players
				Local programme:TProgramme = TProgramme(player.GetProgrammePlan().GetProgramme(day, hour))
				'If player.GetProgrammePlan().GetProgrammeBlock(day, hour) = 1
				If programme and programme.data.IsLive() and programme.programmedHour <= hour 'block 1
					'try to find an still to shoot production
					local production:TProduction = GetProductionManager().GetLiveProductionByProgrammeLicenceID(programme.licence.GetID())
					'preproduction is done else it would not be "programmeable"
					'so simply check if production is finished
					if production and not production.IsProduced() 
						'only start it once
						if not production.IsShooting()
							GetProductionManager().StartLiveProductionInStudio(production.GetID())
						EndIf
					EndIf
				EndIf
			Next
		EndIf

		'broadcasts change at xx:00, xx:05, xx:55
		If minute = 5 Or minute = 55 Or minute = 0
			Local broadcastMaterial:TBroadcastMaterial

			'step 1/2
			'log in current broadcasted media
			For Local player:TPlayer = EachIn GetPlayerCollection().players
				broadcastMaterial = player.GetProgrammePlan().LogInCurrentBroadcast(day, hour, minute)
			Next

			'step 2/2
			'calculate audience
			TPlayerProgrammePlan.CalculateCurrentBroadcastAudience(day, hour, minute)
		EndIf


		'=== CHECK FOR X-RATED PROGRAMME ===
		'calculate each hour if not or when the current broadcasts are
		'checked for XRated.
		'do this to create some tension :p
		If minute = 0 Then GetGame().ComputeNextXRatedCheckMinute()

		'time to check for Xrated programme?
		If minute = GetGame().GetNextXRatedCheckMinute()
			'only check between 6:00-21:59 o'clock (there it is NOT allowed)
			If hour <= 21 And hour >= 6
				Local currentProgramme:TProgramme
				For Local player:TPlayer = EachIn GetPlayerCollection().players
					currentProgramme = TProgramme(player.GetProgrammePlan().GetProgramme(day, hour))
					'skip non-programme broadcasts or malfunction
					If Not currentProgramme Then Continue
					'skip "normal" programme
					If Not currentProgramme.data.IsXRated() Then Continue
					Local penalty:Int = player.GetDifficulty().sentXRatedPenalty
					'pay penalty
					player.GetFinance().PayMisc(penalty)
					'remove programme from plan
					player.GetProgrammePlan().ForceRemoveProgramme(currentProgramme, day, hour)
					'set current broadcast to malfunction
					GetBroadcastManager().SetBroadcastMalfunction(player.playerID, TVTBroadcastMaterialType.PROGRAMME)
					'decrease image by 0.5%
					player.GetPublicImage().ChangeImage(New SAudience(-0.5, -0.5))

					'chance that the programme will get (tried) to get confiscated
					Local confiscateProgramme:Int = RandRange(1,100) <= player.GetDifficulty().sentXRatedConfiscateRisk

					If confiscateProgramme
						TriggerBaseEvent(GameEventKeys.PublicAuthorities_OnStartConfiscateProgramme, New TData.AddString("broadcastMaterialGUID", currentProgramme.GetGUID()).AddNumber("owner", player.playerID), currentProgramme, player)

						'Send out first marshal - Mr. Czwink or Mr. Czwank
						TFigureMarshal(GetGame().marshals[randRange(0,1)]).AddConfiscationJob(currentProgramme.licence.GetGUID())
					EndIf

					'emit event (eg.for ingame toastmessages)
					TriggerBaseEvent(GameEventKeys.PublicAuthorities_OnStopXRatedBroadcast, New TData.AddInt("penalty", penalty), currentProgramme, player)
				Next
			EndIf
		EndIf


		'=== INFORM BROADCASTS ===
		'inform about broadcasts starting / ending
		'-> earn call-in profit
		'-> cut topicality
		If (minute = 5 Or minute = 55 Or minute = 0) Or ..
		   (minute = 4 Or minute = 54 Or minute = 59)

			'send out an event for "block types" to begin/finish now
			'this enables to run things before manipulation like
			'topicality decrease takes place
			Local evKey:TEventKey
			Local evData:TData
			Select minute
				Case 0
					evKey = GameEventKeys.Broadcasting_BeforeStartAllNewsShowBroadcasts
					evData = New TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.NEWSSHOW) )
				Case 4
					evKey = GameEventKeys.Broadcasting_BeforeFinishAllNewsShowBroadcasts
					evData = New TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.NEWSSHOW) )
				Case 5
					evKey = GameEventKeys.Broadcasting_BeforeStartAllProgrammeBlockBroadcasts
					evData = New TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.PROGRAMME) )
				Case 54
					evKey = GameEventKeys.Broadcasting_BeforeFinishAllProgrammeBlockBroadcasts
					evData = New TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.PROGRAMME) )
				Case 55
					evKey = GameEventKeys.Broadcasting_BeforeStartAllAdBlockBroadcasts
					evData = New TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.ADVERTISEMENT) )
				Case 59
					evKey = GameEventKeys.Broadcasting_BeforeFinishAllAdBlockBroadcasts
					evData = New TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.ADVERTISEMENT) )
			End Select
			If evKey And evData
				TriggerBaseEvent(evKey, evData)
			EndIf


			'shuffle players, so each time another plan is informed the
			'first (and their "doBegin" is called earlier than others)
			'this is useful for "who broadcasted a news as first channel?"
			'things.
			Local players:TPlayerBase[] = GetPlayerCollection().players[ .. ]
			For Local a:Int = 0 To players.length - 2
				Local b:Int = RandRange( a, players.length - 1)
				Local p:TPlayerBase = players[a]
				players[a] = players[b]
				players[b] = p
			Next


			For Local player:TPlayer = EachIn players
				player.GetProgrammePlan().InformCurrentBroadcast(day, hour, minute)
			Next


			evKey = Null
			Select minute
				Case 0
					evKey = GameEventKeys.Broadcasting_AfterStartAllNewsShowBroadcasts
				Case 4
					evKey = GameEventKeys.Broadcasting_AfterFinishAllNewsShowBroadcasts
				Case 5
					evKey = GameEventKeys.Broadcasting_AfterStartAllProgrammeBlockBroadcasts
				Case 54
					evKey = GameEventKeys.Broadcasting_AfterFinishAllProgrammeBlockBroadcasts
				Case 55
					evKey = GameEventKeys.Broadcasting_AfterStartAllAdBlockBroadcasts
				Case 59
					evKey = GameEventKeys.Broadcasting_AfterFinishAllAdBlockBroadcasts
			End Select
			If evKey And evData
				TriggerBaseEvent(evKey, evData)
			EndIf
		EndIf


		'=== UPDATE LIVE PROGRAMME ===
		'(do that AFTER setting the broadcasts, so the programme data
		' knows whether it is broadcasted currently or not)
		'1) call data.update()
		'2) remove LIVE-status from programmes once they finished airing
		If minute Mod 5 = 0
			GetProgrammeDataCollection().UpdateLive()
		EndIf

		'=== UPDATE DYNAMIC DATA PROGRAMME ===
		'(do that AFTER setting the broadcasts, so the programme data
		' knows whether it is broadcasted currently or not)
		'Calls UpdateDynamicData() of the programme so it could adjust
		'values like description, title or other values
		'Example: programme data for the "header" of soccer leagues could
		'         tell about "live on tape" or "currently run" matches
		If minute Mod 5 = 0 'minute = 5 or minute = 55
			GetProgrammeDataCollection().UpdateDynamicData()
		EndIf

		'=== UPDATE Players' news max Level ===
		'it is determined as a side-effect of the getter
		If minute Mod 5 = 0
			For Local player:TPlayer = EachIn GetPlayerCollection().players
				For Local genre:Int = 0 To TVTNewsGenre.count
					player.GetNewsAbonnementDaysMax(genre)
				Next
			Next
		EndIf

		'=== UPDATE ACHIEVEMENTS ===
		'(do that AFTER setting the broadcasts and calculating the
		' audience as some achievements check audience of a broadcast)
		GetAchievementCollection().Update(now)
		
		
		'=== UPDATE PROGRAMME PRODUCERS ===
		If minute Mod 15 = 0 'every 15 minutes
			GetProgrammeProducerCollection().UpdateAll()
		EndIf

		'=== UPDATE AWARDS / SAMMYS ===
		'ensure awards finish on the correct day (usually 23:59); ending an award on the next day could cause
		'fail of mission possible although the award is won/wrong award count
		If minute = 59 Then GetAwardCollection().UpdateAwards()

		If TSaveGame.autoSaveNow and Not GetPlayer().GetFigure().IsInRoom()
			Local gameName:String = GameConfig.savegame_lastUsedName
			Local autoSaveName:String = "autosave"
			If gameName and gameName <> "quicksave" and not gameName.endsWith("_autosave")
				autoSaveName = gameName + "_autosave"
			EndIf
			Local autoSaveURI:String = TSavegame.GetSavegameURI(autoSaveName)
			TSaveGame.PrepareAutoSave(autoSaveURI)
			TSaveGame.autoSaveNow = False
		EndIf


		Return True
	End Function


	'things happening each hour
	Function OnHour:Int(triggerEvent:TEventBase)
		Local time:Long = triggerEvent.GetData().GetLong("time",-1)
		Local day:Int = GetWorldTime().GetDay(time)
		Local hour:Int = GetWorldTime().GetHour(time)

		'=== UPDATE WORLD / WEATHER AUDIENCE MODIFIERS ===
		GetGame().UpdateBaseGameModifiers()

		'=== HANDLE EMPTY ROOMS ===
		'let previous renter take back their rooms (if nobody wanted the
		'studio after a specific waiting time)
		GetRoomAgency().UpdateEmptyRooms()


		'=== REMOVE ENDED NEWSEVENTS  ===
		'newsevents might have a "happenedEndTime" indicating that
		'the event is only a temporary one (eg. storm warning)

		'remove such events when they get invalid
		'remove from players
		For Local pBase:TPlayerBase = EachIn GetPlayerBaseCollection().players
			Local p:TPlayer = TPlayer(pBase)
			If Not p Then Continue

			'COLLECTION
			'loop through a copy to avoid concurrent modification
			For Local news:TNews = EachIn p.GetProgrammeCollection().news.Copy()
				Local ne:TNewsEvent = news.GetNewsEvent()
				If ne.HasHappened() And ne.HasEnded()
					p.GetProgrammeCollection().RemoveNews(news)
				EndIf
			Next

			'PLAN
			'do not remove from plan
			Rem
			'no need to copy the array because it has a fixed length
			For Local news:TNews = EachIn p.GetProgrammePlan().news
				If news.newsEvent.HasHappened() and news.newsEvent.HasEnded()
					p.GetProgrammePlan().RemoveNews(news.GetGUID(),-1,False)
				EndIf
			Next
			endrem


			'=== REMOVE OLD NEWS AND NEWSEVENTS ===
			'news and newsevents both have a "happenedTime" but they must
			'not be the same (multiple news with the same event but happened
			'to different times)
			Local hoursToKeep:Int
			Local minTopicalityToKeep:Float

			'remove old news from the all player plans and collections
			For Local pBase:TPlayerBase = EachIn GetPlayerBaseCollection().players
				Local p:TPlayer = TPlayer(pBase)
				If Not p Then Continue

				'COLLECTION
				'news could stay there for 1.5 days (including today)
				hoursToKeep = 36

				'loop through a copy to avoid concurrent modification
				For Local news:TNews = EachIn p.GetProgrammeCollection().news.Copy()
					'if paid for the news, keep it a bit longer
					If news.IsPaid()
						minTopicalityToKeep = 0.04
					Else
						minTopicalityToKeep = 0.012
					EndIf
					If hour - GetWorldTime().GetHour(news.GetHappenedTime()) > hoursToKeep
						p.GetProgrammeCollection().RemoveNews(news)
					ElseIf news.GetNewsEvent().GetTopicality() < minTopicalityToKeep
						p.GetProgrammeCollection().RemoveNews(news)
					EndIf
				Next

				'PLAN
				'news could get send a bit longer
				hoursToKeep = 48
				'minTopicalityToKeep = 0.01
				'no need to copy the array because it has a fixed length
				For Local news:TNews = EachIn p.GetProgrammePlan().news
					If hour - GetWorldTime().GetHour(news.GetHappenedTime()) > hoursToKeep
						p.GetProgrammePlan().RemoveNewsByGUID(news.GetGUID(), False)
					'elseif news.newsevent.GetTopicality() < minTopicalityToKeep
					'	p.GetProgrammePlan().RemoveNewsByGUID(news.GetGUID(), False)
					EndIf
				Next
			Next

		Next
		'NEWSEVENTS
		'remove old news events - wait a bit more than "plan time"
		'this also gets rid of "one time" news events which should
		'have been "triggered" then
		Local daysToKeep:Int = 3
		GetNewsEventCollection().RemoveOutdatedNewsEvents(daysToKeep)
		'remove from collection (reuse if possible)
		GetNewsEventCollection().RemoveEndedNewsEvents()

		If GameConfig.autoSaveIntervalHours > 0 And Not TSaveGame.autoSaveNow and TSaveGame.lastSaveTime > 0 and time - TSaveGame.lastSaveTime > GameConfig.autoSaveIntervalHours * TWorldTime.HOURLENGTH
			TSaveGame.autoSaveNow = True
		EndIf
	End Function


	Function OnDay:Int(triggerEvent:TEventBase)
		Local time:Long = triggerEvent.GetData().GetLong("time",-1)
		Local day:Int = GetWorldTime().GetDay(time)

		TLogger.Log("GameEvents.OnDay", "begin of day "+(GetWorldTime().GetDaysRun()+1)+" (real day: "+day+")", LOG_DEBUG)

		'finish upcoming programmes (set them to cinema, released...)
		GetProgrammeDataCollection().UpdateUnreleased()

		'if new day, not start day
		If GetWorldTime().GetDaysRun(time) >= 1
			GetProgrammeDataCollection().RefreshTopicalities()
			GetAdContractBaseCollection().RefreshInfomercialTopicalities()

			TAuctionProgrammeBlocks.EndAllAuctions() 'won auctions moved to programmecollection of player
			If GetWorldTime().GetDayOfYear(time) = 1
				TAuctionProgrammeBlocks.RefillAuctionsWithoutBid()
			EndIf


			Rem
			'Ronny: should not be needed

			'fix old savegames with broken finances (existing finances of
			'bankrupt players at incorrect array indices)
			'attention:: make sure that GetDaysRun() is >= 1
			For Local Player:TPlayer = EachIn GetPlayerCollection().players
				local oldFinance:TPlayerFinance = GetPlayerFinance(player.playerID, day-1)
				local oldMoney:Long = oldFinance.GetMoney()
				local finance:TPlayerFinance = GetPlayerFinance(player.playerID, day)
				'take over money, credit ... and reset rest
				finance.TakeOverFrom(oldFinance)
				print Player.playerID+") TakeOverMoney:  money "+ oldMoney +" -> "+finance.GetMoney() +"  now: " + GetPlayerFinance(player.playerID, day).GetMoney()
			Next
			print "---------------------"
			endrem


			'pay for contracts we did not fulfill
			GetGame().ComputeContractPenalties(day)
			'first pay everything ...
			GetGame().ComputeDailyCosts(day)
			'then earn... (avoid wrong balance interest)
			GetGame().ComputeDailyIncome(day)

			'archive player image of that day
			GetPublicImageCollection().ArchiveImages()
			'archive pressure group sympathies of that day
			GetPressureGroupCollection().ArchiveSympathies()

			'Check if a player goes bankrupt now
			GetGame().UpdatePlayerBankruptLevel()


			'remove no longer needed DailyBroadcastStatistics
			'by default we store maximally one week
			Local statisticDaysToKeep:Int = 7 '4 * GetWorldTime()._daysPerSeason
			GetDailyBroadcastStatisticCollection().RemoveBeforeDay( day - statisticDaysToKeep )
			'history for single transactions of office's financial screen can be shorter
			statisticDaysToKeep = 2
			GetPlayerFinanceHistoryListCollection().RemoveBeforeTime(time - statisticDaysToKeep * TWorldTime.DAYLENGTH)


			'force adagency to refill their sortiment a bit more intensive
			'the next time
			'GameRules.refillAdAgencyTime = -1
			GetGameBase().refillAdAgencyOverridePercentage = 0.75


			'TODO: give image points or something like it for best programme
			'of day?!
			Local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic( day - 1 )
			If stat And stat.bestBroadcast
				Local audience:String = ""
				If stat.bestAudienceResult Then audience = Long(stat.bestAudienceResult.audience.GetTotalSum())+", player: "+stat.bestBroadcast.owner
				TLogger.Log("OnDay", "BestBroadcast: "+stat.bestBroadcast.GetTitle() + " (audience: "+audience+")", LOG_INFO)
			Else
				If stat
					TLogger.Log("OnDay", "BestBroadcast: No best broadcast found for today", LOG_INFO)
				Else
					TLogger.Log("OnDay", "GetDailyBroadcastStatistic() failed - nothing available for that day", LOG_DEBUG)
				EndIf
			EndIf


			'=== PRINT OUT FINANCIAL STATS ===

			For Local playerID:Int = 1 To 4
				Local text:String[] = TDebugScreenPage_Misc.GetInstance().GetPlayerFinanceOverviewText(playerID, day - 1)
				For Local s:String = EachIn text
					TLogger.Log("OnDay Financials", s, LOG_DEBUG)
				Next
			Next
		EndIf

		'=== UPDATE AWARDS / SAMMYS ===
		'in particular start award on the beginning of the day
		'otherwise it might start 00:59 and and at that time on the next day...
		GetAwardCollection().UpdateAwards()

		Return True
	End Function
End Type




Type AppEvents
	Global InitDone:Int=False
	Global SimpleSoundSource:TSimpleSoundSource = New TSimpleSoundSource

	Function Init:Int()
		If InitDone Then Return True

		EventManager.registerListenerFunction(GUIEventKeys.GUIModalWindow_OnClose, onGuiModalWindowClose)
		EventManager.registerListenerFunction(GUIEventKeys.GUIModalWindowChain_OnClose, onGuiModalWindowClose)
		EventManager.registerListenerFunction(GUIEventKeys.GUIModalWindow_OnOpen, onGuiModalWindowCreate)
		EventManager.registerListenerFunction(GUIEventKeys.GUIModalWindowChain_OnOpen, onGuiModalWindowCreate)
		EventManager.registerListenerFunction(TToastMessageCollection.eventKey_ToastMessageCollection_onAddMessage, onToastMessageCollectionAddMessage)
		EventManager.registerListenerFunction(GameEventKeys.App_OnStart, onAppStart)
'		EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onMouseOverGUIObject)

	End Function
rem
	Function onMouseOverGUIObject:Int(triggerEvent:TEventBase)
		Local obj:TGUIObject = TGUIObject(triggerEvent.GetSender())
		If Not obj Then Return False

		'SetCursor() only replaces the previous cursor if none was
		'set since begin of "game loop Update()" - use ", true" to force
		'replacement
		If obj.isDragged() 
			GetGameBase().SetCursor( TGameBase.CURSOR_HOLD )
		ElseIf obj.isDragable() 
			GetGameBase().SetCursor( TGameBase.CURSOR_INTERACT )
		EndIf
	End Function
endrem

	Function onGuiModalWindowClose:Int(triggerEvent:TEventBase)
		'play a sound with the default sfxchannel
		SimpleSoundSource.PlayRandomSfx("gui_close_fade_window")
	End Function


	Function onGuiModalWindowCreate:Int(triggerEvent:TEventBase)
		'play a sound with the default sfxchannel
		SimpleSoundSource.PlayRandomSfx("gui_open_window")
	End Function


	Function onToastMessageCollectionAddMessage:Int(triggerEvent:TEventBase)
		Local toastMessage:TToastMessage = TToastMessage(triggerEvent.GetReceiver())
		If Not toastMessage Then Return False

		Local sfx:String = toastMessage.getData().getString("onAddMessageSFX")
		If sfx = "" Then sfx = "gui_open_window"

		'play a random sound of the given playlist with the default sfxchannel
		SimpleSoundSource.PlayRandomSfx(sfx)
	End Function


	'App is ready ...
	'- create special fonts
	Function onAppStart:Int(triggerEvent:TEventBase)
		If Not headerFont
			GetBitmapFontManager().Add("headerFont", "res/fonts/sourcesans/SourceSansPro-Semibold.ttf", 18)
			GetBitmapFontManager().Add("headerFont", "res/fonts/sourcesans/SourceSansPro-Bold.ttf", 18, BOLDFONT)
			GetBitmapFontManager().Add("headerFont", "res/fonts/sourcesans/SourceSansPro-BoldIt.ttf", 18, BOLDFONT | ITALICFONT)
			GetBitmapFontManager().Add("headerFont", "res/fonts/sourcesans/SourceSansPro-It.ttf", 18, ITALICFONT)

			Local shadowSettings:TData = New TData.addNumber("size", 1).addNumber("intensity", 0.5)
			Local gradientSettings:TData = New TData.addNumber("gradientBottom", 180)
			'setup effects for normal and bold
			headerFont = GetBitmapFontManager().Copy("default", "headerFont", 20, BOLDFONT)
			headerFont.SetCharsEffectFunction(1, Font_AddGradient, gradientSettings)
			headerFont.SetCharsEffectFunction(2, Font_AddShadow, shadowSettings)
			headerFont.InitFont()

			headerFont = GetBitmapFont("headerFont", 20, ITALICFONT)
			headerFont.SetCharsEffectFunction(1, Font_AddGradient, gradientSettings)
			headerFont.SetCharsEffectFunction(2, Font_AddShadow, shadowSettings)
			headerFont.InitFont()

			headerFont = GetBitmapFont("headerFont", 20)
			headerFont.SetCharsEffectFunction(1, Font_AddGradient, gradientSettings)
			headerFont.SetCharsEffectFunction(2, Font_AddShadow, shadowSettings)
			headerFont.InitFont()
		EndIf
	End Function


	'lower priority updates (currently happening every 2 "appUpdates")
	Function onLowPriorityUpdate:Int(triggerEvent:TEventBase)
		TProfiler.Enter("SoundUpdate")
		GetSoundManager().Update()
		TProfiler.Leave("SoundUpdate")
	End Function
End Type




OnEnd( EndHook )
Function EndHook()
	'CleanUp
	For Local player:TPLayer = EachIn GetPlayerCollection().players
		player.StopAI()
	Next
	
	TProfiler.DumpLog("logfiles/"+PROFILER_LOG_NAME)
	TLogFile.DumpLogs()

?bmxng
'	Local buf:Byte[4096*3]
'	DumpObjectCounts(buf, 4096*3, 0)
'	Print String.FromCString(buf)
'	OCM.FetchDump("OnEnd")
'	OCM.Dump()
?
End Function


'===== COMMON FUNCTIONS =====











?bmxng And (android Or ios)
Function handleMobileDeviceEvents:Int(data:Object, event:Int)
	Select event
		Case SDL_APP_WILLENTERBACKGROUND
			App.SetRunningInBackground(True)
			Return False
		Case SDL_APP_DIDENTERBACKGROUND
		Case SDL_APP_WILLENTERFOREGROUND
		Case SDL_APP_DIDENTERFOREGROUND
			App.SetRunningInBackground(False)
			Return False
	End Select
	Return True
End Function
?


Function DEV_switchRoom:Int(room:TRoomBase, figure:TFigure = Null)
	If Not room Then Return False

	If Not figure Then figure = GetPlayer().GetFigure()
	'do not react if already switching
	If figure.IsChangingRoom() Then Return False

	'skip if already there
	If figure.inRoom = room Then Return False

	If figure.playerID
		TLogger.Log("DEV_switchRoom", "Player #"+figure.playerID+" switching to room ~q"+room.GetName()+"~q.", LOG_DEBUG)
	Else
		TLogger.Log("DEV_switchRoom", "Figure '"+figure.GetGUID()+"' switching to room ~q"+room.GetName()+"~q.", LOG_DEBUG)
	EndIf

	'to avoid seeing too much animation
	TInGameScreen_Room.temporaryDisableScreenChangeEffects = True


	If figure.inRoom
		'abort current screen actions (drop back dragged items etc.)
		Local roomHandler:TRoomHandler = GetRoomHandlerCollection().GetHandler(figure.inRoom.GetName())
		If roomHandler Then roomHandler.AbortScreenActions()

		TLogger.Log("DEV_switchRoom", "Leaving room ~q"+figure.inRoom.GetName()+"~q first.", LOG_DEBUG)
		'force leave?
		'figure.LeaveRoom(True)
		'not forcing a leave is similar to "right-click"-leaving
		'which means it signs contracts, buys programme etc
		If figure.LeaveRoom(False)
			'finish leaving room in the same moment
			figure.FinishLeaveRoom()
		Else
			GetGame().SendSystemMessage("[DEV] cannot switch rooms: Leaving old room failed")
			Return False
		EndIf
	EndIf


	'remove potential elevator passenger
	GetElevator().LeaveTheElevator(figure)

	'a) add the room as new target before all others
	'GetPlayer().GetFigure().PrependTarget(TRoomDoor.GetMainDoorToRoom(room))
	'b) set it as the only route
	figure.SetTarget( New TFigureTarget.Init( GetRoomDoorCollection().GetMainDoorToRoom(room.id) ) )
	figure.MoveToCurrentTarget()

	'call reach step 1 - so it actually reaches the target in this turn
	'already (instead of next turn - which might have another "dev_key"
	'pressed)
	figure.ReachTargetStep1()
	figure.EnterTarget()

	Return True
End Function

Function PrintCurrentTranslationState(compareLang:String="tr")
	Print "=== TRANSLATION STATUS: DE - "+compareLang.ToUpper()+" ====="

	TLocalization.PrintCurrentTranslationState(compareLang)

	Local deLangID:Int = TLocalization.GetLanguageID("de")
	Local compareLangID:Int = TLocalization.GetLanguageID(compareLang)

	Print "~t"
	Print "=== PROGRAMMES ================="
	Print "AVAILABLE:"
	Print "----------"
	For Local obj:TProgrammeData = EachIn GetProgrammeDataCollection().entries.Values()
		Local printed:Int = False
		If obj.title.Get(deLangID) <> obj.title.Get(compareLangID)
			Print "* [T] de: "+ obj.title.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "+ obj.title.Get(compareLangID).Replace("~n", "~n          ")
			printed = True
		EndIf
		If obj.description.Get(deLangID) <> obj.description.Get(compareLangID)
			Print "* [D] de: "+ obj.description.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "+ obj.description.Get(compareLangID).Replace("~n", "~n          ")
			printed = True
		EndIf
		If printed Then Print Chr(8203) 'zero width space, else it skips "~n"
	Next

	Print "~t"
	Print "MISSING:"
	Print "--------"
	For Local obj:TProgrammeData = EachIn GetProgrammeDataCollection().entries.Values()
		Local printed:Int = False
		If obj.title.Get(deLangID) = obj.title.Get(compareLangID)
			Print "* [T] de: "+ obj.title.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "
			printed = True
		EndIf
		If obj.description.Get(deLangID) = obj.description.Get(compareLangID)
			Print "* [D] de: "+ obj.description.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "
			printed = True
		EndIf
		If printed Then Print Chr(8203) 'zero width space, else it skips "~n"
	Next


	Print "~t"
	Print "=== ADCONTRACTS ================"
	Print "AVAILABLE:"
	Print "----------"
	For Local obj:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
		Local printed:Int = False
		If obj.title.Get(deLangID) <> obj.title.Get(compareLangID)
			Print "* [T] de: "+ obj.title.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "+ obj.title.Get(compareLangID).Replace("~n", "~n          ")
			printed = True
		EndIf
		If obj.description.Get(deLangID) <> obj.description.Get(compareLangID)
			Print "* [D] de: "+ obj.description.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "+ obj.description.Get(compareLangID).Replace("~n", "~n          ")
			printed = True
		EndIf
		If printed Then Print Chr(8203) 'zero width space, else it skips "~n"
	Next

	Print "~t"
	Print "MISSING:"
	Print "--------"
	For Local obj:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
		Local printed:Int = False
		If obj.title.Get(deLangID) = obj.title.Get(compareLangID)
			Print "* [T] de: "+ obj.title.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "
			printed = True
		EndIf
		If obj.description.Get(deLangID) = obj.description.Get(compareLangID)
			Print "* [D] de: "+ obj.description.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "
			printed = True
		EndIf
		If printed Then Print Chr(8203) 'zero width space, else it skips "~n"
	Next


	Print "~t"
	Print "=== NEWSEVENTS ================="
	Print "AVAILABLE:"
	Print "----------"
	For Local obj:TNewsEvent = EachIn GetNewsEventCollection().newsEvents.Values()
		Local printed:Int = False
		If obj.title.Get(deLangID) <> obj.title.Get(compareLangID)
			Print "* [T] de: "+ obj.title.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "+ obj.title.Get(compareLangID).Replace("~n", "~n          ")
			printed = True
		EndIf
		If obj.description.Get(deLangID) <> obj.description.Get(compareLangID)
			Print "* [D] de: "+ obj.description.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "+ obj.description.Get(compareLangID).Replace("~n", "~n          ")
			printed = True
		EndIf
		If printed Then Print Chr(8203) 'zero width space, else it skips "~n"
	Next

	Print "~t"
	Print "MISSING:"
	Print "--------"
	For Local obj:TNewsEvent = EachIn GetNewsEventCollection().newsEvents.Values()
		Local printed:Int = False
		If obj.title.Get(deLangID) = obj.title.Get(compareLangID)
			Print "* [T] de: "+ obj.title.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "
			printed = True
		EndIf
		If obj.description.Get(deLangID) = obj.description.Get(compareLangID)
			Print "* [D] de: "+ obj.description.Get(deLangID).Replace("~n", "~n          ")
			Print "      "+compareLang+": "
			printed = True
		EndIf
		If printed Then Print Chr(8203) 'zero width space, else it skips "~n"
	Next
	Print "================================"
End Function


Function StartApp:Int()
	TProfiler.Enter("StartApp")

	?bmxng And (android Or ios)
	SetEventFilterCallback(handleMobileDeviceEvents)
	?

	'assign dev config (resources are now loaded)
	GameRules.devConfig = TData(GetRegistry().Get("DEV_CONFIG"))
	If not GameRules.devConfig Then GameRules.devConfig = New TData
	GameRules.devConfigBackup = GameRules.devConfig.Copy()

	'disable log from now on (if dev wished so)
	If Not GameRules.devConfig.GetBool("DEV_LOG", True)
		TLogger.SetPrintMode(0)
	EndIf


	'modify game rules by DEV.xml-Values
	GameRules.AssignFromData( Gamerules.devConfig )


	TFunctions.roundToBeautifulEnabled = GameRules.devConfig.GetBool("DEV_ROUND_TO_BEAUTIFUL_VALUES", True)
	If TFunctions.roundToBeautifulEnabled
		TLogger.Log("StartTVTower()", "DEV RoundToBeautiful is enabled", LOG_DEBUG | LOG_LOADING)
	Else
		TLogger.Log("StartTVTower()", "DEV RoundToBeautiful is disabled", LOG_DEBUG | LOG_LOADING)
	EndIf


	MainMenuJanitor = New TFigureJanitor.Create("Hausmeister", GetSpriteFromRegistry("janitor"), 250, 2, 65)
	MainMenuJanitor.useElevator = False
	MainMenuJanitor.useDoors = False
	MainMenuJanitor.useAbsolutePosition = True
	MainMenuJanitor.BoredCleanChance = 30
	MainMenuJanitor.MovementRangeMinX = 0
	MainMenuJanitor.MovementRangeMaxX = 800
	MainMenuJanitor.area.SetY(600)
	'remove figure from collection so it is not drawn/updated in other
	'screens (eg. ingame)
	GetFigureCollection().Remove(MainMenuJanitor)

	'add menu screens
	ScreenGameSettings = New TScreen_GameSettings.Create("GameSettings")
	ScreenCollection.Add(ScreenGameSettings)
	ScreenCollection.Add(New TScreen_NetworkLobby.Create("NetworkLobby"))
	ScreenCollection.Add(New TScreen_PrepareGameStart.Create("PrepareGameStart"))


	'init sound receiver
	GetSoundManager().SetDefaultReceiver(TPlayerSoundSourcePosition.Create())

	InitializeHelp()

	App.Start()
	TProfiler.Leave("StartApp")
End Function

Function InitializeHelp()
	'example for ingame-help "MainMenu"
	'IngameHelpWindowCollection.Add(new TIngameHelpWindow.Init("WELCOME_TITLE", "WELCOME_CONTENT", "MainMenu"))

	'temporary solution
	For Local screen:TScreen = EachIn ScreenCollection.screens.Values()
		Local helpTextKeyTitle:String = "INGAME_HELP_TITLE_"+screen.GetName()
		Local helpTextKeyText:String = "INGAME_HELP_TEXT_"+screen.GetName()
		If HasLocale(helpTextKeyText)
'			Print "Hilfetext gefunden fuer ~q"+helpTextKeyText+"~q -> "+screen.GetName()
			Local screenHelpWindow:TIngameHelpWindow=New TIngameHelpWindow.Init(helpTextKeyTitle, helpTextKeyText, screen.GetName())
			screenHelpWindow.showLimit = 1
			IngameHelpWindowCollection.Add( screenHelpWindow )
		EndIf
	Next


	'generic ingame-help (available via "F1")
	Local files:TList=TLocalization.GetLanguageFiles("docs/manual*.md");
	For Local file:String = EachIn files
		Local manualContent:String = LoadText(file).Replace("~r~n", "~n").Replace("~r", "~n")
		Local languageCode:String=TLocalization.GetLanguageCodeFromFilename(file)
		TLocalization.GetLanguage(languageCode).map.insert("manual_content", manualContent)
	Next

	Local manualWindow:TIngameHelpWindow = New TIngameHelpWindow.Init("MANUAL", "manual_content", "GameManual")
	manualWindow.EnableHideOption(False)
	IngameHelpWindowCollection.Add(manualWindow)

	'trigger initial ingamehelp for screen "MainMenu" as it is not called
	'for the first screen
	IngameHelpWindowCollection.ShowByHelpGUID("MainMenu")
End Function

Function ShowApp:Int()
	TProfiler.Enter("ShowApp")

	'=== LOAD LOCALIZATION ===
	'load all localizations
	TLocalization.LoadLanguages("res/lang")
	'select user language (defaulting to "de")
	TLocalization.SetCurrentLanguage(App.config.GetString("language", "de"))


	'Menu
	ScreenMainMenu = New TScreen_MainMenu.Create("MainMenu")
	ScreenCollection.Add(ScreenMainMenu)

	'go into the start menu
	GetGame().SetGamestate(TGame.STATE_MAINMENU)

	TProfiler.Leave("ShowApp")
End Function


'Global bbGCAllocCount:ULong = 0
?bmxng
'ron|gc
Extern
    Global bbGCAllocCount:ULong="bbGCAllocCount"
End Extern
?


?linux
Function CreateDesktopFile()
	Local cwd:String = CurrentDir()
	local file:TStream = WriteStream("TVTower.desktop")
	if file
		file.WriteLine("[Desktop Entry]")
		file.WriteLine("Name=TVTower " + VersionString) 
		file.WriteLine("Exec="+cwd+"/TVTower_Linux64") 
		file.WriteLine("Icon="+cwd+"/tvtower.png") 
		file.WriteLine("Type=Application") 
		file.WriteLine("Categories=Game;")
		file.Close()
		file = Null
		TLogger.Log("CreateDesktopFile()", "Created new TVTower.desktop file.", LOG_DEBUG)
	endif
End Function
?

Function StartTVTower(start:Int=True)
	'for now we ignore a lot of types to keep the OCM stuff small
	OCM.AddIgnoreTypes("TObjectCountDumpEntry, TObjectCountDump, TRamStream")
rem	
	OCM.AddIgnoreTypes("TStyledBitmapFonts, TRoomBaseCollection, TMovieFlagDefinition, TGUINewsSlotList, TDeltaTimer, TRoomAgency")
	OCM.AddIgnoreTypes("TSmartFloorRoute, TSizedBitmapFonts, TGUIGameModalWindow, TSpriteParticleEmitter")
	OCM.AddIgnoreTypes("RoomHandler_RoomAgency, RoomHandler_Roomboard, RoomHandler_Studio")
	OCM.AddIgnoreTypes("TNewsEventTemplate, TWorld, TProductionCompany, TNewsEventSportLeague_IceHockey")
	OCM.AddIgnoreTypes("TGUIScrollablePanel, TGUICheckBox, TGUIGameEntryList, TGUIGameChat, TStringBuilder, TBettyPresent, TRoomDoor, TPlayer")
	OCM.AddIgnoreTypes("TGUIProductionCompanyDropDownItem")
	'OCM.AddIgnoreTypes("String, TApp, TBank, TBitmapFont, TBitmapFontChar, TBitmapFontManager")
	OCM.AddIgnoreTypes("TCatmullRomSpline, TConstant, TField, TFreeAudioChannel, TFreeAudioSound, TFreeTypeFont, TFreeTypeGlyph")
	OCM.AddIgnoreTypes("TGLImageFrame, TGlobal, TGraphicsContext, THook, TSDLGLContext, TSDLGraphics, TSDLWindow")
	OCM.AddIgnoreTypes("TImageFont, TImageGlyph, TMax2DGraphics, TMethod, TMutex, TTypeId")

	OCM.AddIgnoreTypes("TSoundManager_Soloud, TDigAudioStream_Soloud, TPlayerColor, TBitmapFontChar, TGUITooltipBase, TIntMap")
	OCM.AddIgnoreTypes("TGame, TThread, TRegistry, TLocalizationLanguage, TLink")
	OCM.AddIgnoreTypes("TGUIButton, TGUIinput, TGUILabel, TGUISlider, TGUISpriteDropDown, TGUIListBase")
	OCM.AddIgnoreTypes("TToastMessageCollection, TDrawTextSettings, TSpriteFrameAnimation")
	OCM.AddIgnoreTypes("TScreen_MainMenu, TSoloudChannel, TBuildingIntervalTimer")
	OCM.AddIgnoreTypes("TGUIChatWindow, TScreen_PrepareGameStart, TCStream, TGUIDropDown, TVirtualGfx, TFigureCollection")
	OCM.AddIgnoreTypes("TIngameHelpWindow, TFigureJanitor, TGUIArrowButton, TSLWavStream, TDrawTextEffect, TInGameScreen_Room, TGUIGameWindow")
	OCM.AddIgnoreTypes("TSoloudSound, TScreen_GameSettings, TSpriteFrameAnimationCollection, TApp, TSLWav, TGUIBackgroundBox, TRoomDoorBaseCollection, TFunction, TMouseManagerClick, TEventListenerRunFunction, TPlayerSoundSourcePosition, TGUISpriteDropDownItem, TSfxSettings, TGUIScroller, TBitmapFont, TGUISelectList, TBitmapFontManager")
	OCM.AddIgnoreTypes("TSpriteEntity, TFigureGeneratorPart, TBuildingTime, TBuildingBase, TGUITextBox, TIntervalTimer, TDynamicSfxChannel, TGUIDropDownItem, TElevator, TStreamFile, TFigureBaseSoundSource, TScreen_NetworkLobby")
endrem
	OCM.StoreBaseDump()

	Global InitialResourceLoadingDone:Int = False
	Global AppSuspendedProcessed:Int = False

	EventManager.Init()

	TProfiler.Enter("StartTVTower: Create App")
	App = TApp.Create(60, -1, True) 'create with screen refreshrate and vsync
	'App = TApp.Create(30, -1, False) 'create with refreshrate of 40
	App.LoadResources("config/resources.xml")
	TProfiler.Leave("StartTVTower: Create App")

?Threaded
'	While not RURC.FinishedLoading()
'		Delay(1)
'	Wend
?

	'====
	'to avoid the "is loaded check" we have two loops
	'====

	'a) the mode before everything important was loaded
TProfiler.Enter("InitialLoading")
	ShowApp()
	Repeat
		'handle if app is run in background (mobile devices like android/iOS)
		App.ProcessRunningInBackground()

		'instead of only checking for resources in main loop
		'(happens eg. 30 times a second), check each update cycle
		TProfiler.Enter("RessourceLoader")
		RURC.Update()
		TProfiler.Leave("RessourceLoader")

		GetDeltaTimer().Loop()

		If RURC.FinishedLoading() Then InitialResourceLoadingDone = True

		EventManager.update()
		'If RandRange(0,20) = 20 Then GCCollect()
	Until AppTerminate() Or TApp.ExitApp Or InitialResourceLoadingDone
TProfiler.Leave("InitialLoading")
GCCollect()

	'=== ADJUST GUI FONTS ===
	'set the now available default font
	GuiManager.SetDefaultFont( GetBitmapFontManager().Get("Default", 14) )
	'buttons get a bold font
	TGUIButton.SetTypeFont( GetBitmapFontManager().Get("Default", 14, BOLDFONT) )
	'checkbox (and their labels) get a smaller one
	'TGUICheckbox.SetTypeFont( GetBitmapFontManager().Get("Default", 11) )
	'labels get a slight smaller one
	'TGUILabel.SetTypeFont( GetBitmapFontManager().Get("Default", 11) )



	'b) set language
	App.SetLanguage(App.config.GetString("language", "de"))
	TLocalization.SetDefaultLanguage("en")

if collectDebugStats
	GCSetMode(2) 'manual
endif

	'c) everything loaded - normal game loop
TProfiler.Enter("GameLoop")
	StartApp()

	Repeat
		If collectDebugStats
			If MilliSecs() - debugCreationTime > 1000
				local memCollected:Int = GCCollect()
				Local gcAllocChanges:Int
				Local gcAllocTotal:Int

				If OCM.enabled
					OCM.FetchDump()
					gcAllocChanges = OCM.GetLastDump().totalChange
					gcAllocTotal = OCM.GetLastDump().total
					If OCM.printEnabled
						OCM.Dump(null)
					EndIf
				EndIf
				
				If printDebugStats
					If OCM.enabled
						If gcAllocChanges >= 0
							Print "tick: " + rectangle_created +" TRectangle. " + vec2d_created + " Tvec2d. " + tcolor_created + " TColor.  GC: " + bbGCAllocCount + " allocs (OCM: " + gcAllocTotal+" +"+gcAllocChanges+"). GC Mem: " +GCMemAlloced() + " allocated, " + memCollected + " collected"
						Else
							Print "tick: " + rectangle_created +" TRectangle. " + vec2d_created + " Tvec2d. " + tcolor_created + " TColor.  GC: " + bbGCAllocCount + " allocs (OCM: " + gcAllocTotal+" "+gcAllocChanges+"). GC Mem: " +GCMemAlloced() + " allocated, " + memCollected + " collected"
						EndIf
					Else
					Print "tick: " + rectangle_created +" TRectangle. " + vec2d_created + " Tvec2d. " + tcolor_created + " TColor.  GC: " + bbGCAllocCount + " allocs. GC Mem: " +GCMemAlloced() + " allocated, " + memCollected + " collected"
					EndIf
				EndIf
				bbGCAllocCount = 0
				rectangle_created = 0
				vec2d_created = 0
				tcolor_created = 0
				debugCreationTime :+ 1000
				?
			EndIf
		EndIf

		If AppSuspended()
			If Not AppSuspendedProcessed
				TLogger.Log("App", "App suspended.", LOG_DEBUG)
				AppSuspendedProcessed = True
			EndIf
		ElseIf AppSuspendedProcessed
			TLogger.Log("App", "App resumed.", LOG_DEBUG)
			AppSuspendedProcessed = False
		EndIf


		'handle if app is run in background (mobile devices like android/iOS)
		App.ProcessRunningInBackground()

		GetDeltaTimer().Loop()

		'process events not directly triggered
		'process "onMinute" etc. -> App.OnUpdate, App.OnDraw ...
'TProfiler.Enter("EventManager")
		EventManager.update()
'TProfiler.Leave("EventManager")
		'If RandRange(0,20) = 20 Then GCCollect()
	Until TApp.ExitApp 
TProfiler.Leave("GameLoop")

	'take care of network
	If GetGame().networkgame Then Network.DisconnectFromServer()
End Function
