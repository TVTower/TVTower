SuperStrict
Import "base.gfx.gui.button.bmx"


Type TGUIToggleButton Extends TGUIButton
	Field toggled:Int = False
	Field valueUntoggled:String
	Field valueToggled:String
	Field spriteNameToggled:String
	Field spriteNameUntoggled:String


	Method GetClassName:String()
		Return "tguitogglebutton"
	End Method


	Method Create:TGUIToggleButton(pos:SVec2I, dimension:SVec2I, value:String, limitState:String="")
		'use another sprite name (assign before initing super)
		SetSpriteName("gfx_gui_button.round")

		SetCaptionValues(value, value)

		Super.Create(pos, dimension, value, limitState)

		Return Self
	End Method


	'override default to (un)check box
	Method onClick:Int(triggerEvent:TEventBase) override
		Local button:Int = triggerEvent.GetData().GetInt("button", -1)
		'only react to left mouse button
		If button <> 1 Then Return False

		'set box (un)checked
		SetToggled(1 - Istoggled())
		
		Return True
	End Method


	Method SetToggled:Int(toggled:Int=True, informOthers:Int=True)
		'if already same state - do nothing
		If Self.toggled = toggled Then Return False

		Self.toggled = toggled

		If informOthers 
			TriggerBaseEvent(GUIEventKeys.GUIToggleButton_OnSetToggled, New TData.AddNumber("toggled", toggled), Self )
		EndIf

		Return True
	End Method


	Method IsToggled:Int()
		Return toggled
	End Method


	'override to get value depending on toggled state
	Method GetValue:String()
		If IsToggled() Then Return valueToggled
		Return valueUntoggled
	End Method


	Method SetCaptionValues:Int(toggledValue:String, untoggledValue:String)
		Self.valueToggled = toggledValue
		Self.valueUntoggled = untoggledValue

		If Self.caption Then SetValue(GetValue())
	End Method


	'override for a differing alignment
	Method SetCaption:Int(text:String, color:TColor=Null)
		Super.SetCaption(text, color)

		'only overwrite this values if they weren't set yet
		If valueUntoggled = "" And valueToggled = ""
			valueUntoggled = text
			valueToggled = text
		EndIf
	End Method

Rem
	'private getter
	'acts as cache
	Method GetToggledSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not toggledSprite or toggledSprite.GetName() <> spriteNameToggled
			toggledSprite = GetSpriteFromRegistry(spriteNameToggled)
		endif

		return toggledSprite
	End Method


	'private getter
	'acts as cache
	Method GetUntoggledSprite:TSprite()
		if not spriteNameUntoggled then return Null

		'refresh cache if not set or wrong sprite name
		if not untoggledSprite or untoggledSprite.GetName() <> spriteNameUntoggled
			untoggledSprite = GetSpriteFromRegistry(spriteNameUntoggled)
		endif

		return untoggledSprite
	End Method
endrem

	'override
	'acts as cache
	Method GetSprite:TSprite()
		If toggled And spriteNameToggled
			_spriteName = spriteNameToggled
		ElseIf spriteNameUntoggled
			_spriteName = spriteNameUntoggled
		EndIf

		'refresh cache if not set or wrong sprite name
		If Not _sprite Or _sprite.GetName() <> _spriteName
			_sprite = GetSpriteFromRegistry(_spriteName)
			'new -non default- sprite: adjust appearance
			If _sprite <> TSprite.defaultSprite
				SetAppearanceChanged(True)
			EndIf
		EndIf
		Return _sprite
	End Method


	Method UpdateLayout()
	End Method
End Type




Type TGUITabGroup Extends TGUIObject
	Field buttons:TGUIToggleButton[]
	Field toggledButtonIndex:Int = -1

	Method GetClassName:String()
		Return "tguitabgroup"
	End Method


	Method Create:TGUITabGroup(position:SVec2I, dimension:SVec2I, limitState:String="")
		Super.CreateBase(position, dimension, limitState)
		Self.SetSize(dimension.x, dimension.y)

    	GUIManager.Add( Self )
		Return Self
	End Method


	Method AddButton(button:TGUIToggleButton, index:Int=-1)
		If Not buttons Then buttons = New TGUIToggleButton[0]

		If index = -1 Then index = buttons.length + 1
		If buttons.length <= index Then buttons = buttons[.. index + 1]

		buttons[index] = button
		AddChild(button)


		'adjust button skin
		For Local i:Int = 0 Until buttons.length
			If Not buttons[i] Then Continue

			If i = 0
				buttons[i].spriteNameToggled = "gfx_gui_tabgroup.left.toggled.default"
				buttons[i].spriteNameUntoggled = "gfx_gui_tabgroup.left.default"
			ElseIf i = buttons.length - 1
				buttons[i].spriteNameToggled = "gfx_gui_tabgroup.right.toggled.default"
				buttons[i].spriteNameUntoggled = "gfx_gui_tabgroup.right.default"
			Else
				buttons[i].spriteNameToggled = "gfx_gui_tabgroup.center.toggled.default"
				buttons[i].spriteNameUntoggled = "gfx_gui_tabgroup.center.default"
			EndIf
			buttons[i].SetAppearanceChanged(True)
		Next


		'align buttons
		Local totalButtonsWidth:Int = 0
		Local visibleButtonsCount:Int = 0
		For Local i:Int = 0 Until buttons.length
			If Not buttons[i] Then Continue

			If buttons[i].autoSizeModeWidth = TGUIBUtton.AUTO_SIZE_MODE_TEXT
				totalButtonsWidth :+ buttons[i].GetFont().getWidth(buttons[i].value) + 8 'TODO: button padding
			Else
				totalButtonsWidth :+ buttons[i].GetScreenRect().GetW()
			EndIf
			visibleButtonsCount :+ 1
		Next
'print "AddButton: visibleButtonsCount="+visibleButtonsCount+"  totalButtonsWidth="+totalButtonsWidth
		Local buttonSpacing:Int = 0
		Local buttonX:Int = 0
		If visibleButtonsCount > 0 Then buttonSpacing = totalButtonsWidth / visibleButtonsCount
		'center buttons?
		buttonX = 0.5 * (GetScreenRect().GetW() - totalButtonsWidth)
		For Local i:Int = 0 Until buttons.length
			If Not buttons[i] Then Continue

'print "  buttons["+i+"].rect.SetX("+buttonX+")   screenWidth="+buttons[i].GetScreenRect().GetW()
			buttons[i].rect.SetX(buttonX)

			Local buttonScreenWidth:Float = buttons[i].GetScreenRect().w
			buttonX :+ buttonScreenWidth + Max(0, (buttonSpacing - buttonScreenWidth))
		Next


		If toggledButtonIndex = -1
			button.SetToggled(True)
			toggledButtonIndex = index
		EndIf


		AddEventListener(EventManager.registerListenerMethod(GUIEventKeys.GUIToggleButton_OnSetToggled, Self, "onSetToggled", Null, button))
	End Method


	Method GetToggledButtonIndex:Int()
		If Not buttons Then Return -1
		toggledButtonIndex = -1
		For Local i:Int = 0 Until buttons.length
			If buttons[i] And buttons[i].IsToggled()
				toggledButtonIndex = i
				Return i
			EndIf
		Next
		Return -1
	End Method


	Method SetToggledButtonIndex:Int(i:Int)
		If buttons.length <= i Or i < 0
			i = -1
		EndIf

		Local button:TGUIToggleButton = buttons[i]
		If button
			If Not button.IsToggled()
				button.SetToggled(True)
			EndIf
			button.SetOption(GUI_OBJECT_CLICKABLE, False)
		EndIf

		If toggledButtonIndex <> -1
			If buttons[toggledButtonIndex] And buttons[toggledButtonIndex] <> button
				buttons[toggledButtonIndex].SetToggled(False)
				buttons[toggledButtonIndex].SetOption(GUI_OBJECT_CLICKABLE, True)
			EndIf
			'refresh
			GetToggledButtonIndex()
		EndIf

		TriggerBaseEvent(GUIEventKeys.GUITabGroup_OnSetToggledButton, New TData.AddNumber("index", i), Self )
	End Method


	Method GetButtonIndex:Int(button:TGUIToggleButton)
		If Not buttons Then Return -1

		For Local i:Int = 0 Until buttons.length
			If buttons[i] = button Then Return i
		Next
		Return -1
	End Method


	Method onSetToggled:Int(triggerEvent:TEventBase)
		Local toggledButton:TGUIToggleButton = TGUIToggleButton(triggerEvent._sender)
		If Not toggledButton Then Return False

		Local gotToggled:Int = toggledButton.IsToggled()
		If Not gotToggled Then Return False

		SetToggledButtonIndex( GetButtonIndex(toggledButton) )
Rem
		if toggledButtonIndex <> -1
			if buttons[toggledButtonIndex] and buttons[toggledButtonIndex] <> toggledButton
				buttons[toggledButtonIndex].SetToggled(False)
				buttons[toggledButtonIndex].SetOption(GUI_OBJECT_CLICKABLE, True)
			endif
			'refresh
			GetToggledButtonIndex()
		endif
		toggledButton.SetOption(GUI_OBJECT_CLICKABLE, False)
endrem
	End Method


	Method Update:Int()
'		If informOthers then TriggerBaseEvent(GUIEventKeys.GUICheckBox_OnSetChecked, new TData.AddNumber("checked", checked), Self )
		Return Super.Update()
	End Method


	Method DrawContent()
		Local oldColA:Float = GetAlpha()
		SetAlpha(oldColA * 0.3)
		GetSpriteFromRegistry("gfx_gui_slider.gauge").DrawArea(GetScreenRect().GetX(), GetScreenRect().GetY() + GetScreenRect().GetH()*0.5 - 8, GetScreenRect().GetW(), 6)
		SetAlpha(oldColA)
'		Super.DrawContent()
	End Method


	Method UpdateLayout()
	End Method
End Type
