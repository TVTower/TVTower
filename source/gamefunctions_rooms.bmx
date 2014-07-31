Type TRoomCollection
	Field list:TList = CreateList()
	Global _eventsRegistered:int= FALSE
	Global _instance:TRoomCollection


	Method New()
		if not _eventsRegistered
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
			_eventsRegistered = TRUE
		Endif
	End Method


	Function GetInstance:TRoomCollection()
		if not _instance then _instance = new TRoomCollection
		return _instance
	End Function


	Method Add:int(room:TRoom)
		List.AddLast(room)
		return TRUE
	End Method


	Method Remove:int(room:TRoom)
		List.Remove(room)
		return TRUE
	End Method


	Function Get:TRoom(ID:int)
		For Local room:TRoom = EachIn _instance.list
			If room.id = ID Then Return room
		Next
		Return Null
	End Function


	Function GetRandom:TRoom()
		return TRoom( _instance.list.ValueAtIndex( Rand(_instance.list.Count() - 1) ) )
	End Function


	'returns all room fitting to the given details
	Function GetAllByDetails:TRoom[]( name:String, owner:Int=-1000 ) {_exposeToLua}
		local rooms:TRoom[]
		For Local room:TRoom = EachIn _instance.list
			'print name+" <> "+room.name+"   "+owner+" <> "+room.owner
			'skip wrong owners
			if owner <> -1000 and room.owner <> owner then continue

			If room.name = name Then rooms :+ [room]
		Next
		Return rooms
	End Function


	Function GetFirstByDetails:TRoom( name:String, owner:Int=-1000 ) {_exposeToLua}
		local rooms:TRoom[] = GetAllByDetails(name,owner)
		if not rooms or rooms.length = 0 then return Null
		return rooms[0]
	End Function


	'run when loading finished
	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		TLogger.Log("TRoomCollection", "Savegame started loading - clean occupants list", LOG_DEBUG | LOG_SAVELOAD)
		For local room:TRoom = eachin _instance.list
			room.occupants.Clear()
		Next
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetRoomCollection:TRoomCollection()
	Return TRoomCollection.GetInstance()
End Function




'container for data describing the room
'without data attached which is used for visual representation
'(tooltip, hotspots, signs...) -> they are now in TRoomDoor
'usage examples:
' - RoomAgency
' - Multiple "Doors" to the same room
Type TRoom {_exposeToLua="selected"}
	Field name:string
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
	
	'the image used in the room (store individual backgrounds depending on "money")
	Field _background:TSprite {nosave}
	Field backgroundSpriteName:string
	'figure currently in this room
	Field occupants:TList = CreateList()
	'allow more occupants than one?
	Field allowMultipleOccupants:int = FALSE
	'list of special areas in the room
	Field hotspots:TList = CreateList()
	'is this a room or just a "plan" or "view"
	Field fakeRoom:int = FALSE
	'size of this room (eg. for studios)
	Field size:int = 1
	Field id:int = 0
	Field GUID:string = ""
	Global LastID:int = 0
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


	Method New()
		LastID:+1
		id = LastID

		'register all needed events if not done yet
		if not _initDone
			EventManager.registerListenerFunction("room.onLeave", onLeave)
			EventManager.registerListenerFunction("room.onEnter", onEnter)
			_initDone = TRUE
		endif

		GetRoomCollection().Add(self)
	End Method


	Method onLoad:int()
		'
	End Method


	Method AssignToScreen:int(screen:TInGameScreen_Room)
		if screen
			screen.SetRoom(self)
			return TRUE
		else
			return FALSE
		endif
	End Method


	'init a room with basic variables
	Method Init:TRoom(name:String="unknown", description:String[], owner:int, size:int=1)
		self.GUID = "room_"+self.id
		self.name = name
		self.owner = owner
		self.description = description
		self.size = Max(0, Min(3, size))

		'default studio rooms
		if name = "studio" then SetUsableAsStudio(true)

		return self
	End Method


	Method PlaceBomb:int()
		bombPlacedTime = GetWorldTime().GetTimeGone()
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


	'returns if figure-sprites in this room are drawn in the building
	'(eg. for plans)
	Method ShowsFigures:int()
		'maybe offload it to xml and a room-property
		if fakeRoom then return True
		'If (not inRoom Or inRoom.name = "elevatorplaner")

		return False
	End Method


	'draw Room
	Method Draw:int()
		'if not self.screen then Throw "ERROR: room.draw() - screen missing";return 0
		'draw current screen
		'ScreenCollection.DrawCurrent(App.timer.getTween())
		'emit event so custom functions can run after screen draw, sender = screen
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenDraw", new TData.Add("room", self) , ScreenCollection.GetCurrentScreen() ) )

		'emit event so custom draw functions can run
		EventManager.triggerEvent( TEventSimple.Create("room.onDraw", null, self) )

		return 0
	End Method


	'checks the room for a placed bomb
	Method CheckForBomb:int()
		'was a bomb placed? check fuse and detonation time
		if bombPlacedTime >= 0 and blockedState <> TRoom.BLOCKEDSTATE_BOMB
			if bombPlacedTime + bombFuseTime < GetWorldTime().GetTimeGone()
				SetBlockedState(TRoom.BLOCKEDSTATE_BOMB)
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
		'emit event so custom functions can run after screen update, sender = screen
		'also this event has "room" as payload
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenUpdate", new TData.Add("room", self) , ScreenCollection.GetCurrentScreen() ) )

		'emit event so custom updaters can handle
		EventManager.triggerEvent( TEventSimple.Create("room.onUpdate", null, self) )

		return 0
	End Method


	Method GetOwnerPlayerName:string()
		If GetPlayerCollection().IsPlayer(owner)
			Return GetPlayerCollection().Get(owner).name
		Endif
		Return "UNKNOWN PLAYER"
	End Method


	Method GetOwnerChannelName:string()
		If GetPlayerCollection().IsPlayer(owner)
			Return GetPlayerCollection().Get(owner).channelName
		Endif
		Return "UNKNOWN CHANNEL"
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

		if res.Find("%") = -1 then return res

		res = res.Replace("%PLAYERNAME%", GetOwnerPlayerName())
		res = res.Replace("%CHANNELNAME%", GetOwnerChannelName())

		return res
	End Method



	Method isOccupant:int(figure:TFigure)
		return occupants.contains(figure)
	End Method


	Method hasOccupant:int()
		return occupants.count() > 0
	End Method


	Method addOccupant:int(figure:TFigure)
		if not occupants.contains(figure)
			occupants.addLast(figure)
		endif
		return TRUE
	End Method


	Method removeOccupant:int(figure:TFigure)
		if not occupants.contains(figure) then return FALSE

		occupants.remove(figure)
		return TRUE
	End Method


	Method addHotspot:int( hotspot:THotspot )
		if hotspot then hotspots.addLast(hotspot);return TRUE
		return FALSE
	End Method


	'==== ENTER / LEAVE PROCESS ====
Rem
    === ENTER ===
	figure.EnterRoom()
		-> room.CanFigureEnter()
		-> ev: figure.onTryEnterRoom
		-> room.DoEnter()
			-> add occupant (right when opening the door, avoids
			                 simultaneous enter of 2+ figures)
			-> ev: room.onBeginEnter
			-> ev: room.onEnter (delayed --> door anim)
				-> room.onEnter()
					-> figure.onEnterRoom()
						-> ev: figure.onEnterRoom
						-> figure.SetInRoom(Room)
	=== LEAVE ===
	figure.LeaveRoom()
		-> room.CanFigureLeave()
		-> ev: figure.onTryLeaveRoom
		-> room.DoLeave()
			-> ev: room.onBeginLeave
			-> ev: room.onLeave (delayed --> door anim)
				-> room.onLeave()
					-> remove occupant (when door closes)
					-> figure.onLeaveRoom()
						-> ev: figure.onLeaveRoom
						-> figure.SetInRoom(null)
End Rem

	Method DoEnter:int(door:TRoomDoor, figure:TFigure, speed:int)
		if door and figure then door.Open(figure)

 		'set the room used in that moment to avoid that two figures
 		'opening the door at the same time will both get into the room
 		'(occupied check is done in "onFigureTryEnterRoom")
		if not hasOccupant() then addOccupant(figure)

		'kick other figures from the room if figure is the owner 
		'only player-figures need such handling (events etc.)
		If figure.parentPlayerID and figure.parentPlayerID = owner
			for local occupant:TFigure = eachin occupants
				if occupant <> figure then figure.KickFigureFromRoom(occupant, self)
			next
		EndIf
	
		'inform others that we start going into the room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginEnter", new TData.Add("figure", figure) , self ) )

		'finally inform that the figure enters the room - eg for AI-scripts
		'but delay that by ChangeRoomSpeed/2 - so the real entering takes place later
		local event:TEventSimple = TEventSimple.Create("room.onEnter", new TData.Add("figure", figure) , self )
		if speed = 0
			EventManager.triggerEvent(event)
		else
			event.delayStart(speed/2)
			EventManager.registerEvent(event)
		endif
	End Method


	'gets called when the figure really enters a room (fadeout animation finished etc)
	Function onEnter:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent.getData().get("figure") )
		if not figure then return FALSE

		local room:TRoom = TRoom(triggerEvent.getSender())
		if not room then return FALSE

		local door:TRoomDoor = TRoomDoor( triggerEvent.getData().get("door") )

		'close the door (for now: close all doors to this room)
		if not door
			For door = eachin TRoomDoor.GetDoorsToRoom(room)
				If door.GetDoorType() >= 0 then door.Close(figure)
			Next
		else
			If door.GetDoorType() >= 0 then door.Close(figure)
		endif

		'inform figure that it now entered the room
		figure.onEnterRoom(room, door)
	End Function


	'returns whether the figure can enter this room
	'override this in custom rooms
	Method CanFigureEnter:int(figure:TFigure)
		'access to this room is blocked (eg. repair after attack)
		if IsBlocked() then return False
		'all can enter if there is no limit...
		if allowMultipleOccupants then return True
		'non players can enter everytime
		if not figure.parentPlayerID then return True
		'players must be owner of the room
		If figure.parentPlayerID = owner then return True

		return False
	End Method
	

	Method DoLeave:int(figure:TFigure, speed:int)
		'figure isn't in that room - so just leave
		if not isOccupant(figure) then return TRUE

		figure.isChangingRoom = true

		'inform others that we start going out of that room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginLeave", new TData.Add("figure", figure) , self ) )

		'finally inform that the figure leaves the room - eg for AI-scripts
		'but delay that ChangeRoomSpeed/2 - so the real leaving takes place later
		local event:TEventSimple = TEventSimple.Create("room.onLeave", new TData.Add("figure", figure) , self )
		if speed = 0
			'fire immediately
			EventManager.triggerEvent(event)
		else
			'delay so that the leaving takes half the time available
			event.delayStart(speed/2)
			EventManager.registerEvent(event)
		endif
	End Method


	'gets called when the figure really leaves the room (fadein animation finished etc)
	Function onLeave:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent.getData().get("figure") )
		local room:TRoom = TRoom(triggerEvent.getSender())
		if not figure or not room then return FALSE

		'open the door
		'which door to open?
		local door:TRoomDoor = TRoomDoor( triggerEvent.getData().get("door") )
		if not door then door = TRoomDoor.GetMainDoorToRoom(room)

		if door and door.GetDoorType() >= 0 then door.Open(figure)

		'remove the occupant from the rooms list after animation finished
		'and figure really left that room
		room.removeOccupant(figure)

		'inform figure that it now left the room
		figure.onLeaveRoom(room)
	End Function


	'returns whether the figure can leave the room
	Method CanFigureLeave:int(figure:TFigure=null)
		'by default everyone can leave
		return TRUE
	End Method
End Type


Type TRoomDoorTooltip extends TTooltip
	Field roomID:int

	Function Create:TRoomDoorTooltip(title:String = "", content:String = "unknown", x:Int = 0, y:Int = 0, w:Int = -1, h:Int = -1, lifetime:Int = 300)
		local obj:TRoomDoorTooltip = new TRoomDoorTooltip
		obj.Initialize(title, content, x, y, w, h, lifetime)
		return obj
	End Function


	Method AssignRoom(roomID:int)
		self.roomID = roomID
	End Method


	'override to add "blocked" support
	Method DrawBackground:int(x:int, y:int, w:int, h:int)
		local room:TRoom = GetRoomCollection().Get(roomID)
		if not room then return False

		local oldCol:TColor = new TColor.Get()

		if room.IsBlocked()
			SetColor 255,235,215
		else
			SetColor 255,255,255
		endif
		DrawRect(x, y, w, h)

		oldCol.SetRGB()
	End Method


	'override to modify header col
	Method SetHeaderColor:int()
		local room:TRoom = GetRoomCollection().Get(roomID)
		if room and room.isBlocked()
			SetColor 250,230,210
		else
			Super.SetHeaderColor()
		endif
	End Method
	


	Method Update:Int()
		local room:TRoom = GetRoomCollection().Get(roomID)
		if not room then return False

		'adjust image used in tooltip
		If room.name = "archive" Then tooltipimage = 0
		If room.name = "office" Then tooltipimage = 1
		If room.name = "chief" Then tooltipimage = 2
		If room.name = "news" Then tooltipimage = 4
		If room.name.Find("studio",0) = 0 Then tooltipimage = 5
		'adjust header bg color
		If room.owner >= 1 then
			TitleBGtype = room.owner + 10
		Else
			TitleBGtype = 0
		EndIf


		local newTitle:String = room.GetDescription(1)
		if newTitle <> title then SetTitle(newTitle)

		local newContent:String = room.GetDescription(2)
		if room.IsBlocked()
			'add line spacer
			if newContent<>"" then newContent :+ chr(13) + chr(13)
			'add blocked message
			newContent :+ GetLocale("ROOM_IS_BLOCKED")
		endif
		if newContent <> content then SetContent(newContent)

		Super.Update()
	End Method
End Type




Type TRoomDoor extends TStaticEntity  {_exposeToLua="selected"}
	'Field area:
	'  position.x is x of the rooms door in the building
	'  position.y is floornumber

	Field room:TRoom
	'uses description
	Field tooltip:TRoomDoorTooltip = null
	'time is set in Init() depending on changeRoomSpeed..
	Field DoorTimer:TIntervalTimer = TIntervalTimer.Create(1)
	'door 1-4 on floor (<0 is invisible, -1 is unset)
	Field doorSlot:Int = -1
	Field doortype:Int = -1
	Field _soundSource:TDoorSoundSource = Null {nosave}
	Field sign:TRoomDoorSign = null

	Global list:TList = CreateList()				'List of doors
	Global _doorsDrawnToBackground:Int	= 0			'doors drawn to Pixmap of background

	const doorSlot0:int	= -10						'x coord of defined slots
	const doorSlot1:int	= 206
	const doorSlot2:int	= 293
	const doorSlot3:int	= 469
	const doorSlot4:int	= 557


	'create room and use preloaded image
	Method Init:TRoomDoor(room:TRoom, doorSlot:int=-1, x:Int=0, floor:Int=0, doortype:Int=-1)
		'autocalc the position
		if x=-1 and doorSlot>=0 AND doorSlot<=4 then x = getDoorSlotX(doorSlot)

		'assign variables
		self.room = room

		DoorTimer.setInterval( TRoom.ChangeRoomSpeed )

		'x = x of the given doorSlot
		'y = floor
		'w = door width
		'h = door height
		self.area = new TRectangle.Init(x, floor, GetSpriteFromRegistry("gfx_building_Tueren").framew, 52)
		self.doorSlot = doorSlot
		self.doorType = doorType

		'give it an ID
		GenerateID()
		'create the sign next to room's door
		CreateRoomsign()

		list.AddLast(self)

		Return self
	End Method


	Method GetSoundSource:TDoorSoundSource()
		if not _soundSource then _soundSource = TDoorSoundSource.Create(self)
		return _soundSource
	End Method


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


	Method Close(figure:TFigure)
		'timer finished
		If Not DoorTimer.isExpired()
			GetSoundSource().PlayCloseDoorSfx(figure)
			DoorTimer.expire()
		Endif
	End Method


	Method Open(figure:TFigure)
		'timer ticks again
		If DoorTimer.isExpired()
			GetSoundSource().PlayOpenDoorSfx(figure)
		Endif
		DoorTimer.reset()
	End Method


	Function CloseAll()
		For Local door:TRoomDoor = EachIn list
			door.Close(null)
		Next
	End Function


	Method DrawTooltip:Int()
		If not tooltip or not tooltip.enabled then return False

		tooltip.Render()
	End Method


	Function DrawAllTooltips:Int()
		For Local door:TRoomDoor = EachIn list
			door.DrawTooltip()
		Next
	End Function


	Method UpdateTooltip:Int()
		'only show tooltip if not "empty" and mouse in door-rect
		If room.GetDescription(1) <> "" and GetPlayerCollection().Get().Figure.IsInBuilding() And THelper.MouseIn(area.GetX(), GetBuilding().area.GetY()  + TBuilding.GetFloorY(area.GetY()) - area.GetH(), area.GetW(), area.GetH())
			If not tooltip
				tooltip = TRoomDoorTooltip.Create("", "", 100, 140, 0, 0)
				tooltip.AssignRoom(room.id)
			endif

			tooltip.Hover()
			tooltip.enabled	= 1
		EndIf


		If tooltip AND tooltip.enabled
			tooltip.Update()

			tooltip.area.position.SetY( GetBuilding().area.position.y + TBuilding.GetFloorY(area.GetY()) - GetSpriteFromRegistry("gfx_building_Tueren").area.GetH() - 20 )
			tooltip.area.position.setX( area.GetX() + area.GetW()/2 - tooltip.GetWidth()/2 )

			'delete old tooltips
			if tooltip.lifetime < 0 then tooltip = null
		EndIf

	End Method


	Function UpdateToolTips:Int()
		For Local door:TRoomDoor = EachIn list
			'delete and skip if not found
			If not door
				list.remove(door)
				continue
			Endif

			door.UpdateTooltip()
		Next
	End Function


	Method IsVisible:int()
		'skip invisible doors (without door-sprite)
		'Ronny TODO: maybe replace "invisible doors" with hotspots + room signes (if visible in elevator)
		If room = null then Return FALSE
		If room.name = "roomboard" OR room.name = "credits" OR room.name = "porter" then Return FALSE
		If doorType < 0 OR area.GetX() <= 0 then Return FALSE

		Return TRUE
	End Method


	Function DrawDoorsOnBackground:Int()
		'do nothing if already done
		If _doorsDrawnToBackground then return 0

		Local Pix:TPixmap = LockImage(GetSpriteFromRegistry("gfx_building").parent.image)

		'elevator border
		Local elevatorBorder:TSprite= GetSpriteFromRegistry("gfx_building_Fahrstuhl_Rahmen")
		For Local i:Int = 0 To 13
			DrawImageOnImage(elevatorBorder.getImage(), Pix, 230, 67 - elevatorBorder.area.GetH() + 73*i)
		Next

		local doorSprite:TSprite = GetSpriteFromRegistry("gfx_building_Tueren")
		For Local door:TRoomDoor = EachIn list
			'skip invisible doors (without door-sprite)
			If not door.IsVisible() then continue

			'clamp doortype
			door.doorType = Min(5, door.doorType)
			'draw door
			DrawImageOnImage(doorSprite.GetFrameImage(door.doorType), Pix, door.area.GetX() - GetBuilding().area.GetX() - 127, TBuilding.GetFloorY(door.area.GetY()) - doorSprite.area.GetH())
		Next
		'no unlock needed atm as doing nothing
		'UnlockImage(GetSpriteFromRegistry("gfx_building").parent.image)
		_doorsDrawnToBackground = True
	End Function


	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		local doorSprite:TSprite = GetSpriteFromRegistry("gfx_building_Tueren")

		'==== DRAW DOOR ====
		If getDoorType() >= 5
			If getDoorType() = 5 AND DoorTimer.isExpired() Then Close(null)
			'valign = 1 -> subtract sprite height
			doorSprite.Draw(xOffset + area.GetX(), yOffset + GetBuilding().area.GetY() + TBuilding.GetFloorY(area.GetY()), getDoorType(), ALIGN_LEFT_BOTTOM)
		EndIf


		'==== DRAW DOOR SIGN ====
		'draw on same height than door startY
		If room.owner < 5 And room.owner >=0 then GetSpriteFromRegistry("gfx_building_sign_"+room.owner).Draw(xOffset + area.GetX() + 2 + doorSprite.framew, yOffset + GetBuilding().area.GetY() + TBuilding.GetFloorY(area.GetY()) - doorSprite.area.GetH())


		'==== DRAW OVERLAY ===

		if room.IsBlocked()
			'when a bomb is the reason - draw a barrier tape
			if room.blockedState = room.BLOCKEDSTATE_BOMB

				'is there is an explosion happening in that moment?
				'attention: not gametime but time (realtime effect)
				if room.bombExplosionTime + room.bombExplosionDuration > Time.GetTimeGone()
					local bombTimeGone:int = (Time.GetTimeGone() - room.bombExplosionTime)
					local scale:float = 1.0
					scale = TInterpolation.BackOut(0.0, 1.0, Min(room.bombExplosionDuration, bombTimeGone), room.bombExplosionDuration)
					scale :* TInterpolation.BounceOut(0.0, 1.0, Min(room.bombExplosionDuration, bombTimeGone), room.bombExplosionDuration)
					GetSpriteFromRegistry("gfx_building_explosion").Draw(xOffset + area.GetX() + area.GetW()/2, yOffset + GetBuilding().area.GetY() + TBuilding.GetFloorY(area.GetY()) - doorSprite.area.GetH()/2, -1, ALIGN_CENTER_CENTER, scale)
				else
					GetSpriteFromRegistry("gfx_building_blockeddoorsign").Draw(xOffset + area.GetX(), yOffset + GetBuilding().area.GetY() + TBuilding.GetFloorY(area.GetY()), -1, ALIGN_LEFT_BOTTOM)
				endif
			EndIf
		EndIf


		'==== DRAW DEBUG TEXT ====
		if Game.DebugInfos
			local textY:int = GetBuilding().area.GetY() + TBuilding.GetFloorY(area.GetY()) - 62
			if room.hasOccupant()
				for local figure:TFigure = eachin room.occupants
					GetBitmapFontManager().basefont.Draw(figure.name, xOffset + area.GetX(), yOffset + textY)
					textY:-10
				next
			else
				GetBitmapFontManager().basefont.Draw("empty", xOffset + area.GetX(), yOffset + textY)
			endif
		endif
	End Method


	Function DrawAll:Int()
		For Local door:TRoomDoor = EachIn list
			'skip invisible doors (without door-sprite)
			'Ronny TODO: maybe replace "invisible doors" with hotspots + room signes (if visible in elevator)
			If not door.IsVisible() then continue

			door.Render()
		Next
	End Function


	Method CreateRoomSign:int( slot:int=-1 )
		if slot = -1 then slot = doorSlot

		If doortype < 0 then return 0

		'area.getY() is the floor of the door
		sign = new TRoomDoorSign.Init(self, slot, area.getY())
		return true
	End Method


	Function Get:TRoomDoor(id:int)
		For Local door:TRoomDoor = EachIn list
			if door.id = id then return door
		Next
		return Null
	End Function


	Function GetByCoord:TRoomDoor( x:int, y:int )
		For Local door:TRoomDoor = EachIn list
			'also allow invisible rooms... so just check if hit the area
			'If room.doortype >= 0 and THelper.IsIn(x, y, room.Pos.x, Building.area.position.y + TBuilding.GetFloorY(room.pos.y) - room.doorDimension.Y, room.doorDimension.x, room.doorDimension.y)
			If THelper.IsIn(x, y, door.area.GetX(), GetBuilding().area.GetY() + TBuilding.GetFloorY(door.area.GetY()) - door.area.GetH(), door.area.GetW(), door.area.GetH())
				Return door
			EndIf
		Next
		Return Null
	End Function

	Function GetRandom:TRoomDoor()
		return TRoomDoor( list.ValueAtIndex( Rand(list.Count() - 1) ) )
	End Function


	'returns the first door connected to a room
	Function GetDoorsToRoom:TRoomDoor[]( room:TRoom )
		local res:TRoomDoor[]
		if not room then return res

		For Local door:TRoomDoor = EachIn list
			if door.room = room then res :+ [door]
		Next
		return res
	End Function


	Function GetMainDoorToRoom:TRoomDoor( room:TRoom )
		'Ronny TODO: add configuration "mainDoor"
		'            or remove whole function and replace with
		'            "nearestDoorToRoom"
		local doors:TRoomDoor[] = GetDoorsToRoom(room)
		If doors.length = 0 then return Null
		return doors[0]
	End Function


	Function GetByMapPos:TRoomDoor( doorSlot:Int, doorFloor:Int )
		if doorSlot >= 0 and doorFloor >= 0
			For Local door:TRoomDoor= EachIn list
				If door.area.GetY() = doorFloor And door.doorSlot = doorSlot Then Return door
			Next
		EndIf
		Return Null
	End Function


	Function GetByDetails:TRoomDoor( name:String, owner:Int, floor:int =-1 )
		For Local door:TRoomDoor = EachIn list
			'skip wrong floors
			if floor >=0 and door.area.GetY() <> floor then continue
			'skip wrong owners
			if door.room.owner <> owner then continue

			If door.room.name = name Then Return door
		Next
		Return Null
	End Function
End Type




Type TRoomHandler

	Function _RegisterHandler(updateFunc(triggerEvent:TEventBase), drawFunc(triggerEvent:TEventBase), room:TRoom = null)
		if room
			EventManager.registerListenerFunction( "room.onUpdate", updateFunc, room )
			EventManager.registerListenerFunction( "room.onDraw", drawFunc, room )
		endif
	End Function

	'special events for screens used in rooms - only this event has the room as sender
	'screen.onScreenUpdate/Draw is more general purpose
	Function _RegisterScreenHandler(updateFunc(triggerEvent:TEventBase), drawFunc(triggerEvent:TEventBase), screen:TScreen)
		if screen
			EventManager.registerListenerFunction( "room.onScreenUpdate", updateFunc, screen )
			EventManager.registerListenerFunction( "room.onScreenDraw", drawFunc, screen )
		endif
	End Function


	Function CheckPlayerInRoom:int(roomName:string)
		'check if we are in the correct room
		If GetPlayerCollection().Get().figure.isChangingRoom Then Return False
		If not GetPlayerCollection().Get().figure.inRoom Then Return False
		if GetPlayerCollection().Get().figure.inRoom.name <> roomName then return FALSE
		return TRUE
	End Function


'	Function Init() abstract
'	Function Update:int( triggerEvent:TEventBase ) abstract
'	Function Draw:int( triggerEvent:TEventBase ) abstract
End Type


'Office: handling the players room
Type RoomHandler_Office extends TRoomHandler
	'=== OFFICE ROOM ===
	global StationsToolTip:TTooltip
	global PlannerToolTip:TTooltip
	global SafeToolTip:TTooltip
	global currentSubRoom:TRoom = null
	global lastSubRoom:TRoom = null

	'=== STATIONMAP ===
	global stationList:TGUISelectList
	global stationMapMode:int				= 0	'1=searchBuy,2=buy,3=sell
	global stationMapActionConfirmed:int	= FALSE
	global stationMapSelectedStation:TStation
	global stationMapMouseoverStation:TStation
	global stationMapShowStations:TGUICheckBox[4]
	global stationMapBuyButton:TGUIButton
	global stationMapSellButton:TGUIButton

	'=== PROGRAMME PLANNER ===
	Global showPlannerShortCutHintTime:int = 0
	Global showPlannerShortCutHintFadeAmount:int = 1
	Global planningDay:int = -1
	Global talkToProgrammePlanner:int = TRUE		'set to FALSE for deleting gui objects without modifying the plan
	Global DrawnOnProgrammePlannerBG:int = 0
	Global ProgrammePlannerButtons:TGUIButton[6]
	Global PPprogrammeList:TgfxProgrammelist
	Global PPcontractList:TgfxContractlist
	Global fastNavigateTimer:TIntervalTimer = TIntervalTimer.Create(250)
	Global fastNavigateInitialTimer:int = 250
	Global fastNavigationUsedContinuously:int = FALSE

	Global hoveredGuiProgrammePlanElement:TGuiProgrammePlanElement = null
	Global draggedGuiProgrammePlanElement:TGuiProgrammePlanElement = null
	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListProgrammes:TGUIProgrammePlanSlotList
	Global GuiListAdvertisements:TGUIProgrammePlanSlotList

	'=== FINANCIAL SCREEN ===
	global financePreviousDayButton:TGUIArrowButton
	global financeNextDayButton:TGUIArrowButton
	global financeHistoryDownButton:TGUIArrowButton
	global financeHistoryUpButton:TGUIArrowButton
	Global financeHistoryStartPos:int = 0
	Global financeShowDay:int = 0
	Global clTypes:TColor[6]



	Function Init()
		'===== RUN SCREEN SPECIFIC INIT =====
		'(event connection etc.)
		InitStationMap()
		InitProgrammePlanner()
		InitFinancialScreen()

		'localize gui elements
		SetLanguage()

		'===== REGISTER SCREEN HANDLERS =====
		'no need for individual screens, all can be handled by one function (room is param)
		super._RegisterScreenHandler( onUpdateOffice, onDrawOffice, ScreenCollection.GetScreen("screen_office") )
		super._RegisterScreenHandler( onUpdateProgrammePlanner, onDrawProgrammePlanner, ScreenCollection.GetScreen("screen_office_pplanning") )
		super._RegisterScreenHandler( onUpdateFinancials, onDrawFinancials, ScreenCollection.GetScreen("screen_office_financials") )
		super._RegisterScreenHandler( onUpdateImage, onDrawImage, ScreenCollection.GetScreen("screen_office_image") )
		super._RegisterScreenHandler( onUpdateStationMap, onDrawStationMap, ScreenCollection.GetScreen("screen_office_stationmap") )

		'===== REGISTER EVENTS =====
		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)

		'inform if language changes
		EventManager.registerListenerFunction("Language.onSetLanguage", onSetLanguage)
	End Function


	Function onSetLanguage:int(triggerEvent:TEventBase)
		SetLanguage()
	End Function


	Function SetLanguage()
		'programmeplanner
		if ProgrammePlannerButtons[0]
			ProgrammePlannerButtons[0].SetCaption(GetLocale("PLANNER_ADS"))
			ProgrammePlannerButtons[1].SetCaption(GetLocale("PLANNER_PROGRAMME"))
			ProgrammePlannerButtons[2].SetCaption(GetLocale("PLANNER_OPTIONS"))
			ProgrammePlannerButtons[3].SetCaption(GetLocale("PLANNER_FINANCES"))
			ProgrammePlannerButtons[4].SetCaption(GetLocale("PLANNER_IMAGE"))
			ProgrammePlannerButtons[5].SetCaption(GetLocale("PLANNER_MESSAGES"))
		endif
		
		'stationmap
		if stationMapBuyButton
			stationMapBuyButton.SetCaption(GetLocale("BUY_STATION"))
			stationMapSellButton.SetCaption(GetLocale("SELL_STATION"))
		endif
	End Function


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new programmes are not loaded yet
		hoveredGuiProgrammePlanElement = null
		draggedGuiProgrammePlanElement = null

		RemoveAllGuiElements(TRUE)
	End Function


	Function InitProgrammePlanner()
		'add gfx to background image
		If Not DrawnOnProgrammePlannerBG then InitProgrammePlannerBackground()

		'===== CREATE GUI LISTS =====
		'the visual gap between 0-11 and 12-23 hour
		local gapBetweenHours:int = 57
		local area:TRectangle = new TRectangle.Init(67,17,600,12 * GetSpriteFromRegistry("pp_programmeblock1").area.GetH())

		GuiListProgrammes = new TGUIProgrammePlanSlotList.Create(area.position, area.dimension, "programmeplanner")
		GuiListProgrammes.Init("pp_programmeblock1", GetSpriteFromRegistry("pp_adblock1").area.GetW() + gapBetweenHours)
		GuiListProgrammes.isType = TBroadcastMaterial.TYPE_PROGRAMME

		GuiListAdvertisements = new TGUIProgrammePlanSlotList.Create(new TVec2D.Init(area.GetX() + GetSpriteFromRegistry("pp_programmeblock1").area.GetW(), area.GetY()), area.dimension, "programmeplanner")
		GuiListAdvertisements.Init("pp_adblock1", GetSpriteFromRegistry("pp_programmeblock1").area.GetW() + gapBetweenHours)
		GuiListAdvertisements.isType = TBroadcastMaterial.TYPE_ADVERTISEMENT

		'init lists
		PPprogrammeList	= new TgfxProgrammelist.Create(660, 16, 21)
		PPcontractList = new TgfxContractlist.Create(660, 16)

		'buttons
		ProgrammePlannerButtons[0] = new TGUIButton.Create(new TVec2D.Init(672, 40 + 0*56), null, GetLocale("PLANNER_ADS"), "programmeplanner_buttons")
		ProgrammePlannerButtons[0].spriteName = "programmeplanner_btn_ads"

		ProgrammePlannerButtons[1] = new TGUIButton.Create(new TVec2D.Init(672, 40 + 1*56), null, GetLocale("PLANNER_PROGRAMME"), "programmeplanner_buttons")
		ProgrammePlannerButtons[1].spriteName = "programmeplanner_btn_programme"

		ProgrammePlannerButtons[2] = new TGUIButton.Create(new TVec2D.Init(672, 40 + 2*56), null, GetLocale("PLANNER_OPTIONS"), "programmeplanner_buttons")
		ProgrammePlannerButtons[2].spriteName = "programmeplanner_btn_options"

		ProgrammePlannerButtons[3] = new TGUIButton.Create(new TVec2D.Init(672, 40 + 3*56), null, GetLocale("PLANNER_FINANCES"), "programmeplanner_buttons")
		ProgrammePlannerButtons[3].spriteName = "programmeplanner_btn_financials"

		ProgrammePlannerButtons[4] = new TGUIButton.Create(new TVec2D.Init(672, 40 + 4*56), null, GetLocale("PLANNER_IMAGE"), "programmeplanner_buttons")
		ProgrammePlannerButtons[4].spriteName = "programmeplanner_btn_image"

		ProgrammePlannerButtons[5] = new TGUIButton.Create(new TVec2D.Init(672, 40 + 5*56), null, GetLocale("PLANNER_MESSAGES"), "programmeplanner_buttons")
		ProgrammePlannerButtons[5].spriteName = "programmeplanner_btn_news"

		for local i:int = 0 to 5
			ProgrammePlannerButtons[i].SetAutoSizeMode(TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE)
			ProgrammePlannerButtons[i].caption.SetContentPosition(ALIGN_CENTER, ALIGN_TOP)
			ProgrammePlannerButtons[i].caption.SetFont( GetBitmapFont("Default", 10, BOLDFONT) )

			ProgrammePlannerButtons[i].SetCaptionOffset(0,42)
		Next
	'	TGUILabel.SetTypeFont( null )


		'===== REGISTER EVENTS =====

		'for all office rooms - register if someone goes into the programmeplanner
		local screen:TScreen = ScreenCollection.GetScreen("screen_office_pplanning")
		'player enters screen - reset the guilists
		if screen then EventManager.registerListenerFunction("screen.onEnter", onEnterProgrammePlannerScreen, screen)
		'player leaves screen - only without dragged blocks
		EventManager.registerListenerFunction("screen.OnLeave", onLeaveProgrammePlannerScreen, screen)

		'to react on changes in the programmePlan (eg. contract finished)
		EventManager.registerListenerFunction("programmeplan.addObject", onChangeProgrammePlan)
		EventManager.registerListenerFunction("programmeplan.removeObject", onChangeProgrammePlan)
		'also react on "group changes" like removing unneeded adspots
		EventManager.registerListenerFunction("programmeplan.removeObjectInstances", onChangeProgrammePlan)


		'begin drop - to intercept if dropping ad to programme which does not allow Ad-Show
		EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammePlanElement, "TGUIProgrammePlanElement")
		'drag/drop ... from or to one of the two lists
		EventManager.registerListenerFunction("guiList.removeItem", onRemoveItemFromSlotList, GuiListProgrammes)
		EventManager.registerListenerFunction("guiList.removeItem", onRemoveItemFromSlotList, GuiListAdvertisements)
		EventManager.registerListenerFunction("guiList.addItem", onAddItemToSlotList, GuiListProgrammes)
		EventManager.registerListenerFunction("guiList.addItem", onAddItemToSlotList, GuiListAdvertisements)
		'so we can forbid adding to a "past"-slot
		EventManager.registerListenerFunction("guiList.TryAddItem", onTryAddItemToSlotList, GuiListProgrammes)
		EventManager.registerListenerFunction("guiList.TryAddItem", onTryAddItemToSlotList, GuiListAdvertisements)
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction("guiGameObject.OnMouseOver", onMouseOverProgrammePlanElement, "TGUIProgrammePlanElement" )
		'these lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction("guiobject.onClick", onClickProgrammePlanElement, "TGUIProgrammePlanElement")
		'handle dragging of dayChangeProgrammePlanElements (eg. when dropping an item on them)
		'in this case - send them to GuiManager (like freshly created to avoid a history)
		EventManager.registerListenerFunction("guiobject.onDrag", onDragProgrammePlanElement, "TGUIProgrammePlanElement")
		'we want to handle drops on the same guilist slot (might be other planning day)
		EventManager.registerListenerFunction("guiobject.onDropBack", onDropProgrammePlanElementBack, "TGUIProgrammePlanElement")

		'intercept dragging items if we want a SHIFT/CTRL-copy/nextepisode
		EventManager.registerListenerFunction("guiobject.onTryDrag", onTryDragProgrammePlanElement, "TGUIProgrammePlanElement")
		'handle dropping at the end of the list (for dragging overlapped items)
		EventManager.registerListenerFunction("programmeplan.addObject", onProgrammePlanAddObject)

		'we want to colorize the list background depending on minute
		'EventManager.registerListenerFunction("Game.OnMinute",	onGameMinute)

		'we are interested in the programmeplanner buttons
		EventManager.registerListenerFunction("guiobject.onClick", onProgrammePlannerButtonClick, "TGUIButton" )
	End Function


	'===== OFFICE ROOM SCREEN ======


	Function onDrawOffice:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen( triggerEvent._sender )
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		if room.GetBackground() then room.GetBackground().draw(20,10)

		'allowed for owner only
		If room AND room.owner = GetPlayerCollection().playerID
			If StationsToolTip Then StationsToolTip.Render()
		EndIf

		'allowed for all - if having keys
		If PlannerToolTip <> Null Then PlannerToolTip.Render()

		If SafeToolTip <> Null Then SafeToolTip.Render()
	End Function


	Function onUpdateOffice:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		GetPlayerCollection().Get().figure.fromroom = Null
		If MOUSEMANAGER.IsClicked(1)
			If THelper.IsIn(MouseManager.x,MouseManager.y,25,40,150,295)
				GetPlayerCollection().Get().Figure.LeaveRoom()
				MOUSEMANAGER.resetKey(1)
			EndIf
		EndIf

		Game.cursorstate = 0
		'safe - reachable for all
		If THelper.IsIn(MouseManager.x, MouseManager.y, 165,85,70,100)
			If SafeToolTip = Null Then SafeToolTip = TTooltip.Create(GetLocale("ROOM_SAFE"), GetLocale("FOR_PRIVATE_AFFAIRS"), 140, 100,-1,-1)
			SafeToolTip.enabled = 1
			SafeToolTip.minContentWidth = 150
			SafeToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0

				ScreenCollection.GoToSubScreen("screen_office_safe")
			endif
		EndIf

		'planner - reachable for all
		If THelper.IsIn(MouseManager.x, MouseManager.y, 600,140,128,210)
			If PlannerToolTip = Null Then PlannerToolTip = TTooltip.Create(GetLocale("ROOM_PROGRAMMEPLANNER"), GetLocale("AND_STATISTICS"), 580, 140)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				ScreenCollection.GoToSubScreen("screen_office_pplanning")
			endif
		EndIf

		'station map - only reachable for owner
		If room.owner = GetPlayerCollection().playerID
			If THelper.IsIn(MouseManager.x, MouseManager.y, 732,45,160,170)
				If not StationsToolTip Then StationsToolTip = TTooltip.Create(GetLocale("ROOM_STATIONMAP"), GetLocale("BUY_AND_SELL"), 650, 80, 0, 0)
				StationsToolTip.enabled = 1
				StationsToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0
					ScreenCollection.GoToSubScreen("screen_office_stationmap")
				endif
			EndIf
			If StationsToolTip Then StationsToolTip.Update()
		EndIf

		If PlannerToolTip Then PlannerToolTip.Update()
		If SafeToolTip Then SafeToolTip.Update()
	End Function



	'===== OFFICE PROGRAMME PLANNER SCREEN =====

	'=== EVENTS ===

	'clear the guilist if a player enters
	'screens are only handled by real players
	Function onEnterProgrammePlannerScreen:int(triggerEvent:TEventBase)
		'==== EMPTY/DELETE GUI-ELEMENTS =====

		hoveredGuiProgrammePlanElement = null
		draggedGuiProgrammePlanElement = null

		'remove all entries
		RemoveAllGuiElements(true)
		RefreshGUIElements()
	End Function


	Function onLeaveProgrammePlannerScreen:int( triggerEvent:TEventBase )
		'do not allow leaving with a list open
		if PPprogrammeList.enabled Or PPcontractList.enabled
			PPprogrammeList.SetOpen(0)
			PPcontractList.SetOpen(0)
			triggerEvent.SetVeto()
			return FALSE
		endif

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammePlanElement
			triggerEvent.setVeto()
			return FALSE
		endif

		return TRUE
	End Function


	'sets slots of the lists used according to the current time
	Function onGameMinute:int(triggerEvent:TEventBase)
		Local minute:Int = triggerEvent.GetData().getInt("minute",-1)
		Local hour:Int = triggerEvent.GetData().getInt("hour",-1)
		'programme start
'		if minute = 5 then GuiListProgrammes.SetSlotState(hour, 2)
		'programme start
'		if minute = 55 then GuiListAdvertisements.SetSlotState(hour, 2)
		return TRUE
	End Function


	'if players are in the office during changes
	'to their programme plan, react to...
	Function onChangeProgrammePlan:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("office") then return FALSE

		'is it our plan?
		local plan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		if not plan then return FALSE
		if plan.owner <> GetPlayerCollection().playerID then return FALSE
'print "onChangeProgrammePlan: running RefreshGuiElements"
'		haveToRefreshGuiElements = TRUE
		RefreshGuiElements()
	End Function


	'handle dragging dayChange elements (give them to GuiManager)
	'this way the newly dragged item is kind of a "newly" created
	'item without history of a former slot etc.
	Function onDragProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		'check if we somehow dragged a dayChange element
		'if so : remove it from the list and let the GuiManager manage it
		if item = GuiListProgrammes.dayChangeGuiProgrammePlanElement
			GuiManager.AddDragged(GuiListProgrammes.dayChangeGuiProgrammePlanElement)
			GuiListProgrammes.dayChangeGuiProgrammePlanElement = null
			return TRUE
		endif
		if item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement
			GuiManager.AddDragged(GuiListAdvertisements.dayChangeGuiProgrammePlanElement)
			GuiListAdvertisements.dayChangeGuiProgrammePlanElement = null
			return TRUE
		endif
		return FALSE
	End Function


	Function onTryDragProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		if CreateNextEpisodeOrCopyByShortcut(item)
			triggerEvent.SetVeto()
			return FALSE
		endif

		'dragging is ok
		return TRUE
	End Function


	'handle adding items at the end of a day
	'so the removed material can be recreated as dragged gui items
	Function onProgrammePlanAddObject:int(triggerEvent:TEventBase)
		local removedObjects:object[] = object[](triggerEvent.GetData().get("removedObjects"))
		local addedObject:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().get("object"))
		if not removedObjects then return FALSE
		if not addedObject then return FALSE
		'also not interested if the programme ends before midnight
		if addedObject.programmedHour + addedObject.getBlocks() <= 24 then return FALSE

		'create new gui items for all removed ones
		'this also includes todays programmes:
		'ex: added 5block to 21:00 - removed programme from 23:00-24:00 gets added again too
		for local i:int = 0 to removedObjects.length-1
			local material:TBroadcastMaterial = TBroadcastMaterial(removedObjects[i])
			if material then new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(material, "programmePlanner").drag()
		Next
		return FALSE
	End Function


	'intercept if item does not allow dropping on specific lists
	'eg. certain ads as programme if they do not allow no commercial shows
	Function onTryDropProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetReceiver())
		if not list then return FALSE

		'check if that item is allowed to get dropped on such a list

		'up to now: all are allowed
		return TRUE
	End Function


	'remove the material from the programme plan
	Function onRemoveItemFromSlotList:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		local slot:int = triggerEvent.GetData().getInt("slot", -1)

		if not list or not item or slot = -1 then return FALSE

		'we removed the item but do not want the planner to know
		if not talkToProgrammePlanner then return TRUE

		if list = GuiListProgrammes
			if not GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
				print "[WARNING] dragged item from programmelist - removing from programmeplan at "+slot+":00 - FAILED"
			endif
		elseif list = GuiListAdvertisements
			if not GetPlayerCollection().Get().GetProgrammePlan().RemoveAdvertisement(item.broadcastMaterial)
				print "[WARNING] dragged item from adlist - removing from programmeplan at "+slot+":00 - FAILED"
			endif
		else
			print "[ERROR] dragged item from unknown list - removing from programmeplan at "+slot+":00 - FAILED"
		endif


		return TRUE
	End Function


	'handle if a programme is dropped on the same slot but different
	'planning day
	Function onDropProgrammePlanElementBack:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetReceiver())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())

		'is the gui item coming from another day?
		'remove it from there (was "silenced" during automatic mode)
		if List = GuiListProgrammes or list = GuiListAdvertisements
			if item.plannedOnDay >= 0 and item.plannedOnDay <> list.planDay
				if item.lastList = GuiListAdvertisements
					if not GetPlayerCollection().Get().GetProgrammePlan().RemoveAdvertisement(item.broadcastMaterial)
						print "[ERROR] dropped item from another day on active day - removal in other days adlist FAILED"
						return False
					Endif
				ElseIf item.lastList = GuiListProgrammes
					if not GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
						print "[ERROR] dropped item from another day on active day - removal in other days programmelist FAILED"
						return False
					Endif
				Endif
			Endif
		EndIf

	End Function

	'add the material to the programme plan
	'added shortcuts for faster placement here as this event
	'is emitted on successful placements (avoids multiple dragged blocks
	'while dropping not possible)
	Function onAddItemToSlotList:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		local slot:int = triggerEvent.GetData().getInt("slot", -1)
		if not list or not item or slot = -1 then return FALSE

		'we removed the item but do not want the planner to know
		if not talkToProgrammePlanner then return TRUE


		'is the gui item coming from another day?
		'remove it from there (was "silenced" during automatic mode)
		if List = GuiListProgrammes or list = GuiListAdvertisements
			if item.plannedOnDay >= 0 and item.plannedOnDay <> list.planDay
				if item.lastList = GuiListAdvertisements
					if not GetPlayerCollection().Get().GetProgrammePlan().RemoveAdvertisement(item.broadcastMaterial)
						print "[ERROR] dropped item from another day on active day - removal in other days adlist FAILED"
						return False
					Endif
				ElseIf item.lastList = GuiListProgrammes
					if not GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
						print "[ERROR] dropped item from another day on active day - removal in other days programmelist FAILED"
						return False
					Endif
				Endif
			Endif
		EndIf


		if list = GuiListProgrammes
			'is the gui item coming from another day?
			'remove it from there (was "silenced" during automatic mode)
			if item.plannedOnDay >= 0 and item.plannedOnDay <> list.planDay
				if not GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
					print "[ERROR] dropped item on programmelist - removal from other day FAILED"
					return False
				endif
			Endif

			if not GetPlayerCollection().Get().GetProgrammePlan().SetProgrammeSlot(item.broadcastMaterial, planningDay, slot)
				print "[WARNING] dropped item on programmelist - adding to programmeplan at "+slot+":00 - FAILED"
				return FALSE
			endif
			'set indicator on which day the item is planned
			'  (this saves some processing time - else we could request
			'   the day from the players ProgrammePlan)
			item.plannedOnDay = list.planDay
		elseif list = GuiListAdvertisements
			if not GetPlayerCollection().Get().GetProgrammePlan().SetAdvertisementSlot(item.broadcastMaterial, planningDay, slot)
				print "[WARNING] dropped item on adlist - adding to programmeplan at "+slot+":00 - FAILED"
				return FALSE
			endif
			'set indicator on which day the item is planned
			'  (this saves some processing time - else we could request
			'   the day from the players ProgrammePlan)
			item.plannedOnDay = list.planDay
		else
			print "[ERROR] dropped item on unknown list - adding to programmeplan at "+slot+":00 - FAILED"
			return FALSE
		endif

		'if a shortcut is pressed - create copy/next episode
		'CreateNextEpisodeOrCopyByShortcut(item)

		return TRUE
	End Function


	'checks if it is allowed to occupy the the targeted slot (eg. slot lies in the past)
	Function onTryAddItemToSlotList:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		local slot:int = triggerEvent.GetData().getInt("slot", -1)
		if not list or not item or slot = -1 then return FALSE

		'only check slot state if interacting with the programme planner
		if talkToProgrammePlanner
			'already running or in the past
			if list.GetSlotState(slot) = 2
				triggerEvent.SetVeto()
				return FALSE
			endif
		endif
		return TRUE
	End Function


	'right mouse button click: remove the block from the player's programmePlan
	'left mouse button click: check shortcuts and create a copy/nextepisode-block
	Function onClickProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement= TGUIProgrammePlanElement(triggerEvent._sender)
		if not item then print "onClickProgrammePlanElement got wrong sender";return false

		'left mouse button
		if triggerEvent.GetData().getInt("button",0) = 1
			'special handling for special items
			'-> remove dayChangeObjects from plan if dragging (and allowed)
			if not item.isDragged() and item.isDragable() and talkToProgrammePlanner
				if item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement
					if GetPlayerCollection().Get().GetProgrammePlan().RemoveAdvertisement(item.broadcastMaterial)
						GuiListAdvertisements.dayChangeGuiProgrammePlanElement = null
					endif
				elseif item = GuiListProgrammes.dayChangeGuiProgrammePlanElement
					if GetPlayerCollection().Get().GetProgrammePlan().RemoveProgramme(item.broadcastMaterial)
						GuiLisTProgrammes.dayChangeGuiProgrammePlanElement = null
					endif
				endif
			endif


			'if shortcut is used on a dragged item ... it gets executed
			'on a successful drop, no need to do it here before
			if item.isDragged() then return FALSE

			'assisting shortcuts create new guiobjects
			if CreateNextEpisodeOrCopyByShortcut(item)
				'do not try to drag the object - we did something special
				triggerEvent.SetVeto()
				return FALSE
			endif

			return TRUE
		endif

		'right mouse button - delete
		if triggerEvent.GetData().getInt("button",0) = 2
			'ignore wrong types and NON-dragged items
			if not item.isDragged() then return FALSE

			'remove if special
			if item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement then GuiListAdvertisements.dayChangeGuiProgrammePlanElement = null
			if item = GuiListProgrammes.dayChangeGuiProgrammePlanElement then GuiListProgrammes.dayChangeGuiProgrammePlanElement = null

			'will automatically rebuild at correct spot if needed
			item.remove()
			item = null

			'remove right click - to avoid leaving the room
			MouseManager.ResetKey(2)
		endif
	End Function


	Function onMouseOverProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		'only assign the first hovered item (to avoid having the lowest of a stack)
		if not hoveredGuiProgrammePlanElement
			hoveredGuiProgrammePlanElement = item
			TGUIProgrammePlanElement.hoveredElement = item

			if item.isDragged()
				draggedGuiProgrammePlanElement = item
				'if we have an item dragged... we cannot have a menu open
				PPprogrammeList.SetOpen(0)
				PPcontractList.SetOpen(0)
			endif
		endif

		return TRUE
	End Function


	Function onDrawProgrammePlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'time indicator
		If planningDay = GetWorldTime().getDay() Then SetColor 0,100,0
		If planningDay < GetWorldTime().getDay() Then SetColor 100,100,0
		If planningDay > GetWorldTime().getDay() Then SetColor 0,0,0
		GetBitmapFont("Default", 10).drawBlock(GetWorldTime().GetFormattedDay(1+ planningDay - GetWorldTime().getDay(GetWorldTime().GetTimeStart())), 691, 18, 100, 15)
		SetColor 255,255,255

		GUIManager.Draw("programmeplanner|programmeplanner_buttons")

		if hoveredGuiProgrammePlanElement
			'draw the current sheet
			hoveredGuiProgrammePlanElement.DrawSheet(30, 35, 700)
		endif


		'overlay old days
		If GetWorldTime().getDay() > planningDay
			SetColor 100,100,100
			SetAlpha 0.5
			DrawRect(27,17,637,360)
			SetColor 255,255,255
			SetAlpha 1.0
		EndIf

		SetColor 255,255,255
		If room.owner = GetPlayerCollection().playerID
			If PPprogrammeList.GetOpen() > 0 Then PPprogrammeList.Draw()
			If PPcontractList.GetOpen()  > 0 Then PPcontractList.Draw()
			'draw lists sheet
			If PPprogrammeList.GetOpen() and PPprogrammeList.hoveredLicence
				PPprogrammeList.hoveredLicence.ShowSheet(30,20)
			endif
			'If PPcontractList.GetOpen() and
			if PPcontractList.hoveredAdContract
				PPcontractList.hoveredAdContract.ShowSheet(30,20)
			endif
		EndIf

		if showPlannerShortCutHintTime > 0
			SetAlpha showPlannerShortCutHintTime/100.0
			DrawRect(23, 18, 640, 18)
			SetAlpha Min(1.0, 2.0*showPlannerShortCutHintTime/100.0)
			GetBitmapFont("Default", 11, BOLDFONT).drawBlock(GetLocale("HINT_PROGRAMMEPLANER_SHORTCUTS"), 23, 20, 640, 15, new TVec2D.Init(ALIGN_CENTER), TColor.Create(0,0,0),2,1,0.25)
			SetAlpha 1.0
		else
			SetAlpha 0.75
		endif
		DrawOval(-8,-8,55,55)
		GetBitmapFont("Default", 24, BOLDFONT).drawStyled("?", 22, 17, TColor.Create(50,50,150),2,1,0.5)
		SetAlpha 1.0
	End Function


	Function onUpdateProgrammePlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'if not initialized, do so
		if planningDay = -1 then planningDay = GetWorldTime().getDay()


		'if we have a licence dragged ... we should take care of "ESC"-Key
		if draggedGuiProgrammePlanElement
			if KeyManager.IsHit(KEY_ESCAPE)
				draggedGuiProgrammePlanElement.dropBackToOrigin()
				draggedGuiProgrammePlanElement = null
				hoveredGuiProgrammePlanElement = null
			endif
		endif

		Game.cursorstate = 0

		'set all slots occupied or not
		local day:int = GetWorldTime().getDay()
		local hour:int = GetWorldTime().GetDayHour()
		local minute:int = GetWorldTime().GetDayMinute()
		for local i:int = 0 to 23
			if not TPlayerProgrammePlan.IsUseableTimeSlot(TBroadcastMaterial.TYPE_PROGRAMME, planningDay, i, day, hour, minute)
				GuiListProgrammes.SetSlotState(i, 2)
			else
				GuiListProgrammes.SetSlotState(i, 0)
			endif
			if not TPlayerProgrammePlan.IsUseableTimeSlot(TBroadcastMaterial.TYPE_ADVERTISEMENT, planningDay, i, day, hour, minute)
				GuiListAdvertisements.SetSlotState(i, 2)
			else
				GuiListAdvertisements.SetSlotState(i, 0)
			endif
		Next

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then RefreshGUIElements()


		'reset hovered and dragged gui objects - gets repopulated automagically
		hoveredGuiProgrammePlanElement = null
		draggedGuiProgrammePlanElement = null
		TGUIProgrammePlanElement.hoveredElement = null

		If THelper.IsIn(MouseManager.x, MouseManager.y, 759,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				ChangePlanningDay(planningDay+1)
			endif
		EndIf
		If THelper.IsIn(MouseManager.x, MouseManager.y, 670,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0

				ChangePlanningDay(planningDay-1)
			endif
		EndIf
		'RON
		'fast movement is possible with keys
		'we use doAction as this allows a decreasing time
		'while keeping the original interval backupped
		if fastNavigateTimer.isExpired()
			if not KEYMANAGER.isDown(KEY_PAGEUP) and not KEYMANAGER.isDown(KEY_PAGEDOWN)
				fastNavigationUsedContinuously = FALSE
			endif
			if KEYMANAGER.isDown(KEY_PAGEUP)
				ChangePlanningDay(planningDay-1)
				fastNavigationUsedContinuously = TRUE
			endif
			if KEYMANAGER.isDown(KEY_PAGEDOWN)
				ChangePlanningDay(planningDay+1)
				fastNavigationUsedContinuously = TRUE
			endif

			'modify action time AND reset timer
			if fastNavigationUsedContinuously
				'decrease action time each time a bit more...
				fastNavigateTimer.setInterval( Max(50, fastNavigateTimer.GetInterval() * 0.9), true )
			else
				'set to initial value
				fastNavigateTimer.setInterval( fastNavigateInitialTimer, true )
			endif
		endif


		local listsOpened:int = (PPprogrammeList.enabled Or PPcontractList.enabled)
		'only handly programmeblocks if the lists are closed
		if not listsOpened
			GUIManager.Update("programmeplanner|programmeplanner_buttons")
		'if a list is opened, we cannot have a hovered gui element
		else
			hoveredGuiProgrammePlanElement = null
			'but still have to check for clicks on the buttons
			GUIManager.Update("programmeplanner_buttons")
		endif


		If room.owner = GetPlayerCollection().playerID
			PPprogrammeList.Update()
			PPcontractList.Update()
		EndIf

		'hide or show help
		If THelper.IsIn(MouseManager.x, MouseManager.y, 10,10,35,35)
			showPlannerShortCutHintTime = 90
			showPlannerShortCutHintFadeAmount = 1
		else
			showPlannerShortCutHintTime = Max(showPlannerShortCutHintTime-showPlannerShortCutHintFadeAmount, 0)
			showPlannerShortCutHintFadeAmount:+1
		endif
	End Function


	Function onProgrammePlannerButtonClick:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton( triggerEvent._sender )
		if not button then return 0

		'only react if the click came from the left mouse button
		if triggerEvent.GetData().getInt("button",0) <> 1 then return TRUE

		'Just close all lists and reopen the wanted one
		'->saves "if ProgrammePlannerButtons[o].clicked then closeAll, openMine ..."

		'close both lists
		PPcontractList.SetOpen(0)
		PPprogrammeList.SetOpen(0)

		'reset mousebutton
		MouseManager.ResetKey(1)

		'open others?
		If button = ProgrammePlannerButtons[0] Then return PPcontractList.SetOpen(1)		'opens contract list
		If button = ProgrammePlannerButtons[1] Then return PPprogrammeList.SetOpen(1)		'opens programme genre list

		'If button = ProgrammePlannerButtons[2] then return ScreenCollection.GoToSubScreen("screen_office_options")
		If button = ProgrammePlannerButtons[3] then return ScreenCollection.GoToSubScreen("screen_office_financials")
		If button = ProgrammePlannerButtons[4] then return ScreenCollection.GoToSubScreen("screen_office_image")
		'If button = ProgrammePlannerButtons[5] then return ScreenCollection.GoToSubScreen("screen_office_messages")
	End Function


	'=== COMMON FUNCTIONS / HELPERS ===


	Function CreateNextEpisodeOrCopyByShortcut:int(item:TGUIProgrammePlanElement)
		if not item then return FALSE
		'assisting shortcuts create new guiobjects
		'shift: next episode
		'ctrl : programme again
		if KEYMANAGER.IsDown(KEY_LSHIFT) OR KEYMANAGER.IsDown(KEY_RSHIFT)
			'reset key
			KEYMANAGER.ResetKey(KEY_LSHIFT)
			KEYMANAGER.ResetKey(KEY_RSHIFT)
			CreateNextEpisodeOrCopy(item, FALSE)
			return TRUE
		elseif KEYMANAGER.IsDown(KEY_LCONTROL) OR KEYMANAGER.IsDown(KEY_RCONTROL)
			KEYMANAGER.ResetKey(KEY_LCONTROL)
			KEYMANAGER.ResetKey(KEY_RCONTROL)
			CreateNextEpisodeOrCopy(item, TRUE)
			return TRUE
		endif
		'nothing clicked
		return FALSE
	End Function


	Function CreateNextEpisodeOrCopy:int(item:TGUIProgrammePlanElement, createCopy:int=TRUE)
		local newMaterial:TBroadcastMaterial = null

		'copy:         for ads and programmes create a new object based
		'              on licence or contract
		'next episode: for ads: create a copy
		'              for movies and series: rely on a licence-function
		'              which returns the next licence of a series/collection
		'              OR the first one if already on the latest spot

		select item.broadcastMaterial.materialType
			case TBroadcastMaterial.TYPE_ADVERTISEMENT
				newMaterial = new TAdvertisement.Create(TAdvertisement(item.broadcastMaterial).contract)

			case TBroadcastMaterial.TYPE_PROGRAMME
				if CreateCopy
					newMaterial = new TProgramme.Create(TProgramme(item.broadcastMaterial).licence)
				else
					local licence:TProgrammeLicence = TProgramme(item.broadcastMaterial).licence.GetNextSubLicence()
					'if no licence was given, the licence is for a normal movie...
					if not licence then licence = TProgramme(item.broadcastMaterial).licence
					newMaterial = new TProgramme.Create(licence)
				endif
		end select

		'create and drag
		if newMaterial then new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(newMaterial, "programmePlanner").drag()
	End Function


	Function ChangePlanningDay:int(day:int=0)
		planningDay = day
		'limit to start day
		If planningDay < GetWorldTime().getDay(GetWorldTime().GetTimeStart()) Then planningDay = GetWorldTime().getDay(GetWorldTime().GetTimeStart())

		'adjust slotlists (to hide ghosts on differing days)
		GuiListProgrammes.planDay = planningDay
		GuiListAdvertisements.planDay = planningDay

		'FALSE: without removing dragged
		'->ONLY keeps newly created, not ones dragged from a slot
		RemoveAllGuiElements(FALSE)
		RefreshGuiElements()
	end Function


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int(removeDragged:int=TRUE)
		'do not inform programmeplanner!
		local oldTalk:int =	talkToProgrammePlanner
		talkToProgrammePlanner = False

'		Rem
'			this is problematic as this could bug out the programmePlan
		'keep the dragged entries if wanted so
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListProgrammes._slots
			if not guiObject then continue
			if removeDragged or not guiObject.IsDragged()
				guiObject.remove()
				guiObject = null
			endif
		Next
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListAdvertisements._slots
			if not guiObject then continue
			if removeDragged or not guiObject.IsDragged()
				guiObject.remove()
				guiObject = null
			endif
		Next
'		End Rem

		'remove dragged ones of gui manager
		if removeDragged
			For local guiObject:TGuiProgrammePlanElement = eachin GuiManager.listDragged
				guiObject.remove()
				guiObject = null
			Next
		endif

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE

		'set to backupped value
		talkToProgrammePlanner = oldTalk
	End Function


	Function RefreshGuiElements:int()
		'do not inform programmeplanner!
		local oldTalk:int =	talkToProgrammePlanner
		talkToProgrammePlanner = False

		'===== REMOVE UNUSED =====
		 
		'remove overnight
		if GuiListProgrammes.daychangeGuiProgrammePlanElement
			GuiListProgrammes.daychangeGuiProgrammePlanElement.remove()
			GuiListProgrammes.daychangeGuiProgrammePlanElement = null
		endif
		if GuiListAdvertisements.daychangeGuiProgrammePlanElement
			GuiListAdvertisements.daychangeGuiProgrammePlanElement.remove()
			GuiListAdvertisements.daychangeGuiProgrammePlanElement = null
		endif

		local currDay:int = planningDay
		if currDay = -1 then currDay = GetWorldTime().getDay()

		
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListProgrammes._slots
			if guiObject.isDragged() then continue
			'check if programmed on the current day
			if guiObject.broadcastMaterial.isProgrammedForDay(currDay) then continue
			'print "GuiListProgramme has obsolete programme: "+guiObject.broadcastMaterial.GetTitle()
			guiObject.remove()
			guiObject = null
		Next
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListAdvertisements._slots
			if guiObject.isDragged() then continue
			'check if programmed on the current day
			if guiObject.broadcastMaterial.isProgrammedForDay(currDay) then continue
			'print "GuiListAdvertisement has obsolete ad: "+guiObject.broadcastMaterial.GetTitle()
			guiObject.remove()
			guiObject = null
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all programmes/ads
		local daysProgramme:TBroadcastMaterial[] = GetPlayerCollection().Get().GetProgrammePlan().GetProgrammesInTimeSpan(planningDay, 0, planningDay, 23)
		For local obj:TBroadcastMaterial = eachin daysProgramme
			if not obj then continue
			'if already included - skip it
			if GuiListProgrammes.ContainsBroadcastMaterial(obj) then continue
			
			'DAYCHANGE
			'skip programmes started yesterday (they are stored individually)
			if obj.programmedDay < planningDay and planningDay > 0
				'set to the obj still running at the begin of the planning day
				GuiListProgrammes.SetDayChangeBroadcastMaterial(obj, planningDay)
				continue
			endif

			'DRAGGED
			'check if we find it in the GuiManagers list of dragged items
			local foundInDragged:int = FALSE
			for local draggedGuiProgrammePlanElement:TGUIProgrammePlanElement = eachin GuiManager.ListDragged
				if draggedGuiProgrammePlanElement.broadcastMaterial = obj
					foundInDragged = TRUE
					continue
				endif
			Next
			if foundInDragged then continue

			'NORMAL MISSING
			if GuiListProgrammes.getFreeSlot() < 0
				print "[ERROR] ProgrammePlanner: should add programme but no empty slot left"
				continue
			endif

			local block:TGUIProgrammePlanElement = new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(obj)
			'print "ADD GuiListProgramme - missed new programme: "+obj.GetTitle() +" -> created block:"+block._id

			if not GuiListProgrammes.addItem(block, string(obj.programmedHour))
				print "ADD ERROR - could not add programme"
			else
				'set value so a dropped block will get the correct ghost image
				block.lastListType = GuiListProgrammes.isType
			endif
		Next


		'ad list (can contain ads, programmes, ...)
		local daysAdvertisements:TBroadcastMaterial[] = GetPlayerCollection().Get().GetProgrammePlan().GetAdvertisementsInTimeSpan(planningDay, 0, planningDay, 23)
		For local obj:TBroadcastMaterial = eachin daysAdvertisements
			if not obj then continue

			'if already included - skip it
			if GuiListAdvertisements.ContainsBroadcastMaterial(obj) then continue

			'DAYCHANGE
			'skip programmes started yesterday (they are stored individually)
			if obj.programmedDay < planningDay and planningDay > 0
				'set to the obj still running at the begin of the planning day
				GuiListProgrammes.SetDayChangeBroadcastMaterial(obj, planningDay)
				continue
			endif

			'DRAGGED
			'check if we find it in the GuiManagers list of dragged items
			local foundInDragged:int = FALSE
			for local draggedGuiProgrammePlanElement:TGUIProgrammePlanElement = eachin GuiManager.ListDragged
				if draggedGuiProgrammePlanElement.broadcastMaterial = obj
					foundInDragged = TRUE
					continue
				endif
			Next
			if foundInDragged then continue

			'NORMAL MISSING
			if GuiListAdvertisements.getFreeSlot() < 0
				print "[ERROR] ProgrammePlanner: should add advertisement but no empty slot left"
				continue
			endif

			local block:TGUIProgrammePlanElement = new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(obj, "programmePlanner")
			'print "ADD GuiListAdvertisements - missed new advertisement: "+obj.GetTitle()

			if not GuiListAdvertisements.addItem(block, string(obj.programmedHour))
				print "ADD ERROR - could not add advertisement"
			endif
		Next


		haveToRefreshGuiElements = FALSE

		'set to backupped value
		talkToProgrammePlanner = oldTalk
	End Function


	'add gfx to background
	Function InitProgrammePlannerBackground:int()
		Local roomImg:TImage				= GetSpriteFromRegistry("screen_bg_pplanning").parent.image
		Local Pix:TPixmap					= LockImage(roomImg)
		Local gfx_ProgrammeBlock1:TImage	= GetSpriteFromRegistry("pp_programmeblock1").GetImage()
		Local gfx_AdBlock1:TImage			= GetSpriteFromRegistry("pp_adblock1").GetImage()

		'block"shade" on bg
		local shadeColor:TColor = TColor.CreateGrey(200, 0.3)
		For Local j:Int = 0 To 11
			DrawImageOnImage(gfx_Programmeblock1, Pix, 67 - 20, 17 - 10 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Programmeblock1, Pix, 394 - 20, 17 - 10 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Adblock1, Pix, 67 + ImageWidth(gfx_Programmeblock1) - 20, 17 - 10 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Adblock1, Pix, 394 + ImageWidth(gfx_Programmeblock1) - 20, 17 - 10 + j * 30, shadeColor)
		Next


		'set target for font
		TBitmapFont.setRenderTarget(roomImg)

		local fontColor:TColor = TColor.CreateGrey(240)

		For Local i:Int = 0 To 11
			'left side
			GetBitmapFontManager().baseFont.drawStyled( (i + 12) + ":00", 338, 18 + i * 30, fontColor, 2,1,0.25)
			'right side
			local text:string = i + ":00"
			If i < 10 then text = "0" + text
			GetBitmapFontManager().baseFont.drawStyled(text, 10, 18 + i * 30, fontColor,2,1,0.25)
		Next
		DrawnOnProgrammePlannerBG = True

		'reset target for font
		TBitmapFont.setRenderTarget(null)
	End Function


	Function InitFinancialScreen:int()
		clTypes[TPlayerFinanceHistoryEntry.GROUP_NEWS] = new TColor.Create(0, 31, 83)
		clTypes[TPlayerFinanceHistoryEntry.GROUP_PROGRAMME] = new TColor.Create(89, 40, 0)
		clTypes[TPlayerFinanceHistoryEntry.GROUP_DEFAULT] = new TColor.Create(30, 30, 30)
		clTypes[TPlayerFinanceHistoryEntry.GROUP_PRODUCTION] = new TColor.Create(44, 0, 78)
		clTypes[TPlayerFinanceHistoryEntry.GROUP_STATION] = new TColor.Create(0, 75, 69)

		financeHistoryUpButton = new TGUIArrowButton.Create(new TVec2D.Init(500 + 20, 180), new TVec2D.Init(120, 15), "DOWN", "officeFinancialScreen")
		financeHistoryDownButton = new TGUIArrowButton.Create(new TVec2D.Init(500 + 120 + 20, 180), new TVec2D.Init(120, 15), "UP", "officeFinancialScreen")

		financePreviousDayButton = new TGUIArrowButton.Create(new TVec2D.Init(20 + 20, 10 + 10), new TVec2D.Init(26, 26), "LEFT", "officeFinancialScreen")
		financeNextDayButton = new TGUIArrowButton.Create(new TVec2D.Init(20 + 175 + 20, 10 + 10), new TVec2D.Init(26, 26), "RIGHT", "officeFinancialScreen")

		'listen to clicks on the four buttons
		EventManager.registerListenerFunction("guiobject.onClick", onClickFinanceButtons, "TGUIArrowButton")

		'reset finance history scroll position when entering a screen
		local screen:TScreen = ScreenCollection.GetScreen("screen_office_financials")
		if screen then EventManager.registerListenerFunction("screen.onEnter", onEnterFinancialScreen, screen)
	End Function


	'===== OFFICE FINANCIALS SCREEN =====

	'=== EVENTS ===

	'reset finance history scrolling position when entering the screen
	'reset finance show day to current when entering the screen
	Function onEnterFinancialScreen:int( triggerEvent:TEventBase )
		financeHistoryStartPos = 0
		financeShowDay = GetWorldTime().getDay()
	End function


	Function onDrawFinancials:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'limit finance day between 0 and current day
		financeShowDay = Max(0, Min(financeShowDay, GetWorldTime().getDay()))


		local screenOffsetX:int = 20
		local screenOffsetY:int = 10

		local finance:TPlayerFinance= GetPlayerCollection().Get(room.owner).GetFinance(financeShowDay)

		local captionColor:TColor = new TColor.CreateGrey(70)
		local captionFont:TBitmapFont = GetBitmapFont("Default", 13, BOLDFONT)
		local captionHeight:int = 20 'to center it to table header according "font Baseline"
		local textFont:TBitmapFont = GetBitmapFont("Default", 13)
		local logFont:TBitmapFont = GetBitmapFont("Default", 11)
		local textSmallFont:TBitmapFont = GetBitmapFont("Default", 10)
		local textBoldFont:TBitmapFont = GetBitmapFont("Default", 13, BOLDFONT)

		local clLog:TColor = new TColor.CreateGrey(50)

		local clNormal:TColor = TColor.clBlack
		local clPositive:TColor = new TColor.Create(90, 110, 90)
		local clNegative:TColor = new TColor.Create(110, 90, 90)


		'=== DAY CHANGER ===
		local today:int = GetWorldTime().MakeTime(0, financeShowDay, 0, 0)
		local todayText:string = GetWorldTime().GetDayOfYear(today)+"/"+GetWorldTime().GetDaysPerYear()+" "+GetWorldTime().getYear(today)
		textFont.DrawBlock(GetLocale("GAMEDAY")+" "+todayText, 50 + screenOffsetX, 15 +  screenOffsetY, 140, 20, ALIGN_CENTER_CENTER, TColor.CreateGrey(90), 2, 1, 0.2)



		'=== NEWS LOG ===
		captionFont.DrawBlock(GetLocale("FINANCES_LAST_FINANCIAL_ACTIVITIES"), 500 + screenOffsetX, 13 + screenOffsetY,  240, captionHeight, ALIGN_CENTER_CENTER, captionColor, 1,,0.5)
		local list:TList = GetPlayerFinanceHistoryListCollection().Get(room.owner)
		local logSlot:int = 0
		local logH:int = 19
		local history:TPlayerFinanceHistoryEntry
		local logCol:string = ""

		'limit log
		financeHistoryStartPos = Max(0, Min(list.Count()-1 - 6, financeHistoryStartPos))

		For local i:int = financeHistoryStartPos to Min(financeHistoryStartPos + 6, list.Count()-1)
			history = TPlayerFinancehistoryEntry(list.ValueAtIndex(i))
			if not history then continue

			GetSpriteFromRegistry("screen_financial_newsLog"+history.GetTypeGroup()).DrawArea(501 + screenOffsetX, 39 + screenOffsetY + logSlot*logH , 238, logH)
			if history.GetMoney() < 0
				logCol = "color=190,30,30"
			else
				logCol = "color=35,130,30"
			Endif
			logFont.DrawBlock("|"+logCol+"|"+TFunctions.convertValue(abs(history.GetMoney()),, -2, ".")+" "+getLocale("CURRENCY")+"|/color| "+history.GetDescription(), 501 + screenOffsetX + 5, 41 + screenOffsetY + logSlot*logH, 238 - 2*5, logH, ALIGN_LEFT_CENTER, clLog)
			logSlot:+1
		Next



		'=== BALANCE TABLE ===

		local labelX:int = 20 + screenOffsetX
		local labelStartY:int = 39 + screenOffsetY
		local labelH:int = 19, labelW:int = 220

		local valueIncomeX:int = 240 + screenOffsetX
		local valueExpenseX:int = 360 + screenOffsetX
		local valueStartY:int = 39 + screenOffsetY
		local valueH:int = 19, valueW:int = 95

		'draw balance table
		captionFont.DrawBlock(GetLocale("FINANCES_INCOME"), 240 + screenOffsetX, 13 + screenOffsetY,  104, captionHeight, ALIGN_CENTER_CENTER, captionColor, 1,,0.5)
		captionFont.DrawBlock(GetLocale("FINANCES_EXPENSES"), 352 + screenOffsetX, 13 + screenOffsetY,  104, captionHeight, ALIGN_CENTER_CENTER, captionColor, 1,,0.5)

		'draw total-area
		local profit:int = finance.revenue_after - finance.revenue_before
		if profit >= 0
			GetSpriteFromRegistry("screen_financial_positiveBalance").DrawArea(250 + screenOffsetX, 332 + screenOffsetY, 200, 25)
		else
			GetSpriteFromRegistry("screen_financial_negativeBalance").DrawArea(250 + screenOffsetX, 332 + screenOffsetY, 200, 25)
		endif
		captionFont.DrawBlock(TFunctions.convertValue(profit,,-2,"."), 250 + screenOffsetX, 332 + screenOffsetY, 200, 25, ALIGN_CENTER_CENTER, TColor.clWhite, 2, 1, 0.75)

		'draw label backgrounds
		local labelBGX:int = 20 + screenOffsetX
		local labelBGW:int = 220
		local valueBGX:int = 20 + labelBGW + 1 + screenOffsetX
		local labelBGs:TSprite[6]
		for local i:int = 1 to 5
			labelBGs[i] = GetSpriteFromRegistry("screen_financial_balanceLabel"+i)
		Next

		labelBGs[TPlayerFinanceHistoryEntry.GROUP_PROGRAMME].DrawArea(labelBGX, labelStartY + 0*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_PROGRAMME].DrawArea(labelBGX, labelStartY + 1*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_PROGRAMME].DrawArea(labelBGX, labelStartY + 2*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_PROGRAMME].DrawArea(labelBGX, labelStartY + 3*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_NEWS].DrawArea(labelBGX, labelStartY + 4*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_NEWS].DrawArea(labelBGX, labelStartY + 5*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_STATION].DrawArea(labelBGX, labelStartY + 6*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_PRODUCTION].DrawArea(labelBGX, labelStartY + 7*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_PRODUCTION].DrawArea(labelBGX, labelStartY + 8*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_PRODUCTION].DrawArea(labelBGX, labelStartY + 9*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_DEFAULT].DrawArea(labelBGX, labelStartY + 10*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_DEFAULT].DrawArea(labelBGX, labelStartY + 11*valueH, labelBGW, labelH)
		labelBGs[TPlayerFinanceHistoryEntry.GROUP_DEFAULT].DrawArea(labelBGX, labelStartY + 12*valueH, labelBGW, labelH)

		labelBGs[TPlayerFinanceHistoryEntry.GROUP_DEFAULT].DrawArea(labelBGX, labelStartY + 14*valueH +5, labelBGW, labelH)

		'draw value backgrounds
		local balanceValueBG:TSprite = GetSpriteFromRegistry("screen_financial_balanceValue")
		for local i:int = 0 to 12
			balanceValueBG.DrawArea(valueBGX, labelStartY + i*valueH, balanceValueBG.GetWidth(), labelH)
		Next
		balanceValueBG.DrawArea(valueBGX, labelStartY + 14*valueH + 5, balanceValueBG.GetWidth(), labelH)

		'draw balance labels
		textFont.DrawBlock(GetLocale("FINANCES_TRADING_PROGRAMMELICENCES"), labelX, labelStartY + 0*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_PROGRAMME])
		textFont.DrawBlock(GetLocale("FINANCES_AD_INCOME__CONTRACT_PENALTY"), labelX, labelStartY + 1*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_PROGRAMME])
		textFont.DrawBlock(GetLocale("FINANCES_CALL_IN_SHOW_INCOME"), labelX, labelStartY + 2*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_PROGRAMME])
		textFont.DrawBlock(GetLocale("FINANCES_SPONSORSHIP_INCOME__PENALTY"), labelX, labelStartY + 3*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_PROGRAMME])
		textFont.DrawBlock(GetLocale("FINANCES_NEWS"), labelX, labelStartY + 4*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_NEWS])
		textFont.DrawBlock(GetLocale("FINANCES_NEWSAGENCIES"), labelX, labelStartY + 5*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_NEWS])
		textFont.DrawBlock(GetLocale("FINANCES_STATIONS"), labelX, labelStartY + 6*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_STATION])
		textFont.DrawBlock(GetLocale("FINANCES_SCRIPTS"), labelX, labelStartY + 7*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_PRODUCTION])
		textFont.DrawBlock(GetLocale("FINANCES_ACTORS_AND_PRODUCTIONSTUFF"), labelX, labelStartY + 8*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_PRODUCTION])
		textFont.DrawBlock(GetLocale("FINANCES_STUDIO_RENT"), labelX, labelStartY + 9*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_PRODUCTION])
		textFont.DrawBlock(GetLocale("FINANCES_INTEREST_BALANCE__CREDIT"), labelX, labelStartY + 10*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_DEFAULT])
		textFont.DrawBlock(GetLocale("FINANCES_CREDIT_TAKEN__REPAYED"), labelX, labelStartY + 11*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_DEFAULT])
		textFont.DrawBlock(GetLocale("FINANCES_MISC"), labelX, labelStartY + 12*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_DEFAULT])
		'spacer for total
		textBoldFont.DrawBlock(GetLocale("FINANCES_TOTAL"), labelX, labelStartY + 14*valueH+5, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_DEFAULT])


		'draw "grouped"-info-sign
		GetSpriteFromRegistry("screen_financial_balanceInfo").Draw(valueBGX, labelStartY + 1 + 6*valueH)

		'draw balance values: income
		textBoldFont.drawBlock(TFunctions.convertValue(finance.income_programmeLicences,,-2,"."), valueIncomeX, valueStartY + 0*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.income_ads,,-2,"."), valueIncomeX, valueStartY + 1*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.income_callerRevenue,,-2,"."), valueIncomeX, valueStartY + 2*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.income_sponsorshipRevenue,,-2,"."), valueIncomeX, valueStartY + 3*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)
		'news: generate no income
		'newsagencies: generate no income
		textBoldFont.drawBlock(TFunctions.convertValue(finance.income_stations,,-2,"."), valueIncomeX, valueStartY + 6*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)
		'scripts: generate no income
		'actors and productionstuff: generate no income
		'studios: generate no income
		textBoldFont.drawBlock(TFunctions.convertValue(finance.income_balanceInterest,,-2,"."), valueIncomeX, valueStartY + 10*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.income_creditTaken,,-2,"."), valueIncomeX, valueStartY + 11*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.income_misc,,-2,"."), valueIncomeX, valueStartY + 12*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)
		'spacer for total
		textBoldFont.drawBlock(TFunctions.convertValue(finance.income_total,,-2,"."), valueIncomeX, valueStartY + 14*valueH +5, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)


		'draw balance values: expenses
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_programmeLicences,,-2,"."), valueExpenseX, valueStartY + 0*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_penalty,,-2,"."), valueExpenseX, valueStartY + 1*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		'no callin expenses ?
		'no expenses for sponsorships ?
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_news,,-2,"."), valueExpenseX, valueStartY + 4*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_newsAgencies,,-2,"."), valueExpenseX, valueStartY + 5*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_stationFees + finance.expense_stations,,-2,"."), valueExpenseX, valueStartY + 6*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_scripts,,-2,"."), valueExpenseX, valueStartY + 7*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_productionStuff,,-2,"."), valueExpenseX, valueStartY + 8*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_rent,,-2,"."), valueExpenseX, valueStartY + 9*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_drawingCreditInterest,,-2,"."), valueExpenseX, valueStartY + 10*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_creditRepayed,,-2,"."), valueExpenseX, valueStartY + 11*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_creditInterest,,-2,"."), valueExpenseX, valueStartY + 12*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		'spacer for total
		textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_total,,-2,"."), valueExpenseX, valueStartY + 14*valueH +5, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)



		'=== DRAW GROUP HOVERS ===
		local balanceEntryW:int = labelBGX + labelBGW - labelX + labelW
		'"station group"
		if THelper.MouseIn(labelX, labelStartY + 6*valueH, balanceEntryW, labelH)
			local bgcol:TColor = new TColor.Get()

			SetAlpha bgcol.a * 0.5
			SetColor 200,200,200
			TFunctions.DrawOutlineRect(labelX, labelStartY + 6*valueH, balanceEntryW +2, 2*labelH +2)
			SetAlpha bgcol.a * 0.75
			SetColor 100,100,100
			TFunctions.DrawOutlineRect(labelX-1, labelStartY + 6*valueH -1, balanceEntryW + 1, 2*labelH +1)
			bgcol.SetRGBA()
			labelBGs[TPlayerFinanceHistoryEntry.GROUP_STATION].DrawArea(labelBGX, labelStartY + 6*valueH, labelBGW, labelH)
			labelBGs[TPlayerFinanceHistoryEntry.GROUP_STATION].DrawArea(labelBGX, labelStartY + 7*valueH, labelBGW, labelH)

			balanceValueBG.DrawArea(valueBGX, labelStartY + 6*valueH, balanceValueBG.GetWidth(), labelH)
			balanceValueBG.DrawArea(valueBGX, labelStartY + 7*valueH, balanceValueBG.GetWidth(), labelH)

			textFont.DrawBlock(GetLocale("FINANCES_STATIONS_FEES"), labelX, labelStartY + 6*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_STATION])
			textFont.DrawBlock(GetLocale("FINANCES_STATIONS_BUY_SELL"), labelX, labelStartY + 7*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TPlayerFinanceHistoryEntry.GROUP_STATION])

			textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_stationFees,,-2,"."), valueExpenseX, valueStartY + 6*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)

			textBoldFont.drawBlock(TFunctions.convertValue(finance.income_stations,,-2,"."), valueIncomeX, valueStartY + 7*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, clPositive)
			textBoldFont.drawBlock(TFunctions.convertValue(finance.expense_stations,,-2,"."), valueExpenseX, valueStartY + 7*valueH, valueW, valueH, ALIGN_LEFT_CENTER, clNegative)
		endif


		'==== DRAW MONEY CURVE====
		captionFont.DrawBlock(GetLocale("FINANCES_FINANCIAL_CURVES"), 500 + screenOffsetX, 207 + screenOffsetY,  240, captionHeight, ALIGN_CENTER_CENTER, captionColor, 1,,0.5)

		'how much days to draw
		local showDays:int = 10
		'where to draw + dimension
		local curveArea:TRectangle = new TRectangle.Init(509 + screenOffsetX,239 + screenOffsetY, 220, 70)
		'heighest reached money value of that days
		Local maxValue:int = 0
		'minimum money (may be negative)
		Local minValue:int = 0
		'color of labels
		Local labelColor:TColor = new TColor.CreateGrey(80)

		'first get the maximum value so we know how to scale the rest
		For local i:Int = GetWorldTime().getDay()-showDays To GetWorldTime().getDay()
			'skip if day is less than startday (saves calculations)
			if i < GetWorldTime().GetStartDay() then continue

			For Local player:TPlayer = EachIn GetPlayerCollection().players
				maxValue = max(maxValue, player.GetFinance(i).money)
				minValue = min(minValue, player.GetFinance(i).money)
			Next
		Next


		local slot:int				= 0
		local slotPos:TVec2D		= new TVec2D.Init(0,0)
		local previousSlotPos:TVec2D= new TVec2D.Init(0,0)
		local slotWidth:int 		= curveArea.GetW() / showDays

		local yPerMoney:Float = curveArea.GetH() / Float(Abs(minValue) + maxValue)
		'zero is at "bottom - minMoney*yPerMoney"
		local yOfZero:Float = curveArea.GetH() - yPerMoney * Abs(minValue)

		local hoveredDay:int = -1
		For local i:Int = GetWorldTime().getDay()-showDays To GetWorldTime().getDay()
			if THelper.MouseIn(curveArea.GetX() + (slot-0.5) * slotWidth, curveArea.GetY(), slotWidth, curveArea.GetH())
				hoveredDay = i
				'leave for loop
				exit
			EndIf
			slot :+ 1
		Next
		if hoveredDay >= 0
			local time:int = GetWorldTime().MakeTime(0, hoveredDay, 0, 0)
			local gameDay:string = GetWorldTime().GetDayOfYear(time)+"/"+GetWorldTime().GetDaysPerYear()+" "+GetWorldTime().getYear(time)
			if GetPlayerCollection().Get(room.owner).GetFinance(hoveredDay).money > 0
				textSmallFont.Draw(GetLocale("GAMEDAY")+" "+gameDay+": |color=50,110,50|"+TFunctions.convertValue(GetPlayerCollection().Get(room.owner).GetFinance(hoveredDay).money,,-2,".")+"|/color|", curveArea.GetX(), curveArea.GetY() + curveArea.GetH() + 2, TColor.CreateGrey(50))
			Else
				textSmallFont.Draw(GetLocale("GAMEDAY")+" "+gameDay+": |color=110,50,50|"+TFunctions.convertValue(GetPlayerCollection().Get(room.owner).GetFinance(hoveredDay).money,,-2,".")+"|/color|", curveArea.GetX(), curveArea.GetY() + curveArea.GetH() + 2, TColor.CreateGrey(50))
			Endif

			local hoverX:int = curveArea.GetX() + (slot-0.5) * slotWidth
			local hoverW:int = Min(curveArea.GetX() + curveArea.GetW() - hoverX, slotWidth)
			if hoverX < curveArea.GetX() then hoverW = slotWidth / 2
			hoverX = Max(curveArea.GetX(), hoverX)

			local col:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha 0.1 * col.a
			DrawRect(hoverX, curveArea.GetY(), hoverW, curveArea.GetH())
			SetBlend AlphaBlend
			col.SetRGBA()
		EndIf

		'draw the curves
		SetLineWidth(2)
		GlEnable(GL_LINE_SMOOTH)
		slot = 0
		For Local player:TPlayer = EachIn GetPlayerCollection().players
			slot = 0
			slotPos.SetXY(0,0)
			previousSlotPos.SetXY(0,0)
			For local i:Int = GetWorldTime().getDay()-showDays To GetWorldTime().getDay()
				previousSlotPos.SetXY(slotPos.x, slotPos.y)
				slotPos.SetXY(slot * slotWidth, 0)
				'maximum is at 90% (so it is nicely visible)
'				if maxValue > 0 then slotPos.SetY(curveArea.GetH() - Floor((player.GetFinance(i).money / float(maxvalue)) * curveArea.GetH()))

				slotPos.SetY(yOfZero - player.GetFinance(i).money * yPerMoney)
				player.color.setRGB()
				SetAlpha 0.3
				DrawOval(curveArea.GetX() + slotPos.GetX()-3, curveArea.GetY() + slotPos.GetY()-3,6,6)
				SetAlpha 1.0
				if slot > 0
					DrawLine(curveArea.GetX() + previousSlotPos.GetX(), curveArea.GetY() + previousSlotPos.GetY(), curveArea.GetX() + slotPos.GetX(), curveArea.GetY() + slotPos.GetY())
					SetColor 255,255,255
				endif
				slot :+ 1
			Next
		Next
		SetLineWidth(1)

		'coord descriptor
		textSmallFont.drawBlock(TFunctions.convertValue(maxvalue,2,0), curveArea.GetX(), curveArea.GetY(), curveArea.GetW(), 20, new TVec2D.Init(ALIGN_RIGHT), labelColor)
		textSmallFont.drawBlock(TFunctions.convertValue(minvalue,2,0), curveArea.GetX(), curveArea.GetY() + curveArea.GetH()-20, curveArea.GetW(), 20, new TVec2D.Init(ALIGN_RIGHT, ALIGN_BOTTOM), labelColor)


		GuiManager.Draw("officeFinancialScreen")
	End Function


	Function onUpdateFinancials:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'disable "up" or "down" button of finance history
		if financeHistoryStartPos = 0
			financeHistoryDownButton.Disable()
		else
			financeHistoryDownButton.Enable()
		endif

		local maxVisible:int = 6
		local notVisible:int = GetPlayerFinanceHistoryListCollection().Get(room.owner).Count() - financeHistoryStartPos - maxVisible
		if notVisible <= 0
			financeHistoryUpButton.Disable()
		else
			financeHistoryUpButton.Enable()
		endif


		'disable "previou" or "newxt" button of finance display
		if financeShowDay = 0 or financeShowDay = GetWorldTime().GetStartDay()
			financePreviousDayButton.Disable()
		else
			financePreviousDayButton.Enable()
		endif

		if financeShowDay = GetWorldTime().getDay()
			financeNextDayButton.Disable()
		else
			financeNextDayButton.Enable()
		endif



		Game.cursorstate = 0
		GuiManager.Update("officeFinancialScreen")
	End Function


	'right mouse button click: remove the block from the player's programmePlan
	'left mouse button click: check shortcuts and create a copy/nextepisode-block
	Function onClickFinanceButtons:int(triggerEvent:TEventBase)
		local arrowButton:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		if not arrowButton then return False

		if arrowButton = financeHistoryDownButton then financeHistoryStartPos :- 1
		if arrowButton = financeHistoryUpButton then financeHistoryStartPos :+ 1

		if arrowButton = financeNextDayButton then financeShowDay :+ 1
		if arrowButton = financePreviousDayButton then financeShowDay :- 1
	End Function


	'===== OFFICE IMAGE SCREEN =====


	Function onDrawImage:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		local fontColor:TColor = TColor.CreateGrey(50)
		GetBitmapFont("Default",13).drawBlock(GetLocale("IMAGE_REACH") , 55, 233, 330, 20, null, fontColor)
		GetBitmapFont("Default",12).drawBlock(GetLocale("IMAGE_SHARETOTAL") , 55, 45, 330, 20, null, fontColor)
		GetBitmapFont("Default",12).drawBlock(MathHelper.floatToString(100.0 * GetPlayerCollection().Get(room.owner).GetStationMap().getCoverage(), 2) + "%", 280, 45, 93, 20, new TVec2D.Init(ALIGN_RIGHT), fontColor)
	End Function

	Function onUpdateImage:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		'local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		'if not room then return 0

		Game.cursorstate = 0
	End Function



	'===================================
	'Office: Stationmap
	'===================================
	Function InitStationMap()
		'StationMap-GUIcomponents
		stationMapBuyButton = new TGUIButton.Create(new TVec2D.Init(610, 110), new TVec2D.Init(155,-1), "", "STATIONMAP")
		EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapBuy, stationMapBuyButton )
		EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapBuy, stationMapBuyButton )

		stationMapSellButton = new TGUIButton.Create(new TVec2D.Init(610, 345), new TVec2D.Init(155,-1), "", "STATIONMAP")
		stationMapSellButton.disable()
		EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapSell, stationMapSellButton )
		EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapSell, stationMapSellButton )

		'we have to refresh the gui station list as soon as we remove or add a station
		EventManager.registerListenerFunction( "stationmap.removeStation",	OnChangeStationMapStation )
		EventManager.registerListenerFunction( "stationmap.addStation",	OnChangeStationMapStation )

		stationList = new TGUISelectList.Create(new TVec2D.Init(595,233), new TVec2D.Init(185,100), "STATIONMAP")
		EventManager.registerListenerFunction( "GUISelectList.onSelectEntry", OnSelectEntry_StationMapStationList, stationList )

		'player enters station map screen - set checkboxes according to station map config
		EventManager.registerListenerFunction("screen.onEnter", onEnterStationMapScreen, ScreenCollection.GetScreen("screen_office_stationmap"))


		For Local i:Int = 0 To 3
			stationMapShowStations[i] = new TGUICheckBox.Create(new TVec2D.Init(535, 30 + i * GetSpriteFromRegistry("gfx_gui_ok_off").area.GetH()*GUIManager.globalScale), new TVec2D.Init(20, 20), String(i + 1), "STATIONMAP")
			stationMapShowStations[i].SetChecked(True, False)
			stationMapShowStations[i].ShowCaption(False)
			'register checkbox changes
			EventManager.registerListenerFunction("guiCheckBox.onSetChecked", OnSetChecked_StationMapFilters, stationMapShowStations[i])
		Next
	End Function


	Function onDrawStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		GUIManager.Draw("STATIONMAP")

		For Local i:Int = 0 To 3
			SetColor 100, 100, 100
			DrawRect(564, 32 + i * GetSpriteFromRegistry("gfx_gui_ok_off").area.GetH()*GUIManager.globalScale, 15, 18)
			GetPlayerCollection().Get(i+1).color.SetRGB()
			DrawRect(565, 33 + i * GetSpriteFromRegistry("gfx_gui_ok_off").area.GetH()*GUIManager.globalScale, 13, 16)
		Next
		SetColor 255, 255, 255
		GetBitmapFontManager().baseFont.drawBlock(GetLocale("SHOW_PLAYERS")+":", 480, 15, 100, 20, new TVec2D.Init(ALIGN_RIGHT))

		'draw stations and tooltips
		GetPlayerCollection().Get(room.owner).GetStationMap().Draw()

		'also draw the station used for buying/searching
		If stationMapMouseoverStation then stationMapMouseoverStation.Draw()
		'also draw the station used for buying/searching
		If stationMapSelectedStation then stationMapSelectedStation.Draw(true)

		local font:TBitmapFont = GetBitmapFontManager().baseFont
		GetBitmapFontManager().baseFontBold.drawStyled(GetLocale("PURCHASE"), 595, 18, TColor.clBlack, 1, 1, 0.5)
		GetBitmapFontManager().baseFontBold.drawStyled(GetLocale("YOUR_STATIONS"), 595, 178, TColor.clBlack, 1, 1, 0.5)

		'draw a kind of tooltip over a mouseoverStation
		if stationMapMouseoverStation then stationMapMouseoverStation.DrawInfoTooltip()

		If stationMapMode = 1 and stationMapSelectedStation
			GetBitmapFontManager().baseFontBold.draw( getLocale("MAP_COUNTRY_"+stationMapSelectedStation.getFederalState()), 595, 37, TColor.Create(80,80,0))

			font.draw(GetLocale("REACH")+": ", 595, 55, TColor.clBlack)
			font.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getReach(), 2), 660, 55, 102, 20, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)

			font.draw(GetLocale("INCREASE")+": ", 595, 72, TColor.clBlack)
			font.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getReachIncrease(), 2), 660, 72, 102, 20, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)

			font.draw(GetLocale("PRICE")+": ", 595, 89, TColor.clBlack)
			GetBitmapFontManager().baseFontBold.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getPrice(), 2, 0), 660, 89, 102, 20, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
			SetColor(255,255,255)
		EndIf

		If stationMapSelectedStation and stationMapSelectedStation.paid
			font.draw(GetLocale("REACH")+": ", 595, 200, TColor.clBlack)
			font.drawBlock(TFunctions.convertValue(stationMapSelectedStation.reach, 2, 0), 660, 200, 102, 20, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)

			font.draw(GetLocale("VALUE")+": ", 595, 216, TColor.clBlack)
			GetBitmapFontManager().baseFontBold.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getSellPrice(), 2, 0), 660, 215, 102, 20, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
		EndIf
	End Function


	Function onUpdateStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'backup room if it changed
		if currentSubRoom <> lastSubRoom
			lastSubRoom = currentSubRoom
			'if we changed the room meanwhile - we have to rebuild the stationList
			RefreshStationMapStationList()
		endif

		currentSubRoom = room

		GetPlayerCollection().Get(room.owner).GetStationMap().Update()

		'process right click
		if MOUSEMANAGER.isHit(2)
			local reset:int = (stationMapSelectedStation or stationMapMouseoverStation)

			ResetStationMapAction(0)

			if reset then MOUSEMANAGER.ResetKey(2)
		Endif


		'buying stations using the mouse
		'1. searching
		If stationMapMode = 1
			'create a temporary station if not done yet
			if not StationMapMouseoverStation then StationMapMouseoverStation = GetStationMapCollection().getMap(room.owner).getTemporaryStation( MouseManager.x, MouseManager.y )
			local mousePos:TVec2D = new TVec2D.Init( MouseManager.x, MouseManager.y)

			'if the mouse has moved - refresh the station data and move station
			if not StationMapMouseoverStation.pos.isSame( mousePos )
				StationMapMouseoverStation.pos.CopyFrom(mousePos)
				StationMapMouseoverStation.refreshData()
				'refresh state information
				StationMapMouseoverStation.getFederalState(true)
			endif

			'if mouse gets clicked, we store that position in a separate station
			if MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				if StationMapMouseoverStation.GetHoveredMapSection() and StationMapMouseoverStation.getReach()>0
					StationMapSelectedStation = GetStationMapCollection().getMap(room.owner).getTemporaryStation( StationMapMouseoverStation.pos.x, StationMapMouseoverStation.pos.y )
				endif
			endif

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			if StationMapMouseoverStation.getReach() <= 0 or not StationMapMouseoverStation.GetHoveredMapSection() then StationMapMouseoverStation = null

			if StationMapSelectedStation
				if StationMapSelectedStation.getReach() <= 0 or not StationMapSelectedStation.GetHoveredMapSection() then StationMapSelectedStation = null
			endif
		endif

		GUIManager.Update("STATIONMAP")
	End Function


	Function OnChangeStationMapStation:int( triggerEvent:TEventBase )
		if not currentSubRoom then return FALSE
		'do nothing when not in a roomy

		RefreshStationMapStationList( currentSubRoom.owner )
	End Function


	Function ResetStationMapAction(mode:int=0)
		stationMapMode = mode
		stationMapActionConfirmed = FALSE
		'remove selection
		stationMapSelectedStation = null
		stationMapMouseoverStation = Null

		'reset gui list
		stationList.deselectEntry()
	End Function


	'===================================
	'Stationmap: Connect GUI elements
	'===================================

	Function OnUpdate_StationMapBuy:int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().figure.inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		if stationMapMode=1
			button.value = GetLocale("CONFIRM_PURCHASE")
		else
			button.value = GetLocale("BUY_STATION")
		endif
	End Function

	Function OnClick_StationMapBuy:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().figure.inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		'coming from somewhere else... reset first
		if stationMapMode<>1 then ResetStationMapAction(1)

		If stationMapSelectedStation and stationMapSelectedStation.getReach() > 0
			'add the station (and buy it)
			if GetPlayerCollection().Get().GetStationMap().AddStation(stationMapSelectedStation, TRUE)
				ResetStationMapAction(0)
			endif
		EndIf
	End Function


	Function OnClick_StationMapSell:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().figure.inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		'coming from somewhere else... reset first
		if stationMapMode<>2 then ResetStationMapAction(2)

		If stationMapSelectedStation and stationMapSelectedStation.getReach() > 0
			'remove the station (and sell it)
			if GetPlayerCollection().Get().GetStationMap().RemoveStation(stationMapSelectedStation, TRUE)
				ResetStationMapAction(0)
			endif
		EndIf
	End Function

	'enables/disables the button depending on selection
	'sets button label depending on userAction
	Function OnUpdate_StationMapSell:int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().figure.inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		'noting selected yet
		if not stationMapSelectedStation then return FALSE

		'different owner or not paid
		if stationMapSelectedStation.owner <> GetPlayerCollection().playerID or not stationMapSelectedStation.paid
			button.disable()
		else
			button.enable()
		endif

		if stationMapMode=2
			button.value = GetLocale("CONFIRM_SALE")
		else
			button.value = GetLocale("SELL_STATION")
		endif
	End Function


	'rebuild the stationList - eg. when changed the room (other office)
	Function RefreshStationMapStationList(playerID:int=-1)
		If playerID <= 0 Then playerID = GetPlayerCollection().playerID

		'first fill of stationlist
		stationList.EmptyList()
		'remove potential highlighted item
		stationList.deselectEntry()

		For Local station:TStation = EachIn GetPlayerCollection().Get(playerID).GetStationMap().Stations
			local item:TGUICustomSelectListItem = new TGUICustomSelectListItem.Create(new TVec2D, new TVec2D.Init(100,20), GetLocale("STATION")+" (" + TFunctions.convertValue(station.reach, 2, 0) + ")")
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawValue = DrawMapStationListEntry
			stationList.AddItem( item )
		Next
	End Function


	'custom drawing function for list entries
	Function DrawMapStationListEntry:int(obj:TGUIObject)
		local item:TGUICustomSelectListItem = TGUICustomSelectListItem(obj)
		if not item then return False

		local station:TStation = TStation(item.data.Get("station"))
		if not station then return False

		local sprite:TSprite
		if station.IsActive()
			sprite = GetSpriteFromRegistry("stationlist_antenna_on")
		else
			sprite = GetSpriteFromRegistry("stationlist_antenna_off")
		endif


		'draw with different color according status
		if station.IsActive()
			'draw antenna
			sprite.Draw(Int(item.GetScreenX() + 5), item.GetScreenY() + 0.5*(item.rect.getH() - sprite.GetHeight()))
			item.GetFont().draw(item.GetValue(), Int(item.GetScreenX() + 5 + sprite.GetWidth() + 5), Int(item.GetScreenY() + 2 + 0.5*(item.rect.getH()- item.GetFont().getHeight(item.value))), item.valueColor)
		else
			local oldAlpha:float = GetAlpha()
			SetAlpha oldAlpha*0.5
			'draw antenna
			sprite.Draw(Int(item.GetScreenX() + 5), item.GetScreenY() + 0.5*(item.rect.getH() - sprite.GetHeight()))
			item.GetFont().draw(item.GetValue(), Int(item.GetScreenX() + 5 + sprite.GetWidth() + 5), Int(item.GetScreenY() + 2 + 0.5*(item.rect.getH()- item.GetFont().getHeight(item.value))), item.valueColor.copy().AdjustFactor(50))
			SetAlpha oldAlpha
		endif
	End Function
	

	'an entry was selected - make the linked station the currently selected station
	Function OnSelectEntry_StationMapStationList:int(triggerEvent:TEventBase)
		Local senderList:TGUISelectList = TGUISelectList(triggerEvent._sender)
		If not senderList then return FALSE

		if not currentSubRoom or not GetPlayerCollection().IsPlayer(currentSubRoom.owner) then return FALSE

		'set the linked station as selected station
		'also set the stationmap's userAction so the map knows we want to sell
		local item:TGUISelectListItem = TGUISelectListItem(senderList.getSelectedEntry())
		if item
			stationMapSelectedStation = TStation(item.data.get("station"))
			stationMapMode = 2 'sell
		endif
	End Function


	'set checkboxes according to stationmap config
	Function onEnterStationMapScreen:int(triggerEvent:TEventBase)
		'only players can "enter screens" - so just use "inRoom"

		For local i:int = 0 to 3
			local show:int = GetStationMapCollection().GetMap(GetPlayerCollection().Get().figure.inRoom.owner).showStations[i]
			stationMapShowStations[i].SetChecked(show)
		Next
	End Function


	Function OnSetChecked_StationMapFilters:int(triggerEvent:TEventBase)
		Local button:TGUICheckBox = TGUICheckBox(triggerEvent._sender)
		if not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().figure.inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		local player:int = int(button.value)
		if not GetPlayerCollection().IsPlayer(player) then return FALSE

		'only set if not done already
		if GetPlayerCollection().Get().GetStationMap().showStations[player-1] <> button.isChecked()
			TLogger.Log("StationMap", "show stations for player "+player+": "+button.isChecked(), LOG_DEBUG)
			GetPlayerCollection().Get().GetStationMap().showStations[player-1] = button.isChecked()
		endif
	End Function
End Type



'Archive: handling of players programmearchive - for selling it later, ...
Type RoomHandler_Archive extends TRoomHandler
	Global hoveredGuiProgrammeLicence:TGuiProgrammeLicence = null
	Global draggedGuiProgrammeLicence:TGuiProgrammeLicence = null
	Global openCollectionTooltip:TTooltip

	Global programmeList:TgfxProgrammelist
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListSuitcase:TGUIProgrammeLicenceSlotList = null
	Global DudeArea:TGUISimpleRect	'allows registration of drop-event

	'configuration
	Global suitcasePos:TVec2D				= new TVec2D.Init(40,270)
	Global suitcaseGuiListDisplace:TVec2D	= new TVec2D.Init(14,25)


	Function Init()
		'===== CREATE GUI LISTS =====
		GuiListSuitcase	= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(200, 80), "archive")
		GuiListSuitcase.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.acceptType		= TGUIProgrammeLicenceSlotList.acceptAll
		GuiListSuitcase.SetItemLimit(GameRules.maxProgrammeLicencesInSuitcase)
		GuiListSuitcase.SetSlotMinDimension(GetSpriteFromRegistry("gfx_movie0").area.GetW(), GetSpriteFromRegistry("gfx_movie0").area.GetH())
		GuiListSuitcase.SetAcceptDrop("TGUIProgrammeLicence")

		DudeArea = new TGUISimpleRect.Create(new TVec2D.Init(600,100), new TVec2D.Init(200, 350), "archive" )
		'dude should accept drop - else no recognition
		DudeArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)

		programmeList = New TgfxProgrammelist.Create(575, 16, 21)


		'===== REGISTER EVENTS =====
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "guiGameObject.OnMouseOver", onMouseOverProgrammeLicence, "TGUIProgrammeLicence" )
		'drop programme ... so sell/buy the thing
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropProgrammeLicence, "TGUIProgrammeLicence" )
		'drop programme on dude - add back to player's collection
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropProgrammeLicenceOnDude, "TGUIProgrammeLicence" )
		'check right clicks on a gui block
		EventManager.registerListenerFunction( "guiobject.onClick", onClickProgrammeLicence, "TGUIProgrammeLicence" )

		'register self for all archives-rooms
		For local i:int = 1 to 4
			local room:TRoom = GetRoomCollection().GetFirstByDetails("archive", i)
			if room then super._RegisterHandler(onUpdate, onDraw, room)

			'figure enters room - reset the suitcase's guilist, limit listening to the 4 rooms
			EventManager.registerListenerFunction( "room.onEnter", onEnterRoom, room )
			EventManager.registerListenerFunction( "figure.onTryLeaveRoom", onTryLeaveRoom, null,room )
			EventManager.registerListenerFunction( "room.onLeave", onLeaveRoom, room )
		Next

		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
	End Function


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'for further explanation of this, check
		'RoomHandler_Office.onSaveGameBeginLoad()

		hoveredGuiProgrammeLicence = null
		draggedGuiProgrammeLicence = null
		GuiListSuitcase.EmptyList()

		haveToRefreshGuiElements = true
	End Function


	Function onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.parentPlayerID then return FALSE

		'if the list is open - just close the list and veto against
		'leaving the room
		if programmeList.openState <> 0
			programmeList.SetOpen(0)
			triggerEvent.SetVeto()
			return FALSE
		endif

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammeLicence
			triggerEvent.setVeto()
			return FALSE
		endif

		return TRUE
	End Function


	'remove suitcase licences from a players programme plan
	Function onLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayerID then return FALSE

		'remove all licences in the suitcase from the programmeplan
		local plan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(figure.parentPlayerID)
		For local licence:TProgrammeLicence = EachIn GetPlayerProgrammeCollectionCollection().Get(figure.parentPlayerID).suitcaseProgrammeLicences
			plan.RemoveProgrammeInstancesByLicence(licence, true)
		Next
		return TRUE
	End Function


	Function RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with licences the player does not have any
		'longer in the suitcase

		'suitcase
		For local guiLicence:TGUIProgrammeLicence = eachin GuiListSuitcase._slots
			'if the player has this licence in suitcase, skip deletion
			if GetPlayerCollection().Get().GetProgrammeCollection().HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
			guiLicence = null
		Next

		'===== CREATE NEW =====
		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayerCollection().Get().GetProgrammeCollection().suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem(new TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
			'print "ADD suitcase had missing licence: "+licence.getTitle()
		Next

		haveToRefreshGuiElements = FALSE
	End Function



	'in case of right mouse button click we want to add back the
	'dragged block to the player's programmeCollection
	Function onClickProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("archive") then return FALSE
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiBlock or not guiBlock.isDragged() then return FALSE

		'add back to collection if already dropped it to suitcase before
		if not GetPlayerCollection().Get().GetProgrammeCollection().HasProgrammeLicence(guiBlock.licence)
			GetPlayerCollection().Get().GetProgrammeCollection().RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
		endif
		'remove the gui element
		guiBlock.remove()
		guiBlock = null

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	Function onDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("archive") then return FALSE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiBlock or not receiverList then return FALSE

		local owner:int = guiBlock.licence.owner

		select receiverList
			case GuiListSuitcase
				'check if still in collection - if so, remove
				'from collection and add to suitcase
				if GetPlayerCollection().Get().GetProgrammeCollection().HasProgrammeLicence(guiBlock.licence)
					'remove gui - a new one will be generated automatically
					'as soon as added to the suitcase and the room's update
					guiBlock.remove()

					'if not able to add to suitcase (eg. full), cancel
					'the drop-event
					if not GetPlayerCollection().Get().GetProgrammeCollection().AddProgrammeLicenceToSuitcase(guiBlock.licence)
						triggerEvent.setVeto()
					endif
					
					guiBlock = null
				endif

				'else it is just a "drop back"
				return TRUE
		end select

		return TRUE
	End Function


	'handle cover block drops on the dude
	Function onDropProgrammeLicenceOnDude:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("archive") then return FALSE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver then return FALSE
		if receiver <> DudeArea then return FALSE

		'add back to collection
		GetPlayerCollection().Get().GetProgrammeCollection().RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
		'remove the gui element
		guiBlock.remove()
		guiBlock = null

		return TRUE
	End function


	Function onMouseOverProgrammeLicence:int( triggerEvent:TEventBase )
		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProgrammeLicence = item
		if item.isDragged()
			draggedGuiProgrammeLicence = item
			'if we have an item dragged... we cannot have a menu open
			programmeList.SetOpen(0)
		endif

		return TRUE
	End Function


	'clear the guilist for the suitcase if a player enters
	Function onEnterRoom:int( triggerEvent:TEventBase )
		'we are not interested in other figures than our player's
		local figure:TFigure = TFigure(triggerEvent.GetData().Get("figure"))
		if not figure or not figure.IsActivePlayer() then return FALSE

		'empty the guilist / delete gui elements
		'- the real list still may contain elements with gui-references
		guiListSuitcase.EmptyList()
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return 0
		if room.owner <> GetPlayerCollection().playerID then return FALSE

		programmeList.Draw()

		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		if draggedGuiProgrammeLicence then glowSuitcase = "_glow"
		'draw suitcase
		GetSpriteFromRegistry("gfx_suitcase"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		GUIManager.Draw("archive")

		'draw dude tooltip
		If openCollectionTooltip Then openCollectionTooltip.Render()


		'show sheet from hovered list entries
		if programmeList.hoveredLicence
			programmeList.hoveredLicence.ShowSheet(30,20)
		endif
		'show sheet from hovered suitcase entries
		if hoveredGuiProgrammeLicence
			'draw the current sheet
			hoveredGuiProgrammeLicence.DrawSheet()
		endif
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return 0

		if room.owner <> GetPlayerCollection().playerID then return FALSE

		Game.cursorstate = 0

		'open list when clicking dude
		if not draggedGuiProgrammeLicence
			If not programmeList.GetOpen()
				if THelper.IsIn(MouseManager.x, MouseManager.y, 605,65,160,90) Or THelper.IsIn(MouseManager.x, MouseManager.y, 525,155,240,225)
					'activate tooltip
					If not openCollectionTooltip Then openCollectionTooltip = TTooltip.Create(GetLocale("PROGRAMMELICENCES"), GetLocale("SELECT_LICENCES_FOR_SALE"), 470, 130, 0, 0)
					openCollectionTooltip.enabled = 1
					openCollectionTooltip.Hover()

					Game.cursorstate = 1
					If MOUSEMANAGER.IsHit(1)
						MOUSEMANAGER.resetKey(1)
						Game.cursorstate = 0
						programmeList.SetOpen(1)
					endif
				EndIf
			endif
			programmeList.enabled = TRUE
		else
			'disable list if we have a dragged guiobject
			programmeList.enabled = FALSE
		endif
		programmeList.Update(TgfxProgrammelist.MODE_ARCHIVE)

		'handle tooltip
		If openCollectionTooltip Then openCollectionTooltip.Update()


		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayerCollection().Get().GetProgrammeCollection().suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem( new TGuiProgrammeLicence.CreateWithLicence(licence),"-1" )
		Next

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then RefreshGUIElements()


		'reset hovered block - will get set automatically on gui-update
		hoveredGuiProgrammeLicence = null
		'reset dragged block too
		draggedGuiProgrammeLicence = null

		GUIManager.Update("archive")
	End Function
End Type


'Movie agency
Type RoomHandler_MovieAgency extends TRoomHandler
	Global twinkerTimer:TIntervalTimer = TIntervalTimer.Create(6000,250)
	Global AuctionToolTip:TTooltip

	Global VendorArea:TGUISimpleRect	'allows registration of drop-event

	Global hoveredGuiProgrammeLicence:TGUIProgrammeLicence = null
	Global draggedGuiProgrammeLicence:TGUIProgrammeLicence = null

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listMoviesGood:TProgrammeLicence[]
	Field listMoviesCheap:TProgrammeLicence[]
	Field listSeries:TProgrammeLicence[]

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListMoviesGood:TGUIProgrammeLicenceSlotList = null
	Global GuiListMoviesCheap:TGUIProgrammeLicenceSlotList = null
	Global GuiListSeries:TGUIProgrammeLicenceSlotList = null
	Global GuiListSuitcase:TGUIProgrammeLicenceSlotList = null

	'configuration
	Global suitcasePos:TVec2D = new TVec2D.Init(350,130)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(14,25)
	Field programmesPerLine:int	= 12
	Field movieCheapMaximum:int	= 50000

	Global _instance:RoomHandler_MovieAgency
	Global _initDone:int = FALSE


	Function GetInstance:RoomHandler_MovieAgency()
		if not _instance then _instance = new RoomHandler_MovieAgency
		if not _initDone then _instance.Init()
		return _instance
	End Function


	Method Init:int()
		if _initDone then return FALSE

		'resize arrays
		listMoviesGood	= listMoviesGood[..programmesPerLine]
		listMoviesCheap	= listMoviesCheap[..programmesPerLine]
		listSeries		= listSeries[..programmesPerLine]

		GuiListMoviesGood	= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(596,50), new TVec2D.Init(200,80), "movieagency")
		GuiListMoviesCheap	= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(596,148), new TVec2D.Init(200,80), "movieagency")
		GuiListSeries		= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(596,246), new TVec2D.Init(200,80), "movieagency")
		GuiListSuitcase		= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(200,80), "movieagency")

		GuiListMoviesGood.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListMoviesCheap.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSeries.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSuitcase.guiEntriesPanel.minSize.SetXY(200,80)

		GuiListMoviesGood.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListMoviesCheap.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSeries.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

		GuiListMoviesGood.acceptType	= TGUIProgrammeLicenceSlotList.acceptMovies
		GuiListMoviesCheap.acceptType	= TGUIProgrammeLicenceSlotList.acceptMovies
		GuiListSeries.acceptType		= TGUIProgrammeLicenceSlotList.acceptSeries
		GuiListSuitcase.acceptType		= TGUIProgrammeLicenceSlotList.acceptAll

		GuiListMoviesGood.SetItemLimit(listMoviesGood.length)
		GuiListMoviesCheap.SetItemLimit(listMoviesCheap.length)
		GuiListSeries.SetItemLimit(listSeries.length)
		GuiListSuitcase.SetItemLimit(GameRules.maxProgrammeLicencesInSuitcase)

		GuiListMoviesGood.SetSlotMinDimension(GetSpriteFromRegistry("gfx_movie0").area.GetW(), GetSpriteFromRegistry("gfx_movie0").area.GetH())
		GuiListMoviesCheap.SetSlotMinDimension(GetSpriteFromRegistry("gfx_movie0").area.GetW(), GetSpriteFromRegistry("gfx_movie0").area.GetH())
		GuiListSeries.SetSlotMinDimension(GetSpriteFromRegistry("gfx_movie0").area.GetW(), GetSpriteFromRegistry("gfx_movie0").area.GetH())
		GuiListSuitcase.SetSlotMinDimension(GetSpriteFromRegistry("gfx_movie0").area.GetW(), GetSpriteFromRegistry("gfx_movie0").area.GetH())

		GuiListMoviesGood.SetAcceptDrop("TGUIProgrammeLicence")
		GuiListMoviesCheap.SetAcceptDrop("TGUIProgrammeLicence")
		GuiListSeries.SetAcceptDrop("TGUIProgrammeLicence")
		GuiListSuitcase.SetAcceptDrop("TGUIProgrammeLicence")

		VendorArea = new TGUISimpleRect.Create(new TVec2D.Init(20,60), new TVec2D.Init(GetSpriteFromRegistry("gfx_hint_rooms_movieagency").area.GetW(), GetSpriteFromRegistry("gfx_hint_rooms_movieagency").area.GetH()), "movieagency" )
		'vendor should accept drop - else no recognition
		VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)

		'drop ... so sell/buy the thing
		EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammeLicence, "TGUIProgrammeLicence" )
		EventManager.registerListenerFunction("guiobject.onDropOnTarget", onDropProgrammeLicence, "TGUIProgrammeLicence")
		'is dragging even allowed? - eg. intercept if not enough money
		EventManager.registerListenerFunction("guiobject.onDrag", onDragProgrammeLicence, "TGUIProgrammeLicence")
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction("guiGameObject.OnMouseOver", onMouseOverProgrammeLicence, "TGUIProgrammeLicence")
		'drop on vendor - sell things
		EventManager.registerListenerFunction("guiobject.onDropOnTarget", onDropProgrammeLicenceOnVendor, "TGUIProgrammeLicence")

		local room:TRoom = GetRoomCollection().GetFirstByDetails("movieagency")
		'figure enters room - reset the suitcase's guilist, limit listening to this room
		EventManager.registerListenerFunction("room.onEnter", onEnterRoom, room)
		'figure leaves room - only without dragged blocks
		EventManager.registerListenerFunction("figure.onTryLeaveRoom", onTryLeaveRoom, null, room)
		EventManager.registerListenerFunction("room.onLeave", onLeaveRoom, room)

		super._RegisterScreenHandler( onUpdateMovieAgency, onDrawMovieAgency, ScreenCollection.GetScreen("screen_movieagency"))
		super._RegisterScreenHandler( onUpdateMovieAuction, onDrawMovieAuction, ScreenCollection.GetScreen("screen_movieauction"))

		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)

		_initDone = true
	End Method


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new programmes are not loaded yet

		GetInstance().RemoveAllGuiElements()
		haveToRefreshGuiElements = true
	End Function


	'clear the guilist for the suitcase if a player enters
	Function onEnterRoom:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent.GetSender())
		local figure:TFigure = TFigure(triggerEvent.GetData().Get("figure"))
		if not room or not figure then return FALSE

		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure.parentPlayerID then return False

		'fill all open slots in the agency
		GetInstance().ReFillBlocks()
	End Function


	Function onTryLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent.GetReceiver())

		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.parentPlayerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammeLicence
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function


	'add back the programmes from the suitcase
	'also fill empty blocks, remove gui elements
	Function onLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayerID then return FALSE

		GetPlayerProgrammeCollectionCollection().Get(figure.parentPlayerID).ReaddProgrammeLicencesFromSuitcase()

		return TRUE
	End Function


	'===================================
	'Movie Agency: common TFunctions
	'===================================

	Method GetProgrammeLicencesInStock:int()
		Local ret:Int = 0
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence Then ret:+1
			Next
		Next
		return ret
	End Method


	Method GetProgrammeLicenceByPosition:TProgrammeLicence(position:int)
		if position > GetProgrammeLicencesInStock() then return null
		local currentPosition:int = 0
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence
					if currentPosition = position then return licence
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Method


	Method HasProgrammeLicence:int(licence:TProgrammeLicence)
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local listLicence:TProgrammeLicence = EachIn lists[j]
				if listLicence= licence then return TRUE
			Next
		Next
		return FALSE
	End Method


	Method GetProgrammeLicenceByID:TProgrammeLicence(licenceID:int)
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence and licence.id = licenceID then return licence
			Next
		Next
		return null
	End Method


	Method SellProgrammeLicenceToPlayer:int(licence:TProgrammeLicence, playerID:int)
		if licence.owner = playerID then return FALSE

		if not GetPlayerCollection().IsPlayer(playerID) then return FALSE

		'try to add to suitcase of player
		if not GetPlayerProgrammeCollectionCollection().Get(playerID).AddProgrammeLicenceToSuitcase(licence)
			return FALSE
		endif

		'remove from agency's lists
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = licence then lists[j][i] = null
			Next
		Next

		return TRUE
	End Method


	Method BuyProgrammeLicenceFromPlayer:int(licence:TProgrammeLicence)
		local buy:int = (licence.owner > 0)

		'remove from player (lists and suitcase) - and give him money
		if GetPlayerCollection().IsPlayer(licence.owner)
			GetPlayerProgrammeCollectionCollection().Get(licence.owner).RemoveProgrammeLicence(licence, TRUE)
		endif

		'add to agency's lists - if not existing yet
		if not HasProgrammeLicence(licence) then AddProgrammeLicence(licence)

		return TRUE
	End Method


	Method AddProgrammeLicence:int(licence:TProgrammeLicence)
		'try to fill the licence into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TProgrammeLicence[][]

		'do not add episodes
		if licence.isEpisode()
			licence.owner = 0
			return FALSE
		endif

		if licence.isMovie() or licence.isCollection()
			if licence.getPrice() < movieCheapMaximum
				lists = [listMoviesCheap,listMoviesGood]
			else
				lists = [listMoviesGood,listMoviesCheap]
			endif
		else
			lists = [listSeries]
		endif

		'loop through all lists - as soon as we find a spot
		'to place the programme - do so and return
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if lists[j][i] then continue
				licence.owner = -1
				lists[j][i] = licence
				'print "added licence "+licence.title+" to list "+j+" at spot:"+i
				return TRUE
			Next
		Next

		'there was no empty slot to place that licence
		'so just give it back to the pool
		licence.owner = 0

		return FALSE
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Method RemoveAllGuiElements:int()
		GuiListMoviesGood.EmptyList()
		GuiListMoviesCheap.EmptyList()
		GuiListSeries.EmptyList()
		GuiListSuitcase.EmptyList()

		For local guiLicence:TGUIProgrammeLicence = eachin GuiManager.listDragged
			guiLicence.remove()
			guiLicence = null
		Next

		hoveredGuiProgrammeLicence = null
		draggedGuiProgrammeLicence = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Method


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with movies the player does not have any
		'longer in the suitcase

		'suitcase
		For local guiLicence:TGUIProgrammeLicence = eachin GuiListSuitcase._slots
			'if the player has this licence in suitcase, skip deletion
			if GetPlayerProgrammeCollectionCollection().Get(GetPlayerCollection().playerID).HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
			guiLicence = null
		Next
		'agency lists
		local lists:TProgrammeLicence[][] = [ listMoviesGood,listMoviesCheap,listSeries ]
		local guiLists:TGUIProgrammeLicenceSlotList[] = [ guiListMoviesGood, guiListMoviesCheap, guiListSeries ]
		For local j:int = 0 to guiLists.length-1
			For local guiLicence:TGUIProgrammeLicence = eachin guiLists[j]._slots
				if HasProgrammeLicence(guiLicence.licence) then continue

				'print "REM lists"+j+" has obsolete licence: "+guiLicence.licence.getTitle()
				guiLicence.remove()
				guiLicence = null
			Next
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all programme-lists

		For local j:int = 0 to lists.length-1
			For local licence:TProgrammeLicence = eachin lists[j]
				if not licence then continue
				if guiLists[j].ContainsLicence(licence) then continue

				guiLists[j].addItem(new TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
rem
				local lic:TGUIProgrammeLicence = new TGUIProgrammeLicence.CreateWithLicence(licence)
				GUIManager.Remove(lic)
				guiLists[j].addItem(lic,"-1" )
endrem
				'print "ADD lists"+j+" had missing licence: "+licence.getTitle()
			Next
		Next
		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayerProgrammeCollectionCollection().Get(GetPlayerCollection().playerID).suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem(new TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
			'print "ADD suitcase had missing licence: "+licence.getTitle()
		Next

		haveToRefreshGuiElements = FALSE
	End Method


	'refills slots in the movie agency
	'replaceOffer: remove (some) old programmes and place new there?
	Method RefillBlocks:Int(replaceOffer:int=FALSE, replaceChance:float=1.0)
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		local licence:TProgrammeLicence = null

		haveToRefreshGuiElements = TRUE

		'delete some random movies/series
		if replaceOffer
			for local j:int = 0 to lists.length-1
				for local i:int = 0 to lists[j].length-1
					if not lists[j][i] then continue
					'delete an old movie by a chance of 50%
					if RandRange(0,100) < replaceChance*100
						'reset owner
						lists[j][i].owner = 0
						'unlink from this list
						lists[j][i] = null
					endif
				Next
			Next
		endif


		for local j:int = 0 to lists.length-1
			local warnedOfMissingLicence:int = FALSE
			for local i:int = 0 to lists[j].length-1
				'if exists...skip it
				if lists[j][i] then continue

				if lists[j] = listMoviesGood then licence = TProgrammeLicence.GetRandomWithPrice(75000,-1, TProgrammeLicence.TYPE_MOVIE)
				if lists[j] = listMoviesCheap then licence = TProgrammeLicence.GetRandomWithPrice(0,75000, TProgrammeLicence.TYPE_MOVIE)
				if lists[j] = listSeries then licence = TProgrammeLicence.GetRandom(TProgrammeLicence.TYPE_SERIES)

				'add new licence at slot
				if licence
					licence.owner = -1
					lists[j][i] = licence
				else
					if not warnedOfMissingLicence
						TLogger.log("MovieAgency.RefillBlocks()", "Not enough licences to refill slot["+i+"+] in list["+j+"]", LOG_WARNING | LOG_DEBUG)
						warnedOfMissingLicence = TRUE
					endif
				endif
			Next
		Next
	End Method


	'===================================
	'Movie Agency: Room screen
	'===================================


	Function onMouseOverProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProgrammeLicence = item
		if item.isDragged() then draggedGuiProgrammeLicence = item

		return TRUE
	End Function


	'check if we are allowed to drag that licence
	Function onDragProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		local owner:int = item.licence.owner

		'do not allow dragging items from other players
		if owner > 0 and owner <> GetPlayerCollection().playerID
			triggerEvent.setVeto()
			return FALSE
		endif

		'check whether a player could afford the licence
		'if not - just veto the event so it does not get dragged
		if owner <= 0
			if not GetPlayerCollection().Get().getFinance().canAfford(item.licence.getPrice())
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Function


	'- check if dropping on suitcase and affordable
	'- check if dropping on an item which is not affordable
	Function onTryDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiLicence or not receiverList then return FALSE

		local owner:int = guiLicence.licence.owner

		select receiverList
			case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'check if something is underlaying and whether the
				'player could afford it
				local underlayingItem:TGUIProgrammeLicence = null
				local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", new TVec2D.Init(-1,-1)))
				if coord then underlayingItem = TGUIProgrammeLicence(receiverList.GetItemByCoord(coord))

				'allow drop on own place
				if underlayingItem = guiLicence then return TRUE

				if underlayingItem and not GetPlayerCollection().Get().getFinance().canAfford(underlayingItem.licence.getPrice())
					triggerEvent.SetVeto()
					return FALSE
				endif
			case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				if guiLicence.licence.owner = GetPlayerCollection().playerID then return TRUE

				if not GetPlayerCollection().Get().getFinance().canAfford(guiLicence.licence.getPrice())
					triggerEvent.setVeto()
				endif
		End select

		return TRUE
	End Function


	'dropping takes place - sell/buy licences or veto if not possible
	Function onDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiLicence or not receiverList then return FALSE

		local owner:int = guiLicence.licence.owner

		select receiverList
			case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'when dropping vendor licence on vendor shelf .. no prob
				if guiLicence.licence.owner <= 0 then return true

				if not GetInstance().BuyProgrammeLicenceFromPlayer(guiLicence.licence)
					triggerEvent.setVeto()
					return FALSE
				endif
			case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				if guiLicence.licence.owner = GetPlayerCollection().playerID then return TRUE

				if not GetInstance().SellProgrammeLicenceToPlayer(guiLicence.licence, GetPlayerCollection().playerID)
					triggerEvent.setVeto()
					'try to drop back to old list - which triggers
					'this function again... but with a differing list..
					guiLicence.dropBackToOrigin()
					haveToRefreshGuiElements = TRUE
				endif
		end select

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropProgrammeLicenceOnVendor:int(triggerEvent:TEventBase)
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiLicence or not receiver then return FALSE
		if receiver <> VendorArea then return FALSE

		'do not accept blocks from the vendor itself
		if guiLicence.licence.owner <=0
			triggerEvent.setVeto()
			return FALSE
		endif

		if not GetInstance().BuyProgrammeLicenceFromPlayer(guiLicence.licence)
			triggerEvent.setVeto()
			return FALSE
		else
			'successful - delete that gui block
			guiLicence.remove()
			'remove the whole block too
			guiLicence = null
		endif

		return TRUE
	End function


	Function onDrawMovieAgency:int( triggerEvent:TEventBase )
		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		local glowVendor:string = ""
		if draggedGuiProgrammeLicence
			if draggedGuiProgrammeLicence.licence.owner <= 0
				glowSuitcase = "_glow"
			else
				glowVendor = "_glow"
			endif
		endif

		'let the vendor glow if over auction hammer
		'or if a player's block is dragged
		if not draggedGuiProgrammeLicence
			If THelper.IsIn(MouseManager.x, MouseManager.y, 210,220,140,60)
				GetSpriteFromRegistry("gfx_hint_rooms_movieagency").Draw(20,60)
			endif
		else
			if glowVendor="_glow"
				GetSpriteFromRegistry("gfx_hint_rooms_movieagency").Draw(20,60)
			endif
		endif
		'let the vendor twinker sometimes...
		If twinkerTimer.doAction() then GetSpriteFromRegistry("gfx_gimmick_rooms_movieagency").Draw(10,60)
		'draw suitcase
		GetSpriteFromRegistry("gfx_suitcase"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		SetAlpha 0.5
		local fontColor:TColor = TColor.CreateGrey(50)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("MOVIES"),		642,  27+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SPECIAL_BIN"),	642, 125+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SERIES"), 		642, 223+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")

		if hoveredGuiProgrammeLicence
			'draw the current sheet
			hoveredGuiProgrammeLicence.DrawSheet()
		endif


		If AuctionToolTip Then AuctionToolTip.Render()
	End Function


	Function onUpdateMovieAgency:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.cursorstate = 0

		'if we have a licence dragged ... we should take care of "ESC"-Key
		if draggedGuiProgrammeLicence
			if KeyManager.IsHit(KEY_ESCAPE)
				draggedGuiProgrammeLicence.dropBackToOrigin()
				draggedGuiProgrammeLicence = null
				hoveredGuiProgrammeLicence = null
			endif
		endif


		'show a auction-tooltip (but not if we dragged a block)
		if not hoveredGuiProgrammeLicence
			If THelper.IsIn(MouseManager.x, MouseManager.y, 210,220,140,60)
				If not AuctionToolTip Then AuctionToolTip = TTooltip.Create(GetLocale("AUCTION"), GetLocale("MOVIES_AND_SERIES_AUCTION"), 200, 180, 0, 0)
				AuctionToolTip.enabled = 1
				AuctionToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0
					ScreenCollection.GoToSubScreen("screen_movieauction")
				endif
			EndIf
		endif

		If twinkerTimer.isExpired() then twinkerTimer.Reset()

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiProgrammeLicence = null
		'reset dragged block too
		draggedGuiProgrammeLicence = null

		GUIManager.Update("movieagency")

		If AuctionToolTip Then AuctionToolTip.Update()
	End Function



	'===================================
	'Movie Agency: Room screen
	'===================================

	Function onDrawMovieAuction:int( triggerEvent:TEventBase )
		GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		SetAlpha 0.5
		local fontColor:TColor = TColor.CreateGrey(50)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("MOVIES"),		642,  27+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SPECIAL_BIN"),	642, 125+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SERIES"), 		642, 223+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")
		SetAlpha 0.5;SetColor 0,0,0
		DrawRect(20,10,760,373)
		SetAlpha 1.0;SetColor 255,255,255
		DrawGFXRect(TSpritePack(GetRegistry().Get("gfx_gui_rect")), 120, 60, 555, 290)
		SetAlpha 0.5
		GetBitmapFont("Default",12,BOLDFONT).drawBlock(GetLocale("CLICK_ON_MOVIE_OR_SERIES_TO_PLACE_BID"), 140,317, 535,30, new TVec2D.Init(ALIGN_CENTER), TColor.CreateGrey(230), 2, 1, 0.25)
		SetAlpha 1.0

		TAuctionProgrammeBlocks.DrawAll()
	End Function

	Function onUpdateMovieAuction:int( triggerEvent:TEventBase )
		Game.cursorstate = 0
		TAuctionProgrammeBlocks.UpdateAll()
	End Function
End Type


'News room
Type RoomHandler_News extends TRoomHandler
	global PlannerToolTip:TTooltip
	Global NewsGenreButtons:TGUIButton[5]
	Global NewsGenreTooltip:TTooltip			'the tooltip if hovering over the genre buttons
	Global currentRoom:TRoom					'holding the currently updated room (so genre buttons can access it)

	'lists for visually placing news blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global guiNewsListAvailable:TGUINewsList
	Global guiNewsListUsed:TGUINewsSlotList
	Global draggedGuiNews:TGuiNews = null
	Global hoveredGuiNews:TGuiNews = null

	Function Init()
		'create genre buttons
		'ATTENTION: We could do this in order of The NewsGenre-Values
		'           But better add it to the buttons.data-property
		'           for better checking
		NewsGenreButtons[0]	= new TGUIButton.Create( new TVec2D.Init(20, 194), null, GetLocale("NEWS_TECHNICS_MEDIA"), "newsroom")
		NewsGenreButtons[1]	= new TGUIButton.Create( new TVec2D.Init(69, 194), null, GetLocale("NEWS_POLITICS_ECONOMY"), "newsroom")
		NewsGenreButtons[2]	= new TGUIButton.Create( new TVec2D.Init(20, 247), null, GetLocale("NEWS_SHOWBIZ"), "newsroom")
		NewsGenreButtons[3]	= new TGUIButton.Create( new TVec2D.Init(69, 247), null, GetLocale("NEWS_SPORT"), "newsroom")
		NewsGenreButtons[4]	= new TGUIButton.Create( new TVec2D.Init(118, 247), null, GetLocale("NEWS_CURRENTAFFAIRS"), "newsroom")
		for local i:int = 0 to 4
			NewsGenreButtons[i].SetAutoSizeMode( TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE )
			'adjust width according sprite dimensions
			NewsGenreButtons[i].spriteName = "gfx_news_btn"+i
			'disable drawing of caption
			NewsGenreButtons[i].caption.Hide()
		Next

		'add news genre to button data
		NewsGenreButtons[0].data.AddNumber("newsGenre", TNewsEvent.GENRE_TECHNICS)
		NewsGenreButtons[1].data.AddNumber("newsGenre", TNewsEvent.GENRE_POLITICS)
		NewsGenreButtons[2].data.AddNumber("newsGenre", TNewsEvent.GENRE_SHOWBIZ)
		NewsGenreButtons[3].data.AddNumber("newsGenre", TNewsEvent.GENRE_SPORT)
		NewsGenreButtons[4].data.AddNumber("newsGenre", TNewsEvent.GENRE_CURRENTS)


		'we are interested in the genre buttons
		for local i:int = 0 until len( NewsGenreButtons )
			EventManager.registerListenerFunction( "guiobject.onMouseOver", onHoverNewsGenreButtons, NewsGenreButtons[i] )
			EventManager.registerListenerFunction( "guiobject.onDraw", onDrawNewsGenreButtons, NewsGenreButtons[i] )
			EventManager.registerListenerFunction( "guiobject.onClick", onClickNewsGenreButtons, NewsGenreButtons[i] )
		Next

		'create the lists in the news planner
		guiNewsListAvailable = new TGUINewsList.Create(new TVec2D.Init(34,20), new TVec2D.Init(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(), 356), "Newsplanner")
		guiNewsListAvailable.SetAcceptDrop("TGUINews")
		guiNewsListAvailable.Resize(guiNewsListAvailable.rect.GetW() + guiNewsListAvailable.guiScrollerV.rect.GetW() + 3,guiNewsListAvailable.rect.GetH())
		guiNewsListAvailable.guiEntriesPanel.minSize.SetXY(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(),356)

		guiNewsListUsed = new TGUINewsSlotList.Create(new TVec2D.Init(444,105), new TVec2D.Init(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(), 3*GetSpriteFromRegistry("gfx_news_sheet0").area.GetH()), "Newsplanner")
		guiNewsListUsed.SetItemLimit(3)
		guiNewsListUsed.SetAcceptDrop("TGUINews")
		guiNewsListUsed.SetSlotMinDimension(0,GetSpriteFromRegistry("gfx_news_sheet0").area.GetH())
		guiNewsListUsed.SetAutofillSlots(false)
		guiNewsListUsed.guiEntriesPanel.minSize.SetXY(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(),3*GetSpriteFromRegistry("gfx_news_sheet0").area.GetH())

		'if the player visually manages the blocks, we need to handle the events
		'so we can inform the programmeplan about changes...
		EventManager.registerListenerFunction("guiobject.onDropOnTargetAccepted", onDropNews, "TGUINews" )
		'this lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction("guiobject.onClick", onClickNews, "TGUINews")

		'we want to get informed if the news situation changes for a user
		EventManager.registerListenerFunction("programmeplan.SetNews", onChangeNews )
		EventManager.registerListenerFunction("programmeplan.RemoveNews", onChangeNews )
		EventManager.registerListenerFunction("programmecollection.addNews", onChangeNews )
		EventManager.registerListenerFunction("programmecollection.removeNews", onChangeNews )
		'we want to know if we hover a specific block
		EventManager.registerListenerFunction("guiGameObject.OnMouseOver", onMouseOverNews, "TGUINews" )

		'for all news rooms - register if someone goes into the planner
		local screen:TScreen = ScreenCollection.GetScreen("screen_news_newsplanning")
		'figure enters screen - reset the guilists, limit listening to the 4 rooms
		if screen then EventManager.registerListenerFunction("screen.onEnter", onEnterNewsPlannerScreen, screen)
		'also we want to interrupt leaving a room with dragged items
		EventManager.registerListenerFunction("screen.OnLeave", onLeaveNewsPlannerScreen, screen)

		super._RegisterScreenHandler( onUpdateNews, onDrawNews, ScreenCollection.GetScreen("screen_news") )
		super._RegisterScreenHandler( onUpdateNewsPlanner, onDrawNewsPlanner, ScreenCollection.GetScreen("screen_news_newsplanning") )


		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
	End Function


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'for further explanation of this, check
		'RoomHandler_Office.onSaveGameBeginLoad()

		hoveredGuiNews = null
		draggedGuiNews = null

		RemoveAllGuiElements()
	End Function


	'===================================
	'News: room screen
	'===================================


	Function onDrawNews:int( triggerEvent:TEventBase )
		GUIManager.Draw("newsroom")
		If PlannerToolTip Then PlannerToolTip.Render()
		If NewsGenreTooltip then NewsGenreTooltip.Render()

	End Function


	Function onUpdateNews:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'store current room for later access (in guiobjects)
		currentRoom = room

		GUIManager.Update("newsroom")

		Game.cursorstate = 0
		If PlannerToolTip Then PlannerToolTip.Update()
		If NewsGenreTooltip Then NewsGenreTooltip.Update()

		'pinwall
		If THelper.IsIn(MouseManager.x, MouseManager.y, 167,60,240,160)
			If not PlannerToolTip Then PlannerToolTip = TTooltip.Create("Newsplaner", "Hinzufügen und entfernen", 180, 100, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				ScreenCollection.GoToSubScreen("screen_news_newsplanning")
			endif
		endif
Rem
	Sjaele wants to use this printer differently

		'printer
		If THelper.IsIn(MouseManager.x, MouseManager.y, 165,240,240,110)
			If not PlannerToolTip Then PlannerToolTip = TTooltip.Create("Newsplaner", "Hinzufügen und entfernen", 180, 260, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				ScreenCollection.GoToSubScreen("screen_news_newsplanning")
			endif
		endif
EndRem
	End Function


	'could handle the buttons in one function ( by comparing triggerEvent._trigger )
	'onHover: handle tooltip
	Function onHoverNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0


		'how much levels do we have?
		local level:int = 0
		local genre:int = -1
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				genre = button.data.GetInt("newsGenre", i)
				level = GetPlayerCollection().Get(room.owner).GetNewsAbonnement( genre )
				exit
			endif
		Next

		if not NewsGenreTooltip then NewsGenreTooltip = TTooltip.Create("genre", "abonnement", 180,100 )
		NewsGenreTooltip.minContentWidth = 180
		NewsGenreTooltip.enabled = 1
		'refresh lifetime
		NewsGenreTooltip.Hover()

		'move the tooltip
		NewsGenreTooltip.area.position.SetXY(Max(21,button.rect.GetX() + button.rect.GetW()), button.rect.GetY()-30)

		If level = 0
			NewsGenreTooltip.title = button.caption.GetValue()+" - "+getLocale("NEWSSTUDIO_NOT_SUBSCRIBED")
			NewsGenreTooltip.content = getLocale("NEWSSTUDIO_SUBSCRIBE_GENRE_LEVEL")+" 1: "+ TNewsAgency.GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
		Else
			NewsGenreTooltip.title = button.caption.GetValue()+" - "+getLocale("NEWSSTUDIO_SUBSCRIPTION_LEVEL")+" "+level
			if level = GameRules.maxAbonnementLevel
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_DONT_SUBSCRIBE_GENRE_ANY_LONGER")+ ": 0" + getLocale("CURRENCY")
			Else
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_NEXT_SUBSCRIPTION_LEVEL")+": "+ TNewsAgency.GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
			EndIf
		EndIf
		if GetPlayerCollection().Get().GetNewsAbonnementDaysMax(genre) > level
			NewsGenreTooltip.content :+ "~n~n"
			local tip:String = getLocale("NEWSSTUDIO_YOU_ALREADY_USED_LEVEL_AND_THEREFOR_PAY")
			tip = tip.Replace("%MAXLEVEL%", GetPlayerCollection().Get().GetNewsAbonnementDaysMax(genre))
			tip = tip.Replace("%TOPAY%", TNewsAgency.GetNewsAbonnementPrice(GetPlayerCollection().Get().GetNewsAbonnementDaysMax(genre)) + getLocale("CURRENCY"))
			NewsGenreTooltip.content :+ getLocale("HINT")+": " + tip
		endif
	End Function


	Function onClickNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0

		'wrong room? go away!
		if room.owner <> GetPlayerCollection().playerID then return 0

		'increase the abonnement
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				GetPlayerCollection().Get().IncreaseNewsAbonnement( button.data.GetInt("newsGenre", i) )
				exit
			endif
		Next
	End Function


	Function onDrawNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0

		'how much levels do we have?
		local level:int = 0
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				level = GetPlayerCollection().Get(room.owner).GetNewsAbonnement( button.data.GetInt("newsGenre", i) )
				exit
			endif
		Next

		'draw the levels
		SetColor 0,0,0
		SetAlpha 0.4
		For Local i:Int = 0 to level-1
			DrawRect( button.rect.GetX()+8+i*10, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -7, 7,4)
		Next
		SetColor 255,255,255
		SetAlpha 1.0
	End Function



	'===================================
	'News: NewsPlanner screen
	'===================================

	Function onDrawNewsPlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		SetColor 255,255,255  'normal
		GUIManager.Draw("Newsplanner")

local count:int = 0
for local news:TGUINews = Eachin GUIMANAGER.list
	count:+1
Next
SetColor 0,0,0
DrawText("RONNY: inList="+guiNewsListAvailable.entries.Count()+"  inManagerList="+count,470, 50)
SetColor 255,255,255
	End Function


	Function onChangeNews:int( triggerEvent:TEventBase )
		'something changed -- refresh  gui elements
		RefreshGuiElements()
	End Function


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		guiNewsListAvailable.emptyList()
		guiNewsListUsed.emptyList()

		For local guiNews:TGuiNews = eachin GuiManager.listDragged
			guiNews.remove()
			guiNews = null
		Next
		'should not be needed
		rem
		For local guiNews:TGuiNews = eachin GuiManager.list
			guiNews.remove()
			guiNews = null
		Next
		endrem
	End Function


	Function RefreshGuiElements:int()
		local owner:int = GetPlayerCollection().playerID
		'remove gui elements with news the player does not have anylonger
		For local guiNews:TGuiNews = eachin guiNewsListAvailable.entries
			if not GetPlayerProgrammeCollectionCollection().Get(owner).hasNews(guiNews.news)
				guiNews.remove()
				guiNews = null
			endif
		Next
		For local guiNews:TGuiNews = eachin guiNewsListUsed._slots
			if not GetPlayerProgrammePlanCollection().Get(owner).hasNews(guiNews.news)
				guiNews.remove()
				guiNews = null
			endif
		Next

		'if removing "dragged" we also bug out the "replace"-mechanism when
		'dropping on occupied slots
		'so therefor this items should check itself for being "outdated"
		'For local guiNews:TGuiNews = eachin GuiManager.ListDragged
		'	if guiNews.news.isOutdated() then guiNews.remove()
		'Next

		'fill a list containing dragged news - so we do not create them again
		local draggedNewsList:TList = CreateList()
		For local guiNews:TGuiNews = eachin GuiManager.ListDragged
			draggedNewsList.addLast(guiNews.news)
		Next

		'create gui element for news still missing them
		For Local news:TNews = EachIn GetPlayerProgrammeCollectionCollection().Get(owner).news
			'skip if news is dragged
			if draggedNewsList.contains(news) then continue

			if not guiNewsListAvailable.ContainsNews(news)
				'only add for news NOT planned in the news show
				if not GetPlayerCollection().Get().GetProgrammePlan().HasNews(news)
					local guiNews:TGUINews = new TGUINews.Create(null,null, news.GetTitle())
					guiNews.SetNews(news)
					guiNewsListAvailable.AddItem(guiNews)
				endif
			endif
		Next
		For Local i:int = 0 to GetPlayerCollection().Get().GetProgrammePlan().news.length - 1
			local news:TNews = TNews(GetPlayerProgrammePlanCollection().Get(owner).GetNews(i))
			'skip if news is dragged
			if news and draggedNewsList.contains(news) then continue

			if news and not guiNewsListUsed.ContainsNews(news)
				local guiNews:TGUINews = new TGUINews.Create(null,null, news.GetTitle())
				guiNews.SetNews(news)
				guiNewsListUsed.AddItem(guiNews, string(i))
			endif
		Next

		haveToRefreshGuiElements = FALSE
	End Function


	Function onUpdateNewsPlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'if we have a licence dragged ... we should take care of "ESC"-Key
		if draggedGuiNews
			if KeyManager.IsHit(KEY_ESCAPE)
				draggedGuiNews.dropBackToOrigin()
			endif
		endif

		Game.cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then RefreshGUIElements()

		'reset dragged block - will get set automatically on gui-update
		hoveredGuiNews = null
		draggedGuiNews = null

		'general newsplanner elements
		GUIManager.Update("Newsplanner")
	End Function


	'we need to know whether we dragged or hovered an item - so we
	'can react to right clicks ("forbid room leaving")
	Function onMouseOverNews:int( triggerEvent:TEventBase )
		local item:TGUINews = TGUINews(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiNews = item
		if item.isDragged() then draggedGuiNews = item

		return TRUE
	End Function


	'in case of right mouse button click we want to remove the
	'block from the player's programmePlan
	Function onClickNews:int(triggerEvent:TEventBase)
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiNews:TGUINews= TGUINews(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiNews or not guiNews.isDragged() then return FALSE

		'remove from plan (with addBackToCollection=FALSE) and collection
		local player:TPlayer = GetPlayerCollection().Get(guiNews.news.owner)
		player.GetProgrammePlan().RemoveNews(guiNews.news, -1, FALSE)
		player.GetProgrammeCollection().RemoveNews(guiNews.news)

		'remove gui object
		guiNews.remove()
		guiNews = null
		
		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	Function onDropNews:int(triggerEvent:TEventBase)
		local guiNews:TGUINews = TGUINews( triggerEvent._sender )
		local receiverList:TGUIListBase = TGUIListBase( triggerEvent._receiver )
		if not guiNews or not receiverList then return FALSE

		local player:TPlayer = GetPlayerCollection().Get(guiNews.news.owner)
		if not player then return False

		if receiverList = guiNewsListAvailable
			player.GetProgrammePlan().RemoveNews(guiNews.news, -1, TRUE)
		elseif receiverList = guiNewsListUsed
			local slot:int = -1
			'check drop position
			local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", new TVec2D.Init(-1,-1)))
			if coord then slot = guiNewsListUsed.GetSlotByCoord(coord)
			if slot = -1 then slot = guiNewsListUsed.getSlot(guiNews)

			'this may also drag a news that occupied that slot before
			player.GetProgrammePlan().SetNews(guiNews.news, slot)
		endif
	End Function


	'clear the guilist for the suitcase if a player enters
	'screens are only handled by real players
	Function onEnterNewsPlannerScreen:int(triggerEvent:TEventBase)
		'empty the guilist / delete gui elements
		RemoveAllGuiElements()
		RefreshGUIElements()
	End Function


	Function onLeaveNewsPlannerScreen:int( triggerEvent:TEventBase )
		'do not allow leaving as long as we have a dragged block
		if draggedGuiNews
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function
End Type



'Chief: credit and emmys - your boss :D
Type RoomHandler_Chief extends TRoomHandler
	'smoke effect
	Global smokeEmitter:TSpriteParticleEmitter
	Global Dialogues:TList = CreateList()

	Function Init()
		local smokeConfig:TData = new TData
		smokeConfig.Add("sprite", GetSpriteFromRegistry("gfx_tex_smoke"))
		smokeConfig.AddNumber("velocityMin", 5.0)
		smokeConfig.AddNumber("velocityMax", 35.0)
		smokeConfig.AddNumber("lifeMin", 0.30)
		smokeConfig.AddNumber("lifeMax", 2.75)
		smokeConfig.AddNumber("scaleMin", 0.1)
		smokeConfig.AddNumber("scaleMax", 0.15)
		smokeConfig.AddNumber("angleMin", 176)
		smokeConfig.AddNumber("angleMax", 184)
		smokeConfig.AddNumber("xRange", 2)
		smokeConfig.AddNumber("yRange", 2)

		local emitterConfig:TData = new TData
		emitterConfig.Add("area", new TRectangle.Init(69, 335, 0, 0))
		emitterConfig.AddNumber("particleLimit", 100)
		emitterConfig.AddNumber("spawnEveryMin", 0.30)
		emitterConfig.AddNumber("spawnEveryMax", 0.60)

		smokeEmitter = new TSpriteParticleEmitter.Init(emitterConfig, smokeConfig)


		'register self for all bosses
		For local i:int = 1 to 4
			local room:TRoom = GetRoomCollection().GetFirstByDetails("chief", i)
			if room then super._RegisterHandler(RoomHandler_Chief.Update, RoomHandler_Chief.Draw, room)
		Next
		'register dialogue handlers
		EventManager.registerListenerFunction("dialogue.onAcceptBossCredit", onAcceptBossCredit)
		EventManager.registerListenerFunction("dialogue.onRepayBossCredit", onRepayBossCredit)

	End Function


	Function onAcceptBossCredit:int(triggerEvent:TEventBase)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		GetPlayerCollection().Get().GetFinance().TakeCredit(value)
	End Function


	Function onRepayBossCredit:int(triggerEvent:TEventBase)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		GetPlayerCollection().Get().GetFinance().RepayCredit(value)
	End Function


	Function Draw:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return 0

		smokeEmitter.Draw()

		For Local dialog:TDialogue = EachIn Dialogues
			dialog.Draw()
		Next
	End Function

	Function Update:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return 0

		GetPlayerCollection().Get().figure.fromroom = Null

		If Dialogues.Count() <= 0
			Local ChefDialoge:TDialogueTexts[5]
			ChefDialoge[0] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_WELCOME").replace("%1", GetPlayerCollection().Get().name) )
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_WILLNOTDISTURB"), - 2, Null))
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_ASKFORCREDIT"), 1, Null))

			If GetPlayerCollection().Get().GetCredit() > 0
				ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_REPAYCREDIT"), 3, Null))
			endif
			If GetPlayerCollection().Get().GetCreditAvailable() > 0
				local acceptEvent:TEventSimple = TEventSimple.Create("dialogue.onAcceptBossCredit", new TData.AddNumber("value", GetPlayerCollection().Get().GetCreditAvailable()))
				ChefDialoge[1] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_OK").replace("%1", GetPlayerCollection().Get().GetCreditAvailable()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_OK_ACCEPT"), 2, acceptEvent))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			Else
				ChefDialoge[1] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY").replace("%1", GetPlayerCollection().Get().GetCredit()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_ACCEPT"), 3))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			EndIf
			ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))

			ChefDialoge[2] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_BACKTOWORK").replace("%1", GetPlayerCollection().Get().name) )
			ChefDialoge[2].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_BACKTOWORK_OK"), - 2))

			ChefDialoge[3] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_BOSSRESPONSE") )
			If GetPlayerCollection().Get().GetCredit() >= 100000 And GetPlayerCollection().Get().GetMoney() >= 100000
				local payBackEvent:TEventSimple = TEventSimple.Create("dialogue.onRepayBossCredit", new TData.AddNumber("value", 100000))
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_100K"), - 2, payBackEvent))
			EndIf
			If GetPlayerCollection().Get().GetCredit() < GetPlayerCollection().Get().GetMoney()
				local payBackEvent:TEventSimple = TEventSimple.Create("dialogue.onRepayBossCredit", new TData.AddNumber("value", GetPlayerCollection().Get().GetCredit()))
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_ALL").replace("%1", GetPlayerCollection().Get().GetCredit()), - 2, payBackEvent))
			EndIf
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))
			Local ChefDialog:TDialogue = TDialogue.Create(350, 60, 450, 200)
			ChefDialog.AddText(Chefdialoge[0])
			ChefDialog.AddText(Chefdialoge[1])
			ChefDialog.AddText(Chefdialoge[2])
			ChefDialog.AddText(Chefdialoge[3])
			Dialogues.AddLast(ChefDialog)
		EndIf

		smokeEmitter.Update()

		For Local dialog:TDialogue = EachIn Dialogues
			If dialog.Update() = 0
				GetPlayerCollection().Get().figure.LeaveRoom()
				Dialogues.Remove(dialog)
			endif
		Next
	End Function

	rem
	  Local ChefText:String
	  ChefText = "Was ist?!" + Chr(13) + "Haben Sie nichts besseres zu tun als meine Zeit zu verschwenden?" + Chr(13) + " " + Chr(13) + "Ab an die Arbeit oder jemand anderes erledigt Ihren Job...!"
	  If Betty.LastAwardWinner <> GetPlayerCollection().playerID And Betty.LastAwardWinner <> 0
		If Betty.GetAwardTypeString() <> "NONE" Then ChefText = "In " + (Betty.GetAwardEnding() - Game.day) + " Tagen wird der Preis für " + Betty.GetAwardTypeString() + " verliehen. Holen Sie den Preis oder Ihr Job ist nicht mehr sicher."
		If Betty.LastAwardType <> 0
			ChefText = "Was fällt Ihnen ein den Award für " + Betty.GetAwardTypeString(Betty.LastAwardType) + " nicht zu holen?!" + Chr(13) + " " + Chr(13) + "Naja ich hoffe mal Sie schnappen sich den Preis für " + Betty.GetAwardTypeString() + "."
		EndIf
	  EndIf
	  TFunctions.DrawDialog(Assets.GetSpritePack("gfx_dialog"), 350, 60, 450, 120, "StartLeftDown", 0, ChefText, Font14)
	endrem

End Type




'Movie agency
Type RoomHandler_AdAgency extends TRoomHandler
	Global hoveredGuiAdContract:TGuiAdContract = null
	Global draggedGuiAdContract:TGuiAdContract = null

	Global VendorArea:TGUISimpleRect	'allows registration of drop-event

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listNormal:TAdContract[]
	Field listCheap:TAdContract[]

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListNormal:TGUIAdContractSlotList[]
	Global GuiListCheap:TGUIAdContractSlotList = null
	Global GuiListSuitcase:TGUIAdContractSlotList = null

	'configuration
	Global suitcasePos:TVec2D = new TVec2D.Init(520,100)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(19,32)
	Global contractsPerLine:int	= 4
	Global contractsNormalAmount:int = 12
	Global contractsCheapAmount:int	= 4
	Global contractCheapAudienceMaximum:float = 0.05 '5% market share

	Global _instance:RoomHandler_AdAgency
	Global _initDone:int = FALSE


	Function GetInstance:RoomHandler_AdAgency()
		if not _instance then _instance = new RoomHandler_AdAgency
		if not _initDone then _instance.Init()
		return _instance
	End Function


	Method Init:int()
		if _initDone then return FALSE

		'===== CREATE/RESIZE LISTS =====

		listNormal = listNormal[..contractsNormalAmount]
		listCheap = listCheap[..contractsCheapAmount]


		'===== CREATE GUI LISTS =====

		GuiListNormal	= GuiListNormal[..3]
		for local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i] = new TGUIAdContractSlotList.Create(new TVec2D.Init(430 - i*70, 170 + i*32), new TVec2D.Init(200, 140), "adagency")
			GuiListNormal[i].SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListNormal[i].SetItemLimit( contractsNormalAmount / GuiListNormal.length  )
			GuiListNormal[i].Resize(GetSpriteFromRegistry("gfx_contracts_0").area.GetW() * (contractsNormalAmount / GuiListNormal.length), GetSpriteFromRegistry("gfx_contracts_0").area.GetH() )
			GuiListNormal[i].SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW(), GetSpriteFromRegistry("gfx_contracts_0").area.GetH())
			GuiListNormal[i].SetAcceptDrop("TGuiAdContract")
			GuiListNormal[i].setZindex(i)
		Next

		GuiListSuitcase	= new TGUIAdContractSlotList.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(200,80), "adagency")
		GuiListSuitcase.SetAutofillSlots(true)

		GuiListCheap = new TGUIAdContractSlotList.Create(new TVec2D.Init(70, 200), new TVec2D.Init(10 +GetSpriteFromRegistry("gfx_contracts_0").area.GetW()*4,GetSpriteFromRegistry("gfx_contracts_0").area.GetH()), "adagency")
		GuiListCheap.setEntriesBlockDisplacement(70,0)



		GuiListCheap.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

		GuiListCheap.SetItemLimit(listCheap.length)
		GuiListSuitcase.SetItemLimit(GameRules.maxContracts)

		GuiListCheap.SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW(), GetSpriteFromRegistry("gfx_contracts_0").area.GetH())
		GuiListSuitcase.SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW(), GetSpriteFromRegistry("gfx_contracts_0").area.GetH())

		GuiListCheap.SetEntryDisplacement( -2*GuiListNormal[0]._slotMinDimension.x, 5)
		GuiListSuitcase.SetEntryDisplacement( 0, 0)

		GuiListCheap.SetAcceptDrop("TGuiAdContract")
		GuiListSuitcase.SetAcceptDrop("TGuiAdContract")

		VendorArea = new TGUISimpleRect.Create(new TVec2D.Init(286, 110), new TVec2D.Init(GetSpriteFromRegistry("gfx_hint_rooms_adagency").area.GetW(), GetSpriteFromRegistry("gfx_hint_rooms_adagency").area.GetH()), "adagency" )
		'vendor should accept drop - else no recognition
		VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)


		'===== REGISTER EVENTS =====

		'to react on changes in the programmeCollection (eg. contract finished)
		EventManager.registerListenerFunction( "programmecollection.addAdContract", onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.removeAdContract", onChangeProgrammeCollection )

		'figure enters room - reset guilists and refill slots
		EventManager.registerListenerFunction( "room.onEnter", onEnterRoom, GetRoomCollection().GetFirstByDetails("adagency") )

		'2014/05/04 (Ronny): commented out, currently no longer in use
		'begin drop - to intercept if dropping to wrong list
		'EventManager.registerListenerFunction( "guiobject.onTryDropOnTarget", onTryDropContract, "TGuiAdContract" )

		'instead of "guiobject.onDropOnTarget" the event "guiobject.onDropOnTargetAccepted"
		'is only emitted if the drop is successful (so it "visually" happened)
		'drop ... to vendor or suitcase
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropContract, "TGuiAdContract" )
		'drop on vendor - sell things
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropContractOnVendor, "TGuiAdContract" )
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "guiGameObject.OnMouseOver", onMouseOverContract, "TGuiAdContract" )
		'figure leaves room - only without dragged blocks
		EventManager.registerListenerFunction( "figure.onTryLeaveRoom", onTryLeaveRoom, null, GetRoomCollection().GetFirstByDetails("adagency") )
		EventManager.registerListenerFunction( "room.onLeave", onLeaveRoom, GetRoomCollection().GetFirstByDetails("adagency") )
		'this lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction("guiobject.onClick", onClickContract, "TGuiAdContract")

		super._RegisterScreenHandler( onUpdateAdAgency, onDrawAdAgency, ScreenCollection.GetScreen("screen_adagency") )

		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)

		_initDone = true
	End Method


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new contracts are not loaded yet

		'We cannot rely on "onEnterRoom" as we could have saved
		'in this room
		GetInstance().RemoveAllGuiElements()
		haveToRefreshGuiElements = true
	End Function



	Function onEnterRoom:int(triggerEvent:TEventBase)
		local room:TRoom = TRoom(triggerEvent.GetSender())
		local figure:TFigure = TFigure(triggerEvent.GetData().Get("figure"))
		if not room or not figure then return FALSE

		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure.parentPlayerID then return False

		if figure.IsActivePlayer()
			GetInstance().ResetContractOrder()
		endif

		'refill the empty blocks, also sets haveToRefreshGuiElements=true
		'so next call the gui elements will be redone
		GetInstance().ReFillBlocks()
	End function


	Function onTryLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent.GetReceiver())
		if not room then return FALSE

		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.parentPlayerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiAdContract
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function


	'add back the programmes from the suitcase
	'also fill empty blocks, remove gui elements
	Function onLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayerID then return FALSE

		'sign all new contracts
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollectionCollection().Get(figure.parentPlayerID)
		For Local contract:TAdContract = EachIn programmeCollection.suitcaseAdContracts
			'adds a contract to the players collection (gets signed THERE)
			'if successful, this also removes the contract from the suitcase
			programmeCollection.AddAdContract(contract)
		Next

		return TRUE
	End Function


	'===================================
	'AD Agency: common TFunctions
	'===================================

	Method GetContractsInStock:int()
		Local ret:Int = 0
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				if contract Then ret:+1
			Next
		Next
		return ret
	End Method


	Method GetContractByPosition:TAdContract(position:int)
		if position > GetContractsInStock() then return null
		local currentPosition:int = 0
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				if contract
					if currentPosition = position then return contract
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Method


	Method HasContract:int(contract:TAdContract)
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local cont:TAdContract = EachIn lists[j]
				if cont = contract then return TRUE
			Next
		Next
		return FALSE
	End Method


	Method GetContractByID:TAdContract(contractID:int)
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				if contract and contract.id = contractID then return contract
			Next
		Next
		return null
	End Method


	Method GiveContractToPlayer:int(contract:TAdContract, playerID:int, sign:int=FALSE)
		if contract.owner = playerID then return FALSE
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		if not programmeCollection then return FALSE

		'try to add to suitcase of player
		if not sign
			if not programmeCollection.AddUnsignedAdContractToSuitcase(contract) then return FALSE
		'we do not need the suitcase, direkt sign pls (eg. for AI)
		else
			if not programmeCollection.AddAdContract(contract) then return FALSE
		endif

		'remove from agency's lists
		GetInstance().RemoveContract(contract)

		return TRUE
	End Method


	Method TakeContractFromPlayer:int(contract:TAdContract, playerID:int)
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		if not programmeCollection then return False

		if programmeCollection.RemoveUnsignedAdContractFromSuitcase(contract)
			'add to agency's lists - if not existing yet
			if not HasContract(contract) then AddContract(contract)

			return TRUE
		else
			return FALSE
		endif
	End Method


	Function isCheapContract:int(contract:TAdContract)
		return contract.GetMinAudiencePercentage() < contractCheapAudienceMaximum
	End Function


	Method ResetContractOrder:int()
		local contracts:TList = CreateList()
		for local contract:TAdContract = eachin listNormal
			contracts.addLast(contract)
		Next
		for local contract:TAdContract = eachin listCheap
			contracts.addLast(contract)
		Next
		listNormal = new TAdContract[listNormal.length]
		listCheap = new TAdContract[listCheap.length]

		contracts.sort()

		'add again - so it gets sorted
		for local contract:TAdContract = eachin contracts
			AddContract(contract)
		Next

		RemoveAllGuiElements()
	End Method


	Method RemoveContract:int(contract:TAdContract)
		local foundContract:int = FALSE
		'remove from agency's lists
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = contract then lists[j][i] = null;foundContract=TRUE
			Next
		Next

		return foundContract
	End Method


	Method AddContract:int(contract:TAdContract)
		'try to fill the program into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TAdContract[][]

		if isCheapContract(contract)
			lists = [listCheap,listNormal]
		else
			lists = [listNormal,listCheap]
		endif

		'loop through all lists - as soon as we find a spot
		'to place the programme - do so and return
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if lists[j][i] then continue
				contract.owner = -1
				lists[j][i] = contract
				return TRUE
			Next
		Next

		'there was no empty slot to place that programme
		'so just give it back to the pool
		contract.owner = 0

		return FALSE
	End Method



	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		For local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i].EmptyList()
		Next
		GuiListCheap.EmptyList()
		GuiListSuitcase.EmptyList()
		For local guiAdContract:TGuiAdContract = eachin GuiManager.listDragged
			guiAdContract.remove()
			guiAdContract = null
		Next

		hoveredGuiAdContract = null
		draggedGuiAdContract = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Function


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with contracts the player does not have any longer

		'suitcase
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollectionCollection().Get(GetPlayer().playerID)
		For local guiAdContract:TGuiAdContract = eachin GuiListSuitcase._slots
			'if the player has this contract in suitcase or list, skip deletion
			if programmeCollection.HasAdContract(guiAdContract.contract) then continue
			if programmeCollection.HasUnsignedAdContractInSuitcase(guiAdContract.contract) then continue

			'print "guiListSuitcase has obsolete contract: "+guiAdContract.contract.id
			guiAdContract.remove()
			guiAdContract = null
		Next
		'agency lists
		For local i:int = 0 to GuiListNormal.length-1
			For local guiAdContract:TGuiAdContract = eachin GuiListNormal[i]._slots
				'if not HasContract(guiAdContract.contract) then print "REM guiListNormal"+i+" has obsolete contract: "+guiAdContract.contract.id
				if not HasContract(guiAdContract.contract)
					guiAdContract.remove()
					guiAdContract = null
				endif
			Next
		Next
		For local guiAdContract:TGuiAdContract = eachin GuiListCheap._slots
			'if not HasContract(guiAdContract.contract) then	print "REM guiListCheap has obsolete contract: "+guiAdContract.contract.id
			if not HasContract(guiAdContract.contract)
				guiAdContract.remove()
				guiAdContract = null
			endif
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all contract-lists

		'normal list
		For local contract:TAdContract = eachin listNormal
			if not contract then continue
			local contractAdded:int = FALSE

			'search the contract in all of our lists...
			local contractFound:int = FALSE
			For local i:int = 0 to GuiListNormal.length-1
				if contractFound then continue
				if GuiListNormal[i].ContainsContract(contract) then contractFound=true
			Next

			'try to fill in one of the normalList-Parts
			if not contractFound
				For local i:int = 0 to GuiListNormal.length-1
					if contractAdded then continue
					if GuiListNormal[i].ContainsContract(contract) then contractAdded=true;continue
					if GuiListNormal[i].getFreeSlot() < 0 then continue
					local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
					'change look
					block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

					'print "ADD guiListNormal"+i+" missed new contract: "+block.contract.id

					GuiListNormal[i].addItem(block, "-1")
					contractAdded = true
				Next
				if not contractAdded
					TLogger.log("AdAgency.RefreshGuiElements", "contract exists but does not fit in GuiListNormal - contract removed.", LOG_ERROR)
					RemoveContract(contract)
				endif
			endif
		Next

		'cheap list
		For local contract:TAdContract = eachin listCheap
			if not contract then continue
			if GuiListCheap.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

			'print "ADD guiListCheap missed new contract: "+block.contract.id

			GuiListCheap.addItem(block, "-1")
		Next

		'create missing gui elements for the players contracts
		For local contract:TAdContract = eachin programmeCollection.adContracts
			if guiListSuitcase.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			'print "ADD guiListSuitcase missed new (old) contract: "+block.contract.id

			block.setOption(GUI_OBJECT_DRAGABLE, FALSE)
			guiListSuitcase.addItem(block, "-1")
		Next

		'create missing gui elements for the current suitcase
		For local contract:TAdContract = eachin programmeCollection.suitcaseAdContracts
			if guiListSuitcase.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			'print "guiListSuitcase missed new contract: "+block.contract.id

			guiListSuitcase.addItem(block, "-1")
		Next
		haveToRefreshGuiElements = FALSE
	End Method


	'refills slots in the ad agency
	'replaceOffer: remove (some) old contracts and place new there?
	Method ReFillBlocks:Int(replaceOffer:int=FALSE, replaceChance:float=1.0)
		local lists:TAdContract[][] = [listNormal,listCheap]
		local contract:TAdContract = null

		haveToRefreshGuiElements = TRUE

		'delete some random ads
		if replaceOffer
			for local j:int = 0 to lists.length-1
				for local i:int = 0 to lists[j].length-1
					if not lists[j][i] then continue
					'delete an old contract by a chance of 50%
					if RandRange(0,100) < replaceChance*100
						'reset owner
						lists[j][i].owner = 0
						'unlink from this list
						lists[j][i] = null
					endif
				Next
			Next
		endif


		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				'if exists...skip it
				if lists[j][i] then continue

				if lists[j] = listNormal then contract = new TAdContract.Create( GetAdContractBaseCollection().GetRandom() )
				if lists[j] = listCheap then contract = new TAdContract.Create( GetAdContractBaseCollection().GetRandomWithLimitedAudienceQuote(0.0, contractCheapAudienceMaximum) )

				'add new contract to slot
				if contract
					contract.owner = -1
					lists[j][i] = contract
				else
					TLogger.log("AdAgency.ReFillBlocks", "Not enough contracts to fill ad agency in list "+i, LOG_ERROR)
				endif
			Next
		Next
	End Method



	'===================================
	'Ad Agency: Room screen
	'===================================

	'if players are in the agency during changes
	'to their programme collection, react to...
	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("adagency") then return FALSE

		GetInstance().RefreshGuiElements()
	End Function


	'in case of right mouse button click a dragged contract is
	'placed at its original spot again
	Function onClickContract:int(triggerEvent:TEventBase)
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiAdContract:TGuiAdContract= TGUIAdContract(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiAdContract or not guiAdContract.isDragged() then return FALSE

		'remove gui object
		guiAdContract.remove()
		guiAdContract = null

		'rebuild at correct spot
		GetInstance().RefreshGuiElements()

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	Function onMouseOverContract:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("adagency") then return FALSE

		local item:TGuiAdContract = TGuiAdContract(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiAdContract = item
		if item.isDragged() then draggedGuiAdContract = item

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropContractOnVendor:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("adagency") then return FALSE

		local guiBlock:TGuiAdContract = TGuiAdContract( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver or receiver <> VendorArea then return FALSE

		local parent:TGUIobject = guiBlock._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local senderList:TGUIAdContractSlotList = TGUIAdContractSlotList(parent)
		if not senderList then return FALSE

		'if coming from suitcase, try to remove it from the player
		if senderList = GuiListSuitcase
			if not GetInstance().TakeContractFromPlayer(guiBlock.contract, GetPlayerCollection().Get().playerID )
				triggerEvent.setVeto()
				return FALSE
			endif
		else
			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveContract(guiBlock.contract)
			GetInstance().AddContract(guiBlock.contract)
		endif
		'remove the block, will get recreated if needed
		guiBlock.remove()
		guiBlock = null

		'something changed...refresh missing/obsolete...
		GetInstance().RefreshGuiElements()

		return TRUE
	End function


	'in this stage, the item is already added to the new gui list
	'we now just add or remove it to the player or vendor's list
	Function onDropContract:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("adagency") then return FALSE

		local guiAdContract:TGuiAdContract = TGuiAdContract(triggerEvent._sender)
		local receiverList:TGUIAdContractSlotList = TGUIAdContractSlotList(triggerEvent._receiver)
		if not guiAdContract or not receiverList then return FALSE

		'get current owner of the contract, as the field "owner" is set
		'during sign we cannot rely on it. So we check if the player has
		'the contract in the suitcaseContractList
		local owner:int = guiAdContract.contract.owner
		if owner <= 0 and GetPlayerProgrammeCollectionCollection().Get(GetPlayerCollection().playerID).HasUnsignedAdContractInSuitcase(guiAdContract.contract)
			owner = GetPlayerCollection().playerID
		endif

		'find out if we sell it to the vendor or drop it to our suitcase
		if receiverList <> GuiListSuitcase
			guiAdContract.InitAssets( guiAdContract.getAssetName(-1, FALSE ), guiAdContract.getAssetName(-1, TRUE ) )

			'no problem when dropping vendor programme to vendor..
			if owner <= 0 then return TRUE

			if not GetInstance().TakeContractFromPlayer(guiAdContract.contract, GetPlayerCollection().playerID )
				triggerEvent.setVeto()
				return FALSE
			endif

			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveContract(guiAdContract.contract)
			GetInstance().AddContract(guiAdContract.contract)
		else
			guiAdContract.InitAssets(guiAdContract.getAssetName(-1, TRUE ), guiAdContract.getAssetName(-1, TRUE ))
			'no problem when dropping own programme to suitcase..
			if owner = GetPlayerCollection().playerID then return TRUE
			if not GetInstance().GiveContractToPlayer(guiAdContract.contract, GetPlayerCollection().playerID)
				triggerEvent.setVeto()
				return FALSE
			endif
		endIf

		'2014/05/04 (Ronny): commented out, obsolete ?
		'something changed...refresh missing/obsolete...
		'GetInstance().RefreshGuiElements()


		return TRUE
	End Function


	Function onDrawAdAgency:int( triggerEvent:TEventBase )
		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		if draggedGuiAdContract
			if not GetPlayerProgrammeCollectionCollection().Get(GetPlayerCollection().playerID).HasUnsignedAdContractInSuitcase(draggedGuiAdContract.contract)
				glowSuitcase = "_glow"
			endif
			GetSpriteFromRegistry("gfx_hint_rooms_adagency").Draw(VendorArea.getScreenX(), VendorArea.getScreenY())
		endif

		'draw suitcase
		GetSpriteFromRegistry("gfx_suitcase_big"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		GUIManager.Draw("adagency")

		if hoveredGuiAdContract
			'draw the current sheet
			hoveredGuiAdContract.DrawSheet()
		endif

	End Function


	Function onUpdateAdAgency:int( triggerEvent:TEventBase )
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'if we have a licence dragged ... we should take care of "ESC"-Key
		if draggedGuiAdContract
			if KeyManager.IsHit(KEY_ESCAPE)
				draggedGuiAdContract.dropBackToOrigin()
				draggedGuiAdContract = null
				hoveredGuiAdContract = null
			endif
		endif

		Game.cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiAdContract = null
		'reset dragged block too
		draggedGuiAdContract = null

		GUIManager.Update("adagency")
	End Function

End Type


'Dies hier ist die Raumauswahl im Fahrstuhl.
Type RoomHandler_ElevatorPlan extends TRoomHandler
	const signSlot1:int	= 26
	const signSlot2:int	= 208
	const signSlot3:int	= 417
	const signSlot4:int	= 599


	Function Init()
		super._RegisterHandler(onUpdate, onDraw, GetRoomCollection().GetFirstByDetails("elevatorplan") )
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return 0

		TRoomDoorSign.DrawAll()
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return 0

		local mouseClicked:int = MouseManager.IsClicked(1)

		Game.cursorstate = 0

		'if possible, change the target to the clicked door
		if mouseClicked
			local door:TRoomDoor = GetDoorByPlanXY(MouseManager.x,MouseManager.y)
			if door
				local playerFigure:TFigure = GetPlayerCollection().Get().figure
				playerFigure.ChangeTarget(door.area.GetX(), GetBuilding().area.GetY() + TBuilding.GetFloorY(door.area.GetY()))
			endif
		endif

		TRoomDoorSign.UpdateAll(False)
		if mouseClicked then MouseManager.ResetKey(1)
	End Function


	'returns the door defined by a sign at X,Y
	Function GetDoorByPlanXY:TRoomDoor(x:Int=-1, y:Int=-1)
		For Local sign:TRoomDoorSign = EachIn TRoomDoorsign.List
			'virtual rooms
			If sign.rect.GetX() < 0 then continue

			If sign.rect.containsXY(x,y)
				Local xpos:Int = 0
				If sign.rect.GetX() = signSlot1 Then xpos = 1
				If sign.rect.GetX() = signSlot2 Then xpos = 2
				If sign.rect.GetX() = signSlot3 Then xpos = 3
				If sign.rect.GetX() = signSlot4 Then xpos = 4
				Local door:TRoomDoor = TRoomDoor.GetByMapPos(xpos, 13 - Ceil((y-41)/23))
				if door then return door
			EndIf
		Next

		return null
	End Function
End Type


Type RoomHandler_Roomboard extends TRoomHandler
	Function Init()
		super._RegisterHandler(onUpdate, onDraw, GetRoomCollection().GetFirstByDetails("roomboard"))

		EventManager.registerListenerFunction( "figure.onTryLeaveRoom", onTryLeaveRoom, null, GetRoomCollection().GetFirstByDetails("roomboard"))
	End Function


	'gets called if somebody tries to leave the roomboard
	Function onTryLeaveRoom:int(triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent.GetSender())
		local room:TRoom = TRoom(triggerEvent.GetReceiver())
		if not room or not figure then return FALSE

		'only pay attention to players
		if figure.ParentPlayerID
			'roomboard left without animation as soon as something dragged but leave forced
			If room.name = "roomboard" AND TRoomDoorSign.AdditionallyDragged > 0
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Function
	

	Function onDraw:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return 0

		TRoomDoorSign.DrawAll()
	End Function

	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return 0

		Game.cursorstate = 0
		TRoomDoorSign.UpdateAll(True)
		If MouseManager.IsDown(1) Then MouseManager.resetKey(1)
	End Function
End Type

'Betty
Type RoomHandler_Betty extends TRoomHandler
	Function Init()
		super._RegisterHandler(onUpdate, onDraw, GetRoomCollection().GetFirstByDetails("betty"))
	End Function

	Function onDraw:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent._sender)
		if not room then return 0

		For Local i:Int = 1 To 4
			local sprite:TSprite = GetSpriteFromRegistry("gfx_room_betty_picture1")
			Local picY:Int = 240
			Local picX:Int = 410 + i * (sprite.area.GetW() + 5)
			sprite.Draw( picX, picY )
			SetAlpha 0.4
			GetPlayerCollection().Get(i).color.copy().AdjustRelative(-0.5).SetRGB()
			DrawRect(picX + 2, picY + 8, 26, 28)
			SetColor 255, 255, 255
			SetAlpha 1.0
			local x:float = picX + Int(sprite.area.GetW() / 2) - Int(GetPlayerCollection().Get(i).Figure.Sprite.framew / 2)
			local y:float = picY + sprite.area.GetH() - 30
			GetPlayerCollection().Get(i).Figure.Sprite.DrawClipped(new TRectangle.Init(x, y, -1, sprite.area.GetH()-16), null, 8)
		Next

		DrawDialog("default", 430, 120, 280, 110, "StartLeftDown", 0, GetLocale("DIALOGUE_BETTY_WELCOME"), GetBitmapFont("Default",14))
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		'nothing yet
	End Function
End Type



'RoomAgency
Type RoomHandler_RoomAgency extends TRoomHandler
	Function Init()
		super._RegisterHandler(onUpdate, onDraw, GetRoomCollection().GetFirstByDetails("roomagency"))
	End Function


	Function RentRoom:int(room:TRoom, owner:int=0)
		print "RoomHandler_RoomAgency.RentRoom()"
		room.ChangeOwner(owner)
	End Function


	Function CancelRoom:int(room:TRoom)
		print "RoomHandler_RoomAgency.CancelRoom()"
		room.ChangeOwner(0)
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		'nothing yet
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		'nothing yet
	End Function
End Type



'helper for Credits
Type TCreditsRole
	field name:string = ""
	field cast:string[]
	field color:TColor

	Method Init:TCreditsRole(name:string, color:TColor)
		self.name = name
		self.color = color
		return self
	End Method

	Method addCast:int(name:string)
		cast = cast[..cast.length+1]
		cast[cast.length-1] = name
		return true
	End Method
End Type


Type RoomHandler_Credits extends TRoomHandler
	Global roles:TCreditsRole[]
	Global currentRolePosition:int = 0
	Global currentCastPosition:int = 0
	Global changeRoleTimer:TIntervalTimer = TIntervalTimer.Create(3200, 0)
	Global fadeTimer:TIntervalTimer = TIntervalTimer.Create(1000, 0)
	Global fadeMode:int = 0 '0 = fadein, 1=stay, 2=fadeout
	Global fadeRole:int = TRUE
	Global fadeValue:float = 0.0

	Function Init()
		super._RegisterHandler(onUpdate, onDraw, GetRoomCollection().GetFirstByDetails("credits"))

		'player figure enters screen - reset the current displayed role
		EventManager.registerListenerFunction("room.onEnter", OnEnterRoom, GetRoomCollection().GetFirstByDetails("credits"))


		local role:TCreditsRole
		local cast:TList = null

		role = CreateRole("Das TVTower-Team", TColor.Create(255,255,255))
		role.addCast("und die fleissigen Helfer")

		role = CreateRole("Programmierung", TColor.Create(200,200,0))
		role.addCast("Ronny Otto~n(Engine, Spielmechanik)")
		role.addCast("Manuel Vögele~n(Quotenberechnung, Sendermarkt)")

		role = CreateRole("Grafik", TColor.Create(240,160,150))
		role.addCast("Ronny Otto")

		role = CreateRole("KI-Entwicklung", TColor.Create(140,240,250))
		role.addCast("Ronny Otto~n(KI-Anbindung)")
		role.addCast("Manuel Vögele~n(KI-Verhalten & -Anbindung)")

		role = CreateRole("Datenbank-Team", TColor.Create(210,120,250))
		role.addCast("Ronny Otto")
		role.addCast("Martin Rackow")
		role.addCast("u.a. Freiwillige")

		role = CreateRole("Tester", TColor.Create(160,180,250))
		role.addCast("...und Motivationsteam")
		role.addCast("Basti")
		role.addCast("Ceddy")
		role.addCast("dirkw")
		role.addCast("djmetzger")
		role.addCast("Kurt TV")
		role.addCast("Själe")
		role.addCast("SushiTV")
		role.addCast("...und all die anderen Fehlermelder im Forum")


		role = CreateRole("", TColor.clWhite)
		role.addCast("")

		role = CreateRole("Besucht uns im Netz", TColor.clWhite)
		role.addCast("http://www.tvgigant.de")

		role = CreateRole("", TColor.clWhite)
		role.addCast("")

	End Function


	'helper to create a role and store it in the array
	Function CreateRole:TCreditsRole(name:string, color:TColor)
		roles = roles[..roles.length+1]
		roles[roles.length-1] = new TCreditsRole.Init(name, color)
		return roles[roles.length-1]
	End Function


	Function GetRole:TCreditsRole()
		'reached end
		if currentRolePosition = roles.length then currentRolePosition = 0
		return roles[currentRolePosition]
	End Function


	Function GetCast:string(addToCurrent:int=0)
		local role:TCreditsRole = GetRole()
		'reached end
		if (currentCastPosition + addToCurrent) = role.cast.length then return NULL
		return role.cast[currentCastPosition + addToCurrent]
	End function


	Function NextCast:int()
		currentCastPosition :+1
		return (GetCast() <> "")
	End Function


	Function NextRole:int()
		currentRolePosition :+1
		currentCastPosition = 0
		return TRUE
	End Function


	'reset to start role when entering
	Function onEnterRoom:int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetData().get("figure"))
		if not figure then return FALSE

		fadeTimer.Reset()
		changeRoleTimer.Reset()
		currentRolePosition = 0
		currentCastPosition = 0
		fadeMode = 0
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		SetAlpha fadeValue

		local fontRole:TBitmapFont = GetBitmapFont("Default",28, BOLDFONT)
		local fontCast:TBitmapFont = GetBitmapFont("Default",20, BOLDFONT)
		if not fadeRole then SetAlpha 1.0
		fontRole.DrawBlock(GetRole().name.ToUpper(), 20,180, GetGraphicsManager().GetWidth() - 40, 40, new TVec2D.Init(ALIGN_CENTER), GetRole().color, 2, 1, 0.6)
		SetAlpha fadeValue
		if GetCast() then fontCast.DrawBlock(GetCast(), 150,210, GetGraphicsManager().GetWidth() - 300, 80, new TVec2D.Init(ALIGN_CENTER), TColor.CreateGrey(230), 2, 1, 0.6)

		SetAlpha 1.0
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		if fadeTimer.isExpired() and fadeMode < 2
			fadeMode:+1
			fadeTimer.Reset()

			'gets "true" if the role is changed again
			fadeRole = FALSE
			'fade if last cast is fading out
			if not GetCast(+1) then fadeRole = true

			if fadeMode = 0 then fadeValue = 0.0
			if fadeMode = 1 then fadeValue = 1.0
			if fadeMode = 2 then fadeValue = 1.0
		endif
		if changeRoleTimer.isExpired()
			'if there is no new cast...next role pls
			if not NextCast() then NextRole()
			changeRoleTimer.Reset()
			fadeTimer.Reset()
			fadeMode = 0 'next fadein
		endif

		'linear fadein
		fadeValue = fadeTimer.GetTimeGoneInPercents()
		if fadeMode = 0 then fadeValue = fadeValue
		if fadeMode = 1 then fadeValue = 1.0
		if fadeMode = 2 then fadeValue = 1.0 - fadeValue
	End Function
End Type


'signs used in elevator-plan /room-plan
Type TRoomDoorSign Extends TBlockMoveable
	Field door:TRoomDoor
	Field signSlot:int = 0
	Field signFloor:int = 0
	Field imageCache:TSprite = null
	Field imageDraggedCache:TSprite	= null

	Global DragAndDropList:TList = CreateList()
	Global List:TList = CreateList()
	Global AdditionallyDragged:Int = 0
	Global eventsRegistered:Int = FALSE

	Global imageBaseName:string = "gfx_elevator_sign_"
	Global imageDraggedBaseName:string = "gfx_elevator_sign_dragged_"


	Method Init:TRoomDoorSign(roomDoor:TRoomDoor, signSlot:Int=0, signFloor:Int=0)
		local tmpImage:TSprite = GetSpriteFromRegistry(imageBaseName + Max(0, roomDoor.room.owner))
		door = roomDoor
		dragable = 1

		self.signFloor = signFloor
		self.signSlot = signSlot

		Local y:Int = GetFloorY(signFloor)
		local x:Int = GetSlotX(signSlot)

		OrigPos = new TVec2D.Init(x, y)
		StartPos = new TVec2D.Init(x, y)
		rect = new TRectangle.Init(x, y, tmpImage.area.GetW(), tmpImage.area.GetH() - 1)

		List.AddLast(self)
		SortList List

		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 		DragAndDrop.slot = CountList(List) - 1
 		DragAndDrop.pos.setXY(x,y)
 		DragAndDrop.w = rect.GetW()
 		DragAndDrop.h = rect.GetH()

		DragAndDropList.AddLast(DragAndDrop)
 		SortList(DragAndDropList)

		'===== REGISTER EVENTS =====
		if not eventsRegistered
			'handle savegame loading (remove old gui elements)
			EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
			EventManager.registerListenerFunction("Language.onSetLanguage", onSetLanguage)
			eventsRegistered = TRUE
		endif

		Return self
	End Method


	Function GetFloorY:int(signFloor:int)
		return 41 + (13 - signFloor) * 23
	End Function


	Function GetFloor:int(signY:int)
		return 13 - ((signY - 41) / 23)
	End Function


	Function GetSlotX:int(signSlot:int)
		select signSlot
			case 1	return 26
			case 2	return 208
			case 3	return 417
			case 4	return 599
			default Throw "TRoomDoorSign.GetSlotX(): invalid signSlot "+signSlot
		end select
		return 0
	End Function


	Function GetSlot:int(signX:int)
		select signX
			case 26		return 1
			case 208	return 2
			case 417	return 3
			case 599	return 4
			default Throw "TRoomDoorSign.GetSlot(): invalid signX "+signX
		end select
		return 0
	End Function


	Function GetFirstByRoom:TRoomDoorSign(room:TRoom)
		For local sign:TRoomDoorSign = eachin list
			if not sign.door then continue
			if not sign.door.room then continue

			if sign.door.room = room then return sign
		Next
		return Null
	End Function


	'return the sign originally at the given position
	Function GetByOriginalPosition:TRoomDoorSign(signSlot:int, signFloor:int)
		For local sign:TRoomDoorSign = eachin list
			if sign.signSlot = signSlot and sign.signFloor = signFloor
				return sign
			endif
		Next
		return Null
	End Function


	'return the sign now at the given position
	Function GetByCurrentPosition:TRoomDoorSign(signSlot:int, signFloor:int)
		For local sign:TRoomDoorSign = eachin list
			if sign.GetSlot(sign.rect.GetX()) = signSlot and sign.GetFloor(sign.rect.GetY()) = signFloor
				return sign
			endif
		Next
		return Null
	End Function
	

	'as soon as a language changes, remove the cached images
	'to get them regenerated
	Function onSetLanguage(triggerEvent:TEventBase)
		For Local obj:TRoomDoorSign = EachIn list
			obj.imageCache = null
			obj.imageDraggedCache = null
		Next
	End Function


	'as soon as a savegame gets loaded, we remove the cached images
	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		ResetImageCaches()
	End Function


	Function ResetImageCaches:int()
		For Local obj:TRoomDoorSign = EachIn list
			obj.imageCache = null
			obj.imageDraggedCache = null
		Next
	End Function


	Function ResetPositions()
		For Local obj:TRoomDoorSign = EachIn list
			obj.rect.position.CopyFrom(obj.OrigPos)
			obj.StartPos.CopyFrom(obj.OrigPos)
			obj.dragged	= 0
		Next
		TRoomDoorSign.AdditionallyDragged = 0
	End Function


	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method


	Method Compare:Int(otherObject:Object)
	   Local s:TRoomDoorSign = TRoomDoorSign(otherObject)
	   If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
	   Return (dragged * 100)-(s.dragged * 100)
	End Method

rem unused
	Method GetSlotOfBlock:Int()
		If rect.GetX() = 589 then Return 12+(Int(Floor(StartPos.y - 17) / 30))
		If rect.GetX() = 262 then Return 1*(Int(Floor(StartPos.y - 17) / 30))
		Return -1
	End Method
endrem

	'draw the Block inclusive text
	'zeichnet den Block inklusive Text
	Method Draw()
		SetColor 255,255,255;dragable=1  'normal

		If dragged = 1
			If AdditionallyDragged > 0 Then SetAlpha 1- 1/AdditionallyDragged * 0.25
			'refresh cache if needed
			If not imageDraggedCache
				imageDraggedCache = GenerateCacheImage( GetSpriteFromRegistry(imageDraggedBaseName + Max(0, door.room.owner)) )
			Endif
			imageDraggedCache.Draw(rect.GetX(),rect.GetY())
		Else
			'refresh cache if needed
			If not imageCache
				imageCache = GenerateCacheImage( GetSpriteFromRegistry(imageBaseName + Max(0, door.room.owner)) )
			Endif
			imageCache.Draw(rect.GetX(),rect.GetY())
		EndIf
		SetAlpha 1
	End Method


	'generates an image containing background + text on it
	Method GenerateCacheImage:TSprite(background:TSprite)
		local newImage:Timage = background.GetImageCopy()
		Local font:TBitmapFont = GetBitmapFont("Default",9, BOLDFONT)
		TBitmapFont.setRenderTarget(newImage)
		if door.room.owner > 0
			font.drawBlock(door.room.GetDescription(1), 22, 4, 150,15, null, TColor.CreateGrey(230), 2, 1, 0.5)
		else
			font.drawBlock(door.room.GetDescription(1), 22, 4, 150,15, null, TColor.CreateGrey(50), 2, 1, 0.3)
		endif
		TBitmapFont.setRenderTarget(null)

		return new TSprite.InitFromImage(newImage, "tempCacheImage")
	End Method


	Function UpdateAll(DraggingAllowed:int)
		'reset additional dragged objects
		AdditionallyDragged = 0
		'sort blocklist
		SortList(List)
		'reorder: first are dragged obj then not dragged
		ReverseList(list)

		For Local locObj:TRoomDoorSign = EachIn List
			If not locObj then continue

			If locObj.dragged
				If locObj.StartPosBackup.y = 0
					LocObj.StartPosBackup.CopyFrom(LocObj.StartPos)
				EndIf
			EndIf
			'block is dragable
			If DraggingAllowed And locObj.dragable
				'if right mbutton clicked and block dragged: reset coord of block
				If MOUSEMANAGER.IsHit(2) And locObj.dragged
					locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
					locObj.dragged = False
					MOUSEMANAGER.resetKey(2)
				EndIf

				'if left mbutton clicked: drop, replace with underlaying block...
				If MouseManager.IsHit(1)
					'search for underlaying block (we have a block dragged already)
					If locObj.dragged
						'obj over old position - drop ?
						If THelper.IsIn(MouseManager.x,MouseManager.y,LocObj.StartPosBackup.x,locobj.StartPosBackup.y,locobj.rect.GetW(),locobj.rect.GetH())
							locObj.dragged = False
						EndIf

						'want to drop in origin-position
						If locObj.containsCoord(MouseManager.x, MouseManager.y)
							locObj.dragged = False
							MouseManager.resetKey(1)
						'not dropping on origin: search for other underlaying obj
						Else
							For Local OtherLocObj:TRoomDoorSign = EachIn TRoomDoorSign.List
								If not OtherLocObj then continue
								If OtherLocObj.containsCoord(MouseManager.x, MouseManager.y) And OtherLocObj <> locObj And OtherLocObj.dragged = False And OtherLocObj.dragable
'											If game.networkgame Then
'												Network.SendMovieAgencyChange(Network.NET_SWITCH, GetPlayerCollection().playerID, OtherlocObj.Programme.id, -1, locObj.Programme)
'			  								End If
									locObj.SwitchBlock(otherLocObj)
									MouseManager.resetKey(1)
									Exit	'exit enclosing for-loop (stop searching for other underlaying blocks)
								EndIf
							Next
						EndIf		'end: drop in origin or search for other obj underlaying
					Else			'end: an obj is dragged
						If LocObj.containsCoord(MouseManager.x, MouseManager.y)
							locObj.dragged = 1
							MouseManager.resetKey(1)
						EndIf
					EndIf
				EndIf 				'end: left mbutton clicked
			EndIf					'end: dragable block and player or movieagency is owner

			'if obj dragged then coords to mousecursor+displacement, else to startcoords
			If locObj.dragged = 1
				TRoomDoorSign.AdditionallyDragged :+1
				Local displacement:Int = AdditionallyDragged *5
				locObj.setCoords(MouseManager.x - locObj.rect.GetW()/2 - displacement, 11+ MouseManager.y - locObj.rect.GetH()/2 - displacement)
			Else
				locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
			EndIf
		Next
		ReverseList list 'reorder: first are not dragged obj
	End Function


	Function DrawAll()
		SortList List
		'draw background sprites
		For Local sign:TRoomDoorSign = EachIn List
			GetSpriteFromRegistry("gfx_elevator_sign_bg").Draw(sign.OrigPos.x + 20, sign.OrigPos.y + 6)
		Next
		'draw actual sign
		For Local sign:TRoomDoorSign = EachIn List
			sign.Draw()
		Next
	End Function
End Type


Function Init_CreateAllRooms()
	local room:TRoom = null
	Local roomMap:TMap = TMap(GetRegistry().Get("rooms"))
	if not roomMap then Throw("ERROR: no room definition loaded!")

	For Local vars:TData = EachIn roomMap.Values()
		'==== SCREEN ====
		local screen:TInGameScreen_Room = TInGameScreen_Room(ScreenCollection.GetScreen(vars.GetString("screen") ))


		'==== ROOM ====
		local room:TRoom = new TRoom
		room.Init(..
			vars.GetString("roomname"),  ..
			[ ..
				vars.GetString("tooltip"), ..
				vars.GetString("tooltip2") ..
			], ..
			vars.GetInt("owner",-1),  ..
			vars.GetInt("size", 1)  ..
		)
		room.AssignToScreen(screen)
		room.fakeRoom = vars.GetBool("fake", FALSE)


		'==== DOOR ====
		local door:TRoomDoor = new TRoomDoor
		door.Init(..
			room,..
			vars.GetInt("doorslot"), ..
			vars.GetInt("x"), ..
			vars.GetInt("floor"), ..
			vars.GetInt("doortype") ..
		)
		if vars.GetInt("doorwidth") > 0
			door.area.dimension.setX( vars.GetInt("doorwidth") )
		endif

		'==== HOTSPOTS ====
		local hotSpots:TList = TList( vars.Get("hotspots") )
		if hotSpots
			for local conf:TData = eachin hotSpots
				local name:string 	= conf.GetString("name")
				local x:int			= conf.GetInt("x", -1)
				local y:int			= conf.GetInt("y", -1)
				local bottomy:int	= conf.GetInt("bottomy", 0)
				local floor:int 	= conf.GetInt("floor", -1)
				local width:int 	= conf.GetInt("width", 0)
				local height:int 	= conf.GetInt("height", 0)
				local tooltipText:string	 	= conf.GetString("tooltiptext")
				local tooltipDescription:string	= conf.GetString("tooltipdescription")

				'align at bottom of floor
				if floor >= 0 then y = TBuilding.GetFloorY(floor) - height

				local hotspot:THotspot = new THotspot.Create( name, x, y - bottomy, width, height)
				hotspot.setTooltipText( GetLocale(tooltipText), GetLocale(tooltipDescription) )
				room.addHotspot( hotspot )
			next
		endif

	Next

	'connect Update/Draw-Events
	RoomHandler_Office.Init()
	RoomHandler_News.Init()
	RoomHandler_Chief.Init()
	RoomHandler_Archive.Init()

	RoomHandler_AdAgency.GetInstance().Init()
	RoomHandler_MovieAgency.GetInstance().Init()
	RoomHandler_RoomAgency.Init()

	RoomHandler_Betty.Init()

	RoomHandler_ElevatorPlan.Init()
	RoomHandler_Roomboard.Init()

	RoomHandler_Credits.Init()
End Function

