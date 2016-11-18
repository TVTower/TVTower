Rem
	====================================================================
	ProgrammeLicence data - basics of broadcastable programme
	====================================================================
EndRem
SuperStrict
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.gameobject.bmx"
Import "game.broadcastmaterial.base.bmx"
Import "game.programme.programmedata.bmx"
Import "game.player.base.bmx"
Import "game.player.finance.bmx"
Import "game.broadcast.audience.bmx"
Import "game.broadcast.broadcaststatistic.bmx"
Import "basefunctions.bmx" 'CreateEmptyImage()
'to access datasheet-functions
Import "common.misc.datasheet.bmx"




Type TProgrammeLicenceCollection
	'holding all programme licences
	Field licences:TList = CreateList()
	'holding only licences of special packages containing multiple
	'movies/series
	Field collections:TList	= CreateList()
	'holding only single licences (movies, one-time-events)
	Field singles:TList = CreateList()
	'holding only series licences
	Field series:TList = CreateList()

	Global _instance:TProgrammeLicenceCollection


	Function GetInstance:TProgrammeLicenceCollection()
		if not _instance then _instance = new TProgrammeLicenceCollection
		return _instance
	End Function


	Method Initialize:TProgrammeLicenceCollection()
		licences.Clear()
		collections.Clear()
		singles.Clear()
		series.Clear()
		
		return self
	End Method


	Method PrintLicences:int()
		print "--------- singles: "+singles.Count()
		For local single:TProgrammeLicence = Eachin singles
			print single.GetTitle() + "   [owner: "+single.owner+"]"
		Next
		print "---------"
		print "--------- series: "+series.Count()
		For local serie:TProgrammeLicence = Eachin series
			print serie.GetTitle() + "   [owner: "+serie.owner+"]"
			For local episode:TProgrammeLicence = Eachin serie.subLicences
				print "'-- "+episode.GetTitle() + "   [owner: "+episode.owner+"]"
			Next
		Next
		print "---------"
		print "--------- collections: "+collections.Count()
		For local collection:TProgrammeLicence = Eachin collections
			print collection.GetTitle() + "   [owner: "+collection.owner+"]"
			For local episode:TProgrammeLicence = Eachin collection.subLicences
				print "'-- "+episode.GetTitle() + "   [owner: "+episode.owner+"]"
			Next
		Next
		print "---------"
	End Method


	'add a licence
	Method Add:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and licences.contains(licence) then return False

		licences.AddLast(licence)
		return True
	End Method


	Method Remove:Int(licence:TProgrammeLicence)
		return licences.Remove(licence)
	End Method


	'checks if the licences list contains the given licence
	Method Contains:Int(licence:TProgrammeLicence)
		return licences.contains(licence)
	End Method


	'add a licence as single (movie, one-time-event)
	Method AddSingle:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False

		singles.AddLast(licence)
		return True
	End Method


	Method RemoveSingle:Int(licence:TProgrammeLicence)
		Remove(licence)
		singles.Remove(licence)
	End Method


	'checks if the singles list contains the given licence
	Method ContainsSingle:Int(licence:TProgrammeLicence)
		return singles.contains(licence)
	End Method	


	'add a licence as series
	Method AddSeries:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False
		
		series.AddLast(licence)
		return True
	End Method


	Method RemoveSeries:Int(licence:TProgrammeLicence)
		Remove(licence)
		series.Remove(licence)
	End Method


	'checks if the series list contains the given licence
	Method ContainsSeries:Int(licence:TProgrammeLicence)
		return series.contains(licence)
	End Method	


	Method AddEpisode:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False

		'nothing more to do
		
		return True
	End Method


	Method RemoveEpisode:Int(licence:TProgrammeLicence)
		'TODO: remove from parents sublicence list?
		
		Remove(licence)
	End Method


	'checks if the licences list contains the given licence
	Method ContainsEpisode:Int(licence:TProgrammeLicence)
		return Contains(licence)
	End Method	


	'add a licence as collection
	Method AddCollection:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False
		
		collections.AddLast(licence)
		return True
	End Method


	'checks if the collection list contains the given licence
	Method ContainsCollection:Int(licence:TProgrammeLicence)
		return collections.contains(licence)
	End Method


	Method RemoveCollection:Int(licence:TProgrammeLicence)
		Remove(licence)
		collections.Remove(licence)
	End Method


	'add a licence to all needed lists
	Method AddAutomatic:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'do not add franchise-licences
		if licence.licenceType = TVTProgrammeLicenceType.FRANCHISE then return False

		'=== SINGLES ===
		if licence.isSingle() then return AddSingle(licence, skipDuplicates)

		'=== SERIES ===
		if licence.isSeries() then return AddSeries(licence, skipDuplicates)
		if licence.isEpisode() then return AddEpisode(licence, skipDuplicates)

		'=== COLLECTIONS ===
		if licence.isCollection() then return AddCollection(licence, skipDuplicates)

		return False
	End Method
		

	'remove a licence from all needed lists
	Method RemoveAutomatic:Int(licence:TProgrammeLicence)
		'skip franchise-licences
		if licence.licenceType = TVTProgrammeLicenceType.FRANCHISE then return False

		'=== SINGLES ===
		if licence.isSingle() then RemoveSingle(licence)

		'=== SERIES ===
		if licence.isSeries() then RemoveSeries(licence)
		if licence.isEpisode() then RemoveEpisode(licence)

		'=== COLLECTIONS ===
		if licence.isCollection() then RemoveCollection(licence)

		return True
	End Method
	

	'returns the list to use for the given type
	'this is just important for "random" access as we could
	'also just access "progList" in all cases...
	Method _GetList:TList(programmeLicenceType:int=0)
		Select programmeLicenceType
			case TVTProgrammeLicenceType.SINGLE
				return singles
			case TVTProgrammeLicenceType.SERIES
				return series
			case TVTProgrammeLicenceType.COLLECTION
				return collections
			default
				return licences
		End Select
	End Method


	Global warnedEmptyRandomFromList:int = False
	Method GetRandomFromList:TProgrammeLicence(_list:TList)

		If _list = Null Then Return Null
		If _list.count() > 0
			Local Licence:TProgrammeLicence = TProgrammeLicence(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If Licence then return Licence
		EndIf
		if not warnedEmptyRandomFromList
			TLogger.log("TProgrammeLicence.GetRandomFromList()", "list is empty (incorrect filter or not enough available licences?)", LOG_DEBUG | LOG_WARNING | LOG_DEV, TRUE)
			warnedEmptyRandomFromList = true
		endif
		Return Null
	End Method


	Method Get:TProgrammeLicence(id:Int, programmeLicenceType:int=0)
		local list:TList = _GetList(programmeLicenceType)
		local licence:TProgrammeLicence = null

		For Local i:Int = 0 To list.Count() - 1
			Licence = TProgrammeLicence(list.ValueAtIndex(i))
			if Licence and Licence.id = id Then Return Licence
		Next
		Return Null
	End Method


	Method GetByGUID:TProgrammeLicence(GUID:String)
		'TODO: change to tmap if to slow
		For local licence:TProgrammeLicence = EachIn licences
			if licence.GetGUID() = GUID then return licence
		Next
		Return Null
	End Method



	Method GetRandom:TProgrammeLicence(programmeLicenceType:int=0, includeEpisodes:int=FALSE)
		'filter to entries we need
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeLicenceType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.IsOwned() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'if available (unbought, released..), add it to candidates list
			resultList.addLast(Licence)
		Next

		Return GetRandomFromList(resultList)
	End Method


	Method GetRandomWithGenre:TProgrammeLicence(genre:Int=0, programmeLicenceType:int=0, includeEpisodes:int=FALSE)
		Local Licence:TProgrammeLicence
		Local sourceList:TList = _GetList(programmeLicenceType)
		Local resultList:TList = CreateList()

		For Licence = EachIn sourceList
			'ignore if filtered out
			If Licence.IsOwned() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue

			'if available (unbought, released..), add it to candidates list
			If Licence.isSingle() or Licence.isEpisode()
				if Licence.GetGenre() = genre Then resultList.addLast(Licence)
			else
				local foundGenreInSubLicence:int = FALSE
				for local subLicence:TProgrammeLicence = eachin Licence.subLicences
					if foundGenreInSubLicence then continue
					if subLicence.GetGenre() = genre
						resultList.addLast(Licence)
						foundGenreInSubLicence = TRUE
					endif
				Next
			endif
		Next
		Return GetRandomFromList(resultList)
	End Method


	Method GetRandomByFilter:TProgrammeLicence(filter:TProgrammeLicenceFilter)
		Local Licence:TProgrammeLicence
		Local resultList:TList = CreateList()

		For Licence = EachIn licences
			'ignore already used
			If Licence.IsOwned() Then continue
			'ignore episodes
			If Licence.isEpisode() Then continue

			if not filter.DoesFilter(licence) then continue

			'add it to candidates list
			resultList.addLast(Licence)
		Next
		Return GetRandomFromList(resultList)
	End Method	
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeLicenceCollection:TProgrammeLicenceCollection()
	Return TProgrammeLicenceCollection.GetInstance()
End Function




'licence of for movies, series and so on
Type TProgrammeLicence Extends TBroadcastMaterialSource {_exposeToLua="selected"}
	'wird nur in der Lua-KI verwendet um die Lizenzen zu bewerten
	Field attractiveness:Float = -1
	Field data:TProgrammeData				{_exposeToLua}
	'the latest hour-(from-start) one of the planned programmes ends
	Field latestPlannedEndHour:int = -1
	Field latestPlannedTrailerHour:int = -1
	'is this licence a: collection, series, episode or single element?
	'you cannot distinguish between "series" and "collections" without
	'as both could contain "shows" or "episodes"
	Field licenceType:int = 0
	'series are parent of episodes
	Field parentLicenceGUID:string = ""
	'other licences this licence covers
	Field subLicences:TProgrammeLicence[]
	Field episodeNumber:int = -1
	'store stats for each owner
	Field broadcastStatistics:TBroadcastStatistic[]
	'flags:
	'is this licence tradeable? if not, licence cannot get sold.
	'use this eg. for opening programme
	Field licenceFlags:int = TVTProgrammeLicenceFlag.TRADEABLE

'	Field cacheTextOverlay:TImage 			{nosave}
'	Field cacheTextOverlayMode:string = ""	{nosave}	'for which mode the text was cached


	Method GenerateGUID:string()
		return "broadcastmaterialsource-programmelicence-"+id
	End Method


	Method GetReferenceID:int() {_exposeToLua}
		'return own licence id as referenceID - programme.id is not
		'possible for collections/series
		return self.ID
	End Method


	Function SortByName:Int(o1:Object, o2:Object)
		Local p1:TProgrammeLicence = TProgrammeLicence(o1)
		Local p2:TProgrammeLicence = TProgrammeLicence(o2)
		If Not p2 Then Return 1
		If Not p1 Then Return -1
		if p1.GetTitle() = p2.GetTitle() 
			return p1.GetGUID() > p2.GetGUID()
		endif
        If p1.GetTitle().ToLower() > p2.GetTitle().ToLower()
			return 1
        elseif p1.GetTitle().ToLower() < p2.GetTitle().ToLower()
			return -1
		endif
		return 0
	End Function
	

	Function SortByTopicality:Int(o1:Object, o2:Object)
		Local p1:TProgrammeLicence = TProgrammeLicence(o1)
		Local p2:TProgrammeLicence = TProgrammeLicence(o2)
		If p2 and p1
			if p1.GetTopicality() < p2.GetTopicality()
				return -1
			elseif p1.GetTopicality() > p2.GetTopicality()
				return 1
			endif
			'return int(Floor((p1.GetTopicality() - p2.GetTopicality()) + 0.5))
		Endif
		return SortByName(o1, o2)
	End Function	
	

	Function SortByBlocks:Int(o1:Object, o2:Object)
		Local p1:TProgrammeLicence = TProgrammeLicence(o1)
		Local p2:TProgrammeLicence = TProgrammeLicence(o2)
		If p2 and p1 and p2.data and p1.data
			return p1.data.GetBlocks() - p2.data.GetBlocks()
		Endif
		return SortByName(o1, o2)
	End Function	


	Method hasLicenceFlag:Int(flag:Int) {_exposeToLua}
		Return licenceFlags & flag
	End Method


	Method setLicenceFlag(flag:Int, enable:Int=True)
		If enable
			licenceFlags :| flag
		Else
			licenceFlags :& ~flag
		EndIf
	End Method
	

	'connect programmedata to a licence
	Method SetData:int(data:TProgrammeData)
		self.data = data
	End Method


	Method GetData:TProgrammeData() {_exposeToLua}
		'if not self.data then print "[ERROR] data for TProgrammeLicence with title: ~q"+title+"~q is missing."
		return self.data
	End Method


	Method GetTargetGroupAttractivityMod:TAudience()
		'return if single element or episode but with own modifier
		if not self.parentLicenceGUID or data.GetTargetGroupAttractivityMod()
			return data.GetTargetGroupAttractivityMod()
		else
			return GetParentLicence().GetTargetGroupAttractivityMod()
		endif
	End Method


	'returns how many slots for sublicences are reserved yet
	'ex.: [null, null, licence] returns 3
	Method GetSubLicenceSlots:int() {_exposeToLua}
		if not subLicences then return 0

		return subLicences.length
	End Method


	'returns how many sub licences EXIST
	Method GetSubLicenceCount:int() {_exposeToLua}
		if not subLicences then return 0

		local result:int = 0
		For local i:int = 0 until subLicences.length
			if subLicences[i] then result :+ 1
		Next
		return result
	End Method


	Method GetSubLicences:TProgrammeLicence[]() {_exposeToLua}
		local result:TProgrammeLicence[]
		For local i:int = 0 until subLicences.length
			if subLicences[i] then result :+ [subLicences[i]]
		Next
		return result
	End Method


	Method GetSubLicenceAtIndex:TProgrammeLicence(arrayIndex:int=1) {_exposeToLua}
		if arrayIndex >= subLicences.length or arrayIndex < 0 then return null
		return subLicences[arrayIndex]
	End Method


	Method AddSubLicence:int(licence:TProgrammeLicence, index:int = -1)
		'=== ADJUST LICENCE TYPES ===

		'as each licence is individual we easily can set the main licence
		'as parent (so sublicences can ask for sibling licences).
		licence.parentLicenceGUID = self.GetGUID()

		'inform programmeData about being episode of a series
		if isSeries() and licence.data and self.data
			licence.data.parentGUID = self.data.GetGUID()
		endif

		if index = -1
			subLicences :+ [licence]
		'set at the given index and move the existing ones +1
		'exception: if slot is unused (pre-reserved already)
		'[1,2,3] + add(x, 2) = [1,2,x,3]
		else
			if subLicences.length > index and not subLicences[index]
				subLicences[index] = licence
			else
				if index = 0
					subLicences = [licence] + sublicences
				else
					subLicences = subLicences[.. index] + [licence] + subLicences[index ..]
				endif
			endif
		endif
				
		Return TRUE
	End Method


	Method GetBroadcastStatistic:TBroadcastStatistic(useOwner:int=-1)
		if useOwner < 0 then useOwner = Max(0, owner)
		
		if broadcastStatistics.length <= useOwner then broadcastStatistics = broadcastStatistics[.. useOwner + 1]
		if not broadcastStatistics[useOwner] then broadcastStatistics[useOwner] = new TBroadcastStatistic

		return broadcastStatistics[useOwner]
	End Method


	Method SetBroadcastStatistic:Int(broadcastStatistic:TBroadcastStatistic)
		local useOwner:int = owner
		if owner < 0 then useOwner = 0

		if broadcastStatistics.length <= useOwner then broadcastStatistics = broadcastStatistics[.. useOwner + 1]
		broadcastStatistics[useOwner] = broadcastStatistic
		return True
	End Method


	Method GiveBackToLicencePool:int()
		SetOwner( TOwnedGameObject.OWNER_NOBODY )

		'remove tradeability?
		if HasLicenceFlag(TVTProgrammeLicenceFlag.LICENCEPOOL_REMOVES_TRADEABILITY)
			setLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE, False)
		endif

		'refill broadcast limits - or disable tradeability
		if broadcastLimitMax > 0 and isExceedingBroadcastLimit()
			if HasLicenceFlag(TVTProgrammeLicenceFlag.LICENCEPOOL_REFILLS_BROADCASTLIMITS)
				SetBroadcastLimit(broadcastLimitMax)
			else
				setLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE, False)
			endif
		endif

		'refill topicality?
		if HasLicenceFlag(TVTProgrammeLicenceFlag.LICENCEPOOL_REFILLS_TOPICALITY)
			GetData().topicality = GetData().GetMaxTopicality()
		endif

		return True
	End Method


	Method isProgrammeType:int(programmeDataType:int) {_exposeToLua}
		return GetData() and GetData().isType(programmeDataType)
	End Method


	Method isSeries:int() {_exposeToLua}
		return licenceType = TVTProgrammeLicenceType.SERIES
	End Method


	Method isEpisode:int() {_exposeToLua}
		return licenceType = TVTProgrammeLicenceType.EPISODE
	End Method


	Method isSingle:int() {_exposeToLua}
		return licenceType = TVTProgrammeLicenceType.SINGLE
	End Method
	

	Method isCollection:int() {_exposeToLua}
		return licenceType = TVTProgrammeLicenceType.COLLECTION
	End Method


	Method GetLicenceType:int()
		return licenceType
	End Method


	'override default method to add sublicences
	Method SetOwner:int(owner:int=0)
		self.owner = owner
		'do the same for all children
		For local licence:TProgrammeLicence = eachin subLicences
			licence.SetOwner(owner)
		Next
		return TRUE
	End Method


	'override
	Method GetBroadcastLimit:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			'licence-invidividual limit or base-defined limit?
			if self.broadcastLimit <= 0 then return data.GetBroadcastLimit()

			return self.broadcastLimit
		else
			local maxLimit:int = 0
			local foundLimit:int = 0
			'find smalles limit
			For local licence:TProgrammeLicence = eachin subLicences
				if not foundLimit
					maxLimit = licence.GetBroadcastLimit()
					foundLimit = True
				else
					maxLimit = Max(maxLimit, licence.GetBroadcastLimit())
				endif
			Next

			return maxLimit
		endif
	End Method


	'override
	Method GetBroadcastTimeSlotStart:int()
		local result:int = Super.GetBroadcastTimeSlotStart()
		if result = -1 and data then return data.GetBroadcastTimeSlotStart()

		return result
	End Method


	'override
	Method GetBroadcastTimeSlotEnd:int()
		local result:int = Super.GetBroadcastTimeSlotEnd()
		if result = -1 and data then return data.GetBroadcastTimeSlotEnd()

		return result
	End Method


	'override
	Method HasBroadcastTimeSlot:int()
		if GetSubLicenceCount() = 0 and GetData()
			if data.HasBroadcastTimeSlot() then return True

			return Super.HasBroadcastTimeSlot()
		else
			'it is enough if one licence has a time slot
			For local licence:TProgrammeLicence = eachin subLicences
				if licence.HasBroadcastTimeSlot() then return True
			Next

			return False
		endif
	End Method


	'override
	Method IsExceedingBroadcastLimit:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			if data.IsExceedingBroadcastLimit() then return True

			return Super.IsExceedingBroadcastLimit()
		else
			'it is enough if one licence is exceeding
			For local licence:TProgrammeLicence = eachin subLicences
				if licence.IsExceedingBroadcastLimit() then return True
			Next

			return False
		endif
	End Method


	Method IsVisible:int()
		if GetSubLicenceCount() = 0 and GetData()
			return GetData().IsVisible()
		else
			'it is enough if one licence is visible
			For local licence:TProgrammeLicence = eachin subLicences
				if licence.IsVisible() then return True
			Next
			return False
		endif
	End Method


	Method IsTradeable:int()
		if GetSubLicenceCount() = 0 and GetData()
			if not hasLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE) then return False

			'disallow selling a custom production until it was
			'broadcasted at least once
			if GetData().GetTimesBroadcasted() <= 0 and GetData().IsCustomProduction()
			'using this would also disable selling live programme
			'if GetData().IsTVDistribution() and GetData().GetOutcomeTV() < 0
				return False
			endif

		else
			'if licence is a collection: ask subs
			For local licence:TProgrammeLicence = eachin subLicences
				if not licence.IsTradeable() then return FALSE
			Next
		endif

		return True
	End Method


	Method Sell:int()
		'forbid selling if not tradeable
		if not IsTradeable() then return False
		
		local finance:TPlayerFinance = GetPlayerFinance(owner)
		if not finance then return False

		finance.SellProgrammeLicence(getPrice(owner), self)

		'set unused again
		SetOwner( TOwnedGameObject.OWNER_NOBODY )

		return TRUE
	End Method


	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int=-1)
		local finance:TPlayerFinance = GetPlayerFinance(playerID, -1)
		if not finance then return False

		If finance.PayProgrammeLicence(getPrice(playerID), self)
			SetOwner(playerID)
			Return TRUE
		EndIf
		Return FALSE
	End Method


	Method GetParentLicence:TProgrammeLicence() {_exposeToLua}
		if not self.parentLicenceGUID then return self
		return GetProgrammeLicenceCollection().GetByGUID(self.parentLicenceGUID)
	End Method


	Method GetSubLicencePosition:int(licence:TProgrammeLicence) {_exposeToLua}
		For local i:int = 0 until GetSubLicenceSlots()
			if GetSubLicenceAtIndex(i) = licence then return i
		Next
		return -1
	End Method


	'returns the next licence of a licences parent sublicences
	Method GetNextSubLicence:TProgrammeLicence() {_exposeToLua}
		if not parentLicenceGUID then return Null

		'find my position and add 1
		local nextArrayIndex:int = GetParentLicence().GetSubLicencePosition(self) + 1
		'if we are at the last position, return the first one
		if nextArrayIndex >= GetParentLicence().GetSubLicenceCount() then nextArrayIndex = 0

		return GetParentLicence().GetSubLicenceAtIndex(nextArrayIndex)
	End Method


	Method GetEpisodeNumber:int() {_exposeToLua}
		if not self.parentLicenceGUID then return 1

		if episodeNumber > 0 then return episodeNumber

		return GetParentLicence().GetSubLicencePosition(self)+1
	End Method


	Method GetEpisodeCount:int() {_exposeToLua}
		'disabled: do not skip calculations as you could have a collection
		'          of series
		'if parentLicenceGUID then return 1
		
		'returns the _current_ amount of licences, so if you did not
		'finish a custom production yet, the number represents the current
		'state, not the final one!
		return GetParentLicence().GetSubLicenceCount()
		'to return the amount of currently "planned" episodes use:
		'return GetParentLicence().GetSubLicenceSlots()
	End Method



	Method CanBroadcastAtTime:int(broadcastType:int, day:int, hour:int) {_exposeToLua}
		'check timeslot limits
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if HasBroadcastTimeSlot()
				'hour incorrect?
				if GetBroadcastTimeSlotStart() >= 0 and GetBroadcastTimeSlotStart() > hour then return False
				if GetBroadcastTimeSlotEnd() >= 0 and GetBroadcastTimeSlotEnd() < (hour + GetBlocks(broadcastType)-1) then return False
			endif
		endif

		'check live-programme
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if data.IsLive()
				'hour or day incorrect
				if GameRules.onlyExactLiveProgrammeTimeAllowedInProgrammePlan
					if GetWorldTime().GetDayHour( data.releaseTime ) <> hour then return False
					if GetWorldTime().GetDay( data.releaseTime ) <> day then return False
				'all times after the live event are allowed too
				else
					'live happens on a later day
					if GetWorldTime().GetDay( data.releaseTime ) > day
						return False
					'live happens on that day but on a later hour
					elseif GetWorldTime().GetDay( data.releaseTime ) = day
						if GetWorldTime().GetDayHour( data.releaseTime ) > hour then return False
					endif
				endif
			endif
		endif

		return Super.CanBroadcastAtTime(broadcastType, day, hour)
	End Method


	Method isAvailable:int() {_exposeToLua}
		'checking for isReleased() hides "live" programme"
		'also: GetData().isAvailable() calls data.isReleased() already
		'if not isReleased() then return False

		if GetData() and not GetData().isAvailable() then return False

		if isExceedingBroadcastLimit() then return False

		'if licence is a collection: ask subs
		'one single available entry is enough to return True
		'For local licence:TProgrammeLicence = eachin subLicences
		'	if licence.isAvailable() then return True
		'Next

		return Super.IsAvailable()
	End Method


	Method isReleased:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().isReleased()

		'if licence is a collection: ask subs
		For local licence:TProgrammeLicence = eachin subLicences
			if not licence.isReleased() then return FALSE
		Next

		return TRUE
	End Method


	Method IsControllable:int() {_exposeToLua}
		'single-licence
		'if GetSubLicenceCount() = 0
			if Super.IsControllable()
				if GetData() then return GetData().IsControllable()
				return True
			endif
		'endif

		'ask sublicences?
		rem
		'if licence is a collection: ask subs
		For local licence:TProgrammeLicence = eachin subLicences
			if not licence.IsControllable() then return FALSE
		Next
		endrem
		return False
	End Method


	Method setPlanned:int(latestHour:int=-1)
		if latestHour >= 0
			'set to maximum
			self.latestPlannedEndHour = Max(latestHour, self.latestPlannedEndHour)
		else
			'reset
			latestPlannedEndHour = -1
		endif
	End Method


	Method setTrailerPlanned:int(latestHour:int=-1)
		if latestHour >= 0
			'set to maximum
			self.latestPlannedTrailerHour = Max(latestHour, self.latestPlannedTrailerHour)
		else
			'reset
			self.latestPlannedTrailerHour = -1
		endif
	End Method


	Method isPlanned:int() {_exposeToLua}
		return isProgrammePlanned() or isTrailerPlanned()
	End Method
	
	
	'instead of asking the programmeplan about each licence
	'we cache that information directly within the programme
	Method isProgrammePlanned:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData()
			if (latestPlannedEndHour>=0) then return TRUE
			'if self is not planned - ask if parent is set to planned
			'do not use this for series if used in the programmePlanner-view
			'to "emphasize" planned programmes
			'if self.parentLicence then return self.parentLicence.isPlanned()

			return False
		endif

		For local licence:TProgrammeLicence = eachin subLicences
			if licence.isPlanned() then return TRUE
		Next
		return FALSE
	End Method


	'instead of asking the programmeplan about each licence
	'we cache that information directly within the programme
	Method isTrailerPlanned:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData()
			if (latestPlannedTrailerHour>=0) then return TRUE
			'if self is not planned - ask if parent is set to planned
			'do not use this for series if used in the programmePlanner-view
			'to "emphasize" planned programmes
			'if self.parentLicence then return self.parentLicence.isTrailerPlanned()

			return False
		endif

		For local licence:TProgrammeLicence = eachin subLicences
			if licence.isTrailerPlanned() then return TRUE
		Next
		return FALSE
	End Method


	'override
	'only allow broadcasts for non-series-/non-collection-headers
	Method IsNewBroadcastPossible:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 then return Super.IsNewBroadcastPossible()
		return False
	End Method


	'returns the genre of a licence - if a group, the one used the most
	'often is returned
	Method GetGenre:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetGenre()

		'return genre if one was defined (overriding episodes)
		if GetData() and GetData().GetGenre() >= 0 then return GetData().GetGenre()

		local genres:int[] = [0] 'init genre 0 with count 0
		local bestGenre:int=0
		For local licence:TProgrammeLicence = eachin subLicences
			local genre:int = licence.GetGenre()
			if genre > genres.length-1 then genres = genres[..genre+1]
			genres[genre]:+1
		Next
		For local i:int = 0 to genres.length-1
			if genres[i] > genres[bestGenre] then bestGenre = i
		Next

		return bestGenre
	End Method


	Method GetGenreString:String(_genre:Int=-1)
		'return the string of the best genre of the licence (packet)
		if GetData() then return GetData().GetGenreString( GetGenre() )
		return ""
	End Method


	'override
	'checks flags of all data-objects contained in self and sublicences
	Method hasDataFlag:Int(flag:Int) {_exposeToLua}
		return GetDataFlags() & flag
	End Method


	'override
	'checks flags of all data-objects contained in self and sublicences
	Method hasBroadcastFlag:Int(flag:Int) {_exposeToLua}
		return GetBroadcastFlags() & flag
	End Method


	'override
	'checks flags of all data-objects contained in self and sublicences
	Method hasFlag:Int(flag:Int) {_exposeToLua}
		return GetFlags() & flag
	End Method


	'returns the flags as a mix of all licences
	Method GetFlags:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return flags

		local allFlags:int
		For local licence:TProgrammeLicence = eachin subLicences
			allFlags :| licence.GetFlags()
		Next
		return allFlags
	End Method


	'returns the flags as a mix of all licences
	Method GetBroadcastFlags:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return broadcastFlags

		local allBroadcastFlags:int
		For local licence:TProgrammeLicence = eachin subLicences
			allBroadcastFlags :| licence.GetBroadcastFlags()
		Next
		return allBroadcastFlags
	End Method	


	'returns the flags as a mix of all licences
	'ATTENTION: if ONE has xrated, all are xrated, if one has trash, all ..
	'so this kind of "taints"
	Method GetDataFlags:int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().flags

		local allFlags:int
		For local licence:TProgrammeLicence = eachin subLicences
			allFlags :| licence.GetDataFlags()
		Next
		return allFlags
	End Method


	Method GetQuality:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetQuality()

		'if licence is a collection: ask subs
		local quality:Float = 0
		For local licence:TProgrammeLicence = eachin subLicences
			quality :+ licence.GetQuality()
		Next

		if subLicences.length > 0 then return quality / subLicences.length
		return 0.0
	End Method


	Method GetQualityRaw:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetQualityRaw()

		'if licence is a collection: ask subs
		local qualityRaw:Float = 0
		For local licence:TProgrammeLicence = eachin subLicences
			qualityRaw :+ licence.GetQualityRaw()
		Next

		if subLicences.length > 0 then return qualityRaw / subLicences.length
		return 0.0
	End Method
	

	'override
	Method GetTitle:string() {_exposeToLua}
		if not title and GetData() then return GetData().GetTitle()

		return Super.GetTitle()
	End Method


	'override
	Method GetBlocks:int(broadcastType:int = 0) {_exposeToLua}
		Select broadcastType
			'trailer?
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				Return 1
			'programme?
			Default
				Return GetData().GetBlocks()
		End Select
	End Method


	Method GetBlocksTotal:int(broadcastType:int = 0) {_exposeToLua}
		if GetSubLicenceCount() = 0
			Select broadcastType
				'trailer?
				Case TVTBroadcastMaterialType.ADVERTISEMENT
					Return 1
				'programme?
				Default
					Return GetData().GetBlocks()
			End Select
		else
			local blocksTotal:Float = 0
			For local licence:TProgrammeLicence = eachin subLicences
				blocksTotal :+ licence.GetBlocksTotal(broadcastType)
			Next

			return blocksTotal
		endif
	End Method


	Method GetDescription:string() {_exposeToLua}
		if not description and GetData() then return GetData().GetDescription()

		return Super.GetDescription()
	End Method


	'returns the (avg) relative topicality of a licence (package)
	Method GetRelativeTopicality:Float() {_exposeToLua}
		return GetTopicality() / GetMaxTopicality()
	End Method


	'when used as trailer Get
	Method GetAdTopicality:Float() {_exposeToLua}
		if GetData()
			return GetData().GetTrailerTopicality()
		else
			return 0
		endif
	End Method


	'returns the avg topicality of a licence (package)
	Method GetTopicality:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetTopicality()

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetTopicality()
		Next

		if subLicences.length > 0 then return value / subLicences.length
		return 0.0
	End Method


	'returns the avg maxTopicality of a licence (package)
	Method GetMaxTopicality:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().GetMaxTopicality()

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetMaxTopicality()
		Next

		if subLicences.length > 0 then return value / subLicences.length
		return 0.0
	End Method


	Method GetPrice:Int(playerID:int) {_exposeToLua}
		if playerID = 0 and owner > 0 then playerID = owner 
		if playerID = 0 then playerID = GetPlayerBaseCollection().playerID

		Local value:Float

		'single-licence
		if GetSubLicenceCount() = 0 and GetData()
			value = GetData().GetPrice(playerID)
		else
			'licence for a package or series
			For local licence:TProgrammeLicence = eachin subLicences
				value :+ licence.GetPrice(playerID)
			Next
			value :* 0.90
		endif


		'=== INDIVIDUAL PRICE ===
		'individual licence price mod (eg. "special collection discount")
		value :* GetModifier("price")

		'=== AUCTION PRICE ===
		'if this licence was won in an auction, this price is modifying
		'the real one
		value :* GetModifier("auctionPrice")

		'=== DIFFICULTY ===
		'eg. "auctions" set this flag
		if not HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY)
			value :* GetPlayerDifficulty(string(playerID)).programmePriceMod
		endif

		'=== BEAUTIFY ===
		'round to next "1000" block
		'value = Int(Floor(value / 1000) * 1000)
		value = TFunctions.RoundToBeautifulValue(value)


		Return value
	End Method


	Method GetTimesBroadcasted:int(owner:int = -1)
		if GetSubLicenceCount() = 0 then return data.GetTimesBroadcasted(owner)

		local sum:int = 0
		For local sub:TProgrammeLicence = EachIn subLicences
			sum :+ sub.GetTimesBroadcasted(owner)
		Next

		'round upwards, the first broadcast already return "1"
		return int(ceil(float(sum) / GetSubLicenceCount()))
	End Method


	'override
	'called as soon as the last block of a programme ends
	Method doFinishBroadcast(playerID:int = -1, broadcastType:int = 0)
		'=== BROADCAST LIMITS ===
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if broadcastLimit > 0 then broadcastLimit :- 1
		endif
	End Method
	

	Method ShowSheet:Int(x:Int,y:Int, align:int=0, showMode:int=0, useOwner:int=-1, extraData:TData = null)
		if useOwner = -1 then useOwner = owner
		'set default mode
		if showMode = 0 then showMode = TVTBroadcastMaterialType.PROGRAMME

		if KeyManager.IsDown(KEY_LALT) or KeyManager.IsDown(KEY_RALT)
			'when doing alt-tab the "ALT"-keys keep "down"

			if showMode = TVTBroadcastMaterialType.PROGRAMME
				showMode = TVTBroadcastMaterialType.ADVERTISEMENT
			else
				showMode = TVTBroadcastMaterialType.PROGRAMME
			endif
		Endif


		if showMode = TVTBroadcastMaterialType.PROGRAMME
			ShowProgrammeSheet(x, y, align, useOwner, extraData)
		'trailermode
		elseif showMode = TVTBroadcastMaterialType.ADVERTISEMENT
			ShowTrailerSheet(x, y, align, useOwner, extraData)
		endif
	End Method


	Method ShowProgrammeSheet:Int(x:Int,y:Int, align:int=0, useOwner:int=-1, extraData:TData = null)
		if useOwner = -1 then useOwner = owner
		
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 320
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("programme")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()

		local currentPlayerID:int = GetPlayerBaseCollection().playerID
		'save checks on data availability...
		local data:TProgrammeData = GetData()
		'save on requests to the player finance
		local finance:TPlayerFinance
		'only check finances if it is no other player (avoids exposing
		'that information to us)
		if useOwner <= 0 or currentPlayerID = useOwner
			finance = GetPlayerFinance(currentPlayerID)
		endif

		local title:string
		if not isEpisode()
			title = GetTitle()
		else
			title = GetParentLicence().GetTitle()
		endif

		'can player afford this licence?
		local canAfford:int = False
		'possessing player always can
		if currentPlayerID = useOwner
			canAfford = True
		'if it is another player... just display "can afford"
		elseif useOwner > 0
			canAfford = True
		'not our licence but enough money to buy
		elseif finance and finance.canAfford(GetPrice(currentPlayerID))
			canAfford = True
		endif
		
		Local showMsgPlannedWarning:Int = False
		Local showMsgEarnInfo:Int = False
		Local showMsgLiveInfo:Int = False
		Local showMsgBroadcastLimit:Int = False
		Local showMsgBroadcastTimeSlot:Int = False
		
		'only if planned and in archive
		'if useOwner > 0 and GetPlayer().figure.inRoom
		'	if self.IsPlanned() and GetPlayer().figure.inRoom.name = "archive"
		if useOwner > 0 and self.IsPlanned() then showMsgPlannedWarning = True
		'if licence is for a specific programme it might contain a flag...
		'TODO: do this for "all" via licence.HasFlag() doing recursive checks?
		If data.IsPaid() then showMsgEarnInfo = True
		If data.IsLive() or data.IsLiveOnTape()
			local programmedDay:int = -1
			local programmedHour:int = -1
			if extraData
				programmedDay = extraData.GetInt("programmedDay", -1)
				programmedHour = extraData.GetInt("programmedHour", -1)
				'not programmed = freshly created or dragged, so it is
				'live, if the live-time is not passed yet
				if programmedDay = -1 or programmedHour = -1
					if GetWorldTime().GetTimeGone() < data.releaseTime + 5*60 ' xx:05
						showMsgLiveInfo = true
					endif
				'if programmed, check if this the time of the live broadcast
				'if so - also display the "live"-information for something
				'which is only "live on tape" (was live at that time)
				else
					if GetWorldTime().GetDay(data.releaseTime) = programmedDay and GetWorldTime().GetDayHour(data.releaseTime) = programmedHour
						showMsgLiveInfo = true
					endif
				endif
			elseif data.IsLive()
				'it is only live until it happens
				if GetWorldTime().GetTimeGone() < data.releaseTime + 5*60 ' xx:05
					showMsgLiveInfo = True
				endif
			endif
		endif
		If HasBroadcastLimit() then showMsgBroadcastLimit= True
		If HasBroadcastTimeSlot() then showMsgBroadcastTimeSlot= True


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, subtitleH:int = 16, genreH:int = 16, descriptionH:int = 70, castH:int=50
		local splitterHorizontalH:int = 6
		local boxH:int = 0, msgH:int = 0, barH:int = 0
		local msgAreaH:int = 0, boxAreaH:int = 0, barAreaH:int = 0
		local boxAreaPaddingY:int = 4, msgAreaPaddingY:int = 4, barAreaPaddingY:int = 4
		 
		msgH = skin.GetMessageSize(contentW - 10, -1, "", "money", "good", null, ALIGN_CENTER_CENTER).GetY()
		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").GetY()
		barH = skin.GetBarSize(100, -1).GetY()
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(title, contentW - 10, 100))
		'increase for multiline
'		if titleH > 18 then titleH :+ 3

		'message area
		If showMsgEarnInfo then msgAreaH :+ msgH
		If showMsgPlannedWarning then msgAreaH :+ msgH
		If showMsgLiveInfo then msgAreaH :+ msgH
		If showMsgBroadcastLimit then msgAreaH :+ msgH
		If showMsgBroadcastTimeSlot then msgAreaH :+ msgH
		'if there are messages, add padding of messages
		if msgAreaH > 0 then msgAreaH :+ 2* msgAreaPaddingY


		'box area
		'contains 1 line of boxes
		'box area might start with padding and end with padding
		boxAreaH = 1 * boxH
		if msgAreaH = 0 then boxAreaH :+ boxAreaPaddingY
		'no ending if nothing comes after "boxes"

		'bar area starts with padding, ends with padding and contains
		'also contains 4 bars
		barAreaH = 2 * barAreaPaddingY + 4 * (barH + 2)

		'total height
		sheetHeight = titleH + genreH + descriptionH + castH + barAreaH + msgAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		if isSeries() or isEpisode() then sheetHeight :+ subtitleH
		'there is a splitter between description and cast...
		sheetHeight :+ splitterHorizontalH

		
		'=== RENDER ===
	
		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
			if titleH <= 18
				GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY -1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY +1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
		contentY :+ titleH

		
		'=== SUBTITLE AREA ===
		if isSeries()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			skin.fontNormal.drawBlock(GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetEpisodeCount()), contentX + 5, contentY, contentW - 10, genreH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ subtitleH
		elseif isEpisode()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			'episode num/max + episode title
			skin.fontNormal.drawBlock(GetEpisodeNumber() + "/" + GetParentLicence().GetEpisodeCount() + ": " + data.GetTitle(), contentX + 5, contentY, contentW - 10, genreH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ subtitleH
		endif
		

		'=== COUNTRY / YEAR / GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		'splitter
		GetSpriteFromRegistry("gfx_datasheet_content_splitterV").DrawArea(contentX + 5 + 65, contentY, 2, 16)
		'country [+year] + genre, year for non-callin-shows
		If data.HasFlag(TVTProgrammeDataFlag.PAID)
			skin.fontNormal.drawBlock(data.country, contentX + 5, contentY, 65, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		else
			skin.fontNormal.drawBlock(data.country + " " + data.GetYear(), contentX + 5, contentY, 65, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		endif
		skin.fontNormal.drawBlock(GetGenreString(), contentX + 5 + 65 + 2, contentY, contentW - 10 - 65 - 2, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ genreH

	
		'=== DESCRIPTION AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.drawBlock(GetDescription(), contentX + 5, contentY + 3, contentW - 10, descriptionH - 3, null, skin.textColorNeutral)
		contentY :+ descriptionH


		'splitter
		skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
		contentY :+ splitterHorizontalH
		

		'=== CAST AREA ===
		skin.RenderContent(contentX, contentY, contentW, castH, "2")
		'cast
		local cast:string = ""

		For local i:int = 1 to TVTProgrammePersonJob.count
			local jobID:int = TVTProgrammePersonJob.GetAtIndex(i)
			local requiredPersons:int = data.GetCastGroup(jobID).length
			if requiredPersons <= 0 then continue

			if cast <> "" then cast :+ ", "

			if requiredPersons = 1
				cast :+ "|b|"+GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(jobID, True))+":|/b| "
			else
				cast :+ "|b|"+GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(jobID, False))+":|/b| "
			endif
			
			cast :+ data.GetCastGroupString(jobID)
		Next

		if cast <> ""
			contentY :+ 3

			'max width of cast word - to align their content properly
			skin.fontNormal.drawBlock(cast, contentX + 5, contentY , contentW  - 10, castH, null, skin.textColorNeutral)

			contentY:+ castH - 3
		else
			contentY:+ castH
		endif

		'=== BARS / MESSAGES / BOXES AREA ===
		'background for bars + messages + boxes
		skin.RenderContent(contentX, contentY, contentW, barAreaH + msgAreaH + boxAreaH, "1_bottom")


		'===== DRAW RATINGS / BARS =====

		'bars have a top-padding
		contentY :+ barAreaPaddingY
		'speed
		skin.RenderBar(contentX + 5, contentY, 200, 12, data.GetSpeed())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_SPEED"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'critic/review
		skin.RenderBar(contentX + 5, contentY, 200, 12, data.GetReview())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_CRITIC"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'boxoffice/outcome
		if data.IsTVDistribution()
			skin.RenderBar(contentX + 5, contentY, 200, 12, data.GetOutcomeTV())
			'use a different text color if tv-outcome is not calculated
			'yet
			if data.GetOutcomeTV() < 0
				skin.fontSemiBold.drawBlock(GetLocale("MOVIE_TVAUDIENCE"), contentX + 5 + 200 + 5, contentY, 75, 15, null, new TColor.Create(180,50,50))
			else
				skin.fontSemiBold.drawBlock(GetLocale("MOVIE_TVAUDIENCE"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
			endif
		else
			skin.RenderBar(contentX + 5, contentY, 200, 12, data.GetOutcome())
			skin.fontSemiBold.drawBlock(GetLocale("MOVIE_BOXOFFICE"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		endif
		contentY :+ barH + 2
		'topicality/maxtopicality
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetTopicality(), GetMaxTopicality())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
	

		'=== MESSAGES ===
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY

		If showMsgLiveInfo
			local time:string = ""
			local days:int = GetWorldTime().GetDay( data.releaseTime ) - GetWorldTime().GetDay()

			if days = 0
				time = GetLocale("TODAY")
			elseif days = 1
				time = GetLocale("TOMORROW")
			elseif days =-1
				time = GetLocale("YESTERDAY")
			elseif days > 0
				time = GetLocale("IN_X_DAYS").Replace("%DAYS%", GetWorldTime().GetDaysRun( data.releaseTime ) - GetWorldTime().GetDaysRun())
			else
				time = GetLocale("X_DAYS_AGO").Replace("%DAYS%", Abs(GetWorldTime().GetDaysRun( data.releaseTime ) - GetWorldTime().GetDaysRun()))
			endif
			'programme start time
			time :+ ", "+ GetWorldTime().GetDayHour( data.releaseTime )+":05"
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("MOVIE_LIVESHOW")+": "+time, "runningTime", "bad", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		if showMsgBroadcastLimit
			local broadcastsLeft:int =  GetBroadcastLimit()
			if broadcastsLeft <= 0
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("NO_MORE_BROADCASTS_ALLOWED"), "spotsPlanned", "bad", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			elseif broadcastsLeft = 1
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("ONLY_1_BROADCAST_POSSIBLE"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			else
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("ONLY_X_BROADCASTS_POSSIBLE").replace("%X%", GetBroadcastLimit()), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			endif
			contentY :+ msgH
		endif

		if showMsgBroadcastTimeSlot
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("BROADCAST_ONLY_ALLOWED_FROM_X_TO_Y").Replace("%X%", GetBroadcastTimeSlotStart()).Replace("%Y%", GetBroadcastTimeSlotEnd()) , "spotsPlanned", "bad", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif

		If showMsgEarnInfo
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			local revenue:string = TFunctions.DottedValue(int(1000 * data.GetPerViewerRevenue()))+CURRENCYSIGN

			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), "money", "good", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		if showMsgPlannedWarning
			if not isProgrammePlanned()
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("TRAILER_IN_PROGRAMME_PLAN"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			elseif not isTrailerPlanned()
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PROGRAMME_IN_PROGRAMME_PLAN"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			else
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PROGRAMME_AND_TRAILER_IN_PROGRAMME_PLAN"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			endif
			contentY :+ msgH
		endif


		'if there is a message then add padding to the bottom
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		'=== BOXES ===
		'boxes have a top-padding (except with messages)
		if msgAreaH = 0 then contentY :+ boxAreaPaddingY


		'=== BOX LINE 1 ===
		'blocks
		skin.RenderBox(contentX + 5, contentY, 47, -1, data.GetBlocks(), "duration", "neutral", skin.fontBold)
		'repetitions
		if useOwner <= 0
			skin.RenderBox(contentX + 5 + 51, contentY, 52, -1, GetTimesBroadcasted(-1), "repetitions", "neutral", skin.fontBold)
		else
			skin.RenderBox(contentX + 5 + 51, contentY, 52, -1, GetTimesBroadcasted(useOwner), "repetitions", "neutral", skin.fontBold)
		endif
		'record
		skin.RenderBox(contentX + 5 + 107, contentY, 83, -1, TFunctions.convertValue(GetBroadcastStatistic(useOwner).GetBestAudienceResult(useOwner, -1).audience.GetTotalSum(),2), "maxAudience", "neutral", skin.fontBold)

		'price
		local showPrice:int = not data.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.HIDE_PRICE)
		'- hide for custom productions until aired
		if showPrice and data.IsTVDistribution() and data.GetOutcomeTV() < 0 and data.IsCustomProduction() then showPrice = False
		'- hide unowned and not tradeable ones
		'-> disabled because of "Opener show"
		'if showPrice not IsOwned() and not IsTradeable() then showPrice = False

		'show price if forced to. ATTENTION: licence flag, not data/broadcast flag!
		'showPrice = showPrice or hasLicenceFlag(TVTProgrammeLicenceFlag.SHOW_PRICE)
		
		if showPrice
			if canAfford
				skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(GetPrice(useOwner)), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(GetPrice(useOwner)), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER, "bad")
			endif
		else
			skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, "- ?? -", "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		endif
		'=== BOX LINE 2 ===
		contentY :+ boxH



		'=== DEBUG ===
		If TVTDebugInfos
			'begin at the top ...again
			contentY = y + skin.GetContentY()
			local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.drawBlock("Programm: "+GetTitle(), contentX + 5, contentY, contentW - 10, 28)
			contentY :+ 28
			skin.fontNormal.draw("Letzte Stunde im Plan: "+latestPlannedEndHour, contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Letzte Trailerstunde im Plan: "+latestPlannedTrailerHour, contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Tempo: "+MathHelper.NumberToString(data.GetSpeed(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Kritik: "+MathHelper.NumberToString(data.GetReview(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Kinokasse: "+MathHelper.NumberToString(data.GetOutcome(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("TV-Kasse: "+MathHelper.NumberToString(data.GetOutcomeTV(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Preismodifikator: "+MathHelper.NumberToString(data.GetModifier("price"), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Qualitaet roh: "+MathHelper.NumberToString(GetQualityRaw(), 4)+"  (ohne Alter, Wdh.)", contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Qualitaet: "+MathHelper.NumberToString(GetQuality(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Aktualitaet: "+MathHelper.NumberToString(GetTopicality(), 4)+" von " + MathHelper.NumberToString(data.GetMaxTopicality(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Bloecke: "+data.GetBlocks(), contentX + 5, contentY)
			contentY :+ 12
			if useOwner <= 0
				skin.fontNormal.draw("Ausgestrahlt: "+GetTimesBroadcasted(0)+"x unbekannt, "+GetTimesBroadcasted()+"x alle  Limit:"+broadcastLimit, contentX + 5, contentY)
			else
				skin.fontNormal.draw("Ausgestrahlt: "+GetTimesBroadcasted(useOwner)+"x Spieler, "+GetTimesBroadcasted()+"x alle  Limit:"+broadcastLimit, contentX + 5, contentY)
			endif
			contentY :+ 12	
			skin.fontNormal.draw("Quotenrekord: "+Long(GetBroadcastStatistic().GetBestAudienceResult(useOwner, -1).audience.GetTotalSum())+" (Spieler), "+Long(GetBroadcastStatistic().GetBestAudienceResult(-1, -1).audience.GetTotalSum())+" (alle)", contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Preis: "+GetPrice(useOwner), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Trailerakt.-modifikator: "+MathHelper.NumberToString(data.GetTrailerMod().GetTotalAverage(), 4), contentX + 5, contentY)
		endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)

		'=== X-Rated Overlay ===
		If data.IsXRated()
			GetSpriteFromRegistry("gfx_datasheet_overlay_xrated").Draw(contentX + sheetWidth, y, -1, ALIGN_RIGHT_TOP)
		Endif
	End Method


	Method ShowTrailerSheet:Int(x:Int,y:Int, align:int=0, useOwner:int = -1, extraData:TData = null)
		if useOwner = -1 then useOwner = owner
		
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 310
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("trailer")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, genreH:int = 16, descriptionH:int = 70
		local barH:int = 0, msgH:int = 0
		local msgAreaH:int = 0, barAreaH:int = 0
		local barAreaPaddingY:int = 4, msgAreaPaddingY:int = 4

		'reactivate when adding messages
		'msgH = skin.GetMessageSize(contentW - 10, -1, "", "targetGroupLimited", "warning", null, ALIGN_CENTER_CENTER).GetY()
		barH = skin.GetBarSize(100, -1).GetY()

		'bar area
		'bar area starts with padding, ends with padding and contains
		barAreaH = 2 * barAreaPaddingY + barH

		'message area
		'show earn message
		rem
		'TODO: add messages? ("shown max already - no efficiency increase")
		'if blaCondition > 0 then msgAreaH :+ msgH
		'if there are messages, add padding of messages
		if msgAreaH > 0 then msgAreaH :+ msgAreaPaddingY
		'if nothing comes after the messages, add bottom padding
		if msgAreaH > 0 and barAreaH=0 then msgAreaH :+ msgAreaPaddingY
		endrem
		
		'total height
		sheetHeight = titleH + genreH + descriptionH + msgAreaH + barAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()


		
		'=== RENDER ===
	
		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH


		'=== GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		skin.fontNormal.drawBlock(GetLocale("TRAILER"), contentX + 5, contentY -1, contentW - 10, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ genreH


		'=== CONTENT AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.drawBlock(getLocale("MOVIE_TRAILER"), contentX + 5, contentY + 3, contentW - 10, descriptionH, null, skin.textColorNeutral)
		contentY :+ descriptionH
		

		'=== MESSAGES ===
		'background for messages + boxes
		skin.RenderContent(contentX, contentY, contentW, msgAreaH + barAreaH , "1_bottom")
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		'=== BARS ===
		'bars have a top-padding
		contentY :+ barAreaPaddingY

		'topicality
		skin.RenderBar(contentX + 5, contentY, 200, 12, data.GetTrailerTopicality())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)


		If TVTDebugInfos
			'begin at the top ...again
			contentY = y + skin.GetContentY()

			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.draw("Trailer: "+GetTitle(), contentX + 5, contentY)
			contentY :+ 14	
			skin.fontNormal.draw("Traileraktualitaet: "+MathHelper.NumberToString(data.GetTrailerTopicality(), 4)+" von " + MathHelper.NumberToString(data.GetMaxTrailerTopicality(), 4), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Ausstrahlungen: "+data.trailerAired, contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Ausstrahlungen seit letzter Sendung: "+data.trailerAiredSinceShown, contentX + 5, contentY)
		Endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
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
	Method GetPricePerBlock:Int(broadcastType:int) {_exposeToLua}
		if broadcastType = 0 then broadcastType = TVTBroadcastMaterialType.PROGRAMME
		return GetPrice(owner) / GetBlocksTotal(broadcastType)
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method GetQualityLevel:Int() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData()
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





'create all filters
TProgrammeLicenceFilter.Init()

Type TProgrammeLicenceFilter
	Field caption:string = ""
	Field genres:Int[]
	Field dataFlags:int
	Field notDataFlags:int
	Field checkAvailability:int = True
	Field checkTradeability:int = False
	Field checkVisibility:int = True
	Field qualityMin:Float = -1.0
	Field qualityMax:Float = -1.0
	Field relativeTopicalityMin:Float = -1.0
	Field relativeTopicalityMax:Float = -1.0
	Field maxTopicalityMin:Float = -1.0
	Field maxTopicalityMax:Float = -1.0
	Field licenceTypes:int[]
	Field forbiddenLicenceTypes:int[]
	Field childrenForbidden:int = False
	Field requiredOwners:int[]
	Field forbiddenOwners:int[]
	Field priceMin:int = -1
	Field priceMax:int = -1
	Field releaseTimeMin:Long = -1
	Field releaseTimeMax:Long = -1
	Field checkAgeMin:int = False
	Field checkAgeMax:int = False
	Field ageMin:Long = 0
	Field ageMax:Long = 0
	Field checkTimeToReleaseMin:int = False
	Field checkTimeToReleaseMax:int = False
	Field timeToReleaseMin:Long = 0
	Field timeToReleaseMax:Long = 0
	Field playerID:int = 0
	Field displayInMenu:int = False
	Field id:int = 0

	Global filters:TList = CreateList()
	Global visibleCount:int = -1
	Global lastID:Int=0


	Method New()
		lastID:+1
		id = lastID
	End Method


	function Init()
		'reset old filters
		filters = CreateList()

		'flags having custom categories
		local categoryFlags:int = TVTProgrammeDataFlag.PAID | TVTProgrammeDataFlag.LIVE | TVTProgrammeDataFlag.TRASH

		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([1])			'adventure
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([2])			'action
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([4, 17])		'crime & thriller
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([5])			'comedy
		'documentation & reportage
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([6, 300, 301]).SetCaption("PROGRAMME_GENRE_DOCUMENTARIES_AND_FEATURES")
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([7])			'drama
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([8])			'erotic
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([9, 3])			'family & cartoons
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([10, 14])		'fantasy & mystery
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([11])			'history
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([12])			'horror
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([13])			'monumental
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([15])			'lovestory
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([16])			'scifi
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([18])			'western
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([0])			'undefined
		'show/event -> all categories
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([100, 101, 102, 103, 200, 201, 202, 203, 204]).SetCaption("PROGRAMME_GENRE_SHOW_AND_EVENTS")
		CreateVisible().SetDataFlag(TVTProgrammeDataFlag.LIVE)						'live
'		CreateVisible().SetDataFlag(TVTProgrammeDataFlag.TRASH).AddGenres([301])	'Trash + Yellow Press

		'either trash - or genre 301 (yellow press)
		local trash:TProgrammeLicenceFilterGroup = TProgrammeLicenceFilterGroup.CreateVisible()
		trash.SetConnectionType(TProgrammeLicenceFilterGroup.CONNECTION_TYPE_OR)
		'store config in group for proper caption
		trash.SetDataFlag(TVTProgrammeDataFlag.TRASH).AddGenres([301])
		trash.AddFilter( new TProgrammeLicenceFilter.SetDataFlag(TVTProgrammeDataFlag.TRASH).ForbidChildren())
		trash.AddFilter( new TProgrammeLicenceFilter.AddGenres([301]).ForbidChildren() )

		CreateVisible().SetDataFlag(TVTProgrammeDataFlag.PAID)						'Call-In
	End Function


	Method InitFrom:TProgrammeLicenceFilter(otherFilter:TProgrammeLicenceFilter)
		caption = otherFilter.caption
		checkTradeability = otherFilter.checkTradeability
		checkAvailability = otherFilter.checkAvailability
		checkVisibility = otherFilter.checkVisibility
		dataFlags = otherFilter.dataFlags
		notDataFlags = otherFilter.notDataFlags
		for local i:int = EachIn otherFilter.genres
			genres :+ [i]
		Next
		licenceTypes = otherFilter.licenceTypes[.. otherFilter.licenceTypes.length]
		forbiddenLicenceTypes = otherFilter.forbiddenLicenceTypes[.. otherFilter.forbiddenLicenceTypes.length]
		requiredOwners = otherFilter.requiredOwners[.. otherFilter.requiredOwners.length]
		forbiddenOwners = otherFilter.forbiddenOwners[.. otherFilter.forbiddenOwners.length]
		qualityMin = otherFilter.qualityMin
		qualityMax = otherFilter.qualityMin
		relativeTopicalityMin = otherFilter.relativeTopicalityMin
		relativeTopicalityMax = otherFilter.relativeTopicalityMax
		maxTopicalityMin = otherFilter.maxTopicalityMin
		maxTopicalityMax = otherFilter.maxTopicalityMax
		'for local i:int = EachIn otherFilter.licenceTypes
		'	licenceTypes :+ [i]
		'Next
		priceMin = otherFilter.priceMin
		priceMax = otherFilter.priceMax
		releaseTimeMin = otherFilter.releaseTimeMin
		releaseTimeMax = otherFilter.releaseTimeMax
		ageMin = otherFilter.ageMin
		ageMax = otherFilter.ageMax
		checkAgeMin = otherFilter.checkAgeMin
		checkAgeMax = otherFilter.checkAgeMax

		timeToReleaseMin = otherFilter.timeToReleaseMin
		timeToReleaseMax = otherFilter.timeToReleaseMax
		checkTimeToReleaseMin = otherFilter.checkTimeToReleaseMin
		checkTimeToReleaseMax = otherFilter.checkTimeToReleaseMax

		childrenForbidden = otherFilter.childrenForbidden
		displayInMenu = otherFilter.displayInMenu

		return self
	End Method


	Method Copy:TProgrammeLicenceFilter()
		return New TProgrammeLicenceFilter.InitFrom(self)
	End Method


	'creates a new filter and sets it up to get displayed in the licence
	'selection menu
	Function CreateVisible:TProgrammeLicenceFilter()
		local obj:TProgrammeLicenceFilter = new TProgrammeLicenceFilter
		obj.displayInMenu = True
		'obj.SetForbiddenLicenceTypes( [TVTProgrammeLicenceType.EPISODE] )
		obj.ForbidChildren()

		'add to list
		Add(obj)

		return obj
	End Function


	Function Add:TProgrammeLicenceFilter(filter:TProgrammeLicenceFilter)
		filters.AddLast(filter)

		'invalidate cached vars
		visibleCount :-1

		return filter
	End Function


	Method SetCaption(caption:String)
		self.caption = caption
	End Method


	Method GetCaption:string()
		if caption then return GetLocale(caption)

		local result:string
'		if result = ""
			local flag:int = 0
			For local flagNumber:int = 0 to 7 'manual limitation to "7" to exclude series/paid?
				flag = 2^flagNumber
				'contains that flag?
				if dataFlags & flag > 0
					if result <> "" then result :+ " & "
					result :+ GetLocale("PROGRAMME_FLAG_" + TVTProgrammeDataFlag.GetAsString(flag))
				endif
			Next
'		endif

		For local entry:int = EachIn GetGenres()
			if result <> "" then result :+ " & "
			result :+ GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(entry))
		Next
		return result
	End Method


	Function GetCount:Int()
		return filters.Count()
	End Function


	Function GetVisibleCount:Int()
		if visibleCount >= 0 then return visibleCount

		visibleCount = 0
		For local f:TProgrammeLicenceFilter = EachIn filters
			if f.displayInMenu then visibleCount :+ 1
		Next
		return visibleCount
	End Function


	Function GetVisible:TProgrammeLicenceFilter[]()
		local result:TProgrammeLicenceFilter[]
		For local f:TProgrammeLicenceFilter = EachIn filters
			if f.displayInMenu then result :+ [f]
		Next
		return result
	End Function


	'returns a filter which contains ALL given genres and flags
	'so it is like "genre1 AND genre2 AND flag1 AND flag2"
	Function Get:TProgrammeLicenceFilter(genres:int[], dataFlags:int=0)
		local result:TProgrammeLicenceFilter
		For local filter:TProgrammeLicenceFilter = EachIn filters
			if genres.length > 0
				for local genre:int = eachin genres
					local foundGenre:int = False
					for local filterGenre:int = eachin filter.genres
						if filterGenre = genre then foundGenre = True;exit 
					Next
					'if the genre was not found, the filter is not the right
					'one -> exit the genre loop
					if not foundGenre
						result = Null
						exit
					else
						result = filter
					endif
				Next
				if not result then continue
			endif

			'check dataFlags
			'skip if not all were set
			if (filter.dataFlags & dataFlags) <> dataFlags then continue

			'found the filter
			return filter
		Next
		return result
	End Function


	Function GetAtIndex:TProgrammeLicenceFilter(index:int)
		return TProgrammeLicenceFilter(filters.ValueAtIndex(index))
	End Function


	Method ToString:String()
		local g:string = ""
		for local i:int = eachin genres
			if g<>"" then g:+ ", "
			g:+ i
		Next

		return "filter["+id+"]  genres=~q"+g+"~q  dataflags="+dataFlags
	End Method


	Method ForbidChildren:TProgrammeLicenceFilter(bool:int=True)
		childrenForbidden = bool
		return self
	End Method
	

	Method AddGenres:TProgrammeLicenceFilter(newGenres:int[])
		For local newGenre:int = eachIn newGenres
			For local genre:int = EachIn genres
				'skip if genre exists already
				if genre = newGenre then continue
			Next
			genres :+ [newGenre]
		Next
		return self
	End Method


	Method SetDataFlag:TProgrammeLicenceFilter(flag:int, enable:int = 1)
		If enable
			dataFlags :| flag
		Else
			dataFlags :& ~flag
		EndIf
		return self
	End Method


	Method SetNotDataFlag:TProgrammeLicenceFilter(flag:int, enable:int = 1)
		If enable
			notDataFlags :| flag
		Else
			notDataFlags :& ~flag
		EndIf

		return self
	End Method


	Method GetGenres:int[]()
		return genres
	End Method


	Method SetForbiddenOwners:TProgrammeLicenceFilter(owners:int[])
		forbiddenOwners = owners[ .. owners.length]
		return self
	End Method


	Method SetRequiredOwners:TProgrammeLicenceFilter(owners:int[])
		requiredOwners = owners[ .. owners.length]
		return self
	End Method


	Method SetForbiddenLicenceTypes:TProgrammeLicenceFilter(types:int[])
		forbiddenLicenceTypes = types[ .. types.length]
		return self
	End Method


	Method SetLicenceTypes:TProgrammeLicenceFilter(types:int[])
		licenceTypes = types[ .. types.length]
		return self
	End Method


	'checks if the given programmelicence contains at least ONE of the given
	'filter criterias ("OR"-chain of criterias)
	'Ex.: filter cares for genres 1,2 and flags "trash" and "bmovie"
	'     True is returned genre 1 or 2 or flag "trash" or flag "bmovie"
	Method DoesFilter:Int(licence:TProgrammeLicence)
		if not licence then return False

		if checkAvailability and not licence.isAvailable() then return False
		if checkTradeability and not licence.isTradeable() then return False
		if checkVisibility and not licence.isVisible() then return False

		if childrenForbidden and licence.parentLicenceGUID then return False
		
		'check flags filter does NOT care for
		if notDataFlags > 0 and (licence.GetDataFlags() & notDataFlags) > 0 then return False

		'check if it fits to the desired genres
		if genres.length > 0
			local licenceGenre:int = licence.GetGenre()
			local hasGenre:int = False
			for local genre:int = eachin genres
				if licenceGenre = genre then hasGenre = True;exit
			Next
			if not hasGenre then return False
		endif

		'check quality (not qualityRaw which ignores age, airedtimes,...)
		if qualityMin >= 0 and licence.GetQuality() < qualityMin then return False
		if qualityMax >= 0 and licence.GetQuality() > qualityMax then return False

		'check relative topicality (topicality/maxTopicality)
		if relativeTopicalityMin >= 0 and licence.GetRelativeTopicality() < relativeTopicalityMin then return False
		if relativeTopicalityMax >= 0 and licence.GetRelativeTopicality() > relativeTopicalityMax then return False

		'check absolute topicality (maxTopicality)
		'this is done to avoid selling "no longer useable entries"
		if maxTopicalityMin >= 0 and licence.GetMaxTopicality() < maxTopicalityMin then return False
		if maxTopicalityMax >= 0 and licence.GetMaxTopicality() > maxTopicalityMax then return False

		'check price
		if priceMin >= 0 and licence.GetPrice(playerID) < priceMin then return False
		if priceMax >= 0 and licence.GetPrice(playerID) > priceMax then return False

		'check release time (absolute value)
		if releaseTimeMin >= 0 and licence.data.GetReleaseTime() < releaseTimeMin then return False
		if releaseTimeMax >= 0 and licence.data.GetReleaseTime() > releaseTimeMax then return False

		'check age (relative value)
		if checkAgeMin and GetWorldTime().GetTimeGone() - licence.data.GetReleaseTime() < ageMin then return False
		if checkAgeMax and GetWorldTime().GetTimeGone() - licence.data.GetReleaseTime() > ageMax then return False

		'check time to relase (aka "negative age")
		if checkTimeToReleaseMin and licence.data.GetReleaseTime() - GetWorldTime().GetTimeGone() < timeToReleaseMin then return False
		if checkTimeToReleaseMax and licence.data.GetReleaseTime() - GetWorldTime().GetTimeGone() > timeToReleaseMax then return False

		'check licenceType
		if licenceTypes.length > 0
			local hasType:int = False
			for local licenceType:int = eachin licenceTypes
				if licenceType = licence.licenceType then hasType = True;exit
			Next
			if not hasType then return False
		endif

		'check if licenceType is one of the forbidden types
		'if so, filter fails
		if forbiddenLicenceTypes.length > 0
			for local licenceType:int = eachin forbiddenLicenceTypes
				if licenceType = licence.licenceType then return False
			Next
		endif
		
		'check if owner is one of the owners required for the filter
		'if not, filter failed
		if requiredOwners.length > 0
			local hasOwner:int = False
			for local owner:int = eachin requiredOwners
				if owner = licence.owner then hasOwner = True;exit
			Next
			if not hasOwner then return False
		endif

		'check if owner is one of the forbidden owners
		'if so, filter fails
		if forbiddenOwners.length > 0
			for local owner:int = eachin forbiddenOwners
				if owner = licence.owner then return False
			Next
		endif
				
		'check flags share something
		if dataFlags > 0 and (licence.GetDataFlags() & dataFlags) <= 0 then return False

		return True
	End Method
End Type




'filters checked via "OR" (a or b) or "AND" (a and b)
Type TProgrammeLicenceFilterGroup extends TProgrammeLicenceFilter
	Field filters:TProgrammeLicenceFilter[]
	Field connectionType:int = 0
	Const CONNECTION_TYPE_OR:int = 0
	Const CONNECTION_TYPE_AND:int = 1


	'creates a new filter and sets it up to get displayed in the licence
	'selection menu
	Function CreateVisible:TProgrammeLicenceFilterGroup()
		local obj:TProgrammeLicenceFilterGroup = new TProgrammeLicenceFilterGroup
		obj.displayInMenu = True

		'add to list
		Add(obj)

		return obj
	End Function


	Method InitFrom:TProgrammeLicenceFilterGroup(otherFilter:TProgrammeLicenceFilter)
		if TProgrammeLicenceFilterGroup(otherFilter)
			local otherFilterGroup:TProgrammeLicenceFilterGroup = TProgrammeLicenceFilterGroup(otherFilter)
			connectionType = otherFilterGroup.connectionType
			for local f:TProgrammeLicenceFilter = EachIn otherFilterGroup.filters
				filters :+ [f.Copy()]
			Next
		else
			Super.InitFrom(otherFilter)
		endif
		return self
	End Method


	Method Copy:TProgrammeLicenceFilterGroup()
		return New TProgrammeLicenceFilterGroup.InitFrom(self)
	End Method
	

	Method AddFilter:TProgrammeLicenceFilterGroup(filter:TProgrammeLicenceFilter)
		filters :+ [filter]
		return self
	End Method


	Method SetConnectionType:TProgrammeLicenceFilterGroup(connectionType:int = 0)
		self.connectionType = connectionType
		return self
	End Method
	
	
	Method DoesFilter:Int(licence:TProgrammeLicence)
		if filters.length = 0 then return Super.DoesFilter(licence)
		
		if connectionType = CONNECTION_TYPE_OR
			For local filter:TProgrammeLicenceFilter = Eachin filters
				if filter.DoesFilter(licence) then return True
			Next
			return False
		else
			For local filter:TProgrammeLicenceFilter = Eachin filters
				if filter <> filters[filters.length - 1]
					if not filter.DoesFilter(licence) then return False
				else
					'last filter - if this is reached, all others filtered
					'ok and this one might return desired result
					if filter.DoesFilter(licence) then return True
				endif
			Next
			return False
		endif
	End Method
End Type