'Summary: all kind of characters walking through the building (players, terrorists and so on)
Type TFigures
	Field Name:String		= "unknown"
	Field pos:TPosition		= TPosition.Create(0.0,0.0) 'pos.y is difference to y of building
	Field dx:Float			= 0.0 'pixels per second
	Field initialdx:Float	= 0.0
	field target:TPosition	= TPosition.Create(-1,-1)

'	Field clickedToFloor:Int = -1
	Field toRoom:TRooms		= Null			{sl = "no"}
	Field fromRoom:TRooms	= Null			{sl = "no"}
	Field clickedToRoom:TRooms = Null		{sl = "no"}
	Field inRoom:TRooms		= Null			{sl = "no"}
	Field id:Int			= 0
	Field calledElevator:Int= 0
	Field Visible:Int		= 1
	Field Sprite:TGW_Sprites 				{sl = "no"}
	Field FrameWidth:Int	= 11
	Field AnimPos:Int		= 0
	Field NextTwinkerTimer:Int = 0
	Field NextAnimTimer:Int	= 0				{sl = "no"}
	Field NextAnimTime:Int	= 130			{sl = "no"}
	Field specialTime:Int	= 0
	Field LastSpecialTime:Int = 0
	Field WaitTime:Int		= 0
	Field BackupAnimTime:Int= 120
	Field inElevator:Byte	= 0
	Field ControlledByID:Int= -1
	Field alreadydrawn:Int	= 0 {sl = "no"}
	Field updatefunc_(ListLink:TLink, deltaTime:float) {sl = "no"}
	Field LastSync:Int		= 0
	Field ListLink:TLink					{sl = "no"}
	Field ParentPlayer:TPlayer = Null		{sl = "no"}
	Global LastID:Int = 1					{sl = "no"}
	Global List:TList = CreateList()


	Function Load:TFigures(pnode:xmlNode, figure:TFigures)
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
	End Function

	Function LoadAll()
		Local figureID:Int = 1
		Local Children:TList = LoadSaveFile.node.ChildList
		For Local node:xmlNode = EachIn Children
			If node.name = "FIGURES_CHILD"
				Local Figure:TFigures = TFigures.GetFigure(figureID)
				figureID:+1
				If Figure <> Null Then Figure = TFigures.Load(NODE, Figure)
				If Figure = Null Then Print "Figure.LoadAll: Figure Missing";Exit
			End If
		Next
		'Print "loaded figure informations"
	End Function

	Function AdditionalLoad(obj:Object, node:xmlNode)
		Local figure:TFigures = TFigures(obj)
		If figure <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Select NODE.name
				Case "TOROOMID" figure.toRoom = TRooms.GetRoomFromID(Int(nodevalue))
				Case "FROMROOMID" figure.fromRoom = TRooms.GetRoomFromID(Int(nodevalue))
				Case "CLICKEDTOROOMID" figure.clickedToRoom = TRooms.GetRoomFromID(Int(nodevalue))
				Case "INROOMID" figure.inRoom = TRooms.GetRoomFromID(Int(nodevalue))
			End Select
			figure.NextAnimTimer = MilliSecs()
		EndIf
	End Function

	Function AdditionalSave(obj:Object)
		Local figure:TFigures = TFigures(obj)
		If figure <> Null
			If figure.toRoom <> Null Then LoadSaveFile.xmlWrite("TOROOMID", figure.toRoom.uniqueID) Else LoadSaveFile.xmlWrite("TOROOMID", "-1")
			If figure.fromRoom <> Null Then LoadSaveFile.xmlWrite("FROMROOMID", figure.FromRoom.uniqueID) Else LoadSaveFile.xmlWrite("FROMROOMID", "-1")
			If figure.clickedToRoom <> Null Then LoadSaveFile.xmlWrite("CLICKEDTOROOMID", figure.ClickedToRoom.uniqueID) Else LoadSaveFile.xmlWrite("CLICKEDTOROOMID", "-1")
			If figure.inRoom <> Null Then LoadSaveFile.xmlWrite("INROOMID", figure.inRoom.uniqueID) Else LoadSaveFile.xmlWrite("INROOMID", "-1")
		EndIf
	End Function

	Method HasToChangeFloor:int()
		return Building.getFloor(Building.pos.y + target.y) <> Building.getFloor(Building.pos.y + pos.y)
	End Method

	Method GetFloor:int(_pos:TPosition = null)
		if _pos = null then _pos = self.pos
		'print self.name + " is on floor: " + Building.getFloor( Building.pos.y + pos.y + sprite.h )
		Return Building.getFloor( Building.pos.y + _pos.y )
	End Method


	Method IsOnFloor:Byte()
		return pos.y = Building.GetFloorY(GetFloor())
	End Method

	'ignores y
	Method IsAtElevator:Byte()
		return Building.Elevator.IsInFrontOfDoor(pos.x + self.framewidth/2)
	End Method

	Method IsInElevator:Byte()
		If Not IsAtElevator()
			inElevator=False
			If Building.Elevator.passenger = self Then Building.Elevator.passenger = null
			Return False
		else
			If Building.Elevator.passenger = self
				inElevator=True
				Return True
			EndIf
		EndIf
		inElevator=False
		Return False
	End Method

	Method IsAI:Int()
		If id > 4 Then Return True
	'	If Game.networkgame Then If id < 4 Then If Network.IP[id - 1] = Null Then Return True
		if self.ControlledByID = 0 then return true
		Return False
	End Method

	Method FigureMovement(deltaTime:float=1.0)
		local targetX:int = self.target.x
		if target.y=-1 then target.setPos(pos)

		'do we have to change the floor?
		if self.HasToChangeFloor() then targetX = Building.Elevator.GetDoorCenter() - self.framewidth/2 '-framewidth/2 to center figure

		If targetX < Floor(Self.pos.x) Then Self.dx = -(Abs(Self.initialdx))
		If targetX > Floor(Self.pos.x) Then Self.dx =  (Abs(Self.initialdx))
 		If Abs( Floor(targetX)-Floor(Self.pos.x) ) < Abs(deltaTime*Self.dx) Then Self.dx = 0;Self.pos.setX(targetX)

		If not Self.IsInElevator() 'And isOnFloor())
			Self.pos.x	:+ deltaTime * Self.dx
			If Not Self.IsOnFloor() Then Self.pos.setY( Building.GetFloorY(Self.GetFloor()) )
		Else
			Self.dx = 0.0
		EndIf

		'limit player position (only within floor 13 and floor 0 allowed)
		If self.pos.y - self.sprite.h < Building.GetFloorY(13) Then self.pos.setY( Building.GetFloorY(13) )
		If self.pos.y - self.sprite.h > Building.GetFloorY( 0) Then self.pos.setY( Building.GetFloorY(0) )
		'limit player position horizontally
	    If Floor(pos.x) <= 200 Then pos.setX(200);target.setX(200)
	    If Floor(pos.x) >= 579 Then pos.setX(579);target.setX(579)
	End Method

	Method FigureAnimation(deltaTime:float=1.0)
	    If MilliSecs()- NextAnimTimer >= 0
			AnimPos = Min(8, AnimPos+1)

	      	NextAnimTimer = MilliSecs() + NextAnimTime
	  		If dx = 0
	      		If self.hasToChangeFloor() and not IsInElevator() and IsAtElevator()
	     		   	AnimPos = 10
	      		Else
			        If MilliSecs() - NextTwinkerTimer > 0 Then
	        			AnimPos = 9
	      			   	NextTwinkerTimer = MilliSecs() + Rand(1000)+1500
	      			Else
	          			AnimPos = 8
					EndIf
				EndIf
			EndIf
	    EndIf

	    If dx > 0 Then If AnimPos > 3 Then AnimPos = 0
	    If dx < 0 Then If AnimPos > 7 Or AnimPos < 4 Then AnimPos = 4
	End Method

	Method GetPeopleOnSameFloor()
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.pos.y = Self.pos.y And Figure <> Self
				If Abs(Figure.pos.x - Self.pos.x) < 50
					If figure.id <= 3 And Self.id <= 3
						If Figure.pos.x > Self.pos.x And Self.dx > 0 Then DrawImage (gfx_building_textballons, Self.pos.x + framewidth, Building.pos.y + self.pos.y - self.sprite.h - 8, 0)
						If Figure.pos.x < Self.pos.x And Self.dx < 0 Then DrawImage (gfx_building_textballons, Self.pos.x-18,Building.pos.y + self.pos.y - self.sprite.h-8, 3)
					Else
						If Self.id = figure_HausmeisterID
							If Figure.pos.x > Self.pos.x And Self.dx > 0 Then DrawImage (gfx_building_textballons, Self.pos.x - 8 + framewidth, Building.pos.y + self.pos.y - self.sprite.h - 8, 1)
							If Figure.pos.x < Self.pos.x And Self.dx < 0 Then DrawImage (gfx_building_textballons, Self.pos.x-18+13,Building.pos.y + self.pos.y - self.sprite.h-8, 4)
						Else
							If Figure.pos.x > Self.pos.x And Self.dx > 0 Then DrawImage (gfx_building_textballons, Self.pos.x + framewidth, Building.pos.y + self.pos.y - self.sprite.h - 8, 1)
							If Figure.pos.x < Self.pos.x And Self.dx < 0 Then DrawImage (gfx_building_textballons, Self.pos.x - 18, Building.pos.y + self.pos.y - self.sprite.h - 8, 4)
						EndIf
					EndIf
				EndIf
			EndIf
		Next
	End Method

	'player is now in room "room"
	Method SetInRoom:Int(room:TRooms)
		If room <> null Then room.CloseDoor()

	 	inRoom = room
		If ParentPlayer <> Null And controlledByID = 0
			If room <> Null Then ParentPlayer.PlayerKI.CallOnReachRoom(room.uniqueID) Else ParentPlayer.PlayerKI.CallOnReachRoom(0)
		EndIf
		If Game.networkgame Then If Network.IsConnected Then Network.SendPlayerPosition()
	End Method

	'backing up former room
	Method SetToRoom:Int(room:TRooms)
		if toRoom <> room
			If fromRoom <> toRoom Then fromRoom = toRoom
			toRoom = room
			If Game.networkgame Then If Network.IsConnected Then Network.SendPlayerPosition()
		endif
	End Method

	Method LeaveRoom:Int()
		If ParentPlayer <> Null And controlledByID = 0
			If Players[ParentPlayer.PlayerKI.playerId].Figure.inRoom <> Null
				'Print "LeaveRoom:"+Players[ParentPlayer.PlayerKI.playerId].Figure.inRoom.name
				If Players[ParentPlayer.PlayerKI.playerId].figure.inRoom.name = "movieagency"
					 TMovieAgencyBlocks.ProgrammeToPlayer(ParentPlayer.PlayerKI.playerId)
					 'Print "movieagency left: programmes bought"
				EndIf
			EndIf
			ParentPlayer.PlayerKI.CallOnLeaveRoom()
		EndIf
		toRoom = fromRoom
		If fromRoom <> Null Then fromRoom.CloseDoor()
		fromRoom = Null
		SetInRoom(toRoom)
		clickedToRoom = Null
		If inRoom = Null Then pos.setX(target.x)
		If Game.networkgame Then If Network.IsConnected Then Network.SendPlayerPosition()
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

	Function GetFigure:TFigures(id:Int)
		For Local Figure:TFigures = EachIn TFigures.List
			If Figure.id = id Then Return Figure
		Next
		Return Null
	End Function

	Function Create:TFigures(FigureName:String, sprite:TGW_Sprites, x:Int, onFloor:Int = 13, dx:Int, ControlledByID:Int = -1)
		Local obj:TFigures=New TFigures
		obj.name = Figurename
		obj.pos.setX(x)
		obj.target.setX(x)
		obj.dx			= dx
		obj.initialdx	= dx
		obj.id			= LastID
		obj.LastID:+1
		obj.Sprite		= sprite
		obj.framewidth	= obj.sprite.framew 'overwriteable for different center/handle
		obj.pos.setY( Building.GetFloorY(onFloor) )
		obj.NextAnimTimer = MilliSecs() + obj.NextAnimTime
		obj.ControlledByID = ControlledByID
		obj.ListLink = List.AddLast(obj)
		SortList List
		Return obj
	End Function

	Method CallElevator:Int()
		if calledElevator then return false
		'print self.name+" calls elevator"

		If id = Game.playerID Or (IsAI() And Game.playerID = 1)
			If IsAtElevator() Then Building.Elevator.AddFloorRoute(self.GetFloor(), 1, id, False, False)
		Else
			If IsAtElevator() Then Building.Elevator.AddFloorRoute(self.GetFloor(), 1, id, False, True)
		EndIf
		calledElevator = True
		If Not Building.Elevator.EgoMode Then SortList(Building.Elevator.FloorRouteList)
	End Method

	Method SendElevator:Int()
		print self.name+" sends elevator"
		Building.Elevator.passenger = self
		'target.y		= Building.getFloorY(Building.getFloor(target.y))
		If id = Game.playerID Or (IsAI() And Game.playerID = 1)
			Building.Elevator.AddFloorRoute(self.GetFloor(target), 0, id, True, False)
		Else
			Building.Elevator.AddFloorRoute(self.GetFloor(target), 0, id, True, True)
		EndIf
		'clickedToFloor	= -1
		'calledElevator	= False
	End Method

	Method ChangeTarget(x:Int=null, y:Int=null)
		if x=null then x=target.x
		if y=null then y=target.y

		'if player is in elevator dont accept changes
		If Self = Building.Elevator.passenger then return
		'y is not of floor 0 -13
		If Building.GetFloor(y) < 0 OR Building.GetFloor(y) > 13 then return

		'set target y to "basement" y of that floor
		target.setY(Building.GetFloorY(Building.GetFloor(y)))
		'set target x so, that center of figure moves to there
		target.setX(x)

		'targeting a room ? - add building displace
		self.clickedToRoom = TRooms.GetTargetroom(target.x, Building.pos.y + target.y)
		if self.clickedToRoom <> null
			'print "clicked to room: "+self.clickedToRoom.name + " "+self.clickedToRoom.pos.x
			target.setX(self.clickedToRoom.pos.x +  (self.clickedToRoom.name <> "elevator")*Assets.GetSprite("gfx_building_Tueren").framew/2 )
		endif

		'center figure to target
		target.setX(target.x - frameWidth/2)

		inRoom = Null
		'change to event
		If Game.networkgame Then If Network.IsConnected Then Network.SendPlayerPosition()
	End Method


	Method Update(deltaTime:float)
		self.alreadydrawn = 0

		If updatefunc_ <> Null
			updatefunc_(ListLink, deltaTime)
		Else
			If id = Game.playerID
				If Int(target.x) = Floor(pos.x)
					If Game.networkgame and LastSync + 1000 < MilliSecs()
						Network.SendPlayerPosition()
						LastSync = MilliSecs()
					EndIf
				EndIf
			EndIf
			Self.FigureMovement(deltaTime)
			Self.FigureAnimation(deltaTime)
		EndIf
		'figure wants to change room
		If clickedToRoom <> Null and clickedToRoom <> fromRoom
			local doorCenter:int = (clickedToRoom.name <> "elevator")*Assets.GetSprite("gfx_building_Tueren").framew/2

			If Self.ControlledByID >= 0 and Self.id <> figure_HausmeisterID 'in multiplayer to be checked if its the player or not
				'figure center is within 4px wide frame of room "spot" ?
				'if self.ControlledByID = 1 then print "targetx="+target.x+" x="+(pos.x + framewidth/2)+", y="+(Building.pos.y + Building.GetFloorY(toFloor) - 5)+", wx:"+(clickedToRoom.Pos.x + doorCenter -2)+", wy:"+(Building.pos.y + Building.GetFloorY(clickedToRoom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h)+" w:"+4+" h:"+54
				If inRoom = Null And functions.IsIn(pos.x + framewidth/2, Building.pos.y + pos.y - 5, clickedToRoom.Pos.x + doorCenter -2, Building.pos.y + Building.GetFloorY(clickedToRoom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h, 4, 54)
			        'Print "standing in front of clickedroom "
					AnimPos = 10
					If clickedToRoom.doortype >= 0 and clickedToRoom.getDoorType() <> 5 and inRoom <> clickedToRoom
		        		If id = Game.playerID Then Fader.Enable() 'room fading
						clickedToRoom.OpenDoor()
					EndIf
					If clickedToRoom.getDoorType() = 5 and clickedToRoom.DoorOpenTimer > 0 and clickedToRoom.DoorOpenTimer + Game.DoorOpenTime < MilliSecs()
						clickedToRoom.CloseDoor()
						If id = Game.playerID Then Fader.EnableFadeout() 'room fading
        			    SetInRoom(clickedToRoom)
					EndIf
					If clickedToRoom.getDoorType() <> 5
						If clickedToRoom.name = "elevator" And clickedToRoom.Pos.y = GetFloor() And IsAtElevator()
							CallElevator()
						EndIf
					EndIf
					If clickedToRoom.name = "elevator" And clickedToRoom.Pos.y = GetFloor() And Building.Elevator.onFloor = clickedToRoom.Pos.y And Building.Elevator.Open = 1
						SetInRoom(clickedToRoom)
						Building.Elevator.waitAtFloorTimer = MilliSecs() + Building.Elevator.PlanTime
					EndIf
				EndIf
			EndIf
		EndIf
		If Visible and (inRoom = Null or inRoom.name = "elevator")
			'figure wants to change floor
			If Self.HasToChangeFloor() and IsAtElevator()
				CallElevator()
		        If Building.Elevator.passenger= null  and calledElevator = True and Building.Elevator.Open = 1 and Building.Elevator.onFloor = GetFloor()
	          		SendElevator()
		        EndIf
			EndIf

			If Building.Elevator.passenger = self and Building.Elevator.Open = 1 and pos.y = target.y and Building.getFloor(building.pos.y+target.y) = Building.Elevator.toFloor
				print (self.sprite.h + Int(pos.y))+" = "+(target.y)
				If self.sprite.h + Int(pos.y) = (target.y)
					calledElevator	= False
					Building.Elevator.passenger = null
					print "fahrstuhlrausschmiss"

					'set target again - so player can click on signs in roomboard
				'	self.SetToRoom( TRooms.GetTargetroom(self.target.x + self.FrameWidth /2, Building.pos.y + Building.GetFloorY(Building.GetFloor(self.pos.y)) - 5) )
				EndIf
			EndIf

	    EndIf
	End Method

	Function UpdateAll(deltaTime:float)
		For Local Figure:TFigures = EachIn TFigures.List
			Figure.Update(deltaTime)
		Next
	End Function

	Method Draw()
		Local ShadowDisabled:Int = 0
		If Visible And (inRoom = Null Or inRoom.name = "elevator")
			If Sprite <> Null
				If Not ShadowDisabled
					SetColor 0, 0, 0
					SetAlpha 0.2
					Sprite.DrawClipped(self.pos.x + 2, Building.pos.y + self.pos.y - self.sprite.h + 2, self.pos.x + 2, Building.pos.y + self.pos.y - self.sprite.h, Sprite.framew, Sprite.frameh, 0, 0, AnimPos)
					SetAlpha 1.0
					SetColor 255, 255, 255
				EndIf
				Sprite.Draw(self.pos.x, Building.pos.y + self.pos.y - self.sprite.h, AnimPos)
			EndIf
		EndIf
		'DrawRect(0,Building.pos.y + self.pos.y, 50,2)
		'DrawRect(0,Building.pos.y + self.target.y, 100,2)
		Self.GetPeopleOnSameFloor()
	End Method

End Type
