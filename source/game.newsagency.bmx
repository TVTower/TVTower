SuperStrict
Import "game.newsagency.base.bmx"
Import "game.newsagency.sports.soccer.bmx"
Import "game.newsagency.sports.icehockey.bmx"

GetNewsAgency().AddNewsProvider( new TNewsAgencyNewsProvider_Weather )
GetNewsAgency().AddNewsProvider( TNewsAgencyNewsProvider_Sport.GetInstance() )



EventManager.registerListenerFunction( "SaveGame.OnLoad", onSavegameLoadAddMissingProviders)

Function onSavegameLoadAddMissingProviders:int(triggerEvent:TEventBase)
	local found:int = False
	For local np:TNewsAgencyNewsProvider_Weather = EachIn GetNewsAgency().newsProviders

		found = True; exit
	Next
	if not found
		GetNewsAgency().AddNewsProvider( new TNewsAgencyNewsProvider_Weather )
		print "Recreated NewsProvider_Weather"
	endif

	found = False
	For local np:TNewsAgencyNewsProvider_Sport = EachIn GetNewsAgency().newsProviders
		found = True; exit
	Next
	if not found
		GetNewsAgency().AddNewsProvider( new TNewsAgencyNewsProvider_Sport )
		print "Recreated NewsProvider_Sport"
	endif
End Function



'=== CREATE SPORTS ===
GetNewsEventSportCollection().Add( New TNewsEventSport_Soccer )
GetNewsEventSportCollection().Add( New TNewsEventSport_IceHockey )


'EventManager.registerListenerFunction( "Sport.StartPlayoffs", onStartPlayoffs )
'EventManager.registerListenerFunction( "Sport.FinishPlayoffs", onFinishPlayoffs )
'EventManager.registerListenerFunction( "SportLeague.StartSeasonPart", onStartSeasonPart )
'EventManager.registerListenerFunction( "SportLeague.FinishSeasonPart", onFinishSeasonPart )
'EventManager.registerListenerFunction( "SportLeague.FinishMatchGroup", onFinishMatchGroup )


Function onStartPlayoffs:Int(event:TEventBase)

	Local sport:TNewsEventSport = TNewsEventSport(event.GetSender())
	Local time:Long = event.GetData().GetLong("time", -1)
	If Not sport Or Not sport.playoffSeasons Then Return False
	Print "onStartPlayoffs : "+sport.name
Return False
	Print "  " + "-------------------------"
	For Local i:Int = 0 Until sport.playoffSeasons.length
		Print "  Leaderboard Playoffs League "+(i+1)+"->"+(i+2)
		Print "  " + LSet("Score", 8) + LSet("Team", 40)

		Local season:TNewsEventSportSeason = sport.playoffSeasons[i]
If Not season Then Print "season null"
		Local seasonData:TNewsEventSportSeasonData = sport.playoffSeasons[i].data
If Not seasonData Then Print "seasonData null"

		For Local rank:TNewsEventSportLeagueRank = EachIn sport.playoffSeasons[i].data.GetLeaderboard( time )
			Print "  " + LSet(rank.score, 8) + LSet(rank.team.nameInitials, 5)+" "+LSet(rank.team.name, 40)
		Next
		Print "  " + "-------------------------"
	Next
End Function

Function onFinishPlayoffs:Int(event:TEventBase)
	Local sport:TNewsEventSport = TNewsEventSport(event.GetSender())
	Print "onFinishPlayoffs: "+sport.name
End Function


Function onStartSeasonPart:Int(event:TEventBase)
	Local league:TNewsEventSportLeague = TNewsEventSportLeague(event.GetSender())


	Local time:Long = event.GetData().Getlong("time")

	if GetWorldTime().GetDay(time) < GetWorldTime().GetStartDay() then return False

	print "onStartSeasonPart: "+league.GetCurrentSeason().part+"/"+league.GetCurrentSeason().partMax+"  "+league.name
End Function

Function onFinishSeasonPart:Int(event:TEventBase)
	Local league:TNewsEventSportLeague = TNewsEventSportLeague(event.GetSender())


	Local time:Long = event.GetData().Getlong("time")

	if GetWorldTime().getDay(time) < GetWorldTime().GetStartDay() then return False

	If league.GetCurrentSeason().part = league.GetCurrentSeason().partMax
		Print "FINISH SEASON: "+league.name +"   day:"+GetWorldTime().GetDay(time)
	Else
'			print "FINISH SEASON PART: "+league.seasonPart+"/"+league.seasonPartMax+"  "+league.name
	EndIf

	'only final leaderboard
	If league.GetCurrentSeason().part = league.GetCurrentSeason().partMax
		Print "  " + "-------------------------"
		Print "  Leaderboard "+league.name+":"
		Print "  " + LSet("Score", 8) + LSet("Team", 40)
		For Local rank:TNewsEventSportLeagueRank = EachIn league.GetLeaderboard()
			Print "  " + LSet(rank.score, 8) + LSet(rank.team.nameInitials, 5)+" "+LSet(rank.team.name, 40)
		Next
		Print "  " + "-------------------------"
	EndIf
End Function


'==== OPTION 2: wait for match groups ====
Function onFinishMatchGroup:Int(event:TEventBase)
	Local league:TNewsEventSportLeague = TNewsEventSportLeague(event.GetSender())
	Local matches:TNewsEventSportMatch[] = TNewsEventSportMatch[](event.GetData().Get("matches"))
	If Not matches Or matches.length = 0 Or Not league Then Return False
	'ignore games of the past
	Local time:Long = event.GetData().GetLong("time")
	if GetWorldTime().getDay(time) < GetWorldTime().GetStartDay() then return False

	Print league.name+"  MatchGroup  gameDay="+RSet(GetWorldTime().GetDaysRun(time),2)+"  " + GetWorldTime().GetFormattedTime(time)

	Local weekday:String = GetWorldTime().GetDayName( GetWorldTime().GetWeekday( GetWorldTime().GetOnDay(matches[0].GetMatchTime()) ) )
	For Local match:TNewsEventSportMatch = EachIn matches
'RONNY
		Print "    Match: "+GetWorldTime().GetFormattedDate(match.GetMatchTime())+"  "+LSet(weekday,10) + match.teams[0].nameInitials + " " + match.points[0]+" : " + match.points[1] + " " + match.teams[1].nameInitials
	Next
End Function




Type TNewsAgencyNewsProvider_Sport extends TNewsAgencyNewsProvider
	Global _eventListeners:TEventListenerBase[]
	Global _instance:TNewsAgencyNewsProvider_Sport


	Method New()
		'=== REGISTER EVENTS ===
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		_eventListeners :+ [EventManager.registerListenerFunction( "SportLeague.RunMatch", onRunMatch )]
		_eventListeners :+ [EventManager.registerListenerFunction( "Sport.Playoffs.RunMatch", onRunPlayoffMatch )]
	End Method


	Function GetInstance:TNewsAgencyNewsProvider_Sport()
		if not _instance then _instance = new TNewsAgencyNewsProvider_Sport
		return _instance
	End Function


	'==== OPTION 1: directly wait for matches (regular and playoffs) ====
	Function onRunPlayoffMatch:Int(event:TEventBase)
		Local match:TNewsEventSportMatch = TNewsEventSportMatch(event.GetData().Get("match"))
		Local sport:TNewsEventSport = TNewsEventSport(event.GetSender())
		Local season:TNewsEventSportSeason = TNewsEventSportSeason(event.GetData().Get("season"))
		Local leagueIndex:int = event.GetData().GetInt("leagueIndex", 0)
		Local league:TNewsEventSportLeague = sport.GetLeagueAtIndex(leagueIndex)

		CreateEventFromMatch(match, league, season, sport)
		'if CreateEventFromMatch(match, league, season, sport)
		'	print "onRunPlayoffMatch " + GetWorldTime().GetFormattedDate(match.GetMatchTime()) +"  " + match.GetReportShort() +"  OK"
		'else
		'	print "onRunPlayoffMatch " + GetWorldTime().GetFormattedDate(match.GetMatchTime()) +"  " + match.GetReportShort() +"  FAILED"
		'endif
	End Function


	Function onRunMatch:Int(event:TEventBase)
		Local match:TNewsEventSportMatch = TNewsEventSportMatch(event.GetData().Get("match"))
		Local league:TNewsEventSportLeague = TNewsEventSportLeague(event.GetSender())
		Local sport:TNewsEventSport = GetNewsEventSportCollection().GetByGUID( league.sportGUID )
		Local season:TNewsEventSportSeason = TNewsEventSportSeason(event.GetData().Get("season"))
		If Not match Or not season or not sport Then Return False

		CreateEventFromMatch(match, league, season, sport)
		'if CreateEventFromMatch(match, league, season, sport)
		'	print "onRunMatch " + GetWorldTime().GetFormattedDate(match.GetMatchTime()) +"  " + match.GetReportShort() +"  OK"
		'else
		'	print "onRunMatch " + GetWorldTime().GetFormattedDate(match.GetMatchTime()) +"  " + match.GetReportShort() +"  FAILED"
		'endif
	End Function


	Function CreateEventFromMatch:int(match:TNewsEventSportMatch, league:TNewsEventSportLeague, season:TNewsEventSportSeason, sport:TNewsEventSport)
		'ignore games of the past
		if GetWorldTime().getDay(match.GetMatchTime()) < GetWorldTime().GetStartDay() then return False

		local leagueIndex:int = league._leaguesIndex

		'ignore leagues >= 3 ("Regionalliga")
		if leagueIndex > 2
			'except for playoffs of the league #3
			if leagueIndex = 3 and season and season.seasonType = TNewsEventSportSeason.SEASONTYPE_PLAYOFF
				'keep that
			else
				'print "skipping league: "+leagueIndex+"  " + match.GetReportShort()
				return False
			endif
		endif

		'Do not send news for each match - higher league index = higher chance of being ignored
		If Not season Or season.seasonType <> TNewsEventSportSeason.SEASONTYPE_PLAYOFF
			If randRange(1,100) > 50 + 10 * leagueIndex
				Return False
			EndIf
		EndIf

		Local weekday:String = GetWorldTime().GetDayName( GetWorldTime().GetWeekday( GetWorldTime().GetOnDay(match.GetMatchTime()) ) )


		Local NewsEvent:TNewsEvent_Sport = new TNewsEvent_Sport
		local localizeTitle:TLocalizedString = new TLocalizedString
		local localizeDescription:TLocalizedString = new TLocalizedString
		'quality gets lower the higher the league index (less important)
		Local quality:Float = 0.01 * randRange(50,60) * 0.9 ^ leagueIndex
		Local price:Float = 1.0 + 0.01 * randRange(-5,10) * 1.05 ^ leagueIndex

		'add sport meta data
		NewsEvent.matchID = match.GetID()
		NewsEvent.leagueID = league.GetID()
		NewsEvent.sportID = sport.GetID()
		

		localizeTitle.Set(Getlocale("SPORT_"+sport.name) +" ["+league.nameShort+"]: " +match.GetReportShort())
		if season and season.seasonType = TNewsEventSportSeason.SEASONTYPE_PLAYOFF
			local nextLeague:TNewsEventSportLeague = Sport.GetLeagueAtIndex(league._leaguesIndex + 1)
			if nextLeague
				localizeTitle.Set(Getlocale("SPORT_"+sport.name) +" [REL]: " +match.GetReportShort())
			endif
			localizeDescription.Set(GetRandomLocale2(["SPORT_PLAYOFFS_LONG", "SPORT_"+sport.name+"_PLAYOFFS_LONG"])+":  " + league.nameShort+" -> "+nextLeague.nameShort+"~n"+match.GetReport())
		elseif not season
			localizeDescription.Set("unbekannt:~n"+match.GetReport())
		else
			localizeDescription.Set(match.GetReport())
		endif
		NewsEvent.Init("", localizeTitle, localizeDescription, TVTNewsGenre.SPORT, quality, null, TVTNewsType.InitialNewsByInGameEvent)
		NewsEvent.SetModifier(TNewsEvent.modKeyPriceLS, price)
		'3.0 means it reaches topicality of 0 at ~5 hours after creation.
		NewsEvent.SetModifier(TNewsEvent.modKeyTopicality_AgeLS, 3.0)
		NewsEvent.AddKeyword("SPORT")
		'let the game finish first (duration + 15 Min break)
		NewsEvent.happenedTime = GetWorldTime().GetTimeGone() + (match.duration + 15 * TWorldTime.MINUTELENGTH)

		NewsEvent.eventDuration = 6 * TWorldTime.HOURLENGTH 'only for 6 hours
		NewsEvent.SetFlag(TVTNewsFlag.UNIQUE_EVENT, True) 'one time event
		'
		if league._leaguesIndex = 0 '1. BL
			NewsEvent.minSubscriptionLevel = 3
		elseif league._leaguesIndex = 1 '2. BL
			NewsEvent.minSubscriptionLevel = 2
		'elseif league._leaguesIndex = 2 '3. L
		'	NewsEvent.minSubscriptionLevel = 1
		endif
		
		'add sports information and parse potential expressions
		NewsEvent.title = NewsEvent._ParseScriptExpressions(NewsEvent.title, True, Null)
		NewsEvent.description = NewsEvent._ParseScriptExpressions(NewsEvent.description, True, Null)
		
		'debug
		'print NewsEvent.GetTitle() + "  minLevel=" + NewsEvent.minSubscriptionLevel
		'print "  Match: gameday="+RSet(GetWorldTime().GetDaysRun(),2)+"  "+ GetWorldTime().GetFormattedDate(NewsEvent.happenedTime)+"  "+Lset(weekday,10) + " " + match.GetReportshort() + "  " + match.GetReport()

		GetNewsEventCollection().AddOneTimeEvent(NewsEvent)

		GetInstance().AddNewNewsEvent(newsEvent)
		return True
	End Function


	Method Update:int()
		_instance = self
		'nothing for now, sports updates are handled by TGame
	End Method
End Type




Type TNewsAgencyNewsProvider_Weather extends TNewsAgencyNewsProvider
	'=== WEATHER HANDLING ===
	'time of last weather event/news
	Field weatherUpdateTime:Long = 0
	'announce new weather every x-y minutes
	Field weatherUpdateTimeInterval:int[] = [270, 300]
	Field weatherType:int = 0

	Global _eventListeners:TEventListenerBase[]


	Method Initialize:int()
		Super.Initialize()

		weatherUpdateTime = 0
		weatherUpdateTimeInterval = [270, 300]
		weatherType = 0

		'=== REGISTER EVENTS ===
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]
	End Method


	Method Update:int()
		If weatherUpdateTime < GetWorldTime().GetTimeGone()
			weatherUpdateTime = GetWorldTime().GetTimeGone() + randRange(weatherUpdateTimeInterval[0], weatherUpdateTimeInterval[1]) * TWorldTime.MINUTELENGTH
			'limit weather forecasts to get created between xx:10-xx:40
			'to avoid forecasts created just before the news show
			If GetWorldTime().GetDayMinute(weatherUpdateTime) > 40
				local newTime:Long = GetWorldTime().GetTimeGoneForGameTime(0, GetWorldtime().GetDay(weatherUpdateTime), GetWorldtime().GetDayHour(weatherUpdateTime), RandRange(10, 40), 0, 0)
				weatherUpdateTime = newTime
			EndIf

			local newsEvent:TNewsEvent = GetWeatherNewsEvent()
			AddNewNewsEvent(newsEvent)
		EndIf
	End Method



	Method GetWeatherNewsEvent:TNewsEvent()
		'if we want to have a forecast for a fixed time
		'(overlapping with other forecasts!)
		'-> forecast for 6 hours
		'   (after ~5 hours the next forecast gets created)
		local forecastHours:int = 6
		'if we want to have a forecast till next update
		'local forecastHours:int = ceil((weatherUpdateTime - GetWorldTime().GetTimeGone()) / TWorldTime.HOURLENGTH)

		'quality and price are nearly the same everytime
		Local quality:Float = 0.01 * randRange(50,60)
		Local price:Float = 1.0 + 0.01 * randRange(-5,10)
		'append 1 hour to both: forecast is done eg. at 7:30 - so it
		'cannot be a weatherforecast for 7-10 but for 8-11
		local beginHour:int = (GetWorldTime().GetDayHour()+1) mod 24
		local endHour:int = (GetWorldTime().GetDayHour(GetWorldTime().GetTimeGone() + forecastHours * TWorldTime.HOURLENGTH)+1) mod 24
		Local description:string = ""
		local title:string = GetLocale("WEATHER_FORECAST_FOR_X_TILL_Y").replace("%BEGINHOUR%", beginHour).replace("%ENDHOUR%", endHour)
		local weather:TWorldWeatherEntry
		'states
		local isRaining:int = 0
		local isSnowing:int = 0
		local isBelowZero:int = 0
		local isCloudy:int = 0
		local isClear:int = 0
		local isPartiallyCloudy:int = 0
		local isNight:int = 0
		local isDay:int = 0
		local isNotDay:int = 0
		local becameNight:int = False
		local becameDay:int = False
		local sunHours:int = 0
		local sunAverage:float = 0.0
		local tempMin:int = 1000, tempMax:int = -1000
		local windMin:Float = 1000, windMax:Float = -1000

		'fetch next weather
		local upcomingWeather:TWorldWeatherEntry[forecastHours]
		For local i:int = 0 until forecastHours
			upcomingWeather[i] = GetWorld().Weather.GetUpcomingWeather(i+1)
		Next


		'check for specific states
		For weather = eachin upcomingWeather
			rem
				old variant - leading to "sun wins" news during dusk times
			if GetWorldTime().IsNight(weather._time)
				if isDay then becameNight = True
				isNight = True
			else
				if isNight then becameDay = True
				isDay = True
			endif
			endrem

			if not GetWorldTime().IsDay(weather._time)
				isNotDay = true
			endif

			if GetWorldTime().IsNight(weather._time)
				if isDay then becameNight = True
				isNight = True
				isDay = False
			'ignore DUSK/DAWN times! so check for IsDay() too
			elseif GetWorldTime().IsDay(weather._time)
				if isNotDay then becameDay = True
				isDay = True
				isNotDay = False
				isNight = False
			endif


			tempMin = Min(tempMin, weather.GetTemperature())
			tempMax = Max(tempMax, weather.GetTemperature())

			windMin = Min(windMin, weather.GetWindSpeedKmh())
			windMax = Max(windMax, weather.GetWindSpeedKmh())

			if weather.GetTemperature() < 0 then isBelowZero = True
			if weather.IsRaining() and weather.GetTemperature() >= 0 then isRaining = True
			if weather.GetTemperature() < 0 and weather.IsRaining() then isSnowing = True

			if weather.GetWorldWeather() = TWorldWeather.WEATHER_CLEAR
				isClear = True
			else
				isCloudy = True
			endif

			if weather.IsSunVisible() then sunHours :+1
		Next
		if isCloudy and isClear
			isPartiallyCloudy = True
			isCloudy = False
			isClear = False
		endif
		sunAverage = float(sunHours)/float(forecastHours)



		'construct text
		description = ""

		if isPartiallyCloudy
			description :+ GetRandomLocale("SKY_IS_PARTIALLY_CLOUDY")+" "
		elseif isCloudy
			description :+ GetRandomLocale("SKY_IS_OVERCAST")+" "
		elseif isClear
			description :+ GetRandomLocale("SKY_IS_WITHOUT_CLOUDS")+" "
		endif

		if isDay or becameDay
			if becameDay then description :+ GetRandomLocale("IN_THE_LATER_HOURS")+": "

			if sunAverage = 1.0 and not isCloudy and not becameDay
				if not isNight then description :+ GetRandomLocale("SUN_SHINES_WHOLE_TIME")+" "
			elseif sunAverage > 0.5
				description :+ GetRandomLocale("SUN_WINS_AGAINST_CLOUDS")+" "
			elseif sunAverage > 0
				description :+ GetRandomLocale("SUN_IS_SHINING_SOMETIMES")+" "
			else
				description :+ GetRandomLocale("SUN_IS_NOT_SHINING")+" "
			endif
		endif

		if isRaining and isSnowing
			description :+ GetRandomLocale("RAIN_AND_SNOW_ALTERNATE")+" "
		elseif isRaining
			description :+ GetRandomLocale("RAIN_IS_POSSIBLE")+" "
		elseif isSnowing
			description :+ GetRandomLocale("SNOW_IS_FALLING")+" "
		endif

		local temperatureText:string
		if tempMin <> tempMax
			temperatureText = GetRandomLocale("TEMPERATURES_ARE_BETWEEN_X_AND_Y")
		else
			temperatureText = GetRandomLocale("TEMPERATURE_IS_CONSTANT_AT_X")
		endif


		local weatherText:string
		if windMin <= 10 and windMax <= 10
			weatherText = GetRandomLocale("NEARLY_NO_WIND")
		elseif windMin <> windMax
			if windMin > 20 and windMax > 20
				if windMin > 40 and windMax > 60
					weatherText = GetRandomLocale("STORMY_WINDS_OF_UP_TO_X")
				else
					weatherText = GetRandomLocale("SLOW_WIND_WITH_X_AND_GUST_OF_WIND_WITH_Y")
				endif
			else
				weatherText = GetRandomLocale("WIND_VELOCITIES_ARE_BETWEEN_X_AND_Y")
			endif
		else
			weatherText = GetRandomLocale("WIND_VELOCITY_IS_CONSTANT_AT_X")
		endif

		if temperatureText <> "" then description :+ " " + temperatureText.replace("%TEMPERATURE%", tempMin).replace("%MINTEMPERATURE%", tempMin).replace("%MAXTEMPERATURE%", tempMax)
		if weatherText <> ""  then description :+ " " + weatherText.replace("%MINWINDVELOCITY%", MathHelper.NumberToString(windMin, 0, True)).replace("%MAXWINDVELOCITY%", MathHelper.NumberToString(windMax, 0, True))


		local localizeTitle:TLocalizedString = new TLocalizedString
		localizeTitle.Set(title) 'use default lang
		local localizeDescription:TLocalizedString = new TLocalizedString
		localizeDescription.Set(description) 'use default lang

		Local NewsEvent:TNewsEvent = new TNewsEvent.Init("", localizeTitle, localizeDescription, TVTNewsGenre.CURRENTAFFAIRS, quality, null, TVTNewsType.InitialNewsByInGameEvent)
		NewsEvent.SetModifier(TNewsEvent.modKeyPriceLS, price)
		'after 50 hours a news topicality is 0 - so accelerating it by
		'5.0 means it reaches topicality of 0 at 10 hours after creation.
		'This is 2 hours after the next forecast (a bit overlapping)
		NewsEvent.SetModifier(TNewsEvent.modKeyTopicality_AgeLS, 5.0)

		NewsEvent.AddKeyword("WEATHERFORECAST")

		'TODO
		'add weather->audience effects
		'rain = more audience
		'sun = less audience
		'...
		'-> instead of using "effects" for weather forecast, we just
		'emit gameevents (world-time-depending!) to enable the effect
		'at the forecast start and _NOT_ at the newsevent creation time
		'
		'maybe just connect weather and potential audience directly
		'instead of using the newsevents

		NewsEvent.eventDuration = 8 * TWorldTime.HOURLENGTH 'only for 8 hours
		NewsEvent.SetFlag(TVTNewsFlag.SEND_IMMEDIATELY, True)
		'one time event
		NewsEvent.SetFlag(TVTNewsFlag.UNIQUE_EVENT, True)
		'do not delay other current affair news
		NewsEvent.SetFlag(TVTNewsFlag.KEEP_TICKER_TIME, True)
		'mark it as special (graphical overlay)
		NewsEvent.SetFlag(TVTNewsFlag.SPECIAL_EVENT, True)
		'happened right now
		NewsEvent.happenedTime = GetWorldTime().GetTimeGone()

		GetNewsEventCollection().AddOneTimeEvent(NewsEvent)

		Return NewsEvent
	End Method
End Type


