Rem
	====================================================================
	Vector Classes (2D + 3D vectors/vecs)
	====================================================================

	Functionality for 2D and 3D vectors.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2022 Ronny Otto, digidea.de

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
Import Math.Vector

Global vec2d_created:Int = 0
Type TVec2D {_exposeToLua="selected"}
	Field x:Float = 0
	Field y:Float = 0

	Method New()
		vec2d_created :+ 1
	End Method


	Method New(x:Float, y:Float)
		vec2d_created :+ 1

		Self.x = x
		Self.y = y
	End Method


	Method New(p:SVec2F)
		vec2d_created :+ 1

		Self.x = p.x
		Self.y = p.y
	End Method


	Method ToString:String()
		If String(Float(Int(x))) = String(x) And String(Float(Int(y))) = String(y)
			Return Int(x)+", "+Int(y)
		Else
			Return x+", "+y
		EndIf
	End Method


	Method ToVec3D:TVec3D()
		Return New TVec3D.Init(x, y, 0)
	End Method


	Method Copy:TVec2D()
		Return New TVec2D(x, y)
	End Method


	Method GetIntX:Int() {_exposeToLua}
		Return Int(x)
	End Method


	Method GetIntY:Int() {_exposeToLua}
		Return Int(y)
	End Method


	Method GetX:Float() {_exposeToLua}
		Return x
	End Method


	Method GetY:Float() {_exposeToLua}
		Return y
	End Method


	Method SetX:TVec2D(x:Float)
		Self.x = x
		Return Self
	End Method


	Method SetY:TVec2D(y:Float)
		Self.y = y
		Return Self
	End Method


	Method SetXY:TVec2D(x:Float, y:Float)
		Self.x = x
		Self.y = y
		Return Self
	End Method


	Method CopyFrom:TVec2D(otherVec:TVec2D)
		If otherVec
			SetXY(otherVec.x, otherVec.y)
		EndIf
		Return Self
	End Method


	Method CopyFrom:TVec2D(otherVec:SVec2D)
		SetXY(Float(otherVec.x), Float(otherVec.y))
		Return Self
	End Method


	Method CopyFrom:TVec2D(otherVec:SVec2F)
		SetXY(otherVec.x, otherVec.y)
		Return Self
	End Method


	Method CopyFrom:TVec2D(otherVec:SVec2I)
		SetXY(otherVec.x, otherVec.y)
		Return Self
	End Method


	Method CopyFromVec3D:TVec2D(otherVec:TVec3D)
		If otherVec
			SetXY(otherVec.x, otherVec.y)
		EndIf
		Return Self
	End Method


	Method AddX:TVec2D(x:Float)
		Self.x :+ x
		Return Self
	End Method


	Method AddY:TVec2D(y:Float)
		Self.y :+ y
		Return Self
	End Method


	Method AddXY:TVec2D(x:Float, y:Float)
		Self.x :+ x
		Self.y :+ y
		Return Self
	End Method


	Method AddVec:TVec2D(otherVec:TVec2D)
		Self.x :+ otherVec.x
		Self.y :+ otherVec.y
		Return Self
	End Method


	Method SubtractXY:TVec2D(x:Float, y:Float)
		Self.x :- x
		Self.y :- y
		Return Self
	End Method


	Method SubtractVec:TVec2D(otherVec:TVec2D)
		Self.x :- otherVec.x
		Self.y :- otherVec.y
		Return Self
	End Method


	Method MultiplyFactor:TVec2D(factor:Float)
		Self.x :* factor
		Self.y :* factor
		Return Self
	End Method


	Method MultiplyXY:TVec2D(multiplierX:Float, multiplierY:Float)
		Self.x :* multiplierX
		Self.y :* multiplierY
		Return Self
	End Method


	Method MultiplyVec:TVec2D(otherVec:TVec2D)
		Self.x :* otherVec.x
		Self.y :* otherVec.y
		Return Self
	End Method


	Method Divide:TVec2D(scalar:Float)
		If scalar = 0 Then Return Self

		Self.x :/ scalar
		Self.y :/ scalar
		Return Self
	End Method


	Method GetDotProductXY:Float(x:Float, y:Float)
		Return Self.x * x + Self.y * y
	End Method


	Method GetDotProductVec:Float(otherVec:TVec2D)
		Return Self.x * otherVec.x + Self.y * otherVec.y
	End Method


	Method GetAngle:Float()
		Return ATan2(y, x)
	End Method


	Method GetMagnitude:Float()
		Return Sqr(x * x + y * y)
	End Method


	Method GetAngleDifference:Float(x:Float, y:Float)
		Return Abs(PositiveModulo(ATan2(Self.y, Self.x) + 180 - ATan2(y, x), 360) - 180)
	End Method


	Method GetAngleDifferenceVec:Float(otherVec:TVec2D)
		Return Abs(PositiveModulo(ATan2(Self.y, Self.x) + 180 - ATan2(otherVec.y, otherVec.x), 360) - 180)
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
		Return copy().Normalize()
	End Method


	Method Normalize:TVec2D()
		Local magnitude:Float = GetMagnitude()
		If magnitude <> 0
			x :/ magnitude
			y :/ magnitude
		End If

		Return Self
	End Method


	Method Rotate:TVec2D(angle:Float)
		Local newX:Float = Cos(angle) * x - Sin(angle) * y
		Local newY:Float = Sin(angle) * x + Cos(angle) * y
		x = newX
		y = newY

		Return Self
	End Method


	Method RotateAroundPoint:TVec2D(point:TVec2D, angle:Float)
		Local xnew:Float = (x - point.x) * Cos(angle) - (y - point.y) * Sin(angle) + point.x
		Local ynew:Float = (x - point.x) * Sin(angle) + (y - point.y) * Cos(angle) + point.y
		x = xnew
		y = ynew
		Return Self
	End Method


	Method isSame:Int(otherVec:TVec2D, Round:Int=False) {_exposeToLua}
		If Not otherVec Then Return False

		If Round
			Return Abs(x - otherVec.x) < 1.0 And Abs(y - otherVec.y) < 1.0
		Else
			Return x = otherVec.x And y = otherVec.y
		EndIf
	End Method


	Method isSame:Int(otherVec:SVec2I, Round:Int=False) {_exposeToLua}
		If Not otherVec Then Return False

		If Round
			Return Abs(x - otherVec.x) < 1.0 And Abs(y - otherVec.y) < 1.0
		Else
			Return x = otherVec.x And y = otherVec.y
		EndIf
	End Method


	Method EqualsXY:Int(x:Float, y:Float, Round:Int=False)
		If Round
			Return Abs(Self.x - x) < 1.0 And Abs(Self.y - y) < 1.0
		Else
			Return Self.x = x And Self.y = y
		EndIf
	End Method

	Method DistanceTo:Float(otherVec:TVec2D) {_exposeToLua}
		'a² + b² = c²... pythagoras
		Local distanceXY:Float = Sqr((x - othervec.x)^2 + (y - othervec.y)^2)
		Return distanceXY
	End Method


	'switches values of given vecs
	'(switching vec references might corrupt references in other objects)
	Function SwitchVecs(vecA:TVec2D, vecB:TVec2D)
		Local tmpVec:TVec2D = vecA.Copy()
		vecA.CopyFrom(vecB)
		vecB.CopyFrom(tmpVec)
	End Function
End Type




Type TVec2I {_exposeToLua="selected"}
	Field x:Int = 0
	Field y:Int = 0

	Method New(x:Int, y:Int)
		SetXY(x, y)
	End Method
	

	Method New(s:SVec2I)
		SetXY(s.x, s.y)
	End Method


	Method ToString:String()
		Return Int(x)+", "+Int(y)
	End Method


	Method ToVec3D:TVec3D()
		Return New TVec3D.Init(x, y, 0)
	End Method


	Method Copy:TVec2I()
		Return New TVec2I(x, y)
	End Method


	Method GetX:Int() {_exposeToLua}
		Return x
	End Method


	Method GetY:Int() {_exposeToLua}
		Return y
	End Method


	Method SetX:TVec2I(x:Int)
		Self.x = x
		Return Self
	End Method


	Method SetY:TVec2I(y:Int)
		Self.y = y
		Return Self
	End Method


	Method SetXY:TVec2I(x:Float, y:Float)
		Self.x = x
		Self.y = y
		Return Self
	End Method


	Method CopyFrom:TVec2I(otherVec:SVec2I)
		SetXY(otherVec.x, otherVec.y)
		Return Self
	End Method


	Method CopyFrom:TVec2I(otherVec:TVec2I)
		If otherVec
			SetXY(otherVec.x, otherVec.y)
		EndIf
		Return Self
	End Method


	Method CopyFrom:TVec2I(otherVec:TVec2D, mathRound:Int = True)
		If otherVec
			If mathRound
				SetXY(Int(otherVec.x + 0.5), Int(otherVec.y + 0.5))
			Else
				SetXY(Int(otherVec.x), Int(otherVec.y))
			EndIf
		EndIf
		Return Self
	End Method


	Method CopyFrom:TVec2I(otherVec:TVec3D, mathRound:Int = True)
		If otherVec
			If mathRound
				SetXY(Int(otherVec.x + 0.5), Int(otherVec.y + 0.5))
			Else
				SetXY(Int(otherVec.x), Int(otherVec.y))
			EndIf
		EndIf
		Return Self
	End Method


	Method AddX:TVec2I(x:Int)
		Self.x :+ x
		Return Self
	End Method


	Method AddY:TVec2I(y:Int)
		Self.y :+ y
		Return Self
	End Method


	Method AddXY:TVec2I(x:Int, y:Int)
		Self.x :+ x
		Self.y :+ y
		Return Self
	End Method


	Method AddVec:TVec2I(otherVec:TVec2I)
		Self.x :+ otherVec.x
		Self.y :+ otherVec.y
		Return Self
	End Method


	Method SubtractXY:TVec2I(x:Float, y:Float)
		Self.x :- x
		Self.y :- y
		Return Self
	End Method


	Method SubtractVec:TVec2I(otherVec:TVec2I)
		Self.x :- otherVec.x
		Self.y :- otherVec.y
		Return Self
	End Method


	Method MultiplyFactor:TVec2I(factor:Float)
		Self.x = Int(Self.x * factor + 0.5)
		Self.y = Int(Self.y * factor + 0.5)
		Return Self
	End Method


	Method MultiplyXY:TVec2I(multiplierX:Float, multiplierY:Float)
		Self.x = Int(Self.x * multiplierX + 0.5)
		Self.y = Int(Self.y * multiplierY + 0.5)
		Return Self
	End Method


	Method MultiplyVec:TVec2I(otherVec:TVec2I)
		Self.x :* otherVec.x
		Self.y :* otherVec.y
		Return Self
	End Method


	Method Divide:TVec2I(scalar:Float)
		If scalar = 0 Then Return Self

		Self.x = Int(Self.x / scalar + 0.5)
		Self.y = Int(Self.y / scalar + 0.5)
		Return Self
	End Method


	Method GetDotProductXY:Int(x:Int, y:Int)
		Return Self.x * x + Self.y * y
	End Method


	Method GetDotProduct:Int(otherVec:TVec2I)
		Return Self.x * otherVec.x + Self.y * otherVec.y
	End Method


	Method GetAngle:Float()
		Return ATan2(y, x)
	End Method


	Method GetMagnitude:Float()
		Return Sqr(x * x + y * y)
	End Method


	Method GetAngleDifference:Float(x:Float, y:Float)
		Return Abs(PositiveModulo(ATan2(Self.y, Self.x) + 180 - ATan2(y, x), 360) - 180)
	End Method


	Method GetAngleDifference:Float(otherVec:TVec2I)
		Return Abs(PositiveModulo(ATan2(Self.y, Self.x) + 180 - ATan2(otherVec.y, otherVec.x), 360) - 180)
	End Method


	Method GetReflectedVec:TVec2I(otherVec:TVec2I)
		Local result:TVec2I = copy()
		Local normalVector:TVec2I = GetNormalizedVec()
		Local dotProduct:Float = normalVector.GetDotProduct(result)
		normalVector.MultiplyXY(2 * dotProduct, 2 * dotProduct)
		result.SubtractVec(normalVector)

		Return result
	End Method


	Method GetNormalizedVec:TVec2I()
		Return copy().Normalize()
	End Method


	Method Normalize:TVec2I()
		Local magnitude:Float = GetMagnitude()
		If magnitude <> 0
			x = Int(x / magnitude + 0.5)
			y = Int(y / magnitude + 0.5)
		End If

		Return Self
	End Method


	Method Rotate:TVec2I(angle:Float)
		Local newX:Float = Cos(angle) * x - Sin(angle) * y
		Local newY:Float = Sin(angle) * x + Cos(angle) * y
		x = Int(newX + 0.5)
		y = Int(newY + 0.5)

		Return Self
	End Method


	Method RotateAroundPoint:TVec2I(point:TVec2I, angle:Float)
		Local xnew:Float = (x - point.x) * Cos(angle) - (y - point.y) * Sin(angle) + point.x
		Local ynew:Float = (x - point.x) * Sin(angle) + (y - point.y) * Cos(angle) + point.y
		x = Int(xnew + 0.5)
		y = Int(ynew + 0.5)
		Return Self
	End Method


	Method isSame:Int(otherVec:TVec2I) {_exposeToLua}
		If Not otherVec Then Return False

		Return x = otherVec.x And y = otherVec.y
	End Method


	Method EqualsXY:Int(x:Int, y:Int) {_exposeToLua}
		Return Self.x = x And Self.y = y
	End Method


	Method DistanceTo:Float(otherVec:TVec2I) {_exposeToLua}
		'a² + b² = c²... pythagoras
		Local distanceXY:Float = Sqr((x - othervec.x)^2 + (y - othervec.y)^2)
		Return distanceXY
	End Method


	'switches values of given vecs
	'(switching vec references might corrupt references in other objects)
	Function SwitchVecs(vecA:TVec2I, vecB:TVec2I)
		Local tmpVec:TVec2I = vecA.Copy()
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
		Return Self
	End Method


	Method ToString:String()
		If String(Int(x)) = String(x) And String(Int(y)) = String(y) And String(Int(z)) = String(z)
			Return Int(x)+", "+Int(y)+", "+Int(z)
		Else
			Return x+", "+y+", "+z
		EndIf
	End Method


	Method ToVec2D:TVec2D()
		Return New TVec2D(x,y)
	End Method


	Method Copy:TVec3D()
		Return New TVec3D.Init(x, y, z)
	End Method


	Method GetIntX:Int() {_exposeToLua}
		Return Int(x)
	End Method


	Method GetIntY:Int() {_exposeToLua}
		Return Int(y)
	End Method


	Method GetIntZ:Int() {_exposeToLua}
		Return Int(z)
	End Method


	Method GetX:Float() {_exposeToLua}
		Return x
	End Method


	Method GetY:Float() {_exposeToLua}
		Return y
	End Method


	Method GetZ:Float() {_exposeToLua}
		Return z
	End Method


	Method SetX:TVec3D(_x:Float)
		x = _x
		Return Self
	End Method


	Method SetY:TVec3D(_y:Float)
		y = _y
		Return Self
	End Method


	Method SetZ:TVec3D(_z:Float)
		z = _z
		Return Self
	End Method


	Method SetXY:TVec3D(_x:Float, _y:Float)
		SetX(_x)
		SetY(_y)
		Return Self
	End Method


	Method SetXYZ:TVec3D(_x:Float, _y:Float, _z:Float)
		SetX(_x)
		SetY(_y)
		SetZ(_z)
		Return Self
	End Method


	Method CopyFrom:Int(otherVec:TVec3D)
		If Not otherVec Then Return False
		SetXYZ(otherVec.x, otherVec.y, otherVec.z)
	End Method


	Method CopyFromVec2D:Int(otherVec:TVec2D)
		If Not otherVec Then Return False
		SetXYZ(otherVec.x, otherVec.y, 0)
	End Method

	Method AddX:TVec3D(x:Float)
		Self.x :+ x
		Return Self
	End Method


	Method AddY:TVec3D(y:Float)
		Self.y :+ y
		Return Self
	End Method


	Method AddXY:TVec3D(x:Float, y:Float)
		Self.x :+ x
		Self.y :+ y
		Return Self
	End Method


	Method AddXYZ:TVec3D(x:Float, y:Float, z:Float)
		Self.x :+ x
		Self.y :+ y
		Self.z :+ z
		Return Self
	End Method


	Method AddVec:TVec3D(otherVec:TVec3D)
		Self.x :+ otherVec.x
		Self.y :+ otherVec.y
		Self.z :+ otherVec.z
		Return Self
	End Method


	Method SubtractXYZ:TVec3D(x:Float, y:Float, z:Float)
		Self.x :- x
		Self.y :- y
		Self.z :- z
		Return Self
	End Method


	Method SubtractVec:TVec3D(otherVec:TVec3D)
		Self.x :- otherVec.x
		Self.y :- otherVec.y
		Self.z :- otherVec.z
		Return Self
	End Method


	Method MultiplyFactor:TVec3D(factor:Float)
		Self.x :* factor
		Self.y :* factor
		Self.z :* factor
		Return Self
	End Method


	Method MultiplyXYZ:TVec3D(multiplierX:Float, multiplierY:Float, multiplierZ:Float)
		Self.x :* multiplierX
		Self.y :* multiplierY
		Self.z :* multiplierZ
		Return Self
	End Method


	Method MultiplyVec:TVec3D(otherVec:TVec3D)
		Self.x :* otherVec.x
		Self.y :* otherVec.y
		Self.z :* otherVec.z
		Return Self
	End Method


	Method Divide:TVec3D(scalar:Float)
		If scalar = 0 Then Return Self

		Self.x :/ scalar
		Self.y :/ scalar
		Self.z :/ scalar
		Return Self
	End Method


	Method GetDotProductXYZ:Float(x:Float, y:Float, z:Float)
		Return Self.x * x + Self.y * y + Self.z * z
	End Method


	Method GetDotProductVec:Float(otherVec:TVec3D)
		Return Self.x * otherVec.x + Self.y * otherVec.y + Self.z * otherVec.z
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
		Return copy().Normalize()
	End Method


	Method Normalize:TVec3D()
		Local magnitude:Float = GetMagnitude()
		If magnitude <> 0
			x :/ magnitude
			y :/ magnitude
			z :/ magnitude
		End If

		Return Self
	End Method


	Method CrossProductVec:TVec3D(otherVec:TVec3D)
		Local cpx:Float = Self.y * otherVec.z - Self.z * otherVec.y
		Local cpy:Float = Self.z * otherVec.x - Self.x * otherVec.z
		Local cpz:Float = Self.x * otherVec.y - Self.y * otherVec.x
		Self.x = cpx
		Self.y = cpy
		Self.z = cpz

		Return Self
	End Method


	Method CrossProductXYZ:TVec3D(x:Float, y:Float, z:Float)
		Local cpx:Float = Self.y * z - Self.z * y
		Local cpy:Float = Self.z * x - Self.x * z
		Local cpz:Float = Self.x * y - Self.y * x
		Self.x = cpx
		Self.y = cpy
		Self.z = cpz

		Return Self
	End Method


	Method Rotate2D:TVec3D(angle:Float)
		Local newX:Float = Cos(angle) * x - Sin(angle) * y
		Local newY:Float = Sin(angle) * x + Cos(angle) * y
		x = newX
		y = newY

		Return Self
	End Method


	Method isSame:Int(otherVec:TVec3D, Round:Int=False) {_exposeToLua}
		If Round
			Return Abs(x - otherVec.x) < 1.0 And Abs(y - otherVec.y) < 1.0 And Abs(z - otherVec.z) < 1.0
		Else
			Return x = otherVec.x And y = otherVec.y And z = otherVec.z
		EndIf
	End Method


	Method DistanceTo:Float(otherVec:TVec3D, withZ:Int = True) {_exposeToLua}
		Local distanceX:Float = Abs(x - otherVec.x)
		Local distanceY:Float = Abs(y - otherVec.y)
		Local distanceZ:Float = Abs(z - otherVec.z)

		'a² + b² = c²... pythagoras
		Local distanceXY:Float = Sqr(distanceX * distanceX + distanceY * distanceY)

		If withZ And distanceZ <> 0
			'this time a² is the result of the first 2D triangle
			Return Sqr(distanceXY * distanceXY + distanceZ * distanceZ)
		Else
			Return distanceXY
		EndIf
	End Method


	'switches values of given vecs
	'(switching vec references might corrupt references in other objects)
	Function SwitchVecs(vecA:TVec3D, vecB:TVec3D)
		Local tmpVec:TVec3D = vecA.Copy()
		vecA.CopyFrom(vecB)
		vecB.CopyFrom(tmpVec)
	End Function
End Type




Function PositiveModulo:Double(value:Double, modulo:Int)
	value = value Mod modulo
	If value < 0 Then value :+ modulo
	Return value
End Function