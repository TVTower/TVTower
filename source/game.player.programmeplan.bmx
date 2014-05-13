REM
	===========================================================
	code for PlayerProgrammePlan
	===========================================================
ENDREM
SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameobject.bmx"
Import "game.gametime.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.programme.adcontract.bmx"
Import "game.programme.newsevent.bmx"
Import "game.broadcastmaterial.programme.bmx"
Import "game.broadcastmaterial.advertisement.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.player.programmecollection.bmx"



Type TPlayerProgrammePlanCollection
	Field plans:TPlayerProgrammePlan[]
	Global _instance:TPlayerProgrammePlanCollection
	Global _eventsRegistered:int= FALSE


	Method New()
		if not _eventsRegistered
			EventManager.registerListenerFunction("programmecollection.addProgrammeLicenceToSuitcase", onAddProgrammeLicenceToSuitcase)
			_eventsRegistered = TRUE
		Endif
	End Method


	Function GetInstance:TPlayerProgrammePlanCollection()
		if not _instance then _instance = new TPlayerProgrammePlanCollection
		return _instance
	End Function


	Function onAddProgrammeLicenceToSuitcase:int(triggerEvent:TEventBase)
		local gameobject:TOwnedGameObject = TOwnedGameObject(triggerEvent.GetSender())
		local programmeLicence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().Get("programmeLicence"))
		if not gameobject or programmeLicence then return False

		'remove that programme from the players plan (if set)
		' - second param = true: also remove currently run programmes
		local plan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(gameobject.owner)
		if plan then plan.RemoveProgrammeInstancesByLicence(programmeLicence, true)
	End Function


	Method Set:int(playerID:int, plan:TPlayerProgrammePlan)
		if playerID <= 0 then return False
		if playerID > plans.length then plans = plans[.. playerID]
		plans[playerID-1] = plan
	End Method


	Method Get:TPlayerProgrammePlan(playerID:int)
		if playerID <= 0 or playerID > plans.length then return null
		return plans[playerID-1]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPlayerProgrammePlanCollection:TPlayerProgrammePlanCollection()
	Return TPlayerProgrammePlanCollection.GetInstance()
End Function
'return specific plan
Function GetPlayerProgrammePlan:TPlayerProgrammePlan(playerID:int)
	Return TPlayerProgrammePlanCollection.GetInstance().Get(playerID)
End Function




Type TPlayerProgrammePlan {_exposeToLua="selected"}
	Field programmes:TBroadcastMaterial[]		= new TBroadcastMaterial[0]
	Field news:TBroadcastMaterial[]				= new TBroadcastMaterial[3]	'single news -> eg for specials
	Field newsShow:TBroadcastMaterial[]			= new TBroadcastMaterial[0] 'news show
	Field advertisements:TBroadcastMaterial[]	= new TBroadcastMaterial[0]
	Field owner:int

	Global fireEvents:int						= TRUE		'FALSE to avoid recursive handling (network)

	'===== COMMON FUNCTIONS =====


	Method Create:TPlayerProgrammePlan(playerID:int)
		self.owner = playerID
		GetPlayerProgrammePlanCollection().Set(playerID, self)
		return self
	End Method


	Method getSkipHoursFromIndex:int()
		return (GetGameTime().GetStartDay()-1)*24
	End Method


	'returns the index of an array to use for a given hour
	Method GetArrayIndex:int(hour:int)
		return hour - getSkipHoursFromIndex()
	End Method


	'returns the Game-hour for a given array Index
	Method GetHourFromArrayIndex:int(arrayIndex:int)
		return arrayIndex + getSkipHoursFromIndex()
	End Method


	'eg. for debugging
	Method printOverview()
		rem
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


		print "=== AD/PROGRAMME PLAN PLAYER " + owner + " ==="
		For local i:int = 0 to Max(programmes.length - 1, advertisements.length - 1)
			local currentHour:int = GetHourFromArrayIndex(i) 'hours since start
			local time:int = GetGameTime().MakeTime(0, 0, currentHour, 0)
			local adString:string = ""
			local progString:string = ""

			'use "0" as day param because currentHour includes days already
			local advertisement:TBroadcastMaterial = GetAdvertisement(0, currentHour)
			if advertisement
				local startHour:int = advertisement.programmedDay*24 + advertisement.programmedHour
				adString = " -> " + advertisement.GetTitle() + " [" + (currentHour - startHour + 1) + "/" + advertisement.GetBlocks() + "]"
			endif


			local programme:TBroadcastMaterial = GetProgramme(0, currentHour)
			if programme
				local startHour:int = programme.programmedDay*24 + programme.programmedHour
				progString = programme.GetTitle() + " ["+ (currentHour - startHour + 1) + "/" + programme.GetBlocks() +"]"
			endif

			'only show if ONE is set
			if adString <> "" or progString <> ""
				if progString = "" then progString = "SENDEAUSFALL"
				if adString = "" then adString = " -> WERBEAUSFALL"
				print "[" + GetArrayIndex(time / 60) + "] " + GetGameTime().GetYear(time) + " " + GetGameTime().GetDayOfYear(time) + ".Tag " + GetGameTime().GetHour(currentHour * 60) + ":00 : " + progString + adString
			endif
		Next
		For local i:int = 0 to programmes.length - 1
		Next
		print "=== ----------------------- ==="
	End Method




	'===== common function for managed objects =====


	'sets the given array to the one requested through slotType
	Method GetObjectArray:TBroadcastMaterial[](slotType:int=0)
		if slotType = TBroadcastMaterial.TYPE_PROGRAMME then return programmes
		if slotType = TBroadcastMaterial.TYPE_ADVERTISEMENT then return advertisements
		if slotType = TBroadcastMaterial.TYPE_NEWSSHOW then return newsShow

		return new TBroadcastMaterial[0]
	End Method


	'sets the given array to the one requested through objectType
	'this is needed as assigning to "getObjectArray"-arrays is not possible for now
	Method SetObjectArrayEntry:int(obj:TBroadcastMaterial, slotType:int=0, arrayIndex:int)
		'resize array if needed
		if arrayIndex >= GetObjectArray(slotType).length then ResizeObjectArray(slotType, arrayIndex + 1 + obj.GetBlocks() - 1)
		if arrayIndex < 0 then throw "[ERROR] SetObjectArrayEntry: arrayIndex is negative"

		if slotType = TBroadcastMaterial.TYPE_PROGRAMME then programmes[arrayIndex] = obj
		if slotType = TBroadcastMaterial.TYPE_ADVERTISEMENT then advertisements[arrayIndex] = obj
		if slotType = TBroadcastMaterial.TYPE_NEWSSHOW then newsShow[arrayIndex] = obj

		return TRUE
	End Method


	'make the resizing more generic so the functions do not have to know the
	'underlying array
	Method ResizeObjectArray:int(objectType:int=0, newSize:int=0)
		Select objectType
			case TBroadcastMaterial.TYPE_PROGRAMME
					programmes = programmes[..newSize]
					return TRUE
			case TBroadcastMaterial.TYPE_ADVERTISEMENT
					advertisements = advertisements[..newSize]
					return true
			case TBroadcastMaterial.TYPE_NEWSSHOW
					newsShow = newsShow[..newSize]
					return true
		End Select

		return FALSE
	End Method


	'returns whether the slot can be used or is already in the past...
	Function IsUseableTimeSlot:int(slotType:int=0, day:int=-1, hour:int=-1, currentDay:int=-1, currentHour:int=-1, currentMinute:int=-1)
		if day = -1 then day = GetGameTime().getDay()
		if hour = -1 then hour = GetGameTime().getHour()
		if currentDay =-1  then currentDay = GetGameTime().GetDay()
		if currentHour =-1  then currentHour = GetGameTime().GetHour()
		if currentMinute = -1 then currentMinute = GetGameTime().getMinute()
		'convert to total hour
		currentHour = currentDay*24 + currentHour
		'do not allow adding in the past
		Local slotHour:Int = day * 24 + hour

		'if the hour is in the future, the slot MUST be useable
		if slotHour > currentHour then return TRUE
		'if the hour is in the past, the slot MUST be useable
		if slotHour < currentHour then return FALSE

		Select slotType
			'check newsShow
			case TBroadcastMaterial.TYPE_NEWSSHOW
				if currentMinute >= 1 then return FALSE
			'check programmes
			case TBroadcastMaterial.TYPE_PROGRAMME
				if currentMinute >= 5 then return FALSE
			'check ads
			case TBroadcastMaterial.TYPE_ADVERTISEMENT
				if currentMinute >= 55 then return FALSE
		End Select
		return TRUE
	End Function


	'returns a programme (or null) for the given array index
	Method GetObjectAtIndex:TBroadcastMaterial(objectType:int=0, arrayIndex:int)
		local array:TBroadcastMaterial[] = GetObjectArray(objectType)
		if arrayIndex > 0 and array.length > arrayIndex
			return array[arrayIndex]
		else
			return Null
		endif
	End Method


	Method GetObject:TBroadcastMaterial(slotType:int=0, day:int=-1, hour:Int=-1)
		local startHour:int = GetObjectStartHour(slotType, day, hour)
		if startHour < 0 then return Null
		return GetObjectAtIndex(slotType, GetArrayIndex(startHour))
	End Method


	'returns the block of the media at the given time
	Method GetObjectBlock:int(objectType:int=0, day:int=-1, hour:int=-1) {_exposeToLua}
		if day = -1 then day = GetGameTime().getDay()
		if hour = -1 then hour = GetGameTime().getHour()
		local startHour:int = GetObjectStartHour(objectType, day, hour)

		if startHour < 0 then return -1

		return 1 + (day * 24 + hour) - startHour
	End Method


	'returns an array of objects within the given time frame of a
	'specific object/list-type
	Method GetObjectsInTimeSpan:TBroadcastMaterial[](objectType:int=0, dayStart:int=-1, hourStart:int=-1, dayEnd:int=-1, hourEnd:int=-1, includeStartingEarlierObject:int=TRUE, requireSameType:int=FALSE) {_exposeToLua}
		If dayStart = -1 Then dayStart = GetGameTime().GetDay()
		If hourStart = -1 Then hourStart = GetGameTime().GetHour()
		If dayEnd = -1 Then dayEnd = GetGameTime().GetDay()
		If hourEnd = -1 Then hourEnd = GetGameTime().GetHour()

		local material:TBroadcastMaterial = null
		local result:TBroadcastMaterial[]

		'check if the starting time includes a block of a programme starting earlier
		'if so: adjust starting time
		if includeStartingEarlierObject
			'StartHour is "hours since day0"
			local earlierStartHour:int = GetObjectStartHour(objectType, dayStart, hourStart)
			if earlierStartHour > -1
				hourStart = earlierStartHour mod 24
				dayStart = floor(earlierStartHour / 24)
			endif
		endif

		'loop through the given range
		Local minIndex:Int = GetArrayIndex(dayStart*24 + hourStart)
		Local maxIndex:Int = GetArrayIndex(dayEnd*24 + hourEnd)
		For local i:int = minIndex to maxIndex
			material = TBroadcastMaterial(GetObjectAtIndex(objectType, i))
			if not material then continue
			'skip wrong type
			if requireSameType and material.materialType <> objectType then continue

			result = result[..result.length+1]
			result[result.length-1] = material

		Next

		Return result
	End Method


	'returns whether an object exists in the time span
	'if so - the first (or last) material-instance is returned
	Method ObjectPlannedInTimeSpan:TBroadcastMaterial(material:TBroadcastMaterial, slotType:int=0, dayStart:int=-1, hourStart:int=-1, dayEnd:int=-1, hourEnd:int=-1, startAtLatestTime:int=FALSE) {_exposeToLua}
		If dayStart = -1 Then dayStart = GetGameTime().GetDay()
		If hourStart = -1 Then hourStart = GetGameTime().GetHour()
		If dayEnd = -1 Then dayEnd = GetGameTime().GetDay()
		If hourEnd = -1 Then hourEnd = GetGameTime().GetHour()

		'check if the starting time includes a block of a programme starting earlier
		'if so: adjust starting time
		'StartHour is "hours since day0"
		local earlierStartHour:int = GetObjectStartHour(slotType, dayStart, hourStart)
		if earlierStartHour > -1
			hourStart = earlierStartHour mod 24
			dayStart = floor(earlierStartHour / 24)
		endif

		'loop through the given range
		Local minIndex:Int = GetArrayIndex(dayStart*24 + hourStart)
		Local maxIndex:Int = GetArrayIndex(dayEnd*24 + hourEnd)
		local plannedMaterial:TBroadcastMaterial

'materials might differ from each other
'instead of comparing objects we compare their content
		if startAtLatestTime
			For local i:int = minIndex to maxIndex
				local obj:TBroadcastMaterial = TBroadcastMaterial(GetObjectAtIndex(slotType, i))
				if not obj then continue
				if material.GetReferenceID() = obj.GetReferenceID() then return material
			Next
		else
			For local i:int = maxIndex to minIndex step -1
				local obj:TBroadcastMaterial = TBroadcastMaterial(GetObjectAtIndex(slotType, i))
				if not obj then continue
				if material.GetReferenceID() = obj.GetReferenceID() then return material
			Next
		endif
rem
		if startAtLatestTime
			For local i:int = minIndex to maxIndex
				if not TBroadcastMaterial(GetObjectAtIndex(slotType, i)) then continue
				if material = TBroadcastMaterial(GetObjectAtIndex(slotType, i)) then return material
			Next
		else
			For local i:int = maxIndex to minIndex step -1
				if material = TBroadcastMaterial(GetObjectAtIndex(slotType, i)) then return material
			Next
		endif
endrem
		Return null
	End Method


	'returns the hour a object at the given time slot really starts
	'attention: that is not a gamedayHour from 0-24 but in hours since day0
	'returns -1 if no object was found
	Method GetObjectStartHour:int(objectType:int=0, day:int=-1, hour:int=-1) {_exposeToLua}
		if day = -1 then day = GetGameTime().getDay()
		if hour = -1 then hour = GetGameTime().getHour()
		local arrayIndex:int = GetArrayIndex(day * 24 + hour)

		'out of bounds?
		if arrayIndex < 0 then return -1

		local array:TBroadcastMaterial[] = GetObjectArray(objectType)

		'check if the current hour is the start of an object
		'-> saves further requests (like GetBlocks() )
		if arrayIndex < array.length AND array[arrayIndex] then return GetHourFromArrayIndex(arrayIndex)

		'search the past for the previous programme
		'then check if start+blocks is still our time
		local searchIndex:int = arrayIndex
		while searchIndex >= 0
			if searchIndex < array.length AND array[searchIndex]
				if searchIndex + TBroadcastMaterial(array[searchIndex]).GetBlocks() - 1 >= arrayIndex
					return GetHourFromArrayIndex(searchIndex)
				else
					return -1
				endif
			endif
			searchIndex:-1
		wend
		return -1
	End Method


	'add an object / set a slot occupied
	Method AddObject:int(obj:TBroadcastMaterial, slotType:int=0, day:int=-1, hour:int=-1, checkSlotTime:int=TRUE)
		if day = -1 then day = GetGameTime().getDay()
		if hour = -1 then hour = GetGameTime().getHour()
		local arrayIndex:int = GetArrayIndex(day * 24 + hour)

		'do not allow adding objects we do not own
		if obj.GetOwner() <> owner then return FALSE

		'the same object is at the exact same slot - skip actions/events
		if obj = GetObjectAtIndex(slotType, arrayIndex) then return TRUE

		'do not allow adding in the past
		if checkSlotTime and not IsUseableTimeSlot(slotType, day, hour)
			TLogger.log("TPlayerProgrammePlan.AddObject", "Failed: time is in the past", LOG_INFO)
			return FALSE
		endif

		'clear all potential overlapping objects
		local removedObjects:object[]
		local removedObject:object
		For local i:int = 0 to obj.GetBlocks(slotType) -1
			removedObject = RemoveObject(null, slotType, day, hour+i)
			if removedObject
				removedObjects = removedObjects[..removedObjects.length+1]
				removedObjects[removedObjects.length-1] = removedObject
			endif
		Next

		'add the object to the corresponding array
		SetObjectArrayEntry(obj, slotType, arrayIndex)
		obj.programmedDay = day
		obj.programmedHour = hour

		'special for programmelicences: set a maximum planned time
		'setting does not require special calculations
		if TProgramme(obj) then TProgramme(obj).licence.SetPlanned(day*24+hour+obj.GetBlocks(slotType))
		'Advertisements: adjust planned
		if TAdvertisement(obj) then TAdvertisement(obj).contract.SetSpotsPlanned( GetAdvertisementsPlanned(TAdvertisement(obj).contract) )

		'emit an event
		If fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmeplan.addObject", new TData.add("object", obj).add("removedObjects", removedObjects).addNumber("slotType", slotType).addNumber("day", day).addNumber("hour", hour), self))

		'local time:int = GetGameTime().MakeTime(0, day, hour, 0)
		'print "..addObject day="+day+" hour="+hour+" array[" +arrayIndex + "] " + GetGameTime().GetYear(time) + " " + GetGameTime().GetDayOfYear(time) + ".Tag " + GetGameTime().GetHour(time) + ":00 : " + obj.getTitle()+" ("+obj.getReferenceID()+")"
		return TRUE
	End Method


	'remove object from slot / clear a slot
	'if no obj is given it is tried to get one by day/hour
	'returns the deleted object if one is found
	Method RemoveObject:object(obj:TBroadcastMaterial=null, slotType:int=0, day:int=-1, hour:int=-1)
		if not obj then obj = GetObject(slotType, day, hour)
		if not obj then return null

		'print "RON: PLAN.RemoveObject          id="+obj.id+" day="+day+" hour="+hour+" progDay="+obj.programmedDay+" progHour="+obj.programmedHour + " arrayIndex="+GetArrayIndex(obj.programmedDay*24 + obj.programmedHour) + " title:"+obj.GetTitle()

		'backup programmed date for event
		local programmedDay:int = obj.programmedDay
		local programmedHour:int = obj.programmedHour

		'if not programmed, skip deletion and events
		if obj.isProgrammed()
			'reset programmed date
			obj.programmedDay = -1
			obj.programmedHour = -1

			'null the corresponding array index
			SetObjectArrayEntry(null, slotType, GetArrayIndex(programmedDay*24 + programmedHour))

			'ProgrammeLicences: recalculate the latest planned hour
			if TProgramme(obj) then RecalculatePlannedProgramme(TProgramme(obj))
			'Advertisements: adjust planned amount
			if TAdvertisement(obj) then TAdvertisement(obj).contract.SetSpotsPlanned( GetAdvertisementsPlanned(TAdvertisement(obj).contract) )

			'inform others
			If fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmeplan.removeObject", new TData.add("object", obj).addNumber("slotType", slotType).addNumber("day", programmedDay).addNumber("hour", programmedHour), self))
		endif

		return obj
	End Method


	'Removes all not-yet-run instances of the given programme from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveObjectInstances:int(obj:TBroadcastMaterial, slotType:int=0, currentHour:int=-1, removeCurrentRunning:Int=FALSE)
		if currentHour = -1 then currentHour = GetGameTime().GetDay() * 24 + GetGameTime().GetHour()
		Local array:TBroadcastMaterial[] = GetObjectArray(slotType)
		Local earliestIndex:int = Max(0, GetArrayIndex(currentHour - obj.GetBlocks()))
		Local currentIndex:int = Max(0, GetArrayIndex(currentHour))
		Local latestIndex:int = array.length - 1
		Local foundAnInstance:int = FALSE

		'lock back in the history (programme may have started some blocks ago and is
		'still running
		For local i:int = earliestIndex to latestIndex
			'skip other programmes
			If not TBroadcastMaterial(array[i]) then continue
			if array[i].GetReferenceID() <> obj.GetReferenceID() then continue

			'only remove if sending is planned in the future or param allows current one
			If i + removeCurrentRunning * obj.GetBlocks() > currentIndex
				for local j:int = 0 to obj.GetBlocks()-1
					'method a) removeObject - emits events for each removed item
					RemoveObject(null, slotType, 0, GetHourFromArrayIndex(i+j))
					'method b) just clear the array at the given index
					'SetObjectArrayEntry(null, slotType, GetHourFromArrayIndex(i+j))
				next
				foundAnInstance = TRUE
			Endif
		Next

		If foundAnInstance
			If fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmeplan.removeObjectInstances", new TData.add("object", obj).addNumber("slotType", slotType).addNumber("removeCurrentRunning", removeCurrentRunning), self))
			return TRUE
		Else
			return FALSE
		EndIf
	End Method


	'Returns whether an object could be placed at the given day/time
	'without disturbing others
	Method ObjectPlaceable:Int(obj:TBroadcastMaterial, slotType:int=0, day:Int=-1, hour:int=-1)
		If not obj Then Return 0
		if day = -1 then day = GetGameTime().getDay()
		if hour = -1 then hour = GetGameTime().getHour()

		'check all slots the obj will occupy...
		For local i:int = 0 to obj.GetBlocks() - 1
			'... and if there is already an object, return the information
			if GetObject(slotType, day, hour + i) then return FALSE
		Next

		Return TRUE
	End Method




	'===== PROGRAMME FUNCTIONS =====
	'mostly wrapping the commong object functions


	'returns the hour a programme at the given time slot really starts
	'attention: that is not a gamedayHour from 0-24 but in hours since day0
	'returns -1 if no programme was found
	Method GetProgrammeStartHour:int(day:int=-1, hour:int=-1) {_exposeToLua}
		return GetObjectStartHour(TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
	End Method


	'returns the current block a programme is in (eg. 2 [of 3])
	Method GetProgrammeBlock:int(day:int=-1, hour:int=-1) {_exposeToLua}
		return GetObjectBlock(TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
	End Method


	'clear a slot so others can get placed without trouble
	Method RemoveProgramme:int(obj:TBroadcastMaterial=null, day:int=-1, hour:int=-1) {_exposeToLua}
		if not obj then obj = GetObject(TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
		'if alread not set for that time, just return success
		if not obj.isProgrammed() then return TRUE

		if obj
			'print "RON: PLAN.RemoveProgramme       owner="+owner+" day="+day+" hour="+hour + " obj :"+obj.GetTitle()

			'backup programmed date
			local programmedDay:int = obj.programmedDay
			local programmedHour:int = obj.programmedHour

			'try to remove the object from the array
			return (null <> RemoveObject(obj, TBroadcastMaterial.TYPE_PROGRAMME, day, hour))
		endif
		return FALSE
	End Method


	'Removes all not-yet-run users of the given programme licence from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveProgrammeInstancesByLicence:int(licence:TProgrammeLicence, removeCurrentRunning:Int=FALSE)
		'no programme connected to that licence?
		'Maybe we got a collection/series - so revoke all sublicences
		if not licence.getData()
			For local subLicence:TProgrammeLicence = eachin licence.subLicences
				RemoveProgrammeInstancesByLicence(subLicence, removeCurrentRunning)
			Next
			return TRUE
		endif

		'first of all we need to find a user of our licence
		Local array:TBroadcastMaterial[] = GetObjectArray(TBroadcastMaterial.TYPE_PROGRAMME)
		Local currentHour:Int = GetGameTime().GetDay() * 24 + GetGameTime().GetHour()
		Local earliestIndex:int = Max(0, GetArrayIndex(currentHour - licence.GetData().GetBlocks()))
		Local currentIndex:int = Max(0, GetArrayIndex(currentHour))
		Local latestIndex:int = array.length - 1
		Local programme:TBroadcastMaterial
		'lock back in the history (programme may have started some blocks ago and is
		'still running
		For local i:int = earliestIndex to latestIndex
			'skip other programmes
			If not TBroadcastMaterial(array[i]) then continue
			if array[i].GetReferenceID() <> licence.GetReferenceID() then continue

			programme = TBroadcastMaterial(array[i])
			exit
		Next

		'no instance found - no need to call the programmeRemover
		if not programme then return TRUE

		return RemoveProgrammeInstances(programme, removeCurrentRunning)
	End Method


	'Removes all not-yet-run instances of the given programme from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveProgrammeInstances:int(obj:TBroadcastMaterial, removeCurrentRunning:Int=FALSE)
		local doneSomething:int=FALSE
		if RemoveObjectInstances(obj, TBroadcastMaterial.TYPE_PROGRAMME, -1, removeCurrentRunning) then doneSomething = TRUE
		if RemoveObjectInstances(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, -1, removeCurrentRunning) then doneSomething = TRUE
		return doneSomething
	End Method


	'refreshes the programme's licence "latestPlannedEndHour"
	Method RecalculatePlannedProgramme:int(programme:TProgramme, dayStart:int=-1, hourStart:int=-1)
		if dayStart = -1 then dayStart = GetGameTime().GetDay()
		if hourStart = -1 then hourStart = GetGameTime().GetHour()

		if programme.licence.owner <= 0
			programme.licence.SetPlanned(-1)
		else
			'find "longest running" in all available type slots
			'if none is found, the planned value contains "-1"
			local instance:TBroadcastMaterial
			local blockEnd:int = -1
			'check ad usage
			instance = ObjectPlannedInTimeSpan(programme, TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, -1, 23, TRUE)
			if instance then blockEnd = Max(blockEnd, instance.programmedDay*24+instance.programmedHour + instance.GetBlocks(TBroadcastMaterial.TYPE_ADVERTISEMENT))
			'check prog usage
			instance = ObjectPlannedInTimeSpan(programme, TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, -1, 23, TRUE)
			if instance then blockEnd = Max(blockEnd, instance.programmedDay*24+instance.programmedHour + instance.GetBlocks(TBroadcastMaterial.TYPE_PROGRAMME))

			programme.licence.SetPlanned(blockEnd)
		endif
		return TRUE
	End Method



	'Returns the programme for the given day/time
	Method GetProgramme:TBroadcastMaterial(day:int=-1, hour:Int=-1) {_exposeToLua}
		return GetObject(TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
	End Method


	'returns an array of real programmes within the given time frame
	Method GetRealProgrammesInTimeSpan:TProgramme[](dayStart:int=-1, hourStart:int=-1, dayEnd:int=-1, hourEnd:int=-1, includeStartingEarlierObject:int=TRUE) {_exposeToLua}
		return TProgramme[](GetObjectsInTimeSpan(TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject, TRUE))
	End Method


	'returns an array of used-as programme within the given time frame
	'in the programme list
	Method GetProgrammesInTimeSpan:TBroadcastMaterial[](dayStart:int=-1, hourStart:int=-1, dayEnd:int=-1, hourEnd:int=-1, includeStartingEarlierObject:int=TRUE) {_exposeToLua}
		return GetObjectsInTimeSpan(TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject)
	End Method


	Method ProgrammePlannedInTimeSpan:int(material:TBroadcastMaterial, dayStart:int=-1, hourStart:int=-1, dayEnd:int=-1, hourEnd:int=-1) {_exposeToLua}
		'check if planned as programme
		if ObjectPlannedInTimeSpan(material, TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, dayEnd, hourEnd)
			return TRUE
		else
			'check if planned as trailer
			if ObjectPlannedInTimeSpan(material, TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd)
				return TRUE
			else
				return FALSE
			endif
		endif
	End Method


	'Add a used-as-programme to the player's programme plan
	Method SetProgrammeSlot:int(obj:TBroadcastMaterial, day:int=-1, hour:int=-1)
		'if nothing is given, we have to reset that slot
		if not obj then return (null<>RemoveObject(null, TBroadcastMaterial.TYPE_PROGRAMME, day, hour))
'		if not obj then return FALSE

		return AddObject(obj, TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
	End Method


	'Returns whether a used-as-programme can be placed at the given day/time
	'without intercepting other programmes
	Method ProgrammePlaceable:Int(obj:TBroadcastMaterial, time:Int=-1, day:Int=-1)
		return ObjectPlaceable(obj, TBroadcastMaterial.TYPE_PROGRAMME, time, day)
	End Method


	'AI helper .. should be made available through "TVT."
	'counts how many times a programme is Planned
	Method HowOftenProgrammeLicenceInPlan:Int(licenceID:Int, day:Int=-1, includePlanned:Int=FALSE, includeStartedYesterday:int=TRUE) {_exposeToLua}
		If day = -1 Then day = GetGameTime().GetDay()
		'no filter for other days than today ... would be senseless
		if day <> GetGameTime().getDay() then includePlanned = TRUE
		Local count:Int = 0
		Local minHour:Int = 0
		Local maxHour:Int = 23
		local programme:TProgramme = null

		'include programmes which may not be run yet?
		'else we stop at the current time of the day...
		if not includePlanned then maxhour = GetGameTime().GetHour()

		'debug
		'print "HowOftenProgrammeLicenceInPlan: day="+day+" GameDay="+GetGameTime().getDay()+" minHour="+minHour+" maxHour="+maxHour + " includeYesterday="+includeStartedYesterday

		'only programmes with more than 1 block can start the day before
		'and still run the next day - so we have to check that too
		if includeStartedYesterday
			'we just compare the programme started 23:00 or earlier the day before
			programme = TProgramme(GetProgramme(day - 1, 23))
			if programme and programme.GetReferenceID() = licenceID and programme.data.GetBlocks() > 1
				count:+1
				'add the hours the programme "takes over" to the next day
				minHour = (GetProgrammeStartHour(day - 1, 23) + programme.data.GetBlocks()) mod 24
			endif
		endif

		local midnightIndex:int = GetArrayIndex(day * 24)
		For local i:int = minHour to maxHour
			programme = TProgramme(GetObjectAtIndex(TBroadcastMaterial.TYPE_PROGRAMME, midnightIndex + i))
			'no need to skip blocks as only the first block of a programme
			'is stored in the array
			if programme and programme.GetReferenceID() = licenceID then count:+1
		Next

		Return count
	End Method



	'===== Advertisement contract functions =====


	'returns the hour a advertisement at the given time slot really starts
	'returns -1 if no ad was found
	Method GetAdvertisementStartHour:int(day:int=-1, hour:int=-1) {_exposeToLua}
		return GetObjectStartHour(TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
	End Method


	Method GetAdvertisementBlock:int(day:int=-1, hour:int=-1) {_exposeToLua}
		return GetObjectBlock(TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
	End Method


	'returns how many times an contract was programmed since signing the contract
	'start time: contract sign
	'end time: day +/- hour (if day > -1)
	Method GetAdvertisementsSent:int(contract:TAdContract, day:int=-1, hour:int=-1, onlySuccessful:int=FALSE) {_exposeToLua}
		return GetAdvertisementsCount(contract, day, hour, TRUE, FALSE)
	End Method


	Method GetAdvertisementsPlanned:int(contract:TAdContract, includeSuccessful:int=TRUE)
		'start with sign
		local startIndex:int= Max(0, GetArrayIndex(24 * (contract.daySigned - 1)))
		'end with latest planned element
		local endIndex:int = advertisements.length-1

		Local count:Int	= 0
		For Local i:int = startIndex to endIndex
			local ad:TAdvertisement = TAdvertisement(advertisements[i])
			'skip missing or wrong ads
			If not ad or ad.contract <> contract then continue
			'skip failed
			if ad.isState(ad.STATE_FAILED) then continue
			'skip sent ads if wanted
			if not includeSuccessful and ad.isState(ad.STATE_OK) then continue

			count:+1
		Next
		return count
	End Method


	'returns how many times advertisements of an adcontract were sent/planned...
	'in the case of no given day, the hour MUST be given (or set to 0)
	'
	'start time: contract sign
	'end time: day +/- hour (if day > -1)
	Method GetAdvertisementsCount:int(contract:TAdContract, day:int=-1, hour:int=-1, onlySuccessful:int=TRUE, includePlanned:int=FALSE)
		local startIndex:int= Max(0, GetArrayIndex(24 * (contract.daySigned - 1)))
		local endIndex:int	= 0
		if day = -1
			endIndex = advertisements.length-1 + hour
		else
			endIndex = GetArrayIndex(day*24 + hour)
		endif
		endIndex = Min(advertisements.length-1, Max(0,endIndex))

		'somehow we have a timeframe ending earlier than starting
		if endIndex < startIndex then return 0

		Local count:Int	= 0
		For Local i:int = startIndex to endIndex
			local ad:TAdvertisement = TAdvertisement(advertisements[i])
			'skip missing or wrong ads
			If not ad or ad.contract <> contract then continue

			if onlySuccessful and ad.isState(ad.STATE_FAILED) then continue
			if not includePlanned and ad.isState(ad.STATE_NORMAL) then continue

			count:+1
		Next
		return count
	End Method


	'clear a slot so others can get placed without trouble
	Method RemoveAdvertisement:int(obj:TBroadcastMaterial=null, day:int=-1, hour:int=-1) {_exposeToLua}
		if not obj then obj = GetObject(TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
		if obj
			'backup programmed date
			local programmedDay:int = obj.programmedDay
			local programmedHour:int = obj.programmedHour

			'try to remove the object from the array
			return (null <> RemoveObject(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour))
		endif
		return FALSE
	End Method



	'Removes all not-yet-run sisters of the given ad from the plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveAdvertisementInstances:int(obj:TBroadcastMaterial, removeCurrentRunning:Int=FALSE)
		local doneSomething:int=FALSE
		if RemoveObjectInstances(obj, TBroadcastMaterial.TYPE_PROGRAMME, -1, removeCurrentRunning) then doneSomething = TRUE
		if RemoveObjectInstances(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, -1, removeCurrentRunning) then doneSomething = TRUE
		return doneSomething
	End Method


	'Returns the ad for the given day/time
	Method GetAdvertisement:TBroadcastMaterial(day:int=-1, hour:Int=-1) {_exposeToLua}
		return GetObject(TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
	End Method


	'returns an array of real advertisements within the given time frame
	'in the advertisement list
	Method GetRealAdvertisementsInTimeSpan:TAdvertisement[](dayStart:int=-1, hourStart:int=-1, dayEnd:int=-1, hourEnd:int=-1, includeStartingEarlierObject:int=TRUE) {_exposeToLua}
		return TAdvertisement[](GetObjectsInTimeSpan(TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject, TRUE))
	End Method


	'returns an array of used-as advertisements within the given time
	'frame in the advertisement list
	Method GetAdvertisementsInTimeSpan:TBroadcastMaterial[](dayStart:int=-1, hourStart:int=-1, dayEnd:int=-1, hourEnd:int=-1, includeStartingEarlierObject:int=TRUE) {_exposeToLua}
		return GetObjectsInTimeSpan(TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject)
	End Method


	Method AdvertisementPlannedInTimeSpan:int(material:TBroadcastMaterial, dayStart:int=-1, hourStart:int=-1, dayEnd:int=-1, hourEnd:int=-1) {_exposeToLua}
		'check if planned as ad
		if ObjectPlannedInTimeSpan(material, TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd)
			return TRUE
		else
			'check if planned as infomercial
			if ObjectPlannedInTimeSpan(material, TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, dayEnd, hourEnd)
				return TRUE
			else
				return FALSE
			endif
		endif
	End Method


	'Fill/Clear the given advertisement slot with the given broadcast material
	Method SetAdvertisementSlot:int(obj:TBroadcastMaterial, day:int=-1, hour:int=-1)
		'if nothing is given, we have to reset that slot
		if not obj then return (null<>RemoveObject(null, TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour))

		'add it
		return AddObject(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
	End Method


	'Returns whether a programme can be placed at the given day/time
	Method AdvertisementPlaceable:Int(obj:TBroadcastMaterial, time:int=-1, day:int=-1)
		return ObjectPlaceable(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, time, day)
	End Method


	'returns the next number a new ad spot will have (counts all existing non-failed ads + 1)
	Method GetNextAdvertisementSpotNumber:int(contract:TAdContract) {_exposeToLua}
		return 1 + GetAdvertisementsCount(contract, -1, -1, TRUE, TRUE)
	End Method



	'===== NEWS FUNCTIONS =====

	'set the slot of the given newsblock
	'if not paid yet, it will only continue if pay is possible
    Method SetNews:int(newsObject:TNews, slot:int) {_exposeToLua}
		'out of bounds check
		if slot < 0 OR slot >= news.length then return FALSE

		'do not continue if pay not possible but needed
		If Not newsObject.paid and not newsObject.Pay() then return FALSE

		'if just dropping on the own slot ...do nothing
		if news[slot] = newsObject then return TRUE

		'remove this news from a slot if it occupies one
		'do not add it back to the collection
		RemoveNews(newsObject,-1,FALSE)


		'is there an other newsblock, remove that first
		'and adding that back to the collection
		if news[slot] then RemoveNews(null, slot, TRUE)

		'nothing is against using that slot (payment, ...) - so assign it
		news[slot] = newsObject

		'remove that news from the collection
		GetPlayerProgrammeCollectionCollection().Get(owner).RemoveNews(newsObject)


		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmeplan.SetNews", new TData.AddNumber("slot", slot), newsObject))

		return TRUE
    End Method


	'Remove the news from the plan
	'by default the news gets added back to the collection, this can
	'be controlled with the third param "addToCollection"
	Method RemoveNews:int(newsObject:TBroadcastMaterial=null, slot:int=-1, addToCollection:int=TRUE) {_exposeToLua}
		local newsSlot:int = slot
		if newsObject
			'try to find the slot occupied by the news
			For local i:int = 0 to news.length-1
				if GetNews(i) = newsObject then newsSlot = i;exit
			Next
		endif
		'was the news planned (-> in a slot) ?
		if newsSlot >= 0 and newsSlot < news.length and news[newsSlot]
			local deletedNews:TBroadcastMaterial = news[newsSlot]

			'add that news back to the collection ?
			if addToCollection and TNews(deletedNews)
				GetPlayerProgrammeCollectionCollection().Get(owner).AddNews(TNews(deletedNews))
			endif

			'empty the slot
			news[newsSlot] = null

			if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmeplan.RemoveNews", new TData.AddNumber("slot", newsSlot), deletedNews))
			return TRUE
		endif
		return FALSE
	End Method


	Method HasNews:int(newsObject:TBroadcastMaterial) {_exposeToLua}
		For local i:int = 0 to news.length-1
			if GetNews(i) = newsObject then return TRUE
		Next
		return FALSE
	End Method


	Method GetNews:TBroadcastMaterial(slot:int) {_exposeToLua}
		'out of bounds check
		if slot < 0 OR slot >= news.length then return null

		return news[slot]
	End Method


	Method ProduceNewsShow:TBroadcastMaterial(allowAddToPast:int=FALSE)
		local show:TNewsShow = TNewsShow.Create("Nachrichten", owner, GetNews(0),GetNews(1),GetNews(2))
		'if
		AddObject(show, TBroadcastMaterial.TYPE_NEWSSHOW,-1,-1, FALSE)
			'print "Production of news show for player "+owner + " OK."
		'endif
		return show
	End Method


	Method GetNewsShow:TBroadcastMaterial(day:int=-1, hour:Int=-1) {_exposeToLua}
		'if no news placed there already, just produce one live
		local show:TBroadcastMaterial = GetObject(TBroadcastMaterial.TYPE_NEWSSHOW, day, hour)
		if not show then show = ProduceNewsShow()
		return show
	End Method


	'returns which number that given advertisement spot will have
	Method GetAdvertisementSpotNumber:Int(advertisement:TAdvertisement) {_exposeToLua}
		'if programmed - count all non-failed ads up to the programmed date
		if advertisement.isProgrammed()
			return 1 + GetAdvertisementsCount(advertisement.contract, advertisement.programmedDay, advertisement.programmedHour-1, TRUE, TRUE)
		'if not programmed we just count ALL existing non-failed ads
		else
			return 1 + GetAdvertisementsCount(advertisement.contract, -1, -1, TRUE, TRUE)
		endif
	End Method


	'that method could be externalized to "main.bmx" or another common
	'function, there is no need to place it in this file
	'
	'STEP 1/3: function fills current broadcast, does NOT calculate audience
	Method LogInCurrentBroadcast:int(day:int, hour:int, minute:int)
		local obj:TBroadcastMaterial = null

		'=== BEGIN OF NEWSSHOW ===
		If minute = 0
			obj = GetNewsShow()
			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj)

		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			obj = GetProgramme(day, hour)
			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj)
		EndIf
	End Method


	'STEP 2/3: calculate audience (for all players at once)
	Function CalculateCurrentBroadcastAudience:int(day:int, hour:int, minute:int)
		local obj:TBroadcastMaterial = null

		'=== BEGIN OF NEWSSHOW ===
		If minute = 0
			'calculate audience
			GetBroadcastManager().BroadcastNewsShow(day, hour)

		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			'calculate audience
			GetBroadcastManager().BroadcastProgramme(day, hour)
		EndIf
	End Function


	'STEP 3/3: inform broadcasts
	Method InformCurrentBroadcast:int(day:int, hour:int, minute:int)
		local obj:TBroadcastMaterial = null

		'=== BEGIN OF NEWSSHOW ===
		If minute = 0
			'nothing to do

		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			obj = GetProgramme(day, hour)

			if obj
				local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				'inform the object what happens (start or continuation)
				If 1 = GetProgrammeBlock(day, hour)
					obj.BeginBroadcasting(day, hour, minute, audienceResult)
				Else
					obj.ContinueBroadcasting(day, hour, minute, audienceResult)
				EndIf
			endif

		'=== END/BREAK OF PROGRAMME ===
		'call-in shows/quiz - generate income
		ElseIf minute = 54
			obj = GetProgramme(day, hour)

			'inform  object that it gets broadcasted
			if obj
				local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				If obj.GetBlocks() = GetProgrammeBlock(day, hour)
					if obj.FinishBroadcasting(day, hour, minute, audienceResult)
						'for programmes: refresh planned state - for next hour
						if TProgramme(obj)
							RecalculatePlannedProgramme(TProgramme(obj), -1, hour+1)
						endif
					endif
				Else
					obj.BreakBroadcasting(day, hour, minute, audienceResult)
				EndIf
			endif

		'=== BEGIN OF COMMERCIAL BREAK ===
		ElseIf minute = 55
			obj = GetAdvertisement(day, hour)

			'inform  object that it gets broadcasted
			If obj
				local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				If 1 = GetAdvertisementBlock(day, hour)
					obj.BeginBroadcasting(day, hour, minute, audienceResult)

					'computes ads - if adcontract finishes, earn money
					if TAdvertisement(obj) and TAdvertisement(obj).contract.isSuccessful()
						'removes ads which are more than needed (eg 3 of 2 to be shown ads)
						RemoveAdvertisementInstances(obj, FALSE)
						'removes them also from programmes (shopping show)
						RemoveProgrammeInstances(obj, FALSE)

						'remove contract from collection (and suitcase)
						'contract is still stored within advertisements (until they get deleted)
						GetPlayerProgrammeCollectionCollection().Get(owner).RemoveAdContract(TAdvertisement(obj).contract)
					endif
				Else
					obj.ContinueBroadcasting(day, hour, minute, audienceResult)
				EndIf
			EndIf

		'=== END OF COMMERCIAL BREAK ===
		'ads end - so trailers can set their "ok"
		ElseIf minute = 59
			obj = GetAdvertisement(day, hour)

			'inform  object that it gets broadcasted
			If obj
				local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				If obj.GetBlocks() = GetAdvertisementBlock(day, hour)
					obj.FinishBroadcasting(day, hour, minute, audienceResult)
				Else
					obj.BreakBroadcasting(day, hour, minute, audienceResult)
				EndIf
			EndIf
		EndIf
	End Method


	'=== AUDIENCE ===
	'maybe move that helpers to TBroadcastManager
	Method GetAudience:Int() {_exposeToLua}
		local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
		If Not audienceResult Then Return 0
		Return audienceResult.Audience.GetSum()
	End Method


	'returns formatted value of actual audience
	Method GetFormattedAudience:String() {_exposeToLua}
		Return TFunctions.convertValue(GetAudience(), 2)
	End Method


	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetAudiencePercentage:Float() {_exposeToLua}
		local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
		If audienceResult then return audienceResult.AudienceQuote.GetAverage()

		return 0
		'Local audienceResult:TAudienceResult = TAudienceResult.Curr(playerID)
		'Return audienceResult.MaxAudienceThisHour.GetSumFloat() / audienceResult.WholeMarket.GetSumFloat()
	End Method
End Type