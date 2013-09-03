'Summary: all kind of characters walking through the building (players, terrorists and so on)
Type TFigures Extends TMoveableAnimSprites {_exposeToLua="selected"}
	'rect: from TMoveableAnimSprites
	' .position.y is difference to y of building
	' .dimension.x and .y = "end" of figure in sprite

	Field Name:String			= "unknown"
	Field initialdx:Float		= 0.0 'backup of self.vel.x
	Field target:TPoint			= TPoint.Create(-1,-1) {_exposeToLua}
	Field PosOffset:TPoint		= TPoint.Create(0,0)
	Field boardingState:Int		= 0				'0=no boarding, 1=boarding, -1=deboarding

	Field isChangingRoom:int	= FALSE			'active as soon as figure leaves/enters rooms
	Field targetRoom:TRooms			= Null			{sl = "no"}
	Field fromRoom:TRooms		= Null			{sl = "no"}
	Field inRoom:TRooms			= Null			{sl = "no"}
	Field id:Int				= 0
	Field Visible:Int			= 1

	Field SpecialTimer:TIntervalTimer	= TIntervalTimer.Create(1500)
	Field WaitAtElevatorTimer:TIntervalTimer = TIntervalTimer.Create(25000)
	Field SyncTimer:TIntervalTimer		= TIntervalTimer.Create(2500) 'network sync position timer

	Field ControlledByID:Int	= -1
	Field alreadydrawn:Int		= 0 			{sl = "no"}
	Field updatefunc_(ListLink:TLink, deltaTime:Float) {sl = "no"}
	Field ListLink:TLink						{sl = "no"}
	Field ParentPlayer:TPlayer	= Null			{sl = "no"}
	Field SoundSource:TFigureSoundSource = TFigureSoundSource.Create(Self)

	Global LastID:Int			= 0				{sl = "no"}
	Global List:TList			= CreateList()


	Method CreateFigure:TFigures(FigureName:String, sprite:TGW_Sprites, x:Int, onFloor:Int = 13, dx:Int, ControlledByID:Int = -1)
		Super.Create(sprite, 4, 130)

		Self.insertAnimation("default", TAnimation.Create([ [8,1000] ], -1, 0 ) )

		Self.insertAnimation("walkRight", TAnimation.Create([ [0,130], [1,130], [2,130], [3,130] ], -1, 0) )
		Self.insertAnimation("walkLeft", TAnimation.Create([ [4,130], [5,130], [6,130], [7,130] ], -1, 0) )
		Self.insertAnimation("standFront", TAnimation.Create([ [8,2500], [9,150] ], -1, 0, 500) )
		Self.insertAnimation("standBack", TAnimation.Create([ [10,1000] ], -1, 0 ) )

		Self.name 			= Figurename
		Self.rect			= TRectangle.Create(x, Building.GetFloorY(onFloor), sprite.framew, sprite.frameh )
		Self.target.setX(x)
		Self.vel.SetX(dx)
		Self.initialdx		= dx
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
		Return Building.getFloor(Building.pos.y + target.GetY() ) <> Building.getFloor(Building.pos.y + Self.rect.GetY() )
	End Method


	Method GetFloor:Int(_pos:TPoint = Null)
		If _pos = Null Then _pos = Self.rect.position
		'print self.name + " is on floor: " + Building.getFloor( Building.pos.y + pos.y + sprite.h )
		Return Building.getFloor( Building.pos.y + _pos.y )
	End Method


	Method GetTargetFloor:Int()
		Return Building.getFloor( Building.pos.y + target.y)
	End Method


	Method IsOnFloor:Byte()
		Return rect.GetY() = Building.GetFloorY(GetFloor())
	End Method


	Method GetCenterX:Int()
		Return Ceil(Self.rect.GetX() + Self.rect.GetW()/2)
	End Method


	'ignores y
	Method IsAtElevator:Byte()
		Return Building.Elevator.IsFigureInFrontOfDoor(Self)
	End Method


	Method IsInElevator:Byte()
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
		'stop movement if changing rooms
		if isChangingRoom then return FALSE

		Local targetX:Int = Floor(Self.target.x)
		If target.y=-1 Then target.setPos(Self.rect.position)

		'do we have to change the floor?
		If Self.HasToChangeFloor() Then targetX = Building.Elevator.GetDoorCenterX() - Self.rect.GetW()/2 '-GetW/2 to center figure

		If targetX < Floor(Self.rect.GetX())
			Self.vel.SetX( -(Abs(Self.initialdx)))
			SoundSource.PlayOrContinueSFX(SFX_STEPS)
		EndIf
		If targetX > Floor(Self.rect.GetX())
			Self.vel.SetX(  (Abs(Self.initialdx)))
			SoundSource.PlayOrContinueSFX(SFX_STEPS)
		EndIf

 		If Abs( Floor(targetX) - Floor(Self.rect.GetX()) ) < Abs(deltaTime*Self.vel.GetX())
			Self.vel.SetX(0)
			Self.rect.position.setX(targetX)
			SoundSource.Stop(SFX_STEPS)
		EndIf

		If Not Self.IsInElevator()
			Self.rect.position.MoveXY(deltaTime * Self.vel.GetX(), 0)
			If Not Self.IsOnFloor() Then Self.rect.position.setY( Building.GetFloorY(Self.GetFloor()) )
		Else
			Self.vel.SetX(0)
			SoundSource.Stop(SFX_STEPS)
		EndIf

		'limit player position (only within floor 13 and floor 0 allowed)
		If Self.rect.GetY() < Building.GetFloorY(13) Then Self.rect.position.setY( Building.GetFloorY(13) ) 'beim Vergleich oben nicht "self.sprite.h" abziehen... das war falsch und führt zum Ruckeln im obersten Stock
		If Self.rect.GetY() - Self.sprite.h > Building.GetFloorY( 0) Then Self.rect.position.setY( Building.GetFloorY(0) )
		'limit player position horizontally
	    If Floor(Self.rect.GetX()) <= 200 Then rect.position.setX(200);target.setX(200)
	    If Floor(Self.rect.GetX()) >= 579 Then rect.position.setX(579);target.setX(579)
	End Method


	Method FigureAnimation:int(deltaTime:Float=1.0)
		'if standing
		If Self.vel.GetX() = 0
				'default - no movement needed
				If Self.boardingState = 0
					Self.setCurrentAnimation("standFront",True)
				'boarding/deboarding movement
				Else
					'multiply boardingState : if boarding it is 1, if deboarding it is -1
					'so multiplying negates value if needed
					If Self.boardingState * Self.PosOffset.GetX() > 0 Then Self.setCurrentAnimation("walkRight", True)
					If Self.boardingState * Self.PosOffset.GetX() < 0 Then Self.setCurrentAnimation("walkLeft", True)
				EndIf

			'show the backside if at elevator
			If Self.hasToChangeFloor() And Not IsInElevator() And IsAtElevator()
				Self.setCurrentAnimation("standBack",True)
			'show front
			Else
				Self.setCurrentAnimation("standFront",True)
			EndIf
		'if moving
		Else
			If Self.vel.GetX() > 0 Then Self.setCurrentAnimation("walkRight", True)
			If Self.vel.GetX() < 0 Then Self.setCurrentAnimation("walkLeft", True)
		EndIf
	End Method


	Method GetPeopleOnSameFloor()
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.rect.GetY() = Self.rect.GetY() And Figure <> Self
				If Abs(Figure.rect.GetX() - Self.rect.GetX()) < 50
					If figure.id <= 3 And Self.id <= 3
						If Figure.rect.GetX() > Self.rect.GetX() And Self.vel.GetX() > 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() + rect.GetW(), Building.pos.y + Self.rect.GetY() - Self.sprite.h - 8, 0)
						If Figure.rect.GetX() < Self.rect.GetX() And Self.vel.GetX() < 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX()-18,Building.pos.y + Self.rect.GetY() - Self.sprite.h - 8, 3)
					Else
						If Self.id = figure_HausmeisterID
							If Figure.rect.GetX() > Self.rect.GetX() And Self.vel.GetX() > 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() - 8 + Self.rect.GetW(), Building.pos.y + Self.rect.GetY() - Self.sprite.h - 8, 1)
							If Figure.rect.GetX() < Self.rect.GetX() And Self.vel.GetX() < 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() -18+13,Building.pos.y + Self.rect.GetY() - Self.sprite.h-8, 4)
						Else
							If Figure.rect.GetX() > Self.rect.GetX() And Self.vel.GetX() > 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() + Self.rect.GetW(), Building.pos.y + Self.rect.GetY() - Self.sprite.h - 8, 1)
							If Figure.rect.GetX() < Self.rect.GetX() And Self.vel.GetX() < 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() - 18, Building.pos.y + Self.rect.GetY() - Self.sprite.h - 8, 4)
						EndIf
					EndIf
				EndIf
			EndIf
		Next
	End Method


	'player is now in room "room"
	Method _SetInRoom:Int(room:TRooms)
		'in all cases: close the door (even if we cannot enter)
		If room then room.CloseDoor(self)

		If room <> Null then room.occupant = Self

		'backup old room as origin
		fromRoom = inRoom

		'set new room
	 	inRoom = room

		'room change finished
		isChangingRoom = FALSE

if self.id = 1
	if room
		print "set "+self.id+" to room "+room.name
	else
		print "set "+self.id+" to building"
	endif
endif
	 	'inform AI that we reached a room
	 	If ParentPlayer <> Null And Self.isAI()
			If room Then ParentPlayer.PlayerKI.CallOnReachRoom(room.id) Else ParentPlayer.PlayerKI.CallOnReachRoom(TLuaFunctions.RESULT_NOTFOUND)
		EndIf

		If Game.networkgame And Network.IsConnected Then Self.Network_SendPosition()
	End Method


    Method CanEnterRoom:Int(room:TRooms)
		If Not room Then Return False
		'nicht besetzt: enter moeglich
		If not room.occupant Then Return True

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

		'npcs wie Boten koennen einfach rein
		If Not ParentPlayer
			_SetInRoom(room)
			return TRUE
		endif

		self.isChangingRoom = true

if self.id=1 then print "1/4 | figure: EnterRoom | figure.id:"+self.id

		'this sends out an event that we want to enter a room
		'if successfull, event "room.onEnter" will get triggered - which we listen to
		room.Enter( self, forceEnter )
	End Method


	'gets called when the figure really enters the room (animation finished etc)
	Method onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigures = TFigures( triggerEvent._sender )
		if not figure or figure <> self then return FALSE
		local room:TRooms = TRooms( triggerEvent.getData().get("room") )

if figure.id=1 then print "4/4 | figure: onEnterRoom | figure.id:"+self.id

		_setInRoom(room)

		return TRUE
	End Method


	'command to leave a room - "onLeaveRoom" is called when successful
	Method LeaveRoom:Int()
		'skip command if we already are leaving
		if self.isChangingRoom then return TRUE

if self.id=1 then print "1/4 | figure: LeaveRoom | figure.id:"+self.id

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

if figure.id=1 then print "4/4 | figure: onLeaveRoom | figure.id:"+self.id

		If ParentPlayer And Self.isAI() then ParentPlayer.PlayerKI.CallOnLeaveRoom()

		'enter target -> null = building
		_setInRoom( null )

		targetRoom = Null

		Self.rect.position.setX(target.x)
		If Game.networkgame Then If Network.IsConnected Then NetworkHelper.SendFigurePosition(Self)
	End Method



	Method SendToRoom:Int(room:TRooms)
		If Self.inRoom <> Null then Self.LeaveRoom()
 		If room Then Self.ChangeTarget(room.Pos.x + 5, Building.pos.y + Building.getfloorY(room.Pos.y) - 5)
	End Method

	Method GoToCoordinatesRelative:Int(relX:Int = 0, relYFloor:Int = 0)
		'leave "subrooms"
		For Local i:Int = 0 To 4
			If Self.inRoom <> Null
				'Print "leaving room " + Self.inroom.name
				Self.LeaveRoom()
			Else
				Exit
			EndIf
		Next

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
		If IsAtElevator() Then 'Fahrstuhl darf man nur rufen, wenn man davor steht
			Building.Elevator.CallElevator(Self)
		EndIf
	End Method

	Method GoOnBoardAndSendElevator:Int()
		If Building.Elevator.EnterTheElevator(Self, Self.getFloor(target))
			Building.Elevator.SendElevator(Self.getFloor(target), Self)
		EndIf
	End Method

	Method ChangeTarget:Int(x:Int=Null, y:Int=Null) {_exposeToLua}
		'ego nur ich selbst
		'if not self.parentPlayer or self.parentPlayer.playerID <> 1 then return false

		'needed for AI like post dude
		If Self.inRoom <> Null Then Self.LeaveRoom()

		'only change target if its your figure or you are game leader
		If id <> Game.Players[ game.playerID ].figure.id And Not Game.isGameLeader() Then Return False

		If x=Null Then x=target.x
		If y=Null Then y=target.y

		'if player is in elevator dont accept changes
		If Building.Elevator.passengers.Contains(Self) Then Return False

		'y is not of floor 0 -13
		If Building.GetFloor(y) < 0 Or Building.GetFloor(y) > 13 Then Return False

		'set target x so, that center of figure moves to there
		'set target y to "basement" y of that floor
		target.setXY( x,Building.GetFloorY(Building.GetFloor(y)) )

		'targeting a room ? - add building displace
		Self.targetRoom = TRooms.GetTargetroom(target.x, Building.pos.y + target.y)
		If Self.targetRoom
			'print "clicked to room: "+self.clickedToRoom.name + " "+self.clickedToRoom.pos.x
			target.setX(Self.targetRoom.pos.x +  (Self.targetRoom.name <> "elevator")*Assets.GetSprite("gfx_building_Tueren").framew/2 )
		EndIf

		'center figure to target
		target.setX(target.x - Self.rect.GetW()/2)

'ron290813		inRoom = Null
		'change to event
		If Game.networkgame Then If Network.IsConnected Then NetworkHelper.SendFigurePosition(Self)
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

	Method Update:int(deltaTime:Float)
		'update parent class (anim pos)
		Super.Update(deltaTime)

		Self.alreadydrawn = 0

		If updatefunc_ <> Null
			updatefunc_(ListLink, deltaTime)
		Else
			If id = Game.playerID
				If Self.rect.position.isSame(target)
					If Game.networkgame And Self.SyncTimer.isExpired()
						NetworkHelper.SendFigurePosition(Self)
						Self.SyncTimer.Reset()
					EndIf
				EndIf
			EndIf
			Self.FigureMovement(deltaTime)
			Self.FigureAnimation(deltaTime)
		EndIf
		'figure wants to change room
		If targetRoom 'And targetRoom <> fromRoom
			Local doorCenter:Int = (targetRoom.name <> "elevator")*Assets.GetSprite("gfx_building_Tueren").framew/2

			If Self.ControlledByID >= 0 And Self.id <> figure_HausmeisterID 'in multiplayer to be checked if its the player or not
				'figure center is within 4px wide frame of room "spot" ?
				'if self.ControlledByID = 1 then print "targetx="+target.x+" x="+(pos.x + framewidth/2)+", y="+(Building.pos.y + Building.GetFloorY(toFloor) - 5)+", wx:"+(targetRoom.Pos.x + doorCenter -2)+", wy:"+(Building.pos.y + Building.GetFloorY(targetRoom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h)+" w:"+4+" h:"+54
				If inRoom = Null And functions.IsIn(rect.GetX() + rect.GetW()/2, Building.pos.y + rect.GetY() - 5, targetRoom.Pos.x + doorCenter -2, Building.pos.y + Building.GetFloorY(targetRoom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h, 4, 54)

					If targetRoom.doortype >= 0 And targetRoom.getDoorType() <> 5 And inRoom <> targetRoom
						targetRoom.OpenDoor(Self)
						Self.SetCurrentAnimation("standBack")
					Else
						'RON: show me the back when going into a room
						Self.SetCurrentAnimation("standBack")
						'Self.SetCurrentAnimation("standFront")
					EndIf
					'if open, timer started and reached halftime --> "wait a moment" before entering
					If targetRoom.getDoorType() = 5 And Not targetRoom.DoorTimer.isExpired() And targetRoom.DoorTimer.reachedHalftime()
						targetRoom.CloseDoor(Self)
						EnterRoom(targetRoom)

					ElseIf targetRoom.getDoorType() <> 5 '5 is an open door
					'we stand in front of elevator - and clicked on it (to go to other floors)
						If targetRoom.name = "elevator" And targetRoom.Pos.y = GetFloor() And IsAtElevator()
							'elevator is in our floor and open
							If Building.Elevator.CurrentFloor = targetRoom.Pos.y And Building.Elevator.DoorStatus = 1 'offen
						EnterRoom(targetRoom)
						Building.Elevator.UsePlan(Self)
							'not here or closed
							Else
								CallElevator()
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf

		If Visible And (inRoom = Null Or inRoom.name = "elevator")
			If Self.HasToChangeFloor() And IsAtElevator() And Not IsInElevator()
				Local elevator:TElevator = Building.Elevator

				'TODOX: Blockiert.. weil noch einer aus dem Plan auswählen will

				'Ist der Fahrstuhl da? Kann ich einsteigen?
				If elevator.CurrentFloor = GetFloor() And elevator.ReadyForBoarding
					GoOnBoardAndSendElevator()
				Else 'Ansonsten ruf ich ihn halt
					CallElevator()
				EndIf
			EndIf

			If IsInElevator() 'And elevator.CurrentFloor = GetTargetFloor() And elevator.ReadyForBoarding Then
				Local elevator:TElevator = Building.Elevator
				If elevator.CurrentFloor = GetTargetFloor() And elevator.ReadyForBoarding Then
					elevator.LeaveTheElevator(Self)
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

	Method Draw(_x:Float= -10000, _y:Float = -10000, overwriteAnimation:String="")
		If Visible And (inRoom = Null Or inRoom.name = "elevator")
			If Sprite <> Null
				Super.Draw(Self.rect.GetX() + PosOffset.getX(), Building.pos.y + Self.rect.GetY() - Self.sprite.h + PosOffset.getY())
			EndIf
		EndIf
		Self.GetPeopleOnSameFloor()
	End Method

End Type
