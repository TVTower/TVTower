Rem
	===========================================================
	GUI Button
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"



Type TGUILabel Extends TGUIobject
	Field contentDisplacement:TVec2D = new TVec2D.Init(0,0)
	Field color:TColor = TColor.Create(0,0,0)
	Field valueEffectType:int = 1
	Field valueEffectSpecial:Float = 0.25
	Field _valueDimensionCache:TVec2D = null

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
			_valueDimensionCache = new TVec2D
			_valueDimensionCache.SetX(GetFont().getWidth(value))
			'does the text fit into the maximum given width?
			'if so, there is no need for a linebreak/more complex calc.
			if rect.GetW() > 0 and _valueDimensionCache.x < rect.GetW() 
				_valueDimensionCache.SetY(GetFont().getHeight(value))
			'if not, the dimensions are equal to the text block dimensions
			else
				_valueDimensionCache = GetFont().GetBlockDimension(value, rect.GetW(), rect.GetH())
			endif
		endif
		return _valueDimensionCache
	End Method


	'override to reset cache
	Method onStatusAppearanceChange:int()
		_valueDimensionCache = null
	End Method


	Method DrawContent()
		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()

		GetFont().drawBlock(value, GetScreenX() + contentDisplacement.GetX(), GetScreenY() + contentDisplacement.GetY(), GetScreenWidth() - 2*contentDisplacement.GetX(), GetScreenHeight() - 2*contentDisplacement.GetY(), new TVec2D.Init(contentPosition.x, contentPosition.y), color, valueEffectType, true, valueEffectSpecial)

		oldCol.SetRGBA()
	End Method
End Type