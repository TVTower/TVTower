SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.player.base.bmx"
Import "game.betty.bmx"
Import "game.award.base.bmx"
Import "common.misc.dialogue.bmx"
Import "Dig/base.gfx.gui.bmx"
Import "common.misc.gamegui.bmx"



'Betty
Type RoomHandler_Betty extends TRoomHandler
	Field dialogue:TDialogue

	Global BettySprite:TSprite
	Global BettyArea:TGUISimpleRect	'allows registration of drop-event

	Field spriteSuitcase:TSprite {nosave}
	Field presentInSuitcase:TGUIBettyPresent {nosave}
	Field draggedPresent:TGUIBettyPresent {nosave}
	Field suitcasePos:TVec2D = new TVec2D.Init(20,220) {nosave}

	Global _eventListeners:TEventListenerBase[]
	Global _instance:RoomHandler_Betty
	Global LS_betty:TLowerString = TLowerString.Create("betty")


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
		BettySprite = GetSpriteFromRegistry("gfx_room_betty_betty")
		BettyArea = New TGUISimpleRect.Create(new TVec2D.Init(303,142), new TVec2D.Init(112,148), "betty" )
		'Betty accepts presents
		BettyArea.setOption(GUI_OBJECT_ACCEPTS_DROP, True)


		'=== EVENTS ===
		'remove old listeners
		EventManager.UnregisterListenersArray(_eventListeners)

		'register new listeners
		_eventListeners = new TEventListenerBase[0]
		'handle players visiting betty
		_eventListeners :+ [ EventManager.registerListenerFunction("player.onBeginEnterRoom", onPlayerBeginEnterRoom) ]
		'handle present
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickPresent, "TGUIBettyPresent" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onDropOnTargetAccepted", onDropPresent, "TGUIBettyPresent" ) ]


		'(re-)localize content
		SetLanguage()
		spriteSuitcase = GetSpriteFromRegistry("gfx_suitcase")
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

		Local present:TBettyPresent=GetBetty().getCurrentPresent(GetPlayerBaseCollection().playerID)
		If present
			If not GetInstance().presentInSuitcase
				GetInstance().presentInSuitcase=new TGUIBettyPresent.Create(GetInstance().suitcasePos.GetX() + 70, GetInstance().suitcasePos.GetY() + 32, present)
				GetInstance().presentInSuitcase.setLimitToState("betty")
			End If
		End If
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


		BettySprite.Draw(BettyArea.GetX(), BettyArea.GetY())

		If dialogue then dialogue.Draw()
		'TDialogue.DrawDialog("default", 440, 110, 280, 90, "StartLeftDown", 15, GetLocale("DIALOGUE_BETTY_WELCOME"), 0, GetBitmapFont("Default",14))

		Local highlightBetty:int = False
		If presentInSuitcase
			spriteSuitcase.Draw(suitcasePos.GetX(), suitcasePos.GetY(),-1,null, 1.3)
			If presentInSuitcase.isHovered
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK)
			End If
			If presentInSuitcase.isDragged
				GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
				draggedPresent = presentInSuitcase
				highlightBetty = True
			Else
				draggedPresent = null
			End If
		End If

		If highlightBetty
			Local oldCol:TColor = New TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * Float(0.4 + 0.2 * Sin(Time.GetAppTimeGone() / 5))

			BettySprite.Draw(BettyArea.GetX(), BettyArea.GetY())

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		EndIf

		GUIManager.draw(LS_betty)
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		if not dialogue and ..
		   not GetPlayerBase().GetFigure().isLeavingRoom() and ..
		   GetPlayerBase().GetFigure().GetInRoomID() > 0
			GenerateDialogue()
		endif

		GUIManager.update(LS_betty)

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

'for now we leave the room now
'change this when we can actually give Betty our presents 
'				MouseManager.SetClickHandled(2)

			endif
		endif
	End Method

	Method AbortScreenActions:Int()
		If draggedPresent
			draggedPresent.dropBackToOrigin()
			draggedPresent = null
		End If
	End Method

	Method onLeaveRoom:int( triggerEvent:TEventBase )
		If presentInSuitcase
			GuiManager.Remove(presentInSuitcase)
		End If
		presentInSuitcase = null
		draggedPresent = null
		Return True
	End Method

	Function onClickPresent:int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("betty") then Return False
		Local presentItem:TGUIBettyPresent = TGUIBettyPresent(triggerEvent._sender)
		If presentItem and presentItem.isDragged()
			local button:Int=triggerEvent.GetData().getInt("button",0)
			If button = 2
				presentItem.dropBackToOrigin()
				MouseManager.SetClickHandled(2)
			Else If button = 1
				Local pos:TVec2D=RoomHandler_Betty.GetInstance().suitcasePos
				If THelper.MouseIn(pos.GetX(), pos.GetY(), 250, 120) And GetInstance().draggedPresent
					presentItem.dropBackToOrigin()
				End If
			End If
		End If
		Return False
	End Function

	Function onDropPresent:int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("betty") then Return False
		Local presentItem:TGUIBettyPresent = TGUIBettyPresent(triggerEvent._sender)
		Local droptarget:TGUISimpleRect = TGUISimpleRect(triggerEvent._receiver)
		If presentItem = GetInstance().draggedPresent and droptarget = BettyArea
			GetInstance().givePresent()
			return true
		End If
		Return False
	End Function

	Method givePresent()
		If presentInSuitcase
			Local present:TBettyPresent = presentInSuitcase.present
			TBetty.GetInstance().GivePresent(GetPlayerBase().playerID, present)
			presentInSuitcase.remove()
			presentInSuitcase = null
			draggedPresent = null
		End If
	End Method
End Type
