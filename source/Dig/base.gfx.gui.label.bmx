Rem
	===========================================================
	GUI Button
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"



Type TGUILabel Extends TGUIobject
	Field contentDisplacement:TPoint = new TPoint.Init(0,0)
	Field color:TColor = TColor.Create(0,0,0)
	Field _valueDimensionCache:TPoint = null

	Global _typeDefaultFont:TBitmapFont


	'will be added to general GuiManager
	'-- use CreateSelfContained to get a unmanaged object
	Method Create:TGUILabel(pos:TPoint, text:String, color:TColor=Null, State:String="")
		Super.CreateBase(pos, null, State)

		'by default labels have left aligned content
		SetContentPosition(ALIGN_LEFT, ALIGN_CENTER)

		Self.SetValue(text)
		If color Then Self.color = color

		GUIManager.Add(Self)
		Return Self
	End Method


	Method SetContentDisplacement:int(displacement:TPoint)
		if displacement then contentDisplacement.CopyFrom(displacement)
	End Method


	Method SetValue:Int(value:string)
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


	Method GetValueDimension:TPoint()
		if not _valueDimensionCache
			_valueDimensionCache = new TPoint
			_valueDimensionCache.SetX(GetFont().getWidth(value))
			_valueDimensionCache.SetY(GetFont().getHeight(value))
		endif
		return _valueDimensionCache
	End Method


	'override to reset cache
	Method onStatusAppearanceChange:int()
		_valueDimensionCache = null
	End Method


	Method Draw:Int()
		GetFont().drawStyled(value, Floor(GetScreenX() + contentPosition.x*(rect.GetW() - GetValueDimension().GetX()) + contentDisplacement.GetX()), Floor(GetScreenY() + contentPosition.y*(rect.GetH() - GetValueDimension().GetY()) + contentDisplacement.GetY()), color, 1)
	End Method
End Type