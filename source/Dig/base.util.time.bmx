Rem
	====================================================================
	Time related helpers
	====================================================================

	Time:
	BRL Millisecs() can "wrap" to a negative value (if your uptime
	is bigger than 25 days).

	This class provides an alternative function to Millisecs() called
	MillisecsLong().

	TStopWatch:
	Also a class TStopWatch is provided for easing the process of
	measuring the interval of between a starting time and now.


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
Import Brl.retro



Type Time
	'=== GETTIMEGONE ===
	Global startTime:Long = 0
	Global appStartTime:Long = 0

	'=== MILLISECSLONG
	Global MilliSeconds:Long=0
	Global LastMilliSeconds:Long = Time.MilliSecsLong()


	'returns the time gone since the computer was started
	Function MilliSecsLong:Long()
		'code from:
		'http://www.blitzbasic.com/Community/post.php?topic=84114&post=950107

		'Convert to 32-bit unsigned
		Local Milli:Long = Long(Millisecs()) + 2147483648:Long
		 'Accumulate 2^32
		If Milli < LastMilliSeconds Then MilliSeconds :+ 4294967296:long

		LastMilliSeconds = Milli
		Return MilliSeconds + Milli
	End Function


	'set startTime so that GetTimeGone would return "timeGone"
	Function SetTimeGone:int(timeGone:long)
		startTime = MilliSecsLong() - timeGone
	End Function
	

	'returns the time gone since the first call to "GetTimeGone()"
	Function GetTimeGone:Long()
		if startTime = 0 then startTime = MilliSecsLong()

		return (MilliSecsLong() - startTime)
	End Function


	'returns the time gone since the start of the app
	Function GetAppTimeGone:Long()
		return (MilliSecsLong() - appStartTime)
	End Function
	
	

	'%H ... 24 Hour | %I ... 12 Hour
	'%M ... Minutes
	'%S ... Seconds
	Function GetSystemTime:String(format:String="%d %B %Y")
		Local time:Byte[256]
		Local buff:Byte[256]
		time_(time)
		strftime_(buff, 256, format, localtime_(time))
		Return String.FromCString(buff)
	End Function
End Type
'initialize on app start
Time.appStartTime = Time.MilliSecsLong()


'a simple stop watch to measure a time interval
Type TStopWatch
	Field startTime:int = -1
	Field stopTime:int = -1
	Field pausedTime:int = 0


	Method Init:TStopWatch()
		Reset()

		return self
	End Method


	Method Reset()
		startTime = Time.GetTimeGone()
		stopTime = -1
		pausedTime = 0
	End Method


	Method Stop()
		stopTime = Time.GetTimeGone()
	End Method


	Method Start()
		if startTime = -1 then Reset()
		if stopTime >= 0
			pausedTime :+ Time.GetTimeGone() - stopTime
			stopTime = -1
		endif
	End Method


	Method GetTime:int()
		if startTime = -1 then return 0
		if stopTime >= 0 then return (stopTime - startTime) - pausedTime
		return (Time.GetTimeGone() - startTime) - pausedTime
	End Method
End Type



'for things happening every X moments
Type TIntervalTimer
	'happens every ...
	field interval:int = 0
	'happens every ...
	field intervalToUse:int	= 0
	'plus duration
	field actionTime:int = 0
	'value the interval can "change" on GetIntervall()
	field randomnessMin:int = 0
	field randomnessMax:int = 0
	'time when event last happened
	field timer:Long = 0


	Function Create:TIntervalTimer(interval:int, actionTime:int = 0, randomnessMin:int = 0, randomnessMax:int = 0)
		return new TIntervalTimer.Init(interval, actionTime, randomnessMin, randomnessMax)
	End Function


	Method Init:TIntervalTimer(interval:int, actionTime:int = 0, randomnessMin:int = 0, randomnessMax:int = 0)
		self.interval = interval
		self.actionTime = actionTime
		self.SetRandomness(randomnessMin, randomnessMax)
		'set timer
		self.reset()
		return self
	End Method


	Function _GetTimeGone:Long()
		return Time.GetTimeGone()
	End Function


	Method GetInterval:int()
		return intervalToUse
	End Method


	Method SetInterval(value:int, resetTimer:int=false)
		interval = value
		if resetTimer then Reset()
	End Method


	Method SetRandomness(minValue:int, maxValue:int)
		randomnessMin = minValue
		randomnessMax = maxValue
	End Method


	Method SetActionTime(value:int, resetTimer:int=false)
		actionTime = value
		if resetTimer then Reset()
	End Method


	'returns TRUE if interval is gone (ignores action time)
	'action time could be eg. "show text for actiontime-seconds EVERY interval-seconds"
	Method doAction:int()
		local timeLeft:Double = _GetTimeGone() - (timer + GetInterval() )
		return ( timeLeft > 0 AND timeLeft < actionTime )
	End Method


	'returns TRUE if interval and duration is gone (ignores duration)
	Method isExpired:int()
		return ( timer + GetInterval() + actionTime <= _GetTimeGone() )
	End Method


	Method getTimeGoneInPercents:float()
		local restTime:int = Max(0, getTimeUntilExpire())
		if restTime = 0 then return 1.0
		return 1.0 - (restTime / float(GetInterval()))
	End Method


	Method getTimeUntilActionInPercents:Float()
		return 1.0 - Min(1.0, Max(0.0, getTimeUntilAction() / GetInterval()))
	End Method


	Method getTimeUntilExpire:Double()
		return timer + GetInterval() + actionTime - _GetTimeGone()
	End Method


	Method getTimeUntilAction:Double()
		return timer + GetInterval() - _GetTimeGone()
	End Method


	Method reachedHalftime:int()
		return ( timer + 0.5*(GetInterval() + actionTime) <= _GetTimeGone() )
	End Method


	Method expire()
		timer = -GetInterval()
	End Method


	Method reset()
		intervalToUse = interval + rand(randomnessMin, randomnessMax)

		timer = _GetTimeGone()
	End Method
End Type