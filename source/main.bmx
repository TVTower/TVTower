'Application: TVGigant/TVTower
'Author: Ronny Otto & Manuel Vögele

SuperStrict

Import brl.timer
Import brl.Graphics
Import brl.glmax2d
Import "basefunctions_network.bmx"
Import "basefunctions.bmx"						'Base-functions for Color, Image, Localization, XML ...
Import "basefunctions_screens.bmx"

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
Import "game.broadcast.base.bmx"				'Quotenberechnung
Import "game.player.finance.bmx"
'Import "game.player.bmx"
Import "game.stationmap.bmx"

Import "game.broadcastmaterial.programme.bmx" 'needed by gamefunctions
Import "game.player.programmecollection.bmx" 'needed by game.player.bmx
Import "game.player.programmeplan.bmx" 'needed by game.player.bmx

'===== Includes =====
include "game.player.bmx"

Include "gamefunctions.bmx" 					'Types: - TError - Errorwindows with handling
												'		- base class For buttons And extension newsbutton
												'		- stationmap-handling, -creation ...

Include "gamefunctions_betty.bmx"
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
Global VersionDate:String		= LoadText("incbin::source/version.txt")
Global VersionString:String		= "version of " + VersionDate
Global CopyrightString:String	= "by Ronny Otto & Manuel Vögele"
Global App:TApp = null
Global Interface:TInterface
Global Game:TGame
Global InGame_Chat:TGUIChat
Global PlayerDetailsTimer:Int = 0
Global MainMenuJanitor:TFigureJanitor
Global ScreenGameSettings:TScreen_GameSettings = null
Global ScreenMainMenu:TScreen_MainMenu = null
Global GameScreen_Building:TInGameScreen_Building = null
Global headerFont:TBitmapFont
Global Init_Complete:Int = 0

Global RURC:TRegistryUnloadedResourceCollection = TRegistryUnloadedResourceCollection.GetInstance()


'==== Initialize ====
AppTitle = "TVTower: " + VersionString + " " + CopyrightString
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



'Enthaelt Verbindung zu Einstellungen und Timern, sonst nix
Type TApp
	Field devConfig:TData = new TData
	'developer/base configuration
	Field configBase:TData = new TData
	'configuration containing base + user
	Field config:TData = new TData
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
	Global settingsBasePath:string = "config/settings.xml"
	Global settingsUserPath:string = "config/settings.user.xml"

	Function Create:TApp(updatesPerSecond:Int = 60, framesPerSecond:Int = 30, vsync:int=TRUE, initializeGUI:Int=True)
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
	
			GetGraphicsManager().SetVsync(vsync)
			GetGraphicsManager().SetResolution(800,600)
			GetGraphicsManager().InitGraphics()
			
			'load graphics needed for loading screen
			obj.LoadResources(obj.baseResourceXmlUrl, true)			
		EndIf

		Return obj
	End Function


	'if no startup-music was defined, try to play menu music if some
	'is loaded
	Function onLoadMusicResource( triggerEvent:TEventBase )
		local resourceName:string = triggerEvent.GetData().GetString("resourceName")
		if resourceName = "MUSIC"
			'if no music is played yet, try to get one from the "menu"-playlist
			if not GetSoundManager().isPlaying() then GetSoundManager().PlayMusicPlaylist("menu")
		endif
	End Function


	Function onLoadXmlFromFinished( triggerEvent:TEventBase )
		If triggerEvent.getData().getString("uri") = TApp.baseResourceXmlUrl
			TApp.baseResourcesLoaded = 1
		endif
	End Function


	Method LoadSettings:Int()
		local storage:TDataXmlStorage = new TDataXmlStorage
		storage.SetRootNodeKey("config")
		'load default config
		configBase = storage.Load(settingsBasePath)
		if not configBase then configBase = new TData

		'load custom config and merge to a useable "total" config
		config = configBase.copy().Append(storage.Load(settingsUserPath))
	End Method


	Method SaveSettings:Int(newConfig:TData)
		'save the data differing to the default config
		'that "-" sets libxml to output the content instead of writing to
		'a file. Normally you should write to "test.user.xml" to overwrite
		'the users customized settings

		'remove "DEV_" ignore key so they get stored too
		local storage:TDataXmlStorage = new TDataXmlStorage
		storage.SetRootNodeKey("config")
		storage.SetIgnoreKeysStartingWith("")
		storage.Save(settingsUserPath, newConfig.GetDifferenceTo(self.configBase))
	End Method


	Method ApplySettings:Int()
		GetGraphicsManager().SetFullscreen(config.GetBool("fullscreen", False))
		GetGraphicsManager().SetRenderer(config.GetInt("renderer", GetGraphicsManager().GetRenderer()))
		GetGraphicsManager().SetColordepth(config.GetInt("colordepth", 16))

		TSoundManager.SetAudioEngine(config.GetString("sound_engine", "AUTOMATIC"))
		TSoundManager.GetInstance().MuteMusic(not config.GetBool("sound_music", TRUE))
		TSoundManager.GetInstance().MuteSfx(not config.GetBool("sound_effects", TRUE))

		if Game then Game.LoadConfig(config)
	End Method


	Method LoadResources:Int(path:String="config/resources.xml", directLoad:int=FALSE)
		local registryLoader:TRegistryLoader = new TRegistryLoader
		registryLoader.LoadFromXML(path, directLoad)
	End Method


	Method SetLanguage:Int(languageCode:string="de")
		'skip if the same language is already set
		if TLocalization.GetCurrentLanguageCode() = languageCode then return False

		'select language
		TLocalization.SetCurrentLanguage(languageCode)

		'store in config - for auto save of user settings
		config.Add("language", languageCode)
		
		'inform others - so eg. buttons can re-localize
		EventManager.triggerEvent(TEventSimple.Create("Language.onSetLanguage", new TData.Add("languageCode", languageCode), self))
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
		if OnLoadMusicListener then EventManager.unregisterListenerByLink( OnLoadMusicListener )

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
		If overlay Then overlay.DrawOnImage(img, GetGraphicsManager().GetWidth() - overlay.GetWidth() - 10, 10, TColor.Create(255,255,255,0.5))

		'remove alpha
		SavePixmapPNG(ConvertPixmap(img, PF_RGB888), filename)

		TLogger.Log("App.SaveScreenshot", "Screenshot saved as ~q"+filename+"~q", LOG_INFO)
	End Method


	Function Update:Int()
		'every 3rd update do a system update
		if GetDeltaTimer().timesUpdated mod 3 = 0
			EventManager.triggerEvent( TEventSimple.Create("App.onSystemUpdate",null) )
		endif

		'check for new resources to load
		RURC.Update()

		KEYMANAGER.Update()
		MOUSEMANAGER.Update()

		'fetch and cache mouse and keyboard states for this cycle
		GUIManager.StartUpdates()


		'enable reading of clicked states (just for the case of being
		'diabled because of an exitDialogue exists)
		MouseManager.Enable(1)
		MouseManager.Enable(2)

		GUIManager.Update("SYSTEM")
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
					If KEYMANAGER.IsDown(KEY_UP) Then GetGameTime().speed:+0.10
					If KEYMANAGER.IsDown(KEY_DOWN) Then GetGameTime().speed = Max( GetGameTime().speed - 0.10, 0)

					If KEYMANAGER.IsDown(KEY_RIGHT)
						TEntity.worldSpeedFactor :+ 0.10
						GetGameTime().speed :+ 0.10
					endif
					If KEYMANAGER.IsDown(KEY_LEFT) Then
						TEntity.worldSpeedFactor = Max( TEntity.worldSpeedFactor - 0.10, 0)
						GetGameTime().speed = Max( GetGameTime().speed - 0.10, 0)
					Endif


					If KEYMANAGER.IsHit(KEY_1) Then Game.SetActivePlayer(1)
					If KEYMANAGER.IsHit(KEY_2) Then Game.SetActivePlayer(2)
					If KEYMANAGER.IsHit(KEY_3) Then Game.SetActivePlayer(3)
					If KEYMANAGER.IsHit(KEY_4) Then Game.SetActivePlayer(4)

					If KEYMANAGER.IsHit(KEY_W) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("adagency") )
					If KEYMANAGER.IsHit(KEY_A) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("archive", GetPlayerCollection().playerID) )
					If KEYMANAGER.IsHit(KEY_B) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("betty") )
					If KEYMANAGER.IsHit(KEY_F) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("movieagency"))
					If KEYMANAGER.IsHit(KEY_O) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("office", GetPlayerCollection().playerID))
					If KEYMANAGER.IsHit(KEY_C) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("chief", GetPlayerCollection().playerID))

					'e wie "employees" :D
					If KEYMANAGER.IsHit(KEY_E) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("credits"))
					If KEYMANAGER.IsHit(KEY_N) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("news", GetPlayerCollection().playerID))
					If KEYMANAGER.IsHit(KEY_R) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("roomboard"))
				EndIf
				If KEYMANAGER.IsHit(KEY_5) Then GetGameTime().speed = 120.0	'60 minutes per second
				If KEYMANAGER.IsHit(KEY_6) Then GetGameTime().speed = 240.0	'120 minutes per second
				If KEYMANAGER.IsHit(KEY_7) Then GetGameTime().speed = 360.0	'180 minutes per second
				If KEYMANAGER.IsHit(KEY_8) Then GetGameTime().speed = 480.0	'240 minute per second
				If KEYMANAGER.IsHit(KEY_9) Then GetGameTime().speed = 1.0	'1 minute per second
				If KEYMANAGER.IsHit(KEY_Q) Then Game.DebugQuoteInfos = 1 - Game.DebugQuoteInfos
				If KEYMANAGER.IsHit(KEY_P) Then GetPlayerCollection().Get().GetProgrammePlan().printOverview()

rem debug only
				If KEYMANAGER.IsHit(KEY_TAB)
					if TLocalization.GetCurrentLanguageCode() = "de"
						App.SetLanguage("en")
					else
						App.SetLanguage("de")
					endif
				endif
endrem					

				'Save game only when in a game
				if game.gamestate = TGame.STATE_RUNNING
					If KEYMANAGER.IsHit(KEY_S) Then TSaveGame.Save("savegame.xml")
				endif

				If KEYMANAGER.IsHit(KEY_L) Then TSaveGame.Load("savegame.xml")

				If KEYMANAGER.IsHit(KEY_D) Then Game.DebugInfos = 1 - Game.DebugInfos

				If Game.isGameLeader()
					If KEYMANAGER.Ishit(Key_F1) And GetPlayerCollection().Get(1).isAI() Then GetPlayerCollection().Get(1).PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F2) And GetPlayerCollection().Get(2).isAI() Then GetPlayerCollection().Get(2).PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F3) And GetPlayerCollection().Get(3).isAI() Then GetPlayerCollection().Get(3).PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F4) And GetPlayerCollection().Get(4).isAI() Then GetPlayerCollection().Get(4).PlayerKI.reloadScript()
				EndIf

				If KEYMANAGER.Ishit(Key_F5) Then GetNewsAgency().AnnounceNewNewsEvent()
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
	End Function


	Function Render:Int()
		TProfiler.Enter("Draw")
		ScreenCollection.DrawCurrent(GetDeltaTimer().GetTween())

		if App.devConfig.GetBool("DEV_OSD", FALSE)
			Local textX:Int = 20
			GetBitmapFontManager().baseFont.draw("Speed:" + Int(GetGameTime().GetGameMinutesPerSecond() * 100), textX , 0)
			textX:+80
			GetBitmapFontManager().baseFont.draw("FPS: "+GetDeltaTimer().currentFps, textX, 0)
			textX:+60
			GetBitmapFontManager().baseFont.draw("UPS: " + Int(GetDeltaTimer().currentUps), textX,0)
			textX:+60
			GetBitmapFontManager().baseFont.draw("Loop: "+Int(GetDeltaTimer().getLoopTimeAverage())+"ms", textX,0)
			textX:+100

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
		endif

		If Game.DebugInfos
			SetAlpha 0.75
			SetColor 0,0,0
			DrawRect(20,10,160,373)
			SetColor 255, 255, 255
			SetAlpha 1.0
			GetBitmapFontManager().baseFontBold.draw("Debug information:", 25,20)
			GetBitmapFontManager().baseFont.draw("Renderer: "+GetGraphicsManager().GetRendererName(), 25,40)

	'		GUIManager.Draw("InGame") 'draw ingamechat
	'		GetBitmapFontManager().baseFont.draw(Network.stream.UDPSpeedString(), 662,490)
			GetBitmapFontManager().baseFont.draw("Player positions:", 25,65)
			local roomName:string = ""
			local fig:TFigure
			For Local i:Int = 0 To 3
				fig = GetPlayerCollection().Get(i+1).figure
				roomName = "Building"
				If fig.inRoom
					roomName = fig.inRoom.Name
				elseif fig.IsInElevator()
					roomName = "InElevator"
				elseIf fig.IsAtElevator()
					roomName = "AtElevator"
				endif
				GetBitmapFontManager().baseFont.draw("P " + (i + 1) + ": "+roomName, 25, 80 + i * 11)
			Next

			if ScreenCollection.GetCurrentScreen()
				GetBitmapFontManager().baseFont.draw("onScreen: "+ScreenCollection.GetCurrentScreen().name, 25, 130)
			else
				GetBitmapFontManager().baseFont.draw("onScreen: Main", 25, 130)
			endif


			GetBitmapFontManager().baseFont.draw("Elevator routes:", 25,150)
			Local routepos:Int = 0
			Local startY:Int = 165
			If Game.networkgame Then startY :+ 4*11

			Local callType:String = ""

			Local directionString:String = "up"
			If GetBuilding().elevator.Direction = 1 Then directionString = "down"
			Local debugString:String =	"floor:" + GetBuilding().elevator.currentFloor +..
										"->" + GetBuilding().elevator.targetFloor +..
										" doorState:"+GetBuilding().elevator.ElevatorStatus

			GetBitmapFontManager().baseFont.draw(debugString, 25, startY)


			If GetBuilding().elevator.RouteLogic.GetSortedRouteList() <> Null
				For Local FloorRoute:TFloorRoute = EachIn GetBuilding().elevator.RouteLogic.GetSortedRouteList()
					If floorroute.call = 0 Then callType = " 'send' " Else callType= " 'call' "
					GetBitmapFontManager().baseFont.draw(FloorRoute.floornumber + callType + FloorRoute.who.Name, 25, startY + 15 + routepos * 11)
					routepos:+1
				Next
			Else
				GetBitmapFontManager().baseFont.draw("recalculate", 25, startY + 15)
			EndIf

			'room states: debug fuer sushitv
			local occupants:string = "-"
			if GetRoomCollection().GetFirstByDetails("adagency").HasOccupant()
				occupants = ""
				for local figure:TFigure = eachin GetRoomCollection().GetFirstByDetails("adagency").occupants
					occupants :+ figure.name+" "
				next
			Endif
			GetBitmapFontManager().baseFont.draw("AdA. : "+occupants, 25, 350)

			occupants = "-"
			if GetRoomCollection().GetFirstByDetails("movieagency").HasOccupant()
				occupants = ""
				for local figure:TFigure = eachin GetRoomCollection().GetFirstByDetails("movieagency").occupants
					occupants :+ figure.name+" "
				next
			Endif
			GetBitmapFontManager().baseFont.draw("MoA. : "+occupants, 25, 365)
		Endif
		'show quotes even without "DEV_OSD = true"
		If Game.DebugQuoteInfos
			Game.DebugAudienceInfo.Draw()
		EndIf


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
		if RURC.FinishedLoading() then return TRUE

		SetAlpha 0.2
		SetColor 50,0,0
		DrawRect(0, GraphicsHeight() - 20, GraphicsWidth(), 20)
		SetAlpha 1.0
		SetColor 255,255,255
		DrawText("Loading: "+RURC.loadedCount+"/"+RURC.toLoadCount+"  "+String(RURC.loadedLog.Last()), 0, 580)
	End Function


	Function onAppConfirmExit:Int(triggerEvent:TEventBase)
		local dialogue:TGUIModalWindow = TGUIModalWindow(triggerEvent.GetSender())
		if not dialogue then return False

		'store closeing time of this modal window (does not matter which
		'one) to skip creating another exit dialogue within a certain
		'timeframe
		ExitAppDialogueTime = Millisecs()

		'not interested in other dialogues
		if dialogue <> TApp.ExitAppDialogue then return False

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
		'100ms since last dialogue
		If MilliSecs() - ExitAppDialogueTime < 100 then Return False

		ExitAppDialogueTime = MilliSecs()
		'in single player: pause game
		If Game And Not Game.networkgame Then Game.SetPaused(True)

		ExitAppDialogue = New TGUIGameModalWindow.Create(new TPoint, new TPoint.Init(400,150), "SYSTEM")
		ExitAppDialogue.SetDialogueType(2)
		ExitAppDialogue.SetZIndex(100000)
		'limit to "screen" area
		If game.gamestate = TGame.STATE_RUNNING
			ExitAppDialogue.darkenedArea = new TRectangle.Init(20,10,760,373)
		EndIf

		ExitAppDialogue.SetCaptionAndValue( GetLocale("ALREADY_OVER"), GetLocale("DO_YOU_REALLY_WANT_TO_QUIT_THE_GAME") )
	End Function

End Type


'just an object holding all data which has to get saved
'it is kind of an "DataCollectionCollection" ;D
Type TSaveGame
	Field _Game:TGame = Null
	'store the time since when the app started - timers rely on this
	'and without, times will differ after "loading" (so elevator stops
	'closing doors etc.)
	'this allows to have "realtime" (independend from "logic updates")
	'effects - for visual effects (fading), sound ...
	Field _Time_startTime:Long = 0
	Field _GameTime:TGameTime = Null
	Field _GameRules:TGamerules = Null
	Field _ProgrammeDataCollection:TProgrammeDataCollection = Null
	Field _NewsEventCollection:TNewsEventCollection = Null
	Field _FigureCollection:TFigureCollection = Null
	Field _PlayerCollection:TPlayerCollection = Null
	Field _PlayerFinanceCollection:TPlayerFinanceCollection = Null
	Field _PlayerFinanceHistoryListCollection:TPlayerFinanceHistoryListCollection = Null
	Field _PlayerProgrammePlanCollection:TPlayerProgrammePlanCollection = null
	Field _PlayerProgrammeCollectionCollection:TPlayerProgrammeCollectionCollection = null
	Field _PublicImageCollection:TPublicImageCollection = null
	Field _EventManagerEvents:TList = null
	Field _PopularityManager:TPopularityManager = null
	Field _BroadcastManager:TBroadcastManager = null
	Field _StationMapCollection:TStationMapCollection = null
	Field _Building:TBuilding 'includes, sky, moon, ufo, elevator
	Field _NewsAgency:TNewsAgency
	Field _RoomHandler_MovieAgency:RoomHandler_MovieAgency
	Field _RoomHandler_AdAgency:RoomHandler_AdAgency
	Const MODE_LOAD:int = 0
	Const MODE_SAVE:int = 1


	Method RestoreGameData:Int()
		_Assign(_FigureCollection, TFigureCollection._instance, "FigureCollection", MODE_LOAD)
		_Assign(_ProgrammeDataCollection, TProgrammeDataCollection._instance, "ProgrammeDataCollection", MODE_LOAD)
		_Assign(_PlayerCollection, TPlayerCollection._instance, "PlayerCollection", MODE_LOAD)
		_Assign(_PlayerFinanceCollection, TPlayerFinanceCollection._instance, "PlayerFinanceCollection", MODE_LOAD)
		_Assign(_PlayerFinanceHistoryListCollection, TPlayerFinanceHistoryListCollection._instance, "PlayerFinanceHistoryListCollection", MODE_LOAD)
		_Assign(_PlayerProgrammeCollectionCollection, TPlayerProgrammeCollectionCollection._instance, "PlayerProgrammeCollectionCollection", MODE_LOAD)
		_Assign(_PlayerProgrammePlanCollection, TPlayerProgrammePlanCollection._instance, "PlayerProgrammePlanCollection", MODE_LOAD)
		_Assign(_PublicImageCollection, TPublicImageCollection._instance, "PublicImageCollection", MODE_LOAD)
		_Assign(_NewsEventCollection, NewsEventCollection, "NewsEventCollection", MODE_LOAD)
		_Assign(_NewsAgency, TNewsAgency._instance, "NewsAgency", MODE_LOAD)
		_Assign(_Building, TBuilding._instance, "Building", MODE_LOAD)
		_Assign(_EventManagerEvents, EventManager._events, "Events", MODE_LOAD)
		_Assign(_PopularityManager, TPopularityManager._instance, "PopularityManager", MODE_LOAD)
		_Assign(_BroadcastManager, TBroadcastManager._instance, "BroadcastManager", MODE_LOAD)
		_Assign(_StationMapCollection, TStationMapCollection._instance, "StationMapCollection", MODE_LOAD)
		_Assign(_GameTime, TGameTime._instance, "GameTime", MODE_LOAD)
		_Assign(_GameRules, GameRules, "GameRules", MODE_LOAD)
		_Assign(_RoomHandler_MovieAgency, RoomHandler_MovieAgency._instance, "MovieAgency", MODE_LOAD)
		_Assign(_RoomHandler_AdAgency, RoomHandler_AdAgency._instance, "AdAgency", MODE_LOAD)
		_Assign(_Game, Game, "Game")

		'restore "started time"
		Time.startTime = _Time_startTime
	End Method


	Method BackupGameData:Int()
		'store "started time"
		_Time_startTime = Time.startTime

		_Assign(Game, _Game, "Game", MODE_SAVE)
		_Assign(TBuilding._instance, _Building, "Building", MODE_SAVE)
		_Assign(TFigureCollection._instance, _FigureCollection, "FigureCollection", MODE_SAVE)
		_Assign(TPlayerCollection._instance, _PlayerCollection, "PlayerCollection", MODE_SAVE)
		_Assign(TPlayerFinanceCollection._instance, _PlayerFinanceCollection, "PlayerFinanceCollection", MODE_SAVE)
		_Assign(TPlayerFinanceHistoryListCollection._instance, _PlayerFinanceHistoryListCollection, "PlayerFinanceHistoryListCollection", MODE_SAVE)
		_Assign(TPlayerProgrammeCollectionCollection._instance, _PlayerProgrammeCollectionCollection, "PlayerProgrammeCollectionCollection", MODE_SAVE)
		_Assign(TPlayerProgrammePlanCollection._instance, _PlayerProgrammePlanCollection, "PlayerProgrammePlanCollection", MODE_SAVE)
		_Assign(TPublicImageCollection._instance, _PublicImageCollection, "PublicImageCollection", MODE_SAVE)
		_Assign(TProgrammeDataCollection._instance, _ProgrammeDataCollection, "ProgrammeDataCollection", MODE_SAVE)
		_Assign(NewsEventCollection, _NewsEventCollection, "NewsEventCollection", MODE_SAVE)
		_Assign(TNewsAgency._instance, _NewsAgency, "NewsAgency", MODE_SAVE)
		_Assign(EventManager._events, _EventManagerEvents, "Events", MODE_SAVE)
		_Assign(TPopularityManager._instance, _PopularityManager, "PopularityManager", MODE_SAVE)
		_Assign(TBroadcastManager._instance, _BroadcastManager, "BroadcastManager", MODE_SAVE)
		_Assign(TStationMapCollection._instance, _StationMapCollection, "StationMapCollection", MODE_SAVE)
		_Assign(TGameTime._instance, _GameTime, "GameTime", MODE_SAVE)
		_Assign(GameRules, _GameRules, "GameRules", MODE_SAVE)
		'special room data
		_Assign(RoomHandler_MovieAgency._instance, _RoomHandler_MovieAgency, "MovieAgency", MODE_Save)
		_Assign(RoomHandler_AdAgency._instance, _RoomHandler_AdAgency, "AdAgency", MODE_Save)
	End Method


	Method _Assign(objSource:object var, objTarget:object var, name:string="DATA", mode:int=0)
		if objSource
			objTarget = objSource
			if mode = MODE_LOAD
				TLogger.Log("TSaveGame.RestoreGameData()", "Loaded object "+name, LOG_DEBUG | LOG_SAVELOAD)
			else
				TLogger.Log("TSaveGame.BackupGameData()", "Saved object "+name, LOG_DEBUG | LOG_SAVELOAD)
			endif
		else
			TLogger.Log("TSaveGame", "object "+name+" was NULL - ignored", LOG_DEBUG | LOG_SAVELOAD)
		endif
	End Method


	Method CheckGameData:Int()
		'check if all data is available
		Return True
	End Method


	Function ShowMessage:int(load:int=false)
		local title:string = getLocale("PLEASE_BE_PATIENT")
		local text:string = getLocale("SAVEGAME_GETS_LOADED")
		if not load then text = getLocale("SAVEGAME_GETS_CREATED")

		local col:TColor = new TColor.Get()
		local pix:TPixmap = VirtualGrabPixmap(0, 0, GraphicsWidth(), GraphicsHeight() )
		Cls
		DrawPixmap(pix, 0,0)
		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(0,0, GraphicsWidth(), GraphicsHeight())
		SetAlpha 1.0
		SetColor 255,255,255

		GetSpriteFromRegistry("gfx_errorbox").Draw(GraphicsWidth()/2, GraphicsHeight()/2, -1, new TPoint.Init(0.5, 0.5))
		local w:int = GetSpriteFromRegistry("gfx_errorbox").GetWidth()
		local h:int = GetSpriteFromRegistry("gfx_errorbox").GetHeight()
		local x:int = GraphicsWidth()/2 - w/2
		local y:int = GraphicsHeight()/2 - h/2
		GetBitmapFont("Default", 15, BOLDFONT).drawBlock(title, x + 18, y + 15, w - 60, 40, Null, TColor.Create(150, 50, 50))
		GetBitmapFont("Default", 12).drawBlock(text, x + 18, y + 50, w - 40, h - 60, Null, TColor.Create(50, 50, 50))

		Flip 0
		col.SetRGBA()
	End Function


	Function Load:Int(saveName:String="savegame.xml")
		ShowMessage(true)

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
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnBeginLoad", new TData.addString("saveName", saveName)))
		'load savegame data into game object
		saveGame.RestoreGameData()

		'tell everybody we finished loading (eg. for clearing GUI-lists)
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnLoad", new TData.addString("saveName", saveName).add("saveGame", saveGame)))

		'call game that game continues/starts now
		Game.StartLoadedSaveGame()
		Return True
	End Function


	Function Save:Int(saveName:String="savegame.xml")
		ShowMessage(false)

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






Type TFigurePostman Extends TFigure
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500, 0, 0, 5000)

	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigurePostman(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		Super.Create(FigureName, sprite, x, onFloor, speed, ControlledByID)
		Return Self
	End Method


	'override to make the figure stay in the room for a random time
	Method onEnterRoom:int(room:TRoom, door:TRoomDoor)
		Super.onEnterRoom(room, door)

		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	Method UpdateCustom:Int()
		'figure is in building and without target waiting for orders
		If Not inRoom And Not target
			Local door:TRoomDoor
			'search for a visible door
			Repeat
				door = TRoomDoor.GetRandom()
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
	Field nextActionTime:int = 2500
	Field nextActionRandomTime:int = 500
	Field useElevator:Int = True
	Field useDoors:Int = True
	Field BoredCleanChance:Int = 10
	Field NormalCleanChance:Int = 30
	Field MovementRangeMinX:Int	= 220
	Field MovementRangeMaxX:Int	= 580


	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigureJanitor(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		Super.Create(FigureName, sprite, x, onFloor, speed, ControlledByID)
		area.dimension.setX(14)

		GetFrameAnimations().Set("cleanRight", TSpriteFrameAnimation.Create([ [11,130], [12,130] ], -1, 0) )
		GetFrameAnimations().Set("cleanLeft", TSpriteFrameAnimation.Create([ [13,130], [14,130] ], -1, 0) )

		Return Self
	End Method


	'override to make the figure stay in the room for a random time
	Method onEnterRoom:int(room:TRoom, door:TRoomDoor)
		Super.onEnterRoom(room, door)

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
	Method GetVelocity:TPoint()
		If currentAction = 1 then return new TPoint
		return velocity
	End Method


	Method UpdateCustom:Int()
		'waited to long - change target (returns false while in elevator)
		If hasToChangeFloor() And WaitAtElevatorTimer.isExpired()
			If ChangeTarget(Rand(150, 580), GetBuilding().area.position.y + GetBuilding().GetFloorY(GetFloor()))
				WaitAtElevatorTimer.Reset()
			EndIf
		EndIf

		'waited long enough in room ... go out
		if inRoom and nextActionTimer.isExpired()
			LeaveRoom()
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
				Until Abs(area.GetX() - zufallx) > 75

				'move to a different floor (only if doing nothing special)
				If useElevator And currentAction=0 And zufall > 80 And Not IsAtElevator()
					Local sendToFloor:Int = GetFloor() + 1
					If sendToFloor > 13 Then sendToFloor = 0
					ChangeTarget(zufallx, GetBuilding().area.position.y + GetBuilding().GetFloorY(sendToFloor))
					WaitAtElevatorTimer.Reset()
				'move to a different X on same floor - if not cleaning now
				Else If currentAction=0
					ChangeTarget(zufallx, GetBuilding().area.position.y + GetBuilding().GetFloorY(GetFloor()))
				EndIf
			EndIf

		EndIf

		If Not inRoom And nextActionTimer.isExpired() And Not hasToChangeFloor()
			nextActionTimer.SetRandomness(-nextActionRandomTime / TEntity.worldSpeedFactor, nextActionRandomTime * TEntity.worldSpeedFactor)
			nextActionTimer.SetInterval(nextActionTime / TEntity.worldSpeedFactor)
			nextActionTimer.Reset()

			
			currentAction = 0

			'chose actions
			'only clean with a chance of 30% when on the way to something
			'and do not clean if target is a room near figure
			local targetDoor:TRoomDoor = TRoomDoor(targetObj)
			If target And (Not targetDoor Or (20 < Abs(targetDoor.area.GetX() - area.GetX()) Or targetDoor.area.GetY() <> GetFloor()))
				If Rand(0,100) < NormalCleanChance Then currentAction = 1
			EndIf
			'if just standing around give a chance to clean
			If Not target And Rand(0,100) < BoredCleanChance Then currentAction = 1
		EndIf

		if targetObj
			If Not useDoors And TRoomDoor(targetObj) Then targetObj = Null
		endif
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

		self.SetScreenChangeEffects(null,null) 'menus do not get changers

		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		local panelGap:int = GUIManager.config.GetInt("panelGap", 10)
		guiButtonsWindow = New TGUIGameWindow.Create(new TPoint.Init(300, 330), new TPoint.Init(200, 400), name)
		guiButtonsWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")

		guiButtonsPanel	= guiButtonsWindow.AddContentBox(0,0,-1,-1)

		TGUIButton.SetTypeFont( GetBitmapFontManager().baseFontBold )
		TGUIButton.SetTypeCaptionColor( TColor.CreateGrey(75) )

		guiButtonStart		= New TGUIButton.Create(new TPoint.Init(0,   0), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonNetwork	= New TGUIButton.Create(new TPoint.Init(0,  40), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonOnline		= New TGUIButton.Create(new TPoint.Init(0,  80), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonSettings	= New TGUIButton.Create(new TPoint.Init(0, 120), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonQuit		= New TGUIButton.Create(new TPoint.Init(0, 170), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonNetwork)
		guiButtonsPanel.AddChild(guiButtonOnline)
		guiButtonsPanel.AddChild(guiButtonSettings)
		guiButtonsPanel.AddChild(guiButtonQuit)


		if TLocalization.languagesCount > 0
			guiLanguageDropDown = New TGUISpriteDropDown.Create(new TPoint.Init(620, 560), new TPoint.Init(170,-1), "Sprache", 128, name)
			local itemHeight:int = 0
			local languageCount:int = 0

			For local lang:TLocalizationLanguage = eachin TLocalization.languages.Values()
				languageCount :+ 1
				local item:TGUISpriteDropDownItem = new TGUISpriteDropDownItem.Create(null, null, lang.Get("LANGUAGE_NAME_LOCALE"))
				item.SetValueColor(TColor.CreateGrey(100))
				item.data.Add("value", lang.Get("LANGUAGE_NAME_LOCALE"))
				item.data.Add("languageCode", lang.languageCode)
				item.data.add("spriteName", "flag_"+lang.languageCode)
				'item.SetZindex(10000)
				guiLanguageDropDown.AddItem(item)
				if itemHeight = 0 then itemHeight = item.GetScreenHeight()

				if lang.languageCode = TLocalization.GetCurrentLanguageCode()
					guiLanguageDropDown.SetSelectedEntry(item)
				endif
			Next
			GuiManager.SortLists()
			'we want to have max 4 items visible at once
			guiLanguageDropDown.SetListContentHeight(itemHeight * Min(languageCount,4))
			EventManager.registerListenerMethod("GUIDropDown.onSelectEntry", self, "onSelectLanguageEntry", guiLanguageDropDown)
		endif

		'fill captions with the localized values
		SetLanguage()

		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickButtons")

		'handle saving/applying of settings
		EventManager.RegisterListenerMethod("guiModalWindow.onClose", self, "onCloseModalDialogue")

		Return Self
	End Method


	Method onCloseModalDialogue:Int(triggerEvent:TEventBase)
		if not settingsWindow then return False
		
		local dialogue:TGUIModalWindow = TGUIModalWindow(triggerEvent.GetSender())
		if dialogue <> settingsWindow.modalDialogue then return False

		'"apply" button was used...save the whole thing
		if triggerEvent.GetData().GetInt("closeButton", -1) = 0
			ApplySettingsWindow()
		endif
		'unset variable - allows escape/quit-window again
		settingsWindow = null
	End Method



	'handle clicks on the buttons
	Method onSelectLanguageEntry:Int(triggerEvent:TEventBase)
		local languageEntry:TGUIObject = TGUIObject(triggerEvent.GetReceiver())
		if not languageEntry then Return False

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
		settingsWindow = new TSettingsWindow.Init()
	End Method


	Method ApplySettingsWindow:int()
		local newConfig:TData = App.config.copy()
		'append values stored in gui elements
		newConfig.Append(settingsWindow.ReadGuiValues())

		App.SaveSettings(newConfig)
		'save the new config as current config
		App.config = newConfig
		'and "reinit" settings
		App.ApplySettings()
	End Method
	

	'override default
	Method SetLanguage:int(languageCode:String = "")
		guiButtonStart.SetCaption(GetLocale("MENU_SOLO_GAME"))
		guiButtonNetwork.SetCaption(GetLocale("MENU_NETWORKGAME"))
		guiButtonOnline.SetCaption(GetLocale("MENU_ONLINEGAME"))
		guiButtonSettings.SetCaption(GetLocale("MENU_SETTINGS"))
		guiButtonQuit.SetCaption(GetLocale("MENU_QUIT"))
	End Method
	

	'override default draw
	Method Draw:int(tweenValue:float)
		DrawMenuBackground(False)

		'draw the janitor BEHIND the panels
		if MainMenuJanitor then MainMenuJanitor.Draw(tweenValue)

		GUIManager.Draw(Self.name)
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)
		Super.Update(deltaTime)

		'if gamesettings screen is still missing: disable buttons
		'-> resources not finished loading
		if not ScreenGameSettings
			guiButtonStart.Disable()
			guiButtonNetwork.Disable()
			guiButtonOnline.Disable()
		else
			guiButtonStart.Enable()
			guiButtonNetwork.Enable()
			guiButtonOnline.Enable()
		endif



		GUIManager.Update(Self.name)

		if MainMenuJanitor then  MainMenuJanitor.Update()
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
	Global settingsArea:TRectangle = new TRectangle.Init(10,10,780,0) 'position of the panel
	Global playerBoxDimension:TPoint = new TPoint.Init(165,150) 'size of each player area
	Global playerColors:Int = 10
	Global playerColorHeight:Int = 10
	Global playerSlotGap:Int = 25
	Global playerSlotInnerGap:Int = 10 'the gap between inner canvas and inputs


	Method Create:TScreen_GameSettings(name:String)
		Super.Create(name)

		'===== CREATE AND SETUP GUI =====
		guiSettingsWindow = New TGUIGameWindow.Create(settingsArea.position, settingsArea.dimension, name)
		guiSettingsWindow.guiBackground.spriteAlpha = 0.5
		local panelGap:int = GUIManager.config.GetInt("panelGap", 10)
		guiSettingsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)

		guiPlayersPanel = guiSettingsWindow.AddContentBox(0,0,-1, playerBoxDimension.GetY() + 2 * panelGap)
		guiSettingsPanel = guiSettingsWindow.AddContentBox(0,0,-1, 100)

		guiGameTitleLabel	= New TGUILabel.Create(new TPoint.Init(0, 0), "", TColor.CreateGrey(75), name)
		guiGameTitle		= New TGUIinput.Create(new TPoint.Init(0, 12), new TPoint.Init(300, -1), "", 32, name)
		guiStartYearLabel	= New TGUILabel.Create(new TPoint.Init(310, 0), "", TColor.CreateGrey(75), name)
		guiStartYear		= New TGUIinput.Create(new TPoint.Init(310, 12), new TPoint.Init(65, -1), "", 4, name)

		Local checkboxHeight:Int = 0
		gui24HoursDay = New TGUICheckBox.Create(new TPoint.Init(430, 0), new TPoint.Init(300), "", name)
		gui24HoursDay.SetChecked(True, False)
		gui24HoursDay.disable() 'option not implemented
		checkboxHeight :+ gui24HoursDay.GetScreenHeight()

		guiSpecialFormats = New TGUICheckBox.Create(new TPoint.Init(430, 0 + checkboxHeight), new TPoint.Init(300), "", name)
		guiSpecialFormats.SetChecked(True, False)
		guiSpecialFormats.disable() 'option not implemented
		checkboxHeight :+ guiSpecialFormats.GetScreenHeight()

		guiFilterUnreleased = New TGUICheckBox.Create(new TPoint.Init(430, 0 + checkboxHeight), new TPoint.Init(300), "", name)
		guiFilterUnreleased.SetChecked(True, False)
		checkboxHeight :+ guiFilterUnreleased.GetScreenHeight()

		guiAnnounce = New TGUICheckBox.Create(new TPoint.Init(430, 0 + checkboxHeight), new TPoint.Init(300), "", name)
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
		guiButtonsWindow = New TGUIGameWindow.Create(new TPoint.Init(590, 400), new TPoint.Init(200, 190), name)
		guiButtonsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")


		guiButtonsPanel = guiButtonsWindow.AddContentBox(0,0,-1,-1)

		TGUIButton.SetTypeFont( GetBitmapFontManager().baseFontBold )
		TGUIButton.SetTypeCaptionColor( TColor.CreateGrey(75) )

		guiButtonStart = New TGUIButton.Create(new TPoint.Init(0, 0), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonBack = New TGUIButton.Create(new TPoint.Init(0, guiButtonsPanel.GetcontentScreenHeight() - guiButtonStart.GetScreenHeight()), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonBack)


		guiChatWindow = New TGUIChatWindow.Create(new TPoint.Init(10,400), new TPoint.Init(540,190), name)
		guiChatWindow.guiChat.guiInput.setMaxLength(200)

		guiChatWindow.guiBackground.spriteAlpha = 0.5
		guiChatWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiChatWindow.guiChat.guiList.Resize(guiChatWindow.guiChat.guiList.rect.GetW(), guiChatWindow.guiChat.guiList.rect.GetH()-10)
		guiChatWindow.guiChat.guiInput.rect.position.MoveXY(panelGap, -panelGap)
		guiChatWindow.guiChat.guiInput.Resize( guiChatWindow.guiChat.GetContentScreenWidth() - 2* panelGap, guiStartYear.GetScreenHeight())

		local player:TPlayer
		For Local i:Int = 0 To 3
			player = GetPlayerCollection().Get(i+1)
			Local slotX:Int = i * (playerSlotGap + playerBoxDimension.GetIntX())
			Local playerPanel:TGUIBackgroundBox = New TGUIBackgroundBox.Create(new TPoint.Init(slotX, 0), new TPoint.Init(playerBoxDimension.GetIntX(), playerBoxDimension.GetIntY()), name)
			playerPanel.spriteBaseName = "gfx_gui_panel.subContent.bright"
			playerPanel.SetPadding(playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap)
			guiPlayersPanel.AddChild(playerPanel)

			guiPlayerNames[i] = New TGUIinput.Create(new TPoint.Init(0, 0), new TPoint.Init(playerPanel.GetContentScreenWidth(), -1), player.Name, 16, name)
			guiPlayerNames[i].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_player"))

			guiChannelNames[i] = New TGUIinput.Create(new TPoint.Init(0, 0), new TPoint.Init(playerPanel.GetContentScreenWidth(), -1), player.channelname, 16, name)
			guiChannelNames[i].rect.position.SetY(playerPanel.GetContentScreenHeight() - guiChannelNames[i].rect.GetH())
			guiChannelNames[i].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_tvchannel"))

			'left arrow
			guiFigureArrows[i*2 + 0] = New TGUIArrowButton.Create(new TPoint.Init(0 + 10, 50), new TPoint.Init(24, 24), "LEFT", name)
			'right arrow
			guiFigureArrows[i*2 + 1] = New TGUIArrowButton.Create(new TPoint.Init(playerPanel.GetContentScreenWidth() - 10, 50), new TPoint.Init(24, 24), "RIGHT", name)
			guiFigureArrows[i*2 + 1].rect.position.MoveXY(-guiFigureArrows[i*2 + 1].GetScreenWidth(),0)

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
	Method Start:int()
		guiGameTitle.SetValue(Game.title)
		guiStartYear.SetValue(Game.userStartYear)
		guiPlayerNames[0].SetValue(game.username)
		guiChannelNames[0].SetValue(game.userchannelname)
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
						Game.SetGamestate(TGame.STATE_NETWORKLOBBY)
						guiAnnounce.SetChecked(FALSE)
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
		if Game.gamestate = TGame.STATE_SETTINGSMENU
			If sender.isChecked()
				TGame.SendSystemMessage(GetLocale("OPTION_ON")+": "+sender.GetValue())
			Else
				TGame.SendSystemMessage(GetLocale("OPTION_OFF")+": "+sender.GetValue())
			EndIf
		endif
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
			GetGameTime().setStartYear( Max(1980, Int(value)) )
			TGUIInput(sender).value = Max(1980, Int(value))
		EndIf
	End Method


	'override default
	Method SetLanguage:int(languageCode:String = "")
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
		local y:int = 0
		gui24HoursDay.rect.position.SetY(0)
		y :+ gui24HoursDay.GetScreenHeight()

		guiSpecialFormats.rect.position.SetY(y)
		y :+ guiSpecialFormats.GetScreenHeight()

		guiFilterUnreleased.rect.position.SetY(y)
	End Method
	

	Method Draw:int(tweenValue:float)
		DrawMenuBackground(True)

		'background gui items
		GUIManager.Draw(name, 0, 100)

		Local slotPos:TPoint = new TPoint.Init(guiPlayersPanel.GetContentScreenX(),guiPlayersPanel.GetContentScreeny())
		For Local i:Int = 0 To 3
			If Game.networkgame Or GetPlayerCollection().playerID=1
				If Game.gamestate <> TGame.STATE_PREPAREGAMESTART And GetPlayerCollection().Get(i+1).Figure.ControlledByID = GetPlayerCollection().playerID Or (GetPlayerCollection().Get(i+1).Figure.ControlledByID = 0 And GetPlayerCollection().playerID = 1)
					SetColor 255,255,255
				Else
					SetColor 225,255,150
				EndIf
			EndIf

			'draw colors
			Local colorRect:TRectangle = new TRectangle.Init(slotPos.GetIntX()+2, Int(guiChannelNames[i].GetContentScreenY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)
			For Local obj:TColor = EachIn TColor.List
				If obj.ownerID = 0
					colorRect.position.MoveXY(colorRect.GetW(), 0)
					obj.SetRGB()
					DrawRect(colorRect.GetX(), colorRect.GetY(), colorRect.GetW(), colorRect.GetH())
				EndIf
			Next

			'draw player figure
			SetColor 255,255,255
			GetPlayerCollection().Get(i+1).Figure.Sprite.Draw(Int(slotPos.GetX() + playerBoxDimension.GetX()/2 - GetPlayerCollection().Get(1).Figure.Sprite.framew / 2), Int(colorRect.GetY() - GetPlayerCollection().Get(1).Figure.Sprite.area.GetH()), 8)

			'move to next slot position
			slotPos.MoveXY(playerSlotGap + playerBoxDimension.GetX(), 0)
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
			if guiAnnounce.isChecked()
				Network.client.playerName = GetPlayerCollection().Get().name
				If Not Network.announceEnabled Then Network.StartAnnouncing(Game.title)
			else
				Network.StopAnnouncing()
			endif
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
			Local slotPos:TPoint = new TPoint.Init(guiPlayersPanel.GetContentScreenX(),guiPlayersPanel.GetContentScreeny())
			For Local i:Int = 0 To 3
				Local colorRect:TRectangle = new TRectangle.Init(slotPos.GetIntX() + 2, Int(guiChannelNames[i].GetContentScreenY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)

				For Local obj:TColor = EachIn TColor.List
					'only for unused colors
					If obj.ownerID <> 0 Then Continue

					colorRect.position.MoveXY(colorRect.GetW(), 0)

					'skip if outside of rect
					If Not THelper.MouseInRect(colorRect) Then Continue
					If (GetPlayerCollection().Get(i+1).Figure.ControlledByID = GetPlayerCollection().playerID Or (GetPlayerCollection().Get(i+1).Figure.ControlledByID = 0 And GetPlayerCollection().playerID = 1))
						modifiedPlayers=True
						GetPlayerCollection().Get(i+1).RecolorFigure(obj)
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

		'create and setup GUI objects
		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		local panelGap:int = GUIManager.config.GetInt("panelGap", 10)
		guiButtonsWindow = New TGUIGameWindow.Create(new TPoint.Init(590, 355), new TPoint.Init(200, 235), name)
		guiButtonsWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.SetCaption("")
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsPanel = guiButtonsWindow.AddContentBox(0,0,-1,-1)


		guiButtonJoin	= New TGUIButton.Create(new TPoint.Init(0, 0), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(),-1), GetLocale("MENU_JOIN"), name)
		guiButtonCreate	= New TGUIButton.Create(new TPoint.Init(0, 45), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(),-1), GetLocale("MENU_CREATE_GAME"), name)
		guiButtonBack	= New TGUIButton.Create(new TPoint.Init(0, guiButtonsPanel.GetcontentScreenHeight() - guiButtonJoin.GetScreenHeight()), new TPoint.Init(guiButtonsPanel.GetContentScreenWidth(), -1), GetLocale("MENU_BACK"), name)

		guiButtonsPanel.AddChild(guiButtonJoin)
		guiButtonsPanel.AddChild(guiButtonCreate)
		guiButtonsPanel.AddChild(guiButtonBack)

		guiButtonJoin.disable() 'until an entry is clicked


		'GameList
		'contained within a window/panel for styling
		guiGameListWindow = New TGUIGameWindow.Create(new TPoint.Init(20, 355), new TPoint.Init(520, 235), name)
		guiGameListWindow.SetPadding(TScreen_GameSettings.headerSize, panelGap, panelGap, panelGap)
		guiGameListWindow.guiBackground.spriteAlpha = 0.5
		Local guiGameListPanel:TGUIBackgroundBox = guiGameListWindow.AddContentBox(0,0,-1,-1)
		'add list to the panel (which is located in the window
		guiGameList	= New TGUIGameList.Create(new TPoint.Init(0,0), new TPoint.Init(guiGameListPanel.GetContentScreenWidth(),guiGameListPanel.GetContentScreenHeight()), name)
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
	Method SetLanguage:int(languageCode:String = "")
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


	Method Draw:int(tweenValue:float)
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
	Field startGameCalled:int = False
	'was "prepareGame()" called already?
	Field prepareGameCalled:int = False
	'was "SpreadConfiguration()" called already?
	Field spreadConfigurationCalled:int = False
	'was "SpreadStartData()" called already?
	Field spreadStartDataCalled:int = False
	'can "startGame()" get called?
	Field canStartGame:int = False


	Method Create:TScreen_PrepareGameStart(name:String)
		Super.Create(name)

		messageWindow = new TGUIGameModalWindow.Create(new TPoint, new TPoint.Init(400,250), name)
		'messageWindow.DarkenedArea = new TRectangle.Init(20,10,760,373)
		messageWindow.SetCaptionAndValue("title", "")
		messageWindow.SetDialogueType(0) 'no buttons
		
		Return Self
	End Method


	Method Draw:int(tweenValue:float)
		'draw settings screen as background
		'BESSER: VORHERIGEN BILDSCHIRM zeichnen (fuer Laden)
		ScreenCollection.GetScreen("GameSettings").Draw(tweenValue)

		'draw messageWindow
		GUIManager.Draw(name)

		'rect of the message window's content area 
		local messageRect:TRectangle = messageWindow.GetContentScreenRect()
		local oldAlpha:float = GetAlpha()
		SetAlpha messageWindow.GetScreenAlpha()
		local messageDY:int = 0
		if Game.networkgame
			GetBitmapFontManager().baseFont.draw(GetLocale("SYNCHRONIZING_START_CONDITIONS")+"...", messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
			messageDY :+ 20
			for local i:int = 1 to 4
				GetBitmapFontManager().baseFont.draw(GetLocale("PLAYER")+" "+i+"..."+GetPlayerCollection().Get(i).networkstate+" MovieListCount: "+GetPlayerCollection().Get(i).GetProgrammeCollection().GetProgrammeLicenceCount(), messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
				messageDY :+ 20
			Next
			If Not Game.networkgameready = 1
				GetBitmapFontManager().baseFont.draw("not ready!!", messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
			EndIf
		Else
			GetBitmapFontManager().baseFont.draw(GetLocale("PREPARING_START_DATA")+"...", messageRect.GetX(), messageRect.GetY() + messageDY, TColor.clBlack)
		Endif
		SetAlpha oldAlpha
	End Method


	Method Reset:int()
		startGameCalled = False
		prepareGameCalled = False
		spreadConfigurationCalled = False
		spreadStartDataCalled = False
		canStartGame = False
	End Method


	'override to reset values
	Method Start:int()
		Reset()
		
		If Game.networkGame
			messageWindow.SetCaption(GetLocale("STARTING_NETWORKGAME"))
		Else
			messageWindow.SetCaption(GetLocale("STARTING_SINGLEPLAYERGAME"))
		EndIf
	End Method


	Method Enter:int(fromScreen:TScreen=null)
		Super.Enter(fromScreen)

		If wait = 0 then wait = Time.GetTimeGone()
		Reset()
	End Method


	global wait:int = 0

	'override default update
	Method Update:Int(deltaTime:Float)
		'update messagewindow
		GUIManager.Update(name)


		'=== STEPS ===
		'MP = MultiPlayer, SP = SinglePlayer, ALL = all modes
		'1. MP:  Spread configuration (database / name)
		'2. ALL: Prepare game (load database, color figures)
		'3. MP:  Check if ready to start game
		'4. ALL: Start game (if ready)


		'=== STEP 1 ===
		If game.networkGame
			SpreadConfiguration()
			spreadConfigurationCalled = True
		Endif


		'=== STEP 2 ===
		If not prepareGameCalled
			Game.PrepareStart()
			StartMultiplayerSyncStarted = Time.GetTimeGone()
			prepareGameCalled = True
		EndIf


		'=== STEP 3 ===
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

		if not startGameCalled
			'singleplayer games can always start
			If not Game.networkGame
'				if Time.GetTimeGone() - wait > 5000
					canStartGame = True
'				endif
			'multiplayer games can start if all players are ready
			else
				if Game.networkgameready = 1
					ScreenGameSettings.guiAnnounce.SetChecked(FALSE)
					GetPlayerCollection().Get().networkstate = 1
					canStartGame = True
				EndIf
			EndIf
		endif
		

		'=== STEP 4 ===
		If canStartGame and not startGameCalled
			'register events and start game
			Game.StartNewGame()
			'reset randomizer
			Game.SetRandomizerBase( Game.GetRandomizerBase() )
			startGameCalled = True
		EndIf
	End Method


	'spread configuration to other players
	Method SpreadConfiguration:int()
		if not Game.networkGame then return False

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
		local data:TData = new TData

		data.Add("playername", inputPlayerName.GetValue())
		data.Add("channelname", inputChannelName.GetValue())
		data.Add("startyear", inputStartYear.GetValue())
		'data.Add("stationmap", inputStationmap.GetValue())
		'data.Add("database", inputDatabase.GetValue())
		data.AddBoolString("sound_music", checkMusic.IsChecked())
		data.AddBoolString("sound_effects", checkSfx.IsChecked())

		data.AddBoolString("fullscreen", checkFullscreen.IsChecked())
		data.Add("gamename", inputGameName.GetValue())
		data.Add("onlineport", inputOnlinePort.GetValue())

		return data
	End Method


	Method SetGuiValues:int(data:TData)
		inputPlayerName.SetValue(data.GetString("playername", "Player"))
		inputChannelName.SetValue(data.GetString("channelname", "My Channel"))
		inputStartYear.SetValue(data.GetInt("startyear", 1985))
		'inputStationmap.SetValue(data.GetString("stationmap", "config/maps/germany.xml"))
		'inputDatabase.SetValue(data.GetString("database", "res/database.xml"))
		checkMusic.SetChecked(data.GetBool("sound_music", True))
		checkSfx.SetChecked(data.GetBool("sound_effects", True))

		checkFullscreen.SetChecked(data.GetBool("fullscreen", False))

		inputGameName.SetValue(data.GetString("gamename", "New Game"))
		inputOnlinePort.SetValue(data.GetInt("onlineport", 4544))
	End Method


	Method Init:TSettingsWindow()
		'LAYOUT CONFIG
		local nextY:int = 0, nextX:int = 0
		local rowWidth:int = 215
		local checkboxWidth:int = 180
		local inputWidth:int = 170
		local labelH:int = 12
		local inputH:int = 0
		local windowW:int = 670
		local windowH:int = 380

		modalDialogue = new TGUIGameModalWindow.Create(new TPoint, new TPoint.Init(windowW, windowH), "SYSTEM")

		modalDialogue.SetDialogueType(2)
		modalDialogue.buttons[0].SetCaption(GetLocale("SAVE_AND_APPLY"))
		modalDialogue.buttons[0].Resize(160,-1)
		modalDialogue.buttons[1].SetCaption(GetLocale("CANCEL"))
		modalDialogue.buttons[1].Resize(160,-1)
		modalDialogue.SetCaptionAndValue(GetLocale("MENU_SETTINGS"), "")

		local canvas:TGUIObject = modalDialogue.GetGuiContent()
				
		local labelTitleGameDefaults:TGUILabel = New TGUILabel.Create(new TPoint.Init(0, nextY), GetLocale("DEFAULTS_FOR_NEW_GAME"))
		labelTitleGameDefaults.SetFont(GetBitmapFont("default", 11, BOLDFONT))
		canvas.AddChild(labelTitleGameDefaults)
		nextY :+ 25

		local labelPlayerName:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("PLAYERNAME")+":")
		inputPlayerName = New TGUIInput.Create(new TPoint.Init(nextX, nextY + labelH), new TPoint.Init(inputWidth,-1), "", 128)
		canvas.AddChild(labelPlayerName)
		canvas.AddChild(inputPlayerName)
		inputH = inputPlayerName.GetScreenHeight()
		nextY :+ inputH + labelH * 1.5

		local labelChannelName:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("CHANNELNAME")+":")
		inputChannelName = New TGUIInput.Create(new TPoint.Init(nextX, nextY + labelH), new TPoint.Init(inputWidth,-1), "", 128)
		canvas.AddChild(labelChannelName)
		canvas.AddChild(inputChannelName)
		nextY :+ inputH + labelH * 1.5

		local labelStartYear:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("START_YEAR")+":")
		inputStartYear = New TGUIInput.Create(new TPoint.Init(nextX, nextY + labelH), new TPoint.Init(50,-1), "", 4)
		canvas.AddChild(labelStartYear)
		canvas.AddChild(inputStartYear)
		nextY :+ inputH + labelH * 1.5

		local labelStationmap:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("STATIONMAP")+":")
		inputStationmap = New TGUIDropDown.Create(new TPoint.Init(nextX, nextY + labelH), new TPoint.Init(inputWidth,-1), "germany.xml", 128)
		inputStationmap.disable()
		canvas.AddChild(labelStationmap)
		canvas.AddChild(inputStationmap)
		nextY :+ inputH + labelH * 1.5

		local labelDatabase:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("DATABASE")+":")
		inputDatabase = New TGUIDropDown.Create(new TPoint.Init(nextX, nextY + labelH), new TPoint.Init(inputWidth,-1), "database.xml", 128)
		inputDatabase.disable()
		canvas.AddChild(labelDatabase)
		canvas.AddChild(inputDatabase)
		nextY :+ inputH + labelH * 1.5


		nextY = 0
		nextX = 1*rowWidth
		'SOUND
		local labelTitleSound:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("SOUND_OUTPUT"))
		labelTitleSound.SetFont(GetBitmapFont("default", 11, BOLDFONT))
		canvas.AddChild(labelTitleSound)
		nextY :+ 25

		checkMusic = New TGUICheckbox.Create(new TPoint.Init(nextX, nextY), new TPoint.Init(checkboxWidth,-1), "")
		checkMusic.SetCaption(GetLocale("MUSIC"))
		canvas.AddChild(checkMusic)
		nextY :+ Max(inputH, checkMusic.GetScreenHeight())

		checkSfx = New TGUICheckbox.Create(new TPoint.Init(nextX, nextY), new TPoint.Init(checkboxWidth,-1), "")
		checkSfx.SetCaption(GetLocale("SFX"))
		canvas.AddChild(checkSfx)
		nextY :+ Max(inputH, checkSfx.GetScreenHeight())
		nextY :+ 15


		'GRAPHICS
		local labelTitleGraphics:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("GRAPHICS"))
		labelTitleGraphics.SetFont(GetBitmapFont("default", 11, BOLDFONT))
		canvas.AddChild(labelTitleGraphics)
		nextY :+ 25

		local labelRenderer:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("RENDERER") + ":")
		dropdownRenderer = New TGUIDropDown.Create(new TPoint.Init(nextX, nextY + 12), new TPoint.Init(inputWidth,-1), "", 128)
		local rendererValues:string[] = ["0", "3"]
		local rendererTexts:string[] = ["OpenGL", "Buffered OpenGL"]
		?Win32
			rendererValues :+ ["1","2"]
			rendererTexts :+ ["DirectX 7", "DirectX 9"]
		?
		local itemHeight:int = 0
		For local i:int = 0 until rendererValues.Length
			local item:TGUIDropDownItem = new TGUIDropDownItem.Create(null, null, rendererTexts[i])
			item.SetValueColor(TColor.CreateGrey(50))
			item.data.Add("value", rendererValues[i])
			dropdownRenderer.AddItem(item)
			if itemHeight = 0 then itemHeight = item.GetScreenHeight()
		Next
		dropdownRenderer.SetListContentHeight(itemHeight * Len(rendererValues))

		canvas.AddChild(labelRenderer)
		canvas.AddChild(dropdownRenderer)
'		GuiManager.SortLists()
		nextY :+ inputH + labelH * 1.5

		checkFullscreen = New TGUICheckbox.Create(new TPoint.Init(nextX, nextY), new TPoint.Init(checkboxWidth,-1), "")
		checkFullscreen.SetCaption(GetLocale("FULLSCREEN"))
		canvas.AddChild(checkFullscreen)
		nextY :+ Max(inputH, checkFullscreen.GetScreenHeight()) + labelH * 1.5


		'MULTIPLAYER
		nextY = 0
		nextX = 2*rowWidth
		local labelTitleMultiplayer:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("MULTIPLAYER"))
		labelTitleMultiplayer.SetFont(GetBitmapFont("default", 11, BOLDFONT))
		canvas.AddChild(labelTitleMultiplayer)
		nextY :+ 25

		local labelGameName:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("GAME_TITLE")+":")
		inputGameName = New TGUIInput.Create(new TPoint.Init(nextX, nextY + labelH), new TPoint.Init(inputWidth,-1), "", 128)
		canvas.AddChild(labelGameName)
		canvas.AddChild(inputGameName)
		nextY :+ inputH + labelH * 1.5

	
		local labelOnlinePort:TGUILabel = New TGUILabel.Create(new TPoint.Init(nextX, nextY), GetLocale("PORT_ONLINEGAME")+":")
		inputOnlinePort = New TGUIInput.Create(new TPoint.Init(nextX, nextY + 12), new TPoint.Init(50,-1), "", 4)
		canvas.AddChild(labelOnlinePort)
		canvas.AddChild(inputOnlinePort)
		nextY :+ inputH + 5

		'fill values
		SetGuiValues(App.config)

		return self
	End Method
End Type




Type GameEvents
	Function PlayersOnMinute:Int(triggerEvent:TEventBase)
		Local minute:Int = triggerEvent.GetData().getInt("minute",-1)
		If minute < 0 Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isAI() Then player.PlayerKI.CallOnMinute(minute)
		Next
		Return True
	End Function


	Function PlayersOnDay:Int(triggerEvent:TEventBase)
		Local minute:Int = triggerEvent.GetData().getInt("minute",-1)
		If minute < 0 Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isAI() Then player.PlayerKI.CallOnDayBegins()
		Next
		Return True
	End Function


	Function PlayerBroadcastMalfunction:Int(triggerEvent:TEventBase)
		local playerID:int = triggerEvent.GetData().GetInt("playerID", 0)
		local player:TPlayer = GetPlayerCollection().Get(playerID)
		if not player then return False

		If player.isAI() then player.PlayerKI.CallOnMalfunction()
	End Function


	Function PlayerFinanceOnChangeMoney:Int(triggerEvent:TEventBase)
		local playerID:int = triggerEvent.GetData().GetInt("playerID", 0)
		local player:TPlayer = GetPlayerCollection().Get(playerID)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		if playerID = -1 or not player then return FALSE

		If player.isAI() Then player.PlayerKI.CallOnMoneyChanged()
		If player.isActivePlayer() Then Interface.BottomImgDirty = True
	End Function


	'show an error if a transaction was not possible
	Function PlayerFinanceOnTransactionFailed:Int(triggerEvent:TEventBase)
		local playerID:int = triggerEvent.GetData().GetInt("playerID", 0)
		local player:TPlayer = GetPlayerCollection().Get(playerID)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		if playerID = -1 or not player then return FALSE

		'create an visual error
		If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
	End Function


	'called each time a room (the active player visits) is updated
	Function RoomOnUpdate:int(triggerEvent:TEventBase)
		'handle normal right click
		if MOUSEMANAGER.IsHit(2)
			'check subrooms
			'only leave a room if not in a subscreen
			'if in subscreen, go to parent one
			if ScreenCollection.GetCurrentScreen().parentScreen
				ScreenCollection.GoToParentScreen()
				MOUSEMANAGER.ResetKey(2)
			else
				'leaving prohibited - just reset button
				if not GetPlayerCollection().Get().figure.LeaveRoom()
					MOUSEMANAGER.resetKey(2)
				endif
			endif
		endif
	End Function

	Function StationMapOnTrySellLastStation:Int(triggerEvent:TEventBase)
		local playerID:int = triggerEvent.GetData().GetInt("playerID", 0)
		local player:TPlayer = GetPlayerCollection().Get(playerID)
		if playerID = -1 or not player then return FALSE

		'create an visual error
		If player.isActivePlayer() then TError.Create( getLocale("ERROR_NOT_POSSIBLE"), getLocale("ERROR_NOT_ABLE_TO_SELL_LAST_STATION") )
	End Function



	Function OnMinute:Int(triggerEvent:TEventBase)
		For local room:TRoom = eachin GetRoomCollection().list
			if room.occupants.count() > 0
				For local fig:TFigure = eachin room.occupants
					if fig.IsInBuilding() then THROW "FIGURE "+fig.name+" in room="+room.name 
				Next
			endif
		Next

	
		'things happening x:05
		Local minute:Int = triggerEvent.GetData().GetInt("minute",-1)
		Local hour:Int = triggerEvent.GetData().GetInt("hour",-1)
		Local day:Int = triggerEvent.GetData().GetInt("day",-1)
		If hour = -1 Then Return False

		'===== UPDATE POPULARITY MANAGER =====
		'the popularity manager takes care itself whether to do something
		'or not (update intervals)
		GetPopularityManager().Update(triggerEvent)

		'===== CHANGE OFFER OF MOVIEAGENCY AND ADAGENCY =====
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
				Game.refillAdAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				Game.refillAdAgencyTime = Game.refillAdAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling adagency", LOG_DEBUG)
				RoomHandler_adagency.GetInstance().ReFillBlocks(True, 0.5)
			EndIf
		EndIf


		'for all
		If minute = 5 Or minute = 55 Or minute = 0 Then Interface.BottomImgDirty = True

		'step 1/3
		'log in current broadcasted media
		For Local player:TPlayer = EachIn GetPlayerCollection().players
			player.GetProgrammePlan().LogInCurrentBroadcast(day, hour, minute)
		Next
		'step 2/3
		'calculate audience
		TPlayerProgrammePlan.CalculateCurrentBroadcastAudience(day, hour, minute)
		'step 3/3
		'inform broadcasted media about their status
		For Local player:TPlayer = EachIn GetPlayerCollection().players
			player.GetProgrammePlan().InformCurrentBroadcast(day, hour, minute)
		Next


		Return True
	End Function


	'things happening each hour
	Function OnHour:Int(triggerEvent:TEventBase)
		'
	End Function


	Function OnDay:Int(triggerEvent:TEventBase)
		Local day:Int = triggerEvent.GetData().GetInt("day", -1)

		'TLogger.Log("GameEvents.OnDay", "begin of day "+(GetGameTime().GetDaysPlayed()+1)+" (real day: "+day+")", LOG_DEBUG)

		'if new day, not start day
		If GetGameTime().GetDaysPlayed() >= 1

			'Neuer Award faellig?
			If Betty.GetAwardEnding() < GetGameTime().getDay() - 1
				Betty.GetLastAwardWinner()
				Betty.SetAwardType(RandRange(0, Betty.MaxAwardTypes), True)
			End If

			GetProgrammeDataCollection().RefreshTopicalities()
			GetAdContractBaseCollection().RefreshInfomercialTopicalities()
			Game.ComputeContractPenalties()
			Game.ComputeDailyCosts()	'first pay everything, then earn...
			Game.ComputeDailyIncome()
			TAuctionProgrammeBlocks.EndAllAuctions() 'won auctions moved to programmecollection of player

			'reset room signs each day to their normal position
			TRoomDoorSign.ResetPositions()

			'remove old news from the players (only unset ones)
			For Local i:Int = 1 To 4
				Local news:TNews
				For news = EachIn GetPlayerCollection().Get(i).GetProgrammeCollection().news
					If day - GetGameTime().getDay(news.newsEvent.happenedtime) >= 2
						GetPlayerCollection().Get(i).GetProgrammePlan().RemoveNews(news)
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
			GetBitmapFontManager().Add("headerFont", "res/fonts/Vera.ttf", 18)
			GetBitmapFontManager().Add("headerFont", "res/fonts/VeraBd.ttf", 18, BOLDFONT)
			GetBitmapFontManager().Add("headerFont", "res/fonts/VeraBI.ttf", 18, BOLDFONT | ITALICFONT)
			GetBitmapFontManager().Add("headerFont", "res/fonts/VeraIt.ttf", 18, ITALICFONT)

			Local shadowSettings:TData = new TData.addNumber("size", 1).addNumber("intensity", 0.5)
			Local gradientSettings:TData = new TData.addNumber("gradientBottom", 180)
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

			Global logoAnimStart:int = 0
			Global logoAnimTime:int = 1500
			Global logoScale:float = 0.0
			local logo:TSprite = GetSpriteFromRegistry("gfx_startscreen_logo")
			if logo
				local timeGone:int = Time.GetTimeGone()
				if logoAnimStart = 0 then logoAnimStart = timeGone
				logoScale = TInterpolation.BackOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)
				logoScale :* TInterpolation.BounceOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)

				local oldAlpha:float = GetAlpha()
				SetAlpha TInterpolation.RegularOut(0.0, 1.0, Min(0.5*logoAnimTime, timeGone - logoAnimStart), 0.5*logoAnimTime)

				logo.Draw( GraphicsWidth()/2, 150, -1, new TPoint.Init(0.5, 0.5), logoScale)
				SetAlpha oldAlpha
			Endif
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

	GetRegistry().Set("gfx_building_sign_0", new TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_base").GetColorizedImage(gray), "gfx_building_sign_0"))
	GetRegistry().Set("gfx_building_sign_dragged_0", new TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_dragged_base").GetColorizedImage(gray), "gfx_building_sign_dragged_0"))
	GetRegistry().Set("gfx_interface_channelbuttons_off_0", new TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_off").GetColorizedImage(gray2), "gfx_interface_channelbuttons_off_0"))
	GetRegistry().Set("gfx_interface_channelbuttons_on_0", new TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_on").GetColorizedImage(gray2), "gfx_interface_channelbuttons_on_0"))
	'colorizing for every player
	For Local i:Int = 1 To 4
		GetPlayerCollection().Get(i).RecolorFigure()
		local color:TColor = GetPlayerCollection().Get(i).color

		GetRegistry().Set("gfx_building_sign_"+i, new TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_base").GetColorizedImage(color), "gfx_building_sign_"+i))
		GetRegistry().Set("gfx_elevator_sign_"+i, new TSprite.InitFromImage(GetSpriteFromRegistry("gfx_elevator_sign_base").GetColorizedImage(color), "gfx_elevator_sign_"+i))
		GetRegistry().Set("gfx_elevator_sign_dragged_"+i, new TSprite.InitFromImage(GetSpriteFromRegistry("gfx_elevator_sign_dragged_base").GetColorizedImage(color), "gfx_elevator_sign_dragged_"+i))
		GetRegistry().Set("gfx_interface_channelbuttons_off_"+i, new TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_off").GetColorizedImage(color, i), "gfx_interface_channelbuttons_off_"+i))
		GetRegistry().Set("gfx_interface_channelbuttons_on_"+i, new TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_on").GetColorizedImage(color, i), "gfx_interface_channelbuttons_on_"+i))
	Next
End Function



Function DEV_switchRoom:int(room:TRoom)
	if not room then return FALSE
	local figure:TFigure = GetPlayerCollection().Get().figure

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




Function StartApp:int()
	'assign dev config (resources are now loaded)
	App.devConfig = TData(GetRegistry().Get("DEV_CONFIG", new TData))
	TFunctions.roundToBeautifulEnabled = App.devConfig.GetBool("DEV_ROUND_TO_BEAUTIFUL_VALUES", TRUE)
	if TFunctions.roundToBeautifulEnabled
		TLogger.Log("StartTVTower()", "DEV RoundToBeautiful is enabled", LOG_DEBUG | LOG_LOADING)
	else
		TLogger.Log("StartTVTower()", "DEV RoundToBeautiful is disabled", LOG_DEBUG | LOG_LOADING)
	endif

	Game.Create()


	MainMenuJanitor = New TFigureJanitor.Create("Hausmeister", GetSpriteFromRegistry("figure_Hausmeister"), 250, 2, 65)
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
End Function

Function ShowApp:int()
	'without creating players, rooms
	Game = TGame.GetInstance().Create(false, false)

	'Menu
	ScreenMainMenu = New TScreen_MainMenu.Create("MainMenu")
	ScreenCollection.Add(ScreenMainMenu)

	'go into the start menu
	Game.SetGamestate(TGame.STATE_MAINMENU)
End Function


Function StartTVTower(start:Int=true)
	DebugStop
	Global InitialResourceLoadingDone:int = FALSE

	EventManager.Init()
	
	App = TApp.Create(30, -1, TRUE) 'create with screen refreshrate and vsync
	App.LoadResources("config/resources.xml")

	'====
	'to avoid the "is loaded check" we have two loops
	'====

	'a) the mode before everything important was loaded
	ShowApp()
	Repeat
		'instead of only checking for resources in main loop
		'(happens eg. 30 times a second), check each update cycle
		RURC.Update()

		GetDeltaTimer().Loop()

		if RURC.FinishedLoading() then InitialResourceLoadingDone = true

		EventManager.update()
		'If RandRange(0,20) = 20 Then GCCollect()
	Until AppTerminate() Or TApp.ExitApp Or InitialResourceLoadingDone

	'=== ADJUST GUI FONTS ===
	'set the now available default font
	GuiManager.SetDefaultFont( GetBitmapFontManager().Get("Default", 12) )
	'buttons get a bold font
	TGUIButton.SetTypeFont( GetBitmapFontManager().baseFontBold )
	'checkbox (and their labels) get a smaller one
	'TGUICheckbox.SetTypeFont( GetBitmapFontManager().Get("Default", 11) )
	'labels get a slight smaller one
	'TGUILabel.SetTypeFont( GetBitmapFontManager().Get("Default", 11) )



	'b) everything loaded - normal game loop
	StartApp()
	Repeat
		GetDeltaTimer().Loop()

		'process events not directly triggered
		'process "onMinute" etc. -> App.OnUpdate, App.OnDraw ...
		EventManager.update()
		'If RandRange(0,20) = 20 Then GCCollect()
	Until AppTerminate() Or TApp.ExitApp

	'take care of network
	If Game.networkgame Then Network.DisconnectFromServer()
End Function