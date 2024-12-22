SuperStrict
Import "game.gamescriptexpression.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameinformation.base.bmx"
Import "Dig/base.util.persongenerator.bmx"

Import "game.stationmap.bmx"
Import "game.production.script.bmx"
Import "game.production.scripttemplate.bmx"
Import "game.programme.programmedata.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.programme.newsevent.bmx"
Import "game.database.localizer.bmx"
Import Brl.Map


'override base gamescript expression instance with specific instance
GameScriptExpression = New TGameScriptExpression

'valid context(s): "all supported"
GameScriptExpression.RegisterFunctionHandler( "self", SEFN_self, 1, 3)

GameScriptExpression.RegisterFunctionHandler( "newsevent", SEFN_newsevent, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "programmedata", SEFN_programmedata, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "programmelicence", SEFN_programmelicence, 2, 3) '
GameScriptExpression.RegisterFunctionHandler( "programme", SEFN_programmelicence, 2, 3) 'synonym usage
GameScriptExpression.RegisterFunctionHandler( "role", SEFN_role, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "person", SEFN_person, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "locale", SEFN_locale, 1, 3)
GameScriptExpression.RegisterFunctionHandler( "script", SEFN_script, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "sport", SEFN_sport, 2, 4)
GameScriptExpression.RegisterFunctionHandler( "sportleague", SEFN_sportleague, 2, 4)
GameScriptExpression.RegisterFunctionHandler( "sportteam", SEFN_sportteam, 2, 4)
GameScriptExpression.RegisterFunctionHandler( "stationmap", SEFN_StationMap, 1, 1)
GameScriptExpression.RegisterFunctionHandler( "persongenerator", SEFN_PersonGenerator, 1, 3)
GameScriptExpression.RegisterFunctionHandler( "worldtime", SEFN_WorldTime, 1, 2)
GameScriptExpression.RegisterFunctionHandler( "random", SEFN_random, 1, 2)




'${.worldTime:***} - context: all
'${.worldTime:"year"}
'${.worldTime:"isnight"}
Function SEFN_WorldTime:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local command:String = params.GetToken(0).GetValueText()
	Local subCommand:String = params.GetToken(1).value 'MUST be a string
	Local timeStamp:Long = -1
	if params.HasToken(2) then timeStamp = params.GetToken(2).GetValueLong()

	'TODO formatted date, weekdayname?
	Select subCommand.ToLower()
		case "year"         Return New SToken( TK_NUMBER, GetWorldTime().GetYear(timeStamp), params.GetToken(0) )
		case "month"        Return New SToken( TK_NUMBER, GetWorldTime().GetMonth(timeStamp), params.GetToken(0) )
		case "day"          Return New SToken( TK_NUMBER, GetWorldTime().GetDay(timeStamp), params.GetToken(0) )
		case "hour"         Return New SToken( TK_NUMBER, GetWorldTime().GetDayHour(timeStamp), params.GetToken(0) )
		case "minute"       Return New SToken( TK_NUMBER, GetWorldTime().GetDayMinute(timeStamp), params.GetToken(0) )
		case "daysplayed"   Return New SToken( TK_NUMBER, GetWorldTime().GetDaysRun(timeStamp), params.GetToken(0) )
		case "dayplaying"   Return New SToken( TK_NUMBER, GetWorldTime().GetDaysRun(timeStamp) + 1, params.GetToken(0) )
		case "yearsplayed"  Return New SToken( TK_NUMBER, int(floor(GetWorldTime().GetDaysRun(timeStamp) / GetWorldTime().GetDaysPerYear())), params.GetToken(0) )
		'attention, use the weekday depending on game start (day 1
		'of a game is always a monday... ani: no it is not)
		'case "weekday"     Return string( GetWorldTime().GetWeekdayByDay( GetWorldTime().GetDaysRun() ) )
		'this would return weekday of the exact start date
		'so 1985/1/1 is a different weekday than 1986/1/1
		case "weekday"      Return New SToken( TK_NUMBER, GetWorldTime().GetWeekday(timeStamp), params.GetToken(0) )
		case "season"       Return New SToken( TK_NUMBER, GetWorldTime().GetSeason(timeStamp), params.GetToken(0) )
		case "dayofmonth"   Return New SToken( TK_NUMBER, GetWorldTime().GetDayOfMonth(timeStamp), params.GetToken(0) )
		case "dayofyear"    Return New SToken( TK_NUMBER, GetWorldTime().GetDayOfYear(timeStamp), params.GetToken(0) )
		case "isnight"      Return New SToken( TK_BOOLEAN, GetWorldTime().IsNight(timeStamp), params.GetToken(0) )
		case "isdawn"       Return New SToken( TK_BOOLEAN, GetWorldTime().IsDawn(timeStamp), params.GetToken(0) )
		case "isday"        Return New SToken( TK_BOOLEAN, GetWorldTime().IsDay(timeStamp), params.GetToken(0) )
		case "isdusk"       Return New SToken( TK_BOOLEAN, GetWorldTime().IsDusk(timeStamp), params.GetToken(0) )
		default             Return New SToken( TK_ERROR, "Undefined command ~q"+subCommand+"~q", params.GetToken(0) )
	End Select
End Function



'${.stationmap:***} - context: all
'${.stationmap:"randomcity"}
'${.stationmap:"mapname"}
Function SEFN_StationMap:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local command:String = params.GetToken(0).GetValueText()
	Local subCommand:String = params.GetToken(1).value 'MUST be a string

	Select subCommand.ToLower()
		case "randomcity"    Return New SToken( TK_TEXT, GetStationMapCollection().GenerateCity(), params.GetToken(0) )
		'case "population"    Return New SToken( TK_NUMBER, GetGameInformation("stationmap", "population"), params.GetToken(0) )
		'case "mapname"       Return New SToken( TK_TEXT, GetGameInformation("stationmap", "mapname"), params.GetToken(0) )
		'case "mapnameshort"  Return New SToken( TK_TEXT, GetGameInformation("stationmap", "mapnameshort"), params.GetToken(0) )
		case "population"    Return New SToken( TK_NUMBER, GetStationMapCollection().population, params.GetToken(0) )
		case "mapname"       Return New SToken( TK_TEXT, GetStationMapCollection().GetMapName(), params.GetToken(0) )
		Case "mapnameshort"  Return New SToken( TK_TEXT, GetStationMapCollection().GetMapISO3166Code(), params.GetToken(0) )
		default              Return New SToken( TK_ERROR, "Undefined command ~q"+subCommand+"~q", params.GetToken(0) )
	End Select
End Function



'${.persongenerator:***} - context: all
'${.persongenerator:"firstname":"us":"male/female/0/1/m/f"}
'${.persongenerator:"fullname"}
Function SEFN_PersonGenerator:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local command:String = params.GetToken(0).GetValueText()
	Local subCommand:String = params.GetToken(1).value 'MUST be a string
	'choose a random country if the country is not defined or no generator
	'existing for it
	Local country:String
	If params.HasToken(2)
		country = params.GetToken(2).GetValueText()
	EndIf
	If country = "" or Not GetPersonGenerator().HasProvider(country)
		country = GetPersonGenerator().GetRandomCountryCode()
	EndIf
	'gender as defined or a random one
	Local gender:Int
	If params.HasToken(3)
		gender = TPersonGenerator.GetGenderFromString( params.GetToken(3).GetValueText() )
	EndIf
	'chance (0 - 1.0) that full names get a title (like "Dr.") prefixed
	Local titleChance:Float
	If params.HasToken(4)
		Local t:SToken = params.GetToken(4)
		'in case someone wrote 0 or 1 (not 0.0 or 1.0) we handle long too
		If t.valueLong <> 0
			titleChance = Float(t.valueLong)
		Else
			titleChance = Float(t.valueDouble)
		EndIf
	EndIf

	Select subCommand.ToLower()
		case "firstname"  Return New SToken( TK_TEXT, GetPersonGenerator().GetFirstName(country, gender), params.GetToken(0) )
		case "lastname"   Return New SToken( TK_TEXT, GetPersonGenerator().GetLastName(country, gender), params.GetToken(0) )
		case "fullname"   Return New SToken( TK_TEXT, GetPersonGenerator().GetFullName(country, gender, titleChance), params.GetToken(0) )
		case "name"       Return New SToken( TK_TEXT, GetPersonGenerator().GetFirstName(country, gender), params.GetToken(0) )
		case "title"      Return New SToken( TK_TEXT, GetPersonGenerator().GetTitle(country, gender), params.GetToken(0) )
		default           Return New SToken( TK_ERROR, "PersonGenerator: Undefined command ~q"+subCommand+"~q", params.GetToken(0) )
	End Select
End Function




'${.locale:"localekey":"optional: language":"optional: randomlocale true/false/1/0"} - context: all
Function SEFN_locale:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	If params.HasToken(1)
		Local key:String = params.GetToken(1).GetValueText()
		Local random:Int
		If params.HasToken(3)
			random = params.GetToken(3).GetValueBool()
		EndIf
		If params.HasToken(2)
			Local languageCode:String = params.GetToken(2).value 'MUST be a string
			If languageCode <> ""
				If random
					Return New SToken( TK_TEXT, GetRandomLocale(key, languageCode), params.GetToken(0) )
				Else
					Return New SToken( TK_TEXT, GetLocale(key, languageCode), params.GetToken(0) )
				EndIf
			EndIf
		EndIf

		Local localeID:Int = context.contextNumeric
		If random
			Return New SToken( TK_TEXT, GetRandomLocale(key, localeID), params.GetToken(0) )
		Else
			Return New SToken( TK_TEXT, GetLocale(key, localeID), params.GetToken(0) )
		EndIf
	Else
		Return New SToken( TK_ERROR, "No locale key passed", params.GetToken(0) )
	EndIf
End Function


'${.random:maxValue/minValue:optional maxValue} - context: all
Function SEFN_random:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	If params.HasToken(1)
		Local minValue:Int
		Local maxValue:Int
		If params.HasToken(2)
			minValue = Int(params.GetToken(1).GetValueLong())
			maxValue = Int(params.GetToken(2).GetValueLong())
		Else
			maxValue = Int(params.GetToken(1).GetValueLong())
		EndIf
		
		Return New SToken( TK_NUMBER, RandRange(minValue, maxValue), params.GetToken(0) )
	Else
		Return New SToken( TK_ERROR, "No random max value passed", params.GetToken(0) )
	EndIf
End Function




'${.programme/.programmelicence:"guid"/id:"title"} - context: all
'${.self:"title"} - context: TProgrameLicence / TProgrammeData
Function SEFN_programmelicence:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	'non-self requires an offset of 1 to retrieve required property
	'${.self:"episodes"} - ${.myclass:"guid":"episodes"}
	Local tokenOffset:Int = 0
	Local licence:TProgrammeLicence
	Local firstTokenIsSelf:Int = params.GetToken(0).GetValueText() = "self"

	If firstTokenIsSelf
		licence = TProgrammeLicence(context.context)
		If Not licence Then Return New SToken( TK_ERROR, ".self is not a TProgrammeLicence", params.GetToken(0) )
	Else
		Local GUID:String = params.GetToken(1).value
		Local ID:Long = params.GetToken(1).GetValueLong()
		If GUID
			licence = GetProgrammeLicenceCollection().GetByGUID(GUID)
			If Not licence Then Return New SToken( TK_ERROR, ".programmelicence with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
		Else
			licence = GetProgrammeLicenceCollection().Get(Int(ID))
			If Not licence Then Return New SToken( TK_ERROR, ".programmelicence with ID ~q"+ID+"~q not found", params.GetToken(0) )
		EndIf
		tokenOffset = 1
	EndIf
	
	Local propertyName:String = params.GetToken(1 + tokenOffset).value.ToLower()

	If propertyName = "parent"
		If licence.parentLicenceGUID
			licence = licence.GetParentLicence()
		Else
			Return New SToken( TK_ERROR, ".self has no parent", params.GetToken(0) )
		EndIf
		If Not licence Then Return New SToken( TK_ERROR, ".self has no parent", params.GetToken(0) )
		firstTokenIsSelf = False
		propertyName = params.GetToken(2 + tokenOffset).value.ToLower()
	EndIf

	'do not allow title/description for "self" as this is prone
	'to a recursive call (description requesting description)
	if not firstTokenIsSelf
		Select propertyName
			Case "title"               Return New SToken( TK_TEXT, licence.GetTitle(), params.GetToken(0) )
			Case "description"         Return New SToken( TK_TEXT, licence.GetDescription(), params.GetToken(0) )
		End Select
	EndIf


	' delegate to custom sport property handler as programmedata 
	' and programelicence use same functionality
	If TSportsProgrammeData(licence.data)
		Local leagueID:Int = TSportsProgrammeData(licence.data).leagueID
		Local matchID:Int = TSportsProgrammeData(licence.data).matchID
		Select propertyName
			Case "sport", "sportleague", "sportmatch", "sportteam"
				Return _EvaluateSportsProperties(leagueID, matchID, propertyName, params, 1 + tokenOffset, context.contextNumeric)
		End Select
	EndIf

	
	Select propertyName
		Case "cast"                    Return _EvaluateProgrammeDataCast(licence.data, params, 1 + tokenOffset, context.contextNumeric)
		'convenience access - could be removed if one uses ${.role:${.self:"cast":x:"roleid"}:"fullname"} ...
		Case "role"                    Return _EvaluateProgrammeDataRole(licence.data, params, 1 + tokenOffset, context.contextNumeric)
		Case "year"                    Return New SToken( TK_NUMBER, licence.data.GetYear(), params.GetToken(0) )
		Case "episodecount"            Return New SToken( TK_NUMBER, licence.GetEpisodeCount(), params.GetToken(0) )
		Case "episodenumber"           Return New SToken( TK_NUMBER, licence.GetEpisodeNumber(), params.GetToken(0) )
		Case "country"                 Return New SToken( TK_TEXT, licence.data.country, params.GetToken(0) )
		case "guid"                    Return New SToken( TK_TEXT, licence.GetGUID(), params.GetToken(0) )
		case "id"                      Return New SToken( TK_NUMBER, licence.GetID(), params.GetToken(0) )
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
		Case "broadcasttimeslotend"    Return New SToken( TK_NUMBER, licence.GetBroadcastTimeSlotEnd(), params.GetToken(0) )
		Case "hasbroadcasttimeslot"    Return New SToken( TK_BOOLEAN, licence.HasBroadcastTimeSlot(), params.GetToken(0) )
		Case "broadcastlimitmax"       Return New SToken( TK_NUMBER, licence.GetBroadcastLimitMax(), params.GetToken(0) )
		Case "broadcastlimit"          Return New SToken( TK_NUMBER, licence.GetBroadcastLimit(), params.GetToken(0) )
		Case "hasbroadcastlimit"       Return New SToken( TK_BOOLEAN, licence.HasBroadcastLimit(), params.GetToken(0) )
		'Case "isavailable"             Return New SToken( TK_BOOLEAN, licence.isAvailable(), params.GetToken(0) )
		'Case "isreleased"              Return New SToken( TK_BOOLEAN, licence.isReleased(), params.GetToken(0) )
		'Case "isplanned"               Return New SToken( TK_BOOLEAN, licence.isPlanned(), params.GetToken(0) )
		'Case "isprogrammeplanned"      Return New SToken( TK_BOOLEAN, licence.isProgrammePlanned(), params.GetToken(0) )
		'Case "istrailerplanned"        Return New SToken( TK_BOOLEAN, licence.isTrailerPlanned(), params.GetToken(0) )
		'Case "isnewbroadcastpossible"  Return New SToken( TK_TEXT, licence.IsNewBroadcastPossible(), params.GetToken(0) )
		Case "genre"                   Return New SToken( TK_NUMBER, licence.GetGenre(), params.GetToken(0) )
		Case "genrestring"             Return New SToken( TK_TEXT, licence.GetGenreString(), params.GetToken(0) )
		Case "genresline"              Return New SToken( TK_TEXT, licence.GetGenresLine(), params.GetToken(0) )
		Case "hasdataflag"             Return New SToken( TK_BOOLEAN, licence.HasDataFlag(Int(params.GetToken(3).GetValueLong())), params.GetToken(0) )
		Case "hasbroadcastflag"        Return New SToken( TK_BOOLEAN, licence.HasBroadcastFlag(Int(params.GetToken(3).GetValueLong())), params.GetToken(0) )
		Case "hasflag"                 Return New SToken( TK_BOOLEAN, licence.HasFlag(Int(params.GetToken(3).GetValueLong())), params.GetToken(0) )
		Case "quality"                 Return New SToken( TK_NUMBER, licence.GetQuality(), params.GetToken(0) )
		Case "speed"                   Return New SToken( TK_NUMBER, licence.GetSpeed(), params.GetToken(0) )
		Case "review"                  Return New SToken( TK_NUMBER, licence.GetReview(), params.GetToken(0) )
		Case "outcome"                 Return New SToken( TK_NUMBER, licence.GetOutcome(), params.GetToken(0) )
		Case "outcometv"               Return New SToken( TK_NUMBER, licence.GetOutcomeTV(), params.GetToken(0) )
		Case "blocks"                  Return New SToken( TK_NUMBER, licence.GetBlocks(), params.GetToken(0) )
		Case "relativetopicality"      Return New SToken( TK_NUMBER, licence.GetRelativeTopicality(), params.GetToken(0) )
		Case "topicality"              Return New SToken( TK_NUMBER, licence.GetTopicality(), params.GetToken(0) )
		Case "maxtopicality"           Return New SToken( TK_NUMBER, licence.GetMaxTopicality(), params.GetToken(0) )

		Default                        Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function


'${.programmedata:"guid"/id:"title"} - context: all
'${.self:"title"} - context: TProgrammeData
Function SEFN_programmedata:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	'non-self requires an offset of 1 to retrieve required property
	'${.self:"episodes"} - ${.myclass:"guid":"episodes"}
	Local tokenOffset:Int = 0
	Local data:TprogrammeData
	Local firstTokenIsSelf:Int = params.GetToken(0).GetValueText() = "self"

	If firstTokenIsSelf
		data = TProgrammeData(context.context)
		If Not data Then Return New SToken( TK_ERROR, ".self is not a TProgrammeData", params.GetToken(0) )
	Else
		Local GUID:String = params.GetToken(1).value
		Local ID:Long = params.GetToken(1).GetValueLong()
		If GUID
			data = GetProgrammeDataCollection().GetByGUID(GUID)
			If Not data Then Return New SToken( TK_ERROR, ".programmedata with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
		Else
			data = GetProgrammeDataCollection().GetByID(Int(ID))
			If Not data Then Return New SToken( TK_ERROR, ".programmedata with ID ~q"+ID+"~q not found", params.GetToken(0) )
		EndIf
		tokenOffset = 1
	EndIf
	
	Local propertyName:String = params.GetToken(1 + tokenOffset).value.ToLower()

	If propertyName = "parent"
		data = GetProgrammeDataCollection().GetByID(data.parentDataID)
		If Not data Then Return New SToken( TK_ERROR, ".self has no parent", params.GetToken(0) )
		firstTokenIsSelf = False
		propertyName = params.GetToken(2 + tokenOffset).value.ToLower()
	EndIf


	' delegate to custom sport property handler as programmedata 
	' and programelicence use same functionality
	If TSportsProgrammeData(data)
		Local leagueID:Int = TSportsProgrammeData(data).leagueID
		Local matchID:Int = TSportsProgrammeData(data).matchID
		Select propertyName
			Case "sport", "sportleague", "sportmatch", "sportteam"
				Return _EvaluateSportsProperties(leagueID, matchID, propertyName, params, 1 + tokenOffset, context.contextNumeric)
		End Select
	EndIf

	'do not allow title/description for "self" as this is prone
	'to a recursive call (description requesting description)
	if not firstTokenIsSelf
		Select propertyName
			Case "title"               Return New SToken( TK_TEXT, data.GetTitle(), params.GetToken(0) )
			Case "description"         Return New SToken( TK_TEXT, data.GetDescription(), params.GetToken(0) )
		End Select
	EndIf

	Select propertyName
		Case "cast"                    Return _EvaluateProgrammeDataCast(data, params, 1 + tokenOffset, context.contextNumeric)
		'convenience access - could be removed if one uses ${.role:${.self:"cast":x:"roleid"}:"fullname"} ...
		Case "role"                    Return _EvaluateProgrammeDataRole(data, params, 1 + tokenOffset, context.contextNumeric)
		Case "year"                    Return New SToken( TK_NUMBER, data.GetYear(), params.GetToken(0) )
		case "guid"                    Return New SToken( TK_TEXT, data.GetGUID(), params.GetToken(0) )
		case "id"                      Return New SToken( TK_NUMBER, data.GetID(), params.GetToken(0) )
		Case "country"                 Return New SToken( TK_TEXT, data.country, params.GetToken(0) )
		Case "islive"                  Return New SToken( TK_BOOLEAN, data.IsLive(), params.GetToken(0) )
		Case "isalwayslive"            Return New SToken( TK_BOOLEAN, data.IsAlwayslive(), params.GetToken(0) )
		Case "isxrated"                Return New SToken( TK_BOOLEAN, data.IsXRated(), params.GetToken(0) )
		Case "isliveontape"            Return New SToken( TK_BOOLEAN, data.IsLiveOnTape(), params.GetToken(0) )
		Case "ispaid"                  Return New SToken( TK_BOOLEAN, data.IsPaid(), params.GetToken(0) )
		Case "isepisode"               Return New SToken( TK_BOOLEAN, data.IsEpisode(), params.GetToken(0) )
		Case "issingle"                Return New SToken( TK_BOOLEAN, data.IsSingle(), params.GetToken(0) )
		Case "iscustomproduction"      Return New SToken( TK_BOOLEAN, data.IsCustomProduction(), params.GetToken(0) )
		Case "broadcasttimeslotstart"  Return New SToken( TK_NUMBER, data.GetBroadcastTimeSlotStart(), params.GetToken(0) )
		Case "broadcasttimeslotend"    Return New SToken( TK_NUMBER, data.GetBroadcastTimeSlotEnd(), params.GetToken(0) )
		Case "hasbroadcasttimeslot"    Return New SToken( TK_BOOLEAN, data.HasBroadcastTimeSlot(), params.GetToken(0) )
		Case "broadcastlimitmax"       Return New SToken( TK_NUMBER, data.GetBroadcastLimitMax(), params.GetToken(0) )
		Case "broadcastlimit"          Return New SToken( TK_NUMBER, data.GetBroadcastLimit(), params.GetToken(0) )
		Case "hasbroadcastlimit"       Return New SToken( TK_BOOLEAN, data.HasBroadcastLimit(), params.GetToken(0) )
		Case "genre"                   Return New SToken( TK_NUMBER, data.GetGenre(), params.GetToken(0) )
		Case "genrestring"             Return New SToken( TK_TEXT, data.GetGenreString(), params.GetToken(0) )
		Case "hasbroadcastflag"        Return New SToken( TK_BOOLEAN, data.HasBroadcastFlag(Int(params.GetToken(2).GetValueLong())), params.GetToken(0) )
		Case "hasflag"                 Return New SToken( TK_BOOLEAN, data.HasFlag(Int(params.GetToken(2).GetValueLong())), params.GetToken(0) )
		Case "quality"                 Return New SToken( TK_NUMBER, data.GetQuality(), params.GetToken(0) )
		Case "speed"                   Return New SToken( TK_NUMBER, data.GetSpeed(), params.GetToken(0) )
		Case "review"                  Return New SToken( TK_NUMBER, data.GetReview(), params.GetToken(0) )
		Case "outcome"                 Return New SToken( TK_NUMBER, data.GetOutcome(), params.GetToken(0) )
		Case "outcometv"               Return New SToken( TK_NUMBER, data.GetOutcomeTV(), params.GetToken(0) )
		Case "blocks"                  Return New SToken( TK_NUMBER, data.GetBlocks(), params.GetToken(0) )
		Case "topicality"              Return New SToken( TK_NUMBER, data.GetTopicality(), params.GetToken(0) )
		Case "maxtopicality"           Return New SToken( TK_NUMBER, data.GetMaxTopicality(), params.GetToken(0) )

		Default                        Return New SToken( TK_ERROR, "Unknown property ~q" + propertyName + "~q", params.GetToken(0) )
	End Select
End Function


'${.newsevent:"guid"/id:"title"} - context: all
'${.self:"title"} - context: TNewsEvent
Function SEFN_newsevent:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	'non-self requires an offset of 1 to retrieve required property
	'${.self:"title"} - ${.myclass:"guid":"title"}
	Local tokenOffset:Int = 0
	Local data:TNewsEvent
	Local firstTokenIsSelf:Int = params.GetToken(0).GetValueText() = "self"

	If firstTokenIsSelf
		data = TNewsEvent(context.context)
		If Not data Then Return New SToken( TK_ERROR, ".self is not a TNewsEvent", params.GetToken(0) )
	Else
		Local GUID:String = params.GetToken(1).value
		Local ID:Long = params.GetToken(1).GetValueLong()
		If GUID
			data = GetNewsEventCollection().GetByGUID(GUID)
			If Not data Then Return New SToken( TK_ERROR, ".newsevent with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
		Else
			data = GetNewsEventCollection().GetByID(Int(ID))
			If Not data Then Return New SToken( TK_ERROR, ".newsevent with ID ~q"+ID+"~q not found", params.GetToken(0) )
		EndIf
		tokenOffset = 1
	EndIf
	
	Local propertyName:String = params.GetToken(1 + tokenOffset).value.ToLower()

	'TODO: parent retrieval for "news parent" (triggered by newsevent...)
	rem
	If propertyName = "parent"
		data = GetNewsEventCollection().GetByID(data.parentDataID)
		If Not data Then Return New SToken( TK_ERROR, ".self has no parent", params.GetToken(0) )
		firstTokenIsSelf = False
		propertyName = params.GetToken(2 + tokenOffset).value.ToLower()
	EndIf
	endrem


	' delegate to custom sport property handler as newsevent 
	' and programelicence use same functionality
	If TNewsEvent_Sport(data)
		Local leagueID:Int = TNewsEvent_Sport(data).leagueID
		Local matchID:Int = TNewsEvent_Sport(data).matchID
		Select propertyName
			Case "sport", "sportleague", "sportmatch", "sportteam"
				Return _EvaluateSportsProperties(leagueID, matchID, propertyName, params, 1 + tokenOffset, context.contextNumeric)
		End Select
	EndIf

	'do not allow title/description for "self" as this is prone
	'to a recursive call (description requesting description)
	if not firstTokenIsSelf
		Select propertyName
		End Select
	EndIf

	Select propertyName
		Case "title"            Return New SToken( TK_TEXT, data.GetTitle(), params.GetToken(0) )
		Case "description"      Return New SToken( TK_TEXT, data.GetDescription(), params.GetToken(0) )

		Case "genre"            Return New SToken( TK_NUMBER, data.GetGenre(), params.GetToken(0) )
		Case "happenedtime"     Return New SToken( TK_NUMBER, data.happenedTime, params.GetToken(0) )
		Case "eventduration"    Return New SToken( TK_NUMBER, data.eventDuration, params.GetToken(0) )
		Case "quality"          Return New SToken( TK_NUMBER, data.GetQuality(), params.GetToken(0) )
		Case "price"            Return New SToken( TK_NUMBER, data.GetPrice(), params.GetToken(0) )

		Default                 Return New SToken( TK_ERROR, "Unknown property ~q" + propertyName + "~q", params.GetToken(0) )
	End Select
End Function


Function _EvaluateSportsProperties:SToken(leagueID:Int, matchID:Int, propertyName:String, params:STokenGroup Var, tokenOffset:int, language:int) 'inline
	If Not propertyName
		propertyName = params.GetToken(tokenOffset).value.ToLower()
	EndIf

	Select propertyName
		Case "sport", "sportleague", "sportmatch", "sportteam"
			Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeague(leagueID)
			If Not league
				Return New SToken( TK_ERROR, "No league with ID " + leagueID +" defined in context", params.GetToken(0) )
			EndIf

			If propertyName = "sportleague"
				Return _EvaluateNewsEventSportLeague(league, params, tokenOffset + 1, language) 'inline
			ElseIf propertyName = "sport"
				Local sport:TNewsEventSport = league.GetSport()
				If Not sport
					Return New SToken( TK_ERROR, "No sport defined for league in context", params.GetToken(0) )
				EndIf
				Return _EvaluateNewsEventSport(sport, params, tokenOffset + 1, language) 'inline
			ElseIf propertyName = "sportmatch"
				Local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatch(matchID)
				If Not match
					Return New SToken( TK_ERROR, "No match with ID " + matchID + " defined in context", params.GetToken(0) )
				EndIf
				Return _EvaluateNewsEventSportMatch(match, params, tokenOffset + 1, language) 'inline
			ElseIf propertyName = "sportteam"
				Local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatch(matchID)
				If Not match
					Return New SToken( TK_ERROR, "No match (to identify teams) with ID " + matchID + " defined in context", params.GetToken(0) )
				EndIf
				Local teamIndex:Int = Int(params.GetToken(tokenOffset + 1).GetValueLong())
				If match.teams.length < 0 or match.teams.length <= teamIndex or not match.teams[teamIndex] 
					Return New SToken( TK_ERROR, "No team at index " + teamIndex + " found", params.GetToken(0) )
				EndIf
				Return _EvaluateNewsEventSportTeam(match.teams[teamIndex], params, tokenOffset + 2, language)
			EndIf
	End Select
	Return New SToken( TK_ERROR, "Unsupported sports-token ~q"+propertyName+"~q", params.GetToken(0) )
End Function



Function _EvaluateProgrammeDataCast:SToken(data:TProgrammeData, params:STokenGroup Var, tokenOffset:int, language:int) 'inline
	If Not params.HasToken(1 + tokenOffset, ETokenValueType.Integer)
		Return New SToken( TK_ERROR, "No valid cast number passed", params.GetToken(0) )
	EndIf

	Local castIndex:Int = Int(params.GetToken(1 + tokenOffset).GetValueLong())
	If castIndex < 0 Then Return New SToken( TK_ERROR, "Cast number must be positive", params.GetToken(0) )

	Local job:TPersonProductionJob = data.GetCastAtIndex(castIndex)
	If Not job Then Return New SToken( TK_ERROR, "Cast " + castIndex +" not found", params.GetToken(0) )

	Local person:TPersonBase = GetPersonBaseCollection().GetByID( job.personID )
	If Not person Then Return New SToken( TK_ERROR, "Cast " + castIndex +" person not found", params.GetToken(0) )
	
	Local includeTitle:Int
	If params.HasToken(3 + tokenOffset)
		includeTitle = params.GetToken(3 + tokenOffset).GetValueBool()
	EndIf

	Local propertyName:String = params.GetToken(2 + tokenOffset).value
	Select propertyName.ToLower()
		Case "firstname" Return New SToken( TK_TEXT, _getLocalizedPerson(person, language).GetFirstName(), params.GetToken(0) )
		Case "lastname"  Return New SToken( TK_TEXT, _getLocalizedPerson(person, language).GetLastName(includeTitle), params.GetToken(0) )
		Case "fullname"  Return New SToken( TK_TEXT, _getLocalizedPerson(person, language).GetFullName(includeTitle), params.GetToken(0) )
		Case "nickname"  Return New SToken( TK_TEXT, _getLocalizedPerson(person, language).GetNickName(), params.GetToken(0) )
		Case "title"     Return New SToken( TK_TEXT, _getLocalizedPerson(person, language).GetTitle(), params.GetToken(0) )
		Case "guid"      Return New SToken( TK_TEXT, person.GetGUID(), params.GetToken(0) )
		Case "id"        Return New SToken( TK_NUMBER, person.GetID(), params.GetToken(0) )
		Case "roleid"    Return New SToken( TK_TEXT, job.roleID, params.GetToken(0) )
		Case "hasrole"   Return New SToken( TK_BOOLEAN, Long(job.roleID<>0), params.GetToken(0) )

		Default          Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function


Function _EvaluateProgrammeDataRole:SToken(data:TProgrammeData, params:STokenGroup Var, tokenOffset:int, language:int) 'inline
	Local roleIndex:Int = Int(params.GetToken(1 + tokenOffset).GetValueLong())
	If roleIndex < 0 Then Return New SToken( TK_ERROR, "Role index must be positive", params.GetToken(0) )

	Local job:TPersonProductionJob = data.GetCastAtIndex(roleIndex)
	If Not job Then Return New SToken( TK_ERROR, "No cast at index " + roleIndex + " to look for assigned role", params.GetToken(0) )
	
	If job.roleID = 0 Then Return New SToken( TK_ERROR, "No role assigned to cast " + roleIndex, params.GetToken(0) )

	Local role:TProgrammeRole = GetProgrammeRoleCollection().GetByID( job.roleID )
	If Not role Then Return New SToken( TK_ERROR, "Role " + roleIndex +" not found", params.GetToken(0) )

	Local includeTitle:Int
	If params.HasToken(3 + tokenOffset)
		includeTitle = params.GetToken(3 + tokenOffset).GetValueBool()
	EndIf

	Local propertyName:String = params.GetToken(2 + tokenOffset).value
	Select propertyName.ToLower()
		Case "firstname" Return New SToken( TK_TEXT, _getLocalizedRole(role, language).GetFirstName(), params.GetToken(0) )
		Case "lastname"  Return New SToken( TK_TEXT, _getLocalizedRole(role, language).GetLastName(includeTitle), params.GetToken(0) )
		Case "fullname"  Return New SToken( TK_TEXT, _getLocalizedRole(role, language).GetFullName(includeTitle), params.GetToken(0) )
		Case "nickname"  Return New SToken( TK_TEXT, _getLocalizedRole(role, language).GetNickName(), params.GetToken(0) )
		Case "title"     Return New SToken( TK_TEXT, _getLocalizedRole(role, language).GetTitle(), params.GetToken(0) )
		case "countrycode" Return New SToken( TK_TEXT, role.countrycode, params.GetToken(0) )
		case "gender"    Return New SToken( TK_NUMBER, role.gender, params.GetToken(0) )
		Case "guid"      Return New SToken( TK_TEXT, role.GetGUID(), params.GetToken(0) )
		Case "id"        Return New SToken( TK_NUMBER, role.GetID(), params.GetToken(0) )
		case "fictional" Return New SToken( TK_BOOLEAN, role.fictional, params.GetToken(0) )

		Default          Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function


Function _getLocalizedPerson:TPersonBase(person:TPersonBase, language:Int)
	Local loc:TPersonBase = GetDatabaseLocalizer().getPersonNames(person.GetId(), language)
	If loc Then return loc
	Return person
EndFunction


Function _getLocalizedRole:TProgrammeRole(role:TProgrammeRole, language:Int)
	Local loc:TProgrammeRole = GetDatabaseLocalizer().getRoleNames(role.GetId(), language)
	If loc Then return loc
	Return role
EndFunction

'${.role:"guid"/id:"fullname"} - context: all
Function SEFN_role:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local role:TProgrammeRole
	Local token:SToken = params.GetToken(1)
	Local GUID:String = token.value
	Local ID:Long = token.GetValueLong()
	If GUID
		role = GetProgrammeRoleCollection().GetByGUID(GUID)
		If Not role Then Return New SToken( TK_ERROR, ".role with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
	Else
		role = GetProgrammeRoleCollection().GetByID(Int(ID))
		If Not role Then Return New SToken( TK_ERROR, ".role with ID ~q"+ID+"~q not found", params.GetToken(0) )
	EndIf

	Local includeTitle:Int
	If params.HasToken(3)
		includeTitle = params.GetToken(3).GetValueBool()
	EndIf

	Local propertyName:String = params.GetToken(2).value
	Select propertyName.ToLower()
		case "firstname"    Return New SToken( TK_TEXT, _getLocalizedRole(role, context.contextNumeric).GetFirstName(), params.GetToken(0) )
		case "lastname"     Return New SToken( TK_TEXT, _getLocalizedRole(role, context.contextNumeric).GetLastName(includeTitle), params.GetToken(0) )
		case "fullname"     Return New SToken( TK_TEXT, _getLocalizedRole(role, context.contextNumeric).GetFullName(includeTitle), params.GetToken(0) )
		Case "nickname"     Return New SToken( TK_TEXT, _getLocalizedRole(role, context.contextNumeric).GetNickName(), params.GetToken(0) )
		Case "title"        Return New SToken( TK_TEXT, _getLocalizedRole(role, context.contextNumeric).GetTitle(), params.GetToken(0) )
		case "countrycode"  Return New SToken( TK_TEXT, role.countrycode, params.GetToken(0) )
		case "gender"       Return New SToken( TK_NUMBER, role.gender, params.GetToken(0) )
		case "guid"         Return New SToken( TK_TEXT, role.GetGUID(), params.GetToken(0) )
		case "id"           Return New SToken( TK_NUMBER, role.GetID(), params.GetToken(0) )
		case "fictional"    Return New SToken( TK_BOOLEAN, role.fictional, params.GetToken(0) )

		default             Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function


'${.person:"guid"/id:"name"} - context: all
Function SEFN_person:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local person:TPersonBase
	Local token:SToken = params.GetToken(1)
	Local GUID:String = token.value
	Local ID:Long = token.GetValueLong()
	If GUID
		person = GetPersonBaseCollection().GetByGUID(GUID)
		If Not person Then Return New SToken( TK_ERROR, ".person with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
	Else
		person = GetPersonBaseCollection().GetByID(Int(ID))
		If Not person Then Return New SToken( TK_ERROR, ".person with ID ~q"+ID+"~q not found", params.GetToken(0) )
	EndIf
	
	Local includeTitle:Int = True
	If params.HasToken(3)
		includeTitle = params.GetToken(3).GetValueBool()
	EndIf
	
	Local propertyName:String = params.GetToken(2).value
	Select propertyName.ToLower()
		case "firstname"    Return New SToken( TK_TEXT, _getLocalizedPerson(person, context.contextNumeric).GetFirstName(), params.GetToken(0) )
		case "lastname"     Return New SToken( TK_TEXT, _getLocalizedPerson(person, context.contextNumeric).GetLastName(includeTitle), params.GetToken(0) )
		case "fullname"     Return New SToken( TK_TEXT, _getLocalizedPerson(person, context.contextNumeric).GetFullName(includeTitle), params.GetToken(0) )
		case "nickname"     Return New SToken( TK_TEXT, _getLocalizedPerson(person, context.contextNumeric).GetNickName(), params.GetToken(0) )
		case "title"        Return New SToken( TK_TEXT, _getLocalizedPerson(person, context.contextNumeric).GetTitle(), params.GetToken(0) )
		case "gender"       Return New SToken( TK_NUMBER, person.gender, params.GetToken(0) )
		case "guid"         Return New SToken( TK_TEXT, person.GetGUID(), params.GetToken(0) )
		case "id"           Return New SToken( TK_NUMBER, person.GetID(), params.GetToken(0) )
		case "age"          Return New SToken( TK_NUMBER, person.GetAge(), params.GetToken(0) )
		case "isalive"      Return New SToken( TK_BOOLEAN, person.IsAlive(), params.GetToken(0) )
		case "isdead"       Return New SToken( TK_BOOLEAN, person.IsDead(), params.GetToken(0) )
		case "isborn"       Return New SToken( TK_BOOLEAN, person.IsBorn(), params.GetToken(0) )
		case "iscelebrity"  Return New SToken( TK_BOOLEAN, person.IsCelebrity(), params.GetToken(0) )
		case "iscastable"   Return New SToken( TK_BOOLEAN, person.IsCastable(), params.GetToken(0) )
		case "isbookable"   Return New SToken( TK_BOOLEAN, person.IsBookable(), params.GetToken(0) )
		case "canlevelup"   Return New SToken( TK_BOOLEAN, person.CanLevelUp(), params.GetToken(0) )
		case "isfictional"  Return New SToken( TK_BOOLEAN, person.IsFictional(), params.GetToken(0) )
		case "ispolitician" Return New SToken( TK_BOOLEAN, person.IsPolitician(), params.GetToken(0) )
		case "ismusician"   Return New SToken( TK_BOOLEAN, person.IsMusician(), params.GetToken(0) )
		case "ispainter"    Return New SToken( TK_BOOLEAN, person.IsPainter(), params.GetToken(0) )
		case "iswriter"     Return New SToken( TK_BOOLEAN, person.IsWriter(), params.GetToken(0) )
		case "isartist"     Return New SToken( TK_BOOLEAN, person.IsArtist(), params.GetToken(0) )
		case "ismodel"      Return New SToken( TK_BOOLEAN, person.IsModel(), params.GetToken(0) )
		case "issportsman"  Return New SToken( TK_BOOLEAN, person.IsSportsman(), params.GetToken(0) )
		case "isadult"      Return New SToken( TK_BOOLEAN, person.IsAdult(), params.GetToken(0) )
		case "countrycode"  Return New SToken( TK_TEXT, person.GetCountryCode(), params.GetToken(0) )
		case "country"      Return New SToken( TK_TEXT, person.GetCountry(), params.GetToken(0) )
		case "countrylong"  Return New SToken( TK_TEXT, person.GetCountryLong(), params.GetToken(0) )
		case "popularity"   Return New SToken( TK_NUMBER, person.GetPopularityValue(), params.GetToken(0) )
		case "channelsympathy"
			if Not params.HasToken(3)
				If Not person Then Return New SToken( TK_ERROR, ".person ChannelSympathy requires channel parameter", params.GetToken(0) )
			else
				Local channel:Int = Int(params.GetToken(3).GetValueLong())
				Return New SToken( TK_NUMBER, person.GetChannelSympathy(channel), params.GetToken(0) )
			endif
		case "productionjobsdone"  Return New SToken( TK_NUMBER, person.GetTotalProductionJobsDone(), params.GetToken(0) )
		case "jobsdone"
			if Not params.HasToken(3)
				If Not person Then Return New SToken( TK_ERROR, ".person JobsDone requires jobID parameter", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueLong())
				Return New SToken( TK_NUMBER, person.GetJobsDone(jobID), params.GetToken(0) )
			endif
		case "effectivejobexperiencepercentage"
			if Not params.HasToken(3)
				If Not person Then Return New SToken( TK_ERROR, ".person EffectiveJobExperiencePercentage requires jobID parameter", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueLong())
				Return New SToken( TK_NUMBER, person.GetEffectiveJobExperiencePercentage(jobID), params.GetToken(0) )
			endif
		case "hasjob"
			if Not params.HasToken(3) 
				If Not person Then Return New SToken( TK_ERROR, ".person HasJob requires jobID parameter", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueLong())
				Return New SToken( TK_BOOLEAN, person.HasJob(jobID), params.GetToken(0) )
			endif
		case "haspreferredjob"
			if Not params.HasToken(3)
				If Not person Then Return New SToken( TK_ERROR, ".person HasPreferredJob requires jobID parameter", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueLong())
				Return New SToken( TK_BOOLEAN, person.HasPreferredJob(jobID), params.GetToken(0) )
			endif
		default             Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function



'${.script:"guid"/id:"title"} - context: all
'${.self:"title"} - context: TScript
Function SEFN_script:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	'non-self requires an offset of 1 to retrieve required property
	'${.self:"episodes"} - ${.myclass:"guid":"episodes"}
	Local tokenOffset:Int = 0
	Local script:TScript
	Local firstTokenIsSelf:Int = params.GetToken(0).GetValueText() = "self"

	If firstTokenIsSelf
		script = TScript(context.context)
		If Not script Then Return New SToken( TK_ERROR, ".self is not a TScript", params.GetToken(0) )
	Else
		Local GUID:String = params.GetToken(1).value
		Local ID:Long = params.GetToken(1).GetValueLong()
		If GUID
			script = GetScriptCollection().GetByGUID(GUID)
			If Not script Then Return New SToken( TK_ERROR, ".script with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
		Else
			script = GetScriptCollection().GetByID(Int(ID))
			If Not script Then Return New SToken( TK_ERROR, ".script with ID ~q"+ID+"~q not found", params.GetToken(0) )
		EndIf
		tokenOffset = 1
	EndIf
	
	Local propertyName:String = params.GetToken(1 + tokenOffset).value 
	Local propertyNameLower:String = propertyName.ToLower()

	If propertyNameLower = "parent"
		'access via parent ID does not work as scripts are added to the collection only after creation is finished
		If Not script._parentScriptTmp Then Return New SToken( TK_ERROR, ".self has no parent", params.GetToken(0) )
		script = script._parentScriptTmp
		firstTokenIsSelf = False
		propertyName = params.GetToken(2 + tokenOffset).value
		propertyNameLower = propertyName.ToLower()
	EndIf
	
	'do not allow title/description for "self" as this is prone
	'to a recursive call (description requesting description)
	if not firstTokenIsSelf
		Select propertyNameLower
			Case "title"        Return New SToken( TK_TEXT, script.GetTitle(), params.GetToken(0) )
			Case "description"  Return New SToken( TK_TEXT, script.GetDescription(), params.GetToken(0) )
		End Select
	EndIf
	
	Select propertyNameLower
		Case "role"
			Local roleIndex:Int = Int(params.GetToken(2 + tokenOffset).GetValueLong())
 			If roleIndex < 0 Then Return New SToken( TK_ERROR, "role index must be positive.", params.GetToken(0) )

			Local actors:TPersonProductionJob[] = script.GetJobs()
			If roleIndex >= actors.length Then Return New SToken( TK_ERROR, "(not enough actors for role #" + roleIndex+".)", params.GetToken(0) )

			Local role:TProgrammeRole = TScript._EnsureRole(actors[roleIndex])
			role = _getLocalizedRole(role, context.contextNumeric)

			Local subCommand:String = params.GetToken(3 + tokenOffset).GetValueText()
			Select subCommand.ToLower()
				Case "firstname"  Return New SToken( TK_TEXT, role.GetFirstName(), params.GetToken(0) )
				Case "lastname"   Return New SToken( TK_TEXT, role.GetLastName(), params.GetToken(0) )
				Case "fullname"   Return New SToken( TK_TEXT, role.GetFullName(), params.GetToken(0) )
				Case "nickname"   Return New SToken( TK_TEXT, role.GetNickName(), params.GetToken(0) )
				Case "title"      Return New SToken( TK_TEXT, role.GetTitle(), params.GetToken(0) )
				'TODO weitere properties, fullname with title flag?sollten hier nicht die wichtigsten anderen properties unterstützt und im Defaultfall ein Error-Token zurückgegeben werden? 
				Default           Return New SToken( TK_ERROR, "unknown property ~q" + subCommand + "~q", params.GetToken(0) )
			End Select
		Case "episodes"         Return New SToken( TK_NUMBER, script.GetEpisodes(), params.GetToken(0) )
		Case "genre"            Return New SToken( TK_NUMBER, script.GetMainGenre(), params.GetToken(0) )
		Case "genrestring"      Return New SToken( TK_NUMBER, script.GetMainGenreString(), params.GetToken(0) )
		case "guid"             Return New SToken( TK_TEXT, script.GetGUID(), params.GetToken(0) )
		case "id"               Return New SToken( TK_NUMBER, script.GetID(), params.GetToken(0) )
		case "parentid"         Return New SToken( TK_NUMBER, script.parentScriptID, params.GetToken(0) )

		Default                 Return New SToken( TK_ERROR, "unknown property ~q" + propertyName + "~q", params.GetToken(0) )
	End Select
End Function



'${.sport:"guid"/id:"name"} - context: all
Function SEFN_sport:SToken(params:STokenGroup Var, context:SScriptExpressionContext)
	Local sport:TNewsEventSport
	Local token:SToken = params.GetToken(1)
	Local GUID:String = token.value
	Local ID:Long = token.GetValueLong()
	If GUID
		sport = GetNewsEventSportCollection().GetByGUID(GUID)
		If Not sport Then Return New SToken( TK_ERROR, ".sport with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
	Else
		sport = GetNewsEventSportCollection().GetByID(Int(ID))
		If Not sport Then Return New SToken( TK_ERROR, ".sport with ID ~q"+ID+"~q not found", params.GetToken(0) )
	EndIf
	
	Return _EvaluateNewsEventSport(sport, params, 2, context.contextNumeric)
End Function


'${.sportleague:"guid"/id:"name"} - context: all
Function SEFN_sportleague:SToken(params:STokenGroup Var, context:SScriptExpressionContext)
	Local league:TNewsEventSportLeague
	Local token:SToken = params.GetToken(1)
	Local GUID:String = token.value
	Local ID:Long = token.GetValueLong()
	If GUID
		league = GetNewsEventSportCollection().GetLeague(GUID)
		If Not league Then Return New SToken( TK_ERROR, ".sportleague with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
	Else
		league = GetNewsEventSportCollection().GetLeague(Int(ID))
		If Not league Then Return New SToken( TK_ERROR, ".sportleague with ID ~q"+ID+"~q not found", params.GetToken(0) )
	EndIf
	
	Return _EvaluateNewsEventSportLeague(league, params, 2, context.contextNumeric)
End Function


'${.sportteam:"guid"/id:"name"} - context: all
Function SEFN_sportteam:SToken(params:STokenGroup Var, context:SScriptExpressionContext)
	Local team:TNewsEventSportTeam
	Local token:SToken = params.GetToken(1)
	Local GUID:String = token.value
	Local ID:Long = token.GetValueLong()
	If GUID
		team = GetNewsEventSportCollection().GetTeam(GUID)
		If Not team Then Return New SToken( TK_ERROR, ".sportteam with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
	Else
		team = GetNewsEventSportCollection().GetTeam(Int(ID))
		If Not team Then Return New SToken( TK_ERROR, ".sportteam with ID ~q"+ID+"~q not found", params.GetToken(0) )
	EndIf
	
	Return _EvaluateNewsEventSportTeam(team, params, 2, context.contextNumeric)
End Function


Function _EvaluateNewsEventSport:SToken(sport:TNewsEventSport, params:STokenGroup Var, tokenOffset:int, language:Int) 'inline
	If params.added <= tokenOffset Then Return New SToken( TK_ERROR, "No subcommand given", params.GetToken(0) )
	
	Local propertyName:String = params.GetToken(tokenOffset).value

	Select propertyName.ToLower()
		case "name"                 Return New SToken( TK_TEXT, GetLocale("SPORT_"+sport.name, language), params.GetToken(0) )
		case "leaguecount"          Return New SToken( TK_NUMBER, sport.leagues.length, params.GetToken(0) )
		case "league"
			Local leagueIndex:Int = Int(params.GetToken(tokenOffset + 1).GetValueLong())
			If sport.leagues.length < 0 or sport.leagues.length <= leagueIndex or not sport.leagues[leagueIndex] 
				Return New SToken( TK_ERROR, "No league at index " + leagueIndex + " found", params.GetToken(0) )
			EndIf
			Return _EvaluateNewsEventSportLeague(sport.leagues[leagueIndex], params, tokenOffset + 2, language)
		case "isseasonstarted"      Return New SToken( TK_BOOLEAN, sport.IsSeasonStarted(), params.GetToken(0) )
		case "isseasonfinished"     Return New SToken( TK_BOOLEAN, sport.IsSeasonFinished(), params.GetToken(0) )
		case "areplayoffsrunning"   Return New SToken( TK_BOOLEAN, sport.ArePlayoffsRunning(), params.GetToken(0) )
		case "areplayoffsfinished"  Return New SToken( TK_BOOLEAN, sport.ArePlayoffsFinished(), params.GetToken(0) )
		case "getnextmatchtime"     Return New SToken( TK_NUMBER, sport.GetNextMatchTime(), params.GetToken(0) )
		case "getfirstmatchtime"    Return New SToken( TK_NUMBER, sport.GetFirstMatchTime(), params.GetToken(0) )
		case "getlastmatchtime"     Return New SToken( TK_NUMBER, sport.GetLastMatchTime(), params.GetToken(0) )
		case "getlastmatchendtime"  Return New SToken( TK_NUMBER, sport.GetLastMatchEndTime(), params.GetToken(0) )
		'nameraw is the internal "type appendix"/name of the sport ("SOCCER") 
		'instead of a text value which can be/is localized 
		case "nameraw"              Return New SToken( TK_TEXT, sport.name, params.GetToken(0) )
		default                     Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function



Function _EvaluateNewsEventSportLeague:SToken(league:TNewsEventSportLeague, params:STokenGroup Var, tokenOffset:int, language:Int) 'inline
	If params.added <= tokenOffset Then Return New SToken( TK_ERROR, "No subcommand given", params.GetToken(0) )
	
	Local propertyName:String = params.GetToken(tokenOffset).value

	Select propertyName.ToLower()
		case "name"                 Return New SToken( TK_TEXT, league.name, params.GetToken(0) )
		case "nameshort"            Return New SToken( TK_TEXT, league.nameShort, params.GetToken(0) )
		case "matchcount"           Return New SToken( TK_NUMBER, league.GetMatchCount(), params.GetToken(0) )
		case "upcomingmatchcount"   Return New SToken( TK_NUMBER, league.GetUpcomingMatchesCount(), params.GetToken(0) )
		case "getnextmatchtime"     Return New SToken( TK_NUMBER, league.GetNextMatchTime(), params.GetToken(0) )
		case "getfirstmatchtime"    Return New SToken( TK_NUMBER, league.GetFirstMatchTime(), params.GetToken(0) )
		case "getlastmatchtime"     Return New SToken( TK_NUMBER, league.GetLastMatchTime(), params.GetToken(0) )
		case "getlastmatchendtime"  Return New SToken( TK_NUMBER, league.GetLastMatchEndTime(), params.GetToken(0) )
		case "matchtimesformatted"	
			Return New SToken( TK_TEXT, league.GetMatchTimesFormatted(False, True, language), params.GetToken(0) )
		case "upcomingmatchtimesformatted"	
			Return New SToken( TK_TEXT, league.GetMatchTimesFormatted(True, True, language), params.GetToken(0) )
		default                     Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function



Function _EvaluateNewsEventSportMatch:SToken(match:TNewsEventSportMatch, params:STokenGroup Var, tokenOffset:int, language:Int) 'inline
	If params.added <= tokenOffset Then Return New SToken( TK_ERROR, "No subcommand given", params.GetToken(0) )
	
	Local propertyName:String = params.GetToken(tokenOffset).value

	Select propertyName.ToLower()
		case "nameshort"
			Return New SToken( TK_TEXT, match.GetNameShort(), params.GetToken(0) )
		case "teamcount"
			Return New SToken( TK_NUMBER, match.teams.length, params.GetToken(0) )
		case "team"
			Local teamIndex:Int = Int(params.GetToken(tokenOffset + 1).GetValueLong())
			If match.teams.length < 0 or match.teams.length <= teamIndex or not match.teams[teamIndex] 
				Return New SToken( TK_ERROR, "No team at index " + teamIndex + " found", params.GetToken(0) )
			EndIf
			Return _EvaluateNewsEventSportTeam(match.teams[teamIndex], params, tokenOffset + 2, language)
		case "rank"
			Local teamIndex:Int = Int(params.GetToken(tokenOffset + 1).GetValueLong())
			If match.teams.length < 0 or match.teams.length <= teamIndex or not match.teams[teamIndex] 
				Return New SToken( TK_ERROR, "No team at index " + teamIndex + " found", params.GetToken(0) )
			EndIf
			Return New SToken( TK_NUMBER, match.GetRank(match.teams[teamIndex]), params.GetToken(0) )
		case "score"
			Local teamIndex:Int = Int(params.GetToken(tokenOffset + 1).GetValueLong())
			If match.teams.length < 0 or match.teams.length <= teamIndex or not match.teams[teamIndex] 
				Return New SToken( TK_ERROR, "No team at index " + teamIndex + " found", params.GetToken(0) )
			EndIf
			Return New SToken( TK_NUMBER, match.GetScore(match.teams[teamIndex]), params.GetToken(0) )
		case "finalscoretext"
			Return New SToken( TK_TEXT, match.GetFinalScoreText(), params.GetToken(0) )
		case "resulttext"
			Return New SToken( TK_TEXT, match.GetResultText(), params.GetToken(0) )
		case "playtimeminutes"
			Return New SToken( TK_NUMBER, match.GetPlaytimeMinutes(), params.GetToken(0) )
		case "report"
			Return New SToken( TK_TEXT, match.GetReport(), params.GetToken(0) )
		case "reportshort"
			Local mode:String = params.GetToken(tokenOffset + 1).value
			Return New SToken( TK_TEXT, match.GetReportShort(mode), params.GetToken(0) )
		case "livereportshort"
			Local mode:String = params.GetToken(tokenOffset + 1).value
			Local time:Long = -1
			If params.HasToken(tokenOffset + 2) Then time = params.GetToken(tokenOffset + 2).GetValueLong()
			Return New SToken( TK_TEXT, match.GetLiveReportShort(mode, time), params.GetToken(0) )
		case "time"
			Return New SToken( TK_NUMBER, match.GetMatchTime(), params.GetToken(0) )
		case "endtime"
			Return New SToken( TK_NUMBER, match.GetMatchEndtime(), params.GetToken(0) )
		case "looserscore"
			Return New SToken( TK_NUMBER, match.GetLooserScore(), params.GetToken(0) )
		case "winnerscore"
			Return New SToken( TK_NUMBER, match.GetWinnerScore(), params.GetToken(0) )
		case "drawgamescore"
			Return New SToken( TK_NUMBER, match.GetDrawGameScore(), params.GetToken(0) )
		case "isrun"
			Return New SToken( TK_BOOLEAN, match.IsRun(), params.GetToken(0) )
		case "haswinner"
			Return New SToken( TK_BOOLEAN, match.HasWinner(), params.GetToken(0) )
		case "haslooser"
			Return New SToken( TK_BOOLEAN, match.HasLooser(), params.GetToken(0) )
		case "winner"
			Return New SToken( TK_NUMBER, match.GetWinner(), params.GetToken(0) )
		default
			Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function



Function _EvaluateNewsEventSportTeam:SToken(team:TNewsEventSportTeam, params:STokenGroup Var, tokenOffset:int, language:Int) 'inline
	If params.added <= tokenOffset Then Return New SToken( TK_ERROR, "No subcommand given", params.GetToken(0) )
	
	Local propertyName:String = params.GetToken(tokenOffset).value

	Select propertyName.ToLower()
		case "trainer"
			If not team.trainer
				Return New SToken( TK_ERROR, "No trainer found", params.GetToken(0) )
			EndIf
			Return _EvaluateNewsEventSportTeamMember(team.trainer, params, tokenOffset + 1, language)
		case "member"
			Local member:TPersonBase
			If params.HasToken(tokenOffset + 1, ETokenValueType.Text)
				Local memberType:String = params.GetToken(tokenOffset + 1).value
				Local offsetPos:Int = memberType.Find(",")
				Local offset:Int
				If offsetPos > 0 
					offset = Int(memberType[offsetPos+1 ..])
					memberType = memberType[.. offsetPos]
					print "offset = " + offset
					print "memberType = " + memberType
				EndIf
				member = team.GetMemberOfType( memberType, offset )
				If not member 
					Return New SToken( TK_ERROR, "No member of type ~q" + memberType + "~q (offset="+offset+") found", params.GetToken(0) )
				EndIf
			Else
				'numeric index, if no value was given, index will be 0
				member = team.GetMemberAtIndex( Int(params.GetToken(tokenOffset + 1).GetValueLong()) )
				If not member 
					Return New SToken( TK_ERROR, "No member at index " + params.GetToken(tokenOffset + 1).GetValueLong() + " found", params.GetToken(0) )
				EndIf
			EndIf
			Return _EvaluateNewsEventSportTeamMember(member, params, tokenOffset + 2, language)
		case "city"     
			Return New SToken( TK_TEXT, team.GetCity(), params.GetToken(0) )
		case "leaguerank"
			Return New SToken( TK_TEXT, team.GetLeagueRank(), params.GetToken(0) )
		case "leaguerank"
			Return New SToken( TK_TEXT, team.GetLeagueRank(), params.GetToken(0) )
		case "teamname"
			Return New SToken( TK_TEXT, team.GetTeamName(), params.GetToken(0) )
		case "teamnamewitharticle"
			Local variant:Int = 1
			If params.HasToken(tokenOffset + 1) 
				variant = Int(params.GetToken(tokenOffset + 1).GetValueLong())
			EndIf
			Select variant
				case 2
					If team.clubNameSingular
						Return New SToken( TK_TEXT, GetLocale("SPORT_TEAMNAME_S_VARIANT_B", language) + " " + team.GetTeamName(), params.GetToken(0) )
					Else
						Return New SToken( TK_TEXT, GetLocale("SPORT_TEAMNAME_P_VARIANT_B", language) + " " + team.GetTeamName(), params.GetToken(0) )
					EndIf
				default
					If team.clubNameSingular
						Return New SToken( TK_TEXT, GetLocale("SPORT_TEAMNAME_S_VARIANT_A", language) + " " + team.GetTeamName(), params.GetToken(0) )
					Else
						Return New SToken( TK_TEXT, GetLocale("SPORT_TEAMNAME_P_VARIANT_A", language) + " " + team.GetTeamName(), params.GetToken(0) )
					EndIf
			End Select
		case "teamnamearticle"
			Local variant:Int = 1
			If params.HasToken(tokenOffset + 1) 
				variant = Int(params.GetToken(tokenOffset + 1).GetValueLong())
			EndIf
			Select variant
				case 2
					If team.clubNameSingular
						Return New SToken( TK_TEXT, GetLocale("SPORT_TEAMNAME_S_VARIANT_B", language), params.GetToken(0) )
					Else
						Return New SToken( TK_TEXT, GetLocale("SPORT_TEAMNAME_P_VARIANT_B", language), params.GetToken(0) )
					EndIf
				default
					If team.clubNameSingular
						Return New SToken( TK_TEXT, GetLocale("SPORT_TEAMNAME_S_VARIANT_A", language), params.GetToken(0) )
					Else
						Return New SToken( TK_TEXT, GetLocale("SPORT_TEAMNAME_P_VARIANT_A", language), params.GetToken(0) )
					EndIf
			End Select
		case "teamnameshort"
			Return New SToken( TK_TEXT, team.GetTeamNameShort(), params.GetToken(0) )
		case "teaminitials"
			Return New SToken( TK_TEXT, team.GetTeamInitials(), params.GetToken(0) )
		case "teamnameissingular"
			Return New SToken( TK_BOOLEAN, team.clubNameSingular, params.GetToken(0) )
		case "leagueid"
			Return New SToken( TK_NUMBER, team.leagueID, params.GetToken(0) )
		case "league"
			Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeague(team.leagueID)
			If Not league
				Return New SToken( TK_ERROR, "No valid league found for team", params.GetToken(0) )
			EndIf
			Return _EvaluateNewsEventSportLeague(league, params, tokenOffset + 1, language)
		default
			Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function



Function _EvaluateNewsEventSportTeamMember:SToken(member:TPersonBase, params:STokenGroup Var, tokenOffset:int, language:Int) 'inline
	If Not member Then Return New SToken( TK_ERROR, "No member instance passed", params.GetToken(0) )

	If params.added <= tokenOffset Then Return New SToken( TK_ERROR, "No subcommand given", params.GetToken(0) )

rem
	'evaluate person stuff first (name etc), then type special things
	Local result:SToken =_EvaluatePersonBase(member, params, tokenOffset)			

	If result.id = TK_ERROR 'not evaluated (or real error)
		If member.IsSportsman()
			'load the "current" sportdata set (no special sport-type requested) 
			Local sportData:TPersonSportBaseData = TPersonSportBaseData(member.GetData("sport"))
			If sportData
				Select params.GetToken(tokenOffset).value.ToLower()
					case "teamid"  Return New SToken( TK_TEXT, sportData.teamID, params.GetToken(0) )
					case "sportid" Return New SToken( TK_TEXT, sportData.sportID, params.GetToken(0) )
				End Select
			EndIf
		EndIf
	EndIf
	Return result 'person-token-result is already an error
endrem	
	Local includeTitle:Int
	If params.HasToken(1 + tokenOffset)
		includeTitle = params.GetToken(1 + tokenOffset).GetValueBool()
	EndIf
	Local subCommand:String = params.GetToken(tokenOffset).value 'MUST be a string
	Local subCommandLower:String = subCommand.ToLower()
	Select subCommandLower
		Case "firstname" Return New SToken( TK_TEXT, member.GetFirstName(), params.GetToken(0) )
		Case "lastname"  Return New SToken( TK_TEXT, member.GetLastName(includeTitle), params.GetToken(0) )
		Case "fullname"  Return New SToken( TK_TEXT, member.GetFullName(includeTitle), params.GetToken(0) )
		Case "nickname"  Return New SToken( TK_TEXT, member.GetNickName(), params.GetToken(0) )
		Case "title"     Return New SToken( TK_TEXT, member.GetTitle(), params.GetToken(0) )
		Case "guid"      Return New SToken( TK_TEXT, member.GetGUID(), params.GetToken(0) )
		Case "id"        Return New SToken( TK_NUMBER, member.GetID(), params.GetToken(0) )
	End Select

	If member.IsSportsman()
		'load the "current" sportdata set (no special sport-type requested) 
		Local sportData:TPersonSportBaseData = TPersonSportBaseData(member.GetData("sport"))
		If sportData
			Select subCommandLower
				case "teamid"  Return New SToken( TK_TEXT, sportData.teamID, params.GetToken(0) )
				case "sportid" Return New SToken( TK_TEXT, sportData.sportID, params.GetToken(0) )
			End Select
		EndIf
	EndIf
	Return New SToken( TK_ERROR, "Undefined command ~q"+subCommand+"~q", params.GetToken(0) )
End Function


rem
Function _EvaluatePersonBase:SToken(person:TPersonBase, params:STokenGroup Var, tokenOffset:int) 'inline
	If Not person Then Return New SToken( TK_ERROR, "No person instance passed", params.GetToken(0) )
	
	Local includeTitle:Int
	If params.HasToken(1 + tokenOffset)
		includeTitle = params.GetToken(1 + tokenOffset).GetValueBool()
	EndIf
	
	Local subCommand:String = params.GetToken(tokenOffset).value 'MUST be a string

	Select subCommand.ToLower()
		Case "firstname" Return New SToken( TK_TEXT, person.GetFirstName(), params.GetToken(0) )
		Case "lastname"  Return New SToken( TK_TEXT, person.GetLastName(includeTitle), params.GetToken(0) )
		Case "fullname"  Return New SToken( TK_TEXT, person.GetFullName(includeTitle), params.GetToken(0) )
		Case "nickname"  Return New SToken( TK_TEXT, person.GetNickName(), params.GetToken(0) )
		Case "title"     Return New SToken( TK_TEXT, person.GetTitle(), params.GetToken(0) )
		Case "guid"      Return New SToken( TK_TEXT, person.GetGUID(), params.GetToken(0) )
		Case "id"        Return New SToken( TK_NUMBER, person.GetID(), params.GetToken(0) )

		default          Return New SToken( TK_ERROR, "Undefined command ~q"+subCommand+"~q", params.GetToken(0) )
	End Select
End Function
endrem

'various "self"-referencing options
'context: TProgrammeLicence
'context: TProgrammeData
Function SEFN_self:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	If TProgrammeData(context.context)
		return SEFN_programmedata(params, context)
	ElseIf TProgrammeLicence(context.context)
'		Local subContext:SScriptExpressionContext = New SScriptExpressionContext(TProgrammeLicence(context.context).data, context.contextNumeric, context.extra)
		'return SEFN_programmelicence(params, subContext)
		return SEFN_programmelicence(params, context)
	ElseIf TScript(context.context)
		return SEFN_script(params, context)
	ElseIf TNewsEvent(context.context)
		return SEFN_newsevent(params, context)
	EndIf
End Function



Type TGameScriptExpression extends TGameScriptExpressionBase
	Method New()
		'set custom config for variable handlers etc
		'self.config = New TScriptExpressionConfig(null, null, null )
		self.config.s.variableHandlerCB = TGameScriptExpression.GameScriptVariableHandlerCB
	End Method


	'override to add support for template variables
	Function GameScriptVariableHandlerCB:String(variable:String, context:SScriptExpressionContext var) override
		Local result:String
		Local localeID:Int = context.contextNumeric
		Local tv:TTemplateVariables
		Local resolved:Int = True
		
		'explicitely passed template vars? higher priority than context-provided ones
		If TTemplateVariables(context.extra)
			tv = TTemplateVariables(context.extra)
		'check if the passed context is one we know it has template variables
		Else
			If TScriptTemplate(context.context)
				tv = TScriptTemplate(context.context).templateVariables
			ElseIf TScript(context.context)
				' TScript does not offer own variables, so fall back to
				' use the variables of the template it bases on (if it does)
				Local basedOnScriptTemplateID:Int = TScript(context.context).basedOnScriptTemplateID
				If basedOnScriptTemplateID
					Local template:TScriptTemplate = GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
					If template
						tv = template.templateVariables
					EndIf
				EndIf
			ElseIf TNewsEvent(context.context)
				tv = TNewsEvent(context.context).templateVariables
			ElseIf TNewsEventTemplate(context.context)
				tv = TNewsEventTemplate(context.context).templateVariables
			EndIf
		EndIf

		Local varLowerCase:String = variable.ToLower()
		If tv
			result = _ParseWithTemplateVariables(varLowerCase, context, tv, resolved)
		Else
			resolved = False
		EndIf
		If Not Resolved
			'parsing expression if it contains further variables necessary? 
			'${.worldtime:"year"} was resolved without further changes...
			result = GetDatabaseLocalizer().getGlobalVariable(localeID, varLowerCase, True)
			If Not result Then result = TGameScriptExpressionBase.GameScriptVariableHandlerCB(variable, context)
		EndIf

		Return result
	End Function


	Function _ParseWithTemplateVariables:String(variableLowerCase:String, context:SScriptExpressionContext, tv:TTemplateVariables = Null, success:Int var)
		If not tv and TTemplateVariables(context.extra)
			tv = TTemplateVariables(context.extra)
		EndIf
		If Not tv
			success = False
			Return TGameScriptExpressionBase.GameScriptVariableHandlerCB(variableLowerCase, context)
		EndIf
		
		'store the template variables as context (working on a copy here!)
		context.extra = tv 
		
		Local result:String
		Local localeID:Int = context.contextNumeric

		' Create a localized string only containing resolved variables
		' (the single option "Beaver" is chosen from the variable value "Ape|Beaver|Camel") 
		Local lsResult:TLocalizedString = tv.GetResolvedVariable(variableLowerCase, 0, True)

		' The result MIGHT contain script expressions itself 
		' -> parse it and replace the resolved variable accordingly
		' -> this allows to only evaluate it once instead of on each
		'    request
		' The whole "GameScriptVariableHandlerCB" is called ONCE per language
		' so we only need to parse the specific language value here!
		If lsResult
			result = lsResult.Get( localeID )
			local resultNew:TStringBuilder = GameScriptExpression.ParseNestedExpressionText(result, context)

			'avoid string creation and compare hashes first
			If result.hash() <> resultNew.hash()
				result = resultNew.ToString()
				'store the newly parsed expression result
				lsResult.Set(result, localeID)
			EndIf
		' lsResult can be null if the variable was not resolved (or is
		' not contained in the variables collection)
		Else
			success = False
			Return TGameScriptExpressionBase.GameScriptVariableHandlerCB(variableLowerCase, context)
		EndIf
		
		Return result
	End Function
End Type
