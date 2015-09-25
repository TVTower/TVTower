REM
	===========================================================
	code for programme-objects (movies, ..) in programme planning
	===========================================================
ENDREM
SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.world.worldtime.bmx"
Import "game.programme.programmeperson.base.bmx"
Import "game.broadcast.genredefinition.movie.bmx"
Import "game.broadcastmaterialsource.base.bmx"
Import "game.gameconstants.bmx"


Type TProgrammeDataCollection Extends TGameObjectCollection

	'factor by what a programmes topicality DECREASES by sending it
	'(with whole audience, so 100%, watching)
	'ex.: 0.9 = 10% cut, 0.85 = 15% cut
	Field wearoffFactor:float = 0.85
	'factor by what a programmes topicality INCREASES by a day switch
	'ex.: 1.0 = 0%, 1.5 = add 50%y
	Field refreshFactor:float = 1.5

	'factor by what a trailer topicality DECREASES by sending it
	Field trailerWearoffFactor:float = 0.85
	'factor by what a trailer topicality INCREASES by broadcasting
	'the programme
	Field trailerRefreshFactor:float = 1.5
	'helper data
	Field _unreleasedProgrammeData:TList = CreateList() {nosave}

	Global _instance:TProgrammeDataCollection


	Function GetInstance:TProgrammeDataCollection()
		if not _instance then _instance = new TProgrammeDataCollection
		return _instance
	End Function


	Method Initialize:TProgrammeDataCollection()
		Super.Initialize()

		_InvalidateCaches()

		return self
	End Method


	Method _InvalidateCaches()
		_unreleasedProgrammeData = Null
	End Method


	Method Add:int(obj:TGameObject)
		_InvalidateCaches()
		return Super.Add(obj)
	End Method


	Method Remove:int(obj:TGameObject)
		_InvalidateCaches()
		return Super.Remove(obj)
	End Method
	

	Method GetByGUID:TProgrammeData(GUID:String)
		Return TProgrammeData( Super.GetByGUID(GUID) )
	End Method


	'returns (and creates if needed) a list containing only upcoming
	'programmeData
	Method GetUnreleasedProgrammeDataList:TList()
		if not _unreleasedProgrammeData
			_unreleasedProgrammeData = CreateList()
			For local data:TProgrammeData = EachIn entries.Values()
				if data.IsReleased() then continue

				_unreleasedProgrammeData.AddLast(data)
			Next
		endif
		'order by release
		_unreleasedProgrammeData.Sort(True, _SortUnreleasedByRelease)

		return _unreleasedProgrammeData
	End Method	


	Method GetGenreRefreshModifier:float(genre:int)
		'values get multiplied with the refresh factor
		'so this means: higher (>1.0) values increase the resulting
		'topicality win
		Select genre
			case TVTProgrammeGenre.Adventure
				return 1.0
			case TVTProgrammeGenre.Action
				return 1.0
			case TVTProgrammeGenre.Animation
				return 1.1
			case TVTProgrammeGenre.Crime
				return 1.0
			case TVTProgrammeGenre.Comedy
				return 1.25
			case TVTProgrammeGenre.Documentary
				return 1.1
			case TVTProgrammeGenre.Drama
				return 1.05
			case TVTProgrammeGenre.Erotic
				return 1.1
			case TVTProgrammeGenre.Family
				return 1.15
			case TVTProgrammeGenre.Fantasy
				return 1.1
			case TVTProgrammeGenre.History
				return 1.0
			case TVTProgrammeGenre.Horror
				return 1.0
			case TVTProgrammeGenre.Monumental
				return 0.95
			case TVTProgrammeGenre.Mystery
				return 0.95
			case TVTProgrammeGenre.Romance
				return 1.1
			case TVTProgrammeGenre.Scifi
				return 0.95
			case TVTProgrammeGenre.Thriller
				return 1.0
			case TVTProgrammeGenre.Western
				return 0.95
			case TVTProgrammeGenre.Show, ..
			     TVTProgrammeGenre.Show_Politics, ..
			     TVTProgrammeGenre.Show_Music
				return 0.90
			case TVTProgrammeGenre.Event, ..
			     TVTProgrammeGenre.Event_Politics, ..
			     TVTProgrammeGenre.Event_Music, ..
			     TVTProgrammeGenre.Event_Sport, ..
			     TVTProgrammeGenre.Event_Showbiz
				return 0.90
			case TVTProgrammeGenre.Feature, ..
			     TVTProgrammeGenre.Feature_YellowPress
				return 0.95
			default
				return 1.0
		End Select
	End Method


	Method GetGenreWearoffModifier:float(genre:int)
		'values get multiplied with the wearOff factor
		'so this means: higher (>1.0) values decrease the resulting
		'topicality loss
		Select genre
			case TVTProgrammeGenre.Adventure
				return 1.0
			case TVTProgrammeGenre.Action
				return 0.95
			case TVTProgrammeGenre.Animation
				return 1.0
			case TVTProgrammeGenre.Crime
				return 0.95
			case TVTProgrammeGenre.Comedy
				return 1.1
			case TVTProgrammeGenre.Documentary
				return 1.1
			case TVTProgrammeGenre.Drama
				return 1.1
			case TVTProgrammeGenre.Erotic
				return 1.2
			case TVTProgrammeGenre.Family
				return 1.25
			case TVTProgrammeGenre.Fantasy
				return 0.95
			case TVTProgrammeGenre.History
				return 1.0
			case TVTProgrammeGenre.Horror
				return 1.0
			case TVTProgrammeGenre.Monumental
				return 0.9
			case TVTProgrammeGenre.Mystery
				return 0.95
			case TVTProgrammeGenre.Romance
				return 1.0
			case TVTProgrammeGenre.Scifi
				return 0.9
			case TVTProgrammeGenre.Thriller
				return 0.95
			case TVTProgrammeGenre.Western
				return 0.90
			case TVTProgrammeGenre.Show, ..
			     TVTProgrammeGenre.Show_Politics, ..
			     TVTProgrammeGenre.Show_Music
				return 0.95
			case TVTProgrammeGenre.Event, ..
			     TVTProgrammeGenre.Event_Politics, ..
			     TVTProgrammeGenre.Event_Music, ..
			     TVTProgrammeGenre.Event_Sport, ..
			     TVTProgrammeGenre.Event_Showbiz
				return 0.85
			case TVTProgrammeGenre.Feature, ..
			     TVTProgrammeGenre.Feature_YellowPress
				return 0.95
			default
				return 1.0
		End Select
	End Method


	'amount the wearoff effect gets reduced/increased by programme flags
	Method GetFlagsWearoffModifier:float(flags:int)
		local flagMod:float = 1.0
		if flags & TVTProgrammeDataFlag.LIVE then flagMod :* 0.75
		'if flags & TVTProgrammeDataFlag.ANIMATION then flagMod :* 1.0
		if flags & TVTProgrammeDataFlag.CULTURE then flagMod :* 1.05
		if flags & TVTProgrammeDataFlag.CULT then flagMod :* 1.2
		if flags & TVTProgrammeDataFlag.TRASH then flagMod :* 0.95
		if flags & TVTProgrammeDataFlag.BMOVIE then flagMod :* 0.90
		'if flags & TVTProgrammeDataFlag.XRATED then flagMod :* 1.0
		if flags & TVTProgrammeDataFlag.PAID then flagMod :* 0.75
		'if flags & TVTProgrammeDataFlag.SERIES then flagMod :* 1.0
		if flags & TVTProgrammeDataFlag.SCRIPTED then flagMod :* 0.90

		return flagMod
	End Method


	'amount the refresh effect gets reduced/increased by programme flags
	Method GetFlagsRefreshModifier:float(flags:int)
		local flagMod:float = 1.0
		if flags & TVTProgrammeDataFlag.LIVE then flagMod :* 0.75
		'if flags & TVTProgrammeDataFlag.ANIMATION then flagMod :* 1.0
		if flags & TVTProgrammeDataFlag.CULTURE then flagMod :* 1.1
		if flags & TVTProgrammeDataFlag.CULT then flagMod :* 1.2
		if flags & TVTProgrammeDataFlag.TRASH then flagMod :* 1.05
		if flags & TVTProgrammeDataFlag.BMOVIE then flagMod :* 1.05
		'if flags & TVTProgrammeDataFlag.XRATED then flagMod :* 1.0
		if flags & TVTProgrammeDataFlag.PAID then flagMod :* 0.85
		'if flags & TVTProgrammeDataFlag.SERIES then flagMod :* 1.0
		if flags & TVTProgrammeDataFlag.SCRIPTED then flagMod :* 0.90

		return flagMod
	End Method	


	Method RefreshTopicalities:int()
		For Local data:TProgrammeData = eachin entries.Values()
			data.RefreshTopicality()
			data.RefreshTrailerTopicality()
		Next
	End Method


	'helper for external callers so they do not need to know
	'the internal structure of the collection
	Method RefreshUnreleased:int()
		_unreleasedProgrammeData = Null
		GetUnreleasedProgrammeDataList()
	End Method


	Method SetProgrammeDataState(data:TProgrammeData, state:int)
		Select state
			case TVTProgrammeState.IN_PRODUCTION
				'

			case TVTProgrammeState.IN_CINEMA
				'invalidate previous cache
				'_inProductionProgrammeData = Null

			case TVTProgrammeState.RELEASED
				'invalidate previous cache
				'_inCinemaProgrammeData = Null

				_unreleasedProgrammeData = Null
		End Select
	End Method


	'updates just unreleased programmes (checks for new states)
	'so: unreleased -> production (->cinema) -> released
	Method UpdateUnreleased:int()
		local unreleased:TList = GetUnreleasedProgrammeDataList()
		local now:Double = GetWorldTime().GetTimeGone()
		For local pd:TProgrammeData = EachIn unreleased
			pd.Update()
			'data is sorted by production start, so as soon as the
			'production start of an entry is in the future, all entries
			'coming after it will be even later and can get skipped
			if pd.GetProductionStartTime() > now then exit
		Next 
	End Method


	'updates all programmes programmes (checks for new states)
	'call this after a game start to set all "old programmes" to be
	'finished
	Method UpdateAll:int()
		local now:Double = GetWorldTime().GetTimeGone()
		For local pd:TProgrammeData = EachIn entries.Values()
			pd.Update()
		Next 
	End Method


	Function _SortUnreleasedByRelease:Int(o1:Object, o2:Object)
		Local p1:TProgrammeData = TProgrammeData(o1)
		Local p2:TProgrammeData = TProgrammeData(o2)
		If Not p2 Then Return 1
        Return p1.GetProductionStartTime() - p2.GetProductionStartTime()
	End Function	
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeDataCollection:TProgrammeDataCollection()
	Return TProgrammeDataCollection.GetInstance()
End Function





'raw data for movies, epidodes (series)
'but also series-headers, collection-headers,...
Type TProgrammeData extends TBroadcastMaterialSourceBase {_exposeToLua}
	Field originalTitle:TLocalizedString
	Field title:TLocalizedString
	Field description:TLocalizedString
	'contains the title with placeholders replaced
	Field titleProcessed:TLocalizedString {nosave}
	Field descriptionProcessed:TLocalizedString {nosave}


	'array holding actor(s) and director(s) and ...
	Field cast:TProgrammePersonJob[]
	Field country:String = "UNK"
	Field year:Int = 1900
	'special targeted audiences?
	Field targetGroups:int = 0
	Field proPressureGroups:int = 0
	Field contraPressureGroups:int = 0
	'time of a live event
	Field liveTime:Long = -1
	Field outcome:Float	= 0
	Field review:Float = 0
	Field speed:Float = 0
	Field genre:Int	= 0
	Field subGenres:Int[]
	Field blocks:Int = 1
	'guid of a potential franchise entry
	Field franchiseGUID:string
	'which kind of distribution was used? Cinema, Custom production ...
	Field distributionChannel:int = 0
	'ID according to TVTProgrammeProductType
	Field productType:Int = 1
	'at which day was the programme released?
	Field releaseTime:Long = -1
	'announced in news etc?
	Field releaseAnnounced:int = FALSE
	'state of the programme (in production, cinema, released...)
	Field state:int = 0
	'how "fresh" a programme is (the more shown, the less this value)
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

	Field _handledFirstTimeBroadcast:int = False
	Field _handledFirstTimeBroadcastAsTrailer:int = False


	Rem
	"modifiers" : extra data block containing various information (if set)
	
	"topicality::age" - influence of the age on the max topicality
	"topicality::timesBroadcasted" - influence of the broadcast amount to max topicality
	"price"
	"wearoff" - changes how much a programme loses during sending it
	"refresh" - changes how much a programme "regenerates" (multiplied with genreModifier)
	endrem


	Function Create:TProgrammeData(GUID:String, title:TLocalizedString, description:TLocalizedString, cast:TProgrammePersonJob[], country:String, year:Int, releaseTime:Long=-1, liveTime:Long, Outcome:Float, review:Float, speed:Float, modifiers:TData, Genre:Int, blocks:Int, xrated:Int, productType:Int=1) {_private}
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
		obj.SetFlag(TVTProgrammeDataFlag.XRATED, xrated)
		obj.country     = country
		obj.cast        = cast
		obj.year        = year
		if GetWorldTime().GetYear(releaseTime) < 1900
			obj.releaseTime = GetWorldTime().Maketime(year, 1,1, 0,0)
		endif
		obj.liveTime    = Max(-1,liveTime)
		obj.topicality  = obj.GetTopicality()
		GetProgrammeDataCollection().Add(obj)

		Return obj
	End Function


	'what to earn for each viewer
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		local result:float = 0.0
		If HasFlag(TVTProgrammeDataFlag.PAID)
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
			if job.personGUID = j.personGUID and job.job = j.job then continue
			'add rest
			newCast :+ [j]
		Next
		cast = newCast
		return True
	End Method


	Method HasCastPerson:int(personGUID:string)
		For local doneJob:TProgrammePersonJob = EachIn cast
			if doneJob.personGUID = personGUID then return True
		Next
		return False
	End Method
	

	Method HasCast:int(job:TProgrammePersonJob)
		'do not check job against jobs in the list, as only the
		'content might be the same but the job a duplicate
		For local doneJob:TProgrammePersonJob = EachIn cast
			if job.personGUID <> doneJob.personGUID then continue 
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
			if job.job = jobFlag
				res :+ [ GetProgrammePersonBaseCollection().GetByGUID(job.personGUID) ]
			endif
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
				if job.job = TVTProgrammePersonJob.ACTOR
					cachedActors :+ [ GetProgrammePersonBaseCollection().GetByGUID(job.personGUID) ]
				endif
			Next
		endif
		
		return cachedActors
	End Method


	Method GetDirectors:TProgrammePersonBase[]()
		if cachedDirectors.length = 0
			For local job:TProgrammePersonJob = EachIn cast
				if job.job = TVTProgrammePersonJob.DIRECTOR
					cachedDirectors :+ [ GetProgrammePersonBaseCollection().GetByGUID(job.personGUID) ]
				endif
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


	Method GetTrailerRefreshModifier:float()
		return GetModifier("topicality::trailerRefresh")
	End Method


	Method GetTrailerWearoffModifier:float()
		return GetModifier("topicality::trailerWearoff")
	End Method


	Method GetGenreWearoffModifier:float(genre:int=-1)
		if genre = -1 then genre = self.genre
		return GetProgrammeDataCollection().GetGenreWearoffModifier(genre)
	End Method


	Method GetFlagsWearoffModifier:float(flags:int=-1)
		if flags = -1 then flags = self.flags
		return GetProgrammeDataCollection().GetFlagsWearoffModifier(flags)
	End Method


	Method GetFlagsRefreshModifier:float(flags:int=-1)
		if flags = -1 then flags = self.flags
		return GetProgrammeDataCollection().GetFlagsRefreshModifier(flags)
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
		local checkFlags:int[] = [TVTProgrammeDataFlag.LIVE, TVTProgrammeDataFlag.PAID]

		'checkall
		'local checkFlags:int[]
		'for local i:int = 0 to 10 '1-1024 
		'	checkFlags :+ [2^i]
		'next

		for local i:int = eachin checkFlags
			if flags & i > 0
				if result <> "" then result :+ delimiter
				result :+ GetLocale("PROGRAMME_FLAG_" + TVTProgrammeDataFlag.GetAsString(i))
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
				local person:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID(elements[1])
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
						local person:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID( job.personGUID )
						result = result.replace("["+i+"|Full]", person.GetFullName())
						result = result.replace("["+i+"|First]", person.GetFirstName())
						result = result.replace("["+i+"|Nick]", person.GetNickName())
						result = result.replace("["+i+"|Last]", person.GetLastName())
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
			'replace placeholders and and cache the result
			if not titleProcessed
				titleProcessed = new TLocalizedString
				titleProcessed.Set( _LocalizeContent(title.Get()) )
			endif
			return titleProcessed.Get()
		endif
		return ""
	End Method


	Method GetDescription:string()
		if description
			'replace placeholders and and cache the result
			if not descriptionProcessed
				descriptionProcessed = new TLocalizedString
				descriptionProcessed.Set( _LocalizeContent(description.Get()) )
			endif
			return descriptionProcessed.Get()
		endif
		return ""
	End Method

	
	Method IsLive:int()
		return HasFlag(TVTProgrammeDataFlag.LIVE)
	End Method
	
	
	Method IsAnimation:Int()
		return HasFlag(TVTProgrammeDataFlag.ANIMATION)
	End Method
	
	
	Method IsCulture:Int()
		return HasFlag(TVTProgrammeDataFlag.CULTURE)
	End Method	
		
	
	Method IsCult:Int()
		return HasFlag(TVTProgrammeDataFlag.CULT)
	End Method
	
	
	Method IsTrash:Int()
		return HasFlag(TVTProgrammeDataFlag.TRASH)
	End Method
	
	Method IsBMovie:Int()
		return HasFlag(TVTProgrammeDataFlag.BMOVIE)
	End Method
	
	
	Method IsXRated:int()
		return HasFlag(TVTProgrammeDataFlag.XRATED)
	End Method


	Method IsPaid:int()
		return HasFlag(TVTProgrammeDataFlag.PAID)
	End Method


	Method IsScripted:int()
		return HasFlag(TVTProgrammeDataFlag.SCRIPTED)
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


	Method GetReleaseTime:Long()
		return releaseTime
	End Method


	Method GetCinemaReleaseTime:Long()
		return releaseTime - Max(1, floor(0.5 * GetWorldTime().GetDaysPerYear())) * TWorldTime.DAYLENGTH
	End Method


	'only useful for cinematic movies
	Method GetProductionStartTime:Long()
		return releaseTime - GetWorldTime().GetDaysPerYear() * TWorldTime.DAYLENGTH
	End Method



	Method SetReleaseTime(dayOfYear:int)
		releaseTime = GetWorldTime().MakeTime(year, dayOfYear mod GetWorldTime().GetDaysPerYear(), 0, 0)
	End Method


	Method GetPrice:int()
		Local value:int = 0

		'price is based on quality
		local priceMod:float = GetQualityRaw()

		'movies run in cinema (outcome >0)
		If isType(TVTProgrammeProductType.MOVIE) and GetOutcome() > 0
			priceMod = THelper.LogisticalInfluence_Euler(priceMod, 0.5)
			value = 35000 + 870000 * priceMod
		 'shows, productions, series...
		Else
			priceMod = THelper.LogisticalInfluence_Euler(priceMod, 0.5)
			'basefactor * priceFactor
			value = 15000 + 100000 * priceMod
		EndIf

		'=== MODIFIERS ===
		'price modifier just influences price by 25% (to avoid "0" prices)
		value :* (0.75 + 0.25 * GetModifier("price"))


		'=== TOPICALITY ===
		'the more current the more expensive
		'multipliers stack"
		local topicalityModifier:Float = 1.0
		If (GetMaxTopicality() >= 0.80) Then topicalityModifier = 1.1
		If (GetMaxTopicality() >= 0.85) Then topicalityModifier = 1.3
		If (GetMaxTopicality() >= 0.90) Then topicalityModifier = 1.7
		If (GetMaxTopicality() >= 0.94) Then topicalityModifier = 2.25
		If (GetMaxTopicality() >= 0.98) Then topicalityModifier = 3.0
		'make just released programmes even more expensive
		If (GetMaxTopicality() > 0.99)  Then topicalityModifier = 4.5

		value :* topicalityModifier

		'topicality has a certain value influence
		value :* GetTopicality()

		'the older the less a licence costs
		'shrinkage: fast shrinking at the begin (low distance) and slow
		'           shrinking the more it gets to ageDistance = 0.0
		'the age factor is also used in "GetMaxTopicality())
		'the modifier "price::age" increases the "age" used in _this_
		'calculation 
		Local ageDistance:Float = 0.01 * Max(0, 100 - Max(0, GetModifier("price::age") * (GetWorldTime().GetYear() - year)))
		value :* (1.0 - THelper.LogisticalInfluence_Euler(1.0 - Max(0.30, ageDistance), 0.85))
		
		'=== FLAGS ===
		'BMovies lower the price
		If Self.IsBMovie() then value :* 0.85

		'Income generating programmes (infomercials) increase the price
		If Self.IsPaid() then value :* 1.2


			
		'round to next "1000" block
		value = Int(Floor(value / 1000) * 1000)

		'print GetTitle()+"  value1: "+value + "  outcome:"+GetOutcome()+"  review:"+GetReview() + " maxTop:"+GetMaxTopicality()+" year:"+year

		return value
	End Method


	'override
	Method GetMaxTopicality:Float()
		Local age:Int = Max(0, GetWorldTime().GetYear() - year)
		'maximum of 25 broadcasts decrease up to "50%" of max topicality
		Local timesBroadcasted:Int = 0.5 * Min(100, GetTimesBroadcasted() * 4)

		'modifiers could increase or decrease influences of age/aired/...
		local ageInfluence:Float = age * GetModifier("topicality::age")
		local timesBroadcastedInfluence:Float = timesBroadcasted * GetModifier("topicality::timesBroadcasted")

		'cult-movies are less affected by aging or broadcast amounts
		If Self.IsCult()
			ageInfluence :* 0.75
			timesBroadcastedInfluence :* 0.50
		EndIf

		local influencePercentage:Float = 0.01 * MathHelper.Clamp(ageInfluence + timesBroadcastedInfluence, 0, 100)
		return 1.0 - THelper.LogisticalInfluence_Euler(influencePercentage, 1)
		'return MathHelper.Clamp(1.0 - influencePercentage, 0.0, 1.0)
	End Method


	Method GetMaxTrailerTopicality:Float()
		return trailerMaxTopicality
	End Method


	Method GetTrailerTopicality:Float()
		if trailerTopicality < 0 then trailerTopicality = GetMaxTrailerTopicality()

		'refresh topicality on each request
		'-> avoids a "topicality > MaxTopicality" when MaxTopicality
		'   shrinks because of aging/airing
		trailerTopicality = Min(trailerTopicality, GetMaxTrailerTopicality())
		
		return trailerTopicality
	End Method


	Method GetGenreDefinition:TMovieGenreDefinition()
		If Not genreDefinitionCache Then
			genreDefinitionCache = GetMovieGenreDefinitionCollection().Get(Genre)

			If Not genreDefinitionCache
				TLogger.Log("GetGenreDefinition()", "Programme ~q"+GetTitle()+"~q: Genre #"+Genre+" misses a genreDefinition. Creating BASIC definition-", LOG_ERROR)
				genreDefinitionCache = new TMovieGenreDefinition.InitBasic(Genre, null)
			EndIf
		EndIf
		Return genreDefinitionCache
	End Method


	Method GetQualityRaw:Float()
		Local genreDef:TMovieGenreDefinition = GetGenreDefinition()
		local quality:Float = 0.0

		quality :+ GetReview() * genreDef.ReviewMod
		quality :+ GetSpeed() * genreDef.SpeedMod
		if GetOutcome() > 0
			quality :+ GetOutcome() * genreDef.OutcomeMod
		'if no outcome was defined, increase weight of the other parts
		'increase quality according to their weight to the outcome mod
		elseif genreDef.OutcomeMod > 0 and genreDef.OutcomeMod < 1.0
			'1.0 - genreDef.OutcomeMod = amount left to share
			if genreDef.ReviewMod > 0
				quality :+ genreDef.ReviewMod/(1.0 - genreDef.OutcomeMod) * GetReview()
			endif
			if genreDef.SpeedMod > 0 
				quality :+ genreDef.SpeedMod/(1.0 - genreDef.OutcomeMod) * GetSpeed()
			endif
		endif

		return quality
	End Method


	'Diese Methode ersetzt "GetBaseAudienceQuote"
	Method GetQuality:Float() {_exposeToLua}
		Local quality:Float = GetQualityRaw()

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Float = 0.01 * Max(0, 100 - Max(0, GetWorldTime().GetYear() - year))
		quality :* Max(0.20, age)

		'the more the programme got repeated, the lower the quality in
		'that moment (^2 increases loss per air)
		'but a "good movie" should benefit from being good - so the
		'influence of repetitions gets lower by higher raw quality
		'-> a movie with 100% base quality will have at least 25% of
		'   quality no matter how many times it got aired
		'-> a movie with 0% base quality will cut to up to 75% of that
		'   resulting in <= 25% quality
		
		quality :* (0.25*GetQualityRaw() + (1.0 - 0.75*GetQualityRaw()) * GetTopicality()^2)
		'old variant
		'quality :* GetTopicality() ^ 2

		'no minus quote, min 0.01 quote
		quality = Max(0.01, quality)

		Return quality
	End Method


	'override
	Method CutTopicality:Float(cutModifier:float=1.0) {_private}
		'cutModifier can be used to manipulate the resulting cut
		'ex. for night times, for low audience...

		'cut by an individual cutoff factor - do not allow values > 1.0
		'(refresh instead of cut)
		'the value : default * invidual * individualGenre
		cutModifier :* GetProgrammeDataCollection().wearoffFactor
		cutModifier :* GetGenreWearoffModifier()
		cutModifier :* GetFlagsWearoffModifier()
		cutModifier :* GetWearoffModifier()

		'cut by at least 5%, limit to 0-Max
		Return Super.CutTopicality( Min(0.95, cutModifier) )
	End Method


	Method CutTrailerTopicality:Float(cutModifier:Float = 1.0) {_private}
		cutModifier :* GetProgrammeDataCollection().trailerWearoffFactor
		cutModifier :* GetWearoffModifier()
		'trailers also get influenced by flags and genre
		cutModifier :* GetGenreWearoffModifier()
		cutModifier :* GetFlagsWearoffModifier()

		'cut by at least 5%, limit to 0-1
		'(trailers do not inherit "aged" topicality, so 1 is max)
		trailerTopicality = MathHelper.Clamp(trailerTopicality * Min(0.95, cutModifier), 0.0, 1.0)

		Return trailerTopicality
	End Method


	'override
	Method RefreshTopicality:Float(refreshModifier:Float = 1.0) {_private}
		refreshModifier :* GetProgrammeDataCollection().refreshFactor
		refreshModifier :* GetRefreshModifier()
		refreshModifier :* GetGenreRefreshModifier()

		'refresh by at least 5%, limit to 0-Max
		Return Super.RefreshTopicality( Max(1.05, refreshModifier) )
	End Method


	Method RefreshTrailerTopicality:Float(refreshModifier:Float = 1.0) {_private}
		refreshModifier :* GetProgrammeDataCollection().trailerRefreshFactor
		refreshModifier :* GetTrailerRefreshModifier()
		'trailers also get influenced by flags and genre
		refreshModifier :* GetGenreRefreshModifier()
		refreshModifier :* GetFlagsRefreshModifier()

		'refresh by at least 5%, limit to 0-1
		trailerTopicality = MathHelper.Clamp(trailerTopicality * Max(1.05, refreshModifier), 0, 1.0)

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

		Return new TAudience.InitValue(trailerMod, trailerMod)
	End Method


	'override
	Method IsAvailable:int()
		'if a date for a live broadcast was defined, the programme
		'isn't anymore from this time on
		if liveTime >= 0 and GetWorldTime().GetTimeGone() >= liveTime
			return False
		endif

		if not isReleased() then return False

		return Super.IsAvailable()
	End Method


	Method isReleased:int()
		'call-in shows are kind of "live"
		if HasFlag(TVTProgrammeDataFlag.PAID) then return True

		return GetWorldTime().GetTimeGone() >= releaseTime
	End Method


	Method isInCinema:int()
		if isReleased() then return False
		' without stored outcome, the movie wont run in the cinemas
		if outcome <= 0 then return False
		
		return GetCinemaReleaseTime() <= GetWorldTime().GetTimeGone()
	End Method


	Method isInProduction:int()
		if isReleased() then return False
		
		return GetProductionStartTime() <= GetWorldTime().GetTimeGone() and GetCinemaReleaseTime() > GetWorldTime().GetTimeGone()
	End Method
	

	Method isType:int(typeID:int)
		'if productType is a bitmask flag
		'return (productType & typeID)

		return productType = typeID
	End Method	


	Method SetState:int(state:int)
		'skip if already done
		if self.state = state then return False

		Select state
			case TVTProgrammeState.NONE
				'
			case TVTProgrammeState.IN_PRODUCTION
				if not onProductionStart() then return False
			case TVTProgrammeState.IN_CINEMA
				if not onCinemaRelease() then return False
			case TVTProgrammeState.RELEASED
				if not onRelease() then return False
		End Select

		'inform collection that this programme(data) is in a new state
		GetProgrammeDataCollection().SetProgrammeDataState(self, state)

		self.state = state
	End Method


	Method onProductionStart:int(time:Long = 0)
		'trigger effects/modifiers
		local params:TData = new TData.Add("source", self)
		effects.Run("productionStart", params)

		return True
	End Method


	Method onCinemaRelease:int(time:Long = 0)
		if IsLive() then return False
		
		'inform each person in the cast that the production finished
		For local job:TProgrammePersonJob = eachIn GetCast()
			local person:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID( job.personGUID )
			if person then person.FinishProduction(GetGUID())
		Next
		return True
	End Method


	Method onRelease:int(time:Long = 0)
		return True
	End Method


	Method Update:int()
		Select state
			case TVTProgrammeState.NONE
				'repair old programme (finished before game start year)
				'and loop through all states (prod - cinema - release)
				if isReleased()
					SetState(TVTProgrammeState.IN_PRODUCTION)
					SetState(TVTProgrammeState.IN_CINEMA)
					SetState(TVTProgrammeState.RELEASED)
				elseif isInCinema()
					SetState(TVTProgrammeState.IN_PRODUCTION)
					SetState(TVTProgrammeState.IN_CINEMA)
				elseif isInProduction()
					SetState(TVTProgrammeState.IN_PRODUCTION)
				endif
			case TVTProgrammeState.IN_PRODUCTION
				if isInCinema()
					SetState(TVTProgrammeState.IN_CINEMA)
				'some programme do not run in cinema
				elseif isReleased()
					SetState(TVTProgrammeState.RELEASED)
				endif
			case TVTProgrammeState.IN_PRODUCTION
				if isReleased() then SetState(TVTProgrammeState.RELEASED)
		End Select
	End Method



	'override
	'called as soon as the programme is broadcasted
	Method doBeginBroadcast(playerID:int = -1, broadcastType:int = 0)
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("source", self).AddNumber("playerID", playerID)

		'send as programme
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			if GetTimesBroadcasted() = 0
				'inform each person in the cast that the production finished
				'(albeit this is NOT strictly the truth)
				if IsLive()
					For local job:TProgrammePersonJob = eachIn GetCast()
						local person:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID( job.personGUID )
						if person then person.FinishProduction(GetGUID())
					Next
				endif


				if not _handledFirstTimeBroadcast
					effects.Run("broadcastFirstTime", effectParams)
					_handledFirstTimeBroadcast = True
				endif
			endif

			effects.Run("broadcast", effectParams)


		'send as trailer
		elseif broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			if GetTimesTrailerAired() = 0
				if not _handledFirstTimeBroadcastAsTrailer
					effects.Run("broadcastFirstTimeTrailer", effectParams)
					_handledFirstTimeBroadcastAsTrailer = True
				endif
			endif

			effects.Run("broadcastInfomercial", effectParams)
		endif
	End Method
End Type





