Rem
	====================================================================
	Rectangle Class
	====================================================================

	Base rectangle class including some helper functions.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
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


	Method ToString:String()
		return "xy="+position.ToString()+"  wh="+dimension.ToString()
	End Method


'	Method ToIntString:String()
'		return "xy="+position.ToIntString()+"  wh="+dimension.ToIntString()
'	End Method


	Method SerializeTRectangleToString:string()
		local xS:string = position.x; if float(int(position.x)) = position.x then xS = int(position.x)
		local yS:string = position.y; if float(int(position.y)) = position.y then yS = int(position.y)
		local wS:string = dimension.x; if float(int(dimension.x)) = dimension.x then wS = int(dimension.x)
		local hS:string = dimension.y; if float(int(dimension.y)) = dimension.y then hS = int(dimension.y)
		return xS+","+yS+","+wS+","+hS
	End Method


	Method DeSerializeTRectangleFromString(text:String)
		local vars:string[] = text.split(",")
		if vars.length > 0 then position.SetX(float(vars[0]))
		if vars.length > 1 then position.SetY(float(vars[1]))
		if vars.length > 2 then dimension.SetX(float(vars[2]))
		if vars.length > 3 then dimension.SetY(float(vars[3]))
	End Method


	'create a new rectangle with the same values
	Method Copy:TRectangle()
		return new TRectangle.Init(position.x, position.y, dimension.x, dimension.y)
	End Method


	'copies all values from the given rectangle
	Method CopyFrom:TRectangle(rect:TRectangle)
		if not rect then return self

		position.copyFrom(rect.position)
		dimension.copyFrom(rect.dimension)
		return self
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


	?bmxng
	Method Contains:int(vec:TVec2D)
		return containsXY( vec.GetX(), vec.GetY() )
	End Method
	?

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


	'makes sure that width and height are positive
	Method MakeDimensionsPositive:TRectangle()
		local minX:Float = Float( Min(GetX(), GetX2()) )
		local maxX:Float = Float( Max(GetX(), GetX2()) )
		local minY:Float = Float( Min(GetY(), GetY2()) )
		local maxY:Float = Float( Max(GetY(), GetY2()) )
		SetXYWH(minX, minY, maxX-minX, maxY-minY)
		return self
	End Method


	'moves the rectangle to x,y
	Method MoveXY:int(x:float, y:float)
		position.AddXY(x, y)
	End Method


	'Set the rectangles values
	Method SetXYWH(x:float, y:float, w:float, h:float)
		position.setXY(x,y)
		dimension.setXY(w,h)
	End Method


	Method GetX:float()
		return position.GetX()
	End Method


	Method GetY:float()
		return position.GetY()
	End Method


	Method GetXCenter:float()
		return position.GetX() + 0.5 * dimension.GetX()
	End Method


	Method GetYCenter:float()
		return position.GetY() + 0.5 * dimension.GetY()
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


	Method GetIntX:int()
		return position.GetIntX()
	End Method

	Method GetIntY:int()
		return position.GetIntY()
	End Method

	Method GetIntX2:int()
		return position.GetIntX() + GetIntW()
	End Method

	Method GetIntY2:int()
		return position.GetIntY() + GetIntH()
	End Method

	Method GetIntW:int()
		return dimension.GetIntX()
	End Method

	Method GetIntH:int()
		return dimension.GetIntY()
	End Method


	'setter when using "sides" insteadsof coords
	Method setTLBR:TRectangle(top:float, left:float, bottom:float, right:float)
		position.setXY(top, left)
		dimension.setXY(bottom, right)
		return self
	End Method


	Method SetPosition:TRectangle(position:TVec2D)
		self.position.CopyFrom(position)
		return self
	End Method


	Method SetDimension:TRectangle(dimension:TVec2D)
		self.dimension.CopyFrom(dimension)
		return self
	End Method


	Method SetTop:TRectangle(value:float)
		position.SetX(value)
		return self
	End Method


	Method SetLeft:TRectangle(value:float)
		position.SetY(value)
		return self
	End Method


	Method SetBottom:TRectangle(value:float)
		dimension.SetX(value)
		return self
	End Method


	Method SetRight:TRectangle(value:float)
		dimension.SetY(value)
		return self
	End Method


	Method SetX:TRectangle(value:float)
		position.SetX(value)
		return self
	End Method


	Method SetY:TRectangle(value:float)
		position.SetY(value)
		return self
	End Method


	Method SetX2:TRectangle(value:float)
		dimension.SetX(value - position.x)
		return self
	End Method


	Method SetY2:TRectangle(value:float)
		dimension.SetY(value - position.y)
		return self
	End Method


	Method SetXY:TRectangle(valueX:float, valueY:float)
		SetX(valueX)
		SetY(valueY)
		return self
	End Method


	Method SetWH:TRectangle(valueW:float, valueH:float)
		SetW(valueW)
		SetH(valueH)
		return self
	End Method


	Method SetW:TRectangle(value:float)
		dimension.SetX(value)
		return self
	End Method


	Method SetH:TRectangle(value:float)
		dimension.SetY(value)
		return self
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


	Method Round:TRectangle()
		position.x = int(position.x + 0.5)
		position.y = int(position.y + 0.5)
		dimension.x = int(dimension.x + 0.5)
		dimension.y = int(dimension.y + 0.5)
		return self
	End Method


	Method Integerize:TRectangle()
		position.x = int(position.x)
		position.y = int(position.y)
		dimension.x = int(dimension.x)
		dimension.y = int(dimension.y)
		return self
	End Method


	Method Compare:Int(otherObj:Object)
		Local rect:TRectangle = TRectangle(otherObj)
		if rect
			If rect.dimension.y*rect.dimension.x < dimension.y*dimension.x then Return -1
			If rect.dimension.y*rect.dimension.x > dimension.y*dimension.x then Return 1
		endif
		Return Super.Compare(otherObj)
	End Method
End Type