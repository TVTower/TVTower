Rem
	===========================================================
	Rectangle Class
	===========================================================

	Base rectangle class including some helper functions.
End Rem
SuperStrict
Import "base.util.vector.bmx"


Type TRectangle {_exposeToLua="selected"}
	Field position:TVec2D = new TVec2D {_exposeToLua}
	Field dimension:TVec2D = new TVec2D {_exposeToLua}
	'global helper variables should be faster than allocating locals each time (in huge amount)
	global ix:float,iy:float,iw:float,ih:float


	'sets the position and dimension (creates new point objects)
	Method Init:TRectangle(x:Float=0, y:Float=0, w:float=0, h:float=0)
		position.SetXY(x, y)
		dimension.SetXY(w, h)
		return self
	End Method


	'create a new rectangle with the same values
	Method Copy:TRectangle()
		return new TRectangle.Init(position.x, position.y, dimension.x, dimension.y)
	End Method


	'copies all values from the given rectangle
	Method CopyFrom:Int(rect:TRectangle)
		if not rect then return False

		position.copyFrom(rect.position)
		dimension.copyFrom(rect.dimension)
		return True
	End Method


	'returns if the rect overlaps with the given one
	Method Intersects:int(rect:TRectangle) {_exposeToLua}
		'checking if topleft or bottomright of the rect
		'is contained in our rect via "containsXY" also returns true
		'for rects next to each other:
		'rectA = 0,0 - 10,10
		'rectB = 10,10 - 20,10
		'-> rectA contains point "10,10"
		'return ( containsXY( rect.GetX(), rect.GetY() ) ..
		'         OR containsXY( rect.GetX() + rect.GetW(),  rect.GetY() + rect.GetH() ) ..
		'       )

		'to avoid this, we use "exclusive" ranges (> instead of >=)
		Return ( GetX() < rect.GetX2() AND GetY() < rect.GetY2() ) AND ..
		       ( GetX2() > rect.GetX() AND GetY2() > rect.GetY() )
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns NULL if there is no intersection
	Method IntersectRect:TRectangle(rectB:TRectangle) {_exposeToLua}
		ix = max(GetX(), rectB.GetX())
		iy = max(GetY(), rectB.GetY())
		iw = min(GetX2(), rectB.GetX2() ) - ix
		ih = min(GetY2(), rectB.GetY2() ) - iy

		local intersect:TRectangle = new TRectangle.Init(ix,iy,iw,ih)

		if iw > 0 AND ih > 0 then return intersect
		return Null
	End Method


	'modifies the rectangle to contain the intersection of self and the
	'given one
	Method Intersect:TRectangle(rectB:TRectangle)
		ix = max(GetX(), rectB.GetX())
		iy = max(GetY(), rectB.GetY())
		iw = min(GetX2(), rectB.GetX2() ) - ix
		ih = min(GetY2(), rectB.GetY2() ) - iy

		position.x = ix
		position.y = iy
		dimension.x = iw
		dimension.y = ih

		return self
	End Method


	'returns whether the rectangle contains a point
	Method ContainsVec:int(vec:TVec2D) {_exposeToLua}
		return containsXY( vec.GetX(), vec.GetY() )
	End Method


	'returns whether the rectangle contains the given rectangle
	Method ContainsRect:int(rect:TRectangle) {_exposeToLua}
		return containsXY(rect.GetX(), rect.GetY()) And containsXY(rect.GetX2(), rect.GetY2())
	End Method


	'returns whether x is within the x-coords of the rectangle
	Method ContainsX:int(x:float) {_exposeToLua}
		return (x >= GetX() And x <= GetX2())
	End Method


	'returns whether y is within the y-coords of the rectangle
	Method ContainsY:int(y:float) {_exposeToLua}
		return (y >= GetY() And y <= GetY2() )
	End Method


	'returns whether the rectangle contains the given coord
	Method ContainsXY:int(x:float, y:float) {_exposeToLua}
		return (    x >= GetX() And x < GetX2() ..
		        And y >= GetY() And y < GetY2() ..
		       )
	End Method


	'resizes a rectangle by the given values (like scaling but with
	'fixed numbers)
	Method Grow:TRectangle(dx:Float, dy:Float, dw:Float, dh:Float)
		position.AddXY(-dx, -dy)
		dimension.AddXY(dx + dw, dy + dh)
		return self
	End Method


	Method Scale:TRectangle(sx:Float, sy:Float)
		local centerX:Float = 0.5 * GetW()
		local centerY:Float = 0.5 * GetH()
		position.AddXY( -(sx - 1.0) * centerX, -(sy - 1.0) * centerY)
		dimension.AddXY( +2*(sx - 1.0) * centerX, +2*(sy - 1.0) * centerY)
		return self
	End Method


	'moves the rectangle to x,y
	Method MoveXY:int(x:float, y:float)
		position.AddXY(x, y)
	End Method


	'Set the rectangles values
	Method setXYWH(x:float, y:float, w:float, h:float)
		position.setXY(x,y)
		dimension.setXY(w,h)
	End Method


	Method GetX:float()
		return position.GetX()
	End Method


	Method GetY:float()
		return position.GetY()
	End Method


	Method GetX2:float()
		return position.GetX() + dimension.GetX()
	End Method


	Method GetY2:float()
		return position.GetY() + dimension.GetY()
	End Method


	Method GetW:float()
		return dimension.GetX()
	End Method


	Method GetH:float()
		return dimension.GetY()
	End Method


	'setter when using "sides" insteadsof coords
	Method setTLBR(top:float, left:float, bottom:float, right:float)
		position.setXY(top, left)
		dimension.setXY(bottom, right)
	End Method


	Method SetTop:int(value:float)
		position.SetX(value)
	End Method


	Method SetLeft:int(value:float)
		position.SetY(value)
	End Method


	Method SetBottom:int(value:float)
		dimension.SetX(value)
	End Method


	Method SetRight:int(value:float)
		dimension.SetY(value)
	End Method


	Method GetTop:float()
		return position.GetX()
	End Method


	Method GetLeft:float()
		return position.GetY()
	End Method


	Method GetBottom:float()
		return dimension.GetX()
	End Method


	Method GetRight:float()
		return dimension.GetY()
	End Method


	Method GetAbsoluteCenterVec:TVec2D()
		return new TVec2D.Init(GetX() + GetW()/2, GetY() + GetH()/2)
	End Method


	Method Compare:Int(otherObj:Object)
		Local rect:TRectangle = TRectangle(otherObj)
		If rect.dimension.y*rect.dimension.x < dimension.y*dimension.x then Return -1
		If rect.dimension.y*rect.dimension.x > dimension.y*dimension.x then Return 1
		Return 0
	End Method
End Type