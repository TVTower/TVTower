Rem
	===========================================================
	GUI Scrollable Panel
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.panel.bmx"




Type TGUIScrollablePanel Extends TGUIPanel
	Field scrollPosition:TVec2D	= new TVec2D.Init(0,0)
	Field scrollLimit:TVec2D	= new TVec2D.Init(0,0)
	Field minSize:TVec2D		= new TVec2D.Init(0,0)


	Method Create:TGUIScrollablePanel(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)
		Self.minSize.SetXY(50,50)

		Return Self
	End Method


	'override resize and add minSize-support
	Method Resize(w:Float = 0, h:Float = 0)
		If w > 0 And w >= minSize.GetX() Then rect.dimension.setX(w)
		If h > 0 And h >= minSize.GetY() Then rect.dimension.setY(h)
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



	Method SetLimits(lx:Float,ly:Float)
		scrollLimit.setXY(lx,ly)
	End Method


	Method ScrollToX:Int(x:Float)
		'check limits
		scrollPosition.SetX(Max(Min(0, x), scrollLimit.GetX()))

		return scrollPosition.GetY()
	End Method


	Method ScrollToY:Int(y:Float)
		'check limits
		scrollPosition.SetY(Max(Min(0, y), scrollLimit.GetY()))

		return scrollPosition.GetY()
	End Method


	Method ScrollTo(x:Float,y:Float)
		ScrollToX(x)
		ScrollToY(y)
	End Method


	Method ScrollBy(dx:Float,dy:Float)
		if dx <> 0 then ScrollToX(scrollPosition.GetX() + dx)
		if dy <> 0 then ScrollToY(scrollPosition.GetY() + dy)
	End Method


	Method GetScrollPercentageX:Float()
		if scrollLimit.GetX() = 0 then return 0
		return Max(0, Min(100, scrollPosition.getX() / scrollLimit.GetX()))
	End Method


	Method GetScrollPercentageY:Float()
		if scrollLimit.GetY() = 0 then return 0
		return Max(0, Min(100, scrollPosition.getY() / scrollLimit.GetY()))
	End Method


	Method SetScrollPercentageX:Float(percentage:float = 0.0)
		percentage = Max(0, Min(100, percentage))
		scrollPosition.SetX( percentage * scrollLimit.GetX() )
		return scrollPosition.GetX()
	End Method


	Method SetScrollPercentageY:Float(percentage:float = 0.0)
		percentage = Max(0, Min(100, percentage))
		scrollPosition.SetY( percentage * scrollLimit.GetY() )
		return scrollPosition.GetY()
	End Method

	


	Method RestrictViewport:Int()
		Local screenRect:TRectangle = Self.GetScreenRect()
		If screenRect
			'disabled by Ronny, 2017/05/16:
			'do IGNORE scrollPosition and just view the original position
			'move viewport by scrolled amount ("virtual displace")
			'GUIManager.RestrictViewport(int(screenRect.getX() - scrollPosition.getX()), int(screenRect.getY() + scrollPosition.getY()), int(screenRect.getW()), int(screenRect.getH()))
			GUIManager.RestrictViewport(int(screenRect.getX()), int(screenRect.getY()), int(screenRect.getW()), int(screenRect.getH()))
			Return True
		Else
			Return False
		EndIf
	End Method

	
	Method DrawDebug()
		SetAlpha 0.3
		SetColor 255,0,0
		DrawRect(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight())
		SetAlpha 0.9
		SetColor 0,255,0
		DrawRect(GetScreenX() + scrollPosition.x + 10, GetScreenY() + scrollPosition.y, GetScreenWidth()/2, 2)
		SetColor 0,0,255
		DrawRect(GetScreenX() + scrollLimit.x, GetScreenY() + scrollLimit.y, GetScreenWidth()/2, 2)
		SetColor 255,255,255
		SetAlpha 1.0
	End Method
End Type