Rem
	====================================================================
	Interpolation
	====================================================================

	This class provides some helpful functions to enable easing,
	bouncing, ... growth of a given interval.

	Calling example:
	- if half of the time is gone (500/1000 = 0.5)
	  x = TInterpolation.Linear(0, 10, 500, 1000)

	- if 25% of a 2 sec animation is gone (0.5/2 = 0.25)
	  x = TInterpolation.Linear(0, 10, 0.5, 2.0)


	Some functions allow additional params:
	- Elastic (a, p)
	- Back (s)
	Both have defaults if no specific params are given


	====================================================================
	Licence: Equation Formulas

	TERMS OF USE - EASING EQUATIONS

	Open source under the BSD License.

	Copyright © 2001 Robert Penner
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions
	are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name of the author nor the names of contributors may
      be used to endorse or promote products derived from this software
      without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
	COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2018 Ronny Otto, digidea.de

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



Type TInterpolation

	'=== LINEAR ===

	Function Linear:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		return (endValue - startValue) * (time / timeTotal) + startValue
	End Function


	'=== BOUNCE ===
	'by Robert Penner

	Function BounceOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ timeTotal

		if time < (1 / 2.75)
			return (endValue - startValue) * (7.5625 * time * time) + startValue
		ElseIf time < (2/2.75)
			time :- (1.5 / 2.75)
			return (endValue - startValue) * (7.5625 * time * time + 0.75) + startValue
		ElseIf time < (2.5/2.75)
			time :- (2.25 / 2.75)
			return (endValue - startValue) * (7.5625 * time * time + 0.9375) + startValue
		Else
			time :- (2.625 / 2.75)
			return (endValue - startValue) * (7.5625 * time * time + 0.984375) + startValue
		Endif
	End Function


	Function BounceIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		Return endValue - BounceOut(0, endValue, timeTotal - time, timeTotal) + startValue
	End Function


	Function BounceInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		If time < 0.5 * timeTotal
			Return BounceIn(0, endValue, 2 * time, timeTotal) * 0.5 + startValue
		Else
			Return BounceOut(0, endValue, 2 * time - timeTotal, timeTotal) * 0.5 + (endValue - startValue) * 0.5 + startValue
		EndIf
	End Function


	'=== REGULAR ===
	'by Robert Penner

	Function RegularIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ timeTotal
		Return (endValue - startValue) * time * time + startValue
	End Function


	Function RegularOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ timeTotal
		Return - (endValue - startValue) * time * (time - 2) + startValue
	End Function


	Function RegularInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ (0.5 * timeTotal)
		If time < 1.0
			Return 0.5 * (endValue - startValue) * time * time + startValue
		Else
			Return - 0.5 * (endValue - startValue) * ((time - 1) * (time - 3) - 1) + startValue
		EndIf
	End Function


	'=== STRONG ===
	'by Robert Penner

	Function StrongIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ timeTotal
		Return (endValue - startValue) * time^5 + startValue
	End Function


	Function StrongOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time = time / timeTotal - 1
		Return  (endValue - startValue) * (time^5 + 1) + startValue
	End Function


	Function StrongInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ (0.5 * timeTotal)
		If time < 1.0
			Return 0.5 * (endValue - startValue) * time^5 + startValue
		Else
			time :- 2
			Return 0.5 * (endValue - startValue) * (time^5 + 2) + startValue
		EndIf
	End Function


	'=== BACK ===
	'by Robert Penner

	Function BackIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double, s:Double = -1.0)
		If s = -1.0 Then s = 1.70158
		time :/ timeTotal
		Return (endValue - startValue) * time * time * ((s + 1) * time - s) + startValue
	End Function


	Function BackOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double, s:Double = -1.0)
		If s = -1.0 Then s = 1.70158
		time = time / timeTotal - 1.0
		Return (endValue - startValue) * (time * time * ((s + 1) * time + s) + 1) + startValue
	End Function


	Function BackInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double, s:Double = -1.0)
		If s = -1.0 Then s = 1.70158
		time :/ (0.5 * timeTotal)
		s :* 1.525
		If time < 1.0
			Return 0.5 * (endValue - startValue) * (time * time * ((s + 1) * time - s)) + startValue
		Else
			time :- 2.0
			Return 0.5 * (endValue - startValue) * (time * time * ((s + 1) * time + s) + 2) + startValue
		EndIf
	End Function


	'=== ELASTIC ===
	'by Robert Penner

	Function ElasticIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double, a:Double = 0.0, p:Double = 0.0)
		Local s:Double

		If time = 0.0 Then Return startValue
		time :/ timeTotal
		If time = 1.0 Then Return endValue

		If p = 0 Then p = timeTotal * 0.3
		If a = 0 Or a < Abs((endValue - startValue))
			a = (endValue - startValue)
			s = p / 4.0
		Else
			s = p / (2.0 * PI) * ASin((endValue - startValue) / a)
		EndIf

		time :- 1.0
		Return - (a * (2.0 ^ (10 * time)) * Sin((time * timeTotal - s) * (2.0 * PI) / p)) + startValue
	End Function


	Function ElasticOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double, a:Double = 0.0, p:Double = 0.0)
		Local s:Double

		If time = 0.0 Then Return startValue
		time :/ timeTotal
		If time = 1.0 Then Return endValue

		If not p Then p = timeTotal * 0.3

		If not a Or a < Abs((endValue - startValue))
			a = (endValue - startValue)
			s = p / 4.0
		Else
			s = p / (2.0 * PI) * ASin((endValue - startValue) / a)
		EndIf

		Return (a * (2.0 ^ (-10 * time)) * Sin((time * timeTotal - s) * (2.0 * PI) / p)) + endValue
	End Function


	Function ElasticInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double, a:Double = 0.0, p:Double = 0.0)
		Local s:Double

		If time = 0.0 Then Return startValue
		time :/ (0.5 * timeTotal)
		If time = 2.0 Then Return endValue

		If p = 0 Then p = timeTotal * (0.3 * 1.5)

		If a = 0 Or a < Abs((endValue - startValue))
			a = (endValue - startValue)
			s = p / 4.0
		Else
			s = p / (2 * PI) * ASin((endValue - startValue) / a)
		EndIf

		If time < 1.0
			time :- 1.0
			Return - 0.5 * (a * (2.0 ^ (10 * time)) * Sin((time * timeTotal - s) * (2.0 * PI) / p)) + startValue
		EndIf

		time :- 1.0
		Return a * (2.0 ^ (-10 * time)) * Sin((time * timeTotal - s) * (2.0 * PI) / p) * 0.5 + endValue
	End Function


	'=== CIRC ===
	'by Robert Penner

	Function CircIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ timeTotal
		Return - (endValue - startValue) * (Sqr(1.0 - time * time) - 1.0) + startValue
	End Function


	Function CircOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time = time / timeTotal - 1
		Return (endValue - startValue) * Sqr(1.0 - time * time) + startValue
	End Function


	Function CircInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ (0.5 * timeTotal)
		If time < 1.0
			Return - 0.5 * (endValue - startValue) * (Sqr(1.0 - time * time) - 1.0) + startValue
		Else
			time :- 2.0
			Return 0.5 * (endValue - startValue) * (Sqr(1.0 - time * time) + 1.0) + startValue
		EndIf
	End Function


	'=== CUBIC ===
	'by Robert Penner

	Function CubicIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ timeTotal
		Return (endValue - startValue) * time * time * time + startValue
	End Function


	Function CubicOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time = time / timeTotal - 1
		Return (endValue - startValue) * (time * time * time + 1.0) + startValue
	End Function


	Function CubicInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ (0.5 * timeTotal)
		If time < 1.0
			Return 0.5 * (endValue - startValue) * time * time * time + startValue
		Else
			time :- 2.0
			Return 0.5 * (endValue - startValue) * (time * time * time + 2.0) + startValue
		EndIf
	End Function


	'=== EXPO ===
	'by Robert Penner

	Function ExpoIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		If time = 0.0
			Return startValue
		Else
			Return (endValue - startValue) * (2.0 ^ (10 * (time / timeTotal - 1.0))) + startValue
		EndIf
	End Function


	Function ExpoOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		If time = timeTotal
			Return endValue
		Else
			Return (endValue - startValue) * (-(2.0 ^ (-10 * time / timeTotal)) + 1.0) + startValue
		EndIf
	End Function


	Function ExpoInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		If time = 0.0 Then Return startValue
		If time = timeTotal Then Return endValue

		time :/ (0.5 * timeTotal)
		If time < 1.0
			Return 0.5 * (endValue - startValue) * (2.0 ^ (10 * (time - 1))) + startValue
		Else
			Return 0.5 * (endValue - startValue) * (-(2.0 ^ (-10 * (time - 1))) + 2.0) + startValue
		EndIf
	End Function


	'=== QUART ===
	'by Robert Penner

	Function QuartIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ timeTotal
		Return (endValue - startValue) * time * time * time * time + startValue
	End Function


	Function QuartOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time = time / timeTotal - 1.0
		Return - (endValue - startValue) * (time * time * time * time - 1.0) + startValue
	End Function


	Function QuartInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		time :/ (0.5 * timeTotal)
		If time < 1.0
			Return 0.5 * (endValue - startValue) * time * time * time * time + startValue
		Else
			time :- 2.0
			Return - 0.5 * (endValue - startValue) * (time * time * time * time - 2.0) + startValue
		EndIf
	End Function


	'=== SINE ===
	'by Robert Penner

	Function SineIn:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		Return - (endValue - startValue) * Cos((time / timeTotal * (PI / 2.0)) * (180.0 / PI)) + endValue
	End Function


	Function SineOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		Return (endValue - startValue) * Sin((time / timeTotal * (PI / 2.0)) * (180.0 / PI)) + startValue
	End Function


	Function SineInOut:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		Return - 0.5 * (endValue - startValue) * (Cos((PI * time / timeTotal) * (180.0 / PI)) - 1.0) + startValue
	End Function
End Type
