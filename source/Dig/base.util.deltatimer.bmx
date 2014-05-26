Rem
	====================================================================
	class for smooth framerates
	====================================================================

	This class provides a Loop-Method too.
	To have functions run in this loop, connect functions to the
	_funcUpdate and _funcRender properties.


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
Import Brl.retro
Import "base.util.time.bmx"



Type TDeltaTimer
	'1.0/UPS
	Field _updateRate:float
	'1.0/FPS
	Field _renderRate:float
	'conversion from realtime->apptime (2.0 = double as fast)
	Field _timeFactor:float  = 1.0

	'time available for updates in this loop
	Field _updateAccumulator:float
	'time available for renders in this loop
	Field _renderAccumulator:float

	Field timesUpdated:int   = 0
	Field timesRendered:int  = 0
	Field currentUPS:int     = 0
	Field currentFPS:int     = 0

	'connect functions with this properties to get called during Loop()
	Field _funcUpdate:int()
	Field _funcRender:int()

	'when did the current loop begin
	Field _loopBeginTime:int
	'realtime how long the last loop took
	Field _lastLoopTime:int
	'time all loops used so far
	Field _loopTimeSum:float = 0.0
	'amount of loops done
	Field _loopTimeCount:int = 0
	'time accumulator to check whether a second passed
	'(value = milliseconds)
	Field _secondGone:int = 0

	Global _instance:TDeltaTimer


	Function GetInstance:TDeltaTimer()
		if not _instance then _instance = new TDeltaTimer
		return _instance
	End Function


	Method Init:TDeltaTimer(UpdatesPerSecond:int = 60, RendersPerSecond:int = -1)
		_updateRate = 1.0 / UpdatesPerSecond	'UPS
		_renderRate = 1.0 / RendersPerSecond	'FPS
		Reset()
		return self
	End Method


	Method Reset()
		_loopBeginTime = Time.GetTimeGone()
	End Method


	'returns the time available for the next loop.
	'=====
	'if not enough time is left, the time left is returned
	'returned value is in seconds (0.123 seconds)
	Method GetDelta:float()
		return _updateRate  'fixed rate
	End Method


	'time the current loop needed up to now
	Method GetCurrentLoopTime:float()
		return Time.GetTimeGone() - _loopBeginTime
	End Method


	Method GetLoopTimeAverage:float()
		if _loopTimeCount > 0
			return _loopTimeSum / _loopTimeCount
		else
			return 0
		endif
	End Method


	'get the progress/percentage to next update
	'=====
	'result is a value between 0.0 and 1.0 (percentage)
	Method GetTween:float()
		'_updateAccumulator contains remainder
		return _updateAccumulator / _updateRate
	End Method


	Method GetTweenResult:float(currentValue:float, oldValue:float, avoidShaking:int=TRUE)
		local result:float = currentValue * getTween() + oldValue * (1.0 - getTween())
		if avoidShaking and Abs(result - currentValue) < 0.1 then return currentValue
		return result
	End Method


	'updates currentFps and currentUps
	Method UpdateStatistics:int()
		_secondGone	:+ _lastLoopTime

		if _secondGone >= 1000 'in ms
			_secondGone   = 0
			currentFPS    = timesRendered
			currentUPS    = timesUpdated
			timesRendered = 0
			timesUpdated  = 0
			_loopTimeSum  = GetLoopTimeAverage()
			_loopTimeCount= 1
		endif
	End Method


	Method RunUpdate()
		'each loop the looptime is added to an accumulator
		'as soon as the accumulator is bigger than the time reserved
		'for an update ("timeStep"), the loop does as much updates
		'as the accumulator "fits"
		_updateAccumulator:+ _lastLoopTime/1000.0
		while(_updateAccumulator > _updateRate)
			'if there is a function connected - run it
			if _funcUpdate then _funcUpdate()

			'subtract the time reserved for an update from the accumulator
			_updateAccumulator = Max(0.0, _updateAccumulator - _updateRate)
			'for stats
			timesUpdated:+1
		wend
	End Method


	Method RunRender()
		'the time available for rendering has to consider the time
		'used for updating - so subtract that from the accumulator
		_renderAccumulator:+ Max(0, _lastLoopTime - getCurrentLoopTime()) / 1000.0

		if(_renderAccumulator > _renderRate)
			'if there is a function connected - run it
			if _funcRender then _funcRender()

			'subtract the time reserved for a render from the accumulator
			_renderAccumulator = 0

			'for stats
			timesRendered:+1
		endif
	End Method


	Method HasLimitedFPS:int()
		return _renderRate > 0
	End Method


	Method Loop()
		'compute time last loop neeeded
		'1/2: compute delta
		_lastLoopTime  = Time.GetTimeGone() - _loopBeginTime
		'2/2: store for next run
		_loopBeginTime = Time.GetTimeGone()

		'update values for FPS/UPS stats
		updateStatistics()

		'the loop time is limited to 250 ms to avoid spiral of dead
		_lastLoopTime  = Min(250, _lastLoopTime)


		RunUpdate()
		RunRender()

		'for looptime-average-calculation
		_loopTimeSum :+ GetCurrentLoopTime()
		_loopTimeCount :+ 1

		'if there was time left but no updates need to be done
		'ALTERNATIV?: hierfuer feststellen wieviel zeit ein loop haette
		'und wieviel davon benutzt worden ist... den rest dann "delayen"
		if _renderRate > 0 and (_updateRate*1000 - getCurrentLoopTime() > 0)
			delay(1)
		endif
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetDeltaTimer:TDeltaTimer()
	return TDeltaTimer.GetInstance()
End Function
