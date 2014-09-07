'SuperStrict
'Import "game.gameobject.bmx"


Type TFigureCollection extends TFigureBaseCollection
	'custom eventsregistered variable - because we listen to more events
	Global _eventsRegistered:int= FALSE


	Method New()
		if not _eventsRegistered
			'TFigure can handle rooms, TFigureBase not - so listen only
			'in this collection
			EventManager.registerListenerFunction("room.onLeave", onLeaveRoom)
			EventManager.registerListenerFunction("room.onEnter", onEnterRoom)

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
			collection.list = _instance.list
			collection.lastFigureID = _instance.lastFigureID
			'now the new collection is the instance
			_instance = collection
		endif
		return TFigureCollection(_instance)
	End Function


	Method Get:TFigure(figureID:int)
		Return TFigure(Super.Get(figureID))
	End Method


	'=== EVENTS ===

	'gets called when the figure really enters a room (fadeout animation finished etc)
	Function onEnterRoom:Int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		local room:TRoomBase = TRoomBase(triggerEvent.getSender())
		if not figure or not room then return FALSE

		local door:TRoomDoorBase = TRoomDoorBase( triggerEvent.getData().get("door") )

		figure.FinishEnterRoom(room, door)
	End Function


	'gets called when the figure really leaves a room (fadein animation finished etc)
	Function onLeaveRoom:Int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		local room:TRoom = TRoom(triggerEvent.getSender())
		if not figure or not room then return FALSE

		figure.FinishLeaveRoom(room)
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetFigureCollection:TFigureCollection()
	Return TFigureCollection.GetInstance()
End Function





'all kind of characters walking through the building
'(players, terrorists and so on)
Type TFigure extends TFigureBase
	'active as soon as figure leaves/enters rooms
	Field isChangingRoom:int = FALSE
	'the door used (there might be multiple)
	Field fromDoor:TRoomDoorBase = Null
	'coming from room
	Field fromRoom:TRoomBase = Null
	Field inRoom:TRoomBase = Null

	Field WaitAtElevatorTimer:TIntervalTimer = TIntervalTimer.Create(25000)
	'network sync position timer
	Field SyncTimer:TIntervalTimer = TIntervalTimer.Create(2500)

	Field ParentPlayerID:int = 0
	Field _soundSource:TSoundSourceElement {nosave}
	'use the building coordinates or is the area absolute positioned?
	Field useAbsolutePosition:int = FALSE


	Method Create:TFigure(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		'adjust sprite animations

		SetSprite(sprite)
		GetFrameAnimations().Set("default", TSpriteFrameAnimation.Create([ [8,1000] ], -1, 0 ) )
		GetFrameAnimations().Set("walkRight", TSpriteFrameAnimation.Create([ [0,130], [1,130], [2,130], [3,130] ], -1, 0) )
		GetFrameAnimations().Set("walkLeft", TSpriteFrameAnimation.Create([ [4,130], [5,130], [6,130], [7,130] ], -1, 0) )
		GetFrameAnimations().Set("standFront", TSpriteFrameAnimation.Create([ [8,2500], [9,250] ], -1, 0, 500) )
		GetFrameAnimations().Set("standBack", TSpriteFrameAnimation.Create([ [10,1000] ], -1, 0 ) )

		name = Figurename
		area = new TRectangle.Init(x, GetBuilding().GetFloorY(onFloor), sprite.framew, sprite.frameh )
		velocity.SetX(0)
		initialdx = speed

		Self.ControlledByID	= ControlledByID

		GetFigureCollection().Add(self)

		self.figureID = GetFigureCollection().GenerateID()

		if not _initdone
			_initDone = TRUE
		endif

		Return Self
	End Method


	Method GetSoundSource:TSoundSourceElement()
		if not _soundSource then _soundSource = TFigureSoundSource.Create(Self)
		return _soundSource
	End Method


	'override to add room-support
	Method onLoad:int()
		Super.onLoad()

		'reassign rooms
		if inRoom then inRoom = GetRoomCollection().Get(inRoom.id)
		if fromRoom then fromRoom = GetRoomCollection().Get(fromRoom.id)
		if fromDoor then fromDoor = GetRoomDoorBaseCollection().Get(fromDoor.id)
		if TRoomDoorBase(targetObj) then targetObj = GetRoomDoorBaseCollection().Get(TRoomDoorBase(targetObj).id)
		'set as room occupier again (so rooms occupant list gets refilled)
		if inRoom and not inRoom.isOccupant(self)
			inRoom.addOccupant(Self)
		endif
	End Method


	Method HasToChangeFloor:Int()
		if not self.target then return FALSE
		Return GetFloor(self.target) <> GetFloor()
	End Method


	Method GetFloor:Int(pos:TVec2D = Null)
		'if we have no floor set in the pos, we return the current floor
		If not pos Then pos = area.position
		Return GetBuilding().getFloor( GetBuilding().area.position.y + pos.y )
	End Method


	Method IsOnFloor:Int()
		Return area.GetY() = GetBuilding().GetFloorY(GetFloor())
	End Method


	'ignores y
	Method IsAtElevator:int()
		Return GetBuilding().Elevator.IsFigureInFrontOfDoor(Self)
	End Method


	Method IsInElevator:int()
		Return GetBuilding().Elevator.IsFigureInElevator(Self)
	End Method


	Method IsAI:Int()
		If id > 4 Then Return True
		If ControlledByID = 0 or (GetPlayerCollection().Get(parentPlayerID) and GetPlayerCollection().Get(parentPlayerID).playerKI) Then Return True
		Return False
	End Method


	Method IsActivePlayer:Int()
		return (parentPlayerID = GetPlayerCollection().playerID)
	End Method




	Method FigureMovement:int()
		If not CanMove() then return False

		'stop movement, will get set to a value if we have a target to move to
		velocity.setX(0)

		'we have a target to move to
		if target
			'get a temporary target coordinate so we can manipulate that safely
			Local targetX:Int = target.getIntX()

			'do we have to change the floor?
			'if that is the case - change temporary target to elevator
			If HasToChangeFloor() Then targetX = GetBuilding().Elevator.GetDoorCenterX()

			'check whether the target is left or right side of the figure
			If targetX < area.GetX()
				velocity.SetX( -(Abs(initialdx)))
			ElseIf targetX > area.GetX()
				velocity.SetX(  (Abs(initialdx)))
			EndIf


			'does the center of the figure will reach the target during update?
			local dx:float = GetVelocity().GetX() * GetDeltaTimer().GetDelta() * GetWorldSpeedFactor()
			local reachTemporaryTarget:int = FALSE
			'move to right and next step is more right than target
			if dx > 0 and ceil(area.getX() + dx) >= targetX then reachTemporaryTarget=true
			'move to left and next step is more left than target
			if dx < 0 and ceil(area.getX() + dx) <= targetX then reachTemporaryTarget=true
			'we stand in front of the target
			if dx = 0 and abs(area.getX() - targetX) < 1.0 then reachTemporaryTarget=true


			'we reached our current target (temp or real)
			If reachTemporaryTarget
				'stop moving
				velocity.SetX(0)

				'we reached our real target
				if not HasToChangeFloor()
					'you can only reach target when not a passenger of
					'the elevator - this avoids going into the elevator
					'plan without really leaving the elevator
					If not GetBuilding().Elevator.passengers.Contains(Self)
						reachTarget()
					endif
				else
					'set to elevator-targetx
					oldPosition.setX(targetX) 'set tween position too
					area.position.setX(targetX)
				endif
			endif
		endif

		'decide if we have to play sound
		if GetVelocity().getX() <> 0 and not IsInElevator()
			GetSoundSource().PlayOrContinueRandomSFX("steps")
		else
			GetSoundSource().Stop("steps")
		EndIf


		'adjust/limit position based on location
		If Not IsInElevator()
			If Not IsOnFloor() and not useAbsolutePosition Then area.position.setY( GetBuilding().GetFloorY(GetFloor()) )
		EndIf

		'limit player position (only within floor 13 and floor 0 allowed)
		if not useAbsolutePosition
			'beim Vergleich oben nicht "self.sprite.area.GetH()" abziehen... das war falsch und führt zum Ruckeln im obersten Stock
			If area.GetY() < GetBuilding().GetFloorY(13) Then area.position.setY( GetBuilding().GetFloorY(13) )
			If area.GetY() - sprite.area.GetH() > GetBuilding().GetFloorY( 0) Then area.position.setY( GetBuilding().GetFloorY(0) )
		endif
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
				'multiply boardingState : if boarding it is 1, if deboarding it is -1
				'so multiplying negates value if needed
				If boardingState * PosOffset.GetX() > 0 Then result = "walkRight"
				If boardingState * PosOffset.GetX() < 0 Then result = "walkLeft"
			EndIf

			'show the backside if at elevator
			If hasToChangeFloor() And Not IsInElevator() And IsAtElevator()
				result = "standBack"
			'going into a room
			ElseIf isChangingRoom and TRoomDoor(targetObj)
				result = "standBack"
			'in a room (or standing in front of a fake room - looking at plan)
			ElseIf inRoom and inRoom.ShowsOccupants()
				result = "standBack"
			'show front
			Else
				result = "standFront"
			EndIf
		EndIf

		return result
	End Method



	Method GetGreetingTypeForFigure:int(figure:TFigure)
		'0 = grrLeft
		'1 = hiLeft
		'2 = ?!left

		'if both figures are "players" we display "GRRR" or "?!!?"
		If figure.parentPlayerID and parentPlayerID
			'depending on floor use "grr" or "?!"
			return 0 + 2*((1 + GetBuilding().GetFloor(area.GetY()) mod 2)-1)
		'display "hi"
		else
			return 1
		endif
	End Method


	Method GreetPeopleOnSameFloor()
		For Local Figure:TFigure = EachIn GetFigureCollection().List
			'skip other figures
			if self = Figure then continue
			'skip if both can't see each other to me
			if not CanSeeFigure(figure) and not figure.CanSeeFigure(self) then continue


			local greetType:int = GetGreetingTypeForFigure(figure)

			'if the greeting type differs
			'- or enough time has gone for another greet
			'- or another figure gets greeted
			if greetType <> lastGreetType or Time.GetTimeGone() - lastGreetTime > greetEvery or lastGreetFigureID <> figure.id
				lastGreetType = greetType
				lastGreetFigureID = figure.id

				lastGreetTime = Time.GetTimeGone()
			endif

			'show greet for a maximum time of "showGreetTime"
			if Time.GetTimeGone() - lastGreetTime < greetTime
				local scale:float = TInterpolation.BackOut(0.0, 1.0, Min(greetTime, Time.GetTimeGone() - lastGreetTime), greetTime)
				local oldAlpha:float = GetAlpha()
				SetAlpha TInterpolation.RegularOut(0.5, 1.0, Min(0.5*greetTime, Time.GetTimeGone() - lastGreetTime), 0.5*greetTime)
				'subtract half width from position - figure is drawn centered
				'figure right of me
				If Figure.area.GetX() > area.GetX()
					'draw the "to the right" balloon a bit lower (so both are better visible)
					GetSpriteFromRegistry("gfx_building_textballons").Draw(int(area.GetX() + area.GetW()/2 -2), int(GetBuilding().area.GetY() + area.GetY() - sprite.area.GetH() + 2), greetType, ALIGN_LEFT_CENTER, scale)
				'figure left of me
				else
					greetType :+ 3
					GetSpriteFromRegistry("gfx_building_textballons").Draw(int(area.GetX() - area.GetW()/2 +2), int(GetBuilding().area.GetY() + area.GetY() - sprite.area.GetH()), greetType, ALIGN_RIGHT_CENTER, scale)
				endif
				SetAlpha oldAlpha
			endif
		Next
	End Method


	'override to take rooms into consideration
	Method IsVisible:int()
		'in a fake room?
		if inRoom and inRoom.ShowsOccupants() then return True
		
		return (IsInBuilding() or isChangingRoom)
	End Method


	Method IsInBuilding:int()
		If isChangingRoom Then Return False
		If inRoom Then Return False
		Return True
	End Method


	'override to add buildingsupport
	Method CanMove:int()
		If not IsInBuilding() then return False

		return Super.CanMove()
	End Method


	'player is now in room "room"
	Method SetInRoom:Int(room:TRoomBase)
		'in all cases: close the door (even if we cannot enter)
		'Ronny TODO: really needed?
		If room and TRoomDoorBase(targetObj) then TRoomDoorBase(targetObj).Close(self)

		If room and not room.IsOccupant(self) then room.addOccupant(Self)

		'remove target if we are going in a room
		if room then targetObj = null

		'backup old room as origin
		fromRoom = inRoom

		'set new room
	 	inRoom = room

		'room change finished
		isChangingRoom = FALSE

	 	'inform AI that we reached a room
	 	If ParentPlayerID > 0 And isAI()
			If room Then GetPlayerCollection().Get(ParentPlayerID).PlayerKI.CallOnReachRoom(room.id) Else GetPlayerCollection().Get(ParentPlayerID).PlayerKI.CallOnReachRoom(LuaFunctions.RESULT_NOTFOUND)
		EndIf

		'inform others that room is changed
		EventManager.triggerEvent( TEventSimple.Create("figure.SetInRoom", self, inroom) )
	End Method


	Method KickFigureFromRoom:Int(kickFigure:TFigure, room:TRoomBase)
		If Not kickFigure Or Not room Then Return False
		If kickFigure = self then return FALSE

		'fetch at least the main door if none is provided
		local door:TRoomDoorBase = kickFigure.fromDoor
		if not door then door = TRoomDoor.GetMainDoorToRoom(room)

		TLogger.log("TFigure.KickFigureFromRoom()", name+" kicks "+ kickFigure.name + " out of room: "+room.name, LOG_DEBUG)
		'instead of SimpleSoundSource we use the rooms sound source
		'so we are able to have positioned sound
		if TRoomDoor(door)
			TRoomDoor(door).GetSoundSource().PlayRandomSFX("kick_figure", TRoomDoor(door).GetSoundSource().GetPlayerBeforeDoorSettings())
		endif

		'maybe someone is interested in this information
		EventManager.triggerEvent( TEventSimple.Create("room.kickFigure", new TData.Add("figure", kickFigure).Add("door", door), room ) )

		kickFigure.LeaveRoom(True)
		Return True
	End Method


	'figure wants to enter a room
	'"onEnterRoom" is called when successful
	'@param door         door to use
	'@param room         room to enter (in case no door exists)
	'@param forceEnter   kick without being the room owner
	Method EnterRoom:Int(door:TRoomDoor, room:TRoomBase, forceEnter:int=FALSE)
		'skip command if we already are entering/leaving
		if isChangingRoom then return TRUE

		'assign room if not done yet
		if not room and door then room = door.room

		'if already in another room, leave that first
		if inRoom then LeaveRoom(True)

		'figure is already in that room - so just enter
		if room.isOccupant(self) then return TRUE

		'something (bomb, renovation, ...) does not allow access to this
		'room for now
		if room.IsBlocked()
			'inform player AI
			If isAI() then GetPlayerCollection().Get(parentPlayerID).PlayerKI.CallOnReachRoom(LuaFunctions.RESULT_NOTALLOWED)
			'tooltip only for active user
			If isActivePlayer() then GetBuilding().CreateRoomBlockedTooltip(door, room)
			return FALSE
		endif

		'check if enter not possible
		if not CanEnterRoom(room) and not forceEnter
			If room.hasOccupant() and not room.isOccupant(self)
				'only player-figures need such handling (events etc.)
				If parentPlayerID and not parentPlayerID = room.owner
					'inform player AI
					If isAI() then GetPlayerCollection().Get(parentPlayerID).PlayerKI.CallOnReachRoom(LuaFunctions.RESULT_INUSE)
					'tooltip only for active user
					If isActivePlayer() then GetBuilding().CreateRoomUsedTooltip(door, room)
					return FALSE
				EndIf
			EndIf
		endif

		'ask if somebody is against going into the room
		local event:TEventSimple = TEventSimple.Create("figure.onTryEnterRoom", new TData.Add("door", door) , self, room )
		EventManager.triggerEvent(event)
		'stop entering
		if event.IsVeto() then return False
		
		'enter is allowed - set time of start
		isChangingRoom = Time.GetTimeGone()

		'actually enter the room
		room.BeginEnter(door, self, TRoom.ChangeRoomSpeed/2)


		'kick other figures from the room if figure is the owner 
		'only player-figures need such handling (events etc.)
		If parentPlayerID and parentPlayerID = room.owner
			for local occupant:TFigure = eachin room.occupants
				if occupant <> self then KickFigureFromRoom(occupant, room)
			next
		EndIf
	End Method


	Method FinishEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase)
		'=== INFORM OTHERS ===
		'inform figure that it now entered the room
		EventManager.triggerEvent( TEventSimple.Create("figure.onEnterRoom", new TData.Add("room", room).Add("door", door) , self, room) )
		'maybe move this lines to TPlayer
		If ParentPlayerID > 0
			EventManager.triggerEvent( TEventSimple.Create("player.onEnterRoom", new TData.Add("door", door), GetPlayerCollection().Get(ParentPlayerID), room) )
		EndIf
		
	 	'inform player AI that figure entered a room
	 	If ParentPlayerID > 0 And isAI()
			GetPlayerCollection().Get(ParentPlayerID).PlayerKI.CallOnEnterRoom(room.id)
		EndIf

		'=== SET IN ROOM ===
		SetInRoom(room)
	End Method


	Method CanEnterRoom:Int(room:TRoomBase)
		'cannot enter if room forbids
		'(exception are non-players)
		if not room.CanEntityEnter(self)
			if not room.IsBlocked() and not parentPlayerID
				return True
			endif

			return False
		endif

		'players must be owner of the room
		If parentPlayerID = room.owner then return True

		return False
	End Method 


	'command to leave a room - "onLeaveRoom" is called when successful
	Method LeaveRoom:Int(force:Int=False)
		'skip command if in no room or already leaving
		if not inroom or isChangingRoom then return True

		'=== CHECK IF LEAVING IS ALLOWED ===
		'skip leaving if not allowed to do so
		if not force and not CanLeaveroom(inroom) then return False

		'ask if somebody is against leaving that room
		'but ignore the result if figure is forced to leave
		local event:TEventSimple = TEventSimple.Create("figure.onTryLeaveRoom", null , self, inroom )
		EventManager.triggerEvent(event)
		'stop leaving
		if not force and event.IsVeto() then return False

		'inform that a figure forcefully leaves a room (so GUI or so can
		'get cleared)
		if force then EventManager.triggerEvent(TEventSimple.Create("figure.onForcefullyLeaveRoom", null , self, inroom))


		'=== LEAVE ===
		'leave is allowed - set time of start
		isChangingRoom = Time.GetTimeGone()

		inRoom.BeginLeave(null, self, TRoom.ChangeRoomSpeed/2)
	End Method


	'gets called when the figure really leaves the room (animation finished etc)
	Method FinishLeaveRoom(room:TRoomBase)
		'inform others that a figure left the room
		EventManager.triggerEvent( TEventSimple.Create("figure.onLeaveRoom", null, self, room ) )
		'maybe move this lines to TPlayer
		If ParentPlayerID > 0
			EventManager.triggerEvent( TEventSimple.Create("player.onLeaveRoom", null, GetPlayerCollection().Get(ParentPlayerID), room) )
		EndIf

		'inform player AI
		If GetPlayerCollection().Get(ParentPlayerID) And isAI()
			local roomID:int = 0
			if room then roomID = room.id
			GetPlayerCollection().Get(ParentPlayerID).PlayerKI.CallOnLeaveRoom(roomID)
		endif

		'enter target -> null = building
		SetInRoom( null )
	End Method


	Method CanLeaveRoom:Int(room:TRoomBase)
		'cannot leave if room forbids
		if not room.CanEntityLeave(self) then return False

		return True
	End Method 


	Method SendToDoor:Int(door:TRoomDoorBase, forceSend:Int=False)
 		If not door then return FALSE

		If forceSend
			ForceChangeTarget(door.area.GetX() + 5, GetBuilding().area.GetY() + GetBuilding().getfloorY(door.area.GetY()) - 5)
		Else
			ChangeTarget(door.area.GetX() + 5, GetBuilding().area.GetY() + GetBuilding().getfloorY(door.area.GetY()) - 5)
		EndIf
	End Method


	'send a figure to the offscreen position
	Method SendToOffscreen:Int()
		ChangeTarget(-50, GetBuilding().area.GetY() + GetBuilding().getfloorY(0) - 5)
	End Method


	'instantly move a figure to the offscreen position
	Method MoveToOffscreen:Int()
		area.position.SetXY(-50, GetBuilding().GetFloorY(0))
	End Method


	Method IsOffscreen:int()
		if GetFloor() = 0 and area.GetX() = -50 then return True
		return False
	End Method


	Method GoToCoordinatesRelative:Int(relX:Int = 0, relYFloor:Int = 0)
		Local newX:Int = area.GetX() + relX
		Local newY:Int = GetBuilding().area.GetY() + GetBuilding().getfloorY(GetFloor() + relYFloor) - 5

		if (newX < 150) then newX = 150 end
		if (newX > 580) then newX = 580 end

 		ChangeTarget(newX, newY)
	End Method


	Method CallElevator:Int()
		'ego nur ich selbst
		'if not self.parentPlayer or self.parentPlayer.playerID <> 1 then return false

		If IsElevatorCalled() Then Return False 'Wenn er bereits gerufen wurde, dann abbrechen

		'Wenn der Fahrstuhl schon da ist, dann auch abbrechen. TODOX: Muss überprüft werden
		If GetBuilding().Elevator.CurrentFloor = GetFloor() And IsAtElevator() Then Return False

		'Fahrstuhl darf man nur rufen, wenn man davor steht
		If IsAtElevator() Then GetBuilding().Elevator.CallElevator(Self)
	End Method


	Method GoOnBoardAndSendElevator:Int()
		if not target then return FALSE
		If GetBuilding().Elevator.EnterTheElevator(Self, Self.getFloor(target))
			GetBuilding().Elevator.SendElevator(Self.getFloor(target), Self)
		EndIf
	End Method


	'overridden
	'change the target of the figure
	'@forceChange   defines wether the target could change target
	'               even when not controllable
	Method _ChangeTarget:Int(x:Int=-1, y:Int=-1, forceChange:Int=False)
		'remove control
		if forceChange then controllable = False
		'is controlling allowed (eg. figure MUST go to a specific target)
		if not forceChange and not IsControllable() then Return False

		'if player is in elevator dont accept changes
		if not forceChange and GetBuilding().Elevator.passengers.Contains(Self) Then Return False
		'only change target if it's your figure or you are game leader
		If self <> GetPlayerCollection().Get().figure And Not Game.isGameLeader() Then Return False


		'=== CALCULATE NEW TARGET/TARGET-OBJECT ===
		local newTargetObj:TStaticEntity = Null
		local newTarget:TVec2D = Null
	
		'only a partial target was given
		if x=-1 or y=-1
			'change current target
			if target
				If x<>-1 Then x = target.x
				If y<>-1 Then y = target.y
			'create a new target
			else
				If x=-1 Then x = area.position.x
				If y=-1 Then y = area.position.y
			endif
		endif

		'y is not of floor 0 -13
		If GetBuilding().GetFloor(y) < 0 Or GetBuilding().GetFloor(y) > 13 Then Return False

		'set new target, y is recalculated to "basement"-y of that floor
		newTarget = new TVec2D.Init(x, GetBuilding().GetFloorY(GetBuilding().GetFloor(y)) )

		'when targeting a room, set target to center of door
		newTargetObj = TRoomDoor.GetByCoord(newTarget.x, GetBuilding().area.GetY() + newTarget.y)
		If newTargetObj then newTarget.setX(newTargetObj.area.GetX() + ceil(newTargetObj.area.GetW()/2))

		'limit target coordinates
		'on the base floor we can walk outside the building, so just
		'check right side
		'target.y contains the floorY so we use "y" which holds clicked
		'floor
		local rightLimit:int = 603' - ceil(rect.GetW()/2) 'subtract half a figure
		local leftLimit:int = 200' + ceil(rect.GetW()/2) 'add half a figure

		if GetBuilding().GetFloor(y) = 0
			If Floor(newTarget.x) >= rightLimit Then newTarget.X = rightLimit
		else
			If Floor(newTarget.x) <= leftLimit Then newTarget.X = leftLimit
			If Floor(newTarget.x) >= rightLimit Then newTarget.X = rightLimit
		endif

		local targetRoom:TRoomBase
		if TRoomDoor(newTargetObj) then targetRoom = TRoomDoor(newTargetObj).room 


		'=== CHECK IF ALREADY THERE ===
		'check if figure is already at this target
		if newTargetObj and newTargetObj = targetObj then return False
		if newTarget and target and newTarget.isSame(target) then return False
		'or if already in this room
		if targetRoom and targetRoom = inRoom then return False


		'=== SET NEW TARGET ===
		'new target - so go to it
		target = newTarget.Copy()
		targetObj = newTargetObj

		'if still in a room, but targetting another one ... leave first
		'this is needed as computer players do not "leave a room", they
		'just change targets
		If targetRoom and targetRoom <> inRoom Then LeaveRoom(forceChange)

		'emit an event
		EventManager.triggerEvent( TEventSimple.Create("figure.onChangeTarget", self ) )

		return TRUE
	End Method


	Method IsGameLeader:Int()
		Return (id = GetPlayerCollection().playerID Or (IsAI() And GetPlayerCollection().playerID = Game.isGameLeader()))
	End Method


	Method IsElevatorCalled:Int()
		For Local floorRoute:TFloorRoute = EachIn GetBuilding().Elevator.FloorRouteList
			If floorRoute.who.id = Self.id
				Return True
			EndIf
		Next
		Return False
	End Method


	'override to add support for hotspots/rooms and sending an event
	Method reachTarget:int()
		Super.ReachTarget()

		if targetObj
			'emit an event
			EventManager.triggerEvent( TEventSimple.Create("figure.onReachTarget", null, self, targetObj ) )

			if THotspot(targetObj)
				'remove targeted hotspot
				targetObj = null
			elseif TRoomDoor(targetObj)
				local targetDoor:TRoomDoor = TRoomDoor(targetObj)

				'do not remove the target room as it is done during
				'"entering the room" (which can be animated and so we
				'just trust the method to do it)
				EnterRoom(targetDoor, null)
			EndIf
		endif
	End Method


	Method Update:int()
		'call figureBase update (does movement and updates current animation)
		Super.Update()


		If isVisible() And CanMove()
			If HasToChangeFloor() And IsAtElevator() And Not IsInElevator()
				'TODOX: Blockiert.. weil noch einer aus dem Plan auswählen will

				'Ist der Fahrstuhl da? Kann ich einsteigen?
				If GetBuilding().Elevator.CurrentFloor = GetFloor() And GetBuilding().Elevator.ReadyForBoarding
					GoOnBoardAndSendElevator()
				Else 'Ansonsten ruf ich ihn halt
					CallElevator()
				EndIf
			EndIf

			If IsInElevator() and GetBuilding().Elevator.ReadyForBoarding
				If (not target OR GetBuilding().Elevator.CurrentFloor = GetFloor(target))
					GetBuilding().Elevator.LeaveTheElevator(Self)
				EndIf
			EndIf
		EndIf


		'maybe someone is interested in this information
		If SyncTimer.isExpired() 
			EventManager.triggerEvent( TEventSimple.Create("figure.onSyncTimer", self) )
			SyncTimer.Reset()
		EndIf
	End Method


	Method Draw:int(overwriteAnimation:String="")
		if not sprite or not isVisible() then return FALSE

		'skip figures in rooms or in rooms not showing a figure
		If inRoom and not inRoom.ShowsOccupants() then return False

		local oldAlpha:Float = GetAlpha()
		if isChangingRoom
			local alpha:float = Min(1.0, float(Time.GetTimeGone() - isChangingRoom) / (TRoom.ChangeRoomSpeed / 2))
			'to building -> fade in
			if inroom
				'nothing to do
			'from building -> fade out
			else
				alpha = 1.0 - alpha
			endif

			'do not fade when it is a fake room
			if inRoom and inRoom.ShowsOccupants() then alpha = 1.0
			if fromRoom and fromRoom.ShowsOccupants() then alpha = 1.0
			if TRoomDoor(targetObj) and TRoomDoor(targetObj).room
				if TRoomDoor(targetObj).room.ShowsOccupants() then alpha = 1.0
			endif
			
			SetAlpha(alpha * oldAlpha)
		endif

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

		'draw x-centered at current position, with int
		if useAbsolutePosition
			RenderAt( int(tweenPos.X - ceil(area.GetW()/2) + PosOffset.getX()), int(tweenPos.Y - sprite.area.GetH() + PosOffset.getY()))
		else
			RenderAt( int(tweenPos.X - ceil(area.GetW()/2) + PosOffset.getX()), int(GetBuilding().area.position.y + tweenPos.Y - sprite.area.GetH() + PosOffset.getY()))
		endif
		SetAlpha(oldAlpha)

		if greetOthers then GreetPeopleOnSameFloor()
	End Method
End Type
