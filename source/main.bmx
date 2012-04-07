'Application: TVGigant/TVTower
'Author: Ronny Otto

SuperStrict
'Framework brl.glmax2d
Import brl.timer
Import brl.Graphics
Import brl.reflection
Import "basefunctions_network.bmx"
Import "basefunctions.bmx"						'Base-functions for Color, Image, Localization, XML ...
Import "files.bmx"								'Load images, configs,... (imports functions.bmx)

Import "basefunctions_guielements.bmx"			'Guielements like Input, Listbox, Button...
Import "basefunctions_events.bmx"				'event handler
Import "basefunctions_deltatimer.bmx"
Import "basefunctions_lua.bmx"					'our lua engine
GUIManager.globalScale	= 0.75
GUIManager.defaultFont	= FontManager.GetFont("Default", 12)
Include "gamefunctions_tvprogramme.bmx"  		'contains structures for TV-programme-data/Blocks and dnd-objects
Include "gamefunctions.bmx" 					'Types: - TError - Errorwindows with handling
												'		- base class For buttons And extension newsbutton
												'		- stationmap-handling, -creation ...
Include "gamefunctions_rooms.bmx"				'basic roomtypes with handling
Include "gamefunctions_ki.bmx"					'LUA connection

'Initialise Render-To-Texture
tRender.Initialise()

Global ArchiveProgrammeList:TgfxProgrammelist	= TgfxProgrammelist.Create(575, 16, 21)
Global PPprogrammeList:TgfxProgrammelist		= TgfxProgrammelist.Create(515, 16, 21)
Global PPcontractList:TgfxContractlist			= TgfxContractlist.Create(645, 16)

Print "onclick-eventlistener integrieren: btn_newsplanner_up/down"
Global Btn_newsplanner_up:TGUIImageButton		= TGUIImageButton.Create(375, 150, 47, 32, "gfx_news_pp_btn_up", 0, 1, 0, "Newsplanner", 0)
Global Btn_newsplanner_down:TGUIImageButton		= TGUIImageButton.Create(375, 250, 47, 32, "gfx_news_pp_btn_down", 0, 1, 0, "Newsplanner", 3)

Global SaveError:TError, LoadError:TError
Global ExitGame:Int 							= 0 			'=1 and the game will exit
Global Fader:TFader								= New TFader
Global NewsAgency:TNewsAgency					= New TNewsAgency

SeedRand(103452)
print "seedRand festgelegt - bei Netzwerk bitte jeweils neu auswürfeln und bei join mitschicken - fuer Testzwecke aber aktiv, immer gleiches Programm"

TButton.UseFont 		= FontManager.GetFont("Default", 12, 0)
TTooltip.UseFontBold	= FontManager.GetFont("Default", 11, BOLDFONT)
TTooltip.UseFont 		= FontManager.GetFont("Default", 11, 0)
TTooltip.ToolTipIcons	= gfx_building_tooltips
TTooltip.TooltipHeader	= Assets.GetSprite("gfx_tooltip_header")
Global App:TApp = TApp.Create(60, 1) 'create with 60fps for physics and graphics

Type TApp
	Field Timer:TDeltaTimer
	Field limitFrames:Int = 0
	Field settings:TApplicationSettings
	Field prepareScreenshot:Int = 0

	Function Create:TApp(physicsFps:Int = 60, limitFrames:Int = 0)
		Local obj:TApp = New TApp
		obj.settings = Settings 'global
		'create timer
		obj.timer = TDeltaTimer.Create(physicsFps)
		'listen to App-timer
		EventManager.registerListener( "App.onUpdate", 	TEventListenerOnAppUpdate.Create() )
		EventManager.registerListener( "App.onDraw", 	TEventListenerOnAppDraw.Create() )

		Return obj
	End Function
End Type


Const GAMESTATE_RUNNING:Int					= 0
Const GAMESTATE_MAINMENU:Int				= 1
Const GAMESTATE_NETWORKLOBBY:Int			= 2
Const GAMESTATE_SETTINGSMENU:Int			= 3
Const GAMESTATE_STARTMULTIPLAYER:Int		= 4		'mode when data gets synchronized

'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame
	''rename CONFIG-vars ... config_DoorOpenTime... config_gameSpeed ...
	Const maxAbonnementLevel:Int		= 3

	Field maxAudiencePercentage:Float 	= 0.3	{nosave}	'how many 0.0-1.0 (100%) audience is maximum reachable
	Field maxContractsAllowed:Int 		= 8		{nosave}	'how many contracts a player can possess
	Field maxMoviesInSuitcaseAllowed:Int= 12	{nosave}	'how many movies can be carried in suitcase
	Field startMovieAmount:Int 			= 5		{nosave}	'how many movies does a player get on a new game
	Field startSeriesAmount:Int			= 1		{nosave}	'how many series does a player get on a new game
	Field startAdAmount:Int				= 3		{nosave}	'how many contracts a player gets on a new game
	Field debugmode:Byte				= 0		{nosave}	'0=no debug messages; 1=some debugmessages
	Field DebugInfos:Byte				= 0		{nosave}

	Field daynames:String[]						{nosave}	'array of abbreviated (short) daynames
	Field daynamesLong:String[] 				{nosave}	'array of daynames (long version)
	Field DoorOpenTime:Int				= 100	{nosave}	'time how long a door will be shown open until figure enters

	Field username:String				= ""	{nosave}	'username of the player ->set in config
	Field userport:Short				= 4544	{nosave}	'userport of the player ->set in config
	Field userchannelname:String		= ""	{nosave}	'channelname the player uses ->set in config
	Field userlanguage:String			= "de"	{nosave}	'language the player uses ->set in config
	Field userdb:String					= ""	{nosave}
	Field userfallbackip:String			= "" 	{nosave}

	Field speed:Float				= 0.1 					'Speed of the game
	Field oldspeed:Float			= 0.1 					'Speed of the game - used when saving a game ("pause")
	Field minutesOfDayGone:Float	= 0.0					'time of day in game, unformatted
	Field lastMinutesOfDayGone:Float= 0.0					'time last update was done
	Field timeSinceBegin:Float 								'time in game, not reset every day
	Field year:Int=2006, day:Int=1, minute:Int=0, hour:Int=0 'date in game

	Field title:String 				= "MyGame"				'title of the game
	Field daytoplan:Int 			= 1						'which day has to be shown in programmeplanner

	Field cursorstate:Int		 	= 0 					'which cursor has to be shown? 0=normal 1=dragging
	Field playerID:Int 				= 1						'playerID of player who sits in front of the screen
	Field error:Int 				= 0 					'is there a error (errorbox) floating around?
	Field gamestate:Int 			= 0						'0 = Mainmenu, 1=Running, ...

	Field stateSyncTime:int			= 0						'last sync
	Field stateSyncTimer:int		= 2000					'sync every

	'--networkgame auf "isNetworkGame()" umbauen
	Field networkgame:Int 			= 0 					'are we playing a network game? 0=false, 1=true, 2
	Field networkgameready:Int 		= 0 					'is the network game ready - all options set? 0=false
	Field onlinegame:Int 			= 0 					'playing over internet? 0=false

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
print "implement TGame:Load"
return 0
rem
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
			If Players[i] <> Null
				If Players[i].PlayerKI = Null And Players[i].figure.controlledbyID = 0 Then PrintDebug ("TGame.Update()", "FEHLER: KI fuer Spieler " + i + " nicht gefunden", DEBUG_UPDATES)
				If Players[i].figure.controlledbyID = 0
					LoadSaveFile.xmlWrite("KI"+i, Players[i].PlayerKI.CallOnSave())
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
		TContractBlock.SaveAll();			TError.DrawErrors();Flip 0  'XML
		TProgrammeBlock.SaveAll();			TError.DrawErrors();Flip 0  'XML
		TAdBlock.SaveAll();					TError.DrawErrors();Flip 0  'XML
		TNewsBlock.SaveAll();				TError.DrawErrors();Flip 0  'XML
		TMovieAgencyBlocks.SaveAll();		TError.DrawErrors();Flip 0  'XML
		TArchiveProgrammeBlock.SaveAll();	TError.DrawErrors();Flip 0  'XML
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
						Players[1].PlayerKI.CallOnLoad(LoadSaveFile.NODE.getContent())
					Case "KI2"
						Players[2].PlayerKI.CallOnLoad(LoadSaveFile.NODE.getContent())
					Case "KI3"
						Players[3].PlayerKI.CallOnLoad(LoadSaveFile.NODE.getContent())
					Case "KI4"
						Players[4].PlayerKI.CallOnLoad(LoadSaveFile.NODE.getContent())
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
		Game.day 				= 1
		Game.minute 			= 0
		Game.title				= "unknown"
		Return Game
	End Function

	Method IsPlayerID:Int(number:Int)
		Return (number > 0 And number <= 4)
	End Method

	Method GetDayName:String(day:Int, longVersion:Int=0)
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
		local node:TxmlNode = xml.FindRootChild("settings")
		If node = Null Or node.getName() <> "settings"
			Print "settings.xml fehlt der settings-Bereich"
			return 0
		endif
		Self.username			= xml.FindValue(node,"username", "Ano Nymus")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'username' fehlt, setze Defaultwert: 'Ano Nymus'", DEBUG_LOADING)
		Self.userchannelname	= xml.FindValue(node,"channelname", "SunTV")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'userchannelname' fehlt, setze Defaultwert: 'SunTV'", DEBUG_LOADING)
		Self.userlanguage		= xml.FindValue(node,"language", "de")			'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'language' fehlt, setze Defaultwert: 'de'", DEBUG_LOADING)
		Self.userport			= xml.FindValueInt(node,"onlineport", 4444)		'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'onlineport' fehlt, setze Defaultwert: '4444'", DEBUG_LOADING)
		Self.userdb				= xml.FindValue(node,"database", "res/database.xml")	'Print "settings.xml - missing 'database' - set to default: 'database.xml'"
		Self.title				= xml.FindValue(node,"defaultgamename", "MyGame")		'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'defaultgamename' fehlt, setze Defaultwert: 'MyGame'", DEBUG_LOADING)
		Self.userfallbackip		= xml.FindValue(node,"fallbacklocalip", "192.168.0.1")	'PrintDebug ("TGame.LoadConfig()", "settings.xml - 'fallbacklocalip' fehlt, setze Defaultwert: '192.168.0.1'", DEBUG_LOADING)
	End Method

	Method calculateMaxAudiencePercentage:Float(forHour:Int= -1)
		If forHour <= 0 Then forHour = Self.hour

		'based on weekday (thursday) in march 2011 - maybe add weekend
		Select hour
			Case 0	game.maxAudiencePercentage = 11.40 + Float(RandRange( -6, 6))/ 100.0 'Germany ~9 Mio
			Case 1	game.maxAudiencePercentage =  6.50 + Float(RandRange( -4, 4))/ 100.0 'Germany ~5 Mio
			Case 2	game.maxAudiencePercentage =  3.80 + Float(RandRange( -3, 3))/ 100.0
			Case 3	game.maxAudiencePercentage =  3.60 + Float(RandRange( -3, 3))/ 100.0
			Case 4	game.maxAudiencePercentage =  2.25 + Float(RandRange( -2, 2))/ 100.0
			Case 5	game.maxAudiencePercentage =  3.45 + Float(RandRange( -2, 2))/ 100.0 'workers awake
			Case 6	game.maxAudiencePercentage =  3.25 + Float(RandRange( -2, 2))/ 100.0 'some go to work
			Case 7	game.maxAudiencePercentage =  4.45 + Float(RandRange( -3, 3))/ 100.0 'more awake
			Case 8	game.maxAudiencePercentage =  5.05 + Float(RandRange( -4, 4))/ 100.0
			Case 9	game.maxAudiencePercentage =  5.60 + Float(RandRange( -4, 4))/ 100.0
			Case 10	game.maxAudiencePercentage =  5.85 + Float(RandRange( -4, 4))/ 100.0
			Case 11	game.maxAudiencePercentage =  6.70 + Float(RandRange( -4, 4))/ 100.0
			Case 12	game.maxAudiencePercentage =  7.85 + Float(RandRange( -4, 4))/ 100.0
			Case 13	game.maxAudiencePercentage =  9.10 + Float(RandRange( -5, 5))/ 100.0
			Case 14	game.maxAudiencePercentage = 10.20 + Float(RandRange( -5, 5))/ 100.0
			Case 15	game.maxAudiencePercentage = 10.90 + Float(RandRange( -5, 5))/ 100.0
			Case 16	game.maxAudiencePercentage = 11.45 + Float(RandRange( -6, 6))/ 100.0
			Case 17	game.maxAudiencePercentage = 14.10 + Float(RandRange( -7, 7))/ 100.0 'people come home
			Case 18	game.maxAudiencePercentage = 22.95 + Float(RandRange( -8, 8))/ 100.0 'meal + worker coming home
			Case 19	game.maxAudiencePercentage = 33.45 + Float(RandRange(-10,10))/ 100.0
			Case 20	game.maxAudiencePercentage = 38.70 + Float(RandRange(-15,15))/ 100.0
			Case 21	game.maxAudiencePercentage = 37.60 + Float(RandRange(-15,15))/ 100.0
			Case 22	game.maxAudiencePercentage = 28.60 + Float(RandRange( -9, 9))/ 100.0 'bed time starts
			Case 23	game.maxAudiencePercentage = 18.80 + Float(RandRange( -7, 7))/ 100.0
		EndSelect
		game.maxAudiencePercentage :/ 100.0

		Return game.maxAudiencePercentage
	End Method

	Method getNextHour:Int()
		If Self.hour+1 > 24 Then Return Self.hour+1 - 24
		Return Self.hour + 1
	End Method

	Method IsGameLeader:Int()
		Return (Game.networkgame And Network.isServer) Or (Not Game.networkgame)
	End Method

	'Summary: Updates Time, Costs, States ...
	Method Update(deltaTime:Float=1.0)
		Self.minutesOfDayGone :+ (Float(speed) / 10.0)
		Self.timeSinceBegin	:+ (Float(speed) / 10.0)

		'time for news ?
		If IsGameLeader() And NewsAgency.NextEventTime < timeSinceBegin Then NewsAgency.AnnounceNewNews()

		'send state to clients
		If IsGameLeader() And self.networkgame and self.stateSyncTime < Millisecs()
			NetworkHelper.SendGameState()
			self.stateSyncTime = Millisecs() + self.stateSyncTimer
		endif

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
		Return _day+"."+GetLocale("DAY")+" ("+Self.GetDayName( Max(0,_day-1) Mod 7, 0)+ ")"
	End Method

	Method GetFormattedDayLong:String(_day:Int = -1)
		If _day < 0 Then _day = Self.day
		Return Self.GetDayName( Max(0,_day-1) Mod 7, 1)
	End Method

	Method GetWeekday:Int(_day:Int = -1)
		If _day < 0 Then _day = Self.day
		Return Max(0,_day-1) Mod 7
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

Type PacketTypes
	Global PlayerState:Byte				= 6					' Player Name, Position...
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

	Function getByID:TPlayer( playerID:Int = 0)
		For Local player:TPlayer = EachIn TPlayer.list
			If playerID = player.playerID Then Return player
		Next
		Return Null
	End Function

	Function Load:Tplayer(pnode:TxmlNode)
print "implement Load:Tplayer"
return null
rem
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
		Players[Player.playerID] = Player  '.player is player in root-scope
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

	Method IsAI:Int()
		'return self.playerKI <> null
		Return Self.figure.IsAI()
	End Method

	Function LoadAll()
		TPlayer.List.Clear()
		Players[1] = Null;Players[2] = Null;Players[3] = Null;Players[4] = Null;
		TPlayer.globalID = 1
		TFinancials.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.getChildren()
		For Local node:txmlNode = EachIn Children
			If NODE.getName() = "PLAYER" then TPlayer.Load(NODE)
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
	Function Create:TPlayer(Name:String, channelname:String = "", sprite:TGW_Sprites, x:Int, onFloor:Int = 13, dx:Int, pcolr:Int, pcolg:Int, pcolb:Int, ControlledByID:Int = 1, FigureName:String = "")
		Local Player:TPlayer = New TPlayer
		Player.Name = Name
		Player.playerID = globalID
		Player.color = TPlayerColor.Create(pcolr,pcolg,pcolb, TPlayer.globalID)
		Player.channelname = channelname
		Player.Figure = TFigures.Create(FigureName, sprite, x, onFloor, dx, ControlledByID)
		Player.Figure.ParentPlayer = Player
		If controlledByID = 0 And Game.playerID = 1 Then
			If TPlayer.globalID = 2
				Player.PlayerKI = KI.Create(Player.playerID, "res/ai/DefaultAIPlayer.lua")
			Else
				Player.PlayerKI = KI.Create(Player.playerID, "res/ai/test_base.lua")
			EndIf
		EndIf
		For Local i:Int = 0 To 6
			Player.finances[i] = TFinancials.Create(Player.playerID, 550000, 250000)
			Player.finances[i].revenue_before = 550000
			Player.finances[i].revenue_after  = 550000
		Next
		Player.ProgrammeCollection = TPlayerProgrammeCollection.Create(Player)
		Player.ProgrammePlan = TPlayerProgrammePlan.Create(Player)

		Player.Figure.Sprite = Assets.GetSprite("Player" + Player.playerID)
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
	Method RecolorFigure(PlayerColor:TPlayerColor = Null)
		If PlayerColor = Null Then PlayerColor = Self.color
		color.used	= 0
		color		= PlayerColor
		color.used	= playerID
		UpdateFigureBase(figurebase)
		'overwrite asset
		Assets.AddImageAsSprite( "gfx_building_sign"+String(playerID), ColorizeTImage(Assets.GetSprite("gfx_building_sign_base").getImage(), color.colR, color.colG, color.colB) )
	End Method

	'nothing up to now
	Method UpdateFinances:Int()
		For Local i:Int = 0 To 6
		Next
	End Method

	Method GetNewsAbonnement:int(genre:int)
		If genre > 5 Then Return 0 'max 6 categories 0-5
		return self.newsabonnements[genre]
	End Method

	Method SetNewsAbonnement(genre:Int, level:Int, sendToNetwork:Int = True)
		If level > Game.maxAbonnementLevel Then Return
		If genre > 5 Then Return 'max 6 categories 0-5
		if Self.newsabonnements[genre] <> level
			Self.newsabonnements[genre] = level
			If Game.networkgame And Network.IsConnected And sendToNetwork Then NetworkHelper.SendNewsSubscriptionChange(Game.playerID, genre, level)
		endif
	End Method

	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetAudiencePercentage:Float()
		If maxaudience > 0 And audience > 0
			Return Float(audience * 100) / Float(maxaudience)
		EndIf
		Return 0.0
	End Method

	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetRelativeAudiencePercentage:Float()
		If game.maxAudiencePercentage > 0
			Return Float(GetAudiencePercentage() / game.maxAudiencePercentage)
		EndIf
		Return 0.0
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
		Players[Game.playerID].SetCredit(amount)
	End Function

	'increases Credit
	Method SetCredit(amount:Int)
		Self.finances[Game.getWeekday()].money:+amount
		Self.finances[Game.getWeekday()].credit:+amount
		Self.CreditCurrent:+amount
	End Method

	'computes daily costs like station or newsagency fees for every player
	Function ComputeDailyCosts()
		Local playerID:Int = 1
		For Local Player:TPlayer = EachIn TPlayer.List
			'stationfees
			Player.finances[Game.getWeekday()].PayStationFees(StationMap.CalculateStationCosts(playerID))

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
					Player.finances[Game.getWeekday()].SellAds(Adblock.contract.calculatedProfit)
					AdBlock.RemoveOverheadAdblocks() 'removes Blocks which are more than needed (eg 3 of 2 to be shown Adblocks)
					'Print "should remove contract:"+adblock.contract.title
					TContractBlock.RemoveContractFromSuitcase(Adblock.contract)
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
							Player.finances[Game.getWeekday()].PayPenalty(contract.calculatedPenalty)
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
		Local block:TProgrammeBlock
		For Local Player:TPlayer = EachIn TPlayer.List
			block = Player.ProgrammePlan.GetActualProgrammeBlock()
			Player.audience = 0

			If block and block.programme and Player.maxaudience <> 0
				Player.audience = Floor(Player.maxaudience * block.Programme.ComputeAudienceQuote(Player.audience/Player.maxaudience) / 1000)*1000
				'maybe someone sold a station
				If recompute
					Local quote:TAudienceQuotes = TAudienceQuotes.GetAudienceOfDate(Player.playerID, Game.day, Game.GetActualHour(), Game.GetActualMinute())
					If quote <> Null
						quote.audience = Player.audience
						quote.audiencepercentage = Int(Floor(Player.audience * 1000 / Player.maxaudience))
					EndIf
				Else
					TAudienceQuotes.Create(block.Programme.title + " (" + GetLocale("BLOCK") + " " + (1 + Game.GetActualHour() - (block.sendhour - game.day*24)) + "/" + block.Programme.blocks, Int(Player.audience), Int(Floor(Player.audience * 1000 / Player.maxaudience)), Game.GetActualHour(), Game.GetActualMinute(), Game.day, Player.playerID)
				EndIf
				If block.sendHour - (game.day*24) + block.Programme.blocks <= Game.getNextHour()
					If Not recompute
						block.Programme.CutTopicality()
						block.Programme.ComputePrice()
					EndIf
				EndIf
			EndIf
		Next
	End Function

	'computes newsshow-audience
	Function ComputeNewsAudience()
		Local newsBlock:TNewsBlock
		For Local Player:TPlayer = EachIn TPlayer.List
			Player.audience = 0
			Local audience:Int = 0
			For Local i:Int = 1 To 3
				newsBlock = Player.ProgrammePlan.getActualNewsBlock(i)
				If newsBlock <> Null And Player.maxaudience <> 0
					audience :+ Floor(Player.maxaudience * NewsBlock.news.ComputeAudienceQuote(Player.audience/Player.maxaudience) / 1000)*1000
					If Player.playerID = 1 Print "Newsaudience for News: "+i+" - "+audience
				EndIf
			Next
			Player.audience= Ceil(audience / 3)
			TAudienceQuotes.Create("News: "+ Game.GetActualHour()+":00", Int(Player.audience), Int(Floor(Player.audience*1000/Player.maxaudience)),Game.GetActualHour(),Game.GetActualMinute(),Game.day, Player.playerID)
		Next
	End Function

	'nothing up to now
	Method Update:Int()
		''
	End Method

	'returns formatted value of actual money
	'gibt einen formatierten Wert des aktuellen Geldvermoegens zurueck
	Method GetFormattedMoney:String()
		Return functions.convertValue(String(Self.finances[Game.getWeekday()].money), 2, 0)
	End Method

	Method GetRawMoney:Int()
		Return Self.finances[Game.getWeekday()].money
	End Method

	'returns formatted value of actual credit
	Method GetFormattedCredit:String()
		Return functions.convertValue(String(Self.finances[Game.getWeekday()].credit), 2, 0)
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
	Field callerRevenue:Int			= 0
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



	Function Load:TFinancials(pnode:txmlNode, finance:TFinancials)
print "implement Load:TFinancials"
return null
rem
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
		finances.money		= startmoney
		finances.credit		= startcredit
		finances.playerID	= playerID
		finances.ListLink	= List.AddLast(finances)
		Return finances
	End Function

	'returns the the position in the array the actual game-day fits to
	Function GetDayOfWeek:Int(day:Int)
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
		If Players[ Self.playerID ].isAI() Then Players[ Self.playerID ].PlayerKI.CallOnMoneyChanged()
		If Self.playerID = Game.playerID Then Interface.BottomImgDirty = True
	End Method

	'refreshs stats about earned money from adspots
	Method SellAds(_money:Int)
		sold_ads	:+_money
		sold_total	:+_money
		money		:+_money
		ChangeMoney(_money)
	End Method

	'refreshs stats about earned money from sending ad powered shows or call-in
	Method earnCallerRevenue(_money:Int)
		Self.callerRevenue	:+_money
		Self.sold_total		:+_money
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
		DragAndDrop.pos.setXY(57+Assets.GetSprite("gfx_movie0").w*i, 297)
		DragAndDrop.w = Assets.GetSprite("gfx_movie0").w
		DragAndDrop.h = Assets.GetSprite("gfx_movie0").h
		If Not TArchiveProgrammeBlock.DragAndDropList Then TArchiveProgrammeBlock.DragAndDropList = CreateList()
		TArchiveProgrammeBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TArchiveProgrammeBlock.DragAndDropList
	Next

	'AdAgency: Contract DND-zones
	For i = 0 To Game.maxContractsAllowed-1
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.pos.setXY(550 + Assets.GetSprite("gfx_contracts_base").w * i, 87)
		DragAndDrop.w = Assets.GetSprite("gfx_contracts_base").w - 1
		DragAndDrop.h = Assets.GetSprite("gfx_contracts_base").h
		If Not TContractBlock.DragAndDropList Then TContractBlock.DragAndDropList = CreateList()
		TContractBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TContractBlock.DragAndDropList
	Next

	'left newsagency slots
	For i = 0 To 3
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.pos.setXY(35, 22 + i * Assets.getSprite("gfx_news_sheet0").h)
		DragAndDrop.w = Assets.getSprite("gfx_news_sheet0").w
		DragAndDrop.h = Assets.getSprite("gfx_news_sheet0").h
		If Not TNewsBlock.DragAndDropList Then TNewsBlock.DragAndDropList = CreateList()
		TNewsBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TNewsBlock.DragAndDropList
	Next

	For i = 0 To 2
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i+4
		DragAndDrop.pos.setXY( 445, 106 + i * Assets.getSprite("gfx_news_sheet0").h )
		DragAndDrop.w = Assets.getSprite("gfx_news_sheet0").w
		DragAndDrop.h = Assets.getSprite("gfx_news_sheet0").h
		If Not TNewsBlock.DragAndDropList Then TNewsBlock.DragAndDropList = CreateList()
		TNewsBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TNewsBlock.DragAndDropList
	Next

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

'an elevator, contains rules how to draw and functions when to move
Type TFloorRoute
	Field floornumber:Int
	Field call:Int
	Field who:Int =0

	Method Save()
		LoadSaveFile.xmlBeginNode("ROUTE")
		LoadSaveFile.xmlWrite("FLOORNUMBER",Self.floornumber)
		LoadSaveFile.xmlWrite("CALL",		Self.call)
		LoadSaveFile.xmlWrite("WHO",		Self.who)
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Load:TFloorRoute(loadfile:TStream)
		Local Route:TFloorRoute = New TFloorRoute
		Route.floornumber = ReadInt(loadfile:TStream)
		Route.call 		= ReadInt(loadfile:TStream)
		Route.who		= ReadInt(loadfile:TStream)
		ReadString(loadfile, 5) 'read |FLR|
		Return Route
	End Function

	Function Create:TFloorRoute(floornumber:Int, call:Int=0, who:Int=0, direction:Int=-1)
		Local FloorRoute:TFloorRoute = New TFloorRoute
		FloorRoute.floornumber = floornumber
		FloorRoute.call = call
		floorRoute.who = who
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
	Field waitAtFloorTime:Int	= 650 								'wait 650ms until moving to destination
	Field waitAtFloorTimeForRoomboard:Int = 7500 					'wait 7500ms then throw out
	Field spriteDoor:TAnimSprites
	Field spriteInner:TGW_Sprites
	Field passenger:TFigures = Null
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

	Field Network_LastSynchronize:Int	= 0
	Field Network_SynchronizeTimer:Int	= 2000 						'every 2000ms

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
		Local obj:TElevator=New TElevator
		obj.spriteDoor	= TAnimSprites.Create(Assets.GetSprite("gfx_building_Fahrstuhl_oeffnend"), 0, 0, 0, 0, 8, 150)
		obj.spriteDoor.insertAnimation("default", TAnimation.Create([ [0,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("closed", TAnimation.Create([ [0,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("open", TAnimation.Create([ [7,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("opendoor", TAnimation.Create([ [0,70],[1,70],[2,70],[3,70],[4,70],[5,70],[6,70],[7,70] ], 0, 1) )
		obj.spriteDoor.insertAnimation("closedoor", TAnimation.Create([ [7,70],[6,70],[5,70],[4,70],[3,70],[2,70],[1,70],[0,70] ], 0, 1) )
		obj.spriteInner	= Assets.GetSprite("gfx_building_Fahrstuhl_Innen")  'gfx_building_elevator_inner
		obj.Parent		= Parent
		obj.Pos.SetY(Parent.GetFloorY(obj.onFloor) - obj.spriteInner.h)
		Return obj
	End Function

	'nice-modus ? -- wenn spieler aus 1. etage fahrstuhl von 12. etage holt - und zwischendrin
	'einer von 8. in den 6. fahren will - mitnehmen - dafuer muss der Fahrstuhl aber wissen,
	'das er vom 8. in den 6. will - momentan gibt es nur die information "fahr in den 8."
	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:Int, First:Int = False, fromNetwork:Int = False)
		If ElevatorCallIsDuplicate(floornumber, who) Then Return 0	'if duplicate - don't add
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
		If Not fromNetwork And Game.networkgame
			'Print "send route to net"
			Network_SendRouteChange(floornumber, call, who, First)
		EndIf
	End Method

	Method GetFloorRoute:Int()
		If Not FloorRouteList.IsEmpty()
			Local tmpfloor:TFloorRoute = TFloorRoute(FloorRouteList.First())
			If onFloor = tmpfloor.floornumber
				Local fig:TFigures = TFigures.getByID( tmpfloor.who )
				If fig <> Null And Not fig.isAtElevator() Then fig.calledElevator = False
				FloorRouteList.RemoveFirst
			EndIf
			Return tmpfloor.floornumber
		EndIf
		Return -1
	End Method

	Method CloseDoor()
		Self.spriteDoor.setCurrentAnimation("closedoor", True)
		open = 3

		If Game.networkgame Then Self.Network_SendSynchronize()
	End Method

	Method OpenDoor()
		Self.spriteDoor.setCurrentAnimation("opendoor", True)
		open = 2 'wird geoeffnet
		If passenger <> Null Then passenger.pos.setY( Building.GetFloorY(onFloor) - passenger.sprite.h )

		If Game.networkgame Then Self.Network_SendSynchronize()
	End Method



	Method Network_SendRouteChange(floornumber:Int, call:Int=0, who:Int, First:Int=False)
		Local obj:TNetworkObject = TNetworkObject.Create( NET_ELEVATORROUTECHANGE )
		obj.SetInt(1, call)
		obj.SetInt(2, floornumber)
		obj.SetInt(3, who)
		obj.SetInt(4, First)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method Network_ReceiveRouteChange( obj:TNetworkObject )
		Local call:Int			= obj.getInt(1)
		Local floornumber:Int	= obj.getInt(2)
		Local who:Int			= obj.getInt(3)
		Local first:Int			= obj.getInt(4)

		AddFloorRoute(floornumber, call, who, First, True)
		If First Then passenger = TFigures.getById( who )
	End Method



	Method Network_SendSynchronize()
		'only server sends packet
		If Not Network.isServer Then Return

		Local obj:TNetworkObject = TNetworkObject.Create( NET_ELEVATORSYNCHRONIZE )
		obj.setInt(1, upwards)
		obj.setFloat(2, pos.x)
		obj.setFloat(3, pos.y)
		obj.setInt(4, open)
		If passenger <> Null Then obj.setInt(5, passenger.id)
		obj.setInt(6, FloorRouteList.Count() )
		If FloorRouteList.Count() > 0
			Local floorString:String = ""
			For Local FloorRoute:TFloorRoute = EachIn FloorRouteList
				floorString:+ FloorRoute.call+"|"+FloorRoute.floornumber+"|"+FloorRoute.who+","
			Next
			obj.setString(7, floorString)
		EndIf
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
'		Network_LastSynchronize = MilliSecs() + Network_SynchronizeTimer
	End Method

	Method Network_ReceiveSynchronize( obj:TNetworkObject )
		upwards 				= obj.getInt(1)
		Pos.x					= obj.getFloat(2)
'		If passenger Then

		'only change y if difference is bigger than 10 pixels
		Local newPosY:Float		= obj.getFloat(3)
		If Abs(newPosY - pos.y) > 10 Then Pos.Y = newPosY

	'	open					= obj.getInt(4)
		Local passengerID:Int	= obj.getInt(5,-1)
		If passengerID > 0 Then passenger = TFigures.getByID( passengerID )

		Local floorCount:Int	= obj.getInt(6)
		Local floors:String[]	= obj.getString(7).split(",")
		'print "floorCount:"+floorCount + " floors:"+floors.length
		If floorCount > 0 And floorCount = floors.length-1 '-1 as there is a "," at the end of a string
			Self.FloorRouteList.clear() 'empty list
			For Local i:Int = 0 To floors.length -1 -1
				Local Floor:String[] = floors[i].split("|")
				If Floor.length = 3 Then AddFloorRoute(Int(Floor[1]), Int(Floor[0]), Int(Floor[2]), False, True)
			Next
		EndIf
	End Method

	Method SendToFloor(Floor:Int, figure:TFigures)
		passenger = figure
		If figure.id = Game.playerID Or (figure.IsAI() And Game.playerID = 1)
			AddFloorRoute(Floor, 0, figure.id, True, False)
		Else
			AddFloorRoute(Floor, 0, figure.id, True, True)
		EndIf
	End Method

	Method GetDoorCenter:Int()
		Return parent.pos.x + Pos.x + Self.spriteDoor.sprite.framew/2
	End Method

	Method IsInFrontOfDoor:Int(x:Int, y:Int=-1)
		Return x = GetDoorCenter()
	End Method

	Method DrawFloorDoors()
		Local locy:Int = 0

		'elevatorBG without image -> black
		SetColor 0,0,0
		DrawRect(Parent.pos.x + 360, Max(parent.pos.y, 10) , 44, 373)
		SetColor 255, 255, 255

		'elevatorbg
		spriteInner.Draw(Parent.pos.x + Pos.x, Parent.pos.y + Pos.y + 4)
		'figures in elevator
		If passenger <> Null Then passenger.Draw();passenger.alreadydrawn = 1


		For Local i:Int = 0 To 13
			locy = Parent.pos.y + Building.GetFloorY(i) - Self.spriteDoor.sprite.h
			If locy < 410 And locy > - 50 And i <> onFloor Then  Self.spriteDoor.Draw(Parent.pos.x + Pos.x, locy, "closed")
		Next
	End Method


	Method Update(deltaTime:Float=1.0)
		'the -1 is used for displace the object one pixel higher, so it has to reach the first pixel of the floor
		'until the function returns the new one, instead of positioning it directly on the floorground
		If Abs(Building.GetFloorY(Building.GetFloor(Parent.pos.y + Pos.y + spriteInner.h - 1)) - (Pos.y + spriteInner.h)) <= 1
			onFloor = Building.GetFloor(Parent.pos.y + Pos.y + spriteInner.h - 1)
		EndIf

		If spriteDoor.getCurrentAnimationName() = "opendoor"
			open = 2 'opening
			If spriteDoor.getCurrentAnimation().isFinished()
				If open = 2 And passenger <> Null
					passenger.calledElevator= False
					passenger.inElevator	= False
					passenger				= Null
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
		If (onFloor <> toFloor And open <> 0) And open <> 3 And waitAtFloorTimer <= MilliSecs()
			CloseDoor()
			Network_SendSynchronize()
		EndIf
		If (onFloor = toFloor) And open = 0 Then OpenDoor;waitAtFloorTimer = MilliSecs() + waitAtFloorTime

		'move figure who is in elevator
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.IsInElevator()
					Figure.pos.setY ( Building.Elevator.Pos.y + spriteInner.h) '+1 odd displacement
				Exit 'only one figure in elevator possible
			EndIf
		Next

		spriteDoor.Update(deltaTime)

		'wait some time?
		If (onFloor <> toFloor And open <> 0) Or (onFloor = toFloor)
			Local tmpFloor:Int 		= GetFloorRoute()
			If waitAtFloorTimer <= MilliSecs() And toFloor = onFloor
				If tmpfloor = onFloor	Then waitAtFloorTimer = MilliSecs() + waitAtFloorTime
				If tmpFloor <> -1		Then toFloor = tmpfloor
			EndIf
		EndIf

		'move elevator
		If onFloor <> toFloor
			If open = 0 And waitAtFloorTimer <= MilliSecs() 'elevator is closed, closing-animation stopped
				upwards = onfloor < toFloor
				If Not upwards
					Pos.y	= Min(Pos.y + deltaTime * speed, Building.GetFloorY(toFloor) - spriteInner.h)
				Else
					Pos.y	= Max(Pos.y - deltaTime * speed, Building.GetFloorY(toFloor) - spriteInner.h)
				EndIf
				If Pos.y + spriteInner.h < Building.GetFloorY(13) Then Pos.y = Building.GetFloorY(13) - spriteInner.h
				If Pos.y + spriteInner.h > Building.GetFloorY( 0) Then Pos.y = Building.GetFloorY(0) - spriteInner.h
			EndIf
		EndIf
		TRooms.UpdateDoorToolTips(deltaTime)

'		if Network_LastSynchronize < Millisecs() then Network_SendSynchronize()
	End Method

	'needs to be restructured (some test-lines within)
	Method Draw()
		Local locy:Int = 0
		SetBlend MASKBLEND
		TRooms.DrawDoors()

		If (onFloor <> toFloor And open <> 0)Or(onFloor = toFloor)
'			For Local Figure:TFigures = EachIn TFigures.List
'				If Figure.isOnFloor() and Figure.IsAtElevator() Then Figure.Draw() ;Figure.alreadydrawn = 0 'not alreadydrawn for openinganimation
'			Next
		EndIf

		'draw missing door (where elevator is)
		spriteDoor.Draw(Parent.pos.x + pos.x, Parent.pos.y + Parent.GetFloorY(onFloor) - 50)

		For Local i:Int = 0 To 13
			locy = Parent.pos.y + Building.GetFloorY(i) - Self.spriteDoor.sprite.h - 8
			If locy < 410 And locy > -50
				SetColor 200,0,0
				DrawRect(Parent.pos.x+Pos.x-4 + 10 + (onFloor)*2, locy + 3, 2,2)
				SetColor 255,255,255
			EndIf
		Next

		'elevator sign - indicator
		For Local FloorRoute:TFloorRoute = EachIn FloorRouteList
			locy = Parent.pos.y + Building.GetFloorY(floorroute.floornumber) - spriteInner.h + 23
			'elevator is called to this floor					'elevator will stop there (destination)
			If	 floorroute.call Then SetColor 200,220,20 	Else SetColor 100,220,20
			DrawRect(Parent.pos.x + Pos.x + 44, locy, 3,3)
			SetColor 255,255,255
		Next

		SetBlend ALPHABLEND
		Local routepos:Int = 0
		For Local FloorRoute:TFloorRoute = EachIn FloorRouteList
			If floorroute.call = 0
				FontManager.basefont.draw(FloorRoute.floornumber + " 'senden' " + TFigures.GetByID(FloorRoute.who).Name, 650, 50 + routepos * 15)
			Else
				FontManager.basefont.draw(FloorRoute.floornumber + " 'holen' " + TFigures.GetByID(FloorRoute.who).Name, 650, 50 + routepos * 15)
			EndIf
			routepos:+1
		Next
	End Method

End Type

Include "gamefunctions_figures.bmx"

'Summary: Type of building, area around it and doors,...
Type TBuilding Extends TRenderable
	Field pos:TPosition = TPosition.Create(20,0)
	Field borderright:Int 			= 127 + 40 + 429
	Field borderleft:Int			= 127 + 40
	Field skycolor:Float = 0
	Field ufo_normal:TAnimSprites = TAnimSprites.Create(Assets.GetSprite("gfx_building_ufo"), 0, 100, 0,0, 9, 100)
	Field ufo_beaming:TAnimSprites = TAnimSprites.Create(Assets.GetSprite("gfx_building_ufo2"), 0, 100, 0,0, 9, 100)
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
	Field Clouds:TAnimSprites[5]
	Field CloudCount:Int = 5
	Field TimeColor:Double
	Field DezimalTime:Float
	Field ActHour:Int
	Field ItemsDrawnToBackground:Byte = 0
	Field gfx_bgBuildings:TGW_Sprites[6]
	Field gfx_building:TGW_Sprites
	Field gfx_buildingEntrance:TGW_Sprites
	Field gfx_buildingRoof:TGW_Sprites
	Field gfx_buildingWall:TGW_Sprites

	Global StarsX:Int[60]
	Global StarsY:Int[60]
	Global StarsC:Int[60]
	Global List:TList = CreateList()

	Function Create:TBuilding()
		Local Building:TBuilding = New TBuilding
		Building.gfx_building	= Assets.GetSprite("gfx_building")
		Building.pos.y			= 0 - Building.gfx_building.h + 5 * 73 + 20	' 20 = interfacetop, 373 = raumhoehe
		Building.Elevator		= TElevator.Create(Building)

		Building.Moon_curKubSplineX.GetDataInt([1, 2, 3, 4, 5], [-50, -50, 400, 850, 850])
		Building.Moon_curKubSplineY.GetDataInt([1, 2, 3, 4, 5], [650, 200, 20 , 200, 650])
		Building.ufo_curKubSplineX.GetDataInt([1, 2, 3, 4, 5], [-150, 200+RandMax(400), 200+RandMax(200), 65, -50])
		Building.ufo_curKubSplineY.GetDataInt([1, 2, 3, 4, 5], [-50+RandMax(200), 100+RandMax(200) , 200+RandMax(300), 330,150])
		For Local i:Int = 0 To Building.CloudCount-1
			Building.Clouds[i] = TAnimSprites.Create(Assets.GetSprite("building_clouds"), - 200 * i + (i + 1) * RandMax(400), - 30 + RandMax(30), 2 + RandRange(0, 6),0,1,0)
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
			StarsX[j] = 10+RandMax(150)
			StarsY[j] = 20+RandMax(273)
			StarsC[j] = 50+RandMax(150)
		Next
		For Local j:Int = 30 To 59
			StarsX[j] = 650+RandMax(150)
			StarsY[j] = 20+RandMax(273)
			StarsC[j] = 50+RandMax(150)
		Next
		If Not List Then List = CreateList()
		List.AddLast(Building)
		SortList List
		Return Building
	End Function

	Method Update(deltaTime:Float=1.0)
		pos.y = Clamp(pos.y, - 637, 88)
		UpdateBackground(deltaTime)
	End Method

	Method DrawItemsToBackground:Int()
		Local locy13:Int	= GetFloorY(13)
		Local locy3:Int		= GetFloorY(3)
		Local locy0:Int		= GetFloorY(0)
		Local locy12:Int	= GetFloorY(12)
		If Not ItemsDrawnToBackground
			Local Pix:TPixmap = LockImage(gfx_building.parent.image)
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
			UnlockImage(gfx_building.parent.image)
			Pix = Null
			ItemsDrawnToBackground = True
		EndIf
	End Method

	Method Draw(tweenValue:Float=1.0)
		TProfiler.Enter("Draw-Building-Background")
		DrawBackground(tweenValue)
		TProfiler.Leave("Draw-Building-Background")

		If Building.GetFloor(Players[Game.playerID].Figure.pos.y) <= 4
			SetColor Int(205 * timecolor) + 150, Int(205 * timecolor) + 150, Int(205 * timecolor) + 150
			Building.gfx_buildingEntrance.Draw(pos.x, pos.y + 1024 - Building.gfx_buildingEntrance.h - 3)
			Building.gfx_buildingWall.Draw(pos.x + 127 + 507, pos.y + 1024 - Building.gfx_buildingWall.h - 3)
		Else If Building.GetFloor(Players[Game.playerID].Figure.pos.y) >= 8
			SetColor 255, 255, 255
			Building.gfx_buildingRoof.Draw(pos.x + 127, pos.y - Building.gfx_buildingRoof.h)
		EndIf
		SetBlend MASKBLEND
		elevator.DrawFloorDoors()

		Assets.GetSprite("gfx_building").draw(pos.x + 127, pos.y)

		SetBlend ALPHABLEND
		Elevator.Draw()

		For Local Figure:TFigures = EachIn TFigures.List
			If Not Figure.alreadydrawn Then Figure.Draw()
		Next


		SetBlend MASKBLEND
		Local pack:TGW_Spritepack = Assets.getSpritePack("gfx_hochhauspack")
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + borderright - 130, pos.y + GetFloorY(9), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + borderleft + 150, pos.y + GetFloorY(13), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + borderright - 110, pos.y + GetFloorY(9), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + borderleft + 150, pos.y + GetFloorY(6), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze6").Draw(pos.x + borderright - 85, pos.y + GetFloorY(8), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze3a").Draw(pos.x + borderleft + 60, pos.y + GetFloorY(1), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze3a").Draw(pos.x + borderleft + 60, pos.y + GetFloorY(12), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze3b").Draw(pos.x + borderleft + 150, pos.y + GetFloorY(12), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + borderright - 70, pos.y + GetFloorY(3), - 1, 1)
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + borderright - 75, pos.y + GetFloorY(12), - 1, 1)
		SetBlend ALPHABLEND
		TRooms.DrawDoorToolTips()
	End Method

	Method UpdateBackground(deltaTime:Float)
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
					ufo_beaming.pos.y = -15 + 105 + 0.25 * (pos.y + Assets.GetSprite("gfx_building").h - Assets.GetSprite("gfx_building_BG_Ebene3L").h)
					ufo_beaming.Update(deltatime)
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
		For Local i:Int = 0 To Building.CloudCount-1
			Clouds[i].Update(deltaTime)
		Next
	End Method

	'Summary: Draws background of the mainscreen (stars, buildings, moon...)
	Method DrawBackground(tweenValue:Float=1.0)
		Local BuildingHeight:Int = gfx_building.h + 56
		SetBlend MASKBLEND
		DezimalTime = Float(Game.GetActualHour()) + Float(Game.GetActualMinute())*10/6/100
		If DezimalTime > 18 Or DezimalTime < 7
			If DezimalTime > 18 And DezimalTime < 19 Then SetAlpha (19 - Dezimaltime)
			If DezimalTime > 6 And DezimalTime < 8 Then SetAlpha (4 - Dezimaltime / 2)

			'stars
			Local minute:Float = Game.GetActualMinute()
			For Local i:Int = 0 To 59
				If i Mod 6 = 0 And minute Mod 2 = 0 Then StarsC[i] = RandMax( Max(1,StarsC[i]) )
				SetColor StarsC[i] , StarsC[i] , StarsC[i]
				Plot(StarsX[i] , StarsY[i] )
			Next

			SetColor 255, 255, 255
			DezimalTime:+3
			If DezimalTime > 24 Then DezimalTime:-24
			SetBlend ALPHABLEND
			Assets.GetSprite("gfx_BG_moon").DrawInViewPort(Moon_curKubSplineX.ValueInt(Moon_tPos), pos.y + Moon_curKubSplineY.ValueInt(Moon_tPos), 0, Game.day Mod 12)
		EndIf
		SetColor Int(205 * timecolor) + 50, Int(205 * timecolor) + 50, Int(205 * timecolor) + 50

		For Local i:Int = 0 To Building.CloudCount - 1
			Clouds[i].Draw(Null, Clouds[i].pos.Y + 0.2*pos.y) 'parallax
		Next

		If DezimalTime > 18 Or DezimalTime < 7
			SetBlend MASKBLEND
			SetAlpha 1.0

			If Game.day Mod 2 = 0 Then
				'compute and draw Ufo
				If (Floor(ufo_curKubSplineX.ValueInt(ufo_tPos)) = 65 And Floor(ufo_curKubSplineY.ValueInt(ufo_tPos)) = 330) Or (ufo_beaming.getCurrentAnimation().getCurrentFramePos() > 1 And ufo_beaming.getCurrentAnimation().getCurrentFramePos() <= ufo_beaming.getCurrentAnimation().getFrameCount())
					ufo_beaming.Draw()
				Else
					Assets.GetSprite("gfx_building_ufo").DrawInViewPort(ufo_curKubSplineX.ValueInt(ufo_tPos), - 330 - 15 + 105 + 0.25 * (pos.y + Assets.GetSprite("gfx_building").h - Assets.GetSprite("gfx_building_BG_Ebene3L").h) + ufo_curKubSplineY.ValueInt(ufo_tPos), 0, ufo_normal.GetCurrentFrame())
				EndIf
			EndIf
		EndIf

		SetBlend MASKBLEND

		SetColor Int(225 * timecolor) + 30, Int(225 * timecolor) + 30, Int(225 * timecolor) + 30
		gfx_bgBuildings[0].Draw(pos.x		, 105 + 0.25 * (pos.y + 5 + BuildingHeight - gfx_bgBuildings[0].h), - 1, 0)
		gfx_bgBuildings[1].Draw(pos.x + 634	, 105 + 0.25 * (pos.y + 5 + BuildingHeight - gfx_bgBuildings[1].h), - 1, 0)

		SetColor Int(215 * timecolor) + 40, Int(215 * timecolor) + 40, Int(215 * timecolor) + 40
		gfx_bgBuildings[2].Draw(pos.x		, 120 + 0.35 * (pos.y 		+ BuildingHeight - gfx_bgBuildings[2].h), - 1, 0)
		gfx_bgBuildings[3].Draw(pos.x + 636	, 120 + 0.35 * (pos.y + 60	+ BuildingHeight - gfx_bgBuildings[3].h), - 1, 0)

		SetColor Int(205 * timecolor) + 50, Int(205 * timecolor) + 50, Int(205 * timecolor) + 50
		gfx_bgBuildings[4].Draw(pos.x		, 45 + 0.80 * (pos.y + BuildingHeight - gfx_bgBuildings[4].h), - 1, 0)
		gfx_bgBuildings[5].Draw(pos.x + 634	, 45 + 0.80 * (pos.y + BuildingHeight - gfx_bgBuildings[5].h), - 1, 0)

		SetColor 255, 255, 255
		SetBlend ALPHABLEND
	End Method

	Method CenterToFloor:Int(floornumber:Int)
		pos.y = ((13 - (floornumber)) * 73) - 115
	End Method

	'Summary: returns y which has to be added to building.y, so its the difference
	Method GetFloorY:Int(floornumber:Int)
		Return (66 + 1 + (13 - floornumber) * 73)		  ' +10 = interface
	End Method

	Method GetFloor:Int(_y:Int)
		Return Clamp(14 - Ceil((_y - pos.y) / 73),0,13)
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
				If parentnews.parent <> Null
					If parentnews.episode < parentnews.parent.episodecount
						news = TNews.GetNextInNewsChain(parentnews)
					EndIf
				End If
				If parentnews.episodecount > 0 And parentnews.parent = Null
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
			If Players[i].newsabonnements[news.genre] > 0
				TNewsBlock.Create("",0,-100, i, 60*(3-Players[i].newsabonnements[news.genre]), news)
				If Game.networkgame Then NetworkHelper.SendNews(i, news)
			EndIf
		Next
	End Method

	Method AnnounceNewNews()
		Local news:TNews = Null
		If RandRange(1,10)>3 Then news = GetNextFromChain()  '70% alte Nachrichten holen, 30% neue Kette/Singlenews
		If news = Null Then news = TNews.GetRandomNews() 'TNews.GetRandomChainParent()
		If news <> Null Then
			news.happenedday = Game.day
			news.happenedhour = Game.GetActualHour()
			news.happenedminute = Game.GetActualMinute()
			Local NoOneSubscribed:Byte= True
			For Local i:Int = 1 To 4
				If Players[i].newsabonnements[news.genre] > 0
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
		If RandRange(0,10) = 1 Then
			NextEventTime = Game.timeSinceBegin + RandRange(5,50) 'between 5 and 50 minutes until next news
		Else
			NextEventTime = Game.timeSinceBegin + RandRange(90,200) 'between 60 and 250 minutes until next news
		EndIf
	End Method
End Type



Function UpdateBote:Int(ListLink:TLink, deltaTime:Float=1.0) 'SpecialTime = 1 if letter in hand
	Local Figure:TFigures = TFigures(ListLink.value())
	Figure.FigureMovement(deltaTime)
	Figure.FigureAnimation(deltaTime)
	If figure.inRoom <> Null
		If figure.specialTime = 0
			figure.specialTime = MilliSecs()+2000+RandMax(50)*100
		Else
			If figure.specialTime < MilliSecs()
				Figure.specialTime = 0
				Local room:TRooms
				Repeat
					room = TRooms.GetRandomReachableRoom()
				Until room <> Figure.inRoom
				If Figure.LastSpecialTime = 0
					Figure.LastSpecialTime=1
					Figure.sprite = Assets.GetSpritePack("figures").GetSprite("BotePost")
				Else
					Figure.sprite = Assets.GetSpritePack("figures").GetSprite("BoteLeer")
					Figure.LastSpecialTime=0
				EndIf
				'Print "Bote: war in Raum -> neues Ziel gesucht"
				Figure.ChangeTarget(room.Pos.x + 13, Building.pos.y + Building.GetFloorY(room.Pos.y) - figure.sprite.h)
			EndIf
		EndIf
	EndIf
	If figure.inRoom = Null And figure.clickedToRoom = Null And figure.dx = 0 And Not (Figure.IsAtElevator() Or Figure.IsInElevator()) 'not moving but not in/at elevator
		Local room:TRooms = TRooms.GetRandomReachableRoom()
		'Print "Bote: steht rum -> neues Ziel gesucht"
		Figure.ChangeTarget(room.Pos.x + 13, Building.pos.y + Building.GetFloorY(room.Pos.y) - figure.sprite.h)
	EndIf
End Function

Function UpdateHausmeister:Int(ListLink:TLink, deltaTime:Float=1.0)
	Local Figure:TFigures = TFigures(ListLink.value())
	If figure.WaitTime < MilliSecs()
		figure.WaitTime = MilliSecs() + 15000
		'Print "zu lange auf fahrstuhl gewartet"
		Figure.ChangeTarget(RandRange(150, 580), Building.pos.y + Building.GetFloorY(figure.GetFloor()) - figure.sprite.h)
	EndIf
	If Int(Figure.pos.x) = Int(Figure.target.x) And Not Figure.IsInElevator() And figure.GetFloor() = Building.GetFloor(figure.target.y)
		Local zufall:Int = RandRange(0, 100)
		Local zufallx:Int = RandRange(150, 580)
		If figure.LastSpecialTime < MilliSecs()
			figure.LastSpecialTime = MilliSecs() + 1500
			'no left-right-left-right movement for just some pixels
			Repeat
				zufallx = RandRange(150, 580)
			Until Abs(figure.pos.x - zufallx) > 15

			If zufall > 85 And Not figure.IsAtElevator()
				Local sendToFloor:Int = figure.GetFloor() + 1
				If sendToFloor > 13 Then sendToFloor = 0
				Figure.ChangeTarget(zufallx, Building.pos.y + Building.GetFloorY(sendToFloor) - figure.sprite.h)
				figure.WaitTime = MilliSecs() + 15000
			Else If zufall <= 85 And Not figure.isAtElevator()
				Figure.ChangeTarget(zufallx, Building.pos.y + Building.GetFloorY(figure.GetFloor()) - figure.sprite.h)
			EndIf
		EndIf
	EndIf
	Figure.FigureMovement(deltaTime)

	If MilliSecs() - Figure.NextAnimTimer >= 0
		If Figure.AnimPos < 8 Or Figure.AnimPos > 10 Then Figure.AnimPos = Figure.AnimPos + 1
		Figure.NextAnimTimer = MilliSecs() + Figure.NextAnimTime
		If Figure.dx = 0
			If Figure.HasToChangeFloor() And Not Figure.IsInElevator() And Figure.IsAtElevator()
				Figure.AnimPos = 10
			Else
				If MilliSecs() - Figure.NextTwinkerTimer > 0
					Figure.AnimPos = 9
					Figure.NextTwinkerTimer = MilliSecs() + RandMax(1000) + 1500
				Else
					Figure.AnimPos = 8
				EndIf
			EndIf
		EndIf
	EndIf
	If Floor(Figure.pos.x) <= 200 Then Figure.pos.setX(200);Figure.target.setX(200)
	If Floor(Figure.pos.x) >= 579 Then Figure.pos.setX(579);Figure.target.setX(579)

	If Figure.specialTime < MilliSecs()
		If Figure.dx > 0 Then If Figure.AnimPos > 3
			Figure.NextAnimTime = Figure.BackupAnimTime
			Figure.AnimPos = 0
			If RandRange(0,40) > 30 Then Figure.specialTime = MilliSecs()+RandRange(1000,3000);Figure.AnimPos = 11
		EndIf
		If Figure.dx < 0 Then If Figure.AnimPos > 7
			Figure.NextAnimTime = Figure.BackupAnimTime
			Figure.AnimPos = 3
			If RandRange(0,40) > 30 Then Figure.specialTime = MilliSecs()+RandRange(1000,3000);Figure.AnimPos = 13
		EndIf
	EndIf
	If Figure.dx > 0
		If Figure.AnimPos >= 11
			Figure.NextAnimTime = 300
			Figure.pos.x		:-deltaTime * Figure.dx
			If Figure.specialTime < MilliSecs()
				Figure.NextAnimTime = Figure.BackupAnimTime
				Figure.AnimPos = 0
			EndIf
			If Figure.AnimPos >= 13 Then Figure.AnimPos = 11
		EndIf
	Else If Figure.dx < 0
		If Figure.AnimPos >= 13
			Figure.NextAnimTime = 300
			Figure.pos.x		:- deltaTime * Figure.dx
			If Figure.specialTime < MilliSecs()
				Figure.NextAnimTime = Figure.BackupAnimTime
				Figure.AnimPos = 4
			EndIf
			If Figure.AnimPos >= 15 Or Figure.AnimPos = 0 Then Figure.AnimPos = 13
		EndIf
		If (Figure.AnimPos > 7 And Figure.AnimPos < 13) Or Figure.AnimPos < 4 Then Figure.AnimPos = 4
	EndIf
End Function



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
Global Players:TPlayer[5]
Local playerSpeed:Int = 90
Players[1] = TPlayer.Create(Game.username, Game.userchannelname, Assets.GetSpritePack("figures").GetSpriteByID(0), 500, 1, playerSpeed, 247, 50, 50, 1, "Player 1")
Players[2] = TPlayer.Create("Alfie", "SunTV", Assets.GetSpritePack("figures").GetSpriteByID(0), 450, 3, playerSpeed, 245, 220, 0, 0, "Player 2")
Players[3] = TPlayer.Create("Seidi", "FunTV", Assets.GetSpritePack("figures").GetSpriteByID(0), 250, 8, playerSpeed, 40, 210, 0, 0, "Player 3")
Players[4] = TPlayer.Create("Sandra", "RatTV", Assets.GetSpritePack("figures").GetSpriteByID(0), 480, 13, playerSpeed, 0, 110, 245, 0, "Player 4")

Global tempfigur:TFigures = TFigures.Create("Hausmeister", Assets.GetSprite("figure_Hausmeister"), 210, 2,60,0)
tempfigur.FrameWidth	= 12 'overwriting
tempfigur.target.setX(550)
tempfigur.updatefunc_ = UpdateHausmeister
Global figure_HausmeisterID:Int = tempfigur.id

tempfigur = TFigures.Create("Bote1", Assets.GetSpritePack("figures").GetSprite("BoteLeer"), 210, 3, 65, 0)
tempfigur.FrameWidth = 12
tempfigur.target.setX(550)
tempfigur.updatefunc_	= UpdateBote
Global figure_Bote1ID:Int = tempfigur.id
tempfigur				= TFigures.Create("Bote2", Assets.GetSpritePack("figures").GetSprite("BotePost"), 410, 8,-65,0)
tempfigur.FrameWidth = 12
tempfigur.target.setX(550)
tempfigur.updatefunc_	= UpdateBote
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

Global MainMenuButton_Start:TGUIButton		= TGUIButton.Create(600, 300, 120, 0, 1, 1, GetLocale("MENU_SOLO_GAME"), "MainMenu", FontManager.GetFont("Default", 11, BOLDFONT))
Global MainMenuButton_Network:TGUIButton	= TGUIButton.Create(600, 348, 120, 0, 1, 1, GetLocale("MENU_NETWORKGAME"), "MainMenu", FontManager.GetFont("Default", 11, BOLDFONT))
Global MainMenuButton_Online:TGUIButton		= TGUIButton.Create(600, 396, 120, 0, 1, 1, GetLocale("MENU_ONLINEGAME"), "MainMenu", FontManager.GetFont("Default", 11, BOLDFONT))

Global NetgameLobbyButton_Join:TGUIButton	= TGUIButton.Create(600, 300, 120, 0, 1, 1, GetLocale("MENU_JOIN"), "NetGameLobby", FontManager.GetFont("Default", 11, BOLDFONT))
Global NetgameLobbyButton_Create:TGUIButton	= TGUIButton.Create(600, 345, 120, 0, 1, 1, GetLocale("MENU_CREATE_GAME"), "NetGameLobby", FontManager.GetFont("Default", 11, BOLDFONT))
Global NetgameLobbyButton_Back:TGUIButton	= TGUIButton.Create(600, 390, 120, 0, 1, 1, GetLocale("MENU_BACK"), "NetGameLobby", FontManager.GetFont("Default", 11, BOLDFONT))
Global NetgameLobby_gamelist:TGUIList		= TGUIList.Create(25 + 3, 300, 440, 175, 1, 100, "NetGameLobby")
NetgameLobby_gamelist.SetFilter("HOSTGAME")
NetgameLobby_gamelist.GUIbackground = Null

Global GameSettingsBG:TGUIBackgroundBox = TGUIBackgroundBox.Create(20, 20, 760, 260, 00, "Spieleinstellung", "GameSettings", FontManager.GetFont("Default", 16, BOLDFONT))

Global GameSettingsOkButton_Announce:TGUIOkButton = TGUIOkButton.Create(420, 234, 0, 1, "Spieleinstellungen abgeschlossen", "GameSettings")
Global GameSettingsGameTitle:TGuiInput = TGUIinput.Create(50, 230, 320, 1, Game.title, 32, "GameSettings")
Global GameSettingsButton_Start:TGUIButton = TGUIButton.Create(600, 300, 120, 0, 1, 1, GetLocale("MENU_START_GAME"), "GameSettings", FontManager.GetFont("Default", 11, BOLDFONT))
Global GameSettingsButton_Back:TGUIButton = TGUIButton.Create(600, 345, 120, 0, 1, 1, GetLocale("MENU_BACK"), "GameSettings", FontManager.GetFont("Default", 11, BOLDFONT))
Global GameSettings_Chat:TGUIChat = TGuiChat.Create(20 + 3, 300, 450, 250, 1, 200, "GameSettings")
Global InGame_Chat:TGUIChat = TGuiChat.Create(20, 10, 250, 200, 1, 200, "InGame")
GameSettings_Chat._UpdateFunc_	= UpdateChat_GameSettings
InGame_Chat._UpdateFunc_ 		= UpdateChat_InGame

GUIManager.DefaultFont = FontManager.GetFont("Default", 12, BOLDFONT)

GameSettings_Chat.GUIInput.TextDisplacement.setXY(5,2)
'#Region  :configuring "InGame_Chat"-object
InGame_Chat.clickable			= 0
InGame_Chat.nobackground		= True
InGame_Chat.fadeout				= True
InGame_Chat.GUIInput.pos.setXY( 290, 385)
InGame_Chat.GuiInput.width		= gfx_GuiPack.GetSprite("Chat_IngameOverlay").w
InGame_Chat.GuiInput.maxTextWidth = gfx_GuiPack.GetSprite("Chat_IngameOverlay").w - 20
InGame_Chat.GUIInput.InputImage	= gfx_GuiPack.GetSprite("Chat_IngameOverlay")
InGame_Chat.useFont				= FontManager.GetFont("Default", 11)
InGame_Chat.guichatgfx			= 0

InGame_Chat.colR= 255; InGame_Chat.colG= 255; InGame_Chat.colB= 255
InGame_Chat.GuiInput.color.adjust(255,255,255, True)
'#End Region
'#End Region

Function UpdateChat_GameSettings();		UpdateChat(GameSettings_Chat);		End Function
Function UpdateChat_InGame();			UpdateChat(InGame_Chat);			End Function

Function UpdateChat(UseChat:TGuiChat)
	If Usechat.EnterPressed = 2
		If Usechat.GUIInput.Value$ <> ""
			Usechat.AddEntry("",Usechat.GUIInput.Value$, Game.playerID,"", "", MilliSecs())
			If Game.networkgame Then NetworkHelper.SendChatMessage(Usechat.GUIInput.Value$)
			'NetPlayer.SendNetMessage(UDPClientIP, NetworkPlayername$, "CHAT", GUIChat_NWGL_Chat.GUIInput.value$)
			Usechat.GUIInput.Value$ = ""
			Network.ChatSpamTime = MilliSecs() + 500
			GUIManager.setActive(0)
		EndIf
'		if GUIManager.isActive(Usechat.GUIInput.uid) then GUIManager.setActive(0)
	EndIf
	If Usechat.TeamNames[1] = ""
		For Local i:Int = 0 To 4
			If Players[i] <> Null
				Usechat.TeamNames[i] = Players[i].Name
				Usechat.TeamColors[i] = Players[i].color
			Else
				Usechat.TeamNames[i] = "unknown"
				Usechat.TeamColors[i] = TPlayerColor.Create(255,255,255)
			EndIf
		Next
	EndIf
End Function

'Doubleclick-function for NetGameLobby_GameList
Function NetGameLobbyDoubleClick:Int(sender:Object)
	NetgameLobbyButton_Join.Clicked	= 1
	GameSettingsButton_Start.disable()

	If Network.ConnectToServer( HostIp(NetgameLobby_gamelist.GetEntryIP()), NetgameLobby_gamelist.GetEntryPort() )
		Game.gamestate = GAMESTATE_SETTINGSMENU
		GameSettingsGameTitle.Value = NetgameLobby_gamelist.GetEntryTitle()
	EndIf
End Function
NetgameLobby_gamelist.SetDoubleClickFunc(NetGameLobbyDoubleClick)


Include "gamefunctions_network.bmx"
'Network.init(game.userfallbackip)

For Local i:Int = 0 To 7
	If i < 4
		MenuPlayerNames[i]	= TGUIinput.Create(50 + 190 * i, 65, 130, 1, Players[i + 1].Name, 16, "GameSettings", FontManager.GetFont("Default", 12)).SetOverlayImage(Assets.GetSprite("gfx_gui_overlay_player"))
		MenuPlayerNames[i].TextDisplacement.setX(3)
		MenuChannelNames[i]	= TGUIinput.Create(50 + 190 * i, 180, 130, 1, Players[i + 1].channelname, 16, "GameSettings", FontManager.GetFont("Default", 12)).SetOverlayImage(Assets.GetSprite("gfx_gui_overlay_tvchannel"))
		MenuChannelNames[i].TextDisplacement.setX(3)
	End If
	If i Mod 2 = 0
		MenuFigureArrows[i] = TGUIArrowButton.Create(25+ 20+190*Ceil(i/2)+10, 125,0,0,1,0,"GameSettings", 0)
	Else
		MenuFigureArrows[i] = TGUIArrowButton.Create(25+140+190*Ceil(i/2)+10, 125,2,0,1,0,"GameSettings", 1)
	EndIf
Next

'#Region : Button (News and ProgrammePlanner)-Creation
For Local i:Int = 0 To 4
	TNewsbuttons.Create(0,3, GetLocale("NEWS_TECHNICS_MEDIA"), i, 20,194,0)
	TNewsbuttons.Create(1,0, GetLocale("NEWS_POLITICS_ECONOMY"), i, 69,194,1)
	TNewsbuttons.Create(2,1, GetLocale("NEWS_SHOWBIZ"), i, 20,247,2)
	TNewsbuttons.Create(3,2, GetLocale("NEWS_SPORT"), i, 69,247,3)
	TNewsbuttons.Create(4,4, GetLocale("NEWS_CURRENTAFFAIRS"),i, 118,247,4)
Next
TPPbuttons.Create(Assets.GetSprite("btn_options"), GetLocale("PLANNER_OPTIONS"), 672, 40 + 2 * 56, 2)
TPPbuttons.Create(Assets.GetSprite("btn_programme"), GetLocale("PLANNER_PROGRAMME"), 672, 40 + 1 * 56, 1)
TPPbuttons.Create(Assets.GetSprite("btn_ads"), GetLocale("PLANNER_ADS"), 672, 40 + 0 * 56, 0)
TPPbuttons.Create(Assets.GetSprite("btn_financials"), GetLocale("PLANNER_FINANCES"), 672, 40 + 3 * 56, 3)
TPPbuttons.Create(Assets.GetSprite("btn_image"), GetLocale("PLANNER_IMAGE"), 672, 40 + 4 * 56, 4)
TPPbuttons.Create(Assets.GetSprite("btn_news"), GetLocale("PLANNER_MESSAGES"), 672, 40 + 5 * 56, 5)
'#End Region

CreateDropZones()
Global Database:TDatabase = TDatabase.Create(); Database.Load(Game.userdb) 'load all movies, news, series and ad-contracts

StationMap.AddStation(310, 260, 1, Players[1].maxaudience)
StationMap.AddStation(310, 260, 2, Players[2].maxaudience)
StationMap.AddStation(310, 260, 3, Players[3].maxaudience)
StationMap.AddStation(310, 260, 4, Players[4].maxaudience)

HideMouse()
SetColor 255,255,255

For Local i:Int = 0 To 9
	TContractBlock.Create(TContract.GetRandomContract(), i, 0)
	TMovieAgencyBlocks.Create(TProgramme.GetRandomMovie(),i,0)
	If i > 0 And i < 9 Then TAuctionProgrammeBlocks.Create(TProgramme.GetRandomMovieWithMinPrice(200000),i)
Next

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
	If game.gamestate = GAMESTATE_NETWORKLOBBY
		Game.networkgame = 1
	EndIf
End Function

Function Menu_NetworkLobby()
	NetgameLobby_gamelist.RemoveOldEntries(NetgameLobby_gamelist.uId, 11000)
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
					Local responseArray:String[] = responsestring.split("|")
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
		Game.gamestate	= GAMESTATE_SETTINGSMENU
		Network.localFallbackIP = HostIp(game.userfallbackip)
		Network.StartServer()
		Network.ConnectToLocalServer()
		Network.client.playerID	= 1
	EndIf
	If NetgameLobbyButton_Join.GetClicks() > 0 Then
		GameSettingsButton_Start.disable()
		Network.isServer				= False

		If Network.ConnectToServer( HostIp(NetgameLobby_gamelist.GetEntryIP()), NetgameLobby_gamelist.GetEntryPort() )
			Game.gamestate = GAMESTATE_SETTINGSMENU
			GameSettingsGameTitle.Value = NetgameLobby_gamelist.GetEntryTitle()
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

	'disable/enable announcement on lan/online
	Network.announceEnabled = GameSettingsOkButton_Announce.crossed

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
	EndIf

	For Local i:Int = 0 To 3
		If Not MenuPlayerNames[i].on Then Players[i+1].Name = MenuPlayerNames[i].Value
		If Not MenuChannelNames[i].on Then Players[i+1].channelname = MenuChannelNames[i].Value
		If Game.networkgame Or Game.playerID=1 Then
			If Game.gamestate <> GAMESTATE_STARTMULTIPLAYER And Players[i+1].Figure.ControlledByID = Game.playerID Or (Players[i+1].Figure.ControlledByID = 0 And Game.playerID=1)
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
			If Not Init_Complete Then Init_All() ;Init_Complete = True		'check if rooms/colors/... are initiated
			Game.gamestate = GAMESTATE_RUNNING
		Else
			GameSettingsOkButton_Announce.crossed = False
			Interface.ShowChannel = Game.playerID

			Game.gamestate = GAMESTATE_STARTMULTIPLAYER
		EndIf
		'Begin Game - create Events
		EventManager.registerEvent(TEventOnTime.Create("Game.OnMinute", game.minute))
		EventManager.registerEvent(TEventOnTime.Create("Game.OnHour", game.hour))
		EventManager.registerEvent(TEventOnTime.Create("Game.OnDay", game.day))
	EndIf
	If GameSettingsButton_Back.GetClicks() > 0 Then
		If Game.networkgame
			If Game.networkgame Then Network.DisconnectFromServer()
			Game.playerID = 1
			Game.gamestate = GAMESTATE_NETWORKLOBBY
			GameSettingsOkButton_Announce.crossed = False
		Else
			Game.gamestate = GAMESTATE_MAINMENU
		EndIf
	EndIf

	'clicks on color rect
	Local i:Int = 0
	For Local locobject:TPlayerColor = EachIn TPlayerColor.List
		If locobject.used = 0
			If MOUSEMANAGER.IsHit(1)
				If functions.IsIn(MouseX(), MouseY(), 26 + 40 + i * 10, 92 + 68, 7, 9) And (Players[1].Figure.ControlledByID = Game.playerID Or (Players[1].Figure.ControlledByID = 0 And Game.playerID = 1)) Then modifiedPlayers=True;Players[1].RecolorFigure(locobject)
				If functions.IsIn(MouseX(), MouseY(), 216 + 40 + i * 10, 92 + 68, 7, 9) And (Players[2].Figure.ControlledByID = Game.playerID Or (Players[2].Figure.ControlledByID = 0 And Game.playerID = 1)) Then modifiedPlayers=True;Players[2].RecolorFigure(locobject)
				If functions.IsIn(MouseX(), MouseY(), 406 + 40 + i * 10, 92 + 68, 7, 9) And (Players[3].Figure.ControlledByID = Game.playerID Or (Players[3].Figure.ControlledByID = 0 And Game.playerID = 1)) Then modifiedPlayers=True;Players[3].RecolorFigure(locobject)
				If functions.IsIn(MouseX(), MouseY(), 596 + 40 + i * 10, 92 + 68, 7, 9) And (Players[4].Figure.ControlledByID = Game.playerID Or (Players[4].Figure.ControlledByID = 0 And Game.playerID = 1)) Then modifiedPlayers=True;Players[4].RecolorFigure(locobject)
			EndIf
			i:+1
		EndIf
	Next

	'left right arrows to change figure base
	For Local i:Int = 0 To 7
		If ChangesAllowed[Ceil(i/2)]
			If MenuFigureArrows[i].GetClicks() > 0
				If i Mod 2  = 0 Then Players[1+Ceil(i/2)].UpdateFigureBase(Players[Ceil(1+i/2)].figurebase -1)
				If i Mod 2 <> 0 Then Players[1+Ceil(i/2)].UpdateFigureBase(Players[Ceil(1+i/2)].figurebase +1)
				modifiedPlayers = True
			EndIf
		EndIf
	Next

	If Game.networkgame = 1
		If modifiedPlayers
			NetworkHelper.SendPlayerDetails()
			PlayerDetailsTimer = MilliSecs()
		EndIf
		If MilliSecs() >= PlayerDetailsTimer + 1000
			NetworkHelper.SendPlayerDetails()
			PlayerDetailsTimer = MilliSecs()
		EndIf
	EndIf


End Function

Global MenuPreviewPicTimer:Int = 0
Global MenuPreviewPicTime:Int = 4000
Global MenuPreviewPic:TGW_Sprites = Null
Function Menu_Main_Draw()
	If RandRange(0,10) = 10 Then GCCollect()
	SetColor 190,220,240
	SetAlpha 0.5
	DrawRect(0,0,App.settings.width,App.settings.Height)
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
	DrawRect(0,0,App.settings.width,App.settings.height)
	SetAlpha 1.0
	SetColor 255,255,255
	GUIManager.Draw("NetGameLobby")
	If Not Game.onlinegame Then
		FontManager.GetFont("Default",16, BOLDFONT).drawstyled(GetLocale("MENU_NETWORKGAME")+": "+GetLocale("MENU_AVAIABLE_GAMES"), 36,277,20,20,150, 1)
	Else
		FontManager.GetFont("Default",16, BOLDFONT).drawstyled(GetLocale("MENU_ONLINEGAME")+": "+GetLocale("MENU_AVAIABLE_GAMES"), 36,277,20,20,150, 1)
	EndIf

	If Game.cursorstate = 0 DrawImage(gfx_mousecursor, MouseX()-7, MouseY(),0)
	If Game.cursorstate = 1 DrawImage(gfx_mousecursor, MouseX()-10, MouseY()-10,1)
End Function

Function Menu_GameSettings_Draw()
	SetColor 190,220,240
	SetAlpha 0.5
	DrawRect(0,0,App.settings.width,App.settings.height)
	SetAlpha 1.0
	SetColor 255,255,255

	' Local ChangesAllowed:Byte[4]
	If Not Game.networkgame
		GameSettingsBG.value = GetLocale("MENU_SOLO_GAME")
		GameSettings_Chat._visible = False
	Else
		GameSettings_Chat._visible = True
		If Not Game.onlinegame Then
			GameSettingsBG.value = GetLocale("MENU_NETWORKGAME")
		Else
			GameSettingsBG.value = GetLocale("MENU_ONLINEGAME")
		EndIf
	EndIf
	GUIManager.Draw("GameSettings",0, 0,9)

	For Local i:Int = 0 To 3
		SetColor 50,50,50
		DrawRect(60 + i*190, 90, 110,110)
		If Game.networkgame Or Game.playerID=1 Then
			If Game.gamestate <> GAMESTATE_STARTMULTIPLAYER And Players[i+1].Figure.ControlledByID = Game.playerID Or (Players[i+1].Figure.ControlledByID = 0 And Game.playerID=1)
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


	Local i:Int =0
	For Local locobject:TPlayerColor = EachIn TPlayerColor.List
		If locobject.used = 0
			SetColor locobject.colR, locobject.colG, locobject.colB
			DrawRect(26 + 40 + i * 10, 92 + 68, 9, 9)
			DrawRect(216 + 40 + i * 10, 92 + 68, 9, 9)
			DrawRect(406 + 40 + i * 10, 92 + 68, 9, 9)
			DrawRect(596 + 40 + i * 10, 92 + 68, 9, 9)
			i:+1
		EndIf
	Next
	SetColor 255,255,255

	Players[1].Figure.Sprite.Draw(25 + 90 - Players[1].Figure.Sprite.framew / 2, 159 - Players[1].Figure.Sprite.h, 8)
	Players[2].Figure.Sprite.Draw(215 + 90 - Players[2].Figure.Sprite.framew / 2, 159 - Players[2].Figure.Sprite.h, 8)
	Players[3].Figure.Sprite.Draw(405 + 90 - Players[3].Figure.Sprite.framew / 2, 159 - Players[3].Figure.Sprite.h, 8)
	Players[4].Figure.Sprite.Draw(595 + 90 - Players[4].Figure.Sprite.framew / 2, 159 - Players[4].Figure.Sprite.h, 8)

	GUIManager.Draw("GameSettings",0, 10)
	If Game.cursorstate = 0 DrawImage(gfx_mousecursor, MouseX()-7, MouseY(),0)
	If Game.cursorstate = 1 DrawImage(gfx_mousecursor, MouseX()-10, MouseY()-10,1)

	If Game.gamestate = GAMESTATE_STARTMULTIPLAYER
		SetColor 180,180,200
		SetAlpha 0.5
		DrawRect 200,200,400,200
		SetAlpha 1.0
		SetColor 0,0,0
		FontManager.basefont.draw("Synchronisiere Startbedingungen...", 220,220)
		FontManager.basefont.draw("Starte Netzwerkspiel...", 220,240)

		'master should spread startprogramme around
		If Game.isGameLeader()
			For Local playerids:Int = 1 To 4
				Local ProgrammeArray:TProgramme[Game.startMovieAmount + Game.startSeriesAmount + 1]
				SeedRnd(MilliSecs())
				Local i:Int = 0
				For i = 0 To Game.startMovieAmount-1
					ProgrammeArray[i] = TProgramme.GetRandomMovie(playerids)
				Next
				'give series to each player
				For i = Game.startMovieAmount To Game.startMovieAmount + Game.startSeriesAmount-1
					ProgrammeArray[i] = TProgramme.GetRandomSerie(playerids)
				Next
				'give 1 call in
				ProgrammeArray[Game.startMovieAmount + Game.startSeriesAmount] = TProgramme.GetRandomProgrammeByGenre(20)
				NetworkHelper.SendProgrammesToPlayer(playerids, ProgrammeArray)

				Local ContractArray:TContract[]
				For Local j:Int = 0 To Game.startAdAmount-1
					ContractArray		= ContractArray[..ContractArray.length+1]
					ContractArray[j]	= TContract.GetRandomContract()
				Next
				NetworkHelper.SendContractsToPlayer(playerids, ContractArray)
				Print "sent data for player: "+playerids

				'add to local collections
				For local programme:TProgramme = eachin programmeArray
					if programme then Players[ playerids ].ProgrammeCollection.AddProgramme( programme )
				Next
				For local contract:TContract = eachin contractArray
					if contract then Players[ playerids ].ProgrammeCollection.AddContract( contract )
				Next



			Next
			NetworkHelper.SendGameReady(Game.playerID)
		EndIf

		Local start:Int = MilliSecs()
		Repeat
			SetColor 180,180,200
			SetAlpha 1.0
			DrawRect 200,200,400,200
			SetAlpha 1.0
			SetColor 0,0,0
			FontManager.basefont.draw("Synchronisiere Startbedingungen...", 220,220)
			FontManager.basefont.draw("Starte Netzwerkspiel...", 220,240)
			FontManager.basefont.draw("Player 1..."+Players[1].networkstate+" MovieListCount: "+Players[1].ProgrammeCollection.MovieList.Count(), 220,260)
			FontManager.basefont.draw("Player 2..."+Players[2].networkstate+" MovieListCount: "+Players[2].ProgrammeCollection.MovieList.Count(), 220,280)
			FontManager.basefont.draw("Player 3..."+Players[3].networkstate+" MovieListCount: "+Players[3].ProgrammeCollection.MovieList.Count(), 220,300)
			FontManager.basefont.draw("Player 4..."+Players[4].networkstate+" MovieListCount: "+Players[4].ProgrammeCollection.MovieList.Count(), 220,320)
			If Not Game.networkgameready = 1 Then FontManager.basefont.draw("not ready!!", 220,360)
			Flip
			Network.Update()
			If MilliSecs() - start > 5000 Then game.gamestate = GAMESTATE_SETTINGSMENU
		Until Game.networkgameready = 1 Or game.gamestate <> GAMESTATE_STARTMULTIPLAYER

		If Game.networkgameready
			If Not Init_Complete Then Init_All() ;Init_Complete = True		'check if rooms/colors/... are initiated
			Game.networkgameready = 1
			Game.gamestate = GAMESTATE_RUNNING
			GameSettingsOkButton_Announce.crossed = False
			Players[Game.playerID].networkstate=1
			Game.gamestate = GAMESTATE_RUNNING
			Print "STARTED THE GAME ..."
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

Game.gamestate = GAMESTATE_MAINMENU
Function UpdateMenu(deltaTime:Float=1.0)
	'	App.Timer.Update(0)
	If Game.networkgame then Network.Update()
	Select Game.gamestate
		Case GAMESTATE_MAINMENU
			Menu_Main()
		Case GAMESTATE_NETWORKLOBBY
			Menu_NetworkLobby()
		Case GAMESTATE_SETTINGSMENU, GAMESTATE_STARTMULTIPLAYER
			Menu_GameSettings()
	EndSelect

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


	Select game.gamestate
		Case GAMESTATE_SETTINGSMENU, GAMESTATE_STARTMULTIPLAYER
			DrawImage(gfx_startscreen_logosmall, 540, 480)
		Default
			If LogoCurrY > LogoTargetY Then LogoCurrY:+- 30.0 * App.Timer.getDeltaTime() Else LogoCurrY = LogoTargetY
			DrawImage(gfx_startscreen_logo, 400 - ImageWidth(gfx_startscreen_logo) / 2, LogoCurrY)
	EndSelect
	SetColor 0, 0, 0

	SetColor 255,255,255
	FontManager.GetFont("Default",11, ITALICFONT).drawBlock(versionstring, 10,575, 500,20,0,75,75,140)
	FontManager.GetFont("Default",11, ITALICFONT).drawBlock(copyrightstring, 10,585, 500,20,0,60,60,120)

	Select Game.gamestate
		Case GAMESTATE_MAINMENU
			Menu_Main_Draw()
		Case GAMESTATE_NETWORKLOBBY
			Menu_NetworkLobby_Draw()
		Case GAMESTATE_SETTINGSMENU, GAMESTATE_STARTMULTIPLAYER
			Menu_GameSettings_Draw()
	EndSelect
End Function

Function Init_Creation()
	Local lastblocks:Int = 0
	'Local lastprogramme:TProgrammeBlock = New TProgrammeBlock
	For Local i:Int = 0 To 5
		TMovieAgencyBlocks.Create(TProgramme.GetRandomSerie(),20+i,0)
	Next

	'create random programmes and so on
	TFigures.GetByID(figure_HausmeisterID).updatefunc_ = Null
	If Not Game.networkgame Then
		For Local playerids:Int = 1 To 4
			SeedRnd(MilliSecs())
			Local i:Int = 0
			For i = 0 To Game.startMovieAmount-1
				Players[playerids].ProgrammeCollection.AddProgramme(TProgramme.GetRandomMovie(playerids))
			Next
			'give series to each player
			For i = Game.startMovieAmount To Game.startMovieAmount + Game.startSeriesAmount-1
				Players[playerids].ProgrammeCollection.AddProgramme(TProgramme.GetRandomSerie(playerids))
			Next
			'give 1 call in
			Players[playerids].ProgrammeCollection.AddProgramme(TProgramme.GetRandomProgrammeByGenre(20))


			Players[playerids].ProgrammeCollection.AddContract(TContract.GetRandomContract(),playerids)
			Players[playerids].ProgrammeCollection.AddContract(TContract.GetRandomContract(),playerids)
			Players[playerids].ProgrammeCollection.AddContract(TContract.GetRandomContract(),playerids)
		Next
		TFigures.GetByID(figure_HausmeisterID).updatefunc_ = UpdateHausmeister
	EndIf
			'abonnement for each newsgroup = 1
	For Local playerids:Int = 1 To 4
		For Local i:Int = 0 To 4
			Players[playerids].SetNewsAbonnement(i, 1)
		Next
	Next

	'creation of blocks for players rooms
	For Local playerids:Int = 1 To 4
		lastblocks = 0
		TAdBlock.Create(67 + Assets.GetSprite("pp_programmeblock1").w, 17 + 0 * Assets.GetSprite("pp_adblock1").h, playerids, 1)
		TAdBlock.Create(67 + Assets.GetSprite("pp_programmeblock1").w, 17 + 1 * Assets.GetSprite("pp_adblock1").h, playerids, 2)
		TAdBlock.Create(67 + Assets.GetSprite("pp_programmeblock1").w, 17 + 2 * Assets.GetSprite("pp_adblock1").h, playerids, 3)
		Local lastprogramme:TProgrammeBlock
		lastprogramme = TProgrammeBlock.Create(67, 17 + 0 * Assets.GetSprite("pp_programmeblock1").h, 0, playerids, 1)
		lastblocks :+ lastprogramme.programme.blocks
		lastprogramme = TProgrammeBlock.Create(67, 17 + lastblocks * Assets.GetSprite("pp_programmeblock1").h, 0, playerids, 2)
		lastblocks :+ lastprogramme.programme.blocks
		lastprogramme = TProgrammeBlock.Create(67, 17 + lastblocks * Assets.GetSprite("pp_programmeblock1").h, 0, playerids, 3)
	Next
End Function

Function Init_Colorization()
	'colorize the images
	Assets.AddImageAsSprite("gfx_financials_barren0", Assets.GetSprite("gfx_officepack_financials_barren").GetColorizedImage(200, 200, 200) )
	Assets.AddImageAsSprite("gfx_building_sign0", Assets.GetSprite("gfx_building_sign_base").GetColorizedImage(200,200,200) )
	Assets.AddImageAsSprite("gfx_elevator_sign0", Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage(200,200,200) )
	Assets.AddImageAsSprite("gfx_elevator_sign_dragged0", Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage(200, 200, 200) )
	Assets.AddImageAsSprite("gfx_interface_channelbuttons0", Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage(100,100,100), Assets.GetSprite("gfx_building_sign_base").animcount )
	Assets.AddImageAsSprite("gfx_interface_channelbuttons5", Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage(100,100,100), Assets.GetSprite("gfx_building_sign_base").animcount )

	'colorizing for every player and inputvalues (player and channelname) to players variables
	For Local i:Int = 1 To 4
		Players[i].Name					= MenuPlayerNames[i-1].Value
		Players[i].channelname			= MenuChannelNames[i-1].Value
		Assets.AddImageAsSprite("gfx_financials_barren"+i, Assets.GetSprite("gfx_officepack_financials_barren").GetColorizedImage(Players[i].color.colR, Players[i].color.colG, Players[i].color.colB) )
		Assets.AddImageAsSprite("gfx_building_sign"+i, Assets.GetSprite("gfx_building_sign_base").GetColorizedImage(Players[i].color.colR, Players[i].color.colG, Players[i].color.colB) )
		Assets.AddImageAsSprite("gfx_elevator_sign"+i, Assets.GetSprite("gfx_elevator_sign_base").GetColorizedImage( Players[i].color.colR, Players[i].color.colG, Players[i].color.colB) )
		Assets.AddImageAsSprite("gfx_elevator_sign_dragged"+i, Assets.GetSprite("gfx_elevator_sign_dragged_base").GetColorizedImage(Players[i].color.colR, Players[i].color.colG, Players[i].color.colB) )
		Assets.AddImageAsSprite("gfx_interface_channelbuttons"+i,   Assets.GetSprite("gfx_interface_channelbuttons_off").GetColorizedImage(Players[i].color.colR, Players[i].color.colG, Players[i].color.colB),Assets.GetSprite("gfx_interface_channelbuttons_off").animcount )
		Assets.AddImageAsSprite("gfx_interface_channelbuttons"+(i+5), Assets.GetSprite("gfx_interface_channelbuttons_on").GetColorizedImage(Players[i].color.colR, Players[i].color.colG, Players[i].color.colB),Assets.GetSprite("gfx_interface_channelbuttons_on").animcount )
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
	TRooms.DrawDoorsOnBackground() 		'draws the door-sprites on the building-sprite
	PrintDebug ("  Building.DrawItemsToBackground()", "drawing plants and lights on the building-sprite", DEBUG_START)
	Building.DrawItemsToBackground()  	'draws plants and lights which are behind the figures
	PrintDebug ("Init_All()", "complete", DEBUG_START)
End Function


'ingame update
Function UpdateMain(deltaTime:Float = 1.0)
	TError.UpdateErrors()
	Game.cursorstate = 0
	If Players[Game.playerID].Figure.inRoom <> Null Then Players[Game.playerID].Figure.inRoom.Update(0)

	'ingamechat
	'	If Game.networkgame
	'		If KEYWRAPPER.pressedKey(KEY_ENTER) And GUIManager.getActive() <> InGame_Chat.GUIINPUT.uId And Network.ChatSpamTime < MilliSecs()
	If KEYMANAGER.IsHit(KEY_ENTER)
		If Not GUIManager.isActive(InGame_Chat.GUIINPUT.uId)
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
		If KEYMANAGER.IsHit(KEY_W) Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("adagency", 0)
		If KEYMANAGER.IsHit(KEY_A) Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("archive", Game.playerID)
		If KEYMANAGER.IsHit(KEY_B) Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("betty", 0)
		If KEYMANAGER.IsHit(KEY_F) Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("movieagency", 0)
		If KEYMANAGER.IsHit(KEY_O) Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("office", Game.playerID)
		If KEYMANAGER.IsHit(KEY_C) Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("chief", Game.playerID)
		If KEYMANAGER.IsHit(KEY_N) Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("news", Game.playerID)
		If KEYMANAGER.IsHit(KEY_R) Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("roomboard", -1)
		If KEYMANAGER.IsHit(KEY_D) Players[Game.playerID].maxaudience = Stationmap.einwohner
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
		If KEYMANAGER.IsDown(KEY_UP) Game.speed:+0.05
		If KEYMANAGER.IsDown(KEY_DOWN) Game.speed:-0.05;If Game.speed < 0 Then Game.speed = 0
	EndIf
	'#EndRegion

	If Players[Game.playerID].Figure.inRoom = Null
		If MOUSEMANAGER.IsDown(1)
			If functions.IsIn(MouseX(), MouseY(), 20, 10, 760, 373)
				Players[Game.playerID].Figure.ChangeTarget(MouseX(), MouseY())
			EndIf
			MOUSEMANAGER.resetKey(1)
		EndIf
	EndIf
	'66 = 13th floor height, 2 floors normal = 1*73, 50 = roof
	If Players[Game.playerID].Figure.inRoom = Null Then Building.pos.y =  1 * 66 + 1 * 73 + 50 - Players[Game.playerID].Figure.pos.y  'working for player as center
	Fader.Update(deltaTime)

	Game.Update(deltaTime)
	Interface.Update(deltaTime)
	If Players[Game.playerID].Figure.inRoom = Null Then Building.Update(deltaTime)
	Building.Elevator.Update(deltaTime)
	TFigures.UpdateAll(deltaTime)

	If KEYMANAGER.IsHit(KEY_ESCAPE) Then ExitGame = 1
	If KEYMANAGER.IsHit(KEY_F12) Then App.prepareScreenshot = 1
	If Game.networkgame Then Network.Update()
End Function

'inGame
Function DrawMain(tweenValue:Float=1.0)
	If Players[Game.playerID].Figure.inRoom = Null
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
		Players[Game.playerID].Figure.inRoom.Draw()		'draw the room
		Players[Game.playerID].Figure.inRoom.Update(1) 	'update room-actions
		TProfiler.Leave("Draw-Room")
	EndIf

	Fader.Draw()
	TProfiler.Enter("Draw-Interface")
	Interface.Draw()
	TProfiler.Leave("Draw-Interface")

	FontManager.baseFont.draw( "Netstate:" + Players[Game.playerID].networkstate + " Speed:" + Int(Game.speed * 100), 0, 0)

	If Game.DebugInfos
		SetColor 0,0,0
		DrawRect(10,15,100,100)
		SetColor 255, 255, 255
		If App.settings.directx = -1 Then FontManager.baseFont.draw("Mode: OpenGL", 15,50)
		If App.settings.directx = 0  Then FontManager.baseFont.draw("Mode: BufferedOpenGL", 15,50)
		If App.settings.directx = 1  Then FontManager.baseFont.draw("Mode: DirectX 7", 15, 50)
		If App.settings.directx = 2  Then FontManager.baseFont.draw("Mode: DirectX 9", 15,50)

		If Game.networkgame
			GUIManager.Draw("InGame") 'draw ingamechat
			SetAlpha 0.4
			SetColor 0, 0, 0
			DrawRect(660, 483,115,120)
			SetAlpha 1.0
			SetColor 255,255,255
'			FontManager.basefont.draw(Network.stream.UDPSpeedString(), 662,490)
			For Local i:Int = 0 To 3
				If Players[i + 1].Figure.inRoom <> Null
					FontManager.basefont.draw("Player " + (i + 1) + ": " + Players[i + 1].Figure.inRoom.Name, 662, 510 + i * 11)
				Else
					If Players[i + 1].Figure.IsInElevator()
						FontManager.basefont.draw("Player " + (i + 1) + ": InElevator", 662, 510 + i * 11)
					Else If Players[i + 1].Figure.IsAtElevator()
						FontManager.basefont.draw("Player " + (i + 1) + ":			AtElevator", 662, 510 + i * 11)
					Else
						FontManager.basefont.draw("Player " + (i + 1) + ": Building", 662, 510 + i * 11)
					EndIf
				EndIf
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
			If evt._trigger = "game.onminute" And Self.Player.isAI() Then Self.Player.PlayerKI.CallOnMinute()
			If evt._trigger = "game.onday" And Self.Player.isAI() Then Self.Player.PlayerKI.CallOnDayBegins()
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

			'begin of a programme
			If minute = 5
				TPlayer.ComputeAudience()
			'call-in shows/quiz - generate income
			ElseIf minute = 54
				For Local player:TPlayer = EachIn TPlayer.list
					Local block:TProgrammeBlock = player.ProgrammePlan.GetActualProgrammeBlock()
					If block<>Null And block.programme.genre = GENRE_CALLINSHOW
						Local revenue:Int = player.audience * Rnd(0.05, 0.2)
						player.finances[Game.getWeekday()].earnCallerRevenue(revenue)
					EndIf
				Next
			'ads
			ElseIf minute = 55
				TPlayer.ComputeAds()
			ElseIf minute = 0
				Game.calculateMaxAudiencePercentage(hour)
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
				TRooms.ResetRoomSigns()
				For Local i:Int = 1 To 4
					For Local NewsBlock:TNewsBlock = EachIn Players[i].ProgrammePlan.NewsBlocks
						If Game.day - Newsblock.news.happenedday >= 2
							Players[Newsblock.owner].ProgrammePlan.RemoveNewsBlock(NewsBlock)
						EndIf
					Next
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
			If KEYMANAGER.IsHit(KEY_ESCAPE) ExitGame = 1				'ESC pressed, exit game
			If KEYMANAGER.Ishit(Key_F1) And Players[1].isAI() Then Players[1].PlayerKI.reloadScript()
			If KEYMANAGER.Ishit(Key_F2) And Players[2].isAI() Then Players[2].PlayerKI.reloadScript()
			If KEYMANAGER.Ishit(Key_F3) And Players[3].isAI() Then Players[3].PlayerKI.reloadScript()
			If KEYMANAGER.Ishit(Key_F4) And Players[4].isAI() Then Players[4].PlayerKI.reloadScript()

			If KEYMANAGER.Ishit(Key_F5) Then NewsAgency.AnnounceNewNews()


			KEYMANAGER.changeStatus()
			If Game.gamestate = 0
				UpdateMain(App.Timer.getDeltaTime())
			Else
				UpdateMenu(App.Timer.getDeltaTime())
			EndIf
			If RandRange(0,20) = 20 Then GCCollect()

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
			TProfiler.Enter("Draw")
			If Game.gamestate = 0
				DrawMain()
			Else
				DrawMenu()
			EndIf
			FontManager.baseFont.Draw("FPS:"+App.Timer.fps + " UPS:" + Int(App.Timer.ups), 150,0)
			FontManager.baseFont.Draw("dTime "+Int(1000*App.Timer.loopTime)+"ms", 275,0)
			if game.networkgame then FontManager.baseFont.Draw("ping "+Int(Network.client.latency)+"ms", 375,0)
			If App.prepareScreenshot = 1 Then DrawImage(gfx_startscreen_logosmall, App.settings.width - ImageWidth(gfx_startscreen_logosmall) - 10, 10)

			TProfiler.Enter("Draw-Flip")
				Flip App.limitFrames
			TProfiler.Leave("Draw-Flip")

			If App.prepareScreenshot = 1 Then SaveScreenshot();App.prepareScreenshot = 0
			TProfiler.Leave("Draw")
		EndIf
	End Method
End Type



'__________________________________________
'events
For Local i:Int = 1 To 4
	If Players[i].figure.isAI()
		EventManager.registerListener( "Game.OnMinute",	TEventListenerPlayer.Create(Players[i]) )
		EventManager.registerListener( "Game.OnDay", 	TEventListenerPlayer.Create(Players[i]) )
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
	KEYWRAPPER.allowKey(13, KEYWRAP_ALLOW_BOTH, 400, 200)
	Repeat
		App.Timer.loop()
		'process events not directly triggered
		'process "onMinute" etc. -> App.OnUpdate, App.OnDraw ...
		EventManager.update()
	Until AppTerminate() Or ExitGame = 1
	If Game.networkgame Then Network.DisconnectFromServer()
EndIf 'not exit game


OnEnd( EndHook )
Function EndHook()
	Print "Dumping profile information -> Profiler.txt ."
	TProfiler.DumpLog("Profiler.txt")

End Function
