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
			EventManager.registerListenerFunction(GameEventKeys.Game_OnDay, onGameDay)
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

		if plans[playerID-1] and plans[playerID-1] <> plan
			'prepare old plan for removal
			plans[playerID-1].Reset()
		EndIf

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
	Field slotLocks:TIntMap = new TIntMap
	Field owner:Int

	Field _daysPlanned:int = -1 {nosave}
	Field _programmesMutex:TMutex
	Field _newsMutex:TMutex
	Field _newsShowMutex:TMutex
	Field _advertisementsMutex:TMutex
	Field _slotLockMutex:TMutex

	'FALSE to avoid recursive handling (network)
	Global fireEvents:Int = True

	Const LOCK_TYPE_COUNT:int = 5

	Const LOCK_TYPE_COMMON:int = 0
	Const LOCK_TYPE_TEMPORARY:int = 1
	Const LOCK_TYPE_THIRDPARTY:int = 2
	Const LOCK_TYPE_BOSS:int = 4
	Const LOCK_TYPE_GOVERNMENT:int = 8
	
	Global useMutexes:Int = False

	'===== COMMON FUNCTIONS =====
	
	Method New()
		_programmesMutex = CreateMutex()
		_newsMutex = CreateMutex()
		_newsShowMutex = CreateMutex()
		_advertisementsMutex = CreateMutex()
		_slotLockMutex = CreateMutex()
	End Method


	Method Create:TPlayerProgrammePlan(playerID:Int)
		Self.owner = playerID
		GetPlayerProgrammePlanCollection().Set(playerID, Self)
		Return Self
	End Method


	Method Reset()
		If useMutexes Then LockMutex(_programmesMutex)
		programmes = programmes[..0]
		If useMutexes Then UnlockMutex(_programmesMutex)

		If useMutexes Then LockMutex(_newsMutex)
		news = New TBroadcastMaterial[3]
		If useMutexes Then UnlockMutex(_newsMutex)

		If useMutexes Then LockMutex(_newsShowMutex)
		newsShow = newsShow[..0]
		If useMutexes Then UnlockMutex(_newsShowMutex)
		
		If useMutexes Then LockMutex(_advertisementsMutex)
		advertisements = advertisements[..0]
		If useMutexes Then UnlockMutex(_advertisementsMutex)

		'unregister events if any
	End Method


	Method Initialize:Int()
		Reset()

		'register events if any
	End Method


	Method GetSkipHoursFromIndex:Int()
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
		Print "=== AD/PROGRAMME PLAN PLAYER " + owner + " ==="
		For Local i:Int = 0 To Max(programmes.length - 1, advertisements.length - 1)
			Local currentHour:Int = GetHourFromArrayIndex(i) 'hours since start
			Local time:Long = GetWorldTime().MakeTime(0, 0, currentHour, 0)
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
				If progString = "" Then progString = "OUTAGE"
				If adString = "" Then adString = " -> AD OUTAGE"
				Print "[" + GetArrayIndex(int(time / TWorldTime.HOURLENGTH)) + "] " + GetWorldTime().GetYear(time) + " " + GetWorldTime().GetDayOfYear(time) + ".Tag " + GetWorldTime().GetDayHour(time) + ":00 : " + progString + adString
			EndIf
		Next
		Print "=== ----------------------- ==="
	End Method


	'adjusts given day and hour if eg. hour is negative or bigger than 23
	'eg. day=0 and hour=25 become day=1 and hour=1
	Function FixDayHour(day:int var, hour:int var, disableAutoValue:int = False)
		If day < 0 Then day = GetWorldTime().GetDay()
		If hour = -1 and not disableAutoValue
			hour = GetWorldTime().getDayHour()
		Else
			day :+ int(hour / 24)
			hour = hour mod 24
		EndIf
	End Function


	'adjusts day value if hour is <0 or >23
	Function WrapDayHour(day:int var, hour:int var)
		day :+ int(hour / 24)
		hour = hour mod 24
	End Function


	'===== common function for managed objects =====


	Method LockMutexObjectArray:TBroadcastMaterial[](slotType:Int=0)
		Select slotType
			Case TVTBroadcastMaterialType.PROGRAMME      If useMutexes Then LockMutex(_programmesMutex)
			Case TVTBroadcastMaterialType.ADVERTISEMENT  If useMutexes Then LockMutex(_advertisementsMutex)
			Case TVTBroadcastMaterialType.NEWS           If useMutexes Then LockMutex(_newsMutex)
			Case TVTBroadcastMaterialType.NEWSSHOW       If useMutexes Then LockMutex(_newsShowMutex)
			Default
				TLogger.Log("TPlayerProgrammePlan", "If useMutexes Then LockMutexObjectArray() request with unknown slotType "+slotType+".", LOG_DEBUG)
		End Select
	End Method


	Method UnlockMutexObjectArray:TBroadcastMaterial[](slotType:Int=0)
		Select slotType
			Case TVTBroadcastMaterialType.PROGRAMME      If useMutexes Then UnlockMutex(_programmesMutex)
			Case TVTBroadcastMaterialType.ADVERTISEMENT  If useMutexes Then UnlockMutex(_advertisementsMutex)
			Case TVTBroadcastMaterialType.NEWS           If useMutexes Then UnlockMutex(_newsMutex)
			Case TVTBroadcastMaterialType.NEWSSHOW       If useMutexes Then UnlockMutex(_newsShowMutex)
			Default
				TLogger.Log("TPlayerProgrammePlan", "UnlockMutexObjectArray() request with unknown slotType "+slotType+".", LOG_DEBUG)
		End Select
	End Method


	'Get the array of the requested slotType
	Method GetObjectArray:TBroadcastMaterial[](slotType:Int=0)
		Select slotType
			case TVTBroadcastMaterialType.PROGRAMME      Return programmes
			case TVTBroadcastMaterialType.ADVERTISEMENT  Return advertisements
			case TVTBroadcastMaterialType.NEWSSHOW       Return newsShow
			case TVTBroadcastMaterialType.NEWS           Return news
			Default 
				TLogger.Log("TPlayerProgrammePlan", "GetObjectArray() request with unknown slotType "+slotType+".", LOG_DEBUG)
				Return New TBroadcastMaterial[0]
		End Select
	End Method


	'sets the entry to the suiting array requested through slotType
	'this is needed as assigning to "getObjectArray"-arrays is not possible for now
	Method SetObjectArrayEntry:Int(obj:TBroadcastMaterial, slotType:Int=0, arrayIndex:Int)
		If arrayIndex < 0 Then Throw "[ERROR] SetObjectArrayEntry: arrayIndex is negative"
		
		Local arr:TBroadcastMaterial[]

		Select slotType
			Case TVTBroadcastMaterialType.PROGRAMME
				If useMutexes Then LockMutex(_programmesMutex)
				arr = programmes
			Case TVTBroadcastMaterialType.NEWS
				If useMutexes Then LockMutex(_newsMutex)
				arr = news
			Case TVTBroadcastMaterialType.NEWSSHOW
				If useMutexes Then LockMutex(_newsShowMutex)
				arr = newsShow
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				If useMutexes Then LockMutex(_advertisementsMutex)
				arr = advertisements
			Default
				Throw "TPlayerProgrammePlan.SetObjectArrayEntry() with unhandled slotType "+slotType+"."
		End Select

		'resize array if needed
		If arrayIndex >= arr.length
			'if obj is null, then we want to unset the entry
			'if the arrayIndex was never used before (in the future) we can
			'skip doing something if no obj was passed... 
			if obj
				'increase by "10" (or more if needed) to save some resizes
				Local newSize:Int = arrayIndex + 1 + Max(10, obj.GetBlocks() - 1)
				arr = arr[..newSize]
			EndIf
		EndIf

		'actually assign now
		arr[arrayIndex] = obj

		Select slotType
			Case TVTBroadcastMaterialType.PROGRAMME
				programmes = arr
				If useMutexes Then UnlockMutex(_programmesMutex)
			Case TVTBroadcastMaterialType.NEWS
				news = arr
				If useMutexes Then UnlockMutex(_newsMutex)
			Case TVTBroadcastMaterialType.NEWSSHOW
				newsShow = arr
				If useMutexes Then UnlockMutex(_newsShowMutex)
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				advertisements = arr
				If useMutexes Then UnlockMutex(_advertisementsMutex)
		End Select
		
		Return True
	End Method


	'Set a time slot locked
	'each lock is identifyable by "hours"
	Method LockSlot:int(slotType:int=0, day:int=-1, hour:int=-1, lockTypeFlags:int=0)
		FixDayHour(day, hour)

		Local key:Int = day*24 + hour
		Local createdNew:int
		'null if unset
		If useMutexes Then LockMutex(_slotLockMutex)
		Local currentLock:TSlotLockInfo = TSlotLockInfo(slotLocks.ValueForKey(key))
		If useMutexes Then UnlockMutex(_slotLockMutex)
		If Not currentLock
			currentLock = New TSlotLockInfo
			createdNew = True
		endIf

		'add new lockTypeFlags
		Select slotType
			case TVTBroadcastMaterialType.PROGRAMME
				currentLock.programmeLock :| lockTypeFlags
			case TVTBroadcastMaterialType.ADVERTISEMENT
				currentLock.adLock :| lockTypeFlags
			default
				currentLock.programmeLock :| lockTypeFlags
				currentLock.adLock :| lockTypeFlags
		End Select

		If createdNew
			If useMutexes Then LockMutex(_slotLockMutex)
			slotLocks.Insert(key, currentLock)
			If useMutexes Then UnlockMutex(_slotLockMutex)
		EndIf
	End Method


	Method UnlockSlot:int(slotType:int=0, day:int=-1, hour:int=-1, lockTypeFlags:int=0)
		FixDayHour(day, hour)

		Local key:Int = day*24 + hour
		'null if unset
		If useMutexes Then LockMutex(_slotLockMutex)
		Local currentLock:TSlotLockInfo = TSlotLockInfo(slotLocks.ValueForKey(key))
		If useMutexes Then UnlockMutex(_slotLockMutex)
		if not currentLock then Return False

		'remove lockTypeFlags
		Select slotType
			case TVTBroadcastMaterialType.PROGRAMME
				currentLock.programmeLock :& ~lockTypeflags
			case TVTBroadcastMaterialType.ADVERTISEMENT
				currentLock.adLock :& ~lockTypeflags
			default
				currentLock.programmeLock :& ~lockTypeflags
				currentLock.adLock :& ~lockTypeflags
		End Select
	End Method


	Method IsLockedSlot:int(slotType:Int = 0, day:Int=-1, hour:Int=-1)
		FixDayHour(day, hour)

		If useMutexes Then LockMutex(_slotLockMutex)
		Local currentLock:TSlotLockInfo = TSlotLockInfo(slotLocks.ValueForKey(day*24 + hour))
		If useMutexes Then UnlockMutex(_slotLockMutex)
		if not currentLock then Return False

		Select slotType
			case TVTBroadcastMaterialType.PROGRAMME
				Return currentLock.programmeLock > 0
			case TVTBroadcastMaterialType.ADVERTISEMENT
				Return currentLock.adLock > 0
			default
				Return currentLock.programmeLock > 0 or currentLock.adLock > 0
		End Select
	End Method


	'returns whether a slot is locked, or belongs to an object which
	'occupies at least 1 locked slot
	Method BelongsToLockedSlot:int(slotType:int=0, day:int=-1, hour:int=-1)
		FixDayHour(day, hour)

		local obj:TBroadcastMaterial = GetObject(slotType, day, hour)
		local hours:int = day*24 + hour
		if obj
			hours = obj.programmedDay*24 + obj.programmedHour
			For local blockHour:int = hours until hours + obj.GetBlocks()
				if IsLockedSlot(slotType, 0, blockHour)
					return True
				endif
			Next
			return False
		else
			return IsLockedSlot(slotType, day, hour)
		endif
	End Method


	'returns whether a slot is locked, or belongs to an object which
	'occupies at least 1 locked slot
	Method BelongsToModifiyableSlot:int(slotType:int=0, day:int=-1, hour:int=-1)
		FixDayHour(day, hour)

		local obj:TBroadcastMaterial = GetObject(slotType, day, hour)
		local hours:int = day*24 + hour
		if obj
			hours = obj.programmedDay*24 + obj.programmedHour
			For local blockHour:int = hours until hours + obj.GetBlocks()
				if not IsModifyableSlot(slotType, 0, blockHour)
					return False
				endif
			Next
			return True
		else
			return IsModifyableSlot(slotType, day, hour)
		endif
	End Method


	'helper function
	'returns whether the given material occupies a locked slot
	Method IsLockedBroadcastMaterial:int(broadcastMaterial:TBroadcastMaterial)
		if not broadcastMaterial then return False

		'for now we ignore owner checks - so every broadcastmaterial is just
		'checked if it occupies a locked slot

		'skip material not programmed yet
		if broadcastMaterial.programmedDay = -1 then return False
		for local block:int = 0 until broadcastMaterial.GetBlocks()
			if IsLockedSlot(broadcastMaterial.usedAsType, broadcastMaterial.programmedDay, broadcastMaterial.programmedHour + block)
				return True
			endif
		Next
		return False
	End Method


	'removes slot lock info from past days (to keep things small sized)
	Method RemoveObsoleteSlotLocks:int()
		local time:Long = GetWorldTime().GetDay()*24 ' + 0 hours, start at midnight)

		If useMutexes Then LockMutex(_slotLockMutex)
		Local toRemove:int[]
		For local k:TIntKey = EachIn slotLocks.Keys()
			if k.value < time
				toRemove :+ [k.value]
			else
				'as the keys are sorted by time we could skip all others
				'once we reached a lock of the present/future
				exit
			endif
		Next

		For local key:Int = EachIn toRemove
			slotLocks.Remove(key)
		Next
		If useMutexes Then UnlockMutex(_slotLockMutex)

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
	Method IsModifyableSlot:int(slotType:int=0, day:int=-1, hour:int=-1, currentDay:Int=-1, currentHour:Int=-1, currentMinute:Int=-1)
		if not IsUseableTimeSlot(slotType, day, hour, currentDay, currentHour, currentMinute) then return False
		if BelongsToLockedSlot(slotType, day, hour) then return False
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
		'if the hour is in the past, the slot MUST be NOT useable
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
		Local result:TBroadcastMaterial

		If useMutexes Then LockMutexObjectArray(objectType)
		Local array:TBroadcastMaterial[] = GetObjectArray(objectType)
		If arrayIndex > 0 And array.length > arrayIndex
			result = array[arrayIndex]
		EndIf
		If useMutexes Then UnlockMutexObjectArray(objectType)
		Return result
	End Method


	Method GetObject:TBroadcastMaterial(slotType:Int=0, day:Int=-1, hour:Int=-1)
		If useMutexes Then LockMutexObjectArray(slotType)
		Local startHour:Int = GetObjectStartHour(slotType, day, hour)
		Local result:TBroadcastMaterial
		If startHour >= 0
			result = GetObjectAtIndex(slotType, GetArrayIndex(startHour))
		EndIf
		If useMutexes Then UnlockMutexObjectArray(slotType)
		Return result
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
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(objectType)

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

			result :+ [material]
		Next

		If useMutexes Then UnlockMutexObjectArray(objectType)
		Return result
	End Method


	'returns an array of broadcastmaterials (or NULLs) for each slot
	'in the given timespan
	Method GetObjectSlotsInTimeSpan:TBroadcastMaterial[](objectType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(objectType)

		'loop through the given range
		Local minIndex:Int = GetArrayIndex(dayStart*24 + hourStart)
		Local maxIndex:Int = GetArrayIndex(dayEnd*24 + hourEnd)
		if maxIndex - minIndex < 0 then return Null

		Local result:TBroadcastMaterial[] = new TBroadcastMaterial[ maxIndex-minIndex +1 ]
		For Local i:Int = minIndex To maxIndex
			result[i-minIndex] = GetObject(objectType, 0, GetHourFromArrayIndex(i))
		Next

		If useMutexes Then UnlockMutexObjectArray(objectType)
		Return result
	End Method


	'returns whether an object exists in the time span
	'if so - the first (or last) material-instance is returned
	Method ObjectPlannedInTimeSpan:TBroadcastMaterial(material:TBroadcastMaterial, slotType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, startAtLatestTime:Int=False) {_exposeToLua}
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(slotType)

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

		'materials might differ from each other
		'instead of comparing objects we compare their content
		Local result:TBroadcastMaterial
		If not startAtLatestTime
			For Local i:Int = minIndex To maxIndex
				Local obj:TBroadcastMaterial = TBroadcastMaterial(GetObjectAtIndex(slotType, i))
				If Not obj Then Continue
				If material.GetReferenceID() = obj.GetReferenceID() 
					result = obj
					exit
				EndIf
			Next
		Else
			For Local i:Int = maxIndex To minIndex Step -1
				Local obj:TBroadcastMaterial = TBroadcastMaterial(GetObjectAtIndex(slotType, i))
				If Not obj Then Continue
				If material.GetReferenceID() = obj.GetReferenceID() 
					result = obj
					exit
				EndIf
			Next
		EndIf

		If useMutexes Then UnlockMutexObjectArray(slotType)
		Return result
	End Method


	'return the lastest hour (since game start) a given broadcast material
	'so TProgrammelicence, TAdContract, ...) is scheduled to start (block 1!)
	Method GetObjectLatestStartHour:Int(material:TBroadcastMaterial, slotType:int, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourend:int=-1)
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		local latestInstance:TBroadcastMaterial = ObjectPlannedInTimeSpan(material, slotType, dayStart, hourStart, dayEnd, hourEnd, True)
		If latestInstance Then return latestInstance.programmedDay*24 + latestInstance.programmedHour
		return -1
	End Method


	'return the earliest hour (since game start) a given broadcast material
	'so TProgrammelicence, TAdContract, ...) is scheduled to start (block 1!)
	Method GetObjectEarliestStartHour:Int(material:TBroadcastMaterial, slotType:int, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourend:int=-1)
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		local firstInstance:TBroadcastMaterial = ObjectPlannedInTimeSpan(material, slotType, dayStart, hourStart, dayEnd, hourEnd, False)
		If firstInstance Then return firstInstance.programmedDay*24 + latestInstance.programmedHour
		return -1
	End Method


	'returns the amount of source-users in the time span
	Method GetBroadcastMaterialSourceProgrammedCountInTimeSpan:int(materialSource:TBroadcastMaterialSource, slotType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		FixDayHour(dayStart, hourStart)
		FixDayHour(dayEnd, hourEnd)

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(slotType)

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
			Local obj:TBroadcastMaterial = GetObjectAtIndex(slotType, i)
			If Not obj Then Continue
			If materialSource = obj.GetSource() Then result :+ 1
		Next

		If useMutexes Then UnlockMutexObjectArray(slotType)
		Return result
	End Method


	'returns the hour a object at the given time slot really starts
	'attention: that is not a gamedayHour from 0-24 but in hours since day0
	'returns -1 if no object was found
	Method GetObjectStartHour:Int(objectType:Int=0, day:Int=-1, hour:Int=-1) {_exposeToLua}
		FixDayHour(day, hour)
		Local arrayIndex:Int = GetArrayIndex(day*24 + hour)
		'out of bounds?
		If arrayIndex < 0 Then Return -1

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(objectType)

		Local array:TBroadcastMaterial[] = GetObjectArray(objectType)
		Local result:Int = -1

		'check if the current hour is the start of an object
		'-> saves further requests (like GetBlocks() )
		If arrayIndex < array.length And array[arrayIndex] 
			result = GetHourFromArrayIndex(arrayIndex)
		Else
			'search the past for the previous programme
			'then check if start+blocks is still our time
			Local searchIndex:Int = arrayIndex
			While searchIndex >= 0
				If searchIndex < array.length And array[searchIndex]
					If searchIndex + TBroadcastMaterial(array[searchIndex]).GetBlocks() - 1 >= arrayIndex
						result = GetHourFromArrayIndex(searchIndex)
					Else
						result = -1
					EndIf
					exit
				EndIf
				searchIndex:-1
			Wend
		EndIf

		If useMutexes Then UnlockMutexObjectArray(objectType)
		Return result
	End Method


hier weiter... aufraeumen
... und schauen, welche Events wirklich gebraucht werden,
und inwieweit "erstmal" sowas wie "TriggerNetworkEvent" ("stub"-Funktion mit Gameevent...)
hinzugefuegt werden sollte - das wuerde dann spaeter bei "commands" ja eh wegfallen...


	'add an object / set a slot occupied
	Method AddObject:Int(obj:TBroadcastMaterial, slotType:Int=0, day:Int=-1, hour:Int=-1, checkModifyableSlot:Int=True)
		FixDayHour(day, hour)
		If Not obj Then Return False
		'do not allow adding objects we do not own
		If obj.GetOwner() <> owner Then Return False
		'do not allow adding objects we cannot control
		If not obj.IsControllable() then Return False
		'do not allow adding objects which are not available now
		'(eg. exceeded broadcast limit)
		If obj.GetSource()
			if not obj.GetSource().IsAvailable() then Return False
		EndIf

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(slotType)

		Local arrayIndex:Int = GetArrayIndex(day*24 + hour)

		'the same object is at the exact same slot - skip actions/events
		If obj <> GetObjectAtIndex(slotType, arrayIndex)
			'check all affected slots whether they allow modification
			'do not allow adding in the past
			'do not allow adding to a locked slot
			If checkModifyableSlot
				if not BelongsToModifiyableSlot(slotType, day, hour)
					'TLogger.Log("TPlayerProgrammePlan.AddObject", "Failed: slot (type="+slotType+", day="+day+", hour="+hour+") cannot get modified - belongs to not-modifyable broadcast. GameTime:" + GetWorldTime().GetFormattedTime(), LOG_INFO)
					If useMutexes Then UnlockMutexObjectArray(slotType)
					return False
				endif

				For Local i:Int = 0 To obj.GetBlocks(slotType) -1
					if Not IsModifyableSlot(slotType, day, hour + i)
						'TLogger.Log("TPlayerProgrammePlan.AddObject", "Failed: slot (type="+slotType+", day="+day+", hour="+hour+", block="+i+", blockHour="+(hour+i)+") cannot get modified - is in the past or locked. GameTime:" + GetWorldTime().GetFormattedTime(), LOG_INFO)
						If useMutexes Then UnlockMutexObjectArray(slotType)
						Return False
					endif
				Next
			EndIf


			'clear all potential overlapping objects
			Local removedObjects:Object[]
			Local removedObject:Object
			For Local i:Int = 0 To obj.GetBlocks(slotType) -1
				removedObject = RemoveObject(slotType, day, hour+i, checkModifyableSlot)
				If removedObject then removedObjects :+ [removedObject]
			Next

			'add the object to the corresponding array
			SetObjectArrayEntry(obj, slotType, arrayIndex)
			obj.programmedDay = day
			obj.programmedHour = hour
			'assign "used as type"
			obj.setUsedAsType(slotType)


			Local programme:TProgramme = TProgramme(obj)
			Local advertisement:TAdvertisement = TAdvertisement(obj)

			'special for programmelicences: set a maximum planned time
			'setting does not require special calculations
			If programme
				'updated "latest planned hour"
				programme.licence.SetPlanned(day*24+hour+obj.GetBlocks(slotType))
				'ProgrammeLicences: recalculate the latest planned hour
				RecalculatePlannedProgramme(programme)
			EndIf
			
			'Advertisements: adjust planned (when placing in contract-slot
			If slotType = TVTBroadcastMaterialType.ADVERTISEMENT and advertisement
				advertisement.contract.SetSpotsPlanned( GetAdvertisementsPlanned(advertisement.contract, advertisement.contract.daySigned, 0, -1, -1) )
			EndIf

			'if slotType = TVTBroadcastMaterialType.ADVERTISEMENT
				'TLogger.Log("PlayerProgrammePlan.AddObject()", "Plan #"+owner+" added object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") to ADVERTISEMENTS, index="+arrayIndex+", day="+day+", hour="+hour+". Removed "+removedObjects.length+" objects before.", LOG_DEBUG)
			'else
				'TLogger.Log("PlayerProgrammePlan.AddObject()", "Plan #"+owner+" added object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") to PROGRAMMES, index="+arrayIndex+", day="+day+", hour="+hour+". Removed "+removedObjects.length+" objects before.", LOG_DEBUG)
			'endif

			'invalidate cache
			_daysPlanned = -1

			SendNotificationEvent(GameEventKeys.ProgrammePlan_AddObject, New TData.add("object", obj).add("removedObjects", removedObjects).addInt("slotType", slotType).addInt("day", day).addInt("hour", hour), Self)
		EndIf

		If useMutexes Then UnlockMutexObjectArray(slotType)
		Return True
	End Method




	Method RemoveObject:Object(slotType:Int=0, day:Int=-1, hour:Int=-1, checkModifyableSlot:int=True)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(slotType)

		Local obj:TBroadcastMaterial = GetObject(slotType, day, hour)
		Local removedObject:Object = RemoveObject(slotType, obj, checkModifyableSlot)

		If useMutexes Then UnlockMutexObjectArray(slotType)
		Return removedObject
	End Method


	'remove object from slot / clear a slot
	'returns the deleted object if one is found
	Method RemoveObject:Object(slotType:Int=0, obj:TBroadcastMaterial, checkModifyableSlot:int=True)
		If Not obj Then Return Null
		
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(slotType)

		'do not allow removing objects we cannot control
		'(to forcefully remove it, unset that flag before!)
		If Not obj.IsControllable() 
			If useMutexes Then UnlockMutexObjectArray(slotType)
			Return Null
		EndIf

		'if not programmed, skip deletion and events
		If Not obj.IsProgrammed() 
			TLogger.Log("PlayerProgrammePlan.RemoveObject()", "Plan #"+owner+" SKIPPED removal of object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") from " + TVTBroadcastMaterialType.GetAsString(slotType).ToUpper() + " - not programmed.", LOG_DEBUG)
			If useMutexes Then UnlockMutexObjectArray(slotType)
			Return obj
		EndIf


		'backup programmed date for event
		Local programmedDay:Int = obj.programmedDay
		Local programmedHour:Int = obj.programmedHour

		If checkModifyableSlot
			For Local i:Int = 0 To obj.GetBlocks(slotType) -1
				if Not IsModifyableSlot(slotType, programmedDay, programmedHour + i)
					Local nowDay:Int = programmedDay
					Local nowHour:Int = programmedHour + i
					FixDayHour(nowDay, nowHour)
					TLogger.Log("TPlayerProgrammePlan.RemoveObject", "Failed: slot (type="+slotType+", day="+nowDay+", hour="+nowHour+", block="+i+" cannot get modified - is in the past or locked", LOG_INFO)
					If useMutexes Then UnlockMutexObjectArray(slotType)
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
		If TProgramme(obj)
			RecalculatePlannedProgramme(TProgramme(obj))
		'Advertisements: adjust planned amount
		ElseIf TAdvertisement(obj)
			Local advertisement:TAdvertisement = TAdvertisement(obj)
			advertisement.contract.SetSpotsPlanned( GetAdvertisementsPlanned(advertisement.contract, advertisement.contract.daySigned, 0, -1, -1) )
		EndIf

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
		If fireEvents
			TriggerBaseEvent(GameEventKeys.ProgrammePlan_RemoveObject, New TData.add("object", obj).addNumber("slotType", slotType).addNumber("day", programmedDay).addNumber("hour", programmedHour), Self)
		Endif

		If useMutexes Then UnlockMutexObjectArray(slotType)
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

		'TLogger.Log("PlayerProgrammePlan.RemoveObjectInstances()", "Plan #"+owner+" removes all instances of object ~q"+obj.GetTitle()+"~q (owner="+obj.owner+") from " + TVTBroadcastMaterialType.GetAsString(slotType).ToUpper() + ".", LOG_DEBUG)

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(slotType)

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
					RemoveObject(slotType, 0, GetHourFromArrayIndex(i+j), not removeCurrentRunning)
					'method b) just clear the array at the given index
					'SetObjectArrayEntry(null, slotType, GetHourFromArrayIndex(i+j))
				Next
				foundAnInstance = True
			EndIf
		Next

		If foundAnInstance and fireEvents 
			TriggerBaseEvent(GameEventKeys.ProgrammePlan_RemoveObjectInstances, New TData.add("object", obj).addNumber("slotType", slotType).addNumber("removeCurrentRunning", removeCurrentRunning), Self)
		Endif

		If useMutexes Then UnlockMutexObjectArray(slotType)
		Return foundAnInstance
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

		'check live programme or potential time slot limits
		if not obj.GetSource().CanStartBroadcastAtTime(slotType, day, hour)
			return -1
		endif

		
		'check all slots the obj will occupy if there is something else
		'is there already
		Local existingAtBlock:Int = - 1
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(slotType)
		For Local i:Int = 0 To obj.GetBlocks() - 1
			If GetObject(slotType, day, hour + i) 
				existingAtBlock = i
				exit
			Endif
		Next
		If useMutexes Then UnlockMutexObjectArray(slotType)

		if existingAtBlock >= 0 Then Return -2
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
				RemoveProgramme(b.programmedDay, b.programmedHour)
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


	'Removes all not-yet-run users of the given programme licence from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveProgrammeInstancesByLicence:Int(licence:TProgrammeLicence, removeCurrentRunning:Int=False)
		'Maybe we got a collection/series - so revoke all sublicences
		If licence.GetSubLicenceSlots() > 0
			'avoid others manipulating the collection meanwhile
			If useMutexes Then LockMutex(_programmesMutex)
			For Local subLicence:TProgrammeLicence = EachIn licence.subLicences
				RemoveProgrammeInstancesByLicence(subLicence, removeCurrentRunning)
			Next
			If useMutexes Then UnlockMutex(_programmesMutex)
			Return True
		EndIf

		'first of all we need to find a user of our licence
		'read: find a programme which uses the licence
		'loop other all potential slot types so to find programmes
		'which are not planned, but eg. promoted by trailers
		local slotTypes:int[] = [TVTBroadcastMaterialType.PROGRAMME, TVTBroadcastMaterialType.ADVERTISEMENT]
		Local programme:TBroadcastMaterial
		Local currentHour:Int = GetWorldTime().GetHour()

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_programmesMutex)
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

		Local result:Int = True
		If programme Then result = RemoveProgrammeInstances(programme, removeCurrentRunning)

		If useMutexes Then UnlockMutex(_programmesMutex)
		Return result
	End Method


	'Removes all not-yet-run instances of the given programme from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveProgrammeInstances:Int(obj:TBroadcastMaterial, removeCurrentRunning:Int=False)
		Local doneSomething:Int=False
		Local programme:TBroadcastMaterial

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_programmesMutex)

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
		If useMutexes Then UnlockMutex(_programmesMutex)


		'also remove from advertisement slots (Trailers)
		If RemoveObjectInstances(obj, TVTBroadcastMaterialType.ADVERTISEMENT, -1, removeCurrentRunning)
			doneSomething = True
		EndIf

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


	'reset that programmed programme
	Method RemoveProgramme:Int(obj:TBroadcastMaterial, checkModifyableSlot:Int=True)
		'try to remove the object from the array
		Local result:Object = RemoveObject(TVTBroadcastMaterialType.PROGRAMME, obj, checkModifyableSlot)
		If result then 
			Return True
		Else
			Return False
		EndIf
	End Method

	'reset that slot
	Method RemoveProgramme:Int(day:Int=-1, hour:Int=-1, checkModifyableSlot:Int=True)
		'try to remove the object from the array
		Local result:Object = RemoveObject(TVTBroadcastMaterialType.PROGRAMME, day, hour, checkModifyableSlot)
		If result
			Return True
		Else
			Return False
		EndIf
	End Method
	

	'Add a used-as-programme to the player's programme plan
	Method AddProgramme:Int(obj:TBroadcastMaterial, day:Int=-1, hour:Int=-1)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_programmesMutex)

		'check if we are allowed to place it there
		'for now, only skip if failing live programme or time slot fails (-1)
		'- if also interested in "other programme on slots", this is -2
		If ProgrammePlaceable(obj, day, hour) = -1 
			If useMutexes Then UnlockMutex(_programmesMutex)
			Return False
		EndIf

		Local result:Int = AddObject(obj, TVTBroadcastMaterialType.PROGRAMME, day, hour)

		If useMutexes Then UnlockMutex(_programmesMutex)
		Return result
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

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutexObjectArray(slotType)

		'only programmes with more than 1 block can start the day before
		'and still run the next day - so we have to check that too
		If includeStartedYesterday
			'we just compare the programme started 23:00 or earlier the day before
			material = GetObject(slotType, day - 1, 23)
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
		If useMutexes Then UnlockMutexObjectArray(slotType)

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

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_advertisementsMutex)

		Local result:Int = -1
		'loop through the given range
		For Local i:Int = maxIndex To minIndex Step -1
			Local obj:TAdvertisement = TAdvertisement(GetObjectAtIndex(TVTBroadcastMaterialType.ADVERTISEMENT, i))
			If Not obj Then Continue
			If obj.contract = contract 
				result = obj.programmedDay*24 + obj.programmedHour
				exit
			EndIf
		Next
		If useMutexes Then UnlockMutex(_advertisementsMutex)
		
		return result
	End Method


	Method GetAdvertisementBlock:Int(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObjectBlock(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)
	End Method


'unused for now
rem
	'returns how many times an contract was programmed since signing the contract
	'start time: contract sign
	'end time: day +/- hour (if day > -1)
	Method GetAdvertisementsSent:Int(contract:TAdContract, day:Int=-1, hour:Int=-1, onlySuccessful:Int=False) {_exposeToLua}
		if not contract then return 0
		FixDayHour(day, hour)
		Return GetAdvertisementsCount(contract, contract.daySigned, 0, day, hour, True, False)
	End Method
endrem

	Method GetTotalAdvertisementsPlanned:Int(contract:TAdContract, includeSuccessful:Int=True) {_exposeToLua}
		return GetAdvertisementsPlanned(contract, contract.daySigned, 0, -1, -1, includeSuccessful)
	End Method


	'dayEnd=-1 and dayHour=-1 means "total"
	Method GetAdvertisementsPlanned:Int(contract:TAdContract, dayStart:Int, hourStart:Int, dayEnd:Int=1, hourEnd:Int=-1, includeSuccessful:Int=True) {_exposeToLua}
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_advertisementsMutex)

		Local minIndex:Int = 0
		Local maxIndex:Int = advertisements.length - 1

		WrapDayHour(dayStart, hourStart)
		minIndex = GetArrayIndex(dayStart*24 + hourStart)

		if dayEnd <> -1 and hourEnd <> -1
			WrapDayHour(dayEnd, hourEnd)
			maxIndex = min(maxIndex, GetArrayIndex(dayEnd*24 + hourEnd))
		endif

		'somehow we have a timeframe ending earlier than starting
		If maxIndex < minIndex 
			If useMutexes Then UnlockMutex(_advertisementsMutex)
			Return 0
		EndIf

		Local count:Int	= 0
		For Local i:Int = minIndex To maxIndex
			Local ad:TAdvertisement = TAdvertisement(advertisements[i])
			'skip missing or wrong ads
			If Not ad Or ad.contract <> contract Then Continue
			'skip failed
			If ad.isState(ad.STATE_FAILED) Then Continue
			'skip sent ads if wanted
			If Not includeSuccessful And ad.isState(ad.STATE_OK) Then Continue

			count:+1
		Next
		If useMutexes Then UnlockMutex(_advertisementsMutex)
		Return count
	End Method



	'returns how many times advertisements of an adcontract were sent/planned...
	'
	'start day = -1 then use contract sign day
	Method GetAdvertisementsCount:Int(contract:TAdContract, dayStart:Int, hourStart:Int, dayEnd:Int, hourEnd:Int, onlySuccessful:Int=True, includePlanned:Int=False)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_advertisementsMutex)

		WrapDayHour(dayStart, hourStart)
		WrapDayHour(dayEnd, hourEnd)

		Local startIndex:Int= Max(0, GetArrayIndex( dayStart*24 + hourStart ))
		'end with latest planned element
		Local endIndex:Int = Min(advertisements.length-1, GetArrayIndex(dayEnd*24 + hourEnd))
		'somehow we have a timeframe ending earlier than starting
		If endIndex < startIndex
			If useMutexes Then UnlockMutex(_advertisementsMutex)
			Return 0
		EndIf

		Local count:Int	= 0
		For Local i:Int = startIndex To endIndex
			Local ad:TAdvertisement = TAdvertisement(advertisements[i])
			'skip missing or wrong ads
			If Not ad Or ad.contract <> contract Then Continue

			If onlySuccessful And ad.isState(ad.STATE_FAILED) Then Continue
			If Not includePlanned And ad.isState(ad.STATE_NORMAL) Then Continue

			count:+1
		Next
		If useMutexes Then UnlockMutex(_advertisementsMutex)

		Return count
	End Method


	'clear a slot so others can get placed without trouble
	Method RemoveAdvertisement:Int(obj:TBroadcastMaterial=Null, day:Int=-1, hour:Int=-1) {_exposeToLua}
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_advertisementsMutex)
		Local result:Object

		If Not obj Then obj = GetObject(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)
		If obj
			'try to remove the object from the array
			result = RemoveObject(TVTBroadcastMaterialType.ADVERTISEMENT, obj)
		EndIf
		If useMutexes Then UnlockMutex(_advertisementsMutex)
		
		If result
			Return True
		Else
			Return False
		EndIf
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



	'reset that programmed advertisement
	Method RemoveAdvertisement:Int(obj:TBroadcastMaterial, checkModifyableSlot:Int=True)
		'try to remove the object from the array
		Local result:Object = RemoveObject(TVTBroadcastMaterialType.ADVERTISEMENT, obj, checkModifyableSlot)
		If result then 
			Return True
		Else
			Return False
		EndIf
	End Method

	'reset that slot
	Method RemoveAdvertisement:Int(day:Int=-1, hour:Int=-1, checkModifyableSlot:Int=True)
		'try to remove the object from the array
		Local result:Object = RemoveObject(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour, checkModifyableSlot)
		If result
			Return True
		Else
			Return False
		EndIf
	End Method
	

	'Fill/Clear the given advertisement slot with the given broadcast material
	Method AddAdvertisement:Int(obj:TBroadcastMaterial, day:Int=-1, hour:Int=-1)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_advertisementsMutex)
		'check if we are allowed to place it there
		'ATTENTION: check for -1 as "-2" means there is another
		'           broadcastmaterial at the desired slot
		If AdvertisementPlaceable(obj, day, hour) = -1 
			If useMutexes Then UnlockMutex(_advertisementsMutex)
			Return False
		EndIf

		'add it
		Local result:Int = AddObject(obj, TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)

		If useMutexes Then UnlockMutex(_advertisementsMutex)
		Return result
	End Method


	'Returns whether a programme can be placed at the given day/time
	Method AdvertisementPlaceable:Int(obj:TBroadcastMaterial, day:Int=-1, hour:int=-1)
		Return ObjectPlaceable(obj, TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)
	End Method


'unused for now
rem
	'returns the next number a new ad spot will have (counts all existing non-failed ads + 1)
	Method GetNextAdvertisementSpotNumber:Int(contract:TAdContract) {_exposeToLua}
		if not contract then return 1
		if GetWorldTime().GetDayMinute() >= 55
			Return 1 + GetAdvertisementsCount(contract, contract.daySigned, 0, GetWorldTime().GetDay(), GetWorldTime().GetDayHour(), True, True)
		else
			Return 1 + GetAdvertisementsCount(contract, contract.daySigned, 0, GetWorldTime().GetDay(), GetWorldTime().GetDayHour()-1, True, True)
		endif
	End Method
endrem


	'===== NEWS FUNCTIONS =====

    Method SetNewsByGUID:Int(newsGUID:string, slot:Int)
		'use RemoveNews() to unset a news
		If not newsGUID then return False

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_advertisementsMutex)
		local news:TNews = GetPlayerProgrammeCollection(owner).GetNews(newsGUID)
		Local result:Int
		if not news
			result = False
		Else
			result = SetNews(news, slot)
		EndIf
		If useMutexes Then UnlockMutex(_newsMutex)

		Return result
	End Method


	'set the slot of the given newsblock
	'if not paid yet, it will only continue if pay is possible
    Method SetNews:Int(newsObject:TNews, slot:Int) {_exposeToLua}
		'use RemoveNews() to unset a news
		If not newsObject then return False

		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		'out of bounds check
		If slot < 0 Or slot >= news.length
			If useMutexes Then UnlockMutex(_newsMutex)
			Return False
		EndIf

		'do not continue if pay not possible but needed
		If Not newsObject.Pay() 
			If useMutexes Then UnlockMutex(_newsMutex)
			Return False
		EndIf

		'if just dropping on the own slot ...do nothing
		If news[slot] = newsObject 
			If useMutexes Then UnlockMutex(_newsMutex)
			Return True
		EndIf

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
		If fireEvents 
			TriggerBaseEvent(GameEventKeys.ProgrammePlan_SetNews, New TData.Add("news",newsObject).AddNumber("slot", slot), self)
		EndIf
		
		If useMutexes Then UnlockMutex(_newsMutex)
		Return True
    End Method


	Method RemoveNewsBySlot:Int(slot:Int, addToCollection:Int=True) {_exposeToLua}
		return RemoveNews(null, slot, addToCollection)
	End Method


	Method RemoveNewsByID:Int(newsID:Int, addToCollection:Int=True)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		Local result:Int
		For Local i:Int = 0 To news.length-1
			If not TNews(news[i]) Then Continue
			If not news[i].GetID() = newsID
				result = RemoveNews(TNews(news[i]), i, addToCollection)
				exit
			EndIf
		Next
		
		If useMutexes Then UnlockMutex(_newsMutex)
		Return result
	End Method


	'Remove the news from the plan
	'by default the news gets added back to the collection, this can
	'be controlled with the third param "addToCollection"
	Method RemoveNews:Int(newsObject:TNews=null, slot:Int=-1, addToCollection:Int=True) {_exposeToLua}
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		Local newsSlot:Int = slot
		'try to find the slot occupied by the news
		If newsObject and slot < 0
			For Local i:Int = 0 To news.length-1
				local news:TBroadcastMaterial = GetNewsAtIndex(i)
				If news = newsObject 
					newsSlot = i
					Exit
				EndIf
			Next
		EndIf

		'was the news planned (-> in a slot) ?
		Local result:Int
		Local plannedNews:TBroadcastMaterial = GetNewsAtIndex(newsSlot)
		if plannedNews
			'add that news back to the collection ?
			If addToCollection and TNews(plannedNews)
				GetPlayerProgrammeCollection(owner).AddNews(TNews(plannedNews))
			EndIf

			'empty the slot
			news[newsSlot] = Null

			If fireEvents 
				TriggerBaseEvent(GameEventKeys.ProgrammePlan_RemoveNews, New TData.Add("news", plannedNews).AddNumber("slot", newsSlot), self)
			Endif

			result = True
		Else
			result = False
		EndIf

		If useMutexes Then UnlockMutex(_newsMutex)

		Return result
	End Method


	Method HasNewsEvent:Int(newsEvent:TNewsEvent)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		Local result:Int
		For local newsEntry:TNews = EachIn news
			If newsEntry.GetNewsEvent() = newsEvent 
				result = True
				exit
			EndIf
		Next

		If useMutexes Then UnlockMutex(_newsMutex)

		Return result
	End Method


	Method HasNewsEventID:Int(newsEventID:Int)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		Local result:Int
		For local newsEntry:TNews = EachIn news
			If newsEntry.GetNewsEvent().GetID() = newsEventID 
				result = True
				exit
			EndIf
		Next

		If useMutexes Then UnlockMutex(_newsMutex)

		Return result
	End Method


	Method HasNews:Int(news:TBroadcastMaterial)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		Local result:Int
		For local newsEntry:TBroadcastMaterial = EachIn self.news
			If newsEntry = news 
				result = True
				exit
			EndIf
		Next

		If useMutexes Then UnlockMutex(_newsMutex)

		Return result
	End Method


	Method HasNews:Int(newsID:Int)
		Return GetNews(newsID) <> Null
	End Method



	Method GetNews:TBroadcastMaterial(newsID:Int)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		Local result:TBroadcastMaterial
		For local newsEntry:TBroadcastMaterial = EachIn news
			If newsEntry.GetID() = newsID 
				result = newsEntry
				exit
			EndIf
		Next
		
		If useMutexes Then UnlockMutex(_newsMutex)

		Return result
	End Method


	Method GetNewsByGUID:TBroadcastMaterial(newsGUID:String)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		Local result:TBroadcastMaterial
		For local newsEntry:TBroadcastMaterial = EachIn news
			If newsEntry.GetGUID() = newsGUID 
				result = newsEntry
				exit
			EndIf
		Next
		
		If useMutexes Then UnlockMutex(_newsMutex)

		Return result
	End Method


	'use this when passing all entries to LUA (copy to avoid modification)
	Method GetNewsArrayCopy:TBroadcastMaterial[]()
		Return news[ .. ]
	End Method


	Method GetNewsAtIndex:TBroadcastMaterial(index:Int)
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		Local result:TBroadcastMaterial
		If index >= 0 and index < news.length 
			result = news[index]
		EndIf
		
		If useMutexes Then UnlockMutex(_newsMutex)
		
		Return result
	End Method


	Method ProduceNewsShow:TBroadcastMaterial()
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsMutex)

		Local news1:TBroadcastMaterial = GetNewsAtIndex(0)
		Local news2:TBroadcastMaterial = GetNewsAtIndex(1)
		Local news3:TBroadcastMaterial = GetNewsAtIndex(2)
		Local show:TNewsShow = TNewsShow.Create("News show " + GetWorldTime().GetFormattedTime(), owner, news1, news2, news3)

		If useMutexes Then UnlockMutex(_newsMutex)

		AddObject(show, TVTBroadcastMaterialType.NEWSSHOW,-1,-1, False)

		Return show
	End Method


	Method GetNewsShow:TBroadcastMaterial(day:Int=-1, hour:Int=-1) {_exposeToLua}
		'avoid others manipulating the collection meanwhile
		If useMutexes Then LockMutex(_newsShowMutex)

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

		If useMutexes Then UnlockMutex(_newsShowMutex)

		Return show
	End Method


	'returns which number that given advertisement spot will have
	Method GetAdvertisementSpotNumber:Int(advertisement:TAdvertisement, viewType:int=-1) {_exposeToLua}
		if not advertisement then return 0
		if not advertisement.contract.daySigned then return 0

		'if programmed (as advertisement!) - count all non-failed ads
		'up to the programmed date
		If advertisement.isProgrammed() and (viewType < 0 or advertisement.usedAsType = viewType)
			Return 1 + GetAdvertisementsCount(advertisement.contract, advertisement.contract.daySigned, 0, advertisement.programmedDay, advertisement.programmedHour-1, True, True)
		'if not programmed we just count ALL existing non-failed ads
		Else
			Return 1 + GetAdvertisementsCount(advertisement.contract, advertisement.contract.daySigned, 0, GetWorldTime().GetDay(), GetWorldTime().GetDayHour(), True, True)
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
			'avoid others manipulating the collection meanwhile
			If useMutexes Then LockMutex(_newsShowMutex)

			obj = GetNewsShow(day, hour)
			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj, TVTBroadcastMaterialType.NEWSSHOW)

			'adjust currently broadcasted block
			If obj then obj.currentBlockBroadcasting = GetObjectBlock(TVTBroadcastMaterialType.NEWSSHOW, day, hour)
			
			If useMutexes Then UnlockMutex(_newsShowMutex)

			return obj
		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			'avoid others manipulating the collection meanwhile
			If useMutexes Then LockMutex(_programmesMutex)
			
			obj = GetProgramme(day, hour)
			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj, TVTBroadcastMaterialType.PROGRAMME)

			'adjust currently broadcasted block
			If obj then obj.currentBlockBroadcasting = GetObjectBlock(TVTBroadcastMaterialType.PROGRAMME, day, hour)

			If useMutexes Then UnlockMutex(_programmesMutex)

			return obj
		'=== BEGIN OF ADVERTISEMENT ===
		ElseIf minute = 55
			'avoid others manipulating the collection meanwhile
			If useMutexes Then LockMutex(_advertisementsMutex)

			obj = GetAdvertisement(day, hour)

			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj, TVTBroadcastMaterialType.ADVERTISEMENT)

			'adjust currently broadcasted block
			If obj then obj.currentBlockBroadcasting = GetObjectBlock(TVTBroadcastMaterialType.ADVERTISEMENT, day, hour)

			If useMutexes Then UnlockMutex(_advertisementsMutex)

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

			Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
			If obj
				'inform news show that broadcasting started
				'(which itself informs the broadcasted news)
				obj.BeginBroadcasting(day, hour, minute, audienceResult)
			EndIf

			'store audience/broadcast for daily stats (if obj=null then outage)
			GetDailyBroadcastStatistic( day, true ).SetNewsBroadcastResult(obj, owner, hour, audienceResult)

			'inform others (eg. boss), "broadcastMaterial" could be null!
			TriggerBaseEvent(GameEventKeys.Broadcast_common_BeginBroadcasting, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.NEWSSHOW).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self)

		'=== END OF NEWSSHOW ===
		ElseIf minute = 4
			obj = GetNewsShow(day, hour)

			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				'inform news show that broadcasting ended
				'(which itself informs the broadcasted news)
				obj.FinishBroadcasting(day, hour, minute, audienceResult)
			EndIf
			'inform others (eg. boss), "broadcastMaterial" could be null!
			TriggerBaseEvent(GameEventKeys.Broadcast_common_FinishBroadcasting, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.NEWSSHOW).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self)

		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			'avoid others manipulating the collection meanwhile
			If useMutexes Then LockMutex(_programmesMutex)

			obj = GetProgramme(day, hour)
			local eventKey:TEventKey = GameEventKeys.Broadcast_common_BeginBroadcasting

			Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
			If obj
				'inform the object what happens (start or continuation)
				If 1 = GetProgrammeBlock(day, hour)
					obj.BeginBroadcasting(day, hour, minute, audienceResult)
				Else
					obj.ContinueBroadcasting(day, hour, minute, audienceResult)
					eventKey = GameEventKeys.Broadcast_common_ContinueBroadcasting
				EndIf
			EndIf
			If useMutexes Then UnlockMutex(_programmesMutex)

			'store audience/broadcast for daily stats (also for outage!)
			GetDailyBroadcastStatistic( day, true ).SetBroadcastResult(obj, owner, hour, audienceResult)

			'inform others (eg. boss), "broadcastMaterial" could be null!
			TriggerBaseEvent(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.PROGRAMME).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self)

		'=== END/BREAK OF PROGRAMME ===
		'call-in shows/quiz - generate income
		ElseIf minute = 54
			'avoid others manipulating the collection meanwhile
			If useMutexes Then LockMutex(_programmesMutex)

			obj = GetProgramme(day, hour)
			local eventKey:TEventKey = GameEventKeys.Broadcast_common_FinishBroadcasting

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

								Local licenceToRemove:TProgrammeLicence
								Local remove:Int = False
								Local sell:Int = False
								If licence.IsEpisode()
									'check if whole series needs removing
									licenceToRemove = licence.getParentLicence()
									If Not licenceToRemove Or Not licenceToRemove.isExceedingBroadcastLimit()
										'nothing to remove
										licenceToRemove = Null
									Else
										'for series - flag value is true if any of the episodes or the head has the flag
										For Local l:TProgrammeLicence = eachin licenceToRemove.subLicences
											If l.HasLicenceFlag(TVTProgrammeLicenceFlag.REMOVE_ON_REACHING_BROADCASTLIMIT) Then remove = True
											If l.HasLicenceFlag(TVTProgrammeLicenceFlag.SELL_ON_REACHING_BROADCASTLIMIT) Then sell = True
										Next
									EndIf
								ElseIf licence.GetSublicenceCount() = 0
									'TODO maybe handle franchise/collection differently
									licenceToRemove = licence
								EndIf

								If licenceToRemove and licenceToRemove.isTradeable()
									If licenceToRemove.HasLicenceFlag(TVTProgrammeLicenceFlag.REMOVE_ON_REACHING_BROADCASTLIMIT) Then remove = True
									If licenceToRemove.HasLicenceFlag(TVTProgrammeLicenceFlag.SELL_ON_REACHING_BROADCASTLIMIT) Then sell = True
									If remove
										GetPlayerProgrammeCollection(owner).RemoveProgrammeLicence(licenceToRemove, False)
									ElseIf sell
										GetPlayerProgrammeCollection(owner).RemoveProgrammeLicence(licenceToRemove, True)
									EndIf
								EndIf

								'remove _upcoming_ planned programmes with that licence
								RemoveProgrammeInstancesByLicence(licence, False)

								'inform others
								TriggerBaseEvent(GameEventKeys.ProgrammeLicence_ExceedingBroadcastLimit, null, licence)
							endif
						EndIf
					EndIf
				Else
					obj.BreakBroadcasting(day, hour, minute, audienceResult)
					eventKey = GameEventKeys.Broadcast_common_BreakBroadcasting
				EndIf
			EndIf
			
			If useMutexes Then UnlockMutex(_programmesMutex)

			'inform others (eg. boss), "broadcastMaterial" could be null!
			TriggerBaseEvent(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.PROGRAMME).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self)

		'=== BEGIN OF COMMERCIAL BREAK ===
		ElseIf minute = 55
			'avoid others manipulating the collection meanwhile
			If useMutexes Then LockMutex(_advertisementsMutex)

			obj = GetAdvertisement(day, hour)
			local eventKey:TEventKey = GameEventKeys.Broadcast_common_BeginBroadcasting

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
					If TAdvertisement(obj) And TAdvertisement(obj).contract.CanComplete()
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
					eventKey = GameEventKeys.Broadcast_common_ContinueBroadcasting
				EndIf
			EndIf
			
			If useMutexes Then UnlockMutex(_advertisementsMutex)
			
			'store audience/broadcast for daily stats (also for outage!)
			GetDailyBroadcastStatistic( day, true ).SetAdBroadcastResult(obj, owner, hour, audienceResult)

			'inform others (eg. boss), "broadcastMaterial" could be null!
			TriggerBaseEvent(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.ADVERTISEMENT).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self)

		'=== END OF COMMERCIAL BREAK ===
		'ads end - so trailers can set their "ok"
		ElseIf minute = 59
			'avoid others manipulating the collection meanwhile
			If useMutexes Then LockMutex(_advertisementsMutex)

			obj = GetAdvertisement(day, hour)
			local eventKey:TEventKey = GameEventKeys.Broadcast_common_FinishBroadcasting

			'inform  object that it gets broadcasted
			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				If obj.GetBlocks() = GetAdvertisementBlock(day, hour)
					obj.FinishBroadcasting(day, hour, minute, audienceResult)
					'eventKey = "broadcasting.finish"
				Else
					obj.BreakBroadcasting(day, hour, minute, audienceResult)
					eventKey = GameEventKeys.Broadcast_common_BreakBroadcasting
				EndIf
			EndIf
			
			If useMutexes Then UnlockMutex(_advertisementsMutex)
			'inform others (eg. boss), "broadcastMaterial" could be null!
			TriggerBaseEvent(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TVTBroadcastMaterialType.ADVERTISEMENT).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self)
		EndIf
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
			EventManager.registerListenerFunction(GameEventKeys.Broadcast_Programme_FinishBroadcastingAsAdvertisement, onFinishBroadcasting)
			EventManager.registerListenerFunction(GameEventKeys.Broadcast_Programme_FinishBroadcasting, onFinishBroadcasting)
			EventManager.registerListenerFunction(GameEventKeys.Broadcast_Advertisement_FinishBroadcastingAsProgramme, onFinishBroadcasting)
			'EventManager.registerListenerFunction(GameEventKeys.Broadcast_Advertisement_FinishBroadcasting, onFinishBroadcasting)
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

		local broadcast:TBroadcastMaterial = TBroadcastMaterial(GetPlayerProgrammePlan(player).GetProgramme(GetWorldTime().GetDay(time), GetWorldTime().GetDayHour(time)))
		if TProgramme(broadcast)
			genreKey = string(TProgramme(broadcast).data.GetGenre())
		elseif TAdvertisement(broadcast)
			genreKey = "infomercial"
		else
			genreKey = "unknown"
		endif

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

		Select triggerEvent.GetEventKey()
			Case GameEventKeys.Broadcast_Programme_FinishBroadcastingAsAdvertisement
				GetInstance().SetTrailerAired(broadcast.owner, GetInstance().GetTrailerAired(broadcast.owner) + 1, time)
			Case GameEventKeys.Broadcast_Advertisement_FinishBroadcastingAsProgramme
				GetInstance().SetInfomercialsAired(broadcast.owner, GetInstance().GetInfomercialsAired(broadcast.owner) + 1, time)
				GetInstance().RefreshAudienceData(broadcast.owner, time, data.Get("audienceData"))
			Case GameEventKeys.Broadcast_Programme_FinishBroadcasting
				GetInstance().RefreshProgrammeData(broadcast.owner, time)
				GetInstance().RefreshAudienceData(broadcast.owner, time, data.Get("audienceData"))
			Default
				print "onFinishBroadcasting: unhandled trigger - "+ triggerEvent.GetEventKey().text.ToString()
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




Type TSlotLockInfo
	Field adLock:Int
	Field programmeLock:Int
End Type