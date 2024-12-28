SuperStrict
Import "Dig/base.gfx.gui.window.modal.bmx"
Import "game.game.base.bmx"
Import "game.room.base.bmx"
Import "game.player.bmx"
Import "game.production.bmx"
Import "game.production.productionmanager.bmx"
Import "game.screen.base.bmx"
Import "game.database.bmx"
Import "game.misc.archivedmessage.bmx"
Import "game.roomhandler.elevatorplan.bmx"
Import "game.programmeproducer.bmx"
Import "game.programmeproducer.sport.bmx"
Import "game.programmeproducer.specialprogrammes.bmx"
Import "game.ai.bmx"
Import "basefunctions_network.bmx"
Import "game.network.networkhelper.bmx"
?bmxng
Import "Dig/base.util.bmxng.objectcountmanager.bmx"
?

'Game - holds time, audience, money and other variables (typelike structure makes it easier to save the actual state)
Type TGame Extends TGameBase {_exposeToLua="selected"}
	Field startAdContractBaseGUIDs:String[3]
	Field startProgrammeGUIDs:String[]

	Global GameScreen_World:TInGameScreen_World

	Global _initDone:Int = False
	Global _eventListeners:TEventListenerBase[]
	Global StartTipWindow:TGUIModalWindow
	Global gamesStarted:Int = 0


	Method New()
	End Method


	Function GetInstance:TGame()
		If Not _instance
			_instance = New TGame
		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		'==== ATTENTION =====
		'NEVER store _instance somewhere without paying attention
		'to this "whacky hack"
		ElseIf Not TGame(_instance)
			'now the new collection is the instance
			Local oldInstance:TGameBase = _instance
			_instance = New TGame
			THelper.TakeOverObjectValues(oldInstance, _instance)
		EndIf
		Return TGame(_instance)
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


		If Not GameScreen_World
			GameScreen_World = New TInGameScreen_World.Create("World")
			ScreenCollection.Add(GameScreen_World)
		EndIf


		startAdContractBaseGUIDs = New String[3]
		startProgrammeGUIDs = New String[0]


		refillMovieAgencyTime = GameRules.refillMovieAgencyTimer
		refillScriptAgencyTime = GameRules.refillScriptAgencyTimer
		refillAdAgencyTime = GameRules.refillAdAgencyTimer
		refillAdAgencyOverridePercentage = GameRules.refillAdAgencyPercentage


		'=== SETUP TOOLTIPS ===
		TTooltip.UseFontBold = GetBitmapFontManager().baseFontBold
		TTooltip.UseFont = GetBitmapFontManager().baseFont
		TTooltip.ToolTipIcons = GetSpriteFromRegistry("gfx_building_tooltips")
		TTooltip.TooltipHeader = GetSpriteFromRegistry("gfx_tooltip_header")

		'=== SETUP INTERFACE ===
		GetInGameInterface() 'calls init() if not done yet

		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]

		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnStart, onStart) ]
		'handle begin of savegameloading (prepare first game if needed)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnBeginLoad, onSaveGameBeginLoad) ]
		'handle savegame loading (assign sprites)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnLoad, onSaveGameLoad) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnBeginSave, onSaveGameBeginSave) ]
		'handle finance change (reset bankrupt level if positive balance)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PlayerFinance_OnChangeMoney, onPlayerChangeMoney) ]
	End Method


	Method SetGameSpeedPreset(preset:Int)
		preset = Max(Min(GameRules.worldTimeSpeedPresets.length-1, preset), 0)
		SetGameSpeed(GameRules.worldTimeSpeedPresets[preset], True)
	End Method

	Method SetGameSpeed(timeFactor:Int = 15, reducedBuildingTimeFactor:Int = False)
		GetWorldTime().SetTimeFactor( timeFactor ) 'same as "modifier * GameRules.worldTimeSpeedPresets[0]"
		'15 30 180 600
		'1  2  12  40
		Local modifier:Float = Float(timeFactor) / GameRules.worldTimeSpeedPresets[0]
		If reducedBuildingTimeFactor Then
			TEntity.globalWorldSpeedFactor = GameRules.globalEntityWorldSpeedFactor + 0.005 * modifier
			'also move slightly faster with higher speed...
			'speed preset 1 (modifier = 2) is default
			'"modifier" alone as factor does not look nice (fast forward)
			'exponent has impact only for preset 3!
			GetBuildingTime().SetTimeFactor(float( 0.75 + 0.5 * (modifier-1) ^ 0.6))
		Else
			GetBuildingTime().SetTimeFactor( modifier )
			TEntity.globalWorldSpeedFactor = modifier
		EndIf

'		TEntity.globalWorldSpeedFactor = GameRules.globalEntityWorldSpeedFactor + 0.005 * modifier
		'move as fast as on level 2 (to avoid odd looking figures)
'		GetBuildingTime().SetTimeFactor( Max(1.0, (modifier-1) * 1.0) )
'print "modifier: " + modifier + "  timefactor: " + (modifier * GameRules.worldTimeSpeedPresets[0]) + "  TEntity.globalWorldSpeedFactor="+TEntity.globalWorldSpeedFactor  +"   building time fac: "  + (Max(1.0, (modifier-1) * 1.0))
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


	Method EndGame:Int()
		If Self.gamestate = TGame.STATE_RUNNING
			'start playing the menu music again
			GetSoundManagerBase().PlayMusicPlaylist("menu")
		EndIf
		
		GetSoundManagerBase().StopSFX()

		'reset speeds (so janitor in main menu moves "normal" again)
		SetGameSpeedPreset(1)

		SetGameState(TGame.STATE_MAINMENU)
		GetToastMessageCollection().RemoveAllMessages()

		'stop ai
		For Local i:Int = 1 To 4
			GetPlayer(i).StopAI()
'			if GetPlayer(i).IsLocalAI() and GetPlayer(i).playerAI
'				GetPlayer(i).playerAI.Stop()
'			endif
		Next

		
		'remove chat messages
		GetInGameInterface().CleanUp()


		TLogger.Log("TGame", "====== END CURRENT GAME ======", LOG_DEBUG)
		'EventManager.DumpListeners()
	End Method


	'run when a specific game starts
	Method _Start:Int(startNewGame:Int = True)
		'set force=true so the gamestate is set even if already in this
		'state (eg. when loaded)
		GetGame().SetGamestate(TGame.STATE_RUNNING, True)

		GetSoundManagerBase().PlayMusicPlaylist("default")


		Local currDate:Int = Int(Time.GetSystemTime("%m%d"))
		If currDate > 1201 Or currDate < 115
			GameConfig.isChristmasTime = True
		Else
			GameConfig.isChristmasTime = False
		EndIf
		'christmas: change terrorist figures
		If GameConfig.isChristmasTime
			TLogger.Log("TGame", "Dress terrorists as Santa Claus.", LOG_DEBUG)
			terrorists[0].sprite = GetSpriteFromRegistry("Santa1")
			terrorists[1].sprite = GetSpriteFromRegistry("Santa2")
		Else
			If terrorists[0].sprite.name = "Santa1"
				terrorists[0].sprite = GetSpriteFromRegistry("Terrorist1")
				terrorists[1].sprite = GetSpriteFromRegistry("Terrorist2")
			EndIf
		EndIf


		Local timeData:TData = New TData.AddInt("minute", GetWorldTime().GetDayMinute()).AddInt("hour", GetWorldTime().GetDayHour()).AddInt("day", GetWorldTime().GetDay()).AddLong("time", GetWorldTime().GetTimeGone())

		If startNewGame
			'=== RESET SAVEGAME INFORMATION ===
			GameConfig.savegame_initialBuildDate = ""
			GameConfig.savegame_initialVersion = ""
			GameConfig.savegame_initialSaveGameVersion = ""
			GameConfig.savegame_saveCount = 0
			'also reset last used save name
			GameConfig.savegame_lastUsedName = ""

			'=== CREATE / INIT SPORTS ("life outside")===
			TLogger.Log("TGame", "Starting all sports (and their leagues) -1 year before now.", LOG_DEBUG)
			GetNewsEventSportCollection().CreateAllLeagues()
			GetNewsEventSportCollection().StartAll( Long(GetWorldTime().GetTimeGoneForRealDate(GetWorldTime().GetYear()-1,1,1)) )
			

			'refresh states of old programme productions (now we now
			'the start year and are therefore able to refresh who has
			'done which programme yet)
			TLogger.Log("TGame", "Refreshing production/cinema states of programmes (refreshing cast-information)", LOG_DEBUG)
			GetProgrammeDataCollection().UpdateAll()
			
			TLogger.Log("TGame", "Ensure enough castable amateurs exist.", LOG_DEBUG)
			GetProductionManager().UpdateCurrentlyAvailableAmateurs()


			'Begin Game - fire Events
			'so we start at day "1"
			TriggerBaseEvent(GameEventKeys.Game_OnDay, timeData)
			'time after day
			TriggerBaseEvent(GameEventKeys.Game_OnMinute, timeData)
			TriggerBaseEvent(GameEventKeys.Game_OnHour, timeData)
		Else
			if not GetProductionManager().currentAvailableAmateurs or GetProductionManager().currentAvailableAmateurs.length = 0
				TLogger.Log("TGame", "Ensure enough castable amateurs exist (old savegame).", LOG_DEBUG)
				GetProductionManager().UpdateCurrentlyAvailableAmateurs()
			endif
		EndIf
		
		If mission
			mission.Initialize(gameId)
		EndIf

		'so we could add news etc.
		TriggerBaseEvent(GameEventKeys.Game_OnStart, timeData)
		'inform about the begin of this game (for now equal to "OnStart")
		TriggerBaseEvent(GameEventKeys.Game_OnBegin, timeData)
		'trigger setting current language for database language update
		TriggerBaseEvent(GameEventKeys.App_OnSetLanguage, New TData.Add("languageCode", TLocalization.GetCurrentLanguageCode()), Self)

		?bmxng
		if OCM.enabled
			OCM.FetchDump("GAMESTART")
			If OCM.printEnabled
				OCM.Dump()
			EndIf
			SaveText(OCM.DumpToString(), "log.objectcount.gamestart" + (gamesStarted+1)+".txt")
		endif
		?

		If mission
			Local suffix:String = ".~n|b|"+GetRandomLocale2(["MISSION_START_PEP"])+"|/b|"
			?not debug
				If GameRules.devMode
					GameRules.devMode = 0
					suffix:+ ("~n"+GetLocale("MISSION_DISABLE_DEV"))
				EndIf
			?

			Local toast:TGameToastMessage = New TGameToastMessage
			toast.SetLifeTime(10)
			toast.SetMessageType( 1 )
			toast.SetMessageCategory(TVTMessageCategory.MISC)
			toast.SetCaption( GetLocale("MISSION")+": "+mission.getTitle() )
			toast.SetText( mission.GetDescription() + suffix)
			GetToastMessageCollection().AddMessage(toast, "TOPRIGHT")
		ElseIf Not GameRules.devMode
rem
			're-enable dev mode for endless game - can be done via dev command...
			If FileType("config/DEV.xml") = 1
				Local dataLoader:TDataXmlStorage = New TDataXmlStorage
				Local data:TData = dataLoader.Load("config/DEV.xml")
				If data
					Local devKeyEnabled:Int = data.GetBool(New TLowerString.Create("DEV_KEYS"), False)
					If devKeyEnabled Then GameRules.devMode = True
				EndIf
			EndIf
endrem
		EndIf

		gamesStarted :+ 1
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
		EndIf


		'=== ADJUST GAME RULES ===
		If startNewGame
			'initialize variables too
			TLogger.Log("Game.PrepareStart()", "GameRules initialization + override with DEV values.", LOG_DEBUG)
			GameRules.AssignFromData( GameRules.devConfigBackup )
		Else
			'Do nothing; value assignment has been done on loading (TGameState#RestoreGameData)
			'TLogger.Log("Game.PrepareStart()", "resetting GameRules values.", LOG_DEBUG)
			'GameRules.Reset()
		EndIf


		'Game screens
		GameScreen_World.Initialize()


		'=== ALL GAMES ===
		'TLogger.Log("Game.PrepareStart()", "preparing all room handlers and screens for new game", LOG_DEBUG)
		'GetRoomHandlerCollection().PrepareGameStart()

		'load the most current official achievements, so old savegames
		'get the new ones / adjustments too
		If Not startNewGame
			TLogger.Log("Game.PrepareStart()", "loading most current (official) achievements", LOG_DEBUG)
			LoadDB(["database_achievements.xml"])
		EndIf


		TLogger.Log("Game.PrepareStart()", "Reassuring correct room flags (freeholds, fake rooms)", LOG_DEBUG)
		For Local room:TRoomBase = EachIn GetRoomBaseCollection().list
			'mark porter, elevatorplan, ... as fake rooms
			If room.GetOwner() <= 0
				Select room.GetNameRaw().ToLower()
					Case "elevatorplan"
						room.SetFlag(TVTRoomFlag.FAKE_ROOM, True)
						room.SetFlag(TVTRoomFlag.NEVER_RESTRICT_OCCUPANT_NUMBER, True)
					Case "porter", "building", "credits", "roomboard"
						room.SetFlag(TVTRoomFlag.FAKE_ROOM, True)
				End Select
			EndIf

			'mark office, news, boss and archive as freeholds so they
			'cannot get cancelled in the room agency - nor do they cost
			'rent
			'mark owned studios as used (needed for older savegames!
			Select room.GetNameRaw().ToLower()
				'"studio" is only set for studios of a game start
				Case "office", "news", "boss", "archive", "studio"
					room.SetFlag(TVTRoomFlag.FREEHOLD, True)
				'some important rooms should also never be configured
				'to become "free studios"
				Case "movieagency", "adagency", "scriptagency", "supermarket", "betty"
					room.SetFlag(TVTRoomFlag.FREEHOLD, True)
			End Select
		Next


		'take over player/channel names (from savegame or new games)
		For Local i:Int = 1 To 4
			playerNames[i-1] = GetPlayer(i).name
			channelNames[i-1] = GetPlayer(i).channelName
		Next


		TLogger.Log("Game.PrepareStart()", "colorizing images corresponding to playercolors", LOG_DEBUG)
		Local gray:TColor = TColor.CreateGrey(200)
		Local gray2:TColor = TColor.CreateGrey(100)
		Local gray3:TColor = TColor.CreateGrey(225)

		GetRegistry().Set("gfx_building_sign_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_base").GetColorizedImage(gray), "gfx_building_sign_0"))
		GetRegistry().Set("gfx_roomboard_sign_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base").GetColorizedImage(gray3,-1, EColorizeMode.Overlay), "gfx_roomboard_sign_0"))
		GetRegistry().Set("gfx_roomboard_sign_dragged_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base_dragged").GetColorizedImage(gray3,-1, EColorizeMode.Overlay), "gfx_roomboard_sign_dragged_0"))
		GetRegistry().Set("gfx_interface_channelbuttons_off_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_off").GetColorizedImage(gray2), "gfx_interface_channelbuttons_off_0"))
		GetRegistry().Set("gfx_interface_channelbuttons_on_0", New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_on").GetColorizedImage(gray2), "gfx_interface_channelbuttons_on_0"))

		If Not startNewGame
			ColorizePlayerExtras(1)
			ColorizePlayerExtras(2)
			ColorizePlayerExtras(3)
			ColorizePlayerExtras(4)
		EndIf

		TLogger.Log("Game.PrepareStart()", "drawing doors, plants and lights on the building-sprite", LOG_DEBUG)
		'also registers events...
		GetBuilding().Init()


		TLogger.Log("Game.PrepareStart()", "Creating the world around us (weather and weather effects :-))", LOG_DEBUG)
		'(re-)inits weather effects (raindrops, snow flakes etc)
		InitWorldWeatherEffects()


		'refreshcreate the elevator roomboard
		If startNewGame
			TLogger.Log("Game.PrepareStart()", "Creating room board", LOG_DEBUG)
			GetRoomBoard().Initialize()
			GetElevatorRoomBoard().Initialize()
		EndIf

		'=== NEW GAMES ===
		'new games need some initializations (database etc.)
		If startNewGame Then PrepareNewGame()
	End Method


	Method UpdatePlayerBankruptLevel()
		'todo: individual time? eg. 24hrs after going into negative balance

		For Local playerID:Int = 1 To 4
			If GetPlayerFinance(playerID).GetMoney() < 0
				'skip level increase if level was adjusted that day already
				If GetWorldTime().GetDay() = GetWorldTime().GetDay(GetPlayerBankruptLevelTime(playerID)) Then Continue

				SetPlayerBankruptLevel(playerID, GetPlayerBankruptLevel(playerID)+1)

				If GetPlayerBankruptLevel(playerID) >= 3
					SetPlayerBankrupt(playerID)
				EndIf
			Else
				If GetPlayerBankruptLevel(playerID) <> 0
					SetPlayerBankruptLevel(playerID, 0)
				EndIf
			EndIf
		Next

	End Method


	Method SetPlayerBankrupt(playerID:Int)
		Local player:TPlayer = GetPlayer(playerID)
		If Not player Then Return

		'emit an event before player data gets reset (money, name ...)
		TriggerBaseEvent(GameEventKeys.Game_SetPlayerBankruptBegin, New TData.AddInt("playerID", playerID), Self, player)

		'inform all AI players about the bankruptcy (eg. to clear their stats)
		For Local p:TPlayer = EachIn GetPlayerCollection().players
			If Not p.IsLocalAI() Or Not p.PlayerAI Then Continue

			'p.PlayerAI.CallOnPlayerGoesBankrupt( playerID )
			p.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnPlayerGoesBankrupt).AddInt(playerID))
		Next
		
		
		'stop playerAI
		'this will also be done by "ResetPlayer()"
		if player.IsLocalAI() Then player.StopAI()


		Local figure:TFigure = player.GetFigure()
		If figure
			'remove figure from game once it reaches its target
			figure.removeOnReachTarget = True
			'move figure to offscreen (figure got fired)
			If figure.inRoom Then figure.LeaveRoom(True)
			figure.SendToOffscreen(True) 'force
			figure.playerID = 0
			'create a sprite copy for this figure, so the real player
			'can create a new one
			figure.sprite = New TSprite.InitFromImage( figure.sprite.GetImageCopy(False), "Player"+playerID, figure.sprite.frames)


			If player.IsLocalAI()
				'give the player a new figure
				player.Figure = New TFigure.Create(figure.name, GetSpriteFromRegistry("Player"+playerID), 0, 0, Int(figure.initialdx))
				Local colors:TPlayerColor[] = TPlayerColor.getUnowned()
				if colors.length = 0 then colors :+ [TPlayerColor.Create(255,255,255)]
				Local newColor:TPlayerColor = colors[RandRange(0, colors.length-1)]
				If newColor
					'set color free to use again
					player.color.SetOwner(0)
					player.color = newcolor.Register().SetOwner(playerID)
					player.RecolorFigure(player.color)
				EndIf
				'choose a random one
				If player.figurebase <= 5
					'male
					player.UpdateFigureBase(RandRange(0,5))
				Else
					'female
					player.UpdateFigureBase(RandRange(6,12))
				EndIf

				player.Figure.SetParent(GetBuilding().buildingInner)
				player.Figure.playerID = playerID
				player.Figure.SendToOffscreen()
				player.Figure.MoveToOffscreen()
			EndIf
		EndIf


		'only start a new player if it is a local ai player
		If player.IsLocalAI()
			'store time of game over
			player.bankruptcyTimes :+ [ Long(GetWorldTime().GetTimeGone()) ]

			'reset everything of that player
			ResetPlayer(playerID)
			'prepare new player data (take credit, give starting programme...)
			PreparePlayerStep1(playerID, True)
			PreparePlayerStep2(playerID)

			StartPlayer(playerID)
			
			'refresh current broadcast information (not broadcasting 
			'something now)
			GetBroadcastManager().ResetCurrentPlayerBroadcast(playerID)
		EndIf


		If player.IsLocalHuman()
			GetGame().SetGameOver()
			'disable figure control (disable changetarget)
			player.GetFigure()._controllable = False
		EndIf

		'now names might differ
		TriggerBaseEvent(GameEventKeys.Game_SetPlayerBankruptFinish, New TData.AddInt("playerID", playerID), Self, player)
	End Method


	Method ResetPlayer(playerID:Int)
		Local player:TPlayer = GetPlayer(playerID)
		If Not player Then Return

		TLogger.Log("ResetPlayer()", "Resetting Player #"+playerID, LOG_DEBUG)
		TLogger.Log("ResetPlayer()", "-------------------", LOG_DEBUG)


		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		Local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlan(playerID)

		'TODO: ueberpruefen, ob der Programmplan eines alten Spielers
		'      gespeichert werden sollte (bspweise in TPlayer)
		'      So koennte auch bei alten Spielern noch auf die Historie
		'      zurueckgegriffen werden



		'=== AI DATA ===
		'reset temporary data of the previous AI
		If player.aiData
			player.aiData = New TData
			TLogger.Log("ResetPlayer()", "Removed aiData", LOG_DEBUG)
		EndIf
		'inform player AI (if existing) it stopped (means it also stops its thread)
		player.StopAI()



		'=== ABORT PRODUCTIONS ? ===
		Local productions:TProduction[]
		For Local p:TProduction = EachIn GetProductionManager().productionsToProduce
			If p.owner = playerID Then productions :+ [p]
		Next
		For Local p:TProduction = EachIn GetProductionManager().liveProductions
			If p.owner = playerID Then productions :+ [p]
		Next
		For Local p:TProduction = EachIn productions
			GetProductionManager().AbortProduction(p)
			'delete corresponding concept too
			GetProductionConceptCollection().Remove(p.productionConcept)
			TLogger.Log("ResetPlayer()", "Stopped production: "+p.productionConcept.getTitle(), LOG_DEBUG)
		Next

		'=== SELL ALL SCRIPTS ===
		Local lists:TList[] = [ programmeCollection.scripts, ..
		          programmeCollection.suitcaseScripts, ..
		          programmeCollection.studioScripts ]
		Local scripts:TScript[]
		For Local list:TList = EachIn lists
			For Local script:TScript = EachIn list
				scripts :+ [script]
			Next
		Next

		For Local script:TScript = EachIn scripts
			'remove script, sell it and destroy production concepts
			'linked to that script
			programmeCollection.RemoveScript(script, True)
			TLogger.Log("ResetPlayer()", "Sold script: "+script.getTitle(), LOG_DEBUG)
		Next


		'=== SELL ALL PROGRAMMES ===
		'sell forced too (so also programmed ones)
		lists = [ programmeCollection.suitcaseProgrammeLicences, ..
		                        programmeCollection.singleLicences, ..
		                        programmeCollection.seriesLicences, ..
		                        programmeCollection.collectionLicences ]
		Local licences:TProgrammeLicence[]
		For Local list:TList = EachIn lists
			For Local licence:TProgrammeLicence = EachIn list
				licences :+ [licence]
			Next
		Next
		For Local licence:TProgrammeLicence = EachIn licences
			'remove regardless of a successful sale
			programmePlan.RemoveProgrammeInstancesByLicence(licence, True)
			If licence.sell()
				TLogger.Log("ResetPlayer()", "Sold licence: "+licence.getTitle(), LOG_DEBUG)
			Else
				TLogger.Log("ResetPlayer()", "Cannot sell licence: "+licence.getTitle(), LOG_DEBUG)

				'absolutely remove non-tradeable data?
				'for now: no! We want to be able to retrieve information
				'         about these licences.
				If Not licence.isTradeable()
				'	GetProgrammeLicenceCollection().RemoveAutomatic(licence)
				'	GetProgrammeDataCollection().Remove(licence.data)
				EndIf
			EndIf
		Next



		'=== ABANDON/ABORT ALL CONTRACTS ===
		lists = [ programmeCollection.suitcaseAdContracts, ..
		          programmeCollection.adContracts ]
		Local contracts:TAdContract[]
		For Local list:TList = EachIn lists
			For Local contract:TAdContract = EachIn list
				contracts :+ [contract]
			Next
		Next
		For Local contract:TAdContract = EachIn contracts
			contract.Fail( GetWorldTime().GetTimeGone() )
			TLogger.Log("ResetPlayer()", "Aborted contract: "+contract.getTitle(), LOG_DEBUG)
		Next


		'=== STOP ROOM RENT CONTRACTS ===
		GetRoomAgency().CancelRoomRentalsOfPlayer(PlayerID)
		TLogger.Log("ResetPlayer()", "TODO - stop rented rooms", LOG_DEBUG)


		'=== RESET ARCHIVED MESSAGES ===
		GetArchivedMessageCollection().RemoveAll(PlayerID)
		TLogger.Log("ResetPlayer()", "Removed archived messages", LOG_DEBUG)


		'=== RESET ROOM BOARD IMAGES ===
		GetRoomBoard().ResetImageCaches(PlayerID)



		'=== RESET BETTY FEELINGS / AWARDS ===
		GetBetty().ResetLove(PlayerID)
		If GetAwardCollection().GetCurrentAward()
			GetAwardCollection().GetCurrentAward().ResetScore(playerID)
		EndIf
		TLogger.Log("ResetPlayer()", "Adjusted Betty love and awards", LOG_DEBUG)



		'=== RESET NEWS ABONNEMENTS ===
		'reset so next player wont start with a higher level for this day
		player.ResetNewsAbonnements()
		TLogger.Log("ResetPlayer()", "Reset news abonnements", LOG_DEBUG)


		'=== REMOVE NEWS ===
		'delayed ones
		GetNewsAgency().ResetDelayedList(playerID)
		'"available" ones
		'albeit the programmecollection gets replaced by a new one afterwards
		'this might be useful as RemoveNews() emits events
		For Local news:TNews = EachIn programmeCollection.news.copy()
			programmeCollection.RemoveNews(news)
		Next
		TLogger.Log("ResetPlayer()", "Removed news", LOG_DEBUG)



		'=== SELL ALL STATIONS ===
		Local map:TStationMap = GetStationMap(playerID)
		If map
			'iterate over copy, as we manipulate the content
			For Local station:TStationBase = EachIn map.stations.Copy()
				map.RemoveStation(station, True, True)
			Next
			'reset map itself (eg station counter to start station names with #1 again)
			map.Initialize()
			GetStationMapCollection().Update()
			TLogger.Log("ResetPlayer()", "Sold stations", LOG_DEBUG)
		EndIf

		For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
			section.SetBroadcastPermission(playerID, False)
		Next
		TLogger.Log("ResetPlayer()", "Removed broadcast permissions", LOG_DEBUG)



		'=== RESET PRESSURE GROUP SYMPATHIES ==
		For Local pg:TPressureGroup = EachIn GetPressureGroupCollection().pressureGroups
			'use Reset instead of a simple "set" to also remove archived
			'values
			pg.Reset(playerID)
		Next
		TLogger.Log("ResetPlayer()", "Reset pressure group sympathies", LOG_DEBUG)



		'=== RESET BOSS (OR INIT NEW ONE?) ===
		'reset mood
		'reset talk-about-subject-counters...
		'assign new playerID !
		Local boss:TPlayerBoss = GetPlayerBoss(playerID)
		boss.Initialize()
		'assign new playerID (initialize unsets it)
		GetPlayerBossCollection().Set(playerID, boss)



		'=== RESET FINANCES ===
		'if disabled: keep the finances of older players for easier
		'AI improvement because of financial log files
		If Not GameConfig.KeepBankruptPlayerFinances
			GetPlayerFinanceCollection().ResetFinances(playerID)
		EndIf

		'set current day's finance to zero
		GetPlayerFinance(playerID, GetWorldTime().GetDay()).Reset()

		'keep history of previous player (if linked somewhere)
		'and instead of "GetPlayerFinanceHistoryList(playerID).clear()"
		'just create a new one
		GetPlayerFinanceHistoryListCollection().Set(playerID, CreateList())
		'also reset bankrupt level
		SetPlayerBankruptLevel(playerID, 0)
	End Method


	Method StartPlayer(playerID:Int)
		'now names might differ
		TriggerBaseEvent(GameEventKeys.Game_OnStartPlayer, New TData.AddInt("playerID", playerID))
	End Method


	Method GetPlayerAIFileURI:String(playerID:Int)
		Local defaultFile:String = "res/ai/DefaultAIPlayer/DefaultAIPlayer.lua"
		Local luaFile:String = GameRules.devConfig.GetString("playerAIScript" + playerID, defaultFile)

		If FileType(luaFile) = 1
			Return luaFile
		Else
			TLogger.Log("GetPlayerAIFileURI", "File ~q" + luaFile + "~q does not exist.", LOG_ERROR)
			Print "GetPlayerAIFileURI: File ~q" + luaFile + "~q does not exist."
		EndIf

		If FileType(defaultFile) <> 1
			TLogger.Log("GetPlayerAIFileURI", "File ~q" + defaultFile + "~q does not exist.", LOG_ERROR)
			Throw "AI File ~q" + defaultFile + "~q does not exist."
		EndIf
		Return defaultFile
	End Method


	'prepare player basics
	Method PreparePlayerStep1(playerID:Int, isRestartingPlayer:Int = False)
		Local player:TPlayer = GetPlayer(playerID)
		'create player if not done yet
		If Not player
			GetPlayerCollection().Set(playerID, TPlayer.Create(playerID, "Player", "Channel", GetSpriteFromRegistry("Player"+playerID), 190, 13, 90, TPlayerColor.getByOwner(0), "Player "+playerID))
			player = GetPlayer(playerID)
		EndIf

		'get names from base config (might differ on other clients/savegames)
		GetPlayer(playerID).Name = playerNames[playerID-1]
		GetPlayer(playerID).channelname = channelNames[playerID-1]

		Local difficulty:TPlayerDifficulty = player.GetDifficulty()

		GetPlayer(playerID).SetStartDay(GetWorldTime().GetDaysRun())

		'colorize figure, signs, ...
		ColorizePlayerExtras(playerID)


		'=== 3RD PARTY PLAYER COMPONENTS ===
		TPublicImage.Create(Player.playerID)
		New TPlayerProgrammeCollection.Create(playerID)
		New TPlayerProgrammePlan.Create(playerID)

		Local boss:TPlayerBoss = GetPlayerBoss(playerID)
		boss.Initialize()
		boss.creditMaximum = difficulty.creditAvailableOnGameStart


		'=== FIGURE ===
		If isGameLeader()
			If GetPlayer(playerID).IsLocalAI()
				GetPlayer(playerID).InitAI( New TAI.Create(playerID, GetPlayerAIFileURI(playerID)) )
			EndIf
		EndIf

		'move figure to offscreen, and set target to their office
		'(for now just to the "floor", later maybe to the boss)
		Local figure:TFigure = GetPlayer(playerID).GetFigure()
		'remove potential elevator passenger
		GetElevator().LeaveTheElevator(figure)

		If figure.inRoom Then figure.LeaveRoom(True)
		figure.SetParent(GetBuilding().buildingInner)
		figure.MoveToOffscreen()
		figure.area.MoveX(playerID*3 + (playerID Mod 2)*15)
		'forcefully send (no controlling possible until reaching the target)
		'GetPlayer(i).GetFigure().SendToDoor( GetRoomDoorBasecollection().GetFirstByDetails("office", i), True)
		Local newsDoor:TRoomDoorBase = GetRoomDoorBasecollection().GetFirstByDetails("news", playerID)
		If Not newsDoor
			Throw "No 'news' room found - broken config?"
		EndIf
		figure.ForceChangeTarget(Int(newsDoor.area.x) + 60, Int(newsDoor.area.y))



		'=== STATIONMAP ===
		'create station map if not done yet
		Local map:TStationMap = GetStationMap(playerID)
		If Not map
			map = New TStationMap(playerID)
			GetStationMapCollection().AddMap(map)
		EndIf


		'add new station
		Local dataX:Int = GetStationMapCollection().mapInfo.SurfaceXToDataX(GetStationMapCollection().mapInfo.startAntennaSurfacePos.x)
		Local dataY:Int = GetStationMapCollection().mapInfo.SurfaceYToDataY(GetStationMapCollection().mapInfo.startAntennaSurfacePos.y)
		Local s:TStationBase = New TStationAntenna.Init(new SVec2I(dataX, dataY), playerID )
		'Local s:TStationBase = New TStationAntenna.Init(GetStationMapCollection().mapInfo.startAntennaSurfacePos.x, GetStationMapCollection().mapInfo.startAntennaSurfacePos.y , -1, playerID )

		TStationAntenna(s).radius = GetStationMapCollection().antennaStationRadius
		If s.GetReceivers() < GameRules.stationInitialIntendedReach
			For Local cableNetwork:TStationMap_CableNetwork = EachIn GetStationMapCollection().cableNetworks
				If Not cableNetwork.isLaunched() Then Continue
				 
				Local cableUplink:TStationBase = New TStationCableNetworkUplink.Init(cableNetwork, playerID, True)
				If cableUplink.GetReceivers() >= GameRules.stationInitialIntendedReach
					If TStationAntenna(s) or cableUplink.GetReceivers() < s.GetReceivers()
						s = cableUplink
					EndIf
				EndIf
			Next
		EndIf
		'first station is not sellable (this enforces competition)
		s.SetFlag(TVTStationFlag.SELLABLE, False)
		'mark it as being gifted (by your boss or so)
		s.SetFlag(TVTStationFlag.GRANTED, True)
		'do not pay for it each day
		s.SetFlag(TVTStationFlag.NO_RUNNING_COSTS, True)
		'activate it instantly (no build time)
		s.SetActive(True)

		'add a broadcast permission for this station (price: 0 euro)
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(s.GetSectionName())
		If section Then section.SetBroadcastPermission(playerID, True, 0)

		If TStationCableNetworkUplink(s)
			s.SetFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT,True)
			s.GetProvider().minimumChannelImage = 0
		EndIf
		map.AddStation( s, False )
		'before changing bankruptcy handling, at this point stations at random positions were added
		'this was changed, so the AI has a chance to choose position itself and does not have to
		'fight with high initial fix costs


		map.DoCensus()
		map.Update()
		GetStationMapCollection().Update()
		If GetStationMap(playerID).GetReceivers() = 0 Then Throw "Player initialization: GetStationMap("+playerID+").GetReceivers() returned 0."


		'=== FINANCE ===
		'inform finance about new startday
		GetPlayerFinanceCollection().SetPlayerStartDay(playerID, GetWorldTime().GetDay())
		If Not GetPlayerFinance(playerID) Then Print "finance "+playerID+" failed."

		Local addMoney:Int = difficulty.startMoney
		If isRestartingPlayer
			Local avgMoney:Long = 0
			For Local i:Int = 1 To 4
				If i = playerID Then Continue
				Local playerSum:Long = GetPlayerFinance(i).GetMoney()

				'add monetary value of programme licences
				Local pc:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(i)
				Local licenceValue:Long = 0
				For Local list:TList = EachIn [pc.GetSingleLicences(), pc.GetSeriesLicences(), pc.GetCollectionLicences() ]
					For Local l:TProgrammeLicence = EachIn list
						licenceValue :+ l.GetPrice(l.owner)
					Next
				Next
				playerSum :+ licenceValue
				'limit each player's influence to 100Mio; 
				'limiting the maximal resulting start amount to 100Mio
				avgMoney:+ min(playerSum, 100000000)
			Next
			avgMoney :/ 3 '3 to ignore our player

			'adjust by difficulty and replace start money only if average is more
			avgMoney :* difficulty.restartingPlayerMoneyRatio
			If avgMoney > addMoney Then addMoney = avgMoney
			'print "avgMoney = " + avgMoney
		EndIf


		If addMoney > 0 Then GetPlayerFinance(playerID).EarnGrantedBenefits( addMoney )
		If (GameRules.startGameWithCredit Or GetPlayer(playerID).IsLocalAI()) And difficulty.startCredit > 0
			GetPlayerFinance(playerID).TakeCredit( difficulty.startCredit )
		EndIf
	End Method


	'can be run after _all_ other players have run PreparePlayerStep1()
	'Reason: when signing ad contracts, the average reach of the stations
	'        is used, but if only one player exists yet, the average is
	'        incorrect -> create all stations first in PreparePlayerStep1()
	Method PreparePlayerStep2(playerID:Int)
		'=== SETUP NEWS + ABONNEMENTS ===
		'have a level 1 abonnement for currents
		GetPlayer(playerID).SetNewsAbonnement(4, 1)


		'fetch last 3 news events
		For Local ne:TNewsEvent = EachIn GetNewsEventCollection().GetNewsHistory(3)
			If GetPlayerProgrammeCollection(playerID).HasNewsEvent(ne) Then Continue

			'True, True = send now and add even if not subscribed!
			GetNewsAgency().AddNewsEventToPlayer(ne, playerID, True, True)
			'avoid having that news again (same is done during add, so this
			'step is not strictly needed here)
			GetNewsAgency().RemoveFromDelayedListsByNewsEventID(playerID, ne.GetID())
		Next


		'place them into the players news shows
		Local newsToPlace:TNews
		Local count:Int = GetPlayerProgrammeCollection(playerID).GetNewsCount()
		Local placeAmount:Int = 3
		For Local i:Int = 0 Until placeAmount
			'attention: instead of using "GetNewsAtIndex(i)" we always
			'use the same starting point - as each "placed" news is
			'removed from the collection leaving the next on this listIndex
			newsToPlace = GetPlayerProgrammeCollection(playerID).GetNewsAtIndex(Max(0, count -placeAmount))
			'within a game (player restart) there might not be enough
			'news ... but we cannot create new news just because of one
			'player (others would benefit too)
			If Not newsToPlace Then Continue

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
			Local adContractBase:TAdContractBase = GetAdContractBaseCollection().GetByGUID(guid)
			If adContractBase
				'forcefully add to the collection (skips requirements checks)
				Local ad:TAdContract = New TAdContract.Create(adContractBase)
				GetPlayerProgrammeCollection(playerID).AddAdContract(ad, True)
			EndIf
		Next



		'=== CREATE OPENING PROGRAMME ===
		Local programmeData:TProgrammeData = New TProgrammeData

		programmeData.title = GetLocalizedString("OPENINGSHOW_TITLE")
		programmeData.description = GetLocalizedString("OPENINGSHOW_DESCRIPTION")
		programmeData.title.Replace("%CHANNELNAME%", GetPlayer(playerID).channelName)
		programmeData.description.Replace("%CHANNELNAME%", GetPlayer(playerID).channelName)

		programmeData.blocks = 5
		programmeData.genre = TVTProgrammeGenre.SHOW
		programmeData.review = 0.1
		programmeData.speed = 0.4
		programmeData.outcome = 0.5
		programmeData.country = GetStationMapCollection().config.GetString("nameShort", "UNK")
		'time is adjusted during adding (as we know the time then)
		'programmeData.releaseTime = GetWorldTime().GetTimeGoneForGameTime(GetWorldTime().GetYear(), 0, 0, 5)
		programmeData.SetFlag(TVTProgrammeDataFlag.LIVE, True)
		programmeData.distributionChannel = TVTProgrammeDistributionChannel.TV
		'hide from player/vendor/...
		programmeData.SetFlag(TVTProgrammeDataFlag.INVISIBLE, True)

		programmeData.AddCast( New TPersonProductionJob.Init(GetPersonBaseCollection().GetByGUID("Ronny-person-various-sjaele").GetID(), TVTPersonJob.DIRECTOR) )
		programmeData.AddCast( New TPersonProductionJob.Init(GetPersonBaseCollection().GetByGUID("9104f9c1-7a0f-4bc0-a34c-389ce282eebf").GetID(), TVTPersonJob.HOST) )
		programmeData.AddCast( New TPersonProductionJob.Init(GetPersonBaseCollection().GetByGUID("Ronny-person-various-ukuleleorchesterstarscrazy").GetID(), TVTPersonJob.MUSICIAN) )
		'select 3 guests out of the listed ones
		Local randomGuests:String[] = ["Ronny-person-various-helmut", ..
		                               "Ronny-person-various-ratz", ..
		                               "Ronny-person-various-sushitv", ..
		                               "Ronny-person-various-teppic", ..
		                               "Ronny-person-various-therob" ..
		                              ]
		Local startIndex:Int = (GetWorldTime().GetTimeGone() + MersenneSeed) Mod randomGuests.length
		For Local guestIndex:Int = 0 To 2
			Local index:Int = (startIndex + guestIndex) Mod randomGuests.length
			programmeData.AddCast( New TPersonProductionJob.Init(GetPersonBaseCollection().GetByGUID(randomGuests[index]).GetID(), TVTPersonJob.GUEST) )
		Next

		GetProgrammeDataCollection().Add(programmeData)

		Local programmeLicence:TProgrammeLicence = New TProgrammeLicence
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
		Local startDay:int
		Local startHour:int

'		SortList(playerCollection.adContracts)
		Local currentLicence:TProgrammeLicence = playerCollection.GetSingleLicenceAtIndex(0)
		If currentLicence
			Local startHour:Int = 0
			Local currentHour:Int = 0
			Local startDay:Int = GetWorldTime().GetDay()
			'find the next possible programme hour
			If GetWorldTime().GetDayMinute() >= 5
				startHour = GetWorldTime().GetDayHour() + 1
				If startHour > 23
					startHour :- 24
					startDay :+ 1
				EndIf
			EndIf
			'adjust opener live-time
			programmeData.releaseTime = GetWorldTime().GetTimeGoneForGameTime(0, startDay, startHour, 5)
			Local broadcast:TProgramme = TProgramme.Create(currentLicence)
			playerPlan.SetProgrammeSlot(broadcast, startDay, startHour )
			'disable control of that programme
			broadcast.licence.SetControllable(False)
			If broadcast.isControllable() Then Throw "controllable!"
			'disable availability
			broadcast.data.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, True)
			'does not affect betty (if set to be trash/paid somewhen)
			broadcast.data.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORED_BY_BETTY, True)

			currentHour:+ currentLicence.getData().getBlocks()

			'add the last ad as infomercial (all others should be finished
			'then)
'debugstop
			playerPlan.SetProgrammeSlot(New TAdvertisement.Create(playerCollection.GetAdContractAtIndex(2)), startDay, startHour + currentHour )

			'place ads for all broadcasted hours
			Local currentAdIndex:Int = 0
			Local currentAdSpotIndex:Int = 0
			Local currentAdDay:Int = startDay
			Local currentAdHour:Int = startHour
			For Local adContract:TAdContract = EachIn playerCollection.GetAdContracts()
				For Local spotIndex:Int = 1 To adContract.GetSpotCount()
					Local ad:TAdvertisement = New TAdvertisement.Create(adContract)
					If Not ad.GetSource().IsAvailable() Then DebugStop
					playerPlan.SetAdvertisementSlot(ad, currentAdDay, currentAdHour )
					currentAdHour :+ 1
					If currentAdHour > 23
						currentAdHour :- 24
						currentAdHour :+ 1
					EndIf
				Next
			Next
		EndIf

		TriggerBaseEvent(GameEventKeys.Game_PreparePlayer, New TData.AddInt("playerID", playerID), GetPlayer(playerID), Self)
	End Method


	'- kann vor Spielstart durchgefuehrt werden
	'- kann mehrfach ausgefuehrt werden
	Function ColorizePlayerExtras(playerID:Int)
		'colorize the images
		GetPlayer(playerID).RecolorFigure()
		Local color:TColor = GetPlayer(playerID).color

		GetRegistry().Set("stationmap_antenna"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("stationmap_antenna0").GetColorizedImage(color,-1, EColorizeMode.Overlay), "stationmap_antenna"+playerID))
		GetRegistry().Set("gfx_building_sign_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_building_sign_base").GetColorizedImage(color), "gfx_building_sign_"+playerID))
		GetRegistry().Set("gfx_roomboard_sign_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base").GetColorizedImage(color,-1, EColorizeMode.Overlay), "gfx_roomboard_sign_"+playerID))
		GetRegistry().Set("gfx_roomboard_sign_dragged_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_roomboard_sign_base_dragged").GetColorizedImage(color, -1, EColorizeMode.Overlay), "gfx_roomboard_sign_dragged_"+playerID))
		GetRegistry().Set("gfx_interface_channelbuttons_off_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_off").GetColorizedImage(color, playerID), "gfx_interface_channelbuttons_off_"+playerID))
		GetRegistry().Set("gfx_interface_channelbuttons_on_"+playerID, New TSprite.InitFromImage(GetSpriteFromRegistry("gfx_interface_channelbuttons_on").GetColorizedImage(color, playerID), "gfx_interface_channelbuttons_on_"+playerID))
	End Function


	Method PrepareNewGame:Int()
		'=== SET DEFAULTS ===
		SetStartYear(userStartYear)


		'=== START TIPS ===
		'maybe show this window each game? or only on game start or ... ?
		Local showStartTips:Int = False
		If showStartTips Then CreateStartTips()


		'=== LOAD DATABASES ===
		'load all movies, news, series and ad-contracts
		'do this here, as saved games already contain the database
		TLogger.Log("Game.PrepareNewGame()", "loading database", LOG_DEBUG)
		LoadDatabase(userDBDir, True)
		'load map specific databases
		LoadDatabase("res/maps/germany/database", False)

		'maybe something cached processed-title/description by calling
		'GetTitle() (eg. in a logfile)
		GetProgrammeDataCollection().RemoveReplacedPlaceholderCaches()

		'=== FIGURES ===
		'create/move other figures of the building
		'all of them are created at "offscreen position"
		Local fig:TFigure = GetFigureCollection().GetByName("Hausmeister")
		If Not fig Then fig = New TFigureJanitor.Create("Hausmeister", GetSpriteFromRegistry("janitor"), GetBuildingBase().figureOffscreenX, 0, 65)
		fig.MoveToOffscreen()
		fig.SetParent(GetBuilding().buildingInner)
		fig.SendToDoor(GetRoomDoorCollection().GetFirstByDetails("supermarket",-1), True)

		fig = GetFigureCollection().GetByName("Bote1")
		If Not fig Then fig = New TFigurePostman.Create("Bote1", GetSpriteFromRegistry("BoteLeer"), GetBuildingBase().figureOffscreenX - 90, 0, 65)
		fig.MoveToOffscreen()
		fig.SetParent(GetBuilding().buildingInner)
		fig.SendToDoor(GetRoomDoorCollection().GetFirstByDetails("boss", 1), True)

		fig = GetFigureCollection().GetByName("Bote2")
		If Not fig Then fig = New TFigurePostman.Create("Bote2", GetSpriteFromRegistry("BoteLeer"), GetBuildingBase().figureOffscreenX -60, 0, -65)
		fig.MoveToOffscreen()
		fig.SetParent(GetBuilding().buildingInner)
		fig.SendToDoor(GetRoomDoorCollection().GetFirstByDetails("boss", 3), True)


		'create 2 terrorists
		For Local i:Int = 0 To 1
			Local fig:TFigureTerrorist = TFigureTerrorist(GetFigureCollection().GetByName("Terrorist"+(i+1)))
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
			Local fig:TFigureMarshal = TFigureMarshal(GetFigureCollection().GetByName("Marshal"+(i+1)))
			If Not fig
				fig = New TFigureMarshal
				fig.Create("Marshal"+(i+1), GetSpriteFromRegistry("Marshal"+(i+1)), GetBuildingBase().figureOffscreenX, 0, 65)
			EndIf
			fig.MoveToOffscreen()
			fig.SetParent(GetBuilding().buildingInner)

			marshals[i] = fig
		Next


		'=== STATION MAP ===
		GetStationMapCollection().Initialize()
		'set marker for initializing antenna radius on new game
		GetStationMapCollection().antennaStationRadius = TStationMapCollection.ANTENNA_RADIUS_NOT_INITIALIZED
		'load the used map
		GetStationMapCollection().LoadMapFromXML("res/maps/germany/germany.xml")


		'=== CUSTOM PRODUCTION ===
		'ensure we have at least 3 persons per job available,
		'and when creating some, prefer the current country
		local addedCelebs:Int = EnsureEnoughCastableCelebritiesPerJob(3, GetStationMapCollection().GetMapISO3166Code())
		if addedCelebs
			TLogger.Log("Game.PrepareNewGame()", "Added " + addedCelebs + " additional celebrity persons for custom production.", LOG_DEBUG)
		else
			TLogger.Log("Game.PrepareNewGame()", "No need to add additional celebrity persons for custom production. Found enough.", LOG_DEBUG)
		endif


		'=== MOVIE AGENCY ===
		TLogger.Log("Game.PrepareNewGame()", "initializing movie agency", LOG_DEBUG)
		'shuffle programme licences offer lists - so each game starts 
		'with a varying set of licences
		RoomHandler_MovieAgency.GetInstance().OfferPlanShuffle()
		
		'create series/movies in movie agency
		RoomHandler_MovieAgency.GetInstance().ReFillBlocks()

		'8 auctionable movies/series
		For Local i:Int = 0 To 7
			New TAuctionProgrammeBlocks.Create(i, Null)
		Next


		'=== NEWS AGENCY ===
		TLogger.Log("Game.PrepareNewGame()", "initializing news agency", LOG_DEBUG)
		
		GetNewsEventCollection().ScheduleTimedInitialNews()
		'create 3 random news happened some time before today ...
		'Limit to CurrentAffairs as this is the starting abonnement of
		'all players
		GetNewsAgency().AnnounceNewNewsEvent(TVTNewsGenre.CURRENTAFFAIRS, - int((60 + RandRange(0,60)) * TWorldTime.MINUTELENGTH), True, False, False)
		GetNewsAgency().AnnounceNewNewsEvent(TVTNewsGenre.CURRENTAFFAIRS, - int((60 + RandRange(60,100)) * TWorldTime.MINUTELENGTH), True, False, False)
		'this is added to the "left side" (> 2,5h)
		GetNewsAgency().AnnounceNewNewsEvent(TVTNewsGenre.CURRENTAFFAIRS, - int((120 + RandRange(31,60)) * TWorldTime.MINUTELENGTH), True, False, False)
		'create a random for each news
		'for local i:int = 0 until TVTNewsGenre.count
		'	GetNewsAgency().AnnounceNewNewsEvent(i, - (120 + RandRange(31,60)) * TWorldTime.MINUTELENGTH, True, False, False)
		'Next

		'create 3 starting news with random genre (for starting news show)
		Local newsCount:Int = 3
		Local newsGenres:Int[] = RandRangeArray(0, TVTNewsGenre.count - 1, newsCount)
		For Local i:Int = 0 Until newsCount
			Local newsEvent:TNewsEvent = GetNewsAgency().GenerateNewNewsEvent(newsGenres[i])
			If newsEvent
				' time must be lower than for the "current affairs" news
				' (which are the default subscription) so they are
				' recognizeable as the most recent ones
				Local adjustMinutes:Int = - RandRange(0, 60) * TWorldTime.MINUTELENGTH
				newsEvent.doHappen( GetWorldTime().GetTimeGone() + adjustMinutes )
			EndIf
		Next


		'adjust next ticker times to something right after game start
		'(or a bit before)
		For Local i:Int = 0 Until TVTNewsGenre.count
			GetNewsAgency().SetNextEventTime(i, GetWorldTime().GetTimeGone() + RandRange(5, 90) * TWorldTime.MINUTELENGTH)
		Next


		'first create basics (player, finances, stationmap)
		For Local playerID:Int = 1 To 4
			PreparePlayerStep1(playerID, False)
		Next
		'then prepare plan, news abonnements, ...
		'this is needed because adcontracts use average reach of
		'stationmaps on sign - which needs 4 stationmaps to be "set up"
		For Local playerID:Int = 1 To 4
			PreparePlayerStep2(playerID)
		Next


		For Local playerID:Int = 1 To 4
			StartPlayer(playerID)
		Next


		'=== CREATE TIMED NEWSEVENTS ===
		'Creates all newsevents with fixed times in the future
		GetNewsAgency().CreateTimedNewsEvents()
		
		
		'=== CREATE PROGRAMME PRODUCERS ===
		'Creates various programme producers (sport live programme,
		'custom produced movies and series ...)
		GenerateStartProgrammeProducers()


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
		Local room:TRoom = Null
		Local roomMap:TMap = TMap(GetRegistry().Get("rooms"))
		If Not roomMap Then Throw("ERROR: no room definition loaded!")

		'remove all previous rooms
		GetRoomCollection().Initialize()
		'and their doors
		GetRoomDoorBaseCollection().Initialize()


		For Local vars:TData = EachIn roomMap.Values()
			'==== ROOM ====
			Local room:TRoom = New TRoom
			room.Init(..
				vars.GetString("roomname"),  ..
				[ ..
					vars.GetString("tooltip"), ..
					vars.GetString("tooltip2") ..
				], ..
				vars.GetInt("owner",-1),  ..
				vars.GetInt("size", 1)  ..
			)
			room.flags = vars.GetInt("flags", 0)
			room.SetScreenName( vars.GetString("screen") )

			'only add if not already there
			If Not GetRoomCollection().Get(room.id)
				GetRoomCollection().Add(room)
			Else
				room = GetRoomCollection().Get(room.id)
			EndIf

			'==== DOOR ====
			'no door for the artificial room "building"
			'if vars.GetString("roomname") <> "building"
			Local doors:TObjectList = TObjectList(vars.Get("doors"))
			If doors
				For local doorConfig:TData = EachIn doors
					Local door:TRoomDoor = New TRoomDoor
					door.Init(..
						room.id,..
						doorConfig.GetInt("doorSlot"), ..
						doorConfig.GetInt("onFloor"), ..
						doorConfig.GetInt("doortype") ..
					)

					GetRoomDoorBaseCollection().Add( door )
					'add the door to the building (sets parent etc)
					GetBuilding().AddDoor(door)

					'override defaults
					If doorConfig.GetInt("width") > 0 Then door.area.SetW( doorConfig.GetInt("width") )
					If doorConfig.GetInt("height") > 0 Then door.area.SetH( doorConfig.GetInt("height") )
					door.stopOffset = doorConfig.GetInt("stopOffset", 0)
					door.doorFlags = doorConfig.GetInt("doorFlags", 0)
					'move these doors outside so they do not overlap with the "porter"
					If doorConfig.GetInt("doorType") = -1 Then door.area.SetX(-1000 - room.id * door.area.w)
					'allow overriding door positions
					If doorConfig.GetInt("x",-1000) <> -1000 Then door.area.SetX(doorConfig.GetInt("x"))
				Next
			EndIf


			'==== HOTSPOTS ====
			Local hotSpots:TList = TList( vars.Get("hotspots") )
			If hotSpots
				For Local conf:TData = EachIn hotSpots
					Local name:String 	= conf.GetString("name")
					Local x:Int			= conf.GetInt("x", -1)
					Local y:Int			= conf.GetInt("y", -1)
					Local bottomy:Int	= conf.GetInt("bottomy", 0)
					'the "building"-room uses floors
					Local f:Int         = conf.GetInt("floor", -1)
					Local width:Int 	= conf.GetInt("width", 0)
					Local height:Int 	= conf.GetInt("height", 0)
					Local tooltipText:String	 	= conf.GetString("tooltiptext")
					Local tooltipDescription:String	= conf.GetString("tooltipdescription")

					'align at bottom of floor
					If f >= 0 Then y = TBuilding.GetFloorY2(f) - height

					Local hotspot:THotspot = New THotspot.Create( name, x, y - bottomy, width, height)
					hotspot.setTooltipText( GetLocale(tooltipText), GetLocale(tooltipDescription) )

					room.addHotspot( hotspot )
				Next
			EndIf

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

			StartTipWindow = New TGUIGameModalWindow.Create(New SVec2I(0,0), New SVec2I(400,350), "InGame")
			StartTipWindow.screenArea = New TRectangle.Init(0,0,800,385)
			StartTipWindow.DarkenedArea = New TRectangle.Init(0,0,800,385)
			StartTipWindow.SetCaptionAndValue( tip[0], tip[1] )
			StartTipWindow.Open()
		EndIf
	End Function
	
	
	Method GenerateStartProgrammeProducers:Int()
		'cleanup and remove old ones
		GetProgrammeProducerCollection().GetInstance().Initialize()
		
		'if there is only ONE producer for special stuff - add this way
		GetProgrammeProducerCollection().Add( TProgrammeProducerSport.GetInstance().Initialize() )
		TLogger.Log("PrepareNewGame()", "Generated sport programme producer (id=" + TProgrammeProducerSport.GetInstance().id+").", LOG_DEBUG)
		'GetProgrammeProducerCollection().Add( TProgrammeProducerMorningShows.GetInstance().Initialize() )
		'TLogger.Log("PrepareNewGame()", "Generated morning show programme producer.", LOG_DEBUG)

		'movie/series producers exist with different characteristics/budgets
		For local i:int = 0 to (GameRules.devConfig.GetInt("DEV_PRODUCERS_COUNT", 4) - 1)
			Local p:TProgrammeProducer = new TProgrammeProducer
			p.countryCode = GetProgrammeProducerCollection().GenerateRandomCountryCode()
			p.name = GetProgrammeProducerCollection().GenerateRandomName()
			p.RandomizeCharacteristics()
			GetProgrammeProducerCollection().Add( p )
			TLogger.Log("PrepareNewGame()", "Generated programme producer ~q"+p.name+"~q (id="+p.id+") from ~q"+p.countryCode+"~q with budget of " + p.budget + " and an experience of " + p.experience +"/100. First production at " + GetWorldTime().GetFormattedGameDate(p.nextProductionTime)+".", LOG_DEBUG)
		Next
	End Method


	Method GenerateStartAdContracts:Int()
		startAdContractBaseGUIDs = startAdContractBaseGUIDs[..3]
		startAdContractBaseGUIDs[0] = "ronny-ad-startad-bmxng"
		startAdContractBaseGUIDs[1] = "ronny-ad-startad-gamezworld"
		startAdContractBaseGUIDs[2] = "ronny-ad-startad-digidea"


		'assign a random one, if the predefined ones are missing

		Rem
		'OLD - only useable for "completely random contracts"
		'remove invalidated/obsolete/no-longer-available entries
		For local i:int = 0 until startAdContractBaseGUIDs.length
			local adContractBase:TAdContractBase = GetAdContractBaseCollection().GetByGUID(startAdContractBaseGUIDs[i])
			if adContractBase and not adContractBase.IsAvailable()
				startAdContractBaseGUIDs[i] = null
			endif
		Next
		end rem


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
		'the game rules value is defining how many simultaneously are allowed
		'while the filter filters contracts already having that much (or
		'more) contracts, that's why we subtract 1
		Local limitInstances:Int = GameRules.adContractInstancesMax
		If limitInstances > 0 Then cheapFilter.SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		Local addContract:TAdContractBase
		For Local i:Int = 0 Until startAdContractBaseGUIDs.length
			'already assigned (and available - others are already removed)
			If startAdContractBaseGUIDs[i] And GetAdContractBaseCollection().GetByGUID(startAdContractBaseGUIDs[i]) Then Continue

			If i < startAdContractBaseGUIDs.length-1
				addContract = GetAdContractBaseCollection().GetRandomNormalByFilter(cheapFilter, False)
			Else
				'and one with 0-1% audience requirement
				cheapFilter.SetAudience(0.015, 0.03)
				addContract = GetAdContractBaseCollection().GetRandomNormalByFilter(cheapFilter, False)
				If Not addContract
					Print "GenerateStartAdContracts: No ~qno audience~q contract in DB? Trying a 1.5-4% one..."
					cheapFilter.SetAudience(0.015, 0.04)
					addContract = GetAdContractBaseCollection().GetRandomNormalByFilter(cheapFilter, False)
					If Not addContract
						Print "GenerateStartAdContracts: 1.5-4% failed too... using random contract now."
						addContract = GetAdContractBaseCollection().GetRandomNormalByFilter(cheapFilter, True)
					EndIf
				EndIf
			EndIf

			If Not addContract
				Print "GenerateStartAdContracts: GetAdContractBaseCollection().GetRandomNormalByFilter failed! Skipping contract ..."
				Continue
			EndIf
			startAdContractBaseGUIDs[i] = addContract.GetGUID()

			'mark this ad as used
			If limitInstances <> 0
				cheapFilter.AddForbiddenContractGUID(addContract.GetGUID())
			EndIf
		Next

		'override with DEV.xml
		For Local i:Int = 0 Until startAdContractBaseGUIDs.length
			Local guid:String = GameRules.devConfig.GetString("DEV_STARTPROGRAMME_AD"+(i+1)+"_GUID", "")
			If guid = "" Then Continue

			Local devAd:TAdContractBase = GetAdContractBaseCollection().GetByGUID(guid)
			'only override if the ad exists
			If devAd Then startAdContractBaseGUIDs[i] = devAd.GetGUID()
		Next
	End Method


	'run when loading starts
	Function onSaveGameBeginLoad:Int(triggerEvent:TEventBase)
		'if not done yet: run preparation for first game
		'(eg. if loading is done from mainmenu)
		PrepareFirstGameStart(False)

		'remove all old messages
		GetToastMessageCollection().RemoveAllMessages()
	End Function


	'run when loading finished
	Function onSaveGameLoad:Int(triggerEvent:TEventBase)
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

		'SAVEGAMEREPAIR (TVTower v0.7)
		'older savegames might contain orphaned production concepts
		Local removedOrphans:Int = RemoveOrphanedProductionConcepts()
		if removedOrphans > 0
			TLogger.Log("Game.OnSaveGameLoad", "Removed " + removedOrphans + " orphaned productionconcept elements.", LOG_DEBUG)
		endif
	End Function


	Function RemoveOrphanedProductionConcepts:Int()
		'broken savegames might contain productionConcepts which are no
		'longer stored in the player's collections, but are still unproduced
		'and in the concept collection
		'-> remove these orphans
		Local orphans:TProductionConcept[]
		For local pc:TProductionConcept = EachIn GetProductionConceptCollection().entries.Values()
			'keep produced concepts for later lookups
			if pc.IsProductionFinished() continue
			
			local isOrphan:Int = True
			For local obj:TPlayerProgrammeCollection = eachin GetPlayerProgrammeCollectionCollection().plans
				if obj.HasProductionConcept(pc)
					isOrphan = False
					exit
				endif
			Next
			if isOrphan then orphans :+ [pc]
		Next
		

		For local pc:TProductionConcept = EachIn orphans
			GetProductionConceptCollection().Remove(pc)
		Next
		Return orphans.length
	End Function


	'run when starting saving a savegame
	Function onSaveGameBeginSave:Int(triggerEvent:TEventBase)
		TLogger.Log("TGame", "Start saving - inform AI.", LOG_DEBUG | LOG_SAVELOAD)

		'wait for all AIs to have finished with their events
		'TODO: still enqueued events for paused AIs ... what to do with them?
		'for now we ignore queued events if ais is paused ..
		If not GetGame().IsPaused() and TAIBase.airunning
			local allDone:Int
			Local t:Int = Millisecs()
			Repeat
				allDone = True
				For Local player:TPlayer = EachIn GetPlayerCollection().players
					If player.isLocalAI()
						if player.PlayerAI.GetNextEventCount() > 0
							print "waiting for player: " + player.playerID +"  events:"  + player.PlayerAI.GetNextEventCount() + "   " + GetWorldTime().GetFormattedGameDate()
							'LockMutex(player.PlayerAI._eventQueueMutex)
							'for local ev:TAIEvent = EachIn player.PlayerAI.eventQueue
							'	print " - event.id="+ev.id + "  " + ev.GetName()
							'Next
							'UnlockMutex(player.PlayerAI._eventQueueMutex)

							allDone = False
						endif
					EndIf
				Next
				if Millisecs() - t > 5000
					For Local player:TPlayer = EachIn GetPlayerCollection().players
						If player.isLocalAI() 
							if player.PlayerAI.GetNextEventCount() > 0
								print "AI " + player.playerID + " stalled."
								print "--------------------------------------------"
								DebugStop
							endif
						endif
					Next
					'end application for now
					'Notify("AI stalled ... something is wrong! Exiting application.")
					'end
					
					'inform save process of fail state
					triggerEvent.SetVeto(True)
					triggerEvent.GetData().AddString("vetoReason", "AI did not react quick enough.")
					Return False
				endif
				If not allDone then delay(100)
			Until allDone
		EndIf
		
		'inform player AI that we are saving now
		For Local player:TPlayer = EachIn GetPlayerCollection().players
			If player.isLocalAI() Then player.PlayerAI.CallOnSave()
		Next
	End Function

	'run when financial balance of a player changes
	Function onPlayerChangeMoney:Int(triggerEvent:TEventBase)
		Local finance:TPlayerFinance = TPlayerFinance(triggerEvent.GetSender())
		If Not finance Then Return False

		Local playerID:Int = finance.playerID
		If finance.GetMoney() < 0 And GetGame().GetPlayerBankruptLevel(playerID) = 0
			GetGame().SetPlayerBankruptLevel(playerID, 1, -1)
		ElseIf finance.GetMoney() >= 0 And GetGame().GetPlayerBankruptLevel(playerID) <> 0
			GetGame().SetPlayerBankruptLevel(playerID, 0, -1)
		EndIf
	End Function


	'override
	Method SetPlayerBankruptLevel:Int(playerID:Int, level:Int, time:Long = -1)
		If Not Super.SetPlayerBankruptLevel(playerID, level) Then Return False

		If time = -1 Then time = GetWorldTime().GetTimeGone()
		playerBankruptLevelTime[playerID -1] = time

		TriggerBaseEvent(GameEventKeys.Game_SetPlayerBankruptLevel, New TData.AddInt("playerID", playerID) )

		Return True
	End Method


	Method SetPaused(bool:Int=False)
		local changed:int = bool <> GetWorldTime().IsPaused()
		
		GetWorldTime().SetPaused(bool)
		GetBuildingTime().SetPaused(bool)
		
		if changed
			if bool
				TriggerBaseEvent(GameEventKeys.Game_OnPause)
			else
				TriggerBaseEvent(GameEventKeys.Game_OnResume)
			endif
		EndIf
			
	End Method


	Method IsPaused:Int() override
		Return GetWorldTime().IsPaused()
	End Method


	'override
	'computes daily costs like station or newsagency fees for every player
	Method ComputeDailyCosts(day:Int)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			Local finance:TPlayerFinance = Player.GetFinance(day)
			If Not finance Then Throw "ComputeDailyCosts failed: finance = null."
			
			Local map:TStationMap = GetStationMap(Player.playerID)
			If Not map Then Throw "ComputeDailyCosts failed: map = null."
			'stationfees
			finance.PayStationFees( map.CalculateStationCosts() )
			'interest rate for your current credit
			finance.PayCreditInterest( finance.GetCreditInterest() )
			'newsagencyfees
			finance.PayNewsAgencies(Player.GetTotalNewsAbonnementFees())
			'room rental costs
			For Local r:TRoomBase = EachIn GetRoomBaseCollection().list
				If r.GetOwner() <> Player.playerID Then Continue
				'ignore freeholds
				If r.IsFreehold() Then Continue
				'we use GetRent() here as a rented room returns the
				'"agreed rent" already (which includes difficulty)
				Local rent:Int = r.GetRent()
				If rent > 0 Then finance.PayRent(rent, r)
			Next
		Next
	End Method


	'computes daily income like account interest income
	Method ComputeDailyIncome(day:Int)
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			Local finance:TPlayerFinance = Player.GetFinance()
			If Not finance Then Throw "ComputeDailyIncome failed: finance = null."

			If finance.money > 0
				finance.EarnBalanceInterest( Long(finance.money * Player.getDifficulty().interestRatePositiveBalance) )
			Else
				'attention: multiply current money * -1 to make the
				'negative value an "positive one" - a "positive expense"
				finance.PayDrawingCreditInterest( Long(-1 * finance.money * Player.getDifficulty().interestRateNegativeBalance) )
			EndIf
		Next
	End Method


	'computes penalties for expired ad-contracts
	Method ComputeContractPenalties(day:Int)
		Local obsoleteContracts:TAdContract[]
		'add all obsolete contracts to an array to avoid concurrent
		'modification
		For Local Player:TPlayer = EachIn GetPlayerCollection().players
			For Local Contract:TAdContract = EachIn Player.GetProgrammeCollection().adContracts
				If Not contract Then Continue

				'0 days = "today", -1 days = ended
				If contract.GetDaysLeft() < 0
					'inform contract
					contract.Fail(GetWorldTime().GetTimeGoneForGameTime(0, day, 0, 0))

					obsoleteContracts :+ [contract]
				EndIf
			Next
		Next

		'remove all obsolete contracts
		For Local c:TAdContract = EachIn obsoleteContracts
			GetPlayerProgrammeCollection(c.owner).RemoveAdContract(c)
		Next
	End Method


	'creates the default players (as shown in game-settings-screen)
	Method CreateInitialPlayers()
		'skip if already done
		If GetPlayer(1) Then Return

		'create players, draws playerfigures on figures-image
		'TColor.GetByOwner -> get first unused color,
		'TPlayer.Create sets owner of the color
		local c1:TPlayerColor = TPlayerColor.getByOwner(0)
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
				ScreenCollection.GoToScreen(Null,"MainMenu", True)
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
					ScreenCollection.GoToScreen(ScreenCollection.GetCurrentScreen())
				Else
					ScreenCollection.GoToScreen(GameScreen_world)
				EndIf
		EndSelect


		'remove focus of gui objects
		GuiManager.ResetFocus()
		GuiManager.SetKeyboardInputReceiver(Null)


		'reset mouse clicks
		MouseManager.ResetClicked(1)
		MouseManager.ResetClicked(2)


		Self.gamestate = gamestate
	End Method


	Method GetObservedFigure:TFigureBase()
		If Not TFigureBase(GameConfig.GetObservedObject())
			Return GetPlayerBase().GetFigure()
		Else
			Return TFigureBase(GameConfig.GetObservedObject())
		EndIf
	End Method

Rem
	Method SwitchPlayer:int(newID:int, oldID:Int=-1)
		if oldID = -1 then oldID = GetPlayerBaseCollection().playerID
		if newID = oldID
			print "SwitchLocalPlayer() skipped: switching with itself"
			return False
		EndIf
		local playerNew:TPlayer = GetPlayer(newID)
		local playerOld:TPlayer = GetPlayer(oldID)

		GetPlayerCollection().Set(newID, playerOld)
		GetPlayerCollection().Set(oldID, playerNew)

		local figureNew:TFigureBase = playerNew.figure
		local figureOld:TFigureBase = playerOld.figure
'		playerNew.figure = figureOld
'		playerOld.figure = figureNew
		playerNew.figure.playerID = playerNew.playerID
		playerOld.figure.playerID = playerOld.playerID

		local oldIsLocalHuman:int = playerOld.IsLocalHuman()
		local newIsLocalHuman:int = playerNew.IsLocalHuman()
		local oldIsLocalAI:int = playerOld.IsLocalAI()
		local newIsLocalAI:int = playerNew.IsLocalAI()

		if oldIsLocalHuman
			playerNew.SetLocalHumanControlled()
			playerOld.SetLocalAIControlled()
		elseif newIsLocalHuman
			playerNew.SetLocalAIControlled()
			playerOld.SetLocalHumanControlled()
		endif
		return True
	End Method
endrem

	Method SwitchPlayerIdentity:Int(ID1:Int, ID2:Int)
		If ID1 = ID2
			Print "SwitchPlayerIdentity() skipped: switching with itself"
			Return False
		EndIf
		local player1:TPlayer = GetPlayer(ID1)
		local player2:TPlayer = GetPlayer(ID2)

		Local tmpPlayerName:String = player2.name
		Local tmpChannelName:String = player2.channelName
		Local tmpFigureBase:Int = player2.figureBase
		local tmpPlayerColor:TPlayerColor = player2.color
		local tmpPlayerDifficulty:String = player2.difficultyGUID

		player2.name = player1.name
		player2.channelName = player1.channelName
		player2.figureBase = player1.figureBase
		player2.color = player1.color
		player2.color.SetOwner(ID2)
		player2.difficultyGUID = player1.difficultyGUID

		player1.name = tmpPlayerName
		player1.channelName = tmpChannelName
		player1.figureBase = tmpFigureBase
		player1.color = tmpPlayerColor
		player1.color.SetOwner(ID1)
		player1.difficultyGUID = tmpPlayerDifficulty

		Return True
	End Method


	'select player in start menu
	Method SetLocalPlayer:Int(ID:Int=-1)
		'skip if already done
		If GetPlayerCollection().playerID = ID
			Print "SetLocalPlayer() skipped: already set"
			Return False
		EndIf

		Local oldID:Int = GetPlayerCollection().playerID
		Local playerNew:TPlayer = GetPlayer(ID)
		Local playerOld:TPlayer = GetPlayer()


		Local oldIsLocalHuman:Int = playerOld.IsLocalHuman()
		Local newIsLocalHuman:Int = playerNew.IsLocalHuman()
		Local oldIsLocalAI:Int = playerOld.IsLocalAI()
		Local newIsLocalAI:Int = playerNew.IsLocalAI()

		If oldIsLocalHuman
			playerNew.SetLocalHumanControlled()
			playerOld.SetLocalAIControlled()
		ElseIf newIsLocalHuman
			playerNew.SetLocalAIControlled()
			playerOld.SetLocalHumanControlled()
		EndIf

'		GetPlayer(ID).SetLocalHumanControlled()
'		GetPlayer(oldID).SetLocalAIControlled()

		SetActivePlayer(ID)
		Return True
	End Method


	'sets the player controlled by this client
	Method SetActivePlayer(ID:Int=-1)
		If ID = -1 Then ID = GetPlayerCollection().playerID

		Local oldPlayerID:Int = GetPlayerCollection().playerID

		'for debug purposes we need to adjust more than just
		'the playerID.
		GetPlayerCollection().playerID = ID
		'also set this information for the boss collection (avoids
		'circular references)
		GetPlayerBossCollection().playerID = ID

		TriggerBaseEvent(GameEventKeys.Game_onSetActivePlayer, New TData.AddInt("playerID", ID).AddInt("oldPlayerID", oldPlayerID) )

		'get currently shown screen of that player
		If Self.gamestate = TGame.STATE_RUNNING
			If GetPlayer().GetFigure().inRoom And Not GameConfig.highSpeedObservation
				ScreenCollection.GoToScreen(ScreenCollection.GetScreen(GetPlayer().GetFigure().inRoom.GetScreenName()))
			'go to building
			Else
				ScreenCollection.GoToScreen(GameScreen_World)
			EndIf
		EndIf
	End Method


	Function SendSystemMessage:Int(message:String)
		'send out to chats
		TriggerBaseEvent(GameEventKeys.Chat_OnAddEntry, New TData.AddInt("senderID", -1).AddInt("channels", CHAT_CHANNEL_SYSTEM).AddString("senderName", "SYSTEM").AddString("text", message) )
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


	Method CalculateAudienceWeatherMod:Float()
		'skip redirection over GetGameModiferManager() if possible
		'(eg. if we just want to manipulate the value without time-
		' constraints)

		Local weather:TWorldWeatherEntry = GetWorld().Weather.GetCurrentWeather()
		Local hour:Int = GetWorldTime().GetHour()


		'WEATHER
		'TODO: country/map dependend ("no" snow in Africa ;-))
		'      maybe add "minTemp" and "maxTemp" so we know if it is "cold"
		'      or rather "warm", etc.
		Local weatherMod:Float = 1.0
		'up to 10% change by temperature
		'hot temperatures make people go out (<=20°C = 0% change, >=40°C = 100%)
		weatherMod :- 0.1 * 0.05*MathHelper.Clamp(weather.GetTemperature()-20, 0, 20)
		'cold temperatures make people stay at home (<=-20°C = 100% change, >=5°C = 0%)
		weatherMod :+ 0.1 * 0.04*Abs(MathHelper.Clamp(weather.GetTemperature()-5, -25, 0))
		'winds make people stay at home (speeds from 0-4), ignore 0-1
		weatherMod :+ 0.05 * 0.25*Abs(MathHelper.Clamp(weather.GetWindSpeed()-1, 0, 4))


		'rain makes people stay at home (rain levels = 0-3 = 0-100%)
		'levels 4 and 5 are "storming"
		weatherMod :+ 0.1 * 0.33*weather.IsRaining()

		'===
		'current weatherMod ranges:
		'0.9 - 1.15


		'during night weather does nearly not influence people (they do
		'not go out ...)
		'TODO: weekends + teenagers
		Local weatherModDayTimeWeighting:Float = 1.0
		If hour >= 23 Or hour <= 8
			weatherModDayTimeWeighting = 0.25
		ElseIf hour >= 22 Or hour <= 9
			weatherModDayTimeWeighting = 0.6
		ElseIf hour >= 21 Or hour <= 10
			weatherModDayTimeWeighting = 0.85
		EndIf

		weatherMod :* weatherModDayTimeWeighting + 1.0*(1.0-weatherModDayTimeWeighting)


		'storm makes people stay at home AND POWER OFF electric devices
		'(storm levels = 0-2 = 0-100%)
		'attention: storming includes raining!
		'people put off plugs regardless of day time - so modify
		'after having done the weighting
		weatherMod :- 0.1 * 0.50*weather.IsStorming()

		Return weatherMod
	End Method


	Method CalculateStationMapReceptionWeatherMod:Float(stationType:Int)
		'WEATHER-STATION-RECEPTION
		'bad weather conditions might influence how good a reception type
		'rain and storms make satellite/antenna signals weak
		'clouds make satellite signals weak

		Local weather:TWorldWeatherEntry = GetWorld().Weather.GetCurrentWeather()
		Local weatherMod:Float = 1.0

		Select stationType
			Case TVTStationType.ANTENNA, TVTStationType.SATELLITE_UPLINK
				'storming = 0-2 / 0-100%
				weatherMod :- 0.1 * 0.50*weather.IsStorming()

				'rain makes reception worse (raining 0-5)
				'-> 25*0.04 = 1.0 (0, 0.04, 0.16, 0.36,...)
				weatherMod :- 0.15 * 0.04*(weather.IsRaining()^2)

				'clouds make reception worse (okta 0-8)
				weatherMod :- 0.1 * 0.125 * weather.GetCloudOkta()

			Case TVTStationType.CABLE_NETWORK_UPLINK
				'no influence
		End Select

		'===
		'current weatherMod ranges
		'0.75 - 1.0

		Return weatherMod
	End Method


	Method CalculateStationMapAntennaReceptionWeatherMod:Float()
		Return CalculateStationMapReceptionWeatherMod(TVTStationType.ANTENNA)
	End Method


	Method CalculateStationMapCableNetworkReceptionWeatherMod:Float()
		Return CalculateStationMapReceptionWeatherMod(TVTStationType.CABLE_NETWORK_UPLINK)
	End Method


	Method CalculateStationMapSatelliteReceptionWeatherMod:Float()
		Return CalculateStationMapReceptionWeatherMod(TVTStationType.SATELLITE_UPLINK)
	End Method


	'update basic game modifiers
	'basic modifiers are not modified by external code (use custom
	'modifiers and keys for this stuff)
	'- weather (without extras like tornado-news, ...)
	Method UpdateBaseGameModifiers()
		'WEATHER-AUDIENCE
		GameConfig.SetModifier(modKeyStationMap_Audience_WeatherModLS, CalculateAudienceWeatherMod())

		'WEATHER-STATION-RECEPTION
		GameConfig.SetModifier(modKeyStationMap_Reception_AntennaModLS, CalculateStationMapAntennaReceptionWeatherMod())
		GameConfig.SetModifier(modKeyStationMap_Reception_CableNetworkModLS, CalculateStationMapCableNetworkReceptionWeatherMod())
		GameConfig.SetModifier(modKeyStationMap_Reception_SatelliteModLS, CalculateStationMapSatelliteReceptionWeatherMod())
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
		If Not GetGame().networkGame
			If GetPlayer().IsInRoom() 'and not GetPlayer().GetFigure().IsInBuilding()
				If TEntity.globalWorldSpeedFactorMod <> GameConfig.InRoomTimeSlowDownMod
					GetWorldTime().SetTimeFactorMod(GameConfig.InRoomTimeSlowDownMod)
					TEntity.globalWorldSpeedFactorMod = GameConfig.InRoomTimeSlowDownMod
				EndIf
			Else
				If TEntity.globalWorldSpeedFactorMod <> 1.0
					GetWorldTime().SetTimeFactorMod(1.0)
					TEntity.globalWorldSpeedFactorMod = 1.0
				EndIf
			EndIf
		EndIf


		'=== REALTIME GONE CHECK ===
		'checks if at least 1 second is gone since the last call
		If lastTimeRealTimeSecondGone = 0 Then lastTimeRealTimeSecondGone = Time.GetTimeGone()
		If Time.GetTimeGone() - lastTimeRealTimeSecondGone > 1000
			'event passes milliseconds gone since last call
			'so if hickups made the game stop for 4.3 seconds, this value
			'will be about 4300. Maybe AI wants this information.
			TriggerBaseEvent(GameEventKeys.Game_OnRealTimeSecond, New TData.AddLong("timeGoneSinceLastRTS", Time.GetTimeGone()-lastTimeRealTimeSecondGone).AddLong("gameTimeGone", WorldTime.GetTimeGone()))
			lastTimeRealTimeSecondGone = Time.GetTimeGone()
		EndIf



		'init if not done yet
		If lastTimeMinuteGone = 0 Then lastTimeMinuteGone = worldTime.GetTimeGone()

		'==== HANDLE IN GAME TIME ====
		'less than a ingame minute gone? nothing to do YET
		If worldTime.GetTimeGone() - lastTimeMinuteGone < TWorldTime.MINUTELENGTH Then Return

		'==== HANDLE GONE/SKIPPED MINUTES ====
		'if speed is to high - minutes might get skipped,
		'handle this case so nothing gets lost.
		'missedMinutes is >1 in all cases (else this part isn't run)
		Local missedMilliseconds:Long = (worldTime.GetTimeGone() - lastTimeMinuteGone)
		Local missedSeconds:Int = missedMilliseconds / 1000
		Local missedMinutes:Int = missedMilliseconds / TWorldTime.MINUTELENGTH
		Local daysMissed:Int = missedMilliseconds / TWorldTime.DAYLENGTH

		'adjust the game time so GetWorldTime().GetDayHour()/Minute/...
		'return the correct value for each loop cycle. So Functions can
		'rely on that functions to get the time they request.
		'as everything can get calculated using "timeGone", no further
		'adjustments have to take place
		worldTime._timeGone :- missedMilliseconds

		For Local i:Int = 1 To missedMinutes
			'add back another gone minute each loop
			worldTime._timeGone :+ TWorldTime.MINUTELENGTH

			'day
			If worldTime.GetDayHour() = 0 And worldTime.GetDayMinute() = 0
				'year
				If worldTime.GetDayOfYear() = 1
					TriggerBaseEvent(GameEventKeys.Game_OnYear, New TData.AddLong("time", worldTime.GetTimeGone()))
				EndIf

				TriggerBaseEvent(GameEventKeys.Game_OnDay, New TData.AddLong("time", worldTime.GetTimeGone()))
			EndIf

			'hour
			If worldTime.GetDayMinute() = 0
				TriggerBaseEvent(GameEventKeys.Game_OnHour, New TData.AddLong("time", worldTime.GetTimeGone()))

				'reset availableNewsEventList - maybe this hour made some
				'more news available
				GetNewsEventTemplateCollection()._InvalidateUnusedAvailableInitialTemplates()
			EndIf

			'minute
			TriggerBaseEvent(GameEventKeys.Game_OnMinute, New TData.AddLong("time", worldTime.GetTimeGone()))
		Next

		'reset time of last minute so next update can calculate missed minutes
		lastTimeMinuteGone = worldTime.GetTimeGone()
		'add back remainder (what did not fit into a single minute..)
		worldTime._timeGone :+ (missedMilliseconds - missedMinutes * TWorldTime.MINUTELENGTH)
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetGame:TGame()
	Return TGame.GetInstance()
End Function
