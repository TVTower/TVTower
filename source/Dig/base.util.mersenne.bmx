SuperStrict
Rem
	Mersenne: Random numbers

	Version: 1.01"
	Author: Various"
	License: Public Domain"
	Credit: Adapted for BlitzMax by Kanati"
EndRem
Import Brl.Blitz
Import Brl.Math

Import "base.util.mersenne.c"

Extern "c"
  Function mt_SeedRand(seed:int)
  Function mt_Rand32:Int()
  Function mt_RandMax:Int(hi:int)
  Function mt_RandRange:Int(lo:int,hi:int)
End Extern

'Const MAX_INT:int = 2^31-1
'Const MIN_INT:int = -2^31
global MersenneSeed:int = 0

'custom wrapped functions to be sure to pass only "unsigned" integers
'(within the range of the "signed integers" BlitzMax uses)

Function SeedRand(seed:int)
	if seed < 0 then Throw "SeedRand got passed a negative seed ~q"+seed+"~q. not allowed."
	MersenneSeed = seed
	mt_SeedRand(seed)
End Function

Function Rand32:int()
	return mt_Rand32()
End Function

Function RandMax:int(hi:int)
	if hi < 0 then Throw "RandMax got passed a negative limit ~q"+hi+"~q. not allowed."
	return mt_RandMax(hi)
End Function

Function RandRange:int(lo:int, hi:int)
	If lo = hi Then Return lo
	'order min/max
	if hi < lo
		local tmp:int = hi
		hi = lo
		lo = tmp
	endif

	if lo < 0
		local offset:int = -lo
		lo = 0
		hi = hi + offset
		return mt_RandRange(lo, hi) - offset
	endif

	return mt_RandRange(lo, hi)
End Function


'returns a "biased" random number
'bias of 1.0 means "mostly maximum", a bias of 0.1 means "mostly minimum"
Function BiasedRandRangeOld:Int(lo:int, hi:int, bias:Float)
	If lo = hi Then Return lo
	'higher bias values lead to more results near "hi"
	'lower bias values lead to more results near "lo"

	If bias < 0.499
		bias = 2 * bias

		local r:Float = mt_RandRange(0, 1000000) / 1000000.0
		r = r ^ bias
		return hi - (hi - lo) * r + 0.5
	ElseIf bias > 0.501
		bias = 2 * (1 - bias)

		local r:Float = mt_RandRange(0, 1000000) / 1000000.0
		r = r ^ bias
		return (hi - lo) * r + 0.5
	Else
		Return hi - (hi - lo) * mt_RandRange(0, 1000000) / 1000000.0 + 0.5
	EndIf

End Function


Function BiasedRandRange:Int(lo:int, hi:int, bias:Float)
	If lo = hi Then Return lo
    local r:Float = mt_RandRange(0, 1000000) / 1000000.0

    If bias < 0.5
		'round mathematically via int(x+0.5)
        Return hi - r^((bias*2)^0.5) * (hi-lo) + 0.5
    Else
		'round mathematically via int(x+0.5)
		Return (lo + r^((2 - bias*2)^0.5) * (hi-lo)) + 0.5
    EndIf

End Function


'Calculate Gaussian random numbers (based on Box-Müller approach)
Function GaussRand:Float(mean:Float, standardDerivation:Float)
	'+1 to be > 0 (we use Log(v1))
	local v1:Float = (mt_RandMax(999998)+1) / 1000000.0
	local v2:Float = (mt_RandMax(999998)+1) / 1000000.0
	'blitzmax uses degrees instead of radians ... so "Cos(2*pi*v2)" got "Cos(360*v2)"
	return mean + standardDerivation*(Sqr(-2 * Log(v1)) * Cos(360 * v2))
End Function


Function GaussRandRange:Double(minValue:Double, maxValue:Double, mean:Float, standardDerivation:Float)
	local v1:Float = mt_RandRange(0,1000000) / 1000000.0
	local v2:Float = mt_RandRange(0,1000000) / 1000000.0

	return minValue + (maxValue - minValue) * mean * abs(1.0 + sqr(-2.0 * log(v1)) * cos(360 * v2) * standardDerivation)
End Function


'The Function returns a random value within the given range.
'A weighting less or higher than 0.5 define which direction (low or high)
'gets more probably. The more extreme the weight is (0.0 or 1.0) the
'smaller the chance of numbers of the opposite direction. The extremity
'also defines the maximum range of numbers. The more narrow the center
'of a weighting is placed to an extremum, the smaller the range gets.
'
'Ex.: WeightedRange(0, 100, 0.1) will most probably return values of 0-20
'     WeightedRange(0, 100, 0.9) will most probably return values of 80-100
'     WeightedRange(0, 100, 0.6) will most probably return values of 20-100
'But all of them (except 0.0 and 1.0) might return values between 0-100
Function WeightedRandRange:Int(lo:int, hi:int, weight:Float = 0.5, strength:Float = 1.0)
	If lo = hi Then Return lo
	'order min/max
	if hi < lo
		local tmp:int = hi
		hi = lo
		lo = tmp
	endif

	local offset:int = 0
	if lo < 0
		offset = -lo
		lo = 0
		hi = hi + offset
	endif

	'save processing time
	if weight = 0.5 then return RandRange(lo, hi) - offset
	if weight <= 0.0 then return lo - offset
	if weight >= 1.0 then return hi - offset

	'a lower weight makes the "lo" values more likely

	'probability contains a value of 0-1.0 defining how probable
	'it is that twe have to use a weighted random number
	'the more we go to the extreme, the more probable it gets.
	local probability:Float = 2.0 * abs(0.5 - weight)
	local useWeighted:Int = mt_RandMax(100000)/100000.0 < probability

	if useWeighted
		'method a
		'When weighting we recenter the "average" and limit lo,hi so
		'that the resulting random number is somewhere in that area.
		'The more exteme, the smaller the range of potential numbers
		'local range:int = (1.0-probability) * (hi-lo)
		'local influence:Float = abs(1 - 2*weight) ^ strength
		'local center:int = lo + (1-influence) * range/2
		'if weight > 0.5 then center = hi - center

		'method b
		local center:Float = 0.5*(lo + hi) 'lo + (hi-lo)*0.5
		local range:int = 0.5*(hi-lo)
		'move the center according to weighting and strength
		'-> the more strength, the less influence the lower a more and
		'   more centered weighting has
		if weight > 0.5
			center :+ abs(1 - 2*weight)^strength * range
		else
			center :- abs(1 - 2*weight)^strength * range
		endif

		'the new center now defines the maximum range in both directions
		if weight > 0.5
			range = hi - center
		else
			range = center - lo
		endif

		'now calculate new limits (both in the range of the new center)
		hi = center + range
		lo = center - range
	endif

	return RandRange(lo, hi) - offset
End Function


'returns an array of random numbers (no repetitions, including lo and hi)
'efficient only for small amount or small "range"
Function RandRangeArray:int[](lo:int, hi:int, amount:int = 1)
	Local rangeSize:Int =  hi - lo + 1
	'if lo...hi does not contain enough possible candidates
	If amount < 1 or lo > hi or rangeSize < amount then throw "invalid parameters to RandRangeArray; lo "+lo+", hi "+ hi+", amount "+amount

	Local coverage:Float = Float(amount) / rangeSize
	If coverage > 0.7
		'prevent duplicate checks but use memory for index array
		return _fromIndexArray(lo, hi, amount)
	Else
		return _iterativeWithDuplicateCheck(lo, hi, amount)
	EndIF

	Function _iterativeWithDuplicateCheck:int[](lo:int, hi:int, amount:int)
		local result:int[] = new int[amount]
		local number:int
		local numberOK:int
	
		For local i:int = 0 until amount
			repeat
				numberOK = True
				number = RandRange(lo, hi)
				For local d:Int = EachIn result
					if d = number
						numberOK = False
						exit
					endif
				Next
			until numberOK
			result[i] = number
		Next
		return result
	End Function

	Function _fromIndexArray:int[](lo:int, hi:int, amount:int)
		Local all:int = hi - lo + 1
		Local indexes:Int[all]
		Local iptr:Int Ptr = indexes
		For Local i:Int = 0 Until all
			iptr[i] = i
		Next
	
		Local result:int[] = new int[amount]
		Local last:Int = all - 1
		For Local c:Int = 0 Until amount
			Local index:Int = RandRange(0, last)
			result[c] = lo + iptr[index]
	
			iptr[index] = iptr[last]
			last :- 1
		Next
		return result
	End Function
End Function
