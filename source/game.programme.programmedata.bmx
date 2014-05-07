REM
	===========================================================
	code for programme-objects (movies, ..) in programme planning
	===========================================================
ENDREM
SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.gametime.bmx"
Import "game.programme.programmeperson.bmx"
Import "game.broadcast.genredefinition.movie.bmx"


Type TProgrammeDataCollection
	Field list:TList			= CreateList()
	'factor by what a programmes topicality DECREASES by sending it
	Field wearoffFactor:float	= 0.65
	'factor by what a programmes topicality INCREASES by a day switch
	Field refreshFactor:float	= 1.5
	'values get multiplied with the refresh factor
	'so this means: higher values increase the resulting topicality win
	Field genreRefreshModifier:float[] =  [	1.0, .. 	'action
											1.0, .. 	'thriller
											1.0, .. 	'scifi
											1.5, .. 	'comedy
											1.0, ..		'horror
											1.0, ..		'love
											1.5, ..		'erotic
											1.0, ..		'western
											0.75, ..	'live
											1.5, .. 	'children
											1.25, .. 	'animated / cartoon
											1.25, .. 	'music
											1.0, .. 	'sport
											1.0, .. 	'culture
											1.0, .. 	'fantasy
											1.25, .. 	'yellow press
											1.0, .. 	'news
											1.0, .. 	'show
											1.0, .. 	'monumental
											2.0, .. 	'fillers
											2.0 .. 		'paid programming
										  ]
	'values get multiplied with the wearOff factor
	'so this means: higher (>1.0) values decrease the resulting topicality loss
	Field genreWearoffModifier:float[] =  [	1.0, .. 	'action
											1.0, .. 	'thriller
											1.0, .. 	'scifi
											1.0, .. 	'comedy
											1.0, ..		'horror
											1.0, ..		'love
											1.2, ..		'erotic
											1.0, ..		'western
											0.75, ..		'live
											1.25, .. 	'children
											1.15, .. 	'animated / cartoon
											1.2, .. 	'music
											0.95, .. 	'sport
											1.1, .. 	'culture
											1.0, .. 	'fantasy
											1.2, .. 	'yellow press
											0.9, .. 	'news
											0.9, .. 	'show
											1.1, .. 	'monumental
											1.4, .. 	'fillers
											1.4 .. 		'paid programming
										  ]


	Method Add:int(obj:TProgrammeData)
		list.AddLast(obj)
		return TRUE
	End Method


	Method GetGenreRefreshModifier:float(genre:int=-1)
		if genre < self.genreRefreshModifier.length then return self.genreRefreshModifier[genre]
		'default is 1.0
		return 1.0
	End Method


	Method GetGenreWearoffModifier:float(genre:int=-1)
		if genre < self.genreWearoffModifier.length then return self.genreWearoffModifier[genre]
		'default is 1.0
		return 1.0
	End Method

End Type
Global ProgrammeDataCollection:TProgrammeDataCollection = new TProgrammeDataCollection




'raw data for movies, series,...
Type TProgrammeData {_exposeToLua}
	Field title:string					= ""
	Field description:string			= ""
	Field actors:TProgrammePerson[]							'array holding actor(s)
	Field directors:TProgrammePerson[]						'array holding director(s)
	Field country:String				= "UNK"
	Field year:Int						= 1900
	Field targetGroup:int				= 0					'special targeted audience?
	Field refreshModifier:float			= 1.0				'changes how much a programme "regenerates" (multiplied with genreModifier)
	Field wearoffModifier:Float			= 1.0				'changes how much a programme loses during sending it
	Field liveHour:Int					= 0
	Field outcome:Float					= 0
	Field review:Float					= 0
	Field speed:Float					= 0
	Field relPrice:Int					= 0
	Field genre:Int						= 0
	Field blocks:Int					= 1
	Field xrated:Int					= 0
	Field programmeType:Int				= 1					'0 = serie, 1 = movie, ...?
	Field releaseDay:Int				= 1					'at which day was the programme released?
	Field releaseAnnounced:int			= FALSE				'announced in news etc?
	Field timesAired:int				= 0					'how many times that programme was run
	Field topicality:Int				= -1 				'how "attractive" a programme is (the more shown, the less this value)
	'trailer data
	Field trailerTopicality:float		= 1.0
	Field trailerMaxTopicality:float	= 1.0
	Field trailerAired:int				= 0					'times the trailer aired
	Field trailerAiredSinceShown:int	= 0					'times the trailer aired since the programme was shown "normal"

	Field genreDefinitionCache:TMovieGenreDefinition = Null

	const TYPE_UNKNOWN:int		= 1
	const TYPE_EPISODE:int		= 2
	const TYPE_SERIES:int		= 4
	const TYPE_MOVIE:int		= 8

	Const GENRE_ACTION:Int		= 0
	Const GENRE_THRILLER:Int	= 1
	Const GENRE_SCIFI:Int		= 2
	Const GENRE_COMEDY:Int		= 3
	Const GENRE_HORROR:Int		= 4
	Const GENRE_LOVE:Int		= 5
	Const GENRE_EROTIC:Int		= 6
	Const GENRE_WESTERN:Int		= 7
	Const GENRE_LIVE:Int		= 8
	Const GENRE_KIDS:Int		= 9
	Const GENRE_CARTOON:Int		= 10
	Const GENRE_MUSIC:Int		= 11
	Const GENRE_SPORT:Int		= 12
	Const GENRE_CULTURE:Int		= 13
	Const GENRE_FANTASY:Int		= 14
	Const GENRE_YELLOWPRESS:Int	= 15
	Const GENRE_NEWS:Int		= 16
	Const GENRE_SHOW:Int		= 17
	Const GENRE_MONUMENTAL:Int	= 18
	Const GENRE_CALLINSHOW:Int	= 20


	Function Create:TProgrammeData(title:String, description:String, actors:String, directors:String, country:String, year:Int, day:int=0, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, xrated:Int, refreshModifier:float=1.0, wearoffModifier:float=1.0, programmeType:Int=1) {_private}
		Local obj:TProgrammeData = New TProgrammeData

		obj.title			= title
		obj.description 	= description
		obj.programmeType	= programmeType
		obj.refreshModifier = Max(0.0, refreshModifier)
		obj.wearoffModifier = Max(0.0, wearoffModifier)
		obj.review			= Max(0,review)
		obj.speed			= Max(0,speed)
		obj.relPrice		= Max(0,relPrice)
		obj.outcome			= Max(0,Outcome)
		obj.genre			= Max(0,Genre)
		obj.blocks			= blocks
		obj.xrated			= xrated
		obj.actors			= _GetPersonsFromString(actors, TProgrammePerson.JOB_ACTOR)
		obj.directors		= _GetPersonsFromString(directors, TProgrammePerson.JOB_DIRECTOR)
		obj.country			= country
		obj.year			= year
		obj.releaseDay		= day
		obj.liveHour		= Max(-1,livehour)
		obj.topicality		= obj.GetTopicality()

		ProgrammeDataCollection.Add(obj)
		Return obj
	End Function


	Function CreateMinimal:TProgrammeData(title:String = null, genre:Int = 0, fixQuality:Float, year:Int = 1985)
		Local quality:Int = fixQuality * 255
		Return TProgrammeData.Create(title, Null, Null, Null, Null, year, 0, 0, quality, quality, quality, 0, genre, 0, 0, 1, 1, 1)
	End Function


	'what to earn for each viewer
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		local result:float = 0.0
		If GetGenre() = TProgrammeData.GENRE_CALLINSHOW
			result :+ GetSpeed() * 0.05
			result :+ GetReview() * 0.2
			'adjust by topicality
			result :* (GetTopicality()/GetMaxTopicality())
		Else
			'by default no programme has a sponsorship
			result = 0.0
			'TODO: include sponsorships
		Endif
		return result
	End Method


	Method GetActor:string(number:int=1)
		number = Min(actors.length, Max(1, number))
		if number = 0 then return ""
		return actors[number-1].GetFullName()
	End Method


	Method GetActorsString:string()
		local result:string = ""
		for local i:int = 0 to actors.length-1
			result:+ actors[i].GetFullName()+", "
		Next
		return result[..result.length-2]
	End Method


	Method GetDirector:string(number:int=1)
		number = Min(directors.length, Max(1, number))
		if number = 0 then return ""
		return directors[number-1].GetFullName()
	End Method


	Method GetDirectorsString:string()
		local result:string = ""
		for local i:int = 0 to directors.length-1
			result:+ directors[i].GetFullName()+", "
		Next
		return result[..result.length-2]
	End Method


	Function _GetPersonsFromString:TProgrammePerson[](personsString:string="", job:int=0)
		local personsStringArray:string[] = personsString.split(",")
		local personArray:TProgrammePerson[]

		For local personString:string = eachin personsStringArray
			'split first and lastName
			local _name:string[] = personString.split(" ")
			local name:string[]
			'remove " "-strings
			for local i:int = 0 to _name.length-1
				if _name[i].trim() = "" then continue
				name = name[..name.length+1]
				name[name.length-1] = _name[i]
			Next

			'ignore "unknown" actors
			if name.length <= 0 or name[0] = "XXX" then continue

			local firstName:string = name[0]
			local lastName:string = ""
			'add rest to lastname
			For local i:int = 1 to name.length - 1
				lastName:+ name[i]+" "
			Next
			'trim last space
			lastName = lastName[..lastName.length-1]

			local person:TProgrammePerson = TProgrammePerson.GetByName(firstName, lastName)
			if person
				person.AddJob(job)
			else
				person = TProgrammePerson.Create(firstName, lastName, job)
			endif

			'increase arraysize by 1
			personArray = personArray[..personArray.length+1]
			'add person
			personArray[personArray.length-1] = person
		Next
		return personArray
	End Function



	Method GetRefreshModifier:float()
		return self.refreshModifier
	End Method


	Method GetWearoffModifier:float()
		return self.wearoffModifier
	End Method


	Method GetGenreWearoffModifier:float(genre:int=-1)
		if genre = -1 then genre = self.genre
		return ProgrammeDataCollection.GetGenreWearoffModifier(genre)
	End Method


	Method GetGenre:int()
		return self.genre
	End Method


	Method GetGenreRefreshModifier:float(genre:int=-1)
		if genre = -1 then genre = self.genre
		return ProgrammeDataCollection.GetGenreRefreshModifier(genre)
	End Method


	Method GetGenreString:String(_genre:Int=-1)
		If _genre > 0 Then Return GetLocale("MOVIE_GENRE_" + _genre)
		Return GetLocale("MOVIE_GENRE_" + Self.genre)
	End Method


	Method GetTitle:string()
		return self.title
	End Method


	Method GetDescription:string()
		return self.description
	End Method


	Method GetXRated:int()
		return (self.xrated <> "")
	End Method


	Method GetBlocks:int()
		return self.blocks
	End Method


	Method GetOutcome:int()
		return self.outcome
	End Method


	Method GetSpeed:int()
		return self.speed
	End Method


	Method GetReview:int()
		return self.review
	End Method


	Method GetPrice:int()
		Local tmpreview:Float
		Local tmpspeed:Float
		Local value:int = 0
		If Outcome > 0 'movies
			value = 0.55 * 255 * Outcome + 0.25 * 255 * review + 0.2 * 255 * speed
			If (GetMaxTopicality() >= 230) Then value:*1.4
			If (GetMaxTopicality() >= 240) Then value:*1.6
			If (GetMaxTopicality() >= 250) Then value:*1.8
			If (GetMaxTopicality() > 253)  Then value:*2.1 'the more current the more expensive
		Else 'shows, productions, series...
			If (review > 0.5 * 255) Then tmpreview = 255 - 2.5 * (review - 0.5 * 255) else tmpreview = 1.6667 * review
			If (speed > 0.6 * 255) Then tmpspeed = 255 - 2.5 * (speed - 0.6 * 255) else tmpspeed = 1.6667 * speed
			value = 1.3 * ( 0.45 * 255 * tmpreview + 0.55 * 255 * tmpspeed )
		EndIf
		value:*(1.5 * GetTopicality() / 255)
		value = Int(Floor(value / 1000) * 1000)

		return value
	End Method


	Method GetMaxTopicality:int()
		return Max(0, 255 - 2 * Max(0, GetGameTime().GetYear() - year) - Min(50, timesAired * 5)) 'simplest form ;D
	End Method


	Method GetTopicality:int()
		if topicality < 0 then topicality = GetMaxTopicality()
		return topicality
	End Method


	Method GetGenreDefinition:TMovieGenreDefinition()
		If Not genreDefinitionCache Then
			genreDefinitionCache = GetMovieGenreDefinitionCollection().Get(Genre)
		EndIf
		Return genreDefinitionCache
	End Method


	Method GetQualityRaw:Float()
		Local genreDef:TMovieGenreDefinition = GetGenreDefinition()
		If genreDef.OutcomeMod > 0.0 Then
			Return Float(Outcome) / 255.0 * genreDef.OutcomeMod ..
				+ Float(review) / 255.0 * genreDef.ReviewMod ..
				+ Float(speed) / 255.0 * genreDef.SpeedMod
		Else
			Return Float(review) / 255.0 * genreDef.ReviewMod ..
				+ Float(speed) / 255.0 * genreDef.SpeedMod
		EndIf
	End Method


	'Diese Methode ersetzt "GetBaseAudienceQuote"
	Method GetQuality:Float() {_exposeToLua}
		Local quality:Float = GetQualityRaw()

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0, 100 - Max(0, GetGameTime().GetYear() - year))
		quality:*Max(0.20, (age / 100.0))

		'repetitions wont be watched that much
		quality:*(GetTopicality() / 255.0) ^ 2

		quality = quality * 0.99 + 0.01 'Mindestens 1% Qualitaet

		'no minus quote
		quality = Max(0.01, quality)

		Return quality
	End Method


	Method CutTopicality:Int(cutFactor:float=1.0) {_private}
		'cutFactor can be used to manipulate the resulting cut
		'eg for night times

		'cut of by an individual cutoff factor - do not allow values > 1.0 (refresh instead of cut)
		'the value : default * invidual * individualGenre
		topicality:* Min(1.0,  cutFactor * ProgrammeDataCollection.wearoffFactor * GetGenreWearoffModifier() * GetWearoffModifier() )
	End Method


	'by default each airing cuts to 90% of the current topicality
	Method CutTrailerTopicality:Int(cutToFactor:float=0.9) {_private}
		trailerTopicality:* Min(1.0,  cutToFactor * trailerTopicality)
	End Method


	Function RefreshAllTopicalities:int() {_private}
		For Local data:TProgrammeData = eachin ProgrammeDataCollection.list
			data.RefreshTopicality()
			data.RefreshTrailerTopicality()
		Next
	End Function


	Method RefreshTopicality:Int() {_private}
		topicality = Min(GetMaxTopicality(), topicality*ProgrammeDataCollection.refreshFactor*self.GetGenreRefreshModifier()*self.GetRefreshModifier())
		Return topicality
	End Method


	Method RefreshTrailerTopicality:Int() {_private}
		trailerTopicality = Min(1.0, trailerTopicality*1.25)
		Return trailerTopicality
	End Method


	Method getTargetGroup:int()
		return self.targetGroup
	End Method


	'returns amount of trailers aired since last normal programme broadcast
	'or "in total"
	Method GetTimesTrailerAired:Int(total:int=TRUE)
		if total then return self.trailerAired
		return self.trailerAiredSinceShown
	End Method


	Method GetTrailerMod:TAudience()
		'TODO: Bessere Berechnung
		Local timesTrailerAired:Int = GetTimesTrailerAired(False)
		Local trailerMod:Float = 1

		Select timesTrailerAired
			Case 0 	trailerMod = 1
			Case 1 	trailerMod = 1.25
			Case 2 	trailerMod = 1.40
			Case 3 	trailerMod = 1.50
			Case 4 	trailerMod = 1.55
			Default	trailerMod = 1.6
		EndSelect

		Return TAudience.CreateAndInit(trailerMod, trailerMod, trailerMod, trailerMod, trailerMod, trailerMod, trailerMod, trailerMod, trailerMod)
	End Method


	Method GetTimesAired:Int()
		return timesAired
	End Method


	Method isReleased:int()
		'call-in shows are kind of "live"
		if genre = GENRE_CALLINSHOW then return TRUE

		return (year <= GetGameTime().getYear() and releaseDay <= GetGameTime().getDay())
	End Method


	Method isMovie:int()
		return programmeType = TYPE_MOVIE
	End Method


	Method isSeries:int()
		return programmeType = TYPE_SERIES | TYPE_EPISODE
	End Method
End Type
