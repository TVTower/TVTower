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
Import "game.gameconstants.bmx"


Type TProgrammeDataCollection Extends TGameObjectCollection

	'factor by what a programmes topicality DECREASES by sending it
	Field wearoffFactor:float = 0.65
	'factor by what a programmes topicality INCREASES by a day switch
	Field refreshFactor:float = 1.5
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


	Method Initialize:TProgrammeDataCollection()
		Super.Initialize()
		return self
	End Method


	Method GetByGUID:TProgrammeData(GUID:String)
		Return TProgrammeData( Super.GetByGUID(GUID) )
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


	Method RefreshTopicalities:int()
		For Local data:TProgrammeData = eachin entries.Values()
			data.RefreshTopicality()
			data.RefreshTrailerTopicality()
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeDataCollection:TProgrammeDataCollection()
	Return TProgrammeDataCollection.GetInstance()
End Function





'raw data for movies, epidodes (series)
'but also series-headers, collection-headers,...
Type TProgrammeData extends TGameObject {_exposeToLua}
	Field originalTitle:TLocalizedString
	Field title:TLocalizedString
	Field description:TLocalizedString
	'array holding actor(s) and director(s) and ...
	Field cast:TProgrammePersonJob[]
	Field country:String = "UNK"
	Field year:Int = 1900
	'special targeted audiences?
	Field targetGroups:int = 0
	Field proPressureGroups:int = 0
	Field contraPressureGroups:int = 0
	Field liveHour:Int = -1
	Field outcome:Float	= 0
	Field review:Float = 0
	Field speed:Float = 0
	Field genre:Int	= 0
	Field subGenres:Int[]
	Field blocks:Int = 1
	'guid of a potential franchise entry
	Field franchiseGUID:string
	'id of the creating user
	Field creator:Int = 0
	'name of the creating user
	Field createdBy:String = ""
	Rem
	extra data block containing various information (if set)
	"maxTopicality::ageInfluence" - influence of the age on the max topicality
	oder nur
	"maxTopicality"

	"price"
	"wearoff" - changes how much a programme loses during sending it
	"refresh" - changes how much a programme "regenerates" (multiplied with genreModifier)
	endrem
	Field modifiers:TData = new TData
	
	'flags contains bitwise encoded things like xRated, paid, trash ...
	Field flags:Int = 0
	'which kind of distribution was used? Cinema, Custom production ...
	Field distributionChannel:int = 0
	'ID according to TVTProgrammeProductType
	Field productType:Int = 1
	'at which day was the programme released?
	Field releaseDay:Int = 1
	'announced in news etc?
	Field releaseAnnounced:int = FALSE
	'how many times that programme was run
	'(per player, 0 = unknown - eg before "game start" to lower values)
	Field timesAired:int[] = [0]
	'how "attractive" a programme is (the more shown, the less this value)
	Field topicality:Float = -1
	'programmes descending from this programme (eg. "Lord of the Rings"
	'as "franchise" and the individual programmes as "franchisees"
	Field franchisees:string[] {nosave}

	'=== trailer data ===
	Field trailerTopicality:float = 1.0
	Field trailerMaxTopicality:float = 1.0
	'times the trailer aired
	Field trailerAired:int = 0
	'times the trailer aired since the programme was shown "normal"
	Field trailerAiredSinceShown:int = 0

	Field cachedActors:TProgrammePersonBase[] {nosave}
	Field cachedDirectors:TProgrammePersonBase[] {nosave}
	Field genreDefinitionCache:TMovieGenreDefinition = Null {nosave}



	Function Create:TProgrammeData(GUID:String, title:TLocalizedString, description:TLocalizedString, cast:TProgrammePersonJob[], country:String, year:Int, day:int=0, livehour:Int, Outcome:Float, review:Float, speed:Float, modifiers:TData, Genre:Int, blocks:Int, xrated:Int, productType:Int=1) {_private}
		Local obj:TProgrammeData = New TProgrammeData
		obj.SetGUID(GUID)
		obj.title       = title
		obj.description = description
		obj.productType = productType
		obj.review      = Max(0,Min(1.0, review))
		obj.speed       = Max(0,Min(1.0, speed))
		obj.outcome     = Max(0,Min(1.0, Outcome))
		'modificators: > 1.0 increases price (1.0 = 100%)
		if modifiers then obj.modifiers = modifiers.Copy()
		obj.genre       = Max(0,Genre)
		obj.blocks      = blocks
		obj.SetFlag(TVTProgrammeFlag.XRATED, xrated)
		obj.country     = country
		obj.cast        = cast
		obj.year        = year
		obj.releaseDay  = day
		obj.liveHour    = Max(-1,livehour)
		obj.topicality  = obj.GetTopicality()
		GetProgrammeDataCollection().Add(obj)

		Return obj
	End Function


	Method hasFlag:Int(flag:Int) {_exposeToLua}
		Return flags & flag
	End Method


	Method setFlag(flag:Int, enable:Int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method


	'what to earn for each viewer
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		local result:float = 0.0
		If HasFlag(TVTProgrammeFlag.PAID)
			'leads to a maximum of "0.25 * (20+10)" if speed/review
			'reached 100%
			'-> 8 Euro per Viewer
			result :+ GetSpeed() * 22
			result :+ GetReview() * 10
			'cut to 25%
			result :* 0.25
			'adjust by topicality
			result :* (GetTopicality()/GetMaxTopicality())
		Else
			'by default no programme has a sponsorship
			result = 0.0
			'TODO: include sponsorships
		Endif
		return result
	End Method


	Method AddCast:int(job:TProgrammePersonJob)
		if HasCast(job) then return False

		cast :+ [job]
		
		'invalidate caches
		cachedActors = cachedActors[..0]
		cachedDirectors = cachedDirectors[..0]
		return True 
	End Method


	Method RemoveCast:int(job:TProgrammePersonJob)
		if not HasCast(job) then return False
		if cast.Length = 0 then return False

		local newCast:TProgrammePersonJob[]
		for local j:TProgrammePersonJob = EachIn cast
			'skip our job
			if job.person = j.person and job.job = j.job then continue
			'add rest
			newCast :+ [j]
		Next
		cast = newCast
		return True
	End Method


	Method HasCast:int(job:TProgrammePersonJob)
		'do not check job against jobs in the list, as only the
		'content might be the same but the job a duplicate
		For local doneJob:TProgrammePersonJob = EachIn cast
			if job.person <> doneJob.person then continue 
			if job.job <> doneJob.job then continue 
			if job.roleGUID <> doneJob.roleGUID then continue

			return True
		Next
		return False
	End Method


	Method GetCast:TProgrammePersonJob[]()
		return cast
	End Method


	Method GetCastAtIndex:TProgrammePersonJob(index:int=0)
		if index < 0 or index >= cast.length then return null
		return cast[index]
	End Method


	Method GetCastGroup:TProgrammePersonBase[](jobFlag:int)
		local res:TProgrammePersonBase[0]
		For local job:TProgrammePersonJob = EachIn cast
			if job.job = jobFlag then res :+ [job.person]
		Next
		return res
	End Method
	

	Method GetCastGroupString:string(jobFlag:int)
		local result:string = ""
		local group:TProgrammePersonBase[] = GetCastGroup(jobFlag)
		for local i:int = 0 to group.length-1
			if result <> "" then result:+ ", "
			result:+ group[i].GetFullName()
		Next
		return result
	End Method


	Method GetActors:TProgrammePersonBase[]()
		if cachedActors.length = 0
			For local job:TProgrammePersonJob = EachIn cast
				if job.job = TVTProgrammePersonJob.ACTOR then cachedActors :+ [job.person]
			Next
		endif
		
		return cachedActors
	End Method


	Method GetDirectors:TProgrammePersonBase[]()
		if cachedDirectors.length = 0
			For local job:TProgrammePersonJob = EachIn cast
				if job.job = TVTProgrammePersonJob.DIRECTOR then cachedDirectors :+ [job.person]
			Next
		endif
		
		return cachedDirectors
	End Method


	'1 based
	Method GetActor:TProgrammePersonBase(number:int=1)
		'generate if needed
		GetActors()

		number = Min(cachedActors.length, Max(1, number))
		if number = 0 then return null
		return cachedActors[number-1]
	End Method


	Method GetActorsString:string()
		local result:string = ""
		'generate if needed
		GetActors()

		for local i:int = 0 to cachedActors.length-1
			if result <> "" then result:+ ", "
			result:+ cachedActors[i].GetFullName()
		Next
		return result
	End Method


	'1 based
	Method GetDirector:TProgrammePersonBase(number:int=1)
		'generate if needed
		GetDirectors()

		number = Min(cachedDirectors.length, Max(1, number))
		if number = 0 then return null
		return cachedDirectors[number-1]
	End Method


	Method GetDirectorsString:string()
		local result:string = ""
		'generate if needed
		GetDirectors()

		for local i:int = 0 to cachedDirectors.length-1
			if result <> "" then result:+ ", "
			result:+ cachedDirectors[i].GetFullName()
		Next
		return result
	End Method


	Method HasFranchisee:int(programme:TProgrammeData)
		if not programme then return False

		For local g:string = EachIn franchisees
			if g = programme.GetGUID() then return True
		Next

		return False
	End Method

	
	Method AddFranchisee(programme:TProgrammeData)
		if HasFranchisee(programme) then return
		 
		programme.franchiseGUID = self.GetGUID()
		franchisees :+ [programme.GetGUID()]
	End Method


	Method RemoveFranchisee(programme:TProgrammeData)
		if not HasFranchisee(programme) then return

		programme.franchiseGUID = ""

		local newFranchisees:string[]
		For local g:String = EachIn franchisees
			if g = programme.GetGUID() then continue

			newFranchisees :+ [g]
		Next
		franchisees = newFranchisees
	End Method


	Method GetFranchisees:string[]()
		return franchisees
	End Method


	Method SetFranchiseByGUID( newFranchiseGUID:String )
		'remove old
		if franchiseGUID
			local oldF:TProgrammeData = GetProgrammeDataCollection().GetByGUID(franchiseGUID)
			if oldF then oldF.RemoveFranchisee(self)
		endif

		if newFranchiseGUID
			local newF:TProgrammeData = GetProgrammeDataCollection().GetByGUID(newFranchiseGUID)
			if newF then newF.AddFranchisee(self)
		endif
	End Method


	Method GetRefreshModifier:float()
		return GetModifier("topicality::refresh")
	End Method


	Method GetWearoffModifier:float()
		return GetModifier("topicality::wearoff")
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
		If _genre < 0 Then _genre = self.genre
		'eg. PROGRAMME_GENRE_ACTION
		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(_genre))
	End Method


	Method GetFlagsString:String(delimiter:string=" / ")
		local result:String = ""
		'checkspecific
		local checkFlags:int[] = [TVTProgrammeFlag.LIVE, TVTProgrammeFlag.PAID]

		'checkall
		'local checkFlags:int[]
		'for local i:int = 0 to 10 '1-1024 
		'	checkFlags :+ [2^i]
		'next

		for local i:int = eachin checkFlags
			if flags & i > 0
				if result <> "" then result :+ delimiter
				result :+ GetLocale("PROGRAMME_FLAG_" + TVTProgrammeFlag.GetAsString(i))
			endif
		Next

		return result
	End Method


	Method _LocalizeContent:string(content:string)
		local result:string = content

		'placeholders are: "%object|guid|whatinformation%"
		local placeHolders:string[] = StringHelper.ExtractPlaceholders(content, "%")
		For local placeHolder:string = EachIn placeHolders
			local elements:string[] = placeHolder.split("|")
			if elements.length < 3 then continue

			if elements[0] = "person"
				local person:TProgrammePersonBase = GetProgrammePersonCollection().GetByGUID(elements[1])
				if not person
					result = result.replace("%person|"+elements[1]+"|Full%", "John Doe")
					result = result.replace("%person|"+elements[1]+"|First%", "John")
					result = result.replace("%person|"+elements[1]+"|Nick%", "John")
					result = result.replace("%person|"+elements[1]+"|Last%", "Doe")
				else
					result = result.replace("%person|"+elements[1]+"|Full%", person.GetFullName())
					result = result.replace("%person|"+elements[1]+"|First%", person.GetFirstName())
					result = result.replace("%person|"+elements[1]+"|Nick%", person.GetNickName())
					result = result.replace("%person|"+elements[1]+"|Last%", person.GetLastName())
				endif
			endif
		Next

		if result.find("|") >= 0
			if result.find("[") >= 0
				local job:TProgrammePersonJob
				'check for cast
				for local i:int = 0 to 5
					job = GetCastAtIndex(i)
					if not job
						result = result.replace("["+i+"|Full]", "John Doe")
						result = result.replace("["+i+"|First]", "John")
						result = result.replace("["+i+"|Nick]", "John")
						result = result.replace("["+i+"|Last]", "Doe")
					else
						result = result.replace("["+i+"|Full]", job.person.GetFullName())
						result = result.replace("["+i+"|First]", job.person.GetFirstName())
						result = result.replace("["+i+"|Nick]", job.person.GetNickName())
						result = result.replace("["+i+"|Last]", job.person.GetLastName())
					endif
				Next
			endif
			'replace left "|" entries with newlines
			'TODO: remove when fixed in DB
			result = result.replace("|", chr(13))
		endif
		
		return result
	End Method


	Method GetTitle:string()
		if title
			'cache the now processed result
			title.Set( _LocalizeContent(title.Get()) )
			return title.Get()
		endif
		return ""
	End Method


	Method GetOriginalTitle:string()
		if originalTitle
			'cache the now processed result
			originalTitle.Set( _LocalizeContent(originalTitle.Get()) )
			return originalTitle.Get()
		endif
		return ""
	End Method


	Method GetDescription:string()
		if description
			'cache the now processed result
			description.Set( _LocalizeContent(description.Get()) )
			return description.Get()
		endif
		return ""
	End Method


	'returns the stored value for a modifier - defaults to "100%"
	Method GetModifier:Float(modifierKey:string, defaultValue:Float = 1.0)
		return modifiers.GetFloat(modifierKey, defaultValue)
	End Method


	'stores a modifier value
	Method SetModifier:int(modifierKey:string, value:Float)
		'skip adding the modifier if it is the same - or a default value
		'-> keeps datasets smaller
		if GetModifier(modifierKey) = value then return False
		
		modifiers.AddNumber(modifierKey, value)
		return True
	End Method

	
	Method IsLive:int()
		return HasFlag(TVTProgrammeFlag.LIVE)
	End Method
	
	
	Method IsAnimation:Int()
		return HasFlag(TVTProgrammeFlag.ANIMATION)
	End Method
	
	
	Method IsCulture:Int()
		return HasFlag(TVTProgrammeFlag.CULTURE)
	End Method	
		
	
	Method IsCult:Int()
		return HasFlag(TVTProgrammeFlag.CULT)
	End Method
	
	
	Method IsTrash:Int()
		return HasFlag(TVTProgrammeFlag.TRASH)
	End Method
	
	Method IsBMovie:Int()
		return HasFlag(TVTProgrammeFlag.BMOVIE)
	End Method
	
	
	Method IsXRated:int()
		return HasFlag(TVTProgrammeFlag.XRATED)
	End Method


	Method IsPaid:int()
		return HasFlag(TVTProgrammeFlag.PAID)
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
		'basefactor * topicalityModifier * GetModifier("price")

		'movies run in cinema (outcome >0)
		If isType(TVTProgrammeProductType.MOVIE) and GetOutcome() > 0
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

		Rem
		'individual price modifier - default is 1.0
		'until we revisited the database, it only has a 20% influence
		'value :* (0.8 + 0.2 * GetModifier("price"))
		End Rem
		value :* GetModifier("price")

		
		If Self.IsBMovie()
			value :* 0.3
		End If
			
		'round to next "1000" block
		value = Int(Floor(value / 1000) * 1000)

'print GetTitle()+"  value1: "+value + "  outcome:"+GetOutcome()+"  review:"+GetReview() + " maxTop:"+GetMaxTopicality()+" year:"+year

		return value
	End Method


	Method GetMaxTopicality:Float()
		Local age:Int = Max(0, GetWorldTime().GetYear() - year)
		Local timeAired:Int = Min(40, GetTimesAired() * 4)

		'modifiers could increase or decrease influences of age/aired/...
		local ageInfluence:Float = age * GetModifier("topicality::age")
		local timeAiredInfluence:Float = timeAired * GetModifier("topicality::aired")
		
		If Self.IsCult() 'Bei Kult-Filmen ist der Nachteil des Filmalters und der Anzahl der Ausstrahlungen deutlich verringert.
			If age >= 20
				return 0.01 * Max(10, 80 - Max(40, (ageInfluence - 20) * 0.5) - timeAiredInfluence * 0.5)
			Else
				return 0.01 * Max(10, 100 - ageInfluence - timeAiredInfluence * 0.5)
			Endif
		Else
			return 0.01 * Max(1, 100 - ageInfluence - timeAiredInfluence)
		EndIf
	End Method


	Method GetTopicality:Float()
		if topicality < 0 then topicality = GetMaxTopicality()

		'refresh topicality on each request
		'-> avoids a "topicality > MaxTopicality" when MaxTopicality
		'   shrinks because of aging/airing
		topicality = Min(topicality, GetMaxTopicality())
		
		return topicality
	End Method


	Method GetGenreDefinition:TMovieGenreDefinition()
		If Not genreDefinitionCache Then
			genreDefinitionCache = GetMovieGenreDefinitionCollection().Get(Genre)

			If Not genreDefinitionCache
				TLogger.Log("GetGenreDefinition()", "Programme ~q"+GetTitle()+"~q: Genre #"+Genre+" misses a genreDefinition. Creating BASIC definition-", LOG_ERROR)
				genreDefinitionCache = new TMovieGenreDefinition.InitBasic(Genre)
			EndIf
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
		Local age:Float = 0.01 * Max(0, 100 - Max(0, GetWorldTime().GetYear() - year))
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


	Method GetTargetGroups:int()
		return targetGroups
	End Method


	Method HasTargetGroup:Int(group:Int) {_exposeToLua}
		Return targetGroups & group
	End Method


	Method SetTargetGroup:int(group:int, enable:int=True)
		If enable
			targetGroups :| group
		Else
			targetGroups :& ~group
		EndIf
	End Method


	Method GetProPressureGroups:int()
		return proPressureGroups
	End Method


	Method HasProPressureGroup:Int(group:Int) {_exposeToLua}
		Return proPressureGroups & group
	End Method


	Method SetProPressureGroup:int(group:int, enable:int=True)
		If enable
			proPressureGroups :| group
		Else
			proPressureGroups :& ~group
		EndIf
	End Method


	Method GetContraPressureGroups:int()
		return contraPressureGroups
	End Method


	Method HasContraPressureGroup:Int(group:Int) {_exposeToLua}
		Return contraPressureGroups & group
	End Method


	Method SetContraPressureGroup:int(group:int, enable:int=True)
		If enable
			contraPressureGroups :| group
		Else
			contraPressureGroups :& ~group
		EndIf
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

		Return TAudience.CreateAndInitValue(trailerMod)
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
		if HasFlag(TVTProgrammeFlag.PAID) then return True

		return (year <= GetWorldTime().getYear() and releaseDay <= GetWorldTime().getDay())
	End Method


	Method isType:int(typeID:int)
		return (productType & typeID)
	End Method	
End Type




