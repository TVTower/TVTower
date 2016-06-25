SuperStrict
Import "Dig/base.util.deltatimer.bmx"


Type TBuildingTime {_exposeToLua="selected"}
	'time (seconds) gone at all 
	Field _timeGone:Double
	'time (seconds) of the last update
	'(enables calculation of missed time between two updates)
	Field _timeGoneLastUpdate:Double = -1.0
	 
	'Speed of the world in "virtual seconds per real-time second"
	'1.0 = realtime - a virtual day would take 86400 real-time seconds
	'3600.0 = a virtual day takes 24 real-time seconds
	'60.0 : 1 virtual minute = 1 real-time second
	Field _timeFactor:Float = 1.0
	Field _timeFactorMod:Float = 1.0
	'does time go by?
	Field _paused:Int = False

	Global _instance:TBuildingTime


	Function GetInstance:TBuildingTime()
		if not _instance then _instance = new TBuildingTime
		return _instance
	End Function
	

	Method Init:TBuildingTime(timeGone:Double = 0.0)
		SetTimeGone(timeGone)

		return self
	End Method


	Method Initialize:int()
		_timeGone = 0:double
		_timeGoneLastUpdate = -1:double
		_timeFactor = 60.0
		_paused = False
	End Method


	Method SetTimeFactor:int(timeFactor:Float)
		self._timeFactor = Max(0.0, timeFactor)
	End Method


	Method AdjustTimeFactor:int(adjustBy:Float = 0.0)
		SetTimeFactor(_timeFactor + adjustBy)
	End Method


	'returns how many "virtual seconds" equal to one "real time second"
	Method GetTimeFactor:Float()
		Return self._timeFactor * self.GetTimeFactorMod() * (not _paused)
	End Method


	Method GetRawTimeFactor:Float()
		Return self._timeFactor
	End Method


	Method SetTimeFactorMod:int(timeFactorMod:Float)
		self._timeFactorMod = Max(0.0, timeFactorMod)
	End Method


	Method AdjustTimeFactorMod:int(adjustBy:Float = 0.0)
		SetTimeFactorMod(_timeFactorMod + adjustBy)
	End Method


	Method GetTimeFactorMod:Float()
		Return self._timeFactorMod
	End Method


	'returns how many "virtual minutes" equal to one "real time second"
	Method GetVirtualMinutesPerSecond:Float()
		Return GetTimeFactor()/60.0
	End Method


	'returns how many "real time seconds" pass for one "virtual minute"
	Method GetSecondsPerVirtualMinute:Float()
		If GetTimeFactor() = 0 Then Return 0
		Return 1.0 / GetTimeFactor()
	End Method


	Method IsPaused:int()
		return self._paused
	End Method


	Method SetPaused:int(bool:int)
		self._paused = bool
	End Method


	Method SetTimeGone(timeGone:Double)
		_timeGone = timeGone
		'also set last update
		_timeGoneLastUpdate = timeGone
	End Method


	Method GetTimeGone:Double() {_exposeToLua}
		Return _timeGone
	End Method


	Method GetMillisecondsGone:Double() {_exposeToLua}
		Return _timeGone * 1000
	End Method


	Method Update:int()
		'Update the time (includes pausing)
		_timeGone :+ GetDeltaTimer().GetDelta() * GetTimeFactor()

		'backup last update time
		_timeGoneLastUpdate = _timeGone
	End Method
End Type
'endrem

'===== CONVENIENCE ACCESSOR =====
Function GetBuildingTime:TBuildingTime()
	Return TBuildingTime.GetInstance()
End Function





'for things happening every X moments
Type TBuildingIntervalTimer
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


	Function Create:TBuildingIntervalTimer(interval:int, actionTime:int = 0, randomnessMin:int = 0, randomnessMax:int = 0)
		local obj:TBuildingIntervalTimer = new TBuildingIntervalTimer
		obj.interval = interval
		obj.actionTime = actionTime
		obj.SetRandomness(randomnessMin, randomnessMax)
		'set timer
		obj.reset()
		return obj
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
		local timeLeft:Double = GetBuildingTime().GetMillisecondsGone() - (timer + GetInterval() )
		return ( timeLeft > 0 AND timeLeft < actionTime )
	End Method


	'returns TRUE if interval and duration is gone (ignores duration)
	Method isExpired:int()
		return ( timer + GetInterval() + actionTime <= GetBuildingTime().GetMillisecondsGone() )
	End Method


	Method getTimeGoneInPercents:float()
		local restTime:int = Max(0, getTimeUntilExpire())
		if restTime = 0 then return 1.0
		return 1.0 - (restTime / float(GetInterval()))
	End Method


	Method getTimeUntilExpire:Double()
		return timer + GetInterval() + actionTime - GetBuildingTime().GetMillisecondsGone()
	End Method


	Method reachedHalftime:int()
		return ( timer + 0.5*(GetInterval() + actionTime) <= GetBuildingTime().GetMillisecondsGone() )
	End Method


	Method expire()
		timer = -GetInterval()
	End Method


	Method reset()
		intervalToUse = interval + rand(randomnessMin, randomnessMax)

		timer = GetBuildingTime().GetMillisecondsGone()
	End Method
End Type


Function GetBuildingTimeTimeFactor:Float()
	Return TBuildingTime.GetInstance().GetTimeFactor()
End Function