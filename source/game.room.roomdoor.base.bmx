SuperStrict
Import "Dig/base.framework.entity.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.helper.bmx"
Import "game.building.buildingtime.bmx"
Import "game.gameconstants.bmx"

Type TRoomDoorBaseCollection
	Field List:TList = CreateList()

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


	Method Initialize:Int()
		'call Remove() for all objects so they can unregister stuff
		'and tidy up in general
		For local r:TRoomDoorBase = EachIn list
			r.RemoveFromCollection(self)
		Next

		list.Clear()
	End Method


	Method Get:TRoomDoorBase(id:int)
		For local door:TRoomDoorBase = eachin List
			if door.id = id then return door
		Next
		return Null
	End Method


	Method GetByGUID:TRoomDoorBase(GUID:String)
		For local door:TRoomDoorBase = eachin List
			if door.GetGUID() = GUID then return door
		Next
		return Null
	End Method


	Method GetFirstByDetails:TRoomDoorBase( roomName:String, roomOwner:Int =-1, onFloor:int =-1 )
		For Local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().list
			'skip wrong floors
			If onFloor >=0 and door.GetOnFloor() <> onFloor Then Continue
			'skip wrong owners
			If roomOwner >= 0 And door.GetOwner() <> roomOwner Then Continue
			If door.GetRoomName() <> roomName Then Continue
			
			Return door
		Next
		Return Null
	End Method


	Method GetByDetails:TRoomDoorBase[]( roomName:String, roomOwner:Int =-1, onFloor:int =-1 )
		Local result:TRoomDoorBase[]
		For Local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().list
			'skip wrong floors
			If onFloor >=0 and door.GetOnFloor() <> onFloor Then Continue
			'skip wrong owners
			If roomOwner >= 0 And door.GetOwner() <> roomOwner Then Continue
			If door.GetRoomName() <> roomName Then Continue
			
			result :+ [door]
		Next
		Return result
	End Method


	'returns a door by the given (local to parent/building) coordinates
	Method GetByCoord:TRoomDoorBase( x:Int, y:Int )
		For Local door:TRoomDoorBase = EachIn list
			'also allow invisible rooms... so just check if hit the area
			'If room.doortype >= 0 and THelper.IsIn(x, y, room.Pos.x, Building.area.position.y + TBuilding.GetFloorY2(room.pos.y) - room.doorDimension.Y, room.doorDimension.x, room.doorDimension.y)
			If THelper.IsIn(x, y, door.area.GetIntX(), int(door.area.y - (door.area.h -1)), int(door.area.w), int(door.area.h))
				Return door
			EndIf
		Next
		Return Null
	End Method
	

	Method GetFirstByRoomID:TRoomDoorBase(roomID:int)
		For local door:TRoomDoorBase = eachin List
			if door.roomID = roomID then return door
		Next
		return Null
	End Method


	Method GetDoorsToRoom:TRoomDoorBase[]( roomID:int )
		local res:TRoomDoorBase[]

		For Local door:TRoomDoorBase = EachIn list
			if door.roomID = roomID then res :+ [door]
		Next
		return res
	End Method


	'returns the first door connected to a room
	Method GetMainDoorToRoom:TRoomDoorBase( roomID:Int )
		'Ronny TODO: add configuration "mainDoor"
		'            or remove whole function and replace with
		'            "nearestDoorToRoom" ?
		local doors:TRoomDoorBase[] = GetDoorsToRoom(roomID)
		If doors.length = 0 then return Null
		return doors[0]
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
		return TRoomDoorBase( list.ValueAtIndex( RandRange(0, list.Count() - 1) ) )
	End Method


	Method GetByMapPos:TRoomDoorBase( doorSlot:Int, doorFloor:Int )
		if doorSlot >= 0 and doorFloor >= 0
			For Local door:TRoomDoorBase= EachIn list
				If door.onFloor = doorFloor And door.doorSlot = doorSlot Then Return door
			Next
		EndIf
		Return Null
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetRoomDoorBaseCollection:TRoomDoorBaseCollection()
	Return TRoomDoorBaseCollection.GetInstance()
End Function




Type TRoomDoorBase extends TRenderableEntity  {_exposeToLua="selected"}
	'time is set in Init() depending on changeRoomSpeed..
	Field DoorTimer:TBuildingIntervalTimer = new TBuildingIntervalTimer.Init(1)
	'the id of the room
	Field roomID:int = -1
	'floor in the building
	Field onFloor:Int = -1
	'door 1-4 on floor (<0 is invisible, -1 is unset)
	Field doorSlot:Int = -1
	Field doorType:Int = -1
	'offset from "center" of the door - which is where figures enter
	Field stopOffset:Int = 0
	Field doorFlags:Int
	'who opened the door as the last one (this entity also closes the
	'door then)
	Field openedByEntityGUID:string
	Field _sprite:TSprite {nosave}
	
	
	Method New()
		'set default flags
		SetFlag(TVTRoomDoorFlag.SHOW_TOOLTIP)
	End Method


	Method GenerateGUID:string()
		return "roomdoor-"+roomID+"-"+doorSlot+"-"+onFloor
	End Method


	Method hasFlag:Int(flag:Int) {_exposeToLua}
		Return (doorFlags & flag)
	End Method


	Method setFlag(flag:Int, enable:Int=True)
		If enable
			doorFlags :| flag
		Else
			doorFlags :& ~flag
		EndIf
	End Method
	

	Method GetOnFloor:int()
		return onFloor
	End Method


	Method GetDoorType:int()
		if DoorTimer.isExpired() then return doortype else return 5
	End Method


	Method IsOpen:int()
		return getDoorType() >= 5
	End Method


	Method GetSprite:TSprite()
		if not _sprite
			_sprite = GetSpriteFromRegistry("gfx_building_Tueren")
			if _sprite.name = "defaultsprite"
				local tmpSprite:TSprite = _sprite
				_sprite = null
				return tmpSprite
			endif
		endif
		Return _sprite
	End Method


	Method Close(entity:TEntity)
		'timer finished
		If Not DoorTimer.isExpired() then DoorTimer.expire()
	End Method


	Method Open(entity:TEntity)
		DoorTimer.reset()
		if entity
			openedByEntityGUID = entity.GetGUID()
		else
			openedByEntityGUID = ""
		endif
	End Method


	Method IsVisible:int()
		If doorType < 0 OR area.GetX() <= 0 then Return FALSE

		Return TRUE
	End Method


	Method GetRoomName:String()
		return "unknown"
	End Method


	Method GetOwnerName:String()
		return "unknown"
	End Method


	Method GetOwner:Int()
		return 0
	End Method


	Method RemoveFromCollection:Int(collection:object = null)
		Return True
	End Method
End Type