Rem
	===========================================================
	GUI Button
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.gfx.gui.label.bmx"
Import "base.util.registry.spriteloader.bmx"



Type TGUIButton Extends TGUIobject
	Field manualState:Int = 0
	Field spriteName:String = "gfx_gui_button.default"
	Field _sprite:TSprite 'private
	Field caption:TGUILabel	= Null
	Field captionArea:TRectangle = null
	Field autoSizeModeWidth:int = 0
	Field autoSizeModeHeight:int = 0

	Global AUTO_SIZE_MODE_NONE:int = 0
	Global AUTO_SIZE_MODE_TEXT:int = 1
	Global AUTO_SIZE_MODE_SPRITE:int = 2
	Global _typeDefaultFont:TBitmapFont
	Global _typeDefaultCaptionColor:TColor


	Method Create:TGUIButton(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, State)

		SetValue(value)

    	GUIManager.Add(Self)
		Return Self
	End Method


	'override
	Method onClick:Int(triggerEvent:TEventBase)
		Super.onClick(triggerEvent)
		'send a more specialized event
		if not triggerEvent.isVeto()
			EventManager.triggerEvent( TEventSimple.Create("guibutton.OnClick", triggerEvent._data, Self) )
		endif
	End Method


	Method RepositionCaption:Int()
		if not caption then return FALSE

		'resize to button dimension
		if captionArea
			local newX:Float = captionArea.GetX()
			local newY:Float = captionArea.GetY()
			local newDimX:Float = captionArea.GetW()
			local newDimY:Float = captionArea.GetH()
			'use parent values
			if newX = -1 then newX = 0
			if newY = -1 then newY = 0
			'take all the space left
			if newDimX <= 0 then newDimX = rect.GetW() - newX
			if newDimY <= 0 then newDimY = rect.GetH() - newY

			caption.rect.position.SetXY(newX, newY)
			caption.rect.dimension.SetXY(newDimX, newDimY)
		else
			caption.rect.position.SetXY(0, 0)
			caption.rect.dimension.CopyFrom(rect.dimension)
		endif
	End Method


	'override resize to add autocalculation and caption handling
	'size 0, 0 is not possible (leads to autosize)
	Method Resize(w:Float = 0, h:Float = 0)
		'autocalculate width/height
		if w <= 0
			if autoSizeModeWidth = AUTO_SIZE_MODE_TEXT
				w = GetFont().getWidth(self.value) + 8
			elseif autoSizeModeWidth = AUTO_SIZE_MODE_SPRITE
				w = GetSprite().GetWidth(false)
			endif
		endif
		if h <= 0
			h = rect.GetH()
			if autoSizeModeHeight <> AUTO_SIZE_MODE_NONE or h = -1

				if autoSizeModeHeight = AUTO_SIZE_MODE_TEXT
					h = GetFont().GetMaxCharHeight()
				endif

				'if height is less then sprite height (the "minimum")
				'use this
				h = Max(h, GetSprite().GetHeight(false))
			endif
		endif


		If w > 0 Then rect.dimension.setX(w)
		If h > 0 Then rect.dimension.setY(h)

		'move caption according to its rules
		RepositionCaption()
	End Method


	Method SetAutoSizeMode(modeWidth:int = 1, modeHeight:int = 1)
		autoSizeModeWidth = modeWidth
		autoSizeModeHeight = modeHeight
		Resize(-1,-1)
	End Method


	'override to inform other elements too
	Method SetAppearanceChanged:Int(bool:int)
		Super.SetAppearanceChanged(bool)
		'only inform if changed
		if bool = true
			if caption then caption.SetAppearanceChanged(bool)
		endif
	End Method



	'acts as cache
	Method GetSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not _sprite or _sprite.GetName() <> spriteName
			_sprite = GetSpriteFromRegistry(spriteName)
			'new -non default- sprite: adjust appearance
			if _sprite.GetName() <> "defaultsprite"
				SetAppearanceChanged(TRUE)
			endif
		endif
		return _sprite
	End Method


	'override default to handle image changes
	Method onStatusAppearanceChange:int()
		'if background changed we have to resize
		resize(-1, -1)
	End Method


	'override default - to use caption instead of value
	Method SetValue(value:string)
		SetCaption(value)
	End Method


	'override default - to use caption instead of value
	Method GetValue:String()
		if not caption then return Super.GetValue()
		return caption.GetValue()
	End Method


	Method SetCaption:Int(text:String, color:TColor=Null)
		if not caption
			'caption area starts at top left of button
			caption = New TGUILabel.Create(null, text, color, null)
			caption.SetContentPosition(ALIGN_CENTER, ALIGN_CENTER)
			'we want the caption to use the buttons font
			caption.SetOption(GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE, TRUE)
			'we want to manage it...
			GUIManager.Remove(caption)

			'reposition the caption
			RepositionCaption()

			'assign button as parent of caption
			caption.SetParent(self)
		elseif caption.value <> text
			caption.SetValue(text)
		endif

		If color
			caption.color = color
		Elseif _typeDefaultCaptionColor
			caption.color = _typeDefaultCaptionColor
		Endif
	End Method


	Method SetCaptionOffset:Int(x:int = -1, y:int = -1)
		if not captionArea then captionArea = new TRectangle
		captionArea.position.SetXY(x,y)
	End Method


	Function SetTypeCaptionColor:Int(color:TColor)
		_typeDefaultCaptionColor = color.Copy()
	End Function


	Function SetTypeFont:Int(font:TBitmapFont)
		_typeDefaultFont = font
	End Function


	'override in extended classes if wanted
	Function GetTypeFont:TBitmapFont()
		return _typeDefaultFont
	End Function


	Method GetSpriteName:String()
		return spriteName
	End Method


	Method SetCaptionAlign(alignType:String = "LEFT", valignType:String = "CENTER")
		if not caption then return

		'by default labels have left aligned content
		Select aligntype.ToUpper()
			case "CENTER" 	caption.SetContentPosition(ALIGN_LEFT, caption.contentPosition.y)
			case "RIGHT" 	caption.SetContentPosition(ALIGN_RIGHT, caption.contentPosition.y)
			default		 	caption.SetContentPosition(ALIGN_CENTER, caption.contentPosition.y)
		End Select
	End Method


	'override to update caption
	Method Update:int()
		Super.Update()
		if caption then caption.Update()
	End Method


	Method DrawButtonContent:Int(position:TVec2D)
		if not caption then return False
		if not caption.IsVisible() then return False

		'move caption
		if state = ".active" then caption.rect.position.AddXY(1,1)

		caption.Draw()

		'move caption back
		if state = ".active" then caption.rect.position.AddXY(-1,-1)
	End Method


	Method DrawContent()
		Local atPoint:TVec2D = GetScreenPos()
		Local oldCol:TColor = new TColor.Get()

		SetColor 255, 255, 255
		SetAlpha oldCol.a * GetScreenAlpha()

		Local sprite:TSprite = GetSprite()
		if not IsEnabled()
			sprite = GetSpriteFromRegistry(GetSpriteName() + ".disabled", sprite)
		else
			if state <> "" then sprite = GetSpriteFromRegistry(GetSpriteName() + state, sprite)
		endif

		if sprite
			'no active image available (when "mousedown" over widget)
			if state = ".active" and (sprite.name = spriteName or sprite.name="defaultsprite")
				sprite.DrawArea(atPoint.getX()+1, atPoint.getY()+1, rect.GetW(), rect.GetH())
			else
				sprite.DrawArea(atPoint.getX(), atPoint.getY(), rect.GetW(), rect.GetH())
			endif
		endif

		'draw label/caption of button
		DrawButtonContent(atPoint)

		oldCol.SetRGBA()
	End Method
End Type
