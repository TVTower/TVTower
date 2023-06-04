Rem
	===========================================================
	code for programme-objects (movies, ..) in programme planning
	===========================================================
ENDREM
SuperStrict
Import "Dig/base.util.localization.bmx"
Import "game.player.difficulty.bmx"
Import "game.world.worldtime.bmx"
Import "game.person.base.bmx"
Import "game.broadcast.genredefinition.movie.bmx"
Import "game.broadcastmaterialsource.base.bmx"
Import "game.gameconstants.bmx"
Import "basefunctions.bmx"
Import "game.stationmap.bmx"

Type TProgrammeDataCollection Extends TGameObjectCollection

	'factor by what a programmes topicality DECREASES by sending it
	'(with whole audience, so 100%, watching)
	'a value > 1.0 means, it decreases to 0 with less than 100% watching
	'ex.: 0.9 = 10% cut, 0.85 = 15% cut
	Field wearoffFactor:Float = 1.25
	'factor by what a programmes topicality INCREASES by a day switch
	'ex.: 1.0 = 0%, 1.5 = add 50%y
	Field refreshFactor:Float = 1.4

	'factor by what a trailer topicality DECREASES by sending it
	'2.0 means, it reaches 0 with 50% audience/area quote
	Field trailerWearoffFactor:Float = 0.5
	'factor by what a trailer topicality INCREASES by broadcasting
	'the programme
	Field trailerRefreshFactor:Float = 1.4
	'helper data
	Field _unreleasedProgrammeData:TList {nosave}
	Field _liveProgrammeData:TList {nosave}
	Field _dynamicDataProgrammeData:TList {nosave}
	Field _finishedProductionProgrammeData:TList {nosave}

	Global _instance:TProgrammeDataCollection
	Global _eventListeners:TEventListenerBase[]


	Function GetInstance:TProgrammeDataCollection()
		If Not _instance Then _instance = New TProgrammeDataCollection
		Return _instance
	End Function


	Method New()
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction( "App.onSetLanguage", onSetLanguage ) ]
	End Method


	Method Initialize:TProgrammeDataCollection()
		Super.Initialize()

		_InvalidateCaches()

		Return Self
	End Method


	Method _InvalidateCaches()
		_unreleasedProgrammeData = Null
		_liveProgrammeData = Null
		_dynamicDataProgrammeData = Null
		_finishedProductionProgrammeData = Null
	End Method


	Method Add:Int(obj:TGameObject)
		_InvalidateCaches()
		Return Super.Add(obj)
	End Method


	Method Remove:Int(obj:TGameObject)
		_InvalidateCaches()
		Return Super.Remove(obj)
	End Method


	Method GetByID:TProgrammeData(ID:Int)
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
		If Not _unreleasedProgrammeData
			_unreleasedProgrammeData = CreateList()
			For Local data:TProgrammeData = EachIn entries.Values()
				If data.IsReleased() Then Continue

				_unreleasedProgrammeData.AddLast(data)
			Next

			'order by release
			_unreleasedProgrammeData.Sort(True, _SortByReleaseTime)
		EndIf

		Return _unreleasedProgrammeData
	End Method


	'returns (and creates if needed) a list containing only live
	'programmeData
	Method GetLiveProgrammeDataList:TList()
		If Not _liveProgrammeData
			_liveProgrammeData = CreateList()
			For Local data:TProgrammeData = EachIn entries.Values()
				'If data.IsHeader() Then Continue
				If Not data.IsLive() Then Continue

				_liveProgrammeData.AddLast(data)
			Next

			'order by release
			_liveProgrammeData.Sort(True, _SortByReleaseTime)
		EndIf

		Return _liveProgrammeData
	End Method


	'returns (and creates if needed) a list containing only programmeData
	'with dynamic data (eg. text descriptions of live-programme-headers)
	Method GetDynamicDataProgrammeDataList:TList()
		If Not _dynamicDataProgrammeData
			_dynamicDataProgrammeData = CreateList()
			For Local data:TProgrammeData = EachIn entries.Values()
				If Not data.HasDynamicData() Then Continue

				_dynamicDataProgrammeData.AddLast(data)
			Next
		EndIf

		Return _dynamicDataProgrammeData
	End Method


	'returns (and creates if needed) a list containing only entries
	'with finished production (= released or in cinema)
	Method GetFinishedProductionProgrammeDataList:TList()
		If Not _finishedProductionProgrammeData
			_finishedProductionProgrammeData = CreateList()
			For Local data:TProgrammeData = EachIn entries.Values()
				If data.IsHeader() Then Continue
				If Not data.IsReleased() And Not data.IsInCinema() Then Continue

				_finishedProductionProgrammeData.AddLast(data)
			Next

			'order by release
			_finishedProductionProgrammeData.Sort(True, _SortByReleaseTime)
		EndIf

		Return _finishedProductionProgrammeData
	End Method


	Method GetGenreRefreshModifier:Float(genre:Int)
		'values get multiplied with the refresh factor
		'so this means: higher (>1.0) values increase the resulting
		'topicality win
		Select genre
			Case TVTProgrammeGenre.Adventure
				Return 1.0
			Case TVTProgrammeGenre.Action
				Return 1.0
			Case TVTProgrammeGenre.Animation
				Return 1.1
			Case TVTProgrammeGenre.Crime
				Return 1.0
			Case TVTProgrammeGenre.Comedy
				Return 1.25
			Case TVTProgrammeGenre.Documentary
				Return 1.1
			Case TVTProgrammeGenre.Drama
				Return 1.05
			Case TVTProgrammeGenre.Erotic
				Return 1.1
			Case TVTProgrammeGenre.Family
				Return 1.15
			Case TVTProgrammeGenre.Fantasy
				Return 1.1
			Case TVTProgrammeGenre.History
				Return 1.0
			Case TVTProgrammeGenre.Horror
				Return 1.0
			Case TVTProgrammeGenre.Monumental
				Return 0.95
			Case TVTProgrammeGenre.Mystery
				Return 0.95
			Case TVTProgrammeGenre.Romance
				Return 1.1
			Case TVTProgrammeGenre.Scifi
				Return 0.95
			Case TVTProgrammeGenre.Thriller
				Return 1.0
			Case TVTProgrammeGenre.Western
				Return 0.95
			Case TVTProgrammeGenre.Show, ..
			     TVTProgrammeGenre.Show_Politics, ..
			     TVTProgrammeGenre.Show_Music
				Return 0.90
			Case TVTProgrammeGenre.Event, ..
			     TVTProgrammeGenre.Event_Politics, ..
			     TVTProgrammeGenre.Event_Music, ..
			     TVTProgrammeGenre.Event_Sport, ..
			     TVTProgrammeGenre.Event_Showbiz
				Return 0.90
			Case TVTProgrammeGenre.Feature, ..
			     TVTProgrammeGenre.Feature_YellowPress
				Return 0.95
			Default
				Return 1.0
		End Select
	End Method


	Method GetGenreWearoffModifier:Float(genre:Int)
		'values get multiplied with the wearOff factor
		'so this means: higher (>1.0) values increase the resulting
		'topicality loss
		Select genre
			Case TVTProgrammeGenre.Adventure
				Return 1.0
			Case TVTProgrammeGenre.Action
				Return 1.05
			Case TVTProgrammeGenre.Animation
				Return 1.0
			Case TVTProgrammeGenre.Crime
				Return 1.05
			Case TVTProgrammeGenre.Comedy
				Return 0.90
			Case TVTProgrammeGenre.Documentary
				Return 0.85
			Case TVTProgrammeGenre.Drama
				Return 0.95
			Case TVTProgrammeGenre.Erotic
				Return 0.80
			Case TVTProgrammeGenre.Family
				Return 0.85
			Case TVTProgrammeGenre.Fantasy
				Return 1.05
			Case TVTProgrammeGenre.History
				Return 1.0
			Case TVTProgrammeGenre.Horror
				Return 1.0
			Case TVTProgrammeGenre.Monumental
				Return 1.1
			Case TVTProgrammeGenre.Mystery
				Return 1.05
			Case TVTProgrammeGenre.Romance
				Return 1.0
			Case TVTProgrammeGenre.Scifi
				Return 1.10
			Case TVTProgrammeGenre.Thriller
				Return 1.05
			Case TVTProgrammeGenre.Western
				Return 1.10
			Case TVTProgrammeGenre.Show, ..
			     TVTProgrammeGenre.Show_Politics, ..
			     TVTProgrammeGenre.Show_Music
				Return 1.10
			Case TVTProgrammeGenre.Event, ..
			     TVTProgrammeGenre.Event_Politics, ..
			     TVTProgrammeGenre.Event_Music, ..
			     TVTProgrammeGenre.Event_Sport, ..
			     TVTProgrammeGenre.Event_Showbiz
				Return 1.15
			Case TVTProgrammeGenre.Feature, ..
			     TVTProgrammeGenre.Feature_YellowPress
				Return 1.05
			Default
				Return 1.0
		End Select
	End Method


	'amount the wearoff effect gets reduced/increased by programme flags
	Method GetFlagsWearoffModifier:Float(flags:Int)
		'values get multiplied with the wearOff factor
		'so this means: higher (>1.0) values increase the resulting
		'topicality loss

		Local flagMod:Float = 1.0
		If flags & TVTProgrammeDataFlag.LIVE Then flagMod :* 1.25
		'if flags & TVTProgrammeDataFlag.ANIMATION then flagMod :* 1.0
		If flags & TVTProgrammeDataFlag.CULTURE Then flagMod :* 0.95
		If flags & TVTProgrammeDataFlag.CULT Then flagMod :* 0.85
		If flags & TVTProgrammeDataFlag.TRASH Then flagMod :* 1.10
		If flags & TVTProgrammeDataFlag.BMOVIE Then flagMod :* 1.15
		'if flags & TVTProgrammeDataFlag.XRATED then flagMod :* 1.0
		If flags & TVTProgrammeDataFlag.PAID Then flagMod :* 1.30
		'if flags & TVTProgrammeDataFlag.SERIES then flagMod :* 1.0
		If flags & TVTProgrammeDataFlag.SCRIPTED Then flagMod :* 1.15

		Return flagMod
	End Method


	'amount the refresh effect gets reduced/increased by programme flags
	Method GetFlagsRefreshModifier:Float(flags:Int)
		'values get multiplied with the refresh factor
		'so this means: higher (>1.0) values increase the resulting
		'refresh value

		Local flagMod:Float = 1.0
		If flags & TVTProgrammeDataFlag.LIVE Then flagMod :* 0.75
		'if flags & TVTProgrammeDataFlag.ANIMATION then flagMod :* 1.0
		If flags & TVTProgrammeDataFlag.CULTURE Then flagMod :* 1.1
		If flags & TVTProgrammeDataFlag.CULT Then flagMod :* 1.2
		If flags & TVTProgrammeDataFlag.TRASH Then flagMod :* 1.05
		If flags & TVTProgrammeDataFlag.BMOVIE Then flagMod :* 1.05
		'if flags & TVTProgrammeDataFlag.XRATED then flagMod :* 1.0
		If flags & TVTProgrammeDataFlag.PAID Then flagMod :* 0.85
		'if flags & TVTProgrammeDataFlag.SERIES then flagMod :* 1.0
		If flags & TVTProgrammeDataFlag.SCRIPTED Then flagMod :* 0.90

		Return flagMod
	End Method


	Method RefreshTopicalities:Int()
		For Local data:TProgrammeData = EachIn entries.Values()
			data.RefreshTopicality()
			data.RefreshTrailerTopicality()
		Next
	End Method


	'helper for external callers so they do not need to know
	'the internal structure of the collection
	Method RefreshUnreleased:Int()
		_unreleasedProgrammeData = Null
		GetUnreleasedProgrammeDataList()
	End Method


	Method SetProgrammeDataState(data:TProgrammeData, state:Int)
		Select state
			Case TVTProgrammeState.IN_PRODUCTION
				'

			Case TVTProgrammeState.IN_CINEMA
				'invalidate previous cache
				'_inProductionProgrammeData = Null

			Case TVTProgrammeState.RELEASED
				'invalidate previous cache
				'_inCinemaProgrammeData = Null

				_unreleasedProgrammeData = Null
		End Select
	End Method


	'updates just unreleased programmes (checks for new states)
	'so: unreleased -> production (->cinema) -> released
	Method UpdateUnreleased:Int()
		Local unreleased:TList = GetUnreleasedProgrammeDataList()
		Local now:Long = GetWorldTime().GetTimeGone()
		For Local pd:TProgrammeData = EachIn unreleased
			pd.Update()
			'data is sorted by production start, so as soon as the
			'production start of an entry is in the future, all entries
			'coming after it will be even later and can get skipped
			If pd.GetProductionStartTime() > now Then Exit
		Next
	End Method


	'updates live programmes (checks if they aired now)
	Method UpdateLive:Int()
		Local live:TList = GetLiveProgrammeDataList()
		Local invalidate:Int = False

		For Local pd:TProgrammeData = EachIn live
			'skip not yet started ones
			If pd.GetReleaseTime() > GetWorldTime().GetTimeGone() Then Exit

			If pd.IsLive()
				'update eg. title/description, returns true if live status changed
				if pd.UpdateLive(False) Then invalidate = True
			EndIf
		Next
		If invalidate Then _liveProgrammeData = Null
	End Method


	'updates programmes with dynamic data (descriptions, values...)
	Method UpdateDynamicData:Int()
		Local dynamicList:TList = GetDynamicDataProgrammeDataList()
		Local invalidate:Int = False

		For Local pd:TProgrammeData = EachIn dynamicList
			'update description or other data, returns true if no longer contains
			'dynamic data-status was changed (= no longer dynamic)
			if pd.UpdateDynamicData() Then invalidate = True
		Next
		If invalidate Then _dynamicDataProgrammeData = Null
	End Method


	'updates all programmes programmes (checks for new states)
	'call this after a game start to set all "old programmes" to be
	'finished
	Method UpdateAll:Int()
		Local now:Long = GetWorldTime().GetTimeGone()
		For Local pd:TProgrammeData = EachIn entries.Values()
			pd.Update()
		Next
	End Method


	Method RemoveReplacedPlaceholderCaches()
		For Local data:TProgrammeData = EachIn entries.Values()
			data.titleProcessed = Null
			data.descriptionProcessed = Null
			data.cachedActors = data.cachedActors[..0]
			data.cachedDirectors = data.cachedDirectors[..0]
		Next
	End Method



	Function _SortByReleaseTime:Int(o1:Object, o2:Object)
		Local p1:TProgrammeData = TProgrammeData(o1)
		Local p2:TProgrammeData = TProgrammeData(o2)
		If Not p2 Then Return 1
	
        If p1.releaseTime > p2.releaseTime
			Return 1
        ElseIf p1.releaseTime < p2.releaseTime
			Return -1
		Else
			Return _SortByName(o1, o2)
		EndIf
	End Function


	Function _SortByName:Int(o1:Object, o2:Object)
		Local p1:TProgrammeData = TProgrammeData(o1)
		Local p2:TProgrammeData = TProgrammeData(o2)
		If Not p2 Then Return 1
		If Not p1 Then Return -1

		'remove "ToLower" for case sensitive comparison
		Local t1:String = p1.GetTitle().ToLower()
		Local t2:String = p2.GetTitle().ToLower()
		
		If t1 = t2
			Return p1.GetGUID() > p2.GetGUID()
        ElseIf t1 > t2
			Return 1
        ElseIf t1 < t2
			Return -1
		endif
		return 0
	End Function

	'=== EVENT HANDLERS ===
	Function onSetLanguage:int( triggerEvent:TEventBase )
		GetInstance().RemoveReplacedPlaceholderCaches()
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeDataCollection:TProgrammeDataCollection()
	Return TProgrammeDataCollection.GetInstance()
End Function





'raw data for movies, episodes (series)
'but also series-headers, collection-headers,...
Type TProgrammeData Extends TBroadcastMaterialSource {_exposeToLua}
	'Field originalTitle:TLocalizedString
	'contains the title with placeholders replaced
	Field titleProcessed:TLocalizedString {nosave}
	Field descriptionProcessed:TLocalizedString {nosave}


	'array holding actor(s) and director(s) and ...
	Field cast:TPersonProductionJob[]
	Field country:String = "UNK"

	'fine grained attractivity for target groups (splitted gender)
	Field targetGroupAttractivityMod:TAudience = Null
	'special targeted audiences?
	Field targetGroups:Int = 0
	Field proPressureGroups:Int = 0
	Field contraPressureGroups:Int = 0
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
	Field parentGUID:String
	'TVTProgrammeDataType-value
	'(eg. "SERIES" for series-headers, or "SINGLE" for a movie)
	Field dataType:Int = 0

	'guid of a potential franchise entry (for now only one franchise per
	'franchisee)
	Field franchiseGUID:String
	'programmes descending from this programme (eg. "Lord of the Rings"
	'as "franchise" and the individual programmes as "franchisees"
	Field franchisees:String[]

	'which kind of distribution was used? Cinema, Custom production ...
	Field distributionChannel:Int = 0
	'ID according to TVTProgrammeProductType
	Field productType:Int = 1
	'at which day was the programme released?
	'for live shows this is the time of the live event (if fixed)
	Field releaseTime:Long = -1
	'announced in news etc?
	Field releaseAnnounced:Int = False
	Field finishedProductionForCast:Int = False
	'state of the programme (in production, cinema, released...)
	Field state:Int = 0
	'bitmask for all players whether they currently broadcast it
	Field playersBroadcasting:Int
	Field playersLiveBroadcasting:Int

	Field maxTopicalityCache:Float {nosave}
	Field maxTopicalityCacheCode:String {nosave}
	Field priceCache:Int {nosave}
	Field priceCacheCode:String {nosave}

	'=== trailer data ===
	'=== shared
	'this data is shared along multiple licences (so maybe players)!
	Field trailerTopicality:Float = 1.0
	Field trailerMaxTopicality:Float = 1.0
	'times the trailer aired in total
	Field trailerAired:Int = 0
	'=== individual
	'times the trailer aired since the programme was shown "normal"
	Field trailerAiredSinceLastBroadcast:Int[]
	Field trailerMods:TAudience[]


	Field cachedActors:TPersonBase[] {nosave}
	Field cachedDirectors:TPersonBase[] {nosave}
	Field genreDefinitionCache:TMovieGenreDefinition = Null {nosave}

	Field extra:TData

	'hide movies of 2012 when in 1985?
	Global ignoreUnreleasedProgrammes:Int = True
	Global _filterReleaseDateStart:Int = 1900
	Global _filterReleaseDateEnd:Int = 2100

	Global modKeyTopicality_RefreshLS:TLowerString = New TLowerString.Create("topicality::refresh")
	Global modKeyTopicality_TrailerRefreshLS:TLowerString = New TLowerString.Create("topicality::trailerRefresh")
	Global modKeyTopicality_TrailerWearoffLS:TLowerString = New TLowerString.Create("topicality::trailerWearoff")
	Global modKeyCallIn_PerViewerRevenueLS:TLowerString = New TLowerString.Create("callin::perViewerRevenue")
	Global modKeyTopicality_FirstBroadcastDoneLS:TLowerString = New TLowerString.Create("topicality::firstBroadcastDone")
	Global modKeyTopicality_NotLiveLS:TLowerString = New TLowerString.Create("topicality::notLive")

	Rem
	"modifiers" : extra data block containing various information (if set)

	"topicality::age" - influence of the age on the max topicality
	"topicality::timesBroadcasted" - influence of the broadcast amount to max topicality
	"price"
	"wearoff" - changes how much a programme loses during sending it
	"refresh" - changes how much a programme "regenerates" (multiplied with genreModifier)
	endrem

	Method GenerateGUID:String()
		Return "broadcastmaterialsource-programmedata-"+id
	End Method


	Function setIgnoreUnreleasedProgrammes(ignore:Int=True, releaseStart:Int=1900, releaseEnd:Int=2100)
		ignoreUnreleasedProgrammes = ignore
		_filterReleaseDateStart = releaseStart
		_filterReleaseDateEnd = releaseEnd
	End Function

	'what to earn for each viewer
	Method GetPerViewerRevenue:Float(forPlayer:Int) {_exposeToLua}
		'TODO caching somehow? - topicality and reach can change
		Local result:Float = 0.0
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
		EndIf
		If result > 0
			Local population:Int = 1000
			Local reach:Int = population
			If forPlayer > 0 
				population = GetStationMapCollection().GetPopulation()
				reach = GetStationMap(forPlayer, True).GetReach()
				result = result * (1 - 0.85 * Float(reach) / population)
				'TODO replace with own difficulty value
				result:*  GetPlayerDifficulty(forPlayer).adcontractProfitMod
			EndIf
		EndIf
		Return result
	End Method


	Method ClearCast:Int()
		cast = New TPersonProductionJob[0]

		'invalidate caches
		cachedActors = cachedActors[..0]
		cachedDirectors = cachedDirectors[..0]

		Return True
	End Method


	Method AddCast:Int(job:TPersonProductionJob)
		If HasCast(job) Then Return False

		cast :+ [job]

		'invalidate caches
		cachedActors = cachedActors[..0]
		cachedDirectors = cachedDirectors[..0]
		Return True
	End Method


	Method RemoveCast:Int(job:TPersonProductionJob)
		If Not HasCast(job) Then Return False
		If cast.Length = 0 Then Return False

		Local newCast:TPersonProductionJob[]
		For Local j:TPersonProductionJob = EachIn cast
			'skip our job
			If job.personID = j.personID And job.job = j.job Then Continue
			'add rest
			newCast :+ [j]
		Next
		cast = newCast

		'invalidate caches
		cachedActors = cachedActors[..0]
		cachedDirectors = cachedDirectors[..0]

		Return True
	End Method


	Method GetCastPopularity:Float()
		Local res:Float = 0.0
		Local castCount:Int = 0

		For Local job:TPersonProductionJob = EachIn cast
			Local p:TPersonBase = GetPersonBase(job.personID)
			If Not p Then Continue
			res :+ p.GetPopularityValue()
			castCount :+ 1
		Next
		If castCount > 0 Then res = res / castCount

		'return a value between -1 and 1
		Return MathHelper.Clamp(res / 100.0, -2.0, 2.0 )
	End Method


	Method GetCastFame:Float()
		Local res:Float = 0.0
		Local castCount:Int = 0

		For Local job:TPersonProductionJob = EachIn cast
			Local p:TPersonBase = GetPersonBase(job.personID)
			If Not p Then Continue
			res :+ p.GetPersonalityData().GetAttributeValue(TVTPersonPersonalityAttribute.FAME)
			castCount :+ 1
		Next
		If castCount > 0 Then res = res / castCount

		'return a value between 0 and 1
		Return MathHelper.Clamp(res, 0.0, 1.0 )
	End Method


	Method HasCastPerson:Int(personID:Int, job:Int = -1)
		If job >= 0
			For Local doneJob:TPersonProductionJob = EachIn cast
				If doneJob.job & job <= 0 Then Continue

				If doneJob.personID = personID Then Return True
			Next
		Else
			For Local doneJob:TPersonProductionJob = EachIn cast
				If doneJob.personID = personID Then Return True
			Next
		EndIf
		Return False
	End Method


	Method HasCast:Int(job:TPersonProductionJob, checkRoleID:Int = True)
		'do not check job against jobs in the list, as only the
		'content might be the same but the job a duplicate
		For Local doneJob:TPersonProductionJob = EachIn cast
			If job.personID <> doneJob.personID Then Continue
			If job.job <> doneJob.job Then Continue
			If checkRoleID And job.roleID <> doneJob.roleID Then Continue

			Return True
		Next
		Return False
	End Method


	Method GetCast:TPersonProductionJob[]()
		Return cast
	End Method


	Method GetCastAtIndex:TPersonProductionJob(index:Int=0)
		If index < 0 Or index >= cast.length Then Return Null
		Return cast[index]
	End Method


	Method GetCastGroup:TPersonBase[](jobFlag:Int)
		Local res:TPersonBase[0]
		For Local job:TPersonProductionJob = EachIn cast
			If job.job & jobFlag
				res :+ [ GetPersonBaseCollection().GetByID( job.personID) ]
			EndIf
		Next
		Return res
	End Method


	Method GetCastGroupString:String(jobFlag:Int)
		Local result:String = ""
		Local group:TPersonBase[] = GetCastGroup(jobFlag)
		For Local i:Int = 0 To group.length-1
			If result <> "" Then result:+ ", "
			result:+ group[i].GetFullName()
		Next
		Return result
	End Method


	Method GetActors:TPersonBase[]()
		If cachedActors.length = 0
			For Local job:TPersonProductionJob = EachIn cast
				If job.job & TVTPersonJob.ACTOR
					cachedActors :+ [ GetPersonBaseCollection().GetByID( job.personID ) ]
				EndIf
			Next
		EndIf

		Return cachedActors
	End Method


	Method GetDirectors:TPersonBase[]()
		If cachedDirectors.length = 0
			For Local job:TPersonProductionJob = EachIn cast
				If job.job & TVTPersonJob.DIRECTOR
					cachedDirectors :+ [ GetPersonBaseCollection().GetByID( job.personID ) ]
				EndIf
			Next
		EndIf

		Return cachedDirectors
	End Method


	'1 based
	Method GetActor:TPersonBase(number:Int=1)
		'generate if needed
		GetActors()

		number = Min(cachedActors.length, Max(1, number))
		If number = 0 Then Return Null
		Return cachedActors[number-1]
	End Method


	Method GetActorsString:String()
		Local result:String = ""
		'generate if needed
		GetActors()

		For Local i:Int = 0 To cachedActors.length-1
			If result <> "" Then result:+ ", "
			result :+ cachedActors[i].GetFullName()
		Next
		Return result
	End Method


	'1 based
	Method GetDirector:TPersonBase(number:Int=1)
		'generate if needed
		GetDirectors()

		number = Min(cachedDirectors.length, Max(1, number))
		If number = 0 Then Return Null
		Return cachedDirectors[number-1]
	End Method


	Method GetDirectorsString:String()
		Local result:String = ""
		'generate if needed
		GetDirectors()

		For Local i:Int = 0 To cachedDirectors.length-1
			If result <> "" Then result:+ ", "
			result :+ cachedDirectors[i].GetFullName()
		Next
		Return result
	End Method


	Method HasFranchisee:Int(programme:TProgrammeData)
		If Not programme Then Return False

		For Local g:String = EachIn franchisees
			If g = programme.GetGUID() Then Return True
		Next

		Return False
	End Method


	Method AddFranchisee(programme:TProgrammeData)
		If HasFranchisee(programme) Then Return

		programme.franchiseGUID = Self.GetGUID()
		franchisees :+ [programme.GetGUID()]
	End Method


	Method RemoveFranchisee(programme:TProgrammeData)
		If Not HasFranchisee(programme) Then Return

		programme.franchiseGUID = ""

		Local newFranchisees:String[]
		For Local g:String = EachIn franchisees
			If g = programme.GetGUID() Then Continue

			newFranchisees :+ [g]
		Next
		franchisees = newFranchisees
	End Method


	Method GetFranchisees:String[]()
		Return franchisees
	End Method


	Method SetFranchiseByGUID( newFranchiseGUID:String )
		'remove old
		If franchiseGUID
			Local oldF:TProgrammeData = GetProgrammeDataCollection().GetByGUID(franchiseGUID)
			If oldF Then oldF.RemoveFranchisee(Self)
		EndIf

		If newFranchiseGUID
			Local newF:TProgrammeData = GetProgrammeDataCollection().GetByGUID(newFranchiseGUID)
			If newF Then newF.AddFranchisee(Self)
		EndIf
	End Method


	Method GetRefreshModifier:Float()
		Return GetModifier(modKeyTopicality_RefreshLS)
	End Method


	Method GetWearoffModifier:Float()
		Return GetModifier(modKeyTopicality_WearoffLS)
	End Method


	Method GetTrailerRefreshModifier:Float()
		Return GetModifier(modKeyTopicality_TrailerRefreshLS)
	End Method


	Method GetTrailerWearoffModifier:Float()
		Return GetModifier(modKeyTopicality_TrailerWearoffLS)
	End Method


	Method GetPerViewerRevenueModifier:Float()
		Return GetModifier(modKeyCallIn_PerViewerRevenueLS)
	End Method


	Method GetGenreWearoffModifier:Float(genre:Int=-1)
		If genre = -1 Then genre = Self.genre
		Return GetProgrammeDataCollection().GetGenreWearoffModifier(genre)
	End Method


	Method GetFlagsWearoffModifier:Float(flags:Int=-1)
		If flags = -1 Then flags = Self.flags
		Return GetProgrammeDataCollection().GetFlagsWearoffModifier(flags)
	End Method


	Method GetFlagsRefreshModifier:Float(flags:Int=-1)
		If flags = -1 Then flags = Self.flags
		Return GetProgrammeDataCollection().GetFlagsRefreshModifier(flags)
	End Method


	Method GetGenre:Int()
		Return Self.genre
	End Method


	Method HasSubGenre:Int(genre:Int)
		For Local i:Int = EachIn subGenres
			If genre = i Then Return True
		Next
		Return False
	End Method


	Method GetGenreRefreshModifier:Float(genre:Int=-1)
		If genre = -1 Then genre = Self.genre
		Return GetProgrammeDataCollection().GetGenreRefreshModifier(genre)
	End Method


	Function _GetGenreString:String(_genre:Int=-1)
		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(_genre))
	End Function


	Method GetGenreString:String(_genre:Int=-1)
		If _genre < 0 Then _genre = Self.genre
		'eg. PROGRAMME_GENRE_ACTION
		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(_genre))
	End Method


	Method GetFlagsString:String(delimiter:String=" / ")
		Local result:String = ""
		'checkspecific
		Local checkFlags:Int[] = [TVTProgrammeDataFlag.LIVE, TVTProgrammeDataFlag.PAID]

		For Local i:Int = EachIn checkFlags
			If flags & i > 0
				If result <> "" Then result :+ delimiter
				result :+ GetLocale("PROGRAMME_FLAG_" + TVTProgrammeDataFlag.GetAsString(i))
			EndIf
		Next

		Return result
	End Method


	Method _ReplacePlaceholdersInLocalizedString:TLocalizedString(localizedString:TLocalizedString)
		Local result:TLocalizedString = New TLocalizedString
		For Local langID:Int = EachIn localizedString.GetLanguageIDs()
			result.Set(_ReplacePlaceholdersInString(localizedString.Get(langID)), langID)
			'print langID + "  => " + Lset(localizedString.valueStrings[langID],30) + "  =>  " + Lset(localizedString.Get(langID),30) +"     result: " + Lset(result.Get(langID),30) +"  langIndex="+localizedString.GetLanguageIndex(langID)
		Next
		Return result
	End Method


	Method _ReplacePlaceholdersInString:String(content:String)
		Local result:String = content

		'placeholders are: "%object|guid|whatinformation%"
		'              or: "${object|guid|whatinformation}"
		Local placeHolders:String[] = StringHelper.ExtractPlaceholdersCombined(content)
		For Local placeHolder:String = EachIn placeHolders
			Local elements:String[] = placeHolder.split("|")
			If elements.length < 3 Then Continue

			If elements[0] = "person"
				Local person:TPersonBase = GetPersonBaseCollection().GetByGUID(elements[1])
				If Not person
					TTemplateVariables.ReplacePlaceholderInText(result, "person|"+elements[1]+"|Full", "John Doe")
					TTemplateVariables.ReplacePlaceholderInText(result, "person|"+elements[1]+"|First", "John")
					TTemplateVariables.ReplacePlaceholderInText(result, "person|"+elements[1]+"|Nick", "John")
					TTemplateVariables.ReplacePlaceholderInText(result, "person|"+elements[1]+"|Last", "Doe")
				Else
					TTemplateVariables.ReplacePlaceholderInText(result, "person|"+elements[1]+"|Full", person.GetFullName())
					TTemplateVariables.ReplacePlaceholderInText(result, "person|"+elements[1]+"|First", person.GetFirstName())
					TTemplateVariables.ReplacePlaceholderInText(result, "person|"+elements[1]+"|Nick", person.GetNickName())
					TTemplateVariables.ReplacePlaceholderInText(result, "person|"+elements[1]+"|Last", person.GetLastName())
				EndIf
			EndIf
		Next

		If result.find("|") >= 0
			If result.find("[") >= 0
				Local job:TPersonProductionJob
				'check for cast
				For Local i:Int = 0 To 10
					job = GetCastAtIndex(i)
					If Not job
						result = result.Replace("["+i+"|Full]", "John Doe")
						result = result.Replace("["+i+"|First]", "John")
						result = result.Replace("["+i+"|Nick]", "John")
						result = result.Replace("["+i+"|Last]", "Doe")
					Else
						Local person:TPersonBase = GetPersonBaseCollection().GetByID( job.personID )
						result = result.Replace("["+i+"|Full]", person.GetFullName())
						result = result.Replace("["+i+"|First]", person.GetFirstName())
						result = result.Replace("["+i+"|Nick]", person.GetNickName())
						result = result.Replace("["+i+"|Last]", person.GetLastName())
					EndIf
				Next
			EndIf
		EndIf

		Return result
	End Method


	Method GetTitle:String()
		If title
			'replace placeholders and and cache the result
			If Not titleProcessed
				titleProcessed = _ReplacePlaceholdersInLocalizedString(title)
			EndIf
			Return titleProcessed.Get()
		EndIf
		Return ""
	End Method


	Method GetDescription:String()
		If description
			'replace placeholders and and cache the result
			If Not descriptionProcessed
				descriptionProcessed = _ReplacePlaceholdersInLocalizedString(description)
			EndIf
			Return descriptionProcessed.Get()
		EndIf
		Return ""
	End Method


	Method IsHeader:Int() {_exposeToLua}
		Return (dataType = TVTProgrammeDataType.SERIES) Or ..
		       (dataType = TVTProgrammeDataType.COLLECTION) Or ..
		       (dataType = TVTProgrammeDataType.FRANCHISE)
	End Method


	Method IsEpisode:Int() {_exposeToLua}
		Return (dataType = TVTProgrammeDataType.EPISODE)
	End Method


	Method IsSingle:Int() {_exposeToLua}
		Return (dataType = TVTProgrammeDataType.SINGLE)
	End Method


	'first premiered on TV?
	Method IsTVDistribution:Int() {_exposeToLua}
		Return distributionChannel & TVTProgrammeDistributionChannel.TV > 0
	End Method


	'first premiered in cinema?
	Method IsCinemaDistribution:Int() {_exposeToLua}
		Return distributionChannel & TVTProgrammeDistributionChannel.CINEMA > 0
	End Method


	Method IsLive:Int()
		Return HasFlag(TVTProgrammeDataFlag.LIVE) > 0
	End Method

	Method IsAlwaysLive:Int()
		Return HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.ALWAYS_LIVE) > 0
	End Method

	Method SetPlayerIsBroadcasting(playerID:Int, enable:Int)
		'ensure "2 ^ (i-1)" does not result in a ":double"!
		Local flag:Int = 1 shl (playerID-1)  ' = 2^(playerID-1)
		If enable
			playersBroadcasting :| flag
		Else
			playersBroadcasting :& ~flag
		EndIf
	End Method


	Method IsPlayerIsBroadcasting:Int(playerID:Int)
		Local flag:Int = 1 shl (playerID-1)  ' = 2^(playerID-1)
		Return (playersBroadcasting & flag > 0)
	End Method


	Method SetPlayerIsLiveBroadcasting(playerID:Int, enable:Int)
		Local flag:Int = 1 shl (playerID-1)  ' = 2^(playerID-1)
		If enable
			playersLiveBroadcasting :| flag
		Else
			playersLiveBroadcasting :& ~flag
		EndIf
	End Method


	Method IsPlayerIsLiveBroadcasting:Int(playerID:Int)
		Local flag:Int = 1 shl (playerID-1)  ' = 2^(playerID-1)
		Return (playersBroadcasting & flag > 0)
	End Method


	Method HasDynamicData:Int()
		Return False
	End Method

	'returns true if the dynamic data state changed
	Method UpdateDynamicData:Int()
		Return False
	End Method


	'returns whether the live-state was updated
	'Informs casts about the finish of the production regardless
	'whether it got broadcasted or not
	Method UpdateLive:Int(calledAfterbroadCast:Int)
		If Not IsLive() Then Return False
		'do update for alwaysLive only after broadcast
		If IsAlwaysLive() and Not calledAfterbroadCast Then Return False
		If Not IsAlwaysLive() and calledAfterbroadCast Then Return False

		'cannot update as long somebody is broadcasting that programme
		If playersLiveBroadcasting > 0 Then Return False

		'do not update flags of header
		If Not isHeader()
			'programmes begin at xx:05 - but their live events will end xx:55
			'releaseTime is not guaranteed to be "xx:00" so, we use GetHours()
			Local finishedLiveBroadcast:Int = GetWorldTime().GetTimeGone() >= GetWorldTime().GetHour(releaseTime) * TWorldTime.HOURLENGTH  + (blocks*60 - 5) * TWorldTime.MINUTELENGTH

			'finish production on first broadcast (an always-live will
			'only finish once this way)
			If finishedLiveBroadcast and GetTimesBroadcasted() <= 1
				onFinishProduction()
			EndIf
	
			'or transform into "live on tape"
			'also remove broadcast restrictions
			If finishedLiveBroadcast
				SetFlag(TVTProgrammeDataFlag.LIVE, False)
				SetFlag(TVTProgrammeDataFlag.LIVEONTAPE, True)
				SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.ALWAYS_LIVE, FALSE)
				Return True
			EndIf
		EndIf

		Return False
	End Method


	Method IsLiveOnTape:Int()
		Return HasFlag(TVTProgrammeDataFlag.LIVEONTAPE) > 0
	End Method


	Method IsAnimation:Int()
		Return HasFlag(TVTProgrammeDataFlag.ANIMATION) > 0
	End Method


	Method IsCulture:Int()
		Return HasFlag(TVTProgrammeDataFlag.CULTURE) > 0
	End Method


	Method IsCult:Int()
		Return HasFlag(TVTProgrammeDataFlag.CULT) > 0
	End Method


	Method IsTrash:Int()
		Return HasFlag(TVTProgrammeDataFlag.TRASH) > 0
	End Method

	Method IsBMovie:Int()
		Return HasFlag(TVTProgrammeDataFlag.BMOVIE) > 0
	End Method


	Method IsXRated:Int()
		Return HasFlag(TVTProgrammeDataFlag.XRATED) > 0
	End Method


	Method IsPaid:Int()
		Return HasFlag(TVTProgrammeDataFlag.PAID) > 0
	End Method


	Method IsScripted:Int()
		Return HasFlag(TVTProgrammeDataFlag.SCRIPTED) > 0
	End Method


	Method IsVisible:Int()
		Return Not (HasFlag(TVTProgrammeDataFlag.INVISIBLE) > 0)
	End Method


	Method GetYear:Int()
		'PAID is always "live/from now"
		If HasFlag(TVTProgrammeDataFlag.PAID) Then Return GetWorldTime().GetYear()

		Return GetWorldTime().GetYear(releaseTime)
	End Method


	Method GetBlocks:Int(broadcastType:Int = -1)
		Return Self.blocks
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcome:Float()
		Return Self.outcome
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcomeTV:Float()
		Return Self.outcomeTV
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetSpeed:Float()
		Return Self.speed
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetReview:Float()
		Return Self.review
	End Method


	Method GetReleaseTime:Long()
		Return releaseTime
	End Method


	Method GetCinemaReleaseTime:Long()
		Return releaseTime - Max(1, GetWorldTime().GetDaysPerYear()/2) * TWorldTime.DAYLENGTH
	End Method


	'only useful for cinematic movies
	Method GetProductionStartTime:Long()
		Return releaseTime - GetWorldTime().GetDaysPerYear() * TWorldTime.DAYLENGTH
	End Method



	Method SetReleaseTime(dayOfYear:Int)
		releaseTime = GetWorldTime().GetTimeGoneForGameTime(GetYear(), dayOfYear Mod GetWorldTime().GetDaysPerYear(), 0, 0)
	End Method


	Method GetPrice:Int(playerID:Int)
		Local topicality:Float = GetTopicality() 'this includes age-adjustments
		Local maxTopicality:Float = GetMaxTopicality()

		Local newCacheCode:String = topicality+"_"+maxTopicality+"_" + Self.IsLive()
		If priceCacheCode <> newCacheCode
			Local value:Int = 0
			Local qRaw:Float = GetQualityRaw()
			'priceMod used to be GetQuality(); make this factor stable wrt. topicality
			Local priceMod:Float = qRaw * (0.10 + 0.90 * maxTopicality^2)

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
			'Local highQualityIndex:Float = 0.40 * qRaw + 0.60 * qRaw ^ 4
			Local highQualityIndex:Float = 0.40 * qRaw + 0.60* (qRaw + (qRaw^0.5 * 0.3)) ^ 4
			Local highTopicalityIndex:Float = 0.30 * maxTopicality + 0.70 * maxTopicality ^ 4

			priceMod :* highTopicalityIndex * highQualityIndex

			'=== FLAGS ===
			'BMovies lower the price
			If Self.IsBMovie() Then priceMod :* 0.95
			'Cult movies increase price
			If Self.IsCult() Then priceMod :* 1.05
			'Income generating programmes (infomercials) increase the price
			If Self.IsPaid() Then priceMod :* 1.30
			'Live is something more expensive as it is "exclusive"
			If Self.IsLive() Then priceMod :* 1.20


			'raw price based on max topicality
			If isType(TVTProgrammeProductType.MOVIE)
				value = 25000 + 2400000 * priceMod
			 'shows, productions, series...
			Else
				value = 15000 + 1600000 * priceMod
			EndIf

			'make price difference due to topicality loss explicit
			'maximum loss of 50%
			If topicality < maxTopicality
				value :- (value / 2 * (maxTopicality - topicality))
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
			Local b:Int = GetBlocks()
			value :* b * 0.92^(b-1)


			'=== INDIVIDUAL PRICE ===
			'general data price mod
			value :* GetModifier(modKeyPriceLS)

			priceCacheCode = newCacheCode
			priceCache = value
		EndIf
		Return priceCache
	End Method


	Method GetPriceOld:Int(playerID:Int)
		Local value:Int = 0
		Local priceMod:Float = GetQuality() 'this includes age-adjustments


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
		Local highQualityIndex:Float = 0.38 * GetQualityRaw() + 0.62 * GetQualityRaw() ^ 4
		Local highTopicalityIndex:Float = 0.25 * GetMaxTopicality() + 0.75 * GetMaxTopicality() ^ 4

		priceMod :* highTopicalityIndex * highQualityIndex

		'=== FLAGS ===
		'BMovies lower the price
		If Self.IsBMovie() Then priceMod :* 0.90
		'Cult movies increase price
		If Self.IsCult() Then priceMod :* 1.05
		'Income generating programmes (infomercials) increase the price
		If Self.IsPaid() Then priceMod :* 1.30


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
		value :* GetModifier(modKeyPriceLS)

		Return value
	End Method


	'override
	Method GetMaxTopicality:Float()
		'ATTENTION: cache won't work with dynamic/changing modifiers

		Local timesBroadcastedValue:Int = GetTimesBroadcasted()
		Local age:Int = Max(0, GetWorldTime().GetYear() - GetYear())

		Local newCacheCode:String = timesBroadcastedValue + "_" + GetWorldTime().GetDayHour()

		If maxTopicalityCacheCode <> newCacheCode
			Local res:Float = 1.0

			Local timesBroadcasted:Int = 0
			Local weightAge:Float = 0.8
			Local weightTimesBroadcasted:Float = 0.4

			If IsPaid()
				'always age = 0 ... so just decrease by broadcasts
				age = 0
				weightAge = 0.0

				'maximum of 10 broadcasts decrease up to "80%" of max topicality
				timesBroadcasted = 0.8 * Min(100, Int(timesBroadcastedValue * 10))
				weightTimesBroadcasted = 1.0

			Else
				'TODO higher weight for broadcast influence?
				'TODO non-linear influence
				'maximum of 10 broadcasts decrease up to "50%" of max topicality
				timesBroadcasted = 0.5 * Min(100, timesBroadcastedValue * 10)
			EndIf

			'modifiers could increase or decrease influences of age/aired/...
			Local ageInfluence:Float = 1.5 * age * GetModifier(modKeyTopicality_AgeLS)
			Local timesBroadcastedInfluence:Float = timesBroadcasted * GetModifier(modKeyTopicality_TimesBroadcastedLS)

			Local firstBroadcastInfluence:Float = 10 * (timesBroadcasted>0)
			Local notLiveInfluence:Float = 0.0
			If IsLiveOnTape()
				'Live programmes like sport matches should lose attractiveness after the first broadcast.
				notLiveInfluence = 10 * GetModifier(modKeyTopicality_NotLiveLS, 1.0)
				firstBroadcastInfluence:* GetModifier(modKeyTopicality_FirstBroadcastDoneLS, 1.0)
				'Also they should age much faster
				weightAge = 1.0
				Local daysSinceLive:Int = Max(0, GetWorldTime().GetDay() - GetWorldTime().GetDay(releaseTime))
				Select daysSinceLive
					Case 0
						'notLiveInfluence unchanged
					Case 1
						notLiveInfluence :* 1.25
					Case 2
						notLiveInfluence :* 1.5
					Case 3
						notLiveInfluence :* 1.75
					Default
						notLiveInfluence :* 2
				EndSelect
			Else
				'by default the first broadcast has a much smaller influence than for live programmes
				firstBroadcastInfluence:* GetModifier(modKeyTopicality_FirstBroadcastDoneLS, 0.2)
			EndIf

			'cult-movies are less affected by aging or broadcast amounts
			If Self.IsCult()
				ageInfluence :* 0.75
				timesBroadcastedInfluence :* 0.50
				notLiveInfluence :* 0.50
			EndIf

			Local influencePercentage:Float = 0.01 * MathHelper.Clamp(weightAge * ageInfluence + notLiveInfluence + firstBroadcastInfluence + weightTimesBroadcasted * timesBroadcastedInfluence, 0, 100)

			maxTopicalityCache = 1.0 - THelper.ATanFunction(influencePercentage, 2)
			'print GetTitle() +" age "+ age +" #br "+ timesBroadcastedValue +" ageInfl " +MathHelper.NumberToString(weightAge * ageInfluence) +" firstBrInfl "+ MathHelper.NumberToString(firstBroadcastInfluence) +" brInfl "+ MathHelper.NumberToString(weightTimesBroadcasted * timesBroadcastedInfluence) +" -> "+ MathHelper.NumberToString(maxTopicalityCache)
			maxTopicalityCacheCode = newCacheCode
		EndIf
		Return maxTopicalityCache
	End Method


	Method GetMaxTrailerTopicality:Float()
		Return trailerMaxTopicality
	End Method


	Method GetTrailerTopicality:Float()
		If trailerTopicality < 0 Then trailerTopicality = GetMaxTrailerTopicality()

		'refresh topicality on each request
		'-> avoids a "topicality > MaxTopicality" when MaxTopicality
		'   shrinks because of aging/airing
		trailerTopicality = Min(trailerTopicality, GetMaxTrailerTopicality())

		Return trailerTopicality
	End Method


	Method GetGenreDefinition:TMovieGenreDefinition()
		If Not genreDefinitionCache Then
			genreDefinitionCache = GetMovieGenreDefinitionCollection().Get([Genre]+subgenres)

			If Not genreDefinitionCache
				TLogger.Log("GetGenreDefinition()", "Programme ~q"+GetTitle()+"~q: Genre #"+Genre+" misses a genreDefinition. Creating BASIC definition-", LOG_ERROR)
				genreDefinitionCache = New TMovieGenreDefinition.InitBasic(Genre, Null)
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
		Local quality:Float = 0.0

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
			Local add:Float = FixOutcome(genreDef)

			quality :+ add
		EndIf

		Return quality
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
	Method CutTopicality:Float(cutModifier:Float=1.0) {_private}
		'for the calculation we need to know what to cut, not what to keep
		Local toCut:Float =  (1.0 - cutModifier)
		Local minimumRelativeCut:Float = 0.20 '20%
		Local minimumAbsoluteCut:Float = 0.15 '15%
		Local baseCut:Float = 0.10 '10%

		Rem

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
		Local toCut:Float =  (1.0 - cutModifier)
		Local minimumRelativeCut:Float = 0.10 '10%
		Local minimumAbsoluteCut:Float = 0.10 '10%

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
		Local minimumRelativeRefresh:Float = 1.10 '110%
		Local minimumAbsoluteRefresh:Float = 0.10 '10%

		refreshModifier :* GetProgrammeDataCollection().refreshFactor
		Local modifer:Float = GetRefreshModifier()
		If modifer <> 1.0
			refreshModifier = 1.0 + (refreshModifier - 1.0) * modifer
		EndIf
		refreshModifier :* GetGenreRefreshModifier()
		refreshModifier :* GetFlagsRefreshModifier()

		refreshModifier = Max(refreshModifier, minimumRelativeRefresh)
		topicality = GetTopicality() 'limit to max topicality

		topicality :+ Max(topicality * (refreshModifier-1.0), minimumAbsoluteRefresh)
		topicality = MathHelper.Clamp(topicality, 0, GetMaxTopicality())

		Return topicality
	End Method


	Method RefreshTrailerTopicality:Float(refreshModifier:Float = 1.0) {_private}
		Local minimumRelativeRefresh:Float = 1.10 '110%
		Local minimumAbsoluteRefresh:Float = 0.10 '10%

		refreshModifier :* GetProgrammeDataCollection().trailerRefreshFactor
		Local modifer:Float = GetTrailerRefreshModifier()
		If modifer <> 1.0
			refreshModifier = 1.0 + (refreshModifier - 1.0) * modifer
		EndIf
		refreshModifier :* GetGenreRefreshModifier()
		refreshModifier :* GetFlagsRefreshModifier()

		refreshModifier = Max(refreshModifier, minimumRelativeRefresh)

		trailerTopicality = GetTrailerTopicality() 'account for limits
		trailerTopicality :+ Max(trailerTopicality * (refreshModifier-1.0), minimumAbsoluteRefresh)
		trailerTopicality = MathHelper.Clamp(trailerTopicality, 0, 1.0)

		Return trailerTopicality
	End Method


	Method GetTargetGroupAttractivityMod:TAudience()
		Return targetGroupAttractivityMod
	End Method


	Method GetTargetGroups:Int()
		Return targetGroups
	End Method


	Method HasTargetGroup:Int(group:Int) {_exposeToLua}
		Return targetGroups & group
	End Method


	Method SetTargetGroup:Int(group:Int, enable:Int=True)
		If enable
			targetGroups :| group
		Else
			targetGroups :& ~group
		EndIf
	End Method


	Method GetProPressureGroups:Int()
		Return proPressureGroups
	End Method


	Method HasProPressureGroup:Int(group:Int) {_exposeToLua}
		Return proPressureGroups & group
	End Method


	Method SetProPressureGroup:Int(group:Int, enable:Int=True)
		If enable
			proPressureGroups :| group
		Else
			proPressureGroups :& ~group
		EndIf
	End Method


	Method GetContraPressureGroups:Int()
		Return contraPressureGroups
	End Method


	Method HasContraPressureGroup:Int(group:Int) {_exposeToLua}
		Return contraPressureGroups & group
	End Method


	Method SetContraPressureGroup:Int(group:Int, enable:Int=True)
		If enable
			contraPressureGroups :| group
		Else
			contraPressureGroups :& ~group
		EndIf
	End Method


	'returns amount of trailers aired since last normal programme broadcast
	'or "in total"
	Method GetTimesTrailerAired:Int()
		Return Self.trailerAired
	End Method


	Method SetTimesTrailerAiredSinceLastBroadcast:Int(amount:Int, playerID:Int=-1)
		If playerID = -1 Then playerID = owner
		If playerID <= 0 Or playerID > TVTPlayerCount Then Return False
		If playerID > Self.trailerAiredSinceLastBroadcast.length Then Self.trailerAiredSinceLastBroadcast = Self.trailerAiredSinceLastBroadcast[.. playerID]

		Self.trailerAiredSinceLastBroadcast[playerID-1] = amount
		Return True
	End Method


	Method GetTimesTrailerAiredSinceLastBroadcast:Int(playerID:Int)
		If playerID <= 0 Or playerID > Self.trailerAiredSinceLastBroadcast.length Then Return 0

		Return Self.trailerAiredSinceLastBroadcast[playerID-1]
	End Method


	'return a value between 0 - 1.0
	'describes how much of a potential trailer-bonus of 100% was reached
	Method GetTrailerMod:TAudience(playerID:Int, createIfMissing:Int = True)
		If playerID <= 0 Or playerID > TVTPlayerCount Then Return Null
		If playerID > Self.trailerMods.length
			If Not createIfMissing Then Return Null
			'resize
			Self.trailerMods = Self.trailerMods[.. playerID]
		EndIf

		If Not Self.trailerMods[playerID-1] And createIfMissing
			Self.trailerMods[playerID-1] = New TAudience
		EndIf

		Return Self.trailerMods[playerID-1]
	End Method


	Method RemoveTrailerMod:Int(playerID:Int)
		If playerID <= 0 Or playerID > Self.trailerMods.length Then Return False
		Self.trailerMods[playerID-1] = Null
	End Method


	'override
	Method IsAvailable:Int()
		'live programme is available 10 days before

		If IsLive()
			'TODO the alwaysLive-Flag of the header is not set
			'but if it was, the header would not be available anymore as then the "released"-check fails
			'print getTitle() +" available?" + " "+isHeader()+ " "+ isReleased()+ " "+ isAlwaysLive()
			If IsAlwaysLive()
				'is a default case - available after release
			Else If GetWorldTime().GetDay() + 10 >= GetWorldTime().GetDay(releaseTime)
				Return True
			Else
				Return False
			EndIf
		EndIf

		If Not isReleased() Then Return False

		Return Super.IsAvailable()
	End Method


	Method isReleased:Int()
		'call-in shows are kind of "live"
		If HasFlag(TVTProgrammeDataFlag.PAID) Then Return True
		'TODO alwaysLive is also released?
		'If IsAlwaysLive() Then Return True

		If Not ignoreUnreleasedProgrammes Then Return True

		Return releaseTime >= 0 and GetWorldTime().GetTimeGone() >= releaseTime
	End Method


	Method isInCinema:Int()
		'live programme is never in a cinema
		If IsLive() Then Return False

		If isReleased() Then Return False
		' without stored outcome, the movie wont run in the cinemas
		If outcome <= 0 Then Return False

		Return releaseTime >= 0 and GetCinemaReleaseTime() <= GetWorldTime().GetTimeGone()
	End Method


	Method isInProduction:Int()
		'live programme is never "in production"
		If IsLive() Then Return False

		If isReleased() Then Return False

		Return releaseTime >= 0 and GetProductionStartTime() <= GetWorldTime().GetTimeGone() And GetCinemaReleaseTime() > GetWorldTime().GetTimeGone()
	End Method


	Method isCustomProduction:Int() {_exposeToLua}
		Return HasFlag(TVTProgrammeDataFlag.CUSTOMPRODUCTION)
	End Method
	
	
	Method IsAPlayersCustomProduction:Int() {_exposeToLua}
		Return isCustomProduction() and (extra and extra.GetInt("producerID") > 0)
	End Method


	Method isType:Int(typeID:Int)
		'if productType is a bitmask flag
		'return (productType & typeID)

		Return productType = typeID
	End Method
	
	
	Method GetProductionID:Int()
		If not IsCustomProduction() or not extra then Return 0
		Return extra.GetInt("productionID")
	End Method


	Method GetProducerID:Int()
		If not IsCustomProduction() or not extra then Return 0
		Return extra.GetInt("producerID")
	End Method


	Method SetState:Int(state:Int)
		'skip if already done
		If Self.state = state Then Return False

		Select state
			Case TVTProgrammeState.NONE
				'
			Case TVTProgrammeState.IN_PRODUCTION
				If Not onProductionStart() Then Return False
			Case TVTProgrammeState.IN_CINEMA
				If Not onCinemaRelease() Then Return False
			Case TVTProgrammeState.RELEASED
				If Not onRelease() Then Return False
		End Select

		'inform collection that this programme(data) is in a new state
		GetProgrammeDataCollection().SetProgrammeDataState(Self, state)

		Self.state = state
	End Method


	Method FixOutcome:Int(genreDef:TMovieGenreDefinition = Null)
		If Not genreDef Then genreDef = GetGenreDefinition()

		Local newOutcome:Float = 0
		If genreDef.ReviewMod > 0
			newOutcome :+ (genreDef.ReviewMod / (1.0 - genreDef.OutcomeMod) ) - genreDef.ReviewMod
		EndIf
		If genreDef.SpeedMod > 0
			newOutcome :+ (genreDef.SpeedMod / (1.0 - genreDef.OutcomeMod) ) - genreDef.SpeedMod
		EndIf


		If IsTVDistribution() And GetOutcomeTV() <= 0
			If GetOutcome() > 0
				outcomeTV = GetOutcome()
			Else
				'print "FIX TV : "+GetTitle()+"  new:"+newOutcome
				outcomeTV = newOutcome
			EndIf
			outcome = 0
		ElseIf Not IsTVDistribution() And GetOutcome() <= 0
			If GetOutcomeTV() > 0
				outcome = GetOutcomeTV()
			Else
				'print "FIX CIN: "+GetTitle()+"  new:"+newOutcome
				outcome = newOutcome
			EndIf
			outcomeTV = 0
		EndIf

		Return newOutcome
	End Method


	Method onProductionStart:Int(time:Long = 0)
		'trigger effects/modifiers
		Local params:TData = New TData.Add("source", Self)
		if effects then effects.Update("productionStart", params)

		Return True
	End Method


	Method onCinemaRelease:Int(time:Long = 0)
		If IsLive() Then Return False

		If Not isHeader()
			onFinishProduction()
		EndIf

		Return True
	End Method


	Method onRelease:Int(time:Long = 0)
		'if not done already via onCinemaRelase ...
		If Not isHeader()
			onFinishProduction()
		EndIf

		Return True
	End Method


	'inform each person in the cast that the production finished
	'TODO should this really be done also for *programmes* defined in the database
	'alternative: initialize with True and set False when creating programme data for a script
	Method onFinishProduction:Int(time:Long = 0)
		'already done
		If finishedProductionForCast Then Return False

		If GetCast()
			For Local job:TPersonProductionJob = EachIn GetCast()
				Local person:TPersonBase = GetPersonBaseCollection().GetByID( job.personID )
				If person Then person.FinishProduction( GetID(), job.job )
			Next
		EndIf

		finishedProductionForCast = True
	End Method


	Method Update:Int()
		?debug
		print self.GetTitle() + "  Update(). State="+state + " (" + TVTProgrammeState.GetAsString(state) +")"
		?
		Select state
			Case TVTProgrammeState.NONE
				'repair old programme (finished before game start year)
				'and loop through all states (prod - cinema - release)
				If isReleased()
					?debug
					print "  from NONE. isReleased. production -> cinema -> released"
					?
					SetState(TVTProgrammeState.IN_PRODUCTION)
					SetState(TVTProgrammeState.IN_CINEMA)
					SetState(TVTProgrammeState.RELEASED)
				ElseIf isInCinema()
					?debug
					print "  from NONE. isInCinema. production -> cinema"
					?
					SetState(TVTProgrammeState.IN_PRODUCTION)
					SetState(TVTProgrammeState.IN_CINEMA)
				ElseIf isInProduction()
					?debug
					print "  from NONE. isInProduction. production"
					?
					SetState(TVTProgrammeState.IN_PRODUCTION)
				EndIf
			Case TVTProgrammeState.IN_PRODUCTION
				If isInCinema()
					?debug
					print "  from PRODUCTION. isInCinema -> cinema"
					?
					SetState(TVTProgrammeState.IN_CINEMA)
				'some programme do not run in cinema
				ElseIf isReleased()
					?debug
					print "  from PRODUCTION. isInCinema -> released"
					?
					SetState(TVTProgrammeState.RELEASED)
				EndIf
			Case TVTProgrammeState.IN_CINEMA
				If isReleased() Then SetState(TVTProgrammeState.RELEASED)
		End Select
	End Method


	'override
	'called as soon as the last block of a programme ends
	Method doFinishBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		'mark broadcasting state
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			If playerID > 0
				SetPlayerIsBroadcasting(playerID, False)
				'reset of live in all cases
				SetPlayerIsLiveBroadcasting(playerID, False)
			EndIf
		EndIf


		'inform always-live-programmes about broadcast finish
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			If IsLive() And IsAlwaysLive()
				updateLive(True)
			End If
		EndIf


		'=== BROADCAST LIMITS ===
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			If broadcastLimit > 0 Then broadcastLimit :- 1
		EndIf
		

		'=== EFFECTS ===
		'trigger broadcastEffects
		Local effectParams:TData = New TData.Add("source", Self).AddNumber("playerID", playerID)

		'send as programme
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast - after "onFinishBroadcasting"-call)
			If GetTimesBroadcasted() = 0
				If Not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE)
					If effects Then effects.Update("broadcastFirstTimeDone", effectParams)
					setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE, True)
				EndIf
			EndIf

			If effects Then effects.Update("broadcastDone", effectParams)

		'send as trailer
		ElseIf broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			If GetTimesTrailerAired() = 0
				If Not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL_DONE)
					If effects Then effects.Update("broadcastFirstTimeTrailerDone", effectParams)
					setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL_DONE, True)
				EndIf
			EndIf

			If effects Then effects.Update("broadcastTrailerDone", effectParams)
		EndIf
	End Method


	'override
	'called as soon as the last block of a programme ends
	Method doAbortBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		'mark broadcasting state
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			If playerID > 0
				SetPlayerIsBroadcasting(playerID, False)
				'reset of live in all cases
				SetPlayerIsLiveBroadcasting(playerID, False)
			EndIf
		EndIf


		'=== EFFECTS ===
		'trigger broadcastEffects
		Local effectParams:TData = New TData.Add("source", Self).AddNumber("playerID", playerID)

		'send as programme
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			If effects Then effects.Update("broadcastAborted", effectParams)

		'send as trailer
		ElseIf broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			If effects Then effects.Update("broadcastTrailerAborted", effectParams)
		EndIf
	End Method


	'override
	'called as soon as the programme is broadcasted
	Method doBeginBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		'mark broadcasting state
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			If playerID > 0
				SetPlayerIsBroadcasting(playerID, True)
				'if broadcasting right at live time - mark it
				If IsLive() And (IsAlwaysLive() Or GetWorldTime().GetDayHour() = GetWorldTime().GetDayHour( releaseTime ))
					SetPlayerIsLiveBroadcasting(playerID, True)
				EndIf
			EndIf
		EndIf


		'=== UPDATE BROADCAST RESTRICTIONS ===
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			If HasBroadcastTimeSlot() and not HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.KEEP_BROADCAST_TIME_SLOT_ENABLED_ON_BROADCAST)
				broadcastTimeSlotStart = -1
				broadcastTimeSlotEnd = -1
			EndIf
		EndIf


		'=== EFFECTS ===
		'trigger broadcastEffects
		Local effectParams:TData = New TData.Add("source", Self).AddNumber("playerID", playerID)

		'send as programme
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast - after "onFinishBroadcasting"-call)
			If GetTimesBroadcasted() = 0
				If Not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME)
					If effects Then effects.Update("broadcastFirstTime", effectParams)
					setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME, True)
				EndIf
			EndIf

			If effects Then effects.Update("broadcast", effectParams)

		'send as trailer
		ElseIf broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			If GetTimesTrailerAired() = 0
				If Not hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL)
					If effects Then effects.Update("broadcastFirstTimeTrailer", effectParams)
					setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL, True)
				EndIf
			EndIf

			If effects Then effects.Update("broadcastTrailer", effectParams)
		EndIf
	End Method


End Type