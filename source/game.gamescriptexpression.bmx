SuperStrict
Import "game.gamescriptexpression.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameinformation.base.bmx"


GetGameScriptExpression().RegisterHandler("TIME_YEAR", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_DAY", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_HOUR", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_MINUTE", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_WEEKDAY", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_SEASON", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_DAYSPLAYED", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_YEARSPLAYED", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_DAYOFMONTH", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_DAYOFYEAR", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_ISNIGHT", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_ISDAWN", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_ISDAY", GameScriptExpression_Handle_Time)
GetGameScriptExpression().RegisterHandler("TIME_ISDUSK", GameScriptExpression_Handle_Time)

GetGameScriptExpression().RegisterHandler("STATIONMAP_MAPNAME", GameScriptExpression_Handle_StationMap)
GetGameScriptExpression().RegisterHandler("STATIONMAP_MAPNAMESHORT", GameScriptExpression_Handle_StationMap)




Function GameScriptExpression_Handle_Time:string(variable:string, params:string[], resultElementType:int var)
	resultElementType = TScriptExpression.ELEMENTTYPE_NUMERIC

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
			return string( GetWorldTime().GetWeekday() )
		case "time_season"
			return string( GetWorldTime().GetSeason() )
		case "time_dayofmonth"
			return string( GetWorldTime().GetDayOfMonth() )
		case "time_dayofyear"
			return string( GetWorldTime().GetDayOfYear() )
		case "time_isnight"
			return string( GetWorldTime().IsNight() )
		case "time_isdawn"
			return string( GetWorldTime().IsDawn() )
		case "time_isday"
			return string( GetWorldTime().IsDay() )
		case "time_isdusk"
			return string( GetWorldTime().IsDusk() )
		default
			GetGameScriptExpression()._error :+ "GameScriptExpression_Handle_Time: unknown variable ~q"+variable+"~q.~n"
	End Select

	return ""
End Function



Function GameScriptExpression_Handle_StationMap:string(variable:string, params:string[], resultElementType:int var)
	resultElementType = TScriptExpression.ELEMENTTYPE_STRING

	Select variable.ToLower()

		case "stationmap_mapname"
			return string(GetGameInformation("stationmap", "mapname"))
		Case "stationmap_mapnameshort"
			return string(GetGameInformation("stationmap", "mapnameshort"))
		Case "population"
			resultElementType = TScriptExpression.ELEMENTTYPE_NUMERIC
			return string(GetGameInformation("stationmap", "population"))
		default
			GetGameScriptExpression()._error :+ "GameScriptExpression_Handle_StationMap: unknown variable ~q"+variable+"~q.~n"
	End Select

	return ""
End Function