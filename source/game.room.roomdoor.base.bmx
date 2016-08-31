SuperStrict
Import "Dig/base.framework.entity.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.building.buildingtime.bmx"


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
	'who opened the door as the last one (this entity also closes the
	'door then)
	Field openedByEntityGUID:string


	Method GenerateGUID:string()
		return "roomdoor-"+roomID+"-"+doorSlot+"-"+onFloor
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
		return GetSpriteFromRegistry("gfx_building_Tueren")
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


	Method GetOwnerName:String()
		return "unknown"
	End Method


	Method GetOwner:Int()
		return 0
	End Method
End Type