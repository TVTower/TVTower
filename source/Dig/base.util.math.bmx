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
	Function _StrLeft:string(str:string, n:int)
		If n > str.length then n = str.length
		Return str[.. n]
	End Function


	Function _StrRight:string(str:string, n:int)
		If n > str.length then n = str.length
		Return str[str.length-n ..]
	End Function


	Function _StrMid:string(str:string, pos:int, size:int = -1)
		If pos > str.length then Return Null
		pos :- 1
		If size < 0 then Return str[pos ..]
		If pos < 0
			size :+ pos
			pos = 0
		endif
		If pos + size > str.length then size = str.length - pos
		Return str[pos .. pos + size]
	End Function


	global asc0:int = Asc("0")
	global asc9:int = Asc("9")
	global ascZ:int = Asc("A") - asc9 - 1
	Function Int2Hex:String(i:int)
		Local buf:Short[8]
		For Local k:int = 7 To 0 Step -1
			Local n:int = (i & 15) + asc0
			If n > asc9 then n:+ ascZ
			buf[k] = n
			i:Shr 4
		Next
		Return String.FromShorts(buf, 8)
	End Function


	'returns the value if within limits, else the corresponding border
	Function Clamp:Float(value:Float, minValue:Float = 0.0, maxValue:Float = 1.0)
		Return Min(Max(value, minvalue), maxvalue)
	End Function


	Function SortValues(valueA:Float var, valueB:Float var)
		if valueB < valueA
			local tmp:int = valueB
			valueB = valueA
			valueA = tmp
		endif
	End Function

	'for "var" params we need the correct types
	Function SortIntValues(valueA:Int var, valueB:Int var)
		if valueB < valueA
			local tmp:int = valueB
			valueB = valueA
			valueA = tmp
		endif
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
		local result:Float = startValue + (endValue - startValue) * Clamp(percentage)
		if Abs(result - endValue) < 0.1 then return endValue
		return result
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
		Return (value mod 2) = 0
	End Function


	'returns whether a value is odd
	Function IsOdd:Int(value:Int)
		Return (value mod 2) <> 0
	End Function


	Function InIntArray:int(i:int, intArray:int[])
		if not intArray then return False

		For local d:Int = EachIn intArray
			if d = i then return True
		Next
		return False
	End Function


	Function RemoveIntArrayIndex:int(index:int, arr:int[] var)
		if not arr or arr.length = 0 or index < 0 or index >= arr.length
			return -1
		endif

		local result:int = arr[index]
		if arr.length = 1
			arr = new Int[0]
		else
			arr = arr[0 .. index] + arr[index+1 .. arr.Length]
		endif
		return result
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
	Function NumberToString:string(number:Double, digitsAfterDecimalPoint:int = 2, truncateZeros:int = False)
		local pow:int = 10
		For local i:int = 1 until digitsAfterDecimalPoint
			pow :* 10
		Next
		'slower than the loop!
		'local pow:int = int(10 ^ digitsAfterDecimalPoint)

		'bring all decimals in front of the dot, add 0.5 to "round"
		'divide "back" the rounded value
		local tmp:double = (number * pow + sgn(number) * 0.5) / pow

		'find dot - and keep "digitsAfterDecimalPoint" numbers afterwards
		local dotPos:int = string(long(tmp)).length  '+1
		if tmp < 0 then dotPos :+ 1
		local s:string = string(tmp)[.. dotPos + 1 + digitsAfterDecimalPoint]
		's = _StrLeft(string(tmp), dotPos + 1 + digitsAfterDecimalPoint)

		'remove 0s? 1.23000 => 1.23, 1.00 = 1
		if truncateZeros
			while s<>"" and _StrRight(s, 1) = "0"
				s = s[.. s.length-1]
			Wend
			'only "xx." left?
			if _StrRight(s, 1) = "." then s = s[.. s.length-1]
		endif
		return s
	End Function


	'formats a given value from "123000,12" to "123.000,12"
	'optimized variant
	Function DottedValue:String(value:Double, thousandsDelimiter:String=".", decimalDelimiter:String=",", digitsAfterDecimalPoint:int = -1)
		'is there a "minus" in front ?
		Local addSign:Int = value < 0
		Local result:String
		Local decimalValue:string

		'only process decimals when requested
		if digitsAfterDecimalPoint > 0 and 1=2
			Local stringValues:String[] = String(Abs(value)).Split(".")
			Local fractionalValue:String = ""
			decimalValue = stringValues[0]
			if stringValues.length > 1 then fractionalValue = stringValues[1]

			'do we even have a fractionalValue <> ".000" ?
			if Long(fractionalValue) > 0
				'not rounded, just truncated
				fractionalValue = _StrLeft(fractionalValue, digitsAfterDecimalPoint)
				result :+ decimalDelimiter + fractionalValue
			endif
		else
			decimalValue = String(Abs(Long(value)))
		endif


		For Local i:Int = decimalValue.length-1 To 0 Step -1
			result = Chr(decimalValue[i]) + result

			'every 3rd char, but not if the last one (avoid 100 -> .100)
			If (decimalValue.length-i) Mod 3 = 0 And i > 0
				result = thousandsDelimiter + result
			EndIf
		Next

		if addSign
			Return "-" + result
		else
			Return result
		endif
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
		if number = 0 then return 0
		Local t:Long = 10 ^ digitsAfterDecimalPoint
		Return RoundLong(number * t) / Double(t)
	End Function


	Function hex2dec:int(hexString:string)
		return hexString.ToInt()
	End Function
End Type
