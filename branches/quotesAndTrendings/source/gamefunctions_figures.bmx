'Summary: all kind of characters walking through the building (players, terrorists and so on)
Type TFigures Extends TMoveableAnimSprites {_exposeToLua="selected"}
	'rect: from TMoveableAnimSprites
	' .position.y is difference to y of building
	' .dimension.x and .y = "end" of figure in sprite

	Field Name:String			= "unknown"
	Field initialdx:Float		= 0.0 'backup of self.vel.x
	Field PosOffset:TPoint		= TPoint.Create(0,0)
	Field boardingState:Int		= 0				'0=no boarding, 1=boarding, -1=deboarding

	Field target:TPoint			= Null {_exposeToLua}
	Field targetRoom:TRooms		= Null			'targetting a special room?
	Field targetHotspot:THotspot= Null			'targetting a special hotspot?
	Field isChangingRoom:int	= FALSE			'active as soon as figure leaves/enters rooms
	Field fromRoom:TRooms		= Null
	Field inRoom:TRooms			= Null
	Field id:Int				= 0
	Field Visible:Int			= 1

	Field WaitAtElevatorTimer:TIntervalTimer = TIntervalTimer.Create(25000)
	Field SyncTimer:TIntervalTimer		= TIntervalTimer.Create(2500) 'network sync position timer

	Field ControlledByID:Int	= -1
	Field alreadydrawn:Int		= 0 			{sl = "no"}
	Field updatefunc_(ListLink:TLink, deltaTime:Float) {sl = "no"}
	Field ListLink:TLink						{sl = "no"}
	Field ParentPlayer:TPlayer	= Null			{sl = "no"}
	Field SoundSource:TFigureSoundSource = TFigureSoundSource.Create(Self)
	Field moveable:int			= TRUE	'whether this figure can move or not (eg. for debugging)

	Global LastID:Int			= 0				{sl = "no"}
	Global List:TList			= CreateList()


	Method CreateFigure:TFigures(FigureName:String, sprite:TGW_Sprites, x:Int, onFloor:Int = 13, speed:Int, ControlledByID:Int = -1)
		Super.Create(sprite, 4, 130)

		Self.insertAnimation("default", TAnimation.Create([ [8,1000] ], -1, 0 ) )

		Self.insertAnimation("walkRight", TAnimation.Create([ [0,130], [1,130], [2,130], [3,130] ], -1, 0) )
		Self.insertAnimation("walkLeft", TAnimation.Create([ [4,130], [5,130], [6,130], [7,130] ], -1, 0) )
		Self.insertAnimation("standFront", TAnimation.Create([ [8,2500], [9,250] ], -1, 0, 500) )
		Self.insertAnimation("standBack", TAnimation.Create([ [10,1000] ], -1, 0 ) )

		Self.name 			= Figurename
		Self.rect			= TRectangle.Create(x, Building.GetFloorY(onFloor), sprite.framew, sprite.frameh )
'		Self.vel.SetX(speed)
		Self.vel.SetX(0)
		Self.initialdx		= speed
		Self.Sprite			= sprite
		Self.ControlledByID	= ControlledByID

		'instead of "room.onLeave" we listen to figure.onLeaveRoom as it has
		'the figure as sender - so we can filter
		EventManager.registerListenerMethod( "figure.onLeaveRoom", self, "onLeaveRoom", self )
		'same for onEnterRoom
		EventManager.registerListenerMethod( "figure.onEnterRoom", self, "onEnterRoom", self )

		Return Self
	End Method


	Method New()
		LastID:+1
		id		= LastID
		ListLink= List.AddLast(Self)
		List.Sort()
	End Method


	Function Load:TFigures(pnode:txmlNode, figure:TFigures)
Print "implement Load:TFigures"
Return Null
	End Function


	Function LoadAll()
		Local figureID:Int = 1
		Local Children:TList = LoadSaveFile.node.getChildren()
		For Local node:txmlNode = EachIn Children
			If node.getName() = "FIGURES_CHILD"
				Local Figure:TFigures = TFigures.GetByID(figureID)
				figureID:+1
				If Figure <> Null Then Figure = TFigures.Load(NODE, Figure)
				If Figure = Null Then Print "Figure.LoadAll: Figure Missing";Exit
			End If
		Next
		'Print "loaded figure informations"
	End Function


	Function AdditionalLoad(obj:Object, node:txmlNode)
Print "implement additionalLoad"
Return
	End Function


	Function AdditionalSave(obj:Object)
		Local figure:TFigures = TFigures(obj)
		If figure <> Null
			If figure.targetRoom <> Null Then LoadSaveFile.xmlWrite("TARGETROOMID", figure.targetRoom.id) Else LoadSaveFile.xmlWrite("TARGETROOMID", "-1")
			If figure.fromRoom <> Null Then LoadSaveFile.xmlWrite("FROMROOMID", figure.FromRoom.id) Else LoadSaveFile.xmlWrite("FROMROOMID", "-1")
			If figure.inRoom <> Null Then LoadSaveFile.xmlWrite("INROOMID", figure.inRoom.id) Else LoadSaveFile.xmlWrite("INROOMID", "-1")
		EndIf
	End Function


	Method HasToChangeFloor:Int()
		if not self.target then return FALSE
		Return GetFloor(self.target) <> GetFloor()
	End Method


	Method GetFloor:Int(_pos:TPoint = Null)
		'if we have no floor set in the pos, we return the current floor
		If not _pos Then _pos = Self.rect.position
		Return Building.getFloor( Building.pos.y + _pos.y )
	End Method

	Method IsOnFloor:Int()
		Return rect.GetY() = Building.GetFloorY(GetFloor())
	End Method


	'ignores y
	Method IsAtElevator:int()
		Return Building.Elevator.IsFigureInFrontOfDoor(Self)
	End Method


	Method IsInElevator:int()
		Return Building.Elevator.IsFigureInElevator(Self)
	End Method


	Method IsAI:Int()
		If id > 4 Then Return True
		If Self.ControlledByID = 0 or (self.parentPlayer and self.parentPlayer.playerKI) Then Return True
		Return False
	End Method


	Method IsActivePlayer:Int()
		return (self.parentPlayer and self.parentPlayer.playerID = Game.playerID)
	End Method



	Method FigureMovement:int(deltaTime:Float=1.0)
		'figure is in a room, do not move...
		if inRoom then return FALSE

		if not moveable then return FALSE

		'stop movement if changing rooms
		if isChangingRoom then return FALSE

		'stop movement, will get set to a value if we have a target to move to
		self.vel.setX(0)

		'we have a target to move to
		if target
			'get a temporary target coordinate so we can manipulate that safely
			Local targetX:Int = Self.target.getIntX()

			'do we have to change the floor?
			'if that is the case - change temporary target to elevator
			If Self.HasToChangeFloor() Then targetX = Building.Elevator.GetDoorCenterX()

			'check whether the target is left or right side of the figure
			If targetX < Self.rect.GetX()
				Self.vel.SetX( -(Abs(Self.initialdx)))
			ElseIf targetX > Self.rect.GetX()
				Self.vel.SetX(  (Abs(Self.initialdx)))
			EndIf


			'does the center of the figure will reach the target during?
			local dx:float = deltaTime * Self.vel.GetX()
			local reachTemporaryTarget:int = FALSE
			'move to right and next step is more right than target
			if dx > 0 and ceil(self.rect.getX())+dx >= targetX then reachTemporaryTarget=true
			'move to left and next step is more left than target
			if dx < 0 and ceil(self.rect.getX())+dx <= targetX then reachTemporaryTarget=true
			'we stand in front of the target
			if dx = 0 and abs(self.rect.getX() - targetX)<1.0 then reachTemporaryTarget=true

			'we reached our current target (temp or real)
			If reachTemporaryTarget
				'we reached our real target
				if not Self.HasToChangeFloor()
					self.reachTarget()
				else
					'set to elevator-targetx
					rect.position.setX( targetX )
				endif
			endif
		endif

		'decide if we have to play sound
		if self.vel.getX() <> 0 and not IsInElevator()
			SoundSource.PlayOrContinueSFX(SFX_STEPS)
		else
			SoundSource.Stop(SFX_STEPS)
		EndIf

		'do real moving
		doMove(deltaTime)
	End Method

	Method doMove(deltaTime:float)
		If Not Self.IsInElevator()
			Self.rect.position.MoveXY(deltaTime * Self.vel.GetX(), 0)
			If Not Self.IsOnFloor() Then Self.rect.position.setY( Building.GetFloorY(Self.GetFloor()) )
		Else
			Self.vel.SetX(0)
		EndIf

		'limit player position (only within floor 13 and floor 0 allowed)
		If Self.rect.GetY() < Building.GetFloorY(13) Then Self.rect.position.setY( Building.GetFloorY(13) ) 'beim Vergleich oben nicht "self.sprite.h" abziehen... das war falsch und führt zum Ruckeln im obersten Stock
		If Self.rect.GetY() - Self.sprite.h > Building.GetFloorY( 0) Then Self.rect.position.setY( Building.GetFloorY(0) )
		'limit player position horizontally
	    If Floor(Self.rect.GetX()) <= 200 Then self.changeTarget(200);self.reachTarget()
	    If Floor(Self.rect.GetX()) >= 579 Then self.changeTarget(579);self.reachTarget()
	End Method

	'returns what animation has to get played in that moment
	Method getAnimationToUse:string()
		local result:string = "standFront"
		'if standing
		If Self.vel.GetX() = 0 or not self.moveable
			'default - no movement needed
			If Self.boardingState = 0
				result = "standFront"
			'boarding/deboarding movement
			Else
				'multiply boardingState : if boarding it is 1, if deboarding it is -1
				'so multiplying negates value if needed
				If Self.boardingState * Self.PosOffset.GetX() > 0 Then result = "walkRight"
				If Self.boardingState * Self.PosOffset.GetX() < 0 Then result = "walkLeft"
			EndIf

			'show the backside if at elevator
			If Self.hasToChangeFloor() And Not IsInElevator() And IsAtElevator()
				result = "standBack"
			'going into a room
			ElseIf isChangingRoom and targetRoom
				result = "standBack"
			'show front
			Else
				result = "standFront"
			EndIf
		'if moving
		Else
			If Self.vel.GetX() > 0 Then result = "walkRight"
			If Self.vel.GetX() < 0 Then result = "walkLeft"
		EndIf

		return result
	End Method


	Method GetPeopleOnSameFloor()
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.rect.GetY() = Self.rect.GetY() And Figure <> Self
				If Abs(Figure.rect.GetX() - Self.rect.GetX()) < 50
					If figure.id <= 3 And Self.id <= 3
						If Figure.rect.GetX() > Self.rect.GetX() And Self.vel.GetX() > 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() + rect.GetW(), Building.pos.y + Self.rect.GetY() - Self.sprite.h - 8, 0)
						If Figure.rect.GetX() < Self.rect.GetX() And Self.vel.GetX() < 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX()-18,Building.pos.y + Self.rect.GetY() - Self.sprite.h - 8, 3)
					Else
						If Figure.rect.GetX() > Self.rect.GetX() And Self.vel.GetX() > 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() + Self.rect.GetW(), Building.pos.y + Self.rect.GetY() - Self.sprite.h - 8, 1)
						If Figure.rect.GetX() < Self.rect.GetX() And Self.vel.GetX() < 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() - 18, Building.pos.y + Self.rect.GetY() - Self.sprite.h - 8, 4)
					EndIf
				EndIf
			EndIf
		Next
	End Method


	'player is now in room "room"
	Method _SetInRoom:Int(room:TRooms)
		'in all cases: close the door (even if we cannot enter)
		If room then room.CloseDoor(self)

		If room then room.addOccupant(Self)

		'remove target Room if we are going in a room
		if room then targetRoom = null

		'backup old room as origin
		fromRoom = inRoom

		'set new room
	 	inRoom = room

		'room change finished
		isChangingRoom = FALSE

	 	'inform AI that we reached a room
	 	If ParentPlayer <> Null And Self.isAI()
			If room Then ParentPlayer.PlayerKI.CallOnReachRoom(room.id) Else ParentPlayer.PlayerKI.CallOnReachRoom(TLuaFunctions.RESULT_NOTFOUND)
		EndIf

		If Game.networkgame And Network.IsConnected Then Self.Network_SendPosition()
	End Method


    Method CanEnterRoom:Int(room:TRooms)
		If Not room Then Return False
		'nicht besetzt: enter moeglich
		If not room.hasOccupant() or room.allowMultipleOccupants Then Return True

		'sonstige spielfiguren (keine spieler) koennen niemanden rausschmeissen
		'aber auch einfach ueberall rein egal ob wer drin ist
		If Not Self.parentPlayer Then Return True

		'kann andere rausschmeissen
		If Self.parentPlayer.playerID = room.owner Then Return True

		'sobald besetzt und kein spieler:
		Return False
    End Method

	Method KickFigureFromRoom:Int(kickFigure:TFigures, room:TRooms)
		If Not kickFigure Or Not room Then Return False

		Print "Figur "+Self.name+" schmeisst "+ kickFigure.name + " aus dem Raum "+room.name
		Print "<--- hier nen Rausschmeiss-Sound - auch per Event einbindbar"
		'maybe someone is interested in this information
		EventManager.triggerEvent( TEventSimple.Create("room.kickFigure", TData.Create().Add("figure", kickFigure), room ) )

		kickFigure.LeaveRoom()
		Return True
	End Method


	'figure wants to enter a room
	'"onEnterRoom" is called when successful
	'@param room					room to enter
	'@param forceEnter				kick without being the room owner
	'@param canShowFadeAnimation	are we allowed to show a fader?
	Method EnterRoom:Int(room:TRooms, forceEnter:int=FALSE, canShowFadeAnimation:int=TRUE)
		'skip command if we already are entering/leaving
		if self.isChangingRoom then return TRUE

		'if already in another room, leave that first
		if self.inRoom then self.LeaveRoom()

'RON: if self.id=1 then print "1/4 | figure: EnterRoom | figure.id:"+self.id

		'this sends out an event that we want to enter a room
		'if successfull, event "room.onEnter" will get triggered - which we listen to
		room.Enter( self, forceEnter )
	End Method


	'gets called when the figure really enters the room (animation finished etc)
	Method onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigures = TFigures( triggerEvent._sender )
		if not figure or figure <> self then return FALSE
		local room:TRooms = TRooms( triggerEvent.getData().get("room") )

'RON: if figure.id=1 then print "4/4 | figure: onEnterRoom | figure.id:"+self.id

		_setInRoom(room)

		return TRUE
	End Method


	'command to leave a room - "onLeaveRoom" is called when successful
	Method LeaveRoom:Int()
		'skip command if we already are leaving
		if self.isChangingRoom then return TRUE

'RON: if self.id=1 then print "1/4 | figure: LeaveRoom | figure.id:"+self.id

		If not Self.inRoom
			'also reset from (from nothing to nothing :D)
			EnterRoom(null)
			return TRUE
		endif
		'this sends out an event that we want to leave the room
		'if successfull, event "room.onLeave" will get triggered - which we listen to
		self.inRoom.Leave( self )
	End Method


	'gets called when the figure really leaves the room (animation finished etc)
	Method onLeaveRoom:int( triggerEvent:TEventBase )
		local figure:TFigures = TFigures( triggerEvent._sender )
		if not figure or figure <> self then return FALSE

'RON: if figure.id=1 then print "4/4 | figure: onLeaveRoom | figure.id:"+self.id

		If ParentPlayer And Self.isAI() then ParentPlayer.PlayerKI.CallOnLeaveRoom()

		'enter target -> null = building
		_setInRoom( null )


		If Game.networkgame Then If Network.IsConnected Then NetworkHelper.SendFigurePosition(Self)
	End Method



	Method SendToRoom:Int(room:TRooms)
 		If room Then Self.ChangeTarget(room.Pos.x + 5, Building.pos.y + Building.getfloorY(room.Pos.y) - 5)
	End Method

	Method GoToCoordinatesRelative:Int(relX:Int = 0, relYFloor:Int = 0)
		Local newX:Int = Self.rect.GetX() + relX
		Local newY:Int = Building.pos.y + Building.getfloorY(self.GetFloor() + relYFloor) - 5

		if (newX < 150) then newX = 150 end
		if (newX > 580) then newX = 580 end

 		Self.ChangeTarget(newX, newY)
	End Method


	Function GetByID:TFigures(id:Int)
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.id = id Then Return Figure
		Next
		Return Null
	End Function


	Method CallElevator:Int()
		'ego nur ich selbst
		'if not self.parentPlayer or self.parentPlayer.playerID <> 1 then return false

		If IsElevatorCalled() Then Return False 'Wenn er bereits gerufen wurde, dann abbrechen

		'Wenn der Fahrstuhl schon da ist, dann auch abbrechen. TODOX: Muss überprüft werden
		If Building.Elevator.CurrentFloor = GetFloor() And IsAtElevator() Then Return False

		'Fahrstuhl darf man nur rufen, wenn man davor steht
		If IsAtElevator() Then Building.Elevator.CallElevator(Self)
	End Method


	Method GoOnBoardAndSendElevator:Int()
		if not target then return FALSE
		If Building.Elevator.EnterTheElevator(Self, Self.getFloor(target))
			Building.Elevator.SendElevator(Self.getFloor(target), Self)
		EndIf
	End Method


	Method ChangeTarget:Int(x:Int=-1, y:Int=-1) {_exposeToLua}
		'if player is in elevator dont accept changes
		If Building.Elevator.passengers.Contains(Self) Then Return False

		'only change target if it's your figure or you are game leader
		If self <> Game.GetPlayer().figure And Not Game.isGameLeader() Then Return False

		'needed for AI like post dude
		If Self.inRoom Then Self.LeaveRoom()

		'only a partial target was given
		if x=-1 or y=-1
			'change current target
			if target
				If x<>-1 Then x = target.x
				If y<>-1 Then y = target.y
			'create a new target
			else
				If x=-1 Then x = rect.position.x
				If y=-1 Then y = rect.position.y
			endif
		endif

		'y is not of floor 0 -13
		If Building.GetFloor(y) < 0 Or Building.GetFloor(y) > 13 Then Return False

		'set new target, y is recalculated to "basement"-y of that floor
		target = TPoint.Create(x, Building.GetFloorY(Building.GetFloor(y)) )

		'when targeting a room, set target to center of door
		targetRoom = TRooms.GetTargetroom(target.x, Building.pos.y + target.y)
		If targetRoom then target.setX( targetRoom.pos.x + ceil(targetRoom.doorDimension.x/2) )

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
		For Local floorRoute:TFloorRoute = EachIn Building.Elevator.FloorRouteList
			If floorRoute.who.id = Self.id
				Return True
			EndIf
		Next
		Return False
	End Method


	Method reachTarget:int()
		vel.SetX(0)
		'set target as current position - so we are exactly there we want to be
		if target then rect.position.setX( target.getX() )
		'remove target
		target = null

		'hotspots are "overlaying" rooms - so more important
		if targetHotspot
			'emit an event
			EventManager.triggerEvent( TEventSimple.Create("figure.onReachTarget", TData.Create().Add("hotspot", targetHotspot), self ) )

			'remove targeted hotspot
			targetHotspot = null
		endif

		'figure wants to change room
		If not targetHotspot and targetRoom 'and not inRoom
			'emit an event
			EventManager.triggerEvent( TEventSimple.Create("figure.onReachTarget", TData.Create().Add("room", targetRoom), self ) )

			If targetRoom.doortype >= 0 And targetRoom.getDoorType() <> 5 And inRoom <> targetRoom
				targetRoom.OpenDoor(Self)
			endif

			'do not remove the target room as it is done during "entering the room"
			'(which can be animated and so we just trust the method to do it)
			EnterRoom(targetRoom)
		EndIf
	End Method


	Method UpdateCustom:int(deltaTime:Float)
		'empty by default
	End Method


	Method Update:int(deltaTime:Float)

		'update parent class (anim pos)
		Super.Update(deltaTime)

		Self.alreadydrawn = 0

		'movement is not done when in a room
		FigureMovement(deltaTime)

		'set the animation
		setCurrentAnimation( getAnimationToUse() )

		'this could be overwritten by extended types
		self.UpdateCustom(deltaTime)


		If Visible And (not inRoom Or inRoom.name = "elevatorplaner")
			If HasToChangeFloor() And IsAtElevator() And Not IsInElevator()
				'TODOX: Blockiert.. weil noch einer aus dem Plan auswählen will

				'Ist der Fahrstuhl da? Kann ich einsteigen?
				If Building.Elevator.CurrentFloor = GetFloor() And Building.Elevator.ReadyForBoarding
					GoOnBoardAndSendElevator()
				Else 'Ansonsten ruf ich ihn halt
					CallElevator()
				EndIf
			EndIf

			If IsInElevator() and Building.Elevator.ReadyForBoarding
				If (not target OR Building.Elevator.CurrentFloor = GetFloor(target))
					Building.Elevator.LeaveTheElevator(Self)
				EndIf
			EndIf
		EndIf

		'sync playerposition if not done for long time
		If Game.networkgame And Network.IsConnected And Self.SyncTimer.isExpired()
			Self.Network_SendPosition()
			Self.SyncTimer.Reset()
		EndIf
	End Method

	Method Network_SendPosition()
		NetworkHelper.SendFigurePosition(Self)
	End Method

	Function UpdateAll(deltaTime:Float)
		For Local Figure:TFigures = EachIn TFigures.List
			Figure.Update(deltaTime)
		Next
	End Function

	Method Draw:int (_x:Float= -10000, _y:Float = -10000, overwriteAnimation:String="")
		if not sprite or not Visible then return FALSE

		If (not inRoom Or inRoom.name = "elevatorplaner")
			'draw x-centered at current position
			Super.Draw( rect.getX() - ceil(rect.GetW()/2) + PosOffset.getX(), Building.pos.y + Self.rect.GetY() - Self.sprite.h + PosOffset.getY())
		EndIf
		Self.GetPeopleOnSameFloor()
	End Method

End Type
