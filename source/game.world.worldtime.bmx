SuperStrict
Import "Dig/base.util.deltatimer.bmx"
Import "Dig/base.util.localization.bmx"

'rem
Type TWorldTime {_exposeToLua="selected"}
	'time (seconds) used when starting 
	Field _timeStart:Double = 0.0
	'time (seconds) gone at all 
	Field _timeGone:Double
	'time (seconds) of the last update
	'(enables calculation of missed time between two updates)
	Field _timeGoneLastUpdate:Double = -1.0
	'how many days does each season have? (year = 4 * value)
	Field _daysPerSeason:int = 3
	'how many days does a week have?
	Field _daysPerWeek:int = 7
	 
	'Speed of the world in "virtual seconds per real-time second"
	'1.0 = realtime - a virtual day would take 86400 real-time seconds
	'3600.0 = a virtual day takes 24 real-time seconds
	'60.0 : 1 virtual minute = 1 real-time second
	Field _timeFactor:Float = 60.0
	Field _timeFactorMod:Float = 1.0
	'current "phase" of the day: 0=Dawn  1=Day  2=Dusk  3=Night
	Field currentPhase:int
	'time at which the dawn starts
	'negative = automatic calculation
	Field _dawnTime:Int = -1
	'does time go by?
	Field _paused:Int = False

	Global _instance:TWorldTime

	Const DAYLENGTH:int      = 86400
	Const HOURLENGTH:int     = 3600
	Const DAYPHASE_DAWN:int	 = 0
	Const DAYPHASE_DAY:int	 = 1
	Const DAYPHASE_DUSK:int	 = 2
	Const DAYPHASE_NIGHT:int = 3
	Const SEASON_SPRING:int  = 1
	Const SEASON_SUMMER:int  = 2
	Const SEASON_AUTUMN:int  = 3
	Const SEASON_WINTER:int  = 4
	

	Function GetInstance:TWorldTime()
		if not _instance then _instance = new TWorldTime
		return _instance
	End Function
	

	Method Init:TWorldTime(timeGone:Double = 0.0)
		SetTimeGone(timeGone)

		return self
	End Method


	Method Initialize:int()
		_timeStart = 0:double
		_timeGone = 0:double
		_timeGoneLastUpdate = -1:double
		_daysPerSeason = 4
		_daysPerWeek = 7
		_timeFactor = 60.0
		currentPhase = 0
		_dawnTime = -1
		_paused = False
	End Method


	'create a time in seconds
	'attention: there are only GetDaysPerYear() days per year, not 365!
	Method MakeTime:Double(year:Int, day:Int, hour:Int, minute:Int, second:int = 0) {_exposeToLua}
		'old:
		'year=1, day=1, hour=0, minute=1 should result in "1*yearInSeconds+1*60"
		'as it is 1 minute after end of last year - new years eve ;D
		'there is no "day 0" (as there would be no "month 0")
		'Return ((((day-1) + year*GetDaysPerYear())*24 + hour)*60 + minute)*60 + second

		'new:
		'year=1, day=1, hour=0, minute=1 should result in "1*yearInSeconds+1*dayInSeconds+1*60"
		Return ((double(day + year*GetDaysPerYear())*24 + hour)*60 + minute)*60 + second
	End Method


	'create a time in seconds
	'attention: month and day use real world values (12m and 365d)
	Method MakeRealTime:Double(year:int, month:int, day:int, hour:int, minute:int, second:int = 0) {_exposeToLua}
		Return ((double((30*month + day)*GetDaysPerYear()/360.0 + year*GetDaysPerYear())*24 + hour)*60 + minute)*60 + second
	End Method


	Method AddTime:int(year:int, day:int, hour:Double, minute:Double, second:Double)
		local add:Double = second + 60*(minute + 60*(hour + 24*(day + year*GetDaysPerYear())))
		
		_timeGone :+ add
		'also set last update
		_timeGoneLastUpdate :+ add
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


	Method GetTimeGoneFromString:Long(str:string)
		'accepts format "y-m-d h:i"
		local dateTime:string[] = str.split(" ")
		local dateParts:string[] = dateTime[0].split("-")

		local years:int = 0
		local months:int = 0
		local days:Float = 0
		local hours:int = 0
		local minutes:int = 0
		local seconds:int = 0
		

		if dateParts.length > 0 then years = int(dateParts[0])
		'subtract 1 as we _add_ time so "january" should be 0 instead
		'of 1 ...
		if dateParts.length > 1 then days = int(dateParts[1]) - 1
		'scale down the days as there are x days/year, 
		if dateParts.length > 2 then days :+ int(dateParts[2]) * (GetDaysPerYear()/365.0)

		if dateTime.length > 1
			local timeParts:string[] = dateTime[1].split(":")
			if timeParts.length > 0 then hours = int(timeParts[0])
			if timeParts.length > 1 then minutes = int(timeParts[1])
			if timeParts.length > 2 then seconds = int(timeParts[2])
		endif
		'give remainders of a rounded day value
		local addHours:Float = 24.0 * (days - floor(days))
		local addMinutes:Float = 60.0 * (addHours - floor(addHours))

		'add remainder to hours/minutes
		days = floor(days)
		hours :+ floor(addHours)
		minutes :+ floor(addMinutes)

		
		return GetWorldTime().MakeTime(years, days, hours, minutes, seconds)
	End Method
	

	Method IsPaused:int()
		return self._paused
		'return GetTimeFactor() = 0
	End Method


	Method SetPaused:int(bool:int)
		self._paused = bool
	End Method


	Method SetDawnTimeBegin:int(hour:int)
		'set to automatic?
		if hour = -1
			_dawnTime = -1
		else
			_dawnTime = hour * 3600
		endif
	End Method


	Method SetStartYear:Int(year:Int=0)
		If year = 0 Then Return False
		If year < 1930 Then Return False

		SetTimeGone(MakeTime(year,0,0,0))
		SetTimeStart(MakeTime(year,0,0,0))
	End Method


	Method GetStartYear:Int()
		return GetYear(_timeStart)
	End Method
		

	Method SetTimeGone(timeGone:Double)
		_timeGone = timeGone
		'also set last update
		_timeGoneLastUpdate = timeGone
	End Method


	Method GetTimeGone:Double() {_exposeToLua}
		Return _timeGone
	End Method
	
	
	Method GetTimeGoneAsMinute:Double(sinceStart:Int=False) {_exposeToLua}
		Local useTime:Double = _timeGone
		If sinceStart Then useTime = (_timeGone - _timeStart)	
		Return Int(Floor(useTime / 60))
	End Method	


	Method SetTimeStart(timeStart:Double)
		_timeStart = timeStart
	End Method


	Method GetTimeStart:Double() {_exposeToLua}
		Return _timeStart
	End Method


	Method GetYearLength:int() {_exposeToLua}
		return DAYLENGTH * GetDaysPerYear()
	End Method


	'get the amount of days the worldTime completed till now
	'returns completed days
	Method GetDaysRun:Int(useTime:Double= -1.0) {_exposeToLua}
		return GetDay(useTime) - GetStartDay()
	End Method


	'returns the hour world started running
	Method GetStartHour:Int() {_exposeToLua}
		Return GetHour(_timeStart)
	End Method

	
	'returns the day world started running
	Method GetStartDay:Int() {_exposeToLua}
		Return GetDay(_timeStart)
	End Method


	Method GetDayTime:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return useTime mod DAYLENGTH
	End Method

	
	'Calculated hour of the days clock (xx:00:00)
	Method GetDayHour:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return int((floor((usetime / DAYLENGTH) * 24)) mod 24)
	End Method


	'Calculated minute of the days clock (00:xx:00)
	Method GetDayMinute:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return int((floor(useTime / 60)) mod 60)
	End Method


	'Calculated second of the days clock (00:00:xx)
	Method GetDaySecond:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return int(useTime mod 60)
	End Method
	

	Method GetDayProgress:Float(useTime:Double = -1.0) {_exposeToLua}
		return GetDayTime(useTime) / DAYLENGTH
	End Method


	'1-4, Spring  Summer  Autumn  Winter
	Method GetSeason:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		'would lead to "month 1-3 = spring"
		'return ceil(useTime / GetYearLength() * 4) mod 4

		local month:int = GetMonth(useTime)
		Select month
			Case  3, 4, 5  return 1
			Case  6, 7, 8  return 2
			Case  9,10,11  return 3
			Case 12, 1, 2  return 4
		End Select
		return 0
	End Method


	Method GetSeasonName:string(useTime:Double = -1.0) {_exposeToLua}
		Select GetSeason(useTime)
			Case 1  return "SPRING"
			Case 2  return "SUMMER"
			Case 3  return "AUTUMN"
			Case 4  return "WINTER"
			default return "UNKNOWN"
		End Select
	End Method


	'attention: LUA uses a default param of "0"
	'-> so for this and other functions we have to use "<=0" instead of "<0"
	Method GetHour:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return floor(useTime / (DAYLENGTH/24))
	End Method


	'attention: LUA uses a default param of "0"
	'-> so for this and other functions we have to use "<=0" instead of "<0"
	Method GetDay:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return floor(useTime / DAYLENGTH)
	End Method


	'attention: LUA uses a default param of "0"
	'-> so for this and other functions we have to use "<=0" instead of "<0"
	Method GetOnDay:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return floor(useTime / DAYLENGTH) + 1
	End Method


	Method GetMonth:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return floor(useTime / GetYearLength() * 12) mod 12 +1
	End Method


	Method GetYear:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return floor(useTime / GetYearLength())
	End Method


	Method GetYearProgress:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return (useTime / GetYearLength()) mod floor(useTime)
	End Method


	'returns the hour which is in 60 minutes (23:30 -> 0)
	Method GetNextHour:Int() {_exposeToLua}
		Return (GetDayHour()+1 mod 24)
	End Method


	Method GetWeekday:Int(_day:Int = -1) {_exposeToLua}
		If _day < 0 Then _day = GetOnDay()
		Return Max(0,_day-1) Mod _daysPerWeek
	End Method


	Method GetDaysPerYear:int() {_exposeToLua}
		return _daysPerSeason * 4
	End Method


	Method GetDaysPerSeason:int()
		return _daysPerSeason
	End Method


	Method GetDaysPerWeek:int() {_exposeToLua}
		return _daysPerWeek
	End Method


	'returns the current day in a month (30 days/month)
	Method GetDayOfMonth:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		'local month:int = ceil(GetYearProgress(useTime)*12)
		'day = 1-30
		return floor(GetYearProgress(usetime)*360) mod 30 +1
	End Method


	Method GetDayOfYear:Int(_time:Double = 0) {_exposeToLua}
		Return (GetDay(_time) - GetYear(_time) * GetDaysPerYear()) + 1
	End Method


	'this does only work if "_daysPerWeek" is 7 or lower
	Method GetDayName:String(day:Int) {_exposeToLua}
		Select day
			Case 0	Return "MONDAY"
			Case 1	Return "TUESDAY"
			Case 2	Return "WEDNESDAY"
			Case 3	Return "THURSDAY"
			Case 4	Return "FRIDAY"
			Case 5	Return "SATURDAY"
			Case 6	Return "SUNDAY"
			Default	Return "UNKNOWN"
		End Select
	End Method


	'returns day of the week including gameday
	Method GetFormattedDay:String(_day:Int = -1) {_exposeToLua}
		if _day = -1 then _day = GetDaysRun()
		Return _day+"."+GetLocale("DAY")+" ("+ GetLocale("WEEK_SHORT_"+GetDayName(GetWeekday(_day)))+ ")"
	End Method


	Method GetFormattedDayLong:String(_day:Int = -1) {_exposeToLua}
		Return GetLocale("WEEK_LONG_"+GetDayName(GetWeekday(_day)))
	End Method


	'Summary: returns formatted value of actual worldtime
	Method GetFormattedTime:String(time:Double = -1, format:string="h:i") {_exposeToLua}
		Local strHours:String = GetDayHour(time)
		Local strMinutes:String = GetDayMinute(time)
		Local strSeconds:String = GetDaySecond(time)
		
		If Int(strHours) < 10 Then strHours = "0"+strHours
		If Int(strMinutes) < 10 Then strMinutes = "0"+strMinutes
		If Int(strSeconds) < 10 Then strSeconds = "0"+strSeconds
		Return format.replace("h", strHours).replace("i", strMinutes).replace("s", strSeconds)
	End Method


	Method GetFormattedDate:String(time:Double = -1, format:string="h:i d.m.y") {_exposeToLua}
		Local strYear:String = GetYear(time)
		Local strMonth:String = GetMonth(time)
		Local strDay:String = GetDayOfMonth(time)
		
		If Int(strMonth) < 10 Then strMonth = "0"+strMonth
		If Int(strDay) < 10 Then strDay = "0"+strDay
		Return GetFormattedTime(time, format).replace("d", strDay).replace("m", strMonth).replace("y", strYear)
	End Method

	'returns sunrise that day - in seconds
	Method GetSunrise:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		local month:int = GetMonth(useTime)
		local dayOfMonth:int = GetDayOfMonth(useTime)
		'stretch/shrink the days to our "days per year"
		'resulting day:
		'ex.: 20 daysPerYear -> 19 daysPerDay -> day30 = "day 2"
		'ex.: 12 daysPerYear -> 30 daysPerDay -> day30 = "day 1"
		dayOfMonth = floor(dayOfMonth / (360 / GetDaysPerYear()))

		return 60 * (350 + 90.0 * cos( 180.0/PI * ((month-1)*30.5 + dayOfMonth +8)/58.1 ))
	End Method


	'returns sunset that day - in seconds
	Method GetSunset:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		local month:int = GetMonth(useTime)
		'for details: see GetSunRise
		local dayOfMonth:int = floor(GetDayOfMonth(useTime) / (360 / GetDaysPerYear()))

		return 60* (1075 + 90.0 * sin( 180.0/PI * ((month-1)*30.5 + dayOfMonth -83)/58.1 ))
	End Method


	'returns seconds of daylight that day
	Method GetDayLightLength:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return GetSunset(useTime) - GetSunrise(useTime)
		
		'return 0.35 * WorldTime.DAYLENGTH
	End Method
	

	Method GetDawnDuration:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return 0.15 * DAYLENGTH
	End Method


	Method GetDayDuration:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return GetDayLightLength(useTime)
'		return 0.35 * WorldTime.DAYLENGTH
	End Method


	Method GetDuskDuration:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return 0.15 * DAYLENGTH
	End Method


	Method GetNightDuration:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		'0.7 = rest of the day without dusk/dawn
		return 0.7 * DAYLENGTH - GetDayLightLength()
		'return 0.35 * DAYLENGTH
	End Method


	Method GetDawnPhaseBegin:Float(useTime:Double = -1.0) {_exposeToLua}
		if _dawnTime > 0 then return _dawnTime
		'have to end with sunrise
		return GetSunrise(useTime) - GetDawnDuration(useTime)
		'return 5*3600 'dawnTime
	End Method


	Method GetDayPhaseBegin:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return GetDawnPhaseBegin(useTime) + GetDawnDuration(useTime)
	End Method


	Method GetDuskPhaseBegin:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return GetDayPhaseBegin(useTime) + GetDayDuration(useTime)
	End Method


	Method GetNightPhaseBegin:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		return GetDuskPhaseBegin(useTime) + GetDuskDuration(useTime)
	End Method


	Method IsNight:int(useTime:Double = -1.0) {_exposeToLua}
		return GetDayPhase(useTime) = DAYPHASE_NIGHT
	End Method


	Method IsDawn:int(useTime:Double = -1.0) {_exposeToLua}
		return GetDayPhase(useTime) = DAYPHASE_DAWN
	End Method


	Method IsDay:int(useTime:Double = -1.0) {_exposeToLua}
		return GetDayPhase(useTime) = DAYPHASE_DAY
	End Method


	Method IsDusk:int(useTime:Double = -1.0) {_exposeToLua}
		return GetDayPhase(useTime) = DAYPHASE_DUSK
	End Method


	'Sets currentPhase to "dawn"
	Method SetDawn:int()
		currentPhase = DAYPHASE_DAWN
	End Method


	'Sets currentPhase to "day"
	Method SetDay:int()
		currentPhase = DAYPHASE_DAY
	End Method


	'Sets currentPhase to "dusk"
	Method SetDusk:int()
		currentPhase = DAYPHASE_DUSK
	End Method


	'Sets currentPhase to "night"
	Method SetNight:int()
		currentPhase = DAYPHASE_NIGHT
	End Method


	'returns the phase of the given time's day
	'value is calculated dynamically, no cache is used!
	Method GetDayPhase:int(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone
		'cache the current dayTime to avoid multiple calculations
		local dayTime:double = GetDayTime(useTime)

		if dayTime >= GetDawnPhaseBegin(useTime) and dayTime < GetDayPhaseBegin(useTime)
			return DAYPHASE_DAWN
		elseif dayTime >= GetDayPhaseBegin(useTime) and dayTime < GetDuskPhaseBegin(useTime)
			return DAYPHASE_DAY
		elseif dayTime >= GetDuskPhaseBegin(useTime) and dayTime < GetNightPhaseBegin(useTime)
			return DAYPHASE_DUSK
		elseif dayTime >= GetNightPhaseBegin(useTime) or dayTime < GetDawnPhaseBegin(useTime)
			return DAYPHASE_NIGHT
		else
			return -1
		endif
	End Method

	
	Method GetDayPhaseText:string(useTime:Double = -1.0) {_exposeToLua}
		Select GetDayPhase(useTime)
			case DAYPHASE_DAWN  return "DAWN"
			case DAYPHASE_DUSK  return "DUSK"
			case DAYPHASE_DAY   return "DAY"
			case DAYPHASE_NIGHT return "NIGHT"
			default             return "UKNOWN"
		End Select
	End Method


	Method GetDayPhaseProgress:Float(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) = -1.0 then useTime = _timeGone

		Select GetDayPhase(useTime)
			case DAYPHASE_NIGHT
				return (GetDayTime(useTime) - GetNightPhaseBegin(useTime)) / GetNightDuration(useTime)
			case DAYPHASE_DAWN
				return (GetDayTime(useTime) - GetDawnPhaseBegin(useTime)) / GetDawnDuration(useTime)
			case DAYPHASE_DAY
				return (GetDayTime(useTime) - GetDayPhaseBegin(useTime)) / GetDayDuration(useTime)
			case DAYPHASE_DUSK
				return (GetDayTime(useTime) - GetDuskPhaseBegin(useTime)) / GetDuskDuration(useTime)
		End Select
		return 0
	End Method	


	Method Update:int()
		local newPhase:int = GetDayPhase()
		'inform about the start of a phase
		if currentPhase <> newPhase
			Select GetDayPhase()
				Case DAYPHASE_NIGHT
					SetNight()
					'print GetDayHour()+":"+GetDayMinute()+"  NIGHT" + "  NEXT DAWN: "+GetDayHour(GetDawnPhaseBegin())+":"+GetDayMinute(GetDawnPhaseBegin())
				Case DAYPHASE_DUSK
					SetDusk()
					'print GetDayHour()+":"+GetDayMinute()+"  DUSK" + "  NEXT NIGHT: "+GetDayHour(GetNightPhaseBegin())+":"+GetDayMinute(GetNightPhaseBegin())
				Case DAYPHASE_DAY
					SetDay()
					'print GetDayHour()+":"+GetDayMinute()+"  DAY" + "  NEXT DUSK: "+GetDayHour(GetDuskPhaseBegin())+":"+GetDayMinute(GetDuskPhaseBegin())
				Case DAYPHASE_DAWN
					SetDawn()
					'print GetDayHour()+":"+GetDayMinute()+"  DAWN" + "  NEXT DAY: "+GetDayHour(GetDayPhaseBegin())+":"+GetDayMinute(GetDayPhaseBegin())
			End Select
		endif
		'Update the time (includes pausing)
		_timeGone :+ GetDeltaTimer().GetDelta() * GetTimeFactor()

		'backup last update time
'		_timeGoneLastUpdate = _timeGone
		'initialize last update value if still at default value
'		if _timeGoneLastUpdate < 0 then _timeGoneLastUpdate = _timeGone
	End Method
End Type
'endrem

'===== CONVENIENCE ACCESSOR =====
Function GetWorldTime:TWorldTime()
	Return TWorldTime.GetInstance()
End Function

