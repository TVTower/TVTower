SuperStrict
Import "game.gamescriptexpression.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameinformation.base.bmx"
Import "Dig/base.util.persongenerator.bmx"

Import "game.production.script.bmx"
Import "game.programme.programmedata.bmx"
Import "game.programme.programmelicence.bmx"

'valid context(s): TScript
GameScriptExpression.RegisterFunctionHandler( "episodeCount", SEFN_Script_episodeCount, 0, 0)
'valid context(s): TProgrammeData
GameScriptExpression.RegisterFunctionHandler( "cast", SEFN_cast, 1,  2)

'valid context(s): "all supported"
GameScriptExpression.RegisterFunctionHandler( "self", SEFN_self, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "programmedata", SEFN_programmedata, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "programmelicence", SEFN_programmelicence, 2, 3)


'valid context(s): all
GameScriptExpression.RegisterFunctionHandler( "stationmap_randomcity", SEFN_StationMap_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "stationmap_population", SEFN_StationMap_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "stationmap_mapname", SEFN_StationMap_Various, 0, 0)
GameScriptExpression.RegisterFunctionHandler( "stationmap_mapnameshort", SEFN_StationMap_Various, 0, 0)

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

'${.cast:n:"full"} - context: TProgrammeData
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


'${.programme:"the-guid-1-2":"title"} - context: all
Function SEFN_programmelicence:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local licenceGUID:String = params.GetToken(1).value
	Local licence:TProgrammeLicence

	If not licenceGUID
		licence = TProgrammeLicence(context)
		If Not licence
			Local data:TProgrammeData = TProgrammeData(context)
			print "lookup by parentid: " + data.parentDataID
			if data and data.parentDataID
				licence = GetProgrammeLicenceCollection().Get(data.parentDataID)
			EndIf
		EndIf
		If Not licence Then Return New SToken( TK_ERROR, "(.programme only usable with a valid programme(licence) GUID or within a TProgrammeData or TProgrammeLicence itself.)", params.GetToken(0) )
	Else
		licence = GetProgrammeLicenceCollection().GetByGUID(licenceGUID)
	EndIf

	If Not licence Then Return New SToken( TK_ERROR, "(.programme with GUID ~q"+licenceGUID+"~q not found.)", params.GetToken(0) )
		
	Select params.GetToken(2).value.ToLower()
		Case "title"                   Return New SToken( TK_TEXT, licence.GetTitle(), params.GetToken(0) )
		Case "description"             Return New SToken( TK_TEXT, licence.GetDescription(), params.GetToken(0) )
		Case "country"                 Return New SToken( TK_TEXT, licence.data.country, params.GetToken(0) )
		Case "year"                    Return New SToken( TK_NUMBER, licence.data.GetYear(), params.GetToken(0) )
		Case "islive"                  Return New SToken( TK_BOOLEAN, licence.IsLive(), params.GetToken(0) )
		Case "isalwayslive"            Return New SToken( TK_BOOLEAN, licence.IsAlwayslive(), params.GetToken(0) )
		Case "isxrated"                Return New SToken( TK_BOOLEAN, licence.IsXRated(), params.GetToken(0) )
		Case "isliveontape"            Return New SToken( TK_BOOLEAN, licence.IsLiveOnTape(), params.GetToken(0) )
		Case "ispaid"                  Return New SToken( TK_BOOLEAN, licence.IsPaid(), params.GetToken(0) )
		Case "isseries"                Return New SToken( TK_BOOLEAN, licence.IsSeries(), params.GetToken(0) )
		Case "isepisode"               Return New SToken( TK_BOOLEAN, licence.IsEpisode(), params.GetToken(0) )
		Case "issingle"                Return New SToken( TK_BOOLEAN, licence.IsSingle(), params.GetToken(0) )
		Case "iscollection"            Return New SToken( TK_BOOLEAN, licence.IsCollection(), params.GetToken(0) )
		Case "iscollectionelement"     Return New SToken( TK_BOOLEAN, licence.IsCollectionElement(), params.GetToken(0) )
		Case "istvdistribution"        Return New SToken( TK_BOOLEAN, licence.IsTVDistribution(), params.GetToken(0) )
		Case "iscustomproduction"      Return New SToken( TK_BOOLEAN, licence.IsCustomProduction(), params.GetToken(0) )
		'Case "isaplayerscustomproduction"            Return New SToken( TK_BOOLEAN, licence.IsAPlayersCustomProduction(), params.GetToken(0) )
		'Case "isaplayersunfinishedcustomproduction"  Return New SToken( TK_BOOLEAN, licence.IsAPlayersUnfinishedCustomProduction(), params.GetToken(0) )
		'Case "isunfinishedcustomproduction"          Return New SToken( TK_BOOLEAN, licence.IsUnfinishedCustomProduction(), params.GetToken(0) )
		Case "broadcasttimeslotstart"  Return New SToken( TK_NUMBER, licence.GetBroadcastTimeSlotStart(), params.GetToken(0) )
		Case "broadcasttimeslotstart"  Return New SToken( TK_NUMBER, licence.GetBroadcastTimeSlotStart(), params.GetToken(0) )
		Case "hasbroadcasttimeslot"    Return New SToken( TK_BOOLEAN, licence.HasBroadcastTimeSlot(), params.GetToken(0) )
		Case "broadcastlimitmax"       Return New SToken( TK_NUMBER, licence.GetBroadcastLimitMax(), params.GetToken(0) )
		Case "broadcastlimit"          Return New SToken( TK_NUMBER, licence.GetBroadcastLimit(), params.GetToken(0) )
		Case "hasbroadcastlimit"       Return New SToken( TK_BOOLEAN, licence.HasBroadcastLimit(), params.GetToken(0) )
		Case "episodenumber"           Return New SToken( TK_NUMBER, licence.GetEpisodeNumber(), params.GetToken(0) )
		Case "episodecount"            Return New SToken( TK_NUMBER, licence.GetEpisodeCount(), params.GetToken(0) )
		'Case "isavailable"             Return New SToken( TK_BOOLEAN, licence.isAvailable(), params.GetToken(0) )
		'Case "isreleased"              Return New SToken( TK_BOOLEAN, licence.isReleased(), params.GetToken(0) )
		'Case "isplanned"               Return New SToken( TK_BOOLEAN, licence.isPlanned(), params.GetToken(0) )
		'Case "isprogrammeplanned"      Return New SToken( TK_BOOLEAN, licence.isProgrammePlanned(), params.GetToken(0) )
		'Case "istrailerplanned"        Return New SToken( TK_BOOLEAN, licence.isTrailerPlanned(), params.GetToken(0) )
		'Case "isnewbroadcastpossible"  Return New SToken( TK_TEXT, licence.IsNewBroadcastPossible(), params.GetToken(0) )
		Case "genre"                   Return New SToken( TK_TEXT, licence.GetGenre(), params.GetToken(0) )
		Case "genrestring"             Return New SToken( TK_TEXT, licence.GetGenreString(), params.GetToken(0) )
		Case "genresline"              Return New SToken( TK_TEXT, licence.GetGenresLine(), params.GetToken(0) )
		Case "hasdataflag"             Return New SToken( TK_BOOLEAN, licence.HasDataFlag(Int(params.GetToken(3).valueLong)), params.GetToken(0) )
		Case "hasbroadcastflag"        Return New SToken( TK_BOOLEAN, licence.HasBroadcastFlag(Int(params.GetToken(3).valueLong)), params.GetToken(0) )
		Case "hasflag"                 Return New SToken( TK_BOOLEAN, licence.HasFlag(Int(params.GetToken(3).valueLong)), params.GetToken(0) )
		Case "quality"                 Return New SToken( TK_NUMBER, licence.GetQuality(), params.GetToken(0) )
		Case "speed"                   Return New SToken( TK_NUMBER, licence.GetSpeed(), params.GetToken(0) )
		Case "review"                  Return New SToken( TK_NUMBER, licence.GetReview(), params.GetToken(0) )
		Case "outcome"                 Return New SToken( TK_NUMBER, licence.GetOutcome(), params.GetToken(0) )
		Case "outcometv"               Return New SToken( TK_NUMBER, licence.GetOutcomeTV(), params.GetToken(0) )
		Case "blocks"                  Return New SToken( TK_NUMBER, licence.GetBlocks(), params.GetToken(0) )
		Case "relativetopicality"      Return New SToken( TK_NUMBER, licence.GetRelativeTopicality(), params.GetToken(0) )
		Case "topicality"              Return New SToken( TK_NUMBER, licence.GetTopicality(), params.GetToken(0) )
		Case "maxtopicality"           Return New SToken( TK_NUMBER, licence.GetMaxTopicality(), params.GetToken(0) )
		Default                        Return New SToken( TK_TEXT, licence.GetTitle(), params.GetToken(0) )
	End Select
End Function



'${.self:"title"} - context: TProgrammeLicence / TProgrammeData
Function SEFN_programmedata:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local data:TProgrammeData = TProgrammeData(context)
	If Not data Then Return New SToken( TK_ERROR, "(."+params.GetToken(0).GetValueText()+" only usable with a valid programme(data).)", params.GetToken(0) )

	'do not allow title/description for "self" as this is prone
	'to a recursive call (description requesting description)
	if params.GetToken(0).GetValueText() <> "self"
		Select params.GetToken(1).value.ToLower()
			Case "title"               Return New SToken( TK_TEXT, data.GetTitle(), params.GetToken(0) )
			Case "description"         Return New SToken( TK_TEXT, data.GetDescription(), params.GetToken(0) )
		End Select
	EndIf
	
	Select params.GetToken(1).value.ToLower()
		Case "country"                 Return New SToken( TK_TEXT, data.country, params.GetToken(0) )
		Case "year"                    Return New SToken( TK_NUMBER, data.GetYear(), params.GetToken(0) )
		Case "islive"                  Return New SToken( TK_BOOLEAN, data.IsLive(), params.GetToken(0) )
		Case "isalwayslive"            Return New SToken( TK_BOOLEAN, data.IsAlwayslive(), params.GetToken(0) )
		Case "isxrated"                Return New SToken( TK_BOOLEAN, data.IsXRated(), params.GetToken(0) )
		Case "isliveontape"            Return New SToken( TK_BOOLEAN, data.IsLiveOnTape(), params.GetToken(0) )
		Case "ispaid"                  Return New SToken( TK_BOOLEAN, data.IsPaid(), params.GetToken(0) )
		Case "isepisode"               Return New SToken( TK_BOOLEAN, data.IsEpisode(), params.GetToken(0) )
		Case "issingle"                Return New SToken( TK_BOOLEAN, data.IsSingle(), params.GetToken(0) )
		Case "iscustomproduction"      Return New SToken( TK_BOOLEAN, data.IsCustomProduction(), params.GetToken(0) )
		Case "broadcasttimeslotstart"  Return New SToken( TK_NUMBER, data.GetBroadcastTimeSlotStart(), params.GetToken(0) )
		Case "broadcasttimeslotstart"  Return New SToken( TK_NUMBER, data.GetBroadcastTimeSlotStart(), params.GetToken(0) )
		Case "hasbroadcasttimeslot"    Return New SToken( TK_BOOLEAN, data.HasBroadcastTimeSlot(), params.GetToken(0) )
		Case "broadcastlimitmax"       Return New SToken( TK_NUMBER, data.GetBroadcastLimitMax(), params.GetToken(0) )
		Case "broadcastlimit"          Return New SToken( TK_NUMBER, data.GetBroadcastLimit(), params.GetToken(0) )
		Case "hasbroadcastlimit"       Return New SToken( TK_BOOLEAN, data.HasBroadcastLimit(), params.GetToken(0) )
		Case "genre"                   Return New SToken( TK_TEXT, data.GetGenre(), params.GetToken(0) )
		Case "genrestring"             Return New SToken( TK_TEXT, data.GetGenreString(), params.GetToken(0) )
		Case "hasbroadcastflag"        Return New SToken( TK_BOOLEAN, data.HasBroadcastFlag(Int(params.GetToken(2).valueLong)), params.GetToken(0) )
		Case "hasflag"                 Return New SToken( TK_BOOLEAN, data.HasFlag(Int(params.GetToken(2).valueLong)), params.GetToken(0) )
		Case "quality"                 Return New SToken( TK_NUMBER, data.GetQuality(), params.GetToken(0) )
		Case "speed"                   Return New SToken( TK_NUMBER, data.GetSpeed(), params.GetToken(0) )
		Case "review"                  Return New SToken( TK_NUMBER, data.GetReview(), params.GetToken(0) )
		Case "outcome"                 Return New SToken( TK_NUMBER, data.GetOutcome(), params.GetToken(0) )
		Case "outcometv"               Return New SToken( TK_NUMBER, data.GetOutcomeTV(), params.GetToken(0) )
		Case "blocks"                  Return New SToken( TK_NUMBER, data.GetBlocks(), params.GetToken(0) )
		Case "topicality"              Return New SToken( TK_NUMBER, data.GetTopicality(), params.GetToken(0) )
		Case "maxtopicality"           Return New SToken( TK_NUMBER, data.GetMaxTopicality(), params.GetToken(0) )
		Default                        Return New SToken( TK_TEXT, "unknown_property", params.GetToken(0) )
	End Select
End Function


'various "self"-referencing options
'context: TProgrammeLicence
'context: TProgrammeData
Function SEFN_self:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	If TProgrammeData(context)
		return SEFN_programmedata(params, context, contextNumeric)
	ElseIf TProgrammeLicence(context)
		return SEFN_programmelicence(params, TProgrammeLicence(context).data, contextNumeric)
	EndIf
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
