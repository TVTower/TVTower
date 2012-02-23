'Application: TVGigant/TVTower
'Author: Ronny Otto

SuperStrict
'Framework brl.glmax2d
Import brl.timer
Import brl.Graphics
Import brl.maxlua
Import brl.reflection
Import brl.threads
Import "bnetex.bmx"								'udp and tcpip-layer and functions
'Import "changelog.bmx"							'holds the notes for changes and additions

Import "basefunctions.bmx"						'Base-functions for Color, Image, Localization, XML ...
Import "files.bmx"								'Load images, configs,... (imports functions.bmx)
Import "basefunctions_guielements.bmx"			'Guielements like Input, Listbox, Button...
Import "basefunctions_events.bmx"				'event handler
Import "basefunctions_deltatimer.bmx"
GUIManager.globalScale = 0.75
GUIManager.defaultFont	= FontManager.GW_GetFont("Default", 12)


Include "gamefunctions_tvprogramme.bmx"  		'contains structures for TV-programme-data/Blocks and dnd-objects
Include "gamefunctions.bmx" 					'Types: - TError - Errorwindows with handling
												'		- base class For buttons And extension newsbutton
												'		- stationmap-handling, -creation ...
Include "gamefunctions_rooms.bmx"				'basic roomtypes with handling

Include "lua_ki.bmx"							'LUA connection

'Initialise Render-To-Texture
tRender.Initialise()

Global Fader:TFader	= New TFader
Global PrepareScreenshot:Int = 0


Global ArchiveProgrammeList:TgfxProgrammelist	= TgfxProgrammelist.Create(580, 30)
Global PPprogrammeList:TgfxProgrammelist		= TgfxProgrammelist.Create(520, 30)
Global PPcontractList:TgfxContractlist			= TgfxContractlist.Create(650, 30)

Print "onclick-eventlistener integrieren: btn_newsplanner_up/down"
Global Btn_newsplanner_up:TGUIImageButton		= TGUIImageButton.Create(375, 150, 47, 32, gfx_news_pp_btn, 0, 1, 0, "Newsplanner", 0)
Global Btn_newsplanner_down:TGUIImageButton		= TGUIImageButton.Create(375, 250, 47, 32, gfx_news_pp_btn, 0, 1, 0, "Newsplanner", 3)

Local tmpPix:TPixmap = LockImage(Assets.GetSprite("gfx_building").parent.image)
Print "grosse bilder automatisch auf 'bigimage' umstellen"
Global gfx_building_skyscraper:TBigImage = TBigImage.CreateFromPixmap(tmpPix)
UnlockImage(Assets.GetSprite("gfx_building").parent.image)

Global SaveError:TError, LoadError:TError
Global ExitGame:Int 				= 0 			'=1 and the game will exit

Global NewsAgency:TNewsAgency = New TNewsAgency

SeedRand(103452)

TButton.UseFont 		= FontManager.GW_GetFont("Default", 12, 0)
TTooltip.UseFontBold	= FontManager.GW_GetFont("Default", 11, BOLDFONT)
TTooltip.UseFont 		= FontManager.GW_GetFont("Default", 11, 0)
TTooltip.ToolTipIcons	= gfx_building_tooltips
TTooltip.TooltipHeader	= Assets.GetSprite("gfx_tooltip_header")

Global App:TApp = TApp.Create(100, 1, WIDTH, HEIGHT) 'create with 60fps for physics and graphics

Type TApp
	Field Timer:TDeltaTimer
	Field limitFrames:Int = 0
	Field height:Int = 600
	Field width:Int = 800

	Function Create:TApp(physicsFps:Int = 60, limitFrames:Int = 0, width:Int = 800, height:Int = 600)
		Local obj:TApp = New TApp
		obj.width = width
		obj.height = height
		'create timer
		obj.timer = TDeltaTimer.Create(physicsFps)
		'listen to App-timer
		EventManager.registerListener( "App.onUpdate", 	TEventListenerOnAppUpdate.Create() )
		EventManager.registerListener( "App.onDraw", 	TEventListenerOnAppDraw.Create() )

		Return obj
	End Function
End Type

'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame
	''rename CONFIG-vars ... config_DoorOpenTime... config_gameSpeed ...

	Field debugmode:Byte			= 0 {sl = "no"}		'0=no debug messages; 1=some debugmessages
	Field DebugInfos:Byte			= 0 {sl = "no"}
	Field speed:Float				= 0.1 				'Speed of the game
	Field oldspeed:Float			= 0.1 				'Speed of the game
	Field DoorOpenTime:Int			= 100 {sl = "no"}	'time how long a door will be shown open until figure enters
	Field minutesOfDayGone:Float	= 0.0				'time of day in game, unformatted
	Field lastMinutesOfDayGone:Float= 0.0				'time last update was done
	Field timeSinceBegin:Float 							'time in game, not reset every day
	Field year:Int=2006, day:Int=1, minute:Int=0, hour:Int=0 'date in game

	Field cursorstate:Int		 	= 0 				'which cursor has to be shown? 0=normal 1=dragging
	Field playerID:Int 				= 1					'playerID of player who sits in front of the screen
	Field start_MovieAmount:Int 	= 5 {sl = "no"}		'how many movies does a player get on a new game
	Field start_AdAmount:Int		= 3 {sl = "no"}		'how many contracts a player gets on a new game
	Field error:Int 				= 0 				'is there a error (errorbox) floating around?
	Field maxAudiencePercentage:Float 	= 0.3 			'how many 0.0-1.0 (100%) audience is maximum reachable
	Field maxContractsAllowed:Int 		= 10			'how many contracts a player can possess
	Field maxMoviesInSuitcaseAllowed:Int= 12			'how many movies can be carried in suitcase
	Field gamestate:Int 			= 0					'0 = Mainmenu, 1=Running, ...
	Field networkgame:Int 			= 0 				'are we playing a network game? 0=false
	Field networkgameready:Int 		= 0 				'is the network game ready - all options set? 0=false
	Field onlinegame:Int 			= 0 				'playing over internet? 0=false
	Field title:String 				= "MyGame"			'title of the game
	Field daytoplan:Int 			= day 				'which day has to be shown in programmeplanner
	Field daynames:String[] {sl = "no"}					'array of abbreviated (short) daynames
	Field daynames_long:String[] {sl = "no"}			'array of daynames (long version)
	Field fullscreen:Int = 0 {sl = "no"}				'playing fullscreen? 0=false
	Field username:String = "Ano Nymus" {sl = "no"}		'username of the player
	Field userport:Short = 4444 {sl = "no"}				'userport of the player
	Field userchannelname:String = "SunTV" {sl = "no"}	'channelname the player uses
	Field userlanguage:String = "de" {sl = "no"}		'language the player uses
	Field userdb:String = "res/database.xml" {sl = "no"}
	Field userfallbackip:String = "" {sl = "no"}
	Global List:TList {sl = "no"}						'list of all games, mainly only one

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
	End Function

	'Summary: saves all objects of the game (figures, quotes...)
	Function SaveGame:Int(savename:String="savegame.xml")
		LoadSaveFile.InitSave()   'opens a savegamefile for getting filled
		For Local i:Int = 1 To 4
			If Player[i] <> Null
				If Player[i].PlayerKI = Null And Player[i].figure.controlledbyID = 0 Then PrintDebug ("TGame.Update()", "FEHLER: KI fuer Spieler " + i + " nicht gefunden", DEBUG_UPDATES)
				If Player[i].figure.controlledbyID = 0
					LoadSaveFile.xmlWrite("KI"+i, Player[i].PlayerKI.CallOnSave())
				EndIf
			EndIf
		Next
		LoadSaveFile.SaveObject(Game, "GAMESETTINGS", Null) ; TError.DrawErrors() ;Flip 0  'XML
		LoadSaveFile.SaveObject(TFigures.List, "FIGURES", TFigures.AdditionalSave) ; TError.DrawErrors() ;Flip 0  'XML
		LoadSaveFile.SaveObject(TPlayer.List, "PLAYERS", TFigures.AdditionalSave) ; TError.DrawErrors() ;Flip 0  'XML


		TStationMap.SaveAll();				TError.DrawErrors();Flip 0  'XML
		TAudienceQuotes.SaveAll();			TError.DrawErrors();Flip 0  'XML
		TProgramme.SaveAll();	 			TError.DrawErrors();Flip 0  'XML
		TContract.SaveAll();	  			TError.DrawErrors();Flip 0  'XML
		TNews.SaveAll();	  				TError.DrawErrors();Flip 0  'XML
		TContractBlocks.SaveAll();			TError.DrawErrors();Flip 0  'XML
		TProgrammeBlock.SaveAll();			TError.DrawErrors();Flip 0  'XML
		TAdBlock.SaveAll();					TError.DrawErrors();Flip 0  'XML
		TNewsBlock.SaveAll();				TError.DrawErrors();Flip 0  'XML
		TMovieAgencyBlocks.SaveAll();		TError.DrawErrors();Flip 0  'XML
		TArchiveProgrammeBlocks.SaveAll();	TError.DrawErrors();Flip 0  'XML
		Building.Elevator.Save();			TError.DrawErrors();Flip 0  'XML
		Delay(50)
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
		If LoadSaveFile.file = Null
			PrintDebug("TGame.LoadGame()", "Spielstandsdatei defekt!", DEBUG_SAVELOAD)
			TError.DrawNewError("Spielstandsdatei defekt!...") ;Delay(2500)
		Else
			Local NodeList:TList = LoadSaveFile.node.ChildList
			For Local NODE:xmlNode = EachIn NodeList
				LoadSaveFile.NODE = NODE
				Select LoadSaveFile.NODE.Name
					Case "KI1"
						Player[1].PlayerKI.CallOnLoad(LoadSaveFile.NODE.Value)
					Case "KI2"
						Player[2].PlayerKI.CallOnLoad(LoadSaveFile.NODE.Value)
					Case "KI3"
						Player[3].PlayerKI.CallOnLoad(LoadSaveFile.NODE.Value)
					Case "KI4"
						Player[4].PlayerKI.CallOnLoad(LoadSaveFile.NODE.Value)
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
					Case "ALLAUDIENCEQUOTES"
						TError.DrawNewError("Lade Quotenarchiv...")
						TAudienceQuotes.LoadAll()
					Case "ALLPROGRAMMES"
						TError.DrawNewError("Lade Programme...")
						TProgramme.LoadAll()
					Case "ALLCONTRACTS"
						TError.DrawNewError("Lade Werbeverträge...")
					'TContract.LoadAll()
					Case "ALLNEWS"
						TError.DrawNewError("Lade Nachrichten...")
					'TNews.LoadAll()
					Case "ALLCONTRACTBLOCKS"
						TError.DrawNewError("Lade Werbeverträgeblöcke...")
					'TContractBlocks.LoadAll()
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
		Game.networkgame	= 0
		Game.minutesOfDayGone	= 0
		Game.day 			= 1
		Game.minute 		= 0
		Game.title			= "unknown"
		Game.daynames		= [	Localization.GetString("WEEK_SHORT_MONDAY"), 	Localization.GetString("WEEK_SHORT_TUESDAY"),..
								Localization.GetString("WEEK_SHORT_WEDNESDAY"), Localization.GetString("WEEK_SHORT_THURSDAY"),..
								Localization.GetString("WEEK_SHORT_FRIDAY"),	Localization.GetString("WEEK_SHORT_SATURDAY"),..
								Localization.GetString("WEEK_SHORT_SUNDAY") ]
		Game.daynames_long	= [	Localization.GetString("WEEK_LONG_MONDAY"),		Localization.GetString("WEEK_LONG_TUESDAY"),..
								Localization.GetString("WEEK_LONG_WEDNESDAY"),	Localization.GetString("WEEK_LONG_THURSDAY"),..
								Localization.GetString("WEEK_LONG_FRIDAY"),		Localization.GetString("WEEK_LONG_SATURDAY"),..
								Localization.GetString("WEEK_LONG_SUNDAY") ]
		If Not List Then List = New TList
		List.AddLast(Game)
		List.Sort()
		Return Game
	End Function

	'Summary: load the config-file and set variables depending on it
	Method LoadConfig:Byte(configfile:String="config/settings.xml")
		Local root:xmlNode
		Local XMLFile:xmlDocument = xmlDocument.Create(configfile)
		If XMLFile <> Null Then PrintDebug ("TGame.LoadConfig()", "settings.xml eingelesen", DEBUG_LOADING)
		root = XMLFile.root().FindChild("settings")
		If root = Null Then Throw "XML:root not found"
		If root.Name = "settings" Then
			If root.FindChild("username") <> Null
				Self.username = (root.FindChild("username").Value)
			Else
				PrintDebug ("TGame.LoadConfig()", "settings.xml - 'username' fehlt, setze Defaultwert: 'Ano Nymus'", DEBUG_LOADING)
				Self.username = "Ano Nymus"
			EndIf

			If root.FindChild("channelname") <> Null
				Self.userchannelname = (root.FindChild("channelname").Value)
			Else
				PrintDebug ("TGame.LoadConfig()", "settings.xml - 'userchannelname' fehlt, setze Defaultwert: 'SunTV'", DEBUG_LOADING)
				Self.userchannelname = "SunTV"
			EndIf

			If root.FindChild("language") <> Null
				Self.userlanguage	 = (root.FindChild("language").Value)
			Else
				PrintDebug ("TGame.LoadConfig()", "settings.xml - 'language' fehlt, setze Defaultwert: 'de'", DEBUG_LOADING)
				Self.userlanguage = "de"
			EndIf

			If root.FindChild("onlineport") <> Null
				Self.userport = Short(root.FindChild("onlineport").Value)
			Else
				PrintDebug ("TGame.LoadConfig()", "settings.xml - 'onlineport' fehlt, setze Defaultwert: '4444'", DEBUG_LOADING)
				Self.userport = 4444
			EndIf

			If root.FindChild("database") <> Null
				Self.userdb	 = (root.FindChild("database").Value)
			Else
				Print "settings.xml - missing 'database' - set to default: 'database.xml'"
				Self.userdb = "res/database.xml"
			EndIf

			If root.FindChild("defaultgamename") <> Null
				Self.title	 = (root.FindChild("defaultgamename").Value)
			Else
				PrintDebug ("TGame.LoadConfig()", "settings.xml - 'defaultgamename' fehlt, setze Defaultwert: 'MyGame'", DEBUG_LOADING)
				Self.title = "MyGame"
			EndIf

			If root.FindChild("fullscreen") <> Null
				Self.fullscreen	 = Int(root.FindChild("fullscreen").Value)
			Else
				PrintDebug ("TGame.LoadConfig()", "settings.xml - 'fullscreen' fehlt, setze Defaultwert: '0' (Fenster)", DEBUG_LOADING)
				Self.fullscreen = 0
			EndIf

			If root.FindChild("fallbacklocalip") <> Null
				Self.userfallbackip = root.FindChild("fallbacklocalip").Value
			Else
				PrintDebug ("TGame.LoadConfig()", "settings.xml - 'fallbacklocalip' fehlt, setze Defaultwert: '192.168.0.1'", DEBUG_LOADING)
				Self.userfallbackip = "192.168.0.1"
			EndIf
		EndIf
	End Method

	Method getNextHour:Int()
		If Self.hour+1 > 24 Then Return Self.hour+1 - 24
		Return Self.hour + 1
	End Method

	'Summary: Updates Time, Costs, States ...
	Method Update(deltaTime:Float=1.0)
		Self.minutesOfDayGone :+ (Float(speed) / 10.0)
		Self.timeSinceBegin	:+ (Float(speed) / 10.0)

		If (Game.networkgame And Game.playerID = 1) Or (Not Game.networkgame)
			If NewsAgency.NextEventTime < timeSinceBegin Then NewsAgency.AnnounceNewNews()
		EndIf

		'if speed to high - potential skip of minutes, so "fetch them"
		'sets minute / hour / day
		Local missedMinutes:Int = Floor( Self.minutesOfDayGone - Self.lastMinutesOfDayGone)
		If missedMinutes > 0
			For Local i:Int = 1 To missedMinutes
				Self.minute = Floor ( Self.lastMinutesOfDayGone + i ) Mod 60 '0 to 59
				EventManager.registerEvent(TEventOnTime.Create("Game.OnMinute", Self.minute))

				'hour
				If Self.minute = 0
					Self.hour = Floor( (Self.lastMinutesOfDayGone + i) / 60) Mod 24 '0 after midnight
					EventManager.registerEvent(TEventOnTime.Create("Game.OnHour", Self.hour))
				EndIf

				'day
				If Self.hour = 0 And Self.minute = 0
					Self.minutesOfDayGone 	= 0			'reset minutes of day
					Self.day				:+1			'increase current day
					Self.daytoplan 			= Self.day 	'weg, wenn doch nicht automatisch wechseln
					EventManager.registerEvent(TEventOnTime.Create("Game.OnDay", Self.day))
				EndIf
			Next
			Self.lastMinutesOfDayGone = Self.minutesOfDayGone
		EndIf
	End Method

	'Summary: returns day of the week including gameday
	Method GetFormattedDay:String(_day:Int = -5)
		If _day <= 0 Then _day = 1
		Return _day+"."+Localization.GetString("DAY")+" ("+daynames[((_day-1) Mod 7)]+")"
	End Method

	Method GetFormattedDayLong:String(_day:Int = -5)
		If _day <= 0 Then _day = 1
		Return daynames_long[((_day-1) Mod 7)]
	End Method

	'Summary: returns formatted value of actual gametime
	Method GetFormattedTime:String()
		Local strHours:String = Self.hour
		Local strMinutes:String = Self.minute

		If Self.hour < 10 Then strHours = "0"+strHours
		If Self.minute < 10 Then strMinutes = "0"+strMinutes
		Return strHours+":"+strMinutes
	End Method

	Method GetFormattedExternTime:String(hour:Int, _minute:Int)
		Local minute:String = ""
		If Int(_minute) Mod 60 < 10
			minute = "0"+Int(_minute) Mod 60
		Else
			minute = Int(_minute Mod 60)
		End If
		Return hour+":"+minute
	End Method

	Method GetActualDay:Int(_time:Int = 0)
		If _time = 0 Then Return Self.day
		_time = Ceil(_time / (24 * 60)) + 1
		Return Int(_time)
	End Method

	Method GetActualMinute:Int(_time:Int = 0)
		If _time = 0 Then Return Self.minute
		_time:-((Game.day - 1) * 24 * 60)
		Return Int(_time) Mod 60
	End Method

	Method GetActualHour:Int(_time:Int = 0)
		If _time = 0 Then Return Self.hour
		_time:-(Game.day - 1) * 24 * 60
		Return Int(Floor(_time / 60))
	End Method
End Type

'class holding name, channelname, infos about the figure, programmeplan, programmecollection and so on - from a player
Type TPlayer
	Field Name:String 						{saveload = "normal"}		'playername
	Field channelname:String 				{saveload = "normal"} 		'name of the channel
	Field finances:TFinancials[7]										'One week of financial stats about credit, money, payments ...
	Field audience:Int 			= 0 		{saveload = "normal"}		'general audience
	Field maxaudience:Int 		= 0 		{saveload = "normal"}		'maximum possible audience
	Field ProgrammeCollection:TPlayerProgrammeCollection
	Field ProgrammePlan:TPlayerProgrammePlan
	Field ActualProgramme:TProgramme									'holds actual programme running on players channel
	Field ActualContract:TContract										'holds actual contract running on players channel
	Field Figure:TFigures												'actual figure the player uses
	Field playerID:Int 			= 0			{saveload = "normal"}		'global used ID of the player
	Field color:TPlayerColor											'the playercolor used to colorize symbols and figures
	Field figurebase:Int 		= 0			{saveload = "normal"}		'actual number of an array of figure-images
	Field networkstate:Int 		= 0			{saveload = "normal"}		'1=ready, 0=not set, ...
	Field newsabonnements:Int[6]										'abonnementlevels for the newsgenres
	Field PlayerKI:KI			= Null
	Global globalID:Int			= 1
	Global List:TList = CreateList()
	Field CreditCurrent:Int = 200000
	Field CreditMaximum:Int = 300000

	Function Load:Tplayer(pnode:xmlNode)
		Local Player:TPlayer = TPlayer.Create("save", "save", Assets.GetSpritePack("figures").GetSprite("Man1") , 0, 0, 0, 0, 0, 0, 1, "")
		TFigures.List.Remove(Player.figure)
		Local i:Int = 0, j:Int = 0
		Local colr:Byte = 0, colg:Byte = 0, colb:Byte = 0
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
				Case "COLORR" colR = Byte(nodevalue)
				Case "COLORG" colG = Byte(nodevalue)
				Case "COLORB" colB = Byte(nodevalue)
				Case "FIGUREID" FigureID = Int(nodevalue)
				Case "NEWSABONNEMENTS0" Or "NEWSABONNEMENTS1" Or "NEWSABONNEMENTS2" Or "NEWSABONNEMENTS3" Or "NEWSABONNEMENTS4" Or "NEWSABONNEMENTS5"
					If TNewsbuttons.GetButton(j, Player.playerID) <> Null Then TNewsbuttons.GetButton(j, Player.playerID).clickstate = Player.newsabonnements[j] ;j:+1
			End Select
			Node = Node.NextSibling()
		Wend
		Player.color = TPlayerColor.GetColor(colr, colg, colb)
			.Player[Player.playerID] = Player  '.player is player in root-scope
		Player.Figure = TFigures.GetFigure(FigureID)
		If Player.figure.controlledByID = 0 And Game.playerID = 1 Then
			PrintDebug("TPlayer.Load()", "Lade AI für Spieler" + Player.playerID, DEBUG_SAVELOAD)
			Player.playerKI = KI.Create(Player.playerID, "res/ai/DefaultAIPlayer.lua")
		EndIf
		Player.Figure.ParentPlayer = Player
		Player.UpdateFigureBase(Player.figurebase)
		Player.RecolorFigure(Player.color)
		Return Player
	End Function

	Function LoadAll()
		TPlayer.List.Clear()
		Player[1] = Null;Player[2] = Null;Player[3] = Null;Player[4] = Null;
		TPlayer.globalID = 1
		TFinancials.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local node:xmlNode = EachIn Children
			If NODE.Name = "PLAYER"
				TPlayer.Load(NODE)
			End If
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
		LoadSaveFile.xmlWrite("COLORR",			Self.color.colr)
		LoadSaveFile.xmlWrite("COLORG",			Self.color.colg)
		LoadSaveFile.xmlWrite("COLORB",			Self.color.colb)
		LoadSaveFile.xmlWrite("FIGUREID", Self.figure.id)
		For Local j:Int = 0 To 5
			LoadSaveFile.xmlWrite("NEWSABONNEMENTS"+j,	Self.newsabonnements[j])
		Next
		LoadSaveFile.xmlCloseNode()
	End Method

	'creates and returns a player
	'-creates the given playercolor and a figure with the given
	' figureimage, a programmecollection and a programmeplan
	Function Create:TPlayer(Name:String, channelname:String = "", ImageOrSprite:Object, x:Int, onFloor:Int = 13, dx:Int, pcolr:Int, pcolg:Int, pcolb:Int, ControlledByID:Int = 1, FigureName:String = "")
		Local Player:TPlayer = New TPlayer
		Player.Name = Name
		Player.playerID = globalID
		Player.color = TPlayerColor.Create(pcolr,pcolg,pcolb, TPlayer.globalID)
		Player.channelname = channelname
		Player.Figure = TFigures.Create(FigureName, imageOrSprite, x, onFloor, dx, ControlledByID)
		Player.Figure.ParentPlayer = Player
		If controlledByID = 0 And Game.playerID = 1 Then
			If TPlayer.globalID = 2
				Player.PlayerKI = KI.Create(Player.playerID, "res/ai/DefaultAIPlayer.lua")
			Else
				Player.PlayerKI = KI.Create(Player.playerID, "res/ai/alt/test_base.lua")			
			EndIf
		EndIf
		For Local i:Int = 0 To 6
			Player.finances[i] = TFinancials.Create(Player.playerID, 550000, 250000)
			Player.finances[i].revenue_before = 550000
			Player.finances[i].revenue_after  = 550000
		Next
		Player.ProgrammeCollection = New TPlayerProgrammeCollection
		Player.ProgrammePlan = TPlayerProgrammePlan.Create()

		Player.Figure.Sprite = Assets.GetSpritePack("figures").GetSpriteByID(0)
		Player.Figure.Sprite = Assets.GetSpritePack("figures").GetSprite("Player" + Player.playerID)
		Player.RecolorFigure(Player.color.GetUnusedColor(globalID))
		Player.UpdateFigureBase(0)
		If Not List Then List = CreateList()
		List.AddLast(Player)
		SortList List
		TPlayer.globalID:+1
		Return Player
	End Function

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
		DrawOnPixmap(ColorizeTImage(Assets.GetSpritePack("figures").GetSpriteImage("", figurebase, False), color.colR, color.colG, color.colB), 0, tmppix, tmpSprite.Pos.x, tmpSprite.Pos.y)
		UnlockImage(Assets.GetSpritePack("figures").image, 0)
	End Method

	'colorizes a figure and the corresponding sign next to the players doors in the building
	Method RecolorFigure(PlayerColor:TPlayerColor)
		color.used	= 0
		color		= PlayerColor
		color.used	= playerID
		UpdateFigureBase(figurebase)
		Print "RecolorFigure r:" + color.colR + " g" + color.colG + " b" + color.colB
		'overwrite asset
		Assets.AddImageAsSprite( "gfx_building_sign"+String(playerID), ColorizeTImage(Assets.GetImage("gfx_building_sign_base"), color.colR, color.colG, color.colB) )
	End Method

	'nothing up to now
	Method UpdateFinances:Int()
		For Local i:Int = 0 To 6
		Next
	End Method

	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetAudiencePercentage:Int()
		If maxaudience > 0
			Return Floor((audience * 100) / maxaudience)
		EndIf
		Return 0
	End Method

	'returns value chief will give as credit
	Method GetCreditAvaiable:Int()
		Return Max(0, Self.CreditMaximum - Self.CreditCurrent)
	End Method

	Method GetCreditCurrent:Int()
		Return Self.CreditCurrent
	End Method

	'helper to call from external types - only for current game.playerID-Player
	Function extSetCredit:String(amount:Int)
		Player[Game.playerID].SetCredit(amount)
	End Function

	'increases Credit
	Method SetCredit(amount:Int)
		Self.finances[TFinancials.GetDayArray(Game.day)].money:+amount
		Self.finances[TFinancials.GetDayArray(Game.day)].credit:+amount
		Self.CreditCurrent:+amount
	End Method

	'computes daily costs like station or newsagency fees for every player
	Function ComputeDailyCosts()
		Local playerID:Int = 1
		For Local Player:TPlayer = EachIn TPlayer.List
			'stationfees
			Player.finances[TFinancials.GetDayArray(Game.day)].PayStationFees(StationMap.CalculateStationCosts(playerID))

			'newsagencyfees
			Local newsagencyfees:Int =0
			For Local i:Int = 0 To 5
				newsagencyfees:+ Player.newsabonnements[i]*10000 'baseprice for an subscriptionlevel
			Next
			Player.finances[TFinancials.GetDayArray(Game.day)].PayNewsAgencies((newsagencyfees/2))

			playerID :+1
		Next
	End Function

	'computes ads - if a adblock is botched or run successful
	'if successfull and ad-contract finished then it sells the ad (earn money)
	Function ComputeAds()
		Local Adblock:TAdBlock
		For Local Player:TPlayer = EachIn TPlayer.List
			Adblock = Player.ProgrammePlan.GetActualAdBlock(Player.playerID)
			If Adblock <> Null
				If Player.audience < Adblock.contract.calculatedMinAudience
					'Print "player audience:"+player.audience + " < "+Adblock.contract.calculatedMinAudience
					Adblock.botched = 1
					Adblock.contract.botched = 1
					Adblock.GetPreviousContractCount()
				EndIf
				If Player.audience >= Adblock.contract.calculatedMinAudience
					'Print "player audience:"+player.audience + " < "+Adblock.contract.calculatedMinAudience
					Adblock.botched = 3
					Adblock.contract.botched = 3
				EndIf
				If Player.audience > Adblock.contract.calculatedMinAudience And Adblock.contract.spotnumber >= Adblock.contract.spotcount
					Adblock.contract.botched = 2
					Player.finances[TFinancials.GetDayArray(Game.day)].SellAds(Adblock.contract.calculatedProfit)
					AdBlock.RemoveOverheadAdblocks() 'removes Blocks which are more than needed (eg 3 of 2 to be shown Adblocks)
					'Print "should remove contract:"+adblock.contract.title
					TContractBlocks.RemoveContractFromSuitcase(Adblock.contract)
					Player.ProgrammeCollection.RemoveOriginalContract(Adblock.contract)
				EndIf
			EndIf
			Adblock = Null
		Next
	End Function

	'computes penalties for expired ad-contracts
	Function ComputeContractPenalties()
		Local LastContract:TContract = Null
		For Local Player:TPlayer = EachIn TPlayer.List
			For Local Contract:TContract = EachIn Player.ProgrammeCollection.contractlist
				If contract <> Null
					If (contract.daystofinish-(Game.day - contract.daysigned)) <= 0
						If LastContract = Null Or LastContract.title <> contract.title
							Player.finances[TFinancials.GetDayArray(Game.day)].PayPenalty(contract.calculatedPenalty)
							'Print Player.name+" paid a penalty of "+contract.calculatedPenalty+" for contract:"+contract.title
						EndIf
						LastContract = contract
						Player.ProgrammeCollection.RemoveOriginalContract(contract)
						TAdBlock.RemoveAdblocks(contract, Game.day)
					EndIf
				EndIf
				contract= Null
				LastContract= Null
			Next
		Next
	End Function

	'computes audience depending on ComputeAudienceQuote and if the time is the same
	'as for the last block of a programme, it decreases the topicality of that programme
	Function ComputeAudience(recompute:Int = 0)
		Local Programme:TProgramme
		For Local Player:TPlayer = EachIn TPlayer.List
			Programme = Player.ProgrammePlan.GetActualProgramme()
			Player.audience = 0
			If Programme <> Null And Player.maxaudience <> 0
				Player.audience = Floor(Player.maxaudience * Programme.ComputeAudienceQuote(Player.audience/Player.maxaudience) / 1000)*1000
				'maybe someone sold a station
				If recompute
					Local quote:TAudienceQuotes = TAudienceQuotes.GetAudienceOfDate(Player.playerID, Game.day, Game.GetActualHour(), Game.GetActualMinute())
					If quote <> Null
						quote.audience = Player.audience
						quote.audiencepercentage = Int(Floor(Player.audience * 1000 / Player.maxaudience))
					End If
				Else
					TAudienceQuotes.Create(Programme.title + " (" + Localization.GetString("BLOCK") + " " + (1 + Game.GetActualHour() - Programme.sendtime) + "/" + Programme.blocks, Int(Player.audience), Int(Floor(Player.audience * 1000 / Player.maxaudience)), Game.GetActualHour(), Game.GetActualMinute(), Game.day, Player.playerID)
				End If
				If Programme.sendtime + Programme.blocks <= Game.getNextHour()
					Local OrigProgramme:TProgramme = Player.ProgrammeCollection.GetOriginalProgramme(Programme)
					If OrigProgramme <> Null And Not recompute
						OrigProgramme.topicality = OrigProgramme.topicality - Int(OrigProgramme.topicality / 2)
						OrigProgramme.ComputePrice()
						Player.ProgrammeCollection.TopicalityToProgrammeClones(OrigProgramme, Player.ProgrammePlan.ProgList)
					EndIf
				EndIf
			EndIf
			Programme = Null
		Next
	End Function

	'computes newsshow-audience
	Function ComputeNewsAudience()
		Local news:TNews
		For Local Player:TPlayer = EachIn TPlayer.List
			Player.audience = 0
			Local audience:Int = 0
			For Local i:Int = 1 To 3
				news = Player.ProgrammePlan.getActualNews(i)
				If news <> Null And Player.maxaudience <> 0
					audience :+ Floor(Player.maxaudience * News.ComputeAudienceQuote(Player.audience/Player.maxaudience) / 1000)*1000
					If Player.playerID = 1 Print "Newsaudience for News: "+i+" - "+audience
				EndIf
			Next
			Player.audience= Ceil(audience / 3)
			TAudienceQuotes.Create("News: "+ Game.GetActualHour()+":00", Int(Player.audience), Int(Floor(Player.audience*1000/Player.maxaudience)),Game.GetActualHour(),Game.GetActualMinute(),Game.day, Player.playerID)
			'If Player.playerID = 1 Print "Newsaudience: "+audience
			news = Null
		Next
	End Function

	'nothing up to now
	Method Update:Int()
		''
	End Method

	'returns formatted value of actual money
	'gibt einen formatierten Wert des aktuellen Geldvermoegens zurueck
	Method GetFormattedMoney:String()
		Return functions.convertValue(String(Self.finances[TFinancials.GetDayArray(Game.day)].money), 2, 0)
	End Method

	Method GetRawMoney:Int()
		Return Self.finances[TFinancials.GetDayArray(Game.day)].money
	End Method

	'returns formatted value of actual credit
	Method GetFormattedCredit:String()
		Return functions.convertValue(String(Self.finances[TFinancials.GetDayArray(Game.day)].credit), 2, 0)
	End Method

	'returns formatted value of actual audience
	'gibt einen formatierten Wert der aktuellen Zuschauer zurueck
	Method GetFormattedAudience:String()
		Return functions.convertValue(String(Self.audience), 2, 0)
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
	Field sold_misc:Int				= 0
	Field sold_total:Int = 0
	Field sold_stations:Int = 0
	Field revenue_interest:Int = 0
	Field revenue_before:Int 		=-1
	Field revenue_after:Int 		= 0
	Field money:Int					= 0
	Field credit:Int 				= 0
	Field playerID:Int 				= 0
	Field ListLink:TLink {saveload = "special" sl = "no"}
	Global List:TList = CreateList() {saveload = "special" sl = "no"}



	Function Load:TFinancials(pnode:xmlNode, finance:TFinancials)
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
	End Function

	'not used - implemented in player-class
	Function LoadAll()
		TFinancials.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local NODE:xmlNode = EachIn Children
			If NODE.Name = "FINANCE"
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
		finances.money		= startmoney
		finances.credit		= startcredit
		finances.playerID	= playerID
		finances.ListLink	= List.AddLast(finances)
		Return finances
	End Function

	'returns the the position in the array the actual game-day fits to
	Function GetDayArray:Int(day:Int)
		Return ((day-1) Mod 7)
	End Function

	'refreshs stats about misc sells
	Method SellMisc(_money:Int)
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
		If Player[Self.playerID].Figure.isAI() Then Player[Self.playerID].PlayerKI.CallOnMoneyChanged()
		If Self.playerID = Game.playerID Then Interface.BottomImgDirty = True
	End Method

	'refreshs stats about earned money from adspots
	Method SellAds(_money:Int)
		sold_ads	:+_money
		sold_total	:+_money
		money		:+_money
		ChangeMoney(_money)
	End Method

	'refreshs stats about earned money from selling a movie/programme
	Method SellMovie(_money:Int)
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

	'refreshs stats about paid money from buying a movie/programme
	Method PayMovie:Byte(_money:Int)
		If money >= _money
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
		paid_penalty:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method

	'refreshs stats about paid money from paying the rent of rooms
	Method PayRent(_money:Int)
		paid_rent:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method

	'refreshs stats about paid money from paying for the sent newsblocks
	Method PayNews:Byte(_money:Int)
		If money >= _money
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
		paid_newsagencies:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method

	'refreshs stats about paid money from paying the fees for the owned stations
	Method PayStationFees(_money:Int)
		paid_stationfees:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method

	'refreshs stats about paid money from paying misc things
	Method PayMisc(_money:Int)
		paid_misc:+_money
		paid_total:+_money
		ChangeMoney(- _money)
	End Method
End Type


'Include "gamefunctions_interface.bmx"

'create just one drop-zone-grid for all programme blocks instead the whole set for every block..
Function CreateDropZones:Int()
	Local i:Int = 0
	'Archive: Movie DND-zones in suitcase
	For i = 0 To Game.maxMoviesInSuitcaseAllowed-1
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.typ = "archiveprogrammeblock"
		DragAndDrop.used = 0
		DragAndDrop.rectx = 57+Assets.GetSprite("gfx_movie0").w*i
		DragAndDrop.recty = 297
		DragAndDrop.rectw = Assets.GetSprite("gfx_movie0").w
		DragAndDrop.recth = Assets.GetSprite("gfx_movie0").h
		If Not TArchiveProgrammeBlocks.DragAndDropList Then TArchiveProgrammeBlocks.DragAndDropList = CreateList()
		TArchiveProgrammeBlocks.DragAndDropList.AddLast(DragAndDrop)
		SortList TArchiveProgrammeBlocks.DragAndDropList
	Next

	'AdAgency: Contract DND-zones
	For i = 0 To Game.maxContractsAllowed-1
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.used = 0
		DragAndDrop.rectx = 550 + gfx_contract.GetSprite("Contract0").w * i
		DragAndDrop.recty = 87
		DragAndDrop.rectw = gfx_contract.GetSprite("Contract0").w - 1
		DragAndDrop.recth = gfx_contract.GetSprite("Contract0").h
		If Not TContractBlocks.DragAndDropList Then TContractBlocks.DragAndDropList = CreateList()
		TContractBlocks.DragAndDropList.AddLast(DragAndDrop)
		SortList TContractBlocks.DragAndDropList
	Next

	'left newsagency slots
	For i = 0 To 3
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.rectx = 35
		DragAndDrop.recty = 22 + i * ImageHeight(gfx_news_sheet) / 5 '[0])
		DragAndDrop.rectw = ImageWidth(gfx_news_sheet) '[0])
		DragAndDrop.recth = ImageHeight(gfx_news_sheet) / 5'[0])
		If Not TNewsBlock.DragAndDropList Then TNewsBlock.DragAndDropList = CreateList()
		TNewsBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TNewsBlock.DragAndDropList
	Next

	For i = 0 To 2
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i+4
		DragAndDrop.rectx = 445
		DragAndDrop.recty = 106 + i * ImageHeight(gfx_news_sheet) / 5 '[0])
		DragAndDrop.rectw = ImageWidth(gfx_news_sheet) '[0])
		DragAndDrop.recth = ImageHeight(gfx_news_sheet) / 5'[0])
		If Not TNewsBlock.DragAndDropList Then TNewsBlock.DragAndDropList = CreateList()
		TNewsBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TNewsBlock.DragAndDropList
	Next

	'adblock
	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.typ = "adblock"
		DragAndDrop.rectx = 394 + Assets.GetSprite("pp_programmeblock1").w
		DragAndDrop.recty = 17 + i * Assets.GetSprite("pp_adblock1").h
		DragAndDrop.rectw = Assets.GetSprite("pp_adblock1").w
		DragAndDrop.recth = Assets.GetSprite("pp_adblock1").h
		If Not TAdBlock.DragAndDropList Then TAdBlock.DragAndDropList = CreateList()
		TAdBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TAdBlock.DragAndDropList
	Next
	'adblock
	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i+11
		DragAndDrop.typ = "adblock"
		DragAndDrop.rectx = 67 + Assets.GetSprite("pp_programmeblock1").w
		DragAndDrop.recty = 17 + i * Assets.GetSprite("pp_adblock1").h
		DragAndDrop.rectw = Assets.GetSprite("pp_adblock1").w
		DragAndDrop.recth = Assets.GetSprite("pp_adblock1").h
		If Not TAdBlock.DragAndDropList Then TAdBlock.DragAndDropList = CreateList()
		TAdBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TAdBlock.DragAndDropList
	Next
	'programmeblock
	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.typ = "programmeblock"
		DragAndDrop.rectx = 394
		DragAndDrop.recty = 17 + i * Assets.GetSprite("pp_programmeblock1").h
		DragAndDrop.rectw = Assets.GetSprite("pp_programmeblock1").w
		DragAndDrop.recth = Assets.GetSprite("pp_programmeblock1").h
		If Not TProgrammeBlock.DragAndDropList Then TProgrammeBlock.DragAndDropList = CreateList()
		TProgrammeBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TProgrammeBlock.DragAndDropList
	Next

	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i+11
		DragAndDrop.typ = "programmeblock"
		DragAndDrop.rectx = 67
		DragAndDrop.recty = 17 + i * Assets.GetSprite("pp_programmeblock1").h
		DragAndDrop.rectw = Assets.GetSprite("pp_programmeblock1").w
		DragAndDrop.recth = Assets.GetSprite("pp_programmeblock1").h
		If Not TProgrammeBlock.DragAndDropList Then TProgrammeBlock.DragAndDropList = CreateList()
		TProgrammeBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TProgrammeBlock.DragAndDropList
	Next

End Function

'an elevator, contains rules how to draw and functions when to move
Type TFloorRoute
	Field floornumber:Int
	Field call:Int
	Field direction:Int
	Field who:Int =0

	Method Save()
		LoadSaveFile.xmlBeginNode("ROUTE")
		LoadSaveFile.xmlWrite("FLOORNUMBER",Self.floornumber)
		LoadSaveFile.xmlWrite("CALL",		Self.call)
		LoadSaveFile.xmlWrite("DIRECTION",	Self.direction)
		LoadSaveFile.xmlWrite("WHO",		Self.who)
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Load:TFloorRoute(loadfile:TStream)
		Local Route:TFloorRoute = New TFloorRoute
		Route.floornumber = ReadInt(loadfile:TStream)
		Route.call 		= ReadInt(loadfile:TStream)
		Route.direction	= ReadInt(loadfile:TStream)
		Route.who		= ReadInt(loadfile:TStream)
		ReadString(loadfile, 5) 'read |FLR|
		Return Route
	End Function

	Function Create:TFloorRoute(floornumber:Int, call:Int=0, who:Int=0, direction:Int=-1)
		Local FloorRoute:TFloorRoute = New TFloorRoute
		FloorRoute.floornumber = floornumber
		FloorRoute.call = call
		floorRoute.who = who
		floorRoute.direction = direction
		Return FloorRoute
	End Function

	Method Compare:Int(otherObject:Object)
		Local s:TFloorRoute = TFloorRoute(otherObject)
		If Not s Then Return 1				  ' Objekt nicht gefunden, an das Ende der Liste setzen
		If Building.Elevator.upwards Then
			If Building.Elevator.onFloor-s.floornumber >= Building.Elevator.onFloor-floornumber Then Return 1
			If Building.Elevator.onFloor-s.floornumber <= Building.Elevator.onFloor-floornumber Then Return 0
			Else
				If Building.Elevator.onFloor-s.floornumber >= Building.Elevator.onFloor-floornumber Then Return 0
			If Building.Elevator.onFloor-s.floornumber <= Building.Elevator.onFloor-floornumber Then Return 1
		EndIf
	End Method

End Type

Type TElevator
	Field PlanTime:Int			= 4000
	Field waitAtFloorTimer:Int	= 0
	Field waitAtFloorTime:Int = 650 								'wait 650ms until moving to destination
	Field spriteDoor:TAnimSprites
	Field Image_inner:TGW_Sprites
	Field passenger:Int			=-1
	Field passengerFigure:TFigures = Null
	Field onFloor:Int 			= 0
	Field open:Int 				= 0
	Field toFloor:Int 			= 0
	Field speed:Float 			= 120  								'pixels per second ;D
	Field Pos:TPosition			= TPosition.Create(131+230,115) 	'difference to x/y of building,
	Field Parent:TBuilding
	Field FloorRouteList:TList	= CreateList()
	Field upwards:Int = 0
	Field EgoMode:Int = 1   								'EgoMode: 	If I have the elevator, the elevator will only stop
	'			at my destination and not if someone waits between
	'			both floors and could be taken with me.
	Global List:TList = CreateList()

	Method ElevatorCallIsDuplicate:Int(floornumber:Int, who:Int)
		For Local DupeRoute:TFloorRoute = EachIn FloorRouteList
			If DupeRoute.who = who And DupeRoute.floornumber = floornumber Then Return True
		Next
		Return False
	End Method

	Method Save()
		LoadSaveFile.xmlBeginNode("ELEVATOR")
		LoadSaveFile.xmlWrite("PLANTIME",			Self.PlanTime)
		LoadSaveFile.xmlWrite("WAITATFLOORTIMER",	Self.waitAtFloorTimer)
		LoadSaveFile.xmlWrite("WAITATFLOORTIME",	Self.waitAtFloorTime)
		LoadSaveFile.xmlWrite("PASSENGER",			Self.passenger)
		LoadSaveFile.xmlWrite("ONFLOOR",	 		Self.onFloor)
		LoadSaveFile.xmlWrite("OPEN",	 			Self.open)
		LoadSaveFile.xmlWrite("TOFLOOR",			Self.toFloor)
		LoadSaveFile.xmlWrite("SPEED",				Self.speed)
		LoadSaveFile.xmlWrite("X",					Self.Pos.x)
		LoadSaveFile.xmlWrite("Y",					Self.Pos.y)
		LoadSaveFile.xmlWrite("UPWARDS",			Self.upwards)
		LoadSaveFile.xmlWrite("EGOMODE",			Self.EgoMode)
		LoadSaveFile.xmlBeginNode("ELEVATORROUTE")
		For Local Route:TFloorRoute = EachIn FloorRouteList
			If Route.floornumber <= 13 And route.floornumber >=0 Then Route.Save()';Print "s:"+route.who
		Next
		LoadSaveFile.xmlCloseNode()
		LoadSaveFile.xmlCloseNode()
	End Method

	Method Load(loadfile:TStream)
		FloorRouteList.Clear()
		Local BeginPos:Int = Stream_SeekString("<ELEVATOR/>",loadfile)+1
		Local EndPos:Int = Stream_SeekString("</ELEVATOR>",loadfile)  -11
		loadfile.Seek(BeginPos)
		PlanTime		= ReadInt(loadfile)
		waitAtFloorTimer= ReadInt(loadfile)
		waitAtFloorTime = ReadInt(loadfile)
		passenger		= ReadInt(loadfile)
		onFloor		 	= ReadInt(loadfile)
		open		 	= ReadInt(loadfile)
		toFloor		 	= ReadInt(loadfile)
		speed		 	= ReadInt(loadfile)
		Pos.x		 	= ReadFloat(loadfile)
		Pos.y		 	= ReadFloat(loadfile)
		upwards			= ReadInt(loadfile)
		egomode			= ReadInt(loadfile)
		BeginPos = Stream_SeekString("<ELEVATORROUTE/>",loadfile)+1
		EndPos   = Stream_SeekString("</ELEVATORROUTE>",loadfile)  -17
		loadfile.Seek(BeginPos)
		Repeat
		Local Route:TFloorRoute = TFloorRoute.Load(loadfile)
		If route.who < 100 And route.floornumber <=13 And route.floornumber >= 0 Then FloorRouteList.AddLast(route)
		Until loadfile.Pos() >= EndPos
	End Method

	Function Create:TElevator(Parent:TBuilding)
		Local localObject:TElevator=New TElevator
		localObject.spriteDoor				= TAnimSprites.Create(Assets.GetSprite("gfx_building_Fahrstuhl_oeffnend").GetImage(), 0, 0, 0, 8, 150)
		localObject.spriteDoor.insertAnimation("default", TAnimation.Create([ [0,70] ], 0, 0) )
		localObject.spriteDoor.insertAnimation("closed", TAnimation.Create([ [0,70] ], 0, 0) )
		localObject.spriteDoor.insertAnimation("open", TAnimation.Create([ [7,70] ], 0, 0) )
		localObject.spriteDoor.insertAnimation("opendoor", TAnimation.Create([ [0,70],[1,70],[2,70],[3,70],[4,70],[5,70],[6,70],[7,70] ], 0, 1) )
		localObject.spriteDoor.insertAnimation("closedoor", TAnimation.Create([ [7,70],[6,70],[5,70],[4,70],[3,70],[2,70],[1,70],[0,70] ], 0, 1) )

'		localObject.animation_opening				= TAnimSprites.Create(Assets.GetSprite("gfx_building_Fahrstuhl_oeffnend").GetImage(), 0, 0, 0, 8, 70)
		localObject.Image_inner						= Assets.GetSprite("gfx_building_Fahrstuhl_Innen")  'gfx_building_elevator_inner
		localObject.Parent							= Parent
		localObject.Pos.SetY(Parent.GetFloorY(localObject.onFloor) - localobject.Image_inner.h)
		List.AddLast(localObject)
		SortList List
		Return localObject
	End Function

	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:Int, First:Int = False, fromNetwork:Int = False)
		If ElevatorCallIsDuplicate(floornumber, who) Then Print "duplicate elevator call by ID "+who;Return 0	'if duplicate - don't add
		Local FloorRoute:TFloorRoute = TFloorRoute.Create(floornumber,call,who)
		If First Or Not call
			FloorRouteList.AddFirst(floorroute)
			Self.toFloor = Self.GetFloorRoute()
		Else
			If Not FloorRouteList.IsEmpty() And (TFloorRoute(FloorRouteList.Last()).who = who Or TFloorRoute(FloorRouteList.Last()).floornumber = floornumber)
				FloorRouteList.RemoveLast()
			EndIf
			FloorRouteList.AddLast(floorroute)
		EndIf
		If Not fromNetwork Then If Game.networkgame Then If Network.IsConnected Then Print "send route to net";Network.SendElevatorRouteChange(floornumber, call, who, First)
	End Method

	Method GetFloorRoute:Int()
		If Not FloorRouteList.IsEmpty()
			Local tmpfloor:TFloorRoute = TFloorRoute(FloorRouteList.First())
			If onFloor = tmpfloor.floornumber Then FloorRouteList.RemoveFirst
			Return tmpfloor.floornumber
		EndIf
		Return -1
	End Method

	Method moveTo(_tofloor:Int)
		toFloor = Clamp(_tofloor,0,13)
	End Method

	Method CloseDoor()
		Self.spriteDoor.setCurrentAnimation("closedoor", True)
		open = 3
		If Game.networkgame Then If Network.IsConnected Then If Game.playerID = 1 Then Network.SendElevatorSynchronize()
	End Method

	Method OpenDoor()
		Self.spriteDoor.setCurrentAnimation("opendoor", True)
		open = 2 'wird geoeffnet
		If passenger >= 0
			Local Figure:TFigures = TFigures.GetFigure(passenger)
			If Figure <> Null
				Figure.onFloor	= onFloor
				Figure.pos.setY( Building.GetFloorY(onFloor) - Figure.frameheight )
			EndIf
		End If
		'If Game.networkgame Then If Network.IsConnected Then If Game.playerID = 1 Then Network.SendElevatorSynchronize()
	End Method

	Method DrawFloorDoors()
		Local locy:Int = 0

		'elevatorBG without image -> black
		SetColor 0,0,0
		DrawRect(Parent.x + 127 + 233, Max(parent.y, 10) , 44, 373)
		SetColor 255, 255, 255

		'elevatorbg
		Image_inner.Draw(Parent.x + Pos.x, Parent.y + Pos.y + 4)
		'figures in elevator
		If passengerFigure = Null
			For Local Figure:TFigures = EachIn TFigures.List
				If Figure.IsInElevator() Then passengerFigure = Figure;passengerFigure.Draw(); passengerFigure.alreadydrawn = 1
			Next
		Else
			passengerFigure.Draw(); passengerFigure.alreadydrawn = 1
		EndIf
		'
		For Local i:Int = 0 To 13
			locy = Parent.y + Building.GetFloorY(i) - Self.spriteDoor.image.height
'			locy = Parent.y + Building.GetFloorY(i) - image_closed.h
			If locy < 410 And locy > - 50
				Self.spriteDoor.Draw(Parent.x + Pos.x, locy, "closed")
			EndIf
		Next
	End Method


	Method Update(deltaTime:Float=1.0)
		'the -1 is used for displace the object one pixel higher, so it has to reach the first pixel of the floor
		'until the function returns the new one, instead of positioning it directly on the floorground
		If Abs(Building.GetFloorY(Building.GetFloor(Parent.y + Pos.y + Image_inner.h - 1)) - (Pos.y + Image_inner.h)) <= 1
			onFloor = Building.GetFloor(Parent.y + Pos.y + Image_inner.h - 1)
		EndIf

		If spriteDoor.getCurrentAnimationName() = "opendoor"
			open = 2 'opening
			If spriteDoor.getCurrentAnimation().isFinished()
				If open = 2 And passenger <> - 1
					TFigures.GetFigure(passenger).inElevator	= False
					passengerFigure 							= Null
				EndIf
				spriteDoor.setCurrentAnimation("open")
				open = 1 'open
			EndIf
		EndIf
		If spriteDoor.getCurrentAnimationName() = "closedoor"
			open = 3 'closing
			If spriteDoor.getCurrentAnimation().isFinished()
				spriteDoor.setCurrentAnimation("closed")
				open = 0 'closed
			EndIf

		EndIf

		'check wether elevator has to move to somewhere but doors aren't closed - if so, start closing-animation
		If (onFloor <> toFloor And open <> 0) And open <> 3 And waitAtFloorTimer <= MilliSecs() Then CloseDoor
		If (onFloor = toFloor) And open = 0 Then OpenDoor;waitAtFloorTimer = MilliSecs() + waitAtFloorTime
		If open And waitAtFloortimer + 5000 <= MilliSecs() And waitAtFloorTimer <> 0
			If passenger <> - 1
				TFigures.GetFigure(passenger).inElevator = False
				passengerFigure = Null
				Print "Schmeisse Figur " + TFigures.GetFigure(passenger).Name + " aus dem Fahrstuhl (" + (MilliSecs() - waitatfloortimer) + ")"
				passenger = -1
			EndIf
		End If
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.IsInElevator()
				If open=0 And waitAtFloorTimer <= MilliSecs() 'elevator is closed, closing-animation stopped
					Figure.pos.setY ( Building.Elevator.Pos.y + Image_inner.h - Figure.frameheight )
				EndIf
				Exit 'only one figure in elevator possible
			EndIf
		Next

		spriteDoor.Update(deltaTime)

		If (onFloor <> toFloor And open <> 0) Or(onFloor = toFloor)
			Local tmpFloor:Int 		= GetFloorRoute()
			For Local i:Int = 0 To 13
				If 13-i = onFloor
					'					spriteDoor.Update()
					For Local Figure:TFigures = EachIn TFigures.List
						If Figure.IsInElevator() And Figure.toFloor = toFloor
							Figure.onFloor = Building.Elevator.onFloor
							Figure.pos.setY( Building.GetFloorY(Figure.onFloor) - Figure.frameheight )
							Exit 'only one figure in elevator possible
						EndIf
					Next
					If waitAtFloorTimer <= MilliSecs() And toFloor = onFloor
						If tmpfloor = onFloor	Then waitAtFloorTimer = MilliSecs() + waitAtFloorTime
						If tmpFloor = -1		Then toFloor = toFloor Else toFloor = tmpfloor
					EndIf
				EndIf
			Next
		EndIf

		If onFloor <> toFloor
			If open = 0 And waitAtFloorTimer <= MilliSecs() 'elevator is closed, closing-animation stopped
				'				If onFloor > toFloor Then Pos.y:+Min(((Building.GetFloorY(tofloor) - Image_inner.h) - Pos.y), deltaTime * speed) ;upwards = 0
				'				If onFloor < toFloor Then Pos.y:-Min(((Building.GetFloorY(tofloor) - Image_inner.h) - Pos.y), deltaTime * speed) ;upwards = 1
				upwards = onfloor < toFloor
				If Not upwards
					Pos.y	= Min(Pos.y + deltaTime * speed, Building.GetFloorY(toFloor) - image_inner.h)
				Else
					Pos.y	= Max(Pos.y - deltaTime * speed, Building.GetFloorY(toFloor) - image_inner.h)
				EndIf
				If Pos.y + Image_inner.h < Building.GetFloorY(13) Then Pos.y = Building.GetFloorY(0) - Image_inner.h
				If Pos.y + Image_inner.h > Building.GetFloorY(0) Then Pos.y = Building.GetFloorY(0) - Image_inner.h
			EndIf
		EndIf
		TRooms.UpdateDoorToolTips(deltaTime)
	End Method

	'needs to be restructured (some test-lines within)
	Method Draw()
		Local locy:Int = 0
		SetBlend MASKBLEND
		TRooms.DrawDoors()

		'check wether elevator has to move to somewhere but doors aren't closed, if so, start closing-animation
		If (onFloor <> toFloor And open <> 0)Or(onFloor = toFloor)
			Local locy:Int = Parent.y + Parent.GetFloorY(onFloor) - image_inner.h + 5
			Image_inner.DrawClipped(Parent.x + 131 + 230, locy - 3, Parent.x + 131 + 230, locy, 40, 50,0,0)
		EndIf
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.IsOnFloor() Then Figure.Draw() ;Figure.alreadydrawn = 0 'not alreadydrawn for openinganimation
		Next

		If (onFloor <> toFloor And open <> 0) Or (onFloor = toFloor)
			spriteDoor.Draw(Parent.x + 131 + 230, Parent.y + Parent.GetFloorY(onFloor) - 50)
		EndIf

		For Local i:Int = 0 To 13
			locy = Parent.y + Building.GetFloorY(i) - Self.spriteDoor.image.height - 8
			If locy < 410 And locy > -50
				SetColor 200,0,0
				DrawRect(Parent.x+Pos.x-4 + 10 + (onFloor)*2, locy + 3, 2,2)
				SetColor 255,255,255
			EndIf
		Next

		'elevator sign - indicator
		For Local FloorRoute:TFloorRoute = EachIn FloorRouteList
			locy = Parent.y + Building.GetFloorY(floorroute.floornumber) - Image_inner.h + 23
			'elevator is called to this floor					'elevator will stop there (destination)
			If	 floorroute.call Then SetColor 200,220,20 	Else SetColor 100,220,20
			DrawRect(Parent.x + Pos.x + 44, locy, 3,3)
			SetColor 255,255,255
		Next
		SetBlend ALPHABLEND

		Local routepos:Int = 0
		For Local FloorRoute:TFloorRoute = EachIn FloorRouteList
			If floorroute.call = 0
				DrawText(FloorRoute.floornumber + " 'senden' " + TFigures.GetFigure(FloorRoute.who).Name, 650, 50 + routepos * 15)
			Else
				DrawText(FloorRoute.floornumber + " 'holen' " + TFigures.GetFigure(FloorRoute.who).Name, 650, 50 + routepos * 15)
			EndIf
			routepos:+1
		Next


		For Local Figure:TFigures = EachIn TFigures.List
			If (Not Figure.IsInElevator()) And Not Figure.alreadydrawn Then Figure.Draw()
		Next
	End Method

End Type

Include "gamefunctions_figures.bmx"

'Summary: Type of building, area around it and doors,...
Type TBuilding
	Field x:Int						= 20
	Field borderright:Int 			= 127 + 40 + 429
	Field borderleft:Int			= 127 + 40
	Field y:Int = 0
	Field skycolor:Float = 0
	Field ufo_normal:TAnimSprites = TAnimSprites.Create(Assets.GetSprite("gfx_building_ufo").GetImage(), 0, 100, 1, 9, 100)
	Field ufo_beaming:TAnimSprites = TAnimSprites.Create(Assets.GetSprite("gfx_building_ufo2").GetImage(), 0, 100, 0, 9, 100)
	Field Elevator:TElevator

	Field Moon_curKubSplineX:appKubSpline =New appKubSpline
	Field Moon_curKubSplineY:appKubSpline =New appKubSpline
	Field Moon_curvStep:Float 		=.05
	Field Moon_tPos:Float 			= 3
	Field Moon_lastTChange:Int 		= MilliSecs()
	Field Moon_setNewCurve:Int 		= False
	Field Moon_newDataT:Int[], Moon_newDataX:Int[], Moon_newDataY:Int[]
	Field Moon_constSpeed:Int 		= False
	Field Moon_pixelPerSecond:Float 	= 10

	Field ufo_curKubSplineX:appKubSpline =New appKubSpline
	Field ufo_curKubSplineY:appKubSpline =New appKubSpline
	Field ufo_curvStep:Float 			=.05
	Field ufo_tPos:Float 				= 1
	Field ufo_lastTChange:Int 		= MilliSecs()
	Field ufo_setNewCurve:Int 		= False
	Field ufo_newDataT:Int[], ufo_newDataX:Int[], ufo_newDataY:Int[]
	Field ufo_constSpeed:Int 			= False
	Field ufo_pixelPerSecond:Float	= 25
	Field Clouds:TSprites[3]
	Field CloudCount:Int = 3
	Field TimeColor:Double
	Field DezimalTime:Float
	Field ActHour:Int
	Field ItemsDrawnToBackground:Byte = 0
	'  Field BGbuildings:TImage
	'  Field BGbuildingsDirty:Byte = 1
	Global StarsX:Int[60]
	Global StarsY:Int[60]
	Global StarsC:Int[60]
	Global CloudPack:TSpritesPack = TSpritesPack.Create()
	Global List:TList = CreateList()

	Function Create:TBuilding()
		Local Building:TBuilding = New TBuilding
		Building.y = 0 - gfx_building_skyscraper.Height + 5 * 73 + 20	' 20 = interfacetop, 373 = raumhoehe

		Building.Elevator = TElevator.Create(Building)
		Building.Moon_curKubSplineX.GetDataInt([1, 2, 3, 4, 5], [-50, -50, 400, 850, 850])
		Building.Moon_curKubSplineY.GetDataInt([1, 2, 3, 4, 5], [650, 200, 20 , 200, 650])
		Building.ufo_curKubSplineX.GetDataInt([1, 2, 3, 4, 5], [-150, 200+Rand(400), 200+Rand(200), 65, -50])
		Building.ufo_curKubSplineY.GetDataInt([1, 2, 3, 4, 5], [-50+Rand(200), 100+Rand(200) , 200+Rand(300), 330,150])
		For Local i:Int = 0 To Building.CloudCount-1
			Building.Clouds[i] = TSprites.Create(CloudPack, Assets.GetSprite("building_clouds").parent.image, "", "clouds", - 400 * i + (i + 1) * Rand(200), - 30 + Rand(30), 2 + Rand(0, 5), 512 + Rand(50), Rand(0, 1))
		Next

		For Local j:Int = 0 To 29
			StarsX[j] = 10+Rand(150)
			StarsY[j] = 20+Rand(273)
			StarsC[j] = 50+Rand(150)
		Next
		For Local j:Int = 30 To 59
			StarsX[j] = 650+Rand(150)
			StarsY[j] = 20+Rand(273)
			StarsC[j] = 50+Rand(150)
		Next
		If Not List Then List = CreateList()
		List.AddLast(Building)
		SortList List
		Return Building
	End Function

	Method Update(deltaTime:Float=1.0)
		y = Clamp(y, - 637, 88)
		UpdateBackground(deltaTime)
	End Method

	Method DrawItemsToBackground:Int()
		Local locy13:Int	= GetFloorY(13)
		Local locy3:Int		= GetFloorY(3)
		Local locy0:Int		= GetFloorY(0)
		Local locy12:Int	= GetFloorY(12)
		If Not ItemsDrawnToBackground
			Local Pix:TPixmap = LockImage(Assets.GetSprite("gfx_building").parent.image)
			'	  Local Pix:TPixmap = gfx_building_skyscraper.RestorePixmap()

			DrawOnPixmap(Assets.GetSprite("gfx_building_Pflanze4").GetImage(), 0, Pix, 127 + borderleft + 40, locy12 - Assets.GetSprite("gfx_building_Pflanze4").h)
			DrawOnPixmap(Assets.GetSprite("gfx_building_Pflanze6").GetImage(), 0, Pix, 127 + borderright - 95, locy12 - Assets.GetSprite("gfx_building_Pflanze6").h)
			DrawOnPixmap(Assets.GetSprite("gfx_building_Pflanze2").GetImage(), 0, Pix, 127 + borderleft + 105, locy13 - Assets.GetSprite("gfx_building_Pflanze2").h)
			DrawOnPixmap(Assets.GetSprite("gfx_building_Pflanze3").GetImage(), 0, Pix, 127 + borderright - 105, locy13 - Assets.GetSprite("gfx_building_Pflanze3").h)
			DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, 145, locy0 - Assets.GetSprite("gfx_building_Wandlampe").h)
			DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, 506 - 145 - Assets.GetSprite("gfx_building_Wandlampe").w, locy0 - Assets.GetSprite("gfx_building_Wandlampe").h)
			DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, 145, locy13 - Assets.GetSprite("gfx_building_Wandlampe").h)
			DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, 506 - 145 - Assets.GetSprite("gfx_building_Wandlampe").w, locy13 - Assets.GetSprite("gfx_building_Wandlampe").h)
			DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, 145, locy3 - Assets.GetSprite("gfx_building_Wandlampe").h)
			DrawOnPixmap(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), 0, Pix, 506 - 145 - Assets.GetSprite("gfx_building_Wandlampe").w, locy3 - Assets.GetSprite("gfx_building_Wandlampe").h)
			UnlockImage(Assets.GetSprite("gfx_building").parent.image)
			Pix = Null
			ItemsDrawnToBackground = True
		EndIf
	End Method

	Method Draw(tweenValue:Float=1.0)
		'		SetViewport(10,10,780,383)
		DrawBackground(tweenValue)
		If Building.GetFloor(Player[Game.playerID].Figure.pos.y) <= 4
			SetColor Int(205 * timecolor) + 150, Int(205 * timecolor) + 150, Int(205 * timecolor) + 150
			Assets.GetSprite("gfx_building_Eingang").Draw(x, y + 1024 - Assets.GetSprite("gfx_building_Eingang").h - 3)
			Assets.GetSprite("gfx_building_Zaun").Draw(x + 127 + 507, y + 1024 - Assets.GetSprite("gfx_building_Zaun").h - 3)
		Else If Building.GetFloor(Player[Game.playerID].Figure.pos.y) >= 8
			SetColor 255, 255, 255
			Assets.GetSprite("gfx_building_Dach").Draw(x + 127, y - Assets.GetSprite("gfx_building_Dach").h)
		EndIf
		SetBlend MASKBLEND
		elevator.DrawFloorDoors()
		gfx_building_skyscraper.renderInViewPort(x + 127, y, 10, 10, 780, 383)
		SetBlend ALPHABLEND
		Elevator.Draw()

		SetBlend MASKBLEND
		Assets.GetSprite("gfx_building_Pflanze1").Draw(x + borderright - 130, y + GetFloorY(9), - 1, 1)
		Assets.GetSprite("gfx_building_Pflanze1").Draw(x + borderleft + 150, y + GetFloorY(13), - 1, 1)
		Assets.GetSprite("gfx_building_Pflanze2").Draw(x + borderright - 110, y + GetFloorY(9), - 1, 1)
		Assets.GetSprite("gfx_building_Pflanze2").Draw(x + borderleft + 150, y + GetFloorY(6), - 1, 1)
		Assets.GetSprite("gfx_building_Pflanze6").Draw(x + borderright - 85, y + GetFloorY(8), - 1, 1)
		Assets.GetSprite("gfx_building_Pflanze3a").Draw(x + borderleft + 60, y + GetFloorY(1), - 1, 1)
		Assets.GetSprite("gfx_building_Pflanze3a").Draw(x + borderleft + 60, y + GetFloorY(12), - 1, 1)
		Assets.GetSprite("gfx_building_Pflanze3b").Draw(x + borderleft + 150, y + GetFloorY(12), - 1, 1)
		Assets.GetSprite("gfx_building_Pflanze1").Draw(x + borderright - 70, y + GetFloorY(3), - 1, 1)
		Assets.GetSprite("gfx_building_Pflanze2").Draw(x + borderright - 75, y + GetFloorY(12), - 1, 1)
		SetBlend ALPHABLEND
		TRooms.DrawDoorToolTips()

		SetViewport(0, 0, App.width, App.height)
	End Method

	Method UpdateBackground(deltaTime:Float=1.0)
		ActHour = Game.GetActualHour()
		DezimalTime = Float(Game.GetActualHour()) + Float(Game.GetActualMinute())*10/6/100
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
		'compute and draw moon
		If ActHour > 18 Or ActHour < 7 Then Moon_pixelPerSecond = Float(Floor(Game.speed * 10))
		If ActHour > 18 And ActHour < 20
			Moon_tPos = 2;
			Moon_lastTChange = MilliSecs()
		EndIf
		If ActHour = 7 Or ActHour = 18
			Moon_tPos = 2;
			Moon_pixelPerSecond = 1
			Moon_lastTChange = MilliSecs()
		EndIf
		Local nextTPos:Float
		Local curDist:Float =0
		For nextTPos = Moon_tPos To Moon_tPos + Moon_curKubSplineX.dataX[Moon_curKubSplineX.dataCount - 1] -.001 Step.001
			curDist:+Sqr((Moon_curKubSplineX.Value(nextTPos +.001) - Moon_curKubSplineX.Value(nextTPos)) ^ 2 + (Moon_curKubSplineY.Value(nextTPos +.001) - Moon_curKubSplineY.Value(nextTPos)) ^ 2)
			If curDist >= Moon_pixelPerSecond Then Exit
		Next
		Moon_tPos:+(nextTPos - Moon_tPos) * (MilliSecs() - Moon_lastTChange) / 1000
		Moon_lastTChange = MilliSecs()
		'end compute and draw moon
		If DezimalTime > 18 Or DezimalTime < 7
			If Game.day Mod 2 = 0
				'compute and draw Ufo
				If ActHour < 6 Then ufo_pixelPerSecond = Float(Floor(Game.speed * 30))
				If ActHour = 0
					ufo_tPos = 1
					ufo_lastTChange = MilliSecs()
				EndIf
				If ActHour = 6 'or ActHour = 18
					ufo_tPos = 6
					ufo_pixelPerSecond = 1
					ufo_lastTChange = MilliSecs()
				EndIf
				If (Floor(ufo_curKubSplineX.ValueInt(ufo_tPos)) = 65 And Floor(ufo_curKubSplineY.ValueInt(ufo_tPos)) = 330) Or (ufo_beaming.getCurrentAnimation().getCurrentFramePos() > 1 And ufo_beaming.getCurrentAnimation().getCurrentFramePos() <= ufo_beaming.getCurrentAnimation().getFrameCount())
					ufo_beaming.pos.x = 65
					ufo_beaming.pos.y = -15 + 105 + 0.25 * (y + gfx_building_skyscraper.Height - Assets.GetSprite("gfx_building_BG_Ebene3L").h)
					ufo_beaming.Update()
					If ufo_beaming.getCurrentAnimation().getCurrentFramePos() <> 6
						ufo_pixelPerSecond = 0
					Else
						ufo_pixelPerSecond = 10
						ufo_lastTChange:+50
					EndIf
				Else
					curDist = 0
					For nextTPos = ufo_tPos To ufo_tPos + ufo_curKubSplineX.dataX[ufo_curKubSplineX.dataCount - 1] -.001 Step.001
						curDist:+Sqr((ufo_curKubSplineX.Value(nextTPos +.001) - ufo_curKubSplineX.Value(nextTPos)) ^ 2 + (ufo_curKubSplineY.Value(nextTPos +.001) - ufo_curKubSplineY.Value(nextTPos)) ^ 2)
						If curDist >= ufo_pixelPerSecond Then Exit
					Next
				EndIf
				If ufo_pixelPerSecond > 0 Then ufo_tPos:+(nextTPos - ufo_tPos) * (MilliSecs() - ufo_lastTChange) / 1000
				ufo_lastTChange = MilliSecs()
				'end compute and draw Ufo
			EndIf
		EndIf
		'backgroundlayer: neighbour-buildings
		Local oldclouddx:Float = 0.0
		For Local i:Int = 0 To Building.CloudCount-1
			oldclouddx = Clouds[i].dx
			Clouds[i].dx:*Float(Game.speed)
			Clouds[i].Update(- 10000, - 80 + y + Clouds[i].y)
			Clouds[i].dx = oldclouddx
		Next
	End Method

	Method DrawStars(rndvalue:Int=0)
		Local minute:Float = Game.GetActualMinute()
		For Local i:Int = 0 To 59
			If i Mod 6 = 0 And minute Mod 2 = 0 Then StarsC[i] = Rand(StarsC[i] )
			SetColor StarsC[i] , StarsC[i] , StarsC[i]
			Plot(StarsX[i] , StarsY[i] )
		Next
	End Method

	'Summary: Draws background of the mainscreen (stars, buildings, moon...)
	Method DrawBackground(tweenValue:Float=1.0)
		Local BuildingHeight:Int = gfx_building_skyscraper.Height + 56
		SetBlend MASKBLEND
		DezimalTime = Float(Game.GetActualHour()) + Float(Game.GetActualMinute())*10/6/100
		If DezimalTime > 18 Or DezimalTime < 7
			If DezimalTime > 18 And DezimalTime < 19 Then SetAlpha (19 - Dezimaltime)
			If DezimalTime > 6 And DezimalTime < 8 Then SetAlpha (4 - Dezimaltime / 2)
			DrawStars()
			SetColor 255, 255, 255
			DezimalTime:+3
			If DezimalTime > 24 Then DezimalTime:-24
			SetBlend ALPHABLEND
			Assets.GetSprite("gfx_BG_moon").DrawInViewPort(Moon_curKubSplineX.ValueInt(Moon_tPos), y + Moon_curKubSplineY.ValueInt(Moon_tPos), 0, Game.day Mod 12)
			SetColor Int(205 * timecolor) + 50, Int(205 * timecolor) + 50, Int(205 * timecolor) + 50
			For Local i:Int = 0 To Building.CloudCount - 1
				Clouds[i].Draw(- 10000, - 80 + y + Clouds[i].y)
			Next
		EndIf

		If DezimalTime > 18 Or DezimalTime < 7
			SetBlend MASKBLEND
			SetAlpha 1.0

			If Game.day Mod 2 = 0 Then
				'compute and draw Ufo
				If (Floor(ufo_curKubSplineX.ValueInt(ufo_tPos)) = 65 And Floor(ufo_curKubSplineY.ValueInt(ufo_tPos)) = 330) Or (ufo_beaming.getCurrentAnimation().getCurrentFramePos() > 1 And ufo_beaming.getCurrentAnimation().getCurrentFramePos() <= ufo_beaming.getCurrentAnimation().getFrameCount())
					ufo_beaming.Draw()
				Else
					Assets.GetSprite("gfx_building_ufo").DrawInViewPort(ufo_curKubSplineX.ValueInt(ufo_tPos), - 330 - 15 + 105 + 0.25 * (y + gfx_building_skyscraper.Height - Assets.GetSprite("gfx_building_BG_Ebene3L").h) + ufo_curKubSplineY.ValueInt(ufo_tPos), 0, ufo_normal.GetCurrentFrame())
				EndIf
			EndIf
		EndIf

		SetBlend MASKBLEND

		SetColor Int(225 * timecolor) + 30, Int(225 * timecolor) + 30, Int(225 * timecolor) + 30
		Assets.GetSprite("gfx_building_BG_Ebene3L").Draw(x, 105 + 0.25 * (y + 5 + BuildingHeight - Assets.GetSprite("gfx_building_BG_Ebene3L").h), - 1, 0)
		Assets.GetSprite("gfx_building_BG_Ebene3R").Draw(x + 634, 105 + 0.25 * (y + 5 + BuildingHeight - Assets.GetSprite("gfx_building_BG_Ebene3R").h), - 1, 0)
		SetColor Int(215 * timecolor) + 40, Int(215 * timecolor) + 40, Int(215 * timecolor) + 40
		Assets.GetSprite("gfx_building_BG_Ebene2L").Draw(x, 120 + 0.35 * (y + BuildingHeight - Assets.GetSprite("gfx_building_BG_Ebene2L").h), - 1, 0)
		Assets.GetSprite("gfx_building_BG_Ebene2R").Draw(x + 636, 120 + 0.35 * (y + 60 + BuildingHeight - Assets.GetSprite("gfx_building_BG_Ebene2R").h), - 1, 0)
		SetColor Int(205 * timecolor) + 50, Int(205 * timecolor) + 50, Int(205 * timecolor) + 50
		Assets.GetSprite("gfx_building_BG_Ebene1L").Draw(x, 45 + 0.80 * (y + BuildingHeight - Assets.GetSprite("gfx_building_BG_Ebene1L").h), - 1, 0)
		Assets.GetSprite("gfx_building_BG_Ebene1R").Draw(x + 634, 45 + 0.80 * (y + BuildingHeight - Assets.GetSprite("gfx_building_BG_Ebene1R").h), - 1, 0)

		'	SetAlpha 1.0
		SetColor 255, 255, 255
		SetBlend ALPHABLEND
	End Method

	Method CenterToFloor:Int(floornumber:Int)
		y = ((13 - (floornumber)) * 73) - 115
	End Method

	'Summary: returns y which has to be added to building.y, so its the difference
	Method GetFloorY:Int(floornumber:Int)
		Return (66 + 1 + (13 - floornumber) * 73)		  ' +10 = interface
	End Method

	Method GetFloor:Int(_y:Int)
		Return Clamp(13 - Ceil((_y - y) / 73),0,13)
		'		Local locfloor:Int = 13 - Ceil((_y - y) / 73)
		'		If locfloor < 0 Then locfloor = 0
		'		If locfloor > 13 Then locfloor = 13
		'		Return locfloor
	End Method
End Type


'likely a kind of agency providing news... 'at the moment only a base object
Type TNewsAgency
	Field LastEventTime:Float =0
	Field NextEventTime:Float = 0
	Field LastNewsList:TList = CreateList() 'holding news from the past hours/day for chains


	Method GetNextFromChain:TNews()
		Local news:TNews
		For Local parentnews:TNews = EachIn LastNewsList
			If parentnews.happenedday < Game.day
				If parentnews.parentNews <> Null
					If parentnews.episode < parentnews.parentNews.episodecount
						news = TNews.GetNextInNewsChain(parentnews)
					EndIf
				End If
				If parentnews.episodecount > 0 And parentnews.parentNews = Null
					news = TNews.GetNextInNewsChain(parentnews, True) 'true = is the parent
				EndIf
				LastNewsList.Remove(parentnews)
				If news <> Null Then PrintDebug("TNewsAgency.GetNextFromChain()", "NEWS: returning news:" + news.episode + " " + news.title, DEBUG_NEWS)
				'Print "NEWS: returning previous news"
				Return news
			End If
		Next
		'Print "NEWS: no previous news found"
	End Method

	Method AddNews:Int(news:TNews)
		For Local i:Int = 1 To 4
			If Player[i].newsabonnements[news.genre] > 0
				Player[i].ProgrammeCollection.AddNews(news)
				TNewsBlock.Create("",0,-100, i, 60*(3-Player[i].newsabonnements[news.genre]), news)
				If Game.networkgame Then If Network.IsConnected Then Network.SendNews(i, news)
			EndIf
		Next
	End Method

	Method AnnounceNewNews()
		Local news:TNews = Null
		If Rand(1,10)>3 Then news = GetNextFromChain()  '70% alte Nachrichten holen, 30% neue Kette/Singlenews
		If news = Null Then news = TNews.GetRandomNews() 'TNews.GetRandomChainParent()
		If news <> Null Then
			news.happenedday = Game.day
			news.happenedhour = Game.GetActualHour()
			news.happenedminute = Game.GetActualMinute()
			Local NoOneSubscribed:Byte= True
			For Local i:Int = 1 To 4
				If Player[i].newsabonnements[news.genre] > 0
					NoOneSubscribed = False
				EndIf
			Next
			If Not NoOneSubscribed Then
				AddNews(news)
				LastNewsList.AddLast(News)
				'Print "NEWS: added "+news.title+" episodes:"+news.episodecount
			Else
				News.used = 0
			EndIf
		EndIf
		LastEventTime = Game.timeSinceBegin
		If Rand(0,10) = 1 Then
			NextEventTime = Game.timeSinceBegin + Rand(5,50) 'between 5 and 50 minutes until next news
		Else
			NextEventTime = Game.timeSinceBegin + Rand(90,200) 'between 60 and 250 minutes until next news
		EndIf
	End Method
End Type

'Include "stationmap.bmx"			'stationmap-handling, -creation ...

'#Region: Globals, Player-Creation
Global StationMap:TStationMap	= TStationMap.Create()
Global Interface:TInterface		= TInterface.Create()
Global Game:TGame	  			= TGame.Create()
Global Building:TBuilding		= TBuilding.Create()
PrintDebug ("  Init_CreateAllRooms()", "creation of all rooms with assigned playernames", DEBUG_START)
Init_CreateAllRooms() 				'creates all Rooms - with the names assigned at this moment

'#Region  Creating PlayerColors
TPlayerColor.Create(247, 50, 50, 0) ; TPlayerColor.Create(245, 220, 0, 0)
TPlayerColor.Create(40, 210, 0, 0) ; TPlayerColor.Create(0, 110, 245, 0)
TPlayerColor.Create(158, 62, 32, 0) ; TPlayerColor.Create(224, 154, 0, 0)
TPlayerColor.Create(102, 170, 29, 0) ; TPlayerColor.Create(18, 187, 107, 0)
TPlayerColor.Create(205, 113, 247, 0) ; TPlayerColor.Create(255, 255, 0, 0)
TPlayerColor.Create(125, 143, 147, 0) ; TPlayerColor.Create(255, 125, 255, 0)
'#End Region

'create playerfigures in figures-image
'Local tmpFigure:TImage = Assets.GetSpritePack("figures").GetSpriteImage("", 0)
Global Player:TPlayer[5]

Player[1] = TPlayer.Create(Game.username, Game.userchannelname, Assets.GetSpritePack("figures").GetSpriteByID(0), 500, 1, 70, 247, 50, 50, 1, "Player 1")
Player[2] = TPlayer.Create("Alfie", "SunTV", Assets.GetSpritePack("figures").GetSpriteByID(0), 450, 3, 70, 245, 220, 0, 0, "Player 2")
Player[3] = TPlayer.Create("Seidi", "FunTV", Assets.GetSpritePack("figures").GetSpriteByID(0), 250, 8, 70, 40, 210, 0, 0, "Player 3")
Player[4] = TPlayer.Create("Sandra", "FatTV", Assets.GetSpritePack("figures").GetSpriteByID(0), 480, 13, 70, 0, 110, 245, 0, "Player 4")

Global tempfigur:TFigures = TFigures.Create("Hausmeister", gfx_figures_hausmeister, 210, 2,60,0)
tempfigur.FrameWidth = 12;tempfigur.targetx = 550
tempfigur.updatefunc_ = TFigures.UpdateHausmeister
Global figure_HausmeisterID:Int = tempfigur.id

tempfigur = TFigures.Create("Bote1", Assets.GetSpritePack("figures").GetSprite("BoteLeer"), 210, 3, 65, 0)
tempfigur.FrameWidth = 12;tempfigur.targetx = 550
tempfigur.updatefunc_	= TFigures.UpdateBote
Global figure_Bote1ID:Int = tempfigur.id
tempfigur				= TFigures.Create("Bote2", Assets.GetSpritePack("figures").GetSprite("BotePost"), 410, 8,-65,0)
tempfigur.FrameWidth = 12;tempfigur.targetx = 550
tempfigur.updatefunc_	= TFigures.UpdateBote
Global figure_Bote2ID:Int = tempfigur.id
tempfigur = Null

Global gfx_elevator_sign:TImage[5]
Global gfx_elevator_sign_dragged:TImage[5]
Global gfx_financials_barren:TImage[5]
Global MenuPlayerNames:TGUIinput[4]
Global MenuChannelNames:TGUIinput[4]
Global MenuFigureArrows:TGUIArrowButton[8]

PrintDebug ("Base", "creating GUIelements", DEBUG_START)
'MainMenu

Global MainMenuButton_Start:TGUIButton		= TGUIButton.Create(600, 300, 120, 0, 1, 1, Localization.GetString("MENU_SOLO_GAME"), "MainMenu", FontManager.GW_GetFont("Default", 11, BOLDFONT))
Global MainMenuButton_Network:TGUIButton	= TGUIButton.Create(600, 348, 120, 0, 1, 1, Localization.GetString("MENU_NETWORKGAME"), "MainMenu", FontManager.GW_GetFont("Default", 11, BOLDFONT))
Global MainMenuButton_Online:TGUIButton		= TGUIButton.Create(600, 396, 120, 0, 1, 1, Localization.GetString("MENU_ONLINEGAME"), "MainMenu", FontManager.GW_GetFont("Default", 11, BOLDFONT))

Global NetgameLobbyButton_Join:TGUIButton	= TGUIButton.Create(600, 300, 120, 0, 1, 1, Localization.GetString("MENU_JOIN"), "NetGameLobby", FontManager.GW_GetFont("Default", 11, BOLDFONT))
Global NetgameLobbyButton_Create:TGUIButton	= TGUIButton.Create(600, 345, 120, 0, 1, 1, Localization.GetString("MENU_CREATE_GAME"), "NetGameLobby", FontManager.GW_GetFont("Default", 11, BOLDFONT))
Global NetgameLobbyButton_Back:TGUIButton	= TGUIButton.Create(600, 390, 120, 0, 1, 1, Localization.GetString("MENU_BACK"), "NetGameLobby", FontManager.GW_GetFont("Default", 11, BOLDFONT))
Global NetgameLobby_gamelist:TGUIList		= TGUIList.Create(25 + 3, 300, 440, 175, 1, 100, "NetGameLobby")
NetgameLobby_gamelist.SetFilter("HOSTGAME")
NetgameLobby_gamelist.GUIbackground = Null

Global GameSettingsBG:TGUIBackgroundBox = TGUIBackgroundBox.Create(20, 20, 760, 260, 00, "Spieleinstellung", "GameSettings", FontManager.GW_GetFont("Default", 16, BOLDFONT))

Global GameSettingsOkButton_Announce:TGUIOkButton = TGUIOkButton.Create(420, 234, 0, 1, "Spieleinstellungen abgeschlossen", "GameSettings")
Global GameSettingsGameTitle:TGuiInput = TGUIinput.Create(50, 230, 320, 1, Game.title, 32, "GameSettings")
Global GameSettingsButton_Start:TGUIButton = TGUIButton.Create(600, 300, 120, 0, 1, 1, Localization.GetString("MENU_START_GAME"), "GameSettings", FontManager.GW_GetFont("Default", 11, BOLDFONT))
Global GameSettingsButton_Back:TGUIButton = TGUIButton.Create(600, 345, 120, 0, 1, 1, Localization.GetString("MENU_BACK"), "GameSettings", FontManager.GW_GetFont("Default", 11, BOLDFONT))
Global GameSettings_Chat:TGUIChat = TGuiChat.Create(20 + 3, 300, 450, 250, 1, 200, "GameSettings")
Global InGame_Chat:TGUIChat = TGuiChat.Create(10 + 3, 5, 360, 250, 1, 200, "InGame")
GameSettings_Chat._UpdateFunc_	= UpdateChat_GameSettings
InGame_Chat._UpdateFunc_ 		= UpdateChat_InGame
GUIManager.DefaultFont = FontManager.GW_GetFont("Default", 12, BOLDFONT)

GameSettings_Chat.GUIInput.TextDisplaceX = 5
GameSettings_Chat.GUIInput.TextDisplaceY = 2
'#Region  :configuring "InGame_Chat"-object
InGame_Chat.clickable= 0
InGame_Chat.nobackground = True
InGame_Chat.fadeout = True
InGame_Chat.GUIInput.pos.setXY( 290, 385)
InGame_Chat.GuiInput.width = gfx_GuiPack.GetSprite("Chat_IngameOverlay").w
InGame_Chat.GUIInput.InputImage = gfx_GuiPack.GetSprite("Chat_IngameOverlay")
InGame_Chat.Font = FontManager.GW_GetFont("Default", 10)

InGame_Chat.guichatgfx= 0
InGame_Chat.colR= 255; InGame_Chat.colG= 255; InGame_Chat.colB= 255
InGame_Chat.GuiInput.colR = 255; InGame_Chat.GuiInput.colG = 255; InGame_Chat.GuiInput.colB = 255
'#End Region
'#End Region


Function UpdateChat_GameSettings();		UpdateChat(GameSettings_Chat);		End Function
Function UpdateChat_InGame();			UpdateChat(InGame_Chat);			End Function

Function UpdateChat(UseChat:TGuiChat)
	If Usechat.EnterPressed >=1
		Usechat.EnterPressed = 0
		If Usechat.GUIInput.Value$ <> ""
			Usechat.AddEntry("",Usechat.GUIInput.Value$, Game.playerID,"", "", MilliSecs())
			If Game.networkgame If Network.isConnected Then Network.SendChatMessage(Usechat.GUIInput.Value$)
			'NetPlayer.SendNetMessage(UDPClientIP, NetworkPlayername$, "CHAT", GUIChat_NWGL_Chat.GUIInput.value$)
			Usechat.GUIInput.Value$ = ""
			GUIManager.setActive(0)
			Network.ChatSpamTime = MilliSecs() + 500
		EndIf
	EndIf
	If Usechat.TeamNames[1] = ""
		For Local i:Int = 0 To 4
			If Player[i] <> Null
				Usechat.TeamNames[i] = Player[i].Name
				Usechat.TeamColors[i] = Player[i].color
			Else
				Usechat.TeamNames[i] = "unknown"
				Usechat.TeamColors[i] = TPlayerColor.Create(255,255,255)
			End If
		Next
	EndIf
End Function


Function DrawAllSelectionRects()
	Local i:Int = 0

	For Local locobject:TPlayerColor = EachIn TPlayerColor.List
		If locobject.used = 0
			SetColor locobject.colR, locobject.colG, locobject.colB
			DrawRect(26 + 40 + i * 10, 92 + 68, 9, 9)
			DrawRect(216 + 40 + i * 10, 92 + 68, 9, 9)
			DrawRect(406 + 40 + i * 10, 92 + 68, 9, 9)
			DrawRect(596 + 40 + i * 10, 92 + 68, 9, 9)
			If MOUSEMANAGER.IsHit(1)
				If functions.IsIn(MouseX(), MouseY(), 26 + 40 + i * 10, 92 + 68, 7, 9) And (Player[1].Figure.ControlledByID = Game.playerID Or (Player[1].Figure.ControlledByID = 0 And Game.playerID = 1)) Then Player[1].RecolorFigure(locobject)
				If functions.IsIn(MouseX(), MouseY(), 216 + 40 + i * 10, 92 + 68, 7, 9) And (Player[2].Figure.ControlledByID = Game.playerID Or (Player[2].Figure.ControlledByID = 0 And Game.playerID = 1)) Then Player[2].RecolorFigure(locobject)
				If functions.IsIn(MouseX(), MouseY(), 406 + 40 + i * 10, 92 + 68, 7, 9) And (Player[3].Figure.ControlledByID = Game.playerID Or (Player[3].Figure.ControlledByID = 0 And Game.playerID = 1)) Then Player[3].RecolorFigure(locobject)
				If functions.IsIn(MouseX(), MouseY(), 596 + 40 + i * 10, 92 + 68, 7, 9) And (Player[4].Figure.ControlledByID = Game.playerID Or (Player[4].Figure.ControlledByID = 0 And Game.playerID = 1)) Then Player[4].RecolorFigure(locobject)
			EndIf
			i:+1
		EndIf
		SetColor 255,255,255
	Next
End Function

'Doubleclick-function for NetGameLobby_GameList
Function NetGameLobbyDoubleClick:Int(sender:Object)
	NetgameLobbyButton_Join.Clicked	= 1
	GameSettingsButton_Start.disable()
	Network.isHost 					= False
	Network.IP[0] = TNetwork.IntIP(NetgameLobby_gamelist.GetEntryIP())
	Network.Port[0] = Short(NetgameLobby_gamelist.GetEntryPort())
	GameSettingsGameTitle.Value = NetgameLobby_gamelist.GetEntryTitle()
	Network.NetConnect()
End Function
NetgameLobby_gamelist.SetDoubleClickFunc(NetGameLobbyDoubleClick)

Global Network:TTVGNetwork = TTVGNetwork.Create(game.userfallbackip)
Network.ONLINEPORT = Game.userport


For Local i:Int = 0 To 7
	If i < 4
		MenuPlayerNames[i]	= TGUIinput.Create(50 + 190 * i, 65, 130, 1, Player[i + 1].Name, 16, "GameSettings", FontManager.GW_GetFont("Default", 12)).SetOverlayImage(Assets.GetSprite("gfx_gui_overlay_player"))
		MenuPlayerNames[i].TextDisplaceX = 3
		MenuChannelNames[i]	= TGUIinput.Create(50 + 190 * i, 180, 130, 1, Player[i + 1].channelname, 16, "GameSettings", FontManager.GW_GetFont("Default", 12)).SetOverlayImage(Assets.GetSprite("gfx_gui_overlay_tvchannel"))
		MenuChannelNames[i].TextDisplaceX = 3
	End If
	If i Mod 2 = 0
		MenuFigureArrows[i] = TGUIArrowButton.Create(25+ 20+190*Ceil(i/2)+10, 125,0,0,1,0,"GameSettings", 0)
	Else
		MenuFigureArrows[i] = TGUIArrowButton.Create(25+140+190*Ceil(i/2)+10, 125,2,0,1,0,"GameSettings", 1)
	EndIf
Next

'#Region : Button (News and ProgrammePlanner)-Creation
For Local i:Int = 0 To 4
	TNewsbuttons.Create(0,3, Localization.GetString("NEWS_TECHNICS_MEDIA"), i, 20,194,0)
	TNewsbuttons.Create(1,0, Localization.GetString("NEWS_POLITICS_ECONOMY"), i, 69,194,1)
	TNewsbuttons.Create(2,1, Localization.GetString("NEWS_SHOWBIZ"), i, 20,247,2)
	TNewsbuttons.Create(3,2, Localization.GetString("NEWS_SPORT"), i, 69,247,3)
	TNewsbuttons.Create(4,4, Localization.GetString("NEWS_CURRENTAFFAIRS"),i, 118,247,4)
Next
TPPbuttons.Create(Assets.GetSprite("btn_options"), Localization.GetString("PLANNER_OPTIONS"), 672, 40 + 2 * 56, 2)
TPPbuttons.Create(Assets.GetSprite("btn_programme"), Localization.GetString("PLANNER_PROGRAMME"), 672, 40 + 1 * 56, 1)
TPPbuttons.Create(Assets.GetSprite("btn_ads"), Localization.GetString("PLANNER_ADS"), 672, 40 + 0 * 56, 0)
TPPbuttons.Create(Assets.GetSprite("btn_financials"), Localization.GetString("PLANNER_FINANCES"), 672, 40 + 3 * 56, 3)
TPPbuttons.Create(Assets.GetSprite("btn_image"), Localization.GetString("PLANNER_IMAGE"), 672, 40 + 4 * 56, 4)
TPPbuttons.Create(Assets.GetSprite("btn_news"), Localization.GetString("PLANNER_MESSAGES"), 672, 40 + 5 * 56, 5)
'#End Region

CreateDropZones()
Global Database:TDatabase = TDatabase.Create(); Database.Load(Game.userdb) 'load all movies, news, series and ad-contracts


StationMap.AddStation(310, 260, 1, Player[1].maxaudience)
StationMap.AddStation(310, 260, 2, Player[2].maxaudience)
StationMap.AddStation(310, 260, 3, Player[3].maxaudience)
StationMap.AddStation(310, 260, 4, Player[4].maxaudience)

HideMouse()
SetColor 255,255,255
SetImageFont FontManager.GW_GetFont("Default", 11)

For Local i:Int = 0 To 9
	TContractBlocks.Create(TContract.GetRandomContract(), i, 0)
	TMovieAgencyBlocks.Create(TProgramme.GetRandomMovie(),i,0)
	If i > 0 And i < 9 Then TAuctionProgrammeBlocks.Create(TProgramme.GetRandomMovieWithMinPrice(200000),i)
Next

Global PlayerDetailsTimer:Int
'Menuroutines... Submenus and so on
Function Menu_Main()
	GUIManager.Update("MainMenu")
	If MainMenuButton_Start.GetClicks() > 0 Then Game.gamestate = 5
	If MainMenuButton_Network.GetClicks() > 0 Then
		Game.gamestate  = 2
		Game.onlinegame = 0
		Network.stream = New TUDPStream
		If Not Network.Stream.Init() Then Throw("Can't create socket")
		Network.stream.SetLocalPort(Network.GetMyPort())
		Game.networkgame = 1
	EndIf
	If MainMenuButton_Online.GetClicks() > 0 Then
		Game.gamestate = 2
		Game.onlinegame = 1
		Network.stream = New TUDPStream
		If Not Network.Stream.Init() Then Throw("Can't create socket")
		Network.stream.SetLocalPort(Network.GetMyPort())
		Game.networkgame = 1
	EndIf
End Function

Function Menu_NetworkLobby()
	NetgameLobby_gamelist.RemoveOldEntries(NetgameLobby_gamelist.uId, 11000)
	If Game.onlinegame
		If Network.OnlineIP = ""
			Local Onlinestream:TStream   = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=MyIP")
			Local timeouttimer:Int = MilliSecs()+5000 '5 seconds okay?
			Local timeout:Byte = False
			If Not Onlinestream Then Throw ("Not Online?")
			While Not Eof(Onlinestream) Or timeout
				If timeouttimer < MilliSecs() Then timeout = True
				Local responsestring:String = ReadLine(Onlinestream)
				Local responseArray:String[] = StringSplit(responsestring, "|")
				If responseArray <> Null
					Network.OnlineIP = responseArray[0]
					Network.intOnlineIP = TNetwork.IntIP(Network.OnlineIP)
					Print "set your onlineIP"+responseArray[0]
				EndIf
			Wend
			CloseStream Onlinestream
		Else
			NetgameLobby_gamelist.SetFilter("ONLINEHOSTGAME")
			If Network.LastOnlineRequestTimer + Network.LastOnlineRequestTime < MilliSecs()
				Network.LastOnlineRequestTimer = MilliSecs()
				Local Onlinestream:TStream   = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=ListGames")
				Local timeouttimer:Int = MilliSecs()+2500 '2.5 seconds okay?
				Local timeout:Byte = False
				If Not Onlinestream Then Throw ("Not Online?")
				While Not Eof(Onlinestream) Or timeout
					If timeouttimer < MilliSecs() Then timeout = True
					Local responsestring:String = ReadLine(Onlinestream)
					Local responseArray:String[] = StringSplit(responsestring, "|")
					If responseArray <> Null
						NetgameLobby_gamelist.addUniqueEntry(Network.URLDecode(responseArray[0]), Network.URLDecode(responseArray[0])+"  (Spieler: "+responseArray[1]+" von 4)","",responseArray[2],Short(responseArray[3]),0, "ONLINEHOSTGAME")
						Print "added "+responseArray[0]
					EndIf
				Wend
				CloseStream Onlinestream
			EndIf
		EndIf
	EndIf
	If Not Game.onlinegame Then NetgameLobby_gamelist.SetFilter("HOSTGAME")
	GUIManager.Update("NetGameLobby")
	If NetgameLobbyButton_Create.GetClicks() > 0 Then
		GameSettingsButton_Start.enable()
		Game.gamestate = 3
		Network.isHost = True
		Network.IP[0] = Network.GetMyIP()
		Network.Port[0] = Network.GetMyPort()
		Network.MyID = 1
		DebugLog "create networkgame"
	EndIf
	If NetgameLobbyButton_Join.GetClicks() > 0 Then
		'Game.gamestate = 3
		GameSettingsButton_Start.disable()
		Network.isHost = False
		Network.IP[0] = TNetwork.IntIP(NetgameLobby_gamelist.GetEntryIP())
		Network.Port[0] = Short(NetgameLobby_gamelist.GetEntryPort())
		GameSettingsGameTitle.Value = NetgameLobby_gamelist.GetEntryTitle()
		Network.NetConnect()
	EndIf
	If NetgameLobbyButton_Back.GetClicks() > 0 Then
		Game.gamestate = 1
		Game.onlinegame = False
		Network.stream.Close
		Game.networkgame = False
	EndIf
End Function

Function Menu_GameSettings()
	If GameSettingsOkButton_Announce.crossed And Game.playerID=1
		GameSettingsOkButton_Announce.enable()
		GameSettingsGameTitle.disable()
		GameSettingsGameTitle.grayedout = True
		If GameSettingsGameTitle.Value = "" Then GameSettingsGameTitle.Value = "no title"
		Game.title = GameSettingsGameTitle.Value
	Else
		GameSettingsGameTitle.enable()
		GameSettingsGameTitle.grayedout = False
	EndIf
	If Game.playerID <> 1
		GameSettingsGameTitle.disable()
		GameSettingsGameTitle.grayedout = True
		GameSettingsOkButton_Announce.disable()
	End If

	Local ChangesAllowed:Byte[4]
	If Network.IsConnected
		If MilliSecs() >= PlayerDetailsTimer + 1000
			Network.SendPlayerDetails()
			PlayerDetailsTimer = MilliSecs()
		End If
	End If

	For Local i:Int = 0 To 3
		If Not MenuPlayerNames[i].on Then Player[i+1].Name = MenuPlayerNames[i].Value
		If Not MenuChannelNames[i].on Then Player[i+1].channelname = MenuChannelNames[i].Value
		If Network.IsConnected Or Game.playerID=1 Then
			If Game.gamestate <> 4 And Player[i+1].Figure.ControlledByID = Game.playerID Or (Player[i+1].Figure.ControlledByID = 0 And Game.playerID=1)
				ChangesAllowed[i] = True
				MenuPlayerNames[i].grayedout = False
				MenuChannelNames[i].grayedout = False
				MenuFigureArrows[i*2].enable()
				MenuFigureArrows[i*2 +1].enable()
			Else
				ChangesAllowed[i] = False
				MenuPlayerNames[i].grayedout = True
				MenuChannelNames[i].grayedout = True
				MenuFigureArrows[i*2].disable()
				MenuFigureArrows[i*2 +1].disable()
			EndIf
		EndIf
	Next

	GUIManager.Update("GameSettings")
	If GameSettingsButton_Start.GetClicks() > 0 Then
		If Not Game.networkgame And Not Game.onlinegame
			Game.gamestate = 0
		Else
			Game.gamestate = 4
		EndIf
		'Begin Game - create Events
		EventManager.registerEvent(TEventOnTime.Create("Game.OnMinute", game.minute))
		EventManager.registerEvent(TEventOnTime.Create("Game.OnHour", game.hour))
		EventManager.registerEvent(TEventOnTime.Create("Game.OnDay", game.day))
	EndIf
	If GameSettingsButton_Back.GetClicks() > 0 Then
		If Game.networkgame
			If Network.IsConnected Then Network.NetDisconnect(False)
			Game.playerID = 1
			TReliableUDP.List.Clear()
			Game.gamestate = 2
			GameSettingsOkButton_Announce.crossed = False
		Else
			Game.gamestate = 1
		EndIf
	EndIf
	For Local i:Int = 0 To 7
		If ChangesAllowed[Ceil(i/2)]
			If MenuFigureArrows[i].GetClicks() > 0
				If i Mod 2  = 0 Player[1+Ceil(i/2)].UpdateFigureBase(Player[Ceil(1+i/2)].figurebase -1)
				If i Mod 2 <> 0 Player[1+Ceil(i/2)].UpdateFigureBase(Player[Ceil(1+i/2)].figurebase +1)
			End If
		EndIf
	Next

	If Game.gamestate = 4
		GameSettingsOkButton_Announce.crossed = False
		Interface.ShowChannel = Game.playerID
	End If
End Function

Global MenuPreviewPicTimer:Int = 0
Global MenuPreviewPicTime:Int = 4000
Global MenuPreviewPic:TGW_Sprites = Null
Function Menu_Main_Draw()
	If Rand(0,10) = 10 Then GCCollect()
	SetColor 190,220,240
	SetAlpha 0.5
	DrawRect(0,0,App.width,App.Height)
	SetAlpha 1.0
	SetColor 255, 255, 255

	Local ScaledRoomHeight:Float = 190.0
	Local RoomImgScale:Float = ScaledRoomHeight / 373.0
	Local ScaledRoomWidth:Float = RoomImgScale * 760.0

	If MenuPreviewPicTimer < MilliSecs()
		MenuPreviewPicTimer = MilliSecs() + MenuPreviewPicTime
		MenuPreviewPic = TRooms(TRooms.RoomList.ValueAtIndex(Rnd(1, TRooms.RoomList.Count() - 1))).background
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

	If Game.cursorstate = 0 DrawImage(gfx_mousecursor, MouseX()-7, MouseY(),0)
	If Game.cursorstate = 1 DrawImage(gfx_mousecursor, MouseX() - 10, MouseY() - 10, 1)

End Function

Function Menu_NetworkLobby_Draw()
	SetColor 190,220,240
	SetAlpha 0.5
	DrawRect(0,0,App.width,App.height)
	SetAlpha 1.0
	SetColor 255,255,255
	GUIManager.Draw("NetGameLobby")
	If Not Game.onlinegame Then
		SetAlpha 0.3;functions.BlockText(Localization.GetString("MENU_NETWORKGAME")+": "+Localization.GetString("MENU_AVAIABLE_GAMES"), 36,277,500,50,0, Font16italic,  0, 0,  0)
		SetAlpha 1.0;functions.BlockText(Localization.GetString("MENU_NETWORKGAME")+": "+Localization.GetString("MENU_AVAIABLE_GAMES"), 34,275,500,50,0, Font16italic, 20,20,150)
	Else
		SetAlpha 0.3;functions.BlockText(Localization.GetString("MENU_ONLINEGAME")+": "+Localization.GetString("MENU_AVAIABLE_GAMES"), 36,277,500,50,0, Font16italic,  0, 0,  0)
		SetAlpha 1.0;functions.BlockText(Localization.GetString("MENU_ONLINEGAME")+": "+Localization.GetString("MENU_AVAIABLE_GAMES"), 34,275,500,50,0, Font16italic, 20,20,150)
	EndIf
	If Game.cursorstate = 0 DrawImage(gfx_mousecursor, MouseX()-7, MouseY(),0)
	If Game.cursorstate = 1 DrawImage(gfx_mousecursor, MouseX()-10, MouseY()-10,1)
End Function

Function Menu_GameSettings_Draw()
	SetColor 190,220,240
	SetAlpha 0.5
	DrawRect(0,0,App.width,App.height)
	SetAlpha 1.0
	SetColor 255,255,255

	' Local ChangesAllowed:Byte[4]
	If Not Game.networkgame
		GameSettingsBG.value = Localization.GetString("MENU_SOLO_GAME")
		GameSettings_Chat._visible = False
	Else
		GameSettings_Chat._visible = True
		If Not Game.onlinegame Then
			GameSettingsBG.value = Localization.GetString("MENU_NETWORKGAME")
		Else
			GameSettingsBG.value = Localization.GetString("MENU_ONLINEGAME")
		EndIf
	EndIf
	GUIManager.Draw("GameSettings",0, 0,9)

	For Local i:Int = 0 To 3
		SetColor 50,50,50
		DrawRect(60 + i*190, 90, 110,110)
		If Network.IsConnected Or Game.playerID=1 Then
			If Game.gamestate <> 4 And Player[i+1].Figure.ControlledByID = Game.playerID Or (Player[i+1].Figure.ControlledByID = 0 And Game.playerID=1)
				SetColor 255,255,255
			Else
				SetColor 225,255,150
			EndIf
		EndIf
		DrawRect(60 + i*190 +1, 90+1, 110-2,110-2)
'		DrawGFXRect(Assets.GetSpritePack("gfx_gui_rect"), 25 + 3 + i * 190, 50, 180, 200)
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

	DrawAllSelectionRects()

	Player[1].Figure.Sprite.Draw(25 + 90 - Player[1].Figure.Sprite.framew / 2, 159 - Player[1].Figure.Sprite.h, 8)
	Player[2].Figure.Sprite.Draw(215 + 90 - Player[2].Figure.Sprite.framew / 2, 159 - Player[2].Figure.Sprite.h, 8)
	Player[3].Figure.Sprite.Draw(405 + 90 - Player[3].Figure.Sprite.framew / 2, 159 - Player[3].Figure.Sprite.h, 8)
	Player[4].Figure.Sprite.Draw(595 + 90 - Player[4].Figure.Sprite.framew / 2, 159 - Player[4].Figure.Sprite.h, 8)

	GUIManager.Draw("GameSettings",0, 10)
	If Game.cursorstate = 0 DrawImage(gfx_mousecursor, MouseX()-7, MouseY(),0)
	If Game.cursorstate = 1 DrawImage(gfx_mousecursor, MouseX()-10, MouseY()-10,1)

	If Game.gamestate = 4
		SetColor 180,180,200
		SetAlpha 0.5
		DrawRect 200,200,400,200
		SetAlpha 1.0
		SetColor 0,0,0
		DrawText("Synchronisiere Startbedingungen...", 220,220)
		DrawText("Starte Netzwerkspiel...", 220,240)
		If Game.playerID = 1 Then
			For Local playerids:Int = 1 To 4
				SeedRnd(MilliSecs()*Rand(5))
				Local ProgrammeArray:TProgramme[]
				For Local j:Int = 0 To Game.start_MovieAmount-1
					ProgrammeArray=ProgrammeArray[..ProgrammeArray.length+1]
					ProgrammeArray[j] = TProgramme.GetRandomMovie(playerids)
					Print "send programme:"+ProgrammeArray[j].title
				Next
				Network.SendProgramme(playerids, ProgrammeArray)
				Local ContractArray:TContract[]
				For Local j:Int = 0 To Game.start_AdAmount-1
					ContractArray=ContractArray[..ContractArray.length+1]
					ContractArray[j] = TContract.GetRandomContract()
					Print "send contract:"+ContractArray[j].title
				Next
				Network.SendContract(playerids, ContractArray)
			Next

			Network.SendGameReady(Game.playerID)
		End If
		Repeat
		SetColor 180,180,200
		SetAlpha 1.0
		DrawRect 200,200,400,200
		SetAlpha 1.0
		SetColor 0,0,0
		DrawText("Synchronisiere Startbedingungen...", 220,220)
		DrawText("Starte Netzwerkspiel...", 220,240)
		DrawText("Player 1..."+Player[1].networkstate+" MovieListCount"+Player[1].ProgrammeCollection.MovieList.Count(), 220,260)
		DrawText("Player 2..."+Player[2].networkstate+" MovieListCount"+Player[2].ProgrammeCollection.MovieList.Count(), 220,280)
		DrawText("Player 3..."+Player[3].networkstate+" MovieListCount"+Player[3].ProgrammeCollection.MovieList.Count(), 220,300)
		DrawText("Player 4..."+Player[4].networkstate+" MovieListCount"+Player[4].ProgrammeCollection.MovieList.Count(), 220,320)
		If Not Game.networkgameready = 1 Then DrawText("not ready!!", 220,360)
		Flip
		Network.UpdateUDP()
		Until Game.networkgameready = 1
		If Game.networkgameready Then
			GameSettingsOkButton_Announce.crossed = False
			TReliableUDP.DeletePacketsWithCommand("SetSlot (Got Join)")
			TReliableUDP.DeletePacketsWithCommand("SendProgramme")
			TReliableUDP.DeletePacketsWithCommand("SendContract")
			Player[Game.playerID].networkstate=1
			Game.gamestate =0
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
		If SetEndingDay = True Then AwardEndingAtDay = Game.day + Duration
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

Game.gamestate = 1
Function UpdateMenu(deltaTime:Float=1.0)
	'	App.Timer.Update(0)

	If Game.networkgame Then Network.UpdateUDP
	If Game.gamestate = 1
		Menu_Main()
	ElseIf Game.gamestate = 2
		Menu_NetworkLobby()
	ElseIf (Game.gamestate = 3 Or Game.gamestate = 4 Or Game.gamestate = 5)
		Menu_GameSettings()
	EndIf
	If KEYMANAGER.IsHit(KEY_ESCAPE) Then ExitGame = 1
	If AppTerminate() Then ExitGame = 1
End Function

Global LogoTargetY:Float = 20
Global LogoCurrY:Float = 100
Function DrawMenu(tweenValue:Float=1.0)
'no cls needed - we render a background
'	Cls
	SetColor 255,255,255
	gfx_startscreen.render(0, 0)

	' DrawImage(gfx_startscreen, 0, 0)
	If Game.gamestate < 3 Or Game.gamestate > 5
		If LogoCurrY > LogoTargetY Then LogoCurrY:+- 30.0 * App.Timer.getDeltaTime() Else LogoCurrY = LogoTargetY
		DrawImage(gfx_startscreen_logo, 400 - ImageWidth(gfx_startscreen_logo) / 2, LogoCurrY)
	Else
		DrawImage(gfx_startscreen_logosmall, 540, 480)
	EndIf
	SetColor 0, 0, 0
	DrawText (Game.playerID, 10, 2)


	SetColor 255,255,255
	functions.BlockText(versionstring, 10,575, 500,20,0,Font11italic,75,75,140)
	functions.BlockText(copyrightstring, 10,585, 500,20,0,Font11italic,60,60,120)
	If Game.gamestate = 1 Then Menu_Main_Draw()..
	ElseIf Game.gamestate = 2 Then Menu_NetworkLobby_Draw()..
	ElseIf (Game.gamestate = 3 Or Game.gamestate = 4 Or Game.gamestate = 5) Then Menu_GameSettings_Draw()
End Function

Function Init_Creation()
	Local lastblocks:Int = 0
	'Local lastprogramme:TProgrammeBlock = New TProgrammeBlock

	For Local i:Int = 0 To 5
		TMovieAgencyBlocks.Create(TProgramme.GetRandomSerie(),20+i,0)
	Next

	'create random programmes and so on
	TFigures.GetFigure(figure_HausmeisterID).updatefunc_ = Null
	If Not Game.networkgame Then
		For Local playerids:Int = 1 To 4
			For Local i:Int = 0 To 5
				SeedRnd(MilliSecs())
				Player[playerids].ProgrammeCollection.AddMovie(TProgramme.GetRandomMovie(playerids), playerids)
			Next
			Player[playerids].ProgrammeCollection.AddContract(TContract.GetRandomContract(),playerids)
			Player[playerids].ProgrammeCollection.AddContract(TContract.GetRandomContract(),playerids)
			Player[playerids].ProgrammeCollection.AddContract(TContract.GetRandomContract(),playerids)
		Next
		TFigures.GetFigure(figure_HausmeisterID).updatefunc_ = TFigures.UpdateHausmeister
	EndIf

	'creation of blocks for players rooms
	lastblocks = 0
	For Local playerids:Int = 1 To 4
		TAdBlock.Create("1.", 67 + Assets.GetSprite("pp_programmeblock1").w, 17 + 0 * Assets.GetSprite("pp_adblock1").h, playerids, 1)
		TAdBlock.Create("2.", 67 + Assets.GetSprite("pp_programmeblock1").w, 17 + 1 * Assets.GetSprite("pp_adblock1").h, playerids, 2)
		TAdBlock.Create("3.", 67 + Assets.GetSprite("pp_programmeblock1").w, 17 + 2 * Assets.GetSprite("pp_adblock1").h, playerids, 3)
		Local lastprogramme:TProgrammeBlock
		lastprogramme = TProgrammeBlock.Create("1.", 67, 17 + 0 * Assets.GetSprite("pp_programmeblock1").h, 0, playerids, 1)
		lastblocks :+ lastprogramme.blocks
		lastprogramme = TProgrammeBlock.Create("2.", 67, 17 + lastblocks * Assets.GetSprite("pp_programmeblock1").h, 0, playerids, 2)
		lastblocks :+ lastprogramme.blocks
		lastprogramme = TProgrammeBlock.Create("3.", 67, 17 + lastblocks * Assets.GetSprite("pp_programmeblock1").h, 0, playerids, 3)
	Next

End Function

Function Init_Colorization()
	'colorize the images

	Assets.AddImageAsSprite("gfx_financials_barren0", ColorizeTImage(gfx_financials_barren_base, 200, 200, 200) )
	Assets.AddImageAsSprite("gfx_building_sign0", Assets.GetSprite("gfx_building_sign_base").GetColorizedImage(200,200,200) )
	Assets.AddImageAsSprite("gfx_elevator_sign0", Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage(200,200,200) )
	Assets.AddImageAsSprite("gfx_elevator_sign_dragged0", Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage(200, 200, 200) )
	Assets.AddImageAsSprite("gfx_interface_channelbuttons0", Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage(100,100,100), Assets.GetSprite("gfx_building_sign_base").animcount )
	Assets.AddImageAsSprite("gfx_interface_channelbuttons5", Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage(100,100,100), Assets.GetSprite("gfx_building_sign_base").animcount )

	'colorizing for every player and inputvalues (player and channelname) to players variables
	For Local i:Int = 1 To 4
		Player[i].Name					= MenuPlayerNames[i-1].Value
		Player[i].channelname			= MenuChannelNames[i-1].Value
		Assets.AddImageAsSprite("gfx_financials_barren"+i, ColorizeTImage(gfx_financials_barren_base,Player[i].color.colR, Player[i].color.colG, Player[i].color.colB) )
		Assets.AddImageAsSprite("gfx_building_sign"+i, Assets.GetSprite("gfx_building_sign_base").GetColorizedImage(Player[i].color.colR, Player[i].color.colG, Player[i].color.colB) )
		Assets.AddImageAsSprite("gfx_elevator_sign"+i, Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage( Player[i].color.colR, Player[i].color.colG, Player[i].color.colB) )
		Assets.AddImageAsSprite("gfx_elevator_sign_dragged"+i, Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage(Player[i].color.colR, Player[i].color.colG, Player[i].color.colB) )
		Assets.AddImageAsSprite("gfx_interface_channelbuttons"+i,   Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage(Player[i].color.colR, Player[i].color.colG, Player[i].color.colB),Assets.GetSprite("gfx_interface_channelbuttons_off").animcount )
		Assets.AddImageAsSprite("gfx_interface_channelbuttons"+(i+5), Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage(Player[i].color.colR, Player[i].color.colG, Player[i].color.colB),Assets.GetSprite("gfx_interface_channelbuttons_on").animcount )
		Player[i].ProgrammePlan.refreshprogrammeplan(i,Game.day)
	Next
End Function

Function Init_All()
	PrintDebug ("Init_All()", "start", DEBUG_START)
	Init_Creation()
	PrintDebug ("  Init_Colorization()", "colorizing Images corresponding to playercolors", DEBUG_START)
	Init_Colorization()
	Init_SetRoomNames()	'setzt Raumnamen entsprechend Spieler/Sendernamen
	Init_CreateRoomTooltips()  'erstellt Raum-Tooltips und somit auch Raumplaner-Schilder
	PrintDebug ("  TRooms.DrawDoorsOnBackground()", "drawing door-prites on the building-sprite", DEBUG_START)
	Print "init_doors"
	TRooms.DrawDoorsOnBackground() 		'draws the door-sprites on the building-sprite
	PrintDebug ("  Building.DrawItemsToBackground()", "drawing plants and lights on the building-sprite", DEBUG_START)
	Print "init_back"
	Building.DrawItemsToBackground()  	'draws plants and lights which are behind the figures
	PrintDebug ("Init_All()", "complete", DEBUG_START)
End Function

'ingame update
Function UpdateMain(deltaTime:Float = 1.0)
	TError.UpdateErrors()
	Game.cursorstate = 0
	If Player[Game.playerID].Figure.inRoom <> Null Then Player[Game.playerID].Figure.inRoom.Update(0)

	'ingamechat
	'	If Game.networkgame
	'		If KEYWRAPPER.pressedKey(KEY_ENTER) And GUIManager.getActive() <> InGame_Chat.GUIINPUT.uId And Network.ChatSpamTime < MilliSecs()
	If KEYMANAGER.IsHit(KEY_ENTER)
		If GUIManager.getActive() <> InGame_Chat.GUIINPUT.uId
			If Network.ChatSpamTime < MilliSecs()
				GUIManager.setActive( InGame_Chat.GUIInput.uId )
			Else
				Print "no spam pls"
			EndIf
		EndIf
	EndIf
	'	EndIf

	'#Region 'developer shortcuts (1-4, B=office, C=Chief ...)
	If GUIManager.getActive() <> InGame_Chat.GUIInput.uId
		If Not Game.networkgame
			If KEYMANAGER.IsHit(KEY_1) Game.playerID = 1
			If KEYMANAGER.IsHit(KEY_2) Game.playerID = 2
			If KEYMANAGER.IsHit(KEY_3) Game.playerID = 3
			If KEYMANAGER.IsHit(KEY_4) Game.playerID = 4
		EndIf
		If KEYMANAGER.IsHit(KEY_TAB) Game.DebugInfos = 1 - Game.DebugInfos
		If KEYMANAGER.IsHit(KEY_6) Game.speed = 20.0
		If KEYMANAGER.IsHit(KEY_7) Game.speed = 0.5
		If KEYMANAGER.IsHit(KEY_8) Game.speed = 1.5
		If KEYMANAGER.IsHit(KEY_9) Game.speed = 3.0
		If KEYMANAGER.IsHit(KEY_W) Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("adagency", 0)
		If KEYMANAGER.IsHit(KEY_A) Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("archive", Game.playerID)
		If KEYMANAGER.IsHit(KEY_B) Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("betty", 0)
		If KEYMANAGER.IsHit(KEY_F) Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("movieagency", 0)
		If KEYMANAGER.IsHit(KEY_O) Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("office", Game.playerID)
		If KEYMANAGER.IsHit(KEY_C) Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("chief", Game.playerID)
		If KEYMANAGER.IsHit(KEY_N) Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("news", Game.playerID)
		If KEYMANAGER.IsHit(KEY_R) Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("roomboard", -1)
		If KEYMANAGER.IsHit(KEY_D) TProfiler.activated = 1 - TProfiler.activated
		If KEYMANAGER.IsHit(KEY_S)
			Game.oldspeed = Game.speed
			Game.speed = 0
			SaveError = TError.Create("Speichere...", "Spielstand wird gespeichert")
			Game.SaveGame()
			SaveError.link.Remove()
			Game.speed = Game.oldspeed
		EndIf
		If KEYMANAGER.IsHit(KEY_L)
			Game.speed = 0
			LoadError = TError.Create("Lade...", "Spielstand wird geladen")
			Game.LoadGame("savegame.zip")
			LoadError.link.Remove()
		EndIf
		If KEYMANAGER.IsHit(KEY_P)
			'Local Room:TRooms = TRooms.GetRoomFromID(30)
			Local Room:TRooms = TRooms.GetRoom("news", 1)
			If Room <> Null Then Player[1].Figure.SendToRoom(Room) ;Print "send to room:" + room.Name + " floor"+room.Pos.y + " owner:" + room.owner

		End If
		If KEYMANAGER.IsDown(KEY_UP) Game.speed:+0.05
		If KEYMANAGER.IsDown(KEY_DOWN) Game.speed:-0.05;If Game.speed < 0 Then Game.speed = 0
	EndIf
	'#EndRegion

	If Player[Game.playerID].Figure.inRoom = Null
		If MOUSEMANAGER.IsDown(1)
			If functions.IsIn(MouseX(), MouseY(), 20, 10, 760, 373)
				Player[Game.playerID].Figure.ChangeTarget(MouseX(), MouseY())
				TRooms.GetClickedRoom(Player[Game.playerID].Figure)
			EndIf
			MOUSEMANAGER.resetKey(1)
		EndIf
	EndIf
	'	If Player[Game.playerID].Figure.inRoom = Null Then Building.y = 115 + 73 - Player[Game.playerID].Figure.y  'working for player as center
	'66 = 13th floor height, 2 floors normal = 2*73, 50 = roof
	If Player[Game.playerID].Figure.inRoom = Null Then Building.y = 1 * 66 + 2 * 73 + 50 - Player[Game.playerID].Figure.pos.y  'working for player as center
	Fader.Update(deltaTime)

	Game.Update(deltaTime)
	Interface.Update(deltaTime)
	If Player[Game.playerID].Figure.inRoom = Null Then Building.Update(deltaTime)
	Building.Elevator.Update(deltaTime)
	TFigures.UpdateAll(deltaTime)

	If KEYMANAGER.IsHit(KEY_ESCAPE) Then ExitGame = 1
	If KEYMANAGER.IsHit(KEY_F12) Then PrepareScreenshot = 1
	If Game.networkgame Then If Network.IsConnected Then Network.UpdateUDP
End Function

'inGame
Function DrawMain(tweenValue:Float=1.0)
	If Player[Game.playerID].Figure.inRoom = Null
		TProfiler.Enter("DrawBuilding")
		SetColor Int(190 * Building.timecolor), Int(215 * Building.timecolor), Int(230 * Building.timecolor)
		DrawRect(20, 10, 140, 373)
		If Building.y > 10 Then DrawRect(150, 10, 500, 200)
		DrawRect(650, 10, 130, 373)
		SetColor 255, 255, 255
		Building.Draw()									'player is not in a room so draw building
		TProfiler.Leave("DrawBuilding")
	Else
		TProfiler.Enter("DrawRoom")
		Player[Game.playerID].Figure.inRoom.Draw()		'draw the room
		Player[Game.playerID].Figure.inRoom.Update(1) 	'update room-actions
		TProfiler.Leave("DrawRoom")
	EndIf

	Fader.Draw()
	Interface.Draw()

	DrawText ("Netstate:" + Player[Game.playerID].networkstate + " Speed:" + Int(Game.speed * 100), 0, - 2)

	If Game.DebugInfos
		SetColor 0,0,0
		DrawRect(10,15,100,100)
		SetColor 255, 255, 255
		If directx = 1 Then DrawText ("Mode: DirectX 7", 15, 50)
		If directx = 0 Then DrawText ("Mode: OpenGL", 15,50)
		If directx = 2 Then DrawText ("Mode: DirectX 9", 15,50)

		If Game.networkgame
			GUIManager.Draw("InGame") 'draw ingamechat
			SetAlpha 0.4
			SetColor 0, 0, 0
			DrawRect(660, 483,115,120)
			SetAlpha 1.0
			SetColor 255,255,255
			DrawText(Network.stream.UDPSpeedString(), 662,490)
			For Local i:Int = 0 To 3
				If Player[i + 1].Figure.inRoom <> Null
					DrawText("Player " + (i + 1) + ": " + Player[i + 1].Figure.inRoom.Name, 662, 510 + i * 11)
				Else
					If Player[i + 1].Figure.IsInElevator()
						DrawText("Player " + (i + 1) + ": InElevator", 662, 510 + i * 11)
					Else If Player[i + 1].Figure.IsAtElevator()
						DrawText("Player " + (i + 1) + ":			AtElevator", 662, 510 + i * 11)
					Else
						DrawText("Player " + (i + 1) + ": Building", 662, 510 + i * 11)
					EndIf
				EndIf
				DrawText("Ping "+(i+1)+": "+Network.MyPing[i]+"ms", 672,555+i*11)
			Next
		EndIf
	EndIf
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

	Method OnEvent(triggerEvent:TEventBase)
		Local evt:TEventOnTime = TEventOnTime(triggerEvent)
		If evt<>Null

			If evt._trigger = "game.onminute" Then Self.Player.PlayerKI.CallOnMinute()
			If evt._trigger = "game.onday" Then Self.Player.PlayerKI.CallOnDayBegins()
		EndIf
	End Method
End Type

Type TEventListenerOnMinute Extends TEventListenerBase

	Function Create:TEventListenerOnMinute()
		Local obj:TEventListenerOnMinute = New TEventListenerOnMinute
		Return obj
	End Function


	Method OnEvent(triggerEvent:TEventBase)
		Local evt:TEventOnTime = TEventOnTime(triggerEvent)
		If evt<>Null
			'things happening x:05
			Local minute:Int = evt.time Mod 60
			Local hour:Int = Floor(evt.time / 60)

			If minute = 5 Then TPlayer.ComputeAudience()
			If minute = 55 Then TPlayer.ComputeAds()
			If minute = 0
				If hour+1 < 6 And hour+1 > 1 Then game.maxAudiencePercentage = Float(RandRange(5, 15)) / 100
				If hour+1 >= 6 And hour+1 < 18 Then game.maxAudiencePercentage = Float(RandRange(10, 10 + hour+1)) / 100
				If hour+1 >= 18 Or hour+1 <= 1 Then game.maxAudiencePercentage = Float(RandRange(15, 20 + hour+1)) / 100
				TPlayer.ComputeNewsAudience()
 			EndIf
 			If minute = 5 Or minute = 55 Or minute=0 Then Interface.BottomImgDirty = True
		EndIf
	End Method
End Type

Type TEventListenerOnDay Extends TEventListenerBase

	Function Create:TEventListenerOnDay()
		Local obj:TEventListenerOnDay = New TEventListenerOnDay
		Return obj
	End Function

	Method OnEvent(triggerEvent:TEventBase)
		Local evt:TEventOnTime = TEventOnTime(triggerEvent)
		If evt<>Null
			'Neuer Award faellig?
			If Betty.GetAwardEnding() < Game.day - 1
				Betty.GetLastAwardWinner()
				Betty.SetAwardType(Rand(0, Betty.MaxAwardTypes), True)
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
				TRooms.ResetRoomSigns()
				TNewsBlock.List.sort()
				For Local NewsBlock:TNewsBlock = EachIn TNewsBlock.List
					If Game.day - Newsblock.news.happenedday >= 2
						Player[Newsblock.owner].ProgrammePlan.RemoveNews(NewsBlock.news)
						TNewsBlock.List.remove(NewsBlock)
					EndIf
				Next
			EndIf

		EndIf
	End Method
End Type

Type TEventListenerOnAppUpdate Extends TEventListenerBase

	Function Create:TEventListenerOnAppUpdate()
		Return New TEventListenerOnAppUpdate
	End Function


	Method OnEvent(triggerEvent:TEventBase)
		Local evt:TEventSimple = TEventSimple(triggerEvent)
		If evt<>Null
			KEYMANAGER.changeStatus()

			If Game.gamestate = 0
				UpdateMain(App.Timer.getDeltaTime())
			Else
				UpdateMenu(App.Timer.getDeltaTime())
			EndIf
			If Rand(0,20) = 20 Then GCCollect()

			MOUSEMANAGER.changeStatus(Game.error)
		EndIf
	End Method
End Type

Type TEventListenerOnAppDraw Extends TEventListenerBase

	Function Create:TEventListenerOnAppDraw()
		Return New TEventListenerOnAppDraw
	End Function


	Method OnEvent(triggerEvent:TEventBase)
		Local evt:TEventSimple = TEventSimple(triggerEvent)
		If evt<>Null
			If Game.gamestate = 0
				DrawMain()
			Else
				DrawMenu()
			EndIf
			DrawText("FPS:"+App.Timer.fps + " UPS:" + Int(App.Timer.ups), 150,0)
			DrawText("deltaTime "+Int(1000*App.Timer.loopTime)+"ms", 250,0)
			If PrepareScreenshot = 1 Then PrepareScreenshot:+1;DrawImage(gfx_startscreen_logosmall, App.width - ImageWidth(gfx_startscreen_logosmall) - 10, 10)
			'GUIManager.Draw("InGame")
			Flip App.limitFrames
			If PrepareScreenshot = 2 Then PrepareScreenshot = 0;SaveScreenshot()
		EndIf
	End Method
End Type



'__________________________________________
'events
For Local i:Int = 1 To 4
	If Player[i].figure.isAI()
		EventManager.registerListener( "Game.OnMinute",	TEventListenerPlayer.Create(Player[i]) )
		EventManager.registerListener( "Game.OnDay", 	TEventListenerPlayer.Create(Player[i]) )
	EndIf
Next
EventManager.registerListener( "Game.OnDay", 	TEventListenerOnDay.Create() )
EventManager.registerListener( "Game.OnMinute",	TEventListenerOnMinute.Create() )


Global Curves:TNumberCurve = TNumberCurve.Create(1, 200)

Global DelayPossible:Int = 0
Global Init_Complete:Int = 0

'Init EventManager
'could also be done during update ("if not initDone...")
EventManager.Init()
If ExitGame <> 1 And Not AppTerminate()'not exit game
	KEYWRAPPER.allowKey(13, KEYWRAP_ALLOW_BOTH, 400, 100)
	Repeat
		If Not Init_Complete Then Init_All() ;Init_Complete = True		'check if rooms/colors/... are initiated
		If KEYMANAGER.IsHit(KEY_ESCAPE) ExitGame = 1;Exit				'ESC pressed, exit game

		If KEYMANAGER.Ishit(Key_F1)
			If Player[1].figure.isAI() Then Player[1].PlayerKI.reloadScript()
		EndIf
		If KEYMANAGER.Ishit(Key_F2)
			If Player[2].figure.isAI() Then Player[2].PlayerKI.reloadScript()
		EndIf
		If KEYMANAGER.Ishit(Key_F3)
			If Player[3].figure.isAI() Then Player[3].PlayerKI.reloadScript()
		EndIf
		If KEYMANAGER.Ishit(Key_F4)
			If Player[4].figure.isAI() Then Player[4].PlayerKI.reloadScript()
		EndIf
		App.Timer.loop()

		'process events not directly triggered
		'process "onMinute" etc.
		EventManager.update()

	Until AppTerminate() Or ExitGame = 1
	If Game.networkgame Then If Network.IsConnected = True Then Network.NetDisconnect ' Disconnect
EndIf 'not exit game

Include "network.bmx"