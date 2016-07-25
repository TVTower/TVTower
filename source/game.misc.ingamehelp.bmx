SuperStrict
Import "../source/Dig/base.gfx.gui.textarea.bmx"
Import "../source/Dig/base.gfx.gui.window.modal.bmx"
Import "../source/Dig/base.gfx.gui.checkbox.bmx"


Type TIngameHelpWindowCollection
	Field showHelp:int = True
	Field disabledHelpGUIDs:String[]
	Field currentIngameHelpWindow:TIngameHelpWindow {nosave}
	Global helpWindows:TMap = CreateMap()
	Global currentIngameHelpWindowLocked:int = False


	Method Add(window:TIngameHelpWindow)
		if not window then return
		helpWindows.Insert(window.helpGUID.ToLower(), window)
	End Method


	Method Get:TIngameHelpWindow(helpGUID:string)
		return TIngameHelpWindow( helpWindows.ValueForKey(helpGUID.toLower()))
	End Method


	Method SetCurrentByHelpGUID(helpGUID:string)
		SetCurrent(Get(helpGUID))
	End Method


	Method SetCurrent(currentWindow:TIngameHelpWindow)
		if currentIngameHelpWindow <> currentWindow
			'cannot set current if locked
			if currentIngameHelpWindowLocked then return
			
			if currentIngameHelpWindow then currentIngameHelpWindow.Remove()
		endif
		currentIngameHelpWindow = currentWindow
	End Method


	Method GetCurrent:TIngameHelpWindow()
		return currentIngameHelpWindow
	End Method


	Method LockCurrent()
		currentIngameHelpWindowLocked = true
	End Method


	Method ShowByHelpGUID(helpGUID:string, force:int = False)
		if not force and currentIngameHelpWindowLocked then return
	
		if not currentIngameHelpWindow or currentIngameHelpWindow.helpGUID <> helpGUID.ToLower()
			SetCurrentByHelpGUID(helpGUID)
		endif
		if currentIngameHelpWindow
			'skip creating the very same visible window again
			if currentIngameHelpWindow.helpGUID.ToLower() = helpGUID.ToLower()
				if currentIngameHelpWindow.active then return
			endif
			currentIngameHelpWindow.Show(force)

			EventManager.triggerEvent(TEventSimple.Create("InGameHelp.ShowHelpWindow", new TData.Add("window", currentIngameHelpWindow) , Self))
		endif
	End Method


	Method IsDisabledHelpGUID:int(helpGUID:string)
		return StringHelper.InArray(helpGUID, disabledHelpGUIDs, False)
	End Method


	Method EnableHelpGUID(helpGUID:string, bool:int = True)
		local arrIndex:int = StringHelper.GetArrayIndex(helpGUID, disabledHelpGUIDs, False)

		'disable
		if not bool
			if arrIndex < 0 then disabledHelpGUIDs :+ [helpGUID]
		'enable
		else
			if arrIndex >=0 then StringHelper.RemoveArrayIndex(arrIndex, disabledHelpGUIDs)
		endif
	End Method
	

	Method Update:int()
		if currentIngameHelpWindow
			local wasClosing:int = currentIngameHelpWindow.IsClosing()

			currentIngameHelpWindow.Update()

			if currentIngameHelpWindow.IsClosing()
				if not wasClosing
					EventManager.triggerEvent(TEventSimple.Create("InGameHelp.CloseHelpWindow", new TData.Add("window", currentIngameHelpWindow) , Self))
				endif
				
				currentIngameHelpWindowLocked = False

				'disable this help
				if currentIngameHelpWindow.hideFlag = 1
					EnableHelpGUID(currentIngameHelpWindow.helpGUID, False)
				endif
				'disable help at all
				if currentIngameHelpWindow.hideFlag = 2
					showHelp = False
				endif
			elseif currentIngameHelpWindow.IsClosed()
				EventManager.triggerEvent(TEventSimple.Create("InGameHelp.ClosedHelpWindow", new TData.Add("window", currentIngameHelpWindow) , Self))

				currentIngameHelpWindow = null
			endif
		endif
	End Method


	Method Render:int()
		if currentIngameHelpWindow
			currentIngameHelpWindow.Render()
		endif
	End Method
End Type
Global IngameHelpWindowCollection:TIngameHelpWindowCollection = new TIngameHelpWindowCollection




Type TIngameHelpWindow
	Field area:TRectangle
	Field modalDialogue:TGUIModalWindow
	Field guiTextArea:TGUITextArea
	Field checkboxHideThis:TGUICheckbox
	Field checkboxHideAll:TGUICHeckbox

	Field _eventListeners:TLink[]
	Field active:int = False
	Field helpGUID:string = "" 'id of the ingame help
	Field title:string
	Field content:string
	Field hideFlag:int = 0 '1 = hide this, 2 = hide all

	Field showHideOption:int = True
	Field shownTimes:int = 0
	Field showLimit:int = -1

	

	Method Init:TIngameHelpWindow(title:string, content:string, helpGUID:string)
		
		area = new TRectangle.Init(100, 20, 600, 350)

		self.helpGUID = helpGUID.toLower()
		self.content = content
		self.title = title

		return self
	End Method


	Method Show:int(force:int = False)
		if not force
			if not IngameHelpWindowCollection.showHelp then return False
			if IngameHelpWindowCollection.IsDisabledHelpGUID(helpGUID) then return False

			'reached display limit?
			if showLimit > 0 and showLimit < shownTimes then return False
		endif
		shownTimes :+ 1

		'clean up old widgets
		Remove()

		Local windowW:Int = 600
		Local windowH:Int = 320

		modalDialogue = New TGUIModalWindow.Create(New TVec2D, New TVec2D.Init(windowW, windowH), "INGAMEHELP_"+helpGUID)
		modalDialogue.screenArea = area.Copy()

		modalDialogue._defaultValueColor = TColor.clBlack.copy()
		modalDialogue.defaultCaptionColor = TColor.clWhite.copy()

		modalDialogue.SetCaptionArea(New TRectangle.Init(-1,10,-1,25))
		modalDialogue.guiCaptionTextBox.SetValueAlignment("CENTER", "TOP")

		modalDialogue.SetDialogueType(1)
		modalDialogue.buttons[0].SetCaption(GetLocale("OK"))
		modalDialogue.buttons[0].Resize(180,-1)

'		modalDialogue.SetOption(GUI_OBJECT_CLICKABLE, FALSE)

		modalDialogue.SetCaptionAndValue(title, "")
	'	If modalDialogue.guiCaptionTextBox Then modalDialogue.guiCaptionTextBox.SetFont(.headerFont)



		Local canvas:TGUIObject = modalDialogue.GetGuiContent()
		guiTextArea = New TGUITextArea.Create(new TVec2D.Init(0,0), new TVec2D.Init(532,188 + 22 * (not showHideOption)), "INGAMEHELP_"+helpGUID)
		'guiTextArea.Move(0,0)
		guiTextArea.SetFont( GetBitmapFont("default", 14) )
		guiTextArea.textColor = TColor.clBlack.Copy()
		guiTextArea.SetWordWrap(True)
		guiTextArea.SetValue( content )

		canvas.AddChild(guiTextArea)

		local checkboxWidth:int = 0
		if not IngameHelpWindowCollection.IsDisabledHelpGUID(helpGUID)
			checkboxHideThis = New TGUICheckBox.Create(new TVec2D.Init(0,190), new TVec2D.Init(-1,-1), "", "INGAMEHELP_"+helpGUID)
			checkboxHideThis.SetFont( GetBitmapFont("default", 12) )
	'		checkboxHideThis.textColor = TColor.clBlack.Copy()
			checkboxHideThis.SetValue( GetLocale("DO_NOT_SHOW_AGAIN") )
			canvas.AddChild(checkboxHideThis)

			checkboxWidth = checkboxHideThis.GetScreenWidth() + 20
		endif


		checkboxHideAll = New TGUICheckBox.Create(new TVec2D.Init(0 + checkboxWidth,190), new TVec2D.Init(-1,-1), "", "INGAMEHELP_"+helpGUID)
		checkboxHideAll.SetFont( GetBitmapFont("default", 12) )
'		checkboxHideAll.textColor = TColor.clBlack.Copy()
		checkboxHideAll.SetValue( GetLocale("DO_NOT_SHOW_ANY_TIPS") )

		canvas.AddChild(checkboxHideAll)
		if not showHideOption
			if checkboxHideThis then checkboxHideThis.Hide()
			checkboxHideAll.Hide()
		endif


		modalDialogue.Open()
		active = True


		'=== EVENTS ===
		_eventListeners :+ [ EventManager.registerListenerMethod("guiCheckBox.onSetChecked", self, "OnSetCheckbox", checkboxHideAll) ]
		if checkboxHideThis
			_eventListeners :+ [ EventManager.registerListenerMethod("guiCheckBox.onSetChecked", self, "OnSetCheckbox", checkboxHideThis) ]
		endif
	End Method


	Method EnableHideOption:int(bool:int)
		showHideOption = bool

		if guiTextArea and checkboxHideAll
			if not showHideOption and checkboxHideAll.IsVisible()
				if checkboxHideThis then checkboxHideThis.Hide()
				checkboxHideAll.Hide()
				guiTextArea.Resize(-1, guiTextArea.rect.GetH() + checkboxHideAll.GetScreenheight())
			else
				guiTextArea.Resize(-1, guiTextArea.rect.GetH() - checkboxHideAll.GetScreenheight())
			endif
		endif
	End Method


	Method OnSetCheckbox:int(triggerEvent:TEventBase)
		local checkBox:TGUICheckBox = TGUICheckBox(triggerEvent.GetSender())
		if not checkBox then return False

		hideFlag = 0
		if checkboxHideAll.IsChecked()
			hideFlag = 2
		elseif checkboxHideThis and checkboxHideThis.IsChecked()
			hideFlag = 1
		endif
	End Method


	Method Remove:int()
		'no need to remove the child GUI widgets individually ...
		'everything is handled via removal of the modalDialogue as the
		'other elements are children of that dialogue
		if modalDialogue then modalDialogue.Remove()

		active = False
		
		EventManager.unregisterListenersByLinks(_eventListeners)
	End Method


	Method IsClosed:int()
		if not modalDialogue then return True
		return modalDialogue.IsClosed()
	End Method


	Method IsClosing:int()
		if not modalDialogue then return False
		return modalDialogue.closeActionStarted and not IsClosed()
	End Method


	Method Delete()
		Remove()
	End Method


	Method Update:int()
		if active
			if modalDialogue.IsClosed() then active = False
			if not active then Remove()

			GuiManager.Update("INGAMEHELP_"+helpGUID)

			'no right clicking allowed as long as "help window" is active
			MouseManager.ResetKey(2)
			'also avoid long-clicking (touch)
			MouseManager.ResetLongClicked(1)
		endif
	End Method


	Method Render:int()
'		print "render: "+helpGUID
		if active then GuiManager.Draw("INGAMEHELP_"+helpGUID)
	End Method
End Type