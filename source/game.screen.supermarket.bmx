SuperStrict
Import "game.screen.base.bmx"
Import "game.betty.bmx"
Import "game.player.base.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "common.misc.datasheet.bmx"


Type TScreenHandler_Supermarket extends TScreenHandler
	Global vendorSprite:TSprite
	Global vendorArea:TRectangle = new TRectangle.Init(0,70,120,312)
	Global dialogue:TDialogue
	Global _eventListeners:TEventListenerBase[]
	Global _instance:TScreenHandler_Supermarket

	Global _globalEventListeners:TEventListenerBase[]
	Global _localEventListeners:TEventListenerBase[]


	Function GetInstance:TScreenHandler_Supermarket()
		if not _instance then _instance = new TScreenHandler_Supermarket
		return _instance
	End Function


	Method Initialize:int()
		local screen:TScreen = ScreenCollection.GetScreen("screen_supermarket")
		if not screen then return False


		'=== CREATE ELEMENTS ===

		vendorSprite = GetSpriteFromRegistry("gfx_supermarket_vendor")


		' === REGISTER EVENTS ===

		' remove old listeners
		EventManager.UnregisterListenersArray(_globalEventListeners)
		EventManager.UnregisterListenersArray(_localEventListeners)
		_globalEventListeners = new TEventListenerBase[0]
		_localEventListeners = new TEventListenerBase[0]

		' register new global listeners
		' none yet


		' === REGISTER CALLBACKS ===

		' to update/draw the screen
		screen.AddUpdateCallback(onUpdateScreen)
		screen.AddDrawCallback(onDrawScreen)

	End Method


	Method SetLanguage()
	End Method


	Method AbortScreenActions:Int()
		Return False
	End Method


	Method Draw:Int(tweenValue:Float) Final
		vendorSprite.Draw(vendorArea.GetX(), vendorArea.GetY())

		If dialogue then dialogue.Draw()
	End Method


	Method Update:Int(deltaTime:Float) Final
		if not dialogue and ..
		   not GetPlayerBase().GetFigure().isLeavingRoom() and ..
		   GetPlayerBase().GetFigure().GetInRoomID() > 0

			'just show the dialogue, do not require the player to first
			'click on the dude
			GenerateDialogue()
		endif

		if dialogue
			'leave the room
			if dialogue.Update() = 0
				dialogue = null
				GetPlayerBase().GetFigure().LeaveRoom()
			endif

			'prepare leaving - will remove room now
			If MOUSEMANAGER.IsClicked(2)
				dialogue = null
			endif

			'no mouse reset - we still want to leave the room
		endif
	End Method



	Function onDrawScreen:Int(sender:TScreen, tweenValue:Float)
		Return GetInstance().Draw(tweenValue)
	End Function

	Function onUpdateScreen:Int(sender:TScreen, deltaTime:Float)
		Return GetInstance().Update(deltaTime)
	End Function


	Function GenerateDialogue()

		'each array entry is a "topic" the chef could talk about
		local text:string

		text = GetRandomLocale("DIALOGUE_SUPERMARKET_TITLE")
		text :+ "~n~n"
		text :+ GetRandomLocale("DIALOGUE_SUPERMARKET_TEXT")

		text = text.replace("%PLAYERNAME%", GetPlayerBase().name)

		Local dialogueText:TDialogueTexts = TDialogueTexts.Create(text)
		'null = event when click
		dialogueText.AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_SUPERMARKET_PLAN_A_PRODUCTION"), 0, Null, onClickPlanAProduction))
		dialogueText.AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_SUPERMARKET_BUY_A_PRESENT"), 0, Null, onClickBuySomePresents))
		dialogueText.AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_SUPERMARKET_GOODBYE"), -2, Null))

		dialogue = new TDialogue
		dialogue.AddTexts([dialogueText])


		dialogue.SetArea(new TRectangle.Init(140, 40, 350, 90))
		dialogue.SetAnswerArea(new TRectangle.Init(200, 170, 350, 90))
		'dialogue.answerStartType = "StartDownRight"
		'dialogue.moveAnswerDialogueBalloonStart = 100
		dialogue.SetGrow(1,1)
	End Function


	Function onClickBuySomePresents(data:TData)
		ScreenCollection.GoToSubScreen("screen_supermarket_presents")
		dialogue = null
	End Function


	Function onClickPlanAProduction(data:TData)
		ScreenCollection.GoToSubScreen("screen_supermarket_production")
		dialogue = null
	End Function
End Type
