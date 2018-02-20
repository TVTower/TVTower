Rem
	====================================================================
	Vector Classes (2D + 3D vectors/vecs)
	====================================================================

	Functionality for 2D and 3D vectors.

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
Import Brl.Math

Type TVec2D {_exposeToLua="selected"}
	Field x:Float = 0
	Field y:Float = 0


	Method Init:TVec2D(x:Float=0.0, y:Float=0.0)
		SetXY(x, y)
		Return self
	End Method


	Method ToString:String()
		if string(float(int(x))) = string(x) and string(float(int(y))) = string(y)
			return int(x)+", "+int(y)
		else
			return x+", "+y
		endif
	End Method


	Method ToVec3D:TVec3D()
		return new TVec3D.Init(x, y, 0)
	End Method


	Method Copy:TVec2D()
		return new TVec2D.Init(x, y)
	End Method


	Method GetIntX:int() {_exposeToLua}
		return Int(x)
	End Method


	Method GetIntY:int() {_exposeToLua}
		return Int(y)
	End Method


	Method GetX:Float() {_exposeToLua}
		return x
	End Method


	Method GetY:Float() {_exposeToLua}
		return y
	End Method


	Method SetX:TVec2D(x:Float)
		self.x = x
		return Self
	End Method


	Method SetY:TVec2D(y:Float)
		self.y = y
		return Self
	End Method


	Method SetXY:TVec2D(x:Float, y:Float)
		self.x = x
		self.y = y
		return Self
	End Method


	Method CopyFrom:Int(otherVec:TVec2D)
		if not otherVec then return FALSE
		SetXY(otherVec.x, otherVec.y)
	End Method


	Method CopyFromVec3D:Int(otherVec:TVec3D)
		if not otherVec then return FALSE
		SetXY(otherVec.x, otherVec.y)
	End Method


	Method AddX:TVec2D(x:Float)
		self.x :+ x
		return Self
	End Method


	Method AddY:TVec2D(y:Float)
		self.y :+ y
		return Self
	End Method


	Method AddXY:TVec2D(x:Float, y:Float)
		self.x :+ x
		self.y :+ y
		return Self
	End Method


	Method AddVec:TVec2D(otherVec:TVec2D)
		self.x :+ otherVec.x
		self.y :+ otherVec.y
		return self
	End Method


	Method SubtractXY:TVec2D(x:Float, y:Float)
		self.x :- x
		self.y :- y
		return Self
	End Method


	Method SubtractVec:TVec2D(otherVec:TVec2D)
		self.x :- otherVec.x
		self.y :- otherVec.y
		return self
	End Method


	Method MultiplyFactor:TVec2D(factor:Float)
		self.x :* factor
		self.y :* factor
		return self
	End Method


	Method MultiplyXY:TVec2D(multiplierX:Float, multiplierY:Float)
		self.x :* multiplierX
		self.y :* multiplierY
		return self
	End Method

		
	Method MultiplyVec:TVec2D(otherVec:TVec2D)
		self.x :* otherVec.x
		self.y :* otherVec.y
		return self
	End Method


	Method Divide:TVec2D(scalar:Float)
		if scalar = 0 then return self
		
		self.x :/ scalar
		self.y :/ scalar
		return self
	End Method


	Method GetDotProductXY:Float(x:Float, y:Float)
		return self.x * x + self.y * y
	End Method


	Method GetDotProductVec:Float(otherVec:TVec2D)
		return self.x * otherVec.x + self.y * otherVec.y
	End Method


	Method GetAngle:Float()
		Return ATan2(y, x)
	End Method


	Method GetMagnitude:Float()
		Return Sqr(x * x + y * y)
	End Method


	Method GetAngleDifference:Float(x:Float, y:Float)
		Return Abs(PositiveModulo(ATan2(self.y, self.x) + 180 - ATan2(y, x), 360) - 180)
	End Method


	Method GetAngleDifferenceVec:Float(otherVec:TVec2D)
		Return Abs(PositiveModulo(ATan2(self.y, self.x) + 180 - ATan2(otherVec.y, otherVec.x), 360) - 180)
	End Method


	Method GetReflectedVec:TVec2D(otherVec:TVec2D)
		Local result:TVec2D = copy()
		Local normalVector:TVec2D = GetNormalizedVec()
		Local dotProduct:Float = normalVector.GetDotProductVec(result)
		normalVector.MultiplyXY(2.0 * dotProduct, 2.0 * dotProduct)
		result.SubtractVec(normalVector)

		Return result
	End Method


	Method GetNormalizedVec:TVec2D()
		return copy().Normalize()
	End Method


	Method Normalize:TVec2D()
		Local magnitude:Float = GetMagnitude()
		If magnitude <> 0
			x :/ magnitude
			y :/ magnitude
		End If

		return self
	End Method
		

	Method Rotate:TVec2D(angle:Float)
		local newX:Float = Cos(angle) * x - Sin(angle) * y
		local newY:Float = Sin(angle) * x + Cos(angle) * y
		x = newX
		y = newY

		return self
	End Method


	Method RotateAroundPoint:TVec2D(point:TVec2D, angle:Float)
		local xnew:float = (x - point.x) * cos(angle) - (y - point.y) * sin(angle) + point.x
		local ynew:float = (x - point.x) * sin(angle) + (y - point.y) * cos(angle) + point.y
		x = xnew
		y = ynew
		return self
	End Method

	
	Method isSame:int(otherVec:TVec2D, round:int=FALSE) {_exposeToLua}
		If round
			Return abs(x - otherVec.x) < 1.0 AND abs(y - otherVec.y) < 1.0
		Else
			Return x = otherVec.x AND y = otherVec.y
		Endif
	End Method


	Method DistanceTo:Float(otherVec:TVec2D) {_exposeToLua}
		'a² + b² = c²... pythagoras
		local distanceXY:Float = Sqr((x - othervec.x)^2 + (y - othervec.y)^2)
		Return distanceXY
	End Method


	'switches values of given vecs
	'(switching vec references might corrupt references in other objects)
	Function SwitchVecs(vecA:TVec2D, vecB:TVec2D)
		local tmpVec:TVec2D = vecA.Copy()
		vecA.CopyFrom(vecB)
		vecB.CopyFrom(tmpVec)
	End Function
End Type




Type TVec3D {_exposeToLua="selected"}
	Field x:Float = 0
	Field y:Float = 0
	Field z:Float = 0	'also potential z-index


	Method Init:TVec3D(_x:Float=0.0, _y:Float=0.0, _z:Float=0.0)
		SetXYZ(_x, _y, _z)
		Return self
	End Method


	Method ToString:String()
		if string(int(x)) = string(x) and string(int(y)) = string(y) and string(int(z)) = string(z)
			return int(x)+", "+int(y)+", "+int(z)
		else
			return x+", "+y+", "+z
		endif
	End Method


	Method ToVec2D:TVec2D()
		return new TVec2D.Init(x,y)
	End Method


	Method Copy:TVec3D()
		return new TVec3D.Init(x, y, z)
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


	Method GetX:Float() {_exposeToLua}
		return x
	End Method


	Method GetY:Float() {_exposeToLua}
		return y
	End Method


	Method GetZ:Float() {_exposeToLua}
		return z
	End Method


	Method SetX:TVec3D(_x:Float)
		x = _x
		return Self
	End Method


	Method SetY:TVec3D(_y:Float)
		y = _y
		return Self
	End Method


	Method SetZ:TVec3D(_z:Float)
		z = _z
		return Self
	End Method


	Method SetXY:TVec3D(_x:Float, _y:Float)
		SetX(_x)
		SetY(_y)
		return Self
	End Method


	Method SetXYZ:TVec3D(_x:Float, _y:Float, _z:Float)
		SetX(_x)
		SetY(_y)
		SetZ(_z)
		return Self
	End Method


	Method CopyFrom:Int(otherVec:TVec3D)
		if not otherVec then return FALSE
		SetXYZ(otherVec.x, otherVec.y, otherVec.z)
	End Method


	Method CopyFromVec2D:Int(otherVec:TVec2D)
		if not otherVec then return FALSE
		SetXYZ(otherVec.x, otherVec.y, 0)
	End Method

	Method AddX:TVec3D(x:Float)
		self.x :+ x
		return Self
	End Method


	Method AddY:TVec3D(y:Float)
		self.y :+ y
		return Self
	End Method


	Method AddXY:TVec3D(x:Float, y:Float)
		self.x :+ x
		self.y :+ y
		return Self
	End Method


	Method AddXYZ:TVec3D(x:Float, y:Float, z:Float)
		self.x :+ x
		self.y :+ y
		self.z :+ z
		return Self
	End Method


	Method AddVec:TVec3D(otherVec:TVec3D)
		self.x :+ otherVec.x
		self.y :+ otherVec.y
		self.z :+ otherVec.z
		return self
	End Method


	Method SubtractXYZ:TVec3D(x:Float, y:Float, z:Float)
		self.x :- x
		self.y :- y
		self.z :- z
		return Self
	End Method


	Method SubtractVec:TVec3D(otherVec:TVec3D)
		self.x :- otherVec.x
		self.y :- otherVec.y
		self.z :- otherVec.z
		return self
	End Method


	Method MultiplyFactor:TVec3D(factor:Float)
		self.x :* factor
		self.y :* factor
		self.z :* factor
		return self
	End Method


	Method MultiplyXYZ:TVec3D(multiplierX:Float, multiplierY:Float, multiplierZ:Float)
		self.x :* multiplierX
		self.y :* multiplierY
		self.z :* multiplierZ
		return self
	End Method

		
	Method MultiplyVec:TVec3D(otherVec:TVec3D)
		self.x :* otherVec.x
		self.y :* otherVec.y
		self.z :* otherVec.z
		return self
	End Method


	Method Divide:TVec3D(scalar:Float)
		if scalar = 0 then return self
		
		self.x :/ scalar
		self.y :/ scalar
		self.z :/ scalar
		return self
	End Method


	Method GetDotProductXYZ:Float(x:Float, y:Float, z:Float)
		return self.x * x + self.y * y + self.z * z
	End Method


	Method GetDotProductVec:Float(otherVec:TVec3D)
		return self.x * otherVec.x + self.y * otherVec.y + self.z * otherVec.z
	End Method


	Method GetAngle:Float()
		Return ATan2(y, Sqr(x * x + z * z))
	End Method


	Method GetMagnitude:Float()
		Return Sqr(x * x + y * y + z * z)
	End Method


	Method GetReflectedVec:TVec3D(otherVec:TVec3D)
		Local result:TVec3D = copy()
		Local normalVector:TVec3D = GetNormalizedVec()
		Local dotProduct:Float = normalVector.GetDotProductVec(result)
		normalVector.MultiplyXYZ(2.0 * dotProduct, 2.0 * dotProduct, 2.0 * dotProduct)
		result.SubtractVec(normalVector)

		Return result
	End Method


	Method GetNormalizedVec:TVec3D()
		return copy().Normalize()
	End Method


	Method Normalize:TVec3D()
		Local magnitude:Float = GetMagnitude()
		If magnitude <> 0
			x :/ magnitude
			y :/ magnitude
			z :/ magnitude
		End If

		return Self
	End Method


	Method CrossProductVec:TVec3D(otherVec:TVec3D)
		Local cpx:Float = self.y * otherVec.z - self.z * otherVec.y
		Local cpy:Float = self.z * otherVec.x - self.x * otherVec.z
		Local cpz:Float = self.x * otherVec.y - self.y * otherVec.x
		self.x = cpx
		self.y = cpy
		self.z = cpz

		return Self
	End Method


	Method CrossProductXYZ:TVec3D(x:Float, y:Float, z:Float)
		Local cpx:Float = self.y * z - self.z * y
		Local cpy:Float = self.z * x - self.x * z
		Local cpz:Float = self.x * y - self.y * x
		self.x = cpx
		self.y = cpy
		self.z = cpz

		return Self
	End Method


	Method Rotate2D:TVec3D(angle:Float)
		local newX:Float = Cos(angle) * x - Sin(angle) * y
		local newY:Float = Sin(angle) * x + Cos(angle) * y
		x = newX
		y = newY
		
		return Self
	End Method
				

	Method isSame:int(otherVec:TVec3D, round:int=FALSE) {_exposeToLua}
		If round
			Return abs(x - otherVec.x) < 1.0 AND abs(y - otherVec.y) < 1.0 AND abs(z - otherVec.z) < 1.0
		Else
			Return x = otherVec.x AND y = otherVec.y AND z = otherVec.z
		Endif
	End Method


	Method DistanceTo:Float(otherVec:TVec3D, withZ:int = True) {_exposeToLua}
		local distanceX:Float = abs(x - otherVec.x)
		local distanceY:Float = abs(y - otherVec.y)
		local distanceZ:Float = abs(z - otherVec.z)

		'a² + b² = c²... pythagoras
		local distanceXY:Float = Sqr(distanceX * distanceX + distanceY * distanceY)

		If withZ and distanceZ <> 0
			'this time a² is the result of the first 2D triangle
			Return Sqr(distanceXY * distanceXY + distanceZ * distanceZ)
		Else
			Return distanceXY
		Endif
	End Method


	'switches values of given vecs
	'(switching vec references might corrupt references in other objects)
	Function SwitchVecs(vecA:TVec3D, vecB:TVec3D)
		local tmpVec:TVec3D = vecA.Copy()
		vecA.CopyFrom(vecB)
		vecB.CopyFrom(tmpVec)
	End Function
End Type




Function PositiveModulo:Double(value:Double, modulo:Int)
	value = value mod modulo
	If value < 0 Then value :+ modulo
	Return value
End Function