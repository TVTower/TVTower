SuperStrict
Import "Dig/base.util.mersenne.bmx"
Import "game.world.worldtime.bmx"



Type TWorldWeather
	Field currentWeather:TWorldWeatherEntry
	Field upcomingWeather:TList = CreateList()
	'to get a "prediction" (cold nights, hot days) we need to know at
	'which interval the weather will get updated ...
	'eg. every 3600 seconds (every hour)
	Field weatherInterval:int = 3600
	'timer values
	Field nextUpdateTime:Double = -1
	Field lastUpdateTime:Double = -1


	'=== PRESSURE THRESHOLDS ===
	'all values must be even numbers.
	const PRESSURE_THRESHOLD_SEVERESTORM:int= -28
	const PRESSURE_THRESHOLD_STORM:int		= -24
	const PRESSURE_THRESHOLD_HEAVYRAIN:int	= -20
	const PRESSURE_THRESHOLD_RAIN:int		= -16
	const PRESSURE_THRESHOLD_LIGHTRAIN:int	= -12
	const PRESSURE_THRESHOLD_HEAVYCLOUD:int	= -10
	const PRESSURE_THRESHOLD_CLOUDY:int		= -8
	const PRESSURE_THRESHOLD_FINE:int		= -6
	'must be equal to PRESSURE_THRESHOLD_FINE + 8 * positive integer
	const PRESSURE_THRESHOLD_CLEAR:int		= 10

	'=== WEATHER CONSTANTS ===
	const WEATHER_HURRICANE:int		= 0
	const WEATHER_SEVERESTORM:int	= 1
	const WEATHER_STORM:int			= 2
	const WEATHER_HEAVYRAIN:int		= 3
	const WEATHER_RAIN:int			= 4
	const WEATHER_LIGHTRAIN:int		= 5
	const WEATHER_HEAVYCLOUD:int	= 6
	const WEATHER_CLOUDY:int		= 7
	const WEATHER_FINE:int			= 8
	const WEATHER_CLEAR:int			= 9


	Method Init:TWorldWeather(pressure:Float = 0.0, temperature:Float = 18.0, windVelocity:Float = 0.0, weatherInterval:Int = 3600)
		currentWeather = null
		upcomingWeather.Clear()
		nextUpdateTime = -1
		lastUpdateTime = -1

		currentWeather = new TWorldWeatherEntry.Init(pressure, temperature, windVelocity, GetWorldTime().GetTimeGone(), new TWorldWeatherConfiguration)

		SetWeatherInterval(weatherInterval)

		return self
	End Method


	'adjust at which interval the weather gets updated
	'time is in seconds of a day
	Method SetWeatherInterval(weatherInterval:int)
		self.weatherInterval = weatherInterval
	End Method


	Method GetTimeSinceUpdate:Double()
		if lastUpdateTime = -1 then return 0
		return GetWorldTime().GetTimeGone() - lastUpdateTime
	End Method


	Method GetPressure:Float()
		return currentWeather.GetPressure()
	End Method


	Method GetTemperature:Float()
		return currentWeather.GetTemperature()
	End Method


	Method GetWindSpeed:Float()
		return currentWeather.GetWindSpeed()
	End Method


	Method GetWindVelocity:Float()
		return currentWeather.GetWindVelocity()
    End Method


	Method GetWeather:int()
		return currentWeather.GetWorldWeather()
	End Method


    Method GetWeatherText:string()
		return currentWeather.GetWorldWeatherText()
	End Method


	Method GetCloudOkta:int()
		return currentWeather.GetCloudOkta()
    End Method


    Method GetMaximumLight:int()
		return currentWeather.GetMaximumLight()
    End Method


	Method SetPressure(pressure:Float)
		currentWeather.SetPressure(pressure)
		'remove previously predicted weather
		ResetUpcomingWeather()
	End Method


	Method SetTemperature(temperature:Float)
		currentWeather.SetTemperature(temperature)
		'remove previously predicted weather
		ResetUpcomingWeather()
	End Method


	'returns whether the sun is visible
    Method IsSunVisible:int()
		return currentWeather.IsSunVisible()
	End Method


	'returns whether it is raining or not.
	'returned value ranges from 0 (no rain) to 5 (full rain)
	Method IsRaining:int()
		return currentWeather.IsRaining()
	End Method

	'returns how bright a cloud is.
	'values are from 0-100 (so "percentage"). 100 means pure white
    Method GetCloudBrightness:int()
		return currentWeather.GetCloudBrightness()
	End Method


	Method GetCurrentWeather:TWorldWeatherEntry()
		if not currentWeather then Init(0,0)
		return currentWeather
	End Method


	Method GetUpcomingWeather:TWorldWeatherEntry(position:int = 1)
		if upcomingWeather.Count() < position then GenerateUpcomingWeather(position)

		return TWorldWeatherEntry(upcomingWeather.ValueAtIndex(Max(0,position-1)))
	End Method


	Method ResetUpcomingWeather:int()
		local oldCount:int = upcomingWeather.Count()
		if oldCount > 0
			upcomingWeather.Clear()
			GenerateUpcomingWeather(oldCount)
		endif
	End Method


	Method GenerateUpcomingWeather:int(limit:int=100)
		if upcomingWeather.Count() >= limit then return False

		local baseWeather:TWorldWeatherEntry = TWorldWeatherEntry(upcomingWeather.Last())
		if not baseWeather then baseWeather = GetCurrentWeather()

		local weatherTime:Double = baseWeather._time

		For local i:int = upcomingWeather.Count() until limit
			if weatherTime >= 0 then weatherTime :+ weatherInterval
			'create a new one based on the baseWeather
			baseWeather = TWorldWeatherEntry.Create(baseWeather, weatherTime)

			'add it to the list
			upcomingWeather.AddLast(baseWeather)
		Next
	End Method


	Method NeedsUpdate:int()
		'time for another weather update?
		'just rely on the world time
		return nextUpdateTime < GetWorldTime().GetTimeGone()
	End Method


    Method Update:int()
		'check if there is already weather precalculated
		'if not, update the existing weather
		local nextWeather:TWorldWeatherEntry = TWorldWeatherEntry(upcomingWeather.First())
		if nextWeather
			'remove that weather from the upcoming list
			upcomingWeather.RemoveFirst()
			'set is as current one
			currentWeather = nextWeather
		else
			GetCurrentWeather().Update()
		endif

		'adjust time for next weather update
		lastUpdateTime = nextUpdateTime
		nextUpdateTime = GetWorldTime().GetTimeGone() + weatherInterval
	End Method


	Method ToString:string()
		return GetCurrentWeather().ToString()
	End Method
End Type




Type TWorldWeatherConfiguration
	'=== CONFIGURE GENERATION VALUES ===
	'values determine range of generated random numbers
	Field multiplier:int = 64
	'values determine granularity of generated random numbers
	'steps defines how quickly the weather will change
	Field steps:int = 8
	Field increment:float = 1.0/steps
	'threshold determines max deviation from 0 before the generated
	'random number will influence the system.
	'It determines how often velocity of the wind will drift towards
	'0. Larger values = less randomness (= reduce standard deviation).
	Field threshold:int = 2 '6


	Method SerializeTWorldWeatherConfigurationToString:string()
		return multiplier + " " + steps + " " + increment + " " + threshold
	End Method


	Method DeSerializeTWorldWeatherConfigurationFromString(text:String)
		local vars:string[] = text.split(" ")
		if vars.length > 0 then multiplier = int(vars[0])
		if vars.length > 1 then steps = int(vars[1])
		if vars.length > 2 then increment = float(vars[2])
		if vars.length > 3 then threshold = int(vars[3])
	End Method
End Type




Type TWorldWeatherEntry
	Field _pressure:Float
	Field _temperature:Float
    Field _windVelocity:Float
    Field _time:Double = -1.0
	Field _config:TWorldWeatherConfiguration


	Method Init:TWorldWeatherEntry(pressure:Float, temperature:Float, windVelocity:Float, time:Double = -1, configuration:TWorldWeatherConfiguration)
		SetPressure(pressure)
		SetTemperature(temperature)
        SetWindVelocity(windVelocity)
        _time = time
        _config = configuration

        return self
	End Method


	Function Create:TWorldWeatherEntry(previousWeather:TWorldWeatherEntry = null, time:Double = -1)
		'create a new weather with the values from the previous weather
		local newWeather:TWorldWeatherEntry = new TWorldWeatherEntry
		if previousWeather
			newWeather.Init(previousWeather._pressure, previousWeather._temperature, previousWeather._windVelocity, time, previousWeather._config)
		else
			newWeather.Init(0, 18.0, 0, time, new TWorldWeatherConfiguration)
		endif

		newWeather.Update()
		return newWeather
	End Function


	'calculate new weather conditions for this entry
	'calculation is based on previous values
	Method Update()
		'=== GENERATE RANDOM VALUES ===
		'randRange in network games so all clients get the same weather
		local randomPressure:int = RandRange(0, _config.multiplier * _config.steps - 1) / 8 - (_config.multiplier/2) + GetPressure()


		'=== UPDATE WIND VELOCITY ===
		if randomPressure > _config.threshold
			SetWindVelocity(GetWindVelocity() - _config.increment)
		elseif randomPressure < _config.threshold
			SetWindVelocity(GetWindVelocity() + _config.increment)
		elseif GetWindVelocity() > 0
			'default: reduce speed
			SetWindVelocity(GetWindVelocity() - _config.increment)
		elseif GetWindVelocity() < 0
			SetWindVelocity(GetWindVelocity() + _config.increment)
		else
			'nothing
		endif

		'=== UPDATE PRESSURE ===
        SetPressure(GetPressure() + GetWindVelocity())


		'=== UPDATE TEMPERATURE ===
		local temperatureChange:float = 0.0
		'high noon + 1 the max temperature will be reached (max increase)
		local maxTempHour:int = GetWorldTime().GetDayHour(GetWorldTime().GetSunrise(_time) + 1.0*GetWorldTime().GetDayLightLength(_time) )
'print maxTempHour+"  " + (GetWorldTime().GetDayLightLength(_time)/60)+"min"
		'to make it an "increasing" or "decreasing" tendence we use the
		'distance to half a dayLightLength (summer 18/2=9 hours)
		'7:00 = "2/9"   0:00 = "-4/9"   15:00 = "8/9"
		local halfDayLightLength:int = 9 '0.5 * GetWorldTime().GetDayLightLength(_time)/3600
		local heatInfluence:Float = (halfDayLightLength - abs(GetDayHour() - maxTempHour)) / float(halfDayLightLength)

		'day times (warming period)
		if heatInfluence > 0
			temperatureChange :+ heatInfluence * 1.0
			'sun shining
			If IsSunVisible() then temperatureChange :+ 0.25 * heatInfluence
		'night times (lower temperature period)
		else
			temperatureChange :- abs(heatInfluence)^2 * 1.20

			'aka "no clouds". No clouds means it gets colder
			If IsSunVisible() then temperatureChange :- 1.35 * abs(heatInfluence)
		endif


		'winds lower temperature
		if GetWindSpeed() <= 0.25 then temperatureChange :- 0.25*GetWindSpeed()
		'strong winds lower temperature even more
		if GetWindSpeed() > 0.25 then temperatureChange :- 0.35*GetWindSpeed()
		'cold and wet winds
		if IsRaining() then temperatureChange :- (0.4 + 0.25 * GetWindSpeed())

		local newTemperature:Float = GetTemperature() + temperatureChange

		'limit to seasons
		Select GetWorldTime().GetSeason(_time)
			case GetWorldTime().SEASON_SPRING, GetWorldTime().SEASON_AUTUMN
				newTemperature = Max(-10, Min(25, newTemperature))
			case GetWorldTime().SEASON_SUMMER
				newTemperature = Max(5, newTemperature)
			case GetWorldTime().SEASON_WINTER
				newTemperature = Min(20, newTemperature)
		EndSelect
		if newTemperature <> GetTemperature() + temperatureChange
			newTemperature :+ randRange(int(-3*_config.increment), int(3*_config.increment))
		endif

		if temperatureChange <> 0
			SetTemperature(newTemperature)
		endif
	End Method


	Method GetTime:Double()
		return _time
	End Method


	Method GetDayHour:int()
		return GetWorldTime().GetDayHour(_time)
	End Method


	Method GetDayMinute:int()
		return GetWorldTime().GetDayMinute(_time)
	End Method


	Method GetPressure:Float()
		return _pressure
	End Method


	Method SetPressure(pressure:Float)
		'rounded pressure must be an int-multiple of 1/8
		pressure = Int(8*pressure + (Sgn(pressure) * 0.5)) / 8.0

		'absolute value is limited between -50 and 50
		pressure = min(50, max(-50, pressure))

		_pressure = pressure
	End Method


	Method GetTemperature:Float()
		return _temperature
	End Method


	Method SetTemperature(temperature:Float)
		'rounded pressure must be an int-multiple of 1/8
		'-> 0.125, 0.25, ... 0.875, ...
		temperature = Int(8*temperature + (Sgn(temperature) * 0.5)) / 8.0

		'absolute value is limited between -25 and 40 degrees
		temperature = min(40, max(-25, temperature))

		_temperature = temperature
	End Method


	Method GetWindSpeed:Float()
		return abs(GetWindVelocity())
	End Method


	Method GetWindVelocity:Float()
		return _windVelocity
    End Method


	Method SetWindVelocity(velocity:float)
        'velocity must be an int-multiple of 1/8
		velocity = Int(8*velocity + (Sgn(velocity) * 0.5)) / 8.0

		'absolute value is limited between -4 and 4
		velocity = min(4, max(-4, velocity))

		_windVelocity = velocity
	End Method


	Method GetWorldWeather:int()
		local result:int = TWorldWeather.WEATHER_CLEAR

        if GetPressure() >= TWorldWeather.PRESSURE_THRESHOLD_CLEAR
			result = TWorldWeather.WEATHER_CLEAR
		elseif GetPressure() >= TWorldWeather.PRESSURE_THRESHOLD_FINE
			result = TWorldWeather.WEATHER_FINE
		elseif GetPressure() >= TWorldWeather.PRESSURE_THRESHOLD_CLOUDY
			result = TWorldWeather.WEATHER_CLOUDY
		elseif GetPressure() >= TWorldWeather.PRESSURE_THRESHOLD_HEAVYCLOUD
			result = TWorldWeather.WEATHER_HEAVYCLOUD
		elseif GetPressure() >= TWorldWeather.PRESSURE_THRESHOLD_LIGHTRAIN
			result = TWorldWeather.WEATHER_LIGHTRAIN
		elseif GetPressure() >= TWorldWeather.PRESSURE_THRESHOLD_RAIN
			result = TWorldWeather.WEATHER_RAIN
		elseif GetPressure() >= TWorldWeather.PRESSURE_THRESHOLD_HEAVYRAIN
			result = TWorldWeather.WEATHER_HEAVYRAIN
		elseif GetPressure() >= TWorldWeather.PRESSURE_THRESHOLD_STORM
			result = TWorldWeather.WEATHER_STORM
		elseif GetPressure() >= TWorldWeather.PRESSURE_THRESHOLD_SEVERESTORM
			result = TWorldWeather.WEATHER_SEVERESTORM
		else
			result = TWorldWeather.WEATHER_HURRICANE
		endif

		return result
	End Method


    Method GetWorldWeatherText:string()
		Select GetWorldWeather()
			case TWorldWeather.WEATHER_CLEAR        return "Clear"
			case TWorldWeather.WEATHER_FINE         return "Fine"
			case TWorldWeather.WEATHER_CLOUDY       return "Cloudy"
			case TWorldWeather.WEATHER_HEAVYCLOUD   return "Heavy Cloud"
			case TWorldWeather.WEATHER_LIGHTRAIN    return "Light Rain"
			case TWorldWeather.WEATHER_RAIN         return "Rain"
			case TWorldWeather.WEATHER_HEAVYRAIN    return "Heavy Rain"
			case TWorldWeather.WEATHER_STORM        return "Storm"
			case TWorldWeather.WEATHER_SEVERESTORM  return "Severe Storm"
			Default                                 return "Hurricane"
		End Select
	End Method


	'returns fraction of the sky covered by clouds
	'values are 0 (no cloud) to 8 (overcast).
	'okta units: https://www.wikipedia.org/wiki/Okta
	Method GetCloudOkta:int()
		local result:int = 0

		Select GetWorldWeather()
			Case TWorldWeather.WEATHER_CLEAR
				result = 0
			Case TWorldWeather.WEATHER_FINE
				result = ceil(8 * (1 - (GetPressure() - TWorldWeather.PRESSURE_THRESHOLD_FINE) / (TWorldWeather.PRESSURE_THRESHOLD_CLEAR - TWorldWeather.PRESSURE_THRESHOLD_FINE) ))
			Default
				result = 8
		End Select
        return result
    End Method


    Method GetMaximumLight:int()
		Select GetWorldWeather()
			case TWorldWeather.WEATHER_CLEAR        return 15
			case TWorldWeather.WEATHER_FINE         return 15
			case TWorldWeather.WEATHER_CLOUDY       return 14
			case TWorldWeather.WEATHER_HEAVYCLOUD   return 13
			case TWorldWeather.WEATHER_LIGHTRAIN    return 12
			case TWorldWeather.WEATHER_RAIN         return 11
			case TWorldWeather.WEATHER_HEAVYRAIN    return 10
			'9 is unused
			case TWorldWeather.WEATHER_STORM        return 8
			case TWorldWeather.WEATHER_SEVERESTORM  return 7
			case TWorldWeather.WEATHER_HURRICANE    return 6
			Default                                 return 15
		End Select
    End Method


	'returns whether the sun is visible
    Method IsSunVisible:int()
		return (GetWorldWeather() = TWorldWeather.WEATHER_FINE OR GetWorldWeather() = TWorldWeather.WEATHER_CLEAR)
	End Method


	'returns whether it is raining or not.
	'returned value ranges from 0 (no rain) to 5 (full rain)
	Method IsRaining:int()
		Select GetWorldWeather()
			case TWorldWeather.WEATHER_LIGHTRAIN    return 1
			case TWorldWeather.WEATHER_RAIN         return 2
			case TWorldWeather.WEATHER_HEAVYRAIN    return 3
			case TWorldWeather.WEATHER_STORM        return 4
			case TWorldWeather.WEATHER_SEVERESTORM  return 5
		End Select
		return 0
	End Method


	Method IsStorming:int()
		Select GetWorldWeather()
			case TWorldWeather.WEATHER_STORM        return 1
			case TWorldWeather.WEATHER_SEVERESTORM  return 2
		EndSelect
		return 0
	End Method


	'returns how bright a cloud is.
	'values are from 0-100 (so "percentage"). 100 means pure white
    Method GetCloudBrightness:int()
		Select GetWorldWeather()
			case TWorldWeather.WEATHER_CLEAR        return 100
			case TWorldWeather.WEATHER_FINE         return 100
			case TWorldWeather.WEATHER_CLOUDY       return 100
			case TWorldWeather.WEATHER_HEAVYCLOUD   return 75
			case TWorldWeather.WEATHER_LIGHTRAIN    return 75
			case TWorldWeather.WEATHER_RAIN         return 75
			case TWorldWeather.WEATHER_HEAVYRAIN    return 75
			case TWorldWeather.WEATHER_STORM        return 75
			case TWorldWeather.WEATHER_SEVERESTORM  return 25
			case TWorldWeather.WEATHER_HURRICANE    return 25
			Default                                 return 100
		End Select
	End Method


	Method ToString:string()
		return "Weather="+GetWorldWeatherText()+" pressure="+GetPressure()+" windVelocity="+GetWindVelocity()
	End Method
End Type