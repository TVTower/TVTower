SuperStrict
Import "game.gamescriptexpression.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameinformation.base.bmx"
Import "Dig/base.util.persongenerator.bmx"


GetGameScriptExpressionOLD().RegisterHandler("TIME_YEAR", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_DAY", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_HOUR", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_MINUTE", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_WEEKDAY", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_SEASON", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_DAYSPLAYED", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_YEARSPLAYED", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_DAYOFMONTH", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_DAYOFYEAR", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_MONTH", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_ISNIGHT", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_ISDAWN", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_ISDAY", GameScriptExpression_Handle_Time)
GetGameScriptExpressionOLD().RegisterHandler("TIME_ISDUSK", GameScriptExpression_Handle_Time)

GetGameScriptExpressionOLD().RegisterHandler("STATIONMAP_MAPNAME", GameScriptExpression_Handle_StationMap)
GetGameScriptExpressionOLD().RegisterHandler("STATIONMAP_MAPNAMESHORT", GameScriptExpression_Handle_StationMap)
GetGameScriptExpressionOLD().RegisterHandler("STATIONMAP_POPULATION", GameScriptExpression_Handle_StationMap)

GetGameScriptExpressionOLD().RegisterHandler("PERSONGENERATOR_FIRSTNAME", GameScriptExpression_Handle_PersonGenerator)
GetGameScriptExpressionOLD().RegisterHandler("PERSONGENERATOR_LASTNAME", GameScriptExpression_Handle_PersonGenerator)
GetGameScriptExpressionOLD().RegisterHandler("PERSONGENERATOR_NAME", GameScriptExpression_Handle_PersonGenerator)
GetGameScriptExpressionOLD().RegisterHandler("PERSONGENERATOR_TITLE", GameScriptExpression_Handle_PersonGenerator)




Function GameScriptExpression_Handle_Time:string(variable:string, params:string[], resultElementType:int var)
	resultElementType = TScriptExpressionOLD.ELEMENTTYPE_NUMERIC

	Select variable.ToLower()
		case "time_year"
			return string( GetWorldTime().GetYear() )
		case "time_day"
			return string( GetWorldTime().GetDay() )
		case "time_hour"
			return string( GetWorldTime().GetDayHour() )
		case "time_minute"
			return string( GetWorldTime().GetDayMinute() )
		case "time_daysplayed"
			return string( GetWorldTime().GetDaysRun() )
		case "time_yearsplayed"
			return string( floor(GetWorldTime().GetDaysRun() / GetWorldTime().GetDaysPerYear()) )
		case "time_weekday"
			'attention, use the weekday depending on game start (day 1
			'of a game is always a monday... ani: no it is not)
			'return string( GetWorldTime().GetWeekdayByDay( GetWorldTime().GetDaysRun() ) )
			'this would return weekday of the exact start date
			'so 1985/1/1 is a different weekday than 1986/1/1
			return string( GetWorldTime().GetWeekday() )
		case "time_season"
			return string( GetWorldTime().GetSeason() )
		case "time_dayofmonth"
			return string( GetWorldTime().GetDayOfMonth() )
		case "time_dayofyear"
			return string( GetWorldTime().GetDayOfYear() )
		case "time_month"
			return string( GetWorldTime().GetMonth() )
		case "time_isnight"
			return string( GetWorldTime().IsNight() )
		case "time_isdawn"
			return string( GetWorldTime().IsDawn() )
		case "time_isday"
			return string( GetWorldTime().IsDay() )
		case "time_isdusk"
			return string( GetWorldTime().IsDusk() )
		default
			GetGameScriptExpressionOLD()._error :+ "GameScriptExpression_Handle_Time: unknown variable ~q"+variable+"~q.~n"
			GetGameScriptExpressionOLD()._lastCommandErrored = True
	End Select

	return ""
End Function



Function GameScriptExpression_Handle_StationMap:string(variable:string, params:string[], resultElementType:int var)
	resultElementType = TScriptExpressionOLD.ELEMENTTYPE_STRING

	Select variable.ToLower()

		case "stationmap_mapname"
			return string(GetGameInformation("stationmap", "mapname"))
		Case "stationmap_mapnameshort"
			return string(GetGameInformation("stationmap", "mapnameshort"))
		Case "population"
			resultElementType = TScriptExpressionOLD.ELEMENTTYPE_NUMERIC
			return string(GetGameInformation("stationmap", "population"))
		default
			GetGameScriptExpressionOLD()._error :+ "GameScriptExpression_Handle_StationMap: unknown variable ~q"+variable+"~q.~n"
			GetGameScriptExpressionOLD()._lastCommandErrored = True
	End Select

	return ""
End Function




Function GameScriptExpression_Handle_PersonGenerator:string(variable:string, params:string[], resultElementType:int var)
	resultElementType = TScriptExpressionOLD.ELEMENTTYPE_STRING

	local country:string = ""
	if params.length > 1 then country = params[0].Trim().ToLower()
	if not GetPersonGenerator().HasProvider(country)
		country = GetPersonGenerator().GetRandomCountryCode()
	endif

	local gender:int= 0
	if params.length > 1 then gender = TPersonGenerator.GetGenderFromString( params[1] )

	Select variable.ToLower()
		case "persongenerator_firstname"
			return GetPersonGenerator().GetFirstName(country, gender)
		case "persongenerator_lastname"
			return GetPersonGenerator().GetLastName(country, gender)
		case "persongenerator_name"
			return GetPersonGenerator().GetFirstName(country, gender) + " " + GetPersonGenerator().GetLastName(country, gender)
		case "persongenerator_title"
			return GetPersonGenerator().GetTitle(country, gender)
		default
			print "GameScriptExpression_Handle_PersonGenerator: unknown variable ~q"+variable+"~q.~n"
			GetGameScriptExpressionOLD()._error :+ "GameScriptExpression_Handle_PersonGenerator: unknown variable ~q"+variable+"~q.~n"
			GetGameScriptExpressionOLD()._lastCommandErrored = True
	End Select

	return ""
End Function
