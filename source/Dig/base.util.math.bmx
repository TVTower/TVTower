Rem
	====================================================================
	Math helper class
	====================================================================

	Various helpers to work with numbers.


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



Type MathHelper
	'little helpers
	Function _StrLeft:String(str:String, n:Int)
		If n > str.length Then n = str.length
		Return str[.. n]
	End Function


	Function _StrRight:String(str:String, n:Int)
		If n > str.length Then n = str.length
		Return str[str.length-n ..]
	End Function


	Function _StrMid:String(str:String, pos:Int, size:Int = -1)
		If pos > str.length Then Return Null
		pos :- 1
		If size < 0 Then Return str[pos ..]
		If pos < 0
			size :+ pos
			pos = 0
		EndIf
		If pos + size > str.length Then size = str.length - pos
		Return str[pos .. pos + size]
	End Function


	Global asc0:Int = Asc("0")
	Global asc9:Int = Asc("9")
	Global ascZ:Int = Asc("A") - asc9 - 1
	Function Int2Hex:String(i:Int)
		Local buf:Short[8]
		For Local k:Int = 7 To 0 Step -1
			Local n:Int = (i & 15) + asc0
			If n > asc9 Then n:+ ascZ
			buf[k] = n
			i:Shr 4
		Next
		Return String.FromShorts(buf, 8)
	End Function


	'returns the value if within limits, else the corresponding border
	Function Clamp:Float(value:Float, minValue:Float = 0.0, maxValue:Float = 1.0)
		Return Float(Min(Max(value, minvalue), maxvalue))
	End Function


	Function Clamp:Double(value:Double, minValue:Double = 0.0, maxValue:Double = 1.0)
		Return Min(Max(value, minvalue), maxvalue)
	End Function


	Function SortValues(valueA:Float Var, valueB:Float Var)
		If valueB < valueA
			Local tmp:Int = valueB
			valueB = valueA
			valueA = tmp
		EndIf
	End Function

	'for "var" params we need the correct types
	Function SortIntValues(valueA:Int Var, valueB:Int Var)
		If valueB < valueA
			Local tmp:Int = valueB
			valueB = valueA
			valueA = tmp
		EndIf
	End Function

	'returns a linear interpolated value between startValue and endValue
	'the percentage is clamped between 0 and 1 !
	Function Tween:Float(startValue:Float, endValue:Float, percentage:Float = 1.0)
		Return startValue + (endValue - startValue) * Clamp(percentage)
	End Function


	'returns a linear interpolated value between startValue and endValue
	'if the result is less than 0.1 away from endValue, endValue is returned
	'this is done to avoid "shaking" between "short before end" and "end"
	'-> percentage 0.99 vs 1.00
	Function SteadyTween:Float(startValue:Float, endValue:Float, percentage:Float = 1.0)
		Local result:Float = startValue + (endValue - startValue) * Clamp(percentage)
		If Abs(result - endValue) < 0.1 Then Return endValue
		Return result
	End Function


	'returns whether a value is between a range
	Function inInclusiveRange:Int(value:Float, minValue:Float, maxValue:Float )
		Return value >= minValue And value <= maxValue
	End Function


	'returns whether a value between an exclusive range (> <)
	Function inExclusiveRange:Int(value:Float, minValue:Float, maxValue:Float )
		Return value > minValue And value < maxValue
	End Function


	'returns whether a value is even
	Function IsEven:Int(value:Int)
		Return (value Mod 2) = 0
	End Function


	'returns whether a value is odd
	Function IsOdd:Int(value:Int)
		Return (value Mod 2) <> 0
	End Function


	Function GetIntArrayIndex:Int(number:Int, arr:Int[])
		For Local i:Int = 0 Until arr.length
			If arr[i] = number Then Return i
		Next
		Return -1
	End Function


	Function InIntArray:Int(i:Int, intArray:Int[])
		If Not intArray Then Return False

		For Local d:Int = EachIn intArray
			If d = i Then Return True
		Next
		Return False
	End Function


	Function RemoveIntArrayIndex:Int(index:Int, arr:Int[] Var)
		If Not arr Or arr.length = 0 Or index < 0 Or index >= arr.length
			Return -1
		EndIf

		Local result:Int = arr[index]
		If arr.length = 1
			arr = New Int[0]
		Else
			arr = arr[0 .. index] + arr[index+1 .. arr.Length]
		EndIf
		Return result
	End Function


	'returns whether two values are approximately the same
	'(1 and 1.00001 are identical, 1 and 1.1 not)
	Function areApproximatelyEqual:Int(a:Float, b:Float)
		'1E-06 is a value defining at which point things get equal
		'-> 5th digit after comma/point
		'1.121039E-44 is the smallest value
		Return Abs(b - a) < Max(1E-06 * Max(Abs(a), Abs(b)), 1.121039E-44)
		'another possibility is:
		'Return Abs(b - a) < Max(0.000001 * Max(Abs(a), Abs(b)), 2^(-146))
	End Function


	'convert a double to a string
	'double is rounded to the requested amount of digits after comma
	Function NumberToString:String(number:Double, digitsAfterDecimalPoint:Int = 2, truncateZeros:Int = False)
		Local pow:Int = 10
		For Local i:Int = 1 Until digitsAfterDecimalPoint
			pow :* 10
		Next
		'slower than the loop!
		'local pow:int = int(10 ^ digitsAfterDecimalPoint)

		'bring all decimals in front of the dot, add 0.5 to "round"
		'divide "back" the rounded value
		Local tmp:Double = (number * pow + Sgn(number) * 0.5) / pow

		'find dot - and keep "digitsAfterDecimalPoint" numbers afterwards
		Local dotPos:Int = String(Long(tmp)).length  '+1
		If tmp < 0 Then dotPos :+ 1
		Local s:String = String(tmp)[.. dotPos + 1 + digitsAfterDecimalPoint]
		's = _StrLeft(string(tmp), dotPos + 1 + digitsAfterDecimalPoint)

		'remove 0s? 1.23000 => 1.23, 1.00 = 1
		If truncateZeros
			While s<>"" And _StrRight(s, 1) = "0"
				s = s[.. s.length-1]
			Wend
			'only "xx." left?
			If _StrRight(s, 1) = "." Then s = s[.. s.length-1]
		EndIf
		Return s
	End Function


	'formats a given value from "123000,12" to "123.000,12"
	'optimized variant
	Function DottedValue:String(value:Double, thousandsDelimiter:String=".", decimalDelimiter:String=",", digitsAfterDecimalPoint:Int = -1)
		Local result:String
		Local decimalValue:String

		'only process decimals when requested
		If digitsAfterDecimalPoint > 0
			Local stringValues:String[] = String(Abs(value)).Split(".")
			Local fractionalValue:String = ""
			decimalValue = stringValues[0]
			If stringValues.length > 1 Then fractionalValue = stringValues[1]

			'do we even have a fractionalValue <> ".000" ?
			If Long(fractionalValue) > 0
				'not rounded, just truncated
				fractionalValue = _StrLeft(fractionalValue, digitsAfterDecimalPoint)
				result :+ decimalDelimiter + fractionalValue
			EndIf
		Else
			decimalValue = String(Abs(Long(value)))
		EndIf


		For Local i:Int = decimalValue.length-1 To 0 Step -1
			result = Chr(decimalValue[i]) + result

			'every 3rd char, but not if the last one (avoid 100 -> .100)
			If (decimalValue.length-i) Mod 3 = 0 And i > 0
				result = thousandsDelimiter + result
			EndIf
		Next

		'is there a "minus" in front ?
		If value < 0
			Return "-" + result
		Else
			Return result
		EndIf
	End Function


	'round to an integer value
	Function RoundInt:Int(f:Float)
		'http://www.blitzbasic.com/Community/posts.php?topic=92064
	    Return f + 0.5 * Sgn(f)
	End Function


	'round to an Long value
	Function RoundLong:Long(f:Double)
		'http://www.blitzbasic.com/Community/posts.php?topic=92064
	    Return f + 0.5 * Sgn(f)
	End Function


	'round a number using weighted non-truncate rounding.
	Function RoundNumber:Double(number:Double, digitsAfterDecimalPoint:Byte = 2)
		If number = 0 Then Return 0
		Local t:Long = 10 ^ digitsAfterDecimalPoint
		Return RoundLong(number * t) / Double(t)
	End Function


	Function hex2dec:Int(hexString:String)
		Return hexString.ToInt()
	End Function
	
	
	Function EditBitmask:Int(bitmask:int, add:int, remove:int)
		Local result:Int = bitmask
		'add / remove override
		result :| add
		result :& ~remove
		
		Return result
	End Function
End Type
