SuperStrict
Import "Dig/base.gfx.gui.bmx"
Import "Dig/base.gfx.gui.dropdown.bmx"
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "Dig/base.gfx.gui.input.bmx"
Import "Dig/base.sfx.soundmanager.base.bmx"
Import "common.misc.gamegui.bmx"
Import "game.misc.ingamehelp.bmx"


'panel for "single" display (not within the escape-menu)
Type TGUISettingsPanel Extends TGUIPanel
	Field inputPlayerName:TGUIInput
	Field inputChannelName:TGUIInput
	Field inputStartYear:TGUIInput
	Field inputStationmap:TGUIDropDown
	Field inputDatabase:TGUIDropDown
	Field sliderMusicVolume:TGUISlider
	Field sliderSFXVolume:TGUISlider
'	Field checkMusic:TGUICheckbox
'	Field checkSfx:TGUICheckbox
	Field dropdownSoundEngine:TGUIDropDown
	Field dropdownRenderer:TGUIDropDown
	Field checkFullscreen:TGUICheckbox
	Field checkVSync:TGUICheckbox
	Field inputWindowResolutionWidth:TGUIInput
	Field inputWindowResolutionHeight:TGUIInput
	Field inputGameName:TGUIInput
	Field inputInRoomSlowdown:TGUIInput
	Field inputAutoSaveInterval:TGUIInput
	Field inputOnlinePort:TGUIInput
	Field inputTouchClickRadius:TGUIInput
	Field checkTouchInput:TGUICheckbox
	Field checkLongClickMode:TGUICheckbox
	Field inputLongClickTime:TGUIInput

	Field checkShowIngameHelp:TGUICheckbox

	'labels for deactivation
	Field labelLongClickTime:TGUILabel
	Field labelLongClickTimeMilliseconds:TGUILabel
	Field labelTouchClickRadiusPixel:TGUILabel
	Field labelTouchClickRadius:TGUILabel

	Field _eventListeners:TEventListenerBase[]


	Method New()
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUICheckbox_OnSetChecked, Self, "onCheckCheckboxes", "TGUICheckbox") ]
	End Method


	Method Remove:Int()
		Super.Remove()

		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]
	End Method


	Method Create:TGUISettingsPanel(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)


		'LAYOUT CONFIG
		Local nextY:Int = 0, nextX:Int = 0
		Local rowWidth:Int[] = [210,210,250]
		Local checkboxWidth:Int = 180
		Local inputWidth:Int = 170
		Local labelH:Int = 14
		Local inputH:Int = 0
		Local guiDistance:Int = labelH + 4

		Local labelTitleGameDefaults:TGUILabel = New TGUILabel.Create(New SVec2I(0, nextY), GetLocale("DEFAULTS_FOR_NEW_GAME"))
		labelTitleGameDefaults.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		Self.AddChild(labelTitleGameDefaults)
		nextY :+ 22

		Local labelPlayerName:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("PLAYERNAME")+":")
		labelH = labelPlayerName.GetFont().GetHeight(GetLocale("PLAYERNAME"))
		labelH :- 1 'a bit more near
		inputPlayerName = New TGUIInput.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(inputWidth,-1), "", 128)
		Self.AddChild(labelPlayerName)
		Self.AddChild(inputPlayerName)
		inputH = inputPlayerName.GetScreenRect().GetH()
		nextY :+ inputH + guiDistance

		Local labelChannelName:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("CHANNELNAME")+":")
		inputChannelName = New TGUIInput.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(inputWidth,-1), "", 128)
		Self.AddChild(labelChannelName)
		Self.AddChild(inputChannelName)
		nextY :+ inputH + guiDistance

		Local labelStartYear:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("START_YEAR")+":")
		inputStartYear = New TGUIInput.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(50,-1), "", 4)
		Self.AddChild(labelStartYear)
		Self.AddChild(inputStartYear)
		nextY :+ inputH + guiDistance

		Local labelStationmap:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("STATIONMAP")+":")
		inputStationmap = New TGUIDropDown.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(inputWidth,-1), "germany.xml", 128)
		inputStationmap.disable()
		Self.AddChild(labelStationmap)
		Self.AddChild(inputStationmap)
		nextY :+ inputH + guiDistance

		Local labelDatabase:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("DATABASE")+":")
		inputDatabase = New TGUIDropDown.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(inputWidth,-1), "res/database/Default", 128)
		inputDatabase.disable()
		Self.AddChild(labelDatabase)
		Self.AddChild(inputDatabase)
		nextY :+ inputH + guiDistance
		
		nextY :+ 2

		checkShowIngameHelp = New TGUICheckbox.Create(New SVec2I(nextX, nextY), New SVec2I(checkboxWidth + 20,-1), GetLocale("SHOW_INTRODUCTORY_GUIDES"))
		Self.AddChild(checkShowIngameHelp)
		nextY :+ checkShowIngameHelp.GetScreenRect().GetH() + guiDistance
		
		nextY :- 6


		'SINGLEPLAYER
		Local labelTitleSingleplayer:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("SINGLEPLAYER"))
		labelTitleSingleplayer.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		Self.AddChild(labelTitleSingleplayer)
		nextY :+ 22

		Local labelInRoomSlowdown:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("GAME_SPEED_IN_ROOMS")+":")
		inputInRoomSlowdown = New TGUIInput.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(50,-1), "", 128)
		Local labelInRoomSlowdownPercentage:TGUILabel = New TGUILabel.Create(New SVec2I(nextX + 50 + 5, nextY + 22), "%")
		Self.AddChild(labelInRoomSlowdown)
		Self.AddChild(inputInRoomSlowdown)
		Self.AddChild(labelInRoomSlowdownPercentage)
		nextY :+ inputH + guiDistance

		Local labelAutoSaveInterval:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("AUTOSAVE_INTERVAL"))
		inputAutoSaveInterval = New TGUIInput.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(50,-1), "", 128)
		Local labelAutoSaveIntervalHours:TGUILabel = New TGUILabel.Create(New SVec2I(nextX + 50 + 5, nextY + 22), GetLocale("HOURS"))
		Self.AddChild(labelAutoSaveInterval)
		Self.AddChild(inputAutoSaveInterval)
		Self.AddChild(labelAutoSaveIntervalHours)
		nextY :+ inputH + guiDistance

		'-----

		nextY = 0
		nextX = rowWidth[0]


		'SOUND
		Local labelTitleSound:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("SOUND_OUTPUT"))
		labelTitleSound.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		Self.AddChild(labelTitleSound)
		nextY :+ 22

		Local labelMusicVolume:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("SOUND_MUSIC_VOLUME") + ":")
		sliderMusicVolume = New TGUISlider.Create(New SVec2I(nextX -2, nextY + labelH + 4), New SVec2I(140,inputH -6), "10")
		sliderMusicVolume.SetValueRange(0, 100)
		Self.AddChild(labelMusicVolume)
		Self.AddChild(sliderMusicVolume)
		nextY :+ guiDistance + Max(labelH, sliderMusicVolume.GetScreenRect().GetH() + 6)


		Local labelSFXVolume:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("SOUND_SFX_VOLUME") + ":")
		sliderSFXVolume = New TGUISlider.Create(New SVec2I(nextX -2, nextY + labelH + 4), New SVec2I(140,inputH -6), "10")
		sliderSFXVolume.SetValueRange(0, 100)
		Self.AddChild(labelSFXVolume)
		Self.AddChild(sliderSFXVolume)
		nextY :+ guiDistance + Max(labelH, sliderMusicVolume.GetScreenRect().GetH() + 6)

		Local labelSoundEngine:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("SOUND_ENGINE") + ":")
		dropdownSoundEngine = New TGUIDropDown.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(inputWidth,-1), "", 128)
		Local soundEngineValues:String[] = ["AUTOMATIC", "NONE"]
		Local soundEngineTexts:String[] = ["Auto", "---"]
		?Win32
			soundEngineValues :+ ["WINDOWS_ASIO","WINDOWS_DS"]
			soundEngineTexts :+ ["ASIO", "Direct Sound"]
		?Linux
			soundEngineValues :+ ["LINUX_ALSA","LINUX_PULSE","LINUX_OSS"]
			soundEngineTexts :+ ["ALSA", "PulseAudio", "OSS"]
		?MacOS
			soundEngineValues :+ ["MACOSX_CORE"]
			soundEngineTexts :+ ["CoreAudio"]
		?

		Local itemHeight:Int = 0
		For Local i:Int = 0 Until soundEngineValues.Length
			Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(New SVec2I(0,0), GUI_DIM_AUTOSIZE, soundEngineTexts[i])
			item.SetValueColor(TColor.CreateGrey(50))
			item.data.Add("value", soundEngineValues[i])
			dropdownSoundEngine.AddItem(item)
			If itemHeight = 0 Then itemHeight = item.GetScreenRect().GetH()
		Next
		dropdownSoundEngine.SetListContentHeight(itemHeight * Len(soundEngineValues))

		Self.AddChild(labelSoundEngine)
		Self.AddChild(dropdownSoundEngine)
'		GuiManager.SortLists()
		nextY :+ inputH + guiDistance
		nextY :+ 15


		'GRAPHICS
		Local labelTitleGraphics:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("GRAPHICS"))
		labelTitleGraphics.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		Self.AddChild(labelTitleGraphics)
		nextY :+ 22

		Local labelRenderer:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("RENDERER") + ":")
		dropdownRenderer = New TGUIDropDown.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(inputWidth,-1), "", 128)
		'Local rendererValues:String[] = ["0", "4"]
		'Local rendererTexts:String[] = ["OpenGL", "Buffered OpenGL"]
		Local rendererValues:String[]
		Local rendererTexts:String[]

		'fill with all available renderers
		For Local i:Int = 0 Until TGraphicsManager.RENDERER_AVAILABILITY.length
			If TGraphicsManager.RENDERER_AVAILABILITY[i]
				rendererValues :+ [String(i)] 'i is the same key here
				rendererTexts :+ [ TGraphicsManager.RENDERER_NAMES[i] ]
			EndIf
		Next

		itemHeight = 0
		For Local i:Int = 0 Until rendererValues.Length
			Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(Null, Null, rendererTexts[i])
			item.SetValueColor(TColor.CreateGrey(50))
			item.data.Add("value", rendererValues[i])
			dropdownRenderer.AddItem(item)
			If itemHeight = 0 Then itemHeight = item.GetScreenRect().GetH()
		Next
		dropdownRenderer.SetListContentHeight(itemHeight * Len(rendererValues))

		Self.AddChild(labelRenderer)
		Self.AddChild(dropdownRenderer)
		nextY :+ inputH + guiDistance

		checkFullscreen = New TGUICheckbox.Create(New SVec2I(nextX, nextY), New SVec2I(checkboxWidth,-1), "")
		checkFullscreen.SetCaption(GetLocale("FULLSCREEN"))
		Self.AddChild(checkFullscreen)
		nextY :+ Max(inputH -5, checkFullscreen.GetScreenRect().GetH())

		checkVSync = New TGUICheckbox.Create(New SVec2I(nextX, nextY), New SVec2I(checkboxWidth,-1), "")
		checkVSync.SetCaption(GetLocale("VSYNC"))
		Self.AddChild(checkVSync)
		nextY :+ Max(inputH, checkVSync.GetScreenRect().GetH())

		Local labelWindowResolution:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("WINDOW_MODE_RESOLUTION")+":")
		inputWindowResolutionWidth = New TGUIInput.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(inputWidth/2 - 15,-1), "", 4)
		inputWindowResolutionHeight = New TGUIInput.Create(New SVec2I(nextX + inputWidth/2 + 15, nextY + labelH), New SVec2I(inputWidth/2 - 15,-1), "", 4)
		Local labelWindowResolutionX:TGUILabel = New TGUILabel.Create(New SVec2I(nextX + inputWidth/2 - 4, nextY + labelH + 4), "x")
		Self.AddChild(labelWindowResolution)
		Self.AddChild(labelWindowResolutionX)
		Self.AddChild(inputWindowResolutionWidth)
		Self.AddChild(inputWindowResolutionHeight)
		nextY :+ inputH + 5 + guiDistance


		'MULTIPLAYER
		nextY = 0
		nextX = rowWidth[0] + rowWidth[1]
		Local labelTitleMultiplayer:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("MULTIPLAYER"))
		labelTitleMultiplayer.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		Self.AddChild(labelTitleMultiplayer)
		nextY :+ 22

		Local labelGameName:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("GAME_TITLE")+":")
		inputGameName = New TGUIInput.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(inputWidth,-1), "", 128)
		Self.AddChild(labelGameName)
		Self.AddChild(inputGameName)
		nextY :+ inputH + guiDistance


		Local labelOnlinePort:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("PORT_ONLINEGAME")+":")
		inputOnlinePort = New TGUIInput.Create(New SVec2I(nextX, nextY + labelH), New SVec2I(50,-1), "", 4)
		Self.AddChild(labelOnlinePort)
		Self.AddChild(inputOnlinePort)
		nextY :+ inputH + guiDistance
		nextY :+ 15

		'INPUT
		'nextY = 0
		'nextX = rowWidth[0] + rowWidth[1]
		Local labelTitleInput:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("INPUT"))
		labelTitleInput.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		Self.AddChild(labelTitleInput)
		nextY :+ 22

		checkTouchInput = New TGUICheckbox.Create(New SVec2I(nextX, nextY), New SVec2I(checkboxWidth + 20,-1), GetLocale("USE_TOUCH_INPUT"))
		Self.AddChild(checkTouchInput)
		nextY :+ checkTouchInput.GetScreenRect().GetH()

		Local labelTouchInput:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("USE_TOUCH_INPUT_EXPLANATION"))
		Self.AddChild(labelTouchInput)
		labelTouchInput.SetSize(checkboxWidth+30,-1)
		labelTouchInput.SetFont( GetBitmapFont("default", 10) )
		labelTouchInput.SetValueColor(TColor.CreateGrey(75))
		labelTouchInput.SetValue(labelTouchInput.GetValue())
		nextY :+ labelTouchInput.GetValueDimension().y + 5

		labelTouchClickRadius = New TGUILabel.Create(New SVec2I(nextX + 22, nextY), GetLocale("MOVE_INSTEAD_CLICK_RADIUS")+":")
		inputTouchClickRadius = New TGUIInput.Create(New SVec2I(nextX + 22, nextY + labelH), New SVec2I(50,-1), "", 4)
		labelTouchClickRadiusPixel = New TGUILabel.Create(New SVec2I(nextX + 22 + 55, nextY + labelH + 4), "px")
		Self.AddChild(labelTouchClickRadius)
		Self.AddChild(inputTouchClickRadius)
		Self.AddChild(labelTouchClickRadiusPixel)
		nextY :+ Max(inputH, inputTouchClickRadius.GetScreenRect().GetH()) + labelH + 4


		checkLongClickMode = New TGUICheckbox.Create(New SVec2I(nextX, nextY), New SVec2I(checkboxWidth + 20,-1), GetLocale("LONGCLICK_MODE"))
		Self.AddChild(checkLongClickMode)
		nextY :+ checkLongClickMode.GetScreenRect().GetH()

		Local labelLongClickMode:TGUILabel = New TGUILabel.Create(New SVec2I(nextX, nextY), GetLocale("LONGCLICK_MODE_EXPLANATION"))
		Self.AddChild(labelLongClickMode)
		labelLongClickMode.SetSize(checkboxWidth+30, -1)
		labelLongClickMode.SetFont( GetBitmapFont("default", 10) )
		labelLongClickMode.SetValueColor(TColor.CreateGrey(75))
		nextY :+ labelLongClickMode.GetValueDimension().y + 5

		labelLongClickTime = New TGUILabel.Create(New SVec2I(nextX + 22, nextY), GetLocale("LONGCLICK_TIME")+":")
		inputLongClickTime = New TGUIInput.Create(New SVec2I(nextX + 22, nextY + labelH), New SVec2I(50,-1), "", 4)
		labelLongClickTimeMilliseconds = New TGUILabel.Create(New SVec2I(nextX + 22 + 55 , nextY + labelH + 4), "ms")
		Self.AddChild(labelLongClickTime)
		Self.AddChild(inputLongClickTime)
		Self.AddChild(labelLongClickTimeMilliseconds)

		nextY :+ inputH + 5

		Return Self
	End Method


	Method ReadGuiValues:TData()
		Local data:TData = New TData

		data.Add("playername", inputPlayerName.GetValue())
		data.Add("channelname", inputChannelName.GetValue())
		data.Add("startyear", inputStartYear.GetValue())
		'data.Add("stationmap", inputStationmap.GetValue())
		data.Add("databaseDir", inputDatabase.GetValue())
		data.Add("inroomslowdown", inputInRoomSlowdown.GetValue())
		data.Add("autosaveInterval", inputAutoSaveInterval.GetValue())

'		data.AddBoolString("sound_music", checkMusic.IsChecked())
'		data.AddBoolString("sound_effects", checkSfx.IsChecked())
		data.Add("sound_engine", dropdownSoundEngine.GetSelectedEntry().data.GetString("value", "0"))


		data.Add("renderer", dropdownRenderer.GetSelectedEntry().data.GetString("value", "0"))
		data.AddBoolString("fullscreen", checkFullscreen.IsChecked())
		data.AddBoolString("vsync", checkVSync.IsChecked())
		data.Add("screenW", inputWindowResolutionWidth.GetValue())
		data.Add("screenH", inputWindowResolutionHeight.GetValue())

		data.Add("gamename", inputGameName.GetValue())
		data.Add("onlineport", inputOnlinePort.GetValue())

		data.AddBoolString("touchInput", checkTouchInput.IsChecked())
		data.Add("touchClickRadius", inputTouchClickRadius.GetValue())
		data.AddBoolString("longClickMode", checkLongClickMode.IsChecked())
		data.Add("longClicktime", inputLongClickTime.GetValue())

		data.AddBoolString("showIngameHelp", checkShowIngameHelp.IsChecked())

		data.AddNumber("sound_music_volume", sliderMusicVolume.GetValue().ToInt())
		data.AddNumber("sound_sfx_volume", sliderSFXVolume.GetValue().ToInt())

		Return data
	End Method


	Method SetGuiValues:Int(data:TData)
		sliderMusicVolume.SetValue(data.GetInt("sound_music_volume", 100))
		sliderSFXVolume.SetValue(data.GetInt("sound_sfx_volume", 100))

		inputPlayerName.SetValue(data.GetString("playername", "Player"))
		inputChannelName.SetValue(data.GetString("channelname", "My Channel"))
		inputStartYear.SetValue(data.GetInt("startyear", 1985))
		'inputStationmap.SetValue(data.GetString("stationmap", "res/maps/germany.xml"))
		If FileType(data.GetString("databaseDir")) <> 2
			data.AddString("databaseDir", "res/database/Default")
		EndIf
		inputDatabase.SetValue(data.GetString("databaseDir", "res/database/Default"))
		inputInRoomSlowdown.SetValue(data.GetInt("inroomslowdown", 100))
		inputAutoSaveInterval.SetValue(data.GetInt("autosaveInterval", 0))
'		checkMusic.SetChecked(data.GetBool("sound_music", True))
'		checkSfx.SetChecked(data.GetBool("sound_effects", True))
		checkFullscreen.SetChecked(data.GetBool("fullscreen", False))
		checkVSync.SetChecked(data.GetBool("vsync", True))
		inputWindowResolutionWidth.SetValue(Max(400, data.GetInt("screenW", 800)))
		inputWindowResolutionHeight.SetValue(Max(300, data.GetInt("screenH", 600)))
		checkTouchInput.SetChecked(data.GetBool("touchInput", MouseManager._ignoreFirstClick))
		inputTouchClickRadius.SetValue(Max(5, data.GetInt("touchClickRadius", MouseManager._minSwipeDistance)))
		checkLongClickMode.SetChecked(data.GetBool("longClickMode", MouseManager._longClickModeEnabled))
		inputLongClickTime.SetValue(Max(50, data.GetInt("longClickTime", MouseManager.longClickMinTime)))

		checkShowIngameHelp.SetChecked(data.GetBool("showIngameHelp", IngameHelpWindowCollection.showHelp))


		'disable certain elements if needed
		If Not checkLongClickMode.IsChecked()
			labelLongClickTime.Disable()
			inputLongClickTime.Disable()
			labelLongClickTimeMilliseconds.Disable()
		EndIf
		If Not checkTouchInput.IsChecked()
			labelTouchClickRadius.Disable()
			inputTouchClickRadius.Disable()
			labelTouchClickRadiusPixel.Disable()
		EndIf


		'check available sound engine entries
		Local selectedDropDownItem:TGUIDropDownItem
		For Local item:TGUIDropDownItem = EachIn dropdownSoundEngine.GetEntries()
			Local soundEngine:String = item.data.GetString("value")
			'if the same renderer - select this
			If soundEngine = data.GetString("sound_engine", "")
				selectedDropDownItem = item
				Exit
			EndIf
		Next
		'select the first if nothing was preselected
		If Not selectedDropDownItem
			dropdownSoundEngine.SetSelectedEntryByPos(0)
		Else
			dropdownSoundEngine.SetSelectedEntry(selectedDropDownItem)
		EndIf

		'check available renderer entries
		selectedDropDownItem = Null
		For Local item:TGUIDropDownItem = EachIn dropdownRenderer.GetEntries()
			Local renderer:Int = item.data.GetInt("value")
			'if the same renderer - select this
			If renderer = data.GetInt("renderer", 0)
				selectedDropDownItem = item
				Exit
			EndIf
		Next
		'select the first if nothing was preselected
		If Not selectedDropDownItem
			dropdownRenderer.SetSelectedEntryByPos(0)
		Else
			dropdownRenderer.SetSelectedEntry(selectedDropDownItem)
		EndIf


		inputGameName.SetValue(data.GetString("gamename", "New Game"))
		inputOnlinePort.SetValue(data.GetInt("onlineport", 4544))
	End Method



	Method onCheckCheckboxes:Int(event:TEventBase)
		Local checkBox:TGUICheckbox = TGUICheckbox(event.GetSender())
		If Not checkBox Then Return False

		If checkBox = checkLongClickMode
			If Not labelLongClickTime Then Return False
			If Not inputLongClickTime Then Return False
			If Not labelLongClickTimeMilliseconds Then Return False

			If checkLongClickMode.IsChecked()
				If Not labelLongClickTime.IsEnabled()
					labelLongClickTime.Enable()
					inputLongClickTime.Enable()
					labelLongClickTimeMilliseconds.Enable()
				EndIf
			Else
				If labelLongClickTime.IsEnabled()
					labelLongClickTime.Disable()
					inputLongClickTime.Disable()
					labelLongClickTimeMilliseconds.Disable()
				EndIf
			EndIf
		EndIf

		If checkBox = checkTouchInput
			If Not labelTouchClickRadius Then Return False
			If Not inputTouchClickRadius Then Return False
			If Not labelTouchClickRadiusPixel Then Return False

			If checkTouchInput.IsChecked()
				If Not labelTouchClickRadius.IsEnabled()
					labelTouchClickRadius.Enable()
					inputTouchClickRadius.Enable()
					labelTouchClickRadiusPixel.Enable()
				EndIf
			Else
				If labelTouchClickRadius.IsEnabled()
					labelTouchClickRadius.Disable()
					inputTouchClickRadius.Disable()
					labelTouchClickRadiusPixel.Disable()
				EndIf
			EndIf
		EndIf

		Return True
	End Method


	Method Update:Int()
		'dynamically update sounds
		GetSoundManagerBase().sfxVolume = (0.01 * sliderSFXVolume.GetValue().ToInt())
		GetSoundManagerBase().SetMusicVolume(0.01 * sliderMusicVolume.GetValue().ToInt())

		Return Super.Update()
	End Method


	Method DrawContent()
		Super.DrawContent()
		local col:Scolor8 = new SColor8(50, 50, 50)

		If Int(sliderSFXVolume.GetValue()) = 0
			GetBitmapFont("default").DrawSimple(GetLocale("SOUND_MUTED"), sliderSFXVolume.GetScreenRect().GetX() + 142, sliderSFXVolume.GetScreenRect().GetY() + 6, col)
		Else
			GetBitmapFont("default").DrawSimple(Int(sliderSFXVolume.GetValue())+" %", sliderSFXVolume.GetScreenRect().GetX() + 142, sliderSFXVolume.GetScreenRect().GetY() + 6, col)
		EndIf

		If Int(sliderMusicVolume.GetValue()) = 0
			GetBitmapFont("default").DrawSimple(GetLocale("SOUND_MUTED"), sliderMusicVolume.GetScreenRect().GetX() + 142, sliderMusicVolume.GetScreenRect().GetY() + 6, col)
		Else
			GetBitmapFont("default").DrawSimple(Int(sliderMusicVolume.GetValue())+" %", sliderMusicVolume.GetScreenRect().GetX() + 142, sliderMusicVolume.GetScreenRect().GetY() + 6, col)
		EndIf
	End Method

End Type



'the modal window containing various gui elements to configure some
'basics in the game
Type TSettingsWindow
	Field modalDialogue:TGUIGameModalWindow
	Field settingsPanel:TGUISettingsPanel
	Field _eventListeners:TEventListenerBase[]


	Method Remove:Int()
		If modalDialogue Then modalDialogue.Remove()
		If settingsPanel Then settingsPanel.Remove()

		settingsPanel = Null
		modalDialogue = Null

		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]
	End Method


	Method Delete()
		Remove()
	End Method


	Method Init:TSettingsWindow()
		'LAYOUT CONFIG
		Local windowW:Int = 700
		Local windowH:Int = 535

		modalDialogue = New TGUIGameModalWindow.Create(New SVec2I(0,0), New SVec2I(windowW, windowH), "SYSTEM")

		modalDialogue.SetDialogueType(2)
		modalDialogue.buttons[0].SetCaption(GetLocale("SAVE_AND_APPLY"))
		modalDialogue.buttons[0].SetSize(180,-1)
		modalDialogue.buttons[1].SetCaption(GetLocale("CANCEL"))
		modalDialogue.buttons[1].SetSize(160,-1)
		modalDialogue.SetCaptionAndValue(GetLocale("MENU_SETTINGS"), "")


		settingsPanel = New TGUISettingsPanel.Create(New SVec2I(0,0), New SVec2I(windowW, windowH), "SYSTEM")
		'add to canvas of this window
		modalDialogue.GetGuiContent().AddChild(settingsPanel)

		modalDialogue.Open()

		Return Self
	End Method


	Method SetGuiValues:Int(data:TData)
		If settingsPanel Then Return settingsPanel.SetGuiValues(data)
	End Method


	Method ReadGuiValues:TData()
		If settingsPanel Then Return settingsPanel.ReadGuiValues()
		Return New TData
	End Method
End Type