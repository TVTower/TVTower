'Basictype of all rooms
'Basictype of all rooms
Type TRooms extends TGameObject  {_exposeToLua="selected"}
	Field screenManager:TScreenManager		= null		'screenmanager - controls what scene to show
	Field name:String			= ""  					'name of the room, eg. "archive" for archive room
    Field desc:String			= ""					'description, eg. "Bettys bureau" (used for tooltip)
    Field descTwo:String		= ""					'description, eg. "name of the owner" (used for tooltip)
    Field tooltip:TTooltip		= null					'uses description

	Field DoorTimer:TIntervalTimer	= TIntervalTimer.Create(1) 'time is set in basecreate depending on changeRoomSpeed..
	Field Pos:TPoint									'x of the rooms door in the building, y as floornumber
    Field doorSlot:Int			= -1					'door 1-4 on floor (<0 is invisible, -1 is unset)
    Field doortype:Int			=-1
    Field doorDimension:TPoint	= TPoint.Create(38,52)
    Field RoomSign:TRoomSigns
    Field owner:Int				=-1						'to draw the logo/symbol of the owner
    Field occupants:TList		= CreateList()			'figure currently in this room
    Field allowMultipleOccupants:int = FALSE			'allow more than one
	Field SoundSource:TDoorSoundSource = TDoorSoundSource.Create(self)
	Field hotspots:TList		= CreateList()			'list of special areas in the room
	Field fakeRoom:int			= FALSE					'is this a room or just a "plan" or "view"

	Global ChangeRoomSpeed:int	= 600					'time the change of a room needs (1st half is opening, 2nd closing the door)
    Global RoomList:TList		= CreateList()			'global list of rooms
	Global DoorsDrawnToBackground:Int = 0   			'doors drawn to Pixmap of background

	const doorSlot0:int	= -10							'x coord of defined slots
	const doorSlot1:int	= 206
	const doorSlot2:int	= 293
	const doorSlot3:int	= 469
	const doorSlot4:int	= 557


    'create room and use preloaded image
    'Raum erstellen und bereits geladenes Bild nutzen
    'x = 1-4
    'y = floor
	Function Create:TRooms(screenManager:TScreenManager, name:String="unknown", desc:String="unknown", descTwo:String="", doorSlot:int=-1, x:Int=0, floor:Int=0, doortype:Int=-1, owner:Int=-1, createRoomplannerSign:Int=FALSE)
		Local obj:TRooms=New TRooms.BaseSetup(screenManager, name, desc, owner)

		obj.descTwo		= descTwo
		obj.doorDimension.SetX( Assets.GetSprite("gfx_building_Tueren").framew )
		obj.doorSlot	= doorSlot
		obj.doortype	= doortype
		'autocalc the position
		if x=-1 and doorSlot>=0 AND doorSlot<=4 then x = getDoorSlotX(doorSlot)
		obj.Pos			= TPoint.Create(x,floor)

		If createRoomplannerSign then obj.CreateRoomsign()

		Return obj
	End Function


	Method BaseSetup:TRooms(screenManager:TScreenManager, name:string, desc:string, owner:int)
		self.screenManager = screenManager
		self.name		= name
		self.desc		= desc
		self.owner		= owner
		self.LastID:+1
		self.id			= self.LastID

		self.DoorTimer.setInterval( ChangeRoomSpeed )

		self.RoomList.AddLast(self)

		EventManager.registerListenerMethod( "room.onTryLeave", self, "onTryLeave", self )
		EventManager.registerListenerMethod( "room.onLeave", self, "onLeave", self )
		EventManager.registerListenerMethod( "room.onTryEnter", self, "onTryEnter", self )
		EventManager.registerListenerMethod( "room.onEnter", self, "onEnter", self )


		return self
	End Method

	Method isOccupant:int(figure:TFigures)
		return self.occupants.contains(figure)
	End Method

	Method hasOccupant:int()
		return self.occupants.count() > 0
	End Method

	Method addOccupant:int(figure:TFigures)
		if not self.occupants.contains(figure)
			self.occupants.addLast(figure)
		endif
		return TRUE
	End Method

	Method removeOccupant:int(figure:TFigures)
		if not self.occupants.contains(figure) then return FALSE

		self.occupants.remove(figure)
		return TRUE
	End Method

	Method addHotspot:int( hotspot:THotspot )
		if hotspot then hotspots.addLast(hotspot);return TRUE
		return FALSE
	End Method


	Function getDoorSlotX:int(slot:int)
		select slot
			case 1	return doorSlot1
			case 2	return doorSlot2
			case 3	return doorSlot3
			case 4	return doorSlot4
		end select

		return 0
	End Function

	Method getDoorSlot:int()
		'already adjusted...
		if self.doorSlot >= 0 then return self.doorSlot

		if int(self.pos.x) = self.doorSlot1 then return 1
		if int(self.pos.x) = self.doorSlot2 then return 2
		if int(self.pos.x) = self.doorSlot3 then return 3
		if int(self.pos.x) = self.doorSlot4 then return 4

		return 0
	End Method

	Method getDoorType:int()
		if self.DoorTimer.isExpired() then return self.doortype else return 5
	End Method


    Method CloseDoor(figure:TFigures)
		'timer finished
		If Not DoorTimer.isExpired()
			SoundSource.PlayDoorSfx(SFX_CLOSE_DOOR, figure)
			self.DoorTimer.expire()
		Endif
    End Method


    Method OpenDoor(figure:TFigures)
		'timer ticks again
		If DoorTimer.isExpired()
			SoundSource.PlayDoorSfx(SFX_OPEN_DOOR, figure)
		Endif
		self.DoorTimer.reset()
    End Method


	Function CloseAllDoors()
		For Local room:TRooms = EachIn TRooms.RoomList
			room.CloseDoor(null)
		Next
	End Function


    Function DrawDoorToolTips:Int()
		For Local obj:TRooms = EachIn RoomList
			If obj.tooltip and obj.tooltip.enabled
				obj.tooltip.Draw()
			endif
		Next
	End Function


    Function UpdateDoorToolTips:Int(deltaTime:float)
		For Local obj:TRooms = EachIn TRooms.RoomList
			'delete and skip if not found
			If not obj then TRooms.RoomList.remove(obj); continue

			If obj.tooltip AND obj.tooltip.enabled
				obj.tooltip.pos.y = Building.pos.y + Building.GetFloorY(obj.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h - 20
				obj.tooltip.Update(deltaTime)
				'delete old tooltips
				if obj.tooltip.lifetime < 0 then obj.tooltip = null
			EndIf

			'only show tooltip if not "empty" and mouse in door-rect
			If obj.desc <> "" and Game.Players[Game.playerID].Figure.inRoom = Null And functions.IsIn(MouseManager.x, MouseManager.y, obj.Pos.x, Building.pos.y  + building.GetFloorY(obj.Pos.y) - obj.doorDimension.y, obj.doorDimension.x, obj.doorDimension.y)
				If obj.tooltip <> null
					obj.tooltip.Hover()
				else
					obj.tooltip = TTooltip.Create(obj.desc, obj.descTwo, 100, 140, 0, 0)
				endif
				obj.tooltip.pos.y	= Building.pos.y + Building.GetFloorY(obj.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h - 20
				obj.tooltip.pos.x	= obj.Pos.x + obj.doorDimension.x/2 - obj.tooltip.GetWidth()/2
				obj.tooltip.enabled	= 1
				If obj.name = "chief"					Then obj.tooltip.tooltipimage = 2
				If obj.name = "news"					Then obj.tooltip.tooltipimage = 4
				If obj.name = "archive"					Then obj.tooltip.tooltipimage = 0
				If obj.name = "office"					Then obj.tooltip.tooltipimage = 1
				If (obj.name.Find("studio",0)+1) =1		Then obj.tooltip.tooltipimage = 5
				If obj.owner >= 1 Then obj.tooltip.TitleBGtype = obj.owner + 10

				'returning leaves other tooltips unhandled (and drawn in a semi-finished-state)
				'return 0
			EndIf
		Next
    End Function


	Method Enter:int( figure:TFigures=null, forceEnter:int )
		'figure is already in that room - so just enter
		if self.isOccupant(figure) then return TRUE

		'ask if enter possible
		'=====================
		'emit event that someone wants to enter a room + param forceEnter
		local event:TEventSimple = TEventSimple.Create("room.onTryEnter", TData.Create().Add("figure", figure).AddNumber("forceEnter", forceEnter) , self )
		EventManager.triggerEvent( Event )
		if event.isVeto()
			'maybe someone wants to know that ...eg. for closing doors
			EventManager.triggerEvent( TEventSimple.Create("room.onCancelEnter", TData.Create().Add("figure", figure) , self ) )
			return FALSE
		endif

'RON: if figure.id = 1 then print "2/4 | room: onTryEnter | room: "+self.name

		'enter is allowed
		'================
		figure.isChangingRoom = true

		'inform others that we start going into the room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginEnter", TData.Create().Add("figure", figure) , self ) )

		'finally inform that the figure enters the room - eg for AI-scripts
		'but delay that by ChangeRoomSpeed/2 - so the real entering takes place later
		event = TEventSimple.Create("room.onEnter", TData.Create().Add("figure", figure) , self )
		event.delayStart(ChangeRoomSpeed/2)
		EventManager.registerEvent( event )

		return TRUE
	End Method


	'gets called if somebody tries to enter that room
	'also kicks figures in rooms if the owner tries to enter
	Method onTryEnter:int( triggerEvent:TEventBase )
		local figure:TFigures = TFigures( triggerEvent.getData().get("figure") )
		if not figure then return FALSE

		local forceEnter:int = triggerEvent.getData().getInt("forceEnter",FALSE)

		'no problem as soon as multiple figures are allowed
		if allowMultipleOccupants then return TRUE

		'occupied, only one figure allowed and figure is not the occupier
		If hasOccupant() and not isOccupant(figure)
			'only player-figures need such handling (events etc.)
			If figure.parentPlayer
				'kick others, except multiple figures allowed in the room
				If figure.parentPlayer.playerID = owner OR forceEnter
					'andere rausschmeissen (falls vorhanden)
					for local occupant:TFigures = eachin occupants
						figure.KickFigureFromRoom(occupant, self)
					next
				'Besetztzeichen ausgeben / KI informieren
				Else
					'Spieler-KI benachrichtigen
					If figure.isAI() then figure.parentPlayer.PlayerKI.CallOnReachRoom(TLuaFunctions.RESULT_INUSE)
					'tooltip only for active user
					If figure.isActivePlayer() then Building.CreateRoomUsedTooltip(self)

					triggerEvent.setVeto()
					return FALSE
				EndIf
			EndIf
		EndIf

		return TRUE
	End Method


	'gets called when the figure really enters the room (fadeout animation finished etc)
	Method onEnter:int( triggerEvent:TEventBase )
		local figure:TFigures = TFigures( triggerEvent.getData().get("figure") )
		if not figure then return FALSE

		'set the room used
		self.addOccupant(figure)

'RON: if figure.id = 1 then print "3/4 | room: onEnter | room: "+self.name+ " | triggering figure.onEnterRoom"
		'inform others that a figure enters the room
		EventManager.triggerEvent( TEventSimple.Create("figure.onEnterRoom", TData.Create().Add("room", self) , figure ) )

		'close the door
		If GetDoorType() >= 0 then CloseDoor(figure)
	End Method



	'a figure wants to leave that room
    Method Leave:int( figure:TFigures=null )
		if not figure then figure = Game.getPlayer().figure

		'figure isn't in that room - so just leave
		if not self.isOccupant(figure) then return TRUE

		'ask if leave possible
		'=====================
		'emit event that someone wants to leave a room
		local event:TEventSimple = TEventSimple.Create("room.onTryLeave", TData.Create().Add("figure", figure) , self )
		EventManager.triggerEvent( Event )
		if event.isVeto()
			EventManager.triggerEvent( TEventSimple.Create("room.onCancelLeave", TData.Create().Add("figure", figure) , self ) )
			return FALSE
		endif

'if figure.id = 1 then
'RON: print "2/4 | figure: "+figure.name+" | room: onTryLeave | room: "+self.name

		'leave is allowed
		'================
		figure.isChangingRoom = true

		'inform others that we start going out of that room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginLeave", TData.Create().Add("figure", figure) , self ) )

		'finally inform that the figure leaves the room - eg for AI-scripts
		'but delay that ChangeRoomSpeed/2 - so the real leaving takes place later
		event = TEventSimple.Create("room.onLeave", TData.Create().Add("figure", figure) , self )
		event.delayStart(ChangeRoomSpeed/2)
		EventManager.registerEvent( event )

		return TRUE
	End Method


	'gets called if somebody tries to leave that room
	'generic handler - could be done individual (in room handlers...)
	Method onTryLeave:int( triggerEvent:TEventBase )
		local figure:TFigures = TFigures( triggerEvent.getData().get("figure") )
		if not figure then return FALSE

		'only pay attention to players
		if figure.ParentPlayer
			'roomboard left without animation as soon as something dragged but leave forced
			If Self.name = "roomboard" 	AND TRoomSigns.AdditionallyDragged > 0
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Method


	'gets called when the figure really leaves the room (fadein animation finished etc)
	Method onLeave:int( triggerEvent:TEventBase )
		local figure:TFigures = TFigures( triggerEvent.getData().get("figure") )
		if not figure then return FALSE

'RON: if figure.id = 1 then print "3/4 | room: onLeave | room: "+self.name+ " | triggering figure.onLeaveRoom"
		'inform others that a figure leaves the room
		EventManager.triggerEvent( TEventSimple.Create("figure.onLeaveRoom", TData.Create().Add("room", self) , figure ) )

		'open the door
		If GetDoorType() >= 0 then OpenDoor(figure)

		'remove the occupant from the rooms list
		removeOccupant(figure)
	End Method



	Function DrawDoorsOnBackground:Int()
		'do nothing if already done
		If DoorsDrawnToBackground then return 0

		Local Pix:TPixmap = LockImage(Assets.GetSprite("gfx_building").parent.image)

		'elevator border
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
				If obj.getDoorType() = 5 AND obj.DoorTimer.isExpired() Then obj.CloseDoor(null); print "DrawDoors - CloseDoor"
				'valign = 1 -> subtract sprite height
				Assets.GetSprite("gfx_building_Tueren").Draw(obj.Pos.x, Building.pos.y + Building.GetFloorY(obj.Pos.y), obj.getDoorType(), VALIGN_TOP)
			EndIf
		Next
    End Function


    'draw Room
	Method Draw:int()
		if not self.screenManager then Throw "ERROR: room.draw() - screenManager missing";return 0

		'draw rooms current screen
		self.screenManager.Draw()
		'emit event so custom functions can run after screen draw, sender = screen
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenDraw", TData.Create().Add("room", self) , self.screenManager.GetCurrentScreen() ) )

		'emit event so custom draw functions can run
		EventManager.triggerEvent( TEventSimple.Create("room.onDraw", TData.Create().AddNumber("type", 1), self) )

		return 0
	End Method


    'process special functions of this room. Is there something to click on?
    'animated gimmicks? draw within this function.
	Method Update:Int()
		'update rooms current screen
		self.screenManager.Update(App.timer.getDeltaTime())
		'emit event so custom functions can run after screen update, sender = screen
		'also this event has "room" as payload
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenUpdate", TData.Create().Add("room", self) , self.screenManager.GetCurrentScreen() ) )

		'emit event so custom updaters can handle
		EventManager.triggerEvent( TEventSimple.Create("room.onUpdate", TData.Create().AddNumber("type", 0), self) )


		'handle normal right click - check subrooms
		'only leave a room if not in a subscreen
		'if in subscreen, go to parent one
		if self.screenManager.GetCurrentScreen() <> self.screenManager.baseScreen
			if MOUSEMANAGER.IsHit(2)
				local event:TEventSimple = TEventSimple.Create("screens.OnLeave", TData.Create().Add("room", self) , self.screenManager.GetCurrentScreen() )
				EventManager.triggerEvent( event )
				if not event.isVeto()
					self.screenManager.GoToParentScreen()
					MOUSEMANAGER.ResetKey(2)
				endif
			endif
		else
			If MOUSEMANAGER.IsHit(2) AND not Game.Players[game.playerID].figure.LeaveRoom() then MOUSEMANAGER.resetKey(2)
		endif

		return 0
	End Method


	Method CreateRoomsign:int(slot:int=-1)
		if slot = -1 then slot = self.doorSlot

		If doortype < 0 then return 0

		local signx:int = 0
		Local signy:Int = 41 + (13 - Pos.y) * 23
		select slot
			case 1	signx = 26
			case 2	signx = 208
			case 3	signx = 417
			case 4	signx = 599
			default return 0
		end select
		RoomSign = TRoomSigns.Create(desc, signx, signy, owner)
		return true
	End Method

    Function GetTargetRoom:TRooms(x:int, y:int)
		For Local room:TRooms = EachIn TRooms.RoomList
			'also allow invisible rooms... so just check if hit the area
			'If room.doortype >= 0 and functions.IsIn(x, y, room.Pos.x, Building.pos.y + Building.GetFloorY(room.pos.y) - room.doorDimension.Y, room.doorDimension.x, room.doorDimension.y)
			If functions.IsIn(x, y, room.Pos.x, Building.pos.y + Building.GetFloorY(room.pos.y) - room.doorDimension.Y, room.doorDimension.x, room.doorDimension.y)
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
		if x < 0 or y < 0 then return NULL

		For Local room:TRooms= EachIn RoomList
			If room.Pos.x = x And room.Pos.y = y Then Return room
		Next

		Return Null
	End Function

	Function GetRoomFromMapPos:TRooms(doorSlot:Int, floor:Int)
		if doorSlot >= 0 and floor >= 0
			For Local room:TRooms= EachIn TRooms.RoomList
				If room.Pos.y = floor And room.doorSlot = doorSlot Then Return room
			Next
		EndIf
		Return Null
	End Function

	Function GetRoomByDetails:TRooms(name:String, owner:Int, floor:int =-1)
		For Local room:TRooms= EachIn TRooms.RoomList
			'skip wrong floors
			if floor >=0 and room.pos.y <> floor then continue
			'skip wrong owners
			if room.owner <> owner then continue

			If room.name = name Then Return room
		Next
		Return Null
	End Function
End Type

Type TRoomHandler

	Function _RegisterHandler(updateFunc(triggerEvent:TEventBase), drawFunc(triggerEvent:TEventBase), room:TRooms = null)
		if room
			EventManager.registerListenerFunction( "room.onUpdate", updateFunc, room )
			EventManager.registerListenerFunction( "room.onDraw", drawFunc, room )
		endif
	End Function

	'special events for screens used in rooms - only this event has the room as sender
	'screens.onScreenUpdate/Draw is more general purpose
	Function _RegisterScreenHandler(updateFunc(triggerEvent:TEventBase), drawFunc(triggerEvent:TEventBase), screen:TScreen)
		if screen
			EventManager.registerListenerFunction( "room.onScreenUpdate", updateFunc, screen )
			EventManager.registerListenerFunction( "room.onScreenDraw", drawFunc, screen )
		endif
	End Function

	Function Init() abstract
	Function Update:int( triggerEvent:TEventBase ) abstract
	Function Draw:int( triggerEvent:TEventBase ) abstract
End Type


'Office: handling the players room
Type RoomHandler_Office extends TRoomHandler
	global StationsToolTip:TTooltip
	global PlannerToolTip:TTooltip
	global SafeToolTip:TTooltip
	global DrawnOnProgrammePlannerBG:int = 0
	global ProgrammePlannerButtons:TGUIImageButton[6]
	global PPprogrammeList:TgfxProgrammelist
	global PPcontractList:TgfxContractlist
	global currentSubRoom:TRooms = null
	global lastSubRoom:TRooms = null

	global stationList:TGUISelectList
	global stationMapMode:int				= 0	'1=searchBuy,2=buy,3=sell
	global stationMapActionConfirmed:int	= FALSE
	global stationMapSelectedStation:TStation
	global stationMapMouseoverStation:TStation

	Global fastNavigateTimer:TIntervalTimer = TIntervalTimer.Create(250)
	Global fastNavigateInitialTimer:int = 250
	Global fastNavigationUsedContinuously:int = FALSE

	Function Init()
		'add gfx to background image
		If Not DrawnOnProgrammePlannerBG then InitProgrammePlannerBackground()

		'connect stationmap buttons/events
		InitStationMap()

		'init lists
		PPprogrammeList		= TgfxProgrammelist.Create(515, 16, 21)
		PPcontractList		= TgfxContractlist.Create(645, 16)


		'programme planner buttons
		TGUILabel.SetDefaultLabelFont( Assets.GetFont("Default", 10, BOLDFONT) )
		ProgrammePlannerButtons[0] = new TGUIImageButton.Create(672, 40+0*56, "programmeplanner_btn_ads","programmeplanner")
		ProgrammePlannerButtons[0].SetCaption(GetLocale("PLANNER_ADS"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[1] = new TGUIImageButton.Create(672, 40+1*56, "programmeplanner_btn_programme","programmeplanner")
		ProgrammePlannerButtons[1].SetCaption(GetLocale("PLANNER_PROGRAMME"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[2] = new TGUIImageButton.Create(672, 40+2*56, "programmeplanner_btn_options","programmeplanner")
		ProgrammePlannerButtons[2].SetCaption(GetLocale("PLANNER_OPTIONS"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[3] = new TGUIImageButton.Create(672, 40+3*56, "programmeplanner_btn_financials","programmeplanner")
		ProgrammePlannerButtons[3].SetCaption(GetLocale("PLANNER_FINANCES"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[4] = new TGUIImageButton.Create(672, 40+4*56, "programmeplanner_btn_image","programmeplanner")
		ProgrammePlannerButtons[4].SetCaption(GetLocale("PLANNER_IMAGE"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[5] = new TGUIImageButton.Create(672, 40+5*56, "programmeplanner_btn_news","programmeplanner")
		ProgrammePlannerButtons[5].SetCaption(GetLocale("PLANNER_MESSAGES"),,TPoint.Create(0,42))
		TGUILabel.SetDefaultLabelFont( null )

		'we are interested in the programmeplanner buttons
		EventManager.registerListenerFunction( "guiobject.onClick", onProgrammePlannerButtonClick )

		'no need for individual screens, all can be handled by one function (room is param)
		super._RegisterScreenHandler( onUpdateOffice, onDrawOffice, TScreen.GetScreen("screen_office") )
		super._RegisterScreenHandler( onUpdateProgrammePlanner, onDrawProgrammePlanner, TScreen.GetScreen("screen_office_pplanning") )
		super._RegisterScreenHandler( onUpdateFinancials, onDrawFinancials, TScreen.GetScreen("screen_office_financials") )
		super._RegisterScreenHandler( onUpdateImage, onDrawImage, TScreen.GetScreen("screen_office_image") )
		super._RegisterScreenHandler( onUpdateStationMap, onDrawStationMap, TScreen.GetScreen("screen_office_stationmap") )

	End Function


'===================================
'Office: Room screen
'===================================

	Function onDrawOffice:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		'allowed for owner only
		If room AND room.owner = Game.playerID
			If StationsToolTip Then StationsToolTip.Draw()
		EndIf

		'allowed for all - if having keys
		If PlannerToolTip <> Null Then PlannerToolTip.Draw()

		If SafeToolTip <> Null Then SafeToolTip.Draw()
	End Function

	Function onUpdateOffice:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.Players[game.playerID].figure.fromroom = Null
		If MOUSEMANAGER.IsClicked(1)
			If functions.IsIn(MouseManager.x,MouseManager.y,25,40,150,295)
				Game.Players[Game.playerID].Figure.LeaveRoom()
				MOUSEMANAGER.resetKey(1)
			EndIf
		EndIf

		Game.cursorstate = 0
		'safe - reachable for all
		If functions.IsIn(MouseManager.x, MouseManager.y, 165,85,70,100)
			If SafeToolTip = Null Then SafeToolTip = TTooltip.Create("Safe", "Laden und Speichern", 140, 100, 0, 0)
			SafeToolTip.enabled = 1
			SafeToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0

				room.screenManager.GoToSubScreen("screen_office_safe")
			endif
		EndIf

		'planner - reachable for all
		If functions.IsIn(MouseManager.x, MouseManager.y, 600,140,128,210)
			If PlannerToolTip = Null Then PlannerToolTip = TTooltip.Create("Programmplaner", "und Statistiken", 580, 140, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				room.screenManager.GoToSubScreen("screen_office_pplanning")
			endif
		EndIf

		'station map - only reachable for owner
		If room.owner = Game.playerID
			If functions.IsIn(MouseManager.x, MouseManager.y, 732,45,160,170)
				If not StationsToolTip Then StationsToolTip = TTooltip.Create("Senderkarte", "Kauf und Verkauf", 650, 80, 0, 0)
				StationsToolTip.enabled = 1
				StationsToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0
					room.screenManager.GoToSubScreen("screen_office_stationmap")
				endif
			EndIf
			If StationsToolTip Then StationsToolTip.Update(App.timer.getDeltaTime())
		EndIf

		If PlannerToolTip Then PlannerToolTip.Update(App.timer.getDeltaTime())
		If SafeToolTip Then SafeToolTip.Update(App.timer.getDeltaTime())
	End Function



'===================================
'Office: ProgrammePlanner screen
'===================================

	'add gfx to background
	Function InitProgrammePlannerBackground:int()
		Local roomImg:TImage				= Assets.GetSprite("screen_bg_pplanning").parent.image
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
			Assets.fonts.baseFont.drawStyled( (i + 12) + ":00", 338, 18 + i * 30, 240,240,240,2,1,0.25)
			'right side
			local text:string = i + ":00"
			If i < 10 then text = "0" + text
			Assets.fonts.baseFont.drawStyled(text, 10, 18 + i * 30, 240,240,240,2,1,0.25)
		Next
		DrawnOnProgrammePlannerBG = True

		'reset target for font
		Assets.fonts.baseFont.resetTarget()
	End Function


	Function onDrawProgrammePlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		Local State:Int		= 0
		Local othertime:Int	= 0

		'draw blocks (backgrounds)
		For Local i : Byte = 0 To 23
			local rightSide:int = floor(i / 11) '0-11 = 0,12-23 = 1
			local slotPos:int = i
			if rightSide then slotPos :- 12

			'for programmeblocks
			If Game.GetDay() > Game.daytoplan Then State = 4 Else State = 0 'else = game.day < game.daytoplan
			If Game.GetDay() = Game.daytoplan
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
			If Game.GetDay() > Game.daytoplan Then State = 4 Else State = 0 'else = game.day < game.daytoplan
			If Game.GetDay() = Game.daytoplan
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

		GUIManager.Draw("programmeplanner")


		If Game.Players[room.owner].ProgrammePlan.AdditionallyDraggedProgrammeBlocks > 0
			TAdBlock.DrawAll(room.owner)
			SetColor 255,255,255  'normal
			Game.Players[room.owner].ProgrammePlan.DrawAllProgrammeBlocks()
		Else
			Game.Players[room.owner].ProgrammePlan.DrawAllProgrammeBlocks()
			SetColor 255,255,255  'normal
			TAdBlock.DrawAll(room.owner)
		EndIf


		'overlay old days
		If Game.GetDay() > Game.daytoplan
			SetColor 100,100,100
			SetAlpha 0.5
			DrawRect(27,17,637,360)
			SetColor 255,255,255
			SetAlpha 1.0
		EndIf

		If Game.daytoplan = Game.GetDay() Then SetColor 0,100,0
		If Game.daytoplan < Game.GetDay() Then SetColor 100,100,0
		If Game.daytoplan > Game.GetDay() Then SetColor 0,0,0
		Assets.GetFont("Default", 10).drawBlock(Game.GetFormattedDay(1+ Game.daytoplan - Game.GetDay(Game.GetTimeStart())), 691, 18, 100, 15, 0)

		SetColor 255,255,255
		If room.owner = Game.playerID
			If PPprogrammeList.GetOpen() > 0 Then PPprogrammeList.Draw(1)
			If PPcontractList.GetOpen()  > 0 Then PPcontractList.Draw()
			If PPprogrammeList.GetOpen() = 0 And PPcontractList.GetOpen() = 0
				For Local ProgrammeBlock:TProgrammeBlock = EachIn Game.Players[room.owner].ProgrammePlan.ProgrammeBlocks
					If ProgrammeBlock.sendHour >= Game.daytoplan*24 AND ProgrammeBlock.sendHour <= Game.daytoplan*24+24 And..
					   functions.IsIn(MouseManager.x,MouseManager.y, ProgrammeBlock.StartPos.x, ProgrammeBlock.StartPos.y, ProgrammeBlock.rect.GetW(), ProgrammeBlock.rect.GetH()*ProgrammeBlock.programme.blocks)
						If Programmeblock.sendHour > game.getDay()*24 + game.GetHour()
							Game.cursorstate = 1
						EndIf
						local showOnRightSide:int = 0
						if MouseManager.x < 390 then showOnrightSide = 1
						ProgrammeBlock.Programme.ShowSheet(30+328*showOnRightside,20,-1, ProgrammeBlock.programme.parent)
						Exit
					EndIf
				Next
				For Local AdBlock:TAdBlock = EachIn Game.Players[ room.owner ].ProgrammePlan.AdBlocks
					If AdBlock.senddate = Game.daytoplan And functions.IsIn(MouseManager.x,MouseManager.y, AdBlock.StartPos.x, AdBlock.StartPos.y, AdBlock.rect.GetW(), AdBlock.rect.GetH())
						Game.cursorstate = 1
						If MouseManager.x <= 400 then AdBlock.ShowSheet(358,20);Exit else AdBlock.ShowSheet(30,20);Exit
					EndIf
				Next
			EndIf 'if no programmeList is open
		EndIf
		SetColor 255,255,255


	End Function

	Function onUpdateProgrammePlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.cursorstate = 0

		If functions.IsIn(MouseManager.x, MouseManager.y, 759,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				Game.daytoplan :+ 1
			endif
		EndIf
		If functions.IsIn(MouseManager.x, MouseManager.y, 670,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				Game.daytoplan :- 1
			endif
		EndIf
		'RON
		'fast movement is possible with keys
		'we use doAction as this allows a decreasing time
		'while keeping the original interval backupped
		if self.fastNavigateTimer.isExpired()
			if not KEYMANAGER.isDown(KEY_PAGEUP) and not KEYMANAGER.isDown(KEY_PAGEDOWN)
				self.fastNavigationUsedContinuously = FALSE
			endif
			if KEYMANAGER.isDown(KEY_PAGEUP) then Game.daytoplan :-1;self.fastNavigationUsedContinuously = TRUE
			if KEYMANAGER.isDown(KEY_PAGEDOWN) then Game.daytoplan :+1;self.fastNavigationUsedContinuously = TRUE


			'modify action time AND reset timer
			if self.fastNavigationUsedContinuously
				'decrease action time each time a bit more...
				self.fastNavigateTimer.setInterval( Max(50, self.fastNavigateTimer.GetInterval() * 0.9), true )
			else
				'set to initial value
				self.fastNavigateTimer.setInterval( self.fastNavigateInitialTimer, true )
			endif
		endif


		'limit to start day
		If Game.daytoplan < Game.GetDay(Game.timeStart) Then Game.daytoplan = Game.GetDay(Game.timeStart)

		GUIManager.Update("programmeplanner")


		local listsOpened:int = (PPprogrammeList.enabled <> 0 Or PPcontractList.enabled <> 0)
		TAdBlock.UpdateAll(room.owner, listsOpened, PPprogrammeList.enabled)
		Game.Players[room.owner].ProgrammePlan.UpdateAllProgrammeBlocks(listsOpened)

		If room.owner = Game.playerID
			'change mouse cursor
			If Game.Players[room.owner].ProgrammePlan.AdditionallyDraggedProgrammeBlocks > 0 then Game.cursorstate=2
			If TADblock.AdditionallyDragged > 0 Then Game.cursorstate=2
			PPprogrammeList.Update()
			PPcontractList.Update()
		EndIf
	End Function


	Function onProgrammePlannerButtonClick:int( triggerEvent:TEventBase )
		local button:TGUIImageButton = TGUIImageButton( triggerEvent._sender )
		if not button then return 0

		'we take care of ALL buttons as we close the lists then
		'if done normal we would do "if ProgrammePlannerButtons[o].clicked then ..."

		'close both lists
		PPcontractList.SetOpen(0)
		PPprogrammeList.SetOpen(0)

		'open others?
		If button = ProgrammePlannerButtons[0] Then return PPcontractList.SetOpen(1)		'opens contract list
		If button = ProgrammePlannerButtons[1] Then return PPprogrammeList.SetOpen(1)		'opens programme genre list

		local room:TRooms = Game.Players[Game.playerID].Figure.inRoom
		'If button = ProgrammePlannerButtons[2] then return room.screenManager.GoToSubScreen("screen_office_options")
		If button = ProgrammePlannerButtons[3] then return room.screenManager.GoToSubScreen("screen_office_financials")
		If button = ProgrammePlannerButtons[4] then return room.screenManager.GoToSubScreen("screen_office_image")
		'If button = ProgrammePlannerButtons[5] then return room.screenManager.GoToSubScreen("screen_office_messages")
	End Function

'===================================
'Office: Financials screen
'===================================

	Function onDrawFinancials:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		local finances:TFinancials	= Game.Players[ room.owner ].finances[ Game.getWeekday() ]
		local font13:TBitmapFont	= Assets.GetFont("Default", 14, BOLDFONT)
		local font12:TBitmapFont	= Assets.GetFont("Default", 11)

		local line:int = 14
		font13.drawBlock(Localization.GetString("FINANCES_OVERVIEW") 	,55, 235,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_COSTS")       ,55,  29,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_INCOME")      ,415, 29,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_MONEY_BEFORE"),415,129,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_MONEY_AFTER") ,415,193,330,20, 0,50,50,50)

		font12.drawBlock(Localization.GetString("FINANCES_SOLD_MOVIES")		,415, 48+line*0,330,20,0, 50, 50, 50)
		font12.drawBlock(Localization.GetString("FINANCES_AD_INCOME")		,415, 48+line*1,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_CALLER_REVENUE")	,415, 48+line*2,330,20,0, 50, 50, 50)
		font12.drawBlock(Localization.GetString("FINANCES_MISC_INCOME")		,415, 48+line*3,330,20,0,120,120,120)
		font12.drawBlock(finances.sold_movies+getLocale("CURRENCY")		,640, 48+line*0, 100,20,2, 50, 50, 50)
		font12.drawBlock(finances.sold_ads+getLocale("CURRENCY")		,640, 48+line*1, 100,20,2,120,120,120)
		font12.drawBlock(finances.callerRevenue+getLocale("CURRENCY")	,640, 48+line*2, 100,20,2, 50, 50, 50)
		font12.drawBlock(finances.sold_misc+getLocale("CURRENCY")		,640, 48+line*3, 100,20,2, 50, 50, 50)
		font13.drawBlock(finances.sold_total+getLocale("CURRENCY")		,640, 48+line*4+5, 100,20,2, 30, 30, 30)

		font13.drawBlock(finances.revenue_before+getLocale("CURRENCY")	,640,129,100,20,2,30,30,30)
		font12.drawBlock("+"											,415,148+line*0,10,20,1,50,50,50)
		font12.drawBlock("-"											,415,148+line*1,10,20,1,120,120,120)
		font12.drawBlock("-"											,415,148+line*2,10,20,1,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_INCOME")		,425,148+line*0,150,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_COSTS")		,425,148+line*1,150,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_INTEREST")	,425,148+line*2,150,20,0,50,50,50)


		font12.drawBlock(finances.sold_total+getLocale("CURRENCY")		,640,148+line*0,100,20,2,50,50,50)
		font12.drawBlock(finances.paid_total+getLocale("CURRENCY")		,640,148+line*1,100,20,2,120,120,120)
		font12.drawBlock(finances.revenue_interest+getLocale("CURRENCY"),640,148+line*2,100,20,2,50,50,50)
		font13.drawBlock(finances.revenue_after+getLocale("CURRENCY")	,640,193,100,20,2,30,30,30)

		font12.drawBlock(getLocale("FINANCES_BOUGHT_MOVIES")				,55, 49+line*0,330,20,0,50,50,50)
		font12.drawBlock(getLocale("FINANCES_BOUGHT_STATIONS")				,55, 49+line*1,330,20,0,120,120,120)
		font12.drawBlock(getLocale("FINANCES_SCRIPTS")						,55, 49+line*2,330,20,0,50,50,50)
		font12.drawBlock(getLocale("FINANCES_ACTORS_STAGES")				,55, 49+line*3,330,20,0,120,120,120)
		font12.drawBlock(getLocale("FINANCES_PENALTIES")					,55, 49+line*4,330,20,0,50,50,50)
		font12.drawBlock(getLocale("FINANCES_STUDIO_RENT")					,55, 49+line*5,330,20,0,120,120,120)
		font12.drawBlock(getLocale("FINANCES_NEWS")							,55, 49+line*6,330,20,0,50,50,50)
		font12.drawBlock(getLocale("FINANCES_NEWSAGENCIES")					,55, 49+line*7,330,20,0,120,120,120)
		font12.drawBlock(getLocale("FINANCES_STATION_COSTS")				,55, 49+line*8,330,20,0,50,50,50)
		font12.drawBlock(getLocale("FINANCES_MISC_COSTS")					,55, 49+line*9,330,20,0,120,120,120)
		font12.drawBlock(finances.paid_movies+getLocale("CURRENCY")			,280, 49+line*0,100,20,2,50,50,50)
		font12.drawBlock(finances.paid_stations+getLocale("CURRENCY")		,280, 49+line*1,100,20,2,120,120,120)
		font12.drawBlock(finances.paid_scripts+getLocale("CURRENCY")		,280, 49+line*2,100,20,2,50,50,50)
		font12.drawBlock(finances.paid_productionstuff+getLocale("CURRENCY"),280, 49+line*3,100,20,2,120,120,120)
		font12.drawBlock(finances.paid_penalty+getLocale("CURRENCY")		,280, 49+line*4,100,20,2,50,50,50)
		font12.drawBlock(finances.paid_rent+getLocale("CURRENCY")            ,280, 49+line*5,100,20,2,120,120,120)
		font12.drawBlock(finances.paid_news+getLocale("CURRENCY")            ,280, 49+line*6,100,20,2,50,50,50)
		font12.drawBlock(finances.paid_newsagencies+getLocale("CURRENCY")    ,280, 49+line*7,100,20,2,120,120,120)
		font12.drawBlock(finances.paid_stationfees+getLocale("CURRENCY")     ,280, 49+line*8,100,20,2,50,50,50)
		font12.drawBlock(finances.paid_misc+getLocale("CURRENCY")            ,280, 49+line*9,100,20,2,120,120,120)
		font13.drawBlock(finances.paid_total+getLocale("CURRENCY")           ,280,193,100,20,2,30,30,30)


		Local maxvalue:float	= 0.0
		Local barrenheight:Float= 0
		For local day:Int = 0 To 6
			'special handling for the first days in a game
			'-> the days which did not happen yet, exception is current day
			if day>0 and day > Game.getDaysPlayed() then continue

			For Local obj:TPlayer = EachIn TPlayer.List
				maxValue = max(maxValue, obj.finances[day].money)
			Next
		Next
		SetColor 200, 200, 200
		DrawLine(53,265,578,265)
		DrawLine(53,315,578,315)
		SetColor 255, 255, 255
		TPlayer.List.Sort(False)
		For local day:Int = 0 To 6
			'draw a background for the current day
			if day = Game.GetWeekday()
				SetAlpha 0.25
				SetColor 180,120,30
				DrawRect (60 + 65 * (day), 265, 65,100)
				SetAlpha 1.0
				SetColor 255,255,255
			endif

			'game day
			if day = Game.GetWeekday()
				font12.drawBlock(Game.GetDayName(day) ,60+65*day , 255,65,20,1,0,0,0)
			else
				font12.drawBlock(Game.GetDayName(day) ,60+65*day , 255,65,20,1,180,180,180)
			endif

			'special handling for the first days in a game
			'-> the days which did not happen yet
			if day > Game.getDaysPlayed() then continue

			For Local locObject:TPlayer = EachIn TPlayer.List
				barrenheight = 0 + (maxvalue > 0) * Floor((Float(locobject.finances[day].money) / maxvalue) * 100)
				if barrenheight > 0
					Assets.getSprite("gfx_financials_barren"+locObject.playerID).drawClipped(60 + 65 * (day) + (locObject.playerID) * 9, 365 - barrenheight, 60 + 65 * (day) + (locObject.playerID) * 9, 265, 21, 100)
				endif
			Next

		Next
		'coord descriptor
		font12.drawBlock(functions.convertValue(maxvalue,2,0)       ,478-1 , 265+1,100,20,2,180,180,180)
		font12.drawBlock(functions.convertValue(Int(maxvalue/2),2,0),478-1 , 315+1,100,20,2,180,180,180)
	End Function

	Function onUpdateFinancials:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		'local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		'if not room then return 0

		Game.cursorstate = 0
	End Function



	'===================================
	'Office: Image screen
	'===================================

	Function onDrawImage:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		Assets.GetFont("Default",13).drawBlock(Localization.GetString("IMAGE_REACH") , 55, 233, 330, 20, 0, 50, 50, 50)

		Assets.GetFont("Default",12).drawBlock(Localization.GetString("IMAGE_SHARETOTAL") , 55, 45, 330, 20, 0, 50, 50, 50)
		Assets.GetFont("Default",12).drawBlock(functions.convertPercent(100.0 * Game.Players[room.owner].StationMap.getCoverage(), 2) + "%", 280, 45, 93, 20, 2, 50, 50, 50)
	End Function

	Function onUpdateImage:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		'local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		'if not room then return 0

		Game.cursorstate = 0
	End Function



	'===================================
	'Office: Stationmap
	'===================================

	Function InitStationMap()
		'StationMap-GUIcomponents
		Local button:TGUIButton
		button = new TGUIButton.Create(TPoint.Create(610, 110), 155, "Sendemast kaufen", "STATIONMAP")
		button.SetTextalign("CENTER")
		EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapBuy, button )
		EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapBuy, button )

		button = new TGUIButton.Create(TPoint.Create(610, 345), 155, "Sendemast verkaufen", "STATIONMAP")
		button.disable()
		button.SetTextalign("CENTER")
		EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapSell, button )
		EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapSell, button )

		'we have to refresh the gui station list as soon as we remove or add a station
		EventManager.registerListenerFunction( "stationmap.removeStation",	OnChangeStationMapStation )
		EventManager.registerListenerFunction( "stationmap.addStation",	OnChangeStationMapStation )

		stationList = new TGUISelectList.Create(595,233,185,100, "STATIONMAP")
		EventManager.registerListenerFunction( "GUISelectList.onSelectEntry", OnSelectEntry_StationMapStationList, stationList )

		For Local i:Int = 0 To 3
			local button:TGUIOkbutton = new TGUIOkButton.Create(535, 30 + i * Assets.GetSprite("gfx_gui_ok_off").h*GUIManager.globalScale, 1, String(i + 1), "STATIONMAP", Assets.GetFont("Default", 11, BOLDFONT))
			EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapFilters, button )
		Next
	End Function

	Function onDrawStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		GUIManager.Draw("STATIONMAP")

		For Local i:Int = 0 To 3
			SetColor 100, 100, 100
			DrawRect(564, 32 + i * Assets.GetSprite("gfx_gui_ok_off").h*GUIManager.globalScale, 15, 18)
			Game.Players[i + 1].color.SetRGB()
			DrawRect(565, 33 + i * Assets.GetSprite("gfx_gui_ok_off").h*GUIManager.globalScale, 13, 16)
		Next
		SetColor 255, 255, 255
		Assets.fonts.baseFont.drawBlock("zeige Spieler:", 480, 15, 100, 20, 2)

		'draw stations and tooltips
		Game.Players[room.owner].StationMap.Draw()

		'also draw the station used for buying/searching
		If stationMapMouseoverStation then stationMapMouseoverStation.Draw()
		'also draw the station used for buying/searching
		If stationMapSelectedStation then stationMapSelectedStation.Draw(true)

		local font:TBitmapFont = Assets.fonts.baseFont
		Assets.fonts.baseFontBold.drawStyled( "Einkauf", 595, 18, 0,0,0, 1, 1, 0.5)
		Assets.fonts.baseFontBold.drawStyled( "Deine Sendemasten", 595, 178, 0,0,0, 1, 1, 0.5)

		'draw a kind of tooltip over a mouseoverStation
		if stationMapMouseoverStation then stationMapMouseoverStation.DrawInfoTooltip()

		If stationMapMode = 1 and stationMapSelectedStation
			SetColor(80, 80, 0)
			Assets.fonts.baseFontBold.draw( getLocale("MAP_COUNTRY_"+stationMapSelectedStation.getFederalState()), 595, 37)

			SetColor(0, 0, 0)
			font.draw("Reichweite: ", 595, 55)
				font.drawBlock(functions.convertValue(String(stationMapSelectedStation.getReach()), 2, 0), 660, 55, 102, 20, 2)
			font.draw("Zuwachs: ", 595, 72)
				font.drawBlock(functions.convertValue(String(stationMapSelectedStation.getReachIncrease()), 2, 0), 660, 72, 102, 20, 2)
			font.draw("Preis: ", 595, 89)
				Assets.fonts.baseFontBold.drawBlock(functions.convertValue(stationMapSelectedStation.getPrice(), 2, 0), 660, 89, 102, 20, 2)
			SetColor(255,255,255)
		EndIf

		If stationMapSelectedStation and stationMapSelectedStation.paid
			SetColor(0, 0, 0)
			font.draw("Reichweite: ", 595, 200)
				font.drawBlock(functions.convertValue(stationMapSelectedStation.reach, 2, 0), 660, 200, 102, 20, 2)
			font.draw("Wert: ", 595, 216)
				Assets.fonts.baseFontBold.drawBlock(functions.convertValue(stationMapSelectedStation.getSellPrice(), 2, 0), 660, 215, 102, 20, 2)
			SetColor(255, 255, 255)
		EndIf

	End Function

	Function onUpdateStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		'backup room if it changed
		if currentSubRoom <> lastSubRoom
			lastSubRoom = currentSubRoom
			'if we changed the room meanwhile - we have to rebuild the stationList
			RefreshStationMapStationList()
		endif

		currentSubRoom = room

		Game.Players[room.owner].StationMap.Update()

		'process right click
		if MOUSEMANAGER.isHit(2)
			local reset:int = (stationMapSelectedStation or stationMapMouseoverStation)

			ResetStationMapAction(0)

			if reset then MOUSEMANAGER.ResetKey(2)

		Endif


		'buying stations using the mouse
		'1. searching
		If stationMapMode = 1
			'create a temporary station if not done yet
			if not StationMapMouseoverStation then StationMapMouseoverStation = TStationMap.getStationMap(room.owner).getTemporaryStation( MouseManager.x -20, MouseManager.y -10 )
			local mousePos:TPoint = TPoint.Create( MouseManager.x -20, MouseManager.y -10)

			'if the mouse has moved - refresh the station data and move station
			if not StationMapMouseoverStation.pos.isSame( mousePos )
				StationMapMouseoverStation.pos.SetPos(mousePos)
				StationMapMouseoverStation.refreshData()
				'refresh state information
				StationMapMouseoverStation.getFederalState(true)
			endif

			'if mouse gets clicked, we store that position in a separate station
			if MOUSEMANAGER.isClicked(1) and StationMapMouseoverStation.getReach()>0
				StationMapSelectedStation = TStationMap.getStationMap(room.owner).getTemporaryStation( StationMapMouseoverStation.pos.x, StationMapMouseoverStation.pos.y )
			endif

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			if StationMapMouseoverStation.getReach() <= 0 then StationMapMouseoverStation = null
			if StationMapSelectedStation and StationMapSelectedStation.getReach() <= 0 then StationMapSelectedStation = null
		endif

		GUIManager.Update("STATIONMAP")
	End Function

	Function OnChangeStationMapStation:int( triggerEvent:TEventBase )
		'do nothing when not in a room
		if not currentSubRoom then return FALSE

		RefreshStationMapStationList( currentSubRoom.owner )
	End Function

	Function ResetStationMapAction(mode:int=0)
		stationMapMode = mode
		stationMapActionConfirmed = FALSE
		'remove selection
		stationMapSelectedStation = null
		stationMapMouseoverStation = Null

		'reset gui list
		stationList.deselectEntry()
	End Function


	'===================================
	'Stationmap: Connect GUI elements
	'===================================

	Function OnUpdate_StationMapBuy:int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		if not currentSubRoom or not Game.isPlayer(currentSubRoom.owner) then return FALSE

		if stationMapMode=1
			button.value = "Kauf bestätigen"
		else
			button.value = "Sendemast kaufen"
		endif
	End Function

	Function OnClick_StationMapBuy:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		if not currentSubRoom or not Game.isPlayer(currentSubRoom.owner) then return FALSE

		'coming from somewhere else... reset first
		if stationMapMode<>1 then ResetStationMapAction(1)

		If stationMapSelectedStation and stationMapSelectedStation.getReach() > 0
			'add the station (and buy it)
			if Game.Players[currentSubRoom.owner].Stationmap.AddStation(stationMapSelectedStation, TRUE)
				ResetStationMapAction(0)
			endif
		EndIf
	End Function


	Function OnClick_StationMapSell:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		if not currentSubRoom or not Game.isPlayer(currentSubRoom.owner) then return FALSE

		'coming from somewhere else... reset first
		if stationMapMode<>2 then ResetStationMapAction(2)

		If stationMapSelectedStation and stationMapSelectedStation.getReach() > 0
			'remove the station (and sell it)
			if Game.Players[currentSubRoom.owner].Stationmap.RemoveStation(stationMapSelectedStation, TRUE)
				ResetStationMapAction(0)
			endif
		EndIf
	End Function

	'enables/disables the button depending on selection
	'sets button label depending on userAction
	Function OnUpdate_StationMapSell:int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		if not currentSubRoom or not Game.isPlayer(currentSubRoom.owner) then return FALSE

		'noting selected yet
		if not stationMapSelectedStation then return FALSE

		'different owner or not paid
		if stationMapSelectedStation.owner <> Game.playerID or not stationMapSelectedStation.paid
			button.disable()
		else
			button.enable()
		endif

		if stationMapMode=2
			button.value = "Verkauf bestätigen"
		else
			button.value = "Sendemast verkaufen"
		endif
	End Function


	'rebuild the stationList - eg. when changed the room (other office)
	Function RefreshStationMapStationList(playerID:int=-1)
		If playerID <= 0 Then playerID = Game.playerID

		'first fill of stationlist
		stationList.EmptyList()
		'remove potential highlighted item
		stationList.deselectEntry()

		For Local station:TStation = EachIn Game.Players[playerID].StationMap.Stations
			local item:TGUISelectListItem = new TGUISelectListItem.Create("Sendemast (" + functions.convertValue(station.reach, 2, 0) + ")",0,0,100,20)
			'link the station to the item
			item.data.Add("station", station)
			stationList.AddItem( item )
		Next
	End Function

	'an entry was selected - make the linked station the currently selected station
	Function OnSelectEntry_StationMapStationList:int(triggerEvent:TEventBase)
		Local senderList:TGUISelectList = TGUISelectList(triggerEvent._sender)
		If not senderList then return FALSE

		if not currentSubRoom or not Game.isPlayer(currentSubRoom.owner) then return FALSE

		'set the linked station as selected station
		'also set the stationmap's userAction so the map knows we want to sell
		local item:TGUISelectListItem = TGUISelectListItem(senderList.getSelectedEntry())
		if item
			stationMapSelectedStation = TStation(item.data.get("station"))
			stationMapMode = 2 'sell
		endif
	End Function

	Function OnUpdate_StationMapFilters:int(triggerEvent:TEventBase)
		Local button:TGUIOkbutton = TGUIOkbutton(triggerEvent._sender)
		if not button then return FALSE

		if not currentSubRoom or not Game.isPlayer(currentSubRoom.owner) then return FALSE
		if int(button.value) < 4 and int(button.value) > 0
			Game.Players[currentSubRoom.owner].StationMap.showStations[Int(button.value)-1] = button.crossed
		endif
	End Function
End Type



'Archive: handling of players programmearchive - for selling it later, ...
Type RoomHandler_Archive extends TRoomHandler
	Global hoveredGuiProgrammeCoverBlock:TGuiProgrammeCoverBlock = null
	Global draggedGuiProgrammeCoverBlock:TGuiProgrammeCoverBlock = null

	Global GuiListSuitcase:TGUIProgrammeSlotList = null
	Global DudeArea:TGUISimpleRect	'allows registration of drop-event

	'configuration
	Global suitcasePos:TPoint				= TPoint.Create(40,270)
	Global suitcaseGuiListDisplace:TPoint	= TPoint.Create(17,27)


	Function Init()
		GuiListSuitcase	= new TGUIProgrammeSlotList.Create(suitcasePos.GetX()+suitcaseGuiListDisplace.GetX(),suitcasePos.GetY()+suitcaseGuiListDisplace.GetY(),200,80, "archive")
		GuiListSuitcase.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.acceptType		= TGUIProgrammeSlotList.acceptAll
		GuiListSuitcase.SetItemLimit( Game.maxMoviesInSuitcaseAllowed )
		GuiListSuitcase.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").w, Assets.GetSprite("gfx_movie0").h)
		GuiListSuitcase.SetAcceptDrop("TGUIProgrammeCoverBlock")

		DudeArea = new TGUISimpleRect.Create(TRectangle.Create(600,100, 200, 350), "archive" )
		'dude should accept drop - else no recognition
		DudeArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)

		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "TGUIBaseCoverBlock.OnMouseOver", onMouseOverProgrammeCoverBlock, "TGUIProgrammeCoverBlock" )
		'drop programme ... so sell/buy the thing
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropProgrammeCoverBlock, "TGUIProgrammeCoverBlock" )
		'drop programme on dude - add back to player's collection
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropProgrammeCoverBlockOnDude, "TGUIProgrammeCoverBlock" )
		'check right clicks on a gui block
		EventManager.registerListenerFunction( "guiobject.onClick", onClickProgrammeBlock, "TGUIProgrammeCoverBlock" )

		'register self for all archives-rooms
		For local i:int = 1 to 4
			local room:TRooms = TRooms.GetRoomByDetails("archive", i)
			if room then super._RegisterHandler(onUpdate, onDraw, room)

			'figure enters room - reset the suitcase's guilist, limit listening to the 4 rooms
			EventManager.registerListenerFunction( "room.onEnter", onEnterRoom, TRooms.GetRoomByDetails("archive",i) )
			EventManager.registerListenerFunction( "room.onTryLeave", onTryLeaveRoom, TRooms.GetRoomByDetails("archive",i) )
		Next

	End Function

	Function onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigures = TFigures(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayer then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammeCoverBlock
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function


	Function CheckPlayerInRoom:int()
		'check if we are in the correct room
		if not Game.getPlayer().figure.inRoom then return FALSE
		if Game.getPlayer().figure.inRoom.name <> "archive" then return FALSE

		return TRUE
	End Function

	'in case of right mouse button click we want to add back the
	'dragged block to the player's programmeCollection
	Function onClickProgrammeBlock:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiBlock:TGUIProgrammeCoverBlock=TGUIProgrammeCoverBlock(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiBlock or not guiBlock.isDragged() then return FALSE

		'add back to collection if already dropped it to suitcase before
		if not Game.GetPlayer().programmeCollection.GetProgramme(guiBlock.programme.id)
			Game.GetPlayer().programmeCollection.RemoveProgrammeFromSuitcase(guiBlock.Programme)
		endif
		'remove the gui element
		guiBlock.remove()
		guiBlock = null
	End Function

	'normally we should split in two parts:
	' OnDrop - check money etc, veto if needed
	' OnDropAccepted - do all things to finish the action
	'but this should be kept simple...
	Function onDropProgrammeCoverBlock:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGUIProgrammeCoverBlock = TGUIProgrammeCoverBlock( triggerEvent._sender )
		local receiverList:TGUIListBase = TGUIListBase( triggerEvent._receiver )
		if not guiBlock or not receiverList then return FALSE

		local owner:int = guiBlock.programme.owner

		select receiverList
			case GuiListSuitcase
				'check if still in collection - if so, remove
				'from collection and add to suitcase
				if Game.GetPlayer().programmeCollection.GetProgramme(guiBlock.programme.id)
					'remove gui - a new one will be generated automatically
					'as soon as added to the suitcase and the room's update
					guiBlock.remove()

					'if not able to add to suitcase (eg. full), cancel
					'the drop-event
					if not Game.GetPlayer().programmeCollection.AddProgrammeToSuitcase(guiBlock.programme)
						triggerEvent.setVeto()
					endif
				endif

				'else it is just a "drop back"
				return TRUE
		end select

		return TRUE
	End Function


	'handle cover block drops on the dude
	Function onDropProgrammeCoverBlockOnDude:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGUIProgrammeCoverBlock = TGUIProgrammeCoverBlock( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver then return FALSE
		if receiver <> DudeArea then return FALSE

		'add back to collection
		Game.GetPlayer().programmeCollection.RemoveProgrammeFromSuitcase(guiBlock.Programme)
		'remove the gui element
		guiBlock.remove()
		guiBlock = null

		return TRUE
	End function


	Function onMouseOverProgrammeCoverBlock:int( triggerEvent:TEventBase )
		local item:TGUIProgrammeCoverBlock = TGUIProgrammeCoverBlock(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProgrammeCoverBlock = item
		if item.isDragged()
			draggedGuiProgrammeCoverBlock = item
			'if we have an item dragged... we cannot have a menu open
			ArchiveprogrammeList.SetOpen(0)
		endif

		return TRUE
	End Function

	'clear the guilist for the suitcase if a player enters
	Function onEnterRoom:int( triggerEvent:TEventBase )
		'we are not interested in other figures than our player's
		local figure:TFigures = TFigures(triggerEvent.GetData().Get("figure"))
		if not figure or not figure.IsActivePlayer() then return FALSE

		'empty the guilist / delete gui elements
		'- the real list still may contain elements with gui-references
		self.guiListSuitcase.EmptyList()
	End Function



	Function onDraw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0
		if room.owner <> Game.playerID then return FALSE

		ArchiveprogrammeList.Draw(False)

		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		if draggedGuiProgrammeCoverBlock then glowSuitcase = "_glow"
		'draw suitcase
		Assets.GetSprite("gfx_suitcase"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		GUIManager.Draw("archive")

		if hoveredGuiProgrammeCoverBlock
			'draw the current sheet
			hoveredGuiProgrammeCoverBlock.DrawSheet()
		endif
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		if room.owner <> game.playerID then return FALSE

		Game.cursorstate = 0

		'open list when clicking dude
		if not draggedGuiProgrammeCoverBlock
			If ArchiveProgrammeList.GetOpen() = 0
				if functions.IsIn(MouseManager.x, MouseManager.y, 605,65,120,90) Or functions.IsIn(MouseManager.x, MouseManager.y, 525,155,240,225)
					Game.cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						Game.cursorstate = 0
						ArchiveProgrammeList.SetOpen(1)
					endif
				EndIf
			endif
			ArchiveprogrammeList.Update(False)
		endif

		'create missing gui elements for the current suitcase
		For local programme:TProgramme = eachin Game.getPlayer().ProgrammeCollection.SuitcaseProgrammeList
			if guiListSuitcase.ContainsProgramme(programme) then continue
			guiListSuitcase.addItem( new TGuiProgrammeCoverBlock.CreateWithProgramme(programme),"-1" )
		Next

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiProgrammeCoverBlock = null
		'reset dragged block too
		draggedGuiProgrammeCoverBlock = null

		GUIManager.Update("archive")

	End Function

End Type


'Movie agency
Type RoomHandler_MovieAgency extends TRoomHandler
	Global twinkerTimer:TIntervalTimer = TIntervalTimer.Create(6000,250)
	Global AuctionToolTip:TTooltip

	Global VendorArea:TGUISimpleRect	'allows registration of drop-event

	Global hoveredGuiProgrammeCoverBlock:TGuiProgrammeCoverBlock = null
	Global draggedGuiProgrammeCoverBlock:TGuiProgrammeCoverBlock = null

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Global listMoviesGood:TProgramme[]
	Global listMoviesCheap:TProgramme[]
	Global listSeries:TProgramme[]

	'graphical lists for interaction with blocks
	Global GuiListMoviesGood:TGUIProgrammeSlotList = null
	Global GuiListMoviesCheap:TGUIProgrammeSlotList = null
	Global GuiListSeries:TGUIProgrammeSlotList = null
	Global GuiListSuitcase:TGUIProgrammeSlotList = null

	'configuration
	Global suitcasePos:TPoint				= TPoint.Create(350,130)
	Global suitcaseGuiListDisplace:TPoint	= TPoint.Create(17,27)
	Global programmesPerLine:int			= 12
	Global movieCheapMaximum:int			= 50000


	Function Init()
		'resize arrays
		listMoviesGood	= listMoviesGood[..programmesPerLine]
		listMoviesCheap	= listMoviesCheap[..programmesPerLine]
		listSeries		= listSeries[..programmesPerLine]

		GuiListMoviesGood	= new TGUIProgrammeSlotList.Create(596,50,200,80, "movieagency")
		GuiListMoviesCheap	= new TGUIProgrammeSlotList.Create(596,148,200,80, "movieagency")
		GuiListSeries		= new TGUIProgrammeSlotList.Create(596,246,200,80, "movieagency")
		GuiListSuitcase		= new TGUIProgrammeSlotList.Create(suitcasePos.GetX()+suitcaseGuiListDisplace.GetX(),suitcasePos.GetY()+suitcaseGuiListDisplace.GetY(),200,80, "movieagency")

		GuiListMoviesGood.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListMoviesCheap.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSeries.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSuitcase.guiEntriesPanel.minSize.SetXY(200,80)

		GuiListMoviesGood.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListMoviesCheap.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSeries.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

		GuiListMoviesGood.acceptType	= TGUIProgrammeSlotList.acceptMovies
		GuiListMoviesCheap.acceptType	= TGUIProgrammeSlotList.acceptMovies
		GuiListSeries.acceptType		= TGUIProgrammeSlotList.acceptSeries
		GuiListSuitcase.acceptType		= TGUIProgrammeSlotList.acceptAll

		GuiListMoviesGood.SetItemLimit( listMoviesGood.length )
		GuiListMoviesCheap.SetItemLimit( listMoviesCheap.length )
		GuiListSeries.SetItemLimit( listSeries.length )
		GuiListSuitcase.SetItemLimit( Game.maxMoviesInSuitcaseAllowed )

		GuiListMoviesGood.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").w, Assets.GetSprite("gfx_movie0").h)
		GuiListMoviesCheap.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").w, Assets.GetSprite("gfx_movie0").h)
		GuiListSeries.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").w, Assets.GetSprite("gfx_movie0").h)
		GuiListSuitcase.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").w, Assets.GetSprite("gfx_movie0").h)

		GuiListMoviesGood.SetAcceptDrop("TGUIProgrammeCoverBlock")
		GuiListMoviesCheap.SetAcceptDrop("TGUIProgrammeCoverBlock")
		GuiListSeries.SetAcceptDrop("TGUIProgrammeCoverBlock")
		GuiListSuitcase.SetAcceptDrop("TGUIProgrammeCoverBlock")

		VendorArea = new TGUISimpleRect.Create(TRectangle.Create(20,60, Assets.GetSprite("gfx_hint_rooms_movieagency").w, Assets.GetSprite("gfx_hint_rooms_movieagency").h), "movieagency" )
		'vendor should accept drop - else no recognition
		VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)

		'drop ... so sell/buy the thing
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropProgrammeCoverBlock, "TGUIProgrammeCoverBlock" )
		'is dragging even allowed? - eg. intercept if not enough money
		EventManager.registerListenerFunction( "guiobject.onDrag", onDragProgrammeCoverBlock, "TGUIProgrammeCoverBlock" )
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "TGUIBaseCoverBlock.OnMouseOver", onMouseOverProgrammeCoverBlock, "TGUIProgrammeCoverBlock" )
		'drop on vendor - sell things
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropProgrammeCoverBlockOnVendor, "TGUIProgrammeCoverBlock" )
		'figure enters room - reset the suitcase's guilist, limit listening to this room
		EventManager.registerListenerFunction( "room.onEnter", onEnterRoom, TRooms.GetRoomByDetails("movieagency",0) )
		'figure leaves room - only without dragged blocks
		EventManager.registerListenerFunction( "room.onTryLeave", onTryLeaveRoom, TRooms.GetRoomByDetails("movieagency",0) )
		EventManager.registerListenerFunction( "room.onLeave", onLeaveRoom, TRooms.GetRoomByDetails("movieagency",0) )

		super._RegisterScreenHandler( onUpdateMovieAgency, onDrawMovieAgency, TScreen.GetScreen("screen_movieagency") )
		super._RegisterScreenHandler( onUpdateMovieAuction, onDrawMovieAuction, TScreen.GetScreen("screen_movieauction") )
	End Function

	'clear the guilist for the suitcase if a player enters
	Function onEnterRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent.GetSender())
		local figure:TFigures = TFigures(triggerEvent.GetData().Get("figure"))
		if not room or not figure then return FALSE

		'we are not interested in other figures than our player's
		if not figure.IsActivePlayer() then return FALSE

		'empty guilists / delete gui elements
		'- the real list still may contain elements with gui-references
		'- this avoids zombies when watching players..
		hoveredGuiProgrammeCoverBlock = null
		draggedGuiProgrammeCoverBlock = null
		GuiListMoviesGood.EmptyList()
		GuiListMoviesCheap.EmptyList()
		GuiListSeries.EmptyList()
		GuiListSuitcase.EmptyList()
	End Function


	Function onTryLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigures = TFigures(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayer then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammeCoverBlock
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function


	'add back the programmes from the suitcase
	'also fill empty blocks, remove gui elements
	Function onLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigures = TFigures(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayer then return FALSE

		figure.parentPlayer.ProgrammeCollection.ReaddProgrammesFromSuitcase()

		'fill all open slots in the agency
		ReFillBlocks()

		return TRUE
	End Function


	'===================================
	'Movie Agency: common functions
	'===================================

	Function GetProgrammesInStock:int()
		Local ret:Int = 0
		local lists:TProgramme[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local programme:TProgramme = EachIn lists[j]
				if programme Then ret:+1
			Next
		Next
		return ret
	End Function


	Function GetProgrammeByPosition:TProgramme(position:int)
		if position > GetProgrammesInStock() then return null
		local currentPosition:int = 0
		local lists:TProgramme[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local programme:TProgramme = EachIn lists[j]
				if programme
					if currentPosition = position then return programme
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Function

	Function HasProgramme:int(programme:TProgramme)
		local lists:TProgramme[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local prog:TProgramme = EachIn lists[j]
				if prog = programme then return TRUE
			Next
		Next
		return FALSE
	End Function

	Function GetProgrammeByProgrammeID:TProgramme(programmeID:int)
		local lists:TProgramme[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local programme:TProgramme = EachIn lists[j]
				if programme and programme.id = programmeID then return programme
			Next
		Next
		return null
	End Function


	Function SellProgrammeToPlayer:int(programme:TProgramme, playerID:int)
		if programme.owner = playerID then return FALSE

		if not Game.isPlayer(playerID) then return FALSE

		'try to add to suitcase of player
		if not Game.Players[ playerID ].ProgrammeCollection.AddProgrammeToSuitcase(programme)
			return FALSE
		endif

		'remove from agency's lists
		local lists:TProgramme[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = programme then lists[j][i] = null
			Next
		Next

		return TRUE
	End Function


	Function BuyProgrammeFromPlayer:int(programme:TProgramme)
		local buy:int = (programme.owner > 0)

		'remove from player (lists and suitcase) - and give him money
		if Game.isPlayer(programme.owner)
			print "remove from player "+programme.owner
			Game.Players[ programme.owner ].ProgrammeCollection.RemoveProgramme(programme, TRUE)
		endif

		'add to agency's lists - if not existing yet
		if not HasProgramme(programme) then AddProgramme(programme)

		return TRUE
	End Function


	Function AddProgramme:int(programme:TProgramme)
		'try to fill the program into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TProgramme[][]

		if programme.isMovie()
			if programme.getPrice() < movieCheapMaximum
				lists = [listMoviesCheap,listMoviesGood]
			else
				lists = [listMoviesGood,listMoviesCheap]
			endif
		else
			lists = [listSeries]
		endif

		'loop through all lists - as soon as we find a spot
		'to place the programme - do so and return
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if lists[j][i] then continue
				programme.owner = -1
				lists[j][i] = programme
				'print "added programme "+programme.title+" to list "+j+" at spot:"+i
				return TRUE
			Next
		Next

		'there was no empty slot to place that programme
		'so just give it back to the pool
		programme.owner = 0

		return FALSE
	End Function



	'refills slots in the movie agency
	Function ReFillBlocks:Int()
		local lists:TProgramme[][] = [listMoviesGood,listMoviesCheap,listSeries]
		local programme:TProgramme = null

		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				'if exists...skip it
				if lists[j][i] then continue

				if lists[j] = listMoviesGood then programme = TProgramme.GetRandomMovieWithPrice(75000)
				if lists[j] = listMoviesCheap then programme = TProgramme.GetRandomMovieWithPrice(0,75000)
				if lists[j] = listSeries then programme = TProgramme.GetRandomSerie()

				'add new programme at slot
				if programme
					programme.owner = -1
					lists[j][i] = programme
				else
					print "ERROR: Not enough programmes to fill movie agency in list "+i
				endif
			Next
		Next
	End Function


	Function CheckPlayerInRoom:int()
		'check if we are in the correct room
		if not Game.getPlayer().figure.inRoom then return FALSE
		if Game.getPlayer().figure.inRoom.name <> "movieagency" then return FALSE

		return TRUE
	End Function



	'===================================
	'Movie Agency: Room screen
	'===================================


	Function onMouseOverProgrammeCoverBlock:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local item:TGUIProgrammeCoverBlock = TGUIProgrammeCoverBlock(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProgrammeCoverBlock = item
		if item.isDragged() then draggedGuiProgrammeCoverBlock = item

		return TRUE
	End Function


	'check if we are allowed to drag that programmeblock
	Function onDragProgrammeCoverBlock:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local item:TGUIProgrammeCoverBlock = TGUIProgrammeCoverBlock(triggerEvent.GetSender())
		if item = Null then return FALSE

		local owner:int = item.programme.owner

		'do not allow dragging items from other players
		if owner > 0 and owner <> Game.playerID
			triggerEvent.setVeto()
			return FALSE
		endif

		'check whether a player could afford the programme
		if owner <= 0
			if not Game.getPlayer().getFinancial().canAfford(item.programme.getPrice())
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Function


	'normally we should split in two parts:
	' OnDrop - check money etc, veto if needed
	' OnDropAccepted - do all things to finish the action
	'but this should be kept simple...
	Function onDropProgrammeCoverBlock:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGUIProgrammeCoverBlock = TGUIProgrammeCoverBlock( triggerEvent._sender )
		local receiverList:TGUIListBase = TGUIListBase( triggerEvent._receiver )
		if not guiBlock or not receiverList then return FALSE

		local owner:int = guiBlock.programme.owner

		select receiverList
			case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'no problem when dropping vendor programme on vendor shelf..
				if guiBlock.programme.owner <= 0 then return TRUE

				if not BuyProgrammeFromPlayer(guiBlock.programme)
					triggerEvent.setVeto()
					return TRUE
				endif
			case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				if guiBlock.programme.owner = Game.playerID then return TRUE

				if not SellProgrammeToPlayer(guiBlock.programme, Game.playerID)
					triggerEvent.setVeto()
					'try to drop back to old list - which triggers
					'this function again... but with a differing list..
					guiBlock.dropBackToOrigin()
				endif
		end select

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropProgrammeCoverBlockOnVendor:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGUIProgrammeCoverBlock = TGUIProgrammeCoverBlock( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver then return FALSE
		if receiver <> VendorArea then return FALSE

		'do not accept blocks from the vendor itself
		if guiBlock.programme.owner <=0
			triggerEvent.setVeto()
			return FALSE
		endif

		if not BuyProgrammeFromPlayer(guiBlock.programme)
			triggerEvent.setVeto()
			return FALSE
		else
			'successful - delete that gui block
			guiBlock.remove()
			'remove the whole block too
			guiBlock = null
		endif

		return TRUE
	End function


	Function onDrawMovieAgency:int( triggerEvent:TEventBase )
		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		local glowVendor:string = ""
		if draggedGuiProgrammeCoverBlock
			if draggedGuiProgrammeCoverBlock.programme.owner <= 0
				glowSuitcase = "_glow"
			else
				glowVendor = "_glow"
			endif
		endif

		'let the vendor glow if over auction hammer
		'or if a player's block is dragged
		if not draggedGuiProgrammeCoverBlock
			If functions.IsIn(MouseManager.x, MouseManager.y, 210,220,140,60)
				Assets.GetSprite("gfx_hint_rooms_movieagency").Draw(20,60)
			endif
		else
			if glowVendor="_glow"
				Assets.GetSprite("gfx_hint_rooms_movieagency").Draw(20,60)
			endif
		endif
		'let the vendor twinker sometimes...
		If twinkerTimer.doAction() then Assets.GetSprite("gfx_gimmick_rooms_movieagency").Draw(10,60)
		'draw suitcase
		Assets.GetSprite("gfx_suitcase"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		SetAlpha 0.5
		Assets.GetFont("Default",12, BOLDFONT).drawBlock("Filme",		642,  27+3, 108,20, 1, 50,50,50,0,1)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock("Ramschkiste",	642, 125+3, 108,20, 1, 50,50,50,0,1)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock("Serien", 		642, 223+3, 108,20, 1, 50,50,50,0,1)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")

		if hoveredGuiProgrammeCoverBlock
			'draw the current sheet
			hoveredGuiProgrammeCoverBlock.DrawSheet()
		endif


		If AuctionToolTip Then AuctionToolTip.Draw()
	End Function

	Function onUpdateMovieAgency:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.cursorstate = 0

		'show a auction-tooltip (but not if we dragged a block)
		if not hoveredGuiProgrammeCoverBlock
			If functions.IsIn(MouseManager.x, MouseManager.y, 210,220,140,60)
				If not AuctionToolTip Then AuctionToolTip = TTooltip.Create("Auktion", "Film- und Serienauktion", 200, 180, 0, 0)
				AuctionToolTip.enabled = 1
				AuctionToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0
					room.screenManager.GoToSubScreen("screen_movieauction")
				endif
			EndIf
		endif

		If twinkerTimer.isExpired() then twinkerTimer.Reset()


		'create missing gui elements for all programme-lists
		local lists:TProgramme[][]				= [	listMoviesGood,listMoviesCheap,listSeries ]
		local guiLists:TGUIProgrammeSlotList[]	= [	guiListMoviesGood, guiListMoviesCheap, guiListSeries ]
		For local j:int = 0 to lists.length-1
			For local programme:TProgramme = eachin lists[j]
				if not programme then continue
				if guiLists[j].ContainsProgramme(programme) then continue
				guiLists[j].addItem( new TGuiProgrammeCoverBlock.CreateWithProgramme(programme),"-1" )
			Next
		Next
		'create missing gui elements for the current suitcase
		For local programme:TProgramme = eachin Game.getPlayer().ProgrammeCollection.SuitcaseProgrammeList
			if guiListSuitcase.ContainsProgramme(programme) then continue
			guiListSuitcase.addItem( new TGuiProgrammeCoverBlock.CreateWithProgramme(programme),"-1" )
		Next

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiProgrammeCoverBlock = null
		'reset dragged block too
		draggedGuiProgrammeCoverBlock = null
		GUIManager.Update("movieagency")

		If AuctionToolTip Then AuctionToolTip.Update( App.timer.getDeltaTime() )
	End Function



	'===================================
	'Movie Agency: Room screen
	'===================================

	Function onDrawMovieAuction:int( triggerEvent:TEventBase )
		Assets.GetSprite("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		SetAlpha 0.5
		Assets.GetFont("Default",12, BOLDFONT).drawBlock("Filme",		642,  27+3, 108,20, 1, 50,50,50,0,1)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock("Ramschkiste",	642, 125+3, 108,20, 1, 50,50,50,0,1)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock("Serien", 		642, 223+3, 108,20, 1, 50,50,50,0,1)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")
		SetAlpha 0.5;SetColor 0,0,0
		DrawRect(20,10,760,373)
		SetAlpha 1.0;SetColor 255,255,255
		DrawGFXRect(Assets.GetSpritePack("gfx_gui_rect"), 120, 60, 555, 290)
		SetAlpha 0.5
		Assets.GetFont("Default",12,BOLDFONT).drawBlock(Localization.GetString("CLICK_ON_MOVIE_OR_SERIES_TO_PLACE_BID"), 140,317, 535,30, 1, 230,230,230, false, 2, 1, 0.25)
		SetAlpha 1.0

		TAuctionProgrammeBlocks.DrawAll(0)
	End Function

	Function onUpdateMovieAuction:int( triggerEvent:TEventBase )
		Game.cursorstate = 0
		TAuctionProgrammeBlocks.UpdateAll(0)
	End Function
End Type


'News room
Type RoomHandler_News extends TRoomHandler
	global PlannerToolTip:TTooltip
	Global NewsGenreButtons:TGUIImageButton[5]
	Global NewsGenreTooltip:TTooltip			'the tooltip if hovering over the genre buttons
	Global currentRoom:TRooms					'holding the currently updated room (so genre buttons can access it)

	'lists for visually placing news blocks
	Global NewsBlockListAvailable:TGUIListBase[5]
	Global NewsBlockListUsed:TGUISlotList[5]

	Function Init()
		'create genre buttons
		NewsGenreButtons[0]		= new TGUIImageButton.Create(20, 194, "gfx_news_btn0", "newsroom", 0).SetCaption( GetLocale("NEWS_TECHNICS_MEDIA") )
		NewsGenreButtons[1]		= new TGUIImageButton.Create(69, 194, "gfx_news_btn1", "newsroom", 1).SetCaption( GetLocale("NEWS_POLITICS_ECONOMY") )
		NewsGenreButtons[2]		= new TGUIImageButton.Create(20, 247, "gfx_news_btn2", "newsroom", 2).SetCaption( GetLocale("NEWS_SHOWBIZ") )
		NewsGenreButtons[3]		= new TGUIImageButton.Create(69, 247, "gfx_news_btn3", "newsroom", 3).SetCaption( GetLocale("NEWS_SPORT") )
		NewsGenreButtons[4]		= new TGUIImageButton.Create(118, 247, "gfx_news_btn4", "newsroom", 4).SetCaption( GetLocale("NEWS_CURRENTAFFAIRS") )
		'disable drawing of caption
		for local i:int = 0 until len ( NewsGenreButtons ); NewsGenreButtons[i].GetCaption().Disable(); Next

		'we are interested in the genre buttons
		for local i:int = 0 until len( NewsGenreButtons )
			EventManager.registerListenerFunction( "guiobject.onMouseOver", onHoverNewsGenreButtons, NewsGenreButtons[i] )
			EventManager.registerListenerFunction( "guiobject.onDraw", onDrawNewsGenreButtons, NewsGenreButtons[i] )
			EventManager.registerListenerFunction( "guiobject.onClick", onClickNewsGenreButtons, NewsGenreButtons[i] )
		Next

		'create the lists in the news planner
		for local i:int = 1 to 4
			NewsBlockListAvailable[i] = new TGUIListBase.Create(34,20,Assets.getSprite("gfx_news_sheet0").w, 356,"Newsplanner"+i)
			NewsBlockListAvailable[i].SetAcceptDrop("TGUINewsBlock")
			NewsBlockListAvailable[i].Resize(NewsBlockListAvailable[i].rect.GetW() + NewsBlockListAvailable[i].guiScroller.rect.GetW() + 3,NewsBlockListAvailable[i].rect.GetH())
			NewsBlockListAvailable[i].guiEntriesPanel.minSize.SetXY(Assets.getSprite("gfx_news_sheet0").w,356)


			NewsBlockListUsed[i] = new TGUISlotList.Create(444,105,Assets.getSprite("gfx_news_sheet0").w, 3*Assets.getSprite("gfx_news_sheet0").h,"Newsplanner"+i)
			NewsBlockListUsed[i].SetItemLimit(3)
			NewsBlockListUsed[i].SetAcceptDrop("TGUINewsBlock")
			NewsBlockListUsed[i].SetSlotMinDimension(0,Assets.getSprite("gfx_news_sheet0").h)
			NewsBlockListUsed[i].SetAutofillSlots(false)
			NewsBlockListUsed[i].guiEntriesPanel.minSize.SetXY(Assets.getSprite("gfx_news_sheet0").w,3*Assets.getSprite("gfx_news_sheet0").h)

		Next
		'if the player visually manages the blocks, we need to handle the events
		'so we can inform the programmeplan about changes...
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropNewsBlock, "TGUINewsBlock" )
		'this lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction( "guiobject.onClick", onClickNewsBlock, "TGUINewsBlock")
		'also we want to interrupt leaving a room with dragged items
		EventManager.registerListenerFunction( "screens.OnLeave", onLeaveScreen )



		super._RegisterScreenHandler( onUpdateNews, onDrawNews, TScreen.GetScreen("screen_news") )
		super._RegisterScreenHandler( onUpdateNewsPlanner, onDrawNewsPlanner, TScreen.GetScreen("screen_news_newsplanning") )
	End Function


	'===================================
	'News: room screen
	'===================================

	Function onDrawNews:int( triggerEvent:TEventBase )
		GUIManager.Draw("newsroom")
		If PlannerToolTip Then PlannerToolTip.Draw()
		If NewsGenreTooltip then NewsGenreTooltip.Draw()

	End Function

	Function onUpdateNews:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		'store current room for later access (in guiobjects)
		currentRoom = room

		GUIManager.Update("newsroom")

		Game.cursorstate = 0
		If PlannerToolTip Then PlannerToolTip.Update(App.Timer.getDeltaTime())
		If NewsGenreTooltip Then NewsGenreTooltip.Update(App.Timer.getDeltaTime())

		If functions.IsIn(MouseManager.x, MouseManager.y, 167,60,240,160)
			If not PlannerToolTip Then PlannerToolTip = TTooltip.Create("Newsplaner", "Hinzufügen und entfernen", 180, 100, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				room.screenManager.GoToSubScreen("screen_news_newsplanning")
			endif
		endif
	End Function

	'could handle the buttons in one function ( by comparing triggerEvent._trigger )
	'onHover: handle tooltip
	Function onHoverNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIImageButton= TGUIImageButton(triggerEvent._sender)
		local room:TRooms			= currentRoom
		if not button then return 0
		if not room then return 0


		'how much levels do we have?
		local level:int = 0
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i] then level = Game.Players[ room.owner ].GetNewsAbonnement(i);exit
		Next

		if not NewsGenreTooltip then NewsGenreTooltip = TTooltip.Create("genre", "abonnement", 180,100 )
		NewsGenreTooltip.enabled = 1
		'refresh lifetime
		NewsGenreTooltip.Hover()
		'RON: test for sjaele
'		NewsGenreTooltip.dirtyImage = True

		'move the tooltip
		NewsGenreTooltip.pos.SetXY(Max(21,button.rect.GetX()), button.rect.GetY()-30)

		If level = 0
			NewsGenreTooltip.title	= button.GetCaptionText()+" - "+getLocale("NEWSSTUDIO_NOT_SUBSCRIBED")
			NewsGenreTooltip.text	= getLocale("NEWSSTUDIO_SUBSCRIBE_GENRE_LEVEL")+" 1: "+ Game.Players[ Game.playerID ].GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
		Else
			NewsGenreTooltip.title	= button.GetCaptionText()+" - "+getLocale("NEWSSTUDIO_SUBSCRIPTION_LEVEL")+" "+level
			if level = 3
				NewsGenreTooltip.text = getLocale("NEWSSTUDIO_DONT_SUBSCRIBE_GENRE_ANY_LONGER")+ "0" + getLocale("CURRENCY")
			Else
				NewsGenreTooltip.text = getLocale("NEWSSTUDIO_NEXT_SUBSCRIPTION_LEVEL")+": "+ Game.Players[ Game.playerID ].GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
			EndIf
		EndIf
	End Function

	Function onClickNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIImageButton= TGUIImageButton(triggerEvent._sender)
		local room:TRooms			= currentRoom
		if not button then return 0
		if not room then return 0

		'wrong room? go away!
		if room.owner <> Game.playerID then return 0

		'increase the abonnement
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i] then Game.Players[ Game.playerID ].IncreaseNewsAbonnement(i);exit
		Next
	End Function

	Function onDrawNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIImageButton= TGUIImageButton(triggerEvent._sender)
		local room:TRooms			= currentRoom
		if not button then return 0
		if not room then return 0

		'how much levels do we have?
		local level:int = 0
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i] then level = Game.Players[ room.owner ].GetNewsAbonnement(i);exit
		Next

		'draw the levels
		SetColor 0,0,0
		SetAlpha 0.4
		For Local i:Int = 0 to level-1
			DrawRect( button.rect.GetX()+8+i*10, button.rect.GetY()+ Assets.getSprite(button.spriteBaseName).h -7, 7,4)
		Next
		SetColor 255,255,255
		SetAlpha 1.0
	End Function



	'===================================
	'News: NewsPlanner screen
	'===================================

	Function onDrawNewsPlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		SetColor 255,255,255  'normal
		GUIManager.Draw("Newsplanner")
		'player specific newsplanner elements
		GUIManager.Draw("Newsplanner"+ room.owner )
	End Function

	Function onUpdateNewsPlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.cursorstate = 0
'		If TNewsBlock.AdditionallyDragged > 0 Then Game.cursorstate=2

		'create Newsblock-guiBlocks if not done yet
		For Local block:TNewsBlock = EachIn Game.Players[ room.owner ].ProgrammePlan.NewsBlocks
			if not block.guiBlock
				block.guiBlock = new TGUINewsBlock.Create(block.news.title)
				block.guiBlock.SetNewsBlock(block)
				if block.slot >= 0
					NewsBlockListUsed[ room.owner ].AddItem(block.guiBlock, string(block.slot))
				else
					NewsBlockListAvailable[ room.owner ].AddItem(block.guiBlock)
				endif
			endif
			'check if game logic changed slots - if so, update positions
			'used-list has a special order, so we have to sync slot-numbers
			if block.slot >= 0
				'move to the other list if not done yet
				if block.guiBlock.getParent("TGUIListBase") = NewsBlockListAvailable[ room.owner ]
					if NewsBlockListAvailable[ room.owner ].RemoveItem(block.guiBlock)
						NewsBlockListUsed[ room.owner].AddItem(block.guiBlock, string(block.slot) )
					endif
				'if it is already on the correct side ... just set the correct slot values
				elseif block.guiBlock.getParent("TGUISlotList") = NewsBlockListUsed[ room.owner ]
					NewsBlockListUsed[ room.owner ].SetItemToSlot(block.guiBlock, block.slot)
				endif
			endif

			if block.slot < 0 AND block.guiBlock.getParent("TGUISlotList") = NewsBlockListUsed[ room.owner ]
				if NewsBlockListUsed[ room.owner].RemoveItem(block.guiBlock)
					NewsBlockListAvailable[ room.owner ].AddItem(block.guiBlock)
					print "moved to left"
				else
					print "not able to remove from usedList"
				endif
			endif
		Next

		'general newsplanner elements
		GUIManager.Update("Newsplanner")
		'player specific newsplanner elements
		GUIManager.Update("Newsplanner"+ room.owner )
	End Function

	'in case of right mouse button click we want to remove the
	'block from the player's programmePlan
	Function onClickNewsBlock:int( triggerEvent:TEventBase )
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiBlock:TGUINewsBlock= TGUINewsBlock(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiBlock or not guiBlock.isDragged() then return FALSE

		'delete the newsblock of that guinewsblock from the owners programmeplan
		' - this also removes the guiblock
		Game.Players[ guiBlock.newsBlock.owner ].ProgrammePlan.RemoveNewsBlock( guiBlock.newsBlock )
	End Function

	Function onDropNewsBlock:int( triggerEvent:TEventBase )
		local guiNewsBlock:TGUINewsBlock = TGUINewsBlock( triggerEvent._sender )
		local receiverList:TGUIListBase = TGUIListBase( triggerEvent._receiver )
		if not guiNewsBlock or not receiverList then return FALSE

		local owner:int = guiNewsBlock.newsBlock.owner

		if receiverList = NewsBlockListAvailable[owner]
			Game.Players[ owner ].ProgrammePlan.SetNewsBlockSlot(guiNewsBlock.newsBlock, -1)
		elseif receiverList = NewsBlockListUsed[owner]
			local slot:int = NewsBlockListUsed[owner].getSlot(guiNewsBlock)
			Game.Players[ owner ].ProgrammePlan.SetNewsBlockSlot(guiNewsBlock.newsBlock, slot)
		endif
	End Function

	Function onLeaveScreen:int( triggerEvent:TEventBase )
		local screen:TScreen = TScreen( triggerEvent._sender )
		if screen.name <> "screen_news_newsplanning" return TRUE

		'if there are some draggedObjects then do not leave
		if GUIManager.draggedObjects > 0
			triggerEvent.setVeto()
			return FALSE
		else
			return TRUE
		endif
	End Function
End Type



'Chief: credit and emmys - your boss :D
Type RoomHandler_Chief extends TRoomHandler
	'smoke effect
	Global part_array:TGW_SpritesParticle[100]
	Global spawn_delay:Int = 15
	Global Dialogues:TList = CreateList()

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
		For Local dialog:TDialogue = EachIn Dialogues
			dialog.Draw()
		Next
	End Function

	Function Update:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Game.Players[game.playerID].figure.fromroom = Null

		If Dialogues.Count() <= 0
			Local ChefDialoge:TDialogueTexts[5]
			ChefDialoge[0] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_WELCOME").replace("%1", Game.Players[Game.playerID].name) )
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_WILLNOTDISTURB"), - 2, Null))
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_ASKFORCREDIT"), 1, Null))

			If Game.Players[Game.playerID].GetCreditCurrent() > 0
				ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_REPAYCREDIT"), 3, Null))
			endif
			If Game.Players[Game.playerID].GetCreditAvailable() > 0
				ChefDialoge[1] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_OK").replace("%1", Game.Players[Game.playerID].GetCreditAvailable()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_OK_ACCEPT"), 2, TPlayer.extSetCredit, Game.Players[Game.playerID].GetCreditAvailable()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			Else
				ChefDialoge[1] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY").replace("%1", Game.Players[Game.playerID].GetCreditCurrent()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_ACCEPT"), 3))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			EndIf
			ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))

			ChefDialoge[2] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_BACKTOWORK").replace("%1", Game.Players[Game.playerID].name) )
			ChefDialoge[2].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_BACKTOWORK_OK"), - 2))

			ChefDialoge[3] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_BOSSRESPONSE") )
			If Game.Players[Game.playerID].GetCreditCurrent() >= 100000 And Game.Players[Game.playerID].GetMoney() >= 100000
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_100K"), - 2, TPlayer.extSetCredit, - 1 * 100000))
			EndIf
			If Game.Players[Game.playerID].GetCreditCurrent() < Game.Players[Game.playerID].GetMoney()
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_ALL").replace("%1", Game.Players[Game.playerID].GetCreditCurrent()), - 2, TPlayer.extSetCredit, - 1 * Game.Players[Game.playerID].GetCreditCurrent()))
			EndIf
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))
			Local ChefDialog:TDialogue = TDialogue.Create(350, 60, 450, 200)
			ChefDialog.AddText(Chefdialoge[0])
			ChefDialog.AddText(Chefdialoge[1])
			ChefDialog.AddText(Chefdialoge[2])
			ChefDialog.AddText(Chefdialoge[3])
			Dialogues.AddLast(ChefDialog)
		EndIf

		'cigar particles
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

		For Local dialog:TDialogue = EachIn Dialogues
			If dialog.Update(MOUSEMANAGER.IsHit(1)) = 0
				room.Leave()
				Dialogues.Remove(dialog)
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




'Movie agency
Type RoomHandler_AdAgency extends TRoomHandler
	Global hoveredGuiContractCoverBlock:TGuiContractCoverBlock = null
	Global draggedGuiContractCoverBlock:TGuiContractCoverBlock = null

	Global VendorArea:TGUISimpleRect	'allows registration of drop-event

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Global listNormal:TContract[]
	Global listCheap:TContract[]

	'graphical lists for interaction with blocks
	Global GuiListNormal:TGUIContractSlotList[]
	Global GuiListCheap:TGUIContractSlotList = null
	Global GuiListSuitcase:TGUIContractSlotList = null

	'configuration
	Global suitcasePos:TPoint					= TPoint.Create(520,100)
	Global suitcaseGuiListDisplace:TPoint		= TPoint.Create(17,32)
	Global contractsPerLine:int					= 4
	Global contractsNormalAmount:int			= 12
	Global contractsCheapAmount:int				= 4
	Global contractCheapAudienceMaximum:float	= 0.05 '5% market share


	Function Init()
		'resize arrays
		listNormal		= listNormal[..contractsNormalAmount]
		listCheap		= listCheap[..contractsCheapAmount]

		GuiListNormal	= GuiListNormal[..3]
		for local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i] = new TGUIContractSlotList.Create(430-i*70,170+i*32, 200,140, "adagency")
			GuiListNormal[i].SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListNormal[i].SetItemLimit( contractsNormalAmount / GuiListNormal.length  )
			GuiListNormal[i].Resize(Assets.GetSprite("gfx_contracts_0").w * (contractsNormalAmount / GuiListNormal.length), Assets.GetSprite("gfx_contracts_0").h )
			GuiListNormal[i].SetSlotMinDimension(Assets.GetSprite("gfx_contracts_0").w, Assets.GetSprite("gfx_contracts_0").h)
			GuiListNormal[i].SetAcceptDrop("TGUIContractCoverBlock")
			GuiListNormal[i].setZindex(i)
		Next

		GuiListSuitcase	= new TGUIContractSlotList.Create(suitcasePos.GetX()+suitcaseGuiListDisplace.GetX(),suitcasePos.GetY()+suitcaseGuiListDisplace.GetY(),200,80, "adagency")

		GuiListCheap	= new TGUIContractSlotList.Create(70,200,80,80, "adagency")
		GuiListCheap.setEntriesBlockDisplacement(70,0)

		GuiListCheap.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

		GuiListCheap.SetItemLimit( listCheap.length )
		GuiListSuitcase.SetItemLimit( Game.maxContractsAllowed )

		GuiListCheap.SetSlotMinDimension(Assets.GetSprite("gfx_contracts_0").w, Assets.GetSprite("gfx_contracts_0").h)
		GuiListSuitcase.SetSlotMinDimension(Assets.GetSprite("gfx_contracts_0").w, Assets.GetSprite("gfx_contracts_0").h)

		GuiListCheap.SetEntryDisplacement( -2*GuiListNormal[0]._slotMinDimension.x, 6)
		GuiListSuitcase.SetEntryDisplacement( -1, 0)

		GuiListCheap.SetAcceptDrop("TGUIContractCoverBlock")
		GuiListSuitcase.SetAcceptDrop("TGUIContractCoverBlock")

		VendorArea = new TGUISimpleRect.Create(TRectangle.Create(286,110, Assets.GetSprite("gfx_hint_rooms_adagency").w, Assets.GetSprite("gfx_hint_rooms_adagency").h), "adagency" )
		'vendor should accept drop - else no recognition
		VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)

		'to react on changes in the programmeCollection (eg. contract finished)
		EventManager.registerListenerFunction( "programmecollection.addContract", onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.removeContract", onChangeProgrammeCollection )


		'to change the asset - we intercept in dragging events
		EventManager.registerListenerFunction( "guiobject.onDrag", onDragContract, "TGUIContractCoverBlock" )
		'begin drop - to intercept if dropping to wrong list
		EventManager.registerListenerFunction( "guiobject.onTryDropOnTarget", onTryDropContract, "TGUIContractCoverBlock" )
		'drop ... to vendor or suitcase
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropContract, "TGUIContractCoverBlock" )
		'drop on vendor - sell things
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropContractOnVendor, "TGUIContractCoverBlock" )
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "TGUIBaseCoverBlock.OnMouseOver", onMouseOverContract, "TGUIContractCoverBlock" )
		'figure enters room - reset the suitcase's guilist, limit listening to this room
		EventManager.registerListenerFunction( "room.onEnter", onEnterRoom, TRooms.GetRoomByDetails("adagency",0) )
		'figure leaves room - only without dragged blocks
		EventManager.registerListenerFunction( "room.onTryLeave", onTryLeaveRoom, TRooms.GetRoomByDetails("adagency",0) )
		EventManager.registerListenerFunction( "room.onLeave", onLeaveRoom, TRooms.GetRoomByDetails("adagency",0) )

		super._RegisterScreenHandler( onUpdateAdAgency, onDrawAdAgency, TScreen.GetScreen("screen_adagency") )
	End Function


	'clear the guilist for the suitcase if a player enters
	Function onEnterRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent.GetSender())
		local figure:TFigures = TFigures(triggerEvent.GetData().Get("figure"))
		if not room or not figure then return FALSE

		'we are not interested in other figures than our player's
		if not figure.IsActivePlayer() then return FALSE

		'empty guilists / delete gui elements
		'- the real list still may contain elements with gui-references
		'- this avoids zombies when watching players..
		hoveredGuiContractCoverBlock = null
		draggedGuiContractCoverBlock = null

		'reorders the contracts of the agency (not the suitcase)
		'and also empties the corresponding gui list
		ResetContractOrder()

		GuiListSuitcase.EmptyList()

		'fill all open slots in the agency - eg when entering the first time
		ReFillBlocks()
	End Function


	Function onTryLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigures = TFigures(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayer then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiContractCoverBlock
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function


	'add back the programmes from the suitcase
	'also fill empty blocks, remove gui elements
	Function onLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigures = TFigures(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayer then return FALSE

		'sign all new contracts
		For Local contract:TContract = EachIn figure.parentPlayer.ProgrammeCollection.suitcaseContractList
			'adds a contract to the players collection (gets signed THERE)
			figure.ParentPlayer.ProgrammeCollection.AddContract(contract)
		Next

		'fill all open slots in the agency
		ReFillBlocks()

		return TRUE
	End Function


	'===================================
	'AD Agency: common functions
	'===================================

	Function GetContractsInStock:int()
		Local ret:Int = 0
		local lists:TContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TContract = EachIn lists[j]
				if contract Then ret:+1
			Next
		Next
		return ret
	End Function


	Function GetContractByPosition:TContract(position:int)
		if position > GetContractsInStock() then return null
		local currentPosition:int = 0
		local lists:TContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TContract = EachIn lists[j]
				if contract
					if currentPosition = position then return contract
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Function


	Function HasContract:int(contract:TContract)
		local lists:TContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local cont:TContract = EachIn lists[j]
				if cont = contract then return TRUE
			Next
		Next
		return FALSE
	End Function


	Function GetContractByID:TContract(contractID:int)
		local lists:TContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TContract = EachIn lists[j]
				if contract and contract.id = contractID then return contract
			Next
		Next
		return null
	End Function

	Function GiveContractToPlayer:int(contract:TContract, playerID:int, sign:int=FALSE)
		if contract.owner = playerID then return FALSE

		if not Game.isPlayer(playerID) then return FALSE

		'try to add to suitcase of player
		if not sign
			if not Game.Players[ playerID ].ProgrammeCollection.AddUnsignedContractToSuitcase(contract) then return FALSE
		'we do not need the suitcase, direkt sign pls (eg. for AI)
		else
			if not Game.Players[ playerID ].ProgrammeCollection.AddContract(contract) then return FALSE
		endif

		'remove from agency's lists
		RemoveContract(contract)

		return TRUE
	End Function


	Function TakeContractFromPlayer:int(contract:TContract, playerID:int)
		if Game.Players[ playerID ].ProgrammeCollection.RemoveUnsignedContractFromSuitcase(contract)
			'add to agency's lists - if not existing yet
			if not HasContract(contract) then AddContract(contract)

			return TRUE
		else
			return FALSE
		endif
	End Function

	Function isCheapContract:int(contract:TContract)
		return contract.GetMinAudiencePercentage() < contractCheapAudienceMaximum
	End Function

	Function ResetContractOrder:int()
		local contracts:TList = CreateList()
		for local contract:TContract = eachin listNormal
			contracts.addLast(contract)
		Next
		for local contract:TContract = eachin listCheap
			contracts.addLast(contract)
		Next
		listNormal = new TContract[listNormal.length]
		listCheap = new TContract[listCheap.length]

		contracts.sort()

		'add again - so it gets sorted
		for local contract:TContract = eachin contracts
			AddContract(contract)
		Next

		'empty gui list - so it gets rebuild during update
		for local i:int = 0 to GuiListNormal.length-1
			if GuiListNormal[i] then GuiListNormal[i].EmptyList()
		Next

		if GuiListCheap then GuiListCheap.EmptyList()
	End Function

	Function RemoveContract:int(contract:TContract)
		local foundContract:int = FALSE
		'remove from agency's lists
		local lists:TContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = contract then lists[j][i] = null;foundContract=TRUE
			Next
		Next

		return foundContract
	End Function


	Function AddContract:int(contract:TContract)
		'try to fill the program into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TContract[][]

		if isCheapContract(contract)
			lists = [listCheap,listNormal]
		else
			lists = [listNormal,listCheap]
		endif

		'loop through all lists - as soon as we find a spot
		'to place the programme - do so and return
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if lists[j][i] then continue
				contract.owner = -1
				lists[j][i] = contract
				return TRUE
			Next
		Next

		'there was no empty slot to place that programme
		'so just give it back to the pool
		contract.owner = 0

		return FALSE
	End Function



	'refills slots in the movie agency
	Function ReFillBlocks:Int()
		local lists:TContract[][] = [listNormal,listCheap]
		local contract:TContract = null

		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				'if exists...skip it
				if lists[j][i] then continue

				if lists[j] = listNormal then contract = TContract.Create( TContractBase.GetRandom() )
				if lists[j] = listCheap then contract = TContract.Create( TContractBase.GetRandomWithLimitedAudienceQuote(0.0, contractCheapAudienceMaximum) )

				'add new contract to slot
				if contract
					contract.owner = -1
					lists[j][i] = contract
				else
					print "ERROR: Not enough contracts to fill ad agency in list "+i
				endif
			Next
		Next
	End Function


	Function CheckPlayerInRoom:int()
		'check if we are in the correct room
		if not Game.getPlayer().figure.inRoom then return FALSE
		if Game.getPlayer().figure.inRoom.name <> "adagency" then return FALSE

		return TRUE
	End Function



	'===================================
	'Ad Agency: Room screen
	'===================================


	'if players are in the agency during changes
	'to their programme collection, react to...
	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local figure:TFigures = TFigures( triggerEvent.getData().get("figure") )
		if not figure and not figure.isActivePlayer() then return FALSE

		'empty the suitcase for rebuilding in update call
		GuiListSuitcase.EmptyList()
	End Function


	Function onMouseOverContract:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local item:TGUIContractCoverBlock = TGUIContractCoverBlock(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiContractCoverBlock = item
		if item.isDragged() then draggedGuiContractCoverBlock = item

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropContractOnVendor:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGUIContractCoverBlock = TGUIContractCoverBlock( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver or receiver <> VendorArea then return FALSE

		local parent:TGUIobject = guiBlock._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local senderList:TGUIContractSlotList = TGUIContractSlotList(parent)
		if not senderList then return FALSE

		'if coming from suitcase, try to remove it from the player
		if senderList = GuiListSuitcase
			if not TakeContractFromPlayer(guiBlock.contract, Game.getPlayer().playerID )
				triggerEvent.setVeto()
				return FALSE
			endif
		else
			'remove and add again (so we drop automatically to the correct list)
			RemoveContract(guiBlock.contract)
			AddContract(guiBlock.contract)
		endif
		'reset gui element
		guiBlock.remove()
		guiBlock = null

		return TRUE
	End function


	'we intercept so we can change the used assed
	Function onDragContract:int( triggerEvent:TEventBase )
		local guiBlock:TGUIContractCoverBlock = TGUIContractCoverBlock( triggerEvent._sender )
		'set to dragged
		guiBlock.InitAsset( guiBlock.getAssetName(-1, TRUE ) )
	End Function


	'we intercept that event so we can avoid dropping from one
	'vendor list to another
	Function onTryDropContract:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGUIContractCoverBlock = TGUIContractCoverBlock( triggerEvent._sender )
		local receiverList:TGUIContractSlotList = TGUIContractSlotList( triggerEvent._receiver )
		if not guiBlock or not receiverList then return FALSE

		local parent:TGUIobject = guiBlock._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local senderList:TGUIContractSlotList = TGUIContractSlotList(parent)
		if not senderList then return FALSE

		'just dropping back to origin - no problem
		if senderList = receiverList then return TRUE

		'do not allow changes between vendor lists ?
		'->sender or receiver must be suitcase
		if senderList <> GuiListSuitcase and receiverList <> GuiListSuitcase
			triggerEvent.setVeto()
			return FALSE
		endif

		return TRUE
	End Function


	'in this stage, the item is already added to the new gui list
	'we now just add or remove it to the player or vendor's list
	Function onDropContract:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGUIContractCoverBlock = TGUIContractCoverBlock( triggerEvent._sender )
		local receiverList:TGUIContractSlotList = TGUIContractSlotList( triggerEvent._receiver )
		if not guiBlock or not receiverList then return FALSE

		'get current owner of the contract, as the field "owner" is set
		'during sign we cannot rely on it. So we check if the player has
		'the contract in the suitcaseContractList
		local owner:int = guiBlock.contract.owner
		if owner <= 0 and Game.getPlayer().ProgrammeCollection.HasUnsignedContractInSuitcase(guiBlock.contract)
			owner = Game.playerID
		endif

		local toVendor:int = FALSE
		for local i:int = 0 to GuiListNormal.length
			if receiverList = GuiListNormal[i] then toVendor = true;exit
		Next
		if receiverList = GuiListcheap then toVendor = true

		if toVendor
			guiBlock.InitAsset( guiBlock.getAssetName(-1, FALSE ) )

			'no problem when dropping vendor programme to vendor..
			if owner <= 0 then return TRUE
			if not TakeContractFromPlayer(guiBlock.contract, Game.getPlayer().playerID )
				triggerEvent.setVeto()
				return FALSE
			endif

			'in all cases - remove that contract and add again (so we drop automatically
			'to the correct list)
			guiBlock.remove()
			RemoveContract(guiBlock.contract)
			AddContract(guiBlock.contract)
		else
			guiBlock.InitAsset( guiBlock.getAssetName(-1, TRUE ) )

			'no problem when dropping own programme to suitcase..
			if owner = Game.playerID then return TRUE
			if not GiveContractToPlayer(guiBlock.contract, Game.playerID)
				triggerEvent.setVeto()
				return FALSE
			endif
		EndIf

		return TRUE
	End Function



	Function onDrawAdAgency:int( triggerEvent:TEventBase )
		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		if draggedGuiContractCoverBlock
			if not Game.getPlayer().ProgrammeCollection.HasUnsignedContractInSuitcase(draggedGuiContractCoverBlock.contract)
				glowSuitcase = "_glow"
			endif
			Assets.GetSprite("gfx_hint_rooms_adagency").Draw(VendorArea.getScreenX(), VendorArea.getScreenY())
		endif

		'draw suitcase
		Assets.GetSprite("gfx_suitcase_big"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		GUIManager.Draw("adagency")

		if hoveredGuiContractCoverBlock
			'draw the current sheet
			hoveredGuiContractCoverBlock.DrawSheet()
		endif

	End Function

	Function onUpdateAdAgency:int( triggerEvent:TEventBase )
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.cursorstate = 0

		'create missing gui elements for all contract-lists
		'normal list
		For local contract:TContract = eachin listNormal
			if not contract then continue
			local contractAdded:int = FALSE
			local contractFound:int = FALSE
			'check if in one of the gui lists
			For local i:int = 0 to GuiListNormal.length-1
				if contractFound then continue
				if GuiListNormal[i].ContainsContract(contract)
					contractFound = true
				endif
			Next
			if not contractFound
				'try to fill in one of them
				For local i:int = 0 to GuiListNormal.length-1
					if contractAdded then continue
					if GuiListNormal[i].getFreeSlot() < 0 then continue
					local block:TGuiContractCoverBlock = new TGuiContractCoverBlock.CreateWithContract(contract)
					'change look
					block.InitAsset( block.getAssetName(-1, FALSE) )
					GuiListNormal[i].addItem( block ,"-1" )
					contractAdded = true
				Next
				if not contractAdded
					print "[ERORR] AdAgency: contract exists but does not fit in GuiListNormal - contract removed."
					RemoveContract(contract)
				endif
			endif
		Next

		'cheap list
		For local contract:TContract = eachin listCheap
			if not contract then continue
			if GuiListCheap.ContainsContract(contract) then continue
			local block:TGuiContractCoverBlock = new TGuiContractCoverBlock.CreateWithContract(contract)
			'change look
			block.InitAsset( block.getAssetName(-1, FALSE) )
			GuiListCheap.addItem( block ,"-1" )
		Next

		'create missing gui elements for the players contracts
		For local contract:TContract = eachin Game.getPlayer().ProgrammeCollection.ContractList
			if guiListSuitcase.ContainsContract(contract) then continue
			local block:TGuiContractCoverBlock = new TGuiContractCoverBlock.CreateWithContract(contract)
			'change look
			block.InitAsset( block.getAssetName(-1, TRUE) )
			block.setOption(GUI_OBJECT_DRAGABLE, FALSE)
			guiListSuitcase.addItem( block,"-1" )
		Next

		'create missing gui elements for the current suitcase
		For local contract:TContract = eachin Game.getPlayer().ProgrammeCollection.SuitcaseContractList
			if guiListSuitcase.ContainsContract(contract) then continue
			local block:TGuiContractCoverBlock = new TGuiContractCoverBlock.CreateWithContract(contract)
			'change look
			block.InitAsset( block.getAssetName(-1, TRUE) )
			guiListSuitcase.addItem( block,"-1" )

		Next

		if MOUSEMANAGER.isClicked(2) and draggedGuiContractCoverBlock
			draggedGuiContractCoverBlock.remove() 'will automatically rebuild at correct spot
		endif

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiContractCoverBlock = null
		'reset dragged block too
		draggedGuiContractCoverBlock = null
		GUIManager.Update("adagency")
	End Function

End Type


'Dies hier ist die Raumauswahl im Fahrstuhl.
Type RoomHandler_ElevatorPlan extends TRoomHandler
	Function Init()
		super._RegisterHandler(onUpdate, onDraw, TRooms.getRoomByDetails("elevatorplan",0) )
	End Function

	Function onDraw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		local playerFigure:TFigures = Game.Players[ Game.playerID ].figure

		TRoomSigns.DrawAll()
	End Function

	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		local playerFigure:TFigures = Game.Players[ Game.playerID ].figure
		local mouseHit:int = MouseManager.IsHit(1)

		Game.cursorstate = 0

		'if possible, change the target to the clicked room
		if mouseHit
			local clickedRoom:TRooms = TRoomSigns.GetRoomFromXY(MouseManager.x,MouseManager.y)
			if clickedRoom then playerFigure.ChangeTarget(clickedroom.Pos.x, Building.pos.y + Building.GetFloorY(clickedroom.Pos.y))
		endif

		TRoomSigns.UpdateAll(False)
		if mouseHit then MouseManager.ResetKey(1)
	End Function
End Type

Type RoomHandler_Roomboard extends TRoomHandler
	Function Init()
		super._RegisterHandler(onUpdate, onDraw, TRooms.GetRoomByDetails("roomboard", -1))
	End Function

	Function onDraw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		TRoomSigns.DrawAll()
		Assets.fonts.baseFont.draw("owner:"+ room.owner, 20,20)
		Assets.fonts.baseFont.draw(building.Elevator.waitAtFloorTimer.GetTimeUntilExpire(), 20,40)
	End Function

	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		Game.cursorstate = 0
		TRoomSigns.UpdateAll(True)
		If MouseManager.IsDown(1) Then MouseManager.resetKey(1)
	End Function
End Type

'Betty
Type RoomHandler_Betty extends TRoomHandler
	Function Init()
		super._RegisterHandler(onUpdate, onDraw, TRooms.GetRoomByDetails("betty",0))
	End Function

	Function onDraw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		For Local i:Int = 1 To 4
			local sprite:TGW_Sprites = Assets.GetSprite("gfx_room_betty_picture1")
			Local picY:Int = 240
			Local picX:Int = 410 + i * (sprite.w + 5)
			sprite.Draw( picX, picY )
			SetAlpha 0.4
			Game.Players[i].color.SetRGB()
			DrawRect(picX + 2, picY + 8, 26, 28)
			SetColor 255, 255, 255
			SetAlpha 1.0
			local x:float = picX + Int(sprite.framew / 2) - Int(Game.Players[i].Figure.Sprite.framew / 2)
			local y:float = picY + sprite.h - 30
			Game.Players[i].Figure.Sprite.DrawClipped(x, y, x, y, sprite.w, sprite.h-16,0,0,8)
		Next

		Local DlgText:String = "Na Du?" + Chr(13) + "Du könntest ruhig mal öfters bei mir vorbeischauen."
		DrawDialog(Assets.GetSpritePack("gfx_dialog"), 430, 120, 280, 90, "StartLeftDown", 0, DlgText, Assets.GetFont("Default",14))
	End Function

	Function onUpdate:int( triggerEvent:TEventBase )
		'nothing yet
	End Function
End Type


'signs used in elevator-plan /room-plan
Type TRoomSigns Extends TBlockMoveable
	Field title:String				= ""
	Field image:TGW_Sprites			= null
	Field imageWithText:TGW_Sprites	= null
	Field image_dragged:TGW_Sprites	= null

	Global DragAndDropList:TList	= CreateList()
	Global List:TList				= CreateList()
	Global AdditionallyDragged:Int	= 0
	Global DebugMode:Byte			= 1

	const signSlot1:int	= 26
	const signSlot2:int	= 208
	const signSlot3:int	= 417
	const signSlot4:int	= 599


  Function Create:TRoomSigns(text:String="unknown", x:Int=0, y:Int=0, owner:Int=0)
	  Local LocObject:TRoomSigns=New TRoomSigns

 	  LocObject.dragable = 1
	  LocObject.owner = owner
	  If owner <0 Then owner = 0

 	  Locobject.image			= Assets.GetSprite("gfx_elevator_sign"+owner)
 	  Locobject.image_dragged	= Assets.GetSprite("gfx_elevator_sign_dragged"+owner)
	  LocObject.OrigPos			= TPoint.Create(x, y)
	  LocObject.StartPos		= TPoint.Create(x, y)
	  LocObject.rect 			= TRectangle.Create(x,y, LocObject.image.w, LocObject.image.h - 1)
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
			obj.rect.position.SetPos(obj.OrigPos)
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
    	If rect.GetX() = 589 then Return 12+(Int(Floor(StartPos.y - 17) / 30))
    	If rect.GetX() = 262 then Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	Return -1
    End Method

	'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		SetColor 255,255,255;dragable=1  'normal

		If dragged = 1
			If TRoomSigns.AdditionallyDragged > 0 Then SetAlpha 1- 1/TRoomSigns.AdditionallyDragged * 0.25
			if image_dragged <> null
				image_dragged.Draw(rect.GetX(),rect.GetY())
				If imagewithtext <> Null then imagewithtext.Draw(rect.GetX(),rect.GetY())
			endif
		Else
			If imagewithtext <> Null
				imagewithtext.Draw(rect.GetX(),rect.GetY())
			Elseif image
				local newimgwithtext:Timage = image.GetImageCopy()
				Local font:TBitmapFont = Assets.GetFont("Default",9, BOLDFONT)
				font.setTargetImage(newimgwithtext)
				if self.owner > 0
					font.drawBlock(title, 22, 3, 150,20, 0, 230, 230, 230, 0, 2, 1, 0.5)
				else
					font.drawBlock(title, 22, 3, 150,20, 0, 50, 50, 50, 0, 2, 1, 0.3)
				endif
				font.resetTarget()

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
						locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
						locObj.dragged = False
						MOUSEMANAGER.resetKey(2)
					EndIf

					'if left mbutton clicked: drop, replace with underlaying block...
					If MouseManager.IsHit(1)
						'search for underlaying block (we have a block dragged already)
						If locObj.dragged
							'obj over old position - drop ?
							If functions.IsIn(MouseManager.x,MouseManager.y,LocObj.StartPosBackup.x,locobj.StartPosBackup.y,locobj.rect.GetW(),locobj.rect.GetH())
								locObj.dragged = False
							EndIf

							'want to drop in origin-position
							If locObj.containsCoord(MouseManager.x, MouseManager.y)
								locObj.dragged = False
								MouseManager.resetKey(1)
								If Self.DebugMode=1 Then Print "roomboard: dropped to original position"
							'not dropping on origin: search for other underlaying obj
							Else
								For Local OtherLocObj:TRoomSigns = EachIn TRoomSigns.List
									If OtherLocObj <> Null
										If OtherLocObj.containsCoord(MouseManager.x, MouseManager.y) And OtherLocObj <> locObj And OtherLocObj.dragged = False And OtherLocObj.dragable
'											If game.networkgame Then
'												Network.SendMovieAgencyChange(Network.NET_SWITCH, Game.playerID, OtherlocObj.Programme.id, -1, locObj.Programme)
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
							If LocObj.containsCoord(MouseManager.x, MouseManager.y)
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
				locObj.setCoords(MouseManager.x - locObj.rect.GetW()/2 - displacement, 11+ MouseManager.y - locObj.rect.GetH()/2 - displacement)
			Else
				locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
			EndIf
		Next
		ReverseList TRoomSigns.list 'reorder: first are not dragged obj
	End Function

	Function DrawAll()
		SortList TRoomSigns.List
		'draw background sprites
		For Local sign:TRoomSigns = EachIn List
			Assets.GetSprite("gfx_elevator_sign_bg").Draw(sign.OrigPos.x + 20, sign.OrigPos.y + 6)
		Next
		'draw actual sign
		For Local sign:TRoomSigns = EachIn List
			sign.Draw()
		Next
	End Function

    Function GetRoomFromXY:TRooms(x:Int=-1, y:Int=-1)
		For Local sign:TRoomSigns = EachIn List
			'virtual rooms
			If sign.rect.GetX() < 0 then continue

			If sign.rect.containsXY(x,y)
				Local xpos:Int = 0
				If sign.rect.GetX() = signSlot1 Then xpos = 1
				If sign.rect.GetX() = signSlot2 Then xpos = 2
				If sign.rect.GetX() = signSlot3 Then xpos = 3
				If sign.rect.GetX() = signSlot4 Then xpos = 4
				Local clickedroom:TRooms = TRooms.GetRoomFromMapPos(xpos, 13 - Ceil((y-41)/23))
				if clickedroom then return clickedroom
			EndIf
		Next

		Print "GetRoomFromXY : no room found at "+x+","+y
		return null
    End Function

End Type


Function Init_CreateAllRooms()
	local room:TRooms = null
	Local roomMap:TMap = Assets.GetMap("rooms")
	For Local asset:TAsset = EachIn roomMap.Values()
		local vars:TMap = TMap(asset._object)
		room = TRooms.Create(..
					TScreenManager.Create(TScreen.GetScreen( String(vars.ValueForKey("screen")) )),  ..
					String(vars.ValueForKey("roomname")),  ..
					GetLocale(String(vars.ValueForKey("tooltip"))),  ..
					GetLocale(String(vars.ValueForKey("tooltip2"))),  ..
					Int(String(vars.ValueForKey("doorslot"))),  ..
					Int(String(vars.ValueForKey("x"))),  ..
					Int(String(vars.ValueForKey("floor"))),  ..
					Int(String(vars.ValueForKey("doortype"))),  ..
					Int(String(vars.ValueForKey("owner")))..
				)
		if Int(String(vars.ValueForKey("doorwidth"))) > 0 then room.doorDimension.setX( Int(String(vars.ValueForKey("doorwidth"))) )
		if Int(String(vars.ValueForKey("fake"))) > 0 then room.fakeRoom = TRUE

		'load hotspots
		local hotSpots:TList = TList( (vars.ValueForKey("hotspots") ) )
		if hotSpots
			for local hotSpotData:TMap = eachin hotSpots
				local name:string 	= String(hotSpotData.ValueForKey("name"))
				local x:int			= int(String(hotSpotData.ValueForKey("x")))
				local y:int			= int(String(hotSpotData.ValueForKey("y")))
				local bottomy:int	= int(String(hotSpotData.ValueForKey("bottomy")))
				local floor:int 	= int(String(hotSpotData.ValueForKey("floor")))
				local width:int 	= int(String(hotSpotData.ValueForKey("width")))
				local height:int 	= int(String(hotSpotData.ValueForKey("height")))
				local tooltipText:string	 	= String(hotSpotData.ValueForKey("tooltiptext"))
				local tooltipDescription:string	= String(hotSpotData.ValueForKey("tooltipdescription"))

				'align at bottom of floor
				if floor>=0 then y = TBuilding.GetFloorY(floor) - height

				local hotspot:THotspot = new THotspot.Create( name, x, y - bottomy, width, height)
				hotspot.setTooltipText( GetLocale(tooltipText), GetLocale(tooltipDescription) )
				room.addHotspot( hotspot )
			next
		endif

	Next

	'connect Update/Draw-Events
	RoomHandler_Office.Init()
	RoomHandler_News.Init()
	RoomHandler_Chief.Init()
	RoomHandler_Archive.Init()

	RoomHandler_AdAgency.Init()
	RoomHandler_MovieAgency.Init()

	RoomHandler_Betty.Init()

	RoomHandler_ElevatorPlan.Init()
	RoomHandler_Roomboard.Init()


End Function

Function Init_CreateRoomDetails()
	For Local i:Int = 1 To 4
		TRooms.GetRoomByDetails("studiosize1", i).desc:+" " + Game.Players[i].channelname
		TRooms.GetRoomByDetails("office", i).desc:+" " + Game.Players[i].name
		TRooms.GetRoomByDetails("chief", i).desc:+" " + Game.Players[i].channelname
		TRooms.GetRoomByDetails("news", i).desc:+" " + Game.Players[i].channelname
		TRooms.GetRoomByDetails("archive", i).desc:+" " + Game.Players[i].channelname
	Next

	For Local Room:TRooms = EachIn TRooms.RoomList
		Room.CreateRoomsign()
	Next
End Function