'INCLUDED FILE
Type TGUIModalMainMenu Extends TGUIModalWindowChainElement
	Field buttons:TGUIButton[]
	Field chainSettingsMenu:TGUIModalWindowChainElement
	Field chainLoadMenu:TGUIModalWindowChainElement
	Field chainSaveMenu:TGUIModalWindowChainElement


	Method New()
'		className= "TGUIModalMainMenu"
	End Method


	Method Create:TGUIModalMainMenu(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		Local canvas:TGUIObject = GetGuiContent()
		Local buttonsY:Int = 10


		Local buttonsText:String[] = ["CONTINUE_GAME", "LOAD_GAME", "SAVE_GAME", "MENU_SETTINGS", "EXIT_TO_MAINMENU", "EXIT_GAME"]
		buttons = buttons[ .. buttonsText.length]
		For Local i:Int = 0 Until buttons.length
			'move exit-buttons a bit down
			If i >= 4
				buttons[i] = New TGUIButton.Create(New SVec2I(0, buttonsY + 10 + i*40), New SVec2I(Int(canvas.GetContentScreenRect().w), -1), GetLocale(buttonsText[i]), "")
			Else
				buttons[i] = New TGUIButton.Create(New SVec2I(0, buttonsY + i*40), New SVec2I(Int(canvas.GetContentScreenRect().w), -1), GetLocale(buttonsText[i]), "")
			EndIf
			AddChild(buttons[i])
			AddEventListener( EventManager.RegisterListenerMethod(GUIEventKeys.GUIObject_OnClick, Self, "onButtonClick", buttons[i]) )
		Next

		If guiCaptionTextBox
			guiCaptionTextBox.SetFont(headerFont)
			guiCaptionTextBox.SetSize(-1,-1)
			SetCaptionArea(New TRectangle.Init(-1, 6, -1, 30))
		EndIf

		Return Self
	End Method


	Method Activate:Int()
		'reset gui states
		For Local i:Int = 0 Until buttons.length
			if buttons[i].IsActive() Then GUIManager.SetActive(Null)
			buttons[i].SetHovered(False)
		Next
	End Method


	'override to remove all known submenus
	Method Remove:Int()
		Super.Remove()
		If chainSaveMenu
			chainSaveMenu.Remove()
			chainSaveMenu = Null
		EndIf
		If chainLoadMenu
			chainLoadMenu.Remove()
			chainLoadMenu = Null
		EndIf
		If chainSettingsMenu
			chainSettingsMenu.Remove()
			chainSettingsMenu = Null
		EndIf
	End Method


	Method onButtonClick:Int(triggerEvent:TEventBase)
		Local clickedButton:TGUIButton = TGUIButton( triggerEvent.GetSender() )
		If Not clickedButton Then Return False

		Select clickedButton
			Case buttons[0]
				Close()

			Case buttons[1]
				If Not chainLoadMenu
					chainLoadMenu = New TGUIModalLoadSavegameMenu.Create(New SVec2I(0,0), New SVec2I(520,356), "SYSTEM")
					chainLoadMenu._defaultValueColor = TColor.clBlack.copy()
					chainLoadMenu.defaultCaptionColor = TColor.clWhite.copy()
					'set self as previous one
					chainLoadMenu.previousChainElement = Self
				EndIf
				'set new one as the active one
				SwitchActive( chainLoadMenu )

			Case buttons[2]
				If Not chainSaveMenu
					chainSaveMenu = New TGUIModalSaveSavegameMenu.Create(New SVec2I(0,0), New SVec2I(520,356), "SYSTEM")
					chainSaveMenu._defaultValueColor = TColor.clBlack.copy()
					chainSaveMenu.defaultCaptionColor = TColor.clWhite.copy()
					'set self as previous one
					chainSaveMenu.previousChainElement = Self
				EndIf
				'set new one as the active one
				SwitchActive( chainSaveMenu )

			Case buttons[3]
				If Not chainSettingsMenu
					chainSettingsMenu = New TGUIModalSettingsMenu.Create(New SVec2I(0,0), New SVec2I(700,535), "SYSTEM")
					chainSettingsMenu._defaultValueColor = TColor.clBlack.copy()
					chainSettingsMenu.defaultCaptionColor = TColor.clWhite.copy()
					'set self as previous one
					chainSettingsMenu.previousChainElement = Self
				EndIf
				TGUIModalSettingsMenu(chainSettingsMenu).SetGuiValues(App.config)

				'set new one as the active one
				SwitchActive( chainSettingsMenu )

			Case buttons[4]
				'create extra dialog
				TApp.CreateConfirmExitAppDialogue(True)
				Close()

			Case buttons[5]
				'create extra dialog
				TApp.CreateConfirmExitAppDialogue(False)
				Close()
		End Select
	End Method
	
	
	Method Draw() override
		'reset cursor in "draw" for now so "underlaying" element
		'modifications are ignored
		GetGameBase().SetCursor(TGameBase.CURSOR_DEFAULT)

		Super.Draw()
	End Method
	
Rem
	'override
	Method OnReposition(dx:Float, dy:Float)
		If dx = 0 And dy = 0 Then Return

		Super.OnReposition(dx, dy)

		For local i:int = 0 until buttons.length
			buttons[i].OnReposition(dx,dy)
		Next
	End Method


	Method OnParentReposition(parent:TGUIObject, dx:Float, dy:Float)
		Super.OnParentReposition(parent,dx,dy)

		For local i:int = 0 until buttons.length
			buttons[i].OnParentReposition(self, dx,dy)
		Next
	End Method
endrem
End Type




Type TGUIModalSettingsMenu Extends TGUIGameModalWindowChainDialogue
	Field settingsPanel:TGUISettingsPanel
	Field _eventListeners:TEventListenerBase[]


	Method Create:TGUIModalSettingsMenu(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)
		SetDialogueType(2)

		dialogueButtons[0].SetCaption(GetLocale("SAVE_AND_APPLY"))
		dialogueButtons[0].SetSize(180,-1)
		dialogueButtons[1].SetCaption(GetLocale("CANCEL"))
		dialogueButtons[1].SetSize(160,-1)

		SetCaptionAndValue(GetLocale("MENU_SETTINGS"), "")

		If guiCaptionTextBox
			guiCaptionTextBox.SetFont(headerFont)
			guiCaptionTextBox.SetSize(-1,-1)
			SetCaptionArea(New TRectangle.Init(-1, 6, -1, 30))
		EndIf

		'use the gfx with content inset (and padding)
		guiBackground.spriteBaseName = "gfx_gui_modalWindow"



		settingsPanel = New TGUISettingsPanel.Create(New SVec2I(0,0), New SVec2I(700, 535), "SYSTEM")
		'add to canvas of this window
		'GetGuiContent()
		AddChild(settingsPanel)


		'=== EVENTS ===
		'listen to clicks on "load savegame"
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIButton_Onclick, Self, "onApplySettings", dialogueButtons[0]) ]

		Return Self
	End Method


	Method onApplySettings:Int( triggerEvent:TEventBase )
		App.ApplyConfigToSettings( ReadGuiValues() )
		Return True
	End Method


Global LS_modalSettingsMenu:TLowerString = TLowerString.Create("modalSettings")
	Method Update:Int()
'		GuiManager.Update( LS_modalSettingsMenu )
		Super.Update()
	End Method


	Method DrawContent()
		Super.DrawContent()

'		GuiManager.Draw( LS_modalSettingsMenu )
	End Method


	'override
	Method Activate:Int()
	End Method


	Method Remove:Int()
		Super.Remove()

		If settingsPanel Then settingsPanel.remove()
		settingsPanel = Null

		'remove all event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]
	End Method


	Method SetGuiValues:Int(data:TData)
		If settingsPanel Then Return settingsPanel.SetGuiValues(data)
	End Method


	Method ReadGuiValues:TData()
		If settingsPanel Then Return settingsPanel.ReadGuiValues()
		Return New TData
	End Method
End Type




Type TGUIModalLoadSavegameMenu Extends TGUIGameModalWindowChainDialogue
	Field savegameList:TGUISelectList
	Field _eventListeners:TEventListenerBase[]
	Field _onLoadSavegameFunc:Int()
	Field doSetManualFocus:Int
	Global LS_modalLoadMenu:TLowerString = TLowerString.Create("modalloadmenu")

	Method Create:TGUIModalLoadSavegameMenu(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)
		SetDialogueType(2)
		dialogueButtons[0].SetCaption(GetLocale("LOAD_GAME"))
		dialogueButtons[1].SetCaption(GetLocale("CANCEL"))

		SetCaption(GetLocale("LOAD_GAME"))

		'use the gfx with content inset (and padding)
		guiBackground.spriteBaseName = "gfx_gui_modalWindow"

'		Local canvas:TGUIObject = GetGuiContent()

		savegameList = New TGUISelectList.Create(New SVec2I(0, 0), New SVec2I(Int(GetContentScreenRect().w),80), "MODALLOADMENU")

		AddChild(savegameList)

		If guiCaptionTextBox
			guiCaptionTextBox.SetFont(headerFont)
			guiCaptionTextBox.SetSize(-1,-1)
			SetCaptionArea(New TRectangle.Init(-1, 6, -1, 30))
		EndIf

		'=== EVENTS ===
		'listen to clicks on "load savegame"
		_eventListeners :+ [ EventManager.RegisterListenerMethod(GUIEventKeys.GUIButton_OnClick, Self, "onClickLoadSavegame") ]
		_eventListeners :+ [ EventManager.RegisterListenerMethod(GameEventKeys.SaveGame_OnLoad, Self, "onLoadSavegame") ]

		Return Self
	End Method

	'override
	Method Activate:Int()
		'remove previous entries
		savegamelist.EmptyList()

		Local dirTree:TDirectoryTree = New TDirectoryTree.SimpleInit()
		dirTree.SetIncludeFileEndings([TGameConfig.compressedSavegameExtension, TGameConfig.uncompressedSavegameExtension])
		dirTree.ScanDir(TSavegame.GetSavegamePath(), True)
		Local fileURIs:String[] = dirTree.GetFiles()

		'disable autosort - handled via "compare()" now
		'savegameList.autoSortItems = False

		'loop over all filenames
		For Local fileURI:String = EachIn fileURIs
			'skip non-existent files
			If FileSize(fileURI) = 0 Then Continue
			Local item:TGUISavegameListItem = New TGUISavegameListItem.Create(Null, Null, "savegame " + fileURI)

			'make compatible "FORCEFULLY"
			If Keymanager.IsDown(KEY_LSHIFT)
				item.SetSavegameFile(fileURI, True)
			Else
				item.SetSavegameFile(fileURI, False)
			EndIf
			
			savegameList.AddItem(item)
		Next
		
		'try to preselect last used item
		Local foundEntry:Int = False
		If GameConfig.savegame_lastUsedName	
			For Local i:TGUISavegameListItem = EachIn savegameList.entries
				Local fileURI:String = i.GetFileInformation().GetString("fileURI")
				If TSavegame.GetSavegameName(fileURI) = GameConfig.savegame_lastUsedName
					savegameList.SelectEntry(i)

					SelectButton(0)
					
					foundEntry = True
					Exit
				EndIf
			Next
		EndIf

		If Not foundEntry
			savegameList.SelectEntry( savegameList.GetFirstItem() )
		EndIf

		doSetManualFocus = True
	End Method


	Method Remove:Int()
		Super.Remove()
		If savegameList Then savegameList.remove()
		Self.savegameList = Null

		'remove all event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

	End Method


	Method Update:Int()
		If doSetManualFocus
			doSetManualFocus = False
			GUIManager.SetFocus(savegamelist)
		EndIF
	
		GuiManager.Update( LS_modalLoadMenu )

		local loadableEntry:Int = True
		local item:TGUISaveGameListItem = TGUISaveGameListItem(savegameList.getSelectedEntry())
		if not item then loadableEntry = False
		if item and item.fileState < 0 then loadableEntry = False

		'disable/enable load-button
		If Not loadableEntry
			If dialogueButtons[0].isEnabled() Then dialogueButtons[0].disable()
		Else
			If Not dialogueButtons[0].isEnabled() Then dialogueButtons[0].enable()
		EndIf


		'handle Enter-Key
		If KeyManager.IsHit(KEY_ENTER)
			'avoid others getting triggered too (eg. chat)
			KeyManager.ResetKey(KEY_ENTER)

			If dialogueButtons[0].isEnabled()
				LoadSelectedSaveGame()
			EndIf
		EndIf

		Super.Update()
	End Method


	Method DrawContent()
		Super.DrawContent()

		GuiManager.Draw( LS_modalLoadMenu )
	End Method


	Method LoadSelectedSaveGame:Int()
		Local selectedItem:TGUISaveGameListItem = TGUISaveGameListItem(savegameList.getSelectedEntry())
		If Not selectedItem Then Return False

		Local fileURI:String = selectedItem.GetFileInformation().GetString("fileURI")
		Local fileName:String = TSaveGame.GetSavegameName(fileURI)

		if selectedItem.fileState >= 0
			'close self
			Back()

			'close escape menu
			If App.EscapeMenuWindow
				App.EscapeMenuWindow.Close()
			ElseIf TGUIModalWindowChain(_parent)
				TGUIModalWindowChain(_parent).SetClosed()
				TGUIModalWindowChain(_parent).Close()
			EndIf

			TSaveGame.Load(fileURI, fileName, True, True)

			Return True
		EndIf

		Return False
	End Method


	Method UpdateLayout()
		Super.UpdateLayout()

		If savegameList
			savegameList.SetSize(GetContentScreenRect().GetW(), GetContentScreenRect().GetH())
'			savegameList.RecalculateElements()
		EndIf
	End Method


	Method onLoadSavegame:Int( triggerEvent:TEventBase )
		'close escape menu regardless of "loading/saving" via
		'shortcut or gui?
		Return True
	End Method


	Method onClickLoadSavegame:Int( triggerEvent:TEventBase )
		Local button:TGUIButton = TGUIButton(triggerEvent.GetSender())
		If Not button Then Return False


		If button = dialogueButtons[0]
			If Not LoadSelectedSaveGame()
				triggerEvent.SetVeto(True)
				Return False
			EndIf
		ElseIf button = dialogueButtons[1]
			Close()
		EndIf

		Return True
	End Method
End Type




Type TGUIModalSaveSavegameMenu Extends TGUIGameModalWindowChainDialogue
	Field savegameList:TGUISelectList
	Field savegameName:TGUIInput
	Field savegameNameLabel:TGUILabel
	Field _eventListeners:TEventListenerBase[]
	Field doSetManualFocus:Int = False
	Field lastSavegameName:String

	Global _confirmOverwriteDialogue:TGUIModalWindow
	Global LS_modalSaveMenu:TLowerString = TLowerString.Create("modalsavemenu")


	Method Create:TGUIModalSaveSavegameMenu(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)
		SetDialogueType(2)
		dialogueButtons[0].SetCaption(GetLocale("SAVE_GAME"))
		dialogueButtons[1].SetCaption(GetLocale("CANCEL"))

		SetCaption(GetLocale("SAVE_GAME"))

		'use the gfx with content inset (and padding)
		guiBackground.spriteBaseName = "gfx_gui_modalWindow"

'		Local canvas:TGUIObject = GetGuiContent()

		savegameName = New TGUIInput.Create(New SVec2I(0,0), New SVec2I(Int(GetContentScreenRect().w), 40), "", 64, "MODALSAVEMENU")
		savegameNameLabel = New TGUILabel.Create(New SVec2I(0, 0), "")
		savegameList = New TGUISelectList.Create(New SVec2I(0, Int(savegameName.GetScreenRect().h)), New SVec2I(Int(GetContentScreenRect().w),80), "MODALSAVEMENU")

		AddChild(savegameName)
		AddChild(savegameNameLabel)
		AddChild(savegameList)

		If guiCaptionTextBox
			guiCaptionTextBox.SetFont(headerFont)
			SetCaptionArea(New TRectangle.Init(-1, 6, -1, 30))
			guiCaptionTextBox.SetSize(-1,-1)
		EndIf

		'=== EVENTS ===
		'listen to clicks on "save savegame"
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIButton_OnClick, Self, "onClickSaveSavegame") ]
		'listen to clicks on the list
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUISelectList_OnSelectEntry, Self, "onClickOnSavegameEntry") ]
		'select entry according input content
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIInput_OnChangeValue, Self, "onChangeSavegameNameInputValue") ]
		'register to quit confirmation dialogue
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIModalWindow_OnClose, Self, "onConfirmOverwrite" ) ]

		'localize texts
		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.App_OnSetLanguage, Self, "onSetLanguage" ) ]

		'(re-)localize
		SetLanguage()
		Return Self
	End Method


	'override
	Method Activate:Int()
		'remove previous entries
		savegamelist.EmptyList()

		'restore last name used to save a game
		savegameName.SetValue(GameConfig.savegame_lastUsedName)

		SelectButton(-1) 'deselect buttons
		'SelectButton(1) 'select abort

		'fill existing savegames
		Local dirTree:TDirectoryTree = New TDirectoryTree.SimpleInit()
		dirTree.SetIncludeFileEndings([TGameConfig.compressedSavegameExtension, TGameConfig.uncompressedSavegameExtension])
		dirTree.ScanDir(TSavegame.GetSavegamePath(), True)
		Local fileURIs:String[] = dirTree.GetFiles()

		'loop over all filenames
		For Local fileURI:String = EachIn fileURIs
			'skip non-existent files
			If FileSize(fileURI) = 0 Then Continue
			Local item:TGUISavegameListItem = New TGUISavegameListItem.Create(Null, Null, "savegame " + fileURI)
			item.SetSavegameFile(fileURI, True)
			savegameList.AddItem(item)
		Next

		'select and activate input field if NO name was entered yet!
		If Not GetSavegameNameValue()
			doSetManualFocus = True
		EndIf
	End Method


	Method SetLanguage()
		If savegameNameLabel
			savegameNameLabel.SetValue( GetLocale("NAME_OF_SAVEGAME") + ":" )
		EndIf
	End Method
	

	Method Remove:Int()
		Super.Remove()
		If savegameList Then savegameList.remove()
		Self.savegameList = Null

		If savegameName Then savegameName.remove()
		Self.savegameName = Null

		If savegameNameLabel Then savegameNameLabel.remove()
		Self.savegameNameLabel = Null

		'remove all event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]
	End Method


	Method Update:Int()
		If doSetManualFocus
			doSetManualFocus = False
			GUIManager.SetFocus( savegameName )
		EndIF
		
		GuiManager.Update( LS_modalSaveMenu )


		'focus save button?
		'only if we previously were using the savename input or the 
		'savegame selection list!
		'this avoids breaking the "tab through buttons" functions
rem
		If savegameName.IsFocused() or savegameList.IsFocused()
			If GetSavegameNameValue()
				'only select if no other was selected already
				If GetSelectedButtonIndex() = -1
					SelectButton(0)
				EndIf
			ElseIf GetSelectedButtonIndex() = 0
				SelectButton(1)
			EndIf
		EndIf
endrem

		'disable/enable load-button (check current value to react during
		'typing already)
		If GetSavegameNameValue() = ""
			If dialogueButtons[0].isEnabled() Then dialogueButtons[0].disable()
		Else
			If Not dialogueButtons[0].isEnabled() Then dialogueButtons[0].enable()
		EndIf

		If not savegameName.IsActive()
			Local selectButtonIndex:Int = GetSelectedButtonIndex()
			If GetSavegameNameValue()
				'only select if no other was selected already
				If GetSelectedButtonIndex() = -1 
					selectButtonIndex = 0
				EndIf
'			ElseIf GetSelectedButtonIndex() = 0
'				selectButtonIndex = 1
			'select abort/cancel if save is no longer enabled
			ElseIf not dialogueButtons[0].isEnabled() and GetSelectedButtonIndex() <> 1
				selectButtonIndex = 1
			EndIf

			'select the desired button - but if it is not enabled, select the cancel (1) button
			If GetSelectedButtonIndex() <> selectButtonIndex
				If selectButtonIndex >= 0 and selectButtonIndex <> 1 and dialogueButtons[selectButtonIndex].isEnabled()
					SelectButton(selectButtonIndex)
				ElseIf GetSelectedButtonIndex() <> 1
					SelectButton(1)
				EndIf
			EndIf
		'deactivate buttons if the input is active (name entered now)
		ElseIf GetSelectedButtonIndex() <> -1
			SelectButton(-1)
		EndIf


		'handle Enter-Key (except something like an input is reading input)
		If KeyManager.IsHit(KEY_ENTER) And Not GuiManager.GetKeyboardInputReceiver()
'print "ENTER " + Millisecs() + "   GetSelectedButtonIndex()="+GetSelectedButtonIndex() + "   dialogueButtons[0].isEnabled()="+dialogueButtons[0].isEnabled()
			'avoid others getting triggered too (eg. chat)
			'also avoids a popup confirm dialogue to see enter on next 
			'update
			KeyManager.blockKey(KEY_ENTER, 250)
		
			If GetSelectedButtonIndex() = 0 and dialogueButtons[0].isEnabled()
				SaveSavegame(GetSavegameNameValue())
			ElseIf GetSelectedButtonIndex() = 1 and dialogueButtons[1].isEnabled()
				Back()
			EndIf
		EndIf

		Super.Update()
	End Method


	Method DrawContent()
		Super.DrawContent()

		GuiManager.Draw( LS_modalSaveMenu )
	End Method
	
	
	Method GetSavegameNameValue:String()
		'ensure to use "GetCurrentValue()" (whatever is stored "inside"
		'input - instead of "GetValue()" which uses the last value before
		'the input became active
		Return savegameName.GetCurrentValue()
	End Method


	Method CreateConfirmOverwriteDialogue:Int(fileURI:String)
		If _confirmOverwriteDialogue Then Return False
		_confirmOverwriteDialogue = New TGUIGameModalWindow.Create(New SVec2I(0,0), New SVec2I(400,150), "SYSTEM")
		_confirmOverwriteDialogue.guiCaptionTextBox.SetFont(headerFont)

		_confirmOverwriteDialogue._defaultValueColor = TColor.clBlack.copy()
		_confirmOverwriteDialogue.defaultCaptionColor = TColor.clWhite.copy()
		_confirmOverwriteDialogue.SetCaptionArea(New TRectangle.Init(-1, 6, -1, 30))
		_confirmOverwriteDialogue.guiCaptionTextBox.SetValueAlignment( ALIGN_CENTER_TOP )

		_confirmOverwriteDialogue.SetDialogueType(2)
		_confirmOverwriteDialogue.SetZIndex(100001)
		_confirmOverwriteDialogue.SetCaptionAndValue( GetLocale("OVERWRITE_SAVEGAME"), GetLocale("DO_YOU_REALLY_WANT_TO_OVERWRITE_SAVEGAME_X").Replace("%SAVEGAME%", "~q|i|"+fileURI+"|/i|~q") )

		_confirmOverwriteDialogue.darkenedArea = New TRectangle.Init(0,0,800,385)
		'center to this area
		_confirmOverwriteDialogue.screenArea = New TRectangle.Init(0,0,800,385)

		_confirmOverwriteDialogue.Open()
		
		_confirmOverwriteDialogue.SelectButton(0) 'preselect "yes"
	End Method


	Method SaveSavegame:Int(fileName:String, skipFileCheck:Int = False)
		If Not fileName Then Return False

		'check for both variants: compressed and uncompressed
		Local fileURI:String = TSavegame.GetSavegameURI(fileName)
		Local fileURI1:String = TSavegame.GetSavegameURI(fileName, True)
		Local fileURI2:String = TSavegame.GetSavegameURI(fileName, False)

		'if savegame exists already, create confirmation dialogue
		If Not skipFileCheck And (FileType(fileURI1) = 1 or FileType(fileURI2) = 1)
			CreateConfirmOverwriteDialogue(fileName)
			Return False
		EndIf

		TSaveGame.Save(fileURI, fileName, True)

		'close self
'		Back()
'		Close()

		'close escape menu
		If App.EscapeMenuWindow Then App.EscapeMenuWindow.Close()

		Return True
	End Method



	Method UpdateLayout()
		Super.UpdateLayout()

		Local addH:Int = 0
		If savegameNameLabel
			savegameNameLabel.SetSize(GetContentScreenRect().GetW(), -1)
			addH :+ savegameNameLabel.GetScreenRect().GetH() + 18
		EndIf
		If savegameName
			savegameName.SetSize(GetContentScreenRect().GetW(), -1)
			savegameName.SetPosition(0, 0 + addH)
			addH :+ savegameName.GetScreenRect().GetH() + 5
		EndIf
		If savegameList
			savegameList.SetSize(GetContentScreenRect().GetW(), GetContentScreenRect().GetH() - addH)
			savegameList.SetPosition(0, 0 + addH)
			'savegameList.RecalculateElements()
		EndIf
	End Method


	'=== EVENTS ===

	'override
	Method onButtonClick:Int( triggerEvent:TEventBase )
		'skip "save" button handling - we go back if we do not
		'have to confirm or "saved"
		If dialogueButtons[0] = triggerEvent._sender Then Return False

		Super.onButtonClick(triggerEvent)
	End Method


	Method onSetLanguage:Int( triggerEvent:TEventBase )
		SetLanguage()
	End Method


	Method onConfirmOverwrite:Int( triggerEvent:TEventBase )
		'only react to confirmation dialogue
		If _confirmOverwriteDialogue <> triggerEvent._sender Then Return False

		Local buttonNumber:Int = triggerEvent.GetData().getInt("closeButton",-1)

		'approve overwrite
		If buttonNumber = 0
			SaveSavegame(GetSavegameNameValue(), True)
		EndIf

		'remove connection to dialogue (guimanager takes care of fading)
		_confirmOverwriteDialogue = Null
	End Method


	Method onChangeSavegameNameInputValue:Int( triggerEvent:TEventBase )
		Local guiInput:TGUIInput = TGUIInput(triggerEvent._sender)
		if not guiInput then Return False
		Local newName:String = GetSavegameNameValue()
		
		Local refocus:Int
		If guiInput.IsFocused() then refocus = True

		'loop through all savegames and select the one with the name
		'(if there is none, select nothing)
		savegameList.deselectEntry()
		'attention: does select by filename (ignoring subdirectories)
		'           which might lead to the wrong file selected if the
		'           list contains multiple savegames with the same name
		'           but in different directories
		For Local i:TGUISavegameListItem = EachIn savegameList.entries
			Local fileName:String = i.GetFileInformation().GetString("fileURI")
			If TSavegame.GetSavegameName(fileName) = newName
				savegameList.SelectEntry(i)

'				SelectButton(0)

				If refocus 
					GUIManager.SetActive(guiInput)
					GUIManager.SetFocus(guiInput)
				EndIf
				Return True
			EndIf
		Next

		Return False
	End Method


	Method onClickSaveSavegame:Int( triggerEvent:TEventBase )
		Local button:TGUIButton = TGUIButton(triggerEvent.GetSender())
		If Not button Or button <> dialogueButtons[0] Then Return False

		If Not SaveSavegame(GetSavegameNameValue())
			triggerEvent.SetVeto(True)
			Return False
		EndIf

		Return True
	End Method


	'fill the name of the selected entry as savegame name
	Method onClickOnSavegameEntry:Int( triggerEvent:TEventBase )
		Local entry:TGUISaveGameListItem = TGUISaveGameListItem(triggerEvent._receiver)
		If Not entry Then Return False

		Local fileName:String = TSavegame.GetSavegameName( entry.GetFileInformation().GetString("fileURI") )

		If savegameName.IsActive()
			savegameName._SetActive(False)
			GUIManager.SetActive(Null)
			GUIManager.ResetFocus()
		EndIf
		savegameName.SetValue( fileName )
	End Method

End Type



Type TGUISavegameListItem Extends TGUISelectListItem
	Field paddingBottom:Int = 12
	Field paddingTop:Int = 4
	Field fileInformation:TData = Null
	Field fileState:Int = 0
	Global _typeDefaultFont:TBitmapFont

    Method Create:TGUISavegameListItem(position:SVec2I, dimension:SVec2I, value:String="")
		Super.Create(position, dimension, value)

		'resize it
		GetDimension()

		Return Self
	End Method


	Method onAddAsChild:Int(parent:TGUIObject)
		'resize it
		GetDimension()
	End Method


	Function SetTypeFont:Int(font:TBitmapFont)
		_typeDefaultFont = font
	End Function


	'override in extended classes if wanted
	Function GetTypeFont:TBitmapFont()
		Return _typeDefaultFont
	End Function


	Method Compare:Int( other:Object )
		Local otherItem:TGUISavegameListItem = TGUISavegameListItem(other)
		If otherItem
			Local timeA:Int = GetFileInformation().GetInt("fileTime", 0)
			Local timeB:Int = otherItem.GetFileInformation().GetInt("fileTime", 0)
			If timeA < timeB Then Return 1
			If timeA > timeB Then Return -1
		EndIf

		Return Super.Compare(other)
	End Method


	Method SetSavegameFile(fileURI:String, skipFileChecks:Int = False)
		fileInformation = TSavegame.GetGameSummary(fileURI)

		If skipFilechecks
			fileState = 1
		Else
			fileState = TSavegame.CheckFilestate(fileURI, fileInformation, True)
		EndIf

		If fileState < 0
			Self.Disable()
		Else
			Self.Enable()
		EndIf
	End Method


	Method GetFileInformation:TData()
		If Not fileInformation Then fileInformation = New TData
		Return fileInformation
	End Method


	Method GetDimension:SVec2F() override
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(GetFirstParentalObject("tguiscrollablepanel"))

		Local maxWidth:Int = 170
		If parentPanel Then maxWidth = parentPanel.GetContentScreenRect().GetW()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		'2 lines of text
		Local w:Float = maxWidth
		Local h:Float = 2 * GetBitmapFontManager().baseFont.GetMaxCharHeight()

		'add padding
		h :+ Self.paddingTop
		h :+ Self.paddingBottom

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.w <> w Or Self.rect.h <> h
			'resize item
			Self.SetSize(w, h)
		EndIf

		Return new SVec2F(w, h)
	End Method


	Method DrawContent()
		Local time:Long = GetFileInformation().GetLong("game_timegone", 0)
		Local gameTime:String = GetWorldTime().getFormattedTime(time)+" "+getLocale("DAY")+" "+GetWorldTime().getDayOfYear(time)+"/"+GetWorldTime().GetDaysPerYear()+" "+GetWorldTime().getYear(time)
		Local col:SColor8 = new SColor8(100,105,140)
		Local playerCol:SColor8 = new SColor8(70, 75, 110)
		Local headCol:SColor8 = new SColor8.White 'TColor.Create(150,90,0)
		Local width:Int = GetContentScreenRect().GetW() - 4

		Local leftX:Int = GetContentScreenRect().GetX() + 2
		Local oldAlpha:Float = GetAlpha()
		Local useAlpha:Float = oldAlpha * GetScreenAlpha()
		SetAlpha useAlpha

		local compressionInfo:string
		'add info note to uncompressed savegames if compression is enabled
		'and vice versa if not
		Local fileExtension:String = ExtractExt(GetFileInformation().GetString("fileURI")).ToLower()
		If GameConfig.compressSavegames
			If fileExtension = GameConfig.uncompressedSavegameExtension
				compressionInfo = "  |color=220,220,230|"+GameConfig.uncompressedSavegameExtension+"|/color|"
			EndIf
		Else
			If fileExtension = GameConfig.compressedSavegameExtension
				compressionInfo = "  |color=220,220,230|"+GameConfig.compressedSavegameExtension+"|/color|"
			EndIf
		EndIf
		GetBitmapFontManager().baseFont.DrawBox("|b|"+GetFileInformation().GetString("fileName")+"|/b|" + compressionInfo, leftX, GetScreenRect().GetY() + Self.paddingTop, 0.70*width, 20, sALIGN_LEFT_TOP, headCol, EDrawTextEffect.Shadow, 0.6)
		GetFont().DrawBox("|b|"+GetLocale("PLAYER")+":|/b| " + GetFileInformation().GetString("player_name", "unknown player"), leftX, GetScreenRect().GetY() + 15 + Self.paddingTop, 0.25 * width, 20, sALIGN_LEFT_TOP, playerCol, EDrawTextEffect.Shadow, 0.25)
		GetFont().DrawBox("|b|"+GetLocale("GAMETIME")+":|/b| "+gameTime, leftX + 0.65 * width, GetScreenRect().GetY() + Self.paddingTop, 0.35 * width, 20, sALIGN_RIGHT_CENTER, col)
		GetFont().DrawBox("|b|"+GetLocale("MONEY")+":|/b| "+MathHelper.DottedValue(GetFileInformation().GetInt("player_money", 0)), leftX + 0.60 * width, GetScreenRect().GetY() + 15 + Self.paddingTop, 0.40 * width, 20, sALIGN_RIGHT_CENTER, col)

		SetAlpha useAlpha * 0.30
		DrawRect(leftX, GetScreenRect().GetY() + GetScreenRect().GetH() - 1, width, 1)
		SetAlpha oldAlpha
	End Method
	
	
	Method DrawOverlay() override
		Super.DrawOverlay()

		if fileState < 0
			Local oldAlpha:Float = GetAlpha()
			Local useAlpha:Float = oldAlpha * GetScreenAlpha()
			SetAlpha useAlpha

			Local width:Int = GetContentScreenRect().GetW() - 4 - 10 - 80
			Local leftX:Int = GetContentScreenRect().GetX() + 2 + 40
			SetColor 200,80,0
			SetAlpha useAlpha * 0.3
			DrawRect(leftX + 10, GetScreenRect().GetY() + 10,  width, GetScreenRect().GetH() - 20)
			SetAlpha useAlpha
			SetColor 255,255,255
			if fileState = -1
				GetFont().DrawBox(GetLocale("FILE_NOT_FOUND"), leftX, GetScreenRect().GetY() + 10, width, GetScreenRect().GetH() - 20, sALIGN_CENTER_CENTER, SColor8.White, EDrawTextEffect.Shadow, 0.25)
			elseif fileState = -2
				GetFont().DrawBox(GetLocale("INVALID_SAVEGAME"), leftX, GetScreenRect().GetY() + 10, width, GetScreenRect().GetH() - 20, sALIGN_CENTER_CENTER, SColor8.White, EDrawTextEffect.Shadow, 0.25)
			else
				GetFont().DrawBox(GetLocale("INCOMPATIBLE_SAVEGAME"), leftX, GetScreenRect().GetY() + 10, width, GetScreenRect().GetH() - 20, sALIGN_CENTER_CENTER, SColor8.White, EDrawTextEffect.Shadow, 0.25)
			endif
			SetAlpha oldAlpha
		endif
	End Method
End Type
