SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.player.base.bmx"
Import "game.screen.supermarket.production.bmx"
Import "game.screen.supermarket.presents.bmx"
Import "common.misc.dialogue.bmx"



Type RoomHandler_SuperMarket extends TRoomHandler
	Global dialogue:TDialogue
	Global _eventListeners:TLink[]
	Global _instance:RoomHandler_SuperMarket


	Function GetInstance:RoomHandler_SuperMarket()
		if not _instance then _instance = new RoomHandler_SuperMarket
		return _instance
	End Function

	
	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()

		'reset/initialize screens (event connection etc.)
		TScreenHandler_SupermarketProduction.GetInstance().Initialize()
		TScreenHandler_SupermarketPresents.GetInstance().Initialize()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]


		'=== register event listeners
		'handle the "office" itself (not computer etc)
		'using this approach avoids "tooltips" to be visible in subscreens
		_eventListeners :+ _RegisterScreenHandler( onUpdateSupermarket, onDrawSupermarket, ScreenCollection.GetScreen("screen_supermarket") )

		
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
		GetRoomHandlerCollection().SetHandler("supermarket", GetInstance())
	End Method


	Method SetLanguage()
		TScreenHandler_SupermarketProduction.GetInstance().SetLanguage()
		TScreenHandler_SupermarketPresents.GetInstance().SetLanguage()
	End Method


	'override: clear the screen (remove dragged elements)
	Method AbortScreenActions:Int()
		'abort handling dragged elements in the production / present
		'screens
		TScreenHandler_SupermarketProduction.GetInstance().AbortScreenActions()
		TScreenHandler_SupermarketPresents.GetInstance().AbortScreenActions()

		return False
	End Method


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
'		If MOUSEMANAGER.IsClicked(1)
'			MOUSEMANAGER.resetKey(1)
'			GetGameBase().cursorstate = 0

			ScreenCollection.GoToSubScreen("screen_supermarket_production")
			dialogue = null
'		endif
	End Function


	Function onDrawSupermarket:int( triggerEvent:TEventBase )
		If dialogue then dialogue.Draw()
	End Function


	Function onUpdateSupermarket:int( triggerEvent:TEventBase )
		if not dialogue and ..
		   not GetPlayerBase().GetFigure().isLeavingRoom() and ..
		   GetPlayerBase().GetFigure().GetInRoomID() > 0
		   ' not GetPlayerBase().GetFigure().isLeavingRoom()
rem
			'method a
			'require the player to click on the dude first
			
			'over dude
			if THelper.IsIn(MouseManager.x, MouseManager.y, 0,0,160,300)
				GetGameBase().cursorstate = 1
				If MOUSEMANAGER.IsClicked(1) and not MouseManager.IsLongClicked(1)
					MOUSEMANAGER.resetKey(1)
					GetGameBase().cursorstate = 0

					GenerateDialogue()
				endif
			endif
endrem

			'method b
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
			If MOUSEMANAGER.IsClicked(2) or MouseManager.IsLongClicked(1)
				dialogue = null
			endif

			'reset right clicks as long as dialogue exists
			'-> leave via "say good bye"
			rem
			If MOUSEMANAGER.IsClicked(2) or MouseManager.IsLongClicked(1)
				MOUSEMANAGER.resetKey(1)
				MOUSEMANAGER.resetKey(2)
			endif
			endrem
		endif
	End Function
End Type
