'Basictype of all rooms
Type TRooms
    Field background:TGW_Sprites    	   	'background, the image containing the whole room
	Field name:String			= ""  		'name of the room, eg. "archive" for archive room
    Field desc:String			= ""		'description, eg. "Bettys bureau" (used for tooltip)
    Field descTwo:String		= ""		'description, eg. "name of the owner" (used for tooltip)
    Field tooltip:TTooltip		= null		'uses description

	Field DoorTimer:TTimer		= TTimer.Create(500)
	Field Pos:TPoint						'x of the rooms door in the building, y as floornumber
    Field xpos:Int				= 0			'door 1-4 on floor
    Field doortype:Int			=-1
    Field doorwidth:Int			= 38
    Field RoomSign:TRoomSigns
    Field owner:Int				=-1			'to draw the logo/symbol of the owner
    Field id:Int				= 1
	Field FadeAnimationActive:Int = 0
	Field RoomBoardX:Int		= 0
	Field Dialogues:TList		= CreateList()

    Global RoomList:TList		= CreateList()		'global list of rooms
    Global LastID:Int			= 1
	Global doadraw:Int			= 0
	Global DoorsDrawnToBackground:Int = 0   'doors drawn to Pixmap of background

	Method getDoorType:int()
		if self.DoorTimer.isExpired() then return self.doortype else return 5
	End Method

    Method CloseDoor()
		'timer finished
		self.DoorTimer.expire()
    End Method

    Method OpenDoor()
		'timer ticks again
		self.DoorTimer.reset()
    End Method

	Function CloseAllDoors()
		For Local room:TRooms = EachIn TRooms.RoomList
			room.CloseDoor()
		Next
	End Function

    Function DrawDoorToolTips:Int()
		For Local obj:TRooms = EachIn RoomList
			If obj.tooltip and obj.tooltip.enabled Then obj.tooltip.Draw()
		Next
	End Function

    Function UpdateDoorToolTips:Int(deltaTime:float)
		For Local obj:TRooms = EachIn TRooms.RoomList
			'delete and skip if not found
			If not obj then TRooms.RoomList.remove(obj); continue

			If obj.tooltip AND obj.tooltip.enabled
				obj.tooltip.pos.y = Building.pos.y + Building.GetFloorY(obj.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h - 20
				obj.tooltip.Update(deltaTime)
			EndIf

			If Players[Game.playerID].Figure.inRoom = Null And functions.IsIn(MouseX(), MouseY(), obj.Pos.x, Building.pos.y  + building.GetFloorY(obj.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h, obj.doorwidth, 54)
				If obj.tooltip <> null
					obj.tooltip.Hover()
				else
					obj.tooltip = TTooltip.Create(obj.desc, obj.descTwo, 100, 140, 0, 0)
				endif
				obj.tooltip.pos.y	= Building.pos.y + Building.GetFloorY(obj.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h - 20
				obj.tooltip.pos.x	= obj.Pos.x + obj.doorwidth/2 - obj.tooltip.GetWidth()/2
				obj.tooltip.enabled	= 1
				If obj.name = "chief"					Then obj.tooltip.tooltipimage = 2
				If obj.name = "news"					Then obj.tooltip.tooltipimage = 4
				If obj.name = "archive"					Then obj.tooltip.tooltipimage = 0
				If obj.name = "office"					Then obj.tooltip.tooltipimage = 1
				If (obj.name.Find("studio",0)+1) =1		Then obj.tooltip.tooltipimage = 5
				If obj.owner >= 1 Then obj.tooltip.TitleBGtype = obj.owner + 10

				return 0
			EndIf
		Next
    End Function

	Function DrawDoorsOnBackground:Int()
		'do nothing if already done
		If DoorsDrawnToBackground then return 0

		Local Pix:TPixmap = LockImage(Assets.GetSprite("gfx_building").parent.image)

		'fahrstuhlrahmen
		Local elevatorBorder:TGW_Sprites= Assets.GetSprite("gfx_building_Fahrstuhl_Rahmen")
		For Local i:Int = 0 To 13
			DrawOnPixmap(elevatorBorder.getImage(), 0, Pix, 230, 67 - elevatorBorder.h + 73*i)
		Next

		local doorSprite:TGW_Sprites = Assets.GetSprite("gfx_building_Tueren")
		For Local obj:TRooms = EachIn TRooms.RoomList
			'skip invisible rooms (without door)
			if obj.name = "" OR obj.name = "roomboard" OR obj.name = "credits" OR obj.name = "porter" then continue
			If obj.doortype < 0 OR obj.Pos.x <= 0 then continue

			'clamp doortype
			obj.doortype = Min(5, obj.doortype)
			'draw door
			DrawOnPixmap(doorSprite.GetFrameImage(obj.doortype), 0, Pix, obj.Pos.x - Building.pos.x - 127, Building.GetFloorY(obj.Pos.y) - doorSprite.h)
			'draw sign next to door
			If obj.owner < 5 And obj.owner >=0 then DrawOnPixmap(Assets.GetSprite("gfx_building_sign"+obj.owner).parent.image , 0, Pix, obj.Pos.x - Building.pos.x - 127 + 2 + doorSprite.framew, Building.GetFloorY(obj.Pos.y) - doorSprite.h)
        Next
		'no unlock needed atm as doing nothing
		'UnlockImage(Assets.GetSprite("gfx_building").parent.image)
		DoorsDrawnToBackground = True
	End Function

	Function DrawDoors:Int()
		For Local obj:TRooms = EachIn TRooms.RoomList
			'skip invisible rooms (without door)
			if obj.name = "" OR obj.name = "roomboard" OR obj.name = "credits" OR obj.name = "porter" then continue
			If obj.doortype < 0 OR obj.Pos.x <= 0 then continue

			If obj.getDoorType() >= 5
				If obj.getDoorType() = 5 AND obj.DoorTimer.isExpired() Then obj.CloseDoor()
				'valign = 1 -> subtract sprite height
				Assets.GetSprite("gfx_building_Tueren").Draw(obj.Pos.x, Building.pos.y + Building.GetFloorY(obj.Pos.y), obj.getDoorType(), VALIGN_TOP)
			EndIf
		Next
    End Function

	'leave with Open/close-animation (black)
	Method LeaveAnimated:Int(dontleave:Int)
		'roomboard left without animation as soon as something dragged but leave forced
        If Self.name = "roomboard" 	AND TRoomSigns.AdditionallyDragged > 0 Then return True
        If Self.name = "adagency"		Then TContractBlock.ContractsToPlayer(Game.playerID)
        If Self.name = "movieagency"	Then TMovieAgencyBlocks.ProgrammeToPlayer(Game.playerID)
        If Self.name = "archive"		Then TArchiveProgrammeBlock.ProgrammeToSuitcase(Game.playerID)

		If GetDoorType() >= 0
			Fader.Enable() 'room fading
			OpenDoor()
			FadeAnimationActive = True
		Else
			CloseDoor()
			Players[Game.playerID].Figure.LeaveRoom()
		EndIf
		Return false
	End Method

    'draw Room
	Method Draw:int()
		if not self.background then Throw "ERROR: room.draw() - background missing";return 0

		SetBlend SOLIDBLEND
		self.background.Draw(20,10)
		SetBlend ALPHABLEND

		'emit event so custom draw functions can run
		EventManager.triggerEvent( TEventSimple.Create("rooms.onDraw", TData.Create().AddNumber("type", 1), self) )

		TRooms.doadraw = 1
		Select Self.name
			Case "betty"			Room_Betty_Compute(Self) ;Return 0
			Case "safe"				Room_Safe_Compute(Self) ;Return 0
			Case "elevator"			Room_Elevator_Compute(Self) ;Return 0
			Case "roomboard"		Room_RoomBoard_Compute(Self) ;Return 0
			Case "adagency"			Room_AdAgency_Compute(Self) ;Return 0
			Case "stationmap"		Room_StationMap_Compute(Self) ;Return 0
		End Select
		return 0
	End Method

    'process special functions of this room. Is there something to click on?
    'animated gimmicks? draw within this function.
	Method Update:Int()
		TRooms.doadraw = 0

		If Fader.fadeenabled And FadeAnimationActive
			If Fader.fadecount >= 20 And not Fader.fadeout
				Fader.EnableFadeout()
				CloseDoor()
				FadeAnimationActive = False
 			    Players[Game.playerID].Figure.LeaveRoom()
				Return 0
			EndIf
		End If

		'emit event so custom updaters can handle
		'store amount of listeners
		local listeners:int = EventManager.triggerEvent( TEventSimple.Create("rooms.onUpdate", TData.Create().AddNumber("type", 0), self) )

		'something blocks leaving? - check it
		If MOUSEMANAGER.IsDown(2) AND not Self.LeaveAnimated(0) then MOUSEMANAGER.resetKey(2)

		Select Self.name
			Case "betty"			Room_Betty_Compute(Self) ;Return 0
			Case "safe"				Room_Safe_Compute(Self) ;Return 0
			Case "elevator"			Room_Elevator_Compute(Self) ;Return 0
			Case "roomboard"		Room_RoomBoard_Compute(Self) ;Return 0
			Case "adagency"			Room_AdAgency_Compute(Self) ;Return 0
			Case "stationmap"		Room_StationMap_Compute(Self) ;Return 0
		End Select

		'room got no special handling ...
		if listeners = 0 then Players[game.playerID].figure.fromroom = Null
		return 0

	End Method

	Method BaseSetup:TRooms(background:TGW_Sprites, name:string, desc:string, owner:int)
		self.background	= background
		self.name		= name
		self.desc		= desc
		self.owner		= owner
		self.LastID:+1
		self.id			= self.LastID

		self.RoomList.AddLast(self)

		return self
	End Method

    'create room and use preloaded image
    'Raum erstellen und bereits geladenes Bild nutzen
    'x = 1-4
    'y = floor
	Function Create:TRooms(background:TGW_Sprites, name:String = "unknown", desc:String = "unknown", descTwo:String = "", x:Int = 0, y:Int = 0, doortype:Int = -1, owner:Int = -1, createATooltip:Int = 0)
		Local obj:TRooms=New TRooms.BaseSetup(background, name, desc, owner)

		obj.descTwo		= descTwo
		obj.doorwidth	= Assets.GetSprite("gfx_building_Tueren").framew
		obj.xpos		= x
		obj.Pos			= TPoint.Create(0,y)
		If x <=4
			If x = 0 Then obj.Pos.x = -10
			If x = 1 Then obj.Pos.x = 206
			If x = 2 Then obj.Pos.x = 293
			If x = 3 Then obj.Pos.x = 469
			If x = 4 Then obj.Pos.x = 557
		EndIf
		obj.RoomBoardX	= x
		obj.doortype	= doortype
		If createATooltip then obj.CreateRoomsign(x)

		Return obj
	End Function

    'create room and use preloaded image
    'Raum erstellen und bereits geladenes Bild nutzen
	Function CreateWithPos:TRooms(background:TGW_Sprites, name:String = "unknown", desc:String = "unknown", x:Int = 0, xpos:Int = 0, width:Int = 0, y:Int = 0, doortype:Int = -1, owner:Int = -1, createATooltip:Int = 0)
		Local obj:TRooms=New TRooms.BaseSetup(background, name, desc, owner)
		obj.doorwidth	= width
		obj.xpos		= xpos
		obj.Pos			= TPoint.Create(x,y)
		obj.doortype	= doortype
		obj.RoomBoardX	= obj.xpos

		If CreateAToolTip then obj.CreateRoomsign(xpos)

		Return obj
	End Function


	Method CreateRoomsign:int(myx:Int = 0)
		If doortype < 0 then return 0

		Local signx:Int = Self.RoomBoardX
		Local signy:Int = 41 + (13 - Pos.y) * 23
		select signx
			case 1	signx = 26
			case 2	signx = 208
			case 3	signx = 417
			case 4	signx = 599
		end select
		RoomSign = TRoomSigns.Create(desc, signx, signy, owner)
	End Method



    Function GetTargetRoom:TRooms(x:int, y:int)
		For Local room:TRooms = EachIn TRooms.RoomList
			If room.doortype >= 0
				If room.name = "roomboard" Then room.doorwidth = 59
				If functions.IsIn(x, y, room.Pos.x, Building.pos.y + Building.GetFloorY(room.pos.y) - Assets.GetSprite("gfx_building_Tueren").h, room.doorwidth, 54)
					Return room
				EndIf
			EndIf
			If room.name = "elevator" AND functions.IsIn(x, y, Building.pos.x + Building.Elevator.pos.x, Building.pos.y + Building.GetFloorY(room.Pos.y) - 58, Building.Elevator.spriteDoor.sprite.framew, 58)
				room.Pos.x = Building.Elevator.GetDoorCenter()
				Return room
			EndIf
		Next
		Return Null
    End Function

	Function GetRoom:TRooms(ID:Int)
		For Local room:TRooms = EachIn TRooms.RoomList
			If room.id = id Then Return room
		Next
		Return Null
	End Function

	Function GetRoomFromXY:TRooms(x:Int, y:Int)
      if x > 0 and y > 0
        For Local room:TRooms= EachIn TRooms.RoomList
          If room.Pos.x = x And room.Pos.y = y Then Return room
        Next
      EndIf
      Return Null
	End Function

	Function GetRoomFromMapPos:TRooms(x:Int, y:Int)
      if x > 0 and y >= 0
        For Local room:TRooms= EachIn TRooms.RoomList
	      If room.Pos.y = y And room.xpos = x Then Return room
        Next
      EndIf
      Return Null
	End Function

	Function GetRoomByDetails:TRooms(desc:String, owner:Int, strictOwner:int = 1)
		For Local room:TRooms= EachIn TRooms.RoomList
			If room.name = desc and (room.owner = owner OR (strictOwner = 0 AND owner <=0 AND room.owner <=0)) Then Return room
		Next
		Return Null
	End Function
End Type

Type TRoomHandler
	'unused atm global playerID:int

	Function _RegisterHandler(updateFunc(triggerEvent:TEventBase), drawFunc(triggerEvent:TEventBase), room:TRooms = null)
		EventManager.registerListenerFunction( "rooms.onUpdate", updateFunc, room )
		EventManager.registerListenerFunction( "rooms.onDraw", drawFunc, room )
	End Function

	Function Init() abstract
	Function Update:int( triggerEvent:TEventBase ) abstract
	Function Draw:int( triggerEvent:TEventBase ) abstract
End Type


'Office: handling the players room
Type RoomHandler_Office extends TRoomHandler
	global StationsToolTip:TTooltip
	global PlannerToolTip:TTooltip
	global DrawnOnProgrammePlannerBG:int = 0

	Function Init()
		'add gfx to background image
		If Not DrawnOnProgrammePlannerBG then InitProgrammePlannerBackground()


		'register self for all offices
		For local i:int = 1 to 4
			local room:TRooms = null
			room = TRooms.GetRoomByDetails("office", i)
			'only add if room found, else skip reg
			if room then super._RegisterHandler(RoomHandler_Office.Update, RoomHandler_Office.Draw, room)

			room = TRooms.GetRoomByDetails("programmeplanner", i)
			if room then super._RegisterHandler(RoomHandler_Office.Update, RoomHandler_Office.Draw, room)

		Next
	End Function

	Function Draw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Select room.name
			case "programmeplanner"		DrawProgrammePlanner( room )
			case "financials"			DrawFinancials( room )
			case "image"				DrawImage( room )
			default						DrawMain( room )
		End Select
	End Function

	Function Update:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Select room.name
			case "programmeplanner"		UpdateProgrammePlanner( room )
			case "financials"			UpdateFinancials( room )
			case "image"				UpdateImage( room )
			default						UpdateMain( room )
		End Select
	End Function



'===================================
'Office: Room screen
'===================================

	Function DrawMain:int( room:TRooms )
		'allowed for owner only
		If room AND room.owner = Game.playerID
			If StationsToolTip Then StationsToolTip.Draw()
		EndIf

		'allowed for all - if having keys
		If PlannerToolTip <> Null Then PlannerToolTip.Draw()
	End Function

	Function UpdateMain:int( room:TRooms )
		Players[game.playerid].figure.fromroom = Null
		If MouseManager.IsHit(1)
			If functions.IsIn(MouseX(),MouseY(),25,40,150,295)
				Players[Game.playerID].Figure.LeaveRoom()
				MOUSEMANAGER.resetKey(1)
			EndIf
			If functions.IsIn(MouseX(),MouseY(),164,54,67,110) And room.owner = game.playerID
				MOUSEMANAGER.resetKey(1);
				Game.cursorstate = 0;
				Players[game.playerID].figure.inRoom = TRooms.GetRoomByDetails("safe", -1)
				Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", room.owner)
			EndIf
		EndIf

		Game.cursorstate = 0
		If functions.IsIn(MouseX(), MouseY(), 600,140,128,210)
			If PlannerToolTip = Null Then PlannerToolTip = TTooltip.Create("Programmplaner", "und Statistiken", 580, 140, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsHit(1) Then MOUSEMANAGER.resetKey(1);Game.cursorstate = 0;players[game.playerID].figure.inRoom = TRooms.GetRoomByDetails("programmeplanner", room.owner)
		EndIf
		If room.owner = Game.playerID
			If functions.IsIn(MouseX(), MouseY(), 732,45,160,170)
				If not StationsToolTip Then StationsToolTip = TTooltip.Create("Senderkarte", "Kauf und Verkauf", 650, 80, 0, 0)
				StationsToolTip.enabled = 1
				StationsToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsHit(1) Then MOUSEMANAGER.resetKey(1);Game.cursorstate = 0;players[game.playerID].figure.inRoom = TRooms.GetRoomByDetails("stationmap", room.owner)
			EndIf
			If StationsToolTip Then StationsToolTip.Update(App.timer.getDeltaTime())
		EndIf
		If PlannerToolTip Then PlannerToolTip.Update(App.timer.getDeltaTime())
	End Function



'===================================
'Office: ProgrammePlanner screen
'===================================

	'add gfx to background
	Function InitProgrammePlannerBackground:int()
		Local roomImg:TImage				= Assets.GetSprite("rooms_pplanning").parent.image
		Local Pix:TPixmap					= LockImage(roomImg)
		Local gfx_ProgrammeBlock1:TImage	= Assets.GetSprite("pp_programmeblock1").GetImage()
		Local gfx_AdBlock1:TImage			= Assets.GetSprite("pp_adblock1").GetImage()

		'block"shade" on bg
		For Local j:Int = 0 To 11
			DrawOnPixmap(gfx_Programmeblock1, 0, Pix, 67 - 20, 17 - 10 + j * 30, 0.3, 0.8)
			DrawOnPixmap(gfx_Programmeblock1, 0, Pix, 394 - 20, 17 - 10 + j * 30, 0.3, 0.8)
			DrawOnPixmap(gfx_Adblock1, 0, Pix, 67 + ImageWidth(gfx_Programmeblock1) - 20, 17 - 10 + j * 30, 0.3, 0.8)
			DrawOnPixmap(gfx_Adblock1, 0, Pix, 394 + ImageWidth(gfx_Programmeblock1) - 20, 17 - 10 + j * 30, 0.3, 0.8)
		Next


		'set target for font
		Assets.fonts.baseFont.setTargetImage(roomImg)

		For Local i:Int = 0 To 11
			'left side
			Assets.fonts.baseFont.drawStyled( (i + 12) + ":00", 338, 18 + i * 30, 240,240,240,2,0,1,0.25)
			'right side
			local text:string = i + ":00"
			If i < 10 then text = "0" + text
			Assets.fonts.baseFont.drawStyled(text, 10, 18 + i * 30, 240,240,240,2,0,1,0.25)
		Next
		'Ron: not needed - we reference the image
		'room.background = Assets.GetSprite("rooms_pplanning")
		DrawnOnProgrammePlannerBG = True

		'reset target for font
		Assets.fonts.baseFont.resetTarget()
	End Function

	Function DrawProgrammePlanner:int( room:TRooms )
		Local State:Int		= 0
		Local othertime:Int	= 0


		'draw blocks (backgrounds)
		For Local i : Byte = 0 To 23
			local rightSide:int = floor(i / 11) '0-11 = 0,12-23 = 1
			local slotPos:int = i
			if rightSide then slotPos :- 12

			'for programmeblocks
			If Game.day > Game.daytoplan Then State = 4 Else State = 0 'else = game.day < game.daytoplan
			If Game.day = Game.daytoplan
				If i > othertime
					State = 0  'normal
				Else If i = othertime
					State = 2  'running
				Else If i < (Int(Floor((Game.minutesOfDayGone+5) / 60)))
					State = 1  'runned
				EndIf
			EndIf
 			If State <> 0 And State <> 4 '0=normal, 4=old day
				If State = 1
					SetColor 195, 105, 105  'runned - red, if a programme is set, the programme will overlay it
				Else If State = 2
					SetColor 180, 160, 50  'running
				EndIf
				SetAlpha 0.5
				Assets.GetSprite("pp_programmeblock1").Draw(67 + rightSide*327, 17 + slotPos * 30)
			EndIf

			'for adblocks
			If Game.day > Game.daytoplan Then State = 4 Else State = 0 'else = game.day < game.daytoplan
			If Game.day = Game.daytoplan
				othertime = Int(Floor((Game.minutesOfDayGone - 55) / 60))
				If i > othertime
					State = 0  'normal
				Else If i = othertime
					State = 2  'running
				Else If i < (Int(Floor((Game.minutesOfDayGone) / 60)))
					State = 1  'runned
				EndIf
			EndIf

			If State <> 0 And State <> 4 '0=normal, 4=old day
				If State = 1
					SetColor 195, 105, 105  'runned - red, if a programme is set, the programme will overlay it
				Else If State = 2
					SetColor 180, 160, 50  'running
				EndIf
				SetAlpha 0.5
				Assets.GetSprite("pp_adblock1").Draw(67 + rightSide*327 + Assets.GetSprite("pp_programmeblock1").w, 17 + slotPos * 30)
			EndIf
		Next
		SetAlpha 1.0
		SetColor 255, 255, 255  'normal

		TPPbuttons.DrawAll()


		If Players[room.owner].ProgrammePlan.AdditionallyDraggedProgrammeBlocks > 0
			TAdBlock.DrawAll(room.owner)
			SetColor 255,255,255  'normal
			Players[room.owner].ProgrammePlan.DrawAllProgrammeBlocks()
		Else
			Players[room.owner].ProgrammePlan.DrawAllProgrammeBlocks()
			SetColor 255,255,255  'normal
			TAdBlock.DrawAll(room.owner)
		EndIf


		'overlay old days
		If Game.day > Game.daytoplan
			SetColor 100,100,100
			SetAlpha 0.5
			DrawRect(27,17,637,360)
			SetColor 255,255,255
			SetAlpha 1.0
		EndIf

		If Game.daytoplan = Game.day Then SetColor 0,100,0
		If Game.daytoplan < Game.day Then SetColor 100,100,0
		If Game.daytoplan > Game.day Then SetColor 0,0,0
		Assets.GetFont("Default", 10).drawBlock(Game.GetFormattedDay(Game.daytoplan), 691, 17, 100, 15, 0)

		SetColor 255,255,255
		If room.owner = Game.playerID
			If PPprogrammeList.GetOpen() > 0 Then PPprogrammeList.Draw(1)
			If PPcontractList.GetOpen()  > 0 Then PPcontractList.Draw()
			If PPprogrammeList.GetOpen() = 0 And PPcontractList.GetOpen() = 0
				For Local ProgrammeBlock:TProgrammeBlock = EachIn Players[room.owner].ProgrammePlan.ProgrammeBlocks
					If ProgrammeBlock.sendHour >= Game.daytoplan*24 AND ProgrammeBlock.sendHour <= Game.daytoplan*24+24 And..
					   functions.IsIn(MouseX(),MouseY(), ProgrammeBlock.StartPos.x, ProgrammeBlock.StartPos.y, ProgrammeBlock.width, ProgrammeBlock.height*ProgrammeBlock.programme.blocks)
						If Programmeblock.sendHour > game.getDay()*24 + game.GetHour()
							Game.cursorstate = 1
						EndIf
						local showOnRightSide:int = 0
						if MouseX() < 390 then showOnrightSide = 1
						ProgrammeBlock.Programme.ShowSheet(30+328*showOnRightside,20,-1, ProgrammeBlock.programme.parent)
						Exit
					EndIf
				Next
				For Local AdBlock:TAdBlock = EachIn TAdBlock.List
					If room.owner = AdBlock.owner And..
					   AdBlock.senddate = Game.daytoplan And..
					   functions.IsIn(MouseX(),MouseY(), AdBlock.StartPos.x, AdBlock.StartPos.y, AdBlock.width, AdBlock.Height)
						Game.cursorstate = 1
						If MouseX() <= 400 then AdBlock.ShowSheet(358,20);Exit else AdBlock.ShowSheet(30,20);Exit
					EndIf
				Next
			EndIf 'if no programmeList is open
		EndIf
		SetColor 255,255,255


	End Function

	Function UpdateProgrammePlanner:int( room:TRooms )
		Game.cursorstate = 0
		Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", room.owner)
		If functions.IsIn(MouseX(), MouseY(), 759,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsHit(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				Game.daytoplan :+ 1
			endif
		EndIf
		If functions.IsIn(MouseX(), MouseY(), 670,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsHit(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				Game.daytoplan :- 1
			endif
			If Game.daytoplan <= 1 Then Game.daytoplan = 1
		EndIf
		TPPbuttons.UpdateAll()

		TAdBlock.UpdateAll(room.owner)
		Players[room.owner].ProgrammePlan.UpdateAllProgrammeBlocks()

		If room.owner = Game.playerID
			If TProgrammeBlock.AdditionallyDragged > 0 OR TADblock.AdditionallyDragged > 0 Then Game.cursorstate=2
			PPprogrammeList.Update()
			PPcontractList.Update()
		EndIf
	End Function



'===================================
'Office: Financials screen
'===================================

	Function DrawFinancials:int( room:TRooms )
		local finances:TFinancials	= Players[ room.owner ].finances[ Game.getWeekday() ]
		local font13:TBitmapFont	= Assets.GetFont("Default", 14, BOLDFONT)
		local font12:TBitmapFont	= Assets.GetFont("Default", 11)

		local line:int = 14
		font13.drawBlock(Localization.GetString("FINANCES_OVERVIEW") 	,55, 236,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_COSTS")       ,55,  30,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_INCOME")      ,415, 30,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_MONEY_BEFORE"),415,130,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_MONEY_AFTER") ,415,194,330,20, 0,50,50,50)

		font12.drawBlock(Localization.GetString("FINANCES_SOLD_MOVIES") ,415, 49+line*0,330,20,0, 50, 50, 50)
		font12.drawBlock(Localization.GetString("FINANCES_AD_INCOME")   ,415, 49+line*1,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_MISC_INCOME") ,415, 49+line*2,330,20,0, 50, 50, 50)
		font12.drawBlock(finances.sold_movies							,640, 49+line*0, 95,20,2, 50, 50, 50)
		font12.drawBlock(finances.sold_ads       						,640, 49+line*1, 95,20,2,120,120,120)
		font12.drawBlock(finances.sold_misc 							,640, 49+line*2, 95,20,2, 50, 50, 50)
		font12.drawBlock(finances.callerRevenue							,640, 49+line*3, 95,20,2, 50, 50, 50)
		font13.drawBlock(finances.sold_total							,640, 96, 92,20,2, 30, 30, 30)

		font13.drawBlock(finances.revenue_before 						,640,130,92,20,2,30,30,30)
		font12.drawBlock(" + "+Localization.GetString("FINANCES_INCOME"),415,148+line*0,93,20,0,50,50,50)
		font12.drawBlock(" - "+Localization.GetString("FINANCES_COSTS")	,415,148+line*1,93,20,0,120,120,120)
		font12.drawBlock(" - "+Localization.GetString("FINANCES_INTEREST"),415,148+line*2,93,20,0,50,50,50)
		font12.drawBlock(finances.sold_total							,640,148+line*0,93,20,2,50,50,50)
		font12.drawBlock(finances.paid_total							,640,148+line*1,93,20,2,120,120,120)
		font12.drawBlock(finances.revenue_interest						,640,148+line*2,93,20,2,50,50,50)
		font13.drawBlock(finances.money									,640,194,92,20,2,30,30,30)

		font12.drawBlock(Localization.GetString("FINANCES_BOUGHT_MOVIES")   ,55, 49+line*0,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_BOUGHT_STATIONS") ,55, 49+line*1,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_SCRIPTS")         ,55, 49+line*2,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_ACTORS_STAGES")   ,55, 49+line*3,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_PENALTIES")       ,55, 49+line*4,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_STUDIO_RENT")     ,55, 49+line*5,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_NEWS")            ,55, 49+line*6,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_NEWSAGENCIES")    ,55, 49+line*7,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_STATION_COSTS")   ,55, 49+line*8,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_MISC_COSTS")     	,55, 49+line*9,330,20,0,120,120,120)
		font12.drawBlock(finances.paid_movies          ,280, 49+line*0,93,20,2,50,50,50)
		font12.drawBlock(finances.paid_stations        ,280, 49+line*1,93,20,2,120,120,120)
		font12.drawBlock(finances.paid_scripts         ,280, 49+line*2,93,20,2,50,50,50)
		font12.drawBlock(finances.paid_productionstuff ,280, 49+line*3,93,20,2,120,120,120)
		font12.drawBlock(finances.paid_penalty         ,280, 49+line*4,93,20,2,50,50,50)
		font12.drawBlock(finances.paid_rent            ,280, 49+line*5,93,20,2,120,120,120)
		font12.drawBlock(finances.paid_news            ,280, 49+line*6,93,20,2,50,50,50)
		font12.drawBlock(finances.paid_newsagencies    ,280, 49+line*7,93,20,2,120,120,120)
		font12.drawBlock(finances.paid_stationfees     ,280, 49+line*8,93,20,2,50,50,50)
		font12.drawBlock(finances.paid_misc            ,280, 49+line*9,93,20,2,120,120,120)
		font13.drawBlock(finances.paid_total           ,280,194,92,20,2,30,30,30)


		Local maxvalue:float	= 0.0
		Local barrenheight:Float= 0
		For local day:Int = 0 To 6
			For Local obj:TPlayer = EachIn TPlayer.List
				maxValue = max(maxValue, obj.finances[6 - day].money)
			Next
		Next
		SetColor 200, 200, 200
		DrawLine(53,265,578,265)
		DrawLine(53,315,578,315)
		SetColor 255, 255, 255
		TPlayer.List.Sort(False)
		For local day:Int = 0 To 6
			For Local locObject:TPlayer = EachIn TPlayer.List
				barrenheight = 0 + (maxvalue > 0) * Floor((Float(locobject.finances[day].money) / maxvalue) * 100)
				Assets.getSprite("gfx_financials_barren"+locObject.playerID).drawClipped(450 - 65 * (day) + (locObject.playerID) * 9, 365 - barrenheight, 450 - + 65 * (day) + (locObject.playerID) * 9, 265, 21, 100)
			Next
		Next
		'coord descriptor
		font12.drawBlock(functions.convertValue(maxvalue,2,0)       ,478 , 265,100,20,2,180,180,180)
		font12.drawBlock(functions.convertValue(Int(maxvalue/2),2,0),478 , 315,100,20,2,180,180,180)
	End Function

	Function UpdateFinancials:int( room:TRooms )
		Players[ Game.playerID ].Figure.fromRoom = TRooms.GetRoomByDetails("programmeplanner", room.owner)
		Game.cursorstate = 0
	End Function



	'===================================
	'Office: Image screen
	'===================================

	Function DrawImage:int( room:TRooms )
		Assets.GetFont("Default",13).drawBlock(Localization.GetString("IMAGE_REACH") , 55, 233, 330, 20, 0, 50, 50, 50)

		Assets.GetFont("Default",12).drawBlock(Localization.GetString("IMAGE_SHARETOTAL") , 55, 45, 330, 20, 0, 50, 50, 50)
		Assets.GetFont("Default",12).drawBlock(functions.convertPercent(100.0 * Players[room.owner].maxaudience / StationMap.einwohner, 2) + "%", 280, 45, 93, 20, 2, 50, 50, 50)
	End Function

	Function UpdateImage:int( room:TRooms )
		Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("programmeplanner", room.owner)
		Game.cursorstate = 0
	End Function

End Type



'Archive: handling of players programmearchive - for selling it later, ...
Type RoomHandler_Archive extends TRoomHandler

	Function Init()
		'register self for all archives
		For local i:int = 1 to 4
			local room:TRooms = TRooms.GetRoomByDetails("archive", i)
			if room then super._RegisterHandler(RoomHandler_Archive.Update, RoomHandler_Archive.Draw, room)
		Next
	End Function

	Function Draw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Assets.GetSprite("gfx_suitcase").Draw(40, 270)

		If room.owner = Game.playerID
			TArchiveProgrammeBlock.DrawAll(room.owner)
			ArchiveprogrammeList.Draw(False)
		EndIf

		For Local obj:TArchiveProgrammeBlock= EachIn TArchiveProgrammeBlock.List
			'skip other players
			If obj.owner > 0 and obj.owner<>Game.playerID then continue
			'skip problematic ones
			if not obj.Programme then continue

			if functions.IsIn(MouseX(), MouseY(), obj.Pos.x, obj.Pos.y, obj.width, obj.height)
				If obj.dragged = 0 then obj.Programme.ShowSheet(30,20)
				Exit
			EndIf
		Next
	End Function

	Function Update:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Game.cursorstate = 0

		Players[Game.playerID].Figure.fromRoom = Null

		If ArchiveProgrammeList.GetOpen() = 0
			if functions.IsIn(MouseX(), MouseY(), 605,65,120,90) Or functions.IsIn(MouseX(), MouseY(), 525,155,240,225)
				Game.cursorstate = 1
				If MOUSEMANAGER.IsHit(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0
					ArchiveProgrammeList.SetOpen(1)
				endif
			EndIf
		endif

		For Local obj:TArchiveProgrammeBlock= EachIn TArchiveProgrammeBlock.List
			'skip other players
			If obj.owner > 0 and obj.owner<>Game.playerID then exit
			'skip problematic ones
			if not obj.Programme then exit

			if functions.IsIn(MouseX(), MouseY(), obj.Pos.x, obj.Pos.y, obj.width, obj.height)
				If obj.dragged = 0 then game.cursorstate = 1 else game.cursorstate = 2
				Exit
			EndIf
		Next

		If room.owner = Game.playerID
			TArchiveProgrammeBlock.UpdateAll(room.owner)
			ArchiveprogrammeList.Update(False)
		EndIf
	End Function

End Type


'Movie agency
Type RoomHandler_MovieAgency extends TRoomHandler
	Global twinkerTimer:TTimer = TTimer.Create(6000,250)
	Global AuctionToolTip:TTooltip

	Function Init()
		super._RegisterHandler(RoomHandler_MovieAgency.Update, RoomHandler_MovieAgency.Draw, TRooms.GetRoomByDetails("movieagency", 0) )
	End Function

	Function Draw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Select room.name
			case "movieauction"			DrawMovieAuction( room )
			default						DrawMain( room )
		End Select
	End Function

	Function Update:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Select room.name
			case "movieauction"			UpdateMovieAuction( room )
			default						UpdateMain( room )
		End Select
	End Function



'===================================
'Movie Agency: Room screen
'===================================

	Function DrawMain:int( room:TRooms )
		If functions.IsIn(MouseX(), MouseY(), 210,220,140,60) then Assets.GetSprite("gfx_hint_rooms_movieagency").Draw(20,60)

		If twinkerTimer.doAction() then Assets.GetSprite("gfx_gimmick_rooms_movieagency").Draw(10,60)

		local glow:string = ""
		For Local obj:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
			If obj.owner <=0 and obj.dragged
				glow = "_glow"
				exit
			endif
		Next
		Assets.GetSprite("gfx_suitcase"+glow).Draw(530, 240)

		SetAlpha 0.5
		Assets.GetFont("Default",12).drawBlock("Filme", 640, 28, 110,25, 1, 50,50,50)
		Assets.GetFont("Default",12).drawBlock("Serien", 640, 139, 110,25, 1, 50,50,50)
		SetAlpha 1.0

		TMovieAgencyBlocks.DrawAll(True)

		If AuctionToolTip Then AuctionToolTip.Draw()

		ReverseList(TMovieAgencyBlocks.List)
        For Local obj:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
			If obj.owner > 0 and obj.owner <> Game.playerID then continue
            If not obj.Programme then continue

			If obj.dragged = 1 OR functions.IsIn(MouseX(), MouseY(), obj.Pos.x, obj.Pos.y, obj.width, obj.height)
				If obj.dragged Then game.cursorstate = 2 Else Game.cursorstate = 1
				SetColor 0,0,0
				SetAlpha 0.2
				Local x:Float = 120 + Assets.GetSprite("gfx_datasheets_movie").w - 20
				Local tri:Float[]=[x,45.0,x,90.0,obj.Pos.x+obj.width/2.0+3,obj.Pos.y+obj.height/2.0]
				DrawPoly(tri)
				SetColor 255,255,255
				SetAlpha 1.0
				obj.Programme.ShowSheet(120,30)
				Exit
            EndIf
        Next
		ReverseList(TMovieAgencyBlocks.List)
	End Function

	Function UpdateMain:int( room:TRooms )
		Players[game.playerid].figure.fromroom = Null
		Game.cursorstate = 0

		If functions.IsIn(MouseX(), MouseY(), 210,220,140,60)
			If not AuctionToolTip Then AuctionToolTip = TTooltip.Create("Auktion", "Film- und Serienauktion", 200, 180, 0, 0)
			AuctionToolTip.enabled = 1
			AuctionToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsHit(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				players[ game.playerID ].figure.inRoom = TRooms.GetRoomByDetails("movieauction", room.owner)
			endif
		EndIf

		If twinkerTimer.isExpired() then twinkerTimer.Reset()

		TMovieAgencyBlocks.UpdateAll(True)
		If AuctionToolTip Then AuctionToolTip.Update( App.timer.getDeltaTime() )
	End Function



'===================================
'Movie Agency: Room screen
'===================================

	Function DrawMovieAuction:int( room:TRooms )
		Assets.GetSprite("gfx_suitcase").Draw(530, 240)
		SetAlpha 0.5
		Assets.GetFont("Default",12).drawBlock("Filme", 640, 28, 110,25, 1, 50,50,50)
		Assets.GetFont("Default",12).drawBlock("Serien", 640, 139, 110,25, 1, 50,50,50)
		SetAlpha 1.0
		TMovieAgencyBlocks.DrawAll(True)
		SetAlpha 0.5;SetColor 0,0,0
		DrawRect(20,10,760,373)
		SetAlpha 1.0;SetColor 255,255,255
		DrawGFXRect(Assets.GetSpritePack("gfx_gui_rect"), 120, 60, 555, 290)
		SetAlpha 0.5
		Assets.GetFont("Default",12,BOLDFONT).drawBlock(Localization.GetString("CLICK_ON_MOVIE_OR_SERIES_TO_PLACE_BID"), 140,317, 535,30, 1, 230,230,230, false, 2, 1, 0.25)
		SetAlpha 1.0

		TAuctionProgrammeBlocks.DrawAll(0)
	End Function

	Function UpdateMovieAuction:int( room:TRooms )
		Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("movieagency", 0)
		Game.cursorstate = 0
		TAuctionProgrammeBlocks.UpdateAll(0)
	End Function
End Type


'News room
Type RoomHandler_News extends TRoomHandler
	global PlannerToolTip:TTooltip

	Function Init()
		'register self for all archives
		For local i:int = 1 to 4
			local room:TRooms = TRooms.GetRoomByDetails("news", i)
			if room then super._RegisterHandler(RoomHandler_News.Update, RoomHandler_News.Draw, room)
		Next
	End Function

	Function Draw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		If PlannerToolTip Then PlannerToolTip.Draw( App.Timer.getDeltaTime() )
		TNewsbuttons.DrawAll( App.timer.getTween() )
	End Function

	Function Update:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Players[ game.playerid ].figure.fromroom = Null
		TNewsbuttons.UpdateAll( App.timer.getDeltaTime() )
		Game.cursorstate = 0

		If PlannerToolTip Then PlannerToolTip.Update(App.Timer.getDeltaTime())

		If functions.IsIn(MouseX(), MouseY(), 167,60,240,160)
			If not PlannerToolTip Then PlannerToolTip = TTooltip.Create("Newsplaner", "Hinzufügen und entfernen", 180, 100, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsHit(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				players[game.playerID].figure.inRoom = TRooms.GetRoomByDetails("newsplanner", room.owner)
			endif
		endif
	End Function
End Type


'Newsplanner: placing, deleting of news ...
Type RoomHandler_NewsPlanner extends TRoomHandler
	Global Btn_newsplanner_up:TGUIImageButton
	Global Btn_newsplanner_down:TGUIImageButton

	Function Init()
		Btn_newsplanner_up		= new TGUIImageButton.Create(375, 150, 47, 32, "gfx_news_pp_btn_up", 0, 1, "Newsplanner", 0)
		Btn_newsplanner_down	= new TGUIImageButton.Create(375, 250, 47, 32, "gfx_news_pp_btn_down", 0, 1, "Newsplanner", 3)

		'register self for all archives
		For local i:int = 1 to 4
			local room:TRooms = TRooms.GetRoomByDetails("newsplanner", i)
			if room then super._RegisterHandler(RoomHandler_NewsPlanner.Update, RoomHandler_NewsPlanner.Draw, room)
		Next
	End Function

	Function Draw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		SetColor 255,255,255  'normal
		GUIManager.Draw("Newsplanner")
		Players[ room.owner ].ProgrammePlan.DrawAllNewsBlocks()
	End Function

	Function Update:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("news", room.owner)
		Game.cursorstate = 0
		If Btn_newsplanner_up.GetClicks() >= 1 Then TNewsBlock.DecLeftLisTPoint()
		If Btn_newsplanner_down.GetClicks() >= 1 Then TNewsBlock.IncLeftLisTPoint()
		If TNewsBlock.AdditionallyDragged > 0 Then Game.cursorstate=2
		GUIManager.Update("Newsplanner")
		Players[ room.owner ].ProgrammePlan.UpdateAllNewsBlocks()
	End Function

End Type



'Chief: credit and emmys - your boss :D
Type RoomHandler_Chief extends TRoomHandler
	'smoke effect
	Global part_array:TGW_SpritesParticle[100]
	Global spawn_delay:Int = 15

	Function Init()
		'create smoke effect particles
		For Local i:Int = 1 To Len part_array-1
			part_array[i] = New TGW_SpritesParticle
			part_array[i].image = Assets.GetSprite("gfx_tex_smoke")
			part_array[i].life = Rnd(0.100,1.5)
			part_array[i].scale = 1.1
			part_array[i].is_alive =False
			part_array[i].alpha = 1
		Next

		'register self for all bosses
		For local i:int = 1 to 4
			local room:TRooms = TRooms.GetRoomByDetails("chief", i)
			if room then super._RegisterHandler(RoomHandler_Chief.Update, RoomHandler_Chief.Draw, room)
		Next
	End Function

	Function Draw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		For Local i:Int = 1 To Len(part_array)-1
			part_array[i].Draw()
		Next
		For Local dialog:TDialogue = EachIn room.Dialogues
			dialog.Draw()
		Next
	End Function

	Function Update:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Players[game.playerid].figure.fromroom = Null

		If room.Dialogues.Count() <= 0
			Local ChefDialoge:TDialogueTexts[5]
			ChefDialoge[0] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_WELCOME").replace("%1", Players[Game.playerID].name) )
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_WILLNOTDISTURB"), - 2, Null))
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_ASKFORCREDIT"), 1, Null))

			If Players[Game.playerID].GetCreditCurrent() > 0
				ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_REPAYCREDIT"), 3, Null))
			endif
			If Players[Game.playerID].GetCreditAvailable() > 0
				ChefDialoge[1] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_OK").replace("%1", Players[Game.playerID].GetCreditAvailable()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_OK_ACCEPT"), 2, TPlayer.extSetCredit, Players[Game.playerID].GetCreditAvailable()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			Else
				ChefDialoge[1] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY").replace("%1", Players[Game.playerID].GetCreditCurrent()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_ACCEPT"), 3))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			EndIf
			ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))

			ChefDialoge[2] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_BACKTOWORK").replace("%1", Players[Game.playerID].name) )
			ChefDialoge[2].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_BACKTOWORK_OK"), - 2))

			ChefDialoge[3] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_BOSSRESPONSE") )
			If Players[Game.playerID].GetCreditCurrent() >= 100000 And Players[Game.playerID].GetMoney() >= 100000
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_100K"), - 2, TPlayer.extSetCredit, - 1 * 100000))
			EndIf
			If Players[Game.playerID].GetCreditCurrent() < Players[Game.playerID].GetMoney()
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_ALL").replace("%1", Players[Game.playerID].GetCreditCurrent()), - 2, TPlayer.extSetCredit, - 1 * Players[Game.playerID].GetCreditCurrent()))
			EndIf
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))
			Local ChefDialog:TDialogue = TDialogue.Create(350, 60, 450, 200)
			ChefDialog.AddText(Chefdialoge[0])
			ChefDialog.AddText(Chefdialoge[1])
			ChefDialog.AddText(Chefdialoge[2])
			ChefDialog.AddText(Chefdialoge[3])
			room.Dialogues.AddLast(ChefDialog)
		EndIf

		spawn_delay:-1
		If spawn_delay<0
			spawn_delay=5
			For local pp:int = 1 To 64
				For local i:int = 1 To Len(part_array)-1
					If part_array[i].is_alive = False
						part_array[i].Spawn(69,335,Rnd (5.0,35.0),Rnd (0.30,2.75),Rnd (0.2,1.4),Rnd(176, 184),2,2)
						Exit
					EndIf
				Next
			Next
		EndIf
		For local i:int = 1 To Len(part_array)-1
			part_array[i].Update(App.timer.getDeltaTime())
		Next

		For Local dialog:TDialogue = EachIn room.Dialogues
			If dialog.Update(MOUSEMANAGER.IsHit(1)) = 0
				room.LeaveAnimated(0)
				room.Dialogues.Remove(dialog)
			endif
		Next
	End Function

	rem
	  Local ChefText:String
	  ChefText = "Was ist?!" + Chr(13) + "Haben Sie nichts besseres zu tun als meine Zeit zu verschwenden?" + Chr(13) + " " + Chr(13) + "Ab an die Arbeit oder jemand anderes erledigt Ihren Job...!"
	  If Betty.LastAwardWinner <> Game.playerID And Betty.LastAwardWinner <> 0
		If Betty.GetAwardTypeString() <> "NONE" Then ChefText = "In " + (Betty.GetAwardEnding() - Game.day) + " Tagen wird der Preis für " + Betty.GetAwardTypeString() + " verliehen. Holen Sie den Preis oder Ihr Job ist nicht mehr sicher."
		If Betty.LastAwardType <> 0
			ChefText = "Was fällt Ihnen ein den Award für " + Betty.GetAwardTypeString(Betty.LastAwardType) + " nicht zu holen?!" + Chr(13) + " " + Chr(13) + "Naja ich hoffe mal Sie schnappen sich den Preis für " + Betty.GetAwardTypeString() + "."
		EndIf
	  EndIf
	  functions.DrawDialog(Assets.GetSpritePack("gfx_dialog"), 350, 60, 450, 120, "StartLeftDown", 0, ChefText, Font14)
	endrem

End Type




'Buereau: special functions, gimmicks, ...
'Buero: Spezialfunktionen, Gimmicks, ...
Function Room_Safe_Compute(_room:TRooms)
  If TRooms.doadraw 'draw it
  Else
    Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", game.playerID)
    Game.cursorstate = 0
  EndIf
End Function


Function Room_Elevator_Compute(_room:TRooms)
	local playerFigure:TFigures = Players[Game.playerID].figure
	If TRooms.doadraw 'draw it
		TRoomSigns.DrawAll()
		Assets.fonts.baseFont.Draw("Rausschmiss in "+(Building.Elevator.waitAtFloorTimer - MilliSecs()), 600, 20)
	Else
		local mouseHit:int = MouseManager.IsHit(1)

		Game.cursorstate = 0
		playerFigure.fromroom =Null
		If playerFigure.inRoom.name = "elevator"
			if Building.Elevator.waitAtFloorTimer <= MilliSecs()
				Print "Schmeisse Figur " +  playerFigure.Name + " aus dem Fahrstuhl (" + (MilliSecs() - Building.Elevator.waitAtFloorTimer) + ")"
				'waitatfloortimer synchronisieren, wenn spieler fahrstuhlplan betritt
				playerFigure.inElevator		= False
				playerFigure.calledElevator	= False
				playerFigure.inRoom			= Null
				playerFigure.clickedToRoom	= Null
				Building.Elevator.blockedByFigureID = -1
				building.elevator.waitAtFloorTimer = MilliSecs()
			else if mouseHit
				building.Elevator.waitAtFloorTimer = 0
				building.Elevator.blockedByFigureID	= playerFigure.id
				local clickedRoom:TRooms = TRoomSigns.GetRoomFromXY(MouseX(),MouseY())
				if clickedRoom then playerFigure.ChangeTarget(clickedroom.Pos.x, Building.pos.y + Building.GetFloorY(clickedroom.Pos.y))
			endif
		EndIf
		TRoomSigns.UpdateAll(False)
		if mouseHit then MouseManager.ResetKey(1)
	EndIf
End Function

Function Room_RoomBoard_Compute(_room:TRooms)
	if TRooms.doadraw 'draw it
		Players[game.playerid].figure.fromroom =Null
		TRoomSigns.DrawAll()
		Assets.fonts.baseFont.draw("owner:"+_room.owner, 20,20)
		Assets.fonts.baseFont.draw(building.Elevator.waitAtFloorTimer - MilliSecs(), 20,40)
	Else
		' MouseManager.changeStatus()
		Game.cursorstate = 0
		Players[game.playerid].figure.fromroom =Null
		TRoomSigns.UpdateAll(True)
		If MouseManager.IsDown(1) Then MouseManager.resetKey(1)
	EndIf
End Function

Function Room_AdAgency_Compute(_room:TRooms)
	if TRooms.doadraw 'draw it
		Assets.GetSprite("gfx_suitcase").Draw(530, 55)
		' Local locContractX:Int =550
		TContractBlock.DrawAll(True)
        For Local LocObject:TContractBlock= EachIn TContractBlock.List
      	  If locobject.owner <=0 Or locobject.owner=Game.playerID And..
      	     functions.IsIn(MouseX(), MouseY(), LocObject.Pos.x, locobject.Pos.y, locobject.width, locobject.height)
            If LocObject.contract <> Null
			  If LocObject.contract.owner <> 0 Then
			    Local block:TAdBlock = TAdblock.GetBlockByContract(LocObject.contract)
				If block <> Null Then block.ShowSheet(480,185);Exit
				If block =  Null Then LocObject.contract.ShowSheet(480,185);Exit
			  Else
			    If LocObject.dragged Then Game.cursorstate = 2 Else Game.cursorstate = 1
                LocObject.contract.ShowSheet(480,185);Exit
			  EndIf
            EndIf
          EndIf
        Next
	Else
		Players[ game.playerid ].figure.fromroom = Null
		Game.cursorstate = 0
		TContractBlock.UpdateAll(True)
	EndIf
End Function


Function Room_Betty_Compute(_room:TRooms)
  If TRooms.doadraw 'draw it
    Players[Game.playerid].figure.fromroom = Null
	For Local i:Int = 1 To 4
		local sprite:TGW_Sprites = Assets.GetSprite("gfx_room_betty_picture1")
		Local picY:Int = 240
		Local picX:Int = 410 + i * (sprite.w + 5)
		sprite.Draw( picX, picY )
		SetAlpha 0.4
		Players[i].color.SetRGB()
		DrawRect(picX + 2, picY + 8, 26, 28)
		SetColor 255, 255, 255
		SetAlpha 1.0
		local x:float = picX + Int(sprite.framew / 2) - Int(Players[i].Figure.Sprite.framew / 2)
		local y:float = picY + sprite.h - 30
		Players[i].Figure.Sprite.DrawClipped(x, y, x, y, sprite.w, sprite.h-16,0,0,8)
	Next
	Local DlgText:String = "Na Du?" + Chr(13) + "Du könntest ruhig mal öfters bei mir vorbeischauen."
	DrawDialog(Assets.GetSpritePack("gfx_dialog"), 430, 120, 280, 90, "StartLeftDown", 0, DlgText, Assets.GetFont("Default",14))
  EndIf

End Function



Function OnClick_StationMapSell(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local button:TGUIButton = TGUIButton(evt._sender)
		If button <> Null
			if StationMap.action <> 3
				button.value = "Wirklich verkaufen"
				StationMap.action = 3 'selling of stations
			else
				 button.value = "Verkaufen"
				 StationMap.action = 4 'finished selling
			endif
		endif
     EndIf
End Function

Function OnClick_StationMapBuy(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local button:TGUIButton = TGUIButton(evt._sender)
		If button <> Null
			if StationMap.action <> 1
				button.value		= "Kaufen"
				StationMap.action	= 1			'enables buying of stations
			else
				button.value		= "Neue Station"
				StationMap.action 	= 2			'tries to buy
			endif
		EndIf
	endif
End Function

Function OnUpdate_StationMapBuy(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local obj:TGUIButton = TGUIButton(evt._sender)

		If MOUSEMANAGER.IsHit(1) And StationMap.action = 1 And MouseX() < 570
			local ClickPos:TPoint = TPoint.Create( MouseX() - 20, MouseY() - 10 )
			If StationMap.LastStation.pos.isSame( ClickPos )
				EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", null, obj ) )
			Else
				StationMap.LastStation.pos.setPos(clickPos)
			EndIf
			MouseManager.resetKey(1)
			If StationMap.action > 1
				EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", null, obj ) )
			endif
		EndIf
	EndIf
End Function

Function OnUpdate_StationMapSell(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local obj:TGUIButton = TGUIButton(evt._sender)
		If obj <> Null
			If StationMap.sellStation[Game.playerID] <> Null Then obj.enable() Else obj.disable()
		EndIf
	EndIf
End Function

Function OnUpdate_StationMapList(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local obj:TGUIList = TGUIList(evt._sender)
		If obj <> Null
			'first fill of stationlist
			obj.ClearEntries()
			Local counter:Int = 0
			For Local station:TStation = EachIn StationMap.StationList
				If Game.playerID = station.owner
					obj.AddEntry("", "Station (" + functions.convertValue(station.reach, 2, 0) + ")", 0, 0, 0, MilliSecs())
					If obj.ListPosClicked = counter
						StationMap.sellStation[Game.playerID] = station
					EndIf
					counter:+1
				EndIf
			Next
		EndIf
	Endif
End Function

Function OnUpdate_StationMapFilters(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local obj:TGUIOkbutton = TGUIOkbutton(evt._sender)
		If obj <> Null then StationMap.filter_ShowStations[Int(obj.value)] = obj.crossed
	EndIf
End Function

'StationMap-GUIcomponents
Local button:TGUIButton
button = new TGUIButton.Create(TPoint.Create(610, 110), 155,,, , "Neue Station", "STATIONMAP")
button.SetTextalign("CENTER")
EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapBuy, button )
EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapBuy, button )

button = new TGUIButton.Create(TPoint.Create(610, 345), 155,,, , "Station verkaufen", "STATIONMAP")
button.disable()
button.SetTextalign("CENTER")
EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapSell, button )
EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapSell, button )

Local stationlist:TGUIList = new TGUIList.Create(588, 233, 190, 100,, 40, "STATIONMAP")
stationlist.SetControlState(1)
EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapList, stationlist )
For Local i:Int = 0 To 3
	local button:TGUIOkbutton = new TGUIOkButton.Create(535, 30 + i * Assets.GetSprite("gfx_gui_ok_off").h*GUIManager.globalScale, 1, 1, String(i + 1), "STATIONMAP", Assets.GetFont("Default", 11, BOLDFONT))
	EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapFilters, button )
Next


Function Room_StationMap_Compute(_room:TRooms)
  If TRooms.doadraw 'draw it
	Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", _room.owner)
    StationMap.Draw()
	GUIManager.Draw("STATIONMAP")
	Assets.fonts.baseFont.drawBlock("zeige Spieler:", 480, 15, 100, 20, 2)
	For Local i:Int = 0 To 3
		SetColor 100, 100, 100
		DrawRect(564, 32 + i * Assets.GetSprite("gfx_gui_ok_off").h*GUIManager.globalScale, 15, 18)
		Players[i + 1].color.SetRGB()
		DrawRect(565, 33 + i * Assets.GetSprite("gfx_gui_ok_off").h*GUIManager.globalScale, 13, 16)
	Next
	SetColor 255, 255, 255
  Else
	Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", _room.owner)
    StationMap.Update()
	GUIManager.Update("STATIONMAP")
  EndIf
End Function


'signs used in elevator-plan /room-plan
Type TRoomSigns Extends TBlock
  Field title:String				= ""
  Field image:TGW_Sprites			= null
  Field imageWithText:TGW_Sprites	= null
  Field image_dragged:TGW_Sprites	= null

  Global DragAndDropList:TList		= CreateList()
  Global List:TList					= CreateList()
  Global AdditionallyDragged:Int	= 0
  Global DebugMode:Byte				= 1


  Function Create:TRoomSigns(text:String="unknown", x:Int=0, y:Int=0, owner:Int=0)
	  Local LocObject:TRoomSigns=New TRoomSigns
	  LocObject.Pos 	= TPoint.Create(x, y)
	  LocObject.OrigPos	= TPoint.Create(x, y)
	  LocObject.StartPos= TPoint.Create(x, y)

 	  LocObject.dragable = 1
	  LocObject.owner = owner
	  If owner <0 Then owner = 0

 	  Locobject.image			= Assets.GetSprite("gfx_elevator_sign"+owner)
 	  Locobject.image_dragged	= Assets.GetSprite("gfx_elevator_sign_dragged"+owner)
 	  LocObject.width			= LocObject.image.w
 	  LocObject.Height			= LocObject.image.h - 1
 	  LocObject.title			= text
 	  List.AddLast(LocObject)
 	  SortList List
        Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 	    DragAndDrop.slot = CountList(List) - 1
 	    DragAndDrop.pos.setXY(x,y)
 	    DragAndDrop.w = LocObject.image.w
 	    DragAndDrop.h = LocObject.image.h-1
   	    If Not TRoomSigns.DragAndDropList Then TRoomSigns.DragAndDropList = CreateList()
        TRoomSigns.DragAndDropList.AddLast(DragAndDrop)
 	    SortList TRoomSigns.DragAndDropList

 	  Return LocObject
	End Function


    Function ResetPositions()
		For Local obj:TRoomSigns = EachIn TRoomSigns.list
			obj.Pos.SetPos(obj.OrigPos)
			obj.StartPos.SetPos(obj.OrigPos)
			obj.dragged	= 0
		Next
		TRoomSigns.AdditionallyDragged = 0
    End Function


	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method


    Method Compare:Int(otherObject:Object)
       Local s:TRoomSigns = TRoomSigns(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
       Return (dragged * 100)-(s.dragged * 100)
    End Method

    Method GetSlotOfBlock:Int()
    	If Pos.x = 589 then Return 12+(Int(Floor(StartPos.y - 17) / 30))
    	If Pos.x = 262 then Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	Return -1
    End Method

	'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		SetColor 255,255,255;dragable=1  'normal

		If dragged = 1
			If TRoomSigns.AdditionallyDragged > 0 Then SetAlpha 1- 1/TRoomSigns.AdditionallyDragged * 0.25
			if image_dragged <> null
				image_dragged.Draw(Pos.x,Pos.y)
				If imagewithtext <> Null then imagewithtext.Draw(Pos.x,Pos.y)
			endif
		Else
			If imagewithtext <> Null
				imagewithtext.Draw(Pos.x,Pos.y)
			Else
				if image <> null
					image.Draw(Pos.x,Pos.y)
					Local colr:Int = 255
					Local colg:Int = 255
					Local colb:Int = 255
					If colr > 255 Then colr = 255
					If colg > 255 Then colg = 255
					If colb > 255 Then colb = 255
					SetAlpha 1.0;Assets.GetFont("Default",10).drawBlock(title, Pos.x+23,Pos.y+4,150,20,0,0,0,0,1)
					SetAlpha 1.0;Assets.GetFont("Default",10).drawBlock(title, Pos.x+22,Pos.y+3,150,20,0,0,0,0,1)
					Local TxtWidth:Int = Min(TextWidth(title)+4, image.w-23-5)
					Local pixmap:TPixmap = GrabPixmap(Pos.x+23-2,Pos.y+4-2,TxtWidth,TextHeight(title)+3)
					pixmap = ConvertPixmap(pixmap, PF_RGB888)
					blurPixmap(pixmap, 0.5)
					pixmap = ConvertPixmap(pixmap, PF_RGB888)
					DrawImage(LoadImage(pixmap), Pos.x+21,Pos.y+2)

					If owner > 0 And owner <=4
						SetAlpha 1.0;Assets.GetFont("Default",10).drawBlock(title, Pos.x+22,Pos.y+3,150,20,0,colr,colg,colb,1)
					Else
						SetAlpha 1.0;Assets.GetFont("Default",10).drawBlock(title, Pos.x+22,Pos.y+3,150,20,0,250,250,250,1)
					EndIf
				endif
			EndIf
			If imagewithtext = Null AND image <> null
				local newimgwithtext:Timage = TImage.Create(image.w, image.h -1,1,0,255,0,255)
				newimgwithtext.pixmaps[0].format = PF_RGB888
				newimgwithtext.pixmaps[0] = GrabPixmap(Pos.x,Pos.y,image.w,image.h-1)
				newimgwithtext.pixmaps[0] = ConvertPixmap(newimgwithtext.pixmaps[0], PF_RGB888)
				imagewithtext = Assets.ConvertImageToSprite(newimgwithtext, "imagewithtext")
			EndIf
		EndIf
		SetAlpha 1
    End Method


	Function UpdateAll(DraggingAllowed:Byte)
		'Local localslot:Int = 0 								'slot in suitcase

		TRoomSigns.AdditionallyDragged = 0				'reset additional dragged objects
		SortList TRoomSigns.List						'sort blocklist
		ReverseList TRoomSigns.list 					'reorder: first are dragged obj then not dragged

		For Local locObj:TRoomSigns = EachIn TRoomSigns.List
			If locObj <> Null
				If locObj.dragged
					If locObj.StartPosBackup.y = 0 Then
						LocObj.StartPosBackup.SetPos(LocObj.StartPos)
					EndIf
				EndIf
				'block is dragable
				If DraggingAllowed And locObj.dragable
					'if right mbutton clicked and block dragged: reset coord of block
					If MOUSEMANAGER.IsHit(2) And locObj.dragged
						locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y, 1000, 1000)
						locObj.dragged = False
						MOUSEMANAGER.resetKey(2)
					EndIf

					'if left mbutton clicked: drop, replace with underlaying block...
					If MouseManager.IsHit(1)
						'search for underlaying block (we have a block dragged already)
						If locObj.dragged
							'obj over old position - drop ?
							If functions.IsIn(MouseX(),MouseY(),LocObj.StartPosBackup.x,locobj.StartPosBackup.y,locobj.width,locobj.height)
								locObj.dragged = False
							EndIf

							'want to drop in origin-position
							If locObj.ContainingCoord(MouseX(), MouseY())
								locObj.dragged = False
								MouseManager.resetKey(1)
								If Self.DebugMode=1 Then Print "roomboard: dropped to original position"
							'not dropping on origin: search for other underlaying obj
							Else
								For Local OtherLocObj:TRoomSigns = EachIn TRoomSigns.List
									If OtherLocObj <> Null
										If OtherLocObj.ContainingCoord(MouseX(), MouseY()) And OtherLocObj <> locObj And OtherLocObj.dragged = False And OtherLocObj.dragable
'											If game.networkgame Then
'												Network.SendMovieAgencyChange(Network.NET_SWITCH, game.playerID, OtherlocObj.Programme.id, -1, locObj.Programme)
'			  								End If
											locObj.SwitchBlock(otherLocObj)
											If Self.DebugMode=1 Then Print "roomboard: switched - other obj found"
											MouseManager.resetKey(1)
											Exit	'exit enclosing for-loop (stop searching for other underlaying blocks)
										EndIf
									End If
								Next
							EndIf		'end: drop in origin or search for other obj underlaying
						Else			'end: an obj is dragged
							If LocObj.ContainingCoord(MouseX(), MouseY())
								locObj.dragged = 1
								MouseManager.resetKey(1)
							EndIf
						EndIf
					EndIf 				'end: left mbutton clicked
				EndIf					'end: dragable block and player or movieagency is owner
			EndIf 						'end: obj <> NULL

			'if obj dragged then coords to mousecursor+displacement, else to startcoords
			If locObj.dragged = 1
				TRoomSigns.AdditionallyDragged :+1
				Local displacement:Int = TRoomSigns.AdditionallyDragged *5
				locObj.setCoords(MouseX() - locObj.width/2 - displacement, 11+ MouseY() - locObj.height/2 - displacement)
			Else
				locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y,1000,1000)
			EndIf
		Next
		ReverseList TRoomSigns.list 'reorder: first are not dragged obj
  End Function

	Function DrawAll()
		SortList TRoomSigns.List
		For Local locObject:TRoomSigns = EachIn TRoomSigns.List
			Assets.GetSprite("gfx_elevator_sign_bg").Draw(locObject.OrigPos.x + 20, locObject.OrigPos.y + 6)
		Next
		For Local locObject:TRoomSigns = EachIn TRoomSigns.List
			locObject.Draw()
		Next
  End Function

    Function GetRoomFromXY:TRooms(_x:Int, _y:Int)
		Local _width:Int = Assets.GetSprite("gfx_elevator_sign_bg").w
		Local _height:Int = Assets.GetSprite("gfx_elevator_sign_bg").h

		For Local room:TRoomSigns = EachIn TRoomSigns.List
			If room.Pos.x >= 0
				Local signfloor:Int = (13 - Ceil((MouseY() -41) / 23))
				Local xpos:Int = 0
				If room.Pos.x = 26 Then xpos = 1
				If room.Pos.x = 208 Then xpos = 2
				If room.Pos.x = 417 Then xpos = 3
				If room.Pos.x = 599 Then xpos = 4
				If functions.IsIn(_x, _y, room.Pos.x, room.Pos.y, _width, _height)
					Local clickedroom:TRooms = TRooms.GetRoomFromMapPos(xpos, signfloor)
					print "GetRoomFromXY : "+clickedroom.name
					return clickedroom
				EndIf
			EndIf
		Next
		Print "GetRoomFromXY : no room found"
		return null
    End Function

End Type


Function Init_CreateAllRooms()
	For Local i:Int = 1 To 4
		TRooms.Create(Assets.GetSprite("rooms_pplanning") , "programmeplanner", Localization.GetString("ROOM_PROGRAMMEPLANNER") , "", 0, 0, - 1, i)
		TRooms.Create(Assets.GetSprite("rooms_stationmap") , "stationmap", Localization.GetString("ROOM_STATIONMAP") , "", 0, 0, - 1, i)
		TRooms.Create(Assets.GetSprite("rooms_newsplanning") , "newsplanner", Localization.GetString("ROOM_NEWSPLANNER") , "", 0, 0, - 1, i)
		TRooms.Create(Assets.GetSprite("rooms_financials") , "financials", Localization.GetString("ROOM_FINANCES") , "", 0, 0, - 1, i)
		TRooms.Create(Assets.GetSprite("rooms_image") , "image", Localization.GetString("ROOM_IMAGE_AND_QUOTES") , "", 0, 0, - 1, i)
	Next

	'elevator doors, to make them clickable
	For Local i:Int =0 To 13
	  TRooms.Create(Assets.GetSprite("rooms_elevator"), "elevator", Localization.GetString("ROOM_ROOMMAP") , "", 0, i, - 1, 0)
	Next

	'exact xpos
	TRooms.CreateWithPos(Assets.GetSprite("rooms_elevator"), "roomboard", Localization.GetString("ROOM_ROOMBOARD"), 527, 4, 59, 0, 1, - 1)
	TRooms.CreateWithPos(Assets.GetSprite("rooms_credits"), "credits", Localization.GetString("ROOM_CREDITS"), 559, 4, 52, 13, 1, - 1)
	TRooms.CreateWithPos(Assets.GetSprite("rooms_credits"), "porter", Localization.GetString("ROOM_PORTER"), 186, 1, 66, 0, 1, - 1)
	'empty rooms

	PrintDebug("  Init_CreateAllRooms()", "created Rooms", DEBUG_START)

	Local roomMap:TMap = Assets.GetMap("rooms")
	For Local asset:TAsset = EachIn roomMap.Values()
		local room:TMap = TMap(asset._object)
		TRooms.Create(Assets.GetSprite(String(room.ValueForKey("image"))),  ..
					  String(room.ValueForKey("roomname")),  ..
					  Localization.GetString(String(room.ValueForKey("tooltip"))),  ..
					  Localization.GetString(String(room.ValueForKey("tooltip2"))),  ..
					  Int(String(room.ValueForKey("x"))),  ..
					  Int(String(room.ValueForKey("y"))),  ..
					  Int(String(room.ValueForKey("doortype"))),  ..
					  Int(String(room.ValueForKey("owner"))))
	Next

	'connect Update/Draw-Events
	RoomHandler_Office.Init()
	RoomHandler_Archive.Init()
	RoomHandler_MovieAgency.Init()
	RoomHandler_News.Init()
	RoomHandler_NewsPlanner.Init()
	RoomHandler_Chief.Init()


End Function

Function Init_CreateRoomDetails()
	For Local i:Int = 1 To 4
		TRooms.GetRoomByDetails("studiosize1", i).desc:+" " + Players[i].channelname
		TRooms.GetRoomByDetails("office", i).desc:+" " + Players[i].name
		TRooms.GetRoomByDetails("chief", i).desc:+" " + Players[i].channelname
		TRooms.GetRoomByDetails("news", i).desc:+" " + Players[i].channelname
		TRooms.GetRoomByDetails("archive", i).desc:+" " + Players[i].channelname
	Next

	For Local Room:TRooms = EachIn TRooms.RoomList
		Room.CreateRoomsign()
	Next
End Function