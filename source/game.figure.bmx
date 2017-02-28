SuperStrict
Import "game.gameobject.bmx"
Import "game.game.base.bmx"
Import "game.figure.base.bmx"
Import "game.figure.base.sfx.bmx"
Import "game.building.elevator.bmx"
Import "game.room.bmx"
Import "game.room.roomdoor.bmx"



Type TFigureCollection extends TFigureBaseCollection
	'custom eventsregistered variable - because we listen to more events
	Global _eventsRegistered:int= FALSE


	Method New()
		if not _eventsRegistered
			'...

			_eventsRegistered = TRUE
		Endif
	End Method


	'override - create a FigureCollection instead of FigureBaseCollection
	Function GetInstance:TFigureCollection()
		if not _instance
			_instance = new TFigureCollection

		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		'==== ATTENTION =====
		'NEVER store _instance somewhere without paying attention
		'to this "whacky hack"
		elseif not TFigureCollection(_instance)
			local collection:TFigureCollection = new TFigureCollection
			collection.entries = _instance.entries
			collection.entriesCount = _instance.entriesCount
			'collection.lastFigureID = _instance.lastFigureID
			'now the new collection is the instance
			_instance = collection
		endif
		return TFigureCollection(_instance)
	End Function


	Method Get:TFigure(figureID:int)
		Return TFigure(Super.Get(figureID))
	End Method


	Method GetByName:TFigure(name:string)
		Return TFigure(Super.GetByName(name))
	End Method


	Method GetByGUID:TFigure(guid:string)
		Return TFigure(Super.GetByGUID(guid))
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetFigureCollection:TFigureCollection()
	Return TFigureCollection.GetInstance()
End Function





'all kind of characters walking through the building
'(players, terrorists and so on)
Type TFigure extends TFigureBase
	Field fadeOnChangingRoom:int = False
	
	'the door used (there might be multiple)
	Field usedDoor:TRoomDoorBase = Null
	'coming from room
	Field fromRoom:TRoomBase = Null
	'going to room
	Field inRoom:TRoomBase = Null

	'network sync position timer
	Field SyncTimer:TIntervalTimer = TIntervalTimer.Create(2500)

	Field _soundSource:TSoundSourceElement {nosave}
	'use the building coordinates or is the area absolute positioned?
	Field useAbsolutePosition:int = FALSE


	Method Create:TFigure(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		'adjust sprite animations

		SetSprite(sprite)
		GetFrameAnimations().Set(TSpriteFrameAnimation.Create("default", [ [8,1000] ], -1, 0 ) )
		GetFrameAnimations().Set(TSpriteFrameAnimation.Create("walkRight", [ [0,130], [1,130], [2,130], [3,130] ], -1, 0) )
		GetFrameAnimations().Set(TSpriteFrameAnimation.Create("walkLeft", [ [4,130], [5,130], [6,130], [7,130] ], -1, 0) )
		GetFrameAnimations().Set(TSpriteFrameAnimation.Create("standFront", [ [8,2500], [9,250] ], -1, 0, 500) )
		GetFrameAnimations().Set(TSpriteFrameAnimation.Create("standBack", [ [10,1000] ], -1, 0 ) )

		name = Figurename
		area = new TRectangle.Init(x, TBuildingBase.GetFloorY2(onFloor), sprite.framew, sprite.frameh )
		velocity.SetX(0)
		initialdx = abs(speed)

		GetFigureCollection().Add(self)

		'self.figureID = GetFigureCollection().GenerateID()

		if not _initdone
			_initDone = TRUE
		endif

		Return Self
	End Method


	Method GetSoundSource:TSoundSourceElement()
		if not _soundSource then _soundSource = TFigureBaseSoundSource.Create(Self)
		return _soundSource
	End Method


	'override to add room-support
	Method onLoad:int()
		Super.onLoad()

		'reassign rooms
		if inRoom then inRoom = GetRoomCollection().Get(inRoom.id)
		if usedDoor then usedDoor = GetRoomDoorBaseCollection().Get(usedDoor.id)
		For local target:object = EachIn figureTargets
			if TRoomDoorBase(target) then target = GetRoomDoorBaseCollection().Get(TRoomDoorBase(target).id)
		Next
		'set as room occupier again (so rooms occupant list gets refilled)
		if inRoom and not inRoom.isOccupant(self)
			inRoom.addOccupant(Self)
		endif

		'convert old targets
		for local target:object = eachin targets
			SetTarget( new TFigureTarget.Init(target) )
		Next
		'reset - so they are no longer in new savegames (ready to get
		'deleted later on)
		targets = null
	End Method


	Method onGameStart:int()
		'would bug out in multiplayer games as states are only
		'locally adjusted
		rem
		're-start leavin/entering actions
		if currentAction = ACTION_ENTERING
			'SetInRoom(null)
			'BeginEnterRoom(usedDoor, inRoom)
		elseif currentAction = ACTION_LEAVING
			'SetInRoom(inRoom)
			'BeginLeaveRoom()
		endif
		endrem
	End Method


	Method onReachTarget:int()
		'stub
	End Method


	Method onReachElevator:int()
		'stub
	End Method


	Method HasToChangeFloor:Int()
		if not GetTarget() then return FALSE
		Return GetFloor( GetTargetMoveToPosition() ) <> GetFloor()
	End Method


	Method GetFloor:Int(pos:TVec2D = Null)
		'if we have no floor set in the pos, we return the current floor
		If not pos Then pos = area.position
		Return GetBuildingBase().getFloor(pos.y)
	End Method


	Method IsOnFloor:Int()
		Return area.GetY() = TBuildingBase.GetFloorY2(GetFloor())
	End Method


	'ignores y
	Method IsAtElevator:int()
		Return GetElevator().IsFigureInFrontOfDoor(Self)
	End Method


	Method IsInElevator:int()
		Return GetElevator().HasPassenger(Self)
	End Method


	'override to add building/room support
	Method IsIdling:int()
		if not Super.IsIdling() then return False
		
		If not IsInBuilding() then return False

		return True
	End Method


	'override to wait when reaching a target door/hotspot
	Method customReachTargetStep1:Int()
		local targetObject:object = GetTargetObject()  
		'start waiting in front of the target
		If TRoomDoorBase(targetObject) or THotspot(targetObject)
			WaitEnterTimer = GetBuildingTime().GetMillisecondsGone() + WaitEnterLeavingTime
		Else
			Super.customReachTargetStep1()
		EndIf
	End Method


	'override to 
	Method TargetNeedsToGetEntered:int()
		local targetObject:object = GetTargetObject()  

		if TRoomDoorBase(targetObject) then return True
		'if hotspot, ask it whether enter is wanted
		if THotSpot(targetObject) then return THotSpot(targetObject).IsEnterable()

		return Super.TargetNeedsToGetEntered()
	End Method


	Method IsInFrontOfTarget:int()
		if not HasToChangeFloor() and GetTarget()
			'get target coordinate
			Local targetX:Int = GetTargetMoveToPosition().getIntX()

			'we stand in front of the target -> reach target!
			if GetVelocity().GetX() = 0 and abs(area.getX() - targetX) < 1.0
				return True
			endif
		endif
		return False
	End Method


	Method FigureMovement:int()
		'stop movement, will get set to a value if we have a target to move to
		velocity.setX(0)

		'we have a target to move to and are not yet entering it
		'check if we reach it now
		if GetTarget() and currentReachTargetStep = 0
			'does the center of the figure will reach the target during update?
			'can happen even when not able to move (manual position set
			'or target acquired without moving)
			local reachTemporaryTarget:int = FALSE
			'get a temporary target coordinate so we can manipulate that safely
			Local targetX:Int = GetTargetMoveToPosition().getIntX()
			'do we have to change the floor?
			'if that is the case - change temporary target to elevator
			If HasToChangeFloor() Then targetX = GetElevator().GetDoorCenterX()

			'we stand in front of the target -> reach target!
			if GetVelocity().GetX() = 0 and abs(area.getX() - targetX) < 1.0 then reachTemporaryTarget=true

			'if able to move, check if the movement will lead to reaching
			'the target
			if CanMove()
				'check whether the target is left or right side of the figure
				If targetX < area.GetX()
					velocity.SetX( -(Abs(initialdx)))
				ElseIf targetX > area.GetX()
					velocity.SetX(  (Abs(initialdx)))
				EndIf

				local dx:float = GetVelocity().GetX() * GetDeltaTime()
				'move to right and next step is more right than target
				if dx > 0 and ceil(area.getX() + dx) >= targetX then reachTemporaryTarget=true
				'move to left and next step is more left than target
				if dx < 0 and ceil(area.getX() + dx) <= targetX then reachTemporaryTarget=true
			endif

			'we reached our current target (temp or real)
			If reachTemporaryTarget
				'stop moving
				velocity.SetX(0)

				'we reached our real target
				if not HasToChangeFloor()
					'you can only reach target when not a passenger of
					'the elevator - this avoids going into the elevator
					'plan without really leaving the elevator
					If not IsInElevator()
						ReachTargetStep1()
					endif

					if not reachedTemporaryTarget then onReachTarget()
				else
					'set to elevator-targetx
					oldPosition.setX(targetX) 'set tween position too
					area.position.setX(targetX)

					if not reachedTemporaryTarget then onReachElevator()
				endif

				reachedTemporaryTarget = True
			endif
		endif

		'we have a target and are in this moment entering it
		if GetTarget() and currentReachTargetStep = 1 'and not isChangingRoom()
			if not TargetNeedsToGetEntered()
				'aendert currentReachTargetStep auf 0
				ReachTargetStep2()
			else

				'if waitingtime is over, start going-into-animation (takes
				'some time too -> FinishEnterRoom is called when that is
				'finished too)
				'CanEnterTarget also checks for "IsWaitingToEnter()"
				if not IsWaitingToEnter() and CanEnterTarget() 'and currentAction = ACTION_IDLE  
					WaitEnterTimer = -1
					if not EnterTarget() then print "Enter target failed. Figure: " + name
				endif
			endif
		endif


		'decide if we have to play sound
		if GetVelocity().getX() <> 0 and not IsInElevator() and not GetBuildingTime().TooFastForSound()
			GetSoundSource().PlayOrContinueRandomSFX("steps")
		else
			GetSoundSource().Stop("steps")
		EndIf


		'adjust/limit position based on location
		If Not IsInElevator()
			If Not IsOnFloor() and not useAbsolutePosition Then area.position.setY( TBuildingBase.GetFloorY2(GetFloor()) )
		EndIf

		'limit player position (only within floor 13 and floor 0 allowed)
		if not useAbsolutePosition
			'beim Vergleich oben nicht "self.sprite.area.GetH()" abziehen... das war falsch und f�hrt zum Ruckeln im obersten Stock
			If area.GetY() < TBuildingBase.GetFloorY2(13) Then area.position.setY( TBuildingBase.GetFloorY2(13) )
			If area.GetY() - sprite.area.GetH() > TBuildingBase.GetFloorY2(0) Then area.position.setY( TBuildingBase.GetFloorY2(0) )
		endif

		return true
	End Method


	'overwrite default to add stoppers (at elevator)
	Method GetVelocity:TVec2D()
		if IsInElevator() then return new TVec2D
		return velocity
	End Method


	'returns what animation has to get played in that moment
	Method GetAnimationToUse:string()
		'fetch the animation for walking and standing
		local result:string = Super.GetAnimationToUse()

		'check for special animations
		If GetVelocity().GetX() = 0 or not moveable
			'boarding/deboarding movement
			If boardingState <> 0
				'default (when not walking to your elevator position)
				result = "standFront"
				'multiply boardingState : if boarding it is 1, if deboarding it is -1
				'so multiplying negates value if needed
				If boardingState * PosOffset.GetX() > 0 Then result = "walkRight"
				If boardingState * PosOffset.GetX() < 0 Then result = "walkLeft"
			EndIf

			'show the backside if at elevator to change floor
			If hasToChangeFloor() And Not IsInElevator() And IsAtElevator()
				result = "standBack"
			'not moving but wants to go to somewhere (also show back if
			'room is used and enter not possible "for now".
			ElseIf currentAction = ACTION_ENTERING or IsInFrontOfTarget()
				result = "standBack"
			'in a room (or standing in front of a fake room - looking at plan)
			ElseIf inRoom and inRoom.ShowsOccupants()
				result = "standBack"
			EndIf
		EndIf

		return result
	End Method


	Method GetGreetingTypeForFigure:int(figure:TFigure)
		'0 = grrLeft
		'1 = hiLeft
		'2 = ?!left

		'if both figures are "players" we display "GRRR" or "?!!?"
		If figure.playerID and playerID
			'depending on floor use "grr" or "?!"
			return 0 + 2*((1 + GetBuildingBase().GetFloor(area.GetY()) mod 2)-1)
		'display "hi"
		else
			return 1
		endif
	End Method


	Method GreetPeopleOnSameFloor()
		For Local Figure:TFigure = EachIn GetFigureCollection().entries.Values()
			'skip other figures
			if self = Figure then continue
			'skip if both can't see each other to me
			if not CanSeeFigure(figure) and not figure.CanSeeFigure(self) then continue


			local greetType:int = GetGreetingTypeForFigure(figure)

			'if the greeting type differs
			'- or enough time has gone for another greet
			'- or another figure gets greeted
			if greetType <> lastGreetType or GetBuildingTime().GetMillisecondsGone() - lastGreetTime > greetEvery or lastGreetFigureID <> figure.id
				lastGreetType = greetType
				lastGreetFigureID = figure.id

				lastGreetTime = GetBuildingTime().GetMillisecondsGone()
			endif

			'show greet for a maximum time of "showGreetTime"
			if GetBuildingTime().GetMillisecondsGone() - lastGreetTime < greetTime
				local scale:float = TInterpolation.BackOut(0.0, 1.0, Min(greetTime, GetBuildingTime().GetMillisecondsGone() - lastGreetTime), greetTime)
				local oldAlpha:float = GetAlpha()
				SetAlpha Float(TInterpolation.RegularOut(0.5, 1.0, Min(0.5*greetTime, GetBuildingTime().GetMillisecondsGone() - lastGreetTime), 0.5*greetTime))
				'subtract half width from position - figure is drawn centered
				'figure right of me
				If Figure.area.GetX() > area.GetX()
					'draw the "to the right" balloon a bit lower (so both are better visible)
					GetSpriteFromRegistry("gfx_building_textballons").Draw(int(GetScreenX() + area.GetW()/2 -2), int(GetScreenY() - sprite.area.GetH() + 2), greetType, ALIGN_LEFT_CENTER, scale)
				'figure left of me
				else
					greetType :+ 3
					GetSpriteFromRegistry("gfx_building_textballons").Draw(int(GetScreenX() - area.GetW()/2 +2), int(GetScreenY() - sprite.area.GetH()), greetType, ALIGN_RIGHT_CENTER, scale)
				endif
				SetAlpha oldAlpha
			endif
		Next
	End Method

	'a room is locked for all figures except they have the masterKey
	'(or are non-player figures)
	Method HasKeyForRoom:int(room:TRoomBase)
		if hasMasterKey then return True
		if not playerID then return True

		'players can visit bosses of other channels
		if room.name = "boss" then return True

		'players can visit non-player-rooms
		if not room.owner then return True

		'else they can only visit if they are owner
		return playerID = room.owner
	End Method


	'override to take rooms into consideration
	Method IsVisible:int()
		'in a fake room?
		if inRoom and inRoom.ShowsOccupants() then return True
		
		return (IsInBuilding() or isChangingRoom())
	End Method


	Method IsChangingRoom:int()
		return currentAction = ACTION_ENTERING or currentAction = ACTION_LEAVING
	End Method


	Method IsEnteringRoom:int()
		return currentAction = ACTION_ENTERING
	End Method


	Method IsLeavingRoom:int()
		return currentAction = ACTION_LEAVING
	End Method



	'override to add room support
	Method IsInBuilding:int()
		If IsChangingRoom() Then Return False
		If isInRoom() Then Return False
		Return True
	End Method


	'override to add support for rooms
	Method IsInRoom:Int(roomName:String="")
		If roomName <> ""
			Return (inRoom And inRoom.Name.toLower() = roomname.toLower())
		Else
			Return inRoom <> null
		EndIf
	End Method


	'override
	Method GetInRoomID:Int()
		if inRoom then return inRoom.id

		return Super.GetInRoomID()
	End Method


	Method GetInRoom:object()
		return inRoom
	End Method


	Method GetUsedDoorID:Int()
		if usedDoor then return usedDoor.id

		return Super.GetUsedDoorID()
	End Method


	Method GetUsedDoor:object()
		return usedDoor
	End Method


	'override to add buildingsupport
	Method CanMove:int()
		If not IsInBuilding() then return False

		return Super.CanMove()
	End Method


	'player is now in room "room"
	Method SetInRoom:Int(room:TRoomBase)
		If room and not room.IsOccupant(self) then room.addOccupant(Self)

		'backup old room as origin
		fromRoom = inRoom

		'set new room
	 	inRoom = room

		'inform others that room is changed
		EventManager.triggerEvent( TEventSimple.Create("figure.SetInRoom", null, self, inroom) )
	End Method


	'override
	Method KickOutOfRoom:Int(kickingFigure:TFigureBase=null)
		If not GetInRoom() Then Return False
		'self kick?
		If self = kickingFigure then return FALSE

		'fetch at least the main door if none is provided
		local door:TRoomDoorBase = usedDoor
		if not door and inRoom then door = GetRoomDoorCollection().GetMainDoorToRoom(inRoom.id)

		if kickingFigure
			TLogger.log("TFigure.KickFigureOutOfRoom()", kickingFigure.name+" kicks "+ name + " out of room: "+inRoom.name, LOG_DEBUG)
		else
			TLogger.log("TFigure.KickFigureOutOfRoom()", name + " gets kicked out of room: "+inRoom.name, LOG_DEBUG)
		endif
		'instead of SimpleSoundSource we use the rooms sound source
		'so we are able to have positioned sound
		if TRoomDoor(door)
			TRoomDoor(door).GetSoundSource().PlayRandomSFX("kick_figure", TRoomDoor(door).GetSoundSource().GetPlayerBeforeDoorSettings())
		endif

		'maybe someone is interested in this information
		EventManager.triggerEvent( TEventSimple.Create("room.kickFigure", new TData.Add("figure", self).Add("door", door), GetInRoom() ) )

		LeaveRoom(True)
		Return True
	End Method


	'overridden to add support for roombase and roomdoorbase
	Method EnterLocation:Int(obj:object, forceEnter:int=False)
		if TRoomDoor(obj) then EnterRoom( TRoomDoor(obj),null, forceEnter )
		if TRoomBase(obj) then EnterRoom( null, TRoomBase(obj), forceEnter )
	End Method


	'figure wants to enter a room
	'"onEnterRoom" is called when successful
	'@param door         door to use
	'@param room         room to enter (in case no door exists)
	'@param forceEnter   kick without being the room owner
	Method EnterRoom:Int(door:TRoomDoorBase, room:TRoomBase, forceEnter:int=FALSE)
		'skip command if we already are entering/leaving
		if isChangingRoom() then return TRUE

		'assign room if not done yet
		if not room and door then room = GetRoomBaseCollection().Get(door.roomID)
		if room and not door then door = GetRoomDoorBaseCollection().GetFirstByRoomID(room.id)
		'need a room and a door
		if not room or not door then return False

		'figure is already in that room - so just enter
		if room.isOccupant(self) or inRoom = room then return TRUE

		'=== INFORM OTHERS ===
		'inform that figure now begins entering the room
		'(eg. for players informing the ai)
		EventManager.triggerEvent( TEventSimple.Create("figure.onEnterRoom", new TData.Add("room", room).Add("door", door) , self, room) )

		'Debug
		'print "--------------------------------------------"
		'print self.name+" ENTERING " + room.GetName() +" ["+room.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"

		'try to enter the room 
		if not TryEnterRoom(door, room, forceEnter)
			return False
		endif

		BeginEnterRoom(door, room)

		return True
	End Method


	Method TryEnterRoom:int(door:TRoomDoorBase, room:TRoomBase, forceEnter:int = False)

		'something (bomb, renovation, ...) does not allow access to this
		'room for now
		if room.IsBlocked()
			FailEnterRoom(room, door, "blocked")
			return FALSE
		endif


		'check if enter not possible
		if not CanEnterRoom(room) and not forceEnter
			'rooms of other players are locked, you need the master key or
			'you must be a non-player-figure ...
			if not HasKeyForRoom(room)
				FailEnterRoom(room, door, "locked")
				return FALSE
			endif

			'no key needed or having one... check if there is someone
			'in already (who is not kick-able)
			If room.hasOccupant() and not room.isOccupant(self)
				'only player-figures need such handling (events etc.)
				'all others just enter
				If playerID and not playerID = room.owner
					FailEnterRoom(room, door, "inuse")
					return FALSE
				EndIf
			EndIf
		endif

		'ask if somebody is against going into the room
		local event:TEventSimple = TEventSimple.Create("figure.onTryEnterRoom", new TData.Add("door", door) , self, room )
		EventManager.triggerEvent(event)
		'stop entering
		if event.IsVeto() then return False

		return True
	End Method


	Method BeginEnterRoom:int(door:TRoomDoorBase, room:TRoomBase)
		'set time of start
		changingRoomBuildingTimeStart = GetBuildingTime().GetMillisecondsGone()
		changingRoomBuildingTimeEnd = GetBuildingTime().GetMillisecondsGone() + changingRoomTime
		changingRoomRealTimeStart = Time.GetTimeGone()
		changingRoomRealTimeEnd = Time.GetTimeGone() + changingRoomTime
		'inform what the figure does now
		currentAction = ACTION_ENTERING

		'reset wait timer
		WaitEnterTimer = -1

		'Debug
		'print self.name+" START ENTERING " + room.GetName() +" ["+room.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"
	
		'do not fade when it is a fake room
		fadeOnChangingRoom = True
		if room.ShowsOccupants() then fadeOnChangingRoom = False
	
		'kick other figures from the room if figure is the owner 
		'only player-figures need such handling (events etc.)
		If playerID and playerID = room.owner and room.occupants.Count() > 0
			for local occupant:TFigure = eachin room.occupants.Copy()
				'only kick other players ?!
				if not occupant.playerID then continue
				if occupant <> self
					occupant.KickOutOfRoom(self)
					'Debug
					'print self.name+" KICKING " + occupant.name +" FROM "+ room.GetName() +" ["+room.id+"]"
				endif
			next
		EndIf

		'set figure already "inRoom" in that moment
		'(room adds occupant too on "BeginEnter")
		'print self.name+" SET IN ROOM  (" + Time.GetSystemTime("%H:%I:%S") +")"
		SetInRoom(room)

		'inform room
		room.BeginEnter(door, self, changingRoomTime)

		'=== INFORM OTHERS ===
		'inform that figure now begins entering the room
		'(eg. for players informing the ai)
		EventManager.triggerEvent(TEventSimple.Create("figure.onBeginEnterRoom", null, self, room))

		return True
	End Method


	Method FinishEnterRoom:Int()
		local door:TRoomDoorBase = TRoomDoorBase( GetTargetObject() )
		local room:TRoomBase
		'send to offscreen?
		if TVec2D( GetTargetObject() )
			print "Send To Offscreen while entering a door!!!"
		endif
		if door then room = GetRoomBaseCollection().Get(door.roomID)
		if door and not room then print "FinishEnterRoom : NO ROOM"

		'Debug
		rem
		local roomName:string = "UNKNOWN"
		if room
			roomName = room.name + " ["+room.id+"]"
		else
			if inRoom then roomName = inRoom.name+" [inRoom] ["+inRoom.id+"]"
		endif
		print self.name+" FINISH ENTERING " + roomName +"  (" + Time.GetSystemTime("%H:%I:%S") +")"
		'print "--------------------------------------------"
		endrem

		if not room then room = inRoom

		'backup the used door
		usedDoor = door

		'reset action
		currentAction = ACTION_IDLE

		changingRoomBuildingTimeStart = -1
		changingRoomRealTimeStart = -1

		'finish reaching-target-steps (and remove current target)
		'also this might add a new target (eg. via AI)
		ReachTargetStep2()

		'inform room
		if room then room.FinishEnter(self)


		'=== INFORM OTHERS ===
		local hasT:int = GetTarget() <> null
		'inform that figure now entered the room
		'(eg. for players informing the ai)
		EventManager.triggerEvent( TEventSimple.Create("figure.onFinishEnterRoom", new TData.Add("room", room).Add("door", door) , self, room) )

rem
'Ronny: "normally" this should not be needed at all
		'another target to do?
		if GetTarget()
			print "Figure "  + name + " got another target - going to it now " + hasT
			local targetPos:TVec2D = GetTargetMoveToPosition()
			'remove that target, so we can add it again
			RemoveCurrentTarget()
			ChangeTarget( int(targetPos.x), int(targetPos.y))
		endif
endrem

		return True
	End Method


	Method FailEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase, reason:String)
		'=== INFORM OTHERS ===
		'inform that figure failed to enter the room
		'(eg. for players informing the ai)
		EventManager.triggerEvent( TEventSimple.Create("figure.onFailEnterRoom", new TData.AddString("reason", reason).Add("door", door), self, room))

		'Debug
		'print self.name+" FAILED ENTERING " + room.GetName() +" ["+room.id+"]"

		'reset action
		currentAction = ACTION_IDLE

		'reset wait timer
		WaitEnterTimer = -1

		changingRoomBuildingTimeStart = -1
		changingRoomRealTimeStart = -1

		'stay in building
		SetInRoom(null)

		'finish reaching-target-steps (and remove current target)
		ReachTargetStep2()
	End Method


	Method CanEnterRoom:Int(room:TRoomBase)
		'cannot enter if room forbids
		'(exception are non-players)
		if not room.CanEntityEnter(self)
			if not room.IsBlocked() and not playerID
				return True
			endif

			return False
		endif

		'players must be owner of the room or needs a masterKey
		Return HasKeyForRoom(room)
	End Method 


	'command to leave a room - "onLeaveRoom" is called when successful
	Method LeaveRoom:Int(forceLeave:Int=False)
		'skip command if in no room or already leaving
		if not inRoom or IsLeavingRoom() then return True

		'=== INFORM OTHERS ===
		'inform that figure now begins leaving the room
		'(eg. for players informing the ai)
		EventManager.triggerEvent( TEventSimple.Create("figure.onLeaveRoom", null, self, inRoom ) )

		'Debug
		'print self.name+" LEAVING " + inRoom.GetName() +" ["+inRoom.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"

		'=== CHECK IF LEAVING IS ALLOWED ===
		'skip leaving if not allowed to do so
		if not forceLeave and not CanLeaveroom(inroom) then return False

		'ask if somebody is against leaving that room
		if not TryLeaveRoom( forceLeave )
			return False
		endif

		'inform that a figure forcefully leaves a room (so GUI or so can
		'get cleared)
		if forceLeave
			EventManager.triggerEvent(TEventSimple.Create("figure.onForcefullyLeaveRoom", new TData.Add("door", usedDoor) , self, inroom))
		endif

		BeginLeaveRoom()

		return True
	End Method


	Method TryLeaveRoom:int(forceLeave:int = False)
		'but ignore the result if figure is forced to leave
		local event:TEventSimple = TEventSimple.Create("figure.onTryLeaveRoom", new TData.Add("door", usedDoor) , self, inroom )
		EventManager.triggerEvent(event)
		'stop leaving
		if event.IsVeto() then return False

		return True
	End Method


	Method BeginLeaveRoom:int()
		'set time of start
		changingRoomBuildingTimeStart = GetBuildingTime().GetMillisecondsGone()
		changingRoomBuildingTimeEnd = GetBuildingTime().GetMillisecondsGone() + changingRoomTime
		changingRoomRealTimeStart = Time.GetTimeGone()
		changingRoomRealTimeEnd = Time.GetTimeGone() + changingRoomTime

		'inform what the figure does now
		currentAction = ACTION_LEAVING

		'Debug
		'print self.name+" START LEAVING " + inRoom.GetName() +" ["+inRoom.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"

		'do not fade when it is a fake room
		fadeOnChangingRoom = True
		if inRoom.ShowsOccupants() then fadeOnChangingRoom = False

		inRoom.BeginLeave(usedDoor, self, changingRoomTime)

		'=== INFORM OTHERS ===
		'inform that figure now leaves the room
		'(eg. for players informing the ai)
		EventManager.triggerEvent(TEventSimple.Create("figure.onBeginLeaveRoom", null, self, inroom))

		return True
	End Method


	'gets called when the figure really left the room
	Method FinishLeaveRoom()
		local inRoomBackup:TRoomBase = inRoom
		'Debug
		'print self.name+" FINISHED LEAVING " + inRoom.GetName() +" ["+inRoom.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"

		'enter target -> null = building
		SetInRoom( null )

		'remove used door
		usedDoor = null

		'reset action
		currentAction = ACTION_IDLE

		'activate timer to wait a bit after leaving a room
		WaitLeavingTimer = GetBuildingTime().GetMillisecondsGone() + WaitEnterLeavingTime

		inRoomBackup.FinishLeave(self)

		'=== INFORM OTHERS ===
		'inform that figure now leaves the room
		'(eg. for players informing the ai)
		EventManager.triggerEvent( TEventSimple.Create("figure.onFinishLeaveRoom", null, self, inRoomBackup ) )
	End Method


	Method CanLeaveRoom:Int(room:TRoomBase)
		'cannot leave if room forbids
		if not room.CanEntityLeave(self) then return False

		return True
	End Method


	Method SendToDoor:Int(door:TRoomDoorBase, forceSend:Int=False)
 		If not door then return False

		local moveToPos:TVec2D = GetMoveToPosition( new TFigureTarget.Init(door) )
		if not moveToPos
			print "SendToDoor: failed, moveToPos = null"
			return False
		endif
	
		If forceSend
			ForceChangeTarget(moveToPos.GetIntX(), moveToPos.GetIntY())
		Else
			ChangeTarget(moveToPos.GetIntX(), moveToPos.GetIntY())
		EndIf
	End Method


	'override
	'send a figure to the offscreen position
	Method SendToOffscreen:Int(forceSend:Int = False)
		if forceSend
			ForceChangeTarget(GetBuildingBase().figureOffscreenX, TBuildingBase.GetFloorY2(0) - 5)
		else
			ChangeTarget(GetBuildingBase().figureOffscreenX, TBuildingBase.GetFloorY2(0) - 5)
		endif
	End Method


	'override
	'instantly move a figure to the offscreen position
	Method MoveToOffscreen:Int()
		area.position.SetXY(GetBuildingBase().figureOffscreenX, TBuildingBase.GetFloorY2(0))
	End Method


	Method IsOffscreen:int()
		if GetFloor() = 0 and area.GetX() <= GetBuildingBase().figureOffscreenX then return True
		return False
	End Method


	Method GoToCoordinatesRelative:Int(relX:Int = 0, relYFloor:Int = 0)
		Local newX:Int = area.GetX() + relX
		Local newY:Int = GetBuildingBase().area.GetY() + TBuildingBase.GetFloorY2(GetFloor() + relYFloor) - 5

		newX = MathHelper.Clamp(newX, 10, GetBuildingBase().floorWidth - 10)

 		ChangeTarget(newX, newY)
	End Method


	Method CallElevator:Int()
		'ego nur ich selbst
		'if not self.parentPlayer or self.parentPlayer.playerID <> 1 then return false

		If IsElevatorCalled() Then Return False 'Wenn er bereits gerufen wurde, dann abbrechen

		'Wenn der Fahrstuhl schon da ist, dann auch abbrechen. TODOX: Muss ueberprueft werden
		If GetElevator().CurrentFloor = GetFloor() And IsAtElevator() Then Return False

		'Fahrstuhl darf man nur rufen, wenn man davor steht
		If IsAtElevator() Then GetElevator().CallElevator(Self)
	End Method


	Method GoOnBoardAndSendElevator:Int()
		if not GetTarget() then return FALSE
		If GetElevator().EnterTheElevator(Self, GetFloor(GetTargetMoveToPosition()))
			GetElevator().SendElevator(GetFloor(GetTargetMoveToPosition()), Self)
		EndIf
	End Method


	'overridden to add roomdoor/hotspot
	'returns the coordinate the figure has to walk to, to reach that
	'target
	Method GetTargetMoveToPosition:TVec2D()
		return GetMoveToPosition( GetTarget() )
	End Method


	Function GetMoveToPosition:TVec2D(target:TFigureTargetBase = null)
		if not target then return Null
		return target.GetMoveToPosition()
	End Function


	'overridden
	'change the target of the figure
	'@forceChange   defines wether the target could change target
	'               even when not controllable
	Method _ChangeTarget:Int(x:Int=-1, y:Int=-1, forceChange:Int=False)
		'reset target reach
		currentReachTargetStep = 0

		'is controlling allowed (eg. figure MUST go to a specific target)
		if not forceChange and not IsControllable() then Return False

		'if player is in elevator dont accept changes
		if not forceChange and IsInElevator() Then Return False

		reachedTemporaryTarget = False

		'=== CALCULATE NEW TARGET/TARGET-OBJECT ===
		local newTarget:object = Null
	
		'only a partial target was given
		if x=-1 or y=-1
			'change current target
			if TVec2D( GetTargetObject() )
				If x<>-1 Then x = TVec2D( GetTargetObject() ).x
				If y<>-1 Then y = TVec2D( GetTargetObject() ).y
			'create a new target
			else
				If x=-1 Then x = area.position.x
				If y=-1 Then y = area.position.y
			endif
		endif

		'y is not of floor 0 -13
		If GetBuildingBase().GetFloor(y) < 0 Or GetBuildingBase().GetFloor(y) > 13 Then Return False

		local newTargetCoord:TVec2D

		'set new target, y is recalculated to "basement"-y of that floor
		newTargetCoord = new TVec2D.Init(x, TBuildingBase.GetFloorY2(GetBuildingBase().GetFloor(y)) )
		newTarget = newTargetCoord

		'when targeting a room, set target to center of door
		local targetedDoor:TRoomDoorBase = TRoomDoor.GetByCoord(newTargetCoord.x, newTargetCoord.y)
		if targetedDoor
			newTarget = targetedDoor
			newTargetCoord = TFigureTarget.GetTargetMoveToPosition(targetedDoor)
		endif

		'limit target coordinates
		'on the base floor we can walk outside the building, so just
		'check right side
		'target.y contains the floorY so we use "y" which holds clicked
		'floor

		'TODO: do this in a GetLimitX() method to make it overrideable
		'      by bigger figures - like the the janitor
		local rightLimit:int = TBuildingBase.floorWidth-15 '603
		local leftLimit:int = 15 '200

		if GetBuildingBase().GetFloor(y) = 0
			If Floor(newTargetCoord.x) >= rightLimit Then newTargetCoord.X = rightLimit
		else
			If Floor(newTargetCoord.x) <= leftLimit Then newTargetCoord.X = leftLimit
			If Floor(newTargetCoord.x) >= rightLimit Then newTargetCoord.X = rightLimit
		endif

		local targetRoom:TRoomBase
		if TRoomDoor(newTarget) then targetRoom = TRoomDoor(newTarget).GetRoom() 


		'=== CHECK IF ALREADY THERE ===
		'check if figure is already at this target
		'RONNY: REALLY NEEDED? - bugs out AI in rooms (sometimes) as
		'       GetTarget() might return a new one already
		'if newTarget and newTarget = GetTarget() then return False
		'-> alternative: check coordinates

		if GetTargetObject()
			'new target and current target are the same
			if newTarget = GetTargetObject() then return False
			'new target and current target are at the same position?
			if newTargetCoord.IsSame( GetTargetMoveToPosition() ) then return False

			'print playerID+": targets are different " + newTargetCoord.getIntX()+","+newTargetCoord.getIntY()+" vs " + GetTargetMovetoPosition().GetIntX()+","+GetTargetMovetoPosition().getIntY() 
		endif
		'or if already in this room
		if targetRoom and targetRoom = inRoom then return False


		'=== NEW TARGET IS OK ===
		'(and differing to current one)
		rem
		local targetText:string = "unknown"
		if newTarget then targetText = TTypeId.ForObject(newTarget).name()
		if TRoomDoorBase(newTarget) then targetText = "RoomDoor (id="+TRoomDoorBase(newTarget).roomID+")"
		if TVec2D(newTarget) then targetText = "Building (x="+TVec2D(newTarget).GetIntX()+" floor=unk)"
		if playerID > 0 then print playerID+": _changeTarget = " + targetText+ "   "+ GetWorldTime().GetFormattedDate()
		endrem


		'=== SET NEW TARGET ===
		'if still in a room, but targetting something else ... leave first
		'this is needed as computer players do not "leave a room", they
		'just change targets
		If inRoom and targetRoom <> inRoom then LeaveRoom(forceChange)

		'new target - so go to it, remove other previously set targets
		if forceChange
			SetTarget( new TFigureTarget.Init(newTarget, 0, TFigureTargetBase.FIGURESTATE_UNCONTROLLABLE) )
		else
			SetTarget( new TFigureTarget.Init(newTarget) )
		endif

		'emit an event
		EventManager.triggerEvent( TEventSimple.Create("figure.onChangeTarget", new TData.AddNumber("x", x).AddNumber("y", y).AddNumber("forceChange", forceChange), self, null ) )

		return TRUE
	End Method


	Method IsElevatorCalled:Int()
		For Local floorRoute:TFloorRoute = EachIn GetElevator().FloorRouteList
			If floorRoute.who.id = Self.id
				Return True
			EndIf
		Next
		Return False
	End Method


	'override to add support for hotspots/rooms
	Method EnterTarget:Int()
		if not GetTarget() then return False

		'emit event
		if not Super.EnterTarget() then return False

		local targetDoor:TRoomDoor = TRoomDoor(GetTargetObject())
		if targetDoor
			'do not remove the target room as it is done during
			'"entering the room" (which can be animated and so we
			'just trust the method to do it)
			EnterLocation(targetDoor)
		EndIf

		return True
	End Method


	Method FixBrokenEnterLeavingStates()
		if currentAction = ACTION_ENTERING and not inRoom
			if WaitEnterTimer > 0 and WaitEnterTimer + 5000 < GetBuildingTime().GetMillisecondsGone()
				print "FIX: figure ~q"+name+"~q forcefully enter room again."

				currentReachTargetStep = 0
				currentAction = ACTION_IDLE
				if TRoomDoorBase(GetTargetObject())
					local door:TRoomDoorBase = TRoomDoorBase(GetTargetObject())
					local room:TRoomBase = GetRoomBaseCollection().Get(door.roomID)
					room.RemoveOccupant(self)
				endif
				
'				FinishEnterRoom( inRoom )
			endif
		endif

rem
		'we have a target and are in this moment entering it
		if GetTarget() and currentReachTargetStep = 1 'and not isChangingRoom()
			if TargetNeedsToGetEntered()
				'if waitingtime is over, start going-into-animation (takes
				'some time too -> FinishEnterRoom is called when that is
				'finished too)
				'CanEnterTarget also checks for "IsWaitingToEnter()"
				if not IsWaitingToEnter() and CanEnterTarget()
					'TODO: find reason for the need of the following fix
					'      (Ronny: I assume it happens when saving while
					'       a figure enters a room)
					'fix broken savegames
					if WaitEnterTimer > 0 and GetBuildingTime().GetMillisecondsGone() > WaitEnterTimer + WaitEnterLeavingTime + 100 and GetBuildingTime().GetTimeFactor() < 100
						print "FIX ENTER state for figure ~q"+name+"~q (playerID: "+playerID+")"
						currentReachTargetStep = 0
						currentAction = ACTION_IDLE
						if TRoomDoorBase(GetTarget())
							local door:TRoomDoorBase = TRoomDoorBase(GetTarget())
							local room:TRoomBase = GetRoomBaseCollection().Get(door.roomID)
							room.RemoveOccupant(self)
						endif
					endif
				endif
			endif
		endif
endrem
	End Method


	Method Update:int()
		if IsChangingRoom()
			if GetBuildingTime().GetMillisecondsGone() > changingRoomBuildingTimeEnd or ..
			   Time.GetTimeGone() > changingRoomRealTimeEnd
				if currentAction = ACTION_ENTERING
					FinishEnterRoom()
				elseif currentAction = ACTION_LEAVING
					FinishLeaveRoom()
				else
					print "UNKNOWN ROOM CHANGE ACTIONSTATE"
				endif
			endif
		endif
		

		'TODO: make obsolete ;-)
		'ATTENTION: Call _before_ figure movement
		FixBrokenEnterLeavingStates()

		'call figureBase update (does movement and updates current animation)
		local result:int = Super.Update()

		if GetGameBase().PlayingAGame()
			If isVisible() And CanMove()
				If HasToChangeFloor() And IsAtElevator() And Not IsInElevator()
					'Ist der Fahrstuhl da? Kann ich einsteigen?
					If GetElevator().CurrentFloor = GetFloor() And GetElevator().ReadyForBoarding
						GoOnBoardAndSendElevator()
					Else 'Ansonsten ruf ich ihn halt
						CallElevator()
					EndIf
				EndIf

				If IsInElevator() and GetElevator().ReadyForBoarding
					If (not GetTarget() OR GetElevator().CurrentFloor = GetFloor(GetTargetMovetoPosition()))
						GetElevator().LeaveTheElevator(Self)
					EndIf
				EndIf
			EndIf
		Endif


		'maybe someone is interested in this information
		If SyncTimer.isExpired() 
			EventManager.triggerEvent( TEventSimple.Create("figure.onSyncTimer", self) )
			SyncTimer.Reset()
		EndIf

		return result
	End Method


	Method Draw:int(overwriteAnimation:String="")
		if not sprite or not isVisible() then return FALSE

		'skip figures in rooms or in rooms not showing a figure
		If not IsChangingRoom() and inRoom and not inRoom.ShowsOccupants() then return False

		local oldAlpha:Float = GetAlpha()
		if isChangingRoom() and fadeOnChangingRoom
			'either use the building time or the real world time
			'this allows to fade out also with building time = 0
			local smallestTime:Long = GetBuildingTime().GetMillisecondsGone() - changingRoomBuildingTimeStart
			smallestTime = Min(smallestTime, Time.GetTimeGone() - changingRoomRealTimeStart)
			local alpha:float = Min(1.0, smallestTime / (float(changingRoomTime) / 2.0))
			'to building -> fade in
			if currentAction = ACTION_LEAVING
				'nothing to do
			'from building -> fade out
			elseif currentAction = ACTION_ENTERING
				alpha = 1.0 - alpha
			endif
			SetAlpha(alpha * oldAlpha)
		endif


		local renderPos:TVec2D = GetRenderAtPosition()
		RenderAt(renderPos.GetIntX(), renderPos.GetIntY())

		SetAlpha(oldAlpha)

		if greetOthers then GreetPeopleOnSameFloor()
	End Method


	Method GetRenderAtPosition:TVec2D()
		'avoid shaking figures when standing - only use tween
		'position when moving
		local tweenPos:TVec2D
		
		'also do not move with WorldTime being paused
		'alternatively (also do not move when gamespeed is "0")
		'-> and GetWorldTime().GetTimeFactor() > 0
		if velocity.GetIntX() <> 0 and not GetWorldTime().IsPaused()
			tweenPos = new TVec2D.Init(..
				MathHelper.SteadyTween(oldPosition.x, area.getX(), GetDeltaTimer().GetTween()), ..
				MathHelper.SteadyTween(oldPosition.y, area.getY(), GetDeltaTimer().GetTween()) ..
			)
		else
			tweenPos = area.position.Copy()
		endif

		'center figure
		tweenPos.AddXY(- Float(ceil(area.GetW()/2)) + PosOffset.getX(), - sprite.area.GetH() + PosOffset.getY())

		'with parent: set local to parent (add parents screen coord)
		'RONNY: 2015/01/22 - no longer needed with new RenderAt-function
		'                    for entities
		'if parent then tweenPos.AddXY(parent.GetScreenX(), parent.GetScreenY())

		return tweenPos
	End Method 


	Method RenderDebug(pos:TVec2D = Null)
		if not pos
			pos = GetRenderAtPosition()
			pos.AddXY(40, -100)
		endif

		local oldCol:TColor = new TColor.Get()

		SetAlpha oldCol.a * 0.5
		SetColor 0,0,0
		DrawRect(pos.x, pos.y, 140, 110)


		local usedDoorText:string = ""
		local inRoomText:string = ""
		local targetText:string = ""
		local targetObjText:string = ""
		if TRoomDoor(usedDoor) then usedDoorText = TRoomDoor(usedDoor).GetRoom().GetName()
		if TRoom(inRoom) then inRoomText = TRoom(inRoom).GetName()
		if GetTarget()
			local t:object = GetTarget()
			targetText = int(GetTargetMovetoPosition().x)+", "+int(GetTargetMovetoPosition().y)
			if TRoomDoor(GetTargetObject())
				targetObjText = TRoomDoor(GetTargetObject()).GetRoom().GetName()
			elseif THotSpot(GetTargetObject())
				targetObjText = "Hotspot"
			endif
		endif
		
		SetAlpha oldCol.a
		SetColor 255,255,255
		GetBitMapFont("default").Draw(name, pos.x + 5, pos.y + 5)
		GetBitMapFont("default").Draw("isChangingRoom: "+isChangingRoom(), pos.x+ 5, pos.y + 5 + 1*12)
		GetBitmapFont("default").draw("IsControllable(): " + IsControllable(), pos.x + 5, pos.y + 5 + 2 * 12)
		GetBitmapFont("default").draw("CanMove(): " + CanMove(), pos.x + 5, pos.y + 5 + 3 * 12)
		GetBitmapFont("default").draw("usedDoor: " + usedDoorText, pos.x + 5, pos.y + 5 + 4 * 12)
		GetBitmapFont("default").draw("inRoom: " + inRoomText, pos.x + 5, pos.y + 5 + 6 * 12)
		GetBitmapFont("default").draw("target: " + targetText, pos.x + 5, pos.y + 5 + 7 * 12)
		GetBitmapFont("default").draw("targetObj: " + targetObjText, pos.x + 5, pos.y + 5 + 8 * 12)

		'restore col/alpha
		oldCol.SetRGBA()
	End Method
End Type




Type TFigureTarget extends TFigureTargetBase
	'override
	Method CanEnter:int()
		If not Super.CanEnter() then return False

		return True
	End Method


	Function GetTargetMoveToPosition:TVec2D(target:object)
		if TVec2D(target)
			return TVec2D(target)
		elseif TRoomDoorBase(target)
			return new TVec2D.Init(TRoomDoorBase(target).area.GetX() + TRoomDoorBase(target).area.GetW()/2, TRoomDoorBase(target).area.GetY())
		elseif THotspot(target)
			'attention: return GetY2() (bottom point) as this is used for figures too
			return new TVec2D.Init(THotspot(target).area.GetX() + THotspot(target).area.GetW()/2, THotspot(target).area.GetY2())
		endif
		return null
	End Function


	Method GetMoveToPosition:TVec2D()
		return TFigureTarget.GetTargetMovetoPosition( targetObj )
	End Method
End Type
