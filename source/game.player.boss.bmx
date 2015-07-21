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


Type TPlayerBossCollection
	Field bosses:TPlayerBoss[4]
	'playerID of player who sits in front of the screen
	'adjust this TOO when switching players
	Field playerID:Int = 1
	Global _instance:TPlayerBossCollection


	Function GetInstance:TPlayerBossCollection()
		if not _instance then _instance = new TPlayerBossCollection
		return _instance
	End Function


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

		Return bosses[id-1]
	End Method


	Method GetCount:Int()
		return bosses.length
	End Method


	Method IsBoss:Int(number:Int)
		Return (number > 0 And number <= bosses.length And bosses[number-1] <> Null)
	End Method
	
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
	Field awaitingPlayerCalled:Int = False
	Field playerVisitsMe:int = False
	'amount the boss is likely to give the player
	Field creditMaximum:Int	= 600000

	'in the case of the player sends a favorite movie, this might
	'brighten the mood of the boss
	Field favoriteMovieGUID:String = ""
	'things the boss wants to talk about
	Field talkSubjects:TPlayerBossTalkSubjects[]
	'dialogues for the things the boss can talk about
	Field Dialogues:TList = CreateList()

	Field registeredProgrammeMalfunctions:int = 0
	Field registeredNewsMalfunctions:int = 0
	Field playerID:int = -1

	'event listeners - so we can remove them at the end
	Field _registeredListeners:TList = CreateList() {nosave}
	Global registeredEvents:int = False

	Const MOODADJUSTMENT_BROADCAST_POS1:Float             = 0.075
	Const MOODADJUSTMENT_BROADCAST_POS2:Float             = 0.04
	Const MOODADJUSTMENT_FINISH_CONTRACT:Float            = 0.05
	Const MOODADJUSTMENT_FAIL_CONTRACT:Float              = -0.1
	Const MOODADJUSTMENT_MALFUNCTION_PROGRAMME:Float      = -2.0
	Const MOODADJUSTMENT_MALFUNCTION_PROGRAMME_EACH:Float = -0.5
	Const MOODADJUSTMENT_MALFUNCTION_NEWS:Float           = -1.0
	Const MOODADJUSTMENT_MALFUNCTION_NEWS_EACH:Float      = -0.25
	Const MOOD_EXCITED:Float    =100.0
	Const MOOD_HAPPY:Float      = 90.0
	Const MOOD_FRIENDLY:Float   = 70.0
	Const MOOD_NEUTRAL:Float    = 50.0
	Const MOOD_UNHAPPY:Float    = 30.0
	Const MOOD_UNFRIENDLY:Float = 10.0
	Const MOOD_ANGRY:Float      =  0.0


	Method New()
		RegisterEvents()

		mood = MOOD_NEUTRAL
	End Method

	Method Delete()
		UnRegisterEvents()
	End Method


	Method RegisterEvents:Int()
		'register events for all bosses
		if not registeredEvents
			EventManager.registerListenerFunction("broadcasting.finish", onFinishBroadcasting)
			'instead of updating the boss way to often, we update bosses
			'once a ingame minute
			EventManager.registerListenerFunction("Game.OnMinute", onGameMinute)

			EventManager.registerListenerFunction("AdContract.onFinish", onFinishOrFailAdContract)
			EventManager.registerListenerFunction("AdContract.onFail", onFinishOrFailAdContract)

			EventManager.registerListenerFunction("player.onEnterRoom", onPlayerEnterRoom)
			EventManager.registerListenerFunction("player.onLeaveRoom", onPlayerLeaveRoom)

			'register dialogue handlers
			EventManager.registerListenerFunction("dialogue.onTakeBossCredit", onDialogueTakeCredit)
			EventManager.registerListenerFunction("dialogue.onRepayBossCredit", onDialogueRepayCredit)

			registeredEvents = True
		endif

		'boss specific events
		' - none for now -
	End Method


	Method UnRegisterEvents:Int()
		For local link:TLink = EachIn _registeredListeners
			'variant a: link.Remove()
			'variant b: we never know if there happens something else
			EventManager.unregisterListenerByLink(link)
		Next
	End Method


	Method GetMood:int()
		return mood
	End Method


	Method ChangeMood:int(value:Float)
		mood :+ value
		mood = Min(100.0, Max(0.0, mood))
		return mood
	End Method


	Method IsInMoodOrWorse:int(mood:Float)
		return self.mood <= mood
	End Method

	Method IsInMoodOrBetter:int(mood:Float)
		return self.mood >= mood
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


	Method ResetDialogues()
		Dialogues.Clear()
	End Method


	Method GenerateDialogues(visitingPlayerID:int)
		'each array entry is a "topic" the chef could talk about
		Local ChefDialoge:TDialogueTexts[5]
		local text:string

		if visitingPlayerID = playerID
			local isUnfriendly:int = isInMoodOrWorse(MOOD_UNFRIENDLY) or registeredNewsMalfunctions > 0 or registeredProgrammeMalfunctions > 0
			if isUnfriendly
				text = GetRandomLocale("DIALOGUE_BOSS_MAIN_TITLE_UNFRIENDLY")
			else
				text = GetRandomLocale("DIALOGUE_BOSS_MAIN_TITLE_DEFAULT")
			endif

			if registeredNewsMalfunctions > 0 or registeredProgrammeMalfunctions > 0
				if registeredProgrammeMalfunctions > 0
					text :+ "~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_PROGRAMMEMALFUNCTION")
				endif
				if registeredNewsMalfunctions > 0
					text :+ "~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_NEWSMALFUNCTION")
				endif
			else
				text :+ "~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_DEFAULT")
			endif
			if isUnfriendly
				text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_ENDING_UNFRIENDLY")
			else
				text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_ENDING_DEFAULT")
			endif

			text = text.replace("%PROGRAMMEMALFUNCTION%", registeredProgrammeMalfunctions)
			text = text.replace("%NEWSMALFUNCTION%", registeredNewsMalfunctions)
			text = text.replace("%PLAYERNAME%", GetPlayerBase().name)

			ChefDialoge[0] = TDialogueTexts.Create(text)
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_WILLNOTDISTURB"), - 2, Null))
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_ASKFORCREDIT"), 1, Null))


			'add repay option if having a credit
			If GetPlayerBase().GetCredit() > 0
				ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_REPAYCREDIT"), 3, Null))
			endif
			'creditMax - credit taken
			If GetPlayerBase().GetCreditAvailable() > 0
				local acceptEvent:TEventSimple = TEventSimple.Create("dialogue.onTakeBossCredit", new TData.AddNumber("value", GetPlayerBase().GetCreditAvailable()))
				local acceptHalfEvent:TEventSimple = TEventSimple.Create("dialogue.onTakeBossCredit", new TData.AddNumber("value", 0.5 * GetPlayerBase().GetCreditAvailable()))
				ChefDialoge[1] = TDialogueTexts.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_OK").replace("%CREDIT%", TFunctions.DottedValue(GetPlayerBase().GetCreditAvailable())))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_OK_ACCEPT").replace("%CREDIT%",TFunctions.DottedValue(0.5 * GetPlayerBase().GetCreditAvailable())), 2, acceptEvent))
				'avoid micro credits
				if GetPlayerBase().GetCreditAvailable() > 50000
					ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_OK_ACCEPT_HALF").replace("%CREDITHALF%", TFunctions.DottedValue(0.5 * GetPlayerBase().GetCreditAvailable())),2, acceptHalfEvent))
				endif
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_DECLINE"), - 2))
			Else
				ChefDialoge[1] = TDialogueTexts.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY").replace("%CREDIT%", GetPlayerBase().GetCredit()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY_ACCEPT"), 3))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_DECLINE"), - 2))
			EndIf
			ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))

			ChefDialoge[2] = TDialogueTexts.Create( GetRandomLocale("DIALOGUE_BOSS_BACKTOWORK").replace("%PLAYERNAME%", GetPlayerBase().name) )
			ChefDialoge[2].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_BACKTOWORK_OK"), - 2))

			'repay credit + options
			ChefDialoge[3] = TDialogueTexts.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY_BOSSRESPONSE") )
			If GetPlayerBase().GetCredit() >= 100000 And GetPlayerBase().GetMoney() >= 100000
				local payBackEvent:TEventSimple = TEventSimple.Create("dialogue.onRepayBossCredit", new TData.AddNumber("value", 100000))
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY_100K"), - 2, payBackEvent))
			EndIf
			If GetPlayerBase().GetCredit() >= 500000 And GetPlayerBase().GetMoney() >= 500000
				local payBackEvent:TEventSimple = TEventSimple.Create("dialogue.onRepayBossCredit", new TData.AddNumber("value", 500000))
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY_500K"), - 2, payBackEvent))
			EndIf
			If GetPlayerBase().GetCredit() < GetPlayerBase().GetMoney()
				local payBackEvent:TEventSimple = TEventSimple.Create("dialogue.onRepayBossCredit", new TData.AddNumber("value", GetPlayerBase().GetCredit()))
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CREDIT_REPAY_ALL").replace("%CREDIT%", GetPlayerBase().GetCredit()), - 2, payBackEvent))
			EndIf
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_DECLINE"), - 2))
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))

			'clear the talk subjects - boss talked about them
			talkSubjects = new TPlayerBossTalkSubjects[0]

		'other players
		else
			text = GetRandomLocale("DIALOGUE_BOSS_MAIN_TITLE_UNFRIENDLY")
			text :+ "~n~n" + GetRandomLocale("DIALOGUE_BOSS_MAIN_TEXT_OTHERPLAYER")

			ChefDialoge[0] = TDialogueTexts.Create(text)
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BOSS_WILLNOTDISTURB_OTHERPLAYER"), - 2, Null))
		endif
		
		Local ChefDialog:TDialogue = new TDialogue
		ChefDialog.SetArea(new TRectangle.Init(350, 60, 460, 230))
		ChefDialog.AddTexts(Chefdialoge)

		Dialogues.AddLast(ChefDialog)
	End Method


	'call this method to request the player to visit the boss
	'-> this creates an event the game listens to and creates
	'   a toastmessage in the case of the active player, so they can react
	Method CallPlayer:Int()
		'give the player 2 hrs
		awaitingPlayerVisitTillTime = GetWorldTime().GetTimeGone() + 7200
		awaitingPlayerCalled = True
		awaitingPlayerAccepted = False

		'send out event that the boss wants to see his player
		EventManager.triggerEvent(TEventSimple.Create("playerboss.onCallPlayer", new TData.AddNumber("latestTime", awaitingPlayerVisitTillTime), Self, GetPlayerBaseCollection().Get(playerID)))
	End Method

	
	'call this method to force the player to visit the boss NOW
	'-> this creates an event the game listens to
	Method CallPlayerForced:Int()
		awaitingPlayerCalled = True

		'so the boss does no longer wait for the player to accept
		InformPlayerAcceptedCall()

		'send out event that the boss wants to see his player immediately
		'latestTime = -1 so event knows "now"
		EventManager.triggerEvent(TEventSimple.Create("playerboss.onCallPlayerForced", new TData.AddNumber("latestTime", -1), Self, GetPlayerBaseCollection().Get(playerID)))
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

		EventManager.triggerEvent(TEventSimple.Create("playerboss.onPlayerRepaysCredit", new TData.AddNumber("value", value).AddNumber("success", result), Self))
		return result
	End Method


	Method PlayerTakesCredit:int(value:int)
		local result:int = False
		if GetPlayerBase(playerID).GetCreditAvailable() >= value
			GetPlayerFinance(playerID).TakeCredit(value)
			result = True
		endif

		EventManager.triggerEvent(TEventSimple.Create("playerboss.onPlayerTakesCredit", new TData.AddNumber("value", value).AddNumber("success", result), Self))
		return result
	End Method


	'=== EVENTS THE BOSSES LISTEN TO ===
	Function onGameMinute:Int(triggerEvent:TEventBase)
		Local minute:Int = triggerEvent.GetData().GetInt("minute",-1)
		Local hour:Int = triggerEvent.GetData().GetInt("hour",-1)
		Local day:Int = triggerEvent.GetData().GetInt("day",-1)

		For local boss:TPlayerBoss = Eachin GetPlayerBossCollection().bosses
			'=== RESET REGISTERED MALFUNCTIONS ===
			'reset them at a given time?
			If minute = 0 and hour = 3 
				boss.registeredNewsMalfunctions = 0
				boss.registeredProgrammeMalfunctions = 0
			EndIf
		
			'=== CHECK IF BOSS WANTS TO SEE PLAYER ===
			'await the player each day at 16:00 (except player is already there)
			if GameRules.dailyBossVisit and not boss.playerVisitsMe
				If minute = 0 and hour = 16 and not boss.awaitingPlayerVisit
					boss.awaitingPlayerVisit = True
				EndIf
			endif

			'call the player if needed
			If boss.awaitingPlayerVisit and not boss.awaitingPlayerCalled
				boss.CallPlayer()
			EndIf

			'check if the player knows he has to visit but did not visit
			'the boss yet - force him to visit NOW
			if boss.awaitingPlayerCalled and not boss.awaitingPlayerAccepted and boss.awaitingPlayerVisitTillTime < GetWorldTime().GetTimeGone()
				boss.CallPlayerForced()
			endif
		Next
	End Function


	Function onFinishOrFailAdContract:Int(triggerEvent:TEventBase)
		local contract:TNamedGameObject = TNamedGameObject(triggerEvent.GetSender())
		if not contract then return False
		local boss:TPlayerBoss = GetPlayerBoss(contract.owner)
		if not boss then return False

		if triggerEvent.isTrigger("AdContract.onFinish")
			boss.ChangeMood(MOODADJUSTMENT_FINISH_CONTRACT)
		elseif triggerEvent.isTrigger("AdContract.onFail")
			boss.ChangeMood(MOODADJUSTMENT_FAIL_CONTRACT)
		endif
	End Function

	
	Function onFinishBroadcasting:Int(triggerEvent:TEventBase)
		local programmePlan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		if not programmePlan then return False

		local boss:TPlayerBoss = GetPlayerBoss(programmePlan.owner)
		if not boss then return False

		local broadcastMaterial:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("broadcastMaterial"))
		local broadcastedAsType:Int = triggerEvent.GetData().GetInt("broadcastedAsType",-1)

		'register malfunctions
		If not broadcastMaterial
			if broadcastedAsType = TVTBroadcastMaterialType.NEWSSHOW
				boss.talkSubjects :+ [new TPlayerBossTalkSubjects.InitNewsMalfunctionSubject(broadcastMaterial)]
				boss.registeredNewsMalfunctions :+1
				
				if boss.registeredNewsMalfunctions = 1
					boss.ChangeMood(MOODADJUSTMENT_MALFUNCTION_NEWS)
				else
					boss.ChangeMood(MOODADJUSTMENT_MALFUNCTION_NEWS_EACH)
				endif
			elseif broadcastedAsType = TVTBroadcastMaterialType.PROGRAMME
				boss.talkSubjects :+ [new TPlayerBossTalkSubjects.InitProgrammeMalfunctionSubject(broadcastMaterial)]
				boss.registeredProgrammeMalfunctions :+1

				if boss.registeredProgrammeMalfunctions = 1
					boss.ChangeMood(MOODADJUSTMENT_MALFUNCTION_PROGRAMME)
				else
					boss.ChangeMood(MOODADJUSTMENT_MALFUNCTION_PROGRAMME_EACH)
				endif
			endif
		endif

		'TODO - or unneeded?
		rem
		'register top 1 or top 2 audience quote
		'we check on "finish" - because now the blocks of all players
		'are running
		if broadcastMaterial
			if broadcastedAsType = TVTBroadcastMaterialType.PROGRAMME
			endif
		endif
		endrem
	End Function


	'called as soon as a player leaves the boss' room
	Function onPlayerLeaveRoom:Int(triggerEvent:TEventBase)
		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())
		if not room or room.name <> "boss" then return False

		'only interested in the visit of the player linked to this room
		local player:TPlayerBase = TPlayerBase(triggerEvent.GetSender())
		if not player or room.owner <> player.playerID then return False

		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False

		'reset boss call state so boss can call player again
		boss.awaitingPlayerCalled = False

		boss.playerVisitsMe = False
	End Function

	
	'called as soon as a player enters the boss' room
	Function onPlayerEnterRoom:Int(triggerEvent:TEventBase)
		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())
		if not room or room.name <> "boss" then return False

		'only interested in the visit of the player linked to this room
		local player:TPlayerBase = TPlayerBase(triggerEvent.GetSender())
		if not player or room.owner <> player.playerID then return False

		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False


		'no longer await the visit of this player
		boss.awaitingPlayerVisit = False

		boss.playerVisitsMe = True


		'remove an old (maybe obsolete) dialogue
		boss.ResetDialogues()
		boss.GenerateDialogues(GetPlayerBase().playerID)

		'send out event that the player enters the bosses room
		EventManager.triggerEvent(TEventSimple.Create("playerboss.onPlayerEnterBossRoom", null, boss, player))
	End Function


	Function onDialogueTakeCredit:int(triggerEvent:TEventBase)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		GetPlayerBoss().PlayerTakesCredit(value)
	End Function


	Function onDialogueRepayCredit:int(triggerEvent:TEventBase)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		GetPlayerBoss().PlayerRepaysCredit(value)
	End Function

End Type




Type TPlayerBossTalkSubjects
	Field subjectType:Int = 0
	'store specific objects in it
	'- broadcastmaterial
	'- audienceresults ...
	Field subjectObject:object
	Field changeMoodAmount:Int = 0

	'did the boss recognize that the player sent a malfunction?
	Const TYPE_PROGRAMME_MALFUNCTION:Int = 1
	Const TYPE_NEWS_MALFUNCTION:Int = 2
	'boss wants you to payback some credit
	Const TYPE_NEED_TO_PAYBACK_CREDIT:Int = 3
	Const TYPE_SENT_FAVORITE_PROGRAMME:Int = 4
	Const TYPE_WON_PRICE:Int = 5


	Method InitProgrammeMalfunctionSubject:TPlayerBossTalkSubjects(broadcastMaterial:TBroadcastMaterial)
		subjectType = TYPE_PROGRAMME_MALFUNCTION
		subjectObject = broadcastMaterial
		changeMoodAmount :- 5
		return self
	End Method

	Method InitNewsMalfunctionSubject:TPlayerBossTalkSubjects(broadcastMaterial:TBroadcastMaterial)
		subjectType = TYPE_NEWS_MALFUNCTION
		subjectObject = broadcastMaterial
		changeMoodAmount :- 2
		return self
	End Method
End Type