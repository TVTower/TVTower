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
    Field color:TColor = new TColor.Create(120,120,120)
    Field maxTextWidth:Int
    Field spriteName:String = "gfx_gui_input.default"

	'=== OVERLAY ===
	'containing text or an icon (displayed separate from input widget)
    Field overlaySpriteName:String = Null	'name in case of dynamic getting
    Field overlaySprite:TSprite = Null		'icon in case of a custom created sprite
    Field overlayText:String = ""			'text to display separately
	'where to position the overlay: empty=none, "left", "right"
	Field overlayPosition:String = ""

	Field valueDisplacement:TVec2D
	Field _valueChanged:Int	= False '1 if changed
	Field _valueBeforeEdit:String = ""
	Field _editable:Int = True

	Global minDimension:TVec2D = new TVec2D.Init(40,28)
	'default name for all inputs
    Global spriteNameDefault:String	= "gfx_gui_input.default"


	Method Create:TGUIinput(pos:TVec2D, dimension:TVec2D, value:String, maxLength:Int=128, limitState:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, limitState)

'		SetZindex(20)
		SetValue(value)
		if maxLength >= 0
			SetMaxLength(maxLength)
		else
			SetMaxLength(2048)
		endif
'		SetValueColor(new TColor.Init(120,120,120))

		'this element reacts to keystrokes
		SetOption(GUI_OBJECT_CAN_RECEIVE_KEYSTROKES, True)

		GUIMAnager.Add(Self)
	  	Return Self
	End Method


	'override resize to add autocalculation and min handling
	Method Resize(w:Float=-1,h:Float=-1)
		Super.Resize(Max(w, minDimension.GetX()), Max(h, minDimension.GetY()))
	End Method


	Method SetEditable:Int(bool:Int)
		_editable = bool
	End Method


	Method SetMaxLength:Int(maxLength:Int)
		Self.maxLength = maxLength
	End Method


	Method SetValueDisplacement(x:Int, y:Int)
		valueDisplacement = new TVec2D.Init(x,y)
	End Method


	'(this creates a backup of the old value)
	Method SetFocus()
		Super.SetFocus()
		'backup old value
		_valueBeforeEdit = value
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		If Self._flags & GUI_OBJECT_ENABLED
			if _editable
				'manual entering "focus" with ENTER-key is not intended,
				'this is done by the app/game with "if enter then setFocus..."

				'enter pressed means: finished editing -> loose focus too
				If KEYMANAGER.isHit(KEY_ENTER) And hasFocus()
					KEYMANAGER.blockKey(KEY_ENTER, 200) 'to avoid auto-enter on a chat input
					GuiManager.ResetFocus()
					If Self = GuiManager.GetKeystrokeReceiver() Then GuiManager.SetKeystrokeReceiver(Null)
				EndIf

				'as soon as an input field is marked as active input
				'all key strokes could change the input
				If Self = GuiManager.GetKeystrokeReceiver()
					'ignore enter keys => TRUE
					If Not ConvertKeystrokesToText(value, True)
						value = _valueBeforeEdit

						'do not allow another ESC-press for 150ms
						KeyManager.blockKey(KEY_ESCAPE, 150)

						If Self = GuiManager.GetKeystrokeReceiver() Then GuiManager.SetKeystrokeReceiver(Null)
						GuiManager.ResetFocus()
					Else
						_valueChanged = (_valueBeforeEdit <> value)
					EndIf
				EndIf
			EndIf

			'if input is not the active input (enter key or clicked on another input)
			'and the value changed, inform others with an event
			If Self <> GuiManager.GetKeystrokeReceiver() And _valueChanged
				'reset changed indicator
				_valueChanged = False

				'fire onChange-event (text changed)
				EventManager.registerEvent( TEventSimple.Create( "guiobject.onChange", new TData.AddNumber("type", 1).AddString("value", value), Self ) )
			EndIf
		EndIf
		'set to "active" look
		If _editable and Self = GuiManager.GetKeystrokeReceiver() Then setState("active")

		'limit input length
        If value.length > maxlength Then value = value[..maxlength]
	End Method


    Method SetOverlayPosition:Int(position:String="left")
		Select position.toLower()
			Case "left" 	overlayPosition = "iconLeft"
			Case "right" 	overlayPosition = "iconRight"
			Default			overlayPosition = ""
		EndSelect
    End Method


	Method GetOverlaySprite:TSprite()
		if overlaySprite then return overlaySprite
		if overlaySpriteName then return GetSpriteFromRegistry(overlaySpriteName)
		return null
	End Method


	Method SetOverlay:Int(spriteOrSpriteName:object=Null, text:String="")
		'reset old
		overlaySprite = null
		overlaySpriteName = ""
		if TSprite(spriteOrSpriteName) then overlaySprite = TSprite(spriteOrSpriteName)
		if String(spriteOrSpriteName) then overlaySpriteName = String(spriteOrSpriteName)

		overlayText = text
		'give it an default orientation
		If overlayPosition = "" Then SetOverlayPosition("left")
	End Method


	'returns the area the overlay covers
	Method GetOverlayArea:TRectangle()
		local overlayArea:TRectangle = new TRectangle.Init(0,0,-1,-1)
		If overlayText<>""
			overlayArea.dimension.SetXY(GetFont().GetWidth(overlayText), GetFont().GetHeight(overlayText))
		Elseif GetOverlaySprite()
			overlayArea.dimension.SetXY(GetOverlaySprite().GetWidth(), GetOverlaySprite().GetHeight())
		EndIf
		return overlayArea
	End Method


	Method GetSpriteName:String()
		If overlayPosition<>"" Then Return spriteName + "."+overlayPosition
		Return spriteName
	End Method


	'draws overlay and returns used dimension/space
	Method DrawOverlay:TVec2D(position:TVec2D)
		'contains width/height of space the overlay uses
		local dim:TVec2D = new TVec2D.Init(0,0)
		local overlayArea:TRectangle = GetOverlayArea()
		'skip invalid overlay data
		If overlayArea.GetW() < 0  or overlayPosition = "" then return dim

		'draw background for overlay  [.][  Input  ]
		'design of input/button has to have a "name.background" sprite for this
		'area to get drawn properly
		'the overlays dimension is: overlaySprites border + icon dimension
		Local overlayBGSprite:TSprite = GetSpriteFromRegistry(GetSpriteName() + ".background" + Self.state)
		If overlayBGSprite
			'calculate center of overlayBG (left and right border could have different values)
			'-> bgBorderWidth/2
			local bgBorderWidth:int = overlayBGSprite.GetNinePatchBorderDimension().GetLeft() + overlayBGSprite.GetNinePatchBorderDimension().GetRight()
			local bgBorderHeight:int = overlayBGSprite.GetNinePatchBorderDimension().GetTop() + overlayBGSprite.GetNinePatchBorderDimension().GetBottom()

			'overlay background width is overlay + background  borders (the non content area)
			dim.SetX(overlayArea.GetW() + bgBorderWidth)

			If overlayPosition = "iconLeft"
				overlayBGSprite.DrawArea(position.GetX(), position.getY(), dim.GetX(), rect.GetH())
				'move area of overlay (eg. icon) - so it centers on the overlayBG
				overlayArea.position.SetX(bgBorderWidth/2)
			ElseIf overlayPosition = "iconRight"
				overlayBGSprite.DrawArea(position.GetX() + rect.GetW() - dim.GetX(), position.getY(), dim.GetX(), rect.GetH())
				'move area of overlay (eg. icon)
				overlayArea.position.SetX(rect.GetW() - dim.GetX() + bgBorderWidth/2)
			EndIf
		EndIf

		'vertical align overlayArea (ceil: "odd" values get rounded so coords are more likely within button area)
		overlayArea.position.SetY(ceil((rect.GetH()- overlayArea.GetH())/2))
		'draw the icon or label if needed
		If GetOverlaySprite()
			GetOverlaySprite().Draw(position.GetX() + overlayArea.GetX(), position.getY() + overlayArea.GetY())
		ElseIf overlayText<>""
			GetFont().Draw(overlayText, position.GetX() + overlayArea.GetX(), position.getY() + overlayArea.GetY())
		EndIf

		return dim
	End Method


	Method DrawContent:Int(position:TVec2D)
	    Local i:Int	= 0
		Local printValue:String	= value

		'if we are the input receiving keystrokes, symbolize it with the
		'blinking underscore sign "text_"
		'else just draw it like a normal gui object
		If _editable AND Self = GuiManager.GetKeystrokeReceiver()
			color.copy().AdjustFactor(-80).SetRGB()
			While Len(printvalue) >1 And GetFont().getWidth(printValue + "_") > maxTextWidth
				printvalue = printValue[1..]
			Wend
			GetFont().draw(printValue, position.GetIntX(), position.GetIntY())

			local oldAlpha:float = GetAlpha()
			SetAlpha Ceil(Sin(Time.GetTimeGone() / 4)) * oldAlpha
			GetFont().draw("_", Int(position.GetIntX() + GetFont().getWidth(printValue)), Int(position.GetY()) )

			SetAlpha oldAlpha
	    Else
			color.setRGB()
			While GetFont().GetWidth(printValue) > maxTextWidth And printvalue.length > 0
				printvalue = printValue[..printvalue.length - 1]
			Wend

			GetFont().drawStyled(printValue, position.GetIntX(), position.GetIntY(), color, 1)
		EndIf

	End Method


	Method Draw()
		Local atPoint:TVec2D = GetScreenPos()
		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()

		Local textPos:TVec2D
		Local widgetWidth:Int = rect.GetW()
		If Not valueDisplacement
			'add "false" to GetMaxCharHeight so it ignores parts of
			'characters with parts below baseline.
			'avoids "above center"-look if value does not contain such
			'characters
			textPos = new TVec2D.Init(5, (rect.GetH() - GetFont().GetMaxCharHeight(False)) /2)
		Else
			textPos = valueDisplacement.copy()
		EndIf


		'=== DRAW BACKGROUND SPRITE ===
		'if a spriteName is set, we use a spriteNameDefault,
		'else we just skip drawing the sprite
		Local sprite:TSprite
		If spriteName<>"" Then sprite = GetSpriteFromRegistry(GetSpriteName() + Self.state, spriteNameDefault)
		If sprite
			'draw overlay and save occupied space
			local overlayDim:TVec2D = DrawOverlay(atPoint)

			'move sprite by Icon-Area (and decrease width)
			If overlayPosition = "iconLeft" Then atPoint.AddXY(overlayDim.GetX(), overlayDim.GetY())
			widgetWidth :- overlayDim.GetX()

			sprite.DrawArea(atPoint.GetX(), atPoint.getY(), widgetWidth, rect.GetH())
			'move text according to content borders
			textPos.SetX(Max(textPos.GetX(), sprite.GetNinePatchContentBorder().GetLeft()))
		EndIf


		'=== DRAW TEXT/CONTENT ===
		'limit maximal text width
		Self.maxTextWidth = widgetWidth - textPos.GetX()*2
		'actually draw
		DrawContent(atPoint.Copy().AddXY(textPos.GetX(), textPos.GetY()))

		oldCol.SetRGBA()
	End Method
End Type