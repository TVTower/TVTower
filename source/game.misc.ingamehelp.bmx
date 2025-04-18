SuperStrict
Import "Dig/base.gfx.gui.textarea.bmx"
Import "Dig/base.gfx.gui.window.modal.bmx"
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "common.misc.gamegui.bmx"
Import "common.misc.screen.bmx"
Import "game.game.base.bmx"

Import "game.roomhandler.base.bmx"
Import "game.player.bmx"

Type TIngameHelpWindowCollection
	Field showHelp:Int = True
	Field currentIngameHelpWindow:TIngameHelpWindow {nosave}
	Global helpWindows:TStringMap = new TStringMap()
	Global currentIngameHelpWindowLocked:Int = False


	Method Add(window:TIngameHelpWindow)
		If Not window Then Return
		helpWindows.Insert(window.helpGUID.ToLower(), window)
	End Method


	Method Get:TIngameHelpWindow(helpGUID:String)
		Return TIngameHelpWindow( helpWindows.ValueForKey(helpGUID.toLower()))
	End Method


	Method SetCurrentByHelpGUID:Int(helpGUID:String)
		Return SetCurrent(Get(helpGUID))
	End Method


	Method SetCurrent:Int(currentWindow:TIngameHelpWindow)
		If currentIngameHelpWindow <> currentWindow
			'cannot set current if locked
			If currentIngameHelpWindowLocked Then Return False

			If currentIngameHelpWindow Then currentIngameHelpWindow.Remove()
		EndIf
		
		if currentIngameHelpWindow <> currentWindow
			currentIngameHelpWindow = currentWindow
			Return True
		EndIf
		
		Return False
	End Method


	Method GetCurrent:TIngameHelpWindow()
		Return currentIngameHelpWindow
	End Method


	Method LockCurrent()
		'you cannot lock without a window
		if currentIngameHelpWindow
			currentIngameHelpWindowLocked = True
		endif
	End Method

	Method openHelpWindow()
		Local player:TPlayer = GetPlayer()
		If player and player.GetFigure() and player.GetFigure().inRoom
			Local roomHandler:TRoomHandler = GetRoomHandlerCollection().GetHandler(player.GetFigure().inRoom.GetName())
			If roomHandler Then roomHandler.AbortScreenActions()
		End If

		Local screen:String = ScreenCollection.GetCurrentScreen().GetName()
		If Get(screen)
			ShowByHelpGUID(screen , True)
		Else
			ShowByHelpGUID("GameManual", True)
		EndIf
		'avoid that this window gets replaced by another one
		'until it is "closed"
		LockCurrent()
	End Method


	Method ShowByHelpGUID(helpGUID:String, force:Int = False)
		If Not force And currentIngameHelpWindowLocked Then Return

		If Not currentIngameHelpWindow Or currentIngameHelpWindow.helpGUID <> helpGUID.ToLower()
			if not SetCurrentByHelpGUID(helpGUID)
				Return
			EndIf
		EndIf
		If currentIngameHelpWindow
			'skip creating the very same visible window again
			If currentIngameHelpWindow.helpGUID.ToLower() = helpGUID.ToLower()
				If currentIngameHelpWindow.active Then Return
			EndIf
			If currentIngameHelpWindow.Show(force)
				TriggerBaseEvent(GameEventKeys.InGameHelp_ShowHelpWindow, New TData.Add("window", currentIngameHelpWindow) , Self)
			EndIf
		EndIf
	End Method

	Method Update:Int()
		If currentIngameHelpWindow
			Local wasClosing:Int = currentIngameHelpWindow.IsClosing()

			currentIngameHelpWindow.Update()

			If currentIngameHelpWindow.IsClosing()
				If Not wasClosing
					TriggerBaseEvent(GameEventKeys.InGameHelp_CloseHelpWindow, New TData.Add("window", currentIngameHelpWindow) , Self)
				EndIf

				currentIngameHelpWindowLocked = False
			ElseIf currentIngameHelpWindow.IsClosed()
				TriggerBaseEvent(GameEventKeys.InGameHelp_ClosedHelpWindow, New TData.Add("window", currentIngameHelpWindow) , Self)

				currentIngameHelpWindow = Null
			EndIf
		EndIf
	End Method


	Method Render:Int()
		If currentIngameHelpWindow
			currentIngameHelpWindow.Render()
		EndIf
	End Method
End Type
Global IngameHelpWindowCollection:TIngameHelpWindowCollection = New TIngameHelpWindowCollection




'easier to identify ingame help windows this way 
Type TIngameHelpModalWindow Extends TGUIGameModalWindow
End Type




Type TIngameHelpWindow
	Field area:TRectangle
	Field modalDialogue:TGUIModalWindow
	Field guiTextArea:TGUITextArea
	Field checkboxHideAll:TGUICHeckbox

	Field _eventListeners:TEventListenerBase[]
	Field active:Int = False
	Field helpGUID:String = "" 'id of the ingame help
	Field titleKey:String
	Field contentKey:String

	Field showHideOption:Int = True
	Field shownTimes:Int = 0
	Field showLimit:Int = -1

	Field state:TLowerString


	Method Init:TIngameHelpWindow(titleKey:String, contentKey:String, helpGUID:String)

		area = New TRectangle.Init(100, 20, 600, 350)

		Self.helpGUID = helpGUID.toLower()
		Self.contentKey = contentKey
		Self.titleKey = titleKey
		state = TLowerString.Create("INGAMEHELP_"+helpGUID)

		Return Self
	End Method


	Method Show:Int(force:Int = False)
		If Not force
			If Not IngameHelpWindowCollection.showHelp Then Return False

			'reached display limit?
			If showLimit > 0 And showLimit <= shownTimes Then Return False
		EndIf
		shownTimes :+ 1

		'clean up old widgets
		Remove()

		Local windowW:Int = 600
		Local windowH:Int = 320

		modalDialogue = New TIngameHelpModalWindow.Create(New SVec2I(0,0), New SVec2I(windowW, windowH), state.ToString())
		modalDialogue.SetManaged(False)
		modalDialogue.screenArea = area.Copy()

		modalDialogue._defaultValueColor = TColor.clBlack.copy()
		modalDialogue.defaultCaptionColor = TColor.clWhite.copy()

		modalDialogue.SetCaptionArea(New TRectangle.Init(-1, 6,-1, 30))
		modalDialogue.guiCaptionTextBox.SetValueAlignment( ALIGN_CENTER_TOP)

		if helpGUID = "gamemanual"
			modalDialogue.SetDialogueType(1)
			modalDialogue.buttons[0].SetCaption(GetLocale("OK"))
			modalDialogue.buttons[0].SetSize(150,-1)
		else
			modalDialogue.SetDialogueType(2)
			modalDialogue.buttons[0].SetCaption(GetLocale("OK"))
			modalDialogue.buttons[0].SetSize(150,-1)
			modalDialogue.buttons[1].SetCaption(GetLocale("MANUAL"))
			modalDialogue.buttons[1].SetSize(120,-1)
			modalDialogue.buttonCallbacks[1] = onClickCallback_ShowManual
			'move manual button to the most left
			modalDialogue.buttonPositionTemplate = 1
		endif


'		modalDialogue.SetOption(GUI_OBJECT_CLICKABLE, FALSE)

		modalDialogue.SetCaptionAndValue(GetLocale(titleKey), "")
	'	If modalDialogue.guiCaptionTextBox Then modalDialogue.guiCaptionTextBox.SetFont(.headerFont)



		Local canvas:TGUIObject = modalDialogue.GetGuiContent()
		guiTextArea = New TGUITextArea.Create(New SVec2I(0,0), New SVec2I(Int(canvas.GetContentWidth()), Int(canvas.GetContentHeight(-1) - 22 + 22 * (Not showHideOption))), state.ToString())
		'guiTextArea.Move(0,0)
		guiTextArea.SetFont( GetBitmapFont("default", 13) )
		guiTextArea.textColor = SColor8.Black
		guiTextArea.SetWordWrap(True)
		guiTextArea.SetValue( GetLocale(contentKey) )
		
		guiTextArea.SetManaged(False)

		canvas.AddChild(guiTextArea)


		Local checkboxWidth:Int = 0

		checkboxHideAll = New TGUICheckBox.Create(New SVec2I(0 + checkboxWidth,190), New SVec2I(-1,-1), "", state.ToString())
		checkboxHideAll.SetFont( GetBitmapFont("default", 11) )
'		checkboxHideAll.textColor = TColor.clBlack.Copy()
		checkboxHideAll.SetValue( GetLocale("DO_NOT_SHOW_ANY_TIPS"))
		checkboxHideAll.SetChecked(Not IngameHelpWindowCollection.showHelp)

		checkboxHideAll.SetManaged(False)
		canvas.AddChild(checkboxHideAll)
		If Not showHideOption
			checkboxHideAll.Hide()
		EndIf


		modalDialogue.Open()
		active = True
		
		'focus on the text area so we can control with "up down pageup..."
		GuiManager.SetFocus(guiTextArea)


		'=== EVENTS ===
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUICheckbox_OnSetChecked, Self, "OnSetCheckbox", checkboxHideAll) ]
	End Method
	
	
	Method Close:Int()
		modalDialogue.Close()
	End Method
	
	
	Function onClickCallback_ShowManual:Int(index:Int, sender:TGUIObject)
		IngameHelpWindowCollection.currentIngameHelpWindowLocked = False
'		IngameHelpWindowCollection.currentIngameHelpWindow.Close()
		IngameHelpWindowCollection.ShowByHelpGUID("GameManual", True)
	End Function
	

	Method EnableHideOption:Int(bool:Int)
		showHideOption = bool

		If guiTextArea And checkboxHideAll
			If Not showHideOption And checkboxHideAll.IsVisible()
				checkboxHideAll.Hide()
				guiTextArea.SetSize(-1, guiTextArea.rect.GetH() + checkboxHideAll.GetScreenRect().GetH())
			Else
				guiTextArea.SetSize(-1, guiTextArea.rect.GetH() - checkboxHideAll.GetScreenRect().GetH())
			EndIf
		EndIf
	End Method


	Method OnSetCheckbox:Int(triggerEvent:TEventBase)
		Local checkBox:TGUICheckBox = TGUICheckBox(triggerEvent.GetSender())
		If Not checkBox Then Return False

		If checkboxHideAll.IsChecked()
			IngameHelpWindowCollection.showHelp = False
		Else
			IngameHelpWindowCollection.showHelp = True
		EndIf
	End Method


	Method Remove:Int()
		'no need to remove the child GUI widgets individually ...
		'everything is handled via removal of the modalDialogue as the
		'other elements are children of that dialogue
		If modalDialogue Then modalDialogue.Remove()

		active = False

		EventManager.UnregisterListenersArray(_eventListeners)
	End Method


	Method IsClosed:Int()
		If Not modalDialogue Then Return True
		Return modalDialogue.IsClosed()
	End Method


	Method IsClosing:Int()
		If Not modalDialogue Then Return False
		Return modalDialogue.closeActionStarted And Not IsClosed()
	End Method


	Method Delete()
		Remove()
	End Method


	Method Update:Int()
		If active
			If modalDialogue.IsClosed() Then active = False
			If Not active Then Remove()


'			GuiManager.Update(state)
			modalDialogue.Update()

			if KeyManager.IsHit(KEY_ESCAPE)
				if GuiManager.GetFocus() = guiTextArea
					'do not allow another ESC-press for X ms
					KeyManager.blockKey(KEY_ESCAPE, 250)
					Close()
				EndIf
			endif

			'block right clicks?
			'no right clicking allowed as long as "help window" is active
			'MouseManager.SetClickHandled(2)

			'close the help, do not propagate right-click
			If MouseManager.IsClicked(2)
				Close()
				MouseManager.SetClickHandled(2)
			EndIf
		EndIf
	End Method


	Method Render:Int()
		if active
			'reset cursor in "draw" for now so "underlaying" element
			'modifications are ignored
			GetGameBase().SetCursor(TGameBase.CURSOR_DEFAULT)
		
			modalDialogue.Draw()
			'GuiManager.Draw(state)
		Endif
	End Method
End Type
