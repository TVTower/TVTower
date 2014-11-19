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
'			EventManager.registerListenerFunction("programmecollection.addProgrammeLicenceToSuitcase", onAddProgrammeLicenceToSuitcase)
			_eventsRegistered = True
		EndIf
	End Method


	Function GetInstance:TPlayerProgrammePlanCollection()
		If Not _instance Then _instance = New TPlayerProgrammePlanCollection
		Return _instance
	End Function

Rem
	Function onAddProgrammeLicenceToSuitcase:int(triggerEvent:TEventBase)
		local gameobject:TOwnedGameObject = TOwnedGameObject(triggerEvent.GetSender())
		local programmeLicence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().Get("programmeLicence"))
		if not gameobject or programmeLicence then return False

		'remove that programme from the players plan (if set)
		' - second param = true: also remove currently run programmes
		local plan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(gameobject.owner)
		if plan then plan.RemoveProgrammeInstancesByLicence(programmeLicence, true)
	End Function
endrem

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
	Field owner:Int

	'FALSE to avoid recursive handling (network)
	Global fireEvents:Int = True

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
		Return hour - getSkipHoursFromIndex()
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
			Local time:Int = GetWorldTime().MakeTime(0, 0, currentHour, 0)
			Local adString:String = ""
			Local progString:String = ""

			'use "0" as day param because currentHour includes days already
			Local advertisement:TBroadcastMaterial = GetAdvertisement(0, currentHour)
			If advertisement
				Local startHour:Int = advertisement.programmedDay*24 + advertisement.programmedHour
				adString = " -> " + advertisement.GetTitle() + " [" + (currentHour - startHour + 1) + "/" + advertisement.GetBlocks() + "]"
			EndIf


			Local programme:TBroadcastMaterial = GetProgramme(0, currentHour)
			If programme
				Local startHour:Int = programme.programmedDay*24 + programme.programmedHour
				progString = programme.GetTitle() + " ["+ (currentHour - startHour + 1) + "/" + programme.GetBlocks() +"]"
			EndIf

			'only show if ONE is set
			If adString <> "" Or progString <> ""
				If progString = "" Then progString = "SENDEAUSFALL"
				If adString = "" Then adString = " -> WERBEAUSFALL"
				Print "[" + GetArrayIndex(time / 60) + "] " + GetWorldTime().GetYear(time) + " " + GetWorldTime().GetDayOfYear(time) + ".Tag " + GetWorldTime().GetDayHour(currentHour * 60) + ":00 : " + progString + adString
			EndIf
		Next
		For Local i:Int = 0 To programmes.length - 1
		Next
		Print "=== ----------------------- ==="
	End Method




	'===== common function for managed objects =====


	'sets the given array to the one requested through slotType
	Method GetObjectArray:TBroadcastMaterial[](slotType:Int=0)
		If slotType = TBroadcastMaterial.TYPE_PROGRAMME Then Return programmes
		If slotType = TBroadcastMaterial.TYPE_ADVERTISEMENT Then Return advertisements
		If slotType = TBroadcastMaterial.TYPE_NEWSSHOW Then Return newsShow

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

		If slotType = TBroadcastMaterial.TYPE_PROGRAMME Then programmes[arrayIndex] = obj
		If slotType = TBroadcastMaterial.TYPE_ADVERTISEMENT Then advertisements[arrayIndex] = obj
		If slotType = TBroadcastMaterial.TYPE_NEWSSHOW Then newsShow[arrayIndex] = obj

		Return True
	End Method


	'make the resizing more generic so the functions do not have to know the
	'underlying array
	Method ResizeObjectArray:Int(objectType:Int=0, newSize:Int=0)
		Select objectType
			Case TBroadcastMaterial.TYPE_PROGRAMME
					programmes = programmes[..newSize]
					Return True
			Case TBroadcastMaterial.TYPE_ADVERTISEMENT
					advertisements = advertisements[..newSize]
					Return True
			Case TBroadcastMaterial.TYPE_NEWSSHOW
					newsShow = newsShow[..newSize]
					Return True
		End Select

		Return False
	End Method


	'returns whether the slot can be used or is already in the past...
	Function IsUseableTimeSlot:Int(slotType:Int=0, day:Int=-1, hour:Int=-1, currentDay:Int=-1, currentHour:Int=-1, currentMinute:Int=-1)
		If day = -1 Then day = GetWorldTime().getDay()
		If hour = -1 Then hour = GetWorldTime().getDayHour()
		If currentDay =-1  Then currentDay = GetWorldTime().GetDay()
		If currentHour =-1  Then currentHour = GetWorldTime().GetDayHour()
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
			Case TBroadcastMaterial.TYPE_NEWSSHOW
				If currentMinute >= 1 Then Return False
			'check programmes
			Case TBroadcastMaterial.TYPE_PROGRAMME
				If currentMinute >= 5 Then Return False
			'check ads
			Case TBroadcastMaterial.TYPE_ADVERTISEMENT
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
		If day = -1 Then day = GetWorldTime().getDay()
		If hour = -1 Then hour = GetWorldTime().getDayHour()
		Local startHour:Int = GetObjectStartHour(objectType, day, hour)

		If startHour < 0 Then Return -1

		Return 1 + (day * 24 + hour) - startHour
	End Method


	'returns an array of objects within the given time frame of a
	'specific object/list-type
	Method GetObjectsInTimeSpan:TBroadcastMaterial[](objectType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True, requireSameType:Int=False) {_exposeToLua}
		If dayStart = -1 Then dayStart = GetWorldTime().GetDay()
		If hourStart = -1 Then hourStart = GetWorldTime().GetDayHour()
		If dayEnd = -1 Then dayEnd = GetWorldTime().GetDay()
		If hourEnd = -1 Then hourEnd = GetWorldTime().GetDayHour()

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


	'returns whether an object exists in the time span
	'if so - the first (or last) material-instance is returned
	Method ObjectPlannedInTimeSpan:TBroadcastMaterial(material:TBroadcastMaterial, slotType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, startAtLatestTime:Int=False) {_exposeToLua}
		If dayStart = -1 Then dayStart = GetWorldTime().GetDay()
		If hourStart = -1 Then hourStart = GetWorldTime().GetDayHour()
		If dayEnd = -1 Then dayEnd = GetWorldTime().GetDay()
		If hourEnd = -1 Then hourEnd = GetWorldTime().GetDayHour()

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
		If startAtLatestTime
			For Local i:Int = minIndex To maxIndex
				Local obj:TBroadcastMaterial = TBroadcastMaterial(GetObjectAtIndex(slotType, i))
				If Not obj Then Continue
				If material.GetReferenceID() = obj.GetReferenceID() Then Return material
			Next
		Else
			For Local i:Int = maxIndex To minIndex Step -1
				Local obj:TBroadcastMaterial = TBroadcastMaterial(GetObjectAtIndex(slotType, i))
				If Not obj Then Continue
				If material.GetReferenceID() = obj.GetReferenceID() Then Return material
			Next
		EndIf
Rem
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
		Return Null
	End Method


	'returns the hour a object at the given time slot really starts
	'attention: that is not a gamedayHour from 0-24 but in hours since day0
	'returns -1 if no object was found
	Method GetObjectStartHour:Int(objectType:Int=0, day:Int=-1, hour:Int=-1) {_exposeToLua}
		If day = -1 Then day = GetWorldTime().getDay()
		If hour = -1 Then hour = GetWorldTime().getDayHour()
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
	Method AddObject:Int(obj:TBroadcastMaterial, slotType:Int=0, day:Int=-1, hour:Int=-1, checkSlotTime:Int=True)
		If day = -1 Then day = GetWorldTime().getDay()
		If hour = -1 Then hour = GetWorldTime().getDayHour()
		Local arrayIndex:Int = GetArrayIndex(day * 24 + hour)

		'do not allow adding objects we do not own
		If obj.GetOwner() <> owner Then Return False

		'the same object is at the exact same slot - skip actions/events
		If obj = GetObjectAtIndex(slotType, arrayIndex) Then Return True

		'do not allow adding in the past
		If checkSlotTime And Not IsUseableTimeSlot(slotType, day, hour)
			TLogger.Log("TPlayerProgrammePlan.AddObject", "Failed: time is in the past", LOG_INFO)
			Return False
		EndIf

		'clear all potential overlapping objects
		Local removedObjects:Object[]
		Local removedObject:Object
		For Local i:Int = 0 To obj.GetBlocks(slotType) -1
			removedObject = RemoveObject(Null, slotType, day, hour+i)
			If removedObject
				removedObjects = removedObjects[..removedObjects.length+1]
				removedObjects[removedObjects.length-1] = removedObject
			EndIf
		Next

		'add the object to the corresponding array
		SetObjectArrayEntry(obj, slotType, arrayIndex)
		obj.programmedDay = day
		obj.programmedHour = hour

		'special for programmelicences: set a maximum planned time
		'setting does not require special calculations
		If TProgramme(obj) Then TProgramme(obj).licence.SetPlanned(day*24+hour+obj.GetBlocks(slotType))
		'Advertisements: adjust planned
		If TAdvertisement(obj) Then TAdvertisement(obj).contract.SetSpotsPlanned( GetAdvertisementsPlanned(TAdvertisement(obj).contract) )

		'local time:int = GetWorldTime().MakeTime(0, day, hour, 0)
		'if obj.owner = 1 then print "..addObject day="+day+" hour="+hour+" array[" +arrayIndex + "] " + GetWorldTime().GetYear(time) + " " + GetWorldTime().GetDayOfYear(time) + ".Tag " + GetWorldTime().GetDayHour(time) + ":00 : " + obj.getTitle()+" ("+obj.getReferenceID()+")"

		'emit an event
		If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("programmeplan.addObject", New TData.add("object", obj).add("removedObjects", removedObjects).addNumber("slotType", slotType).addNumber("day", day).addNumber("hour", hour), Self))

		Return True
	End Method


	'remove object from slot / clear a slot
	'if no obj is given it is tried to get one by day/hour
	'returns the deleted object if one is found
	Method RemoveObject:Object(obj:TBroadcastMaterial=Null, slotType:Int=0, day:Int=-1, hour:Int=-1)
		If Not obj Then obj = GetObject(slotType, day, hour)
		If Not obj Then Return Null

		'print "RON: PLAN.RemoveObject          id="+obj.id+" day="+day+" hour="+hour+" progDay="+obj.programmedDay+" progHour="+obj.programmedHour + " arrayIndex="+GetArrayIndex(obj.programmedDay*24 + obj.programmedHour) + " title:"+obj.GetTitle()

		'backup programmed date for event
		Local programmedDay:Int = obj.programmedDay
		Local programmedHour:Int = obj.programmedHour

		'if not programmed, skip deletion and events
		If obj.isProgrammed()
			'reset programmed date
			obj.programmedDay = -1
			obj.programmedHour = -1

			'null the corresponding array index
			SetObjectArrayEntry(Null, slotType, GetArrayIndex(programmedDay*24 + programmedHour))

			'ProgrammeLicences: recalculate the latest planned hour
			If TProgramme(obj) Then RecalculatePlannedProgramme(TProgramme(obj))
			'Advertisements: adjust planned amount
			If TAdvertisement(obj) Then TAdvertisement(obj).contract.SetSpotsPlanned( GetAdvertisementsPlanned(TAdvertisement(obj).contract) )

			'local time:int = GetWorldTime().MakeTime(0, programmedDay, programmedHour, 0)
			'if obj.owner = 1 then print "..removeObject day="+programmedDay+" hour="+programmedHour+" array[" +GetArrayIndex(programmedDay*24 + programmedHour) + "] " + GetWorldTime().GetYear(time) + " " + GetWorldTime().GetDayOfYear(time) + ".Tag " + GetWorldTime().GetDayHour(time) + ":00 : " + obj.getTitle()+" ("+obj.getReferenceID()+")"

			'inform others
			If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("programmeplan.removeObject", New TData.add("object", obj).addNumber("slotType", slotType).addNumber("day", programmedDay).addNumber("hour", programmedHour), Self))
		EndIf

		Return obj
	End Method


	'Removes all not-yet-run instances of the given programme from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveObjectInstances:Int(obj:TBroadcastMaterial, slotType:Int=0, currentHour:Int=-1, removeCurrentRunning:Int=False)
		If currentHour = -1 Then currentHour = GetWorldTime().GetDay() * 24 + GetWorldTime().GetDayHour()
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
					RemoveObject(Null, slotType, 0, GetHourFromArrayIndex(i+j))
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
		If day = -1 Then day = GetWorldTime().getDay()
		If hour = -1 Then hour = GetWorldTime().getDayHour()

		'check all slots the obj will occupy...
		For Local i:Int = 0 To obj.GetBlocks() - 1
			'... and if there is already an object, return the information
			If GetObject(slotType, day, hour + i) Then Return False
		Next

		Return True
	End Method




	'===== PROGRAMME FUNCTIONS =====
	'mostly wrapping the commong object functions


	'returns the hour a programme at the given time slot really starts
	'attention: that is not a gamedayHour from 0-24 but in hours since day0
	'returns -1 if no programme was found
	Method GetProgrammeStartHour:Int(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObjectStartHour(TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
	End Method


	'returns the current block a programme is in (eg. 2 [of 3])
	Method GetProgrammeBlock:Int(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObjectBlock(TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
	End Method


	'clear a slot so others can get placed without trouble
	Method RemoveProgramme:Int(obj:TBroadcastMaterial=Null, day:Int=-1, hour:Int=-1) {_exposeToLua}
		If Not obj Then obj = GetObject(TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
		'if alread not set for that time, just return success
		If Not obj.isProgrammed() Then Return True

		If obj
			'print "RON: PLAN.RemoveProgramme       owner="+owner+" day="+day+" hour="+hour + " obj :"+obj.GetTitle()

			'backup programmed date
			Local programmedDay:Int = obj.programmedDay
			Local programmedHour:Int = obj.programmedHour

			'try to remove the object from the array
			Return (Null <> RemoveObject(obj, TBroadcastMaterial.TYPE_PROGRAMME, day, hour))
		EndIf
		Return False
	End Method


	'Removes all not-yet-run users of the given programme licence from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveProgrammeInstancesByLicence:Int(licence:TProgrammeLicence, removeCurrentRunning:Int=False)
		'no programme connected to that licence?
		'Maybe we got a collection/series - so revoke all sublicences
		If Not licence.getData()
			For Local subLicence:TProgrammeLicence = EachIn licence.subLicences
				RemoveProgrammeInstancesByLicence(subLicence, removeCurrentRunning)
			Next
			Return True
		EndIf

		'first of all we need to find a user of our licence
		Local array:TBroadcastMaterial[] = GetObjectArray(TBroadcastMaterial.TYPE_PROGRAMME)
		Local currentHour:Int = GetWorldTime().GetDay() * 24 + GetWorldTime().GetDayHour()
		Local earliestIndex:Int = Max(0, GetArrayIndex(currentHour - licence.GetData().GetBlocks()))
		Local currentIndex:Int = Max(0, GetArrayIndex(currentHour))
		Local latestIndex:Int = array.length - 1
		Local programme:TBroadcastMaterial
		'lock back in the history (programme may have started some blocks ago and is
		'still running
		For Local i:Int = earliestIndex To latestIndex
			'skip other programmes
			If Not TBroadcastMaterial(array[i]) Then Continue

			If array[i].GetReferenceID() <> licence.GetReferenceID() Then Continue

			programme = TBroadcastMaterial(array[i])
			Exit
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

		If RemoveObjectInstances(obj, TBroadcastMaterial.TYPE_PROGRAMME, -1, removeCurrentRunning)
			'if the object is the current broadcasted thing, reset audience
			If programme And obj = programme
				GetBroadcastManager().SetBroadcastMalfunction(owner, TBroadcastMaterial.TYPE_PROGRAMME)
			EndIf
			doneSomething = True
		EndIf
		If RemoveObjectInstances(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, -1, removeCurrentRunning) Then doneSomething = True
		Return doneSomething
	End Method


	'refreshes the programme's licence "latestPlannedEndHour"
	Method RecalculatePlannedProgramme:Int(programme:TProgramme, dayStart:Int=-1, hourStart:Int=-1)
		If dayStart = -1 Then dayStart = GetWorldTime().GetDay()
		If hourStart = -1 Then hourStart = GetWorldTime().GetDayHour()

		If programme.licence.owner <= 0
			programme.licence.SetPlanned(-1)
		Else
			'find "longest running" in all available type slots
			'if none is found, the planned value contains "-1"
			Local instance:TBroadcastMaterial
			Local blockEnd:Int = -1
			'check ad usage
			instance = ObjectPlannedInTimeSpan(programme, TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, -1, 23, True)
			If instance Then blockEnd = Max(blockEnd, instance.programmedDay*24+instance.programmedHour + instance.GetBlocks(TBroadcastMaterial.TYPE_ADVERTISEMENT))
			'check prog usage
			instance = ObjectPlannedInTimeSpan(programme, TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, -1, 23, True)
			If instance Then blockEnd = Max(blockEnd, instance.programmedDay*24+instance.programmedHour + instance.GetBlocks(TBroadcastMaterial.TYPE_PROGRAMME))

			programme.licence.SetPlanned(blockEnd)
		EndIf
		Return True
	End Method



	'Returns the programme for the given day/time
	Method GetProgramme:TBroadcastMaterial(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObject(TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
	End Method


	'returns an array of real programmes within the given time frame
	Method GetRealProgrammesInTimeSpan:TProgramme[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True) {_exposeToLua}
		Return TProgramme[](GetObjectsInTimeSpan(TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject, True))
	End Method


	'returns an array of used-as programme within the given time frame
	'in the programme list
	Method GetProgrammesInTimeSpan:TBroadcastMaterial[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True) {_exposeToLua}
		Return GetObjectsInTimeSpan(TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject)
	End Method


	Method ProgrammePlannedInTimeSpan:Int(material:TBroadcastMaterial, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		'check if planned as programme
		If ObjectPlannedInTimeSpan(material, TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, dayEnd, hourEnd)
			Return True
		Else
			'check if planned as trailer
			If ObjectPlannedInTimeSpan(material, TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd)
				Return True
			Else
				Return False
			EndIf
		EndIf
	End Method


	'Add a used-as-programme to the player's programme plan
	Method SetProgrammeSlot:Int(obj:TBroadcastMaterial, day:Int=-1, hour:Int=-1)
		'if nothing is given, we have to reset that slot
		If Not obj Then Return (Null<>RemoveObject(Null, TBroadcastMaterial.TYPE_PROGRAMME, day, hour))
'		if not obj then return FALSE

		Return AddObject(obj, TBroadcastMaterial.TYPE_PROGRAMME, day, hour)
	End Method


	'Returns whether a used-as-programme can be placed at the given day/time
	'without intercepting other programmes
	Method ProgrammePlaceable:Int(obj:TBroadcastMaterial, time:Int=-1, day:Int=-1)
		Return ObjectPlaceable(obj, TBroadcastMaterial.TYPE_PROGRAMME, time, day)
	End Method


	'AI helper .. should be made available through "TVT."
	'counts how many times a programme is Planned
	Method HowOftenProgrammeLicenceInPlan:Int(licenceID:Int, day:Int=-1, includePlanned:Int=False, includeStartedYesterday:Int=True) {_exposeToLua}
		If day = -1 Then day = GetWorldTime().GetDay()
		'no filter for other days than today ... would be senseless
		If day <> GetWorldTime().GetDay() Then includePlanned = True
		Local count:Int = 0
		Local minHour:Int = 0
		Local maxHour:Int = 23
		Local programme:TProgramme = Null

		'include programmes which may not be run yet?
		'else we stop at the current time of the day...
		If Not includePlanned Then maxhour = GetWorldTime().GetDayHour()

		'debug
		'print "HowOftenProgrammeLicenceInPlan: day="+day+" GameDay="+GetWorldTime().getDay()+" minHour="+minHour+" maxHour="+maxHour + " includeYesterday="+includeStartedYesterday

		'only programmes with more than 1 block can start the day before
		'and still run the next day - so we have to check that too
		If includeStartedYesterday
			'we just compare the programme started 23:00 or earlier the day before
			programme = TProgramme(GetProgramme(day - 1, 23))
			If programme And programme.GetReferenceID() = licenceID And programme.data.GetBlocks() > 1
				count:+1
				'add the hours the programme "takes over" to the next day
				minHour = (GetProgrammeStartHour(day - 1, 23) + programme.data.GetBlocks()) Mod 24
			EndIf
		EndIf

		Local midnightIndex:Int = GetArrayIndex(day * 24)
		For Local i:Int = minHour To maxHour
			programme = TProgramme(GetObjectAtIndex(TBroadcastMaterial.TYPE_PROGRAMME, midnightIndex + i))
			'no need to skip blocks as only the first block of a programme
			'is stored in the array
			If programme And programme.GetReferenceID() = licenceID Then count:+1
		Next

		Return count
	End Method



	'===== Advertisement contract functions =====


	'returns the hour a advertisement at the given time slot really starts
	'returns -1 if no ad was found
	Method GetAdvertisementStartHour:Int(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObjectStartHour(TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
	End Method


	Method GetAdvertisementBlock:Int(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObjectBlock(TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
	End Method


	'returns how many times an contract was programmed since signing the contract
	'start time: contract sign
	'end time: day +/- hour (if day > -1)
	Method GetAdvertisementsSent:Int(contract:TAdContract, day:Int=-1, hour:Int=-1, onlySuccessful:Int=False) {_exposeToLua}
		Return GetAdvertisementsCount(contract, day, hour, True, False)
	End Method


	Method GetAdvertisementsPlanned:Int(contract:TAdContract, includeSuccessful:Int=True)
		'start with sign
		Local startIndex:Int= Max(0, GetArrayIndex(24 * (contract.daySigned - 1)))
		'end with latest planned element
		Local endIndex:Int = advertisements.length-1

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
	Method GetAdvertisementsCount:Int(contract:TAdContract, day:Int=-1, hour:Int=-1, onlySuccessful:Int=True, includePlanned:Int=False)
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
		If Not obj Then obj = GetObject(TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
		If obj
			'backup programmed date
			Local programmedDay:Int = obj.programmedDay
			Local programmedHour:Int = obj.programmedHour

			'try to remove the object from the array
			Return (Null <> RemoveObject(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour))
		EndIf
		Return False
	End Method



	'Removes all not-yet-run sisters of the given ad from the plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveAdvertisementInstances:Int(obj:TBroadcastMaterial, removeCurrentRunning:Int=False)
		Local doneSomething:Int=False
		If RemoveObjectInstances(obj, TBroadcastMaterial.TYPE_PROGRAMME, -1, removeCurrentRunning) Then doneSomething = True
		If RemoveObjectInstances(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, -1, removeCurrentRunning) Then doneSomething = True
		Return doneSomething
	End Method


	'Returns the ad for the given day/time
	Method GetAdvertisement:TBroadcastMaterial(day:Int=-1, hour:Int=-1) {_exposeToLua}
		Return GetObject(TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
	End Method


	'returns an array of real advertisements within the given time frame
	'in the advertisement list
	Method GetRealAdvertisementsInTimeSpan:TAdvertisement[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True) {_exposeToLua}
		Return TAdvertisement[](GetObjectsInTimeSpan(TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject, True))
	End Method


	'returns an array of used-as advertisements within the given time
	'frame in the advertisement list
	Method GetAdvertisementsInTimeSpan:TBroadcastMaterial[](dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True) {_exposeToLua}
		Return GetObjectsInTimeSpan(TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject)
	End Method


	Method AdvertisementPlannedInTimeSpan:Int(material:TBroadcastMaterial, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1) {_exposeToLua}
		'check if planned as ad
		If ObjectPlannedInTimeSpan(material, TBroadcastMaterial.TYPE_ADVERTISEMENT, dayStart, hourStart, dayEnd, hourEnd)
			Return True
		Else
			'check if planned as infomercial
			If ObjectPlannedInTimeSpan(material, TBroadcastMaterial.TYPE_PROGRAMME, dayStart, hourStart, dayEnd, hourEnd)
				Return True
			Else
				Return False
			EndIf
		EndIf
	End Method


	'Fill/Clear the given advertisement slot with the given broadcast material
	Method SetAdvertisementSlot:Int(obj:TBroadcastMaterial, day:Int=-1, hour:Int=-1)
		'if nothing is given, we have to reset that slot
		If Not obj Then Return (Null<>RemoveObject(Null, TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour))

		'add it
		Return AddObject(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, day, hour)
	End Method


	'Returns whether a programme can be placed at the given day/time
	Method AdvertisementPlaceable:Int(obj:TBroadcastMaterial, time:Int=-1, day:Int=-1)
		Return ObjectPlaceable(obj, TBroadcastMaterial.TYPE_ADVERTISEMENT, time, day)
	End Method


	'returns the next number a new ad spot will have (counts all existing non-failed ads + 1)
	Method GetNextAdvertisementSpotNumber:Int(contract:TAdContract) {_exposeToLua}
		Return 1 + GetAdvertisementsCount(contract, -1, -1, True, True)
	End Method



	'===== NEWS FUNCTIONS =====

	'set the slot of the given newsblock
	'if not paid yet, it will only continue if pay is possible
    Method SetNews:Int(newsObject:TNews, slot:Int) {_exposeToLua}
		'out of bounds check
		If slot < 0 Or slot >= news.length Then Return False

		'do not continue if pay not possible but needed
		If Not newsObject.Pay() Then Return False

		'if just dropping on the own slot ...do nothing
		If news[slot] = newsObject Then Return True

		'remove this news from a slot if it occupies one
		'do not add it back to the collection
		RemoveNews(newsObject,-1,False)


		'is there an other newsblock, remove that first
		'and adding that back to the collection
		If news[slot] Then RemoveNews(Null, slot, True)

		'nothing is against using that slot (payment, ...) - so assign it
		news[slot] = newsObject

		'remove that news from the collection
		GetPlayerProgrammeCollectionCollection().Get(owner).RemoveNews(newsObject)


		'emit an event so eg. network can recognize the change
		If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("programmeplan.SetNews", New TData.AddNumber("slot", slot), newsObject))

		Return True
    End Method


	'Remove the news from the plan
	'by default the news gets added back to the collection, this can
	'be controlled with the third param "addToCollection"
	Method RemoveNews:Int(newsObject:TBroadcastMaterial=Null, slot:Int=-1, addToCollection:Int=True) {_exposeToLua}
		Local newsSlot:Int = slot
		If newsObject
			'try to find the slot occupied by the news
			For Local i:Int = 0 To news.length-1
				If GetNews(i) = newsObject Then newsSlot = i;Exit
			Next
		EndIf
		'was the news planned (-> in a slot) ?
		If newsSlot >= 0 And newsSlot < news.length And news[newsSlot]
			Local deletedNews:TBroadcastMaterial = news[newsSlot]

			'add that news back to the collection ?
			If addToCollection And TNews(deletedNews)
				GetPlayerProgrammeCollectionCollection().Get(owner).AddNews(TNews(deletedNews))
			EndIf

			'empty the slot
			news[newsSlot] = Null

			If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("programmeplan.RemoveNews", New TData.AddNumber("slot", newsSlot), deletedNews))
			Return True
		EndIf
		Return False
	End Method


	Method HasNews:Int(newsObject:TBroadcastMaterial) {_exposeToLua}
		For Local i:Int = 0 To news.length-1
			If GetNews(i) = newsObject Then Return True
		Next
		Return False
	End Method


	Method GetNews:TBroadcastMaterial(slot:Int) {_exposeToLua}
		'out of bounds check
		If slot < 0 Or slot >= news.length Then Return Null

		Return news[slot]
	End Method


	Method ProduceNewsShow:TBroadcastMaterial(allowAddToPast:Int=False)
		Local show:TNewsShow = TNewsShow.Create("Nachrichten", owner, GetNews(0),GetNews(1),GetNews(2))
		'if
		AddObject(show, TBroadcastMaterial.TYPE_NEWSSHOW,-1,-1, False)
			'print "Production of news show for player "+owner + " OK."
		'endif
		Return show
	End Method


	Method GetNewsShow:TBroadcastMaterial(day:Int=-1, hour:Int=-1) {_exposeToLua}
		'if no news placed there already, just produce one live
		Local show:TBroadcastMaterial = GetObject(TBroadcastMaterial.TYPE_NEWSSHOW, day, hour)
		If Not show Then show = ProduceNewsShow()
		Return show
	End Method


	'returns which number that given advertisement spot will have
	Method GetAdvertisementSpotNumber:Int(advertisement:TAdvertisement) {_exposeToLua}
		'if programmed - count all non-failed ads up to the programmed date
		If advertisement.isProgrammed()
			Return 1 + GetAdvertisementsCount(advertisement.contract, advertisement.programmedDay, advertisement.programmedHour-1, True, True)
		'if not programmed we just count ALL existing non-failed ads
		Else
			Return 1 + GetAdvertisementsCount(advertisement.contract, -1, -1, True, True)
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
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj, TBroadcastMaterial.TYPE_NEWSSHOW)

		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			obj = GetProgramme(day, hour)
			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj, TBroadcastMaterial.TYPE_PROGRAMME)
			return obj
		'=== BEGIN OF ADVERTISEMENT ===
		ElseIf minute = 5
			obj = GetAdvertisement(day, hour)
			'log in current broadcast
			GetBroadcastManager().SetCurrentBroadcastMaterial(owner, obj, TBroadcastMaterial.TYPE_ADVERTISEMENT)
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
			local eventKey:String = "broadcasting.begin"

			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				'inform news show that broadcasting started
				'(which itself informs the broadcasted news)
				obj.BeginBroadcasting(day, hour, minute, audienceResult)
				'store audience/broadcast for daily stats
				GetDailyBroadcastStatistic( day, true ).SetNewsBroadcastResult(obj, owner, hour, audienceResult.audience)
			Else
				'store audience/broadcast for daily stats - outage
				GetDailyBroadcastStatistic( day, true).SetNewsBroadcastResult(null, owner, hour, null)
			EndIf
			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TBroadcastMaterial.TYPE_NEWSSHOW).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))
			
		'=== END OF NEWSSHOW ===
		ElseIf minute = 4
			obj = GetNewsShow(day, hour)
			local eventKey:String = "broadcasting.finish"

			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				'inform news show that broadcasting started
				'(which itself informs the broadcasted news)
				obj.FinishBroadcasting(day, hour, minute, audienceResult)
			EndIf
			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TBroadcastMaterial.TYPE_NEWSSHOW).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))

		'=== BEGIN OF PROGRAMME ===
		ElseIf minute = 5
			obj = GetProgramme(day, hour)
			local eventKey:String = "broadcasting.begin"

			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				'inform the object what happens (start or continuation)
				If 1 = GetProgrammeBlock(day, hour)
					obj.BeginBroadcasting(day, hour, minute, audienceResult)
					'eventKey = "broadcasting.begin"
				Else
					obj.ContinueBroadcasting(day, hour, minute, audienceResult)
					eventKey = "broadcasting.continue"
				EndIf
				'store audience/broadcast for daily stats
				GetDailyBroadcastStatistic( day, true ).SetBroadcastResult(obj, owner, hour, audienceResult.audience)
			else
				'store audience/broadcast for daily stats
				GetDailyBroadcastStatistic( day, true).SetBroadcastResult(null, owner, hour, null)
			EndIf
			
			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TBroadcastMaterial.TYPE_PROGRAMME).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))

		'=== END/BREAK OF PROGRAMME ===
		'call-in shows/quiz - generate income
		ElseIf minute = 54
			obj = GetProgramme(day, hour)
			local eventKey:String = "broadcasting.finish"

			'inform  object that it gets broadcasted
			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				If obj.GetBlocks() = GetProgrammeBlock(day, hour)
					If obj.FinishBroadcasting(day, hour, minute, audienceResult)
						'for programmes: refresh planned state - for next hour
						If TProgramme(obj)
							RecalculatePlannedProgramme(TProgramme(obj), -1, hour+1)
						EndIf
						'eventKey = "broadcasting.finish"
					EndIf
				Else
					obj.BreakBroadcasting(day, hour, minute, audienceResult)
					eventKey = "broadcasting.break"
				EndIf
			EndIf
			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TBroadcastMaterial.TYPE_PROGRAMME).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))
			
		'=== BEGIN OF COMMERCIAL BREAK ===
		ElseIf minute = 55
			obj = GetAdvertisement(day, hour)
			local eventKey:String = "broadcasting.begin"

			'inform  object that it gets broadcasted
			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				If 1 = GetAdvertisementBlock(day, hour)
					obj.BeginBroadcasting(day, hour, minute, audienceResult)

					'computes ads - if adcontract finishes, earn money
					If TAdvertisement(obj) And TAdvertisement(obj).contract.isSuccessful()
						'removes ads which are more than needed (eg 3 of 2 to be shown ads)
						RemoveAdvertisementInstances(obj, False)
						'removes them also from programmes (shopping show)
						RemoveProgrammeInstances(obj, False)

						'inform contract and earn money
						TAdvertisement(obj).contract.Finish( GetWorldTime().MakeTime(0, day, hour, minute) )

						'remove contract from collection (and suitcase)
						'contract is still stored within advertisements (until they get deleted)
						GetPlayerProgrammeCollectionCollection().Get(owner).RemoveAdContract(TAdvertisement(obj).contract)
					EndIf
					'eventKey = "broadcasting.begin"
				Else
					obj.ContinueBroadcasting(day, hour, minute, audienceResult)
					eventKey = "broadcasting.continue"
				EndIf
			EndIf
			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TBroadcastMaterial.TYPE_ADVERTISEMENT).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))

		'=== END OF COMMERCIAL BREAK ===
		'ads end - so trailers can set their "ok"
		ElseIf minute = 59
			obj = GetAdvertisement(day, hour)
			local eventKey:String = "broadcasting.finish"

			'inform  object that it gets broadcasted
			If obj
				Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
				If obj.GetBlocks() = GetAdvertisementBlock(day, hour)
					obj.FinishBroadcasting(day, hour, minute, audienceResult)
					'eventKey = "broadcasting.finish"
				Else
					obj.BreakBroadcasting(day, hour, minute, audienceResult)
					eventKey = "broadcasting.break"
				EndIf
			EndIf
			'inform others (eg. boss), "broadcastMaterial" could be null!
			EventManager.triggerEvent(TEventSimple.Create(eventKey, New TData.add("broadcastMaterial", obj).addNumber("broadcastedAsType", TBroadcastMaterial.TYPE_ADVERTISEMENT).addNumber("day", day).addNumber("hour", hour).addNumber("minute", minute), Self))
		EndIf
	End Method


	'=== AUDIENCE ===
	'maybe move that helpers to TBroadcastManager
	Method GetAudience:Int() {_exposeToLua}
		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
		If Not audienceResult Then Return 0
		Return audienceResult.Audience.GetSum()
	End Method


	'returns formatted value of actual audience
	Method GetFormattedAudience:String() {_exposeToLua}
		Return TFunctions.convertValue(GetAudience(), 2)
	End Method


	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetAudiencePercentage:Float() {_exposeToLua}
		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(owner)
		If audienceResult Then Return audienceResult.GetAudienceQuote().GetAverage()

		Return 0
		'Local audienceResult:TAudienceResult = TAudienceResult.Curr(playerID)
		'Return audienceResult.MaxAudienceThisHour.GetSumFloat() / audienceResult.WholeMarket.GetSumFloat()
	End Method
End Type