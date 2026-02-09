SuperStrict
Import "game.gameinformation.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.stationmap.bmx"

'===== REGISTER PROVIDERS ====
TProgrammePlanInformationProviderBase.GetInstance()
TWorldTimeInformationProviderBase.GetInstance()
TStationMapInformationProviderBase.GetInstance()




'contains general information of all broadcasts in the programmeplans
'does not contain specific information (eg. programme licence information)
Type TProgrammePlanInformationProviderBase extends TGameInformationProvider
	Field firstTrailerAired:long
	Field lastTrailerAired:long
	Field trailerAired:int[]

	Field firstInfomercialAired:long
	Field lastInfomercialAired:long
	Field infomercialsAired:int[]

	Field adspotsAired:int[]

	'times a genre was broadcasted by each player
	Field programmeGenreAired:TMap[]

	'each genre stores its record, newsshows are stored as "newsshow"
	Field audienceRecord:TMap[]

	Global _instance:TProgrammePlanInformationProviderBase

	CONST FIRST_TRAILER_AIRED:int = 101
	CONST LAST_TRAILER_AIRED:int = 102
	CONST TRAILER_AIRED:int = 102

	CONST FIRST_INFOMERCIAL_AIRED:int = 201
	CONST LAST_INFOMERCIAL_AIRED:int = 202
	CONST INFOMERCIAL_AIRED:int = 202

	CONST AUDIENCE_RECORD:int = 501


	Function GetInstance:TProgrammePlanInformationProviderBase()
		if not _instance then _instance = new TProgrammePlanInformationProviderBase
		return _instance
	End Function


	Method New()
		Reset()

		'register provider to provider collection
		GetGameInformationCollection().AddProvider("programmeplan", self)
	End Method


	Method Reset()
		firstTrailerAired = -1
		lastTrailerAired = -1
		trailerAired = new Int[5]

		firstInfomercialAired = -1
		lastInfomercialAired = -1
		infomercialsAired = new Int[5]

		adspotsAired = new Int[5]

		programmeGenreAired = programmeGenreAired[..5]
		audienceRecord = audienceRecord[..5]
		For local i:int = 0 to 4
			programmeGenreAired[i] = CreateMap()
			audienceRecord[i] = CreateMap()
		Next
	End Method


	Method SerializeTProgrammePlanInformationProviderBaseToString:string()
		local result:string = ""
		result :+       firstTrailerAired
		result :+ ":" + lastTrailerAired
		result :+ ":" + StringHelper.IntArrayToString(trailerAired, ",")

		result :+ ":" + firstInfomercialAired
		result :+ ":" + lastInfomercialAired
		result :+ ":" + StringHelper.IntArrayToString(infomercialsAired, ",")

		result :+ ":" + StringHelper.IntArrayToString(adspotsAired, ",")

		For local i:int = 0 to 4
			local keys:string[], values:string[]
			For local v:string = EachIn programmeGenreAired[i].Keys()
				keys :+ [v]
				values :+ [string(programmeGenreAired[i].ValueForKey(v))]
			Next
			if keys.length > 0 and values.length = keys.length
				result :+ ":" + ",".Join(keys)
				result :+ ":" + ",".Join(values)
			endif

			keys = keys[..0]; values = values[..0]
			For local v:string = EachIn audienceRecord[i].Keys()
				keys :+ [v]
				values :+ [string(audienceRecord[i].ValueForKey(v))]
			Next
			if keys.length > 0 and values.length = keys.length
				result :+ ":" + ",".Join(keys)
				result :+ ":" + ",".Join(values)
			endif
		Next
		return result
	End Method


	Method DeSerializeTProgrammePlanInformationProviderBaseFromString(text:String)
		local parts:string[] = text.split(":")
		if parts.length >= 3
			firstTrailerAired = Long(parts[0])
			lastTrailerAired = Long(parts[1])
			trailerAired = StringHelper.StringToIntArray(parts[2], Asc(","))
		endif
		if parts.length >= 6
			firstInfomercialAired = Long(parts[3])
			lastInfomercialAired = Long(parts[4])
			infomercialsAired = StringHelper.StringToIntArray(parts[5], Asc(","))
		endif
		if parts.length >= 7
			adspotsAired = StringHelper.StringToIntArray(parts[6], Asc(","))
		endif
		For local player:int = 0 to 4
			programmeGenreAired[player].Clear()
			audienceRecord[player].Clear()
			'4 because 2 * (keys + values)
			local start:int = 7 + (player)*4
			if parts.length >= start + 4
				local keys:string[] = parts[start].split(",")
				local values:string[] = parts[start+1].split(",")
				For local i:int = 0 until keys.length
					programmeGenreAired[player].insert(keys[i], values[i])
				Next

				keys = parts[start+2].split(",")
				values = parts[start+3].split(",")
				For local i:int = 0 until keys.length
					audienceRecord[player].insert(keys[i], values[i])
				Next
			endif
		Next
		'debug
		'print "deserialize:  " + text
		'print "deserialized: " + SerializeToString()
	End Method


	Method Set(key:string, obj:object)
		Select int(key)
			Case FIRST_TRAILER_AIRED
				SetFirstTrailerAired( Long(string(obj)) )
			Case LAST_TRAILER_AIRED
				SetLastTrailerAired( Long(string(obj)) )
			Case TRAILER_AIRED
				local i:Long[] = Long[](obj)
				if i.length >= 3
					SetTrailerAired( int(i[0]), int(i[1]), i[2] )
				else
					print "Set: TRAILER_AIRED. Incorrect param length."
				endif

			Case FIRST_INFOMERCIAL_AIRED
				SetFirstInfomercialAired( Long(string(obj)) )
			Case LAST_INFOMERCIAL_AIRED
				SetLastInfomercialAired( Long(string(obj)) )
			Case INFOMERCIAL_AIRED
				local i:Long[] = Long[](obj)
				if i.length >= 3
					SetInfomercialsAired( int(i[0]), int(i[1]), i[2] )
				else
					print "Set: INFOMERCIAL_AIRED. Incorrect param length."
				endif
		End Select
	End Method


	Method SetFirstTrailerAired(time:Long)
		firstTrailerAired = time
	End Method


	Method SetLastTrailerAired(time:Long)
		lastTrailerAired = time
	End Method


	Method SetTrailerAired(player:int, count:int, time:Long)
		trailerAired[player] = count

		if firstTrailerAired = -1 or firstTrailerAired > time
			firstTrailerAired = time
		endif
		if lastTrailerAired = -1 or lastTrailerAired > time
			lastTrailerAired = time
		endif
	End Method


	Method SetFirstInfomercialAired(time:Long)
		firstInfomercialAired = time
	End Method


	Method SetLastInfomercialAired(time:Long)
		lastInfomercialAired = time
	End Method


	Method SetInfomercialsAired(player:int, count:int, time:Long)
		infomercialsAired[player] = count

		if firstInfomercialAired = -1 or firstInfomercialAired > time
			firstInfomercialAired = time
		endif
		if lastInfomercialAired = -1 or lastInfomercialAired > time
			lastInfomercialAired = time
		endif
	End Method



	Method Get:object(key:string, params:object, useTime:Long = 0)
		Select int(key)
			Case FIRST_TRAILER_AIRED
				return string( GetFirstTrailerAired() )
			Case LAST_TRAILER_AIRED
				return string( GetLastTrailerAired() )
			Case TRAILER_AIRED
				return string( GetTrailerAired( int(string(params)) ) )

			Case FIRST_INFOMERCIAL_AIRED
				return string( GetFirstInfomercialAired() )
			Case LAST_INFOMERCIAL_AIRED
				return string( GetLastInfomercialAired() )
			Case INFOMERCIAL_AIRED
				return string( GetInfomercialsAired( int(string(params)) ) )
		End Select
	End Method


	Method GetFirstTrailerAired:Long()
		return firstTrailerAired
	End Method


	Method GetLastTrailerAired:Long()
		return lastTrailerAired
	End Method


	Method GetTrailerAired:int(player:int)
		return trailerAired[player]
	End Method


	Method GetFirstInfomercialAired:Long()
		return firstInfomercialAired
	End Method


	Method GetLastInfomercialAired:Long()
		return lastInfomercialAired
	End Method


	Method GetInfomercialsAired:int(player:int)
		return infomercialsAired[player]
	End Method


	Method RefreshProgrammeData(player:int, time:Long); End Method
	Method RefreshAudienceData(player:int, time:Long, audienceData:object); End Method

End Type

'===== CONVENIENCE ACCESSOR =====
'return instance
Function GetProgrammePlanInformationProviderBase:TProgrammePlanInformationProviderBase()
	Return TProgrammePlanInformationProviderBase.GetInstance()
End Function





Type TWorldTimeInformationProviderBase extends TGameInformationProvider
	Global _instance:TWorldTimeInformationProviderBase

	Function GetInstance:TWorldTimeInformationProviderBase()
		if not _instance then _instance = new TWorldTimeInformationProviderBase
		return _instance
	End Function


	Method New()
		Reset()

		'register provider to provider collection
		GetGameInformationCollection().AddProvider("worldtime", self)
	End Method


	Method Reset()
		'nothing cached
	End Method


	Method Set(key:string, obj:object)
		Select int(key)
			Default
				print "Set is not allowed for TWorldTimeInformationProviderBase"
		End Select
	End Method


	Method Get:object(key:string, params:object, useTime:Long = 0)
		Select key.ToLower()
			Case "year", "gameyear"
				return string( GetWorldTime().GetYear(useTime) )
			Case "gameday"
				return string( GetWorldTime().GetDaysRun(useTime) + 1 )
			Case "day"
				return string( GetWorldTime().GetOnDay(useTime) )
			Case "daylong"
				'already localized to current lang!
				return GetWorldTime().GetFormattedDayLongByTime(useTime)
			Case "weekday"
				return string( GetWorldTime().GetWeekDay(useTime) )
			Case "hour"
				return string( GetWorldTime().GetDayHour(useTime) )
			Case "season"
				return string( GetWorldTime().GetSeason(useTime) )

			'Germany has a time dependend capital and currency
			Case "germancurrency"
				if GetWorldTime().GetYear(useTime) >= 2002
					return "Euro"
				elseif GetWorldTime().GetYear(useTime) >= 1990
					return "DM"
				else
					return "Mark"
				endif

			Case "germancapital"
				if GetWorldTime().GetYear(useTime) >= 1990
					return "Berlin"
				else
					return "Bonn"
				endif


			Default
				return "UNHANDLED_KEY"
		End Select
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return instance
Function GetWorldTimeProviderBase:TWorldTimeInformationProviderBase()
	Return TWorldTimeInformationProviderBase.GetInstance()
End Function




Type TStationMapInformationProviderBase extends TGameInformationProvider
	Global _instance:TStationMapInformationProviderBase

	Function GetInstance:TStationMapInformationProviderBase()
		if not _instance then _instance = new TStationMapInformationProviderBase
		return _instance
	End Function


	Method New()
		Reset()

		'register provider to provider collection
		GetGameInformationCollection().AddProvider("stationmap", self)
	End Method


	Method Reset()
		'nothing cached
	End Method


	Method Set(key:string, obj:object)
		Select int(key)
			Default
				print "Set is not allowed for TStationMapInformationProviderBase"
		End Select
	End Method


	Method Get:object(key:string, params:object, useTime:Long = 0)
		Select key.ToLower()
			Case "countryname"
				return GetLocale("COUNTRYNAME_" + GetStationMapCollection().config.GetString("name", "Unknownia"))
			Case "mapname"
				return GetStationMapCollection().config.GetString("name", "Unknownia")
			Case "mapnameshort", "countrycode"
				return GetStationMapCollection().config.GetString("nameShort", "Unk")
			Case "population"
				return string( GetStationMapCollection().population )
			Case "randomcity"
				return GetStationMapCollection().GenerateCity()
			Default
				return "UNHANDLED_KEY"
		End Select
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return instance
Function GetStationMapInformationProviderBase:TStationMapInformationProviderBase()
	Return TStationMapInformationProviderBase.GetInstance()
End Function


