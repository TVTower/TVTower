'Summary: all kind of characters walking through the building (players, terrorists and so on)
Type TFigures extends TMoveableAnimSprites {_exposeToLua="selected"}
	'rect: from TMoveableAnimSprites
	' .position.y is difference to y of building
	' .dimension.x and .y = "end" of figure in sprite

	Field Name:String			= "unknown"
	Field initialdx:Float		= 0.0 'backup of self.vel.x
	field target:TPoint			= TPoint.Create(-1,-1) {_exposeToLua}
	Field PosOffset:TPoint		= TPoint.Create(0,0)
	Field boardingState:int		= 0				'0=no boarding, 1=boarding, -1=deboarding

	Field toRoom:TRooms			= Null			{sl = "no"}
	Field fromRoom:TRooms		= Null			{sl = "no"}
	Field clickedToRoom:TRooms	= Null			{sl = "no"}
	Field inRoom:TRooms			= Null			{sl = "no"}
	Field id:Int				= 0
	Field Visible:Int			= 1

	Field SpecialTimer:TTimer	= TTimer.Create(1500)
	Field WaitAtElevatorTimer:TTimer = TTimer.Create(25000)
	Field SyncTimer:TTimer		= TTimer.Create(2500) 'network sync position timer

	Field ControlledByID:Int	= -1
	Field alreadydrawn:Int		= 0 			{sl = "no"}
	Field updatefunc_(ListLink:TLink, deltaTime:float) {sl = "no"}
	Field ListLink:TLink						{sl = "no"}
	Field ParentPlayer:TPlayer	= Null			{sl = "no"}

	Global LastID:Int			= 0				{sl = "no"}
	Global List:TList			= CreateList()


	Function Load:TFigures(pnode:txmlNode, figure:TFigures)
print "implement Load:TFigures"
return null
rem
		Local node:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(figure)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("sl") <> "no" And Upper(t.name()) = NODE.name
					t.Set(figure, nodevalue)
				EndIf
			Next
			AdditionalLoad(figure, NODE)
			Node = Node.NextSibling()
		Wend
		Return Figure
endrem
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
print "implement additionalLoad"
return
rem
		Local figure:TFigures = TFigures(obj)
		If figure <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Select NODE.name
				Case "TOROOMID" 		figure.toRoom = TRooms.GetRoomFromID(Int(nodevalue))
				Case "FROMROOMID" 		figure.fromRoom = TRooms.GetRoomFromID(Int(nodevalue))
				Case "CLICKEDTOROOMID"	figure.clickedToRoom = TRooms.GetRoomFromID(Int(nodevalue))
				Case "INROOMID"			figure.inRoom = TRooms.GetRoomFromID(Int(nodevalue))
			End Select
			figure.NextAnimTimer = MilliSecs()
		EndIf
endrem
	End Function

	Function AdditionalSave(obj:Object)
		Local figure:TFigures = TFigures(obj)
		If figure <> Null
			If figure.toRoom <> Null Then LoadSaveFile.xmlWrite("TOROOMID", figure.toRoom.id) Else LoadSaveFile.xmlWrite("TOROOMID", "-1")
			If figure.fromRoom <> Null Then LoadSaveFile.xmlWrite("FROMROOMID", figure.FromRoom.id) Else LoadSaveFile.xmlWrite("FROMROOMID", "-1")
			If figure.clickedToRoom <> Null Then LoadSaveFile.xmlWrite("CLICKEDTOROOMID", figure.ClickedToRoom.id) Else LoadSaveFile.xmlWrite("CLICKEDTOROOMID", "-1")
			If figure.inRoom <> Null Then LoadSaveFile.xmlWrite("INROOMID", figure.inRoom.id) Else LoadSaveFile.xmlWrite("INROOMID", "-1")
		EndIf
	End Function

	Method HasToChangeFloor:int()
		return Building.getFloor(Building.pos.y + target.GetY() ) <> Building.getFloor(Building.pos.y + self.rect.GetY() )
	End Method

	Method GetFloor:int(_pos:TPoint = null)
		if _pos = null then _pos = self.rect.position
		'print self.name + " is on floor: " + Building.getFloor( Building.pos.y + pos.y + sprite.h )
		Return Building.getFloor( Building.pos.y + _pos.y )
	End Method

	Method GetTargetFloor:int()
		Return Building.getFloor( Building.pos.y + target.y)
	End Method

	Method IsOnFloor:Byte()
		return rect.GetY() = Building.GetFloorY(GetFloor())
	End Method

	Method GetCenterX:int()
		Return ceil(self.rect.GetX() + self.rect.GetW()/2)
	End Method

	'ignores y
	Method IsAtElevator:Byte()
		return Building.Elevator.IsFigureInFrontOfDoor(self)
	End Method

	Method IsInElevator:Byte()
		Return Building.Elevator.IsFigureInElevator(self)
	End Method

	Method IsAI:Int()
		If id > 4 Then Return True
	'	If Game.networkgame Then If id < 4 Then If Network.IP[id - 1] = Null Then Return True
		if self.ControlledByID = 0 then return true
		Return False
	End Method

	Method IsActivePlayer:Int()
		If id = 1 Then Return true 'TODO: Man müsste hier noch prüfen, ob andere Spieler gesteuert werden außer id = 1
		Return false
	End Method

	Method FigureMovement(deltaTime:float=1.0)
		local targetX:int = floor(self.target.x)
		if target.y=-1 then target.setPos(self.rect.position)

		'do we have to change the floor?
		if self.HasToChangeFloor() then targetX = Building.Elevator.GetDoorCenterX() - self.rect.GetW()/2 '-GetW/2 to center figure

		If targetX < Floor(Self.rect.GetX()) Then Self.vel.SetX( -(Abs(Self.initialdx)))
		If targetX > Floor(Self.rect.GetX()) Then Self.vel.SetX(  (Abs(Self.initialdx)))

 		If Abs( Floor(targetX) - Floor(Self.rect.GetX()) ) < Abs(deltaTime*Self.vel.GetX())
			Self.vel.SetX(0)
			Self.rect.position.setX(targetX)
		endif

		If not Self.IsInElevator()
			Self.rect.position.MoveXY(deltaTime * Self.vel.GetX(), 0)
			If Not Self.IsOnFloor() Then Self.rect.position.setY( Building.GetFloorY(Self.GetFloor()) )
		Else
			Self.vel.SetX(0)
		EndIf

		'limit player position (only within floor 13 and floor 0 allowed)
		If self.rect.GetY() < Building.GetFloorY(13) Then self.rect.position.setY( Building.GetFloorY(13) ) 'beim Vergleich oben nicht "self.sprite.h" abziehen... das war falsch und führt zum Ruckeln im obersten Stock
		If self.rect.GetY() - self.sprite.h > Building.GetFloorY( 0) Then self.rect.position.setY( Building.GetFloorY(0) )
		'limit player position horizontally
	    If Floor(self.rect.GetX()) <= 200 Then rect.position.setX(200);target.setX(200)
	    If Floor(self.rect.GetX()) >= 579 Then rect.position.setX(579);target.setX(579)
	End Method

	Method FigureAnimation(deltaTime:float=1.0)
		If self.vel.GetX() = 0
				'default - no movement needed
				if self.boardingState = 0
					self.setCurrentAnimation("standFront",true)
				'boarding/deboarding movement
				else
					'multiply boardingState : if boarding it is 1, if deboarding it is -1
					'so multiplying negates value if needed
					if self.boardingState * self.PosOffset.GetX() > 0 then self.setCurrentAnimation("walkRight", true)
					if self.boardingState * self.PosOffset.GetX() < 0 then self.setCurrentAnimation("walkLeft", true)
				endif

			'show the backside if at elevator
			If self.hasToChangeFloor() and not IsInElevator() and IsAtElevator()
				self.setCurrentAnimation("standBack",true)
			'show front
			Else
			EndIf
		EndIf
		if self.vel.GetX() > 0 then self.setCurrentAnimation("walkRight", true)
		if self.vel.GetX() < 0 then self.setCurrentAnimation("walkLeft", true)
	End Method

	Method GetPeopleOnSameFloor()
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.rect.GetY() = Self.rect.GetY() And Figure <> Self
				If Abs(Figure.rect.GetX() - Self.rect.GetX()) < 50
					If figure.id <= 3 And Self.id <= 3
						If Figure.rect.GetX() > Self.rect.GetX() And self.vel.GetX() > 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() + rect.GetW(), Building.pos.y + self.rect.GetY() - self.sprite.h - 8, 0)
						If Figure.rect.GetX() < Self.rect.GetX() And self.vel.GetX() < 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX()-18,Building.pos.y + self.rect.GetY() - self.sprite.h - 8, 3)
					Else
						If Self.id = figure_HausmeisterID
							If Figure.rect.GetX() > Self.rect.GetX() And self.vel.GetX() > 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() - 8 + self.rect.GetW(), Building.pos.y + self.rect.GetY() - self.sprite.h - 8, 1)
							If Figure.rect.GetX() < Self.rect.GetX() And self.vel.GetX() < 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() -18+13,Building.pos.y + self.rect.GetY() - self.sprite.h-8, 4)
						Else
							If Figure.rect.GetX() > Self.rect.GetX() And self.vel.GetX() > 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() + self.rect.GetW(), Building.pos.y + self.rect.GetY() - self.sprite.h - 8, 1)
							If Figure.rect.GetX() < Self.rect.GetX() And self.vel.GetX() < 0 Then Assets.GetSprite("gfx_building_textballons").Draw(Self.rect.GetX() - 18, Building.pos.y + self.rect.GetY() - self.sprite.h - 8, 4)
						EndIf
					EndIf
				EndIf
			EndIf
		Next
	End Method

	'player is now in room "room"
	Method _SetInRoom:Int(room:TRooms)
		If room <> null Then room.CloseDoor()

		room.used = self.id

	 	inRoom = room
		If ParentPlayer <> Null And self.isAI()
			If room Then ParentPlayer.PlayerKI.CallOnReachRoom(room.id) Else ParentPlayer.PlayerKI.CallOnReachRoom(TLuaFunctions.RESULT_NOTFOUND)
		EndIf
		If Game.networkgame and Network.IsConnected then self.Network_SendPosition()
	End Method

    Method CanEnterRoom:int(room:TRooms)
		if not room then return false
		'nicht besetzt: enter moeglich
		if room.used < 0 then return true

		'sonstige spielfiguren (keine spieler) koennen niemanden rausschmeissen
		'aber auch einfach ueberall rein egal ob wer drin ist
		if not self.parentPlayer then return true

		'kann andere rausschmeissen
		if self.parentPlayer.playerID = room.owner then return true

		'sobald besetzt und kein spieler:
		return false
    End Method


	Method EnterRoom:int(room:TRooms, useFader:int = true)
		'no room = going to building
		if not room then return _SetInRoom(null)

		'npcs wie Boten koennen einfach rein
		if not ParentPlayer then _SetInRoom(room)

		'besetzt - und jemand anderes ?
		if room.used >=0 and room.used <> self.id
			'nur richtige Spieler benoetigen spezielle Behandlung (events etc.)
			if ParentPlayer <> null
				'andere rausschmeissen
				if self.parentPlayer.playerID = room.owner
					'andere rausschmeissen
					local kickFigure:TFigures = TFigures.GetByID(room.used)
					if kickFigure
						print "Figur "+self.name+" schmeisst "+ kickFigure.name + " aus dem Raum "+room.name
						EventManager.triggerEvent( TEventSimple.Create("room.kickFigure", TData.Create().Add("figure", kickFigure), room ) )

						kickFigure.LeaveRoom()
					endif
					If useFader and id = Game.playerID Then Fader.EnableFadeout() 'room fading
					_SetInRoom(room)
				'Besetztzeichen ausgeben / KI informieren
				else
					'ziel entfernen
					self.toRoom = null
					self.clickedToRoom = null

					'Spieler benachrichtigen
					if self.isAI()
						ParentPlayer.PlayerKI.CallOnReachRoom(TLuaFunctions.RESULT_INUSE)
					else
						'tooltip only for user
						if self.parentPlayer.playerID = Game.playerID
							Building.CreateRoomUsedTooltip(room)
'							print room.name +" ist besetzt"
						endif
					endif
				endif
			endif
		else
			If useFader and id = Game.playerID Then Fader.EnableFadeout() 'room fading
			_SetInRoom(room)
		endif
	End Method

	Method LeaveToBuilding:int()
		self.inRoom = null
	End Method

	Method LeaveRoom:Int()
		if self.inRoom
			print self.name+" leaves room:"+self.inRoom.name

			'set unused
			self.inRoom.used = -1

			If ParentPlayer And self.isAI()
				If Players[ParentPlayer.PlayerKI.playerId].Figure.inRoom <> Null
					'Print "LeaveRoom:"+Players[ParentPlayer.PlayerKI.playerId].Figure.inRoom.name
					If Players[ParentPlayer.PlayerKI.playerId].figure.inRoom.name = "movieagency"
						 TMovieAgencyBlocks.ProgrammeToPlayer(ParentPlayer.PlayerKI.playerId)
						 'Print "movieagency left: programmes bought"
					EndIf
				EndIf
				ParentPlayer.PlayerKI.CallOnLeaveRoom()
			EndIf
		endif
		'display a open door if leaving it
		If inRoom Then inRoom.OpenDoor()

		toRoom = fromRoom
'		If fromRoom <> Null Then fromRoom.CloseDoor()
		fromRoom = Null
		EnterRoom( toRoom )

		clickedToRoom = Null
		If inRoom = Null Then self.rect.position.setX(target.x)
		If Game.networkgame Then If Network.IsConnected Then NetworkHelper.SendFigurePosition(self)
		'EndIf
	End Method

	Method SendToRoom:Int(room:TRooms)
		'leave "subrooms"
		For Local i:Int = 0 To 4
			If Self.inRoom <> Null
				'Print "leaving room " + Self.inroom.name
				Self.LeaveRoom()
			Else
				Exit
			EndIf
		Next
 		If room <> Null Then Self.ChangeTarget(room.Pos.x + 5, Building.pos.y + Building.getfloorY(room.Pos.y) - 5)
	End Method

	Function GetByID:TFigures(id:Int)
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.id = id Then Return Figure
		Next
		Return Null
	End Function

	Method New()
		LastID:+1
		id		= LastID
		ListLink= List.AddLast(self)
		List.Sort()
	End Method

	Method CreateFigure:TFigures(FigureName:String, sprite:TGW_Sprites, x:Int, onFloor:Int = 13, dx:Int, ControlledByID:Int = -1)
		super.Create(sprite, 4, 130)

		self.insertAnimation("default", TAnimation.Create([ [8,1000] ], -1, 0 ) )

		self.insertAnimation("walkRight", TAnimation.Create([ [0,130], [1,130], [2,130], [3,130] ], -1, 0) )
		self.insertAnimation("walkLeft", TAnimation.Create([ [4,130], [5,130], [6,130], [7,130] ], -1, 0) )
		self.insertAnimation("standFront", TAnimation.Create([ [8,2500], [9,150] ], -1, 0, 500) )
		self.insertAnimation("standBack", TAnimation.Create([ [10,1000] ], -1, 0 ) )


		self.name 			= Figurename
		self.rect			= TRectangle.Create(x, Building.GetFloorY(onFloor), sprite.framew, sprite.frameh )
		self.target.setX(x)
		self.vel.SetX(dx)
		self.initialdx		= dx
		self.Sprite			= sprite
		self.ControlledByID	= ControlledByID
		Return self
	End Method

	Method CallElevator:Int()
		if IsElevatorCalled() then return false 'Wenn er bereits gerufen wurde, dann abbrechen

		'Wenn der Fahrstuhl schon da ist, dann auch abbrechen. TODOX: Muss überprüft werden
		if Building.Elevator.CurrentFloor = GetFloor() and IsAtElevator() then return false
		If IsAtElevator() Then 'Fahrstuhl darf man nur rufen, wenn man davor steht
			Building.Elevator.CallElevator(self)
		Endif
	End Method

	Method GoOnBoardAndSendElevator:Int()
		If Building.Elevator.EnterTheElevator(self, self.getFloor(target))
			Building.Elevator.SendElevator(self.getFloor(target), self)
		Endif
	End Method

	Method ChangeTarget(x:Int=null, y:Int=null) {_exposeToLua}
		'needed for AI like post dude
		if self.inRoom <> null then self.LeaveRoom()

		'only change target if its your figure or you are game leader
		if id <> Players[ game.playerID ].figure.id and not Game.isGameLeader() then return

		if x=null then x=target.x
		if y=null then y=target.y

		'if player is in elevator dont accept changes
		If Building.Elevator.passengers.Contains(Self) then return

		'y is not of floor 0 -13
		If Building.GetFloor(y) < 0 OR Building.GetFloor(y) > 13 then return

		'set target x so, that center of figure moves to there
		'set target y to "basement" y of that floor
		target.setXY( x,Building.GetFloorY(Building.GetFloor(y)) )

		'targeting a room ? - add building displace
		self.clickedToRoom = TRooms.GetTargetroom(target.x, Building.pos.y + target.y)
		if self.clickedToRoom <> null
			'print "clicked to room: "+self.clickedToRoom.name + " "+self.clickedToRoom.pos.x
			target.setX(self.clickedToRoom.pos.x +  (self.clickedToRoom.name <> "elevator")*Assets.GetSprite("gfx_building_Tueren").framew/2 )
		endif

		'center figure to target
		target.setX(target.x - self.rect.GetW()/2)

		inRoom = Null
		'change to event
		If Game.networkgame Then If Network.IsConnected Then NetworkHelper.SendFigurePosition(self)
	End Method

	Method IsGameLeader:Int()
		Return (id = Game.playerID Or (IsAI() And Game.playerID = Game.isGameLeader()))
	End Method

	'overwrite default UpdateMovement - we handle it in FigureMovement
	Method UpdateMovement(deltaTime:float)
		'nothing
	End Method

	Method IsElevatorCalled:int()
		For Local floorRoute:TFloorRoute = EachIn Building.Elevator.FloorRouteList
			If floorRoute.who.id = self.id
				Return true
			Endif
		Next
		Return false
	End Method

	Method Update(deltaTime:float)
		'update parent class (anim pos)
		super.Update(deltaTime)

		self.alreadydrawn = 0

		If updatefunc_ <> Null
			updatefunc_(ListLink, deltaTime)
		Else
			If id = Game.playerID
				If self.rect.position.isSame(target)
					If Game.networkgame and self.SyncTimer.isExpired()
						NetworkHelper.SendFigurePosition(self)
						self.SyncTimer.Reset()
					EndIf
				EndIf
			EndIf
			Self.FigureMovement(deltaTime)
			Self.FigureAnimation(deltaTime)
		EndIf
		'figure wants to change room
		If clickedToRoom and clickedToRoom <> fromRoom
			local doorCenter:int = (clickedToRoom.name <> "elevator")*Assets.GetSprite("gfx_building_Tueren").framew/2

			If Self.ControlledByID >= 0 and Self.id <> figure_HausmeisterID 'in multiplayer to be checked if its the player or not
				'figure center is within 4px wide frame of room "spot" ?
				'if self.ControlledByID = 1 then print "targetx="+target.x+" x="+(pos.x + framewidth/2)+", y="+(Building.pos.y + Building.GetFloorY(toFloor) - 5)+", wx:"+(clickedToRoom.Pos.x + doorCenter -2)+", wy:"+(Building.pos.y + Building.GetFloorY(clickedToRoom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h)+" w:"+4+" h:"+54
				If inRoom = Null And functions.IsIn(rect.GetX() + rect.GetW()/2, Building.pos.y + rect.GetY() - 5, clickedToRoom.Pos.x + doorCenter -2, Building.pos.y + Building.GetFloorY(clickedToRoom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h, 4, 54)

					If clickedToRoom.doortype >= 0 and clickedToRoom.getDoorType() <> 5 and inRoom <> clickedToRoom
						'if player is able to enter the room (not used) then start fader
						if id = Game.playerID and self.CanEnterRoom(clickedToRoom) then Fader.Enable() 'room fading

						clickedToRoom.OpenDoor()
						self.SetCurrentAnimation("standBack")
					else
						'Print "standing in front of clickedroom "
						self.SetCurrentAnimation("standFront")
					EndIf
					'if open, timer started and reached halftime --> "wait a moment" before entering
					If clickedToRoom.getDoorType() = 5 and not clickedToRoom.DoorTimer.isExpired() and clickedToRoom.DoorTimer.reachedHalftime()
						clickedToRoom.CloseDoor()
						EnterRoom(clickedToRoom)
					'we stand in front of elevator - and clicked on it (to go to other floors)
					elseIf clickedToRoom.getDoorType() <> 5
						If clickedToRoom.name = "elevator" And clickedToRoom.Pos.y = GetFloor() And IsAtElevator()
							CallElevator()
						EndIf
					elseIf clickedToRoom.name = "elevator" And clickedToRoom.Pos.y = GetFloor() And Building.Elevator.CurrentFloor = clickedToRoom.Pos.y And Building.Elevator.DoorStatus = 1 'offen
						EnterRoom(clickedToRoom, false)
						Building.Elevator.UsePlan(self)
					EndIf
				EndIf
			EndIf
		EndIf

		If Visible and (inRoom = Null or inRoom.name = "elevator")
			If Self.HasToChangeFloor() And IsAtElevator() And Not IsInElevator()
				local elevator:TElevator = Building.Elevator

				'TODOX: Blockiert.. weil noch einer aus dem Plan auswählen will

				'Ist der Fahrstuhl da? Kann ich einsteigen?
				If elevator.CurrentFloor = GetFloor() And elevator.ReadyForBoarding
					GoOnBoardAndSendElevator()
				Else 'Ansonsten ruf ich ihn halt
					CallElevator()
				Endif
			Endif

			If IsInElevator() 'And elevator.CurrentFloor = GetTargetFloor() And elevator.ReadyForBoarding Then
				local elevator:TElevator = Building.Elevator
				If elevator.CurrentFloor = GetTargetFloor() And elevator.ReadyForBoarding Then
					elevator.LeaveTheElevator(self)
				Endif
			Endif
		Endif

		'sync playerposition if not done for long time
		If Game.networkgame and Network.IsConnected and self.SyncTimer.isExpired()
			self.Network_SendPosition()
			self.SyncTimer.Reset()
		endif
	End Method

	Method Network_SendPosition()
		NetworkHelper.SendFigurePosition(self)
	End Method

	Function UpdateAll(deltaTime:float)
		For Local Figure:TFigures = EachIn TFigures.List
			Figure.Update(deltaTime)
		Next
	End Function

	Method Draw(_x:float= -10000, _y:float = -10000, overwriteAnimation:string="")
		If Visible And (inRoom = Null Or inRoom.name = "elevator")
			If Sprite <> Null
				super.Draw(self.rect.GetX() + PosOffset.getX(), Building.pos.y + self.rect.GetY() - self.sprite.h + PosOffset.getY())
			EndIf
		EndIf
		Self.GetPeopleOnSameFloor()
	End Method

End Type
