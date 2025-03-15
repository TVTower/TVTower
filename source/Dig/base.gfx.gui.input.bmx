Rem
	===========================================================
	GUI Input box
	===========================================================
End Rem
SuperStrict
Import "base.util.registry.spriteloader.bmx"
Import "base.gfx.gui.bmx"
Import "base.gfx.sprite.bmx"



Type TGUIinput Extends TGUIobject
    Field maxLength:Int
    Field color:SColor8 = New SColor8(80,80,80)
    Field editColor:SColor8 = New SColor8(40,40,40)
    Field maxTextWidthBase:Int
    Field maxTextWidthCurrent:Int
    Field _sprite:TSprite
	Field _spriteName:String = "gfx_gui_input.default"
	Field _spriteNameBase:String = "gfx_gui_input.default"
	Field _spriteNameDisabled:String = "gfx_gui_input.default"
	Field _spriteNameActive:String = "gfx_gui_input.default"
	Field _spriteNameHovered:String = "gfx_gui_input.default"
	Field _spriteNameSelected:String = "gfx_gui_input.default"
	Field _spriteNameInUse:String = "gfx_gui_input.default"

    Field textEffectAmount:Float = -1.0
    Field textEffectType:EDrawTextEffect = EDrawTextEffect.None
    Field overlayArea:TRectangle = New TRectangle


	'=== OVERLAY ===
	'containing text or an icon (displayed separate from input widget)

    'name in case of dynamic getting
    Field overlaySpriteName:String = Null
    'icon in case of a custom created sprite
    Field overlaySprite:TSprite = Null
    'text to display separately
    Field overlayText:String = ""
    'color for overlay text
    Field overlayColor:SColor8
	'where to position the overlay: empty=none, "left", "right"
	Field overlayPosition:String = ""

	Field placeholder:String = ""
    Field placeholderColor:SColor8
	Field valueDisplacement:TVec2D
	Field _textPos:TVec2D
	Field _cursorPosition:Int = -1
	Field _valueChanged:Int	= False '1 if changed
	Field _valueBeforeEdit:String = ""
	Field _valueAtLastUpdate:String = ""
	Field _valueOffset:Int = 0
	Field _editable:Int = True
	Field _mousePositionsCursor:Int = False

	Global minDimension:TVec2D = New TVec2D(40,28)
	'default name for all inputs
    Global spriteNameDefault:String	= "gfx_gui_input.default"
    
    Const FINISHED_WITH_OTHER:Int = 0
    Const FINISHED_WITH_ENTERKEY:Int = 1
    Const FINISHED_LOOSING_FOCUS:Int = 2


	Method GetClassName:String()
		Return "tguiinput"
	End Method


	Method Create:TGUIInput(pos:SVec2I, dimension:SVec2I, value:String, maxLength:Int=128, limitState:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, limitState)

'		SetZindex(20)
		SetValue(value)
		If maxLength >= 0
			SetMaxLength(maxLength)
		Else
			SetMaxLength(2048)
		EndIf

		'this element reacts to keystrokes
		SetOption(GUI_OBJECT_CAN_RECEIVE_KEYBOARDINPUT, True)
		'stay activated if clicked into
		SetOption(GUI_OBJECT_STAY_ACTIVE_AFTER_MOUSECLICK, True)

		'init sprite names
		SetSpriteName(_spriteNameBase)

		GUIMAnager.Add(Self)
	  	Return Self
	End Method


	'override resize to add autocalculation and min handling
	Method SetSize(w:Float = 0, h:Float = 0)
		Super.SetSize(Max(w, minDimension.GetX()), Max(h, minDimension.GetY()))
	End Method


	Method SetEditable:Int(bool:Int)
		_editable = bool
	End Method


	Method SetMaxLength:Int(maxLength:Int)
		Self.maxLength = maxLength
	End Method


	Method SetMaxTextWidth(maxTextWidth:Int)
		maxTextWidthBase = maxTextWidth
	End Method


	Method SetValueDisplacement(x:Int, y:Int)
		valueDisplacement = New TVec2D(x,y)
	End Method


	'override
	Method SetValue(value:String)
		If value <> GetValue()
			_valueChanged = True
			_valueBeforeEdit = value

			Super.SetValue(value)
		EndIf
	End Method


	'override
	Method GetValue:String()
		'return the original value until edit was finished (or aborted)
		If _valueChanged Then Return _valueBeforeEdit

		Return Super.GetValue()
	End Method


	Method GetCurrentValue:String()
		'return the current value regardless of "in edit" or not
		Return value
	End Method


	Method onClick:Int(triggerEvent:TEventBase) override
		'only handle left clicks
		If triggerEvent.GetData().GetInt("button") <> 1 Then Return False
		
		'first click activates "cursor positioning mode"
		If not _mousePositionsCursor
			_mousePositionsCursor = true
			Return True
		EndIf
		
		'active input fields react to mouse clicks on the input-area
		'to move the cursor position
		If Self = GuiManager.GetKeyboardInputReceiver()
			'shrink screenrect to "text area"
			Local scrRect:TRectangle = GetScreenRect()
			Local screenX:Int = _textPos.x
			Local screenY:Int = _textPos.y
			Local screenW:Int = Self.maxTextWidthCurrent
			Local screenH:Int = scrRect.h - (_textPos.y - scrRect.y)

			'clear "getchar()"-queue and states
			'(this avoids entering previously pressed keystrokes)
			FlushKeys()

			If THelper.MouseIn(screenX, screenY, screenW, screenH)
				Local valueOffsetPixels:Int = 0
				If _valueOffset > 0 Then valueOffsetPixels = GetFont().GetWidth( value[.. _valueOffset] )
'local old:int = _cursorPosition
				Local valueClickedPixel:Int = MouseManager.x - screenX + valueOffsetPixels
				Local newCursorPosition:Int = -1
				For Local i:Int = 0 To value.length-1
					If GetFont().GetWidth(value[.. i]) > valueClickedPixel
						newCursorPosition = Max(0, i-1)
						Exit
					EndIf
				Next
				If newCursorPosition <> -1 Then _cursorPosition = newCursorPosition
'print " ... Mouse "+int(MouseManager.x)+", "+int(MouseManager.y)+" is in. Position: " + old +" => " + _cursorPosition + "  valueClickedPixel="+valueClickedPixel+"  valueOffsetPixels="+valueOffsetPixels

				'handled left click
				Return True
			EndIf
		EndIf
	End Method


	Method PasteFromClipboard:Int() override
		'cannot edit at all?
		if not _editable then Return False
		
		Local t:String = GetOSClipboard()
		t = t.Replace("~n", "~~n")

		'only override value if clipboard contained something?
		if t
			If not IsFocused()
				SetValue( t )
			else
				_valueChanged = True
				if _cursorPosition = -1 or _cursorPosition = 0
					value = t + value
				elseif _cursorPosition = value.length
					value = value + t
				else
					value = value[.. _cursorPosition] + t + value[_cursorPosition + 1 ..]
				endif
			EndIf
		endif
		
		Return True
	End Method


	'called when trying to "ctrl + c"
	Method CopyToClipboard:Int() override
		'GetCurrentValue() returns value as displayed
		'GetValue() returns the "old value" until an edit was finished
		Local t:String = GetCurrentValue()
		t = t.Replace("~~n", "~n")
		SetOSClipboard( t )
		
		Return True
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		If Self._flags & GUI_OBJECT_ENABLED
			Local confirmedWithEnter:Int
			If _editable
				'manual entering "focus" with ENTER-key is not intended,
				'this is done by the app/game with "if enter then setFocus..."

				'enter pressed means: finished editing -> loose focus too
				If KEYMANAGER.isHit(KEY_ENTER) And IsFocused()
					KEYMANAGER.blockKey(KEY_ENTER, 200) 'to avoid auto-enter on a chat input

					GuiManager.ResetFocus()
					If Self = GuiManager.GetKeyboardInputReceiver()
						GuiManager.SetKeyboardInputReceiver(Null)
					EndIf

					'remove internal "active" state 
					_SetActive(False)

					'manually confirm this edit has finished
					confirmedWithEnter = True
				EndIf
'				If GuiManager.GetActive() = self Then GuiManager.SetActive(Null)



				'as soon as an input field is marked as active input
				'all key strokes could change the input
				If Self = GuiManager.GetKeyboardInputReceiver()
					If _cursorPosition = -1 Then _cursorPosition = value.length

					'ignore enter keys => TRUE
					If Not ConvertKeystrokesToText(value, _cursorPosition, True)
						value = _valueBeforeEdit

						'do not allow another ESC-press for 150ms
						KeyManager.blockKey(KEY_ESCAPE, 150)

						GuiManager.SetKeyboardInputReceiver(Null)
						If Self = GuiManager.GetKeyboardInputReceiver()
							GuiManager.SetKeyboardInputReceiver(Null)
						EndIf
						_SetActive(False)
					Else
						_valueChanged = (_valueBeforeEdit <> value)
					EndIf

					If _valueAtLastUpdate <> value
						'explicitely inform about a change of the displayed value
						TriggerBaseEvent(GUIEventKeys.GUIInput_OnChangeValue, New TData.AddNumber("type", 1).AddString("value", value).AddString("originalValue", _valueBeforeEdit).AddString("previousValue", _valueAtLastUpdate), Self )
						_valueAtLastUpdate = value
					EndIf
				EndIf
			EndIf

			'if input is not the active input (enter key or clicked on another input)
			'inform others with events
			'onChangedValue for changed value
			'onFinishEdit for being done with editing now
			If Self <> GuiManager.GetKeyboardInputReceiver() 
				If confirmedWithEnter
					FinishEdit(TGUIInput.FINISHED_WITH_ENTERKEY)
				ElseIf _valueChanged
					FinishEdit(TGUIInput.FINISHED_WITH_OTHER)
				Endif
			EndIf
		EndIf
		'set to "active" look
		If _editable and not IsActive() And Self = GuiManager.GetKeyboardInputReceiver() 
			_SetActive(True)
		endif

		'limit input length
        If value.length > maxlength
			value = value[..maxlength]
			_cursorPosition = -1
		EndIf
	End Method
	
	
	Method FinishEdit(finishMode:Int)
		If _valueChanged 
			'reset changed indicator
			_valueChanged = False
			'reset cursor position
			_cursorPosition = -1

			'fire onChange-event (text changed)
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnChange, New TData.AddNumber("type", 1).AddString("value", value).AddString("originalValue", _valueBeforeEdit), Self )

			'explicitely inform about a change of the displayed value
			'only send this once
			If _valueAtLastUpdate <> value
				TriggerBaseEvent(GUIEventKeys.GUIInput_OnChangeValue, New TData.AddNumber("type", 1).AddString("value", value).AddString("originalValue", _valueBeforeEdit), Self )
			EndIf
		EndIf

		'inform that editing was somehow finished (eg ENTER Key or lost focus)
		TriggerBaseEvent(GUIEventKeys.GUIInput_OnFinishEdit, New TData.AddInt("FinishMode", finishMode), Self )
	End Method


    Method SetOverlayPosition:Int(position:String="left")
		Select position.toLower()
			Case "left" 	overlayPosition = "iconLeft"
			Case "right" 	overlayPosition = "iconRight"
			Default			overlayPosition = ""
		EndSelect

		'update sprite names
		If _spriteNameBase
			SetSpriteName(_spriteNameBase)
		EndIf
    End Method


	Method GetOverlaySprite:TSprite()
		If overlaySprite Then Return overlaySprite
		If overlaySpriteName Then Return GetSpriteFromRegistry(overlaySpriteName)
		Return Null
	End Method


	Method SetOverlay:Int(spriteOrSpriteName:Object=Null, text:String="")
		'reset old
		overlaySprite = Null
		overlaySpriteName = ""
		If TSprite(spriteOrSpriteName) Then overlaySprite = TSprite(spriteOrSpriteName)
		If String(spriteOrSpriteName) Then overlaySpriteName = String(spriteOrSpriteName)

		overlayText = text
		'give it an default orientation
		If overlayPosition = "" Then SetOverlayPosition("left")
	End Method


	'returns the area the overlay covers
	Method GetOverlayArea:TRectangle()
		If overlayText<>""
			overlayArea.SetWH(GetFont().GetWidth(overlayText), GetFont().GetHeight(overlayText))
		ElseIf GetOverlaySprite()
			overlayArea.SetWH(GetOverlaySprite().GetWidth(), GetOverlaySprite().GetHeight())
		Else
			overlayArea.SetWH(-1, -1)
		EndIf
		Return overlayArea
	End Method


	Method SetSpriteName(name:String)
		_spriteNameBase = name

		If overlayPosition
			_spriteName = _spriteNameBase + "." + overlayPosition
		Else
			_spriteName = _spriteNameBase
		EndIf
		_spriteNameDisabled = _spriteName + ".disabled"
		_spriteNameActive = _spriteName + ".active"
		_spriteNameSelected = _spriteName + ".selected"
		_spriteNameHovered = _spriteName + ".hover"
		
		_spriteNameInUse = ""
	End Method


	Method GetSpriteName:String()
		Return _spriteName
	End Method


	'acts as cache
	Method GetSprite:TSprite()
		'if no spriteName is defined, do not return a sprite 
		If not _spriteName Then Return Null

		Local newSprite:TSprite

		If Not IsEnabled() 
			If _spriteNameInUse <> _spriteNameDisabled
				newSprite = GetSpriteFromRegistry(_spriteNameDisabled, spriteNameDefault)
				_spriteNameInUse = _spriteNameDisabled 'even if name did NOT exist!
			EndIf
		ElseIf IsActive() 
			If _spriteNameInUse <> _spriteNameActive
				newSprite = GetSpriteFromRegistry(_spriteNameActive, spriteNameDefault)
				_spriteNameInUse = _spriteNameActive 'even if name did NOT exist!
			EndIf
		ElseIf IsHovered() 
			If _spriteNameInUse <> _spriteNameHovered
				newSprite = GetSpriteFromRegistry(_spriteNameHovered, spriteNameDefault)
				_spriteNameInUse = _spriteNameHovered 'even if name did NOT exist!
			EndIf
		ElseIf IsSelected() 
			If _spriteNameInUse <> _spriteNameSelected
				newSprite = GetSpriteFromRegistry(_spriteNameSelected, spriteNameDefault)
				_spriteNameInUse = _spriteNameSelected 'even if name did NOT exist!
			EndIf
		'back to normal?
		ElseIf _spriteNameInUse <> _spriteName
			newSprite = GetSpriteFromRegistry(_spriteName, spriteNameDefault)
			_spriteNameInUse = _spriteName
		EndIf

		If Not _sprite
			newSprite = GetSpriteFromRegistry(_spriteName, spriteNameDefault)
		EndIf

		If newSprite
			_sprite = newSprite
			If _sprite <> TSprite.defaultSprite
				SetAppearanceChanged(True)
				'print "changed input sprite: " + _spriteNameInUse + "   name="+_spriteName + "  hovered="+_spriteNameHovered + "  active="+_spriteNameActive
			EndIf
		EndIf

		Return _sprite
	End Method

	'draws overlay and returns used dimension/space
	Method DrawButtonOverlay:SVec2F(position:SVec2F)
		'contains width/height of space the overlay uses
		Local oW:Float
		Local oH:Float
		Local overlayArea:TRectangle = GetOverlayArea()
		'skip invalid overlay data
		If overlayArea.w < 0  Or overlayPosition = "" Then Return new SVec2F(oW, oH)

		'draw background for overlay  [.][  Input  ]
		'design of input/button has to have a "name.background" sprite for this
		'area to get drawn properly
		'the overlays dimension is: overlaySprites border + icon dimension
		Local overlayBGSprite:TSprite
		If Self.IsHovered()
			overlayBGSprite = GetSpriteFromRegistry(GetSpriteName() + ".background.hover")
		ElseIf Self.IsActive()
			overlayBGSprite = GetSpriteFromRegistry(GetSpriteName() + ".background.active")
		Else
			overlayBGSprite = GetSpriteFromRegistry(GetSpriteName() + ".background")
		EndIf
		If overlayBGSprite
			'calculate center of overlayBG (left and right border could have different values)
			'-> bgBorderWidth/2
			Local cb:SRect = overlayBGSprite.GetNinePatchInformation().contentBorder
			Local bgBorderWidth:Int = cb.GetLeft() + cb.GetRight()
			Local bgBorderHeight:Int = cb.GetTop() + cb.GetBottom()

			'overlay background width is overlay + background  borders (the non content area)
			oW = overlayArea.GetW() + bgBorderWidth

			If overlayPosition = "iconLeft"
				overlayBGSprite.DrawArea(Float(position.x), Float(position.y), oW, rect.h)
				'move area of overlay (eg. icon) - so it centers on the overlayBG
				overlayArea.SetX(bgBorderWidth/2)
			ElseIf overlayPosition = "iconRight"
				overlayBGSprite.DrawArea(Float(position.x) + rect.w - oW, Float(position.y), oW, rect.h)
				'move area of overlay (eg. icon)
				overlayArea.SetX(rect.w - oW + bgBorderWidth/2)
			EndIf
		EndIf

		'vertical align overlayArea (ceil: "odd" values get rounded so coords are more likely within button area)
		overlayArea.SetY(Float(Ceil((rect.h - overlayArea.h)/2)))
		'draw the icon or label if needed
		If GetOverlaySprite()
			GetOverlaySprite().Draw(Float(position.x) + overlayArea.x, Float(position.y) + overlayArea.y)
		ElseIf overlayText<>""
			GetFont().Draw(overlayText, Float(position.x) + overlayArea.x, Float(position.y) + overlayArea.y, overlayColor)
		EndIf

		Return new SVec2F(oW, oH)
	End Method


	Method DrawInputContent:Int(x:Int, y:Int)
	    Local i:Int	= 0
		Local printValue:String	= value
		Local oldCol:SColor8; GetColor(oldCol)

		'if we are the input receiving keystrokes, symbolize it with the
		'blinking underscore sign "text_"
		'else just draw it like a normal gui object
		If _editable And Self = GuiManager.GetKeyboardInputReceiver()
			SetColor( editColor )

			If _cursorPosition = -1 Then _cursorPosition = printValue.length

			'calculate values left and right sided of the cursor
			_valueOffset = 0
			Local leftValue:String, rightValue:String
			Local leftValueW:Int, rightValueW:Int
			Local cursorW:Int = 0
			If _cursorPosition = printValue.length
				leftValue = printValue
				rightValue = ""
			ElseIf _cursorPosition = 0
				leftValue = ""
				rightValue = printValue
			Else
				leftValue = printValue[.. _cursorPosition]
				rightValue = printValue[_cursorPosition ..]
			EndIf

			'make sure we see the cursor
			While leftValue.length > 1 And GetFont().getWidth(leftValue) + cursorW > maxTextWidthCurrent
				leftValue = leftValue[1..]
				_valueOffset :+ 1
			Wend
			'beautify: if there is much on the right side left, move it even further to the left
			'if value.length - leftValue.length > 0 and leftValue.length >= 3
			'	leftValue = leftValue[3 ..]
			'endif

			leftValueW = GetFont().GetWidth(leftValue)

			'limit rightValue to fit into the left space
			If rightValue <> ""
				While rightValue.length > 0 And GetFont().getWidth(rightValue) > maxTextWidthCurrent - leftValueW - cursorW
					rightValue = rightValue[.. rightValue.length -1]
				Wend
			EndIf


			GetFont().DrawSimple(leftValue, x, y, editColor, EDrawTextEffect.None, textEffectAmount * 0.75)
			DrawCaret(x + leftValueW, y)
			'ignore cursor-offset (to avoid "letter-jiggling")
			GetFont().DrawSimple(rightValue, x + leftValueW, y, editColor, EDrawTextEffect.None, textEffectAmount * 0.5 )
	    Else
			If printValue.length = 0
				printValue = placeholder
			EndIf

			While printValue.length > 0 And GetFont().GetWidth(printValue) > maxTextWidthCurrent
				printValue = printValue[.. printValue.length - 1]
			Wend


			If value.length = 0
				GetFont().DrawSimple(printValue, x, y, placeholderColor, textEffectType, textEffectAmount)
			Else
				GetFont().DrawSimple(printValue, x, y, color, textEffectType, textEffectAmount)
			EndIf
		EndIf

		SetColor(oldCol)
	End Method


	Method DrawCaret(x:Int, y:Int)
		Local oldAlpha:Float = GetAlpha()
		SetAlpha Float(Ceil(Sin(Time.GetTimeGone() / 4)) * oldAlpha)
	'	DrawLine(x, y + 2, x, y + GetFont().GetMaxCharHeight() - 4 )
		DrawLine(x, y + 3, x, y + GetFont().GetMaxCharHeightAboveBaseline() + 1 )
		SetAlpha oldAlpha
	End Method


	Method DrawContent()
		'to allow modification
		Local atPointX:Int = GetScreenRect().x
		Local atPointY:Int = GetScreenRect().y
		'Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		SetAlpha oldColA * GetScreenAlpha()

		Local widgetWidth:Int = rect.w
		
		If Not _textPos Then _textPos = New TVec2D

		If Not valueDisplacement
			'add "false" to GetMaxCharHeight so it ignores parts of
			'characters with parts below baseline.
			'avoids "above center"-look if value does not contain such
			'characters
'			_textPos.SetXY(2, (rect.h - GetFont().GetMaxCharHeight(False)) / 2)
			' Noto Sans seems to define a big "ascender" (a lot whitespace
			' on top of the UPPER-case letters)
			Local f:TBitmapFont = GetFont()
			_textPos.SetXY(2, Int((rect.h - f.GetMaxCharHeight(True)) / 2.0 + f.GetXHeight()/6.0))
		Else
			_textPos.copyFrom(valueDisplacement)
		EndIf
		_textPos.AddXY(atPointX, atPointY)


		'=== DRAW BACKGROUND SPRITE ===
		'if a spriteName is set, we use a spriteNameDefault,
		'else we just skip drawing the sprite
		Local sprite:TSprite = GetSprite()
		If sprite
			'draw overlay and save occupied space
			Local overlayDim:SVec2F = DrawButtonOverlay(GetScreenRect().GetPosition())

			'move sprite by Icon-Area (and decrease width)
			If overlayPosition = "iconLeft"
				atPointX :+ overlayDim.x
				atPointY :+ overlayDim.y
				_textPos.AddX(overlayDim.x)
			EndIf
			widgetWidth :- overlayDim.x

			sprite.DrawArea(atPointX, atPointY, widgetWidth, rect.h)
			'move text according to content borders
			_textPos.AddX(sprite.GetNinePatchInformation().contentBorder.GetLeft())
			'_textPos.SetX(Max(_textPos.GetX(), sprite.GetNinePatchContentBorder().GetLeft()))
		EndIf


		'=== DRAW TEXT/CONTENT ===
		'limit maximal text width
		If maxTextWidthBase > 0
			Self.maxTextWidthCurrent = Min(maxTextWidthBase, widgetWidth - (_textPos.GetX() - atPointX)*2)
		Else
			Self.maxTextWidthCurrent = widgetWidth - (_textPos.GetX() - atPointX)*2
		EndIf
		'actually draw
		DrawInputContent(_textPos.GetIntX(), _textPos.GetIntY())
		
		SetAlpha(oldColA)
	End Method


	Method UpdateLayout()
	End Method


	'override
	'(this creates a backup of the old value)
	Method _OnSetFocus:Int() Override
		If Super._OnSetFocus()
			'backup old value
			_valueBeforeEdit = value
			
			'start at end of "value"
			_cursorPosition = -1

			'clear "getchar()"-queue and states
			'(this avoids entering previously pressed keystrokes)
			FlushKeys()

			Return True
		Else
			Return False
		EndIf
	End Method


	Method _OnRemoveFocus:Int() Override
		Super._OnRemoveFocus()

		FinishEdit(TGUIInput.FINISHED_LOOSING_FOCUS)

		_mousePositionsCursor = False

		Return True
	End Method
End Type
