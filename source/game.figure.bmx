'SuperStrict
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
	Field changingRoomStart:Long = 0 {nosave}
	Field fadeOnChangingRoom:int = False
	
	'the door used (there might be multiple)
	Field fromDoor:TRoomDoorBase = Null
	'coming from room
	Field fromRoom:TRoomBase = Null
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
		For local target:object = EachIn targets
			if TRoomDoorBase(target) then target = GetRoomDoorBaseCollection().Get(TRoomDoorBase(target).id)
		Next
		'set as room occupier again (so rooms occupant list gets refilled)
		if inRoom and not inRoom.isOccupant(self)
			inRoom.addOccupant(Self)
		endif
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
		'start waiting in front of the target
		If TRoomDoorBase(GetTarget()) or THotspot(GetTarget())
			WaitEnterTimer = Time.GetTimeGone() + WaitEnterLeavingTime
		Else
			Super.customReachTargetStep1()
		EndIf
	End Method


	'override to 
	Method TargetNeedsToGetEntered:int()
		if TRoomDoorBase(GetTarget()) then return True
		'if hotspot, ask it whether enter is wanted
		if THotSpot(GetTarget()) then return THotSpot(GetTarget()).IsEnterable()

		return Super.TargetNeedsToGetEntered()
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

				local dx:float = GetVelocity().GetX() * GetDeltaTimer().GetDelta() * GetWorldSpeedFactor()
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
				else
					'set to elevator-targetx
					oldPosition.setX(targetX) 'set tween position too
					area.position.setX(targetX)
				endif
			endif
		endif

		'we have a target and are in this moment entering it
		if GetTarget() and currentReachTargetStep = 1
			if not TargetNeedsToGetEntered()
				ReachTargetStep2()
			else
				'if waitingtime is over, start going-into-animation (takes
				'some time too -> FinishEnterRoom is called when that is
				'finished too)
				if not IsWaitingToEnter()
					if CanEnterTarget() then EnterTarget()
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
			If Not IsOnFloor() and not useAbsolutePosition Then area.position.setY( TBuildingBase.GetFloorY2(GetFloor()) )
		EndIf

		'limit player position (only within floor 13 and floor 0 allowed)
		if not useAbsolutePosition
			'beim Vergleich oben nicht "self.sprite.area.GetH()" abziehen... das war falsch und führt zum Ruckeln im obersten Stock
			If area.GetY() < TBuildingBase.GetFloorY2(13) Then area.position.setY( TBuildingBase.GetFloorY2(13) )
			If area.GetY() - sprite.area.GetH() > TBuildingBase.GetFloorY2(0) Then area.position.setY( TBuildingBase.GetFloorY2(0) )
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

			'show the backside if at elevator to change floor
			If hasToChangeFloor() And Not IsInElevator() And IsAtElevator()
				result = "standBack"
			'not moving but wants to go to somewhere
			ElseIf currentAction = ACTION_ENTERING
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


	'override to take rooms into consideration
	Method IsVisible:int()
		'in a fake room?
		if inRoom and inRoom.ShowsOccupants() then return True
		
		return (IsInBuilding() or isChangingRoom())
	End Method


	Method IsChangingRoom:int()
		return currentAction = ACTION_ENTERING or currentAction = ACTION_LEAVING
	End Method


	'override to add room support
	Method IsInBuilding:int()
		If isChangingRoom() Then Return False
		If inRoom Then Return False
		Return True
	End Method


	'override to add support for rooms
	Method IsInRoom:Int(roomName:String="", checkFromRoom:Int=False)
		If checkFromRoom
			'when checking "fromRoom", fromRoom has to be set AND
			'inroom <> null (then figure is NOT in the building!)

			'check for specified room
			If roomName <> ""
				Return (inRoom And inRoom.Name.toLower() = roomname.toLower()) Or (inRoom And fromRoom And Name.toLower() = roomname.toLower())
			'just check if we are in a unspecified room
			Else
				Return inRoom Or (inRoom And fromRoom)
			Endif
		Else
			If roomName <> ""
				Return (inRoom And inRoom.Name.toLower() = roomname.toLower())
			Else
				Return inRoom <> null
			EndIf
		EndIf
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
		If room and TRoomDoorBase(GetTarget()) then TRoomDoorBase(GetTarget()).Close(self)

		If room and not room.IsOccupant(self) then room.addOccupant(Self)

		'backup old room as origin
		fromRoom = inRoom

		'set new room
	 	inRoom = room

		'inform others that room is changed
		EventManager.triggerEvent( TEventSimple.Create("figure.SetInRoom", self, inroom) )
	End Method


	Method KickFigureFromRoom:Int(kickFigure:TFigure, room:TRoomBase)
		If Not kickFigure Or Not room Then Return False
		If kickFigure = self then return FALSE

		'fetch at least the main door if none is provided
		local door:TRoomDoorBase = kickFigure.fromDoor
		if not door and room then door = GetRoomDoorCollection().GetMainDoorToRoom(room.id)

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


		'if already in another room, leave that first
		if inRoom then LeaveRoom(True)

		'figure is already in that room - so just enter
		if room.isOccupant(self) then return TRUE

		'something (bomb, renovation, ...) does not allow access to this
		'room for now
		if room.IsBlocked()
			'inform ALL about this (eg. inform AI or Player )
			EventManager.triggerEvent(TEventSimple.Create("figure.onFailEnterRoom", new TData.AddString("reason", "blocked").Add("door", door), self, room))

			return FALSE
		endif

		'check if enter not possible
		if not CanEnterRoom(room) and not forceEnter
			If room.hasOccupant() and not room.isOccupant(self)
				'only player-figures need such handling (events etc.)
				'all others just enter
				If playerID and not playerID = room.owner
					'inform ALL about this (eg. inform AI or Player )
					EventManager.triggerEvent(TEventSimple.Create("figure.onFailEnterRoom", new TData.AddString("reason", "inuse").Add("door", door), self, room))

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
		changingRoomStart = Time.GetTimeGone()

		'actually enter the room
		room.BeginEnter(door, self, TRoomBase.ChangeRoomSpeed/2)

		'inform what the figure does now
		currentAction = ACTION_ENTERING

		'inform ALL about this
		EventManager.triggerEvent(TEventSimple.Create("figure.onBeginEnterRoom", null, self, room))


		'do not fade when it is a fake room
		fadeOnChangingRoom = True
		if room.ShowsOccupants() then fadeOnChangingRoom = False
	
		'kick other figures from the room if figure is the owner 
		'only player-figures need such handling (events etc.)
		If playerID and playerID = room.owner
			for local occupant:TFigure = eachin room.occupants
				'only kick other players ?!
				if not occupant.playerID then continue
				if occupant <> self then KickFigureFromRoom(occupant, room)
			next
		EndIf
	End Method



	Method FinishEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase)
		'=== INFORM OTHERS ===
		'inform that figure now enters the room
		'(eg. for players informing the ai)
		EventManager.triggerEvent( TEventSimple.Create("figure.onEnterRoom", new TData.Add("room", room).Add("door", door) , self, room) )

		'reset action
		currentAction = ACTION_IDLE

		'=== SET IN ROOM ===
		SetInRoom(room)

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

		'players must be owner of the room
		If playerID = room.owner then return True

		return False
	End Method 


	'command to leave a room - "onLeaveRoom" is called when successful
	Method LeaveRoom:Int(force:Int=False)
		'skip command if in no room or already leaving
		if not inroom or isChangingRoom() then return True

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
		changingRoomStart = Time.GetTimeGone()

		'inform what the figure does now
		currentAction = ACTION_LEAVING

		'do not fade when it is a fake room
		fadeOnChangingRoom = True
		if inRoom.ShowsOccupants() then fadeOnChangingRoom = False

		inRoom.BeginLeave(null, self, TRoom.ChangeRoomSpeed/2)
	End Method


	'gets called when the figure really leaves the room (animation finished etc)
	Method FinishLeaveRoom(room:TRoomBase)
		'inform others that a figure left the room
		'-> triggers Player-AI etc.
		EventManager.triggerEvent( TEventSimple.Create("figure.onLeaveRoom", null, self, room ) )

		'enter target -> null = building
		SetInRoom( null )

		'reset action
		currentAction = ACTION_IDLE

		'activate timer to wait a bit after leaving a room
		WaitLeavingTimer = Time.GetTimeGone() + WaitEnterLeavingTime
	End Method


	Method CanLeaveRoom:Int(room:TRoomBase)
		'cannot leave if room forbids
		if not room.CanEntityLeave(self) then return False

		return True
	End Method 


	Method SendToDoor:Int(door:TRoomDoorBase, forceSend:Int=False)
 		If not door then return FALSE

		If forceSend
			ForceChangeTarget(door.area.GetX() + 5, door.area.GetY())
		Else
			ChangeTarget(door.area.GetX() + 5, door.area.GetY())
		EndIf
	End Method


	'send a figure to the offscreen position
	Method SendToOffscreen:Int()
		ChangeTarget(GameRules.offscreenX, TBuildingBase.GetFloorY2(0) - 5)
	End Method


	'instantly move a figure to the offscreen position
	Method MoveToOffscreen:Int()
		area.position.SetXY(GameRules.offscreenX, TBuildingBase.GetFloorY2(0))
	End Method


	Method IsOffscreen:int()
		if GetFloor() = 0 and area.GetX() <= GameRules.offscreenX then return True
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

		'Wenn der Fahrstuhl schon da ist, dann auch abbrechen. TODOX: Muss überprüft werden
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
		local target:object = GetTarget()
		if TVec2D(target)
			return TVec2D(target)
		elseif TRoomDoorBase(target)
			return new TVec2D.Init(TRoomDoorBase(target).area.GetX() + TRoomDoorBase(target).area.GetW()/2, TRoomDoorBase(target).area.GetY())
		elseif THotspot(target)
			return new TVec2D.Init(THotspot(target).area.GetX() + THotspot(target).area.GetW()/2, THotspot(target).area.GetY())
		endif
		
		return Null
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
		if not forceChange and IsInElevator() Then Return False

		'=== CALCULATE NEW TARGET/TARGET-OBJECT ===
		local newTarget:object = Null
	
		'only a partial target was given
		if x=-1 or y=-1
			'change current target
			if TVec2D( GetTarget() )
				If x<>-1 Then x = TVec2D( GetTarget() ).x
				If y<>-1 Then y = TVec2D( GetTarget() ).y
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
		if TRoomDoor.GetByCoord(newTargetCoord.x, newTargetCoord.y)
			newTarget = TRoomDoor.GetByCoord(newTargetCoord.x, newTargetCoord.y)
			newTargetCoord = TRoomDoor(newTarget).area.position.copy()
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
		if newTarget and newTarget = GetTarget() then return False
		'new target and current target are positions and the same?
		if TVec2D(newTarget) and TVec2D(GetTarget()) and TVec2D(newTarget).isSame(TVec2D(GetTarget())) then return False
		'or if already in this room
		if targetRoom and targetRoom = inRoom then return False

		'=== SET NEW TARGET ===
		'new target - so go to it, remove other previously set targets
		SetTarget(newTarget)

		'if still in a room, but targetting another one ... leave first
		'this is needed as computer players do not "leave a room", they
		'just change targets
		If targetRoom and targetRoom <> inRoom Then LeaveRoom(forceChange)

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

		'emit an event
		EventManager.triggerEvent( TEventSimple.Create("figure.onEnterTarget", null, self, GetTarget() ) )

		local targetDoor:TRoomDoor = TRoomDoor(GetTarget())
		if targetDoor
			'do not remove the target room as it is done during
			'"entering the room" (which can be animated and so we
			'just trust the method to do it)
			EnterLocation(targetDoor)
		EndIf
	End Method


	Method Update:int()
		'call figureBase update (does movement and updates current animation)
		Super.Update()


		If isVisible() And CanMove()
			If HasToChangeFloor() And IsAtElevator() And Not IsInElevator()
				'TODOX: Blockiert.. weil noch einer aus dem Plan auswählen will

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


		'maybe someone is interested in this information
		If SyncTimer.isExpired() 
			EventManager.triggerEvent( TEventSimple.Create("figure.onSyncTimer", self) )
			SyncTimer.Reset()
		EndIf
	End Method


	Method Draw:int(overwriteAnimation:String="")
		if not sprite or not isVisible() then return FALSE

		'skip figures in rooms or in rooms not showing a figure
		If not IsChangingRoom() and inRoom and not inRoom.ShowsOccupants() then return False

		local oldAlpha:Float = GetAlpha()
		if isChangingRoom() and fadeOnChangingRoom
			local alpha:float = Min(1.0, float(Time.GetTimeGone() - changingRoomStart) / (TRoom.ChangeRoomSpeed / 2.0))
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
		tweenPos.AddXY(- ceil(area.GetW()/2) + PosOffset.getX(), - sprite.area.GetH() + PosOffset.getY())

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


		local fromDoorText:string = ""
		local fromRoomText:string = ""
		local inRoomText:string = ""
		local targetText:string = ""
		local targetObjText:string = ""
		if TRoomDoor(fromDoor) then fromDoorText = TRoomDoor(fromDoor).GetRoom().GetName()
		if TRoom(fromRoom) then fromRoomText = TRoom(fromRoom).GetName()
		if TRoom(inRoom) then inRoomText = TRoom(inRoom).GetName()
		if GetTarget()
			targetText = int(GetTargetMovetoPosition().x)+", "+int(GetTargetMovetoPosition().y)
			if TRoomDoor(GetTarget())
				targetObjText = TRoomDoor(GetTarget()).GetRoom().GetName()
			elseif THotSpot(GetTarget())
				targetObjText = "Hotspot"
			endif
		endif
		
		SetAlpha oldCol.a
		SetColor 255,255,255
		GetBitMapFont("default").Draw(name, pos.x + 5, pos.y + 5)
		GetBitMapFont("default").Draw("isChangingRoom: "+isChangingRoom(), pos.x+ 5, pos.y + 5 + 1*12)
		GetBitMapFont("default").Draw("IsControllable(): "+IsControllable(), pos.x+ 5, pos.y + 5 + 2*12)
		GetBitMapFont("default").Draw("CanMove(): "+CanMove(), pos.x+ 5, pos.y + 5 + 3*12)
		GetBitMapFont("default").Draw("fromDoor: "+fromDoorText, pos.x+ 5, pos.y + 5 + 4*12)
		GetBitMapFont("default").Draw("fromRoom: "+fromRoomText, pos.x+ 5, pos.y + 5 + 5*12)
		GetBitMapFont("default").Draw("inRoom: "+inRoomText, pos.x+ 5, pos.y + 5 + 6*12)
		GetBitMapFont("default").Draw("target: "+targetText, pos.x+ 5, pos.y + 5 + 7*12)
		GetBitMapFont("default").Draw("targetObj: "+targetObjText, pos.x+ 5, pos.y + 5 + 8*12)

		'restore col/alpha
		oldCol.SetRGBA()
	End Method
End Type
