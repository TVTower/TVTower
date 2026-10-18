Rem
	====================================================================
	FastRandom (LCG based pseudo random number generator)
	====================================================================

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2026-now Ronny Otto, digidea.de

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
Import Brl.Math ' for Log(), Cos(), Sqr()


Rem
bbdoc: Fast deterministic pseudo-random number generator. Algorithm taken from brl.random
about:
Use #SFastRandom when you need reproducible random sequences from explicit seeds,
for example in gameplay systems, simulations, tests or other deterministic logic.
Unlike #TRandom-based PRNG implementations, this is a struct and value-based and
does not require object allocations during number generation, so repeated use does
not create additional GC pressure.
End Rem
Struct SFastRandom
	Field seed:Int
	Field state:Int=$1234

	Rem
	bbdoc: Creates a new fast random generator with an initial @seed.
	returns: The initialized generator instance.
	about:
	@seed: Initial seed value.
	End Rem
	Method New(seed:Int)
		SeedRnd(seed)
	End Method


	Rem
	bbdoc: Sets the new seed for the generator.
	about:
	@seed: New seed value.
	End Rem
	Method SeedRnd(seed:Int) NoDebug
		self.seed = seed
		'start with new state based on seed
		self.state = seed
	End Method


	Rem
	bbdoc: Returns the current seed/state as integer.
	returns: Current internal state cast to Int.
	End Rem
	Method RndSeed:Int() NoDebug
		Return seed
	End Method


	Rem
	bbdoc: Advances the internal state
	returns: Next state value
	End Rem
	Method NextState:Int() NoDebug
		Const RND_A:Int=48271
		Const RND_M:Int=2147483647
		Const RND_Q:Int=44488
		Const RND_R:Int=3399
		state = RND_A * (state Mod RND_Q) - RND_R * (state / RND_Q)
		If state < 0 Then state :+ RND_M
		
		'state = 48271 * (state Mod 44488) - 3399 * (state / 44488)
		'If state < 0 Then state :+ 2147483647
		Return state
	End Method

	Method NextULong:ULong()
		' 31-bit rnd_state; avoid low bits by shifting right.
		' harvest 22 + 22 + 20 = 64 bits total.

		Local a:ULong = ULong((NextState() Shr 9)  & $003FFFFF) ' top-ish 22 bits
		Local b:ULong = ULong((NextState() Shr 9)  & $003FFFFF) ' 22 bits
		Local c:ULong = ULong((NextState() Shr 11) & $000FFFFF) ' 20 bits

		Return (a Shl 42) | (b Shl 20) | c
	End Method


	Rem
	bbdoc: Generates a random float in range [0,1).
	returns: Random Float from 0 (inclusive) to 1 (exclusive).
	End Rem
	Method RndFloat:Float()
		NextState()
		Return (state & $ffffff0) / 268435456#  'divide by 2^28
	End Method


	Rem
	bbdoc: Generates a random double in range [0,1).
	returns: Random Double from 0 (inclusive) to 1 (exclusive).
	End Rem
	Method RndDouble:Double()
		Const TWO27:Double = 134217728.0		'2 ^ 27
		Const TWO29:Double = 536870912.0		'2 ^ 29
	
		NextState()
		Local r_hi:Double = state & $1ffffffc
	
		NextState()
		Local r_lo:Double = state & $1ffffff8
	
		Return (r_hi + r_lo/TWO27)/TWO29
	End Method


	Rem
	bbdoc: Generates a random double in range [min,max).
	returns: Random Double from @minValue (inclusive) to @maxValue (exclusive).
	about:
	The optional parameters allow you to call this in three ways:
	- Rnd() -> 0.0 to 1.0
	- Rnd(x) -> 0.0 to x
	- Rnd(x,y) -> x to y
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (exclusive). If omitted, @minValue is used as upper bound and lower bound becomes 0.
	End Rem
	Method Rnd:Double(minValue:Double = 1.0, maxValue:Double = 0.0)
		If maxValue = 0.0
			maxValue = minValue
			minValue = 0.0
		EndIf

		If maxValue < minValue
			Local t:Double = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Return minValue + RndDouble() * (maxValue - minValue)
	End Method

	Rem
	bbdoc: Generates a random float in range [min,max).
	returns: Random Float from @minValue (inclusive) to @maxValue (exclusive).
	about:
	The optional parameters are handled analog to #Rand:
	- RandFloat(x) -> 1.0 to x
	- RandFloat(x,y) -> x to y
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (exclusive). If omitted, @minValue is used as upper bound and lower bound becomes 1.
	End Rem
	Method RandomFloat:Float(minValue:Float = 1.0, maxValue:Float = 0.0)
		If maxValue = 0.0
			maxValue = minValue
			minValue = 1.0
		EndIf

		If maxValue < minValue
			Local t:Float = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Return minValue + RndFloat() * (maxValue - minValue)
	End Method


	Rem
	bbdoc: Generates a random double in range [min,max).
	returns: Random Double from @minValue (inclusive) to @maxValue (exclusive).
	about:
	The optional parameters are handled analog to #Rand:
	- RandDouble(x) -> 1.0 to x
	- RandDouble(x,y) -> x to y
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (exclusive). If omitted, @minValue is used as upper bound and lower bound becomes 1.
	End Rem
	Method RandomDouble:Double(minValue:Double = 1.0, maxValue:Double = 0.0)
		If maxValue = 0.0
			maxValue = minValue
			minValue = 1.0
		EndIf

		If maxValue < minValue
			Local t:Double = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Return minValue + RndDouble() * (maxValue - minValue)
	End Method


	Rem
	bbdoc: Generates a random boolean (0 or 1).
	returns: 0 or 1.
	End Rem
	Method RandomBool:Int()
		Return Int(NextState() & UInt(1))
	End Method


	Rem
	bbdoc: Generates a random integer in range [min,max].
	returns: Random Int from @minValue (inclusive) to @maxValue (inclusive).
	about:
	The optional parameters allow two call styles:
	- Rand(x) -> 1 to x
	- Rand(x,y) -> x to y
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive). If omitted, @minValue is used as upper bound and lower bound becomes 1.
	End Rem
	Method RandomInt:Int(minValue:Int = 1, maxValue:Int = 0)
		Return Int(RandomLong(minValue, maxValue))
	End Method


	Rem
	bbdoc: Generates an array of unique random integers in range [min,max].
	returns: Int[] with up to @amount unique values (no duplicates).
	about:
	Uses an LCG cycle over a power-of-two modulus and filters values to the desired
	range, yielding each valid value at most once per cycle.
	If @amount is larger than the available count in range, all values are returned.
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	@amount: Number of unique random values to return.
	End Rem
	Method RandomIntArray:Int[](minValue:Int, maxValue:Int, amount:Int)
		Local result:Int[]
		If amount <= 0 Then Return result

		If minValue > maxValue
			Local t:Int = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Local valueCount:ULong = ULong(Long(maxValue) - Long(minValue) + 1)
		If valueCount <= 0 Then Return result

		If ULong(amount) > valueCount Then amount = Int(valueCount)
		result = New Int[amount]

		' LCG parameters for full period with power-of-two modulus:
		'  - odd increment
		'  - multiplier = 1 mod 4
		Local modulus:ULong = _NextPowerOfTwo(valueCount)
		Local mask:ULong = modulus - 1

		Local value:ULong = RandomULong(0, mask)
		Local offset:ULong = (RandomULong(0, mask) Shl 1) | 1
		Local multiplier:ULong = ((RandomULong(0, mask) Shr 2) Shl 2) + 1
		Local multiplierMod4:ULong = multiplier Mod 4
		If multiplierMod4 <> 1
			multiplier :+ (1 - multiplierMod4)
		EndIf

		Local found:Int = 0
		While found < amount
			If value < valueCount
				result[found] = minValue + Int(value)
				found :+ 1
			EndIf

			value = (value * multiplier + offset) & mask
		Wend

		Return result


		Function _NextPowerOfTwo:ULong(v:ULong)
			If v <= 1 Then Return 1
			v :- 1
			v :| (v Shr 1)
			v :| (v Shr 2)
			v :| (v Shr 4)
			v :| (v Shr 8)
			v :| (v Shr 16)
			v :| (v Shr 32)
			Return v + 1
		End Function
	End Method



	Rem
	bbdoc: Generates a biased random double in range [min,max].
	returns: Random Double from @minValue (inclusive) to @maxValue (inclusive), biased by @bias.
	about:
	@bias is clamped to [0,1].
	- 0.0: strong tendency towards @minValue
	- 0.5: unbiased (uniform)
	- 1.0: strong tendency towards @maxValue
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	@bias: Bias factor in [0,1].
	End Rem
	Method RandomBiasedDouble:Double(minValue:Double, maxValue:Double, bias:Double = 0.5)
		If minValue > maxValue
			Local t:Double = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		If minValue = maxValue Then Return minValue

		If bias < 0.0 Then bias = 0.0
		If bias > 1.0 Then bias = 1.0

		Local r:Double = RndDouble()
		Local range:Double = maxValue - minValue

		If bias = 0.5
			Return minValue + r * range
		ElseIf bias < 0.5
			Local exponent:Double = (bias * 2.0) ^ 0.5
			Return maxValue - (r ^ exponent) * range
		Else
			Local exponent:Double = (2.0 - bias * 2.0) ^ 0.5
			Return minValue + (r ^ exponent) * range
		EndIf
	End Method


	Rem
	bbdoc: Generates a biased random integer in range [min,max].
	returns: Random Int from @minValue (inclusive) to @maxValue (inclusive), biased by @bias.
	about:
	Uses #RandomBiasedDouble internally and maps to equal-width integer buckets.
	@bias is clamped to [0,1].
	- 0.0: strong tendency towards @minValue
	- 0.5: unbiased (uniform)
	- 1.0: strong tendency towards @maxValue
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	@bias: Bias factor in [0,1].
	End Rem
	Method RandomBiasedInt:Int(minValue:Int, maxValue:Int, bias:Double = 0.5)
		If minValue > maxValue
			Local t:Int = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		If minValue = maxValue Then Return minValue

		' Map normalized biased values to equal-width integer buckets.
		' This avoids the half-width edge bins produced by rounding.
		Local span:Long = Long(maxValue) - Long(minValue) + 1
		Local unitValue:Double = RandomBiasedDouble(0.0, 1.0, bias)
		Local index:Long = Long(unitValue * Double(span))

		If index < 0 Then index = 0
		If index >= span Then index = span - 1

		Return minValue + Int(index)
	End Method


	Rem
	bbdoc: Generates a Gaussian-distributed random value using the Box-Muller transform.
	returns: Random Double distributed around @mean with standard deviation @standardDeviation.
	about:
	The method uses deterministic values from this generator and works with BlitzMax
	trigonometric functions in degree mode.
	@mean: Center of the normal distribution.
	@standardDeviation: Standard deviation (spread). Values <= 0 return @mean.
	End Rem
	Method RandomGaussian:Double(mean:Double = 0.0, standardDeviation:Double = 1.0)
		If standardDeviation <= 0.0 Then Return mean

		Local v1:Double = RndDouble()
		Local v2:Double = RndDouble()
		' Avoid log(0) which would yield NaN. Clamp to a small positive value.
		If v1 = 0.0 Then v1 = 1e-10

		' BlitzMax trigonometric functions use degrees, so 2*pi*v2 => 360*v2
		Local gaussian:Double = Sqr(-2.0 * Log(v1)) * Cos(360.0 * v2)
		Return mean + standardDeviation * gaussian
	End Method


	Rem
	bbdoc: Generates a Gaussian-distributed value mapped into [min,max].
	returns: Random Double in [@minValue,@maxValue] based on Gaussian parameters in normalized space.
	about:
	This method samples a Gaussian in normalized space and rejects values outside [0,1],
	then maps the accepted value to [@minValue,@maxValue].
	@minValue: Lower bound.
	@maxValue: Upper bound.
	@mean: Mean in normalized space (typical 0.5).
	@standardDeviation: Standard deviation in normalized space (typical 0.15).
	@maxIterations: Safety cap for rejection sampling. If exceeded, falls back to clamped sample.
	End Rem
	Method RandomGaussianDouble:Double(minValue:Double, maxValue:Double, mean:Double = 0.5, standardDeviation:Double = 0.15, maxIterations:Int = 1000)
		Local lo:Double = minValue
		Local hi:Double = maxValue
		If lo > hi
			Local t:Double = lo
			lo = hi
			hi = t
		EndIf

		If lo = hi Then Return lo

		Local normalized:Double
		If standardDeviation <= 0.0
			normalized = mean
		Else
			Local accepted:Int = False
			For Local i:Int = 0 Until Max(1, maxIterations)
				normalized = RandomGaussian(mean, standardDeviation)
				If normalized >= 0.0 And normalized <= 1.0
					accepted = True
					Exit
				EndIf
			Next
			If Not accepted
				normalized = RandomGaussian(mean, standardDeviation)
			EndIf
		EndIf

		If normalized < 0.0 Then normalized = 0.0
		If normalized > 1.0 Then normalized = 1.0

		Return lo + (hi - lo) * normalized
	End Method


	Rem
	bbdoc: Generates a Gaussian-distributed integer in range [min,max].
	returns: Random Int in [@minValue,@maxValue] based on Gaussian parameters in normalized space.
	about:
	This method samples Gaussian values in normalized space and maps them to equal-width
	integer buckets so that edge values (@minValue and @maxValue) remain reachable.
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	@mean: Mean in normalized space (typical 0.5).
	@standardDeviation: Standard deviation in normalized space (typical 0.15).
	@maxIterations: Safety cap for rejection sampling. If exceeded, falls back to clamped sample.
	End Rem
	Method RandomGaussianInt:Int(minValue:Int, maxValue:Int, mean:Double = 0.5, standardDeviation:Double = 0.15, maxIterations:Int = 1000)
		If minValue > maxValue
			Local t:Int = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		If minValue = maxValue Then Return minValue

		Local normalized:Double
		If standardDeviation <= 0.0
			normalized = mean
		Else
			Local accepted:Int = False
			For Local i:Int = 0 Until Max(1, maxIterations)
				normalized = RandomGaussian(mean, standardDeviation)
				If normalized >= 0.0 And normalized <= 1.0
					accepted = True
					Exit
				EndIf
			Next
			If Not accepted
				normalized = RandomGaussian(mean, standardDeviation)
			EndIf
		EndIf

		If normalized < 0.0 Then normalized = 0.0
		If normalized > 1.0 Then normalized = 1.0

		Local span:Long = Long(maxValue) - Long(minValue) + 1
		Local index:Long = Long(normalized * Double(span))
		If index < 0 Then index = 0
		If index >= span Then index = span - 1

		Return minValue + Int(index)
	End Method


	Rem
	bbdoc: Generates a random unsigned long in range [min,max].
	returns: Random ULong from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomULong:ULong(lo:ULong, hi:ULong)
		If lo > hi Then
			Local t:ULong = lo
			lo = hi
			hi = t
		End If

		Local span:ULong = hi - lo + 1:ULong

		' span==0 means full 0..2^64-1
		If span = 0:ULong Then
			Return NextULong()
		End If

		Local max:ULong = $FFFFFFFFFFFFFFFF:ULong
		Local limit:ULong = (max / span) * span - 1:ULong

		Local r:ULong
		Repeat
			r = NextULong()
		Until r <= limit

		Return lo + (r Mod span)
	End Method

	Rem
	bbdoc: Generates a random long in range [min,max].
	returns: Random Long from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomLong:Long(minValue:Long, maxValue:Long = 1)
		Local lo:Long = minValue
		Local hi:Long = maxValue
		If lo > hi Then
			Local t:Long = lo
			lo = hi
			hi = t
		End If

		' Map signed -> order-preserving unsigned
		Const SIGNBIT_64:ULong = $8000000000000000:ULong
		Local ulo:ULong = (ULong(lo) ~ SIGNBIT_64)
		Local uhi:ULong = (ULong(hi) ~ SIGNBIT_64)

		' Draw uniformly in that unsigned interval
		Local u:ULong = RandomULong(ulo, uhi)

		' Map back unsigned -> signed
		Return Long(u ~ SIGNBIT_64)
	End Method


	Rem
	bbdoc: Generates a random short in range [min,max].
	returns: Random Short from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomShort:Short(minValue:Short, maxValue:Short = 1)
		Return Short(RandomULong(ULong(minValue), ULong(maxValue)))
	End Method


	Rem
	bbdoc: Generates a random byte in range [min,max].
	returns: Random Byte from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomByte:Byte(minValue:Byte, maxValue:Byte = 1)
		Return Byte(RandomULong(ULong(minValue), ULong(maxValue)))
	End Method

	Rem
	bbdoc: Generates a random unsigned integer in range [min,max].
	returns: Random UInt from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomUInt:UInt(minValue:UInt, maxValue:UInt = 1)
		Return UInt(RandomULong(ULong(minValue), ULong(maxValue)))
	End Method


	Rem
	bbdoc: Generates a random signed long integer in range [min,max].
	returns: Random LongInt from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomLongInt:LongInt(minValue:LongInt, maxValue:LongInt = 1)
		Return LongInt(RandomLong(minValue, maxValue))
	End Method


	Rem
	bbdoc: Generates a random unsigned long integer in range [min,max].
	returns: Random ULongInt from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomULongInt:ULongInt(minValue:ULongInt, maxValue:ULongInt = 1)
		Return ULongInt(RandomULong(ULong(minValue), ULong(maxValue)))
	End Method


	Rem
	bbdoc: Generates a random size_t value in range [min,max].
	returns: Random Size_T from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomSizeT:Size_T(minValue:Size_T, maxValue:Size_T = 1)
		Return Size_T(RandomULong(ULong(minValue), ULong(maxValue)))
	End Method
End Struct


Rem
bbdoc: Generates a deterministic random integer in range [0,max].
returns: Random Int from 1 (inclusive) to @maxValue (inclusive).
about:
Creates a temporary #SFastRandom seeded with @seed.
@maxValue: Upper bound (inclusive).
@seed: Seed used for deterministic output.
End Rem
Function FastRandomInt:Int(maxValue:Int, seed:Int)
	Local r:SFastRandom = New SFastRandom(seed)
	Return r.RandomInt(maxValue)
End Function

Rem
bbdoc: Generates a deterministic random integer in range [min,max].
returns: Random Int from @minValue (inclusive) to @maxValue (inclusive).
about:
Creates a temporary #SFastRandom seeded with @seed.
@minValue: Lower bound (inclusive).
@maxValue: Upper bound (inclusive).
@seed: Seed used for deterministic output.
End Rem
Function FastRandomInt:Int(minValue:Int, maxValue:Int, seed:Int)
	Local r:SFastRandom = New SFastRandom(seed)
	Return r.RandomInt(minValue, maxValue)
End Function


Rem
bbdoc: Generates a deterministic random float in range [0,max).
returns: Random Float from 1.0 (inclusive) to @maxValue (exclusive).
about:
Creates a temporary #SFastRandom seeded with @seed.
@maxValue: Upper bound (exclusive).
@seed: Seed used for deterministic output.
End Rem
Function FastRandomFloat:Float(maxValue:Float, seed:Int)
	Local r:SFastRandom = New SFastRandom(seed)
	Return r.RandomFloat(maxValue)
End Function


Rem
bbdoc: Generates a deterministic random float in range [min,max).
returns: Random Float from @minValue (inclusive) to @maxValue (exclusive).
about:
Creates a temporary #SFastRandom seeded with @seed.
@minValue: Lower bound (inclusive).
@maxValue: Upper bound (exclusive).
@seed: Seed used for deterministic output.
End Rem
Function FastRandomFloat:Float(minValue:Float, maxValue:Float, seed:Int)
	Local r:SFastRandom = New SFastRandom(seed)
	Return r.RandomFloat(minValue, maxValue)
End Function


Rem
bbdoc: Generates a deterministic random double in range [0,max).
returns: Random Double from 1.0 (inclusive) to @maxValue (exclusive).
about:
Creates a temporary #SFastRandom seeded with @seed.
@maxValue: Upper bound (exclusive).
@seed: Seed used for deterministic output.
End Rem
Function FastRandomDouble:Double(maxValue:Double, seed:Int)
	Local r:SFastRandom = New SFastRandom(seed)
	Return r.RandomDouble(maxValue)
End Function


Rem
bbdoc: Generates a deterministic random double in range [min,max).
returns: Random Double from @minValue (inclusive) to @maxValue (exclusive).
about:
Creates a temporary #SFastRandom seeded with @seed.
@minValue: Lower bound (inclusive).
@maxValue: Upper bound (exclusive).
@seed: Seed used for deterministic output.
End Rem
Function FastRandomDouble:Double(minValue:Double, maxValue:Double, seed:Int)
	Local r:SFastRandom = New SFastRandom(seed)
	Return r.RandomDouble(minValue, maxValue)
End Function

