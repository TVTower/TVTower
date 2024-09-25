SuperStrict
Import "game.gamescriptexpression.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameinformation.base.bmx"
Import "Dig/base.util.persongenerator.bmx"

Import "game.production.script.bmx"
Import "game.programme.programmedata.bmx"
Import "game.programme.programmelicence.bmx"

'valid context(s): "all supported"
GameScriptExpression.RegisterFunctionHandler( "self", SEFN_self, 1, 3)

GameScriptExpression.RegisterFunctionHandler( "programmedata", SEFN_programmedata, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "programmelicence", SEFN_programmelicence, 2, 3) '
GameScriptExpression.RegisterFunctionHandler( "programme", SEFN_programmelicence, 2, 3) 'synonym usage
GameScriptExpression.RegisterFunctionHandler( "person", SEFN_person, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "locale", SEFN_locale, 1, 2)
GameScriptExpression.RegisterFunctionHandler( "script", SEFN_script, 2, 3)
GameScriptExpression.RegisterFunctionHandler( "stationmap", SEFN_StationMap, 1, 1)
GameScriptExpression.RegisterFunctionHandler( "persongenerator", SEFN_PersonGenerator, 1, 3)
GameScriptExpression.RegisterFunctionHandler( "worldtime", SEFN_WorldTime, 1, 1)




'${.worldTime:***} - context: all
'${.worldTime:"year"}
'${.worldTime:"isnight"}
Function SEFN_WorldTime:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local command:String = params.GetToken(0).GetValueText()
	Local subCommand:String = params.GetToken(1).value 'MUST be a string
	
	Select subCommand.ToLower()
		case "year"         Return New SToken( TK_NUMBER, GetWorldTime().GetYear(), params.GetToken(0) )
		case "month"        Return New SToken( TK_NUMBER, GetWorldTime().GetMonth(), params.GetToken(0) )
		case "day"          Return New SToken( TK_NUMBER, GetWorldTime().GetDay(), params.GetToken(0) )
		case "hour"         Return New SToken( TK_NUMBER, GetWorldTime().GetDayHour(), params.GetToken(0) )
		case "minute"       Return New SToken( TK_NUMBER, GetWorldTime().GetDayMinute(), params.GetToken(0) )
		case "daysplayed"   Return New SToken( TK_NUMBER, GetWorldTime().GetDaysRun(), params.GetToken(0) )
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
		default             Return New SToken( TK_ERROR, "(Undefined command ~q"+subCommand+"~q.)", params.GetToken(0) )
	End Select
End Function



'${.stationmap:***} - context: all
'${.stationmap:"randomcity"}
'${.stationmap:"mapname"}
Function SEFN_StationMap:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
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
		default              Return New SToken( TK_ERROR, "(Undefined command ~q"+subCommand+"~q.)", params.GetToken(0) )
	End Select
End Function



'${.persongenerator:***} - context: all
'${.persongenerator:"firstname":"us":"female"}
'${.persongenerator:"fullname"}
Function SEFN_PersonGenerator:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local command:String = params.GetToken(0).GetValueText()
	Local subCommand:String = params.GetToken(1).value 'MUST be a string
	'choose a random country if the country is not defined or no generator
	'existing for it
	Local country:String = params.GetToken(2).GetValueText()
	If country = "" or Not GetPersonGenerator().HasProvider(country)
		country = GetPersonGenerator().GetRandomCountryCode()
	EndIf
	'gender as defined or a random one
	Local gender:Int = TPersonGenerator.GetGenderFromString( params.GetToken(3).GetValueText() )

	Select subCommand.ToLower()
		case "firstname"  Return New SToken( TK_TEXT, GetPersonGenerator().GetFirstName(country, gender), params.GetToken(0) )
		case "lastname"   Return New SToken( TK_TEXT, GetPersonGenerator().GetLastName(country, gender), params.GetToken(0) )
		case "fullname"   Return New SToken( TK_TEXT, GetPersonGenerator().GetFirstName(country, gender) + " " + GetPersonGenerator().GetLastName(country, gender), params.GetToken(0) )
		case "title"      Return New SToken( TK_TEXT, GetPersonGenerator().GetTitle(country, gender), params.GetToken(0) )
		default           Return New SToken( TK_ERROR, "(Undefined command ~q"+subCommand+"~q.)", params.GetToken(0) )
	End Select
End Function




'${.locale:"localekey":"optional: language"} - context: all
Function SEFN_locale:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	If params.added >= 1
		Local key:String = params.GetToken(1).GetValueText()
		If params.added >= 2
			Local languageCode:String = params.GetToken(2).value 'MUST be a string
			Return New SToken( TK_TEXT, GetLocale(key, languageCode), params.GetToken(0) )
		Else
			Return New SToken( TK_TEXT, "hallo" + GetLocale(key), params.GetToken(0) )
		EndIf
	Else
		Return New SToken( TK_ERROR, "(no locale key passed.)", params.GetToken(0) )
	EndIf
End Function




'${.programme/.programmelicence:"the-guid-1-2":"title"} - context: TProgrameLicence / TProgrammeData
Function SEFN_programmelicence:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	'non-self requires an offset of 1 to retrieve required property
	'${.self:"episodes"} - ${.myclass:"guid":"episodes"}
	Local tokenOffset:Int = 0
	Local licence:TProgrammeLicence
	Local firstTokenIsSelf:Int = params.GetToken(0).GetValueText() = "self"

	If firstTokenIsSelf
		licence = TProgrammeLicence(context)
		If Not licence Then Return New SToken( TK_ERROR, "(.self is not a TProgrammeLicence.)", params.GetToken(0) )
	Else
		Local GUID:String = params.GetToken(1).value
		Local ID:Long = params.GetToken(1).valueLong
		If GUID
			licence = GetProgrammeLicenceCollection().GetByGUID(GUID)
			If Not licence Then Return New SToken( TK_ERROR, "(.programmelicence with GUID ~q"+GUID+"~q not found.)", params.GetToken(0) )
		ElseIf ID <> 0
			licence = GetProgrammeLicenceCollection().Get(Int(ID))
			If Not licence Then Return New SToken( TK_ERROR, "(.programmelicence with ID ~q"+ID+"~q not found.)", params.GetToken(0) )
		EndIf
		tokenOffset = 1
	EndIf
	
	Local propertyName:String = params.GetToken(1 + tokenOffset).value.ToLower() 

	'do not allow title/description for "self" as this is prone
	'to a recursive call (description requesting description)
	if not firstTokenIsSelf
		Select propertyName
			Case "title"               Return New SToken( TK_TEXT, licence.GetTitle(), params.GetToken(0) )
			Case "description"         Return New SToken( TK_TEXT, licence.GetDescription(), params.GetToken(0) )
		End Select
	EndIf
	
	Select propertyName
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
		Case "broadcasttimeslotend"    Return New SToken( TK_NUMBER, licence.GetBroadcastTimeSlotEnd(), params.GetToken(0) )
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
		Case "cast"
			Local castNum:Int = params.GetToken(2 + tokenOffset).valueLong
 			If castNum <= 0 Then Return New SToken( TK_ERROR, "(cast number must be positive.)", params.GetToken(0) )

			Local job:TPersonProductionJob = licence.data.GetCastAtIndex(castNum)
			If Not job Then Return New SToken( TK_ERROR, "(cast " + castNum +" not found.)", params.GetToken(0) )

			Local person:TPersonBase = GetPersonBaseCollection().GetByID( job.personID )
			If Not person Then Return New SToken( TK_ERROR, "(cast " + castNum +" person not found.)", params.GetToken(0) )

			Select params.GetToken(3 + tokenOffset).value.ToLower()
				Case "firstname" Return New SToken( TK_TEXT, person.GetFirstName(), params.GetToken(0) )
				Case "lastname"  Return New SToken( TK_TEXT, person.GetLastName(), params.GetToken(0) )
				Case "nickname"  Return New SToken( TK_TEXT, person.GetNickName(), params.GetToken(0) )
				'Case "fullname"  Return New SToken( TK_TEXT, person.GetFullName(), params.GetToken(0) )
				Default          Return New SToken( TK_TEXT, person.GetFullName(), params.GetToken(0) )
			End Select

		Default                        Return New SToken( TK_TEXT, licence.GetTitle(), params.GetToken(0) )
	End Select
End Function



'${.programmedata:"title"} - context: TProgrammeData
Function SEFN_programmedata:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	'non-self requires an offset of 1 to retrieve required property
	'${.self:"episodes"} - ${.myclass:"guid":"episodes"}
	Local tokenOffset:Int = 0
	Local data:TprogrammeData
	Local firstTokenIsSelf:Int = params.GetToken(0).GetValueText() = "self"

	If firstTokenIsSelf
		data = TProgrammeData(context)
		If Not data Then Return New SToken( TK_ERROR, "(.self is not a TProgrammeData.)", params.GetToken(0) )
	Else
		Local GUID:String = params.GetToken(1).value
		Local ID:Long = params.GetToken(1).valueLong
		If GUID
			data = GetProgrammeDataCollection().GetByGUID(GUID)
			If Not data Then Return New SToken( TK_ERROR, "(.programmedata with GUID ~q"+GUID+"~q not found.)", params.GetToken(0) )
		ElseIf ID <> 0
			data = GetProgrammeDataCollection().GetByID(Int(ID))
			If Not data Then Return New SToken( TK_ERROR, "(.programmedata with ID ~q"+ID+"~q not found.)", params.GetToken(0) )
		EndIf
		tokenOffset = 1
	EndIf
	
	Local propertyName:String = params.GetToken(1 + tokenOffset).value.ToLower() 

	'do not allow title/description for "self" as this is prone
	'to a recursive call (description requesting description)
	if not firstTokenIsSelf
		Select propertyName
			Case "title"               Return New SToken( TK_TEXT, data.GetTitle(), params.GetToken(0) )
			Case "description"         Return New SToken( TK_TEXT, data.GetDescription(), params.GetToken(0) )
		End Select
	EndIf
	
	Select propertyName
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
		Case "broadcasttimeslotend"    Return New SToken( TK_NUMBER, data.GetBroadcastTimeSlotEnd(), params.GetToken(0) )
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
		Case "cast"
			Local castNum:Int = params.GetToken(2 + tokenOffset).valueLong
 			If castNum <= 0 Then Return New SToken( TK_ERROR, "(cast number must be positive.)", params.GetToken(0) )

			Local job:TPersonProductionJob = data.GetCastAtIndex(castNum)
			If Not job Then Return New SToken( TK_ERROR, "(cast " + castNum +" not found.)", params.GetToken(0) )

			Local person:TPersonBase = GetPersonBaseCollection().GetByID( job.personID )
			If Not person Then Return New SToken( TK_ERROR, "(cast " + castNum +" person not found.)", params.GetToken(0) )

			Select params.GetToken(3 + tokenOffset).value.ToLower()
				Case "firstname" Return New SToken( TK_TEXT, person.GetFirstName(), params.GetToken(0) )
				Case "lastname"  Return New SToken( TK_TEXT, person.GetLastName(), params.GetToken(0) )
				Case "nickname"  Return New SToken( TK_TEXT, person.GetNickName(), params.GetToken(0) )
				Case "guid"      Return New SToken( TK_TEXT, person.GetGUID(), params.GetToken(0) )
				Case "id"        Return New SToken( TK_NUMBER, person.GetID(), params.GetToken(0) )
				'Case "fullname"  Return New SToken( TK_TEXT, person.GetFullName(), params.GetToken(0) )
				Default          Return New SToken( TK_TEXT, person.GetFullName(), params.GetToken(0) )
			End Select

		Default                        Return New SToken( TK_ERROR, "(unknown property ~q" + propertyName + "~q.)", params.GetToken(0) )
	End Select
End Function





'${.person:"guid":"name"} - context: all
Function SEFN_person:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	Local person:TPersonBase
	Local token:SToken = params.GetToken(1)
	Local GUID:String = token.value
	Local ID:Long = token.valueLong
	If GUID
		person = GetPersonBaseCollection().GetByGUID(GUID)
		If Not person Then Return New SToken( TK_ERROR, "(.person with GUID ~q"+GUID+"~q not found.)", params.GetToken(0) )
	ElseIf ID <> 0
		person = GetPersonBaseCollection().GetByID(Int(ID))
		If Not person Then Return New SToken( TK_ERROR, "(.person with ID ~q"+ID+"~q not found.)", params.GetToken(0) )
	EndIf
	
	Local propertyName:String = params.GetToken(2).value

	Select propertyName.ToLower()
		case "firstname"    Return New SToken( TK_TEXT, person.GetFirstName(), params.GetToken(0) )
		case "lastname"     Return New SToken( TK_TEXT, person.GetLastName(), params.GetToken(0) )
		case "fullname"     Return New SToken( TK_TEXT, person.GetFullName(), params.GetToken(0) )
		case "nickname"     Return New SToken( TK_TEXT, person.GetNickName(), params.GetToken(0) )
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
		case "popularity"   Return New SToken( TK_TEXT, person.GetPopularityValue(), params.GetToken(0) )
		case "channelsympathy"
			if params.added < 3 
				If Not person Then Return New SToken( TK_ERROR, "(.person ChannelSympathy requires channel parameter.)", params.GetToken(0) )
			else
				Local channel:Int = Int(params.GetToken(3).GetValueText())
				Return New SToken( TK_NUMBER, person.GetChannelSympathy(channel), params.GetToken(0) )
			endif
		case "productionjobsdone"  Return New SToken( TK_NUMBER, person.GetTotalProductionJobsDone(), params.GetToken(0) )
		case "jobsdone"
			if params.added < 3 
				If Not person Then Return New SToken( TK_ERROR, "(.person JobsDone requires jobID parameter.)", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueText())
				Return New SToken( TK_NUMBER, person.GetJobsDone(jobID), params.GetToken(0) )
			endif
		case "effectivejobexperiencepercentage"
			if params.added < 3 
				If Not person Then Return New SToken( TK_ERROR, "(.person EffectiveJobExperiencePercentage requires jobID parameter.)", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueText())
				Return New SToken( TK_NUMBER, person.GetEffectiveJobExperiencePercentage(jobID), params.GetToken(0) )
			endif
		case "hasjob"
			if params.added < 3 
				If Not person Then Return New SToken( TK_ERROR, "(.person HasJob requires jobID parameter.)", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueText())
				Return New SToken( TK_NUMBER, person.HasJob(jobID), params.GetToken(0) )
			endif
		case "haspreferredjob"
			if params.added < 3 
				If Not person Then Return New SToken( TK_ERROR, "(.person HasPreferredJob requires jobID parameter.)", params.GetToken(0) )
			else
				Local jobID:Int = Int(params.GetToken(3).GetValueText())
				Return New SToken( TK_NUMBER, person.HasPreferredJob(jobID), params.GetToken(0) )
			endif
		default             Return New SToken( TK_ERROR, "(Undefined property ~q"+propertyName+"~q.)", params.GetToken(0) )
	End Select
End Function



'${.self:"title"} - context: TProgrammeLicence / TProgrammeData
Function SEFN_script:SToken(params:STokenGroup Var, context:Object = Null, contextNumeric:Int = 0)
	'non-self requires an offset of 1 to retrieve required property
	'${.self:"episodes"} - ${.myclass:"guid":"episodes"}
	Local tokenOffset:Int = 0
	Local script:TScript
	Local firstTokenIsSelf:Int = params.GetToken(0).GetValueText() = "self"

	If firstTokenIsSelf
		script = TScript(context)
		If Not script Then Return New SToken( TK_ERROR, "(.self is not a TScript.)", params.GetToken(0) )
	Else
		Local GUID:String = params.GetToken(1).value
		Local ID:Long = params.GetToken(1).valueLong
		If GUID
			script = GetScriptCollection().GetByGUID(GUID)
			If Not script Then Return New SToken( TK_ERROR, "(.script with GUID ~q"+GUID+"~q not found.)", params.GetToken(0) )
		ElseIf ID <> 0
			script = GetScriptCollection().GetByID(Int(ID))
			If Not script Then Return New SToken( TK_ERROR, "(.script with ID ~q"+ID+"~q not found.)", params.GetToken(0) )
		EndIf
		tokenOffset = 1
	EndIf
	
	Local propertyName:String = params.GetToken(1 + tokenOffset).value.ToLower() 

	'do not allow title/description for "self" as this is prone
	'to a recursive call (description requesting description)
	if not firstTokenIsSelf
		Select propertyName
			Case "title"        Return New SToken( TK_TEXT, script.GetTitle(), params.GetToken(0) )
			Case "description"  Return New SToken( TK_TEXT, script.GetDescription(), params.GetToken(0) )
		End Select
	EndIf
	
	Select propertyName
		Case "episodes"         Return New SToken( TK_NUMBER, script.GetEpisodes(), params.GetToken(0) )
		Case "genre"            Return New SToken( TK_NUMBER, script.GetMainGenre(), params.GetToken(0) )
		Case "genrestring"      Return New SToken( TK_NUMBER, script.GetMainGenreString(), params.GetToken(0) )

		Case "role"
			Local roleNum:Int = Int(params.GetToken(2 + tokenOffset).GetValueText())
 			If roleNum <= 0 Then Return New SToken( TK_ERROR, "(role number must be positive.)", params.GetToken(0) )

			Local actors:TPersonProductionJob[] = script.GetSpecificJob(TVTPersonJob.ACTOR | TVTPersonJob.SUPPORTINGACTOR)
			If roleNum > actors.length Then Return New SToken( TK_ERROR, "(not enough actors for role #" + roleNum+".)", params.GetToken(0) )

			Local role:TProgrammeRole = TScript._EnsureRole(actors[roleNum-1])

			Local subCommand:String = params.GetToken(3 + tokenOffset).GetValueText()
			Select subCommand.ToLower()
				Case "firstname"  Return New SToken( TK_TEXT, role.GetFirstName(), params.GetToken(0) )
				Case "lastname"   Return New SToken( TK_TEXT, role.GetLastName(), params.GetToken(0) )
				'Case "fullname"   Return New SToken( TK_TEXT, role.GetFullName(), params.GetToken(0) )
				Default           Return New SToken( TK_TEXT, role.GetFullName(), params.GetToken(0) )
			End Select
							
		Default                 Return New SToken( TK_ERROR, "(unknown property ~q" + propertyName + "~q.)", params.GetToken(0) )
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
	ElseIf TScript(context)
		return SEFN_script(params, context, contextNumeric)
	EndIf
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
