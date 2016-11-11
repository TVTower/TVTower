Rem
	===========================================================
	GUI Panel
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.backgroundbox.bmx"
Import "base.gfx.gui.textbox.bmx"




Type TGUIPanel Extends TGUIObject
	Field guiBackground:TGUIBackgroundBox = Null
	Field guiTextBox:TGUITextBox
	Field guiTextBoxAlignment:TVec2D
	Field _defaultValueColor:TColor


	Method Create:TGUIPanel(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)

		GUIManager.Add(Self)
		Return Self
	End Method


	Method Remove:int()
		Super.Remove()

		if guiBackground then guiBackground.Remove()
		if guiTextBox then guiTextBox.Remove()
	End Method


	Method GetPadding:TRectangle()
		'if no manual padding was setup - use sprite padding
		if not _padding and guiBackground then return guiBackground.GetPadding()
		Return Super.GetPadding()
	End Method


	Method Resize(w:Float = 0, h:Float = 0)
		'resize self
		If w > 0 Then rect.dimension.setX(w) Else w = rect.GetW()
		If h > 0 Then rect.dimension.setY(h) Else h = rect.GetH()

		'move background
		If guiBackground Then guiBackground.resize(w,h)
		'move textbox
		If guiTextBox
			'text box is aligned to padding - so can start at "0,0"
			'-> no additional offset
			guiTextBox.rect.position.SetXY(0,0)

			'getContentScreenWidth takes GetPadding into consideration
			'which considers guiBackground already - so no need to distinguish
			guiTextBox.resize(GetContentScreenWidth(),GetContentScreenHeight())
		EndIf
	End Method


	'override to also check  children
	Method IsAppearanceChanged:int()
		if guiBackground and guiBackground.isAppearanceChanged() then return TRUE
		if guiTextBox and guiTextBox.isAppearanceChanged() then return TRUE

		return Super.isAppearanceChanged()
	End Method


	'override default to handle image changes
	Method onStatusAppearanceChange:int()
		'if background changed - or textbox, we to have resize and
		'reposition accordingly
		resize()
	End Method


	Method SetBackground(obj:TGUIBackgroundBox=Null)
		'remove old background from children
		if guiBackground then removeChild(guiBackground)

		'reset to nothing?
		If Not obj
			If guiBackground
				guiBackground.remove()
				guiBackground = Null
			EndIf
		Else
			guiBackground = obj
			'set background to ignore parental padding (so it starts at 0,0)
			guiBackground.SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
			'set background to to be on same level than parent
			guiBackground.SetZIndex(-1)

			'we manage it now, not the guimanager
			addChild(obj)
		EndIf
	End Method


	'override default to return textbox value
	Method GetValue:String()
		If guiTextBox Then Return guiTextBox.GetValue()
		Return ""
	End Method


	'override default to set textbox value
	Method SetValue(value:String="")
		If value=""
			If guiTextBox
				RemoveChild(guiTextBox)
				guiTextBox.remove()
				guiTextBox = Null
			EndIf
		Else
			Local padding:TRectangle = new TRectangle.Init(0,0,0,0)
			'read padding from background

			if guiBackground then padding = guiBackground.GetSprite().GetNinePatchContentBorder()

			if not guiTextBox
				guiTextBox = New TGUITextBox.Create(new TVec2D.Init(0,0), new TVec2D.Init(50,50), value, "")
				'we take care of the text box
				AddChild(guiTextBox)

				if not guiTextBoxAlignment then guiTextBoxAlignment = ALIGN_CENTER_CENTER
			else
				guiTextBox.SetValue(value)
			endif

			If _defaultValueColor
				guiTextBox.SetValueColor(_defaultValueColor)
			Else
				guiTextBox.SetValueColor(TColor.clWhite)
			EndIf
			guiTextBox.SetValueAlignment( guiTextBoxAlignment )
			guiTextBox.SetAutoAdjustHeight(True)
		EndIf

		'to resize textbox accordingly
		Resize()
	End Method


	Method disableBackground()
		If guiBackground Then guiBackground.disable()
	End Method


	Method enableBackground()
		If guiBackground Then guiBackground.enable()
	End Method


	Method DrawContent()
		'
	End Method


	Method Update:Int()
		'as we do not call "super.Update()" - we handle this manually
		'if appearance changed since last update tick: inform widget
		If isAppearanceChanged()
			onStatusAppearanceChange()
			SetAppearanceChanged(false)
		Endif

		UpdateChildren()
	End Method
End Type
