SuperStrict
Import "Dig/base.gfx.gui.bmx"
Import "Dig/base.gfx.gui.dropdown.bmx"
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "Dig/base.gfx.gui.input.bmx"
Import "Dig/base.sfx.soundmanager.base.bmx"
Import "common.misc.gamegui.bmx"
Import "game.misc.ingamehelp.bmx"


'panel for "single" display (not within the escape-menu)
Type TGUISettingsPanel extends TGUIPanel
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

	Field _eventListeners:TLink[]


	Method New()
		_EventListeners :+ [ EventManager.registerListenerMethod("guiCheckBox.onSetChecked", Self, "onCheckCheckboxes", "TGUICheckbox") ]
	End Method


	Method Remove:int()
		Super.Remove()

		EventManager.unregisterListenersByLinks(_eventListeners)
	End Method


	Method Create:TGUISettingsPanel(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)


		'LAYOUT CONFIG
		Local nextY:Int = 0, nextX:Int = 0
		Local rowWidth:Int[] = [210,210,250]
		Local checkboxWidth:Int = 180
		Local inputWidth:Int = 170
		Local labelH:Int = 12
		Local inputH:Int = 0

		Local labelTitleGameDefaults:TGUILabel = New TGUILabel.Create(New TVec2D.Init(0, nextY), GetLocale("DEFAULTS_FOR_NEW_GAME"))
		labelTitleGameDefaults.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		self.AddChild(labelTitleGameDefaults)
		nextY :+ 25

		Local labelPlayerName:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("PLAYERNAME")+":")
		inputPlayerName = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "", 128)
		self.AddChild(labelPlayerName)
		self.AddChild(inputPlayerName)
		inputH = inputPlayerName.GetScreenHeight()
		nextY :+ inputH + labelH * 1.5

		Local labelChannelName:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("CHANNELNAME")+":")
		inputChannelName = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "", 128)
		self.AddChild(labelChannelName)
		self.AddChild(inputChannelName)
		nextY :+ inputH + labelH * 1.5

		Local labelStartYear:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("START_YEAR")+":")
		inputStartYear = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(50,-1), "", 4)
		self.AddChild(labelStartYear)
		self.AddChild(inputStartYear)
		nextY :+ inputH + labelH * 1.5

		Local labelStationmap:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("STATIONMAP")+":")
		inputStationmap = New TGUIDropDown.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "germany.xml", 128)
		inputStationmap.disable()
		self.AddChild(labelStationmap)
		self.AddChild(inputStationmap)
		nextY :+ inputH + labelH * 1.5

		Local labelDatabase:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("DATABASE")+":")
		inputDatabase = New TGUIDropDown.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "res/database/Default", 128)
		inputDatabase.disable()
		self.AddChild(labelDatabase)
		self.AddChild(inputDatabase)
		nextY :+ inputH + labelH * 1.5

		checkShowIngameHelp = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth + 20,-1), GetLocale("SHOW_INTRODUCTORY_GUIDES"))
		self.AddChild(checkShowIngameHelp)
		nextY :+ checkShowIngameHelp.GetScreenHeight()

		nextY :+ 15



		'SINGLEPLAYER
		Local labelTitleSingleplayer:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("SINGLEPLAYER"))
		labelTitleSingleplayer.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		self.AddChild(labelTitleSingleplayer)
		nextY :+ 25

		Local labelInRoomSlowdown:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("GAME_SPEED_IN_ROOMS")+":")
		inputInRoomSlowdown = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(75,-1), "", 128)
		local labelInRoomSlowdownPercentage:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX + 75 + 5, nextY + 18), "%")
		self.AddChild(labelInRoomSlowdown)
		self.AddChild(inputInRoomSlowdown)
		self.AddChild(labelInRoomSlowdownPercentage)
		nextY :+ inputH + labelH * 1.5


		nextY = 0
		nextX = rowWidth[0]


		'SOUND
		Local labelTitleSound:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("SOUND_OUTPUT"))
		labelTitleSound.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		self.AddChild(labelTitleSound)
		nextY :+ 25

		Local labelMusicVolume:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("SOUND_MUSIC_VOLUME") + ":")
		sliderMusicVolume = New TGUISlider.Create(New TVec2D.Init(nextX -2, nextY + 14), New TVec2D.Init(140,inputH -6), "10")
		sliderMusicVolume.SetValueRange(0, 100)
		self.AddChild(labelMusicVolume)
		self.AddChild(sliderMusicVolume)
		nextY :+ Max(inputH - 5, sliderMusicVolume.GetScreenHeight())
		nextY :+ 20

		Local labelSFXVolume:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("SOUND_SFX_VOLUME") + ":")
		sliderSFXVolume = New TGUISlider.Create(New TVec2D.Init(nextX -2, nextY + 14), New TVec2D.Init(140,inputH -6), "10")
		sliderSFXVolume.SetValueRange(0, 100)
		self.AddChild(labelSFXVolume)
		self.AddChild(sliderSFXVolume)
		nextY :+ Max(inputH - 5, sliderSFXVolume.GetScreenHeight())
		nextY :+ 20


'		checkMusic = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth,-1), "")
'		checkMusic.SetCaption(GetLocale("MUSIC"))
'		self.AddChild(checkMusic)
'		nextY :+ Max(inputH - 5, checkMusic.GetScreenHeight())

'		checkSfx = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth,-1), "")
'		checkSfx.SetCaption(GetLocale("SFX"))
'		self.AddChild(checkSfx)
'		nextY :+ Max(inputH, checkSfx.GetScreenHeight())

		Local labelSoundEngine:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("SOUND_ENGINE") + ":")
		dropdownSoundEngine = New TGUIDropDown.Create(New TVec2D.Init(nextX, nextY + 14), New TVec2D.Init(inputWidth,-1), "", 128)
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
			Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(Null, Null, soundEngineTexts[i])
			item.SetValueColor(TColor.CreateGrey(50))
			item.data.Add("value", soundEngineValues[i])
			dropdownSoundEngine.AddItem(item)
			If itemHeight = 0 Then itemHeight = item.GetScreenHeight()
		Next
		dropdownSoundEngine.SetListContentHeight(itemHeight * Len(soundEngineValues))

		self.AddChild(labelSoundEngine)
		self.AddChild(dropdownSoundEngine)
'		GuiManager.SortLists()
		nextY :+ inputH + labelH * 1.5
		nextY :+ 15


		'GRAPHICS
		Local labelTitleGraphics:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("GRAPHICS"))
		labelTitleGraphics.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		self.AddChild(labelTitleGraphics)
		nextY :+ 25

		Local labelRenderer:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("RENDERER") + ":")
		dropdownRenderer = New TGUIDropDown.Create(New TVec2D.Init(nextX, nextY + 12), New TVec2D.Init(inputWidth,-1), "", 128)
		'Local rendererValues:String[] = ["0", "4"]
		'Local rendererTexts:String[] = ["OpenGL", "Buffered OpenGL"]
		Local rendererValues:String[]
		Local rendererTexts:String[]

		'fill with all available renderers
		For local i:int = 0 until TGraphicsManager.RENDERER_AVAILABILITY.length
			if TGraphicsManager.RENDERER_AVAILABILITY[i]
				rendererValues :+ [string(i)] 'i is the same key here
				rendererTexts :+ [ TGraphicsManager.RENDERER_NAMES[i] ]
			endif
		Next

		itemHeight = 0
		For Local i:Int = 0 Until rendererValues.Length
			Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(Null, Null, rendererTexts[i])
			item.SetValueColor(TColor.CreateGrey(50))
			item.data.Add("value", rendererValues[i])
			dropdownRenderer.AddItem(item)
			If itemHeight = 0 Then itemHeight = item.GetScreenHeight()
		Next
		dropdownRenderer.SetListContentHeight(itemHeight * Len(rendererValues))

		self.AddChild(labelRenderer)
		self.AddChild(dropdownRenderer)
		nextY :+ inputH + labelH * 1.5

		checkFullscreen = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth,-1), "")
		checkFullscreen.SetCaption(GetLocale("FULLSCREEN"))
		self.AddChild(checkFullscreen)
		nextY :+ Max(inputH -5, checkFullscreen.GetScreenHeight())

		checkVSync = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth,-1), "")
		checkVSync.SetCaption(GetLocale("VSYNC"))
		self.AddChild(checkVSync)
		nextY :+ Max(inputH, checkVSync.GetScreenHeight())

		Local labelWindowResolution:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("WINDOW_MODE_RESOLUTION")+":")
		inputWindowResolutionWidth = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + 12), New TVec2D.Init(inputWidth/2 - 15,-1), "", 4)
		inputWindowResolutionHeight = New TGUIInput.Create(New TVec2D.Init(nextX + inputWidth/2 + 15, nextY + 12), New TVec2D.Init(inputWidth/2 - 15,-1), "", 4)
		Local labelWindowResolutionX:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX + inputWidth/2 - 4, nextY + 18), "x")
		self.AddChild(labelWindowResolution)
		self.AddChild(labelWindowResolutionX)
		self.AddChild(inputWindowResolutionWidth)
		self.AddChild(inputWindowResolutionHeight)
		nextY :+ inputH + 5 + labelH * 1.5


		'MULTIPLAYER
		nextY = 0
		nextX = rowWidth[0] + rowWidth[1]
		Local labelTitleMultiplayer:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("MULTIPLAYER"))
		labelTitleMultiplayer.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		self.AddChild(labelTitleMultiplayer)
		nextY :+ 25

		Local labelGameName:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("GAME_TITLE")+":")
		inputGameName = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + labelH), New TVec2D.Init(inputWidth,-1), "", 128)
		self.AddChild(labelGameName)
		self.AddChild(inputGameName)
		nextY :+ inputH + labelH * 1.5


		Local labelOnlinePort:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("PORT_ONLINEGAME")+":")
		inputOnlinePort = New TGUIInput.Create(New TVec2D.Init(nextX, nextY + 12), New TVec2D.Init(50,-1), "", 4)
		self.AddChild(labelOnlinePort)
		self.AddChild(inputOnlinePort)
		nextY :+ inputH + labelH * 1.5
		nextY :+ 15

		'INPUT
		'nextY = 0
		'nextX = rowWidth[0] + rowWidth[1]
		Local labelTitleInput:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("INPUT"))
		labelTitleInput.SetFont(GetBitmapFont("default", 14, BOLDFONT))
		self.AddChild(labelTitleInput)
		nextY :+ 25

		checkTouchInput = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth + 20,-1), GetLocale("USE_TOUCH_INPUT"))
		self.AddChild(checkTouchInput)
		nextY :+ checkTouchInput.GetScreenHeight()

		local labelTouchInput:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("USE_TOUCH_INPUT_EXPLANATION"))
		self.AddChild(labelTouchInput)
		labelTouchInput.Resize(checkboxWidth+30,-1)
		labelTouchInput.SetFont( GetBitmapFont("default", 10) )
		labelTouchInput.SetValueColor(new TColor.CreateGrey(75))
		labelTouchInput.SetValue(labelTouchInput.GetValue())
		nextY :+ labelTouchInput.GetValueDimension().y + 5

		labelTouchClickRadius = New TGUILabel.Create(New TVec2D.Init(nextX + 22, nextY), GetLocale("MOVE_INSTEAD_CLICK_RADIUS")+":")
		inputTouchClickRadius = New TGUIInput.Create(New TVec2D.Init(nextX + 22, nextY + 12), New TVec2D.Init(50,-1), "", 4)
		labelTouchClickRadiusPixel = New TGUILabel.Create(New TVec2D.Init(nextX + 22 + 55, nextY + 18), "px")
		self.AddChild(labelTouchClickRadius)
		self.AddChild(inputTouchClickRadius)
		self.AddChild(labelTouchClickRadiusPixel)
		nextY :+ Max(inputH, inputTouchClickRadius.GetScreenHeight()) + 18


		checkLongClickMode = New TGUICheckbox.Create(New TVec2D.Init(nextX, nextY), New TVec2D.Init(checkboxWidth + 20,-1), GetLocale("LONGCLICK_MODE"))
		self.AddChild(checkLongClickMode)
		nextY :+ checkLongClickMode.GetScreenHeight()

		local labelLongClickMode:TGUILabel = New TGUILabel.Create(New TVec2D.Init(nextX, nextY), GetLocale("LONGCLICK_MODE_EXPLANATION"))
		self.AddChild(labelLongClickMode)
		labelLongClickMode.Resize(checkboxWidth+30, -1)
		labelLongClickMode.SetFont( GetBitmapFont("default", 10) )
		labelLongClickMode.SetValueColor(new TColor.CreateGrey(75))
		nextY :+ labelLongClickMode.GetValueDimension().y + 5

		labelLongClickTime = New TGUILabel.Create(New TVec2D.Init(nextX + 22, nextY), GetLocale("LONGCLICK_TIME")+":")
		inputLongClickTime = New TGUIInput.Create(New TVec2D.Init(nextX + 22, nextY + 12), New TVec2D.Init(50,-1), "", 4)
		labelLongClickTimeMilliseconds = New TGUILabel.Create(New TVec2D.Init(nextX + 22 + 55 , nextY + 18), "ms")
		self.AddChild(labelLongClickTime)
		self.AddChild(inputLongClickTime)
		self.AddChild(labelLongClickTimeMilliseconds)

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
		if FileType(data.GetString("databaseDir")) <> 2
			data.AddString("databaseDir", "res/database/Default")
		endif
		inputDatabase.SetValue(data.GetString("databaseDir", "res/database/Default"))
		inputInRoomSlowdown.SetValue(data.GetInt("inroomslowdown", 100))
'		checkMusic.SetChecked(data.GetBool("sound_music", True))
'		checkSfx.SetChecked(data.GetBool("sound_effects", True))
		checkFullscreen.SetChecked(data.GetBool("fullscreen", False))
		checkVSync.SetChecked(data.GetBool("vsync", True))
		inputWindowResolutionWidth.SetValue(Max(400, data.GetInt("screenW", 800)))
		inputWindowResolutionHeight.SetValue(Max(300, data.GetInt("screenH", 600)))
		checkTouchInput.SetChecked(data.GetBool("touchInput", MouseManager._ignoreFirstClick))
		inputTouchClickRadius.SetValue(Max(5, data.GetInt("touchClickRadius", MouseManager._minSwipeDistance)))
		checkLongClickMode.SetChecked(data.GetBool("longClickMode", MouseManager._longClickModeEnabled))
		inputLongClickTime.SetValue(Max(50, data.GetInt("longClickTime", MouseManager._longClickTime)))

		checkShowIngameHelp.SetChecked(data.GetBool("showIngameHelp", IngameHelpWindowCollection.showHelp))


		'disable certain elements if needed
		if not checkLongClickMode.IsChecked()
			labelLongClickTime.Disable()
			inputLongClickTime.Disable()
			labelLongClickTimeMilliseconds.Disable()
		endif
		if not checkTouchInput.IsChecked()
			labelTouchClickRadius.Disable()
			inputTouchClickRadius.Disable()
			labelTouchClickRadiusPixel.Disable()
		endif


		'check available sound engine entries
		Local selectedDropDownItem:TGUIDropDownItem
		For Local item:TGUIDropDownItem = EachIn dropdownSoundEngine.GetEntries()
			Local soundEngine:string = item.data.GetString("value")
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
		selectedDropDownItem = null
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



	Method onCheckCheckboxes:int(event:TEventSimple)
		local checkBox:TGUICheckbox = TGUICheckbox(event.GetSender())
		if not checkBox then return False

		if checkBox = checkLongClickMode
			if not labelLongClickTime then return False
			if not inputLongClickTime then return False
			if not labelLongClickTimeMilliseconds then return False

			if checkLongClickMode.IsChecked()
				if not labelLongClickTime.IsEnabled()
					labelLongClickTime.Enable()
					inputLongClickTime.Enable()
					labelLongClickTimeMilliseconds.Enable()
				endif
			else
				if labelLongClickTime.IsEnabled()
					labelLongClickTime.Disable()
					inputLongClickTime.Disable()
					labelLongClickTimeMilliseconds.Disable()
				endif
			endif
		endif

		if checkBox = checkTouchInput
			if not labelTouchClickRadius then return False
			if not inputTouchClickRadius then return False
			if not labelTouchClickRadiusPixel then return False

			if checkTouchInput.IsChecked()
				if not labelTouchClickRadius.IsEnabled()
					labelTouchClickRadius.Enable()
					inputTouchClickRadius.Enable()
					labelTouchClickRadiusPixel.Enable()
				endif
			else
				if labelTouchClickRadius.IsEnabled()
					labelTouchClickRadius.Disable()
					inputTouchClickRadius.Disable()
					labelTouchClickRadiusPixel.Disable()
				endif
			endif
		endif

		return True
	End Method


	Method Update:Int()
		'dynamically update sounds
		GetSoundManagerBase().sfxVolume = (0.01 * sliderSFXVolume.GetValue().ToInt()) 
		GetSoundManagerBase().SetMusicVolume(0.01 * sliderMusicVolume.GetValue().ToInt())

		Return Super.Update()
	End Method


	Method DrawContent()
		Super.DrawContent()

		If Int(sliderSFXVolume.GetValue()) = 0
			GetBitmapFont("default").Draw("muted", sliderSFXVolume.GetScreenX() + 142, sliderSFXVolume.GetScreenY() + 6, new TColor.CreateGrey(50))
		Else
			GetBitmapFont("default").Draw(Int(sliderSFXVolume.GetValue())+" %", sliderSFXVolume.GetScreenX() + 142, sliderSFXVolume.GetScreenY() + 6, new TColor.CreateGrey(50))
		EndIf

		If Int(sliderMusicVolume.GetValue()) = 0
			GetBitmapFont("default").Draw("muted", sliderMusicVolume.GetScreenX() + 142, sliderMusicVolume.GetScreenY() + 6, new TColor.CreateGrey(50))
		Else
			GetBitmapFont("default").Draw(Int(sliderMusicVolume.GetValue())+" %", sliderMusicVolume.GetScreenX() + 142, sliderMusicVolume.GetScreenY() + 6, new TColor.CreateGrey(50))
		EndIf
	End Method

End Type



'the modal window containing various gui elements to configure some
'basics in the game
Type TSettingsWindow
	Field modalDialogue:TGUIGameModalWindow
	Field settingsPanel:TGUISettingsPanel
	Field _eventListeners:TLink[]


	Method Remove:int()
		if modalDialogue then modalDialogue.Remove()
		if settingsPanel then settingsPanel.Remove()

		settingsPanel = null
		modalDialogue = null

		EventManager.unregisterListenersByLinks(_eventListeners)
	End Method


	Method Delete()
		Remove()
	End Method


	Method Init:TSettingsWindow()
		'LAYOUT CONFIG
		Local windowW:Int = 700
		Local windowH:Int = 490

		modalDialogue = New TGUIGameModalWindow.Create(New TVec2D, New TVec2D.Init(windowW, windowH), "SYSTEM")

		modalDialogue.SetDialogueType(2)
		modalDialogue.buttons[0].SetCaption(GetLocale("SAVE_AND_APPLY"))
		modalDialogue.buttons[0].Resize(180,-1)
		modalDialogue.buttons[1].SetCaption(GetLocale("CANCEL"))
		modalDialogue.buttons[1].Resize(160,-1)
		modalDialogue.SetCaptionAndValue(GetLocale("MENU_SETTINGS"), "")


		settingsPanel = new TGUISettingsPanel.Create(New TVec2D, New TVec2D.Init(windowW, windowH), "SYSTEM")
		'add to canvas of this window
		modalDialogue.GetGuiContent().AddChild(settingsPanel)

		modalDialogue.Open()

		return self
	End Method


	Method SetGuiValues:int(data:TData)
		if settingsPanel then return settingsPanel.SetGuiValues(data)
	End Method


	Method ReadGuiValues:TData()
		if settingsPanel then return settingsPanel.ReadGuiValues()
		return new TData
	End Method
End Type