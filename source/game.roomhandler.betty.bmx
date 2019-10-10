SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.player.base.bmx"
Import "game.betty.bmx"
Import "game.award.base.bmx"
Import "common.misc.dialogue.bmx"



'Betty
Type RoomHandler_Betty extends TRoomHandler
	Field dialogue:TDialogue
	Global _eventListeners:TLink[]
	Global _instance:RoomHandler_Betty


	Function GetInstance:RoomHandler_Betty()
		if not _instance then _instance = new RoomHandler_Betty
		return _instance
	End Function


	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS =====
		'nothing up to now


		'=== EVENTS ===
		'remove old listeners
		EventManager.unregisterListenersByLinks(_eventListeners)

		'register new listeners
		_eventListeners = new TLink[0]
		'handle players visiting betty
		_eventListeners :+ [ EventManager.registerListenerFunction("player.onBeginEnterRoom", onPlayerBeginEnterRoom) ]


		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		'

		'=== remove obsolete gui elements ===
		'

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("betty", GetInstance())
	End Method


	'called as soon as a player enters bettys room
	Function onPlayerBeginEnterRoom:Int(triggerEvent:TEventBase)
		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())
		if not room or room.GetName() <> "betty" then return False

		'remove an old (maybe obsolete) dialogue
		'ResetDialogue()
		'generate already overrides an existing dialogue
		GenerateDialogue()
	End Function


	Function ResetDialogue()
		GetInstance().dialogue = null
	End Function


	Function GenerateDialogue()
		local bettyLove:float = GetBetty().GetInLovePercentage( GetPlayerBase().playerID )
		local bettyLoveLevel:int = ceil(int(bettyLove*100) / 25.0)
		local player:TPlayerBase = GetPlayerBase()

		'each array entry is a "topic" you could talk about
		Local dialogueTexts:TDialogueTexts[2]

		local text:string

		'=== WELCOME MESSAGE ===
		text = GetRandomLocale2(["DIALOGUE_BETTY_WELCOME_LEVEL"+bettyLoveLevel+"_TEXT", "DIALOGUE_BETTY_WELCOME_TEXT"])
		text = text.replace("%PLAYERNAME%", player.name)
		dialogueTexts[0] = TDialogueTexts.Create(text)

		'enough love to ask for the master key?
		if not player.GetFigure().hasMasterKey and bettyLove > GameRules.bettyLoveToGetMasterKey
			dialogueTexts[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BETTY_ASK_FOR_MASTERKEY"), -2, Null, onTakeMasterKey))
		endif
		dialogueTexts[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BETTY_ASK_FOR_SAMMYINFORMATION"), 1))
		dialogueTexts[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale2(["DIALOGUE_BETTY_LEVEL"+bettyLoveLevel+"_GOODBYE", "DIALOGUE_BETTY_GOODBYE"]), -2, Null))



		'=== SAMMY TOPIC ===
		'only two level supported
		local lvl:int = bettyLoveLevel > 0
		local key:string
		local awardName:string
		local rank:int = 0
		local currentAward:TAward = GetAwardCollection().GetCurrentAward()
		if currentAward
			awardName = GetLocale("AWARDNAME_" + TVTAwardType.GetAsString(currentAward.awardType))
			rank = currentAward.GetCurrentRank( player.playerID )
			local hasWinner:int = currentAward.GetCurrentWinner()<>0
			'local awardTimeLeft:int = currentAward.GetEndTime() - GetWorldTime().GetTimeGone()

			if not hasWinner
				key = "DIALOGUE_BETTY_AWARDINFORMATION_NO_FAVORITE"
			else
				if rank = 1
					key = "DIALOGUE_BETTY_AWARDINFORMATION_YOU_ARE_FAVORITE"
				elseif rank = currentAward.GetRanks()
					key = "DIALOGUE_BETTY_AWARDINFORMATION_YOU_ARE_NOT_FAVORITE"
				else
					key = "DIALOGUE_BETTY_AWARDINFORMATION_YOU_ARE_AVERAGE"
				endif
			endif
		else
			key = "DIALOGUE_BETTY_NO_AWARD"
		endif
		text = GetRandomLocale2([key+"_LEVEL"+lvl+"_TEXT", key+"_LEVEL0_TEXT"])
		text = text.replace("%AWARDNAME%", awardName)
		text = text.replace("%AWARDRANK%", rank)

		dialogueTexts[1] = TDialogueTexts.Create(text)
		dialogueTexts[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale2(["DIALOGUE_BETTY_LEVEL"+bettyLoveLevel+"_CHANGETOPIC", "DIALOGUE_BETTY_CHANGETOPIC"]), 0))
		dialogueTexts[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale2(["DIALOGUE_BETTY_LEVEL"+bettyLoveLevel+"_GOODBYE", "DIALOGUE_BETTY_GOODBYE"]), -2, Null))


		GetInstance().dialogue = new TDialogue
		GetInstance().dialogue.AddTexts(dialogueTexts)

		GetInstance().dialogue.SetArea(new TRectangle.Init(440, 80, 300, 95))
		GetInstance().dialogue.SetAnswerArea(new TRectangle.Init(380, 325, 360, 50))
		'dialogue.answerStartType = "StartDownRight"
		'dialogue.moveAnswerDialogueBalloonStart = 100
		GetInstance().dialogue.SetGrow(-1,-1)
	End Function


	Function onTakeMasterKey(data:TData)
		'TODO: give master key to player if love reaches XX percents
		'      ATTENTION: do it with a "Setter" and an event
		'                 -> inform others in a multiplayer game!
		GetPlayerBase().GetFigure().SetHasMasterKey(true)

		ResetDialogue()
	End Function


	Method onDrawRoom:int( triggerEvent:TEventBase )
		For Local i:Int = 1 To 4
			local sprite:TSprite = GetSpriteFromRegistry("gfx_room_betty_picture1")
			Local picY:Int = 240
			Local picX:Int = 410 + i * (sprite.area.GetW() + 10)

			'move the picture higher according to "love"
			picY :- GetBetty().GetInLovePercentage(i) * 40


			sprite.Draw( picX, picY )
			SetAlpha 0.4
			GetPlayerBase(i).color.copy().AdjustRelative(-0.5).SetRGB()
			DrawRect(picX + 2, picY + 8, 26, 28)
			SetColor 255, 255, 255
			SetAlpha 1.0
			local x:float = picX + Int(sprite.area.GetW() / 2) - Int(GetPlayerBase(i).Figure.Sprite.framew / 2)
			local y:float = picY + sprite.area.GetH() - 30
			GetPlayerBase(i).Figure.Sprite.DrawClipped(x, y, -1, sprite.area.GetH()-16, 0,0, 8)
		Next

		If dialogue then dialogue.Draw()
		'TDialogue.DrawDialog("default", 440, 110, 280, 90, "StartLeftDown", 15, GetLocale("DIALOGUE_BETTY_WELCOME"), 0, GetBitmapFont("Default",14))
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		if not dialogue and ..
		   not GetPlayerBase().GetFigure().isLeavingRoom() and ..
		   GetPlayerBase().GetFigure().GetInRoomID() > 0
			GenerateDialogue()
		endif

		if dialogue
			'leave the room
			if dialogue.Update() = 0
				dialogue = null
				GetPlayerBase().GetFigure().LeaveRoom()
			endif

			'prepare leaving - will remove room now
			If MOUSEMANAGER.IsClicked(2) or MouseManager.IsLongClicked(1)
				dialogue = null

				'avoid clicks
				'remove right click - to avoid leaving the room
				MouseManager.ResetClicked(2)
				'also avoid long click (touch screen)
				MouseManager.ResetLongClicked(1)
			endif
		endif
	End Method
End Type
