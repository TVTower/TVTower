Const CURRENCYSIGN:string = Chr(8364) 'eurosign

Type TPlayerProgrammePlanNEW {_exposeToLua="selected"}
	Field programmes:TBroadcastMaterial[]		= new TBroadcastMaterial[0]
	Field news:TNews[]							= new TNews[3]
	Field advertisements:TBroadcastMaterial[]	= new TBroadcastMaterial[0]
	Field parent:TPlayer						= null
	Global skipHoursFromIndex:int				= -1		'amount of hours to substract from the arrays
	Global fireEvents:int						= TRUE		'FALSE to avoid recursive handling (network)

	const TYPE_PROGRAMME:int					= 1
	const TYPE_ADVERTISEMENT:int				= 2


	'===== common functions =====


	Method Create:TPlayerProgrammePlanNEW(player:TPlayer)
		self.parent = player
		if skipHoursFromIndex = -1 then skipHoursFromIndex = Game.GetDaysPlayed() * 24
		return self
	End Method


	'returns the index of an array to use for a given hour
	Method GetArrayIndex:int(hour:int)
		return hour - skipHoursFromIndex
	End Method


	'returns the Game-hour for a given array Index
	Method GetHourFromArrayIndex:int(arrayIndex:int)
		return arrayIndex + skipHoursFromIndex
	End Method


	'eg. for debugging
	Method printOverview()
		print "=== AD/PROGRAMME PLAN PLAYER "+parent.playerID+" ==="
		For local i:int = 0 to Max(programmes.length - 1, advertisements.length - 1)
			local currentHour:int = GetHourFromArrayIndex(i)
			local time:int = Game.MakeTime(0, 0, currentHour, 0)
			local adString:string = ""
			local progString:string = ""

			local advertisement:TAdvertisement = GetAdvertisement(0, currentHour)
			if advertisement
				local startHour:int = GetAdvertisementStartHour(0, currentHour)
				adString = " -> " + advertisement.GetTitle() + " [" + (currentHour - startHour + 1) + "/" + advertisement.GetBlocks() + "]"
			endif


			local programme:TProgramme = GetProgramme(0, currentHour)
			if programme
				local startHour:int = GetProgrammeStartHour(0, currentHour)
				progString = programme.title + " ["+ (currentHour - startHour + 1) + "/" + programme.GetBlocks() +"]"
			endif

			if adString <> "" or progString <> ""
				if progString = "" then progString = "SENDEAUSFALL"
				if adString = "" then adString = " -> WERBEAUSFALL"
				print "[" + GetArrayIndex(time / 60) + "] " + Game.GetYear(time) + " " + Game.GetDayOfYear(time) + ".Tag " + Game.GetHour(currentHour * 60) + ":00 : " + progString + adString
			endif
		Next
		For local i:int = 0 to programmes.length - 1
		Next
		print "=== ----------------------- ==="
	End Method




	'===== common function for managed objects =====


	'sets the given array to the one requested through objectType
	Method GetObjectArray:TBroadcastMaterial[](objectType:int=0)
		if objectType = TYPE_PROGRAMME then return programmes
		if objectType = TYPE_ADVERTISEMENT then return advertisements

		return new TBroadcastMaterial[0]
	End Method


	'make the resizing more generic so the functions do not have to know the
	'underlying array
	Method ResizeObjectArray:int(objectType:int=0, newSize:int=0)
		Select objectType
			case TYPE_PROGRAMME
					programmes = programmes[..newSize]
					return TRUE
			case TYPE_ADVERTISEMENT
					advertisements = advertisements[..newSize]
					return true
		End Select

		return FALSE
	End Method


	'returns a programme (or null) for the given array index
	Method GetObjectAtIndex:TBroadcastMaterial(objectType:int=0, arrayIndex:int)
		local array:TBroadcastMaterial[] = GetObjectArray(objectType)
		if arrayIndex > 0 and array.length > arrayIndex
			return array[arrayIndex]
		else
			return Null
		endif
	End Method


	Method GetObject:TBroadcastMaterial(objectType:int=0, day:int=-1, hour:Int=-1)
		local startHour:int = GetObjectStartHour(objectType, day, hour)
		if startHour < 0 then return Null

		return GetObjectAtIndex(objectType, GetArrayIndex(startHour))
	End Method


	'returns the hour a object at the given time slot really starts
	'attention: that is not a gamedayHour from 0-24 but in hours since day0
	'returns -1 if no object was found
	Method GetObjectStartHour:int(objectType:int=0, day:int=-1, hour:int=-1) {_exposeToLua}
		if day = -1 then day = Game.getDay()
		if hour = -1 then hour = Game.getHour()
		local arrayIndex:int = GetArrayIndex(day * 24 + hour)

		'out of bounds?
		if arrayIndex < 0 then return -1

		local array:TBroadcastMaterial[] = GetObjectArray(objectType)

		'check if the current hour is the start of an object
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


	Method AddObject:int(objectType:int=0, obj:TBroadcastMaterial, day:int=-1, hour:int=-1)
		if day = -1 then day=game.getDay()
		if hour = -1 then hour=game.getHour()
		local arrayIndex:int = GetArrayIndex(day * 24 + hour)

		'do not allow adding in the past
		Local currentHour:Int = game.GetDay() * 24 + game.GetHour()
		if game.getMinute() >= 5 and currentHour >= day * 24 + hour
			print "ProgrammePlan.AddObject failed: time is in the past"
			return FALSE
		endif

		'clear a potential overlapping obj in the PAST
		ClearObjectSlot(objectType, day, hour)
		'clear a potential overlapping obj in the FUTURE
		ClearObjectSlot(objectType, day, hour + obj.GetBlocks() - 1)


		'resize array if needed
		if arrayIndex >= GetObjectArray(objectType).length then ResizeObjectArray(objectType, arrayIndex + 1 + obj.GetBlocks() - 1)

		local array:TBroadcastMaterial[] = GetObjectArray(objectType)

		array[arrayIndex] = obj

		return TRUE
	End Method


	'Removes all not-yet-run instances of the given programme from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveObjectInstances:int(objectType:int=0, obj:TBroadcastMaterial, removeCurrentRunning:Int=FALSE)
		Local currentHour:Int = game.GetDay() * 24 + game.GetHour()
		Local earliestHour:int = Max(0, currentHour - obj.GetBlocks())
		Local array:TBroadcastMaterial[] = GetObjectArray(objectType)
		Local latestHour:int = Min(obj.GetBlocks(), Max(0, array.length - 1))
		Local foundAnInstance:int = FALSE

		'lock back in the history (programme may have started some blocks ago and is
		'still running
		For local i:int = earliestHour to latestHour
			'skip other programmes
			If not TBroadcastMaterial(array[GetArrayIndex(i)]) then continue
			if array[GetArrayIndex(i)].GetReferenceID() <> obj.GetReferenceID() then continue

			'only remove if sending is planned in the future or param allows current one
			If i + removeCurrentRunning * obj.GetBlocks() > currentHour
				for local j:int = 0 to obj.GetBlocks()-1
					array[i + j] = null
				next
				foundAnInstance = TRUE
			Endif
		Next

		If foundAnInstance
			If fireEvents then EventManager.registerEvent(TEventSimple.Create("programmeplan.removeObjectInstances", TData.Create().add("object", obj).addNumber("objectType", objectType).addNumber("removeCurrentRunning", removeCurrentRunning), self))
			return TRUE
		Else
			return FALSE
		EndIf
	End Method


	'clear a slot so others can get placed without trouble
	Method ClearObjectSlot:int(objectType:int=0, day:int=-1, hour:int=-1)
		local startHour:int = GetObjectStartHour(objectType, day, hour)
		local arrayIndex:int = GetArrayIndex(startHour)
		if startHour < 0 then return FALSE

		Local currentHour:Int = game.GetDay() * 24 + game.GetHour()
		if game.getMinute() >= 5 and currentHour >= startHour
			print "ClearObjectSlot failed: time is in the past"
			return FALSE
		endif

		local array:TBroadcastMaterial[] = GetObjectArray(objectType)

		'out of bounds?
		if arrayIndex < 0 OR arrayIndex > array.length then return FALSE

		if array[arrayIndex]
			array[arrayIndex] = null

			'emit an event so eg. network can recognize the change
			If fireEvents then EventManager.registerEvent(TEventSimple.Create("programmeplan.clearObjectSlot", TData.Create().addNumber("hour", startHour).addNumber("objectType", objectType), self))
			return TRUE
		endif
		return FALSE
	End Method


	'Returns whether an object could be placed at the given day/time
	Method ObjectPlaceable:Int(objectType:int=0, obj:TBroadcastMaterial, day:Int=-1, hour:int=-1)
		If not obj Then Return 0
		if day = -1 then day = game.getDay()
		if hour = -1 then hour = game.getHour()

		'check all slots the obj will occupy...
		For local i:int = 0 to obj.GetBlocks() - 1
			'... and if there is already an object, return the information
			if GetObject(day, hour + i) then return FALSE
		Next

		Return TRUE
	End Method




	'===== programme functions =====
	'mostly wrapping the commong object functions


	'returns the hour a programme at the given time slot really starts
	'attention: that is not a gamedayHour from 0-24 but in hours since day0
	'returns -1 if no programme was found
	Method GetProgrammeStartHour:int(day:int=-1, hour:int=-1) {_exposeToLua}
		return GetObjectStartHour(TYPE_PROGRAMME, day, hour)
	End Method


	'clear a slot so others can get placed without trouble
	Method ClearProgrammeSlot:int(day:int=-1, hour:int=-1) {_exposeToLua}
		if ClearObjectSlot(TYPE_PROGRAMME, day, hour)
			If fireEvents
				local startHour:int = GetObjectStartHour(TYPE_PROGRAMME, day, hour)
				EventManager.registerEvent(TEventSimple.Create("programmeplan.clearProgrammeSlot", TData.Create().addNumber("hour", startHour), self))
			endif
		endif
		return FALSE
	End Method


	'Removes all not-yet-run instances of the given programme from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveProgrammeInstances:int(programme:TProgramme, removeCurrentRunning:Int=FALSE)
		if RemoveObjectInstances(TYPE_PROGRAMME, programme, removeCurrentRunning)
			'emit an event so eg. network can recognize the change
			If fireEvents then EventManager.registerEvent(TEventSimple.Create("programmeplan.removeProgrammeInstances", TData.Create().add("programme", programme).addNumber("removeCurrentRunning", removeCurrentRunning), self))
			return TRUE
		else
			return FALSE
		endif
	End Method


	'Returns the programme for the given day/time
	Method GetProgramme:TProgramme(day:int=-1, hour:Int=-1) {_exposeToLua}
		return TProgramme(GetObject(TYPE_PROGRAMME, day, hour))
	End Method


	'Add a programme to the player's programme plan
	Method AddProgramme:int(programme:TProgramme, day:int=-1, hour:int=-1) {_exposeToLua}
		if not programme then return FALSE
		'do not add programmes the players does not control
		if not parent.programmeCollection.hasProgramme(programme) then return FALSE

		return AddObject(TYPE_PROGRAMME, programme, day, hour)
	End Method


	'Returns whether a programme can be placed at the given day/time
	Method ProgrammePlaceable:Int(programme:TProgramme, time:Int=-1, day:Int=-1)
		return ObjectPlaceable(TYPE_PROGRAMME, programme, time, day)
	End Method


	'AI helper .. should be made available through "TVT."
	'counts how many times a programme is Planned
	Method HowOftenProgrammeInPlan:Int(programmeId:Int, day:Int=-1, includePlanned:Int=FALSE, includeStartedYesterday:int=TRUE) {_exposeToLua}
		If day = -1 Then day = Game.GetDay()
		'no filter for other days than today ... would be senseless
		if day <> Game.getDay() then includePlanned = TRUE
		Local count:Int = 0
		Local minHour:Int = 0
		Local maxHour:Int = 23
		local programme:TProgramme = null

		'include programmes which may not be run yet?
		'else we stop at the current time of the day...
		if not includePlanned then maxhour = Game.GetHour()

		'debug
		'print "HowOftenProgrammeInPlan: day="+day+" GameDay="+Game.getDay()+" minHour="+minHour+" maxHour="+maxHour + " includeYesterday="+includeStartedYesterday

		'only programmes with more than 1 block can start the day before
		'and still run the next day - so we have to check that too
		if includeStartedYesterday
			'we just compare the programme started 23:00 or earlier the day before
			programme = GetProgramme(day - 1, 23)
			if programme and programme.id = programmeId and programme.GetBlocks() > 1
				count:+1
				'add the hours the programme "takes over" to the next day
				minHour = (GetProgrammeStartHour(day - 1, 23) + programme.GetBlocks()) mod 24
			endif
		endif

		local midnightIndex:int = GetArrayIndex(day * 24)
		For local i:int = minHour to maxHour
			programme = TProgramme(GetObjectAtIndex(TYPE_PROGRAMME, midnightIndex + i))
			'no need to skip blocks as only the first block of a programme
			'is stored in the array
			if programme and programme.id = programmeId then count:+1
		Next

		Return count
	End Method



	'===== Advertisement contract functions =====


	'returns the hour a advertisement at the given time slot really starts
	'returns -1 if no ad was found
	Method GetAdvertisementStartHour:int(day:int=-1, hour:int=-1) {_exposeToLua}
		return GetObjectStartHour(TYPE_ADVERTISEMENT, day, hour)
	End Method


	'clear a slot so others can get placed without trouble
	Method ClearAdvertisementSlot:int(day:int=-1, hour:int=-1) {_exposteTuLua}
		if ClearObjectSlot(TYPE_ADVERTISEMENT, day, hour)
			If fireEvents
				local startHour:int = GetObjectStartHour(TYPE_ADVERTISEMENT, day, hour)
				EventManager.registerEvent(TEventSimple.Create("programmeplan.clearAdvertisementSlot", TData.Create().addNumber("hour", startHour), self))
			endif
			return TRUE
		endif
		return FALSE
	End Method


	'Removes all not-yet-run sisters of the given ad from the plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveAdvertisementInstances:int(advertisement:TAdvertisement, removeCurrentRunning:Int=FALSE)
		if RemoveObjectInstances(TYPE_ADVERTISEMENT, advertisement, removeCurrentRunning)
			'emit an event so eg. network can recognize the change
			If fireEvents then EventManager.registerEvent(TEventSimple.Create("programmeplan.removeAdvertisementInstances", TData.Create().add("advertisement", advertisement).addNumber("removeCurrentRunning", removeCurrentRunning), self))
			return TRUE
		else
			return FALSE
		endif
	End Method


	'Returns the ad for the given day/time
	Method GetAdvertisement:TAdvertisement(day:int=-1, hour:Int=-1) {_exposeToLua}
		return TAdvertisement(GetObject(TYPE_ADVERTISEMENT, day, hour))
	End Method


	'Add a advertisement to the player's programme plan
	Method AddAdvertisement:int(advertisement:TAdvertisement, day:int=-1, hour:int=-1) {_exposeToLua}
		if not advertisement then return FALSE
		'do not add ads the players does have contracts for
		if not parent.programmeCollection.hasAdContract(advertisement.contract) then return FALSE

		return AddObject(TYPE_ADVERTISEMENT, advertisement, day, hour)
	End Method


	'Returns whether a programme can be placed at the given day/time
	Method AdvertisementPlaceable:Int(advertisement:TAdvertisement, time:int=-1, day:int=-1)
		return ObjectPlaceable(TYPE_ADVERTISEMENT, advertisement, time, day)
	End Method




	'===== news functions =====


End Type





Type TPlayerProgrammePlan {_exposeToLua="selected"}
	Field ProgrammeBlocks:TList = CreateList()
	Field news:TNews[]			= new TNews[3]
	Field AdBlocks:TList		= CreateList()

	Field AdditionallyDraggedProgrammeBlocks:Int = 0

	Field parent:TPlayer
	Global fireEvents:int		= TRUE			'FALSE to avoid recursive handling (network)


	Function Create:TPlayerProgrammePlan( parent:TPlayer)
		Local obj:TPlayerProgrammePlan = New TPlayerProgrammePlan
		obj.parent = parent
		Return obj
	End Function


	'Remove all blocks from the Plan
	Method ClearLists:int()
		ProgrammeBlocks.Clear()
		AdBlocks.Clear()
		'create a new array
		news = news[..]
	End Method


	'Returns a number based on day to send and hour from position
	'121 means 5 days and 1 hours -> 01:00 on day 5
	Function GetPlanHour:Int(dayHour:Int, dayToPlan:Int=Null)
		If dayToPlan = Null Then dayToPlan = game.daytoplan
		Return dayToPlan*24 + dayHour
	End Function


	'Programme(Block)
	'================

	'Returns whether a programme can be placed at the given day/time
	Method ProgrammePlaceable:Int(Programme:TProgramme, time:Int = -1, day:Int = -1)
		If Programme = Null Then Return 0
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.GetDay()

		If GetCurrentProgramme(time, day) = Null
			If time + Programme.blocks - 1 > 23 Then time:-24;day:+1 'sendung geht bis nach 0 Uhr
			If GetCurrentProgramme(time + Programme.blocks - 1, day) = Null Then Return TRUE
		EndIf
		Return FALSE
	End Method


	'Removes all not-yet-run ProgrammeBlocks of the given programme from the
	'plan's list.
	'If removeCurrentRunning is true, also the current block can be affected
	Method RemoveProgramme(programme:TProgramme, removeCurrentRunning:Int = 0)
		Local currentHour:Int = game.GetDay()*24 + game.GetHour()
		local removedProgramme:int = FALSE
		For Local block:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			'skip other programmes
			If block.programme <> programme then continue
			'only remove if sending is planned in the future or param allows current one
			If block.sendhour +removeCurrentRunning*block.programme.blocks > currentHour
				programmeBlocks.remove(block)
				removedProgramme=TRUE
			endif
		Next

		if removedProgramme
			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmeplan.removeProgramme", TData.Create().add("programme", programme).addNumber("removeCurrentRunning", removeCurrentRunning), self ) )
		endif
	End Method


	'Returns the programme for the given day/time
	Method GetCurrentProgramme:TProgramme(time:Int = -1, day:Int = -1) {_exposeToLua}
		local block:TProgrammeBlock = self.GetCurrentProgrammeBlock(time, day)
		if block then return block.programme

		return Null
	End Method




'== GUI ==

	'Add a ProgrammeBlock to the player's ProgrammePlan
	Method AddProgrammeBlock:TLink(block:TProgrammeBlock)
		Return Self.ProgrammeBlocks.addLast(block)
	End Method


	'Get a ProgrammeBlock from the player's ProgrammePlan
	Method GetProgrammeBlock:TProgrammeBlock(id:Int)
		For Local obj:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			If obj.id = id Then Return obj
		Next
		Return Null
	EndMethod


	'Get a ProgrammeBlock which is set for the given time/day
	Method GetCurrentProgrammeBlock:TProgrammeBlock(time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.GetDay()
		Local planHour:Int = self.GetPlanHour(time, day)

		For Local block:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			If (block.sendHour + block.Programme.blocks - 1 >= planHour And block.sendHour <= planHour) Then Return block
		Next
		Return Null
	End Method


	'Draw all ProgrammeBlocks of that ProgrammePlan
    Method DrawAllProgrammeBlocks()
		If Self.AdditionallyDraggedProgrammeBlocks > 0
			For Local ProgBlock:TProgrammeBlock = EachIn Self.ProgrammeBlocks
				If Self.parent.playerID = Game.playerID And ProgBlock.dragged=1 Then ProgBlock.DrawShades()
			Next
		EndIf
		For Local ProgrammeBlock:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			ProgrammeBlock.Draw()
		Next
    End Method


	'Update all ProgrammeBlocks of that ProgrammePlan
	Method UpdateAllProgrammeBlocks(gfxListenabled:int = 0)
		'assume all are dropped
		Self.AdditionallyDraggedProgrammeBlocks = 0

		Self.ProgrammeBlocks.sort(True, TBlockMoveable.SortDragged)
		Local clickrecognized :Byte = 0

		For Local block:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			If gfxListenabled = 0 And MOUSEMANAGER.IsHit(2) And block.dragged = 1
				block.DeleteBlock() 'removes block from Programmeplan
				MOUSEMANAGER.resetKey(2)
			EndIf

			If gfxListenabled=0 And Not Clickrecognized And MOUSEMANAGER.IsHit(1)
				If Not block.dragged
					If block.dragable And block.State = 0 And functions.DoMeet(block.sendhour, block.sendhour+block.programme.blocks, Game.daytoplan*24,Game.daytoplan*24+24)
						For Local i:Int = 1 To block.programme.blocks
							Local pos:TPoint = block.GetBlockSlotXY(i, block.rect.position)
							If functions.MouseIn(pos.x, pos.y, block.rect.getW(), 30)
								block.Drag()
								Exit
							EndIf
						Next
					EndIf
				Else 'drop dragged block
					Local DoNotDrag:Int = 0
					If gfxListenabled = 0 And MOUSEMANAGER.IsHit(1) And block.State = 0
						For Local DragAndDrop:TDragAndDrop = EachIn block.DragAndDropList  					'loop through DnDs
							If DragAndDrop.CanDrop(MouseManager.x,MouseManager.y, "programmeblock")						'mouse within dnd-rect
								For Local Otherblock:TProgrammeBlock = EachIn Self.ProgrammeBlocks   		'loop through other pblocks
									'is there a block positioned at the desired place?

									'is otherblock not the same as our actual block? - on the same day
									If Otherblock <> block
										Local dndHour:Int = game.daytoplan*24 + (DragAndDrop.pos.x = 394)*12 + (DragAndDrop.pos.y - 17) / 30		'timeset calc.

										'loop through aimed time + duration in scheduler
										If functions.DoMeet(dndHour, dndHour+block.programme.blocks-1,  otherblock.sendHour, otherBlock.sendHour + otherBlock.programme.blocks-1)
											clickrecognized = 1
											If Not Otherblock.DraggingAllowed()
												DoNotDrag = 1
												block.Drag()
												Otherblock.Drop()
												'print "would swap "+block.programme.title+" with "+otherblock.programme.title + " but not allowed"
												Exit
											Else
												block.Drop()
												Otherblock.Drag()
											EndIf
										EndIf
									EndIf
								Next
								If DoNotDrag <> 1
									block.rect.position.setPos(DragAndDrop.pos)
									block.StartPos.SetPos(block.rect.position)
									clickrecognized = 1

									block.sendhour = Self.getPlanHour(block.GetHourOfBlock(1, block.rect.position), game.daytoplan)
									block.Drop()
									Exit 'exit loop-each-dragndrop, we've already found the right position
								EndIf
							EndIf
						Next
						If block.IsAtStartPos() And DoNotDrag = 0 And (Game.GetDay() < Game.dayToPlan Or (Game.GetDay() = Game.dayToPlan And Game.GetHour() < block.GetHourOfBlock(1,block.StartPos)))
							block.Drop()
							block.rect.position.SetPos(block.StartPos)

							'pressing shift tries to get the next episode
							if KEYMANAGER.IsDown(KEY_LSHIFT) OR KEYMANAGER.IsDown(KEY_RSHIFT)
								TProgrammeblock.CreateDragged(block.programme.GetNextEpisode() )
							endif

							'pressing ctrl makes the programme placeable again
							if KEYMANAGER.IsDown(KEY_LCONTROL) OR KEYMANAGER.IsDown(KEY_RCONTROL)
								TProgrammeblock.CreateDragged(block.programme)
								'MOUSEMANAGER.resetKey(1)
							endif

						EndIf
					EndIf
				EndIf
			EndIf

			If block.dragged = 1
				Self.AdditionallyDraggedProgrammeBlocks :+1
				Local displace:Int = Self.AdditionallyDraggedProgrammeBlocks *5
				block.rect.position.SetXY(MouseManager.x - block.rect.GetW()/2 - displace, MouseManager.y - block.rect.GetH()*0.25 - displace)
			EndIf
		Next
    End Method

'== GUI ENDE ==




	Method HowOftenProgrammeInPlan:Int(programmeId:Int, day:Int=-1, withPlanned:Int=0) {_exposeToLua}
		If (day = -1) Then day = Game.GetDay()

		Local currentHour:Int = Game.GetHour()
		Local count:Int = 0

		local programme:TProgramme = null
		For Local i:Int = 0 To 23
			If currentHour > i Or withPlanned = 1
				programme = GetCurrentProgramme(i, day)
				If programme and programme.GetID() = programmeId then count:+1
			Endif
		Next

		Return count
	End Method


REM
EVENTUELL newsblock so umschreiben, dass er eher wird wie Werbung:
TNewsTicker (die Basisdaten)
TNews extends TBroadcastMaterial ("Sendematerial")
ENDREM

	'NewsBlock
	'=========

	'set the slot of the given newsblock
	'if not paid yet, it will only continue if pay is possible
    Method SetNews:int(newsObject:TNews, slot:int) {_exposeToLua}
		'out of bounds check
		if slot < 0 OR slot >= news.length then return FALSE

		'only if not added already
		'if HasNews(newsObject) then return TRUE
		'--
		'or better just remove old ones
		RemoveNews(newsObject)


		If Not newsObject.paid
			'do not continue if pay not possible
			if not newsObject.Pay() then return FALSE
		endif

		'is there an other newsblock, remove that first
		'if news[slot] then ClearSlot(slot)
		if news[slot] then RemoveNews(news[slot], FALSE)

		'nothing is against using that slot (payment, ...) - so assign it
		news[slot] = newsObject

		'remove that news from the collection
		parent.ProgrammeCollection.RemoveNews(newsObject)


		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmeplan.SetSlot", TData.Create().AddNumber("slot", slot), newsObject))

		return TRUE
    End Method


	'Remove the news from the plan
	'by default the news gets added back to the collection, this can
	'be controlled with the second param "addToCollection"
	Method RemoveNews:int(newsObject:TNews, addToCollection:int=TRUE) {_exposeToLua}
		For local slot:int = 0 to news.length-1
			if GetNews(slot) = newsObject and ClearSlot(slot, addToCollection)
				if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmeplan.RemoveNews", TData.Create().AddNumber("slot", slot), newsObject))
				return TRUE
			endif
		Next
		return FALSE
	End Method


	Method ClearSlot:int(slot:int, addToCollection:int=TRUE) {_exposeToLua}
		'out of bounds check
		if slot < 0 OR slot >= news.length then return FALSE

		if not news[slot]
			return FALSE
		else
			'add that news back to the collection
			if addToCollection then parent.ProgrammeCollection.AddNews(news[slot])

			'empty the slot
			news[slot] = null

			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmeplan.ClearSlot", TData.Create().AddNumber("slot", slot), self))
			return TRUE
		endif
	End Method


	Method GetNews:TNews(slot:int) {_exposeToLua}
		'out of bounds check
		if slot < 0 OR slot >= news.length then return null

		return news[slot]
	End Method


	Method HasNews:int(newsObject:TNews) {_exposeToLua}
		For local i:int = 0 to news.length-1
			if GetNews(i) = newsObject then return TRUE
		Next
		return FALSE
	End Method


	'Ad(Block)
	'=========

	Method AdblockPlaceable:Int(time:Int = -1, day:Int = -1)
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.GetDay()
		If not GetCurrentAdBlock(time, day) Then Return True else Return False
	End Method


	Method GetCurrentAdBlock:TAdBlock(time:Int = -1, day:Int = - 1) {_exposeToLua}
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.GetDay()

		For Local block:TAdBlock= EachIn self.Adblocks
			If block.sendtime = time And block.senddate = day Then Return block
		Next
		Return Null
	End Method


	'used if receiving changes via network
	Method RefreshAdPlan(day:Int)
		'remove all from today in players plan
		For Local block:TAdblock = EachIn Self.AdBlocks
			If block.senddate = day Then Self.RemoveAdBlock(block)
		Next
		print "RON: check RefreshAdPlan - needed ? "
		'add all from player in global list
		For Local block:TAdBlock= EachIn self.AdBlocks
			'Print "REFRESH AD:ADDED "+adblock.contract.title;
			Self.AddAdBlock(block)
		Next
	End Method


	Method AddAdBlock(block:TAdBlock)
		block.owner 	= Self.parent.playerID
		block.senddate	= Game.daytoplan

		self.AdBlocks.AddLast(block)
		'sort my adblocks
		self.AdBlocks.sort(True, TAdblock.sort)
	End Method

	'remove a block from the plan's list
	Method RemoveAdBlock(block:TAdBlock)
		Self.AdBlocks.remove(block)
		'sort my adblocks
		self.AdBlocks.sort(True, TAdblock.sort)
	End Method


	'return a value how often a successfull/planned adblock was placed
	global sentBroadcastHint:int = 0
	Method GetAdContractBroadcastCount:Int(_contractId:int, successful:int = 1, planned:int = 0) {_exposeToLua} 'successful & planned sind bool-Werte
		if not sentBroadcastHint
			'TODO?
			'print "GetContractBroadcastCount:"
			'print " - koennte eventuell ersetzt werden, da der TContract nur in der Collection vorhanden ist, wenn er noch nicht abgeschlossen ist"
			sentBroadcastHint = 1
		endif
		Local count:Int = 0
		For Local block:TAdBlock= EachIn self.AdBlocks
			'skip wrong contracts
			If block.contract.id <> _contractId then continue

			'Block erfolgreich gesendet
			if successful = 1 And not block.isBotched() and block.isAired()
				count :+1
			'Block noch nicht gesendet / die sendtime- und senddate-Prüfung ist da, damit auch wirklich sicher ist, dass es sich um einen Geplanten handelt.
			Elseif planned = 1 And not block.isAired() and block.senddate <> -1 and block.sendtime <> -1
				count :+1
			EndIf
		Next
		Return count
	End Method
End Type


Global GENRE_CALLINSHOW:Int	= 20
Global TYPE_MOVIE:Int		= 1
Global TYPE_SERIE:Int		= 2
Global TYPE_EPISODE:Int		= 4
Global TYPE_CONTRACT:Int	= 8
Global TYPE_AD:Int 			= 32
Global TYPE_NEWS:Int 		= 64


'holds all Programmes a player possesses
Type TPlayerProgrammeCollection {_exposeToLua="selected"}
	Field List:TList					= CreateList()	'no need to add {_private} as expose is selected
	Field MovieList:TList				= CreateList()
	Field SeriesList:TList				= CreateList()
	Field News:TList				= CreateList()
	Field AdContractList:TList			= CreateList()
	Field SuitcaseProgrammeList:TList	= CreateList()	'objects not available directly but still owned
	Field SuitcaseAdContractList:TList	= CreateList()	'objects in the suitcase but not signed
	Field parent:TPlayer
	Global fireEvents:int		= TRUE			'FALSE to avoid recursive handling (network)


	Function Create:TPlayerProgrammeCollection(player:TPlayer)
		Local obj:TPlayerProgrammeCollection = New TPlayerProgrammeCollection
		obj.parent = player
		Return obj
	End Function


	Method ClearLists()
		List.Clear()
		MovieList.Clear()
		SeriesList.Clear()
		AdContractList.Clear()
	End Method


	Method GetMovieCount:Int() {_exposeToLua}
		Return MovieList.count()
	End Method


	Method GetSeriesCount:Int() {_exposeToLua}
		Return SeriesList.count()
	End Method


	Method GetProgrammeCount:Int() {_exposeToLua}
		Return List.count()
	End Method


	Method GetAdContractCount:Int() {_exposeToLua}
		Return AdContractList.count()
	End Method


	'removes AdContract from Collection (Advertising-Menu in Programmeplanner)
	Method RemoveAdContract:int(contract:TAdContract)
		If not contract then return False
		if AdContractList.Remove(contract)
			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.removeAdContract", TData.Create().add("adcontract", contract), self ) )
		endif
	End Method


	Method AddAdContract:Int(contract:TAdContract)
		If not contract then return FALSE

		if contract.sign( self.parent.playerID ) and not AdContractList.contains(contract)
			AdContractList.AddLast(contract)

			'emit an event so eg. network can recognize the change
			If fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.addAdContract", TData.Create().add("adcontract", contract), self ) )
			return TRUE
		else
			return FALSE
		endif
	End Method


	Method GetUnsignedAdContractFromSuitcase:TAdContract(id:Int) {_exposeToLua}
		For Local contract:TAdContract=EachIn SuitcaseAdContractList
			If contract.id = id Then Return contract
		Next
		Return Null
	End Method


	Method HasUnsignedAdContractInSuitcase:int(contract:TAdContract)
		If not contract then return FALSE
		return SuitcaseAdContractList.Contains(contract)
	End Method

	'used when adding a contract to the suitcase
	Method AddUnsignedAdContractToSuitcase:int(contract:TAdContract)
		If not contract then return FALSE
		'do not add if already "full"
		if SuitcaseAdContractList.count() >= Game.maxContractsAllowed then return FALSE

		'add a special block-object to the suitcase
		SuitcaseAdContractList.AddLast( contract )

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.addUnsignedAdContractToSuitcase", TData.Create().add("adcontract", contract), self ) )

		return TRUE
	End Method


	Method RemoveUnsignedAdContractFromSuitcase:int(contract:TAdContract)
		if not SuitcaseAdContractList.Contains(contract) then return FALSE
		SuitcaseAdContractList.Remove(contract)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.removeUnsignedAdContractFromSuitcase", TData.Create().add("adcontract", contract), self ) )
		return TRUE
	End Method


	'readd programmes from suitcase to player's list of available programmes
	Method ReaddProgrammesFromSuitcase:int()
		For Local obj:TProgramme = EachIn SuitcaseProgrammeList
			RemoveProgrammeFromSuitcase(obj)
		Next

		return TRUE
	End Method


	Method AddProgrammeToSuitcase:int(programme:TProgramme)
		'do not add if already "full"
		if SuitcaseProgrammeList.count() >= Game.maxMoviesInSuitcaseAllowed then return FALSE

		'if owner differs, check if we have to buy
		if parent.playerID<>programme.owner
			if not programme.buy(parent.playerID) then return FALSE
		endif

		List.remove(programme)
		MovieList.remove(programme)
		SeriesList.remove(programme)

		'add a special block-object to the suitcase
		SuitcaseProgrammeList.AddLast( programme )

		'remove that programme from the players plan (if set)
		' - second param = true: also remove currently run programmes
		self.parent.programmeplan.RemoveProgramme(programme, true)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.addProgrammeToSuitcase", TData.Create().add("programme", programme), self ) )

		return TRUE
	End Method


	Method RemoveProgrammeFromSuitcase:int(programme:TProgramme)
		if not SuitcaseProgrammeList.Contains(programme) then return FALSE

		If programme.isMovie() Then MovieList.AddLast(programme) Else SeriesList.AddLast(programme)
		List.AddLast(programme)

		SuitcaseProgrammeList.Remove(programme)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.removeProgrammeFromSuitcase", TData.Create().add("programme", programme), self ) )
		return TRUE
	End Method


	Method RemoveProgramme:Int(programme:TProgramme, sell:int=FALSE)
		If programme = Null Then Return False

		if sell and not programme.sell() then return FALSE

		'Print "RON: PlayerCollection.RemoveProgramme: sell="+sell+" title="+programme.title
		List.remove(programme)
		MovieList.remove(programme)
		SeriesList.remove(programme)
		'remove from suitcase too!
		SuitcaseProgrammeList.remove(programme)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.removeProgramme", TData.Create().add("programme", programme).addNumber("sell", sell), self ) )
	End Method


	Method AddProgramme:Int(programme:TProgramme, buy:int=FALSE)
		If not programme then return FALSE

		'if owner differs, check if we have to buy or got that gifted
		'at program start or through special event...
		if parent.playerID<>programme.owner
			if buy and not programme.buy(parent.playerID) then return FALSE
		endif

		'Print "RON: PlayerCollection.AddProgramme: buy="+buy+" title="+programme.title

		If programme.isMovie() Then MovieList.AddLast(programme) Else SeriesList.AddLast(programme)
		Self.List.AddLast(programme)

		if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.addProgramme", TData.Create().add("programme", programme).addNumber("buy", buy), self ) )
	End Method



	'GetLocalRandom... differs from GetRandom... for using it's personal programmelist
	'instead of the global one
	'returns a movie out of the players programmebouquet

	Method GetRandomProgramme:TProgramme(serie:Int = 0) {_exposeToLua}
		If serie Then Return Self.GetRandomSerie()
		Return Self.GetRandomMovie()
	End Method

	Method GetRandomMovie:TProgramme() {_exposeToLua}
		if MovieList.count() = 0 then return NULL
		'randrange is Mersenne - which is only used for across-Network-sync values
		'Return TProgramme(MovieList.ValueAtIndex(randRange(0, MovieList.count()-1)))
		Return TProgramme(MovieList.ValueAtIndex(rand(0, MovieList.count()-1)))
	End Method

	Method GetRandomSerie:TProgramme() {_exposeToLua}
		if SeriesList.count() = 0 then return NULL
		'randrange is Mersenne - which is only used for across-Network-sync values
		'Return TProgramme(SeriesList.ValueAtIndex(randRange(0, SeriesList.count()-1)))
		Return TProgramme(SeriesList.ValueAtIndex(rand(0, SeriesList.count()-1)))
	End Method

	Method GetRandomAdContract:TAdContract() {_exposeToLua}
		Return TAdContract(AdContractList.ValueAtIndex(rand(0, AdContractList.count()-1)))
	End Method


	'get programme by index number in list - useful for lua-scripts
	Method GetProgrammeFromList:TProgramme(pos:Int=0) {_exposeToLua}
		Return TProgramme( List.ValueAtIndex(pos) )
	End Method

	'get movie by index number in list - useful for lua-scripts
	Method GetMovieFromList:Tprogramme(pos:Int=0) {_exposeToLua}
		Return TProgramme( MovieList.ValueAtIndex(pos) )
	End Method

	'get series by index number in list - useful for lua-scripts
	Method GetSeriesFromList:Tprogramme(pos:Int=0) {_exposeToLua}
		Return TProgramme( SeriesList.ValueAtIndex(pos) )
	End Method

	'get contract by index number in list - useful for lua-scripts
	Method GetAdContractFromList:TAdContract(pos:Int=0) {_exposeToLua}
		Return TAdContract( AdContractList.ValueAtIndex(pos) )
	End Method

	Method HasProgramme:int(programme:TProgramme) {_exposeToLua}
		return list.contains(programme)
	End Method

	Method HasAdContract:int(Contract:TAdContract) {_exposeToLua}
		return AdContractList.contains(contract)
	End Method


	Method HasNews:int(newsObject:TNews) {_exposeToLua}
		return news.contains(newsObject)
	End Method


	Method GetProgramme:TProgramme(id:Int) {_exposeToLua}
		For Local obj:TProgramme = EachIn Self.List
			If Obj.id = id Then Return obj
		Next
		Return Null
	End Method

	Method GetAdContract:TAdContract(id:Int) {_exposeToLua}
		For Local contract:TAdContract=EachIn Self.AdContractList
			If contract.id = id Then Return contract
		Next
		Return Null
	End Method

	Method GetAdContractByBase:TAdContract(id:Int) {_exposeToLua}
		For Local contract:TAdContract=EachIn Self.AdContractList
			If contract.base.id = id Then Return contract
		Next
		Return Null
	End Method

	Method GetMovies:Object[]() {_exposeToLua}
		Return Self.MovieList.toArray()
	End Method

	Method GetSeries:Object[]() {_exposeToLua}
		Return Self.SeriesList.toArray()
	End Method

	Method GetProgrammes:Object[]() {_exposeToLua}
		Return Self.list.toArray()
	End Method

	Method GetContracts:Object[]() {_exposeToLua}
		Return Self.AdContractList.toArray()
	End Method


	'returns the amount of news currently available
	Method GetNewsCount:Int() {_exposeToLua}
		Return news.count()
	End Method


	'returns the block with the given id
	Method GetNews:TNews(id:Int) {_exposeToLua}
		For Local obj:TNews = EachIn news
			If obj.id = id Then Return obj
		Next
		Return Null
	End Method


	'returns the newsblock at a specific position in the list
	Method GetNewsAtIndex:TNews(arrayIndex:Int=0) {_exposeToLua}
		'out of bounds?
		if arrayIndex < 0 OR arrayIndex > news.count()-1 then return Null

		Return TNews( news.ValueAtIndex(arrayIndex) )
	End Method


	Method AddNews:int(newsObject:TNews) {_private} 'do not expose to Lua.
		'skip adding if existing already
		if news.contains(newsObject)
			print "AddNews: already containing. "+newsObject.getTitle();
			return FALSE
		endif

		newsObject.owner = parent.playerID
		news.AddLast(newsObject)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmecollection.addNews", TData.Create(), newsObject))

		return TRUE
	End Method


	Method RemoveNews:int(newsObject:TNews) {_exposeToLua}
		'remove from list
		if news.remove(newsObject)
			'run cleanup
			newsObject.Remove()

			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.removeNews", TData.Create(), newsObject ) )
			return TRUE
		endif
		return FALSE
	End Method

End Type




REM
	Contracts:
	As we have to know individual broadcast states (eg. "this spot
	failed/run OK"), we have to create individual "TAdvertisement"/spots.
	This way these objects can store that states.

	Another benefit is: TAdvertisement is "TBroadcastMaterial" which would
	make it exchangeable with other material... This could be eg. used
	to make them placeable as "programme" - which creates shoppingprogramme
	or other things. (while programme as advertisement could generate Trailers)

	The normal contract data is splitted into "contractBase" and "contract".
	So the resulting contract can differe to the raw database contract
	(eg. discounts, special prices...). Also you can have the same contract
	data with different ids ... so multiple incarnations of a contract are
	possible.
ENDREM

'contracts bases for advertisement - straight from the DB
'they just contain data to base new contracts of
Type TAdContractBase Extends TGameObject {_exposeToLua}
	Field title:string			= ""
	Field description:string	= ""
	Field daysToFinish:Int					' days to fullfill a (signed) contract
	Field spotCount:Int						' spots to send
	Field blocks:int = 1					' blocklength
	Field targetGroup:Int					' target group of the spot
	Field minAudienceBase:Float				' minimum audience (real value calculated on sign)
	Field minImageBase:Float				' minimum image base value (real value calculated on sign)
	Field hasFixedPrice:Int					' flag wether price is fixed
	Field profitBase:Float					' base of profit (real value calculated on sign)
	Field penaltyBase:Float					' base of penalty (real value calculated on sign)
	global List:TList = CreateList()		' holding all TContractBases


	Method Create:TAdContractBase(title:String, description:String, daystofinish:Int, spotcount:Int, targetgroup:Int, minaudience:Int, minimage:Int, fixedPrice:Int, profit:Int, penalty:Int)
		self.title			= title
		self.description	= description
		self.daysToFinish	= daystofinish
		self.spotCount		= spotcount
		self.targetGroup	= targetgroup
		self.minAudienceBase= Float(minaudience) / 10.0
		self.minImageBase	= Float(minimage) / 10.0
		self.hasFixedPrice	= fixedPrice
		self.profitBase		= Float(profit)
		self.penaltyBase 	= Float(penalty)

		List.AddLast(self)
		Return self
	End Method


	Function Get:TAdContractBase(id:Int) {_exposeToLua}
		For Local obj:TAdContractBase = EachIn List
			If obj.id = id Then Return obj
		Next
		Return Null
	End Function


	Function GetRandom:TAdContractBase(_list:TList = null)
		if _list = Null then _list = List
		If _list = Null Then Return Null
		If _list.count() > 0
			Local obj:TAdContractBase = TAdContractBase(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			if obj then return obj
		endif
		return Null
	End Function


	Function GetRandomWithLimitedAudienceQuote:TAdContractBase(minAudienceQuote:float=0.0, maxAudienceQuote:Float=0.35)
		'maxAudienceQuote - xx% market share as maximum
		'filter to entries we need
		Local resultList:TList = CreateList()
		For local obj:TAdContractBase = EachIn TAdContractBase.list
			If obj.minAudienceBase >= minAudienceQuote AND obj.minAudienceBase <= maxAudienceQuote
				resultList.addLast(obj)
			EndIf
		Next
		Return TAdContractBase.GetRandom(resultList)
	End Function


	Method GetTitle:string() {_exposeToLua}
		return self.title
	End Method


	Method GetDescription:string() {_exposeToLua}
		return self.description
	End Method


	Method GetBlocks:string() {_exposeToLua}
		return self.blocks
	End Method
End Type




'the useable contract for advertisements used in the playercollections
Type TAdContract extends TGameObject {_exposeToLua="selected"}
	Field base:TAdContractBase			= Null					' holds raw contract data
	Field spotsSent:Int					= 0						' how many spots were succesfully sent up to now
	Field state:Int						= 0						' 1 = finished, -1 = botched
	Field owner:Int						= 0
	Field daySigned:Int					= -1					' day the contract has been taken from the advertiser-room
	Field profit:Int					= -1					' calculated profit value (on sign)
	Field penalty:Int					= -1					' calculated penalty value (on sign)
	Field minAudience:Int		 		= -1					' calculated minimum audience value (on sign)
	Field attractiveness:Float			= -1					' KI: Wird nur in der Lua-KI verwendet du die Filme zu bewerten

	global List:TList					= CreateList()			' holding all Tcontracts


	'create UNSIGNED (adagency)
	Method Create:TAdContract(baseContract:TAdContractBase)
		self.base = baseContract

		List.AddLast(self)
		Return self
	End Method


	'overwrite method from base
	Method GetTitle:string() {_exposeToLua}
		Return base.GetTitle()
	End Method


	'overwrite method from base
	Method GetDescription:string() {_exposeToLua}
		Return base.GetDescription()
	End Method


	'overwrite method from base
	Method GetBlocks:string() {_exposeToLua}
		Return base.GetBlocks()
	End Method


	'sign the contract -> calculate values and change owner
	Method Sign:int(owner:int, day:int=-1)
		if self.owner = owner then return FALSE

		If day < 0 Then day = game.GetDay()
		self.daySigned		= day
		self.owner			= owner
		self.profit			= GetProfit()
		self.penalty		= GetPenalty()
		self.minAudience	= GetMinAudience(owner)
		return TRUE
	End Method


	Function GetRandomFromList:TAdvertisement(_list:TList, playerID:Int =-1)
		If _list = Null Then Return Null
		If _list.count() > 0
			Local obj:TAdvertisement = TAdvertisement(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If obj <> Null
				obj.owner = playerID
				Return obj
			EndIf
		EndIf
		Print "TAdvertisement list empty - wrong filter ?"
		Return Null
	End Function


	Method IsAvailableToSign:Int() {_exposeToLua}
		Return (self.owner <= 0 and self.daySigned = -1)
	End Method


	'percents = 0.0 - 1.0 (0-100%)
	Method GetMinAudiencePercentage:Float(dbvalue:Float = -1) {_exposeToLua}
		If dbvalue < 0 Then dbvalue = Self.base.minAudienceBase
		Return Max(0.0, Min(1.0, dbvalue / 100.0)) 'from 75% to 0.75
	End Method


	'multiplies basevalues of prices, values are from 0 to 255 for 1 spot... per 1000 people in audience
	'if targetgroup is set, the price is doubled
	Method GetProfit:Int(baseValue:Int= -1, playerID:Int=-1) {_exposeToLua}
		'already calculated
		If Self.profit >= 0 Then Return Self.profit

		'calculate
		if baseValue = -1 then baseValue = self.base.profitBase
		if playerID = -1 then playerID = self.owner
		Return CalculatePrices(baseValue, playerID)
	End Method


	Method GetPenalty:Int(baseValue:Int= -1, playerID:Int=-1) {_exposeToLua}
		'already calculated
		If Self.penalty >= 0 Then Return Self.penalty

		'calculate
		if baseValue = -1 then baseValue = self.base.penaltyBase
		if playerID = -1 then playerID = self.owner
		Return CalculatePrices(baseValue, playerID)
	End Method


	Method CalculatePrices:Int(baseprice:Int=0, playerID:Int=-1) {_exposeToLua}
		'price is for each spot
		Local price:Float = baseprice * Float( self.GetSpotCount() )

		'ad is with fixed price - only avaible without minimum restriction
		If Self.base.hasFixedPrice
			'print self.contractBase.title + " has fixed price : "+ price + " base:"+baseprice + " profitbase:"+self.contractBase.profitBase
			Return price
		endif
		'dynamic price
		'----
		'price we would get if 100% of audience is watching
		price :* Max(5, getMinAudience(playerID)/1000)

		'specific targetgroups change price
		If Self.GetTargetGroup() > 0 Then price :*1.75

		'return "beautiful" prices
		Return TFunctions.RoundToBeautifulValue(price)
	End Method


	'gets audience in numbers (not percents)
	Method GetMinAudience:Int(playerID:Int=-1) {_exposeToLua}
		'already calculated?
		If self.minAudience >=0 Then Return self.minAudience

		If playerID < 0 Then playerID = Self.owner

		local useAudience:int = 0

		'in case of "playerID = -1" we get the avg value
		useAudience = Game.GetMaxaudience(playerID)

		'0.5 = more than 50 percent of whole germany wont watch TV the same time
		'therefor: maximum of half the audience can be "needed"
		Return TFunctions.RoundToBeautifulValue( Floor(useAudience*0.5 * Self.GetMinAudiencePercentage()) )
	End Method


	'days left for sending all contracts from today
	Method GetDaysLeft:Int() {_exposeToLua}
		Return ( self.base.daysToFinish - (Game.GetDay() - self.daySigned) )
	End Method


	'get the contract (to access its ID or title by its GetXXX() )
	Method GetBase:TAdContractBase() {_exposeToLua}
		Return self.base
	End Method


	'amount of spots still missing
	Method GetSpotsToSend:int() {_exposeToLua}
		Return ( self.base.spotCount - self.spotsSent )
	End Method


	'amount of spots which have already been successfully broadcasted
	Method GetSpotsSent:int() {_exposeToLua}
		Return self.spotsSent
	End Method


	'amount of total spots to send
	Method GetSpotCount:Int() {_exposeToLua}
		Return self.base.spotCount
	End Method


	'total days to send contract from date of sign
	Method GetDaysToFinish:Int() {_exposeToLua}
		Return self.base.daysToFinish
	End Method


	Method GetTargetGroup:Int() {_exposeToLua}
		Return self.base.targetGroup
	End Method


	Method GetTargetGroupString:String(group:Int=-1) {_exposeToLua}
		'if no group given, use the one of the object
		if group < 0 then group = self.base.targetGroup

		If group >= 1 And group <=9
			Return GetLocale("AD_GENRE_"+group)
		else
			Return GetLocale("AD_GENRE_NONE")
		EndIf
	End Method


	Method ShowSheet:Int(x:Int,y:Int, align:int=0)
		if align=1 then x :- Assets.GetSprite("gfx_datasheets_contract").w

		Local playerID:Int = owner
		'nobody owns it or unsigned contract
		If playerID <= 0 or self.daySigned < 0 Then playerID = Game.playerID

		Assets.GetSprite("gfx_datasheets_contract").Draw(x,y)

		Local font:TBitmapFont = Assets.fonts.basefont
		Assets.fonts.basefontBold.drawBlock(self.GetTitle()	, x+10 , y+11 , 270, 70,0, 0,0,0, 0,0)
		font.drawBlock(self.GetDescription()   		 		, x+10 , y+33 , 270, 70)
		font.drawBlock(getLocale("AD_PROFIT")+": "	, x+10 , y+94 , 130, 16)
		font.drawBlock(functions.convertValue(String( self.GetProfit() ), 2, 0)+" "+CURRENCYSIGN , x+10 , y+94 , 130, 16,2)
		font.drawBlock(getLocale("AD_PENALTY")+": "       , x+10 , y+117, 130, 16)
		font.drawBlock(functions.convertValue(String( self.GetPenalty() ), 2, 0)+" "+CURRENCYSIGN, x+10 , y+117, 130, 16,2)
		font.drawBlock(getLocale("AD_MIN_AUDIENCE")+": "    , x+10, y+140, 127, 16)
		font.drawBlock(functions.convertValue(String( GetMinAudience( playerID ) ), 2, 0), x+10, y+140, 127, 16,2)

		font.drawBlock(getLocale("AD_TOSEND")+": "    , x+150, y+94 , 127, 16)
		font.drawBlock(self.GetSpotsToSend()+"/"+self.GetSpotCount() , x+150, y+94 , 127, 16,2)
		font.drawBlock(getLocale("AD_PLANNED")+": "    , x+150, y+117 , 127, 16)
		if self.owner > 0
			font.drawBlock( Game.players[self.owner].ProgrammePlan.GetAdContractBroadcastCount(self.id, FALSE, TRUE)+"/"+self.GetSpotCount() , x+150, y+117 , 127, 16,2)
		else
			font.drawBlock( "-" , x+150, y+117 , 127, 16,2)
		endif

		font.drawBlock(getLocale("AD_TARGETGROUP")+": "+self.GetTargetgroupString()   , x+10 , y+163 , 270, 16)
		If owner <= 0
			If self.GetDaysToFinish() > 1
				font.drawBlock(getLocale("AD_TIME")+": "+self.GetDaysToFinish() +" "+ getLocale("DAYS"), x+86 , y+186 , 122, 16)
			Else
				font.drawBlock(getLocale("AD_TIME")+": "+self.GetDaysToFinish() +" "+ getLocale("DAY"), x+86 , y+186 , 122, 16)
			EndIf
		Else
			Select self.GetDaysLeft()
				Case 0	font.drawBlock(getLocale("AD_TIME")+": "+getLocale("AD_TILL_TODAY") , x+86 , y+186 , 126, 16)
				Case 1	font.drawBlock(getLocale("AD_TIME")+": "+getLocale("AD_TILL_TOMORROW") , x+86 , y+186 , 126, 16)
				Default	font.drawBlock(getLocale("AD_TIME")+": "+Replace(getLocale("AD_STILL_X_DAYS"),"%1", Self.GetDaysLeft()), x+86 , y+186 , 122, 16)
			EndSelect
		EndIf
	End Method


	Function Get:TAdContract(id:Int)
		For Local contract:TAdContract = EachIn List
			If contract.id = id Then Return contract
		Next
		Return Null
	End Function


	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method

	'Wird bisher nur in der LUA-KI verwendet
	Method SetAttractiveness(value:Float) {_exposeToLua}
		Self.attractiveness = value
	End Method

	'Wird bisher nur in der LUA-KI verwendet
	'Wie hoch ist das finanzielle Gewicht pro Spot?
	'Wird dafür gebraucht um die Wichtigkeit des Spots zu bewerten
	Method GetFinanceWeight:float() {_exposeToLua}
		Return (self.GetProfit() + self.GetPenalty()) / self.GetSpotCount()
	End Method

	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (Gesamt)
	Method GetPressure:float() {_exposeToLua}
		local _daysToFinish:int = self.GetDaysToFinish() + 1 'In diesem Zusammenhang nicht 0-basierend
		Return self.GetSpotCount() / _daysToFinish * _daysToFinish
	End Method

	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (tatsächlich / aktuell)
	Method GetCurrentPressure:float() {_exposeToLua}
		local _daysToFinish:int = self.GetDaysToFinish() + 1 'In diesem Zusammenhang nicht 0-basierend
		Return self.GetSpotsToSend() / _daysToFinish * _daysToFinish
	End Method

	'Wird bisher nur in der LUA-KI verwendet
	'Wie dringd ist es diese Spots zu senden
	Method GetAcuteness:float() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotCount() - self.GetSpotsToSend()
		Local daysLeft:int = self.getDaysLeft() + 1 'In diesem Zusammenhang nicht 0-basierend
		Return spotsToBroadcast  / daysLeft * daysLeft  * 100
	End Method

	'Wird bisher nur in der LUA-KI verwendet
	'Viele Spots sollten heute mindestens gesendet werden
	Method SendMinimalBlocksToday:int() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotCount() - self.GetSpotsToSend()
		Local acuteness:int = self.GetAcuteness()
		Local daysLeft:int = self.getDaysLeft() + 1 'In diesem Zusammenhang nicht 0-basierend

		If (acuteness >= 100)
			Return int(spotsToBroadcast / daysLeft) 'int rundet
		Elseif (acuteness >= 70)
			Return 1
		Else
			Return 0
		Endif
	End Method

	'Wird bisher nur in der LUA-KI verwendet
	'Viele Spots sollten heute optimalerweise gesendet werden
	Method SendOptimalBlocksToday:int() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotCount() - self.GetSpotsToSend()
		Local daysLeft:int = self.getDaysLeft() + 1 'In diesem Zusammenhang nicht 0-basierend

		Local acuteness:int = self.GetAcuteness()
		Local optimumCount:int = Int(spotsToBroadcast / daysLeft) 'int rundet

		If (acuteness >= 100) and (spotsToBroadcast > optimumCount)
			optimumCount = optimumCount + 1
		Endif

		If (acuteness >= 100)
			return Int(spotsToBroadcast / daysLeft)  'int rundet
		Endif
	End Method

End Type




'Base type for programmes, advertisements...
Type TBroadcastMaterial	extends TGameObject {exposeToLua="selected"}
	Field title:string			= ""
	Field description:string	= ""
	Field blocks:int			= 1		'length in blocks (eg. "hours")
	Field state:int				= 0		'by default the state is "normal"
	Field owner:int				= 0		'owner of that element

	'states a program can be in
	const STATE_NORMAL:int		= 0
	const STATE_OK:int			= 1
	const STATE_FAILED:int		= 2
	const STATE_RUN:int			= 3


	'get the title
	Method GetDescription:string() {_exposeToLua}
		Return self.description
	End Method


	'get the title
	Method GetTitle:string() {_exposeToLua}
		Return self.title
	End Method


	Method GetBlocks:int() {_exposeToLua}
		Return self.blocks
	End Method


	'by default this is the normal ID, but could be the contracts id or so...
	Method GetReferenceID:int() {_exposeToLua}
		return self.id
	End Method
End Type


'ad spot
Type TAdvertisement Extends TBroadcastMaterial {_exposeToLua="selected"}
	Field contract:TAdContract	= Null
	Field state:int				= 0				'botched, run ok, running
	'Eventuell den "state" hier als reine visuelle Hilfe nehmen.
	'Dinge wie "Spot X von Y" koennen auch dynamisch erfragt werden
	'
	'Auch sollte ein AdContract einen Event aussenden, wenn erfolgreich
	'gesendet worden ist ... dann koennen die "GUI"-Bloecke darauf reagieren
	'und ihre Werte aktualisieren

	Global List:TList			= CreateList()


	Method Create:TAdvertisement(contract:TAdContract)
		self.contract = contract

		List.AddLast(self)
		Return self
	End Method

	'override default getter to make contract id the reference id
	Method GetReferenceID:int() {_exposeToLua}
		return self.contract.id
	End Method
End Type




'parent of movies, series and so on
Type TProgramme Extends TBroadcastMaterial {_exposeToLua="selected"}
	Field actors:String			= ""
	Field director:String		= ""
	Field country:String		= "UNK"
	Field year:Int				= 1900
	Field releaseDay:Int		= 1					'at which day was the programme released?
	Field releaseAnnounced:int	= FALSE				'announced in news etc?
	Field timesAired:int		= 0					'how many times that programme was run
	Field targetGroup:int		= 0					'special targeted audience?
	Field refreshModifier:float	= 1.0				'changes how much a programme "regenerates" (multiplied with genreModifier)
	Field wearoffModifier:Float	= 1.0				'changes how much a programme loses during sending it
	Field liveHour:Int			= 0
	Field outcome:Float			= 0
	Field review:Float			= 0
	Field speed:Float			= 0
	Field relPrice:Int			= 0
	Field genre:Int				= 0
	Field episode:Int			= 0
	Field episodes:TList		= CreateList()
	Field xrated:Int			= 0
	Field topicality:Int		= -1 				'how "attractive" a movie is (the more shown, the less this value)
	Field maxtopicality:Int 	= 255
	Field parent:TProgramme		= Null
	Field attractiveness:Float	= -1				'Wird nur in der Lua-KI verwendet du die Filme zu bewerten
	Field programmeType:Int		= 1					'0 = serie, 1 = movie, ...?
	Global ProgList:TList			= CreateList()	'holding all programmes
	Global ProgMovieList:TList		= CreateList()	'holding only movies
	Global ProgSeriesList:TList		= CreateList()	'holding only series

	Global wearoffFactor:float		= 0.65			'factor by what a programmes topicality DECREASES by sending it
	Global refreshFactor:float		= 1.5			'factor by what a programmes topicality INCREASES by a day switch
	Global releaseDayCounter:int	= 0
	Global ignoreUnreleasedProgrammes:int	= TRUE	'hide movies of 2012 when in 1985?
	Global _filterReleaseDateStart:int		= 1900
	Global _filterReleaseDateEnd:int		= 2100

	'values get multiplied with the refresh factor
	'so this means: higher values increase the resulting topicality win
	Global genreRefreshModifier:float[] =  [	1.0, .. 	'action
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
	Global genreWearoffModifier:float[] =  [	1.0, .. 	'action
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

	const TYPE_SERIE:int			= 0
	const TYPE_MOVIE:int			= 1



	Function Create:TProgramme(title:String, description:String, actors:String, director:String, country:String, year:Int, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, xrated:Int, refreshModifier:float=1.0, wearoffModifier:float=1.0, episode:Int=0)
		Local obj:TProgramme =New TProgramme

		If episode >= 0
			obj.programmeType = TYPE_SERIE
			'only add parent of series
			If episode = 0 Then ProgSeriesList.AddLast(obj)
		Else
			obj.programmeType = TYPE_MOVIE
			ProgMovieList.AddLast(obj)
		EndIf

		obj.title		= title
		obj.description = description
		obj.episode		= episode
		obj.refreshModifier = Max(0.0, refreshModifier)
		obj.wearoffModifier = Max(0.0, wearoffModifier)
		obj.review      = Max(0,review)
		obj.speed       = Max(0,speed)
		obj.relPrice    = Max(0,relPrice)
		obj.outcome	    = Max(0,Outcome)
		obj.genre       = Max(0,Genre)
		obj.blocks      = Max(1,blocks)
		obj.xrated       = xrated
		obj.actors 		= actors
		obj.director    = director
		obj.country     = country
		obj.year        = year
		obj.liveHour    = Max(-1,livehour)
		obj.topicality  = obj.ComputeTopicality()
		obj.maxTopicality = obj.topicality

		obj.releaseDay = obj.releaseDayCounter mod TGame.daysPerYear
		obj.releaseDaycounter:+1

		ProgList.AddLast(obj)
		Return obj
	End Function


	Method AddEpisode:TProgramme(title:String, description:String, actors:String, director:String, country:String, year:Int, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, xrated:Int, refreshModifier:float=null, wearoffModifier:float=null, episode:Int=0, id:Int=0)
		Local obj:TProgramme = New TProgramme

		obj.title = title
		obj.description = description
		obj.programmeType = TYPE_SERIE | TYPE_EPISODE
		If review < 0 Then obj.review = Self.review Else obj.review = review
		If speed < 0 Then obj.speed = Self.speed Else obj.speed = speed
		If relPrice < 0 Then obj.relPrice = Self.relPrice Else obj.relPrice = relPrice
		If blocks < 0 Then obj.blocks = Self.blocks Else obj.blocks = blocks
		If year < 0	Then obj.year = Self.year Else obj.year = year
		obj.releaseDay = self.releaseDay
		If livehour < 0	Then obj.livehour = Self.livehour Else obj.livehour = livehour
		If genre < 0 Then obj.genre = Self.genre Else obj.genre = genre
		If actors = "" Then obj.actors = Self.actors Else obj.actors = actors
		If director = "" Then obj.director = Self.director Else obj.director = director
		If country = "" Then obj.country = Self.country Else obj.country = country
		If description = "" Then obj.description = Self.description Else obj.description = description

		If refreshModifier = null Then obj.refreshModifier = Self.refreshModifier Else obj.refreshModifier = Max(0.0, refreshModifier)
		If wearoffModifier = null Then obj.wearoffModifier = Self.wearoffModifier Else obj.wearoffModifier = Max(0.0, wearoffModifier)

		obj.topicality		= obj.ComputeTopicality()
		obj.maxtopicality	= obj.topicality

		obj.xrated       	= xrated
		obj.programmeType  	= TYPE_SERIE | TYPE_EPISODE
		If episode = 0 Then episode = Self.episodes.count()+1
		obj.episode			= episode
		obj.parent			= Self
		Self.episodes.AddLast(obj)
		ProgList.AddLast(obj)
		Return obj
	End Method


	Function setIgnoreUnreleasedProgrammes(ignore:int=TRUE, releaseStart:int=0, releaseEnd:int=0)
		TProgramme.ignoreUnreleasedProgrammes = ignore
		TProgramme._filterReleaseDateStart = releaseStart
		TProgramme._filterReleaseDateEnd = releaseEnd
	End Function


	Method GetParent:TProgramme()
		if not self.parent then return self
		return self.parent
	End Method


	Method GetNextEpisode:TProgramme()
	print "GetNextEpisode "+self.episode
		local episode:TProgramme = self.GetParent().GetEpisode(self.episode+1)
		if episode then return episode
		'if no next episode was found - return self
		return self
	End Method


	Method Sell:int()
		if not Game.IsPlayer(self.owner) then return FALSE

		Game.Players[self.owner].finances[Game.getWeekday()].SellMovie(self.getPrice())
		'set unused again
		self.owner = 0
		'DebugLog "Programme "+title +" sold"
		return TRUE
	End Method


	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int = -1)
		If playerID = -1 Then playerID = Game.playerID
		if not Game.IsPlayer(playerID) then return FALSE

		If Game.Players[playerID].finances[Game.getWeekday()].PayMovie(self.getPrice())
			self.owner = playerID
			Return TRUE
		EndIf
		Return FALSE
	End Method


	Method GetActor:string(number:int=1)
		number = max(1,number)
		local _array:string[] = self.actors.split(",")
		if _array.length >= number then return _array[number-1].trim()
		return _array[0]
	End Method


	Method GetDirector:string(number:int=1)
		number = max(1,number)
		local _array:string[] = self.director.split(",")
		if _array.length >= number then return _array[number-1].trim()
		return _array[0]
	End Method


	Method isReleased:int()
		if not self.ignoreUnreleasedProgrammes then return TRUE

		'call-in shows are kind of "live"
		if self.genre = GENRE_CALLINSHOW then return TRUE

		return (self.year <= Game.getYear() and self.releaseDay <= Game.getDay())
	End Method

	Function CountGenre:Int(Genre:Int, Liste:TList)
		Local genrecount:Int=0
		For Local movie:TProgramme= EachIn Liste
			If movie.Genre = Genre Then genrecount:+1
		Next
		Return genrecount
	End Function


	'returns the list to use for the given type
	'this is just important for "random" access as we could
	'also just access "progList" in all cases...
	Function _GetList:TList(programmeType:int=0)
		Select programmeType
			case 1	return ProgMovieList
			case 2	return ProgSeriesList
			default	return ProgList
		End Select
	End Function


	Function GetProgramme:TProgramme(id:Int, programmeType:int=0)
		local list:TList = _GetList(programmeType)
		local programme:TProgramme = null

		For Local i:Int = 0 To list.Count() - 1
			programme = TProgramme(list.ValueAtIndex(i))
			if programme and programme.id = id Then Return programme
		Next
		Return Null
	End Function


	Function GetRandomProgrammeFromList:TProgramme(_list:TList)
		If _list = Null Then Return Null
		If _list.count() > 0
			Local prog:TProgramme = TProgramme(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If prog then return prog
		EndIf
		Print "ProgrammeList empty - wrong filter ?"
		Return Null
	End Function


	Function GetRandomProgramme:TProgramme(programmeType:int=0)
		'filter to entries we need
		Local prog:TProgramme
		Local sourceList:TList = _GetList(programmeType)
		Local resultList:TList = CreateList()
		For prog = EachIn sourceList
			'ignore if filtered out
			if not prog.ignoreUnreleasedProgrammes AND prog.year < _filterReleaseDateStart OR prog.year > _filterReleaseDateEnd then continue
			If prog.owner <> 0 or not prog.isReleased() Then continue

			'if available (unbought, released..), add it to candidates list
			resultList.addLast(prog)
		Next
		Return GetRandomProgrammeFromList(resultList)
	End Function


	Function GetRandomProgrammeWithPrice:TProgramme(MinPrice:int=0, MaxPrice:Int=-1, programmeType:int=0)
		'filter to entries we need
		Local prog:TProgramme
		Local sourceList:TList = _GetList(programmeType)
		Local resultList:TList = CreateList()
		For prog = EachIn sourceList
			'ignore if filtered out
			if not prog.ignoreUnreleasedProgrammes AND prog.year < _filterReleaseDateStart OR prog.year > _filterReleaseDateEnd then continue
			If prog.owner <> 0 or not prog.isReleased() Then continue

			'skip if to expensive
			if MaxPrice > 0 and prog.getPrice() > MaxPrice then continue

			'if available (unbought, released..), add it to candidates list
			If prog.getPrice() >= MinPrice Then resultList.addLast(prog)
		Next
		Return GetRandomProgrammeFromList(resultList)
	End Function


	Function GetRandomProgrammeByGenre:TProgramme(genre:Int = 0, programmeType:int=0)
		Local prog:TProgramme
		Local sourceList:TList = _GetList(programmeType)
		Local resultList:TList = CreateList()
		For prog = EachIn sourceList
			'ignore if filtered out
			if not prog.ignoreUnreleasedProgrammes AND prog.year < _filterReleaseDateStart OR prog.year > _filterReleaseDateEnd then continue
			If prog.owner <> 0 or not prog.isReleased() Then continue

			'if available (unbought, released..), add it to candidates list
			If prog.genre = genre And prog.episode <= 0 Then resultList.addLast(prog)
		Next
		Return GetRandomProgrammeFromList(resultList)
	End Function


	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method


	Method SetAttractiveness(value:Float) {_exposeToLua}
		Self.attractiveness = value
	End Method


	Method GetRefreshModifier:float() {_exposeToLua}
		return self.refreshModifier
	End Method


	Method GetGenreRefreshModifier:float(genre:int=-1) {_exposeToLua}
		if genre = -1 then genre = self.genre
		if genre < self.genreRefreshModifier.length then return self.genreRefreshModifier[genre]
		'default is 1.0
		return 1.0
	End Method


	Method GetWearoffModifier:float() {_exposeToLua}
		return self.wearoffModifier
	End Method


	Method GetGenreWearoffModifier:float(genre:int=-1) {_exposeToLua}
		if genre = -1 then genre = self.genre
		if genre < self.genreWearoffModifier.length then return self.genreWearoffModifier[genre]
		'default is 1.0
		return 1.0
	End Method


	Method GetGenre:int() {_exposeToLua}
		return self.genre
	End Method


	Method GetGenreString:String(_genre:Int=-1) {_exposeToLua}
		If _genre > 0 Then Return GetLocale("MOVIE_GENRE_" + _genre)
		Return GetLocale("MOVIE_GENRE_" + Self.genre)
	End Method


	Method isMovie:int() {_exposeToLua}
		return self.programmeType = TYPE_MOVIE
	End Method


	Method GetXRated:int() {_exposeToLua}
		return (self.xrated <> "")
	End Method


	Method GetOutcome:int() {_exposeToLua}
		return self.outcome
	End Method


	Method GetSpeed:int() {_exposeToLua}
		return self.speed
	End Method


	Method GetReview:int() {_exposeToLua}
		return self.review
	End Method


	Method GetTopicality:int() {_exposeToLua}
		return self.topicality
	End Method


	Method GetEpisodeCount:int() {_exposeToLua}
		return self.episodes.count()
	End Method


	'Manuel: Wird nur in der Lua-KI verwendet
	Method GetPricePerBlock:Int() {_exposeToLua}
		Return Self.GetPrice() / Self.GetBlocks()
	End Method


	'Manuel: Wird nur in der Lua-KI verwendet
	Method GetQualityLevel:Int() {_exposeToLua}
		Local quality:Int = Self.GetQuality() * 100
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
	End Method


	'returns array of all episodes or an empty array if no episodes are found
	Method GetEpisodes:Object[]() {_exposeToLua}
		If Self.episodes
			Return Self.episodes.toArray()
		Else
			Return CreateList().toArray()
		EndIf
	End Method


	'returns episode if found
	'episode starts with 1 not 0 !
	Method GetEpisode:TProgramme(episodeNumber:Int) {_exposeToLua}
		'ignore episodes which cannot exist
		if episodeNumber<=0 then return Null
		if self.episodes.count() < episodeNumber then return Null

		If TProgramme(Self.episodes.ValueAtIndex(Max(0,episodeNumber-1))) <> Null Then Return TProgramme(Self.episodes.ValueAtIndex(Max(0,episodeNumber-1)))

		Return Null
	End Method


	Method ComputeTopicality:Float()
		Local value:Int = 0

		'parent of serie called
		If Self.episodes.count() > 0
			For Local episode:TProgramme = EachIn Self.episodes
				episode.topicality = episode.ComputeTopicality()
				value :+ episode.topicality
			Next
			topicality = value / Self.episodes.count()
		ElseIf topicality < 0
			topicality = Max(0, 255 - 2 * Max(0, Game.GetYear() - year) )   'simplest form ;D
		EndIf
		Return topicality
	End Method

	Method GetGenreDefinition:TMovieGenreDefinition()
		Return Game.BroadcastManager.GetMovieGenreDefinition(Genre)
	End Method	
	
	'Diese Methode ersetzt "GetBaseAudienceQuote"
	Method GetQuality:Float(luckFactor:Int = 1) {_exposeToLua}
		Local genreDef:TMovieGenreDefinition = GetGenreDefinition()
		Local quality:Float = 0.0
		
		If genreDef.OutcomeMod > 0.0 Then
			quality = Float(Outcome) / 255.0 * genreDef.OutcomeMod ..
				+ Float(review) / 255.0 * genreDef.ReviewMod ..
				+ Float(speed) / 255.0 * genreDef.SpeedMod
		Else
			quality = Float(review) / 255.0 * genreDef.ReviewMod ..
				+ Float(speed) / 255.0 * genreDef.SpeedMod
		EndIf

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0, 100 - Max(0, game.GetYear() - year))
		quality:*Max(0.10, (age / 100.0))
		
		'repetitions wont be watched that much
		quality:*(ComputeTopicality() / 255.0) ^ 2

		If luckFactor = 1 Then
			quality = quality * 0.98 + Float(RandRange(10, 20)) / 1000.0 '1%-Punkte bis 2%-Punkte Basis-Qualität
		Else
			quality = quality * 0.99 + 0.01 'Mindestens 1% Qualität
		EndIf
		
		'no minus quote
		quality = Max(0, quality)
		Return quality
	End Method

	rem
	'base quote of a programme
	Method GetBaseAudienceQuote:Float(lastquote:Float=0.1) {_exposeToLua}
		Local quality:Float		= 0.0

		If outcome > 0
			quality	=	 0.2	*Float(lastquote)..
						+0.35	*Float(Outcome)/255.0..
						+0.2	*Float(review)/255.0..
						+0.15	*Float(speed)/255.0..
		Else 'tv shows
			quality	=	 0.3	*Float(lastquote)..
						+0.4	*Float(review)/255.0..
						+0.3	*Float(speed)/255.0..
		EndIf
		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0,100-Max(0,game.GetYear() - year))
		quality:* Max(0.10, (age/ 100.0))
		'repetitions wont be watched that much
		quality	:*	(ComputeTopicality()/255.0)^2

		'no minus quote
		Return Max(0, quality)
	End Method


	'computes a percentage which could be multiplied with maxaudience
	Method GetAudienceQuote:Float(lastquote:Float=0, maxAudiencePercentage:Float=-1) {_exposeToLua}
		Local quote:Float		= self.getBaseAudienceQuote(lastquote)
		'a bit of luck :D
		quote	:+ Float(RandRange(-10,10))/1000.0 ' +/- 0.1-1%

		If maxAudiencePercentage = -1
			quote :* Game.BroadcastManager.maxAudiencePercentage
		Else
			quote :* maxAudiencePercentage
		EndIf

		'no minus quote
		Return Max(0, quote)
	End Method
endrem

	Method CutTopicality:Int(cutFactor:float=1.0)
		'cutFactor can be used to manipulate the resulting cut
		'eg for night times

		'cut of by an individual cutoff factor - do not allow values > 1.0 (refresh instead of cut)
		'the value : default * invidual * individualGenre
		topicality:* Min(1.0,  cutFactor * self.wearoffFactor * self.GetGenreWearoffModifier() * self.GetWearoffModifier() )
	End Method


	Method RefreshTopicality:Int()
		topicality = Min(maxtopicality, topicality*self.refreshFactor*self.GetGenreRefreshModifier()*self.GetRefreshModifier())
		Return topicality
	End Method


	Method getTargetGroup:int() {_exposeToLua}
		return self.targetGroup
	End Method


	Method GetTimesAired:Int() {_exposeToLua}
		return self.timesAired
	End Method


	Method GetPrice:Int() {_exposeToLua}
		Local value:Float
		Local tmpreview:Float
		Local tmpspeed:Float

		If Self.episodes.count() > 0
			For Local episode:TProgramme = EachIn Self.episodes
				value :+ episode.getPrice()
			Next
			value :* 0.75
		Else
			If Outcome > 0 'movies
				value = 0.55 * 255 * Outcome + 0.25 * 255 * review + 0.2 * 255 * speed
				If (maxTopicality >= 230) Then value:*1.4
				If (maxTopicality >= 240) Then value:*1.6
				If (maxTopicality >= 250) Then value:*1.8
				If (maxTopicality > 253)  Then value:*2.1 'the more current the more expensive
			Else 'shows, productions, series...
				If (review > 0.5 * 255) Then tmpreview = 255 - 2.5 * (review - 0.5 * 255) else tmpreview = 1.6667 * review
				If (speed > 0.6 * 255) Then tmpspeed = 255 - 2.5 * (speed - 0.6 * 255) else tmpspeed = 1.6667 * speed
				value = 1.3 * ( 0.45 * 255 * tmpreview + 0.55 * 255 * tmpspeed )
			EndIf
			value:*(1.5 * ComputeTopicality() / 255)
			value = Int(Floor(value / 1000) * 1000)
		EndIf
		Return value
	End Method


	Method ShowSheet:Int(x:Int,y:Int, plannerday:Int = -1, series:TProgramme=Null, align:int=0)
		Local widthbarspeed:Float		= Float(speed / 255)
		Local widthbarreview:Float		= Float(review / 255)
		Local widthbaroutcome:Float		= Float(Outcome/ 255)
		Local widthbartopicality:Float	= Float(Float(topicality) / 255)
		Local widthbarMaxTopicality:Float= Float(Float(MaxTopicality) / 255)
		Local normalFont:TBitmapFont	= Assets.fonts.baseFont

		Local dY:Int = 0

		If isMovie()
			if align=1 then x :- Assets.GetSprite("gfx_datasheets_movie").w

			Assets.GetSprite("gfx_datasheets_movie").Draw(x,y)
			Assets.fonts.basefontBold.drawBlock(title, x + 10, y + 11, 278, 20)
		Else
			if align=1 then x :- Assets.GetSprite("gfx_datasheets_series").w

			Assets.GetSprite("gfx_datasheets_series").Draw(x,y)
			'episode display
			If series <> Null
				Assets.fonts.basefontBold.drawBlock(series.title, x + 10, y + 11, 278, 20)
				normalFont.drawBlock("(" + episode + "/" + series.episodes.count() + ") " + title, x + 10, y + 34, 278, 20, 0)  'prints programmedescription on moviesheet
			Else
				Assets.fonts.basefontBold.drawBlock(title, x + 10, y + 11, 278, 20)
				normalFont.drawBlock(episodes.count()+" "+GetLocale("MOVIE_EPISODES") , x+10,  y+34 , 278, 20,0) 'prints programmedescription on moviesheet
			EndIf

			dy :+ 22
		EndIf
		If Self.xrated <> 0 Then normalFont.drawBlock(GetLocale("MOVIE_XRATED") , x+240 , y+dY+34 , 50, 20,0) 'prints pg-rating

		normalFont.drawBlock(GetLocale("MOVIE_DIRECTOR")+":", x+10 , y+dY+135, 280, 16,0)
		normalFont.drawBlock(GetLocale("MOVIE_SPEED")       , x+222, y+dY+187, 280, 16,0)
		normalFont.drawBlock(GetLocale("MOVIE_CRITIC")      , x+222, y+dY+210, 280, 16,0)
		normalFont.drawBlock(GetLocale("MOVIE_BOXOFFICE")   , x+222, y+dY+233, 280, 16,0)
		normalFont.drawBlock(director         , x+10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":")) , y+dY+135, 280-15-normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":"), 16,0) 	'prints director
		if actors <> ""
			normalFont.drawBlock(GetLocale("MOVIE_ACTORS")+":"  , x+10 , y+dY+148, 280, 32,0)
			normalFont.drawBlock(actors           , x+10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":")), y+dY+148, 280-15-normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":"), 32,0) 	'prints actors
		endif
		normalFont.drawBlock(GetGenreString(Genre)  , x+78 , y+dY+35 , 150, 16,0) 	'prints genre
		normalFont.drawBlock(country          , x+10 , y+dY+35 , 150, 16,0)		'prints country
		If genre <> GENRE_CALLINSHOW
			normalFont.drawBlock(year		      , x+36 , y+dY+35 , 150, 16,0) 	'prints year
			normalFont.drawBlock(description      , x+10,  y+dy+56 , 278, 70,0) 'prints programmedescription on moviesheet
		Else
			normalFont.drawBlock(description      , x+10,  y+dy+56 , 278, 50,0) 'prints programmedescription on moviesheet
			normalFont.drawBlock(getLocale("MOVIE_CALLINSHOW")      , x+10,  y+dy+106 , 278, 20,0) 'prints programmedescription on moviesheet
		EndIf
		normalFont.drawBlock(GetLocale("MOVIE_TOPICALITY")  , x+84, y+281, 40, 16,0)
		normalFont.drawBlock(GetLocale("MOVIE_BLOCKS")+": "+blocks, x+10, y+281, 100, 16,0)
		if Game.getPlayer().getFinancial().canAfford(self.getPrice()) OR self.owner = Game.playerID
			normalFont.drawBlock(self.GetPrice(), x+240, y+281, 120, 20,0)
		else
			normalFont.drawBlock(self.GetPrice(), x+240, y+281, 120, 20,0, 200,0,0)
		endif

		If widthbarspeed  >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbarspeed*200,	y+dY+188,		x+13, y+dY+187, 200, 12)
		If widthbarreview >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbarreview*200,y+dY+210,		x+13, y+dY+209, 200, 12)
		If widthbaroutcome>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbaroutcome*200,y+dY+232,		x+13, y+dY+231, 200, 12)
		SetAlpha 0.3
		If widthbarMaxTopicality>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+115 - 200 + widthbarMaxTopicality*100,y+280,	x+115, y+279, 100,12)
		SetAlpha 1.0
		If widthbartopicality>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+115 - 200 + widthbartopicality*100,y+280,	x+115, y+279, 100,12)
	End Method
End Type



Type TNewsEvent Extends TBroadcastMaterial {_exposeToLua="selected"}
	Field genre:Int				= 0
	Field quality:Int			= 0
	Field price:Int				= 0
	Field episode:Int			= 0
	Field episodes:TList		= CreateList()	
	Field happenedTime:Double	= -1
	Field happenDelayData:int[]	= [5,0,0,0]			'different params for delay generation
	Field happenDelayType:int	= 2					'what kind of delay do we have? 2 = hours
	Field parent:TNewsEvent		= Null				'is this news a child of a chain?

	Global usedList:TList		= CreateList()		'holding already announced news
	Global List:TList			= CreateList()		'holding single news and first/parent of news-chains (start)


	Function Create:TNewsEvent(title:String, description:String, Genre:Int, quality:Int=0, price:Int=0)
		Local obj:TNewsEvent =New TNewsEvent
		obj.title       = title
		obj.description = description
		obj.genre       = Genre
		obj.episode     = 0
		obj.quality     = quality
		obj.price       = price

		List.AddLast(obj)
		Return obj
	End Function

	Method AddEpisode:TNewsEvent(title:String, description:String, Genre:Int, episode:Int=0,quality:Int=0, price:Int=0, id:Int=0)
		Local obj:TNewsEvent =New TNewsEvent
		obj.title       = title
		obj.description = description
		obj.Genre       = Genre
		obj.quality     = quality
		obj.price       = price

	    obj.episode     = episode
		obj.parent		= Self

		obj.happenDelayType		= 2 'data is hours
		obj.happenDelayData[0]	= 5 '5hrs default
		'add to parent
		Self.episodes.AddLast(obj)
		SortList(Self.episodes)

		'list.AddLast(obj)
		Return obj
	End Method

	'returns the next news out of a chain
	Method GetNextNewsEventFromChain:TNewsEvent()
		Local news:TNewsEvent=Null
		'if element is an episode of a chain
		If self.parent
			news = TNewsEvent(self.parent.episodes.ValueAtIndex(Max(0,self.episode -1)))
		'if it is the parent of a chain
		elseif self.episodes.count() > 0
			news = TNewsEvent(self.episodes.ValueAtIndex(0))
		endif
		if news
			news.doHappen()
			Return news
		endif
		'if something strange happens - better return self than nothing
		return self
	End Method


	Function Get:TNewsEvent(id:Int)
		Local news:TNewsEvent = Null
		For Local i:Int = 0 To List.Count()-1
			news = TNewsEvent(List.ValueAtIndex(i))
			If news and news.id = id
				news.doHappen()
				Return news
			endif
		Next
		Return Null
	End Function


	Function SetOldNewsUnused(daysAgo:int=1)
		For local news:TNewsEvent = eachin usedList
			if abs(Game.GetDay(news.happenedTime) - Game.GetDay()) >= daysAgo
				usedList.Remove(news)
				list.addLast(news)
				news.happenedTime = -1
			endif
		Next
	End Function


	Function GetRandom:TNewsEvent()
		'if no news is available, make older ones available again
		if List.Count() = 0 then SetOldNewsUnused(7)
		'if there is still nothing - also accept younger ones
		if List.Count() = 0 then SetOldNewsUnused(2)

		if List.Count() = 0 then print "NO ELEMENTS IN NEWSEVENT LIST!!"

		'fetch a random news
		Local news:TNewsEvent = TNewsEvent(List.ValueAtIndex((randRange(0, List.Count() - 1))))

		news.doHappen()

		'Print "get random news: "+news.title + " ("+news.episode+"/"+news.getEpisodesCount()+")"
		Return news
	End Function


	Function GetGenreString:String(Genre:Int)
		If Genre = 0 Then Return GetLocale("NEWS_POLITICS_ECONOMY")
		If Genre = 1 Then Return GetLocale("NEWS_SHOWBIZ")
		If Genre = 2 Then Return GetLocale("NEWS_SPORT")
		If Genre = 3 Then Return GetLocale("NEWS_TECHNICS_MEDIA")
		If Genre = 4 Then Return GetLocale("NEWS_CURRENTAFFAIRS")
		Return Genre+ " unbekannt"
	End Function


	Method getHappenDelay:int()
		'data is days from now
		if self.happenDelayType = 1 then return self.happenDelayData[0]*60*24
		'data is hours from now
		if self.happenDelayType = 2 then return self.happenDelayData[0]*60
		'data is days from now at X:00
		if self.happenDelayType = 3
			local time:int = Game.MakeTime(Game.GetYear(), Game.GetDayOfYear() + self.happenDelayData[0], self.happenDelayData[1],0)
			return time - Game.getTimeGone()
		endif

		return 0
	End Method


	Method doHappen(time:int = 0)
		'nothing set - use "now"
		if time = 0 then time = Game.timegone

		self.happenedtime = time
		if not self.parent
			self.usedList.addLast(self)
			self.list.remove(self)
		endif
	End Method


	Method getEpisodesCount:int()
		if self.parent then return self.parent.episodes.Count()
		return self.episodes.Count()
	End Method


	Method isLastEpisode:int()
		return self.parent<>null and self.episode = self.parent.episodes.count()
	End Method


	Method ComputeTopicality:Float()
		'the older the less ppl want to watch - 1hr = 0.95%, 2hr = 0.90%...
		'means: after 20 hrs, the topicality is 0
		local ageHours:int = floor( float(Game.GetTimeGone() - self.happenedTime)/60.0 )
		Local age:float = Max(0,100-5*Max(0, ageHours) )
		return age*2.55 ',max is 255
	End Method


	Method GetAttractiveness:Float() {_exposeToLua}
		Return 0.30*((quality+5)/255) + 0.4*ComputeTopicality()/255 + 0.2*price/255 + 0.1
	End Method

	rem
	'base quote of a programme
	Method GetBaseAudienceQuote:Float(lastquote:Float=0.1) {_exposeToLua}
		Local quality:Float		= 0.0

		quality	=	 0.10	*Float(lastquote)..
					+0.40	*Float(self.ComputeTopicality())/255.0..
					+0.30	*Float(quality)/255.0..
					+0.20	*Float(price)/255.0

		'no minus quote
		Return Max(0, quality)
	End Method


	'computes a percentage which could be multiplied with maxaudience
	Method GetAudienceQuote:Float(lastquote:Float=0, maxAudiencePercentage:Float=-1) {_exposeToLua}
		Local quote:Float		= self.getBaseAudienceQuote(lastquote)
		'a bit of luck :D
		quote	:+ Float(RandRange(-10,10))/1000.0 ' +/- 0.1-1%

		If maxAudiencePercentage = -1
			quote :* Game.BroadcastManager.maxAudiencePercentage
		Else
			quote :* maxAudiencePercentage
		EndIf

		'no minus quote
		Return Max(0, quote)
	End Method
	endrem
rem
	'computes a percentage which could be multiplied with maxaudience
	Method ComputeAudienceQuote:Float(lastquote:Float=0)
		Local quote:Float =0.0
		If lastquote < 0 Then lastquote = 0
			quote = 0.1*lastquote + 0.35*((quality+5)/255) + 0.5*ComputeTopicality()/255 + 0.05*(rand(0,254)+1)/255
		Return quote * Game.maxAudiencePercentage
	End Method
endrem


	Method ComputePrice:Int() {_exposeToLua}
		'price ranges from 0-10.000
		Return 100 * ceil( 100 * float(0.6*quality + 0.3*price + 0.1*self.ComputeTopicality())/255.0 )
		'Return Floor(Float(quality * price / 100 * 2 / 5)) * 100 + 1000  'Teuerstes in etwa 10000+1000
	End Method
End Type


Type TDatabase
	Field file:String
	Field moviescount:Int
	Field totalmoviescount:Int
	Field seriescount:Int
	Field newscount:Int
	Field totalnewscount:Int
	Field contractscount:Int

	Function Create:TDatabase()
		Local Database:TDatabase=New TDatabase
		Database.file				= ""
		Database.moviescount   		= 0
		Database.totalmoviescount	= 0
		Database.seriescount		= 0
		Database.newscount			= 0
		Database.contractscount		= 0
		Return Database
	End Function


	Method Load(filename:String)
		Local title:String
		Local description:String
		Local actors:String
		Local director:String
		Local land:String
		Local year:Int
		Local Genre:Int
		Local duration:Int
		Local xrated:Int
		Local price:Int
		Local review:Int
		Local speed:Int
		Local Outcome:Int
		Local livehour:Int
		local refreshModifier:float = 1.0
		local wearoffModifier:float = 1.0

		Local daystofinish:Int
		Local spotcount:Int
		Local targetgroup:Int
		Local minimage:Int
		Local minaudience:Int
		Local fixedPrice:Int
		Local profit:Int
		Local penalty:Int

		Local quality:Int


		Local xml:TXmlHelper = TXmlHelper.Create(filename)
		Local nodeParent:TxmlNode
		Local nodeChild:TxmlNode
		Local nodeEpisode:TxmlNode
		Local listChildren:TList
		Local loadError:String = ""



		'---------------------------------------------
		'importing all movies
		'Print "reading movies from database"
		nodeParent		= xml.FindRootChild("allmovies")
		loadError		= "Problems loading movies. Check database.xml"
		If nodeParent <> Null
			listChildren = nodeParent.getChildren()
			If listChildren = Null Then Throw loadError

			For nodeChild = EachIn listChildren
				If nodeChild.getName() = "movie"
					title       = xml.FindValue(nodeChild,"title", "unknown title")
					description = xml.FindValue(nodeChild,"description", "23")
					actors      = xml.FindValue(nodeChild,"actors", "")
					director    = xml.FindValue(nodeChild,"director", "")
					land        = xml.FindValue(nodeChild,"country", "UNK")
					year 		= xml.FindValueInt(nodeChild,"year", 1900)
					Genre 		= xml.FindValueInt(nodeChild,"genre", 0 )
					duration    = xml.FindValueInt(nodeChild,"blocks", 2)
					xrated 		= xml.FindValueInt(nodeChild,"xrated", 0)
					price 		= xml.FindValueInt(nodeChild,"price", 0)
					review 		= xml.FindValueInt(nodeChild,"critics", 0)
					speed 		= xml.FindValueInt(nodeChild,"speed", 0)
					Outcome 	= xml.FindValueInt(nodeChild,"outcome", 0)
					livehour 	= xml.FindValueInt(nodeChild,"time", 0)
					refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", 1.0)
					wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", 1.0)
					If duration < 0 Or duration > 12 Then duration =1
					TProgramme.Create(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, xrated, refreshModifier, wearoffModifier, -1)
					'print "film: "+title+ " " + Database.totalmoviescount
					Database.totalmoviescount :+ 1
				EndIf
			Next
		Else
			Throw loadError
		EndIf

		'---------------------------------------------
		'importing all series including their episodes
		nodeParent		= xml.FindRootChild("allseries")
		'Print "reading series from database"
		loadError		= "Problems loading series. Check database.xml"
		If nodeParent = Null Then Throw loadError
		listChildren = nodeParent.getChildren()
		If listChildren = Null Then Throw loadError
		For nodeChild = EachIn listChildren
			If nodeChild.getName() = "serie"
				'load series main data
				title       = xml.FindValue(nodeChild,"title", "unknown title")
				description = xml.FindValue(nodeChild,"description", "")
				actors      = xml.FindValue(nodeChild,"actors", "")
				director    = xml.FindValue(nodeChild,"director", "")
				land        = xml.FindValue(nodeChild,"country", "UNK")
				year 		= xml.FindValueInt(nodeChild,"year", 1900)
				Genre 		= xml.FindValueInt(nodeChild,"genre", 0)
				duration    = xml.FindValueInt(nodeChild,"blocks", 2)
				xrated 		= xml.FindValueInt(nodeChild,"xrated", 0)
				price 		= xml.FindValueInt(nodeChild,"price", -1)
				review 		= xml.FindValueInt(nodeChild,"critics", -1)
				speed 		= xml.FindValueInt(nodeChild,"speed", -1)
				Outcome 	= xml.FindValueInt(nodeChild,"outcome", -1)
				livehour 	= xml.FindValueInt(nodeChild,"time", -1)
				refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", 1.0)
				wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", 1.0)
				If duration < 0 Or duration > 12 Then duration =1
				Local parent:TProgramme = TProgramme.Create(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, xrated, refreshModifier, wearoffModifier, 0)
				Database.seriescount :+ 1

				'load episodes
				Local EpisodeNum:Int = 0
				Local listEpisodes:TList = nodeChild.getChildren()
				If listEpisodes <> Null And listEpisodes.count() > 0
					For nodeEpisode = EachIn listEpisodes
						If nodeEpisode.getName() = "episode"
							EpisodeNum	= xml.FindValueInt(nodeEpisode,"number", EpisodeNum+1)
							title      	= xml.FindValue(nodeEpisode,"title", "")
							description = xml.FindValue(nodeEpisode,"description", description)
							actors      = xml.FindValue(nodeEpisode,"actors", "")
							director    = xml.FindValue(nodeEpisode,"director", "")
							land        = xml.FindValue(nodeEpisode,"country", "")
							year 		= xml.FindValueInt(nodeEpisode,"year", -1)
							Genre 		= xml.FindValueInt(nodeEpisode,"genre", -1)
							duration    = xml.FindValueInt(nodeEpisode,"blocks", -1)
							xrated 		= xml.FindValueInt(nodeEpisode,"xrated", xrated)
							price 		= xml.FindValueInt(nodeEpisode,"price", -1)
							review 		= xml.FindValueInt(nodeEpisode,"critics", -1)
							speed 		= xml.FindValueInt(nodeEpisode,"speed", -1)
							Outcome 	= xml.FindValueInt(nodeEpisode,"outcome", -1)
							livehour	= xml.FindValueInt(nodeEpisode,"time", -1)
							refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", 1.0)
							wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", 1.0)
							'add episode to last added serie
							'print "serie: --- episode:"+duration + " " + title
							parent.AddEpisode(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, xrated, refreshModifier, wearoffModifier, EpisodeNum)
						EndIf
					Next
				EndIf
			EndIf
		Next

		'---------------------------------------------
		'importing all ads
		nodeParent		= xml.FindRootChild("allads")
		'Print "reading ads from database"
		loadError		= "Problems loading ads. Check database.xml"
		If nodeParent = Null Then Throw loadError

		listChildren = nodeParent.getChildren()
		If listChildren = Null Then Throw loadError
		For nodeChild = EachIn listChildren
			If nodeChild.getName() = "ad"
				title       = xml.FindValue(nodeChild,"title", "unknown title")
				description = xml.FindValue(nodeChild,"description", "")
				targetgroup = xml.FindValueInt(nodeChild,"targetgroup", 0)
				spotcount	= xml.FindValueInt(nodeChild,"repetitions", 1)
				minaudience	= xml.FindValueInt(nodeChild,"minaudience", 0)
				minimage	= xml.FindValueInt(nodeChild,"minimage", 0)
				fixedPrice	= xml.FindValueInt(nodeChild,"fixedprice", 0)
				profit	    = xml.FindValueInt(nodeChild,"profit", 0)
				penalty		= xml.FindValueInt(nodeChild,"penalty", 0)
				daystofinish= xml.FindValueInt(nodeChild,"duration", 1)

				new TAdContractBase.Create(title, description, daystofinish, spotcount, targetgroup, minaudience, minimage, fixedPrice, profit, penalty)
				'print "contract: "+title+ " " + Database.contractscount
				Database.contractscount :+ 1
			EndIf
		Next


		'---------------------------------------------
		'importing all news including their chains
		nodeParent		= xml.FindRootChild("allnews")
		'Print "reading news from database"
		loadError		= "Problems loading news. Check database.xml"
		If nodeParent = Null Then Throw loadError
		listChildren = nodeParent.getChildren()
		If listChildren = Null Then Throw loadError
		For nodeChild = EachIn listChildren
			If nodeChild.getName() = "news"
				'load series main data
				title       = xml.FindValue(nodeChild,"title", "unknown newstitle")
				description	= xml.FindValue(nodeChild,"description", "")
				genre		= xml.FindValueInt(nodeChild,"genre", 0)
				quality		= xml.FindValueInt(nodeChild,"topicality", 0)
				price		= xml.FindValueInt(nodeChild,"price", 0)
				Local parentNewsEvent:TNewsEvent = TNewsEvent.Create(title, description, Genre, quality, price)

				'load episodes
				Local EpisodeNum:Int = 0
				Local listEpisodes:TList = nodeChild.getChildren()
				If listEpisodes <> Null And listEpisodes.count() > 0
					For nodeEpisode = EachIn listEpisodes
						If nodeEpisode.getName() = "episode"
							EpisodeNum		= xml.FindValueInt(nodeEpisode,"number", EpisodeNum+1)
							title			= xml.FindValue(nodeEpisode,"title", "unknown Newstitle")
							description		= xml.FindValue(nodeEpisode,"description", "")
							genre			= xml.FindValueInt(nodeEpisode,"genre", genre)
							quality			= xml.FindValueInt(nodeEpisode,"topicality", quality)
							price			= xml.FindValueInt(nodeEpisode,"price", price)
							parentNewsEvent.AddEpisode(title,description, Genre, EpisodeNum,quality, price)
							Database.totalnewscount :+1
						EndIf
					Next
					Database.newscount :+ 1
					Database.totalnewscount :+1
				EndIf
			EndIf
		Next

		Print("found " + Database.seriescount+ " series, "+Database.totalmoviescount+ " movies, "+ Database.contractscount + " advertisements, " + Database.totalnewscount + " news")
	End Method
End Type





Type TAdBlock Extends TBlockGraphical
	Field airedState:Int 			= 0			'indicator when the block got aired
    Field blocks:Int				= 1
    Field botched:int				= 0			'did the block run successful or failed it?
    Field senddate:Int				=-1			'which day this ad is planned to be send?
    Field sendtime:Int				=-1			'which time this ad is planned to be send?
    Field contract:TAdContract		= Null		{_exposeToLua}
    Global DragAndDropList:TList	= CreateList()
    Global spriteBaseName:String	= "pp_adblock1"

    Global draggedList:TList		= CreateList() 'so it can get managed again


	Function Create:TAdBlock(contract:TAdContract = Null, x:Int, y:Int, owner:Int)
		If owner < 0 Then owner = game.playerID

		local obj:TAdBlock = new TAdBlock
		obj.rect 		= TRectangle.Create(x, y, Assets.GetSprite("pp_adblock1").w, Assets.GetSprite("pp_adblock1").h)
		obj.StartPos	= TPoint.Create(x, y)
		obj.owner		= owner

		obj.SetDragable(1)
		obj.senddate	= Game.daytoplan
		obj.sendtime	= obj.GetTimeOfBlock()

		If not contract then contract = Game.Players[owner].ProgrammeCollection.GetRandomAdContract()
		obj.contract	= contract

		'store the object in the players plan
		Game.Players[owner].ProgrammePlan.AddAdblock(obj)
		Return obj
	End Function


	Function CreateDragged:TAdBlock(contract:TAdContract, owner:Int=-1)
		Local obj:TAdBlock = TAdBlock.Create(contract, MouseManager.x, MouseManager.y, owner)

		'remove from managed
		Game.Players[obj.owner].ProgrammePlan.RemoveAdblock(obj)
		'and add to dragged-manage
		obj.draggedList.addLast(obj)

		'things differing from normal
		obj.StartPos		= TPoint.Create(0, 0)
		obj.sendtime 		= 100
		obj.dragged			= 1
		Return obj
	End Function


	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method


	Function Sort:Int(o1:Object, o2:Object)
		Local s1:TAdBlock = TAdBlock(o1)
		Local s2:TAdBlock = TAdBlock(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (10000*s1.dragged + (s1.sendtime + 25*s1.senddate))-(10000*s2.dragged + (s2.sendtime + 25*s2.senddate))
	End Function


	Function GetBlockX:Int(time:Int)
		If time < 12 Then Return 67 + Assets.GetSprite("pp_programmeblock1").w
		Return 394 + Assets.GetSprite("pp_programmeblock1").w
	End Function

	Function GetBlockY:Int(time:Int)
		If time < 12 Then Return time * 30 + 17
		Return (time - 12) * 30 + 17
	End Function

    Method GetTimeOfBlock:Int(_x:Int = 1000, _y:Int = 1000)
		If StartPos.x = 589
			Return 12+(Int(Floor(StartPos.y - 17) / 30))
		Else If StartPos.x = 262
			Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	EndIf
    	Return -1
    End Method

	'loops through the list (eg. convert to playerprogrammeplan)
	'and gets the spot number the block will hold
	Method GetSpotNumber:int()
		'list is ordered by sendtime and dragged state
		'the older the earlier -> leave the loop if meeting self
		local spotNumber:int = 1
		For local obj:TAdBlock = eachin Game.Players[ self.owner ].ProgrammePlan.AdBlocks
			'different contract - skip it
			if obj.contract <> self.contract then continue
			'reached self - finish
			if obj = self then return spotNumber
			'other adblock from that contract - get it if not a failed one
			if not obj.isBotched() then spotNumber :+1
		Next
		return spotNumber
	End Method

    'draw the Adblock inclusive text
    'zeichnet den Programmblock inklusive Text
    Method Draw()
		'Draw dragged Adblockgraphic
		If dragged = 1 Or senddate = Game.daytoplan 'out of gameplanner
			If airedState = 0 Then SetColor 255,255,255 'normal
			If airedState = 1 Then SetColor 200,255,200 'runned
			If airedState = 2 Then SetColor 250,230,120 'running
			If airedState = 4 Then SetColor 255,255,255 'old day

			'if botched - set to red
			If self.isAired() and self.isBotched() then SetColor 255, 200, 200

			Local variant:String = ""
			If dragged = 1 And not self.isAired()
				If TAdBlock.AdditionallyDragged >0 Then SetAlpha 1- (1/TAdBlock.AdditionallyDragged * 0.25)
				variant = "_dragged"
			EndIf
			Assets.GetSprite("pp_adblock1"+variant).Draw(rect.GetX(), rect.GetY())

			'draw graphic

			SetColor 0,0,0
			Assets.fonts.basefontBold.drawBlock(contract.GetTitle(), rect.position.GetIntX()+3, rect.position.GetIntY()+2, rect.GetW()-5, 18, 0, 0, 0, 0, True)
			SetColor 80,80,80
			local spotNumber:int	= self.GetSpotNumber()
			local spotCount:int		= self.contract.GetSpotCount()
			Local text:String		= spotNumber + "/" + spotCount + "  ["+contract.id+"] "
			If self.isAired() and not self.isBotched() And spotNumber = spotCount
				text = "- OK -"
			ElseIf self.isBotched()
				text = "------"
			EndIf
			Assets.fonts.baseFont.draw(text ,rect.position.GetIntX()+5,rect.position.GetIntY()+18)
			SetColor 255,255,255 'eigentlich alte Farbe wiederherstellen
			SetAlpha 1.0
		EndIf 'same day or dragged
    End Method

	Function DrawAll(owner:Int =-1)
		if owner = -1 then owner = game.playerID

		local AdBlockList:TList = MergeLists( Game.Players[ owner ].ProgrammePlan.AdBlocks, TAdBlock.draggedList )
		AdBlockList.sort(True, TAdblock.sort)

		For Local AdBlock:TAdBlock = EachIn AdBlockList
			AdBlock.Draw()
		Next
	End Function

	'get bool wether adblock airing failed to fulfill the contracts requirements
	Method isBotched:int() {_exposeToLua}
		return self.botched
	end Method

	Method setBotched:int(bool:int=1)
		self.botched = bool
	End Method

	Method isAired:int() {_exposeToLua}
		Select self.airedState
			case 4,1,2	return True			'4 = old day, 1 = runned, 2 = running
			default		return False
		end Select
	End Method

	Method Update()
		If dragged = 1 Or senddate = Game.daytoplan 'out of gameplanner
			self.airedState = 1
			If Game.GetDay() > Game.daytoplan Then self.airedState = 4 'old day
			If Game.GetDay() < Game.daytoplan Then self.airedState = 0 'normal
			If Game.GetDay() = Game.daytoplan
				If GetTimeOfBlock() > (Int(Floor((Game.minutesOfDayGone-55) / 60))) Then self.airedState = 0  'normal
				If GetTimeOfBlock() = (Int(Floor((Game.minutesOfDayGone-55) / 60))) Then self.airedState = 2  'running
				If GetTimeOfBlock() < (Int(Floor((Game.minutesOfDayGone) / 60)))    Then self.airedState = 1  'runned
				If GetTimeOfBlock() < 0      									    Then self.airedState = 0  'normal
			EndIf

			if not self.isAired() then self.SetDragable(1) else self.SetDragable(0)
		endif
	End Method

	Function UpdateAll(owner:Int = -1, gfxListenabled:int, programmeListOpen:int)
		Local havetosort:Byte = 0
		Local number:Int = 0

		if owner = -1 then owner = game.playerID

		local AdBlockList:TList = MergeLists( Game.Players[ owner ].ProgrammePlan.AdBlocks, TAdBlock.draggedList )
		AdBlockList.sort(True, TAdblock.sort)

		'get current states
		For Local AdBlock:TAdBlock = EachIn AdBlockList
			AdBlock.Update()
		Next

'RON
		TAdBlock.AdditionallyDragged = 0
		For Local AdBlock:TAdBlock = EachIn AdBlockList
			number :+ 1
			If AdBlock.dragged = 1
				AdBlock.senddate = Game.daytoplan
			endif
			If not programmeListOpen And MOUSEMANAGER.IsHit(2) And AdBlock.dragged = 1
				'Game.IsMouseRightHit = 0
				'should not be needed as long as DRAGGED objects
				'are already removed
				print "rightclick adblock.removeFromPlan"
				Adblock.RemoveFromPlan()

				self.draggedList.remove(Adblock)

				havetosort = 1
				MOUSEMANAGER.resetKey(2)
			EndIf
			If Adblock.dragged And Adblock.StartPos.x>0 And Adblock.StartPos.y >0
				If Adblock.GetTimeOfBlock() < game.GetHour() Or (Adblock.GetTimeOfBlock() = game.GetHour() And game.GetMinute() >= 55)
					Adblock.dragged = False
				EndIf
			EndIf

			If not gfxListenabled And MOUSEMANAGER.IsHit(1)
				If AdBlock.dragged = 0 And AdBlock.dragable = 1 And not Adblock.isAired()
					If Adblock.senddate = game.daytoplan
						If AdBlock.rect.containsXY( MouseManager.x, MouseManager.y )
							AdBlock.dragged = 1
							For Local OtherlocObject:TAdBlock = EachIn AdBlockList
								If OtherLocObject.dragged And OtherLocObject <> Adblock
									TPoint.SwitchPos(AdBlock.StartPos, OtherlocObject.StartPos)
									OtherLocObject.dragged = 1
									If OtherLocObject.GetTimeOfBlock() < game.GetHour() And game.GetMinute() >= 55
										OtherLocObject.dragged = 0
									EndIf
								End If
							Next
							'removes the whole adblock from the plan
							'but it also sets it unmanaged
							'print "Adblock.RemoveFromPlan: "+Adblock.contract.contract.title
							Adblock.RemoveFromPlan()
							'that is why we add it to a special list
							TAdblock.draggedList.addLast(Adblock)
						EndIf
					EndIf
				Else
					Local DoNotDrag:Int = 0
					If not programmeListOpen And MOUSEMANAGER.IsHit(1) And not Adblock.isAired()
						'Print ("X:"+Adblock.x+ " Y:"+Adblock.y+" time:"+Adblock.GetTimeOfBlock(Adblock.x,Adblock.y))' > game.GetHour())
						AdBlock.dragged = 0
						For Local DragAndDrop:TDragAndDrop = EachIn TAdBlock.DragAndDropList
							If DragAndDrop.CanDrop(MouseManager.x,MouseManager.y,"adblock")
								For Local OtherAdBlock:TAdBlock = EachIn AdBlockList
									'is there a Adblock positioned at the desired place?
									If MOUSEMANAGER.IsHit(1) And OtherAdBlock.dragable = 1 And OtherAdBlock.rect.getX() = DragAndDrop.pos.getX()
										If OtherAdblock.senddate = game.daytoplan
											If OtherAdBlock.rect.GetY() = DragAndDrop.pos.getY()
												If not OtherAdBlock.isAired()
													OtherAdBlock.dragged = 1

													'print "otherAdblock.RemoveFromPlan: "+otherAdblock.contract.contract.title
													'removes the whole adblock from the plan
													'but it also sets it unmanaged
													otherAdblock.RemoveFromPlan()
													'that is why we add it to a special list
													TAdblock.draggedList.addLast(otherAdblock)

													havetosort = 1
												Else
													DoNotDrag = 1
												EndIf
											EndIf
										EndIf
									EndIf
									If havetosort then Exit
								Next
								If DoNotDrag <> 1
									Local oldPos:TPoint = TPoint.CreateFromPos(AdBlock.StartPos)
									AdBlock.startPos.SetPos(DragAndDrop.pos)
									If Adblock.GetTimeOfBlock() < Game.GetHour() Or (Adblock.GetTimeOfBlock() = Game.GetHour() And Game.GetMinute() >= 55)
										adblock.dragged = True
										If AdBlock.startPos.isSame(oldPos) Then Adblock.dragged = False
										AdBlock.StartPos.setPos(oldPos)
										MOUSEMANAGER.resetKey(1)
									Else
										AdBlock.StartPos.setPos(oldPos)
										Adblock.rect.position.SetPos(DragAndDrop.pos)
										AdBlock.StartPos.SetPos(AdBlock.rect.position)
									EndIf
									Exit 'exit loop-each-dragndrop, we've already found the right position
								EndIf
							EndIf
						Next
						If AdBlock.IsAtStartPos()
							AdBlock.rect.position.SetPos(AdBlock.StartPos)
							AdBlock.dragged 	= 0
							AdBlock.sendtime	= Adblock.GetTimeOfBlock()
							AdBlock.senddate	= Game.daytoplan
							'print "Adblock.AddToPlan: "+Adblock.contract.contract.title
							'remove it from the special list, block is
							'getting managed again
							TAdblock.draggedList.remove(adblock)

							Adblock.AddToPlan()
							'if a special key is pressed, create another
							'dragged block - so we can "plan" faster
							if KEYMANAGER.IsDown(KEY_LCONTROL) OR KEYMANAGER.IsDown(KEY_RCONTROL)
								TAdBlock.CreateDragged(Adblock.contract)
								'MOUSEMANAGER.resetKey(1)
							endif
						EndIf
					EndIf
				EndIf
			EndIf

			If AdBlock.dragged = 1
				Adblock.airedState = 0
				TAdBlock.AdditionallyDragged:+1
				AdBlock.rect.position.SetXY(..
					MouseManager.x - AdBlock.rect.GetW()/2 - TAdBlock.AdditionallyDragged *5, ..
					MouseManager.y - AdBlock.rect.GetH()*0.25 - TAdBlock.AdditionallyDragged *5..
				)
			EndIf
			If AdBlock.dragged = 0
				If Adblock.StartPos.x = 0 And Adblock.StartPos.y = 0
					AdBlock.dragged = 1
					TAdBlock.AdditionallyDragged = TAdBlock.AdditionallyDragged +1
				Else
					AdBlock.rect.position.SetPos(AdBlock.StartPos)
				EndIf
			EndIf
		Next
    End Function

	'remove adblocks not needed (contract successful before)
	Method RemoveOverheadAdblocks:Int()
		'loop through all blocks, increase count if we found a successful adblock
		'- if count is bigger than spotcount, it is overhead: remove them

		Local successfulBlocks:Int = 0
		For Local otherBlock:TAdBlock= EachIn Game.Players[ self.owner ].ProgrammePlan.Adblocks
			'skip other contracts or failed ones
			If otherBlock.contract <> self.contract OR otherBlock.botched then continue
			'else add to the count
			successfulBlocks :+ 1

			'found enough successful adblocks of that contract? remove overhead
			If successfulBlocks > self.contract.GetSpotCount() then otherBlock.RemoveFromPlan()
		Next
		Return successfulBlocks
	End Method

	'removes Adblocks which are supposed to be deleted for its contract being obsolete (expired)
	'BeginDay: AdBlocks with contracts ending before that day get removed
	Function RemoveAdblocks:Int(Contract:TAdContract, BeginDay:Int=0)
		For Local otherBlock:TAdBlock= EachIn Game.Players[ contract.owner ].ProgrammePlan.Adblocks
			'skip other contracts
			If otherBlock.contract <> contract then continue

			if otherBlock.contract.daySigned + contract.GetDaysToFinish() < BeginDay
				print "remove adblock with obsolete contract"
				otherBlock.RemoveFromPlan()
			EndIf
		Next
	End Function

	Method ShowSheet:Int(x:Int,y:Int)
		Self.contract.showSheet(x,y)
	End Method

	'remove from programmeplan
	Method RemoveFromPlan()
		Game.Players[ self.owner ].ProgrammePlan.RemoveAdBlock(Self)
		If game.networkgame Then NetworkHelper.SendPlanAdChange(self.owner, Self, 0)
    End Method

	'add to programmeplan of the owner
    Method AddToPlan()
		Game.Players[ self.owner ].ProgrammePlan.AddAdBlock(Self)
		If game.networkgame Then NetworkHelper.SendPlanAdChange(self.owner, Self, 1)
    End Method

    Function GetBlockByContract:TAdBlock(contract:TAdContract)
		For Local _AdBlock:TAdBlock = EachIn Game.Players[ contract.owner ].ProgrammePlan.Adblocks
			if contract = _Adblock.contract then return _Adblock
		Next
		return Null
	End Function

	Function GetBlock:TAdBlock(playerID:int, id:Int)
		For Local _AdBlock:TAdBlock = EachIn Game.Players[ playerID ].ProgrammePlan.Adblocks
			If _Adblock.ID = id Then Return _Adblock
		Next
		Return Null
	End Function
End Type

Type TProgrammeBlock Extends TBlockGraphical
    Field id:Int		= -1 {saveload = "normal"}
	Field State:Int		= 0 {saveload = "normal"}
	Field link:TLink

    Field image:TGW_Sprites
    Field image_dragged:TGW_Sprites
    Field Programme:TProgramme
    Global LastUniqueID:Int =0
    Global DragAndDropList:TList

	Field sendHour:Int = -1					'which hour of the game (24h*day+dayHour) block is planned to be send?


  Function LoadAll(loadfile:TStream)
'    TProgrammeBlock.List.Clear()
    Local BeginPos:Int = Stream_SeekString("<PRB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</PRB>",loadfile)  -6
    Local strlen:Int = 0
    loadfile.Seek(BeginPos)

	TProgrammeBlock.lastUniqueID:Int        = ReadInt(loadfile)
    TProgrammeBlock.AdditionallyDragged:Int = ReadInt(loadfile)
'	Local FinishString:String = ""
	Repeat
      Local ProgrammeBlock:TProgrammeBlock = New TProgrammeBlock
 	  ProgrammeBlock.image = Assets.GetSprite("pp_programmeblock1")
 	  ProgrammeBlock.image_dragged = Assets.GetSprite("pp_programmeblock1_dragged")
	  ProgrammeBlock.id   = ReadInt(loadfile)
	  ProgrammeBlock.state    = ReadInt(loadfile)
	  ProgrammeBlock.dragable = ReadInt(loadfile)
	  ProgrammeBlock.dragged = ReadInt(loadfile)
	  ProgrammeBlock.StartPos.Load(Null)
	  ProgrammeBlock.rect.dimension.SetY( ReadInt(loadfile) )
	  ProgrammeBlock.rect.dimension.SetX( ReadInt(loadfile) )
	  ProgrammeBlock.rect.position.Load(Null)
	  Local progID:Int = ReadInt(loadfile)
      Local ProgSendHour:Int = ReadInt(loadfile)
	  Local ParentprogID:Int = ReadInt(loadfile)
	  ProgrammeBlock.owner    = ReadInt(loadfile)
      If ProgID >= 0
        ProgrammeBlock.Programme 		  = Tprogramme.GetProgramme(ProgID) 'change owner?
        ProgrammeBlock.sendHour = ProgSendHour
	  EndIf
	  Game.Players[ProgrammeBlock.owner].ProgrammePlan.ProgrammeBlocks.addLast(ProgrammeBlock)
	  ReadString(loadfile, 5)  'finishing string (eg. "|PRB|")
'	  Game.Players[ProgrammeBlock.owner].ProgrammePlan.AddProgramme(ProgrammeBlock.Programme, 1)
	Until loadfile.Pos() >= EndPos 'Or FinishString <> "|PRB|"
	Print "loaded programmeblocklist"
  End Function

	Function SaveAll()
		'foreach player !
		Rem
		LoadSaveFile.xmlBeginNode("ALLPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",		TProgrammeBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",TProgrammeBlock.AdditionallyDragged)
		    For Local ProgrammeBlock:TProgrammeBlock= EachIn TProgrammeBlock.List
				If ProgrammeBlock <> Null Then ProgrammeBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
		endrem
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("PROGRAMMEBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.Programme.id)
				LoadSavefile.xmlWrite("PROGRAMMESENDHOUR",	Self.sendhour)
			Else
				LoadSavefile.xmlWrite("PROGRAMMEID",		"-1")
				LoadSavefile.xmlWrite("PROGRAMMESENDDATE",	"-1")
				LoadSavefile.xmlWrite("PROGRAMMESENDTIME",	"-1")
			EndIf
	 	LoadSaveFile.xmlCloseNode()
	End Method

	Method SetStartConfig(x:Float, y:Float, owner:Int=0, state:Int=0)
 	  Self.image 		= Assets.GetSprite("pp_programmeblock1")
 	  Self.image_dragged= Assets.GetSprite("pp_programmeblock1_dragged")
 	  Self.owner 		= owner
 	  Self.State 		= state
	  Self.id 			= Self.lastUniqueID
	  Self.lastUniqueID:+1
 	  Self.dragable 	= 1
	  Self.rect			= TRectangle.Create(x, y, Self.image.w, Self.image.h)
	  Self.StartPos		= TPoint.Create(x, y)
	End Method


    'creates a programmeblock which is already dragged (used by movie/series-selection)
    'erstellt einen gedraggten Programmblock (genutzt von der Film- und Serienauswahl)
	Function CreateDragged:TProgrammeBlock(movie:TProgramme, owner:Int =-1)
		If owner < 0 Then owner = game.playerID
		Local obj:TProgrammeBlock=New TProgrammeBlock

		local x:float = MouseManager.x - obj.rect.GetW()/2 - TAdblock.AdditionallyDragged *5
		local y:float = MouseManager.y - obj.rect.GetH()*0.25 - TAdblock.AdditionallyDragged *5
		obj.SetStartConfig(x,y,owner, 0)

		obj.dragged		= 1
		obj.Programme	= movie
		obj.sendHour	= TPlayerProgrammePlan.getPlanHour(obj.GetHourOfBlock(1, obj.StartPos), Game.daytoplan)
		obj.link		= Game.Players[owner].ProgrammePlan.ProgrammeBlocks.addLast(obj)
		Game.Players[owner].ProgrammePlan.AdditionallyDraggedProgrammeBlocks :+ 1

		Return obj
	End Function

	Function Create:TProgrammeBlock(x:Int=0, y:Int=0, serie:Int=0, owner:Int=0, programmepos:Int=-1)
		Local obj:TProgrammeBlock=New TProgrammeBlock
		obj.SetStartConfig(x,y,owner, randRange(0,3))
		If Programmepos <= -1
			obj.Programme = Game.Players[owner].ProgrammeCollection.GetRandomProgramme(serie)
		Else
			SortList(Game.Players[owner].ProgrammeCollection.MovieList)
			'get programme "pos"
			obj.Programme = TProgramme(Game.Players[owner].ProgrammeCollection.MovieList.ValueAtIndex(programmepos))
		EndIf

		obj.sendHour	= TPlayerProgrammePlan.getPlanHour(obj.GetHourOfBlock(1, obj.StartPos),Game.daytoplan)
		obj.link		= Game.Players[owner].ProgrammePlan.ProgrammeBlocks.addLast(obj)
		'Print "Player "+owner+" -Create block: added:"+obj.Programme.title
		Return obj
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method DraggingAllowed:Int()
    	Return (dragable And Self.GetState() = 0 And owner=Game.playerID)
    End Method

    Method DrawBlockPart(x:Int,y:Int,kind:Int, variant:String="")
    	If kind=1
			Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y, x, y, -1, 30)
    	Else
			Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30, x, y, -1, 15)
    	    If kind=2
				Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30 + 15, x, y + 15, -1, 15)
    	    Else
				Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30, x, y + 15, -1, -1)
    	    EndIf
	    EndIf
    End Method

	Method GetState:Int()
		State = 1
		If Game.GetDay() > Game.daytoplan Then State = 4
		If Game.GetDay() < Game.daytoplan Then State = 0
		If Game.GetDay() = Game.daytoplan
			'xx:05
			Local moviesStartTime:Int	= Int(Floor((Game.minutesOfDayGone-5) / 60))
			'xx:55
			Local moviesEndTime:Int		= Int(Floor((Game.minutesOfDayGone+5) / 60)) 'with ad
			Local startTime:Int			= Self.GetHourOfBlock(1, Self.StartPos)
			Local endTime:Int			= Self.GetHourOfBlock(Self.programme.blocks, Self.StartPos)
			'running or runned (1 or 2)
			If startTime <= moviesStartTime Then State = 1 + (endTime >= moviesEndTime)
			'not run - normal
			If startTime > moviesStartTime Or Self.sendHour < 0 Then State = 0
		EndIf
		Return State
	End Method

	'draw the programmeblock inclusive text
    'zeichnet den Programmblock inklusive Text
	Method Draw()
		'Draw dragged programmeblockgraphic
		If Self.dragged = 1 Or functions.DoMeet(Self.sendHour, Self.sendHour + Self.programme.blocks, Game.daytoplan*24,Game.daytoplan*24+24)  'out of gameplanner
			GetState()
			If dragged Then state = 0
			If State = 0 Then SetColor 255,255,255;dragable=1  'normal
			If State = 1 Then SetColor 200,255,200;dragable=0  'runned
			If State = 2 Then SetColor 250,230,120;dragable=0  'running
			If State = 4 Then SetColor 255,255,255;dragable=0  'old day

			Local variant:String = ""
			Local drawTitle:Int = 1
			If dragged = 1 And state=0 Then variant = "_dragged"

			If programme.blocks = 1
				Assets.GetSprite("pp_programmeblock1"+variant).Draw(rect.GetX(), rect.GetY())
			Else
				For Local i:Int = 1 To Self.programme.blocks
					Local _type:Int = 1
					If i > 1 And i < Self.programme.blocks Then _type = 2
					If i = Self.programme.blocks Then _type = 3
					If Self.dragged
						'draw on manual position
						Self.DrawBlockPart(rect.GetX(), rect.GetY() + (i-1)*30,_type)
					Else
						'draw on "planner spot" position
						Local _pos:TPoint = Self.getSlotXY(Self.sendhour+i-1)

						If Self.sendhour+i-1 >= game.daytoplan*24 And Self.sendhour+i-1 < game.daytoplan*24+24
							Self.DrawBlockPart(_pos.x,_pos.y ,_type)
							If i = 1 Then rect.position.setPos(_pos)
						Else
							If i=1 Then drawTitle = 0
						EndIf
					EndIf
				Next
			EndIf
			If drawTitle Then Self.DrawBlockText(TColor.Create(50,50,50), Self.rect.position)
		EndIf 'daytoplan switch
    End Method

    Method DrawBlockText(color:TColor = Null, _pos:TPoint)
		SetColor 0,0,0

		Local maxWidth:Int = Self.image.w - 5
		Local title:String = Self.programme.title
		local titleAppend:string = ""
		If Not Self.programme.isMovie()
			title = Self.programme.GetParent().title
			'uncomment if you wish episode number in title
			'titleAppend = " (" + Self.programme.episode + "/" + Self.programme.GetParent().episodes.count() + ")"
		EndIf

		While Assets.fonts.basefontBold.getWidth(title+titleAppend) > maxWidth And title.length > 4
			title = title[..title.length-3]+".."
		Wend
		'add "(1/10)"
		title = title + titleAppend

		Assets.fonts.basefontBold.drawBlock(title, _pos.GetIntX() + 5, _pos.GetIntY() +2, Self.image.w - 10, 18, 0, 0, 0, 0, True)
		If color <> Null Then color.set()
		Local useFont:TBitmapFont = Assets.GetFont("Default", 11, ITALICFONT)
		If programme.parent <> Null
			useFont.draw(Self.Programme.getGenreString()+"-Serie",_pos.GetIntX()+5,_pos.GetIntY()+18)
			useFont.draw("Teil: " + Self.Programme.episode + "/" + Self.programme.parent.episodes.count(), _pos.GetIntX() + 138, _pos.GetIntY() + 18)
		Else
			useFont.draw(Self.Programme.getGenreString(),_pos.GetIntX()+5,_pos.GetIntY()+18)
			If Self.programme.xrated <> 0 Then useFont.draw("FSK 18!",_pos.GetIntX()+138,_pos.GetIntY()+18)
		EndIf
		SetColor 255,255,255
	End Method

	Method DrawShades()
		'draw a shade of the programmeblock on its original position but not when just created and so dragged from its creation on
		 If (Self.StartPos.x = 394 Or Self.StartPos.x = 67) And (Abs(Self.rect.getX() - Self.StartPos.x) > 0 Or Abs(Self.rect.GetY() - Self.StartPos.y) >0)
			SetAlpha 0.4
			If Self.programme.blocks = 1
				Self.image.Draw(Self.StartPos.x, Self.StartPos.y)
			Else
				For Local i:Int = 1 To Self.programme.blocks
					Local _pos:TPoint = Self.getBlockSlotXY(i, Self.startPos)
					Local _type:Int = 1
					If i > 1 And i < Self.programme.blocks Then _type = 2
					If i = Self.programme.blocks Then _type = 3
					Self.DrawBlockPart(_pos.x,_pos.y,_type)
				Next
			EndIf
			Self.DrawBlockText( TColor.Create(80,80,80), Self.startPos )

			SetAlpha 1.0
		EndIf
	End Method

    Method DeleteBlock()
		Print "deleteBlock: programme:"+Self.Programme.title
		'remove self from block list
		Game.Players[Game.playerID].ProgrammePlan.ProgrammeBlocks.remove(Self)
'		self.remove()
'		Game.Players[Game.playerID].ProgrammePlan.RemoveProgramme(Self.Programme)
    End Method

	'give total hour - returns x of planner-slot
	Method GetSlotX:Int(time:Int)
		Return GetSlotXY(time).x
	End Method

	'give total hour - returns y of planner-slot
	Method GetSlotY:Int(time:Int)
		Return GetSlotXY(time).y
	End Method

	'give total hour - returns position of planner-slot
	Method GetSlotXY:TPoint(totalHours:Int)
		totalHours = totalHours Mod 24
		Local top:Int = 17
		If Floor(totalHours/12) Mod 2 = 1 '(12-23, + next day 12-23 and so on)
			Return TPoint.Create(394, top + (totalHours - 12)*30)
		Else
			Return TPoint.Create(67, top + totalHours*30)
		EndIf
	End Method

	'returns the slot coordinates of a position on the plan
	'returns for current day not total (eg. 0-23)
	Method GetBlockSlotXY:TPoint(blockNumber:Int, _pos:TPoint = Null)
		Return Self.GetSlotXY( Self.GetHourOfBlock(blockNumber, _pos) )
	End Method

	'returns the hour of a position on the plan
	'returns for current day not total (eg. 0-23)
	Method GetHourOfBlock:Int(blockNumber:Int, _pos:TPoint= Null)
		If _pos = Null Then _pos = Self.rect.position
		'0-11 links, 12-23 rechts
		Local top:Int = 17
		Return (_pos.y - top) / 30 + 12*(_pos.x = 394)   +  (blockNumber-1)
	End Method

    'remove from programmeplan
    Method Drag()
		If Self.dragged <> 1
			Self.dragged	= 1
			Self.sendHour	= -1

			'emit event ?
			If game.networkgame Then NetworkHelper.SendPlanProgrammeChange(game.playerID, Self, 0)
		EndIf
    End Method

	'add to plan again
    Method Drop()
		If Self.dragged <> 0
			Self.dragged = 0
			self.rect.position.SetPos(StartPos)
			Self.sendHour = TPlayerProgrammePlan.getPlanHour(Self.getHourOfBlock(1, Self.rect.position), game.daytoplan)

			'emit event ?
			If game.networkgame Then NetworkHelper.SendPlanProgrammeChange(game.playerID, Self, 1)
		EndIf
    End Method
End Type



'a graphical representation of programmes/news/ads...
Type TGUINews extends TGUIGameObject
	Field news:TNews = Null
	Field imageBaseName:string = "gfx_news_sheet"


    Method Create:TGUINews(label:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		Super.Create(label,x,y,width,height)

		return self
	End Method

	Method SetNews:int(news:TNews)
		self.news = news
		if news
			'now we can calculate the item width
			self.Resize( Assets.GetSprite(Self.imageBaseName+news.newsEvent.genre).w, Assets.GetSprite(Self.imageBaseName+news.newsEvent.genre).h )
		endif
		'self.SetLimitToState("Newsplanner")

		'as the news inflicts the sorting algorithm - resort
		GUIManager.sortList()
	End Method


	Method Compare:int(Other:Object)
		local otherBlock:TGUINews = TGUINews(Other)
		If otherBlock<>null
			'both items are dragged - check time
			if self._flags & GUI_OBJECT_DRAGGED AND otherBlock._flags & GUI_OBJECT_DRAGGED
				'if a drag was earlier -> move to top
				if self._timeDragged < otherBlock._timeDragged then Return 1
				if self._timeDragged > otherBlock._timeDragged then Return -1
				return 0
			endif

			if self.news and otherBlock.news
				local publishDifference:int = self.news.GetPublishTime() - otherBlock.news.GetPublishTime()

				'self is newer ("later") than other
				if publishDifference>0 then return -1
				'self is older than other
				if publishDifference<0 then return 1
				'self is same age than other
				'if publishDifference=0 then return (self.newsBlock.id > otherBlock.newsBlock.id)
				if publishDifference=0 then return Super.Compare(Other)
			endif
		endif

		return Super.Compare(Other)
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		'set mouse to "hover"
		if news.owner = Game.playerID or news.owner <= 0 and mouseover then Game.cursorstate = 1
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2

		if isDragged() AND 1=5
			print "."
			print "----DEBUG"
			print "gui "+_id+" listed in:"
			'if self = RoomHandler_News.hoveredGuiNews then print "hoveredGuiNews"
			'if self = RoomHandler_News.draggedGuiNews then print "draggedGuiNews"
			for local obj:TGUINews = eachin GUIManager.list
				if self = obj then print "GUIManager"
			Next

			for local obj:TGUINews = eachin RoomHandler_News.guiNewsListAvailable.entries
				if self = obj then print "guiNewsListAvailable"
			Next
			for local obj:TGUINews = eachin RoomHandler_News.guiNewsListAvailable.guiEntriesPanel.children
				if self = obj then print "guiNewsAvailable.CHILDREN"
			Next
			for local i:int = 0 to RoomHandler_News.guiNewsListUsed._slots.length-1
				local obj:TGUINews = TGUINews(RoomHandler_News.guiNewsListUsed._slots[i])
				if self = obj then print "guiNewsListUsed"
			Next
			if RoomHandler_News.guiNewsListUsed.guiEntriesPanel.children
				for local obj:TGUINews = eachin RoomHandler_News.guiNewsListUsed.guiEntriesPanel.children
					if self = obj then print "guiNewsListUsed.CHILDREN"
				Next
			endif
		endif

	End Method


	Method Draw()
		State = 0
		SetColor 255,255,255

		if self.RestrictViewPort()
			local screenX:float = int(self.GetScreenX())
			local screenY:float = int(self.GetScreenY())
			local oldAlpha:float = GetAlpha()
			local itemAlpha:float = 1.0
			'fade out dragged
			if isDragged() then itemAlpha = 0.25 + 0.5^GuiManager.GetDraggedNumber(self)

			SetAlpha oldAlpha*itemAlpha
			'background - no "_dragged" to add to name
			Assets.GetSprite(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)

			'default texts (title, text,...)
			Assets.fonts.basefontBold.drawBlock(news.GetTitle(), screenX + 15, screenY + 4, 290, 15 + 8, 0, 20, 20, 20)
			Assets.fonts.baseFont.drawBlock(news.GetDescription(), screenX + 15, screenY + 19, 300, 50 + 8, 0, 100, 100, 100)
			SetAlpha 0.3*oldAlpha*itemAlpha
			Assets.GetFont("Default", 9).drawBlock(news.GetGenreString(), screenX + 15, screenY + 74, 120, 15, 0, 0, 0, 0)
			SetAlpha 1.0*oldAlpha*itemAlpha
			if not news.paid
				Assets.GetFont("Default", 12, BOLDFONT).drawBlock(news.newsEvent.ComputePrice() + ",-", screenX + 219, screenY + 72, 90, 15, 2, 0, 0, 0)
			else
				Assets.GetFont("Default", 12).drawBlock(news.newsEvent.ComputePrice() + ",-", screenX + 219, screenY + 72, 90, 15, 2, 50, 50, 50)
			endif

			Select Game.getDay() - Game.GetDay(news.newsEvent.happenedtime)
				case 0	Assets.fonts.baseFont.drawBlock("Heute " + Game.GetFormattedTime(news.newsEvent.happenedtime) + " Uhr", screenX + 90, screenY + 74, 140, 15, 2, 0, 0, 0)
				case 1	Assets.fonts.baseFont.drawBlock("(Alt) Gestern " + Game.GetFormattedTime(news.newsEvent.happenedtime) + " Uhr", screenX + 90, screenY + 74, 140, 15, 2, 0, 0, 0)
				case 2	Assets.fonts.baseFont.drawBlock("(Alt) Vorgestern " + Game.GetFormattedTime(news.newsEvent.happenedtime) + " Uhr", screenX + 90, screenY + 74, 140, 15, 2, 0, 0, 0)
			End Select
			SetColor 255, 255, 255
			SetAlpha oldAlpha
			self.resetViewport()
		endif
	End Method
End Type




'This object stores a players news.
Type TNews extends TBroadcastMaterial {_exposeToLua="selected"}
    Field newsEvent:TNewsEvent	= Null	{_exposeToLua}
    Field publishDelay:Int 		= 0						'delay the news for a certain time (depending on the abonnement-level)
    Field paid:int	 			= 0
	Field timesAired:int		= 0					'how many times that programme was run


	Function Create:TNews(text:String="unknown", owner:Int=1, publishdelay:Int=0, useNewsEvent:TNewsEvent=Null)
		If not useNewsEvent
			print"News.Create - RandomNews"
			useNewsEvent = TNewsEvent.GetRandom()
		endif

		'if no happened time is set, use the Game time
		if useNewsEvent.happenedtime <= 0 then useNewsEvent.happenedtime = Game.GetTimeGone()

		Local obj:TNews = New TNews
		obj.publishDelay= publishdelay
		obj.newsEvent	= useNewsEvent

		'add to list and also set owner
		Game.Players[owner].ProgrammeCollection.AddNews(obj)
		Return obj
	End Function


    Method Pay:int()
		'only pay if not already done
		if not paid then paid = Game.Players[owner].finances[Game.getWeekday()].PayNews(newsEvent.ComputePrice())
		return paid
    End Method


	'override default
    Method GetTitle:string() {_exposeToLua}
		return newsEvent.GetTitle()
    End Method


	'override default
    Method GetDescription:string() {_exposeToLua}
		return newsEvent.GetDescription()
    End Method


    Method GetPublishTime:int() {_exposeToLua}
		return newsEvent.happenedtime + publishdelay
    End Method


	Method IsReadyToPublish:Int() {_exposeToLua}
		Return (newsEvent.happenedtime + publishDelay <= Game.GetTimeGone())
	End Method


	Method GetGenre:int() {_exposeToLua}
		return newsEvent.genre
	End Method


	Method GetGenreString:string() {_exposeToLua}
		return TNewsEvent.GetGenreString(newsEvent.genre)
	End Method


	Method IsInProgramme:Int() {_exposeToLua}
		Return Game.getPlayer(owner).ProgrammePlan.HasNews(self)
	End Method
	
	
	Method GetQuality:Float(luckFactor:Int = 1) {_exposeToLua}
		Local quality:Float = 0.0
		
		quality = Float(newsEvent.ComputeTopicality()) / 255.0 * 0.45 ..
			+ Float(newsEvent.quality) / 255.0 * 0.35 ..
			+ Float(newsEvent.price) / 255.0 * 0.2
		
		'Zusätzlicher Bonus bei Erstausstrahlung	
		If timesAired = 0 Then quality:*0.15

		If luckFactor = 1 Then
			quality = quality * 0.97 + Float(RandRange(10, 30)) / 1000.0 '1%-Punkte bis 3%-Punkte Basis-Qualität
		Else
			quality = quality * 0.99 + 0.01 'Mindestens 1% Qualität
		EndIf
		
		'no minus quote
		Return Max(0, quality)
	End Method	
End Type


Type TGUINewsList extends TGUIListBase

    Method Create:TGUINewsList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)
		return self
	End Method

	Method ContainsNews:int(news:TNews)
		for local guiNews:TGUINews = eachin entries
			if guiNews.news = news then return TRUE
		Next
		return FALSE
	End Method
rem
	'override default to check against duplicate
	Method AddItem:int(item:TGUIobject, extra:object=null)
		'if we find a duplicate, just return succesful without
		'adding the item again
		if TGUINews(item) and ContainsNews(TGUINews(item).news)
			print "ListContainsNews - fake ADD"
			return TRUE
		endif
		return Super.AddItem(item,extra)
	End Method
endrem
End Type


Type TGUINewsSlotList extends TGUISlotList

    Method Create:TGUINewsSlotList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)
		return self
	End Method

	Method ContainsNews:int(news:TNews)
		for local i:int = 0 to self.GetSlotAmount()-1
			local guiNews:TGUINews = TGUINews( self.GetItemBySlot(i) )
			if guiNews and guiNews.news = news then return TRUE
		Next
		return FALSE
	End Method
rem
	'override default to check against doublettes
	Method AddItem:int(item:TGUIobject, extra:object=null)
		if TGUINews(item) and ContainsNews(TGUINews(item).news)
			print "SlotListContainsNews";
			return TRUE
		endif
		return Super.AddItem(item,extra)
	End Method
endrem
End Type



Type TGUIProgrammeSlotList extends TGUISlotList
	field  acceptType:int		= 0	'accept all
	Global acceptAll:int		= 0
	Global acceptMovies:int		= 1
	Global acceptSeries:int		= 2

    Method Create:TGUIProgrammeSlotList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)

		'albeit the list base already handles drop on itself
		'we want to intercept too -- to stop dropping if not
		'enough money is available
		'---alternatively we could intercept programmeblocks-drag-event
		'EventManager.registerListenerFunction( "guiobject.onDropOnTarget", self.onDropOnTarget, accept, self)

		return self
	End Method

	Method ContainsProgramme:int(programme:TProgramme)
		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGUIProgrammeCoverBlock = TGUIProgrammeCoverBlock( self.GetItemBySlot(i) )
			if block and block.programme = programme then return TRUE
		Next
		return FALSE
	End Method

	'overriden Method: so it does not accept a certain
	'kind of programme (movies - series)
	Method AddItem:int(item:TGUIobject, extra:object=null)
		local coverBlock:TGUIProgrammeCoverBlock = TGUIProgrammeCoverBlock(item)
		if not coverBlock then return FALSE

		'something odd happened - no programme
		if not coverBlock.programme then return FALSE

		if acceptType > 0
			if acceptType = acceptMovies and not coverBlock.programme.isMovie() then return FALSE
			if acceptType = acceptSeries and coverBlock.programme.isMovie() then return FALSE
		endif

		if super.AddItem(item,extra)
			'print "added an item ... slot state:" + self.GetUnusedSlotAmount()+"/"+self.GetSlotAmount()
			return true
		endif

		return FALSE
	End Method

End Type



Type TGUIAdContractSlotList extends TGUISlotList

    Method Create:TGUIAdContractSlotList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)
		return self
	End Method

	Method ContainsContract:int(contract:TAdContract)
		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGuiAdContract = TGuiAdContract( self.GetItemBySlot(i) )
			if block and block.contract = contract then return TRUE
		Next
		return FALSE
	End Method

	'override to add sort
	Method AddItem:int(item:TGUIobject, extra:object=null)
		if super.AddItem(item, extra)
			GUIManager.sortList()
			return TRUE
		endif
		return FALSE
	End Method

	'override default event handler
	Function onDropOnTarget:int( triggerEvent:TEventBase )
		local item:TGUIListItem = TGUIListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		'ATTENTION:
		'Item is still in dragged state!
		'Keep this in mind when sorting the items

		'only handle if coming from another list ?
		local parent:TGUIobject = item._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local fromList:TGUIListBase = TGUIListBase(parent)
		if not fromList then return FALSE

		local toList:TGUIListBase = TGUIListBase(triggerEvent.GetReceiver())
		if not toList then return FALSE

		local data:TData = triggerEvent.getData()
		if not data then return FALSE

		'move item if possible
		fromList.removeItem(item)
		'try to add the item, if not able, readd
		if not toList.addItem(item, data)
			if fromList.addItem(item) then return TRUE

			'not able to add to "toList" but also not to "fromList"
			'so set veto and keep the item dragged
			triggerEvent.setVeto()
		endif


		return TRUE
	End Function
End Type


'a graphical representation of programmes/news/ads...
Type TGUIGameObject extends TGUIListItem
	Field assetNameDefault:string = "gfx_movie0"
	Field assetNameDragged:string = "gfx_movie0"
	Field asset:TGW_Sprites = null
	Field assetDefault:TGW_Sprites = null
	Field assetDragged:TGW_Sprites = null

    Method Create:TGUIGameObject(label:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		'creates base, registers click-event,...
		Super.Create(label, x,y,width,height)

   		self.InitAssets()
   		self.SetAsset()

		return self
	End Method


	Method InitAssets(nameDefault:string="", nameDragged:string="")
		if nameDefault = "" then nameDefault = self.assetNameDefault
		if nameDragged = "" then nameDragged = self.assetNameDragged

		self.assetNameDefault = nameDefault
		self.assetNameDragged = nameDragged
		self.assetDefault = Assets.GetSprite(nameDefault)
		self.assetDragged = Assets.GetSprite(nameDragged)

		self.SetAsset(self.assetDefault)
	End Method


	Method SetAsset(sprite:TGW_Sprites=null)
		if not sprite then sprite = self.assetDefault

		'only resize if not done already
		if self.asset <> sprite
			self.asset = sprite
			self.Resize(sprite.w, sprite.h)
		endif
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		if self.mouseover or self.isDragged()
			EventManager.triggerEvent(TEventSimple.Create("guiGameObject.OnMouseOver", TData.Create(), self))
		endif

		if self.mouseover then Game.cursorstate = 1
		if self.isDragged()
			self.SetAsset(self.assetDragged)
			Game.cursorstate = 2
		endif
	End Method


	Method Draw()
		asset.draw(self.GetScreenX(), self.GetScreenY())
	End Method
End Type


'a graphical representation of programmes to buy/sell/archive...
Type TGUIProgrammeCoverBlock extends TGUIGameObject
	Field programme:TProgramme
	Field isAffordable:int = TRUE


    Method Create:TGUIProgrammeCoverBlock(label:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		Super.Create(label,x,y,width,height)
		return self
	End Method


	Method CreateWithProgramme:TGUIProgrammeCoverBlock(programme:TProgramme)
		self.Create()
		self.setProgramme(programme)
		return self
	End Method


	Method SetProgramme:TGUIProgrammeCoverBlock(programme:TProgramme)
		self.programme = programme

		local genre:int = 0
		if programme.genre < 15 then genre = programme.genre

		'set to a nice asset image
		if programme.isMovie() then self.InitAssets("gfx_movie" + genre, "gfx_movie" + genre + "_dragged")
		if not programme.isMovie() then self.InitAssets("gfx_serie" + genre, "gfx_serie" + genre + "_dragged")

		return self
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		self.isAffordable = Game.getPlayer().getFinancial().canAfford(programme.getPrice())


		if programme.owner = Game.playerID or (programme.owner <= 0 and self.isAffordable)
			'change cursor to if mouse over item or dragged
			if self.mouseover then Game.cursorstate = 1
		endif
		'ignore affordability if dragged...
		if isDragged() then Game.cursorstate = 2
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30)
'		self.parentBlock.DrawSheet()
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0
		'if mouse on left side of screen - align sheet on right side
		if MouseManager.x < App.settings.GetWidth()/2
			sheetX = App.settings.GetWidth() - rightX
			sheetAlign = 1
		endif

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		self.programme.ShowSheet(sheetX,sheetY,-1,null,sheetAlign)
	End Method


	Method Draw()
		SetColor 255,255,255

		'make faded as soon as not "dragable" for us
		if programme.owner <> Game.playerID and (programme.owner<=0 and not isAffordable) then SetAlpha 0.75
		Super.Draw()
		SetAlpha 1.0
	End Method
End Type


'a graphical representation of contracts at the ad-agency ...
Type TGuiAdContract extends TGUIGameObject
	Field contract:TAdContract


    Method Create:TGuiAdContract(label:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		Super.Create(label,x,y,width,height)

		self.assetNameDefault = "gfx_contracts_0"
		self.assetNameDragged = "gfx_contracts_0_dragged"

		return self
	End Method


	Method CreateWithContract:TGuiAdContract(contract:TAdContract)
		self.Create()
		self.setContract(contract)
		return self
	End Method


	Method SetContract:TGuiAdContract(contract:TAdContract)
		self.contract		= contract
		'targetgroup is between 0-9
		self.InitAssets(GetAssetName(contract.GetTargetGroup(), FALSE), GetAssetName(contract.GetTargetGroup(), TRUE))

		return self
	End Method


	Method GetAssetName:string(targetGroup:int=-1, dragged:int=FALSE)
		if targetGroup < 0 and contract then targetGroup = contract.GetTargetGroup()
		local result:string = "gfx_contracts_" + Min(9,Max(0, targetGroup))
		if dragged then result = result + "_dragged"
		return result
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		'set mouse to "hover"
		if contract.owner = Game.playerID or contract.owner <= 0 and mouseover then Game.cursorstate = 1
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30)
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0
		'if mouse on left side of screen - align sheet on right side
		if MouseManager.x < App.settings.GetWidth()/2
			sheetX = App.settings.GetWidth() - rightX
			sheetAlign = 1
		endif

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		self.contract.ShowSheet(sheetX,sheetY, sheetAlign)
	End Method


	Method DrawGhost()
		'by default a shaded version of the gui element is drawn at the original position
		self.SetOption(GUI_OBJECT_IGNOREPOSITIONMODIFIERS, TRUE)
		SetAlpha 0.5

		local backupAssetName:string = self.asset.getName()
		self.asset = Assets.GetSprite(assetNameDefault)
		self.Draw()
		self.asset = Assets.GetSprite(backupAssetName)

		SetAlpha 1.0
		self.SetOption(GUI_OBJECT_IGNOREPOSITIONMODIFIERS, FALSE)
	End Method


	Method Draw()
		SetColor 255,255,255
		local oldAlpha:float = GetAlpha()

		'make faded as soon as not "dragable" for us
		if contract.owner <> Game.playerID and contract.owner>0 then SetAlpha 0.75*oldAlpha
		if not isDragable() then SetColor 200,200,200
		Super.Draw()
		SetAlpha oldalpha
		SetColor 255,255,255
	End Method
End Type



'Programmeblocks used in Archive
Type TAuctionProgrammeBlocks {_exposeToLua="selected"}
	Field pos:TPoint = TPoint.Create(0,0)
	Field dim:TPoint	= TPoint.Create(0,0)

	Field imageWithText:TImage = Null
	Field Programme:TProgramme
	Field slot:Int = 0				{saveload = "normal"}
	Field Bid:Int[5]
	Field uniqueID:Int = 0			{saveload = "normal"}
	Field Link:TLink
	Global LastUniqueID:Int =0
	Global List:TList = CreateList()

	Function ProgrammeToPlayer()
		For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			If locObject.Programme <> Null And locObject.Bid[0] > 0 And locObject.Bid[0] <= 4
				Game.Players[locobject.Bid[0]].ProgrammeCollection.AddProgramme(locobject.Programme)
				Print "player "+Game.Players[locobject.Bid[0]].name + " won the auction for: "+locobject.Programme.title
				Repeat
					LocObject.Programme = TProgramme.GetRandomProgrammeWithPrice(200000,-1)
				Until LocObject.Programme <> Null
				locObject.imageWithText = Null
				For Local i:Int = 0 To 4
					LocObject.Bid[i] = 0
				Next
			End If
		Next
	End Function

  Function LoadAll(loadfile:TStream)
    TAuctionProgrammeBlocks.List.Clear()
	Print "cleared auctionblocks:"+TAuctionProgrammeBlocks.List.Count()
    Local BeginPos:Int = Stream_SeekString("<ARCHIVEB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</AUCTIONB>",loadfile)  -11
    loadfile.Seek(BeginPos)
	Local AuctionProgrammeBlocksCount:Int = ReadInt(loadfile)
	If AuctionProgrammeBlocksCount > 0
	Repeat
      Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks = New TAuctionProgrammeBlocks
	  AuctionProgrammeBlocks.uniqueID = ReadInt(loadfile)
	  AuctionProgrammeBlocks.pos.x 	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.pos.y   = ReadInt(loadfile)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    AuctionProgrammeBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
	  EndIf
	  AuctionProgrammeBlocks.slot	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[0]	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[1] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[2] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[3] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[4] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Link   = TAuctionProgrammeBlocks.List.AddLast(AuctionProgrammeBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded auctionprogrammeblocks"
  End Function

	Function SaveAll()
	    Local AuctionProgrammeBlocksCount:Int = 0
		For Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks= EachIn TAuctionProgrammeBlocks.List
			If AuctionProgrammeBlocks <> Null Then AuctionProgrammeBlocksCount:+1
		Next
		LoadSaveFile.xmlBeginNode("ALLAUCTIONPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("AUCTIONPROGRAMMEBLOCKSCOUNT",	AuctionProgrammeBlocksCount)
			For Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks= EachIn TAuctionProgrammeBlocks.List
				If AuctionProgrammeBlocks <> Null Then AuctionProgrammeBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACTBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID",	Self.programme.id)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID", "-1")
			EndIf
			LoadSaveFile.xmlWrite("BID0", Self.Bid[0] )
			LoadSaveFile.xmlWrite("BID1", Self.Bid[1] )
			LoadSaveFile.xmlWrite("BID2", Self.Bid[2] )
			LoadSaveFile.xmlWrite("BID3", Self.Bid[3] )
			LoadSaveFile.xmlWrite("BID4", Self.Bid[4] )
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Create:TAuctionProgrammeBlocks(Programme:TProgramme, slot:Int=0, owner:int=0)
		Local obj:TAuctionProgrammeBlocks=New TAuctionProgrammeBlocks

		obj.pos.SetXY( 140+((slot+1) Mod 2)* 260,   80+ Ceil((slot-1) / 2)*60 )
		obj.dim.SetXY( Assets.GetSprite("gfx_auctionmovie").w, Assets.GetSprite("gfx_auctionmovie").h )
		For Local i:Int = 0 To 4
			obj.Bid[i] = 0
		Next
		obj.slot		= slot
		obj.Programme	= Programme
		obj.Programme.owner = owner
		obj.List.AddLast(obj)
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		Return obj
	End Function

	Function Sort:Int(o1:Object, o2:Object)
		Local s1:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o1)
		Local s2:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.slot)-(s2.slot)
	End Function

	Method ShowSheet:Int(x:Int,y:Int)
		Programme.ShowSheet(x,y)
	End Method


    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		Local HighestBid:Int		= Programme.getPrice()
		Local NextBid:Int			= 0

		If Bid[0]>0 And Bid[0] <=4 Then If Bid[ Bid[0] ] <> 0 Then HighestBid = Bid[ Bid[0] ]
		NextBid = HighestBid

		If HighestBid < 100000
			NextBid :+ 10000
		Else If HighestBid >= 100000 And HighestBid < 250000
			NextBid :+ 25000
		Else If HighestBid >= 250000 And HighestBid < 750000
			NextBid :+ 50000
		Else If HighestBid >= 750000
			NextBid :+ 75000
		EndIf

		SetColor 255,255,255  'normal
	    If imageWithText = Null

			ImageWithText = CopyImage2( Assets.GetSprite("gfx_auctionmovie").GetImage(0) )
'			ImageWithText = CreateImage(300,40)
			local pix:TPixmap = LockImage(ImageWithText)

			if not ImageWithText THROW "GetImage Error for gfx_auctionmovie"

			local font:TBitmapFont		= Assets.GetFont("Default", 10)
			local titleFont:TBitmapFont	= Assets.GetFont("Default", 10, BOLDFONT)

			'set target for fonts
			font.setTargetImage(ImageWithText)
			titleFont.setTargetImage(ImageWithText)

			If Game.Players[Bid[0]] <> Null
				titleFont.drawStyled(Game.Players[Bid[0]].name,31,33, Game.Players[Bid[0]].color.r, Game.Players[Bid[0]].color.g, Game.Players[Bid[0]].color.b, 2, 1, 0.25)
			else
				font.drawStyled("ohne Bieter", 31,33, 150,150,150, 0, 1, 0.25)
			EndIf
			titleFont.drawBlock(Programme.title, 31,5, 215,30, 0, 0,0,0, false, 1, 1, 0.50)

			font.drawBlock("Bieten:"+NextBid+CURRENCYSIGN, 31,33, 212,20,2, 0,0,0,1)

			'reset target for fonts
			titleFont.resetTarget()
			font.resetTarget()

	    EndIf
		SetColor 255,255,255
		SetAlpha 1
		DrawImage(imageWithText,pos.x,pos.y)
    End Method


	Function DrawAll(DraggingAllowed:Byte)
		'sort only needed during add/remove...
		'TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			obj.Draw()
		Next

		'draw sheets (must be afterwards to avoid overlapping (itemA Sheet itemB itemC) )
		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			if functions.IsIn(MouseManager.x, MouseManager.y, obj.Pos.x, obj.Pos.y, obj.dim.x, obj.dim.y)
				if obj.pos.x+obj.dim.x > App.settings.GetWidth()/2
					obj.Programme.ShowSheet(90,50)
				else
					obj.Programme.ShowSheet(400,50)
				endif
				Exit
			endif
		Next

	End Function

	Method GetProgramme:TProgramme()  {_exposeToLua}
		return self.Programme
	End Method

	Method SetBid:int(playerID:Int)
		If not Game.isPlayer( playerID ) then return -1
		if self.Bid[ self.Bid[0] ] = playerID then return 0

		'reset so cache gets renewed
		self.imageWithText = null

		local price:int = self.GetNextBid()
		If Game.Players[playerID].finances[Game.getWeekday()].PayProgrammeBid(price) = True
			If Game.Players[Self.Bid[0]] <> Null Then
				Game.Players[Self.Bid[0]].finances[Game.getWeekday()].GetProgrammeBid(Self.Bid[Self.Bid[0]])
				Self.Bid[Self.Bid[0]] = 0
			EndIf
			Self.Bid[0] = playerID
			Self.Bid[playerID] = price
			Self.imageWithText = Null
		EndIf
		return price
	End Method

	Method GetNextBid:int() {_exposeToLua}
		Local HighestBid:Int	= self.Programme.getPrice()
		Local NextBid:Int		= 0
		If Game.isPlayer(self.Bid[0]) AND self.Bid[ self.Bid[0] ] <> 0 Then HighestBid = self.Bid[ self.Bid[0] ]
		NextBid = HighestBid
		If HighestBid < 100000
			NextBid :+ 10000
		Else If HighestBid >= 100000 And HighestBid < 250000
			NextBid :+ 25000
		Else If HighestBid >= 250000 And HighestBid < 750000
			NextBid :+ 50000
		Else If HighestBid >= 750000
			NextBid :+ 75000
		EndIf
		return NextBid
	End Method

	Method GetHighestBidder:int() {_exposeToLua}
		if Game.isPlayer(self.Bid[0]) then return self.Bid[0] else return -1
	End Method

	Function UpdateAll:int(DraggingAllowed:Byte)
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		Local MouseHit:Int = MOUSEMANAGER.IsHit(1)
		if not MouseHit then return 0

		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			if obj.Bid[0] <> game.playerID And functions.IsIn(MouseManager.x, MouseManager.y, obj.pos.x, obj.pos.y, obj.dim.x, obj.dim.y)
				If game.networkgame Then NetworkHelper.SendMovieAgencyChange(NET_BID, game.playerID, obj.GetNextBid(), -1, obj.Programme)
				obj.SetBid( game.playerID )  'set the bid
			EndIf
		Next
	End Function

End Type