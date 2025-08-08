Rem
	====================================================================
	Rectangle Class
	====================================================================

	Base rectangle class including some helper functions.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2025 Ronny Otto, digidea.de

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
Import "base.util.srectangle.bmx"

global rectangle_created:int = 0


Type TRectangle {_exposeToLua="selected"}
	Field x:Float
	Field y:Float
	Field w:Float
	Field h:Float


	Method New()
		rectangle_created :+ 1
	End Method
	
	
	Method New(x:Float, y:Float, w:float, h:float)
		rectangle_created :+ 1

		self.x = x
		self.y = y
		self.w = w
		self.h = h
	End Method


	'sets the position and dimension (creates new point objects)
	Method Init:TRectangle(x:Float=0, y:Float=0, w:float=0, h:float=0)
		self.x = x
		self.y = y
		self.w = w
		self.h = h

		Return Self
	End Method


	Method ToString:String()
		Return "xy=" + x + "," + y + "  wh=" + w + ", " + h
	End Method


	Method ToSRectI:SRectI()
		Return New SRectI(Int(x),Int(y),Int(w),Int(h))
	End Method


'	Method ToIntString:String()
'		return "xy="+position.ToIntString()+"  wh="+dimension.ToIntString()
'	End Method


	Method SerializeTRectangleToString:String()
		Local xS:String = x; If Float(Int(x)) = x Then xS = Int(x)
		Local yS:String = y; If Float(Int(y)) = y Then yS = Int(y)
		Local wS:String = w; If Float(Int(w)) = w Then wS = Int(w)
		Local hS:String = h; If Float(Int(h)) = h Then hS = Int(h)
		Return xS+","+yS+","+wS+","+hS
	End Method


	Method DeSerializeTRectangleFromString(text:String)
		Local vars:String[] = text.split(",")
		If vars.length > 0 Then x = Float(vars[0])
		If vars.length > 1 Then y = Float(vars[1])
		If vars.length > 2 Then w = Float(vars[2])
		If vars.length > 3 Then h = Float(vars[3])
	End Method


	'create a new rectangle with the same values
	Method Copy:TRectangle()
		Return New TRectangle.Init(x, y, w, h)
	End Method


	'copies all values from the given rectangle
	Method New(rect:SRect)
		self.x = rect.x
		self.y = rect.y
		self.w = rect.w
		self.h = rect.h
	End Method


	'copies all values from the given rectangle
	Method CopyFrom:TRectangle(rect:TRectangle)
		If Not rect Then Return Self

		self.x = rect.x
		self.y = rect.y
		self.w = rect.w
		self.h = rect.h
		Return Self
	End Method


	'copies all values from the given rectangle
	Method CopyFrom:TRectangle(rect:SRect)
		self.x = rect.x
		self.y = rect.y
		self.w = rect.w
		self.h = rect.h
		Return Self
	End Method


	Method SwitchPositions:TRectangle(rect:TRectangle)
		Local oldX:Float = x
		Local oldY:Float = y
		x = rect.x
		y = rect.y
		rect.x = oldX
		rect.y = oldY
		Return self
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
		Return ( x < rect.GetX2() And y < rect.GetY2() ) And ..
		       ( GetX2() > rect.x And GetY2() > rect.y )
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
		Return ( self.x < (x+w) And self.y < (y+h) ) And ..
		       ( GetX2() > x And GetY2() > y )
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns NULL if there is no intersection
	Method IntersectRect:TRectangle(rectB:TRectangle) {_exposeToLua}
		local ix:float = max(x, rectB.x)
		local iy:float = max(y, rectB.y)
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
		local ix:float = max(self.x, x)
		local iy:float = max(self.y, y)
		local iw:float = min(GetX2(), x + w) - ix
		local ih:float = min(GetY2(), y + h) - iy

		If iw > 0 and ih > 0
			Return new TRectangle.Init(ix,iy,iw,ih)
		Else
			Return Null
		EndIf
	End Method


	'returns a new SRect describing the intersection of the
	'rectangle and the given one
	'attention: returns the struct even if there is no intersection
	'           (check width and height on your own!)
	Method IntersectSRectXYWH:SRect(x:Float, y:Float, w:Float, h:Float)
		local ix:float = max(self.x, x)
		local iy:float = max(self.y, y)
		Return new SRect(ix, iy, min(GetX2(), x + w) - ix, min(GetY2(), y + h) - iy)
	End Method


	'modifies the rectangle to contain the intersection of self and the
	'given one
	Method Intersect:TRectangle(rectB:TRectangle)
		local ix:float = max(x, rectB.x)
		local iy:float = max(y, rectB.y)
		local iw:float = min(x + w, rectB.x + rectB.w ) - ix
		local ih:float = min(y + h, rectB.y + rectB.h ) - iy

		x = ix
		y = iy
		w = iw
		h = ih

		Return Self
	End Method


	'modifies the rectangle to contain the intersection of self and the
	'given one
	Method IntersectXYWH:TRectangle(x:Float, y:Float, w:Float, h:Float)
		local ix:float = max(self.x, x)
		local iy:float = max(self.y, y)
		local iw:float = min(self.x + self.w, x + w ) - ix
		local ih:float = min(self.y + self.h, y + h ) - iy

		x = ix
		y = iy
		w = iw
		h = ih

		Return Self
	End Method


	Method Contains:Int(vec:TVec2D)
		Return containsXY( vec.x, vec.y )
	End Method


	'returns whether the rectangle contains a point
	Method ContainsVec:Int(vec:TVec2D) {_exposeToLua}
		Return containsXY( vec.x, vec.y )
	End Method


	'returns whether the rectangle contains the given rectangle
	Method ContainsRect:Int(rect:TRectangle) {_exposeToLua}
		Return containsXY(rect.x, rect.y) And containsXY(rect.GetX2(), rect.GetY2())
	End Method


	'returns whether x is within the x-coords of the rectangle
	Method ContainsX:Int(x:Float) {_exposeToLua}
		Return (x >= self.x And x <= GetX2())
	End Method


	'returns whether y is within the y-coords of the rectangle
	Method ContainsY:Int(y:Float) {_exposeToLua}
		Return (y >= self.y And y <= GetY2() )
	End Method


	'returns whether the rectangle contains the given coord
	Method ContainsXY:Int(x:Float, y:Float) {_exposeToLua}
		Return (    x >= self.x And x < GetX2() ..
		        And y >= self.y And y < GetY2() ..
		       )
	End Method


	'resizes a rectangle by the given values (like scaling but with
	'fixed numbers)
	Method Grow:TRectangle(dx:Float, dy:Float, dw:Float, dh:Float)
		x :+ -dx
		y :+ -dy
		w :+ (dx + dw)
		h :+ (dy + dh)
		Return Self
	End Method


	Method GrowTLBR:TRectangle(top:Float, left:Float, bottom:Float, right:Float)
		x :+ -top
		y :+ -left
		w :+ (left + right)
		h :+ (top + bottom)
		Return Self
	End Method


	Method Scale:TRectangle(sx:Float, sy:Float)
		Local centerX:Float = 0.5 * w
		Local centerY:Float = 0.5 * h
		x :+ -(sx - 1.0) * centerX
		y :+ -(sy - 1.0) * centerY
		w :+ +2*(sx - 1.0) * centerX
		h :+ +2*(sy - 1.0) * centerY
		Return Self
	End Method


	'makes sure that width and height are positive
	Method MakeDimensionsPositive:TRectangle()
		Local minX:Float = Float( Min(x, GetX2()) )
		Local maxX:Float = Float( Max(x, GetX2()) )
		Local minY:Float = Float( Min(y, GetY2()) )
		Local maxY:Float = Float( Max(y, GetY2()) )
		SetXYWH(minX, minY, maxX-minX, maxY-minY)
		Return Self
	End Method


	'moves the rectangle by x,y
	Method MoveXY:TRectangle(dx:Float, dy:Float)
		self.x :+ dx
		self.y :+ dy
		Return Self
	End Method


	'moves the rectangle by x
	Method MoveX:TRectangle(dx:Float)
		self.x :+ dx
		Return Self
	End Method


	'moves the rectangle by x
	Method MoveY:TRectangle(dy:Float)
		self.y :+ dy
		Return Self
	End Method


	Method MoveWH:TRectangle(dw:Float, dh:Float)
		self.w :+ dw
		self.h :+ dh
		Return Self
	End Method


	'adjust the rectangle width by dw
	Method MoveW:TRectangle(dw:Float)
		self.w :+ dw
		Return Self
	End Method


	'adjust the rectangle height by dh
	Method MoveH:TRectangle(dh:Float)
		self.h :+ dh
		Return Self
	End Method


	'Set the rectangles values
	Method SetXYWH:TRectangle(x:Float, y:Float, w:Float, h:Float)
		self.x = x
		self.y = y
		self.w = w
		self.h = h
		Return Self
	End Method
	

	Method GetPosition:SVec2F()
		return new SVec2F(x, y)
	End Method


	Method GetDimension:SVec2F()
		return new SVec2F(w, h)
	End Method


	Method GetX:Float()
		Return x
	End Method


	Method GetY:Float()
		Return y
	End Method


	Method GetXCenter:Float()
		Return x + 0.5 * w
	End Method


	Method GetYCenter:Float()
		Return y + 0.5 * h
	End Method


	Method GetX2:Float()
		Return x + w
	End Method


	Method GetY2:Float()
		Return y + h
	End Method


	Method GetW:Float()
		Return w
	End Method


	Method GetH:Float()
		Return h
	End Method


	Method GetIntX:Int()
		Return Int(x)
	End Method


	Method GetIntY:Int()
		Return Int(y)
	End Method


	Method GetIntX2:Int()
		Return Int(x + w)
	End Method


	Method GetIntY2:Int()
		Return Int(y + h)
	End Method


	Method GetIntW:Int()
		Return Int(w)
	End Method

	Method GetIntH:Int()
		Return Int(h)
	End Method


	'setter when using "sides" insteadsof coords
	Method setTLBR:TRectangle(top:Float, Left:Float, bottom:Float, Right:Float)
		x = top
		y = left
		w = bottom
		h = right
		Return Self
	End Method


	Method SetPosition:TRectangle(position:TVec2D)
		x = position.x
		y = position.y
		Return Self
	End Method


	Method SetDimension:TRectangle(dimension:TVec2D)
		w = dimension.x
		h = dimension.y
		Return Self
	End Method


	Method SetTop:TRectangle(value:Float)
		x = value
		Return Self
	End Method


	Method SetLeft:TRectangle(value:Float)
		y = value
		Return Self
	End Method


	Method SetBottom:TRectangle(value:Float)
		w = value
		Return Self
	End Method


	Method SetRight:TRectangle(value:Float)
		h = value
		Return Self
	End Method


	Method SetX:TRectangle(value:Float)
		x = value
		Return Self
	End Method


	Method SetY:TRectangle(value:Float)
		y = value
		Return Self
	End Method


	Method SetX2:TRectangle(value:Float)
		w = value - x
		Return Self
	End Method


	Method SetY2:TRectangle(value:Float)
		h = value - y
		Return Self
	End Method


	Method SetXY:TRectangle(valueX:Float, valueY:Float)
		x = valueX
		y = valueY
		Return Self
	End Method


	Method SetXY:TRectangle(valueX:Double, valueY:Double)
		x = Float(valueX)
		y = Float(valueY)
		Return Self
	End Method


	Method SetXY:TRectangle(p:SVec2D)
		self.x = p.x
		self.y = p.y
		Return Self
	End Method


	Method SetXY:TRectangle(p:SVec2I)
		self.x = p.x
		self.y = p.y
		Return Self
	End Method


	Method SetXY:TRectangle(p:TVec2D)
		self.x = p.x
		self.y = p.y
		Return Self
	End Method


	Method SetWH:TRectangle(valueW:Float, valueH:Float)
		w = valueW
		h = valueH
		Return Self
	End Method


	Method SetWH:TRectangle(p:TVec2D)
		self.w = p.x
		self.h = p.y
		Return Self
	End Method


	Method SetWH:TRectangle(p:SVec2D)
		self.w = p.x
		self.h = p.y
		Return Self
	End Method


	Method SetW:TRectangle(value:Float)
		w = value
		Return Self
	End Method


	Method SetH:TRectangle(value:Float)
		h = value
		Return Self
	End Method


	Method GetTop:Float()
		Return x
	End Method


	Method GetLeft:Float()
		Return y
	End Method


	Method GetBottom:Float()
		Return w
	End Method


	Method GetRight:Float()
		Return h
	End Method


	Method GetAbsoluteCenterVec:TVec2D()
		Return New TVec2D(x + w/2, y + h/2)
	End Method


	Method GetAbsoluteCenterSVec:SVec2D()
		Return New SVec2D(x + w/2, y + h/2)
	End Method


	Method Round:TRectangle()
		x = Int(x + 0.5)
		y = Int(y + 0.5)
		w = Int(w + 0.5)
		h = Int(h + 0.5)
		Return Self
	End Method


	Method Integerize:TRectangle()
		x = Int(x)
		y = Int(y)
		w = Int(w)
		h = Int(h)
		Return Self
	End Method


	'adjust coordinates/dimension so that the rectangle fits
	'into the given rectangle r
	'returns true if values needed to get adjusted
	'(same as "intersect()" but with return value and no negatve values)
	Method LimitToRect:Int(r:TRectangle)
		local ix:float = max(x, r.x)
		local iy:float = max(y, r.y)
		local iw:float = Max(0, min(GetX2(), r.GetX2() ) - ix)
		local ih:float = Max(0, min(GetY2(), r.GetY2() ) - iy)

		if x <> ix or y <> iy or w <> iw or h <> ih
			x = ix
			y = iy
			w = iw
			h = ih
			Return True
		EndIf
		Return False
	End Method


	Method Equals:Int(x:Float, y:Float, w:Float, h:Float)
		Return EqualsXYWH(x,y,w,h)
	End Method


	Method Equals:Int(r:TRectangle)
		Return EqualsRect(r)
	End Method


	Method EqualsXYWH:Int(x:Float, y:Float, w:Float, h:Float)
		If self.x <> x Then Return False
		If self.y <> y Then Return False
		If self.w <> w Then Return False
		If self.h <> h Then Return False
		Return True
	End Method


	Method EqualsTLBR:Int(rTop:Float, rLeft:Float, rBottom:Float, rRight:Float)
		If self.x <> rTop Then Return False
		If self.y <> rLeft Then Return False
		If self.w <> rBottom Then Return False
		If self.h <> rRight Then Return False
		Return True
	End Method


	Method EqualsRect:Int(r:TRectangle)
		If self.x <> r.x Then Return False
		If self.y <> r.y Then Return False
		If self.w <> r.w Then Return False
		If self.h <> r.h Then Return False
		Return True
	End Method


	Method isSamePosition:int(px:Float, py:Float, round:int=False)
		If round
			Return abs(x - px) < 1.0 AND abs(y - py) < 1.0
		Else
			Return x = px AND y = py
		Endif
	End Method


	Method isSamePosition:int(p:SVec2I, round:int=False)
		If round
			Return abs(x - p.x) < 1.0 AND abs(y - p.y) < 1.0
		Else
			Return x = p.x AND y = p.y
		Endif
	End Method


	Method isSamePosition:int(p:SVec2D, round:int=False)
		If round
			Return abs(x - p.x) < 1.0 AND abs(y - p.y) < 1.0
		Else
			Return x = p.x AND y = p.y
		Endif
	End Method


	Method isSamePosition:int(p:TVec2D, round:int=False) {_exposeToLua}
		If round
			Return abs(x - p.x) < 1.0 AND abs(y - p.y) < 1.0
		Else
			Return x = p.x AND y = p.y
		Endif
	End Method


	Method Compare:Int(otherObj:Object)
		Local rect:TRectangle = TRectangle(otherObj)
		If rect
			If rect.h*rect.w < h*w Then Return -1
			If rect.h*rect.w > h*w Then Return 1
		EndIf
		Return Super.Compare(otherObj)
	End Method
End Type





Type TRectangleI {_exposeToLua="selected"}
	Field x:Int
	Field y:Int
	Field w:Int
	Field h:Int


	Method New(x:Int, y:Int, w:Int, h:Int)
		self.x = x
		self.y = y
		self.w = w
		self.h = h
	End Method


	'sets the position and dimension (creates new point objects)
	Method Init:TRectangleI(x:Int=0, y:Int=0, w:Int=0, h:Int=0)
		self.x = x
		self.y = y
		self.w = w
		self.h = h

		Return Self
	End Method


	'copies all values from the given rectangle
	Method New(rect:SRectI)
		self.x = rect.x
		self.y = rect.y
		self.w = rect.w
		self.h = rect.h
	End Method


	Method ToString:String()
		Return "xy=" + x + "," + y + "  wh=" + w + ", " + h
	End Method


	Method ToSRectI:SRectI()
		Return New SRectI(x,y,w,h)
	End Method


	Method SerializeTRectangleIToString:String()
		Return x + "," + y + "," + w + "," + h
	End Method


	Method DeSerializeTRectangleFromString(text:String)
		Local vars:String[] = text.split(",")
		If vars.length > 0 Then x = Int(vars[0])
		If vars.length > 1 Then y = Int(vars[1])
		If vars.length > 2 Then w = Int(vars[2])
		If vars.length > 3 Then h = Int(vars[3])
	End Method


	'create a new rectangle with the same values
	Method Copy:TRectangleI()
		Return New TRectangleI(x, y, w, h)
	End Method


	'copies all values from the given rectangle
	Method CopyFrom:TRectangleI(rect:TRectangleI)
		If Not rect Then Return Self

		self.x = rect.x
		self.y = rect.y
		self.w = rect.w
		self.h = rect.h
		Return Self
	End Method


	'copies all values from the given rectangle
	Method CopyFrom:TRectangleI(rect:SRectI)
		self.x = rect.x
		self.y = rect.y
		self.w = rect.w
		self.h = rect.h

		Return Self
	End Method


	Method SwitchPositions:TRectangleI(rect:TRectangleI)
		Local oldX:Int = x
		Local oldY:Int = y
		x = rect.x
		y = rect.y
		rect.x = oldX
		rect.y = oldY
		Return self
	End Method


	'returns if the rect overlaps with the given one
	Method Intersects:Int(rect:TRectangleI) {_exposeToLua}
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
		Return ( x < rect.GetX2() And y < rect.GetY2() ) And ..
		       ( GetX2() > rect.x And GetY2() > rect.y )
	End Method


	Method IntersectsXYWH:int(x:Int, y:Int, w:Int, h:Int) {_exposeToLua}
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
		Return ( self.x < (x+w) And self.y < (y+h) ) And ..
		       ( GetX2() > x And GetY2() > y )
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns NULL if there is no intersection
	Method IntersectRect:TRectangleI(rectB:TRectangleI) {_exposeToLua}
		local ix:Int = max(x, rectB.x)
		local iy:Int = max(y, rectB.y)
		local iw:Int = min(GetX2(), rectB.GetX2() ) - ix
		local ih:Int = min(GetY2(), rectB.GetY2() ) - iy

		If iw > 0 and ih > 0
			Return new TRectangleI(ix,iy,iw,ih)
		Else
			Return Null
		EndIf
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns NULL if there is no intersection
	Method IntersectRect:TRectangleI(x:Int, y:Int, w:Int, h:Int) {_exposeToLua}
		local ix:Int = max(self.x, x)
		local iy:Int = max(self.y, y)
		local iw:Int = min(GetX2(), x + w) - ix
		local ih:Int = min(GetY2(), y + h) - iy

		If iw > 0 and ih > 0
			Return new TRectangleI(ix,iy,iw,ih)
		Else
			Return Null
		EndIf
	End Method


	'returns a new SRect describing the intersection of the
	'rectangle and the given one
	'attention: returns the struct even if there is no intersection
	'           (check width and height on your own!)
	Method IntersectSRectIXYWH:SRectI(x:Int, y:Int, w:Int, h:Int)
		local ix:Int = max(self.x, x)
		local iy:Int = max(self.y, y)
		Return new SRectI(ix, iy, min(GetX2(), x + w) - ix, min(GetY2(), y + h) - iy)
	End Method


	'modifies the rectangle to contain the intersection of self and the
	'given one
	Method Intersect:TRectangleI(rectB:TRectangleI)
		local ix:Int = max(x, rectB.x)
		local iy:Int = max(y, rectB.y)
		local iw:Int = min(x + w, rectB.x + rectB.w ) - ix
		local ih:Int = min(y + h, rectB.y + rectB.h ) - iy

		x = ix
		y = iy
		w = iw
		h = ih

		Return Self
	End Method


	'modifies the rectangle to contain the intersection of self and the
	'given one
	Method Intersect:TRectangleI(x:Int, y:Int, w:Int, h:Int)
		local ix:Int = max(self.x, x)
		local iy:Int = max(self.y, y)
		local iw:Int = min(self.x + self.w, x + w ) - ix
		local ih:Int = min(self.y + self.h, y + h ) - iy

		x = ix
		y = iy
		w = iw
		h = ih

		Return Self
	End Method


	Method Contains:Int(vec:TVec2I)
		Return containsXY( vec.x, vec.y )
	End Method

	Method Contains:Int(vec:SVec2I)
		Return containsXY( vec.x, vec.y )
	End Method


	' returns whether the rectangle contains a point
	' additional method for explicit exposing
	Method ContainsVec:Int(vec:TVec2I) {_exposeToLua}
		Return containsXY( vec.x, vec.y )
	End Method


	'returns whether the rectangle contains the given rectangle
	Method ContainsRect:Int(rect:TRectangleI) {_exposeToLua}
		Return containsXY(rect.x, rect.y) And containsXY(rect.GetX2(), rect.GetY2())
	End Method


	'returns whether x is within the x-coords of the rectangle
	Method ContainsX:Int(x:Int) {_exposeToLua}
		Return (x >= self.x And x <= GetX2())
	End Method


	'returns whether y is within the y-coords of the rectangle
	Method ContainsY:Int(y:Int) {_exposeToLua}
		Return (y >= self.y And y <= GetY2() )
	End Method


	'returns whether the rectangle contains the given coord
	Method ContainsXY:Int(x:Int, y:Int) {_exposeToLua}
		Return (    x >= self.x And x < GetX2() ..
		        And y >= self.y And y < GetY2() ..
		       )
	End Method


	'resizes a rectangle by the given values (like scaling but with
	'fixed numbers)
	Method Grow:TRectangleI(dx:Int, dy:Int, dw:Int, dh:Int)
		x :+ -dx
		y :+ -dy
		w :+ (dx + dw)
		h :+ (dy + dh)
		Return Self
	End Method


	Method GrowTLBR:TRectangleI(top:Int, left:Int, bottom:Int, right:Int)
		x :+ -top
		y :+ -left
		w :+ (left + right)
		h :+ (top + bottom)
		Return Self
	End Method


	Method Scale:TRectangleI(sx:Float, sy:Float)
		Local centerX:Float = 0.5 * w
		Local centerY:Float = 0.5 * h
		x = Int(x -(sx - 1.0) * centerX)
		y = Int(y -(sy - 1.0) * centerY)
		w = Int(w +2*(sx - 1.0) * centerX)
		h = Int(h +2*(sy - 1.0) * centerY)
		Return Self
	End Method


	'makes sure that width and height are positive
	Method MakeDimensionsPositive:TRectangleI()
		Local minX:Int = Int( Min(x, GetX2()) )
		Local maxX:Int = Int( Max(x, GetX2()) )
		Local minY:Int = Int( Min(y, GetY2()) )
		Local maxY:Int = Int( Max(y, GetY2()) )
		SetXYWH(minX, minY, maxX-minX, maxY-minY)
		Return Self
	End Method


	'moves the rectangle by x,y
	Method MoveXY:TRectangleI(dx:Int, dy:Int)
		self.x :+ dx
		self.y :+ dy
		Return Self
	End Method


	'moves the rectangle by x
	Method MoveX:TRectangleI(dx:Int)
		self.x :+ dx
		Return Self
	End Method


	'moves the rectangle by x
	Method MoveY:TRectangleI(dy:Int)
		self.y :+ dy
		Return Self
	End Method


	Method MoveWH:TRectangleI(dw:Int, dh:Int)
		self.w :+ dw
		self.h :+ dh
		Return Self
	End Method


	'adjust the rectangle width by dw
	Method MoveW:TRectangleI(dw:Int)
		self.w :+ dw
		Return Self
	End Method


	'adjust the rectangle height by dh
	Method MoveH:TRectangleI(dh:Int)
		self.h :+ dh
		Return Self
	End Method


	'Set the rectangles values
	Method SetXYWH:TRectangleI(x:Int, y:Int, w:Int, h:Int)
		self.x = x
		self.y = y
		self.w = w
		self.h = h
		Return Self
	End Method
	

	Method GetPosition:SVec2I()
		return new SVec2I(x, y)
	End Method


	Method GetDimension:SVec2I()
		return new SVec2I(w, h)
	End Method


	Method GetX:Int()
		Return x
	End Method


	Method GetY:Int()
		Return y
	End Method


	Method GetXCenter:Int()
		Return x + w/2
	End Method


	Method GetYCenter:Int()
		Return y + h/2
	End Method


	Method GetX2:Int()
		Return x + w
	End Method


	Method GetY2:Int()
		Return y + h
	End Method


	Method GetW:Int()
		Return w
	End Method


	Method GetH:Int()
		Return h
	End Method


	'setter when using "sides" insteadsof coords
	Method setTLBR:TRectangleI(top:Int, Left:Int, bottom:Int, Right:Int)
		x = top
		y = left
		w = bottom
		h = right
		Return Self
	End Method


	Method SetPosition:TRectangleI(position:TVec2I)
		x = position.x
		y = position.y
		Return Self
	End Method
	
	Method SetPosition:TRectangleI(position:SVec2I)
		x = position.x
		y = position.y
		Return Self
	End Method


	Method SetDimension:TRectangleI(dimension:TVec2I)
		w = dimension.x
		h = dimension.y
		Return Self
	End Method

	Method SetDimension:TRectangleI(dimension:SVec2I)
		w = dimension.x
		h = dimension.y
		Return Self
	End Method


	Method SetTop:TRectangleI(value:Int)
		x = value
		Return Self
	End Method


	Method SetLeft:TRectangleI(value:Int)
		y = value
		Return Self
	End Method


	Method SetBottom:TRectangleI(value:Int)
		w = value
		Return Self
	End Method


	Method SetRight:TRectangleI(value:Int)
		h = value
		Return Self
	End Method


	Method SetX:TRectangleI(value:Int)
		x = value
		Return Self
	End Method


	Method SetY:TRectangleI(value:Int)
		y = value
		Return Self
	End Method


	Method SetX2:TRectangleI(value:Int)
		w = value - x
		Return Self
	End Method


	Method SetY2:TRectangleI(value:Int)
		h = value - y
		Return Self
	End Method


	Method SetXY:TRectangleI(valueX:Int, valueY:Int)
		x = valueX
		y = valueY
		Return Self
	End Method


	Method SetXY:TRectangleI(p:SVec2I)
		self.x = p.x
		self.y = p.y
		Return Self
	End Method


	Method SetXY:TRectangleI(p:TVec2I)
		self.x = p.x
		self.y = p.y
		Return Self
	End Method


	Method SetWH:TRectangleI(valueW:Int, valueH:Int)
		w = valueW
		h = valueH
		Return Self
	End Method


	Method SetWH:TRectangleI(p:TVec2I)
		self.w = p.x
		self.h = p.y
		Return Self
	End Method


	Method SetWH:TRectangleI(p:SVec2I)
		self.w = p.x
		self.h = p.y
		Return Self
	End Method


	Method SetW:TRectangleI(value:Int)
		w = value
		Return Self
	End Method


	Method SetH:TRectangleI(value:Int)
		h = value
		Return Self
	End Method


	Method GetTop:Int()
		Return x
	End Method


	Method GetLeft:Int()
		Return y
	End Method


	Method GetBottom:Int()
		Return w
	End Method


	Method GetRight:Int()
		Return h
	End Method


	Method GetAbsoluteCenterVec:TVec2I()
		Return New TVec2I(x + w/2, y + h/2)
	End Method


	Method GetAbsoluteCenterSVec:SVec2I()
		Return New SVec2I(x + w/2, y + h/2)
	End Method


	'adjust coordinates/dimension so that the rectangle fits
	'into the given rectangle r
	'returns true if values needed to get adjusted
	'(same as "intersect()" but with return value and no negatve values)
	Method LimitToRect:Int(r:TRectangleI)
		local ix:Int = max(x, r.x)
		local iy:Int = max(y, r.y)
		local iw:Int = Max(0, min(GetX2(), r.GetX2() ) - ix)
		local ih:Int = Max(0, min(GetY2(), r.GetY2() ) - iy)

		if x <> ix or y <> iy or w <> iw or h <> ih
			x = ix
			y = iy
			w = iw
			h = ih
			Return True
		EndIf
		Return False
	End Method


	Method Equals:Int(x:Int, y:Int, w:Int, h:Int)
		Return EqualsXYWH(x,y,w,h)
	End Method


	Method Equals:Int(r:TRectangleI)
		Return EqualsRect(r)
	End Method


	Method EqualsXYWH:Int(x:Int, y:Int, w:Int, h:Int)
		If self.x <> x Then Return False
		If self.y <> y Then Return False
		If self.w <> w Then Return False
		If self.h <> h Then Return False
		Return True
	End Method


	Method EqualsTLBR:Int(rTop:Int, rLeft:Int, rBottom:Int, rRight:Int)
		If self.x <> rTop Then Return False
		If self.y <> rLeft Then Return False
		If self.w <> rBottom Then Return False
		If self.h <> rRight Then Return False
		Return True
	End Method


	Method EqualsRect:Int(r:TRectangleI)
		If self.x <> r.x Then Return False
		If self.y <> r.y Then Return False
		If self.w <> r.w Then Return False
		If self.h <> r.h Then Return False
		Return True
	End Method


	Method isSamePosition:int(px:Int, py:Int)
		Return x = px AND y = py
	End Method


	Method isSamePosition:int(p:SVec2I)
		Return x = p.x AND y = p.y
	End Method


	Method isSamePosition:int(p:TVec2I) {_exposeToLua}
		Return x = p.x AND y = p.y
	End Method


	Method Compare:Int(otherObj:Object)
		Local rect:TRectangleI = TRectangleI(otherObj)
		If rect
			If rect.h*rect.w < h*w Then Return -1
			If rect.h*rect.w > h*w Then Return 1
		EndIf
		Return Super.Compare(otherObj)
	End Method
End Type
