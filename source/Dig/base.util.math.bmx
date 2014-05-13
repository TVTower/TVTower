Rem
	====================================================================
	Math helper class
	====================================================================

	Various helpers to work with numbers.
EndRem
SuperStrict
Import Brl.Retro



Type MathHelper
	'returns the value if within limits, else the corresponding border
	Function Clamp:Float(value:Float, minValue:Float = 0.0, maxValue:Float = 1.0)
		Return Min(Max(value, minvalue), maxvalue)
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
		print Abs(b - a)+ " < " +Max(1E-06 * Max(Abs(a), Abs(b)), 1.121039E-44)
		Return Abs(b - a) < Max(1E-06 * Max(Abs(a), Abs(b)), 1.121039E-44)
	End Function


	'convert a float to a string
	'float is rounded to the requested amount of digits after comma
	Function floatToString:String(value:Float, digitsAfterDecimalPoint:int = 2)
		Local s:String = RoundNumber(value, digitsAfterDecimalPoint + 1)

		'calculate amount of digits before "."
		'instead of just string(int(s))).length we use the "Abs"-value
		'and compare the original value if it is negative
		'- this is needed because "-0.1" would be "0" as int (one char less)
		local lengthBeforeDecimalPoint:int = string(abs(int(s))).length
		if value < 0 then lengthBeforeDecimalPoint:+1 'minus sign
		'remove unneeded digits (length = BEFORE + . + AFTER)
		s = Left(s, lengthBeforeDecimalPoint + 1 + digitsAfterDecimalPoint)

		'add at as much zeros as requested by digitsAfterDecimalPoint
		If s.EndsWith(".")
			for local i:int = 0 until digitsAfterDecimalPoint
				s :+ "0"
			Next
		endif

		Return s
	End Function


	'round to an integer value
	Function RoundInt:Int(f:Double)
		'http://www.blitzbasic.com/Community/posts.php?topic=92064
	    Return f + 0.5 * Sgn(f)
	End Function


	'round a number using weighted non-truncate rounding.
	Function RoundNumber:Double(number:Double, digitsAfterDecimalPoint:Byte = 2)
		Local t:Long = 10 ^ digitsAfterDecimalPoint
		Return RoundInt(number) / Double(t)
	End Function


	Function hex2dec:int(hexString:string)
		return hexString.ToInt()
	End Function
End Type
