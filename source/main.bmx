'Application: TVGigant/TVTower
'Author: Ronny Otto & Manuel Vögele

SuperStrict

Import brl.timer
Import brl.Graphics
Import brl.glmax2d
Import "Dig/base.util.registry.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.registry.imageloader.bmx"
Import "Dig/base.util.registry.bitmapfontloader.bmx"
Import "Dig/base.util.registry.soundloader.bmx"
Import "Dig/base.util.luaengine.bmx"

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
Import "Dig/base.framework.tooltip.bmx"


Import "basefunctions_network.bmx"
Import "basefunctions.bmx"
Import "basefunctions_screens.bmx"
Import "common.misc.dialogue.bmx"
Import "game.world.bmx"
Import "game.toastmessage.bmx"
Import "game.figure.base.bmx"

?Linux
Import "external/bufferedglmax2d/bufferedglmax2d.bmx"
?Win32
Import brl.D3D9Max2D
Import brl.D3D7Max2D
?Threaded
Import brl.Threads
?

'game specific
Import "game.gamerules.bmx"
Import "game.registry.loaders.bmx"
Import "game.exceptions.bmx"

Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.base.bmx"
Import "game.player.finance.bmx"
Import "game.player.boss.bmx"
'Import "game.player.bmx"
Import "game.stationmap.bmx"

'needed by gamefunctions
Import "game.broadcastmaterial.programme.bmx"
'needed by game.player.bmx
Import "game.player.programmecollection.bmx"
'needed by game.player.bmx
Import "game.player.programmeplan.bmx"

Import "game.room.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.betty.bmx"

Import "game.database.bmx"

'===== Includes =====
Include "game.player.bmx"

'Types: - TError - Errorwindows with handling
'		- base class For buttons And extension newsbutton
Include "gamefunctions.bmx"

Include "game.ingameinterface.bmx"

Include "gamefunctions_screens.bmx"
Include "gamefunctions_tvprogramme.bmx"  		'contains structures for TV-programme-data/Blocks and dnd-objects
Include "gamefunctions_rooms.bmx"				'basic roomtypes with handling
Include "gamefunctions_ki.bmx"					'LUA connection
Include "gamefunctions_sound.bmx"				'TVTower spezifische Sounddefinitionen
Include "gamefunctions_people.bmx"				'Angestellte und Personen
Include "gamefunctions_production.bmx"			'Alles was mit Filmproduktion zu tun hat
Include "gamefunctions_debug.bmx"
Include "gamefunctions_network.bmx"

Include "gamefunctions_elevator.bmx"
Include "game.figure.bmx"
Include "game.building.bmx"
Include "game.newsagency.bmx"

Include "game.base.bmx"

'===== Globals =====
Global VersionDate:String = LoadText("incbin::source/version.txt")
Global VersionString:String = "ALPHA version ~q" + VersionDate+"~q"
Global CopyrightString:String = "by Ronny Otto & Manuel Vögele"
Global App:TApp = Null
Global Game:TGame
Global InGame_Chat:TGUIChat
Global PlayerDetailsTimer:Int = 0
Global MainMenuJanitor:TFigureJanitor
Global ScreenGameSettings:TScreen_GameSettings = Null
Global ScreenMainMenu:TScreen_MainMenu = Null
Global GameScreen_World:TInGameScreen_World = Null
Global headerFont:TBitmapFont
Global Init_Complete:Int = 0

Global RURC:TRegistryUnloadedResourceCollection = TRegistryUnloadedResourceCollection.GetInstance()


'==== Initialize ====
AppTitle = "TVTower: " + VersionString
TLogger.Log("CORE", "Starting TVTower, "+VersionString+".", LOG_INFO )

'===== SETUP LOGGER FILTER =====
TLogger.setLogMode(LOG_ALL)
TLogger.setPrintMode(LOG_ALL )

'print "ALLE MELDUNGEN AUS"
'TLogger.SetPrintMode(0)

'TLogger.setPrintMode(LOG_ALL &~ LOG_AI ) 'all but ai
'THIS IS TO REMOVE CLUTTER FOR NON-DEVS
'@MANUEL: comment out when doing DEV to see LOG_DEV-messages
'TLogger.changePrintMode(LOG_DEV, FALSE)
'TLogger.changePrintMode(LOG_ERROR | LOG_DEV | LOG_AI, true)



'Enthaelt Verbindung zu Einstellungen und Timern, sonst nix
Type TApp
	Field devConfig:TData = New TData
	'developer/base configuration
	Field configBase:TData = New TData
	'configuration containing base + user
	Field config:TData = New TData
	'draw logo for screenshot ?
	Field prepareScreenshot:Int	= 0

	'only used for debug purpose (loadingtime)
	Field creationTime:Int
	'store listener for music loaded in "startup"
	Field OnLoadMusicListener:TLink

	Global baseResourcesLoaded:Int		= 0						'able to draw loading screen?
	Global baseResourceXmlUrl:String	= "config/startup.xml"	'holds bg for loading screen and more

	Global ExitApp:Int 						= 0		 			'=1 and the game will exit
	Global ExitAppDialogue:TGUIModalWindow	= Null
	Global ExitAppDialogueTime:Int			= 0					'creation time for "double escape" to abort
	Global ExitAppDialogueEventListeners:TList = CreateList()
	Global settingsBasePath:String = "config/settings.xml"
	Global settingsUserPath:String = "config/settings.user.xml"

	Function Create:TApp(updatesPerSecond:Int = 60, framesPerSecond:Int = 30, vsync:Int=True, initializeGUI:Int=True)
		Local obj:TApp = New TApp
		obj.creationTime = MilliSecs()

		If initializeGUI Then
			GetDeltatimer().Init(updatesPerSecond, framesPerSecond)
			GetDeltaTimer()._funcUpdate = update
			GetDeltaTimer()._funcRender = render		

			'register to quit confirmation dialogue
			EventManager.registerListenerFunction( "guiModalWindow.onClose", 	TApp.onAppConfirmExit )
			EventManager.registerListenerFunction( "RegistryLoader.onLoadXmlFromFinished",	TApp.onLoadXmlFromFinished )
			obj.OnLoadMusicListener = EventManager.registerListenerFunction( "RegistryLoader.onLoadResource",	TApp.onLoadMusicResource )
	
			obj.LoadSettings()
			obj.ApplySettings()
			'override settings with app arguments (params when executing)
			obj.ApplyAppArguments()
	
			GetGraphicsManager().SetVsync(vsync)
			GetGraphicsManager().SetResolution(800,600)
			GetGraphicsManager().InitGraphics()
			
			'load graphics needed for loading screen,
			'load directly (no delayed loading)
			obj.LoadResources(obj.baseResourceXmlUrl, True)			
		EndIf

		Return obj
	End Function


	'check for various arguments to the binary (eg. "TVTower -opengl")
	Method ApplyAppArguments:int()
		local argNumber:int = 0
		For local arg:string = EachIn AppArgs
			'only interested in args starting with "-"
			if arg.Find("-") <> 0 then continue

			Select arg.ToLower()
				?Win32
				case "-directx7", "-directx"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 7", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX7)
				case "-directx9"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 9", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX9)
				?
				case "-opengl"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: OpenGL", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_OPENGL)
				case "-bufferedopengl"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: Buffered OpenGL", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_BUFFEREDOPENGL)
			End Select
		Next
	End Method


	'if no startup-music was defined, try to play menu music if some
	'is loaded
	Function onLoadMusicResource( triggerEvent:TEventBase )
		Local resourceName:String = triggerEvent.GetData().GetString("resourceName")
		If resourceName = "MUSIC"
			'if no music is played yet, try to get one from the "menu"-playlist
			If Not GetSoundManager().isPlaying() Then GetSoundManager().PlayMusicPlaylist("menu")
		EndIf
	End Function


	Function onLoadXmlFromFinished( triggerEvent:TEventBase )
		If triggerEvent.getData().getString("uri") = TApp.baseResourceXmlUrl
			TApp.baseResourcesLoaded = 1
		EndIf
	End Function


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


	Method ApplySettings:Int()
		GetGraphicsManager().SetFullscreen(config.GetBool("fullscreen", False))
		GetGraphicsManager().SetRenderer(config.GetInt("renderer", GetGraphicsManager().GetRenderer()))
		GetGraphicsManager().SetColordepth(config.GetInt("colordepth", 16))

		TSoundManager.SetAudioEngine(config.GetString("sound_engine", "AUTOMATIC"))
		TSoundManager.GetInstance().MuteMusic(Not config.GetBool("sound_music", True))
		TSoundManager.GetInstance().MuteSfx(Not config.GetBool("sound_effects", True))

		If Game Then Game.LoadConfig(config)
	End Method


	Method LoadResources:Int(path:String="config/resources.xml", directLoad:Int=False)
		Local registryLoader:TRegistryLoader = New TRegistryLoader
		registryLoader.LoadFromXML(path, directLoad)
	End Method


	Method SetLanguage:Int(languageCode:String="de")
		'skip if the same language is already set
		If TLocalization.GetCurrentLanguageCode() = languageCode Then Return False

		'select language
		TLocalization.SetCurrentLanguage(languageCode)

		'store in config - for auto save of user settings
		config.Add("language", languageCode)
		
		'inform others - so eg. buttons can re-localize
		EventManager.triggerEvent(TEventSimple.Create("Language.onSetLanguage", New TData.Add("languageCode", languageCode), Self))
		Return True
	End Method


	Method Start()
		AppEvents.Init()

		'systemupdate is called from within "update" (lower priority updates)
		EventManager.registerListenerFunction("App.onSystemUpdate", AppEvents.onAppSystemUpdate )
		'so we could create special fonts and other things
		EventManager.triggerEvent( TEventSimple.Create("App.onStart") )

		'from now on we are no longer interested in loaded elements
		'as we are no longer in the loading screen (-> silent loading)
		If OnLoadMusicListener Then EventManager.unregisterListenerByLink( OnLoadMusicListener )

		TLogger.Log("TApp.Start()", "loading time: "+(MilliSecs() - creationTime) +"ms", LOG_INFO)
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

'		Local img:TPixmap = GrabPixmap(0, 0, GraphicsWidth(), GraphicsHeight())
		Local img:TPixmap = VirtualGrabPixmap(0, 0, GraphicsWidth(), GraphicsHeight())

		'add overlay
		If overlay Then overlay.DrawOnImage(img, GetGraphicsManager().GetWidth() - overlay.GetWidth() - 10, 10, -1, null, TColor.Create(255,255,255,0.5))

		'remove alpha
		SavePixmapPNG(ConvertPixmap(img, PF_RGB888), filename)

		TLogger.Log("App.SaveScreenshot", "Screenshot saved as ~q"+filename+"~q", LOG_INFO)
	End Method


	Function Update:Int()
		TProfiler.Enter("Update")
		'every 3rd update do a system update
		If GetDeltaTimer().timesUpdated Mod 3 = 0
			EventManager.triggerEvent( TEventSimple.Create("App.onSystemUpdate",Null) )
		EndIf

		TProfiler.Enter("RessourceLoader")
		'check for new resources to load
		RURC.Update()
		TProfiler.Leave("RessourceLoader")
		

		KEYMANAGER.Update()
		MOUSEMANAGER.Update()

		'fetch and cache mouse and keyboard states for this cycle
		GUIManager.StartUpdates()


		'enable reading of clicked states (just for the case of being
		'diabled because of an exitDialogue exists)
		MouseManager.Enable(1)
		MouseManager.Enable(2)

		GUIManager.Update("SYSTEM")

		'=== UPDATE TOASTMESSAGES ===
		GetToastMessageCollection().Update()


		'as long as the exit dialogue is open, do not accept clicks to
		'non gui elements (eg. to leave rooms)
		If App.ExitAppDialogue
			MouseManager.ResetKey(2)

			'this sets all IsClicked(), IsHit() to False
			MouseManager.Disable(1)
			MouseManager.Disable(2)
		EndIf

		'ignore shortcuts if a gui object listens to keystrokes
		'eg. the active chat input field
		If Not GUIManager.GetKeystrokeReceiver()
			'keywrapper has "key every milliseconds" functionality
			If KEYWRAPPER.hitKey(KEY_ESCAPE) Then TApp.CreateConfirmExitAppDialogue()

			If App.devConfig.GetBool("DEV_KEYS", False)
				'(un)mute sound
				'M: (un)mute all sounds
				'SHIFT+M: (un)mute all sound effects
				'CTRL+M: (un)mute all music
				If KEYMANAGER.IsHit(KEY_M)
					If KEYMANAGER.IsDown(KEY_LSHIFT) Or KEYMANAGER.IsDown(KEY_RSHIFT)
						TSoundManager.GetInstance().MuteSfx(Not TSoundManager.GetInstance().HasMutedSfx())
					ElseIf KEYMANAGER.IsDown(KEY_LCONTROL) Or KEYMANAGER.IsDown(KEY_RCONTROL)
						TSoundManager.GetInstance().MuteMusic(Not TSoundManager.GetInstance().HasMutedMusic())
					Else
						TSoundManager.GetInstance().Mute(Not TSoundManager.GetInstance().IsMuted())
					EndIf
				EndIf

				If Game.gamestate = TGame.STATE_RUNNING
					If KEYMANAGER.IsDown(KEY_UP) Then GetWorldTime().AdjustTimeFactor(+5)
					If KEYMANAGER.IsDown(KEY_DOWN) Then GetWorldTime().AdjustTimeFactor(-5)

					If KEYMANAGER.IsDown(KEY_RIGHT)
						TEntity.globalWorldSpeedFactor :+ 0.05
						GetWorldTime().AdjustTimeFactor(+5)
					EndIf
					If KEYMANAGER.IsDown(KEY_LEFT) Then
						TEntity.globalWorldSpeedFactor = Max( TEntity.globalWorldSpeedFactor - 0.05, 0)
						GetWorldTime().AdjustTimeFactor(-5)
					EndIf

					if KEYMANAGER.IsHit(KEY_Y)
						'print "send to chef:"
						'GetPlayer().SendToBoss()

						'GetWorld().Weather.SetPressure(-14)
						'GetWorld().Weather.SetTemperature(-10)

						'select a random licence
						local licence:TProgrammeLicence = GetPlayer().GetProgrammeCollection().GetRandomMovieLicence()
						'send marshal to confiscate the licence
						Game.marshals[rand(0,1)].AddConfiscationJob( licence.GetGUID() )
					endif

				
					if not GetPlayer().GetFigure().isChangingRoom()
						If KEYMANAGER.IsHit(KEY_1) Then Game.SetActivePlayer(1)
						If KEYMANAGER.IsHit(KEY_2) Then Game.SetActivePlayer(2)
						If KEYMANAGER.IsHit(KEY_3) Then Game.SetActivePlayer(3)
						If KEYMANAGER.IsHit(KEY_4) Then Game.SetActivePlayer(4)

						If KEYMANAGER.IsHit(KEY_W) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("adagency") )
						If KEYMANAGER.IsHit(KEY_A) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("archive", GetPlayerCollection().playerID) )
						If KEYMANAGER.IsHit(KEY_B) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("betty") )
						If KEYMANAGER.IsHit(KEY_F) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("movieagency"))
						If KEYMANAGER.IsHit(KEY_O) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("office", GetPlayerCollection().playerID))
						If KEYMANAGER.IsHit(KEY_C) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("boss", GetPlayerCollection().playerID))

						'e wie "employees" :D
						If KEYMANAGER.IsHit(KEY_E) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("credits"))
						If KEYMANAGER.IsHit(KEY_N) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("news", GetPlayerCollection().playerID))
						If KEYMANAGER.IsHit(KEY_R) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("roomboard"))
					endif
				EndIf
				If KEYMANAGER.IsHit(KEY_5) Then GetWorldTime().SetTimeFactor(60*60.0)  '60 virtual minutes per realtime second
				If KEYMANAGER.IsHit(KEY_6) Then GetWorldTime().SetTimeFactor(120*60.0) '120 minutes per second
				If KEYMANAGER.IsHit(KEY_7) Then GetWorldTime().SetTimeFactor(180*60.0) '180 minutes per second
				If KEYMANAGER.IsHit(KEY_8) Then GetWorldTime().SetTimeFactor(240*60.0) '240 minute per second
				If KEYMANAGER.IsHit(KEY_9) Then GetWorldTime().SetTimeFactor(1*60.0)   '1 minute per second
				If KEYMANAGER.IsHit(KEY_Q) Then TVTDebugQuoteInfos = 1 - TVTDebugQuoteInfos

				If KEYMANAGER.IsHit(KEY_P) Then GetPlayerCollection().Get().GetProgrammePlan().printOverview()
				'If KEYMANAGER.IsHit(KEY_P) Then GetProgrammeLicenceCollection().PrintMovies()

				'Save game only when in a game
				If game.gamestate = TGame.STATE_RUNNING
					If KEYMANAGER.IsHit(KEY_S) Then TSaveGame.Save("savegame.xml")
				EndIf

				If KEYMANAGER.IsHit(KEY_L) Then TSaveGame.Load("savegame.xml")

				If KEYMANAGER.IsHit(KEY_D) Then TVTDebugInfos = 1 - TVTDebugInfos

				If KEYMANAGEr.Ishit(KEY_K) then GetFigureCollection().KickAllFromRooms()

				'send terrorist to a random room
				If KEYMANAGER.IsHit(KEY_T) and not Game.networkGame
					Global whichTerrorist:int = 1
					whichTerrorist = 1 - whichTerrorist

					local targetRoom:TRoom
					Repeat
						targetRoom = GetRoomCollection().GetRandom()
					until targetRoom.name <> "building"
					
					Game.terrorists[whichTerrorist].SetDeliverToRoom( targetRoom )
				EndIf

				If Game.isGameLeader()
					If KEYMANAGER.Ishit(Key_F1) And GetPlayerCollection().Get(1).isAI() Then GetPlayerCollection().Get(1).PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F2) And GetPlayerCollection().Get(2).isAI() Then GetPlayerCollection().Get(2).PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F3) And GetPlayerCollection().Get(3).isAI() Then GetPlayerCollection().Get(3).PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F4) And GetPlayerCollection().Get(4).isAI() Then GetPlayerCollection().Get(4).PlayerKI.reloadScript()
				EndIf

				'only announce news in single player mode - as announces
				'are done on all clients on their own.
				If KEYMANAGER.Ishit(Key_F5) and not Game.networkGame Then GetNewsAgency().AnnounceNewNewsEvent()

				If KEYMANAGER.Ishit(Key_F6) Then GetSoundManager().PlayMusicPlaylist("default")

				If KEYMANAGER.Ishit(Key_F9)
					If (KIRunning)
						TLogger.Log("CORE", "AI deactivated", LOG_INFO | LOG_DEV )
						KIRunning = False
					Else
						TLogger.Log("CORE", "AI activated", LOG_INFO | LOG_DEV )
						KIRunning = True
					EndIf
				EndIf
				If KEYMANAGER.Ishit(Key_F10)
					If (KIRunning)
						For Local fig:TFigure = EachIn GetFigureCollection().list
							If Not fig.isActivePlayer() Then fig.moveable = False
						Next
						TLogger.Log("CORE", "AI Figures deactivated", LOG_INFO | LOG_DEV )
						KIRunning = False
					Else
						For Local fig:TFigure = EachIn GetFigureCollection().list
							If Not fig.isActivePlayer() Then fig.moveable = True
						Next
						TLogger.Log("CORE", "AI activated", LOG_INFO | LOG_DEV )
						KIRunning = True
					EndIf
				EndIf
			EndIf
		EndIf


		TError.UpdateErrors()
		Game.cursorstate = 0

		ScreenCollection.UpdateCurrent(GetDeltaTimer().GetDelta())
	
		If Not GuiManager.GetKeystrokeReceiver() And KEYWRAPPER.hitKey(KEY_ESCAPE)
			TApp.CreateConfirmExitAppDialogue()
		EndIf
		If AppTerminate() Then TApp.ExitApp = True

		'check if we need to make a screenshot
		If KEYMANAGER.IsHit(KEY_F12) Then App.prepareScreenshot = 1

		If Game.networkGame Then Network.Update()

		GUIManager.EndUpdates() 'reset modal window states

		TProfiler.Leave("Update")
	End Function




	Function Render:Int()
		TProfiler.Enter("Draw")
		ScreenCollection.DrawCurrent(GetDeltaTimer().GetTween())

		'=== RENDER TOASTMESSAGES ===
		'below everything else of the interface: our toastmessages
		GetToastMessageCollection().Render(0,0)


'		SetBlend AlphaBlend
		Local textX:Int = 5
		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * 0.25
		SetColor 0,0,0
		If App.devConfig.GetBool("DEV_OSD", False)
			DrawRect(0,0, 800,13)
		else
			DrawRect(0,0, 175,13)
		endif
		oldCol.SetRGBA()

		GetBitmapFontManager().baseFont.drawStyled("Speed:" + Int(GetWorldTime().GetVirtualMinutesPerSecond() * 100), textX , 0)
		textX:+75
		GetBitmapFontManager().baseFont.draw("FPS: "+GetDeltaTimer().currentFps, textX, 0)
		textX:+50
		GetBitmapFontManager().baseFont.draw("UPS: " + Int(GetDeltaTimer().currentUps), textX,0)
		textX:+50

		If App.devConfig.GetBool("DEV_OSD", False)
			GetBitmapFontManager().baseFont.draw("Loop: "+Int(GetDeltaTimer().getLoopTimeAverage())+"ms", textX,0)
			textX:+100
			'update time per second
			GetBitmapFontManager().baseFont.draw("UTPS: " + Int(GetDeltaTimer()._currentUpdateTimePerSecond), 560,0)
			textX:+60
			'render time per second
			GetBitmapFontManager().baseFont.draw("RTPS: " + Int(GetDeltaTimer()._currentRenderTimePerSecond), 620,0)
			textX:+60


			'RON: debug purpose - see if the managed guielements list increase over time
			If TGUIObject.GetFocusedObject()
				GetBitmapFontManager().baseFont.draw("GUI objects: "+ GUIManager.list.count()+"[d:"+GUIManager.GetDraggedCount()+"] focused: "+TGUIObject.GetFocusedObject()._id, textX,0)
				textX:+160
			Else
				GetBitmapFontManager().baseFont.draw("GUI objects: "+ GUIManager.list.count()+"[d:"+GUIManager.GetDraggedCount()+"]" , textX,0)
				textX:+130
			EndIf

			If game.networkgame And Network.client
				GetBitmapFontManager().baseFont.draw("Ping: "+Int(Network.client.latency)+"ms", textX,0)
				textX:+50
			EndIf
		EndIf

		If TVTDebugInfos and not GetPlayer().GetFigure().inRoom
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
				roomName = "Building"
				If fig.inRoom
					roomName = fig.inRoom.Name
				ElseIf fig.IsInElevator()
					roomName = "InElevator"
				ElseIf fig.IsAtElevator()
					roomName = "AtElevator"
				EndIf
				GetBitmapFontManager().baseFont.draw("P " + (i + 1) + ": "+roomName, 5, 70 + i * 11)
			Next

			If ScreenCollection.GetCurrentScreen()
				GetBitmapFontManager().baseFont.draw("onScreen: "+ScreenCollection.GetCurrentScreen().name, 5, 120)
			Else
				GetBitmapFontManager().baseFont.draw("onScreen: Main", 5, 120)
			EndIf


			GetBitmapFontManager().baseFont.draw("Elevator routes:", 5,140)
			Local routepos:Int = 0
			Local startY:Int = 155
			If Game.networkgame Then startY :+ 4*11

			Local callType:String = ""

			Local directionString:String = "up"
			If GetBuilding().elevator.Direction = 1 Then directionString = "down"
			Local debugString:String =	"floor:" + GetBuilding().elevator.currentFloor +..
										"->" + GetBuilding().elevator.targetFloor +..
										" doorState:"+GetBuilding().elevator.ElevatorStatus

			GetBitmapFontManager().baseFont.draw(debugString, 5, startY)


			If GetBuilding().elevator.RouteLogic.GetSortedRouteList() <> Null
				For Local FloorRoute:TFloorRoute = EachIn GetBuilding().elevator.RouteLogic.GetSortedRouteList()
					If floorroute.call = 0 Then callType = " 'send' " Else callType= " 'call' "
					GetBitmapFontManager().baseFont.draw(FloorRoute.floornumber + callType + FloorRoute.who.Name, 5, startY + 15 + routepos * 11)
					routepos:+1
				Next
			Else
				GetBitmapFontManager().baseFont.draw("recalculate", 5, startY + 15)
			EndIf


			For Local i:Int = 0 To 3
				GetBitmapFontManager().baseFont.Draw("Image #"+i+": "+GetPublicImageCollection().Get(i+1).GetAverageImage(), 10, 320 + i*13)
			Next


			GetWorld().RenderDebug(660,0, 140, 130)
			'GetPlayer().GetFigure().RenderDebug(new TVec2D.Init(660, 150))
		EndIf
		'show quotes even without "DEV_OSD = true"
		If TVTDebugQuoteInfos then Game.DebugAudienceInfo.Draw()


		'draw loading resource information
		RenderLoadingResourcesInformation()


		'draw system things at last (-> on top)
		GUIManager.Draw("SYSTEM")

		'default pointer
		If Game.cursorstate = 0 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-9, 	MouseManager.y-2	,0)
		'open hand
		If Game.cursorstate = 1 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11, 	MouseManager.y-8	,1)
		'grabbing hand
		If Game.cursorstate = 2 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11,	MouseManager.y-16	,2)

		'if a screenshot is generated, draw a logo in
		If App.prepareScreenshot = 1
			App.SaveScreenshot(GetSpriteFromRegistry("gfx_startscreen_logoSmall"))
			App.prepareScreenshot = False
		EndIf


		GetGraphicsManager().Flip(GetDeltaTimer().HasLimitedFPS())

		TProfiler.Leave("Draw")
		Return True
	End Function


	Function RenderLoadingResourcesInformation:Int()
		'do nothing if there is nothing to load
		If RURC.FinishedLoading() Then Return True

		SetAlpha 0.2
		SetColor 50,0,0
		DrawRect(0, GraphicsHeight() - 20, GraphicsWidth(), 20)
		SetAlpha 1.0
		SetColor 255,255,255
		DrawText("Loading: "+RURC.loadedCount+"/"+RURC.toLoadCount+"  "+String(RURC.loadedLog.Last()), 0, 580)
	End Function


	Function onAppConfirmExit:Int(triggerEvent:TEventBase)
		Local dialogue:TGUIModalWindow = TGUIModalWindow(triggerEvent.GetSender())
		If Not dialogue Then Return False

		'store closeing time of this modal window (does not matter which
		'one) to skip creating another exit dialogue within a certain
		'timeframe
		ExitAppDialogueTime = MilliSecs()

		'not interested in other dialogues
		If dialogue <> TApp.ExitAppDialogue Then Return False

		Local buttonNumber:Int = triggerEvent.GetData().getInt("closeButton",-1)


		'approve exit
		If buttonNumber = 0
rem
	disable until "new game" works properly
			'if within a game - just return to mainmenu
			if Game.gamestate = TGame.STATE_RUNNING
				'adjust darkened Area to fullscreen!
				'but do not set new screenArea to avoid "jumping"
				ExitAppDialogue.darkenedArea.Init(0,0,800,600)
				'ExitAppDialogue.screenArea.Init(0,0,800,600)

				Game.SetGameState(TGame.STATE_MAINMENU)
			else
				TApp.ExitApp = True
			endif
endrem
			TApp.ExitApp = True
		EndIf
		'remove connection to global value (guimanager takes care of fading)
		TApp.ExitAppDialogue = Null

		'in single player: resume game
		If Game And Not Game.networkgame Then Game.SetPaused(False)

		Return True
	End Function


	Function CreateConfirmExitAppDialogue:Int()
		'100ms since last dialogue
		If MilliSecs() - ExitAppDialogueTime < 100 Then Return False

		ExitAppDialogueTime = MilliSecs()
		'in single player: pause game
		If Game And Not Game.networkgame Then Game.SetPaused(True)

		ExitAppDialogue = New TGUIGameModalWindow.Create(New TVec2D, New TVec2D.Init(400,150), "SYSTEM")
		ExitAppDialogue.SetDialogueType(2)
		ExitAppDialogue.SetZIndex(100000)

rem
	disable until "new game" works properly
		'limit to "screen" area
		If game.gamestate = TGame.STATE_RUNNING
			ExitAppDialogue.darkenedArea = New TRectangle.Init(0,0,800,385)
			'center to this area
			ExitAppDialogue.screenArea = New TRectangle.Init(0,0,800,385)
		EndIf

		if game.gamestate = TGame.STATE_RUNNING
			ExitAppDialogue.SetCaptionAndValue( GetLocale("ALREADY_OVER"), GetLocale("DO_YOU_REALLY_WANT_TO_QUIT_THE_GAME_AND_RETURN_TO_STARTSCREEN") )
		else
			ExitAppDialogue.SetCaptionAndValue( GetLocale("ALREADY_OVER"), GetLocale("DO_YOU_REALLY_WANT_TO_QUIT") )
		endif
endrem
		ExitAppDialogue.SetCaptionAndValue( GetLocale("ALREADY_OVER"), GetLocale("DO_YOU_REALLY_WANT_TO_QUIT") )
	End Function

End Type


'just an object holding all data which has to get saved
'it is kind of an "DataCollectionCollection" ;D
Type TGameState
	Field _Game:TGame = Null
	Field _WorldTime:TWorldTime = Null
	Field _World:TWorld = Null
	Field _GameRules:TGamerules = Null
	Field _Betty:TBetty = Null
	Field _AdContractBaseCollection:TAdContractBaseCollection = Null
	Field _AdContractCollection:TAdContractCollection = Null
	Field _ProgrammeDataCollection:TProgrammeDataCollection = Null
	Field _ProgrammeLicenceCollection:TProgrammeLicenceCollection = Null
	Field _NewsEventCollection:TNewsEventCollection = Null
	Field _FigureCollection:TFigureCollection = Null
	Field _PlayerCollection:TPlayerCollection = Null
	Field _PlayerFinanceCollection:TPlayerFinanceCollection = Null
	Field _PlayerFinanceHistoryListCollection:TPlayerFinanceHistoryListCollection = Null
	Field _PlayerProgrammePlanCollection:TPlayerProgrammePlanCollection = Null
	Field _PlayerProgrammeCollectionCollection:TPlayerProgrammeCollectionCollection = Null
	Field _PublicImageCollection:TPublicImageCollection = Null
	Field _EventManagerEvents:TList = Null
	Field _PopularityManager:TPopularityManager = Null
	Field _BroadcastManager:TBroadcastManager = Null
	Field _StationMapCollection:TStationMapCollection = Null
	Field _Building:TBuilding 'includes, sky, moon, ufo, elevator
	Field _NewsAgency:TNewsAgency
	Field _RoomHandler_MovieAgency:RoomHandler_MovieAgency
	Field _RoomHandler_AdAgency:RoomHandler_AdAgency
	Field _RoomDoorBaseCollection:TRoomDoorBaseCollection
	Field _RoomBaseCollection:TRoomBaseCollection
	Const MODE_LOAD:Int = 0
	Const MODE_SAVE:Int = 1


	Method Initialize:Int()
		GetStationMapCollection().InitializeAll()
		GetPlayerProgrammeCollectionCollection().InitializeAll()
		GetPlayerProgrammePlanCollection().InitializeAll()
		GetAdContractCollection().Initialize()
		GetPopularityManager().Initialize()
		GetBuilding().Initialize()
		'building already initializes elevator
		'GetElevator().Initialize()

		GetAdContractBaseCollection().Initialize()
		GetProgrammeDataCollection().Initialize()
		GetProgrammeLicenceCollection().Initialize()
		GetNewsEventCollection().Initialize()

		rem
			GetWorldTime().Initialize()
			GetWorld().Initialize()
			GetBetty().Initialize()
			GetFigureCollection().Initialize()
			GetPlayerCollection().Initialize()
			GetPlayerFinanceCollection().Initialize()
			GetPlayerFinanceHistoryListCollection().Initialize()
			GetPublicImageCollection().Initialize()
			GetBroadcastManager().Initialize()
			GetBuilding().Initialize()
			GetNewsAgency().Initialize()
			_RoomHandler_MovieAgency.Initialize()
			_RoomHandler_AdAgency.Initialize()
			GetRoomDoorBaseCollection().Initialize()
			GetRoomBaseCollection().Initialize()
		endrem
	End Method


	Method RestoreGameData:Int()
		_Assign(_FigureCollection, TFigureCollection._instance, "FigureCollection", MODE_LOAD)
		_Assign(_RoomDoorBaseCollection, TRoomDoorBaseCollection._instance, "RoomDoorBaseCollection", MODE_LOAD)
		_Assign(_RoomBaseCollection, TRoomBaseCollection._instance, "RoomBaseCollection", MODE_LOAD)

		_Assign(_AdContractCollection, TAdContractCollection._instance, "AdContractCollection", MODE_LOAD)
		_Assign(_AdContractBaseCollection, TAdContractBaseCollection._instance, "AdContractBaseCollection", MODE_LOAD)

		_Assign(_ProgrammeDataCollection, TProgrammeDataCollection._instance, "ProgrammeDataCollection", MODE_LOAD)
		_Assign(_ProgrammeLicenceCollection, TProgrammeLicenceCollection._instance, "ProgrammeLicenceCollection", MODE_LOAD)

		_Assign(_PlayerCollection, TPlayerCollection._instance, "PlayerCollection", MODE_LOAD)
		_Assign(_PlayerFinanceCollection, TPlayerFinanceCollection._instance, "PlayerFinanceCollection", MODE_LOAD)
		_Assign(_PlayerFinanceHistoryListCollection, TPlayerFinanceHistoryListCollection._instance, "PlayerFinanceHistoryListCollection", MODE_LOAD)
		_Assign(_PlayerProgrammeCollectionCollection, TPlayerProgrammeCollectionCollection._instance, "PlayerProgrammeCollectionCollection", MODE_LOAD)
		_Assign(_PlayerProgrammePlanCollection, TPlayerProgrammePlanCollection._instance, "PlayerProgrammePlanCollection", MODE_LOAD)
		_Assign(_PublicImageCollection, TPublicImageCollection._instance, "PublicImageCollection", MODE_LOAD)

		_Assign(_NewsEventCollection, TNewsEventCollection._instance, "NewsEventCollection", MODE_LOAD)
		_Assign(_NewsAgency, TNewsAgency._instance, "NewsAgency", MODE_LOAD)
		_Assign(_Building, TBuilding._instance, "Building", MODE_LOAD)
		_Assign(_EventManagerEvents, EventManager._events, "Events", MODE_LOAD)
		_Assign(_PopularityManager, TPopularityManager._instance, "PopularityManager", MODE_LOAD)
		_Assign(_BroadcastManager, TBroadcastManager._instance, "BroadcastManager", MODE_LOAD)
		_Assign(_StationMapCollection, TStationMapCollection._instance, "StationMapCollection", MODE_LOAD)
		_Assign(_Betty, TBetty._instance, "Betty", MODE_LOAD)
		_Assign(_World, TWorld._instance, "World", MODE_LOAD)
		_Assign(_WorldTime, TWorldTime._instance, "WorldTime", MODE_LOAD)
		_Assign(_GameRules, GameRules, "GameRules", MODE_LOAD)
		_Assign(_RoomHandler_MovieAgency, RoomHandler_MovieAgency._instance, "MovieAgency", MODE_LOAD)
		_Assign(_RoomHandler_AdAgency, RoomHandler_AdAgency._instance, "AdAgency", MODE_LOAD)
		_Assign(_Game, Game, "Game")
	End Method


	Method BackupGameData:Int()
		_Assign(Game, _Game, "Game", MODE_SAVE)
		_Assign(TBuilding._instance, _Building, "Building", MODE_SAVE)
		_Assign(TRoomBaseCollection._instance, _RoomBaseCollection, "RoomBaseCollection", MODE_SAVE)
		_Assign(TRoomDoorBaseCollection._instance, _RoomDoorBaseCollection, "RoomDoorBaseCollection", MODE_SAVE)
		_Assign(TFigureCollection._instance, _FigureCollection, "FigureCollection", MODE_SAVE)
		_Assign(TPlayerCollection._instance, _PlayerCollection, "PlayerCollection", MODE_SAVE)
		_Assign(TPlayerFinanceCollection._instance, _PlayerFinanceCollection, "PlayerFinanceCollection", MODE_SAVE)
		_Assign(TPlayerFinanceHistoryListCollection._instance, _PlayerFinanceHistoryListCollection, "PlayerFinanceHistoryListCollection", MODE_SAVE)
		_Assign(TPlayerProgrammeCollectionCollection._instance, _PlayerProgrammeCollectionCollection, "PlayerProgrammeCollectionCollection", MODE_SAVE)
		_Assign(TPlayerProgrammePlanCollection._instance, _PlayerProgrammePlanCollection, "PlayerProgrammePlanCollection", MODE_SAVE)
		_Assign(TPublicImageCollection._instance, _PublicImageCollection, "PublicImageCollection", MODE_SAVE)

		'database data for contracts
		_Assign(TAdContractBaseCollection._instance, _AdContractBaseCollection, "AdContractBaseCollection", MODE_SAVE)
		_Assign(TAdContractCollection._instance, _AdContractCollection, "AdContractCollection", MODE_SAVE)

		'database data for programmes
		_Assign(TProgrammeDataCollection._instance, _ProgrammeDataCollection, "ProgrammeDataCollection", MODE_SAVE)
		_Assign(TProgrammeLicenceCollection._instance, _ProgrammeLicenceCollection, "ProgrammeLicenceCollection", MODE_SAVE)
		_Assign(TNewsEventCollection._instance, _NewsEventCollection, "NewsEventCollection", MODE_SAVE)
		_Assign(TNewsAgency._instance, _NewsAgency, "NewsAgency", MODE_SAVE)
		_Assign(EventManager._events, _EventManagerEvents, "Events", MODE_SAVE)
		_Assign(TPopularityManager._instance, _PopularityManager, "PopularityManager", MODE_SAVE)
		_Assign(TBroadcastManager._instance, _BroadcastManager, "BroadcastManager", MODE_SAVE)
		_Assign(TStationMapCollection._instance, _StationMapCollection, "StationMapCollection", MODE_SAVE)
		_Assign(TBetty._instance, _Betty, "Betty", MODE_SAVE)
		_Assign(TWorld._instance, _World, "World", MODE_SAVE)
		_Assign(TWorldTime._instance, _WorldTime, "WorldTime", MODE_SAVE)
		_Assign(GameRules, _GameRules, "GameRules", MODE_SAVE)
		'special room data
		_Assign(RoomHandler_MovieAgency._instance, _RoomHandler_MovieAgency, "MovieAgency", MODE_Save)
		_Assign(RoomHandler_AdAgency._instance, _RoomHandler_AdAgency, "AdAgency", MODE_Save)
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


Type TSaveGame extends TGameState
	'store the time gone since when the app started - timers rely on this
	'and without, times will differ after "loading" (so elevator stops
	'closing doors etc.)
	'this allows to have "realtime" (independend from "logic updates")
	'effects - for visual effects (fading), sound ...
	Field _Time_timeGone:Long = 0

	'override to do nothing
	Method Initialize:Int()
		'
	End Method


	'override to add time adjustment
	Method RestoreGameData:Int()
		Super.RestoreGameData()
		'restore "time gone since start"
		Time.SetTimeGone(_Time_timeGone)
	End Method


	'override to add time storage
	Method BackupGameData:Int()
		Super.BackupGameData()

		'store "time gone since start"
		_Time_timeGone = Time.GetTimeGone()
	End Method
	

	'override to output differing log texts
	Method _Assign(objSource:Object Var, objTarget:Object Var, name:String="DATA", mode:Int=0)
		If objSource
			objTarget = objSource
			If mode = MODE_LOAD
				TLogger.Log("TSaveGame.RestoreGameData()", "Loaded object "+name, LOG_DEBUG | LOG_SAVELOAD)
			Else
				TLogger.Log("TSaveGame.BackupGameData()", "Saved object "+name, LOG_DEBUG | LOG_SAVELOAD)
			EndIf
		Else
			TLogger.Log("TSaveGame", "object "+name+" was NULL - ignored", LOG_DEBUG | LOG_SAVELOAD)
		EndIf
	End Method


	Method CheckGameData:Int()
		'check if all data is available
		Return True
	End Method


	Function ShowMessage:Int(Load:Int=False)
		Local title:String = getLocale("PLEASE_BE_PATIENT")
		Local text:String = getLocale("SAVEGAME_GETS_LOADED")
		If Not Load Then text = getLocale("SAVEGAME_GETS_CREATED")

		Local col:TColor = New TColor.Get()
		Local pix:TPixmap = VirtualGrabPixmap(0, 0, GraphicsWidth(), GraphicsHeight() )
		Cls
		DrawPixmap(pix, 0,0)
		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(0,0, GraphicsWidth(), GraphicsHeight())
		SetAlpha 1.0
		SetColor 255,255,255

		GetSpriteFromRegistry("gfx_errorbox").Draw(GraphicsWidth()/2, GraphicsHeight()/2, -1, New TVec2D.Init(0.5, 0.5))
		Local w:Int = GetSpriteFromRegistry("gfx_errorbox").GetWidth()
		Local h:Int = GetSpriteFromRegistry("gfx_errorbox").GetHeight()
		Local x:Int = GraphicsWidth()/2 - w/2
		Local y:Int = GraphicsHeight()/2 - h/2
		GetBitmapFont("Default", 15, BOLDFONT).drawBlock(title, x + 18, y + 15, w - 60, 40, Null, TColor.Create(150, 50, 50))
		GetBitmapFont("Default", 12).drawBlock(text, x + 18, y + 50, w - 40, h - 60, Null, TColor.Create(50, 50, 50))

		Flip 0
		col.SetRGBA()
	End Function


	Function Load:Int(saveName:String="savegame.xml")
		ShowMessage(True)

		TPersist.maxDepth = 4096
		Local persist:TPersist = New TPersist
		Local saveGame:TSaveGame  = TSaveGame(persist.DeserializeFromFile(savename))
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
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginLoad", New TData.addString("saveName", saveName)))
		'load savegame data into game object
		saveGame.RestoreGameData()

		'tell everybody we finished loading (eg. for clearing GUI-lists)
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnLoad", New TData.addString("saveName", saveName).add("saveGame", saveGame)))

		'call game that game continues/starts now
		Game.StartLoadedSaveGame()
		Return True
	End Function


	Function Save:Int(saveName:String="savegame.xml")
		ShowMessage(False)

		Local saveGame:TSaveGame = New TSaveGame
		'tell everybody we start saving
		'payload is saveName
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginSave", New TData.addString("saveName", saveName)))

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
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnSave", New TData.addString("saveName", saveName).add("saveGame", saveGame)))

		Return True
	End Function
End Type






Type TFigurePostman Extends TFigure
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500, 0, 0, 5000)

	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigurePostman(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		Super.Create(FigureName, sprite, x, onFloor, speed, ControlledByID)
		Return Self
	End Method


	'override to make the figure stay in the room for a random time
	Method FinishEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase)
		Super.FinishEnterRoom(room, door)

		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	Method UpdateCustom:Int()
		'figure is in building and without target waiting for orders
		If IsIdling()
			Local door:TRoomDoorBase
			'search for a visible door
			Repeat
				door = GetRoomDoorBaseCollection().GetRandom()
			Until door.doorType > 0

			'TLogger.Log("TFigurePostman", "nothing to do -> send to door of " + door.room.name, LOG_DEBUG | LOG_AI, True)
			SendToDoor(door)
		EndIf

		If inRoom And nextActionTimer.isExpired()
			nextActionTimer.Reset()
			'switch "with" and "without" letter
			If sprite.name = "BotePost"
				sprite = GetSpriteFromRegistry("BoteLeer")
			Else
				sprite = GetSpriteFromRegistry("BotePost")
			EndIf

			'leave that room so we can find a new target
			leaveRoom()
		EndIf
	End Method
End Type


Type TFigureJanitor Extends TFigure
	Field currentAction:Int	= 0		'0=nothing,1=cleaning,...
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(2500,0, -500, 500) '500ms randomness
	Field nextActionTime:Int = 2500
	Field nextActionRandomTime:Int = 500
	Field useElevator:Int = True
	Field useDoors:Int = True
	Field BoredCleanChance:Int = 10
	Field NormalCleanChance:Int = 30
	Field MovementRangeMinX:Int	= 20
	Field MovementRangeMaxX:Int	= 420
	'how many seconds does the janitor wait at the elevator
	'until he goes to elsewhere
	Field WaitAtElevatorTimer:TIntervalTimer = TIntervalTimer.Create(20000)


	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigureJanitor(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		Super.Create(FigureName, sprite, x, onFloor, speed, ControlledByID)
		area.dimension.setX(14)

		GetFrameAnimations().Set("cleanRight", TSpriteFrameAnimation.Create([ [11,130], [12,130] ], -1, 0) )
		GetFrameAnimations().Set("cleanLeft", TSpriteFrameAnimation.Create([ [13,130], [14,130] ], -1, 0) )

		Return Self
	End Method


	'override to make the figure stay in the room for a random time
	Method FinishEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase)
		Super.FinishEnterRoom(room, door)

		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	'overwrite original method
	Method getAnimationToUse:String()
		Local result:String = Super.getAnimationToUse()

		If currentAction = 1
			If result = "walkRight" Then result = "cleanRight" Else result="cleanLeft"
		EndIf
		Return result
	End Method


	'overwrite default to stop moving when cleaning
	Method GetVelocity:TVec2D()
		If currentAction = 1 Then Return New TVec2D
		Return velocity
	End Method


	Method UpdateCustom:Int()
		'waited to long - change target (returns false while in elevator)
		If hasToChangeFloor() And WaitAtElevatorTimer.isExpired()
			If ChangeTarget(Rand(MovementRangeMinX, MovementRangeMaxX), GetBuilding().GetFloorY2(GetFloor()))
				WaitAtElevatorTimer.Reset()
			EndIf
		EndIf

		'waited long enough in room ... go out
		If inRoom And nextActionTimer.isExpired()
			LeaveRoom()
		EndIf

		'reached target - and time to do something
		If IsIdling() and nextActionTimer.isExpired()
			If Not hasToChangeFloor()

				'reset is done later - we want to catch isExpired there too
				'nextActionTimer.Reset()

				Local zufall:Int = Rand(0, 100)	'what to do?
				Local zufallx:Int = 0			'where to go?

				'move to a spot further away than just some pixels
				Repeat
					zufallx = Rand(MovementRangeMinX, MovementRangeMaxX)
				Until Abs(area.GetX() - zufallx) > 75

				'move to a different floor (only if doing nothing special)
				If useElevator And currentAction=0 And zufall > 80 And Not IsAtElevator()
					Local sendToFloor:Int = GetFloor() + 1
					If sendToFloor > 13 Then sendToFloor = 0
					ChangeTarget(zufallx, GetBuilding().GetFloorY2(sendToFloor))
					WaitAtElevatorTimer.Reset()
				'move to a different X on same floor - if not cleaning now
				Else If currentAction=0
					ChangeTarget(zufallx, GetBuilding().GetFloorY2(GetFloor()))
				EndIf
			EndIf

		EndIf

		If Not inRoom And nextActionTimer.isExpired() And Not hasToChangeFloor()
			nextActionTimer.SetRandomness(-nextActionRandomTime / TEntity.globalWorldSpeedFactor, nextActionRandomTime * TEntity.globalWorldSpeedFactor)
			nextActionTimer.SetInterval(nextActionTime / TEntity.globalWorldSpeedFactor)
			nextActionTimer.Reset()

			
			currentAction = 0

			'chose actions
			'- only if not outside the building
			if area.position.GetX() > GetBuilding().leftWallX
				'only clean with a chance of 30% when on the way to something
				'and do not clean if target is a room near figure
				Local targetDoor:TRoomDoor = TRoomDoor(GetTarget())
				If GetTarget() And (Not targetDoor Or (20 < Abs(targetDoor.GetScreenX() - area.GetX()) Or targetDoor.GetOnFloor() <> GetFloor()))
					If Rand(0,100) < NormalCleanChance Then currentAction = 1
				EndIf
				'if just standing around give a chance to clean
				If Not GetTarget() And Rand(0,100) < BoredCleanChance Then currentAction = 1
			endif
		EndIf

		If GetTarget()
			If Not useDoors And TRoomDoor(GetTarget()) Then RemoveCurrentTarget()
		EndIf
	End Method
End Type





'base figure type for figures coming from outside the building looking
'for a room at the roomboard etc.
Type TFigureDeliveryBoy Extends TFigure
	'did the figure check the roomboard where to go to?
	Field checkedRoomboard:int = False
	Field deliverToRoom:TRoomBase
	'was the "package" delivered already?
	Field deliveryDone:int = True
	'time to wait between doing something
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500, 0, 0, 5000)


	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigureDeliveryBoy(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		Super.Create(FigureName, sprite, x, onFloor, speed, ControlledByID)
		Return Self
	End Method


	'used in news effect function
	Function SendFigureToRoom(data:TData, params:TData)
		local figure:TFigureDeliveryBoy = TFigureDeliveryBoy(data.Get("figure"))
		local room:TRoomBase = TRoomBase(data.Get("room"))
		if not figure or not room then return

		figure.SetDeliverToRoom(room)
	End Function


	'override to make the figure stay in the room for a random time
	Method FinishEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase)
		Super.FinishEnterRoom(room, door)

		'terrorist now knows where to "deliver"
		if not checkedRoomboard then checkedRoomboard = True
		'if the room is the deliver target, delivery is finished
		if room = deliverToRoom then deliveryDone = True
			
		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	'set the room the figure should go to.
	'DeliveryBoys do not know where the room will be, so they
	'go to the roomboard first
	Method SetDeliverToRoom:int(room:TRoomBase)
		'to go to this room, we have to first visit the roomboard
		checkedRoomboard = False
		deliveryDone = False
		deliverToRoom = room
	End Method


	Method UpdateCustom:Int()
		'nothing to do - move to offscreen (leave building)
		If not deliverToRoom and not GetTarget()
			if not IsOffScreen() then SendToOffscreen()
		EndIf

		'figure is in building and without target waiting for orders
		If not deliveryDone and IsIdling()
			'before directly going to a room, ask the roomboard where
			'to go
			If Not checkedRoomboard
				TLogger.Log("TFigureDeliveryBoy", self.name+" is sent to roomboard", LOG_DEBUG | LOG_AI, True)
				SendToDoor(TRoomDoor.GetByDetails("roomboard", 0))
			Else
				'instead of sending the figure to the correct door, we
				'ask the roomsigns where to go to
				'1) get sign of the door
				local roomDoor:TRoomDoorBase = TRoomDoor.GetMainDoorToRoom(deliverToRoom)
				'2) get sign which is now at the slot/floor of the room
				local sign:TRoomBoardSign
				if roomDoor then sign = TRoomBoardSign.GetByCurrentPosition(roomDoor.doorSlot, roomDoor.onFloor)

				if sign and sign.door
					TLogger.Log("TFigureDeliveryBoy", self.name+" is sent to room "+TRoomDoor(sign.door).GetRoom().name+" (intended room: "+deliverToRoom.name+")", LOG_DEBUG | LOG_AI, True)
					SendToDoor(sign.door)
				else
					TLogger.Log("TFigureDeliveryBoy", self.name+" cannot send to a room, sign of target over empty room slot (intended room: "+deliverToRoom.name+")", LOG_DEBUG | LOG_AI, True)
					'send home again
					deliveryDone = True
					SendToOffscreen()
				endif
			EndIf
		EndIf

		If inRoom and nextActionTimer.isExpired()
			nextActionTimer.Reset()

			'delivery finished - send home again
			If deliveryDone
				FinishDelivery()

				deliverToRoom = Null
			EndIf

			'leave that room so we can find a new target
			leaveRoom()
		EndIf
	End Method


	Method FinishDelivery:Int()
		'nothing
	End Method
End Type


Type TFigureTerrorist Extends TFigureDeliveryBoy

	'override to place a bomb when delivered
	Method FinishDelivery:Int()
		'place bomb
		deliverToRoom.PlaceBomb()

		SendToOffscreen()
	End Method


	'override: terrorist do like nobody
	Method GetGreetingTypeForFigure:int(figure:TFigure)
		'0 = grrLeft
		'1 = hiLeft
		'2 = ?!left

		'depending on floor use "grr" or "?!"
		return 0 + 2*((1 + GetBuilding().GetFloor(area.GetY()) mod 2)-1)
	End Method	
End Type




'person who confiscates licences/programmes
Type TFigureMarshal Extends TFigureDeliveryBoy
	'arrays containing information of GUID->owner (so it stores the
	'owner of the licence in the moment of the task creation)
	Field confiscateProgammeLicenceGUID:String[]
	Field confiscateProgammeLicenceFromOwner:int[]

	'used in news effect function
	Function CreateConfiscationJob(data:TData, params:TData)
		local figure:TFigureMarshal = TFigureMarshal(data.Get("figure"))
		local licenceGUID:string = data.GetString("confiscateProgrammeLicenceGUID")
		if not figure or not licenceGUID then return

		figure.AddConfiscationJob(licenceGUID)
	End Function


	Method AddConfiscationJob:Int(confiscateGUID:string, owner:int=-1)
		local licence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(confiscateGUID)
		'no valid licence found
		if not licence then return False

		if owner = -1 then owner = licence.owner
		'only confiscate from players ?
		if not GetPlayerCollection().isPlayer(owner) then return False

		confiscateProgammeLicenceGUID :+ [licence.GetGUID()]
		confiscateProgammeLicenceFromOwner :+ [owner]

		return True
	End Method


	Method StartNextConfiscationJob:int()
		if not HasNextConfiscationJob() then return False

		'remove invalid jobs (eg after loading a savegame)
		if GetConfiscateProgrammeLicenceGUID() = ""
			RemoveCurrentConfiscationJob()
			return False
		endif
		
		'when confiscating programmes: start with your authorization
		'letter
		sprite = GetSpriteFromRegistry(GetBaseSpriteName()+".letter")

		'send figure to the archive of the stored owner
		SetDeliverToRoom(GetRoomCollection().GetFirstByDetails("archive", GetConfiscateProgrammeLicenceFromOwner()))
	End Method


	Method HasNextConfiscationJob:int()
		return confiscateProgammeLicenceFromOwner.length > 0
	End Method


	Method RemoveCurrentConfiscationJob()
		confiscateProgammeLicenceGUID = confiscateProgammeLicenceGUID[1..]
		confiscateProgammeLicenceFromOwner = confiscateProgammeLicenceFromOwner[1..]
	End Method
	

	Method GetConfiscateProgrammeLicenceGUID:string()
		if confiscateProgammeLicenceGUID.length = 0 then return ""
		return confiscateProgammeLicenceGUID[0]
	End Method


	Method GetConfiscateProgrammeLicenceFromOwner:int()
		if confiscateProgammeLicenceFromOwner.length = 0 then return -1
		return confiscateProgammeLicenceFromOwner[0]
	End Method
	

	Method GetBaseSpriteName:string()
		local dotPosition:int = sprite.GetName().Find(".")
		if dotPosition > 0
			return Left(sprite.GetName(), dotPosition)
		else
			return sprite.GetName()
		endif
	End Method
	

	'override to try to fetch the programme they should confiscate
	Method FinishDelivery:Int()
		'try to get the licence from the owner of the room we are now in
		local roomOwner:int = -1
		if inRoom then roomOwner = inRoom.owner

		if not GetPlayerCollection().isPlayer(roomOwner)
			'block room for x hours - like terror attack ?
		else
			'try to get the licence from the player - if that player does
			'not own the licence (eg. someone switched roomSigns), take
			'a random one ... :p
			local licence:TProgrammeLicence = GetPlayer(roomOwner).GetProgrammeCollection().GetProgrammeLicenceByGUID( GetConfiscateProgrammeLicenceGUID() )
			if not licence then licence = GetPlayer(roomOwner).GetProgrammeCollection().GetRandomProgrammeLicence()

			'hmm player does not have programme licences at all...skip
			'removal in that case
			if not licence then return False
				
			GetPlayer(roomOwner).GetProgrammeCollection().RemoveProgrammeLicence(licence)

			'inform others - including taken and originally intended
			'licence (so we see if the right one was took ... to inform
			'players correctly)
			EventManager.triggerEvent( TEventSimple.Create("publicAuthorities.onConfiscateProgrammeLicence", new TData.AddString("targetProgrammeGUID", GetConfiscateProgrammeLicenceGUID() ).AddString("confiscatedProgrammeGUID", licence.GetGUID()), null, GetPlayer(roomOwner)) )

			'switch used sprite - we confiscated something
			sprite = GetSpriteFromRegistry(GetBaseSpriteName()+".box")
		endif

		'remove the current job, we are done with it
		RemoveCurrentConfiscationJob()

		'send to offscreen again when finished
		SendToOffscreen()
	End Method


	Method UpdateCustom:Int()
		'try to start another job when doing nothing
		If isOffscreen() and IsIdling() then StartNextConfiscationJob()

		Super.UpdateCustom()
	End Method
End Type



'MENU: MAIN MENU SCREEN
Type TScreen_MainMenu Extends TGameScreen
	Field guiButtonStart:TGUIButton
	Field guiButtonNetwork:TGUIButton
	Field guiButtonOnline:TGUIButton
	Field guiButtonSettings:TGUIButton
	Field guiButtonQuit:TGUIButton
	Field guiLanguageDropDown:TGUISpriteDropDown
	Field settingsWindow:TSettingsWindow

	Method Create:TScreen_MainMenu(name:String)
		Super.Create(name)

		Self.SetScreenChangeEffects(Null,Null) 'menus do not get changers

		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		Local panelGap:Int = GUIManager.config.GetInt("panelGap", 10)
		guiButtonsWindow = New TGUIGameWindow.Create(New TVec2D.Init(300, 330), New TVec2D.Init(200, 400), name)
		guiButtonsWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")

		guiButtonsPanel	= guiButtonsWindow.AddContentBox(0,0,-1,-1)

		TGUIButton.SetTypeFont( GetBitmapFontManager().baseFontBold )
		TGUIButton.SetTypeCaptionColor( TColor.CreateGrey(75) )

		guiButtonStart		= New TGUIButton.Create(New TVec2D.Init(0,   0), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonNetwork	= New TGUIButton.Create(New TVec2D.Init(0,  40), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonOnline		= New TGUIButton.Create(New TVec2D.Init(0,  80), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonSettings	= New TGUIButton.Create(New TVec2D.Init(0, 120), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonQuit		= New TGUIButton.Create(New TVec2D.Init(0, 170), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonNetwork)
		guiButtonsPanel.AddChild(guiButtonOnline)
		guiButtonsPanel.AddChild(guiButtonSettings)
		guiButtonsPanel.AddChild(guiButtonQuit)


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

		'handle saving/applying of settings
		EventManager.RegisterListenerMethod("guiModalWindow.onClose", Self, "onCloseModalDialogue")

		Return Self
	End Method


	Method onCloseModalDialogue:Int(triggerEvent:TEventBase)
		If Not settingsWindow Then Return False
		
		Local dialogue:TGUIModalWindow = TGUIModalWindow(triggerEvent.GetSender())
		If dialogue <> settingsWindow.modalDialogue Then Return False

		'"apply" button was used...save the whole thing
		If triggerEvent.GetData().GetInt("closeButton", -1) = 0
			ApplySettingsWindow()
		EndIf
		'unset variable - allows escape/quit-window again
		settingsWindow = Null
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
					CreateSettingsWindow()
					
			Case guiButtonStart
					Game.SetGamestate(TGame.STATE_SETTINGSMENU)

			Case guiButtonNetwork
					Game.onlinegame = False
					Game.SetGamestate(TGame.STATE_NETWORKLOBBY)
					Game.networkgame = True

			Case guiButtonOnline
					Game.onlinegame = True
					Game.SetGamestate(TGame.STATE_NETWORKLOBBY)
					Game.networkgame = True

			Case guiButtonQuit
					App.ExitApp = True
		End Select
	End Method


	Method CreateSettingsWindow()
		'load config
		App.LoadSettings()
		settingsWindow = New TSettingsWindow.Init()
	End Method


	Method ApplySettingsWindow:Int()
		Local newConfig:TData = App.config.copy()
		'append values stored in gui elements
		newConfig.Append(settingsWindow.ReadGuiValues())

		App.SaveSettings(newConfig)
		'save the new config as current config
		App.config = newConfig
		'and "reinit" settings
		App.ApplySettings()
	End Method
	

	'override default
	Method SetLanguage:Int(languageCode:String = "")
		guiButtonStart.SetCaption(GetLocale("MENU_SOLO_GAME"))
		guiButtonNetwork.SetCaption(GetLocale("MENU_NETWORKGAME"))
		guiButtonOnline.SetCaption(GetLocale("MENU_ONLINEGAME"))
		guiButtonSettings.SetCaption(GetLocale("MENU_SETTINGS"))
		guiButtonQuit.SetCaption(GetLocale("MENU_QUIT"))
	End Method
	

	'override default draw
	Method Draw:Int(tweenValue:Float)
		DrawMenuBackground(False)

		'draw the janitor BEHIND the panels
		If MainMenuJanitor Then MainMenuJanitor.Draw(tweenValue)

		GUIManager.Draw(Self.name)
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
			guiButtonNetwork.Enable()
			guiButtonOnline.Enable()
		EndIf



		GUIManager.Update(Self.name)

		If MainMenuJanitor Then  MainMenuJanitor.Update()
	End Method
End Type



'MENU: GAME SETTINGS SCREEN
Type TScreen_GameSettings Extends TGameScreen
	Field guiSettingsWindow:TGUIGameWindow
	Field guiAnnounce:TGUICheckBox
	Field gui24HoursDay:TGUICheckBox
	Field guiSpecialFormats:TGUICheckBox
	Field guiFilterUnreleased:TGUICheckBox
	Field guiGameTitleLabel:TGuiLabel
	Field guiGameTitle:TGuiInput
	Field guiStartYearLabel:TGuiLabel
	Field guiStartYear:TGuiInput
	Field guiButtonStart:TGUIButton
	Field guiButtonBack:TGUIButton
	Field guiChatWindow:TGUIChatWindow
	Field guiPlayerNames:TGUIinput[4]
	Field guiChannelNames:TGUIinput[4]
	Field guiFigureArrows:TGUIArrowButton[8]
	Field modifiedPlayers:Int = False
	Global headerSize:Int = 35
	Global guiSettingsPanel:TGUIBackgroundBox
	Global guiPlayersPanel:TGUIBackgroundBox
	Global settingsArea:TRectangle = New TRectangle.Init(10,10,780,0) 'position of the panel
	Global playerBoxDimension:TVec2D = New TVec2D.Init(165,150) 'size of each player area
	Global playerColors:Int = 10
	Global playerColorHeight:Int = 10
	Global playerSlotGap:Int = 25
	Global playerSlotInnerGap:Int = 10 'the gap between inner canvas and inputs


	Method Create:TScreen_GameSettings(name:String)
		Super.Create(name)

		'===== CREATE AND SETUP GUI =====
		guiSettingsWindow = New TGUIGameWindow.Create(settingsArea.position, settingsArea.dimension, name)
		guiSettingsWindow.guiBackground.spriteAlpha = 0.5
		Local panelGap:Int = GUIManager.config.GetInt("panelGap", 10)
		guiSettingsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)

		guiPlayersPanel = guiSettingsWindow.AddContentBox(0,0,-1, playerBoxDimension.GetY() + 2 * panelGap)
		guiSettingsPanel = guiSettingsWindow.AddContentBox(0,0,-1, 100)

		guiGameTitleLabel	= New TGUILabel.Create(New TVec2D.Init(0, 0), "", TColor.CreateGrey(90), name)
		guiGameTitle		= New TGUIinput.Create(New TVec2D.Init(0, 12), New TVec2D.Init(300, -1), "", 32, name)
		guiStartYearLabel	= New TGUILabel.Create(New TVec2D.Init(310, 0), "", TColor.CreateGrey(90), name)
		guiStartYear		= New TGUIinput.Create(New TVec2D.Init(310, 12), New TVec2D.Init(65, -1), "", 4, name)

		guiGameTitleLabel.SetFont( GetBitmapFontManager().Get("DefaultThin", 14, BOLDFONT) )
		guiStartYearLabel.SetFont( GetBitmapFontManager().Get("DefaultThin", 14, BOLDFONT) )


		Local checkboxHeight:Int = 0
		gui24HoursDay = New TGUICheckBox.Create(New TVec2D.Init(430, 0), New TVec2D.Init(300), "", name)
		gui24HoursDay.SetChecked(True, False)
		gui24HoursDay.disable() 'option not implemented
		checkboxHeight :+ gui24HoursDay.GetScreenHeight()

		guiSpecialFormats = New TGUICheckBox.Create(New TVec2D.Init(430, 0 + checkboxHeight), New TVec2D.Init(300), "", name)
		guiSpecialFormats.SetChecked(True, False)
		guiSpecialFormats.disable() 'option not implemented
		checkboxHeight :+ guiSpecialFormats.GetScreenHeight()

		guiFilterUnreleased = New TGUICheckBox.Create(New TVec2D.Init(430, 0 + checkboxHeight), New TVec2D.Init(300), "", name)
		guiFilterUnreleased.SetChecked(True, False)
		checkboxHeight :+ guiFilterUnreleased.GetScreenHeight()

		guiAnnounce = New TGUICheckBox.Create(New TVec2D.Init(430, 0 + checkboxHeight), New TVec2D.Init(300), "", name)
		guiAnnounce.SetChecked(True, False)


		guiSettingsPanel.AddChild(guiGameTitleLabel)
		guiSettingsPanel.AddChild(guiGameTitle)
		guiSettingsPanel.AddChild(guiStartYearLabel)
		guiSettingsPanel.AddChild(guiStartYear)
		guiSettingsPanel.AddChild(guiAnnounce)
		guiSettingsPanel.AddChild(gui24HoursDay)
		guiSettingsPanel.AddChild(guiSpecialFormats)
		guiSettingsPanel.AddChild(guiFilterUnreleased)


		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		guiButtonsWindow = New TGUIGameWindow.Create(New TVec2D.Init(590, 400), New TVec2D.Init(200, 190), name)
		guiButtonsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")


		guiButtonsPanel = guiButtonsWindow.AddContentBox(0,0,-1,-1)

		TGUIButton.SetTypeFont( GetBitmapFontManager().baseFontBold )
		TGUIButton.SetTypeCaptionColor( TColor.CreateGrey(75) )

		guiButtonStart = New TGUIButton.Create(New TVec2D.Init(0, 0), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonBack = New TGUIButton.Create(New TVec2D.Init(0, guiButtonsPanel.GetcontentScreenHeight() - guiButtonStart.GetScreenHeight()), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonBack)


		guiChatWindow = New TGUIChatWindow.Create(New TVec2D.Init(10,400), New TVec2D.Init(540,190), name)
		guiChatWindow.guiChat.guiInput.setMaxLength(200)

		guiChatWindow.guiBackground.spriteAlpha = 0.5
		guiChatWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiChatWindow.guiChat.guiList.Resize(guiChatWindow.guiChat.guiList.rect.GetW(), guiChatWindow.guiChat.guiList.rect.GetH()-10)
		guiChatWindow.guiChat.guiInput.rect.position.addXY(panelGap, -panelGap)
		guiChatWindow.guiChat.guiInput.Resize( guiChatWindow.guiChat.GetContentScreenWidth() - 2* panelGap, guiStartYear.GetScreenHeight())

		Local player:TPlayer
		For Local i:Int = 0 To 3
			player = GetPlayerCollection().Get(i+1)
			Local slotX:Int = i * (playerSlotGap + playerBoxDimension.GetIntX())
			Local playerPanel:TGUIBackgroundBox = New TGUIBackgroundBox.Create(New TVec2D.Init(slotX, 0), New TVec2D.Init(playerBoxDimension.GetIntX(), playerBoxDimension.GetIntY()), name)
			playerPanel.spriteBaseName = "gfx_gui_panel.subContent.bright"
			playerPanel.SetPadding(playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap)
			guiPlayersPanel.AddChild(playerPanel)

			guiPlayerNames[i] = New TGUIinput.Create(New TVec2D.Init(0, 0), New TVec2D.Init(playerPanel.GetContentScreenWidth(), -1), player.Name, 16, name)
			guiPlayerNames[i].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_player"))

			guiChannelNames[i] = New TGUIinput.Create(New TVec2D.Init(0, 0), New TVec2D.Init(playerPanel.GetContentScreenWidth(), -1), player.channelname, 16, name)
			guiChannelNames[i].rect.position.SetY(playerPanel.GetContentScreenHeight() - guiChannelNames[i].rect.GetH())
			guiChannelNames[i].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_tvchannel"))

			'left arrow
			guiFigureArrows[i*2 + 0] = New TGUIArrowButton.Create(New TVec2D.Init(0 + 10, 50), New TVec2D.Init(24, 24), "LEFT", name)
			'right arrow
			guiFigureArrows[i*2 + 1] = New TGUIArrowButton.Create(New TVec2D.Init(playerPanel.GetContentScreenWidth() - 10, 50), New TVec2D.Init(24, 24), "RIGHT", name)
			guiFigureArrows[i*2 + 1].rect.position.AddXY(-guiFigureArrows[i*2 + 1].GetScreenWidth(),0)

			playerPanel.AddChild(guiPlayerNames[i])
			playerPanel.AddChild(guiChannelNames[i])
			playerPanel.AddChild(guiFigureArrows[i*2 + 0])
			playerPanel.AddChild(guiFigureArrows[i*2 + 1])
		Next


		'set button texts
		'could be done in "startup"-methods when changing screens
		'to the DIG ones
		SetLanguage()


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


	'override to set guielements values (instead of only on screen creation)
	Method Start:Int()
		guiGameTitle.SetValue(Game.title)
		guiStartYear.SetValue(Game.userStartYear)
		guiPlayerNames[0].SetValue(game.username)
		guiChannelNames[0].SetValue(game.userchannelname)

		GetPlayerCollection().Get(1).Name = game.username
		GetPlayerCollection().Get(1).Channelname = game.userchannelname

		guiGameTitle.SetValue(game.title)
	End Method



	'handle clicks on the buttons
	Method onClickArrows:Int(triggerEvent:TEventBase)
		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent._sender)
		If Not sender Then Return False

		'left/right arrows to change figure base
		For Local i:Int = 0 To 7
			If sender = guiFigureArrows[i]
				If i Mod 2  = 0 Then GetPlayerCollection().Get(1+Ceil(i/2)).UpdateFigureBase(GetPlayerCollection().Get(Ceil(1+i/2)).figurebase -1)
				If i Mod 2 <> 0 Then GetPlayerCollection().Get(1+Ceil(i/2)).UpdateFigureBase(GetPlayerCollection().Get(Ceil(1+i/2)).figurebase +1)
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
						TLogger.Log("Game", "Start a new singleplayer game", LOG_DEBUG)
					Else
						TLogger.Log("Game", "Start a new multiplayer game", LOG_DEBUG)
						guiAnnounce.SetChecked(False)
						Network.StopAnnouncing()
					EndIf
					Game.SetGamestate(TGame.STATE_PREPAREGAMESTART)

			Case guiButtonBack
					If Game.networkgame
						If Game.networkgame Then Network.DisconnectFromServer()
						GetPlayerCollection().playerID = 1
						GetPlayerBossCollection().playerID = 1
						Game.SetGamestate(TGame.STATE_NETWORKLOBBY)
						guiAnnounce.SetChecked(False)
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

		'only inform when in settings menu
		If Game.gamestate = TGame.STATE_SETTINGSMENU
			If sender.isChecked()
				TGame.SendSystemMessage(GetLocale("OPTION_ON")+": "+sender.GetValue())
			Else
				TGame.SendSystemMessage(GetLocale("OPTION_OFF")+": "+sender.GetValue())
			EndIf
		EndIf
	End Method


	Method onChangeGameSettingsInputs(triggerEvent:TEventBase)
		Local sender:TGUIObject = TGUIObject(triggerEvent.GetSender())
		Local value:String = triggerEvent.GetData().getString("value")

		'name or channel changed?
		For Local i:Int = 0 To 3
			If sender = guiPlayerNames[i] Then GetPlayerCollection().Get(i+1).Name = value
			If sender = guiChannelNames[i] Then GetPlayerCollection().Get(i+1).channelName = value
		Next

		'start year changed
		If sender = guiStartYear
			GetWorldTime().setStartYear( Max(1980, Int(value)) )
			TGUIInput(sender).value = Max(1980, Int(value))
		EndIf
	End Method


	'override default
	Method SetLanguage:Int(languageCode:String = "")
		'not needed, done during update
		'guiSettingsWindow.SetCaption(GetLocale("MENU_NETWORKGAME"))

		guiGameTitleLabel.SetValue(GetLocale("GAME_TITLE")+":")
		guiStartYearLabel.SetValue(GetLocale("START_YEAR")+":")

		gui24HoursDay.SetValue(GetLocale("24_HOURS_GAMEDAY"))
		guiSpecialFormats.SetValue(GetLocale("ALLOW_TRAILERS_AND_INFOMERCIALS"))
		guiFilterUnreleased.SetValue(GetLocale("ALLOW_MOVIES_WITH_YEAR_OF_PRODUCTION_GT_GAMEYEAR"))

		guiAnnounce.SetValue("Nach weiteren Spielern suchen")
		
		guiButtonStart.SetCaption(GetLocale("MENU_START_GAME"))
		guiButtonBack.SetCaption(GetLocale("MENU_BACK"))

		guiChatWindow.SetCaption(GetLocale("CHAT"))


		're-align the checkboxes as localization might have changed
		'label dimensions
		Local y:Int = 0
		gui24HoursDay.rect.position.SetY(0)
		y :+ gui24HoursDay.GetScreenHeight()

		guiSpecialFormats.rect.position.SetY(y)
		y :+ guiSpecialFormats.GetScreenHeight()

		guiFilterUnreleased.rect.position.SetY(y)
	End Method
	

	Method Draw:Int(tweenValue:Float)
		DrawMenuBackground(True)

		'background gui items
		GUIManager.Draw(name, 0, 100)

		Local slotPos:TVec2D = New TVec2D.Init(guiPlayersPanel.GetContentScreenX(),guiPlayersPanel.GetContentScreeny())
		For Local i:Int = 0 To 3
			If Game.networkgame Or GetPlayerCollection().playerID=1
				If Game.gamestate <> TGame.STATE_PREPAREGAMESTART And GetPlayerCollection().Get(i+1).Figure.ControlledByID = GetPlayerCollection().playerID Or (GetPlayerCollection().Get(i+1).Figure.ControlledByID = 0 And GetPlayerCollection().playerID = 1)
					SetColor 255,255,255
				Else
					SetColor 225,255,150
				EndIf
			EndIf

			'draw colors
			Local colorRect:TRectangle = New TRectangle.Init(slotPos.GetIntX()+2, Int(guiChannelNames[i].GetContentScreenY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)
			For Local obj:TColor = EachIn TColor.List
				If obj.ownerID = 0
					colorRect.position.AddXY(colorRect.GetW(), 0)
					obj.SetRGB()
					DrawRect(colorRect.GetX(), colorRect.GetY(), colorRect.GetW(), colorRect.GetH())
				EndIf
			Next

			'draw player figure
			SetColor 255,255,255
			GetPlayerCollection().Get(i+1).Figure.Sprite.Draw(Int(slotPos.GetX() + playerBoxDimension.GetX()/2 - GetPlayerCollection().Get(1).Figure.Sprite.framew / 2), Int(colorRect.GetY() - GetPlayerCollection().Get(1).Figure.Sprite.area.GetH()), 8)

			'move to next slot position
			slotPos.AddXY(playerSlotGap + playerBoxDimension.GetX(), 0)
		Next

		'overlay gui items (higher zindex)
		GUIManager.Draw(name, 101)
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

			guiAnnounce.show()
			guiGameTitle.show()
			guiGameTitleLabel.show()

			If guiAnnounce.isChecked() And Game.isGameLeader()
			'If Game.isGameLeader()
				'guiAnnounce.enable()
				guiGameTitle.disable()
				If guiGameTitle.Value = "" Then guiGameTitle.Value = "no title"
				Game.title = guiGameTitle.Value
			Else
				guiGameTitle.enable()
			EndIf
			If Not Game.isGameLeader()
				guiGameTitle.disable()
				guiAnnounce.disable()
			EndIf

			'disable/enable announcement on lan/online
			If guiAnnounce.isChecked()
				Network.client.playerName = GetPlayerCollection().Get().name
				If Not Network.announceEnabled Then Network.StartAnnouncing(Game.title)
			Else
				Network.StopAnnouncing()
			EndIf
		Else
			guiSettingsWindow.SetCaption(GetLocale("MENU_SOLO_GAME"))
			'guiChat.setOption(GUI_OBJECT_VISIBLE,False)


			guiAnnounce.hide()
			guiGameTitle.disable()
		EndIf

		For Local i:Int = 0 To 3
			If Game.networkgame Or Game.isGameLeader()
				If Game.gamestate <> TGame.STATE_PREPAREGAMESTART And GetPlayerCollection().Get(i+1).Figure.ControlledByID = GetPlayerCollection().playerID Or (GetPlayerCollection().Get(i+1).Figure.ControlledByID = 0 And GetPlayerCollection().playerID=1)
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
				GUIManager.SetFocus(guiChatWindow.guiChat.guiInput)
				'KEYMANAGER.blockKey(KEY_ENTER, 200) 'block for 100ms
				'KEYMANAGER.resetKey(KEY_ENTER)
			EndIf
		EndIf

		'clicks on color rect
		Local i:Int = 0

	'	rewrite to Assets instead of global list in TColor ?
	'	local colors:TList = Assets.GetList("PlayerColors")

		If MOUSEMANAGER.IsHit(1)
			Local slotPos:TVec2D = New TVec2D.Init(guiPlayersPanel.GetContentScreenX(),guiPlayersPanel.GetContentScreeny())
			For Local i:Int = 0 To 3
				Local colorRect:TRectangle = New TRectangle.Init(slotPos.GetIntX() + 2, Int(guiChannelNames[i].GetContentScreenY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)

				For Local obj:TColor = EachIn TColor.List
					'only for unused colors
					If obj.ownerID <> 0 Then Continue

					colorRect.position.AddXY(colorRect.GetW(), 0)

					'skip if outside of rect
					If Not THelper.MouseInRect(colorRect) Then Continue
					If (GetPlayerCollection().Get(i+1).Figure.ControlledByID = GetPlayerCollection().playerID Or (GetPlayerCollection().Get(i+1).Figure.ControlledByID = 0 And GetPlayerCollection().playerID = 1))
						modifiedPlayers=True
						GetPlayerCollection().Get(i+1).RecolorFigure(obj)
					EndIf
				Next
				'move to next slot position
				slotPos.AddXY(playerSlotGap + playerBoxDimension.GetX(), 0)
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
		guiGameList	= New TGUIGameList.Create(New TVec2D.Init(0,0), New TVec2D.Init(guiGameListPanel.GetContentScreenWidth(),guiGameListPanel.GetContentScreenHeight()), name)
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

		If Network.ConnectToServer( HostIp(_hostIP), _hostPort )
			Network.isServer = False
			Game.SetGameState(TGame.STATE_SETTINGSMENU)
			ScreenGameSettings.guiGameTitle.Value = gameTitle
		EndIf
	End Method


	Method Draw:Int(tweenValue:Float)
		DrawMenuBackground(True)

		If Not Game.onlinegame
			guiGameListWindow.SetCaption(GetLocale("MENU_NETWORKGAME")+" : "+GetLocale("MENU_AVAILABLE_GAMES"))
		Else
			guiGamelistWindow.SetCaption(GetLocale("MENU_ONLINEGAME")+" : "+GetLocale("MENU_AVAILABLE_GAMES"))
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
						Print "set your onlineIP: "+responseArray[0]
					EndIf
				Wend
				CloseStream Onlinestream
			Else
				If Network.LastOnlineRequestTimer + Network.LastOnlineRequestTime < MilliSecs()
	'TODO: [ron] rewrite handling
					Network.LastOnlineRequestTimer = MilliSecs()
					Local Onlinestream:TStream   = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=ListGames")
					Local timeOutTimer:Int = MilliSecs()+2500 '2.5 seconds okay?
					Local timeOut:int = False
					
					If Not Onlinestream Then Throw ("Not Online?")

					While Not Eof(Onlinestream) Or timeout
						If timeouttimer < MilliSecs() Then timeout = True
						
						Local responsestring:String = ReadLine(Onlinestream)
						Local responseArray:String[] = responsestring.split("|")
						If responseArray and responseArray.length > 3
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
'	Field prepareGameCalled:Int = False
	'was "SpreadConfiguration()" called already?
	Field spreadConfigurationCalled:Int = False
	'was "SpreadStartData()" called already?
	Field spreadStartDataCalled:Int = False
	'can "startGame()" get called?
	Field canStartGame:Int = False


	Method Create:TScreen_PrepareGameStart(name:String)
		Super.Create(name)

		messageWindow = New TGUIGameModalWindow.Create(New TVec2D, New TVec2D.Init(400,250), name)
		'messageWindow.DarkenedArea = new TRectangle.Init(0,0,800,385)
		messageWindow.SetCaptionAndValue("title", "")
		messageWindow.SetDialogueType(0) 'no buttons
		
		Return Self
	End Method


	Method Draw:Int(tweenValue:Float)
		'draw settings screen as background
		'BESSER: VORHERIGEN BILDSCHIRM zeichnen (fuer Laden)
		ScreenCollection.GetScreen("GameSettings").Draw(tweenValue)

		'draw messageWindow
		GUIManager.Draw(name)

		'rect of the message window's content area 
		Local messageRect:TRectangle = messageWindow.GetContentScreenRect()
		Local oldAlpha:Float = GetAlpha()
		SetAlpha messageWindow.GetScreenAlpha()
		Local messageDY:Int = 0
		If Game.networkgame
			GetBitmapFontManager().baseFont.draw(GetLocale("SYNCHRONIZING_START_CONDITIONS")+"...", messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
			messageDY :+ 20
			For Local i:Int = 1 To 4
				GetBitmapFontManager().baseFont.draw(GetLocale("PLAYER")+" "+i+"..."+GetPlayerCollection().Get(i).networkstate+" MovieListCount: "+GetPlayerCollection().Get(i).GetProgrammeCollection().GetProgrammeLicenceCount(), messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
				messageDY :+ 20
			Next
			If Not Game.networkgameready = 1
				GetBitmapFontManager().baseFont.draw("not ready!!", messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
			EndIf
		Else
			GetBitmapFontManager().baseFont.draw(GetLocale("PREPARING_START_DATA")+"...", messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
		EndIf
		SetAlpha oldAlpha
	End Method


	Method Reset:Int()
		startGameCalled = False
'		prepareGameCalled = False
		spreadConfigurationCalled = False
		spreadStartDataCalled = False
		canStartGame = False
	End Method


	'override to reset values
	Method Start:Int()
		Reset()
		
		If Game.networkGame
			messageWindow.SetCaption(GetLocale("STARTING_NETWORKGAME"))
		Else
			messageWindow.SetCaption(GetLocale("STARTING_SINGLEPLAYERGAME"))
		EndIf
	End Method


	Method Enter:Int(fromScreen:TScreen=Null)
		Super.Enter(fromScreen)

		If wait = 0 Then wait = Time.GetTimeGone()
		Reset()
	End Method


	Global wait:Int = 0

	'override default update
	Method Update:Int(deltaTime:Float)
		'update messagewindow
		GUIManager.Update(name)


		'=== STEPS ===
		'MP = MultiPlayer, SP = SinglePlayer, ALL = all modes
		'1. MP:  Spread configuration (database / name)
'no longer needed
		'2. ALL: Prepare game (load database, color figures)
'
		'3. MP:  Check if ready to start game
		'4. ALL: Start game (if ready)


		'=== STEP 1 ===
		If game.networkGame
			SpreadConfiguration()
			spreadConfigurationCalled = True
			StartMultiplayerSyncStarted = Time.GetTimeGone()
		EndIf


rem
	do not prepare as things might have to get prepared "FIRST" (first game start)
		'=== STEP 2 ===
		If Not prepareGameCalled
			Game.PrepareStart()
			StartMultiplayerSyncStarted = Time.GetTimeGone()
			prepareGameCalled = True
		EndIf
endrem

		'=== STEP 3 ===
		If game.networkGame
			'ask other players if they are ready (ask every 500ms)
			If Game.isGameLeader() And SendGameReadyTimer < Time.GetTimeGone()
				NetworkHelper.SendGameReady(GetPlayerCollection().playerID)
				SendGameReadyTimer = Time.GetTimeGone() + 500
			EndIf
			'go back to game settings if something takes longer than expected
			If Time.GetTimeGone() - StartMultiplayerSyncStarted > 10000
				Print "sync timeout"
				StartMultiplayerSyncStarted = 0
				game.SetGamestate(TGame.STATE_SETTINGSMENU)
				Return False
			EndIf
		EndIf

		If Not startGameCalled
			'singleplayer games can always start
			If Not Game.networkGame
'				if Time.GetTimeGone() - wait > 5000
					canStartGame = True
'				endif
			'multiplayer games can start if all players are ready
			Else
				If Game.networkgameready = 1
					ScreenGameSettings.guiAnnounce.SetChecked(False)
					GetPlayerCollection().Get().networkstate = 1
					canStartGame = True
				EndIf
			EndIf
		EndIf
		

		'=== STEP 4 ===
		If canStartGame And Not startGameCalled
			'register events and start game
			Game.StartNewGame()
			'reset randomizer
			Game.SetRandomizerBase( Game.GetRandomizerBase() )
			startGameCalled = True
		EndIf
	End Method


	'spread configuration to other players
	Method SpreadConfiguration:Int()
		If Not Game.networkGame Then Return False

		'send which database to use (or send database itself?)
	End Method
End Type



'the modal window containing various gui elements to configur some
'basics in the game
Type TSettingsWindow
	Field modalDialogue:TGUIGameModalWindow
	Field inputPlayerName:TGUIInput
	Field inputChannelName:TGUIInput
	Field inputStartYear:TGUIInput
	Field inputStationmap:TGUIDropDown
	Field inputDatabase:TGUIDropDown
	Field checkMusic:TGUICheckbox
	Field checkSfx:TGUICheckbox
	Field dropdownRenderer:TGUIDropDown
	Field checkFullscreen:TGUICheckbox
	Field inputGameName:TGUIInput
	Field inputOnlinePort:TGUIInput


	Method ReadGuiValues:TData()
		Local data:TData = New TData

		data.Add("playername", inputPlayerName.GetValue())
		data.Add("channelname", inputChannelName.GetValue())
		data.Add("startyear", inputStartYear.GetValue())
		'data.Add("stationmap", inputStationmap.GetValue())
		data.Add("databaseDir", inputDatabase.GetValue())
		data.AddBoolString("sound_music", checkMusic.IsChecked())
		data.AddBoolString("sound_effects", checkSfx.IsChecked())

		data.Add("renderer", dropdownRenderer.GetSelectedEntry().data.GetString("value", "0"))
		data.AddBoolString("fullscreen", checkFullscreen.IsChecked())
		data.Add("gamename", inputGameName.GetValue())
		data.Add("onlineport", inputOnlinePort.GetValue())

		Return data
	End Method


	Method SetGuiValues:Int(data:TData)
		inputPlayerName.SetValue(data.GetString("playername", "Player"))
		inputChannelName.SetValue(data.GetString("channelname", "My Channel"))
		inputStartYear.SetValue(data.GetInt("startyear", 1985))
		'inputStationmap.SetValue(data.GetString("stationmap", "res/maps/germany.xml"))
		inputDatabase.SetValue(data.GetString("databaseDir", "res/database/Default"))
		checkMusic.SetChecked(data.GetBool("sound_music", True))
		checkSfx.SetChecked(data.GetBool("sound_effects", True))
		checkFullscreen.SetChecked(data.GetBool("fullscreen", False))


		'check available renderer entries
		local selectedDropDownItem:TGUIDropDownItem
		For local item:TGUIDropDownItem = EachIn dropdownRenderer.GetEntries()
			local renderer:int = item.data.GetInt("value")
			'if the same renderer - select this
			if renderer = data.GetInt("renderer", 0)
				selectedDropDownItem = item
				exit
			endif
		Next
		'select the first if nothing was preselected
		if not selectedDropDownItem
			dropdownRenderer.SetSelectedEntryByPos(0)
		else
			dropdownRenderer.SetSelectedEntry(selectedDropDownItem)
		endif
		

		inputGameName.SetValue(data.GetString("gamename", "New Game"))
		inputOnlinePort.SetValue(data.GetInt("onlineport", 4544))
	End Method


	Method Init:TSettingsWindow()
		'LAYOUT CONFIG
		Local nextY:Int = 0, nextX:Int = 0
		Local rowWidth:Int = 215
		Local checkboxWidth:Int = 180
		Local inputWidth:Int = 170
		Local labelH:Int = 12
		Local inputH:Int = 0
		Local windowW:Int = 670
		Local windowH:Int = 380

		modalDialogue = New TGUIGameModalWindow.Create(New TVec2D, New TVec2D.Init(windowW, windowH), "SYSTEM")

		modalDialogue.SetDialogueType(2)
		modalDialogue.buttons[0].SetCaption(GetLocale("SAVE_AND_APPLY"))
		modalDialogue.buttons[0].Resize(180,-1)
		modalDialogue.buttons[1].SetCaption(GetLocale("CANCEL"))
		modalDialogue.buttons[1].Resize(160,-1)
		modalDialogue.SetCaptionAndValue(GetLocale("MENU_SETTINGS"), "")

		Local canvas:TGUIObject = modalDialogue.GetGuiContent()
				
		Local labelTitleGameDefaults:TGUILabel = New TGUILabel.Create(New TVec2D.Init(0, nextY), GetLocale("DEFAULTS_FOR_NEW_GAME"))
		labelTitleGameDefaults.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		canvas.AddChild(labelTitleGameDefaults)
		nextY :+ 25

		Local labelPlayerName:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("PLAYERNAME")+":")
		inputPlayerName = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "", 128)
		canvas.AddChild(labelPlayerName)
		canvas.AddChild(inputPlayerName)
		inputH = inputPlayerName.GetScreenHeight()
		nextY :+ inputH + labelH * 1.5

		Local labelChannelName:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("CHANNELNAME")+":")
		inputChannelName = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "", 128)
		canvas.AddChild(labelChannelName)
		canvas.AddChild(inputChannelName)
		nextY :+ inputH + labelH * 1.5

		Local labelStartYear:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("START_YEAR")+":")
		inputStartYear = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(50,-1), "", 4)
		canvas.AddChild(labelStartYear)
		canvas.AddChild(inputStartYear)
		nextY :+ inputH + labelH * 1.5

		Local labelStationmap:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("STATIONMAP")+":")
		inputStationmap = New TGUIDropDown.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "germany.xml", 128)
		inputStationmap.disable()
		canvas.AddChild(labelStationmap)
		canvas.AddChild(inputStationmap)
		nextY :+ inputH + labelH * 1.5

		Local labelDatabase:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("DATABASE")+":")
		inputDatabase = New TGUIDropDown.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "res/database/Default", 128)
		inputDatabase.disable()
		canvas.AddChild(labelDatabase)
		canvas.AddChild(inputDatabase)
		nextY :+ inputH + labelH * 1.5


		nextY = 0
		nextX = 1*rowWidth
		'SOUND
		Local labelTitleSound:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("SOUND_OUTPUT"))
		labelTitleSound.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		canvas.AddChild(labelTitleSound)
		nextY :+ 25

		checkMusic = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth,-1), "")
		checkMusic.SetCaption(GetLocale("MUSIC"))
		canvas.AddChild(checkMusic)
		nextY :+ Max(inputH, checkMusic.GetScreenHeight())

		checkSfx = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth,-1), "")
		checkSfx.SetCaption(GetLocale("SFX"))
		canvas.AddChild(checkSfx)
		nextY :+ Max(inputH, checkSfx.GetScreenHeight())
		nextY :+ 15


		'GRAPHICS
		Local labelTitleGraphics:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("GRAPHICS"))
		labelTitleGraphics.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		canvas.AddChild(labelTitleGraphics)
		nextY :+ 25

		Local labelRenderer:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("RENDERER") + ":")
		dropdownRenderer = New TGUIDropDown.Create(New TVec2D.Init(nextX, nextY + 12), New TVec2D.Init(inputWidth,-1), "", 128)
		Local rendererValues:String[] = ["0", "3"]
		Local rendererTexts:String[] = ["OpenGL", "Buffered OpenGL"]
		?Win32
			rendererValues :+ ["1","2"]
			rendererTexts :+ ["DirectX 7", "DirectX 9"]
		?
		Local itemHeight:Int = 0
		For Local i:Int = 0 Until rendererValues.Length
			Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(Null, Null, rendererTexts[i])
			item.SetValueColor(TColor.CreateGrey(50))
			item.data.Add("value", rendererValues[i])
			dropdownRenderer.AddItem(item)
			If itemHeight = 0 Then itemHeight = item.GetScreenHeight()
		Next
		dropdownRenderer.SetListContentHeight(itemHeight * Len(rendererValues))

		canvas.AddChild(labelRenderer)
		canvas.AddChild(dropdownRenderer)
'		GuiManager.SortLists()
		nextY :+ inputH + labelH * 1.5

		checkFullscreen = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth,-1), "")
		checkFullscreen.SetCaption(GetLocale("FULLSCREEN"))
		canvas.AddChild(checkFullscreen)
		nextY :+ Max(inputH, checkFullscreen.GetScreenHeight()) + labelH * 1.5


		'MULTIPLAYER
		nextY = 0
		nextX = 2*rowWidth
		Local labelTitleMultiplayer:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("MULTIPLAYER"))
		labelTitleMultiplayer.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		canvas.AddChild(labelTitleMultiplayer)
		nextY :+ 25

		Local labelGameName:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("GAME_TITLE")+":")
		inputGameName = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "", 128)
		canvas.AddChild(labelGameName)
		canvas.AddChild(inputGameName)
		nextY :+ inputH + labelH * 1.5

	
		Local labelOnlinePort:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("PORT_ONLINEGAME")+":")
		inputOnlinePort = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + 12), New TVec2D.Init(50,-1), "", 4)
		canvas.AddChild(labelOnlinePort)
		canvas.AddChild(inputOnlinePort)
		nextY :+ inputH + 5

		'fill values
		SetGuiValues(App.config)

		Return Self
	End Method
End Type




Type GameEvents
	Function RegisterEventListeners:int()
		'react on right clicks during a rooms update (leave room)
		EventManager.registerListenerFunction("room.onUpdate", RoomOnUpdate)

		'=== REGISTER PLAYER EVENTS ===
		'events get ignored by non-gameleaders
		EventManager.registerListenerFunction("Game.OnMinute", PlayersOnMinute)
		EventManager.registerListenerFunction("Game.OnDay", PlayersOnDay)
		EventManager.registerListenerFunction("Time.OnSecond", Time_OnSecond)

		EventManager.registerListenerFunction("PlayerFinance.onChangeMoney", PlayerFinanceOnChangeMoney)
		EventManager.registerListenerFunction("PlayerFinance.onTransactionFailed", PlayerFinanceOnTransactionFailed)
		EventManager.registerListenerFunction("PlayerBoss.onCallPlayer", PlayerBoss_OnCallPlayer)
		EventManager.registerListenerFunction("PlayerBoss.onCallPlayerForced", PlayerBoss_OnCallPlayerForced)
		EventManager.registerListenerFunction("PlayerBoss.onPlayerEnterBossRoom", PlayerBoss_OnPlayerEnterBossRoom)

		'=== PUBLIC AUTHORITIES ===
		'-> create ingame notifications
		EventManager.registerListenerFunction("publicAuthorities.onStopXRatedBroadcast", publicAuthorities_onStopXRatedBroadcast)
		EventManager.registerListenerFunction("publicAuthorities.onConfiscateProgrammeLicence", publicAuthorities_onConfiscateProgrammeLicence)

		'visually inform that selling the last station is impossible
		EventManager.registerListenerFunction("StationMap.onTrySellLastStation", StationMapOnTrySellLastStation)
		'trigger audience recomputation when a station is trashed/sold
		EventManager.registerListenerFunction("StationMap.removeStation", StationMapOnSellStation)

		EventManager.registerListenerFunction("BroadcastManager.BroadcastMalfunction", PlayerBroadcastMalfunction)

		'listen to failed or successful ending adcontracts to send out
		'ingame toastmessages
		EventManager.registerListenerFunction("AdContract.onFinish", AdContract_OnFinish)
		EventManager.registerListenerFunction("AdContract.onFail", AdContract_OnFail)
	End Function
	

	Function Time_OnSecond:Int(triggerEvent:TEventBase)
		'only AI handling: only gameleader interested
		If not Game.isGameLeader() then return False

		'milliseconds passed since last event
		Local timeGone:Int = triggerEvent.GetData().getInt("timeGone", 0)

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isAI() Then player.PlayerKI.ConditionalCallOnTick()
			If player.isAI() Then player.PlayerKI.CallOnRealtimeSecond(timeGone)
		Next
		Return True
	End Function


	Function PlayersOnMinute:Int(triggerEvent:TEventBase)
		If not Game.isGameLeader() then return False

		Local minute:Int = triggerEvent.GetData().getInt("minute",-1)
		If minute < 0 Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isAI() Then player.PlayerKI.ConditionalCallOnTick()
			If player.isAI() Then player.PlayerKI.CallOnMinute(minute)
		Next
		Return True
	End Function


	Function PlayersOnDay:Int(triggerEvent:TEventBase)
		If not Game.isGameLeader() then return False

		Local minute:Int = triggerEvent.GetData().getInt("minute",-1)
		If minute < 0 Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isAI() Then player.PlayerKI.CallOnDayBegins()
		Next
		Return True
	End Function


	Function PlayerBroadcastMalfunction:Int(triggerEvent:TEventBase)
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		Local player:TPlayer = GetPlayerCollection().Get(playerID)
		If Not player Then Return False

		If player.isAI() Then player.PlayerKI.CallOnMalfunction()
	End Function


	Function PlayerFinanceOnChangeMoney:Int(triggerEvent:TEventBase)
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		Local player:TPlayer = GetPlayerCollection().Get(playerID)
		Local value:Int = triggerEvent.GetData().GetInt("value", 0)
		If playerID = -1 Or Not player Then Return False

		If player.isAI() Then player.PlayerKI.CallOnMoneyChanged()
		If player.isActivePlayer() Then GetInGameInterface().BottomImgDirty = True
	End Function


	'show an error if a transaction was not possible
	Function PlayerFinanceOnTransactionFailed:Int(triggerEvent:TEventBase)
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID", 0)
		Local player:TPlayer = GetPlayerCollection().Get(playerID)
		Local value:Int = triggerEvent.GetData().GetInt("value", 0)
		If playerID = -1 Or Not player Then Return False

		'create an visual error
		If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
	End Function


	Function PlayerBoss_OnCallPlayerForced:Int(triggerEvent:TEventBase)
		local latestTime:Long = triggerEvent.GetData().GetLong("latestTime", GetWorldTime().GetTimeGone() + 2*3600)
		local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		if player.IsAI() then player.PlayerKI.CallOnBossCallsForced()
		'send player to boss now
		player.SendToBoss()
	End Function
	

	Function PlayerBoss_OnPlayerEnterBossRoom:Int(triggerEvent:TEventBase)
		local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		local player:TPlayer = TPlayer(triggerEvent.GetReceiver())
		'only interested in the real player
		if not player or not player.isActivePlayer() then return False

		'remove potentially existing toastmessages
		local toastGUID:string = "toastmessage-playerboss-callplayer"+player.playerID
		local toast:TToastMessage = GetToastMessageCollection().GetMessageByGUID(toastGUID)
		GetToastMessageCollection().RemoveMessage( toast )
	End Function

	
	Function PlayerBoss_OnCallPlayer:Int(triggerEvent:TEventBase)
		local latestTime:Long = triggerEvent.GetData().GetLong("latestTime", GetWorldTime().GetTimeGone() + 2*3600)
		local boss:TPlayerBoss = TPlayerBoss(triggerEvent.GetSender())
		local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai about the request
		if player.IsAI()
			player.PlayerKI.CallOnBossCalls(latestTime)
		else
			'send out a toast message
			local toastGUID:string = "toastmessage-playerboss-callplayer"+player.playerID
			'try to fetch an existing one
			local toast:TGameToastMessage = TGameToastMessage(GetToastMessageCollection().GetMessageByGUID(toastGUID))
			if not toast then toast = new TGameToastMessage
		
			'until 2 hours
			toast.SetCloseAtWorldTime(latestTime)
			toast.SetCloseAtWorldTimeText("CLOSES_AT_TIME")
			toast.SetMessageType(1)
			toast.SetPriority(10)
			toast.SetCaption("Dein Chef will dich sehen")
			toast.SetText("Der Chef gibt dir 2 Stunden, sich bei Ihm zu melden. Hier klicken um den Besuch vorzeitig zu starten.")
			toast.SetOnCloseFunction(PlayerBoss_onClosePlayerCallMessage)
			toast.GetData().Add("boss", boss)
			toast.GetData().Add("player", player)

			'if this was a new message, the guid will differ
			if toast.GetGUID() <> toastGUID
				toast.SetGUID(toastGUID)
				'new messages get added to a list
				GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
			endif
		endif
	End Function


	'if a player clicks on the toastmessage calling him, he will get
	'sent to the boss in that moment
	Function PlayerBoss_onClosePlayerCallMessage:int(sender:TToastMessage)
		local boss:TPlayerBoss = TPlayerBoss(sender.GetData().get("boss"))
		local player:TPlayer = TPlayer(sender.GetData().get("player"))
		if not boss or not player then return False

		player.SendToBoss()
	End Function


	Function PublicAuthorities_onStopXRatedBroadcast:Int(triggerEvent:TEventBase)
		local programme:TProgramme = TProgramme(triggerEvent.GetSender())
		local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		if player.IsAI() then player.PlayerKI.CallOnPublicAuthoritiesStopXRatedBroadcast()

		'only interest in active players contracts
		if programme.owner <> GetPlayerCollection().playerID then return False

		local toast:TGameToastMessage = new TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(15)
		toast.SetMessageType(1) 'attention
		toast.SetCaption(GetLocale("AUTHORITIES_STOPPED_BROADCAST"))
		toast.SetText( ..
			GetLocale("BROADCAST_OF_XRATED_PROGRAMME_X_NOT_ALLOWED_DURING_DAYTIME").Replace("%TITLE%", "|b|"+programme.GetTitle()+"|/b|") + " " + ..
			GetLocale("PENALTY_OF_X_WAS_PAID").Replace("%MONEY%", "|b|"+TFunctions.DottedValue(GameRules.sentXRatedPenalty)+getLocale("CURRENCY")+"|/b|") ..
		)
		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function


	Function PublicAuthorities_onConfiscateProgrammeLicence:Int(triggerEvent:TEventBase)
		local targetProgrammeLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID( triggerEvent.GetData().GetString("targetProgrammeGUID") )
		local confiscatedProgrammeLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID( triggerEvent.GetData().GetString("confiscatedProgrammeGUID") )
		local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		if player.IsAI() then player.PlayerKI.CallOnPublicAuthoritiesConfiscateProgrammeLicence(confiscatedProgrammeLicence, targetProgrammeLicence)

		'only interest in active players contracts
		if confiscatedProgrammeLicence.owner <> GetPlayerCollection().playerID then return False

		local toast:TGameToastMessage = new TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(15)
		toast.SetMessageType(1) 'attention
		toast.SetCaption(GetLocale("AUTHORITIES_CONFISCATED_LICENCE"))
		local text:string = GetLocale("PROGRAMMELICENCE_X_GOT_CONFISCATED").Replace("%TITLE%", "|b|"+confiscatedProgrammeLicence.GetTitle()+"|/b|") + " "
		if confiscatedProgrammeLicence <> targetProgrammeLicence
			text :+ GetLocale("SEEMS_AUTHORITIES_VISITED_THE_WRONG_ROOM")
		else
			text :+ GetLocale("BETTER_WATCH_OUT_NEXT_TIME")
		endif
		
		toast.SetText(text)
		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function
	
	Function AdContract_OnFinish:Int(triggerEvent:TEventBase)
		local contract:TAdContract = TAdContract(triggerEvent.GetSender())
		if not contract then return False

		'only interest in active players contracts
		if contract.owner <> GetPlayerCollection().playerID then return False

		'send out a toast message
		local toast:TGameToastMessage = new TGameToastMessage
	
		'show it for some seconds
		toast.SetLifeTime(8)
		toast.SetMessageType(2) 'positive
		toast.SetCaption(GetLocale("ADCONTRACT_FINISHED"))
		toast.SetText( ..
			GetLocale("ADCONTRACT_X_SUCCESSFULLY_FINISHED").Replace("%TITLE%", contract.GetTitle()) + " " + ..
			GetLocale("PROFIT_OF_X_GOT_CREDITED").Replace("%MONEY%", "|b|"+TFunctions.DottedValue(contract.GetProfit())+getLocale("CURRENCY")+"|/b|") ..
		)
		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function

	
	Function AdContract_OnFail:Int(triggerEvent:TEventBase)
		local contract:TAdContract = TAdContract(triggerEvent.GetSender())
		if not contract then return False

		'only interest in active players contracts
		 if contract.owner <> GetPlayerCollection().playerID then return False

		'send out a toast message
		local toast:TGameToastMessage = new TGameToastMessage
	
		'show it for some more seconds
		toast.SetLifeTime(12)
		toast.SetMessageType(3) 'negative
		toast.SetCaption(GetLocale("ADCONTRACT_FAILED"))
		toast.SetText( ..
			GetLocale("ADCONTRACT_X_FAILED").Replace("%TITLE%", contract.GetTitle()) + " " + ..
			GetLocale("PENALTY_OF_X_WAS_PAID").Replace("%MONEY%", "|b|"+TFunctions.DottedValue(contract.GetPenalty())+getLocale("CURRENCY")+"|/b|") ..
		)
		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function


	'called each time a room (the active player visits) is updated
	Function RoomOnUpdate:Int(triggerEvent:TEventBase)
		'handle normal right click
		If MOUSEMANAGER.IsHit(2)
			'check subrooms
			'only leave a room if not in a subscreen
			'if in subscreen, go to parent one
			If ScreenCollection.GetCurrentScreen().parentScreen
				ScreenCollection.GoToParentScreen()
				MOUSEMANAGER.ResetKey(2)
			Else
				'leaving prohibited - just reset button
				If Not GetPlayer().GetFigure().LeaveRoom()
					MOUSEMANAGER.resetKey(2)
				EndIf
			EndIf
		EndIf
	End Function


	Function StationMapOnSellStation:Int(triggerEvent:TEventBase)
		Local stationMap:TStationMap = TStationMap(triggerEvent.GetSender())
		If Not stationMap Then Return False
		
		Local player:TPlayer = GetPlayerCollection().Get(stationMap.owner)
		If Not player Then Return False

		TLogger.Log("StationMapOnSellStation", "recomputing audience for player "+player.playerID, LOG_DEBUG)
		GetBroadcastManager().ReComputePlayerAudience(player.playerID)
	End Function


	Function StationMapOnTrySellLastStation:Int(triggerEvent:TEventBase)
		Local stationMap:TStationMap = TStationMap(triggerEvent.GetSender())
		If Not stationMap Then Return False

		Local player:TPlayer = GetPlayerCollection().Get(stationMap.owner)
		If Not player Then Return False

		'create an visual error
		If player.isActivePlayer() Then TError.Create( getLocale("ERROR_NOT_POSSIBLE"), getLocale("ERROR_NOT_ABLE_TO_SELL_LAST_STATION") )
	End Function



	Function OnMinute:Int(triggerEvent:TEventBase)
		Local minute:Int = triggerEvent.GetData().GetInt("minute",-1)
		Local hour:Int = triggerEvent.GetData().GetInt("hour",-1)
		Local day:Int = triggerEvent.GetData().GetInt("day",-1)
		If hour = -1 Then Return False

		'=== UPDATE POPULARITY MANAGER ===
		'the popularity manager takes care itself whether to do something
		'or not (update intervals)
		GetPopularityManager().Update(triggerEvent)


		'=== UPDATE NEWS AGENCY ===
		'check if it is time for new news
		GetNewsAgency().Update()


		'=== CHANGE OFFER OF MOVIEAGENCY AND ADAGENCY ===
		'countdown for the refillers
		Game.refillMovieAgencyTime :-1
		Game.refillAdAgencyTime :-1
		'refill if needed
		If Game.refillMovieAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("movieagency").hasOccupant()
				Game.refillMovieAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				Game.refillMovieAgencyTime = Game.refillMovieAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling movieagency", LOG_DEBUG)
				RoomHandler_movieagency.GetInstance().ReFillBlocks(True, 0.5)
			EndIf
		EndIf
		If Game.refillAdAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("adagency").hasOccupant()
				Game.refillAdAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				Game.refillAdAgencyTime = Game.refillAdAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling adagency", LOG_DEBUG)
				if Game.refillAdAgencyOverridePercentage <> Game.refillAdAgencyPercentage
					RoomHandler_adagency.GetInstance().ReFillBlocks(True, Game.refillAdAgencyOverridePercentage)
					Game.refillAdAgencyOverridePercentage = Game.refillAdAgencyPercentage
				else
					RoomHandler_adagency.GetInstance().ReFillBlocks(True, Game.refillAdAgencyPercentage)
				endif
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
			local broadcastMaterial:TBroadcastMaterial

			'step 1/2
			'log in current broadcasted media
			For Local player:TPlayer = EachIn GetPlayerCollection().players
				broadcastMaterial = player.GetProgrammePlan().LogInCurrentBroadcast(day, hour, minute)
				'adjust currently broadcasted block
				if broadcastMaterial
					broadcastMaterial.currentBlockBroadcasting = player.GetProgrammePlan().GetObjectBlock(broadcastMaterial.usedAsType, day, hour)
				endif
			Next
			
			'step 2/2
			'calculate audience
			TPlayerProgrammePlan.CalculateCurrentBroadcastAudience(day, hour, minute)
		EndIf


		'=== CHECK FOR X-RATED PROGRAMME ===
		'calculate each hour if not or when the current broadcasts are
		'checked for XRated.
		'do this to create some tension :p
		if minute = 0 then Game.ComputeNextXRatedCheckMinute()

		'time to check for Xrated programme?
		if minute = Game.GetNextXRatedCheckMinute()
			'only check between 6:00-21:59 o'clock (there it is NOT allowed)
			if hour <= 21 and hour >= 6
				local currentProgramme:TProgramme
				For Local player:TPlayer = EachIn GetPlayerCollection().players
					currentProgramme = TProgramme(player.GetProgrammePlan().GetProgramme(day, hour))
					'skip non-programme broadcasts or malfunction
					if not currentProgramme then continue
					'skip "normal" programme
					if not currentProgramme.data.IsXRated() then continue

					'pay penalty
					player.GetFinance().PayMisc(GameRules.sentXRatedPenalty)
					'remove programme from plan
					player.GetProgrammePlan().RemoveProgramme(currentProgramme, day, hour)
					'set current broadcast to malfunction
					GetBroadcastManager().SetBroadcastMalfunction(player.playerID, TBroadcastMaterial.TYPE_PROGRAMME)
					'decrease image by 0.5%
					player.GetPublicImage().ChangeImage(New TAudience.AddFloat(-0.5))

					'chance of 25% the programme will get (tried) to get confiscated
					local confiscateProgramme:int = RandRange(0,100) < 25

					if confiscateProgramme
						EventManager.triggerEvent(TEventSimple.Create("publicAuthorities.onStartConfiscateProgramme", new TData.AddString("broadcastMaterialGUID", currentProgramme.GetGUID()).AddNumber("owner", player.playerID), currentProgramme, player))

						'Send out first marshal - Mr. Czwink or Mr. Czwank
						Game.marshals[randRange(0,1)].AddConfiscationJob(currentProgramme.GetGUID())
					endif

					'emit event (eg.for ingame toastmessages)
					EventManager.triggerEvent(TEventSimple.Create("publicAuthorities.onStopXRatedBroadcast",Null , currentProgramme, player))
				Next
			endif
		endif


		'=== INFORM BROADCASTS ===
		'inform about broadcasts starting / ending
		'-> earn call-in profit
		'-> cut topicality
		If (minute = 5 Or minute = 55 Or minute = 0) or ..
		   (minute = 4 Or minute = 54 or minute = 59)
			For Local player:TPlayer = EachIn GetPlayerCollection().players
				player.GetProgrammePlan().InformCurrentBroadcast(day, hour, minute)
			Next
		endIf
	
		Return True
	End Function


	'things happening each hour
	Function OnHour:Int(triggerEvent:TEventBase)
		'
	End Function


	Function OnDay:Int(triggerEvent:TEventBase)
		Local day:Int = triggerEvent.GetData().GetInt("day", -1)

		TLogger.Log("GameEvents.OnDay", "begin of day "+(GetWorldTime().GetDaysRun()+1)+" (real day: "+day+")", LOG_DEBUG)

		'if new day, not start day
		If GetWorldTime().GetDaysRun() >= 1

			'Neuer Award faellig?
			If GetBetty().GetAwardEnding() < GetWorldTime().getDay() - 1
				GetBetty().GetLastAwardWinner()
				GetBetty().SetAwardType(RandRange(0, GetBetty().MaxAwardTypes), True)
			End If

			GetProgrammeDataCollection().RefreshTopicalities()
			GetAdContractBaseCollection().RefreshInfomercialTopicalities()
			Game.ComputeContractPenalties()
			Game.ComputeDailyCosts()	'first pay everything, then earn...
			Game.ComputeDailyIncome()
			TAuctionProgrammeBlocks.EndAllAuctions() 'won auctions moved to programmecollection of player

			'reset room signs each day to their normal position
			TRoomBoardSign.ResetPositions()


			'remove no longer needed DailyBroadcastStatistics
			'by default we store maximally 3 days
			GetDailyBroadcastStatisticCollection().RemoveBeforeDay( day - 3 )


			'force adagency to refill their sortiment a bit more intensive
			'the next time
			'Game.refillAdAgencyTime = -1
			Game.refillAdAgencyOverridePercentage = 0.75
			

			'TODO: give image points or something like it for best programme
			'of day?!
			local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic( day - 1 )
			if stat.bestBroadcast
				local audience:string = ""
				if stat.bestAudience then audience = Long(stat.bestAudience.GetSum())+", player: "+stat.bestBroadcast.owner
				TLogger.Log("OnDay", "BestBroadcast: "+stat.bestBroadcast.GetTitle() + " (audience: "+audience+")", LOG_INFO)
			else
				TLogger.Log("OnDay", "BestBroadcast: No best broadcast found for today", LOG_INFO)
			endif


			'=== REMOVE OLD NEWS AND NEWSEVENTS ===
			'news and newsevents both have a "happenedTime" but they must
			'not be the same (multiple news with the same event but happened
			'to different times)
			local daysToKeep:int = 2
	
			'remove old news from the all player plans and collections
			For Local i:Int = 1 To 4
				'COLLECTION
				'news could stay there for 2 days (including today)
				daysToKeep = 2
				For local news:TNews = EachIn GetPlayerCollection().Get(i).GetProgrammeCollection().news
					If day - GetWorldTime().getDay(news.GetHappenedTime()) >= daysToKeep
						GetPlayer(i).GetProgrammeCollection().RemoveNews(news)
					EndIf
				Next

				'PLAN
				'news could get send a day longer (3 days incl. today)
				daysToKeep = 3
				For local news:TNews = EachIn GetPlayerCollection().Get(i).GetProgrammePlan().news
					If day - GetWorldTime().getDay(news.GetHappenedTime()) >= daysToKeep
						GetPlayer(i).GetProgrammePlan().RemoveNews(news)
					EndIf
				Next
			Next

			'NEWSEVENTS
			'remove old news events - wait a day more than "plan time"
			daysToKeep = 4
			GetNewsEventCollection().RemoveOutdatedNewsEvents(daysToKeep)
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
		EventManager.registerListenerFunction("ToastMessageCollection.onAddMessage", onToastMessageCollectionAddMessage)
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


	Function onToastMessageCollectionAddMessage:Int(triggerEvent:TEventBase)
		'play a sound with the default sfxchannel
		SimpleSoundSource.PlayRandomSfx("gui_open_window")
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
			headerFont = GetBitmapFontManager().Copy("default", "headerFont", 18, BOLDFONT)
			headerFont.SetCharsEffectFunction(1, Font_AddGradient, gradientSettings)
			headerFont.SetCharsEffectFunction(2, Font_AddShadow, shadowSettings)
			headerFont.InitFont()

			headerFont = GetBitmapFont("headerFont", 18, ITALICFONT)
			headerFont.SetCharsEffectFunction(1, Font_AddGradient, gradientSettings)
			headerFont.SetCharsEffectFunction(2, Font_AddShadow, shadowSettings)
			headerFont.InitFont()

			headerFont = GetBitmapFont("headerFont", 18)
			headerFont.SetCharsEffectFunction(1, Font_AddGradient, gradientSettings)
			headerFont.SetCharsEffectFunction(2, Font_AddShadow, shadowSettings)
			headerFont.InitFont()
		EndIf
	End Function


	'lower priority updates (currently happening every 2 "appUpdates")
	Function onAppSystemUpdate:Int(triggerEvent:TEventBase)
		TProfiler.Enter("SoundUpdate")
		GetSoundManager().Update()
		TProfiler.Leave("SoundUpdate")
	End Function
End Type




OnEnd( EndHook )
Function EndHook()
	TProfiler.DumpLog("log.profiler.txt")
	TLogFile.DumpLogs()
End Function


'===== COMMON FUNCTIONS =====

Function DrawMenuBackground(darkened:Int=False)
	'no cls needed - we render a background
	'Cls
	SetColor 255,255,255
	GetSpriteFromRegistry("gfx_startscreen").Draw(0,0)


	'draw an (animated) logo
	Select game.gamestate
		Case TGame.STATE_NETWORKLOBBY, TGame.STATE_MAINMENU

			Global logoAnimStart:Int = 0
			Global logoAnimTime:Int = 1500
			Global logoScale:Float = 0.0
			Local logo:TSprite = GetSpriteFromRegistry("gfx_startscreen_logo")
			If logo
				Local timeGone:Int = Time.GetTimeGone()
				If logoAnimStart = 0 Then logoAnimStart = timeGone
				logoScale = TInterpolation.BackOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)
				logoScale :* TInterpolation.BounceOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)

				Local oldAlpha:Float = GetAlpha()
				SetAlpha TInterpolation.RegularOut(0.0, 1.0, Min(0.5*logoAnimTime, timeGone - logoAnimStart), 0.5*logoAnimTime)

				logo.Draw( GraphicsWidth()/2, 150, -1, ALIGN_CENTER_CENTER, logoScale)
				SetAlpha oldAlpha
			EndIf
	EndSelect

	If game.gamestate = TGame.STATE_MAINMENU
		SetColor 255,255,255
		GetBitmapFont("Default",11, ITALICFONT).drawBlock(versionstring, 10,575, 500,20, Null,TColor.Create(75,75,140))
		GetBitmapFont("Default",11, ITALICFONT).drawBlock(copyrightstring, 10,585, 500,20, Null,TColor.Create(60,60,120))
	EndIf

	If darkened
		SetColor 190,220,240
		SetAlpha 0.5
		DrawRect(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetAlpha 1.0
		SetColor 255, 255, 255
	EndIf
End Function






'- kann vor Spielstart durchgefuehrt werden
'- kann mehrfach ausgefuehrt werden
Function ColorizePlayerExtras()
	'colorize the images
	Local gray:TColor = TColor.Create(200, 200, 200)
	Local gray2:TColor = TColor.Create(100, 100, 100)
	Local gray3:TColor = TColor.Create(225, 225, 225)

	GetRegistry().Set("gfx_building_sign_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_base").GetColorizedImage(gray), "gfx_building_sign_0"))
	GetRegistry().Set("gfx_building_sign_dragged_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_dragged_base").GetColorizedImage(gray), "gfx_building_sign_dragged_0"))
	GetRegistry().Set("gfx_interface_channelbuttons_off_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_off").GetColorizedImage(gray2), "gfx_interface_channelbuttons_off_0"))
	GetRegistry().Set("gfx_interface_channelbuttons_on_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_on").GetColorizedImage(gray2), "gfx_interface_channelbuttons_on_0"))
	GetRegistry().Set("gfx_roomboard_sign_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base").GetColorizedImage(gray3,-1, COLORIZEMODE_OVERLAY), "gfx_roomboard_sign_0"))
	GetRegistry().Set("gfx_roomboard_sign_dragged_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base_dragged").GetColorizedImage(gray3,-1, COLORIZEMODE_OVERLAY), "gfx_roomboard_sign_dragged_0"))

	'colorizing for every player
	For Local i:Int = 1 To 4
		GetPlayerCollection().Get(i).RecolorFigure()
		Local color:TColor = GetPlayerCollection().Get(i).color

		GetRegistry().Set("stationmap_antenna"+i, New TSprite.InitFromImage(GetSpriteFromRegistry("stationmap_antenna0").GetColorizedImage(color,-1, COLORIZEMODE_OVERLAY), "stationmap_antenna"+i))
		GetRegistry().Set("gfx_building_sign_"+i, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_base").GetColorizedImage(color), "gfx_building_sign_"+i))
		GetRegistry().Set("gfx_roomboard_sign_"+i, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base").GetColorizedImage(color,-1, COLORIZEMODE_OVERLAY), "gfx_roomboard_sign_"+i))
		GetRegistry().Set("gfx_roomboard_sign_dragged_"+i, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base_dragged").GetColorizedImage(color, -1, COLORIZEMODE_OVERLAY), "gfx_roomboard_sign_dragged_"+i))
		GetRegistry().Set("gfx_interface_channelbuttons_off_"+i, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_off").GetColorizedImage(color, i), "gfx_interface_channelbuttons_off_"+i))
		GetRegistry().Set("gfx_interface_channelbuttons_on_"+i, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_on").GetColorizedImage(color, i), "gfx_interface_channelbuttons_on_"+i))
	Next
End Function



Function DEV_switchRoom:Int(room:TRoom)
	If Not room Then Return False

	'skip if already there
	if GetPlayer().GetFigure().inRoom = room then return False

	'to avoid seeing too much animation
	TInGameScreen_Room.temporaryDisableScreenChangeEffects = True

	'leave first
	if GetPlayer().GetFigure().inRoom
		GetPlayer().GetFigure().LeaveRoom(True)
	endif

	'remove potential elevator passenger 
	GetElevator().LeaveTheElevator(GetPlayer().GetFigure())
	
	'a) add the room as new target before all others
	'GetPlayer().GetFigure().PrependTarget(TRoomDoor.GetMainDoorToRoom(room))
	'b) set it as the only route
	GetPlayer().GetFigure().SetTarget(TRoomDoor.GetMainDoorToRoom(room))
	GetPlayer().GetFigure().MoveToCurrentTarget()


	Return True
End Function




Function StartApp:Int()
	TProfiler.Enter("StartApp")
	'assign dev config (resources are now loaded)
	App.devConfig = TData(GetRegistry().Get("DEV_CONFIG", New TData))

	'disable log from now on (if dev wished so)
	If not App.devConfig.GetBool("DEV_LOG", True)
		TLogger.SetPrintMode(0)
	EndIf

	'override infomercialCutFactor if given
	TAdContractBase.infomercialCutFactorDevModifier = App.devConfig.GetFloat("DEV_INFOMERCIALCUTFACTOR", 1.0)


	TFunctions.roundToBeautifulEnabled = App.devConfig.GetBool("DEV_ROUND_TO_BEAUTIFUL_VALUES", True)
	If TFunctions.roundToBeautifulEnabled
		TLogger.Log("StartTVTower()", "DEV RoundToBeautiful is enabled", LOG_DEBUG | LOG_LOADING)
	Else
		TLogger.Log("StartTVTower()", "DEV RoundToBeautiful is disabled", LOG_DEBUG | LOG_LOADING)
	EndIf

	Game.Create()


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

	App.Start()
	TProfiler.Leave("StartApp")
End Function

Function ShowApp:Int()
	TProfiler.Enter("ShowApp")
	'without creating players, rooms
	Game = TGame.GetInstance().Create(False, False)

	'Menu
	ScreenMainMenu = New TScreen_MainMenu.Create("MainMenu")
	ScreenCollection.Add(ScreenMainMenu)

	'go into the start menu
	Game.SetGamestate(TGame.STATE_MAINMENU)

	TProfiler.Leave("ShowApp")
End Function


Function StartTVTower(start:Int=True)
	Global InitialResourceLoadingDone:Int = False

	EventManager.Init()
	
	TProfiler.Enter("StartTVTower: Create App")
	App = TApp.Create(30, -1, True) 'create with screen refreshrate and vsync
'	App = TApp.Create(30, 40, False) 'create with refreshrate of 40
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



	'b) everything loaded - normal game loop
TProfiler.Enter("GameLoop")
	StartApp()
	Repeat
		GetDeltaTimer().Loop()

		'process events not directly triggered
		'process "onMinute" etc. -> App.OnUpdate, App.OnDraw ...
TProfiler.Enter("EventManager")
		EventManager.update()
TProfiler.Leave("EventManager")
		'If RandRange(0,20) = 20 Then GCCollect()
	Until AppTerminate() Or TApp.ExitApp
TProfiler.Leave("GameLoop")

	'take care of network
	If Game.networkgame Then Network.DisconnectFromServer()
End Function