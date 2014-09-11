REM
	===========================================================
	code for programme-objects (movies, ..) in programme planning
	===========================================================
ENDREM
SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.world.worldtime.bmx"
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
	Global _instance:TProgrammeDataCollection


	Function GetInstance:TProgrammeDataCollection()
		if not _instance then _instance = new TProgrammeDataCollection
		return _instance
	End Function


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


	Function RefreshTopicalities:int()
		For Local data:TProgrammeData = eachin GetProgrammeDataCollection().list
			data.RefreshTopicality()
			data.RefreshTrailerTopicality()
		Next
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeDataCollection:TProgrammeDataCollection()
	Return TProgrammeDataCollection.GetInstance()
End Function





'raw data for movies, series,...
Type TProgrammeData {_exposeToLua}
	Field title:string = ""
	Field description:string = ""
	'array holding actor(s)
	Field actors:TProgrammePerson[]
	'array holding director(s)
	Field directors:TProgrammePerson[]
	Field country:String = "UNK"
	Field year:Int = 1900
	'special targeted audience?
	Field targetGroup:int = 0
	'changes how much a programme "regenerates" (multiplied with genreModifier)
	Field refreshModifier:float = 1.0
	'changes how much a programme loses during sending it
	Field wearoffModifier:Float	= 1.0
	Field liveHour:Int = 0
	Field outcome:Float	= 0
	Field review:Float = 0
	Field speed:Float = 0
	Field priceModifier:Float = 1.0
	Field genre:Int	= 0
	Field blocks:Int = 1
	Field xrated:Int = 0
	'0 = serie, 1 = movie, ...?
	Field programmeType:Int	= 1
	'at which day was the programme released?
	Field releaseDay:Int = 1
	'announced in news etc?
	Field releaseAnnounced:int = FALSE
	'how many times that programme was run
	'(per player, 0 = unknown - eg before "game start" to lower values)
	Field timesAired:int[] = [0]
	'how "attractive" a programme is (the more shown, the less this value)
	Field topicality:Float = -1

	'=== trailer data ===
	Field trailerTopicality:float = 1.0
	Field trailerMaxTopicality:float = 1.0
	'times the trailer aired
	Field trailerAired:int = 0
	'times the trailer aired since the programme was shown "normal"
	Field trailerAiredSinceShown:int = 0

	Field genreDefinitionCache:TMovieGenreDefinition = Null {nosave}

	Const TYPE_UNKNOWN:int		= 1
	Const TYPE_EPISODE:int		= 2
	Const TYPE_SERIES:int		= 4
	Const TYPE_MOVIE:int		= 8

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
	Const GENRE_FILLER:Int		= 19 'TV films etc.
	Const GENRE_CALLINSHOW:Int	= 20


	Function Create:TProgrammeData(title:String, description:String, actors:TProgrammePerson[], directors:TProgrammePerson[], country:String, year:Int, day:int=0, livehour:Int, Outcome:Float, review:Float, speed:Float, priceModifier:Float, Genre:Int, blocks:Int, xrated:Int, refreshModifier:float=1.0, wearoffModifier:float=1.0, programmeType:Int=1) {_private}
		Local obj:TProgrammeData = New TProgrammeData

		obj.title			= title
		obj.description 	= description
		obj.programmeType	= programmeType
		obj.refreshModifier = Max(0.0, refreshModifier)
		obj.wearoffModifier = Max(0.0, wearoffModifier)
		obj.review			= Max(0,Min(1.0, review))
		obj.speed			= Max(0,Min(1.0, speed))
		obj.outcome			= Max(0,Min(1.0, Outcome))
		obj.priceModifier   = Max(0,priceModifier) '- modificator. > 100% increases price
		obj.genre			= Max(0,Genre)
		obj.blocks			= blocks
		obj.xrated			= xrated
		obj.actors			= actors
		obj.directors		= directors
		obj.country			= country
		obj.year			= year
		obj.releaseDay		= day
		obj.liveHour		= Max(-1,livehour)
		obj.topicality		= obj.GetTopicality()

		GetProgrammeDataCollection().Add(obj)
		Return obj
	End Function


	Function CreateMinimal:TProgrammeData(title:String = null, genre:Int = 0, fixQuality:Float, year:Int = 1985)
		Local quality:Int = fixQuality
		Return TProgrammeData.Create(title, Null, Null, Null, Null, year, 0, 0, quality, quality, quality, 0, genre, 0, 0, 1, 1, 1)
	End Function


	'what to earn for each viewer
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		local result:float = 0.0
		If GetGenre() = TProgrammeData.GENRE_CALLINSHOW
			result :+ GetSpeed() * 127.5
			result :+ GetReview() * 51
			'cut to 50%
			result :* 0.5
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


	Method GetRefreshModifier:float()
		return self.refreshModifier
	End Method


	Method GetWearoffModifier:float()
		return self.wearoffModifier
	End Method


	Method GetGenreWearoffModifier:float(genre:int=-1)
		if genre = -1 then genre = self.genre
		return GetProgrammeDataCollection().GetGenreWearoffModifier(genre)
	End Method


	Method GetGenre:int()
		return self.genre
	End Method


	Method GetGenreRefreshModifier:float(genre:int=-1)
		if genre = -1 then genre = self.genre
		return GetProgrammeDataCollection().GetGenreRefreshModifier(genre)
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


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcome:Float()
		return self.outcome
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetSpeed:Float()
		return self.speed
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetReview:Float()
		return self.review
	End Method


	Method GetPrice:int()
		Local value:int = 0

		'maximum price is
		'basefactor * topicalityModifier * priceModifier

		'movies run in cinema (outcome >0)
		If isMovie() and GetOutcome() > 0
			'basefactor * priceFactor
			value = 120000 * (0.55 * GetOutcome() + 0.25 * GetReview() + 0.2 * GetSpeed())
		 'shows, productions, series...
		Else
			'basefactor * priceFactor
			value = 75000 * ( 0.45 * GetReview() + 0.55 * GetSpeed() )
			if GetReview() > 0.5 then value :* 1.1
			if GetSpeed() > 0.6 then value :* 1.1
		EndIf

		'the more current the more expensive
		'multipliers stack"
		local topicalityModifier:Float = 1.0
		If (GetMaxTopicality() >= 0.80) Then topicalityModifier = 1.1
		If (GetMaxTopicality() >= 0.85) Then topicalityModifier = 1.3
		If (GetMaxTopicality() >= 0.90) Then topicalityModifier = 1.8
		If (GetMaxTopicality() >= 0.94) Then topicalityModifier = 2.5
		If (GetMaxTopicality() >= 0.98) Then topicalityModifier = 3.5
		'make just released programmes even more expensive
		If (GetMaxTopicality() > 0.99)  Then topicalityModifier = 5.0

		value :* topicalityModifier

		'topicality has a certain value influence
		value :* GetTopicality()

		'individual price modifier - default is 1.0
		'until we revisited the database, it only has a 20% influence
		value :* (0.8+0.2*priceModifier)
	
		'round to next "1000" block
		value = Int(Floor(value / 1000) * 1000)

'print GetTitle()+"  value1: "+value + "  outcome:"+GetOutcome()+"  review:"+GetReview() + " maxTop:"+GetMaxTopicality()+" year:"+year

		return value
	End Method


	Method GetMaxTopicality:Float()
		return 0.01 * (Max(0, 100 - Max(0, GetWorldTime().GetYear() - year) - Min(40, GetTimesAired() * 4))) 'simplest form ;D
	End Method


	Method GetTopicality:Float()
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
			Return GetOutcome() * genreDef.OutcomeMod ..
				+ GetReview() * genreDef.ReviewMod ..
				+ GetSpeed() * genreDef.SpeedMod
		Else
			Return GetReview() * genreDef.ReviewMod ..
				+ GetSpeed() * genreDef.SpeedMod
		EndIf
	End Method


	'Diese Methode ersetzt "GetBaseAudienceQuote"
	Method GetQuality:Float() {_exposeToLua}
		Local quality:Float = GetQualityRaw()

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = 0.01 * Max(0, 100 - Max(0, GetWorldTime().GetYear() - year))
		quality :* Max(0.20, age)

		'repetitions wont be watched that much
		quality :* GetTopicality() ^ 2

		'no minus quote, min 0.01 quote
		quality = Max(0.01, quality)

		Return quality
	End Method


	Method CutTopicality:Int(cutFactor:float=1.0) {_private}
		'cutFactor can be used to manipulate the resulting cut
		'eg for night times

		'cut of by an individual cutoff factor - do not allow values > 1.0 (refresh instead of cut)
		'the value : default * invidual * individualGenre
		topicality:* Min(1.0,  cutFactor * GetProgrammeDataCollection().wearoffFactor * GetGenreWearoffModifier() * GetWearoffModifier() )
	End Method


	'by default each airing cuts to 90% of the current topicality
	Method CutTrailerTopicality:Int(cutToFactor:float=0.9) {_private}
		trailerTopicality:* Min(1.0,  cutToFactor * trailerTopicality)
	End Method


	Method RefreshTopicality:Int() {_private}
		topicality = Min(GetMaxTopicality(), topicality*GetProgrammeDataCollection().refreshFactor*self.GetGenreRefreshModifier()*self.GetRefreshModifier())
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


	'playerID < 0 means "get all"
	Method GetTimesAired:Int(playerID:int = -1)
		if playerID >= timesAired.length then return 0
		if playerID >= 0 then return timesAired[playerID]

		local result:int = 0
		For local i:int = 0 until timesAired.length
			result :+ timesAired[i]
		Next
		return result
	End Method


	Method SetTimesAired:Int(times:int, playerID:int)
		if playerID < 0 then playerID = 0

		'resize array if player has no entry yet
		if playerID >= timesAired.length
			timesAired = timesAired[.. playerID + 1]
		endif

		timesAired[playerID] = times
	End Method


	Method isReleased:int()
		'call-in shows are kind of "live"
		if genre = GENRE_CALLINSHOW then return TRUE

		return (year <= GetWorldTime().getYear() and releaseDay <= GetWorldTime().getDay())
	End Method


	Method isMovie:int()
		return programmeType = TYPE_MOVIE
	End Method


	Method isSeries:int()
		return (programmeType = TYPE_SERIES) or (programmeType = TYPE_EPISODE) 
	End Method
End Type
