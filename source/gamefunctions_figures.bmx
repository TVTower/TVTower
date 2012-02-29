'Summary: all kind of characters walking through the building (players, terrorists and so on)
Type TFigures
 Field Name:String		= "unknown"
 Field pos:TPosition	= TPosition.Create(0.0,0.0) 'pos.y is difference to y of building
 Field lastDrawnPos:TPosition	= TPosition.Create(0.0,0.0) 'pos.y is difference to y of building
 Field dx:Float			= 0.0 'pixels per second
 Field initialdx:Float	= 0.0
 Field targetx:Int		= 0
 Field oldtargetx:Int	= 0
 Field toFloor:Int		= 13
 Field toRoom:TRooms	= Null {sl = "no"}
 Field fromRoom:TRooms	= Null {sl = "no"}
 Field clickedToRoom:TRooms = Null {sl = "no"}
 Field inRoom:TRooms	= Null {sl = "no"}
 Field calledElevator:Int = 0
 Field onFloor:Int		= 13
 Field id:Int			= 0
 Field clickedToFloor:Int = -1
 Field xToElevator:Float= 18	'difference to building.elevator.x
 Field Visible:Int		= 1
 Field image:TImage	{sl = "no"}
 Field Sprite:TGW_Sprites {sl = "no"}
										 Field FrameWidth:Int	= 11
										 Field frameheight:Int
										 Field AnimPos:Int		= 0
 Field NextTwinkerTimer:Int = 0
 Field NextAnimTimer:Int = 0 {sl = "no"}
 Field NextAnimTime:Int = 120 {sl = "no"}
 Field specialTime:Int = 0
 Field LastSpecialTime:Int = 0
 Field WaitTime:Int = 0
 Field BackupAnimTime:Int = 120
 Field inElevator:Byte = 0
 Field ControlledByID:Int = -1
 Field alreadydrawn:Int = 0 {sl = "no"}
 Field updatefunc_(ListLink:TLink, deltaTime:float) {sl = "no"}
 Field LastSync:Int = 0
 Field ListLink:TLink {sl = "no"}
 Field ParentPlayer:TPlayer = Null {sl = "no"}
 field mylist:TList = CreateList()
 Global LastID:Int = 0 {sl = "no"}
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


	Method FigureMovement(deltaTime:float=1.0)
		If Self.targetx < Floor(Self.pos.x) Then Self.dx = -(Abs(Self.initialdx))
		If Self.targetx > Floor(Self.pos.x) Then Self.dx = (Abs(Self.initialdx))
 		If Abs( Floor(Self.targetx)-Floor(Self.pos.x) ) < Abs(deltaTime*Self.dx) Then Self.dx = 0;Self.pos.setX(Self.targetx)
		If Self.pos.y + Self.frameheight < Building.GetFloorY(13) Then Self.pos.setY( Building.GetFloorY(13) - Self.frameheight )
    	If Self.pos.y + Self.frameheight > Building.GetFloorY(0) Then Self.pos.setY( Building.GetFloorY(0) - Self.frameheight )
		If not Self.IsInElevator() 'And isOnFloor())
			Self.pos.x	:+ deltaTime * Float(Self.dx)
			If Not Self.IsOnFloor() Then Self.pos.setY( Building.GetFloorY(Self.onFloor) - Self.frameheight )
		Else
			Self.dx = 0.0
		EndIf
	End Method

	Method FigureAnimation(deltaTime:float=1.0)
	    If MilliSecs()- NextAnimTimer >= 0
			If AnimPos < 8 Then AnimPos = AnimPos + 1
	      	NextAnimTimer = MilliSecs() + NextAnimTime
	  		If dx = 0
	      		If onFloor <> clickedToFloor and  not IsInElevator() and IsAtElevator()
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
	    If Floor(pos.x) <= 200 Then pos.setX(200);targetx = 200
	    If Floor(pos.x) >= 579 Then pos.setX(579);targetx = 579

	    If dx > 0 Then If AnimPos > 3 Then AnimPos = 0
	    If dx < 0 Then If AnimPos > 7 Or AnimPos < 4 Then AnimPos = 4
	End Method

	Function UpdateBote:Int(ListLink:TLink, deltaTime:float=1.0) 'SpecialTime = 1 if letter in hand
		Local Figure:TFigures = TFigures(ListLink.value())
		Figure.FigureMovement(deltaTime)
		Figure.FigureAnimation(deltaTime)
		If figure.inRoom <> Null
			If figure.specialTime = 0
				figure.specialTime = MilliSecs()+2000+Rand(50)*100
			Else
				If figure.specialTime < MilliSecs()
					Figure.specialTime = 0
					Local room:TRooms
					Repeat
						room = TRooms.GetRandomReachableRoom()
					Until room <> Figure.inRoom
					If Figure.LastSpecialTime = 0
						Figure.LastSpecialTime=1
						Figure.sprite = Assets.GetSpritePack("figures").GetSprite("BotePost")
					Else
						Figure.sprite = Assets.GetSpritePack("figures").GetSprite("BoteLeer")
						Figure.LastSpecialTime=0
					EndIf
					'Print "Bote: war in Raum -> neues Ziel gesucht"
					Figure.ChangeTarget(room.Pos.x + 13, Building.pos.y + Building.GetFloorY(room.Pos.y) - figure.frameheight)
				EndIf
			EndIf
		End If
		If figure.inRoom = Null and figure.clickedToRoom = Null and figure.dx = 0 and not (Figure.IsAtElevator() or Figure.IsInElevator()) 'not moving but not in/at elevator
			Local room:TRooms = TRooms.GetRandomReachableRoom()
			'Print "Bote: steht rum -> neues Ziel gesucht"
			Figure.ChangeTarget(room.Pos.x + 13, Building.pos.y + Building.GetFloorY(room.Pos.y) - figure.frameheight)
		End If
	End Function

	Function UpdateHausmeister:Int(ListLink:TLink, deltaTime:float=1.0)
		Local Figure:TFigures = TFigures(ListLink.value())
		If figure.WaitTime < MilliSecs()
			figure.WaitTime = MilliSecs() + 15000
			'Print "zu lange auf fahrstuhl gewartet"
			Figure.ChangeTarget(Rand(150, 580), Building.pos.y + Building.GetFloorY(figure.onfloor) - figure.frameheight)
		EndIf
		If Int(Figure.pos.x) = Int(Figure.targetx) And Not Figure.IsInElevator() And figure.onFloor = figure.toFloor
			Local zufall:Int = Rand(0, 100)
			Local zufallx:Int = Rand(150, 580)
			If figure.LastSpecialTime < MilliSecs()
				figure.LastSpecialTime = MilliSecs() + 1500
				'no left-right-left-right movement for just some pixels
				Repeat
					zufallx = Rand(150, 580)
				Until Abs(figure.pos.x - zufallx) > 15

				If zufall > 85 And Not figure.IsAtElevator()
					Local sendToFloor:Int = figure.onFloor + 1
					If figure.onFloor >= 13 Then sendToFloor = 0
					Figure.ChangeTarget(zufallx, Building.pos.y + Building.GetFloorY(sendToFloor) - figure.frameheight)
					figure.WaitTime = MilliSecs() + 15000
				Else If zufall <= 85 And Not figure.isAtElevator()
					Figure.ChangeTarget(zufallx, Building.pos.y + Building.GetFloorY(figure.onfloor) - figure.frameheight)
				EndIf
			EndIf
		EndIf
		Figure.FigureMovement(deltaTime)

		If MilliSecs() - Figure.NextAnimTimer >= 0
			If Figure.AnimPos < 8 Or Figure.AnimPos > 10 Then Figure.AnimPos = Figure.AnimPos + 1
			Figure.NextAnimTimer = MilliSecs() + Figure.NextAnimTime
			If Figure.dx = 0
				If Figure.onFloor <> Figure.clickedToFloor And Not Figure.IsInElevator() And Figure.IsAtElevator()
					Figure.AnimPos = 10
				Else
					If MilliSecs() - Figure.NextTwinkerTimer > 0
						Figure.AnimPos = 9
						Figure.NextTwinkerTimer = MilliSecs() + Rand(1000) + 1500
					Else
						Figure.AnimPos = 8
					EndIf
				EndIf
			EndIf
		EndIf
	    If Floor(Figure.pos.x) <= 200 Then Figure.pos.setX(200);Figure.targetx = 200
	    If Floor(Figure.pos.x) >= 579 Then Figure.pos.setX(579);Figure.targetx = 579

		If Figure.specialTime < MilliSecs()
			If Figure.dx > 0 Then If Figure.AnimPos > 3
				Figure.NextAnimTime = Figure.BackupAnimTime
			    Figure.AnimPos = 0
				If Rand(0,40) > 30 Then Figure.specialTime = MilliSecs()+Rand(1000,3000);Figure.AnimPos = 11
			EndIf
			If Figure.dx < 0 Then If Figure.AnimPos > 7
				Figure.NextAnimTime = Figure.BackupAnimTime
			    Figure.AnimPos = 3
				If Rand(0,40) > 30 Then Figure.specialTime = MilliSecs()+Rand(1000,3000);Figure.AnimPos = 13
			EndIf
		End If
		If Figure.dx > 0
			If Figure.AnimPos >= 11
				Figure.NextAnimTime = 300
				Figure.pos.x		:-deltaTime * Figure.dx
		    	If Figure.specialTime < MilliSecs()
					Figure.NextAnimTime = Figure.BackupAnimTime
					Figure.AnimPos = 0
				EndIf
				If Figure.AnimPos >= 13 Then Figure.AnimPos = 11
			EndIf
		Else If Figure.dx < 0
			If Figure.AnimPos >= 13
				Figure.NextAnimTime = 300
	    		Figure.pos.x		:- deltaTime * Figure.dx
	    		If Figure.specialTime < MilliSecs()
					Figure.NextAnimTime = Figure.BackupAnimTime
					Figure.AnimPos = 4
				EndIf
				If Figure.AnimPos >= 15 Or Figure.AnimPos = 0 Then Figure.AnimPos = 13
			EndIf
			If (Figure.AnimPos > 7 And Figure.AnimPos < 13) Or Figure.AnimPos < 4 Then Figure.AnimPos = 4
		EndIf
	End Function

 Method GetPeopleOnSameFloor()
   For Local Figure:TFigures = EachIn TFigures.List
     If Figure.pos.y = Self.pos.y And Figure <> Self
       If Abs(Figure.pos.x - Self.pos.x) < 50
	    If figure.id <= 3 And Self.id <= 3
         If Figure.pos.x > Self.pos.x And Self.dx > 0 Then DrawImage (gfx_building_textballons, Self.pos.x - 5 + framewidth, Building.pos.y + Self.pos.y - 8, 0)
         If Figure.pos.x < Self.pos.x And Self.dx < 0 Then DrawImage (gfx_building_textballons, Self.pos.x-18,Building.pos.y + Self.pos.y-8, 3)
		Else
		 If Self.id = figure_HausmeisterID
           If Figure.pos.x > Self.pos.x And Self.dx > 0 Then DrawImage (gfx_building_textballons, Self.pos.x - 13 + framewidth, Building.pos.y + Self.pos.y - 8, 1)
           If Figure.pos.x < Self.pos.x And Self.dx < 0 Then DrawImage (gfx_building_textballons, Self.pos.x-18+13,Building.pos.y + Self.pos.y-8, 4)
		 Else
           If Figure.pos.x > Self.pos.x And Self.dx > 0 Then DrawImage (gfx_building_textballons, Self.pos.x - 5 + framewidth, Building.pos.y + Self.pos.y - 8, 1)
           If Figure.pos.x < Self.pos.x And Self.dx < 0 Then DrawImage (gfx_building_textballons, Self.pos.x - 18, Building.pos.y + Self.pos.y - 8, 4)
		 EndIf
		EndIf
       EndIf
     EndIf
   Next

 End Method

	'player is now in room "room"
	Method SetInRoom:Int(room:TRooms)
	 	inRoom = room
		If ParentPlayer <> Null And controlledByID = 0
			If room <> Null Then ParentPlayer.PlayerKI.CallOnReachRoom(room.uniqueID) Else ParentPlayer.PlayerKI.CallOnReachRoom(0)
		EndIf
		If Game.networkgame Then If Network.IsConnected Then Network.SendPlayerPosition()
	End Method

	'backing up former room
	Method SetRoom:Int(room:TRooms)
		If fromRoom <> toRoom Then fromRoom = toRoom
		toRoom = room
		If Game.networkgame Then If Network.IsConnected Then Network.SendPlayerPosition()
	End Method

	Method LeaveRoom:Int()
		'If Self = Player[Game.playerID].Figure
		If ParentPlayer <> Null And controlledByID = 0
			If Player[ParentPlayer.PlayerKI.playerId].Figure.inRoom <> Null
				'Print "LeaveRoom:"+Player[ParentPlayer.PlayerKI.playerId].Figure.inRoom.name
				If Player[ParentPlayer.PlayerKI.playerId].figure.inRoom.name = "movieagency"
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
		If inRoom = Null Then pos.x = targetx
		If Game.networkgame Then If Network.IsConnected Then Network.SendPlayerPosition()
		'EndIf
	End Method

	Method SendToRoom:Int(room:TRooms)
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

 Function Create:TFigures(FigureName:String, imageOrSprite:Object, x:Int, onFloor:Int = 13, dx:Int, ControlledByID:Int = -1)
	  Local Figure:TFigures=New TFigures
	  Figure.name = Figurename
	  Figure.pos.setX(x)
	  Figure.targetx = x
	  Figure.dx = dx
	  Figure.id = LastID+1
	  LastID = LastID + 1
	  Figure.initialdx = dx
	  If TImage(imageOrSprite) <> Null
	  	Figure.image = TImage(imageOrSprite)
		Figure.frameheight = ImageHeight(Figure.image)
	  EndIf
	  If TGW_Sprites(imageOrSprite) <> Null
	  	Figure.Sprite = TGW_Sprites(imageOrSprite)
		Figure.frameheight = Figure.Sprite.h
	  EndIf
  	  Figure.pos.setY( Building.GetFloorY(onFloor) - Figure.frameheight )
'	  Figure.image = image
	  Figure.NextAnimTimer = MilliSecs() + Figure.NextAnimTime
	  Figure.onFloor = onFloor
	  Figure.toFloor = onFloor
	  Figure.ControlledByID = ControlledByID
	  If Not List Then List = CreateList()
	  Figure.ListLink = List.AddLast(Figure)
	  SortList List
	  Return Figure
 End Function

 Method IsOnFloor:Byte()
  If pos.y = (Building.GetFloorY(onFloor) - frameheight) Then Return True
  Return False
 End Method

 Method IsAtElevator:Byte()
   If Int(pos.x) = Int(Building.pos.x + Building.Elevator.Pos.x + xToElevator - FrameWidth) Then Return True
   Return False
 End Method

 Method IsInElevator:Byte()
   If Not IsAtElevator() Then
     inElevator=False
	 If Building.Elevator.passenger = id Then Building.Elevator.passenger = -1
	 Return False
   EndIf
   If IsAtElevator() Then
	If Building.Elevator.passenger = id Then
	  'If inElevator<>True Then Print "in elevator"
	  inElevator=True
	  Return True
	EndIf
   End If

   inElevator=False
   Return False
 End Method

 Method IsAI:Int()
  If id > 4 Then Return True
  If Game.networkgame Then If id < 4 Then If Network.IP[id - 1] = Null Then Return True
  if self.ControlledByID = 0 then return true
  Return False
 End Method

 Method CallElevator:Int()
    If id = Game.playerID Or (IsAI() And Game.playerID = 1) Then
	  If calledElevator = False And IsAtElevator() Then Building.Elevator.AddFloorRoute(onFloor, 1, id, False, False)
    Else
	  If calledElevator = False And IsAtElevator() Then Building.Elevator.AddFloorRoute(onFloor, 1, id, False, True)
	EndIf
    calledElevator = True
    If Not Building.Elevator.EgoMode Then SortList(Building.Elevator.FloorRouteList)
 End Method

 Method SendElevator:Int()
    Building.Elevator.passenger = id
    toFloor = clickedToFloor
	clickedToFloor = -1
    calledElevator = False
    If id = Game.playerID Or (IsAI() And Game.playerID = 1) Then
	  Building.Elevator.AddFloorRoute(toFloor, 0, id, True, False)
    Else
	  Building.Elevator.AddFloorRoute(toFloor, 0, id, True, True)
	EndIf
 End Method

	Method ChangeTarget(x:Int, _y:Int)
		'if player is not in elevator
		If Self.id <> Building.Elevator.passenger
  			If 0 >= Building.GetFloor(_y) <= 13
				Local StandAtElevatorX:Int = Building.pos.x + Building.Elevator.Pos.x + xToElevator - framewidth
				clickedToRoom = Null
				targetx = x - frameWidth
				oldtargetx = targetx
			    If Building.GetFloor(_y) = onFloor Then toFloor = onFloor Else targetx = StandAtElevatorX
				clickedToFloor = Building.GetFloor(_y)
				Local tmpclickedToRoom:TRooms = TRooms.GetClickedRoom(TFigures(Self))
				If tmpclickedtoroom <> Null
					clickedToRoom = tmpclickedtoroom
					Local figureDoorDifference:Int = 17
					If clickedToRoom.name = "elevator"
						FigureDoorDifference = 0
						If oldtargetx = targetx Then targetx = StandAtElevatorX
						oldtargetx = StandAtElevatorX
					Else
						If oldtargetx = targetx Then targetx = clickedToRoom.Pos.x + figureDoorDifference - framewidth
						oldtargetx = clickedToRoom.Pos.x + figureDoorDifference - framewidth
					EndIf
					tmpclickedtoroom = Null
				EndIf
			EndIf
			inRoom = Null
			If Game.networkgame Then If Network.IsConnected Then Network.SendPlayerPosition()
'		Else
'			Print "Player " + Self.ParentPlayer.playerID + ": in elevator, changetarget not possible"
		EndIf
	End Method

	Method Update(deltaTime:float=1.0)
		If updatefunc_ <> Null
			updatefunc_(ListLink, deltaTime)
		Else
			If id = Game.playerID
				If Int(targetx) = Floor(pos.x)
					If Game.networkgame and LastSync + 1000 < MilliSecs()
						Network.SendPlayerPosition()
						LastSync = MilliSecs()
					EndIf
				EndIf
			EndIf
			Self.FigureMovement(deltaTime)
			Self.FigureAnimation(deltaTime)
		EndIf
		Local localroom:TRooms = clickedToRoom
		If localroom <> Null and localroom <> fromRoom 'Or fromroom = Null Or fromroom.name = "building")
			Local figureDoorDifference:Int = 17
			If clickedToRoom.name = "elevator" Then FigureDoorDifference = 0
			If Self.ControlledByID >= 0 and Self.id <> figure_HausmeisterID 'in multiplayer to be checked if its the player or not
				If inRoom = Null And functions.IsIn(pos.x + framewidth, Building.pos.y + Building.GetFloorY(toFloor) - 5, localroom.Pos.x + FigureDoorDifference, Building.pos.y + Building.GetFloorY(localroom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h, 4, 54)
			        'Print "standing in front of clickedroom"
					AnimPos = 10
					If localroom.doortype >= 0 and localroom.doortype <> 5 and inRoom <> localroom
		        		If id = Game.playerID Then Fader.Enable() 'room fading
						localroom.OpenDoor()
					End If
					If localroom.doortype = 5 and localroom.DoorOpenTimer > 0 and localroom.DoorOpenTimer + Game.DoorOpenTime < MilliSecs()
						localroom.CloseDoor()
						If id = Game.playerID Then Fader.EnableFadeout() 'room fading
						'Print "setinroom:"+localroom.name
        			    SetInRoom(localRoom)
					EndIf
					If localroom.doortype <> 5
						If localroom.name = "elevator" And localroom.Pos.y = onFloor And IsAtElevator()
							If calledElevator = False Then CallElevator()
						EndIf
					EndIf
					If localroom.name = "elevator" And localroom.Pos.y = onFloor And Building.Elevator.onFloor = localroom.Pos.y And Building.Elevator.Open = 1
						SetInRoom(localRoom)
						Building.Elevator.waitAtFloorTimer = MilliSecs() + Building.Elevator.PlanTime
					EndIf
				EndIf
			EndIf
			localRoom = Null
		EndIf
		If Visible and (inRoom = Null or inRoom.name = "elevator")
			If onFloor <> clickedToFloor and IsAtElevator() and clickedToFloor <> - 1
				If calledElevator = False Then CallElevator()
		        If Building.Elevator.passenger = -1 and calledElevator = True and Building.Elevator.Open = 1 and Building.Elevator.onFloor = onFloor
	          		SendElevator()
		        EndIf
			EndIf
			If calledElevator And Int(pos.x) <> Building.pos.x + Building.Elevator.Pos.x + xToElevator - FrameWidth
		        If Ceil(pos.x + 2) <> Building.pos.x + Building.Elevator.Pos.x + xToElevator - FrameWidth
					calledElevator = False
				EndIf
			EndIf
			If IsInElevator() and Building.Elevator.Open = 1 and onFloor = toFloor and toFloor = Building.Elevator.toFloor
				If frameheight + Int(pos.y) = Int(Building.GetFloorY(toFloor))
					targetx = oldtargetx
					Building.Elevator.passenger = -1
					TRooms.GetClickedRoom(Player[Game.playerID].Figure)
				EndIf
			EndIf
	    EndIf

		'limit player position (only within floor 13 and floor 0 allowed)
		If self.pos.y + self.frameheight < Building.GetFloorY(13) Then self.pos.setY( Building.GetFloorY(13) - self.frameheight )
		If self.pos.y + self.frameheight > Building.GetFloorY(0) Then self.pos.setY( Building.GetFloorY(0) - self.frameheight )
	End Method

	Function UpdateAll(deltaTime:float=1.0)
		For Local Figure:TFigures = EachIn TFigures.List
			Figure.Update(deltaTime)
		Next
	End Function

	Method GetDrawPosX:float()
'		return self.lastDrawnPos.x * (1-App.Timer.getTween()) + ( App.Timer.getTween() ) * self.pos.x
		return self.lastDrawnPos.x + App.Timer.getTween() * (self.pos.x - self.lastDrawnPos.x)
	End Method

	Method GetDrawPosY:float()
		'return self.lastDrawnPos.y * (1-App.Timer.getTween()) + ( App.Timer.getTween() ) * self.pos.y
		return self.lastDrawnPos.y + App.Timer.getTween() * (self.pos.y - self.lastDrawnPos.y)
	End Method

	Method Draw()
		Local ShadowDisabled:Int = 1
		Local ShadowX:Int = 3
		If Visible And (inRoom = Null Or inRoom.name = "elevator")
			'if self.lastDrawnPos.x = 0.0 AND self.lastDrawnPos.y = 0.0 then self.lastDrawnPos.setPos(self.pos)
			Local myy:Float = self.pos.y ' self.GetDrawPosY()
			Local myx:Float = self.pos.x ' self.GetDrawPosX()

			If Sprite <> Null
				If Not ShadowDisabled
					SetColor 0, 0, 0
					SetAlpha 0.1
					Sprite.DrawClipped(myx + shadowX, Building.pos.y + myy + 2, myx + shadowX, Building.pos.y + myy, Sprite.framew, Sprite.frameh, 0, 0, AnimPos)
					SetAlpha 0.2
					ShadowX = 2
					Sprite.DrawClipped(myx + shadowX, Building.pos.y + myy + 2, myx + shadowX, Building.pos.y + myy, Sprite.framew, Sprite.frameh, 0, 0, AnimPos)
					SetAlpha 1.0
					SetColor 255, 255, 255
				EndIf
				Sprite.Draw(myx, Building.pos.y + myy, AnimPos)
			Else
				DrawImageInViewPort(image, myx, Building.pos.y + myy + frameheight, 0, AnimPos)
			EndIf
		EndIf
		Self.GetPeopleOnSameFloor()
	End Method

End Type
