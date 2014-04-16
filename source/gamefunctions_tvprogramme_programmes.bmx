REM
	===========================================================
	code for programme-objects (movies, ..) in programme planning
	===========================================================
ENDREM

REM
	as globals are not recognized by reflection, we need to
	take care of globals/consts using an singleton manager instead
	of a "global list" containing the children
ENDREM
Type TProgrammeDataCollection
	Field list:TList			= CreateList()
	Field wearoffFactor:float	= 0.65			'factor by what a programmes topicality DECREASES by sending it
	Field refreshFactor:float	= 1.5			'factor by what a programmes topicality INCREASES by a day switch

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

	const TYPE_UNKNOWN:int				= 1
	const TYPE_EPISODE:int				= 2
	const TYPE_SERIES:int				= 4
	const TYPE_MOVIE:int				= 8

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
		return Max(0, 255 - 2 * Max(0, Game.GetYear() - year) )   'simplest form ;D
	End Method


	Method GetTopicality:int()
		if self.topicality < 0 then self.topicality = GetMaxTopicality()
		return self.topicality
	End Method


	Method GetGenreDefinition:TMovieGenreDefinition()
		Return Game.BroadcastManager.GetMovieGenreDefinition(Genre)
	End Method


	'Diese Methode ersetzt "GetBaseAudienceQuote"
	Method GetQuality:Float() {_exposeToLua}
		Local genreDef:TMovieGenreDefinition = GetGenreDefinition()
		Local quality:Float = 0.0

		If genreDef.OutcomeMod > 0.0 Then
			quality = Float(Outcome) / 255.0 * genreDef.OutcomeMod ..
				+ Float(review) / 255.0 * genreDef.ReviewMod ..
				+ Float(speed) / 255.0 * genreDef.SpeedMod
		Else
			quality = Float(review) / 255.0 * genreDef.ReviewMod ..
				+ Float(speed) / 255.0 * genreDef.SpeedMod
		EndIf

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0, 100 - Max(0, game.GetYear() - year))
		quality:*Max(0.10, (age / 100.0))

		'repetitions wont be watched that much
		quality:*(GetTopicality() / 255.0) ^ 2

		quality = quality * 0.99 + 0.01 'Mindestens 1% Qualitaet

		'no minus quote
		quality = Max(0, quality)
		
		Return quality
	End Method


	Method CutTopicality:Int(cutFactor:float=1.0) {_private}
		'cutFactor can be used to manipulate the resulting cut
		'eg for night times

		'cut of by an individual cutoff factor - do not allow values > 1.0 (refresh instead of cut)
		'the value : default * invidual * individualGenre
		topicality:* Min(1.0,  cutFactor * ProgrammeDataCollection.wearoffFactor * self.GetGenreWearoffModifier() * self.GetWearoffModifier() )
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
		return self.timesAired
	End Method


	Method isReleased:int()
		'call-in shows are kind of "live"
		if genre = GENRE_CALLINSHOW then return TRUE

		return (year <= Game.getYear() and releaseDay <= Game.getDay())
	End Method


	Method isMovie:int()
		return programmeType = TYPE_MOVIE
	End Method


	Method isSeries:int()
		return programmeType = TYPE_SERIES | TYPE_EPISODE
	End Method
End Type




'licence of for movies, series and so on
Type TProgrammeLicence Extends TOwnedGameObject {_exposeToLua="selected"}
	Field title:string			= ""
	Field description:string	= ""
	Field licenceType:int		= 1					'type of that programmelicence
	Field attractiveness:Float	= -1				'Wird nur in der Lua-KI verwendet um die Lizenzen zu bewerten
	Field data:TProgrammeData				{_exposeToLua}
	Field latestPlannedEndHour:int = -1				'the latest hour-(from-start) one of the planned programmes ends
	Field parentLicence:TProgrammeLicence			'series are parent of episodes
	Field subLicences:TProgrammeLicence[]			'other licences this licence covers
	Field cacheTextOverlay:TImage 			{nosave}
	Field cacheTextOverlayMode:string = ""	{nosave}	'for which mode the text was cached

	Global licences:TList		= CreateList()		'holding all programme licences
	Global collections:TList	= CreateList()		'holding only licences of special packages containing multiple movies/series
	Global movies:TList			= CreateList()		'holding only movie licences
	Global series:TList			= CreateList()		'holding only series licences

	Global ignoreUnreleasedProgrammes:int	= TRUE	'hide movies of 2012 when in 1985?
	Global _filterReleaseDateStart:int		= 1900
	Global _filterReleaseDateEnd:int		= 2100

	const TYPE_UNKNOWN:int		= 1
	const TYPE_EPISODE:int		= 2
	const TYPE_SERIES:int		= 4
	const TYPE_MOVIE:int		= 8
	const TYPE_COLLECTION:int	= 16



	Function Create:TProgrammeLicence(title:String, description:String, licenceType:int=1)
		Local obj:TProgrammeLicence =New TProgrammeLicence
		obj.title		= title
		obj.description	= description
		obj.licenceType	= licenceType

		Return obj
	End Function


	'directly connect the licence to a programmeData
	Method AddData:int(data:TProgrammeData)
		self.data = data
		self.licenceType = data.programmeType

		'we got direct content - so add that licence to the global list
		'a) exception are episodes...they have to get fetched through the series head
		'if not isEpisode() and not licences.contains(self) then licences.addLast(self)

		'b) store all licences to enable collections of episodes from multiple series/seasons
		if not licences.contains(self) then licences.addLast(self)

		'only "Movies" are stored separately,
		'episodes are listed in a series which gets added
		'during adding of episodes
		if isMovie()
			'print "AddData: movie " + data.getTitle()
			if not movies.contains(self) then movies.addLast(self)
		endif

		'shouldn't be needed: set type to the one of programmedata
		'data.licenceType = data.programmeType


		return TRUE
	End Method


	Method GetReferenceID:int() {_exposeToLua}
		'return own licence id as referenceID - programme.id is not
		'possible for collections/series
		return self.ID
	End Method


	Method GetData:TProgrammeData() {_exposeToLua}
		'if not self.data then print "[ERROR] data for TProgrammeLicence with title: ~q"+title+"~q is missing."
		return self.data
	End Method


	Method GetSubLicenceCount:int() {_exposeToLua}
		return subLicences.length
	End Method


	Method GetSubLicenceAtIndex:TProgrammeLicence(arrayIndex:int=1) {_exposeToLua}
		if arrayIndex > subLicences.length or arrayIndex < 0 then return null
		return subLicences[arrayIndex]
	End Method


	Method AddSubLicence:int(licence:TProgrammeLicence)
		'only do this if "series" does not have own data...
		'but as they can contain a "general description", we allow it
		'as soon as a licence is connected to a programmeData, adding
		'sublicences is not allowed
		'if self.getData() then return FALSE

		'movies and episodes need "data", without we skip that licence
		if licence.isType(TYPE_MOVIE | TYPE_EPISODE) and not licence.getData() then return FALSE

		'print "AddSubLicence "+self.licenceType+" "+self.getTitle()+"  adding title="+licence.getTitle()

		'if the licence has no special type up to now...
		if licence.isType(TYPE_UNKNOWN)
			'we got content - so add the current licence to the global list
			if not licences.contains(self) then licences.addLast(self)
		endif

		'a series episode is added to a series licence
		'-> has data and is of correct type (checked at begin of method)
		if licence.isType(TYPE_EPISODE)
			'set the current licence to type "series"
			self.licenceType = TYPE_SERIES

			'add series licence as parent for this episode
			licence.parentLicence = self

			'add series if not done yet
			if not series.contains(self) then series.addLast(self)
		endif

		'a series is added to a licence (series-heads do not have data) -> gets a collection
		if licence.isType(TYPE_SERIES) then self.licenceType = TYPE_COLLECTION
		'licence is a movie
		if licence.isType(TYPE_MOVIE) then self.licenceType = TYPE_COLLECTION

		'add collections to their list
		if self.isType(TYPE_MOVIE) and not collections.contains(self) then collections.addLast(self)

		'resize array of sublicences first, then add licence
		subLicences = subLicences[.. subLicences.length+1]
		subLicences[subLicences.length-1] = licence
		Return TRUE
	End Method


	Method isType:int(licenceType:int) {_exposeToLua}
		return (self.licenceType & licenceType)
	End Method

	Method isSeries:int() {_exposeToLua}
		return (self.licenceType & self.TYPE_SERIES)
	End Method

	Method isEpisode:int() {_exposeToLua}
		return (self.licenceType & self.TYPE_EPISODE)
	End Method

	Method isMovie:int() {_exposeToLua}
		return (self.licenceType & self.TYPE_MOVIE)
	End Method

	Method isCollection:int() {_exposeToLua}
		return (self.licenceType & self.TYPE_COLLECTION)
	End Method

	Function setIgnoreUnreleasedProgrammes(ignore:int=TRUE, releaseStart:int=1900, releaseEnd:int=2100)
		ignoreUnreleasedProgrammes = ignore
		_filterReleaseDateStart = releaseStart
		_filterReleaseDateEnd = releaseEnd
	End Function


	'override default method to add sublicences
	Method SetOwner:int(owner:int=0)
		self.owner = owner
		'do the same for all children
		For local licence:TProgrammeLicence = eachin subLicences
			licence.SetOwner(owner)
		Next
		return TRUE
	End Method


	Method Sell:int()
		if not Game.IsPlayer(GetOwner()) then return FALSE

		Game.getPlayer(owner).GetFinance().SellProgrammeLicence(getPrice())
		'set unused again
		SetOwner(0)

		'DebugLog "Programme "+title +" sold"
		return TRUE
	End Method


	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int=-1)
		If playerID = -1 Then playerID = Game.playerID
		if not Game.IsPlayer(playerID) then return FALSE

		If Game.getPlayer(playerID).GetFinance().PayProgrammeLicence(self.getPrice())
			SetOwner(playerID)
			Return TRUE
		EndIf
		Return FALSE
	End Method


	Method GetParentLicence:TProgrammeLicence() {_exposeToLua}
		if not self.parentLicence then return self
		return self.parentLicence
	End Method


	Method GetSubLicencePosition:int(licence:TProgrammeLicence) {_exposeToLua}
		'find my position and add 1
		For local i:int = 0 to GetSubLicenceCount() - 1
			if GetSubLicenceAtIndex(i) = licence then return i
		Next
		return 0
	End Method


	'returns the next licence of a licences parent sublicences
	Method GetNextSubLicence:TProgrammeLicence() {_exposeToLua}
		if not parentLicence then return Null

		'find my position and add 1
		local nextArrayIndex:int = parentLicence.GetSubLicencePosition(self) + 1
		'if we are at the last position, return the first one
		if nextArrayIndex >= parentLicence.GetSubLicenceCount() then nextArrayIndex = 0

		return parentLicence.GetSubLicenceAtIndex(nextArrayIndex)
	End Method


	Method isReleased:int() {_exposeToLua}
		if not self.ignoreUnreleasedProgrammes then return TRUE

		'if connected to a programme - just return our value
		if self.GetData() then return self.GetData().isReleased()

		'if licence is a collection: ask subs
		For local licence:TProgrammeLicence = eachin subLicences
			if not licence.isReleased() then return FALSE
		Next

		return TRUE
	End Method


	'returns the list to use for the given type
	'this is just important for "random" access as we could
	'also just access "progList" in all cases...
	Function _GetList:TList(programmeType:int=0)
		Select programmeType
			case TYPE_MOVIE
				return movies
			case TYPE_SERIES
				return series
			case TYPE_COLLECTION
				return collections
			default
				return licences
		End Select
	End Function

	Function _GetRandomFromList:TProgrammeLicence(_list:TList)

		If _list = Null Then Return Null
		If _list.count() > 0
			Local Licence:TProgrammeLicence = TProgrammeLicence(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If Licence then return Licence
		EndIf
		TDevHelper.log("TProgrammeLicence._GetRandomFromList()", "list is empty (incorrect filter or not enough available licences?)", LOG_DEBUG | LOG_WARNING | LOG_DEV, TRUE)
		Return Null
	End Function


	Function Get:TProgrammeLicence(id:Int, programmeType:int=0)
		local list:TList = _GetList(programmeType)
		local licence:TProgrammeLicence = null

		For Local i:Int = 0 To list.Count() - 1
			Licence = TProgrammeLicence(list.ValueAtIndex(i))
			if Licence and Licence.id = id Then Return Licence
		Next
		Return Null
	End Function


	Function GetRandom:TProgrammeLicence(programmeType:int=0, includeEpisodes:int=FALSE)
		'filter to entries we need
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.owner <> 0 or not Licence.isReleased() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'if available (unbought, released..), add it to candidates list
			resultList.addLast(Licence)
		Next

		Return _GetRandomFromList(resultList)
	End Function


	Function GetRandomWithPrice:TProgrammeLicence(MinPrice:int=0, MaxPrice:Int=-1, programmeType:int=0, includeEpisodes:int=FALSE)
		'filter to entries we need
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.owner <> 0 or not Licence.isReleased() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'skip if to expensive
			if MaxPrice > 0 and Licence.getPrice() > MaxPrice then continue

			'if available (unbought, released..), add it to candidates list
			If Licence.getPrice() >= MinPrice Then resultList.addLast(Licence)
		Next
		Return _GetRandomFromList(resultList)
	End Function


	Function GetRandomWithGenre:TProgrammeLicence(genre:Int=0, programmeType:int=0, includeEpisodes:int=FALSE)
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.owner <> 0 or not Licence.isReleased() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'if available (unbought, released..), add it to candidates list
			If Licence.GetData()
				if Licence.GetData().getGenre() = genre Then resultList.addLast(Licence)
			else
				local foundGenreInSubLicence:int = FALSE
				for local subLicence:TProgrammeLicence = eachin Licence.subLicences
					if foundGenreInSubLicence then continue
					if subLicence.GetData() and subLicence.GetData().getGenre() = genre
						resultList.addLast(Licence)
						foundGenreInSubLicence = TRUE
					endif
				Next
			endif
		Next
		Return _GetRandomFromList(resultList)
	End Function


	Method setPlanned:int(latestHour:int=-1)
		if latestHour >= 0
			'set to maximum
			self.latestPlannedEndHour = Max(latestHour, self.latestPlannedEndHour)
		else
			'reset
			self.latestPlannedEndHour = -1
		endif
	End Method


	'instead of asking the programmeplan about each licence
	'we cache that information directly within the programmeplan
	Method isPlanned:int() {_exposeToLua}
		if self.GetData()
			if (self.latestPlannedEndHour>=0) then return TRUE
			'if self is not planned - ask if parent is set to planned
			'do not use this for series if used in the programmePlanner-view
			'to "emphasize" planned programmes
			'if self.parentLicence then return self.parentLicence.isPlanned()
		endif

		For local licence:TProgrammeLicence = eachin subLicences
			if licence.isPlanned() then return TRUE
		Next
		return FALSE
	End Method


	'returns the genre of a licence - if a group, the one used the most
	'often is returned
	Method GetGenre:int() {_exposeToLua}
		if self.GetData() then return self.GetData().GetGenre()

		local genres:int[]
		local bestGenre:int=0
		For local licence:TProgrammeLicence = eachin subLicences
			local genre:int = licence.GetGenre()
			if genre > genres.length-1 then genres = genres[..genre+1]
			genres[genre]:+1
		Next
		For local i:int = 0 to genres.length-1
			if genres[i] > bestGenre then bestGenre = i
		Next

		return bestGenre
	End Method


	Method GetQuality:Float() {_exposeToLua}
		'licence is connected to a programme
		if GetData() and (isType(TYPE_MOVIE) or isType(TYPE_EPISODE))
			return GetData().GetQuality()
		endif

		'if licence is a collection: ask subs
		local quality:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			quality :+ licence.GetQuality()
		Next

		if subLicences.length > 0 then return quality / subLicences.length
		return 0.0
	End Method


	Method GetTitle:string() {_exposeToLua}
		return self.title
	End Method


	Method GetDescription:string() {_exposeToLua}
		return self.description
	End Method


	'returns the avg topicality of a licence (package)
	Method GetTopicality:Int() {_exposeToLua}
		'licence connected to a single programme
		If GetSubLicenceCount() = 0 then return GetData().GetTopicality()

		'licence for a package or series
		Local value:int
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetTopicality()
		Next
		
		if subLicences.length > 0 then return floor(value / subLicences.length)
		return 0
	End Method	


	Method GetPrice:Int() {_exposeToLua}
		'licence connected to a single programme
		If GetSubLicenceCount() = 0 then return GetData().GetPrice()

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetPrice()
		Next
		value :* 0.75

		Return value
	End Method


	Method CutTrailerEfficiency:float()
		'maximum is 100% efficiency (never shown before)
		local efficiency:float = 1.0
		'each air during the last 24 hrs decreases by 5%

	End Method


	Method ShowSheet:Int(x:Int,y:Int, align:int=0, showMode:int=0)
		'set default mode
		if showMode = 0 then showMode = TBroadcastMaterial.TYPE_PROGRAMME

		if KeyManager.IsDown(KEY_LALT) or KeyManager.IsDown(KEY_RALT)
			if showMode = TBroadcastMaterial.TYPE_PROGRAMME
				showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			else
				showMode = TBroadcastMaterial.TYPE_PROGRAMME
			endif
		Endif


		if showMode = TBroadcastMaterial.TYPE_PROGRAMME
			if isSeries()
				ShowSeriesSheet(x, y, align)
			else
				ShowSingleSheet(x, y, align)
			endif
		'trailermode
		elseif showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			ShowTrailerSheet(x, y, align)
		endif
	End Method


	Method DrawSeriesSheetTextOverlay(x:int, y:int, w:int, h:int)
		'reset cache
		if cacheTextOverlayMode <> "SERIES"
			cacheTextOverlayMode = "SERIES"
			cacheTextOverlay = null
		endif

		'===== CREATE CACHE IF MISSING =====
		if not cacheTextOverlay
			cacheTextOverlay = TFunctions.CreateEmptyImage(w, h)

			'render to image
			TGW_BitmapFont.SetRenderTarget(cacheTextOverlay)

			Local normalFont:TGW_BitmapFont	= Assets.fonts.baseFont
			Local dY:Int = 0

			SetColor 0,0,0
			Assets.fonts.basefontBold.drawBlock(GetTitle(), 10, 11, 278, 20)
			normalFont.drawBlock(self.GetSubLicenceCount()+" "+GetLocale("MOVIE_EPISODES") , 10, 34, 278, 20) 'prints programmedescription on moviesheet
			dy :+ 22

			If data.xrated <> 0 Then normalFont.drawBlock(GetLocale("MOVIE_XRATED") , 240 , dY+34 , 50, 20) 'prints pg-rating

			normalFont.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", 10 , dY+135, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_SPEED")		, 222, dY+187, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_CRITIC")		, 222, dY+210, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_BOXOFFICE")	, 222, dY+233, 280, 16)
			normalFont.drawBlock(data.GetDirectorsString()		, 10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":")) , dY+135, 280-15-normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":"), 16) 	'prints director
			if data.GetActorsString() <> ""
				normalFont.drawBlock(GetLocale("MOVIE_ACTORS")+":", 10 , dY+148, 280, 32)
				normalFont.drawBlock(data.GetActorsString()		, 10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":")), dY+148, 280-15-normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":"), 32) 	'prints actors
			endif
			normalFont.drawBlock(data.GetGenreString()			, 78 , dY+35 , 150, 16) 	'prints genre
			normalFont.drawBlock(data.country					, 10 , dY+35 , 150, 16)		'prints country

			If data.genre <> data.GENRE_CALLINSHOW
				'TODO: add sponsorship display handling here
				normalFont.drawBlock(data.year					, 36 , dY+35 , 150, 16) 	'prints year
				normalFont.drawBlock(data.GetDescription()		, 10,  dy+54 , 282, 71) 'prints programmedescription on moviesheet
			Else
				normalFont.drawBlock(data.GetDescription()		, 10,  dy+54 , 282, 51) 'prints programmedescription on moviesheet
				'convert back cents to euros and round it
				'value is "per 1000" - so multiply with that too
				local revenue:string = int(1000 * data.GetPerViewerRevenue())+" "+CURRENCYSIGN
				normalFont.drawBlock(getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), 10,  dy+106 , 278, 20) 'prints programmedescription on moviesheet
			EndIf

			'set back to screen Rendering
			TGW_BitmapFont.SetRenderTarget(null)
		endif

		'===== DRAW CACHE =====
		DrawImage(cacheTextOverlay, x, y)
	End Method


	Method ShowSeriesSheet:Int(x:Int,y:Int, align:int=0)
		local data:TProgrammeData		= GetData()
		'given in series head too but we want to use the "avg"
		'so we add all episodes data and divide by episodecount -> average
		Local widthbarSpeed:Float			= 0
		Local widthbarReview:Float			= 0
		Local widthbarOutcome:Float			= 0
		Local widthbarTopicality:Float		= 0
		Local widthbarMaxTopicality:Float	= 0

		local episodeCount:float = 0.0
		For local licence:TProgrammeLicence = eachin subLicences
			episodeCount:+1.0
			widthbarSpeed 			:+ licence.GetData().speed
			widthbarReview			:+ licence.GetData().review
			widthbarOutcome			:+ licence.GetData().Outcome
			widthbarTopicality		:+ licence.GetData().topicality
			widthbarMaxTopicality	:+ licence.GetData().GetMaxTopicality()
		Next
		if episodeCount > 0
			widthbarSpeed			= widthbarSpeed / episodeCount / 255.0
			widthbarReview			= widthbarReview / episodeCount / 255.0
			widthbarOutcome			= widthbarOutcome/ episodeCount / 255.0
			widthbarTopicality		= widthbarTopicality / episodeCount / 255.0
			widthbarMaxTopicality	= widthbarMaxTopicality / episodeCount / 255.0
		endif


		local asset:TGW_Sprite = Assets.GetSprite("gfx_datasheets_series")
		if align = 1 then x :- asset.area.GetW()

		'===== DRAW PROGRAMMED HINT =====
		if owner > 0 'and Game.getPlayer().figure.inRoom
			'only if planend and in archive
			if self.IsPlanned() ' and Game.getPlayer().figure.inRoom.name = "archive"
				local warningX:int = x
				local warningY:int = 0
				local warningW:int = 0
				warningY = asset.area.GetH()
				warningW = asset.area.GetW()
				warningY :-15 'minus shadow
				if align = 1 then warningX :- warningW
				SetAlpha 0.5
				SetColor 255,235,110
				DrawRect(warningX+20, y + warningY, warningW-40, 30)
				SetAlpha 0.75
				Assets.fonts.basefontBold.drawBlock("Programm im Sendeplan!", warningX+20, y+warningY+15, warningW-40, 20, TPoint.Create(ALIGN_CENTER), TColor.clWhite, 2, 1, 0.5)
				SetAlpha 1.0
				SetColor 255,255,255
			endif
		endif

		'===== DRAW SHEET BACKGROUND =====
		asset.Draw(x,y)

		'===== DRAW STATIC TEXTS =====
		DrawSeriesSheetTextOverlay(x, y, asset.area.GetW(), asset.area.GetH())

		'===== DRAW DYNAMIC TEXTS =====
		Local normalFont:TGW_BitmapFont	= Assets.fonts.baseFont
		SetColor 0,0,0
		normalFont.drawBlock(GetLocale("MOVIE_TOPICALITY")  , x+84, y+281, 40, 16)
		normalFont.drawBlock(GetLocale("MOVIE_BLOCKS")+": "+data.GetBlocks(), x+10, y+281, 100, 16)
		if Game.getPlayer().getFinance().canAfford(self.getPrice()) OR self.owner = Game.playerID
			normalFont.drawBlock(self.GetPrice(), x+240, y+281, 120, 20)
		else
			normalFont.drawBlock(self.GetPrice(), x+240, y+281, 120, 20, null, TColor.Create(200,0,0))
		endif
		SetColor 255,255,255

		'===== DRAW BARS =====
		If widthbarSpeed   >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13, y+22+188), TRectangle.Create(0, 0, widthbarSpeed*200  , 12))
		If widthbarReview  >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13, y+22+210), TRectangle.Create(0, 0, widthbarReview*200 , 12))
		If widthbarOutcome >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13, y+22+232), TRectangle.Create(0, 0, widthbarOutcome*200, 12))
		SetAlpha 0.3
		If widthbarMaxTopicality>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+115,y+280), TRectangle.Create(0, 0, widthbarMaxTopicality*100, 12))
		SetAlpha 1.0
		If widthbarTopicality>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+115,y+280), TRectangle.Create(0, 0, widthbarTopicality*100, 12))
	End Method


	Method DrawSingleSheetTextOverlay(x:int, y:int, w:int, h:int)
		'reset cache
		if cacheTextOverlayMode <> "SINGLE"
			cacheTextOverlayMode = "SINGLE"
			cacheTextOverlay = null
		endif

		'===== CREATE CACHE IF MISSING =====
		if not cacheTextOverlay
			cacheTextOverlay = TFunctions.CreateEmptyImage(w, h)

			'render to image
			TGW_BitmapFont.SetRenderTarget(cacheTextOverlay)

			Local normalFont:TGW_BitmapFont	= Assets.fonts.baseFont

			If data.xrated <> 0 Then normalFont.drawBlock(GetLocale("MOVIE_XRATED") , 240 , 34 , 50, 20) 'prints pg-rating

			normalFont.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", 10 , 135, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_SPEED")       , 222, 187, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_CRITIC")      , 222, 210, 280, 16)
			normalFont.drawBlock(GetLocale("MOVIE_BOXOFFICE")   , 222, 233, 280, 16)
			normalFont.drawBlock(data.GetDirectorsString()      , 10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":")) , 135, 280-15-normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":"), 16) 	'prints director
			if data.GetActorsString() <> ""
				normalFont.drawBlock(GetLocale("MOVIE_ACTORS")+":"  , 10 , 148, 280, 32)
				normalFont.drawBlock(data.GetActorsString()		, 10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":")), 148, 280-15-normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":"), 32) 	'prints actors
			endif
			normalFont.drawBlock(data.GetGenreString()		, 78 , 35 , 150, 16) 	'prints genre
			normalFont.drawBlock(data.country				, 10 , 35 , 150, 16)		'prints country

			If data.genre <> TProgrammeData.GENRE_CALLINSHOW
				normalFont.drawBlock(data.year				, 36 , 35 , 150, 16) 	'prints year
				normalFont.drawBlock(data.GetDescription()	, 10,  54 , 282, 71) 'prints programmedescription on moviesheet
			Else
				normalFont.drawBlock(data.GetDescription()	, 10,  54 , 282, 51) 'prints programmedescription on moviesheet

				'convert back cents to euros and round it
				'value is "per 1000" - so multiply with that too
				local revenue:string = int(1000 * data.GetPerViewerRevenue())+" "+CURRENCYSIGN
				normalFont.drawBlock(getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), 10,  106 , 278, 20) 'prints programmedescription on moviesheet
			EndIf


			'set back to screen Rendering
			TGW_BitmapFont.SetRenderTarget(null)
		endif

		'===== DRAW CACHE =====
		DrawImage(cacheTextOverlay, x, y)
	End Method


	Method ShowSingleSheet:Int(x:Int,y:Int, align:int=0)
		local data:TProgrammeData		= GetData()
		Local widthbarSpeed:Float		= Float(data.speed / 255.0)
		Local widthbarReview:Float		= Float(data.review / 255.0)
		Local widthbarOutcome:Float		= Float(data.Outcome/ 255.0)
		Local widthbarTopicality:Float	= Float(data.topicality / 255.0)
		Local widthbarMaxTopicality:Float= Float(data.GetMaxTopicality() / 255.0)
		Local normalFont:TGW_BitmapFont	= Assets.fonts.baseFont

		Local dY:Int = 0
		local asset:TGW_Sprite = null
		if data.isMovie()
			asset = Assets.GetSprite("gfx_datasheets_movie")
		else
			asset = Assets.GetSprite("gfx_datasheets_series")
		endif


		if owner > 0 'and Game.getPlayer().figure.inRoom
			'only if planend and in archive
			if self.IsPlanned() ' and Game.getPlayer().figure.inRoom.name = "archive"
				local warningX:int = x
				local warningY:int = asset.area.GetH()
				local warningW:int = asset.area.GetW()
				warningY :-15 'minus shadow
				if align = 1 then warningX :- warningW
				SetAlpha 0.5
				SetColor 255,235,110
				DrawRect(warningX+20, y + warningY, warningW-40, 30)
				SetAlpha 0.75
				Assets.fonts.basefontBold.drawBlock("Programm im Sendeplan!", warningX+20, y+warningY+15, warningW-40, 20, TPoint.Create(ALIGN_CENTER), TColor.clWhite, 2, 1, 0.5)
				SetAlpha 1.0
				SetColor 255,255,255
			endif
		endif

		If data.isMovie()
			if align = 1 then x :- Assets.GetSprite("gfx_datasheets_movie").area.GetW()
			Assets.GetSprite("gfx_datasheets_movie").Draw(x,y)
			SetColor 0,0,0
			Assets.fonts.basefontBold.drawBlock(GetTitle(), x + 10, y + 11, 278, 20)
		Else
			if align = 1 then x :- Assets.GetSprite("gfx_datasheets_series").area.GetW()

			Assets.GetSprite("gfx_datasheets_series").Draw(x,y)
			SetColor 0,0,0
			'episode display
			Assets.fonts.basefontBold.drawBlock(parentLicence.GetTitle(), x + 10, y + 11, 278, 20)
			normalFont.drawBlock("(" + (parentLicence.GetSubLicencePosition(self)+1) + "/" + parentLicence.GetSubLicenceCount() + ") " + data.GetTitle(), x + 10, y + 34, 278, 20)  'prints programmedescription on moviesheet

			dy :+ 22
		EndIf

		'===== DRAW STATIC TEXTS =====
		DrawSingleSheetTextOverlay(x, y + dy, asset.area.GetW(), asset.area.GetH() - dy)

		'===== DRAW DYNAMIC TEXTS =====
		SetColor 0,0,0
		normalFont.drawBlock(GetLocale("MOVIE_TOPICALITY")  , x+84, y+281, 40, 16)
		normalFont.drawBlock(GetLocale("MOVIE_BLOCKS")+": "+data.GetBlocks(), x+10, y+281, 100, 16)
		if Game.getPlayer().getFinance().canAfford(self.getPrice()) OR self.owner = Game.playerID
			normalFont.drawBlock(self.GetPrice(), x+240, y+281, 120, 20)
		else
			normalFont.drawBlock(self.GetPrice(), x+240, y+281, 120, 20, null, TColor.Create(200,0,0))
		endif
		SetColor 255,255,255

		'===== DRAW BARS =====
		If widthbarSpeed   >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13, y+dY+188), TRectangle.Create(0, 0, widthbarSpeed*200  , 12))
		If widthbarReview  >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13, y+dY+210), TRectangle.Create(0, 0, widthbarReview*200 , 12))
		If widthbarOutcome >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13, y+dY+232), TRectangle.Create(0, 0, widthbarOutcome*200, 12))

		SetAlpha 0.3
		If widthbarMaxTopicality>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+115,y+280), TRectangle.Create(0, 0, widthbarMaxTopicality*100, 12))
		SetAlpha 1.0
		If widthbarTopicality>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+115,y+280), TRectangle.Create(0, 0, widthbarTopicality*100, 12))
	End Method


	Method ShowTrailerSheet:Int(x:Int,y:Int, align:int=0)
		Local normalFont:TGW_BitmapFont	= Assets.fonts.baseFont

		if align = 1 then x :- Assets.GetSprite("gfx_datasheets_specials").area.GetW()
		Assets.GetSprite("gfx_datasheets_specials").Draw(x,y)
		SetColor 0,0,0
		Assets.fonts.basefontBold.drawBlock(GetTitle(), x + 10, y + 11, 278, 20)
		normalFont.drawBlock("Programmvorschau / Trailer", x + 10, y + 34, 278, 20)

		normalFont.drawBlock(getLocale("MOVIE_TRAILER")   , x+10, y+55, 278, 60)
		normalFont.drawBlock(GetLocale("MOVIE_TOPICALITY"), x+222, y+131,  40, 16)
		SetColor 255,255,255

		SetAlpha 0.3
		Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13,y+131), TRectangle.Create(0, 0, 200, 12))
		SetAlpha 1.0
		if data.trailerTopicality > 0.1 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13,y+131), TRectangle.Create(0, 0, data.trailerTopicality*200, 12))
	End Method


	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method SetAttractiveness(value:Float) {_exposeToLua}
		Self.attractiveness = value
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method GetPricePerBlock:Int() {_exposeToLua}
		'licence is connected to a programme
		if GetData() then return GetPrice() / GetData().GetBlocks()

		'if licence is a collection: ask subs
		local ppB:int = 0
		local ppBcount:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			ppB:+ licence.GetPricePerBlock()
			ppBcount:+1
		Next
		if ppBcount > 0 then Return ppB/ppBcount
		Return 0
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method GetQualityLevel:Int() {_exposeToLua}
		'licence is connected to a programme
		if GetData()
			Local quality:Int = Self.GetData().GetQuality() * 100
			If quality > 20
				Return 5
			ElseIf quality > 15
				Return 4
			ElseIf quality > 10
				Return 3
			ElseIf quality > 5
				Return 2
			Else
				Return 1
			EndIf
		endif

		'if licence is a collection: ask subs
		local quality:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			quality :+ licence.GetQualityLevel()
		Next

		if subLicences.length > 0 then return quality / subLicences.length
		return 1
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type




'parent of movies, series and so on
Type TProgramme Extends TBroadcastMaterial {_exposeToLua="selected"}
	Field licence:TProgrammeLicence			{_exposeToLua}
	Field data:TProgrammeData				{_exposeToLua}	

	Function Create:TProgramme(licence:TProgrammeLicence)
		Local obj:TProgramme = New TProgramme
		obj.licence = licence

		obj.owner = licence.owner
		obj.data = licence.getData()

		obj.setMaterialType(TYPE_PROGRAMME)
		'by default a freshly created programme is of its own type
		obj.setUsedAsType(TYPE_PROGRAMME)

		'someone just gave collection or series header
		if not obj.data then return Null

		Return obj
	End Function

	Method CheckHourlyBroadcastingRevenue:int()
		'callin-shows earn for each sent block... so BREAKs and FINISHs
		'same for "sponsored" programmes
		if self.usedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			'fetch the rounded revenue for broadcasting this programme
			Local revenue:Int = Game.getPlayer(owner).GetAudience() * Max(0, data.GetPerViewerRevenue())

			if revenue > 0
				'earn revenue for callin-shows
				If data.GetGenre() = TProgrammeData.GENRE_CALLINSHOW
					Game.getPlayer(owner).GetFinance().EarnCallerRevenue(revenue)
				'all others programmes get "sponsored"
				Else
					Game.getPlayer(owner).GetFinance().EarnSponsorshipRevenue(revenue)
				EndIf
			endif
		endif
	End Method

	'override
	Method FinishBroadcasting:int(day:int, hour:int, minute:int)
		Super.FinishBroadcasting(day, hour, minute)

		If not Game.GetPlayer(self.owner) then return FALSE

		if self.usedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			self.FinishBroadcastingAsProgramme(day, hour, minute)
		elseif self.usedAsType = TBroadcastMaterial.TYPE_ADVERTISEMENT
			self.FinishBroadcastingAsTrailer(day, hour, minute)
		endif

		'refresh planned state - for next hour
		if owner > 0 and Game.getPlayer(owner)
			Game.getPlayer(owner).ProgrammePlan.RecalculatePlannedProgramme(self, -1, hour+1)
		endif

		return TRUE
	End Method


	'override
	Method BreakBroadcasting:int(day:int, hour:int, minute:int)
		Super.BreakBroadcasting:int(day, hour, minute)

		'check if revenues have to get paid (call-in-shows, sponsorships)
		CheckHourlyBroadcastingRevenue()
	End Method


	Method FinishBroadcastingAsTrailer:int(day:int, hour:int, minute:int)
		'does the trailer finish now?
		if Game.GetPlayer(self.owner).ProgrammePlan.GetAdvertisementBlock(day, hour) = GetBlocks()
			self.SetState(self.STATE_OK)
			data.CutTrailerTopicality(GetTrailerTopicalityCutToFactor())
			data.trailerAired:+1
			data.trailerAiredSinceShown:+1
		endif
	End Method


	Method FinishBroadcastingAsProgramme:int(day:int, hour:int, minute:int)
		self.SetState(self.STATE_OK)

		'check if revenues have to get paid (call-in-shows, sponsorships)
		CheckHourlyBroadcastingRevenue()

		'adjust trend/popularity
		Local popularity:TGenrePopularity = data.GetGenreDefinition().Popularity
		popularity.FinishBroadcastingProgramme(Game.getPlayer(owner).audience, GetBlocks())

		'adjust topicality
		data.CutTopicality(GetTopicalityCutModifier())

		'if someone can watch that movie, increase the aired amount
		data.timesAired:+1
		'reset trailer count
		data.trailerAiredSinceShown = 0
		'now the trailer is for the next broadcast...
		data.trailerTopicality = 1.0
		'print "aired programme "+GetTitle()+" "+data.timesAired+"x."
	End Method


	Method GetQuality:Float() {_exposeToLua}
		return data.GetQuality()
	End Method


	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction )
		Local result:TAudienceAttraction = New TAudienceAttraction
		result.BroadcastType = 1
		result.Genre = licence.GetGenre()
		Local genreDefintion:TMovieGenreDefinition = Game.BroadcastManager.GetMovieGenreDefinition(result.Genre)
		
		If block = 1 Then											
			'1 - Qualität des Programms
			result.Quality = GetQuality()
			
			'2 - Mod: Genre-Popularität / Trend			
			result.GenrePopularityMod = (genreDefintion.Popularity.Popularity / 100) 'Popularity => Wert zwischen -50 und +50
			
			'3 - Genre <> Zielgruppe
			result.GenreTargetGroupMod = genreDefintion.AudienceAttraction.Copy()
			result.GenreTargetGroupMod.SubtractFloat(0.5)
			
			'4 - Image
			result.PublicImageMod = Game.getPlayer(owner).PublicImage.GetAttractionMods()
			result.PublicImageMod.SubtractFloat(1)
			
			'5 - Trailer
			result.TrailerMod = data.GetTrailerMod()
			result.TrailerMod.SubtractFloat(1)
				
			'6 - Flags
			result.FlagsMod = TAudience.CreateAndInit(1, 1, 1, 1, 1, 1, 1, 1, 1)
			result.FlagsMod.SubtractFloat(1)
			
			result.CalculateBaseAttraction()			
			
			rem
			'7 - Audience Flow
			'TODO: AudienceFlow muss sich anpassen... ein fixer Bonus über Stunden hinweg ist nicht gut... eventuell einen Teilschritt sogar zurück zu exklusiven Zuschauern.
			If lastMovieBlockAttraction Then
				Local lastGenreDefintion:TMovieGenreDefinition = Game.BroadcastManager.GetMovieGenreDefinition(lastMovieBlockAttraction.Genre)
				Local audienceFlowMod:TAudience = lastGenreDefintion.GetAudienceFlowMod(result.Genre, result.BaseAttraction)
						
				result.AudienceFlowBonus = lastMovieBlockAttraction.Copy()
				result.AudienceFlowBonus.Multiply(audienceFlowMod)
			Else
				result.AudienceFlowBonus = lastNewsBlockAttraction.Copy()
				result.AudienceFlowBonus.MultiplyFloat(0.2)				
			End If	
			endrem
			'result.CalculateBroadcastAttraction()
		Else
			result.CopyBaseAttractionFrom(lastMovieBlockAttraction)
		Endif
		
		'8 - Stetige Auswirkungen der Film-Quali. Gute Filme bekommen mehr Attraktivität, schlechte Filme animieren eher zum Umschalten	
		result.QualityOverTimeEffectMod = ((result.Quality - 0.5)/2.5) * (block - 1)
		
		'9 - Genres <> Sendezeit
		result.GenreTimeMod = genreDefintion.TimeMods[hour] - 1 'Genre/Zeit-Mod
		
		'10 - News-Mod
		'result.NewsShowBonus = lastNewsBlockAttraction.BaseAttraction.Copy().DivideFloat(2).SubtractFloat(0.1)
		result.NewsShowBonus = lastNewsBlockAttraction.Copy().MultiplyFloat(0.2)
		
		result.CalculateBlockAttraction()			
		
		'Sequence
		'If (Game.playerID = 1) Then DebugStop
		
		result.SequenceEffect = TGenreDefinitionBase.GetSequence(lastNewsBlockAttraction, result, 0.1, 0.5)
		
		result.CalculateFinalAttraction()
		
		result.CalculatePublicImageAttraction()
		
		Return result
	End Method
	



	Method GetTopicalityCutModifier:float(hour:int=-1) {_exposeToLua}
		if hour = -1 then hour = Game.getNextHour()
		'during nighttimes 0-5, the cut should be lower
		'so we increase the cutFactor to 1.5
		if hour-1 <= 5
			return 1.5
		elseif hour-1 <= 12
			return 1.25
		else
			return 1.0
		endif
	End Method


	Method GetTrailerTopicalityCutToFactor:float(hour:int=-1) {_exposeToLua}
		if hour = -1 then hour = Game.getNextHour()
		'during nighttimes 0-5, the cut should be lower
		'so we increase the cutFactor to 1.5
		if hour-1 <= 5
			return 0.99
		elseif hour-1 <= 12
			return 0.95
		else
			return 0.90
		endif
	End Method


	'override default to use blocksamount of programme instead
	Method GetBlocks:int(broadcastType:int=0) {_exposeToLua}
		'nothing special requested? use the currently used type
		if broadcastType = 0 then broadcastType = usedAsType
		if broadcastType & TBroadcastMaterial.TYPE_PROGRAMME
			Return data.GetBlocks()
		'trailers are 1 block long
		elseif broadcastType & TBroadcastMaterial.TYPE_ADVERTISEMENT
			return 1
		endif

		return data.GetBlocks()
	End Method


	'override default getter
	Method GetDescription:string() {_exposeToLua}
		Return data.GetDescription()
	End Method


	'get the title
	Method GetTitle:string() {_exposeToLua}
		Return data.GetTitle()
	End Method


	'override default
	Method GetReferenceID:int() {_exposeToLua}
		return licence.GetReferenceID()
	End Method


	Method GetEpisodeNumber:int() {_exposeToLua}
		if not licence.parentLicence then return 1
		return licence.parentLicence.GetSubLicencePosition(licence)
	End Method


	Method GetEpisodeCount:int() {_exposeToLua}
		if not licence.parentLicence then return 1
		return licence.parentLicence.GetSubLicenceCount()
	End Method


	Method IsSeries:int()
		return self.licence.isEpisode()
	End Method


	Method ShowSheet:int(x:int,y:int,align:int)
		self.licence.ShowSheet(x,y,align, self.usedAsType)
	End Method
	
	Method GetGenreDefinition:TGenreDefinitionBase()
		Return Game.BroadcastManager.GetMovieGenreDefinition(licence.GetGenre())
	End Method
End Type




Type TGUIProgrammeLicenceSlotList extends TGUISlotList
	field  acceptType:int		= 0	'accept all
	Global acceptAll:int		= 0
	Global acceptMovies:int		= 1
	Global acceptSeries:int		= 2

    Method Create:TGUIProgrammeLicenceSlotList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)

		'albeit the list base already handles drop on itself
		'we want to intercept too -- to stop dropping if not
		'enough money is available
		'---alternatively we could intercept programmeblocks-drag-event
		'EventManager.registerListenerFunction( "guiobject.onDropOnTarget", self.onDropOnTarget, accept, self)

		return self
	End Method

	Method ContainsLicence:int(licence:TProgrammeLicence)
		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGUIProgrammeLicence = TGUIProgrammeLicence(self.GetItemBySlot(i))
			if block and block.licence = licence then return TRUE
		Next
		return FALSE
	End Method

	'overriden Method: so it does not accept a certain
	'kind of programme (movies - series)
	Method AddItem:int(item:TGUIobject, extra:object=null)
		local coverBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(item)
		if not coverBlock then return FALSE

		'something odd happened - no licence
		if not coverBlock.licence then return FALSE

		if acceptType > 0
			'movies and series do not accept collections or episodes
			if coverBlock.licence.GetData()
				if acceptType = acceptMovies and coverBlock.licence.GetData().isSeries() then return FALSE
				if acceptType = acceptSeries and coverBlock.licence.GetData().isMovie() then return FALSE
			else
				return FALSE
			endif
		endif

		if super.AddItem(item,extra)
			'print "added an item ... slot state:" + self.GetUnusedSlotAmount()+"/"+self.GetSlotAmount()
			return true
		endif

		return FALSE
	End Method

End Type




'a graphical representation of programmes to buy/sell/archive...
Type TGUIProgrammeLicence extends TGUIGameListItem
	Field licence:TProgrammeLicence
	Field isAffordable:int = TRUE

rem

	'programmeblock
	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i
		DragAndDrop.typ = "programmeblock"
		DragAndDrop.pos.setXY( 394, 17 + i * Assets.GetSprite("pp_programmeblock1").h )
		DragAndDrop.w = Assets.GetSprite("pp_programmeblock1").w
		DragAndDrop.h = Assets.GetSprite("pp_programmeblock1").h
		If Not TProgrammeBlock.DragAndDropList Then TProgrammeBlock.DragAndDropList = CreateList()
		TProgrammeBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TProgrammeBlock.DragAndDropList
	Next

	For i = 0 To 11
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
		DragAndDrop.slot = i+11
		DragAndDrop.typ = "programmeblock"
		DragAndDrop.pos.setXY( 67, 17 + i * Assets.GetSprite("pp_programmeblock1").h )
		DragAndDrop.w = Assets.GetSprite("pp_programmeblock1").w
		DragAndDrop.h = Assets.GetSprite("pp_programmeblock1").h
		If Not TProgrammeBlock.DragAndDropList Then TProgrammeBlock.DragAndDropList = CreateList()
		TProgrammeBlock.DragAndDropList.AddLast(DragAndDrop)
		SortList TProgrammeBlock.DragAndDropList
	Next
endrem


    Method Create:TGUIProgrammeLicence(label:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		Super.Create(label,x,y,width,height)
		return self
	End Method


	Method CreateWithLicence:TGUIProgrammeLicence(licence:TProgrammeLicence)
		self.Create()
		self.setProgrammeLicence(licence)
		return self
	End Method


	Method SetProgrammeLicence:TGUIProgrammeLicence(licence:TProgrammeLicence)
		self.licence = licence

		local genre:int = Min(15, Max(0,licence.GetGenre()))

		'if it is a collection or series
		if not licence.GetData()
			if licence.licenceType = licence.TYPE_COLLECTION
				self.InitAssets("gfx_movie" + genre, "gfx_movie" + genre + "_dragged")
			elseif licence.licenceType = licence.TYPE_SERIES
				self.InitAssets("gfx_serie" + genre, "gfx_serie" + genre + "_dragged")
			endif
		else
			self.InitAssets("gfx_movie" + genre, "gfx_movie" + genre + "_dragged")
		endif

		return self
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		self.isAffordable = Game.getPlayer().getFinance().canAfford(licence.getPrice())


		if licence.owner = Game.playerID or (licence.owner <= 0 and self.isAffordable)
			'change cursor to if mouse over item or dragged
			if self.mouseover then Game.cursorstate = 1
		endif
		'ignore affordability if dragged...
		if isDragged() then Game.cursorstate = 2
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30)
'		self.parentBlock.DrawSheet()
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0
		'if mouse on left side of screen - align sheet on right side
		if MouseManager.x < App.settings.GetWidth()/2
			sheetX = App.settings.GetWidth() - rightX
			sheetAlign = 1
		endif

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		self.licence.ShowSheet(sheetX,sheetY, sheetAlign, TBroadcastMaterial.TYPE_PROGRAMME)
	End Method


	Method Draw()
		SetColor 255,255,255

		'make faded as soon as not "dragable" for us
		if licence.owner <> Game.playerID and (licence.owner<=0 and not isAffordable) then SetAlpha 0.75
		Super.Draw()
		SetAlpha 1.0
	End Method
End Type

