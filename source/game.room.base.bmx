SuperStrict
Import "Dig/base.framework.entity.bmx"
Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.world.worldtime.bmx"
Import "game.room.roomdoor.base.bmx"
Import "common.misc.hotspot.bmx"


Type TRoomBaseCollection
	Field list:TList = CreateList()
	Global _eventsRegistered:int= FALSE
	Global _instance:TRoomBaseCollection


	Method New()
		if not _eventsRegistered
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
			_eventsRegistered = TRUE
		Endif
	End Method


	Function GetInstance:TRoomBaseCollection()
		if not _instance then _instance = new TRoomBaseCollection
		return _instance
	End Function


	Method Reset:int()
		list.Clear()
		'also set back the ids
		TRoomBase.LastID = 0
	End Method
	

	Method Add:int(room:TRoomBase)
		List.AddLast(room)
		return TRUE
	End Method


	Method Remove:int(room:TRoomBase)
		List.Remove(room)
		return TRUE
	End Method


	Function Get:TRoomBase(ID:int)
		For Local room:TRoomBase = EachIn GetInstance().list
			If room.id = ID Then Return room
		Next
		Return Null
	End Function


	Function GetRandom:TRoomBase()
		return TRoomBase( GetInstance().list.ValueAtIndex( Rand(GetInstance().list.Count() - 1) ) )
	End Function


	'returns all room fitting to the given details
	Function GetAllByDetails:TRoomBase[]( name:String, owner:Int=-1000 ) {_exposeToLua}
		local rooms:TRoomBase[]
		For Local room:TRoomBase = EachIn GetInstance().list
			'print name+" <> "+room.name+"   "+owner+" <> "+room.owner
			'skip wrong owners
			if owner <> -1000 and room.owner <> owner then continue

			If room.name = name Then rooms :+ [room]
		Next
		Return rooms
	End Function


	Function GetFirstByDetails:TRoomBase( name:String, owner:Int=-1000 ) {_exposeToLua}
		local rooms:TRoomBase[] = GetAllByDetails(name,owner)
		if not rooms or rooms.length = 0 then return Null
		return rooms[0]
	End Function


	'=== EVENTS ===

	'run when loading finished
	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		TLogger.Log("TRoomCollection", "Savegame started loading - clean occupants list", LOG_DEBUG | LOG_SAVELOAD)
		For local room:TRoomBase = eachin GetInstance().list
			room.occupants.Clear()
		Next
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



Type TRoomBase extends TEntityBase {_exposeToLua="selected"}
	Field name:string
	Field originalName:string
	'description, eg. "Bettys bureau" (+ "name of the owner" for "adagency ... owned by X")
	Field description:String[] = ["", ""]
	'playerID or -1 for system/artificial person
	Field owner:Int	= -1
	'can this room be rented or still occupied?
	Field availableForRent:Int = False
	'can this room be used as a studio?
	Field usableAsStudio:Int = False
	'does something block that room (eg. previous bomb attack)
	Field blockedState:Int = BLOCKEDSTATE_NONE 
	'time until this seconds in the game are gone
	Field blockedUntil:Double = 0
	'if > 0 : time a bomb was placed 
	Field bombPlacedTime:Double = -1
	'if > 0 : a bomb explosion will be drawn
	Field bombExplosionTime:Double = -1
	Field screenName:string = ""
	'who/what did use the door the last time (opening/closing)
	'only this entity closes/opens the door then!
	Field lastDoorUser:TEntity
	'the image used in the room (store individual backgrounds depending on "money")
	Field _background:TSprite {nosave}
	Field backgroundSpriteName:string
	'figures currently in this room
	Field occupants:TList = CreateList()
	'allow more occupants than one?
	Field allowMultipleOccupants:int = FALSE
	'is this a room or just a "plan" or "view"
	Field fakeRoom:int = FALSE
	'size of this room (eg. for studios)
	Field size:int = 1
	'list of special areas in the room
	Field hotspots:TList = CreateList()

	Global _initDone:int = FALSE

	'=== CONFIG FOR ALL ROOMS ===
	'time the change of a room needs (1st half is opening, 2nd closing a door)
	Global ChangeRoomSpeed:int = 500
	'game seconds until a bomb will explode
	Global bombFuseTime:Int = 5*60
	'realtime milliseconds a bomb visually explodes
	Global bombExplosionDuration:int = 1000

	Const BLOCKEDSTATE_NONE:int       = 0 'not blocked at all
	Const BLOCKEDSTATE_BOMB:int       = 1 'eg. after terrorists attacked
	Const BLOCKEDSTATE_RENOVATION:int = 2 'eg. for rooms not "bombable"
	Const BLOCKEDSTATE_MARSHAL:int    = 3 'eg. archive when not enough money


	'init a room base with basic variables
	Method Init:TRoomBase(name:String="unknown", description:String[], owner:int, size:int=1)
		self.name = name
		self.originalName = name
		self.owner = owner
		self.description = description
		self.size = Max(0, Min(3, size))

		'default studio rooms
		if name = "studio" then SetUsableAsStudio(true)

		return self
	End Method


	Method GenerateGUID:string()
		return "roombase-"+name+"-"+owner
	End Method


	Method PlaceBomb:int()
		bombPlacedTime = GetWorldTime().GetTimeGone()
	End Method


	Method addHotspot:int( hotspot:THotspot )
		if hotspot then hotspots.addLast(hotspot);return TRUE
		return FALSE
	End Method


	'easy accessor to block a room using predefined values
	Method SetBlockedState:int(blockedState:int = 0)
		local time:int = 0
		
		'=== BOMB ===
		if blockedState = BLOCKEDSTATE_BOMB
			'"placerholder rooms" (might get rent later)
			if owner = 0 and IsUsableAsStudio() 
				time = 60 * 24
			'rooms like movie agency
			elseIf owner = 0
				time = 60 * 2
			'player rooms
			elseIf owner > 0
				time = 30 
			endif
		endif

		'=== RENOVATION ===
		if blockedState = BLOCKEDSTATE_RENOVATION
			if owner = 0 and IsUsableAsStudio() 
				'ATTENTION: "randRange" to get the same in multiplayer games
				time = 60 * randRange(5,10)
			elseIf owner = 0
				time = 30 * randRange(1,3)
			elseIf owner > 0
				time = 10 * randRange(1,2) 
			endif
		endif

		'=== MARSHAL ===
		if blockedState = BLOCKEDSTATE_RENOVATION
			'just blocks player rooms
			If owner > 0
				time = 15 * randRange(1,4) 
			endif
		endif
			
		SetBlocked(time, blockedState) 
	End Method


	Method SetBlocked:int(blockTimeInMinutes:int = 0, blockedState:int = 0)
		'remove blockage without effects!
		if blockTimeInMinutes = 0
			blockedState = BLOCKEDSTATE_NONE
		else
			self.blockedState = blockedState
			blockedUntil = GetWorldTime().GetTimeGone() + 60*blockTimeInMinutes
		endif
	End Method


	Method SetUnblocked:int()
		'when it was got bombed, free the room now
		if blockedState = BLOCKEDSTATE_BOMB
			if IsUsableAsStudio() then SetAvailableForRent(True)
		EndIf
				
		blockedState = BLOCKEDSTATE_NONE
	End Method



	Method IsBlocked:Int()
		if blockedState <> BLOCKEDSTATE_NONE and blockedUntil < GetWorldTime().GetTimeGone()
			SetUnBlocked()
		EndIf
		return (blockedState <> BLOCKEDSTATE_NONE)
	End Method


	Method SetUsableAsStudio:int(bool:int = True)
		usableAsStudio = bool
	End Method


	Method IsUsableAsStudio:int()
		return usableAsStudio
	End Method


	Method SetAvailableForRent:int(bool:int = True)
		availableForRent = bool
	End Method


	Method IsAvailableForRent:int()
		return fakeRoom = 0 and not HasOwner() and availableForRent
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
		return GetLocale(name)
	End Method


	Method GetOwner:int() {_exposeToLua}
		return owner
	End Method


	Method GetSize:int() {_exposeToLua}
		return size
	End Method


	'change the owner of this room
	Method ChangeOwner:int(newOwner:int)
		local event:TEventSimple = TEventSimple.Create("room.onChangeOwner", new TData.AddNumber("oldOwner", self.owner).AddNumber("newOwner", newOwner), self)
		EventManager.triggerEvent(event)

		if not event.IsVeto()
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
		if allowMultipleOccupants then return True
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
		EventManager.triggerEvent( TEventSimple.Create("room."+self.name+".onDraw", null, self) )

		return 0
	End Method


	'checks the room for a placed bomb
	Method CheckForBomb:int()
		'was a bomb placed? check fuse and detonation time
		if bombPlacedTime >= 0 and blockedState <> BLOCKEDSTATE_BOMB
			if bombPlacedTime + bombFuseTime < GetWorldTime().GetTimeGone()
				SetBlockedState(BLOCKEDSTATE_BOMB)
				'time is NOT a gametime but a real time!
				'so the explosion is visible for a given time independent
				'from game speed
				bombExplosionTime = Time.GetTimeGone()
				'reset placed time
				bombPlacedTime = -1
			endif
		endif
	End Method


	'process special functions of this room. Is there something to click on?
	'animated gimmicks? draw within this function.
	Method Update:Int()
		'emit event so custom updaters can handle
		EventManager.triggerEvent( TEventSimple.Create("room.onUpdate", null, self) )
		'emit event limited to a specific room name
		EventManager.triggerEvent( TEventSimple.Create("room."+self.name+".onUpdate", null, self) )

		return 0
	End Method


	'returns desc-field with placeholders replaced
	Method GetDescription:string(lineNumber:int=1) {_exposeToLua}
		if description = null then return ""
		lineNumber = Max(0, Min(description.length, lineNumber))

		local res:string = GetLocale(description[lineNumber-1])

		'free rooms get a second line added
		'containing size information
		if lineNumber = 2 and IsUsableAsStudio()
			res = GetLocale("ROOM_SIZE").replace("%SIZE%", size)
		endif

		return res
	End Method


	Method hasOccupant:int()
		return occupants.count() > 0
	End Method


	'==== ENTER / LEAVE PROCESS ====
Rem
    === ENTER ===
	figure.EnterRoom()
		-> figure.CanEnterRoom()
			-> room.CanEntityEnter()
		-> ev: figure.onTryEnterRoom
		-> room.BeginEnter()
			-> add occupant (right when opening the door, avoids
			                 simultaneous enter of 2+ figures)
			-> ev: room.onBeginEnter
			-> ev: room.onEnter (delayed --> door anim)
				-> room.FinishEnter()
					-> TFigureCollection.onEnterRoom()
						-> figure.onEnterRoom()
							-> ev: figure.onEnterRoom
							-> figure.SetInRoom(Room)
	=== LEAVE ===
	figure.LeaveRoom()
		-> figure.CanEnterRoom()
			-> room.CanEntityLeave()
		-> ev: figure.onTryLeaveRoom
		-> room.BeginLeave()
			-> ev: room.onBeginLeave
			-> ev: room.onLeave (delayed --> door anim)
				-> room.FinishLeave()
					-> remove occupant (when door closes)
				-> figureCollection.onLeaveRoom()
					-> figure.FinishLeaveRoom()
						-> ev: figure.onLeaveRoom
						-> figure.SetInRoom(null)
End Rem

	Method BeginEnter:int(door:TRoomDoorBase, entity:TEntity, speed:int)
		if door and entity
			door.Open(entity)
			lastDoorUser = entity
		Endif

 		'set the room used in that moment to avoid that two entities
 		'opening the door at the same time will both get into the room
 		'(occupied check is done in "TFigureBase.EnterRoom()")
		'if not hasOccupant() then addOccupant(entity)
rem
		if hasOccupant()
			TLogger.Log("TRoomBase.BeginEnter()", "Figure enters room=~q"+GetName()+"~q while other figures are already in the room.", LOG_DEBUG | LOG_ERROR)
			print "Entering: "+entity.GetGUID()
			print "In Room:"
			For local e:TEntity = Eachin occupants
				print "  - "+e.GetGUID()
			Next
			print "-------"
		Endif
endrem
		addOccupant(entity)

		'inform others that we start going into the room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginEnter", null, self, entity ) )

		'finally inform that the figure enters the room - eg for AI-scripts
		'but delay that by ChangeRoomSpeed/2 - so the real entering takes place later
		local event:TEventSimple = TEventSimple.Create("room.onEnter", new TData.Add("door", door), self, entity )
		if speed = 0
			EventManager.triggerEvent(event)
		else
			event.delayStart(speed/2)
			EventManager.registerEvent(event)
		endif
	End Method
	

	Method FinishEnter:int(door:TRoomDoorBase, entity:TEntity)
		'=== CLOSE DOORS ===
		if door and door.GetDoorType() >= 0
			'only close the door if it was the entity (or nobody) who
			'opened it...
			if lastDoorUser = entity or lastDoorUser = null
				door.Close(entity)
				lastDoorUser = null
			endif
		endif
	End Method


	Method BeginLeave:int(door:TRoomDoorBase, entity:TEntity, speed:int)
		'door is unused atm
		
		'figure isn't in that room - so just leave
		if not isOccupant(entity) then return TRUE

		'inform others that we start going out of that room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginLeave", null, self, entity ) )

		'finally inform that the figure leaves the room - eg for AI-scripts
		'but delay that ChangeRoomSpeed/2 - so the real leaving takes place later
		local event:TEventSimple = TEventSimple.Create("room.onLeave", null, self, entity )
		if speed = 0
			'fire immediately
			EventManager.triggerEvent(event)
		else
			'delay so that the leaving takes half the time available
			event.delayStart(speed/2)
			EventManager.registerEvent(event)
		endif
	End Method


	Method FinishLeave:int(door:TRoomDoorBase, entity:TEntity)
		'open the door
		if door and door.GetDoorType() >= 0
			door.Open(entity)
			lastDoorUser = entity 
		EndIf

		'remove the occupant from the rooms list after animation finished
		'and entity really left that room
		removeOccupant(entity)
	End Method




	'=== EVENTS ===

	'as soon as a room gets entered ...close the doors
	Function onEnter:Int( triggerEvent:TEventBase )
		local entity:TEntity = TEntity(triggerEvent.GetReceiver())
		local room:TRoomBase = TRoomBase(triggerEvent.GetSender())

		if not entity or not room then return False

		local door:TRoomDoorBase = TRoomDoorBase(triggerEvent.getData().get("door"))

		room.FinishEnter(door, entity)
	End Function


	'gets called when the figure really leaves the room (fadein animation finished etc)
	Function onLeave:int( triggerEvent:TEventBase )
		local entity:TEntity = TEntity(triggerEvent.GetReceiver())
		local room:TRoomBase = TRoomBase(triggerEvent.getSender())
		if not entity or not room then return FALSE

		'using a specific door?
		local door:TRoomDoorBase = TRoomDoorBase( triggerEvent.getData().get("door") )

		room.FinishLeave(door, entity)
	End Function
End Type
