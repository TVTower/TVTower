SuperStrict
'to access players current financial situation
Import "game.player.finance.bmx"
'to recognize players broadcasts in events
Import "game.player.programmeplan.bmx"
'to be able to send out toastmessages
Import "game.toastmessage.bmx"
'to access room data
Import "game.room.base.bmx"
'to access player data
Import "game.player.base.bmx"
'to access game rules
Import "game.gamerules.bmx"
'for ingame dialogues
Import "common.misc.dialogue.bmx"
'to access parent of adcontract
Import "game.gameobject.bmx"
'to access awards
Import "game.award.base.bmx"


Type TPlayerBossCollection
	Field bosses:TPlayerBoss[4]
	'playerID of player who sits in front of the screen
	'adjust this TOO when switching players
	Field playerID:Int = 1

	Global _eventListeners:TEventListenerBase[]
	Global _instance:TPlayerBossCollection


	Function GetInstance:TPlayerBossCollection()
		if not _instance then _instance = new TPlayerBossCollection
		return _instance
	End Function


	Method Initialize:int()

		'=== EVENTS ===
		'remove old listeners
		EventManager.UnregisterListenersArray(_eventListeners)

		'register new listeners
		_eventListeners = new TEventListenerBase[0]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Broadcast_Common_FinishBroadcasting, onFinishBroadcasting) ]
		'instead of updating the boss way to often, we update bosses
		'once a ingame minute
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnMinute, onGameMinute) ]
		'react to our player starting (or restarting...)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnStartPlayer, onPlayerStarts) ]

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.AdContract_OnFinish, onFinishOrFailAdContract) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.AdContract_OnFail, onFinishOrFailAdContract) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Room_OnBombExplosion, onBombExplosion) ]

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Player_OnBeginEnterRoom, onPlayerBeginEnterRoom) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Player_OnLeaveRoom, onPlayerLeaveRoom) ]

		'register dialogue handlers
		_eventListeners :+ [ EventManager.registerListenerFunction(TPlayerBoss.eventKey_Dialogue_onTakeBossCredit, onDialogueTakeCredit) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(TPlayerBoss.eventKey_Dialogue_onRepayBossCredit, onDialogueRepayCredit) ]

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Award_OnFinish, onFinishAward) ]
	End Method


	Method Set:int(id:int=-1, boss:TPlayerBoss)
		If id = -1 Then id = playerID
		if id <= 0 Then return False

		If bosses.length < id Then bosses = bosses[..id+1]
		bosses[id-1] = boss

		'inform the boss about the new id
		if boss then boss.playerID = id
	End Method


	Method Get:TPlayerBoss(id:Int=-1)
		If id = -1 Then id = playerID
		If Not IsBoss(id) Then Return Null

		if bosses[id-1] and bosses[id-1].playerID = -1
			bosses[id-1].playerID = id
			TLogger.Log("TPlayerBossCollection.Get()", "Fixed broken playerID for boss #"+id, LOG_DEBUG)
		endif

		Return bosses[id-1]
	End Method


	Method GetCount:Int()
		return bosses.length
	End Method


	Method IsBoss:Int(number:Int)
		Return (number > 0 And number <= bosses.length And bosses[number-1] <> Null)
	End Method


	'=== EVENTS FOR THE BOSSES ===

	Function onGameMinute:Int(triggerEvent:TEventBase)
		local time:Long = triggerEvent.GetData().GetLong("time",-1)
		For local boss:TPlayerBoss = Eachin GetInstance().bosses
			boss.onGameMinute(time)
		Next
	End Function


	Function onFinishOrFailAdContract:Int(triggerEvent:TEventBase)
		local contract:TNamedGameObject = TNamedGameObject(triggerEvent.GetSender())
		if not contract then return False
		local boss:TPlayerBoss = GetPlayerBoss(contract.owner)
		if not boss then return False

		If triggerEvent.GetEventKey() = GameEventKeys.AdContract_OnFinish
			boss.onFinishAdContract(contract)
		elseif triggerEvent.GetEventKey() = GameEventKeys.AdContract_OnFail
			boss.onFailAdContract(contract)
		endif
	End Function


	Function onFinishBroadcasting:Int(triggerEvent:TEventBase)
		local programmePlan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		if not programmePlan then return False

		local boss:TPlayerBoss = GetPlayerBoss(programmePlan.owner)
		if not boss then return False

		local broadcastMaterial:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("broadcastMaterial"))
		local broadcastedAsType:Int = triggerEvent.GetData().GetInt("broadcastedAsType",-1)

		boss.onFinishBroadcasting(broadcastMaterial, broadcastedAsType)
	End Function


	'called as soon as a player leaves the boss' room
	Function onPlayerLeaveRoom:Int(triggerEvent:TEventBase)
		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())
		if not room or room.GetName() <> "boss" then return False

		'only interested in the visit of the player linked to this room
		local player:TPlayerBase = TPlayerBase(triggerEvent.GetSender())
		if not player or room.owner <> player.playerID then return False

		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False

		boss.onPlayerLeaveRoom(player)
	End Function


	'called as soon as a player enters the boss' room
	Function onPlayerBeginEnterRoom:Int(triggerEvent:TEventBase)
		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())
		if not room or room.GetName() <> "boss" then return False

		'only interested in the visit of the player linked to this room
		local player:TPlayerBase = TPlayerBase(triggerEvent.GetSender())
		if not player or room.owner <> player.playerID then return False

		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False

		boss.onPlayerBeginEnterRoom(player)
	End Function


	Function onPlayerStarts:Int(triggerEvent:TEventBase)
		local playerID:int = triggerEvent.GetData().GetInt("playerID", -1)
		if playerID <= 0 then return False

		local boss:TPlayerBoss = GetPlayerBoss( playerID )
		if boss
			boss.InitCreditMaximum()
		endif
	End Function


	'called as soon as a player enters the boss' room
	Function onFinishAward:Int(triggerEvent:TEventBase)
		Local award:TAward = TAward(triggerEvent.GetSender())
		if not award or award.winningPlayerID <= 0 then return False

		local boss:TPlayerBoss = GetPlayerBoss(award.winningPlayerID)
		if not boss then return False

		boss.onWonAward(award)
	End Function


	Function onBombExplosion:Int(triggerEvent:TEventBase)
		Local room:TRoomBase = TRoomBase(triggerEvent.GetSender())
		if not room or room.owner <= 0 or room.GetNameRaw() <> "boss" then return False

		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False

		boss.onBombInOffice()
	End Function


	Function onDialogueTakeCredit:int(triggerEvent:TEventBase)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		GetPlayerBoss().onDialogueTakeCredit(value)
	End Function


	Function onDialogueRepayCredit:int(triggerEvent:TEventBase)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		GetPlayerBoss().onDialogueRepayCredit(value)
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPlayerBossCollection:TPlayerBossCollection()
	Return TPlayerBossCollection.GetInstance()
End Function
'return specific player boss
Function GetPlayerBoss:TPlayerBoss(playerID:int=-1)
	Return TPlayerBossCollection.GetInstance().Get(playerID)
End Function




'class containing information/values for the player's boss
Type TPlayerBoss
	'in which mood is the boss?
	Field mood:Float = 50.0
	'does the player have to visit the boss?
	Field awaitingPlayerVisit:Int = False
	'time the player has to visit the boss
	Field awaitingPlayerVisitTillTime:Long = 0
	'did the player accept and is on his way to the boss?
	Field awaitingPlayerAccepted:Int = False
	'was the player already called (toastmessage for active player)?
	'skip saving this information, so after load the boss calls again
	Field awaitingPlayerCalled:Int = False {nosave}
	Field playerVisitsMe:int = False
	'amount the boss is likely to give the player
	Field creditMaximum:Int	= 600000
	'worth of the channel at start (or restart)
	Field nettoWorthAtBegin:Long = -1

	'in the case of the player sends a favorite movie, this might
	'brighten the mood of the boss
	Field favoriteMovieGUID:String = ""
	'dialogues for each player, each dialogue contains all subjects a
	'boss can talk about
	Field dialogues:TDialogue[4] {nosave}

	Field registeredProgrammeMalfunctions:int = 0
	Field registeredNewsMalfunctions:int = 0
	Field registeredWonAward:int = 0
	Field registeredWonAwardType:int = 0
	Field playerID:int = -1
	
	Global eventKey_Dialogue_onTakeBossCredit:TEventKey = GetEventKey("dialogue.onTakeBossCredit", True)
	Global eventKey_Dialogue_onRepayBossCredit:TEventKey = GetEventKey("dialogue.onRepayBossCredit", True)


	Const MOODADJUSTMENT_BROADCAST_POS1:Float             = 0.075
	Const MOODADJUSTMENT_BROADCAST_POS2:Float             = 0.04
	Const MOODADJUSTMENT_FINISH_CONTRACT:Float            = 0.05
	Const MOODADJUSTMENT_FAIL_CONTRACT:Float              = -0.5
	Const MOODADJUSTMENT_MALFUNCTION_PROGRAMME:Float      = -2.0
	Const MOODADJUSTMENT_MALFUNCTION_PROGRAMME_EACH:Float = -0.5
	Const MOODADJUSTMENT_MALFUNCTION_NEWS:Float           = -1.0
	Const MOODADJUSTMENT_MALFUNCTION_NEWS_EACH:Float      = -0.25
	Const MOODADJUSTMENT_WON_AWARD:Float                  = 2.5
	Const MOODADJUSTMENT_BOMB_IN_BOSS_OFFICE:Float        = -20.0
	Const MOOD_MAX:Float        =100.0
	Const MOOD_EXCITED:Float    =100.0
	Const MOOD_HAPPY:Float      = 90.0
	Const MOOD_FRIENDLY:Float   = 70.0
	Const MOOD_NEUTRAL:Float    = 50.0
	Const MOOD_UNHAPPY:Float    = 30.0
	Const MOOD_UNFRIENDLY:Float = 10.0
	Const MOOD_ANGRY:Float      =  0.0
	Const MOOD_MIN:Float        =  0.0


	Method Initialize:int()
		mood = MOOD_NEUTRAL
		awaitingPlayerVisit = False
		awaitingPlayerVisitTillTime = 0
		awaitingPlayerAccepted = False
		awaitingPlayerCalled = False
		playerVisitsMe = False
		creditMaximum = 600000
		favoriteMovieGUID = ""
		Dialogues = new TDialogue[4]
		registeredProgrammeMalfunctions = 0
		registeredNewsMalfunctions = 0
		registeredWonAward = 0
		registeredWonAwardType = 0
		playerID = -1
	End Method


	Method GetMood:Float()
		return mood
	End Method


	Method GetMoodPercentage:Float()
		return Float(mood) / MOOD_MAX
	End Method


	Method ChangeMood:int(value:Float)
		mood :+ value
		mood = Min(MOOD_MAX, Max(MOOD_MIN, mood))
		return mood
	End Method


	Method IsInMoodOrWorse:int(mood:Float)
		return self.mood <= mood
	End Method

	Method IsInMoodOrBetter:int(mood:Float)
		return self.mood >= mood
	End Method


	Method InitCreditMaximum:int()
		if playerID = -1 then return False

		'store current netto worth to have a base to see worth development
		nettoWorthAtBegin = GetPlayerBase(playerID).GetNettoWorth()

		local difficulty:TPlayerDifficulty = GetPlayerBase(playerID).GetDifficulty()
		creditMaximum = difficulty.creditAvailableOnGameStart
	End Method


	Method UpdateCreditMaximum:int()
		local difficulty:TPlayerDifficulty = GetPlayerBase(playerID).GetDifficulty()

		if nettoWorthAtBegin = -1 then nettoWorthAtBegin = GetPlayerBase(playerID).GetNettoWorth()

		local nettoWorthChange:int = GetPlayerBase(playerID).GetNettoWorth() - nettoWorthAtBegin
		'bonus factor for each 500.000 added netto worth
		'but no more than 5000000
		local nettoWorthBonus:int = Max(0, Min(5000000, difficulty.creditBaseValue * (nettoWorthChange/500000)))

		creditMaximum = difficulty.creditAvailableOnGameStart + nettoWorthBonus
	End Method


	Method GetCreditMaximum:int()
		if isInMoodOrWorse(MOOD_ANGRY) then return 0
		if isInMoodOrWorse(MOOD_UNFRIENDLY) then return 0.25 * creditMaximum
		if isInMoodOrWorse(MOOD_UNHAPPY) then return 0.5 * creditMaximum
		if isInMoodOrWorse(MOOD_NEUTRAL) then return creditMaximum
		if isInMoodOrWorse(MOOD_FRIENDLY) then return 1.25 * creditMaximum
		if isInMoodOrWorse(MOOD_HAPPY) then return 1.5 * creditMaximum
		if isInMoodOrBetter(MOOD_EXCITED) then return 2.0 * creditMaximum

		return creditMaximum
	End Method


	Method GetDialogue:TDialogue(playerID:int)
		if not dialogues or playerID <= 0 or dialogues.length < playerID then return null
		return dialogues[playerID-1]
	End Method


	Method ResetDialogues:int(playerID:int)
		if not GetDialogue(playerID) then return False

		dialogues[playerID-1] = null
		return True
	End Method


	Method GenerateDialogues(visitingPlayerID:int)
		'each array entry is a "topic" the chef could talk about
		Local ChefDialogues:TDialogueTexts[5]
		local text:string

		if visitingPlayerID = playerID
			local isUnfriendly:int = isInMoodOrWorse(MOOD_UNFRIENDLY) or registeredNewsMalfunctions > 0 or registeredProgrammeMalfunctions > 0
			local showDefaultText:int = True

			if isUnfriendly
				text = GetRandomLocale("DIALOGUE_BOSS_MAIN_TITLE_UNFRIENDLY")
			else
				text = GetRandomLocale("DIALOGUE_BOSS_MAIN_TITLE_DEFAULT")
			endif

			'inform about won award
			if registeredWonAward > 0
				local awardName:string = GetLocale("AWARDNAME_" + TVTAwardType.GetAsString(registeredWonAwardType))
				text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_WON_AWARDNAME").Replace("%AWARDNAME%", "|b|"+awardName+"|/b|")
				showDefaultText = False
			endif

			'inform about ending award
			local currentAward:TAward = GetAwardCollection().GetCurrentAward()
			if currentAward and currentAward.GetStartTime() < GetWorldTime().GetTimeGone()
				local awardName:string = GetLocale("AWARDNAME_" + TVTAwardType.GetAsString(currentAward.awardType))
				local awardTimeLeft:int = currentAward.GetEndTime() - GetWorldTime().GetTimeGone()
				if awardTimeLeft >= TWorldTime.DAYLENGTH and awardTimeLeft < 2*TWorldTime.DAYLENGTH
					text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_AWARDNAME_ENDS_TOMORROW").Replace("%AWARDNAME%", "|b|"+awardName+"|/b|")
					showDefaultText = False
				elseif awardTimeLeft >= 0 and awardTimeLeft < 1*TWorldTime.DAYLENGTH
					text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_AWARDNAME_ENDS_TODAY").Replace("%AWARDNAME%", "|b|"+awardName+"|/b|")
					showDefaultText = False
				endif
			endif

			'inform about upcoming award
			local nextAward:TAward = GetAwardCollection().GetNextAward()
			if nextAward
				'print "next Midnight: " + GetWorldTime().GetFormattedGameDate( GetWorldTime().GetNextMidnight() )
				'print nextAward.GetStartTime()+" > "+GetWorldTime().GetNextMidnight()
				'print GetWorldTime().GetDay(nextAward.GetStartTime()) - GetWorldTime().GetDay()
				'starting next day (might be in 2 minutes or 23 hrs), and ending next day
				if GetAwardCollection().GetNextAwardTime() >= GetWorldTime().GetNextMidnight() and GetWorldTime().GetDay(nextAward.GetStartTime()) - GetWorldTime().GetDay() = 1
					local awardName:string = GetLocale("AWARDNAME_" + TVTAwardType.GetAsString(nextAward.awardType))
					text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_NEW_AWARDNAME_TOMORROW").Replace("%AWARDNAME%", "|b|"+awardName+"|/b|")
					showDefaultText = False
				endif
			endif

			if registeredNewsMalfunctions > 0 or registeredProgrammeMalfunctions > 0
				text :+ "~n"
				showDefaultText = False
				if registeredProgrammeMalfunctions > 0
					text :+ "~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_PROGRAMMEMALFUNCTION")
				endif
				if registeredNewsMalfunctions > 0
					text :+ "~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_NEWSMALFUNCTION")
				endif
			endif

			if showDefaultText
				text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_DEFAULT")
			endif

			if isUnfriendly
				text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_ENDING_UNFRIENDLY")
			else
				text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_ENDING_DEFAULT")
			endif

			text = text.replace("%PROGRAMMEMALFUNCTION%", registeredProgrammeMalfunctions)
			text = text.replace("%NEWSMALFUNCTION%", registeredNewsMalfunctions)
			text = text.replace("%PLAYERNAME%", GetPlayerBase().name)


			'clear the talk subjects - boss talked about them
			registeredWonAward = 0
			registeredWonAwardType = 0
			registeredNewsMalfunctions = 0
			registeredProgrammeMalfunctions = 0


			ChefDialogues[0] = TDialogueTexts.Create(text)
			ChefDialogues[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_WILLNOTDISTURB"), -2, Null))
			ChefDialogues[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_ASKFORCREDIT"), 1, Null))


			'add repay option if having a credit
			If GetPlayerBase().GetCredit() > 0
				ChefDialogues[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_REPAYCREDIT"), 3, Null))
			endif
			'creditMax - credit taken
			If GetPlayerBase().GetCreditAvailable() > 0
				local possibleCreditValue:int = GetCreditAvailable()
				local acceptEvent:TEventBase = TEventBase.Create(eventKey_Dialogue_onTakeBossCredit, new TData.Add("value", GetPlayerBase().GetCreditAvailable()))
				local acceptHalfEvent:TEventBase = TEventBase.Create(eventKey_Dialogue_onTakeBossCredit, new TData.Add("value", 0.5 * GetPlayerBase().GetCreditAvailable()))
				local acceptQuarterEvent:TEventBase = TEventBase.Create(eventKey_Dialogue_onTakeBossCredit, new TData.Add("value", 0.25 * GetPlayerBase().GetCreditAvailable()))
				ChefDialogues[1] = TDialogueTexts.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_OK").replace("%CREDIT%", MathHelper.DottedValue(GetPlayerBase().GetCreditAvailable())))
				ChefDialogues[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_OK_ACCEPT").replace("%CREDIT%",MathHelper.DottedValue(0.5 * GetPlayerBase().GetCreditAvailable())), 2, acceptEvent))
				'avoid micro credits
				if GetPlayerBase().GetCreditAvailable() > 50000
					ChefDialogues[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_OK_ACCEPT_HALF").replace("%VALUE%", MathHelper.DottedValue(0.5 * GetPlayerBase().GetCreditAvailable())),2, acceptHalfEvent))
				endif
				if GetPlayerBase().GetCreditAvailable() > 100000
					ChefDialogues[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_OK_ACCEPT_QUARTER").replace("%VALUE%", MathHelper.DottedValue(0.25 * GetPlayerBase().GetCreditAvailable())),2, acceptQuarterEvent))
				endif
				ChefDialogues[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_DECLINE"), - 2))
			Else
				ChefDialogues[1] = TDialogueTexts.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY").replace("%CREDIT%", MathHelper.DottedValue(GetPlayerBase().GetCredit())))
				ChefDialogues[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY_ACCEPT"), 3))
				ChefDialogues[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_DECLINE"), - 2))
			EndIf
			ChefDialogues[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))

			ChefDialogues[2] = TDialogueTexts.Create( GetRandomLocale("DIALOGUE_BOSS_BACKTOWORK").replace("%PLAYERNAME%", GetPlayerBase().name) )
			ChefDialogues[2].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_BACKTOWORK_OK"), - 2))

			'repay credit + options
			local credit:int = GetPlayerBase().GetCredit()
			ChefDialogues[3] = TDialogueTexts.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY_BOSSRESPONSE") )
			For local creditValue:int = EachIn [2500000, 1000000, 500000, 250000, 100000]
				If credit >= creditValue And GetPlayerBase().GetMoney() >= creditValue
					local payBackEvent:TEventBase = TEventBase.Create(eventKey_Dialogue_onRepayBossCredit, new TData.Add("value", creditValue))
					ChefDialogues[3].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY_VALUE").replace("%VALUE%", MathHelper.DottedValue(creditValue)), 0, payBackEvent))
				EndIf
			Next
			If GetPlayerBase().GetCredit() < GetPlayerBase().GetMoney()
				local payBackEvent:TEventBase = TEventBase.Create(eventKey_Dialogue_onRepayBossCredit, new TData.Add("value", GetPlayerBase().GetCredit()))
				ChefDialogues[3].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY_ALL").replace("%CREDIT%",  MathHelper.DottedValue(GetPlayerBase().GetCredit())), 0, payBackEvent))
			EndIf
			ChefDialogues[3].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_DECLINE"), -2))
			ChefDialogues[3].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))

		'other players
		else
			text = GetRandomLocale("DIALOGUE_BOSS_MAIN_TITLE_UNFRIENDLY")
			text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_OTHERPLAYER")

			ChefDialogues[0] = TDialogueTexts.Create(text)
			ChefDialogues[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_WILLNOTDISTURB_OTHERPLAYER"), - 2, Null))
		endif

		Local ChefDialogue:TDialogue = new TDialogue
		ChefDialogue.AddTexts(ChefDialogues)

		if text.length > 100 or text.split("~n").length > 3
			ChefDialogue.SetArea(new TRectangle.Init(300, 15, 400, 110))
			ChefDialogue.moveDialogueBalloonStart = 30
		else
			ChefDialogue.SetArea(new TRectangle.Init(300, 25, 400, 110))
			ChefDialogue.moveDialogueBalloonStart = 30
		endif
		ChefDialogue.SetAnswerArea(new TRectangle.Init(420, 270, 360, 90))
		ChefDialogue.SetGrow(1,-1)

		if Dialogues.length < visitingPlayerID then Dialogues = Dialogues[.. visitingPlayerID]
		Dialogues[visitingPlayerID-1] = ChefDialogue
	End Method


	Method GetCreditAvailable:int()
		Return Max(0, GetCreditMaximum() - GetPlayerFinance(playerID).GetCredit())
	End Method


	'call this method to request the player to visit the boss
	'-> this creates an event the game listens to and creates
	'   a toastmessage in the case of the active player, so they can react
	Method CallPlayer:Int()
		'give the player 2 hrs or reuse old time (eg. savegame)
		if awaitingPlayerVisitTillTime = 0
			awaitingPlayerVisitTillTime = GetWorldTime().GetTimeGone() + 2 * TWorldTime.HOURLENGTH
		endif
		awaitingPlayerCalled = True
		awaitingPlayerAccepted = False

		'send out event that the boss wants to see his player
		TriggerBaseEvent(GameEventKeys.Playerboss_OnCallPlayer, new TData.Add("latestTime", awaitingPlayerVisitTillTime), Self, GetPlayerBaseCollection().Get(playerID))
	End Method


	'call this method to force the player to visit the boss NOW
	'-> this creates an event the game listens to
	Method CallPlayerForced:Int()
		awaitingPlayerCalled = True

		'so the boss does no longer wait for the player to accept
		InformPlayerAcceptedCall()

		'send out event that the boss wants to see his player immediately
		'latestTime = -1 so event knows "now"
		TriggerBaseEvent(GameEventKeys.PlayerBoss_OnCallPlayerForced, new TData.Add("latestTime", -1), Self, GetPlayerBaseCollection().Get(playerID))
	End Method


	'call this so the boss knows: player is on his way to the boss
	'even if it could take a bit longer because of elevator and so on
	Method InformPlayerAcceptedCall:Int()
		awaitingPlayerAccepted = True
	End Method


	Method PlayerRepaysCredit:int(value:int)
		'limit repay value to credit
		value = Min(value, GetPlayerFinance(playerID).GetCredit())

		'without credit return successful, but do not emit an event
		if value = 0 then return True

		local result:int = False
		if GetPlayerFinance(playerID).CanAfford(value)
			GetPlayerFinance(playerID).RepayCredit(value)
			result = True
		endif

		TriggerBaseEvent(GameEventKeys.PlayerBoss_OnPlayerRepaysCredit, new TData.Add("value", value).Add("success", result), Self)
		return result
	End Method


	Method PlayerTakesCredit:int(value:int)
		local result:int = False
		if GetPlayerBase(playerID).GetCreditAvailable() >= value
			if not GetPlayerFinance(playerID)
				TLogger.Log("TPlayerBoss.PlayerTakesCredit()", "GetPlayerFinance() failed for playerID="+playerID+".", LOG_ERROR)
				return False
			endif

			GetPlayerFinance(playerID).TakeCredit(value)
			result = True
		endif

		TriggerBaseEvent(GameEventKeys.PlayerBoss_OnPlayerTakesCredit, new TData.Add("value", value).Add("success", result), Self)
		return result
	End Method


	Method onGameMinute:Int(time:Long = -1)
		if time = -1 then time = GetWorldTime().GetTimeGone()
		Local minute:Int = GetWorldTime().GetDayMinute(time)
		Local hour:Int = GetWorldTime().GetDayHour(time)
		Local day:Int = GetWorldTime().GetDay(time)

		'=== RESET REGISTERED MALFUNCTIONS ===
		'reset them at a given time?
		If minute = 0 and hour = 3
			registeredNewsMalfunctions = 0
			registeredProgrammeMalfunctions = 0
		EndIf

		'=== CHECK IF BOSS WANTS TO SEE PLAYER ===
		'await the player each day at 16:00 (except player is already there)
		if GameRules.dailyBossVisit and not playerVisitsMe
			If minute = 0 and hour = 16 and not awaitingPlayerVisit

				'only await if malfunctions are registered
				'TODO: change this with awards/other subjects the
				'      boss wants to talk about
				if registeredNewsMalfunctions or registeredProgrammeMalfunctions
					awaitingPlayerVisit = True
				endif
			EndIf
		endif

		'call the player if needed
		If awaitingPlayerVisit and not awaitingPlayerCalled
			CallPlayer()
		EndIf

		'check if the player knows he has to visit but did not visit
		'the boss yet - force him to visit NOW
		if awaitingPlayerCalled and not awaitingPlayerAccepted and (awaitingPlayerVisitTillTime > 0 and awaitingPlayerVisitTillTime < time)
			CallPlayerForced()
		endif
	End Method


	Method onFinishAdContract:Int(contract:object)
		ChangeMood(MOODADJUSTMENT_FINISH_CONTRACT)
	End Method


	Method onFailAdContract:Int(contract:object)
		ChangeMood(MOODADJUSTMENT_FAIL_CONTRACT)
	End Method


	Method onFinishBroadcasting:Int(broadcastMaterial:TBroadcastMaterial, broadcastedAsType:int = -1)
		'register malfunctions
		if not broadcastMaterial
			if broadcastedAsType = TVTBroadcastMaterialType.NEWSSHOW
				registeredNewsMalfunctions :+1

				if registeredNewsMalfunctions = 1
					ChangeMood(MOODADJUSTMENT_MALFUNCTION_NEWS)
				else
					ChangeMood(MOODADJUSTMENT_MALFUNCTION_NEWS_EACH)
				endif
			elseif broadcastedAsType = TVTBroadcastMaterialType.PROGRAMME
				registeredProgrammeMalfunctions :+1

				if registeredProgrammeMalfunctions = 1
					ChangeMood(MOODADJUSTMENT_MALFUNCTION_PROGRAMME)
				else
					ChangeMood(MOODADJUSTMENT_MALFUNCTION_PROGRAMME_EACH)
				endif
			endif
		endif

		'TODO - or unneeded?
		rem
		'register top 1 or top 2 audience quote (bonus if reached #1 or #2)
		'we check on "finish" - because now the blocks of all players
		'are running
		if broadcastMaterial
			if broadcastedAsType = TVTBroadcastMaterialType.PROGRAMME
			endif
		endif
		endrem
	End Method


	Method onWonAward:Int(award:TAward)
		registeredWonAward :+ 1
		registeredWonAwardType = award.awardType

		ChangeMood(MOODADJUSTMENT_WON_AWARD)
	End Method


	Method onBombInOffice:Int()
		ChangeMood(MOODADJUSTMENT_BOMB_IN_BOSS_OFFICE)
	End Method

	'called as soon as a player leaves the boss' room
	Method onPlayerLeaveRoom:Int(player:TPlayerBase)
		'reset boss call state so boss can call player again
		awaitingPlayerCalled = False

		playerVisitsMe = False
	End Method


	'called as soon as a player enters the boss' room
	Method onPlayerBeginEnterRoom:Int(player:TPlayerBase)
		'no longer await the visit of this player
		awaitingPlayerVisit = False
		awaitingPlayerVisitTillTime = 0

		playerVisitsMe = True

		'check the charts and update the credit max
		UpdateCreditMaximum()

		'remove an old (maybe obsolete) dialogue
		ResetDialogues(player.playerID)
		GenerateDialogues(player.playerID)

		'send out event that the player enters the bosses room
		TriggerBaseEvent(GameEventKeys.Playerboss_OnPlayerEnterBossRoom, null, self, player)
	End Method


	Method onDialogueTakeCredit:int(value:int)
		PlayerTakesCredit(value)

		'remove an old dialogue (containing old credit information)
		ResetDialogues(GetPlayerBase().playerID)
		GenerateDialogues(GetPlayerBase().playerID)
	End Method


	Method onDialogueRepayCredit:int(value:int)
		PlayerRepaysCredit(value)

		'remove an old dialogue (containing old credit information)
		ResetDialogues(GetPlayerBase().playerID)
		GenerateDialogues(GetPlayerBase().playerID)
	End Method
End Type
