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
	Field kickTime:Long
	Global suitcaseArea:SRect = new SRect(20,220, 145, 120)

	Global haveToRefreshGuiElements:Int = True
	'events we want to listen the whole time
	Global _globalEventListeners:TEventListenerBase[]
	'events only of interest during visit of the player (on screen)
	Global _localEventListeners:TEventListenerBase[]
	Global _instance:RoomHandler_Betty
	Global LS_betty:TLowerString = TLowerString.Create("betty")


	Function GetInstance:RoomHandler_Betty()
		if not _instance then _instance = new RoomHandler_Betty
		return _instance
	End Function


	Method Initialize:Int()
		' === RESET TO INITIAL STATE ===
		CleanUp()


		' === REGISTER HANDLER ===
		RegisterHandler()


		' === CREATE ELEMENTS =====
		BettySprite = GetSpriteFromRegistry("gfx_room_betty_betty")
		if not BettyArea
			BettyArea = New TGUISimpleRect.Create(new SVec2I(303,142), new SVec2I(112,148), "betty" )
			'Betty accepts presents
			BettyArea.setOption(GUI_OBJECT_ACCEPTS_DROP, True)
		EndIf
		spriteSuitcase = GetSpriteFromRegistry("gfx_suitcase_presents")


		' === EVENTS ===
		' remove old listeners
		EventManager.UnregisterListenersArray(_globalEventListeners)
		EventManager.UnregisterListenersArray(_localEventListeners)
		_globalEventListeners = new TEventListenerBase[0]
		_localEventListeners = new TEventListenerBase[0]

		' register new global listeners
		' handle the player visiting betty
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnSetCurrent, onPlayerSeesBettyScreen) ]
		' close bettys office door if Betty is not working
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnHour, CheckOfficeHour) ]


		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== remove obsolete gui elements ===
		'
		if presentInSuitcase
			GUIManager.Remove(presentInSuitcase)
			presentInSuitcase = Null
		EndIf

		EventManager.UnregisterListenersArray(_globalEventListeners)
		EventManager.UnregisterListenersArray(_localEventListeners)
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("betty", GetInstance())
	End Method


	Function CheckOfficeHour:Int(triggerEvent:TEventBase)
		Local time:Long = triggerEvent.GetData().GetLong("time",-1)
		Local hour:Int = GetWorldTime().GetDayHour(time)
		Local bettyRoom:TRoom=GetRoomCollection().GetFirstByDetails("", "betty")
		If bettyRoom and (hour < 9 or hour > 16)
			bettyRoom.setBlocked(TWorldTime.HOURLENGTH, TROOM.BLOCKEDSTATE_NO_OFFICE_HOUR, false)
		EndIf
	End Function

	'alternative to "onEnterRoom" - which does not trigger when loading
	'savegames starting in this screen
	Function onPlayerSeesBettyScreen:Int( triggerEvent:TEventBase )
		If triggerEvent.GetData().GetString("currentScreenName") <> "screen_betty" Then Return False

		'recreate "present" if required
		haveToRefreshGuiElements = True
		ResetDialogue()
	End Function	


	Function ResetDialogue()
		GetInstance().dialogue = null
	End Function


	Function loveLevel:int()
		Local bettyLove:float = GetBetty().GetInLovePercentage( GetPlayerBase().playerID )
		If bettyLove >= 0.4
			return 1
		Else
			return 0
		End If
	End Function


	Function GenerateDialogue()
		local bettyLove:float = GetBetty().GetInLovePercentage( GetPlayerBase().playerID )
		local bettyLoveLevel:int = loveLevel()
		local player:TPlayerBase = GetPlayerBase()

		'each array entry is a "topic" you could talk about
		Local dialogueTexts:TDialogueTexts[2]
		Local text:string
		Local present:TGUIBettyPresent = GetInstance().presentInSuitcase

		If present and present.isVisible()
			dialogueTexts = new TDialogueTexts[1]
			dialogueTexts[0] = TDialogueTexts.Create(GetRandomLocale("DIALOGUE_BETTY_PRESENT_ANNOUNCED_LEVEL"+bettyLoveLevel+"_TEXT"))
			dialogueTexts[0].AddAnswer(TDialogueAnswer.Create(GetRandomLocale("DIALOGUE_BETTY_PRESENT_GIVE_LEVEL"+bettyLoveLevel+"_TEXT"), 0, Null, givePresentViaDialogue))
			dialogueTexts[0].AddAnswer(TDialogueAnswer.Create(GetRandomLocale("DIALOGUE_BETTY_PRESENT_RETRACT_LEVEL"+bettyLoveLevel+"_TEXT"), 0, Null, deactivatePresent))
		Else
			If present and not present.isVisible() Then dialogueTexts = new TDialogueTexts[3]


			'=== WELCOME MESSAGE ===
			text = GetRandomLocale2(["DIALOGUE_BETTY_WELCOME_LEVEL"+bettyLoveLevel+"_TEXT", "DIALOGUE_BETTY_WELCOME_TEXT"])
			text = text.replace("%PLAYERNAME%", player.name)
			dialogueTexts[0] = TDialogueTexts.Create(text)

			'enough love to ask for the master key?
			if not player.GetFigure().hasMasterKey and GetBetty().CanGiveMasterKey(GetPlayerBase().playerID)
				dialogueTexts[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BETTY_ASK_FOR_MASTERKEY"), -2, Null, onTakeMasterKey))
			endif
			dialogueTexts[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_BETTY_ASK_FOR_SAMMYINFORMATION"), 1))
			if present and not present.isVisible() Then dialogueTexts[0].AddAnswer(TDialogueAnswer.Create(GetRandomLocale("DIALOGUE_BETTY_PRESENT_ANNOUNCE_LEVEL"+bettyLoveLevel+"_TEXT"), 0, Null, activatePresent))
			dialogueTexts[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale2(["DIALOGUE_BETTY_LEVEL"+bettyLoveLevel+"_GOODBYE", "DIALOGUE_BETTY_GOODBYE"]), -2, Null))


			'=== SAMMY TOPIC ===
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
			text = GetRandomLocale2([key+"_LEVEL"+bettyLoveLevel+"_TEXT", key+"_LEVEL0_TEXT"])
			text = text.replace("%AWARDNAME%", awardName)
			text = text.replace("%AWARDRANK%", rank)

			dialogueTexts[1] = TDialogueTexts.Create(text)
			dialogueTexts[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale2(["DIALOGUE_BETTY_LEVEL"+bettyLoveLevel+"_CHANGETOPIC", "DIALOGUE_BETTY_CHANGETOPIC"]), 0))
			dialogueTexts[1].AddAnswer(TDialogueAnswer.Create( GetRandomLocale2(["DIALOGUE_BETTY_LEVEL"+bettyLoveLevel+"_GOODBYE", "DIALOGUE_BETTY_GOODBYE"]), -2, Null))
		End If


		GetInstance().dialogue = new TDialogue
		GetInstance().dialogue.AddTexts(dialogueTexts)

		GetInstance().dialogue.SetArea(new TRectangle.Init(440, 80, 300, 95))
		GetInstance().dialogue.SetAnswerArea(new TRectangle.Init(380, 325, 360, 50))
		'GetInstance().dialogue.moveAnswerDialogueBalloonStart = -5
		'dialogue.answerStartType = "StartDownRight"
		'dialogue.moveAnswerDialogueBalloonStart = 100
		GetInstance().dialogue.SetGrow(-1,-1)

		Function activatePresent(data:TData)
			GetInstance().presentInSuitcase.show()
			ResetDialogue()
		End Function
		'reuse existing give present code
		Function givePresentViaDialogue(data:TData)
			Local event:TEventBase = new TEventBase()
			event._sender = GetInstance().presentInSuitcase
			event._receiver = BettyArea
			onDropPresent(event)
		End Function
		Function deactivatePresent(data:TData)
			GetInstance().presentInSuitcase.hide()
			ResetDialogue()
		End Function
	End Function


	Function onTakeMasterKey(data:TData)
		'TODO: give master key to player if love reaches XX percents
		'      ATTENTION: do it with a "Setter" and an event
		'                 -> inform others in a multiplayer game!
		GetPlayerBase().GetFigure().SetHasMasterKey(true)

		ResetDialogue()
	End Function


	Method RefreshGuiElements:Int()
		'create present visualization if required
		If not presentInSuitcase
			Local present:TBettyPresent = GetBetty().getCurrentPresent(GetPlayerBaseCollection().playerID)
			if present 
				presentInSuitcase = new TGUIBettyPresent.Create(Int(suitcaseArea.x + 14), Int(suitcaseArea.y + 19), present)
				presentInSuitcase.setLimitToState("betty")
				'so we get informed of clicks on the item before the widget
				'itself does drop/drag handling
				presentInSuitcase.beforeOnClickCallback = BeforeOnClickPresentCallback
				presentInSuitcase.hide()
			end if
		EndIf

		haveToRefreshGuiElements = False
	End Method


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
		If presentInSuitcase And presentInSuitcase.isVisible()
			spriteSuitcase.Draw(suitcaseArea.x, suitcaseArea.y)
			If presentInSuitcase.isHovered()
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK)
			EndIf
			If presentInSuitcase.isDragged()
				GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
				highlightBetty = True
			EndIf
		EndIf

		If highlightBetty
			Local oldCol:TColor = New TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * Float(0.4 + 0.2 * Sin(Time.GetAppTimeGone() / 5))

			BettySprite.Draw(BettyArea.GetX(), BettyArea.GetY())
			spriteSuitcase.Draw(suitcaseArea.x, suitcaseArea.y)

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		EndIf

		GUIManager.draw(LS_betty)
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'delete unused and create new gui elements
		If haveToRefreshGuiElements Then RefreshGUIElements()
		
		'create dialogue after gui elements exist (it checks "presentInSuitcase")
		if not dialogue and ..
		   not GetPlayerBase().GetFigure().isLeavingRoom() and ..
		   GetPlayerBase().GetFigure().GetInRoomID() > 0
			GenerateDialogue()
		endif

		If kickTime and Time.GetTimeGone() > kickTime Then GetPlayerBase().GetFigure().KickOutOfRoom()

		GUIManager.update(LS_betty)

		if dialogue
			'leave the room
			if dialogue.Update() = 0
				dialogue = null
				GetPlayerBase().GetFigure().LeaveRoom()
			endif

			'prepare leaving - will remove room now
			If MOUSEMANAGER.IsClicked(2)
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
		If presentInSuitcase and presentInSuitcase.IsDragged()
			presentInSuitcase.DropBackToOrigin()
		EndIf
	End Method


	Method onEnterRoom:Int( triggerEvent:TEventBase ) override
		' === EVENTS ===
		' remove old local listeners
		If _localEventListeners.length > 0 
			EventManager.UnregisterListenersArray(_localEventListeners)
			_localEventListeners = new TEventListenerBase[0]
		EndIf
		' register new local events
		' handle present
		_localEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnFinishDrop, onDropPresent, "TGUIBettyPresent") ]
	End Method


	Method onLeaveRoom:int( triggerEvent:TEventBase )
		' === EVENTS ===
		' remove old local listeners
		If _localEventListeners.length > 0 
			EventManager.UnregisterListenersArray(_localEventListeners)
			_localEventListeners = new TEventListenerBase[0]
		EndIf


		If presentInSuitcase
			GuiManager.Remove(presentInSuitcase)
			presentInSuitcase = null
		EndIf
		ResetDialogue()
		kickTime = null
		Return True
	End Method


	Function BeforeOnClickPresentCallback:int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("betty") then Return False
		Local presentItem:TGUIBettyPresent = TGUIBettyPresent(triggerEvent._sender)
		'only interested in clicks to our present
		if not presentItem or presentItem <> GetInstance().presentInSuitcase then Return False

		If presentItem.isDragged()
			local button:Int=triggerEvent.GetData().getInt("button",0)
			If button = 2
				presentItem.dropBackToOrigin()
				MouseManager.SetClickHandled(2)
				Return True
			ElseIf button = 1
				If THelper.MouseInSRect(suitcaseArea)
					presentItem.dropBackToOrigin()
					MouseManager.SetClickHandled(1)
					Return True
				EndIf
			EndIf
		EndIf
		Return False
	End Function


	Function onDropPresent:int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("betty") then Return False
		Local presentItem:TGUIBettyPresent = TGUIBettyPresent(triggerEvent._sender)
		Local droptarget:TGUISimpleRect = TGUISimpleRect(triggerEvent._receiver)

		If presentItem and presentItem = GetInstance().presentInSuitcase and droptarget = BettyArea
			GetInstance().givePresent()
			return true
		End If
		Return False
	End Function


	Method givePresent()
		If presentInSuitcase
			Local bettyLoveLevel:int = loveLevel()
			Local present:TBettyPresent = presentInSuitcase.present
			Local dialogueTexts:TDialogueTexts[1]
			Local result:int = TBetty.GetInstance().GivePresent(GetPlayerBase().playerID, present)
			If result = TBettyPresent.ACCEPT
				If present.bettyValue >= 0
					dialogueTexts[0] = TDialogueTexts.Create(GetRandomLocale("DIALOGUE_BETTY_PRESENT_THANKS_LEVEL"+bettyLoveLevel+"_TEXT"))
					dialogueTexts[0].AddAnswer(TDialogueAnswer.Create(GetRandomLocale("DIALOGUE_BETTY_PRESENT_WELCOME_LEVEL"+bettyLoveLevel+"_TEXT"), 0, null, thanks))
				Else
					dialogueTexts[0] = TDialogueTexts.Create(GetRandomLocale("DIALOGUE_BETTY_PRESENT_HOW_DARE_LEVEL"+bettyLoveLevel+"_TEXT"))
					dialogueTexts[0].AddAnswer(TDialogueAnswer.Create(GetRandomLocale("DIALOGUE_BETTY_PRESENT_WELL"), 0, null, thanks, new TData))
					kickTime = Time.GetTimeGone() + 3000
				End If
				presentInSuitcase.remove()
				presentInSuitcase = null
	
			Else If result =  TBettyPresent.REJECT_ONE_PER_DAY
				dialogueTexts[0] = TDialogueTexts.Create(GetLocale("DIALOGUE_BETTY_PRESENT_REJECT_TODAY"))
				dialogueTexts[0].AddAnswer(TDialogueAnswer.Create(GetLocale("OK"), 0, null, thanks))
			End If
			dialogue = new TDialogue
			dialogue.AddTexts(dialogueTexts)
	
			dialogue.SetArea(new TRectangle.Init(440, 80, 300, 95))
			dialogue.SetAnswerArea(new TRectangle.Init(380, 325, 360, 50))
			'dialogue.answerStartType = "StartDownRight"
			'dialogue.moveAnswerDialogueBalloonStart = 100
			dialogue.SetGrow(-1,-1)
		End If

		Function thanks(data:TData)
			'existing data as marker for leaving
			if data
				GetInstance().kickTime = null
				GetPlayerBase().GetFigure().LeaveRoom()
			else
				If(GetInstance().presentInSuitcase) Then GetInstance().presentInSuitcase.hide()
				ResetDialogue()
			end if
		End Function
	End Method
End Type
