SuperStrict
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "Dig/base.gfx.gui.label.bmx"
Import "Dig/base.gfx.gui.input.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "common.misc.gamegui.bmx" 'tguigamewindow / chat / ...
Import "game.screen.base.bmx"
Import "game.network.networkhelper.base.bmx"
Import "game.player.boss.bmx"


'MENU: GAME SETTINGS SCREEN
Type TScreen_GameSettings Extends TGameScreen
	Field guiSettingsWindow:TGUIGameWindow
	Field guiAnnounce:TGUICheckBox
	Field gui24HoursDay:TGUICheckBox
	Field guiSpecialFormats:TGUICheckBox
	Field guiFilterUnreleased:TGUICheckBox
	Field guiGameTitleLabel:TGuiLabel
	Field guiGameTitle:TGuiInput
	Field guiStartYearLabel:TGuiLabel
	Field guiStartYear:TGuiInput
	Field guiButtonStart:TGUIButton
	Field guiButtonBack:TGUIButton
	Field guiChatWindow:TGUIChatWindow
	Field guiPlayerNames:TGUIinput[4]
	Field guiChannelNames:TGUIinput[4]
	Field guiDifficulty:TGUIDropDown[4]
	Field guiFigureArrows:TGUIArrowButton[8]
	Field guiFigureSelectArrows:TGUIArrowButton[8]
	Field guiGameSeedLabel:TGuiLabel
	Field guiGameSeed:TGUIinput
	'for easier iteration over the widgets (and their tooltips)
	Field guiWidgets:TList = New TList

	Field figureBaseCount:Int = 1
	Field modifiedPlayers:Int = False
	Field modifiedGameOptions:Int = False

	Field PlayerDetailsTimer:Long = 0
	Field OptionsTimer:Long = 0

	Global headerSize:Int = 35
	Global guiSettingsPanel:TGUIBackgroundBox
	Global guiAllPlayersPanel:TGUIBackgroundBox
	Global guiPlayerPanels:TGUIBackgroundBox[4]

	Global settingsArea:TRectangle = New TRectangle.Init(10,10,780,0) 'position of the panel
	Global playerBoxDimension:TVec2D = New TVec2D.Init(165,177) 'size of each player area
	Global playerColors:Int = 10
	Global playerColorHeight:Int = 10
	Global playerSlotGap:Int = 26
	Global playerSlotInnerGap:Int = 10 'the gap between inner canvas and inputs

	Field nameState:TLowerString
	Field settingsState:TLowerString = TLowerString.Create("GameSettings")

	Method Create:TScreen_GameSettings(name:String)
		Super.Create(name)
		SetGroupName("ExGame", "GameSettings")

		nameState = TLowerString.Create(name)

		'===== CREATE AND SETUP GUI =====
		guiSettingsWindow = New TGUIGameWindow.Create(settingsArea.position, settingsArea.dimension, name)
		guiSettingsWindow.guiBackground.spriteAlpha = 0.5
		Local panelGap:Int = GUIManager.config.GetInt("panelGap", 10)
		guiSettingsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)

		guiAllPlayersPanel = guiSettingsWindow.AddContentBox(0,0,-1, Int(playerBoxDimension.GetY() + 2 * panelGap))
		guiSettingsPanel = guiSettingsWindow.AddContentBox(0,0,-1, 100)

		Local col:SColor8 = New SColor8(90, 90, 90)
		Local labelH:Int = GetBitmapFontManager().Get("DefaultThin", 14, BOLDFONT).GetHeight("Title")
		guiGameTitleLabel = New TGUILabel.Create(New TVec2D.Init(0, 0), "", col, name)
		guiGameTitle = New TGUIinput.Create(New TVec2D.Init(0, labelH), New TVec2D.Init(250, -1), "", 32, name)
		guiStartYearLabel = New TGUILabel.Create(New TVec2D.Init(255, 0), "", col, name)
		guiStartYear = New TGUIinput.Create(New TVec2D.Init(255, labelH), New TVec2D.Init(70, -1), "", 4, name)
		guiGameSeedLabel = New TGUILabel.Create(New TVec2D.Init(330, 0), "", col, name)
		guiGameSeed = New TGUIinput.Create(New TVec2D.Init(330, labelH), New TVec2D.Init(75, -1), "", 9, name)

		guiGameTitleLabel.SetFont( GetBitmapFontManager().Get("DefaultThin", 14, BOLDFONT) )
		guiStartYearLabel.SetFont( GetBitmapFontManager().Get("DefaultThin", 14, BOLDFONT) )
		guiGameSeedLabel.SetFont( GetBitmapFontManager().Get("DefaultThin", 14, BOLDFONT) )


		Local checkboxHeight:Int = 0
		gui24HoursDay = New TGUICheckBox.Create(New TVec2D.Init(430, 0), New TVec2D.Init(300), "", name)
		gui24HoursDay.SetChecked(True, False)
		gui24HoursDay.disable() 'option not implemented
		checkboxHeight :+ gui24HoursDay.GetScreenRect().GetH()

		guiSpecialFormats = New TGUICheckBox.Create(New TVec2D.Init(430, 0 + checkboxHeight), New TVec2D.Init(300), "", name)
		guiSpecialFormats.SetChecked(True, False)
		guiSpecialFormats.disable() 'option not implemented
		checkboxHeight :+ guiSpecialFormats.GetScreenRect().GetH()

		guiFilterUnreleased = New TGUICheckBox.Create(New TVec2D.Init(430, 0 + checkboxHeight), New TVec2D.Init(300), "", name)
		guiFilterUnreleased.SetChecked(False, False)
		checkboxHeight :+ guiFilterUnreleased.GetScreenRect().GetH()

		guiAnnounce = New TGUICheckBox.Create(New TVec2D.Init(430, 0 + checkboxHeight), New TVec2D.Init(300), "", name)
		guiAnnounce.SetChecked(True, False)


		guiSettingsPanel.AddChild(guiGameTitleLabel)
		guiSettingsPanel.AddChild(guiGameTitle)
		guiSettingsPanel.AddChild(guiStartYearLabel)
		guiSettingsPanel.AddChild(guiStartYear)
		guiSettingsPanel.AddChild(guiGameSeedLabel)
		guiSettingsPanel.AddChild(guiGameSeed)
		guiSettingsPanel.AddChild(guiAnnounce)
		guiSettingsPanel.AddChild(gui24HoursDay)
		guiSettingsPanel.AddChild(guiSpecialFormats)
		guiSettingsPanel.AddChild(guiFilterUnreleased)


		Local guiButtonsWindow:TGUIGameWindow
		Local guiButtonsPanel:TGUIBackgroundBox
		guiButtonsWindow = New TGUIGameWindow.Create(New TVec2D.Init(590, 400), New TVec2D.Init(200, 190), name)
		guiButtonsWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiButtonsWindow.guiBackground.spriteAlpha = 0.5
		guiButtonsWindow.SetCaption("")


		guiButtonsPanel = guiButtonsWindow.AddContentBox(0,0,-1,-1)

		TGUIButton.SetTypeFont( GetBitmapFontManager().baseFontBold )
		TGUIButton.SetTypeCaptionColor( New SColor8(75, 75, 75) )

		guiButtonStart = New TGUIButton.Create(New TVec2D.Init(0, 0), New TVec2D.Init(guiButtonsPanel.GetContentScreenRect().GetW(), -1), "", name)
		guiButtonBack = New TGUIButton.Create(New TVec2D.Init(0, guiButtonsPanel.GetContentScreenRect().GetH() - guiButtonStart.GetScreenRect().GetH()), New TVec2D.Init(guiButtonsPanel.GetContentScreenRect().GetW(), -1), "", name)

		guiButtonsPanel.AddChild(guiButtonStart)
		guiButtonsPanel.AddChild(guiButtonBack)


		guiChatWindow = New TGUIChatWindow.Create(New TVec2D.Init(10,400), New TVec2D.Init(540,190), name)
		guiChatWindow.guiChat.guiInput.setMaxLength(200)

		guiChatWindow.guiBackground.spriteAlpha = 0.5
		guiChatWindow.SetPadding(headerSize, panelGap, panelGap, panelGap)
		guiChatWindow.guiChat.guiList.SetSize(guiChatWindow.guiChat.guiList.rect.GetW(), guiChatWindow.guiChat.guiList.rect.GetH()-10)
		guiChatWindow.guiChat.guiInput.Move(panelGap, -panelGap)
		guiChatWindow.guiChat.guiInput.SetSize( guiChatWindow.guiChat.GetContentScreenRect().GetW() - 2* panelGap, guiStartYear.GetScreenRect().GetH())

		For Local i:Int = 0 To 3
			Local slotX:Int = i * (playerSlotGap + playerBoxDimension.GetIntX())
			guiPlayerPanels[i] = New TGUIBackgroundBox.Create(New TVec2D.Init(slotX, 0), New TVec2D.Init(playerBoxDimension.GetIntX(), playerBoxDimension.GetIntY()), name)
			guiPlayerPanels[i].spriteBaseName = "gfx_gui_panel.subContent.bright"
			guiPlayerPanels[i].SetPadding(playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap,playerSlotInnerGap)
			guiAllPlayersPanel.AddChild(guiPlayerPanels[i])

			guiPlayerNames[i] = New TGUIinput.Create(New TVec2D.Init(0, 0), New TVec2D.Init(guiPlayerPanels[i].GetContentScreenRect().GetW(), -1), "player", 16, name)
			guiPlayerNames[i].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_player"))

			guiChannelNames[i] = New TGUIinput.Create(New TVec2D.Init(0, 0), New TVec2D.Init(guiPlayerPanels[i].GetContentScreenRect().GetW(), -1), "channel", 16, name)
			guiChannelNames[i].SetPositionY(100)
			guiChannelNames[i].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_tvchannel"))


			guiDifficulty[i] = New TGUIDropDown.Create(New TVec2D.Init(0, 0), New TVec2D.Init(guiPlayerPanels[i].GetContentScreenRect().GetW(), -1), "Leicht", 16, name)
			guiDifficulty[i].SetPositionY(guiPlayerPanels[i].GetContentScreenRect().GetH() - guiDifficulty[i].rect.GetH() + 4)
			Local difficultyValues:String[] = ["easy", "normal", "hard"]
			Local itemHeight:Int = 0
			For Local s:String = EachIn difficultyValues
				Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(New TVec2D, New TVec2D.Init(100,20), GetLocale("DIFFICULTY_"+s))
				item.data.Add("value", s)

				guiDifficulty[i].AddItem( item )
				If itemHeight = 0 Then itemHeight = item.GetScreenRect().GetH()
			Next
			'we want to have max "difficulty-variant" items visible at once
			guiDifficulty[i].SetListContentHeight(itemHeight * Min(difficultyValues.length,5))


			'left arrow
			guiFigureArrows[i*2 + 0] = New TGUIArrowButton.Create(New TVec2D.Init(0 + 25, 45), New TVec2D.Init(24, 24), "LEFT", name)
			'right arrow
			guiFigureArrows[i*2 + 1] = New TGUIArrowButton.Create(New TVec2D.Init(guiPlayerPanels[i].GetContentScreenRect().GetW() - 25, 45), New TVec2D.Init(24, 24), "RIGHT", name)
			guiFigureArrows[i*2 + 1].Move(-guiFigureArrows[i*2 + 1].GetScreenRect().GetW(),0)
			guiFigureArrows[i*2 + 0].SetSpriteButtonOption(TGUISpriteButton.SHOW_BUTTON_NORMAL, False)
			guiFigureArrows[i*2 + 1].SetSpriteButtonOption(TGUISpriteButton.SHOW_BUTTON_NORMAL, False)

			'left arrow
			guiFigureSelectArrows[i*2 + 0] = New TGUIArrowButton.Create(New TVec2D.Init(guiPlayerPanels[i].GetContentScreenRect().GetX() - 36, guiPlayerPanels[i].GetContentScreenRect().GetY() + 71-6), New TVec2D.Init(26, 36), "LEFT", name)
			'right arrow
			guiFigureSelectArrows[i*2 + 1] = New TGUIArrowButton.Create(New TVec2D.Init(guiPlayerPanels[i].GetContentScreenRect().GetX() + guiPlayerPanels[i].GetContentScreenRect().GetW() +36, guiPlayerPanels[i].GetContentScreenRect().GetY() + 71-6), New TVec2D.Init(26, 36), "RIGHT", name)
			guiFigureSelectArrows[i*2 + 1].Move(-guiFigureSelectArrows[i*2 + 1].GetScreenRect().GetW(),0)


			guiPlayerPanels[i].AddChild(guiPlayerNames[i])
			guiPlayerPanels[i].AddChild(guiChannelNames[i])
			guiPlayerPanels[i].AddChild(guiDifficulty[i])
			guiPlayerPanels[i].AddChild(guiFigureArrows[i*2 + 0])
			guiPlayerPanels[i].AddChild(guiFigureArrows[i*2 + 1])


			guiPlayerNames[i].SetTooltip( CreateBasicTooltip("PLAYERNAME", "NEWGAMESETTINGS_PLAYERNAME_DETAIL"), True, False )
			guiChannelNames[i].SetTooltip( CreateBasicTooltip("CHANNELNAME", "NEWGAMESETTINGS_CHANNELNAME_DETAIL"), True, False )
			guiDifficulty[i].SetTooltip( CreateBasicTooltip("NEWGAMESETTINGS_DIFFICULTY", "NEWGAMESETTINGS_DIFFICULTY_DETAIL"), True, False )

			'guiPlayerPanels[i].AddChild(guiFigureSelectArrows[i*2 + 0])
			'guiPlayerPanels[i].AddChild(guiFigureSelectArrows[i*2 + 1])
		Next


		guiGameSeed.SetTooltip( CreateBasicTooltip("NEWGAMESETTINGS_GAME_SEED", "NEWGAMESETTINGS_GAME_SEED_DETAIL"), True, False )
		guiStartYear.SetTooltip( CreateBasicTooltip("START_YEAR", "NEWGAMESETTINGS_START_YEAR_DETAIL"), True, False )
		guiGameTitle.SetTooltip( CreateBasicTooltip("GAME_TITLE", "NEWGAMESETTINGS_GAME_TITLE_DETAIL"), True, False )

		'guiWidgets.AddLast(guiSettingsWindow)
		guiWidgets.AddLast(guiAnnounce)
		guiWidgets.AddLast(gui24HoursDay)
		guiWidgets.AddLast(guiSpecialFormats)
		guiWidgets.AddLast(guiFilterUnreleased)
		'guiWidgets.AddLast(guiGameTitleLabel)
		guiWidgets.AddLast(guiGameTitle)
		'guiWidgets.AddLast(guiStartYearLabel)
		guiWidgets.AddLast(guiStartYear)
		'guiWidgets.AddLast(guiButtonStart)
		'guiWidgets.AddLast(guiButtonBack)
		'guiWidgets.AddLast(guiChatWindow:TGUIChatWindow
		For Local i:Int = 0 Until 4
			guiWidgets.AddLast(guiPlayerPanels[i])
			guiWidgets.AddLast(guiPlayerNames[i])
			guiWidgets.AddLast(guiChannelNames[i])
			guiWidgets.AddLast(guiDifficulty[i])
		Next
		'guiWidgets.AddLast(guiFigureArrows:TGUIArrowButton[8])
		'guiWidgets.AddLast(guiGameSeedLabel)
		guiWidgets.AddLast(guiGameSeed)


		'set button texts
		'could be done in "startup"-methods when changing screens
		'to the DIG ones
		SetLanguage()


		Local figuresConfig:TData = TData(GetRegistry().Get("figuresConfig", New TData))
		Local playerFigures:String[] = figuresConfig.GetString("playerFigures", "").split(",")
		figureBaseCount = Len(playerFigures)


		'===== REGISTER EVENTS =====
		'register changes to GameSettingsStartYear-guiInput
		EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiStartYear)
		'and to game seed
		EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiGameSeed)
		'register checkbox changes
		EventManager.registerListenerMethod("guiCheckBox.onSetChecked", Self, "onCheckCheckboxes", "TGUICheckbox")

		'register changes to player or channel name
		For Local i:Int = 0 To 3
			EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiPlayerNames[i])
			EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeGameSettingsInputs", guiChannelNames[i])
			EventManager.registerListenerMethod("GUIDropDown.onSelectEntry", Self, "onChangeGameSettingsInputs", guiDifficulty[i])
		Next

		'handle clicks on the gui objects
		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickButtons", "TGUIButton")
		EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickArrows", "TGUIArrowButton")

		Return Self
	End Method


	Function CreateBasicTooltip:TGUITooltipBase(titleKey:String, contentKey:String)
		Local tooltip:TGUITooltipBase
		tooltip = New TGUITooltipBase.Initialize("", "", New TRectangle.Init(0,0,-1,-1))
'		tooltips[i].parentArea = New TRectangle
		tooltip.SetOrientationPreset("TOP")
		tooltip.offset = New TVec2D.Init(0,+2)
		tooltip.SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
		tooltip._minContentDim = New TVec2D.Init(130,-1)
		tooltip._maxContentDim = New TVec2D.Init(220,-1)

		tooltip.dwellTime = 750

		tooltip.data.Add("tooltipTitleLocale", titleKey)
		tooltip.data.Add("tooltipContentLocale", contentKey)

		Return tooltip
	End Function


	'override to set guielements values (instead of only on screen creation)
	Method Start()
		'assign player/channel names
		For Local i:Int = 0 To 3
			RefreshPlayerGUIData(i+1)
		Next

		guiGameTitle.SetValue(GetGameBase().title)
		guiStartYear.SetValue(GetGameBase().userStartYear)
		guiPlayerNames[0].SetValue(GetGameBase().username)
		guiChannelNames[0].SetValue(GetGameBase().userchannelname)

		SeedRnd(MilliSecs())
		guiGameSeed.SetValue( String(Rand(0, 10000000)) )

		GetPlayerBase(1).Name = GetGameBase().username
		GetPlayerBase(1).Channelname = GetGameBase().userchannelname

		guiGameTitle.SetValue(GetGameBase().title)
	End Method


	Method RefreshPlayerGUIData:Int(playerID:Int)
		guiPlayerNames[playerID-1].SetValue( GetPlayerBase(playerID).name )
		guiChannelNames[playerID-1].SetValue( GetPlayerBase(playerID).channelName )

		If GetPlayerBaseCollection().IsHuman(playerID)
			guiPlayerNames[playerID-1].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_player"))
		Else
			guiPlayerNames[playerID-1].SetOverlay(GetSpriteFromRegistry("gfx_gui_overlay_computerplayer"))
		EndIf


		Local selectedDropDownItem:TGUIDropDownItem
		For Local item:TGUIDropDownItem = EachIn guiDifficulty[playerID-1].GetEntries()
			Local s:String = item.data.GetString("value")
			If s = GetPlayerBase(playerID).difficultyGUID
				selectedDropDownItem = item
				Exit
			EndIf
		Next
		If selectedDropDownItem Then guiDifficulty[playerID-1].SetSelectedEntry(selectedDropDownItem)
	End Method


	'handle clicks on the buttons
	Method onClickArrows:Int(triggerEvent:TEventBase)
		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent._sender)
		If Not sender Then Return False

		_HandleArrowInteraction(sender)

		'handled even if disabled/reached figure limit
		MouseManager.SetClickHandled(1)

		Return True
	End Method


	Method _HandleArrowInteraction:Int(sender:TGUIArrowButton)
		'left/right arrows to change figure base
		For Local i:Int = 0 To 7
			If sender = guiFigureArrows[i]
				Local playerID:Int = 1+Int(Ceil(i/2))
				If i Mod 2  = 0 Then GetPlayerBase(playerID).UpdateFigureBase(GetPlayerBase(playerID).figurebase -1)
				If i Mod 2 <> 0 Then GetPlayerBase(playerID).UpdateFigureBase(GetPlayerBase(playerID).figurebase +1)
				modifiedPlayers = True

				Return True
			EndIf

			If sender = guiFigureSelectArrows[i]
				Local playerID:Int = 1+Int(Ceil(i/2))
				Local newPlayerID:Int = -1
				'left
				If i Mod 2  = 0 And playerID>1 Then newPlayerID = playerID - 1
				If i Mod 2 <> 0 And playerID<4 Then newPlayerID = playerID + 1

				If newPlayerID <> -1
					If GetGameBase().SwitchPlayerIdentity(newPlayerID, playerID)
						GetGameBase().SetLocalPlayer(newPlayerID)

						'switch difficulties too
						Local oldDifficultyGUID:String = GetPlayerBase(playerID).difficultyGUID
						GetPlayerBase(playerID).difficultyGUID = GetPlayerBase(newPlayerID).difficultyGUID
						GetPlayerBase(newPlayerID).difficultyGUID = oldDifficultyGUID

						'update names
						RefreshPlayerGUIData(playerID)
						RefreshPlayerGUIData(newPlayerID)
						'update figures
						GetPlayerBase(playerID).UpdateFigureBase(GetPlayerBase(playerID).figurebase)
						GetPlayerBase(newPlayerID).UpdateFigureBase(GetPlayerBase(newPlayerID).figurebase)
						modifiedPlayers = True
					EndIf
				EndIf

				Return True
			EndIf
		Next
	End Method


	'handle clicks on the buttons
	Method onClickButtons:Int(triggerEvent:TEventBase)
		Local sender:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not sender Then Return False


		Select sender
			Case guiButtonStart
					If Not GetGameBase().networkgame And Not GetGameBase().onlinegame
						TLogger.Log("Game", "Start a new singleplayer game", LOG_DEBUG)

						'set self into preparation state
						GetGameBase().SetGamestate(TGameBase.STATE_PREPAREGAMESTART)
					Else
						TLogger.Log("Game", "Start a new multiplayer game", LOG_DEBUG)
						guiAnnounce.SetChecked(False)
						Network.StopAnnouncing()

						'demand others to do the same
						GetNetworkHelper().SendPrepareGame()
						'set self into preparation state
						GetGameBase().SetGamestate(TGameBase.STATE_PREPAREGAMESTART)
					EndIf

			Case guiButtonBack
					If GetGameBase().networkgame
						Network.StopAnnouncing()

						If Network.isServer
							Network.DisconnectFromServer()
						Else
							Network.client.Disconnect()
						EndIf
						GetPlayerBaseCollection().playerID = 1
						GetPlayerBossCollection().playerID = 1
						GetGameBase().SetGamestate(TGameBase.STATE_NETWORKLOBBY)
						guiAnnounce.SetChecked(False)
					Else
						GetGameBase().SetGamestate(TGameBase.STATE_MAINMENU)
					EndIf
		End Select
	End Method


	Method onCheckCheckboxes:Int(triggerEvent:TEventBase)
		Local sender:TGUICheckBox = TGUICheckBox(triggerEvent.GetSender())
		If Not sender Then Return False

		Select sender
			Case guiFilterUnreleased
					'ATTENTION: use "not" as checked means "not ignore"
					TProgrammeData.setIgnoreUnreleasedProgrammes( Not sender.isChecked() )
		End Select

		'only inform when in settings menu
		If GetGameBase().IsGameState(TGameBase.STATE_SETTINGSMENU)
			If sender.isChecked()
				GetGameBase().SendSystemMessage(GetLocale("OPTION_ON")+": "+sender.GetValue())
			Else
				GetGameBase().SendSystemMessage(GetLocale("OPTION_OFF")+": "+sender.GetValue())
			EndIf
		EndIf
	End Method


	Method onChangeGameSettingsInputs(triggerEvent:TEventBase)
		Local sender:TGUIObject = TGUIObject(triggerEvent.GetSender())

		'name or channel changed?
		For Local i:Int = 0 To 3
			If Not GetPlayerBase(i+1) Then Continue

			If sender = guiPlayerNames[i] Then GetPlayerBase(i+1).Name = sender.GetValue()
			If sender = guiChannelNames[i] Then GetPlayerBase(i+1).channelName = sender.GetValue()

			If sender = guiDifficulty[i]
				Local item:TGUIDropDownItem = TGUIDropDownItem(guiDifficulty[i].GetSelectedEntry())
				If item
					GetPlayerBase(i+1).SetDifficulty( item.data.GetString("value") )
				EndIf
			EndIf
		Next


		If sender = guiGameSeed
			Local valueNumeric:String = String(StringHelper.NumericFromString( sender.GetValue() ))
			If sender.GetValue() <> valueNumeric Then sender.SetValue(valueNumeric)
			GetGameBase().SetRandomizerBase( Int(valueNumeric)  )
		EndIf


		'start year changed
		If sender = guiStartYear
			GetGameBase().SetStartYear( Int(sender.GetValue()) )
			'use the (maybe corrected value)
			TGUIInput(sender).value = GetGameBase().GetStartYear()

			'store it as user setting so it gets used in
			'GetGameBase().PreparewNewGame()
			GetGameBase().userStartYear = Int(TGUIInput(sender).value)
		EndIf
	End Method


	'override default
	Method SetLanguage:Int(languageCode:String = "")
		'not needed, done during update
		'guiSettingsWindow.SetCaption(GetLocale("MENU_NETWORKGAME"))

		For Local widget:TGUIObject = EachIn guiWidgets
			If widget.GetTooltip()
				widget.GetTooltip().SetTitle(GetLocale(widget.GetTooltip().data.GetString("tooltipTitleLocale")))
				widget.GetTooltip().SetContent(GetLocale(widget.GetTooltip().data.GetString("tooltipContentLocale")))
				widget.GetTooltip().parentArea = widget.GetScreenRect()
			EndIf
		Next
Rem
		local widgets:TGUIObject[] = [guiStartYear, guiGameSeed, guiGameTitle]
		For local i:int = 0 until 4
			widgets :+ [TGUIObject(guiDifficulty[i]), TGUIObject(guiPlayerNames[i]), TGUIObject(guiChannelNames[i])]
		Next
		for local widget:TGUIObject = EachIn widgets
			if widget.GetTooltip()
				widget.GetTooltip().SetTitle(GetLocale(widget.GetTooltip().data.GetString("tooltipTitleLocale")))
				widget.GetTooltip().SetContent(GetLocale(widget.GetTooltip().data.GetString("tooltipContentLocale")))
				widget.GetTooltip().parentArea = widget.GetScreenRect()
			endif
		Next
endrem
		guiGameTitleLabel.SetValue(GetLocale("GAME_TITLE")+":")
		guiStartYearLabel.SetValue(GetLocale("START_YEAR")+":")
		guiGameSeedLabel.SetValue(GetLocale("GAME")+" #:")

		gui24HoursDay.SetValue(GetLocale("24_HOURS_GAMEDAY"))
		guiSpecialFormats.SetValue(GetLocale("ALLOW_TRAILERS_AND_INFOMERCIALS"))
		guiFilterUnreleased.SetValue(GetLocale("ALLOW_MOVIES_WITH_YEAR_OF_PRODUCTION_GT_GAMEYEAR"))

		guiAnnounce.SetValue("Nach weiteren Spielern suchen")

		guiButtonStart.SetCaption(GetLocale("MENU_START_GAME"))
		guiButtonBack.SetCaption(GetLocale("MENU_BACK"))

		guiChatWindow.SetCaption(GetLocale("CHAT"))


		're-align the checkboxes as localization might have changed
		'label dimensions
		Local y:Int = 0
		gui24HoursDay.rect.position.SetY(0)
		y :+ gui24HoursDay.GetScreenRect().GetH()

		guiSpecialFormats.rect.position.SetY(y)
		y :+ guiSpecialFormats.GetScreenRect().GetH()

		guiFilterUnreleased.rect.position.SetY(y)
	End Method


	Method Draw:Int(tweenValue:Float)
		DrawMenuBackground(True)

		'background gui items
		GUIManager.Draw(nameState, 0, 100)

		Local slotPosX:Int = guiAllPlayersPanel.GetContentScreenRect().GetIntX()
		Local colorRect:SRect
		For Local i:Int = 1 To 4
			colorRect = New SRect(slotPosX + 2, Int(guiChannelNames[i-1].GetContentScreenRect().GetY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)

			'draw colors
			For Local pc:TPlayerColor = EachIn TPlayerColor.List
				If pc.ownerID = 0
					colorRect = New SRect(colorRect.x + colorRect.w, colorRect.y, colorRect.w, colorRect.h)
					pc.SetRGB()
					DrawRect(colorRect.x, colorRect.y, colorRect.w, colorRect.h)
				EndIf
			Next

			'draw player figure
			SetColor 255,255,255
			GetPlayerBase(i).GetFigure().Sprite.Draw(Int(slotPosX + playerBoxDimension.GetX()/2 - GetPlayerBase(i).GetFigure().Sprite.framew / 2), Int(colorRect.y - GetPlayerBase(i).GetFigure().Sprite.area.GetH()), 8)

			If GetGameBase().networkgame
				Local hintX:Int = slotPosX + 12
				Local hintY:Int = Int(guiAllPlayersPanel.GetContentScreenRect().GetY()) + 40
				Local hint:String = "undefined playerType"
				If GetPlayerBase(i).IsRemoteHuman()
					hint = "remote player"
				ElseIf GetPlayerBase(i).IsRemoteAI()
					hint = "remote AI"
				ElseIf GetPlayerBase(i).IsLocalAI()
					hint = "local AI"
				ElseIf GetPlayerBase(i).IsLocalHuman()
					hint = "local player"
				EndIf
				GetBitMapFontManager().Get("default", 10).DrawSimple(hint, hintX, hintY, New SColor8(100, 100, 100))
			EndIf

			'move to next slot position
			slotPosX :+ playerSlotGap + playerBoxDimension.GetIntX()
		Next

		'overlay gui items (higher zindex)
		GUIManager.Draw(nameState, 101)

		'draw tooltips above everything
		For Local widget:TGUIObject = EachIn guiWidgets
			If widget.GetTooltip() Then widget.GetTooltip().Render()
		Next
	End Method


	'override default update
	Method Update:Int(deltaTime:Float)
		If GetGameBase().networkgame
			If Not GetGameBase().isGameLeader()
				guiButtonStart.disable()
			Else
				guiButtonStart.enable()
			EndIf
			'guiChat.setOption(GUI_OBJECT_VISIBLE,True)
			If Not GetGameBase().onlinegame
				guiSettingsWindow.SetCaption(GetLocale("MENU_NETWORKGAME"))
			Else
				guiSettingsWindow.SetCaption(GetLocale("MENU_ONLINEGAME"))
			EndIf

			guiAnnounce.show()
			guiGameTitle.show()
			guiGameTitleLabel.show()

			If guiAnnounce.isChecked() And GetGameBase().isGameLeader()
			'If GetGame().isGameLeader()
				'guiAnnounce.enable()
				guiGameTitle.disable()
				If guiGameTitle.Value = "" Then guiGameTitle.Value = "no title"
				GetGameBase().title = guiGameTitle.Value
			Else
				guiGameTitle.enable()
			EndIf
			If Not GetGameBase().isGameLeader()
				guiGameTitle.disable()
				guiAnnounce.disable()
			EndIf

			'disable/enable announcement on lan/online
			If guiAnnounce.isChecked()
				Network.client.playerName = GetPlayerBase().name
				If Not Network.announceEnabled Then Network.StartAnnouncing(GetGameBase().title)
			Else
				Network.StopAnnouncing()
			EndIf
		Else
			guiSettingsWindow.SetCaption(GetLocale("MENU_SOLO_GAME"))
			'guiChat.setOption(GUI_OBJECT_VISIBLE,False)


			guiAnnounce.hide()
			guiGameTitle.disable()
		EndIf


		For Local i:Int = 0 Until 4
			If GetGameBase().networkgame Or GetGameBase().isGameLeader()
				If Not GetGameBase().IsGameState(TGameBase.STATE_PREPAREGAMESTART) And GetGameBase().IsControllingPlayer(i+1)
					guiPlayerNames[i].enable()
					guiChannelNames[i].enable()

					'only enable if direction is allowed
					If GetPlayerBase(i+1).figureBase > 0
						guiFigureArrows[i*2].Enable()
					Else
						guiFigureArrows[i*2].Disable()
					EndIf
					If GetPlayerBase(i+1).figureBase < figureBaseCount - 1
						guiFigureArrows[i*2 +1].Enable()
					Else
						guiFigureArrows[i*2 +1].Disable()
					EndIf
				Else
					guiPlayerNames[i].disable()
					guiChannelNames[i].disable()
					guiFigureArrows[i*2].disable()
					guiFigureArrows[i*2 +1].disable()
				EndIf
			EndIf


			If GetPlayerBaseCollection().playerID = (i+1)
				If Not guiPlayerPanels[i].spriteTintColor Then guiPlayerPanels[i].spriteTintColor = TColor.Create(255,240,235)

				'show selection arrows (except most left/right)
				If i=0
					guiFigureSelectArrows[i*2].Hide()
				Else
					guiFigureSelectArrows[i*2].Show()
				EndIf
				If i=3
					guiFigureSelectArrows[i*2+1].Hide()
				Else
					guiFigureSelectArrows[i*2+1].Show()
				EndIf
			Else
				If guiPlayerPanels[i].spriteTintColor Then guiPlayerPanels[i].spriteTintColor = Null
				'hide selection arrows
				guiFigureSelectArrows[i*2].Hide()
				guiFigureSelectArrows[i*2+1].Hide()
			EndIf
		Next

		GUIManager.Update(settingsState)


		'not final !
		If KEYMANAGER.isDown(KEY_ENTER)
			If Not GUIManager.GetFocus()
				GUIManager.SetFocus(guiChatWindow.guiChat.guiInput)
				'KEYMANAGER.blockKey(KEY_ENTER, 200) 'block for 100ms
				'KEYMANAGER.resetKey(KEY_ENTER)
			EndIf
		EndIf

		'clicks on color rect
		Local i:Int = 0

	'	rewrite to Assets instead of global list in TColor ?
	'	local colors:TList = Assets.GetList("PlayerColors")

		If MOUSEMANAGER.IsClicked(1)
			Local slotPosX:Int = guiAllPlayersPanel.GetContentScreenRect().GetIntX()
			For Local i:Int = 0 To 3
				If MOUSEMANAGER.IsClicked(1)
					Local colorRect:SRect = New SRect(slotPosX + 2, Int(guiChannelNames[i].GetContentScreenRect().GetY() - playerColorHeight - playerSlotInnerGap), (playerBoxDimension.GetX() - 2*playerSlotInnerGap - 10)/ playerColors, playerColorHeight)

					For Local pc:TPlayerColor = EachIn TPlayerColor.List
						'only for unused colors
						If pc.ownerID <> 0 Then Continue

						colorRect = New SRect(colorRect.x + colorRect.w, colorRect.y, colorRect.w, colorRect.h)

						'skip if outside of rect
						If Not THelper.MouseIn(colorRect.x, colorRect.y, colorRect.w, colorRect.h) Then Continue
						'only allow mod if you control the player or if the
						'player is AI and you are the master player
						If GetGameBase().IsControllingPlayer(i+1)
							modifiedPlayers = True
							GetPlayerBase(i+1).RecolorFigure(pc)

							'handled click/hit
							MouseManager.SetClickHandled(1)
						EndIf
					Next
					'move to next slot position
					slotPosX :+ playerSlotGap + playerBoxDimension.GetIntX()
				EndIf
			Next
		EndIf


		If GetGameBase().networkgame = 1
			'sync if the player got modified
			If modifiedPlayers Or Time.GetTimeGone() >= PlayerDetailsTimer + 2000
				GetNetworkHelper().SendPlayerDetails()
				PlayerDetailsTimer = MilliSecs()
				modifiedPlayers = False
			EndIf
			If modifiedGameOptions Or Time.GetTimeGone() >= OptionsTimer + 2000
				Print "NET: TODO - GetNetworkHelper().SendGameOptions()"
				'GetNetworkHelper().SendGameOptions()
				OptionsTimer = MilliSecs()

				modifiedPlayers = False
			EndIf
		EndIf
	End Method
End Type




Global spriteNameLS_StartScreen:TLowerString = New TLowerString.Create("gfx_startscreen")
Global spriteNameLS_StartScreenLogo:TLowerString = New TLowerString.Create("gfx_startscreen_logo")

Function DrawMenuBackground(darkened:Int=False, drawLogo:Int = False)
	'cls only needed if virtual resolution is enabled, else the
	'background covers everything
	If GetGraphicsManager().HasBlackBars()
		SetClsColor 0,0,0
		'use graphicsmanager's cls as it resets virtual resolution
		'first
		'Cls()
		GetGraphicsManager().Cls()
	EndIf

	SetColor 255,255,255
	GetSpriteFromRegistry(spriteNameLS_StartScreen).Draw(0,0)


	'draw an (animated) logo
	If drawLogo
		Global logoAnimStart:Int = 0
		Global logoAnimTime:Int = 1500
		Global logoScale:Float = 0.0
		Local logo:TSprite = GetSpriteFromRegistry(spriteNameLS_StartScreenLogo)
		If logo
			Local timeGone:Int = Time.GetTimeGone()
			If logoAnimStart = 0 Then logoAnimStart = timeGone
			logoScale = TInterpolation.BackOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)
			logoScale :* TInterpolation.BounceOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)

			Local oldAlpha:Float = GetAlpha()
			SetAlpha Float(TInterpolation.RegularOut(0.0, 1.0, Min(0.5*logoAnimTime, timeGone - logoAnimStart), 0.5*logoAnimTime))

			logo.Draw( GetGraphicsManager().GetWidth()/2, 150, -1, ALIGN_CENTER_CENTER, logoScale)
			SetAlpha oldAlpha
		EndIf
	EndIf

	If GetGameBase().IsGameState(TGameBase.STATE_MAINMENU)
		SetColor 255,255,255
		'GetBitmapFont("Default",13, BOLDFONT).DrawBlock("ACHTUNG neue Tastenkürzel:", 10,460, 300,20, Null,TColor.Create(140,75,75))
		'GetBitmapFont("Default",12).DrawBlock("|b|[S]|/b| Schnellspeichern - nun mit |b|[F5]|/b|~n|b|[L]|/b| Schnellspeicherstand einladen - nun mit |b|[F8]|/b|.~nDamit sollten versehentliche Spielverluste durch Einladerei minimiert werden.", 10,480, 300,50, Null,TColor.Create(75,75,75))


		Local defaultColor:SColor8 = New SColor8(75,75,140)
		Local linkColor:SColor8 = New SColor8(60,60,120)
		Local offsetY:Int = 0
		offsetY :+ GetBitmapFont("Default",13, BOLDFONT).DrawBox("Wir brauchen Deine Hilfe!", 10,460 + offsetY, 300, -1, sALIGN_LEFT_TOP, defaultColor).y
		offsetY :+ GetBitmapFont("Default",12).DrawBox("Beteilige Dich an Diskussionen rund um alle Spielelemente in TVTower.", 10,460 + offsetY, 300,-1, sALIGN_LEFT_TOP, defaultColor).y
		offsetY :+ GetBitmapFont("Default",12, BOLDFONT).DrawBox("www.gamezworld.de/phpforum", 10,460 + offsetY, 500, -1, sALIGN_LEFT_TOP, linkColor).y
		SetAlpha 0.5 * GetAlpha()
		offsetY :+ GetBitmapFont("Default",11).DrawBox("(Keine Anmeldung notwendig)", 10,460 + offsetY, 500,20, sALIGN_LEFT_TOP, New SColor8(80,80,170)).y
		SetAlpha 2.0 * GetAlpha()


		Local bottomStartY:Int = GetGraphicsManager().GetHeight() - 100 - 10
		offsetY = 0
		offsetY :+ GetBitmapFont("Default",12, ITALICFONT).DrawBox(copyrightstring+", www.TVTower.org", 10, bottomStartY, 500, 100, sALIGN_LEFT_BOTTOM, linkColor).y
		offsetY :+ GetBitmapFont("Default",12, ITALICFONT).DrawBox(versionstring, 10, bottomStartY - offsetY, 500, 100, sALIGN_LEFT_BOTTOM, defaultColor).y
	EndIf

	If darkened
		SetColor 190,220,240
		SetAlpha 0.5
		DrawRect(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetAlpha 1.0
		SetColor 255, 255, 255
	EndIf
End Function