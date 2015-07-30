Rem
	====================================================================
	Math helper class
	====================================================================

	Various helpers to work with numbers.


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
Import Brl.Retro



Type MathHelper
	'returns the value if within limits, else the corresponding border
	Function Clamp:Float(value:Float, minValue:Float = 0.0, maxValue:Float = 1.0)
		Return Min(Max(value, minvalue), maxvalue)
	End Function


	Function SortValues(valueA:Float var, valueB:Float var)
		local newValueA:Float = min(valueA, valueB)
		valueB = max(valueA, valueB)
		valueA = newValueA
	End Function

	'for "var" params we need the correct types
	Function SortIntValues(valueA:Int var, valueB:Int var)
		local newValueA:Int = min(valueA, valueB)
		valueB = max(valueA, valueB)
		valueA = newValueA
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


	'returns whether a value between an exclusive range (&gt; &lt;)
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
	Function NumberToString:String(value:Double, digitsAfterDecimalPoint:int = 2, truncateZeros:int = False)
		'RoundNumber() rounds, but does not handle "floating point", so
		'1.5999 gets rounded to 1.6, but then it is stored again as
		'floating point, which recreates "1.5999", that is why we do
		'a similar approach, but do not divide already, instead we move
		'the dot accordingly
		'Local s:String = RoundNumber(value, digitsAfterDecimalPoint + 1)

		if digitsAfterDecimalPoint <= 0 then return RoundLong(value)

		Local t:Long = 10 ^ digitsAfterDecimalPoint
		'after rounding, fill the front of the number with zeros,
		'this avoids "0.001 * 1000" to get "1" (wrong length) but "0001"
		local s:string = Rset(RoundLong(Abs(value) * t), digitsAfterDecimalPoint).Replace(" ", "0")
		'instead of comparing "value" we use the rounded one - a value
		'of "0.000" is sometimes represented using "-2xxxxxxx.xxxx"
		local minus:int = (Double(RoundLong(value) * t) < 0)

		
		'calculate amount of digits before "."
		'instead of just string(int(value))).length we use the "Abs"-value
		'and compare the original value if it is negative
		'- this is needed because "-0.1" would be "0" as int (one char less)
		local lengthBeforeDecimalPoint:int = string(abs(int(value))).length

		'remove unneeded digits (length = BEFORE + . + AFTER)
		if s = "0"
			s = "00"
		else
			s = Left(s, lengthBeforeDecimalPoint + 1 + digitsAfterDecimalPoint)
		endif
		'for numbers below 1.0 we add a zero... 
		if int(s) < t then s = "0"+s

		'move the dot accordingly
		s = s[.. lengthBeforeDecimalPoint] + "." + s[lengthBeforeDecimalPoint .. lengthBeforeDecimalPoint + digitsAfterDecimalPoint]

		'append minus if needed
		if minus then s = "-"+s

		'remove 0s? 1.23000 => 1.23, 1.00 = 1
		if truncateZeros
			while s<>"" and Right(s, 1) = "0"
				s = s[.. s.length-1]
			Wend
			'only "xx." left?
			if Right(s, 1) = "." then s = s[.. s.length-1]
		endif
		

		Return s
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
