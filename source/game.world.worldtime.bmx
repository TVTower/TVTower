SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.world.worldtime.base.bmx"



'rem
Type TWorldTime Extends TWorldTimeBase {_exposeToLua="selected"}
	'time (seconds) used when starting
	Field _timeStart:Double = 0.0
	'how many days does each season have? (year = 4 * value)
	Field _daysPerSeason:int = 3
	'how many days does a week have?
	Field _daysPerWeek:int = 7

	'current "phase" of the day: 0=Dawn  1=Day  2=Dusk  3=Night
	Field currentPhase:int
	'time at which the dawn starts
	'negative = automatic calculation
	Field _dawnTime:Int = -1

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


	Method New()
		SetStartYear(1900)
	End Method


	Method Init:TWorldTime(timeGone:Double = 0.0)
		SetTimeGone(timeGone)

		return self
	End Method


	Method Initialize:int()
		Super.Initialize()

		_timeStart = 0:double
		_daysPerSeason = 3
		_daysPerWeek = 7
		currentPhase = 0
		_dawnTime = -1
	End Method


	'create a time in seconds
	'attention: there are only GetDaysPerYear() days per year, not 365!
	Method MakeTime:Double(year:Int, day:Int, hour:Long, minute:Long, second:Long = 0) {_exposeToLua}
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


	Method AddTimeGone:int(year:int, day:int, hour:Double, minute:Double, second:Double)
		local add:Double = second + 60*(minute + 60*(hour + 24*(day + year*GetDaysPerYear())))

		_timeGone :+ add
		'also set last update
		_timeGoneLastUpdate :+ add
	End Method


	Method ModifyTime:Long(time:Long = -1, year:int=0, day:int=0, hour:Long=0, minute:Long=0, second:Long=0)
		if time = -1 then time = GetTimeGone()
		return time + Long(MakeTime(year, day, hour, minute, second))
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


		return GetWorldTime().MakeTime(years, int(days), hours, minutes, seconds)
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


	Method SetTimeStart(timeStart:Double)
		_timeStart = timeStart
	End Method


	Method GetTimeStart:Double() {_exposeToLua}
		Return _timeStart
	End Method


	Method GetTimeGoneAsMinute:Double(sinceStart:Int=False) {_exposeToLua}
		Local useTime:Double = _timeGone
		If sinceStart Then useTime = (_timeGone - _timeStart)
		Return Int(Floor(useTime / 60))
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

		return floor(useTime / HOURLENGTH)
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


	Method GetNextMidnight:Long(useTime:Double = -1.0) {_exposeToLua}
		if Long(useTime) <= 0 then useTime = _timeGone

		Return (useTime + DAYLENGTH) - (useTime mod DAYLENGTH)
	End Method


	Method GetWeekday:Int(useTime:Double = -1.0) {_exposeToLua}
		Return Max(0, GetDay(useTime)) Mod _daysPerWeek
	End Method


	Method GetWeekdayByDay:Int(_day:Int = -1) {_exposeToLua}
		If _day < 0 Then _day = GetOnDay()
		Return Max(0,_day) Mod _daysPerWeek
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


	Method GetDayFromName:int(name:string) {_exposeToLua}
		Select name.ToUpper()
			Case "MONDAY"    Return 0
			Case "TUESDAY"   Return 1
			Case "WEDNESDAY" Return 2
			Case "THURSDAY"  Return 3
			Case "FRIDAY"    Return 4
			Case "SATURDAY"  Return 5
			Case "SUNDAY"    Return 6
			Default          Return 0
		End Select
	End Method

	'returns day of the week including gameday
	Method GetFormattedDay:String(_day:Int = -1) {_exposeToLua}
		if _day = -1 then _day = GetDaysRun()
		Return _day+"."+GetLocale("DAY")+" ("+ GetLocale("WEEK_SHORT_"+GetDayName(GetWeekdayByDay(_day)))+ ")"
	End Method


	Method GetFormattedDayLong:String(_day:Int = -1) {_exposeToLua}
		Return GetLocale("WEEK_LONG_"+GetDayName(GetWeekdayByDay(_day)))
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


	Method GetFormattedGameDate:String(time:Double = -1, format:string="g/h:i (d.m.y)") {_exposeToLua}
		return GetFormattedDate(time, format)
	End Method


	Method GetFormattedDate:String(time:Double = -1, format:string="h:i d.m.y") {_exposeToLua}
		Local strYear:String = GetYear(time)
		Local strMonth:String = GetMonth(time)
		Local strDay:String = GetDayOfMonth(time)
		Local strGameDay:String = GetDaysRun(time) + 1
		Local strWeekDay:String = GetWeekdayByDay(GetDaysRun(time))
		Local strWeekDayLong:String = GetDayName(GetWeekdayByDay(GetDaysRun(time)) )

		If Int(strMonth) < 10 Then strMonth = "0"+strMonth
		If Int(strDay) < 10 Then strDay = "0"+strDay
		Return GetFormattedTime(time, format).replace("d", strDay).replace("m", strMonth).replace("y", strYear).replace("g", strGameDay).replace("w", strWeekDayLong).replace("W", strWeekDay)
	End Method


	Method GetFormattedTimeDifference:String(timeA:Double = -1, timeB:Double, format:string="d h i") {_exposeToLua}
		if timeA = -1 then timeA = GetTimeGone()
		return GetFormattedDuration(timeB - timeA, format)
	End Method


	Method GetFormattedDuration:String(duration:Double, format:string="d h i") {_exposeToLua}
		local days:int = duration / TWorldTime.DAYLENGTH
		local hours:int = (duration - days*TWorldTime.DAYLENGTH) / TWorldTime.HOURLENGTH
		local minutes:int = (duration - days*TWorldTime.DAYLENGTH - hours*TWorldTime.HOURLENGTH) / 60

		return format.replace("d", days + GetLocale("DAY_SHORT")).replace("h", hours + GetLocale("HOUR_SHORT")).replace("i", minutes + GetLocale("MINUTE_SHORT"))
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



	Method CalcTime_HoursFromNow:Long(hoursMin:int, hoursMax:int = -1)
		if hoursMax = -1
			return GetTimeGone() + hoursMin * HOURLENGTH
		else
			return GetTimeGone() + RandRange(hoursMin, hoursMax) * HOURLENGTH
		endif
	End Method


	Method CalcTime_DaysFromNowAtHour:Long(daysBegin:int, daysEnd:int = -1, atHourMin:int, atHourMax:int = -1)
		local result:Long
		if daysEnd = -1
			result = MakeTime(0, GetDay() + daysBegin, 0, 0)
		else
			result = MakeTime(0, GetDay() + RandRange(daysBegin, daysEnd), 0, 0)
		endif

		if atHourMax = -1
			result :+ atHourMin * TWorldTime.HOURLENGTH
		else
			'convert into minutes:
			'for 7-9 this is 7:00, 7:01 ... 8:59, 9:00
			result :+ RandRange(atHourMin*60, atHourMax*60) * 60
		endif

		return result
	End Method


	Method CalcTime_WeekdayAtHour:Long(weekday:int, atHourMin:int, atHourMax:int = -1)
		local daysTillWeekday:int = (7 - GetWeekDay() + weekday) mod 7
		if GetWeekDay() = weekday then daysTillWeekday = 7

		local result:Long = MakeTime(0, GetDay() + daysTillWeekday, 0, 0)

		if atHourMax = -1
			result :+ atHourMin * TWorldTime.HOURLENGTH
		else
			'convert into minutes:
			'for 7-9 this is 7:00, 7:01 ... 8:59, 9:00
			result :+ RandRange(atHourMin*60, atHourMax*60) * 60
		endif

		return result
	End Method


	Method CalcTime_ExactDate:Long(yearMin:int, yearMax:int=-1000000, monthMin:int=-1000000, monthMax:int=-1000000, dayMin:int=-1000000, dayMax:int=-1000000, hourMin:int=-1000000, hourMax:int=-1000000, minuteMin:int=-1000000, minuteMax:int=-1000000)
		'use the "min"-values to store the final values for calculation
		'to save some variables
		if yearMax <> yearMin and yearMax > -1000000 then yearMin = RandRange(yearMin, yearMax)

		if monthMin = -1 then monthMin = RandRange(1, 12)
		if monthMax <> dayMin and monthMax > -1000000 then monthMin = RandRange(monthMin, monthMax)

		if dayMin = -1 then dayMin = RandRange(1, 30) 'Sorry february!
		if dayMax <> dayMin and dayMax > -1000000 then dayMin = RandRange(dayMin, dayMax)

		if hourMin = -1 then hourMin = RandRange(0, 23)
		if hourMax <> hourMin and hourMax > -1000000 then hourMin = RandRange(hourMin, hourMax)

		if minuteMin = -1 then minuteMin = RandRange(0, 59)
		if minuteMax <> minuteMin and minuteMax > -1000000 then minuteMin = RandRange(minuteMin, minuteMax)


		'relative mode, there wont be an time entry before 1000 AD.
		if yearMin < 1000
			return MakeRealTime(GetYear() + yearMin, monthMin, dayMin, hourMin, minuteMin)
		else
			return MakeRealTime(yearMin, monthMin, dayMin, hourMin, minuteMin)
		endif
	End Method


	'use "-1000000" as default to allow relative values - which often include "-1"
	Method CalcTime_ExactGameDate:Long(yearMin:int, yearMax:int=-1000000, gameDayMin:int=-1000000, gameDayMax:int=-1000000, hourMin:int=-1000000, hourMax:int=-1000000, minuteMin:int=-1000000, minuteMax:int=-1000000)
		'use the "min"-values to store the final values for calculation
		'to save some variables
		if yearMax <> yearMin and yearMax >= 0 then yearMin = RandRange(yearMin, yearMax)

		if gameDayMin = -1 then gameDayMin = RandRange(1, GetDaysPerYear())
		if gameDayMax <> gameDayMin and gameDayMax > -1000000 then gameDayMin = RandRange(gameDayMin, gameDayMax)

		if hourMin = -1 then hourMin = RandRange(0, 23)
		if hourMax <> hourMin and hourMax > -1000000 then hourMin = RandRange(hourMin, hourMax)

		if minuteMin = -1 then minuteMin = RandRange(0, 59)
		if minuteMax <> minuteMin and minuteMax > -1000000 then minuteMin = RandRange(minuteMin, minuteMax)


		return MakeTime(yearMin, gameDayMin, hourMin, minuteMin)
	End Method


	Method CalcTime_Auto:long(timeType:int, timeValues:int[])
		if not timeValues or timeValues.length < 1 then return -1

		'what kind of happen time data do we have?
		Select timeType
			'now
			case 0
				return GetWorldTime().GetTimeGone()

			'1 = "A"-"B" hours from now
			case 1
				if timeValues.length > 1
					return CalcTime_HoursFromNow(timeValues[0], timeValues[1])
				else
					return CalcTime_HoursFromNow(timeValues[0], -1)
				endif
			'2 = "A"-"B" days from now at "C":00 - "D":00 o'clock
			case 2
				if timeValues.length <= 1 then return -1

				if timeValues.length = 2
					return CalcTime_DaysFromNowAtHour(timeValues[0], -1, timeValues[1])
				elseif timeValues.length = 3
					return CalcTime_DaysFromNowAtHour(timeValues[0], timeValues[1], timeValues[2])
				else
					return CalcTime_DaysFromNowAtHour(timeValues[0], timeValues[1], timeValues[2], timeValues[3])
				endif
			'3 = next "weekday A" from "B":00 - "C":00 o'clock
			case 3
				if timeValues.length <= 1 then return -1

				if timeValues.length = 2
					return CalcTime_WeekdayAtHour(timeValues[0], -1, timeValues[1])
				elseif timeValues.length >= 3
					return CalcTime_WeekdayAtHour(timeValues[0], timeValues[1], timeValues[2])
				endif
			'4 = next year Y, month M, day D, hour H, minute I
			case 4
				if timeValues.length < 1
					return -1
				else
					Select timeValues.length
						Case 1   return CalcTime_ExactDate(timeValues[0])
						Case 2   return CalcTime_ExactDate(timeValues[0], , timeValues[1])
						Case 3   return CalcTime_ExactDate(timeValues[0], , timeValues[1], , timeValues[2])
						Case 4   return CalcTime_ExactDate(timeValues[0], , timeValues[1], , timeValues[2], , timeValues[3])
						Default  return CalcTime_ExactDate(timeValues[0], , timeValues[1], , timeValues[2], , timeValues[3], , timeValues[4])
					End Select
				endif
			'5 = next year Y-Y2, month M-M2, day D-D2, hour H-H2, minute I-I2
			case 5
				if timeValues.length < 1
					return -1
				else
					Select timeValues.length
						Case 1   return CalcTime_ExactDate(timeValues[0], timeValues[0])
						Case 2   return CalcTime_ExactDate(timeValues[0], timeValues[1])
						Case 3   return CalcTime_ExactDate(timeValues[0], timeValues[1], timeValues[2], timeValues[2])
						Case 4   return CalcTime_ExactDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3])
						Case 5   return CalcTime_ExactDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[4])
						Case 6   return CalcTime_ExactDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5])
						Case 7   return CalcTime_ExactDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5], timeValues[6], timeValues[6])
						Case 8   return CalcTime_ExactDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5], timeValues[6], timeValues[7])
						Case 9   return CalcTime_ExactDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5], timeValues[6], timeValues[7], timeValues[8], timeValues[8])
						Default  return CalcTime_ExactDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5], timeValues[6], timeValues[7], timeValues[8], timeValues[9])
					End Select
				endif
			'6 = next year Y, gameday GD, hour H, minute I
			case 6
				if timeValues.length < 1
					return -1
				else
					Select timeValues.length
						Case 1   return CalcTime_ExactGameDate(timeValues[0])
						Case 2   return CalcTime_ExactGameDate(timeValues[0], , timeValues[1])
						Case 3   return CalcTime_ExactGameDate(timeValues[0], , timeValues[1], , timeValues[2])
						Default  return CalcTime_ExactGameDate(timeValues[0], , timeValues[1], , timeValues[2], , timeValues[3])
					End Select
				endif
			'7 = next year Y-Y2, gameday GD-GD2, hour H-H2, minute I-I2
			case 7
				if timeValues.length < 1
					return -1
				else
					Select timeValues.length
						Case 1   return CalcTime_ExactGameDate(timeValues[0], timeValues[0])
						Case 2   return CalcTime_ExactGameDate(timeValues[0], timeValues[1])
						Case 3   return CalcTime_ExactGameDate(timeValues[0], timeValues[1], timeValues[2], timeValues[2])
						Case 4   return CalcTime_ExactGameDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3])
						Case 5   return CalcTime_ExactGameDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[4])
						Case 6   return CalcTime_ExactGameDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5])
						Case 7   return CalcTime_ExactGameDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5], timeValues[6], timeValues[6])
						Default  return CalcTime_ExactGameDate(timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5], timeValues[6], timeValues[7])
					End Select
				endif

		End Select
		return -1
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

		'actually update the time
		Super.Update()
	End Method
End Type
'endrem

'===== CONVENIENCE ACCESSOR =====
Function GetWorldTime:TWorldTime()
	Return TWorldTime.GetInstance()
End Function

