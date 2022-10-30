Rem
	====================================================================
	Rectangle Struct
	====================================================================

	Base rectangle struct including some helper functions.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2020 Ronny Otto, digidea.de

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
Import Brl.Vector


'=== Test ===
rem
local s:SRect = new SRect(0,0,10,10)
'print s.Grow(10).ToString()
print s.Scale(10).ToString()
endrem



'=== IMPLEMENTATION ===
Struct SRectI
	Field ReadOnly x:Int
	Field ReadOnly y:Int
	Field ReadOnly w:Int
	Field ReadOnly h:Int

	Method New(x:Int, y:Int, w:Int, h:Int)
		self.x = x
		self.y = y
		self.w = w
		self.h = h
	End Method


	Function CreateTLBR:SRectI(top:Int, Left:Int, bottom:Int, Right:Int)
		Return new SRectI(top, left, bottom, right)
	End Function


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


	'moves the rectangle by dx,dy
	'returns a new rectangle
	Method Move:SRectI(dx:Int, dy:Int)
		Return new SRectI(self.x + dx, self.y + dy, self.w, self.h)
	End Method


	Method MoveTo:SRectI(position:SVec2I)
		Return new SRectI(position.x, position.y, self.w, self.h)
	End Method

	Method MoveTo:SRectI(x:Int, y:Int)
		Return new SRectI(x, y, self.w, self.h)
	End Method


	Method Resize:SRectI(size:SVec2I)
		Return new SRectI(x, y, size.x, size.y)
	End Method

	Method Resize:SRectI(w:Int, h:Int)
		Return new SRectI(self.x, self.y, w, h)
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


	'returns if the rect overlaps with the given one
	Method Intersects:Int(rect:SRectI)
		'checking if top left or bottom right of the rect
		'is contained in our rect via "containsXY" also returns true
		'for rects next to each other:
		'rectA = 0,0 - 10,10
		'rectB = 10,10 - 20,10
		'-> rectA contains point "10,10"
		'return ( containsXY( rect.GetX(), rect.GetY() ) ..
		'         OR containsXY( rect.GetX() + rect.GetW(),  rect.GetY() + rect.GetH() ) ..
		'       )

		'to avoid this, we use "exclusive" ranges (> instead of >=)
		Return ( x < rect.x + rect.w And y < rect.y + rect.w ) And ..
		       ( x + w > rect.x And y + h > rect.y )
	End Method


	Method Intersects:Int(x:Int, y:Int, w:Int, h:Int)
		Return ( self.x < (x + w) And self.y < (y + h) ) And ..
		       ( self.x + self.w > x And self.y + self.h > y )
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns an "0,0,0,0"-sRectI if there is no intersection
	Method IntersectRect:SRectI(rectB:SRectI)
		Local ix:Int = Max(x, rectB.x)
		Local iy:Int = Max(y, rectB.y)
		Local iw:Int = Min(x + w, rectB.x + rectB.w ) - ix
		Local ih:Int = Min(y + h, rectB.y + rectB.h ) - iy

		If iw > 0 And ih > 0
			Return New SRectI(ix, iy, iw, ih)
		Else
			Return New SRectI()
		EndIf
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns NULL if there is no intersection
	Method IntersectRect:SRectI(x:Int, y:Int, w:Int, h:Int)
		Local ix:Int = Max(self.x, x)
		Local iy:Int = Max(self.y, y)
		Local iw:Int = Min(self.x + self.w, x + w) - ix
		Local ih:Int = Min(self.y + self.h, y + h) - iy

		If iw > 0 And ih > 0
			Return New SRectI(ix, iy, iw, ih)
		Else
			Return New SRectI()
		EndIf
	End Method

	'returns whether x is within the x-coords of the rectangle
	Method ContainsX:Int(x:Int)
		Return (x >= self.x And x <= self.x + self.w)
	End Method


	'returns whether y is within the y-coords of the rectangle
	Method ContainsY:Int(y:Int)
		Return (y >= self.y And y <= self.y + self.h)
	End Method


	'returns whether the rectangle contains the given coord
	Method Contains:Int(x:Int, y:Int)
		Return (    x >= self.x And x < self.x + self.w ..
		        And y >= self.y And y < self.y + self.h ..
		       )
	End Method


	Method Contains:Int(vec:SVec2I)
		Return (    vec.x >= self.x And vec.x < self.x + self.w ..
		        And vec.y >= self.y And vec.y < self.y + self.h ..
		       )
	End Method


	Method Contains:Int(x:Int, y:Int, w:Int, h:Int)
		Return Contains( x, y ) And Contains(x + w, y + h)
	End Method


	Method Contains:Int(rect:SRectI)
		Return Contains(rect.x, rect.y) And Contains(rect.x + rect.w, rect.y + rect.h)
	End Method
End Struct




Struct SRect
	Field ReadOnly x:Float
	Field ReadOnly y:Float
	Field ReadOnly w:Float
	Field ReadOnly h:Float


	'sets the position and dimension (creates new point objects)
	Method New(x:Float, y:Float, w:Float, h:Float)
		self.x = x
		self.y = y
		self.w = w
		self.h = h
	End Method


	Method New(x:Float, y:Float, w:Float, h:Float, round:Int, integerize:Int=True)
		if round
			self.x = Int(x + 0.5)
			self.y = Int(y + 0.5)
			self.w = Int(w + 0.5)
			self.h = Int(h + 0.5)
		elseif integerize
			self.x = Int(x)
			self.y = Int(y)
			self.w = Int(w)
			self.h = Int(h)
		endif
	End Method
	

	Function CreateTLBR:SRect(top:Float, Left:Float, bottom:Float, Right:Float)
		Return new SRect(top, left, bottom, right)
	End Function


	Method ToString:String()
		Return "rect " + x + ", " + y + "  to  " + (x + w)+", " + (y + h) + "  wh=" + w +", " + h
	End Method


	Method SerializeSRectToString:String()
		Local xS:String = x; If Float(Int(x)) = x Then xS = Int(x)
		Local yS:String = y; If Float(Int(y)) = y Then yS = Int(y)
		Local wS:String = w; If Float(Int(w)) = w Then wS = Int(w)
		Local hS:String = h; If Float(Int(h)) = h Then hS = Int(h)
		Return xS+","+yS+","+wS+","+hS
	End Method


	Function DeSerializeSRectFromString:SRect(text:String)
		Local vars:String[] = text.split(",")
		Local x:Float, y:Float, w:Float, h:Float
		If vars.length > 0 Then x = Float(vars[0])
		If vars.length > 1 Then y = Float(vars[1])
		If vars.length > 2 Then w = Float(vars[2])
		If vars.length > 3 Then h = Float(vars[3])
		Return new SRect(x,y,w,h)
	End Function


	'create a new rectangle with the same values
	Method Copy:SRect()
		Return New SRect(x, y, w, h)
	End Method


	'returns if the rect overlaps with the given one
	Method Intersects:Int(rect:SRect)
		'checking if top left or bottom right of the rect
		'is contained in our rect via "containsXY" also returns true
		'for rects next to each other:
		'rectA = 0,0 - 10,10
		'rectB = 10,10 - 20,10
		'-> rectA contains point "10,10"
		'return ( containsXY( rect.GetX(), rect.GetY() ) ..
		'         OR containsXY( rect.GetX() + rect.GetW(),  rect.GetY() + rect.GetH() ) ..
		'       )

		'to avoid this, we use "exclusive" ranges (> instead of >=)
		Return ( x < rect.x + rect.w And y < rect.y + rect.w ) And ..
		       ( x + w > rect.x And y + h > rect.y )
	End Method


	Method Intersects:Int(x:Float, y:Float, w:Float, h:Float)
		Return ( self.x < (x + w) And self.y < (y + h) ) And ..
		       ( self.x + self.w > x And self.y + self.h > y )
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns an "0,0,0,0"-sRect if there is no intersection
	Method IntersectRect:SRect(rectB:SRect)
		Local ix:Float = Max(x, rectB.x)
		Local iy:Float = Max(y, rectB.y)
		Local iw:Float = Min(x + w, rectB.x + rectB.w ) - ix
		Local ih:Float = Min(y + h, rectB.y + rectB.h ) - iy

		If iw > 0 And ih > 0
			Return New SRect(ix, iy, iw, ih)
		Else
			Return New SRect()
		EndIf
	End Method


	'returns a new rectangle describing the intersection of the
	'rectangle and the given one
	'attention: returns NULL if there is no intersection
	Method IntersectRect:SRect(x:Float, y:Float, w:Float, h:Float)
		Local ix:Float = Max(self.x, x)
		Local iy:Float = Max(self.y, y)
		Local iw:Float = Min(self.x + self.w, x + w) - ix
		Local ih:Float = Min(self.y + self.h, y + h) - iy

		If iw > 0 And ih > 0
			Return New SRect(ix, iy, iw, ih)
		Else
			Return New SRect()
		EndIf
	End Method


	'returns whether x is within the x-coords of the rectangle
	Method ContainsX:Int(x:Float)
		Return (x >= self.x And x <= self.x + self.w)
	End Method


	'returns whether y is within the y-coords of the rectangle
	Method ContainsY:Int(y:Float)
		Return (y >= self.y And y <= self.y + self.h)
	End Method


	'returns whether the rectangle contains the given coord
	Method ContainsXY:Int(x:Float, y:Float)
		Return (    x >= self.x And x < self.x + self.w ..
		        And y >= self.y And y < self.y + self.h ..
		       )
	End Method



	Method Contains:Int(vec:SVec2I)
		Return containsXY( vec.x, vec.y )
	End Method


	Method Contains:Int(x:Float, y:Float)
		Return containsXY( x, y )
	End Method


	Method Contains:Int(x:Float, y:Float, w:Float, h:Float)
		Return containsXY( x, y ) And containsXY(x + w, y + h)
	End Method


	Method Contains:Int(rect:SRect)
		Return containsXY(rect.x, rect.y) And containsXY(rect.x + rect.w, rect.y + rect.h)
	End Method


	'for reflection / lua we define custom methods)
	'returns whether the rectangle contains a point
	Method ContainsVec:Int(vec:SVec2f)
		Return containsXY( vec.x, vec.y )
	End Method

	'returns whether the rectangle contains the given rectangle
	Method ContainsRect:Int(rect:SRect)
		Return containsXY(rect.x, rect.y) And containsXY(rect.x + rect.w, rect.y + rect.h)
	End Method

	'returns whether the rectangle contains the given rectangle
	Method ContainsXYWH:Int(x:Float, y:Float, w:Float, h:Float)
		Return containsXY(x, y) And containsXY(x + w, y + h)
	End Method


	'returns as new rectangle resized by the given values
	'(like scaling but with fixed numbers)
	Method Grow:SRect(dx:Float, dy:Float, dw:Float, dh:Float)
		Return new SRect(x - dx, y - dy, w + dw, h + dh)
	End Method

	Method Grow:SRect(v:Float)
		Return new SRect(x - v, y - v, w + v, h + v)
	End Method


	'scale BY a value, center defined in percentage
	Method Scale:SRect(sx:Float, sy:Float, centerX:Float, centerY:Float)
		Return new SRect(x - sx * (1.0 - centerX) * w, ..
		                 y - sy * (1.0 - centerY) * h, ..
		                 w * sx, ..
		                 h * sy  ..
		                )
	End Method

	
	Method Scale:SRect(sx:Float, sy:Float)
		Return new SRect(x - sx * 0.5 * w, ..
		                 y - sy * 0.5 * h, ..
		                 w * sx, ..
		                 h * sy  ..
		                )
	End Method


	Method Scale:SRect(s:Float)
		Return Scale(s, s)
	End Method



	'makes sure that width and height are positive
	Method MakeDimensionsPositive:SRect()
		Local minX:Float = Float( Min(x, x + w) )
		Local maxX:Float = Float( Max(x, x + w) )
		Local minY:Float = Float( Min(y, y + h) )
		Local maxY:Float = Float( Max(y, y + h) )
		Return new SRect(minX, minY, maxX-minX, maxY-minY)
	End Method


	'moves the rectangle by dx,dy
	'returns a new rectangle
	Method Move:SRect(dx:Float, dy:Float)
		Return new SRect(self.x + dx, self.y + dy, self.w, self.h)
	End Method


	Method MoveTo:SRect(position:SVec2f)
		Return new SRect(position.x, position.y, self.w, self.h)
	End Method

	Method MoveTo:SRect(x:Float, y:Float)
		Return new SRect(x, y, self.w, self.h)
	End Method


	Method Resize:SRect(size:SVec2f)
		Return new SRect(x, y, size.x, size.y)
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


	Method GetIntX:Int()
		Return Int(x)
	End Method


	Method GetIntY:Int()
		Return Int(y)
	End Method


	Method GetIntX2:Int()
		Return Int(x) + Int(w)
	End Method
	

	Method GetIntY2:Int()
		Return Int(y) + Int(h)
	End Method


	Method GetIntW:Int()
		Return Int(w)
	End Method


	Method GetIntH:Int()
		Return Int(h)
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


	Method GetCenter:SVec2F()
		Return New SVec2f(x + 0.5*w, y + 0.5*h)
	End Method


	'adjust coordinates/dimension so that the rectangle fits
	'into the given rectangle r
	'sets adjusted to true if values needed to get adjusted
	'(same as "intersect()" but with no negatve values)
	Method LimitedToRect:SRect(r:SRect, adjusted:Int var)
		Local ix:Float = Max(x, r.x)
		Local iy:Float = Max(y, r.y)
		Local iw:Float = Max(0, Min(x + w, r.x + r.w ) - ix)
		Local ih:Float = Max(0, Min(y + h, r.y + r.h ) - iy)

		If x <> ix Or y <> iy Or w <> iw Or h <> ih
			adjusted = True
			Return New SRect(ix, iy, iw, ih)
		EndIf
		adjusted = False
		Return Self
	End Method


	Method Equals:Int(x:Float, y:Float, w:Float, h:Float)
		If self.x <> x Then Return False
		If self.y <> y Then Return False
		If self.w <> w Then Return False
		If self.h <> h Then Return False
		Return True
	End Method

	Method Equals:Int(r:SRect)
		If x <> r.x Then Return False
		If y <> r.y Then Return False
		If w <> r.w Then Return False
		If h <> r.h Then Return False
		Return True
	End Method


	Method EqualsXYWH:Int(x:Float, y:Float, w:Float, h:Float)
		Equals(x,y,w,h)
	End Method


	Method EqualsTLBR:Int(rTop:Float, rLeft:Float, rBottom:Float, rRight:Float)
		If self.x <> rTop Then Return False
		If self.y <> rLeft Then Return False
		If self.x <> rBottom Then Return False
		If self.y <> rRight Then Return False
		Return True
	End Method


	Method EqualsRect:Int(r:SRect)
		Return Equals(r)
	End Method


	Method Compare:Int(other:SRect)
		If other.h * other.w < h*w Then Return -1
		If other.h * other.w > h*w Then Return 1
		Return 0
	End Method
End Struct