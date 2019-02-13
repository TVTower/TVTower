Rem
	===========================================================
	code for PlayerProgrammePlan
	===========================================================
ENDREM
SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.programme.adcontract.bmx"
Import "game.programme.newsevent.bmx"
Import "game.broadcastmaterial.programme.bmx"
Import "game.broadcastmaterial.advertisement.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.broadcast.dailybroadcaststatistic.bmx"
Import "game.player.programmecollection.bmx"



Type TPlayerProgrammePlanCollection
	Field plans:TPlayerProgrammePlan[]
	Global _instance:TPlayerProgrammePlanCollection
	Global _eventsRegistered:Int= False


	Method New()
		If Not _eventsRegistered
			EventManager.registerListenerFunction("Game.OnDay", onGameDay)
			_eventsRegistered = True
		EndIf
	End Method


	Function GetInstance:TPlayerProgrammePlanCollection()
		If Not _instance Then _instance = New TPlayerProgrammePlanCollection
		Return _instance
	End Function


	'on each new game day, old slot locks of the plans should get removed
	'to keep the map small (less memory, less cpu hunger when processed)
	Function onGameDay:int(triggerEvent:TEventBase)
		For local p:TPlayerProgrammePlan = EachIn GetInstance().plans
			p.RemoveObsoleteSlotLocks()
		Next
	End Function


	Method Set:Int(playerID:Int, plan:TPlayerProgrammePlan)
		If playerID <= 0 Then Return False
		If playerID > plans.length Then plans = plans[.. playerID]
		plans[playerID-1] = plan
	End Method


	Method Get:TPlayerProgrammePlan(playerID:Int)
		If playerID <= 0 Or playerID > plans.length Then Return Null
		Return plans[playerID-1]
	End Method


	Method InitializeAll:int()
		For local obj:TPlayerProgrammePlan = eachin plans
			obj.Initialize()
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPlayerProgrammePlanCollection:TPlayerProgrammePlanCollection()
	Return TPlayerProgrammePlanCollection.GetInstance()
End Function
'return specific plan
Function GetPlayerProgrammePlan:TPlayerProgrammePlan(playerID:Int)
	Return TPlayerProgrammePlanCollection.GetInstance().Get(playerID)
End Function




Type TPlayerProgrammePlan {_exposeToLua="selected"}
	Field programmes:TBroadcastMaterial[] = New TBroadcastMaterial[0]
	'single news -> eg for specials
	Field news:TBroadcastMaterial[]	= New TBroadcastMaterial[3]
	'news show
	Field newsShow:TBroadcastMaterial[]	= New TBroadcastMaterial[0]
	Field advertisements:TBroadcastMaterial[] = New TBroadcastMaterial[0]
	'as it is less common to lock slots we could use a TMap
	'instead of an array with "holes"
	Field lockedSlots:TMap = CreateMap()
	Field owner:Int

	Field _daysPlanned:int = -1 {nosave}

	'FALSE to avoid recursive handling (network)
	Global fireEvents:Int = True

	Const LOCK_TYPE_COUNT:int = 5

	Const LOCK_TYPE_COMMON:int = 0
	Const LOCK_TYPE_TEMPORARY:int = 1
	Const LOCK_TYPE_THIRDPARTY:int = 2
	Const LOCK_TYPE_BOSS:int = 4
	Const LOCK_TYPE_GOVERNMENT:int = 8

	'===== COMMON FUNCTIONS =====


	Method Create:TPlayerProgrammePlan(playerID:Int)
		Self.owner = playerID
		GetPlayerProgrammePlanCollection().Set(playerID, Self)
		Return Self
	End Method


	Method Initialize:Int()
		programmes = programmes[..0]
		news = New TBroadcastMaterial[3]
		newsShow = newsShow[..0]
		advertisements = advertisements[..0]
	End Method


	Method getSkipHoursFromIndex:Int()
		Return (GetWorldTime().GetStartDay()-1)*24
	End Method


	'returns the index of an array to use for a given hour
	Method GetArrayIndex:Int(hour:Int)
		Return Max(0, hour - getSkipHoursFromIndex())
	End Method


	'returns the Game-hour for a given array Index
	Method GetHourFromArrayIndex:Int(arrayIndex:Int)
		Return arrayIndex + getSkipHoursFromIndex()
	End Method


	'eg. for debugging
	Method printOverview()
		Rem
		print "=== AD/PROGRAMME COLLECTION PLAYER "+parent.playerID+" ==="
		print "Programme allg.:"
		For local licence:TProgrammeLicence = eachin parent.ProgrammeCollection.programmeLicences
			if licence.isSeries()
				print "  Serie: "+licence.GetTitle()+" | Episoden: "+licence.GetSubLicenceCount()
			elseif licence.isEpisode()
				print "  Einzelepisode: "+licence.GetTitle()
			elseif licence.isMovie()
				print "  Film: "+licence.GetTitle()
			endif
		Next
		print "Serien:"
		For local licence:TProgrammeLicence = eachin parent.ProgrammeCollection.seriesLicences
			print "  "+licence.GetTitle()+" | Episoden: "+licence.GetSubLicenceCount()
		Next
		print "Filme:"
		For local licence:TProgrammeLicence = eachin parent.ProgrammeCollection.movieLicences
			print "  "+licence.GetTitle()
		Next
		endrem


		Print "=== AD/PROGRAMME PLAN PLAYER " + owner + " ==="
		For Local i:Int = 0 To Max(programmes.length - 1, advertisements.length - 1)
			Local currentHour:Int = GetHourFromArrayIndex(i) 'hours since start
			Local time:Double = GetWorldTime().MakeTime(0, 0, currentHour, 0)
			Local adString:String = ""
			Local progString:String = ""

			'use "0" as day param because currentHour includes days already
			Local advertisement:TBroadcastMaterial = GetAdvertisement(0, currentHour)
			If advertisement
				Local startHour:Int = advertisement.programmedDay*24 + advertisement.programmedHour
				adString = " -> " + advertisement.GetTitle() + " [" + (currentHour - startHour + 1) + "/" + advertisement.GetBlocks(TVTBroadcastMaterialType.ADVERTISEMENT) + "]"
			EndIf


			Local programme:TBroadcastMaterial = GetProgramme(0, currentHour)
			If programme
				Local startHour:Int = programme.programmedDay*24 + programme.programmedHour
				progString = programme.GetTitle() + " ["+ (currentHour - startHour + 1) + "/" + programme.GetBlocks(TVTBroadcastMaterialType.PROGRAMME) +"]"
			EndIf

			'only show if ONE is set
			If adString <> "" Or progString <> ""
				If progString = "" Then progString = "SENDEAUSFALL"
				If adString = "" Then adString = " -> WERBEAUSFALL"
				Print "[" + GetArrayIndex(int(time / 3600)) + "] " + GetWorldTime().GetYear(time) + " " + GetWorldTime().GetDayOfYear(time) + ".Tag " + GetWorldTime().GetDayHour(time) + ":00 : " + progString + adString
			EndIf
		Next
		Print "=== ----------------------- ==="
	End Method


	Function FixDayHour(day:int var, hour:int var)
		If day < 0 Then day = GetWorldTime().GetDay()
		If hour = -1
			hour = GetWorldTime().getDayHour()
		Else
			day :+ int(hour / 24)
			hour = hour mod 24
		EndIf
	End Function

	'===== common function for managed objects =====


	'sets the given array to the one requested through slotType
	Method GetObjectArray:TBroadcastMaterial[](slotType:Int=0)
		If slotType = TVTBroadcastMaterialType.PROGRAMME Then Return programmes
		If slotType = TVTBroadcastMaterialType.ADVERTISEMENT Then Return advertisements
		If slotType = TVTBroadcastMaterialType.NEWSSHOW Then Return newsShow

		Return New TBroadcastMaterial[0]
	End Method


	'sets the given array to the one requested through objectType
	'this is needed as assigning to "getObjectArray"-arrays is not possible for now
	Method SetObjectArrayEntry:Int(obj:TBroadcastMaterial, slotType:Int=0, arrayIndex:Int)
		'resize array if needed
		If arrayIndex >= GetObjectArray(slotType).length
			If obj
				ResizeObjectArray(slotType, arrayIndex + 1 + obj.GetBlocks() - 1)
			'null is used to unset an objectarray
			Else
				ResizeObjectArray(slotType, arrayIndex + 1)
			EndIf
		EndIf
		If arrayIndex < 0 Then Throw "[ERROR] SetObjectArrayEntry: arrayIndex is negative"

		If slotType = TVTBroadcastMaterialType.PROGRAMME Then programmes[arrayIndex] = obj
		If slotType = TVTBroadcastMaterialType.ADVERTISEMENT Then advertisements[arrayIndex] = obj
		If slotType = TVTBroadcastMaterialType.NEWSSHOW Then newsShow[arrayIndex] = obj

		Return True
	End Method


	'make the resizing more generic so the functions do not have to know the
	'underlying array
	Method ResizeObjectArray:Int(objectType:Int=0, newSize:Int=0)
		Select objectType
			Case TVTBroadcastMaterialType.PROGRAMME
					programmes = programmes[..newSize]
					Return True
			Case TVTBroadcastMaterialType.ADVERTISEMENT
					advertisements = advertisements[..newSize]
					Return True
			Case TVTBroadcastMaterialType.NEWSSHOW
					newsShow = newsShow[..newSize]
					Return True
		End Select

		Return False
	End Method


	'Set a time slot locked
	'each lock is identifyable by "typeID_timeHours"
	Method LockSlot:int(slotType:int=0, day:int=-1, hour:int=-1, lockTypeFlags:int=0)
		FixDayHour(day, hour)

		'remove lock flags contained in flag already
		local flag:int = 0
		'flag=0 not contained in loop
		lockedSlots.Remove((day*24 + hour) + "_" +slotType + "_" + flag)
		For local i:int = 0 to LOCK_TYPE_COUNT
			flag = 2^i
			if flag & lockTypeFlags and flag <> lockTypeFlags
				lockedSlots.Remove((day*24 + hour) + "_" +slotType + "_" + flag)
			endif
		Next
		lockedSlots.Insert((day*24 + hour) + "_" +slotType+"_"+lockTypeFlags, null)
	End Method


	Method UnlockSlot:int(slotType:int=0, day:int=-1, hour:int=-1, lockTypeFlags:int=0)
		FixDayHour(day, hour)

		local flag:int = 0
		For local i:int = 0 to LOCK_TYPE_COUNT
			flag = 2^i
			if flag & lockTypeFlags and flag <> lockTypeFlags
				lockedSlots.Remove((day*24 + hour) + "_" +slotType + "_" + flag)
			endif
		Next
	End Method


	'returns whether a slot is locked, or belongs to an object which
	'occupies at least 1 locked slot
	Method BelongsToLockedSlot:int(slotType:int=0, day:int=-1, hour:int=-1, lockTypeFlags:int=0)
		local obj:TBroadcastMaterial = GetObject(slotType, day, hour)
		local hours:int = day*24 + hour
		if obj
			hours = obj.programmedDay*24 + obj.programmedHour
			For local blockHour:int = hours until hours + obj.GetBlocks()
				if IsLockedSlot(slotType, 0, blockHour, lockTypeFlags)
					return True
				endif
			Next
			return False
		else
			return IsLockedSlot(slotType, day, hour, lockTypeflags)
		endif
	End Method


	'returns whether a slot is locked, or belongs to an object which
	'occupies at least 1 locked slot
	Method BelongsToModifiyableSlot:int(slotType:int=0, day:int=-1, hour:int=-1, lockTypeFlags:int=0)
		local obj:TBroadcastMaterial = GetObject(slotType, day, hour)
		local hours:int = day*24 + hour
		if obj
			hours = obj.programmedDay*24 + obj.programmedHour
			For local blockHour:int = hours until hours + obj.GetBlocks()
				if not IsModifyableSlot(slotType, 0, blockHour, lockTypeFlags)
					return False
				endif
			Next
			return True
		else
			return IsModifyableSlot(slotType, day, hour, lockTypeflags)
		endif
	End Method


	'returns whether this slot is locked, ignores locks of other slots
	'occupied by the same broadcastmaterial filling this slot
	Method IsLockedSlot:int(slotType:int=0, day:int=-1, hour:int=-1, lockTypeFlags:int=0)
		FixDayHour(day, hour)

		local flag:int = 0
		'flag 0 is not contained in loop, do it extra
		if lockedSlots.Contains((day*24 + hour) + "_" + slotType + "_" + flag) then return True
		For local i:int = 0 to LOCK_TYPE_COUNT
			flag = 2^i
			if flag & lockTypeFlags and flag <> lockTypeFlags
				if lockedSlots.Contains((day*24 + hour) + "_" + slotType + "_" + flag)
					return True
				endif
			endif
		Next
		return False
	End Method


	'helper function
	'returns whether the given material occupies a locked slot
	Method IsLockedBroadcastMaterial:int(broadcastMaterial:TBroadcastMaterial, lockTypeFlags:int=0)
		if not broadcastMaterial then return False

		'for now we ignore owner checks - so every broadcastmaterial is just
		'checked if it occupies a locked slot

		'skip material not programmed yet
		if broadcastMaterial.programmedDay = -1 then return False

		for local block:int = 0 until broadcastMaterial.GetBlocks()
			if IsLockedSlot(broadcastMaterial.usedAsType, broadcastMaterial.programmedDay, broadcastMaterial.programmedHour, lockTypeFlags)
				return True
			endif
		Next
		return False
	End Method


	'removes slot lock info from past days (to keep things small sized)
	Method RemoveObsoleteSlotLocks:int()
		local time:Double = GetWorldTime().GetDay()*24 ' + 0 hours, start at midnight)

		For local k:string = EachIn lockedSlots.Keys()
			local parts:string[] = k.split("_")
			if parts.length < 2
				lockedSlots.Remove(k)
				continue
			endif

			if int(parts[0] < time)
				lockedSlots.Remove(k)
			else
				'as the keys are sorted by time (and then by type) we could
				'skip all others once we reached a lock of the present/future
				return False
			endif
		Next
		return True
	End Method


	'returns whether a slot is locked, or belongs to an object which
	'occupies at least 1 locked slot
	Method BelongsToOccupiedSlotWithSourceBroadcastFlags:int(slotType:int=0, day:int=-1, hour:int=-1, broadcastMaterialFlags:int=0)
		local obj:TBroadcastMaterial = GetObject(slotType, day, hour)
		if not obj then return False
		return obj.SourceHasBroadcastFlag(broadcastMaterialFlags)
	End Method


	'returns whether a slot is locked, or belongs to an object which
	'occupies at least 1 locked slot
	Method BelongsToOccupiedSlotWithUncontrollableBroadcast:int(slotType:int=0, day:int=-1, hour:int=-1)
		local obj:TBroadcastMaterial = GetObject(slotType, day, hour)
		if not obj then return False
		return not obj.IsControllable()
	End Method


	'returns whether a slot does not belong to a locked programme,
	'is not in the past and is not belonging to a non-controllable element
	Method IsModifyableSlot:int(slotType:int=0, day:int=-1, hour:int=-1, lockTypeFlags:int=0, currentDay:Int=-1, currentHour:Int=-1, currentMinute:Int=-1)
		if not IsUseableTimeSlot(slotType, day, hour, currentDay, currentHour, currentMinute) then return False
		if BelongsToLockedSlot(slotType, day, hour, lockTypeFlags) then return False
		if BelongsToOccupiedSlotWithUncontrollableBroadcast(slotType, day, hour) then return False

		return True
	End Method


	'returns whether the slot can be used or is already in the past...
	Function IsUseableTimeSlot:Int(slotType:Int=0, day:Int=-1, hour:Int=-1, currentDay:Int=-1, currentHour:Int=-1, currentMinute:Int=-1)
		FixDayHour(day, hour)
		FixDayHour(currentDay, currentHour)
		If currentMinute = -1 Then currentMinute = GetWorldTime().getDayMinute()

		'convert to total hour
		currentHour = currentDay*24 + currentHour
		'do not allow adding in the past
		Local slotHour:Int = day * 24 + hour

		'if the hour is in the future, the slot MUST be useable
		If slotHour > currentHour Then Return True
		'if the hour is in the past, the slot MUST be useable
		If slotHour < currentHour Then Return False

		Select slotType
			'check newsShow
			Case TVTBroadcastMaterialType.NEWSSHOW
				If currentMinute >= 1 Then Return False
			'check programmes
			Case TVTBroadcastMaterialType.PROGRAMME
				If currentMinute >= 5 Then Return False
			'check ads
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				If currentMinute >= 55 Then Return False
		End Select
		Return True
	End Function


	'returns a programme (or null) for the given array index
	Method GetObjectAtIndex:TBroadcastMaterial(objectType:Int=0, arrayIndex:Int)
		Local array:TBroadcastMaterial[] = GetObjectArray(objectType)
		If arrayIndex > 0 And array.length > arrayIndex
			Return array[arrayIndex]
		Else
			Return Null
		EndIf
	End Method


	Method GetObject:TBroadcastMaterial(slotType:Int=0, day:Int=-1, hour:Int=-1)
		Local startHour:Int = GetObjectStartHour(slotType, day, hour)
		If startHour < 0 Then Return Null
		Return GetObjectAtIndex(slotType, GetArrayIndex(startHour))
	End Method


	'returns the block of the media at the given time
	Method GetObjectBlock:Int(objectType:Int=0, day:Int=-1, hour:Int=-1) {_exposeToLua}
		FixDayHour(day, hour)
		Local startHour:Int = GetObjectStartHour(objectType, day, hour)

		If startHour < 0 Then Return -1

		Return 1 + (day * 24 + hour) - startHour
	End Method


	'returns an array of objects within the given time frame of a
	'specific object/list-type
	Method GetObjectsInTimeSpan:TBroadcastMaterial[](objectType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True, requireSameType:Int=False) {_exposeToLua}
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		Local material:TBroadcastMaterial = Null
		Local result:TBroadcastMaterial[]

		'check if the starting time includes a block of a programme starting earlier
		'if so: adjust starting time
		If includeStartingEarlierObject
			'StartHour is "hours since day0"
			Local earlierStartHour:Int = GetObjectStartHour(objectType, dayStart, hourStart)
			If earlierStartHour > -1
				hourStart = earlierStartHour Mod 24
				dayStart = Floor(earlierStartHour / 24)
			EndIf
		EndIf

		'loop through the given range
		Local minIndex:Int = GetArrayIndex(dayStart*24 + hourStart)
		Local maxIndex:Int = GetArrayIndex(dayEnd*24 + hourEnd)
		if maxIndex - minIndex < 0 then return result

		For Local i:Int = minIndex To maxIndex
			material = TBroadcastMaterial(GetObjectAtIndex(objectType, i))
			If Not material Then Continue
			'skip wrong type
			If requireSameType And material.materialType <> objectType Then Continue

			result = result[..result.length+1]
			result[result.length-1] = material
		Next

		Return result
	End Method


	Method GetObjectSlotsInTimeSpan:TBroadcastMaterial[](objectType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		Local material:TBroadcastMaterial = Null
		Local result:TBroadcastMaterial[]

		'loop through the given range
		Local minIndex:Int = GetArrayIndex(dayStart*24 + hourStart)
		Local maxIndex:Int = GetArrayIndex(dayEnd*24 + hourEnd)
		if maxIndex - minIndex < 0 then return result

		result = new TBroadcastMaterial[ maxIndex-minIndex +1 ]
		For Local i:Int = minIndex To maxIndex
			result[i-minIndex] = GetObject(objectType, 0, GetHourFromArrayIndex(i))
		Next

		Return result
	End Method


	'returns whether an object exists in the time span
	'if so - the first (or last) material-instance is returned
	Method ObjectPlannedInTimeSpan:TBroadcastMaterial(material:TBroadcastMaterial, slotType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, startAtLatestTime:Int=False) {_exposeToLua}
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		'check if the starting time includes a block of a programme starting earlier
		'if so: adjust starting time
		'StartHour is "hours since day0"
		Local earlierStartHour:Int = GetObjectStartHour(slotType, dayStart, hourStart)
		If earlierStartHour > -1
			hourStart = earlierStartHour Mod 24
			dayStart = Floor(earlierStartHour / 24)
		EndIf

		'loop through the given range
		Local minIndex:Int = GetArrayIndex(dayStart*24 + hourStart)
		Local maxIndex:Int = GetArrayIndex(dayEnd*24 + hourEnd)
		Local plannedMaterial:TBroadcastMaterial

'materials might differ from each other
'instead of comparing objects we compare their content
		If not startAtLatestTime
			For Local i:Int = minIndex To maxIndex
				Local obj:TBroadcastMaterial = TBroadcastMaterial(GetObjectAtIndex(slotType, i))
				If Not obj Then Continue
				If material.GetReferenceID() = obj.GetReferenceID() Then Return obj
			Next
		Else
			For Local i:Int = maxIndex To minIndex Step -1
				Local obj:TBroadcastMaterial = TBroadcastMaterial(GetObjectAtIndex(slotType, i))
				If Not obj Then Continue
				If material.GetReferenceID() = obj.GetReferenceID() Then Return obj
			Next
		EndIf

		Return Null
	End Method


	Method GetObjectLatestStartHour:Int(material:TBroadcastMaterial, slotType:int, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourend:int=-1) {_exposeToLua}
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		'check ad usage - but only for ads!
		local latestInstance:TBroadcastMaterial = ObjectPlannedInTimeSpan(material, slotType, dayStart, hourStart, dayEnd, hourEnd, True)
		If latestInstance Then return latestInstance.programmedDay*24 + latestInstance.programmedHour
		return -1
	End Method


	'returns the amount of source-users in the time span
	Method GetBroadcastMaterialSourceProgrammedCountInTimeSpan:int(materialSource:TBroadcastMaterialSource, slotType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		'check if the starting time includes a block of a programme starting earlier
		'if so: adjust starting time
		'StartHour is "hours since day0"
		Local earlierStartHour:Int = GetObjectStartHour(slotType, dayStart, hourStart)
		If earlierStartHour > -1
			hourStart = earlierStartHour Mod 24
			dayStart = Floor(earlierStartHour / 24)
		EndIf

		'loop through the given range
		Local minIndex:Int = GetArrayIndex(dayStart*24 + hourStart)
		Local maxIndex:Int = GetArrayIndex(dayEnd*24 + hourEnd)

		local result:int = 0

		'materials might differ from each other
		'instead of comparing objects we compare their content
		For Local i:Int = minIndex To maxIndex
			Local obj:TBroadcastMaterial = TBroadcastMaterial(GetObjectAtIndex(slotType, i))
			If Not obj Then Continue
			If materialSource = obj.GetSource() Then result :+ 1
		Next

		Return result
	End Method


	'returns the hour a object at the given time slot really starts
	'attention: that is not a gamedayHour from 0-24 but in hours since day0
	'returns -1 if no object was found
	Method GetObjectStartHour:Int(objectType:Int=0, day:Int=-1, hour:Int=-1) {_exposeToLua}
		FixDayHour(day, hour)
		Local arrayIndex:Int = GetArrayIndex(day * 24 + hour)

		'out of bounds?
		If arrayIndex < 0 Then Return -1

		Local array:TBroadcastMaterial[] = GetObjectArray(objectType)

		'check if the current hour is the start of an object
		'-> saves further requests (like GetBlocks() )
		If arrayIndex < array.length And array[arrayIndex] Then Return GetHourFromArrayIndex(arrayIndex)

		'search the past for the previous programme
		'then check if start+blocks is still our time
		Local searchIndex:Int = arrayIndex
		While searchIndex >= 0
			If searchIndex < array.length And array[searchIndex]
				If searchIndex + TBroadcastMaterial(array[searchIndex]).GetBlocks() - 1 >= arrayIndex
					Return GetHourFromArrayIndex(searchIndex)
				Else
					Return -1
				EndIf
			EndIf
			searchIndex:-1
		Wend
		Return -1
	End Method


	'add an object / set a slot occupied
	Method AddObject:Int(obj:TBroadcastMaterial, slotType:Int=0, day:Int=-1, hour:Int=-1, checkModifyableSlot:Int=True)
		FixDayHour(day, hour)
		Local arrayIndex:Int = GetArrayIndex(day * 24 + hour)

		'do not allow adding objects we do not own
		If obj.GetOwner() <> owner Then Return False

		'do not allow adding objects we cannot control
		If not obj.IsControllable() then Return False

		'do not allow adding objects which are not available now
		'(eg. exceeded broadcast limit)
		If obj.GetSource()
			if not obj.GetSource().IsAvailable() then Return False
		EndIf

		'the same object is at the exact same slot - skip actions/events
		If obj = GetObjectAtIndex(slotType, arrayIndex) Then Return True


		'check all affected slots whether they allow modification
		'do not allow adding in the past
		'do not allow adding to a locked slot
		If checkModifyableSlot
			if not BelongsToModifiyableSlot(slotType, day, hour)
				'TLogger.Log("TPlayerProgrammePlan.AddObject", "Failed: slot (type="+slotType+", day="+day+", hour="+hour+") cannot get modified - belongs to not-modifyable broadcast. GameTime:" + GetWorldTime().GetFormattedTime(), LOG_INFO)
				return False
			endif

			For Local i:Int = 0 To obj.GetBlocks(slotType) -1
				if Not IsModifyableSlot(slotType, day, hour + i)
					'TLogger.Log("TPlayerProgrammePlan.AddObject", "Failed: slot (type="+slotType+", day="+day+", hour="+hour+", block="+i+", blockHour="+(hour+i)+") cannot get modified - is in the past or locked. GameTime:" + GetWorldTime().GetFormattedTime(), LOG_INFO)
					Return False
				endif
			Next
		EndIf


		'clear all potential overlapping objects
		Local removedObjects:Object[]
		Local removedObject:Object
		For Local i:Int = 0 To obj.GetBlocks(slotType) -1
			removedObject = RemoveObject(Null, slotType, day, hour+i, checkModifyableSlot)
			If removedObject then removedObjects :+ [removedObject]
		Next

		'add the object to the corresponding array
		SetObjectArrayEntry(obj, slotType, arrayIndex)
		obj.programmedDay = day
		obj.programmedHour = hour
		'assign "used as type"
		obj.setUsedAsType(slotType)


		'special for programmelicences: set a maximum planned time
		'setting does not require special calculations
		If TProgramme(obj)
			TProgramme(obj).licence.SetPlanned(day*24+hour+obj.GetBlocks(slotType))
			'ProgrammeLicences: recalculate the latest planned hour
			RecalculatePlannedProgramme(TProgramme(obj))
		EndIf

		'Advertisements: adjust planned (when placing in contract-slot
		If slotType = TVTBroadcastMaterialType.ADVERTISEMENT and TAdvertisement(obj)
			TAdvertisement(obj).contract.SetSpotsPlanned( GetAdvertisementsPlanned(TAdvertisement(obj).contract) )
		Endif

		'if slotType = TVTBroadcastMaterialType.ADVERTISEMENT
			'TLogger.Log("PlayerProgrammePlan.AddObject()", "Plan #"+owner+" added object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") to ADVERTISEMENTS, index="+arrayIndex+", day="+day+", hour="+hour+". Removed "+removedObjects.length+" objects before.", LOG_DEBUG)
		'else
			'TLogger.Log("PlayerProgrammePlan.AddObject()", "Plan #"+owner+" added object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") to PROGRAMMES, index="+arrayIndex+", day="+day+", hour="+hour+". Removed "+removedObjects.length+" objects before.", LOG_DEBUG)
		'endif

		'invalidate cache
		_daysPlanned = -1

		'emit an event
		If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("programmeplan.addObject", New TData.add("object", obj).add("removedObjects", removedObjects).addNumber("slotType", slotType).addNumber("day", day).addNumber("hour", hour), Self))

		Return True
	End Method


	'remove object from slot / clear a slot
	'if no obj is given it is tried to get one by day/hour
	'returns the deleted object if one is found
	Method RemoveObject:Object(obj:TBroadcastMaterial=Null, slotType:Int=0, day:Int=-1, hour:Int=-1, checkModifyableSlot:int=True)
		If Not obj Then obj = GetObject(slotType, day, hour)
		If Not obj Then Return Null

		'do not allow removing objects we cannot control
		'(to forcefully remove the, unset that flag before!
		If not obj.IsControllable() then Return Null

		'if not programmed, skip deletion and events
		If obj.isProgrammed()
			'backup programmed date for event
			Local programmedDay:Int = obj.programmedDay
			Local programmedHour:Int = obj.programmedHour

			'nothing to remove - or wrong one
			if obj <> GetObject(slotType, programmedDay, programmedHour)
				'obj = GetObject(slotType, day, hour)
				'if not obj
					TLogger.Log("TPlayerProgrammePlan.RemoveObject", "Failed with programmedDay and programmedHour being invalid.", LOG_ERROR)
					return Null
				'endif
				'programmedDay = obj.programmedDay
				'programmedHour = obj.programmedHour
				'TLogger.Log("TPlayerProgrammePlan.RemoveObject", "Using alternative GetObject.", LOG_DEBUG)
				'?debug
				'DebugStop
				'?
			endif

			If checkModifyableSlot
				For Local i:Int = 0 To obj.GetBlocks(slotType) -1
					if Not IsModifyableSlot(slotType, programmedDay, programmedHour + i)
						TLogger.Log("TPlayerProgrammePlan.RemoveObject", "Failed: slot (type="+slotType+", day="+day+", hour="+hour+", block="+i+", blockHour="+(hour+i)+") cannot get modified - is in the past or locked", LOG_INFO)
						Return Null
					endif
				Next
			EndIf

			'reset programmed date
			obj.programmedDay = -1
			obj.programmedHour = -1

			'null the corresponding array index
			SetObjectArrayEntry(Null, slotType, GetArrayIndex(programmedDay*24 + programmedHour))

			'ProgrammeLicences: recalculate the latest planned hour
			If TProgramme(obj) Then RecalculatePlannedProgramme(TProgramme(obj))
			'Advertisements: adjust planned amount
			If TAdvertisement(obj) Then TAdvertisement(obj).contract.SetSpotsPlanned( GetAdvertisementsPlanned(TAdvertisement(obj).contract) )

			rem
			if slotType = TVTBroadcastMaterialType.ADVERTISEMENT
				TLogger.Log("PlayerProgrammePlan.RemoveObject()", "Plan #"+owner+" removed object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") from ADVERTISEMENTS, index="+GetArrayIndex(programmedDay*24 + programmedHour)+", programmedDay="+programmedDay+", programmedHour="+programmedHour+".", LOG_DEBUG)
			else
				TLogger.Log("PlayerProgrammePlan.RemoveObject()", "Plan #"+owner+" removed object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") from PROGRAMMES, index="+GetArrayIndex(programmedDay*24 + programmedHour)+", programmedDay="+programmedDay+", programmedHour="+programmedHour+".", LOG_DEBUG)
			endif
			endrem

			'invalidate cache
			_daysPlanned = -1

			'inform others
			If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("programmeplan.removeObject", New TData.add("object", obj).addNumber("slotType", slotType).addNumber("day", programmedDay).addNumber("hour", programmedHour), Self))
		else
			if slotType = TVTBroadcastMaterialType.ADVERTISEMENT
				TLogger.Log("PlayerProgrammePlan.RemoveObject()", "Plan #"+owner+" SKIPPED removal of object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") from ADVERTISEMENTS - not programmed.", LOG_DEBUG)
			else
				TLogger.Log("PlayerProgrammePlan.RemoveObject()", "Plan #"+owner+" SKIPPED removal of object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") from PROGRAMMES - not programmed.", LOG_DEBUG)
			endif
		EndIf

		Return obj
	End Method


	'Removes all not-yet-run instances of the given programme from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveObjectInstances:Int(obj:TBroadcastMaterial, slotType:Int=0, time:Long=-1, removeCurrentRunning:Int=False)
		If time = -1 Then time = GetWorldTime().GetTimeGone()
		local currentHour:int = GetWorldTime().GetHour(time)

		'programme finished this block already
		if slotType = TVTBroadcastMaterialType.PROGRAMME
			if GetWorldTime().GetDayMinute(time) >= 55 then currentHour :+ 1
		endif

		rem
		if slotType = TVTBroadcastMaterialType.PROGRAMME
			TLogger.Log("PlayerProgrammePlan.RemoveObjectInstances()", "Plan #"+owner+" removes all instances of object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") from PROGRAMMES.", LOG_DEBUG)
		else
			TLogger.Log("PlayerProgrammePlan.RemoveObjectInstances()", "Plan #"+owner+" removes all instances of object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") from ADVERTISEMENTS.", LOG_DEBUG)
		endif
		endrem


		Local array:TBroadcastMaterial[] = GetObjectArray(slotType)
		Local earliestIndex:Int = Max(0, GetArrayIndex(currentHour - obj.GetBlocks()))
		Local currentIndex:Int = Max(0, GetArrayIndex(currentHour))
		Local latestIndex:Int = array.length - 1
		Local foundAnInstance:Int = False

		'lock back in the history (programme may have started some blocks ago and is
		'still running
		For Local i:Int = earliestIndex To latestIndex
			'skip other programmes
			If Not TBroadcastMaterial(array[i]) Then Continue
			If array[i].GetReferenceID() <> obj.GetReferenceID() Then Continue

			'only remove if sending is planned in the future or param allows current one
			If i + removeCurrentRunning * obj.GetBlocks() > currentIndex
				For Local j:Int = 0 To obj.GetBlocks()-1
					'method a) removeObject - emits events for each removed item
					RemoveObject(Null, slotType, 0, GetHourFromArrayIndex(i+j), not removeCurrentRunning)
					'method b) just clear the array at the given index
					'SetObjectArrayEntry(null, slotType, GetHourFromArrayIndex(i+j))
				Next
				foundAnInstance = True
			EndIf
		Next

		If foundAnInstance
			If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("programmeplan.removeObjectInstances", New TData.add("object", obj).addNumber("slotType", slotType).addNumber("removeCurrentRunning", removeCurrentRunning), Self))
			Return True
		Else
			Return False
		EndIf
	End Method


	'Returns whether an object could be placed at the given day/time
	'without disturbing others
	Method ObjectPlaceable:Int(obj:TBroadcastMaterial, slotType:Int=0, day:Int=-1, hour:Int=-1)
		If Not obj Then Return 0
		'you cannot place an object you do not own
		'TODO: check how to work out objects of 3rd parties, maybe we
		'      should add a force-param
		if not obj.IsOwner(owner) then return False

		FixDayHour(day, hour)

		'check live programme
		if not obj.GetSource().CanBroadcastAtTime(slotType, day, hour)
			return -1
		endif

		'check all slots the obj will occupy...
		For Local i:Int = 0 To obj.GetBlocks() - 1
			'... and if there is already an object, return the information
			If GetObject(slotType, day, hour + i) Then Return -2
		Next

		Return 1
	End Method


	Method RemoveBrokenObjects:int()
		'TODO: Ronny: find out when this might happen ?!
		'fix broken ones (reported via savegame by user Teppic)
		local toRemove:TBroadcastMaterial[]
		local fixed:int = 0
		'do not process things happening in the past
		local start:int = GetArrayIndex(GetWorldTime().GetHour())

		For local i:int = start until programmes.length
			if not programmes[i] then continue

			local t:long = GetWorldTime().MakeTime(0, 0, GetHourFromArrayIndex(i), 0,0)

			if programmes[i].programmedDay = -1 or programmes[i].programmedDay <> GetWorldTime().GetDay(t) or programmes[i].programmedHour <> GetWorldTime().GetDayHour(t)
				local useIndex:int = i

				if programmes[i].programmedDay <> GetWorldTime().GetDay(t) or programmes[i].programmedHour <> GetWorldTime().GetDayHour(t)
					'find first occourence (doublettes check)
					For local j:int = 0 until i
						if programmes[j] = programmes[i]
							useIndex  = j
							exit
						endif
					Next
				endif

				'remove oddly placed programme
				if useIndex <> i
					programmes[i] = null
				else
					local t:long = GetWorldTime().MakeTime(0, 0, GetHourFromArrayIndex(i), 0,0)
					programmes[i].programmedDay = GetWorldTime().GetDay(t)
					programmes[i].programmedHour = GetWorldTime().GetDayHour(t)
					toRemove :+ [programmes[i]]
				endif
			endif
		Next

		For local i:int = start until advertisements.length
			if not advertisements[i] then continue
			if advertisements[i].programmedDay = -1
				local t:long = GetWorldTime().MakeTime(0, 0, GetHourFromArrayIndex(i), 0,0)
				advertisements[i].programmedDay = GetWorldTime().GetDay(t)
				advertisements[i].programmedHour = GetWorldTime().GetDayHour(t)
				toRemove :+ [advertisements[i]]
			endif
		Next


		'avoid direct array modification, so we loop over an extra array
		for local b:TBroadcastMaterial = eachin toRemove
			local t:long = GetWorldTime().MakeTime(0, b.programmedDay, b.programmedHour, 0,0)
			if TAdvertisement(b)
				RemoveAdvertisement(b)
				TLogger.Log("PlayerProgrammePlan", "RemoveBrokenObjects() had to remove BROKEN ad ~q" + b.GetTitle()+"~q from day="+GetWorldTime().GetDay(t)+" hour="+GetWorldTime().GetDayHour(t)+":55.", LOG_ERROR)
			elseif TProgramme(b)
				RemoveProgramme(b)
				TLogger.Log("PlayerProgrammePlan", "RemoveBrokenObjects() had to remove BROKEN programme ~q" + b.GetTitle()+"~q from day="+GetWorldTime().GetDay(t)+" hour="+GetWorldTime().GetDayHour(t)+":00.", LOG_ERROR)
			endif
			fixed :+ 1
		Next

		return fixed
	End Method


	Method GetDaysPlanned:int()
		if _daysPlanned = -1
			For local i:int = programmes.length -1 to 0 step -1
				if not programmes[i] then continue
				local endDay:int = programmes[i].programmedDay
				local endHour:int = programmes[i].programmedHour + programmes[i].GetBlocks( TVTBroadcastMaterialType.PROGRAMME )
				FixDayHour(endDay, endHour)

				_daysPlanned = Max(_daysPlanned, endDay)
				exit
			Next
			For local i:int = advertisements.length -1 to 0 step -1
				if not advertisements[i] then continue
				local endDay:int = advertisements[i].programmedDay
				local endHour:int = advertisements[i].programmedHour + advertisements[i].GetBlocks( TVTBroadcastMaterialType.ADVERTISEMENT )
				FixDayHour(endDay, endHour)

				_daysPlanned = Max(_daysPlanned, endDay)
				exit
			Next
		endif

		return _daysPlanned
	End Method


	'===== PROGRAMME FUNCTIONS =====
	'mostly wrapping the commong object functions


	'returns the hour a programme at the given time slot really starts
	'attention: that is not a gamedayHour from 0-24 but in hours since day0
	'returns -1 if no programme was found
	Method GetProgrammeStartHour:Int(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObjectStartHour(TVTBroadcastMaterialType.PROGRAMME, day, hour)
	End Method


	'returns the current block a programme is in (eg. 2 [of 3])
	Method GetProgrammeBlock:Int(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObjectBlock(TVTBroadcastMaterialType.PROGRAMME, day, hour)
	End Method


	'clear a slot so others can get placed without trouble
	Method RemoveProgramme:Int(obj:TBroadcastMaterial=Null, day:Int=-1, hour:Int=-1) {_exposeToLua}
		return _RemoveProgramme(obj, day, hour)
	End Method


	Method ForceRemoveProgramme:Int(obj:TBroadcastMaterial=Null, day:Int=-1, hour:Int=-1) {_exposeToLua}
		return _RemoveProgramme(obj, day, hour, True)
	End Method


	'clear a slot so others can get placed without trouble
	Method _RemoveProgramme:Int(obj:TBroadcastMaterial=Null, day:Int=-1, hour:Int=-1, forceRemove:int=False)
		'if no obj was provided, use the day/time to fetch an object
		If Not obj Then obj = GetObject(TVTBroadcastMaterialType.PROGRAMME, day, hour)
		if not obj then return False
		'if alread not set for that time, just return success
		If Not obj.isProgrammed() Then Return True

		'print "RON: PLAN.RemoveProgramme       owner="+owner+" day="+day+" hour="+hour + " obj :"+obj.GetTitle()

		'backup programmed date
		Local programmedDay:Int = obj.programmedDay
		Local programmedHour:Int = obj.programmedHour

		'try to remove the object from the array
		Return (Null <> RemoveObject(obj, TVTBroadcastMaterialType.PROGRAMME, day, hour, not forceRemove))
	End Method


	'Removes all not-yet-run users of the given programme licence from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveProgrammeInstancesByLicence:Int(licence:TProgrammeLicence, removeCurrentRunning:Int=False)
		'Maybe we got a collection/series - so revoke all sublicences
		If licence.GetSubLicenceSlots() > 0
			For Local subLicence:TProgrammeLicence = EachIn licence.subLicences
				RemoveProgrammeInstancesByLicence(subLicence, removeCurrentRunning)
			Next
			Return True
		EndIf

		'first of all we need to find a user of our licence
		'read: find a programme which uses the licence
		'loop other all potential slot types so to find programmes
		'which are not planned, but eg. promoted by trailers
		local slotTypes:int[] = [TVTBroadcastMaterialType.PROGRAMME, TVTBroadcastMaterialType.ADVERTISEMENT]
		Local programme:TBroadcastMaterial
		Local currentHour:Int = GetWorldTime().GetHour()

		For local slotType:int = EachIn slotTypes
			Local array:TBroadcastMaterial[] = GetObjectArray(slotType)
			Local earliestIndex:Int = Max(0, GetArrayIndex(currentHour - licence.GetBlocks(slotType)))
			Local currentIndex:Int = Max(0, GetArrayIndex(currentHour))
			Local latestIndex:Int = array.length - 1
			'lock back in the history (programme may have started some blocks ago and is
			'still running
			For Local i:Int = earliestIndex To latestIndex
				'skip other programmes
				If Not TBroadcastMaterial(array[i]) Then Continue

				If array[i].GetReferenceID() <> licence.GetReferenceID() Then Continue

				programme = TBroadcastMaterial(array[i])
				Exit
			Next

			'skip checking advertisement-slots if already found something
			If programme Then exit
		Next

		'no instance found - no need to call the programmeRemover
		If Not programme Then Return True

		Return RemoveProgrammeInstances(programme, removeCurrentRunning)
	End Method


	'Removes all not-yet-run instances of the given programme from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveProgrammeInstances:Int(obj:TBroadcastMaterial, removeCurrentRunning:Int=False)
		Local doneSomething:Int=False
		Local programme:TBroadcastMaterial
		If GetWorldTime().GetDayMinute() >= 5 And GetWorldTime().GetDayMinute() < 55
			programme = GetProgramme()
		EndIf

		If RemoveObjectInstances(obj, TVTBroadcastMaterialType.PROGRAMME, -1, removeCurrentRunning)
			'if the object is the current broadcasted thing, reset audience
			If programme And obj = programme
				GetBroadcastManager().SetBroadcastMalfunction(owner, TVTBroadcastMaterialType.PROGRAMME)

				programme.AbortBroadcasting(GetWorldTime().GetDay(), GetWorldTime().GetDayHour(), GetWorldTime().GetDayMinute(), null)
			EndIf
			doneSomething = True
		EndIf
		'also remove from advertisement slots (Trailers)
		If RemoveObjectInstances(obj, TVTBroadcastMaterialType.ADVERTISEMENT, -1, removeCurrentRunning)
			doneSomething = True
		EndIF
		Return doneSomething
	End Method


	'refreshes the programme's licence "latestPlannedEndHour"
	Method RecalculatePlannedProgramme:Int(programme:TProgramme, dayStart:Int=-1, hourStart:Int=-1)
		'done in "ObjectPlannedInTimeSpan()" calls already
		FixDayHour(dayStart, hourStart)
		'FixDayHour(dayEnd, hourEnd)

		'dayEnd = -1 means, only check the current day
		local dayEnd:Int = -1
		local hourEnd:int = 23

		'override dayEnd to check ALL already planned days
		dayEnd = GetDaysPlanned()

		If programme.licence.owner <= 0
			programme.licence.SetPlanned(-1)
			programme.licence.SetTrailerPlanned(-1)
		Else
			'find "longest running" in all available type slots
			'if none is found, the planned value contains "-1"
			Local instance:TBroadcastMaterial
			'latestHour then contains "hours since startDay 0:00"
			Local latestHour:Int = -1
			Local latestAdHour:Int = -1

			'check ad usage - but only for ads!
			instance = ObjectPlannedInTimeSpan(programme, TVTBroadcastMaterialType.ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd, True)
			If instance Then latestAdHour = Max(latestAdHour, instance.programmedDay*24+instance.programmedHour + instance.GetBlocks(TVTBroadcastMaterialType.ADVERTISEMENT))
			'check prog usage
			instance = ObjectPlannedInTimeSpan(programme, TVTBroadcastMaterialType.PROGRAMME, dayStart, hourStart, dayEnd, hourEnd, True)
			If instance Then latestHour = Max(latestHour, instance.programmedDay*24+instance.programmedHour + instance.GetBlocks(TVTBroadcastMaterialType.PROGRAMME))

			programme.licence.SetPlanned(latestHour)
			programme.licence.SetTrailerPlanned(latestAdHour)
		EndIf
		Return True
	End Method



	'Returns the programme for the given day/time
	Method GetProgramme:TBroadcastMaterial(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObject(TVTBroadcastMaterialType.PROGRAMME, day, hour)
	End Method


	'returns an array of real programmes (no infomercials or so) within
	'the given time frame
	Method GetRealProgrammesInTimeSpan:TProgramme[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True) {_exposeToLua}
		Return TProgramme[](GetObjectsInTimeSpan(TVTBroadcastMaterialType.PROGRAMME, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject, True))
	End Method


	'returns an array of used-as programme within the given time frame
	'in the programme list
	Method GetProgrammesInTimeSpan:TBroadcastMaterial[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True) {_exposeToLua}
		Return GetObjectsInTimeSpan(TVTBroadcastMaterialType.PROGRAMME, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject)
	End Method


	'returns an array of broadcast material (or null) for all slots in the
	'given time frame
	Method GetProgrammeSlotsInTimeSpan:TBroadcastMaterial[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		Return GetObjectSlotsInTimeSpan(TVTBroadcastMaterialType.PROGRAMME, dayStart, hourStart, dayEnd, hourEnd)
	End Method


	Method ProgrammePlannedInTimeSpan:Int(material:TBroadcastMaterial, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		'check if planned as programme
		If ObjectPlannedInTimeSpan(material, TVTBroadcastMaterialType.PROGRAMME, dayStart, hourStart, dayEnd, hourEnd)
			Return True
		Else
			'check if planned as trailer
			If ObjectPlannedInTimeSpan(material, TVTBroadcastMaterialType.ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd)
				Return True
			Else
				Return False
			EndIf
		EndIf
	End Method


	'Add a used-as-programme to the player's programme plan
	Method SetProgrammeSlot:Int(obj:TBroadcastMaterial, day:Int=-1, hour:Int=-1)
		'if nothing is given, we have to reset that slot
		If Not obj Then Return (Null<>RemoveObject(Null, TVTBroadcastMaterialType.PROGRAMME, day, hour))

		'check if we are allowed to place it there
		'for now, only skip if failing live programme or time slot fails (-1)
		'- if also interested in "other programme on slots", this is -2
		if ProgrammePlaceable(obj, day, hour) = -1 then return False

		Return AddObject(obj, TVTBroadcastMaterialType.PROGRAMME, day, hour)
	End Method


	'Returns whether a used-as-programme can be placed at the given day/time
	'without intercepting other programmes
	Method ProgrammePlaceable:Int(obj:TBroadcastMaterial, day:Int=-1, hour:int=-1)
		Return ObjectPlaceable(obj, TVTBroadcastMaterialType.PROGRAMME, day, hour)
	End Method


	'counts how many times a licence is planned as programme (this
	'includes infomercials and movies/series/programmes)
	Method GetBroadcastMaterialInPlanCount:Int(referenceID:Int, day:Int=-1, includePlanned:Int=False, includeStartedYesterday:Int=True, slotType:int = 0) {_exposeToLua}
		If day = -1 Then day = GetWorldTime().GetDay()
		'no filter for other days than today ... would be senseless
		If day <> GetWorldTime().GetDay() Then includePlanned = True
		Local count:Int = 0
		Local minHour:Int = 0
		Local maxHour:Int = 23
		Local material:TBroadcastMaterial = null

		'include programmes which may not be run yet?
		'else we stop at the current time of the day...
		If Not includePlanned Then maxhour = GetWorldTime().GetDayHour()

		'debug
		'print "HowOftenProgrammeLicenceInPlan: day="+day+" GameDay="+GetWorldTime().getDay()+" minHour="+minHour+" maxHour="+maxHour + " includeYesterday="+includeStartedYesterday

		'only programmes with more than 1 block can start the day before
		'and still run the next day - so we have to check that too
		If includeStartedYesterday
			'we just compare the programme started 23:00 or earlier the day before
			if slotType = TVTBroadcastMaterialType.PROGRAMME
				material = GetProgramme(day - 1, 23)
			elseif slotType = TVTBroadcastMaterialType.ADVERTISEMENT
				material = GetAdvertisement(day - 1, 23)
			endif
			If material And material.GetReferenceID() = referenceID And material.GetBlocks(slotType) > 1
				count:+1
				'add the hours the programme "takes over" to the next day
				minHour = (GetObjectStartHour(slotType, day - 1, 23) + material.GetBlocks(slotType)) Mod 24
			EndIf
		EndIf

		Local midnightIndex:Int = GetArrayIndex(day * 24)
		For Local i:Int = minHour To maxHour
			material = GetObjectAtIndex(slotType, midnightIndex + i)
			'no need to skip blocks as only the first block of a programme
			'is stored in the array
			If material And material.GetReferenceID() = referenceID Then count:+1
		Next

		Return count
	End Method



	'===== Advertisement contract functions =====


	'returns the hour a advertisement at the given time slot really starts
	'returns -1 if no ad was found
	Method GetAdvertisementStartHour:Int(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObjectStartHour(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)
	End Method


	Method GetAdContractLatestStartHour:Int(contract:object, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:int=-1) {_exposeToLua}
		if not TAdContract(contract) then return -1

		Local minIndex:Int = 0
		Local maxIndex:Int = advertisements.length

		FixDayHour(dayStart, hourStart)
		minIndex = GetArrayIndex(dayStart*24 + hourStart)

		if dayEnd <> -1 and hourEnd <> -1
			FixDayHour(dayEnd, hourEnd)
			maxIndex = GetArrayIndex(dayEnd*24 + hourEnd)
		endif

		'loop through the given range
		For Local i:Int = maxIndex To minIndex Step -1
			Local obj:TAdvertisement = TAdvertisement(GetObjectAtIndex(TVTBroadcastMaterialType.ADVERTISEMENT, i))
			If Not obj Then Continue
			If obj.contract = contract Then Return obj.programmedDay*24 + obj.programmedHour
		Next
		return -1
	End Method


	Method GetAdvertisementBlock:Int(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObjectBlock(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)
	End Method


	'returns how many times an contract was programmed since signing the contract
	'start time: contract sign
	'end time: day +/- hour (if day > -1)
	Method GetAdvertisementsSent:Int(contract:TAdContract, day:Int=-1, hour:Int=0, onlySuccessful:Int=False) {_exposeToLua}
		Return GetAdvertisementsCount(contract, day, hour, True, False)
	End Method


	Method GetAdvertisementsPlanned:Int(contract:TAdContract, startHour:int=-1, endHour:int=-1, includeSuccessful:Int=True) {_exposeToLua}
		Local endIndex:Int = advertisements.length-1

		'default: start with time of the sign
		if startHour = -1 then startHour = 24 * (contract.daySigned - 1)
		'default: end with latest planned element
		if endHour > -1 then endIndex = Min(endIndex, GetArrayIndex(endHour))

		Local startIndex:Int= Max(0, GetArrayIndex(startHour))

		Local count:Int	= 0
		For Local i:Int = startIndex To endIndex
			Local ad:TAdvertisement = TAdvertisement(advertisements[i])
			'skip missing or wrong ads
			If Not ad Or ad.contract <> contract Then Continue
			'skip failed
			If ad.isState(ad.STATE_FAILED) Then Continue
			'skip sent ads if wanted
			If Not includeSuccessful And ad.isState(ad.STATE_OK) Then Continue

			count:+1
		Next
		Return count
	End Method


	'returns how many times advertisements of an adcontract were sent/planned...
	'in the case of no given day, the hour MUST be given (or set to 0)
	'
	'start time: contract sign
	'end time: day +/- hour (if day > -1)
	Method GetAdvertisementsCount:Int(contract:TAdContract, day:Int=-1, hour:Int=0, onlySuccessful:Int=True, includePlanned:Int=False)
		Local startIndex:Int= Max(0, GetArrayIndex(24 * (contract.daySigned - 1)))
		Local endIndex:Int	= 0
		If day = -1
			endIndex = advertisements.length-1 + hour
		Else
			endIndex = GetArrayIndex(day*24 + hour)
		EndIf
		endIndex = Min(advertisements.length-1, Max(0,endIndex))

		'somehow we have a timeframe ending earlier than starting
		If endIndex < startIndex Then Return 0

		Local count:Int	= 0
		For Local i:Int = startIndex To endIndex
			Local ad:TAdvertisement = TAdvertisement(advertisements[i])
			'skip missing or wrong ads
			If Not ad Or ad.contract <> contract Then Continue

			If onlySuccessful And ad.isState(ad.STATE_FAILED) Then Continue
			If Not includePlanned And ad.isState(ad.STATE_NORMAL) Then Continue

			count:+1
		Next
		Return count
	End Method


	'clear a slot so others can get placed without trouble
	Method RemoveAdvertisement:Int(obj:TBroadcastMaterial=Null, day:Int=-1, hour:Int=-1) {_exposeToLua}
		If Not obj Then obj = GetObject(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)
		If obj
			'backup programmed date
			Local programmedDay:Int = obj.programmedDay
			Local programmedHour:Int = obj.programmedHour

			'try to remove the object from the array
			Return (Null <> RemoveObject(obj, TVTBroadcastMaterialType.ADVERTISEMENT, day, hour))
		EndIf
		Return False
	End Method



	'Removes all not-yet-run sisters of the given ad from the plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveAdvertisementInstances:Int(obj:TBroadcastMaterial, removeCurrentRunning:Int=False)
		Local doneSomething:Int=False
		If RemoveObjectInstances(obj, TVTBroadcastMaterialType.PROGRAMME, -1, removeCurrentRunning) Then doneSomething = True
		If RemoveObjectInstances(obj, TVTBroadcastMaterialType.ADVERTISEMENT, -1, removeCurrentRunning) Then doneSomething = True
		Return doneSomething
	End Method


	'Returns the ad for the given day/time
	Method GetAdvertisement:TBroadcastMaterial(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObject(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)
	End Method


	'Returns the ad for the given day/time
	Method GetRealAdvertisement:TAdvertisement(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return TAdvertisement(GetObject(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour))
	End Method


	'returns an array of real advertisements within the given time frame
	'in the advertisement list
	Method GetRealAdvertisementsInTimeSpan:TAdvertisement[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True) {_exposeToLua}
		Return TAdvertisement[](GetObjectsInTimeSpan(TVTBroadcastMaterialType.ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject, True))
	End Method


	'returns an array of broadcast material (or null) for all slots in the
	'given time frame
	Method GetAdvertisementSlotsInTimeSpan:TBroadcastMaterial[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		Return GetObjectSlotsInTimeSpan(TVTBroadcastMaterialType.ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd)
	End Method


	'returns an array of used-as advertisements within the given time
	'frame in the advertisement list
	Method GetAdvertisementsInTimeSpan:TBroadcastMaterial[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True) {_exposeToLua}
		Return GetObjectsInTimeSpan(TVTBroadcastMaterialType.ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject)
	End Method


	Method AdvertisementPlannedInTimeSpan:Int(material:TBroadcastMaterial, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		'check if planned as ad
		If ObjectPlannedInTimeSpan(material, TVTBroadcastMaterialType.ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd)
			Return True
		Else
			'check if planned as infomercial
			If ObjectPlannedInTimeSpan(material, TVTBroadcastMaterialType.PROGRAMME, dayStart, hourStart, dayEnd, hourEnd)
				Return True
			Else
				Return False
			EndIf
		EndIf
	End Method


	'Fill/Clear the given advertisement slot with the given broadcast material
	Method SetAdvertisementSlot:Int(obj:TBroadcastMaterial, day:Int=-1, hour:Int=-1)
		'if nothing is given, we have to reset that slot
		If Not obj Then Return (Null<>RemoveObject(Null, TVTBroadcastMaterialType.ADVERTISEMENT, day, hour))

		'check if we are allowed to place it there
		'ATTENTION: check for -1 as "-2" means there is another
		'           broadcastmaterial at the desired slot
		if AdvertisementPlaceable(obj, day, hour) = -1 then return False

		'add it
		Return AddObject(obj, TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)
	End Method


	'Returns whether a programme can be placed at the given day/time
	Method AdvertisementPlaceable:Int(obj:TBroadcastMaterial, day:Int=-1, hour:int=-1)
		Return ObjectPlaceable(obj, TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)
	End Method


	'returns the next number a new ad spot will have (counts all existing non-failed ads + 1)
	Method GetNextAdvertisementSpotNumber:Int(contract:TAdContract) {_exposeToLua}
		Return 1 + GetAdvertisementsCount(contract, -1, 0, True, True)
	End Method



	'===== NEWS FUNCTIONS =====

    Method SetNewsByGUID:Int(newsGUID:string, slot:Int) {_exposeToLua}
		'use RemoveNews() to unset a news
		If not newsGUID then return False

		local news:TNews = GetPlayerProgrammeCollection(owner).GetNews(newsGUID)
		if not news then return False

		return SetNews(news, slot)
	End Method


	'set the slot of the given newsblock
	'if not paid yet, it will only continue if pay is possible
    Method SetNews:Int(newsObject:TNews, slot:Int) {_exposeToLua}
		'use RemoveNews() to unset a news
		If not newsObject then return False

		'out of bounds check
		If slot < 0 Or slot >= news.length Then Return False

		'do not continue if pay not possible but needed
		If Not newsObject.Pay() Then Return False

		'if just dropping on the own slot ...do nothing
		If news[slot] = newsObject Then Return True

		'remove this news from slots if it occupies some of them
		'do not add it back to the collection
		'-> this avoids duplicate "cannot remove" messages
		'-> the news is already removed from the collection some lines later
		For Local i:Int = 0 To news.length-1
			if GetNewsAtIndex(i) = newsObject then RemoveNewsBySlot(i, False)
		Next

		'is there an other newsblock, remove that first
		'and adding that back to the collection
		If news[slot] Then RemoveNewsBySlot(slot, True)

		'nothing is against using that slot (payment, ...) - so assign it
		news[slot] = newsObject

		'remove that news from the collection
		GetPlayerProgrammeCollection(owner).RemoveNews(newsObject)


		'emit an event so eg. network can recognize the change
		If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("programmeplan.SetNews", New TData.Add("news",newsObject).AddNumber("slot", slot), self))

		Return True
    End Method


	Method RemoveNewsBySlot:Int(slot:Int, addToCollection:Int=True) {_exposeToLua}
		return RemoveNews(null, slot, addToCollection)
	End Method


	Method RemoveNewsByGUID:Int(newsGUID:string="", addToCollection:Int=True) {_exposeToLua}
		For Local i:Int = 0 To news.length-1
			local news:TNews = TNews(GetNewsAtIndex(i))
			If not news or news.GetGUID() <> newsGUID Then continue

			return RemoveNews(news, i, addToCollection)
		Next

		Return False
	End Method


	'Remove the news from the plan
	'by default the news gets added back to the collection, this can
	'be controlled with the third param "addToCollection"
	Method RemoveNews:Int(newsObject:TNews=null, slot:Int=-1, addToCollection:Int=True) {_exposeToLua}
		Local newsSlot:Int = slot
		'try to find the slot occupied by the news
		If newsObject and slot < 0
			For Local i:Int = 0 To news.length-1
				local news:TBroadcastMaterial = GetNewsAtIndex(i)
				If news = newsObject Then newsSlot = i;Exit
			Next
		EndIf

		'was the news planned (-> in a slot) ?
		If GetNewsAtIndex(newsSlot)
			Local deletedNews:TBroadcastMaterial = news[newsSlot]

			'add that news back to the collection ?
			If addToCollection And TNews(deletedNews)
				GetPlayerProgrammeCollection(owner).AddNews(TNews(deletedNews))
			EndIf

			'empty the slot
			news[newsSlot] = Null

			If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("programmeplan.RemoveNews", New TData.Add("news", deletedNews).AddNumber("slot", newsSlot), self))
			Return True
		EndIf
		Return False
	End Method


	Method HasNewsEvent:Int(newsEventObjectOrGUID:object) {_exposeToLua}
		local guid:string = ""
		if TBroadcastMaterialSource(newsEventObjectOrGUID)
			guid = TBroadcastMaterialSource(newsEventObjectOrGUID).GetGUID()
		else
			guid = string(newsEventObjectOrGUID)
		endif

		For local newsEntry:TNews = EachIn news
			if newsEntry.newsEvent.GetGUID() = guid then Return True
		Next
		Return False
	End Method


	Method HasNews:Int(newsObjectOrGUID:object) {_exposeToLua}
		local guid:string = ""
		if TBroadcastMaterial(newsObjectOrGUID)
			guid = TBroadcastMaterial(newsObjectOrGUID).GetGUID()
		else
			guid = string(newsObjectOrGUID)
		endif

		For local newsEntry:TBroadcastMaterial = EachIn news
			if newsEntry.GetGUID() = guid then Return True
		Next
		Return False
	End Method


	Method GetNews:TBroadcastMaterial(GUID:string) {_exposeToLua}
		For local newsEntry:TBroadcastMaterial = EachIn news
			if newsEntry.GetGUID() = GUID then Return newsEntry
		Next
		Return Null
	End Method


	Method GetNewsArray:TBroadcastMaterial[]() {_exposeToLua}
		Return news
	End Method


	Method GetNewsAtIndex:TBroadcastMaterial(index:Int) {_exposeToLua}
		'out of bounds check
		If index < 0 Or index >= news.length Then Return Null

		Return news[index]
	End Method


	Method ProduceNewsShow:TBroadcastMaterial()
		Local show:TNewsShow = TNewsShow.Create("News show " + GetWorldTime().GetFormattedTime(), owner, GetNewsAtIndex(0),GetNewsAtIndex(1),GetNewsAtIndex(2))
		'if
		AddObject(show, TVTBroadcastMaterialType.NEWSSHOW,-1,-1, False)
			'print "Production of news show for player "+owner + " OK."
		'endif
		Return show
	End Method


	Method GetNewsShow:TBroadcastMaterial(day:Int=-1, hour:Int=-1) {_exposeToLua}
		'if no news placed there already, just produce one live
		Local show:TBroadcastMaterial = GetObject(TVTBroadcastMaterialType.NEWSSHOW, day, hour)
		If Not show
			'only produce NOW
			if day = -1 or day = GetWorldTime().GetDay()
				if hour = -1 or hour = GetWorldTime().GetDayHour()
					show = ProduceNewsShow()
				endif
			endif
		endif
		Return show
	End Method


	'returns which number that given advertisement spot will have
	Method GetAdvertisementSpotNumber:Int(advertisement:TAdvertisement, viewType:int=-1) {_exposeToLua}
		'if programmed (as advertisement!) - count all non-failed ads
		'up to the programmed date
		If advertisement.isProgrammed() and (viewType < 0 or advertisement.usedAsType = viewType)
			Return 1 + GetAdvertisementsCount(advertisement.contract, advertisement.programmedDay, advertisement.programmedHour-1, True, True)
		'if not programmed we just count ALL existing non-failed ads
		Else
			Return 1 + GetAdvertisementsCount(advertisement.contract, -1, 0, True, True)
		EndIf
	End Method

	'that method could be externalized to "main.bmx" or another common
	'function, there is no need to place it in this file
	'
	'STEP 1/3: function fills current broadcast, does NOT calculate audience
	Method LogInCurrentBroadcast:TBroadcastMaterial(day:Int, hour:Int, minute:Int)
		Local obj:TBroadcastMaterial = Null

		'=== BEGIN OF NEWSSHOW ===
		If minute = 0
			obj = GetNewsShow()
			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj, TVTBroadcastMaterialType.NEWSSHOW)

			'adjust currently broadcasted block
			If obj then obj.currentBlockBroadcasting = GetObjectBlock(TVTBroadcastMaterialType.NEWSSHOW, day, hour)

			return obj
		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			obj = GetProgramme(day, hour)
			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj, TVTBroadcastMaterialType.PROGRAMME)

			'adjust currently broadcasted block
			If obj then obj.currentBlockBroadcasting = GetObjectBlock(TVTBroadcastMaterialType.PROGRAMME, day, hour)

			return obj
		'=== BEGIN OF ADVERTISEMENT ===
		ElseIf minute = 55
			obj = GetAdvertisement(day, hour)

			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj, TVTBroadcastMaterialType.ADVERTISEMENT)

			'adjust currently broadcasted block
			If obj then obj.currentBlockBroadcasting = GetObjectBlock(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)

			return obj
		EndIf
		return null
	End Method


	'STEP 2/3: calculate audience (for all players at once)
	Function CalculateCurrentBroadcastAudience:Int(day:Int, hour:Int, minute:Int)
		'=== BEGIN OF NEWSSHOW ===
		If minute = 0
			'calculate audience
			GetBroadcastManager().BroadcastNewsShow(day, hour)

		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			'calculate audience
			GetBroadcastManager().BroadcastProgramme(day, hour)

		'=== BEGIN OF ADVERTISEMENT ===
		ElseIf minute = 55
			'nothing to do yet
			'GetBroadcastManager().BroadcastAdvertisement(day, hour)
		EndIf
	End Function


	'STEP 3/3: inform broadcasts
	Method InformCurrentBroadcast:Int(day:Int, hour:Int, minute:Int)
		Local obj:TBroadcastMaterial = Null

		'=== BEGIN OF NEWSSHOW ===
		If minute = 0
			obj = GetNewsShow(day, hour)
			local eventKey:String = "broadcasting.common.BeginBroadcasting"

			Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
			If obj
				'inform news show that broadcasting started
				'(which itself informs the broadcasted news)
				obj.BeginBroadcasting(day, hour, minute, audienceResult)
			EndIf

			'store audience/broadcast for daily stats (if obj=null then outage)
			GetDailyBroadcastStatistic( day, true ).SetNewsBroadcastResult(obj, owner, hour, audienceResult)

			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.NEWSSHOW).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))

		'=== END OF NEWSSHOW ===
		ElseIf minute = 4
			obj = GetNewsShow(day, hour)
			local eventKey:String = "broadcasting.common.FinishBroadcasting"

			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				'inform news show that broadcasting ended
				'(which itself informs the broadcasted news)
				obj.FinishBroadcasting(day, hour, minute, audienceResult)
			EndIf
			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.NEWSSHOW).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))

		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			obj = GetProgramme(day, hour)
			local eventKey:String = "broadcasting.common.BeginBroadcasting"

			Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
			If obj
				'inform the object what happens (start or continuation)
				If 1 = GetProgrammeBlock(day, hour)
					obj.BeginBroadcasting(day, hour, minute, audienceResult)
					'eventKey = "broadcasting.begin"
				Else
					obj.ContinueBroadcasting(day, hour, minute, audienceResult)
					eventKey = "broadcasting.common.ContinueBroadcasting"
				EndIf
			EndIf
			'store audience/broadcast for daily stats (also for outage!)
			GetDailyBroadcastStatistic( day, true ).SetBroadcastResult(obj, owner, hour, audienceResult)

			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.PROGRAMME).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))

		'=== END/BREAK OF PROGRAMME ===
		'call-in shows/quiz - generate income
		ElseIf minute = 54
			obj = GetProgramme(day, hour)
			local eventKey:String = "broadcast.common.FinishBroadcasting"

			'inform object that it gets broadcasted
			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				If obj.GetBlocks() = GetProgrammeBlock(day, hour)
					If obj.FinishBroadcasting(day, hour, minute, audienceResult)
						'only for programmes:
						If TProgramme(obj)
							'refresh planned state (for next hour)
							RecalculatePlannedProgramme(TProgramme(obj), -1, hour+1)

							'removal of limited programme licences
							local licence:TProgrammeLicence = TProgramme(obj).licence
							if licence.isExceedingBroadcastLimit()

								if licence.HasLicenceFlag(TVTProgrammeLicenceFlag.SELL_ON_REACHING_BROADCASTLIMIT)
									GetPlayerProgrammeCollection(owner).RemoveProgrammeLicence(licence, True)
								elseif licence.HasLicenceFlag(TVTProgrammeLicenceFlag.REMOVE_ON_REACHING_BROADCASTLIMIT)
									GetPlayerProgrammeCollection(owner).RemoveProgrammeLicence(licence, False)
								else
									'just keep the now exceeded licence
									'(maybe it gets extended somehow)
								endif

								'remove _upcoming_ planned programmes with that licence
								RemoveProgrammeInstancesByLicence(licence, False)

								'inform others
								EventManager.triggerEvent(TEventSimple.Create("programmelicence.ExceedingBroadcastLimit", null, licence))
							endif
						EndIf
					EndIf
				Else
					obj.BreakBroadcasting(day, hour, minute, audienceResult)
					eventKey = "broadcast.common.BreakBroadcasting"
				EndIf
			EndIf
			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.PROGRAMME).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))

		'=== BEGIN OF COMMERCIAL BREAK ===
		ElseIf minute = 55
			obj = GetAdvertisement(day, hour)
			local eventKey:String = "broadcasting.common.BeginBroadcasting"

			Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)

			'inform  object that it gets broadcasted
			'convert audienceResult object of "last programme" to be
			'targeting the current advertisement/trailer
			local oldAudienceResult:TAudienceResult = audienceResult
			audienceResult = new TAudienceResult
			'copy (reference!) base things
			audienceResult.CopyFrom(oldAudienceResult)
			'reuse some values by directly linking to it
			audienceResult.AudienceAttraction = oldAudienceResult.AudienceAttraction
			audienceResult.competitionAttractionModifier = oldAudienceResult.competitionAttractionModifier

			'use advertisement instead of programme
			audienceResult.broadcastMaterial = obj

			if not obj
				audienceResult.broadcastOutage = True
			endif

			If obj
				If 1 = GetAdvertisementBlock(day, hour)
					obj.BeginBroadcasting(day, hour, minute, audienceResult)

					'computes ads - if adcontract finishes, earn money
					If TAdvertisement(obj) And TAdvertisement(obj).contract.isSuccessful()
						'removes ads which are more than needed (eg 3 of 2 to be shown ads)
						RemoveAdvertisementInstances(obj, False)
						'removes them also from programmes (shopping show)
						RemoveProgrammeInstances(obj, False)
'print "Finish advertisement " + day+"/" +hour+":"+minute
						'inform contract and earn money
						TAdvertisement(obj).contract.Finish( GetWorldTime().MakeTime(0, day, hour, minute) )

						'remove contract from collection (and suitcase)
						'contract is still stored within advertisements (until they get deleted)
						GetPlayerProgrammeCollection(owner).RemoveAdContract(TAdvertisement(obj).contract)

					'recalculate planned state for programmes of a trailer
					ElseIf TProgramme(obj)
						'refresh planned state (for next hour)
						RecalculatePlannedProgramme(TProgramme(obj), -1, hour+1)
					EndIf
					'eventKey = "broadcasting.begin"
				Else
					obj.ContinueBroadcasting(day, hour, minute, audienceResult)
					eventKey = "broadcasting.common.ContinueBroadcasting"
				EndIf
			EndIf
			'store audience/broadcast for daily stats (also for outage!)
			GetDailyBroadcastStatistic( day, true ).SetAdBroadcastResult(obj, owner, hour, audienceResult)

			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.ADVERTISEMENT).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))

		'=== END OF COMMERCIAL BREAK ===
		'ads end - so trailers can set their "ok"
		ElseIf minute = 59
			obj = GetAdvertisement(day, hour)
			local eventKey:String = "broadcast.common.FinishBroadcasting"

			'inform  object that it gets broadcasted
			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				If obj.GetBlocks() = GetAdvertisementBlock(day, hour)
					obj.FinishBroadcasting(day, hour, minute, audienceResult)
					'eventKey = "broadcasting.finish"
				Else
					obj.BreakBroadcasting(day, hour, minute, audienceResult)
					eventKey = "broadcast.common.BreakBroadcasting"
				EndIf
			EndIf
			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.ADVERTISEMENT).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))
		EndIf
	End Method


	'=== AUDIENCE ===
	'maybe move that helpers to TBroadcastManager


	'returns formatted value of actual audience
	Method GetFormattedAudience:String() {_exposeToLua}
		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
		If audienceResult Then return TFunctions.convertValue(audienceResult.audience.GetTotalSum(), 2)
		return "0"
	End Method


	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetAudiencePercentage:Float() {_exposeToLua}
		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
		If audienceResult Then Return audienceResult.GetAudienceQuotePercentage()

		Return 0
		'Local audienceResult:TAudienceResult = TAudienceResult.Curr(playerID)
		'Return audienceResult.MaxAudienceThisHour.GetSumFloat() / audienceResult.WholeMarket.GetSumFloat()
	End Method
End Type





'contains general information of all broadcasts in the programmeplans
'could contain broadcastmaterial-depending data
Type TProgrammePlanInformationProvider extends TProgrammePlanInformationProviderBase
	global _registeredEvents:int = False

	Function GetInstance:TProgrammePlanInformationProvider()
		if not _instance
			_instance = new TProgrammePlanInformationProvider

		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		elseif not TProgrammePlanInformationProvider(_instance)
			local provider:TProgrammePlanInformationProvider = new TProgrammePlanInformationProvider
			provider.DeserializeTProgrammePlanInformationProviderFromString( _instance.SerializeTProgrammePlanInformationProviderBaseToString() )

			'now the new provider is the instance
			_instance = provider
		endif
		return TProgrammePlanInformationProvider(_instance)
	End Function


	Method New()
		if not _registeredEvents
			EventManager.registerListenerFunction("broadcast.programme.FinishBroadcastingAsAdvertisement", onFinishBroadcasting)
			EventManager.registerListenerFunction("broadcast.programme.FinishBroadcasting", onFinishBroadcasting)
			EventManager.registerListenerFunction("broadcast.advertisement.FinishBroadcastingAsProgramme", onFinishBroadcasting)
			'EventManager.registerListenerFunction("broadcast.advertisement.FinishBroadcasting", onFinishBroadcasting)
			_registeredEvents = True
		endif
	End Method


	Method DeSerializeTProgrammePlanInformationProviderFromString(text:String)
		Super.DeSerializeTProgrammePlanInformationProviderBaseFromString(text)
	End Method


	Method SerializeTProgrammePlanInformationProviderToString:string()
		return Super.SerializeTProgrammePlanInformationProviderBaseToString()
	End Method


	Method RefreshProgrammeData(player:int, time:Long)
		local plan:TPlayerProgrammePlan = GetPlayerProgrammePlan(player)
		local programme:TProgramme = TProgramme(plan.GetProgramme(GetWorldTime().GetDay(time), GetWorldTime().GetDayHour(time)))
		'only interested in programmes
		if not programme then return

		'increase times a specific genre was broadcasted
		local genreKey:string = string(programme.data.GetGenre())
		programmeGenreAired[player].Insert(genreKey, string( int(string(programmeGenreAired[player].ValueForKey(genreKey))) + 1))
		if player <> 0
			programmeGenreAired[0].Insert(genreKey, string( int(string(programmeGenreAired[0].ValueForKey(genreKey))) + 1))
		endif
	End Method


	Method RefreshAudienceData(player:int, time:Long, audienceData:object)
		local audienceResult:TAudienceResult = TAudienceResult(audienceData)
		if not audienceResult then return

		local genreKey:string = ""
		if GetWorldTime().GetDayMinute(time) = 4 then genreKey = "newsshow"

		local programme:TProgramme = TProgramme(GetPlayerProgrammePlan(player).GetProgramme(GetWorldTime().GetDay(time), GetWorldTime().GetDayHour(time)))
		if programme then genreKey = string(programme.data.GetGenre())

		local audience:int = audienceResult.audience.GetTotalSum()
		if audience > int(string(audienceRecord[player].ValueForKey(genreKey)))
			audienceRecord[player].Insert(genreKey, string(audience))
			'save global record too
			if player <> 0
				audienceRecord[0].Insert(genreKey, string(audience))
			endif
		endif
	End Method


	'=== EVENT LISTENERS ===

	Function onFinishBroadcasting:Int(triggerEvent:TEventBase)
		local broadcast:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetSender())
		local data:TData = triggerEvent.GetData()
		local time:long = GetWorldTime().Maketime(0, data.GetInt("day"), data.GetInt("hour"), data.GetInt("minute"), 0)

		Select triggerEvent._trigger
			Case "broadcast.programme.FinishBroadcastingAsAdvertisement".ToLower()
				GetInstance().SetTrailerAired(broadcast.owner, GetInstance().GetTrailerAired(broadcast.owner) + 1, time)
			Case "broadcast.advertisement.FinishBroadcastingAsProgramme".ToLower()
				GetInstance().SetInfomercialsAired(broadcast.owner, GetInstance().GetInfomercialsAired(broadcast.owner) + 1, time)
				GetInstance().RefreshAudienceData(broadcast.owner, time, data.Get("audienceData"))
			Case "broadcast.programme.FinishBroadcasting".ToLower()
				GetInstance().RefreshProgrammeData(broadcast.owner, time)
				GetInstance().RefreshAudienceData(broadcast.owner, time, data.Get("audienceData"))
			Default
				print "onFinishBroadcasting: unhandled trigger - "+ triggerEvent._trigger
		End Select
	End Function

End Type


'register this provider so it listens to events
'-> overrides previous base-provider "TProgrammePlanInformationProviderBase"
GetGameInformationCollection().AddProvider("programmeplan", TProgrammePlanInformationProvider.GetInstance())


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammePlanInformationProvider:TProgrammePlanInformationProvider()
	Return TProgrammePlanInformationProvider.GetInstance()
End Function
