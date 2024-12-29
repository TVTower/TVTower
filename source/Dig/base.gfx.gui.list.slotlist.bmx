Rem
	====================================================================
	GUI Slot List
	====================================================================

	Code contains:
	- TGUISlotList: list allowing to place items on a specific slot


	====================================================================
	LICENCE

	Copyright (C) 2002-2019 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.
	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
End Rem
SuperStrict
Import "base.gfx.gui.list.base.bmx"



Type TGUISlotList Extends TGUIListBase
	Field _slotMinDimension:TVec2D = New TVec2D(0,0)
	'slotAmount: <=0 means dynamically, else it is fixed
	Field _slotAmount:Int = -1
	Field _slots:TGUIobject[0]
	Field _slotsState:Int[0]
	Field _autofillSlots:Int = False
	Field _fixedSlotDimension:Int = False


	Method GetClassName:String()
		Return "tguislotlist"
	End Method


    Method Create:TGUISlotList(position:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(position, dimension, limitState)

		setListOption(GUILIST_AUTOSORT_ITEMS, False)

		Return Self
	End Method


	Method ClearSlotsState:Int()
		_slotsState = New Int[_slots.length]
	End Method


	Method GetSlotState:Int(slot:Int)
		If slot >= _slotsState.length Then Return -1
		Return _slotsState[slot]
	End Method


	Method SetSlotState:Int(slot:Int, state:Int)
		If slot >= _slotsState.length Then Return False
		_slotsState[slot] = state
		Return True
	End Method


	Method EmptyList:Int()
		Super.EmptyList()

		For Local i:Int = 0 To _slots.length-1
			'skip empty slots
			If _slots[i]=Null Then Continue
			'call the objects cleanup-method and unsets afterwards
			_slots[i].Remove()
			_slots[i] = Null
			_slotsState[i] = 0
		Next
		InvalidateLayout()
	End Method


	'returns how many slots that list has at all
	Method GetSlotAmount:Int()
		Return _slotAmount
	End Method


	'returns how many slots of that list are not occupied
	Method GetUnusedSlotAmount:Int()
		Local amount:Int = 0
		For Local i:Int = 0 To _slots.length-1
			If not _slots[i] Then amount:+1
		Next
		Return amount
	End Method


	Method SetAutofillSlots(bool:Int=True)
		Self._autofillSlots = bool
	End Method


	'override
	Method HasItem:Int(item:TGUIobject)
		Return (getSlot(item) >= 0)
	End Method


	'override
	Method SetItemLimit:Int(limit:Int)
		Super.SetItemLimit(limit)
		_slotAmount = limit

		'maybe better "drag" items before if resizing to smaller slot amounts
		_slots = _slots[..limit]
		_slotsState = _slotsState[..limit]
	End Method


	Method SetSlotMinDimension:Int(width:Float=0.0, height:Float=0.0)
		_slotMinDimension.setXY(width, height)
	End Method


	'which slot is occupied by the given item?
	Method GetSlot:Int(item:TGUIobject)
		For Local i:Int = 0 To _slots.length-1
			If _slots[i] = item Then Return i
		Next
		Return -1
	End Method


	'return the next free slot (for autofill)
	Method GetFreeSlot:Int()
		For Local i:Int = 0 To _slots.length-1
			If _slots[i] Then Continue
			Return i
		Next
		Return -1
	End Method

'TODO: TRectangle auf SRect umstellen und coord auf SVec2D (bzw eigenen Overload)
	Method GetSlotOrCoord:SVec3F(slot:Int=-1, coord:TVec2D=Null)
		Local baseRect:TRectangle = Null
		If _fixedSlotDimension
			baseRect = New TRectangle.Init(0, 0, _slotMinDimension.getX(), _slotMinDimension.getY())
		Else
			If _orientation = GUI_OBJECT_ORIENTATION_VERTICAL
				baseRect = New TRectangle.Init(0, 0, rect.GetW(), _slotMinDimension.getY())
			ElseIf _orientation = GUI_OBJECT_ORIENTATION_HORIZONTAL
				baseRect = New TRectangle.Init(0, 0, _slotMinDimension.getX(), rect.GetH())
			Else
				TLogger.Log("TGUISlotList.GetSlotOrCoord", "unknown orientation : " + _orientation, LOG_ERROR)
			EndIf
		EndIf

		'set startpos at point of block displacement
		Local currentPosX:Float = _entriesBlockDisplacement.x
		Local currentPosY:Float = _entriesBlockDisplacement.y
		Local currentPosZ:Float
		'take scrolling into consideration
		currentPosX :+ guiEntriesPanel.scrollposition.x
		currentPosY :+ guiEntriesPanel.scrollPosition.y

		'set to invalid slot position
		currentPosZ = -1

		Local slotW:Int
		Local slotH:Int
		For Local i:Int = 0 To _slots.length-1
			'size the slot dimension accordingly
			slotW = _slotMinDimension.x
			slotH = _slotMinDimension.y
			'only use slots real dimension if occupied and not fixed
			If _slots[i] And Not _fixedSlotDimension
				slotW = Max(slotW, _slots[i].rect.w)
				slotH = Max(slotH, _slots[i].rect.h)
			EndIf

			'move base rect
			baseRect.SetXY(currentPosX, currentPosY)

			'if the current position + dimension contains the given
			'coord or is of this slot - return this position
			'1. GIVEN SLOT
			If slot >= 0 And i = slot Then Return new SVec3F(currentPosX, currentPosY, currentPosZ)
			'2. GIVEN COORD
			If coord
				If _slots[i] And Not _fixedSlotDimension
					'rects are "local", so remove the previously
					'added scroll positions
					If _slots[i].rect.containsXY(coord.x - guiEntriesPanel.scrollposition.x, coord.y - guiEntriesPanel.scrollPosition.y)
						currentPosZ = i
						Return new SVec3F(currentPosX, currentPosY, currentPosZ)
					EndIf
				Else
					If baseRect.containsXY(coord.x, coord.y)
						currentPosZ = i
						Return new SVec3F(currentPosX, currentPosY, currentPosZ)
					EndIf
				EndIf
			EndIf


			'move to the next one
			If _orientation = GUI_OBJECT_ORIENTATION_VERTICAL
				currentPosY :+ slotH
			ElseIf _orientation = GUI_OBJECT_ORIENTATION_HORIZONTAL
				currentPosX :+ slotW
			EndIf

			'add the displacement, z-value is stepping, not for LAST element
			If (i+1) Mod _entryDisplacement.z = 0 And i < _slots.length-1
				currentPosX :+ _entryDisplacement.x
				currentPosY :+ _entryDisplacement.y
			EndIf
		Next
		'return the end of the list coordinate ?!
		Return new SVec3F(currentPosX, currentPosY, currentPosZ)
	End Method


	Method GetSlotCoord:SVec3F(slot:Int)
		Return GetSlotOrCoord(slot, Null)
	End Method


	'get a slot by a (global/screen) coord
	Method GetSlotByCoord:Int(coord:TVec2D, isScreenCoord:Int=True)
		'convert global/screen to local coords
		If isScreenCoord And coord
			'create a copy of the given coord - avoids modifying it
			Local useCoord:TVec2D = coord.copy()
			useCoord.AddXY( - GetScreenRect().GetX(), - GetScreenRect().GetY() )
			Return GetSlotOrCoord(-1, useCoord).z
		Else
			Return GetSlotOrCoord(-1, coord).z
		EndIf
	End Method


	Method GetItemByCoord:TGUIobject(coord:TVec2D)
		Local slot:Int = Self.GetSlotByCoord(coord)
		Return Self.GetItemBySlot(slot)
	End Method


	'returns the slot of the previous occupied slot
	Method GetPreviousUsedSlot:Int(slot:Int)
		Local previousSlot:Int = slot-1
		If previousSlot < 0  Or previousSlot > Self._slots.length-1 Then Return -1
		While previousSlot >= 0
			If Self._slots[previousSlot] Then Return previousSlot
			previousSlot:-1
		Wend
		Return -1
	End Method


	'returns the slot of the next occupied slot
	Method GetNextUsedSlot:Int(slot:Int)
		Local nextSlot:Int = slot+1
		If nextSlot < 0  Or nextSlot > Self._slots.length-1 Then Return -1
		While nextSlot <= Self._slots.length-1
			If Self._slots[nextSlot] Then Return nextSlot
			nextSlot:+1
		Wend
		Return -1
	End Method


	Method GetItemBySlot:TGUIobject(slot:Int)
		If slot < 0 Or slot > Self._slots.length-1 Then Return Null

		Return Self._slots[slot]
	End Method


	'set the slots and emits events
	Method _SetSlot:Int(slot:Int, item:TGUIobject)
		If slot < 0 Or slot > Self._slots.length - 1 Then Return False

		'skip clearing an empty slot
		If Not item And Not Self._slots[slot] Then Return False

		Local slotItem:TGUIObject = Self._slots[slot]

		If item
			TriggerBaseEvent(GUIEventKeys.GUIList_AddItem, New TData.Add("item", item).Add("slot",slot) , Self)
			if TGUIListItem(item)
				TGUIListItem(item).parentListID = self._id
				TGUIListItem(item).parentListPosition = slot
			endif
		ElseIf slotItem
			TriggerBaseEvent(GUIEventKeys.GUIList_RemoveItem, New TData.Add("item", slotItem).Add("slot",slot) , Self)
			if TGUIListItem(item) 
				TGUIListItem(item).parentListID = -1
				TGUIListItem(item).parentListPosition = -1
			endif
		EndIf

		Self._slots[slot] = item
		
		'maybe items overlap others
		SortChildren()

		'resize item
		If item Then item.onParentResize()

		If item
			TriggerBaseEvent(GUIEventKeys.GUIList_AddedItem, New TData.Add("item", item).Add("slot",slot) , Self)
		ElseIf slotItem
			TriggerBaseEvent(GUIEventKeys.GUIList_RemovedItem, New TData.Add("item", slotItem).Add("slot",slot) , Self)
		EndIf

		Return True
	End Method


	'may return a object which was on the place where the new item is to position
	Method SetItemToSlot:Int(item:TGUIobject,slot:Int)
		'If slot < 0 or slot > _slots.length - 1 Then Throw "SetItemToSlot: slot " + slot + " out of valid range: 0 - " + (_slotAmount-1)
		If slot < 0 or slot > _slots.length - 1 Then Return False

		Local itemSlot:Int = Self.GetSlot(item)
		'somehow we try to place an item at the place where the item
		'already resides
		If itemSlot = slot Then Return True

		'is there another item?
		Local dragItem:TGUIobject = TGUIobject(Self.GetItemBySlot(slot))

		If dragItem
			'do not allow if the underlying item cannot get dragged
			If Not dragItem.isDragable() Then Return False

			'ask others if they want to intercept that exchange
			Local event:TEventBase = TEventBase.Create(GUIEventKeys.GUISlotList_OnBeginReplaceSlotItem, New TData.Add("source", item).Add("target", dragItem).Add("slot",slot), Self)
			event.Trigger()

			If Not event.isVeto()
				'remove the other one from the panel - and add back to guimanager
				If dragItem._parent Then dragItem._parent.RemoveChild(dragItem)

				'drag the other one
				dragItem.drag()
				'unset the occupied slot
				Self._SetSlot(slot, Null)

				TriggerBaseEvent(GUIEventKeys.GUISlotList_OnReplaceSlotItem, New TData.Add("source", item).Add("target", dragItem).Add("slot",slot) , Self)
			EndIf
		EndIf

		'if the item is already on the list, remove it from the former slot
		If itemSlot >= 0 Then Self._SetSlot(itemSlot, Null)

		guiEntriesPanel.addChild(item)

		'set the item to the new slot
		Self._SetSlot(slot, item)

		Self.RecalculateElements()

		Return True
	End Method


	'override default handler for the case of dropping something back to
	'its parent
	Method HandleDropBack:Int(triggerEvent:TEventBase)
		'as slotlists can easily compare "old slot" and "dropzone"-slot
		'we use this to check if the slot is changing..
		Local dropCoord:TVec2D = TVec2D(triggerEvent.GetData().get("coord"))
		Local item:TGUIobject = TGUIobject(triggerEvent.GetSender())
		'skip handling if important data is missing/incorrect
		If Not dropCoord Or Not item Then Return False

		'the drop-coordinate is the same one as the original slot, so we
		'handled that situation
		If dropCoord
			Local dropToSlot:Int = GetSlotByCoord(dropCoord)
			If dropToSlot >= 0 And dropToSlot = GetSlot(item)
				Return True
			EndIf
		EndIf

		Return False
	End Method


	Method OnTryReceiveDrop:Int(triggerEvent:TEventBase) override
		'only allow dropping of "new" items if there is a free slot
		'or if there is something which could be dragged instead
		if not HasItem(TGUIObject(triggerEvent.GetSender())) and GetUnusedSlotAmount() <= 0
			Local dropCoord:TVec2D = TVec2D(triggerEvent.GetData().get("coord"))
			If CanDropOnCoord(dropCoord) Then Return True
			
			triggerEvent.SetVeto(True)
			Return False
		Else
			Return True
		EndIf
	End Method
	
	
	Method CanDropOnCoord:Int(dropCoord:TVec2D)
		If dropCoord
			local addToSlot:Int = Self.GetSlotByCoord(dropCoord)
			If addToSlot >= 0 and CanDropOnSlot(addToSlot)
				Return True
			EndIf
		EndIf
		Return False
	End Method


	Method CanDropOnSlot:Int(slot:Int)
		local item:TGUIObject = GetItemBySlot(slot)
		if not item or item.IsDragable()
			Return True
		EndIf
		Return False
	End Method


	'overrideable AddItem-Handler
	Method AddItem:Int(item:TGUIobject, extra:Object=Null)
		Local addToSlot:Int = -1
		Local extraIsRawSlot:Int = False
		If String(extra) <> ""
			addToSlot = Int( String(extra) )
			extraIsRawSlot = True
		EndIf

		'search for first free slot
		If Self._autofillSlots Then addToSlot = Self.getFreeSlot()
		'auto slot requested
		If extraIsRawSlot And addToSlot = -1 Then addToSlot = Self.getFreeSlot()
		
		'no free slot or none given? find out on which slot we are dropping
		'if possible, drag the other one and drop the new
		If addToSlot < 0
			Local data:TData = TData(extra)
			If Not data Then Return False

			Local dropCoord:TVec2D = TVec2D(data.get("coord"))
			If Not dropCoord Then Return False

			'set slot to land
			addToSlot = Self.GetSlotByCoord(dropCoord)

		EndIf
		'no slot was hit or index out of bounds
		If addToSlot < 0 or addToSlot > _slots.length - 1
			If not extraIsRawSlot and not Self._autofillSlots
				print "WARNING: TGUISlotList.AddItem() to non autofillslot-list without passing a valid slot as param!"
				TLogger.Log("TGUISlotList.AddItem()", "Trying to add to non autofillslot-list without passing a valid slot as param!", LOG_ERROR)
			EndIf

			Return False
		EndIf

		'ask if an add to this slot is ok
		Local event:TEventBase =  TEventBase.Create(GUIEventKeys.GUIList_TryAddItem, New TData.Add("item", item).Add("slot",addtoSlot) , Self)
		event.Trigger()
		If event.isVeto() Then Return False

		'return if there is an underlying item which cannot get dragged
		Local dragItem:TGUIobject = TGUIobject(Self.GetItemBySlot(addToSlot))
		If dragItem And Not dragItem.isDragable() Then Return False

		'set parent of the item - so item is able to calculate position
		'disabled: will be done in Self.SetItemToSlot() if slots differ
		'guiEntriesPanel.addChild(item )


		'recalculate positions, dimensions etc.
		InvalidateLayout()

		Return Self.SetItemToSlot(item, addToSlot)
	End Method


	'overrideable RemoveItem-Handler
	Method RemoveItem:Int(item:TGUIobject)
		Local slot:Int = GetSlot(item)
		If slot >=0
			'ask if a removal from this slot is ok
			Local event:TEventBase = TEventBase.Create(GUIEventKeys.GUIList_TryRemoveItem, New TData.Add("item", item).Add("slot",slot) , Self)
			event.Trigger()
			If event.isVeto() Then Return False


			'remove from list - and add back to guimanager
			'do not call Remove() as Remove() could call RemoveItem() again
			'item.Remove()

			'remove from panel and item gets managed by guimanager
			guiEntriesPanel.removeChild(item)

			'remove it
			Self._SetSlot(slot, Null)

			'remove from panel - and add back to guimanager
			'guiEntriesPanel.removeChild(item)

			'recalculate positions, dimensions etc.
			InvalidateLayout()
'			Self.RecalculateElements()
			Return True
		EndIf
		Return False
	End Method


	Method DrawDebug()
		SetAlpha 0.25
		SetColor 255,0,0
		SetAlpha 0.25
		DrawRect(guiEntriesPanel.GetScreenRect().GetX(), guiEntriesPanel.GetScreenRect().GetY(), guiEntriesPanel.GetScreenRect().GetW(), guiEntriesPanel.GetScreenRect().GetH())
		SetColor 255,255,255
		SetAlpha 1.0
		DrawText("Slot: " + GetSlotByCoord(MouseManager.currentPos), guiEntriesPanel.GetScreenRect().GetX(), guiEntriesPanel.GetScreenRect().GetY() - 65)
		DrawText("ID:"+_id, guiEntriesPanel.GetScreenRect().GetX(), guiEntriesPanel.GetScreenRect().GetY() - 50)
		DrawText("scr:"+Int(guiEntriesPanel.scrollPosition.GetY())+"/"+Int(guiEntriesPanel.scrollLimit.GetY()), guiEntriesPanel.GetScreenRect().GetX(), guiEntriesPanel.GetScreenRect().GetY() - 35)
		DrawText("entrDim:"+Int(entriesDimension.GetY()), guiEntriesPanel.GetScreenRect().GetX(), guiEntriesPanel.GetScreenRect().GetY() - 20)


		Local atPoint:SVec2F = GetScreenRect().GetPosition()
		'restrict by scrollable panel - if not possible, there is no "space left"
		If RestrictViewport()
			Local pos:SVec3F
			For Local i:Int = 0 To Self._slots.length-1
			SetAlpha 0.3
				pos = GetSlotOrCoord(i)
				'print "slot "+i+": "+pos.GetX()+","+pos.GetY() +" result: "+(atPoint.GetX()+pos.getX())+","+(atPoint.GetY()+pos.getY()) +" h:"+self._slotMinDimension.getY()
				SetColor 0,0,0
				DrawRect(atPoint.x + pos.x, atPoint.y + pos.y, _slotMinDimension.x, _slotMinDimension.y)
				SetColor 255,255,255
				DrawRect(atPoint.x + pos.x + 1, atPoint.y + pos.y + 1, _slotMinDimension.x-2, _slotMinDimension.y-2)
			SetAlpha 0.8
				SetColor 0,0,0
				DrawText("slot "+i+"|"+GetSlotByCoord(new TVec2D(pos.x, pos.y)), atPoint.x + pos.x + 1, atPoint.y + pos.y + 1)
				SetColor 255,255,255
				DrawText("slot "+i+"|"+GetSlotByCoord(new TVec2D(pos.x, pos.y)), atPoint.x + pos.x, atPoint.y + pos.y)
			Next
			SetAlpha 1.0
			ResetViewPort()
		EndIf
	End Method


	Method RecalculateElements:Int()
		'reset current entriesDimension ...
		entriesDimension.CopyFrom(_entriesBlockDisplacement)

		'set startpos at point of block displacement
		Local currentPos:TVec2D = _entriesBlockDisplacement.copy()
		Local coveredArea:TRectangle = New TRectangle.Init(0,0,_entriesBlockDisplacement.x,_entriesBlockDisplacement.y)
		For Local i:Int = 0 To Self._slots.length-1
			Local slotW:Int = _slotMinDimension.getX()
			Local slotH:Int = _slotMinDimension.getY()
			'only use slots real dimension if occupied and not fixed
			If _slots[i] And Not _fixedSlotDimension
				slotW = Max(slotW, _slots[i].rect.getW())
				slotH = Max(slotH, _slots[i].rect.getH())
			EndIf

			'move entry's position to current one
			If _slots[i] Then _slots[i].rect.SetXY(currentPos)

			'resize covered area
			coveredArea.SetXY( Min(coveredArea.x, currentPos.x), Min(coveredArea.y, currentPos.y) )
			coveredArea.SetWH( Max(coveredArea.w, currentPos.x+slotW), Max(coveredArea.h, currentPos.y+slotH) )


			If _orientation = GUI_OBJECT_ORIENTATION_VERTICAL
				currentPos.AddXY(0, slotH )
				entriesDimension.AddXY(0, slotH)
			ElseIf Self._orientation = GUI_OBJECT_ORIENTATION_HORIZONTAL
				currentPos.AddXY(slotW, 0)
				entriesDimension.AddXY(slotW, 0)
			EndIf

			'add the displacement, z-value is stepping, not for LAST element
			If (i+1) Mod Self._entryDisplacement.z = 0 And i < _slots.length-1
				currentPos.AddXY(_entryDisplacement.x, _entryDisplacement.y)
				entriesDimension.AddXY(_entryDisplacement.x, _entryDisplacement.y)
			EndIf
		Next


		UpdateLimitsAndScrollerState()
	End Method


	Method UpdateLayout()
		Super.UpdateLayout()
	End Method


	'override
	Method GetFirstItem:TGUIListItem()
		For Local i:Int = 0 To _slots.length
			If _slots[i] Then Return TGUIListItem(_slots[i])
		Next
		Return Null
	End Method


	'override
	Method GetLastItem:TGUIListItem()
		For Local i:Int = _slots.length-1 To 0 Step -1
			If _slots[i] Then Return TGUIListItem(_slots[i])
		Next
		Return Null
	End Method


	'override
	Method GetLastItemY:Int()
		If Not _fixedSlotDimension
			Local i:TGUIListItem = GetLastItem()
			If i Then Return i.GetScreenRect().GetY()
			Return 0
		Else
			Return (_slots.length-1) * Int(_slotMinDimension.GetY())
		EndIf
	End Method
End Type
