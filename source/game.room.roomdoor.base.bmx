SuperStrict
Import "Dig/base.framework.entity.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"


Type TRoomDoorBaseCollection
	Field List:TList = CreateList()
	'doors drawn to Pixmap of background
	Field _doorsDrawnToBackground:Int	= 0

	Global _eventsRegistered:int= FALSE
	Global _instance:TRoomDoorBaseCollection


	Method New()
		if not _eventsRegistered
			'register global events
			_eventsRegistered = TRUE
		Endif
	End Method


	Function GetInstance:TRoomDoorBaseCollection()
		if not _instance then _instance = new TRoomDoorBaseCollection
		return _instance
	End Function


	Method Get:TRoomDoorBase(id:int)
		For local door:TRoomDoorBase = eachin List
			if door.id = id then return door
		Next
		return Null
	End Method


	Method Add:int(door:TRoomDoorBase)
		'if there is a room with the same id, remove that first
		if door.id > 0
			local existingDoor:TRoomDoorBase = Get(door.id)
			if existingDoor then Remove(existingDoor)
		endif

		List.AddLast(door)
		return TRUE
	End Method


	Method Remove:int(door:TRoomDoorBase)
		List.Remove(door)
		return TRUE
	End Method


	Method CloseAllDoors()
		For Local door:TRoomDoorBase = EachIn list
			door.Close(null)
		Next
	End Method


	Method DrawAllDoors:Int()
		For Local door:TRoomDoorBase = EachIn list
			'skip invisible doors (without door-sprite)
			'Ronny TODO: maybe replace "invisible doors" with
			'            hotspots + room signs (if visible in elevator)
			If not door.IsVisible() then continue

			door.Render()
		Next
	End Method



	Method GetRandom:TRoomDoorBase()
		return TRoomDoorBase( list.ValueAtIndex( Rand(list.Count() - 1) ) )
	End Method


	Method GetByMapPos:TRoomDoorBase( doorSlot:Int, doorFloor:Int )
		if doorSlot >= 0 and doorFloor >= 0
			For Local door:TRoomDoorBase= EachIn list
				If door.area.GetY() = doorFloor And door.doorSlot = doorSlot Then Return door
			Next
		EndIf
		Return Null
	End Method


	Method DrawDoorsOnBackground:Int()
		'do nothing if already done
		If _doorsDrawnToBackground then return 0

		Local Pix:TPixmap = LockImage(GetSpriteFromRegistry("gfx_building").parent.image)

		'elevator border
		Local elevatorBorder:TSprite= GetSpriteFromRegistry("gfx_building_Fahrstuhl_Rahmen")
		For Local i:Int = 0 To 13
			DrawImageOnImage(elevatorBorder.getImage(), Pix, 230, 67 - elevatorBorder.area.GetH() + 73*i)
		Next

		For Local door:TRoomDoorBase = EachIn list
			'skip invisible doors (without door-sprite)
			If not door.IsVisible() then continue
			door.DrawOnBackground(Pix)
		Next
		'no unlock needed atm as doing nothing
		'UnlockImage(GetSpriteFromRegistry("gfx_building").parent.image)
		_doorsDrawnToBackground = True
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetRoomDoorBaseCollection:TRoomDoorBaseCollection()
	Return TRoomDoorBaseCollection.GetInstance()
End Function




Type TRoomDoorBase extends TStaticEntity  {_exposeToLua="selected"}
	'Field area:
	'  position.x is x of the rooms door in the building
	'  position.y is floornumber
	'time is set in Init() depending on changeRoomSpeed..
	Field DoorTimer:TIntervalTimer = TIntervalTimer.Create(1)
	'door 1-4 on floor (<0 is invisible, -1 is unset)
	Field doorSlot:Int = -1
	Field doortype:Int = -1

	const doorSlot0:int	= -10						'x coord of defined slots
	const doorSlot1:int	= 206
	const doorSlot2:int	= 293
	const doorSlot3:int	= 469
	const doorSlot4:int	= 557


	Function getDoorSlotX:int(slot:int)
		select slot
			case 1	return doorSlot1
			case 2	return doorSlot2
			case 3	return doorSlot3
			case 4	return doorSlot4
		end select

		return 0
	End Function


	Method getDoorSlot:int()
		'already adjusted...
		if doorSlot >= 0 then return doorSlot

		if area.GetX() = doorSlot1 then return 1
		if area.GetX() = doorSlot2 then return 2
		if area.GetX() = doorSlot3 then return 3
		if area.GetX() = doorSlot4 then return 4

		return 0
	End Method


	Method getDoorFloor:int()
		return area.GetY()
	End Method
	 

	Method getDoorType:int()
		if DoorTimer.isExpired() then return doortype else return 5
	End Method


	Method Close(entity:TEntity)
		'timer finished
		If Not DoorTimer.isExpired() then DoorTimer.expire()
	End Method


	Method Open(entity:TEntity)
		DoorTimer.reset()
	End Method


	Method IsVisible:int()
		If doorType < 0 OR area.GetX() <= 0 then Return FALSE

		Return TRUE
	End Method


	Method DrawOnBackground:Int(pix:TPixmap)
		'base door does nothing
	End Method
End Type