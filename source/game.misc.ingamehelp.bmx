SuperStrict
Import "../source/Dig/base.gfx.gui.textarea.bmx"
Import "../source/Dig/base.gfx.gui.window.modal.bmx"
Import "../source/Dig/base.gfx.gui.checkbox.bmx"


Type TIngameHelpWindowCollection
	Field showHelp:Int = True
	Field disabledHelpGUIDs:String[]
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
				EventManager.triggerEvent(TEventSimple.Create("InGameHelp.ShowHelpWindow", New TData.Add("window", currentIngameHelpWindow) , Self))
			EndIf
		EndIf
	End Method


	Method IsDisabledHelpGUID:Int(helpGUID:String)
		Return StringHelper.InArray(helpGUID, disabledHelpGUIDs, False)
	End Method


	Method EnableHelpGUID(helpGUID:String, bool:Int = True)
		Local arrIndex:Int = StringHelper.GetArrayIndex(helpGUID, disabledHelpGUIDs, False)

		'disable
		If Not bool
			If arrIndex < 0 Then disabledHelpGUIDs :+ [helpGUID]
		'enable
		Else
			If arrIndex >=0 Then StringHelper.RemoveArrayIndex(arrIndex, disabledHelpGUIDs)
		EndIf
	End Method


	Method Update:Int()
		If currentIngameHelpWindow
			Local wasClosing:Int = currentIngameHelpWindow.IsClosing()

			currentIngameHelpWindow.Update()

			If currentIngameHelpWindow.IsClosing()
				If Not wasClosing
					EventManager.triggerEvent(TEventSimple.Create("InGameHelp.CloseHelpWindow", New TData.Add("window", currentIngameHelpWindow) , Self))
				EndIf

				currentIngameHelpWindowLocked = False

				'disable this help
				If currentIngameHelpWindow.hideFlag = 1
					EnableHelpGUID(currentIngameHelpWindow.helpGUID, False)
				EndIf
				'disable help at all
				If currentIngameHelpWindow.hideFlag = 2
					showHelp = False
				EndIf
			ElseIf currentIngameHelpWindow.IsClosed()
				EventManager.triggerEvent(TEventSimple.Create("InGameHelp.ClosedHelpWindow", New TData.Add("window", currentIngameHelpWindow) , Self))

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




Type TIngameHelpWindow
	Field area:TRectangle
	Field modalDialogue:TGUIModalWindow
	Field guiTextArea:TGUITextArea
	Field checkboxHideThis:TGUICheckbox
	Field checkboxHideAll:TGUICHeckbox

	Field _eventListeners:TEventListenerBase[]
	Field active:Int = False
	Field helpGUID:String = "" 'id of the ingame help
	Field title:String
	Field content:String
	Field hideFlag:Int = 0 '1 = hide this, 2 = hide all

	Field showHideOption:Int = True
	Field shownTimes:Int = 0
	Field showLimit:Int = -1

	Field state:TLowerString


	Method Init:TIngameHelpWindow(title:String, content:String, helpGUID:String)

		area = New TRectangle.Init(100, 20, 600, 350)

		Self.helpGUID = helpGUID.toLower()
		Self.content = content
		Self.title = title
		state = TLowerString.Create("INGAMEHELP_"+helpGUID)

		Return Self
	End Method


	Method Show:Int(force:Int = False)
		If Not force
			If Not IngameHelpWindowCollection.showHelp Then Return False
			If IngameHelpWindowCollection.IsDisabledHelpGUID(helpGUID) Then Return False

			'reached display limit?
			If showLimit > 0 And showLimit < shownTimes Then Return False
		EndIf
		shownTimes :+ 1

		'clean up old widgets
		Remove()

		Local windowW:Int = 600
		Local windowH:Int = 320

		modalDialogue = New TGUIModalWindow.Create(New TVec2D, New TVec2D.Init(windowW, windowH), state.ToString())
		modalDialogue.SetManaged(False)
		modalDialogue.screenArea = area.Copy()

		modalDialogue._defaultValueColor = TColor.clBlack.copy()
		modalDialogue.defaultCaptionColor = TColor.clWhite.copy()

		modalDialogue.SetCaptionArea(New TRectangle.Init(-1, 6,-1, 30))
		modalDialogue.guiCaptionTextBox.SetValueAlignment( ALIGN_CENTER_TOP)

		modalDialogue.SetDialogueType(1)
		modalDialogue.buttons[0].SetCaption(GetLocale("OK"))
		modalDialogue.buttons[0].SetSize(180,-1)

'		modalDialogue.SetOption(GUI_OBJECT_CLICKABLE, FALSE)

		modalDialogue.SetCaptionAndValue(title, "")
	'	If modalDialogue.guiCaptionTextBox Then modalDialogue.guiCaptionTextBox.SetFont(.headerFont)



		Local canvas:TGUIObject = modalDialogue.GetGuiContent()
		guiTextArea = New TGUITextArea.Create(New TVec2D.Init(0,0), New TVec2D.Init(canvas.GetContentWidth(), canvas.GetContentHeight(-1) - 22 + 22 * (Not showHideOption)), state.ToString())
		'guiTextArea.Move(0,0)
		guiTextArea.SetFont( GetBitmapFont("default", 14) )
		guiTextArea.textColor = SColor8.Black
		guiTextArea.SetWordWrap(True)
		guiTextArea.SetValue( content )
		
		guiTextArea.SetManaged(False)

		canvas.AddChild(guiTextArea)


		Local checkboxWidth:Int = 0
		If Not IngameHelpWindowCollection.IsDisabledHelpGUID(helpGUID)
			checkboxHideThis = New TGUICheckBox.Create(New TVec2D.Init(0,190), New TVec2D.Init(-1,-1), "", state.ToString())
			checkboxHideThis.SetFont( GetBitmapFont("default", 12) )
	'		checkboxHideThis.textColor = TColor.clBlack.Copy()
			checkboxHideThis.SetValue( GetLocale("DO_NOT_SHOW_AGAIN") )
			checkboxHideThis.SetManaged(False)
			canvas.AddChild(checkboxHideThis)

			checkboxWidth = checkboxHideThis.GetScreenRect().GetW() + 20
		EndIf


		checkboxHideAll = New TGUICheckBox.Create(New TVec2D.Init(0 + checkboxWidth,190), New TVec2D.Init(-1,-1), "", state.ToString())
		checkboxHideAll.SetFont( GetBitmapFont("default", 12) )
'		checkboxHideAll.textColor = TColor.clBlack.Copy()
		checkboxHideAll.SetValue( GetLocale("DO_NOT_SHOW_ANY_TIPS") )

		checkboxHideAll.SetManaged(False)
		canvas.AddChild(checkboxHideAll)
		If Not showHideOption
			If checkboxHideThis Then checkboxHideThis.Hide()
			checkboxHideAll.Hide()
		EndIf


		modalDialogue.Open()
		active = True
		
		'focus on the text area so we can control with "up down pageup..."
		GuiManager.SetFocus(guiTextArea)


		'=== EVENTS ===
		_eventListeners :+ [ EventManager.registerListenerMethod("guiCheckBox.onSetChecked", Self, "OnSetCheckbox", checkboxHideAll) ]
		If checkboxHideThis
			_eventListeners :+ [ EventManager.registerListenerMethod("guiCheckBox.onSetChecked", Self, "OnSetCheckbox", checkboxHideThis) ]
		EndIf
	End Method


	Method EnableHideOption:Int(bool:Int)
		showHideOption = bool

		If guiTextArea And checkboxHideAll
			If Not showHideOption And checkboxHideAll.IsVisible()
				If checkboxHideThis Then checkboxHideThis.Hide()
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

		hideFlag = 0
		If checkboxHideAll.IsChecked()
			hideFlag = 2
		ElseIf checkboxHideThis And checkboxHideThis.IsChecked()
			hideFlag = 1
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

			'no right clicking allowed as long as "help window" is active
			MouseManager.SetClickHandled(2)
		EndIf
	End Method


	Method Render:Int()
'		print "render: "+helpGUID
		If active Then modalDialogue.Draw()
'		If active Then GuiManager.Draw(state)
	End Method
End Type