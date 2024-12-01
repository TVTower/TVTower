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

GameScriptExpression.RegisterFunctionHandler( "programmedata", SEFN_programmedata, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "programmelicence", SEFN_programmelicence, 2, 3) '
GameScriptExpression.RegisterFunctionHandler( "programme", SEFN_programmelicence, 2, 3) 'synonym usage
GameScriptExpression.RegisterFunctionHandler( "role", SEFN_role, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "person", SEFN_person, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "locale", SEFN_locale, 1, 2)
GameScriptExpression.RegisterFunctionHandler( "script", SEFN_script, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "stationmap", SEFN_StationMap, 1, 1)
GameScriptExpression.RegisterFunctionHandler( "persongenerator", SEFN_PersonGenerator, 1, 3)
GameScriptExpression.RegisterFunctionHandler( "worldtime", SEFN_WorldTime, 1, 1)




'${.worldTime:***} - context: all
'${.worldTime:"year"}
'${.worldTime:"isnight"}
Function SEFN_WorldTime:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local command:String = params.GetToken(0).GetValueText()
	Local subCommand:String = params.GetToken(1).value 'MUST be a string

	'TODO formatted date, weekdayname?
	Select subCommand.ToLower()
		case "year"         Return New SToken( TK_NUMBER, GetWorldTime().GetYear(), params.GetToken(0) )
		case "month"        Return New SToken( TK_NUMBER, GetWorldTime().GetMonth(), params.GetToken(0) )
		case "day"          Return New SToken( TK_NUMBER, GetWorldTime().GetDay(), params.GetToken(0) )
		case "hour"         Return New SToken( TK_NUMBER, GetWorldTime().GetDayHour(), params.GetToken(0) )
		case "minute"       Return New SToken( TK_NUMBER, GetWorldTime().GetDayMinute(), params.GetToken(0) )
		case "daysplayed"   Return New SToken( TK_NUMBER, GetWorldTime().GetDaysRun(), params.GetToken(0) )
		case "dayplaying"   Return New SToken( TK_NUMBER, GetWorldTime().GetDaysRun() + 1, params.GetToken(0) )
		case "yearsplayed"  Return New SToken( TK_NUMBER, int(floor(GetWorldTime().GetDaysRun() / GetWorldTime().GetDaysPerYear())), params.GetToken(0) )
		'attention, use the weekday depending on game start (day 1
		'of a game is always a monday... ani: no it is not)
		'case "weekday"     Return string( GetWorldTime().GetWeekdayByDay( GetWorldTime().GetDaysRun() ) )
		'this would return weekday of the exact start date
		'so 1985/1/1 is a different weekday than 1986/1/1
		case "weekday"      Return New SToken( TK_NUMBER, GetWorldTime().GetWeekday(), params.GetToken(0) )
		case "season"       Return New SToken( TK_NUMBER, GetWorldTime().GetSeason(), params.GetToken(0) )
		case "dayofmonth"   Return New SToken( TK_NUMBER, GetWorldTime().GetDayOfMonth(), params.GetToken(0) )
		case "dayofyear"    Return New SToken( TK_NUMBER, GetWorldTime().GetDayOfYear(), params.GetToken(0) )
		case "isnight"      Return New SToken( TK_BOOLEAN, GetWorldTime().IsNight(), params.GetToken(0) )
		case "isdawn"       Return New SToken( TK_BOOLEAN, GetWorldTime().IsDawn(), params.GetToken(0) )
		case "isday"        Return New SToken( TK_BOOLEAN, GetWorldTime().IsDay(), params.GetToken(0) )
		case "isdusk"       Return New SToken( TK_BOOLEAN, GetWorldTime().IsDusk(), params.GetToken(0) )
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




'${.locale:"localekey":"optional: language"} - context: all
'TODO support randomlocale?
Function SEFN_locale:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	If params.HasToken(1)
		Local key:String = params.GetToken(1).GetValueText()
		If params.HasToken(2)
			Local languageCode:String = params.GetToken(2).value 'MUST be a string
			Return New SToken( TK_TEXT, GetLocale(key, languageCode), params.GetToken(0) )
		Else
			Local localeID:Int = context.contextNumeric
			Return New SToken( TK_TEXT, GetLocale(key, localeID), params.GetToken(0) )
		EndIf
	Else
		Return New SToken( TK_ERROR, "No locale key passed", params.GetToken(0) )
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
		Local ID:Long = params.GetToken(1).valueLong
		If GUID
			licence = GetProgrammeLicenceCollection().GetByGUID(GUID)
			If Not licence Then Return New SToken( TK_ERROR, ".programmelicence with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
		ElseIf ID <> 0
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
	
	Select propertyName
		Case "cast"                    Return _EvaluateProgrammeDataCast(licence.data, params, 1 + tokenOffset)
		'convenience access - could be removed if one uses ${.role:${.self:"cast":x:"roleid"}:"fullname"} ...
		Case "role"                    Return _EvaluateProgrammeDataRole(licence.data, params, 1 + tokenOffset)
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
		Local ID:Long = params.GetToken(1).valueLong
		If GUID
			data = GetProgrammeDataCollection().GetByGUID(GUID)
			If Not data Then Return New SToken( TK_ERROR, ".programmedata with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
		ElseIf ID <> 0
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

	'do not allow title/description for "self" as this is prone
	'to a recursive call (description requesting description)
	if not firstTokenIsSelf
		Select propertyName
			Case "title"               Return New SToken( TK_TEXT, data.GetTitle(), params.GetToken(0) )
			Case "description"         Return New SToken( TK_TEXT, data.GetDescription(), params.GetToken(0) )
		End Select
	EndIf
	
	Select propertyName
		Case "cast"                    Return _EvaluateProgrammeDataCast(data, params, 1 + tokenOffset)
		'convenience access - could be removed if one uses ${.role:${.self:"cast":x:"roleid"}:"fullname"} ...
		Case "role"                    Return _EvaluateProgrammeDataRole(data, params, 1 + tokenOffset)
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

		Default                        Return New SToken( TK_ERROR, "Unknown property ~q" + propertyName + "~q", params.GetToken(0) )
	End Select
End Function


Function _EvaluateProgrammeDataCast:SToken(data:TProgrammeData, params:STokenGroup Var, tokenOffset:int) 'inline
	If Not params.HasToken(1 + tokenOffset, ETokenValueType.Integer)
		Return New SToken( TK_ERROR, "No valid cast number passed", params.GetToken(0) )
	EndIf

	Local castIndex:Int = params.GetToken(1 + tokenOffset).valueLong
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
		Case "firstname" Return New SToken( TK_TEXT, person.GetFirstName(), params.GetToken(0) )
		Case "lastname"  Return New SToken( TK_TEXT, person.GetLastName(includeTitle), params.GetToken(0) )
		Case "fullname"  Return New SToken( TK_TEXT, person.GetFullName(includeTitle), params.GetToken(0) )
		Case "nickname"  Return New SToken( TK_TEXT, person.GetNickName(), params.GetToken(0) )
		Case "title"     Return New SToken( TK_TEXT, person.GetTitle(), params.GetToken(0) )
		Case "guid"      Return New SToken( TK_TEXT, person.GetGUID(), params.GetToken(0) )
		Case "id"        Return New SToken( TK_NUMBER, person.GetID(), params.GetToken(0) )
		Case "roleid"    Return New SToken( TK_TEXT, job.roleID, params.GetToken(0) )
		Case "hasrole"   Return New SToken( TK_BOOLEAN, Long(job.roleID<>0), params.GetToken(0) )

		Default          Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function


Function _EvaluateProgrammeDataRole:SToken(data:TProgrammeData, params:STokenGroup Var, tokenOffset:int) 'inline
	Local roleIndex:Int = params.GetToken(1 + tokenOffset).valueLong
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
		Case "firstname" Return New SToken( TK_TEXT, role.GetFirstName(), params.GetToken(0) )
		Case "lastname"  Return New SToken( TK_TEXT, role.GetLastName(includeTitle), params.GetToken(0) )
		Case "fullname"  Return New SToken( TK_TEXT, role.GetFullName(includeTitle), params.GetToken(0) )
		Case "nickname"  Return New SToken( TK_TEXT, role.GetNickName(), params.GetToken(0) )
		Case "title"     Return New SToken( TK_TEXT, role.GetTitle(), params.GetToken(0) )
		case "countrycode" Return New SToken( TK_TEXT, role.countrycode, params.GetToken(0) )
		case "gender"    Return New SToken( TK_NUMBER, role.gender, params.GetToken(0) )
		Case "guid"      Return New SToken( TK_TEXT, role.GetGUID(), params.GetToken(0) )
		Case "id"        Return New SToken( TK_NUMBER, role.GetID(), params.GetToken(0) )
		case "fictional" Return New SToken( TK_BOOLEAN, role.fictional, params.GetToken(0) )

		Default          Return New SToken( TK_ERROR, "Undefined property ~q"+propertyName+"~q", params.GetToken(0) )
	End Select
End Function


'${.role:"guid"/id:"fullname"} - context: all
Function SEFN_role:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local role:TProgrammeRole
	Local token:SToken = params.GetToken(1)
	Local GUID:String = token.value
	Local ID:Long = token.valueLong
	If GUID
		role = GetProgrammeRoleCollection().GetByGUID(GUID)
		If Not role Then Return New SToken( TK_ERROR, ".role with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
	ElseIf ID <> 0
		role = GetProgrammeRoleCollection().GetByID(Int(ID))
		If Not role Then Return New SToken( TK_ERROR, ".role with ID ~q"+ID+"~q not found", params.GetToken(0) )
	EndIf

	Local includeTitle:Int
	If params.HasToken(3)
		includeTitle = params.GetToken(3).GetValueBool()
	EndIf

	Local propertyName:String = params.GetToken(2).value
	Select propertyName.ToLower()
		case "firstname"    Return New SToken( TK_TEXT, role.GetFirstName(), params.GetToken(0) )
		case "lastname"     Return New SToken( TK_TEXT, role.GetLastName(includeTitle), params.GetToken(0) )
		case "fullname"     Return New SToken( TK_TEXT, role.GetFullName(includeTitle), params.GetToken(0) )
		Case "nickname"     Return New SToken( TK_TEXT, role.GetNickName(), params.GetToken(0) )
		Case "title"        Return New SToken( TK_TEXT, role.GetTitle(), params.GetToken(0) )
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
	Local ID:Long = token.valueLong
	If GUID
		person = GetPersonBaseCollection().GetByGUID(GUID)
		If Not person Then Return New SToken( TK_ERROR, ".person with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
	ElseIf ID <> 0
		person = GetPersonBaseCollection().GetByID(Int(ID))
		If Not person Then Return New SToken( TK_ERROR, ".person with ID ~q"+ID+"~q not found", params.GetToken(0) )
	EndIf
	
	Local includeTitle:Int = True
	If params.HasToken(3)
		includeTitle = params.GetToken(3).GetValueBool()
	EndIf
	
	Local propertyName:String = params.GetToken(2).value
	Select propertyName.ToLower()
		case "firstname"    Return New SToken( TK_TEXT, person.GetFirstName(), params.GetToken(0) )
		case "lastname"     Return New SToken( TK_TEXT, person.GetLastName(includeTitle), params.GetToken(0) )
		case "fullname"     Return New SToken( TK_TEXT, person.GetFullName(includeTitle), params.GetToken(0) )
		case "nickname"     Return New SToken( TK_TEXT, person.GetNickName(), params.GetToken(0) )
		case "title"        Return New SToken( TK_TEXT, person.GetTitle(), params.GetToken(0) )
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
				Local channel:Int = Int(params.GetToken(3).GetValueText())
				Return New SToken( TK_NUMBER, person.GetChannelSympathy(channel), params.GetToken(0) )
			endif
		case "productionjobsdone"  Return New SToken( TK_NUMBER, person.GetTotalProductionJobsDone(), params.GetToken(0) )
		case "jobsdone"
			if Not params.HasToken(3)
				If Not person Then Return New SToken( TK_ERROR, ".person JobsDone requires jobID parameter", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueText())
				Return New SToken( TK_NUMBER, person.GetJobsDone(jobID), params.GetToken(0) )
			endif
		case "effectivejobexperiencepercentage"
			if Not params.HasToken(3)
				If Not person Then Return New SToken( TK_ERROR, ".person EffectiveJobExperiencePercentage requires jobID parameter", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueText())
				Return New SToken( TK_NUMBER, person.GetEffectiveJobExperiencePercentage(jobID), params.GetToken(0) )
			endif
		case "hasjob"
			if Not params.HasToken(3) 
				If Not person Then Return New SToken( TK_ERROR, ".person HasJob requires jobID parameter", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueText())
				Return New SToken( TK_BOOLEAN, person.HasJob(jobID), params.GetToken(0) )
			endif
		case "haspreferredjob"
			if Not params.HasToken(3)
				If Not person Then Return New SToken( TK_ERROR, ".person HasPreferredJob requires jobID parameter", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueText())
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
		Local ID:Long = params.GetToken(1).valueLong
		If GUID
			script = GetScriptCollection().GetByGUID(GUID)
			If Not script Then Return New SToken( TK_ERROR, ".script with GUID ~q"+GUID+"~q not found", params.GetToken(0) )
		ElseIf ID <> 0
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
			Local roleIndex:Int = Int(params.GetToken(2 + tokenOffset).GetValueText())
 			If roleIndex < 0 Then Return New SToken( TK_ERROR, "role index must be positive.", params.GetToken(0) )

			Local actors:TPersonProductionJob[] = script.GetJobs()
			If roleIndex >= actors.length Then Return New SToken( TK_ERROR, "(not enough actors for role #" + roleIndex+".)", params.GetToken(0) )

			Local role:TProgrammeRole = TScript._EnsureRole(actors[roleIndex])

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

		Default                 Return New SToken( TK_ERROR, "unknown property ~q" + propertyName + "~q", params.GetToken(0) )
	End Select
End Function


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
		If tv And tv.HasVariable(varLowerCase, True)
			result = _ParseWithTemplateVariables(varLowerCase, context, tv)
		Else
			'parsing expression if it contains further variables necessary? 
			'${.worldtime:"year"} was resolved without further changes...
			result = GetDatabaseLocalizer().getGlobalVariable(localeID, varLowerCase, True)
			If Not result Then result = TGameScriptExpressionBase.GameScriptVariableHandlerCB(variable, context)
		EndIf

		Return result
	End Function


	Function _ParseWithTemplateVariables:String(variableLowerCase:String, context:SScriptExpressionContext, tv:TTemplateVariables = Null)
		If not tv and TTemplateVariables(context.extra)
			tv = TTemplateVariables(context.extra)
		EndIf
		If Not tv
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
			Return TGameScriptExpressionBase.GameScriptVariableHandlerCB(variableLowerCase, context)
		EndIf
		
		Return result
	End Function
End Type
