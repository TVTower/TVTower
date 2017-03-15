SuperStrict
Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.world.worldtime.bmx"
Import "game.room.roomdoor.base.bmx"
Import "game.building.buildingtime.bmx"
Import "common.misc.hotspot.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx"


Type TRoomBaseCollection
	Field list:TList = new TList
	'caches for faster traversal
	Field _guidMap:TMap = null {nosave}
	Field _idMap:TIntMap = null {nosave}
	Global _eventsRegistered:int= FALSE
	Global _instance:TRoomBaseCollection


	Method New()
		if not _eventsRegistered
			'handle savegame loading (clear room occupants)
			EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
			'repair old savegames to set new flags
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			_eventsRegistered = TRUE
		Endif
	End Method


	Function GetInstance:TRoomBaseCollection()
		if not _instance then _instance = new TRoomBaseCollection
		return _instance
	End Function


	Method Initialize:int()
		list.Clear()
		_idMap = null
		_guidMap = null
	End Method
	

	Method Add:int(room:TRoomBase)
		if not room then return False
		
		'map-based approach
		'if not Get(room.ID)
		'	count :+ 1
		'endif
		'List.Insert(room.id, room)

		'list-based approach
		if not list.contains(room)
			GetIDMap().Insert(room.id, room)
			GetGUIDMap().Insert(room.GetLowerStringGUID(), room)
			list.AddLast(room)
		endif
		
		return TRUE
	End Method


	Method Remove:int(room:TRoomBase)
		'map-based approach
		'if Get(room.ID)
		'	List.Remove(room.id)
		'	count :- 1
		'	return TRUE
		'endif

		if list.Remove(room)
			_idMap.Remove(room.id)
			_guidMap.Remove( room.GetLowerStringGUID() )
			return True
		Endif
		
		return False
	End Method


	Method GetIDMap:TIntMap()
		if not _idMap
			_idMap = new TIntMap
			for local r:TRoomBase = EachIn list
				_idMap.insert(r.id, r)
			next
		endif
		return _idMap
	End Method


	Method GetGUIDMap:TMap()
		if not _guidMap
			_guidMap = new TMap
			for local r:TRoomBase = EachIn list
				_guidMap.insert(r.GetLowerStringGUID(), r)
			next
		endif
		return _guidMap
	End Method


	Method GetByGUID:TRoomBase(LS_guid:TLowerString)
		Return TRoomBase( GetGUIDMap().ValueForKey( LS_guid ) )
	End Method


	Method Get:TRoomBase(ID:int)
		Return TRoomBase( GetIDMap().ValueForKey(ID) )
		'For Local room:TRoomBase = EachIn GetInstance().list
		'	If room.id = ID Then Return room
		'Next
		'Return Null
	End Method


	Method GetRandom:TRoomBase()
		rem
		'map-based approach
		local i:Int = RandRange(0, GetInstance().count - 1) 
		For Local room:TRoomBase = EachIn GetInstance().list.Values()
			if not i then
				return room
			end if
			i :- 1
		next
		endrem
		'list-based approach
		return TRoomBase( list.ValueAtIndex( RandRange(0, list.Count() - 1) ) )
	End Method


	'returns all room fitting to the given details
	Function GetAllByDetails:TRoomBase[]( name:String, owner:Int=-1000, limit:int=0 ) {_exposeToLua}
		local rooms:TRoomBase[]
		For Local room:TRoomBase = EachIn GetInstance().list
			'print name+" <> "+room.name+"   "+owner+" <> "+room.owner
			'skip wrong owners
			if owner <> -1000 and room.owner <> owner then continue

			If room.GetName() = name Then rooms :+ [room]

			if limit > 0 and rooms.length = limit then return rooms
		Next
		Return rooms
	End Function


	Function GetFirstByDetails:TRoomBase( name:String, owner:Int=-1000 ) {_exposeToLua}
		local rooms:TRoomBase[] = GetAllByDetails(name, owner, 1)
		if not rooms or rooms.length = 0 then return Null
		return rooms[0]
	End Function


	Method UpdateEnteringAndLeavingStates()
		For Local room:TRoomBase = EachIn GetInstance().list
			'someone entering / leaving the room?
			For local action:TEnterLeaveAction = EachIn room.enteringStack
				if action.finishTime <= GetBuildingTime().GetMillisecondsGone() or GetBuildingTime().GetTimeFactor() < 0.25
					room.FinishEnter(action.entity)
				endif
			Next
			For local action:TEnterLeaveAction = EachIn room.leavingStack
				'if time is running slow, finish without waiting 
				if action.finishTime <= GetBuildingTime().GetMillisecondsGone() or GetBuildingTime().GetTimeFactor() < 0.25
					room.FinishLeave(action.entity)
				endif
			Next
		Next
	End Method


 	Method UpdateEmptyRooms()
		'stub
	End Method


	Method GetTotalRent:int(playerID:int)
		return 0
	End Method
	

	Method BeginRoomRental:int(room:TRoomBase, owner:int=0)
		return False
	End Method


	Method CancelRoomRentalsOfPlayer:int(owner:int)
		return False
	End Method


	Method CancelRoomRental:int(room:TRoomBase, owner:int=0)
		return False
	End Method
	

	'=== EVENTS ===

	'run when loading starts
	Function onSaveGameBeginLoad:int(triggerEvent:TEventBase)
		TLogger.Log("TRoomCollection", "Savegame started loading - clean occupants list", LOG_DEBUG | LOG_SAVELOAD)
		For local room:TRoomBase = eachin GetInstance().list
			room.occupants.Clear()
		Next
	End Function


	Function onSaveGameLoad:int(triggerEvent:TEventBase)
'		TLogger.Log("TRoomCollection", "Savegame finished loading - set flags for old savegames", LOG_DEBUG | LOG_SAVELOAD)
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetRoomBaseCollection:TRoomBaseCollection()
	Return TRoomBaseCollection.GetInstance()
End Function

Function GetRoomBase:TRoomBase(roomID:Int)
	Return TRoomBaseCollection.GetInstance().Get(roomID)
End Function

Function GetRoomBaseByGUID:TRoomBase(guid:string)
	Return TRoomBaseCollection.GetInstance().GetByGUID( TLowerString.Create(guid) )
End Function

Function GetRoomBaseByLSGUID:TRoomBase(LS_guid:TLowerString)
	Return TRoomBaseCollection.GetInstance().GetByGUID( LS_guid )
End Function



Type TRoomBase extends TOwnedGameObject {_exposeToLua="selected"}
	Field name:string
	Field LS_guid:TLowerString
	Field originalName:string
	'description, eg. "Bettys bureau" (+ "name of the owner" for "adagency ... owned by X")
	Field description:String[] = ["", ""]
	Field originalOwner:int = -1000
	Field flags:int = 0
	'does something block that room (eg. previous bomb attack)
	Field blockedState:Int = BLOCKEDSTATE_NONE 
	'time until this seconds in the game are gone
	Field blockedUntil:Double = 0
	Field blockedUntilShownInTooltip:int = False
	Field blockedText:string = ""
	'if > 0 : time a bomb was placed 
	Field bombPlacedTime:Double = -1
	'if > 0 : a bomb explosion will be drawn
	Field bombExplosionTime:Double = -1
	'bitmask (1/2/4/8) describing which players switched the signs of
	'the room - and therefore redirected eg. a bomb to the wrong room
	Field roomSignMovedByPlayers:int = 0
	'playerID of the player who switched last
	Field roomSignLastMoveByPlayerID:int = 0
	'name of the screen to use when in this room
	Field screenName:string = ""
	'the rent _agreed_ to (so GetRent() might return something different!)
	Field rent:int
	'when rented or rental got cancelled
	Field rentalChangeTime:Long = 0
	'how many times was the room rented yet?
	Field rentalTimes:int = 0
	

	'== ENTER / LEAVE VARIABLES ==
	'currently entering/leaving entities
	Field enteringStack:TEnterLeaveAction[]
	Field leavingStack:TEnterLeaveAction[]
	
	'the image used in the room (store individual backgrounds depending on "money")
	Field _background:TSprite {nosave}
	Field backgroundSpriteName:string
	'figures currently in this room
	Field occupants:TList = CreateList()
	'size of this room (eg. for studios)
	Field size:int = 1
	'list of special areas in the room
	Field hotspots:TList = CreateList()
	'is this a room or just a "plan" or "view"
	Field fakeRoom:int = FALSE {nosave}

	Global _initDone:int = FALSE

	'=== CONFIG FOR ALL ROOMS ===
	Global ChangeRoomSpeed:int = 600
	'game seconds until a bomb will explode
	Global bombFuseTime:Int = 5*60
	'realtime milliseconds a bomb visually explodes
	Global bombExplosionDuration:int = 1000

	Const BLOCKEDSTATE_NONE:int       = 0 'not blocked at all
	Const BLOCKEDSTATE_BOMB:int       = 1 'eg. after terrorists attacked
	Const BLOCKEDSTATE_RENOVATION:int = 2 'eg. for rooms not "bombable"
	Const BLOCKEDSTATE_MARSHAL:int    = 4 'eg. archive when not enough money
	Const BLOCKEDSTATE_SHOOTING:int   = 8 'studios: when in production


	'init a room base with basic variables
	Method Init:TRoomBase(name:String="unknown", description:String[], owner:int, size:int=1)
		self.name = name
		self.originalName = name
		self.owner = owner
		self.originalOwner = owner
		self.description = description
		self.size = Max(0, Min(3, size))

		'default studio rooms
		if name = "studio" then SetUsableAsStudio(true)

		LS_guid = TLowerString.Create( GetGUID() )

		return self
	End Method


	Method GenerateGUID:string()
		return "roombase-"+name+"-"+owner
	End Method


	Method GetLowerStringGUID:TLowerString()
		if not LS_guid then LS_guid = TLowerString.Create( GetGUID() )
		return LS_guid
	End Method


	Method HasFlag:Int(flag:Int) {_exposeToLua}
		Return flags & flag > 0
	End Method


	Method SetFlag:int(flag:int, enable:int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method
	

	Method PlaceBomb:int()
		bombPlacedTime = GetWorldTime().GetTimeGone()
	End Method


	Method addHotspot:int( hotspot:THotspot )
		if hotspot then hotspots.addLast(hotspot);return TRUE
		return FALSE
	End Method


	'sets the screen name to use when in this room
	Method SetScreenname:int(screenname:string)
		self.screenname = screenname
	End Method
	

	'returns the screen name to use when in this room
	Method GetScreenname:string()
		if IsUsedAsStudio() then return "screen_studio"
		return screenname
	End Method


	Method BeginRental:int(newOwner:int, rent:int)
		local oldOwner:int = owner
		ChangeOwner(newOwner)
		SetRented(True)
		rentalChangeTime = GetWorldTime().GetTimeGone()
		self.rent = rent
		rentalTimes :+ 1

		EventManager.triggerEvent( TEventSimple.Create("room.onBeginRental", New TData.AddString("roomGUID", GetGUID() ).AddNumber("owner", newOwner).AddNumber("oldOwner", oldOwner), self) )

		return True
	End Method


	Method CancelRental:int()
		local oldOwner:int = owner
		ChangeOwner(0)
		SetRented(False)
		rentalChangeTime = GetWorldTime().GetTimeGone()

		EventManager.triggerEvent( TEventSimple.Create("room.onCancelRental", New TData.AddString("roomGUID", GetGUID() ).AddNumber("owner", owner).AddNumber("oldOwner", oldOwner), self) )

		return True
	End Method


	'easy accessor to block a room using predefined values
	Method SetBlockedState:int(blockedState:int = 0)
		local time:int = 0
		
		'=== BOMB ===
		if blockedState & BLOCKEDSTATE_BOMB > 0
			'"placerholder rooms" (might get rent later)
			if owner = 0 and IsUsableAsStudio() 
				time = 60 * 60 * 24
			'rooms like movie agency
			elseIf owner = 0
				time = 60 * 60 * 2
			'player rooms
			elseIf owner > 0
				time = 60 * 30 
			endif

		'=== MARSHAL ===
		elseif blockedState & BLOCKEDSTATE_MARSHAL > 0
			'just blocks player rooms
			If owner > 0
				time = 60 * 15 * randRange(1,4) 
			endif

		'=== RENOVATION ===
		elseif blockedState & BLOCKEDSTATE_RENOVATION > 0
			if owner = 0 and IsUsableAsStudio() 
				'ATTENTION: "randRange" to get the same in multiplayer games
				time = 60 * 60 * randRange(5,10)
			elseIf owner = 0
				time = 60 * 30 * randRange(1,3)
			elseIf owner > 0
				time = 60 * 10 * randRange(1,2) 
			endif
		endif
			
		SetBlocked(time, blockedState) 
	End Method


	Method SetBlocked:int(blockTimeInSeconds:int = 0, newBlockedState:int = 0)
		blockedState :| newBlockedState

		'show the time until end of blocking
		'- when marshal visited the room
		'- when terrorist put a bomb into a room
		'- when shooting / production takes place
		if blockedState & (BLOCKEDSTATE_SHOOTING | BLOCKEDSTATE_MARSHAL | BLOCKEDSTATE_BOMB) <> 0
			blockedUntilShownInTooltip = True
		endif
			
		blockedUntil = GetWorldTime().GetTimeGone() + blockTimeInSeconds

		'remove blockage without effects!
		if blockTimeInSeconds = 0
			blockedState = BLOCKEDSTATE_NONE
			blockedUntilShownInTooltip = False
		endif

		if blockedState <> BLOCKEDSTATE_NONE
			KickOccupants(null)
		endif

		'inform others
		EventManager.triggerEvent( TEventSimple.Create("room.onSetBlocked", New TData.AddString("roomGUID", GetGUID() ).AddString("newBlockedState", newBlockedState).AddNumber("blockTimeInSeconds", blockTimeInSeconds), Null, self) )
	End Method


	Method SetUnblocked:int()
		'when it was got bombed, free the room now
		if blockedState & BLOCKEDSTATE_BOMB > 0
			if IsUsableAsStudio() then SetRented(False)
		EndIf
				
		blockedState = BLOCKEDSTATE_NONE
	End Method


	Method IsBlocked:Int()
		if blockedState > BLOCKEDSTATE_NONE and blockedUntil < GetWorldTime().GetTimeGone()
			SetUnBlocked()
		EndIf
		return (blockedState > BLOCKEDSTATE_NONE)
	End Method


	Method SetUsableAsStudio:int(bool:int = True)
		SetFlag(TVTRoomFlag.USABLE_AS_STUDIO, bool)
	End Method


	Method IsUsableAsStudio:int()
		return HasFlag(TVTRoomFlag.USABLE_AS_STUDIO)
	End Method


	Method SetUsedAsStudio:int(bool:int = True)
		if IsUsedAsStudio() = bool then return False

		_background = null
		SetFlag(TVTRoomFlag.USED_AS_STUDIO, bool)
	End Method


	Method IsUsedAsStudio:int()
		return HasFlag(TVTRoomFlag.USED_AS_STUDIO)
	End Method


	Method SetRented:int(bool:int = True)
		SetFlag(TVTRoomFlag.IS_RENTED, bool)
	End Method


	Method IsRented:int()
		return HasFlag(TVTRoomFlag.IS_RENTED)
	End Method


	Method IsRentable:int()
		'you cannot rent:
		'- already rented rooms
		'- freehold rooms (like boss rooms, player offices...)
		'- fake rooms (porter, room plan, ...)
		return not IsRented() and not IsFreehold() and not IsFake()
	End Method


	'for flats which are not "rented" but in possess of the owner
	'(like newsroom, archive - or some important rooms like movie agency)
	Method SetFreehold:int(bool:int = True)
		SetFlag(TVTRoomFlag.FREEHOLD, bool)
	End Method


	Method IsFreehold:int()
		return HasFlag(TVTRoomFlag.FREEHOLD)
	End Method


	'rooms which are no real "rooms" so a figure stays standing in
	'front of it (porter, room plans, ...)
	Method SetFake:int(bool:int = True)
		SetFlag(TVTRoomFlag.FAKE_ROOM, bool)
	End Method


	Method IsFake:int()
		return HasFlag(TVTRoomFlag.FAKE_ROOM)
	End Method


	Method HasOwner:int()
		return (owner > 0)
	End Method


	Method GetBackground:TSprite()
		if not _background and backgroundSpriteName<>""
			_background = GetSpriteFromRegistry(backgroundSpriteName)
		endif
		return _background
	End Method


	Method GetID:int() {_exposeToLua}
		return id
	End Method


	Method GetName:string() {_exposeToLua}
		if IsUsedAsStudio() then return "studio"
		return name
	End Method


	Method GetOwner:int() {_exposeToLua}
		return owner
	End Method


	Method GetOriginalOwner:int() {_exposeToLua}
		return originalOwner
	End Method


	Method GetSize:int() {_exposeToLua}
		return size
	End Method


	'returns the rent you have to pay for this roo
	'(pay attention to _not_ pay the rent if it is a freehold)
	Method GetRent:int() {_exposeToLua}
		if IsRented() then return rent

		'add 1000 for <10 times, 500 for 11-20 rental times
		'and additional 100 for each time above 20
		local addRentalPenalty:int = 0
		if rentalTimes >= 20 then  addRentalPenalty :+ rentalTimes * 100
		if rentalTimes < 20 then  addRentalPenalty :+ rentalTimes * 500
		if rentalTimes < 10 then  addRentalPenalty :+ rentalTimes * 500

		return GetSize() * (5000 + addRentalPenalty)
	End Method


	'change the owner of this room
	Method ChangeOwner:int(newOwner:int)
		local event:TEventSimple = TEventSimple.Create("room.onChangeOwner", new TData.AddNumber("oldOwner", self.owner).AddNumber("newOwner", newOwner), self)
		EventManager.triggerEvent(event)

		if not event.IsVeto()
			'to auto-repair old savegames:
			if self.originalOwner = -1000 then self.originalOwner = owner
			
			self.owner = newOwner
			return True
		else
			'someone is against changing the owner
			return False
		endif
	End Method


	Method isOccupant:int(entity:TEntity)
		return occupants.contains(entity)
	End Method


	Method addOccupant:int(entity:TEntity)
		if not occupants.contains(entity)
			occupants.addLast(entity)
		endif
		return TRUE
	End Method


	Method removeOccupant:int(entity:TEntity)
		if not occupants.contains(entity) then return FALSE

		occupants.remove(entity)
		return TRUE
	End Method


	Method KickOccupants:int(kickingEntity:TEntity = null)
		For local occupant:TEntity = EachIn occupants
			removeOccupant(occupant)
		Next
	End Method
	

	'returns if occupants (figure-sprites) in this room are drawn in the
	'building (eg. for plan room)
	Method ShowsOccupants:int()
		'maybe offload it to xml and a room-property
		if fakeRoom then return True

		return False
	End Method


	'returns whether the entity can enter this room
	'override this in custom rooms
	Method CanEntityEnter:int(entity:TEntity)
		'access to this room is blocked (eg. repair after attack)
		if IsBlocked() then return False

		'one could enter if:
		'no entity is in the room
		if not HasOccupant() then return True
		'all can enter if there is no limit...
		if HasFlag(TVTRoomFlag.ALLOW_MULTIPLE_OCCUPANTS) then return True
		'entity is already in the room
		if IsOccupant(entity) then return True
		
		return False
	End Method
	

	'returns whether the entity can leave the room
	Method CanEntityLeave:int(entity:TEntity=null)
		'by default everyone can leave
		return TRUE
	End Method
	

	'draw Room
	Method Draw:int()
		'emit event so custom draw functions can run
		EventManager.triggerEvent( TEventSimple.Create("room.onDraw", null, self) )
		'emit event limited to a specific room name
		EventManager.triggerEvent( TEventSimple.Create("room."+self.GetName()+".onDraw", null, self) )

		return 0
	End Method


	'checks the room for a placed bomb
	Method CheckForBomb:int()
		'was a bomb placed? check fuse and detonation time
		if bombPlacedTime >= 0 and not (blockedState & BLOCKEDSTATE_BOMB > 0)
			if bombPlacedTime + bombFuseTime < GetWorldTime().GetTimeGone()
				SetBlockedState(BLOCKEDSTATE_BOMB)
				'time is NOT a gametime but a real time!
				'so the explosion is visible for a given time independent
				'from game speed
				bombExplosionTime = Time.GetTimeGone()

				'reset placed time
				bombPlacedTime = -1

				'inform others
				EventManager.triggerEvent( TEventSimple.Create("room.onBombExplosion", New TData.AddString("roomGUID", GetGUID()).AddNumber("roomSignMovedByPlayers", roomSignMovedByPlayers).AddNumber("roomSignLastMoveByPlayerID", roomSignLastMoveByPlayerID), Null, self) )
				'EventManager.triggerEvent( TEventSimple.Create("room.onBombExplosion", New TData.AddString("roomGUID", GetGUID()).AddNumber("bombRedirectedByPlayers", bombRedirectedByPlayers).AddNumber("bombLastRedirectedByPlayerID", bombLastRedirectedByPlayerID), Null, self) )
			endif
		endif
	End Method


	'process special functions of this room. Is there something to click on?
	'animated gimmicks? draw within this function.
	Method Update:Int()
		'emit event so custom updaters can handle
		EventManager.triggerEvent( TEventSimple.Create("room.onUpdate", null, self) )
		'emit event after updating
		EventManager.triggerEvent( TEventSimple.Create("room.onUpdateDone", null, self) )

		return 0
	End Method


	Method GetDescriptionLocalized:TLocalizedString()
		return TLocalization.GetLocalizedString(description[0])
	End Method


	'returns desc-field with placeholders replaced
	'line 1: "Movie Agency"
	'line 2: "Owner: Mr. Y"
	Method GetDescription:string(lineNumber:int=1) {_exposeToLua}
		if description = null then return ""
		lineNumber = Max(0, Min(description.length, lineNumber))

		local res:string

		if lineNumber = 1 and IsRentable()
			if IsUsableAsStudio()
				res = GetLocale("ROOM_FREE_STUDIO")
			else
				res = GetLocale("ROOM_FREE_ROOM")
			endif
		elseif lineNumber = 1 and IsUsedAsStudio()
			res = GetLocale("ROOM_STUDIO_OF")
		elseif lineNumber = 2 and (IsUsableAsStudio() or IsUsedAsStudio())
			res = GetLocale("ROOM_SIZE").replace("%SIZE%", size)
		else
			res = GetLocale(description[lineNumber-1])
		endif

		return res
	End Method


	Method hasOccupant:int()
		return occupants.count() > 0
	End Method


	Method _AddEnterLeaveEntity:int(direction:int = 1, entity:TEntity, door:TRoomDoorBase, finishTime:Long)
		if _HasEnterLeaveEntity(direction, entity) then _RemoveEnterLeaveEntity(direction, entity)

		local action:TEnterLeaveAction = new TEnterLeaveAction
		action.entity = entity
		action.door = door
		action.finishTime = finishTime

		if direction = 1
			enteringStack :+ [action]
		elseif direction = 2
			leavingStack :+ [action]
		endif
		return True
	End Method


	Method _RemoveEnterLeaveEntity:int(direction:int = 1, entity:TEntity)
		if not _HasEnterLeaveEntity(direction, entity) then return False

		local newStack:TEnterLeaveAction[]
		local stack:TEnterLeaveAction[]
		if direction = 1
			stack = enteringStack
		elseif direction = 2
			stack = leavingStack
		endif
		
		For local action:TEnterLeaveAction = EachIn stack
			if not action or action.entity = entity then continue

			newStack :+ [action]
		Next

		if direction = 1
			enteringStack = newStack
		elseif direction = 2
			leavingStack = newStack
		endif

		return True
	End Method


	Method _HasEnterLeaveEntity:int(direction:int = 1, entity:TEntity)
		local stack:TEnterLeaveAction[]
		if direction = 1
			stack = enteringStack
		elseif direction = 2
			stack = leavingStack
		endif

		For local action:TEnterLeaveAction = EachIn stack
			if not action then continue

			if action.entity = entity then return True
		Next
		return False
	End Method


	Method AddEnteringEntity:int(entity:TEntity, door:TRoomDoorBase, finishTime:Long)
		return _AddEnterLeaveEntity(1, entity, door, finishTime)
	End Method


	Method RemoveEnteringEntity:int(entity:TEntity)
		return _RemoveEnterLeaveEntity(1, entity)
	End Method


	Method HasEnteringEntity:int(entity:TEntity)
		return _HasEnterLeaveEntity(1, entity)
	End Method


	Method AddLeavingEntity:int(entity:TEntity, door:TRoomDoorBase, finishTime:Long)
		return _AddEnterLeaveEntity(2, entity, door, finishTime)
	End Method


	Method RemoveLeavingEntity:int(entity:TEntity)
		return _RemoveEnterLeaveEntity(2, entity)
	End Method


	Method HasLeavingEntity:int(entity:TEntity)
		return _HasEnterLeaveEntity(2, entity)
	End Method


	'==== ENTER / LEAVE PROCESS ====
Rem
    === ENTER ===
	figure.EnterRoom()
		-> figure.CanEnterRoom()
			-> room.CanEntityEnter()
		-> figure.TryEnterRoom()
			-> ev: figure.onTryEnterRoom
		-> figure.BeginEnterRoom()
			-> ev: figure.onBeginEnterRoom
			-> room.BeginEnter()
				-> add occupant (right when opening the door, avoids
								 simultaneous enter of 2+ figures)
				-> ev: room.onBeginEnter

		-> figure.FinishEnterRoom() (when time has passed, via Updat())
			-> ev: figure.onFinishEnterRoom
			-> figure.SetInRoom(Room)
			-> room.FinishEnter()
				-> ev: room.onEnter
	=== LEAVE ===
	figure.LeaveRoom()
		-> figure.CanEnterRoom()
			-> room.CanEntityLeave()
		-> ev: figure.onTryLeaveRoom
		-> room.BeginLeave()
			-> ev: room.onBeginLeave
		-> room.FinishLeave() (delayed --> door anim)
			-> remove occupant (when door closes)
			-> figureCollection.onLeaveRoom()
				-> figure.FinishLeaveRoom()
					-> ev: figure.onLeaveRoom
					-> figure.SetInRoom(null)
End Rem

	Method BeginEnter:int(door:TRoomDoorBase, entity:TEntity, speed:int)
		if door and entity
			door.Open(entity)
		Endif
 		'set the room used in that moment to avoid that two entities
 		'opening the door at the same time will both get into the room
 		'(occupied check is done in "TFigureBase.EnterRoom()")
		'if not hasOccupant() then addOccupant(entity)

		addOccupant(entity)

		AddEnteringEntity(entity, door, GetBuildingTime().GetMillisecondsGone() + speed)

		'inform others that we start going into the room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginEnter", null, self, entity ) )
	End Method
	

	Method FinishEnter:int(enteringEntity:TEntity)
		if not enteringEntity
			TLogger.Log("TRoomBase.FinishEnter", "Called without an entity entering", LOG_ERROR)
			return False
		endif
		
		'=== CLOSE DOORS ===
		local enteringDoor:TRoomDoorBase
		for local action:TEnterLeaveAction = Eachin enteringStack
			'set a default door
			if not enteringDoor then enteringDoor = action.door
			
			if action.door.GetDoorType() >= 0
				'only close the door if it was the entity (or nobody) who
				'opened it...
				if action.door.openedByEntityGUID = "" or action.door.openedByEntityGUID = enteringEntity.GetGUID()
					action.door.Close(enteringEntity)

					'use a closed door
					enteringDoor = action.door
				endif
			endif
		next

		RemoveEnteringEntity(enteringEntity)

		'inform that the figure finished entering the room - eg for AI-scripts
		EventManager.triggerEvent( TEventSimple.Create("room.onFinishEnter", new TData.Add("door", enteringDoor), self, enteringEntity ) )
	End Method


	Method BeginLeave:int(door:TRoomDoorBase, entity:TEntity, speed:int)
		'open the door
		if not door then door = GetRoomDoorBaseCollection().GetMainDoorToRoom(id)
		if door and door.GetDoorType() >= 0
			door.Open(entity)
		EndIf
		
		'figure isn't in that room - so just leave
		if not isOccupant(entity) then return TRUE

		AddLeavingEntity(entity, door, GetBuildingTime().GetMillisecondsGone() + 2*speed)

		'inform others that we start going out of that room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginLeave", null, self, entity ) )
	End Method


	Method FinishLeave:int(leavingEntity:TEntity)
		if not leavingEntity
			TLogger.Log("TRoomBase.FinishEnter", "Called without an entity leaving", LOG_ERROR)
			return False
		endif
		
		'=== CLOSE DOORS ===
		local leavingDoor:TRoomDoorBase
		for local action:TEnterLeaveAction = Eachin leavingStack
			'set a default door
			if not leavingDoor then leavingDoor = action.door
			
			if action.door.GetDoorType() >= 0
				'only close the door if it was the entity (or nobody) who
				'opened it...
				if action.door.openedByEntityGUID = "" or action.door.openedByEntityGUID = leavingEntity.GetGUID()
					action.door.Close(leavingEntity)

					'use a closed door
					leavingDoor = action.door
				endif
			endif
		next
		'no door used? use default one!
		if not leavingDoor then leavingDoor = GetRoomDoorBaseCollection().GetMainDoorToRoom(id)

		'remove the occupant from the rooms list after animation finished
		'and entity really left that room
		removeOccupant(leavingEntity)

		RemoveLeavingEntity(leavingEntity)

		EventManager.triggerEvent( TEventSimple.Create("room.onFinishLeave", new TData.Add("door", leavingDoor), self, leavingEntity ) )
	End Method
End Type


Type TEnterLeaveAction
	Field entity:TEntity
	Field door:TRoomDoorBase
	Field finishTime:Long = -1
End Type
	
