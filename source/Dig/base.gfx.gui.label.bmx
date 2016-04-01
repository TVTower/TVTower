Rem
	===========================================================
	GUI Button
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.util.registry.spriteloader.bmx"



Type TGUILabel Extends TGUIobject
	Field contentDisplacement:TVec2D = new TVec2D.Init(0,0)
	Field color:TColor = TColor.Create(0,0,0)
	Field valueEffectType:int = 1
	Field valueEffectSpecial:Float = 1.0
	Field _valueDimensionCache:TVec2D = null
	Field spriteName:String = ""
	Field _sprite:TSprite 'private
	Field valueSpriteMode:int = 0 'only text

	Const MODE_TEXT_ONLY:int = 0
	Const MODE_SPRITE_ONLY:int = 1
	Const MODE_SPRITE_LEFT_OF_TEXT:int = 2
	Const MODE_SPRITE_RIGHT_OF_TEXT:int = 3
	'variants which get ignored in dimension calculation
	'(they keep text centered in the area)
	Const MODE_SPRITE_LEFT_OF_TEXT2:int = 4
	Const MODE_SPRITE_RIGHT_OF_TEXT2:int = 5
	Const MODE_SPRITE_LEFT_OF_TEXT3:int = 6
	Const MODE_SPRITE_RIGHT_OF_TEXT3:int = 7
	Const MODE_SPRITE_ABOVE_TEXT:int = 8
	Const MODE_SPRITE_BELOW_TEXT:int = 9

	Global _typeDefaultFont:TBitmapFont


	'will be added to general GuiManager
	'-- use CreateSelfContained to get a unmanaged object
	Method Create:TGUILabel(pos:TVec2D, text:String, color:TColor=Null, State:String="")
		Super.CreateBase(pos, null, State)

		'by default labels have left aligned content
		SetContentPosition(ALIGN_LEFT, ALIGN_CENTER)

		Self.SetValue(text)
		If color Then Self.color = color

		GUIManager.Add(Self)
		Return Self
	End Method


	Method SetContentDisplacement:int(displacement:TVec2D)
		if displacement then contentDisplacement.CopyFrom(displacement)
	End Method


	Method SetValueColor:int(color:TColor)
		if color then self.color = color.copy()
	End Method

	
	'override to reset dimension cache
	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w, h)
		_valueDimensionCache = null
	End Method
	

	Method SetValueEffect:int(valueEffectType:Int, valueEffectSpecial:Float = 1.0)
		self.valueEffectType = valueEffectType
		self.valueEffectSpecial = valueEffectSpecial
	End Method


	Method SetValue(value:string)
		Super.SetValue(value)
		'reset cache
		_valueDimensionCache = null
	End Method


	Method SetSpriteName(value:string)
		self.spriteName = value
	End Method


	Method GetSpriteName:String()
		return spriteName
	End Method


	Method SetSprite(sprite:TSprite)
		self._Sprite = sprite
	End Method


	Method GetSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if (not _sprite and spriteName<>"") or (_sprite and _sprite.GetName() <> spriteName)
			_sprite = GetSpriteFromRegistry(spriteName)
			'new -non default- sprite: adjust appearance
			if _sprite.GetName() <> "defaultsprite"
				SetAppearanceChanged(TRUE)
			endif
		endif
		return _sprite
	End Method


	Method SetValueSpriteMode(mode:int)
		valueSpriteMode = mode 
		'reset
		_valueDimensionCache = null
	End Method


	Method SetFont:Int(font:TBitmapFont)
		Super.SetFont(font)
		'reset cache
		_valueDimensionCache = null
	End Method


	Function SetTypeFont:Int(font:TBitmapFont)
		_typeDefaultFont = font
	End Function


	'override in extended classes if wanted
	Function GetTypeFont:TBitmapFont()
		return _typeDefaultFont
	End Function


	Method GetValueDimension:TVec2D()
		if not _valueDimensionCache
			local availableW:int = rect.GetW()
			local availableH:int = rect.GetH()
			local sprite:TSprite = GetSprite()
			'subtract sprite for calculation
			if sprite
				Select valueSpriteMode
					case MODE_SPRITE_ONLY
						_valueDimensionCache = new TVec2D.Init(sprite.GetWidth(), sprite.GetHeight())
					case MODE_SPRITE_LEFT_OF_TEXT, MODE_SPRITE_RIGHT_OF_TEXT
						availableW :- sprite.GetWidth()
					case MODE_SPRITE_ABOVE_TEXT, MODE_SPRITE_BELOW_TEXT
						availableH :- sprite.GetHeight()
				End Select
			endif
						
			_valueDimensionCache = new TVec2D
			_valueDimensionCache.SetX(GetFont().getWidth(value))

			'does the text fit into the maximum given width?
			'if so, there is no need for a linebreak/more complex calc.
			if availableW > 0 and _valueDimensionCache.x < availableW 
				_valueDimensionCache.SetY(GetFont().getHeight(value))
			'if not, the dimensions are equal to the text block dimensions
			else
				_valueDimensionCache = GetFont().GetBlockDimension(value, availableW, availableH)
			endif

			'add back sprite to result
			if sprite
				Select valueSpriteMode
					case MODE_SPRITE_LEFT_OF_TEXT, MODE_SPRITE_RIGHT_OF_TEXT
						_valuedimensionCache.AddX( sprite.GetWidth() )
					case MODE_SPRITE_ABOVE_TEXT, MODE_SPRITE_BELOW_TEXT
						_valuedimensionCache.AddY( sprite.GetHeight() )
				End Select
			endif
		endif
		return _valueDimensionCache
	End Method


	'override to reset cache
	Method onStatusAppearanceChange:int()
		_valueDimensionCache = null
		'if sprite changed we have to resize
		resize(-1, -1)
	End Method


	Method DrawContent()
		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()


		local mode:int = valueSpriteMode
		local dim:TVec2D = GetValueDimension()
		local sprite:TSprite = GetSprite()
		if not sprite then mode = MODE_TEXT_ONLY

		Select valueSpriteMode
			case MODE_SPRITE_LEFT_OF_TEXT
				GetFont().drawBlock(value, GetScreenX() + contentDisplacement.GetX() + sprite.GetWidth(), GetScreenY() + contentDisplacement.GetY(), GetScreenWidth() - 2*contentDisplacement.GetX(), GetScreenHeight() - 2*contentDisplacement.GetY(), contentPosition, color, valueEffectType, true, valueEffectSpecial)
				sprite.Draw(GetScreenX() + contentDisplacement.GetX(), GetScreenY() -1 + contentDisplacement.GetY() + 0.5 * (GetScreenHeight() - 2*contentDisplacement.GetY()), -1, ALIGN_LEFT_CENTER)
			case MODE_SPRITE_LEFT_OF_TEXT2
				local mydim:TVec2D = GetFont().drawBlock(value, GetScreenX() + contentDisplacement.GetX(), GetScreenY() + contentDisplacement.GetY(), GetScreenWidth() - 2*contentDisplacement.GetX(), GetScreenHeight() - 2*contentDisplacement.GetY(), contentPosition, color, valueEffectType, true, valueEffectSpecial)
				sprite.Draw(GetScreenX() + contentDisplacement.GetX(), GetScreenY() -1 + contentDisplacement.GetY() + 0.5 * (GetScreenHeight() - 2*contentDisplacement.GetY()), -1, ALIGN_LEFT_CENTER)
			case MODE_SPRITE_LEFT_OF_TEXT3
				local mydim:TVec2D = GetFont().drawBlock(value, GetScreenX() + contentDisplacement.GetX(), GetScreenY() + contentDisplacement.GetY(), GetScreenWidth() - 2*contentDisplacement.GetX(), GetScreenHeight() - 2*contentDisplacement.GetY(), contentPosition, color, valueEffectType, true, valueEffectSpecial)
				sprite.Draw(GetScreenX() + 0.5 * (GetScreenWidth() - dim.x), GetScreenY() -1 + contentDisplacement.GetY() + 0.5 * (GetScreenHeight() - 2*contentDisplacement.GetY()), -1, ALIGN_RIGHT_CENTER)

			case MODE_SPRITE_RIGHT_OF_TEXT
				local mydim:TVec2D = GetFont().drawBlock(value, GetScreenX() + contentDisplacement.GetX(), GetScreenY() + contentDisplacement.GetY(), GetScreenWidth() - 2*contentDisplacement.GetX() - sprite.GetWidth(), GetScreenHeight() - 2*contentDisplacement.GetY(), contentPosition, color, valueEffectType, true, valueEffectSpecial)
				sprite.Draw(GetScreenX() + contentDisplacement.GetX() + mydim.X, GetScreenY() + contentDisplacement.GetY() + 0.5 * mydim.y)
			case MODE_SPRITE_RIGHT_OF_TEXT2
				local mydim:TVec2D = GetFont().drawBlock(value, GetScreenX() + contentDisplacement.GetX(), GetScreenY() + contentDisplacement.GetY(), GetScreenWidth() - 2*contentDisplacement.GetX(), GetScreenHeight() - 2*contentDisplacement.GetY(), contentPosition, color, valueEffectType, true, valueEffectSpecial)
				sprite.Draw(GetScreenX() + contentDisplacement.GetX() + mydim.X, GetScreenY() + contentDisplacement.GetY() + 0.5 * mydim.y)

			case MODE_SPRITE_ABOVE_TEXT
				sprite.Draw(GetScreenX() + 0.5 * GetScreenWidth(), GetScreenY() + contentDisplacement.GetY(), -1, ALIGN_CENTER_CENTER)
				GetFont().drawBlock(value, GetScreenX() + contentDisplacement.GetX() + sprite.GetWidth(), GetScreenY() + contentDisplacement.GetY(), GetScreenWidth() - 2*contentDisplacement.GetX(), GetScreenHeight() - 2*contentDisplacement.GetY() + sprite.GetHeight(), contentPosition, color, valueEffectType, true, valueEffectSpecial)

			case MODE_SPRITE_BELOW_TEXT
				local dim:TVec2D = GetFont().drawBlock(value, GetScreenX() + contentDisplacement.GetX(), GetScreenY() + contentDisplacement.GetY(), GetScreenWidth() - 2*contentDisplacement.GetX(), GetScreenHeight() - 2*contentDisplacement.GetY(), contentPosition, color, valueEffectType, true, valueEffectSpecial)
				sprite.Draw(GetScreenX() + 0.5 * GetScreenWidth(), GetScreenY() + contentDisplacement.GetY() + dim.y, -1, ALIGN_CENTER_CENTER)

			case MODE_SPRITE_ONLY
				sprite.Draw(GetScreenX() + 0.5 * GetScreenWidth(), GetScreenY() + 0.5 * GetScreenHeight(), -1, ALIGN_CENTER_CENTER)

			default
				GetFont().drawBlock(value, GetScreenX() + contentDisplacement.GetX(), GetScreenY() + contentDisplacement.GetY(), GetScreenWidth() - 2*contentDisplacement.GetX(), GetScreenHeight() - 2*contentDisplacement.GetY(), contentPosition, color, valueEffectType, true, valueEffectSpecial)
		End Select


		oldCol.SetRGBA()
	End Method
End Type