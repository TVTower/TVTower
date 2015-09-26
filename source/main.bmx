'Application: TVGigant/TVTower
'Author: Ronny Otto & Manuel Vögele

SuperStrict

Import Brl.Stream
Import Brl.Retro

Import brl.timer
Import brl.Graphics
Import brl.glmax2d
Import brl.eventqueue
Import "Dig/base.util.registry.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.registry.imageloader.bmx"
Import "Dig/base.util.registry.bitmapfontloader.bmx"
Import "Dig/base.util.registry.soundloader.bmx"
Import "Dig/base.util.registry.spriteentityloader.bmx"
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
Import "Dig/base.gfx.gui.window.modalchain.bmx"
Import "Dig/base.framework.tooltip.bmx"


Import "basefunctions_network.bmx"
Import "basefunctions.bmx"
Import "common.misc.screen.bmx"
Import "common.misc.dialogue.bmx"
Import "common.misc.gamelist.bmx"
Import "game.world.bmx"
Import "game.toastmessage.bmx"
Import "game.figure.base.bmx"

Import "game.gameinformation.bmx"

?Linux
'Import "external/bufferedglmax2d/bufferedglmax2d.bmx"
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
Import "game.building.bmx"
'Import "game.building.base.bmx"
'Import "game.building.elevator.bmx"
'needed by gamefunctions
Import "game.broadcastmaterial.programme.bmx"
'needed by game.player.bmx
Import "game.player.programmecollection.bmx"
'needed by game.player.bmx
Import "game.player.programmeplan.bmx"

Import "game.production.bmx"

Import "game.room.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.betty.bmx"
Import "game.ingameinterface.bmx"

Import "game.database.bmx"
Import "game.game.base.bmx"
Import "game.production.script.gui.bmx"
Import "game.production.shoppinglist.gui.bmx"


'===== Includes =====
Include "game.player.bmx"

'Types: - TError - Errorwindows with handling
'		- base class For buttons And extension newsbutton
Include "gamefunctions.bmx"

Include "gamefunctions_screens.bmx"
Include "gamefunctions_tvprogramme.bmx"  		'contains structures for TV-programme-data/Blocks and dnd-objects
Include "gamefunctions_rooms.bmx"				'basic roomtypes with handling
Include "gamefunctions_ki.bmx"					'LUA connection
Include "gamefunctions_sound.bmx"				'TVTower spezifische Sounddefinitionen
Include "gamefunctions_debug.bmx"
Include "gamefunctions_network.bmx"

Include "game.figure.bmx"
Include "game.newsagency.bmx"

Include "game.game.bmx"

Include "game.escapemenu.bmx"

'===== Globals =====
Global VersionDate:String = LoadText("incbin::source/version.txt")
Global VersionString:String = "v0.2.6-DEV Build ~q" + VersionDate+"~q"
Global CopyrightString:String = "by Ronny Otto & Manuel Vögele"
Global APP_NAME:string = "TVTower"
Global LOG_NAME:string = "log.profiler.txt"

Global App:TApp = Null
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
TLogger.Log("CORE", "Starting "+APP_NAME+", "+VersionString+".", LOG_INFO )

'===== SETUP LOGGER FILTER =====
TLogger.setLogMode(LOG_ALL)
TLogger.setPrintMode(LOG_ALL )
'TLogger.setPrintMode(LOG_AI | LOG_ERROR | LOG_SAVELOAD )

'print "ALLE MELDUNGEN AUS"
'TLogger.SetPrintMode(0)

'TLogger.setPrintMode(LOG_ALL &~ LOG_AI ) 'all but ai
'THIS IS TO REMOVE CLUTTER FOR NON-DEVS
'@MANUEL: comment out when doing DEV to see LOG_DEV-messages
'TLogger.changePrintMode(LOG_DEV, FALSE)
'TLogger.changePrintMode(LOG_ERROR | LOG_DEV | LOG_AI, True)



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
	Field creationTime:Int
	'store listener for music loaded in "startup"
	Field OnLoadMusicListener:TLink

	'able to draw loading screen?
	Global baseResourcesLoaded:Int = 0
	'holds bg for loading screen and more
	Global baseResourceXmlUrl:String = "config/startup.xml"
	'boolean value: 1 and the game will exit
	Global ExitApp:Int = 0
	Global ExitAppDialogue:TGUIModalWindow = Null
	'creation time for "double escape" to abort
	Global ExitAppDialogueTime:Int = 0
	'Global ExitAppDialogueEventListeners:TLink = TLink[]
	Global EscapeMenuWindow:TGUIModalWindowChain = Null
	'creation time for "double escape" to abort
	Global EscapeMenuWindowTime:Int = 0
	'Global EscapeMenuWindowEventListeners:TLink[]

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
			EventManager.registerListenerFunction( "guiModalWindow.onClose", onAppConfirmExit )
			EventManager.registerListenerFunction( "guiModalWindowChain.onClose", onCloseEscapeMenu )
			EventManager.registerListenerFunction( "RegistryLoader.onLoadXmlFromFinished",	TApp.onLoadXmlFromFinished )
			obj.OnLoadMusicListener = EventManager.registerListenerFunction( "RegistryLoader.onLoadResource",	TApp.onLoadMusicResource )
	
			obj.LoadSettings()
			obj.ApplySettings()
			'override settings with app arguments (params when executing)
			obj.ApplyAppArguments()
	
			GetGraphicsManager().SetVsync(vsync)
			GetGraphicsManager().SetResolution(800,600)
			'GetGraphicsManager().SetResolution(1024,768)
			GetGraphicsManager().SetDesignedResolution(800,600)
			GetGraphicsManager().InitGraphics()
			
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
				Case "-directx9"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 9", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX9)
				?
				Case "-opengl"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: OpenGL", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_OPENGL)
				Case "-bufferedopengl"
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

		if TGame._instance Then GetGame().LoadConfig(config)
	End Method


	Method LoadResources:Int(path:String="config/resources.xml", directLoad:Int=False)
		Local registryLoader:TRegistryLoader = New TRegistryLoader
		registryLoader.LoadFromXML(path, directLoad)
	End Method


	Method SetLanguage:Int(languageCode:String="de")
		Local oldLang:String = TLocalization.GetCurrentLanguageCode()
		'select language
		TLocalization.SetCurrentLanguage(languageCode)
		TLocalizedString.SetCurrentLanguage(languageCode)

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

		Local img:TPixmap = VirtualGrabPixmap(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())

		'add overlay
		If overlay Then overlay.DrawOnImage(img, GetGraphicsManager().GetWidth() - overlay.GetWidth() - 10, 10, -1, Null, TColor.Create(255,255,255,0.5))

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

		GUIManager.Update("SYSTEM")

		'=== UPDATE TOASTMESSAGES ===
		GetToastMessageCollection().Update()


		'as long as the exit dialogue is open, do not accept clicks to
		'non gui elements (eg. to leave rooms)
		If App.ExitAppDialogue or App.EscapeMenuWindow
			MouseManager.ResetKey(2)

			'this sets all IsClicked(), IsHit() to False
			MouseManager.Disable(1)
			MouseManager.Disable(2)
		EndIf

		'ignore shortcuts if a gui object listens to keystrokes
		'eg. the active chat input field
		If Not GUIManager.GetKeystrokeReceiver()
			If GameRules.devConfig.GetBool("DEV_KEYS", False)
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

				If GetGame().gamestate = TGame.STATE_RUNNING
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

					If KEYMANAGER.IsHit(KEY_F)
						If KEYMANAGER.IsDown(KEY_LSHIFT) or KEYMANAGER.IsDown(KEY_RSHIFT)
							local text:string[] = GetPlayerFinanceOverviewText( GetWorldTime().GetOnDay() )
							For local s:string = EachIn text
								print s
							Next
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
							print ".---------------------------------.------------------.---------.----------.----------.-------."
							print "| Name                            | Audience       % |  Image  |  Profit  |  Penalty | Spots |"
							print "|---------------------------------+------------------+---------+----------+----------|-------|"

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
								local targetGroup:String = ""
								if ad.GetLimitedToTargetGroup() > 0
									targetGroup = "* "+ getLocale("AD_TARGETGROUP")+": "+ad.GetLimitedToTargetGroupString()
									title :+ "*"
								else
									title :+ " "
								endif
								print "| "+title + " | " + audience + " | " + image + " | " + profit + " | " + penalty + " | " + spots+" |" + targetgroup
								
							Next
							print "'---------------------------------'------------------'---------'----------'----------'-------'"
						endif
					endif
					

					If KEYMANAGER.IsHit(KEY_Y)
'TLocalization.PrintCurrentTranslationState()					
						'print "send to chef:"
						'GetPlayer().SendToBoss()

						'GetWorld().Weather.SetPressure(-14)
						'GetWorld().Weather.SetTemperature(-10)

						'send marshal to confiscate the licence
						'local licence:TProgrammeLicence = GetPlayer().GetProgrammeCollection().GetRandomMovieLicence()
						'GetGame().marshals[rand(0,1)].AddConfiscationJob( licence.GetGUID() )

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

'						RoomHandler_MovieAgency.GetInstance().RefillBlocks(true, 0.9)


'dubletten
local duplicateCount:int = 0
local arr:TProgrammeLicence[] = TProgrammeLicence[] (GetProgrammeLicenceCollection().licences.ToArray())
For local i:int = 0 to arr.length -1
	
	For local j:int = 0 to arr.length -1
		if j = i then continue
		if arr[i] = arr[j]
			print "found duplicate: "+arr[i].GetTitle()
			duplicateCount :+ 1
			continue
		endif

		if arr[i].GetGUID() = arr[j].GetGUID()
			print "found GUID duplicate: "+arr[i].GetTitle()
			duplicateCount :+ 1
			continue
		endif


		if arr[i].GetTitle() <> "Die Streichholzhammerbowle"
			if arr[i].GetTitle() = arr[j].GetTitle()
				print "found TITLE duplicate: "+arr[i].GetTitle()
				duplicateCount :+ 1
				continue
			endif
		endif
	Next
Next
'print "COLLECTION DUPLICATE: "+duplicateCount+"      " + millisecs()

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

rem
local news:TNewsEvent = GetNewsEventCollection().GetByGUID("ronny-news-sandsturm-01")
GetNewsAgency().announceNewsEvent(news, 0, False)
print "happen: "+ news.GetTitle() + "  at: "+GetWorldTime().GetformattedTime(news.happenedTime)
endrem

local m:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID("TheRob-b0db-439c-a852-Goaaaaal")
m.SetOwner(0)
RoomHandler_MovieAgency.GetInstance().SellProgrammeLicenceToPlayer(m, 1)
print "added Goaaal to player1's suitcase"
					EndIf

				
					If Not GetPlayer().GetFigure().isChangingRoom()
						If KEYMANAGER.IsHit(KEY_1) Then GetGame().SetActivePlayer(1)
						If KEYMANAGER.IsHit(KEY_2) Then GetGame().SetActivePlayer(2)
						If KEYMANAGER.IsHit(KEY_3) Then GetGame().SetActivePlayer(3)
						If KEYMANAGER.IsHit(KEY_4) Then GetGame().SetActivePlayer(4)

						If KEYMANAGER.IsHit(KEY_W)
							if not KEYMANAGER.IsDown(KEY_LSHIFT) and not KEYMANAGER.IsDown(KEY_RSHIFT)
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("adagency") )
							endif
						endif
						If KEYMANAGER.IsHit(KEY_A) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("archive", GetPlayerCollection().playerID) )
						If KEYMANAGER.IsHit(KEY_B) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("betty") )
						If KEYMANAGER.IsHit(KEY_F)
							if not KEYMANAGER.IsDown(KEY_LSHIFT) and not KEYMANAGER.IsDown(KEY_RSHIFT)
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("movieagency"))
							endif
						endif
						If KEYMANAGER.IsHit(KEY_O) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("office", GetPlayerCollection().playerID))
						If KEYMANAGER.IsHit(KEY_C) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("boss", GetPlayerCollection().playerID))
						If KEYMANAGER.IsHit(KEY_G) Then TVTGhostBuildingScrollMode = 1 - TVTGhostBuildingScrollMode
						If KEYMANAGER.IsHit(KEY_D)
							If KEYMANAGER.IsDown(KEY_RSHIFT)
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("studio", 2))
							Else If KEYMANAGER.IsDown(KEY_LSHIFT)
								'go to first studio of the player
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("studio", GetPlayerCollection().playerID))
							Else
								DEV_switchRoom(GetRoomCollection().GetFirstByDetails("scriptagency"))
							EndIf
						EndIf
						
						'e wie "employees" :D
						If KEYMANAGER.IsHit(KEY_E) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("credits"))
						If KEYMANAGER.IsHit(KEY_N) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("news", GetPlayerCollection().playerID))
						If KEYMANAGER.IsHit(KEY_R) Then DEV_switchRoom(GetRoomCollection().GetFirstByDetails("roomboard"))
					EndIf
				EndIf
				If KEYMANAGER.IsHit(KEY_5) Then GetWorldTime().SetTimeFactor(60*60.0)  '60 virtual minutes per realtime second
				If KEYMANAGER.IsHit(KEY_6) Then GetWorldTime().SetTimeFactor(120*60.0) '120 minutes per second
				If KEYMANAGER.IsHit(KEY_7) Then GetWorldTime().SetTimeFactor(180*60.0) '180 minutes per second
				If KEYMANAGER.IsHit(KEY_8) Then GetWorldTime().SetTimeFactor(240*60.0) '240 minute per second
				If KEYMANAGER.IsHit(KEY_9) Then GetWorldTime().SetTimeFactor(1*60.0)   '1 minute per second
				If KEYMANAGER.IsHit(KEY_Q) Then TVTDebugQuoteInfos = 1 - TVTDebugQuoteInfos

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
					else
						GetPlayer().GetProgrammePlan().printOverview()
					endif
				endif

				'Save game only when in a game
				If GetGame().gamestate = TGame.STATE_RUNNING
					If KEYMANAGER.IsHit(KEY_S) Then TSaveGame.Save("savegames/quicksave.xml")
				EndIf

				If KEYMANAGER.IsHit(KEY_L)
					TSaveGame.Load("savegames/quicksave.xml")
				endif

				If KEYMANAGER.IsHit(KEY_TAB) Then TVTDebugInfos = 1 - TVTDebugInfos

				If KEYMANAGER.Ishit(KEY_K)
					TLogger.Log("KickAllFromRooms", "Player kicks all figures out of the rooms.", LOG_DEBUG)
					For Local fig:TFigure = EachIn GetFigureCollection().entries.Values()
						If fig.inRoom Then GetPlayer().GetFigure().KickFigureFromRoom(fig, fig.inroom)
					Next
				EndIf

				'send terrorist to a random room
				If KEYMANAGER.IsHit(KEY_T) And Not GetGame().networkGame
					Global whichTerrorist:Int = 1
					whichTerrorist = 1 - whichTerrorist

					Local targetRoom:TRoom
					Repeat
						targetRoom = GetRoomCollection().GetRandom()
					Until targetRoom.name <> "building"
					print "deliver to : "+targetRoom.name
					TFigureTerrorist(GetGame().terrorists[whichTerrorist]).SetDeliverToRoom( targetRoom )
				EndIf

				If GetGame().isGameLeader()
					If KEYMANAGER.Ishit(Key_F1) And GetPlayer(1).isLocalAI() Then GetPlayer(1).PlayerAI.reloadScript()
					If KEYMANAGER.Ishit(Key_F2) And GetPlayer(2).isLocalAI() Then GetPlayer(2).PlayerAI.reloadScript()
					If KEYMANAGER.Ishit(Key_F3) And GetPlayer(3).isLocalAI() Then GetPlayer(3).PlayerAI.reloadScript()
					If KEYMANAGER.Ishit(Key_F4) And GetPlayer(4).isLocalAI() Then GetPlayer(4).PlayerAI.reloadScript()
				EndIf

				'only announce news in single player mode - as announces
				'are done on all clients on their own.
				If KEYMANAGER.Ishit(Key_F5) And Not GetGame().networkGame Then GetNewsAgency().AnnounceNewNewsEvent()

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
						For Local fig:TFigure = EachIn GetFigureCollection().entries.Values()
							If GetPlayerBase().GetFigure() <> fig Then fig.moveable = False
						Next
						TLogger.Log("CORE", "AI Figures deactivated", LOG_INFO | LOG_DEV )
						KIRunning = False
					Else
						For Local fig:TFigure = EachIn GetFigureCollection().entries.Values()
							If GetPlayerBase().GetFigure() <> fig Then fig.moveable = True
						Next
						TLogger.Log("CORE", "AI activated", LOG_INFO | LOG_DEV )
						KIRunning = True
					EndIf
				EndIf
			EndIf
		EndIf


		TError.UpdateErrors()
		GetGame().cursorstate = 0

		ScreenCollection.UpdateCurrent(GetDeltaTimer().GetDelta())
	
		If Not GuiManager.GetKeystrokeReceiver() And KEYWRAPPER.hitKey(KEY_ESCAPE)
			'ask to exit to main menu
			'TApp.CreateConfirmExitAppDialogue(True)
			If GetGame().gamestate = TGame.STATE_RUNNING
				'TApp.CreateConfirmExitAppDialogue(True)
				'create escape-menu
				TApp.CreateEscapeMenuwindow()
			else
				'ask to exit the app - from main menu?
				'TApp.CreateConfirmExitAppDialogue(False)
			endif
		EndIf
		If AppTerminate() and not TApp.ExitAppDialogue
			'ask to exit the app
			TApp.CreateConfirmExitAppDialogue(False)
		endif

		'check if we need to make a screenshot
		If KEYMANAGER.IsHit(KEY_F12) Then App.prepareScreenshot = 1

		If GetGame().networkGame Then Network.Update()

		GUIManager.EndUpdates() 'reset modal window states

		TProfiler.Leave("Update")
	End Function




	Function Render:Int()
		'cls only needed if virtual resolution is enabled, else the
		'background covers everything
		If GetGraphicsManager().HasBlackBars()
			Cls()
'			GetGraphicsManager().SetViewPort(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		Endif

		TProfiler.Enter("Draw")
		ScreenCollection.DrawCurrent(GetDeltaTimer().GetTween())

		'=== RENDER TOASTMESSAGES ===
		'below everything else of the interface: our toastmessages
		GetToastMessageCollection().Render(0,0)


'		SetBlend AlphaBlend
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

			If GetGame().networkgame And Network.client
				GetBitmapFontManager().baseFont.draw("Ping: "+Int(Network.client.latency)+"ms", textX,0)
				textX:+50
			EndIf
		EndIf

		If GetGame().gamestate = TGame.STATE_RUNNING
			if TVTDebugInfos 'And Not GetPlayer().GetFigure().inRoom
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
							change = " <<" 'Chr(8646) '⇆
						else
							change = " >>" 'Chr(8646) '⇆
						endif
					endif

					roomName = "Building"
					If fig.inRoom
						roomName = fig.inRoom.Name
					ElseIf fig.IsInElevator()
						roomName = "InElevator"
					ElseIf fig.IsAtElevator()
						roomName = "AtElevator"
					EndIf
					GetBitmapFontManager().baseFont.draw("P " + (i + 1) + ": "+roomName+change, 5, 70 + i * 11)
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


				GetWorld().RenderDebug(660,0, 140, 160)
				'GetPlayer().GetFigure().RenderDebug(new TVec2D.Init(660, 150))
			EndIf
			'show quotes even without "DEV_OSD = true"
			If TVTDebugQuoteInfos Then debugAudienceInfos.Draw()
		endif

		'draw loading resource information
		RenderLoadingResourcesInformation()


		'draw system things at last (-> on top)
		GUIManager.Draw("SYSTEM")

		'default pointer
		If GetGame().cursorstate = 0 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-9, 	MouseManager.y-2	,0)
		'open hand
		If GetGame().cursorstate = 1 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11, 	MouseManager.y-8	,1)
		'grabbing hand
		If GetGame().cursorstate = 2 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11,	MouseManager.y-16	,2)
		'open hand blocked
		If GetGame().cursorstate = 3 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11,	MouseManager.y-8	,3)

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
		EscapeMenuWindowTime = MilliSecs()

		'not interested in other windows
		If window <> EscapeMenuWindow Then Return False

		'remove connection to global value (guimanager takes care of fading)
		TApp.EscapeMenuWindow = Null

		'in single player: resume game
		If TGame._instance And Not GetGame().networkgame
			'only unpause if there is no exit-dialogue open
			if not TApp.ExitAppDialogue then GetGame().SetPaused(False)
		Endif

		Return True
	End Function



	Function CreateEscapeMenuwindow:Int()
		'100ms since last window
		If MilliSecs() - EscapeMenuWindowTime < 100 Then Return False

		EscapeMenuWindowTime = MilliSecs()
		'in single player: pause game
		If TGame._instance And Not GetGame().networkgame Then GetGame().SetPaused(True)

		TGUISavegameListItem.SetTypeFont(GetBitmapFont(""))

		EscapeMenuWindow = New TGUIModalWindowChain.Create(New TVec2D, New TVec2D.Init(400,150), "SYSTEM")
		EscapeMenuWindow.SetZIndex(99000)
		EscapeMenuWindow.SetCenterLimit(new TRectangle.setTLBR(30,0,0,0))
		EscapeMenuWindow.Open()

		'append menu after creation of screen ares, so it recenters properly
		local mainMenu:TGUIModalMainMenu = New TGUIModalMainMenu.Create(New TVec2D, New TVec2D.Init(300,305), "SYSTEM")
		EscapeMenuWindow.SetContentElement(mainMenu)

		'menu is always ingame...
		EscapeMenuWindow.SetDarkenedArea(New TRectangle.Init(0,0,800,385))
		'center to this area
		EscapeMenuWindow.SetScreenArea(New TRectangle.Init(0,0,800,385))
	End Function
	

	Function onAppConfirmExit:Int(triggerEvent:TEventBase)
		Local dialogue:TGUIModalWindow = TGUIModalWindow(triggerEvent.GetSender())
		If Not dialogue Then Return False

		'store closing time of this modal window (does not matter which
		'one) to skip creating another exit dialogue within a certain
		'timeframe
		ExitAppDialogueTime = MilliSecs()

		'not interested in other dialogues
		If dialogue <> ExitAppDialogue Then Return False


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

		'in single player: resume game
		If TGame._instance And Not GetGame().networkgame
			'only unpause if there is no escape-menu open
			if not TApp.EscapeMenuWindow then GetGame().SetPaused(False)
		Endif

		Return True
	End Function


	Function CreateConfirmExitAppDialogue:Int(quitToMainMenu:int=True)
		'100ms since last dialogue
		If MilliSecs() - ExitAppDialogueTime < 100 Then Return False

		ExitAppDialogueTime = MilliSecs()
		'in single player: pause game
		If TGame._instance And Not GetGame().networkgame Then GetGame().SetPaused(True)

		ExitAppDialogue = New TGUIGameModalWindow.Create(New TVec2D, New TVec2D.Init(400,150), "SYSTEM")
		ExitAppDialogue.SetDialogueType(2)
		ExitAppDialogue.SetZIndex(100000)
		ExitAppDialogue.data.AddNumber("quitToMainMenu", quitToMainMenu)
		ExitAppDialogue.Open()

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
	Field _WorldTime:TWorldTime = Null
	Field _World:TWorld = Null
	Field _GameRules:TGamerules = Null
	Field _Betty:TBetty = Null

	Field _GameInformationCollection:TGameInformationCollection = Null

	Field _AudienceManager:TAudienceManager = Null
	Field _AdContractBaseCollection:TAdContractBaseCollection = Null
	Field _AdContractCollection:TAdContractCollection = Null

	Field _ScriptTemplateCollection:TScriptTemplateCollection = Null
	Field _ScriptCollection:TScriptCollection = Null
	Field _ProgrammeRoleCollection:TProgrammeRoleCollection = Null
	Field _ProgrammePersonBaseCollection:TProgrammePersonBaseCollection = Null
	Field _ProgrammeDataCollection:TProgrammeDataCollection = Null
	Field _ProgrammeLicenceCollection:TProgrammeLicenceCollection = Null

	Field _NewsEventCollection:TNewsEventCollection = Null
	Field _FigureCollection:TFigureCollection = Null
	Field _PlayerCollection:TPlayerCollection = Null
	Field _PlayerFinanceCollection:TPlayerFinanceCollection = Null
	Field _PlayerFinanceHistoryListCollection:TPlayerFinanceHistoryListCollection = Null
	Field _PlayerProgrammePlanCollection:TPlayerProgrammePlanCollection = Null
	Field _PlayerProgrammeCollectionCollection:TPlayerProgrammeCollectionCollection = Null
	Field _PlayerBossCollection:TPlayerBossCollection = Null
	Field _PublicImageCollection:TPublicImageCollection = Null
	Field _EventManagerEvents:TList = Null
	Field _PopularityManager:TPopularityManager = Null
	Field _BroadcastManager:TBroadcastManager = Null
	Field _DailyBroadcastStatisticCollection:TDailyBroadcastStatisticCollection = Null
	Field _StationMapCollection:TStationMapCollection = Null
	Field _Elevator:TElevator
	Field _Building:TBuilding 'includes, sky, moon, ufo
	Field _RoomBoard:TRoomBoard 'signs	
	Field _NewsAgency:TNewsAgency
	Field _AuctionProgrammeBlocksList:TList
	Field _RoomHandler_Studio:RoomHandler_Studio
	Field _RoomHandler_MovieAgency:RoomHandler_MovieAgency
	Field _RoomHandler_AdAgency:RoomHandler_AdAgency
	Field _RoomDoorBaseCollection:TRoomDoorBaseCollection
	Field _RoomBaseCollection:TRoomBaseCollection
	Field _PlayerColorList:TList
	Field _CurrentScreenName:String
	Const MODE_LOAD:Int = 0
	Const MODE_SAVE:Int = 1


	Method Initialize:Int()
print "TGameState.Initialize(): Reinitialize all game objects"
		TLogger.Log("TGameState.Initialize()", "Reinitialize all game objects", LOG_DEBUG)

		'reset player colors
		TPlayerColor.Initialize()
		GetRoomDoorBaseCollection().Initialize()
		GetRoomBaseCollection().Initialize()
		GetStationMapCollection().InitializeAll()
		GetPopularityManager().Initialize()

		AudienceManager.Initialize()

		GetAdContractBaseCollection().Initialize()
		GetAdContractCollection().Initialize()
		GetScriptTemplateCollection().Initialize()
		GetScriptCollection().Initialize()
		GetProgrammeRoleCollection().Initialize()
		GetProgrammePersonBaseCollection().Initialize()
		GetProgrammeDataCollection().Initialize()
		GetProgrammeLicenceCollection().Initialize()
		TAuctionProgrammeBlocks.Initialize()
		GetNewsEventCollection().Initialize()

		GetDailyBroadcastStatisticCollection().Initialize()
		GetFigureCollection().Initialize()
		GetNewsAgency().Initialize()
		GetPublicImageCollection().Initialize()
		GetBroadcastManager().Initialize()

		GetElevator().Initialize()
		GetBuilding().Initialize()
		GetRoomBoard().Initialize()
		GetWorldTime().Initialize()
		GetWorld().Initialize()
		GetGame().Initialize()

		GetPlayerProgrammeCollectionCollection().InitializeAll()
		GetPlayerProgrammePlanCollection().InitializeAll()
		GetPlayerCollection().Initialize()
		GetPlayerFinanceCollection().Initialize()
		GetPlayerFinanceHistoryListCollection().Initialize()

		GetBetty().Initialize()

		'initialize known room handlers + event registration
		GetRoomHandlerCollection().Initialize()
	End Method


	Method RestoreGameData:Int()
print "TGameState.RestoreGameData(): Restore game objects"
		_Assign(_FigureCollection, TFigureCollection._instance, "FigureCollection", MODE_LOAD)
		_Assign(_RoomDoorBaseCollection, TRoomDoorBaseCollection._instance, "RoomDoorBaseCollection", MODE_LOAD)
		_Assign(_RoomBaseCollection, TRoomBaseCollection._instance, "RoomBaseCollection", MODE_LOAD)

		_Assign(_PlayerColorList, TPlayerColor.List, "PlayerColorList", MODE_LOAD)
		_Assign(_GameInformationCollection, TGameInformationCollection._instance, "GameInformationCollection", MODE_LOAD)

		_Assign(_AudienceManager, AudienceManager, "AudienceManager", MODE_LOAD)

		_Assign(_AdContractCollection, TAdContractCollection._instance, "AdContractCollection", MODE_LOAD)
		_Assign(_AdContractBaseCollection, TAdContractBaseCollection._instance, "AdContractBaseCollection", MODE_LOAD)


		_Assign(_ScriptTemplateCollection, TScriptTemplateCollection._instance, "ScriptTemplateCollection", MODE_LOAD)
		_Assign(_ScriptCollection, TScriptCollection._instance, "ScriptCollection", MODE_LOAD)
		_Assign(_ProgrammeRoleCollection, TProgrammeRoleCollection._instance, "ProgrammeRoleCollection", MODE_LOAD)
		_Assign(_ProgrammePersonBaseCollection, TProgrammePersonBaseCollection._instance, "ProgrammePersonBaseCollection", MODE_LOAD)
		_Assign(_ProgrammeDataCollection, TProgrammeDataCollection._instance, "ProgrammeDataCollection", MODE_LOAD)
		_Assign(_ProgrammeLicenceCollection, TProgrammeLicenceCollection._instance, "ProgrammeLicenceCollection", MODE_LOAD)

		_Assign(_PlayerCollection, TPlayerCollection._instance, "PlayerCollection", MODE_LOAD)
		_Assign(_PlayerFinanceCollection, TPlayerFinanceCollection._instance, "PlayerFinanceCollection", MODE_LOAD)
		_Assign(_PlayerFinanceHistoryListCollection, TPlayerFinanceHistoryListCollection._instance, "PlayerFinanceHistoryListCollection", MODE_LOAD)
		_Assign(_PlayerProgrammeCollectionCollection, TPlayerProgrammeCollectionCollection._instance, "PlayerProgrammeCollectionCollection", MODE_LOAD)
		_Assign(_PlayerProgrammePlanCollection, TPlayerProgrammePlanCollection._instance, "PlayerProgrammePlanCollection", MODE_LOAD)
		_Assign(_PlayerBossCollection, TPlayerBossCollection._instance, "PlayerBossCollection", MODE_LOAD)
		_Assign(_PublicImageCollection, TPublicImageCollection._instance, "PublicImageCollection", MODE_LOAD)

		_Assign(_NewsEventCollection, TNewsEventCollection._instance, "NewsEventCollection", MODE_LOAD)
		_Assign(_NewsAgency, TNewsAgency._instance, "NewsAgency", MODE_LOAD)
		_Assign(_Building, TBuilding._instance, "Building", MODE_LOAD)
		_Assign(_Elevator, TElevator._instance, "Elevator", MODE_LOAD)
		_Assign(_RoomBoard, TRoomBoard._instance, "RoomBoard", MODE_LOAD)
		_Assign(_EventManagerEvents, EventManager._events, "Events", MODE_LOAD)
		_Assign(_PopularityManager, TPopularityManager._instance, "PopularityManager", MODE_LOAD)
		_Assign(_BroadcastManager, TBroadcastManager._instance, "BroadcastManager", MODE_LOAD)
		_Assign(_DailyBroadcastStatisticCollection, TDailyBroadcastStatisticCollection._instance, "DailyBroadcastStatisticCollection", MODE_LOAD)
		_Assign(_StationMapCollection, TStationMapCollection._instance, "StationMapCollection", MODE_LOAD)
		_Assign(_Betty, TBetty._instance, "Betty", MODE_LOAD)
		_Assign(_World, TWorld._instance, "World", MODE_LOAD)
		_Assign(_WorldTime, TWorldTime._instance, "WorldTime", MODE_LOAD)
		_Assign(_GameRules, GameRules, "GameRules", MODE_LOAD)
		_Assign(_AuctionProgrammeBlocksList, TAuctionProgrammeBlocks.list, "AuctionProgrammeBlocks", MODE_LOAD)

		_Assign(_RoomHandler_Studio, RoomHandler_Studio._instance, "Studios", MODE_LOAD)
		_Assign(_RoomHandler_MovieAgency, RoomHandler_MovieAgency._instance, "MovieAgency", MODE_LOAD)
		_Assign(_RoomHandler_AdAgency, RoomHandler_AdAgency._instance, "AdAgency", MODE_LOAD)
		_Assign(_Game, TGame._instance, "Game")
	End Method


	Method BackupGameData:Int()
		'start with the most basic data, so we avoid that these basic
		'objects get serialized in the depths of more complex objects
		'instead of getting an "reference" there.
		
	
		'name of the current screen (or base screen)
		_CurrentScreenName = ScreenCollection.GetCurrentScreen().name

		_Assign(GameRules, _GameRules, "GameRules", MODE_SAVE)
		_Assign(TWorldTime._instance, _WorldTime, "WorldTime", MODE_SAVE)

		'database data for contracts
		_Assign(TAdContractBaseCollection._instance, _AdContractBaseCollection, "AdContractBaseCollection", MODE_SAVE)
		_Assign(TAdContractCollection._instance, _AdContractCollection, "AdContractCollection", MODE_SAVE)
		'database data for scripts
		_Assign(TScriptTemplateCollection._instance, _ScriptTemplateCollection, "ScriptTemplateCollection", MODE_SAVE)
		_Assign(TScriptCollection._instance, _ScriptCollection, "ScriptCollection", MODE_SAVE)
		'database data for persons and their roles
		_Assign(TProgrammePersonBaseCollection._instance, _ProgrammePersonBaseCollection, "ProgrammePersonBaseCollection", MODE_SAVE)
		_Assign(TProgrammeRoleCollection._instance, _ProgrammeRoleCollection, "ProgrammeRoleCollection", MODE_SAVE)

		'database data for programmes
		_Assign(TProgrammeDataCollection._instance, _ProgrammeDataCollection, "ProgrammeDataCollection", MODE_SAVE)
		_Assign(TProgrammeLicenceCollection._instance, _ProgrammeLicenceCollection, "ProgrammeLicenceCollection", MODE_SAVE)

		_Assign(TPlayerColor.List, _PlayerColorList, "PlayerColorList", MODE_SAVE)
		_Assign(TGameInformationCollection._instance, _GameInformationCollection, "GameInformationCollection", MODE_SAVE)

		_Assign(AudienceManager, _AudienceManager, "AudienceManager", MODE_SAVE)

		_Assign(TBuilding._instance, _Building, "Building", MODE_SAVE)
		_Assign(TElevator._instance, _Elevator, "Elevator", MODE_SAVE)
		_Assign(TRoomBoard._instance, _RoomBoard, "RoomBoard", MODE_SAVE)
		_Assign(TRoomBaseCollection._instance, _RoomBaseCollection, "RoomBaseCollection", MODE_SAVE)
		_Assign(TRoomDoorBaseCollection._instance, _RoomDoorBaseCollection, "RoomDoorBaseCollection", MODE_SAVE)
		_Assign(TFigureCollection._instance, _FigureCollection, "FigureCollection", MODE_SAVE)
		_Assign(TPlayerCollection._instance, _PlayerCollection, "PlayerCollection", MODE_SAVE)
		_Assign(TPlayerFinanceCollection._instance, _PlayerFinanceCollection, "PlayerFinanceCollection", MODE_SAVE)
		_Assign(TPlayerFinanceHistoryListCollection._instance, _PlayerFinanceHistoryListCollection, "PlayerFinanceHistoryListCollection", MODE_SAVE)
		_Assign(TPlayerProgrammeCollectionCollection._instance, _PlayerProgrammeCollectionCollection, "PlayerProgrammeCollectionCollection", MODE_SAVE)
		_Assign(TPlayerProgrammePlanCollection._instance, _PlayerProgrammePlanCollection, "PlayerProgrammePlanCollection", MODE_SAVE)
		_Assign(TPlayerBossCollection._instance, _PlayerBossCollection, "PlayerBossCollection", MODE_SAVE)
		_Assign(TPublicImageCollection._instance, _PublicImageCollection, "PublicImageCollection", MODE_SAVE)

		_Assign(TGame._instance, _Game, "Game", MODE_SAVE)


		_Assign(TNewsEventCollection._instance, _NewsEventCollection, "NewsEventCollection", MODE_SAVE)
		_Assign(TNewsAgency._instance, _NewsAgency, "NewsAgency", MODE_SAVE)
		_Assign(EventManager._events, _EventManagerEvents, "Events", MODE_SAVE)
		_Assign(TPopularityManager._instance, _PopularityManager, "PopularityManager", MODE_SAVE)
		_Assign(TBroadcastManager._instance, _BroadcastManager, "BroadcastManager", MODE_SAVE)
		_Assign(TDailyBroadcastStatisticCollection._instance, _DailyBroadcastStatisticCollection, "DailyBroadcastStatisticCollection", MODE_SAVE)
		_Assign(TStationMapCollection._instance, _StationMapCollection, "StationMapCollection", MODE_SAVE)
		_Assign(TBetty._instance, _Betty, "Betty", MODE_SAVE)
		_Assign(TWorld._instance, _World, "World", MODE_SAVE)
		_Assign(TAuctionProgrammeBlocks.list, _AuctionProgrammeBlocksList, "AuctionProgrammeBlocks", MODE_Save)
		'special room data
		_Assign(RoomHandler_Studio._instance, _RoomHandler_Studio, "Studios", MODE_Save)
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



Type TSaveGame Extends TGameState
	'store the time gone since when the app started - timers rely on this
	'and without, times will differ after "loading" (so elevator stops
	'closing doors etc.)
	'this allows to have "realtime" (independend from "logic updates")
	'effects - for visual effects (fading), sound ...
	Field _Time_timeGone:Long = 0
	Const SAVEGAME_VERSION:string = "1.0"

	'override to do nothing
	Method Initialize:Int()
		'
	End Method


	'override to add time adjustment
	Method RestoreGameData:Int()
		Super.RestoreGameData()
		'restore "time gone since start"
		Time.SetTimeGone(_Time_timeGone)
		'set event manager to the ticks of that time
		EventManager._ticks = _Time_timeGone
	End Method


	'override to add time storage
	Method BackupGameData:Int()
		'save a short summary of the game at the begin of the file
		_gameSummary = new TData
		_gameSummary.Add("game_mode", "singleplayer")
		_gameSummary.AddNumber("game_timeGone", GetWorldTime().GetTimeGone())
		_gameSummary.Add("player_name", GetPlayer().name)
		_gameSummary.Add("player_channelName", GetPlayer().channelName)
		_gameSummary.AddNumber("player_money", GetPlayer().GetMoney())
		_gameSummary.Add("savegame_version", SAVEGAME_VERSION)

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
		Local pix:TPixmap = VirtualGrabPixmap(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight() )
		Cls
		DrawPixmap(pix, 0,0)
		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetAlpha 1.0
		SetColor 255,255,255

		GetSpriteFromRegistry("gfx_errorbox").Draw(GetGraphicsManager().GetWidth()/2, GetGraphicsManager().GetHeight()/2, -1, New TVec2D.Init(0.5, 0.5))
		Local w:Int = GetSpriteFromRegistry("gfx_errorbox").GetWidth()
		Local h:Int = GetSpriteFromRegistry("gfx_errorbox").GetHeight()
		Local x:Int = GetGraphicsManager().GetWidth()/2 - w/2
		Local y:Int = GetGraphicsManager().GetHeight()/2 - h/2
		GetBitmapFont("Default", 15, BOLDFONT).drawBlock(title, x + 18, y + 15, w - 60, 40, Null, TColor.Create(150, 50, 50))
		GetBitmapFont("Default", 12).drawBlock(text, x + 18, y + 50, w - 40, h - 60, Null, TColor.Create(50, 50, 50))

		Flip 0
		col.SetRGBA()
	End Function


	Function Load:Int(saveName:String="savegame.xml")
		ShowMessage(True)

		'=== CHECK SAVEGAME ===
		If filetype(saveName) <> 1
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is missing.", LOG_SAVELOAD | LOG_ERROR)
			return False
		EndIf
		
		TPersist.maxDepth = 4096*4
		Local persist:TPersist = New TPersist
		Local saveGame:TSaveGame  = TSaveGame(persist.DeserializeFromFile(savename))
		If Not saveGame
			TLogger.Log("Savegame.Load()", "Savegame file ~q"+saveName+"~q is corrupt.", LOG_SAVELOAD | LOG_ERROR)
			Return False
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

		'only set the screen if the figure is in this room ... this
		'allows modifying the player in the savegame
		If GetPlayer().GetFigure().inRoom
			Local playerScreen:TScreen = ScreenCollection.GetScreen(saveGame._CurrentScreenName)
			If playerScreen.HasParentScreen(GetPlayer().GetFigure().inRoom.screenName)
				ScreenCollection.GoToScreen(playerScreen)
				'just set the current screen... no animation
				ScreenCollection._SetCurrentScreen(playerScreen)
			EndIf
		EndIf

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


		unused = 0
		used = GetScriptCollection().GetAvailableScriptList().Count()
		local scriptList:TList = RoomHandler_ScriptAgency.GetInstance().GetScriptsInStock()
		if not scriptList then scriptList = CreateList()
		local availableScripts:TScript[] = TScript[](GetScriptCollection().GetAvailableScriptList().ToArray())
		For local s:TScript = EachIn availableScripts
			unused :+1
			GetScriptCollection().Remove(s)
		Next
		'print "Cleanup: removed "+unused+" unused scripts."
		

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

		TPersist.maxDepth = 4096
		'save the savegame data as xml
		Local persist:TPersist = New TPersist
		persist.SerializeToFile(saveGame, saveName)
		'tell everybody we finished saving
		'payload is saveName and saveGame-object
		EventManager.triggerEvent(TEventSimple.Create("SaveGame.OnSave", New TData.addString("saveName", saveName).add("saveGame", saveGame)))

		Return True
	End Function


	Function GetSavegameName:string(fileURI:string)
		return stripDir(StripExt(fileURI))
	End Function


	Function GetSavegameURI:string(fileName:string)
		if GetSavegamePath() <> "" then return GetSavegamePath() + "/" + GetSavegameName(fileName) + ".xml"
		return GetSavegameName(fileName) + ".xml"
	End Function


	Function GetSavegamePath:string()
		return "savegames"
	End Function
End Type






Type TFigurePostman Extends TFigure
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500, 0, 0, 5000)

	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigurePostman(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		Super.Create(FigureName, sprite, x, onFloor, speed)
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
	Method Create:TFigureJanitor(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		Super.Create(FigureName, sprite, x, onFloor, speed)
		area.dimension.setX(14)

		GetFrameAnimations().Set(TSpriteFrameAnimation.Create("cleanRight", [ [11,130], [12,130] ], -1, 0) )
		GetFrameAnimations().Set(TSpriteFrameAnimation.Create("cleanLeft", [ [13,130], [14,130] ], -1, 0) )

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
		If IsIdling() And nextActionTimer.isExpired()
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
			If area.position.GetX() > GetBuilding().leftWallX
				'only clean with a chance of 30% when on the way to something
				'and do not clean if target is a room near figure
				Local targetDoor:TRoomDoor = TRoomDoor(GetTarget())
				If GetTarget() And (Not targetDoor Or (20 < Abs(targetDoor.GetScreenX() - area.GetX()) Or targetDoor.GetOnFloor() <> GetFloor()))
					If Rand(0,100) < NormalCleanChance Then currentAction = 1
				EndIf
				'if just standing around give a chance to clean
				If Not GetTarget() And Rand(0,100) < BoredCleanChance Then currentAction = 1
			EndIf
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
	Field checkedRoomboard:Int = False
	'the room the figure delivers to (after checking the roomboard)
	Field deliverToRoom:TRoomBase
	'the room the figure intends to deliver to
	Field intentedDeliverToRoom:TRoomBase
	'was the "package" delivered already?
	Field deliveryDone:Int = True
	'time to wait between doing something
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500, 0, 0, 5000)


	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigureDeliveryBoy(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		Super.Create(FigureName, sprite, x, onFloor, speed)
		Return Self
	End Method


	'used in news effect function
	Function SendFigureToRoom(source:TGameModifierBase, params:TData)
		Local figure:TFigureDeliveryBoy = TFigureDeliveryBoy(source.GetData().Get("figure"))
		Local room:TRoomBase = TRoomBase(source.GetData().Get("room"))
		If Not figure Or Not room Then Return

		figure.SetDeliverToRoom(room)
	End Function


	'override to make the figure stay in the room for a random time
	Method FinishEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase)
		Super.FinishEnterRoom(room, door)

		'figure now knows where to "deliver"
		If Not checkedRoomboard Then checkedRoomboard = True
		'figure entered the intended room -> delivery is finished
		If room = deliverToRoom Then deliveryDone = True
			
		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	'set the room the figure should go to.
	'DeliveryBoys do not know where the room will be, so they
	'go to the roomboard first
	Method SetDeliverToRoom:Int(room:TRoomBase)
		'to go to this room, we have to first visit the roomboard
		checkedRoomboard = False
		deliveryDone = False
		deliverToRoom = room
		intentedDeliverToRoom = room
	End Method


	Method HasToDeliver:Int() {_exposeToLua}
		Return Not deliveryDone
	End Method


	Method UpdateCustom:Int()
		'nothing to do - move to offscreen (leave building)
		If Not deliverToRoom And Not GetTarget()
			If Not IsOffScreen() Then SendToOffscreen()
		EndIf

		'figure is in building and without target waiting for orders
		If Not deliveryDone And IsIdling()
			'before directly going to a room, ask the roomboard where
			'to go
			If Not checkedRoomboard
				TLogger.Log("TFigureDeliveryBoy", Self.name+" is sent to roomboard", LOG_DEBUG | LOG_AI, True)
				SendToDoor(TRoomDoor.GetByDetails("roomboard", 0))
			Else
				'instead of sending the figure to the correct door, we
				'ask the roomsigns where to go to
				'1) get sign of the door
				Local roomDoor:TRoomDoorBase = GetRoomDoorCollection().GetMainDoorToRoom(deliverToRoom.id)
				'2) get sign which is now at the slot/floor of the room
				Local sign:TRoomBoardSign
				If roomDoor Then sign = GetRoomBoard().GetSignByCurrentPosition(roomDoor.doorSlot, roomDoor.onFloor)

				If sign And sign.door
					intentedDeliverToRoom = deliverToRoom
					deliverToRoom = TRoomDoor(sign.door).GetRoom()
					TLogger.Log("TFigureDeliveryBoy", Self.name+" is sent to room "+deliverToRoom.name+" (intended room: "+intentedDeliverToRoom.name+")", LOG_DEBUG | LOG_AI, True)
					SendToDoor(sign.door)
				Else
					TLogger.Log("TFigureDeliveryBoy", Self.name+" cannot send to a room, sign of target over empty room slot (intended room: "+deliverToRoom.name+")", LOG_DEBUG | LOG_AI, True)
					'send home again
					deliveryDone = True
					SendToOffscreen()
				EndIf
			EndIf
		EndIf

		If inRoom And nextActionTimer.isExpired()
			nextActionTimer.Reset()

			'delivery finished - send home again
			If deliveryDone
				FinishDelivery()

				deliverToRoom = Null
				intentedDeliverToRoom = Null
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
	Method GetGreetingTypeForFigure:Int(figure:TFigure)
		'0 = grrLeft
		'1 = hiLeft
		'2 = ?!left

		'depending on floor use "grr" or "?!"
		Return 0 + 2*((1 + GetBuilding().GetFloor(area.GetY()) Mod 2)-1)
	End Method	
End Type




'person who confiscates licences/programmes
Type TFigureMarshal Extends TFigureDeliveryBoy
	'arrays containing information of GUID->owner (so it stores the
	'owner of the licence in the moment of the task creation)
	Field confiscateProgammeLicenceGUID:String[]
	Field confiscateProgammeLicenceFromOwner:Int[]

	'used in news effect function
	Function CreateConfiscationJob(data:TData, params:TData)
		Local figure:TFigureMarshal = TFigureMarshal(data.Get("figure"))
		Local licenceGUID:String = data.GetString("confiscateProgrammeLicenceGUID")
		If Not figure Or Not licenceGUID Then Return

		figure.AddConfiscationJob(licenceGUID)
	End Function


	Method AddConfiscationJob:Int(confiscateGUID:String, owner:Int=-1)
		Local licence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(confiscateGUID)
		'no valid licence found
		If Not licence Then Return False

		If owner = -1 Then owner = licence.owner
		'only confiscate from players ?
		If Not GetPlayerCollection().isPlayer(owner) Then Return False

		confiscateProgammeLicenceGUID :+ [licence.GetGUID()]
		confiscateProgammeLicenceFromOwner :+ [owner]

		Return True
	End Method


	Method StartNextConfiscationJob:Int()
		If Not HasNextConfiscationJob() Then Return False

		'remove invalid jobs (eg after loading a savegame)
		If GetConfiscateProgrammeLicenceGUID() = ""
			RemoveCurrentConfiscationJob()
			Return False
		EndIf
		
		'when confiscating programmes: start with your authorization
		'letter
		sprite = GetSpriteFromRegistry(GetBaseSpriteName()+".letter")

		'send figure to the archive of the stored owner
		SetDeliverToRoom(GetRoomCollection().GetFirstByDetails("archive", GetConfiscateProgrammeLicenceFromOwner()))
	End Method


	Method HasNextConfiscationJob:Int()
		Return confiscateProgammeLicenceFromOwner.length > 0
	End Method


	Method RemoveCurrentConfiscationJob()
		confiscateProgammeLicenceGUID = confiscateProgammeLicenceGUID[1..]
		confiscateProgammeLicenceFromOwner = confiscateProgammeLicenceFromOwner[1..]
	End Method
	

	Method GetConfiscateProgrammeLicenceGUID:String()
		If confiscateProgammeLicenceGUID.length = 0 Then Return ""
		Return confiscateProgammeLicenceGUID[0]
	End Method


	Method GetConfiscateProgrammeLicenceFromOwner:Int()
		If confiscateProgammeLicenceFromOwner.length = 0 Then Return -1
		Return confiscateProgammeLicenceFromOwner[0]
	End Method
	

	Method GetBaseSpriteName:String()
		Local dotPosition:Int = sprite.GetName().Find(".")
		If dotPosition > 0
			Return Left(sprite.GetName(), dotPosition)
		Else
			Return sprite.GetName()
		EndIf
	End Method
	

	'override to try to fetch the programme they should confiscate
	Method FinishDelivery:Int()
		'try to get the licence from the owner of the room we are now in
		Local roomOwner:Int = -1
		If inRoom Then roomOwner = inRoom.owner

		If Not GetPlayerCollection().isPlayer(roomOwner)
			'block room for x hours - like terror attack ?
		Else
			'try to get the licence from the player - if that player does
			'not own the licence (eg. someone switched roomSigns), take
			'a random one ... :p
			Local licence:TProgrammeLicence = GetPlayer(roomOwner).GetProgrammeCollection().GetProgrammeLicenceByGUID( GetConfiscateProgrammeLicenceGUID() )
			If Not licence Then licence = GetPlayer(roomOwner).GetProgrammeCollection().GetRandomProgrammeLicence()

			'hmm player does not have programme licences at all...skip
			'removal in that case
			If Not licence Then Return False
				
			GetPlayer(roomOwner).GetProgrammeCollection().RemoveProgrammeLicence(licence)

			'inform others - including taken and originally intended
			'licence (so we see if the right one was took ... to inform
			'players correctly)
			EventManager.triggerEvent( TEventSimple.Create("publicAuthorities.onConfiscateProgrammeLicence", New TData.AddString("targetProgrammeGUID", GetConfiscateProgrammeLicenceGUID() ).AddString("confiscatedProgrammeGUID", licence.GetGUID()), Null, GetPlayer(roomOwner)) )

			'switch used sprite - we confiscated something
			sprite = GetSpriteFromRegistry(GetBaseSpriteName()+".box")
		EndIf

		'remove the current job, we are done with it
		RemoveCurrentConfiscationJob()

		'send to offscreen again when finished
		SendToOffscreen()
	End Method


	Method UpdateCustom:Int()
		'try to start another job when doing nothing
		If isOffscreen() And IsIdling() Then StartNextConfiscationJob()

		Super.UpdateCustom()
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
	Field settingsWindow:TSettingsWindow
	Field loadGameMenuWindow:TGUImodalWindowChain

	Method Create:TScreen_MainMenu(name:String)
		Super.Create(name)

		Self.SetScreenChangeEffects(Null,Null) 'menus do not get changers

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
		guiButtonOnline		= New TGUIButton.Create(New TVec2D.Init(0, 2*38), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonLoadGame	= New TGUIButton.Create(New TVec2D.Init(0, 3*38), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonSettings	= New TGUIButton.Create(New TVec2D.Init(0, 4*38), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)
		guiButtonQuit		= New TGUIButton.Create(New TVec2D.Init(0, 5*38 + 10), New TVec2D.Init(guiButtonsPanel.GetContentScreenWidth(), -1), "", name)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonNetwork)
		guiButtonsPanel.AddChild(guiButtonOnline)
		guiButtonsPanel.AddChild(guiButtonLoadGame)
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
		print "====== PREPARE NEW GAME ======"

		'reset game data collections
		new TGameState.Initialize()
		'load custom configuration (usernames, ports, ...)
		GetGame().LoadConfig(App.config)
		'create player figures so they can get shown in the settings screen
		'does nothing if already done
		GetGame().CreateInitialPlayers()

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

		'=== GAME SETTINGS ===
		GetGame().SetStartYear( App.config.GetInt("startyear", 0) )
	End Method


	Method CreateLoadGameWindow()
		'initialize font for the items
		TGUISavegameListItem.SetTypeFont(GetBitmapFont(""))

		'remove a previously created one
		if loadGameMenuWindow then loadGameMenuWindow.Remove()
		
		loadGameMenuWindow = New TGUIModalWindowChain.Create(New TVec2D, New TVec2D.Init(400,150), "SYSTEM")
		loadGameMenuWindow.SetZIndex(99000)
		loadGameMenuWindow.SetCenterLimit(new TRectangle.setTLBR(30,0,0,0))

		'append menu after creation of screen area, so it recenters properly
		local loadMenu:TGUIModalLoadSavegameMenu = new TGUIModalLoadSavegameMenu.Create(New TVec2D, New TVec2D.Init(450,350), "SYSTEM")
		loadMenu._defaultValueColor = TColor.clBlack.copy()
		loadMenu.defaultCaptionColor = TColor.clWhite.copy()

		loadGameMenuWindow.SetContentElement(loadMenu)

		'menu is always ingame...
		loadGameMenuWindow.SetDarkenedArea(New TRectangle.Init(0,0,800,600))
		'center to this area
		loadGameMenuWindow.SetScreenArea(New TRectangle.Init(0,0,800,600))

		App.EscapeMenuWindow = loadGameMenuWindow
		loadGameMenuWindow = null
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
		guiStartYear		= New TGUIinput.Create(New TVec2D.Init(310, 12), New TVec2D.Init(80, -1), "", 4, name)

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
		guiFilterUnreleased.SetChecked(False, False)
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
			Local slotX:Int = i * (playerSlotGap + playerBoxDimension.GetIntX())
			Local playerPanel:TGUIBackgroundBox = New TGUIBackgroundBox.Create(New TVec2D.Init(slotX, 0), New TVec2D.Init(playerBoxDimension.GetIntX(), playerBoxDimension.GetIntY()), name)
			playerPanel.spriteBaseName = "gfx_gui_panel.subContent.bright"
			playerPanel.SetPadding(playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap)
			guiPlayersPanel.AddChild(playerPanel)

			guiPlayerNames[i] = New TGUIinput.Create(New TVec2D.Init(0, 0), New TVec2D.Init(playerPanel.GetContentScreenWidth(), -1), "player", 16, name)
			guiPlayerNames[i].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_player"))

			guiChannelNames[i] = New TGUIinput.Create(New TVec2D.Init(0, 0), New TVec2D.Init(playerPanel.GetContentScreenWidth(), -1), "channel", 16, name)
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
		'assign player/channel names
		For Local i:Int = 0 To 3
			GetPlayer(i+1)
			guiPlayerNames[i].SetValue( GetPlayer(i+1).name )
			guiChannelNames[i].SetValue( GetPlayer(i+1).channelName )
		Next

		guiGameTitle.SetValue(GetGame().title)
		guiStartYear.SetValue(GetGame().userStartYear)
		guiPlayerNames[0].SetValue(GetGame().username)
		guiChannelNames[0].SetValue(GetGame().userchannelname)

		GetPlayer(1).Name = GetGame().username
		GetPlayer(1).Channelname = GetGame().userchannelname

		guiGameTitle.SetValue(GetGame().title)
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
					If Not GetGame().networkgame And Not GetGame().onlinegame
						TLogger.Log("Game", "Start a new singleplayer game", LOG_DEBUG)

						'set self into preparation state
						GetGame().SetGamestate(TGame.STATE_PREPAREGAMESTART)
					Else
						TLogger.Log("Game", "Start a new multiplayer game", LOG_DEBUG)
						guiAnnounce.SetChecked(False)
						Network.StopAnnouncing()

						'demand others to do the same
						NetworkHelper.SendPrepareGame()
						'set self into preparation state
						GetGame().SetGamestate(TGame.STATE_PREPAREGAMESTART)
					EndIf

			Case guiButtonBack
					If GetGame().networkgame
						Network.StopAnnouncing()

						If Network.isServer
							Network.DisconnectFromServer()
						Else
							Network.client.Disconnect()
						EndIf
						GetPlayerCollection().playerID = 1
						GetPlayerBossCollection().playerID = 1
						GetGame().SetGamestate(TGame.STATE_NETWORKLOBBY)
						guiAnnounce.SetChecked(False)
					Else
						GetGame().SetGamestate(TGame.STATE_MAINMENU)
					EndIf
		End Select
	End Method


	Method onCheckCheckboxes:Int(triggerEvent:TEventBase)
		Local sender:TGUICheckBox = TGUICheckBox(triggerEvent.GetSender())
		If Not sender Then Return False

		Select sender
			Case guiFilterUnreleased
					'ATTENTION: use "not" as checked means "not ignore"
					TProgrammeLicence.setIgnoreUnreleasedProgrammes( not sender.isChecked())
		End Select

		'only inform when in settings menu
		If GetGame().gamestate = TGame.STATE_SETTINGSMENU
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
			GetGame().SetStartYear( int(sender.GetValue()) )
			'use the (maybe corrected value)
			TGUIInput(sender).value = GetGame().GetStartYear()

			'store it as user setting so it gets used in
			'GetGame().PreparewNewGame()
			GetGame().userStartYear = int(TGUIInput(sender).value)
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
		For Local i:Int = 1 To 4
			'draw colors
			Local colorRect:TRectangle = New TRectangle.Init(slotPos.GetIntX()+2, Int(guiChannelNames[i-1].GetContentScreenY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)
			For Local pc:TPlayerColor = EachIn TPlayerColor.List
				If pc.ownerID = 0
					colorRect.position.AddXY(colorRect.GetW(), 0)
					pc.SetRGB()
					DrawRect(colorRect.GetX(), colorRect.GetY(), colorRect.GetW(), colorRect.GetH())
				EndIf
			Next

			'draw player figure
			SetColor 255,255,255
			GetPlayer(i).Figure.Sprite.Draw(Int(slotPos.GetX() + playerBoxDimension.GetX()/2 - GetPlayerCollection().Get(1).Figure.Sprite.framew / 2), Int(colorRect.GetY() - GetPlayerCollection().Get(1).Figure.Sprite.area.GetH()), 8)

			If GetGame().networkgame
				Local hintX:Int = Int(slotPos.GetX()) + 12
				Local hintY:Int = Int(guiPlayersPanel.GetContentScreeny())+40
				Local hint:String = "undefined playerType"
				If GetPlayer(i).IsRemoteHuman()
					hint = "remote player"
				ElseIf GetPlayer(i).IsRemoteAI()
					hint = "remote AI"
				ElseIf GetPlayer(i).IsLocalAI()
					hint = "local AI"
				ElseIf GetPlayer(i).IsLocalHuman()
					hint = "local player"
				EndIf
				GetBitMapFontManager().Get("default", 10).Draw(hint, hintX, hintY, TColor.CreateGrey(100))
			EndIf
			
			'move to next slot position
			slotPos.AddXY(playerSlotGap + playerBoxDimension.GetX(), 0)
		Next

		'overlay gui items (higher zindex)
		GUIManager.Draw(name, 101)
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)


		If GetGame().networkgame
			If Not GetGame().isGameLeader()
				guiButtonStart.disable()
			Else
				guiButtonStart.enable()
			EndIf
			'guiChat.setOption(GUI_OBJECT_VISIBLE,True)
			If Not GetGame().onlinegame
				guiSettingsWindow.SetCaption(GetLocale("MENU_NETWORKGAME"))
			Else
				guiSettingsWindow.SetCaption(GetLocale("MENU_ONLINEGAME"))
			EndIf

			guiAnnounce.show()
			guiGameTitle.show()
			guiGameTitleLabel.show()

			If guiAnnounce.isChecked() And GetGame().isGameLeader()
			'If GetGame().isGameLeader()
				'guiAnnounce.enable()
				guiGameTitle.disable()
				If guiGameTitle.Value = "" Then guiGameTitle.Value = "no title"
				GetGame().title = guiGameTitle.Value
			Else
				guiGameTitle.enable()
			EndIf
			If Not GetGame().isGameLeader()
				guiGameTitle.disable()
				guiAnnounce.disable()
			EndIf

			'disable/enable announcement on lan/online
			If guiAnnounce.isChecked()
				Network.client.playerName = GetPlayer().name
				If Not Network.announceEnabled Then Network.StartAnnouncing(GetGame().title)
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
			If GetGame().networkgame Or GetGame().isGameLeader()
				If GetGame().gamestate <> TGame.STATE_PREPAREGAMESTART And GetGame().IsControllingPlayer(i+1)
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

				For Local pc:TPlayerColor = EachIn TPlayerColor.List
					'only for unused colors
					If pc.ownerID <> 0 Then Continue

					colorRect.position.AddXY(colorRect.GetW(), 0)

					'skip if outside of rect
					If Not THelper.MouseInRect(colorRect) Then Continue
					'only allow mod if you control the player or if the
					'player is AI and you are the master player
					If GetGame().IsControllingPlayer(i+1)
						modifiedPlayers=True
						GetPlayer(i+1).RecolorFigure(pc)
					EndIf
				Next
				'move to next slot position
				slotPos.AddXY(playerSlotGap + playerBoxDimension.GetX(), 0)
			Next
		EndIf


		If GetGame().networkgame = 1
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
	'available games list
	Field guiGameList:TGUIGameEntryList


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
					Network.localFallbackIP = HostIp(GetGame().userFallbackIP)
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


		If Network.ConnectToServer( HostIp(_hostIP), _hostPort )
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

		GUIManager.Draw(Self.name)
	End Method


	Method GetOnlineIP:Int()
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
				Print "[NET] set your onlineIP: "+responseArray[0]
			EndIf
		Wend
		CloseStream Onlinestream
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)
		'register for events if not done yet
		NetworkHelper.RegisterEventListeners()

		If guiGameList.GetSelectedEntry()
			guiButtonJoin.enable()
		Else
			guiButtonJoin.disable()
		EndIf

		If GetGame().onlinegame
			If Network.OnlineIP = "" Then GetOnlineIP()

			If Network.OnlineIP
				If Network.LastOnlineRequestTimer + Network.LastOnlineRequestTime < MilliSecs()
	'TODO: [ron] rewrite handling
					Network.LastOnlineRequestTimer = MilliSecs()
					Local Onlinestream:TStream   = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=ListGames")
					Local timeOutTimer:Int = MilliSecs()+2500 '2.5 seconds okay?
					Local timeOut:Int = False
					
					If Not Onlinestream Then Throw ("Not Online?")

					While Not Eof(Onlinestream) Or timeout
						If timeouttimer < MilliSecs() Then timeout = True
						
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
	Field prepareGameCalled:Int = False
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
	Method Start:Int()
		print "====== START NEW GAME ======"
		Reset()
		
		If GetGame().networkGame
			messageWindow.SetCaption(GetLocale("STARTING_NETWORKGAME"))
		Else
			messageWindow.SetCaption(GetLocale("STARTING_SINGLEPLAYERGAME"))
		EndIf

		'do not play a sound...
		'messageWindow.Open()
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
				NetworkHelper.SendGameReady(GetPlayerCollection().playerID)
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
			'reset randomizer
			GetGame().SetRandomizerBase( GetGame().GetRandomizerBase() )
			startGameCalled = True
		EndIf
	End Method


	'spread configuration to other players
	Method SpreadConfiguration:Int()
		If Not GetGame().networkGame Then Return False

		'send which database to use (or send database itself?)
	End Method
End Type



'the modal window containing various gui elements to configure some
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
	Field dropdownSoundEngine:TGUIDropDown
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
		data.Add("sound_engine", dropdownSoundEngine.GetSelectedEntry().data.GetString("value", "0"))


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

		'check available sound engine entries
		Local selectedDropDownItem:TGUIDropDownItem
		For Local item:TGUIDropDownItem = EachIn dropdownSoundEngine.GetEntries()
			Local soundEngine:string = item.data.GetString("value")
			'if the same renderer - select this
			If soundEngine = data.GetString("sound_engine", "")
				selectedDropDownItem = item
				Exit
			EndIf
		Next
		'select the first if nothing was preselected
		If Not selectedDropDownItem
			dropdownSoundEngine.SetSelectedEntryByPos(0)
		Else
			dropdownSoundEngine.SetSelectedEntry(selectedDropDownItem)
		EndIf

		'check available renderer entries
		selectedDropDownItem = null
		For Local item:TGUIDropDownItem = EachIn dropdownRenderer.GetEntries()
			Local renderer:Int = item.data.GetInt("value")
			'if the same renderer - select this
			If renderer = data.GetInt("renderer", 0)
				selectedDropDownItem = item
				Exit
			EndIf
		Next
		'select the first if nothing was preselected
		If Not selectedDropDownItem
			dropdownRenderer.SetSelectedEntryByPos(0)
		Else
			dropdownRenderer.SetSelectedEntry(selectedDropDownItem)
		EndIf
		

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

		Local labelSoundEngine:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("SOUND_ENGINE") + ":")
		dropdownSoundEngine = New TGUIDropDown.Create(New TVec2D.Init(nextX, nextY + 12), New TVec2D.Init(inputWidth,-1), "", 128)
		Local soundEngineValues:String[] = ["AUTOMATIC", "NONE"]
		Local soundEngineTexts:String[] = ["Auto", "---"]
		?Win32
			soundEngineValues :+ ["WINDOWS_ASIO","WINDOWS_DS"]
			soundEngineTexts :+ ["ASIO", "Direct Sound"]
		?
		?Linux
			soundEngineValues :+ ["LINUX_ALSA","LINUX_PULSE","LINUX_OSS"]
			soundEngineTexts :+ ["ALSA", "PulseAudio", "OSS"]
		?
		?MacOS
			soundEngineValues :+ ["MACOSX_CORE"]
			soundEngineTexts :+ ["CoreAudio"]
		?

		Local itemHeight:Int = 0
		For Local i:Int = 0 Until soundEngineValues.Length
			Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(Null, Null, soundEngineTexts[i])
			item.SetValueColor(TColor.CreateGrey(50))
			item.data.Add("value", soundEngineValues[i])
			dropdownSoundEngine.AddItem(item)
			If itemHeight = 0 Then itemHeight = item.GetScreenHeight()
		Next
		dropdownSoundEngine.SetListContentHeight(itemHeight * Len(soundEngineValues))

		canvas.AddChild(labelSoundEngine)
		canvas.AddChild(dropdownSoundEngine)
'		GuiManager.SortLists()
		nextY :+ inputH + labelH * 1.5
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
		itemHeight = 0
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

		modalDialogue.Open()

		Return Self
	End Method
End Type




Type GameEvents
	Global _eventListeners:TLink[]
	
	Function UnRegisterEventListeners:Int()
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]
	End Function


	Function RegisterEventListeners:Int()
		'react on right clicks during a rooms update (leave room)
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onUpdate", RoomOnUpdate) ]

		'=== REGISTER TIME EVENTS ===
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnDay", OnDay) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnHour", OnHour) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnMinute", OnMinute) ]

		'=== REGISTER PLAYER EVENTS ===
		'events get ignored by non-gameleaders
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnMinute", PlayersOnMinute) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnDay", PlayersOnDay) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("Time.OnSecond", Time_OnSecond) ]

		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerFinance.onChangeMoney", PlayerFinanceOnChangeMoney) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerFinance.onTransactionFailed", PlayerFinanceOnTransactionFailed) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerBoss.onCallPlayer", PlayerBoss_OnCallPlayer) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerBoss.onCallPlayerForced", PlayerBoss_OnCallPlayerForced) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerBoss.onPlayerEnterBossRoom", PlayerBoss_OnPlayerEnterBossRoom) ]

		'=== PUBLIC AUTHORITIES ===
		'-> create ingame notifications
		_eventListeners :+ [ EventManager.registerListenerFunction("publicAuthorities.onStopXRatedBroadcast", publicAuthorities_onStopXRatedBroadcast) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("publicAuthorities.onConfiscateProgrammeLicence", publicAuthorities_onConfiscateProgrammeLicence) ]

		'visually inform that selling the last station is impossible
		_eventListeners :+ [ EventManager.registerListenerFunction("StationMap.onTrySellLastStation", StationMap_OnTrySellLastStation) ]
		'trigger audience recomputation when a station is trashed/sold
		_eventListeners :+ [ EventManager.registerListenerFunction("StationMap.removeStation", StationMap_OnRemoveStation) ]
		'show ingame toastmessage if station is under construction
		_eventListeners :+ [ EventManager.registerListenerFunction("StationMap.addStation", StationMap_OnAddStation) ]

		'listen to failed or successful ending adcontracts to send out
		'ingame toastmessages
		_eventListeners :+ [ EventManager.registerListenerFunction("AdContract.onFinish", AdContract_OnFinish) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("AdContract.onFail", AdContract_OnFail) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ProgrammeLicenceAuction.onGetOutbid", ProgrammeLicenceAuction_OnGetOutbid) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ProgrammeLicenceAuction.onWin", ProgrammeLicenceAuction_OnWin) ]

		'we want to handle "/dev bla"-commands via chat
		_eventListeners :+ [ EventManager.registerListenerFunction("chat.onAddEntry", onChatAddEntry ) ]
	End Function


	Function onChatAddEntry:Int(triggerEvent:TEventBase)
		Local text:String = triggerEvent.GetData().GetString("text")
		'only interested in system/dev-commands
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
					player.GetFinance().ChangeMoney(Int(paramS), TVTPlayerFinanceEntryType.CHEAT)

					If Int(paramS) > 0 Then paramS = "+"+Int(paramS)
					changed = " ("+paramS+")"
				EndIf
				GetGame().SendSystemMessage("[DEV] Money of player "+playerS+": "+player.GetFinance().money+"." + changed)

			Case "image"
				If Not player Then Return GetGame().SendSystemMessage(PLAYER_NOT_FOUND)

				Local changed:String = ""
				If paramS <> ""
					player.GetPublicImage().ChangeImage( New TAudience.AddFloat(Int(paramS)))
					
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
					GetGame().SendSystemMessage("Wrong syntax (/sys help)!")
				EndIf				
				
			Case "help"
				SendHelp()

			Default
				SendHelp()
				'SendSystemMessage("[DEV] unknown command: ~q"+command+"~q")
		End Select


		Function SendHelp()
				Local commands:String = ""
				commands :+ "money [player#] [+- money]~n"
				commands :+ "bossmood [player#] [+- mood %]~n"
				commands :+ "image [player#] [+- image %]~n"
				commands :+ "terrorlvl [terrorgroup# 0 or 1] [level#]"
				GetGame().SendSystemMessage("[DEV] available commands:~n"+commands)
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
			If player.isLocalAI() Then player.PlayerAI.ConditionalCallOnTick()
			If player.isLocalAI() Then player.PlayerAI.CallOnRealtimeSecond(timeGone)
		Next
		Return True
	End Function


	Function PlayersOnMinute:Int(triggerEvent:TEventBase)
		If Not GetGame().isGameLeader() Then Return False

		Local time:Long = triggerEvent.GetData().getInt("time",-1)
		local minute:int = GetWorldTime().GetDayMinute(time)
		If minute < 0 Then Return False

		For Local player:TPLayer = EachIn GetPlayerCollection().players
			If player.isLocalAI() Then player.PlayerAI.ConditionalCallOnTick()
			If player.isLocalAI() Then player.PlayerAI.CallOnMinute(minute)
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
		If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
	End Function


	Function PlayerBoss_OnCallPlayerForced:Int(triggerEvent:TEventBase)
		Local latestTime:Long = triggerEvent.GetData().GetLong("latestTime", GetWorldTime().GetTimeGone() + 2*3600)
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
		Local latestTime:Long = triggerEvent.GetData().GetLong("latestTime", GetWorldTime().GetTimeGone() + 2*3600)
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
			toast.SetCloseAtWorldTimeText("CLOSES_AT_TIME")
			toast.SetMessageType(1)
			toast.SetPriority(10)

			toast.SetCaption(GetLocale("YOUR_BOSS_WANTS_TO_SEE_YOU"))
			toast.SetText(..
				GetLocale("YOU_HAVE_GOT_X_HOURS TO_VISIT_HIM").Replace("%HOURS%", 2) + " " +..
				"|i|"+GetLocale("CLICK_HERE_TO_START_YOUR_VISIT_AHEAD_OF_TIME") + "|/i|" ..
			)
			toast.SetOnCloseFunction(PlayerBoss_onClosePlayerCallMessage)
			toast.GetData().Add("boss", boss)
			toast.GetData().Add("player", player)

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


	Function PublicAuthorities_onStopXRatedBroadcast:Int(triggerEvent:TEventBase)
		Local programme:TProgramme = TProgramme(triggerEvent.GetSender())
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		If player.isLocalAI() Then player.playerAI.CallOnPublicAuthoritiesStopXRatedBroadcast()

		'only interest in active players contracts
		If programme.owner <> GetPlayerCollection().playerID Then Return False

		Local toast:TGameToastMessage = New TGameToastMessage
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
		Local targetProgrammeLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID( triggerEvent.GetData().GetString("targetProgrammeGUID") )
		Local confiscatedProgrammeLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID( triggerEvent.GetData().GetString("confiscatedProgrammeGUID") )
		Local player:TPlayer = TPlayer(triggerEvent.GetReceiver())

		'inform ai before
		If player.isLocalAI() Then player.playerAI.CallOnPublicAuthoritiesConfiscateProgrammeLicence(confiscatedProgrammeLicence, targetProgrammeLicence)

		'only interest in active players contracts
		If confiscatedProgrammeLicence.owner <> GetPlayerCollection().playerID Then Return False

		Local toast:TGameToastMessage = New TGameToastMessage
		'show it for some seconds
		toast.SetLifeTime(15)
		toast.SetMessageType(1) 'attention
		toast.SetCaption(GetLocale("AUTHORITIES_CONFISCATED_LICENCE"))
		Local text:String = GetLocale("PROGRAMMELICENCE_X_GOT_CONFISCATED").Replace("%TITLE%", "|b|"+confiscatedProgrammeLicence.GetTitle()+"|/b|") + " "
		If confiscatedProgrammeLicence <> targetProgrammeLicence
			text :+ GetLocale("SEEMS_AUTHORITIES_VISITED_THE_WRONG_ROOM")
		Else
			text :+ GetLocale("BETTER_WATCH_OUT_NEXT_TIME")
		EndIf
		
		toast.SetText(text)
		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function


	Function ProgrammeLicenceAuction_OnGetOutbid:Int(triggerEvent:TEventBase)
		'only interested in auctions in which the player got overbid
		Local previousBestBidder:Int = triggerEvent.GetData().GetInt("previousBestBidder")
		If GetPlayer().playerID <> previousBestBidder Then Return False

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
		toast.SetText( ..
			GetLocale("SOMEONE_BID_MORE_THAN_YOU_FOR_X").Replace("%TITLE%", licence.GetTitle()) + " " + ..
			GetLocale("YOUR_PREVIOUS_BID_OF_X_WAS_REFUNDED").Replace("%MONEY%", "|b|"+TFunctions.DottedValue(previousBestBid)+getLocale("CURRENCY")+"|/b|") ..
		)
		'play a special sound instead of the default one
		toast.GetData().AddString("onAddMessageSFX", "positiveMoneyChange")

		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")

	End Function


	Function ProgrammeLicenceAuction_OnWin:Int(triggerEvent:TEventBase)
		'only interested in auctions the player won
		Local bestBidder:Int = triggerEvent.GetData().GetInt("bestBidder")
		If GetPlayer().playerID <> bestBidder Then Return False

		Local licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().Get("licence"))
		Local bestBid:Int = triggerEvent.GetData().GetInt("bestBidder")
		If Not licence Or Not GetPlayer(bestBidder) Then Return False


		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
	
		'show it for some seconds
		toast.SetLifeTime(8)
		toast.SetMessageType(2) 'positive
		toast.SetCaption(GetLocale("YOU_HAVE_WON_AN_AUCTION"))
		toast.SetText(GetLocale("THE_LICENCE_OF_X_IS_NOW_AT_YOUR_DISPOSAL").Replace("%TITLE%", licence.GetTitle()))
		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function	

	
	Function AdContract_OnFinish:Int(triggerEvent:TEventBase)
		Local contract:TAdContract = TAdContract(triggerEvent.GetSender())
		If Not contract Then Return False

		'only interest in active players contracts
		If contract.owner <> GetPlayer().playerID Then Return False

		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
	
		'show it for some seconds
		toast.SetLifeTime(8)
		toast.SetMessageType(2) 'positive
		toast.SetCaption(GetLocale("ADCONTRACT_FINISHED"))
		toast.SetText( ..
			GetLocale("ADCONTRACT_X_SUCCESSFULLY_FINISHED").Replace("%TITLE%", contract.GetTitle()) + " " + ..
			GetLocale("PROFIT_OF_X_GOT_CREDITED").Replace("%MONEY%", "|b|"+TFunctions.DottedValue(contract.GetProfit())+getLocale("CURRENCY")+"|/b|") ..
		)
		'play a special sound instead of the default one
		toast.GetData().AddString("onAddMessageSFX", "positiveMoneyChange")

		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function

	
	Function AdContract_OnFail:Int(triggerEvent:TEventBase)
		Local contract:TAdContract = TAdContract(triggerEvent.GetSender())
		If Not contract Then Return False

		'only interest in active players contracts
		 If contract.owner <> GetPlayerCollection().playerID Then Return False

		'send out a toast message
		Local toast:TGameToastMessage = New TGameToastMessage
	
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
		If Not player or not GetPlayerCollection().IsLocalHuman(player.playerID) Then Return False

		'in the past?
		if station.GetActivationTime() < GetWorldTime().GetTimeGone() then return False
		


		local readyTime:String = GetWorldTime().GetFormattedTime(station.GetActivationTime())
		local closeText:string = "CLOSES_AT_TIME"
		local readyText:string = "NEW_STATION_WILL_BE_READY_AT_TIME_X"
		'prepend day if it does not finish today
		if GetWorldTime().GetDay() < GetWorldTime().GetDay(station.GetActivationTime())
			readyTime = GetWorldTime().GetFormattedDay(GetWorldTime().GetDaysRun(station.GetActivationTime()) +1) + " " + readyTime
			closeText = "CLOSES_AT_DAY"
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
		toast.SetPriority(2)

		toast.SetCaption(GetLocale("STATION_UNDER_CONSTRUCTION"))
		toast.SetText( GetLocale(readyText).Replace("%TIME%", readyTime) )

		rem - if only 1 instance allowed
		'if this was a new message, the guid will differ
		If toast.GetGUID() <> toastGUID
			toast.SetGUID(toastGUID)
			'new messages get added to a list
			GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		EndIf
		endrem

		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
	End Function


	Function StationMap_OnTrySellLastStation:Int(triggerEvent:TEventBase)
		Local stationMap:TStationMap = TStationMap(triggerEvent.GetSender())
		If Not stationMap Then Return False

		Local player:TPlayer = GetPlayerCollection().Get(stationMap.owner)
		If Not player Then Return False

		'create an visual error
		If player.isActivePlayer() Then TError.Create( getLocale("ERROR_NOT_POSSIBLE"), getLocale("ERROR_NOT_ABLE_TO_SELL_LAST_STATION") )
	End Function



	Function OnMinute:Int(triggerEvent:TEventBase)
		local time:Long = triggerEvent.GetData().GetLong("time",-1)
		Local minute:Int = GetWorldTime().GetDayMinute(time)
		Local hour:Int = GetWorldTime().GetDayHour(time)
		Local day:Int = GetWorldTime().GetDay(time)
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
		GetGame().refillMovieAgencyTime :-1
		GetGame().refillAdAgencyTime :-1
		'refill if needed
		If GetGame().refillMovieAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("movieagency").hasOccupant()
				GetGame().refillMovieAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				GetGame().refillMovieAgencyTime = GetGame().refillMovieAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling movieagency", LOG_DEBUG)
				RoomHandler_movieagency.GetInstance().ReFillBlocks(True, 0.5)
			EndIf
		EndIf
		If GetGame().refillAdAgencyTime <= 0
			'delay if there is one in this room
			If GetRoomCollection().GetFirstByDetails("adagency").hasOccupant()
				GetGame().refillAdAgencyTime :+ 15
			Else
				'reset but with a bit randomness
				GetGame().refillAdAgencyTime = GetGame().refillAdAgencyTimer + randrange(0,20)-10

				TLogger.Log("GameEvents.OnMinute", "partly refilling adagency", LOG_DEBUG)
				If GetGame().refillAdAgencyOverridePercentage <> GetGame().refillAdAgencyPercentage
					RoomHandler_adagency.GetInstance().ReFillBlocks(True, GetGame().refillAdAgencyOverridePercentage)
					GetGame().refillAdAgencyOverridePercentage = GetGame().refillAdAgencyPercentage
				Else
					RoomHandler_adagency.GetInstance().ReFillBlocks(True, GetGame().refillAdAgencyPercentage)
				EndIf
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
				'adjust currently broadcasted block
				If broadcastMaterial
					broadcastMaterial.currentBlockBroadcasting = player.GetProgrammePlan().GetObjectBlock(broadcastMaterial.usedAsType, day, hour)
				EndIf
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
					player.GetProgrammePlan().RemoveProgramme(currentProgramme, day, hour)
					'set current broadcast to malfunction
					GetBroadcastManager().SetBroadcastMalfunction(player.playerID, TVTBroadcastMaterialType.PROGRAMME)
					'decrease image by 0.5%
					player.GetPublicImage().ChangeImage(New TAudience.AddFloat(-0.5))

					'chance of 25% the programme will get (tried) to get confiscated
					Local confiscateProgramme:Int = RandRange(0,100) < 25

					If confiscateProgramme
						EventManager.triggerEvent(TEventSimple.Create("publicAuthorities.onStartConfiscateProgramme", New TData.AddString("broadcastMaterialGUID", currentProgramme.GetGUID()).AddNumber("owner", player.playerID), currentProgramme, player))

						'Send out first marshal - Mr. Czwink or Mr. Czwank
						TFigureMarshal(GetGame().marshals[randRange(0,1)]).AddConfiscationJob(currentProgramme.GetGUID())
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
			For Local player:TPlayer = EachIn GetPlayerCollection().players
				player.GetProgrammePlan().InformCurrentBroadcast(day, hour, minute)
			Next
		EndIf
	
		Return True
	End Function


	'things happening each hour
	Function OnHour:Int(triggerEvent:TEventBase)
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
					p.GetProgrammePlan().RemoveNews(news,-1,False)
				EndIf
			Next
			endrem
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
			'Neuer Award faellig?
			If GetBetty().GetAwardEnding() < GetWorldTime().GetDay(time) - 1
				GetBetty().GetLastAwardWinner()
				GetBetty().SetAwardType(RandRange(0, GetBetty().MaxAwardTypes), True)
			End If

			GetProgrammeDataCollection().RefreshTopicalities()
			GetAdContractBaseCollection().RefreshInfomercialTopicalities()
			GetGame().ComputeContractPenalties(day)
			'first pay everything ...
			GetGame().ComputeDailyCosts(day)
			'then earn...
			GetGame().ComputeDailyIncome(day)
			TAuctionProgrammeBlocks.EndAllAuctions() 'won auctions moved to programmecollection of player
			if GetWorldTime().GetDayOfYear(time) = 1
				TAuctionProgrammeBlocks.RefillAuctionsWithoutBid()
			endif
		
			'reset room signs each day to their normal position
			GetRoomBoard().ResetPositions()


			'DISABLED
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

			local text:string[] = GetPlayerFinanceOverviewText(day)
			For local s:string = EachIn text
				TLogger.Log("OnDay Financials", s, LOG_DEBUG)
			Next

			'=== REMOVE OLD NEWS AND NEWSEVENTS ===
			'news and newsevents both have a "happenedTime" but they must
			'not be the same (multiple news with the same event but happened
			'to different times)
			Local daysToKeep:Int = 2
	
			'remove old news from the all player plans and collections
			For Local pBase:TPlayerBase = EachIn GetPlayerBaseCollection().players
				local p:TPlayer = TPlayer(pBase)
				if not p then continue
				
				'COLLECTION
				'news could stay there for 2 days (including today)
				daysToKeep = 2
				'loop through a copy to avoid concurrent modification
				For Local news:TNews = EachIn p.GetProgrammeCollection().news.Copy()
					If day - GetWorldTime().GetDay(news.GetHappenedTime()) >= daysToKeep
						p.GetProgrammeCollection().RemoveNews(news)
					EndIf
				Next

				'PLAN
				'news could get send a day longer (3 days incl. today)
				daysToKeep = 3
				'no need to copy the array because it has a fixed length
				For Local news:TNews = EachIn p.GetProgrammePlan().news
					If day - GetWorldTime().GetDay(news.GetHappenedTime()) >= daysToKeep
						p.GetProgrammePlan().RemoveNews(news,-1,False)
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
		
		If obj.isDragable() And GetGame().cursorstate = 0
			GetGame().cursorstate = 1
		EndIf
		If obj.isDragged() Then GetGame().cursorstate = 2
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
	TProfiler.DumpLog(LOG_NAME)
	TLogFile.DumpLogs()
End Function


'===== COMMON FUNCTIONS =====

Function GetPlayerFinanceOverviewText:string[](day:int)
	local finance:TPlayerFinance = GetPlayer().GetFinance(day - 1)
	local financeTotal:TPlayerFinance = GetPlayerFinanceCollection().GetTotal(GetPlayer().playerID)
	local text:string[]
	text :+ ["Finance Stats for day "+(day-1) +". Player #"+GetPlayer().playerID]
	text :+ [".----------------------------------------------------------------------------."]
	text :+ ["|Money:           "+Rset(GetPlayer().GetMoney(), 9)+"  |                       |         TOTAL         |"]
	text :+ ["|----------------------------.-----------.-----------.-----------.-----------|"]
	text :+ ["|                            |   INCOME  |  EXPENSE  |   INCOME  |  EXPENSE  |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_TRADING_PROGRAMMELICENCES"), 27) + " | " + RSet(TFunctions.dottedValue(finance.income_programmeLicences), 9) + " | " + Rset(TFunctions.dottedValue(finance.expense_programmeLicences),9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_programmeLicences), 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_programmeLicences),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_AD_INCOME__CONTRACT_PENALTY"), 27) + " | " + RSet(TFunctions.dottedValue(finance.income_ads), 9) + " | " + Rset(TFunctions.dottedValue(finance.expense_penalty),9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_ads), 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_penalty),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_CALL_IN_SHOW_INCOME"), 27) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_callerRevenue), 9) + " | " + Rset("-",9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_callerRevenue), 9) + " | " + Rset("-",9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_SPONSORSHIP_INCOME__PENALTY"), 27) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_sponsorshipRevenue), 9) + " | " + Rset("-",9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_sponsorshipRevenue), 9) + " | " + Rset("-",9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_NEWS"), 27) + " | " + RSet("-", 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_news),9) + " | " + RSet("-", 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_news),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_NEWSAGENCIES"), 27) + " | " + RSet("-", 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_newsAgencies),9)+ " | " + RSet("-", 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_newsAgencies),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_STATIONS"), 27) + " | " + RSet(TFunctions.dottedValue(finance.income_stations), 9) + " | " + Rset(TFunctions.dottedValue(finance.expense_stationFees),9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_stations), 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_stationFees),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_SCRIPTS"), 27) + " | " + RSet(TFunctions.dottedValue(finance.income_scripts), 9) + " | " + Rset(TFunctions.dottedValue(finance.expense_scripts),9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_scripts), 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_scripts),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_ACTORS_AND_PRODUCTIONSTUFF"), 27) + " | " + RSet("-", 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_productionStuff),9) + " | " + RSet("-", 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_productionStuff),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_STUDIO_RENT"), 27) + " | " + RSet("-", 9) + " | " + Rset(TFunctions.dottedValue(finance.expense_rent),9) + " | " + RSet("-", 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_rent),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_INTEREST_BALANCE__CREDIT"), 27) + " | " + RSet(TFunctions.dottedValue(finance.income_balanceInterest), 9) + " | " + Rset(TFunctions.dottedValue(finance.expense_drawingCreditInterest),9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_balanceInterest), 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_drawingCreditInterest),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_CREDIT_TAKEN__REPAYED"), 27) + " | " + RSet(TFunctions.dottedValue(finance.income_creditTaken), 9) + " | " + Rset(TFunctions.dottedValue(finance.expense_creditRepayed),9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_creditTaken), 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_creditRepayed),9)+ " |"]
	text :+ ["|"+LSet(GetLocale("FINANCES_MISC"), 27) + " | " + RSet(TFunctions.dottedValue(finance.income_misc), 9) + " | " + Rset(TFunctions.dottedValue(finance.expense_misc),9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_misc), 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_misc),9)+ " |"]
	text :+ ["|----------------------------|-----------|-----------|-----------|-----------|"]
	text :+ ["|"+LSet(GetLocale("FINANCES_TOTAL"), 27) + " | " + RSet(TFunctions.dottedValue(finance.income_total), 9) + " | " + Rset(TFunctions.dottedValue(finance.expense_total),9) + " | " + RSet(TFunctions.dottedValue(financeTotal.income_total), 9) + " | " + Rset(TFunctions.dottedValue(financeTotal.expense_total),9)+ " |"]
	text :+ ["'----------------------------'-----------'-----------'-----------'-----------'"]
	return text
End Function


Function DrawMenuBackground(darkened:Int=False)
	'cls only needed if virtual resolution is enabled, else the
	'background covers everything
	if GetGraphicsManager().HasBlackBars() then Cls()

	SetColor 255,255,255
	GetSpriteFromRegistry("gfx_startscreen").Draw(0,0)


	'draw an (animated) logo
	Select GetGame().gamestate
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

				logo.Draw( GetGraphicsManager().GetWidth()/2, 150, -1, ALIGN_CENTER_CENTER, logoScale)
				SetAlpha oldAlpha
			EndIf
	EndSelect

	If GetGame().gamestate = TGame.STATE_MAINMENU
		SetColor 255,255,255
		GetBitmapFont("Default",13, BOLDFONT).DrawBlock("Wir brauchen Deine Hilfe!", 10,490, 300,20, Null,TColor.Create(75,75,140))
		GetBitmapFont("Default",12).DrawBlock("Beteilige Dich an Diskussionen rund um alle Spielelemente in TVTower.", 10,510, 300,30, Null,TColor.Create(75,75,140))
		GetBitmapFont("Default",12, BOLDFONT).drawBlock("http://www.gamezworld.de/phpforum", 10,537, 500,20, Null,TColor.Create(75,75,180))
		SetAlpha 0.5 * GetAlpha()
		GetBitmapFont("Default",11).drawBlock("(Keine Anmeldung notwendig)", 10,551, 500,20, Null,TColor.Create(75,75,180))
		SetAlpha 2.0 * GetAlpha()
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
			local progSlot:TBroadcastMaterial = GetPlayerProgrammePlan(player).GetProgramme(day, hour)
			local adSlot:TBroadcastMaterial = GetPlayerProgrammePlan(player).GetAdvertisement(day, hour)

			local progText:string, progAudienceText:string
			local adText:string, adAudienceText:string
			local newsAudienceText:string

			if progSlot
				if progSlot.isType(TVTBroadcastMaterialType.PROGRAMME)
					progText = LSet(progSlot.GetTitle(), 25)
				else
					progText = LSet("[I] " + progSlot.GetTitle(), 25)
				endif
			else
				progText = LSet("Keine Ausstrahlung", 25)
			endif

			if audience
				progAudienceText = RSet(int(audience.audience.GetTotalSum()), 7) + " " + RSet(MathHelper.NumberToString(audience.GetAudienceQuotePercentage()*100,2), 6)+"%"
			else
				progAudienceText = RSet(" -/- ", 7) + " " +RSet("0%", 6)
			endif

			if newsAudience
				newsAudienceText = RSet(int(newsAudience.audience.GetTotalSum()), 7)
			else
				newsAudienceText = RSet(" -/- ", 7)
			endif


			if adSlot
				adText = LSet(adSlot.GetTitle(), 20)
				adAudienceText = RSet(" -/- ", 7)

				if adSlot.isType(TVTBroadcastMaterialType.PROGRAMME)
					adText = LSet("[T] " + adSlot.GetTitle(), 20)
				elseif adSlot.isType(TVTBroadcastMaterialType.ADVERTISEMENT)
					adAudienceText = RSet(int(TAdvertisement(adSlot).contract.GetMinAudience()),7)
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


Function DEV_switchRoom:Int(room:TRoom)
	'do not react if already switching
	if GetPlayer().GetFigure().IsChangingRoom() then return False
	
	If Not room Then Return False

	'skip if already there
	If GetPlayer().GetFigure().inRoom = room Then Return False

	'to avoid seeing too much animation
	TInGameScreen_Room.temporaryDisableScreenChangeEffects = True

	'leave first
	If GetPlayer().GetFigure().inRoom
		'force leave?
		'GetPlayer().GetFigure().LeaveRoom(True)
		'not forcing a leave is similar to "right-click"-leaving
		'which means it signs contracts, buys programme etc
		GetPlayer().GetFigure().LeaveRoom(False)
	EndIf

	'remove potential elevator passenger 
	GetElevator().LeaveTheElevator(GetPlayer().GetFigure())
	
	'a) add the room as new target before all others
	'GetPlayer().GetFigure().PrependTarget(TRoomDoor.GetMainDoorToRoom(room))
	'b) set it as the only route
	GetPlayer().GetFigure().SetTarget( GetRoomDoorCollection().GetMainDoorToRoom(room.id) )
	GetPlayer().GetFigure().MoveToCurrentTarget()

	'call reach step 1 - so it actually reaches the target in this turn
	'already (instead of next turn - which might have another "dev_key"
	'pressed)
	GetPlayer().GetFigure().ReachTargetStep1()

	Return True
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

	'c) everything loaded - normal game loop
TProfiler.Enter("GameLoop")
	StartApp()
	Repeat
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