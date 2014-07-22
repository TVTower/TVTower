'likely a kind of agency providing news...
'at the moment only a base object
Type TNewsAgency
	'when to announce a new newsevent
	Field NextEventTime:Double = 0
	'check for a new news every x-y minutes
	Field NextEventTimeInterval:int[] = [50, 80]
	'when to announce a new news from a newschain
	Field NextChainTime:Double = 0
	'check for a new newschain every x-y minutes
	Field NextChainTimeInterval:int[] = [10, 15]
	'holding chained news from the past hours/day
	Field activeChains:TList = CreateList()

	'=== WEATHER HANDLING ===
	'time of last weather event/news
	Field weatherUpdateTime:Double = 0
	'announce new weather every x-y minutes
	Field weatherUpdateTimeInterval:int[] = [360, 720]
	Field weatherType:int = 0
	

	'=== TERRORIST HANDLING ===
	'both parties (VR and FR) have their own array entry
	'when to update propabilities the next time
	Field terroristUpdateTime:Double = 0
	'update terrorists probability every x-y minutes
	Field terroristUpdateTimeInterval:int[] = [45, 60]
	'chances that an attack is announced (0 - 1.0)
	Field terroristAttackProbability:Float[] = [0.0, 0.0]
	'rate the propability grows each game hour
	Field terroristAttackProbabilityGrowth:Float[][] = [ [0.02,0.07], [0.02,0.07] ]	
	Global _instance:TNewsAgency


	Function GetInstance:TNewsAgency()
		if not _instance then _instance = new TNewsAgency
		return _instance
	End Function


	Method Update:int()
		'All players update their newsagency on their own.
		'As we use "randRange" this will produce the same random values
		'on all clients - so they should be sync'd all the time.
		
		If NextEventTime < GetWorldTime().GetTimeGone() Then AnnounceNewNewsEvent()
		If NextChainTime < GetWorldTime().GetTimeGone() Then ProcessNewsEventChains()
		If terroristUpdateTime < GetWorldTime().GetTimeGone() Then UpdateTerrorists()
		If weatherUpdateTime < GetWorldTime().GetTimeGone() Then UpdateWeather()
	End Method


	Method UpdateTerrorists:int()
		'set next update time (between min-max interval)
		terroristUpdateTime = GetWorldTime().GetTimeGone() + 60*randRange(terroristUpdateTimeInterval[0], terroristUpdateTimeInterval[1])

		'who is the mainaggressor? - this parties probability grows faster
		local mainAggressor:int = (terroristAttackProbability[1] > terroristAttackProbability[0])
		
		For local i:int = 0 to 1
			'randRange uses "ints", so convert 1.0 to 100
			local increase:Float = 0.01 * randRange(terroristAttackProbabilityGrowth[i][0]*100, terroristAttackProbabilityGrowth[i][1]*100)
			'if not the mainaggressor, grow slower
			if i <> mainAggressor then increase :* 0.5

			terroristAttackProbability[i] :+ increase
			
			'more than 100%? start attack (news event)
			if terroristAttackProbability[i] > 1.0
				terroristAttackProbability[i] = 0.0
				'print GetWorldTime().GetDay()+". "+GetWorldTime().GetFormattedTime() + " | terrorist["+i+"] attack"

				'Create terror news event
			endif
		Next
	End Method


	Method UpdateWeather:int()
		weatherUpdateTime = GetWorldTime().GetTimeGone() + 60 * randRange(weatherUpdateTimeInterval[0], weatherUpdateTimeInterval[1])


		local newsEvent:TNewsEvent = GetWeatherNewsEvent()
		If newsEvent
			'Print "[LOCAL] UpdateWeather: added weather news title="+newsEvent.title+", day="+GetWorldTime().getDay(newsEvent.happenedtime)+", time="+GetWorldTime().GetFormattedTime(newsEvent.happenedtime)
			announceNewsEvent(newsEvent, GetWorldTime().GetTimeGone() + 0)
		EndIf

	End Method



	Method GetWeatherNewsEvent:TNewsEvent()
		'quality and price are nearly the same everytime
		Local quality:int = randRange(50,60)
		Local price:int = randRange(45,50)
		local beginHour:int = GetWorldTime().GetDayHour()+1
		local endHour:int = GetWorldTime().GetDayHour(weatherUpdateTime)
		Local description:string = ""
		local title:string = GetLocale("WEATHER_FORECAST_FOR_X_TILL_Y").replace("%BEGINHOUR%", beginHour).replace("%ENDHOUR%", endHour)
		local forecastHours:int = ceil((weatherUpdateTime - GetWorldTime().GetTimeGone()) / 3600.0)
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
		local sunHours:int = 0
		local sunAverage:float = 0.0
		local tempMin:int = 1000, tempMax:int = -1000

		'fetch next weather
		local upcomingWeather:TWorldWeatherEntry[forecastHours]
		For local i:int = 0 until forecastHours
			upcomingWeather[i] = GetWorld().Weather.GetUpcomingWeather(i+1)
		Next


		'check for specific states
		For weather = eachin upcomingWeather
			if GetWorldTime().IsNight(weather._time)
				isNight = True
			else
				isDay = True
			endif

			tempMin = Min(tempMin, weather.GetTemperature())
			tempMax = Max(tempMax, weather.GetTemperature())

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
			description :+ GetLocale("SKY_IS_PARTIALLY_CLOUDY")
		elseif isCloudy
			description :+ GetLocale("SKY_IS_OVERCAST")
		elseif isClear
			description :+ GetLocale("SKY_IS_WITHOUT_CLOUDS")
		endif
		
		if sunAverage = 1.0 and isDay
			if not isNight then description :+ GetLocale("SUN_SHINES_WHOLE_TIME")
		elseif sunAverage > 0.5
			description :+ GetLocale("SUN_WINS_AGAINST_CLOUDS")
		elseif sunAverage > 0
			description :+ GetLocale("SUN_IS_SHINING_SOMETIMES")
		else
			description :+ GetLocale("SUN_IS_NOT_SHINING")
		endif

		if isRaining and isSnowing
			description :+ GetLocale("RAIN_AND_SNOW_ALTERNATE")
		elseif isRaining
			description :+ GetLocale("RAIN_IS_POSSIBLE")
		elseif isSnowing
			description :+ GetLocale("SNOW_IS_FALLING")
		endif

		if tempMin <> tempMax
			description :+ GetLocale("TEMPERATURES_ARE_BETWEEN_X_AND_Y").replace("%MINTEMPERATURE%", tempMin).replace("%MAXTEMPERATURE%", tempMax)
		else
			description :+ GetLocale("TEMPERATURE_IS_CONSTANT_AT_X").replace("%TEMPERATURE%", tempMin)
		endif
		
		Local NewsEvent:TNewsEvent = TNewsEvent.Create(title, description, TNewsEvent.GENRE_CURRENTS, quality, price)
		'remove news from available list to avoid repetition
		NewsEventCollection.Remove(NewsEvent)

		Return NewsEvent
	End Method


	Method GetMovieNewsEvent:TNewsEvent()
		Local licence:TProgrammeLicence = Self._GetAnnouncableProgrammeLicence()
		If Not licence Then Return Null
		If Not licence.getData() Then Return Null

		licence.GetData().releaseAnnounced = True

		Local title:String = getLocale("NEWS_ANNOUNCE_MOVIE_TITLE"+Rand(1,2) )
		Local description:String = getLocale("NEWS_ANNOUNCE_MOVIE_DESCRIPTION"+Rand(1,4) )

		'if same director and main actor...
		If licence.GetData().getActor(1) = licence.GetData().getDirector(1)
			title = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_TITLE")
			description = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_DESCRIPTION")
		EndIf
		'if no actors ...
		If licence.GetData().getActor(1) = ""
			title = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_TITLE")
			description = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_DESCRIPTION")
		EndIf

		'replace data
		title = Self._ReplaceProgrammeData(title, licence.GetData())
		description = Self._ReplaceProgrammeData(description, licence.GetData())

		'quality and price are based on the movies data
		Local NewsEvent:TNewsEvent = TNewsEvent.Create(title, description, TNewsEvent.GENRE_SHOWBIZ, licence.GetData().review/2.0, licence.GetData().outcome/3.0)
		'remove news from available list as we do not want to have them repeated :D
		NewsEventCollection.Remove(NewsEvent)

		Return NewsEvent
	End Method


	Method _ReplaceProgrammeData:String(text:String, data:TProgrammeData)
		For Local i:Int = 1 To 2
			text = text.Replace("%ACTORNAME"+i+"%", data.getActor(i))
			text = text.Replace("%DIRECTORNAME"+i+"%", data.getDirector(i))
		Next
		text = text.Replace("%MOVIETITLE%", data.title)

		Return text
	End Method


	'helper to get a movie which can be used for a news
	Method _GetAnnouncableProgrammeLicence:TProgrammeLicence()
		'filter to entries we need
		Local licence:TProgrammeLicence
		Local resultList:TList = CreateList()
		For licence = EachIn TProgrammeLicence.movies
			'ignore collection and episodes (which should not be in that list)
			If Not licence.getData() Then Continue

			'ignore if filtered out
			If licence.owner <> 0 Then Continue
			'ignore already announced movies
			If licence.getData().releaseAnnounced Then Continue
			'ignore unreleased
			If Not licence.ignoreUnreleasedProgrammes And licence.getData().year < licence._filterReleaseDateStart Or licence.getData().year > licence._filterReleaseDateEnd Then Continue
			'only add movies of "next X days" - 14 = 1 year
			Local licenceTime:Int = licence.GetData().year * GetWorldTime().GetDaysPerYear() + licence.getData().releaseDay
			If licenceTime > GetWorldTime().getDay() And licenceTime - GetWorldTime().getDay() < 14 Then resultList.addLast(licence)
		Next
		If resultList.count() > 0 Then Return TProgrammeLicence._GetRandomFromList(resultList)

		Return Null
	End Method


	'announces new news chain elements
	Method ProcessNewsEventChains:Int()
		Local announced:Int = 0
		Local newsEvent:TNewsEvent = Null
		For Local chainElement:TNewsEvent = EachIn activeChains
			If Not chainElement.isLastEpisode() Then newsEvent = chainElement.GetNextNewsEventFromChain()
			'remove the "old" one, the new element will get added instead (if existing)
			activeChains.Remove(chainElement)

			'ignore if the chain ended already
			If Not newsEvent Then Continue

			If chainElement.happenedTime + newsEvent.getHappenDelay() < GetWorldTime().GetTimeGone()
				announceNewsEvent(newsEvent)
				announced:+1
			EndIf
		Next

		'check every x-y game minutes
		NextChainTime = GetWorldTime().GetTimeGone() + 60 * randRange(NextChainTimeInterval[0], NextChainTimeInterval[1])

		Return announced
	End Method


	Function GetNewsAbonnementDelay:Int(genre:Int, level:int) {_exposeToLua}
		if level = 3 then return 0
		if level = 2 then return 60
		if level = 1 then return 150 'not needed but better overview
		return 150
	End Function


	'Returns the extra charge for a news
	Function GetNewsRelativeExtraCharge:Float(genre:Int, level:int) {_exposeToLua}
		'up to now: ignore genre, all share the same values
		if level = 3 then return 0.20
		if level = 2 then return 0.10
		if level = 1 then return 0.00 'not needed but better overview
		return 0.00
	End Function


	'Returns the price for this level of a news abonnement
	Function GetNewsAbonnementPrice:Int(level:Int=0)
		if level = 1 then return 10000
		if level = 2 then return 20000
		if level = 3 then return 35000
		return 0
	End Function


	Method AddNewsEventToPlayer:Int(newsEvent:TNewsEvent, forPlayer:Int=-1, fromNetwork:Int=0)
		local player:TPlayer = GetPlayerCollection().Get(forPlayer)
		'only add news/newsblock if player is Host/Player OR AI
		'If Not Game.isLocalPlayer(forPlayer) And Not Game.isAIPlayer(forPlayer) Then Return 'TODO: Wenn man gerade Spieler 2 ist/verfolgt (Taste 2) dann bekommt Spieler 1 keine News
		If Player.newsabonnements[newsEvent.genre] > 0
			local news:TNews = TNews.Create("", 0, newsEvent)

			news.publishDelay = GetNewsAbonnementDelay(newsEvent.genre, Player.newsabonnements[newsEvent.genre] )
			news.priceModRelativeNewsAgency = GetNewsRelativeExtraCharge(newsEvent.genre, GetPlayerCollection().Get(forPlayer).GetNewsAbonnement(newsEvent.genre))

			'add to players collection
			player.GetProgrammeCollection().AddNews(news)
		EndIf
	End Method


	Method announceNewsEvent:Int(newsEvent:TNewsEvent, happenedTime:Int=0)
		newsEvent.doHappen(happenedTime)

		For Local i:Int = 1 To 4
			AddNewsEventToPlayer(newsEvent, i)
		Next

		If newsEvent.episodes.count() > 0 Then activeChains.AddLast(newsEvent)
	End Method


	'generates a new news event from various sources (such as new
	'movie announcements, actor news ...)
	Method GenerateNewNewsEvent:TNewsEvent()
		local newsEvent:TNewsEvent = null

		'=== TYPE MOVIE NEWS ===
		'35% chance: try to load some movie news ("new movie announced...")
		If Not newsEvent And RandRange(1,100) < 35
			newsEvent = GetMovieNewsEvent()
		EndIf


		'=== TYPE RANDOM NEWS ===
		'if no "special case" triggered, just use a random news
		If Not newsEvent
			newsEvent = NewsEventCollection.GetRandom()
		EndIf

		return newsEvent
	End Method


	Method AnnounceNewNewsEvent:Int(delayAnnouncement:Int=0)
		'=== CREATE A NEW NEWS ===
		Local newsEvent:TNewsEvent = GenerateNewNewsEvent()


		'=== ANNOUNCE THE NEWS ===
		'only announce if forced or somebody is listening
		If newsEvent
			local skipNews:int = newsEvent.IsSkippable()
			If skipNews
				For Local player:TPlayer = eachin GetPlayerCollection().players
					'a player listens to this genre, disallow skipping
					If player.newsabonnements[newsEvent.genre] > 0 Then skipNews = False
				Next
			EndIf

			If not skipNews
				'Print "[LOCAL] AnnounceNewNews: added news title="+news.title+", day="+GetWorldTime().getDay(news.happenedtime)+", time="+GetWorldTime().GetFormattedTime(news.happenedtime)
				announceNewsEvent(newsEvent, GetWorldTime().GetTimeGone() + delayAnnouncement)
			EndIf
		EndIf


		'=== ADJUST TIME FOR NEXT NEWS ANNOUNCEMENT ===
		ResetNextEventTime()
	End Method


	Method ResetNextEventTime:int()
		'between 20 and 50 minutes until next news
		NextEventTime = GetWorldTime().GetTimeGone() + 60 * randRange(NextEventTimeInterval[0], NextEventTimeInterval[1])
		'50% chance to have an even longer time
		If RandRange(0,10) > 5
			NextEventTime = + randRange(NextEventTimeInterval[0], NextEventTimeInterval[1])
		EndIf
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return singleton instance
Function GetNewsAgency:TNewsAgency()
	Return TNewsAgency.GetInstance()
End Function
