Rem
	===========================================================
	GUI Button
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.util.registry.spriteloader.bmx"


TGUILabel._defaultDrawTextEffect = new TDrawTextEffect
TGUILabel._defaultDrawTextEffect.data.mode = EDrawTextEffect.Emboss
TGUILabel._defaultDrawTextEffect.data.value = -1.0 'default

Type TGUILabel Extends TGUIobject
	Field contentDisplacement:TVec2D = New TVec2D(0,0)
	Field color:SColor8 = SColor8.Black
	Field _valueDimensionCache:TVec2D = Null
	Field spriteName:String = ""
	Field _sprite:TSprite 'private
	Field valueSpriteMode:Int = 0 'only text
	Field textCache:TBitmapFontText = New TBitmapFontText
	Field _drawTextEffect:TDrawTextEffect


	Const MODE_TEXT_ONLY:Int = 0
	Const MODE_SPRITE_ONLY:Int = 1
	Const MODE_SPRITE_LEFT_OF_TEXT:Int = 2
	Const MODE_SPRITE_RIGHT_OF_TEXT:Int = 3
	'variants which get ignored in dimension calculation
	'(they keep text centered in the area)
	Const MODE_SPRITE_LEFT_OF_TEXT2:Int = 4
	Const MODE_SPRITE_RIGHT_OF_TEXT2:Int = 5
	Const MODE_SPRITE_LEFT_OF_TEXT3:Int = 6
	Const MODE_SPRITE_RIGHT_OF_TEXT3:Int = 7
	Const MODE_SPRITE_ABOVE_TEXT:Int = 8
	Const MODE_SPRITE_BELOW_TEXT:Int = 9

	Global _typeDefaultFont:TBitmapFont
	Global _defaultDrawTextEffect:TDrawTextEffect ' = new TDrawTextEffect



	Method GetClassName:String()
		Return "tguilabel"
	End Method


	Method Create:TGUILabel(pos:SVec2I, text:String, State:String="")
		Return Create(pos, text, self.color, State)
	End Method


	'will be added to general GuiManager
	'-- use CreateSelfContained to get a unmanaged object
	Method Create:TGUILabel(pos:SVec2I, text:String, color:SColor8, State:String="")
		Super.CreateBase(pos, new SVec2I(-1,-1), State)

		'by default labels have left aligned content
		SetContentAlignment(ALIGN_LEFT, ALIGN_CENTER)

		Self.SetValue(text)
		Self.color = color

		GUIManager.Add(Self)
		Return Self
	End Method

	
	Method GetDrawTextEffect:TDrawTextEffect()
		if not _drawTextEffect Then return _defaultDrawTextEffect
		Return _drawTextEffect
	End Method


	Method SetContentDisplacement:Int(displacement:TVec2D)
		If displacement Then contentDisplacement.CopyFrom(displacement)
	End Method


	Method SetValueColor:Int(color:SColor8)
		self.color = color
	End Method
	
	Method SetValueColor:Int(color:TColor)
		If color Then Self.color = color.ToSColor8()
	End Method


	Method SetValueEffect:Int(valueEffectType:Int, valueEffectSpecial:Float = 1.0)
		if not _drawTextEffect Then _drawTextEffect = new TDrawTextEffect

		Select valueEffectType
			case 1	_drawTextEffect.data.mode = EDrawTextEffect.Shadow
			case 2	_drawTextEffect.data.mode = EDrawTextEffect.Glow
			case 3	_drawTextEffect.data.mode = EDrawTextEffect.Emboss
			default _drawTextEffect.data.mode = EDrawTextEffect.None
		End Select
		
		_drawTextEffect.data.value = valueEffectSpecial
	End Method


	Method SetValueEffect:Int(valueEffectType:EDrawTextEffect = EDrawTextEffect.None, valueEffectSpecial:Float = 1.0)
		if not _drawTextEffect Then _drawTextEffect = new TDrawTextEffect

		_drawTextEffect.data.mode = valueEffectType		
		_drawTextEffect.data.value = valueEffectSpecial
	End Method


	Method SetValue(value:String)
		If GetValue() <> value
			Super.SetValue(value)

			_valueDimensionCache = Null
			
			If textCache Then textCache.Invalidate()
			InvalidateScreenRect()

			SetAppearanceChanged(True)
		EndIf
	End Method


	Method SetSpriteName(value:String)
		Self.spriteName = value
	End Method


	Method GetSpriteName:String()
		Return spriteName
	End Method


	Method SetSprite(sprite:TSprite)
		Self._Sprite = sprite
	End Method


	Method GetSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		If (Not _sprite And spriteName<>"") Or (_sprite And _sprite.GetName() <> spriteName)
			_sprite = GetSpriteFromRegistry(spriteName)
			'new -non default- sprite: adjust appearance
			If _sprite <> TSprite.defaultSprite
				SetAppearanceChanged(True)
			EndIf
		EndIf
		Return _sprite
	End Method


	Method SetValueSpriteMode(mode:Int)
		If valueSpriteMode <> mode
			valueSpriteMode = mode

			SetAppearanceChanged(True)
		EndIf
	End Method


	Function SetTypeFont:Int(font:TBitmapFont)
		_typeDefaultFont = font
	End Function


	'override in extended classes if wanted
	Function GetTypeFont:TBitmapFont()
		Return _typeDefaultFont
	End Function
 
	Method GetValueDimension:TVec2D()
		If Not _valueDimensionCache
			Local availableW:Int = rect.GetW()
			Local availableH:Int = rect.GetH()
			Local sprite:TSprite = GetSprite()
			'subtract sprite for calculation
			If sprite
				Select valueSpriteMode
					Case MODE_SPRITE_ONLY
						_valueDimensionCache = New TVec2D(sprite.GetWidth(), sprite.GetHeight())
					Case MODE_SPRITE_LEFT_OF_TEXT, MODE_SPRITE_RIGHT_OF_TEXT
						availableW :- sprite.GetWidth()
					Case MODE_SPRITE_ABOVE_TEXT, MODE_SPRITE_BELOW_TEXT
						availableH :- sprite.GetHeight()
				End Select
			EndIf

			Local s:SVec2I = GetFont().GetBoxDimension(value, availableW, availableH)
			_valueDimensionCache = New TVec2D(s.x, s.y)

			'add back sprite to result
			If sprite
				Select valueSpriteMode
					Case MODE_SPRITE_LEFT_OF_TEXT, MODE_SPRITE_RIGHT_OF_TEXT
						_valuedimensionCache.AddX( sprite.GetWidth() )
					Case MODE_SPRITE_ABOVE_TEXT, MODE_SPRITE_BELOW_TEXT
						_valuedimensionCache.AddY( sprite.GetHeight() )
				End Select
			EndIf
		EndIf
		Return _valueDimensionCache
	End Method


	Method DrawContent()
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		SetAlpha oldColA * GetScreenAlpha()

		Local mode:Int = valueSpriteMode
		Local dim:TVec2D = GetValueDimension()
		Local sprite:TSprite = GetSprite()
		If Not sprite Then mode = MODE_TEXT_ONLY

		Local scrTRect:TRectangle = GetScreenRect()
		
		Local textH:Int = scrTRect.GetH() - 2*contentDisplacement.GetY()
		If scrTRect.GetH() < 0 Then textH = -1

		Local textW:Int = scrTRect.GetW() - 2*contentDisplacement.GetX()
		
		Local scrRect:SRect = New SRect(scrTRect.GetX(), scrTRect.GetY(), scrTRect.GetW(), scrTRect.GetH())

		Select valueSpriteMode
			Case MODE_SPRITE_LEFT_OF_TEXT
				GetFont().DrawBox(value, scrRect.x + contentDisplacement.GetX() + sprite.GetWidth(), scrRect.y + contentDisplacement.GetY(), textW, textH, contentAlignment, color, GetDrawTextEffect().data)
				sprite.Draw(int(scrRect.x + contentDisplacement.GetX()), int(scrRect.y - 1 + contentDisplacement.GetY() + 0.5 * textH), -1, ALIGN_LEFT_CENTER)
			Case MODE_SPRITE_LEFT_OF_TEXT2
				GetFont().DrawBox(value, scrRect.x + contentDisplacement.GetX(), scrRect.y + contentDisplacement.GetY(), textW, textH, contentAlignment, color, GetDrawTextEffect().data)
				sprite.Draw(int(scrRect.x + contentDisplacement.GetX()), int(scrRect.y - 1 + contentDisplacement.GetY() + 0.5 * textH), -1, ALIGN_LEFT_CENTER)
			Case MODE_SPRITE_LEFT_OF_TEXT3
				GetFont().DrawBox(value, scrRect.x + contentDisplacement.GetX(), scrRect.y + contentDisplacement.GetY(), textW, textH, contentAlignment, color, GetDrawTextEffect().data)
				sprite.Draw(int(scrRect.x + 0.5 * (scrRect.w - dim.x)), int(scrRect.y - 1 + contentDisplacement.GetY() + 0.5 * textH), -1, ALIGN_RIGHT_CENTER)

			Case MODE_SPRITE_RIGHT_OF_TEXT
				Local mydim:SVec2I = GetFont().DrawBox(value, scrRect.x + contentDisplacement.GetX(), scrRect.y + contentDisplacement.GetY(), textW - sprite.GetWidth(), textH, contentAlignment, color, GetDrawTextEffect().data)
				sprite.Draw(int(scrRect.x + contentDisplacement.GetX() + mydim.x), int(scrRect.y + contentDisplacement.GetY() + 0.5 * mydim.y))
			Case MODE_SPRITE_RIGHT_OF_TEXT2
				Local mydim:SVec2I = GetFont().DrawBox(value, scrRect.x + contentDisplacement.GetX(), scrRect.y + contentDisplacement.GetY(), textW, textH, contentAlignment, color, GetDrawTextEffect().data)
				sprite.Draw(int(scrRect.x + contentDisplacement.GetX() + mydim.X), int(scrRect.y + contentDisplacement.GetY() + 0.5 * mydim.y))

			Case MODE_SPRITE_ABOVE_TEXT
				sprite.Draw(int(scrRect.x + 0.5 * scrRect.w), int(scrRect.y + contentDisplacement.GetY()), -1, ALIGN_CENTER_CENTER)
				GetFont().DrawBox(value, scrRect.x + contentDisplacement.GetX() + sprite.GetWidth(), scrRect.y + contentDisplacement.GetY(), textW, textH + sprite.GetHeight(), contentAlignment, color, GetDrawTextEffect().data)

			Case MODE_SPRITE_BELOW_TEXT
				Local mydim:SVec2I = GetFont().DrawBox(value, scrRect.x + contentDisplacement.GetX(), scrRect.y + contentDisplacement.GetY(), textW, textH, contentAlignment, color, GetDrawTextEffect().data)
				sprite.Draw(int(scrRect.x + 0.5 * scrRect.w), int(scrRect.y + contentDisplacement.GetY() + mydim.y), -1, ALIGN_CENTER_CENTER)

			Case MODE_SPRITE_ONLY
				sprite.Draw(int(scrRect.x + 0.5 * scrRect.w), int(scrRect.y + 0.5 * scrRect.h), -1, ALIGN_CENTER_CENTER)

			Default
				' TODO: Move that into the text cache if it is of use
				'       for other text display elements too
				
				' the "descend" (the space below the base line required 
				' to eg. draw "pqgyj") is substracted/"added" so that 
				' "centering" between "hello" and "yeah" does not differ.
				' RONNY: descend adjustment seems to be no longer needed
				'textCache.DrawBlock(GetFont(), value, Int(scrRect.x + contentDisplacement.GetX()), Int(scrRect.y + contentDisplacement.GetY() - contentAlignment.y * GetFont().descend), textW, textH, contentAlignment, color, GetDrawTextEffect(), null)
				textCache.DrawBlock(GetFont(), value, Int(scrRect.x + contentDisplacement.GetX()), Int(scrRect.y + contentDisplacement.GetY()), textW, textH, contentAlignment, color, GetDrawTextEffect(), null)
		End Select


		SetColor(oldCol)
		SetAlpha(oldColA)
	End Method


	Method UpdateLayout()
'		Super.UpdateLayout()
	End Method


	Method onAppearanceChanged:Int()
		_valueDimensionCache = Null
		if textCache then textCache.Invalidate()

		Return Super.onAppearanceChanged()
	End Method


	'override
	Method OnResize(dW:Float, dH:Float) override
		Super.OnResize(dW, dH)
		_valueDimensionCache = Null
	End Method
End Type
