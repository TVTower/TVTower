'Basictype of all rooms
Type TRooms extends TGameObject  {_exposeToLua="selected"}
	Field name:String			= ""  					'name of the room, eg. "archive" for archive room
	Field desc:String			= ""					'description, eg. "Bettys bureau" (used for tooltip)
	Field descTwo:String		= ""					'description, eg. "name of the owner" (used for tooltip)
	Field tooltip:TTooltip		= null					'uses description
	Field background:TGW_Sprite							'the image used in the room (store individual backgrounds depending on "money")

	Field DoorTimer:TIntervalTimer	= TIntervalTimer.Create(1) 'time is set in basecreate depending on changeRoomSpeed..
	Field Pos:TPoint									'x of the rooms door in the building, y as floornumber
	Field doorSlot:Int			= -1					'door 1-4 on floor (<0 is invisible, -1 is unset)
	Field doortype:Int			=-1
	Field doorDimension:TPoint	= TPoint.Create(38,52)
	Field owner:Int				=-1						'to draw the logo/symbol of the owner
	Field occupants:TList		= CreateList()			'figure currently in this room
	Field allowMultipleOccupants:int = FALSE			'allow more than one
	Field _soundSource:TDoorSoundSource = Null {nosave}
	Field hotspots:TList		= CreateList()			'list of special areas in the room
	Field fakeRoom:int			= FALSE					'is this a room or just a "plan" or "view"

	Global ChangeRoomSpeed:int         = 500            'time the change of a room needs (1st half is opening, 2nd closing the door)
	Global _doorsDrawnToBackground:Int = 0   			'doors drawn to Pixmap of background
	Global rooms:TList                 = CreateList()   'global list of rooms
	Global _initDone:int		       = FALSE          'global events registered etc.

	const doorSlot0:int	= -10                           'x coord of defined slots
	const doorSlot1:int	= 206
	const doorSlot2:int	= 293
	const doorSlot3:int	= 469
	const doorSlot4:int	= 557


	'create room and use preloaded image
	'Raum erstellen und bereits geladenes Bild nutzen
	'x = 1-4
	'y = floor
	Function Create:TRooms(screen:TInGameScreen_Room, name:String="unknown", desc:String="unknown", descTwo:String="", doorSlot:int=-1, x:Int=0, floor:Int=0, doortype:Int=-1, owner:Int=-1, createRoomplannerSign:Int=FALSE)
		Local obj:TRooms=New TRooms.BaseSetup(name, desc, owner)

		screen.SetRoom(obj)

		'obj.background  = screen.background 'set default background

		obj.descTwo		= descTwo
		obj.doorDimension.SetX( Assets.GetSprite("gfx_building_Tueren").framew )
		obj.doorSlot	= doorSlot
		obj.doortype	= doortype
		'autocalc the position
		if x=-1 and doorSlot>=0 AND doorSlot<=4 then x = getDoorSlotX(doorSlot)
		obj.Pos			= TPoint.Create(x,floor)

		If createRoomplannerSign then obj.CreateRoomsign()

		if not _initdone
			EventManager.registerListenerFunction("room.onTryLeave", onTryLeave)
			EventManager.registerListenerFunction("room.onLeave", onLeave)
			EventManager.registerListenerFunction("room.onTryEnter", onTryEnter)
			EventManager.registerListenerFunction("room.onEnter", onEnter)
			_initDone = true
		endif

		Return obj
	End Function


	Method BaseSetup:TRooms(name:string, desc:string, owner:int)
		self.name		= name
		self.desc		= desc
		self.owner		= owner
		self.LastID:+1
		self.id			= self.LastID

		DoorTimer.setInterval( ChangeRoomSpeed )

		rooms.AddLast(self)

		return self
	End Method


	Method GetSoundSource:TDoorSoundSource()
		if not _soundSource then _soundSource = TDoorSoundSource.Create(self)
		return _soundSource
	End Method


	Method isOccupant:int(figure:TFigure)
		return occupants.contains(figure)
	End Method


	Method hasOccupant:int()
		return occupants.count() > 0
	End Method


	Method addOccupant:int(figure:TFigure)
		if not occupants.contains(figure)
			occupants.addLast(figure)
		endif
		return TRUE
	End Method


	Method removeOccupant:int(figure:TFigure)
		if not occupants.contains(figure) then return FALSE

		occupants.remove(figure)
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
		if doorSlot >= 0 then return doorSlot

		if int(pos.x) = doorSlot1 then return 1
		if int(pos.x) = doorSlot2 then return 2
		if int(pos.x) = doorSlot3 then return 3
		if int(pos.x) = doorSlot4 then return 4

		return 0
	End Method


	Method getDoorType:int()
		if DoorTimer.isExpired() then return doortype else return 5
	End Method


	Method CloseDoor(figure:TFigure)
		'timer finished
		If Not DoorTimer.isExpired()
			GetSoundSource().PlayCloseDoorSfx(figure)
			DoorTimer.expire()
		Endif
	End Method


	Method OpenDoor(figure:TFigure)
		'timer ticks again
		If DoorTimer.isExpired()
			GetSoundSource().PlayOpenDoorSfx(figure)
		Endif
		DoorTimer.reset()
	End Method


	Function CloseAllDoors()
		For Local room:TRooms = EachIn rooms
			room.CloseDoor(null)
		Next
	End Function


	Function DrawDoorToolTips:Int()
		For Local obj:TRooms = EachIn rooms
			If obj.tooltip and obj.tooltip.enabled
				obj.tooltip.Draw()
			endif
		Next
	End Function


	Function UpdateDoorToolTips:Int(deltaTime:float)
		For Local obj:TRooms = EachIn rooms
			'delete and skip if not found
			If not obj then rooms.remove(obj); continue

			If obj.tooltip AND obj.tooltip.enabled
				obj.tooltip.area.position.SetY( Building.pos.y + Building.GetFloorY(obj.Pos.y) - Assets.GetSprite("gfx_building_Tueren").area.GetH() - 20 )
				obj.tooltip.Update(deltaTime)
				'delete old tooltips
				if obj.tooltip.lifetime < 0 then obj.tooltip = null
			EndIf

			'only show tooltip if not "empty" and mouse in door-rect
			If obj.desc <> "" and Game.Players[Game.playerID].Figure.inRoom = Null And TFunctions.IsIn(MouseManager.x, MouseManager.y, obj.Pos.x, Building.pos.y  + building.GetFloorY(obj.Pos.y) - obj.doorDimension.y, obj.doorDimension.x, obj.doorDimension.y)
				If obj.tooltip <> null
					obj.tooltip.Hover()
				else
					obj.tooltip = TTooltip.Create(obj.desc, obj.descTwo, 100, 140, 0, 0)
				endif
				obj.tooltip.area.position.setY( Building.pos.y + Building.GetFloorY(obj.Pos.y) - Assets.GetSprite("gfx_building_Tueren").area.GetH() - 20 )
				obj.tooltip.area.position.setX( obj.Pos.x + obj.doorDimension.x/2 - obj.tooltip.GetWidth()/2 )
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


	'returns whether the figure can leave the room
	Method CanEnter:int(figure:TFigure, forceEnter:int=FALSE)
		'emit event that someone wants to enter a room + param forceEnter
		local event:TEventSimple = TEventSimple.Create("room.onTryEnter", TData.Create().Add("figure", figure).AddNumber("forceEnter", forceEnter) , self )
		EventManager.triggerEvent( Event )
		if event.isVeto()
			'maybe someone wants to know that ...eg. for closing doors
			EventManager.triggerEvent( TEventSimple.Create("room.onCancelEnter", TData.Create().Add("figure", figure) , self ) )
			return FALSE
		endif
		return TRUE
	End Method


	Method DoEnter:int(figure:TFigure, speed:int)
		'inform others that we start going into the room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginEnter", TData.Create().Add("figure", figure) , self ) )

		'finally inform that the figure enters the room - eg for AI-scripts
		'but delay that by ChangeRoomSpeed/2 - so the real entering takes place later
		local event:TEventSimple = TEventSimple.Create("room.onEnter", TData.Create().Add("figure", figure) , self )
		if speed = 0
			EventManager.triggerEvent(event)
		else
			event.delayStart(speed/2)
			EventManager.registerEvent(event)
		endif
	End Method


	Method Enter:int( figure:TFigure=null, forceEnter:int )
		'figure is already in that room - so just enter
		if isOccupant(figure) then return TRUE

		'ask if enter possible
		if not CanEnter(figure, forceEnter) then return FALSE

'if figure.id = 1 then print "2/4 | room: onTryEnter | room: "+self.name

		'enter is allowed
		figure.isChangingRoom = true
		'actually enter the room
		DoEnter(figure, ChangeRoomSpeed/2)
		return TRUE
	End Method


	'gets called if somebody tries to enter a room
	'also kicks figures in rooms if the owner tries to enter
	Function onTryEnter:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent.getData().get("figure") )
		if not figure then return FALSE

		local room:TRooms = TRooms(triggerEvent.getSender())
		if not room then return FALSE

		local forceEnter:int = triggerEvent.getData().getInt("forceEnter",FALSE)

		'no problem as soon as multiple figures are allowed
		if room.allowMultipleOccupants then return TRUE

 		'set the room used in that moment already - else
 		'two figures opening the door at the same time will both get
 		'into the room (occupied check is done here in "onTry")
		if not room.hasOccupant() then room.addOccupant(figure)

		'occupied, only one figure allowed and figure is not the occupier
		If room.hasOccupant() and not room.isOccupant(figure)
			'only player-figures need such handling (events etc.)
			If figure.parentPlayerID
				'kick others, except multiple figures allowed in the room
				If figure.parentPlayerID = room.owner OR forceEnter
					'andere rausschmeissen (falls vorhanden)
					for local occupant:TFigure = eachin room.occupants
						figure.KickFigureFromRoom(occupant, room)
					next
				'Besetztzeichen ausgeben / KI informieren
				Else
					'Spieler-KI benachrichtigen
					If figure.isAI() then Game.GetPlayer(figure.parentPlayerID).PlayerKI.CallOnReachRoom(LuaFunctions.RESULT_INUSE)
					'tooltip only for active user
					If figure.isActivePlayer() then Building.CreateRoomUsedTooltip(room)

					triggerEvent.setVeto()
					return FALSE
				EndIf
			EndIf
		EndIf

		return TRUE
	End Function


	'gets called when the figure really enters a room (fadeout animation finished etc)
	Function onEnter:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent.getData().get("figure") )
		if not figure then return FALSE

		local room:TRooms = TRooms(triggerEvent.getSender())
		if not room then return FALSE

		'set the room used
		room.addOccupant(figure)

'if figure.id = 1 then print "3/4 | room: onEnter | room: "+self.name+ " | triggering figure.onEnterRoom"
		'inform others that a figure enters the room
		EventManager.triggerEvent( TEventSimple.Create("figure.onEnterRoom", TData.Create().Add("room", room) , figure ) )

		'close the door
		If room.GetDoorType() >= 0 then room.CloseDoor(figure)
	End Function


	'returns whether the figure can leave the room
	Method CanLeave:int(figure:TFigure=null)
		'emit event that someone wants to leave a room
		local event:TEventSimple = TEventSimple.Create("room.onTryLeave", TData.Create().Add("figure", figure) , self )
		EventManager.triggerEvent( Event )
		if event.isVeto()
			EventManager.triggerEvent( TEventSimple.Create("room.onCancelLeave", TData.Create().Add("figure", figure) , self ) )
			return FALSE
		endif
		return TRUE
	End Method


	Method DoLeave:int(figure:TFigure, speed:int)

		'inform others that we start going out of that room (eg. for animations)
		EventManager.triggerEvent( TEventSimple.Create("room.onBeginLeave", TData.Create().Add("figure", figure) , self ) )

		'finally inform that the figure leaves the room - eg for AI-scripts
		'but delay that ChangeRoomSpeed/2 - so the real leaving takes place later
		local event:TEventSimple = TEventSimple.Create("room.onLeave", TData.Create().Add("figure", figure) , self )

		if speed = 0
			EventManager.triggerEvent(event)
		else
			event.delayStart(speed/2)
			EventManager.registerEvent(event)
		endif
	End Method


	'a figure wants to leave that room
	Method Leave:int( figure:TFigure=null )
		if not figure then figure = Game.getPlayer().figure

		'figure isn't in that room - so just leave
		if not isOccupant(figure) then return TRUE

		'ask if leave possible
		if not CanLeave(figure) then return FALSE
		'if figure.id = 1 then print "2/4 | figure: "+figure.name+" | room: onTryLeave | room: "+self.name
		'leave is allowed
		figure.isChangingRoom = true
		'actually leave the room
		DoLeave(figure, ChangeRoomSpeed/2)

		return TRUE
	End Method


	'gets called if somebody tries to leave a room
	Function onTryLeave:int(triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent.getData().get("figure") )
		if not figure then return FALSE

		local room:TRooms = TRooms(triggerEvent.getSender())
		if not room then return FALSE

		'only pay attention to players
		if figure.ParentPlayerID
			'roomboard left without animation as soon as something dragged but leave forced
			If room.name = "roomboard" 	AND TRoomSigns.AdditionallyDragged > 0
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Function


	'gets called when the figure really leaves the room (fadein animation finished etc)
	Function onLeave:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent.getData().get("figure") )
		if not figure then return FALSE

		local room:TRooms = TRooms(triggerEvent.getSender())
		if not room then return FALSE
'if figure.id = 1 then print "3/4 | room: onLeave | room: "+self.name+ " | triggering figure.onLeaveRoom"
		'inform others that a figure leaves the room
		EventManager.triggerEvent( TEventSimple.Create("figure.onLeaveRoom", TData.Create().Add("room", room) , figure ) )

		'open the door
		If room.GetDoorType() >= 0 then room.OpenDoor(figure)

		'remove the occupant from the rooms list
		room.removeOccupant(figure)
	End Function



	Function DrawDoorsOnBackground:Int()
		'do nothing if already done
		If _doorsDrawnToBackground then return 0

		Local Pix:TPixmap = LockImage(Assets.GetSprite("gfx_building").parent.image)

		'elevator border
		Local elevatorBorder:TGW_Sprite= Assets.GetSprite("gfx_building_Fahrstuhl_Rahmen")
		For Local i:Int = 0 To 13
			DrawImageOnImage(elevatorBorder.getImage(), Pix, 230, 67 - elevatorBorder.area.GetH() + 73*i)
		Next

		local doorSprite:TGW_Sprite = Assets.GetSprite("gfx_building_Tueren")
		For Local obj:TRooms = EachIn rooms
			'skip invisible rooms (without door)
			if obj.name = "" OR obj.name = "roomboard" OR obj.name = "credits" OR obj.name = "porter" then continue
			If obj.doortype < 0 OR obj.Pos.x <= 0 then continue

			'clamp doortype
			obj.doortype = Min(5, obj.doortype)
			'draw door
			DrawImageOnImage(doorSprite.GetFrameImage(obj.doortype), Pix, obj.Pos.x - Building.pos.x - 127, Building.GetFloorY(obj.Pos.y) - doorSprite.area.GetH())
			'draw sign next to door
			'If obj.owner < 5 And obj.owner >=0 then DrawImageOnImage(Assets.GetSprite("gfx_building_sign"+obj.owner).parent.image , Pix, obj.Pos.x - Building.pos.x - 127 + 2 + doorSprite.framew, Building.GetFloorY(obj.Pos.y) - doorSprite.area.GetH())
		Next
		'no unlock needed atm as doing nothing
		'UnlockImage(Assets.GetSprite("gfx_building").parent.image)
		_doorsDrawnToBackground = True
	End Function


	Function DrawDoors:Int()
		local doorSprite:TGW_Sprite = Assets.GetSprite("gfx_building_Tueren")
		For Local obj:TRooms = EachIn rooms
			'skip invisible rooms (without door)
			if obj.name = "" OR obj.name = "roomboard" OR obj.name = "credits" OR obj.name = "porter" then continue
			If obj.doortype < 0 OR obj.Pos.x <= 0 then continue

			'==== DRAW DOOR ====
			If obj.getDoorType() >= 5
				If obj.getDoorType() = 5 AND obj.DoorTimer.isExpired() Then obj.CloseDoor(null)
				'valign = 1 -> subtract sprite height
				doorSprite.Draw(obj.Pos.x, Building.pos.y + Building.GetFloorY(obj.Pos.y), obj.getDoorType(), TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
			EndIf
			'==== DRAW DOOR SIGN ====
			'draw on same height than door startY
			If obj.owner < 5 And obj.owner >=0 then Assets.GetSprite("gfx_building_sign"+obj.owner).Draw(obj.Pos.x + 2 + doorSprite.framew, Building.pos.y + Building.GetFloorY(obj.Pos.y) - doorSprite.area.GetH())


			'show debug text
			if Game.DebugInfos
				local textY:int = Building.pos.y + Building.GetFloorY(obj.Pos.y) - 62
				if obj.hasOccupant()
					for local figure:TFigure = eachin obj.occupants
						Assets.fonts.basefont.Draw(figure.name, obj.Pos.x, textY)
						textY:-10
					next
				else
					Assets.fonts.basefont.Draw("empty", obj.Pos.x, textY)
				endif
			endif
		Next

	End Function


	'draw Room
	Method Draw:int()
		'if not self.screen then Throw "ERROR: room.draw() - screen missing";return 0
		'draw current screen
		'ScreenCollection.DrawCurrent(App.timer.getTween())
		'emit event so custom functions can run after screen draw, sender = screen
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenDraw", TData.Create().Add("room", self) , ScreenCollection.GetCurrentScreen() ) )

		'emit event so custom draw functions can run
		EventManager.triggerEvent( TEventSimple.Create("room.onDraw", null, self) )

		return 0
	End Method


	'process special functions of this room. Is there something to click on?
	'animated gimmicks? draw within this function.
	Method Update:Int()
		'emit event so custom functions can run after screen update, sender = screen
		'also this event has "room" as payload
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenUpdate", TData.Create().Add("room", self) , ScreenCollection.GetCurrentScreen() ) )

		'emit event so custom updaters can handle
		EventManager.triggerEvent( TEventSimple.Create("room.onUpdate", null, self) )

		'handle normal right click
		if MOUSEMANAGER.IsHit(2)
			'check subrooms
			'only leave a room if not in a subscreen
			'if in subscreen, go to parent one
			if ScreenCollection.GetCurrentScreen().parentScreen
				ScreenCollection.GoToParentScreen()
				MOUSEMANAGER.ResetKey(2)
			else
				'leaving prohibited - just reset button
				if not Game.GetPlayer().figure.LeaveRoom()
					MOUSEMANAGER.resetKey(2)
				endif
			endif
		endif

		return 0
	End Method


	Method CreateRoomSign:int(slot:int=-1)
		if slot = -1 then slot = doorSlot

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
		TRoomSigns.Create(desc, signx, signy, owner)
		return true
	End Method

	Function GetTargetRoom:TRooms(x:int, y:int)
		For Local room:TRooms = EachIn rooms
			'also allow invisible rooms... so just check if hit the area
			'If room.doortype >= 0 and TFunctions.IsIn(x, y, room.Pos.x, Building.pos.y + Building.GetFloorY(room.pos.y) - room.doorDimension.Y, room.doorDimension.x, room.doorDimension.y)
			If TFunctions.IsIn(x, y, room.Pos.x, Building.pos.y + Building.GetFloorY(room.pos.y) - room.doorDimension.Y, room.doorDimension.x, room.doorDimension.y)
				Return room
			EndIf
		Next
		Return Null
	End Function

	Function GetRoom:TRooms(ID:Int)
		For Local room:TRooms = EachIn rooms
			If room.id = id Then Return room
		Next
		Return Null
	End Function

	Function GetRoomFromXY:TRooms(x:Int, y:Int)
		if x < 0 or y < 0 then return NULL

		For Local room:TRooms= EachIn rooms
			If room.Pos.x = x And room.Pos.y = y Then Return room
		Next

		Return Null
	End Function

	Function GetRoomFromMapPos:TRooms(doorSlot:Int, floor:Int)
		if doorSlot >= 0 and floor >= 0
			For Local room:TRooms= EachIn rooms
				If room.Pos.y = floor And room.doorSlot = doorSlot Then Return room
			Next
		EndIf
		Return Null
	End Function

	Function GetRoomByDetails:TRooms(name:String, owner:Int, floor:int =-1)
		For Local room:TRooms= EachIn rooms
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
	'screen.onScreenUpdate/Draw is more general purpose
	Function _RegisterScreenHandler(updateFunc(triggerEvent:TEventBase), drawFunc(triggerEvent:TEventBase), screen:TScreen)
		if screen
			EventManager.registerListenerFunction( "room.onScreenUpdate", updateFunc, screen )
			EventManager.registerListenerFunction( "room.onScreenDraw", drawFunc, screen )
		endif
	End Function

'	Function Init() abstract
'	Function Update:int( triggerEvent:TEventBase ) abstract
'	Function Draw:int( triggerEvent:TEventBase ) abstract
End Type


'Office: handling the players room
Type RoomHandler_Office extends TRoomHandler
	'=== OFFICE ROOM ===
	global StationsToolTip:TTooltip
	global PlannerToolTip:TTooltip
	global SafeToolTip:TTooltip
	global currentSubRoom:TRooms = null
	global lastSubRoom:TRooms = null

	'=== STATIONMAP ===
	global stationList:TGUISelectList
	global stationMapMode:int				= 0	'1=searchBuy,2=buy,3=sell
	global stationMapActionConfirmed:int	= FALSE
	global stationMapSelectedStation:TStation
	global stationMapMouseoverStation:TStation
	global stationMapShowStations:TGUICheckBox[4]

	'=== PROGRAMME PLANNER ===
	Global showPlannerShortCutHintTime:int = 0
	Global showPlannerShortCutHintFadeAmount:int = 1
	Global planningDay:int = -1
	Global talkToProgrammePlanner:int = TRUE		'set to FALSE for deleting gui objects without modifying the plan
	Global DrawnOnProgrammePlannerBG:int = 0
	Global ProgrammePlannerButtons:TGUIImageButton[6]
	Global PPprogrammeList:TgfxProgrammelist
	Global PPcontractList:TgfxContractlist
	Global fastNavigateTimer:TIntervalTimer = TIntervalTimer.Create(250)
	Global fastNavigateInitialTimer:int = 250
	Global fastNavigationUsedContinuously:int = FALSE

	Global hoveredGuiProgrammePlanElement:TGuiProgrammePlanElement = null
	Global draggedGuiProgrammePlanElement:TGuiProgrammePlanElement = null
	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListProgrammes:TGUIProgrammePlanSlotList
	Global GuiListAdvertisements:TGUIProgrammePlanSlotList


	Function Init()
		'===== RUN SCREEN SPECIFIC INIT =====
		'(event connection etc.)
		InitStationMap()
		InitProgrammePlanner()

		'===== REGISTER SCREEN HANDLERS =====
		'no need for individual screens, all can be handled by one function (room is param)
		super._RegisterScreenHandler( onUpdateOffice, onDrawOffice, ScreenCollection.GetScreen("screen_office") )
		super._RegisterScreenHandler( onUpdateProgrammePlanner, onDrawProgrammePlanner, ScreenCollection.GetScreen("screen_office_pplanning") )
		super._RegisterScreenHandler( onUpdateFinancials, onDrawFinancials, ScreenCollection.GetScreen("screen_office_financials") )
		super._RegisterScreenHandler( onUpdateImage, onDrawImage, ScreenCollection.GetScreen("screen_office_image") )
		super._RegisterScreenHandler( onUpdateStationMap, onDrawStationMap, ScreenCollection.GetScreen("screen_office_stationmap") )

		'===== REGISTER EVENTS =====
		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
	End Function


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new programmes are not loaded yet

		hoveredGuiProgrammePlanElement = null
		draggedGuiProgrammePlanElement = null
		GuiListProgrammes.EmptyList()
		GuiListAdvertisements.EmptyList()

		haveToRefreshGuiElements = true
	End Function


	Function InitProgrammePlanner()
		'add gfx to background image
		If Not DrawnOnProgrammePlannerBG then InitProgrammePlannerBackground()

		'===== CREATE GUI LISTS =====
		'the visual gap between 0-11 and 12-23 hour
		local gapBetweenHours:int = 57
		local area:TRectangle = TRectangle.Create(67,17,600,12 * Assets.GetSprite("pp_programmeblock1").area.GetH())

		GuiListProgrammes = new TGUIProgrammePlanSlotList.Create(area.GetX(),area.GetY(),area.GetW(),area.GetH(), "programmeplanner")
		GuiListProgrammes.Init("pp_programmeblock1", Assets.GetSprite("pp_adblock1").area.GetW() + gapBetweenHours)
		GuiListProgrammes.isType = TBroadcastMaterial.TYPE_PROGRAMME

		GuiListAdvertisements = new TGUIProgrammePlanSlotList.Create(area.GetX() + Assets.GetSprite("pp_programmeblock1").area.GetW(),area.GetY(),area.GetW(),area.GetH(), "programmeplanner")
		GuiListAdvertisements.Init("pp_adblock1", Assets.GetSprite("pp_programmeblock1").area.GetW() + gapBetweenHours)
		GuiListAdvertisements.isType = TBroadcastMaterial.TYPE_ADVERTISEMENT



		'init lists
		PPprogrammeList		= new TgfxProgrammelist.Create(660, 16, 21)
		PPcontractList		= new TgfxContractlist.Create(660, 16)

		'buttons
		TGUILabel.SetDefaultLabelFont( Assets.GetFont("Default", 10, BOLDFONT) )
		ProgrammePlannerButtons[0] = new TGUIImageButton.Create(672, 40+0*56, "programmeplanner_btn_ads","programmeplanner_buttons")
		ProgrammePlannerButtons[0].SetCaption(GetLocale("PLANNER_ADS"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[1] = new TGUIImageButton.Create(672, 40+1*56, "programmeplanner_btn_programme","programmeplanner_buttons")
		ProgrammePlannerButtons[1].SetCaption(GetLocale("PLANNER_PROGRAMME"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[2] = new TGUIImageButton.Create(672, 40+2*56, "programmeplanner_btn_options","programmeplanner_buttons")
		ProgrammePlannerButtons[2].SetCaption(GetLocale("PLANNER_OPTIONS"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[3] = new TGUIImageButton.Create(672, 40+3*56, "programmeplanner_btn_financials","programmeplanner_buttons")
		ProgrammePlannerButtons[3].SetCaption(GetLocale("PLANNER_FINANCES"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[4] = new TGUIImageButton.Create(672, 40+4*56, "programmeplanner_btn_image","programmeplanner_buttons")
		ProgrammePlannerButtons[4].SetCaption(GetLocale("PLANNER_IMAGE"),,TPoint.Create(0,42))
		ProgrammePlannerButtons[5] = new TGUIImageButton.Create(672, 40+5*56, "programmeplanner_btn_news","programmeplanner_buttons")
		ProgrammePlannerButtons[5].SetCaption(GetLocale("PLANNER_MESSAGES"),,TPoint.Create(0,42))
		for local i:int = 0 to 5
			ProgrammePlannerButtons[i].caption.SetContentPosition(ALIGN_CENTER, ALIGN_CENTER)
		Next
		TGUILabel.SetDefaultLabelFont( null )


		'===== REGISTER EVENTS =====

		'for all office rooms - register if someone goes into the programmeplanner
		local screen:TScreen = ScreenCollection.GetScreen("screen_office_pplanning")
		'player enters screen - reset the guilists
		if screen then EventManager.registerListenerFunction("screen.onEnter", onEnterProgrammePlannerScreen, screen)
		'player leaves screen - only without dragged blocks
		EventManager.registerListenerFunction("screen.OnLeave", onLeaveProgrammePlannerScreen, screen)

		'to react on changes in the programmePlan (eg. contract finished)
		EventManager.registerListenerFunction("programmeplan.addObject", onChangeProgrammePlan)
		EventManager.registerListenerFunction("programmeplan.removeObject", onChangeProgrammePlan)
		'also react on "group changes" like removing unneeded adspots
		EventManager.registerListenerFunction("programmeplan.removeObjectInstances", onChangeProgrammePlan)


		'begin drop - to intercept if dropping ad to programme which does not allow Ad-Show
		EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammePlanElement, "TGUIProgrammePlanElement")
		'drag/drop ... from or to one of the two lists
'		EventManager.registerListenerFunction("guiList.TryRemoveItem", onTryRemoveItemFromSlotList, GuiListProgrammes)
'		EventManager.registerListenerFunction("guiList.TryRemoveItem", onTryRemoveItemFromSlotList, GuiListAdvertisements)
		EventManager.registerListenerFunction("guiList.removeItem", onRemoveItemFromSlotList, GuiListProgrammes)
		EventManager.registerListenerFunction("guiList.removeItem", onRemoveItemFromSlotList, GuiListAdvertisements)
		EventManager.registerListenerFunction("guiList.addItem", onAddItemToSlotList, GuiListProgrammes)
		EventManager.registerListenerFunction("guiList.addItem", onAddItemToSlotList, GuiListAdvertisements)
		'so we can forbid adding to a "past"-slot
		EventManager.registerListenerFunction("guiList.TryAddItem", onTryAddItemToSlotList, GuiListProgrammes)
		EventManager.registerListenerFunction("guiList.TryAddItem", onTryAddItemToSlotList, GuiListAdvertisements)
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction("guiGameObject.OnMouseOver", onMouseOverProgrammePlanElement, "TGUIProgrammePlanElement" )
		'these lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction("guiobject.onClick", onClickProgrammePlanElement, "TGUIProgrammePlanElement")
		'handle dragging of dayChangeProgrammePlanElements (eg. when dropping an item on them)
		'in this case - send them to GuiManager (like freshly created to avoid a history)
		EventManager.registerListenerFunction("guiobject.onDrag", onDragProgrammePlanElement, "TGUIProgrammePlanElement")
		'intercept dragging items if we want a SHIFT/CTRL-copy/nextepisode
		EventManager.registerListenerFunction("guiobject.onTryDrag", onTryDragProgrammePlanElement, "TGUIProgrammePlanElement")
		'handle dropping at the end of the list (for dragging overlapped items)
		EventManager.registerListenerFunction("programmeplan.addObject", onProgrammePlanAddObject)

		'we want to colorize the list background depending on minute
		'EventManager.registerListenerFunction("Game.OnMinute",	onGameMinute)

		'we are interested in the programmeplanner buttons
		EventManager.registerListenerFunction( "guiobject.onClick", onProgrammePlannerButtonClick, "TGUIImageButton" )
	End Function



	Function CheckPlayerInRoom:int()
		'check if we are in the correct room
		if not Game.getPlayer().figure.inRoom then return FALSE
		if Game.getPlayer().figure.inRoom.name <> "office" then return FALSE

		return TRUE
	End Function


	'===== OFFICE ROOM SCREEN ======


	Function onDrawOffice:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		if room.background then room.background.draw(20,10)

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
			If TFunctions.IsIn(MouseManager.x,MouseManager.y,25,40,150,295)
				Game.Players[Game.playerID].Figure.LeaveRoom()
				MOUSEMANAGER.resetKey(1)
			EndIf
		EndIf

		Game.cursorstate = 0
		'safe - reachable for all
		If TFunctions.IsIn(MouseManager.x, MouseManager.y, 165,85,70,100)
			If SafeToolTip = Null Then SafeToolTip = TTooltip.Create("Safe", "Laden und Speichern", 140, 100, 0, 0)
			SafeToolTip.enabled = 1
			SafeToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0

				ScreenCollection.GoToSubScreen("screen_office_safe")
			endif
		EndIf

		'planner - reachable for all
		If TFunctions.IsIn(MouseManager.x, MouseManager.y, 600,140,128,210)
			If PlannerToolTip = Null Then PlannerToolTip = TTooltip.Create("Programmplaner", "und Statistiken", 580, 140, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				ScreenCollection.GoToSubScreen("screen_office_pplanning")
			endif
		EndIf

		'station map - only reachable for owner
		If room.owner = Game.playerID
			If TFunctions.IsIn(MouseManager.x, MouseManager.y, 732,45,160,170)
				If not StationsToolTip Then StationsToolTip = TTooltip.Create("Senderkarte", "Kauf und Verkauf", 650, 80, 0, 0)
				StationsToolTip.enabled = 1
				StationsToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0
					ScreenCollection.GoToSubScreen("screen_office_stationmap")
				endif
			EndIf
			If StationsToolTip Then StationsToolTip.Update(App.timer.getDelta())
		EndIf

		If PlannerToolTip Then PlannerToolTip.Update(App.timer.getDelta())
		If SafeToolTip Then SafeToolTip.Update(App.timer.getDelta())
	End Function



	'===== OFFICE PROGRAMME PLANNER SCREEN =====

	'=== EVENTS ===

	'clear the guilist if a player enters
	'screens are only handled by real players
	Function onEnterProgrammePlannerScreen:int(triggerEvent:TEventBase)
		'==== EMPTY/DELETE GUI-ELEMENTS =====

		hoveredGuiProgrammePlanElement = null
		draggedGuiProgrammePlanElement = null

		RefreshGUIElements()
	End Function


	Function onLeaveProgrammePlannerScreen:int( triggerEvent:TEventBase )
		'do not allow leaving with a list open
		if PPprogrammeList.enabled Or PPcontractList.enabled
			PPprogrammeList.SetOpen(0)
			PPcontractList.SetOpen(0)
			triggerEvent.SetVeto()
			return FALSE
		endif

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammePlanElement
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function


	'sets slots of the lists used according to the current time
	Function onGameMinute:int(triggerEvent:TEventBase)
		Local minute:Int = triggerEvent.GetData().getInt("minute",-1)
		Local hour:Int = triggerEvent.GetData().getInt("hour",-1)
		'programme start
'		if minute = 5 then GuiListProgrammes.SetSlotState(hour, 2)
		'programme start
'		if minute = 55 then GuiListAdvertisements.SetSlotState(hour, 2)
		return TRUE
	End Function


	'if players are in the office during changes
	'to their programme plan, react to...
	Function onChangeProgrammePlan:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		'is it our plan?
		local plan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		if not plan then return FALSE
		if plan.parent <> Game.getPlayer() then return FALSE
'print "onChangeProgrammePlan: running RefreshGuiElements"
'		haveToRefreshGuiElements = TRUE
		RefreshGuiElements()
	End Function


	'handle dragging dayChange elements (give them to GuiManager)
	'this way the newly dragged item is kind of a "newly" created
	'item without history of a former slot etc.
	Function onDragProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		'check if we somehow dragged a dayChange element
		'if so : remove it from the list and let the GuiManager manage it
		if item = GuiListProgrammes.dayChangeGuiProgrammePlanElement
			GuiManager.AddDragged(GuiListProgrammes.dayChangeGuiProgrammePlanElement)
			GuiListProgrammes.dayChangeGuiProgrammePlanElement = null
			return TRUE
		endif
		if item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement
			GuiManager.AddDragged(GuiListAdvertisements.dayChangeGuiProgrammePlanElement)
			GuiListAdvertisements.dayChangeGuiProgrammePlanElement = null
			return TRUE
		endif
		return FALSE
	End Function


	Function onTryDragProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		if CreateNextEpisodeOrCopyByShortcut(item)
			triggerEvent.SetVeto()
			return FALSE
		endif

		'dragging is ok
		return TRUE
	End Function

	'handle adding items at the end of a day
	'so the removed material can be recreated as dragged gui items
	Function onProgrammePlanAddObject:int(triggerEvent:TEventBase)
		local removedObjects:object[] = object[](triggerEvent.GetData().get("removedObjects"))
		local addedObject:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().get("object"))
		if not removedObjects then return FALSE
		if not addedObject then return FALSE
		'also not interested if the programme ends before midnight
		if addedObject.programmedHour + addedObject.getBlocks() <= 24 then return FALSE

		'create new gui items for all removed ones
		'this also includes todays programmes:
		'ex: added 5block to 21:00 - removed programme from 23:00-24:00 gets added again too
		for local i:int = 0 to removedObjects.length-1
			local material:TBroadcastMaterial = TBroadcastMaterial(removedObjects[i])
			if material then new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(material, "programmePlanner").drag()
		Next
		return FALSE
	End Function


	'intercept if item does not allow dropping on specific lists
	'eg. certain ads as programme if they do not allow no commercial shows
	Function onTryDropProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetReceiver())
		if not list then return FALSE

		'check if that item is allowed to get dropped on such a list

		'up to now: all are allowed
		return TRUE
	End Function


	'remove the material from the programme plan
	Function onRemoveItemFromSlotList:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		local slot:int = triggerEvent.GetData().getInt("slot", -1)
		if not list or not item or slot = -1 then return FALSE

		'we removed the item but do not want the planner to know
		if not talkToProgrammePlanner then return TRUE

		if list = GuiListProgrammes
			if not Game.getPlayer().ProgrammePlan.RemoveProgramme(item.broadcastMaterial)
				print "[WARNING] dragged item from programmelist - removing from programmeplan at "+slot+":00 - FAILED"
			endif
		elseif list = GuiListAdvertisements
			if not Game.getPlayer().ProgrammePlan.RemoveAdvertisement(item.broadcastMaterial)
				print "[WARNING] dragged item from adlist - removing from programmeplan at "+slot+":00 - FAILED"
			endif
		else
			print "[ERROR] dragged item from unknown list - removing from programmeplan at "+slot+":00 - FAILED"
		endif


		return TRUE
	End Function


	'add the material to the programme plan
	'added shortcuts for faster placement here as this event
	'is emitted on successful placements (avoids multiple dragged blocks
	'while dropping not possible)
	Function onAddItemToSlotList:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		local slot:int = triggerEvent.GetData().getInt("slot", -1)
		if not list or not item or slot = -1 then return FALSE

		'we removed the item but do not want the planner to know
		if not talkToProgrammePlanner then return TRUE

		if list = GuiListProgrammes
			if not Game.getPlayer().ProgrammePlan.AddProgramme(item.broadcastMaterial, planningDay, slot)
				print "[WARNING] dropped item on programmelist - adding to programmeplan at "+slot+":00 - FAILED"
				return FALSE
			endif
		elseif list = GuiListAdvertisements
			if not Game.getPlayer().ProgrammePlan.AddAdvertisement(item.broadcastMaterial, planningDay, slot)
				print "[WARNING] dropped item on adlist - adding to programmeplan at "+slot+":00 - FAILED"
				return FALSE
			endif
		else
			print "[ERROR] dropped item on unknown list - adding to programmeplan at "+slot+":00 - FAILED"
			return FALSE
		endif

		'if a shortcut is pressed - create copy/next episode
		'CreateNextEpisodeOrCopyByShortcut(item)

		return TRUE
	End Function


	'checks if it is allowed to occupy the the targeted slot (eg. slot lies in the past)
	Function onTryAddItemToSlotList:int(triggerEvent:TEventBase)
		local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		local slot:int = triggerEvent.GetData().getInt("slot", -1)
		if not list or not item or slot = -1 then return FALSE

		'only check slot state if interacting with the programme planner
		if talkToProgrammePlanner
			'already running or in the past
			if list.GetSlotState(slot) = 2
				triggerEvent.SetVeto()
				return FALSE
			endif
		endif
		return TRUE
	End Function


	'right mouse button click: remove the block from the player's programmePlan
	'left mouse button click: check shortcuts and create a copy/nextepisode-block
	Function onClickProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement= TGUIProgrammePlanElement(triggerEvent._sender)
		if not item then print "onClickProgrammePlanElement got wrong sender";return false

		'left mouse button
		if triggerEvent.GetData().getInt("button",0) = 1
			'special handling for special items
			'-> remove dayChangeObjects from plan if dragging
			if not item.isDragged() and talkToProgrammePlanner
				if item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement
					if Game.getPlayer().ProgrammePlan.RemoveAdvertisement(item.broadcastMaterial)
						GuiListAdvertisements.dayChangeGuiProgrammePlanElement = null
					endif
				elseif item = GuiListProgrammes.dayChangeGuiProgrammePlanElement
					if Game.getPlayer().ProgrammePlan.RemoveProgramme(item.broadcastMaterial)
						GuiLisTProgrammes.dayChangeGuiProgrammePlanElement = null
					endif
				endif
			endif


			'if shortcut is used on a dragged item ... it gets executed
			'on a successful drop, no need to do it here before
			if item.isDragged() then return FALSE

			'assisting shortcuts create new guiobjects
			if CreateNextEpisodeOrCopyByShortcut(item)
				'do not try to drag the object - we did something special
				triggerEvent.SetVeto()
				return FALSE
			endif

			return TRUE
		endif

		'right mouse button - delete
		if triggerEvent.GetData().getInt("button",0) = 2
			'ignore wrong types and NON-dragged items
			if not item.isDragged() then return FALSE

			'remove if special
			if item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement then GuiListAdvertisements.dayChangeGuiProgrammePlanElement = null
			if item = GuiListProgrammes.dayChangeGuiProgrammePlanElement then GuiListProgrammes.dayChangeGuiProgrammePlanElement = null

			'will automatically rebuild at correct spot if needed
			item.remove()
			item = null

			'remove right click - to avoid leaving the room
			MouseManager.ResetKey(2)
		endif
	End Function


	Function onMouseOverProgrammePlanElement:int(triggerEvent:TEventBase)
		local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		if not item then return FALSE

		'only assign the first hovered item (to avoid having the lowest of a stack)
		if not hoveredGuiProgrammePlanElement
			hoveredGuiProgrammePlanElement = item
			TGUIProgrammePlanElement.hoveredElement = item

			if item.isDragged()
				draggedGuiProgrammePlanElement = item
				'if we have an item dragged... we cannot have a menu open
				PPprogrammeList.SetOpen(0)
				PPcontractList.SetOpen(0)
			endif
		endif

		return TRUE
	End Function


	Function onDrawProgrammePlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		'time indicator
		If planningDay = Game.GetDay() Then SetColor 0,100,0
		If planningDay < Game.GetDay() Then SetColor 100,100,0
		If planningDay > Game.GetDay() Then SetColor 0,0,0
		Assets.GetFont("Default", 10).drawBlock(Game.GetFormattedDay(1+ planningDay - Game.GetDay(Game.GetTimeStart())), 691, 18, 100, 15)
		SetColor 255,255,255

		GUIManager.Draw("programmeplanner|programmeplanner_buttons")

		if hoveredGuiProgrammePlanElement
			'draw the current sheet
			hoveredGuiProgrammePlanElement.DrawSheet(30, 35, 700)
		endif


		'overlay old days
		If Game.GetDay() > planningDay
			SetColor 100,100,100
			SetAlpha 0.5
			DrawRect(27,17,637,360)
			SetColor 255,255,255
			SetAlpha 1.0
		EndIf

		SetColor 255,255,255
		If room.owner = Game.playerID
			If PPprogrammeList.GetOpen() > 0 Then PPprogrammeList.Draw()
			If PPcontractList.GetOpen()  > 0 Then PPcontractList.Draw()
			'draw lists sheet
			If PPprogrammeList.GetOpen() and PPprogrammeList.hoveredLicence
				PPprogrammeList.hoveredLicence.ShowSheet(30,20)
			endif
			'If PPcontractList.GetOpen() and
			if PPcontractList.hoveredAdContract
				PPcontractList.hoveredAdContract.ShowSheet(30,20)
			endif
		EndIf

		if showPlannerShortCutHintTime > 0
			SetAlpha showPlannerShortCutHintTime/100.0
			DrawRect(23, 18, 640, 18)
			SetAlpha Min(1.0, 2.0*showPlannerShortCutHintTime/100.0)
			Assets.GetFont("Default", 11, BOLDFONT).drawBlock(GetLocale("HINT_PROGRAMMEPLANER_SHORTCUTS"), 23, 20, 640, 15, TPoint.Create(ALIGN_CENTER), TColor.Create(0,0,0),2,1,0.25)
			SetAlpha 1.0
		else
			SetAlpha 0.75
		endif
		DrawOval(-8,-8,55,55)
		Assets.GetFont("Default", 24, BOLDFONT).drawStyled("?", 22, 17, TColor.Create(50,50,150),2,1,0.5)
		SetAlpha 1.0
	End Function


	Function onUpdateProgrammePlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		'if not initialized, do so
		if planningDay = -1 then planningDay = Game.GetDay()


		Game.cursorstate = 0

		'set all slots occupied or not
		local day:int = Game.GetDay()
		local hour:int = Game.GetHour()
		local minute:int = Game.GetMinute()
		for local i:int = 0 to 23
			if not TPlayerProgrammePlan.IsUseableTimeSlot(TBroadcastMaterial.TYPE_PROGRAMME, planningDay, i, day, hour, minute)
				GuiListProgrammes.SetSlotState(i, 2)
			else
				GuiListProgrammes.SetSlotState(i, 0)
			endif
			if not TPlayerProgrammePlan.IsUseableTimeSlot(TBroadcastMaterial.TYPE_ADVERTISEMENT, planningDay, i, day, hour, minute)
				GuiListAdvertisements.SetSlotState(i, 2)
			else
				GuiListAdvertisements.SetSlotState(i, 0)
			endif
		Next

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then RefreshGUIElements()


		'reset hovered and dragged gui objects - gets repopulated automagically
		hoveredGuiProgrammePlanElement = null
		draggedGuiProgrammePlanElement = null
		TGUIProgrammePlanElement.hoveredElement = null

		If TFunctions.IsIn(MouseManager.x, MouseManager.y, 759,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0

				ChangePlanningDay(planningDay+1)
			endif
		EndIf
		If TFunctions.IsIn(MouseManager.x, MouseManager.y, 670,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0

				ChangePlanningDay(planningDay-1)
			endif
		EndIf
		'RON
		'fast movement is possible with keys
		'we use doAction as this allows a decreasing time
		'while keeping the original interval backupped
		if fastNavigateTimer.isExpired()
			if not KEYMANAGER.isDown(KEY_PAGEUP) and not KEYMANAGER.isDown(KEY_PAGEDOWN)
				fastNavigationUsedContinuously = FALSE
			endif
			if KEYMANAGER.isDown(KEY_PAGEUP)
				ChangePlanningDay(planningDay-1)
				fastNavigationUsedContinuously = TRUE
			endif
			if KEYMANAGER.isDown(KEY_PAGEDOWN)
				ChangePlanningDay(planningDay+1)
				fastNavigationUsedContinuously = TRUE
			endif

			'modify action time AND reset timer
			if fastNavigationUsedContinuously
				'decrease action time each time a bit more...
				fastNavigateTimer.setInterval( Max(50, fastNavigateTimer.GetInterval() * 0.9), true )
			else
				'set to initial value
				fastNavigateTimer.setInterval( fastNavigateInitialTimer, true )
			endif
		endif


		local listsOpened:int = (PPprogrammeList.enabled Or PPcontractList.enabled)
		'only handly programmeblocks if the lists are closed
		if not listsOpened
			GUIManager.Update("programmeplanner|programmeplanner_buttons")
		'if a list is opened, we cannot have a hovered gui element
		else
			hoveredGuiProgrammePlanElement = null
			'but still have to check for clicks on the buttons
			GUIManager.Update("programmeplanner_buttons")
		endif


		If room.owner = Game.playerID
			PPprogrammeList.Update()
			PPcontractList.Update()
		EndIf

		'hide or show help
		If TFunctions.IsIn(MouseManager.x, MouseManager.y, 10,10,35,35)
			showPlannerShortCutHintTime = 90
			showPlannerShortCutHintFadeAmount = 1
		else
			showPlannerShortCutHintTime = Max(showPlannerShortCutHintTime-showPlannerShortCutHintFadeAmount, 0)
			showPlannerShortCutHintFadeAmount:+1
		endif
	End Function


	Function onProgrammePlannerButtonClick:int( triggerEvent:TEventBase )
		local button:TGUIImageButton = TGUIImageButton( triggerEvent._sender )
		if not button then return 0

		'only react if the click came from the left mouse button
		if triggerEvent.GetData().getInt("button",0) <> 1 then return TRUE

		'Just close all lists and reopen the wanted one
		'->saves "if ProgrammePlannerButtons[o].clicked then closeAll, openMine ..."

		'close both lists
		PPcontractList.SetOpen(0)
		PPprogrammeList.SetOpen(0)

		'reset mousebutton
		MouseManager.ResetKey(1)

		'open others?
		If button = ProgrammePlannerButtons[0] Then return PPcontractList.SetOpen(1)		'opens contract list
		If button = ProgrammePlannerButtons[1] Then return PPprogrammeList.SetOpen(1)		'opens programme genre list

		local room:TRooms = Game.Players[Game.playerID].Figure.inRoom
		'If button = ProgrammePlannerButtons[2] then return ScreenCollection.GoToSubScreen("screen_office_options")
		If button = ProgrammePlannerButtons[3] then return ScreenCollection.GoToSubScreen("screen_office_financials")
		If button = ProgrammePlannerButtons[4] then return ScreenCollection.GoToSubScreen("screen_office_image")
		'If button = ProgrammePlannerButtons[5] then return ScreenCollection.GoToSubScreen("screen_office_messages")
	End Function


	'=== COMMON FUNCTIONS / HELPERS ===


	Function CreateNextEpisodeOrCopyByShortcut:int(item:TGUIProgrammePlanElement)
		if not item then return FALSE
		'assisting shortcuts create new guiobjects
		'shift: next episode
		'ctrl : programme again
		if KEYMANAGER.IsDown(KEY_LSHIFT) OR KEYMANAGER.IsDown(KEY_RSHIFT)
			'reset key
			KEYMANAGER.ResetKey(KEY_LSHIFT)
			KEYMANAGER.ResetKey(KEY_RSHIFT)
			CreateNextEpisodeOrCopy(item, FALSE)
			return TRUE
		elseif KEYMANAGER.IsDown(KEY_LCONTROL) OR KEYMANAGER.IsDown(KEY_RCONTROL)
			KEYMANAGER.ResetKey(KEY_LCONTROL)
			KEYMANAGER.ResetKey(KEY_RCONTROL)
			CreateNextEpisodeOrCopy(item, TRUE)
			return TRUE
		endif
		'nothing clicked
		return FALSE
	End Function

	Function CreateNextEpisodeOrCopy:int(item:TGUIProgrammePlanElement, createCopy:int=TRUE)
		local newMaterial:TBroadcastMaterial = null

		'copy:         for ads and programmes create a new object based
		'              on licence or contract
		'next episode: for ads: create a copy
		'              for movies and series: rely on a licence-function
		'              which returns the next licence of a series/collection
		'              OR the first one if already on the latest spot

		select item.broadcastMaterial.materialType
			case TBroadcastMaterial.TYPE_ADVERTISEMENT
				newMaterial = new TAdvertisement.Create(TAdvertisement(item.broadcastMaterial).contract)

			case TBroadcastMaterial.TYPE_PROGRAMME
				if CreateCopy
					newMaterial = new TProgramme.Create(TProgramme(item.broadcastMaterial).licence)
				else
					local licence:TProgrammeLicence = TProgramme(item.broadcastMaterial).licence.GetNextSubLicence()
					'if no licence was given, the licence is for a normal movie...
					if not licence then licence = TProgramme(item.broadcastMaterial).licence
					newMaterial = new TProgramme.Create(licence)
				endif
		end select

		'create and drag
		if newMaterial then new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(newMaterial, "programmePlanner").drag()
	End Function


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int(removeDragged:int=TRUE)
		GuiListProgrammes.EmptyList()
		GuiListAdvertisements.EmptyList()
		'remove dragged ones
		if removeDragged
			For local guiObject:TGuiProgrammePlanElement = eachin GuiManager.listDragged
				guiObject.remove()
			Next
		endif

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Function


	Function ChangePlanningDay:int(day:int=0)
		planningDay = day
		'limit to start day
		If planningDay < Game.GetDay(Game.timeStart) Then planningDay = Game.GetDay(Game.timeStart)

		'change to silent mode: do not interact with programmePlanner
		talkToProgrammePlanner = FALSE
		'FALSE: without removing dragged
		'->ONLY keeps newly created, not ones dragged from a slot
		RemoveAllGuiElements(FALSE)

		RefreshGuiElements()
		talkToProgrammePlanner = TRUE
	end Function


	Function RefreshGuiElements:int()
		'===== REMOVE UNUSED =====

		'remove overnight
		if GuiListProgrammes.daychangeGuiProgrammePlanElement then GuiListProgrammes.daychangeGuiProgrammePlanElement.remove()
		if GuiListAdvertisements.daychangeGuiProgrammePlanElement then GuiListAdvertisements.daychangeGuiProgrammePlanElement.remove()

		'remove gui elements with material the player does not have any longer in plan
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListProgrammes._slots
			if guiObject.isDragged() then continue
			'check if programmed on the current day
			if guiObject.broadcastMaterial.isProgrammedForDay(planningDay) then continue
			'print "GuiListProgramme has obsolete programme: "+guiObject.broadcastMaterial.GetTitle()
			guiObject.remove()
		Next
		For local guiObject:TGuiProgrammePlanElement = eachin GuiListAdvertisements._slots
			if guiObject.isDragged() then continue
			'check if programmed on the current day
			if guiObject.broadcastMaterial.isProgrammedForDay(planningDay) then continue
			'print "GuiListAdvertisement has obsolete ad: "+guiObject.broadcastMaterial.GetTitle()
			guiObject.remove()
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all programmes/ads
		local daysProgramme:TBroadcastMaterial[] = Game.getPlayer().ProgrammePlan.GetProgrammesInTimeSpan(planningDay, 0, planningDay, 23)
		For local obj:TBroadcastMaterial = eachin daysProgramme
			if not obj then continue

			'if already included - skip it
			if GuiListProgrammes.ContainsBroadcastMaterial(obj) then continue

			'DAYCHANGE
			'skip programmes started yesterday (they are stored individually)
			if obj.programmedDay < planningDay and planningDay > 0
				'set to the obj still running at the begin of the planning day
				GuiListProgrammes.SetDayChangeBroadcastMaterial(obj, planningDay)
				continue
			endif

			'DRAGGED
			'check if we find it in the GuiManagers list of dragged items
			local foundInDragged:int = FALSE
			for local draggedGuiProgrammePlanElement:TGUIProgrammePlanElement = eachin GuiManager.ListDragged
				if draggedGuiProgrammePlanElement.broadcastMaterial = obj
					foundInDragged = TRUE
					continue
				endif
			Next
			if foundInDragged then continue

			'NORMAL MISSING
			if GuiListProgrammes.getFreeSlot() < 0
				print "[ERROR] ProgrammePlanner: should add programme but no empty slot left"
				continue
			endif

			local block:TGUIProgrammePlanElement = new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(obj)
			'print "ADD GuiListProgramme - missed new programme: "+obj.GetTitle() +" -> created block:"+block._id

			if not GuiListProgrammes.addItem(block, string(obj.programmedHour))
				print "ADD ERROR - could not add programme"
			else
				'set value so a dropped block will get the correct ghost image
				block.lastListType = GuiListProgrammes.isType
			endif
		Next


		'ad list (can contain ads, programmes, ...)
		local daysAdvertisements:TBroadcastMaterial[] = Game.getPlayer().ProgrammePlan.GetAdvertisementsInTimeSpan(planningDay, 0, planningDay, 23)
		For local obj:TBroadcastMaterial = eachin daysAdvertisements
			if not obj then continue

			'if already included - skip it
			if GuiListAdvertisements.ContainsBroadcastMaterial(obj) then continue

			'DAYCHANGE
			'skip programmes started yesterday (they are stored individually)
			if obj.programmedDay < planningDay and planningDay > 0
				'set to the obj still running at the begin of the planning day
				GuiListProgrammes.SetDayChangeBroadcastMaterial(obj, planningDay)
				continue
			endif

			'DRAGGED
			'check if we find it in the GuiManagers list of dragged items
			local foundInDragged:int = FALSE
			for local draggedGuiProgrammePlanElement:TGUIProgrammePlanElement = eachin GuiManager.ListDragged
				if draggedGuiProgrammePlanElement.broadcastMaterial = obj
					foundInDragged = TRUE
					continue
				endif
			Next
			if foundInDragged then continue

			'NORMAL MISSING
			if GuiListAdvertisements.getFreeSlot() < 0
				print "[ERROR] ProgrammePlanner: should add advertisement but no empty slot left"
				continue
			endif

			local block:TGUIProgrammePlanElement = new TGUIProgrammePlanElement.CreateWithBroadcastMaterial(obj, "programmePlanner")
			'print "ADD GuiListAdvertisements - missed new advertisement: "+obj.GetTitle()

			if not GuiListAdvertisements.addItem(block, string(obj.programmedHour))
				print "ADD ERROR - could not add advertisement"
			endif
		Next


		haveToRefreshGuiElements = FALSE
	End Function


	'add gfx to background
	Function InitProgrammePlannerBackground:int()
		Local roomImg:TImage				= Assets.GetSprite("screen_bg_pplanning").parent.image
		Local Pix:TPixmap					= LockImage(roomImg)
		Local gfx_ProgrammeBlock1:TImage	= Assets.GetSprite("pp_programmeblock1").GetImage()
		Local gfx_AdBlock1:TImage			= Assets.GetSprite("pp_adblock1").GetImage()

		'block"shade" on bg
		local shadeColor:TColor = TColor.CreateGrey(200, 0.3)
		For Local j:Int = 0 To 11
			DrawImageOnImage(gfx_Programmeblock1, Pix, 67 - 20, 17 - 10 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Programmeblock1, Pix, 394 - 20, 17 - 10 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Adblock1, Pix, 67 + ImageWidth(gfx_Programmeblock1) - 20, 17 - 10 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Adblock1, Pix, 394 + ImageWidth(gfx_Programmeblock1) - 20, 17 - 10 + j * 30, shadeColor)
		Next


		'set target for font
		TGW_BitmapFont.setRenderTarget(roomImg)

		local fontColor:TColor = TColor.CreateGrey(240)

		For Local i:Int = 0 To 11
			'left side
			Assets.fonts.baseFont.drawStyled( (i + 12) + ":00", 338, 18 + i * 30, fontColor, 2,1,0.25)
			'right side
			local text:string = i + ":00"
			If i < 10 then text = "0" + text
			Assets.fonts.baseFont.drawStyled(text, 10, 18 + i * 30, fontColor,2,1,0.25)
		Next
		DrawnOnProgrammePlannerBG = True

		'reset target for font
		TGW_BitmapFont.setRenderTarget(null)
	End Function



	'===== OFFICE FINANCIALS SCREEN =====

	'=== EVENTS ===

	Function onDrawFinancials:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		local finance:TPlayerFinance= Game.getPlayer(room.owner).GetFinance()
		local font13:TGW_BitmapFont	= Assets.GetFont("Default", 14, BOLDFONT)
		local font12:TGW_BitmapFont	= Assets.GetFont("Default", 11)

		local line:int = 14
		local fontColor:TColor = new TColor.CreateGrey(50)
		local fontColorLight:TColor = fontColor.copy().AdjustFactor(70)

		font13.drawBlock(GetLocale("FINANCES_OVERVIEW") 	,55, 235,330,20, null, fontColor)
		font13.drawBlock(GetLocale("FINANCES_COSTS")       ,55,  29,330,20, null, fontColor)
		font13.drawBlock(GetLocale("FINANCES_INCOME")      ,415, 29,330,20, null, fontColor)
		font13.drawBlock(GetLocale("FINANCES_MONEY_BEFORE"),415,129,330,20, null, fontColor)
		font13.drawBlock(GetLocale("FINANCES_MONEY_AFTER") ,415,193,330,20, null, fontColor)

		font12.drawBlock(GetLocale("FINANCES_SOLD_MOVIES")		,415, 48+line*0,330,20, null, fontColor)
		font12.drawBlock(GetLocale("FINANCES_AD_INCOME")		,415, 48+line*1,330,20, null, fontColorLight)
		font12.drawBlock(GetLocale("FINANCES_CALLER_REVENUE")	,415, 48+line*2,330,20, null, fontColor)
		font12.drawBlock(GetLocale("FINANCES_MISC_INCOME")		,415, 48+line*3,330,20, null, fontColorLight)
		font12.drawBlock(finance.income_programmeLicences+getLocale("CURRENCY")		,640, 48+line*0, 100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font12.drawBlock(finance.income_ads+getLocale("CURRENCY")		,640, 48+line*1, 100,20, TPoint.Create(ALIGN_RIGHT), fontColorLight)
		font12.drawBlock(finance.income_callerRevenue+getLocale("CURRENCY")	,640, 48+line*2, 100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font12.drawBlock(finance.income_misc+getLocale("CURRENCY")		,640, 48+line*3, 100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font13.drawBlock(finance.income_total+getLocale("CURRENCY")		,640, 48+line*4+5, 100,20, TPoint.Create(ALIGN_RIGHT), fontColor)

		font13.drawBlock(finance.revenue_before+getLocale("CURRENCY")	,640,129,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font12.drawBlock("+"											,415,148+line*0,10,20, TPoint.Create(ALIGN_CENTER), fontColor)
		font12.drawBlock("-"											,415,148+line*1,10,20, TPoint.Create(ALIGN_CENTER), fontColorLight)
		if finance.expense_creditInterest > finance.income_balanceInterest
			font12.drawBlock("-"											,415,148+line*2,10,20, TPoint.Create(ALIGN_CENTER), fontColor)
		else
			font12.drawBlock("+"											,415,148+line*2,10,20, TPoint.Create(ALIGN_CENTER), fontColor)
		endif
		font12.drawBlock(GetLocale("FINANCES_INCOME")		,425,148+line*0,150,20, null, fontColor)
		font12.drawBlock(GetLocale("FINANCES_COSTS")		,425,148+line*1,150,20, null, fontColorLight)
		font12.drawBlock(GetLocale("FINANCES_INTEREST")	,425,148+line*2,150,20, null, fontColor)

		font12.drawBlock(finance.income_total+getLocale("CURRENCY")		,640,148+line*0,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font12.drawBlock(finance.expense_total+getLocale("CURRENCY")		,640,148+line*1,100,20, TPoint.Create(ALIGN_RIGHT), fontColorLight)
		font12.drawBlock(abs(finance.expense_creditInterest - finance.income_balanceInterest) +getLocale("CURRENCY"),640,148+line*2,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font13.drawBlock(finance.revenue_after+getLocale("CURRENCY")	,640,193,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)

		font12.drawBlock(getLocale("FINANCES_BOUGHT_MOVIES")				,55, 49+line*0,330,20, null, fontColor)
		font12.drawBlock(getLocale("FINANCES_BOUGHT_STATIONS")				,55, 49+line*1,330,20, null, fontColorLight)
		font12.drawBlock(getLocale("FINANCES_SCRIPTS")						,55, 49+line*2,330,20, null, fontColor)
		font12.drawBlock(getLocale("FINANCES_ACTORS_STAGES")				,55, 49+line*3,330,20, null, fontColorLight)
		font12.drawBlock(getLocale("FINANCES_PENALTIES")					,55, 49+line*4,330,20, null, fontColor)
		font12.drawBlock(getLocale("FINANCES_STUDIO_RENT")					,55, 49+line*5,330,20, null, fontColorLight)
		font12.drawBlock(getLocale("FINANCES_NEWS")							,55, 49+line*6,330,20, null, fontColor)
		font12.drawBlock(getLocale("FINANCES_NEWSAGENCIES")					,55, 49+line*7,330,20, null, fontColorLight)
		font12.drawBlock(getLocale("FINANCES_STATION_COSTS")				,55, 49+line*8,330,20, null, fontColor)
		font12.drawBlock(getLocale("FINANCES_MISC_COSTS")					,55, 49+line*9,330,20, null, fontColorLight)
		font12.drawBlock(finance.expense_programmeLicences+getLocale("CURRENCY")			,280, 49+line*0,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font12.drawBlock(finance.expense_stations+getLocale("CURRENCY")		,280, 49+line*1,100,20, TPoint.Create(ALIGN_RIGHT), fontColorLight)
		font12.drawBlock(finance.expense_scripts+getLocale("CURRENCY")		,280, 49+line*2,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font12.drawBlock(finance.expense_productionstuff+getLocale("CURRENCY"),280, 49+line*3,100,20, TPoint.Create(ALIGN_RIGHT), fontColorLight)
		font12.drawBlock(finance.expense_penalty+getLocale("CURRENCY")		,280, 49+line*4,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font12.drawBlock(finance.expense_rent+getLocale("CURRENCY")            ,280, 49+line*5,100,20, TPoint.Create(ALIGN_RIGHT), fontColorLight)
		font12.drawBlock(finance.expense_news+getLocale("CURRENCY")            ,280, 49+line*6,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font12.drawBlock(finance.expense_newsagencies+getLocale("CURRENCY")    ,280, 49+line*7,100,20, TPoint.Create(ALIGN_RIGHT), fontColorLight)
		font12.drawBlock(finance.expense_stationfees+getLocale("CURRENCY")     ,280, 49+line*8,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)
		font12.drawBlock(finance.expense_misc+getLocale("CURRENCY")            ,280, 49+line*9,100,20, TPoint.Create(ALIGN_RIGHT), fontColorLight)
		font13.drawBlock(finance.expense_total+getLocale("CURRENCY")           ,280,193,100,20, TPoint.Create(ALIGN_RIGHT), fontColor)


		'==== DRAW MONEY CURVE====

		local showDays:int			= 30		'how much days to draw
		local curveArea:TRectangle	= TRectangle.Create(60,260, 500, 100) 'where to draw + dimension
		Local maxValue:int			= 0			'heighest reached money value of that days

		'first get the maximum value so we know how to scale the rest
		For local i:Int = Game.GetDay()-showDays To Game.GetDay()
			'skip if day is less than startday (saves calculations)
			if i < Game.GetStartDay() then continue

			For Local player:TPlayer = EachIn Game.Players
				maxValue = max(maxValue, player.GetFinance(i).money)
			Next
		Next

		'draw the labels and borders

		SetColor 200, 200, 200
		DrawLine(curveArea.GetX(),curveArea.GetY() , curveArea.GetY() + curveArea.GetW(), curveArea.GetY())
		DrawLine(curveArea.GetX(),curveArea.GetY() + 0.5*curveArea.GetH() , curveArea.GetX() + curveArea.GetW(), curveArea.GetY() + 0.5*curveArea.GetH())
		SetColor 255, 255, 255

		local slot:int				= 0
		local slotPos:TPoint		= TPoint.Create(0,0)
		local previousSlotPos:Tpoint= TPoint.Create(0,0)
		local slotWidth:int 		= curveArea.GetW() / showDays

		'draw the curves
		SetLineWidth(2)
		GlEnable(GL_LINE_SMOOTH)
		For Local player:TPlayer = EachIn Game.Players
			slot = 0
			slotPos.SetXY(0,0)
			previousSlotPos.SetXY(0,0)
			For local i:Int = Game.GetDay()-showDays To Game.GetDay()
				previousSlotPos.SetXY(slotPos.x, slotPos.y)
				slotPos.SetXY(slot * slotWidth, 0)
				'maximum is at 90% (so it is nicely visible)
				if maxValue > 0 then slotPos.SetY(curveArea.GetH() - Floor((player.GetFinance(i).money / float(maxvalue)) * curveArea.GetH()))
				if slotPos.y >= 0
					player.color.setRGB()
					SetAlpha 0.3
					DrawOval(curveArea.GetX() + slotPos.GetX()-3, curveArea.GetY() + slotPos.GetY()-3,6,6)
					SetAlpha 1.0
					if slot > 0
						DrawLine(curveArea.GetX() + previousSlotPos.GetX(), curveArea.GetY() + previousSlotPos.GetY(), curveArea.GetX() + slotPos.GetX(), curveArea.GetY() + slotPos.GetY())
						SetColor 255,255,255
					endif
				endif
				slot :+ 1
			Next
		Next
		SetLineWidth(1)

		'coord descriptor
		font12.drawBlock(TFunctions.convertValue(maxValue,2,0)       ,478-1 , 265+1,100,20, TPoint.Create(ALIGN_RIGHT), TColor.CreateGrey(180))
		font12.drawBlock(TFunctions.convertValue(Int(maxValue/2),2,0),478-1 , 315+1,100,20, TPoint.Create(ALIGN_RIGHT), TColor.CreateGrey(180))
	End Function


	Function onUpdateFinancials:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		'local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		'if not room then return 0

		Game.cursorstate = 0
	End Function



	'===== OFFICE IMAGE SCREEN =====


	Function onDrawImage:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		local fontColor:TColor = TColor.CreateGrey(50)
		Assets.GetFont("Default",13).drawBlock(GetLocale("IMAGE_REACH") , 55, 233, 330, 20, null, fontColor)
		Assets.GetFont("Default",12).drawBlock(GetLocale("IMAGE_SHARETOTAL") , 55, 45, 330, 20, null, fontColor)
		Assets.GetFont("Default",12).drawBlock(TFunctions.shortenFloat(100.0 * Game.GetPlayer(room.owner).GetStationMap().getCoverage(), 2) + "%", 280, 45, 93, 20, TPoint.Create(ALIGN_RIGHT), fontColor)
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

		'player enters station map screen - set checkboxes according to station map config
		EventManager.registerListenerFunction("screen.onEnter", onEnterStationMapScreen, ScreenCollection.GetScreen("screen_office_stationmap"))


		For Local i:Int = 0 To 3
			stationMapShowStations[i] = new TGUICheckBox.Create(TRectangle.Create(535, 30 + i * Assets.GetSprite("gfx_gui_ok_off").area.GetH()*GUIManager.globalScale, 20, 20), TRUE, String(i + 1), "STATIONMAP", Assets.GetFont("Default", 11, BOLDFONT))
			stationMapShowStations[i].SetShowValue(false)
			'register checkbox changes
			EventManager.registerListenerFunction("guiCheckBox.onSetChecked", OnSetChecked_StationMapFilters, stationMapShowStations[i])
		Next
	End Function


	Function onDrawStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		GUIManager.Draw("STATIONMAP")

		For Local i:Int = 0 To 3
			SetColor 100, 100, 100
			DrawRect(564, 32 + i * Assets.GetSprite("gfx_gui_ok_off").area.GetH()*GUIManager.globalScale, 15, 18)
			Game.Players[i + 1].color.SetRGB()
			DrawRect(565, 33 + i * Assets.GetSprite("gfx_gui_ok_off").area.GetH()*GUIManager.globalScale, 13, 16)
		Next
		SetColor 255, 255, 255
		Assets.fonts.baseFont.drawBlock(GetLocale("SHOW_PLAYERS")+":", 480, 15, 100, 20, TPoint.Create(ALIGN_RIGHT))

		'draw stations and tooltips
		Game.GetPlayer(room.owner).GetStationMap().Draw()

		'also draw the station used for buying/searching
		If stationMapMouseoverStation then stationMapMouseoverStation.Draw()
		'also draw the station used for buying/searching
		If stationMapSelectedStation then stationMapSelectedStation.Draw(true)

		local font:TGW_BitmapFont = Assets.fonts.baseFont
		Assets.fonts.baseFontBold.drawStyled(GetLocale("PURCHASE"), 595, 18, TColor.clBlack, 1, 1, 0.5)
		Assets.fonts.baseFontBold.drawStyled(GetLocale("YOUR_STATIONS"), 595, 178, TColor.clBlack, 1, 1, 0.5)

		'draw a kind of tooltip over a mouseoverStation
		if stationMapMouseoverStation then stationMapMouseoverStation.DrawInfoTooltip()

		If stationMapMode = 1 and stationMapSelectedStation
			Assets.fonts.baseFontBold.draw( getLocale("MAP_COUNTRY_"+stationMapSelectedStation.getFederalState()), 595, 37, TColor.Create(80,80,0))

			font.draw(GetLocale("RANGE")+": ", 595, 55, TColor.clBlack)
			font.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getReach(), 2), 660, 55, 102, 20, TPoint.Create(ALIGN_RIGHT), TColor.clBlack)

			font.draw(GetLocale("INCREASE")+": ", 595, 72)
			font.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getReachIncrease(), 2), 660, 72, 102, 20, TPoint.Create(ALIGN_RIGHT), TColor.clBlack)

			font.draw(GetLocale("PRICE")+": ", 595, 89)
			Assets.fonts.baseFontBold.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getPrice(), 2, 0), 660, 89, 102, 20, TPoint.Create(ALIGN_RIGHT), TColor.clBlack)
			SetColor(255,255,255)
		EndIf

		If stationMapSelectedStation and stationMapSelectedStation.paid
			font.draw(GetLocale("RANGE")+": ", 595, 200, TColor.clBlack)
			font.drawBlock(TFunctions.convertValue(stationMapSelectedStation.reach, 2, 0), 660, 200, 102, 20, TPoint.Create(ALIGN_RIGHT), TColor.clBlack)

			font.draw(GetLocale("VALUE")+": ", 595, 216, TColor.clBlack)
			Assets.fonts.baseFontBold.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getSellPrice(), 2, 0), 660, 215, 102, 20, TPoint.Create(ALIGN_RIGHT), TColor.clBlack)
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

		Game.GetPlayer(room.owner).GetStationMap().Update()

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
			if not StationMapMouseoverStation then StationMapMouseoverStation = TStationMap.getStationMap(room.owner).getTemporaryStation( MouseManager.x, MouseManager.y )
			local mousePos:TPoint = TPoint.Create( MouseManager.x, MouseManager.y)

			'if the mouse has moved - refresh the station data and move station
			if not StationMapMouseoverStation.pos.isSame( mousePos )
				StationMapMouseoverStation.pos.SetPos(mousePos)
				StationMapMouseoverStation.refreshData()
				'refresh state information
				StationMapMouseoverStation.getFederalState(true)
			endif

			'if mouse gets clicked, we store that position in a separate station
			if MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				if StationMapMouseoverStation.GetHoveredMapSection() and StationMapMouseoverStation.getReach()>0
					StationMapSelectedStation = TStationMap.getStationMap(room.owner).getTemporaryStation( StationMapMouseoverStation.pos.x, StationMapMouseoverStation.pos.y )
				endif
			endif

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			if StationMapMouseoverStation.getReach() <= 0 or not StationMapMouseoverStation.GetHoveredMapSection() then StationMapMouseoverStation = null

			if StationMapSelectedStation
				if StationMapSelectedStation.getReach() <= 0 or not StationMapSelectedStation.GetHoveredMapSection() then StationMapSelectedStation = null
			endif
		endif

		GUIManager.Update("STATIONMAP")
	End Function


	Function OnChangeStationMapStation:int( triggerEvent:TEventBase )
		if not currentSubRoom then return FALSE
		'do nothing when not in a roomy

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

		'ignore clicks if not in the own office
		if Game.GetPlayer().figure.inRoom.owner <> Game.GetPlayer().playerID then return FALSE

		if stationMapMode=1
			button.value = GetLocale("CONFIRM_PURCHASE")
		else
			button.value = GetLocale("BUY_STATION")
		endif
	End Function

	Function OnClick_StationMapBuy:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if Game.GetPlayer().figure.inRoom.owner <> Game.GetPlayer().playerID then return FALSE

		'coming from somewhere else... reset first
		if stationMapMode<>1 then ResetStationMapAction(1)

		If stationMapSelectedStation and stationMapSelectedStation.getReach() > 0
			'add the station (and buy it)
			if Game.GetPlayer().GetStationMap().AddStation(stationMapSelectedStation, TRUE)
				ResetStationMapAction(0)
			endif
		EndIf
	End Function


	Function OnClick_StationMapSell:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if Game.GetPlayer().figure.inRoom.owner <> Game.GetPlayer().playerID then return FALSE

		'coming from somewhere else... reset first
		if stationMapMode<>2 then ResetStationMapAction(2)

		If stationMapSelectedStation and stationMapSelectedStation.getReach() > 0
			'remove the station (and sell it)
			if Game.GetPlayer().GetStationMap().RemoveStation(stationMapSelectedStation, TRUE)
				ResetStationMapAction(0)
			endif
		EndIf
	End Function

	'enables/disables the button depending on selection
	'sets button label depending on userAction
	Function OnUpdate_StationMapSell:int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if Game.GetPlayer().figure.inRoom.owner <> Game.GetPlayer().playerID then return FALSE

		'noting selected yet
		if not stationMapSelectedStation then return FALSE

		'different owner or not paid
		if stationMapSelectedStation.owner <> Game.playerID or not stationMapSelectedStation.paid
			button.disable()
		else
			button.enable()
		endif

		if stationMapMode=2
			button.value = GetLocale("CONFIRM_SALE")
		else
			button.value = GetLocale("SELL_STATION")
		endif
	End Function


	'rebuild the stationList - eg. when changed the room (other office)
	Function RefreshStationMapStationList(playerID:int=-1)
		If playerID <= 0 Then playerID = Game.playerID

		'first fill of stationlist
		stationList.EmptyList()
		'remove potential highlighted item
		stationList.deselectEntry()

		For Local station:TStation = EachIn Game.GetPlayer(playerID).GetStationMap().Stations
			local item:TGUISelectListItem = new TGUISelectListItem.Create(GetLocale("STATION")+" (" + TFunctions.convertValue(station.reach, 2, 0) + ")",0,0,100,20)
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


	'set checkboxes according to stationmap config
	Function onEnterStationMapScreen:int(triggerEvent:TEventBase)
		'only players can "enter screens" - so just use "inRoom"

		For local i:int = 0 to 3
			local show:int = TStationMap.GetStationMap(Game.GetPlayer().figure.inRoom.owner).showStations[i]
			stationMapShowStations[i].SetChecked(show)
		Next
	End Function


	Function OnSetChecked_StationMapFilters:int(triggerEvent:TEventBase)
		Local button:TGUICheckBox = TGUICheckBox(triggerEvent._sender)
		if not button then return FALSE

		'ignore clicks if not in the own office
		if Game.GetPlayer().figure.inRoom.owner <> Game.GetPlayer().playerID then return FALSE

		local player:int = int(button.value)
		if not Game.IsPlayer(player) then return FALSE

		'only set if not done already
		if Game.GetPlayer().GetStationMap().showStations[player-1] <> button.isChecked()
			TDevHelper.Log("StationMap", "show stations for player "+player+": "+button.isChecked(), LOG_DEBUG)
			Game.GetPlayer().GetStationMap().showStations[player-1] = button.isChecked()
		endif
	End Function
End Type



'Archive: handling of players programmearchive - for selling it later, ...
Type RoomHandler_Archive extends TRoomHandler
	Global hoveredGuiProgrammeLicence:TGuiProgrammeLicence = null
	Global draggedGuiProgrammeLicence:TGuiProgrammeLicence = null

	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListSuitcase:TGUIProgrammeLicenceSlotList = null
	Global DudeArea:TGUISimpleRect	'allows registration of drop-event

	'configuration
	Global suitcasePos:TPoint				= TPoint.Create(40,270)
	Global suitcaseGuiListDisplace:TPoint	= TPoint.Create(14,25)


	Function Init()
		'===== CREATE GUI LISTS =====
		GuiListSuitcase	= new TGUIProgrammeLicenceSlotList.Create(suitcasePos.GetX()+suitcaseGuiListDisplace.GetX(),suitcasePos.GetY()+suitcaseGuiListDisplace.GetY(),200,80, "archive")
		GuiListSuitcase.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.acceptType		= TGUIProgrammeLicenceSlotList.acceptAll
		GuiListSuitcase.SetItemLimit(Game.maxProgrammeLicencesInSuitcase)
		GuiListSuitcase.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").area.GetW(), Assets.GetSprite("gfx_movie0").area.GetH())
		GuiListSuitcase.SetAcceptDrop("TGUIProgrammeLicence")

		DudeArea = new TGUISimpleRect.Create(TRectangle.Create(600,100, 200, 350), "archive" )
		'dude should accept drop - else no recognition
		DudeArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)


		'===== REGISTER EVENTS =====
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "guiGameObject.OnMouseOver", onMouseOverProgrammeLicence, "TGUIProgrammeLicence" )
		'drop programme ... so sell/buy the thing
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropProgrammeLicence, "TGUIProgrammeLicence" )
		'drop programme on dude - add back to player's collection
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropProgrammeLicenceOnDude, "TGUIProgrammeLicence" )
		'check right clicks on a gui block
		EventManager.registerListenerFunction( "guiobject.onClick", onClickProgrammeLicence, "TGUIProgrammeLicence" )

		'register self for all archives-rooms
		For local i:int = 1 to 4
			local room:TRooms = TRooms.GetRoomByDetails("archive", i)
			if room then super._RegisterHandler(onUpdate, onDraw, room)

			'figure enters room - reset the suitcase's guilist, limit listening to the 4 rooms
			EventManager.registerListenerFunction( "room.onEnter", onEnterRoom, TRooms.GetRoomByDetails("archive",i) )
			EventManager.registerListenerFunction( "room.onTryLeave", onTryLeaveRoom, TRooms.GetRoomByDetails("archive",i) )
			EventManager.registerListenerFunction( "room.onLeave", onLeaveRoom, TRooms.GetRoomByDetails("archive",i) )
		Next

		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
	End Function


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'for further explanation of this, check
		'RoomHandler_Office.onSaveGameBeginLoad()

		hoveredGuiProgrammeLicence = null
		draggedGuiProgrammeLicence = null
		GuiListSuitcase.EmptyList()

		haveToRefreshGuiElements = true
	End Function


	Function onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammeLicence
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function


	'remove suitcase licences from a players programme plan
	Function onLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayerID then return FALSE
rem
		Game.GetPlayer(figure.parentPlayerID).ProgrammeCollection.ReaddProgrammeLicencesFromSuitcase()

		'fill all open slots in the agency
		ReFillBlocks()
endrem
		return TRUE
	End Function



	Function CheckPlayerInRoom:int()
		'check if we are in the correct room
		if not Game.getPlayer().figure.inRoom then return FALSE
		if Game.getPlayer().figure.inRoom.name <> "archive" then return FALSE

		return TRUE
	End Function



	Function RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with licences the player does not have any
		'longer in the suitcase

		'suitcase
		For local guiLicence:TGUIProgrammeLicence = eachin GuiListSuitcase._slots
			'if the player has this licence in suitcase, skip deletion
			if Game.getPlayer().ProgrammeCollection.HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
		Next

		'===== CREATE NEW =====
		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin Game.getPlayer().ProgrammeCollection.suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem(new TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
			'print "ADD suitcase had missing licence: "+licence.getTitle()
		Next

		haveToRefreshGuiElements = FALSE
	End Function



	'in case of right mouse button click we want to add back the
	'dragged block to the player's programmeCollection
	Function onClickProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiBlock or not guiBlock.isDragged() then return FALSE

		'add back to collection if already dropped it to suitcase before
		if not Game.GetPlayer().programmeCollection.HasProgrammeLicence(guiBlock.licence)
			Game.GetPlayer().programmeCollection.RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
		endif
		'remove the gui element
		guiBlock.remove()
		guiBlock = null

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	'normally we should split in two parts:
	' OnDrop - check money etc, veto if needed
	' OnDropAccepted - do all things to finish the action
	'but this should be kept simple...
	Function onDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiBlock or not receiverList then return FALSE

		local owner:int = guiBlock.licence.owner

		select receiverList
			case GuiListSuitcase
				'check if still in collection - if so, remove
				'from collection and add to suitcase
				if Game.GetPlayer().programmeCollection.HasProgrammeLicence(guiBlock.licence)
					'remove gui - a new one will be generated automatically
					'as soon as added to the suitcase and the room's update
					guiBlock.remove()

					'if not able to add to suitcase (eg. full), cancel
					'the drop-event
					if not Game.GetPlayer().programmeCollection.AddProgrammeLicenceToSuitcase(guiBlock.licence)
						triggerEvent.setVeto()
					endif
				endif

				'else it is just a "drop back"
				return TRUE
		end select

		return TRUE
	End Function


	'handle cover block drops on the dude
	Function onDropProgrammeLicenceOnDude:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver then return FALSE
		if receiver <> DudeArea then return FALSE

		'add back to collection
		Game.GetPlayer().programmeCollection.RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
		'remove the gui element
		guiBlock.remove()
		guiBlock = null

		return TRUE
	End function


	Function onMouseOverProgrammeLicence:int( triggerEvent:TEventBase )
		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProgrammeLicence = item
		if item.isDragged()
			draggedGuiProgrammeLicence = item
			'if we have an item dragged... we cannot have a menu open
			ArchiveprogrammeList.SetOpen(0)
		endif

		return TRUE
	End Function


	'clear the guilist for the suitcase if a player enters
	Function onEnterRoom:int( triggerEvent:TEventBase )
		'we are not interested in other figures than our player's
		local figure:TFigure = TFigure(triggerEvent.GetData().Get("figure"))
		if not figure or not figure.IsActivePlayer() then return FALSE

		'empty the guilist / delete gui elements
		'- the real list still may contain elements with gui-references
		guiListSuitcase.EmptyList()
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0
		if room.owner <> Game.playerID then return FALSE

		ArchiveprogrammeList.Draw()

		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		if draggedGuiProgrammeLicence then glowSuitcase = "_glow"
		'draw suitcase
		Assets.GetSprite("gfx_suitcase"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		GUIManager.Draw("archive")

		'show sheet from hovered list entries
		if ArchiveprogrammeList.hoveredLicence
			ArchiveprogrammeList.hoveredLicence.ShowSheet(30,20)
		endif
		'show sheet from hovered suitcase entries
		if hoveredGuiProgrammeLicence
			'draw the current sheet
			hoveredGuiProgrammeLicence.DrawSheet()
		endif
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		if room.owner <> game.playerID then return FALSE

		Game.cursorstate = 0

		'open list when clicking dude
		if not draggedGuiProgrammeLicence
			If ArchiveProgrammeList.GetOpen() = 0
				if TFunctions.IsIn(MouseManager.x, MouseManager.y, 605,65,120,90) Or TFunctions.IsIn(MouseManager.x, MouseManager.y, 525,155,240,225)
					Game.cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						Game.cursorstate = 0
						ArchiveProgrammeList.SetOpen(1)
					endif
				EndIf
			endif
			ArchiveprogrammeList.enabled = TRUE
		else
			'disable list if we have a dragged guiobject
			ArchiveprogrammeList.enabled = FALSE
		endif
		ArchiveprogrammeList.Update(TgfxProgrammelist.MODE_ARCHIVE)

		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin Game.getPlayer().ProgrammeCollection.suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem( new TGuiProgrammeLicence.CreateWithLicence(licence),"-1" )
		Next

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then RefreshGUIElements()


		'reset hovered block - will get set automatically on gui-update
		hoveredGuiProgrammeLicence = null
		'reset dragged block too
		draggedGuiProgrammeLicence = null

		GUIManager.Update("archive")

	End Function
End Type


'Movie agency
Type RoomHandler_MovieAgency extends TRoomHandler
	Global twinkerTimer:TIntervalTimer = TIntervalTimer.Create(6000,250)
	Global AuctionToolTip:TTooltip

	Global VendorArea:TGUISimpleRect	'allows registration of drop-event

	Global hoveredGuiProgrammeLicence:TGUIProgrammeLicence = null
	Global draggedGuiProgrammeLicence:TGUIProgrammeLicence = null

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listMoviesGood:TProgrammeLicence[]
	Field listMoviesCheap:TProgrammeLicence[]
	Field listSeries:TProgrammeLicence[]

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListMoviesGood:TGUIProgrammeLicenceSlotList = null
	Global GuiListMoviesCheap:TGUIProgrammeLicenceSlotList = null
	Global GuiListSeries:TGUIProgrammeLicenceSlotList = null
	Global GuiListSuitcase:TGUIProgrammeLicenceSlotList = null

	'configuration
	Global suitcasePos:TPoint				= TPoint.Create(350,130)
	Global suitcaseGuiListDisplace:TPoint	= TPoint.Create(14,25)
	Field programmesPerLine:int			= 12
	Field movieCheapMaximum:int			= 50000

	Global _instance:RoomHandler_MovieAgency
	Global _initDone:int = FALSE


	Function GetInstance:RoomHandler_MovieAgency()
		if not _instance then _instance = new RoomHandler_MovieAgency
		if not _initDone then _instance.Init()
		return _instance
	End Function


	Method Init:int()
		if _initDone then return FALSE

		'resize arrays
		listMoviesGood	= listMoviesGood[..programmesPerLine]
		listMoviesCheap	= listMoviesCheap[..programmesPerLine]
		listSeries		= listSeries[..programmesPerLine]

		GuiListMoviesGood	= new TGUIProgrammeLicenceSlotList.Create(596,50,200,80, "movieagency")
		GuiListMoviesCheap	= new TGUIProgrammeLicenceSlotList.Create(596,148,200,80, "movieagency")
		GuiListSeries		= new TGUIProgrammeLicenceSlotList.Create(596,246,200,80, "movieagency")
		GuiListSuitcase		= new TGUIProgrammeLicenceSlotList.Create(suitcasePos.GetX()+suitcaseGuiListDisplace.GetX(),suitcasePos.GetY()+suitcaseGuiListDisplace.GetY(),200,80, "movieagency")

		GuiListMoviesGood.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListMoviesCheap.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSeries.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSuitcase.guiEntriesPanel.minSize.SetXY(200,80)

		GuiListMoviesGood.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListMoviesCheap.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSeries.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

		GuiListMoviesGood.acceptType	= TGUIProgrammeLicenceSlotList.acceptMovies
		GuiListMoviesCheap.acceptType	= TGUIProgrammeLicenceSlotList.acceptMovies
		GuiListSeries.acceptType		= TGUIProgrammeLicenceSlotList.acceptSeries
		GuiListSuitcase.acceptType		= TGUIProgrammeLicenceSlotList.acceptAll

		GuiListMoviesGood.SetItemLimit(listMoviesGood.length)
		GuiListMoviesCheap.SetItemLimit(listMoviesCheap.length)
		GuiListSeries.SetItemLimit(listSeries.length)
		GuiListSuitcase.SetItemLimit(Game.maxProgrammeLicencesInSuitcase)

		GuiListMoviesGood.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").area.GetW(), Assets.GetSprite("gfx_movie0").area.GetH())
		GuiListMoviesCheap.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").area.GetW(), Assets.GetSprite("gfx_movie0").area.GetH())
		GuiListSeries.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").area.GetW(), Assets.GetSprite("gfx_movie0").area.GetH())
		GuiListSuitcase.SetSlotMinDimension(Assets.GetSprite("gfx_movie0").area.GetW(), Assets.GetSprite("gfx_movie0").area.GetH())

		GuiListMoviesGood.SetAcceptDrop("TGUIProgrammeLicence")
		GuiListMoviesCheap.SetAcceptDrop("TGUIProgrammeLicence")
		GuiListSeries.SetAcceptDrop("TGUIProgrammeLicence")
		GuiListSuitcase.SetAcceptDrop("TGUIProgrammeLicence")

		VendorArea = new TGUISimpleRect.Create(TRectangle.Create(20,60, Assets.GetSprite("gfx_hint_rooms_movieagency").area.GetW(), Assets.GetSprite("gfx_hint_rooms_movieagency").area.GetH()), "movieagency" )
		'vendor should accept drop - else no recognition
		VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)

		'drop ... so sell/buy the thing
		EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammeLicence, "TGUIProgrammeLicence" )
		EventManager.registerListenerFunction("guiobject.onDropOnTarget", onDropProgrammeLicence, "TGUIProgrammeLicence")
		'is dragging even allowed? - eg. intercept if not enough money
		EventManager.registerListenerFunction("guiobject.onDrag", onDragProgrammeLicence, "TGUIProgrammeLicence")
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction("guiGameObject.OnMouseOver", onMouseOverProgrammeLicence, "TGUIProgrammeLicence")
		'drop on vendor - sell things
		EventManager.registerListenerFunction("guiobject.onDropOnTarget", onDropProgrammeLicenceOnVendor, "TGUIProgrammeLicence")
		'figure enters room - reset the suitcase's guilist, limit listening to this room
		EventManager.registerListenerFunction("room.onEnter", onEnterRoom, TRooms.GetRoomByDetails("movieagency",0))
		'figure leaves room - only without dragged blocks
		EventManager.registerListenerFunction("room.onTryLeave", onTryLeaveRoom, TRooms.GetRoomByDetails("movieagency",0))
		EventManager.registerListenerFunction("room.onLeave", onLeaveRoom, TRooms.GetRoomByDetails("movieagency",0))

		super._RegisterScreenHandler( onUpdateMovieAgency, onDrawMovieAgency, ScreenCollection.GetScreen("screen_movieagency"))
		super._RegisterScreenHandler( onUpdateMovieAuction, onDrawMovieAuction, ScreenCollection.GetScreen("screen_movieauction"))

		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)

		_initDone = true
	End Method


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new programmes are not loaded yet

		GetInstance().RemoveAllGuiElements()
		haveToRefreshGuiElements = true
	End Function


	'clear the guilist for the suitcase if a player enters
	Function onEnterRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent.GetSender())
		local figure:TFigure = TFigure(triggerEvent.GetData().Get("figure"))
		if not room or not figure then return FALSE

		'we are not interested in other figures than our player's
		if not figure.IsActivePlayer() then return FALSE

		GetInstance().RemoveAllGuiElements()
		GetInstance().RefreshGUIElements()
	End Function


	Function onTryLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammeLicence
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
		local figure:TFigure = TFigure(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayerID then return FALSE

		Game.GetPlayer(figure.parentPlayerID).ProgrammeCollection.ReaddProgrammeLicencesFromSuitcase()

		'fill all open slots in the agency
		GetInstance().ReFillBlocks()

		return TRUE
	End Function


	'===================================
	'Movie Agency: common TFunctions
	'===================================

	Method GetProgrammeLicencesInStock:int()
		Local ret:Int = 0
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence Then ret:+1
			Next
		Next
		return ret
	End Method


	Method GetProgrammeLicenceByPosition:TProgrammeLicence(position:int)
		if position > GetProgrammeLicencesInStock() then return null
		local currentPosition:int = 0
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence
					if currentPosition = position then return licence
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Method


	Method HasProgrammeLicence:int(licence:TProgrammeLicence)
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local listLicence:TProgrammeLicence = EachIn lists[j]
				if listLicence= licence then return TRUE
			Next
		Next
		return FALSE
	End Method


	Method GetProgrammeLicenceByID:TProgrammeLicence(licenceID:int)
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence and licence.id = licenceID then return licence
			Next
		Next
		return null
	End Method


	Method SellProgrammeLicenceToPlayer:int(licence:TProgrammeLicence, playerID:int)
		if licence.owner = playerID then return FALSE

		if not Game.isPlayer(playerID) then return FALSE

		'try to add to suitcase of player
		if not Game.getPlayer(playerID).ProgrammeCollection.AddProgrammeLicenceToSuitcase(licence)
			return FALSE
		endif

		'remove from agency's lists
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = licence then lists[j][i] = null
			Next
		Next

		return TRUE
	End Method


	Method BuyProgrammeLicenceFromPlayer:int(licence:TProgrammeLicence)
		local buy:int = (licence.owner > 0)

		'remove from player (lists and suitcase) - and give him money
		if Game.isPlayer(licence.owner)
			Game.getPlayer(licence.owner).ProgrammeCollection.RemoveProgrammeLicence(licence, TRUE)
		endif

		'add to agency's lists - if not existing yet
		if not HasProgrammeLicence(licence) then AddProgrammeLicence(licence)

		return TRUE
	End Method


	Method AddProgrammeLicence:int(licence:TProgrammeLicence)
		'try to fill the licence into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TProgrammeLicence[][]

		'do not add episodes
		if licence.isEpisode()
			licence.owner = 0
			return FALSE
		endif

		if licence.isMovie() or licence.isCollection()
			if licence.getPrice() < movieCheapMaximum
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
				licence.owner = -1
				lists[j][i] = licence
				'print "added licence "+licence.title+" to list "+j+" at spot:"+i
				return TRUE
			Next
		Next

		'there was no empty slot to place that licence
		'so just give it back to the pool
		licence.owner = 0

		return FALSE
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Method RemoveAllGuiElements:int()
		GuiListMoviesGood.EmptyList()
		GuiListMoviesCheap.EmptyList()
		GuiListSeries.EmptyList()
		GuiListSuitcase.EmptyList()

		For local guiLicence:TGUIProgrammeLicence = eachin GuiManager.listDragged
			guiLicence.remove()
		Next

		hoveredGuiProgrammeLicence = null
		draggedGuiProgrammeLicence = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Method


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with movies the player does not have any
		'longer in the suitcase

		'suitcase
		For local guiLicence:TGUIProgrammeLicence = eachin GuiListSuitcase._slots
			'if the player has this licence in suitcase, skip deletion
			if Game.getPlayer().ProgrammeCollection.HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
		Next
		'agency lists
		local lists:TProgrammeLicence[][]				= [	listMoviesGood,listMoviesCheap,listSeries ]
		local guiLists:TGUIProgrammeLicenceSlotList[]	= [	guiListMoviesGood, guiListMoviesCheap, guiListSeries ]
		For local j:int = 0 to guiLists.length-1
			For local guiLicence:TGUIProgrammeLicence = eachin guiLists[j]._slots
				if HasProgrammeLicence(guiLicence.licence) then continue

				'print "REM lists"+j+" has obsolete licence: "+guiLicence.licence.getTitle()
				guiLicence.remove()
			Next
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all programme-lists

		For local j:int = 0 to lists.length-1
			For local licence:TProgrammeLicence = eachin lists[j]
				if not licence then continue
				if guiLists[j].ContainsLicence(licence) then continue
				guiLists[j].addItem(new TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
				'print "ADD lists"+j+" had missing licence: "+licence.getTitle()
			Next
		Next
		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin Game.getPlayer().ProgrammeCollection.suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem(new TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
			'print "ADD suitcase had missing licence: "+licence.getTitle()
		Next

		haveToRefreshGuiElements = FALSE
	End Method


	'refills slots in the movie agency
	'replaceOffer: remove (some) old programmes and place new there?
	Method RefillBlocks:Int(replaceOffer:int=FALSE, replaceChance:float=1.0)
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		local licence:TProgrammeLicence = null

		haveToRefreshGuiElements = TRUE

		'delete some random movies/series
		if replaceOffer
			for local j:int = 0 to lists.length-1
				for local i:int = 0 to lists[j].length-1
					if not lists[j][i] then continue
					'delete an old movie by a chance of 50%
					if RandRange(0,100) < replaceChance*100
						'reset owner
						lists[j][i].owner = 0
						'unlink from this list
						lists[j][i] = null
					endif
				Next
			Next
		endif


		for local j:int = 0 to lists.length-1
			local warnedOfMissingLicence:int = FALSE
			for local i:int = 0 to lists[j].length-1
				'if exists...skip it
				if lists[j][i] then continue

				if lists[j] = listMoviesGood then licence = TProgrammeLicence.GetRandomWithPrice(75000,-1, TProgrammeLicence.TYPE_MOVIE)
				if lists[j] = listMoviesCheap then licence = TProgrammeLicence.GetRandomWithPrice(0,75000, TProgrammeLicence.TYPE_MOVIE)
				if lists[j] = listSeries then licence = TProgrammeLicence.GetRandom(TProgrammeLicence.TYPE_SERIES)

				'add new licence at slot
				if licence
					licence.owner = -1
					lists[j][i] = licence
				else
					if not warnedOfMissingLicence
						TDevHelper.log("MovieAgency.RefillBlocks()", "Not enough licences to refill slot["+i+"+] in list["+j+"]", LOG_WARNING | LOG_DEBUG)
						warnedOfMissingLicence = TRUE
					endif
				endif
			Next
		Next
	End Method


	Function CheckPlayerInRoom:int()
		'check if we are in the correct room
		if not Game.getPlayer().figure.inRoom then return FALSE
		if Game.getPlayer().figure.inRoom.name <> "movieagency" then return FALSE

		return TRUE
	End Function



	'===================================
	'Movie Agency: Room screen
	'===================================


	Function onMouseOverProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProgrammeLicence = item
		if item.isDragged() then draggedGuiProgrammeLicence = item

		return TRUE
	End Function


	'check if we are allowed to drag that licence
	Function onDragProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		local owner:int = item.licence.owner

		'do not allow dragging items from other players
		if owner > 0 and owner <> Game.playerID
			triggerEvent.setVeto()
			return FALSE
		endif

		'check whether a player could afford the licence
		'if not - just veto the event so it does not get dragged
		if owner <= 0
			if not Game.getPlayer().getFinance().canAfford(item.licence.getPrice())
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Function


	'- check if dropping on suitcase and affordable
	'- check if dropping on an item which is not affordable
	Function onTryDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiLicence or not receiverList then return FALSE

		local owner:int = guiLicence.licence.owner

		select receiverList
			case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'check if something is underlaying and whether the
				'player could afford it
				local underlayingItem:TGUIProgrammeLicence = null
				local coord:TPoint = TPoint(triggerEvent.getData().get("coord", TPoint.Create(-1,-1)))
				if coord then underlayingItem = TGUIProgrammeLicence(receiverList.GetItemByCoord(coord))

				'allow drop on own place
				if underlayingItem = guiLicence then return TRUE

				if underlayingItem and not Game.getPlayer().getFinance().canAfford(underlayingItem.licence.getPrice())
					triggerEvent.SetVeto()
					return FALSE
				endif
			case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				if guiLicence.licence.owner = Game.playerID then return TRUE

				if not Game.getPlayer().getFinance().canAfford(guiLicence.licence.getPrice())
					triggerEvent.setVeto()
				endif
		End select

		return TRUE
	End Function


	'dropping takes place - sell/buy licences or veto if not possible
	Function onDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiLicence or not receiverList then return FALSE

		local owner:int = guiLicence.licence.owner

		select receiverList
			case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'when dropping vendor licence on vendor shelf .. no prob
				if guiLicence.licence.owner <= 0 then return true

				if not GetInstance().BuyProgrammeLicenceFromPlayer(guiLicence.licence)
					triggerEvent.setVeto()
					return FALSE
				endif
			case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				if guiLicence.licence.owner = Game.playerID then return TRUE

				if not GetInstance().SellProgrammeLicenceToPlayer(guiLicence.licence, Game.playerID)
					triggerEvent.setVeto()
					'try to drop back to old list - which triggers
					'this function again... but with a differing list..
					guiLicence.dropBackToOrigin()
					haveToRefreshGuiElements = TRUE
				endif
		end select

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropProgrammeLicenceOnVendor:int(triggerEvent:TEventBase)
		if not CheckPlayerInRoom() then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiLicence or not receiver then return FALSE
		if receiver <> VendorArea then return FALSE

		'do not accept blocks from the vendor itself
		if guiLicence.licence.owner <=0
			triggerEvent.setVeto()
			return FALSE
		endif

		if not GetInstance().BuyProgrammeLicenceFromPlayer(guiLicence.licence)
			triggerEvent.setVeto()
			return FALSE
		else
			'successful - delete that gui block
			guiLicence.remove()
			'remove the whole block too
			guiLicence = null
		endif

		return TRUE
	End function


	Function onDrawMovieAgency:int( triggerEvent:TEventBase )
		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		local glowVendor:string = ""
		if draggedGuiProgrammeLicence
			if draggedGuiProgrammeLicence.licence.owner <= 0
				glowSuitcase = "_glow"
			else
				glowVendor = "_glow"
			endif
		endif

		'let the vendor glow if over auction hammer
		'or if a player's block is dragged
		if not draggedGuiProgrammeLicence
			If TFunctions.IsIn(MouseManager.x, MouseManager.y, 210,220,140,60)
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
		local fontColor:TColor = TColor.CreateGrey(50)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock(GetLocale("MOVIES"),		642,  27+3, 108,20, TPoint.Create(ALIGN_CENTER), fontColor)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock(GetLocale("SPECIAL_BIN"),	642, 125+3, 108,20, TPoint.Create(ALIGN_CENTER), fontColor)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock(GetLocale("SERIES"), 		642, 223+3, 108,20, TPoint.Create(ALIGN_CENTER), fontColor)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")

		if hoveredGuiProgrammeLicence
			'draw the current sheet
			hoveredGuiProgrammeLicence.DrawSheet()
		endif


		If AuctionToolTip Then AuctionToolTip.Draw()
	End Function


	Function onUpdateMovieAgency:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.cursorstate = 0

		'if we have a licence dragged ... we should take care of "ESC"-Key
		if draggedGuiProgrammeLicence
			if KeyManager.IsHit(KEY_ESCAPE)
				draggedGuiProgrammeLicence.dropBackToOrigin()
				draggedGuiProgrammeLicence = null
				hoveredGuiProgrammeLicence = null
			endif
		endif


		'show a auction-tooltip (but not if we dragged a block)
		if not hoveredGuiProgrammeLicence
			If TFunctions.IsIn(MouseManager.x, MouseManager.y, 210,220,140,60)
				If not AuctionToolTip Then AuctionToolTip = TTooltip.Create(GetLocale("AUCTION"), GetLocale("MOVIES_AND_SERIES_AUCTION"), 200, 180, 0, 0)
				AuctionToolTip.enabled = 1
				AuctionToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0
					ScreenCollection.GoToSubScreen("screen_movieauction")
				endif
			EndIf
		endif

		If twinkerTimer.isExpired() then twinkerTimer.Reset()

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiProgrammeLicence = null
		'reset dragged block too
		draggedGuiProgrammeLicence = null

		GUIManager.Update("movieagency")

		If AuctionToolTip Then AuctionToolTip.Update( App.timer.getDelta() )
	End Function



	'===================================
	'Movie Agency: Room screen
	'===================================

	Function onDrawMovieAuction:int( triggerEvent:TEventBase )
		Assets.GetSprite("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		SetAlpha 0.5
		local fontColor:TColor = TColor.CreateGrey(50)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock(GetLocale("MOVIES"),		642,  27+3, 108,20, TPoint.Create(ALIGN_CENTER), fontColor)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock(GetLocale("SPECIAL_BIN"),	642, 125+3, 108,20, TPoint.Create(ALIGN_CENTER), fontColor)
		Assets.GetFont("Default",12, BOLDFONT).drawBlock(GetLocale("SERIES"), 		642, 223+3, 108,20, TPoint.Create(ALIGN_CENTER), fontColor)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")
		SetAlpha 0.5;SetColor 0,0,0
		DrawRect(20,10,760,373)
		SetAlpha 1.0;SetColor 255,255,255
		DrawGFXRect(Assets.GetSpritePack("gfx_gui_rect"), 120, 60, 555, 290)
		SetAlpha 0.5
		Assets.GetFont("Default",12,BOLDFONT).drawBlock(Localization.GetString("CLICK_ON_MOVIE_OR_SERIES_TO_PLACE_BID"), 140,317, 535,30, TPoint.Create(ALIGN_CENTER), TColor.CreateGrey(230), 2, 1, 0.25)
		SetAlpha 1.0

		TAuctionProgrammeBlocks.DrawAll()
	End Function

	Function onUpdateMovieAuction:int( triggerEvent:TEventBase )
		Game.cursorstate = 0
		TAuctionProgrammeBlocks.UpdateAll()
	End Function
End Type


'News room
Type RoomHandler_News extends TRoomHandler
	global PlannerToolTip:TTooltip
	Global NewsGenreButtons:TGUIImageButton[5]
	Global NewsGenreTooltip:TTooltip			'the tooltip if hovering over the genre buttons
	Global currentRoom:TRooms					'holding the currently updated room (so genre buttons can access it)

	'lists for visually placing news blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global guiNewsListAvailable:TGUINewsList
	Global guiNewsListUsed:TGUINewsSlotList
	Global draggedGuiNews:TGuiNews = null

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
		guiNewsListAvailable = new TGUINewsList.Create(34,20,Assets.getSprite("gfx_news_sheet0").area.GetW(), 356,"Newsplanner")
		guiNewsListAvailable.SetAcceptDrop("TGUINews")
		guiNewsListAvailable.Resize(guiNewsListAvailable.rect.GetW() + guiNewsListAvailable.guiScrollerV.rect.GetW() + 3,guiNewsListAvailable.rect.GetH())
		guiNewsListAvailable.guiEntriesPanel.minSize.SetXY(Assets.getSprite("gfx_news_sheet0").area.GetW(),356)

		guiNewsListUsed = new TGUINewsSlotList.Create(444,105,Assets.getSprite("gfx_news_sheet0").area.GetW(), 3*Assets.getSprite("gfx_news_sheet0").area.GetH(),"Newsplanner")
		guiNewsListUsed.SetItemLimit(3)
		guiNewsListUsed.SetAcceptDrop("TGUINews")
		guiNewsListUsed.SetSlotMinDimension(0,Assets.getSprite("gfx_news_sheet0").area.GetH())
		guiNewsListUsed.SetAutofillSlots(false)
		guiNewsListUsed.guiEntriesPanel.minSize.SetXY(Assets.getSprite("gfx_news_sheet0").area.GetW(),3*Assets.getSprite("gfx_news_sheet0").area.GetH())

		'if the player visually manages the blocks, we need to handle the events
		'so we can inform the programmeplan about changes...
		EventManager.registerListenerFunction("guiobject.onDropOnTargetAccepted", onDropNews, "TGUINews" )
		'this lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction("guiobject.onClick", onClickNews, "TGUINews")

		'we want to get informed if the news situation changes for a user
		EventManager.registerListenerFunction("programmeplan.SetNews", onChangeNews )
		EventManager.registerListenerFunction("programmeplan.RemoveNews", onChangeNews )
		EventManager.registerListenerFunction("programmecollection.addNews", onChangeNews )
		EventManager.registerListenerFunction("programmecollection.removeNews", onChangeNews )
		'we want to know if we hover a specific block
		EventManager.registerListenerFunction("guiGameObject.OnMouseOver", onMouseOverNews, "TGUINews" )

		'for all news rooms - register if someone goes into the planner
		local screen:TScreen = ScreenCollection.GetScreen("screen_news_newsplanning")
		'figure enters screen - reset the guilists, limit listening to the 4 rooms
		if screen then EventManager.registerListenerFunction("screen.onEnter", onEnterNewsPlannerScreen, screen)
		'also we want to interrupt leaving a room with dragged items
		EventManager.registerListenerFunction("screen.OnLeave", onLeaveNewsPlannerScreen, screen)

		super._RegisterScreenHandler( onUpdateNews, onDrawNews, ScreenCollection.GetScreen("screen_news") )
		super._RegisterScreenHandler( onUpdateNewsPlanner, onDrawNewsPlanner, ScreenCollection.GetScreen("screen_news_newsplanning") )


		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
	End Function


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'for further explanation of this, check
		'RoomHandler_Office.onSaveGameBeginLoad()

'		hoveredGuiNews = null
		draggedGuiNews = null
		guiNewsListAvailable.EmptyList()
		guiNewsListUsed.EmptyList()

		haveToRefreshGuiElements = true
	End Function


	Function CheckPlayerInRoom:int()
		'check if we are in the correct room
		if not Game.getPlayer().figure.inRoom then return FALSE
		if Game.getPlayer().isInRoom("newsagency") OR Game.getPlayer().isInRoom("newsplanner") then return FALSE

		return TRUE
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
		If PlannerToolTip Then PlannerToolTip.Update(App.Timer.getDelta())
		If NewsGenreTooltip Then NewsGenreTooltip.Update(App.Timer.getDelta())

		If TFunctions.IsIn(MouseManager.x, MouseManager.y, 167,60,240,160)
			If not PlannerToolTip Then PlannerToolTip = TTooltip.Create("Newsplaner", "Hinzufügen und entfernen", 180, 100, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				ScreenCollection.GoToSubScreen("screen_news_newsplanning")
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
		NewsGenreTooltip.area.position.SetXY(Max(21,button.rect.GetX()), button.rect.GetY()-30)

		If level = 0
			NewsGenreTooltip.title = button.GetCaptionText()+" - "+getLocale("NEWSSTUDIO_NOT_SUBSCRIBED")
			NewsGenreTooltip.content = getLocale("NEWSSTUDIO_SUBSCRIBE_GENRE_LEVEL")+" 1: "+ Game.Players[ Game.playerID ].GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
		Else
			NewsGenreTooltip.title = button.GetCaptionText()+" - "+getLocale("NEWSSTUDIO_SUBSCRIPTION_LEVEL")+" "+level
			if level = 3
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_DONT_SUBSCRIBE_GENRE_ANY_LONGER")+ "0" + getLocale("CURRENCY")
			Else
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_NEXT_SUBSCRIPTION_LEVEL")+": "+ Game.Players[ Game.playerID ].GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
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
			DrawRect( button.rect.GetX()+8+i*10, button.rect.GetY()+ Assets.getSprite(button.spriteBaseName).area.GetH() -7, 7,4)
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
	End Function


	Function onChangeNews:int( triggerEvent:TEventBase )
		'something changed -- refresh  gui elements
		RefreshGuiElements()
	End Function


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		guiNewsListAvailable.emptyList()
		guiNewsListUsed.emptyList()
		For local guiNews:TGuiNews = eachin GuiManager.listDragged
			guiNews.remove()
		Next
	End Function


	Function RefreshGuiElements:int()
		'remove gui elements with news the player does not have anylonger
		For local guiNews:TGuiNews = eachin guiNewsListAvailable.entries
			if not Game.getPlayer().ProgrammeCollection.hasNews(guiNews.news) then guiNews.remove()
		Next
		For local guiNews:TGuiNews = eachin guiNewsListUsed._slots
			if not Game.getPlayer().ProgrammePlan.hasNews(guiNews.news) then guiNews.remove()
		Next

		'if removing "dragged" we also bug out the "replace"-mechanism when
		'dropping on occupied slots
		'so therefor this items should check itself for being "outdated"
		'For local guiNews:TGuiNews = eachin GuiManager.ListDragged
		'	if guiNews.news.isOutdated() then guiNews.remove()
		'Next

		'fill a list containing dragged news - so we do not create them again
		local draggedNewsList:TList = CreateList()
		For local guiNews:TGuiNews = eachin GuiManager.ListDragged
			draggedNewsList.addLast(guiNews.news)
		Next

		'create gui element for news still missing them
		For Local news:TNews = EachIn Game.getPlayer().ProgrammeCollection.news
			'skip if news is dragged
			if draggedNewsList.contains(news) then continue

			if not guiNewsListAvailable.ContainsNews(news)
				'only add for news NOT planned in the news show
				if not Game.getPlayer().ProgrammePlan.HasNews(news)
					local guiNews:TGUINews = new TGUINews.Create(news.GetTitle())
					guiNews.SetNews(news)
					guiNewsListAvailable.AddItem(guiNews)
				endif
			endif
		Next
		For Local i:int = 0 to Game.getPlayer().ProgrammePlan.news.length - 1
			local news:TNews = TNews(Game.getPlayer().ProgrammePlan.GetNews(i))
			'skip if news is dragged
			if news and draggedNewsList.contains(news) then continue

			if news and not guiNewsListUsed.ContainsNews(news)
				local guiNews:TGUINews = new TGUINews.Create(news.GetTitle())
				guiNews.SetNews(news)
				guiNewsListUsed.AddItem(guiNews, string(i))
			endif
		Next

		haveToRefreshGuiElements = FALSE
	End Function


	Function onUpdateNewsPlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then RefreshGUIElements()

		'reset dragged block - will get set automatically on gui-update
		draggedGuiNews = null

		'general newsplanner elements
		GUIManager.Update("Newsplanner")
	End Function


	'we need to know whether we dragged or hovered an item - so we
	'can react to right clicks ("forbid room leaving")
	Function onMouseOverNews:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local item:TGUINews = TGUINews(triggerEvent.GetSender())
		if item = Null then return FALSE

		if item.isDragged() then draggedGuiNews = item

		return TRUE
	End Function


	'in case of right mouse button click we want to remove the
	'block from the player's programmePlan
	Function onClickNews:int(triggerEvent:TEventBase)
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiNews:TGUINews= TGUINews(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiNews or not guiNews.isDragged() then return FALSE

		'remove from plan (with addBackToCollection=FALSE) and collection
		Game.Players[guiNews.news.owner].ProgrammePlan.RemoveNews(guiNews.news, -1, FALSE)
		Game.Players[guiNews.news.owner].ProgrammeCollection.RemoveNews(guiNews.news)

		'remove gui object
		guiNews.remove()

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	Function onDropNews:int(triggerEvent:TEventBase)
		local guiNews:TGUINews = TGUINews( triggerEvent._sender )
		local receiverList:TGUIListBase = TGUIListBase( triggerEvent._receiver )
		if not guiNews or not receiverList then return FALSE

		local owner:int = guiNews.news.owner

		if receiverList = guiNewsListAvailable
			Game.Players[owner].ProgrammePlan.RemoveNews(guiNews.news, -1, TRUE)
		elseif receiverList = guiNewsListUsed
			local slot:int = -1
			'check drop position
			local coord:TPoint = TPoint(triggerEvent.getData().get("coord", TPoint.Create(-1,-1)))
			if coord then slot = guiNewsListUsed.GetSlotByCoord(coord)
			if slot = -1 then slot = guiNewsListUsed.getSlot(guiNews)

			'this may also drag a news that occupied that slot before
			Game.Players[owner].ProgrammePlan.SetNews(guiNews.news, slot)
		endif
	End Function


	'clear the guilist for the suitcase if a player enters
	'screens are only handled by real players
	Function onEnterNewsPlannerScreen:int(triggerEvent:TEventBase)
		'empty the guilist / delete gui elements
		RemoveAllGuiElements()
		RefreshGUIElements()
	End Function


	Function onLeaveNewsPlannerScreen:int( triggerEvent:TEventBase )
		'do not allow leaving as long as we have a dragged block
		if draggedGuiNews
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function
End Type



'Chief: credit and emmys - your boss :D
Type RoomHandler_Chief extends TRoomHandler
	'smoke effect
	Global part_array:TGW_SpriteParticle[100]
	Global spawn_delay:Int = 15
	Global Dialogues:TList = CreateList()

	Function Init()
		'create smoke effect particles
		For Local i:Int = 1 To Len part_array-1
			part_array[i] = New TGW_SpriteParticle
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
		'register dialogue handlers
		EventManager.registerListenerFunction("dialogue.onAcceptBossCredit", onAcceptBossCredit)
		EventManager.registerListenerFunction("dialogue.onRepayBossCredit", onRepayBossCredit)

	End Function


	Function onAcceptBossCredit:int(triggerEvent:TEventBase)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		Game.GetPlayer().GetFinance().TakeCredit(value)
	End Function


	Function onRepayBossCredit:int(triggerEvent:TEventBase)
		local value:int = triggerEvent.GetData().GetInt("value", 0)
		Game.GetPlayer().GetFinance().RepayCredit(value)
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
			ChefDialoge[0] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_WELCOME").replace("%1", Game.GetPlayer().name) )
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_WILLNOTDISTURB"), - 2, Null))
			ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_ASKFORCREDIT"), 1, Null))

			If Game.GetPlayer().GetCredit() > 0
				ChefDialoge[0].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_REPAYCREDIT"), 3, Null))
			endif
			If Game.GetPlayer().GetCreditAvailable() > 0
				local acceptEvent:TEventSimple = TEventSimple.Create("dialogue.onAcceptBossCredit", TData.Create().AddNumber("value", Game.GetPlayer().GetCreditAvailable()))
				ChefDialoge[1] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_OK").replace("%1", Game.GetPlayer().GetCreditAvailable()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_OK_ACCEPT"), 2, acceptEvent))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			Else
				ChefDialoge[1] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY").replace("%1", Game.GetPlayer().GetCredit()))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_ACCEPT"), 3))
				ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_DECLINE"+Rand(1,3)), - 2))
			EndIf
			ChefDialoge[1].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CHANGETOPIC"), 0))

			ChefDialoge[2] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_BACKTOWORK").replace("%1", Game.GetPlayer().name) )
			ChefDialoge[2].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_BACKTOWORK_OK"), - 2))

			ChefDialoge[3] = TDialogueTexts.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_BOSSRESPONSE") )
			If Game.GetPlayer().GetCredit() >= 100000 And Game.GetPlayer().GetMoney() >= 100000
				local payBackEvent:TEventSimple = TEventSimple.Create("dialogue.onRepayBossCredit", TData.Create().AddNumber("value", 100000))
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_100K"), - 2, payBackEvent))
			EndIf
			If Game.GetPlayer().GetCredit() < Game.GetPlayer().GetMoney()
				local payBackEvent:TEventSimple = TEventSimple.Create("dialogue.onRepayBossCredit", TData.Create().AddNumber("value", Game.GetPlayer().GetCredit()))
				ChefDialoge[3].AddAnswer(TDialogueAnswer.Create( GetLocale("DIALOGUE_BOSS_CREDIT_REPAY_ALL").replace("%1", Game.GetPlayer().GetCredit()), - 2, payBackEvent))
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
			part_array[i].Update(App.timer.getDelta())
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
	  TFunctions.DrawDialog(Assets.GetSpritePack("gfx_dialog"), 350, 60, 450, 120, "StartLeftDown", 0, ChefText, Font14)
	endrem

End Type




'Movie agency
Type RoomHandler_AdAgency extends TRoomHandler
	Global hoveredGuiAdContract:TGuiAdContract = null
	Global draggedGuiAdContract:TGuiAdContract = null

	Global VendorArea:TGUISimpleRect	'allows registration of drop-event

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listNormal:TAdContract[]
	Field listCheap:TAdContract[]

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListNormal:TGUIAdContractSlotList[]
	Global GuiListCheap:TGUIAdContractSlotList = null
	Global GuiListSuitcase:TGUIAdContractSlotList = null

	'configuration
	Global suitcasePos:TPoint					= TPoint.Create(520,100)
	Global suitcaseGuiListDisplace:TPoint		= TPoint.Create(19,32)
	Global contractsPerLine:int					= 4
	Global contractsNormalAmount:int			= 12
	Global contractsCheapAmount:int				= 4
	Global contractCheapAudienceMaximum:float	= 0.05 '5% market share

	Global _instance:RoomHandler_AdAgency
	Global _initDone:int = FALSE


	Function GetInstance:RoomHandler_AdAgency()
		if not _instance then _instance = new RoomHandler_AdAgency
		if not _initDone then _instance.Init()
		return _instance
	End Function


	Method Init:int()
		if _initDone then return FALSE

		'===== CREATE/RESIZE LISTS =====

		listNormal		= listNormal[..contractsNormalAmount]
		listCheap		= listCheap[..contractsCheapAmount]


		'===== CREATE GUI LISTS =====

		GuiListNormal	= GuiListNormal[..3]
		for local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i] = new TGUIAdContractSlotList.Create(430-i*70,170+i*32, 200,140, "adagency")
			GuiListNormal[i].SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListNormal[i].SetItemLimit( contractsNormalAmount / GuiListNormal.length  )
			GuiListNormal[i].Resize(Assets.GetSprite("gfx_contracts_0").area.GetW() * (contractsNormalAmount / GuiListNormal.length), Assets.GetSprite("gfx_contracts_0").area.GetH() )
			GuiListNormal[i].SetSlotMinDimension(Assets.GetSprite("gfx_contracts_0").area.GetW(), Assets.GetSprite("gfx_contracts_0").area.GetH())
			GuiListNormal[i].SetAcceptDrop("TGuiAdContract")
			GuiListNormal[i].setZindex(i)
		Next

		GuiListSuitcase	= new TGUIAdContractSlotList.Create(suitcasePos.GetX()+suitcaseGuiListDisplace.GetX(),suitcasePos.GetY()+suitcaseGuiListDisplace.GetY(),200,80, "adagency")
		GuiListSuitcase.SetAutofillSlots(true)

		GuiListCheap	= new TGUIAdContractSlotList.Create(70,200,10 +Assets.GetSprite("gfx_contracts_0").area.GetW()*4,Assets.GetSprite("gfx_contracts_0").area.GetH(), "adagency")
		GuiListCheap.setEntriesBlockDisplacement(70,0)



		GuiListCheap.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

		GuiListCheap.SetItemLimit( listCheap.length )
		GuiListSuitcase.SetItemLimit(Game.maxContracts)

		GuiListCheap.SetSlotMinDimension(Assets.GetSprite("gfx_contracts_0").area.GetW(), Assets.GetSprite("gfx_contracts_0").area.GetH())
		GuiListSuitcase.SetSlotMinDimension(Assets.GetSprite("gfx_contracts_0").area.GetW(), Assets.GetSprite("gfx_contracts_0").area.GetH())

		GuiListCheap.SetEntryDisplacement( -2*GuiListNormal[0]._slotMinDimension.x, 5)
		GuiListSuitcase.SetEntryDisplacement( 0, 0)

		GuiListCheap.SetAcceptDrop("TGuiAdContract")
		GuiListSuitcase.SetAcceptDrop("TGuiAdContract")

		VendorArea = new TGUISimpleRect.Create(TRectangle.Create(286,110, Assets.GetSprite("gfx_hint_rooms_adagency").area.GetW(), Assets.GetSprite("gfx_hint_rooms_adagency").area.GetH()), "adagency" )
		'vendor should accept drop - else no recognition
		VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)


		'===== REGISTER EVENTS =====

		'to react on changes in the programmeCollection (eg. contract finished)
		EventManager.registerListenerFunction( "programmecollection.addAdContract", onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.removeAdContract", onChangeProgrammeCollection )

		'figure enters room - reset guilists if player
		EventManager.registerListenerFunction( "room.onEnter", onEnterRoom, TRooms.GetRoomByDetails("adagency",0) )

		'begin drop - to intercept if dropping to wrong list
		EventManager.registerListenerFunction( "guiobject.onTryDropOnTarget", onTryDropContract, "TGuiAdContract" )
		'drop ... to vendor or suitcase
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropContract, "TGuiAdContract" )
		'drop on vendor - sell things
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropContractOnVendor, "TGuiAdContract" )
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "guiGameObject.OnMouseOver", onMouseOverContract, "TGuiAdContract" )
		'figure leaves room - only without dragged blocks
		EventManager.registerListenerFunction( "room.onTryLeave", onTryLeaveRoom, TRooms.GetRoomByDetails("adagency",0) )
		EventManager.registerListenerFunction( "room.onLeave", onLeaveRoom, TRooms.GetRoomByDetails("adagency",0) )
		'this lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction("guiobject.onClick", onClickContract, "TGuiAdContract")

		super._RegisterScreenHandler( onUpdateAdAgency, onDrawAdAgency, ScreenCollection.GetScreen("screen_adagency") )

		'handle savegame loading (remove old gui elements)
		EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)

		_initDone = true
	End Method


	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new contracts are not loaded yet

		'We cannot rely on "onEnterRoom" as we could have saved
		'in this room
		GetInstance().RemoveAllGuiElements()
		haveToRefreshGuiElements = true
	End Function



	Function onEnterRoom:int(triggerEvent:TEventBase)
		local room:TRooms = TRooms(triggerEvent.GetSender())
		local figure:TFigure = TFigure(triggerEvent.GetData().Get("figure"))
		if not room or not figure then return FALSE

		'fill all open slots in the agency - eg. when entering the first time
		'we are not interested in other figures than our player's
		if not figure.IsActivePlayer() then return FALSE

		GetInstance().RemoveAllGuiElements()
		GetInstance().ResetContractOrder()
		GetInstance().ReFillBlocks()
		GetInstance().RefreshGUIElements()
	End function


	Function onTryLeaveRoom:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return FALSE

		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiAdContract
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
		local figure:TFigure = TFigure(triggerEvent.getData().get("figure"))
		if not figure or not figure.parentPlayerID then return FALSE

		'sign all new contracts
		For Local contract:TAdContract = EachIn Game.GetPlayer(figure.parentPlayerID).ProgrammeCollection.suitcaseAdContracts
			'adds a contract to the players collection (gets signed THERE)
			'if successful, this also removes the contract from the suitcase
			Game.GetPlayer(figure.parentPlayerID).ProgrammeCollection.AddAdContract(contract)
		Next

		'fill all open slots in the agency
		GetInstance().ReFillBlocks()
		'remove all gui elements - else the "dropped" one may still be in the
		'suitcase...
		GetInstance().RemoveAllGuiElements()

		return TRUE
	End Function


	'===================================
	'AD Agency: common TFunctions
	'===================================

	Method GetContractsInStock:int()
		Local ret:Int = 0
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				if contract Then ret:+1
			Next
		Next
		return ret
	End Method


	Method GetContractByPosition:TAdContract(position:int)
		if position > GetContractsInStock() then return null
		local currentPosition:int = 0
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				if contract
					if currentPosition = position then return contract
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Method


	Method HasContract:int(contract:TAdContract)
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local cont:TAdContract = EachIn lists[j]
				if cont = contract then return TRUE
			Next
		Next
		return FALSE
	End Method


	Method GetContractByID:TAdContract(contractID:int)
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				if contract and contract.id = contractID then return contract
			Next
		Next
		return null
	End Method


	Method GiveContractToPlayer:int(contract:TAdContract, playerID:int, sign:int=FALSE)
		if contract.owner = playerID then return FALSE
		if not Game.isPlayer(playerID) then return FALSE

		'try to add to suitcase of player
		if not sign
			if not Game.GetPlayer(playerID).ProgrammeCollection.AddUnsignedAdContractToSuitcase(contract) then return FALSE
		'we do not need the suitcase, direkt sign pls (eg. for AI)
		else
			if not Game.GetPlayer(playerID).ProgrammeCollection.AddAdContract(contract) then return FALSE
		endif

		'remove from agency's lists
		GetInstance().RemoveContract(contract)

		return TRUE
	End Method


	Method TakeContractFromPlayer:int(contract:TAdContract, playerID:int)
		if Game.Players[ playerID ].ProgrammeCollection.RemoveUnsignedAdContractFromSuitcase(contract)
			'add to agency's lists - if not existing yet
			if not HasContract(contract) then AddContract(contract)

			return TRUE
		else
			return FALSE
		endif
	End Method


	Function isCheapContract:int(contract:TAdContract)
		return contract.GetMinAudiencePercentage() < contractCheapAudienceMaximum
	End Function


	Method ResetContractOrder:int()
		local contracts:TList = CreateList()
		for local contract:TAdContract = eachin listNormal
			contracts.addLast(contract)
		Next
		for local contract:TAdContract = eachin listCheap
			contracts.addLast(contract)
		Next
		listNormal = new TAdContract[listNormal.length]
		listCheap = new TAdContract[listCheap.length]

		contracts.sort()

		'add again - so it gets sorted
		for local contract:TAdContract = eachin contracts
			AddContract(contract)
		Next

		RemoveAllGuiElements()
	End Method


	Method RemoveContract:int(contract:TAdContract)
		local foundContract:int = FALSE
		'remove from agency's lists
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = contract then lists[j][i] = null;foundContract=TRUE
			Next
		Next

		return foundContract
	End Method


	Method AddContract:int(contract:TAdContract)
		'try to fill the program into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TAdContract[][]

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
	End Method



	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		For local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i].EmptyList()
		Next
		GuiListCheap.EmptyList()
		GuiListSuitcase.EmptyList()
		For local guiAdContract:TGuiAdContract = eachin GuiManager.listDragged
			guiAdContract.remove()
		Next

		hoveredGuiAdContract = null
		draggedGuiAdContract = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Function


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with contracts the player does not have any longer

		'suitcase
		For local guiAdContract:TGuiAdContract = eachin GuiListSuitcase._slots
			'if the player has this contract in suitcase or list, skip deletion
			if Game.getPlayer().ProgrammeCollection.HasAdContract(guiAdContract.contract) then continue
			if Game.getPlayer().ProgrammeCollection.HasUnsignedAdContractInSuitcase(guiAdContract.contract) then continue

			'print "guiListSuitcase has obsolete contract: "+guiAdContract.contract.id
			guiAdContract.remove()
		Next
		'agency lists
		For local i:int = 0 to GuiListNormal.length-1
			For local guiAdContract:TGuiAdContract = eachin GuiListNormal[i]._slots
				'if not HasContract(guiAdContract.contract) then print "REM guiListNormal"+i+" has obsolete contract: "+guiAdContract.contract.id
				if not HasContract(guiAdContract.contract) then guiAdContract.remove()
			Next
		Next
		For local guiAdContract:TGuiAdContract = eachin GuiListCheap._slots
			'if not HasContract(guiAdContract.contract) then	print "REM guiListCheap has obsolete contract: "+guiAdContract.contract.id
			if not HasContract(guiAdContract.contract) then guiAdContract.remove()
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all contract-lists

		'normal list
		For local contract:TAdContract = eachin listNormal
			if not contract then continue
			local contractAdded:int = FALSE

			'search the contract in all of our lists...
			local contractFound:int = FALSE
			For local i:int = 0 to GuiListNormal.length-1
				if contractFound then continue
				if GuiListNormal[i].ContainsContract(contract) then contractFound=true
			Next

			'try to fill in one of the normalList-Parts
			if not contractFound
				For local i:int = 0 to GuiListNormal.length-1
					if contractAdded then continue
					if GuiListNormal[i].ContainsContract(contract) then contractAdded=true;continue
					if GuiListNormal[i].getFreeSlot() < 0 then continue
					local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
					'change look
					block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

					'print "ADD guiListNormal"+i+" missed new contract: "+block.contract.id

					GuiListNormal[i].addItem(block, "-1")
					contractAdded = true
				Next
				if not contractAdded
					TDevHelper.log("AdAgency.RefreshGuiElements", "contract exists but does not fit in GuiListNormal - contract removed.", LOG_ERROR)
					RemoveContract(contract)
				endif
			endif
		Next

		'cheap list
		For local contract:TAdContract = eachin listCheap
			if not contract then continue
			if GuiListCheap.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

			'print "ADD guiListCheap missed new contract: "+block.contract.id

			GuiListCheap.addItem(block, "-1")
		Next

		'create missing gui elements for the players contracts
		For local contract:TAdContract = eachin Game.getPlayer().ProgrammeCollection.adContracts
			if guiListSuitcase.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			'print "ADD guiListSuitcase missed new (old) contract: "+block.contract.id

			block.setOption(GUI_OBJECT_DRAGABLE, FALSE)
			guiListSuitcase.addItem(block, "-1")
		Next

		'create missing gui elements for the current suitcase
		For local contract:TAdContract = eachin Game.getPlayer().ProgrammeCollection.suitcaseAdContracts
			if guiListSuitcase.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			'print "guiListSuitcase missed new contract: "+block.contract.id

			guiListSuitcase.addItem(block, "-1")
		Next
		haveToRefreshGuiElements = FALSE
	End Method


	'refills slots in the ad agency
	'replaceOffer: remove (some) old contracts and place new there?
	Method ReFillBlocks:Int(replaceOffer:int=FALSE, replaceChance:float=1.0)
		local lists:TAdContract[][] = [listNormal,listCheap]
		local contract:TAdContract = null

		haveToRefreshGuiElements = TRUE

		'delete some random ads
		if replaceOffer
			for local j:int = 0 to lists.length-1
				for local i:int = 0 to lists[j].length-1
					if not lists[j][i] then continue
					'delete an old contract by a chance of 50%
					if RandRange(0,100) < replaceChance*100
						'reset owner
						lists[j][i].owner = 0
						'unlink from this list
						lists[j][i] = null
					endif
				Next
			Next
		endif


		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				'if exists...skip it
				if lists[j][i] then continue

				if lists[j] = listNormal then contract = new TAdContract.Create( TAdContractBase.GetRandom() )
				if lists[j] = listCheap then contract = new TAdContract.Create( TAdContractBase.GetRandomWithLimitedAudienceQuote(0.0, contractCheapAudienceMaximum) )

				'add new contract to slot
				if contract
					contract.owner = -1
					lists[j][i] = contract
				else
					TDevHelper.log("AdAgency.ReFillBlocks", "Not enough contracts to fill ad agency in list "+i, LOG_ERROR)
				endif
			Next
		Next
	End Method


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

		GetInstance().RefreshGuiElements()
	End Function


	'in case of right mouse button click we want to remove the
	'block from the player's programmePlan
	Function onClickContract:int(triggerEvent:TEventBase)
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiAdContract:TGuiAdContract= TGUIAdContract(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiAdContract or not guiAdContract.isDragged() then return FALSE

		'will automatically rebuild at correct spot
		'remove gui object
		guiAdContract.remove()

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	Function onMouseOverContract:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local item:TGuiAdContract = TGuiAdContract(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiAdContract = item
		if item.isDragged() then draggedGuiAdContract = item

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropContractOnVendor:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGuiAdContract = TGuiAdContract( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver or receiver <> VendorArea then return FALSE

		local parent:TGUIobject = guiBlock._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local senderList:TGUIAdContractSlotList = TGUIAdContractSlotList(parent)
		if not senderList then return FALSE

		'if coming from suitcase, try to remove it from the player
		if senderList = GuiListSuitcase
			if not GetInstance().TakeContractFromPlayer(guiBlock.contract, Game.getPlayer().playerID )
				triggerEvent.setVeto()
				return FALSE
			endif
		else
			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveContract(guiBlock.contract)
			GetInstance().AddContract(guiBlock.contract)
		endif
		'remove the block, will get recreated if needed
		guiBlock.remove()

		'something changed...refresh missing/obsolete...
		GetInstance().RefreshGuiElements()

		return TRUE
	End function


	'we intercept that event so we can avoid dropping from one
	'vendor list to another
	Function onTryDropContract:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom() then return FALSE

		local guiBlock:TGuiAdContract = TGuiAdContract( triggerEvent._sender )
		local receiverList:TGUIAdContractSlotList = TGUIAdContractSlotList( triggerEvent._receiver )
		if not guiBlock or not receiverList then return FALSE

		local parent:TGUIobject = guiBlock._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local senderList:TGUIAdContractSlotList = TGUIAdContractSlotList(parent)
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

		local guiAdContract:TGuiAdContract = TGuiAdContract(triggerEvent._sender)
		local receiverList:TGUIAdContractSlotList = TGUIAdContractSlotList(triggerEvent._receiver)
		if not guiAdContract or not receiverList then return FALSE

		'get current owner of the contract, as the field "owner" is set
		'during sign we cannot rely on it. So we check if the player has
		'the contract in the suitcaseContractList
		local owner:int = guiAdContract.contract.owner
		if owner <= 0 and Game.getPlayer().ProgrammeCollection.HasUnsignedAdContractInSuitcase(guiAdContract.contract)
			owner = Game.playerID
		endif

		'find out if we sell it to the vendor or drop it to our suitcase
		local toVendor:int = FALSE
		for local i:int = 0 to GuiListNormal.length
			if receiverList = GuiListNormal[i] then toVendor = true;exit
		Next
		if receiverList = GuiListCheap then toVendor = true

		if toVendor
			guiAdContract.InitAssets( guiAdContract.getAssetName(-1, FALSE ), guiAdContract.getAssetName(-1, TRUE ) )

			'no problem when dropping vendor programme to vendor..
			if owner <= 0 then return TRUE
			if not GetInstance().TakeContractFromPlayer(guiAdContract.contract, Game.playerID )
				triggerEvent.setVeto()
				return FALSE
			endif

			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveContract(guiAdContract.contract)
			GetInstance().AddContract(guiAdContract.contract)
		else
			guiAdContract.InitAssets(guiAdContract.getAssetName(-1, TRUE ), guiAdContract.getAssetName(-1, TRUE ))

			'no problem when dropping own programme to suitcase..
			if owner = Game.playerID then return TRUE
			if not GetInstance().GiveContractToPlayer(guiAdContract.contract, Game.playerID)
				triggerEvent.setVeto()
				return FALSE
			endif
		endIf

		'something changed...refresh missing/obsolete...
		GetInstance().RefreshGuiElements()

		return TRUE
	End Function


	Function onDrawAdAgency:int( triggerEvent:TEventBase )
		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		if draggedGuiAdContract
			if not Game.getPlayer().ProgrammeCollection.HasUnsignedAdContractInSuitcase(draggedGuiAdContract.contract)
				glowSuitcase = "_glow"
			endif
			Assets.GetSprite("gfx_hint_rooms_adagency").Draw(VendorArea.getScreenX(), VendorArea.getScreenY())
		endif

		'draw suitcase
		Assets.GetSprite("gfx_suitcase_big"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		GUIManager.Draw("adagency")

		if hoveredGuiAdContract
			'draw the current sheet
			hoveredGuiAdContract.DrawSheet()
		endif

	End Function


	Function onUpdateAdAgency:int( triggerEvent:TEventBase )
		local room:TRooms		= TRooms( triggerEvent.GetData().get("room") )
		if not room then return 0

		'if we have a licence dragged ... we should take care of "ESC"-Key
		if draggedGuiAdContract
			if KeyManager.IsHit(KEY_ESCAPE)
				draggedGuiAdContract.dropBackToOrigin()
				draggedGuiAdContract = null
				hoveredGuiAdContract = null
			endif
		endif

		Game.cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiAdContract = null
		'reset dragged block too
		draggedGuiAdContract = null
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

		local playerFigure:TFigure = Game.Players[ Game.playerID ].figure

		TRoomSigns.DrawAll()
	End Function

	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TRooms = TRooms(triggerEvent._sender)
		if not room then return 0

		local playerFigure:TFigure = Game.Players[ Game.playerID ].figure
		local mouseHit:int = MouseManager.IsClicked(1)

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
			local sprite:TGW_Sprite = Assets.GetSprite("gfx_room_betty_picture1")
			Local picY:Int = 240
			Local picX:Int = 410 + i * (sprite.area.GetW() + 5)
			sprite.Draw( picX, picY )
			SetAlpha 0.4
			Game.Players[i].color.copy().AdjustRelative(-0.5).SetRGB()
			DrawRect(picX + 2, picY + 8, 26, 28)
			SetColor 255, 255, 255
			SetAlpha 1.0
			local x:float = picX + Int(sprite.area.GetW() / 2) - Int(Game.Players[i].Figure.Sprite.framew / 2)
			local y:float = picY + sprite.area.GetH() - 30
			Game.Players[i].Figure.Sprite.DrawClipped(TPoint.Create(x, y), TRectangle.Create(0, 0, -1, sprite.area.GetH()-16), 8)
		Next

		DrawDialog("default", 430, 120, 280, 110, "StartLeftDown", 0, GetLocale("DIALOGUE_BETTY_WELCOME"), Assets.GetFont("Default",14))
	End Function

	Function onUpdate:int( triggerEvent:TEventBase )
		'nothing yet
	End Function
End Type


'helper for Credits
Type TCreditsRole
	field name:string = ""
	field cast:string[]
	field color:TColor

	Method Init:TCreditsRole(name:string, color:TColor)
		self.name = name
		self.color = color
		return self
	End Method

	Method addCast:int(name:string)
		cast = cast[..cast.length+1]
		cast[cast.length-1] = name
		return true
	End Method
End Type


Type RoomHandler_Credits extends TRoomHandler
	Global roles:TCreditsRole[]
	Global currentRolePosition:int = 0
	Global currentCastPosition:int = 0
	Global changeRoleTimer:TIntervalTimer = TIntervalTimer.Create(3200, 0,0)
	Global fadeTimer:TIntervalTimer = TIntervalTimer.Create(1000, 0,0)
	Global fadeMode:int = 0 '0 = fadein, 1=stay, 2=fadeout
	Global fadeRole:int = TRUE
	Global fadeValue:float = 0.0

	Function Init()
		super._RegisterHandler(onUpdate, onDraw, TRooms.GetRoomByDetails("credits",-1))

		'player figure enters screen - reset the current displayed role
		EventManager.registerListenerFunction("room.onEnter", OnEnterRoom, TRooms.GetRoomByDetails("credits",-1))


		local role:TCreditsRole
		local cast:TList = null

		role = CreateRole("Das TVTower-Team", TColor.Create(255,255,255))
		role.addCast("und die fleissigen Helfer")

		role = CreateRole("Programmierung", TColor.Create(200,200,0))
		role.addCast("Ronny Otto~n(Engine, Spielmechanik)")
		role.addCast("Manuel Vögele~n(Quotenberechnung, Sendermarkt)")

		role = CreateRole("Grafik", TColor.Create(240,160,150))
		role.addCast("Ronny Otto")

		role = CreateRole("KI-Entwicklung", TColor.Create(140,240,250))
		role.addCast("Ronny Otto~n(KI-Anbindung)")
		role.addCast("Manuel Vögele~n(KI-Verhalten & -Anbindung)")

		role = CreateRole("Datenbank-Team", TColor.Create(210,120,250))
		role.addCast("Ronny Otto")
		role.addCast("Martin Rackow")
		role.addCast("u.a. Freiwillige")

		role = CreateRole("Tester", TColor.Create(160,180,250))
		role.addCast("...und Motivationsteam")
		role.addCast("Basti")
		role.addCast("Ceddy")
		role.addCast("dirkw")
		role.addCast("djmetzger")
		role.addCast("Kurt TV")
		role.addCast("Själe")
		role.addCast("...und all die anderen Fehlermelder im Forum")


		role = CreateRole("", TColor.clWhite)
		role.addCast("")

		role = CreateRole("Besucht uns im Netz", TColor.clWhite)
		role.addCast("http://www.tvgigant.de")

		role = CreateRole("", TColor.clWhite)
		role.addCast("")

	End Function


	'helper to create a role and store it in the array
	Function CreateRole:TCreditsRole(name:string, color:TColor)
		roles = roles[..roles.length+1]
		roles[roles.length-1] = new TCreditsRole.Init(name, color)
		return roles[roles.length-1]
	End Function


	Function GetRole:TCreditsRole()
		'reached end
		if currentRolePosition = roles.length then currentRolePosition = 0
		return roles[currentRolePosition]
	End Function


	Function GetCast:string(addToCurrent:int=0)
		local role:TCreditsRole = GetRole()
		'reached end
		if (currentCastPosition + addToCurrent) = role.cast.length then return NULL
		return role.cast[currentCastPosition + addToCurrent]
	End function


	Function NextCast:int()
		currentCastPosition :+1
		return (GetCast() <> "")
	End Function


	Function NextRole:int()
		currentRolePosition :+1
		currentCastPosition = 0
		return TRUE
	End Function


	'reset to start role when entering
	Function onEnterRoom:int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetData().get("figure"))
		if not figure then return FALSE

		fadeTimer.Reset()
		changeRoleTimer.Reset()
		currentRolePosition = 0
		currentCastPosition = 0
		fadeMode = 0
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		SetAlpha fadeValue

		local fontRole:TGW_BitmapFont = Assets.GetFont("Default",28, BOLDFONT)
		local fontCast:TGW_BitmapFont = Assets.GetFont("Default",20, BOLDFONT)
		if not fadeRole then SetAlpha 1.0
		fontRole.DrawBlock(GetRole().name.ToUpper(), 20,180, App.settings.GetWidth()-40, 40, TPoint.Create(ALIGN_CENTER), GetRole().color, 2, 1, 0.6)
		SetAlpha fadeValue
		if GetCast() then fontCast.DrawBlock(GetCast(), 150,210, App.settings.GetWidth()-300, 80, TPoint.Create(ALIGN_CENTER), TColor.CreateGrey(230), 2, 1, 0.6)

		SetAlpha 1.0
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		if fadeTimer.isExpired() and fadeMode < 2
			fadeMode:+1
			fadeTimer.Reset()

			'gets "true" if the role is changed again
			fadeRole = FALSE
			'fade if last cast is fading out
			if not GetCast(+1) then fadeRole = true

			if fadeMode = 0 then fadeValue = 0.0
			if fadeMode = 1 then fadeValue = 1.0
			if fadeMode = 2 then fadeValue = 1.0
		endif
		if changeRoleTimer.isExpired()
			'if there is no new cast...next role pls
			if not NextCast() then NextRole()
			changeRoleTimer.Reset()
			fadeTimer.Reset()
			fadeMode = 0 'next fadein
		endif

		'linear fadein
		fadeValue = fadeTimer.GetTimeGoneInPercents()
		if fadeMode = 0 then fadeValue = fadeValue
		if fadeMode = 1 then fadeValue = 1.0
		if fadeMode = 2 then fadeValue = 1.0 - fadeValue
	End Function
End Type


'signs used in elevator-plan /room-plan
Type TRoomSigns Extends TBlockMoveable
	Field title:String				= ""
	Field image:TGW_Sprite			= null
	Field imageWithText:TGW_Sprite	= null
	Field image_dragged:TGW_Sprite	= null

	Global DragAndDropList:TList	= CreateList()
	Global List:TList				= CreateList()
	Global AdditionallyDragged:Int	= 0

	const signSlot1:int	= 26
	const signSlot2:int	= 208
	const signSlot3:int	= 417
	const signSlot4:int	= 599


	Function Create:TRoomSigns(text:String="unknown", x:Int=0, y:Int=0, owner:Int=0)
		Local sign:TRoomSigns=New TRoomSigns

		sign.dragable	= 1
		sign.owner		= owner
		If owner < 0 Then owner = 0

		sign.image			= Assets.GetSprite("gfx_elevator_sign"+owner)
		sign.image_dragged	= Assets.GetSprite("gfx_elevator_sign_dragged"+owner)
		sign.OrigPos		= TPoint.Create(x, y)
		sign.StartPos		= TPoint.Create(x, y)
		sign.rect 			= TRectangle.Create(x,y, sign.image.area.GetW(), sign.image.area.GetH() - 1)
		sign.title			= text
		List.AddLast(sign)
		SortList List
		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 		DragAndDrop.slot = CountList(List) - 1
 		DragAndDrop.pos.setXY(x,y)
 		DragAndDrop.w = sign.image.area.GetW()
 		DragAndDrop.h = sign.image.area.GetH()-1
   		If Not TRoomSigns.DragAndDropList Then TRoomSigns.DragAndDropList = CreateList()
		TRoomSigns.DragAndDropList.AddLast(DragAndDrop)
 		SortList TRoomSigns.DragAndDropList

		Return sign
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
				Local font:TGW_BitmapFont = Assets.GetFont("Default",9, BOLDFONT)
				TGW_BitmapFont.setRenderTarget(newImgWithText)
				if owner > 0
					font.drawBlock(title, 22, 4, 150,20, null, TColor.CreateGrey(230), 2, 1, 0.5)
				else
					font.drawBlock(title, 22, 4, 150,20, null, TColor.CreateGrey(50), 2, 1, 0.3)
				endif
				TGW_BitmapFont.setRenderTarget(null)

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
							If TFunctions.IsIn(MouseManager.x,MouseManager.y,LocObj.StartPosBackup.x,locobj.StartPosBackup.y,locobj.rect.GetW(),locobj.rect.GetH())
								locObj.dragged = False
							EndIf

							'want to drop in origin-position
							If locObj.containsCoord(MouseManager.x, MouseManager.y)
								locObj.dragged = False
								MouseManager.resetKey(1)
							'not dropping on origin: search for other underlaying obj
							Else
								For Local OtherLocObj:TRoomSigns = EachIn TRoomSigns.List
									If OtherLocObj <> Null
										If OtherLocObj.containsCoord(MouseManager.x, MouseManager.y) And OtherLocObj <> locObj And OtherLocObj.dragged = False And OtherLocObj.dragable
'											If game.networkgame Then
'												Network.SendMovieAgencyChange(Network.NET_SWITCH, Game.playerID, OtherlocObj.Programme.id, -1, locObj.Programme)
'			  								End If
											locObj.SwitchBlock(otherLocObj)
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
					TInGameScreen_Room(ScreenCollection.GetScreen(String(vars.ValueForKey("screen")))),  ..
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

	RoomHandler_AdAgency.GetInstance().Init()
	RoomHandler_MovieAgency.GetInstance().Init()

	RoomHandler_Betty.Init()

	RoomHandler_ElevatorPlan.Init()
	RoomHandler_Roomboard.Init()

	RoomHandler_Credits.Init()


End Function

Function Init_CreateRoomDetails()
	For Local i:Int = 1 To 4
		TRooms.GetRoomByDetails("studiosize1", i).desc:+" " + Game.Players[i].channelname
		TRooms.GetRoomByDetails("office", i).desc:+" " + Game.Players[i].name
		TRooms.GetRoomByDetails("chief", i).desc:+" " + Game.Players[i].channelname
		TRooms.GetRoomByDetails("news", i).desc:+" " + Game.Players[i].channelname
		TRooms.GetRoomByDetails("archive", i).desc:+" " + Game.Players[i].channelname
	Next

	For Local Room:TRooms = EachIn TRooms.rooms
		Room.CreateRoomsign()
	Next
End Function