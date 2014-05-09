Import "Dig/base.util.deltatimer.bmx"
Import "Dig/base.util.localization.bmx"

Type TGameTime {_exposeToLua="selected"}
	Field daysPerYear:Int = 14	{_exposeToLua}
	'time (minutes) used when starting the game
	Field timeStart:Double = 0.0
	'time (minutes) in game, not reset every day
	Field timeGone:Double = 0.0
	'time (minutes) in game of the last update (enables calculation of missed minutes)
	Field timeGoneLastUpdate:Double = -1.0
	Field daysPlayed:Int = 0
	'Speed of the game in "game minutes per real-time second"
	Field speed:Float = 1.0
	Field paused:Int = False

	Global _instance:TGameTime


	Function GetInstance:TGameTime()
		if not _instance then _instance = new TGameTime
		return _instance
	End Function


	Method Update:int()
		'speed is given as a factor "game-time = x * real-time"
		timeGone :+ GetDeltaTimer().GetDelta() * GetGameMinutesPerSecond()
		'initialize last update value if still at default value
		if timeGoneLastUpdate < 0 then timeGoneLastUpdate = timeGone
	End Method


	'returns how many game minutes equal to one real time second
	Method GetGameMinutesPerSecond:Float()
		Return speed*(Not paused)
	End Method


	'returns how many seconds pass for one game minute
	Method GetSecondsPerGameMinute:Float()
		If speed*(Not paused) = 0 Then Return 0
		Return 1.0 / (speed *(Not paused))
	End Method


	Method GetDayName:String(day:Int, longVersion:Int=0) {_exposeToLua}
		Local versionString:String = "SHORT"
		If longVersion = 1 Then versionString = "LONG"

		Select day
			Case 0	Return GetLocale("WEEK_"+versionString+"_MONDAY")
			Case 1	Return GetLocale("WEEK_"+versionString+"_TUESDAY")
			Case 2	Return GetLocale("WEEK_"+versionString+"_WEDNESDAY")
			Case 3	Return GetLocale("WEEK_"+versionString+"_THURSDAY")
			Case 4	Return GetLocale("WEEK_"+versionString+"_FRIDAY")
			Case 5	Return GetLocale("WEEK_"+versionString+"_SATURDAY")
			Case 6	Return GetLocale("WEEK_"+versionString+"_SUNDAY")
			Default	Return "not a day"
		EndSelect
	End Method


	'Summary: returns day of the week including gameday
	Method GetFormattedDay:String(_day:Int = -5) {_exposeToLua}
		Return _day+"."+GetLocale("DAY")+" ("+GetDayName( Max(0,_day-1) Mod 7, 0)+ ")"
	End Method


	Method GetFormattedDayLong:String(_day:Int = -1) {_exposeToLua}
		If _day < 0 Then _day = GetDay()
		Return GetDayName( Max(0,_day-1) Mod 7, 1)
	End Method


	'Summary: returns formatted value of actual gametime
	Method GetFormattedTime:String(time:Double=0) {_exposeToLua}
		Local strHours:String = GetHour(time)
		Local strMinutes:String = GetMinute(time)

		If Int(strHours) < 10 Then strHours = "0"+strHours
		If Int(strMinutes) < 10 Then strMinutes = "0"+strMinutes
		Return strHours+":"+strMinutes
	End Method


	Method GetWeekday:Int(_day:Int = -1) {_exposeToLua}
		If _day < 0 Then _day = Self.GetDay()
		Return Max(0,_day-1) Mod 7
	End Method


	Method MakeTime:Double(year:Int,day:Int,hour:Int,minute:Int) {_exposeToLua}
		'year=1,day=1,hour=0,minute=1 should result in "1*yearInSeconds+1"
		'as it is 1 minute after end of last year - new years eve ;D
		'there is no "day 0" (as there would be no "month 0")

		Return (((day-1) + year*daysPerYear)*24 + hour)*60 + minute
	End Method


	Method GetTimeGone:Double() {_exposeToLua}
		Return timeGone
	End Method


	Method GetTimeStart:Double() {_exposeToLua}
		Return timeStart
	End Method


	Method GetYear:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = timeGone
		_time = Floor(_time / (24 * 60 * daysPerYear))
		Return Int(_time)
	End Method


	Method GetDayOfYear:Int(_time:Double = 0) {_exposeToLua}
		Return (GetDay(_time) - GetYear(_time)*daysPerYear)
	End Method


	'get the amount of days played (completed! - that's why "-1")
	Method GetDaysPlayed:Int() {_exposeToLua}
		Return daysPlayed
'		return self.GetDay(self.timeGone - Self.timeStart) - 1
	End Method


	Method GetStartDay:Int() {_exposeToLua}
		Return GetDay(timeStart)
	End Method


	Method GetDay:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = timeGone
		_time = Floor(_time / (24 * 60))
		'we are ON a day (it is not finished yet)
		'if we "ceil" the time, we would ignore 1.0 as this would
		'not get rounded to 2.0 like 1.01 would do
		Return 1 + Int(_time)
	End Method


	Method GetHour:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = timeGone
		'remove days from time
		_time = _time Mod (24*60)
		'hours = how many times 60 minutes fit into rest time
		Return Int(Floor(_time / 60))
	End Method


	Method GetMinute:Int(_time:Double = 0) {_exposeToLua}
		If _time = 0 Then _time = timeGone
		'remove days from time
		_time = _time Mod (24*60)
		'minutes = rest not fitting into hours
		Return Int(_time) Mod 60
	End Method


	Method GetNextHour:Int() {_exposeToLua}
		Local nextHour:Int = GetHour()+1
		If nextHour > 24 Then Return nextHour - 24
		Return nextHour
	End Method


	Method SetStartYear:Int(year:Int=0)
		If year = 0 Then Return False
		If year < 1930 Then Return False

		timeGone	= MakeTime(year,1,0,0)
		timeStart	= MakeTime(year,1,0,0)
	End Method

End Type

'===== CONVENIENCE ACCESSOR =====
Function GetGameTime:TGameTime()
	Return TGameTime.GetInstance()
End Function
