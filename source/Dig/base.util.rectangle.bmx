Rem
	====================================================================
	Rectangle Class
	====================================================================

	Base rectangle class including some helper functions.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2019 Ronny Otto, digidea.de

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

global rectangle_created:int = 0

Type TRectangle {_exposeToLua="selected"}
	Field position:TVec2D = new TVec2D {_exposeToLua}
	Field dimension:TVec2D = new TVec2D {_exposeToLua}

	Method New()
		rectangle_created :+ 1
	End Method

	'sets the position and dimension (creates new point objects)
	Method Init:TRectangle(x:Float=0, y:Float=0, w:float=0, h:float=0)
		position.SetXY(x, y)
		dimension.SetXY(w, h)
		Return Self
	End Method


	Method ToString:String()
		Return "xy="+position.ToString()+"  wh="+dimension.ToString()
	End Method


'	Method ToIntString:String()
'		return "xy="+position.ToIntString()+"  wh="+dimension.ToIntString()
'	End Method


	Method SerializeTRectangleToString:String()
		Local xS:String = position.x; If Float(Int(position.x)) = position.x Then xS = Int(position.x)
		Local yS:String = position.y; If Float(Int(position.y)) = position.y Then yS = Int(position.y)
		Local wS:String = dimension.x; If Float(Int(dimension.x)) = dimension.x Then wS = Int(dimension.x)
		Local hS:String = dimension.y; If Float(Int(dimension.y)) = dimension.y Then hS = Int(dimension.y)
		Return xS+","+yS+","+wS+","+hS
	End Method


	Method DeSerializeTRectangleFromString(text:String)
		Local vars:String[] = text.split(",")
		If vars.length > 0 Then position.SetX(Float(vars[0]))
		If vars.length > 1 Then position.SetY(Float(vars[1]))
		If vars.length > 2 Then dimension.SetX(Float(vars[2]))
		If vars.length > 3 Then dimension.SetY(Float(vars[3]))
	End Method


	'create a new rectangle with the same values
	Method Copy:TRectangle()
		Return New TRectangle.Init(position.x, position.y, dimension.x, dimension.y)
	End Method


	'copies all values from the given rectangle
	Method CopyFrom:TRectangle(rect:TRectangle)
		If Not rect Then Return Self

		position.copyFrom(rect.position)
		dimension.copyFrom(rect.dimension)
		Return Self
	End Method


	'returns if the rect overlaps with the given one
	Method Intersects:Int(rect:TRectangle) {_exposeToLua}
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
		Return ( GetX() < rect.GetX2() And GetY() < rect.GetY2() ) And ..
		       ( GetX2() > rect.GetX() And GetY2() > rect.GetY() )
	End Method


	Method IntersectsXYWH:int(x:Float, y:Float, w:Float, h:Float) {_exposeToLua}
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
		Return ( GetX() < (x+w) And GetY() < (y+h) ) And ..
		       ( GetX2() > x And GetY2() > y )
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns NULL if there is no intersection
	Method IntersectRect:TRectangle(rectB:TRectangle) {_exposeToLua}
		local ix:float = max(GetX(), rectB.GetX())
		local iy:float = max(GetY(), rectB.GetY())
		local iw:float = min(GetX2(), rectB.GetX2() ) - ix
		local ih:float = min(GetY2(), rectB.GetY2() ) - iy

		If iw > 0 and ih > 0
			Return new TRectangle.Init(ix,iy,iw,ih)
		Else
			Return Null
		EndIf
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns NULL if there is no intersection
	Method IntersectRectXYWH:TRectangle(x:Float, y:Float, w:Float, h:Float) {_exposeToLua}
		local ix:float = max(GetX(), x)
		local iy:float = max(GetY(), y)
		local iw:float = min(GetX2(), x + w) - ix
		local ih:float = min(GetY2(), y + h) - iy

		If iw > 0 and ih > 0
			Return new TRectangle.Init(ix,iy,iw,ih)
		Else
			Return Null
		EndIf
	End Method


	'modifies the rectangle to contain the intersection of self and the
	'given one
	Method Intersect:TRectangle(rectB:TRectangle)
		local ix:float = max(position.x, rectB.position.x)
		local iy:float = max(position.y, rectB.position.y)
		local iw:float = min(position.x + dimension.x, rectB.position.x + rectB.dimension.x ) - ix
		local ih:float = min(position.y + dimension.y, rectB.position.y + rectB.dimension.y ) - iy

		position.x = ix
		position.y = iy
		dimension.x = iw
		dimension.y = ih

		Return Self
	End Method


	'modifies the rectangle to contain the intersection of self and the
	'given one
	Method IntersectXYWH:TRectangle(x:Float, y:Float, w:Float, h:Float)
		local ix:float = max(position.x, x)
		local iy:float = max(position.y, y)
		local iw:float = min(position.x + dimension.x, x + w ) - ix
		local ih:float = min(position.y + dimension.y, y + h ) - iy

		position.x = ix
		position.y = iy
		dimension.x = iw
		dimension.y = ih

		Return Self
	End Method


	?bmxng
	Method Contains:Int(vec:TVec2D)
		Return containsXY( vec.GetX(), vec.GetY() )
	End Method
	?

	'returns whether the rectangle contains a point
	Method ContainsVec:Int(vec:TVec2D) {_exposeToLua}
		Return containsXY( vec.GetX(), vec.GetY() )
	End Method


	'returns whether the rectangle contains the given rectangle
	Method ContainsRect:Int(rect:TRectangle) {_exposeToLua}
		Return containsXY(rect.GetX(), rect.GetY()) And containsXY(rect.GetX2(), rect.GetY2())
	End Method


	'returns whether x is within the x-coords of the rectangle
	Method ContainsX:Int(x:Float) {_exposeToLua}
		Return (x >= GetX() And x <= GetX2())
	End Method


	'returns whether y is within the y-coords of the rectangle
	Method ContainsY:Int(y:Float) {_exposeToLua}
		Return (y >= GetY() And y <= GetY2() )
	End Method


	'returns whether the rectangle contains the given coord
	Method ContainsXY:Int(x:Float, y:Float) {_exposeToLua}
		Return (    x >= GetX() And x < GetX2() ..
		        And y >= GetY() And y < GetY2() ..
		       )
	End Method


	'resizes a rectangle by the given values (like scaling but with
	'fixed numbers)
	Method Grow:TRectangle(dx:Float, dy:Float, dw:Float, dh:Float)
		position.AddXY(-dx, -dy)
		dimension.AddXY(dx + dw, dy + dh)
		Return Self
	End Method


	Method Scale:TRectangle(sx:Float, sy:Float)
		Local centerX:Float = 0.5 * GetW()
		Local centerY:Float = 0.5 * GetH()
		position.AddXY( -(sx - 1.0) * centerX, -(sy - 1.0) * centerY)
		dimension.AddXY( +2*(sx - 1.0) * centerX, +2*(sy - 1.0) * centerY)
		Return Self
	End Method


	'makes sure that width and height are positive
	Method MakeDimensionsPositive:TRectangle()
		Local minX:Float = Float( Min(GetX(), GetX2()) )
		Local maxX:Float = Float( Max(GetX(), GetX2()) )
		Local minY:Float = Float( Min(GetY(), GetY2()) )
		Local maxY:Float = Float( Max(GetY(), GetY2()) )
		SetXYWH(minX, minY, maxX-minX, maxY-minY)
		Return Self
	End Method


	'moves the rectangle to x,y
	Method MoveXY:TRectangle(x:Float, y:Float)
		position.AddXY(x, y)
		Return Self
	End Method


	'Set the rectangles values
	Method SetXYWH:TRectangle(x:Float, y:Float, w:Float, h:Float)
		position.setXY(x,y)
		dimension.setXY(w,h)
		Return Self
	End Method


	Method GetX:Float()
		Return position.GetX()
	End Method


	Method GetY:Float()
		Return position.GetY()
	End Method


	Method GetXCenter:Float()
		Return position.GetX() + 0.5 * dimension.GetX()
	End Method


	Method GetYCenter:Float()
		Return position.GetY() + 0.5 * dimension.GetY()
	End Method


	Method GetX2:Float()
		Return position.GetX() + dimension.GetX()
	End Method


	Method GetY2:Float()
		Return position.GetY() + dimension.GetY()
	End Method


	Method GetW:Float()
		Return dimension.GetX()
	End Method


	Method GetH:Float()
		Return dimension.GetY()
	End Method


	Method GetIntX:Int()
		Return position.GetIntX()
	End Method

	Method GetIntY:Int()
		Return position.GetIntY()
	End Method

	Method GetIntX2:Int()
		Return position.GetIntX() + GetIntW()
	End Method

	Method GetIntY2:Int()
		Return position.GetIntY() + GetIntH()
	End Method

	Method GetIntW:Int()
		Return dimension.GetIntX()
	End Method

	Method GetIntH:Int()
		Return dimension.GetIntY()
	End Method


	'setter when using "sides" insteadsof coords
	Method setTLBR:TRectangle(top:Float, Left:Float, bottom:Float, Right:Float)
		position.setXY(top, Left)
		dimension.setXY(bottom, Right)
		Return Self
	End Method


	Method SetPosition:TRectangle(position:TVec2D)
		Self.position.CopyFrom(position)
		Return Self
	End Method


	Method SetDimension:TRectangle(dimension:TVec2D)
		Self.dimension.CopyFrom(dimension)
		Return Self
	End Method


	Method SetTop:TRectangle(value:Float)
		position.SetX(value)
		Return Self
	End Method


	Method SetLeft:TRectangle(value:Float)
		position.SetY(value)
		Return Self
	End Method


	Method SetBottom:TRectangle(value:Float)
		dimension.SetX(value)
		Return Self
	End Method


	Method SetRight:TRectangle(value:Float)
		dimension.SetY(value)
		Return Self
	End Method


	Method SetX:TRectangle(value:Float)
		position.SetX(value)
		Return Self
	End Method


	Method SetY:TRectangle(value:Float)
		position.SetY(value)
		Return Self
	End Method


	Method SetX2:TRectangle(value:Float)
		dimension.SetX(value - position.x)
		Return Self
	End Method


	Method SetY2:TRectangle(value:Float)
		dimension.SetY(value - position.y)
		Return Self
	End Method


	Method SetXY:TRectangle(valueX:Float, valueY:Float)
		SetX(valueX)
		SetY(valueY)
		Return Self
	End Method


	Method SetWH:TRectangle(valueW:Float, valueH:Float)
		SetW(valueW)
		SetH(valueH)
		Return Self
	End Method


	Method SetW:TRectangle(value:Float)
		dimension.SetX(value)
		Return Self
	End Method


	Method SetH:TRectangle(value:Float)
		dimension.SetY(value)
		Return Self
	End Method


	Method GetTop:Float()
		Return position.GetX()
	End Method


	Method GetLeft:Float()
		Return position.GetY()
	End Method


	Method GetBottom:Float()
		Return dimension.GetX()
	End Method


	Method GetRight:Float()
		Return dimension.GetY()
	End Method


	Method GetAbsoluteCenterVec:TVec2D()
		Return New TVec2D.Init(GetX() + GetW()/2, GetY() + GetH()/2)
	End Method


	Method Round:TRectangle()
		position.x = Int(position.x + 0.5)
		position.y = Int(position.y + 0.5)
		dimension.x = Int(dimension.x + 0.5)
		dimension.y = Int(dimension.y + 0.5)
		Return Self
	End Method


	Method Integerize:TRectangle()
		position.x = Int(position.x)
		position.y = Int(position.y)
		dimension.x = Int(dimension.x)
		dimension.y = Int(dimension.y)
		Return Self
	End Method


	'adjust coordinates/dimension so that the rectangle fits
	'into the given rectangle r
	'returns true if values needed to get adjusted
	'(same as "intersect()" but with return value and no negatve values)
	Method LimitToRect:Int(r:TRectangle)
		local ix:float = max(GetX(), r.GetX())
		local iy:float = max(GetY(), r.GetY())
		local iw:float = Max(0, min(GetX2(), r.GetX2() ) - ix)
		local ih:float = Max(0, min(GetY2(), r.GetY2() ) - iy)

		if position.x <> ix or position.y <> iy or dimension.x <> iw or dimension.y <> ih
			position.x = ix
			position.y = iy
			dimension.x = iw
			dimension.y = ih
			Return True
		EndIf
		Return False
	End Method


	?bmxng
	Method Equals:Int(x:Float, y:Float, w:Float, h:Float)
		Return EqualsXYWH(x,y,w,h)
	End Method

	Method Equals:Int(r:TRectangle)
		Return EqualsRect(r)
	End Method
	?


	Method EqualsXYWH:Int(x:Float, y:Float, w:Float, h:Float)
		If position.x <> x Then Return False
		If position.y <> y Then Return False
		If dimension.x <> w Then Return False
		If dimension.y <> h Then Return False
		Return True
	End Method


	Method EqualsTLBR:Int(rTop:Float, rLeft:Float, rBottom:Float, rRight:Float)
		If position.x <> rTop Then Return False
		If position.y <> rLeft Then Return False
		If dimension.x <> rBottom Then Return False
		If dimension.y <> rRight Then Return False
		Return True
	End Method


	Method EqualsRect:Int(r:TRectangle)
		If position.x <> r.position.x Then Return False
		If position.y <> r.position.y Then Return False
		If dimension.x <> r.dimension.x Then Return False
		If dimension.y <> r.dimension.y Then Return False
		Return True
	End Method


	Method Compare:Int(otherObj:Object)
		Local rect:TRectangle = TRectangle(otherObj)
		If rect
			If rect.dimension.y*rect.dimension.x < dimension.y*dimension.x Then Return -1
			If rect.dimension.y*rect.dimension.x > dimension.y*dimension.x Then Return 1
		EndIf
		Return Super.Compare(otherObj)
	End Method
End Type