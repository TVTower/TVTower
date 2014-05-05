Type TFigureCollection
	Field list:TList	 		= CreateList()
	Global _eventsRegistered:int= FALSE
	Global _instance:TFigureCollection

	Method New()
		_instance = self

		if not _eventsRegistered
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			_eventsRegistered = TRUE
		Endif
	End Method


	Method Add:int(figure:TFigure)
		List.AddLast(figure)
		List.Sort()
		return TRUE
	End Method


	Method Remove:int(figure:TFigure)
		List.Remove(figure)
		return TRUE
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TFigureCollection", "Savegame loaded - reassigning sprites", LOG_DEBUG | LOG_SAVELOAD)
		For local figure:TFigure = eachin _instance.list
			figure.onLoad()
		Next
	End Function
End Type
Global FigureCollection:TFigureCollection = new TFigureCollection




'Summary: all kind of characters walking through the building (players, terrorists and so on)
Type TFigure extends TSpriteEntity {_exposeToLua="selected"}
	'area: from TEntity
	' .position.y is difference to y of building
	' .dimension.x and .y = "end" of figure in sprite
	Field name:String			= "unknown"
	Field initialdx:Float		= 0.0			'backup of self.velocity.x
	Field PosOffset:TPoint		= new TPoint.Init(0,0)
	Field boardingState:Int		= 0				'0=no boarding, 1=boarding, -1=deboarding

	Field target:TPoint			= Null {_exposeToLua}
	Field targetDoor:TRoomDoor	= Null			'targetting a special door?
	Field targetHotspot:THotspot= Null			'targetting a special hotspot?
	Field isChangingRoom:int	= FALSE			'active as soon as figure leaves/enters rooms
	Field fromDoor:TRoomDoor	= Null			'the door used (there might be multiple)
	Field fromRoom:TRoom		= Null			'coming from room
	Field inRoom:TRoom			= Null
	Field id:Int				= 0

	Field WaitAtElevatorTimer:TIntervalTimer	= TIntervalTimer.Create(25000)
	Field SyncTimer:TIntervalTimer				= TIntervalTimer.Create(2500) 'network sync position timer

	Field ControlledByID:Int		= -1
	Field alreadydrawn:Int			= 0 			{nosave}
	Field ParentPlayerID:int		= 0
	Field SoundSource:TFigureSoundSource = TFigureSoundSource.Create(Self) {nosave}
	Field moveable:int				= TRUE			'whether this figure can move or not (eg. for debugging)
	Field greetOthers:int			= TRUE
	Field useAbsolutePosition:int	= FALSE
	Global LastID:Int				= 0
	Global _initDone:int			= FALSE


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

		FigureCollection.Add(self)


		if not _initdone
			'instead of "room.onLeave" we listen to figure.onLeaveRoom as it has
			'the figure as sender - so we can filter
			EventManager.registerListenerFunction("figure.onLeaveRoom", onLeaveRoom, "TFigure" )
			'same for onEnterRoom
			EventManager.registerListenerFunction("figure.onEnterRoom", onEnterRoom, "TFigure" )

			_initDone = TRUE
		endif

		Return Self
	End Method


	Method New()
		LastID:+1
		id = LastID
	End Method


	Method onLoad:int()
		'reassign sprite
		if sprite and sprite.name then sprite = GetSpriteFromRegistry(sprite.name)

		'reassign rooms
		if inRoom then inRoom = RoomCollection.Get(inRoom.id)
		if fromRoom then fromRoom = RoomCollection.Get(fromRoom.id)
		if fromDoor then fromDoor = TRoomDoor.Get(fromDoor.id)
		'set as room occupier again (so rooms occupant list gets refilled)
		if inRoom and not inRoom.isOccupant(self)
			inRoom.addOccupant(Self)
		endif

	End Method


	Method HasToChangeFloor:Int()
		if not self.target then return FALSE
		Return GetFloor(self.target) <> GetFloor()
	End Method


	Method GetFloor:Int(pos:TPoint = Null)
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
		If ControlledByID = 0 or (Game.GetPlayer(parentPlayerID) and Game.GetPlayer(parentPlayerID).playerKI) Then Return True
		Return False
	End Method


	Method IsActivePlayer:Int()
		return (parentPlayerID = Game.playerID)
	End Method



	Method FigureMovement:int(deltaTime:Float=1.0)
		'figure is in a room, do not move...
		if inRoom then return FALSE

		if not moveable then return FALSE

		'stop movement if changing rooms
		if isChangingRoom then return FALSE

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
			local dx:float = deltaTime * velocity.GetX()
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
					reachTarget()
				else
					'set to elevator-targetx
					oldPosition.setX(targetX) 'set tween position too
					area.position.setX(targetX)
				endif
			endif
		endif

		'decide if we have to play sound
		if velocity.getX() <> 0 and not IsInElevator()
			SoundSource.PlayOrContinueRandomSFX("steps")
		else
			SoundSource.Stop("steps")
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
	Method GetVelocity:TPoint()
		if IsInElevator() then return new TPoint
		return velocity
	End Method


	'returns what animation has to get played in that moment
	Method getAnimationToUse:string()
		local result:string = "standFront"
		'if standing
		If GetVelocity().GetX() = 0 or not moveable
			'default - no movement needed
			If boardingState = 0
				result = "standFront"
			'boarding/deboarding movement
			Else
				'multiply boardingState : if boarding it is 1, if deboarding it is -1
				'so multiplying negates value if needed
				If boardingState * PosOffset.GetX() > 0 Then result = "walkRight"
				If boardingState * PosOffset.GetX() < 0 Then result = "walkLeft"
			EndIf

			'show the backside if at elevator
			If hasToChangeFloor() And Not IsInElevator() And IsAtElevator()
				result = "standBack"
			'going into a room
			ElseIf isChangingRoom and targetDoor
				result = "standBack"
			'show front
			Else
				result = "standFront"
			EndIf
		'if moving
		Else
			If GetVelocity().GetX() > 0 Then result = "walkRight"
			If GetVelocity().GetX() < 0 Then result = "walkLeft"
		EndIf

		return result
	End Method


	Method CanSeeFigure:int(figure:TFigure, range:int=50)
		'being in a room - do not knock on the door :D
		if inRoom OR figure.inRoom then return FALSE
		'from different floors
		If area.GetY() <> Figure.area.GetY() then return FALSE
		'and out of range
		If Abs(area.GetX() - Figure.area.GetX()) > range then return FALSE

		'same spot
		if area.GetX() = figure.area.GetX() then return TRUE
		'right of me
		if area.GetX() < figure.area.GetX()
			'i move to the left
			If velocity.GetX() < 0 then return FALSE
			return TRUE
		'left of me
		else
			'i move to the right
			If velocity.GetX() > 0 then return FALSE
			return TRUE
		endif
		return FALSE
	End Method


	Method GetPeopleOnSameFloor()
		For Local Figure:TFigure = EachIn FigureCollection.List
			'skip other figures
			if self = Figure then continue
			'skip if both can't see each other to me
			if not CanSeeFigure(figure) and not figure.CanSeeFigure(self) then continue

			local greetType:int = 0 'grrLeft,hiLeft,?!left  adding +3 is for right side
			'if both figures are "players" we display "GRRR" or "?!!?"
			If figure.parentPlayerID and parentPlayerID
				'depending on floor use "grr" or "?!"
				greetType = 0 + 2*((1 + GetBuilding().GetFloor(area.GetY()) mod 2)-1)
			else
				greetType = 1
			endif

			'subtract half width from position - figure is drawn centered
			'figure right of me
			If Figure.area.GetX() > area.GetX()
				GetSpriteFromRegistry("gfx_building_textballons").Draw(int(area.GetX() + area.GetW()/2 -2), int(GetBuilding().area.GetY() + area.GetX() - Self.sprite.area.GetH()), greetType, new TPoint.Init(ALIGN_LEFT, ALIGN_CENTER))
			'figure left of me
			else
				greetType :+ 3
				GetSpriteFromRegistry("gfx_building_textballons").Draw(int(area.GetX() - area.GetW()/2 +2), int(GetBuilding().area.GetY() + area.GetY() - Self.sprite.area.GetH()), greetType, new TPoint.Init(ALIGN_RIGHT, ALIGN_CENTER))
			endif
		Next
	End Method


	'player is now in room "room"
	Method _SetInRoom:Int(room:TRoom)
		'in all cases: close the door (even if we cannot enter)
		'Ronny TODO: really needed?
		If room and targetDoor then targetDoor.Close(self)

		If room then room.addOccupant(Self)

		'remove target if we are going in a room
		if room then targetDoor = null

		'backup old room as origin
		fromRoom = inRoom

		'set new room
	 	inRoom = room

		'room change finished
		isChangingRoom = FALSE

	 	'inform AI that we reached a room
	 	If ParentPlayerID > 0 And isAI()
			If room Then Game.GetPlayer(ParentPlayerID).PlayerKI.CallOnReachRoom(room.id) Else Game.GetPlayer(ParentPlayerID).PlayerKI.CallOnReachRoom(LuaFunctions.RESULT_NOTFOUND)
		EndIf

		If Game.networkgame And Network.IsConnected Then Network_SendPosition()
	End Method


    Method CanEnterRoom:Int(room:TRoom)
		If Not room Then Return False
		'nicht besetzt: enter moeglich
		If not room.hasOccupant() or room.allowMultipleOccupants Then Return True

		'sonstige spielfiguren (keine spieler) koennen niemanden rausschmeissen
		'aber auch einfach ueberall rein egal ob wer drin ist
		If Not parentPlayerID Then Return True

		'kann andere rausschmeissen
		If parentPlayerID = room.owner Then Return True

		'sobald besetzt und kein spieler:
		Return False
    End Method


	Method KickFigureFromRoom:Int(kickFigure:TFigure, room:TRoom)
		If Not kickFigure Or Not room Then Return False
		If kickFigure = self then return FALSE

		'fetch at least the main door if none is provided
		local door:TRoomDoor = kickFigure.fromDoor
		if not door then door = TRoomDoor.GetMainDoorToRoom(room)

		TLogger.log("TFigure.KickFigureFromRoom()", name+" kicks "+ kickFigure.name + " out of room: "+room.name, LOG_DEBUG)
		'instead of SimpleSoundSource we use the rooms sound source
		'so we are able to have positioned sound
		if door
			door.GetSoundSource().PlayRandomSFX("kick_figure", door.GetSoundSource().GetPlayerBeforeDoorSettings())
		endif

		'maybe someone is interested in this information
		EventManager.triggerEvent( TEventSimple.Create("room.kickFigure", new TData.Add("figure", kickFigure).Add("door", door), room ) )

		kickFigure.LeaveRoom()
		Return True
	End Method


	'figure wants to enter a room
	'"onEnterRoom" is called when successful
	'@param door					door to use
	'@param room					room to enter (in case no door exists)
	'@param forceEnter				kick without being the room owner
	Method EnterRoom:Int(door:TRoomDoor, room:TRoom, forceEnter:int=FALSE)
		'skip command if we already are entering/leaving
		if isChangingRoom then return TRUE

		'assign room if not done yet
		if not room and door then room = door.room


		'if already in another room, leave that first
		if inRoom then LeaveRoom()

		'RON: if self.id=1 then print "1/4 | figure: EnterRoom | figure.id:"+self.id

		'this sends out an event that we want to enter a room
		'if successfull, event "room.onEnter" will get triggered - which we listen to
		if door then door.Open(self)
		room.Enter(self, forceEnter)
	End Method


	'gets called when the figure really enters the room (animation finished etc)
	Function onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent._sender )
		local room:TRoom = TRoom( triggerEvent.getData().get("room") )

		'RON: if figure.id=1 then print "4/4 | figure: onEnterRoom | figure.id:"+self.id
		figure._setInRoom(room)

		return TRUE
	End Function


	'command to leave a room - "onLeaveRoom" is called when successful
	Method LeaveRoom:Int()
		'skip command if we already are leaving
		if isChangingRoom then return TRUE

		'RON: if self.id=1 then print "1/4 | figure: LeaveRoom | figure.id:"+self.id

		If not inRoom then return TRUE

		'this sends out an event that we want to leave the room
		'if successfull, event "room.onLeave" will get triggered - which we listen to

		inRoom.Leave( self )
	End Method


	'gets called when the figure really leaves the room (animation finished etc)
	Function onLeaveRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent._sender )

'RON: if figure.id=1 then print "4/4 | figure: onLeaveRoom | figure.id:"+self.id

		If Game.GetPlayer(figure.ParentPlayerID) And figure.isAI() then Game.GetPlayer(figure.ParentPlayerID).PlayerKI.CallOnLeaveRoom()

		'enter target -> null = building
		figure._setInRoom( null )


		If Game.networkgame Then If Network.IsConnected Then NetworkHelper.SendFigurePosition(figure)
	End Function



	Method SendToDoor:Int(door:TRoomDoor)
 		If not door then return FALSE

		ChangeTarget(door.Pos.x + 5, GetBuilding().area.position.y + GetBuilding().getfloorY(door.Pos.y) - 5)
	End Method


	Method GoToCoordinatesRelative:Int(relX:Int = 0, relYFloor:Int = 0)
		Local newX:Int = area.GetX() + relX
		Local newY:Int = GetBuilding().area.position.y + GetBuilding().getfloorY(GetFloor() + relYFloor) - 5

		if (newX < 150) then newX = 150 end
		if (newX > 580) then newX = 580 end

 		ChangeTarget(newX, newY)
	End Method


	Function GetByID:TFigure(id:Int)
		For Local Figure:TFigure = EachIn FigureCollection.List
			If Figure.id = id Then Return Figure
		Next
		Return Null
	End Function


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


	Method ChangeTarget:Int(x:Int=-1, y:Int=-1) {_exposeToLua}
		'if player is in elevator dont accept changes
		If GetBuilding().Elevator.passengers.Contains(Self) Then Return False

		'only change target if it's your figure or you are game leader
		If self <> Game.GetPlayer().figure And Not Game.isGameLeader() Then Return False

		'needed for AI like post dude
		If inRoom Then LeaveRoom()

		'reset potential target hotspots, they get refilled if user
		'clicks on one in a later stage
		targetHotspot = null

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
		target = new TPoint.Init(x, GetBuilding().GetFloorY(GetBuilding().GetFloor(y)) )

		'when targeting a room, set target to center of door
		targetDoor = TRoomDoor.GetByCoord(target.x, GetBuilding().area.position.y + target.y)
		If targetDoor then target.setX( targetDoor.pos.x + ceil(targetDoor.doorDimension.x/2) )

		'limit target coordinates
		'on the base floor we can walk outside the buildng, so just check right side
		'target.y contains the floorY so we use "y" which holds clicked floor
		local rightLimit:int = 603' - ceil(rect.GetW()/2) 'subtract half a figure
		local leftLimit:int = 200' + ceil(rect.GetW()/2) 'add half a figure

		if GetBuilding().GetFloor(y) = 0
			If Floor(target.x) >= rightLimit Then target.X = rightLimit
		else
			If Floor(target.x) <= leftLimit Then target.X = leftLimit
			If Floor(target.x) >= rightLimit Then target.X = rightLimit
		endif

		'change to event
		If Game.networkgame Then If Network.IsConnected Then NetworkHelper.SendFigurePosition(Self)

		return TRUE
	End Method


	Method IsGameLeader:Int()
		Return (id = Game.playerID Or (IsAI() And Game.playerID = Game.isGameLeader()))
	End Method


	'overwrite default UpdateMovement - we handle it in FigureMovement
	Method UpdateMovement(deltaTime:Float)
		'nothing
	End Method


	Method IsElevatorCalled:Int()
		For Local floorRoute:TFloorRoute = EachIn GetBuilding().Elevator.FloorRouteList
			If floorRoute.who.id = Self.id
				Return True
			EndIf
		Next
		Return False
	End Method


	Method reachTarget:int()
		velocity.SetX(0)
		'set target as current position - so we are exactly there we want to be
		if target then area.position.setX( target.getX() )
		'remove target
		target = null

		'hotspots are "overlaying" rooms - so more important
		if targetHotspot
			'emit an event
			EventManager.triggerEvent( TEventSimple.Create("figure.onReachTarget", new TData.Add("hotspot", targetHotspot), self ) )

			'remove targeted hotspot
			targetHotspot = null
		endif

		'figure wants to change room
		If not targetHotspot and targetDoor
			'emit an event
			EventManager.triggerEvent( TEventSimple.Create("figure.onReachTarget", new TData.Add("door", targetDoor), self ) )

			If targetDoor.doortype >= 0 And targetDoor.getDoorType() <> 5 And inRoom <> targetDoor.room
				targetDoor.Open(Self)
			endif

			'do not remove the target room as it is done during "entering the room"
			'(which can be animated and so we just trust the method to do it)
			EnterRoom(targetDoor, null)
		EndIf
	End Method


	Method UpdateCustom:int(deltaTime:Float)
		'empty by default
	End Method


	Method Update:int()
		'call parents update (which does movement and updates current
		'animation)
		Super.Update()

		local deltaTime:Float = GetDeltaTimer().GetDelta()

		Self.alreadydrawn = 0

		'movement is not done when in a room
		FigureMovement(deltaTime)
		'set the animation
		GetFrameAnimations().SetCurrent( getAnimationToUse() )

		'this could be overwritten by extended types
		UpdateCustom(deltaTime)



		If isVisible() And (not inRoom Or inRoom.name = "elevatorplaner")
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

		'sync playerposition if not done for long time
		If Game.networkgame And Network.IsConnected And SyncTimer.isExpired()
			Network_SendPosition()
			SyncTimer.Reset()
		EndIf
	End Method


	Method Network_SendPosition()
		NetworkHelper.SendFigurePosition(Self)
	End Method


	Function UpdateAll()
		For Local Figure:TFigure = EachIn FigureCollection.list
			Figure.Update()
		Next
	End Function


	Method Draw:int(overwriteAnimation:String="")
		if not sprite or not isVisible() then return FALSE

		If (not inRoom Or inRoom.name = "elevatorplaner")
			'avoid shaking figures when standing - only use tween
			'position when moving
			local tweenPos:TPoint
			if velocity.GetIntX() <> 0 and not Game.paused
				tweenPos = area.position.Copy()
			else
				tweenPos = oldPosition.Copy()
			endif

			'draw x-centered at current position
			'normal
			'Super.Draw( rect.getX() - ceil(rect.GetW()/2) + PosOffset.getX(), GetBuilding().area.position.y + Self.rect.GetY() - Self.sprite.area.GetH() + PosOffset.getY())
			'tweened with floats
			'Super.Draw( tweenPosX - ceil(rect.GetW()/2) + PosOffset.getX(), GetBuilding().area.position.y + tweenPosY - Self.sprite.area.GetH() + PosOffset.getY())
			'tweened with int
			if useAbsolutePosition
				RenderAt( int(tweenPos.X - ceil(area.GetW()/2) + PosOffset.getX()), int(tweenPos.Y - sprite.area.GetH() + PosOffset.getY()))
			else
				RenderAt( int(tweenPos.X - ceil(area.GetW()/2) + PosOffset.getX()), int(GetBuilding().area.position.y + tweenPos.Y - Self.sprite.area.GetH() + PosOffset.getY()))
			endif
		EndIf

		if greetOthers then Self.GetPeopleOnSameFloor()
	End Method

End Type
