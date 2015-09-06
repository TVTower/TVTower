
'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame Extends TGameBase {_exposeToLua="selected"}
	Global _initDone:Int = False
	Global _eventListeners:TLink[]
	Global StartTipWindow:TGUIModalWindow


	Method New()
	End Method


	Function GetInstance:TGame()
		if not _instance
			_instance = new TGame
		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		'==== ATTENTION =====
		'NEVER store _instance somewhere without paying attention
		'to this "whacky hack"
		elseif not TGame(_instance)
			'now the new collection is the instance
			local oldInstance:TGameBase = _instance
			_instance = New TGame
			THelper.TakeOverObjectValues(oldInstance, _instance)
		endif
		return TGame(_instance)
	End Function


	'(re)set everything to default values
	Method Initialize()
		Super.Initialize()

		'do this every new game - or like now,just on a new "app start"?
		SetRandomizerBase( Time.MillisecsLong() )


		'=== GAME TIME / SPEED ===
		'MAD TV speed:
		'slow:   10 game minutes = 30 seconds  -> 1 sec = 20 ingameseconds
		'middle: 10 game minutes = 20 seconds  -> 1 sec = 30 ingameseconds
		'fast:   10 game minutes = 10 seconds  -> 1 sec = 60 ingameseconds
		'set basic game speed to 30 gameseconds per second
		GetWorldTime().SetTimeFactor(30.0)


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		GameEvents.UnRegisterEventListeners()


		'=== register event listeners
		GameEvents.RegisterEventListeners()
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnStart", onStart) ]
		'handle begin of savegameloading (prepare first game if needed)
		_eventListeners :+ [ EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad) ]
		'handle savegame loading (assign sprites)
		_eventListeners :+ [ EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("SaveGame.OnBeginSave", onSaveGameBeginSave) ]
	End Method



	'=== START A GAME ===

	Method StartNewGame:Int()
		'print "====== START NEW GAME ======"
		'Preparation is done before (to share data in network games)
		_Start(True)
	End Method


	Method StartLoadedSaveGame:Int()
		print "====== START SAVED GAME ======"
		PrepareStart(False)
		_Start(False)
	End Method


	Method EndGame:int()
		SetGameState(TGame.STATE_MAINMENU)
		print "====== END CURRENT GAME ======"
	End Method


	'run when a specific game starts
	Method _Start:Int(startNewGame:Int = True)
		'set force=true so the gamestate is set even if already in this
		'state (eg. when loaded)
		GetGame().SetGamestate(TGame.STATE_RUNNING, True)

		If startNewGame
			'Begin Game - fire Events
			EventManager.registerEvent(TEventSimple.Create("Game.OnMinute", New TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().getDay()) ))
			EventManager.registerEvent(TEventSimple.Create("Game.OnHour", New TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().getDay()) ))
			'so we start at day "1"
			EventManager.registerEvent(TEventSimple.Create("Game.OnDay", New TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().getDay()) ))
		EndIf
	End Method



	'=== PREPARE A GAME ===

	'run this before EACH started game
	Method PrepareStart(startNewGame:Int)
		If startNewGame
			GetGame().InitWorld()
			GetGame().InitRoomsAndDoors()
		endif

		
		'Game screens
		if GameScreen_World
			GameScreen_World.Initialize()
		else
			GameScreen_World = New TInGameScreen_World.Create("InGame_World")
			ScreenCollection.Add(GameScreen_World)
		endif
		

		'=== SETUP TOOLTIPS ===
		TTooltip.UseFontBold = GetBitmapFontManager().baseFontBold
		TTooltip.UseFont = GetBitmapFontManager().baseFont
		TTooltip.ToolTipIcons = GetSpriteFromRegistry("gfx_building_tooltips")
		TTooltip.TooltipHeader = GetSpriteFromRegistry("gfx_tooltip_header")



		'=== ALL GAMES ===
		'TLogger.Log("Game.PrepareStart()", "preparing all room handlers and screens for new game", LOG_DEBUG)
		'GetRoomHandlerCollection().PrepareGameStart()


		TLogger.Log("Game.PrepareStart()", "colorizing images corresponding to playercolors", LOG_DEBUG)
		ColorizePlayerExtras()


		TLogger.Log("Game.PrepareStart()", "drawing doors, plants and lights on the building-sprite", LOG_DEBUG)
		'also registers events...
		GetBuilding().Init()


		TLogger.Log("Game.PrepareStart()", "Creating the world around us (weather and weather effects :-))", LOG_DEBUG)
		'(re-)inits weather effects (raindrops, snow flakes etc)
		InitWorldWeatherEffects()


		'refreshcreate the elevator roomboard
		if startNewGame
			TLogger.Log("Game.PrepareStart()", "Creating elevator plan", LOG_DEBUG)
			RoomHandler_ElevatorPlan.ReCreatePlan()
		endif

		'=== NEW GAMES ===
		'new games need some initializations (database etc.)
		If startNewGame Then PrepareNewGame()
	End Method


	Method PrepareNewGame:Int()
		SetStartYear(userStartYear)

		PlayerDetailsTimer = 0
		
		'=== START TIPS ===
		'maybe show this window each game? or only on game start or ... ?
		Local showStartTips:Int = False
		If showStartTips Then CreateStartTips()


		'=== LOAD DATABASES ===
		'load all movies, news, series and ad-contracts
		'do this here, as saved games already contain the database
		TLogger.Log("Game.PrepareNewGame()", "loading database", LOG_DEBUG)
		LoadDatabase(userDBDir)


		'=== FIGURES ===
		'set all non human players to AI
		If isGameLeader()
			For Local id:Int = 1 To 4
				If GetPlayer(id).IsLocalAI()
					GetPlayer(id).InitAI("res/ai/DefaultAIPlayer.lua")
				EndIf
			Next
		EndIf


		'move all figures to offscreen, and set their target to their
		'offices (for now just to the "floor", later maybe to the boss)
		For Local i:Int = 1 To 4
			GetPlayer(i).GetFigure().MoveToOffscreen()
			GetPlayer(i).GetFigure().area.position.x :+ i*3 + (i Mod 2)*15
			'forcefully send (no controlling possible until reaching the target)
			'GetPlayer(i).GetFigure().SendToDoor( TRoomDoor.GetByDetails("office", i), True)
			GetPlayer(i).GetFigure().ForceChangeTarget(TRoomDoor.GetByDetails("news", i).area.GetX() + 60, TRoomDoor.GetByDetails("news", i).area.GetY())
		Next

		'also create/move other figures of the building
		'all of them are created at "offscreen position"
		Local fig:TFigure = GetFigureCollection().GetByName("Hausmeister")
		If Not fig Then fig = New TFigureJanitor.Create("Hausmeister", GetSpriteFromRegistry("janitor"), GetBuildingBase().figureOffscreenX, 0, 65)
		fig.MoveToOffscreen()
		fig.SetParent(GetBuilding().buildingInner)
		fig.SendToDoor(TRoomDoor.GetByDetails("supermarket",-1), True)

		fig = GetFigureCollection().GetByName("Bote1")
		If Not fig Then fig = New TFigurePostman.Create("Bote1", GetSpriteFromRegistry("BoteLeer"), GetBuildingBase().figureOffscreenX - 90, 0, 65)
		fig.MoveToOffscreen()
		fig.SetParent(GetBuilding().buildingInner)
		fig.SendToDoor(TRoomDoor.GetByDetails("boss", 1), True)

		fig = GetFigureCollection().GetByName("Bote2")
		If Not fig Then fig = New TFigurePostman.Create("Bote2", GetSpriteFromRegistry("BoteLeer"), GetBuildingBase().figureOffscreenX -60, 0, -65)
		fig.MoveToOffscreen()
		fig.SetParent(GetBuilding().buildingInner)
		fig.SendToDoor(TRoomDoor.GetByDetails("boss", 3), True)


		'create 2 terrorists
		For Local i:Int = 0 To 1
			local fig:TFigureTerrorist = TFigureTerrorist(GetFigureCollection().GetByName("Terrorist"+(i+1)))
			If Not fig
				fig = New TFigureTerrorist
				fig.Create("Terrorist"+(i+1), GetSpriteFromRegistry("Terrorist"+(i+1)), GetBuildingBase().figureOffscreenX, 0, 65)
			EndIf
			fig.MoveToOffscreen()
			fig.SetParent(GetBuilding().buildingInner)

			terrorists[i] = fig
		Next

		'create 2 marshals (to confiscate different things we use
		'multiple marshals)
		For Local i:Int = 0 To 1
			local fig:TFigureMarshal = TFigureMarshal(GetFigureCollection().GetByName("Marshal"+(i+1)))
			If Not fig
				fig = New TFigureMarshal
				fig.Create("Marshal"+(i+1), GetSpriteFromRegistry("Marshal"+(i+1)), GetBuildingBase().figureOffscreenX, 0, 65)
			EndIf
			fig.MoveToOffscreen()
			fig.SetParent(GetBuilding().buildingInner)

			marshals[i] = fig
		Next


		'=== ADJUST GAME RULES ===
		GameRules.dailyBossVisit = GameRules.devConfig.GetInt("DEV_DAILY_BOSS_VISIT", True)


		'=== STATION MAP ===
		'load the used map
		GetStationMapCollection().LoadMapFromXML("res/maps/germany.xml")

		'create base stations
		For Local i:Int = 1 To 4
			'create station map if not done yet
			local map:TStationMap = GetStationMap(i, True)
			'add new station
			local s:TStation = TStation.Create( New TVec2D.Init(310, 260),-1, GetStationMapCollection().stationRadius, i )
			'first station is not sellable (this enforces competition)
			s.SetFlag(TStation.FLAG_SELLABLE, False)

			map.AddStation( s, False )
		Next

		'update the collection so it contains the audience reach of each player
		GetStationMapCollection().Update()


		'get names from settings
		For Local i:Int = 1 To 4
			GetPlayer(i).Name = ScreenGameSettings.guiPlayerNames[i-1].Value
			GetPlayer(i).channelname = ScreenGameSettings.guiChannelNames[i-1].Value
		Next

		'create series/movies in movie agency
		RoomHandler_MovieAgency.GetInstance().ReFillBlocks()

		'8 auctionable movies/series
		For Local i:Int = 0 To 7
			New TAuctionProgrammeBlocks.Create(i, Null)
		Next


		'give each player some programme
		SpreadStartProgramme()

		'give the players some money
		For Local i:Int = 1 To 4
			GetPlayer(i).GetFinance().TakeCredit(500000)
		Next


		'=== SETUP NEWS + ABONNEMENTS ===
		'adjust abonnement for each newsgroup to 1
		For Local playerids:Int = 1 To 4
			'only have abonnement for currents
			GetPlayer(playerids).SetNewsAbonnement(4, 1)
		Next

		'create 3 starting news, True = add even without news abonnement
		GetNewsAgency().AnnounceNewNewsEvent(-60, True)
		GetNewsAgency().AnnounceNewNewsEvent(-120, True)
		GetNewsAgency().AnnounceNewNewsEvent(-120, True)
		'adjust news agency to wait some time until next news
		GetNewsAgency().ResetNextEventTime()

		'place them into the players news shows
		Local newsToPlace:TNews
		For Local playerID:Int = 1 To 4
			For Local i:Int = 0 To 2
				'attention: instead of using "GetNewsAtIndex(i)" we always
				'use (0) - as each "placed" news is removed from the collection
				'leaving the next on listIndex 0
				newsToPlace = GetPlayerProgrammeCollectionCollection().Get(playerID).GetNewsAtIndex(0)
				If Not newsToPlace
					'throw "GetGame().PrepareNewGame: initial news " + i + " missing."
					Continue
				EndIf
				'set it paid - so money does not change
				newsToPlace.paid = True
				'calculate paid Price of the news
				newsToPlace.Pay()
				'set planned
				GetPlayerProgrammePlanCollection().Get(playerID).SetNews(newsToPlace, i)
			Next
		Next



		'=== SETUP START PROGRAMME PLAN ===

		Local lastblocks:Int=0
		Local playerCollection:TPlayerProgrammeCollection
		Local playerPlan:TPlayerProgrammePlan

		'creation of blocks for players rooms
		For Local playerids:Int = 1 To 4
			lastblocks = 0
			playerCollection = GetPlayerProgrammeCollectionCollection().Get(playerids)
			playerPlan = GetPlayerProgrammePlanCollection().Get(playerids)

			SortList(playerCollection.adContracts)

			Local addWidth:Int = GetSpriteFromRegistry("pp_programmeblock1").area.GetW()
			Local addHeight:Int = GetSpriteFromRegistry("pp_adblock1").area.GetH()

			Local currentLicence:TProgrammeLicence = playerCollection.GetMovieLicenceAtIndex(0)
			if currentLicence
				Local currentHour:Int = 0

				local broadcast:TProgramme = TProgramme.Create(currentLicence)
				playerPlan.SetProgrammeSlot(broadcast, GetWorldTime().GetStartDay(), currentHour )
				'disable control of that programme
				broadcast.SetFlag(TVTBroadcastMaterialFlag.NOT_CONTROLLABLE)
				'disable availability
				broadcast.data.available = False
				'additionally lock slots
'				for local i:int = 0 until broadcast.GetBlocks()
'					playerPlan.LockSlot(TVTBroadcastMaterialType.PROGRAMME, GetWorldTime().GetStartDay(), currentHour + i )
'				Next

				currentHour:+ currentLicence.getData().getBlocks()

				'add two infomercials after that programme
				playerPlan.SetProgrammeSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetWorldTime().GetStartDay(), currentHour )
				currentHour :+ 1
				playerPlan.SetProgrammeSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetWorldTime().GetStartDay(), currentHour )
				currentHour :+ 1

				'place ads for all broadcasted hours
				If playerCollection.GetRandomAdContract()
					For local i:int = 0 to currentHour-1
						playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), GetWorldTime().GetStartDay(), i )
					Next
				EndIf
			endif
		Next


		'=== SETUP INTERFACE ===
		
		'switch active TV channel to player
		GetInGameInterface().ShowChannel = GetPlayerCollection().playerID
	End Method


	Method InitWorld()
		Local appConfig:TData = GetDataFromRegistry("appConfig", New TData)
		Local worldConfig:TData = TData(appConfig.Get("worldConfig", New TData))

		GetWorld().Initialize()
		GetWorld().SetConfiguration(worldConfig)
	End Method


	Method InitWorldWeatherEffects()
		Local world:TWorld = GetWorld()

		'we draw them in front of the background buildings
		world.autoRenderSnow = False
		world.autoRenderRain = False
		
		'=== SETUP WORLD ===
		'1. SKY SPRITES
		World.InitSky(..
			GetSpriteFromRegistry("gfx_world_sky_gradient"), ..
			GetSpriteFromRegistry("gfx_world_sky_moon"), ..
			GetSpriteFromRegistry("gfx_world_sky_sun"), ..
			GetSpriteFromRegistry("gfx_world_sky_sunrays") ..
		)
		'2. SETUP RAIN
		World.InitRainEffect(2, GetSpriteGroupFromRegistry("gfx_world_sky_rain"))
		'3. SETUP SNOW
		World.InitSnowEffect(20, GetSpriteGroupFromRegistry("gfx_world_sky_snow"))
		'4. SETUP LIGHTNING
		World.InitLightningEffect(GetSpriteGroupFromRegistry("gfx_world_sky_lightning"), GetSpriteGroupFromRegistry("gfx_world_sky_lightning_side"))
		'5. SETUP CLOUDS
		World.InitCloudEffect(50, GetSpriteGroupFromRegistry("gfx_world_sky_clouds"))
		World.cloudEffect.Start() 'clouds from begin
	End Method



	Function InitRoomsAndDoors()
		local room:TRoom = null
		Local roomMap:TMap = TMap(GetRegistry().Get("rooms"))
		if not roomMap then Throw("ERROR: no room definition loaded!")

		'remove all previous rooms
		GetRoomCollection().Initialize()
		'and their doors
		GetRoomDoorBaseCollection().Initialize()


		For Local vars:TData = EachIn roomMap.Values()
			'==== ROOM ====
			local room:TRoom = new TRoom
			room.Init(..
				vars.GetString("roomname"),  ..
				[ ..
					vars.GetString("tooltip"), ..
					vars.GetString("tooltip2") ..
				], ..
				vars.GetInt("owner",-1),  ..
				vars.GetInt("size", 1)  ..
			)
			room.fakeRoom = vars.GetBool("fake", FALSE)
			room.screenName = vars.GetString("screen")


			'only add if not already there
			if not GetRoomCollection().Get(room.id)
				GetRoomCollection().Add(room)
			else
				room = GetRoomCollection().Get(room.id)
			endif

			'==== DOOR ====
			local door:TRoomDoor = new TRoomDoor
			door.Init(..
				room.id,..
				vars.GetInt("doorslot"), ..
				vars.GetInt("floor"), ..
				vars.GetInt("doortype") ..
			)
			GetRoomDoorBaseCollection().Add( door )
			'add the door to the building (sets parent etc)
			GetBuilding().AddDoor(door)

			'override defaults
			if not vars.GetBool("doortooltip") then door.showTooltip = False
			if vars.GetInt("doorwidth") > 0 then door.area.dimension.setX( vars.GetInt("doorwidth") )
			if vars.GetInt("x",-1000) <> -1000 then door.area.position.SetX(vars.GetInt("x"))



			'==== HOTSPOTS ====
			local hotSpots:TList = TList( vars.Get("hotspots") )
			if hotSpots
				for local conf:TData = eachin hotSpots
					local name:string 	= conf.GetString("name")
					local x:int			= conf.GetInt("x", -1)
					local y:int			= conf.GetInt("y", -1)
					local bottomy:int	= conf.GetInt("bottomy", 0)
					'the "building"-room uses floors 
					local floor:int 	= conf.GetInt("floor", -1)
					local width:int 	= conf.GetInt("width", 0)
					local height:int 	= conf.GetInt("height", 0)
					local tooltipText:string	 	= conf.GetString("tooltiptext")
					local tooltipDescription:string	= conf.GetString("tooltipdescription")

					'align at bottom of floor
					if floor >= 0 then y = TBuilding.GetFloorY2(floor) - height

					local hotspot:THotspot = new THotspot.Create( name, x, y - bottomy, width, height)
					hotspot.setTooltipText( GetLocale(tooltipText), GetLocale(tooltipDescription) )

					room.addHotspot( hotspot )
				next
			endif

		Next
	End Function




	Method SetStartYear(year:int)
		year = Max(1980, year)
		'set start year
		GetWorldTime().SetStartYear(year)
	End Method


	Method GetStartYear:Int()
		return GetWorldTime().GetStartYear()
	End Method



	Function CreateStartTips:Int()
		TLogger.Log("TGame", "Creating start tip GUIelement", LOG_DEBUG)
		Local StartTips:TList = CreateList()
		Local tipNumber:Int = 1
		'repeat as long there is a localization available
		While GetLocale("STARTHINT_TITLE"+tipNumber) <> "STARTHINT_TITLE"+tipNumber
			StartTips.addLast( [GetLocale("HINT")+ ": "+GetLocale("STARTHINT_TITLE"+tipNumber), GetLocale("STARTHINT_TEXT"+tipNumber)] )
			tipNumber :+ 1
		Wend

		If StartTips.count() > 0
			Local tipNumber:Int = Rand(0, StartTips.count()-1)
			Local tip:String[] = String[](StartTips.valueAtIndex(tipNumber))

			StartTipWindow = New TGUIGameModalWindow.Create(New TVec2D, New TVec2D.Init(400,350), "InGame")
			StartTipWindow.screenArea = New TRectangle.Init(0,0,800,385)
			StartTipWindow.DarkenedArea = New TRectangle.Init(0,0,800,385)
			StartTipWindow.SetCaptionAndValue( tip[0], tip[1] )
			StartTipWindow.Open()
		EndIf
	End Function


	Method SpreadStartProgramme:Int()
		'all players get the same adContractBase (but of course another
		'contract for each of them)
		Local adContractBases:TAdContractBase[]
		Local cheapFilter:TAdContractBaseFilter = New TAdContractbaseFilter
		'some easy ones
		cheapFilter.SetAudience(0.0, 0.01)
		'only without image requirements? not needed for start programme
		'you might have luck to get a better paid one :D
		'cheapFilter.SetImage(0.0, 0.0)
		'do not allow limited ones
		cheapFilter.SetSkipLimitedToProgrammeGenre()
		cheapFilter.SetSkipLimitedToTargetGroup()

rem
		local contracts:TAdContractBase[] = GetAdContractBaseCollection().GetAllAsArray()
		For local contract:TAdContractBase = EachIn contracts
			if not cheapFilter.DoesFilter(contract) then continue

			print contract.GetTitle() + "  " + contract.minAudienceBase
		Next
endrem

		local addContract:TAdContractBase
		For Local i:Int = 0 To 1
			addContract = GetAdContractBaseCollection().GetRandomByFilter(cheapFilter, False)
			if not addContract
				print "SpreadStartProgramme: GetAdContractBaseCollection().GetRandomByFilter failed! Skipping contract ..."
				continue
			endif
			adContractBases :+ [addContract]
		Next
		'and one with 0-1% audience requirement
		cheapFilter.SetAudience(0.0, 0.01)
		addContract = GetAdContractBaseCollection().GetRandomByFilter(cheapFilter, False)
		if not addContract  
			print "SpreadStartProgramme: No ~qno audience~q contract in DB? Trying a 0-3% one..."
			cheapFilter.SetAudience(0.0, 0.03)
			addContract = GetAdContractBaseCollection().GetRandomByFilter(cheapFilter, False)
			if not addContract
				print "SpreadStartProgramme: 0-2% failed too... using random contract now."
				addContract = GetAdContractBaseCollection().GetRandomByFilter(cheapFilter, True)
			endif
		endif
		if addContract then adContractBases :+ [addContract]
		

		If adContractBases.length = 0
			TLogger.Log("SpreadStartProgramme", "adContractBases is empty.", LOG_ERROR)
		EndIf


		'=== CREATE OPENING PROGRAMME ===
		For Local playerID:Int = 1 To 4
			local programmeData:TProgrammeData = new TProgrammeData

			programmeData.title = GetLocalizedString("OPENINGSHOW_TITLE")
			programmeData.description = GetLocalizedString("OPENINGSHOW_DESCRIPTION")
			programmeData.title.replace("%CHANNELNAME%", GetPlayer(playerID).channelName)
			programmeData.description.replace("%CHANNELNAME%", GetPlayer(playerID).channelName)

			programmeData.blocks = 5
			programmeData.genre = TVTProgrammeGenre.SHOW
			programmeData.review = 0.1
			programmeData.speed = 0.4
			programmeData.country = "D" 'make depending on station map?
			programmeData.year = GetWorldTime().GetYear()
			programmeData.liveTime = GetWorldTime().MakeTime(GetWorldTime().GetYear(), 0, 0, 5)
			programmeData.SetFlag(TVTProgrammeDataFlag.LIVE, True)
			GetProgrammeDataCollection().Add(programmeData)

			local programmeLicence:TProgrammeLicence = new TProgrammeLicence
			programmeLicence.setData(programmeData)
			programmeLicence.broadcastLimit = 1
			programmeLicence.licenceType = TVTProgrammeLicenceType.SINGLE
			GetPlayerProgrammeCollection(playerID).AddProgrammeLicence(programmeLicence)
		Next


		'start programmes should be similar to "cheap movie list" of the
		'movieagency - but they do not allow paid programmes
		local startProgrammeFilter:TProgrammeLicenceFilter = RoomHandler_MovieAgency.GetInstance().filterMoviesCheap.Copy()
		startProgrammeFilter.AddNotFlag(TVTProgrammeDataFlag.PAID)
		
		For Local playerids:Int = 1 To 4
			Local ProgrammeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerids)
'			For Local i:Int = 0 Until GameRules.startMovieAmount
'				ProgrammeCollection.AddProgrammeLicence(GetProgrammeLicenceCollection().GetRandomByFilter(startProgrammeFilter))
'			Next

			'create contracts out of the preselected adcontractbases
			For Local adContractBase:TAdContractBase = EachIn adContractBases
				'forcefully add to the collection (skips requirements checks)
				ProgrammeCollection.AddAdContract(New TAdContract.Create(adContractBase), True)
			Next
		Next
	End Method


	'run when loading starts
	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'if not done yet: run preparation for first game
		'(eg. if loading is done from mainmenu)
		PrepareFirstGameStart(False)
	End Function


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Savegame loaded - colorize players.", LOG_DEBUG | LOG_SAVELOAD)
		'reconnect AI and other things
		For Local player:TPlayer = EachIn GetPlayerCollection().players
			player.onLoad(Null)
		Next

		'set active player again (sets correct game screen)
		GetInstance().SetActivePlayer()
	End Function


	'run when starting saving a savegame
	Function onSaveGameBeginSave(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Start saving - inform AI.", LOG_DEBUG | LOG_SAVELOAD)
		'inform player AI that we are saving now
		For Local player:TPlayer = EachIn GetPlayerCollection().players
			If player.isLocalAI() Then player.PlayerAI.CallOnSave()
		Next
	End Function


	Method SetPaused(bool:Int=False)
		GetWorldTime().SetPaused(bool)
	End Method


	'override
	'computes daily costs like station or newsagency fees for every player
	Method ComputeDailyCosts(day:Int=-1)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			'stationfees
			Player.GetFinance().PayStationFees( Player.GetStationMap().CalculateStationCosts())
			'interest rate for your current credit
			Player.GetFinance().PayCreditInterest( Player.GetFinance().GetCreditInterest() )
			'newsagencyfees			
			Player.GetFinance(day).PayNewsAgencies(Player.GetNewsAbonnementFees())
		Next
	End Method


	'computes daily income like account interest income
	Method ComputeDailyIncome(day:Int=-1)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			If Player.GetFinance().money > 0
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
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			For Local Contract:TAdContract = EachIn Player.GetProgrammeCollection().adContracts
				If Not contract Then Continue

				'0 days = "today", -1 days = ended
				If contract.GetDaysLeft() < 0
					'inform contract
					contract.Fail(GetWorldTime().MakeTime(0, day, 0, 0))
					'remove
					Player.GetProgrammeCollection().RemoveAdContract(contract)
				EndIf
			Next
		Next
	End Method


	'creates the default players (as shown in game-settings-screen)
	Method CreateInitialPlayers()
		'skip if already done
		if GetPlayer(1) then return
	
		'Creating PlayerColors - could also be done "automagically"
		Local playerColors:TList = TList(GetRegistry().Get("playerColors"))
		If playerColors = Null Then Throw "no playerColors found in configuration"
		For Local col:TColor = EachIn playerColors
			col.AddToList()
		Next

		'create players, draws playerfigures on figures-image
		'TColor.GetByOwner -> get first unused color,
		'TPlayer.Create sets owner of the color
		GetPlayerCollection().Set(1, TPlayer.Create(1, userName, userChannelName, GetSpriteFromRegistry("Player1"),	150,  2, 90, TPlayerColor.getByOwner(0), "Player 1"))
		GetPlayerCollection().Set(2, TPlayer.Create(2, "Sandra", "SunTV", GetSpriteFromRegistry("Player2"),	180,  5, 90, TPlayerColor.getByOwner(0), "Player 2"))
		GetPlayerCollection().Set(3, TPlayer.Create(3, "Seidi", "FunTV", GetSpriteFromRegistry("Player3"),	140,  8, 90, TPlayerColor.getByOwner(0), "Player 3"))
		GetPlayerCollection().Set(4, TPlayer.Create(4, "Alfi", "RatTV", GetSpriteFromRegistry("Player4"),	190, 13, 90, TPlayerColor.getByOwner(0), "Player 4"))

		'set different figures for other players
		GetPlayer(2).UpdateFigureBase(9)
		GetPlayer(3).UpdateFigureBase(2)
		GetPlayer(4).UpdateFigureBase(6)

		'by default all other players are "AI" and handled by local player
		GetPlayer(2).SetLocalAIControlled()
		GetPlayer(3).SetLocalAIControlled()
		GetPlayer(4).SetLocalAIControlled()
	End Method


	'Things to init directly after game started
	Function onStart:Int(triggerEvent:TEventBase)
	End Function


	Method IsGameLeader:Int()
		Return (networkgame And Network.isServer) Or (Not networkgame)
	End Method


	Method IsControllingPlayer:Int(playerID:Int)
		If Not GetPlayer(playerID) Then Return False
		
		If Not networkgame
			Return True
		Else
			'it's me
			If GetPlayerCollection().isLocalPlayer(playerID) Then Return True
			'it's an AI player and I am the master
			If GetPlayer(playerID).IsLocalAI() And IsGameLeader() Then Return True
			Return False
		EndIf 
	End Method


	'override
	Method SetGameState:Int(gamestate:Int, force:Int=False )
		If Self.gamestate = gamestate And Not force Then Return True

		'switch to screen
		Select gamestate
			Case TGame.STATE_MAINMENU
				ScreenCollection.GoToScreen(Null,"MainMenu")
			Case TGame.STATE_SETTINGSMENU
				ScreenCollection.GoToScreen(Null,"GameSettings")
			Case TGame.STATE_NETWORKLOBBY
				ScreenCollection.GoToScreen(Null,"NetworkLobby")
			Case TGame.STATE_PREPAREGAMESTART
				ScreenCollection.GoToScreen(Null,"PrepareGameStart")
			Case TGame.STATE_RUNNING
				'when a game is loaded we should try set the right screen
				'not just the default building screen
				If GetPlayer().GetFigure().inRoom
					ScreenCollection.GoToScreen(ScreenCollection.GetCurrentScreen())
				Else
					ScreenCollection.GoToScreen(GameScreen_world)
				EndIf
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
					'so we could add news etc.
					EventManager.triggerEvent( TEventSimple.Create("Game.OnStart") )

					TSoundManager.GetInstance().PlayMusicPlaylist("default")
			Default
				'
		EndSelect
	End Method


	'sets the player controlled by this client
	Method SetActivePlayer(ID:Int=-1)
		If ID = -1 Then ID = GetPlayerCollection().playerID
		'for debug purposes we need to adjust more than just
		'the playerID.
		GetPlayerCollection().playerID = ID
		'also set this information for the boss collection (avoids
		'circular references)
		GetPlayerBossCollection().playerID = ID

		'get currently shown screen of that player
		If GetPlayer().GetFigure().inRoom
			ScreenCollection.GoToScreen(ScreenCollection.GetScreen(GetPlayer().GetFigure().inRoom.screenName))
		'go to building
		Else
			ScreenCollection.GoToScreen(GameScreen_World)
		EndIf
	End Method


	Function SendSystemMessage:Int(message:String)
		'send out to chats
		EventManager.triggerEvent(TEventSimple.Create("chat.onAddEntry", New TData.AddNumber("senderID", -1).AddNumber("channels", CHAT_CHANNEL_SYSTEM).AddString("text", message) ) )
		Return True
	End Function


	'Summary: load config from the app config data and set variables
	'depending on it
	Method LoadConfig:Int(config:TData)
		username = config.GetString("playername", "Player")
		userchannelname = config.GetString("channelname", "My Channel")
		userlanguage = config.GetString("language", "de")
		userStartYear = config.GetInt("startyear", 1985)
		userport = config.GetInt("onlineport", 4444)
		userDBDir = config.GetString("databaseDir", "res/database/Default")
		title = config.GetString("gamename", "New Game")
		userFallbackIP = config.GetString("fallbacklocalip", "192.168.0.1")
	End Method


	'Summary: Updates Time, Costs, States ...
	Method Update(deltaTime:Float=1.0)
		Local worldTime:TWorldTime = GetWorldTime()
		'==== ADJUST TIME ====
		worldTime.Update()

		'==== UPDATE WORLD ===
		'only update weather as it affects news etc.
		'lighting/effects are only updated when figure is outside of a
		'room (updateWeather is skipping processing if done just moments
		'ago)
		GetWorld().UpdateWeather()


		'==== CHECK BOMBS ====
		'this triggers potential bombs
		For Local room:TRoom = EachIn GetRoomCollection().list
			room.CheckForBomb()
		Next

		'send state to clients
		If IsGameLeader() And networkgame And stateSyncTime < Time.GetTimeGone()
			NetworkHelper.SendGameState()
			stateSyncTime = Time.GetTimeGone() + stateSyncTimer
		EndIf


		'=== REALTIME GONE CHECK ===
		'checks if at least 1 second is gone since the last call
		If lastTimeRealTimeSecondGone = 0 Then lastTimeRealTimeSecondGone = Time.GetTimeGone()
		If Time.GetTimeGone() - lastTimeRealTimeSecondGone > 1000
			'event passes milliseconds gone since last call
			'so if hickups made the game stop for 4.3 seconds, this value
			'will be about 4300. Maybe AI wants this information.
			EventManager.triggerEvent(TEventSimple.Create("Time.OnSecond", New TData.addNumber("timeGone", Time.GetTimeGone()-lastTimeRealTimeSecondGone)))
			lastTimeRealTimeSecondGone = Time.GetTimeGone()
		EndIf


		
		'init if not done yet
		If lastTimeMinuteGone = 0 Then lastTimeMinuteGone = worldTime.GetTimeGone()

		'==== HANDLE IN GAME TIME ====
		'less than a ingame minute gone? nothing to do YET
		If worldTime.GetTimeGone() - lastTimeMinuteGone < 60.0 Then Return

		'==== HANDLE GONE/SKIPPED MINUTES ====
		'if speed is to high - minutes might get skipped,
		'handle this case so nothing gets lost.
		'missedMinutes is >1 in all cases (else this part isn't run)
		Local missedSeconds:Float = (worldTime.GetTimeGone() - lastTimeMinuteGone)
		Local missedMinutes:Float = missedSeconds/60.0
		Local daysMissed:Int = Floor(missedMinutes / (24*60))

		'adjust the game time so GetWorldTime().GetDayHour()/Minute/...
		'return the correct value for each loop cycle. So Functions can
		'rely on that functions to get the time they request.
		'as everything can get calculated using "timeGone", no further
		'adjustments have to take place
		worldTime._timeGone:- missedSeconds

		For Local i:Int = 1 To missedMinutes
			'add back another gone minute each loop
			worldTime._timeGone :+ 60
			 
			'day
			If worldTime.GetDayHour() = 0 And worldTime.GetDayMinute() = 0
				'year
				If worldTime.GetDayOfYear() = 0
					EventManager.triggerEvent(TEventSimple.Create("Game.OnYear", New TData.addNumber("minute", worldTime.GetDayMinute()).addNumber("hour", worldTime.GetDayHour()).addNumber("day", worldTime.GetDay()) ))

					'reset availableNewsEventList - maybe this is a year
					'with some more news
					GetNewsEventCollection().RefreshAvailable()
				EndIf

			 	'automatically change current-plan-day on day change
			 	TScreenHandler_ProgrammePlanner.ChangePlanningDay(worldTime.GetDay())

				EventManager.triggerEvent(TEventSimple.Create("Game.OnDay", New TData.addNumber("minute", worldTime.GetDayMinute()).addNumber("hour", worldTime.GetDayHour()).addNumber("day", worldTime.GetDay()) ))
			EndIf

			'hour
			If worldTime.GetDayMinute() = 0
				EventManager.triggerEvent(TEventSimple.Create("Game.OnHour", New TData.addNumber("minute", worldTime.GetDayMinute()).addNumber("hour", worldTime.GetDayHour()).addNumber("day", worldTime.GetDay()) ))
			EndIf

			'minute
			EventManager.triggerEvent(TEventSimple.Create("Game.OnMinute", New TData.addNumber("minute", worldTime.GetDayMinute()).addNumber("hour", worldTime.GetDayHour()).addNumber("day", worldTime.GetDay()) ))
		Next

		'reset time of lst minute so next update can calculate missed minutes
		lastTimeMinuteGone = worldTime.GetTimeGone()
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetGame:TGame()
	Return TGame.GetInstance()
End Function
