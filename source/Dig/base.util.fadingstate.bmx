Rem
	====================================================================
	TFadingState
	====================================================================

	Class helper functions for simple faders.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2014 Ronny Otto, digidea.de

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
Import "base.util.time.bmx"
Import "base.util.interpolation.bmx"

Type TFadingState
	Field fadeStart:int
	Field fadeDuration:int
	Field state:int = False
	Field targetState:int = -1


	Method SetState:int(state:int, fadeDuration:int = 0)
		'skip if already in this state
		if targetState = state then return False
		
		if fadeDuration > 0
			self.fadeDuration = fadeDuration
			self.fadeStart = Time.GetTimeGone()
			self.targetState = state
		else
			self.state = state
			self.targetState = -1
		endif
	End Method


	Method GetState:int()
		if targetState >= 0 and fadeStart + fadeDuration < Time.GetTimeGone()
			state = targetState
			targetState = -1
		endif
		return state
	End Method


	Method IsOn:int()
		return GetState() = 1
	End Method


	Method IsOff:int()
		return GetState() = 0
	End Method


	Method GetFadeProgress:Float()
		if targetState = -1 then return 1.0

		return TInterpolation.Linear(0, 1, Min(Time.GetTimeGone() - fadeStart, fadeDuration), fadeDuration)
	End Method


	Method IsFading:int()
		return targetState >= 0 and targetState <> state
	End Method


	Method IsFadingOff:int()
		return targetState = 0 and state <> 0
	End Method
	

	Method IsFadingOn:int()
		return targetState = 1 and state <> 1
	End Method
End Type