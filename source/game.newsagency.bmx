SuperStrict
Import "game.newsagency.base.bmx"

GetNewsAgency().AddNewsProvider( new TNewsAgencyNewsProvider_Weather )



Type TNewsAgencyNewsProvider_Weather extends TNewsAgencyNewsProvider
	'=== WEATHER HANDLING ===
	'time of last weather event/news
	Field weatherUpdateTime:Double = 0
	'announce new weather every x-y minutes
	Field weatherUpdateTimeInterval:int[] = [270, 300]
	Field weatherType:int = 0

	Global _eventListeners:TLink[]


	Method Initialize:int()
		Super.Initialize()
		
		weatherUpdateTime = 0
		weatherUpdateTimeInterval = [270, 300]
		weatherType = 0

		'=== REGISTER EVENTS ===
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]
	End Method


	Method Update:int()
		If weatherUpdateTime < GetWorldTime().GetTimeGone()
			weatherUpdateTime = GetWorldTime().GetTimeGone() + 60 * randRange(weatherUpdateTimeInterval[0], weatherUpdateTimeInterval[1])
			'limit weather forecasts to get created between xx:10-xx:40
			'to avoid forecasts created just before the news show
			If GetWorldTime().GetDayMinute(weatherUpdateTime) > 40
				local newTime:Long = GetWorldTime().MakeTime(0, GetWorldtime().GetDay(weatherUpdateTime), GetWorldtime().GetDayHour(weatherUpdateTime), RandRange(10, 40), 0)
				weatherUpdateTime = newTime
			EndIf
			
			local newsEvent:TNewsEvent = GetWeatherNewsEvent()
			If newsEvent
				?debug
				Print "[NEWSAGENCY | LOCAL] UpdateWeather: added weather news title="+newsEvent.GetTitle()+", day="+GetWorldTime().getDay(newsEvent.happenedtime)+", time="+GetWorldTime().GetFormattedTime(newsEvent.happenedtime)
				?
			EndIf
			
			AddNewNewsEvent(newsEvent)
'				announceNewsEvent(newsEvent, GetWorldTime().GetTimeGone())
		EndIf
	End Method



	Method GetWeatherNewsEvent:TNewsEvent()
		'if we want to have a forecast for a fixed time
		'(overlapping with other forecasts!)
		'-> forecast for 6 hours
		'   (after ~5 hours the next forecast gets created)
		local forecastHours:int = 6
		'if we want to have a forecast till next update
		'local forecastHours:int = ceil((weatherUpdateTime - GetWorldTime().GetTimeGone()) / 3600.0)

		'quality and price are nearly the same everytime
		Local quality:Float = 0.01 * randRange(50,60)
		Local price:Float = 1.0 + 0.01 * randRange(-5,10)
		'append 1 hour to both: forecast is done eg. at 7:30 - so it
		'cannot be a weatherforecast for 7-10 but for 8-11
		local beginHour:int = (GetWorldTime().GetDayHour()+1) mod 24
		local endHour:int = (GetWorldTime().GetDayHour(GetWorldTime().GetTimeGone() + forecastHours * 3600)+1) mod 24
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
			if GetWorldTime().IsNight(weather._time)
				if isDay then becameNight = True
				isNight = True
			else
				if isNight then becameDay = True
				isDay = True
			endif

			tempMin = Min(tempMin, weather.GetTemperature())
			tempMax = Max(tempMax, weather.GetTemperature())

			windMin = Min(windMin, Abs(weather.GetWindVelocity() * 20))
			windMax = Max(windMax, Abs(weather.GetWindVelocity() * 20))

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
		if windMin < 2 and windMax < 2
			weatherText = GetRandomLocale("NEARLY_NO_WIND")
		elseif windMin <> windMax
			if windMin > 0 and windMax > 10
				if windMin > 20 and windMax > 35
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
		if weatherText <> ""  then description :+ " " + weatherText.replace("%MINWINDVELOCITY%", MathHelper.NumberToString(windMin, 2, True)).replace("%MAXWINDVELOCITY%", MathHelper.NumberToString(windMax, 2, True))


		local localizeTitle:TLocalizedString = new TLocalizedString
		localizeTitle.Set(title) 'use default lang
		local localizeDescription:TLocalizedString = new TLocalizedString
		localizeDescription.Set(description) 'use default lang

		Local NewsEvent:TNewsEvent = new TNewsEvent.Init("", localizeTitle, localizeDescription, TVTNewsGenre.CURRENTAFFAIRS, quality, null, TVTNewsType.InitialNewsByInGameEvent)
		NewsEvent.SetModifier("price", price)
		'after 20 hours a news topicality is 0 - so accelerating it by
		'2.0 means it reaches topicality of 0 at 8 hours after creation.
		'This is 2 hours after the next forecast (a bit overlapping)
		NewsEvent.SetModifier("topicality::age", 2.0)

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

		NewsEvent.eventDuration = 8*3600 'only for 8 hours
		NewsEvent.SetFlag(TVTNewsFlag.SEND_IMMEDIATELY, True)
		NewsEvent.SetFlag(TVTNewsFlag.UNIQUE_EVENT, True) 'one time event

		GetNewsEventCollection().AddOneTimeEvent(NewsEvent)

		Return NewsEvent
	End Method
End Type


