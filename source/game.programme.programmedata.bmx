REM
	===========================================================
	code for programme-objects (movies, ..) in programme planning
	===========================================================
ENDREM
SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.player.difficulty.bmx"
Import "game.world.worldtime.bmx"
Import "game.programme.programmeperson.base.bmx"
Import "game.broadcast.genredefinition.movie.bmx"
Import "game.broadcastmaterialsource.base.bmx"
Import "game.gameconstants.bmx"
Import "basefunctions.bmx"


Type TProgrammeDataCollection Extends TGameObjectCollection

	'factor by what a programmes topicality DECREASES by sending it
	'(with whole audience, so 100%, watching)
	'a value > 1.0 means, it decreases to 0 with less than 100% watching
	'ex.: 0.9 = 10% cut, 0.85 = 15% cut
	Field wearoffFactor:float = 1.25
	'factor by what a programmes topicality INCREASES by a day switch
	'ex.: 1.0 = 0%, 1.5 = add 50%y
	Field refreshFactor:float = 1.4

	'factor by what a trailer topicality DECREASES by sending it
	'2.0 means, it reaches 0 with 50% audience/area quote
	Field trailerWearoffFactor:float = 0.5
	'factor by what a trailer topicality INCREASES by broadcasting
	'the programme
	Field trailerRefreshFactor:float = 1.4
	'helper data
	Field _unreleasedProgrammeData:TList {nosave}
	Field _liveProgrammeData:TList {nosave}
	Field _finishedProductionProgrammeData:TList {nosave}

	Global _instance:TProgrammeDataCollection
	Global _eventListeners:TLink[]


	Function GetInstance:TProgrammeDataCollection()
		if not _instance then _instance = new TProgrammeDataCollection
		return _instance
	End Function


	Method New()
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'_eventListeners :+ [ EventManager.registerListenerFunction( "Language.onSetLanguage", onSetLanguage ) ]
	End Method


	Method Initialize:TProgrammeDataCollection()
		Super.Initialize()

		_InvalidateCaches()

		return self
	End Method


	Method _InvalidateCaches()
		_unreleasedProgrammeData = Null
		_liveProgrammeData = Null
		_finishedProductionProgrammeData = Null
	End Method


	Method Add:int(obj:TGameObject)
		_InvalidateCaches()
		return Super.Add(obj)
	End Method


	Method Remove:int(obj:TGameObject)
		_InvalidateCaches()
		return Super.Remove(obj)
	End Method


	Method GetByID:TProgrammeData(ID:int)
		Return TProgrammeData( Super.GetByID(ID) )
	End Method


	Method GetByGUID:TProgrammeData(GUID:String)
		Return TProgrammeData( Super.GetByGUID(GUID) )
	End Method


	Method SearchByPartialGUID:TProgrammeData(GUID:String)
		Return TProgrammeData( Super.SearchByPartialGUID(GUID) )
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

			'order by release
			_unreleasedProgrammeData.Sort(True, _SortByReleaseTime)
		endif

		return _unreleasedProgrammeData
	End Method


	'returns (and creates if needed) a list containing only live
	'programmeData
	Method GetLiveProgrammeDataList:TList()
		if not _liveProgrammeData
			_liveProgrammeData = CreateList()
			For local data:TProgrammeData = EachIn entries.Values()
				if data.IsHeader() then continue
				if not data.IsLive() then continue

				_liveProgrammeData.AddLast(data)
			Next

			'order by release
			_liveProgrammeData.Sort(True, _SortByReleaseTime)
		endif

		return _liveProgrammeData
	End Method


	'returns (and creates if needed) a list containing only entries
	'with finished production (= released or in cinema)
	Method GetFinishedProductionProgrammeDataList:TList()
		if not _finishedProductionProgrammeData
			_finishedProductionProgrammeData = CreateList()
			For local data:TProgrammeData = EachIn entries.Values()
				if data.IsHeader() then continue
				if not data.IsReleased() and not data.IsInCinema() then continue

				_finishedProductionProgrammeData.AddLast(data)
			Next

			'order by release
			_finishedProductionProgrammeData.Sort(True, _SortByReleaseTime)
		endif

		return _finishedProductionProgrammeData
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
		'so this means: higher (>1.0) values increase the resulting
		'topicality loss
		Select genre
			case TVTProgrammeGenre.Adventure
				return 1.0
			case TVTProgrammeGenre.Action
				return 1.05
			case TVTProgrammeGenre.Animation
				return 1.0
			case TVTProgrammeGenre.Crime
				return 1.05
			case TVTProgrammeGenre.Comedy
				return 0.90
			case TVTProgrammeGenre.Documentary
				return 0.85
			case TVTProgrammeGenre.Drama
				return 0.95
			case TVTProgrammeGenre.Erotic
				return 0.80
			case TVTProgrammeGenre.Family
				return 0.85
			case TVTProgrammeGenre.Fantasy
				return 1.05
			case TVTProgrammeGenre.History
				return 1.0
			case TVTProgrammeGenre.Horror
				return 1.0
			case TVTProgrammeGenre.Monumental
				return 1.1
			case TVTProgrammeGenre.Mystery
				return 1.05
			case TVTProgrammeGenre.Romance
				return 1.0
			case TVTProgrammeGenre.Scifi
				return 1.10
			case TVTProgrammeGenre.Thriller
				return 1.05
			case TVTProgrammeGenre.Western
				return 1.10
			case TVTProgrammeGenre.Show, ..
			     TVTProgrammeGenre.Show_Politics, ..
			     TVTProgrammeGenre.Show_Music
				return 1.10
			case TVTProgrammeGenre.Event, ..
			     TVTProgrammeGenre.Event_Politics, ..
			     TVTProgrammeGenre.Event_Music, ..
			     TVTProgrammeGenre.Event_Sport, ..
			     TVTProgrammeGenre.Event_Showbiz
				return 1.15
			case TVTProgrammeGenre.Feature, ..
			     TVTProgrammeGenre.Feature_YellowPress
				return 1.05
			default
				return 1.0
		End Select
	End Method


	'amount the wearoff effect gets reduced/increased by programme flags
	Method GetFlagsWearoffModifier:float(flags:int)
		'values get multiplied with the wearOff factor
		'so this means: higher (>1.0) values increase the resulting
		'topicality loss

		local flagMod:float = 1.0
		if flags & TVTProgrammeDataFlag.LIVE then flagMod :* 1.25
		'if flags & TVTProgrammeDataFlag.ANIMATION then flagMod :* 1.0
		if flags & TVTProgrammeDataFlag.CULTURE then flagMod :* 0.95
		if flags & TVTProgrammeDataFlag.CULT then flagMod :* 0.85
		if flags & TVTProgrammeDataFlag.TRASH then flagMod :* 1.10
		if flags & TVTProgrammeDataFlag.BMOVIE then flagMod :* 1.15
		'if flags & TVTProgrammeDataFlag.XRATED then flagMod :* 1.0
		if flags & TVTProgrammeDataFlag.PAID then flagMod :* 1.30
		'if flags & TVTProgrammeDataFlag.SERIES then flagMod :* 1.0
		if flags & TVTProgrammeDataFlag.SCRIPTED then flagMod :* 1.15

		return flagMod
	End Method


	'amount the refresh effect gets reduced/increased by programme flags
	Method GetFlagsRefreshModifier:float(flags:int)
		'values get multiplied with the refresh factor
		'so this means: higher (>1.0) values increase the resulting
		'refresh value

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


	'updates live programmes (checks if they aired now)
	Method UpdateLive:int()
		local live:TList = GetLiveProgrammeDataList()
		local invalidate:int = False

		For local pd:TProgrammeData = EachIn live
			'skip not yet started ones
			if pd.GetReleaseTime() > GetWorldTime().GetTimeGone() then exit

			if pd.IsLive()
				'update eg. title/description
				pd.UpdateLive()

				'invalidate cache if live-status was changed
				if pd.UpdateLiveStates() then invalidate = True
			endif
		Next
		if invalidate then _liveProgrammeData = null
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


	Method RemoveReplacedPlaceholderCaches()
		For local data:TProgrammeData = EachIn entries.Values()
			data.titleProcessed = null
			data.descriptionProcessed = null
		Next
	End Method



	Function _SortByReleaseTime:Int(o1:Object, o2:Object)
		Local p1:TProgrammeData = TProgrammeData(o1)
		Local p2:TProgrammeData = TProgrammeData(o2)
		If Not p2 Then Return 1
        Return p1.releaseTime - p2.releaseTime
	End Function


	'=== EVENT HANDLERS ===
	rem
	Function onSetLanguage:int( triggerEvent:TEventBase )
		GetInstance().RemoveReplacedPlaceholderCaches()
	End Function
	endrem
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeDataCollection:TProgrammeDataCollection()
	Return TProgrammeDataCollection.GetInstance()
End Function





'raw data for movies, episodes (series)
'but also series-headers, collection-headers,...
Type TProgrammeData extends TBroadcastMaterialSource {_exposeToLua}
	Field originalTitle:TLocalizedString
	'contains the title with placeholders replaced
	Field titleProcessed:TLocalizedString {nosave}
	Field descriptionProcessed:TLocalizedString {nosave}


	'array holding actor(s) and director(s) and ...
	Field cast:TProgrammePersonJob[]
	Field country:String = "UNK"

	'fine grained attractivity for target groups (splitted gender)
	Field targetGroupAttractivityMod:TAudience = null
	'special targeted audiences?
	Field targetGroups:int = 0
	Field proPressureGroups:int = 0
	Field contraPressureGroups:int = 0
	'outcome in cinema (or videomarket)
	Field outcome:Float	= 0
	'outcome in first TV broadcast
	Field outcomeTV:Float = -1.0
	Field review:Float = 0
	Field speed:Float = 0

	Field genre:Int	= 0
	Field subGenres:Int[]
	Field blocks:Int = 1

	'guid of a potential series header
	Field parentGUID:string
	'TVTProgrammeDataType-value
	'(eg. "SERIES" for series-headers, or "SINGLE" for a movie)
	Field dataType:int = 0

	'guid of a potential franchise entry (for now only one franchise per
	'franchisee)
	Field franchiseGUID:string
	'programmes descending from this programme (eg. "Lord of the Rings"
	'as "franchise" and the individual programmes as "franchisees"
	Field franchisees:string[]

	'which kind of distribution was used? Cinema, Custom production ...
	Field distributionChannel:int = 0
	'is this a production of a user?
	Field producedByPlayerID:int = 0
	'ID according to TVTProgrammeProductType
	Field productType:Int = 1
	'at which day was the programme released?
	'for live shows this is the time of the live event
	Field releaseTime:Long = -1
	'announced in news etc?
	Field releaseAnnounced:int = False
	Field finishedProductionForCast:int = False
	'state of the programme (in production, cinema, released...)
	Field state:Int = 0
	'bitmask for all players whether they currently broadcast it
	Field playersBroadcasting:int
	Field playersLiveBroadcasting:int

	'=== trailer data ===
	'=== shared
	'this data is shared along multiple licences (so maybe players)!
	Field trailerTopicality:float = 1.0
	Field trailerMaxTopicality:float = 1.0
	'times the trailer aired in total
	Field trailerAired:int = 0
	'=== individual
	'times the trailer aired since the programme was shown "normal"
	Field trailerAiredSinceLastBroadcast:int[]
	Field trailerMods:TAudience[]


	Field cachedActors:TProgrammePersonBase[] {nosave}
	Field cachedDirectors:TProgrammePersonBase[] {nosave}
	Field genreDefinitionCache:TMovieGenreDefinition = Null {nosave}

	Field extra:TData

	'hide movies of 2012 when in 1985?
	Global ignoreUnreleasedProgrammes:int = TRUE
	Global _filterReleaseDateStart:int = 1900
	Global _filterReleaseDateEnd:int = 2100


	Rem
	"modifiers" : extra data block containing various information (if set)

	"topicality::age" - influence of the age on the max topicality
	"topicality::timesBroadcasted" - influence of the broadcast amount to max topicality
	"price"
	"wearoff" - changes how much a programme loses during sending it
	"refresh" - changes how much a programme "regenerates" (multiplied with genreModifier)
	endrem

	Method GenerateGUID:string()
		return "broadcastmaterialsource-programmedata-"+id
	End Method


	Function setIgnoreUnreleasedProgrammes(ignore:int=TRUE, releaseStart:int=1900, releaseEnd:int=2100)
		ignoreUnreleasedProgrammes = ignore
		_filterReleaseDateStart = releaseStart
		_filterReleaseDateEnd = releaseEnd
	End Function


	'what to earn for each viewer
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		local result:float = 0.0
		If HasFlag(TVTProgrammeDataFlag.PAID)
			'leads to a maximum of "0.15 * (23+12)" if speed/review
			'reached 100%
			'-> 5.25 Euro per Viewer
			result :+ GetSpeed() * 23
			result :+ GetReview() * 12
			'cut to 15%
			result :* 0.15
			'adjust by topicality
			result :* (GetTopicality()/GetMaxTopicality())

			'dynamic modifier
			result :* GetPerViewerRevenueModifier()
		Else
			'by default no programme has a sponsorship
			result = 0.0
			'TODO: include sponsorships
		Endif
		return result
	End Method


	Method ClearCast:int()
		cast = new TProgrammePersonJob[0]

		'invalidate caches
		cachedActors = cachedActors[..0]
		cachedDirectors = cachedDirectors[..0]

		return True
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

		'invalidate caches
		cachedActors = cachedActors[..0]
		cachedDirectors = cachedDirectors[..0]

		return True
	End Method


	Method GetCastPopularity:Float()
		local res:Float = 0.0
		local castCount:int = 0

		For local job:TProgrammePersonJob = EachIn cast
			local p:TProgrammePersonBase = GetProgrammePersonBase(job.personGUID)
			if not p then continue
			res :+ p.GetPopularityValue()
			castCount :+1
		Next
		if castCount > 0 then res = res / castCount

		'return a value between -1 and 1
		Return MathHelper.Clamp(res / 100.0, -2.0, 2.0 )
	End Method


	Method GetCastFame:Float()
		local res:Float = 0.0
		local castCount:int = 0

		For local job:TProgrammePersonJob = EachIn cast
			local p:TProgrammePersonBase = GetProgrammePersonBase(job.personGUID)
			if not p then continue
			res :+ p.GetAttribute(TVTProgrammePersonAttribute.FAME)
			castCount :+1
		Next
		if castCount > 0 then res = res / castCount
		'return a value between 0 and 1
		Return MathHelper.Clamp(res, 0.0, 1.0 )
	End Method


	Method HasCastPerson:int(personGUID:string, job:int = -1)
		For local doneJob:TProgrammePersonJob = EachIn cast
			if job >= 0 and doneJob.job & job <= 0 then continue

			if doneJob.personGUID = personGUID then return True
		Next
		return False
	End Method


	Method HasCast:int(job:TProgrammePersonJob, checkRoleGUID:int = True)
		'do not check job against jobs in the list, as only the
		'content might be the same but the job a duplicate
		For local doneJob:TProgrammePersonJob = EachIn cast
			if job.personGUID <> doneJob.personGUID then continue
			if job.job <> doneJob.job then continue
			if checkRoleGUID and job.roleGUID <> doneJob.roleGUID then continue

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


	Method GetPerViewerRevenueModifier:float()
		return GetModifier("callin::perViewerRevenue")
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


	Method HasSubGenre:int(genre:int)
		For local i:int = EachIn subGenres
			if genre = i then return True
		Next
		return False
	End Method


	Method GetGenreRefreshModifier:float(genre:int=-1)
		if genre = -1 then genre = self.genre
		return GetProgrammeDataCollection().GetGenreRefreshModifier(genre)
	End Method


	Function _GetGenreString:String(_genre:Int=-1)
		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(_genre))
	End Function


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


	Method _ReplacePlaceholdersInLocalizedString:TLocalizedString(localizedString:TLocalizedString)
		local result:TLocalizedString = new TLocalizedString
		For local languageKey:string = EachIn localizedString.GetLanguageKeys()
			result.Set(_ReplacePlaceholdersInString(localizedString.Get(languageKey)), languageKey)
		Next
		return result
	End Method


	Method _ReplacePlaceholdersInString:string(content:string)
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
		endif

		return result
	End Method


	Method GetTitle:string()
		if title
			'replace placeholders and and cache the result
			if not titleProcessed
				titleProcessed = _ReplacePlaceholdersInLocalizedString(title)
			endif
			return titleProcessed.Get()
		endif
		return ""
	End Method


	Method GetDescription:string()
		if description
			'replace placeholders and and cache the result
			if not descriptionProcessed
				descriptionProcessed = _ReplacePlaceholdersInLocalizedString(description)
			endif
			return descriptionProcessed.Get()
		endif
		return ""
	End Method


	Method IsHeader:int() {_exposeToLua}
		return (dataType = TVTProgrammeDataType.SERIES) or ..
		       (dataType = TVTProgrammeDataType.COLLECTION) or ..
		       (dataType = TVTProgrammeDataType.FRANCHISE)
	End Method


	Method IsEpisode:int() {_exposeToLua}
		return (dataType = TVTProgrammeDataType.EPISODE)
	End Method


	Method IsSingle:int() {_exposeToLua}
		return (dataType = TVTProgrammeDataType.SINGLE)
	End Method


	'first premiered on TV?
	Method IsTVDistribution:int() {_exposeToLua}
		return distributionChannel & TVTProgrammeDistributionChannel.TV > 0
	End Method


	'first premiered in cinema?
	Method IsCinemaDistribution:int() {_exposeToLua}
		return distributionChannel & TVTProgrammeDistributionChannel.CINEMA > 0
	End Method


	Method IsLive:int()
		return HasFlag(TVTProgrammeDataFlag.LIVE) > 0
	End Method


	Method SetPlayerIsBroadcasting(playerID:int, enable:int)
		local flag:int = 2^(playerID-1)
		If enable
			playersBroadcasting :| flag
		Else
			playersBroadcasting :& ~flag
		EndIf
	End Method


	Method IsPlayerIsBroadcasting:int(playerID:int)
		local flag:int = 2^(playerID-1)
		return (playersBroadcasting & flag > 0)
	End Method


	Method SetPlayerIsLiveBroadcasting(playerID:int, enable:int)
		local flag:int = 2^(playerID-1)
		If enable
			playersLiveBroadcasting :| flag
		Else
			playersLiveBroadcasting :& ~flag
		EndIf
	End Method


	Method IsPlayerIsLiveBroadcasting:int(playerID:int)
		local flag:int = 2^(playerID-1)
		return (playersBroadcasting & flag > 0)
	End Method


	'Informs casts about the finish of the production regardless
	'whether it got broadcasted or not
	Method UpdateLive:int()
		if not IsLive() then return False

		if GetWorldTime().GetTimeGone() >= double(GetWorldTime().GetHour(releaseTime))*3600 + blocks*3600 - 5*60
			if GetTimesBroadcasted() <= 1
				onFinishProductionForCast()
			endif
		endif
	End Method


	'returns whether the live-state was updated
	Method UpdateLiveStates:int()
		'cannot update as long somebody is broadcasting that programme
		if playersLiveBroadcasting > 0 then return False

		'stay "LIVE" forever
		if hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.ALWAYS_LIVE)
			return False
		endif

		'programmes begin at xx:05 - but their live events will end xx:55
		'releaseTime is not guaranteed to be "xx:00" so, we use GetHours()
		if IsLive() and GetWorldTime().GetTimeGone() >= double(GetWorldTime().GetHour(releaseTime))*3600 + blocks*3600 - 5*60
			SetFlag(TVTProgrammeDataFlag.LIVE, False)
			SetFlag(TVTProgrammeDataFlag.LIVEONTAPE, True)
			return True
		endif
		return False
	End Method


	Method IsLiveOnTape:int()
		return HasFlag(TVTProgrammeDataFlag.LIVEONTAPE) > 0
	End Method


	Method IsAnimation:Int()
		return HasFlag(TVTProgrammeDataFlag.ANIMATION) > 0
	End Method


	Method IsCulture:Int()
		return HasFlag(TVTProgrammeDataFlag.CULTURE) > 0
	End Method


	Method IsCult:Int()
		return HasFlag(TVTProgrammeDataFlag.CULT) > 0
	End Method


	Method IsTrash:Int()
		return HasFlag(TVTProgrammeDataFlag.TRASH) > 0
	End Method

	Method IsBMovie:Int()
		return HasFlag(TVTProgrammeDataFlag.BMOVIE) > 0
	End Method


	Method IsXRated:int()
		return HasFlag(TVTProgrammeDataFlag.XRATED) > 0
	End Method


	Method IsPaid:int()
		return HasFlag(TVTProgrammeDataFlag.PAID) > 0
	End Method


	Method IsScripted:int()
		return HasFlag(TVTProgrammeDataFlag.SCRIPTED) > 0
	End Method


	Method IsVisible:int()
		return not (HasFlag(TVTProgrammeDataFlag.INVISIBLE) > 0)
	End Method


	Method GetYear:int()
		'PAID is always "live/from now"
		if HasFlag(TVTProgrammeDataFlag.PAID) then return GetWorldTime().GetYear()

		return GetWorldTime().GetYear(releaseTime)
	End Method


	Method GetBlocks:int()
		return self.blocks
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcome:Float()
		return self.outcome
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcomeTV:Float()
		return self.outcomeTV
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
		releaseTime = GetWorldTime().MakeTime(GetYear(), dayOfYear mod GetWorldTime().GetDaysPerYear(), 0, 0)
	End Method


	Method GetPrice:int(playerID:int)
		Local value:int = 0
		local priceMod:Float = GetQuality() 'this includes age-adjustments
		local maxTopicality:Float = GetMaxTopicality()

		'=== FRESHNESS ===
		'this is ~1 yrs
		If (maxTopicality >= 0.98) Then priceMod :* 1.35
		'this is ~2 yrs
		If (maxTopicality >= 0.96) Then priceMod :* 1.30
		'this is ~3 yrs
		If (maxTopicality >= 0.93) Then priceMod :* 1.25


		'=== QUALITY FRESHNESS ===
		'A high quality programme is more expensive if very young.
		'The older the programme gets, the less important is a high
		'quality, they then all are relatively "equal"
		local highQualityIndex:Float = 0.40 * GetQualityRaw() + 0.60 * GetQualityRaw() ^ 4
		local highTopicalityIndex:Float = 0.30 * maxTopicality + 0.70 * maxTopicality ^ 4

		priceMod :* highTopicalityIndex * highQualityIndex

		'=== FLAGS ===
		'BMovies lower the price
		If Self.IsBMovie() then priceMod :* 0.95
		'Cult movies increase price
		If Self.IsCult() then priceMod :* 1.05
		'Income generating programmes (infomercials) increase the price
		If Self.IsPaid() then priceMod :* 1.30
		'Live is something more expensive as it is "exclusive"
		If Self.IsLive() then priceMod :* 1.20


		If isType(TVTProgrammeProductType.MOVIE)
			value = 25000 + 3000000 * priceMod
		 'shows, productions, series...
		Else
			value = 15000 + 2000000 * priceMod
		EndIf


		'@ 0.9:
		'variant 1: blocks-1 + x^(blocks-1)
		'variant 2: blocks * x^(blocks-1)
		'           variant 1                variant 2
		'1 Block  = 0.0 + 0.9^0 = 1.00       1 * 0.9^0 = 1
		'2 Blocks = 1.0 + 0.9^1 = 1.90       2 * 0.9^1 = 1.8
		'3 Blocks = 2.0 + 0.9^2 = 2.81       3 * 0.9^2 = 2.43
		'4 Blocks = 3.0 + 0.9^3 = 3.73       4 * 0.9^3 = 2.92
		'5 Blocks = 4.0 + 0.9^4 = 4.66       5 * 0.9^4 = 3.28
		'9 Blocks = 8.0 + 0.9^8 = 8.43       9 * 0.9^8 = 3.87
		'value :* (GetBlocks()-1 + (0.90^(GetBlocks()-1)))
		value :* GetBlocks() * 0.92^(GetBlocks()-1)


		'=== INDIVIDUAL PRICE ===
		'general data price mod
		value :* GetModifier("price")

		return value
	End Method


	Method GetPriceOld:int(playerID:int)
		Local value:int = 0
		local priceMod:Float = GetQuality() 'this includes age-adjustments


		'=== FRESHNESS ===
		'this is ~1 yrs
		If (GetMaxTopicality() >= 0.98) Then priceMod :* 1.30
		'this is ~2 yrs
		If (GetMaxTopicality() >= 0.96) Then priceMod :* 1.25
		'this is ~3 yrs
		If (GetMaxTopicality() >= 0.93) Then priceMod :* 1.20


		'=== QUALITY FRESHNESS ===
		'A high quality programme is more expensive if very young.
		'The older the programme gets, the less important is a high
		'quality, they then all are relatively "equal"
		local highQualityIndex:Float = 0.38 * GetQualityRaw() + 0.62 * GetQualityRaw() ^ 4
		local highTopicalityIndex:Float = 0.25 * GetMaxTopicality() + 0.75 * GetMaxTopicality() ^ 4

		priceMod :* highTopicalityIndex * highQualityIndex

		'=== FLAGS ===
		'BMovies lower the price
		If Self.IsBMovie() then priceMod :* 0.90
		'Cult movies increase price
		If Self.IsCult() then priceMod :* 1.05
		'Income generating programmes (infomercials) increase the price
		If Self.IsPaid() then priceMod :* 1.30


		If isType(TVTProgrammeProductType.MOVIE)
			value = 30000 + 1600000 * priceMod
		 'shows, productions, series...
		Else
			value = 25000 + 1400000 * priceMod
		EndIf


		'@ 0.9:
		'variant 1: blocks-1 + x^(blocks-1)
		'variant 2: blocks * x^(blocks-1)
		'           variant 1                variant 2
		'1 Block  = 0.0 + 0.9^0 = 1.00       1 * 0.9^0 = 1
		'2 Blocks = 1.0 + 0.9^1 = 1.90       2 * 0.9^1 = 1.8
		'3 Blocks = 2.0 + 0.9^2 = 2.81       3 * 0.9^2 = 2.43
		'4 Blocks = 3.0 + 0.9^3 = 3.73       4 * 0.9^3 = 2.92
		'5 Blocks = 4.0 + 0.9^4 = 4.66       5 * 0.9^4 = 3.28
		'9 Blocks = 8.0 + 0.9^8 = 8.43       9 * 0.9^8 = 3.87
		'value :* (GetBlocks()-1 + (0.90^(GetBlocks()-1)))
		value :* GetBlocks() * 0.92^(GetBlocks()-1)


		'=== INDIVIDUAL PRICE ===
		'general data price mod
		value :* GetModifier("price")

		return value
	End Method


	'override
	Method GetMaxTopicality:Float()
		local res:Float = 1.0

		local age:Int = 0
		local timesBroadcasted:Int = 0
		local weightAge:Float = 0.8
		local weightTimesBroadcasted:Float = 0.4

		if IsPaid()
			'always age = 0 ... so just decrease by broadcasts
			weightAge = 0.0

			'maximum of 40 broadcasts decrease up to "80%" of max topicality
			timesBroadcasted = 0.8 * Min(100, Int(GetTimesBroadcasted() * 2.5))
			weightTimesBroadcasted = 1.0

		else
			age = Max(0, GetWorldTime().GetYear() - GetYear())

			'maximum of 25 broadcasts decrease up to "50%" of max topicality
			timesBroadcasted = 0.5 * Min(100, GetTimesBroadcasted() * 4)
		endif

		'modifiers could increase or decrease influences of age/aired/...
		local ageInfluence:Float = 1.5 * age * GetModifier("topicality::age")
		local timesBroadcastedInfluence:Float = timesBroadcasted * GetModifier("topicality::timesBroadcasted")
		'by default they have no influence but programmes like sport matches
		'should loose a big bit of max topicality after the first time
		'on TV. Also they should loose topicality as soon as they are
		'no longer "live" (eg. send 1 hour later)
		local firstBroadcastInfluence:Float = 10 * (timesBroadcasted>0) * GetModifier("topicality::firstBroadcastDone", 0.0)
		local notLiveInfluence:Float = 10 * timesBroadcasted * GetModifier("topicality::notLive", 0.0)

		'cult-movies are less affected by aging or broadcast amounts
		If Self.IsCult()
			ageInfluence :* 0.75
			timesBroadcastedInfluence :* 0.50
		EndIf

		local influencePercentage:Float = 0.01 * MathHelper.Clamp(weightAge * ageInfluence + notLiveInfluence + firstBroadcastInfluence + weightTimesBroadcasted * timesBroadcastedInfluence, 0, 100)
		return 1.0 - THelper.ATanFunction(influencePercentage, 2)
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


	'returns a value describing how strong the cast's popularity
	'modifies the quality of the programme -> perceivedQuality
	Method GetCastQualityMod:Float()
	End Method


	Method GetQualityRaw:Float()
		Local genreDef:TMovieGenreDefinition = GetGenreDefinition()
		local quality:Float = 0.0

		quality :+ GetReview() * genreDef.ReviewMod
		quality :+ GetSpeed() * genreDef.SpeedMod

		If GetOutcome() > 0
			quality :+ GetOutcome() * genreDef.OutcomeMod
		'tv uses same mod
		ElseIf GetOutcomeTV() > 0
			quality :+ GetOutcomeTV() * genreDef.OutcomeMod
		'if no outcome was defined, increase weight of the other parts
		'increase quality according to their weight to the outcome mod
		ElseIf genreDef.OutcomeMod > 0 And genreDef.OutcomeMod < 1.0
			local add:Float = FixOutcome(genreDef)

			quality :+ add
		EndIf
		'if quality < 0 then Notify("Quality of your programme data ~q" + GetGUID()+ "~q is negative. Please mail savegame to developers.")
		'FIX: 5.0 is an arbitrary value to limit values of broken savegames
		'     can get removed 2019 or later
		Return MathHelper.Clamp(quality, 0, 5.0)
	End Method



	'returns the perceived quality of the programme
	'replaces "GetBaseAudienceQuote"
	Method GetQuality:Float() {_exposeToLua}
		Local quality:Float = 1.0

		'the older the less ppl want to watch - 1 year = 0.985%, 2 years = 0.97%...
		Local age:Float = 0.015 * Max(0, 100 - Max(0, GetWorldTime().GetYear() - GetYear()) )
		quality :* Max(0.20, age)


		'the more the programme got repeated, the lower the quality in
		'that moment (^2 increases loss per air)
		'but a "good movie" should benefit from being good - so the
		'influence of repetitions gets lower by higher raw quality
		'-> a movie with 100% base quality will have at least 10% of
		'   quality no matter how many times it got aired
		quality :* GetQualityRaw() * (0.10 + 0.90 * GetTopicality()^2)

		Return MathHelper.Clamp(quality, 0.01, 1.0)
	End Method


	'override
	Method CutTopicality:Float(cutModifier:float=1.0) {_private}
		'for the calculation we need to know what to cut, not what to keep
		local toCut:Float =  (1.0 - cutModifier)
		local minimumRelativeCut:Float = 0.20 '20%
		local minimumAbsoluteCut:Float = 0.15 '15%
		local baseCut:Float = 0.10 '10%

		rem

		  toCut
		    |          _/
		    |        _/
		    |      _/
		    |_____/____________________ minimumAbsoluteCut
		    |  _/
		    | /
		    ||
		    ||                          basecut
		    ||_________________________
		                    cutModifier

		endrem



		'calculate base value (if mod was "1.0" or 100%)
		toCut :* GetProgrammeDataCollection().wearoffFactor

		'cutModifier can be used to manipulate the resulting cut
		'ex. for night times, for low audience...
		toCut :* GetGenreWearoffModifier()
		toCut :* GetFlagsWearoffModifier()
		toCut :* GetWearoffModifier()

		toCut = Max(toCut, minimumRelativeCut)

		toCut = toCut*(1.0-baseCut) + baseCut

		'take care of minimumCut and switch back to "what to cut"
		cutModifier = 1.0 - MathHelper.Clamp(toCut, minimumAbsoluteCut, 1.0)

		'take care of minimumCut and switch back to "what to cut"
		Return Super.CutTopicality( cutModifier )
	End Method


	Method CutTrailerTopicality:Float(cutModifier:Float = 1.0) {_private}
		'for the calculation we need to know what to cut, not what to keep
		local toCut:Float =  (1.0 - cutModifier)
		local minimumRelativeCut:Float = 0.10 '10%
		local minimumAbsoluteCut:Float = 0.10 '10%

		'calculate base value (if mod was "1.0" or 100%)
		toCut :* GetProgrammeDataCollection().trailerWearoffFactor

		'cutModifier can be used to manipulate the resulting cut
		'ex. for night times, for low audience...
		toCut :* GetGenreWearoffModifier()
		toCut :* GetFlagsWearoffModifier()
		toCut :* GetTrailerWearoffModifier()

		toCut = Max(toCut, minimumRelativeCut)

		'take care of minimumCut and switch back to "what to cut"
		cutModifier = 1.0 - MathHelper.Clamp(toCut, minimumAbsoluteCut, 1.0)

		'(trailers do not inherit "aged" topicality, so 1 is max)
		trailerTopicality = GetTrailerTopicality()
		trailerTopicality = MathHelper.Clamp(trailerTopicality * cutModifier, 0.0, 1.0)

		Return trailerTopicality
	End Method


	'override
	Method RefreshTopicality:Float(refreshModifier:Float = 1.0) {_private}
		local minimumRelativeRefresh:Float = 1.10 '110%
		local minimumAbsoluteRefresh:Float = 0.10 '10%

		refreshModifier :* GetProgrammeDataCollection().refreshFactor
		refreshModifier :* GetRefreshModifier()
		refreshModifier :* GetGenreRefreshModifier()
		refreshModifier :* GetFlagsRefreshModifier()

		refreshModifier = Max(refreshModifier, minimumRelativeRefresh)
		topicality = GetTopicality() 'limit to max topicality

		topicality :+ Max(topicality * (refreshModifier-1.0), minimumAbsoluteRefresh)
		topicality = MathHelper.Clamp(topicality, 0, GetMaxTopicality())

		Return topicality
	End Method


	Method RefreshTrailerTopicality:Float(refreshModifier:Float = 1.0) {_private}
		local minimumRelativeRefresh:Float = 1.10 '110%
		local minimumAbsoluteRefresh:Float = 0.10 '10%

		refreshModifier :* GetProgrammeDataCollection().trailerRefreshFactor
		refreshModifier :* GetTrailerRefreshModifier()
		refreshModifier :* GetGenreRefreshModifier()
		refreshModifier :* GetFlagsRefreshModifier()

		refreshModifier = Max(refreshModifier, minimumRelativeRefresh)

		trailerTopicality = GetTrailerTopicality() 'account for limits
		trailerTopicality :+ Max(trailerTopicality * (refreshModifier-1.0), minimumAbsoluteRefresh)
		trailerTopicality = MathHelper.Clamp(trailerTopicality, 0, 1.0)

		Return trailerTopicality
	End Method


	Method GetTargetGroupAttractivityMod:TAudience()
		return targetGroupAttractivityMod
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
	Method GetTimesTrailerAired:Int()
		return self.trailerAired
	End Method


	Method SetTimesTrailerAiredSinceLastBroadcast:int(amount:int, playerID:int=-1)
		if playerID = -1 then playerID = owner
		if playerID <= 0 or playerID > TVTPlayerCount then return False
		if playerID > self.trailerAiredSinceLastBroadcast.length then self.trailerAiredSinceLastBroadcast = self.trailerAiredSinceLastBroadcast[.. playerID]

		self.trailerAiredSinceLastBroadcast[playerID-1] = amount
		return True
	End Method


	Method GetTimesTrailerAiredSinceLastBroadcast:int(playerID:int)
		if playerID <= 0 or playerID > self.trailerAiredSinceLastBroadcast.length then return 0

		return self.trailerAiredSinceLastBroadcast[playerID-1]
	End Method


	'return a value between 0 - 1.0
	'describes how much of a potential trailer-bonus of 100% was reached
	Method GetTrailerMod:TAudience(playerID:int, createIfMissing:int = True)
		if playerID <= 0 or playerID > TVTPlayerCount then return null
		if playerID > self.trailerMods.length
			if not createIfMissing then return null
			'resize
			self.trailerMods = self.trailerMods[.. playerID]
		endif

		if not self.trailerMods[playerID-1] and createIfMissing
			self.trailerMods[playerID-1] = new TAudience
		endif

		return self.trailerMods[playerID-1]
	End Method


	Method RemoveTrailerMod:int(playerID:int)
		if playerID <= 0 or playerID > self.trailerMods.length then return False
		self.trailerMods[playerID-1] = null
	End Method


	'override
	Method IsAvailable:int()
		'live programme is available 10 days before

		if IsLive()
			if GetWorldTime().GetDay() + 10 >= GetWorldTime().GetDay(releaseTime)
				return True
			else
				return False
			endif
		endif

		if not isReleased() then return False

		return Super.IsAvailable()
	End Method


	Method isReleased:int()
		'call-in shows are kind of "live"
		if HasFlag(TVTProgrammeDataFlag.PAID) then return True

		if not ignoreUnreleasedProgrammes then return True

		return GetWorldTime().GetTimeGone() >= releaseTime
	End Method


	Method isInCinema:int()
		'live programme is never in a cinema
		if IsLive() then return False

		if isReleased() then return False
		' without stored outcome, the movie wont run in the cinemas
		if outcome <= 0 then return False

		return GetCinemaReleaseTime() <= GetWorldTime().GetTimeGone()
	End Method


	Method isInProduction:int()
		'live programme is never "in production"
		if IsLive() then return False

		if isReleased() then return False

		return GetProductionStartTime() <= GetWorldTime().GetTimeGone() and GetCinemaReleaseTime() > GetWorldTime().GetTimeGone()
	End Method


	Method isCustomProduction:int() {_exposeToLua}
		return producedByPlayerID <> 0
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


	Method FixOutcome:int(genreDef:TMovieGenreDefinition = null)
		if not genreDef then genreDef = GetGenreDefinition()

		local newOutcome:Float = 0
		If genreDef.ReviewMod > 0
			newOutcome :+ (genreDef.ReviewMod / (1.0 - genreDef.OutcomeMod) ) - genreDef.ReviewMod
		EndIf
		If genreDef.SpeedMod > 0
			newOutcome :+ (genreDef.SpeedMod / (1.0 - genreDef.OutcomeMod) ) - genreDef.SpeedMod
		EndIf


		if IsTVDistribution() and GetOutcomeTV() <= 0
			if GetOutcome() > 0
				outcomeTV = GetOutcome()
			else
				'print "FIX TV : "+GetTitle()+"  new:"+newOutcome
				outcomeTV = newOutcome
			endif
			outcome = 0
		elseif not IsTVDistribution() and GetOutcome() <= 0
			if GetOutcomeTV() > 0
				outcome = GetOutcomeTV()
			else
				'print "FIX CIN: "+GetTitle()+"  new:"+newOutcome
				outcome = newOutcome
			endif
			outcomeTV = 0
		endif

		return newOutcome
	End Method


	Method onProductionStart:int(time:Long = 0)
		'trigger effects/modifiers
		local params:TData = new TData.Add("source", self)
		effects.Update("productionStart", params)

		return True
	End Method


	Method onCinemaRelease:int(time:Long = 0)
		if IsLive() then return False

		if not isHeader()
			onFinishProductionForCast()
		endif

		return True
	End Method


	Method onRelease:int(time:Long = 0)
		return True
	End Method


	'inform each person in the cast that the production finished
	Method onFinishProductionForCast:int(time:Long = 0)
		'already done
		if finishedProductionForCast then return False

		if GetCast()
			For local job:TProgrammePersonJob = eachIn GetCast()
				local person:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID( job.personGUID )
				if person then person.FinishProduction(GetGUID(), job.job)
			Next
		endif

		finishedProductionForCast = True
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
	'called as soon as the last block of a programme ends
	Method doFinishBroadcast(playerID:int = -1, broadcastType:int = 0)
		'mark broadcasting state
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if playerID > 0
				SetPlayerIsBroadcasting(playerID, False)
				'reset of live in all cases
				SetPlayerIsLiveBroadcasting(playerID, False)
			endif
		endif

		'=== BROADCAST LIMITS ===
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if broadcastLimit > 0 then broadcastLimit :- 1
		endif


		'=== EFFECTS ===
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("source", self).AddNumber("playerID", playerID)

		'send as programme
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast - after "onFinishBroadcasting"-call)
			if GetTimesBroadcasted() = 0
				If not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE)
					effects.Update("broadcastFirstTimeDone", effectParams)
					setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE, True)
				endif
			endif

			effects.Update("broadcastDone", effectParams)

		'send as trailer
		elseif broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			if GetTimesTrailerAired() = 0
				If not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL_DONE)
					effects.Update("broadcastFirstTimeTrailerDone", effectParams)
					setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL_DONE, True)
				endif
			endif

			effects.Update("broadcastTrailerDone", effectParams)
		endif
	End Method


	'override
	'called as soon as the last block of a programme ends
	Method doAbortBroadcast(playerID:int = -1, broadcastType:int = 0)
		'mark broadcasting state
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if playerID > 0
				SetPlayerIsBroadcasting(playerID, False)
				'reset of live in all cases
				SetPlayerIsLiveBroadcasting(playerID, False)
			endif
		endif


		'=== EFFECTS ===
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("source", self).AddNumber("playerID", playerID)

		'send as programme
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			effects.Update("broadcastAborted", effectParams)

		'send as trailer
		elseif broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			effects.Update("broadcastTrailerAborted", effectParams)
		endif
	End Method


	'override
	'called as soon as the programme is broadcasted
	Method doBeginBroadcast(playerID:int = -1, broadcastType:int = 0)
		'mark broadcasting state
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if playerID > 0
				SetPlayerIsBroadcasting(playerID, True)
				'if broadcasting right at live time - mark it
				if isLive() and GetWorldTime().GetDayHour() = GetWorldTime().GetDayHour( releaseTime )
					SetPlayerIsLiveBroadcasting(playerID, True)
				endif
			endif
		endif


		'=== EFFECTS ===
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("source", self).AddNumber("playerID", playerID)

		'send as programme
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast - after "onFinishBroadcasting"-call)
			if GetTimesBroadcasted() = 0
				If not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME)
					effects.Update("broadcastFirstTime", effectParams)
					setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME, True)
				endif
			endif

			effects.Update("broadcast", effectParams)

		'send as trailer
		elseif broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			if GetTimesTrailerAired() = 0
				If not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL)
					effects.Update("broadcastFirstTimeTrailer", effectParams)
					setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL, True)
				endif
			endif

			effects.Update("broadcastTrailer", effectParams)
		endif
	End Method


End Type