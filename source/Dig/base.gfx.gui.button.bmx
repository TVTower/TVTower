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
	Field _spriteName:String
	Field _spriteNameDisabled:String
	Field _spriteNameActive:String 
	Field _spriteNameHovered:String
	Field _spriteNameSelected:String
	Field _spriteNameInUse:String
	
	Field _sprite:TSprite 'private
	Field caption:TGUILabel	= Null
	Field captionOffset:SVec2I
	Field autoSizeModeWidth:Int = 0
	Field autoSizeModeHeight:Int = 0

	Global AUTO_SIZE_MODE_NONE:Int = 0
	Global AUTO_SIZE_MODE_TEXT:Int = 1
	Global AUTO_SIZE_MODE_SPRITE:Int = 2
	Global _typeDefaultFont:TBitmapFont
	Global _typeDefaultCaptionColor:SColor8 = SColor8.Black


	Method GetClassName:String()
		Return "tguibutton"
	End Method
	
	
	Method New()
		SetSpriteName("gfx_gui_button.default")
	End Method

	Method Create:TGUIButton(pos:SVec2I, dimension:SVec2I, value:String, State:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, State)

		SetValue(value)

    	GUIManager.Add(Self)
		Return Self
	End Method
	
	
	'override to delete additional widgets too
	Method Remove:Int() override
		Super.Remove()
		
		'just in case this TGUILabel was focused, the Remove()
		'will clean this up 
		if caption then caption.Remove()
	End Method
	

	'override
	Method onClick:Int(triggerEvent:TEventBase) override
		Super.onClick(triggerEvent)
		'send a more specialized event
		If Not triggerEvent.isVeto()
			TriggerBaseEvent(GUIEventKeys.GUIButton_OnClick, triggerEvent.GetData(), Self)
			'button handled that click
			Return True
		EndIf
		
		'button did not handle that click
		Return False
	End Method


	Method RepositionCaption:Int()
		If Not caption Then Return False

		'resize to button dimension
		caption.SetPosition(captionOffset.x, captionOffset.y)
		caption.SetSize(rect.w - captionOffset.x, rect.h - captionOffset.y)
	End Method


	'override SetSize() to add autocalculation and caption handling
	'size 0, 0 is not possible (leads to autosize)
	Method SetSize(w:Float = 0, h:Float = 0)
		If h <= 0 then h = rect.GetH()
rem
		'autocalculate width/height
		If w <= 0
			If autoSizeModeWidth = AUTO_SIZE_MODE_TEXT
				w = GetFont().GetWidth(value) + 8
			ElseIf autoSizeModeWidth = AUTO_SIZE_MODE_SPRITE
				w = GetSprite().GetWidth(False)
			EndIf
		EndIf
		If h <= 0
			h = rect.GetH()
			If autoSizeModeHeight <> AUTO_SIZE_MODE_NONE Or h = -1

				If autoSizeModeHeight = AUTO_SIZE_MODE_TEXT
					h = GetFont().GetMaxCharHeight()
				EndIf

				'if height is less then sprite height (the "minimum")
				'use this
				h = Max(h, GetSprite().GetHeight(False))
			EndIf
		EndIf
endrem

		Super.SetSize(w, h)
	End Method


	Method SetAutoSizeMode(modeWidth:Int = 1, modeHeight:Int = 1)
		If autoSizeModeWidth <> modeWidth Or autoSizeModeHeight <> modeHeight
			autoSizeModeWidth = modeWidth
			autoSizeModeHeight = modeHeight

			InvalidateLayout()
		EndIf
	End Method


	'override to inform other elements too
	Method SetAppearanceChanged:Int(bool:Int)
		Super.SetAppearanceChanged(bool)
		'only inform if changed
		If bool = True
			If caption Then caption.SetAppearanceChanged(bool)
		EndIf
	End Method


	Method SetSpriteName(spriteName:String)
		If _spriteName <> spriteName
			_spriteName = spriteName
			_spriteNameDisabled = spriteName + ".disabled"
			_spriteNameActive = spriteName + ".active"
			_spriteNameSelected = spriteName + ".selected"
			_spriteNameHovered = spriteName + ".hover"
			
			_spriteNameInUse = ""
		EndIf
	End Method


	Method GetSpriteName:String()
		Return _spriteName
	End Method


	'acts as cache
	Method GetSprite:TSprite()
		Local newSprite:TSprite

		If Not IsEnabled()
			If _spriteNameInUse <> _spriteNameDisabled
				newSprite = GetSpriteFromRegistry(_spriteNameDisabled)
				'if not defined, try to fall back to "normal" one
				if newSprite.name = "defaultsprite" Then newSprite = GetSpriteFromRegistry(_spriteName)
				_spriteNameInUse = _spriteNameDisabled 'even if name did NOT exist!
			EndIf
		ElseIf IsActive() 
			If _spriteNameInUse <> _spriteNameActive
				newSprite = GetSpriteFromRegistry(_spriteNameActive)
				'if not defined, try to fall back to "hovered" one
				if newSprite.name = "defaultsprite" Then newSprite = GetSpriteFromRegistry(_spriteNameHovered)
				'if not defined, try to fall back to "normal" one
				if newSprite.name = "defaultsprite" Then newSprite = GetSpriteFromRegistry(_spriteName)
				_spriteNameInUse = _spriteNameActive 'even if name did NOT exist!
			EndIf
		ElseIf IsHovered() 
			If _spriteNameInUse <> _spriteNameHovered
				newSprite = GetSpriteFromRegistry(_spriteNameHovered)
				'if not defined, try to fall back to "active" one
				if newSprite.name = "defaultsprite" Then newSprite = GetSpriteFromRegistry(_spriteNameActive)
				'if not defined, try to fall back to "normal" one
				if newSprite.name = "defaultsprite" Then newSprite = GetSpriteFromRegistry(_spriteName)
				_spriteNameInUse = _spriteNameHovered 'even if name did NOT exist!
			EndIf
		ElseIf IsSelected()
			If _spriteNameInUse <> _spriteNameSelected
				newSprite = GetSpriteFromRegistry(_spriteNameSelected)
				'if not defined, try to fall back to "hovered" one
				if newSprite.name = "defaultsprite" Then newSprite = GetSpriteFromRegistry(_spriteNameHovered)
				'if not defined, try to fall back to "normal" one
				if newSprite.name = "defaultsprite" Then newSprite = GetSpriteFromRegistry(_spriteName)
				_spriteNameInUse = _spriteNameSelected 'even if name did NOT exist!
			EndIf
		'back to normal or initialization?
		ElseIf _spriteNameInUse <> _spriteName or not _sprite
			newSprite = GetSpriteFromRegistry(_spriteName, _sprite)
			_spriteNameInUse = _spriteName
		EndIf


		If newSprite
			_sprite = newSprite
			If _sprite <> TSprite.defaultSprite and _sprite.name <> "defaultsprite"
				SetAppearanceChanged(True)
'print "changed button sprite: " + _spriteNameInUse
			EndIf
		EndIf

		Return _sprite
	End Method


	'override default - to use caption instead of value
	Method SetValue(value:String)
		SetCaption(value)
	End Method


	'override default - to use caption instead of value
	Method GetValue:String()
		If Not caption Then Return Super.GetValue()
		Return caption.GetValue()
	End Method


	Method SetCaption:Int(text:String, color:TColor=Null)
		If Not caption
			'caption area starts at top left of button
			if not color
				caption = New TGUILabel.Create(new SVec2I(0,0), text, "")
			else
				caption = New TGUILabel.Create(new SVec2I(0,0), text, color.ToSColor8(), "")
			endif
			
			caption.SetContentAlignment(ALIGN_CENTER, ALIGN_CENTER)
			'we want the caption to use the buttons font
			caption.SetOption(GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE, True)
			caption.SetOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)
			'we want to manage it...
			GUIManager.Remove(caption)

			'reposition the caption
			RepositionCaption()

			'assign button as parent of caption
			caption.SetParent(Self)
		ElseIf caption.value <> text
			caption.SetValue(text)
			'reposition the caption
'			RepositionCaption()
		EndIf

		If color
			caption.color = color.ToSColor8()
		ElseIf _typeDefaultCaptionColor
			caption.color = _typeDefaultCaptionColor
		EndIf
	End Method


	Method SetCaptionOffset:Int(x:Int, y:Int)
		captionOffset = new SVec2I(x,y)

		RepositionCaption()

		if caption then caption.InvalidateScreenRect()
	End Method


	Function SetTypeCaptionColor:Int(color:SColor8)
		_typeDefaultCaptionColor = color
	End Function


	Function SetTypeFont:Int(font:TBitmapFont)
		_typeDefaultFont = font
	End Function


	'override in extended classes if wanted
	Function GetTypeFont:TBitmapFont()
		Return _typeDefaultFont
	End Function


	Method SetCaptionAlign(alignType:String = "LEFT", valignType:String = "CENTER")
		If Not caption Then Return

		'by default labels have left aligned content
		Select aligntype.ToUpper()
			Case "CENTER" 	caption.SetContentAlignment(ALIGN_LEFT, caption.contentAlignment.y)
			Case "RIGHT" 	caption.SetContentAlignment(ALIGN_RIGHT, caption.contentAlignment.y)
			Default		 	caption.SetContentAlignment(ALIGN_CENTER, caption.contentAlignment.y)
		End Select
	End Method


	'override to update caption
	Method Update:Int()
		Super.Update()
		If caption Then caption.Update()
	End Method


	Method DrawButtonContent:Int(position:SVec2F)
		If Not caption Then Return False
		If Not caption.IsVisible() Then Return False

		'move caption
		If IsActive()
			caption.GetScreenRect().MoveXY(1,1)
			caption.Draw()
			caption.GetScreenRect().MoveXY(-1,-1)
		Else
			caption.Draw()
		EndIf
	End Method
	
	
	Method DrawButtonBackground:Int(position:SVec2F)
		Local sprite:TSprite = GetSprite()
		If sprite
			'no active image available (when "mousedown" over widget)
			If IsActive() And (sprite.name = _spriteName Or sprite = TSprite.defaultSprite)
				sprite.DrawArea(position.x+1, position.y+1, rect.w, rect.h)
			Else
				sprite.DrawArea(position.x, position.y, rect.w, rect.h)
			EndIf
		EndIf
	End Method


	Method DrawContent()
		Local atPoint:SVec2F = GetScreenRect().GetPosition()
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		SetColor 255, 255, 255
		SetAlpha oldColA * GetScreenAlpha()

		DrawButtonBackground(atPoint)

		'draw label/caption of button
		DrawButtonContent(atPoint)

		SetColor(oldCol)
		SetAlpha(oldColA)
	End Method


	'override
	Method UpdateLayout()
		'autocalculate width/height
		If autoSizeModeWidth = AUTO_SIZE_MODE_TEXT
			rect.SetW( GetFont().GetWidth(value) + 8)
		ElseIf autoSizeModeWidth = AUTO_SIZE_MODE_SPRITE
			rect.SetW( GetSprite().GetWidth(False) )
		EndIf

		If autoSizeModeHeight <> AUTO_SIZE_MODE_NONE Or rect.GetH() = -1
			If autoSizeModeHeight = AUTO_SIZE_MODE_TEXT
				rect.SetH( GetFont().GetMaxCharHeight() )
			EndIf

			'if height is less then sprite height (the "minimum")
			'use this
			rect.SetH( Max(rect.GetH(), GetSprite().GetHeight(False)) )
		EndIf

		'move caption according to its rules
		RepositionCaption()
	End Method


	Method InvalidateScreenRect()
		Super.InvalidateScreenRect()
		if caption then caption.InvalidateScreenRect()
	End Method


	Method InvalidateContentScreenRect()
		Super.InvalidateContentScreenRect()
		if caption then caption.InvalidateContentScreenRect()
	End Method


	'override
	Method OnReposition(dx:Float, dy:Float)
		If dx = 0 And dy = 0 Then Return

		Super.OnReposition(dx, dy)
		If caption Then caption.OnReposition(dx, dy)
	End Method


	Method OnParentReposition(parent:TGUIObject, dx:Float, dy:Float)
		Super.OnParentReposition(parent,dx,dy)
		If caption Then caption.OnParentReposition(Self, dx, dy)
	End Method
End Type
