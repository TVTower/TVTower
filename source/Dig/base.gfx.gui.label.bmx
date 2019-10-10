Rem
	===========================================================
	GUI Button
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.util.registry.spriteloader.bmx"



Type TGUILabel Extends TGUIobject
	Field contentDisplacement:TVec2D = New TVec2D.Init(0,0)
	Field color:TColor = TColor.Create(0,0,0)
	Field valueEffectType:Int = 1
	Field valueEffectSpecial:Float = 1.0
	Field _valueDimensionCache:TVec2D = Null
	Field spriteName:String = ""
	Field _sprite:TSprite 'private
	Field valueSpriteMode:Int = 0 'only text
	Field textCache:TBitmapFontText = new TBitmapFontText

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



	Method GetClassName:String()
		Return "tguilabel"
	End Method


	'will be added to general GuiManager
	'-- use CreateSelfContained to get a unmanaged object
	Method Create:TGUILabel(pos:TVec2D, text:String, color:TColor=Null, State:String="")
		Super.CreateBase(pos, Null, State)

		'by default labels have left aligned content
		SetContentAlignment(ALIGN_LEFT, ALIGN_CENTER)

		Self.SetValue(text)
		If color Then Self.color = color

		GUIManager.Add(Self)
		Return Self
	End Method


	Method SetContentDisplacement:Int(displacement:TVec2D)
		If displacement Then contentDisplacement.CopyFrom(displacement)
	End Method


	Method SetValueColor:Int(color:TColor)
		If color Then Self.color = color.copy()
	End Method


	Method SetValueEffect:Int(valueEffectType:Int, valueEffectSpecial:Float = 1.0)
		Self.valueEffectType = valueEffectType
		Self.valueEffectSpecial = valueEffectSpecial
	End Method


	Method SetValue(value:String)
		If GetValue() <> value
			Super.SetValue(value)

			if textCache then textCache.Invalidate()

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
			If _sprite.GetName() <> "defaultsprite"
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
						_valueDimensionCache = New TVec2D.Init(sprite.GetWidth(), sprite.GetHeight())
					Case MODE_SPRITE_LEFT_OF_TEXT, MODE_SPRITE_RIGHT_OF_TEXT
						availableW :- sprite.GetWidth()
					Case MODE_SPRITE_ABOVE_TEXT, MODE_SPRITE_BELOW_TEXT
						availableH :- sprite.GetHeight()
				End Select
			EndIf

			_valueDimensionCache = New TVec2D
			_valueDimensionCache.SetX(GetFont().getWidth(value))

			'does the text fit into the maximum given width?
			'if so, there is no need for a linebreak/more complex calc.
			If availableW > 0 And _valueDimensionCache.x < availableW
				_valueDimensionCache.SetY(GetFont().getHeight(value))
			'if not, the dimensions are equal to the text block dimensions
			Else
				_valueDimensionCache = GetFont().GetBlockDimension(value, availableW, availableH)
			EndIf

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
		Local oldCol:TColor = New TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()

		Local mode:Int = valueSpriteMode
		Local dim:TVec2D = GetValueDimension()
		Local sprite:TSprite = GetSprite()
		If Not sprite Then mode = MODE_TEXT_ONLY

		Local textH:Int = GetScreenRect().GetH() - 2*contentDisplacement.GetY()
		If GetScreenRect().GetH() < 0 Then textH = -1

		Local textW:Int = GetScreenRect().GetW() - 2*contentDisplacement.GetX()


		Select valueSpriteMode
			Case MODE_SPRITE_LEFT_OF_TEXT
				GetFont().drawBlock(value, GetScreenRect().GetX() + contentDisplacement.GetX() + sprite.GetWidth(), GetScreenRect().GetY() + contentDisplacement.GetY(), textW, textH, contentAlignment, color, valueEffectType, True, valueEffectSpecial, , , ,Null)
				sprite.Draw(GetScreenRect().GetX() + contentDisplacement.GetX(), GetScreenRect().GetY() -1 + contentDisplacement.GetY() + 0.5 * textH, -1, ALIGN_LEFT_CENTER)
			Case MODE_SPRITE_LEFT_OF_TEXT2
				GetFont().drawBlock(value, GetScreenRect().GetX() + contentDisplacement.GetX(), GetScreenRect().GetY() + contentDisplacement.GetY(), textW, textH, contentAlignment, color, valueEffectType, True, valueEffectSpecial, , , , Null)
				sprite.Draw(GetScreenRect().GetX() + contentDisplacement.GetX(), GetScreenRect().GetY() -1 + contentDisplacement.GetY() + 0.5 * textH, -1, ALIGN_LEFT_CENTER)
			Case MODE_SPRITE_LEFT_OF_TEXT3
				GetFont().drawBlock(value, GetScreenRect().GetX() + contentDisplacement.GetX(), GetScreenRect().GetY() + contentDisplacement.GetY(), textW, textH, contentAlignment, color, valueEffectType, True, valueEffectSpecial, , , , Null)
				sprite.Draw(GetScreenRect().GetX() + 0.5 * (GetScreenRect().GetW() - dim.x), GetScreenRect().GetY() -1 + contentDisplacement.GetY() + 0.5 * textH, -1, ALIGN_RIGHT_CENTER)

			Case MODE_SPRITE_RIGHT_OF_TEXT
				Local mydim:TVec2D = New TVec2D
				GetFont().drawBlock(value, GetScreenRect().GetX() + contentDisplacement.GetX(), GetScreenRect().GetY() + contentDisplacement.GetY(), textW - sprite.GetWidth(), textH, contentAlignment, color, valueEffectType, True, valueEffectSpecial, , , , mydim)
				sprite.Draw(GetScreenRect().GetX() + contentDisplacement.GetX() + mydim.X, GetScreenRect().GetY() + contentDisplacement.GetY() + 0.5 * mydim.y)
			Case MODE_SPRITE_RIGHT_OF_TEXT2
				Local mydim:TVec2D = New TVec2D
				GetFont().drawBlock(value, GetScreenRect().GetX() + contentDisplacement.GetX(), GetScreenRect().GetY() + contentDisplacement.GetY(), textW, textH, contentAlignment, color, valueEffectType, True, valueEffectSpecial, , , , mydim)
				sprite.Draw(GetScreenRect().GetX() + contentDisplacement.GetX() + mydim.X, GetScreenRect().GetY() + contentDisplacement.GetY() + 0.5 * mydim.y)

			Case MODE_SPRITE_ABOVE_TEXT
				sprite.Draw(GetScreenRect().GetX() + 0.5 * GetScreenRect().GetW(), GetScreenRect().GetY() + contentDisplacement.GetY(), -1, ALIGN_CENTER_CENTER)
				GetFont().drawBlock(value, GetScreenRect().GetX() + contentDisplacement.GetX() + sprite.GetWidth(), GetScreenRect().GetY() + contentDisplacement.GetY(), textW, textH + sprite.GetHeight(), contentAlignment, color, valueEffectType, True, valueEffectSpecial, , , , Null)

			Case MODE_SPRITE_BELOW_TEXT
				Local mydim:TVec2D = New TVec2D
				GetFont().drawBlock(value, GetScreenRect().GetX() + contentDisplacement.GetX(), GetScreenRect().GetY() + contentDisplacement.GetY(), textW, textH, contentAlignment, color, valueEffectType, True, valueEffectSpecial, , , , mydim)
				sprite.Draw(GetScreenRect().GetX() + 0.5 * GetScreenRect().GetW(), GetScreenRect().GetY() + contentDisplacement.GetY() + mydim.y, -1, ALIGN_CENTER_CENTER)

			Case MODE_SPRITE_ONLY
				sprite.Draw(GetScreenRect().GetX() + 0.5 * GetScreenRect().GetW(), GetScreenRect().GetY() + 0.5 * GetScreenRect().GetH(), -1, ALIGN_CENTER_CENTER)

			Default
				'with alpha<>1.0 we most probably are fading, so we skip
				'caching for now
				if oldCol.a <> 1.0
					GetFont().DrawBlock(value, GetScreenRect().GetX() + contentDisplacement.GetX(), GetScreenRect().GetY() + contentDisplacement.GetY(), textW, textH, contentAlignment, color, valueEffectType, True, valueEffectSpecial, , , , Null)
				else
					textCache.DrawBlock(GetFont(), value, GetScreenRect().GetX() + contentDisplacement.GetX(), GetScreenRect().GetY() + contentDisplacement.GetY(), textW, textH, contentAlignment, color, valueEffectType, True, valueEffectSpecial, , , , Null)
				endif
		End Select


		oldCol.SetRGBA()
	End Method


	Method UpdateLayout()
'		Super.UpdateLayout()
	End Method


	Method onAppearanceChanged:Int()
		_valueDimensionCache = Null

		Return Super.onAppearanceChanged()
	End Method


	'override
	Method OnResize()
		Super.OnResize()
		_valueDimensionCache = Null
	End Method
End Type