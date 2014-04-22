Rem
	===========================================================
	Point Class (3D point)
	===========================================================
End Rem
SuperStrict
Import Brl.Math

Type TPoint {_exposeToLua="selected"}
	Field x:Float = 0
	Field y:Float = 0
	Field z:Float = 0 'depth, >0 is foreground, <0 background


	Method Init:TPoint(_x:Float=0.0,_y:Float=0.0,_z:Float=0.0)
		SetXYZ(_x, _y, _z)
		Return self
	End Method


	Method Copy:TPoint()
		return new TPoint.Init(x, y, z)
	End Method


	Method GetIntX:int() {_exposeToLua}
		return Int(x)
	End Method


	Method GetIntY:int() {_exposeToLua}
		return Int(y)
	End Method


	Method GetIntZ:int() {_exposeToLua}
		return Int(z)
	End Method


	Method GetX:float() {_exposeToLua}
		return x
	End Method


	Method GetY:float() {_exposeToLua}
		return y
	End Method


	Method GetZ:float() {_exposeToLua}
		return z
	End Method


	Method SetX:TPoint(_x:Float)
		x = _x
		return Self
	End Method


	Method SetY:TPoint(_y:Float)
		y = _y
		return Self
	End Method


	Method SetZ:TPoint(_z:Float)
		z = _z
		return Self
	End Method


	Method SetXY:TPoint(_x:Float, _y:Float)
		SetX(_x)
		SetY(_y)
		return Self
	End Method


	Method SetXYZ:TPoint(_x:Float, _y:Float, _z:Float)
		SetX(_x)
		SetY(_y)
		SetZ(_z)
		return Self
	End Method


	Method CopyFrom:Int(otherPoint:TPoint)
		if not otherPoint then return FALSE
		SetXYZ(otherPoint.x, otherPoint.y, otherPoint.z)
	End Method


	Method MoveX:TPoint(_x:float)
		x:+ _x
		return Self
	End Method


	Method MoveY:TPoint(_y:float)
		y:+ _y
		return Self
	End Method


	Method MoveXY:TPoint(_x:float, _y:float)
		x:+ _x
		y:+ _y
		return Self
	End Method


	Method isSame:int(otherPos:TPoint, round:int=FALSE) {_exposeToLua}
		If round
			Return abs(x - otherPos.x) < 1.0 AND abs(y - otherPos.y) < 1.0
		Else
			Return x = otherPos.x AND y = otherPos.y
		Endif
	End Method


	Method DistanceTo:Float(otherPoint:TPoint, withZ:int = True) {_exposeToLua}
		local distanceX:Float = DistanceOfValues(x, otherPoint.x)
		local distanceY:Float = DistanceOfValues(y, otherPoint.y)
		local distanceZ:Float = DistanceOfValues(z, otherPoint.z)

		'a² + b² = c²... pythagoras
		local distanceXY:Float = Sqr(distanceX * distanceX + distanceY * distanceY)

		If withZ and distanceZ <> 0
			'this time a² is the result of the first 2D triangle
			Return Sqr(distanceXY * distanceXY + distanceZ * distanceZ)
		Else
			Return distanceXY
		Endif
	End Method


	Function DistanceOfValues:int(value1:int, value2:int)
		return abs(value1 - value2)
	End Function


	'switches values of given points
	'(switching point references might corrupt references in other objects)
	Function SwitchPoints(pointA:TPoint, pointB:TPoint)
		local tmpPoint:TPoint = pointA.Copy()
		pointA.CopyFrom(pointB)
		pointB.CopyFrom(tmpPoint)
	End Function
End Type