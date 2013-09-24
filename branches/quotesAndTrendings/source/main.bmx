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

?Linux
Import "external/bufferedglmax2d/bufferedglmax2d.bmx"
?Win32
Import brl.D3D9Max2D
Import brl.D3D7Max2D
?

?Threaded
Import brl.Threads
?

Include "gamefunctions.bmx" 					'Types: - TError - Errorwindows with handling
												'		- base class For buttons And extension newsbutton
												'		- stationmap-handling, -creation ...


Global VersionDate:String		= LoadText("incbin::source/version.txt")
Global VersionString:String		= "version of " + VersionDate
Global CopyrightString:String	= "by Ronny Otto & Manuel Vögele"
AppTitle = "TVTower: " + VersionString + " " + CopyrightString

Global App:TApp = TApp.Create(60,60) 'create with 60fps for physics and graphics
App.LoadResources("config/resources.xml")

'RON: precalc here until we have abilities to use different maps during
'     start settings setup
TStationMap.InitMapData()

GUIManager.globalScale	= 1.00
GUIManager.defaultFont	= Assets.GetFont("Default", 12)
Include "gamefunctions_tvprogramme.bmx"  		'contains structures for TV-programme-data/Blocks and dnd-objects
Include "gamefunctions_rooms.bmx"				'basic roomtypes with handling
Include "gamefunctions_ki.bmx"					'LUA connection
Include "gamefunctions_sound.bmx"				'TVTower spezifische Sounddefinitionen
Include "gamefunctions_popularity.bmx"			'Popularitäten und Trends
Include "gamefunctions_quotes.bmx"				'Quotenberechnung


Global ArchiveProgrammeList:TgfxProgrammelist	= TgfxProgrammelist.Create(575, 16, 21)

Global SaveError:TError, LoadError:TError
Global ExitGame:Int 							= 0 			'=1 and the game will exit
Global Fader:TFader								= New TFader
Global NewsAgency:TNewsAgency					= New TNewsAgency.Create()

TTooltip.UseFontBold	= Assets.fonts.baseFontBold
TTooltip.UseFont 		= Assets.fonts.baseFont
TTooltip.ToolTipIcons	= Assets.GetSprite("gfx_building_tooltips")
TTooltip.TooltipHeader	= Assets.GetSprite("gfx_tooltip_header")

Rem
Enthaelt Verbindung zu Einstellungen und Timern
sonst nix
endrem
Type TApp
	Field Timer:TDeltaTimer
	Field limitFrames:Int				= 0
	Field settings:TApplicationSettings
	Field prepareScreenshot:Int			= 0						'logo for screenshot
	Field g:TGraphics

	Field creationTime:Int 'only used for debug purpose (loadingtime)
	Global lastLoadEvent:TEventSimple	= Null
	Global baseResourcesLoaded:Int		= 0						'able to draw loading screen?
	Global baseResourceXmlUrl:String	= "config/startup.xml"	'holds bg for loading screen and more
	Global currentResourceUrl:String	= ""
	Global maxResourceCount:Int			= 331					'set to <=0 to get a output of loaded resources

	Global LogoFadeInFirstCall:Int		= 0
	Global LoaderWidth:Int				= 0


	Function Create:TApp(updatesPerSecond:Int = 60, framesPerSecond:Int = 60)
		Local obj:TApp = New TApp
		obj.creationTime = MilliSecs()
		obj.settings = New TApplicationSettings
		'create timer
		obj.timer = TDeltaTimer.Create(updatesPerSecond, framesPerSecond)
		'listen to App-timer
		'-register to draw loading screen
		EventManager.registerListenerFunction( "App.onDraw", 	TApp.drawLoadingScreen )
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

		Self.settings.fullscreen	= xml.FindValueInt(node, "fullscreen", Self.settings.fullscreen, "settings.xml fehlt 'fullscreen', setze Defaultwert: "+Self.settings.fullscreen)
		Self.settings.directx		= xml.FindValueInt(node, "directx", Self.settings.directx, "settings.xml fehlt 'directx', setze Defaultwert: "+Self.settings.directx+" (OpenGL)")
		Self.settings.colordepth	= xml.FindValueInt(node, "colordepth", Self.settings.colordepth, "settings.xml fehlt 'colordepth', setze Defaultwert: "+Self.settings.colordepth)

		If Self.settings.colordepth <> 16 And Self.settings.colordepth <> 32
			Print "settings.xml enthaelt fehlerhaften Eintrag fuer 'colordepth', setze Defaultwert: 16"
			Self.settings.colordepth = 16
		EndIf
	End Method

	Method LoadResources:Int(path:String="config/resources.xml")
		Local XmlLoader:TXmlLoader = TXmlLoader.Create()
		XmlLoader.Parse(path)
		Assets.AddSet(XmlLoader.Values) 'copy XML-values
	End Method

	Method StartApp()
		EventManager.unregisterAllListeners( "App.onDraw" )
		EventManager.registerListener( "App.onUpdate", 	TEventListenerOnAppUpdate.Create() )
		EventManager.registerListener( "App.onDraw", 	TEventListenerOnAppDraw.Create() )
		EventManager.registerListener( "App.onSoundUpdate", TEventListenerOnSoundUpdate.Create() )
		SoundManager.PlayMusic(MUSIC_TITLE)
		Print "LADEZEIT : "+(MilliSecs() - Self.creationTime) +"ms"
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
		SetVirtualGraphics(settings.designedWidth, settings.designedHeight, false)
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
		If TApp.baseResourcesLoaded
			App.timer.loop()
 		EndIf
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
			Assets.GetSprite("gfx_startscreen_logo").Draw( App.settings.getWidth()/2 - Assets.GetSprite("gfx_startscreen_logo").w / 2, 100)
			SetAlpha 1.0
			Assets.GetSprite("gfx_startscreen_loadingBar").Draw( 400, 376, 1, 0, 0.5)

			LoaderWidth = Min(680, LoaderWidth + (680.0 / TApp.maxResourceCount))
			Assets.GetSprite("gfx_startscreen_loadingBar").TileDraw((400-Assets.GetSprite("gfx_startscreen_loadingBar").framew / 2) ,376,LoaderWidth, Assets.GetSprite("gfx_startscreen_loadingBar").frameh)
			SetColor 0,0,0
			If itemNumber > 0
				SetAlpha 0.25
				DrawText "[" + Replace(RSet(itemNumber, String(maxItemNumber).length), " ", "0") + "/" + maxItemNumber + "]", 670, 415
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
			Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-7, 	MouseManager.y	,0)

			Flip 0
		EndIf
	End Function
End Type


Const GAMESTATE_RUNNING:Int					= 0
Const GAMESTATE_MAINMENU:Int				= 1
Const GAMESTATE_NETWORKLOBBY:Int			= 2
Const GAMESTATE_SETTINGSMENU:Int			= 3
Const GAMESTATE_STARTMULTIPLAYER:Int		= 4		'mode when data gets synchronized
Const GAMESTATE_INIZIALIZEGAME:int			= 5		'mode when date needed for game (names,colors) gets loaded

'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame {_exposeToLua="selected"}
	''rename CONFIG-vars ... config_DoorOpenTime... config_gameSpeed ...
	Const maxAbonnementLevel:Int		= 3
	
	Field BroadcastManager:TBroadcastManager = null
	Field PopularityManager:TPopularityManager = null
	
	Field maxContractsAllowed:Int 		= 10	{nosave}	'how many contracts a player can possess
	Field maxMoviesInSuitcaseAllowed:Int= 12	{nosave}	'how many movies can be carried in suitcase
	Field startMovieAmount:Int 			= 5		{nosave}	'how many movies does a player get on a new game
	Field startSeriesAmount:Int			= 1		{nosave}	'how many series does a player get on a new game
	Field startAdAmount:Int				= 3		{nosave}	'how many contracts a player gets on a new game
	Field debugmode:Byte				= 0		{nosave}	'0=no debug messages; 1=some debugmessages
	Field DebugInfos:Byte				= 0		{nosave}
	Field DebugQuoteInfos:Byte			= 0		{nosave}	

	Field daynames:String[]						{nosave}	'array of abbreviated (short) daynames
	Field daynamesLong:String[] 				{nosave}	'array of daynames (long version)
	Field DoorOpenTime:Int				= 100	{nosave}	'time how long a door will be shown open until figure enters

	Field username:String				= ""	{nosave}	'username of the player ->set in config
	Field userport:Short				= 4544	{nosave}	'userport of the player ->set in config
	Field userchannelname:String		= ""	{nosave}	'channelname the player uses ->set in config
	Field userlanguage:String			= "de"	{nosave}	'language the player uses ->set in config
	Field userdb:String					= ""	{nosave}
	Field userfallbackip:String			= "" 	{nosave}

	Field Players:TPlayer[5]
	Field playerCount:int			= 4

	Field speed:Float				= 1.0 					'Speed of the game in "game minutes per real-time second"
	Field oldspeed:Float			= 1.0 					'Speed of the game - used when saving a game ("pause")
	Field minutesOfDayGone:Float	= 0.0					'time of day in game, unformatted
	Field lastMinutesOfDayGone:Float= 0.0					'time last update was done
	Field timeGone:Double			= 0.0					'time (minutes) in game, not reset every day
	Field timeStart:Double			= 0.0					'time (minutes) used when starting the game
	Field daysPlayed:Int			= 0
	Const daysPerYear:Int			= 14 					'5 weeks
	Field daytoplan:Int 			= 0						'which day has to be shown in programmeplanner

	Field title:String 				= "MyGame"				'title of the game

	Field cursorstate:Int		 	= 0 					'which cursor has to be shown? 0=normal 1=dragging
	Field playerID:Int 				= 1						'playerID of player who sits in front of the screen
	Field error:Int 				= 0 					'is there a error (errorbox) floating around?
	Field gamestate:Int 			= 0						'0 = Mainmenu, 1=Running, ...

	Field stateSyncTime:Int			= 0						'last sync
	Field stateSyncTimer:Int		= 2000					'sync every

	'--networkgame auf "isNetworkGame()" umbauen
	Field networkgame:Int 			= 0 					'are we playing a network game? 0=false, 1=true, 2
	Field networkgameready:Int 		= 0 					'is the network game ready - all options set? 0=false
	Field onlinegame:Int 			= 0 					'playing over internet? 0=false

	'used so that random values are the same on all computers having the same seed value
	field randomSeedValue:int		= 0


	'Summary: saves the GameObject to a XMLstream
	Function REMOVE_Save:Int()
		LoadSaveFile.xmlBeginNode("GAMESETTINGS")
		Local typ:TTypeId = TTypeId.ForObject(Game)
		For Local t:TField = EachIn typ.EnumFields()
			If t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal"
				LoadSaveFile.xmlWrite(Upper(t.Name()), String(t.Get(Game)))
			EndIf
		Next
		LoadSaveFile.xmlCloseNode()
	End Function

	'Summary: loads the GameObject from a XMLstream
	Function REMOVE_Load:Int()
Print "implement TGame:Load"
Return 0
Rem
		PrintDebug("TGame.Load()", "Lade Spieleinstellungen", DEBUG_SAVELOAD)
		Local NODE:xmlNode = LoadSaveFile.NODE.FirstChild()
		Local nodevalue:String
		While NODE <> Null
			nodevalue = ""
			If NODE.hasAttribute("var", False) Then nodevalue = NODE.Attribute("var").Value
			Local typ:TTypeId = TTypeId.ForObject(Game)
			For Local t:TField = EachIn typ.EnumFields()
				If (t.MetaData("saveload") = "normal" Or t.MetaData("saveload") <> "nosave") And Upper(t.Name()) = NODE.Name
					t.Set(Game, nodevalue)
				EndIf
			Next
			NODE = NODE.nextSibling()
		Wend
endrem
	End Function

	'Summary: saves all objects of the game (figures, quotes...)
	Function SaveGame:Int(savename:String="savegame.xml")
		LoadSaveFile.InitSave()   'opens a savegamefile for getting filled
		For Local i:Int = 1 To 4
			If Game.Players[i] <> Null
				If Game.Players[i].PlayerKI = Null And Game.Players[i].figure.controlledbyID = 0 Then PrintDebug ("TGame.Update()", "FEHLER: KI fuer Spieler " + i + " nicht gefunden", DEBUG_UPDATES)
				If Game.Players[i].figure.isAI()
					LoadSaveFile.xmlWrite("KI"+i, Game.Players[i].PlayerKI.CallOnSave())
				EndIf
			EndIf
		Next
		LoadSaveFile.SaveObject(Game, "GAMESETTINGS", Null) ; TError.DrawErrors() ;Flip 0  'XML
		LoadSaveFile.SaveObject(TFigures.List, "FIGURES", TFigures.AdditionalSave) ; TError.DrawErrors() ;Flip 0  'XML
		LoadSaveFile.SaveObject(TPlayer.List, "PLAYERS", TFigures.AdditionalSave) ; TError.DrawErrors() ;Flip 0  'XML

		TStationMap.SaveAll();				TError.DrawErrors();Flip 0  'XML
'		TAudienceQuotes.SaveAll();			TError.DrawErrors();Flip 0  'XML
'		TProgramme.SaveAll();	 			TError.DrawErrors();Flip 0  'XML
'		TContract.SaveAll();	  			TError.DrawErrors();Flip 0  'XML
'		TNews.SaveAll();	  				TError.DrawErrors();Flip 0  'XML
		TProgrammeBlock.SaveAll();			TError.DrawErrors();Flip 0  'XML
'		TAdBlock.SaveAll();					TError.DrawErrors();Flip 0  'XML
'		TNewsBlock.SaveAll();				TError.DrawErrors();Flip 0  'XML
		Building.Elevator.Save();			TError.DrawErrors();Flip 0  'XML
		'Delay(50)
		LoadSaveFile.xmlWrite("ENDSAVEGAME", "CHECKSUM")
		'LoadSaveFile.file.setCompressMode(9)
		LoadSaveFile.xmlSave("savegame.zip", True)
		'LoadSaveFile.file.Free()
	End Function

	'Summary: loads all objects of the games (figures, programme...)
	Function LoadGame:Int(savename:String="save")
		PrintDebug("TGame.LoadGame()", "Leere Listen", DEBUG_SAVELOAD)
		TError(TError.List.Last()).message = "Leere Listen...";TError.DrawErrors() ;Flip 0
		PrintDebug("TGame.LoadGame()", "Lade Spielstandsdatei", DEBUG_SAVELOAD)
		TError.DrawNewError("Lade Spielstandsdatei...")
		LoadSaveFile.InitLoad("savegame.zip", True)
		If LoadSaveFile.xml.file = Null
			PrintDebug("TGame.LoadGame()", "Spielstandsdatei defekt!", DEBUG_SAVELOAD)
			TError.DrawNewError("Spielstandsdatei defekt!...") ;Delay(2500)
		Else
			Local NodeList:TList = LoadSaveFile.node.getChildren()
			For Local NODE:TxmlNode = EachIn NodeList
				LoadSaveFile.NODE = NODE
				Select LoadSaveFile.NODE.getName()
					Case "KI1"
						Game.Players[1].PlayerKI.CallOnLoad(LoadSaveFile.NODE.getContent())
					Case "KI2"
						Game.Players[2].PlayerKI.CallOnLoad(LoadSaveFile.NODE.getContent())
					Case "KI3"
						Game.Players[3].PlayerKI.CallOnLoad(LoadSaveFile.NODE.getContent())
					Case "KI4"
						Game.Players[4].PlayerKI.CallOnLoad(LoadSaveFile.NODE.getContent())
					Case "GAMESETTINGS"
						TError.DrawNewError("Lade Basiseinstellungen...")
						TGame.REMOVE_Load()
					Case "ALLFIGURES"
						TError.DrawNewError("Lade Spielfiguren...")
						TFigures.LoadAll()
					Case "ALLPLAYERS"
						TError.DrawNewError("Lade Spieler...")
						TPlayer.LoadAll()
					Case "ALLSTATIONMAPS"
						TError.DrawNewError("Lade Senderkarten...")
						TStationMap.LoadAll()
'					Case "ALLAUDIENCEQUOTES"
'						TError.DrawNewError("Lade Quotenarchiv...")
'						TAudienceQuotes.LoadAll()
'					Case "ALLPROGRAMMES"
'						TError.DrawNewError("Lade Programme...")
'						TProgramme.LoadAll()
'					Case "ALLCONTRACTS"
'						TError.DrawNewError("Lade Werbeverträge...")
					'TContract.LoadAll()
'					Case "ALLNEWS"
'						TError.DrawNewError("Lade Nachrichten...")
					'TNews.LoadAll()
					Case "ALLCONTRACTBLOCKS"
						TError.DrawNewError("Lade Werbeverträgeblöcke...")
					'TContractBlock.LoadAll()
					Case "ALLPROGRAMMEBLOCKS"
						TError.DrawNewError("Lade Programmblöcke...")
					'TProgrammeBlock.LoadAll()
					Case "ALLADBLOCKS"
						TError.DrawNewError("Lade Werbeblöcke...")
					'TAdBlock.LoadAll()
					Case "ALLNEWSBLOCKS"
						TError.DrawNewError("Lade Newsblöcke...")
					'TNewsBlock.LoadAll()
					Case "ALLMOVIEAGENCYBLOCKS"
						TError.DrawNewError("Lade Filmhändlerblöcke...")
					'TMovieAgencyBlocks.LoadAll()
					Case "ELEVATOR"
						TError.DrawNewError("Lade Fahrstuhl...")
					'building.elevator.Load()
				End Select
			Next
			Print "verarbeite savegame OK"
			'			LoadSaveFile.file.Free()
		EndIf
	End Function

	'Summary: create a game, every variable is set to Zero
	Function Create:TGame()
		Local Game:TGame=New TGame
		Game.LoadConfig("config/settings.xml")
		Localization.AddLanguages("de, en") 'adds German and English to possible language
		Localization.SetLanguage(Game.userlanguage) 'selects language
		Localization.LoadResource("res/lang/lang_"+Game.userlanguage+".txt")
		Game.networkgame		= 0
		Game.minutesOfDayGone	= 0

		Game.timeGone			= Game.MakeTime(1985,1,0,0)
		Game.timeStart			= Game.MakeTime(1985,1,0,0)
		Game.dayToPlan			= Game.GetDay()
		Game.title				= "unknown"

		Game.SetRandomizerBase( Millisecs() )
		
		Game.PopularityManager = TPopularityManager.Create()		
		Game.BroadcastManager = TBroadcastManager.Create()

		Return Game
	End Function

	'returns how many game minutes equal to one real time second
	Method GetGameMinutesPerSecond:float()
		return self.speed
	End Method
	'returns how many seconds pass for one game minute
	Method GetSecondsPerGameMinute:float()
		return 1.0 / self.speed
	End Method

	Method GetRandomizerBase:int()
		return self.randomSeedValue
	End Method

	Method SetRandomizerBase( value:int=0 )
		self.randomSeedValue = value
		'seed the random base for MERSENNE TWISTER (seedrnd for the internal one)
		SeedRand( self.randomSeedValue )
		print "setRandomizerBase - first random is: "+RandRange(0,10000)
	End Method

	Method Initialize()
		Game.PopularityManager.Initialize()
		Game.BroadcastManager.Initialize()
		
		CreateInitialPlayers()
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
		Self.Players[1] = TPlayer.Create(Self.username	,Self.userchannelname	,Assets.GetSprite("Player1"),	250,  2, 90, TColor.getByOwner(0), 1, "Player 1")
		Self.Players[2] = TPlayer.Create("Alfie"		,"SunTV"				,Assets.GetSprite("Player2"),	280,  5, 90, TColor.getByOwner(0), 0, "Player 2")
		Self.Players[3] = TPlayer.Create("Seidi"		,"FunTV"				,Assets.GetSprite("Player3"),	240,  8, 90, TColor.getByOwner(0), 0, "Player 3")
		Self.Players[4] = TPlayer.Create("Sandra"		,"RatTV"				,Assets.GetSprite("Player4"),	290, 13, 90, TColor.getByOwner(0), 0, "Player 4")
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
		Return (number>0 And number<=Self.playerCount And Self.Players[number] <> Null)
	End Method

	Method IsHumanPlayer:Int(number:Int)
		Return (Self.IsPlayer(number) And Not Players[number].figure.IsAI())
	End Method
	'the negative of "isHumanPlayer" - also "no human player" is possible
	Method IsAIPlayer:Int(number:Int)
		Return (Self.IsPlayer(number) And Players[number].figure.IsAI())
	End Method

	Method IsLocalPlayer:Int(number:Int)
		Return number = Self.playerID
	End Method

	Method SetGameState:Int( gamestate:Int )
		If Self.gamestate = gamestate Then Return True

		Self.gamestate = gamestate
		Select gamestate
			Case GAMESTATE_RUNNING
					'Begin Game - create Events
					EventManager.registerEvent( TEventOnTime.Create("Game.OnMinute", game.GetMinute()) )
					EventManager.registerEvent( TEventOnTime.Create("Game.OnHour", game.GetHour()) )
					EventManager.registerEvent( TEventOnTime.Create("Game.OnDay", Game.GetDay()) )

					'so we could add news etc.
					EventManager.triggerEvent( TEventSimple.Create("Game.OnStart") )

					Soundmanager.PlayMusic(MUSIC_MUSIC)
			Default
				'
		EndSelect
	End Method

	Method GetPlayer:TPlayer(playerID:int=-1)
		if playerID=-1 then playerID=self.playerID
		if not Game.isPlayer(playerID) then return Null

		return self.players[playerID]
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

	'Summary: load the config-file and set variables depending on it
	Method LoadConfig:Byte(configfile:String="config/settings.xml")
		Local xml:TxmlHelper = TxmlHelper.Create(configfile)
		If xml <> Null Then PrintDebug ("TGame.LoadConfig()", "settings.xml eingelesen", DEBUG_LOADING)
		Local node:TxmlNode = xml.FindRootChild("settings")
		If node = Null Or node.getName() <> "settings"
			Print "settings.xml fehlt der settings-Bereich"
			Return 0
		EndIf
		Self.username			= xml.FindValue(node,"username", "Ano Nymus")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'username' fehlt, setze Defaultwert: 'Ano Nymus'", DEBUG_LOADING)
		Self.userchannelname	= xml.FindValue(node,"channelname", "SunTV")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'userchannelname' fehlt, setze Defaultwert: 'SunTV'", DEBUG_LOADING)
		Self.userlanguage		= xml.FindValue(node,"language", "de")			'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'language' fehlt, setze Defaultwert: 'de'", DEBUG_LOADING)
		Self.userport			= xml.FindValueInt(node,"onlineport", 4444)		'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'onlineport' fehlt, setze Defaultwert: '4444'", DEBUG_LOADING)
		Self.userdb				= xml.FindValue(node,"database", "res/database.xml")	'Print "settings.xml - missing 'database' - set to default: 'database.xml'"
		Self.title				= xml.FindValue(node,"defaultgamename", "MyGame")		'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'defaultgamename' fehlt, setze Defaultwert: 'MyGame'", DEBUG_LOADING)
		Self.userfallbackip		= xml.FindValue(node,"fallbacklocalip", "192.168.0.1")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'fallbacklocalip' fehlt, setze Defaultwert: '192.168.0.1'", DEBUG_LOADING)
	End Method

	Method GetNextHour:Int() {_exposeToLua}
		Local nextHour:Int = Self.GetHour()+1
		If nextHour > 24 Then Return nextHour - 24
		Return nextHour
	End Method

	'Summary: Updates Time, Costs, States ...
	Method Update(deltaTime:Float=1.0)
		'speed is given as a factor "game-time = x * real-time"
		Self.minutesOfDayGone	:+ deltaTime * self.GetGameMinutesPerSecond()
		Self.timeGone			:+ deltaTime * self.GetGameMinutesPerSecond()

		'time for news ?
		If NewsAgency.NextEventTime < Self.timeGone Then NewsAgency.AnnounceNewNewsEvent()
		If NewsAgency.NextChainCheckTime < Self.timeGone Then NewsAgency.ProcessNewsEventChains()

		'send state to clients
		If IsGameLeader() And Self.networkgame And Self.stateSyncTime < MilliSecs()
			NetworkHelper.SendGameState()
			Self.stateSyncTime = MilliSecs() + Self.stateSyncTimer
		EndIf

		'if speed to high - potential skip of minutes, so "fetch them"
		'sets minute / hour / day
		Local missedMinutes:Int = Floor(Self.minutesOfDayGone - Self.lastMinutesOfDayGone)
		If missedMinutes = 0 Then Return

		Local minute:Int	= 0
		Local hour:Int		= 0
		For Local i:Int = 1 To missedMinutes
			minute = (Floor(Self.lastMinutesOfDayGone)  + i ) Mod 60 '0 to 59
			EventManager.triggerEvent(TEventOnTime.Create("Game.OnMinute", minute))

			'hour
			If minute = 0
				hour = Floor( (Self.lastMinutesOfDayGone + i) / 60) Mod 24 '0 after midnight
				EventManager.triggerEvent(TEventOnTime.Create("Game.OnHour", hour))
			EndIf

			'day
			If hour = 0 And minute = 0
				Self.minutesOfDayGone 	= 0			'reset minutes of day
				Self.daysPlayed			:+1			'increase current day
			 	'automatically change current-plan-day on day change
				Self.dayToPlan 			= Self.getDay()
				EventManager.triggerEvent(TEventOnTime.Create("Game.OnDay", Self.GetDay()))
			EndIf
		Next
		Self.lastMinutesOfDayGone = Floor(Self.minutesOfDayGone)
	End Method

	'Summary: returns day of the week including gameday
	Method GetFormattedDay:String(_day:Int = -5) {_exposeToLua}
		Return _day+"."+GetLocale("DAY")+" ("+Self.GetDayName( Max(0,_day-1) Mod 7, 0)+ ")"
	End Method

	Method GetFormattedDayLong:String(_day:Int = -1) {_exposeToLua}
		If _day < 0 Then _day = Self.GetDay()
		Return Self.GetDayName( Max(0,_day-1) Mod 7, 1)
	End Method

	'Summary: returns formatted value of actual gametime
	Method GetFormattedTime:String(time:Double=0) {_exposeToLua}
		Local strHours:String = Self.GetHour(time)
		Local strMinutes:String = Self.GetMinute(time)

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
		If _time = 0 Then _time = Self.timeGone
		_time = Floor(_time / (24 * 60 * Self.daysPerYear))
		Return Int(_time)
	End Method

	Method GetDayOfYear:Int(_time:Double = 0) {_exposeToLua}
		Return (Self.GetDay(_time) - Self.GetYear(_time)*Self.daysPerYear)
	End Method

	'get the amount of days played (completed! - that's why "-1")
	Method GetDaysPlayed:int() {_exposeToLua}
		return self.GetDay(self.timeGone - Self.timeStart) - 1
	End Method

	Method GetDay:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = Self.timeGone
		_time = Floor(_time / (24 * 60))
		'we are ON a day (it is not finished yet)
		'if we "ceil" the time, we would ignore 1.0 as this would
		'not get rounded to 2.0 like 1.01 would do
		Return 1 + Int(_time)
	End Method

	Method GetHour:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = Self.timeGone
		'remove days from time
		_time = _time Mod (24*60)
		'hours = how many times 60 minutes fit into rest time
		Return Int(Floor(_time / 60))
	End Method

	Method GetMinute:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = Self.timeGone
		'remove days from time
		_time = _time Mod (24*60)
		'minutes = rest not fitting into hours
		Return Int(_time) Mod 60
	End Method
End Type

'TODO [ron]: needed?
Type PacketTypes
	Global PlayerState:Byte				= 6					' Player Name, Position...
End Type

'class holding name, channelname, infos about the figure, programmeplan, programmecollection and so on - from a player
Type TPlayer {_exposeToLua="selected"}
	Field Name:String 										{saveload = "normal"}		'playername
	Field channelname:String 								{saveload = "normal"} 		'name of the channel
	Field finances:TFinancials[7]														'One week of financial stats about credit, money, payments ...
	'Field audience:Int 			= 0 						{saveload = "normal"}		'general audience
	'Field audience2:TAudience	= new TAudience
	'Field maxAudience2:TAudience
	Field audience:TAudienceResult	
	
	Field ProgrammeCollection:TPlayerProgrammeCollection	{_exposeToLua}
	Field ProgrammePlan:TPlayerProgrammePlan				{_exposeToLua}
	Field StationMap:TStationMap							{_exposeToLua}
	Field Figure:TFigures									{_exposeToLua}				'actual figure the player uses
	Field playerID:Int 			= 0							{saveload = "normal"}		'global used ID of the player
	Field color:TColor																	'the color used to colorize symbols and figures
	Field figurebase:Int 		= 0							{saveload = "normal"}		'actual number of an array of figure-images
	Field networkstate:Int 		= 0							{saveload = "normal"}		'1=ready, 0=not set, ...
	Field newsabonnements:Int[6]							{_private}					'abonnementlevels for the newsgenres
	Field PlayerKI:KI			= Null						{_private}
	Global globalID:Int			= 1							{_private}
	Global List:TList = CreateList()						{_private}
	Field CreditCurrent:Int = 200000						{_private}
	Field CreditMaximum:Int = 300000						{_private}

	Function getByID:TPlayer( playerID:Int = 0)
		For Local player:TPlayer = EachIn TPlayer.list
			If playerID = player.playerID Then Return player
		Next
		Return Null
	End Function
	
	Function Current:TPlayer()
		Return TPlayer.getByID(Game.playerID)
	End Function

	Function Load:Tplayer(pnode:TxmlNode)
Print "implement Load:Tplayer"
Return Null
Rem
		Local Player:TPlayer = TPlayer.Create("save", "save", Assets.GetSpritePack("figures").GetSprite("Man1") , 0, 0, 0, 0, 0, 0, 1, "")
		TFigures.List.Remove(Player.figure)
		Local i:Int = 0, j:Int = 0
		Local col:TColor = null
		Local FigureID:Int = 0

		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").Value
			Local typ:TTypeId = TTypeId.ForObject(Player)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" And Upper(t.Name()) = NODE.Name
					t.Set(Player, nodevalue)
				EndIf
			Next
			Select NODE.Name
				Case "FINANCE" Player.finances[i].Create(Player.PlayerID, 550000, 2500000) ;Player.finances[i].Load(NODE, Player.finances[i] ) ;i:+1
				Case "COLOR" col = TColor.FromInt(nodevalue)
				Case "FIGUREID" FigureID = Int(nodevalue)
				Case "NEWSABONNEMENTS0" Or "NEWSABONNEMENTS1" Or "NEWSABONNEMENTS2" Or "NEWSABONNEMENTS3" Or "NEWSABONNEMENTS4" Or "NEWSABONNEMENTS5"
					If TNewsbuttons.GetButton(j, Player.playerID) <> Null Then TNewsbuttons.GetButton(j, Player.playerID).clickstate = Player.newsabonnements[j] ;j:+1
			End Select
			Node = Node.NextSibling()
		Wend
		Player.color = TColor.getFromListObj(col)
		Game.Players[Player.playerID] = Player  '.player is player in root-scope
		Player.Figure = TFigures.GetByID( FigureID )
		If Player.figure.controlledByID = 0 And Game.playerID = 1 Then
			PrintDebug("TPlayer.Load()", "Lade AI für Spieler" + Player.playerID, DEBUG_SAVELOAD)
			Player.playerKI = KI.Create(Player.playerID, "res/ai/DefaultAIPlayer.lua")
		EndIf
		Player.Figure.ParentPlayer = Player
		Player.UpdateFigureBase(Player.figurebase)
		Player.RecolorFigure(Player.color)
		Return Player
endrem
	End Function

	Function LoadAll()
		TPlayer.List.Clear()
		Game.Players[1] = Null;Game.Players[2] = Null;Game.Players[3] = Null;Game.Players[4] = Null;
		TPlayer.globalID = 1
		TFinancials.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.getChildren()
		For Local node:txmlNode = EachIn Children
			If NODE.getName() = "PLAYER" Then TPlayer.Load(NODE)
		Next
		'Print "loaded player informations"
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLPLAYERS")
		For Local Player:TPlayer = EachIn TPlayer.List
			If Player<> Null Then Player.Save()
		Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("PLAYER")
		Local typ:TTypeId = TTypeId.ForObject(Self)
		For Local t:TField = EachIn typ.EnumFields()
			If t.MetaData("saveload") = "normal"
				LoadSaveFile.xmlWrite(Upper(t.Name()), String(t.Get(Self)))
			EndIf
		Next
		For Local i:Int = 0 To 6
			Self.finances[i].Save()
		Next
		LoadSaveFile.xmlWrite("COLOR",		Self.color.ToInt())
		LoadSaveFile.xmlWrite("FIGUREID",	Self.figure.id)
		For Local j:Int = 0 To 5
			LoadSaveFile.xmlWrite("NEWSABONNEMENTS"+j,	Self.newsabonnements[j])
		Next
		LoadSaveFile.xmlCloseNode()
	End Method

	Method GetPlayerID:Int() {_exposeToLua}
		Return Self.playerID
	End Method

	Method IsAI:Int() {_exposeToLua}
		'return self.playerKI <> null
		Return Self.figure.IsAI()
	End Method

	Method GetFinancial:TFinancials(weekday:int=-1)
		return self.finances[Game.GetWeekday(weekday)]
	End Method

	Method GetMaxAudience:int() {_exposeToLua}
		return self.Stationmap.GetReach()
	End Method

	Method isInRoom:int(roomName:string="", checkFromRoom:int=FALSE) {_exposeToLua}
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
	Function Create:TPlayer(Name:String, channelname:String = "", sprite:TGW_Sprites, x:Int, onFloor:Int = 13, dx:Int, color:TColor, ControlledByID:Int = 1, FigureName:String = "")
		Local Player:TPlayer		= New TPlayer
		EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Create Player").AddNumber("itemNumber", globalID).AddNumber("maxItemNumber", 4) ) )

		Player.Name					= Name
		Player.playerID				= globalID
		Player.color				= color.AddToList(True).SetOwner(TPlayer.globalID)
		Player.channelname			= channelname
		Player.Figure				= New TFigures.CreateFigure(FigureName, sprite, x, onFloor, dx, ControlledByID)
		Player.Figure.ParentPlayer	= Player
		For Local i:Int = 0 To 6
			Player.finances[i] = TFinancials.Create(Player.playerID, 550000, 250000)
		Next
		Player.ProgrammeCollection	= TPlayerProgrammeCollection.Create(Player)
		Player.ProgrammePlan		= TPlayerProgrammePlan.Create(Player)
		Player.StationMap			= TStationMap.Create(Player)
'		Player.RecolorFigure(Player.color.GetUnusedColor(globalID))
		Player.RecolorFigure(Player.color)
		Player.UpdateFigureBase(0)
		Player.globalID:+1

		List.AddLast(Player)
		List.sort()

		Return Player
	End Function

	Method SetAIControlled(luafile:String="")
		Self.figure.controlledByID = 0
		Self.PlayerKI = KI.Create(Self.playerID, luafile)
	End Method

	'loads a new figurbase and colorizes it
	Method UpdateFigureBase(newfigurebase:Int)
		Local figureCount:Int = 12
		If newfigurebase > figureCount - 1 Then newfigurebase = 0
		If newfigurebase < 0 Then newfigurebase = figureCount - 1
		figurebase = newfigurebase

		Local tmpSprite:TGW_Sprites = Assets.GetSpritePack("figures").GetSprite("Player" + Self.playerID)
		Local tmppix:TPixmap = LockImage(Assets.GetSpritePack("figures").image, 0)
		'clear area in all-figures-image
		tmppix.Window(tmpSprite.Pos.x, tmpSprite.Pos.y, tmpSprite.w, tmpSprite.h).ClearPixels(0)
		DrawOnPixmap(ColorizeTImage(Assets.GetSpritePack("figures").GetSpriteImage("", figurebase, False), color), 0, tmppix, tmpSprite.Pos.x, tmpSprite.Pos.y)
		'unlock not needed as doing nothing
		'UnlockImage(Assets.GetSpritePack("figures").image, 0)
	End Method

	'colorizes a figure and the corresponding sign next to the players doors in the building
	Method RecolorFigure(newColor:TColor = Null)
		If newColor = Null Then newColor = Self.color
		Self.color.ownerID	= 0
		Self.color			= newColor
		Self.color.ownerID	= playerID
		UpdateFigureBase(figurebase)
		'overwrite asset
		Assets.AddImageAsSprite( "gfx_building_sign"+String(playerID), ColorizeTImage(Assets.GetSprite("gfx_building_sign_base").getImage(), color) )
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

	Method GetNewsAbonnementDelay:int(genre:int) {_exposeToLua}
		return 60*(3-self.newsabonnements[genre])
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
rem
	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetRelativeAudiencePercentage:Float(playerID:Int) {_exposeToLua}		
		Return TAudienceResult.Curr(playerID).AudienceQuote.GetAverage()
	End Method
endrem

	'returns value chief will give as credit
	Method GetCreditAvailable:Int() {_exposeToLua}
		Return Max(0, Self.CreditMaximum - Self.CreditCurrent)
	End Method

	Method GetCreditCurrent:Int() {_exposeToLua}
		Return Self.CreditCurrent
	End Method

	'helper to call from external types - only for current game.playerID-Player
	Function extSetCredit:String(amount:Int)
		Game.Players[Game.playerID].SetCredit(amount)
	End Function

	'increases Credit
	Method SetCredit(amount:Int)
		Self.finances[Game.getWeekday()].TakeCredit(amount)
		Self.CreditCurrent:+amount
	End Method

	'computes daily costs like station or newsagency fees for every player
	Function ComputeDailyCosts()
		Local playerID:Int = 1
		For Local Player:TPlayer = EachIn TPlayer.List
			'stationfees
			Player.finances[Game.getWeekday()].PayStationFees( Player.StationMap.CalculateStationCosts(playerID))

			'newsagencyfees
			Local newsagencyfees:Int =0
			For Local i:Int = 0 To 5
				newsagencyfees:+ Player.newsabonnements[i]*10000 'baseprice for an subscriptionlevel
			Next
			Player.finances[Game.getWeekday()].PayNewsAgencies((newsagencyfees/2))

			playerID :+1
		Next
	End Function

	'computes ads - if a adblock is botched or run successful
	'if successfull and ad-contract finished then it sells the ad (earn money)
	Function ComputeAds()
		Local Adblock:TAdBlock
		For Local Player:TPlayer = EachIn TPlayer.List
			Adblock = Player.ProgrammePlan.GetCurrentAdBlock()
			'skip if no ad is send at the moment
			If Not Adblock Then Continue

			'ad failed (audience lower than needed)
			If Player.audience.Audience.GetSum() < Adblock.contract.GetMinAudience()
				Adblock.SetBotched(1)
			'ad is ok
			Else
				Adblock.SetBotched(0)
				'successful sent - so increase the value the contract
				AdBlock.contract.spotsSent:+1

				'successful sent all needed spots?
				If Adblock.contract.GetSpotsToSend()<=0
					'set contract fulfilled
					Adblock.contract.state = 1

					'give money
					Player.finances[Game.getWeekday()].earnAdProfit(Adblock.contract.GetProfit() )

					'removes Blocks which are more than needed (eg 3 of 2 to be shown Adblocks)
					AdBlock.RemoveOverheadAdblocks()

					'remove contract from collection (and suitcase)
					'contract is still stored within adblocks (until they get deleted)
					Player.ProgrammeCollection.RemoveAdContract(Adblock.contract)
				EndIf
			EndIf
		Next
	End Function

	'end of day - take over money for next day
	Function TakeOverMoney()
		Local dayBefore:Int = Game.getWeekday( Game.getDay()-1 )
		For Local Player:TPlayer = EachIn TPlayer.List
			TFinancials.TakeOverFinances( Player.finances[ dayBefore ], Player.finances[Game.getWeekday()] )
		Next
	End Function

	'computes penalties for expired ad-contracts
	Function ComputeContractPenalties()
		For Local Player:TPlayer = EachIn TPlayer.List
			For Local Contract:TAdContract = EachIn Player.ProgrammeCollection.AdContractlist
				If Not contract Then Continue

				If contract.GetDaysLeft() <= 0
					Player.finances[Game.getWeekday()].PayPenalty(contract.GetPenalty() )
					Player.ProgrammeCollection.RemoveAdContract(contract)
					TAdBlock.RemoveAdblocks(contract, Game.GetDay())
					'Print Player.name+" paid a penalty of "+contract.calculatedPenalty+" for contract:"+contract.title
				EndIf
			Next
		Next
	End Function

	'computes audience depending on ComputeAudienceQuote and if the time is the same
	'as for the last block of a programme, it decreases the topicality of that programme
	Function ComputeAudience(recompute:Int = FALSE)
		Game.BroadcastManager.BroadcastProgramme()
	End Function

	'computes newsshow-audience
	Function ComputeNewsAudience()
		Game.BroadcastManager.BroadcastNews()
	rem
		Local newsBlock:TNewsBlock
		For Local Player:TPlayer = EachIn TPlayer.List
			Local audience:Int = 0

			if Player.GetMaxaudience() > 0
				local leadinAudience:int = 0
				local slotaudience:int[] = [int(Player.audience2.GetSum()),0,0,0]
				'in the "0"-position of the index, we store the previous audience
				'so that the result of each news is based on a leadin of the previous
				'so "holes" cut the news reach :D
				for local i:int = 1 to 3
					news = Player.ProgrammePlan.GetNews(i-1)
					If news
						leadinAudience = 0.5 * Player.audience2.GetSum() + 0.5 * slotaudience[i-1]
						slotaudience[i] = Floor(Player.GetMaxaudience() * news.newsEvent.getAudienceQuote(leadinAudience/Player.GetMaxaudience())  / 1000)*1000
						'print "leadinAudience "+i+": "+leadinAudience + " slotaudience:"+slotaudience[i]
					endif

					'different weight for news slots
					if i=1 then audience :+ 0.5 * slotaudience[i]
					if i=2 then audience :+ 0.3 * slotaudience[i]
					if i=3 then audience :+ 0.2 * slotaudience[i]
					'If Player.playerID = 1 Print "Newsaudience for News: "+i+" - "+audience
				Next
			Endif
			Player.audience2 = TAudience.CreateWithBreakdown(Ceil(audience))
			TAudienceQuotes.Create("News: "+ Game.GetHour()+":00", Int(Player.audience2.GetSum()), Game.GetHour(),Game.GetMinute(),Game.GetDay(), Player.playerID)
		Next
		endrem
	End Function

	'nothing up to now
	Method Update:Int()
		''
	End Method

	'returns formatted value of actual money
	'gibt einen formatierten Wert des aktuellen Geldvermoegens zurueck
	Method GetMoneyFormatted:String()
		Return functions.convertValue(String(Self.finances[Game.getWeekday()].money), 2, 0)
	End Method

	Method GetMoney:Int() {_exposeToLua}
		Return Self.finances[Game.getWeekday()].money
	End Method

	'returns formatted value of actual credit
	Method GetCreditFormatted:String()
		Return functions.convertValue(String(Self.finances[Game.getWeekday()].credit), 2, 0)
	End Method

	Method GetCredit:Int() {_exposeToLua}
		Return Self.finances[Game.getWeekday()].credit
	End Method

	Method GetAudience:Int() {_exposeToLua}
		Return Self.audience.Audience.GetSum()
	End Method


	'returns formatted value of actual audience
	'gibt einen formatierten Wert der aktuellen Zuschauer zurueck
	Method GetFormattedAudience:String() {_exposeToLua}
		Return functions.convertValue(String(Self.audience.Audience.GetSum()), 2, 0)
	End Method

	Method Compare:Int(otherObject:Object)
		Local s:TPlayer = TPlayer(otherObject)
		If Not s Then Return 1
		If s.playerID > Self.playerID Then Return 1
		Return 0
	End Method
End Type

'holds data of WHAT has been bought, which amount of money was used and so on ... for 7 days
'containts methods for refreshing stats when paying or selling something
Type TFinancials
	Field paid_movies:Int 			= 0
	Field paid_stations:Int 		= 0
	Field paid_scripts:Int 			= 0
	Field paid_productionstuff:Int 	= 0
	Field paid_penalty:Int 			= 0
	Field paid_rent:Int 			= 0
	Field paid_news:Int 			= 0
	Field paid_newsagencies:Int 	= 0
	Field paid_stationfees:Int 		= 0
	Field paid_misc:Int 			= 0
	Field paid_total:Int 			= 0

	Field sold_movies:Int 			= 0
	Field sold_ads:Int 				= 0
	Field callerRevenue:Int			= 0
	Field sold_misc:Int				= 0
	Field sold_total:Int			= 0
	Field sold_stations:Int			= 0
	Field revenue_interest:Int		= 0
	Field revenue_before:Int 		= 0
	Field revenue_after:Int 		= 0
	Field money:Int					= 0
	Field credit:Int 				= 0
	Field playerID:Int 				= 0
	Field ListLink:TLink {saveload = "special" sl = "no"}
	Global List:TList = CreateList() {saveload = "special" sl = "no"}

	Global debug:Int = 0

	Function Load:TFinancials(pnode:txmlNode, finance:TFinancials)
Print "implement Load:TFinancials"
Return Null
Rem
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").Value
			Local typ:TTypeId = TTypeId.ForObject(finance)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "special" And Upper(t.Name()) = NODE.Name
					t.Set(finance, nodevalue)
				EndIf
			Next
			Node = Node.NextSibling()
		Wend
		Return finance
endrem
	End Function

	'not used - implemented in player-class
	Function LoadAll()
		TFinancials.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.getChildren()
		For Local NODE:txmlNode = EachIn Children
			If NODE.getName() = "FINANCE"
				Local finance:TFinancials = New TFinancials
				finance = TFinancials.Load(NODE, finance)
				finance.ListLink = TFinancials.List.AddLast(finance)
			End If
		Next
		Print "loaded finance-information"
	End Function

	Function SaveAll()
		TFinancials.List.Sort()
		LoadSaveFile.xmlBeginNode("FINANCIALS")
		For Local finance:TFinancials = EachIn TFinancials.List
			If finance <> Null Then finance.Save()
		Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("FINANCE")
		Local typ:TTypeId = TTypeId.ForObject(Self)
		For Local t:TField = EachIn typ.EnumFields()
			If t.MetaData("saveload") <> "special"
				LoadSaveFile.xmlWrite(Upper(t.Name()), String(t.Get(Self)))
			EndIf
		Next
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Create:TFinancials(playerID:Int, startmoney:Int=550000, startcredit:Int = 250000)
		Local finances:TFinancials = New TFinancials
		finances.money			= startmoney
		finances.revenue_before	= startmoney
		finances.revenue_after	= startmoney

		finances.credit			= startcredit
		finances.playerID		= playerID
		finances.ListLink		= List.AddLast(finances)
		Return finances
	End Function

	'take the current balance (money and credit) to the next day
	Function TakeOverFinances:Int(dayBeforeFinance:TFinancials, currentFinance:TFinancials var)
		'remove current finance from financials.list as we create a new one
		currentFinance.ListLink.remove()
		'create the new financial but give the yesterdays money/credit
		currentFinance = TFinancials.Create(dayBeforeFinance.playerID, dayBeforeFinance.money, dayBeforeFinance.credit)
	End Function

	'returns whether the finances allow the given transaction
	Method CanAfford:int(_money:int=0)
		return (self.money > 0 AND self.money >= _money)
	End Method

	'refreshs stats about misc sells
	Method SellMisc(_money:Int)
		If debug Then Print "FINANZ: player :"+Self.playerID+" MISC : "+_money
		sold_ads	:+_money
		sold_total	:+_money
		ChangeMoney(_money)
	End Method

	Method SellStation:Int(_money:Int)
		Self.sold_stations:+_money
		Self.sold_total:+money
		ChangeMoney(+ _money)
		Return True
	End Method

	Method ChangeMoney(_moneychange:Int)
		money:+_moneychange
		revenue_after:+_moneychange
		'change to event?
		If Game.isGameLeader() and Game.Players[ Self.playerID ].isAI() Then Game.Players[ Self.playerID ].PlayerKI.CallOnMoneyChanged()
		If Self.playerID = Game.playerID Then Interface.BottomImgDirty = True
		If debug Then Print "FINANZ: player :"+Self.playerID+" geldaenderung:"+_moneychange
	End Method

	'refreshs stats about earned money from adspots
	Method earnAdProfit(_money:Int)
		If debug Then Print "FINANZ: player :"+Self.playerID+" Werbeeinahme: "+_money
		sold_ads	:+_money
		sold_total	:+_money
		ChangeMoney(_money)
	End Method

	'refreshs stats about earned money from sending ad powered shows or call-in
	Method earnCallerRevenue(_money:Int)
		Self.callerRevenue	:+_money
		Self.sold_total		:+_money
		If debug Then Print "FINANZ: player :"+Self.playerID+" Callshowgewinn: "+_money
		ChangeMoney(_money)
	End Method

	'refreshs stats about earned money from selling a movie/programme
	Method SellMovie(_money:Int)
		If debug Then Print "FINANZ: player :"+Self.playerID+" Filmverkauf: "+_money
		sold_movies	:+_money
		sold_total	:+_money
		ChangeMoney(_money)
	End Method

	'pay the bid for an auction programme
	Method PayProgrammeBid:Byte(_money:Int)
		If money >= _money
			paid_movies	:+_money
			paid_total	:+_money
			ChangeMoney(- _money)
			Return True
		Else
			If playerID = Game.playerID Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method

	'get the bid paid before another player bid for an auction programme
	Method GetProgrammeBid(_money:Int)
		paid_movies:-_money
		paid_total:-_money
		ChangeMoney(+ _money)
	End Method

	Method TakeCredit:Byte(_money:Int)
		credit		:+_money
		sold_misc	:+_money	'kind of income
		sold_total	:+_money	'kind of income
		paid_misc	:+_money	'kind of duty
		paid_total	:+_money	'kind of duty
		ChangeMoney(+ _money)
	End Method

	'refreshs stats about paid money from buying a movie/programme
	Method PayMovie:Byte(_money:Int)
		If money >= _money
			If debug Then Print "FINANZ: player :"+Self.playerID+" Filmkauf: -"+_money
			paid_movies:+_money
			paid_total:+_money
			ChangeMoney(- _money)
			Return True
		Else
			If playerID = Game.playerID Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method

	'refreshs stats about paid money from buying a station
	Method PayStation:Byte(_money:Int)
		If money >= _money
			If debug Then Print "FINANZ: player :"+Self.playerID+" Stationkauf: -"+_money
			paid_stations:+_money
			paid_total:+_money
			ChangeMoney(- _money)
			Return True
		Else
			If playerID = Game.playerID Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method

	'refreshs stats about paid money from buying a script (own production)
	Method PayScript:Byte(_money:Int)
		If money >= _money
			If debug Then Print "FINANZ: player :"+Self.playerID+" Scriptkauf: -"+_money
			paid_scripts:+_money
			paid_total:+_money
			ChangeMoney(- _money)
			Return True
		Else
			If playerID = Game.playerID Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method

	'refreshs stats about paid money from buying stuff for own production
	Method PayProductionStuff:Byte(_money:Int)
		If money >= _money
			paid_productionstuff:+_money
			paid_total:+_money
			ChangeMoney(- _money)
			Return True
		Else
			If playerID = Game.playerID Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method

	'refreshs stats about paid money from paying a penalty fee (not sent the necessary adspots)
	Method PayPenalty(_money:Int)
		If debug Then Print "FINANZ: player :"+Self.playerID+" Werbestrafe: -"+_money
		paid_penalty:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method

	'refreshs stats about paid money from paying the rent of rooms
	Method PayRent(_money:Int)
		If debug Then Print "FINANZ: player :"+Self.playerID+" Miete: -"+_money
		paid_rent:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method

	'refreshs stats about paid money from paying for the sent newsblocks
	Method PayNews:Byte(_money:Int)
		If money >= _money
			If debug Then Print "FINANZ: player :"+Self.playerID+" Newskauf: -"+_money
			paid_news:+_money
			paid_total:+_money
			ChangeMoney(- _money)
			Return True
		Else
			If playerID = Game.playerID Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method

	'refreshs stats about paid money from paying the daily costs a newsagency-abonnement
	Method PayNewsAgencies(_money:Int)
		If debug Then Print "FINANZ: player :"+Self.playerID+" Newsabo: -"+_money
		paid_newsagencies:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method

	'refreshs stats about paid money from paying the fees for the owned stations
	Method PayStationFees(_money:Int)
		If debug Then Print "FINANZ: player :"+Self.playerID+" Stationsgebuehren: -"+_money
		paid_stationfees:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method

	'refreshs stats about paid money from paying misc things
	Method PayMisc(_money:Int)
		If debug Then Print "FINANZ: player :"+Self.playerID+" MISC: -"+_money
		paid_misc:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method
End Type


'Include "gamefunctions_interface.bmx"

'create just one drop-zone-grid for all programme blocks instead the whole set for every block..
Function CreateDropZones:Int()
	Local i:Int = 0

	'adblock
	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.typ = "adblock"
		DragAndDrop.pos.setXY( 394 + Assets.GetSprite("pp_programmeblock1").w, 17 + i * Assets.GetSprite("pp_adblock1").h)
		DragAndDrop.w = Assets.GetSprite("pp_adblock1").w
		DragAndDrop.h = Assets.GetSprite("pp_adblock1").h
		If Not TAdBlock.DragAndDropList Then TAdBlock.DragAndDropList = CreateList()
		TAdBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TAdBlock.DragAndDropList
	Next
	'adblock
	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i+11
		DragAndDrop.typ = "adblock"
		DragAndDrop.pos.setXY( 67 + Assets.GetSprite("pp_programmeblock1").w, 17 + i * Assets.GetSprite("pp_adblock1").h )
		DragAndDrop.w = Assets.GetSprite("pp_adblock1").w
		DragAndDrop.h = Assets.GetSprite("pp_adblock1").h
		If Not TAdBlock.DragAndDropList Then TAdBlock.DragAndDropList = CreateList()
		TAdBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TAdBlock.DragAndDropList
	Next
	'programmeblock
	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.typ = "programmeblock"
		DragAndDrop.pos.setXY( 394, 17 + i * Assets.GetSprite("pp_programmeblock1").h )
		DragAndDrop.w = Assets.GetSprite("pp_programmeblock1").w
		DragAndDrop.h = Assets.GetSprite("pp_programmeblock1").h
		If Not TProgrammeBlock.DragAndDropList Then TProgrammeBlock.DragAndDropList = CreateList()
		TProgrammeBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TProgrammeBlock.DragAndDropList
	Next

	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i+11
		DragAndDrop.typ = "programmeblock"
		DragAndDrop.pos.setXY( 67, 17 + i * Assets.GetSprite("pp_programmeblock1").h )
		DragAndDrop.w = Assets.GetSprite("pp_programmeblock1").w
		DragAndDrop.h = Assets.GetSprite("pp_programmeblock1").h
		If Not TProgrammeBlock.DragAndDropList Then TProgrammeBlock.DragAndDropList = CreateList()
		TProgrammeBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TProgrammeBlock.DragAndDropList
	Next

End Function

Include "gamefunctions_elevator.bmx"
Include "gamefunctions_figures.bmx"

'Summary: Type of building, area around it and doors,...
Type TBuilding Extends TRenderable
	Field pos:TPoint = TPoint.Create(20,0)
	Field buildingDisplaceX:int = 127			'px at which the building starts (leftside added is the door)
	Field innerLeft:Int			= 127 + 40
	Field innerRight:Int		= 127 + 468
	Field skycolor:Float 		= 0
	Field ufo_normal:TMoveableAnimSprites = New TMoveableAnimSprites.Create(Assets.GetSprite("gfx_building_BG_ufo"), 9, 100).SetupMoveable(0, 100, 0,0)
	Field ufo_beaming:TMoveableAnimSprites = New TMoveableAnimSprites.Create(Assets.GetSprite("gfx_building_BG_ufo2"), 9, 100).SetupMoveable(0, 100, 0,0)
	Field Elevator:TElevator

	Field Moon_Path:TCatmullRomSpline	= new TCatmullRomSpline
	Field Moon_PathCurrentDistance:float= 0.0
	Field Moon_MovementStarted:int		= FALSE
	Field Moon_MovementBaseSpeed:float	= 0.0		'so that the whole path moved within time

	Field UFO_Path:TCatmullRomSpline	= New TCatmullRomSpline
	Field UFO_PathCurrentDistance:float	= 0.0
	Field UFO_MovementStarted:int		= FALSE
	Field UFO_MovementBaseSpeed:float	= 0.0
	Field UFO_DoBeamAnimation:int		= FALSE
	Field UFO_BeamAnimationDone:int		= FALSE

	Field Clouds:TMoveableAnimSprites[7]
	Field CloudsAlpha:float[7]

	Field TimeColor:Double
	Field DezimalTime:Float
	Field ActHour:Int
	Field initDone:int					= FALSE
	Field gfx_bgBuildings:TGW_Sprites[6]
	Field gfx_building:TGW_Sprites
	Field gfx_buildingEntrance:TGW_Sprites
	Field gfx_buildingRoof:TGW_Sprites
	Field gfx_buildingWall:TGW_Sprites

	Field room:TRooms					= Null		'the room used for the building

	Field roomUsedTooltip:TTooltip		= Null

	Global Stars:TPoint[60]
	Global List:TList = CreateList()

	Function Create:TBuilding()
		EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Create Building").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )

		Local Building:TBuilding = New TBuilding
		Building.gfx_building	= Assets.GetSprite("gfx_building")
		Building.pos.y			= 0 - Building.gfx_building.h + 5 * 73 + 20	' 20 = interfacetop, 373 = raumhoehe
		Building.Elevator		= TElevator.Create(Building)
		Building.Elevator.RouteLogic = TElevatorSmartLogic.Create(Building.Elevator, 0) 'Die Logik die im Elevator verwendet wird. 1 heißt, dass der PrivilegePlayerMode aktiv ist... mMn macht's nur so wirklich Spaß


		'set moon movement
		Building.Moon_Path.addXY( -50, 640 )
		Building.Moon_Path.addXY( -50, 190 )
		Building.Moon_Path.addXY( 400,  10 )
		Building.Moon_Path.addXY( 850, 190 )
		Building.Moon_Path.addXY( 850, 640 )

		'set ufo movement
		local displaceY:int = 280
		local displaceX:int = 5
		Building.UFO_path.addXY( -60 +displaceX, -410 +displaceY)
		Building.UFO_path.addXY( -50 +displaceX, -400 +displaceY)
		Building.UFO_path.addXY(  50 +displaceX, -350 +displaceY)
		Building.UFO_path.addXY( -100 +displaceX, -300 +displaceY)
		Building.UFO_path.addXY(  100 +displaceX, -250 +displaceY)
		Building.UFO_path.addXY(  40 +displaceX, -200 +displaceY)
		Building.UFO_path.addXY(  50 +displaceX,  -190 +displaceY)
		Building.UFO_path.addXY(  60 +displaceX, -200 +displaceY)
		Building.UFO_path.addXY(  70 +displaceX, -250 +displaceY)
		Building.UFO_path.addXY(  400 +displaceX, -700 +displaceY)
		Building.UFO_path.addXY(  410 +displaceX, -710 +displaceY)
rem
		Building.UFO_path.addXY(        -350, -400+Rand(0,200) )
		Building.UFO_path.addXY( Rand(0,400)+100, -200+Rand(0,200) )
		Building.UFO_path.addXY( Rand(0,200), -100+Rand(0,300) )
		Building.UFO_path.addXY(        -170,             -100 )
		Building.UFO_path.addXY(        -250,             -150 )
endrem

		For Local i:Int = 0 To Building.Clouds.length-1
			Building.Clouds[i] = New TMoveableAnimSprites.Create(Assets.GetSprite("gfx_building_BG_clouds"), 1,0).SetupMoveable(- 200 * i + (i + 1) * Rand(0,400), - 30 + Rand(0,30), 2 + Rand(0, 6),0)
			Building.CloudsAlpha[i] = float(Rand(80,100))/100.0
		Next

		'background buildings
		Building.gfx_bgBuildings[0] = Assets.GetSprite("gfx_building_BG_Ebene3L")
		Building.gfx_bgBuildings[1] = Assets.GetSprite("gfx_building_BG_Ebene3R")
		Building.gfx_bgBuildings[2] = Assets.GetSprite("gfx_building_BG_Ebene2L")
		Building.gfx_bgBuildings[3] = Assets.GetSprite("gfx_building_BG_Ebene2R")
		Building.gfx_bgBuildings[4] = Assets.GetSprite("gfx_building_BG_Ebene1L")
		Building.gfx_bgBuildings[5] = Assets.GetSprite("gfx_building_BG_Ebene1R")

		'building assets
		Building.gfx_buildingEntrance	= Assets.GetSprite("gfx_building_Eingang")
		Building.gfx_buildingWall		= Assets.GetSprite("gfx_building_Zaun")
		Building.gfx_buildingRoof		= Assets.GetSprite("gfx_building_Dach")

		For Local j:Int = 0 To 29
			Stars[j] = TPoint.Create( 10+Rand(0,150), 20+Rand(0,273), 50+Rand(0,150) )
		Next
		For Local j:Int = 30 To 59
			Stars[j] = TPoint.Create( 650+Rand(0,150), 20+Rand(0,273), 50+Rand(0,150) )
		Next
		If Not List Then List = CreateList()
		List.AddLast(Building)
		SortList List
		Return Building
	End Function

	Method Update(deltaTime:Float=1.0)
		pos.y = Clamp(pos.y, - 637, 88)
		UpdateBackground(deltaTime)


		'update hotspot tooltips
		if room
			for local hotspot:THotspot = eachin room.hotspots
				hotspot.update(self.pos.x, self.pos.y)
			Next
		endif


		If Self.roomUsedTooltip <> Null Then Self.roomUsedTooltip.Update(deltaTime)


		'handle player target changes
		If not Game.GetPlayer().Figure.inRoom
			If MOUSEMANAGER.isClicked(1) and not GUIManager.modalActive
				'do not allow movement on fadeIn (when going in a room)
				if not Fader.fadeenabled or (Fader.fadeenabled and Fader.fadeout)
					If functions.IsIn(MouseManager.x, MouseManager.y, 20, 10, 760, 373)
						Game.GetPlayer().Figure.ChangeTarget(MouseManager.x, MouseManager.y)
						MOUSEMANAGER.resetKey(1)
					EndIf
				endif
			EndIf
		EndIf
	End Method

	Method Init:Int()
		if initDone then return TRUE

		Local locy13:Int	= GetFloorY(13)
		Local locy3:Int		= GetFloorY(3)
		Local locy0:Int		= GetFloorY(0)
		Local locy12:Int	= GetFloorY(12)

		Local Pix:TPixmap = LockImage(gfx_building.parent.image)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Pflanze4").GetImage(), 0, Pix, -buildingDisplaceX + innerleft + 40, locy12 - Assets.GetSprite("gfx_building_Pflanze4").h)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Pflanze6").GetImage(), 0, Pix, -buildingDisplaceX + innerRight - 95, locy12 - Assets.GetSprite("gfx_building_Pflanze6").h)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Pflanze2").GetImage(), 0, Pix, -buildingDisplaceX + innerleft + 105, locy13 - Assets.GetSprite("gfx_building_Pflanze2").h)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Pflanze3").GetImage(), 0, Pix, -buildingDisplaceX + innerRight - 105, locy13 - Assets.GetSprite("gfx_building_Pflanze3").h)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, -buildingDisplaceX + innerleft + 125, locy0 - Assets.GetSprite("gfx_building_Wandlampe").h)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, -buildingDisplaceX + innerRight - 125 - Assets.GetSprite("gfx_building_Wandlampe").w, locy0 - Assets.GetSprite("gfx_building_Wandlampe").h)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, -buildingDisplaceX + innerleft + 125, locy13 - Assets.GetSprite("gfx_building_Wandlampe").h)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, -buildingDisplaceX + innerRight - 125 - Assets.GetSprite("gfx_building_Wandlampe").w, locy13 - Assets.GetSprite("gfx_building_Wandlampe").h)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, -buildingDisplaceX + innerleft + 125, locy3 - Assets.GetSprite("gfx_building_Wandlampe").h)
		DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, -buildingDisplaceX + innerRight - 125 - Assets.GetSprite("gfx_building_Wandlampe").w, locy3 - Assets.GetSprite("gfx_building_Wandlampe").h)
		UnlockImage(gfx_building.parent.image)
		Pix = Null

		'assign room
		room = TRooms.getRoomByDetails("building",0)

		'move elevatorplan hotspots to the elevator
		For Local hotspot:THotspot = EachIn room.hotspots
			If hotspot.name = "elevatorplan"
				hotspot.area.position.setX( Elevator.pos.getX() )
				hotspot.area.dimension.setXY( Elevator.GetDoorWidth(), 58 )
			endif
		Next

rem
		'move elevatorplan rooms to the elevator
		For Local room:TRooms = EachIn TRooms.RoomList
			If room.name = "elevatorplan"
				room.Pos.x = pos.x + Elevator.pos.getX()
				room.doorDimension.setXY( Elevator.GetDoorWidth(), 58 )
				print room.Pos.x+" w="+Elevator.GetDoorWidth()
			endif
		Next
endrem

		'register events
		'register each hotspot separately - avoids spamm of other clicked spots
		for local hotspot:THotspot = eachin room.hotspots
			EventManager.registerListenerMethod( "hotspot.onClick", self, "onClickHotspot", hotspot )
		Next

		'we want to get information about figures reaching their desired target
		'(this can be "room", "hotspot" ... )
		EventManager.registerListenerMethod( "figure.onReachTarget", self, "onReachTarget" )

		initDone = True
	End Method


	Method onReachTarget:int( triggerEvent:TEventBase )
		local figure:TFigures = TFigures( triggerEvent._sender )
		if not figure then return FALSE

		local hotspot:THotspot = THotspot( triggerEvent.getData().get("hotspot") )
		'we are only interested in hotspots
		if not hotspot then return FALSE


		if hotspot.name = "elevatorplan"
			print "figure "+figure.name+" reached elevatorplan"

			local room:TRooms = TRooms.getRoomByDetails("elevatorplan",0)
			if not room then print "[ERROR] room: elevatorplan not not defined. Cannot enter that room.";return FALSE

			figure.EnterRoom(room)
			return TRUE
		endif

		return FALSE
	End Method

	Method onClickHotspot:int( triggerEvent:TEventBase )
		local hotspot:THotspot = THotspot( triggerEvent._sender )
		if not hotspot then return FALSE 'or hotspot.name <> "elevatorplan" then return FALSE

		Game.getPlayer().figure.changeTarget( pos.x + hotspot.area.getX() + hotspot.area.getW()/2, pos.y + hotspot.area.getY() )
		Game.getPlayer().figure.targetHotspot = hotspot

		MOUSEMANAGER.resetKey(1)
	End Method


	Method Draw(tweenValue:Float=1.0)
		TProfiler.Enter("Draw-Building-Background")
		DrawBackground(tweenValue)
		TProfiler.Leave("Draw-Building-Background")

		If Building.GetFloor(Game.Players[Game.playerID].Figure.rect.GetY()) <= 4
			SetColor Int(205 * timecolor) + 150, Int(205 * timecolor) + 150, Int(205 * timecolor) + 150
			Building.gfx_buildingEntrance.Draw(pos.x, pos.y + 1024 - Building.gfx_buildingEntrance.h - 3)
			Building.gfx_buildingWall.Draw(pos.x + buildingDisplaceX + 507, pos.y + 1024 - Building.gfx_buildingWall.h - 3)
		Else If Building.GetFloor(Game.Players[Game.playerID].Figure.rect.GetY()) >= 8
			SetColor 255, 255, 255
			SetBlend ALPHABLEND
			Building.gfx_buildingRoof.Draw(pos.x + buildingDisplaceX, pos.y - Building.gfx_buildingRoof.h)
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

		For Local Figure:TFigures = EachIn TFigures.List
			If Not Figure.alreadydrawn Then Figure.Draw()
		Next

		Local pack:TGW_Spritepack = Assets.getSpritePack("gfx_hochhauspack")
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + innerRight - 130, pos.y + GetFloorY(9), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + innerLeft + 150, pos.y + GetFloorY(13), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + innerRight - 110, pos.y + GetFloorY(9), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + innerLeft + 150, pos.y + GetFloorY(6), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze6").Draw(pos.x + innerRight - 85, pos.y + GetFloorY(8), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze3a").Draw(pos.x + innerLeft + 60, pos.y + GetFloorY(1), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze3a").Draw(pos.x + innerLeft + 60, pos.y + GetFloorY(12), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze3b").Draw(pos.x + innerLeft + 150, pos.y + GetFloorY(12), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + innerRight - 70, pos.y + GetFloorY(3), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + innerRight - 75, pos.y + GetFloorY(12), - 1, 1)

		TRooms.DrawDoorToolTips()

		'draw hotspot tooltips
		for local hotspot:THotspot = eachin room.hotspots
			hotspot.draw( self.pos.x, self.pos.y)
		next

		If Self.roomUsedTooltip Then Self.roomUsedTooltip.Draw()

	End Method

	Method UpdateBackground(deltaTime:Float)
		ActHour = Game.GetHour()
		DezimalTime = Float(Game.GetHour()) + Float(Game.GetMinute())*10/6/100
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
			if not Moon_MovementStarted
				'we have 15 hrs to "see the moon" - so we have add them accordingly
				'this means - we have to calculate the hours "gone" since 18:00
				local minutesPassed:int = 0
				if ActHour>18
					minutesPassed = (ActHour-18)*60 + Game.GetMinute()
				else
					minutesPassed = (ActHour+7)*60 + Game.GetMinute()
				endif

				'calculate the base speed needed so that the moon would move
				'the whole path within 15 hrs (15*60 minutes)
				'this means: after 15hrs 100% of distance are reached
				Moon_MovementBaseSpeed = 1.0 / (15*60)

				Moon_PathCurrentDistance = minutesPassed * Moon_MovementBaseSpeed

				Moon_MovementStarted = TRUE
			endif


			Moon_PathCurrentDistance:+ deltaTime * Moon_MovementBaseSpeed * Game.GetGameMinutesPerSecond()
		'	if Moon_PathCurrentDistance > 1.0 then Moon_PathCurrentDistance = 0.0
		else
			Moon_MovementStarted = FALSE
			'set to beginning
			Moon_PathCurrentDistance = 0.0
		endif


		'compute ufo
		'-----------
		'only happens between...
		If Game.GetDay() Mod 2 = 0 and (DezimalTime > 18 Or DezimalTime < 7)
			UFO_MovementBaseSpeed = 1.0 / 60.0 '30 minutes for whole path

			'only continue moving if not doing the beamanimation
			if not UFO_DoBeamAnimation or UFO_BeamAnimationDone
				UFO_PathCurrentDistance:+ deltaTime * UFO_MovementBaseSpeed * Game.GetGameMinutesPerSecond()

				'do beaming now
				if UFO_PathCurrentDistance > 0.50 and not UFO_BeamAnimationDone
					UFO_DoBeamAnimation = TRUE
				endif
			endif
			if UFO_DoBeamAnimation and not UFO_BeamAnimationDone
				if ufo_beaming.getCurrentAnimation().isFinished()
					UFO_BeamAnimationDone = TRUE
					UFO_DoBeamAnimation = FALSE
				endif
				ufo_beaming.update(deltaTime)
			endif

		else
			'reset beam enabler anyways
			UFO_DoBeamAnimation = FALSE
			UFO_BeamAnimationDone=FALSE
		endif

		For Local i:Int = 0 To Building.Clouds.length-1
			Clouds[i].Update(deltaTime)
		Next
	End Method

	'Summary: Draws background of the mainscreen (stars, buildings, moon...)
	Method DrawBackground(tweenValue:Float=1.0)
		Local BuildingHeight:Int = gfx_building.h + 56

		If DezimalTime > 18 Or DezimalTime < 7
			If DezimalTime > 18 And DezimalTime < 19 Then SetAlpha (19 - Dezimaltime)
			If DezimalTime > 6 And DezimalTime < 8 Then SetAlpha (4 - Dezimaltime / 2)

			'stars
			SetBlend MASKBLEND
			Local minute:Float = Game.GetMinute()
			For Local i:Int = 0 To 59
				If i Mod 6 = 0 And minute Mod 2 = 0 Then Stars[i].z = Rand(0, Max(1,Stars[i].z) )
				SetColor Stars[i].z , Stars[i].z , Stars[i].z
				Plot(Stars[i].x , Stars[i].y )
			Next

			SetColor 255, 255, 255
			DezimalTime:+3
			If DezimalTime > 24 Then DezimalTime:-24

			SetBlend ALPHABLEND

			local moonPos:TPoint = Moon_Path.GetTweenPoint( Moon_PathCurrentDistance, TRUE )
			'draw moon - frame is from +6hrs (so day has already changed at 18:00)
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
			SetAlpha 1.0
'			If Game.GetDay() Mod 2 = 0
				'compute and draw Ufo
				local UFOPos:TPoint = UFO_Path.GetTweenPoint( UFO_PathCurrentDistance, TRUE )
				'print UFO_PathCurrentDistance
				if UFO_DoBeamAnimation and not UFO_BeamAnimationDone
					ufo_beaming.rect.position.SetXY(UFOPos.x, 0.25 * (pos.y + BuildingHeight - gfx_bgBuildings[0].h) + UFOPos.y)
					ufo_beaming.Draw()
				else
					Assets.GetSprite("gfx_building_BG_ufo").Draw( UFOPos.x, 0.25 * (pos.y + BuildingHeight - gfx_bgBuildings[0].h) + UFOPos.y, ufo_normal.GetCurrentFrame())
				endif
'			EndIf
		EndIf

		SetBlend MASKBLEND

		local baseBrightness:int = 75

		SetColor Int(225 * timecolor) + baseBrightness, Int(225 * timecolor) + baseBrightness, Int(225 * timecolor) + baseBrightness
		gfx_bgBuildings[0].Draw(pos.x		, 105 + 0.25 * (pos.y + 5 + BuildingHeight - gfx_bgBuildings[0].h), - 1, 0)
		gfx_bgBuildings[1].Draw(pos.x + 634	, 105 + 0.25 * (pos.y + 5 + BuildingHeight - gfx_bgBuildings[1].h), - 1, 0)

		SetColor Int(215 * timecolor) + baseBrightness+15, Int(215 * timecolor) + baseBrightness+15, Int(215 * timecolor) + baseBrightness+15
		gfx_bgBuildings[2].Draw(pos.x		, 120 + 0.35 * (pos.y 		+ BuildingHeight - gfx_bgBuildings[2].h), - 1, 0)
		gfx_bgBuildings[3].Draw(pos.x + 636	, 120 + 0.35 * (pos.y + 60	+ BuildingHeight - gfx_bgBuildings[3].h), - 1, 0)

		SetColor Int(205 * timecolor) + baseBrightness+30, Int(205 * timecolor) + baseBrightness+30, Int(205 * timecolor) + baseBrightness+30
		gfx_bgBuildings[4].Draw(pos.x		, 45 + 0.80 * (pos.y + BuildingHeight - gfx_bgBuildings[4].h), - 1, 0)
		gfx_bgBuildings[5].Draw(pos.x + 634	, 45 + 0.80 * (pos.y + BuildingHeight - gfx_bgBuildings[5].h), - 1, 0)

		SetColor 255, 255, 255
	End Method

	Method CreateRoomUsedTooltip:Int(room:TRooms)
		roomUsedTooltip			= TTooltip.Create("Besetzt", "In diesem Raum ist schon jemand", 0,0,-1,-1,2000)
		roomUsedTooltip.pos.y	= pos.y + GetFloorY(room.Pos.y)
		roomUsedTooltip.pos.x	= room.Pos.x + room.doorDimension.x/2 - roomUsedTooltip.GetWidth()/2
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

		return self
	End Method

	Method GetMovieNewsEvent:TNewsEvent()
		local movie:TProgramme = self._GetAnnouncableMovie()
		if movie
			movie.releaseAnnounced = TRUE

			local title:String = getLocale("NEWS_ANNOUNCE_MOVIE_TITLE"+Rand(1,2) )
			local description:String = getLocale("NEWS_ANNOUNCE_MOVIE_DESCRIPTION"+Rand(1,4) )

			'if same director and main actor...
			if movie.getActor(1) = movie.getDirector(1)
				title = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_TITLE")
				description = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_DESCRIPTION")
			endif
			'if no actors ...
			if movie.getActor(1) = "" or movie.getActor(1) = "XXX"
				title = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_TITLE")
				description = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_DESCRIPTION")
			endif

			'replace data
			title = self._ReplaceMovieData(title, movie)
			description = self._ReplaceMovieData(description, movie)

			'quality and price are based on the movies data
			Local NewsEvent:TNewsEvent = TNewsEvent.Create(title, description, 1, movie.review/2.0, movie.outcome/3.0)
			'remove news from TNews-list as we do not want to have them repeated :D
			NewsEvent.list.remove(NewsEvent)

			return NewsEvent
		endif
		return Null
	End Method

	Method _ReplaceMovieData:string(text:string, movie:TProgramme)
		For local i:int = 1 to 2
			text = text.replace("%ACTORNAME"+i+"%", movie.getActor(i))
			text = text.replace("%DIRECTORNAME"+i+"%", movie.getDirector(i))
		Next
		text = text.replace("%MOVIETITLE%", movie.title)

		return text
	end Method

	'helper to get a movie which can be used for a news
	Method _GetAnnouncableMovie:TProgramme()
		'filter to entries we need
		Local movie:TProgramme
		Local resultList:TList = CreateList()
		For movie = EachIn TProgramme.ProgMovieList
			'ignore if filtered out
			if not movie.ignoreUnreleasedProgrammes AND movie.year < movie._filterReleaseDateStart OR movie.year > movie._filterReleaseDateEnd then continue
			If movie.owner <> 0 Then continue
			'ignore already announced movies
			If movie.releaseAnnounced then continue

			'only add movies of "next X days"
			local movieTime:int = movie.year * Game.daysPerYear + movie.releaseDay
			If movieTime > Game.getDay() AND movieTime - Game.getDay() < 6 Then resultList.addLast(movie)
		Next
		if resultList.count() > 0 then Return TProgramme.GetRandomProgrammeFromList(resultList)

		return null
	End Method

	Method GetSpecialNewsEvent:TNewsEvent()
	End Method


	'announces new news chain elements
	Method ProcessNewsEventChains:int()
		local announced:int = 0
		Local newsEvent:TNewsEvent = NULL
		For Local chainElement:TNewsEvent = EachIn activeChains
			If not chainElement.isLastEpisode() then newsEvent = chainElement.GetNextNewsEventFromChain()
			'remove the "old" one, the new element will get added instead (if existing)
			activeChains.Remove(chainElement)

			'ignore if the chain ended already
			if not newsEvent then continue

			If chainElement.happenedTime + newsEvent.getHappenDelay() < Game.timeGone
				announceNewsEvent(newsEvent)
				announced:+1
			endif
		Next

		'check every 10 game minutes
		self.NextChainCheckTime = Game.timeGone + 10

		return announced
	End Method

	Method AddNewsEventToPlayer:int(newsEvent:TNewsEvent, forPlayer:Int=-1, fromNetwork:Int=0)
		'only add news/newsblock if player is Host/Player OR AI
		'If Not Game.isLocalPlayer(forPlayer) And Not Game.isAIPlayer(forPlayer) Then Return 'TODO: Wenn man gerade Spieler 2 ist/verfolgt (Taste 2) dann bekommt Spieler 1 keine News
		If Game.Players[ forPlayer ].newsabonnements[newsEvent.genre] > 0
			'print "[LOCAL] AddNewsToPlayer: creating newsblock, player="+forPlayer
			TNews.Create("", forPlayer, Game.Players[ forPlayer ].GetNewsAbonnementDelay(newsEvent.genre), newsEvent)
		EndIf
	End Method

	Method announceNewsEvent:int(newsEvent:TNewsEvent, happenedTime:int=0)
		newsEvent.doHappen(happenedTime)

		For Local i:Int = 1 To 4
			AddNewsEventToPlayer(newsEvent, i)
		Next

		if newsEvent.episodes.count() > 0 then activeChains.AddLast(newsEvent)
	End Method

	Method AnnounceNewNewsEvent:int(delayAnnouncement:Int=0)
		'no need to check for gameleader - ALL players
		'will handle it on their own - so the randomizer stays intact
		'if not Game.isGameLeader() then return FALSE

		Local newsEvent:TNewsEvent = Null
		'try to load some movie news ("new movie announced...")
		if not newsEvent and RandRange(1,100)<35 then newsEvent = self.GetMovieNewsEvent()

		If not newsEvent Then newsEvent = TNewsEvent.GetRandom()

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


Type TFigurePostman extends TFigures
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500,0,1000)

	'we need to overwrite it to have a custom type - with custom update routine
	Method CreateFigure:TFigurePostman(FigureName:String, sprite:TGW_Sprites, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		super.CreateFigure(FigureName, sprite, x, onFloor, speed, ControlledByID)
		return self
	End Method

	Method UpdateCustom:int(deltaTime:float)
		If inRoom and nextActionTimer.isExpired()
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
		If not inRoom And not target
			Local room:TRooms
			Repeat
				room = TRooms(TRooms.RoomList.ValueAtIndex(Rand(TRooms.RoomList.Count() - 1)))
			Until room.doortype >0
			Print "[DEV AI] "+name+" steht rum -> neues Ziel gesucht " + room.name
			SendToRoom(room)
		EndIf
	End Method
End Type


Type TFigureJanitor extends TFigures
	Field currentAction:int	= 0		'0=nothing,1=cleaning,...
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500)

	'we need to overwrite it to have a custom type - with custom update routine
	Method CreateFigure:TFigureJanitor(FigureName:String, sprite:TGW_Sprites, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		super.CreateFigure(FigureName, sprite, x, onFloor, speed, ControlledByID)
		self.rect.dimension.setX(14)

		Self.insertAnimation("cleanLeft", TAnimation.Create([ [11,130], [12,130] ], -1, 0) )
		Self.insertAnimation("cleanRight", TAnimation.Create([ [13,130], [14,130] ], -1, 0) )

		return self
	End Method

	'overwrite original method
	Method getAnimationToUse:string()
		local result:string = super.getAnimationToUse()

		if currentAction = 1
			If result = "walkright" then result = "cleanRight" else result="cleanLeft"
		endif
		return result
	End Method

	'overwrite basic doMove and stop movement if needed
	Method doMove(deltaTime:float)
		if currentAction = 1
			local backupSpeed:int = vel.getX()
			vel.setX(0)
			super.doMove(deltaTime)
			vel.setX(backupSpeed)
		else
			super.doMove(deltaTime)
		endif
	End Method

	Method UpdateCustom:int(deltaTime:float)
		'waited to long - change target (returns false while in elevator)
		If hasToChangeFloor() And WaitAtElevatorTimer.isExpired()
			if ChangeTarget(Rand(150, 580), Building.pos.y + Building.GetFloorY(GetFloor()))
				WaitAtElevatorTimer.Reset()
			endif
		EndIf

		'reached target - and time to do something
		If not target and nextActionTimer.isExpired()
			'reset is done later - we want to catch isExpired there too
			'nextActionTimer.Reset()

			Local zufall:Int = Rand(0, 100)	'what to do?
			Local zufallx:Int = Rand(150, 580)	'where to go?

			'move to a spot further away than just some pixels
			Repeat
				zufallx = Rand(150, 580)
			Until Abs(rect.GetX() - zufallx) > 15

			if not hasToChangeFloor()
				'move to a different floor (only if doing nothing special)
				If currentAction=0 and zufall > 80 And Not IsAtElevator()
					Local sendToFloor:Int = GetFloor() + 1
					If sendToFloor > 13 Then sendToFloor = 0
					ChangeTarget(zufallx, Building.pos.y + Building.GetFloorY(sendToFloor))
					WaitAtElevatorTimer.Reset()
				'move to a different X on same floor
				Else
					ChangeTarget(zufallx, Building.pos.y + Building.GetFloorY(GetFloor()))
				EndIf
			Endif
		EndIf

		If nextActionTimer.isExpired() and not hasToChangeFloor()
			nextActionTimer.Reset()
			self.currentAction = 0
			'chose actions
			'only clean with a chance of 30%
			If Rand(0,100) < 30
				self.currentAction = 1
			endif
		Endif
	End Method
End Type




'Sound-Files einlesen - da es lange dauert eventuell nur bei Bedarf oder in einem anderen Thread laden.
SoundManager.SetDefaultReceiver(TPlayerElementPosition.Create())
SoundManager.LoadSoundFiles()


'#Region: Globals, Player-Creation
Global Interface:TInterface		= TInterface.Create()
Global Game:TGame	  			= TGame.Create()
Global Building:TBuilding		= TBuilding.Create()


EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Create Rooms").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )
Init_CreateAllRooms() 				'creates all Rooms - with the names assigned at this moment

Game.Initialize() 'Game.CreateInitialPlayers()

'RON
local haveNPCs:int = TRUE
if haveNPCs
	New TFigureJanitor.CreateFigure("Hausmeister", Assets.GetSprite("figure_Hausmeister"), 210, 2, 65)
	New TFigurePostman.CreateFigure("Bote1", Assets.GetSprite("BoteLeer"), 210, 3, 65, 0)
	New TFigurePostman.CreateFigure("Bote2", Assets.GetSprite("BoteLeer"), 410, 1, -65, 0)
endif


Global MenuPlayerNames:TGUIinput[4]
Global MenuChannelNames:TGUIinput[4]
Global MenuFigureArrows:TGUIArrowButton[8]

PrintDebug ("Base", "creating GUIelements", DEBUG_START)
'MainMenu



Global MainMenuButton_Start:TGUIButton		= New TGUIButton.Create(TPoint.Create(600, 300), 120, GetLocale("MENU_SOLO_GAME"), "MainMenu", Assets.fonts.baseFontBold)
Global MainMenuButton_Network:TGUIButton	= New TGUIButton.Create(TPoint.Create(600, 348), 120, GetLocale("MENU_NETWORKGAME"), "MainMenu", Assets.fonts.baseFontBold)
Global MainMenuButton_Online:TGUIButton		= New TGUIButton.Create(TPoint.Create(600, 396), 120, GetLocale("MENU_ONLINEGAME"), "MainMenu", Assets.fonts.baseFontBold)


Global NetgameLobbyButton_Join:TGUIButton	= New TGUIButton.Create(TPoint.Create(600, 300), 120, GetLocale("MENU_JOIN"), "NetGameLobby", Assets.fonts.baseFontBold)
Global NetgameLobbyButton_Create:TGUIButton	= New TGUIButton.Create(TPoint.Create(600, 345), 120, GetLocale("MENU_CREATE_GAME"), "NetGameLobby", Assets.fonts.baseFontBold)
Global NetgameLobbyButton_Back:TGUIButton	= New TGUIButton.Create(TPoint.Create(600, 390), 120, GetLocale("MENU_BACK"), "NetGameLobby", Assets.fonts.baseFontBold)
'Global NetgameLobby_gamelist:TGUIList		= new TGUIList.Create(20, 300, 520, 250, 100, "NetGameLobby")
'NetgameLobby_gamelist.SetFilter("HOSTGAME")
'NetgameLobby_gamelist.AddBackground("")

'available games list
Global NetgameLobbyGamelist:TGUIGameList = New TGUIGameList.Create(20,300,520,250,"NetGameLobby")
NetgameLobbyGamelist.SetBackground( New TGUIBackgroundBox.Create(0,0,520,200,"") )
NetgameLobbyGamelist.SetPadding(40,5,7,6)
NetgameLobbyGamelist.guiBackground.value	= "Chat"
NetgameLobbyGamelist.guiBackground.usefont	= Assets.GetFont("Default", 16, BOLDFONT)



Global GameSettingsBG:TGUIBackgroundBox = New TGUIBackgroundBox.Create(20, 20, 760, 260, "GameSettings")
GameSettingsBG.value = "Spieleinstellungen"
GameSettingsBG.useFont = Assets.GetFont("Default", 16, BOLDFONT)
Global GameSettingsOkButton_Announce:TGUIOkButton = New TGUIOkButton.Create(420, 234, False, "Spieleinstellungen abgeschlossen", "GameSettings", Assets.fonts.baseFontBold)
Global GameSettingsGameTitle:TGuiInput		= New TGUIinput.Create(50, 230, 320, Game.title, 32, "GameSettings")
Global GameSettingsButton_Start:TGUIButton	= New TGUIButton.Create(TPoint.Create(600, 300), 120, GetLocale("MENU_START_GAME"), "GameSettings", Assets.fonts.baseFontBold)
Global GameSettingsButton_Back:TGUIButton	= New TGUIButton.Create(TPoint.Create(600, 345), 120, GetLocale("MENU_BACK"), "GameSettings", Assets.fonts.baseFontBold)

'chat windows
Global GameSettings_Chat:TGUIChat = New TGUIChat.Create(20,300,520,200,"GameSettings")
GameSettings_Chat.guiInput.setMaxLength(200)
GameSettings_Chat.SetBackground( New TGUIBackgroundBox.Create(0,0,520,200,"") )
GameSettings_Chat.SetPadding(40,5,7,6)
GameSettings_Chat.guiBackground.value	= "Chat"
GameSettings_Chat.guiBackground.usefont	= Assets.GetFont("Default", 16, BOLDFONT)

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
InGame_Chat.guiInput.maxTextWidth		= gfx_GuiPack.GetSprite("Chat_IngameOverlay").w - 20
InGame_Chat.guiInput.InputImageActive	= gfx_GuiPack.GetSprite("Chat_IngameOverlay")
InGame_Chat.guiInput.color.adjust(255,255,255,True)
InGame_Chat.guiInput.autoAlignText = 0
InGame_Chat.guiInput.TextDisplacement.setXY(0,5)

'Doubleclick-function for NetGameLobby_GameList
Function onClick_NetGameLobby:Int(triggerEvent:TEventBase)
	Local entry:TGUIGameEntry = TGUIGameEntry(triggerEvent.getSender())
	If Not entry Then Return False

	'we are only interested in doubleclicks
	Local clickType:Int = triggerEvent.getData().getInt("type", 0)
	If clickType = EVENT_GUI_DOUBLECLICK
		NetgameLobbyButton_Join.mouseIsClicked	= TPoint.Create(1,1)
		GameSettingsButton_Start.disable()

		Local _hostIP:String = entry.data.getString("hostIP","0.0.0.0")
		Local _hostPort:Int = entry.data.getInt("hostPort",0)
		Local gameTitle:String = entry.data.getString("gameTitle","#unknowngametitle#")

		If Network.ConnectToServer( HostIp(_hostIP), _hostPort )
			Game.gamestate = GAMESTATE_SETTINGSMENU
			GameSettingsGameTitle.Value = gameTitle
		EndIf
	EndIf

	Return False
End Function
'we want to know about all clicks on TGUIGameEntry-objects
EventManager.registerListenerFunction( "guiobject.onClick",	onClick_NetGameLobby, "TGUIGameEntry" )


Include "gamefunctions_network.bmx"
'Network.init(game.userfallbackip)

For Local i:Int = 0 To 7
	If i < 4
		MenuPlayerNames[i]	= New TGUIinput.Create(50 + 190 * i, 65, 130, Game.Players[i + 1].Name, 16, "GameSettings", Assets.GetFont("Default", 12)).SetOverlayImage(Assets.GetSprite("gfx_gui_overlay_player"))
		MenuPlayerNames[i].TextDisplacement.setX(3)
		MenuPlayerNames[i].setZindex(150)

		MenuChannelNames[i]	= New TGUIinput.Create(50 + 190 * i, 180, 130, Game.Players[i + 1].channelname, 16, "GameSettings", Assets.GetFont("Default", 12)).SetOverlayImage(Assets.GetSprite("gfx_gui_overlay_tvchannel"))
		MenuChannelNames[i].TextDisplacement.setX(3)
		MenuChannelNames[i].setZindex(150)
	EndIf
	If i Mod 2 = 0
		MenuFigureArrows[i] = New TGUIArrowButton.Create(25+ 20+190*Ceil(i/2)+10, 125,0,"GameSettings")
	Else
		MenuFigureArrows[i] = New TGUIArrowButton.Create(25+140+190*Ceil(i/2)+10, 125,2,"GameSettings")
		MenuFigureArrows[i].rect.position.MoveXY(-MenuFigureArrows[i].GetScreenWidth(),0)
	EndIf
	MenuFigureArrows[i].setZindex(150)
Next


CreateDropZones()
Global Database:TDatabase = TDatabase.Create(); Database.Load(Game.userdb) 'load all movies, news, series and ad-contracts

SetColor 255,255,255


Global PlayerDetailsTimer:Int
'Menuroutines... Submenus and so on
Function Menu_Main()
	GUIManager.Update("MainMenu")
	If MainMenuButton_Start.GetClicks() > 0 Then Game.gamestate = GAMESTATE_SETTINGSMENU
	If MainMenuButton_Network.GetClicks() > 0
		Game.gamestate  = GAMESTATE_NETWORKLOBBY
		Game.onlinegame = 0
	EndIf
	If MainMenuButton_Online.GetClicks() > 0
		Game.gamestate = GAMESTATE_NETWORKLOBBY
		Game.onlinegame = 1
	EndIf
	'multiplayer
	If game.gamestate = GAMESTATE_NETWORKLOBBY Then Game.networkgame = 1
End Function

Function Menu_NetworkLobby()
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
'					Network.intOnlineIP = TNetwork.IntIP(Network.OnlineIP)
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

						NetgameLobbyGamelist.addItem( New TGUIGameEntry.CreateSimple(_hostIP, _hostPort, _hostName, gameTitle, slotsUsed, slotsMax) )
						Print "added "+gameTitle
					EndIf
				Wend
				CloseStream Onlinestream
			EndIf
		EndIf
	EndIf

	GUIManager.Update("NetGameLobby")
	If NetgameLobbyButton_Create.GetClicks() > 0 Then
		GameSettingsButton_Start.enable()
		Game.gamestate	= GAMESTATE_SETTINGSMENU
		Network.localFallbackIP = HostIp(game.userfallbackip)
		Network.StartServer()
		Network.ConnectToLocalServer()
		Network.client.playerID	= 1
	EndIf
	If NetgameLobbyButton_Join.GetClicks() > 0 Then
		GameSettingsButton_Start.disable()
		Network.isServer = False

		Local entry:TGUIGameEntry = TGUIGameEntry(NetgameLobbyGamelist.getSelectedEntry())
		If entry
			Local _hostIP:String = entry.data.getString("hostIP","0.0.0.0")
			Local _hostPort:Int = entry.data.getInt("hostPort",0)
			Local gameTitle:String = entry.data.getString("gameTitle","#unknowngametitle#")

			If Network.ConnectToServer( HostIp(_hostIP), _hostPort )
				Game.gamestate = GAMESTATE_SETTINGSMENU
				GameSettingsGameTitle.Value = gameTitle
			EndIf
		EndIf
	EndIf
	If NetgameLobbyButton_Back.GetClicks() > 0 Then
		Game.gamestate		= GAMESTATE_MAINMENU
		Game.onlinegame		= False

		If Network.infoStream Then Network.infoStream.close()
		Game.networkgame	= False
	EndIf
End Function

Function Menu_GameSettings()
	Local modifiedPlayers:Int = False
	Local ChangesAllowed:Byte[4]

	if Game.networkgame
		GameSettingsOkButton_Announce.show()
		GameSettingsGameTitle.show()

		If GameSettingsOkButton_Announce.crossed And Game.isGameLeader()
			GameSettingsOkButton_Announce.enable()
			GameSettingsGameTitle.disable()
			If GameSettingsGameTitle.Value = "" Then GameSettingsGameTitle.Value = "no title"
			Game.title = GameSettingsGameTitle.Value
		Else
			GameSettingsGameTitle.enable()
		EndIf
		If not Game.isGameLeader()
			GameSettingsGameTitle.disable()
			GameSettingsOkButton_Announce.disable()
		EndIf

		'disable/enable announcement on lan/online
		if GameSettingsOkButton_Announce.crossed
			Network.client.playerName = Game.Players[ Game.playerID ].name
			if not Network.announceEnabled then Network.StartAnnouncing(Game.title)
		else
			Network.StopAnnouncing()
		endif
	else
		GameSettingsOkButton_Announce.hide()
		GameSettingsGameTitle.hide()
	endif

	For Local i:Int = 0 To 3
		If Not MenuPlayerNames[i].isActive() Then Game.Players[i+1].Name = MenuPlayerNames[i].Value
		If Not MenuChannelNames[i].isActive() Then Game.Players[i+1].channelname = MenuChannelNames[i].Value
		If Game.networkgame Or Game.isGameLeader()
			If Game.gamestate <> GAMESTATE_STARTMULTIPLAYER And Game.Players[i+1].Figure.ControlledByID = Game.playerID Or (Game.Players[i+1].Figure.ControlledByID = 0 And Game.playerID=1)
				ChangesAllowed[i] = True
				MenuPlayerNames[i].enable()
				MenuChannelNames[i].enable()
				MenuFigureArrows[i*2].enable()
				MenuFigureArrows[i*2 +1].enable()
			Else
				ChangesAllowed[i] = False
				MenuPlayerNames[i].disable()
				MenuChannelNames[i].disable()
				MenuFigureArrows[i*2].disable()
				MenuFigureArrows[i*2 +1].disable()
			EndIf
		EndIf
	Next

	GUIManager.Update("GameSettings")

	If GameSettingsButton_Start.GetClicks() > 0
		If Not Game.networkgame And Not Game.onlinegame
			Game.SetGamestate(GAMESTATE_INIZIALIZEGAME)
			If Not Init_Complete
				Init_All()
				Init_Complete = True		'check if rooms/colors/... are initiated
			EndIf
			Game.SetGamestate(GAMESTATE_RUNNING)
		Else
			GameSettingsOkButton_Announce.crossed = False
			Network.StopAnnouncing()
			Interface.ShowChannel = Game.playerID

			Game.SetGamestate(GAMESTATE_STARTMULTIPLAYER)
		EndIf
	EndIf
	If GameSettingsButton_Back.GetClicks() > 0 Then
		If Game.networkgame
			If Game.networkgame Then Network.DisconnectFromServer()
			Game.playerID = 1
			Game.SetGamestate(GAMESTATE_NETWORKLOBBY)
			GameSettingsOkButton_Announce.crossed = False
			Network.StopAnnouncing()
		Else
			Game.SetGamestate(GAMESTATE_MAINMENU)
		EndIf
	EndIf

	'clicks on color rect
	Local i:Int = 0

'	rewrite to Assets instead of global list in TColor ?
'	local colors:TList = Assets.GetList("PlayerColors")

	If MOUSEMANAGER.IsHit(1)
		For Local obj:TColor = EachIn TColor.List
			'only for unused colors
			If obj.ownerID = 0
				If functions.IsIn(MouseManager.x, MouseManager.y, 26 + 40 + i * 10, 92 + 68, 7, 9) And (Game.Players[1].Figure.ControlledByID = Game.playerID Or (Game.Players[1].Figure.ControlledByID = 0 And Game.playerID = 1)) Then modifiedPlayers=True;Game.Players[1].RecolorFigure(obj)
				If functions.IsIn(MouseManager.x, MouseManager.y, 216 + 40 + i * 10, 92 + 68, 7, 9) And (Game.Players[2].Figure.ControlledByID = Game.playerID Or (Game.Players[2].Figure.ControlledByID = 0 And Game.playerID = 1)) Then modifiedPlayers=True;Game.Players[2].RecolorFigure(obj)
				If functions.IsIn(MouseManager.x, MouseManager.y, 406 + 40 + i * 10, 92 + 68, 7, 9) And (Game.Players[3].Figure.ControlledByID = Game.playerID Or (Game.Players[3].Figure.ControlledByID = 0 And Game.playerID = 1)) Then modifiedPlayers=True;Game.Players[3].RecolorFigure(obj)
				If functions.IsIn(MouseManager.x, MouseManager.y, 596 + 40 + i * 10, 92 + 68, 7, 9) And (Game.Players[4].Figure.ControlledByID = Game.playerID Or (Game.Players[4].Figure.ControlledByID = 0 And Game.playerID = 1)) Then modifiedPlayers=True;Game.Players[4].RecolorFigure(obj)
				i:+1
			EndIf
		Next
	EndIf

	'left right arrows to change figure base
	For Local i:Int = 0 To 7
		If ChangesAllowed[Ceil(i/2)]
			If MenuFigureArrows[i].GetClicks() > 0
				If i Mod 2  = 0 Then Game.Players[1+Ceil(i/2)].UpdateFigureBase(Game.Players[Ceil(1+i/2)].figurebase -1)
				If i Mod 2 <> 0 Then Game.Players[1+Ceil(i/2)].UpdateFigureBase(Game.Players[Ceil(1+i/2)].figurebase +1)
				modifiedPlayers = True
			EndIf
		EndIf
	Next

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
End Function

'test objects
TGUIObject._debugMode = FALSE
print "TGUIObject._debugMode is set to FALSE"


rem
Global TestList:TGUISlotList = new TGUISlotList.Create(20,20,300,200, "MainMenu")
TestList.SetItemLimit(10)
TestList.SetEntryDisplacement(10,8)
'free lists do not have a proper panel size
TestList.guiEntriesPanel.minSize.SetXY(300,200)
TestList.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
TestList.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").w, Assets.GetSprite("gfx_movie0").h)
TestList.SetAcceptDrop("TGUIProgrammeCoverBlock")
TestList.SetAutofillSlots(FALSE)
endrem
rem
Global TestWindow:TGUIModalWindow = new TGUIModalWindow.Create(0,0,400,200, "")
TestWindow.background.usefont = Assets.GetFont("Default", 18, BOLDFONT)
TestWindow.background.valueColor = TColor.Create(235,235,235)
TestWindow.setText("Willkommen bei TVTower", "Es handelt sich hier um eine Testversion.~nEs ist keine offizielle Demoversion die ausserhalb der Websites des Teams angeboten werden darf.~n~nSie stellt keinerlei Garantie auf Funktionstüchtigkeit bereit, auch ist es möglich, dass das Spiel auf deinem Rechner nicht richtig funktioniert, die Grafikkarte zum Platzen bringt oder Du danach den PC als Grill benutzen kannst.~n~nFalls Dir dies alles einleuchtet und Du es akzeptierst... wünschen wir Dir viel Spaß mit TVTower Version ~q"+VersionDate+"~q")
endrem



rem
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


Global MenuPreviewPicTimer:Int = 0
Global MenuPreviewPicTime:Int = 4000
Global MenuPreviewPic:TGW_Sprites = Null
Function Menu_Main_Draw()
	SetColor 190,220,240
	SetAlpha 0.5
	DrawRect(0,0,App.settings.GetWidth(),App.settings.GetHeight())
	SetAlpha 1.0
	SetColor 255, 255, 255

	Local ScaledRoomHeight:Float = 190.0
	Local RoomImgScale:Float = ScaledRoomHeight / 373.0
	Local ScaledRoomWidth:Float = RoomImgScale * 760.0

	If MenuPreviewPicTimer < MilliSecs()
		MenuPreviewPicTimer = MilliSecs() + MenuPreviewPicTime
		MenuPreviewPic = TRooms(TRooms.RoomList.ValueAtIndex(Rnd(1, TRooms.RoomList.Count() - 1))).screenManager.GetCurrentScreen().background
	EndIf
	If MenuPreviewPic <> Null
		SetBlend ALPHABLEND
		If MenuPreviewPicTimer - MilliSecs() > 3000 Then SetAlpha (4.0 - Float(MenuPreviewPicTimer - MilliSecs()) / 1000)
		If MenuPreviewPicTimer - MilliSecs() < 750 Then SetAlpha (0.25 + Float(MenuPreviewPicTimer - MilliSecs()) / 1000)
		SetScale(RoomImgScale, RoomImgScale)
		MenuPreviewPic.Draw(55 + 5, 265 + 5, RoomImgScale)
		SetScale(1.0, 1.0)
		SetAlpha (1.0)
	EndIf
	DrawGFXRect(Assets.GetSpritePack("gfx_gui_rect"), 50, 260, ScaledRoomWidth + 20, 210)

	DrawGFXRect(Assets.GetSpritePack("gfx_gui_rect"), 575, 260, 170, 210)

	GUIManager.Draw("MainMenu")
End Function

Function Menu_NetworkLobby_Draw()
	SetColor 190,220,240
	SetAlpha 0.5
	DrawRect(0,0,App.settings.GetWidth(),App.settings.GetHeight())
	SetAlpha 1.0
	SetColor 255,255,255

	If Not Game.onlinegame
		NetgameLobbyGamelist.guiBackground.value = Localization.GetString("MENU_NETWORKGAME")+" : "+Localization.GetString("MENU_AVAILABLE_GAMES")
	Else
		NetgameLobbyGamelist.guiBackground.value = Localization.GetString("MENU_ONLINEGAME")+" : "+Localization.GetString("MENU_AVAILABLE_GAMES")
	EndIf


	GUIManager.Draw("NetGameLobby")
End Function

Function Menu_GameSettings_Draw()
	SetColor 190,220,240
	SetAlpha 0.5
	DrawRect(0,0,App.settings.GetWidth(),App.settings.GetHeight())
	SetAlpha 1.0
	SetColor 255,255,255

	If Not Game.networkgame
		GameSettingsBG.value = GetLocale("MENU_SOLO_GAME")
		GameSettings_Chat.setOption(GUI_OBJECT_VISIBLE,False)
	Else
		GameSettings_Chat.setOption(GUI_OBJECT_VISIBLE,True)
		If Not Game.onlinegame Then
			GameSettingsBG.value = GetLocale("MENU_NETWORKGAME")
		Else
			GameSettingsBG.value = GetLocale("MENU_ONLINEGAME")
		EndIf
	EndIf
	'background gui items
	GUIManager.Draw("GameSettings", 0, 100)

	For Local i:Int = 0 To 3
		SetColor 50,50,50
		DrawRect(60 + i*190, 90, 110,110)
		If Game.networkgame Or Game.playerID=1
			If Game.gamestate <> GAMESTATE_STARTMULTIPLAYER And Game.Players[i+1].Figure.ControlledByID = Game.playerID Or (Game.Players[i+1].Figure.ControlledByID = 0 And Game.playerID=1)
				SetColor 255,255,255
			Else
				SetColor 225,255,150
			EndIf
		EndIf
		DrawRect(60 + i*190 +1, 90+1, 110-2,110-2)
	Next

	'player-figure background
	SetColor 100,100,120
	DrawRect(25 + 40, 110, 101, 50 + 10) '+10 for colorselectionborders
	DrawRect(215 + 40, 110, 101, 50 + 10)
	DrawRect(405 + 40, 110, 101, 50 + 10)
	DrawRect(595 + 40, 110, 101, 50 + 10)
	SetColor 180,180,200
	DrawRect(25 + 41, 111, 99, 48)
	DrawRect(215 + 41, 111, 99, 48)
	DrawRect(405 + 41, 111, 99, 48)
	DrawRect(595 + 41, 111, 99, 48)


	Local i:Int =0
	For Local obj:TColor = EachIn TColor.List
		If obj.ownerID = 0 And i <= 10
			obj.SetRGB()
			DrawRect(26 + 40 + i * 10, 92 + 68, 9, 9)
			DrawRect(216 + 40 + i * 10, 92 + 68, 9, 9)
			DrawRect(406 + 40 + i * 10, 92 + 68, 9, 9)
			DrawRect(596 + 40 + i * 10, 92 + 68, 9, 9)
			i:+1
		EndIf
	Next
	SetColor 255,255,255

	Game.Players[1].Figure.Sprite.Draw(25 + 90 - Game.Players[1].Figure.Sprite.framew / 2, 159 - Game.Players[1].Figure.Sprite.h, 8)
	Game.Players[2].Figure.Sprite.Draw(215 + 90 - Game.Players[2].Figure.Sprite.framew / 2, 159 - Game.Players[2].Figure.Sprite.h, 8)
	Game.Players[3].Figure.Sprite.Draw(405 + 90 - Game.Players[3].Figure.Sprite.framew / 2, 159 - Game.Players[3].Figure.Sprite.h, 8)
	Game.Players[4].Figure.Sprite.Draw(595 + 90 - Game.Players[4].Figure.Sprite.framew / 2, 159 - Game.Players[4].Figure.Sprite.h, 8)

	'overlay gui items (higher zindex)
	GUIManager.Draw("GameSettings", 101)
End Function

Function Menu_StartMultiplayer_Draw()
	'as background
	Menu_GameSettings_Draw()

	SetColor 180,180,200
	SetAlpha 0.5
	DrawRect 200,200,400,200
	SetAlpha 1.0
	SetColor 0,0,0
	Assets.fonts.baseFont.draw("Synchronisiere Startbedingungen...", 220,220)
	Assets.fonts.baseFont.draw("Starte Netzwerkspiel...", 220,240)


	SetColor 180,180,200
	SetAlpha 1.0
	DrawRect 200,200,400,200
	SetAlpha 1.0
	SetColor 0,0,0
	Assets.fonts.baseFont.draw("Synchronisiere Startbedingungen...", 220,220)
	Assets.fonts.baseFont.draw("Starte Netzwerkspiel...", 220,240)
	Assets.fonts.baseFont.draw("Player 1..."+Game.Players[1].networkstate+" MovieListCount: "+Game.Players[1].ProgrammeCollection.GetProgrammeCount(), 220,260)
	Assets.fonts.baseFont.draw("Player 2..."+Game.Players[2].networkstate+" MovieListCount: "+Game.Players[2].ProgrammeCollection.GetProgrammeCount(), 220,280)
	Assets.fonts.baseFont.draw("Player 3..."+Game.Players[3].networkstate+" MovieListCount: "+Game.Players[3].ProgrammeCollection.GetProgrammeCount(), 220,300)
	Assets.fonts.baseFont.draw("Player 4..."+Game.Players[4].networkstate+" MovieListCount: "+Game.Players[4].ProgrammeCollection.GetProgrammeCount(), 220,320)
	If Not Game.networkgameready = 1 Then Assets.fonts.baseFont.draw("not ready!!", 220,360)
	SetColor 255,255,255
End Function

Global StartMultiplayerSyncStarted:Int = 0
Global SendGameReadyTimer:int = 0
Function Menu_StartMultiplayer:Int()
	'master should spread startprogramme around
	If Game.isGameLeader() And Not StartMultiplayerSyncStarted
		StartMultiplayerSyncStarted = MilliSecs()

		For Local playerids:Int = 1 To 4
			Local ProgrammeArray:TProgramme[Game.startMovieAmount + Game.startSeriesAmount + 1]
			Local i:Int = 0
			For i = 0 To Game.startMovieAmount-1
				Game.Players[ playerids ].ProgrammeCollection.AddProgramme( TProgramme.GetRandomProgramme(TProgramme.TYPE_MOVIE) )
			Next
			'give series to each player
			For i = 0 To Game.startSeriesAmount-1
				Game.Players[ playerids ].ProgrammeCollection.AddProgramme( TProgramme.GetRandomProgramme(TProgramme.TYPE_SERIE) )
			Next
			'give 1 call in
			Game.Players[ playerids ].ProgrammeCollection.AddProgramme( TProgramme.GetRandomProgrammeByGenre(20) )

			For Local j:Int = 0 To Game.startAdAmount-1
				local contract:TAdContract = new TAdContract.Create(TAdContractBase.GetRandomWithLimitedAudienceQuote(0.0, 0.15))
				Game.Players[ playerids ].ProgrammeCollection.AddAdContract( contract )
			Next
		Next
	EndIf
	'ask every 500ms
	if Game.isGameLeader() and SendGameReadyTimer < millisecs()
		NetworkHelper.SendGameReady(Game.playerID)
		SendGameReadyTimer = Millisecs() +500
	endif

	If Game.networkgameready=1
		GameSettingsOkButton_Announce.crossed = False
		Game.Players[Game.playerID].networkstate=1

		'we have to set gamestate BEFORE init_all()
		'as init_all sends events which trigger gamestate-update/draw
		Game.SetGamestate(GAMESTATE_INIZIALIZEGAME)

		If Not Init_Complete
			Init_All()
			Init_Complete = True		'check if rooms/colors/... are initiated
		EndIf

		'register events and start game
		Game.SetGamestate(GAMESTATE_RUNNING)
		'reset randomizer
		Game.SetRandomizerBase( Game.GetRandomizerBase() )

		Return True
	Else
		'go back to game settings if something takes longer than expected
		If MilliSecs() - StartMultiplayerSyncStarted > 10000
			Print "sync timeout"
			StartMultiplayerSyncStarted = 0
			game.SetGamestate(GAMESTATE_SETTINGSMENU)
			Return False
		EndIf
	EndIf


End Function


Global Betty:TBetty = New TBetty
Type TBetty
	Field InLove:Float[5]
	Field LoveSum:Float
	Field AwardWinner:Float[5]
	Field AwardSum:Float = 0.0
	Field CurrentAwardType:Int = 0
	Field AwardEndingAtDay:Int = 0
	Field MaxAwardTypes:Int = 3
	Field AwardDuration:Int = 3
	Field LastAwardWinner:Int = 0
	Field LastAwardType:Int = 0

	Method IncInLove(PlayerID:Int, Amount:Float)
		For Local i:Int = 1 To 4
			Self.InLove[i] :-Amount / 4
		Next
		Self.InLove[PlayerID] :+Amount * 5 / 4
		Self.LoveSum = 0
		For Local i:Int = 1 To 4
			Self.LoveSum:+Self.InLove[i]
		Next
	End Method

	Method IncAward(PlayerID:Int, Amount:Float)
		For Local i:Int = 1 To 4
			Self.AwardWinner[i] :-Amount / 4
		Next
		Self.AwardWinner[PlayerID] :+Amount * 5 / 4
		Self.AwardSum = 0
		For Local i:Int = 1 To 4
			Self.AwardSum:+Self.AwardWinner[i]
		Next
	End Method

	Method GetAwardTypeString:String(AwardType:Int = 0)
		If AwardType = 0 Then AwardType = CurrentAwardType
		Select AwardType
			Case 0 Return "NONE"
			Case 1 Return "News"
			Case 2 Return "Kultur"
			Case 3 Return "Quoten"
		End Select
	End Method

	Method SetAwardType(AwardType:Int = 0, SetEndingDay:Int = 0, Duration:Int = 0)
		If Duration = 0 Then Duration = Self.AwardDuration
		CurrentAwardType = AwardType
		If SetEndingDay = True Then AwardEndingAtDay = Game.GetDay() + Duration
	End Method

	Method GetAwardEnding:Int()
		Return AwardEndingAtDay
	End Method

	Method GetRealLove:Int(PlayerID:Int)
		If Self.LoveSum < 100 Then Return Ceil(Self.InLove[PlayerID] / 100)
		Return Ceil(Self.InLove[PlayerID] / Self.LoveSum)
	End Method

	Method GetLastAwardWinner:Int()
		Local HighestAmount:Float = 0.0
		Local HighestPlayer:Int = 0
		For Local i:Int = 1 To 4
			If Self.GetRealAward(i) > HighestAmount Then HighestAmount = Self.GetRealAward(i) ;HighestPlayer = i
		Next
		LastAwardWinner = HighestPlayer
		Return HighestPlayer
	End Method

	Method GetRealAward:Int(PlayerID:Int)
		If Self.AwardSum < 100 Then Return Ceil(100 * Self.AwardWinner[PlayerID] / 100)
		Return Ceil(100 * Self.AwardWinner[PlayerID] / Self.AwardSum)
	End Method
End Type

Game.SetGamestate(GAMESTATE_MAINMENU)
Function UpdateMenu(deltaTime:Float=1.0)
	'	App.Timer.Update(0)
	If Game.networkgame
'		Network.client.playerName = Game.Players[Game.playerID].name
		Network.Update()
	EndIf
	Select Game.gamestate
		Case GAMESTATE_MAINMENU
			Menu_Main()
		Case GAMESTATE_NETWORKLOBBY
			Menu_NetworkLobby()
		Case GAMESTATE_SETTINGSMENU
			Menu_GameSettings()
		Case GAMESTATE_STARTMULTIPLAYER
			Menu_StartMultiplayer()
	EndSelect

	If KEYMANAGER.IsHit(KEY_ESCAPE) Then ExitGame = 1
	If AppTerminate() Then ExitGame = 1
End Function

Global LogoTargetY:Float = 20
Global LogoCurrY:Float = 100

Function DrawMenu(tweenValue:Float=1.0)
'no cls needed - we render a background
	Cls
	SetColor 255,255,255
	Assets.GetSprite("gfx_startscreen").Draw(0,0)


	Select game.gamestate
		Case GAMESTATE_SETTINGSMENU, GAMESTATE_STARTMULTIPLAYER
			Assets.GetSprite("gfx_startscreen_logoSmall").Draw(540, 480)
		Default
			If LogoCurrY > LogoTargetY Then LogoCurrY:+- 30.0 * App.Timer.getDeltaTime() Else LogoCurrY = LogoTargetY
			Assets.GetSprite("gfx_startscreen_logo").Draw(400, LogoCurrY, 0, 0, 0.5)
	EndSelect
	SetColor 0, 0, 0

	SetColor 255,255,255
	Assets.GetFont("Default",11, ITALICFONT).drawBlock(versionstring, 10,575, 500,20,0,75,75,140)
	Assets.GetFont("Default",11, ITALICFONT).drawBlock(copyrightstring, 10,585, 500,20,0,60,60,120)

	Select Game.gamestate
		Case GAMESTATE_MAINMENU
			Menu_Main_Draw()
		Case GAMESTATE_NETWORKLOBBY
			Menu_NetworkLobby_Draw()
		Case GAMESTATE_SETTINGSMENU
			Menu_GameSettings_Draw()
		Case GAMESTATE_STARTMULTIPLAYER
			Menu_StartMultiplayer_Draw()
	EndSelect

	If Game.cursorstate = 0 Then Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-7, 	MouseManager.y		,0)
	If Game.cursorstate = 1 Then Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-7, 	MouseManager.y-4	,1)
	If Game.cursorstate = 2 Then Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-10,	MouseManager.y-12	,2)
End Function


Function Init_Creation()
	'create base stations
	for local playerID:int = 1 to 4
		Game.Players[playerID].StationMap.AddStation( TStation.Create( TPoint.Create(310, 260),-1, TStationMap.stationRadius, playerID ), FALSE )
	Next


	'disable chat if not networkgaming
	if not game.networkgame
		InGame_Chat.hide()
	else
		InGame_Chat.show()
	endif		

	'Eigentlich gehört das irgendwo in die Game-Klasse... aber ich habe keinen passenden Platz gefunden... und hier werden auch die anderen Events registriert
	EventManager.registerListenerMethod( "Game.OnHour", Game.PopularityManager, "Update" );

	'set all non human players to AI
	if Game.isGameLeader()
		For Local playerids:Int = 1 To 4
			If Game.IsPlayer(playerids) And Not Game.IsHumanPlayer(playerids)
				Game.Players[playerids].SetAIControlled("res/ai/DefaultAIPlayer.lua")

				'register ai player events - but only for game leader
				EventManager.registerListener( "Game.OnMinute",	TEventListenerPlayer.Create(Game.Players[playerids]) )
				EventManager.registerListener( "Game.OnDay", 	TEventListenerPlayer.Create(Game.Players[playerids]) )
			EndIf
		Next
	endif

	'create series/movies in movie agency
	RoomHandler_MovieAgency.ReFillBlocks()

	'8 auctionable movies/series
	For local i:Int = 0 to 7
		Local programme:TProgramme = TProgramme.GetRandomProgrammeWithPrice(200000,-1)
		If programme <> null Then
			TAuctionProgrammeBlocks.Create(programme,i,-1)
		Endif
	Next


	'create random programmes and so on - but only if local game
	If Not Game.networkgame
		For Local playerids:Int = 1 To 4
			Local i:Int = 0
			For i = 0 To Game.startMovieAmount-1
				Game.Players[playerids].ProgrammeCollection.AddProgramme(TProgramme.GetRandomProgramme(TProgramme.TYPE_MOVIE))
			Next
			'give series to each player
			For i = Game.startMovieAmount To Game.startMovieAmount + Game.startSeriesAmount-1
				Game.Players[playerids].ProgrammeCollection.AddProgramme(TProgramme.GetRandomProgramme(TProgramme.TYPE_SERIE))
			Next
			'give 1 call in
			Game.Players[playerids].ProgrammeCollection.AddProgramme(TProgramme.GetRandomProgrammeByGenre(20))

			For Local i:Int = 0 To 2
				Game.Players[playerids].ProgrammeCollection.AddAdContract(new TAdContract.Create(TAdContractBase.GetRandomWithLimitedAudienceQuote(0, 0.15)) )
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

rem
Global TestPlan:TPlayerProgrammePlanNEW = new TPlayerProgrammePlanNEW.Create( Game.GetPlayer() )
local TestProg:TProgramme = Game.getPlayer().programmeCollection.getRandomProgramme()
TestPlan.AddProgramme( Game.getPlayer().programmeCollection.getRandomProgramme(), -1, 6)
TestPlan.AddProgramme( TestProg, Game.Getday(), 23)
TestPlan.AddProgramme( TestProg, Game.Getday()+1, 2)
TestPlan.AddProgramme( TestProg, Game.Getday()+1, 6)
TestPlan.AddProgramme( TestProg, Game.Getday()+1, 10)
TestPlan.AddAdvertisement( new TAdvertisement.Create(Game.getPlayer().programmeCollection.GetRandomAdContract()), -1, 6)
TestPlan.AddAdvertisement( new TAdvertisement.Create(Game.getPlayer().programmeCollection.GetRandomAdContract()), -1, 7)
TestPlan.AddAdvertisement( new TAdvertisement.Create(Game.getPlayer().programmeCollection.GetRandomAdContract()), -1, 8)
TestPlan.printOverview()
'should return 5
print "testprog is planned: "+TestPlan.HowOftenProgrammeInPlan(TestProg.id, Game.GetDay()+1, TRUE)+" times."
endrem

	local lastblocks:int=0
	'creation of blocks for players rooms
	For Local playerids:Int = 1 To 4
		lastblocks = 0
		SortList(Game.Players[playerids].ProgrammeCollection.AdContractList)

		Local addWidth:Int = Assets.GetSprite("pp_programmeblock1").w
		Local addHeight:Int = Assets.GetSprite("pp_adblock1").h
		Local playerCollection:TPlayerProgrammeCollection = Game.Players[playerids].ProgrammeCollection
		TAdBlock.Create(playerCollection.GetRandomAdContract(), 67 + addWidth, 17 + 0 * addHeight, playerids)
		TAdBlock.Create(playerCollection.GetRandomAdContract(), 67 + addWidth, 17 + 1 * addHeight, playerids)
		TAdBlock.Create(playerCollection.GetRandomAdContract(), 67 + addWidth, 17 + 2 * addHeight, playerids)

		Local lastprogramme:TProgrammeBlock
		lastprogramme = TProgrammeBlock.Create(67, 17 + 0 * Assets.GetSprite("pp_programmeblock1").h, 0, playerids, 1)
		lastblocks :+ lastprogramme.programme.blocks
		lastprogramme = TProgrammeBlock.Create(67, 17 + lastblocks * Assets.GetSprite("pp_programmeblock1").h, 0, playerids, 2)
		lastblocks :+ lastprogramme.programme.blocks
		lastprogramme = TProgrammeBlock.Create(67, 17 + lastblocks * Assets.GetSprite("pp_programmeblock1").h, 0, playerids, 3)
	Next
End Function

Function Init_Colorization()
	EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Colorization").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )
	'colorize the images
	Local gray:TColor = TColor.Create(200, 200, 200)
	Local gray2:TColor = TColor.Create(100, 100, 100)
	Assets.AddImageAsSprite("gfx_financials_barren0", Assets.GetSprite("gfx_officepack_financials_barren").GetColorizedImage( gray ) )
	Assets.AddImageAsSprite("gfx_building_sign0", Assets.GetSprite("gfx_building_sign_base").GetColorizedImage( gray ) )
	Assets.AddImageAsSprite("gfx_elevator_sign0", Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage( gray ) )
	Assets.AddImageAsSprite("gfx_elevator_sign_dragged0", Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage( gray ) )
	Assets.AddImageAsSprite("gfx_interface_channelbuttons_off0", Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage( gray2 ), Assets.GetSprite("gfx_building_sign_base").animcount )
	Assets.AddImageAsSprite("gfx_interface_channelbuttons_on0", Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage( gray2 ), Assets.GetSprite("gfx_building_sign_base").animcount )

	'colorizing for every player and inputvalues (player and channelname) to players variables
	For Local i:Int = 1 To 4
		Game.Players[i].Name		= MenuPlayerNames[i-1].Value
		Game.Players[i].channelname	= MenuChannelNames[i-1].Value
		Assets.AddImageAsSprite("gfx_financials_barren"+i, Assets.GetSprite("gfx_officepack_financials_barren").GetColorizedImage(Game.Players[i].color) )
		Assets.AddImageAsSprite("gfx_building_sign"+i, Assets.GetSprite("gfx_building_sign_base").GetColorizedImage(Game.Players[i].color) )
		Assets.AddImageAsSprite("gfx_elevator_sign"+i, Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage( Game.Players[i].color) )
		Assets.AddImageAsSprite("gfx_elevator_sign_dragged"+i, Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage(Game.Players[i].color) )
		Assets.AddImageAsSprite("gfx_interface_channelbuttons_off"+i,   Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage(Game.Players[i].color),Assets.GetSprite("gfx_interface_channelbuttons_off").animcount )
		Assets.AddImageAsSprite("gfx_interface_channelbuttons_on"+i, Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage(Game.Players[i].color),Assets.GetSprite("gfx_interface_channelbuttons_on").animcount )
	Next
End Function

Function Init_All()
	PrintDebug ("Init_All()", "start", DEBUG_START)
	Init_Creation()
	PrintDebug ("  Init_Colorization()", "colorizing Images corresponding to playercolors", DEBUG_START)
	Init_Colorization()
'triggering that event also triggers app.timer.loop which triggers update/draw of
'gamesstates - which runs this again etc.
	EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Create Roomtooltips").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )
	'setzt Raumnamen, erstellt Raum-Tooltips und Raumplaner-Schilder
	Init_CreateRoomDetails()

	EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Fill background of building").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )

	PrintDebug ("  TRooms.DrawDoorsOnBackground()", "drawing door-sprites on the building-sprite", DEBUG_START)
	TRooms.DrawDoorsOnBackground()		'draws the door-sprites on the building-sprite

	PrintDebug ("  Building.Init()", "drawing plants and lights on the building-sprite", DEBUG_START)
	Building.Init()	'draws additional gfx in the sprite, registers events...

	PrintDebug ("Init_All()", "complete", DEBUG_START)
End Function


'ingame update
Function UpdateMain(deltaTime:Float = 1.0)
	TError.UpdateErrors()
	Game.cursorstate = 0
	If Game.Players[Game.playerID].Figure.inRoom <> Null Then Game.Players[Game.playerID].Figure.inRoom.Update()

	'check for clicks on items BEFORE others check and use it
	GUIManager.Update("InGame")

	'ingamechat
	If Game.networkgame AND KEYMANAGER.IsHit(KEY_ENTER)
		If Not GUIManager.isActive(InGame_Chat.guiInput._id)
			If InGame_Chat.antiSpamTimer < MilliSecs()
				GUIManager.setActive( InGame_Chat.guiInput._id )
			Else
				Print "no spam pls (input stays deactivated)"
			EndIf
		EndIf
	EndIf

	'66 = 13th floor height, 2 floors normal = 1*73, 50 = roof
	If Game.Players[Game.playerID].Figure.inRoom = Null Then Building.pos.y =  1 * 66 + 1 * 73 + 50 - Game.Players[Game.playerID].Figure.rect.GetY()  'working for player as center
	Fader.Update(deltaTime)

	Game.Update(deltaTime)
	Interface.Update(deltaTime)
	If Game.Players[Game.playerID].Figure.inRoom = Null Then Building.Update(deltaTime)
	Building.Elevator.Update(deltaTime)
	TFigures.UpdateAll(deltaTime)

	If KEYMANAGER.IsHit(KEY_ESCAPE) Then ExitGame = 1
	If KEYMANAGER.IsHit(KEY_F12) Then App.prepareScreenshot = 1
	If Game.networkgame Then Network.Update()
End Function


'inGame
Function DrawMain(tweenValue:Float=1.0)
	local drawRoom:TRooms = Game.Players[Game.playerID].Figure.inRoom

	If not drawRoom
		TProfiler.Enter("Draw-Building")
		SetColor Int(190 * Building.timecolor), Int(215 * Building.timecolor), Int(230 * Building.timecolor)
		DrawRect(20, 10, 140, 373)
		If Building.pos.y > 10 Then DrawRect(150, 10, 500, 200)
		DrawRect(650, 10, 130, 373)
		SetColor 255, 255, 255
		Building.Draw()									'player is not in a room so draw building
		TProfiler.Leave("Draw-Building")
	Else
		TProfiler.Enter("Draw-Room")
		drawRoom.Draw()
		TProfiler.Leave("Draw-Room")
	EndIf

	Fader.Draw()
	TProfiler.Enter("Draw-Interface")
	Interface.Draw()
	TProfiler.Leave("Draw-Interface")


	If Game.DebugInfos
		SetColor 0,0,0
		DrawRect(20,10,140,373)
		SetColor 255, 255, 255
		If App.settings.directx = -1 Then Assets.fonts.baseFont.draw("Mode: OpenGL", 25,50)
		If App.settings.directx = 0  Then Assets.fonts.baseFont.draw("Mode: BufferedOpenGL", 25,50)
		If App.settings.directx = 1  Then Assets.fonts.baseFont.draw("Mode: DirectX 7", 25, 50)
		If App.settings.directx = 2  Then Assets.fonts.baseFont.draw("Mode: DirectX 9", 25,50)

		If Game.networkgame
			GUIManager.Draw("InGame") 'draw ingamechat
			SetAlpha 0.4
			SetColor 0, 0, 0
			DrawRect(660, 483,115,120)
			SetAlpha 1.0
			SetColor 255,255,255
'			Assets.fonts.baseFont.draw(Network.stream.UDPSpeedString(), 662,490)
			For Local i:Int = 0 To 3
				If Game.Players[i + 1].Figure.inRoom <> Null
					Assets.fonts.baseFont.draw("Player " + (i + 1) + ": " + Game.Players[i + 1].Figure.inRoom.Name, 25, 75 + i * 11)
				Else
					If Game.Players[i + 1].Figure.IsInElevator()
						Assets.fonts.baseFont.draw("Player " + (i + 1) + ": InElevator", 25, 75 + i * 11)
					Else If Game.Players[i + 1].Figure.IsAtElevator()
						Assets.fonts.baseFont.draw("Player " + (i + 1) + ": AtElevator", 25, 75 + i * 11)
					Else
						Assets.fonts.baseFont.draw("Player " + (i + 1) + ": Building", 25, 75 + i * 11)
					EndIf
				EndIf
			Next
		EndIf


		Local routepos:Int = 0
		Local startY:Int = 75
		If Game.networkgame Then startY :+ 4*11

		Local callType:String = ""

		local debugString:string =	"to:" + Building.elevator.TargetFloor +..
									" on:" + Building.elevator.currentFloor +..
									" dir:" + Building.elevator.Direction +..
									" status:"+Building.elevator.ElevatorStatus

		Assets.fonts.baseFont.draw(debugString, 25, startY)


		If Building.elevator.RouteLogic.GetSortedRouteList() <> Null
			For Local FloorRoute:TFloorRoute = EachIn Building.elevator.RouteLogic.GetSortedRouteList()
				If floorroute.call = 0 Then callType = " 'senden' " Else callType= " 'holen' "
				Assets.fonts.baseFont.draw(FloorRoute.floornumber + callType + FloorRoute.who.Name, 25, startY + 15 + routepos * 11)
				routepos:+1
			Next
		Else
			Assets.fonts.baseFont.draw("neu berechnen", 25, startY + 15)
		EndIf


	EndIf
	
	If Game.DebugQuoteInfos
		SetColor 0,0,0
		DrawRect(20,10,760,373)
		SetColor 255, 255, 255
		
		Local startY:Int = 25		

		'Assets.fonts.baseFont.Draw("Bevölkerung", 25, startY)
		
		Local audienceResult:TAudienceResult = TPlayer.Current().audience
		
		Local x:Int = 200
		Local y:Int = 25
		Local font:TBitmapFont = Assets.fonts.baseFontSmall

		font.drawBlock("Gesamt", x, y, 65, 25, 2, 255, 0, 0)		
		font.drawBlock("Kinder", x + (70*1), y, 65, 25, 2, 255, 255, 255)
		font.drawBlock("Jugenliche", x + (70*2), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Hausfrau.", x + (70*3), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Arbeitneh.", x + (70*4), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Arbeitslose", x + (70*5), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Manager", x + (70*6), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Rentner", x + (70*7), y, 65, 25, 2, 255, 255, 255)				
		
		
		Local wholeMarket:TAudience = audienceResult.WholeMarket
		font.Draw("Bevölkerung", 25, 50);
		DrawAudience(wholeMarket, 200, 50);	

		Local maxAudienceThisHour:TAudience = audienceResult.MaxAudienceThisHour
		Local percent:String = functions.convertPercent(audienceResult.MaxAudienceThisHourQuote.Average*100,2) + "%"		
		font.Draw("Potentielle Zuschauer", 25, 75);
		font.Draw(percent, 175, 75);
		DrawAudience(maxAudienceThisHour, 200, 75);

		Local boundAudience:TAudience = audienceResult.BoundAudience		
		font.drawStyled("      davon gebunden (Audience Flow)", 25, 90, 75, 75, 75);		
		DrawAudience(boundAudience, 200, 90, true);		
		
		Local audienceToShare:TAudience = audienceResult.AudienceToShare		
		font.drawStyled("      davon Zapper", 25, 105, 75, 75, 75);		
		DrawAudience(audienceToShare, 200, 105, true);			
		
		
		Local audience:TAudience = audienceResult.Audience 		
		font.Draw("Aktuelle Zuschauerzahl", 25, 130);		
		percent = functions.convertPercent(audienceResult.AudienceQuote.Average*100,2)		
		font.Draw(percent, 175, 130);
		DrawAudience(audience, 200, 130);
		
		
		
		Local attraction:TAudienceAdv = audienceResult.ProgrammeAttraction
		Local genre:String = "kein Genre"
		If (attraction.AudienceAttraction <> Null) Then
			genre = GetLocale("MOVIE_GENRE_"+attraction.Genre)
		Endif				
		
		
		Assets.fonts.baseFontBold.drawStyled("Sendung: " + audienceResult.Title + "     (" + genre + ")", 25, 170, 255, 0, 0);
		
		
			
		font.Draw("Basis-Programmattraktivität", 25, 190);
		percent = functions.convertPercent(attraction.RawQuality * 100,2) + "%"
		font.drawBlock(percent, 200, 190, 65, 25, 2, 255, 0, 0)
		
		font.Draw("Genre-Popularität", 25, 215);			
		Local genrePopularityMod:string = functions.convertPercent(attraction.GenrePopularityMod  * 100,0) + "%"
		Local genrePopularityQuality:string = functions.convertPercent(attraction.GenrePopularityQuality * 100,2) + "%"
		font.Draw(genrePopularityMod, 175, 215);
		font.drawBlock(genrePopularityQuality, 200, 215, 65, 25, 2, 255, 0, 0)	

		font.Draw("Genre <> Sendezeit", 25, 240);			
		Local genreTimeMod:string = functions.convertPercent(attraction.GenreTimeMod  * 100,0) + "%"
		Local genreTimeQuality:string = functions.convertPercent(attraction.GenreTimeQuality * 100,2) + "%"
		font.Draw(genreTimeMod, 175, 240);
		font.drawBlock(genreTimeQuality, 200, 240, 65, 25, 2, 255, 0, 0)			
				
		font.Draw("Genre <> Zielgruppe", 25, 260);
		DrawAudiencePercent(attraction, 200, 260);
		If (attraction.AudienceAttraction <> Null) Then
			font.drawBlock(genre, 60, 275, 205, 25, 2, 75, 75, 75 )			
			DrawAudiencePercent(attraction.AudienceAttraction, 200, 275, true, true);
		Endif		
		
		font.Draw("Image", 25, 295);	
		font.Draw("100%", 175, 295);
		DrawAudiencePercent(attraction, 200, 295);	
		
		font.Draw("Effektive Attraktivität", 25, 325);	
		DrawAudiencePercent(attraction, 200, 325);	
	EndIf	
End Function

Function DrawAudience(audience:TAudience, x:Int, y:Int, gray:Int = false)
	Local val:String
	Local x2:Int = x + 70
	Local font:TBitmapFont = Assets.fonts.baseFontSmall
	Local cr:Int = 255
	Local cg:Int = 255
	Local cb:Int = 255
		
	If gray Then
		cr = 75
		cg = 75
		cb = 75
	End If
	
	val = functions.convertValue(String(Int(audience.GetSum())), 2, 0)
	If gray Then
		font.drawBlock(val, x, y, 65, 25, 2, 150, 80, 80)
	Else	
		font.drawBlock(val, x, y, 65, 25, 2, 255, 0, 0)
	End If
	
	val = functions.convertValue(String(Int(audience.Children)), 2, 0)
	font.drawBlock(val, x2, y, 65, 25, 2, cr, cg, cb)
	
	val = functions.convertValue(String(Int(audience.Teenagers)), 2, 0)
	font.drawBlock(val, x2 + (70*1), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertValue(String(Int(audience.HouseWifes)), 2, 0)
	font.drawBlock(val, x2 + (70*2), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertValue(String(Int(audience.Employees)), 2, 0)
	font.drawBlock(val, x2 + (70*3), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertValue(String(Int(audience.Unemployed)), 2, 0)
	font.drawBlock(val, x2 + (70*4), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertValue(String(Int(audience.Manager)), 2, 0)
	font.drawBlock(val, x2 + (70*5), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertValue(String(Int(audience.Pensioners)), 2, 0)
	font.drawBlock(val, x2 + (70*6), y, 65, 25, 2, cr, cg, cb)	
End Function

Function DrawAudiencePercent(audience:TAudience, x:Int, y:Int, gray:Int = false, hideAverage:Int = false)
	Local val:String
	Local x2:Int = x + 70
	Local font:TBitmapFont = Assets.fonts.baseFontSmall
	Local cr:Int = 255
	Local cg:Int = 255
	Local cb:Int = 255
		
	If gray Then
		cr = 75
		cg = 75
		cb = 75
	End If	
	
	If Not hideAverage Then
		val = functions.convertPercent(audience.Average * 100,2) + "%"	
		If gray Then
			font.drawBlock(val, x, y, 65, 25, 2, 150, 80, 80)
		Else	
			font.drawBlock(val, x, y, 65, 25, 2, 255, 0, 0)
		End If		
	End if
	
	val = functions.convertPercent(audience.Children * 100,2) + "%"
	font.drawBlock(val, x2, y, 65, 25, 2, cr, cg, cb)
	
	val = functions.convertPercent(audience.Teenagers * 100,2) + "%"
	font.drawBlock(val, x2 + (70*1), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertPercent(audience.HouseWifes * 100,2) + "%"
	font.drawBlock(val, x2 + (70*2), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertPercent(audience.Employees * 100,2) + "%"
	font.drawBlock(val, x2 + (70*3), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertPercent(audience.Unemployed * 100,2) + "%"
	font.drawBlock(val, x2 + (70*4), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertPercent(audience.Manager * 100,2) + "%"
	font.drawBlock(val, x2 + (70*5), y, 65, 25, 2, cr, cg, cb)	
	
	val = functions.convertPercent(audience.Pensioners * 100,2) + "%"
	font.drawBlock(val, x2 + (70*6), y, 65, 25, 2, cr, cg, cb)	
End Function


'events
'__________________________________________
Type TEventOnTime Extends TEventBase
	Field time:Int = 0

	Function Create:TEventOnTime(trigger:String="", time:Int)
		Local evt:TEventOnTime = New TEventOnTime
		'evt._startTime = EventManager.getTicks() 'now
		evt._trigger	= Lower(trigger)
		'special data:
		evt.time		= time
		Return evt
	End Function
End Type

Type TEventListenerPlayer Extends TEventListenerBase
	Field Player:TPlayer

	Function Create:TEventListenerPlayer(player:TPlayer)
		Local obj:TEventListenerPlayer = New TEventListenerPlayer
		obj.player = player
		Return obj
	End Function

	Method OnEvent:Int(triggerEvent:TEventBase)
		Local evt:TEventOnTime = TEventOnTime(triggerEvent)
		If evt<>Null
			If evt._trigger = "game.onminute" And Self.Player.isAI() Then Self.Player.PlayerKI.CallOnMinute(evt.time)
			If evt._trigger = "game.onday" And Self.Player.isAI() Then Self.Player.PlayerKI.CallOnDayBegins()
		EndIf
		Return True
	End Method
End Type

Type TEventListenerOnMinute Extends TEventListenerBase

	Function Create:TEventListenerOnMinute()
		Local obj:TEventListenerOnMinute = New TEventListenerOnMinute
		Return obj
	End Function


	Method OnEvent:Int(triggerEvent:TEventBase)
		Local evt:TEventOnTime = TEventOnTime(triggerEvent)
		If evt<>Null
			'things happening x:05
			Local minute:Int = evt.time Mod 60
			Local hour:Int = Floor(evt.time / 60)

			'begin of a programme
			If minute = 5
				TPlayer.ComputeAudience()
			'call-in shows/quiz - generate income
			ElseIf minute = 54
				For Local player:TPlayer = EachIn TPlayer.list
					Local block:TProgrammeBlock = player.ProgrammePlan.GetCurrentProgrammeBlock()
					If block<>Null And block.programme.genre = GENRE_CALLINSHOW
						Local revenue:Int = player.audience.Audience.GetSum() * float(RandRange(2, 5))/100.0
						'print "audience: "+player.audience + " revenue:"+revenue + " rand:"+RandRange(2,5)
						player.finances[Game.getWeekday()].earnCallerRevenue(revenue)
					EndIf
				Next
			'ads
			ElseIf minute = 55
				TPlayer.ComputeAds()
			ElseIf minute = 0
				'Game.Quotes.calculateMaxAudiencePercentage(hour)
				TPlayer.ComputeNewsAudience()
 			EndIf
 			If minute = 5 Or minute = 55 Or minute=0 Then Interface.BottomImgDirty = True
		EndIf
		Return True
	End Method
End Type

Type TEventListenerOnDay Extends TEventListenerBase

	Function Create:TEventListenerOnDay()
		Local obj:TEventListenerOnDay = New TEventListenerOnDay
		Return obj
	End Function

	Method OnEvent:Int(triggerEvent:TEventBase)
		Local evt:TEventOnTime = TEventOnTime(triggerEvent)
		If evt<>Null
			'take over current money
			TPlayer.TakeOverMoney()

			'Neuer Award faellig?
			If Betty.GetAwardEnding() < Game.GetDay() - 1
				Betty.GetLastAwardWinner()
				Betty.SetAwardType(RandRange(0, Betty.MaxAwardTypes), True)
			End If

			For Local i:Int = 0 To TProgramme.ProgList.Count()-1
				Local Programme:TProgramme = TProgramme(TProgramme.ProgList.ValueAtIndex(i))
				If Programme <> Null Then Programme.RefreshTopicality()
			Next
			TPlayer.ComputeContractPenalties()
			TPlayer.ComputeDailyCosts()
			TAuctionProgrammeBlocks.ProgrammeToPlayer() 'won auctions moved to programmecollection of player
			'if new day, not start day
			If evt.time > 0
				'reset room signs each day to their normal position
				TRoomSigns.ResetPositions()

				'remove old news from the players (only unset ones)
				For Local i:Int = 1 To 4
					local news:TNews
					For news = EachIn Game.getPlayer(i).ProgrammeCollection.news
						If Game.GetDay() - Game.GetDay(news.newsEvent.happenedtime) >= 2
							Game.getPlayer(i).ProgrammePlan.RemoveNews(news)
						EndIf
					Next
				Next
			EndIf

		EndIf
		Return True
	End Method
End Type

Type TEventListenerOnAppUpdate Extends TEventListenerBase

	Function Create:TEventListenerOnAppUpdate()
		Return New TEventListenerOnAppUpdate
	End Function

	'wird ausgeloest wenn OnAppUpdate-Event getriggert wird
	'multi
	Method OnEvent:Int(triggerEvent:TEventBase)
		Local evt:TEventSimple = TEventSimple(triggerEvent)
		If evt<>Null
			'say soundmanager to do something
			EventManager.triggerEvent( TEventSimple.Create("App.onSoundUpdate",Null) ) 'mv 10.11.2012: Bitte den Event noch an die richtige Stelle verschieben. Der Sound braucht wohl nen eigenen Thread, sonst ruckelt es

			'EventManager.triggerEvent( TEventSimple.Create("App.UpdateKeyManager",Null, Null, Null, 1) )
			?Threaded
			LockMutex(RefreshInputMutex)
			RefreshInput = TRUE
			UnLockMutex(RefreshInputMutex)
			?
			?not Threaded
			KEYMANAGER.changeStatus()
			?

'			If Not GUIManager.getActive()
'only ignore when chat is active
if GameSettings_Chat.guiInput.isActive() then print "settingschat active"
if Ingame_chat.guiInput.isActive() then print "ingamechat active"
			If not GameSettings_Chat.guiInput.isActive() AND not InGame_Chat.guiInput.isActive()
				If KEYMANAGER.IsDown(KEY_UP) Then Game.speed:+0.10
				If KEYMANAGER.IsDown(KEY_DOWN) Then Game.speed = Max( Game.speed - 0.10, 0)

				If KEYMANAGER.IsHit(KEY_1) Game.playerID = 1
				If KEYMANAGER.IsHit(KEY_2) Game.playerID = 2
				If KEYMANAGER.IsHit(KEY_3) Game.playerID = 3
				If KEYMANAGER.IsHit(KEY_4) Game.playerID = 4
				If KEYMANAGER.IsHit(KEY_5) Then game.speed = 120.0	'60 minutes per second
				If KEYMANAGER.IsHit(KEY_6) Then game.speed = 240.0	'120 minutes per second
				If KEYMANAGER.IsHit(KEY_7) Then game.speed = 360.0	'180 minutes per second
				If KEYMANAGER.IsHit(KEY_8) Then game.speed = 480.0	'240 minute per second
				If KEYMANAGER.IsHit(KEY_9) Then game.speed = 1.0	'1 minute per second
rem
				if KEYMANAGER.IsHit(KEY_LALT) then Game.getPlayer().getFinancial().ChangeMoney(-50000)
				if KEYMANAGER.IsHit(KEY_SPACE)
					local block:TProgramme = null
					for local i:int = 0 to RoomHandler_MovieAgency.GetProgrammesInStock()-1
						local programme:TProgramme = RoomHandler_MovieAgency.GetProgrammeByPosition(i)
						if programme
							RoomHandler_MovieAgency.SellProgrammeToPlayer(programme, game.playerID)
							exit
						endif
					Next
				endif
endrem
				If KEYMANAGER.IsHit(KEY_TAB) Game.DebugInfos = 1 - Game.DebugInfos
				If KEYMANAGER.IsHit(KEY_Q) Game.DebugQuoteInfos = 1 - Game.DebugQuoteInfos
				If KEYMANAGER.IsHit(KEY_W) Game.Players[Game.playerID].Figure.EnterRoom( TRooms.GetRoomByDetails("adagency", 0), TRUE )
				If KEYMANAGER.IsHit(KEY_A) Game.Players[Game.playerID].Figure.EnterRoom( TRooms.GetRoomByDetails("archive", Game.playerID), TRUE )
				If KEYMANAGER.IsHit(KEY_B) Game.Players[Game.playerID].Figure.EnterRoom( TRooms.GetRoomByDetails("betty", 0), TRUE )
				If KEYMANAGER.IsHit(KEY_F) Game.Players[Game.playerID].Figure.EnterRoom( TRooms.GetRoomByDetails("movieagency", 0), TRUE )
				If KEYMANAGER.IsHit(KEY_O) Game.Players[Game.playerID].Figure.EnterRoom( TRooms.GetRoomByDetails("office", Game.playerID), TRUE )
				If KEYMANAGER.IsHit(KEY_C) Game.Players[Game.playerID].Figure.EnterRoom( TRooms.GetRoomByDetails("chief", Game.playerID), TRUE )
				If KEYMANAGER.IsHit(KEY_N) Game.Players[Game.playerID].Figure.EnterRoom( TRooms.GetRoomByDetails("news", Game.playerID), TRUE )
				If KEYMANAGER.IsHit(KEY_R) Game.Players[Game.playerID].Figure.EnterRoom( TRooms.GetRoomByDetails("roomboard", -1), TRUE )
				If KEYMANAGER.IsHit(KEY_D) Game.Players[Game.playerID].Stationmap.reach = Game.Players[Game.playerID].Stationmap.population
rem
				If KEYMANAGER.IsHit(KEY_Y)
					Game.Players[Game.playerID].Stationmap.GenerateShareMap()
					print "Share 1,3: "+Game.Players[Game.playerID].Stationmap.GetShare([1,3]).z
				endif
				If KEYMANAGER.IsHit(KEY_X)
					Game.Players[Game.playerID].Stationmap.GenerateShareMap()
					print "Share 2,3,4: "+Game.Players[Game.playerID].Stationmap.GetShare([2,3,4]).z
				endif
endrem

				If KEYMANAGER.IsHit(KEY_ESCAPE) ExitGame = 1				'ESC pressed, exit game
				if Game.isGameLeader()
					If KEYMANAGER.Ishit(Key_F1) And Game.Players[1].isAI() Then Game.Players[1].PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F2) And Game.Players[2].isAI() Then Game.Players[2].PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F3) And Game.Players[3].isAI() Then Game.Players[3].PlayerKI.reloadScript()
					If KEYMANAGER.Ishit(Key_F4) And Game.Players[4].isAI() Then Game.Players[4].PlayerKI.reloadScript()
				endif

				If KEYMANAGER.Ishit(Key_F5) Then NewsAgency.AnnounceNewNewsEvent()
				If KEYMANAGER.Ishit(Key_F6) Then Soundmanager.PlayMusic(MUSIC_MUSIC)

				If KEYMANAGER.Ishit(Key_F9)
					If (KIRunning)
						print "[DEV] AI deactivated"
						KIRunning = False
					Else
						print "[DEV] AI activated"
						KIRunning = True
					EndIf
				EndIf
				If KEYMANAGER.Ishit(Key_F10)
					If (KIRunning)
						for local fig:TFigures = eachin TFigures.list
							if not fig.isActivePlayer() then fig.moveable = false
						Next
						KIRunning = False
						print "[DEV] AI FIGURES deactivated"
					Else
						for local fig:TFigures = eachin TFigures.list
							if not fig.isActivePlayer() then fig.moveable = true
						Next
						KIRunning = True
						print "[DEV] AI activated"
					EndIf
				endif

			EndIf


			If Game.gamestate = 0
				UpdateMain(App.Timer.getDeltaTime())
			Else
				UpdateMenu(App.Timer.getDeltaTime())
			EndIf

			'threadsafe?
			?not Threaded
			MOUSEMANAGER.changeStatus()
			?
		EndIf
		Return True
	End Method
End Type

Type TEventListenerOnAppDraw Extends TEventListenerBase

	Function Create:TEventListenerOnAppDraw()
		Return New TEventListenerOnAppDraw
	End Function


	Method OnEvent:Int(triggerEvent:TEventBase)
		Local evt:TEventSimple = TEventSimple(triggerEvent)

		If evt<>Null
			TProfiler.Enter("Draw")
			If Game.gamestate = 0
				DrawMain()
			Else
				DrawMenu()
			EndIf
			local textX:int = 10
			Assets.fonts.baseFont.draw(	"Netstate: " + Game.Players[Game.playerID].networkstate, textX,0)
			textX:+80
			Assets.fonts.baseFont.draw(	"Speed:" + Int(Game.GetGameMinutesPerSecond() * 100), textX , 0)
			textX:+80
			Assets.fonts.baseFont.draw("FPS: "+App.Timer.currentFps, textX, 0)
			textX:+60
			Assets.fonts.baseFont.draw("UPS: " + Int(App.Timer.currentUps), textX,0)
			textX:+60
			Assets.fonts.baseFont.draw("looptime "+Int(1000*App.Timer.loopTime)+"ms", textX,0)
			textX:+100
			'RON: debug purpose - see if the managed guielements list increase over time
			Assets.fonts.baseFont.draw("GUI objects: "+ GUIManager.list.count()+"[d:"+GUIManager.GetDraggedCount()+"]" , textX,0)
			textX:+130
			If game.networkgame and Network.client
				Assets.fonts.baseFont.draw("ping: "+Int(Network.client.latency)+"ms", textX,0)
				textX:+50
			endif
			local inRoomName:string = "building"
			local targetRoomName:string = "building"
			if Game.getPlayer().figure.inRoom then inRoomName = Game.getPlayer().figure.inRoom.name
			if Game.getPlayer().figure.targetRoom then targetRoomName = Game.getPlayer().figure.targetRoom.name
			Assets.fonts.baseFont.draw("rooms: in="+ inRoomName+" to="+targetRoomName , textX,0)

			If App.prepareScreenshot = 1 Then Assets.GetSprite("gfx_startscreen_logoSmall").Draw(App.settings.GetWidth() - 10, 10, 0, 1)

			TProfiler.Enter("Draw-Flip")
				Flip App.limitFrames
			TProfiler.Leave("Draw-Flip")

			If App.prepareScreenshot = 1 Then SaveScreenshot();App.prepareScreenshot = 0
			TProfiler.Leave("Draw")
		EndIf
		Return True
	End Method
End Type

Type TEventListenerOnSoundUpdate Extends TEventListenerBase

	Function Create:TEventListenerOnSoundUpdate()
		Return New TEventListenerOnSoundUpdate
	End Function


	Method OnEvent:Int(triggerEvent:TEventBase)
		Local evt:TEventSimple = TEventSimple(triggerEvent)
		If evt<>Null
			TProfiler.Enter("SoundUpdate")
			SoundManager.Update()
			TProfiler.Leave("SoundUpdate")
		EndIf
		Return True
	End Method
End Type



'=======
' SCREEN FADE IN/OUT for active player
' - we just register for figures changing the room
'=======
'fade IN when entering or leaving a room
Function onFigureBeginChangeRoom:int( triggerEvent:TEventBase )
	local room:TRooms = TRooms( triggerEvent._sender )

	if not room or room.name="elevator" then return FALSE

	local figure:TFigures = TFigures( triggerEvent.getData().get("figure") )
	if not figure or not figure.isActivePlayer() then return FALSE

	Fader.Start()
	Fader.Enable()
End Function
'fade OUT when really entering the room (background changed etc.)
Function onFigureChangeRoom:int( triggerEvent:TEventBase )
	local room:TRooms = TRooms( triggerEvent._sender )
	if not room or room.name="elevator" then return FALSE

	local figure:TFigures = TFigures( triggerEvent.getData().get("figure") )
	if not figure then return FALSE
	if not figure or not figure.isActivePlayer() then return FALSE

	Fader.StartFadeout()
	Fader.Enable()
End Function
'for entering and leaving the room
EventManager.registerListenerFunction( "room.OnBeginEnter", onFigureBeginChangeRoom )
EventManager.registerListenerFunction( "room.OnBeginLeave", onFigureBeginChangeRoom )
EventManager.registerListenerFunction( "room.OnEnter", onFigureChangeRoom )
EventManager.registerListenerFunction( "room.OnLeave", onFigureChangeRoom )
'=======


'__________________________________________
'events
EventManager.registerListener( "Game.OnDay", 	TEventListenerOnDay.Create() )
EventManager.registerListener( "Game.OnMinute",	TEventListenerOnMinute.Create() )
EventManager.registerListenerFunction( "Game.OnStart",	TGame.onStart )
rem
'we do not want them to happen in each timer loop but on request...
EventManager.registerListenerFunction( "App.UpdateKeymanager",	UpdateKeymanager )
EventManager.registerListenerFunction( "App.UpdateMouseManager",UpdateMousemanager )

Function UpdateKeymanager:int( triggerEvent:TEventBase )
	KEYMANAGER.ChangeStatus()
End Function
Function UpdateMousemanager:int( triggerEvent:TEventBase )
	MOUSEMANAGER.ChangeStatus()
End Function
endrem

rem
print "ALLE SPIELER DEAKTIVIERT"
print "ALLE SPIELER DEAKTIVIERT"
print "ALLE SPIELER DEAKTIVIERT"
print "ALLE SPIELER DEAKTIVIERT"
print "ALLE SPIELER DEAKTIVIERT"
for local fig:TFigures = eachin TFigures.list
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
App.StartApp() 'all resources loaded - switch Events for Update/Draw from Loader to MainEvents

Global RefreshInput:int = TRUE
?Threaded
Global RefreshInputMutex:TMutex = CreateMutex()
?

If ExitGame <> 1 And Not AppTerminate()'not exit game
	KEYWRAPPER.allowKey(13, KEYWRAP_ALLOW_BOTH, 400, 200)
	Repeat
		App.Timer.loop()

		'we cannot fetch keystats in threads
		'so we have to do it 100% in the main thread - same for mouse
	?Threaded
	if RefreshInput
		LockMutex(RefreshInputMutex)
		KEYMANAGER.changeStatus()
		MOUSEMANAGER.changeStatus()
		RefreshInput = FALSE
		UnLockMutex(RefreshInputMutex)
	endif
	?

		'process events not directly triggered
		'process "onMinute" etc. -> App.OnUpdate, App.OnDraw ...
		EventManager.update()

		'If RandRange(0,20) = 20 Then GCCollect()
	Until AppTerminate() Or ExitGame = 1
	If Game.networkgame Then Network.DisconnectFromServer()
EndIf 'not exit game


OnEnd( EndHook )
Function EndHook()
	TProfiler.DumpLog("log.profiler.txt")
	TLogFile.DumpLog(False)

End Function