SuperStrict
Import "game.gamescriptexpression.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameinformation.base.bmx"
Import "Dig/base.util.persongenerator.bmx"

Import "game.production.script.bmx"
Import "game.programme.programmedata.bmx"

'valid context(s): TScript
GameScriptExpression.RegisterFunctionHandler( "episodeCount", SEFN_Script_episodeCount, 0, 0)
'valid context(s): TProgrammeData
GameScriptExpression.RegisterFunctionHandler( "cast", SEFN_cast, 1,  2)


'valid context(s): all
GameScriptExpression.RegisterFunctionHandler( "stationmap_randomcity", SEFN_StationMap_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "stationmap_population", SEFN_StationMap_Various, 0, 0)

GameScriptExpression.RegisterFunctionHandler( "worldtime_year", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_month", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_day", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_hour", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_minute", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_daysplayed", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_yearsplayed", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_weekday", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_season", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_dayofmonth", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_dayofyear", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_isnight", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_isdawn", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_isday", SEFN_WorldTime_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "worldtime_isdusk", SEFN_WorldTime_Various, 0, 0)

GameScriptExpression.RegisterFunctionHandler( "persongenerator_firstname", SEFN_PersonGenerator_Various, 0, 2)
GameScriptExpression.RegisterFunctionHandler( "persongenerator_lastname", SEFN_PersonGenerator_Various, 0, 2)
GameScriptExpression.RegisterFunctionHandler( "persongenerator_name", SEFN_PersonGenerator_Various, 0, 2)
GameScriptExpression.RegisterFunctionHandler( "persongenerator_title", SEFN_PersonGenerator_Various, 0, 2)




'${.worldTime_***} - context: all
Function SEFN_WorldTime_Various:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local command:String = params.GetToken(0).GetValueText()
	
	Select command.ToLower()
		case "worldtime_year"
			Return New SToken( TK_NUMBER, GetWorldTime().GetYear(), params.GetToken(0) )
		case "worldtime_month"
			Return New SToken( TK_NUMBER, GetWorldTime().GetMonth(), params.GetToken(0) )
		case "worldtime_day"
			Return New SToken( TK_NUMBER, GetWorldTime().GetDay(), params.GetToken(0) )
		case "worldtime_hour"
			Return New SToken( TK_NUMBER, GetWorldTime().GetDayHour(), params.GetToken(0) )
		case "worldtime_minute"
			Return New SToken( TK_NUMBER, GetWorldTime().GetDayMinute(), params.GetToken(0) )
		case "worldtime_daysplayed"
			Return New SToken( TK_NUMBER, GetWorldTime().GetDaysRun(), params.GetToken(0) )
		case "worldtime_yearsplayed"
			Return New SToken( TK_NUMBER, int(floor(GetWorldTime().GetDaysRun() / GetWorldTime().GetDaysPerYear())), params.GetToken(0) )
		case "worldtime_weekday"
			'attention, use the weekday depending on game start (day 1
			'of a game is always a monday... ani: no it is not)
			'return string( GetWorldTime().GetWeekdayByDay( GetWorldTime().GetDaysRun() ) )
			'this would return weekday of the exact start date
			'so 1985/1/1 is a different weekday than 1986/1/1
			Return New SToken( TK_NUMBER, GetWorldTime().GetWeekday(), params.GetToken(0) )
		case "worldtime_season"
			Return New SToken( TK_NUMBER, GetWorldTime().GetSeason(), params.GetToken(0) )
		case "worldtime_dayofmonth"
			Return New SToken( TK_NUMBER, GetWorldTime().GetDayOfMonth(), params.GetToken(0) )
		case "worldtime_dayofyear"
			Return New SToken( TK_NUMBER, GetWorldTime().GetDayOfYear(), params.GetToken(0) )
		case "worldtime_isnight"
			Return New SToken( TK_NUMBER, GetWorldTime().IsNight(), params.GetToken(0) )
		case "worldtime_isdawn"
			Return New SToken( TK_NUMBER, GetWorldTime().IsDawn(), params.GetToken(0) )
		case "worldtime_isday"
			Return New SToken( TK_NUMBER, GetWorldTime().IsDay(), params.GetToken(0) )
		case "worldtime_isdusk"
			Return New SToken( TK_NUMBER, GetWorldTime().IsDusk(), params.GetToken(0) )
		default
			Return New SToken( TK_ERROR, "(Undefined function ~q."+command+"~q)", params.GetToken(0) )
	End Select
End Function



'${.stationmap_***} - context: all
Function SEFN_StationMap_Various:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local command:String = params.GetToken(0).GetValueText()

	Select command.ToLower()
		case "stationmap_randomcity"
			Return New SToken( TK_TEXT, GetStationMapCollection().GenerateCity(), params.GetToken(0) )
		case "stationmap_population"
			'Return New SToken( TK_NUMBER, GetGameInformation("stationmap", "population"), params.GetToken(0) )
			Return New SToken( TK_NUMBER, GetStationMapCollection().population, params.GetToken(0) )
		case "stationmap_mapname"
			'Return New SToken( TK_TEXT, GetGameInformation("stationmap", "mapname"), params.GetToken(0) )
			Return New SToken( TK_TEXT, GetStationMapCollection().GetMapName(), params.GetToken(0) )
		Case "stationmap_mapnameshort"
			'Return New SToken( TK_TEXT, GetGameInformation("stationmap", "mapnameshort"), params.GetToken(0) )
			Return New SToken( TK_TEXT, GetStationMapCollection().GetMapISO3166Code(), params.GetToken(0) )
		default
			Return New SToken( TK_ERROR, "(Undefined function ~q."+command+"~q)", params.GetToken(0) )
	End Select
End Function



'${.persongenerator_***} - context: all
Function SEFN_PersonGenerator_Various:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local command:String = params.GetToken(0).GetValueText()
	'choose a random country if the country is not defined or no generator
	'existing for it
	Local country:String = params.GetToken(1).GetValueText()
	If country = "" or Not GetPersonGenerator().HasProvider(country)
		country = GetPersonGenerator().GetRandomCountryCode()
	EndIf
	'gender as defined or a random one
	Local gender:Int = TPersonGenerator.GetGenderFromString( params.GetToken(2).GetValueText() )

	Select command.ToLower()
		case "persongenerator_firstname"
			Return New SToken( TK_TEXT, GetPersonGenerator().GetFirstName(country, gender), params.GetToken(0) )
		case "persongenerator_lastname"
			Return New SToken( TK_TEXT, GetPersonGenerator().GetLastName(country, gender), params.GetToken(0) )
		case "persongenerator_name"
			Return New SToken( TK_TEXT, GetPersonGenerator().GetFirstName(country, gender) + " " + GetPersonGenerator().GetLastName(country, gender), params.GetToken(0) )
		case "persongenerator_title"
			Return New SToken( TK_TEXT, GetPersonGenerator().GetTitle(country, gender), params.GetToken(0) )
		default
			Return New SToken( TK_ERROR, "(Undefined function ~q."+command+"~q)", params.GetToken(0) )
	End Select
End Function


'VARIOUS
'--------------

'${.cast:n:full} - context: TProgrammeData
Function SEFN_cast:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local programmeData:TProgrammeData = TProgrammeData(context)
	If Not programmeData Then Return New SToken( TK_ERROR, "(.cast only usable within TProgrammeData)", params.GetToken(0) )

	Local castNumber:Int = params.GetToken(1).valueLong
	Local job:TPersonProductionJob = programmeData.GetCastAtIndex(castNumber)
	If Not job Then Return New SToken( TK_ERROR, "(.cast " + castNumber +" not found)", params.GetToken(0) )

	Local person:TPersonBase = GetPersonBaseCollection().GetByID( job.personID )
	If Not person Then Return New SToken( TK_ERROR, "(.cast " + castNumber +" person not found)", params.GetToken(0) )

	Select params.GetToken(2).value.ToLower()
		Case "firstname"  Return New SToken( TK_TEXT, person.GetFirstName(), params.GetToken(0) )
		Case "lastname"   Return New SToken( TK_TEXT, person.GetLastName(), params.GetToken(0) )
		Case "nickname"   Return New SToken( TK_TEXT, person.GetNickName(), params.GetToken(0) )
		Default           Return New SToken( TK_TEXT, person.GetFullName(), params.GetToken(0) )
	End Select
End Function


'${.episodeCount} - context: TScript
Function SEFN_Script_episodeCount:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local script:TScript = TScript(context)
	If Not script Then Return New SToken( TK_ERROR, "(.episodeCount only usable within scripts)", params.GetToken(0) )

	Return New SToken( TK_NUMBER, script.GetEpisodes(), params.GetToken(0) )
End Function






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
			GetGameScriptExpressionOLD()._error.Append("GameScriptExpression_Handle_Time: unknown variable ~q"+variable+"~q.~n")
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
			GetGameScriptExpressionOLD()._error.Append("GameScriptExpression_Handle_StationMap: unknown variable ~q"+variable+"~q.~n")
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
			GetGameScriptExpressionOLD()._error.Append("GameScriptExpression_Handle_PersonGenerator: unknown variable ~q")
			GetGameScriptExpressionOLD()._error.Append(variable)
			GetGameScriptExpressionOLD()._error.Append("~q.~n")
			GetGameScriptExpressionOLD()._lastCommandErrored = True
	End Select

	return ""
End Function
