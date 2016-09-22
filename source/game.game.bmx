
'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame Extends TGameBase {_exposeToLua="selected"}
	Field startAdContractBaseGUIDs:string[3]
	Field startProgrammeGUIDs:string[]
	
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

		'=== GAME TIME / SPEED ===
		'MAD TV speed:
		'slow:   10 game minutes = 30 seconds  -> 1 sec = 20 ingameseconds
		'middle: 10 game minutes = 20 seconds  -> 1 sec = 30 ingameseconds
		'fast:   10 game minutes = 10 seconds  -> 1 sec = 60 ingameseconds
		'set basic game speed to 30 gameseconds per second
		'GetWorldTime().SetTimeFactor(30.0)
		'GetBuildingTime().SetTimeFactor(1.0)
		SetGameSpeedPreset(1)


		if not GameScreen_World
			GameScreen_World = New TInGameScreen_World.Create("World")
			ScreenCollection.Add(GameScreen_World)
		endif


		startAdContractBaseGUIDs = new string[3]
		startProgrammeGUIDs = new string[0]


		'=== SETUP TOOLTIPS ===
		TTooltip.UseFontBold = GetBitmapFontManager().baseFontBold
		TTooltip.UseFont = GetBitmapFontManager().baseFont
		TTooltip.ToolTipIcons = GetSpriteFromRegistry("gfx_building_tooltips")
		TTooltip.TooltipHeader = GetSpriteFromRegistry("gfx_tooltip_header")

		'=== SETUP INTERFACE ===
		GetInGameInterface() 'calls init() if not done yet


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
		'handle finance change (reset bankrupt level if positive balance)
		_eventListeners :+ [ EventManager.registerListenerFunction("PlayerFinance.onChangeMoney", onPlayerChangeMoney) ]
	End Method


	Method SetGameSpeedPreset(preset:int)
		preset = Max(Min(GameRules.worldTimeSpeedPresets.length-1, preset), 0)
		SetGameSpeed(GameRules.worldTimeSpeedPresets[preset])
	End Method


	Method SetGameSpeed(timeFactor:int = 15)
		local modifier:Float = float(timeFactor) / GameRules.worldTimeSpeedPresets[0]

		GetWorldTime().SetTimeFactor(modifier * GameRules.worldTimeSpeedPresets[0])

		TEntity.globalWorldSpeedFactor = GameRules.globalEntityWorldSpeedFactor + 0.005 * modifier
		'move as fast as on level 2 (to avoid odd looking figures)
		GetBuildingTime().SetTimeFactor( Max(1.0, (modifier-1) * 1.0) )
	End Method


	'=== START A GAME ===

	Method StartNewGame:Int()
		TLogger.Log("TGame", "====== START NEW GAME ======", LOG_DEBUG)
		'Preparation is done before (to share data in network games)
		_Start(True)
	End Method


	Method StartLoadedSaveGame:Int()
		TLogger.Log("TGame", "====== START SAVED GAME ======", LOG_DEBUG)
		PrepareStart(False)
		_Start(False)
	End Method


	Method EndGame:int()
		If Self.gamestate = TGAme.STATE_RUNNING
			'start playing the menu music again
			GetSoundManager().PlayMusicPlaylist("menu")
		endif

		'reset speeds (so janitor in main menu moves "normal" again)
		SetGameSpeedPreset(1)

		SetGameState(TGame.STATE_MAINMENU)
		GetToastMessageCollection().RemoveAllMessages()
		TLogger.Log("TGame", "====== END CURRENT GAME ======", LOG_DEBUG)
	End Method


	'run when a specific game starts
	Method _Start:Int(startNewGame:Int = True)
		'set force=true so the gamestate is set even if already in this
		'state (eg. when loaded)
		GetGame().SetGamestate(TGame.STATE_RUNNING, True)

		TSoundManager.GetInstance().PlayMusicPlaylist("default")


		If startNewGame
			'refresh states of old programme productions (now we now
			'the start year and are therefore able to refresh who has
			'done which programme yet)
			GetProgrammeDataCollection().UpdateAll()

			'Begin Game - fire Events
			'so we start at day "1"
			EventManager.triggerEvent(TEventSimple.Create("Game.OnDay", New TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().GetDay()) ))
			'time after day
			EventManager.triggerEvent(TEventSimple.Create("Game.OnMinute", New TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().GetDay()) ))
			EventManager.triggerEvent(TEventSimple.Create("Game.OnHour", New TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().GetDay()) ))
		EndIf

		'so we could add news etc.
		EventManager.triggerEvent(TEventSimple.Create("Game.OnStart", New TData.addNumber("minute", GetWorldTime().GetDayMinute()).addNumber("hour", GetWorldTime().GetDayHour()).addNumber("day", GetWorldTime().GetDay()) ))
	End Method



	'=== PREPARE A GAME ===

	'override
	'run this BEFORE the first game is started
	Function PrepareFirstGameStart:Int(startNewGame:Int)
'
	End Function


	'run this before EACH started game
	Method PrepareStart(startNewGame:Int)
		If startNewGame
			'print "INITIALIZE: SET RANDOMIZER BASE =" + GetRandomizerBase()
			'reset randomizer to defined value
			SetRandomizerBase( GetRandomizerBase() )
			InitWorld()
			InitRoomsAndDoors()
		endif

		
		'Game screens
		GameScreen_World.Initialize()


		'=== ALL GAMES ===
		'TLogger.Log("Game.PrepareStart()", "preparing all room handlers and screens for new game", LOG_DEBUG)
		'GetRoomHandlerCollection().PrepareGameStart()

		'load the most current official achievements, so old savegames
		'get the new ones / adjustments too
		if not startNewGame
			TLogger.Log("Game.PrepareStart()", "loading most current (official) achievements", LOG_DEBUG)
			LoadDB(["database_achievements.xml"])
		endif


		TLogger.Log("Game.PrepareStart()", "colorizing images corresponding to playercolors", LOG_DEBUG)
		Local gray:TColor = TColor.Create(200, 200, 200)
		Local gray2:TColor = TColor.Create(100, 100, 100)
		Local gray3:TColor = TColor.Create(225, 225, 225)

		GetRegistry().Set("gfx_building_sign_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_base").GetColorizedImage(gray), "gfx_building_sign_0"))
		GetRegistry().Set("gfx_roomboard_sign_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base").GetColorizedImage(gray3,-1, COLORIZEMODE_OVERLAY), "gfx_roomboard_sign_0"))
		GetRegistry().Set("gfx_roomboard_sign_dragged_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base_dragged").GetColorizedImage(gray3,-1, COLORIZEMODE_OVERLAY), "gfx_roomboard_sign_dragged_0"))
		GetRegistry().Set("gfx_interface_channelbuttons_off_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_off").GetColorizedImage(gray2), "gfx_interface_channelbuttons_off_0"))
		GetRegistry().Set("gfx_interface_channelbuttons_on_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_on").GetColorizedImage(gray2), "gfx_interface_channelbuttons_on_0"))

		if not startNewGame
			ColorizePlayerExtras(1)
			ColorizePlayerExtras(2)
			ColorizePlayerExtras(3)
			ColorizePlayerExtras(4)
		endif

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


	Method UpdatePlayerBankruptLevel()
		'todo: individual time? eg. 24hrs after going into negative balance

		for local playerID:int = 1 to 4
			if GetPlayerFinance(playerID).GetMoney() < 0
				'skip level increase if level was adjusted that day already
				if GetWorldTime().GetDay() = GetWorldTime().GetDay(GetPlayerBankruptLevelTime(playerID)) then continue

				SetPlayerBankruptLevel(playerID, GetPlayerBankruptLevel(playerID)+1)

				if GetPlayerBankruptLevel(playerID) >= 3
					SetPlayerBankrupt(playerID)
				endif
			else
				if GetPlayerBankruptLevel(playerID) <> 0
					SetPlayerBankruptLevel(playerID, 0)
				endif
			endif
		Next

	End Method


	Method SetPlayerBankrupt(playerID:int)
		local player:TPlayer = GetPlayer(playerID)
		if not player then return

		local figure:TFigure = player.GetFigure()
		if figure
			'remove figure from game once it reaches its target
			figure.removeOnReachTarget = True
			'move figure to offscreen (figure got fired)
			if figure.inRoom then figure.LeaveRoom(True)
			figure.SendToOffscreen(True) 'force
			figure.playerID = 0
			'create a sprite copy for this figure, so the real player
			'can create a new one
			figure.sprite = new TSprite.InitFromImage( figure.sprite.GetImageCopy(False), "Player"+playerID, figure.sprite.frames)


			if player.IsLocalAI()
				'give the player a new figure
				player.Figure = New TFigure.Create(figure.name, GetSpriteFromRegistry("Player"+playerID), 0, 0, int(figure.initialdx))
				local colors:TPlayerColor[] = TPlayerColor.getUnowned(TPlayerColor.Create(255,255,255))
				local newColor:TPlayerColor = colors[RandRange(0, colors.length-1)]
				if newColor
					'set color free to use again
					Player.color.SetOwner(0)
					Player.color = newcolor.SetOwner(playerID).AddToList()
					Player.RecolorFigure(Player.color)
				endif
				'choose a random one
				if player.figurebase <= 5
					'male
					player.UpdateFigureBase(RandRange(0,5))
				else
					'female
					player.UpdateFigureBase(RandRange(6,12))
				endif

				player.Figure.SetParent(GetBuilding().buildingInner)
				player.Figure.playerID = playerID
				player.Figure.SendToOffscreen()
				player.Figure.MoveToOffscreen()
			endif
		endif


		'only start a new player if it is a local ai player
		if player.IsLocalAI()
			'store time of game over
			player.bankruptcyTimes :+ [ Long(GetWorldTime().GetTimeGone()) ]

			'reset everything of that player
			ResetPlayer(playerID)
			'prepare new player data (take credit, give starting programme...)
			PreparePlayerStep1(playerID)
			PreparePlayerStep2(playerID)
		endif

		if player.IsLocalHuman()
			GetGame().SetGameOver()
			'disable figure control (disable changetarget)
			player.GetFigure().controllable = False
		endif
	End Method


	Method ResetPlayer(playerID:int)
		local player:TPlayer = GetPlayer(playerID)
		if not player then return

		TLogger.Log("ResetPlayer()", "Resetting Player #"+playerID, LOG_DEBUG)
		TLogger.Log("ResetPlayer()", "-------------------", LOG_DEBUG)


		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		Local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlan(playerID)

		'TODO: ueberpruefen, ob der Programmplan eines alten Spielers
		'      gespeichert werden sollte (bspweise in TPlayer)
		'      So koennte auch bei alten Spielern noch auf die Historie
		'      zurueckgegriffen werden
		 

		'=== SELL ALL PROGRAMMES ===
		'sell forced too (so also programmed ones)
		local lists:TList[] = [ programmeCollection.suitcaseProgrammeLicences, ..
		                        programmeCollection.singleLicences, ..
		                        programmeCollection.seriesLicences, ..
		                        programmeCollection.collectionLicences ]
		local licences:TProgrammeLicence[]
		For local list:TList = EachIn lists
			For local licence:TProgrammeLicence = EachIn list
				licences :+ [licence]
			Next
		Next
		For local licence:TProgrammeLicence = EachIn licences
			'remove regardless of a successful sale
			programmePlan.RemoveProgrammeInstancesByLicence(licence, True)
			if licence.sell()
				TLogger.Log("ResetPlayer()", "Sold licence: "+licence.getTitle(), LOG_DEBUG)
			else
				TLogger.Log("ResetPlayer()", "Cannot sell licence: "+licence.getTitle(), LOG_DEBUG)
			
				'absolutely remove non-tradeable data?
				'for now: no! We want to be able to retrieve information
				'         about these licences.
				if not licence.isTradeable()
				'	GetProgrammeLicenceCollection().RemoveAutomatic(licence)
				'	GetProgrammeDataCollection().Remove(licence.data)
				endif
			endif
		Next



		'=== ABANDON/ABORT ALL CONTRACTS ===
		lists = [ programmeCollection.suitcaseAdContracts, ..
		          programmeCollection.adContracts ]
		local contracts:TAdContract[]
		For local list:TList = EachIn lists
			For local contract:TAdContract = EachIn list
				contracts :+ [contract]
			Next
		Next
		For local contract:TAdContract = EachIn contracts
			contract.Fail( GetWorldTime().GetTimeGone() )
			TLogger.Log("ResetPlayer()", "Aborted contract: "+contract.getTitle(), LOG_DEBUG)
		Next



		'=== SELL ALL SCRIPTS ===
		lists = [ programmeCollection.scripts, ..
		          programmeCollection.suitcaseScripts, ..
		          programmeCollection.studioScripts ]
		local scripts:TScript[]
		For local list:TList = EachIn lists
			For local script:TScript = EachIn list
				scripts :+ [script]
			Next
		Next
		For local script:TScript = EachIn scripts
			'remove script, sell it and destroy production concepts
			'linked to that script
			programmeCollection.RemoveScript(script, True)
			TLogger.Log("ResetPlayer()", "Sold script: "+script.getTitle(), LOG_DEBUG)
		Next



		'=== ABORT PRODUCTIONS ? ===
		local productions:TProduction[]
		For local p:TProduction = EachIn GetProductionManager().productionsToProduce
			if p.owner = playerID then productions :+ [p]
		Next
		For local p:TProduction = EachIn productions
			GetProductionManager().AbortProduction(p)
			'delete corresponding concept too
			GetProductionConceptCollection().Remove(p.productionConcept)
			TLogger.Log("ResetPlayer()", "Stopped production: "+p.productionConcept.getTitle(), LOG_DEBUG)
		Next
		


		'=== STOP ROOM RENT CONTRACTS ===
		TLogger.Log("ResetPlayer()", "TODO - stop rented rooms", LOG_DEBUG)



		'=== RESET BETTY FEELINGS ===
		GetBetty().InLove[PlayerID-1] = 0
		GetBetty().AdjustLove(playerID, 0) 'recalc other things

		GetBetty().AwardWinner[PlayerID-1] = 0
		GetBetty().AdjustAward(playerID, 0) 'recalc other things
		TLogger.Log("ResetPlayer()", "Adjusted Betty love and awards", LOG_DEBUG)



		'=== RESET NEWS ABONNEMENTS ===
		'reset so next player wont start with a higher level for this day
		For local i:int = 0 until TVTNewsGenre.count
			player.SetNewsAbonnementDaysMax(i, 0)
			player.SetNewsAbonnement(i, 0)
		Next

		

		'=== REMOVE DELAYED NEWS ===
		GetNewsAgency().ResetDelayedList(playerID)



		'=== SELL ALL STATIONS ===
		local map:TStationMap = GetStationMap(playerID, True)
		For local station:TStation = EachIn map.stations
			map.Removestation(station, True, True)
		Next
		GetStationMapCollection().Update()
		TLogger.Log("ResetPlayer()", "Sold stations", LOG_DEBUG)



		'=== RESET BOSS (OR INIT NEW ONE?) ===
		'reset mood
		'reset talk-about-subject-counters...
		'assign new playerID !
		local boss:TPlayerBoss = GetPlayerBoss(playerID)
		boss.Initialize()
		'assign new playerID (initialize unsets it)
		GetPlayerBossCollection().Set(playerID, boss)



		'=== RESET FINANCES ===
		'disabled: we keep the finances of older players for easier
		'AI improvement because of financial log files
		'GetPlayerFinanceCollection().ResetFinances(playerID)

		'set current day's finance to zero
		GetPlayerFinance(playerID, GetWorldTime().GetDay()).Reset()
		
		'keep history of previous player (if linked somewhere)
		'and instead of "GetPlayerFinanceHistoryList(playerID).clear()"
		'just create a new one
		GetPlayerFinanceHistoryListCollection().Set(playerID, CreateList())
		'also reset bankrupt level
		SetPlayerBankruptLevel(playerID, 0)
	End Method


	Method GetPlayerAIFileURI:string(playerID:int)
		local defaultFile:string = "res/ai/DefaultAIPlayer/DefaultAIPlayer.lua"
		local luaFile:string = GameRules.devConfig.GetString("playerAIScript" + playerID, defaultFile)

		if FileType(luaFile) = 1
			return luaFile
		else
			TLogger.Log("GetPlayerAIFileURI", "File ~q" + luaFile + "~q does not exist.", LOG_ERROR)
			print "GetPlayerAIFileURI: File ~q" + luaFile + "~q does not exist."
		endif

		if FileType(defaultFile) <> 1
			TLogger.Log("GetPlayerAIFileURI", "File ~q" + defaultFile + "~q does not exist.", LOG_ERROR)
			Throw "AI File ~q" + defaultFile + "~q does not exist."
		endif
		return defaultFile
	End Method


	'prepare player basics
	Method PreparePlayerStep1(playerID:int)
		local player:TPlayer = GetPlayer(playerID)
		'create player if not done yet
		if not player
			GetPlayerCollection().Set(playerID, TPlayer.Create(playerID, "Player", "Channel", GetSpriteFromRegistry("Player"+playerID), 190, 13, 90, TPlayerColor.getByOwner(0), "Player "+playerID))
			player = GetPlayer(playerID)
		endif

		'get names from settings
		GetPlayer(playerID).Name = ScreenGameSettings.guiPlayerNames[playerID-1].Value
		GetPlayer(playerID).channelname = ScreenGameSettings.guiChannelNames[playerID-1].Value

		local difficulty:TPlayerDifficulty = player.GetDifficulty()

		GetPlayer(playerID).SetStartDay(GetWorldTime().GetDaysRun())

		'colorize figure, signs, ...
		ColorizePlayerExtras(playerID)
		

		'=== 3RD PARTY PLAYER COMPONENTS ===
		TPublicImage.Create(Player.playerID)
		new TPlayerProgrammeCollection.Create(playerID)
		new TPlayerProgrammePlan.Create(playerID)


		local boss:TPlayerBoss = GetPlayerBoss(playerID)
		boss.Initialize()
		boss.creditMaximum = difficulty.creditMaximum


		'=== FIGURE ===
		If isGameLeader()
			If GetPlayer(playerID).IsLocalAI()
				GetPlayer(playerID).InitAI( new TAI.Create(playerID, GetPlayerAIFileURI(playerID)) )
			EndIf
		EndIf

		'move figure to offscreen, and set target to their office
		'(for now just to the "floor", later maybe to the boss)
		local figure:TFigure = GetPlayer(playerID).GetFigure()
		'remove potential elevator passenger 
		GetElevator().LeaveTheElevator(figure)

		if figure.inRoom then figure.LeaveRoom(True)
		figure.SetParent(GetBuilding().buildingInner)
		figure.MoveToOffscreen()
		figure.area.position.x :+ playerID*3 + (playerID Mod 2)*15
		'forcefully send (no controlling possible until reaching the target)
		'GetPlayer(i).GetFigure().SendToDoor( TRoomDoor.GetByDetails("office", i), True)
		figure.ForceChangeTarget(int(TRoomDoor.GetByDetails("news", playerID).area.GetX()) + 60, int(TRoomDoor.GetByDetails("news", playerID).area.GetY()))



		'=== STATIONMAP ===
		'create station map if not done yet
		local map:TStationMap = GetStationMap(playerID, True)

		'add new station
		local s:TStation = TStation.Create( New TVec2D.Init(310, 260),-1, GetStationMapCollection().stationRadius, playerID )
		'first station is not sellable (this enforces competition)
		s.SetFlag(TStation.FLAG_SELLABLE, False)

		map.AddStation( s, False )

		GetStationMapCollection().Update()



		'=== FINANCE ===
		'adjust start day (days after game start)
		GetPlayerFinanceCollection().SetPlayerStartDay(playerID, GetWorldTime().GetDaysRun() )
		if not GetPlayerFinance(playerID) then print "finance "+playerID+" failed."
		if difficulty.startMoney > 0 
			GetPlayerFinance(playerID).EarnGrantedBenefits( difficulty.startMoney )
		endif
		if difficulty.startCredit > 0 
			GetPlayerFinance(playerID).TakeCredit( difficulty.startCredit )
		endif
	End Method


	'can be run after _all_ other players have run PreparePlayerStep1()
	'Reason: when signing ad contracts, the average reach of the stations
	'        is used, but if only one player exists yet, the average is
	'        incorrect -> create all stations first in PreparePlayerStep1()
	Method PreparePlayerStep2(playerID:int)
		'=== SETUP NEWS + ABONNEMENTS ===
		'have a level 1 abonnement for currents
		GetPlayer(playerID).SetNewsAbonnement(4, 1)


		'fetch last 3 news events
		For local ne:TNewsEvent = EachIn GetNewsEventCollection().GetNewsHistory(3)
			if GetPlayerProgrammeCollection(playerID).HasNewsEvent(ne) then continue
			GetNewsAgency().AddNewsEventToPlayer(ne, playerID, True)
		Next
		

		'place them into the players news shows
		Local newsToPlace:TNews
		local count:int = GetPlayerProgrammeCollection(playerID).GetNewsCount()
		local placeAmount:int = 3
		For Local i:Int = 0 until placeAmount
			'attention: instead of using "GetNewsAtIndex(i)" we always
			'use the same starting point - as each "placed" news is
			'removed from the collection leaving the next on this listIndex
			newsToPlace = GetPlayerProgrammeCollection(playerID).GetNewsAtIndex(Max(0, count -placeAmount))
			'within a game (player restart) there might not be enough
			'news ... but we cannot create new news just because of one
			'player (others would benefit too)
			If Not newsToPlace then continue

			'set it paid - so money does not change
			newsToPlace.paid = True
			'calculate paid Price of the news
			newsToPlace.Pay()
			'set planned
			GetPlayerProgrammePlan(playerID).SetNews(newsToPlace, i)
		Next



		'=== FETCH START CONTRACTS ===
		'generate if not done yet
		GenerateStartAdContracts()

		'create contracts out of the preselected adcontractbases
		For Local guid:String = EachIn startAdContractBaseGUIDs
			local adContractBase:TAdContractBase = GetAdContractBaseCollection().GetByGUID(guid)
			if adContractBase
				'forcefully add to the collection (skips requirements checks)
				GetPlayerProgrammeCollection(playerID).AddAdContract(New TAdContract.Create(adContractBase), True)
			endif
		Next



		'=== CREATE OPENING PROGRAMME ===
		local programmeData:TProgrammeData = new TProgrammeData

		programmeData.title = GetLocalizedString("OPENINGSHOW_TITLE")
		programmeData.description = GetLocalizedString("OPENINGSHOW_DESCRIPTION")
		programmeData.title.replace("%CHANNELNAME%", GetPlayer(playerID).channelName)
		programmeData.description.replace("%CHANNELNAME%", GetPlayer(playerID).channelName)

		programmeData.blocks = 5
		programmeData.genre = TVTProgrammeGenre.SHOW
		programmeData.review = 0.1
		programmeData.speed = 0.4
		programmeData.outcome = 0.5
		programmeData.country = "D" 'make depending on station map?
		'time is adjusted during adding (as we know the time then)
		'programmeData.releaseTime = GetWorldTime().MakeTime(GetWorldTime().GetYear(), 0, 0, 5)
		programmeData.SetFlag(TVTProgrammeDataFlag.LIVE, True)
		programmeData.distributionChannel = TVTProgrammeDistributionChannel.TV
		'hide from player/vendor/...
		programmeData.SetFlag(TVTProgrammeDataFlag.INVISIBLE, True)

		programmeData.AddCast( New TProgrammePersonJob.Init("9104f9c1-7a0f-4bc0-a34c-389ce282eebf", TVTProgrammePersonJob.GUEST) )
		programmeData.AddCast( New TProgrammePersonJob.Init("9104f9c1-7a0f-4bc0-a34c-389ce282eebf", TVTProgrammePersonJob.MUSICIAN) )
		
		GetProgrammeDataCollection().Add(programmeData)

		local programmeLicence:TProgrammeLicence = new TProgrammeLicence
		programmeLicence.setData(programmeData)
		'disable sellability (for player and vendor)
		programmeLicence.setLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE, False)
		'remove after broadcasting
		programmeLicence.setLicenceFlag(TVTProgrammeLicenceFlag.REMOVE_ON_REACHING_BROADCASTLIMIT, True)
		programmeLicence.SetBroadcastLimit(1)
		programmeLicence.licenceType = TVTProgrammeLicenceType.SINGLE
		GetPlayerProgrammeCollection(playerID).AddProgrammeLicence(programmeLicence)



		'=== SETUP START PROGRAMME PLAN ===

		Local lastblocks:Int=0
		Local playerCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		Local playerPlan:TPlayerProgrammePlan = GetPlayerProgrammePlan(playerID)

'		SortList(playerCollection.adContracts)

		Local currentLicence:TProgrammeLicence = playerCollection.GetSingleLicenceAtIndex(0)
		if currentLicence
			Local startHour:Int = 0
			Local currentHour:int = 0
			local startDay:Int = GetWorldTime().GetStartDay()
			'find the next possible programme hour
			if GetWorldTime().GetDayMinute() >= 5
				startHour = GetWorldTime().GetDayHour() + 1
				if startHour > 23
					startHour :- 24
					startDay :+ 1
				endif
			endif			

			'adjust opener live-time
			programmeData.releaseTime = GetWorldTime().MakeTime(GetWorldTime().GetYear(), startDay - GetWorldTime().GetStartDay(), startHour, 5)
			
			Local broadcast:TProgramme = TProgramme.Create(currentLicence)
			playerPlan.SetProgrammeSlot(broadcast, startDay, startHour )
			'disable control of that programme
			broadcast.licence.SetControllable(False)
			if broadcast.isControllable() then Throw "controllable!"
			'disable availability
			broadcast.data.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, True)

			currentHour:+ currentLicence.getData().getBlocks()

			'add two infomercials after that programme
			playerPlan.SetProgrammeSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), startDay, startHour + currentHour )
			currentHour :+ 1
			playerPlan.SetProgrammeSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), startDay, startHour + currentHour )
			currentHour :+ 1

			'place ads for all broadcasted hours
			If playerCollection.GetRandomAdContract()
				For local i:int = 0 to currentHour-1
					playerPlan.SetAdvertisementSlot(New TAdvertisement.Create(playerCollection.GetRandomAdContract()), startDay, startHour + i )
				Next
			EndIf
		endif
	End Method


	'- kann vor Spielstart durchgefuehrt werden
	'- kann mehrfach ausgefuehrt werden
	Function ColorizePlayerExtras(playerID:int)
		'colorize the images
		GetPlayer(playerID).RecolorFigure()
		Local color:TColor = GetPlayer(playerID).color

		GetRegistry().Set("stationmap_antenna"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("stationmap_antenna0").GetColorizedImage(color,-1, COLORIZEMODE_OVERLAY), "stationmap_antenna"+playerID))
		GetRegistry().Set("gfx_building_sign_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_base").GetColorizedImage(color), "gfx_building_sign_"+playerID))
		GetRegistry().Set("gfx_roomboard_sign_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base").GetColorizedImage(color,-1, COLORIZEMODE_OVERLAY), "gfx_roomboard_sign_"+playerID))
		GetRegistry().Set("gfx_roomboard_sign_dragged_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base_dragged").GetColorizedImage(color, -1, COLORIZEMODE_OVERLAY), "gfx_roomboard_sign_dragged_"+playerID))
		GetRegistry().Set("gfx_interface_channelbuttons_off_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_off").GetColorizedImage(color, playerID), "gfx_interface_channelbuttons_off_"+playerID))
		GetRegistry().Set("gfx_interface_channelbuttons_on_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_on").GetColorizedImage(color, playerID), "gfx_interface_channelbuttons_on_"+playerID))
	End Function

	
	Method PrepareNewGame:Int()
		SetStartYear(userStartYear)

		'=== START TIPS ===
		'maybe show this window each game? or only on game start or ... ?
		Local showStartTips:Int = False
		If showStartTips Then CreateStartTips()


		'=== LOAD DATABASES ===
		'load all movies, news, series and ad-contracts
		'do this here, as saved games already contain the database
		TLogger.Log("Game.PrepareNewGame()", "loading database", LOG_DEBUG)
		LoadDatabase(userDBDir, true)
		'load map specific databases
		LoadDatabase("res/maps/germany/database", False)


		'=== FIGURES ===
		'create/move other figures of the building
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
		GameRules.stationConstructionTime = GameRules.devConfig.GetInt("DEV_STATION_CONSTRUCTION_TIME", GameRules.stationConstructionTimeDefault)


		'=== STATION MAP ===
		'load the used map
		GetStationMapCollection().LoadMapFromXML("res/maps/germany/germany.xml")
'		GetStationMapCollection().LoadMapFromXML("res/maps/germany.xml")


		'create series/movies in movie agency
		RoomHandler_MovieAgency.GetInstance().ReFillBlocks()

		'8 auctionable movies/series
		For Local i:Int = 0 To 7
			New TAuctionProgrammeBlocks.Create(i, Null)
		Next


		'create 3 random news happened some time before today ...
		'Limit to CurrentAffairs as this is the starting abonnement of
		'all players
		'Create one which is available at start in all cases (>3h old)
		GetNewsAgency().AnnounceNewNewsEvent(TVTNewsGenre.CURRENTAFFAIRS, - 60 * RandRange(180,210), True)
		For local i:int = 0 to 1
			GetNewsAgency().AnnounceNewNewsEvent(TVTNewsGenre.CURRENTAFFAIRS, - 60 * RandRange(5,15)*RandRange(5,10), True)
		Next

		
		'create 3 starting news with random genre (for starting news show)
		for local i:int = 0 until 3
			'genre = -1 to use a random genre
			local newsEvent:TNewsEvent = GetNewsAgency().GenerateNewNewsEvent(-1)
			'local newsEvent:TNewsEvent = GetNewsAgency().GetMovieNewsEvent()
			if newsEvent
				'time must be lower than for the "current affairs" news
				'so they are recognizeable as the latest ones
				local adjustMinutes:int = (-10*(i+1) + RandRange(-10, 10)) * 60
				newsEvent.doHappen( GetWorldTime().GetTimeGone() + adjustMinutes )
			endif
		Next
	
		'adjust news agency to wait some time until next news
		'RON: disabled, no longer needed as AnnounceNewNewsEvent() already
		'resets next event times
		'GetNewsAgency().ResetNextEventTime(-1)


		'first create basics (player, finances, stationmap)
		For local playerID:int = 1 to 4
			PreparePlayerStep1(playerID)
		Next
		'then prepare plan, news abonnements, ...
		'this is needed because adcontracts use average reach of
		'stationmaps on sign - which needs 4 stationmaps to be "set up"
		For local playerID:int = 1 to 4
			PreparePlayerStep2(playerID)
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


	Method GenerateStartAdContracts:Int()
		'remove invalidated/obsolete/no-longer-available entries
		For local i:int = 0 until startAdContractBaseGUIDs.length
			local adContractBase:TAdContractBase = GetAdContractBaseCollection().GetByGUID(startAdContractBaseGUIDs[i])
			if adContractBase and not adContractBase.IsAvailable()
				startAdContractBaseGUIDs[i] = null
			endif
		Next
		
		
		'all players get the same adContractBase (but of course another
		'contract for each of them)
		Local cheapFilter:TAdContractBaseFilter = New TAdContractbaseFilter
		'some easy ones
		cheapFilter.SetAudience(0.0, 0.02)
		'only without image requirements? not needed for start programme
		'you might have luck to get a better paid one :D
		'cheapFilter.SetImage(0.0, 0.0)
		'do not allow limited ones
		cheapFilter.SetSkipLimitedToProgrammeGenre()
		cheapFilter.SetSkipLimitedToTargetGroup()
		'the dev value is defining how many simultaneously are allowed
		'while the filter filters contracts already having that much (or
		'more) contracts, that's why we subtract 1
		local limitInstances:int = GameRules.devConfig.GetInt("DEV_ADAGENCY_LIMIT_CONTRACT_INSTANCES", GameRules.maxContractInstances)
		if limitInstances > 0 then cheapFilter.SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		local addContract:TAdContractBase
		For Local i:Int = 0 until startAdContractBaseGUIDs.length
			'already assigned (and available - others are already removed)
			if startAdContractBaseGUIDs[i] then continue

			if i < startAdContractBaseGUIDs.length-1
				addContract = GetAdContractBaseCollection().GetRandomByFilter(cheapFilter, False)
			else
				'and one with 0-1% audience requirement
				cheapFilter.SetAudience(0.015, 0.03)
				addContract = GetAdContractBaseCollection().GetRandomByFilter(cheapFilter, False)
				if not addContract  
					print "GenerateStartAdContracts: No ~qno audience~q contract in DB? Trying a 1.5-4% one..."
					cheapFilter.SetAudience(0.015, 0.04)
					addContract = GetAdContractBaseCollection().GetRandomByFilter(cheapFilter, False)
					if not addContract
						print "GenerateStartAdContracts: 1.5-4% failed too... using random contract now."
						addContract = GetAdContractBaseCollection().GetRandomByFilter(cheapFilter, True)
					endif
				endif
			endif
			
			if not addContract
				print "GenerateStartAdContracts: GetAdContractBaseCollection().GetRandomByFilter failed! Skipping contract ..."
				continue
			endif
			startAdContractBaseGUIDs[i] = addContract.GetGUID()

			'mark this ad as used
			if limitInstances <> 0
				cheapFilter.AddForbiddenContractGUID(addContract.GetGUID())
			endif
		Next

		'override with DEV.xml
		For local i:int = 0 until startAdContractBaseGUIDs.length
			local guid:string = GameRules.devConfig.GetString("DEV_STARTPROGRAMME_AD"+(i+1)+"_GUID", "")
			if guid = "" then continue

			local devAd:TAdContractBase = GetAdContractBaseCollection().GetByGUID(guid)
			'only override if the ad exists
			if devAd then startAdContractBaseGUIDs[i] = devAd.GetGUID()
		Next
	End Method


	'run when loading starts
	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'if not done yet: run preparation for first game
		'(eg. if loading is done from mainmenu)
		PrepareFirstGameStart(False)

		'remove all old messages
		GetToastMessageCollection().RemoveAllMessages()
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

		'set bankrupt level again (so toast messages might appear or not)
		For Local player:TPlayer = EachIn GetPlayerCollection().players
			GetInstance().SetPlayerBankruptLevel(player.playerID, GetInstance().GetPlayerBankruptLevel(player.playerID))
		Next
	End Function


	'run when starting saving a savegame
	Function onSaveGameBeginSave(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Start saving - inform AI.", LOG_DEBUG | LOG_SAVELOAD)
		'inform player AI that we are saving now
		For Local player:TPlayer = EachIn GetPlayerCollection().players
			If player.isLocalAI() Then player.PlayerAI.CallOnSave()
		Next
	End Function


	'run when financial balance of a player changes
	Function onPlayerChangeMoney(triggerEvent:TEventBase)
		local finance:TPlayerFinance = TPlayerFinance(triggerEvent.GetSender())
		if not finance then return

		local playerID:int = finance.playerID
		if finance.GetMoney() < 0 and GetGame().GetPlayerBankruptLevel(playerID) = 0
			GetGame().SetPlayerBankruptLevel(playerID, 1, -1)
		elseif finance.GetMoney() >= 0 and GetGame().GetPlayerBankruptLevel(playerID) <> 0
			GetGame().SetPlayerBankruptLevel(playerID, 0, -1)
		endif
	End Function


	'override
	Method SetPlayerBankruptLevel:int(playerID:int, level:int, time:Long = -1)
		if not Super.SetPlayerBankruptLevel(playerID, level) then return False

		if time = -1 then time = GetWorldTime().GetTimeGone()
		playerBankruptLevelTime[playerID -1] = time

		EventManager.triggerEvent( TEventSimple.Create("Game.SetPlayerBankruptLevel", new TData.AddNumber("playerID", playerID) ) )

		return True
	End Method


	Method SetPaused(bool:Int=False)
		GetWorldTime().SetPaused(bool)
		GetBuildingTime().SetPaused(bool)
	End Method


	Method IsPaused:int()
		return GetWorldTime().IsPaused()
	End Method


	'override
	'computes daily costs like station or newsagency fees for every player
	Method ComputeDailyCosts(day:Int)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			local finance:TPlayerFinance = Player.GetFinance(day)
			if not finance then Throw "ComputeDailyCosts failed: finance = null."
			'stationfees
			finance.PayStationFees( Player.GetStationMap().CalculateStationCosts() )
			'interest rate for your current credit
			finance.PayCreditInterest( finance.GetCreditInterest() )
			'newsagencyfees			
			finance.PayNewsAgencies(Player.GetTotalNewsAbonnementFees())
		Next
	End Method


	'computes daily income like account interest income
	Method ComputeDailyIncome(day:Int)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			local finance:TPlayerFinance = Player.GetFinance()
			if not finance then Throw "ComputeDailyIncome failed: finance = null."

			If finance.money > 0
				finance.EarnBalanceInterest( Long(finance.money * TPlayerFinance.balanceInterestRate) )
			Else
				'attention: multiply current money * -1 to make the
				'negative value an "positive one" - a "positive expense"
				finance.PayDrawingCreditInterest( Long(-1 * finance.money * TPlayerFinance.drawingCreditRate) )
			EndIf
		Next
	End Method


	'computes penalties for expired ad-contracts
	Method ComputeContractPenalties(day:Int)
		local obsoleteContracts:TAdContract[]
		'add all obsolete contracts to an array to avoid concurrent
		'modification
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			For Local Contract:TAdContract = EachIn Player.GetProgrammeCollection().adContracts
				If Not contract Then Continue

				'0 days = "today", -1 days = ended
				If contract.GetDaysLeft() < 0
					'inform contract
					contract.Fail(GetWorldTime().MakeTime(0, day, 0, 0))

					obsoleteContracts :+ [contract]
				EndIf
			Next
		Next

		'remove all obsolete contracts
		For local c:TAdContract = EachIn obsoleteContracts
			GetPlayerProgrammeCollection(c.owner).RemoveAdContract(c)
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
				If GetObservedFigure().GetInRoom()
print "goto screen: " + GetObservedFigure().GetInRoomID() + " screen="+ScreenCollection.GetCurrentScreen().name
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
	End Method


	Method GetObservedFigure:TFigureBase()
		if not TFigureBase(GameConfig.GetObservedObject())
			return GetPlayerBase().GetFigure()
		else
			return TFigureBase(GameConfig.GetObservedObject())
		endif
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
		GetBuildingTime().Update()

		'==== UPDATE WORLD ====
		'only update weather as it affects news etc.
		'lighting/effects are only updated when figure is outside of a
		'room (updateWeather is skipping processing if done just moments
		'ago)
		GetWorld().UpdateWeather()


		'==== UPDATE PLAYERS ====
		'eg. they empty their suitcases after a given time (licences
		'to archive)
		GetPlayerBaseCollection().Update()


		'==== CHECK BOMBS ====
		'this triggers potential bombs
		For Local room:TRoom = EachIn GetRoomCollection().list
			room.CheckForBomb()
		Next

		'send state to clients
		If IsGameLeader() And networkgame And stateSyncTime < Time.GetTimeGone()
			GetNetworkHelper().SendGameState()
			stateSyncTime = Time.GetTimeGone() + stateSyncTimer
		EndIf

		'allow slowdown in rooms
		if not GetGame().networkGame
			if GetPlayer().IsInRoom() 'and not GetPlayer().GetFigure().IsInBuilding()
				if TEntity.globalWorldSpeedFactorMod = 1.0
					GetWorldTime().SetTimeFactorMod(GameRules.InRoomTimeSlowDownMod)
					TEntity.globalWorldSpeedFactorMod = GameRules.InRoomTimeSlowDownMod
				endif
			else
				if TEntity.globalWorldSpeedFactorMod <> 1.0
					GetWorldTime().SetTimeFactorMod(1.0)
					TEntity.globalWorldSpeedFactorMod = 1.0
				endif
			endif
		endif


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
				If worldTime.GetDayOfYear() = 1
					EventManager.triggerEvent(TEventSimple.Create("Game.OnYear", New TData.addNumber("time", worldTime.GetTimeGone()) ))

					'reset availableNewsEventList - maybe this is a year
					'with some more news
					GetNewsEventCollection().RefreshAvailable()
				EndIf

			 	'automatically change current-plan-day on day change
			 	TScreenHandler_ProgrammePlanner.ChangePlanningDay(worldTime.GetDay())

				EventManager.triggerEvent(TEventSimple.Create("Game.OnDay", New TData.addNumber("time", worldTime.GetTimeGone()) ))
			EndIf

			'hour
			If worldTime.GetDayMinute() = 0
				EventManager.triggerEvent(TEventSimple.Create("Game.OnHour", New TData.addNumber("time", worldTime.GetTimeGone()) ))
			EndIf

			'minute
			EventManager.triggerEvent(TEventSimple.Create("Game.OnMinute", New TData.addNumber("time", worldTime.GetTimeGone()) ))
		Next

		'reset time of last minute so next update can calculate missed minutes
		lastTimeMinuteGone = worldTime.GetTimeGone()
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetGame:TGame()
	Return TGame.GetInstance()
End Function
