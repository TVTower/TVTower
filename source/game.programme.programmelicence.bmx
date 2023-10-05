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
Import "game.programme.programmedata.specials.bmx"
Import "game.player.base.bmx"
Import "game.player.finance.bmx"
Import "game.broadcast.audience.bmx"
Import "game.broadcast.broadcaststatistic.bmx"
Import "basefunctions.bmx" 'CreateEmptyImage()
'to access datasheet-functions
Import "common.misc.datasheet.bmx"




Type TProgrammeLicenceCollection
	'holding all programme licences
	Field licences:TIntMap = new TIntMap
	'holding only licences of special packages containing multiple
	'movies/series
	Field collections:TIntMap = new TIntMap
	'holding only single licences (movies, one-time-events)
	Field singles:TIntMap = new TIntMap
	'holding only series licences
	Field series:TIntMap = new TIntMap

	'cache for faster access
	Field _parentLicences:TIntMap {nosave}
	Field _licencesGUID:TMap {nosave}

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

		_licencesGUID = null
		_parentLicences = null

		return self
	End Method


	Method PrintLicences:int()
		print "--------- singles: " '+singles.GetCount()
		For local single:TProgrammeLicence = Eachin singles.Values()
			print single.GetTitle() + "   [owner: "+single.owner+"]"
		Next
		print "---------"
		print "--------- series: " '+series.GetCount()
		For local serie:TProgrammeLicence = Eachin series.Values()
			print serie.GetTitle() + "   [owner: "+serie.owner+"]"
			For local episode:TProgrammeLicence = Eachin serie.subLicences
				print "'-- "+episode.GetTitle() + "   [owner: "+episode.owner+"]"
			Next
		Next
		print "---------"
		print "--------- collections: " '+collections.Count()
		For local collection:TProgrammeLicence = Eachin collections.Values()
			print collection.GetTitle() + "   [owner: "+collection.owner+"]"
			For local episode:TProgrammeLicence = Eachin collection.subLicences
				print "'-- "+episode.GetTitle() + "   [owner: "+episode.owner+"]"
			Next
		Next
		print "---------"
	End Method


	'add a licence
	Method Add:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		if skipDuplicates and licences.contains(licence.GetID()) then return False

		licences.Insert(licence.GetID(), licence)
		_GetLicencesGUID().Insert(licence.GetGUID(), licence)

		TriggerBaseEvent(GameEventKeys.ProgrammeLicenceCollection_OnAddLicence, null, self, licence)
		return True
	End Method


	Method Remove:Int(licence:TProgrammeLicence)
		if licences.Remove(licence.GetID())
			_GetLicencesGUID().Remove(licence.GetGUID())
			return True
		endif
	End Method


	'checks if the licences list contains the given licence
	Method Contains:Int(licence:TProgrammeLicence)
		if not licence then return False
		return licences.contains(licence.GetID())
	End Method


	'add a licence as single (movie, one-time-event)
	Method AddSingle:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False

		singles.Insert(licence.GetID(), licence)

		return True
	End Method


	Method RemoveSingle:Int(licence:TProgrammeLicence)
		Remove(licence)
		singles.Remove(licence.GetID())
	End Method


	'checks if the singles list contains the given licence
	Method ContainsSingle:Int(licence:TProgrammeLicence)
		if not licence then return False
		return singles.contains(licence.GetID())
	End Method


	'add a licence as series
	Method AddSeries:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False

		series.Insert(licence.GetID(), licence)

		return True
	End Method


	Method RemoveSeries:Int(licence:TProgrammeLicence)
		Remove(licence)
		return series.Remove(licence.GetID())
	End Method


	'checks if the series list contains the given licence
	Method ContainsSeries:Int(licence:TProgrammeLicence)
		if not licence then return False
		return series.contains(licence.GetID())
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

		collections.Insert(licence.GetID(), licence)

		return True
	End Method


	'checks if the collection list contains the given licence
	Method ContainsCollection:Int(licence:TProgrammeLicence)
		if not licence then return False
		return collections.contains(licence.GetID())
	End Method


	Method RemoveCollection:Int(licence:TProgrammeLicence)
		Remove(licence)
		return collections.Remove(licence.GetID())
	End Method


	Method AddCollectionElement:Int(licence:TProgrammeLicence, skipDuplicates:Int = True)
		'all licences should be listed in the "all-licences-list"
		if not Add(licence, skipDuplicates) then return False

		'nothing more to do

		return True
	End Method


	Method RemoveCollectionElement:Int(licence:TProgrammeLicence)
		'TODO: remove from parents sublicence list?

		Remove(licence)
	End Method


	'checks if the licences list contains the given licence
	Method ContainsCollectionElement:Int(licence:TProgrammeLicence)
		return Contains(licence)
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
		if licence.isCollectionElement() then return AddCollectionElement(licence, skipDuplicates)

		return False
	End Method


	'remove a licence from all needed lists
	Method RemoveAutomatic:Int(licence:TProgrammeLicence)
		'skip franchise-licences (parents of frachisees)
		if licence.licenceType = TVTProgrammeLicenceType.FRANCHISE then return False

		'=== SINGLES ===
		if licence.isSingle() then RemoveSingle(licence)

		'=== SERIES ===
		if licence.isSeries() then RemoveSeries(licence)
		if licence.isEpisode() then RemoveEpisode(licence)

		'=== COLLECTIONS ===
		if licence.isCollection() then RemoveCollection(licence)
		if licence.isCollectionElement() then RemoveCollectionElement(licence)

		return True
	End Method


	'returns the id-map to use for the given type
	'this is just important for "random" access as we could
	'also just access "progList" in all cases...
	Method _GetMap:TIntMap(programmeLicenceType:int=0)
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


	Global warnedEmptyRandomFromArray:int = False
	Method GetRandomFromArray:TProgrammeLicence(_arr:TProgrammeLicence[])
		local result:TProgrammeLicence[] = GetRandomsFromArray(_arr, 1)
		if result and result.length > 0 then return result[0]

		if not warnedEmptyRandomFromArray
			TLogger.log("TProgrammeLicence.GetRandomFromArray()", "array is empty (incorrect filter or not enough available licences?)", LOG_DEBUG | LOG_WARNING | LOG_DEV, TRUE)
			warnedEmptyRandomFromArray = true
		endif
		Return Null
	End Method


	Global warnedEmptyRandomsFromArray:int = False
	Method GetRandomsFromArray:TProgrammeLicence[](_arr:TProgrammeLicence[], amount:int = 1)
		If _arr = Null Then Return Null

		'avoid complicated stuff if there is only 1 entry required
		If amount = 1 and _arr.length > 0
			Local Licence:TProgrammeLicence = _arr[randRange(0, _arr.length - 1)]
			If Licence then return [Licence]
		'avoid complicated stuff if there is only all entries are required
		ElseIf _arr.length = amount
			return _arr[ .. ] 'return a copy!
		ElseIf _arr.length >= amount
			local result:TProgrammeLicence[] = new TProgrammeLicence[amount]
			'to avoid returning duplicate entries we use RandRangeArray() which
			'returns a non-colliding set of numbers in the given range
			local randomNumbers:int[] = RandRangeArray(0, _arr.length-1, amount)
			For local i:int = 0 until randomNumbers.length
				result[i] = _arr[randomNumbers[i]]
			Next
			return result
		EndIf
		if not warnedEmptyRandomsFromArray
			TLogger.log("TProgrammeLicence.GetRandomsFromArray()", "array is empty (incorrect filter or not enough available licences?)", LOG_DEBUG | LOG_WARNING | LOG_DEV, TRUE)
			warnedEmptyRandomsFromArray = true
		endif
		Return Null
	End Method


	Method Get:TProgrammeLicence(id:Int)
		return TProgrammeLicence(licences.ValueForKey(id))
	End Method


	Method GetByGUID:TProgrammeLicence(GUID:String)
		return TProgrammeLicence(_GetLicencesGUID().ValueForKey(GUID))
	End Method


	Method SearchByPartialGUID:TProgrammeLicence(GUID:String)
		'skip searching if there is nothing to search
		if GUID.trim() = "" then return Null

		GUID = GUID.ToLower()

		'find first hit
		For local licence:TProgrammeLicence = EachIn _GetLicencesGUID().Values()
			if licence.GetGUID().ToLower().Find(GUID) >= 0
				return licence
			endif
		Next

		return Null
	End Method


	Method GetByFilter:TProgrammeLicence[](filter:TProgrammeLicenceFilter)
		local result:TProgrammeLicence[] = new TProgrammeLicence[20]
		local added:int = 0
		For local Licence:TProgrammeLicence = EachIn licences.Values()
			'ignore already used
			If Licence.IsOwned() Then continue
			'ignore episodes
			If Licence.isEpisode() Then continue
			'ignore collection elements
			If Licence.isCollectionElement() Then continue

			if not filter.DoesFilter(licence) then continue

			'add it to candidates list
			if result.length >= added then result = result[.. result.length + 20]
			result[added] = Licence

			added :+ 1
		Next
		if result.length > added then result = result[.. added]
		return result
	End Method


	Method GetRandom:TProgrammeLicence(programmeLicenceType:int=0, includeEpisodes:int=FALSE)
		'filter to entries we need
		Local Licence:TProgrammeLicence
		Local sourceMap:TIntMap = _GetMap(programmeLicenceType)
		Local candidates:TProgrammeLicence[] = new TProgrammeLicence[20]
		Local candidatesAdded:int = 0

		For Licence = EachIn sourceMap.Values()
			'ignore if filtered out
			If Licence.IsOwned() Then continue
			'ignoring episodes
			If not includeEpisodes and Licence.isEpisode() Then continue
			If not includeEpisodes and Licence.isCollectionElement() Then continue

			'if available (unbought, released..), add it to candidates list
			if candidates.length >= candidatesAdded then candidates = candidates[.. candidates.length + 20]
			candidates[candidatesAdded] = Licence

			candidatesAdded :+ 1
		Next
		if candidates.length > candidatesAdded then candidates = candidates[.. candidatesAdded]

		Return GetRandomFromArray(candidates)
	End Method


	Method GetRandomByFilter:TProgrammeLicence(filter:TProgrammeLicenceFilter, useLicences:TProgrammeLicence[] = null)
		local results:TProgrammeLicence[] = GetRandomsByFilter(filter, 1, useLicences)
		if results and results.length > 0 then return results[0]
		return null
	End Method


	Method GetRandomsByFilter:TProgrammeLicence[](filter:TProgrammeLicenceFilter, amount:int = 1, useLicences:TProgrammeLicence[] = null)
		if not useLicences then useLicences = GetByFilter(filter)

		Return GetRandomsFromArray(useLicences, amount)
	End Method


	'Cache generators
	Method _GetLicencesGUID:TMap()
		if not _licencesGUID
			_licencesGUID = new TMap
			for local licence:TProgrammeLicence = EachIn licences.Values()
				_licencesGUID.Insert(licence.GetGUID(), licence)
			next
		endif
		return _licencesGUID
	End Method


	Method _GetParentLicences:TIntMap()
		if not _parentLicences
			_parentLicences = new TIntMap
			for local licence:TProgrammeLicence = EachIn licences.Values()
				if licence.isEpisode() then continue
				if licence.isCollectionElement() then continue

				_parentLicences.Insert(licence.GetID(), licence)
			next
		endif
		return _parentLicences
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
	'maxTopicality when buying/receiving a licence
	'used to calculate loss of maxTopicality since owning
	Field maxTopicalityOnOwnerchange:Float = -1.0
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
	'the price paid when buying
	Field buyPrice:int = -1
	'licenced audience level when bought/received
	Field licencedAudienceReachLevel:int = -1
	'store stats for each owner
	Field broadcastStatistics:TBroadcastStatistic[]
	'flags:
	'is this licence tradeable? if not, licence cannot get sold.
	'use this eg. for opening programme
	Field licenceFlags:int = TVTProgrammeLicenceFlag.TRADEABLE

	Field extra:TData

'	Field cacheTextOverlay:TImage 			{nosave}
'	Field cacheTextOverlayMode:string = ""	{nosave}	'for which mode the text was cached

	Global modKeyAuctionPriceLS:TLowerString = New TLowerString.Create("auctionPrice")


	Method GenerateGUID:string()
		return "broadcastmaterialsource-programmelicence-"+id
	End Method


	Method GetMaterialSourceType:Int() {_exposeToLua}
		return TVTBroadcastMaterialSourceType.PROGRAMMELICENCE
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
		Return 0
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


	Function SortByRepititions:Int(o1:Object, o2:Object)
		Local p1:TProgrammeLicence = TProgrammeLicence(o1)
		Local p2:TProgrammeLicence = TProgrammeLicence(o2)
		If p2 and p1
			return p1.GetTimesBroadcasted(p1.GetOwner()) - p2.GetTimesBroadcasted(p2.GetOwner())
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
	
	
	'remove empty slots in the sub licences array
	'and also correct episodes
	Method CompactSubLicences:int()
		Local existingCount:Int = 0
		For local i:int = 0 until subLicences.length
			if subLicences[i] then existingCount :+ 1
		Next		
		If subLicences.length > existingCount
			local newSubLicences:TProgrammeLicence[] = new TProgrammeLicence[existingCount]
			local newIndex:Int
			For local i:int = 0 until subLicences.length
				If subLicences[i] 
					newSubLicences[newIndex] = subLicences[i]
					newIndex :+ 1
				EndIf
			Next
			subLicences = newSubLicences		
		EndIf
		
		'repair episodes
		For local i:int = 0 until subLicences.length
			if subLicences[i].episodeNumber >= 0
				subLicences[i].episodeNumber = i + 1
			endif
		Next
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


	'returns how many sub licences EXIST IN TOTAL
	'(includes sublicences of sublicences)
	Method GetSubLicenceCountTotal:int() {_exposeToLua}
		if not subLicences then return 0

		local result:int = 0
		For local i:int = 0 until subLicences.length
			'add 1 for single licences or add the sublicence count
			if subLicences[i] then result :+ Max(1, subLicences[i].GetSublicenceCountTotal())
		Next
		return result
	End Method

	Method GetNextReleaseTime:Long() {_exposeToLua}
		if not subLicences then return data.GetReleaseTime()

		local result:Long = -1
		For local i:int = 0 until subLicences.length
			local subReleaseTime:Long = -1
			if subLicences[i] then subReleaseTime = subLicences[i].GetNextReleaseTime()
			'fetch earliest "still to come" release time
			if subReleaseTime > GetWorldTime().GetTimeGone()
				if result = -1 then result = subReleaseTime
				result = min(subReleaseTime, result)
			endif
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
		if (isSeries() or isCollection()) and licence.data and self.data
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
			SetLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE, False)
		endif

		'refill broadcast limits - or disable tradeability
		'for a series all episode limits are refilled or none - the refill is done if at least one episode has reached its limit
		if GetBroadcastLimitMax() > 0 and (isExceedingBroadcastLimit() or GetSublicenceExceedingBroadcastLimitCount() > 0 )
			if HasLicenceFlag(TVTProgrammeLicenceFlag.LICENCEPOOL_REFILLS_BROADCASTLIMITS)
				'self.getBroadcastLimitMax() cannot be used because it includes the max limit of episodes
				Local myMax:Int = -1
				If HasBroadcastLimitDefined() and HasBroadcastLimitEnabled()
					myMax = Super.GetBroadcastLimitMax()
				ElseIf GetData() And GetData().HasBroadcastLimit() 
					myMax = GetData().GetBroadcastLimitMax()
				EndIf

				ResetBroadCastLimits(self, myMax)
				'maybe handle collections/franchise differently
				if isSeries() And GetSubLicenceCount() > 0
					For Local l:TProgrammeLicence = eachin subLicences
						ResetBroadCastLimits(l, broadcastLimitMax)
					Next
				endif
			else if isExceedingBroadcastLimit() and not HasParentLicence()
				'remove tradeable only if ALL limits are exceeded and do not remove tradeability for sub licences
				'which may lead to inconsisten behaviour
				SetLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE, False)
			endif
		endif

		'refill topicality?
		if HasLicenceFlag(TVTProgrammeLicenceFlag.LICENCEPOOL_REFILLS_TOPICALITY)
			GetData().topicality = GetData().GetMaxTopicality()
		endif

		'do the same for all children
		For local subLicence:TProgrammeLicence = EachIn subLicences
			subLicence.GiveBackToLicencePool()
		Next

		'inform others about a now unused licence
		TriggerBaseEvent(GameEventKeys.ProgrammeLicence_OnGiveBackToLicencePool, null, self)

		return True

		'reset each licence to its own limit; parent limit as fallback
		Function ResetBroadCastLimits(licence:TProgrammeLicence, defaultLimit:Int = -1)
			Local max:Int=licence.broadCastLimitMax
			'use own limit if present, default limit otherwise
			If max < 0 And licence.GetData() Then max = licence.GetData().broadCastLimitMax
			If max < 0 Then max = defaultLimit
			licence.SetBroadCastLimit(max)
		EndFunction
	End Method


	Method isProgrammeType:int(programmeDataType:int) {_exposeToLua}
		return GetData() and GetData().isType(programmeDataType)
	End Method


	Method isLive:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			return data.IsLive()
		endif
		'is live as soon as one sub-licence is still live
		For local licence:TProgrammeLicence = eachin subLicences
			if licence.isLive() then return True
		Next
		return False
	End Method

	Method isAlwaysLive:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			return data.IsAlwaysLive()
		endif
		'is alwayslive as soon as one sub-licence is live (live date cannot be shown for header)
		For local licence:TProgrammeLicence = eachin subLicences
			if licence.isLive() then return True
		Next
		return False
	End Method

	Method isXRated:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			return data.IsXRated()
		endif
		'is live as soon as one sub-licence is still live
		For local licence:TProgrammeLicence = eachin subLicences
			if licence.IsXRated() then return True
		Next
		return False
	End Method


	Method isLiveOnTape:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			return data.IsLiveOnTape()
		endif
		'is live-on-tape as soon as one sub-licence is (already) live-on-tape
		For local licence:TProgrammeLicence = eachin subLicences
			if licence.IsLiveOnTape() then return True
		Next
		return False
	End Method


	Method isPaid:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			return data.IsPaid()
		endif
		'is paid as soon as one sub-licence is paid
		For local licence:TProgrammeLicence = eachin subLicences
			if licence.ispaid() then return True
		Next
		return False
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


	Method isCollectionElement:int() {_exposeToLua}
		return licenceType = TVTProgrammeLicenceType.COLLECTION_ELEMENT
	End Method


	Method GetLicenceType:int()
		return licenceType
	End Method


	'override default method to add sublicences
	Method SetOwner:int(owner:int=0)
		if owner <> self.owner
			'remove old trailer data
			data.RemoveTrailerMod(self.owner)

			'fetch original maxTopicality
			maxTopicalityOnOwnerchange = GetMaxTopicality()

			'inform others about the new owner of the licence
			TriggerBaseEvent(GameEventKeys.ProgrammeLicence_onSetOwner, new TData.AddNumber("newOwner", owner).AddNumber("oldOwner", self.owner), self)
		endif

		self.owner = owner
		'do the same for all children
		For local licence:TProgrammeLicence = eachin subLicences
			licence.SetOwner(owner)
		Next

		return TRUE
	End Method


	'override default method to add sublicences
	Method SetLicencedAudienceReachLevel:int(level:int)
		licencedAudienceReachLevel = level

		'do the same for all children
		For local licence:TProgrammeLicence = eachin subLicences
			licence.SetLicencedAudienceReachLevel(level)
		Next

		return True
	End Method


	'returns whether the licence - or AT LEAST ONE sublicence is
	'distributed via TV
	Method IsTVDistribution:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			return data.IsTVDistribution()
		else
			local foundValue:int = False
			For local licence:TProgrammeLicence = eachin subLicences
				if not licence.IsTVDistribution() then return False
				foundValue = True
			Next
			return foundValue
		endif
	end Method

	'returns whether the licence - or AT LEAST ONE sublicence is a
	'custom production of a player
	Method IsAPlayersCustomProduction:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			return data.IsAPlayersCustomProduction()
		else
			local foundValue:int = False
			For local licence:TProgrammeLicence = eachin subLicences
				if not licence.IsAPlayersCustomProduction() then return False
				foundValue = True
			Next
			return foundValue
		endif
	End Method

	Method IsAPlayersUnfinishedCustomProduction:int()
		If not IsAPlayersCustomProduction() return False
		'cannot use isTradeable() because all episodes could be finished but not broadcasted...
		If IsSeries() return Not hasLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE)
		'other cases are considered finished for now
		Return False
	End Method


	'returns whether the licence - or AT LEAST ONE sublicence is a
	'custom production
	Method IsCustomProduction:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			return data.IsCustomProduction()
		else
			local foundValue:int = False
			For local licence:TProgrammeLicence = eachin subLicences
				if not licence.IsCustomProduction() then return False
				foundValue = True
			Next
			return foundValue
		endif
	End Method

	Method IsUnfinishedCustomProduction:int()
		If not IsCustomProduction() return False
		'cannot use isTradeable() because all episodes could be finished but not broadcasted...
		If IsSeries() return Not hasLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE)
		'other cases are considered finished for now
		Return False
	End Method

	'returns whether a single licences tv outcome or AT LEAST ONE
	'sublicences contains unknown TV outcome (eg. was not aired yet)
	Method ContainsUnknownTVOutcome:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			return data.GetOutcomeTV() = -1
		else
			For local licence:TProgrammeLicence = eachin subLicences
				if licence.ContainsUnknownTVOutcome() then return True
			Next

			return False
		endif
	End Method

	'returns whether a single licences or AT LEAST ONE
	'sublicences contains an unknown price (eg. was not aired yet)
	Method ContainsUnknownPrice:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 and GetData()
			'if bought then we know the price...for sure
			If buyPrice >= 0 then Return False
			'if broadcasted we know the price too
			if GetData().GetTimesBroadcasted() > 0 Then Return False
			'make sure the price is not hidden for a live series 
			'defined as programme in the database
			if not GetData().IsAPlayersCustomProduction() Then Return False

			'custom live productions need to be started to know the price
			'No! I think they know the price only after the broadcast
			'If GetData().IsAPlayersCustomProduction() and IsLive()
			'	if GetData().releaseTime < GetWorldTime().GetTimeGone() Then Return False
			'EndIf

			Return True
		else
			For local licence:TProgrammeLicence = eachin subLicences
				if licence.ContainsUnknownPrice() then return True
			Next

			return False
		endif
	End Method


	Method GetBroadcastTimeSlotStart:int() override
		Local result:int = Super.GetBroadcastTimeSlotStart()
		If result = -1 And HasBroadcastTimeSlot()
			If data Then Return data.GetBroadcastTimeSlotStart()
		EndIf
		Return result
	End Method


	Method GetBroadcastTimeSlotEnd:int() override
		Local result:int = Super.GetBroadcastTimeSlotEnd()
		If result = -1 And HasBroadcastTimeSlot()
			If data Then Return data.GetBroadcastTimeSlotEnd()
		EndIf
		Return result
	End Method


	'override
	Method HasBroadcastTimeSlot:int()
		if GetSubLicenceCount() = 0 and GetData()
			'TODO aktuell vereinfacht, Sloteinschränkungen können nicht zurückkommen nachdem sie einmal entfallen sind
			'Wäre nur relevant für in der Datenbank definierte Programme, die wieder in den Ausgangszustand zurückkehreb
			'sollen. Das ist aber über Drehbücher sinnvoller abbildbar.
			'Den Fall nur ein Slot gesetzt würde ich komplett ignorieren (Konfigurationsfehler)
			If Super.HasBroadcastTimeSlot()
				Return True
			Else
				Return GetData().HasBroadcastTimeSlot()
			End If
			rem
			If Super.HasBroadcastTimeSlot()
				'if one of the flags is set to "use data's slots" it
				'depends on data's slot enabled state
				if broadcastTimeSlotStart=-1 or broadcastTimeSlotEnd=-1
					Return GetData().HasBroadcastTimeSlot()
				Else
					Return True
				EndIf
			Else
				Return False
			EndIf
			endrem
		else
			'it is enough if one licence has a time slot
			For local licence:TProgrammeLicence = eachin subLicences
				if licence.HasBroadcastTimeSlot() then return True
			Next

			return False
		endif
	End Method


	'returns maximum maxLimit found in licence or sublicences
	Method GetBroadcastLimitMax:int() override {_exposeToLua}
		local result:int
		
		If HasBroadcastLimitDefined() and HasBroadcastLimitEnabled()
			result = Super.GetBroadcastLimitMax()
		ElseIf GetData() And GetData().HasBroadcastLimit() 
			result = GetData().GetBroadcastLimitMax()
		EndIf

		For local licence:TProgrammeLicence = eachin subLicences
			result = max(result, licence.GetBroadcastLimitMax())
		Next
		return result
	End Method


	Method GetBroadcastLimit:int() override {_exposeToLua}
		local result:int
		
		if GetSubLicenceCount() = 0
			If HasBroadcastLimitDefined() and HasBroadcastLimitEnabled()
				Return Super.GetBroadcastLimit()
			ElseIf GetData() and GetData().HasBroadcastLimit()
				Return GetData().GetBroadcastLimit()
			EndIf
			Return -1
		else
			local maxLimit:int = 0
			local foundLimit:int = 0
			'find biggest limit
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


	Method HasBroadcastLimit:int() override {_exposeToLua}
		If GetSubLicenceCount() = 0
			If Super.HasBroadcastLimit()
				Return True
			ElseIf GetData() and GetData().HasBroadcastLimit() 
				Return True
			Else
				Return False
			EndIf
		EndIf

		For local licence:TProgrammeLicence = eachin subLicences
			if licence.HasBroadcastLimit() then return True
		Next
		return False
	End Method


	'returns amount of sublicences exceeding their broadcast limit
	Method GetSublicenceExceedingBroadcastLimitCount:int() {_exposeToLua}
		if GetSubLicenceCount() = 0 then return 0

		local result:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			if licence.IsExceedingBroadcastLimit() then result :+ 1
		Next
		return result
	End Method


	'return true if all (sub-)licences are exceeding its limits
	Method IsExceedingBroadcastLimit:int() override {_exposeToLua}
		If GetSubLicenceCount() = 0
			'why not super isExceeding? only difference is missing check of broadcastLimitMax
			Return (HasBroadcastLimit() and GetBroadcastLimit() <= 0)
		Else
			'all licences need to exceed the limit
			'return GetSublicenceExceedingBroadcastLimitCount() = GetSubLicenceCount()

			For local licence:TProgrammeLicence = eachin subLicences
				if not licence.IsExceedingBroadcastLimit() then return False
			Next

			return True
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
		'series is not tradeable if the header is not tradeable, either
		if not hasLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE) then return False

		if GetSubLicenceCount() = 0 and GetData()
			'disallow selling a custom production until it was
			'broadcasted at least once
			if GetData().GetTimesBroadcasted() <= 0 and GetData().IsAPlayersCustomProduction()
			'using this would also disable selling live programme
			'if IsTVDistribution() and ContainsUnknownTVOutcome()
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

		finance.SellProgrammeLicence(GetPriceForPlayer(owner, licencedAudienceReachLevel), self)

		'set unused again
		SetOwner( TOwnedGameObject.OWNER_NOBODY )

		return TRUE
	End Method


	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int=-1)
		local finance:TPlayerFinance = GetPlayerFinance(playerID, -1)
		if not finance then return False

		local currentAudienceReachLevel:int = 1
		if GetPlayerBase(playerID) then currentAudienceReachLevel = GetPlayerBase(playerID).GetAudienceReachLevel()

		local priceToPay:int = GetPriceForPlayer(playerID, currentAudienceReachLevel)
		If finance.PayProgrammeLicence(priceToPay, self)
			buyPrice = priceToPay

			'set owners audience reach level
			SetLicencedAudienceReachLevel( currentAudienceReachLevel )

			SetOwner(playerID)
			Return TRUE
		EndIf
		Return FALSE
	End Method


	Method HasParentLicence:int() {_exposeToLua}
		return self.parentLicenceGUID <> ""
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


	'returns the next _available_ licence of a licences parent sublicences
	Method GetNextAvailableSubLicence:TProgrammeLicence() {_exposeToLua}
		if not parentLicenceGUID then return Null

		'find my position and add 1
		local myArrayIndex:int = GetParentLicence().GetSubLicencePosition(self)
		local subLicenceCount:int = GetParentLicence().GetSubLicenceCount()
		local choosenLicence:TProgrammeLicence

		'using "to" also checks the given licence at the end so it
		'will at least return "self" if this licence is available
		For local i:int = 1 to subLicenceCount
		'For local i:int = 1 until subLicenceCount
			local nextArrayIndex:int = myArrayIndex + i
			if nextArrayIndex >= subLicenceCount then nextArrayIndex = 0

			'Ronny 2017/05/26: disabled to "wrap around" to the first
			'episode if there is no other available episode available for
			'now (only 1 episode in the series produced)
			'-> shift-clicking on a single-episode-series in the programme
			'   planner will return "self" then

			'nothing found
			'if nextArrayIndex = myArrayIndex then return Null

			choosenLicence = GetParentLicence().GetSubLicenceAtIndex(nextArrayIndex)
			if choosenLicence and choosenLicence.isAvailable() then return choosenLicence
		Next

		return null
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



	Method CanStartBroadcastAtTime:int(broadcastType:int, day:int, hour:int) {_exposeToLua}
		'check timeslot limits (ignoring days!)
		If not CanStartBroadcastAtTimeSlot(broadcastType, day, hour) then Return False

		'check live-programme
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if self.IsLive()
				'TODO check release Date?; may not be necessary due to IsAvailable
				'currrently no bugs found with programmes 
				if data.IsAlwaysLive() and data.isReleased() then return True

				'hour or day incorrect
				if GameRules.onlyExactLiveProgrammeTimeAllowedInProgrammePlan
					if GetWorldTime().GetDayHour( data.GetReleaseTime() ) <> hour then return False
					if GetWorldTime().GetDay( data.GetReleaseTime() ) <> day then return False
				'all times after the live event are allowed too
				else
					'live happens on a later day
					if GetWorldTime().GetDay( data.GetReleaseTime() ) > day
						return False
					'live happens on that day but on a later hour
					elseif GetWorldTime().GetDay( data.GetReleaseTime() ) = day
						if GetWorldTime().GetDayHour( data.GetReleaseTime() ) > hour then return False
					endif
				endif
			endif
		endif

		return Super.CanStartBroadcastAtTime(broadcastType, day, hour)
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


	Method GetGenres:int[]() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return [getGenre()]

		'return genre if one was defined (overriding episodes)
		if GetData() and GetData().GetGenre() >= 0 then return [GetData().GetGenre()]


		local genres:int[] = new Int[0]
		local subGenres:int[] = new Int[0]
		For local licence:TProgrammeLicence = eachin subLicences
			For local genre:int = Eachin licence.GetGenres()
				if genre > genres.length-1 then genres = genres[..genre+1]
				genres[genre]:+1
			Next
		Next
		For local i:int = 0 to genres.length-1
			if genres[i] = 0 then continue

			subGenres :+ [ i ]
		Next

		return subGenres
	End Method


	Method GetSubGenres:int[]() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0 and GetData() then return GetData().subGenres

		'return genre if one was defined (overriding episodes)
		if GetData() and GetData().subGenres and GetData().subGenres.length >= 0 then return GetData().subGenres

		local genres:int[] = new Int[0]
		local subGenres:int[] = new Int[0]
		For local licence:TProgrammeLicence = eachin subLicences
			For local genre:int = Eachin licence.GetSubGenres()
				if genre > genres.length-1 then genres = genres[..genre+1]
				genres[genre]:+1
			Next
		Next
		For local i:int = 0 to genres.length-1
			if genres[i] = 0 then continue

			subGenres :+ [ i ]
		Next

		return subGenres
	End Method


	Method GetGenreString:String(_genre:Int=-1)
		'return the string of the best genre of the licence (packet)
		if GetData() then return GetData().GetGenreString( GetGenre() )
		return ""
	End Method


	Method GetGenresLine:String()
		local genres:int[] = GetGenres()
		local subGenres:int[] = GetSubGenres()

		'add all subgenres not existing in genres
		if subGenres.length > genres.length then genres = genres[.. subGenres.length]
		For local i:int = 0 until subGenres.length
			if MathHelper.InIntArray(subGenres[i], genres) then continue

			genres[i] :+ subGenres[i]
		Next

		local genreLine:string
		local genreStrings:string[]
		'add maingenre
		genreLine = GetGenreString()
		'add culture first, so it is "visible" also for long entries
		if HasDataFlag(TVTProgrammeDataFlag.CULTURE)
			genreStrings :+ [ "|i|" + GetLocale("PROGRAMME_FLAG_CULTURE") +"|/i|" ]
		endif

		local mainGenre:int = GetGenre()
		For local i:int = 0 until subgenres.length
			if subgenres[i] = mainGenre then continue
			genreStrings :+ [TProgrammeData._GetGenreString(subgenres[i])]
		Next

		if genreStrings and genreStrings.length > 0
			genreLine = "|b|"+genreLine+"|/b|, " + ", ".Join(genreStrings)
		endif

		return genreLine
	End Method

	'override
	'checks flags of all data-objects contained in self and sublicences
	Method HasDataFlag:Int(flag:Int) {_exposeToLua}
		return GetDataFlags() & flag
	End Method


	'override
	'checks flags of all data-objects contained in self and sublicences
	Method HasBroadcastFlag:Int(flag:Int) {_exposeToLua}
		return GetBroadcastFlags() & flag
	End Method


	'override
	'checks flags of all data-objects contained in self and sublicences
	Method HasFlag:Int(flag:Int) {_exposeToLua}
		return (GetFlags() & flag) <> 0
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
		if GetSubLicenceCount() = 0 and GetData() 
			'data did not define one but licence? 
			If not GetData().broadcastFlags 
				If broadcastFlags
					Return broadcastFlags.GetMask()
				Else
					Return 0
				EndIf
			Else
				Return GetData().broadcastFlags.GetMixMask(broadcastFlags)
			EndIf
		endif

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


	'override
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
				if GetSubLicenceCount() = 0
					Return GetData().GetBlocks()
				else
					Return floor(GetBlocksTotal(broadcastType) / float(GetSublicenceCountTotal()) + 0.5)
				endif
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


	Method GetSpeed:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0
			if GetData() then return GetData().GetSpeed()
			return 0.0
		endif

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetSpeed()
		Next
		return value / subLicences.length
	End Method


	Method GetReview:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0
			if GetData() then return GetData().GetReview()
			return 0.0
		endif

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetReview()
		Next
		return value / subLicences.length
	End Method


	'returns outcome - or average of children with outcome
	Method GetOutcome:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0
			if GetData() then return GetData().GetOutcome()
			return 0.0
		endif

		'licence for a package or series
		'ATTENTION: if one of the licences contains no outcome, it gets
		'           ignored in the calculation!
		Local value:Float
		local ignored:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			local licenceValue:Float = licence.GetOutcome()
			if licenceValue > 0
				value :+ licence.GetOutcome()
			else
				ignored :+ 1
			endif
		Next
		if subLicences.length > ignored
			return value / (subLicences.length - ignored)
		else
			return 0.0
		endif
	End Method


	'returns outcomeTV - or average of children with outcome
	Method GetOutcomeTV:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0
			if GetData() then return GetData().GetOutcomeTV()
			return 0.0
		endif

		'return a manual assigned value (instead of calculated by sublicences)
		if GetData() and data.GetOutcomeTV() >= 0
			return data.GetOutcomeTV()
		endif

		'licence for a package or series
		'ATTENTION: if one of the licences contains no outcome, it gets
		'           ignored in the calculation!
		Local value:Float
		local ignored:int = 0
		For local licence:TProgrammeLicence = eachin subLicences
			local licenceValue:Float = licence.GetOutcomeTV()
			if licenceValue > 0
				value :+ licence.GetOutcomeTV()
			else
				ignored :+ 1
			endif
		Next
		if subLicences.length > ignored
			return value / (subLicences.length - ignored)
		else
			return 0.0
		endif
	End Method


	Method GetDescription:string() {_exposeToLua}
		if not description and GetData() then return GetData().GetDescription()

		return Super.GetDescription()
	End Method


	'returns the (avg) relative topicality of a licence (package)
	Method GetRelativeTopicality:Float() {_exposeToLua}
		local mTopicality:Float = GetMaxTopicality()
		if mTopicality = 0 then return 0

		return GetTopicality() / mTopicality
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


	Method GetMaxTopicalityOnOwnerChange:Float() {_exposeToLua}
		'single-licence
		if GetSubLicenceCount() = 0
			if maxTopicalityOnOwnerchange < 0 then maxTopicalityOnOwnerchange = GetMaxTopicality()
			return maxTopicalityOnOwnerchange
		endif

		'licence for a package or series
		Local value:Float
		For local licence:TProgrammeLicence = eachin subLicences
			value :+ licence.GetMaxTopicalityOnOwnerChange()
		Next

		if subLicences.length > 0 then return value / subLicences.length
		return 0.0
	End Method


	'returns the avg left maxTopicality compared to when bough/received
	Method GetRelativeMaxTopicalityLoss:Float() {_exposeToLua}
		return 1.0 - (GetMaxTopicality() / GetMaxTopicalityOnOwnerChange())
	End Method


	Method GetAudienceReachLevelPriceMod:Float(audienceReachLevel:int)
		'price modifier should grow slower; good movies are affordable even in higher levels
		'0.5; 0.65; 0.85; 1.1; 
		return (1.3 ^ Max(0, audienceReachLevel-1))/2

		'0.5;    1;  1.5;   2;...
		'return (0.5*Max(1, audienceReachLevel))
		
	End Method


	Method GetPriceForPlayer:int(playerID:int, audienceReachLevel:int = -1)
		Local value:Float

		'single-licence
		if GetSubLicenceCount() = 0 and GetData()
			value = GetData().GetPrice(playerID)
		else
			'licence for a package or series
			For local licence:TProgrammeLicence = eachin subLicences
				value :+ licence.GetPriceForPlayer(playerID, audienceReachLevel)
			Next
			value :* 0.90
		endif


		'=== INDIVIDUAL PRICE ===
		'individual licence price mod (eg. "special collection discount")
		value :* GetModifier(modKeyPriceLS)

		'=== AUCTION PRICE ===
		'if this licence was won in an auction, this price is modifying
		'the real one
		value :* GetModifier(modKeyAuctionPriceLS)

		'=== DIFFICULTY ===
		'eg. "auctions" set this flag
		if not HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY)
			value :* GetPlayerDifficulty(playerID).programmePriceMod
		endif


		'=== AUDIENCE REACH LEVEL ===
		'only do this for single licences or child licences to avoid
		'multiplying what is already multiplied
		if GetSubLicenceCount() = 0 and GetData()
			if audienceReachLevel <= 0
				if GetPlayerBase(playerID)
					audienceReachLevel = Max(1, GetPlayerBase(playerID).GetAudienceReachLevel())
				else
					'default to 0 to skip modification
					audienceReachLevel = 0
				endif
			endif
			'adjust value by audience reach level
			'for now: level 1 is 50% of the value we used before introduction
			'of the reach level
			'use audienceReachLevel=0 to skip modification
			if audienceReachLevel > 0
				value :* GetAudienceReachLevelPriceMod(audienceReachLevel)
			endif
			'print GetTitle() + "    value="+value+"   level="+audienceReachLevel + "  mod="+GetAudienceReachLevelPriceMod(audienceReachLevel)
		endif

		'=== BEAUTIFY ===
		'round to next "1000" block
		'value = Int(Floor(value / 1000) * 1000)
		value = TFunctions.RoundToBeautifulValue(value)


		Return value
	End Method


	'param needed as AI requests price using this method, and this also
	'for not-yet-owned licences
	Method GetPrice:Int(playerID:int) {_exposeToLua}
		if GetPlayerBase(playerID)
			Return GetPriceForPlayer(playerID, Max(1, GetPlayerBase(playerID).GetAudienceReachLevel()))
		else
			Return GetPriceForPlayer(playerID, -1)
		endif
	End Method


	'param needed as AI requests price using this method, and this also
	'for not-yet-owned licences
	Method GetSellPrice:Int(playerID:int) {_exposeToLua}
		if owner = playerID
			Return GetPriceForPlayer(owner, licencedAudienceReachLevel)
		elseif GetPlayerBase(playerID)
			Return GetPriceForPlayer(playerID, Max(1, GetPlayerBase(playerID).GetAudienceReachLevel()))
		else
			Return GetPriceForPlayer(playerID, -1)
		endif
	End Method



	Method GetPriceForPlayerOld:int(playerID:int)
		Local value:Float

		'single-licence
		if GetSubLicenceCount() = 0 and GetData()
			value = GetData().GetPriceOld(playerID)
		else
			'licence for a package or series
			For local licence:TProgrammeLicence = eachin subLicences
				value :+ licence.GetPriceForPlayerOld(playerID)
			Next
			value :* 0.90
		endif


		'=== INDIVIDUAL PRICE ===
		'individual licence price mod (eg. "special collection discount")
		value :* GetModifier(modKeyPriceLS)

		'=== AUCTION PRICE ===
		'if this licence was won in an auction, this price is modifying
		'the real one
		value :* GetModifier(modKeyAuctionPriceLS)

		'=== DIFFICULTY ===
		'eg. "auctions" set this flag
		if not HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY)
			value :* GetPlayerDifficulty(playerID).programmePriceMod
		endif

		'=== BEAUTIFY ===
		'round to next "1000" block
		'value = Int(Floor(value / 1000) * 1000)
		value = TFunctions.RoundToBeautifulValue(value)


		Return value
	End Method


	'param needed as AI requests price using this method, and this also
	'for not-yet-owned licences
	Method GetPriceOld:Int(playerID:int) {_exposeToLua}
		Return GetPriceForPlayerOld(playerID)
	End Method


	Method GetTimesBroadcasted:int(owner:int = -1) {_exposeToLua}
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


	'called as soon as the programme licence is broadcasted
	Method doBeginBroadcast(playerID:Int = -1, broadcastType:Int = 0) override
		'=== UPDATE BROADCAST RESTRICTIONS ===
		If broadcastType = TVTBroadcastMaterialType.PROGRAMME
			If HasBroadcastTimeSlot() and not HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.KEEP_BROADCAST_TIME_SLOT_ENABLED_ON_BROADCAST)
				broadcastTimeSlotStart = -1
				broadcastTimeSlotEnd = -1
			EndIf
		EndIf
	End Method
	

	Method ShowSheet:Int(x:Int,y:Int, align:Float=0.5, showMode:int=0, useOwner:int=-1, extraData:TData = null)
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


	Method ShowProgrammeSheet:Int(x:Int,y:Int, align:Float=0.5, useOwner:int=-1, extraData:TData = null)
		if useOwner = -1 then useOwner = owner

		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 330
		local sheetHeight:int = 0 'calculated later
		x = x - align*sheetWidth

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
		if not (isEpisode() or isCollectionElement())
			title = GetTitle()
		else
			title = GetParentLicence().GetTitle()
		endif

		local price:int
		if currentPlayerID = useOwner
			price = GetSellPrice(useOwner)
		else
			if useOwner <= 0 then useOwner = currentPlayerID
			price = GetPriceForPlayer(useOwner)
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
		elseif finance and finance.canAfford( price )
			canAfford = True
		endif

		Local showMsgPlannedWarning:Int = False
		Local showMsgEarnInfo:Int = False
		Local showMsgLiveInfo:Int = False
		Local showMsgBroadcastLimit:Int = False
		Local showMsgBroadcastTimeSlot:Int = False
		Local showMsgLiveProductionCost:Int = False
		Local showMsgInProduction:Int = False

		'only if planned and in archive
		'if useOwner > 0 and GetPlayer().figure.inRoom
		'	if self.IsPlanned() and GetPlayer().figure.inRoom.name = "archive"
		if useOwner > 0 and self.IsPlanned() then showMsgPlannedWarning = True
		'if licence is for a specific programme it might contain a flag...
		'TODO: do this for "all" via licence.HasFlag() doing recursive checks?
		If self.IsPaid() then showMsgEarnInfo = True

		'always show live info text - regardless of situation ?!
		local nextReleaseTime:Long
		If self.IsLive()
			nextReleaseTime = GetNextReleaseTime()
			if nextReleaseTime = -1 and data then nextReleaseTime = data.GetReleaseTime()

			'release time might be in the past if the live programme is airing
			'now (so it is "live" but start was in the past)
			if self.isAlwaysLive()
				showMsgLiveInfo = True
			else if nextReleaseTime < GetWorldTime().GetTimeGone()
				showMsgLiveInfo = False
			else
				showMsgLiveInfo = True
			endif
		Rem
		If self.IsLive() or self.IsLiveOnTape()
			local programmedDay:int = -1
			local programmedHour:int = -1
			if extraData
				programmedDay = extraData.GetInt("programmedDay", -1)
				programmedHour = extraData.GetInt("programmedHour", -1)
				'not programmed = freshly created or dragged, so it is
				'live, if the live-time is not passed yet
				if programmedDay = -1 or programmedHour = -1
					if GetWorldTime().GetTimeGone() < data.GetReleaseTime() + 5 * TWorldTime.MINUTELENGTH ' xx:05
						showMsgLiveInfo = true
					endif
				'if programmed, check if this the time of the live broadcast
				'if so - also display the "live"-information for something
				'which is only "live on tape" (was live at that time)
				else
					if GetWorldTime().GetDay(data.GetReleaseTime()) = programmedDay and GetWorldTime().GetDayHour(data.GetReleaseTime()) = programmedHour
						showMsgLiveInfo = true
					endif
				endif
			elseif IsLive()
				'it is only live until it happens
				if GetWorldTime().GetTimeGone() < data.releaseTime + 5 * TWorldTime.MINUTELENGTH ' xx:05
					showMsgLiveInfo = True
				endif
			endif

			if GetSubLicenceCount() > 0
				if IsLive()
					local nextT:Long = GetNextReleaseTime()
					local nowT:Long = GetWorldTime().GetTimeGone()
					if GetWorldTime().GetTimeGone() < GetNextReleaseTime() + 5 * TWorldTime.MINUTELENGTH
						showMsgLiveInfo = True
					endif
				endif
			endif
		EndRem
		endif
		If HasBroadcastLimit() then showMsgBroadcastLimit = True
		If HasBroadcastTimeSlot() then showMsgBroadcastTimeSlot = True
		If IsSeries() And IsUnfinishedCustomProduction()
			showMsgInProduction = True
			showMsgPlannedWarning = False
		EndIF

		'Ron: disabled for now - as too many messages do not fit into the
		'     datasheet. Also I am not sure if the information is to
		'     display at all
		'if GetData().productionID and IsLive() and not GameRules.payLiveProductionInAdvance and extraData Then showMsgLiveProductionCost = True


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, subtitleH:int = 16, genreH:int = 16, descriptionH:int = 70, castH:int=50
		local splitterHorizontalH:int = 6
		local boxH:int = 0, msgH:int = 0, barH:int = 0
		local msgAreaH:int = 0, boxAreaH:int = 0, barAreaH:int = 0
		local boxAreaPaddingY:int = 4, msgAreaPaddingY:int = 4, barAreaPaddingY:int = 4

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "money", "good", null, ALIGN_CENTER_CENTER).y
		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").y
		barH = skin.GetBarSize(100, -1).y
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).GetBoxHeight(title, contentW - 10, 100))
		'increase for multiline
'		if titleH > 18 then titleH :+ 3

		'message area
		If showMsgEarnInfo then msgAreaH :+ msgH
		If showMsgPlannedWarning then msgAreaH :+ msgH
		If showMsgLiveInfo then msgAreaH :+ msgH
		If showMsgBroadcastLimit then msgAreaH :+ msgH
		If showMsgBroadcastTimeSlot then msgAreaH :+ msgH
		If showMsgLiveProductionCost then msgAreaH :+ msgH
		IF showMsgInProduction then msgAreaH :+ msgH
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
		barAreaH = 2 * barAreaPaddingY + 4 * (barH + 1)

		'total height
		sheetHeight = titleH + genreH + descriptionH + castH + barAreaH + msgAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		if isSeries() or isCollection() or isEpisode() or isCollectionElement() then sheetHeight :+ subtitleH
		'there is a splitter between description and cast...
		sheetHeight :+ splitterHorizontalH


		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		if titleH <= 18
			GetBitmapFont("default", 13, BOLDFONT).DrawBox(title, contentX + 5, contentY +1, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		else
			GetBitmapFont("default", 13, BOLDFONT).DrawBox(title, contentX + 5, contentY   , contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		endif
		contentY :+ titleH


		'=== SUBTITLE AREA ===
		if isSeries()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			skin.fontNormal.DrawBox(GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetEpisodeCount()), contentX + 5, contentY-1, contentW - 10, genreH +1, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			contentY :+ subtitleH
		elseif isCollection()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			skin.fontNormal.DrawBox(GetLocale("COLLECTION_WITH_X_ELEMENTS").Replace("%X%", GetEpisodeCount()), contentX + 5, contentY-1, contentW - 10, genreH +1, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			contentY :+ subtitleH
		elseif isEpisode() or isCollectionElement()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			'episode num/max + episode title
			skin.fontNormal.DrawBox(GetEpisodeNumber() + "/" + GetParentLicence().GetEpisodeCount() + ": " + GetTitle(), contentX + 5, contentY-1, contentW - 10, genreH +1, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			contentY :+ subtitleH
		endif


		'=== COUNTRY / YEAR / GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		'splitter
		Local yearWidth:Int = 65
		'country [+year] + genre, year only for non-callin-shows
		Local countryYear:String = data.country + " " + data.GetYear()
		If data.HasFlag(TVTProgrammeDataFlag.PAID) Then countryYear = data.country
		If countryYear.length > 10 Then yearWidth = skin.fontNormal.GetWidth(countryYear) + 5
		GetSpriteFromRegistry("gfx_datasheet_content_splitterV").DrawArea(contentX + 5 + yearWidth, contentY, 2, 16)
		skin.fontNormal.DrawBox(countryYear, contentX + 5, contentY-1, yearWidth, genreH+2, sALIGN_LEFT_CENTER, skin.textColorNeutral)

		local genreLine:String = GetGenresLine()

		skin.fontNormal.DrawBox(genreLine, contentX + 5 + yearWidth + 2, contentY-1, contentW - 10 - yearWidth - 2, genreH+2, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		contentY :+ genreH


		'=== DESCRIPTION AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.DrawBox(GetDescription(), contentX + 5, contentY + 1, contentW - 10, descriptionH - 1, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
		contentY :+ descriptionH


		'splitter
		skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
		contentY :+ splitterHorizontalH


		'=== CAST AREA ===
		skin.RenderContent(contentX, contentY, contentW, castH, "2")
		'cast
		local cast:string = ""

		For local jobID:int = EachIn TVTPersonJob.GetCastJobs()
			local requiredPersons:int = data.GetCastGroup(jobID).length
			if requiredPersons <= 0 then continue

			if cast <> "" then cast :+ ", "

			if requiredPersons = 1
				cast :+ "|b|"+GetLocale("JOB_" + TVTPersonJob.GetAsString(jobID, True))+":|/b| "
			else
				cast :+ "|b|"+GetLocale("JOB_" + TVTPersonJob.GetAsString(jobID, False))+":|/b| "
			endif

			cast :+ data.GetCastGroupString(jobID)
		Next

		if cast <> ""
			'max width of cast word - to align their content properly
			skin.fontNormal.DrawBox(cast, contentX + 5, contentY, contentW  - 10, castH, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
		endif
		contentY:+ castH

		'=== BARS / MESSAGES / BOXES AREA ===
		'background for bars + messages + boxes
		skin.RenderContent(contentX, contentY, contentW, barAreaH + msgAreaH + boxAreaH, "1_bottom")


		'===== DRAW RATINGS / BARS =====

		'bars have a top-padding
		contentY :+ barAreaPaddingY
		'speed
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetSpeed())
		skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_SPEED"), contentX + 5 + 200 + 5, contentY - 2, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
		contentY :+ barH + 1
		'critic/review
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetReview())
		skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_CRITIC"), contentX + 5 + 200 + 5, contentY - 2, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
		contentY :+ barH + 1
		'boxoffice/outcome
		if data.IsTVDistribution()
			skin.RenderBar(contentX + 5, contentY, 200, 12, GetOutcomeTV())
			'use a different text color if tv-outcome is not calculated
			'yet
			if GetOutcomeTV() < 0
				skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_TVAUDIENCE"), contentX + 5 + 200 + 5, contentY - 2, new SColor8(180,50,50), EDrawTextEffect.Emboss, 0.3)
			else
				skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_TVAUDIENCE"), contentX + 5 + 200 + 5, contentY - 2, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
			endif
		else
			skin.RenderBar(contentX + 5, contentY, 200, 12, GetOutcome())
			skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_BOXOFFICE"), contentX + 5 + 200 + 5, contentY - 2, skin.textColorLabel,  EDrawTextEffect.Emboss, 0.3)
		endif
		contentY :+ barH + 1
		'topicality/maxtopicality
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetTopicality(), GetMaxTopicality())
		skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_TOPICALITY"), contentX + 5 + 200 + 5, contentY - 2, skin.textColorLabel,  EDrawTextEffect.Emboss, 0.3)
		contentY :+ barH + 1


		'=== MESSAGES ===
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY

		If showMsgLiveInfo
			local time:string = ""
			local days:int = GetWorldTime().GetDay( nextReleaseTime ) - GetWorldTime().GetDay()

			if days = 0
				time = GetLocale("TODAY")
			elseif days = 1
				time = GetLocale("TOMORROW")
			elseif days =-1
				time = GetLocale("YESTERDAY")
			elseif days > 0
				time = GetLocale("IN_X_DAYS").Replace("%DAYS%", GetWorldTime().GetDaysRun( nextReleaseTime ) - GetWorldTime().GetDaysRun())
			else
				time = GetLocale("X_DAYS_AGO").Replace("%DAYS%", Abs(GetWorldTime().GetDaysRun( nextReleaseTime ) - GetWorldTime().GetDaysRun()))
			endif
			'programme start time
			time :+ ", "+ GetWorldTime().GetDayHour( nextReleaseTime )+":00"
			if self.isAlwaysLive()
				time=""
			else
				time = ": "+time
			endif

			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("MOVIE_LIVESHOW") + time, "runningTime", "bad", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		if showMsgBroadcastLimit
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getBroadCastLimitDatasheetText(self), "spotsPlanned", "bad", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif

		if showMsgBroadcastTimeSlot
			If GetSublicenceCountTotal() > 0
				 skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("BROADCAST_TIME_RESTRICTED") , "spotsPlanned", "bad", skin.fontNormal, ALIGN_CENTER_CENTER)
			Else If HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.KEEP_BROADCAST_TIME_SLOT_ENABLED_ON_BROADCAST)
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("BROADCAST_ONLY_ALLOWED_FROM_X_TO_Y").Replace("%X%", GetBroadcastTimeSlotStart()).Replace("%Y%", GetBroadcastTimeSlotEnd()) , "spotsPlanned", "bad", skin.fontNormal, ALIGN_CENTER_CENTER)
			Else
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("FIRST_BROADCAST_ONLY_ALLOWED_FROM_X_TO_Y").Replace("%X%", GetBroadcastTimeSlotStart()).Replace("%Y%", GetBroadcastTimeSlotEnd()) , "spotsPlanned", "bad", skin.fontNormal, ALIGN_CENTER_CENTER)
			EndIf
			contentY :+ msgH
		endif

		If showMsgEarnInfo
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			local revenue:string = GetFormattedCurrency(int(1000 * data.GetPerViewerRevenue(useOwner)))

			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), "money", "good", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		if showMsgLiveProductionCost
			Local productionCostsLeftValue:int
			if extraData then productionCostsLeftValue = extraData.GetInt("productionCostsLeft")
			local productionCostsLeft:string = GetFormattedCurrency(productionCostsLeftValue)
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("LIVE_PRODUCTION_FINISH_WILL_COST_X").Replace("%X%", productionCostsLeft) , "money", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif

		if showMsgPlannedWarning
			if not isProgrammePlanned()
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("TRAILER_IN_PROGRAMME_PLAN"), "spotsPlanned", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
			elseif not isTrailerPlanned()
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PROGRAMME_IN_PROGRAMME_PLAN"), "spotsPlanned", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
			else
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PROGRAMME_AND_TRAILER_IN_PROGRAMME_PLAN"), "spotsPlanned", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
			endif
			contentY :+ msgH
		endif
		
		if showMsgInProduction
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("IN_PRODUCTION"), "warning", "neutral", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif


		'if there is a message then add padding to the bottom
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		'=== BOXES ===
		'boxes have a top-padding (except with messages)
		if msgAreaH = 0 then contentY :+ boxAreaPaddingY

		Local shiftDown:Int = KeyManager.IsDown(KEY_LSHIFT) Or KeyManager.IsDown(KEY_RSHIFT)

		'=== BOX LINE 1 ===
		'blocks
		skin.RenderBox(contentX + 5, contentY, 47, -1, GetBlocks(), "duration", "neutral", skin.fontBold)
		'repetitions
		'TODO total number of broadcasts only when not owned?
		if useOwner <= 0 Or shiftDown
			skin.RenderBox(contentX + 5 + 51, contentY, 52, -1, GetTimesBroadcasted(-1), "repetitions", "neutral", skin.fontBold)
		else
			skin.RenderBox(contentX + 5 + 51, contentY, 52, -1, GetTimesBroadcasted(useOwner), "repetitions", "neutral", skin.fontBold)
		endif
		'record
		If shiftDown
			Local show:String = "-"
			If useOwner
				Local perc:Float = GetBroadcastStatistic(useOwner).bestAudiencePercantage[useOwner-1]
				If perc > 0 then show = MathHelper.NumberToString(perc*100.0)+"%"
			EndIf
			skin.RenderBox(contentX + 5 + 107, contentY, 88, -1, show, "maxAudience", "neutral", skin.fontBold)
		Else
			skin.RenderBox(contentX + 5 + 107, contentY, 88, -1, TFunctions.convertValue(GetBroadcastStatistic(useOwner).GetBestAudienceResult(useOwner, -1).audience.GetTotalSum(),2), "maxAudience", "neutral", skin.fontBold)
		EndIf

		'price
		local showPrice:int = not data.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.HIDE_PRICE)
		'- hide for custom productions until aired (series: if all episoded aired)
		if showPrice and owner > 0 and ContainsUnknownPrice() then showPrice = False
		'if showPrice and IsTVDistribution() and ContainsUnknownTVOutcome() and IsAPlayersCustomProduction() then showPrice = False
	
		'- hide unowned and not tradeable ones
		'-> disabled because of "Opener show"
		'if showPrice not IsOwned() and not IsTradeable() then showPrice = False

		'show price if forced to. ATTENTION: licence flag, not data/broadcast flag!
		'showPrice = showPrice or hasLicenceFlag(TVTProgrammeLicenceFlag.SHOW_PRICE)


		if showPrice
			if canAfford
				skin.RenderBox(contentX + 5 + 199, contentY, contentW - 10 - 199 +1, -1, MathHelper.DottedValue( price ), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + 199, contentY, contentW - 10 - 199 +1, -1, MathHelper.DottedValue( price ), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER, "bad")
			endif
		else
			skin.RenderBox(contentX + 5 + 199, contentY, contentW - 10 - 199 +1, -1, "- ?? -", "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		endif
		'=== BOX LINE 2 ===
		contentY :+ boxH



		'=== DEBUG ===
		If TVTDebugInfo
			'begin at the top ...again
			contentY = y + skin.GetContentY()
			local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.DrawBox("Programm: "+GetTitle(), contentX + 5, contentY, contentW - 10, 28, sALIGN_LEFT_TOP, SColor8.White)
			contentY :+ 28
			skin.fontNormal.DrawSimple("GUID: "+GetGUID(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Letzte Stunde im Plan: "+latestPlannedEndHour, contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Letzte Trailerstunde im Plan: "+latestPlannedTrailerHour, contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Tempo: "+MathHelper.NumberToString(data.GetSpeed(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Kritik: "+MathHelper.NumberToString(data.GetReview(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Kinokasse: "+MathHelper.NumberToString(data.GetOutcome(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("TV-Kasse: "+MathHelper.NumberToString(data.GetOutcomeTV(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Preismodifikator:  Lizenz="+MathHelper.NumberToString(GetModifier(modKeyPriceLS), 4)+"  Data="+MathHelper.NumberToString(data.GetModifier(modKeyPriceLS), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Qualitaet roh: "+MathHelper.NumberToString(GetQualityRaw(), 4)+"  (ohne Alter, Wdh.)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Qualitaet: "+MathHelper.NumberToString(GetQuality(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Aktualitaet: "+MathHelper.NumberToString(GetTopicality(), 4)+" von " + MathHelper.NumberToString(data.GetMaxTopicality(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Bloecke: "+GetBlocks(), contentX + 5, contentY)
			contentY :+ 12
			if useOwner <= 0
				skin.fontNormal.DrawSimple("Ausgestrahlt: "+GetTimesBroadcasted(0)+"x unbekannt, "+GetTimesBroadcasted()+"x alle  Limit:"+broadcastLimit, contentX + 5, contentY)
			else
				skin.fontNormal.DrawSimple("Ausgestrahlt: "+GetTimesBroadcasted(useOwner)+"x Spieler, "+GetTimesBroadcasted()+"x alle  Limit:"+broadcastLimit, contentX + 5, contentY)
			endif
			contentY :+ 12
			skin.fontNormal.DrawSimple("Quotenrekord: "+Long(GetBroadcastStatistic().GetBestAudienceResult(useOwner, -1).audience.GetTotalSum())+" (Spieler), "+Long(GetBroadcastStatistic().GetBestAudienceResult(-1, -1).audience.GetTotalSum())+" (alle)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Kaufpreis: "+MathHelper.DottedValue(GetPriceForPlayer(useOwner))+" (licLvl: " + licencedAudienceReachLevel+")  Verkauf: " + MathHelper.DottedValue(GetSellPrice(useOwner)), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Trailer: " + data.GetTimesTrailerAiredSinceLastBroadcast(useOwner) +" (total: "+ data.GetTimesTrailerAired()+")", contentX + 5, contentY)
			if data.GetTrailerMod(useOwner, False)
				contentY :+ 12
				local titleDim:SVec2I
				titleDim = skin.fontNormal.DrawSimple("TrailerMod:", contentX + 5, contentY)
				skin.fontNormal.DrawBox(data.GetTrailerMod(useOwner).ToStringPercentage(2), contentX + 5 + titleDim.x + 5, contentY, contentW - titleDim.x - 5 - 5, 60, sALIGN_LEFT_TOP, SColor8.White)
				'2 lines of output...
				contentY :+ 12 + 4
			endif
			
			if TSportsProgrammeData(data)
				local sportsData:TSportsProgrammeData = TSportsProgrammeData(data)
				contentY :+ 12
				skin.fontNormal.DrawSimple("IsMatchFinished: " + sportsData.IsMatchFinished() + "   Matchtime: " + GetWorldTime().GetFormattedGameDate(sportsData.GetMatchEndTime()), contentX + 5, contentY)
			endif
			contentY :+ 12
			skin.fontNormal.DrawSimple("IsCustomProduction: " + IsCustomProduction() + "  IsAPlayersCustomProduction: " + IsAPlayersCustomProduction(), contentX + 5, contentY)
			
		endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)

		'=== X-Rated Overlay ===
		If IsXRated()
			GetSpriteFromRegistry("gfx_datasheet_overlay_xrated").Draw(contentX + sheetWidth, y, -1, ALIGN_RIGHT_TOP)
		Endif

		Function getBroadCastLimitDatasheetText:String(l:TProgrammeLicence)
			local limitMin:int = 1000
			local limitMax:int = -1
			local suffix:String = ""
			local childCount:int = l.getSubLicenceCount()
			if childCount > 0
				local limitCount:int = 0
				For local c:TProgrammeLicence = eachin l.subLicences
					local childLimit:int=c.GetBroadCastLimit()
					if childLimit >= 0
						limitMin = min(limitMin, childLimit)
						limitMax = max(limitMax, childLimit)
						limitCount :+ 1
					endif
				Next
				if limitCount < childCount then suffix = " ("+limitCount+"/"+childCount+")"
			else
				limitMin = l.GetBroadCastLimit()
				limitMax = limitMin
			endif

			if limitMax <= 0
				return getLocale("NO_MORE_BROADCASTS_ALLOWED") + suffix
			elseif limitMin = 1 and limitMax = 1
				return getLocale("ONLY_1_BROADCAST_POSSIBLE") + suffix
			elseif limitMin <> limitMax
				return getLocale("ONLY_X_BROADCASTS_POSSIBLE").replace("%X%", limitMin+"-"+limitMax) + suffix
			else
				return getLocale("ONLY_X_BROADCASTS_POSSIBLE").replace("%X%", limitMin) + suffix
			endif
		End Function
	End Method


	Method ShowTrailerSheet:Int(x:Int,y:Int, align:Float=0.5, useOwner:int = -1, extraData:TData = null)
		if useOwner = -1 then useOwner = owner

		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 330
		local sheetHeight:int = 0 'calculated later
		x = x - align*sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("trailer")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, genreH:int = 16, descriptionH:int = 70
		local barH:int = 0, msgH:int = 0
		local msgAreaH:int = 0, barAreaH:int = 0
		local barAreaPaddingY:int = 4, msgAreaPaddingY:int = 4

		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).GetBoxHeight(GetTitle(), contentW - 10, 100))

		'reactivate when adding messages
		'msgH = skin.GetMessageSize(contentW - 10, -1, "", "targetGroupLimited", "warning", null, ALIGN_CENTER_CENTER).GetY()
		barH = skin.GetBarSize(100, -1).y

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
		if titleH <= 18
			GetBitmapFont("default", 13, BOLDFONT).DrawBox(GetTitle(), contentX + 5, contentY +1, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		else
			GetBitmapFont("default", 13, BOLDFONT).DrawBox(GetTitle(), contentX + 5, contentY   , contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		endif
		contentY :+ titleH


		'=== GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		skin.fontNormal.DrawBox(GetLocale("TRAILER"), contentX + 5, contentY - 1, contentW - 10, genreH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		contentY :+ genreH


		'=== CONTENT AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.DrawBox(GetLocale("MOVIE_TRAILER"), contentX + 5, contentY + 1, contentW - 10, descriptionH, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
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
		skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_TOPICALITY"), contentX + 5 + 200 + 5, contentY - 2, skin.textColorLabel,  EDrawTextEffect.Emboss, 0.3)


		If TVTDebugInfo
			'begin at the top ...again
			contentY = y + skin.GetContentY()

			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.DrawSimple("Trailer: "+GetTitle(), contentX + 5, contentY)
			contentY :+ 14
			skin.fontNormal.DrawSimple("Traileraktualitaet: "+MathHelper.NumberToString(data.GetTrailerTopicality(), 4)+" von " + MathHelper.NumberToString(data.GetMaxTrailerTopicality(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Ausstrahlungen: "+data.trailerAired, contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Ausstrahlungen seit letzter Sendung: "+data.GetTimesTrailerAiredSinceLastBroadcast(useOwner), contentX + 5, contentY)
		Endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Method


	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method

	'required until brl.reflection correctly handles "float parameters" 
	'in debug builds (same as "doubles" for 32 bit builds)
	'GREP-key: "brlreflectionbug"
	Method SetAttractivenessString(value:String) {_exposeToLua}
		SetAttractiveness(Float(value))
	End Method

	'expose commented out because of above mentioned brl.reflection bug
	'Wird bisher nur in der LUA-KI verwendet
	Method SetAttractiveness(value:Float) '{_exposeToLua}
		Self.attractiveness = value
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method GetPricePerBlock:Int(playerID:int, broadcastType:int) {_exposeToLua}
		if broadcastType = 0 then broadcastType = TVTBroadcastMaterialType.PROGRAMME
		return GetPriceForPlayer(playerID) / GetBlocksTotal(broadcastType)
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
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([6, 300]).SetCaption("PROGRAMME_GENRE_DOCUMENTARIES_AND_FEATURES")
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
		CreateVisible().SetNotDataFlag(categoryFlags).AddGenres([100, 101, 102, 103, 104, 200, 201, 202, 203, 204]).SetCaption("PROGRAMME_GENRE_SHOW_AND_EVENTS")
		CreateVisible().SetNotDataFlag(TVTProgrammeDataFlag.PAID).SetDataFlag(TVTProgrammeDataFlag.LIVE)						'live
'		CreateVisible().SetDataFlag(TVTProgrammeDataFlag.TRASH).AddGenres([301])	'Trash + Yellow Press

		'either trash - or genre 301 (yellow press)
		local trash:TProgrammeLicenceFilterGroup = TProgrammeLicenceFilterGroup.CreateVisible()
		trash.SetConnectionType(TProgrammeLicenceFilterGroup.CONNECTION_TYPE_OR)
		'store config in group for proper caption
		trash.SetDataFlag(TVTProgrammeDataFlag.TRASH).AddGenres([301])
		'disallow paid
		trash.SetNotDataFlag(TVTProgrammeDataFlag.PAID)
		trash.AddFilter( new TProgrammeLicenceFilter.SetNotDataFlag(TVTProgrammeDataFlag.PAID).SetDataFlag(TVTProgrammeDataFlag.TRASH).ForbidChildren())
		trash.AddFilter( new TProgrammeLicenceFilter.SetNotDataFlag(TVTProgrammeDataFlag.PAID).AddGenres([301]).ForbidChildren() )

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
		local flag:int = 0
		For local flagNumber:int = 0 to 7 'manual limitation to "7" to exclude series/paid?
			flag = 1 shl flagNumber ' = 2^flagNumber
			'contains that flag?
			if dataFlags & flag > 0
				if result <> "" then result :+ " & "
				result :+ GetLocale("PROGRAMME_FLAG_" + TVTProgrammeDataFlag.GetAsString(flag))
			endif
		Next

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


	Method CheckRange:int(minV:Double, maxV:Double, value:Double)
		if minV >= 0 and value < minV then return False
		if maxV >= 0 and value > maxV then return False
		return True
	End Method


	'checks if the given programmelicence contains at least ONE of the given
	'filter criterias ("OR"-chain of criterias)
	'Ex.: filter cares for genres 1,2 and flags "trash" and "bmovie"
	'     True is returned genre 1 or 2 or flag "trash" or flag "bmovie"
	Method DoesFilter:Int(licence:TProgrammeLicence, skipOwnerChecks:int = False)
		if not licence then return False

		'if a licence is exceeding the broadcast limit it is not available
		'in the movie agency it will have lost tradeability, 
		'if owned by a player it should be visible in the archive for potential selling
		if not licence.isExceedingBroadCastLimit()
			if checkAvailability and not licence.isAvailable() then return False
		endif
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
		local quality:Float = licence.GetQuality()
		if qualityMin >= 0 and quality < qualityMin then return False
		if qualityMax >= 0 and quality > qualityMax then return False

		'check relative topicality (topicality/maxTopicality)
		local relativeTopicality:Float = licence.GetRelativeTopicality()
		if relativeTopicalityMin >= 0 and relativeTopicality < relativeTopicalityMin then return False
		if relativeTopicalityMax >= 0 and relativeTopicality > relativeTopicalityMax then return False

		'check absolute topicality (maxTopicality)
		'this is done to avoid selling "no longer useable entries"
		local maxTopicality:Float = licence.GetMaxTopicality()
		if maxTopicalityMin >= 0 and maxTopicality < maxTopicalityMin then return False
		if maxTopicalityMax >= 0 and maxTopicality > maxTopicalityMax then return False

		'check price
		local priceForPlayer:int = licence.GetPriceForPlayer(playerID)
		if priceMin >= 0 and priceForPlayer < priceMin then return False
		if priceMax >= 0 and priceForPlayer > priceMax then return False

		'check release time (absolute value)
		local releaseTime:Long = licence.data.GetReleaseTime()
		if releaseTimeMin >= 0 and releaseTime < releaseTimeMin then return False
		if releaseTimeMax >= 0 and releaseTime > releaseTimeMax then return False

		'check age (relative value)
		local age:long = GetWorldTime().GetTimeGone() - releaseTime
		if checkAgeMin and age < ageMin then return False
		if checkAgeMax and age - releaseTime > ageMax then return False

		'check time to relase (aka "negative age")
		local negativeAge:long = releaseTime - GetWorldTime().GetTimeGone()
		if checkTimeToReleaseMin and negativeAge < timeToReleaseMin then return False
		if checkTimeToReleaseMax and negativeAge > timeToReleaseMax then return False


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

		If Not skipOwnerChecks
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
		EndIf

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


	Method DoesFilter:Int(licence:TProgrammeLicence, skipOwnerChecks:Int = False) override
		if filters.length = 0 then return Super.DoesFilter(licence, skipOwnerChecks)

		if connectionType = CONNECTION_TYPE_OR
			For local filter:TProgrammeLicenceFilter = Eachin filters
				if filter.DoesFilter(licence, skipOwnerChecks) then return True
			Next
			return False
		else
			For local filter:TProgrammeLicenceFilter = Eachin filters
				if filter <> filters[filters.length - 1]
					if not filter.DoesFilter(licence, skipOwnerChecks) then return False
				else
					'last filter - if this is reached, all others filtered
					'ok and this one might return desired result
					if filter.DoesFilter(licence, skipOwnerChecks) then return True
				endif
			Next
			return False
		endif
	End Method
End Type