Rem
	===========================================================
	GUI Scrollable Panel
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.panel.bmx"




Type TGUIScrollablePanel Extends TGUIPanel
	Field scrollPosition:TVec2D	= new TVec2D(0,0)
	Field scrollLimit:TVec2D	= new TVec2D(0,0)
	Field minSize:TVec2D		= new TVec2D(0,0)


	Method GetClassName:String()
		Return "tguiscrollablepanel"
	End Method


	Method Create:TGUIScrollablePanel(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)
		Self.minSize.SetXY(50,50)

		Return Self
	End Method


	'override SetSize and add minSize-support
	Method SetSize(w:Float = 0, h:Float = 0)
		if w < minSize.getX() then w = -1
		if h < minSize.getY() then h = -1
		Super.SetSize(w, h)
	End Method


	'override getters - to adjust values by scrollposition
	Method _UpdateScreenH:Float()
		_screenRect.SetH( Min(Super._UpdateScreenH(), minSize.getY()) )
		Return _screenRect.GetH()
	End Method

	'override getters - to adjust values by scrollposition
	Method _UpdateScreenW:Float()
		_screenRect.SetW( Min(Super._UpdateScreenW(), minSize.getX()) )
		Return _screenRect.GetW()
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
		local newY:Float = Max(Min(0, y), scrollLimit.GetY())

		if scrollPosition.GetY() <> newY
			scrollPosition.SetY(Max(Min(0, y), scrollLimit.GetY()))
		endif
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
		return Max(0, Min(100, 100 * scrollPosition.getX() / scrollLimit.GetX())) / 100.0
	End Method


	Method GetScrollPercentageY:Float()
		if scrollLimit.GetY() = 0 then return 0
		return Max(0, Min(100, 100 * scrollPosition.getY() / scrollLimit.GetY())) / 100.0
	End Method


	Method SetScrollPercentageX:Float(percentage:float = 0.0)
		percentage = Max(0, Min(100, percentage * 100)) / 100.0
		scrollPosition.SetX( percentage * scrollLimit.GetX() )
		return scrollPosition.GetX()
	End Method


	Method SetScrollPercentageY:Float(percentage:float = 0.0)
		percentage = Max(0, Min(100, percentage * 100)) / 100.0

		scrollPosition.SetY( percentage * scrollLimit.GetY() )
		return scrollPosition.GetY()
	End Method
	
	
	Method DrawOverlay() override
		Super.DrawOverlay()
'		DrawDebug()
	End Method


	Method DrawDebug()
		GetGraphicsManager().ResetViewport()
		SetAlpha 0.3
		SetColor 255,255,0
		DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH())
'		SetColor 255,0,255
'		DrawRect(GetContentScreenRect().GetX(), GetContentScreenRect().GetY(), GetContentScreenRect().GetW(), GetContentScreenRect().GetH())
		SetAlpha 0.9
		SetColor 0,255,0
		DrawRect(GetScreenRect().GetX() + scrollPosition.x, GetScreenRect().GetY() + scrollPosition.y, GetScreenRect().GetW(), 2)
		SetColor 0,0,255
		DrawRect(GetScreenRect().GetX() + scrollLimit.x, GetScreenRect().GetY() + scrollLimit.y, GetScreenRect().GetW(), 2)
		SetColor 255,255,255
		SetAlpha 1.0
	End Method


	Method UpdateLayout()
	End Method
End Type
