'INCLUDED FILE
Type TGUIModalMainMenu extends TGUIModalWindowChainElement
	Field buttons:TGUIButton[]
	Field chainLoadMenu:TGUIModalWindowChainElement
	Field chainSaveMenu:TGUIModalWindowChainElement


	Method Create:TGUIModalMainMenu(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		Local canvas:TGUIObject = GetGuiContent()

		local buttonsText:string[] = ["CONTINUE_GAME", "LOAD_GAME", "SAVE_GAME", "MENU_SETTINGS", "EXIT_TO_MAINMENU", "EXIT_GAME"]
		buttons = buttons[ .. buttonsText.length]
		for local i:int = 0 until buttons.length
			if i > 4
				buttons[i] = New TGUIButton.Create(New TVec2D.Init(0, 5 + 10 + i*40), New TVec2D.Init(canvas.GetContentScreenWidth(), -1), GetLocale(buttonsText[i]), "")
			else
				buttons[i] = New TGUIButton.Create(New TVec2D.Init(0, 5 + i*40), New TVec2D.Init(canvas.GetContentScreenWidth(), -1), GetLocale(buttonsText[i]), "")
			endif
			canvas.AddChild(buttons[i])
			AddEventListener( EventManager.RegisterListenerMethod("guiobject.onClick", self, "onButtonClick", buttons[i]) )
		next
		'move exit-button a bit down
		buttons[4].rect.position.AddY(10)

		If guiCaptionTextBox
			guiCaptionTextBox.SetFont(.headerFont)
			guiCaptionTextBox.Resize(-1,-1)
			SetCaptionArea(New TRectangle.Init(-1, 5, -1, 25))
		Endif
		
		return self
	End Method


	Method Activate:int()
		'reset gui states
		For local i:int = 0 until 5
			buttons[i].SetState("")
		Next
	End Method


	'override to remove all known submenus
	Method Remove:int()
		super.Remove()
		if chainSaveMenu then chainSaveMenu.Remove()
		if chainLoadMenu then chainLoadMenu.Remove()
	End Method
	

	Method onButtonClick:int(triggerEvent:TEventBase)
		local clickedButton:TGUIButton = TGUIButton( triggerEvent.GetSender() )
		if not clickedButton then return False

		Select clickedButton
			case buttons[0]
				Close()

			case buttons[1]
				if not chainLoadMenu
					chainLoadMenu = new TGUIModalLoadSavegameMenu.Create(New TVec2D, New TVec2D.Init(450,350), "SYSTEM")
					chainLoadMenu._defaultValueColor = TColor.clBlack.copy()
					chainLoadMenu.defaultCaptionColor = TColor.clWhite.copy()
					'set self as previous one
					chainLoadMenu.previousChainElement = self
				endif
				'set new one as the active one
				SwitchActive( chainLoadMenu )

			case buttons[2]
				if not chainSaveMenu
					chainSaveMenu = new TGUIModalSaveSavegameMenu.Create(New TVec2D, New TVec2D.Init(450,350), "SYSTEM")
					chainSaveMenu._defaultValueColor = TColor.clBlack.copy()
					chainSaveMenu.defaultCaptionColor = TColor.clWhite.copy()
					'set self as previous one
					chainSaveMenu.previousChainElement = self
				endif
				'set new one as the active one
				SwitchActive( chainSaveMenu )
				
			case buttons[4]
				'create extra dialog
				TApp.CreateConfirmExitAppDialogue(True)
				Close()
				
			case buttons[5]
				'create extra dialog
				TApp.CreateConfirmExitAppDialogue(False)
				Close()
		End Select
	End Method
End Type




Type TGUIModalLoadSavegameMenu extends TGUIModalWindowChainDialogue
	Field savegameList:TGUISelectList
	Field _eventListeners:TLink[]


	Method Create:TGUIModalLoadSavegameMenu(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)
		SetDialogueType(2)
		dialogueButtons[0].SetCaption(GetLocale("LOAD_GAME"))
		dialogueButtons[1].SetCaption(GetLocale("CANCEL"))

		SetCaption(GetLocale("LOAD_GAME"))

		'use the gfx with content inset (and padding)
		guiBackground.spriteBaseName = "gfx_gui_modalWindow"

		Local canvas:TGUIObject = GetGuiContent()

		savegameList = new TGUISelectList.Create(new TVec2D.Init(GetContentScreenX(), GetContentScreenY()), new TVec2D.Init(GetContentScreenWidth(),80), "MODALLOADMENU")
'		savegameList.rect.position.SetXY(GetContentScreenX(), GetContentScreenY())


		If guiCaptionTextBox
			guiCaptionTextBox.SetFont(.headerFont)
			guiCaptionTextBox.Resize(-1,-1)
			SetCaptionArea(New TRectangle.Init(-1, 5, -1, 25))
		Endif

		'=== EVENTS ===
		'listen to clicks on "load savegame"
		'_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onclick", onClickLoadSavegame, dialogueButtons[0]) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guibutton.onclick", self, "onClickLoadSavegame") ]

		return self
	End Method


	'override
	Method Activate:int()
		local dirTree:TDirectoryTree = new TDirectoryTree.Init(TSavegame.GetSavegamePath(), ["xml"], null, ["*"])
		dirTree.AddIncludeFileNames(["*"])
		dirTree.ScanDir()
		local fileURIs:String[] = dirTree.GetFiles()
		'loop over all filenames
		for local fileURI:String = EachIn fileURIs
			'skip non-existent files
			if filesize(fileURI) = 0 then continue
			local item:TGUISavegameListItem = new TGUISavegameListItem.Create(null, null, "savegame " + fileURI)
			item.SetSavegameFile(fileURI)
			savegameList.AddItem(item)
		Next
	End Method
	

	Method Remove:int()
		super.Remove()
		if savegameList then savegameList.remove()
		self.savegameList = null

		'remove all event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]
	
	End Method


	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w,h)
		if savegameList
			savegameList.Resize(GetContentScreenWidth(), GetContentScreenHeight())
			savegameList.RecalculateElements()
		endif
	End Method


	Method onRecenter()
		Super.onRecenter()
		'as long as a list cannot be the child element of a window
		'we have to move them manually (and unparented)
		if savegameList 
			savegameList.rect.position.SetXY(GetContentScreenX(), GetContentScreenY())
		endif
	End Method


	Method Update()
		GuiManager.Update("MODALLOADMENU")

		'disable/enable load-button
		if not TGUISaveGameListItem(savegameList.getSelectedEntry())
			if dialogueButtons[0].isEnabled() then dialogueButtons[0].disable()
		else
			if not dialogueButtons[0].isEnabled() then dialogueButtons[0].enable()
		endif


		'handle Enter-Key
		if KeyManager.IsHit(KEY_ENTER)
			'avoid others getting triggered too (eg. chat)
			KeyManager.ResetKey(KEY_ENTER)

			if dialogueButtons[0].isEnabled()
				LoadSelectedSaveGame()
			endif
		endif

		Super.Update()
	End Method


	Method DrawContent()
		Super.DrawContent()

		GuiManager.Draw("MODALLOADMENU")
	End Method


	Method LoadSelectedSaveGame:int()
		local selectedItem:TGUISaveGameListItem = TGUISaveGameListItem(savegameList.getSelectedEntry())
		if not selectedItem then return False

		local fileName:string = selectedItem.GetFileInformation().GetString("fileURI")
		local fileURI:string = TSavegame.GetSavegameURI(fileName)

		if FileType(fileURI) = 1
			TSaveGame.Load(fileURI)
			'close escape menu
			App.EscapeMenuWindow.Close()
			
			return True
		endif

		return False
	End Method


	Method onClickLoadSavegame:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent.GetSender())
		if not button or button <> dialogueButtons[0] then return False

	
		if not LoadSelectedSaveGame()
			triggerEvent.SetVeto(True)
			return false
		endif

		return True
	End Method
End Type



Type TGUIModalSaveSavegameMenu extends TGUIModalWindowChainDialogue
	Field savegameList:TGUISelectList
	Field savegameName:TGUIInput
	Field savegameNameLabel:TGUILabel
	Field _eventListeners:TLink[]

	Global _confirmOverwriteDialogue:TGUIModalWindow

	Method Create:TGUIModalSaveSavegameMenu(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)
		SetDialogueType(2)
		dialogueButtons[0].SetCaption(GetLocale("SAVE_GAME"))
		dialogueButtons[1].SetCaption(GetLocale("CANCEL"))

		SetCaption(GetLocale("SAVE_GAME"))

		'use the gfx with content inset (and padding)
		guiBackground.spriteBaseName = "gfx_gui_modalWindow"

		Local canvas:TGUIObject = GetGuiContent()

		savegameName = new TGUIInput.Create(new TVec2D.Init(GetContentScreenX(), GetContentScreenY()), new TVec2D.Init(GetContentScreenWidth(), 40), "", 64, "MODALSAVEMENU")
		savegameNameLabel = New TGUILabel.Create(New TVec2D.Init(0, 0), "", null, "MODALSAVEMENU")


		savegameList = new TGUISelectList.Create(new TVec2D.Init(GetContentScreenX(), GetContentScreenY() + savegameName.GetScreenHeight()), new TVec2D.Init(GetContentScreenWidth(),80), "MODALSAVEMENU")

'		savegameList.rect.position.SetXY(GetContentScreenX(), GetContentScreenY())
		savegameName.rect.position.SetXY(GetContentScreenX(), GetContentScreenY())


		If guiCaptionTextBox
			guiCaptionTextBox.SetFont(.headerFont)
			SetCaptionArea(New TRectangle.Init(-1, 5, -1, 25))
			guiCaptionTextBox.Resize(-1,-1)
		Endif

		'=== EVENTS ===
		'listen to clicks on "save savegame"
		_eventListeners :+ [ EventManager.registerListenerMethod( "guibutton.onclick", self, "onClickSaveSavegame") ]
		'listen to clicks on the list
		_eventListeners :+ [ EventManager.registerListenerMethod( "GUISelectList.onSelectEntry", self, "onClickOnSavegameEntry") ]
		'select entry according input content
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiinput.onChangeValue", self, "onChangeSavegameNameInputValue") ]
		'register to quit confirmation dialogue
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiModalWindow.onClose", self, "onConfirmOverwrite" ) ]

		'localize texts
		_eventListeners :+ [ EventManager.registerListenerMethod( "Language.onSetLanguage", self, "onSetLanguage" ) ]
		
		'(re-)localize
		SetLanguage()
		return self
	End Method


	'override
	Method Activate:int()
		'fill existing savegames
		local dirTree:TDirectoryTree = new TDirectoryTree.Init(TSavegame.GetSavegamePath(), ["xml"], null, ["*"])
		dirTree.AddIncludeFileNames(["*"])
		dirTree.ScanDir()
		local fileURIs:String[] = dirTree.GetFiles()
		'loop over all filenames
		for local fileURI:String = EachIn fileURIs
			'skip non-existent files
			if filesize(fileURI) = 0 then continue
			local item:TGUISavegameListItem = new TGUISavegameListItem.Create(null, null, "savegame " + fileURI)
			item.SetSavegameFile(fileURI)
			savegameList.AddItem(item)
		Next
	End Method
		

	Method SetLanguage()
		if savegameNameLabel
			savegameNameLabel.SetValue( GetLocale("NAME_OF_SAVEGAME") + ":" )
		endif
	End Method


	Method Remove:int()
		super.Remove()
		if savegameList then savegameList.remove()
		self.savegameList = null

		if savegameName then savegameName.remove()
		self.savegameName = null

		'remove all event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]
	
	End Method


	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w,h)

		local addH:int = 0
		if savegameNameLabel
			savegameNameLabel.Resize(GetContentScreenWidth(), -1)
			addH :+ savegameNameLabel.GetScreenHeight() + 15
		endif
		if savegameName
			savegameName.Resize(GetContentScreenWidth(), -1)
			addH :+ savegameName.GetScreenHeight() + 5
		endif
		if savegameList
			savegameList.Resize(GetContentScreenWidth(), GetContentScreenHeight() - addH)
			savegameList.RecalculateElements()
		endif
	End Method


	Method onRecenter()
		Super.onRecenter()
		'as long as a list cannot be the child element of a window
		'we have to move them manually (and unparented)
		local addH:int = 0
		if savegameNameLabel
			savegameNameLabel.rect.position.SetXY(GetContentScreenX(), GetContentScreenY())
			addH :+ savegameNameLabel.GetScreenHeight() + 15
		endif
		if savegameName
			savegameName.rect.position.SetXY(GetContentScreenX(), GetContentScreenY() + addH)
			addH :+ savegameName.GetScreenHeight() + 5
		endif

		if savegameList 
			savegameList.rect.position.SetXY(GetContentScreenX(), GetContentScreenY() + addH)
		endif
	End Method


	Method Update()
		GuiManager.Update("MODALSAVEMENU")

		'disable/enable load-button
		if savegameName.GetValue() = ""
			if dialogueButtons[0].isEnabled() then dialogueButtons[0].disable()
		else
			if not dialogueButtons[0].isEnabled() then dialogueButtons[0].enable()
		endif


		'handle Enter-Key
		if KeyManager.IsHit(KEY_ENTER)
			'avoid others getting triggered too (eg. chat)
			KeyManager.ResetKey(KEY_ENTER)

			if dialogueButtons[0].isEnabled()
				SaveSavegame(savegameName.GetValue())
			endif
		endif

		Super.Update()
	End Method


	Method DrawContent()
		Super.DrawContent()

		GuiManager.Draw("MODALSAVEMENU")
	End Method


	Method CreateConfirmOverwriteDialogue:int(fileURI:string)
		if _confirmOverwriteDialogue then return False
		_confirmOverwriteDialogue = New TGUIModalWindow.Create(New TVec2D, New TVec2D.Init(400,150), "SYSTEM")
		_confirmOverwriteDialogue.guiCaptionTextBox.SetFont(.headerFont)

		_confirmOverwriteDialogue._defaultValueColor = TColor.clBlack.copy()
		_confirmOverwriteDialogue.defaultCaptionColor = TColor.clWhite.copy()
		_confirmOverwriteDialogue.SetCaptionArea(New TRectangle.Init(-1,10,-1,25))
		_confirmOverwriteDialogue.guiCaptionTextBox.SetValueAlignment("CENTER", "TOP")
		
		_confirmOverwriteDialogue.SetDialogueType(2)
		_confirmOverwriteDialogue.SetZIndex(100001)
		_confirmOverwriteDialogue.SetCaptionAndValue( GetLocale("OVERWRITE_SAVEGAME"), GetLocale("DO_YOU_REALLY_WANT_TO_OVERWRITE_SAVEGAME_X").replace("%SAVEGAME%", fileURI) )

		_confirmOverwriteDialogue.darkenedArea = New TRectangle.Init(0,0,800,385)
		'center to this area
		_confirmOverwriteDialogue.screenArea = New TRectangle.Init(0,0,800,385)
	End Method


	Method SaveSavegame:int(fileName:string, skipFileCheck:int = False)
		if not fileName then return False

		local fileURI:string = TSavegame.GetSavegameURI(fileName)

		'if savegame exists already, create confirmation dialogue
		if not skipFileCheck and filetype(fileURI) = 1
			CreateConfirmOverwriteDialogue(fileURI)
			return False
		endif

		TSaveGame.Save(fileURI)
		'close escape menu
		App.EscapeMenuWindow.Close()

		return True
	End Method




	'=== EVENTS ===

	'override
	Method onButtonClick:Int( triggerEvent:TEventBase )
		'skip "save" button handling - we go back if we do not
		'have to confirm or "saved"
		if dialogueButtons[0] = triggerEvent._sender then return False

		Super.onButtonClick(triggerEvent)
	End Method


	Method onSetLanguage:int( triggerEvent:TEventBase )
		SetLanguage()
	End Method


	Method onConfirmOverwrite:int( triggerEvent:TEventBase )
		'only react to confirmation dialogue
		if _confirmOverwriteDialogue <> triggerEvent._sender then return False
		
		Local buttonNumber:Int = triggerEvent.GetData().getInt("closeButton",-1)
		
		'approve overwrite
		If buttonNumber = 0
			SaveSavegame(savegameName.GetValue(), True)
		endif

		'remove connection to dialogue (guimanager takes care of fading)
		_confirmOverwriteDialogue = Null
	End Method
	

	Method onChangeSavegameNameInputValue:int( triggerEvent:TEventBase )
		local newName:string = TGUIObject(triggerEvent._sender).GetValue()

		'loop through all savegames and select the one with the name
		'(if there is none, select nothing)
		savegameList.deselectEntry()
		'attention: does select by filename (ignoring subdirectories)
		'           which might lead to the wrong file selected if the
		'           list contains multiple savegames with the same name
		'           but in different directories
		For local i:TGUISavegameListItem = EachIn savegameList.entries
			local fileName:string = i.GetFileInformation().GetString("fileURI")
			if TSavegame.GetSavegameName(fileName) = newName
				savegameList.SelectEntry(i)
				return True
			endif
		Next

		return False
	End Method


	Method onClickSaveSavegame:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent.GetSender())
		if not button or button <> dialogueButtons[0] then return False

		if not SaveSavegame(savegameName.GetValue())
			triggerEvent.SetVeto(True)
			return false
		endif

		return True
	End Method


	'fill the name of the selected entry as savegame name
	Method onClickOnSavegameEntry:int( triggerEvent:TEventBase )
		local entry:TGUISaveGameListItem = TGUISaveGameListItem(triggerEvent.GetData().Get("entry"))
		if not entry then return False

		local fileName:string = TSavegame.GetSavegameName( entry.GetFileInformation().GetString("fileURI") )

		savegameName.SetValue( fileName )
	End Method

End Type



Type TGUISavegameListItem extends TGUISelectListItem
	Field paddingBottom:Int = 12
	Field paddingTop:Int = 4
	Field fileInformation:TData = null
	Global _typeDefaultFont:TBitmapFont

    Method Create:TGUISavegameListItem(position:TVec2D=null, dimension:TVec2D=null, value:String="")
		Super.Create(position, dimension, value)

		'resize it
		GetDimension()

		return self
	End Method


	Method onAddAsChild:int(parent:TGUIObject)
		'resize it
		GetDimension()
	End Method

	
	Function SetTypeFont:Int(font:TBitmapFont)
		_typeDefaultFont = font
	End Function


	'override in extended classes if wanted
	Function GetTypeFont:TBitmapFont()
		return _typeDefaultFont
	End Function
	

	Method SetSavegameFile(fileURI:string)
		local stream:TStream = ReadStream(fileURI)
		if not stream
			print "file not found: "+fileURI
			return
		endif

		local lines:string[]
		local line:string = ""
		local lineNum:int = 0
		While not EOF(stream)
			line = stream.ReadLine()
			
			if line.Find("name=~q_Game~q type=~qTGame~q>") > 0
				exit
			endif
			
			lines :+ [line]
			lineNum :+ 1

			if lineNum = 4 and not line.Find("name=~q_gameSummary~q type=~qTData~q>") > 0
				print "unknown savegamefile"
				fileInformation = new TData
				return
			endif
		Wend
		'remove line 3 and 4
		lines[2] = ""
		lines[3] = ""
		'remove last line / let the bmo-file end there
		lines[lines.length-1] = "</bmo>"
		
		local content:string = "~n".Join(lines)

		local p:TPersist = new TPersist
		fileInformation = TData(p.DeserializeObject(content))

		fileInformation.Add("fileURI", fileURI)
	End Method


	Method GetFileInformation:TData()
		if not fileInformation then fileInformation = new TData
		return fileInformation
	End Method


	'override
	Method GetDimension:TVec2D()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))

		Local maxWidth:Int = 150
		If parentPanel Then maxWidth = parentPanel.getContentScreenWidth()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		'2 lines of text
		Local dimension:TVec2D = New TVec2D.Init(maxWidth, 2 * GetBitmapFontManager().baseFont.GetMaxCharHeight())

		'add padding
		dimension.addXY(0, Self.paddingTop)
		dimension.addXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.Resize(dimension.getX(), dimension.getY())
		EndIf

		Return dimension
	End Method


	Method DrawContent()
		local time:Double = GetFileInformation().GetDouble("game_timegone", 0)
		local gameTime:string = GetWorldTime().getFormattedTime(time)+" "+getLocale("DAY")+" "+GetWorldTime().getDayOfYear(time)+"/"+GetWorldTime().GetDaysPerYear()+" "+GetWorldTime().getYear(time)
		local col:TColor = TColor.Create(120,125,160)
		local playerCol:TColor = TColor.Create(80, 85, 120)
		local headCol:TColor = TColor.clWhite 'TColor.Create(150,90,0)
		local width:int = GetScreenWidth()

		GetBitmapFont("",-1, BOLDFONT).DrawBlock(StripDir(GetFileInformation().GetString("fileURI")), GetScreenX(), GetScreenY() + self.paddingTop, width, 15, null, headCol, TBitmapFont.STYLE_SHADOW, 1, 0.5, TRUE)
		GetFont().DrawBlock("|b|"+GetLocale("GAMETIME")+":|/b| "+gameTime, GetScreenX() + 0.45 * width, GetScreenY() + self.paddingTop, 0.55 * width, 15, ALIGN_RIGHT_CENTER, col, 0, 1, 0.5, TRUE)
		GetFont().DrawBlock("|b|"+GetLocale("PLAYER")+":|/b| " + GetFileInformation().GetString("player_name", "unknown player"), GetScreenX(), GetScreenY() + 15 + self.paddingTop, 0.25 * width, 15, null, playerCol, TBitmapFont.STYLE_SHADOW, 1, 0.2, TRUE)
		GetFont().DrawBlock("|b|"+GetLocale("MONEY")+":|/b| "+GetFileInformation().GetInt("player_money", 0), GetScreenX() + 0.45 * width, GetScreenY() + 15 + self.paddingTop, 0.55 * width, 15, ALIGN_RIGHT_CENTER, col, 0, 1, 0.5, TRUE)

		local oldAlpha:Float = GetAlpha()
		SetAlpha oldAlpha * 0.25
		DrawRect(GetScreenX(), GetScreenY() + GetScreenHeight() - 1, GetContentScreenWidth(), 1)
		SetAlpha oldAlpha
	End Method
End Type