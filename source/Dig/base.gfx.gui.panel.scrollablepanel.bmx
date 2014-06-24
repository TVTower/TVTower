Rem
	===========================================================
	GUI Scrollable Panel
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.panel.bmx"




Type TGUIScrollablePanel Extends TGUIPanel
	Field scrollPosition:TPoint	= new TPoint.Init(0,0)
	Field scrollLimit:TPoint	= new TPoint.Init(0,0)
	Field minSize:TPoint		= new TPoint.Init(0,0)


	Method Create:TGUIScrollablePanel(pos:TPoint, dimension:TPoint, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)
		Self.minSize.SetXY(50,50)

		Return Self
	End Method


	'override resize and add minSize-support
	Method Resize(w:Float=Null,h:Float=Null)
		If w And w >= minSize.GetX() Then rect.dimension.setX(w)
		If h And h >= minSize.GetY() Then rect.dimension.setY(h)

	End Method


	'override getters - to adjust values by scrollposition
	Method GetScreenHeight:Float()
		Return Min(Super.GetScreenHeight(), minSize.getY())
	End Method


	'override getters - to adjust values by scrollposition
	Method GetScreenWidth:Float()
		Return Min(Super.GetScreenWidth(), minSize.getX())
	End Method


	Method GetContentScreenY:Float()
		Return Super.GetContentScreenY() + scrollPosition.getY()
	End Method


	Method GetContentScreenX:Float()
		Return Super.GetContentScreenX() + scrollPosition.getX()
	End Method


	Method ReachedLeftLimit:int()
		return (scrollPosition.GetX() >= 0)
	End Method

	Method ReachedRightLimit:int()
		return (scrollPosition.GetX() <= scrollLimit.GetX())
	End Method

	Method ReachedTopLimit:int()
		return (scrollPosition.GetY() >= 0)
	End Method

	Method ReachedBottomLimit:int()
		return (scrollPosition.GetY() <= scrollLimit.GetY())
	End Method



	Method SetLimits:Int(lx:Float,ly:Float)
		scrollLimit.setXY(lx,ly)
	End Method


	Method Scroll:Int(dx:Float,dy:Float)
		scrollPosition.MoveXY(dx, dy)

		'check limits
		scrollPosition.SetY(Min(0, scrollPosition.GetY()))
		scrollPosition.SetY(Max(scrollPosition.GetY(), scrollLimit.GetY()))

		scrollPosition.SetX(Min(0, scrollPosition.GetX()))
		scrollPosition.SetX(Max(scrollPosition.GetX(), scrollLimit.GetX()))
	End Method


	Method RestrictViewport:Int()
		Local screenRect:TRectangle = Self.GetScreenRect()
		If screenRect
			GUIManager.RestrictViewport(screenRect.getX() - scrollPosition.getX() , screenRect.getY() - scrollPosition.getY(), screenRect.getW(), screenRect.getH())
			Return True
		Else
			Return False
		EndIf
	End Method

Rem
'	Debug drawing
	Method Draw()
		Super.Draw()
		SetAlpha 0.7
		SetColor 255,0,0
		DrawRect(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight())
		SetColor 0,255,0
		DrawRect(GetScreenX() + scrollPosition.x, GetScreenY() + scrollPosition.y, 100, 2)
		SetColor 0,0,255
		DrawRect(GetScreenX() + scrollLimit.x, GetScreenY() + scrollLimit.y, 50, 2)
		SetColor 255,255,255
		SetAlpha 1.0
	End Method
End Rem
End Type