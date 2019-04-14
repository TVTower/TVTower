'Application: TVGigant/TVTower
'Author: Ronny Otto & Team

SuperStrict

Import Brl.Stream
Import Brl.Retro

Import brl.timer
Import brl.eventqueue
?Threaded
Import brl.Threads
?
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
Import "game.programmeproducer.bmx"

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

Import "game.network.networkhelper.bmx"
Import "game.misc.savegameserializers.bmx"

?not bmxng
'notify users when there are XML-errors
Function TVTXmlErrorCallback(data:Object, error:TxmlError)
	local result:string = "XML-Error~n"
	result :+ "Error: "+ error.getErrorMessage()+"~n"
	result :+ "File:  "+ error.getFileName()+":"+error.getLine()+"@"+error.getColumn()+"~n"
	Notify result

	TLogger.Log("XML-Error", error.getErrorMessage(), LOG_ERROR)
	TLogger.Log("XML-Error", "File:  "+ error.getFileName()+". Line:"+error.getLine()+" Column:"+error.getColumn(), LOG_ERROR)
End Function
xmlSetErrorFunction(TVTXmlErrorCallback, null)
?

'===== Includes =====

'Types: - TError - Errorwindows with handling
'		- base class For buttons And extension newsbutton
Include "gamefunctions.bmx"

Include "gamefunctions_rooms.bmx"				'basic roomtypes with handling
Include "gamefunctions_sound.bmx"				'TVTower spezifische Sounddefinitionen
Include "gamefunctions_debug.bmx"

Include "game.menu.escapemenu.bmx"


'===== Globals =====
VersionDate = LoadText("incbin::source/version.txt").Trim()
VersionString = "v0.6.2-dev Build ~q" + VersionDate+"~q"
CopyrightString = "by Ronny Otto & Team"

Global APP_NAME:string = "TVTower"
Global LOG_NAME:string = "log.profiler.txt"

Global App:TApp = Null
Global MainMenuJanitor:TFigureJanitor
Global ScreenGameSettings:TScreen_GameSettings = Null
Global ScreenMainMenu:TScreen_MainMenu = Null
Global Init_Complete:Int = 0

Global RURC:TRegistryUnloadedResourceCollection = TRegistryUnloadedResourceCollection.GetInstance()


'==== Initialize ====
AppTitle = "TVTower: " + VersionString
TLogger.Log("CORE", "Starting "+APP_NAME+", "+VersionString+".", LOG_INFO )

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
	Field runningInBackground:int = False
	'developer/base configuration
	Field configBase:TData = New TData
	'configuration containing base + user
	Field config:TData = New TData
	'draw logo for screenshot ?
	Field prepareScreenshot:Int	= 0

	'only used for debug purpose (loadingtime)
	Field creationTime:Long
	'store listener for music loaded in "startup"
	Field OnLoadMusicListener:TLink

	Field settingsWindow:TSettingsWindow

	'bitmask defining what elements set the game to paused (eg. escape
	'menu, ingame help ...)
	Field pausedBy:int = 0

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

	Global DEV_FastForward:int = False
	Global DEV_FastForward_SpeedFactorBackup:Float = 0.0
	Global DEV_FastForward_TimeFactorBackup:Float = 0.0
	Global DEV_FastForward_BuildingTimeSpeedFactorBackup:Float = 0.0

	Global settingsBasePath:String = "config/settings.xml"
	Global settingsUserPath:String = "config/settings.user.xml"

	Const PAUSED_BY_ESCAPEMENU:int = 1
	Const PAUSED_BY_EXITDIALOGUE:int = 2
	Const PAUSED_BY_INGAMEHELP:int = 4
	Const PAUSED_BY_MODALWINDOW:int = 8

	Global systemState:TLowerString = TLowerString.Create("SYSTEM")

	Function Create:TApp(updatesPerSecond:Int = 60, framesPerSecond:Int = 30, vsync:Int=True, initializeGUI:Int=True)
		Local obj:TApp = New TApp
		obj.creationTime = Time.MillisecsLong()

		If initializeGUI Then
			'register to:
			'- quit confirmation dialogue
			'- handle saving/applying of settings
			EventManager.registerListenerFunction( "guiModalWindow.onClose", onCloseModalDialogue )
			EventManager.registerListenerFunction( "guiModalWindowChain.onClose", onCloseEscapeMenu )
			EventManager.registerListenerFunction( "RegistryLoader.onLoadXmlFromFinished",	TApp.onLoadXmlFromFinished )
			obj.OnLoadMusicListener = EventManager.registerListenerFunction( "RegistryLoader.onLoadResource",	TApp.onLoadMusicResource )

			?debug
			EventManager.registerListenerFunction( "RegistryLoader.onLoadResource", TApp.onLoadResource )
			EventManager.registerListenerFunction( "RegistryLoader.onBeginLoadResource", TApp.onBeginLoadResource )
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
			GetGraphicsManager().SetResolution(obj.config.GetInt("screenW", 800), obj.config.GetInt("screenH", 600))
			'GetGraphicsManager().SetResolution(1024,768)
			GetGraphicsManager().SetDesignedResolution(800,600)
			GetGraphicsManager().InitGraphics()

			GameRules.InRoomTimeSlowDownMod = obj.config.GetInt("inroomslowdown", 100) / 100.0

			MouseManager._minSwipeDistance = obj.config.GetInt("touchClickRadius", 10)
			MouseManager._ignoreFirstClick = obj.config.GetBool("touchInput", False)
			MouseManager._longClickModeEnabled = obj.config.GetBool("longClickMode", True)
			MouseManager._longClickTime = obj.config.GetInt("longClickTime", 400)

			IngameHelpWindowCollection.showHelp = obj.config.GetBool("showIngameHelp", True)


			TLogger.Log("App.Create()", "Loading base resources.", LOG_DEBUG)
			'load graphics needed for loading screen,
			'load directly (no delayed loading)
			obj.LoadResources(obj.baseResourceXmlUrl, True)
		EndIf

		Return obj
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


	Function onBeginLoadResource:int( triggerEvent:TEventBase )
		Local resourceName:String = triggerEvent.GetData().GetString("resourceName")
		Local name:String = triggerEvent.GetData().GetString("name")
		TLogger.Log("App.onLoadResource", "Loading ~q"+name+"~q ["+resourceName+"]", LOG_LOADING)
	End Function


	Function onLoadResource:int( triggerEvent:TEventBase )
		Local resourceName:String = triggerEvent.GetData().GetString("resourceName")
		Local name:String = triggerEvent.GetData().GetString("name")
		TLogger.Log("App.onLoadResource", "Loaded ~q"+name+"~q ["+resourceName+"]", LOG_LOADING)
	End Function



	'if no startup-music was defined, try to play menu music if some
	'is loaded
	Function onLoadMusicResource:int( triggerEvent:TEventBase )
		Local resourceName:String = triggerEvent.GetData().GetString("resourceName")
		If resourceName = "MUSIC"
			'if no music is played yet, try to get one from the "menu"-playlist
			If Not GetSoundManager().isPlaying() Then GetSoundManager().PlayMusicPlaylist("menu")
		EndIf
	End Function


	Function onLoadXmlFromFinished:int( triggerEvent:TEventBase )
		If triggerEvent.getData().getString("uri") = TApp.baseResourceXmlUrl
			TApp.baseResourcesLoaded = 1
		EndIf
	End Function


	Method IsRunningInBackground:int()
		return runningInBackground
	End Method


	Method SetRunningInBackground:int(bool:int=True)
		runningInBackground = bool
	End Method


	Method ProcessRunningInBackground()
		If not IsRunningInBackground() then return

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

		if settingsWindow then settingsWindow.Remove()
		settingsWindow = New TSettingsWindow.Init() '.Create(New TVec2D(), New TVec2D.Init(520,45), "SYSTEM")
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
		if not GetGame().PlayingAGame()
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


	Method ApplySettings:Int(doInitGraphics:int = True)
		local adjusted:int = False
		if GetGraphicsManager().SetFullscreen(config.GetBool("fullscreen", False), False)
			TLogger.Log("ApplySettings()", "SetFullscreen = "+config.GetBool("fullscreen", False), LOG_DEBUG)
			'until GLSDL works as intended:
			?not bmxng
			adjusted = True
			?
		endif
		if GetGraphicsManager().SetRenderer(config.GetInt("renderer", GetGraphicsManager().GetRenderer()))
			TLogger.Log("ApplySettings()", "SetRenderer = "+config.GetInt("renderer", GetGraphicsManager().GetRenderer()), LOG_DEBUG)
			'until GLSDL works as intended:
			?not bmxng
			adjusted = True
			?
		endif
		if GetGraphicsManager().SetColordepth(config.GetInt("colordepth", 16))
			TLogger.Log("ApplySettings()", "SetColordepth = "+config.GetInt("colordepth", -1), LOG_DEBUG)
			'until GLSDL works as intended:
			?not bmxng
			adjusted = True
			?
		endif
		if GetGraphicsManager().SetVSync(config.GetBool("vsync", True))
			TLogger.Log("ApplySettings()", "SetVSync = "+config.GetBool("vsync", False), LOG_DEBUG)
			'until GLSDL works as intended:
			?not bmxng
			adjusted = True
			?
		endif
		if GetGraphicsManager().SetResolution(config.GetInt("screenW", 800), config.GetInt("screenH", 600))
			TLogger.Log("ApplySettings()", "SetResolution = "+config.GetInt("screenW", 800)+"x"+config.GetInt("screenH", 600), LOG_DEBUG)
			'until GLSDL works as intended:
			?not bmxng
			adjusted = True
			?
		endif
		if adjusted and doInitGraphics then GetGraphicsManager().InitGraphics()


		GameRules.InRoomTimeSlowDownMod = config.GetInt("inroomslowdown", 100) / 100.0

		GetDeltatimer().SetRenderRate(config.GetInt("fps", -1))

		adjusted = False



		if config.GetString("sound_engine").ToLower() = "none"
			TSoundManager.audioEngineEnabled = False
			GetSoundManager()
			TSoundManager.audioEngineEnabled = True
			GetSoundManager().MuteMusic(true)
			GetSoundManager().MuteSfx(true)
			TSoundManager.audioEngineEnabled = False
		Else
			GetSoundManagerBase().ApplyConfig(config.GetString("sound_engine", "AUTOMATIC"), ..
			                                  0.01 * config.GetInt("sound_music_volume", 100), ..
			                                  0.01 * config.GetInt("sound_sfx_volume", 100) ..
			                                 )
		EndIf
		GetSoundManager().MuteMusic(config.GetInt("sound_music_volume", 100) = 0)
		GetSoundManager().MuteSfx(config.GetInt("sound_sfx_volume", 100) = 0)

		if not GetSoundManager().HasMutedMusic()
			'if no music is played yet, try to get one from the "menu"-playlist
			If Not GetSoundManager().isPlaying()
				GetSoundManager().PlayMusicPlaylist("menu")
			endif
		endif

		MouseManager._minSwipeDistance = config.GetInt("touchClickRadius", 10)
		MouseManager._ignoreFirstClick = config.GetBool("touchInput", False)
		MouseManager._longClickModeEnabled = config.GetBool("longClickMode", True)

		IngameHelpWindowCollection.showHelp = config.GetBool("showIngameHelp", True)

		if TGame._instance Then GetGame().LoadConfig(config)
	End Method


	Method LoadResources:Int(path:String="config/resources.xml", directLoad:Int=False)
		?debug
		local deferred:string = ""
		if not directLoad then deferred = "(Deferred) "
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
		EventManager.triggerEvent(TEventSimple.Create("Language.onSetLanguage", New TData.Add("languageCode", languageCode), Self))
		Return True
	End Method


	Method Start()
		AppEvents.Init()

		'systemupdate is called from within "update" (lower priority updates)
		EventManager.registerListenerFunction("App.onLowPriorityUpdate", AppEvents.onLowPriorityUpdate )
		'so we could create special fonts and other things
		EventManager.triggerEvent( TEventSimple.Create("App.onStart") )

		'from now on we are no longer interested in loaded elements
		'as we are no longer in the loading screen (-> silent loading)
		If OnLoadMusicListener Then EventManager.unregisterListenerByLink( OnLoadMusicListener )

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


	Function Update:Int()
		TProfiler.Enter("Update")
		'every 3rd update do a low priority update
		If GetDeltaTimer().timesUpdated Mod 3 = 0
			EventManager.triggerEvent( TEventSimple.Create("App.onLowPriorityUpdate",Null) )
		EndIf

		TProfiler.Enter("RessourceLoader")
		'check for new resources to load
		RURC.Update()
		TProfiler.Leave("RessourceLoader")


		'needs modified "brl.mod/polledinput.mod" (disabling autopoll)
		SetAutoPoll(False)
		KEYMANAGER.Update()
		MOUSEMANAGER.Update()
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
		If App.ExitAppDialogue or App.EscapeMenuWindow
			MouseManager.ResetKey(2)
			'also avoid long click (touch screen)
			MouseManager.ResetLongClicked(1)

			'this sets all IsClicked(), IsHit() to False
			MouseManager.Disable(1)
			MouseManager.Disable(2)
		EndIf

		'ignore shortcuts if a gui object listens to keystrokes
		'eg. the active chat input field
		'also ignore if there is a modal window opened
		If Not GUIManager.GetKeystrokeReceiver() and ..
		   Not (App.ExitAppDialogue or App.EscapeMenuWindow)

			If GameRules.devConfig.GetBool("DEV_KEYS", False)
				'(un)mute sound
				'M: (un)mute all sounds
				'SHIFT+M: (un)mute all sound effects
				'CTRL+M: (un)mute all music
				If KEYMANAGER.IsHit(KEY_M)
					If KEYMANAGER.IsDown(KEY_LSHIFT) Or KEYMANAGER.IsDown(KEY_RSHIFT)
						GetSoundManager().MuteSfx(Not GetSoundManager().HasMutedSfx())
					ElseIf KEYMANAGER.IsDown(KEY_LCONTROL) Or KEYMANAGER.IsDown(KEY_RCONTROL)
						GetSoundManager().MuteMusic(Not GetSoundManager().HasMutedMusic())
					Elseif not KEYMANAGER.IsDown(KEY_LALT)
						GetSoundManager().Mute(Not GetSoundManager().IsMuted())
					EndIf
				EndIf

				'in game and not gameover
				If GetGame().gamestate = TGame.STATE_RUNNING and not GetGame().IsGameOver()
					If KEYMANAGER.IsDown(KEY_UP) Then GetWorldTime().AdjustTimeFactor(+5)
					If KEYMANAGER.IsDown(KEY_DOWN) Then GetWorldTime().AdjustTimeFactor(-5)

					If KEYMANAGER.IsDown(KEY_RIGHT)
						if not KEYMANAGER.IsDown(KEY_LCONTROL) and not KEYMANAGER.Isdown(KEY_RCONTROL)
							TEntity.globalWorldSpeedFactor :+ 0.05
							GetWorldTime().AdjustTimeFactor(+10)
							GetBuildingTime().AdjustTimeFactor(+0.05)
						else
							'fast forward
							if not DEV_FastForward
								DEV_FastForward = true
								DEV_FastForward_SpeedFactorBackup = TEntity.globalWorldSpeedFactor
								DEV_FastForward_TimeFactorBackup = GetWorldTime()._timeFactor
								DEV_FastForward_BuildingTimeSpeedFactorBackup = GetBuildingTime()._timeFactor

								if KEYMANAGER.IsDown(KEY_RCONTROL)
									TEntity.globalWorldSpeedFactor :+ 200
									GetWorldTime().AdjustTimeFactor(+8000)
									GetBuildingTime().AdjustTimeFactor(+200)
								elseif KEYMANAGER.IsDown(KEY_LCONTROL)
									TEntity.globalWorldSpeedFactor :+ 50
									GetWorldTime().AdjustTimeFactor(+2000)
									GetBuildingTime().AdjustTimeFactor(+50)
								endif
							endif
						endif
					else
						'stop fast forward
						if DEV_FastForward
							DEV_FastForward = False
							TEntity.globalWorldSpeedFactor = DEV_FastForward_SpeedFactorBackup
							GetWorldTime()._timeFactor = DEV_FastForward_TimeFactorBackup
							GetBuildingTime()._timeFactor = DEV_FastForward_BuildingTimeSpeedFactorBackup
						endif
					EndIf


					If KEYMANAGER.IsDown(KEY_LEFT) Then
						TEntity.globalWorldSpeedFactor = Max( TEntity.globalWorldSpeedFactor - 0.05, 0)
						GetWorldTime().AdjustTimeFactor(-10)
						GetBuildingTime().AdjustTimeFactor(-0.05)
					EndIf

					If KEYMANAGER.IsHit(KEY_F)
						If KEYMANAGER.IsDown(KEY_LSHIFT) or KEYMANAGER.IsDown(KEY_RSHIFT)
							if KEYMANAGER.IsDown(KEY_RSHIFT)
								local playerIDs:int[] = [1,2,3,4]

								print "====== TOTAL FINANCE OVERVIEW ======" + "~n"
								local result:string = ""
								For local day:int = GetWorldTime().GetStartDay() to GetworldTime().GetDay()
									For local playerID:int = EachIn playerIDs
										For local s:string = EachIn GetPlayerFinanceOverviewText(playerID, day)
											result :+ s+"~n"
										Next
									Next
									result :+ "~n~n"
								Next

								local logFile:TStream = WriteStream("utf8::" + "log.financeoverview.txt")
								logFile.WriteString(result)
								logFile.close()
								print result
								print "===================================="
							else
								'single overview - only today

								local text:string[] = GetPlayerFinanceOverviewText(GetPlayer().playerID, GetWorldTime().GetOnDay() -1 )
								For local s:string = EachIn text
									print s
								Next
							endif
						endif
					endif


					If KEYMANAGER.IsHit(KEY_W)
						If KEYMANAGER.IsDown(KEY_LSHIFT) or KEYMANAGER.IsDown(KEY_RSHIFT)
							local adList:TList = CreateList()
							For local a:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
								adList.AddLast(a)
							Next
							adList.Sort(True, TAdContractBase.SortByName)



							print "==== AD CONTRACT OVERVIEW ===="
							print ".---------------------------------.------------------.---------.----------.----------.-------.-------."
							print "| Name                            | Audience       % |  Image  |  Profit  |  Penalty | Spots | Avail |"
							print "|---------------------------------+------------------+---------+----------+----------|-------|-------|"

							'For local a:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
							For local a:TAdContractBase = EachIn adList
								local ad:TAdContract = new TAdContract
								'do NOT call ad.Create() as it adds to the adcollection
								ad.base = a
								local title:String = LSet(a.GetTitle(), 30)
								local audience:string = LSet( RSet(ad.GetMinAudience(), 7), 8)+"  "+RSet( MathHelper.NumberToString(100 * a.minAudienceBase,2)+"%", 6)
								local image:string =  Rset(MathHelper.NumberToString(ad.GetMinImage()*100, 2)+"%", 7)
								local profit:string =  Rset(ad.GetProfit(), 8)
								local penalty:string =  Rset(ad.GetPenalty(), 8)
								local spots:string = RSet(ad.GetSpotCount(), 5)
								local availability:string = ""
								local targetGroup:String = ""
								if ad.GetLimitedToTargetGroup() > 0
									targetGroup = "* "+ getLocale("AD_TARGETGROUP")+": "+ad.GetLimitedToTargetGroupString()
									title :+ "*"
								else
									title :+ " "
								endif
								if ad.base.IsAvailable()
									availability = RSet("Yes", 5)
								else
									availability = RSet("No", 5)
								endif

								print "| "+title + " | " + audience + " | " + image + " | " + profit + " | " + penalty + " | " + spots+" | " + availability +" |" + targetgroup

							Next
							print "'---------------------------------'------------------'---------'----------'----------'-------'-------'"
						endif
					endif


					If KEYMANAGER.IsHit(KEY_Y)
						Local reach:Int = GetStationMap( 1 ).GetReach()
						print "reach: " + reach +"  audienceReach=" + GetBroadcastmanager().GetAudienceResult(1).WholeMarket.GetTotalSum()
						reach = GetStationMap( 1 ).GetReach()
						rem
						print "GetBroadcastManager: "
						print GetBroadcastManager().GetAudienceResult(1).ToString()
						print "Daily: "
						debugstop
						local dayHour:int = GetWorldTime().GetDayHour()
						local day:int = GetWorldTime().GetDay()
						Local dailyBroadcastStatistic:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day, True)
						local r:TAudienceResult = TAudienceResult(dailyBroadcastStatistic.GetAudienceResult(1, dayHour))
						if r then print r.ToString()
						endrem


'						print "Force Next Task:"
'						GetPlayer(2).PlayerAI.CallLuaFunction("OnForceNextTask", null)

						local addLicences:string[]
						local addContracts:string[]
						local addNewsEventTemplates:string[]

						'addNewsEventTemplates :+ ["ronny-news-drucktaste-02b"]
						'addLicences :+ ["TheRob-Mon-TvTower-EinmonumentalerVersuch"]
						'addContracts :+ ["ronny-ad-allhits-02"]

						rem
						for local i:int = 0 to 9
							print "i) unused: " + GetNewsEventTemplateCollection().GetUnusedAvailableInitialTemplateList(TVTNewsGenre.CULTURE).Count()
							local newsEvent:TNewsEvent = GetNewsEventCollection().CreateRandomAvailable(TVTNewsGenre.CULTURE)
							if newsEvent
								GetNewsAgency().announceNewsEvent(newsEvent, 0, False)
								print "happen: ~q"+ newsEvent.GetTitle() + "~q ["+newsEvent.GetGUID()+"~q  at: "+GetWorldTime().GetformattedTime(newsEvent.happenedTime)
							endif
						next
						endrem

						for local l:string = EachIn addNewsEventTemplates
							local template:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByGUID(l)
							if template
								local newsEvent:TNewsEvent = new TNewsEvent.InitFromTemplate(template)
								GetNewsAgency().announceNewsEvent(newsEvent, 0, False)
								print "happen: ~q"+ newsEvent.GetTitle() + "~q ["+newsEvent.GetGUID()+"] at: "+GetWorldTime().GetformattedTime(newsEvent.happenedTime)
							endif
						next

						for local l:string = EachIn addContracts
							local adContractBase:TAdContractBase = GetAdContractBaseCollection().GetByGUID(l)
							if adContractBase
								'forcefully add to the collection (skips requirements checks)
								GetPlayerProgrammeCollection(1).AddAdContract(New TAdContract.Create(adContractBase), True)
							endif
						next

						for local l:string = EachIn addLicences
							local p:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(l)
							if not p
								print "DEV: programme licence ~q"+l+"~q not found."
								continue
							endif

							if p.owner <> GetPlayer().playerID
								p.SetOwner(0)
								RoomHandler_MovieAgency.GetInstance().SellProgrammeLicenceToPlayer(p, 1)
								print "added movie: "+p.GetTitle()+" ["+p.GetGUID()+"]"
							else
								print "already had movie: "+p.GetTitle()+" ["+p.GetGUID()+"]"
							endif
						next


						rem
						if GetAwardCollection().currentAward
							TLogger.Log("DEV", "Awards: finish current award.", LOG_DEV)
							GetAwardCollection().currentAward.AdjustScore(1, 1000)
							GetAwardCollection().currentAward.SetEndTime( Long(GetWorldTime().GetTimeGone()-1) )
							GetAwardCollection().UpdateAwards()
						else
							TLogger.Log("DEV", "Awards: force start of next award.", LOG_DEV)
							GetAwardCollection().nextAwardTime = Long(GetWorldTime().GetTimeGone())
							GetAwardCollection().UpdateAwards()
						endif
						endrem

						rem
						local room:TRoomBase = GetRoomBaseCollection().GetFirstByDetails("", "laundry")
						if room
							print "renting room: " + room.GetName()
							GetRoomAgency().CancelRoomRental(room, GetPlayerBase().playerID)
							GetRoomAgency().BeginRoomRental(room, GetPlayerBase().playerID)
							room.SetUsedAsStudio(True)
						else
							print "room not found"
						endif
						endrem


						rem
						local fCheap:TProgrammeLicenceFilter = RoomHandler_MovieAgency.GetInstance().filterMoviesCheap
						local fGood:TProgrammeLicenceFilter = RoomHandler_MovieAgency.GetInstance().filterMoviesGood
						local fAuction:TProgrammeLicenceFilter = RoomHandler_MovieAgency.GetInstance().filterAuction
						local total:int = 0
						local foundCheap:int = 0
						local foundGood:int = 0
						local foundAuction:int = 0
						local foundSkipped:int = 0
						local skippedFilterCount:int = 0
						For local p:TProgrammeLicence = EachIn GetProgrammeLicenceCollection().licences.Values()
							if p.IsEpisode() then continue
							if not p.IsReleased() then continue
							if p.IsSeries() then continue

							skippedFilterCount = 0

							total :+1
							if fCheap.DoesFilter(p)
								'print p.GetTitle()
								foundCheap :+ 1
							else
								skippedFilterCount :+ 1
							endif

							if fGood.DoesFilter(p)
								'print p.GetTitle()
								foundGood :+ 1
							else
								skippedFilterCount :+ 1
							endif

							if fAuction.DoesFilter(p)
								'print p.GetTitle()
								foundAuction :+ 1
							else
								skippedFilterCount :+ 1
							endif

							if skippedFilterCount = 3
								print "unavailable: "+ p.GetTitle()+"  [year="+p.data.GetYear()+"  price="+p.GetPrice(GetPlayerBase().playerID)+"  topicality="+p.GetTopicality()+"/"+p.GetMaxTopicality()+"  quality="+p.GetQuality()+"]"
								foundSkipped :+ 1
							endif
						Next
						print "found cheap:"+foundCheap+", good:"+foundGood+", auction:"+foundAuction+", skipped:"+foundSkipped+" movies/series for 1985. Total="+total
						endrem

'						print "DEV: Set Player 2 bankrupt"
'						GetGame().SetPlayerBankrupt(2)

						'GetWorld().Weather.SetPressure(-14)
						'GetWorld().Weather.SetTemperature(-10)

						'send marshal to confiscate the licence
						rem
						local licence:TProgrammeLicence = GetPlayer().GetProgrammeCollection().GetRandomProgrammeLicence()
						if licence
							TFigureMarshal(GetGame().marshals[rand(0,1)]).AddConfiscationJob( licence.GetGUID() )
						else
							print "no random licence to confiscate"
						endif
						endrem

						'buy script
						rem
						Local s:TScript = RoomHandler_ScriptAgency.GetInstance().GetScriptByPosition(0)
						If Not s
							RoomHandler_ScriptAgency.GetInstance().ReFillBlocks()
							s = RoomHandler_ScriptAgency.GetInstance().GetScriptByPosition(0)
						EndIf

						If s
							RoomHandler_ScriptAgency.GetInstance().SellScriptToPlayer(s, GetPlayer().playerID)
							RoomHandler_ScriptAgency.GetInstance().ReFillBlocks()
							Print "added script: "+s.GetTitle()
						EndIf
						endrem

						rem
						RoomHandler_MovieAgency.GetInstance().RefillBlocks(true, 0.9)
						endrem

						rem
						'Programme bei mehreren Spielern
						'duplicateCount = 0
						for local playerA:int = 1 to 4
							for local playerB:int = 1 to 4
								if playerA = playerB then continue 'skip same


								For local lA:TProgrammeLicence = EachIn GetPlayerProgrammeCollection(playerA).programmeLicences
									For local lB:TProgrammeLicence = EachIn GetPlayerProgrammeCollection(playerB).programmeLicences

										if lA = lB
											print "found playercollection ("+playerA+" vs " + playerB+") duplicate: "+lA.GetTitle()
											duplicateCount :+ 1
											continue
										endif

										if lA.GetGUID() = lB.GetGUID()
											print "found playercollection ("+playerA+" vs " + playerB+")  GUID duplicate: "+lA.GetTitle()
											duplicateCount :+ 1
											continue
										endif

										if lA.GetTitle() = lB.GetTitle() and lA.data.year = lB.data.year
											print "found playercollection ("+playerA+" vs " + playerB+")  TITLE duplicate: "+lA.GetTitle()
											duplicateCount :+ 1
											continue
										endif
									Next
								Next
							Next
						Next


						'check possession
						For local playerID:int = 1 to 4
							For local l:TProgrammeLicence = EachIn GetPlayerProgrammeCollection(playerID).programmeLicences
								if l.owner <> playerID then print "found playerCollection OWNER bug: "+l.GetTitle()
							Next
						Next
						endrem

						rem
						local news:TNewsEvent = GetNewsEventCollection().GetByGUID("ronny-news-sandsturm-01")
						GetNewsAgency().announceNewsEvent(news, 0, False)
						print "happen: "+ news.GetTitle() + "  at: "+GetWorldTime().GetformattedTime(news.happenedTime)
						endrem

'						PrintCurrentTranslationState("en")
					EndIf


					If KEYMANAGER.isDown(KEY_LCONTROL)
						if KEYMANAGER.IsHit(KEY_O)
							GameConfig.observerMode = 1 - GameConfig.observerMode

							KEYMANAGER.ResetKey(KEY_O)
							KEYMANAGER.BlockKey(KEY_O, 150)
						endif
					endif


					If Not GetPlayer().GetFigure().isChangingRoom()
						if not KEYMANAGER.IsDown(KEY_LSHIFT) and not KEYMANAGER.IsDown(KEY_RSHIFT)
							if GameConfig.observerMode
								If KEYMANAGER.IsHit(KEY_1) Then GameConfig.SetObservedObject( GetPlayer(1).GetFigure() )
								If KEYMANAGER.IsHit(KEY_2) Then GameConfig.SetObservedObject( GetPlayer(2).GetFigure() )
								If KEYMANAGER.IsHit(KEY_3) Then GameConfig.SetObservedObject( GetPlayer(3).GetFigure() )
								If KEYMANAGER.IsHit(KEY_4) Then GameConfig.SetObservedObject( GetPlayer(4).GetFigure() )
							else
								If KEYMANAGER.IsHit(KEY_1) Then GetGame().SetActivePlayer(1)
								If KEYMANAGER.IsHit(KEY_2) Then GetGame().SetActivePlayer(2)
								If KEYMANAGER.IsHit(KEY_3) Then GetGame().SetActivePlayer(3)
								If KEYMANAGER.IsHit(KEY_4) Then GetGame().SetActivePlayer(4)
							endif
						elseif KEYMANAGER.IsDown(KEY_RSHIFT)
							If KEYMANAGER.IsHit(Key_1) And GetPlayer(1).isLocalAI() Then GetPlayer(1).PlayerAI.reloadScript()
							If KEYMANAGER.IsHit(Key_2) And GetPlayer(2).isLocalAI() Then GetPlayer(2).PlayerAI.reloadScript()
							If KEYMANAGER.IsHit(Key_3) And GetPlayer(3).isLocalAI() Then GetPlayer(3).PlayerAI.reloadScript()
							If KEYMANAGER.IsHit(Key_4) And GetPlayer(4).isLocalAI() Then GetPlayer(4).PlayerAI.reloadScript()
						else
							If KEYMANAGER.IsHit(KEY_1) then GetGame().SetPlayerBankrupt(1)
							If KEYMANAGER.IsHit(KEY_2) then GetGame().SetPlayerBankrupt(2)
							If KEYMANAGER.IsHit(KEY_3) then GetGame().SetPlayerBankrupt(3)
							If KEYMANAGER.IsHit(KEY_4) then GetGame().SetPlayerBankrupt(4)
						endif

						If KEYMANAGER.IsHit(KEY_W)
							if not KEYMANAGER.IsDown(KEY_LSHIFT) and not KEYMANAGER.IsDown(KEY_RSHIFT)
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("adagency") )
							endif
						endif
						If KEYMANAGER.IsHit(KEY_A) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("archive", "", GetPlayerCollection().playerID) )
						If KEYMANAGER.IsHit(KEY_B) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "betty") )
						If KEYMANAGER.IsHit(KEY_F)
							if not KEYMANAGER.IsDown(KEY_LSHIFT) and not KEYMANAGER.IsDown(KEY_RSHIFT)
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("movieagency"))
							endif
						endif
						If KEYMANAGER.IsHit(KEY_O) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "office", GetPlayerCollection().playerID))
						If KEYMANAGER.IsHit(KEY_C) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "boss", GetPlayerCollection().playerID))
						If KEYMANAGER.isHit(KEY_G) Then TVTGhostBuildingScrollMode = 1 - TVTGhostBuildingScrollMode

						If KEYMANAGER.Ishit(KEY_X)
							print "--- ROOM LOG ---"
							For local entry:string = EachIn GameEvents.roomLog
								print entry
							Next
							print "-- ROOM COUNT --"
							For local key:string = EachIn GameEvents.roomCount.Keys()
								print key+" : " + String(GameEvents.roomCount.ValueForKey(key))
							Next
							print "----------------"
						EndIf

rem
						If KEYMANAGER.isHit(KEY_X)
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
						If KEYMANAGER.isHit(KEY_S)
							If KEYMANAGER.IsDown(KEY_LCONTROL)
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "supermarket"))
							elseIf KEYMANAGER.IsDown(KEY_RCONTROL) or KEYMANAGER.IsDown(KEY_LALT)
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "scriptagency"))
							else
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("studio", "", GetPlayerCollection().playerID))
							endif
						endif
						If KEYMANAGER.IsHit(KEY_D) 'German "Drehbuchagentur"
							DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "scriptagency"))
						EndIf

						'e wie "employees" :D
						If KEYMANAGER.IsHit(KEY_E) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "credits"))
						If KEYMANAGER.IsHit(KEY_N) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "news", GetPlayerCollection().playerID))
						If KEYMANAGER.IsHit(KEY_R)
							If KEYMANAGER.IsDown(KEY_LCONTROL) or KEYMANAGER.IsDown(KEY_RCONTROL)
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "roomboard"))
							else
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("", "roomagency"))
							endif
						endif
					EndIf
				EndIf
				If KEYMANAGER.IsHit(KEY_5) Then GetGame().SetGameSpeed( 60*15 )  '60 virtual minutes per realtime second
				If KEYMANAGER.IsHit(KEY_6) Then GetGame().SetGameSpeed( 120*15 ) '120 minutes per second
				If KEYMANAGER.IsHit(KEY_7) Then GetGame().SetGameSpeed( 180*15 ) '180 minutes per second
				If KEYMANAGER.IsHit(KEY_8) Then GetGame().SetGameSpeed( 240*15 ) '240 minute per second
				If KEYMANAGER.IsHit(KEY_9) Then GetGame().SetGameSpeed( 1*15 )   '1 minute per second
				If KEYMANAGER.IsHit(KEY_Q) Then TVTDebugQuoteInfos = 1 - TVTDebugQuoteInfos
				if KEYMANAGER.IsDown(KEY_LALT) and KEYMANAGER.IsHit(KEY_M) then TVTDebugModifierInfos = 1 - TVTDebugModifierInfos

				If KEYMANAGER.IsHit(KEY_P)
					if KEYMANAGER.IsDown(KEY_LSHIFT)
						print GetBroadcastOverviewString()
					elseif KEYMANAGER.IsDown(KEY_RSHIFT)
						print "====== TOTAL BROADCAST OVERVIEW ======" + "~n"
						local result:string = ""
						For local day:int = GetWorldTime().GetStartDay() to GetworldTime().GetDay()
							result :+ GetBroadcastOverviewString(day)
						Next

						local logFile:TStream = WriteStream("utf8::" + "log.broadcastoverview.txt")
						logFile.WriteString(result)
						logFile.close()
						print result
						print "======================================"

					elseif KEYMANAGER.IsDown(KEY_LCONTROL)
						print "====== TOTAL PLAYER PERFORMANCE OVERVIEW ======" + "~n"
						local result:string = ""
						For local day:int = GetWorldTime().GetStartDay() to GetworldTime().GetDay()
							local text:string[] = GetPlayerPerformanceOverviewText(day)
							For local s:string = EachIn text
								result :+ s + "~n"
							Next
						Next

						local logFile:TStream = WriteStream("utf8::" + "log.playerperformanceoverview.txt")
						logFile.WriteString(result)
						logFile.close()

						print result
						print "==============================================="

					else
						GetPlayer().GetProgrammePlan().printOverview()
					endif
				endif

				'Save game only when in a game
				If GetGame().gamestate = TGame.STATE_RUNNING
					If KEYMANAGER.IsHit(KEY_F5) Then TSaveGame.Save("savegames/quicksave.xml")
					'If KEYMANAGER.IsHit(KEY_S) Then TSaveGame.Save("savegames/quicksave.xml")
				EndIf

				'If KEYMANAGER.IsHit(KEY_L)
				If KEYMANAGER.IsHit(KEY_F8)
					TSaveGame.Load("savegames/quicksave.xml")
				endif

				If KEYMANAGER.IsHit(KEY_TAB)
					if not KEYMANAGER.IsDown(KEY_LCONTROL)
						TVTDebugInfos = 1 - TVTDebugInfos
						TVTDebugProgrammePlan = False
					else
						TVTDebugInfos = False
						TVTDebugProgrammePlan = 1 - TVTDebugProgrammePlan
					endif
				endif

				If KEYMANAGER.Ishit(KEY_K)
					TLogger.Log("KickAllFromRooms", "Player kicks all figures out of the rooms.", LOG_DEBUG)
					For Local fig:TFigure = EachIn GetFigureCollection().entries.Values()
						If fig.GetInRoom()
							fig.KickOutOfRoom()
							'fig.KickOutOfRoom(GetPlayer().GetFigure())
						else
							print "fig: "+fig.name+" not in room."
						endif
					Next
				EndIf

				'send terrorist to a random room
				If KEYMANAGER.IsHit(KEY_T) And Not GetGame().networkGame
					Global whichTerrorist:Int = 1
					whichTerrorist = 1 - whichTerrorist

					Local targetRoom:TRoom
					Repeat
						targetRoom = GetRoomCollection().GetRandom()
					Until targetRoom.GetName() <> "building"
					print TFigureTerrorist(GetGame().terrorists[whichTerrorist]).name +" - deliver to : "+targetRoom.GetName() + " [id="+targetRoom.id+", owner="+targetRoom.owner+"]"
					TFigureTerrorist(GetGame().terrorists[whichTerrorist]).SetDeliverToRoom( targetRoom )
				EndIf

				'show ingame manual
				If KEYMANAGER.IsHit(KEY_F1) ' and not KEYMANAGER.IsDown(KEY_RSHIFT)
					'force show manual
					IngameHelpWindowCollection.ShowByHelpGUID("GameManual", True)
					'avoid that this window gets replaced by another one
					'until it is "closed"
					IngameHelpWindowCollection.LockCurrent()
				EndIf
				'show screen specific ingame help
				If KEYMANAGER.IsHit(KEY_F2)
					'force show manual
					IngameHelpWindowCollection.ShowByHelpGUID(ScreenCollection.GetCurrentScreen().GetName() , True)
					'avoid that this window gets replaced by another one
					'until it is "closed"
					IngameHelpWindowCollection.LockCurrent()
				EndIf

				If KEYMANAGER.Ishit(Key_F6) Then GetSoundManager().PlayMusicPlaylist("default")

				If KEYMANAGER.Ishit(Key_F11)
					If (TAiBase.AiRunning)
						TLogger.Log("CORE", "AI deactivated", LOG_INFO | LOG_DEV )
						TAiBase.AiRunning = False
					Else
						TLogger.Log("CORE", "AI activated", LOG_INFO | LOG_DEV )
						TAiBase.AiRunning = True
					EndIf
				EndIf
				If KEYMANAGER.Ishit(Key_F10)
					If (TAiBase.AiRunning)
						For Local fig:TFigure = EachIn GetFigureCollection().entries.Values()
							If GetPlayerBase().GetFigure() <> fig Then fig.moveable = False
						Next
						TLogger.Log("CORE", "AI Figures deactivated", LOG_INFO | LOG_DEV )
						TAiBase.AiRunning = False
					Else
						For Local fig:TFigure = EachIn GetFigureCollection().entries.Values()
							If GetPlayerBase().GetFigure() <> fig Then fig.moveable = True
						Next
						TLogger.Log("CORE", "AI activated", LOG_INFO | LOG_DEV )
						TAiBase.AiRunning = True
					EndIf
				EndIf
			EndIf
		EndIf


		TError.UpdateErrors()
		GetGameBase().cursorstate = 0

		ScreenCollection.UpdateCurrent(GetDeltaTimer().GetDelta())

		local openEscapeMenu:int = openEscapeMenuViaInterface or (Not GuiManager.GetKeystrokeReceiver() And KEYWRAPPER.hitKey(KEY_ESCAPE))
		'no escape menu in start screen or settingsscreen
		if GetGame().gamestate = TGame.STATE_MAINMENU or GetGame().gamestate = TGame.STATE_SETTINGSMENU
			openEscapeMenu = False
		endif

		'force open escape menu (if eg. borked)
		if KEYMANAGER.IsDown(KEY_LCONTROL) and KEYWRAPPER.hitKey(KEY_ESCAPE)
			openEscapeMenu = True
			print "force open escape menu. gamestate="+GetGame().gamestate +"   keystrokereceiver: " + (GuiManager.GetKeystrokeReceiver() <> null)
		endif

		If openEscapeMenu
			'print "should open escape menu. gamestate="+GetGame().gamestate

			'ask to exit to main menu
			'TApp.CreateConfirmExitAppDialogue(True)
			If GetGame().gamestate = TGame.STATE_RUNNING
				'RONNY: debug
				if openEscapeMenuViaInterface
					TLogger.Log("Dialogues", "Open Escape-Menu via button hit.", LOG_DEBUG)
				else
					TLogger.Log("Dialogues", "Open Escape-Menu via ESC key hit.", LOG_DEBUG)
				endif

				'TApp.CreateConfirmExitAppDialogue(True)
				'create escape-menu
				TApp.CreateEscapeMenuwindow()
			else
				TLogger.Log("Dialogues", "Open Escape menu from a gamestate<>STATE_RUNNING!", LOG_DEBUG)
				'ask to exit the app - from main menu?
				'TApp.CreateConfirmExitAppDialogue(False)
			endif
			openEscapeMenuViaInterface = False
		EndIf
		'Force-quit with CTRL+C
		if KEYMANAGER.IsDown(KEY_LCONTROL) and KEYMANAGER.IsHit(KEY_C)
			TApp.ExitApp = True
		endif

		If AppTerminate()
			if not TApp.ExitAppDialogue
				'ask to exit the app
				TApp.CreateConfirmExitAppDialogue(False)
			else
				TLogger.Log("Dialogues", "Skip opening Exit-dialogue, was opened <100ms before.", LOG_DEBUG)
			endif
		endif

		'check if we need to make a screenshot
		If KEYMANAGER.IsHit(KEY_F12) Then App.prepareScreenshot = 1

		If GetGame().networkGame Then Network.Update()


		'in single player: pause game
		if Not GetGame().networkgame
			If not GetGame().IsPaused() and App.pausedBy > 0
				GetGame().SetPaused(True)
			endif
		endif

		if GetGame().IsPaused() and App.pausedBy = 0
			GetGame().SetPaused(False)
		endif


		GUIManager.EndUpdates() 'reset modal window states

		TProfiler.Leave("Update")
	End Function



	Function RenderDevOSD()
		Local textX:Int = 5
		Local oldCol:TColor = New TColor.Get()
		SetAlpha oldCol.a * 0.25
		SetColor 0,0,0
		If GameRules.devConfig.GetBool("DEV_OSD", False)
			DrawRect(0,0, 800,13)
		Else
			DrawRect(0,0, 175,13)
		EndIf
		oldCol.SetRGBA()

		GetBitmapFontManager().baseFont.drawStyled("Speed:" + Int(GetWorldTime().GetVirtualMinutesPerSecond() * 100), textX , 0)
		textX:+75
		GetBitmapFontManager().baseFont.draw("FPS: "+GetDeltaTimer().currentFps, textX, 0)
		textX:+50
		GetBitmapFontManager().baseFont.draw("UPS: " + Int(GetDeltaTimer().currentUps), textX,0)
		textX:+50

		If GameRules.devConfig.GetBool("DEV_OSD", False)
			GetBitmapFontManager().baseFont.draw("Loop: "+Int(GetDeltaTimer().getLoopTimeAverage())+"ms", textX,0)
			textX:+85
			'update time per second
			GetBitmapFontManager().baseFont.draw("UTPS: " + Int(GetDeltaTimer()._currentUpdateTimePerSecond), textX,0)
			textX:+65
			'render time per second
			GetBitmapFontManager().baseFont.draw("RTPS: " + Int(GetDeltaTimer()._currentRenderTimePerSecond), textX,0)
			textX:+65

			GetBitmapFontManager().baseFont.draw("gobject-Max: "+ TGameObject.lastID, textX,0)
			textX:+115

			'RON: debug purpose - see if the managed guielements list increase over time
			If TGUIObject.GetFocusedObject()
				GetBitmapFontManager().baseFont.draw("GUI objects: "+ GUIManager.list.count()+"[d:"+GUIManager.GetDraggedCount()+"] focused: "+TGUIObject.GetFocusedObject()._id, textX,0)
			Else
				GetBitmapFontManager().baseFont.draw("GUI objects: "+ GUIManager.list.count()+"[d:"+GUIManager.GetDraggedCount()+"]" , textX,0)
			EndIf
			textX:+170

			If GetGame().networkgame And Network.client
				GetBitmapFontManager().baseFont.draw("Ping: "+Int(Network.client.latency)+"ms", textX,0)
				textX:+50
			EndIf
		EndIf
	End Function


	Function RenderSideDebug()
		SetAlpha GetAlpha() * 0.5
		SetColor 0,0,0
		DrawRect(0,0,160,385)
		SetColor 255, 255, 255
		SetAlpha GetAlpha() * 2.0
		GetBitmapFontManager().baseFontBold.draw("Debug information:", 5,10)
		GetBitmapFontManager().baseFont.draw("Renderer: "+GetGraphicsManager().GetRendererName(), 5,30)

		'GetBitmapFontManager().baseFont.draw(Network.stream.UDPSpeedString(), 662,490)
		GetBitmapFontManager().baseFont.draw("Player positions:", 5,55)
		Local roomName:String = ""
		Local fig:TFigure
		For Local i:Int = 0 To 3
			fig = GetPlayerCollection().Get(i+1).GetFigure()

			local change:string = ""
			if fig.isChangingRoom()
				if fig.inRoom
					change = "<-[]" 'Chr(8646) '⇆
				else
					change = "->[]" 'Chr(8646) '⇆
				endif
			endif

			roomName = "Building"
			If fig.inRoom
				roomName = fig.inRoom.GetName()
			ElseIf fig.IsInElevator()
				roomName = "InElevator"
			ElseIf fig.IsAtElevator()
				roomName = "AtElevator"
			EndIf
			if fig.isControllable()
				GetBitmapFontManager().baseFont.draw("P " + (i + 1) + ": "+roomName+change , 5, 70 + i * 11)
			else
				GetBitmapFontManager().baseFont.draw("P " + (i + 1) + ": "+roomName+change +" (forced)" , 5, 70 + i * 11)
			endif
		Next

		If ScreenCollection.GetCurrentScreen()
			GetBitmapFontManager().baseFont.draw("onScreen: "+ScreenCollection.GetCurrentScreen().name, 5, 120)
		Else
			GetBitmapFontManager().baseFont.draw("onScreen: Main", 5, 120)
		EndIf


		GetBitmapFontManager().baseFont.draw("Elevator routes:", 5,140)
		Local routepos:Int = 0
		Local startY:Int = 155
		If GetGame().networkgame Then startY :+ 4*11

		Local callType:String = ""

		Local directionString:String = "up"
		If GetElevator().Direction = 1 Then directionString = "down"
		Local debugString:String =	"floor:" + GetElevator().currentFloor +..
									"->" + GetElevator().targetFloor +..
									" status:"+GetElevator().ElevatorStatus

		GetBitmapFontManager().baseFont.draw(debugString, 5, startY)


		If GetElevator().RouteLogic.GetSortedRouteList() <> Null
			For Local FloorRoute:TFloorRoute = EachIn GetElevator().RouteLogic.GetSortedRouteList()
				If floorroute.call = 0 Then callType = " 'send' " Else callType= " 'call' "
				GetBitmapFontManager().baseFont.draw(FloorRoute.floornumber + callType + FloorRoute.who.Name, 5, startY + 15 + routepos * 11)
				routepos:+1
			Next
		Else
			GetBitmapFontManager().baseFont.draw("recalculate", 5, startY + 15)
		EndIf


		For Local i:Int = 0 To 3
			GetBitmapFontManager().baseFont.Draw("Image #"+i+": "+MathHelper.NumberToString(GetPublicImageCollection().Get(i+1).GetAverageImage(), 4)+" %", 10, 320 + i*13)
		Next

		For Local i:Int = 0 To 3
			GetBitmapFontManager().baseFont.Draw("Boss #"+i+": "+MathHelper.NumberToString(GetPlayerBoss(i+1).mood,4), 10, 270 + i*13)
		Next


		'GetBitmapFontManager().baseFont.Draw("NewsEvents: "+GetNewsEventCollection().managedNewsEvents.count(), 680, 300)
		For Local i:Int = 0 To 3
			GetBitmapFontManager().baseFont.Draw("News #"+i+": "+GetPlayerProgrammeCollection(i+1).news.count(), 680, 320 + i*13)
		Next

		GetWorld().RenderDebug(660,0, 140, 180)
		'GetPlayer().GetFigure().RenderDebug(new TVec2D.Init(660, 150))
	End Function


	Function UpdateDebugControls()
		If GetGame().gamestate <> TGame.STATE_RUNNING then return

		if TVTDebugProgrammePlan
			local playerID:int = GetPlayerBaseCollection().GetObservedPlayerID()
			if GetInGameInterface().ShowChannel > 0
				playerID = GetInGameInterface().ShowChannel
			endif
			if playerID <= 0 then playerID = GetPlayerBase().playerID

			debugProgrammePlanInfos.Update(playerID, 15, 15)
			debugProgrammeCollectionInfos.Update(playerID, 415, 15)
			debugPlayerControls.Update(playerID, 15, 365)
		endif
	End Function


	Function RenderDebugControls()
		If GetGame().gamestate <> TGame.STATE_RUNNING then return

		if TVTDebugInfos And Not GetPlayer().GetFigure().inRoom
			RenderSideDebug()

		'show quotes even without "DEV_OSD = true"
		elseIf TVTDebugQuoteInfos
			debugAudienceInfos.Draw()
		elseIf TVTDebugModifierInfos
			debugModifierInfos.Draw()

		elseif TVTDebugProgrammePlan
			local playerID:int = GetPlayerBaseCollection().GetObservedPlayerID()
			if GetInGameInterface().ShowChannel > 0
				playerID = GetInGameInterface().ShowChannel
			endif
			if playerID <= 0 then playerID = GetPlayerBase().playerID

			debugProgrammePlanInfos.Draw(playerID, 15, 15)
			debugProgrammeCollectionInfos.Draw(playerID, 415, 15)
			debugPlayerControls.Draw(playerID, 15, 365)

			local player:TPlayer = GetPlayer(playerID)
			rem
			if player.playerAI
				SetColor 50,40,0
				DrawRect(235, 313, 150, 36)
				SetColor 255,255,255
				local assignmentType:int = player.aiData.GetInt("currentTaskAssignmentType", 0)
				if assignmentType = 1
					GetBitmapFont("default", 10).Draw("Task: [F] " + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", 238,315)
				elseif assignmentType = 2
					GetBitmapFont("default", 10).Draw("Task: [R]" + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", 238,315)
				else
					GetBitmapFont("default", 10).Draw("Task: " + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", 238,315)
				endif
				GetBitmapFont("default", 10).Draw("Job:   " + player.aiData.GetString("currentTaskJob") + " ["+player.aiData.GetString("currentTaskJobStatus")+"]", 238,325)
			endif
			endrem

			local font:TBitmapFont = GetBitmapFont("default", 10)
			local fontB:TBitmapFont = GetBitmapFont("default", 10, BOLDFONT)
			if player.playerAI
				SetColor 40,40,40
				DrawRect(605, 240, 185, 135)
				SetColor 50,50,40
				DrawRect(606, 241, 183, 23)
				SetColor 255,255,255

				local textX:int = 605 + 3
				local textY:int = 240 + 3

				local assignmentType:int = player.aiData.GetInt("currentTaskAssignmentType", 0)
				if assignmentType = 1
					font.Draw("Task: [F] " + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", textX, textY)
				elseif assignmentType = 2
					font.Draw("Task: [R]" + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", textX, textY)
				else
					font.Draw("Task: " + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", textX, textY)
				endif
				textY :+ 10
				font.Draw("Job:   " + player.aiData.GetString("currentTaskJob") + " ["+player.aiData.GetString("currentTaskJobStatus")+"]", textX, textY)
				textY :+ 13

				fontB.Draw("Task List: ", textX, textY)
				fontB.Draw("Prio ", textX + 90 + 22*0, textY)
				fontB.Draw("Bas", textX + 90 + 22*1, textY)
				fontB.Draw("Sit", textX + 90 + 22*2, textY)
				fontB.Draw("Req", textX + 90 + 22*3, textY)
				textY :+ 10 + 2

				for local taskNumber:int = 1 to player.aiData.GetInt("tasklist_count", 1)
					font.Draw(player.aiData.GetString("tasklist_name"+taskNumber).Replace("Task", ""), textX, textY)
					font.Draw(player.aiData.GetInt("tasklist_priority"+taskNumber), textX + 90 + 22*0, textY)
					font.Draw(player.aiData.GetInt("tasklist_basepriority"+taskNumber), textX + 90 + 22*1, textY)
					font.Draw(player.aiData.GetInt("tasklist_situationpriority"+taskNumber), textX + 90 + 22*2, textY)
					font.Draw(player.aiData.GetInt("tasklist_requisitionpriority"+taskNumber), textX + 90 + 22*3, textY)
					textY :+ 10
				next
			endif

			debugFinancialInfos.Draw(-1, 235, 305)
'				debugProgrammePlanInfos.Draw((playerID + 1) mod 4, 415, 15)

rem
			local textX:int = 10
			local textY:int = 350
			SetColor 0,0,0
			DrawRect(textX, textY, 200, 150)
			SetColor 255,255,255
			For local playerID:int = 1 to 4
				font.Draw("Player "+playerID, textX, textY)
				textY :+ 10
			Next
endrem
		endif
	End Function


	Function Render:Int()
		'cls only needed if virtual resolution is enabled, else the
		'background covers everything
		If GetGraphicsManager().HasBlackBars()
			SetClsColor 0,0,0
			'use graphicsmanager's cls as it resets virtual resolution
			'first
			'Cls()
			GetGraphicsManager().Cls()
		Endif

		TProfiler.Enter("Draw")
		ScreenCollection.DrawCurrent(GetDeltaTimer().GetTween())

		'=== RENDER TOASTMESSAGES ===
		'below everything else of the interface: our toastmessages
		GetToastMessageCollection().Render(0,0)


		'=== RENDER INGAME HELP ===
		IngameHelpWindowCollection.Render()


		RenderDevOSD()


		If GetGame().gamestate = TGame.STATE_RUNNING
			if not TAiBase.AiRunning
				local oldCol:TColor = new TColor.Get()
				SetColor 100,40,40
				SetAlpha 0.65
				DrawRect(275,0,250,35)
				oldCol.SetRGBA()
				GetBitmapFont("default", 16).DrawBlock("PLAYER AI DEACTIVATED", 0, 5, GetGraphicsManager().GetWidth(), 355, ALIGN_CENTER_TOP, TColor.clWhite, TBitmapFont.STYLE_SHADOW)
				GetBitmapFont("default", 12).DrawBlock("(~qF11~q to reactivate AI)", 0, 20, GetGraphicsManager().GetWidth(), 355, ALIGN_CENTER_TOP, TColor.clWhite, TBitmapFont.STYLE_SHADOW)
			endif

			if GameConfig.observerMode
				local playerNum:int = 0
				For local i:int = 1 to 4
					if GameConfig.IsObserved( GetPlayer(i).GetFigure() )
						playerNum = i
						exit
					endif
				Next
				GetBitmapFont("default", 20).DrawBlock("OBSERVING PLAYER #"+playerNum, 0, 0, GetGraphicsManager().GetWidth(), 355, ALIGN_CENTER_BOTTOM, TColor.clWhite, TBitmapFont.STYLE_SHADOW)
				GetBitmapFont("default", 14).DrawBlock("(~qL-Ctrl + O~q to deactivate)", 0, 0, GetGraphicsManager().GetWidth(), 375, ALIGN_CENTER_BOTTOM, TColor.clWhite, TBitmapFont.STYLE_SHADOW)
			else
				if not GetPlayerCollection().IsHuman( GetPlayerCollection().playerID )
					local oldCol:TColor = new TColor.Get()
					SetColor 60,60,40
					SetAlpha 0.65
					DrawRect(275,345,250,35)
					oldCol.SetRGBA()

					GetBitmapFont("default", 16).DrawBlock("SWITCHED TO AI PLAYER #" +GetPlayerCollection().playerID, 0, 0, GetGraphicsManager().GetWidth(), 365, ALIGN_CENTER_BOTTOM, TColor.clWhite, TBitmapFont.STYLE_SHADOW)

					local localHumanNum:int = 0
					For local i:int = 1 to 4
						if GetPlayer(i).playerType = TPlayerBase.PLAYERTYPE_LOCAL_HUMAN
							localHumanNum = i
							exit
						endif
					Next

					if localHumanNum > 0
						GetBitmapFont("default", 12).DrawBlock("(~q"+localHumanNum+"~q to switch back)", 0, 0, GetGraphicsManager().GetWidth(), 380, ALIGN_CENTER_BOTTOM, TColor.clWhite, TBitmapFont.STYLE_SHADOW)
					else
						GetBitmapFont("default", 12).DrawBlock("(all players are AI controlled)", 0, 0, GetGraphicsManager().GetWidth(), 380, ALIGN_CENTER_BOTTOM, TColor.clWhite, TBitmapFont.STYLE_SHADOW)
					endif
				endif
			endif
		endif

		'rendder debug views and control buttons
		RenderDebugControls()

		'draw loading resource information
		RenderLoadingResourcesInformation()


		'draw system things at last (-> on top)
		GUIManager.Draw(systemState)

		If GetGameBase().cursorstate = 0 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-9,  MouseManager.y-2,  0)
		'open hand
		If GetGameBase().cursorstate = 1 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11, MouseManager.y-8,  1)
		'grabbing hand
		If GetGameBase().cursorstate = 2 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11, MouseManager.y-16, 2)
		'open hand blocked
		If GetGameBase().cursorstate = 3 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11, MouseManager.y-8	,  3)

		'if a screenshot is generated, draw a logo in
		If App.prepareScreenshot = 1
			App.SaveScreenshot(GetSpriteFromRegistry("gfx_startscreen_logoSmall"))
			App.prepareScreenshot = False
		EndIf
rem

		SetColor 100,0,0
		DrawRect(0,520,250,80)
		SetColor 255,255,255
		GetBitmapFont("Default", 16).Draw("[x] wurde "+ appTerminateRegistered+"x geklickt.", 20, 525)
		if not App.pausedBy
			GetBitmapFont("Default", 16).Draw("Keine Pause", 20, 540)
		else
			GetBitmapFont("Default", 16).Draw("Grund fuer Pause: "+ App.pausedBy, 20, 540)
		endif
		if App.ExitAppDialogue
			GetBitmapFont("Default", 16).Draw("ExitDialog existiert", 20, 555)
		else
			GetBitmapFont("Default", 16).Draw("kein ExitDialog vorhanden", 20, 555)
		endif
		if App.EscapeMenuWindow
			GetBitmapFont("Default", 16).Draw("EscapeMenue existiert", 20, 570)
		else
			GetBitmapFont("Default", 16).Draw("kein EscapeMenue vorhanden", 20, 570)
		endif
endrem

		GetGraphicsManager().Flip(GetDeltaTimer().HasLimitedFPS())

		TProfiler.Leave("Draw")
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
			print "Removed forgotten dragged element " + obj.GetClassName()
		Next

		EscapeMenuWindowTime = Time.MilliSecsLong()

		App.SetPausedBy(TApp.PAUSED_BY_ESCAPEMENU)

		TGUISavegameListItem.SetTypeFont(GetBitmapFont(""))

		EscapeMenuWindow = New TGUIModalWindowChain.Create(New TVec2D, New TVec2D.Init(400,130), "SYSTEM")
		EscapeMenuWindow.SetZIndex(99000)
		EscapeMenuWindow.SetCenterLimit(new TRectangle.setTLBR(20,0,0,0))

		'append menu after creation of screen area, so it recenters properly
		'355 = with speed buttons
		'local mainMenu:TGUIModalMainMenu = New TGUIModalMainMenu.Create(New TVec2D, New TVec2D.Init(300,355), "SYSTEM")
		local mainMenu:TGUIModalMainMenu = New TGUIModalMainMenu.Create(New TVec2D, New TVec2D.Init(300,315), "SYSTEM")
		mainMenu.SetCaption(GetLocale("MENU"))

		EscapeMenuWindow.SetContentElement(mainMenu)

		'menu is always ingame...
		EscapeMenuWindow.SetDarkenedArea( GameConfig.nonInterfaceRect.Copy() )
		'center to this area
		EscapeMenuWindow.SetScreenArea( GameConfig.nonInterfaceRect.Copy() )
	End Function


	Function onCloseModalDialogue:Int(triggerEvent:TEventBase)
'		If App.settingsWindow and dialogue = App.settingsWindow.modalDialogue
		If App.settingsWindow and App.settingsWindow.modalDialogue = triggerEvent.GetSender()
			return onCloseSettingsWindow(triggerEvent)
		elseif ExitAppDialogue = triggerEvent.GetSender()
			return onAppConfirmExit(triggerEvent)
		endif
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
rem
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
			local quitToMainMenu:int = ExitAppDialogue.data.GetInt("quitToMainMenu", True)
			'if within a game - just return to mainmenu
			if GetGame().gamestate = TGame.STATE_RUNNING and quitToMainMenu
				'adjust darkened Area to fullscreen!
				'but do not set new screenArea to avoid "jumping"
				ExitAppDialogue.darkenedArea = New TRectangle.Init(0,0,800,600)
				'ExitAppDialogue.screenArea = New TRectangle.Init(0,0,800,600)

				GetGame().EndGame()
			else
				TApp.ExitApp = True
			endif
		EndIf
		'remove connection to global value (guimanager takes care of fading)
		TApp.ExitAppDialogue = Null

		App.SetPausedBy(TApp.PAUSED_BY_EXITDIALOGUE, False)

		Return True
	End Function


	Function CreateConfirmExitAppDialogue:Int(quitToMainMenu:int=True)
		'100ms since last dialogue
		If Time.MilliSecsLong() - ExitAppDialogueTime < 100
			TLogger.Log("Dialogues", "Skip opening Exit-dialogue, was opened <100ms before.", LOG_DEBUG)
			Return False
		endif

		TLogger.Log("Dialogues", "User hit [x], create Exit-dialogue.", LOG_DEBUG)


		ExitAppDialogueTime = Time.MilliSecsLong()

		App.SetPausedBy(TApp.PAUSED_BY_EXITDIALOGUE)

		ExitAppDialogue = New TGUIGameModalWindow.Create(New TVec2D, New TVec2D.Init(400,150), "SYSTEM")
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

		if GetGame().gamestate = TGame.STATE_RUNNING and quitToMainMenu
			ExitAppDialogue.SetCaptionAndValue( GetLocale("ALREADY_OVER"), GetLocale("DO_YOU_REALLY_WANT_TO_QUIT_THE_GAME_AND_RETURN_TO_STARTSCREEN") )
		else
			ExitAppDialogue.SetCaptionAndValue( GetLocale("ALREADY_OVER"), GetLocale("DO_YOU_REALLY_WANT_TO_QUIT") )
		endif
	End Function

End Type


'just an object holding all data which has to get saved
'it is kind of an "DataCollectionCollection" ;D
Type TGameState
	Field _gameSummary:TData = Null
	Field _Game:TGame = Null
	Field _BuildingTime:TBuildingTime = Null
	Field _WorldTime:TWorldTime = Null
	Field _World:TWorld = Null
	Field _GameRules:TGamerules = Null
	Field _GameConfig:TGameConfig = Null
	Field _Betty:TBetty = Null
	Field _AwardCollection:TAwardCollection = Null
	Field _NewsEventSportCollection:TNewsEventSportCollection = Null

	Field _GameModifierManager:TGameModifierManager = null
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
	Field _ProgrammePersonBaseCollection:TProgrammePersonBaseCollection = Null
	Field _ProgrammeDataCollection:TProgrammeDataCollection = Null
	Field _ProgrammeLicenceCollection:TProgrammeLicenceCollection = Null

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
	Field _PlayerColorList:TList
	Field _CurrentScreenName:String
	Field _adAgencySortMode:int
	Field _officeProgrammeSortMode:int
	Field _officeProgrammeSortDirection:int
	Field _officeContractSortMode:int
	Field _officeContractSortDirection:int
	Field _programmeDataIgnoreUnreleasedProgrammes:int = False
	Field _programmeDataFilterReleaseDateStart:int = False
	Field _programmeDataFilterReleaseDateEnd:int = False
	Field _interface_ShowChannel:int = 0
	Field _interface_ChatShow:int = 0
	Field _interface_ChatShowHideLocked:int = 0
	Field _aiBase_AiRunning:int = False
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
		GetProgrammePersonBaseCollection().Initialize()
		GetProgrammeDataCollection().Initialize()
		GetProgrammeLicenceCollection().Initialize()
		TAuctionProgrammeBlocks.Initialize()
		GetNewsEventTemplateCollection().Initialize()
		GetNewsEventCollection().Initialize()

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


		if TScreenHandler_ProgrammePlanner.PPprogrammeList
			TScreenHandler_ProgrammePlanner.PPprogrammeList.Initialize()
		endif
		if TScreenHandler_ProgrammePlanner.PPcontractList
			TScreenHandler_ProgrammePlanner.PPcontractList.Initialize()
		endif
	End Method


	Method RestoreGameData:Int()
		_Assign(_FigureCollection, TFigureCollection._instance, "FigureCollection", MODE_LOAD)
		_Assign(_RoomDoorBaseCollection, TRoomDoorBaseCollection._instance, "RoomDoorBaseCollection", MODE_LOAD)
		_Assign(_RoomBaseCollection, TRoomBaseCollection._instance, "RoomBaseCollection", MODE_LOAD)

		_Assign(_PlayerColorList, TPlayerColor.List, "PlayerColorList", MODE_LOAD)
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
		_Assign(_ProgrammePersonBaseCollection, TProgrammePersonBaseCollection._instance, "ProgrammePersonBaseCollection", MODE_LOAD)
		_Assign(_ProgrammeDataCollection, TProgrammeDataCollection._instance, "ProgrammeDataCollection", MODE_LOAD)
		_Assign(_ProgrammeLicenceCollection, TProgrammeLicenceCollection._instance, "ProgrammeLicenceCollection", MODE_LOAD)

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
		_Assign(_World, TWorld._instance, "World", MODE_LOAD)
		_Assign(_WorldTime, TWorldTime._instance, "WorldTime", MODE_LOAD)
		_Assign(_BuildingTime, TBuildingTime._instance, "BuildingTime", MODE_LOAD)
		_Assign(_GameRules, GameRules, "GameRules", MODE_LOAD)
		_Assign(_GameConfig, GameConfig, "GameConfig", MODE_LOAD)
		_Assign(_AuctionProgrammeBlocksList, TAuctionProgrammeBlocks.list, "AuctionProgrammeBlocks", MODE_LOAD)

		_Assign(_RoomHandler_Studio, RoomHandler_Studio._instance, "Studios", MODE_LOAD)
		_Assign(_RoomHandler_MovieAgency, RoomHandler_MovieAgency._instance, "MovieAgency", MODE_LOAD)
		_Assign(_RoomHandler_AdAgency, RoomHandler_AdAgency._instance, "AdAgency", MODE_LOAD)
		_Assign(_RoomHandler_ScriptAgency, RoomHandler_ScriptAgency._instance, "ScriptAgency", MODE_LOAD)
		_Assign(_RoomHandler_News, RoomHandler_News._instance, "News", MODE_LOAD)
		_Assign(_Game, TGame._instance, "Game")


		RoomHandler_AdAgency.ListSortMode = _adAgencySortMode
		TScreenHandler_ProgrammePlanner.PPprogrammeList.ListSortMode = _officeProgrammeSortMode
		TScreenHandler_ProgrammePlanner.PPprogrammeList.ListSortDirection = _officeProgrammeSortDirection
		TScreenHandler_ProgrammePlanner.PPcontractList.ListSortMode = _officeContractSortMode
		TScreenHandler_ProgrammePlanner.PPcontractList.ListSortDirection = _officeContractSortDirection

		TProgrammeData.ignoreUnreleasedProgrammes = _programmeDataIgnoreUnreleasedProgrammes
		TProgrammeData._filterReleaseDateStart = _programmeDataFilterReleaseDateStart
		TProgrammeData._filterReleaseDateEnd = _programmeDataFilterReleaseDateEnd

		GetInGameInterface().ShowChannel = _interface_ShowChannel
		GetInGameInterface().ChatShow = _interface_ChatShow
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

		_programmeDataIgnoreUnreleasedProgrammes = TProgrammeData.ignoreUnreleasedProgrammes
		_programmeDataFilterReleaseDateStart = TProgrammeData._filterReleaseDateStart
		_programmeDataFilterReleaseDateEnd = TProgrammeData._filterReleaseDateEnd

		_interface_ShowChannel = GetInGameInterface().ShowChannel
		_interface_ChatShow = GetInGameInterface().ChatShow
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
		_Assign(TProgrammePersonBaseCollection._instance, _ProgrammePersonBaseCollection, "ProgrammePersonBaseCollection", MODE_SAVE)
		_Assign(TProgrammeRoleCollection._instance, _ProgrammeRoleCollection, "ProgrammeRoleCollection", MODE_SAVE)

		'database data for programmes
		_Assign(TProgrammeDataCollection._instance, _ProgrammeDataCollection, "ProgrammeDataCollection", MODE_SAVE)
		_Assign(TProgrammeLicenceCollection._instance, _ProgrammeLicenceCollection, "ProgrammeLicenceCollection", MODE_SAVE)

		_Assign(TPlayerColor.List, _PlayerColorList, "PlayerColorList", MODE_SAVE)
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
		_Assign(TWorld._instance, _World, "World", MODE_SAVE)
		_Assign(TAuctionProgrammeBlocks.list, _AuctionProgrammeBlocksList, "AuctionProgrammeBlocks", MODE_SAVE)
		'special room data
		_Assign(RoomHandler_Studio._instance, _RoomHandler_Studio, "Studios", MODE_SAVE)
		_Assign(RoomHandler_MovieAgency._instance, _RoomHandler_MovieAgency, "MovieAgency", MODE_SAVE)
		_Assign(RoomHandler_AdAgency._instance, _RoomHandler_AdAgency, "AdAgency", MODE_SAVE)
		_Assign(RoomHandler_ScriptAgency._instance, _RoomHandler_ScriptAgency, "ScriptAgency", MODE_SAVE)
		_Assign(RoomHandler_News._instance, _RoomHandler_News, "News", MODE_SAVE)
	End Method


	Method _Assign(objSource:Object Var, objTarget:Object Var, name:String="DATA", mode:Int=0)
		If objSource
			objTarget = objSource
			If mode = MODE_LOAD
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
	Const SAVEGAME_VERSION:string = "12"
	Const MIN_SAVEGAME_VERSION:string = "11"
	Global messageWindow:TGUIModalWindow
	Global messageWindowBackground:TPixmap
	Global messageWindowLastUpdate:Long
	Global messageWindowUpdatesSkipped:int = 0

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
		_gameSummary = new TData
		_gameSummary.Add("game_version", VersionString)
		_gameSummary.Add("game_builddate", VersionDate)
		_gameSummary.Add("game_mode", "singleplayer")
		_gameSummary.AddNumber("game_timeGone", GetWorldTime().GetTimeGone())
		_gameSummary.Add("player_name", GetPlayer().name)
		_gameSummary.Add("player_channelName", GetPlayer().channelName)
		_gameSummary.AddNumber("player_money", GetPlayer().GetMoney())
		_gameSummary.Add("savegame_version", SAVEGAME_VERSION)
		'store last ID of all entities, to avoid duplicates
		'store them in game summary to be able to reset before "restore"
		'takes place
		'- game 1 run till ID 1000 and is saved then
		'- whole game is restarted then, ID is again 0
		'- load in game 1 (having game objects with ID 1 - 1000)
		'- new entities would again get ID 1 - 1000
		'  -> duplicates
		_gameSummary.AddNumber("entitybase_lastID", TEntityBase.lastID)
		_gameSummary.AddNumber("gameobject_lastID", TGameObject.LastID)

		Super.BackupGameData()

		'store "time gone since start"
		_Time_timeGone = Time.GetTimeGone()
		'store entity speed
		_Entity_globalWorldSpeedFactor = TEntity.globalWorldSpeedFactor
		_Entity_globalWorldSpeedFactorMod = TEntity.globalWorldSpeedFactorMod
	End Method


	'override to output differing log texts
	Method _Assign(objSource:Object Var, objTarget:Object Var, name:String="DATA", mode:Int=0)
		If objSource
			objTarget = objSource

			'uncommented log and update message as the real work is
			'done in the serialization and not in variable=otherVariable
			'assignments
			If mode = MODE_LOAD
				'TLogger.Log("TSaveGame.RestoreGameData()", "Loaded object "+name, LOG_DEBUG | LOG_SAVELOAD)
				'UpdateMessage(True, "Loading: " + name)
			Else
				'TLogger.Log("TSaveGame.BackupGameData()", "Saved object "+name, LOG_DEBUG | LOG_SAVELOAD)
				'UpdateMessage(False, "Saving: " + name)
			EndIf
		Else
			TLogger.Log("TSaveGame", "object "+name+" was NULL - ignored", LOG_DEBUG | LOG_SAVELOAD)
		EndIf
	End Method


	Method CheckGameData:Int()
		'check if all data is available
		Return True
	End Method


	Function UpdateMessage:Int(Load:Int=False, text:string="", progress:Float=0.0, forceUpdate:int=False)
		'skip update if called too often (as it is still FPS limited ... !)
		if not forceUpdate and Time.GetAppTimeGone() - messageWindowLastUpdate < 25 and messageWindowUpdatesSkipped < 5
			messageWindowUpdatesSkipped :+ 1
			return False
		else
			messageWindowUpdatesSkipped = 0
			messageWindowLastUpdate = Time.GetAppTimeGone()
		endif

		if not messageWindowBackground
			messageWindowBackground = VirtualGrabPixmap(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight() )
		endif

		SetClsColor 0,0,0
		'use graphicsmanager's cls as it resets virtual resolution first
		GetGraphicsManager().Cls()
		DrawPixmap(messageWindowBackground, 0,0)

		if load
			messageWindow.SetValue( getLocale("SAVEGAME_GETS_LOADED") + "~n" + text)
		else
			messageWindow.SetValue( getLocale("SAVEGAME_GETS_CREATED") + "~n" + text )
		endif

		messageWindow.Update()
		messageWindow.Draw()

		Flip 0
	End Function


	Function ShowMessage:Int(Load:Int=False, text:string="", progress:Float=0.0)
		'grab a fresh copy
		messageWindowBackground = VirtualGrabPixmap(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight() )

		if messageWindow then messageWindow.Remove()

		'create a new one
		messageWindow = new TGUIGameModalWindow.Create(null, New TVec2D.Init(400, 100), "SYSTEM")
		messageWindow.guiCaptionTextBox.SetFont(headerFont)
		messageWindow._defaultValueColor = TColor.clBlack.copy()
		messageWindow.defaultCaptionColor = TColor.clWhite.copy()
		messageWindow.SetCaptionArea(New TRectangle.Init(-1,10,-1,25))
		messageWindow.guiCaptionTextBox.SetValueAlignment( ALIGN_CENTER_TOP )
		'no buttons
		messageWindow.SetDialogueType(0)
		'use a non-button-background
		messageWindow.guiBackground.spriteBaseName = "gfx_gui_window"



		if GetGame().gamestate = TGame.STATE_RUNNING
			messageWindow.darkenedArea = New TRectangle.Init(0,0,800,385)
			messageWindow.screenArea = New TRectangle.Init(0,0,800,385)
		else
			messageWindow.darkenedArea = null
			messageWindow.screenArea = null
		endif

		messageWindow.SetCaption( getLocale("PLEASE_BE_PATIENT") )

		if load
			messageWindow.SetValue( getLocale("SAVEGAME_GETS_LOADED") + "~n" + text)
		else
			messageWindow.SetValue( getLocale("SAVEGAME_GETS_CREATED") + "~n" + text )
		endif

		messageWindow.Open()

		messageWindow.Update()
		messageWindow.Draw()

		Flip 0
	End Function


	Function GetGameSummary:TData(fileURI:string)
		local stream:TStream = ReadStream(fileURI)
		if not stream
			print "file not found: "+fileURI
			return null
		endif


		local lines:string[]
		local line:string = ""
		local lineNum:int = 0
		local validSavegame:int = False
		While not EOF(stream)
			line = stream.ReadLine()

			'scan bmo version to avoid faulty deserialization
			if line.Find("<bmo ver=~q") >= 0
				local bmoVersion:int = int(line[10 .. line.Find("~q>")])
				if bmoVersion <= 7
					return null
				endif
			endif

			if line.Find("name=~q_Game~q type=~qTGame~q>") > 0
				exit
			endif

			'should not be needed - or might fail if we once have a bigger amount stored
			'in gamesummary then expected
			if lineNum > 1500 then exit

			lines :+ [line]
			lineNum :+ 1
			if lineNum = 4 and line.Find("name=~q___gameSummary~q type=~qTData~q>") > 0
				validSavegame = True
			endif
			if lineNum = 4 and line.Find("name=~q_gameSummary~q type=~qTData~q>") > 0
				validSavegame = True
			endif
		Wend
		CloseStream(stream)
		if not validSavegame
			print "unknown savegamefile"
			return null
		endif

		'remove line 3 and 4
		lines[2] = ""
		lines[3] = ""
		'remove last line / let the bmo-file end there
		lines[lines.length-1] = "</bmo>"

		local content:string = "~n".Join(lines)


		'local p:TPersist = new TPersist
		Local p:TPersist = New TXMLPersistenceBuilder.Build()
		local res:TData = TData(p.DeserializeObject(content))
		if not res then res = new TData
		res.Add("fileURI", fileURI)
		res.Add("fileName", GetSavegameName(fileURI) )
		res.AddNumber("fileTime", FileTime(fileURI))
		p.Free()

		return res
	End Function


	global _nilNode:TNode = new TNode._parent
	Function RepairData()
		rem
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
		local unused:int
		local used:int = GetAdContractCollection().list.count()
		local adagencyContracts:TList = RoomHandler_AdAgency.GetInstance().GetContractsInStock()
		if not adagencyContracts then adagencyContracts = CreateList()
		local availableContracts:TAdContract[] = TAdContract[](GetAdContractCollection().list.ToArray())
		For local a:TAdContract = EachIn availableContracts
			if a.owner = a.OWNER_NOBODY OR (a.daySigned = -1 and a.profit = -1 and not adagencyContracts.Contains(a))
				unused :+1
				GetAdContractCollection().Remove(a)
			endif
		Next
		'print "Cleanup: removed "+unused+" unused AdContracts."


		TLogger.Log("Savegame.CleanUpData().", "Scriptcollection:", LOG_SAVELOAD | LOG_DEBUG)
		'used = GetScriptCollection().GetAvailableScriptList().Count()
		'local scriptList:TList = RoomHandler_ScriptAgency.GetInstance().GetScriptsInStock()
		'if not scriptList then scriptList = CreateList()
		local availableScripts:TScript[] = TScript[](GetScriptCollection().GetAvailableScriptList().ToArray())
		unused = 0
		For local s:TScript = EachIn availableScripts
			unused :+1
			GetScriptCollection().Remove(s)
			TLogger.Log("Savegame.CleanUpData().", "- removing script: "+s.GetTitle()+"  ["+s.GetGUID()+"]", LOG_SAVELOAD | LOG_DEBUG)
		Next
		TLogger.Log("Savegame.CleanUpData().", "Removed "+unused+" generated but unused scripts from collection.", LOG_SAVELOAD | LOG_DEBUG)
	End Function


	Function Load:Int(saveName:String="savegame.xml")
		ShowMessage(True)

		'=== CHECK SAVEGAME ===
		If filetype(saveName) <> 1
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is missing.", LOG_SAVELOAD | LOG_ERROR)
			return False
		EndIf

		TPersist.maxDepth = 4096*4
		Local persist:TPersist = New TXMLPersistenceBuilder.Build()
		'Local persist:TPersist = New TPersist
		persist.serializer = new TSavegameSerializer

		local savegameSummary:TData = GetGameSummary(savename)
		'invalid savegame
		if not savegameSummary
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is corrupt or too old.", LOG_SAVELOAD | LOG_ERROR)
			return False
		endif

		'reset entity ID
		'this avoids duplicate GUIDs
		TEntityBase.lastID = savegameSummary.GetInt("entitybase_lastID", 3000000)
		TGameObject.LastID = savegameSummary.GetInt("gameobject_lastID", 3000000)
		TLogger.Log("Savegame.Load()", "Restored TEntityBase.lastID="+TEntityBase.lastID+", TGameObject.LastID="+TGameObject.LastID+".", LOG_SAVELOAD | LOG_DEBUG)


		'try to repair older savegames
		if savegameSummary.GetString("game_version") <> VersionString or savegameSummary.GetString("game_builddate") <> VersionDate
			TLogger.Log("Savegame.Load()", "Savegame was created with an older TVTower-build. Enabling basic compatibility mode.", LOG_SAVELOAD | LOG_DEBUG)
			persist.strictMode = False
			persist.converterTypeID = TTypeID.ForObject( new TSavegameConverter )
		endif


		local loadingStart:int = Millisecs()
		'this creates new TGameObjects - and therefore increases ID count!
?bmxng
		Local saveGame:TSaveGame  = TSaveGame(persist.DeserializeFromFile(savename))
?not bmxng
		Local saveGame:TSaveGame  = TSaveGame(persist.DeserializeFromFile(savename, XML_PARSE_HUGE))
?
		persist.Free()
		If Not saveGame
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is corrupt.", LOG_SAVELOAD | LOG_ERROR)
			Return False
		Else
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q loaded in " + (Millisecs() - loadingStart)+"ms.", LOG_SAVELOAD | LOG_DEBUG)
		EndIf

		If Not saveGame.CheckGameData()
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is in bad state.", LOG_SAVELOAD | LOG_ERROR)
			Return False
		EndIf


		'=== RESET CURRENT GAME ===
		'reset game data before loading savegame data
		new TGameState.Initialize()


		'=== LOAD SAVED GAME ===
		'tell everybody we start loading (eg. for unregistering objects before)
		'payload is saveName
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginLoad", New TData.addString("saveName", saveName)))
		'load savegame data into game object
		saveGame.RestoreGameData()

		'tell everybody we finished loading (eg. for clearing GUI-lists)
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnLoad", New TData.addString("saveName", saveName).add("saveGame", saveGame)))

		if GetGame().GetObservedFigure() = GetPlayer().GetFigure()
			'only set the screen if the figure is in this room ... this
			'allows modifying the player in the savegame
			If GetPlayer().GetFigure().inRoom
				Local playerScreen:TScreen = ScreenCollection.GetScreen(saveGame._CurrentScreenName)
				If playerScreen.name = GetPlayer().GetFigure().inRoom.GetScreenName() or playerScreen.HasParentScreen(GetPlayer().GetFigure().inRoom.GetScreenName())
					'ScreenCollection.GoToScreen(playerScreen)
					'just set the current screen... no animation
					ScreenCollection._SetCurrentScreen(playerScreen)
				EndIf
			EndIf
rem
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
		endif


		CleanUpData()


		RepairData()

		'close message window
		if messageWindow then messageWindow.Close()

		'call game that game continues/starts now
		GetGame().StartLoadedSaveGame()

		Return True
	End Function


	Function Save:Int(saveName:String="savegame.xml")
		ShowMessage(False)

		'check directories and create them if needed
		local dirs:string[] = ExtractDir(saveName.Replace("\", "/")).Split("/")
		local currDir:string
		for local dir:string = EachIn dirs
			currDir :+ dir + "/"
			'if directory does not exist, create it
			if filetype(currDir) <> 2
				TLogger.Log("Savegame.Save()", "Savegame path contains missing directories. Creating ~q"+currDir[.. currDir.length-1]+"~q.", LOG_SAVELOAD)
				CreateDir(currDir)
			endif
		Next
		if filetype(currDir) <> 2
			TLogger.Log("Savegame.Save()", "Failed to create directories for ~q"+saveName+"~q.", LOG_SAVELOAD)
		endif

		Local saveGame:TSaveGame = New TSaveGame
		'tell everybody we start saving
		'payload is saveName
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginSave", New TData.addString("saveName", saveName)))

		'store game data in savegame
		saveGame.BackupGameData()

		'setup tpersist config
		TPersist.format=True
'during development...(also savegame.XML should be savegame.ZIP then)
'		TPersist.compressed = True

		saveGame.UpdateMessage(False, "Saving: Serializing data to savegame file.")
		TPersist.maxDepth = 4096
		'save the savegame data as xml
		'TPersist.format=False
		Local p:TPersist = New TXMLPersistenceBuilder.Build()
		'local p:TPersist = New TPersist
		p.serializer = new TSavegameSerializer
		if TPersist.compressed
			p.SerializeToFile(saveGame, saveName+".zip")
		else
			p.SerializeToFile(saveGame, saveName)
		endif
		p.Free()

		'tell everybody we finished saving
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnSave", New TData.addString("saveName", saveName).add("saveGame", saveGame)))

		'close message window
		if messageWindow then messageWindow.Close()

		Return True
	End Function


	Function GetSavegameName:string(fileURI:string)
		local p:string = GetSavegamePath()
		local r:string
		if p.length > 0 and fileURI.Find( p ) = 0
			r = StripExt( fileURI[ p.length .. ] )
		else
			r = StripDir(StripExt(fileURI))
		endif

		if r.length = 0 then return ""
		if chr(r[0]) = "/" or chr(r[0]) = "\"
			r = r[1 ..]
		endif

		return r
	End Function


	Function GetSavegameURI:string(fileName:string)
		if GetSavegamePath() <> "" then return GetSavegamePath() + "/" + GetSavegameName(fileName) + ".xml"
		return GetSavegameName(fileName) + ".xml"
	End Function


	Function GetSavegamePath:string()
		return "savegames"
	End Function
End Type


Type TSavegameConverter
	Method DeSerializeUnknownProperty:object(oldType:string, newType:string, obj:object, parentObj:object)
		local convert:string = (oldType+">"+newType).ToLower()
		Select convert
			case "TIntervalTimer>TBuildingIntervalTimer".ToLower()
				local old:TIntervalTimer = TIntervalTimer(obj)
				if old
					local res:TBuildingIntervalTimer = new TBuildingIntervalTimer
					res.Init(old.interval, 0, old.randomnessMin, old.randomnessMax)

					return res
				endif

			case "TProgrammeLicenceFilter>TProgrammeLicenceFilterGroup".ToLower()
				if parentObj and TTypeID.ForObject(parentObj).name().ToLower() = "RoomHandler_MovieAgency".ToLower()
					return RoomHandler_MovieAgency.GetInstance().filterAuction
				endif
			case "TMap>TAudienceAttraction[]".ToLower()
				if parentObj and TTypeID.ForObject(parentObj).name().ToLower() = "TAudienceMarketCalculation".ToLower()
					local oldMap:TMap = TMap(obj)
					local newArr:TAudienceAttraction[]
					for local att:TAudienceAttraction = EachIn oldMap.Values()
						newArr :+ [att]
					next
					return newArr
				endif
			rem
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
		return null
	End Method
End Type


Type TSavegameSerializer
	Method SerializeTSpriteToString:string(obj:object)
		local sprite:TSprite = TSprite(obj)
		if not sprite then return ""
		'Of sprite data, we only need an identifier and all data, which
		'is differing between games. This works because sprites are
		'the same between games - so we just reassign them on load

		'individual data: nothing
		'identifier: name
		local res:string = sprite.name

		return res
	End Method


	Method DeSerializeTSpriteFromString:object(serialized:String, targetObj:object)
		'local sprite:TSprite = TSprite(targetObj)
		'if not sprite then return null

		'only consists of name
		local name:string = serialized
		targetObj = GetSpriteFromRegistry(name)

		return targetObj
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
		guiButtonsWindow = New TGUIGameWindow.Create(New TVec2D.Init(300, 330), New TVec2D.Init(200, 400), name)
		guiButtonsWindow.SetPadding(panelGap, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")

		guiButtonsPanel	= guiButtonsWindow.AddContentBox(0,0,-1,-1)

		TGUIButton.SetTypeFont( GetBitmapFontManager().baseFontBold )
		TGUIButton.SetTypeCaptionColor( TColor.CreateGrey(75) )

		guiButtonStart		= New TGUIButton.Create(New TVec2D.Init(0, 0*38), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonNetwork	= New TGUIButton.Create(New TVec2D.Init(0, 1*38), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonNetwork.Disable()
		guiButtonOnline		= New TGUIButton.Create(New TVec2D.Init(0, 2*38), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonOnline.Disable()
		guiButtonLoadGame	= New TGUIButton.Create(New TVec2D.Init(0, 3*38), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonSettings	= New TGUIButton.Create(New TVec2D.Init(0, 4*38), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonQuit		= New TGUIButton.Create(New TVec2D.Init(0, 5*38 + 10), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonNetwork)
		guiButtonsPanel.AddChild(guiButtonOnline)
		guiButtonsPanel.AddChild(guiButtonLoadGame)
		guiButtonsPanel.AddChild(guiButtonSettings)
		guiButtonsPanel.AddChild(guiButtonQuit)

		'for main menu janitor
		GetBuildingTime().SetTimeFactor(1.0)

		If TLocalization.languagesCount > 0
			guiLanguageDropDown = New TGUISpriteDropDown.Create(New TVec2D.Init(620, 560), New TVec2D.Init(170,-1), "Sprache", 128, name)
			Local itemHeight:Int = 0
			Local languageCount:Int = 0

			For Local lang:TLocalizationLanguage = EachIn TLocalization.languages.Values()
				languageCount :+ 1
				Local item:TGUISpriteDropDownItem = New TGUISpriteDropDownItem.Create(Null, Null, lang.Get("LANGUAGE_NAME_LOCALE"))
				item.SetValueColor(TColor.CreateGrey(100))
				item.data.Add("value", lang.Get("LANGUAGE_NAME_LOCALE"))
				item.data.Add("languageCode", lang.languageCode)
				item.data.add("spriteName", "flag_"+lang.languageCode)
				'item.SetZindex(10000)
				guiLanguageDropDown.AddItem(item)
				If itemHeight = 0 Then itemHeight = item.GetScreenHeight()

				If lang.languageCode = TLocalization.GetCurrentLanguageCode()
					guiLanguageDropDown.SetSelectedEntry(item)
				EndIf
			Next
			GuiManager.SortLists()
			'we want to have max 4 items visible at once
			guiLanguageDropDown.SetListContentHeight(itemHeight * Min(languageCount,4))
			EventManager.registerListenerMethod("GUIDropDown.onSelectEntry", Self, "onSelectLanguageEntry", guiLanguageDropDown)
		EndIf

		'fill captions with the localized values
		SetLanguage()

		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickButtons")

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

		Select sender
			Case guiButtonSettings
					App.CreateSettingsWindow()

			Case guiButtonStart
					PrepareGameObject()
					GetGame().SetGamestate(TGame.STATE_SETTINGSMENU)

			Case guiButtonNetwork
					PrepareGameObject()
					GetGame().onlinegame = False
					GetGame().networkgame = True
					GetGame().SetGamestate(TGame.STATE_NETWORKLOBBY)

			Case guiButtonOnline
					PrepareGameObject()
					GetGame().onlinegame = True
					GetGame().networkgame = True
					GetGame().SetGamestate(TGame.STATE_NETWORKLOBBY)

			Case guiButtonLoadGame
					CreateLoadGameWindow()

			Case guiButtonQuit
					App.ExitApp = True
		End Select
	End Method


	Method PrepareGameObject()
		TLogger.Log("====== PREPARE NEW GAME ======", "", LOG_DEBUG)

		'reset game data collections
		new TGameState.Initialize()
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
		if loadGameMenuWindow then loadGameMenuWindow.Remove()

		loadGameMenuWindow = New TGUIModalWindowChain.Create(New TVec2D, New TVec2D.Init(500,150), "SYSTEM")
		loadGameMenuWindow.SetZIndex(99000)
		loadGameMenuWindow.SetCenterLimit(new TRectangle.setTLBR(30,0,0,0))

		'append menu after creation of screen area, so it recenters properly
		local loadMenu:TGUIModalLoadSavegameMenu = new TGUIModalLoadSavegameMenu.Create(New TVec2D, New TVec2D.Init(520,350), "SYSTEM")
		loadMenu._defaultValueColor = TColor.clBlack.copy()
		loadMenu.defaultCaptionColor = TColor.clWhite.copy()

		loadGameMenuWindow.SetContentElement(loadMenu)

		'menu is always ingame...
		loadGameMenuWindow.SetDarkenedArea(New TRectangle.Init(0,0,800,600))
		'center to this area
		loadGameMenuWindow.SetScreenArea(New TRectangle.Init(0,0,800,600))

		App.EscapeMenuWindow = loadGameMenuWindow
		loadGameMenuWindow = null

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
		DrawMenuBackground(False)

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
		guiButtonsWindow = New TGUIGameWindow.Create(New TVec2D.Init(590, 355), New TVec2D.Init(200, 235), name)
		guiButtonsWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.SetCaption("")
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsPanel = guiButtonsWindow.AddContentBox(0,0,-1,-1)


		guiButtonJoin	= New TGUIButton.Create(New TVec2D.Init(0, 0), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(),-1), GetLocale("MENU_JOIN"), name)
		guiButtonCreate	= New TGUIButton.Create(New TVec2D.Init(0, 45), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(),-1), GetLocale("MENU_CREATE_GAME"), name)
		guiButtonBack	= New TGUIButton.Create(New TVec2D.Init(0, guiButtonsPanel.GetcontentScreenHeight() - guiButtonJoin.GetScreenHeight()), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), GetLocale("MENU_BACK"), name)

		guiButtonsPanel.AddChild(guiButtonJoin)
		guiButtonsPanel.AddChild(guiButtonCreate)
		guiButtonsPanel.AddChild(guiButtonBack)

		guiButtonJoin.disable() 'until an entry is clicked


		'GameList
		'contained within a window/panel for styling
		guiGameListWindow = New TGUIGameWindow.Create(New TVec2D.Init(20, 355), New TVec2D.Init(520, 235), name)
		guiGameListWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiGameListWindow.guiBackground.spriteAlpha = 0.5
		Local guiGameListPanel:TGUIBackgroundBox = guiGameListWindow.AddContentBox(0,0,-1,-1)
		'add list to the panel (which is located in the window
		guiGameList	= New TGUIGameEntryList.Create(New TVec2D.Init(0,0), New TVec2D.Init(guiGameListPanel.GetContentScreenWidth(),guiGameListPanel.GetContentScreenHeight()), name)
		guiGameList.SetBackground(Null)
		guiGameList.SetPadding(0, 0, 0, 0)

		guiGameListPanel.AddChild(guiGameList)

		'localize gui elements
		SetLanguage()

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
					GetGame().SetGamestate(TGame.STATE_SETTINGSMENU)
					?bmxng
						Network.localFallbackIP = DottedIPToInt(HostIp(GetGame().userFallbackIP))
					?not bmxng
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
		?not bmxng
		If Network.ConnectToServer( HostIp(_hostIP), _hostPort )
		?
			Network.isServer = False
			GetGame().SetGameState(TGame.STATE_SETTINGSMENU)
			ScreenGameSettings.guiGameTitle.Value = gameTitle
		EndIf
	End Method


	Method Draw:Int(tweenValue:Float)
		DrawMenuBackground(True)

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
				?not bmxng
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
	Field SendGameReadyTimer:Int = 0
	Field StartMultiplayerSyncStarted:Int = 0
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

	Field stateName:TLowerString

	Method Create:TScreen_PrepareGameStart(name:String)
		Super.Create(name)
		SetGroupName("ExGame", "PrepareGameStart")

		messageWindow = New TGUIGameModalWindow.Create(New TVec2D, New TVec2D.Init(400,250), name)
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
			GetBitmapFontManager().baseFont.draw(GetLocale("SYNCHRONIZING_START_CONDITIONS")+"...", messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
			messageDY :+ 20
			Local allReady:Int = True
			For Local i:Int = 1 To 4
				If Not GetPlayerCollection().Get(i).networkstate Then allReady = False
				GetBitmapFontManager().baseFont.draw(GetLocale("PLAYER")+" "+i+"..."+GetPlayerCollection().Get(i).networkstate, messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
				messageDY :+ 20
			Next
			If Not allReady Then GetBitmapFontManager().baseFont.draw("not ready!!", messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
		Else
			GetBitmapFontManager().baseFont.draw(GetLocale("PREPARING_START_DATA")+"...", messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
		EndIf
		SetAlpha oldAlpha
	End Method


	Method Reset:Int()
		startGameCalled = False
		prepareGameCalled = False
		spreadConfigurationCalled = False
		spreadStartDataCalled = False
		canStartGame = False
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


	Global wait:Int = 0

	'override default update
	Method Update:Int(deltaTime:Float)
		'update messagewindow
		GUIManager.Update(stateName)


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
		EndIf
	End Method


	'spread configuration to other players
	Method SpreadConfiguration:Int()
		If Not GetGame().networkGame Then Return False

		'send which database to use (or send database itself?)
	End Method
End Type




Type GameEvents
	Global _eventListeners:TLink[]


	Function Initialize:int()
		UnRegisterEventListeners()
		RegisterEventListeners()

		return True
	End Function


	Function UnRegisterEventListeners:Int()
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]
	End Function


	Function RegisterEventListeners:Int()
		'react on right clicks during a rooms update (leave room)
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onUpdateDone", RoomOnUpdate) ]

		'forcefully set current screen (eg. after loading a "currently
		'leaving a screen" savegame, or with a faulty timing between
		'doors and screen-transition-animation)
		_eventListeners :+ [ EventManager.registerListenerFunction("figure.SetInRoom", onFigureSetInRoom) ]

		'refresh ingame help
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.OnFinishEnter", OnEnterNewScreen) ]

		'pause on modal windows
		_eventListeners :+ [ EventManager.registerListenerFunction("guiModalWindow.onOpen", OnOpenModalWindow) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiModalWindow.onClose", OnCloseModalWindow) ]
		'pause on ingame help
		_eventListeners :+ [ EventManager.registerListenerFunction("InGameHelp.ShowHelpWindow", OnOpenIngameHelp) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("InGameHelp.CloseHelpWindow", OnCloseIngameHelp) ]

		'=== REGISTER TIME EVENTS ===
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnDay", OnDay) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnHour", OnHour) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnMinute", OnMinute) ]

		'=== REGISTER PLAYER EVENTS ===
		'events get ignored by non-gameleaders
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnMinute", PlayersOnMinute) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnDay", PlayersOnDay) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnBegin", PlayersOnBeginGame) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Time.OnSecond", Time_OnSecond) ]

		_eventListeners :+ [ EventManager.registerListenerFunction("Game.SetPlayerBankruptBegin", PlayerOnSetBankrupt) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerFinance.onChangeMoney", PlayerFinanceOnChangeMoney) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerFinance.onTransactionFailed", PlayerFinanceOnTransactionFailed) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerBoss.onCallPlayer", PlayerBoss_OnCallPlayer) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerBoss.onCallPlayerForced", PlayerBoss_OnCallPlayerForced) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerBoss.onPlayerEnterBossRoom", PlayerBoss_OnPlayerEnterBossRoom) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerBoss.onPlayerTakesCredit", PlayerBoss_OnTakeOrRepayCredit) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerBoss.onPlayerRepaysCredit", PlayerBoss_OnTakeOrRepayCredit) ]

		'=== PUBLIC AUTHORITIES ===
		'-> create ingame notifications
		_eventListeners :+ [ EventManager.registerListenerFunction("publicAuthorities.onStopXRatedBroadcast", publicAuthorities_onStopXRatedBroadcast) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("publicAuthorities.onConfiscateProgrammeLicence", publicAuthorities_onConfiscateProgrammeLicence) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Achievement.OnComplete", Achievement_OnComplete) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Award.OnFinish", Award_OnFinish) ]

		'visually inform that selling the last station is impossible
		_eventListeners :+ [ EventManager.registerListenerFunction("StationMap.onTrySellLastStation", StationMap_OnTrySellLastStation) ]
		'trigger audience recomputation when a station is trashed/sold
		_eventListeners :+ [ EventManager.registerListenerFunction("StationMap.removeStation", StationMap_OnRemoveStation) ]
		'show ingame toastmessage if station is under construction
		_eventListeners :+ [ EventManager.registerListenerFunction("StationMap.addStation", StationMap_OnAddStation) ]
		'show ingame toastmessage if your audience reach level changes
		_eventListeners :+ [ EventManager.registerListenerFunction("StationMap.onChangeReachLevel", StationMap_OnChangeReachLevel) ]
		'show ingame toastmessage if station is under construction
		_eventListeners :+ [ EventManager.registerListenerFunction("Station.onContractEndsSoon", Station_OnContractEndsSoon) ]
		'show ingame toastmessage if bankruptcy could happen
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.SetPlayerBankruptLevel", Game_OnSetPlayerBankruptLevel) ]

		'listen to failed or successful ending adcontracts to send out
		'ingame toastmessages
		_eventListeners :+ [ EventManager.registerListenerFunction("AdContract.onFinish", AdContract_OnFinish) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("AdContract.onFail", AdContract_OnFail) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ProgrammeLicenceAuction.onGetOutbid", ProgrammeLicenceAuction_OnGetOutbid) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ProgrammeLicenceAuction.onWin", ProgrammeLicenceAuction_OnWin) ]

		'listen to custom programme events to send out toastmessages
		_eventListeners :+ [ EventManager.registerListenerFunction("production.finalize", Production_OnFinalize) ]

		'reset room signs when a bomb explosion in a room happened
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onBombExplosion", Room_OnBombExplosion) ]

		'we want to handle "/dev bla"-commands via chat
		_eventListeners :+ [ EventManager.registerListenerFunction("chat.onAddEntry", onChatAddEntry ) ]
		'relay incoming chat messages to the AI
		_eventListeners :+ [ EventManager.registerListenerFunction("chat.onAddEntry", onChatAddEntryForAI ) ]

		'dev
		_eventListeners :+ [ EventManager.registerListenerFunction("player.onEnterRoom", onPlayerEntersRoom ) ]

	End Function


	'helper
	Function CreateArchiveMessageFromToastMessage:TArchivedMessage(toastMessage:TGameToastMessage)
		if not toastMessage then return null

		local archivedMessage:TArchivedMessage = new TArchivedMessage
		archivedMessage.SetTitle(toastMessage.caption)
		archivedMessage.SetText(toastMessage.text)
		archivedMessage.messageCategory = toastMessage.messageCategory
		archivedMessage.group = toastMessage.messageType 'positive, negative, information ...
		archivedMessage.time = GetWorldTime().GetTimeGone()
		archivedMessage.sourceGUID = toastMessage.GetGUID()
		archivedMessage.SetOwner( toastMessage.GetData().GetInt("playerID", -1) )

		return archivedMessage
	End Function


	Function OnOpenIngameHelp:int(triggerEvent:TEventBase)
		App.SetPausedBy(TApp.PAUSED_BY_INGAMEHELP, True)
	End Function


	Function OnCloseIngameHelp:int(triggerEvent:TEventBase)
		App.SetPausedBy(TApp.PAUSED_BY_INGAMEHELP, False)
	End Function


	Function OnOpenModalWindow:int(triggerEvent:TEventBase)
		App.SetPausedBy(TApp.PAUSED_BY_MODALWINDOW)
	End Function


	Function OnCloseModalWindow:int(triggerEvent:TEventBase)
		App.SetPausedBy(TApp.PAUSED_BY_MODALWINDOW, False)
	End Function


	'correct potentially "broken" (eg. savegame inbetween a "leaving" state)
	'screen assignments
	Function onFigureSetInRoom:int(triggerEvent:TEventBase)
		local fig:TFigureBase = TFigureBase(triggerEvent.GetSender())

		if GetGame().GetObservedFigure() = fig
			If fig.GetInRoom()
				ScreenCollection._SetCurrentScreen(ScreenCollection.GetCurrentScreen())
			Else
				ScreenCollection._SetCurrentScreen(GetGame().GameScreen_world)
			EndIf
		endif
	End Function


	Function OnEnterNewScreen:int(triggerEvent:TEventBase)
		local screen:TScreen = TScreen(triggerEvent.GetSender())
		if not screen then return False
		'try to show the ingame help for that screen (if there is any)
		IngameHelpWindowCollection.ShowByHelpGUID( screen.GetName() )
	End Function


	global roomLog:TList = CreateList()
	global roomCount:TMap = CreateMap()
	Function onPlayerEntersRoom:Int(triggerEvent:TEventBase)
		local room:TRoom = TRoom(triggerEvent.GetReceiver())
		local player:TPlayer = TPlayer(triggerEvent.GetSender())

		roomLog.AddLast("Player #"+player.playerID+"  enters " + room.GetName()+ "  [" + GetWorldTime().GetFormattedGameDate()+"]")

		local key:string = player.playerID+"|"+room.GetName()
		local count:int = int(string(roomCount.ValueForKey(key))) + 1
		roomCount.insert(key, string(count))

	End Function


	Function onChatAddEntryForAI:Int(triggerEvent:TEventBase)
		Local text:String = triggerEvent.GetData().GetString("text")
		Local senderID:int = triggerEvent.GetData().GetInt("senderID")
		Local channels:int = triggerEvent.GetData().GetInt("channels")

		local commandType:int = TGUIChat.GetCommandFromText(text)
		local commandText:string = TGUIChat.GetCommandStringFromText(text)
		'print "SenderID=" + senderID +"   commandType/Text="+commandType + "/"+commandText + "   text="+text

		'=== PRIVATE / WHISPER ===
		'-> send to AI ?
		if commandType = CHAT_COMMAND_WHISPER
			local message:string = TGUIChat.GetPayloadFromText(text)
			local receiver:string = message.split(" ")[0]
			local receiverID:int = int(receiver)
			local playerBase:TPlayerBase
			if string(receiverID) <> receiver > 9 'some odd number containing thing or playername?
				For Local pBase:TPlayerBase = EachIn GetPlayerBaseCollection().players
					if pBase.name.ToLower() = receiver.ToLower()
						message = message[receiver.length+1 ..] 'remove name/id
						receiverID = pBase.playerID
						receiver = pBase.name
						playerBase = pBase
						exit
					endif
				Next
			elseif receiverID > 0 and receiverID < 9
				message = message[receiver.length+1 ..] 'remove name/id
				playerBase = GetPlayerBase(receiverID)
				if playerBase
					receiver = playerBase.name
				endif
			endif
			if playerBase and TPlayer(playerBase).isLocalAI()
				TPlayer(playerBase).PlayerAI.CallOnChat(senderID, message, CHAT_COMMAND_WHISPER)
			endif
		endif

		'public chat
		if commandType = CHAT_COMMAND_NONE
			'ignore chats starting with a "command" (maybe misspelled a whisper)
			'also ignore system channel messages
			if text.trim().Find("/") <> 0 and (channels & CHAT_CHANNEL_SYSTEM) = 0 'or text.trim().Find("[DEV]") = 0
				'local channels:int = TGUIChat.GetChannelsFromText(text)
				local message:string = TGUIChat.GetPayloadFromText(text)

				'inform local AI
				For Local player:TPLayer = EachIn GetPlayerCollection().players
					if player.isLocalAI()
						player.PlayerAI.CallOnChat(senderID, message, CHAT_COMMAND_NONE, channels)
					endif
				Next
			endif
			return True
		endif
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

		Select command.Trim().toLower()
			Case "loaddb"
				local dbName:string = payload.Trim()
				if dbName
					'find all fitting files
					local dirTree:TDirectoryTree = new TDirectoryTree.SimpleInit("res/database/Default")
					dirTree.SetIncludeFileEndings(["xml"])
					dirTree.ScanDir("", True)
					local fileURIs:String[] = dirTree.GetFiles("", "", "", "", dbName)

					LoadDB(fileURIs)
					GetGame().SendSystemMessage("[DEV] Loaded the following DBs: "+ ", ".join(fileURIs) +".")
				else
					LoadDB()
					GetGame().SendSystemMessage("[DEV] Loaded the all DBs in the DB directory.")
				endif

				GetNewsEventCollection()._InvalidateCaches()

			Case "maxaudience"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				GetStationMap(player.playerID).CheatMaxAudience()
				GetGame().SendSystemMessage("[DEV] Set Player #"+player.playerID+"'s maximum audience to "+GetStationMap(player.playerID).GetReach())

			Case "debug"
				local what:string = payload
				Select what.Trim().ToLower()
					case "programmeplan"
						TVTDebugProgrammePlan = True
						TVTDebugQuoteInfos = False
						TVTDebugModifierInfos = False
				End Select

			Case "commandai"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				if not player.IsLocalAI()
					GetGame().SendSystemMessage("[DEV] cannot command non-local AI player.")
				else
					player.playerAI.CallOnChat(GetPlayer().playerID, "CMD_" + paramS, CHAT_COMMAND_WHISPER)
				endif

			Case "playerai"
				if GetGame().networkGame
					GetGame().SendSystemMessage("[DEV] Cannot adjust AI in network games.")
					return False
				endif

				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				If Int(params) = 1
					if not player.IsLocalAI()
						player.SetLocalAIControlled()
						'reload ai - to avoid using "outdated" information
						player.InitAI( new TAI.Create(player.playerID, GetGame().GetPlayerAIFileURI(player.playerID)) )
						player.playerAI.CallOnInit()
						'player.PlayerAI.CallLuaFunction("OnForceNextTask", null)
						GetGame().SendSystemMessage("[DEV] Enabled AI for player "+player.playerID)
					else
						GetGame().SendSystemMessage("[DEV] Already enabled AI for player "+player.playerID)
					endif
				else
					if player.IsLocalAI()
						'calling "SetLocalHumanControlled()" deletes AI too
						player.SetLocalHumanControlled()
						GetGame().SendSystemMessage("[DEV] Disabled AI for player "+player.playerID)
					else
						GetGame().SendSystemMessage("[DEV] Already disabled AI for player "+player.playerID)
					endif
				endif

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
					player.GetPublicImage().ChangeImage( New TAudience.AddFloat(Float(paramS)/2.0))

					If Int(paramS) > 0 Then paramS = "+"+Int(paramS)
					changed = " ("+paramS+"%)"
				EndIf
				GetGame().SendSystemMessage("[DEV] Image of player "+playerS+": "+player.GetPublicImage().GetAverageImage()+"%." + changed)

			Case "terrorlvl"
				local paramArray:String[]
				If paramS <> "" then paramArray = paramS.Split(" ")

				if Len(paramArray) = 1
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
				local roomGUID:string = paramS
				local room:TRoomBase
				if string(int(roomGUID)) = roomGUID
					room = GetRoomBaseCollection().Get( int(roomGUID) )
				endif
				if not room
					room = GetRoomBaseCollection().GetByGUID( TLowerString.Create(roomGUID) )
				endif
				if not room
					room = GetRoomBaseCollection().GetFirstByDetails("", roomGUID, player.playerID)
				endif
				if room
					DEV_switchRoom(room, player.GetFigure())
				endif

			Case "rentroom"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				local roomGUID:string = paramS
				local room:TRoomBase
				if string(int(roomGUID)) = roomGUID
					room = GetRoomBaseCollection().Get( int(roomGUID) )
				endif
				if not room
					room = GetRoomBaseCollection().GetByGUID( TLowerString.Create(roomGUID) )
				endif
				if not room
					room = GetRoomBaseCollection().GetFirstByDetails("", roomGUID, player.playerID)
				endif
				if room
					GetRoomAgency().CancelRoomRental(room, player.playerID)
					GetRoomAgency().BeginRoomRental(room, player.playerID)
					room.SetUsedAsStudio(True)
					GetGame().SendSystemMessage("[DEV] Rented room '" + room.GetDescription() +"' ["+room.GetName() + "] for player '" + player.name +"' ["+player.playerID + "]!")
				else
					GetGame().SendSystemMessage("[DEV] Cannot rent room '" + roomGUID + "'. Not found!")
				endif

			Case "setmasterkey"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)
				local bool:int = int(paramS)
				player.GetFigure().SetHasMasterkey(bool)
				if bool
					GetGame().SendSystemMessage("[DEV] Added masterkey to player '" + player.name +"' ["+player.playerID + "]!")
				else
					GetGame().SendSystemMessage("[DEV] Removed masterkey from player '" + player.name +"' ["+player.playerID + "]!")
				endif

			case "reloaddev"
				if FileType("config/DEV.xml") = 1
					local dataLoader:TDataXmlStorage = new TDataXmlStorage
					local data:TData = dataLoader.Load("config/DEV.xml")
					if data
						GetRegistry().Set("DEV_CONFIG", data)
						GameRules.devConfig = data
						GameRules.AssignFromData( Gamerules.devConfig )

						GetGame().SendSystemMessage("[DEV] Reloaded ~qconfig/DEV.xml~q.")
					else
						GetGame().SendSystemMessage("[DEV] Failed to reload ~qconfig/DEV.xml~q.")
					endif
				else
					GetGame().SendSystemMessage("[DEV] ~qconfig/DEV.xml~q not found.")
				endif


			Case "endauctions"
				local paramArray:String[]
				If paramS <> "" then paramArray = playerS.Split(" ")
				if paramArray.length = 0 or paramArray[0] = "-1" then paramArray = ["0", "1", "2", "3", "4", "5", "6", "7", "8"]
				For local indexS:string = EachIn paramArray
					local block:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks.GetByIndex( int(indexS)-1 )
					if not block then continue
					local oldLicence:TProgrammeLicence = block.licence
					local oldPrice:int = block.GetNextBidRaw()
					block.EndAuction()

					if not oldLicence
						GetGame().SendSystemMessage("[DEV] #"+int(indexS)+". Created new auction '" + block.licence.GetTitle()+"'")
					elseif oldLicence <> block.licence and block.licence
						GetGame().SendSystemMessage("[DEV] #"+int(indexS)+". Ended auction for '" + oldLicence.GetTitle()+"', Created new auction '" + block.licence.GetTitle()+"'")
					elseif oldLicence and not block.licence
						GetGame().SendSystemMessage("[DEV] #"+int(indexS)+". Ended auction for '" + oldLicence.GetTitle()+"', Created no new auction")
					elseif oldLicence = block.licence
						GetGame().SendSystemMessage("[DEV] #"+int(indexS)+". Reduced auction raw price for '" + oldLicence.GetTitle()+"' from " + MathHelper.DottedValue(oldPrice) + " to " + MathHelper.DottedValue(block.GetNextBidRaw()))
					endif
				Next


			Case "sendnews"
				local newsGUID:string = playerS '(first payload-param)
				local announceNow:int = int(paramS)

				if newsGUID.trim() = ""
					GetGame().SendSystemMessage("Wrong syntax (/dev help)!")
					return False
				endif

				if newsGUID.Find("devnews") = 0
					'num 1-xxx
					local num:int = Max(1, int(newsGUID.replace("devnews", "")))
					newsGUID = GameRules.devConfig.GetString("DEV_NEWS_GUID"+num, "")
					if not newsGUID
						GetGame().SendSystemMessage("Incorrect devnews-syntax (/dev help)!")
						return False
					endif
				endif

				'check template first
				local news:TNewsEvent
				local template:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByGUID(newsGUID)
				if not template then template = GetNewsEventTemplateCollection().SearchByPartialGUID(newsGUID)

				if template
					if template.IsAvailable()
						news = new TNewsEvent.InitFromTemplate(template)
						if news
							GetNewsEventCollection().Add(news)
						endif
					else
						TLogger.Log("DevCheat", "SendNews: news template not available (yet): "+newsGUID, LOG_DEBUG)
						return false
					endif
				else
					news = GetNewsEventCollection().GetByGUID(newsGUID)
					if not news then news = GetNewsEventCollection().SearchByPartialGUID(newsGUID)
				endif

				if not news
					GetGame().SendSystemMessage("No news with GUID ~q"+newsGUID+"~q found.")
					return False
				endif

				'announce that news
				GetNewsAgency().announceNewsEvent(news, 0, announceNow)
				GetGame().SendSystemMessage("News with GUID ~q"+newsGUID+"~q announced.")

			Case "givelicence"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local licenceGUID:String, hasToPay:String
				FillCommandPayload(paramS, licenceGUID, hasToPay)

				if licenceGUID.trim() = ""
					GetGame().SendSystemMessage("Wrong syntax (/dev help)!")
					return False
				endif

				if licenceGUID.Find("devlicence") = 0
					'num 1-xxx
					local num:int = Max(1, int(licenceGUID.replace("devlicence", "")))
					licenceGUID = GameRules.devConfig.GetString("DEV_PROGRAMMELICENCE_GUID"+num, "")
					if not licenceGUID
						GetGame().SendSystemMessage("Incorrect devlicence-syntax (/dev help)!")
						return False
					endif
				endif

				local licence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(licenceGUID)
				if not licence then licence = GetProgrammeLicenceCollection().SearchByPartialGUID(licenceGUID)
				if not licence
					GetGame().SendSystemMessage("No licence with GUID ~q"+licenceGUID+"~q found.")
					return False
				endif

				'add series not episodes
				if licence.IsEpisode() then licence = licence.GetParentLicence()
				'add collections, not collection episodes
				if licence.IsCollectionElement() then licence = licence.GetParentLicence()

				'hand the licence to the player
				if licence.owner <> player.playerID
					if hasToPay = "0" or hasToPay.ToLower() = "false"
						licence.SetOwner(player.playerID)
					else
						licence.SetOwner(0)
					endif
					'true = skip owner check (needed to be able to skip payment
					RoomHandler_MovieAgency.GetInstance().SellProgrammeLicenceToPlayer(licence, player.playerID, True)
					GetGame().SendSystemMessage("added movie: "+licence.GetTitle()+" ["+licence.GetGUID()+"]")
				else
					GetGame().SendSystemMessage("already had movie: "+licence.GetTitle()+" ["+licence.GetGUID()+"]")
				endif

			Case "givead"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local adGUID:String, checkAvailability:String
				FillCommandPayload(paramS, adGUID, checkAvailability)

				if adGUID.trim() = ""
					GetGame().SendSystemMessage("Wrong syntax (/dev help)!")
					return False
				endif

				local adContractBase:TAdContractBase = GetAdContractBaseCollection().GetByGUID(adGUID)
				if not adContractBase then adContractBase = GetAdContractBaseCollection().SearchByPartialGUID(adGUID)
				if not adContractBase
					GetGame().SendSystemMessage("No adcontract with GUID ~q"+adGUID+"~q found.")
					return False
				endif

				if checkAvailability = "0" or checkAvailability.ToLower() = "false"
					'
				elseif not adContractBase.IsAvailable()
					GetGame().SendSystemMessage("Adcontract with GUID ~q"+adGUID+"~q not available (yet).")
					return False
				endif

				'forcefully add to the collection (skips requirements checks)
				local adContract:TAdContract = New TAdContract.Create(adContractBase)
				GetPlayerProgrammeCollection(player.playerID).AddAdContract(adContract, True)
				GetGame().SendSystemMessage("added adcontract: "+adContract.GetTitle()+" ["+adContract.GetGUID()+"]")

			Case "givescript"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local scriptGUID:String, hasToPay:String
				FillCommandPayload(paramS, scriptGUID, hasToPay)

				if scriptGUID.trim() = ""
					GetGame().SendSystemMessage("Wrong syntax (/dev help)!")
					return False
				endif

				local scriptTemplate:TScriptTemplate = GetScriptTemplateCollection().GetByGUID(scriptGUID)
				if not scriptTemplate then scriptTemplate = GetScriptTemplateCollection().SearchByPartialGUID(scriptGUID)
				if not scriptTemplate
					GetGame().SendSystemMessage("No script template with GUID ~q"+scriptGUID+"~q found.")
					return False
				endif

				'hand the script to the player
				local script:TScript = GetScriptCollection().GenerateFromTemplate(scriptTemplate)
				if hasToPay = "0" or hasToPay.ToLower() = "false"
					script.SetOwner(player.playerID)
				else
					script.SetOwner(0)
				endif
				'true = skip owner check (needed to be able to skip payment
				RoomHandler_ScriptAgency.GetInstance().SellScriptToPlayer(script, player.playerID, True)
				GetGame().SendSystemMessage("added script: "+script.GetTitle()+" ["+script.GetScriptTemplate().GetGUID()+"]")

			Case "help"
				SendHelp()

			Default
				SendHelp()
				'SendSystemMessage("[DEV] unknown command: ~q"+command+"~q")
		End Select


		Function SendHelp()
			GetGame().SendSystemMessage("[DEV] available commands:")
			GetGame().SendSystemMessage("|b|money|/b| [player#] [+- money]")
			GetGame().SendSystemMessage("|b|bossmood|/b| [player#] [+- mood %]")
			GetGame().SendSystemMessage("|b|image|/b| [player#] [+- image %]")
			GetGame().SendSystemMessage("|b|terrorlvl|/b| [terrorgroup# 0 or 1] [level#]")
			GetGame().SendSystemMessage("|b|givelicence|/b| [player#] [GUID / GUID portion / devlicence#] [oay=1, free=0]")
			GetGame().SendSystemMessage("|b|givescript|/b| [player#] [GUID / GUID portion / devscript#] [pay=1, free=0]")
			GetGame().SendSystemMessage("|b|givead|/b| [player#] [GUID / GUID portion] [checkAvailability=1]")
			GetGame().SendSystemMessage("|b|sendnews|/b| [GUID / GUID portion / devnews#] [now=1, normal=0]")
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


	Function Time_OnSecond:Int(triggerEvent:TEventBase)
		'only AI handling: only gameleader interested
		If Not GetGame().isGameLeader() Then Return False

		'milliseconds passed since last event
		Local timeGone:Int = triggerEvent.GetData().getInt("timeGone", 0)

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			if player.isLocalAI()
				TProfiler.Enter("PLAYER_"+player.playerID+"_lua")
				player.PlayerAI.ConditionalCallOnTick()
				player.PlayerAI.CallOnRealtimeSecond(timeGone)
				TProfiler.Leave("PLAYER_"+player.playerID+"_lua")
			endif
		Next
		Return True
	End Function


	Function PlayersOnMinute:Int(triggerEvent:TEventBase)
		If Not GetGame().isGameLeader() Then Return False

		Local time:Long = triggerEvent.GetData().getInt("time",-1)
		local minute:int = GetWorldTime().GetDayMinute(time)
		If minute < 0 Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			if player.isLocalAI()
				TProfiler.Enter("PLAYER_"+player.playerID+"_lua")
				player.PlayerAI.ConditionalCallOnTick()
				player.PlayerAI.CallOnMinute(minute)
				TProfiler.Leave("PLAYER_"+player.playerID+"_lua")
			endif
		Next
		Return True
	End Function


	Function PlayersOnDay:Int(triggerEvent:TEventBase)
		If Not GetGame().isGameLeader() Then Return False

		Local time:Long = triggerEvent.GetData().getInt("time",-1)
		local minute:int = GetWorldTime().GetDayMinute(time)
		If minute < 0 Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isLocalAI() Then player.PlayerAI.CallOnDayBegins()
		Next
		Return True
	End Function


	Function PlayersOnBeginGame:Int(triggerEvent:TEventBase)
		If Not GetGame().isGameLeader() Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isLocalAI() Then player.PlayerAI.CallOnGameBegins()
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

		local t:string
		t :+ GetRandomLocale("PLAYER_X_FROM_CHANNEL_Y_WENT_BANKRUPT").Replace("%X%", "|b|"+player.name+"|/b|").Replace("%Y%", "|b|"+player.channelName+"|/b|")
		t :+ " "
		if not player.isHuman()
			t :+ GetLocale("PLAYER_WILL_START_AGAIN")
		else
			t :+ GetLocale("AI_WILL_TAKE_OVER_THIS_PLAYER")
		endif
		toast.SetText(t)

		toast.GetData().AddNumber("playerID", player.playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interest in other players
		if not player.IsLocalHuman()
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
	End Function


	Function PlayerBroadcastMalfunction:Int(triggerEvent:TEventBase)
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		Local player:TPlayer = GetPlayerCollection().Get(playerID)
		If Not player Then Return False

		If player.isLocalAI() Then player.playerAI.CallOnMalfunction()
	End Function


	Function PlayerFinanceOnChangeMoney:Int(triggerEvent:TEventBase)
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		Local player:TPlayer = GetPlayerCollection().Get(playerID)
		Local value:Int = triggerEvent.GetData().GetInt("value", 0)
		Local reason:Int = triggerEvent.GetData().GetInt("reason", 0)
		Local reference:TNamedGameObject = TNamedGameObject(triggerEvent.GetData().Get("reference", Null))
		If playerID = -1 Or Not player Then Return False

		If player.isLocalAI() Then player.playerAI.CallOnMoneyChanged(value, reason, reference)
		If player.isActivePlayer() Then GetInGameInterface().BottomImgDirty = True
	End Function


	'show an error if a transaction was not possible
	Function PlayerFinanceOnTransactionFailed:Int(triggerEvent:TEventBase)
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		Local player:TPlayer = GetPlayerCollection().Get(playerID)
		Local value:Int = triggerEvent.GetData().GetInt("value", 0)
		If playerID = -1 Or Not player Then Return False

		'create an visual error
		If player.isActivePlayer() and not player.IsLocalAI() Then TError.CreateNotEnoughMoneyError()
	End Function


	Function PlayerBoss_OnCallPlayerForced:Int(triggerEvent:TEventBase)
		Local latestTime:Long = triggerEvent.GetData().GetLong("latestTime", Long(GetWorldTime().GetTimeGone() + 2*3600))
		Local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		If player.isLocalAI() Then player.playerAI.CallOnBossCallsForced()
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
		Local latestTime:Long = triggerEvent.GetData().GetLong("latestTime", Long(GetWorldTime().GetTimeGone() + 2*3600))
		Local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai about the request
		If player.isLocalAI()
			player.playerAI.CallOnBossCalls(latestTime)
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
			toast.SetText(GetLocale("YOU_HAVE_GOT_X_HOURS TO_VISIT_HIM").Replace("%HOURS%", 2))
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
		local success:int = triggerEvent.GetData().GetBool("result", False)
		if not success then return false

		local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		if not boss then return False


		local value:int = triggerEvent.GetData().GetInt("value", 0)
		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage

		'show it for some seconds
		toast.SetLifeTime(3)
		toast.SetMessageCategory(TVTMessageCategory.MONEY)

		if triggerEvent.IsTrigger("PlayerBoss.onPlayerTakesCredit")
			toast.SetMessageType(2) 'positive
			toast.SetCaption(StringHelper.UCFirst(GetLocale("CREDIT_TAKEN")))
			toast.SetText(StringHelper.UCFirst(GetLocale("ACCOUNT_BALANCE"))+": |b||color=0,125,0|+ "+ MathHelper.DottedValue(value) + " " + getLocale("CURRENCY") + "|/color||/b|")
		else
			toast.SetMessageType(3) 'negative
			toast.SetCaption(StringHelper.UCFirst(GetLocale("CREDIT_REPAID")))
			toast.SetText(StringHelper.UCFirst(GetLocale("ACCOUNT_BALANCE"))+": |b||color=125,0,0|- "+ MathHelper.DottedValue(value) + " " + getLocale("CURRENCY") + "|/color||/b|")
		endif

		'play a special sound instead of the default one
		toast.GetData().AddString("onAddMessageSFX", "positiveMoneyChange")
		toast.GetData().AddNumber("playerID", boss.playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interest in active player's boss-credit-actions
		If boss.playerID = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
	End Function


	Function PublicAuthorities_onStopXRatedBroadcast:Int(triggerEvent:TEventBase)
		Local programme:TProgramme = TProgramme(triggerEvent.GetSender())
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		If player.isLocalAI() Then player.playerAI.CallOnPublicAuthoritiesStopXRatedBroadcast()


		Local toast:TGameToastMessage = New TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(15)
		toast.SetMessageType(1) 'attention
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetCaption(GetLocale("AUTHORITIES_STOPPED_BROADCAST"))
		toast.SetText( ..
			GetLocale("BROADCAST_OF_XRATED_PROGRAMME_X_NOT_ALLOWED_DURING_DAYTIME").Replace("%TITLE%", "|b|"+programme.GetTitle()+"|/b|") + " " + ..
			GetLocale("PENALTY_OF_X_WAS_PAID").Replace("%MONEY%", "|b|"+MathHelper.DottedValue(GameRules.sentXRatedPenalty)+getLocale("CURRENCY")+"|/b|") ..
		)
		toast.GetData().AddNumber("playerID", programme.owner)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interest in active player's licences
		If programme.owner = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
	End Function


	Function PublicAuthorities_onConfiscateProgrammeLicence:Int(triggerEvent:TEventBase)
		Local targetProgrammeLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID( triggerEvent.GetData().GetString("targetProgrammeGUID") )
		Local confiscatedProgrammeLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID( triggerEvent.GetData().GetString("confiscatedProgrammeGUID") )
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		If player.isLocalAI() Then player.playerAI.CallOnPublicAuthoritiesConfiscateProgrammeLicence(confiscatedProgrammeLicence, targetProgrammeLicence)


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
		endif
	End Function


	Function Achievement_OnComplete:Int(triggerEvent:TEventBase)
		Local achievement:TAchievement = TAchievement(triggerEvent.GetSender())
		if not achievement then return False

		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		if not GetPlayerCollection().IsPlayer(playerID) then return False

		local player:TPlayer = GetPlayer(playerID)
		if not player then return False


		'inform ai
		If player.isLocalAI() Then player.playerAI.CallOnAchievementCompleted(achievement)


		local rewardText:string
		For local i:int = 0 until achievement.GetRewards().length
			if rewardText <> "" then rewardText :+ "~n"
			rewardText :+ chr(9654) + " " +achievement.GetRewards()[i].GetTitle()
		Next

		rem
			TODO: Bilder fuer toastmessages (+ Pokal)
			 _________
			|[ ] text |
			|    text |
			'---------'
		endrem
		local text:string = GetLocale("YOU_JUST_COMPLETED_ACHIEVEMENTTITLE").Replace("%ACHIEVEMENTTITLE%", "|b|"+achievement.GetTitle()+"|/b|")
		if rewardText
			text :+ "~n|b|" + GetLocale("REWARD") + ":|/b|~n" + rewardText
		endif


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
		endif
	End Function


	Function Award_OnFinish:Int(triggerEvent:TEventBase)
		Local award:TAward = TAward(triggerEvent.GetSender())
		if not award then return False

		Local playerID:Int = triggerEvent.GetData().GetInt("winningPlayerID", 0)
		if not GetPlayerCollection().IsPlayer(playerID) then return False

		local player:TPlayer = GetPlayer(playerID)
		if not player then return False


		'inform ai
		If player.isLocalAI() Then player.playerAI.CallOnWonAward(award)


		rem
			TODO: Bilder fuer toastmessages (+ Preis)
			 _________
			|[ ] text |
			|    text |
			'---------'
		endrem
		local text:string = GetLocale("YOU_WON_THE_AWARDNAME").Replace("%AWARDNAME%", "|b|"+award.GetTitle()+"|/b|")
		local rewardText:string = award.GetRewardText()
		if rewardText
			text :+ "~n|b|" + GetLocale("REWARD") + ":|/b|~n" + rewardText
		endif


		Local toast:TGameToastMessage = New TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(15)
		toast.SetMessageType(2) 'positive
		toast.SetCaption(GetLocale("AWARD_WON"))
		toast.SetMessageCategory(TVTMessageCategory.AWARDS)
		toast.SetText( text )

		toast.GetData().AddNumber("playerID", player.playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interest in active players contracts
		If player = GetPlayer()
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
	End Function


	Function Room_OnBombExplosion:Int(triggerEvent:TEventBase)
		GetRoomBoard().ResetPositions()

		'TODO: send out janitor to the roomboard and when arrived, he
		'      will reset the sign positions


		'=== SEND TOASTMESSAGE ===
		'local roomGUID:string = triggerEvent.GetData().GetString("roomGUID")
		'local room:TRoomBase = GetRoomCollection().GetByGUID( TLowerString.Create(roomGUID) )
		local room:TRoomBase = TRoomBase( triggerEvent.GetSender() )
		if room
			Local caption:string = GetRandomLocale("BOMB_DETONATION_IN_TVTOWER")
			Local text:string = GetRandomLocale("TOASTMESSAGE_BOMB_DETONATION_IN_TVTOWER_TEXT")

			'replace placeholders
			if room.owner > 0
				Local player:TPlayer = GetPlayer(room.owner)
				Local col:TColor = player.color
				text = text.Replace("%ROOM%", "|b||color="+col.r+","+col.g+","+col.b+"|"+Chr(9632)+"|/color|"+room.GetDescription(1, True)+"|/b||color="+col.r+","+col.g+","+col.b+"|"+Chr(9632)+"|/color|")
			else
				text = text.Replace("%ROOM%", "|b|"+room.GetDescription(1, True)+"|/b|")
			endif


			for local i:int = 1 to 4
				Local toast:TGameToastMessage = New TGameToastMessage
				'show it for some seconds
				toast.SetLifeTime(15)
				toast.SetMessageType(1) 'attention
				toast.SetMessageCategory(TVTMessageCategory.MISC)

				toast.SetCaption( caption )
				toast.SetText( text )

				toast.GetData().AddNumber("playerID", i)


				GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


				'only add if it is the active player
				if i = GetPlayerBase().playerID
					GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
				endif
			Next
		endif
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
			GetLocale("YOUR_PREVIOUS_BID_OF_X_WAS_REFUNDED").Replace("%MONEY%", "|b|"+MathHelper.DottedValue(previousBestBid)+getLocale("CURRENCY")+"|/b|") ..
		)
		'play a special sound instead of the default one
		toast.GetData().AddString("onAddMessageSFX", "positiveMoneyChange")

		toast.GetData().AddNumber("playerID", previousBestBidder)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If previousBestBidder = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
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
		endif
	End Function


	Function Production_OnFinalize:Int(triggerEvent:TEventBase)
		'only interested in auctions the player won
		Local production:TProduction = TProduction(triggerEvent.GetSender())
		If not production Then Return False


		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
		local title:string = production.productionConcept.GetTitle()
		if production.productionConcept.script.GetEpisodeNumber() > 0
			title = production.productionConcept.script.GetParentScript().GetTitle() + ": "
			title :+ production.productionConcept.script.GetEpisodeNumber() + "/" + production.productionConcept.script.GetParentScript().GetSubScriptCount()+" "
			title :+ production.productionConcept.GetTitle()
		endif

		'show it for some seconds
		toast.SetLifeTime(8)
		toast.SetMessageType(2) 'positive
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetCaption(GetLocale("SHOOTING_FINISHED"))
		toast.SetText(GetLocale("THE_LICENCE_OF_X_IS_NOW_AT_YOUR_DISPOSAL").Replace("%TITLE%", "|b|"+title+"|/b|"))

		toast.GetData().AddNumber("playerID", production.owner)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If production.owner = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
	End Function


	Function Game_OnSetPlayerBankruptLevel:Int(triggerEvent:TEventBase)
		'only interested in levels of the player
		local playerID:int = triggerEvent.GetData().GetInt("playerID", -1)

		'only interested in the first two days (afterwards player is
		'already gameover)
		if GetGame().GetPlayerBankruptLevel(playerID) > 2 then return False

		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
		local text:string
		if GetGame().GetPlayerBankruptLevel(playerID) = 0
			'show it for some seconds
			toast.SetLifeTime(8)
			toast.SetMessageType(2) 'positive
			text =  GetLocale("YOUR_BALANCE_IS_POSITIVE_AGAIN")
			text :+ "~n"
			text :+ "|color=0,125,0|"+GetLocale("YOU_ARE_NO_LONGER_IN_DANGER_TO_GET_FIRED")+"|/color|"
		elseif GetGame().GetPlayerBankruptLevel(playerID) = 1
			'show it for some seconds
			toast.SetLifeTime(8)
			toast.SetMessageType(3) 'warning
			text =  GetLocale("YOUR_BALANCE_IS_NEGATIVE")
			text :+ "~n"
			text :+ GetLocale("YOU_HAVE_X_DAYS_TO_GET_INTO_THE_BLACK").Replace("%DAYS%", 2+GetLocale("DAYS"))
			text :+ "~n"
			text :+ "|color=125,0,0|"+GetLocale("YOU_ARE_IN_DANGER_TO_GET_FIRED")+"|/color|"
		else
			'make this message a bit more sticky
			local midnight:long = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(), 23, 59, 59)

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
		endif
		toast.SetText(text)

		toast.SetCaption(GetLocale("ACCOUNT_BALANCE"))

		toast.SetMessageCategory(TVTMessageCategory.MONEY)

		toast.GetData().AddNumber("playerID", playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If playerID = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
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
			GetLocale("PROFIT_OF_X_GOT_CREDITED").Replace("%MONEY%", "|b|"+MathHelper.DottedValue(contract.GetProfit())+getLocale("CURRENCY")+"|/b|") ..
		)
		'play a special sound instead of the default one
		toast.GetData().AddString("onAddMessageSFX", "positiveMoneyChange")

		toast.GetData().AddNumber("playerID", contract.owner)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If contract.owner = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
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
			GetLocale("PENALTY_OF_X_WAS_PAID").Replace("%MONEY%", "|b|"+MathHelper.DottedValue(contract.GetPenalty())+getLocale("CURRENCY")+"|/b|") ..
		)

		toast.GetData().AddNumber("playerID", contract.owner)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )


		'only interested in active player
		If contract.owner = GetPlayerCollection().playerID
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
	End Function


	'called each time a room (the active player visits) is updated
	Function RoomOnUpdate:Int(triggerEvent:TEventBase)

		if not GetPlayer().GetFigure().IsChangingRoom()
			'handle normal right click
			If MOUSEMANAGER.IsClicked(2) or MOUSEMANAGER.IsLongClicked(1)
				'check subrooms
				'only leave a room if not in a subscreen
				'if in subscreen, go to parent one
				If ScreenCollection.GetCurrentScreen().parentScreen
					ScreenCollection.GoToParentScreen()
					MOUSEMANAGER.ResetKey(2)
					'also avoid long click (touch screen)
					MouseManager.ResetLongClicked(1)
				Else
					'leaving allowed - reset button
					If GetPlayer().GetFigure().LeaveRoom()
						MOUSEMANAGER.resetKey(2)
						'also avoid long click (touch screen)
						MouseManager.ResetLongClicked(1)
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

		local station:TStation = TStation(triggerEvent.GetData().Get("station"))
		if not station then return False

		'only interested in the players stations
		Local player:TPlayer = GetPlayer(stationMap.owner)
		If Not player Then Return False

		'in the past?
		if station.GetActivationTime() < GetWorldTime().GetTimeGone() then return False



		local readyTime:String = GetWorldTime().GetFormattedTime(station.GetActivationTime())
		local closeText:string = "MESSAGE_CLOSES_AT_TIME"
		local readyText:string = "NEW_STATION_WILL_BE_READY_AT_TIME_X"
		'prepend day if it does not finish today
		if GetWorldTime().GetDay() < GetWorldTime().GetDay(station.GetActivationTime())
			readyTime = GetWorldTime().GetFormattedDay(GetWorldTime().GetDaysRun(station.GetActivationTime()) +1) + " " + readyTime
			closeText = "MESSAGE_CLOSES_AT_DAY"
			readyText = "NEW_STATION_WILL_BE_READY_AT_DAY_X"
		endif

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

		rem - if only 1 instance allowed
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
		endif
	End Function


	Function StationMap_OnChangeReachLevel:Int(triggerEvent:TEventBase)
		Local stationMap:TStationMap = TStationMap(triggerEvent.GetSender())
		If Not stationMap Then Return False

		local reachLevel:int = triggerEvent.GetData().GetInt("reachLevel")
		local oldReachLevel:int = triggerEvent.GetData().GetInt("oldReachLevel")

		'only interested in the players stations
		Local player:TPlayer = GetPlayer(stationMap.owner)
		If Not player Then Return False

		local caption:string
		local text:string
		local text2:string

		if reachLevel > oldReachLevel
			caption = "AUDIENCE_REACH_LEVEL_INCREASED"
			text = "LEVEL_INCREASED_FROM_X_TO_Y"
			text2 = "PRICES_WILL_RISE"
		else
			caption = "AUDIENCE_REACH_LEVEL_DECREASED"
			text = "LEVEL_DECREASED_FROM_X_TO_Y"
			text2 = "PRICES_WILL_FALL"
		endif

		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
		toast.SetLifeTime(6)
		toast.SetMessageType(0)
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetPriority(2)

		toast.SetCaption( GetLocale(caption) )

		local textJoined:string = GetLocale(text2)
		if textJoined
			textJoined = GetLocale(text) + " " + textJoined
		else
			textJoined = GetLocale(text)
		endif
		toast.SetText( textJoined.Replace("%X%", "|b|"+oldReachLevel+"|/b|").Replace("%Y%", "|b|"+reachLevel+"|/b|") )

		toast.GetData().AddNumber("playerID", player.playerID)


		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )

		'only interested in active player
		If player = GetPlayer()
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		endif
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
		if GetPlayer().playerID <> station.owner Then Return False

		'in the past?
		if station.GetSubscriptionTimeLeft() < 0 then return False

		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage

		'toast.SetCloseAtWorldTime( station.GetActivationTime() )
		'toast.SetCloseAtWorldTimeText(closeText)
		toast.SetLifeTime(6)
		toast.SetMessageType(3) 'attention
		toast.SetMessageCategory(TVTMessageCategory.MISC)
		toast.SetPriority(2)

		toast.SetCaption( GetLocale("CONTRACT_ENDS_SOON") )

		local subscriptionEndTime:Long = station.GetProvider().GetSubscribedChannelEndTime(station.owner)
		local t:string
		if TStationCableNetworkUplink(station)
			t = "CABLE_NETWORK_UPLINK_CONTRACT_WITH_COMPANYX_WILL_END_AT_TIMEX_DAYX"
		elseif TStationSatelliteUplink(station)
			t = "SATELLITE_UPLINK_CONTRACT_WITH_COMPANYX_WILL_END_AT_TIMEX_DAYX"
		endif
		t = GetLocale(t)
		t = t.Replace("%COMPANYX%", station.GetProvider().name)
		t = t.Replace("%TIMEX%", GetWorldTime().GetFormattedTime(subscriptionEndTime) )
		if GetWorldTime().GetDay() = GetWorldTime().GetDay(subscriptionEndTime)
			t = t.Replace("%DAYX%", GetLocale("TODAY") )
		ElseIf GetWorldTime().GetDay() + 1 = GetWorldTime().GetDay(subscriptionEndTime)
			t = t.Replace("%DAYX%", GetLocale("TOMORROW") )
		Else
			t = t.Replace("%DAYX%", GetWorldTime().GetFormattedGameDate(subscriptionEndTime) )
		endif

		toast.SetText( t )
		toast.GetData().AddNumber("playerID", station.owner)

		'archive it for all players
		GetArchivedMessageCollection().Add( CreateArchiveMessageFromToastMessage(toast) )

		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function


	Function OnMinute:Int(triggerEvent:TEventBase)
		local now:Long = triggerEvent.GetData().GetLong("time",-1)
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
		if (minute + 5) mod 5 = 0
			GetProductionManager().Update()
		endif


		'=== CHANGE OFFER OF MOVIEAGENCY AND ADAGENCY ===
		'countdown for the refillers
		GetGame().refillMovieAgencyTime :-1
		GetGame().refillAdAgencyTime :-1
		GetGame().refillScriptAgencyTime :-1
		'refill if needed
		If GetGame().refillMovieAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("", "movieagency").hasOccupant()
				GetGame().refillMovieAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				GetGame().refillMovieAgencyTime = GetGame().refillMovieAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling movieagency", LOG_DEBUG)
				local t:long = Time.MillisecsLong()
				RoomHandler_movieagency.GetInstance().ReFillBlocks(True, 0.5)
				TLogger.Log("GameEvents.OnMinute", "... took " + (Time.MillisecsLong() - t)+"ms", LOG_DEBUG)
			EndIf
		EndIf
		If GetGame().refillScriptAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("", "scriptagency").hasOccupant()
				GetGame().refillScriptAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				GetGame().refillScriptAgencyTime = GetGame().refillScriptAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling scriptagency", LOG_DEBUG)
				local t:long = Time.MillisecsLong()
				RoomHandler_scriptagency.GetInstance().WriteNewScripts()
				RoomHandler_scriptagency.GetInstance().ReFillBlocks(True, 0.65)
				TLogger.Log("GameEvents.OnMinute", "... took " + (Time.MillisecsLong() - t)+"ms", LOG_DEBUG)
			EndIf
		EndIf
		If GetGame().refillAdAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("", "adagency").hasOccupant()
				GetGame().refillAdAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				GetGame().refillAdAgencyTime = GetGame().refillAdAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling adagency", LOG_DEBUG)
				local t:long = Time.MillisecsLong()
				If GetGame().refillAdAgencyOverridePercentage <> GetGame().refillAdAgencyPercentage
					RoomHandler_adagency.GetInstance().ReFillBlocks(True, GetGame().refillAdAgencyOverridePercentage)
					GetGame().refillAdAgencyOverridePercentage = GetGame().refillAdAgencyPercentage
				Else
					RoomHandler_adagency.GetInstance().ReFillBlocks(True, GetGame().refillAdAgencyPercentage)
				EndIf
				TLogger.Log("GameEvents.OnMinute", "... took " + (Time.MillisecsLong() - t)+"ms", LOG_DEBUG)
			EndIf
		EndIf


		'=== REFRESH INTERFACE IF NEEDED ===
		If minute = 5 Or minute = 55 Or minute = 0 Then GetInGameInterface().BottomImgDirty = True


		'=== UPDATE STATIONMAPS ===
		'checks for newly activated stations (which start to broadcast
		'then, not earlier). This avoids getting an audience recalculation
		'after the removal of a station - while other stations were
		'bought AFTER the audience got calculated (aka "cheating").
		GetStationMapCollection().Update()


		'=== ADJUST CURRENT BROADCASTS ===
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

					'pay penalty
					player.GetFinance().PayMisc(GameRules.sentXRatedPenalty)
					'remove programme from plan
					player.GetProgrammePlan().ForceRemoveProgramme(currentProgramme, day, hour)
					'set current broadcast to malfunction
					GetBroadcastManager().SetBroadcastMalfunction(player.playerID, TVTBroadcastMaterialType.PROGRAMME)
					'decrease image by 0.5%
					player.GetPublicImage().ChangeImage(New TAudience.AddFloat(-0.5))

					'chance of 25% the programme will get (tried) to get confiscated
					Local confiscateProgramme:Int = RandRange(0,100) < 25

					If confiscateProgramme
						EventManager.triggerEvent(TEventSimple.Create("publicAuthorities.onStartConfiscateProgramme", New TData.AddString("broadcastMaterialGUID", currentProgramme.GetGUID()).AddNumber("owner", player.playerID), currentProgramme, player))

						'Send out first marshal - Mr. Czwink or Mr. Czwank
						TFigureMarshal(GetGame().marshals[randRange(0,1)]).AddConfiscationJob(currentProgramme.licence.GetGUID())
					EndIf

					'emit event (eg.for ingame toastmessages)
					EventManager.triggerEvent(TEventSimple.Create("publicAuthorities.onStopXRatedBroadcast",Null , currentProgramme, player))
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
			local evKey:string = ""
			local evData:TData
			Select minute
				Case 0
					evKey = "broadcasting.BeforeStartAllNewsShowBroadcasts"
					evData = new TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.NEWSSHOW) )
				Case 4
					evKey = "broadcasting.BeforeFinishAllNewsShowBroadcasts"
					evData = new TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.NEWSSHOW) )
				Case 5
					evKey = "broadcasting.BeforeStartAllProgrammeBlockBroadcasts"
					evData = new TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.PROGRAMME) )
				Case 54
					evKey = "broadcasting.BeforeFinishAllProgrammeBlockBroadcasts"
					evData = new TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.PROGRAMME) )
				Case 55
					evKey = "broadcasting.BeforeStartAllAdBlockBroadcasts"
					evData = new TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.ADVERTISEMENT) )
				Case 59
					evKey = "broadcasting.BeforeFinishAllAdBlockBroadcasts"
					evData = new TData.Add("broadcasts", GetBroadcastManager().GetCurrentBroadcastMaterial(TVTBroadcastMaterialType.ADVERTISEMENT) )
			End Select
			if evKey and evData
				EventManager.triggerEvent(TEventSimple.Create(evKey, evData))
			endif


			'shuffle players, so each time another plan is informed the
			'first (and their "doBegin" is called earlier than others)
			'this is useful for "who broadcasted a news as first channel?"
			'things.
			local players:TPlayerBase[] = GetPlayerCollection().players[ .. ]
			For Local a:int = 0 To players.length - 2
				Local b:int = RandRange( a, players.length - 1)
				Local p:TPlayerBase = players[a]
				players[a] = players[b]
				players[b] = p
			Next


			For Local player:TPlayer = EachIn players
				player.GetProgrammePlan().InformCurrentBroadcast(day, hour, minute)
			Next


			evKey = ""
			Select minute
				Case 0
					evKey = "broadcasting.AfterStartAllNewsShowBroadcasts"
				Case 4
					evKey = "broadcasting.AfterFinishAllNewsShowBroadcasts"
				Case 5
					evKey = "broadcasting.AfterStartAllProgrammeBlockBroadcasts"
				Case 54
					evKey = "broadcasting.AfterFinishAllProgrammeBlockBroadcasts"
				Case 55
					evKey = "broadcasting.AfterStartAllAdBlockBroadcasts"
				Case 59
					evKey = "broadcasting.AfterFinishAllAdBlockBroadcasts"
			End Select
			if evKey and evData
				EventManager.triggerEvent(TEventSimple.Create(evKey, evData))
			endif
		EndIf


		'=== UPDATE LIVE PROGRAMME ===
		'(do that AFTER setting the broadcasts, so the programme data
		' knows whether it is broadcasted currently or not)
		'1) call data.update()
		'2) remove LIVE-status from programmes once they finished airing
		If minute mod 5 = 0
			GetProgrammeDataCollection().UpdateLive()
		endif

		'=== UPDATE ACHIEVEMENTS ===
		'(do that AFTER setting the broadcasts and calculating the
		' audience as some achievements check audience of a broadcast)
		GetAchievementCollection().Update(now)

		Return True
	End Function


	'things happening each hour
	Function OnHour:Int(triggerEvent:TEventBase)
		local time:Long = triggerEvent.GetData().GetLong("time",-1)
		Local day:Int = GetWorldTime().GetDay(time)
		Local hour:Int = GetWorldTime().GetHour(time)

		'=== UPDATE WORLD / WEATHER AUDIENCE MODIFIERS ===
		GetGame().UpdateBaseGameModifiers()


		'=== UPDATE AWARDS / SAMMYS ===
		GetAwardCollection().UpdateAwards()


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
			local p:TPlayer = TPlayer(pBase)
			if not p then continue

			'COLLECTION
			'loop through a copy to avoid concurrent modification
			For Local news:TNews = EachIn p.GetProgrammeCollection().news.Copy()
				If news.newsEvent.HasHappened() and news.newsEvent.HasEnded()
					p.GetProgrammeCollection().RemoveNews(news)
				EndIf
			Next

			'PLAN
			'do not remove from plan
			rem
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
				local p:TPlayer = TPlayer(pBase)
				if not p then continue

				'COLLECTION
				'news could stay there for 1.5 days (including today)
				hoursToKeep = 36

				'loop through a copy to avoid concurrent modification
				For Local news:TNews = EachIn p.GetProgrammeCollection().news.Copy()
					'if paid for the news, keep it a bit longer
					if news.IsPaid()
						minTopicalityToKeep = 0.04
					else
						minTopicalityToKeep = 0.012
					endif
					If hour - GetWorldTime().GetHour(news.GetHappenedTime()) > hoursToKeep
						p.GetProgrammeCollection().RemoveNews(news)
					elseif news.newsevent.GetTopicality() < minTopicalityToKeep
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

			'NEWSEVENTS
			'remove old news events - wait a bit more than "plan time"
			'this also gets rid of "one time" news events which should
			'have been "triggered" then
			local daysToKeep:int = int(ceil((hoursToKeep)/48.0) + 1)
			GetNewsEventCollection().RemoveOutdatedNewsEvents(daysToKeep)
		Next
		'remove from collection (reuse if possible)
		GetNewsEventCollection().RemoveEndedNewsEvents()

	End Function


	Function OnDay:Int(triggerEvent:TEventBase)
		local time:Long = triggerEvent.GetData().GetLong("time",-1)
		Local day:Int = GetWorldTime().GetDay(time)

		TLogger.Log("GameEvents.OnDay", "begin of day "+(GetWorldTime().GetDaysRun()+1)+" (real day: "+day+")", LOG_DEBUG)

		'finish upcoming programmes (set them to cinema, released...)
		GetProgrammeDataCollection().UpdateUnreleased()

		'if new day, not start day
		If GetWorldTime().GetDaysRun(time) >= 1
			GetProgrammeDataCollection().RefreshTopicalities()
			GetAdContractBaseCollection().RefreshInfomercialTopicalities()

			TAuctionProgrammeBlocks.EndAllAuctions() 'won auctions moved to programmecollection of player
			if GetWorldTime().GetDayOfYear(time) = 1
				TAuctionProgrammeBlocks.RefillAuctionsWithoutBid()
			endif


			rem
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

			'reset room signs each day to their normal position
			GetRoomBoard().ResetPositions()


			'remove no longer needed DailyBroadcastStatistics
			'by default we store maximally 1 year + current day
			local statisticDaysToKeep:int = 4 * GetWorldTime()._daysPerSeason
			GetDailyBroadcastStatisticCollection().RemoveBeforeDay( day - statisticDaysToKeep )


			'force adagency to refill their sortiment a bit more intensive
			'the next time
			'GetGame().refillAdAgencyTime = -1
			GetGame().refillAdAgencyOverridePercentage = 0.75


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

			For local playerID:int = 1 to 4
				local text:string[] = GetPlayerFinanceOverviewText(playerID, day - 1)
				For local s:string = EachIn text
					TLogger.Log("OnDay Financials", s, LOG_DEBUG)
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

		EventManager.registerListenerFunction("guiModalWindow.onClose", onGuiModalWindowClose)
		EventManager.registerListenerFunction("guiModalWindowChain.onClose", onGuiModalWindowClose)
		EventManager.registerListenerFunction("guiModalWindow.onOpen", onGuiModalWindowCreate)
		EventManager.registerListenerFunction("guiModalWindowChain.onOpen", onGuiModalWindowCreate)
		EventManager.registerListenerFunction("ToastMessageCollection.onAddMessage", onToastMessageCollectionAddMessage)
		EventManager.registerListenerFunction("app.onStart", onAppStart)
		EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverGUIObject)

	End Function


	Function onMouseOverGUIObject:Int(triggerEvent:TEventBase)
		Local obj:TGUIObject = TGUIObject(triggerEvent.GetSender())
		If Not obj Then Return False

		If obj.isDragable() And GetGameBase().cursorstate = 0
			GetGameBase().cursorstate = 1
		EndIf
		If obj.isDragged() Then GetGameBase().cursorstate = 2
	End Function


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
	TProfiler.DumpLog(LOG_NAME)
	TLogFile.DumpLogs()
End Function


'===== COMMON FUNCTIONS =====

Function GetPlayerPerformanceOverviewText:string[](day:int)
	if day = -1 then day = GetWorldTime().GetDay()
	local latestHour:int = 23
	local latestMinute:int = 59
	if day = GetWorldTime().GetDay()
		latestHour = GetWorldTime().GetDayHour()
		latestMinute = GetWorldTime().GetDayMinute()
	endif
	local now:Long = GetWorldTime().MakeTime(0, day, latestHour, latestMinute, 0)
	local midnight:Long = GetWorldTime().MakeTime(0, day+1, 0, 0, 0)
	local latestTime:string = RSet(latestHour,2).Replace(" ","0") + ":" + RSet(latestMinute,2).Replace(" ", "0")


	local text:string[]

	local title:string = LSet("Performance Stats for day " + (GetWorldTime().GetDaysRun(midnight)+1) + ". Time: 00:00 - " + latestTime, 83)

	text :+ [".-----------------------------------------------------------------------------------."]
	text :+ ["|" + title                                          + "|"]

	For local playerID:int = 1 to 4
		local bankruptcyCount:int = GetPlayer(playerID).GetBankruptcyAmount(midnight)
		local bankruptcyTime:long = GetPlayer(playerID).GetBankruptcyTime(bankruptcyCount)
		'bankruptcy happened today?
		if bankruptcyCount > 0
			local restartTime:Long = bankruptcyTime 'GetWorldTime().ModifyTime(bankruptcyTime, 0, 1, 0, 0, 0)

			'bankruptcy on that day (or more detailed: right on midnight the
			'next day)
			if GetWorldTime().GetDay(bankruptcyTime) = GetWorldTime().GetDay(midnight)
				text :+ ["| " + LSet("* Player #"+playerID+" went into bankruptcy that day !", 83) + "|"]
			endif

			'restarted later on?
			if GetWorldTime().GetDay(restartTime) = GetWorldTime().GetDay(midnight)
				text :+ ["| " + LSet("* Player #"+playerID+" (re)started at "+GetWorldTime().GetFormattedTime(restartTime) +" on day " + (GetWorldTime().getDaysRun(restartTime)+1)+" !", 83) + "|"]
			endif
		endif
	Next

	text :+ ["|---------------------------------------.----------.----------.----------.----------|"]
	text :+ ["| TITLE                                 |       P1 |       P2 |       P3 |       P4 |"]
	text :+ ["|---------------------------------------|----------|----------|----------|----------|"]

	local keys:string[]
	local values1:string[]
	local values2:string[]
	local values3:string[]
	local values4:string[]

	local adAudienceProgrammeAudienceRate:Float[4]
	local failedAdSpots:int[4]
	local sentTrailers:int[4]
	local sentInfomercials:int[4]
	local sentAdvertisements:int[4]

	local broadcastStat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day)
	if broadcastStat
		local audienceSum:Long[4]
		local adAudienceSum:Long[4]

		For local player:int = 1 to 4
			For local hour:int = 0 to latestHour
				local audience:TAudienceResultBase = broadcastStat.GetAudienceResult(player, hour, false)
				local adAudience:TAudienceResultBase = broadcastStat.GetAdAudienceResult(player, hour, false)

				local advertisement:TAdvertisement
				local adAudienceValue:int, audienceValue:int


				' AD
				if adAudience
					if TAdvertisement(adAudience.broadcastMaterial)
						advertisement = TAdvertisement(adAudience.broadcastMaterial)
						adAudienceValue = int(advertisement.contract.GetMinAudience())
					else
						sentTrailers[player-1] :+ 1
					endif
				endif

				' PROGRAMME
				if audience and audience.broadcastMaterial
					audienceValue = int(audience.audience.GetTotalSum())

					if TAdvertisement(audience.broadcastMaterial)
						sentInfomercials[player-1] :+ 1
					endif
				endif

				if advertisement
					if advertisement.isState(TAdvertisement.STATE_OK)
						adAudienceSum[player-1] :+ adAudienceValue
						audienceSum[player-1] :+ audienceValue
					elseif advertisement.isState(TAdvertisement.STATE_FAILED)
						failedAdSpots[player-1] :+ 1
					endif
				endif
			Next
			adAudienceProgrammeAudienceRate[player-1] = 0
			if adAudienceSum[player-1] > 0
				adAudienceProgrammeAudienceRate[player-1] = Float(adAudienceSum[player-1]) / audienceSum[player-1]
			endif
		Next
	endif

	keys :+ [ "AdMinAudience/ProgrammeAudience-Rate" ]
	values1 :+ [ MathHelper.NumberToString(adAudienceProgrammeAudienceRate[0]*100,2)+"%" ]
	values2 :+ [ MathHelper.NumberToString(adAudienceProgrammeAudienceRate[1]*100,2)+"%" ]
	values3 :+ [ MathHelper.NumberToString(adAudienceProgrammeAudienceRate[2]*100,2)+"%" ]
	values4 :+ [ MathHelper.NumberToString(adAudienceProgrammeAudienceRate[3]*100,2)+"%" ]

	keys :+ [ "Failed Adspots" ]
	values1 :+ [ string(failedAdSpots[0]) ]
	values2 :+ [ string(failedAdSpots[1]) ]
	values3 :+ [ string(failedAdSpots[2]) ]
	values4 :+ [ string(failedAdSpots[3]) ]
	keys :+ [ "Sent [T]railers and [I]nfomercials" ]
	values1 :+ [ "T:"+sentTrailers[0] + " I:"+sentInfomercials[0] ]
	values2 :+ [ "T:"+sentTrailers[1] + " I:"+sentInfomercials[1] ]
	values3 :+ [ "T:"+sentTrailers[2] + " I:"+sentInfomercials[2] ]
	values4 :+ [ "T:"+sentTrailers[3] + " I:"+sentInfomercials[3] ]




	'MathHelper.DottedValue(financeTotal.expense_programmeLicences)
	For local i:int = 0 until keys.length
		local line:string = "| "+LSet(StringHelper.RemoveUmlauts(keys[i]), 38) + "|"

		line :+ RSet( values1[i] + " |", 11)
		line :+ RSet( values2[i] + " |", 11)
		line :+ RSet( values3[i] + " |", 11)
		line :+ RSet( values4[i] + " |", 11)

		text :+ [line]
	Next

	text :+ ["'---------------------------------------'----------'----------'----------'----------'"]

	return text
End Function


Function GetPlayerFinanceOverviewText:string[](playerID:int, day:int)
	if day = -1 then day = GetWorldTime().GetDay()
	local latestHour:int = 23
	local latestMinute:int = 59
	if day = GetWorldTime().GetDay()
		latestHour = GetWorldTime().GetDayHour()
		latestMinute = GetWorldTime().GetDayMinute()
	endif
	local now:Long = GetWorldTime().MakeTime(0, day, latestHour, latestMinute, 0)
	local midnight:Long = GetWorldTime().MakeTime(0, day+1, 0, 0, 0)
	local latestTime:string = RSet(latestHour,2).Replace(" ","0") + ":" + RSet(latestMinute,2).Replace(" ", "0")


	'ignore player start day and fetch information about "older incarnations"
	'of that player too (bankruptcies)
	local finance:TPlayerFinance = GetPlayerFinanceCollection().GetIgnoringStartDay(playerID, day)
	local financeTotal:TPlayerFinance = GetPlayerFinanceCollection().GetTotal(playerID)

	local title:string = LSet("Finance Stats for player #" + playerID + " on day " + GetWorldTime().GetDaysRun(midnight) +" ("+GetWorldTime().GetDay(midnight)+")"+ ". Time: 00:00 - " + latestTime, 85)
	local text:string[]

	text :+ [".--------------------------------------------------------------------------------------."]
	text :+ ["| " + title                                          + "|"]
	if not finance
		text :+ ["| " + LSet("No Financial overview available for the requested day.", 85) + "|"]
	endif

	local bankruptcyCountAtMidnight:int = GetPlayer(playerID).GetBankruptcyAmount(midnight)
	'bankruptcy happened today?
	if bankruptcyCountAtMidnight > 0
		local bankruptcyCountAtDayBegin:int = GetPlayer(playerID).GetBankruptcyAmount(midnight - TWorldTime.DAYLENGTH)
		'print "player #"+playerID+": bankruptcyCountAtDayBegin=" + bankruptcyCountAtDayBegin+ "  ..AtMidnight=" + bankruptcyCountAtMidnight+"  midnight="+GetWorldTime().GetFormattedGameDate(midnight)

		For local bankruptcyCount:int = bankruptcyCountAtDayBegin to bankruptcyCountAtMidnight
			if bankruptcyCount = 0 then continue
			local bankruptcyTime:long = GetPlayer(playerID).GetBankruptcyTime(bankruptcyCount)

			rem
			'disabled: use this if restarts of players happen the next day
			local restartTime:Long = GetWorldTime().ModifyTime(bankruptcyTime, 0, 1, 0, 0, 0)

			'bankruptcy on that day (or more detailed: right on midnight the
			'next day)
			if GetWorldTime().GetDay(bankruptcyTime) = day
				text :+ ["| " + LSet("* Player #"+playerID+" went into bankruptcy that day !", 85) + "|"]
			endif
			endrem

			text :+ ["| " + LSet("* Player #"+playerID+" (re)started at "+GetWorldTime().GetFormattedTime(bankruptcyTime) + " that day!", 85) + "|"]
		Next
	endif


	if finance and financeTotal
		local titleLength:int = 30

		text :+ ["|-------------------------------------------------------------.------------------------|"]
		text :+ ["| Money:        "+Rset(MathHelper.DottedValue(finance.GetMoney()), 15)+"  |                         |           TOTAL           |"]
		text :+ ["|--------------------------------|------------.------------|-------------.-------------|"]
		text :+ ["|                                |   INCOME   |  EXPENSE   |   INCOME    |   EXPENSE   |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_TRADING_PROGRAMMELICENCES")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_programmeLicences), 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_programmeLicences), 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_programmeLicences), 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_programmeLicences), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_AD_INCOME__CONTRACT_PENALTY")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_ads), 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_penalty), 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_ads), 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_penalty), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_CALL_IN_SHOW_INCOME")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_callerRevenue), 10) + " | " + Rset("-", 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_callerRevenue), 11) + " | " + Rset("-", 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_SPONSORSHIP_INCOME__PENALTY")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_sponsorshipRevenue), 10) + " | " + Rset("-", 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_sponsorshipRevenue), 11) + " | " + Rset("-", 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_NEWS")), titleLength) + " | " + RSet("-", 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_news), 10) + " | " + RSet("-", 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_news), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_NEWSAGENCIES")), titleLength) + " | " + RSet("-", 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_newsAgencies), 10)+ " | " + RSet("-", 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_newsAgencies), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_STATIONS")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_stations), 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_stationFees), 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_stations), 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_stationFees), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_SCRIPTS")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_scripts), 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_scripts), 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_scripts), 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_scripts), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_ACTORS_AND_PRODUCTIONSTUFF")), titleLength) + " | " + RSet("-", 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_productionStuff), 10) + " | " + RSet("-", 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_productionStuff), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_STUDIO_RENT")), titleLength) + " | " + RSet("-", 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_rent), 10) + " | " + RSet("-", 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_rent), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_INTEREST_BALANCE__CREDIT")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_balanceInterest), 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_drawingCreditInterest), 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_balanceInterest), 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_drawingCreditInterest), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_CREDIT_TAKEN__REPAYED")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_creditTaken), 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_creditRepayed), 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_creditTaken), 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_creditRepayed), 11)+ " |"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_MISC")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_misc), 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_misc), 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_misc), 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_misc), 11)+ " |"]
		text :+ ["|--------------------------------|------------|------------|-------------|-------------|"]
		text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_TOTAL")), titleLength) + " | " + RSet(MathHelper.DottedValue(finance.income_total), 10) + " | " + Rset(MathHelper.DottedValue(finance.expense_total), 10) + " | " + RSet(MathHelper.DottedValue(financeTotal.income_total), 11) + " | " + Rset(MathHelper.DottedValue(financeTotal.expense_total), 11)+ " |"]
		text :+ ["'--------------------------------'------------'------------'-------------'-------------'"]
	else
		text :+ ["'--------------------------------------------------------------------------------------'"]
	endif
	return text
End Function



Function GetBroadcastOverviewString:string(day:int = -1, lastHour:int = -1)
	if day = -1 then day = GetWorldTime().GetDay()
	if lastHour = -1 then lastHour = GetWorldTime().GetDayHour()
	if day < GetWorldTime().GetDay() then lastHour = 23
	local time:Long = GetWorldTime().MakeTime(0, day, lastHour, 0, 0)

	local result:string = ""
	result :+ "==== BROADCAST OVERVIEW ====" + "~n"
	result :+ GetWorldTime().GetFormattedDate(time) + "~n"

	local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day)
	if not stat
		result :+ "no dailybroadcaststatistic for day "+day+" found." + "~n"
		return result
	endif


	For local player:int = 1 to 4
		result :+ ".----------." + "~n"
		result :+ "| PLAYER " + player + " |" + "~n"
		result :+ ".-------.--'------.---------------------------.-----------------.----------------------.---------." + "~n"
		result :+ "| TIME  | NEWS-Q  | PROGRAMME                 | QUOTE / SHARE   | ADVERTISEMENT        | MIN-Q   |" + "~n"
		result :+ "|-------+---------+---------------------------+-----------------+----------------------+---------|" + "~n"
		For local hour:int = 0 to lastHour
			local audience:TAudienceResultBase = stat.GetAudienceResult(player, hour, false)
			local newsAudience:TAudienceResultBase = stat.GetNewsAudienceResult(player, hour, false)
			local adAudience:TAudienceResultBase = stat.GetAdAudienceResult(player, hour, false)
'			local progSlot:TBroadcastMaterial = GetPlayerProgrammePlan(player).GetProgramme(day, hour)

			'old savegames
			local adSlotMaterial:TBroadcastMaterial
			if adAudience
				adSlotMaterial = adAudience.broadcastMaterial
			else
				adSlotMaterial = GetPlayerProgrammePlan(player).GetAdvertisement(day, hour)
			endif


			local progText:string, progAudienceText:string
			local adText:string, adAudienceText:string
			local newsAudienceText:string


			if audience and audience.broadcastMaterial
				progText = audience.broadcastMaterial.GetTitle()
				if not audience.broadcastMaterial.isType(TVTBroadcastMaterialType.PROGRAMME)
					progText = "[I] " + progText
				endif

				progAudienceText = RSet(int(audience.audience.GetTotalSum()), 7) + " " + RSet(MathHelper.NumberToString(audience.GetAudienceQuotePercentage()*100,2), 6)+"%"
			else
				progAudienceText = RSet(" -/- ", 7) + " " +RSet("0%", 7)
				progText = "Keine Ausstrahlung"
			endif
			progText = LSet(StringHelper.RemoveUmlauts(progText), 25)


			if newsAudience
				newsAudienceText = RSet(int(newsAudience.audience.GetTotalSum()), 7)
			else
				newsAudienceText = RSet(" -/- ", 7)
			endif


			if adSlotMaterial
				adText = LSet(adSlotMaterial.GetTitle(), 20)
				adAudienceText = RSet(" -/- ", 7)

				if adSlotMaterial.isType(TVTBroadcastMaterialType.PROGRAMME)
					adText = LSet("[T] " + StringHelper.RemoveUmlauts(adSlotMaterial.GetTitle()), 20)
				elseif adSlotMaterial.isType(TVTBroadcastMaterialType.ADVERTISEMENT)
					adAudienceText = RSet(int(TAdvertisement(adSlotMaterial).contract.GetMinAudience()),7)
				endif
			else
				adText = LSet("-/-", 20)
				adAudienceText = RSet(" -/- ", 7)
			endif

			result :+ "| " + RSet(hour, 2)+":00 | " + newsAudienceText+" | " + progText + " | " + progAudienceText+" | " + adText + " | " + adAudienceText +" |" +"~n"
		Next
		result :+ "'-------'---------'---------------------------'-----------------'----------------------'---------'" + "~n"
	Next
	return result
End Function


?bmxng and (android or ios)
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


Function DEV_switchRoom:Int(room:TRoomBase, figure:TFigure = null)
	If Not room Then Return False

	if not figure then figure = GetPlayer().GetFigure()
	'do not react if already switching
	if figure.IsChangingRoom() then Return False

	'skip if already there
	If figure.inRoom = room Then Return False

	if figure.playerID
		TLogger.Log("DEV_switchRoom", "Player #"+figure.playerID+" switching to room ~q"+room.GetName()+"~q.", LOG_DEBUG)
	else
		TLogger.Log("DEV_switchRoom", "Figure '"+figure.GetGUID()+"' switching to room ~q"+room.GetName()+"~q.", LOG_DEBUG)
	endif

	'to avoid seeing too much animation
	TInGameScreen_Room.temporaryDisableScreenChangeEffects = True


	If figure.inRoom
		'abort current screen actions (drop back dragged items etc.)
		local roomHandler:TRoomHandler = GetRoomHandlerCollection().GetHandler(figure.inRoom.GetName())
		if roomHandler then roomHandler.AbortScreenActions()

		TLogger.Log("DEV_switchRoom", "Leaving room ~q"+figure.inRoom.GetName()+"~q first.", LOG_DEBUG)
		'force leave?
		'figure.LeaveRoom(True)
		'not forcing a leave is similar to "right-click"-leaving
		'which means it signs contracts, buys programme etc
		if figure.LeaveRoom(False)
			'finish leaving room in the same moment
			figure.FinishLeaveRoom()
		else
			GetGame().SendSystemMessage("[DEV] cannot switch rooms: Leaving old room failed")
			return False
		endif
	EndIf


	'remove potential elevator passenger
	GetElevator().LeaveTheElevator(figure)

	'a) add the room as new target before all others
	'GetPlayer().GetFigure().PrependTarget(TRoomDoor.GetMainDoorToRoom(room))
	'b) set it as the only route
	figure.SetTarget( new TFigureTarget.Init( GetRoomDoorCollection().GetMainDoorToRoom(room.id) ) )
	figure.MoveToCurrentTarget()

	'call reach step 1 - so it actually reaches the target in this turn
	'already (instead of next turn - which might have another "dev_key"
	'pressed)
	figure.ReachTargetStep1()
	figure.EnterTarget()

	Return True
End Function

Function PrintCurrentTranslationState(compareLang:string="tr")
	print "=== TRANSLATION STATUS: DE - "+compareLang.ToUpper()+" ====="

	TLocalization.PrintCurrentTranslationState(compareLang)

	print "~t"
	print "=== PROGRAMMES ================="
	print "AVAILABLE:"
	print "----------"
	For local obj:TProgrammeData = EachIn GetProgrammeDataCollection().entries.Values()
		local printed:int = False
		if obj.title.Get("de") <> obj.title.Get(compareLang)
			print "* [T] de: "+ obj.title.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "+ obj.title.Get(compareLang).Replace("~n", "~n          ")
			printed = True
		endif
		if obj.description.Get("de") <> obj.description.Get(compareLang)
			print "* [D] de: "+ obj.description.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "+ obj.description.Get(compareLang).Replace("~n", "~n          ")
			printed = True
		endif
		if printed then print Chr(8203) 'zero width space, else it skips "~n"
	Next

	print "~t"
	print "MISSING:"
	print "--------"
	For local obj:TProgrammeData = EachIn GetProgrammeDataCollection().entries.Values()
		local printed:int = False
		if obj.title.Get("de") = obj.title.Get(compareLang)
			print "* [T] de: "+ obj.title.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "
			printed = True
		endif
		if obj.description.Get("de") = obj.description.Get(compareLang)
			print "* [D] de: "+ obj.description.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "
			printed = True
		endif
		if printed then print Chr(8203) 'zero width space, else it skips "~n"
	Next


	print "~t"
	print "=== ADCONTRACTS ================"
	print "AVAILABLE:"
	print "----------"
	For local obj:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
		local printed:int = False
		if obj.title.Get("de") <> obj.title.Get(compareLang)
			print "* [T] de: "+ obj.title.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "+ obj.title.Get(compareLang).Replace("~n", "~n          ")
			printed = True
		endif
		if obj.description.Get("de") <> obj.description.Get(compareLang)
			print "* [D] de: "+ obj.description.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "+ obj.description.Get(compareLang).Replace("~n", "~n          ")
			printed = True
		endif
		if printed then print Chr(8203) 'zero width space, else it skips "~n"
	Next

	print "~t"
	print "MISSING:"
	print "--------"
	For local obj:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
		local printed:int = False
		if obj.title.Get("de") = obj.title.Get(compareLang)
			print "* [T] de: "+ obj.title.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "
			printed = True
		endif
		if obj.description.Get("de") = obj.description.Get(compareLang)
			print "* [D] de: "+ obj.description.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "
			printed = True
		endif
		if printed then print Chr(8203) 'zero width space, else it skips "~n"
	Next


	print "~t"
	print "=== NEWSEVENTS ================="
	print "AVAILABLE:"
	print "----------"
	For local obj:TNewsEvent = EachIn GetNewsEventCollection().newsEvents.Values()
		local printed:int = False
		if obj.title.Get("de") <> obj.title.Get(compareLang)
			print "* [T] de: "+ obj.title.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "+ obj.title.Get(compareLang).Replace("~n", "~n          ")
			printed = True
		endif
		if obj.description.Get("de") <> obj.description.Get(compareLang)
			print "* [D] de: "+ obj.description.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "+ obj.description.Get(compareLang).Replace("~n", "~n          ")
			printed = True
		endif
		if printed then print Chr(8203) 'zero width space, else it skips "~n"
	Next

	print "~t"
	print "MISSING:"
	print "--------"
	For local obj:TNewsEvent = EachIn GetNewsEventCollection().newsEvents.Values()
		local printed:int = False
		if obj.title.Get("de") = obj.title.Get(compareLang)
			print "* [T] de: "+ obj.title.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "
			printed = True
		endif
		if obj.description.Get("de") = obj.description.Get(compareLang)
			print "* [D] de: "+ obj.description.Get("de").Replace("~n", "~n          ")
			print "      "+compareLang+": "
			printed = True
		endif
		if printed then print Chr(8203) 'zero width space, else it skips "~n"
	Next
	print "================================"
End Function


Function StartApp:Int()
	TProfiler.Enter("StartApp")

	?bmxng and (android or ios)
	SetEventFilterCallback(handleMobileDeviceEvents)
	?

	'assign dev config (resources are now loaded)
	GameRules.devConfig = TData(GetRegistry().Get("DEV_CONFIG", New TData))

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
	MainMenuJanitor.area.position.SetY(600)
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


	'example for ingame-help "MainMenu"
	'IngameHelpWindowCollection.Add(new TIngameHelpWindow.Init(GetLocale("WELCOME"), "Willkommen bei TVTower", "MainMenu"))


	'temporary solution
	for local screen:TScreen = EachIn ScreenCollection.screens.Values()
		local helpTextKeyTitle:string = "INGAME_HELP_TITLE_"+screen.GetName()
		local helpTextKeyText:string = "INGAME_HELP_TEXT_"+screen.GetName()
		local helpText:string = GetLocale(helpTextKeyText)
		local helpTitle:string = GetLocale(helpTextKeyTitle)
		if helpText = helpTextKeyText
			print "Kein Hilfetext gefunden fuer ~q"+helpTextKeyText+"~q"
		else
			print "Hilfetext gefunden fuer ~q"+helpTextKeyText+"~q -> "+screen.GetName()
			IngameHelpWindowCollection.Add( new TIngameHelpWindow.Init(GetLocale(helpTitle), GetLocale(helpText), screen.GetName()) )
		endif
	Next


	'generic ingame-help (available via "F1")
	local manualContent:string = LoadText("Spielanleitung.txt").Replace("~r~n", "~n").Replace("~r", "~n")
	local manualWindow:TIngameHelpWindow = new TIngameHelpWindow.Init(GetLocale("MANUAL"), manualContent, "GameManual")
	manualWindow.EnableHideOption(False)
	IngameHelpWindowCollection.Add(manualWindow)


	'trigger initial ingamehelp for screen "MainMenu" as it is not called
	'for the first screen
	IngameHelpWindowCollection.ShowByHelpGUID("MainMenu")

	App.Start()
	TProfiler.Leave("StartApp")
End Function

Function ShowApp:Int()
	TProfiler.Enter("ShowApp")

	'=== LOAD LOCALIZATION ===
	'load all localizations
	TLocalization.LoadLanguageFiles("res/lang/lang_*.txt")
	'select user language (defaulting to "de")
	TLocalization.SetCurrentLanguage(App.config.GetString("language", "de"))


	'Menu
	ScreenMainMenu = New TScreen_MainMenu.Create("MainMenu")
	ScreenCollection.Add(ScreenMainMenu)

	'go into the start menu
	GetGame().SetGamestate(TGame.STATE_MAINMENU)

	TProfiler.Leave("ShowApp")
End Function


Function StartTVTower(start:Int=True)
	Global InitialResourceLoadingDone:Int = False
	global AppSuspendedProcessed:int = False

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
	TLocalization.SetFallbackLanguage("en")

	'c) everything loaded - normal game loop
TProfiler.Enter("GameLoop")
	StartApp()
	Repeat
		if AppSuspended()
			if not AppSuspendedProcessed
				TLogger.Log("App", "App suspended.", LOG_DEBUG)
				AppSuspendedProcessed = True
			endif
		elseif AppSuspendedProcessed
			TLogger.Log("App", "App resumed.", LOG_DEBUG)
			AppSuspendedProcessed = False
		endif

		'handle if app is run in background (mobile devices like android/iOS)
		App.ProcessRunningInBackground()

		GetDeltaTimer().Loop()

		'process events not directly triggered
		'process "onMinute" etc. -> App.OnUpdate, App.OnDraw ...
TProfiler.Enter("EventManager")
		EventManager.update()
TProfiler.Leave("EventManager")
		'If RandRange(0,20) = 20 Then GCCollect()
	Until TApp.ExitApp
TProfiler.Leave("GameLoop")

	'take care of network
	If GetGame().networkgame Then Network.DisconnectFromServer()
End Function