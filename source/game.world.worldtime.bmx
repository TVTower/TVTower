SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.world.worldtime.base.bmx"



'rem
Type TWorldTime Extends TWorldTimeBase {_exposeToLua="selected"}
	'time (milliseconds) used when starting
	Field _timeStart:Long = 0
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

	Const DAYLENGTH:Long      = 86400 * 1000
	Const HOURLENGTH:Long     = 3600 * 1000
	Const MINUTELENGTH:Long   = 60 * 1000
	Const SECONDLENGTH:Long   = 1000
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


	Method Init:TWorldTime(timeGone:Long = 0)
		SetTimeGone(timeGone)

		return self
	End Method


	Method Initialize:int()
		Super.Initialize()

		_timeStart = 0
		_daysPerSeason = 3
		_daysPerWeek = 7
		currentPhase = 0
		_dawnTime = -1
	End Method


	'create a time in seconds
	'attention: there are only GetDaysPerYear() days per year, not 365!
	Method GetTimeGoneForGameTime:Long(year:Int, day:Int, hour:Long, minute:Long, second:Long = 0, milliseconds:Long = 0) {_exposeToLua}
		'old:
		'year=1, day=1, hour=0, minute=1 should result in "1*yearInSeconds+1*60"
		'as it is 1 minute after end of last year - new years eve ;D
		'there is no "day 0" (as there would be no "month 0")
		'Return ((((day-1) + year*GetDaysPerYear())*24 + hour)*60 + minute)*60 + second

		'new:
		'year=1, day=1, hour=0, minute=1 should result in "1*yearInSeconds+1*dayInSeconds+1*60"
		Return (((Long(day + Long(year)*GetDaysPerYear()) * 24 + hour) * 60 + minute) * 60 + second) * SECONDLENGTH + milliseconds
	End Method


	'create a time in seconds
	'attention: month and day use real world values (12m and 365d), i.e. parameters represent a real date
	Method GetTimeGoneForRealDate:Long(year:int, month:int, day:int) {_exposeToLua}
		if day > 30 then day = 30
		local result:long = year * GetYearLength() + ((Long(30 * (month-1) + (day-1)) * GetDaysPerYear() * DAYLENGTH ) / 360)
		'print "TIME:" +year+"-"+month+"-"+day +"   "+ result +"   "+ GetFormattedGameDate(result)
		return result 
	End Method


	Method AddTimeGone:int(year:int, day:int, hour:Long, minute:Long, second:Long, milliseconds:Long = 0)
		local add:Long = milliseconds + SECONDLENGTH * (second + 60 * (minute + 60 * (hour + 24 * Long(day + year * GetDaysPerYear()))))

		_timeGone :+ add
		'also set last update
		_timeGoneLastUpdate :+ add
	End Method


	Method ModifyTime:Long(time:Long = -1, year:int=0, day:int=0, hour:Long=0, minute:Long=0, second:Long=0, millisecond:Long = 0)
		if time = -1 then time = GetTimeGone()
		return time + GetTimeGoneForGameTime(year, day, hour, minute, second, millisecond)
	End Method


	'returns:
	'mode 0: "1h5m"
	'mode 1: "1 Hour 5 Minutes"
	'mode 2: "01:05"
	'mode 3: "65m" "119m"   125min="~2h"  155min="~2.5h" 175min="~3h"
	'mode 4: "65m" "119m"   125min="2h"   155min="2.5h"  175min="3h"
	Function GetHourMinutesLeft:String(time:Long, displayMode:Int = 0)
		Local hours:Long = time / HOURLENGTH
		Local minutes:Int = (time - (hours * HOURLENGTH)) / MINUTELENGTH

		Select displayMode
			'mode 1: "1 Hour 5 Minutes"
			case 1
				if hours = 0 and minutes < 60
					If minutes = 1
						Return minutes + " " + GetLocale("MINUTE")
					Else
						Return minutes + " " + GetLocale("MINUTES")
					EndIf
				else
					if minutes = 0
						If hours = 1
							Return "1 " + GetLocale("HOUR")
						Else
							Return hours + " " + GetLocale("HOURS")
						EndIf
					else
						'do it the long way to avoid string creations
						If hours = 1 and minutes = 1
							Return "1 " + GetLocale("HOUR") + " 1 " + GetLocale("MINUTE")
						ElseIf hours = 1
							Return "1 " + GetLocale("HOUR") + " " + minutes + " " + GetLocale("MINUTES")
						ElseIf minutes = 1
							Return hours + " " + GetLocale("HOURS") + " 1 " + GetLocale("MINUTE")
						Else
							Return hours + " " + GetLocale("HOURS") + " " + minutes + " " + GetLocale("MINUTES")
						endIf
					endif
				endif

			'mode 2: "01:05"
			case 2
				If minutes < 10
					If hours < 10
						Return "0" + hours + ":0" + minutes
					Else
						Return hours + ":0" + minutes
					EndIf
				Else
					If hours < 10
						Return "0" + hours + ":" + minutes
					Else
						Return hours + ":" + minutes
					EndIf
				EndIf
				
			case 3
				If hours <= 1 and minutes < 60
					Return (hours*60 + minutes) + GetLocale("MINUTE_SHORT")
				Else
					if minutes = 0
						Return hours + GetLocale("HOUR_SHORT")
					ElseIf minutes = 30
						Return hours + ".5" + GetLocale("HOUR_SHORT")
					ElseIf minutes < 15
						Return "~~" + hours + GetLocale("HOUR_SHORT")
					ElseIf minutes < 45
						Return "~~" + hours + ".5" + GetLocale("HOUR_SHORT")
					Else
						Return "~~" + (hours+1) + GetLocale("HOUR_SHORT")
					EndIf
				endIf
			case 4
				If hours <= 1 and minutes < 60
					Return (hours*60 + minutes) + GetLocale("MINUTE_SHORT")
				Else
					if minutes < 15
						Return hours + GetLocale("HOUR_SHORT")
					ElseIf minutes >= 15 and minutes < 45
						Return hours + ".5" + GetLocale("HOUR_SHORT")
					Else
						Return (hours+1) + GetLocale("HOUR_SHORT")
					EndIf
				endIf
			default
				if minutes < 60
					Return minutes + GetLocale("MINUTE_SHORT")
				else
					Local hours:Long = time / HOURLENGTH
					Local minutes:Int = (time - (hours * HOURLENGTH)) / MINUTELENGTH
					if minutes = 0
						Return hours + GetLocale("HOUR_SHORT")
					else
						Return hours + GetLocale("HOUR_SHORT") + minutes + GetLocale("MINUTE_SHORT")
					endif
				endif
		End Select
	End Function 

	'ATTENTION: year month and day (representing a real date) are used to determine the game time
	'but the resulting time string will not correspond to that date
	'use GetTimeGoneForRealDate if this is what you want
	Method GetTimeGoneFromString:Long(str:string)
		'accepts format "y-m-d h:i"
		local dateTime:string[] = str.split(" ")
		local dateParts:string[] = dateTime[0].split("-")

		local years:Int = 0
		local months:Int = 0
		local days:Int = 0
		local hours:Int = 0
		local minutes:Int = 0
		local seconds:Int = 0
		local milliseconds:Int = 0
		
		if dateParts.length > 0 then years = int(dateParts[0])
		'subtract 1 as we _add_ time so "january" should be 0 instead
		'of 1 ...
		if dateParts.length > 1 then months = int(dateParts[1]) - 1
		'scale down the days as there are x days/year,
		if dateParts.length > 2 then days = int(dateParts[2])

		if dateTime.length > 1
			local timeParts:string[] = dateTime[1].split(":")
			if timeParts.length > 0 then hours = int(timeParts[0])
			if timeParts.length > 1 then minutes = int(timeParts[1])
			if timeParts.length > 2 then seconds = int(timeParts[2])
			if timeParts.length > 3 then milliseconds = int(timeParts[3])
		endif

		'convert "fractional values" (months per year etc) into "seconds"
		'sum them up and let the GetTimeGoneForGameTime() function handle it

		'use "long()" to ensure the calculation results in a long not int
		Local millisecondsTotal:Long = 0
		millisecondsTotal :+ Long(years) * GetDaysPerYear() * DAYLENGTH
		'months: divide by 12 as last to minimize lost remainder 
		millisecondsTotal :+ (Long(months) * GetDaysPerYear() * DAYLENGTH) / 12
		millisecondsTotal :+ Long(days) * DAYLENGTH
		millisecondsTotal :+ hours * HOURLENGTH
		millisecondsTotal :+ minutes * MINUTELENGTH
		millisecondsTotal :+ seconds * SECONDLENGTH
		millisecondsTotal :+ milliseconds

		'alternative (remove years from secondsTotal calculation)
		'GetWorldTime().GetTimeGoneForGameTime(years, 0, 0, 0, 0, milliseconds)

		Return millisecondsTotal
	End Method


	Method SetDawnTimeBegin:int(hour:int)
		'set to automatic?
		if hour = -1
			_dawnTime = -1
		else
			_dawnTime = hour * HOURLENGTH
		endif
	End Method


	Method SetStartYear:Int(year:Int=0)
		If year = 0 Then Return False
		If year < 1930 Then Return False

		Local startTime:Long = GetTimeGoneForGameTime(year,0,0,0)

		SetTimeGone(startTime)
		SetTimeStart(startTime)
	End Method


	Method GetStartYear:Int()
		return GetYear(_timeStart)
	End Method


	Method SetTimeStart(timeStart:Long)
		_timeStart = timeStart
	End Method


	Method GetTimeStart:Long() {_exposeToLua}
		Return _timeStart
	End Method


	Method GetTimeGoneAsMinute:Long(sinceStart:Int = False) {_exposeToLua}
		Local useTime:Long = _timeGone
		If sinceStart Then useTime :- _timeStart
		Return useTime / Long(MINUTELENGTH)
	End Method


	Method GetTimeGoneAsMinute:Long(sinceStart:Int = False, useTime:Long)
		if useTime <= 0 then useTime = _timeGone
		
		If sinceStart Then useTime :- _timeStart
		Return useTime / Long(MINUTELENGTH)
	End Method


	Method GetYearLength:Long() {_exposeToLua}
		return Long(DAYLENGTH) * GetDaysPerYear()
	End Method


	'get the amount of days the worldTime completed till now
	'returns completed days
	Method GetDaysRun:Int() {_exposeToLua}
		return GetDay() - GetStartDay()
	End Method


	'get the amount of days the worldTime completed till now
	'returns completed days
	Method GetDaysRun:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

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


	Method GetDayTime:Int() {_exposeToLua}
		return _timeGone mod DAYLENGTH
	End Method


	Method GetDayTime:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return useTime mod DAYLENGTH
	End Method


	'Calculated hour of the days clock (xx:00:00)
	Method GetDayHour:Int() {_exposeToLua}
		return ((_timeGone * 24) / DAYLENGTH) mod 24
	End Method


	'Calculated hour of the days clock (xx:00:00)
	Method GetDayHour:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return ((useTime * 24) / DAYLENGTH) mod 24
	End Method


	'Calculated minute of the days clock (00:xx:00)
	Method GetDayMinute:Int() {_exposeToLua}
		return (_timeGone / MINUTELENGTH) mod 60
	End Method


	'Calculated minute of the days clock (00:xx:00)
	Method GetDayMinute:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return (useTime / MINUTELENGTH) mod 60
	End Method


	'Calculated second of the days clock (00:00:xx)
	Method GetDaySecond:Int() {_exposeToLua}
		return int(_timeGone / SECONDLENGTH mod 60)
	End Method


	'Calculated second of the days clock (00:00:xx)
	Method GetDaySecond:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return int(useTime / SECONDLENGTH mod 60)
	End Method


	Method GetDayProgress:Float() {_exposeToLua}
		return Float(GetDayTime()) / DAYLENGTH
	End Method


	Method GetDayProgress:Float(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return Float(GetDayTime(useTime)) / DAYLENGTH
	End Method


	'1-4, Spring  Summer  Autumn  Winter
	Method GetSeason:Int() {_exposeToLua}
		Return GetSeason(_timeGone)
	End Method


	'1-4, Spring  Summer  Autumn  Winter
	Method GetSeason:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

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


	Method GetSeasonName:String() {_exposeToLua}
		Return GetSeasonName(_timeGone)
	End Method


	Method GetSeasonName:String(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		Select GetSeason(useTime)
			Case 1  return "SPRING"
			Case 2  return "SUMMER"
			Case 3  return "AUTUMN"
			Case 4  return "WINTER"
			default return "UNKNOWN"
		End Select
	End Method


	Method GetHour:Int() {_exposeToLua}
		return _timeGone / HOURLENGTH
	End Method


	Method GetHour:Int(useTime:Long)
		return useTime / HOURLENGTH
	End Method


	Method GetDay:Int() {_exposeToLua}
		return _timeGone / DAYLENGTH
	End Method


	Method GetDay:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		'attention: LUA uses a default param of "0"
		'-> so if exposing this function we would have to use "<=0" 
		'   instead of "<0"
		return useTime / DAYLENGTH
	End Method


	Method GetOnDay:Int() {_exposeToLua}
		Return GetDay(_timeGone) + 1
	End Method


	Method GetOnDay:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		Return GetDay(useTime) + 1
	End Method


	Method GetMonth:Int() {_exposeToLua}
		return (_timegone * 12 / GetYearLength()) mod 12 + 1
	End Method


	Method GetMonth:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return (useTime * 12 / GetYearLength()) mod 12 + 1
	End Method


	Method GetYear:Int() {_exposeToLua}
		return _timeGone / GetYearLength()
	End Method


	Method GetYear:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return useTime / GetYearLength()
	End Method


	Method GetYearProgress:Float() {_exposeToLua}
		return Float(Double(_timegone mod GetYearLength()) / GetYearLength())
	End Method


	Method GetYearProgress:Float(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return Float(Double(useTime mod GetYearLength()) / GetYearLength())
	End Method


	'returns the hour which is in 60 minutes (23:30 -> 0)
	Method GetNextHour:Int() {_exposeToLua}
		Return (GetDayHour() + 1) mod 24
	End Method


	Method GetNextMidnight:Long() 'long, do not expose for now
		Return (_timeGone + DAYLENGTH) - (_timeGone mod DAYLENGTH)
	End Method


	Method GetNextMidnight:Long(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		Return (useTime + DAYLENGTH) - (useTime mod DAYLENGTH)
	End Method


	Method GetWeekday:Int() {_exposeToLua}
		Local d:Int = GetDay()
		if d < 0
			Return ((d Mod _daysPerWeek) + _daysPerWeek) Mod _daysPerWeek
		Else
			Return d Mod _daysPerWeek
		EndIf
	End Method


	Method GetWeekday:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		Local d:Int = GetDay(useTime)
		if d < 0
			Return ((d Mod _daysPerWeek) + _daysPerWeek) Mod _daysPerWeek
		Else
			Return d Mod _daysPerWeek
		EndIf
	End Method


	Method GetWeekdayByDay:Int(_day:Int) {_exposeToLua}
		if _day < 0
			Return ((_day Mod _daysPerWeek) + _daysPerWeek) Mod _daysPerWeek
		Else
			Return _day Mod _daysPerWeek
		EndIf
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
	Method GetDayOfMonth:Int() {_exposeToLua}
		'day = 1-30
		'return floor(GetYearProgress(usetime)*360) mod 30 +1

		'add + 1 so time "0" would return day 1 of the first month in year 0
		return (((_timeGone mod GetYearLength())*360) / GetYearLength()) mod 30 + 1
	End Method
	
	
	'returns the current day in a month (30 days/month)
	Method GetDayOfMonth:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		'day = 1-30
		'return floor(GetYearProgress(usetime)*360) mod 30 +1

		'add + 1 so time "0" would return day 1 of the first month in year 0
		return (((useTime mod GetYearLength())*360) / GetYearLength()) mod 30 + 1
	End Method


	Method GetDayOfYear:Int() {_exposeToLua}
		Return (GetDay() - GetYear() * GetDaysPerYear()) + 1
	End Method


	Method GetDayOfYear:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		Return (GetDay(useTime) - GetYear(useTime) * GetDaysPerYear()) + 1
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
		Return _day + "." + GetLocale("DAY") + " (" + GetLocale("WEEK_SHORT_" + GetDayName(GetWeekdayByDay(_day))) + ")"
	End Method


	Method GetFormattedDayByTime:String(useTime:Long)
		Return GetDay(useTime) + "." + GetLocale("DAY") + " (" + GetLocale("WEEK_SHORT_" + GetDayName(GetWeekday(useTime))) + ")"
	End Method


	Method GetFormattedDayLong:String(_day:Int = -1) {_exposeToLua}
		Return GetLocale("WEEK_LONG_" + GetDayName(GetWeekdayByDay(_day)))
	End Method


	Method GetFormattedDayLongByTime:String(useTime:Long)
		Return GetLocale("WEEK_LONG_" + GetDayName(GetWeekday(useTime)))
	End Method



	'Summary: returns formatted value of actual worldtime
	Method GetFormattedTime:String(format:string="h:i") {_exposeToLua}
		Local strHours:String = GetDayHour()
		Local strMinutes:String = GetDayMinute()
		Local strSeconds:String = GetDaySecond()

		If Int(strHours) < 10 Then strHours = "0" + strHours
		If Int(strMinutes) < 10 Then strMinutes = "0" + strMinutes
		If Int(strSeconds) < 10 Then strSeconds = "0" + strSeconds
		Return format.replace("h", strHours).replace("i", strMinutes).replace("s", strSeconds)
	End Method


	'Summary: returns formatted value of actual worldtime
	Method GetFormattedTime:String(time:Long, format:string="h:i")
		Local strHours:String = GetDayHour(time)
		Local strMinutes:String = GetDayMinute(time)
		Local strSeconds:String = GetDaySecond(time)

		If Int(strHours) < 10 Then strHours = "0" + strHours
		If Int(strMinutes) < 10 Then strMinutes = "0" + strMinutes
		If Int(strSeconds) < 10 Then strSeconds = "0" + strSeconds
		Return format.replace("h", strHours).replace("i", strMinutes).replace("s", strSeconds)
	End Method


	Method GetFormattedGameDate:String() {_exposeToLua}
		return GetFormattedDate("g/h:i (d.m.y)")
	End Method


	Method GetFormattedGameDate:String(time:Long)
		return GetFormattedDate(time, "g/h:i (d.m.y)")
	End Method


	Method GetFormattedDate:String(format:string="h:i d.m.y") {_exposeToLua}
		Return GetFormattedDate(_timeGone, format)
	End Method


	Method GetFormattedDate:String(time:Long, format:string="h:i d.m.y")
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


	Method GetFormattedTimeDifference:String(timeA:Long = -1, timeB:Long, format:string="d h i")
		if timeA = -1 then timeA = GetTimeGone()
		return GetFormattedDuration(timeB - timeA, format)
	End Method


	Method GetFormattedDuration:String(duration:Long, format:string="d h i")
		local days:Int = duration / TWorldTime.DAYLENGTH
		local hours:Int = (duration - days * TWorldTime.DAYLENGTH) / TWorldTime.HOURLENGTH
		local minutes:Int = (duration - days * TWorldTime.DAYLENGTH - hours * TWorldTime.HOURLENGTH) / MINUTELENGTH

		return format.replace("d", days + GetLocale("DAY_SHORT")).replace("h", hours + GetLocale("HOUR_SHORT")).replace("i", minutes + GetLocale("MINUTE_SHORT"))
	End Method


	'returns sunrise that day - in seconds
	Method GetSunrise:Int() {_exposeToLua}
		local month:int = GetMonth()
		local dayOfMonth:int = (GetDayOfMonth() * GetDaysPerYear()) / 360
		return MINUTELENGTH * (350 + 90.0 * cos( 180.0/PI * ((month-1) * 30.5 + dayOfMonth + 8) / 58.1 ))
	End Method


	'returns sunrise that day - in seconds
	Method GetSunrise:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		local month:int = GetMonth(useTime)
		'stretch/shrink the days to our "days per year"
		'resulting day:
		'ex.: 20 daysPerYear -> 19 daysPerDay -> day30 = "day 2"
		'ex.: 12 daysPerYear -> 30 daysPerDay -> day30 = "day 1"
		local dayOfMonth:int = (GetDayOfMonth(useTime) * GetDaysPerYear()) / 360

		return MINUTELENGTH * (350 + 90.0 * cos( 180.0/PI * ((month-1) * 30.5 + dayOfMonth + 8) / 58.1 ))
	End Method


	'returns sunset that day - in seconds
	Method GetSunset:Int() {_exposeToLua}
		local month:int = GetMonth()
		'for details: see GetSunrise
		local dayOfMonth:int = (GetDayOfMonth() * GetDaysPerYear()) / 360

		return MINUTELENGTH * (1075 + 90.0 * sin( 180.0/PI * ((month-1) * 30.5 + dayOfMonth - 83) / 58.1 ))
	End Method


	'returns sunset that day - in seconds
	Method GetSunset:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		local month:int = GetMonth(useTime)
		'for details: see GetSunrise
		local dayOfMonth:int = (GetDayOfMonth(useTime) * GetDaysPerYear()) / 360

		return MINUTELENGTH * (1075 + 90.0 * sin( 180.0/PI * ((month-1) * 30.5 + dayOfMonth - 83) / 58.1 ))
	End Method


	'returns seconds of daylight that day
	Method GetDayLightLength:Int() {_exposeToLua}
		Return GetSunset() - GetSunrise()
	End Method


	'returns seconds of daylight that day
	Method GetDayLightLength:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		Return GetSunset(useTime) - GetSunrise(useTime)
	End Method


	Method GetDawnDuration:Int() {_exposeToLua}
		'Return 0.15 * DAYLENGTH
		Return DAYLENGTH / 100 * 15
	End Method


	Method GetDayDuration:Int() {_exposeToLua}
		Return GetDayLightLength()
	End Method


	Method GetDayDuration:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		Return GetDayLightLength(useTime)
	End Method


	Method GetDuskDuration:Int() {_exposeToLua}
		'return 0.15 * DAYLENGTH
		Return DAYLENGTH / 100 * 15
	End Method


	Method GetNightDuration:Int() {_exposeToLua}
		'0.7 = rest of the day without dusk/dawn
		'Return 0.7 * DAYLENGTH - GetDayLightLength()
		Return (DAYLENGTH / 10 * 7) - GetDayLightLength()
	End Method


	Method GetNightDuration:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		'0.7 = rest of the day without dusk/dawn
		'Return 0.7 * DAYLENGTH - GetDayLightLength()
		Return (DAYLENGTH / 10 * 7) - GetDayLightLength(useTime)
	End Method


	Method GetDawnPhaseBegin:Int() {_exposeToLua}
		if _dawnTime > 0 then return _dawnTime
		'have to end with sunrise
		return GetSunrise() - GetDawnDuration()
	End Method


	Method GetDawnPhaseBegin:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		if _dawnTime > 0 then return _dawnTime
		'have to end with sunrise
		return GetSunrise(useTime) - GetDawnDuration()
	End Method


	Method GetDayPhaseBegin:Int() {_exposeToLua}
		'return GetDawnPhaseBegin() + GetDawnDuration()
		'this is the same (but less calculation)
		return GetSunrise()
	End Method


	Method GetDayPhaseBegin:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		'return GetDawnPhaseBegin(useTime) + GetDawnDuration()
		'this is the same (but less calculation)
		return GetSunrise(useTime)
	End Method


	Method GetDuskPhaseBegin:Int() {_exposeToLua}
		'return GetDayPhaseBegin() + GetDayDuration()
		'this is the same (but less calculation)
		return GetSunrise() + GetDayDuration()
	End Method


	Method GetDuskPhaseBegin:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		'return GetDayPhaseBegin(useTime) + GetDayDuration(useTime)
		return GetSunrise(useTime) + GetDayDuration(useTime)
	End Method


	Method GetNightPhaseBegin:Int() {_exposeToLua}
		return GetDuskPhaseBegin() + GetDuskDuration()
	End Method


	Method GetNightPhaseBegin:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return GetDuskPhaseBegin(useTime) + GetDuskDuration()
	End Method


	Method IsNight:Int() {_exposeToLua}
		return GetDayPhase() = DAYPHASE_NIGHT
	End Method


	Method IsNight:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return GetDayPhase(useTime) = DAYPHASE_NIGHT
	End Method


	Method IsDawn:Int() {_exposeToLua}
		return GetDayPhase() = DAYPHASE_DAWN
	End Method


	Method IsDawn:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return GetDayPhase(useTime) = DAYPHASE_DAWN
	End Method


	Method IsDay:Int() {_exposeToLua}
		return GetDayPhase() = DAYPHASE_DAY
	End Method


	Method IsDay:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		return GetDayPhase(useTime) = DAYPHASE_DAY
	End Method


	Method IsDusk:Int() {_exposeToLua}
		return GetDayPhase() = DAYPHASE_DUSK
	End Method

	Method IsDusk:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

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
	Method GetDayPhase:Int() {_exposeToLua}
		'cache the current dayTime to avoid multiple calculations
		local dayTime:Int = GetDayTime()

		if dayTime >= GetDawnPhaseBegin() and dayTime < GetDayPhaseBegin()
			return DAYPHASE_DAWN
		elseif dayTime >= GetDayPhaseBegin() and dayTime < GetDuskPhaseBegin()
			return DAYPHASE_DAY
		elseif dayTime >= GetDuskPhaseBegin() and dayTime < GetNightPhaseBegin()
			return DAYPHASE_DUSK
		elseif dayTime >= GetNightPhaseBegin() or dayTime < GetDawnPhaseBegin()
			return DAYPHASE_NIGHT
		else
			return -1
		endif
	End Method


	'returns the phase of the given time's day
	'value is calculated dynamically, no cache is used!
	Method GetDayPhase:Int(useTime:Long)
		if useTime <= 0 then useTime = _timeGone

		'cache the current dayTime to avoid multiple calculations
		local dayTime:Int = GetDayTime(useTime)

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


	Method GetDayPhaseText:string() {_exposeToLua}
		Return GetDayPhaseText(_timeGone)
	End Method


	Method GetDayPhaseText:string(useTime:Long)
		Select GetDayPhase(useTime)
			case DAYPHASE_DAWN  return "DAWN"
			case DAYPHASE_DUSK  return "DUSK"
			case DAYPHASE_DAY   return "DAY"
			case DAYPHASE_NIGHT return "NIGHT"
			default             return "UKNOWN"
		End Select
	End Method


	Method GetDayPhaseProgress:Float() {_exposeToLua}
		Select GetDayPhase()
			case DAYPHASE_NIGHT
				return (GetDayTime() - GetNightPhaseBegin()) / Float(GetNightDuration())
			case DAYPHASE_DAWN
				return (GetDayTime() - GetDawnPhaseBegin()) / Float(GetDawnDuration())
			case DAYPHASE_DAY
				return (GetDayTime() - GetDayPhaseBegin()) / Float(GetDayDuration())
			case DAYPHASE_DUSK
				return (GetDayTime() - GetDuskPhaseBegin()) / Float(GetDuskDuration())
		End Select
		return 0
	End Method


	Method GetDayPhaseProgress:Float(useTime:Long)
		Select GetDayPhase(useTime)
			case DAYPHASE_NIGHT
				return (GetDayTime(useTime) - GetNightPhaseBegin(useTime)) / Float(GetNightDuration(useTime))
			case DAYPHASE_DAWN
				return (GetDayTime(useTime) - GetDawnPhaseBegin(useTime)) / Float(GetDawnDuration())
			case DAYPHASE_DAY
				return (GetDayTime(useTime) - GetDayPhaseBegin(useTime)) / Float(GetDayDuration(useTime))
			case DAYPHASE_DUSK
				return (GetDayTime(useTime) - GetDuskPhaseBegin(useTime)) / Float(GetDuskDuration())
		End Select
		return 0
	End Method


	Method CalcTime_HoursFromNow:Long(nowTime:Long=-1, hoursMin:int, hoursMax:int = -1)
		If nowTime = -1 Then nowTime = _timeGone

		if hoursMax = -1
			return nowTime + hoursMin * HOURLENGTH
		else
			return nowTime + RandRange(hoursMin, hoursMax) * HOURLENGTH
		endif
	End Method


	Method CalcTime_DaysFromNowAtHour:Long(nowTime:Long=-1, daysBegin:int, daysEnd:int = -1, atHourMin:int, atHourMax:int = -1)
		If nowTime = -1 Then nowTime = _timeGone

		local result:Long
		if daysEnd = -1
			result = GetTimeGoneForGameTime(0, GetDay(nowTime) + daysBegin, 0, 0)
		else
			result = GetTimeGoneForGameTime(0, GetDay(nowTime) + RandRange(daysBegin, daysEnd), 0, 0)
		endif

		if atHourMax = -1
			result :+ atHourMin * HOURLENGTH
		else
			'convert into minutes:
			'for 7-9 this is 7:00, 7:01 ... 8:59, 9:00
			result :+ RandRange(atHourMin*60, atHourMax*60) * MINUTELENGTH
		endif

		return result
	End Method


	Method CalcTime_WeekdayAtHour:Long(nowTime:Long=-1, weekday:int, atHourMin:int, atHourMax:int = -1)
		If nowTime = -1 Then nowTime = _timeGone

		local daysTillWeekday:int = (7 - GetWeekDay(nowTime) + weekday) mod 7
		if GetWeekDay(nowTime) = weekday then daysTillWeekday = 7

		local result:Long = GetTimeGoneForGameTime(0, GetDay(nowTime) + daysTillWeekday, 0, 0)

		if atHourMax = -1
			result :+ atHourMin * HOURLENGTH
		else
			'convert into minutes:
			'for 7-9 this is 7:00, 7:01 ... 8:59, 9:00
			result :+ RandRange(atHourMin*60, atHourMax*60) * MINUTELENGTH
		endif

		return result
	End Method

	'to allow relative years, use -1000000 as default max year; for month/day 0=random, -1 = same as min
	Method CalcTime_ExactDate:Long(nowTime:Long=-1, yearMin:int=0, yearMax:int=-1000000, monthMin:int=0, monthMax:int=-1, dayMin:int=0, dayMax:int=-1)
		If nowTime = -1 Then nowTime = _timeGone

		'print "IN nowTime="+nowTime+"  yearMin="+yearMin+"  yearMax="+yearMax+"  monthMin="+monthMin+"  monthMax="+monthMax+"  dayMin="+dayMin+"  dayMax="+dayMax

		yearMin = max(-1000, yearMin)
		'relative mode, there won't be an time entry before 1000 AD.
		If yearMin < 1000 Then yearMin = GetYear(nowTime) + yearMin
		If yearMax = -1000000
			yearMax = yearMin
		ElseIf yearMax < 1000
			yearMax = GetYear(nowTime) + yearMax
		EndIf
		If yearMax < yearMin Then yearMax = yearMin


		If monthMin <= 0
			monthMin = RandRange(1, 12)
		ElseIf monthMin > 12
			monthMin = 12
		EndIf
		If monthMax < 0
			monthMax = monthMin
		ElseIf monthMax = 0
			If yearMin = yearMax
				monthMax = RandRange(monthMin, 12)
			Else
				monthMax = RandRange(1, 12)
			EndIf
		ElseIf monthMax > 12
			monthMax = 12
		EndIf
		If yearMin = yearMax And monthMax < monthMin Then monthMax = monthMin

		If dayMin <= 0
			dayMin = RandRange(1, 30) 'Sorry february!
		ElseIf dayMin > 30
			dayMin = 30
		EndIf
		If dayMax < 0
			dayMax = dayMin
		ElseIf dayMax = 0
			If yearMin = yearMax And monthMin = monthMax
				dayMax = RandRange(dayMin, 30)
			Else
				dayMax = RandRange(1, 30)
			EndIf
		ElseIf dayMax > 30
			dayMax = 30
		EndIf

		If yearMin = yearMax And monthMax = monthMin And dayMax <= dayMin
			'no randomness - mindate=maxdate
			return GetTimeGoneForRealDate(yearMin, monthMin, dayMin)
		Else
			'determine random time between min and max

			'could abuse nowTime as start to save new variable
			Local start:Long = GetTimeGoneForRealDate(yearMin, monthMin, dayMin)
			'could abuse any min variable as diff to save new variable
			Local diff:Int = (GetTimeGoneForRealDate(yearMax, monthMax, dayMax) - start)/MINUTELENGTH
			diff = RandRange(0, Int(diff))
			Return start + diff*MINUTELENGTH
		EndIf
	End Method


	'use "-1000000" as default to allow relative values - which often include "-1"
	Method CalcTime_ExactGameDate:Long(nowTime:Long=-1, yearMin:int, yearMax:int=-1000000, gameDayMin:int=0, gameDayMax:int=-1000000, hourMin:int=0, hourMax:int=-1000000, minuteMin:int=0 , minuteMax:int=-1000000)
		If nowTime = -1 Then nowTime = _timeGone

		'use the "min"-values to store the final values for calculation
		'to save some variables
		if yearMax <> yearMin and yearMax >= 0 then yearMin = RandRange(yearMin, yearMax)

		if gameDayMin = -1 then gameDayMin = RandRange(1, GetDaysPerYear())
		if gameDayMax <> gameDayMin and gameDayMax > -1000000 then gameDayMin = RandRange(gameDayMin, gameDayMax)

		if hourMin = -1 then hourMin = RandRange(0, 23)
		if hourMax <> hourMin and hourMax > -1000000 then hourMin = RandRange(hourMin, hourMax)

		if minuteMin = -1 then minuteMin = RandRange(0, 59)
		if minuteMax <> minuteMin and minuteMax > -1000000 then minuteMin = RandRange(minuteMin, minuteMax)


		return GetTimeGoneForGameTime(yearMin, gameDayMin -1, hourMin, minuteMin)
	End Method


	Method CalcTime_Auto:long(nowTime:Long=-1, timeType:int, timeValues:int[])
		if not timeValues or timeValues.length < 1 then return -1

		If nowTime = -1 Then nowTime = _timeGone

		'what kind of happen time data do we have?
		Select timeType
			'now
			case 0
				Return nowTime

			'1 = "A"-"B" hours from now
			case 1
				if timeValues.length > 1
					return CalcTime_HoursFromNow(nowTime, timeValues[0], timeValues[1])
				else
					return CalcTime_HoursFromNow(nowTime, timeValues[0], -1)
				endif
			'2 = "A"-"B" days from now at "C":00 - "D":00 o'clock
			case 2
				if timeValues.length <= 1 then return nowTime

				if timeValues.length = 2
					return CalcTime_DaysFromNowAtHour(nowTime, timeValues[0], -1, timeValues[1])
				elseif timeValues.length = 3
					return CalcTime_DaysFromNowAtHour(nowTime, timeValues[0], timeValues[1], timeValues[2])
				else
					return CalcTime_DaysFromNowAtHour(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[3])
				endif
			'3 = next "weekday A" from "B":00 - "C":00 o'clock
			case 3
				if timeValues.length <= 1 then return -1

				if timeValues.length = 2
					return CalcTime_WeekdayAtHour(nowTime, timeValues[0], -1, timeValues[1])
				elseif timeValues.length >= 3
					return CalcTime_WeekdayAtHour(nowTime, timeValues[0], timeValues[1], timeValues[2])
				endif
			'4 = next year Y, month M, day D
			case 4
				if timeValues.length < 1
					return -1
				else
					Select timeValues.length
						Case 1   return CalcTime_ExactDate(nowTime, timeValues[0])
						Case 2   return CalcTime_ExactDate(nowTime, timeValues[0], , timeValues[1])
						Default  return CalcTime_ExactDate(nowTime, timeValues[0], , timeValues[1], , timeValues[2])
					End Select
				endif
			'5 = next year Y-Y2, month M-M2, day D-D2
			case 5
				if timeValues.length < 1
					return -1
				else
					Select timeValues.length
						Case 1   return CalcTime_ExactDate(nowTime, timeValues[0], timeValues[0])
						Case 2   return CalcTime_ExactDate(nowTime, timeValues[0], timeValues[1])
						Case 3   return CalcTime_ExactDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[2])
						Case 4   return CalcTime_ExactDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[3])
						Case 5   return CalcTime_ExactDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[4])
						Default  return CalcTime_ExactDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5])
					End Select
				endif
			'6 = next year Y, gameday GD, hour H, minute I
			case 6
				if timeValues.length < 1
					return -1
				else
					Select timeValues.length
						Case 1   return CalcTime_ExactGameDate(nowTime, timeValues[0])
						Case 2   return CalcTime_ExactGameDate(nowTime, timeValues[0], , timeValues[1])
						Case 3   return CalcTime_ExactGameDate(nowTime, timeValues[0], , timeValues[1], , timeValues[2])
						Default  return CalcTime_ExactGameDate(nowTime, timeValues[0], , timeValues[1], , timeValues[2], , timeValues[3])
					End Select
				endif
			'7 = next year Y-Y2, gameday GD-GD2, hour H-H2, minute I-I2
			case 7
				if timeValues.length < 1
					return -1
				else
					Select timeValues.length
						Case 1   return CalcTime_ExactGameDate(nowTime, timeValues[0], timeValues[0])
						Case 2   return CalcTime_ExactGameDate(nowTime, timeValues[0], timeValues[1])
						Case 3   return CalcTime_ExactGameDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[2])
						Case 4   return CalcTime_ExactGameDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[3])
						Case 5   return CalcTime_ExactGameDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[4])
						Case 6   return CalcTime_ExactGameDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5])
						Case 7   return CalcTime_ExactGameDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5], timeValues[6], timeValues[6])
						Default  return CalcTime_ExactGameDate(nowTime, timeValues[0], timeValues[1], timeValues[2], timeValues[3], timeValues[4], timeValues[5], timeValues[6], timeValues[7])
					End Select
				endif

			'8 = next work day (mo-fr) + daysToAdd to current, hour H-H2, minute I-I2
			case 8
				if timeValues.length < 1
					return -1
				else
					local nowDay:Int = GetWeekday()
					local nextDay:Int = nowDay + timeValues[0]
					local nextDayWeekIndex:Int = nextDay mod 7
					'weekend?
					if nextDayWeekIndex = 5
						nextDay :+ 2
					elseif nextDayWeekIndex = 6
						nextDay :+ 1
					endif

					if timeValues.length < 3
						return CalcTime_DaysFromNowAtHour(nowTime, nextDay - nowDay, -1, 0, -1)
					else
						return CalcTime_DaysFromNowAtHour(nowTime, nextDay - nowDay, -1, timeValues[1], timeValues[2])
					endif
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

