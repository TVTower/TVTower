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


Rem
bbdoc: Fast deterministic pseudo-random number generator.
about:
Use #SFastRandom when you need reproducible random sequences from explicit seeds,
for example in gameplay systems, simulations, tests or other deterministic logic.
Unlike #TRandom-based PRNG implementations, this is a struct and value-based and
does not require object allocations during number generation, so repeated use does
not create additional GC pressure.
End Rem
Struct SFastRandom
	Field seed:Int
	Field state:Long

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
	Method SeedRnd(seed:Int)
		self.seed = seed
		'start with new state based on seed
		self.state = seed
	End Method


	Rem
	bbdoc: Returns the current seed/state as integer.
	returns: Current internal state cast to Int.
	End Rem
	Method RndSeed:Int()
		Return seed
	End Method


	Rem
	bbdoc: Advances the internal state and returns the next 32-bit random value.
	returns: Next pseudo-random UInt value.
	End Rem
	Method NextState:UInt()
		'scambled LCG (Linear Congruential Generator)

		state :* 6364136223846793005
		state :+ 1

		Local x:ULong = state
		x :~ x Shr 18
		Return UInt((x Shr 27) & ULong($FFFFFFFF))
	End Method


	Rem
	bbdoc: Generates a random float in range [0,1).
	returns: Random Float from 0 (inclusive) to 1 (exclusive).
	End Rem
	Method RndFloat:Float()
		Local x:UInt = NextState()
		Return Float(Double(x) * (1.0:Double / 4294967296.0:Double))
	End Method


	Rem
	bbdoc: Generates a random double in range [0,1).
	returns: Random Double from 0 (inclusive) to 1 (exclusive).
	End Rem
	Method RndDouble:Double()
		Local x:UInt = NextState()
		Return Double(x) * (1.0:Double / 4294967296.0:Double)
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
	Method RandFloat:Float(minValue:Float = 1.0, maxValue:Float = 0.0)
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
	Method RandDouble:Double(minValue:Double = 1.0, maxValue:Double = 0.0)
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
	Method RandBool:Int()
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
	Method Rand:Int(minValue:Int = 1, maxValue:Int = 0)
		If maxValue = 0
			maxValue = minValue
			minValue = 1
		EndIf

		If maxValue < minValue
			Local t:Int = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Local range:ULong = ULong(maxValue - minValue + 1)
		Local r:ULong = ULong(NextState())
		Local result:ULong = (r * range) Shr 32

		Return Int(result) + minValue
	End Method


	Rem
	bbdoc: TRandom-compatible integer method.
	returns: Random Int from @minValue (inclusive) to @maxValue (inclusive).
	about:
	This matches TRandom's #RandomInt signature.
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomInt:Int(minValue:Int, maxValue:Int = 1)
		Return Rand(minValue, maxValue)
	End Method


	Rem
	bbdoc: Generates a random long in range [min,max].
	returns: Random Long from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomLong:Long(minValue:Long, maxValue:Long = 1)
		If maxValue < minValue
			Local t:Long = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Local range:Double = Double(maxValue) - Double(minValue) + 1.0
		Return Long(RndDouble() * range) + minValue
	End Method


	Rem
	bbdoc: Generates a random short in range [min,max].
	returns: Random Short from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomShort:Short(minValue:Short, maxValue:Short = 1)
		If maxValue < minValue
			Local t:Short = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Return Short(RandomInt(Int(minValue), Int(maxValue)))
	End Method


	Rem
	bbdoc: Generates a random byte in range [min,max].
	returns: Random Byte from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomByte:Byte(minValue:Byte, maxValue:Byte = 1)
		If maxValue < minValue
			Local t:Byte = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Return Byte(RandomInt(Int(minValue), Int(maxValue)))
	End Method

	Rem
	bbdoc: Generates a random unsigned integer in range [min,max].
	returns: Random UInt from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomUInt:UInt(minValue:UInt, maxValue:UInt = 1)
		If maxValue < minValue
			Local t:UInt = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Local range:ULong = ULong(maxValue) - ULong(minValue) + 1:ULong
		Local r:ULong = ULong(NextState())
		Local result:ULong = (r * range) Shr 32

		Return UInt(result + ULong(minValue))
	End Method


	Rem
	bbdoc: Generates a random unsigned long in range [min,max].
	returns: Random ULong from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomULong:ULong(minValue:ULong, maxValue:ULong = 1)
		If maxValue < minValue
			Local t:ULong = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Local range:Double = Double(maxValue) - Double(minValue) + 1.0
		Return ULong(Double(minValue) + RndDouble() * range)
	End Method


	Rem
	bbdoc: Generates a random signed long integer in range [min,max].
	returns: Random LongInt from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomLongInt:LongInt(minValue:LongInt, maxValue:LongInt = 1)
		If maxValue < minValue
			Local t:LongInt = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Local range:Double = Double(maxValue) - Double(minValue) + 1.0
		Return LongInt(Double(minValue) + RndDouble() * range)
	End Method


	Rem
	bbdoc: Generates a random unsigned long integer in range [min,max].
	returns: Random ULongInt from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomULongInt:ULongInt(minValue:ULongInt, maxValue:ULongInt = 1)
		If maxValue < minValue
			Local t:ULongInt = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Local range:Double = Double(maxValue) - Double(minValue) + 1.0
		Return ULongInt(Double(minValue) + RndDouble() * range)
	End Method


	Rem
	bbdoc: Generates a random size_t value in range [min,max].
	returns: Random Size_T from @minValue (inclusive) to @maxValue (inclusive).
	about:
	@minValue: Lower bound (inclusive).
	@maxValue: Upper bound (inclusive).
	End Rem
	Method RandomSizeT:Size_T(minValue:Size_T, maxValue:Size_T = 1)
		If maxValue < minValue
			Local t:Size_T = minValue
			minValue = maxValue
			maxValue = t
		EndIf

		Local range:Double = Double(maxValue) - Double(minValue) + 1.0
		Return Size_T(Double(minValue) + RndDouble() * range)
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
	Return r.Rand(maxValue)
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
	Return r.Rand(minValue, maxValue)
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
	Return r.RandFloat(maxValue)
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
	Return r.RandFloat(minValue, maxValue)
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
	Return r.RandDouble(maxValue)
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
	Return r.RandDouble(minValue, maxValue)
End Function

