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
			collection.entriesID = _instance.entriesID
			collection.entriesGUID = _instance.entriesGUID
			collection.entriesCount = _instance.entriesCount
			'now the new collection is the instance
			_instance = collection
		endif
		return TFigureCollection(_instance)
	End Function


	Method Get:TFigure(ID:int) override
		Return TFigure(Super.Get(ID))
	End Method


	Method GetByName:TFigure(name:string) override
		Return TFigure(Super.GetByName(name))
	End Method


	Method GetByGUID:TFigure(guid:string) override
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
	'going to room
	Field inRoom:TRoomBase = Null
	
	Field beginLeaveRoomTime:Long
	Field finishLeaveRoomTime:Long
	Field beginEnterRoomTime:Long
	Field finishEnterRoomTime:Long

	'network sync position timer
	Field SyncTimer:TIntervalTimer = TIntervalTimer.Create(2500)

	Field _soundSource:TSoundSourceElement {nosave}
	'use the building coordinates or is the area absolute positioned?
	Field useAbsolutePosition:int = FALSE


	Method Create:TFigure(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		'adjust sprite animations

		SetSprite(sprite)
		GetFrameAnimations().Add(new TSpriteFrameAnimation("default", [ [8,1000] ], -1, 0 ) )
		GetFrameAnimations().Add(new TSpriteFrameAnimation("walkRight", [ [0,130], [1,130], [2,130], [3,130] ], -1, 0) )
		GetFrameAnimations().Add(new TSpriteFrameAnimation("walkLeft", [ [4,130], [5,130], [6,130], [7,130] ], -1, 0) )
		GetFrameAnimations().Add(new TSpriteFrameAnimation("standFront", [ [8,2500], [9,250] ], -1, 0, 500) )
		GetFrameAnimations().Add(new TSpriteFrameAnimation("standBack", [ [10,1000] ], -1, 0 ) )
'local coll:TSpriteFrameAnimationCollection = GetFrameAnimations()
'debugstop
		name = Figurename
		area = new TRectangle.Init(x, TBuildingBase.GetFloorY2(onFloor), sprite.framew, sprite.frameh )
		velocity.SetX(0)
		initialdx = abs(speed)

		GetFigureCollection().Add(self)

		if not _initdone
			_initDone = TRUE
		endif

		Return Self
	End Method


	'override
	Method RemoveFromCollection:Int(collection:object = null)
		'if collection = GetFigureCollection() ...
		if _soundSource
			GetSoundManagerBase().RemoveSoundSource(_soundSource)
		EndIf
	End Method


	Method GetSoundSource:TSoundSourceElement()
		if not _soundSource then _soundSource = TFigureBaseSoundSource.Create(Self)
		return _soundSource
	End Method


	Method onGamePause:int() override
		GetSoundSource().Stop("steps")
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
		Return GetFloor( GetMoveToPosition().y ) <> GetFloor()
	End Method


	'return the current floor
	Method GetFloor:Int()
		Return GetBuildingBase().getFloor(area.y)
	End Method

	'return floor of given y position
	Method GetFloor:Int(y:Float)
		Return GetBuildingBase().getFloor(y)
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
			WaitEnterTimer = GetBuildingTime().GetTimeGone() + WaitEnterLeavingTime
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
			Local targetX:Int = GetMoveToPosition().x

			'we stand in front of the target -> reach target!
			if GetVelocity().x = 0 and abs(area.getX() - targetX) < 1.0
				return True
			endif
		endif
		return False
	End Method


	Method FigureMovement:int()
		'stop movement, will get set to a value if we have a target to move to
		velocity.SetX(0)

		'we have a target to move to and are not yet entering it
		'check if we reach it now
		'skip if in elevator (avoids starting to move while doors are not
		'opened yet)
		if GetTarget() and currentReachTargetStep = 0 and not IsInElevator()
			'does the center of the figure will reach the target during update?
			'can happen even when not able to move (manual position set
			'or target acquired without moving)
			local reachTemporaryTarget:int = FALSE
			'get a temporary target coordinate so we can manipulate that safely
			Local targetX:Int = GetMoveToPosition().x
			'do we have to change the floor?
			'if that is the case - change temporary target to elevator
			If HasToChangeFloor() Then targetX = GetElevator().GetDoorCenterX()

			'we stand in front of the target -> reach target!
			if GetVelocity().x = 0 and abs(area.x - targetX) < 1.0 then reachTemporaryTarget=true

			'if able to move, check if the movement will lead to reaching
			'the target
			if CanMove()
				'check whether the target is left or right side of the figure
				If targetX < area.x
					velocity.SetX( -(Abs(initialdx)))
				ElseIf targetX > area.x
					velocity.SetX(  (Abs(initialdx)))
				EndIf

				local dx:float = GetVelocity().x * GetDeltaTime()
				'move to right and next step is more right than target
				if dx > 0 and ceil(area.x + dx) >= targetX then reachTemporaryTarget=true
				'move to left and next step is more left than target
				if dx < 0 and ceil(area.x + dx) <= targetX then reachTemporaryTarget=true
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
					area.SetX(targetX)

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
				if not IsWaitingToEnter() and CanEnterTarget() 'and (currentAction = ACTION_IDLE or currentAction = ACTION_PLANNED_ENTER)
					WaitEnterTimer = -1
					if not EnterTarget() then print "Enter target failed. Figure: " + name
				endif
			endif
		endif


		'decide if we have to play sound
		if GetGameBase().gamestate <> TGameBase.STATE_RUNNING
			GetSoundSource().Stop("steps")
		Else
			if GetVelocity().x <> 0 and not IsInElevator() and not GetBuildingTime().TooFastForSound() 
				GetSoundSource().PlayOrContinueRandomSFX("steps")
			else
				GetSoundSource().Stop("steps")
			EndIf
		EndIf


		'adjust/limit position based on location
		If Not IsInElevator()
			If Not IsOnFloor() and not useAbsolutePosition Then area.SetY( TBuildingBase.GetFloorY2(GetFloor()) )
		EndIf

		'limit player position (only within floor 13 and floor 0 allowed)
		if not useAbsolutePosition
			'beim Vergleich oben nicht "self.sprite.area.GetH()" abziehen... das war falsch und f�hrt zum Ruckeln im obersten Stock
			If area.y < TBuildingBase.GetFloorY2(13) Then area.SetY( TBuildingBase.GetFloorY2(13) )
			If area.y - sprite.area.h > TBuildingBase.GetFloorY2(0) Then area.SetY( TBuildingBase.GetFloorY2(0) )
		endif

		return true
	End Method


	'overwrite default to add stoppers (at elevator)
	Method GetVelocity:SVec2F() override
		if IsInElevator() then return new SVec2F(0,0)
		return new SVec2F(velocity.x, velocity.y)
	End Method


	'returns what animation has to get played in that moment
	Method GetAnimationToUse:string()
		'fetch the animation for walking and standing
		local result:string = Super.GetAnimationToUse()

		'check for special animations
		If GetVelocity().x = 0 or not moveable
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
			'a) planning to enter a room
			'b) not moving but wants to go to somewhere (also show back 
			'   if room is used and enter not possible "for now").
			'   Also avoids "front back front"-alternation of figures
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
		For Local Figure:TFigure = EachIn GetFigureCollection() '.GetEntriesID().Values()
			'skip other figures
			if self = Figure then continue
			'skip if both can't see each other to me
			if not CanSeeFigure(figure) and not figure.CanSeeFigure(self) then continue


			local greetType:int = GetGreetingTypeForFigure(figure)

			'if the greeting type differs
			'- or enough time has gone for another greet
			'- or another figure gets greeted
			if greetType <> lastGreetType or GetBuildingTime().GetTimeGone() - lastGreetTime > greetEvery or lastGreetFigureID <> figure.id
				lastGreetType = greetType
				lastGreetFigureID = figure.id

				lastGreetTime = GetBuildingTime().GetTimeGone()
			endif

			'show greet for a maximum time of "showGreetTime"
			if GetBuildingTime().GetTimeGone() - lastGreetTime < greetTime
				local scale:float = TInterpolation.BackOut(0.0, 1.0, Min(greetTime, GetBuildingTime().GetTimeGone() - lastGreetTime), greetTime)
				local oldAlpha:float = GetAlpha()
				SetAlpha Float(TInterpolation.RegularOut(0.5, 1.0, Min(0.5*greetTime, GetBuildingTime().GetTimeGone() - lastGreetTime), 0.5*greetTime))
				'subtract half width from position - figure is drawn centered
				'figure right of me
				If Figure.area.GetX() > area.GetX()
					'draw the "to the right" balloon a bit lower (so both are better visible)
					GetSpriteFromRegistry("gfx_building_textballons").Draw(int(GetScreenRect().GetX() + area.GetW()/2 -2), int(GetScreenRect().GetY() - sprite.area.GetH() + 2), greetType, ALIGN_LEFT_CENTER, scale)
				'figure left of me
				else
					greetType :+ 3
					GetSpriteFromRegistry("gfx_building_textballons").Draw(int(GetScreenRect().GetX() - area.GetW()/2 +2), int(GetScreenRect().GetY() - sprite.area.GetH()), greetType, ALIGN_RIGHT_CENTER, scale)
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
		if room.GetName() = "boss" then return True

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
		If roomName
			Local _inRoom:TRoomBase = inRoom
			If inRoom
				Local name:String = inRoom.GetName()
				If name.length = roomname.length
					If name.toLower() = roomname.toLower()
						Return True
					EndIf
				EndIf
			EndIf
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

		'set new room
	 	inRoom = room

		'inform others that room is changed
		TriggerBaseEvent(GameEventKeys.Figure_SetInRoom, null, self, inroom)
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
			TLogger.log("TFigure.KickFigureOutOfRoom()", kickingFigure.name+" kicks "+ name + " out of room: "+inRoom.GetDescription(), LOG_DEBUG)
		else
			TLogger.log("TFigure.KickFigureOutOfRoom()", name + " gets kicked out of room: "+inRoom.GetDescription(), LOG_DEBUG)
		endif
		'instead of SimpleSoundSource we use the rooms sound source
		'so we are able to have positioned sound
		if TRoomDoor(door)
			TRoomDoor(door).GetSoundSource().PlayRandomSFX("kick_figure", TRoomDoor(door).GetSoundSource().GetPlayerBeforeDoorSettings())
		endif

		'maybe someone is interested in this information
		TriggerBaseEvent(GameEventKeys.Room_KickFigure, new TData.Add("figure", self).Add("door", door), GetInRoom())

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
		'inform that figure now starts the "entering the room" process
		'(eg. for players informing the ai)
		TriggerBaseEvent(GameEventKeys.Figure_OnEnterRoom, new TData.Add("room", room).Add("door", door) , self, room)

		'Debug
		'print "--------------------------------------------"
		'if playerID = 1
		'		print self.name+" ENTERING " + room.GetName() +" ["+room.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"
		'endif

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

			'disabled check if there is someone in already
			'(CanEnterRoom() already checks if occupant allows us to enter)
			'If room.hasOccupant() and not room.isOccupant(self)
			FailEnterRoom(room, door, "inuse")
			return FALSE
			'EndIf
		endif

		'ask if somebody is against going into the room
		local event:TEventBase = TEventBase.Create(GameEventKeys.Figure_OnTryEnterRoom, new TData.Add("door", door) , self, room )
		event.Trigger()
		'stop entering
		if event.IsVeto() then return False

		return True
	End Method


	Method BeginEnterRoom:int(door:TRoomDoorBase, room:TRoomBase)
		'set time of start
		changingRoomBuildingTimeStart = GetBuildingTime().GetTimeGone()
		changingRoomBuildingTimeEnd = GetBuildingTime().GetTimeGone() + changingRoomTime
		changingRoomRealTimeStart = Time.GetTimeGone()
		changingRoomRealTimeEnd = Time.GetTimeGone() + changingRoomTime
		'inform what the figure does now
		currentAction = ACTION_ENTERING

		'reset wait timer
		WaitEnterTimer = -1

		'Debug
		'if playerID = 1
		'	print self.name+" START ENTERING " + room.GetName() +" ["+room.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"
		'endif
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

		self.beginEnterRoomTime = Time.GetTimeGone()
		self.finishEnterRoomTime = -1
		self.beginLeaveRoomTime = -1
		self.finishLeaveRoomTime = -1


		'set figure already "inRoom" in that moment
		'(room adds occupant too on "BeginEnter")
		'print self.name+" SET IN ROOM  (" + Time.GetSystemTime("%H:%I:%S") +")"
		SetInRoom(room)

		'inform room
		room.BeginEnter(door, self, changingRoomTime)

		'=== INFORM OTHERS ===
		'inform that figure now begins entering the room
		'(eg. for players informing the ai)
		TriggerBaseEvent(GameEventKeys.Figure_OnBeginEnterRoom, null, self, room)

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
		if door and not room then print "FinishEnterRoom : NO ROOM for roomID: " + door.roomID

		'Debug
		rem
		if playerID = 1
			local roomName:string = "UNKNOWN"
			if room
				roomName = room.name + " ["+room.id+"]"
			else
				if inRoom then roomName = inRoom.name+" [inRoom] ["+inRoom.id+"]"
			endif
			print self.name+" FINISH ENTERING " + roomName +"  (" + Time.GetSystemTime("%H:%I:%S") +")"
			'print "--------------------------------------------"
		endif
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

		self.finishEnterRoomTime = Time.GetTimeGone()
		self.beginLeaveRoomTime = -1
		self.finishLeaveRoomTime = -1

		'inform room
		if room then room.FinishEnter(self)


		'=== INFORM OTHERS ===
		local hasT:int = GetTarget() <> null
		'inform that figure now entered the room
		'(eg. for players informing the ai)
		TriggerBaseEvent(GameEventKeys.Figure_OnFinishEnterRoom, new TData.Add("room", room).Add("door", door) , self, room)

		return True
	End Method


	Method FailEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase, reason:String)
		'=== INFORM OTHERS ===
		'inform that figure failed to enter the room
		'(eg. for players informing the ai)
		TriggerBaseEvent(GameEventKeys.Figure_OnFailEnterRoom, new TData.AddString("reason", reason).Add("door", door), self, room)

		'Debug
		'print self.name+" FAILED ENTERING " + room.GetName() +" ["+room.id+"]"

		'reset action
		'currentAction = ACTION_IDLE
		'stay looking at the door
		if not room.IsBlocked()
			currentAction = ACTION_PLANNED_ENTER
		endif

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
		'non-players (also delivery boys and terrorists!) have some
		'kind of master key
		'player figures need to gain them (via betty love!)
		if not HasKeyForRoom(room) then return False

		return room.CanEntityEnter(self)
	End Method


	'command to leave a room - "onLeaveRoom" is called when successful
	Method LeaveRoom:Int(forceLeave:Int=False)
		'skip command if in no room or already leaving
		if not inRoom or IsLeavingRoom() then return True

		'=== INFORM OTHERS ===
		'inform that figure now begins leaving the room
		'(eg. for players informing the ai)
		TriggerBaseEvent(GameEventKeys.Figure_OnLeaveRoom, null, self, inRoom )


		local target:object = GetTargetObject()
		if TRoomDoorBase(target)
			local door:TRoomDoorBase = TRoomDoorBase(target)
			if inRoom and inRoom.id = door.roomID
				TLogger.Log("TFigure.LeaveRoom", "Removing current target of ~q"+name+"~q as we are already leaving that room (eg. got kicked?).", LOG_DEBUG)
				RemoveCurrentTarget()
			endif
		endif

		'Debug
		'if playerID = 1
			'print self.name+" LEAVING " + inRoom.GetName() +" ["+inRoom.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"
			'if GetTarget() then print " ... has target"
		'endif

		'=== CHECK IF LEAVING IS ALLOWED ===
		'skip leaving if not allowed to do so
		if not forceLeave and not CanLeaveRoom(inroom) then return False

		'ask if somebody is against leaving that room
		if not TryLeaveRoom( forceLeave )
			return False
		endif

		'inform that a figure forcefully leaves a room (so GUI or so can
		'get cleared)
		if forceLeave
			TriggerBaseEvent(GameEventKeys.Figure_OnForcefullyLeaveRoom, new TData.Add("door", usedDoor) , self, inroom)
		endif

		BeginLeaveRoom()

		return True
	End Method


	Method TryLeaveRoom:int(forceLeave:int = False)
		'inform others but ignore the result if figure is forced to leave
		local event:TEventBase = TEventBase.Create(GameEventKeys.Figure_OnTryLeaveRoom, new TData.Add("door", usedDoor) , self, inroom )
		EventManager.triggerEvent(event)
		'stop leaving
		if not forceLeave and event.IsVeto() then return False

		return True
	End Method


	Method BeginLeaveRoom:int()
		'set time of start
		changingRoomBuildingTimeStart = GetBuildingTime().GetTimeGone()
		changingRoomBuildingTimeEnd = GetBuildingTime().GetTimeGone() + changingRoomTime
		changingRoomRealTimeStart = Time.GetTimeGone()
		changingRoomRealTimeEnd = Time.GetTimeGone() + changingRoomTime

		'inform what the figure does now
		currentAction = ACTION_LEAVING

		'Debug
		'if playerID = 1
		'	print self.name+" START LEAVING " + inRoom.GetName() +" ["+inRoom.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"
		'endif

		self.beginLeaveRoomTime = Time.GetTimeGone()

		'do not fade when it is a fake room
		fadeOnChangingRoom = True
		if inRoom.ShowsOccupants() then fadeOnChangingRoom = False

		inRoom.BeginLeave(usedDoor, self, changingRoomTime)

		'=== INFORM OTHERS ===
		'inform that figure now leaves the room
		'(eg. for players informing the ai)
		TriggerBaseEvent(GameEventKeys.Figure_OnBeginLeaveRoom, null, self, inroom)

		return True
	End Method


	'gets called when the figure really left the room
	Method FinishLeaveRoom()
		local inRoomBackup:TRoomBase = inRoom
		'Debug
		'if playerID = 1
		'	print self.name+" FINISHED LEAVING " + inRoom.GetName() +" ["+inRoom.id+"]  (" + Time.GetSystemTime("%H:%I:%S") +")"
		'endif

		'enter target -> null = building
		SetInRoom( null )

		'remove used door
		usedDoor = null

		'reset action
		currentAction = ACTION_IDLE

		'activate timer to wait a bit after leaving a room
		WaitLeavingTimer = GetBuildingTime().GetTimeGone() + WaitEnterLeavingTime

		self.finishLeaveRoomTime = Time.GetTimeGone()

		inRoomBackup.FinishLeave(self)

		'=== INFORM OTHERS ===
		'inform that figure now leaves the room
		'(eg. for players informing the ai)
		TriggerBaseEvent(GameEventKeys.Figure_OnFinishLeaveRoom, null, self, inRoomBackup )
	End Method


	Method CanLeaveRoom:Int(room:TRoomBase)
		'cannot leave if room forbids
		if not room.CanEntityLeave(self) then return False

		return True
	End Method
	
	
	Method SendToHotspot:Int(h:THotspot, forceSend:Int=False)
		If Not h Then Return False
		
		Local target:TFigureTargetBase = new TFigureTarget.Init(h)
		Local moveToPos:SVec2I = GetMoveToPosition( target )
		If Not moveToPos
			print "SendToHotspot: failed, moveToPos = null"
			Return False
		EndIf

		If forceSend
			ForceChangeTarget(moveToPos.x, moveToPos.y)
			SetTarget( target )
		Else
			ChangeTarget(moveToPos.x, moveToPos.y)
			SetTarget( target )
		EndIf
		Return True
	End Method
	

	Method SendToDoor:Int(door:TRoomDoorBase, forceSend:Int=False)
 		If not door then return False

		local moveToPos:SVec2I = GetMoveToPosition( new TFigureTarget.Init(door) )
		if moveToPos.x = -1000 or moveToPos.y = -1000
			print "SendToDoor: failed, moveToPos = null"
			return False
		endif

		If forceSend
			ForceChangeTarget(moveToPos.x, moveToPos.y)
		Else
			ChangeTarget(moveToPos.x, moveToPos.y)
		EndIf
		
		Return True
	End Method
	
	
	'send to a door, hotspot... defined by the given ID
	Method SendToTarget:Int(targetID:Int, forceSend:Int=False)
		Local target:Object = GetBuildingBase().GetTarget(targetID)
		If Not target Then Return False
		
		If TRoomDoor(target)
			Return SendToDoor(TRoomDoor(target), forceSend)
		ElseIf THotspot(target)
			Return SendToHotspot(THotspot(target), forceSend)
		EndIf
	End Method


	Method SendToTarget:Int(target:Object, forceSend:Int=False) override
		If TRoomDoor(target)
			Return SendToDoor(TRoomDoor(target), forceSend)
		ElseIf THotspot(target)
			Return SendToHotspot(THotspot(target), forceSend)
		ElseIf target <> Null
			Throw "unsupported target passed to SendToTarget(). Target type=" + TTypeID.ForObject(target).name()
		EndIf
		Return Null
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
		area.SetXY(GetBuildingBase().figureOffscreenX, TBuildingBase.GetFloorY2(0))
	End Method


	Method IsOffscreen:int()
		if GetFloor() = 0 and area.GetX() <= GetBuildingBase().figureOffscreenX then return True
		return False
	End Method


	Method GoToCoordinatesRelative:Int(relX:Int = 0, relYFloor:Int = 0)
		Local newX:Int = area.x + relX
		Local newY:Int = GetBuildingBase().area.y + TBuildingBase.GetFloorY2(GetFloor() + relYFloor) - 5

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
		Local floorOfTargetY:Int = GetFloor(GetMoveToPosition().y)
		If GetElevator().EnterTheElevator(Self, floorOfTargetY)
			GetElevator().SendElevator(floorOfTargetY, Self)
		EndIf
	End Method


	'overridden
	'change the target of the figure
	'@forceChange   defines wether the target could change target
	'               even when not controllable
	Method _ChangeTarget:Int(x:Int=-1, y:Int=-1, forceChange:Int=False)
		'reset target reach
		currentReachTargetStep = 0
		'if enter failed and we now move to somewhere else, we would
		'show the back once we reach a spot somewhere in the building 
		'(not a door)
		If currentAction = ACTION_PLANNED_ENTER
			currentAction = ACTION_IDLE
		EndIf

		'is controlling allowed (eg. figure MUST go to a specific target)
		if not forceChange and not IsControllable() then Return False

		'if player is in elevator dont accept changes
		if not forceChange and IsInElevator() Then Return False

		reachedTemporaryTarget = False

		'=== CALCULATE NEW TARGET/TARGET-OBJECT ===
		'only a partial target was given
		if x=-1 or y=-1
			Local v:TVec2D = TVec2D(GetTargetObject())
			'change current target
			if v
				If x<>-1 Then x = v.x
				If y<>-1 Then y = v.y
			'create a new target
			else
				If x=-1 Then x = area.x
				If y=-1 Then y = area.y
			endif
		endif

		'y is not of floor 0 -13
		If GetBuildingBase().GetFloor(y) < 0 Or GetBuildingBase().GetFloor(y) > 13 Then Return False


		Local newTarget:object = Null
		Local newTargetCoord:SVec2I

		'set new target, y is recalculated to "basement"-y of that floor
		newTargetCoord = new SVec2I(x, TBuildingBase.GetFloorY2(GetBuildingBase().GetFloor(y)) )


		'when targeting a room, set target to center of door
		local targetedDoor:TRoomDoorBase = GetRoomDoorBaseCollection().GetByCoord(Int(newTargetCoord.x), Int(newTargetCoord.y))
		if targetedDoor
			'move to this door
			newTargetCoord = TFigureTarget.GetMoveToPosition(targetedDoor)
			
			'only go into the room if we were able to target it from our
			'source position
			If not targetedDoor.HasFlag(TVTRoomDoorFlag.ONLY_TARGETABLE_ON_SAME_FLOOR) or targetedDoor.onFloor = GetFloor()
				'found valid "non position" target
				newTarget = targetedDoor
			EndIf
		endif
		
		
		'nothing (valid) found at the position? target becomes a position
		If Not newTarget
			newTarget = New TVec2D(newTargetCoord.x, newTargetCoord.y)
		EndIf
		

		'limit target coordinates when moving to a specific x,y pos, not
		'a specific door/hotspot/...
		If TVec2D(newTarget)
			'on the base floor we can walk outside the building, so just
			'check right side
			'target.y contains the floorY so we use "y" which holds clicked
			'floor

			'TODO: do this in a GetLimitX() method to make it overrideable
			'      by bigger figures - like the the janitor
			local rightLimit:int = TBuildingBase.floorWidth-15 '603
			local leftLimit:int = 15 '200

			if GetBuildingBase().GetFloor(y) = 0
				If newTargetCoord.x >= rightLimit Then TVec2D(newTarget).x = rightLimit
			else
				If newTargetCoord.x <= leftLimit Then TVec2D(newTarget).x = leftLimit
				If newTargetCoord.x >= rightLimit Then TVec2D(newTarget).x = rightLimit
			endif
		EndIf


		'=== CHECK IF ALREADY THERE ===
		'check if figure is already at this target
		'RONNY: REALLY NEEDED? - bugs out AI in rooms (sometimes) as
		'       GetTarget() might return a new one already
		'if newTarget and newTarget = GetTarget() then return False
		'-> alternative: check coordinates

		if GetTargetObject()
			'new target and current target are the same
			if newTarget = GetTargetObject() then return False
			'new target and current target coordinates are at the same?
			if TVec2D(newTarget) and TVec2D(newTarget).IsSame( GetMoveToPosition() ) then return False

			'print playerID+": targets are different " + TVec2D(newTarget).x+","+TVec2D(newTarget).y+" vs " + GetMoveToPosition().x+","+GetMoveToPosition().y
		endif


		local targetRoom:TRoomBase
		if TRoomDoor(newTarget) then targetRoom = TRoomDoor(newTarget).GetRoom()
		'skip moving if already in this room
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
		TriggerBaseEvent(GameEventKeys.Figure_OnChangeTarget, new TData.AddNumber("x", x).AddNumber("y", y).AddNumber("forceChange", forceChange), self, null )

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
			if WaitEnterTimer > 0 and WaitEnterTimer + 5000 < GetBuildingTime().GetTimeGone()
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
	End Method


	Method Update:int()
		if IsChangingRoom()
			if GetBuildingTime().GetTimeGone() > changingRoomBuildingTimeEnd or ..
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
					If (not GetTarget() OR GetElevator().CurrentFloor = GetFloor(GetMoveToPosition().y))
						GetElevator().LeaveTheElevator(Self)
					EndIf
				EndIf
			EndIf
		Endif


		'maybe someone is interested in this information
		If SyncTimer.isExpired()
			TriggerBaseEvent(GameEventKeys.Figure_OnSyncTimer, Null, self)
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
			local smallestTime:Long = GetBuildingTime().GetTimeGone() - changingRoomBuildingTimeStart
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


		local renderPos:SVec2F = GetRenderAtPosition()
		RenderAt(Int(renderPos.x), Int(renderPos.y))

		SetAlpha(oldAlpha)

		if greetOthers then GreetPeopleOnSameFloor()
	End Method


	Method GetRenderAtPosition:SVec2F()
		'avoid shaking figures when standing - only use tween
		'position when moving
		local tweenPosX:Float
		local tweenPosY:Float

		'also do not move with WorldTime being paused
		'alternatively (also do not move when gamespeed is "0")
		'-> and GetWorldTime().GetTimeFactor() > 0
		if Int(velocity.x) <> 0 and not GetWorldTime().IsPaused()
			Local tween:Float = GetDeltaTimer().GetTween() 
			tweenPosX = MathHelper.SteadyTween(oldPosition.x, area.x, tween)
			tweenPosY = MathHelper.SteadyTween(oldPosition.y, area.y, tween)
		else
			tweenPosX = area.x
			tweenPosY = area.y
		endif

		'center figure
		tweenPosX :+ -Float(ceil(area.w/2)) + PosOffset.x
		tweenPosY :+ -sprite.area.h + PosOffset.y

		return new SVec2F(tweenPosX, tweenPosY)
	End Method
End Type




Type TFigureTarget extends TFigureTargetBase
	'override
	Method CanEnter:int()
		If not Super.CanEnter() then return False

		return True
	End Method


	Function GetMoveToPosition:SVec2I(target:object)
		If TVec2D(target) 
			Return New SVec2I(int(TVec2D(target).x), int(TVec2D(target).y))
		ElseIf TRoomDoorBase(target)
			Local door:TRoomDoorBase = TRoomDoorBase(target)
			Return New SVec2I(Int(door.area.x + door.area.w/2 + door.stopOffset), Int(door.area.y))
		ElseIf THotspot(target)
			Local hotspot:THotspot = THotspot(target)
			'attention: return GetY2() (bottom point) as this is used for figures too
			Return New SVec2I(Int(hotspot.area.x + hotspot.area.w/2), Int(hotspot.area.GetY2()))
		EndIf
		Return New SVec2I(-1000,-1000)
	End Function
End Type
