Type TRoomCollection Extends TRoomBaseCollection
	Function GetInstance:TRoomCollection()
		if not _instance
			_instance = new TRoomCollection

		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		'==== ATTENTION =====
		'NEVER store _instance somewhere without paying attention
		'to this "whacky hack"
		elseif not TRoomCollection(_instance)
			local collection:TRoomCollection = new TRoomCollection
			collection.list = _instance.list
			'now the new collection is the instance
			_instance = collection
		endif
		return TRoomCollection(_instance)
	End Function


	Function Get:TRoom(ID:int)
		Return TRoom(Super.Get(ID))
	End Function


	Function GetRandom:TRoom()
		Return TRoom(Super.GetRandom())
	End Function


	'returns all room fitting to the given details
	Function GetAllByDetails:TRoom[]( name:String, owner:Int=-1000 ) {_exposeToLua}
		local rooms:TRoomBase[] = Super.GetAllByDetails(name, owner)
		local result:TRoom[]
		For Local room:TRoom = EachIn rooms
			result :+ [room]
		Next
		Return result
	End Function


	Function GetFirstByDetails:TRoom( name:String, owner:Int=-1000 ) {_exposeToLua}
		return TRoom(Super.GetFirstByDetails(name, owner))
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetRoomCollection:TRoomCollection()
	Return TRoomCollection.GetInstance()
End Function




'container for data describing the room
'without data attached which is used for visual representation
'(tooltip, hotspots, signs...) -> they are now in TRoomDoor
'usage examples:
' - RoomAgency
' - Multiple "Doors" to the same room
Type TRoom extends TRoomBase {_exposeToLua="selected"}
	'list of special areas in the room
	Field hotspots:TList = CreateList()


	Method New()
		'register all needed events if not done yet
		if not _initDone
			'close / open doors
			EventManager.registerListenerFunction("room.onLeave", onLeave)
			EventManager.registerListenerFunction("room.onEnter", onEnter)
			_initDone = TRUE
		endif

		'do not add the room automatically ... it might lead to
		'duplicates in the collection when loading games
		'GetRoomCollection().Add(self)
	End Method


	'init a room with basic variables
	Method Init:TRoom(name:String="unknown", description:String[], owner:int, size:int=1)
		Super.Init(name, description, owner, size)
		return self
	End Method


	'override to add screen draw
	Method Draw:int()
		'if not self.screen then Throw "ERROR: room.draw() - screen missing";return 0
		'draw current screen
		'ScreenCollection.DrawCurrent(App.timer.getTween())
		'emit event so custom functions can run after screen draw, sender = screen
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenDraw", new TData.Add("room", self) , ScreenCollection.GetCurrentScreen() ) )

		return Super.Draw()
	End Method


	'override to add screen update
	Method Update:Int()
		'emit event so custom functions can run after screen update, sender = screen
		'also this event has "room" as payload
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenUpdate", new TData.Add("room", self) , ScreenCollection.GetCurrentScreen() ) )

		return Super.Update()
	End Method


	Method GetOwnerPlayerName:string()
		If GetPlayerCollection().IsPlayer(owner)
			Return GetPlayerCollection().Get(owner).name
		Endif
		Return "UNKNOWN PLAYER"
	End Method


	Method GetOwnerChannelName:string()
		If GetPlayerCollection().IsPlayer(owner)
			Return GetPlayerCollection().Get(owner).channelName
		Endif
		Return "UNKNOWN CHANNEL"
	End Method


	'override to add playername/channelname replacement
	Method GetDescription:string(lineNumber:int=1) {_exposeToLua}
		local res:String = Super.GetDescription(lineNumber)
		if res.Find("%") = -1 then return res

		res = res.Replace("%PLAYERNAME%", GetOwnerPlayerName())
		res = res.Replace("%CHANNELNAME%", GetOwnerChannelName())

		return res
	End Method


	Method addHotspot:int( hotspot:THotspot )
		if hotspot then hotspots.addLast(hotspot);return TRUE
		return FALSE
	End Method


	'override to close all doors to a room
	Method FinishEnter:int(door:TRoomDoorBase, entity:TEntity)
		'=== CLOSE DOORS ===
		'close the door (for now: close all doors to this room)
		'which door to open?
		if not door
			For door = eachin TRoomDoor.GetDoorsToRoom(self)
				If door.GetDoorType() >= 0 then door.Close(entity)
			Next
		else
			Super.FinishEnter(door, entity)
		endif
	End Method


	'override to fetch main door if none was given
	Method FinishLeave:int(door:TRoomDoorBase, entity:TEntity)
		'open the door
		if not door then door = TRoomDoor.GetMainDoorToRoom(self)

		Super.FinishLeave(door, entity)
	End Method
End Type




Type TRoomDoorTooltip extends TTooltip
	Field roomID:int

	Function Create:TRoomDoorTooltip(title:String = "", content:String = "unknown", x:Int = 0, y:Int = 0, w:Int = -1, h:Int = -1, lifetime:Int = 300)
		local obj:TRoomDoorTooltip = new TRoomDoorTooltip
		obj.Initialize(title, content, x, y, w, h, lifetime)
		return obj
	End Function


	Method AssignRoom(roomID:int)
		self.roomID = roomID
	End Method


	'override to add "blocked" support
	Method DrawBackground:int(x:int, y:int, w:int, h:int)
		local room:TRoom = GetRoomCollection().Get(roomID)
		if not room then return False

		local oldCol:TColor = new TColor.Get()

		if room.IsBlocked()
			SetColor 255,235,215
		else
			SetColor 255,255,255
		endif
		DrawRect(x, y, w, h)

		oldCol.SetRGB()
	End Method


	'override to modify header col
	Method SetHeaderColor:int()
		local room:TRoom = GetRoomCollection().Get(roomID)
		if room and room.isBlocked()
			SetColor 250,230,210
		else
			Super.SetHeaderColor()
		endif
	End Method
	


	Method Update:Int()
		local room:TRoomBase = GetRoomBaseCollection().Get(roomID)
		if not room then return False

		'adjust image used in tooltip
		If room.name = "archive" Then tooltipimage = 0
		If room.name = "office" Then tooltipimage = 1
		If room.name = "boss" Then tooltipimage = 2
		If room.name = "news" Then tooltipimage = 4
		If room.name.Find("studio",0) = 0 Then tooltipimage = 5
		'adjust header bg color
		If room.owner >= 1 then
			TitleBGtype = room.owner + 10
		Else
			TitleBGtype = 0
		EndIf


		local newTitle:String = room.GetDescription(1)
		if newTitle <> title then SetTitle(newTitle)

		local newContent:String = room.GetDescription(2)
		if room.IsBlocked()
			'add line spacer
			if newContent<>"" then newContent :+ chr(13) + chr(13)
			'add blocked message
			newContent :+ GetLocale("ROOM_IS_BLOCKED")
		endif
		if newContent <> content then SetContent(newContent)

		Super.Update()
		return True
	End Method
End Type




Type TRoomDoor extends TRoomDoorBase  {_exposeToLua="selected"}
	'uses description
	Field showTooltip:Int = True
	Field tooltip:TRoomDoorTooltip = null
	Field _soundSource:TDoorSoundSource = Null {nosave}


	Method GenerateGUID:string()
		return "roomdoor-"+roomID+"-"+doorSlot+"-"+onFloor
	End Method


	'create room and use preloaded image
	Method Init:TRoomDoor(roomID:int, doorSlot:int=-1, onFloor:Int=0, doorType:Int=-1)
		'assign variables
		self.roomID = roomID

		DoorTimer.setInterval( TRoomBase.ChangeRoomSpeed )

		self.area = new TRectangle.Init(0, 0, GetSpriteFromRegistry("gfx_building_Tueren").framew, 52)
		self.doorSlot = doorSlot
		self.doorType = doorType
		self.onFloor = onFloor

		'generate a new guid
		SetGUID("")

		Return self
	End Method


	Method GetSoundSource:TDoorSoundSource()
		if not _soundSource then _soundSource = TDoorSoundSource.Create(self)
		return _soundSource
	End Method


	Method GetRoom:TRoom()
		if not roomID then return Null
		return GetRoomCollection().Get(roomID)
	End Method


	'override to play sound
	Method Close(entity:TEntity)
		if not TFigure(entity) then return
		
		'timer finished
		If Not DoorTimer.isExpired()
			GetSoundSource().PlayCloseDoorSfx(TFigure(entity))
		Endif
		
		Super.Close(entity)
	End Method


	'override to play sound
	Method Open(entity:TEntity)
		if not TFigure(entity) then return

		'timer ticks again
		If DoorTimer.isExpired()
			GetSoundSource().PlayOpenDoorSfx(TFigure(entity))
		Endif

		Super.Open(entity)
	End Method


	'override to add visibility support for rooms
	Method IsVisible:int()
		if not Super.IsVisible() then return False

		'skip invisible doors (without door-sprite)
		'Ronny TODO: maybe replace "invisible doors" with hotspots + room signes (if visible in elevator)
		local room:TRoom = GetRoom()
		If room = null then Return FALSE
		If room.name = "roomboard" OR room.name = "credits" OR room.name = "porter" then Return FALSE

		return True
	End Method


	Method DrawTooltip:Int()
		If not tooltip or not tooltip.enabled then return False

		tooltip.Render()
	End Method


	Function DrawAllTooltips:Int()
		For Local door:TRoomDoor = EachIn GetRoomDoorBaseCollection().List
			if door.showTooltip then door.DrawTooltip()
		Next
	End Function


	Method UpdateTooltip:Int()
		local room:TRoom = GetRoom()
		if not room then return False

		'only show tooltip if not "empty" and mouse in door-rect
		If room.GetDescription(1) <> "" and GetPlayer().GetFigure().IsInBuilding() And THelper.MouseIn(GetScreenX(), GetScreenY() - area.GetH(), area.GetW(), area.GetH())
			If not tooltip
				tooltip = TRoomDoorTooltip.Create("", "", 100, 140, 0, 0)
				tooltip.AssignRoom(room.id)
			endif

			tooltip.Hover()
			tooltip.enabled	= 1
		EndIf


		If tooltip AND tooltip.enabled
			if tooltip.Update()
				tooltip.area.position.SetY(GetScreenY() - area.GetH() - tooltip.GetHeight())
				tooltip.area.position.SetX(GetScreenX() + area.GetW()/2 - tooltip.GetWidth()/2)
			else
				'delete old tooltips
				tooltip = null
			endif
		EndIf
	End Method


	Function UpdateToolTips:Int()
		For Local door:TRoomDoor = EachIn GetRoomDoorBaseCollection().list
			'delete and skip if not found
			If not door
				GetRoomDoorBaseCollection().list.remove(door)
				continue
			Endif

			if door.showTooltip then door.UpdateTooltip()
		Next
	End Function


	Method Render:int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		local doorSprite:TSprite = GetSprite()

		'==== DRAW DOOR ====
		If getDoorType() >= 5
			If getDoorType() = 5 AND DoorTimer.isExpired() Then Close(null)
			'valign = 1 -> subtract sprite height
			doorSprite.Draw(xOffset + GetScreenX(), yOffset + GetScreenY(), getDoorType(), ALIGN_LEFT_BOTTOM)
		EndIf

		local room:TRoom = GetRoom()
		if not room then return False
		
		'==== DRAW DOOR OWNER SIGN ====
		'draw on same height than door startY
		If room.owner < 5 And room.owner >=0
			GetSpriteFromRegistry("gfx_building_sign_"+room.owner).Draw(xOffset + GetScreenX() + 2 + doorSprite.framew, yOffset + GetScreenY() - area.GetH())
		EndIf


		'==== DRAW OVERLAY ===
		if room.IsBlocked()
			'when a bomb is the reason - draw a barrier tape
			if room.blockedState = room.BLOCKEDSTATE_BOMB

				'is there is an explosion happening in that moment?
				'attention: not gametime but time (realtime effect)
				if room.bombExplosionTime + room.bombExplosionDuration > Time.GetTimeGone()
					local bombTimeGone:int = (Time.GetTimeGone() - room.bombExplosionTime)
					local scale:float = 1.0
					scale = TInterpolation.BackOut(0.0, 1.0, Min(room.bombExplosionDuration, bombTimeGone), room.bombExplosionDuration)
					scale :* TInterpolation.BounceOut(0.0, 1.0, Min(room.bombExplosionDuration, bombTimeGone), room.bombExplosionDuration)
					GetSpriteFromRegistry("gfx_building_explosion").Draw(xOffset + GetScreenX() + area.GetW()/2, yOffset + GetScreenY() - doorSprite.area.GetH()/2, -1, ALIGN_CENTER_CENTER, scale)
				else
					GetSpriteFromRegistry("gfx_building_blockeddoorsign").Draw(xOffset + GetScreenX(), yOffset + GetScreenY(), -1, ALIGN_LEFT_BOTTOM)
				endif
			EndIf
		EndIf


		'==== DRAW DEBUG TEXT ====
		if TVTDebugInfos
			local textY:int = GetScreenY() - area.GetH() - 10
			if room.hasOccupant()
				for local figure:TFigure = eachin room.occupants
					GetBitmapFontManager().basefont.Draw(figure.name, xOffset + GetScreenX(), yOffset + textY)
					textY:-10
				next
			else
				GetBitmapFontManager().basefont.Draw("empty", xOffset + GetScreenX(), yOffset + textY)
			endif
		endif
	End Method


	'override to return owner of room
	Method GetOwner:Int()
		local room:TRoom = GetRoom()
		if room then return room.owner
		return Super.GetOwner()
	End Method


	'override to add rooms description
	Method GetOwnerName:String()
		local room:TRoom = GetRoom()
		if room then return room.GetDescription(1)
		return super.GetOwnerName()
	End Method


	'returns the first door connected to a room
	Function GetDoorsToRoom:TRoomDoor[]( room:TRoomBase )
		local res:TRoomDoor[]
		if not room then return res

		For Local door:TRoomDoor = EachIn GetRoomDoorBaseCollection().list
			if door.GetRoom() = room then res :+ [door]
		Next
		return res
	End Function


	Function GetMainDoorToRoom:TRoomDoorBase( room:TRoomBase )
		'Ronny TODO: add configuration "mainDoor"
		'            or remove whole function and replace with
		'            "nearestDoorToRoom"
		local doors:TRoomDoorBase[] = GetDoorsToRoom(room)
		If doors.length = 0 then return Null
		return doors[0]
	End Function



	Function GetByDetails:TRoomDoor( name:String, owner:Int, floor:int =-1 )
		For Local door:TRoomDoor = EachIn GetRoomDoorBaseCollection().list
			'skip wrong floors
			if floor >=0 and door.GetOnFloor() <> floor then continue

			local room:TRoom = door.GetRoom()
			if not room then continue 
			'skip wrong owners
			if room.owner <> owner then continue

			If room.name = name Then Return door
		Next
		Return Null
	End Function


	'returns a door by the given (local to parent/building) coordinates
	Function GetByCoord:TRoomDoorBase( x:int, y:int )
		For Local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().list
			'also allow invisible rooms... so just check if hit the area
			'If room.doortype >= 0 and THelper.IsIn(x, y, room.Pos.x, Building.area.position.y + TBuilding.GetFloorY2(room.pos.y) - room.doorDimension.Y, room.doorDimension.x, room.doorDimension.y)
			If THelper.IsIn(x, y, door.area.GetX(), door.area.GetY() - door.area.GetH(), door.area.GetW(), door.area.GetH())
				Return door
			EndIf
		Next
		Return Null
	End Function
End Type



Type TRoomHandlerCollection
	Field handlers:TMap = CreateMap()
	'instead of a temporary variable
	Global currentHandler:TRoomHandler

	Global _instance:TRoomHandlerCollection
	Global _initDone:int = False


	Function GetInstance:TRoomHandlerCollection()
		if not _instance then _instance = new TRoomHandlerCollection
		if not _initDone then _instance.Initialize()
		return _instance
	End Function


	Method Initialize:int()
		if _initDone then return False
		_initDone = True

		EventManager.registerListenerFunction( "room.onUpdate", onHandleRoom )
		EventManager.registerListenerFunction( "room.onDraw", onHandleRoom )
		EventManager.registerListenerFunction( "room.onEnter", onHandleRoom )
		EventManager.registerListenerFunction( "room.onLeave", onHandleRoom )
		EventManager.registerListenerFunction( "figure.onTryLeaveRoom", onHandleFigureInRoom )
		EventManager.registerListenerFunction( "figure.onForcefullyLeaveRoom", onHandleFigureInRoom )

		EventManager.registerListenerFunction( "Language.onSetLanguage", onSetLanguage )
		'handle savegame loading
		EventManager.registerListenerFunction( "SaveGame.OnBeginLoad", onSaveGameBeginLoad )
		EventManager.registerListenerFunction( "SaveGame.OnLoad", onSaveGameLoad )
	End Method


	Method SetHandler(roomName:string, handler:TRoomHandler)
		handlers.insert(roomName, handler)
	End Method


	Method GetHandler:TRoomHandler(roomName:string = "")
		return TRoomHandler(handlers.ValueForKey(roomName))
	End Method





	'=== EVENTS FOR ALL HANDLERS ===
	
	Function onSetLanguage:int( triggerEvent:TEventBase )
		For local handler:TRoomHandler = EachIn GetInstance().handlers.Values()
			handler.SetLanguage()
		Next
	End Function
	

	Function onSaveGameBeginLoad:int( triggerEvent:TEventBase )
		For local handler:TRoomHandler = EachIn GetInstance().handlers.Values()
			handler.onSaveGameBeginLoad( triggerEvent )
		Next
	End Function


	Function onSaveGameLoad:int( triggerEvent:TEventBase )
		For local handler:TRoomHandler = EachIn GetInstance().handlers.Values()
			handler.onSaveGameLoad( triggerEvent )
		Next
	End Function




	'=== EVENTS FOR INDIVIDUAL HANDLERS ===
	Function onHandleFigureInRoom:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetReceiver())
		if not room then print "onHandleFigureInRoom: room stored elsewhere: "+triggerEvent._trigger.toLower()
		if not room then return 0

		currentHandler = GetInstance().GetHandler(room.name)
		if not currentHandler then return False

		Select triggerEvent._trigger.toLower()
			case "figure.ontryleaveroom"
				currentHandler.onTryLeaveRoom( triggerEvent )
			case "figure.onforcefullyleaveroom"
				currentHandler.onForcefullyLeaveRoom( triggerEvent )
		End Select
	End Function

	
	Function onHandleRoom:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetSender())
		if not room then print "onHandleRoom: room stored elsewhere: "+triggerEvent._trigger.toLower()
		if not room then return 0

		currentHandler = GetInstance().GetHandler(room.name)
		if not currentHandler then return False
		
		Select triggerEvent._trigger.toLower()
			case "room.onupdate"
				if KeyManager.IsHit(KEY_ESCAPE) then currentHandler.AbortScreenActions()
				currentHandler.onUpdateRoom( triggerEvent )
			case "room.ondraw"
				currentHandler.onDrawRoom( triggerEvent )
			case "room.onenter"
				currentHandler.onEnterRoom( triggerEvent )
			case "room.onleave"
				currentHandler.onLeaveRoom( triggerEvent )
		End Select
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetRoomHandlerCollection:TRoomHandlerCollection()
	Return TRoomHandlerCollection.GetInstance()
End Function



Type TRoomHandler
	Method onUpdateRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onDrawRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onLeaveRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onEnterRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onTryLeaveRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onSaveGameBeginLoad:int( triggerEvent:TEventBase ); return True; End Method
	Method onSaveGameLoad:int( triggerEvent:TEventBase ); return True; End Method
	'called to create all needed things (GUI) AND Reset
	Method Initialize:int() abstract
	'called to return to default state
	'Method Reset() abstract

	Method onForcefullyLeaveRoom:int( triggerEvent:TEventBase )
		'only handle the players figure
		if TFigure(triggerEvent.GetSender()) <> GetPlayer().figure then return False
		AbortScreenActions()
		return True;
	End Method


	'call this function if the visual user actions need to get aborted
	Method AbortScreenActions:Int(); End Method

	Method SetLanguage(); End Method


	'special events for screens used in rooms - only this event has the room as sender
	'screen.onScreenUpdate/Draw is more general purpose
	Function _RegisterScreenHandler(updateFunc(triggerEvent:TEventBase), drawFunc(triggerEvent:TEventBase), screen:TScreen)
		if screen
			EventManager.registerListenerFunction( "room.onScreenUpdate", updateFunc, screen )
			EventManager.registerListenerFunction( "room.onScreenDraw", drawFunc, screen )
		endif
	End Function


	Function CheckPlayerInRoom:int(roomName:string)
		'check if we are in the correct room
		local figure:TFigure = GetPlayer().GetFigure()
		If figure.isChangingRoom() Then Return False
		If not figure.inRoom Then Return False
		if figure.inRoom.name <> roomName then return FALSE
		return TRUE
	End Function


End Type


Include "game.screen.stationmap.bmx"
Include "game.screen.programmeplanner.bmx"
Include "game.screen.financials.bmx"
Include "game.screen.statistics.bmx"

'Office: handling the players room
Type RoomHandler_Office extends TRoomHandler
	'=== OFFICE ROOM ===
	Global StationsToolTip:TTooltip
	Global PlannerToolTip:TTooltip
	Global SafeToolTip:TTooltip

	Global _instance:RoomHandler_Office
	Global _initDone:int = False

	Function GetInstance:RoomHandler_Office()
		if not _instance then _instance = new RoomHandler_Office
		if not _initDone then _instance.Initialize()
		return _instance
	End Function

	
	Method Initialize:Int()
		if _initDone then return False
		_initDone = True
		'===== RUN SCREEN SPECIFIC INIT =====
		'(event connection etc.)
		TScreenHandler_StationMap.Init()
		TScreenHandler_ProgrammePlanner.Init()
		TScreenHandler_Financials.Init()
		TScreenHandler_Statistics.Init()


		GetRoomHandlerCollection().SetHandler("office", self)

		'===== REGISTER SCREEN HANDLERS =====
		'handle the "office" itself (not computer etc)
		'using this approach avoids "tooltips" to be visible in subscreens
		_RegisterScreenHandler( onUpdateOffice, onDrawOffice, ScreenCollection.GetScreen("screen_office") )
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		'
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'
	End Method


	Function onDrawOffice:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen( triggerEvent._sender )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'if room.GetBackground() then room.GetBackground().draw(0, 0)

		'allowed for owner only - or with key
		If GetPlayer().HasMasterKey() OR (room.owner = GetPlayerCollection().playerID)
			If StationsToolTip Then StationsToolTip.Render()
			'allowed for all - if having keys
			If PlannerToolTip Then PlannerToolTip.Render()

			If SafeToolTip Then SafeToolTip.Render()
		EndIf
	End Function


	Function onUpdateOffice:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0


		GetPlayer().GetFigure().fromroom = Null
		If MOUSEMANAGER.IsClicked(1)
			If THelper.IsIn(MouseManager.x,MouseManager.y,25,40,150,295)
				GetPlayer().GetFigure().LeaveRoom()
				MOUSEMANAGER.resetKey(1)
			EndIf
		EndIf


		'allowed for owner only - or with key
		If GetPlayer().HasMasterKey() OR (room.owner = GetPlayerCollection().playerID)
			Game.cursorstate = 0
			'safe - reachable for all
			If THelper.MouseIn(165,85,70,100)
				If not SafeToolTip Then SafeToolTip = TTooltip.Create(GetLocale("ROOM_SAFE"), GetLocale("FOR_PRIVATE_AFFAIRS"), 140, 100,-1,-1)
				SafeToolTip.enabled = 1
				SafeToolTip.minContentWidth = 150
				SafeToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0

					ScreenCollection.GoToSubScreen("screen_office_safe")
				endif
			EndIf

			'planner - reachable for all
			If THelper.IsIn(MouseManager.x, MouseManager.y, 600,140,128,210)
				If not PlannerToolTip Then PlannerToolTip = TTooltip.Create(GetLocale("ROOM_PROGRAMMEPLANNER"), GetLocale("AND_STATISTICS"), 580, 140)
				PlannerToolTip.enabled = 1
				PlannerToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0
					ScreenCollection.GoToSubScreen("screen_office_programmeplanner")
				endif
			EndIf

			If THelper.IsIn(MouseManager.x, MouseManager.y, 732,45,160,170)
				If not StationsToolTip Then StationsToolTip = TTooltip.Create(GetLocale("ROOM_STATIONMAP"), GetLocale("BUY_AND_SELL"), 650, 80, 0, 0)
				StationsToolTip.enabled = 1
				StationsToolTip.Hover()
				Game.cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					Game.cursorstate = 0
					ScreenCollection.GoToSubScreen("screen_office_stationmap")
				endif
			EndIf

			If StationsToolTip Then StationsToolTip.Update()
			If PlannerToolTip Then PlannerToolTip.Update()
			If SafeToolTip Then SafeToolTip.Update()
		EndIf
	End Function
End Type



'Archive: handling of players programmearchive - for selling it later, ...
Type RoomHandler_Archive extends TRoomHandler
	Field hoveredGuiProgrammeLicence:TGuiProgrammeLicence = null
	Field draggedGuiProgrammeLicence:TGuiProgrammeLicence = null
	Field openCollectionTooltip:TTooltip

	Field programmeList:TgfxProgrammelist
	Field haveToRefreshGuiElements:int = TRUE
	Field GuiListSuitcase:TGUIProgrammeLicenceSlotList = null
	Field DudeArea:TGUISimpleRect	'allows registration of drop-event

	'configuration
	Field suitcasePos:TVec2D				= new TVec2D.Init(40,270)
	Field suitcaseGuiListDisplace:TVec2D	= new TVec2D.Init(14,25)

	Global _instance:RoomHandler_Archive


	Function GetInstance:RoomHandler_Archive()
		if not _instance
			_instance = new RoomHandler_Archive
			_instance.Initialize()
		endif
		return _instance
	End Function


	Method Initialize:int()
		'===== CREATE GUI LISTS =====
		GuiListSuitcase	= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(200, 80), "archive")
		GuiListSuitcase.guiEntriesPanel.minSize.SetXY(200,80)
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.acceptType		= TGUIProgrammeLicenceSlotList.acceptAll
		GuiListSuitcase.SetItemLimit(GameRules.maxProgrammeLicencesInSuitcase)
		GuiListSuitcase.SetSlotMinDimension(GetSpriteFromRegistry("gfx_movie_undefined").area.GetW(), GetSpriteFromRegistry("gfx_movie_undefined").area.GetH())
		GuiListSuitcase.SetAcceptDrop("TGUIProgrammeLicence")

		DudeArea = new TGUISimpleRect.Create(new TVec2D.Init(600,100), new TVec2D.Init(200, 350), "archive" )
		'dude should accept drop - else no recognition
		DudeArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)

		programmeList = New TgfxProgrammelist.Create(720, 10)


		'===== REGISTER EVENTS =====
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "guiobject.OnMouseOver", onMouseOverProgrammeLicence, "TGUIProgrammeLicence" )
		'drop programme ... so sell/buy the thing
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropProgrammeLicence, "TGUIProgrammeLicence" )
		'drop programme on dude - add back to player's collection
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropProgrammeLicenceOnDude, "TGUIProgrammeLicence" )
		'check right clicks on a gui block
		EventManager.registerListenerFunction( "guiobject.onClick", onClickProgrammeLicence, "TGUIProgrammeLicence" )


		'register self for all archives-rooms
		GetRoomHandlerCollection().SetHandler("archive", self)
	End Method


	'override: clear the screen (remove dragged elements)
	Method AbortScreenActions:Int()
		'abort handling dragged elements
		If draggedGuiProgrammeLicence
			draggedGuiProgrammeLicence.dropBackToOrigin()
			'remove in all cases
			draggedGuiProgrammeLicence = null
			hoveredGuiProgrammeLicence = null
		EndIf
	End Method


	'override
	Method onSaveGameBeginLoad( triggerEvent:TEventBase )
		'for further explanation of this, check
		'RoomHandler_Office.onSaveGameBeginLoad()

		hoveredGuiProgrammeLicence = null
		draggedGuiProgrammeLicence = null
		GuiListSuitcase.EmptyList()

		haveToRefreshGuiElements = true
	End Method


	'override
	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE

		'if the list is open - just close the list and veto against
		'leaving the room
		if programmeList.openState <> 0
			programmeList.SetOpen(0)
			triggerEvent.SetVeto()
			return FALSE
		endif

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammeLicence
			triggerEvent.setVeto()
			return FALSE
		endif

		return TRUE
	End Method


	'remove suitcase licences from a players programme plan
	Method onLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or not figure.playerID then return FALSE

		'remove all licences in the suitcase from the programmeplan
		local plan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(figure.playerID)
		For local licence:TProgrammeLicence = EachIn GetPlayerProgrammeCollectionCollection().Get(figure.playerID).suitcaseProgrammeLicences
			plan.RemoveProgrammeInstancesByLicence(licence, true)
		Next

		'close the list if open
		'programmeList.SetOpen(0)
		
		return TRUE
	End Method


	'called as soon as a players figure is forced to leave the room
	Method onForcefullyLeaveRoom:int( triggerEvent:TEventBase )
		if not super.onForcefullyLeaveRoom(triggerEvent) then return False

		'instead of leaving the room and accidentially removing programmes
		'from the plan we readd all licences from the suitcase back to
		'the players collection
		GetPlayerProgrammeCollectionCollection().Get(GetPlayer().playerID).ReaddProgrammeLicencesFromSuitcase()
	End Method


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with licences the player does not have any
		'longer in the suitcase

		'suitcase
		For local guiLicence:TGUIProgrammeLicence = eachin GuiListSuitcase._slots
			'if the player has this licence in suitcase, skip deletion
			if GetPlayer().GetProgrammeCollection().HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
			guiLicence = null
		Next

		'===== CREATE NEW =====
		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayer().GetProgrammeCollection().suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem(new TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
			'print "ADD suitcase had missing licence: "+licence.getTitle()
		Next

		haveToRefreshGuiElements = FALSE
	End Method



	'in case of right mouse button click we want to add back the
	'dragged block to the player's programmeCollection
	Function onClickProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("archive") then return FALSE
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiBlock or not guiBlock.isDragged() then return FALSE

		'add back to collection if already dropped it to suitcase before
		if not GetPlayer().GetProgrammeCollection().HasProgrammeLicence(guiBlock.licence)
			GetPlayer().GetProgrammeCollection().RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
		endif
		'remove the gui element
		guiBlock.remove()
		guiBlock = null

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	Function onDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("archive") then return FALSE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiBlock or not receiverList then return FALSE

		local owner:int = guiBlock.licence.owner

		select receiverList
			case GetInstance().GuiListSuitcase
				'check if still in collection - if so, remove
				'from collection and add to suitcase
				if GetPlayer().GetProgrammeCollection().HasProgrammeLicence(guiBlock.licence)
					'remove gui - a new one will be generated automatically
					'as soon as added to the suitcase and the room's update
					guiBlock.remove()

					'if not able to add to suitcase (eg. full), cancel
					'the drop-event
					if not GetPlayer().GetProgrammeCollection().AddProgrammeLicenceToSuitcase(guiBlock.licence)
						triggerEvent.setVeto()
					endif
					
					guiBlock = null
				endif

				'else it is just a "drop back"
				return TRUE
		end select

		return TRUE
	End Function


	'handle cover block drops on the dude
	Function onDropProgrammeLicenceOnDude:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("archive") then return FALSE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver then return FALSE
		if receiver <> GetInstance().DudeArea then return FALSE

		'add back to collection
		GetPlayer().GetProgrammeCollection().RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
		'remove the gui element
		guiBlock.remove()
		guiBlock = null

		return TRUE
	End function


	Function onMouseOverProgrammeLicence:int( triggerEvent:TEventBase )
		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		GetInstance().hoveredGuiProgrammeLicence = item
		if item.isDragged()
			GetInstance().draggedGuiProgrammeLicence = item
			'if we have an item dragged... we cannot have a menu open
			GetInstance().programmeList.SetOpen(0)
		endif

		return TRUE
	End Function


	'clear the guilist for the suitcase if a player enters
	Method onEnterRoom:int( triggerEvent:TEventBase )
		'we are not interested in other figures than our player's
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or GetPlayerBase().GetFigure() <> figure then return FALSE

		'when entering the archive, all scripts are moved from the
		'suitcase to the collection
		'TODO: mark these scripts as "new" 
		GetPlayerProgrammeCollection(figure.playerID).MoveScriptsFromSuitcaseToArchive()


		'empty the guilist / delete gui elements
		'- the real list still may contain elements with gui-references
		guiListSuitcase.EmptyList()
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		'only draw custom elements for players room
		local room:TRoom = TRoom(triggerEvent._sender)
		if room.owner <> GetPlayerCollection().playerID then return FALSE

		programmeList.Draw()

		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		if draggedGuiProgrammeLicence then glowSuitcase = "_glow"
		'draw suitcase
		GetSpriteFromRegistry("gfx_suitcase"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		GUIManager.Draw("archive")

		'draw dude tooltip
		If openCollectionTooltip Then openCollectionTooltip.Render()


		'show sheet from hovered list entries
		if programmeList.hoveredLicence
			programmeList.hoveredLicence.ShowSheet(30,20)
		endif
		'show sheet from hovered suitcase entries
		if hoveredGuiProgrammeLicence
			'draw the current sheet
			hoveredGuiProgrammeLicence.DrawSheet()
		endif
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'only handle custom elements for players room
		local room:TRoom = TRoom(triggerEvent._sender)
		if room.owner <> GetPlayerCollection().playerID then return FALSE

		Game.cursorstate = 0

		'open list when clicking dude
		if not draggedGuiProgrammeLicence
			If not programmeList.GetOpen()
				if THelper.IsIn(MouseManager.x, MouseManager.y, 605,65,160,90) Or THelper.IsIn(MouseManager.x, MouseManager.y, 525,155,240,225)
					'activate tooltip
					If not openCollectionTooltip Then openCollectionTooltip = TTooltip.Create(GetLocale("PROGRAMMELICENCES"), GetLocale("SELECT_LICENCES_FOR_SALE"), 470, 130, 0, 0)
					openCollectionTooltip.enabled = 1
					openCollectionTooltip.Hover()

					Game.cursorstate = 1
					If MOUSEMANAGER.IsHit(1)
						MOUSEMANAGER.resetKey(1)
						Game.cursorstate = 0
						programmeList.SetOpen(1)
					endif
				EndIf
			endif
			programmeList.enabled = TRUE
		else
			'disable list if we have a dragged guiobject
			programmeList.enabled = FALSE
		endif
		programmeList.Update(TgfxProgrammelist.MODE_ARCHIVE)

		'handle tooltip
		If openCollectionTooltip Then openCollectionTooltip.Update()


		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayer().GetProgrammeCollection().suitcaseProgrammeLicences
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
	End Method
End Type


'Movie agency
Type RoomHandler_MovieAgency extends TRoomHandler
	Global AuctionToolTip:TTooltip

	Global VendorEntity:TSpriteEntity
	Global VendorArea:TGUISimpleRect	'allows registration of drop-event

	Global AuctionEntity:TSpriteEntity

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
	Global suitcasePos:TVec2D = new TVec2D.Init(350,130)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(14,25)
	Field programmesPerLine:int	= 13
	Field movieCheapMaximum:int	= 50000

	Global _instance:RoomHandler_MovieAgency
	Global _initDone:int = FALSE


	Function GetInstance:RoomHandler_MovieAgency()
		if not _instance then _instance = new RoomHandler_MovieAgency
		if not _initDone then _instance.Initialize()
		return _instance
	End Function


	Method Initialize:int()
		if _initDone then return FALSE

		'resize arrays
		listMoviesGood	= listMoviesGood[..programmesPerLine]
		listMoviesCheap	= listMoviesCheap[..programmesPerLine]
		listSeries		= listSeries[..programmesPerLine]

		GuiListMoviesGood	= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(596,50), new TVec2D.Init(220,80), "movieagency")
		GuiListMoviesCheap	= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(596,148), new TVec2D.Init(220,80), "movieagency")
		GuiListSeries		= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(596,246), new TVec2D.Init(220,80), "movieagency")
		GuiListSuitcase		= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(200,80), "movieagency")

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
		GuiListSuitcase.SetItemLimit(GameRules.maxProgrammeLicencesInSuitcase)

		local videoCase:TSprite = GetSpriteFromRegistry("gfx_movie_undefined")

		GuiListMoviesGood.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())
		GuiListMoviesCheap.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())
		GuiListSeries.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())
		GuiListSuitcase.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())

		GuiListMoviesGood.SetAcceptDrop("TGUIProgrammeLicence")
		GuiListMoviesCheap.SetAcceptDrop("TGUIProgrammeLicence")
		GuiListSeries.SetAcceptDrop("TGUIProgrammeLicence")
		GuiListSuitcase.SetAcceptDrop("TGUIProgrammeLicence")

		VendorEntity = GetSpriteEntityFromRegistry("entity_movieagency_vendor")
		AuctionEntity = GetSpriteEntityFromRegistry("entity_movieagency_auction")

		'default vendor position/dimension
		local vendorAreaDimension:TVec2D = new TVec2D.Init(200,200)
		local vendorAreaPosition:TVec2D = new TVec2D.Init(20,60)
		if VendorEntity then vendorAreaDimension = VendorEntity.area.dimension.copy()
		if VendorEntity then vendorAreaPosition = VendorEntity.area.position.copy()

		VendorArea = new TGUISimpleRect.Create(vendorAreaPosition, vendorAreaDimension, "movieagency" )
		'vendor should accept drop - else no recognition
		VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)



		'drop ... so sell/buy the thing
		EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammeLicence, "TGUIProgrammeLicence" )
		EventManager.registerListenerFunction("guiobject.onDropOnTarget", onDropProgrammeLicence, "TGUIProgrammeLicence")
		'is dragging even allowed? - eg. intercept if not enough money
		EventManager.registerListenerFunction("guiobject.onDrag", onDragProgrammeLicence, "TGUIProgrammeLicence")
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverProgrammeLicence, "TGUIProgrammeLicence")
		'drop on vendor - sell things
		EventManager.registerListenerFunction("guiobject.onDropOnTarget", onDropProgrammeLicenceOnVendor, "TGUIProgrammeLicence")

		super._RegisterScreenHandler( onUpdateMovieAgency, onDrawMovieAgency, ScreenCollection.GetScreen("screen_movieagency"))
		super._RegisterScreenHandler( onUpdateMovieAuction, onDrawMovieAuction, ScreenCollection.GetScreen("screen_movieauction"))


		'register self for movieagency
		GetRoomHandlerCollection().SetHandler("movieagency", self)

		_initDone = true
	End Method


	Method AbortScreenActions:Int()
		if draggedGuiProgrammeLicence
			'try to drop the licence back
			draggedGuiProgrammeLicence.dropBackToOrigin()
			draggedGuiProgrammeLicence = null
			hoveredGuiProgrammeLicence = null
		endif
	End Method


	Method onSaveGameBeginLoad( triggerEvent:TEventBase )
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new programmes are not loaded yet

		GetInstance().RemoveAllGuiElements()
		haveToRefreshGuiElements = true
	End Method


	'clear the guilist for the suitcase if a player enters
	Method onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure then return FALSE

		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure.playerID then return False

		'fill all open slots in the agency
		GetInstance().ReFillBlocks()
	End Method


	'override: figure leaves room - only without dragged blocks
	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammeLicence
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Method


	'add back the programmes from the suitcase
	'also fill empty blocks, remove gui elements
	Method onLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or not figure.playerID then return FALSE

		GetPlayerProgrammeCollection(figure.playerID).ReaddProgrammeLicencesFromSuitcase()

		return TRUE
	End Method


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

		if not GetPlayerCollection().IsPlayer(playerID) then return FALSE

		'try to add to suitcase of player
		if not GetPlayerProgrammeCollectionCollection().Get(playerID).AddProgrammeLicenceToSuitcase(licence)
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
		if GetPlayerCollection().IsPlayer(licence.owner)
			GetPlayerProgrammeCollectionCollection().Get(licence.owner).RemoveProgrammeLicence(licence, TRUE)
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
			guiLicence = null
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
			if GetPlayerProgrammeCollectionCollection().Get(GetPlayerCollection().playerID).HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
			guiLicence = null
		Next
		'agency lists
		local lists:TProgrammeLicence[][] = [ listMoviesGood,listMoviesCheap,listSeries ]
		local guiLists:TGUIProgrammeLicenceSlotList[] = [ guiListMoviesGood, guiListMoviesCheap, guiListSeries ]
		For local j:int = 0 to guiLists.length-1
			For local guiLicence:TGUIProgrammeLicence = eachin guiLists[j]._slots
				if HasProgrammeLicence(guiLicence.licence) then continue

				'print "REM lists"+j+" has obsolete licence: "+guiLicence.licence.getTitle()
				guiLicence.remove()
				guiLicence = null
			Next
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all programme-lists

		For local j:int = 0 to lists.length-1
			For local licence:TProgrammeLicence = eachin lists[j]
				if not licence then continue
				if guiLists[j].ContainsLicence(licence) then continue


				local lic:TGUIProgrammeLicence = new TGUIProgrammeLicence.CreateWithLicence(licence)
				'if adding to list was not possible, remove the licence again
				if not guiLists[j].addItem(lic,"-1" )
					GUIManager.Remove(lic)
				endif
				
				'print "ADD lists"+j+" had missing licence: "+licence.getTitle()
			Next
		Next

		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayerProgrammeCollectionCollection().Get(GetPlayerCollection().playerID).suitcaseProgrammeLicences
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

				if lists[j] = listMoviesGood then licence = GetProgrammeLicenceCollection().GetRandomWithPrice(75000,-1, TVTProgrammeLicenceType.MOVIE)
				if lists[j] = listMoviesCheap then licence = GetProgrammeLicenceCollection().GetRandomWithPrice(0,75000, TVTProgrammeLicenceType.MOVIE)
				if lists[j] = listSeries then licence = GetProgrammeLicenceCollection().GetRandom(TVTProgrammeLicenceType.SERIES)

				'add new licence at slot
				if licence
					licence.owner = -1
					lists[j][i] = licence
				else
					if not warnedOfMissingLicence
						TLogger.log("MovieAgency.RefillBlocks()", "Not enough licences to refill slot["+i+"+] in list["+j+"]", LOG_WARNING | LOG_DEBUG)
						warnedOfMissingLicence = TRUE
					endif
				endif
			Next
		Next
	End Method


	'===================================
	'Movie Agency: All screens
	'===================================

	'can be done for all, as the order of handling that event
	'does not care ... just update animations is important
	Method onUpdateRoom:int( triggerEvent:TEventBase )
		Super.onUpdateRoom(triggerEvent)

		if AuctionEntity Then AuctionEntity.Update()
		if VendorEntity Then VendorEntity.Update()
	End Method

	
	'===================================
	'Movie Agency: Room screen
	'===================================


	Function onMouseOverProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProgrammeLicence = item
		if item.isDragged() then draggedGuiProgrammeLicence = item

		return TRUE
	End Function


	'check if we are allowed to drag that licence
	Function onDragProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		local owner:int = item.licence.owner

		'do not allow dragging items from other players
		if owner > 0 and owner <> GetPlayerCollection().playerID
			triggerEvent.setVeto()
			return FALSE
		endif

		'check whether a player could afford the licence
		'if not - just veto the event so it does not get dragged
		if owner <= 0
			if not GetPlayer().getFinance().canAfford(item.licence.getPrice())
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Function


	'- check if dropping on suitcase and affordable
	'- check if dropping on an item which is not affordable
	Function onTryDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiLicence or not receiverList then return FALSE

		local owner:int = guiLicence.licence.owner

		select receiverList
			case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'check if something is underlaying and whether the
				'player could afford it
				local underlayingItem:TGUIProgrammeLicence = null
				local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", new TVec2D.Init(-1,-1)))
				if coord then underlayingItem = TGUIProgrammeLicence(receiverList.GetItemByCoord(coord))

				'allow drop on own place
				if underlayingItem = guiLicence then return TRUE

				if underlayingItem and not GetPlayer().getFinance().canAfford(underlayingItem.licence.getPrice())
					triggerEvent.SetVeto()
					return FALSE
				endif
			case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				if guiLicence.licence.owner = GetPlayerCollection().playerID then return TRUE

				if not GetPlayer().getFinance().canAfford(guiLicence.licence.getPrice())
					triggerEvent.setVeto()
				endif
		End select

		return TRUE
	End Function


	'dropping takes place - sell/buy licences or veto if not possible
	Function onDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

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
				if guiLicence.licence.owner = GetPlayerCollection().playerID then return TRUE

				if not GetInstance().SellProgrammeLicenceToPlayer(guiLicence.licence, GetPlayerCollection().playerID)
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
		if not CheckPlayerInRoom("movieagency") then return FALSE

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
		if AuctionEntity Then AuctionEntity.Render()
		if VendorEntity Then VendorEntity.Render()
		GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		'make auction/suitcase/vendor highlighted if needed
		local highlightSuitcase:int = False
		local highlightVendor:int = False
		local highlightAuction:int = False

		'sometimes a draggedGuiProgrammeLicence is defined in an update
		'but isnt dragged anymore (will get removed in the next tick)
		'the dragged check avoids that the vendor is highlighted for
		'1-2 render frames
		if draggedGuiProgrammeLicence and draggedGuiProgrammeLicence.isDragged()
			if draggedGuiProgrammeLicence.licence.owner <= 0
				highlightSuitcase = True
			else
				highlightVendor = True
			endif
		else
			If AuctionEntity and AuctionEntity.GetScreenArea().ContainsXY(MouseManager.x, MouseManager.y)
				highlightAuction = True
			EndIf
		endif

		if highlightAuction or highlightVendor or highlightSuitcase
			local oldCol:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * (0.4 + 0.2 * sin(Time.GetTimeGone() / 5))

			if AuctionEntity and highlightAuction then AuctionEntity.Render()
			if VendorEntity and highlightVendor then VendorEntity.Render()
			if highlightSuitcase then GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		endif


		SetAlpha 0.5
		local fontColor:TColor = TColor.CreateGrey(50)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("MOVIES"),		642,  27+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SPECIAL_BIN"),	642, 125+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SERIES"), 		642, 223+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")

		if hoveredGuiProgrammeLicence
			'draw the current sheet
			hoveredGuiProgrammeLicence.DrawSheet()
		endif


		If AuctionToolTip Then AuctionToolTip.Render()
	End Function


	Function onUpdateMovieAgency:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.cursorstate = 0

		'show a auction-tooltip (but not if we dragged a block)
		if not hoveredGuiProgrammeLicence
			If THelper.IsIn(MouseManager.x, MouseManager.y, 210,220,140,60)
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

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiProgrammeLicence = null
		'reset dragged block too
		draggedGuiProgrammeLicence = null

		GUIManager.Update("movieagency")

		If AuctionToolTip Then AuctionToolTip.Update()
	End Function



	'===================================
	'Movie Agency: Room screen
	'===================================

	Function onDrawMovieAuction:int( triggerEvent:TEventBase )
		if AuctionEntity Then AuctionEntity.Render()
		if VendorEntity Then VendorEntity.Render()
		GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		SetAlpha 0.5
		local fontColor:TColor = TColor.CreateGrey(50)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("MOVIES"),		642,  27+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SPECIAL_BIN"),	642, 125+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SERIES"), 		642, 223+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")
		SetAlpha 0.2;SetColor 0,0,0
		DrawRect(0,0,800,385)
		SetAlpha 1.0;SetColor 255,255,255

		GetSpriteFromRegistry("gfx_gui_panel").DrawArea(120-15,60-15,555+30,290+30)
		GetSpriteFromRegistry("gfx_gui_panel.content").DrawArea(120,60,555,290)

		SetAlpha 0.5
		GetBitmapFont("Default",12,BOLDFONT).drawBlock(GetLocale("CLICK_ON_MOVIE_OR_SERIES_TO_PLACE_BID"), 140,317, 535,30, new TVec2D.Init(ALIGN_CENTER), TColor.CreateGrey(50), 2, 1, 0.20)
		SetAlpha 1.0

		TAuctionProgrammeBlocks.DrawAll()
	End Function

	Function onUpdateMovieAuction:int( triggerEvent:TEventBase )
		Game.cursorstate = 0
		TAuctionProgrammeBlocks.UpdateAll()

		'remove old tooltips from previous screens
		If AuctionToolTip Then AuctionToolTip = null
	End Function
End Type


'News room
Type RoomHandler_News extends TRoomHandler
	Global PlannerToolTip:TTooltip
	Global NewsGenreButtons:TGUIButton[5]
	Global NewsGenreTooltip:TTooltip			'the tooltip if hovering over the genre buttons
	Global currentRoom:TRoom					'holding the currently updated room (so genre buttons can access it)
	'the image displaying "send news"
	Global newsPlannerTextImage:TImage = null

	'lists for visually placing news blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global guiNewsListAvailable:TGUINewsList
	Global guiNewsListUsed:TGUINewsSlotList
	Global draggedGuiNews:TGuiNews = null
	Global hoveredGuiNews:TGuiNews = null

	Global _instance:RoomHandler_News
	Global _initDone:int = False


	Function GetInstance:RoomHandler_News()
		if not _instance then _instance = new RoomHandler_News
		if not _initDone then _instance.Initialize()
		return _instance
	End Function


	Method Initialize:int()
		if _initDone then return False
		_initDone = True
		
		'create genre buttons
		'ATTENTION: We could do this in order of The NewsGenre-Values
		'           But better add it to the buttons.data-property
		'           for better checking
		NewsGenreButtons[0]	= new TGUIButton.Create( new TVec2D.Init(15, 194), null, GetLocale("NEWS_TECHNICS_MEDIA"), "newsroom")
		NewsGenreButtons[1]	= new TGUIButton.Create( new TVec2D.Init(64, 194), null, GetLocale("NEWS_POLITICS_ECONOMY"), "newsroom")
		NewsGenreButtons[2]	= new TGUIButton.Create( new TVec2D.Init(15, 247), null, GetLocale("NEWS_SHOWBIZ"), "newsroom")
		NewsGenreButtons[3]	= new TGUIButton.Create( new TVec2D.Init(64, 247), null, GetLocale("NEWS_SPORT"), "newsroom")
		NewsGenreButtons[4]	= new TGUIButton.Create( new TVec2D.Init(113, 247), null, GetLocale("NEWS_CURRENTAFFAIRS"), "newsroom")
		for local i:int = 0 to 4
			NewsGenreButtons[i].SetAutoSizeMode( TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE )
			'adjust width according sprite dimensions
			NewsGenreButtons[i].spriteName = "gfx_news_btn"+i
			'disable drawing of caption
			NewsGenreButtons[i].caption.Hide()
		Next

		'add news genre to button data
		NewsGenreButtons[0].data.AddNumber("newsGenre", TNewsEvent.GENRE_TECHNICS)
		NewsGenreButtons[1].data.AddNumber("newsGenre", TNewsEvent.GENRE_POLITICS)
		NewsGenreButtons[2].data.AddNumber("newsGenre", TNewsEvent.GENRE_SHOWBIZ)
		NewsGenreButtons[3].data.AddNumber("newsGenre", TNewsEvent.GENRE_SPORT)
		NewsGenreButtons[4].data.AddNumber("newsGenre", TNewsEvent.GENRE_CURRENTS)


		'we are interested in the genre buttons
		for local i:int = 0 until len( NewsGenreButtons )
			EventManager.registerListenerFunction( "guiobject.onMouseOver", onHoverNewsGenreButtons, NewsGenreButtons[i] )
			EventManager.registerListenerFunction( "guiobject.onDraw", onDrawNewsGenreButtons, NewsGenreButtons[i] )
			EventManager.registerListenerFunction( "guiobject.onClick", onClickNewsGenreButtons, NewsGenreButtons[i] )
		Next

		'create the lists in the news planner
		'we add 2 pixel to the height to make "auto scrollbar" work better
		guiNewsListAvailable = new TGUINewsList.Create(new TVec2D.Init(15,16), new TVec2D.Init(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(), 4*GetSpriteFromRegistry("gfx_news_sheet0").area.GetH()), "Newsplanner")
		guiNewsListAvailable.SetAcceptDrop("TGUINews")
		guiNewsListAvailable.Resize(guiNewsListAvailable.rect.GetW() + guiNewsListAvailable.guiScrollerV.rect.GetW() + 8,guiNewsListAvailable.rect.GetH())
		guiNewsListAvailable.guiEntriesPanel.minSize.SetXY(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(),356)

		guiNewsListUsed = new TGUINewsSlotList.Create(new TVec2D.Init(420,106), new TVec2D.Init(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(), 3*GetSpriteFromRegistry("gfx_news_sheet0").area.GetH()), "Newsplanner")
		guiNewsListUsed.SetItemLimit(3)
		guiNewsListUsed.SetAcceptDrop("TGUINews")
		guiNewsListUsed.SetSlotMinDimension(0,GetSpriteFromRegistry("gfx_news_sheet0").area.GetH())
		guiNewsListUsed.SetAutofillSlots(false)
		guiNewsListUsed.guiEntriesPanel.minSize.SetXY(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(),3*GetSpriteFromRegistry("gfx_news_sheet0").area.GetH())

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
		EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverNews, "TGUINews" )

		'for all news rooms - register if someone goes into the planner
		local screen:TScreen = ScreenCollection.GetScreen("screen_newsstudio_newsplanner")
		'figure enters screen - reset the guilists, limit listening to the 4 rooms
		if screen then EventManager.registerListenerFunction("screen.onEnter", onEnterNewsPlannerScreen, screen)
		'also we want to interrupt leaving a room with dragged items
		EventManager.registerListenerFunction("screen.OnLeave", onLeaveNewsPlannerScreen, screen)

		super._RegisterScreenHandler( onUpdateNews, onDrawNews, ScreenCollection.GetScreen("screen_newsstudio") )
		super._RegisterScreenHandler( onUpdateNewsPlanner, onDrawNewsPlanner, ScreenCollection.GetScreen("screen_newsstudio_newsplanner") )

		'register self for all news rooms
		GetRoomHandlerCollection().SetHandler("news", self)
	End Method


	Method AbortScreenActions:Int()
		if draggedGuiNews
			'try to drop the licence back
			draggedGuiNews.dropBackToOrigin()
			draggedGuiNews = null
			hoveredGuiNews = null
		endif

		'Try to drop back dragged elements
		For local obj:TGUINews = eachIn GuiManager.ListDragged
			obj.dropBackToOrigin()
			'successful or not - get rid of the gui element
			obj.Remove()
		Next
	End Method


	Method onSaveGameBeginLoad( triggerEvent:TEventBase )
		'for further explanation of this, check
		'RoomHandler_Office.onSaveGameBeginLoad()

		hoveredGuiNews = null
		draggedGuiNews = null

		RemoveAllGuiElements()
	End Method


	'===================================
	'News: room screen
	'===================================


	Function onDrawNews:int( triggerEvent:TEventBase )
		GUIManager.Draw("newsroom")
		If PlannerToolTip Then PlannerToolTip.Render()
		If NewsGenreTooltip then NewsGenreTooltip.Render()

	End Function


	Function onUpdateNews:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'store current room for later access (in guiobjects)
		currentRoom = room

		GUIManager.Update("newsroom")

		Game.cursorstate = 0
		If PlannerToolTip Then PlannerToolTip.Update()
		If NewsGenreTooltip Then NewsGenreTooltip.Update()

		'pinwall
		If THelper.IsIn(MouseManager.x, MouseManager.y, 167,60,240,160)
			If not PlannerToolTip Then PlannerToolTip = TTooltip.Create("Newsplaner", "Hinzufügen und entfernen", 180, 100, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsClicked(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				ScreenCollection.GoToSubScreen("screen_newsstudio_newsplanner")
			endif
		endif
	End Function


	'could handle the buttons in one function ( by comparing triggerEvent._trigger )
	'onHover: handle tooltip
	Function onHoverNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0


		'how much levels do we have?
		local level:int = 0
		local genre:int = -1
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				genre = button.data.GetInt("newsGenre", i)
				level = GetPlayerCollection().Get(room.owner).GetNewsAbonnement( genre )
				exit
			endif
		Next

		if not NewsGenreTooltip then NewsGenreTooltip = TTooltip.Create("genre", "abonnement", 180,100 )
		NewsGenreTooltip.minContentWidth = 180
		NewsGenreTooltip.enabled = 1
		'refresh lifetime
		NewsGenreTooltip.Hover()

		'move the tooltip
		NewsGenreTooltip.area.position.SetXY(Max(21,button.rect.GetX() + button.rect.GetW()), button.rect.GetY()-30)

		If level = 0
			NewsGenreTooltip.title = button.caption.GetValue()+" - "+getLocale("NEWSSTUDIO_NOT_SUBSCRIBED")
			NewsGenreTooltip.content = getLocale("NEWSSTUDIO_SUBSCRIBE_GENRE_LEVEL")+" 1: "+ TNewsAgency.GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
		Else
			NewsGenreTooltip.title = button.caption.GetValue()+" - "+getLocale("NEWSSTUDIO_SUBSCRIPTION_LEVEL")+" "+level
			if level = GameRules.maxAbonnementLevel
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_DONT_SUBSCRIBE_GENRE_ANY_LONGER")+ ": 0" + getLocale("CURRENCY")
			Else
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_NEXT_SUBSCRIPTION_LEVEL")+": "+ TNewsAgency.GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
			EndIf
		EndIf
		if GetPlayer().GetNewsAbonnementDaysMax(genre) > level
			NewsGenreTooltip.content :+ "~n~n"
			local tip:String = getLocale("NEWSSTUDIO_YOU_ALREADY_USED_LEVEL_AND_THEREFOR_PAY")
			tip = tip.Replace("%MAXLEVEL%", GetPlayer().GetNewsAbonnementDaysMax(genre))
			tip = tip.Replace("%TOPAY%", TNewsAgency.GetNewsAbonnementPrice(GetPlayer().GetNewsAbonnementDaysMax(genre)) + getLocale("CURRENCY"))
			NewsGenreTooltip.content :+ getLocale("HINT")+": " + tip
		endif
	End Function


	Function onClickNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0

		'wrong room? go away!
		if room.owner <> GetPlayerCollection().playerID then return 0

		'increase the abonnement
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				GetPlayer().IncreaseNewsAbonnement( button.data.GetInt("newsGenre", i) )
				exit
			endif
		Next
	End Function


	Function onDrawNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0

		'how much levels do we have?
		local level:int = 0
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				level = GetPlayerCollection().Get(room.owner).GetNewsAbonnement( button.data.GetInt("newsGenre", i) )
				exit
			endif
		Next

		'draw the levels
		SetColor 0,0,0
		SetAlpha 0.4
		For Local i:Int = 0 to level-1
			DrawRect( button.rect.GetX()+8+i*10, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -7, 7,4)
		Next
		SetColor 255,255,255
		SetAlpha 1.0
	End Function



	'===================================
	'News: NewsPlanner screen
	'===================================

	Function onDrawNewsPlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0


		'create sign text image
		if not newsPlannerTextImage
			newsPlannerTextImage = TFunctions.CreateEmptyImage(310, 60)
			'render to image
			TBitmapFont.SetRenderTarget(newsPlannerTextImage)

			GetBitmapFont("default", 18).DrawBlock("An das Team~n|b|Folgende News senden:|/b|", 0, 0, 300, 50, ALIGN_CENTER_CENTER, TColor.CreateGrey(100))

			'set back to screen Rendering
			TBitmapFont.SetRenderTarget(null)
		endif
		SetRotation(-2.1)
		DrawImage(newsPlannerTextImage, 450, 30)
		SetRotation(0)

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
			guiNews = null
		Next
		'should not be needed
		rem
		For local guiNews:TGuiNews = eachin GuiManager.list
			guiNews.remove()
			guiNews = null
		Next
		endrem
	End Function


	Function RefreshGuiElements:int()
		local owner:int = GetPlayerCollection().playerID
		'remove gui elements with news the player does not have anylonger
		For local guiNews:TGuiNews = eachin guiNewsListAvailable.entries
			if not GetPlayerProgrammeCollectionCollection().Get(owner).hasNews(guiNews.news)
				guiNews.remove()
				guiNews = null
			endif
		Next
		For local guiNews:TGuiNews = eachin guiNewsListUsed._slots
			if not GetPlayerProgrammePlanCollection().Get(owner).hasNews(guiNews.news)
				guiNews.remove()
				guiNews = null
			endif
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
		For Local news:TNews = EachIn GetPlayerProgrammeCollectionCollection().Get(owner).news
			'skip if news is dragged
			if draggedNewsList.contains(news) then continue

			if not guiNewsListAvailable.ContainsNews(news)
				'only add for news NOT planned in the news show
				if not GetPlayer().GetProgrammePlan().HasNews(news)
					local guiNews:TGUINews = new TGUINews.Create(null,null, news.GetTitle())
					guiNews.SetNews(news)
					guiNewsListAvailable.AddItem(guiNews)
				endif
			endif
		Next
		For Local i:int = 0 to GetPlayer().GetProgrammePlan().news.length - 1
			local news:TNews = TNews(GetPlayerProgrammePlanCollection().Get(owner).GetNews(i))
			'skip if news is dragged
			if news and draggedNewsList.contains(news) then continue

			if news and not guiNewsListUsed.ContainsNews(news)
				local guiNews:TGUINews = new TGUINews.Create(null,null, news.GetTitle())
				guiNews.SetNews(news)
				guiNewsListUsed.AddItem(guiNews, string(i))
			endif
		Next

		haveToRefreshGuiElements = FALSE
	End Function


	Function onUpdateNewsPlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		Game.cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset dragged block - will get set automatically on gui-update
		hoveredGuiNews = null
		draggedGuiNews = null

		'general newsplanner elements
		GUIManager.Update("Newsplanner")
	End Function


	'we need to know whether we dragged or hovered an item - so we
	'can react to right clicks ("forbid room leaving")
	Function onMouseOverNews:int( triggerEvent:TEventBase )
		local item:TGUINews = TGUINews(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiNews = item
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
		local player:TPlayer = GetPlayerCollection().Get(guiNews.news.owner)
		player.GetProgrammePlan().RemoveNews(guiNews.news, -1, FALSE)
		player.GetProgrammeCollection().RemoveNews(guiNews.news)

		'remove gui object
		guiNews.remove()
		guiNews = null
		
		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	Function onDropNews:int(triggerEvent:TEventBase)
		local guiNews:TGUINews = TGUINews( triggerEvent._sender )
		local receiverList:TGUIListBase = TGUIListBase( triggerEvent._receiver )
		if not guiNews or not receiverList then return FALSE

		local player:TPlayer = GetPlayerCollection().Get(guiNews.news.owner)
		if not player then return False

		if receiverList = guiNewsListAvailable
			player.GetProgrammePlan().RemoveNews(guiNews.news, -1, TRUE)
		elseif receiverList = guiNewsListUsed
			local slot:int = -1
			'check drop position
			local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", new TVec2D.Init(-1,-1)))
			if coord then slot = guiNewsListUsed.GetSlotByCoord(coord)
			if slot = -1 then slot = guiNewsListUsed.getSlot(guiNews)

			'this may also drag a news that occupied that slot before
			player.GetProgrammePlan().SetNews(guiNews.news, slot)
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
Type RoomHandler_Boss extends TRoomHandler
	'smoke effect
	Global smokeEmitter:TSpriteParticleEmitter

	Global _instance:RoomHandler_Boss
	Global _initDone:int = False


	Function GetInstance:RoomHandler_Boss()
		if not _instance then _instance = new RoomHandler_Boss
		if not _initDone then _instance.Initialize()
		return _instance
	End Function


	Method Initialize:int()
		if _initDone then return False
		_initDone = True
		
		local smokeConfig:TData = new TData
		smokeConfig.Add("sprite", GetSpriteFromRegistry("gfx_misc_smoketexture"))
		smokeConfig.AddNumber("velocityMin", 5.0)
		smokeConfig.AddNumber("velocityMax", 35.0)
		smokeConfig.AddNumber("lifeMin", 0.30)
		smokeConfig.AddNumber("lifeMax", 2.75)
		smokeConfig.AddNumber("scaleMin", 0.1)
		smokeConfig.AddNumber("scaleMax", 0.15)
		smokeConfig.AddNumber("angleMin", 176)
		smokeConfig.AddNumber("angleMax", 184)
		smokeConfig.AddNumber("xRange", 2)
		smokeConfig.AddNumber("yRange", 2)

		local emitterConfig:TData = new TData
		emitterConfig.Add("area", new TRectangle.Init(49, 335, 0, 0))
		emitterConfig.AddNumber("particleLimit", 100)
		emitterConfig.AddNumber("spawnEveryMin", 0.30)
		emitterConfig.AddNumber("spawnEveryMax", 0.60)

		smokeEmitter = new TSpriteParticleEmitter.Init(emitterConfig, smokeConfig)

		'register self for all boss rooms
		GetRoomHandlerCollection().SetHandler("boss", self)
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		smokeEmitter.Draw()

		local boss:TPlayerBoss = GetPlayerBoss(GetPlayer().playerID)
		if not boss then return False
		For Local dialog:TDialogue = EachIn boss.Dialogues
			dialog.Draw()
		Next
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		GetPlayer().GetFigure().fromroom = Null


		smokeEmitter.Update()
		

		local boss:TPlayerBoss = GetPlayerBoss(GetPlayer().playerID)
		if not boss then return False

		'generate the dialogue if not done yet
		If boss.Dialogues.Count() <= 0 then boss.GenerateDialogues()
		For Local dialog:TDialogue = EachIn boss.Dialogues
			If dialog.Update() = 0
				GetPlayer().GetFigure().LeaveRoom()
				boss.Dialogues.Remove(dialog)
			endif
		Next
	End Method
End Type


'Studio: emitting and receiving the shopping lists for specific
'        scripts
Type RoomHandler_Studio extends TRoomHandler
	'a map containing "roomGUID"=>"script" pairs
	Field studioScriptsByRoom:TMap = CreateMap()

	Global studioManagerDialogue:TDialogue
	Global studioScriptLimit:int = 1

	Global suitcasePos:TVec2D = new TVec2D.Init(520,70)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(19,32)

	Global studioManagerEntity:TSpriteEntity
	Global studioManagerArea:TGUISimpleRect

	Global studioManagerTooltip:TTooltip
	Global placeScriptTooltip:TTooltip

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global guiListStudio:TGUIScriptSlotList
	Global guiListSuitcase:TGUIScriptSlotList

	Global hoveredGuiScript:TGUIScript
	Global draggedGuiScript:TGUIScript

	Global _instance:RoomHandler_Studio
	Global _initDone:int = False


	Function GetInstance:RoomHandler_Studio()
		if not _instance then _instance = new RoomHandler_Studio
		if not _initDone then _instance.Initialize()
		return _instance
	End Function


	Method Initialize:int()
		if _initDone then return False
		_initDone = True

		'===== CREATE GUI LISTS =====
		local sprite:TSprite = GetSpriteFromRegistry("gfx_scripts_0")
		local spriteSuitcase:TSprite = GetSpriteFromRegistry("gfx_scripts_0_dragged")
		guiListStudio = new TGUIScriptSlotList.Create(new TVec2D.Init(720, 300), new TVec2D.Init(17, 52), "studio")
		guiListStudio.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		guiListStudio.SetItemLimit( studioScriptLimit )
		'increase list size by 2 times - makes it easier to drop
		guiListStudio.Resize(2 * sprite.area.GetW(), sprite.area.GetH() )
		guiListStudio.SetSlotMinDimension(2 * sprite.area.GetW(), sprite.area.GetH())
		guiListStudio.SetAcceptDrop("TGuiScript")

		guiListSuitcase	= new TGUIScriptSlotlist.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(200,80), "studio")
		guiListSuitcase.SetAutofillSlots(true)
		guiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		guiListSuitcase.SetItemLimit(GameRules.maxScriptsInSuitcase)
		guiListSuitcase.SetEntryDisplacement( 0, 0 )
		guiListSuitcase.SetAcceptDrop("TGuiScript")


		studioManagerEntity = GetSpriteEntityFromRegistry("entity_studio_manager")
		'default studioManager dimension
		local studioManagerAreaDimension:TVec2D = new TVec2D.Init(150,270)
		local studioManagerAreaPosition:TVec2D = new TVec2D.Init(0,115)
		if studioManagerEntity then studioManagerAreaDimension = studioManagerEntity.area.dimension.copy()
		if studioManagerEntity then studioManagerAreaPosition = studioManagerEntity.area.position.copy()

		studioManagerArea = new TGUISimpleRect.Create(studioManagerAreaPosition, studioManagerAreaDimension, "studio" )
		'studioManager should accept drop - else no recognition
		studioManagerArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)


		'===== REGISTER EVENTS =====

		'to react on changes in the programmeCollection (eg. custom script finished)
		EventManager.registerListenerFunction( "programmecollection.addScript", onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.removeScript", onChangeProgrammeCollection )

		'instead of "guiobject.onDropOnTarget" the event "guiobject.onDropOnTargetAccepted"
		'is only emitted if the drop is successful (so it "visually" happened)
		'drop ... to studio manager or suitcase
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropScript, "TGuiScript" )
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "guiobject.OnMouseOver", onMouseOverScript, "TGuiScript" )

		
		'register self for all studio rooms
		GetRoomHandlerCollection().SetHandler("studio", self)
	End Method


	'clear the guilist for the suitcase if a player enters
	Method onEnterRoom:int( triggerEvent:TEventBase )
		'we are not interested in other figures than our player's
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or GetPlayerBase().GetFigure() <> figure then return FALSE

		'empty the guilist / delete gui elements so they can get rebuild
		guiListSuitcase.EmptyList()
		guiListStudio.EmptyList()
	End Method


	'if players are in a studio during changes in their programme
	'collection, react to it...
	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("studio") then return FALSE

		GetInstance().RefreshGuiElements()
	End Function


	Function onMouseOverScript:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("studio") then return FALSE

		local item:TGUIScript = TGUIScript(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiScript = item
		if item.isDragged() then draggedGuiScript = item

		return TRUE
	End Function


	Function onDropScript:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("studio") then return FALSE

		local guiBlock:TGUIScript = TGUIScript( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver then return FALSE

		'try to get a list out of the drag-source-guiobject 
		local source:TGuiObject = TGuiObject(triggerEvent.GetData().Get("source"))
		local sourceList:TGUIScriptSlotList
		if source
			local sourceParent:TGUIobject = source._parent
			if TGUIPanel(sourceParent) then sourceParent = TGUIPanel(source)._parent
			sourceList = TGUIScriptSlotList(sourceParent)
		endif
		'only interested in drops FROM a list
		if not sourceList then return FALSE

		'alternatively TGUIGameListItems contain "lastListID" which
		'is the id of the last list they there attached too
		'if guiBlock.lastListID = guiListSuitcase._id ... and so on
		
		'ATTENTION: senderList (parent of the parent of guiBlock) is
		'           only correct when NOT dropping on another list
		'           -> so we use sourceList
		if sourceList = guiListSuitcase
			'assign the dropped script as the current one
			local roomGUID:string = GetPlayer().GetFigure().inRoom.GetGUID()

			GetInstance().SetCurrentStudioScript(guiBlock.script, roomGUID)
		endif

		'dropping to suitcase
		if receiver = guiListSuitcase
			'remove the script as the current one
			local roomGUID:string = GetPlayer().GetFigure().inRoom.GetGUID()
			if GetInstance().GetCurrentStudioScript(roomGUID) = guiBlock.script
				GetInstance().RemoveCurrentStudioScript(roomGUID)
			endif
		endif

		'remove gui block, it will get recreated if needed
		'(and it then will have the correct assets assigned)
		guiBlock.remove()
		guiBlock = null
		GetInstance().RefreshGuiElements()
		
		return TRUE
	End Function


	Method SetCurrentStudioScript:int(script:TScript, roomGUID:string)
		if not script or not roomGUID then return False

		studioScriptsByRoom.Insert(roomGUID, script)

		'remove from suitcase list
		local player:TPlayer = GetPlayer(script.owner)
		if player
			player.GetProgrammeCollection().MoveScriptFromSuitcaseToStudio(script)
		endif
		
		return True
	End Method


	Method RemoveCurrentStudioScript:int(roomGUID:string)
		if not roomGUID then return False

		local script:TScript = GetCurrentStudioScript(roomGUID)
		if script
			local player:TPlayer = GetPlayer(script.owner)
			if player
				player.GetProgrammeCollection().MoveScriptFromStudioToSuitcase(script)
			endif
		endif

		return studioScriptsByRoom.Remove(roomGUID)
	End Method


	Method GetCurrentStudioScript:TScript(roomGUID:string)
		if not roomGUID then return Null

		return TScript(studioScriptsByRoom.ValueForKey(roomGUID))
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		guiListStudio.EmptyList()
		guiListSuitcase.EmptyList()

		For local guiScript:TGUIScript = eachin GuiManager.listDragged
			guiScript.remove()
			guiScript = null
		Next

		hoveredGuiScript = null
		draggedGuiScript = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Function


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with scripts the player does no longer have

		'suitcase
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(GetPlayer().playerID)
		For local guiScript:TGUIScript = eachin GuiListSuitcase._slots
			'if the player has this script in suitcase or list, skip deletion
			if programmeCollection.HasScript(guiScript.script) then continue
			if programmeCollection.HasScriptInSuitcase(guiScript.script) then continue

			guiScript.remove()
			guiScript = null
		Next

		'player should be ALWAYS inRoom when "RefreshGuiElements()" is
		'called...
		if GetPlayer().GetFigure().inRoom
			local roomGUID:string = GetPlayer().GetFigure().inRoom.GetGUID()
			'studio list
			For local guiScript:TGUIScript = eachin guiListStudio._slots
				if GetCurrentStudioScript(roomGUID) <> guiScript.script
					guiScript.remove()
					guiScript = null
				endif
			Next
		endif

		'===== CREATE NEW =====
		'create missing gui elements for all script-lists

		'studio list
		local studioGUID:string = GetPlayer().GetFigure().inRoom.GetGUID()
		local studioScript:TScript = GetCurrentStudioScript(studioGUID)
		if studioScript and not guiListStudio.ContainsScript(studioScript)
			'try to fill in our list
			if guiListStudio.getFreeSlot() >= 0
				local block:TGUIScript = new TGUIScript.CreateWithScript(studioScript)
				block.studioMode = True
				'change look
				block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

				guiListStudio.addItem(block, "-1")
			else
				TLogger.log("Studio.RefreshGuiElements", "script exists but does not fit in GuiListNormal - script removed.", LOG_ERROR)
				RemoveCurrentStudioScript(studioGUID)
			endif
		endif

		'create missing gui elements for the players suitcase scripts
		For local script:TScript = eachin programmeCollection.suitcaseScripts
			if guiListSuitcase.ContainsScript(script) then continue
			local block:TGUIScript = new TGUIScript.CreateWithScript(script)
			block.studioMode = True
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			guiListSuitcase.addItem(block, "-1")
		Next

		haveToRefreshGuiElements = FALSE
	End Method


	Method GenerateStudioManagerDialogue()
		local readyToProduce:int = 0

		local text:string = "Hi"
		if readyToProduce
			text = "Informationen ueber derzeitige Produktion anbieten"
		else
			text = "Einkaufsliste anbieten"
		endif

		text = text.replace("%PLAYERNAME%", GetPlayerBase().name)
		

		local texts:TDialogueTexts[1]
		texts[0] = TDialogueTexts.Create(text)
		texts[0].AddAnswer(TDialogueAnswer.Create( "Ich brauche eine Einkaufsliste", -1, Null))
		texts[0].AddAnswer(TDialogueAnswer.Create( "Tschüss", -2, Null))

		studioManagerDialogue = new TDialogue
		studioManagerDialogue.SetArea(new TRectangle.Init(150, 40, 460, 230))
		studioManagerDialogue.AddTexts(texts)
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		local roomGUID:string = TRoom(triggerEvent.GetSender()).GetGUID()

		if studioManagerEntity Then studioManagerEntity.Render()
		GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		'make suitcase/vendor highlighted if needed
		local highlightSuitcase:int = False
		local highlightStudioManager:int = False

		if draggedGuiScript and draggedGuiScript.isDragged()
			if draggedGuiScript.script = GetCurrentStudioScript(roomGUID)
				highlightSuitcase = True
			else
				highlightStudioManager = True
			endif
		endif

		if highlightStudioManager or highlightSuitcase
			local oldCol:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * (0.4 + 0.2 * sin(Time.GetTimeGone() / 5))

			if highlightStudioManager
				if studioManagerEntity then studioManagerEntity.Render()
				GetSpriteFromRegistry("gfx_studio_deskhint").Draw(710, 325)
			endif
			if highlightSuitcase then GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		endif

		if studioManagerTooltip then studioManagerTooltip.Render()

		GUIManager.Draw("studio")

		if hoveredGuiScript and not studioManagerDialogue
			'draw the current sheet
			hoveredGuiScript.DrawSheet()
		endif

		'draw after potential tooltips
		if studioManagerDialogue then studioManagerDialogue.Draw()

	End Method



	Method onUpdateRoom:int( triggerEvent:TEventBase )
		GetPlayer().GetFigure().fromroom = Null

		'mouse over studio manager
		if THelper.MouseIn(0,100,150,300)
			if not studioManagerDialogue
				'generate the dialogue if not done yet
				if MouseManager.IsHit(1) and not draggedGuiScript
					GenerateStudioManagerDialogue()
				endif

				'show tooltip of studio manager
				'only show when no dialogue is (or just got) opened 
				if not studioManagerDialogue
					If not studioManagerTooltip Then studioManagerTooltip = TTooltip.Create(GetLocale("STUDIO_MANAGER"), GetLocale("GIVES_INFORMATION_ABOUT_PRODUCTION_OR_HANDS_OUT_SHOPPING_LIST"), 150, 160,-1,-1)
					studioManagerTooltip.enabled = 1
					studioManagerTooltip.minContentWidth = 150
					studioManagerTooltip.Hover()
				endif
			endif
		endif

		If studioManagerTooltip Then studioManagerTooltip.Update()

		if studioManagerDialogue and studioManagerDialogue.Update() = 0
			studioManagerDialogue = null
		endif

		Game.cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiScript = null
		'reset dragged block too
		draggedGuiScript = null

		GUIManager.Update("studio")
	End Method
End Type



'Ad agency
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
	Global suitcasePos:TVec2D = new TVec2D.Init(520,100)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(19,32)
	Global contractsPerLine:int	= 4
	Global contractsNormalAmount:int = 12
	Global contractsCheapAmount:int	= 4

	Global _instance:RoomHandler_AdAgency
	Global _initDone:int = FALSE


	Function GetInstance:RoomHandler_AdAgency()
		if not _instance then _instance = new RoomHandler_AdAgency
		if not _initDone then _instance.Initialize()
		return _instance
	End Function


	Method Initialize:int()
		if _initDone then return FALSE
		_initDone = true

		'===== CREATE/RESIZE LISTS =====

		listNormal = listNormal[..contractsNormalAmount]
		listCheap = listCheap[..contractsCheapAmount]


		'===== CREATE GUI LISTS =====

		GuiListNormal	= GuiListNormal[..3]
		for local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i] = new TGUIAdContractSlotList.Create(new TVec2D.Init(430 - i*70, 170 + i*32), new TVec2D.Init(200, 140), "adagency")
			GuiListNormal[i].SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListNormal[i].SetItemLimit( contractsNormalAmount / GuiListNormal.length  )
			GuiListNormal[i].Resize(GetSpriteFromRegistry("gfx_contracts_0").area.GetW() * (contractsNormalAmount / GuiListNormal.length), GetSpriteFromRegistry("gfx_contracts_0").area.GetH() )
			GuiListNormal[i].SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW(), GetSpriteFromRegistry("gfx_contracts_0").area.GetH())
			GuiListNormal[i].SetAcceptDrop("TGuiAdContract")
			GuiListNormal[i].setZindex(i)
		Next

		GuiListSuitcase	= new TGUIAdContractSlotList.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(200,80), "adagency")
		GuiListSuitcase.SetAutofillSlots(true)

		GuiListCheap = new TGUIAdContractSlotList.Create(new TVec2D.Init(70, 200), new TVec2D.Init(10 +GetSpriteFromRegistry("gfx_contracts_0").area.GetW()*4,GetSpriteFromRegistry("gfx_contracts_0").area.GetH()), "adagency")
		GuiListCheap.setEntriesBlockDisplacement(70,0)



		GuiListCheap.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

		GuiListCheap.SetItemLimit(listCheap.length)
		GuiListSuitcase.SetItemLimit(GameRules.maxContracts)

		GuiListCheap.SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW(), GetSpriteFromRegistry("gfx_contracts_0").area.GetH())
		GuiListSuitcase.SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW(), GetSpriteFromRegistry("gfx_contracts_0").area.GetH())

		GuiListCheap.SetEntryDisplacement( -2*GuiListNormal[0]._slotMinDimension.x, 5)
		GuiListSuitcase.SetEntryDisplacement( 0, 0)

		GuiListCheap.SetAcceptDrop("TGuiAdContract")
		GuiListSuitcase.SetAcceptDrop("TGuiAdContract")

		VendorArea = new TGUISimpleRect.Create(new TVec2D.Init(241, 110), new TVec2D.Init(GetSpriteFromRegistry("gfx_screen_adagency_vendor").area.GetW(), GetSpriteFromRegistry("gfx_screen_adagency_vendor").area.GetH()), "adagency" )
		'vendor should accept drop - else no recognition
		VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)


		'===== REGISTER EVENTS =====

		'to react on changes in the programmeCollection (eg. contract finished)
		EventManager.registerListenerFunction( "programmecollection.addAdContract", onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.removeAdContract", onChangeProgrammeCollection )

		'instead of "guiobject.onDropOnTarget" the event "guiobject.onDropOnTargetAccepted"
		'is only emitted if the drop is successful (so it "visually" happened)
		'drop ... to vendor or suitcase
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropContract, "TGuiAdContract" )
		'drop on vendor - sell things
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropContractOnVendor, "TGuiAdContract" )
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "guiobject.OnMouseOver", onMouseOverContract, "TGuiAdContract" )
		'figure leaves room - only without dragged blocks


		'this lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction("guiobject.onClick", onClickContract, "TGuiAdContract")


		GetRoomHandlerCollection().SetHandler("adagency", self)
	End Method


	Method AbortScreenActions:Int()
		if draggedGuiAdContract
			'try to drop the licence back
			draggedGuiAdContract.dropBackToOrigin()
			draggedGuiAdContract = null
			hoveredGuiAdContract = null
		endif

		'remove and recreate all (so they get the correct visual style)
		'do not use that - it reorders elements and changes the position
		'of empty slots ... maybe unwanted
		'GetInstance().RemoveAllGuiElements()
		'GetInstance().RefreshGuiElements()


		'change look to "stand on table look"
		For local i:int = 0 to GuiListNormal.length-1
			For Local obj:TGUIAdContract = EachIn GuiListNormal[i]._slots
				obj.InitAssets(obj.getAssetName(-1, FALSE), obj.getAssetName(-1, TRUE))
			Next
		Next
		For Local obj:TGUIAdContract = EachIn GuiListCheap._slots
			obj.InitAssets(obj.getAssetName(-1, FALSE), obj.getAssetName(-1, TRUE))
		Next

	End Method




	Method onSaveGameBeginLoad:int( triggerEvent:TEventBase )
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
	End Method
	

	'run AFTER the savegame data got loaded
	'handle faulty adcontracts (after data got loaded)
	Method onSaveGameLoad:int( triggerEvent:TEventBase )
		'in the case of being empty (should not happen)
		GetInstance().RefillBlocks()
	End Method


	Method onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure then return FALSE

		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure.playerID then return False

		if figure = GetPlayerBase().GetFigure()
			GetInstance().ResetContractOrder()
		endif

		'refill the empty blocks, also sets haveToRefreshGuiElements=true
		'so next call the gui elements will be redone
		GetInstance().ReFillBlocks()
	End Method


	'override
	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiAdContract
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Method


	'add back the programmes from the suitcase
	'also fill empty blocks, remove gui elements
	Method onLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or not figure.playerID then return FALSE

		'sign all new contracts
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollectionCollection().Get(figure.playerID)
		For Local contract:TAdContract = EachIn programmeCollection.suitcaseAdContracts
			'adds a contract to the players collection (gets signed THERE)
			'if successful, this also removes the contract from the suitcase
			programmeCollection.AddAdContract(contract)
		Next

		return TRUE
	End Method


	'called as soon as a players figure is forced to leave the room
	Method onForcefullyLeaveRoom:int( triggerEvent:TEventBase )
		'only handle the players figure
		if TFigure(triggerEvent.GetSender()) <> GetPlayer().figure then return False

		'instead of leaving the room and accidentially adding contracts
		'we delete all unsigned contracts from the list
		GetPlayerProgrammeCollectionCollection().Get(GetPlayer().playerID).suitcaseAdContracts.Clear()

		AbortScreenActions()
	End Method


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
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		if not programmeCollection then return FALSE

		'try to add to suitcase of player
		if not sign
			if not programmeCollection.AddUnsignedAdContractToSuitcase(contract) then return FALSE
		'we do not need the suitcase, direkt sign pls (eg. for AI)
		else
			if not programmeCollection.AddAdContract(contract) then return FALSE
		endif

		'remove from agency's lists
		GetInstance().RemoveContract(contract)

		return TRUE
	End Method


	Method TakeContractFromPlayer:int(contract:TAdContract, playerID:int)
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		if not programmeCollection then return False

		if programmeCollection.RemoveUnsignedAdContractFromSuitcase(contract)
			'add to agency's lists - if not existing yet
			if not HasContract(contract) then AddContract(contract)

			return TRUE
		else
			return FALSE
		endif
	End Method


	Function isCheapContract:int(contract:TAdContract)
		return contract.adAgencyClassification = 1
	End Function


	Method ResetContractOrder:int()
		local contracts:TList = CreateList()
		for local contract:TAdContract = eachin listNormal
			'only add valid contracts
			if contract.base then contracts.addLast(contract)
		Next
		for local contract:TAdContract = eachin listCheap
			'only add valid contracts
			if contract.base then contracts.addLast(contract)
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
			guiAdContract = null
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
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollectionCollection().Get(GetPlayer().playerID)
		For local guiAdContract:TGuiAdContract = eachin GuiListSuitcase._slots
			'if the player has this contract in suitcase or list, skip deletion
			if programmeCollection.HasAdContract(guiAdContract.contract) then continue
			if programmeCollection.HasUnsignedAdContractInSuitcase(guiAdContract.contract) then continue

			'print "guiListSuitcase has obsolete contract: "+guiAdContract.contract.id
			guiAdContract.remove()
			guiAdContract = null
		Next
		'agency lists
		For local i:int = 0 to GuiListNormal.length-1
			For local guiAdContract:TGuiAdContract = eachin GuiListNormal[i]._slots
				'if not HasContract(guiAdContract.contract) then print "REM guiListNormal"+i+" has obsolete contract: "+guiAdContract.contract.id
				if not HasContract(guiAdContract.contract)
					guiAdContract.remove()
					guiAdContract = null
				endif
			Next
		Next
		For local guiAdContract:TGuiAdContract = eachin GuiListCheap._slots
			'if not HasContract(guiAdContract.contract) then	print "REM guiListCheap has obsolete contract: "+guiAdContract.contract.id
			if not HasContract(guiAdContract.contract)
				guiAdContract.remove()
				guiAdContract = null
			endif
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
					TLogger.log("AdAgency.RefreshGuiElements", "contract exists but does not fit in GuiListNormal - contract removed.", LOG_ERROR)
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
		For local contract:TAdContract = eachin programmeCollection.adContracts
			if guiListSuitcase.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			'print "ADD guiListSuitcase missed new (old) contract: "+block.contract.id

			block.setOption(GUI_OBJECT_DRAGABLE, FALSE)
			guiListSuitcase.addItem(block, "-1")
		Next

		'create missing gui elements for the current suitcase
		For local contract:TAdContract = eachin programmeCollection.suitcaseAdContracts
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


		'=== CALCULATE VARIOUS INFORMATION FOR FILTERS ===
		'we calculate the "average quote" using yesterdays audience but
		'todays reach ... so it is not 100% accurate (buying stations today
		'will lower the quote)
		local averageChannelImage:Float = GetPublicImageCollection().GetAverage().GetAverageImage()
		local averageChannelReach:Int = GetStationMapCollection().GetAverageReach()
		local averageChannelQuote:Float = 0.0
		if averageChannelReach > 0
			averageChannelQuote = GetDailyBroadcastStatistic( GetWorldTime().GetDay()-1, True ).GetAverageAudience().GetSum() / averageChannelReach
		endif
		
		local highestChannelImage:Float = averageChannelImage
		local highestChannelQuote:Float = 0.0

		local lowestChannelImage:Float = averageChannelImage
		local lowestChannelQuote:Float = -1

		For local i:int = 1 to 4
			local image:Float = GetPublicImageCollection().Get(i).GetAverageImage()
			if image > highestChannelImage then highestChannelImage = image
			if image < lowestChannelImage then lowestChannelImage = image

			if averageChannelReach > 0
				local audience:Float = GetDailyBroadcastStatistic( GetWorldTime().GetDay()-1, True ).GetAverageAudience(i).GetSum()
				local quote:Float = audience / averageChannelReach
				if lowestChannelQuote < 0 then lowestChannelQuote = quote
				if lowestChannelQuote > quote then lowestChannelQuote = quote
			endif
		Next


		'=== SETUP FILTERS ===
		'the cheap list contains really low contracts
		local cheapListFilter:TAdContractBaseFilter = new TAdContractbaseFilter
		'0.5% market share -> 1mio reach means 5.000 people!
		cheapListFilter.SetAudience(0.0, 0.005)
		'no image requirements - or not more than the lowest image
		'(so all could sign this)
		cheapListFilter.SetImage(0.0, 0.01 * lowestChannelImage)
		'cheap contracts should in now case limit genre/groups
		cheapListFilter.SetSkipLimitedToProgrammeGenre()
		cheapListFilter.SetSkipLimitedToTargetGroup()

		'the 12 contracts are divided into 3 groups
		'4x fitting the lowest requirements
		'8x fitting the average requirements
		'4x fitting the highest requirements
		
		local levelFilters:TAdContractBaseFilter[3]
		'=== LOWEST ===
		levelFilters[0] = new TAdContractbaseFilter
		'from 1% of avg to 100% of avg
		levelFilters[0].SetAudience(0.0, lowestChannelQuote)
		'1% - avgImage %
		levelFilters[0].SetImage(0.0, 0.01 * lowestChannelImage)
		'lowest should be without "limits"
		levelFilters[0].SetSkipLimitedToProgrammeGenre()
		levelFilters[0].SetSkipLimitedToTargetGroup()

		'=== AVERAGE ===
		levelFilters[1] = new TAdContractbaseFilter
		'from 50% of avg to 150% of avg
		levelFilters[1].SetAudience(0.5 * averageChannelQuote, Max(0.01, 1.5 * averageChannelQuote))
		'0-100% of average Image
		levelFilters[1].SetImage(0, 0.01 * averageChannelImage)

		'=== HIGH ===
		levelFilters[2] = new TAdContractbaseFilter
		'from 50% of avg to 150% of avg, at least 1-3%
		levelFilters[2].SetAudience(Max(0.01, 0.5 * highestChannelQuote), Max(0.02, 1.5 * highestChannelQuote))
		'0-100% of highest Image
		levelFilters[2].SetImage(0, 0.01 * highestChannelImage)

rem
print "REFILL:"
print "level0:  audience "+"0.0"+" - "+lowestChannelQuote
print "level0:  image    "+"0.0"+" - "+(0.01 * lowestChannelImage)
print "level1:  audience "+(0.5 * averageChannelQuote)+" - "+Max(0.01, 1.5 * averageChannelQuote)
print "level1:  image     0.00 - "+(0.01 * averageChannelImage)
print "level2:  audience "+(Max(0.01, 0.5 * highestChannelQuote))+" - "+Max(0.03, 1.5 * highestChannelQuote)
print "level2:  image     0.00 - "+(0.01 * highestChannelImage)
print "------------------"
endrem
		'=== ACTUALLY CREATE CONTRACTS ===
		local classification:int = 0
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				'if exists and is valid...skip it
				if lists[j][i] and lists[j][i].base then continue

				'=== PLAYER ORIENTED LIST ===
				if lists[j] = listNormal
					Select (i mod 4)
						case 0
							'levelFilters[0]
							contract = new TAdContract.Create( GetAdContractBaseCollection().GetRandomByFilter(levelFilters[0]) )
							classification = 2
						case 1,2
							'levelFilters[1]
							contract = new TAdContract.Create( GetAdContractBaseCollection().GetRandomByFilter(levelFilters[1]) )
							classification = 3
						case 3
							'levelFilters[2]
							contract = new TAdContract.Create( GetAdContractBaseCollection().GetRandomByFilter(levelFilters[2]) )
							classification = 4
					End Select
				endif

				'=== CHEAP LIST ===
				if lists[j] = listCheap
					contract = new TAdContract.Create( GetAdContractBaseCollection().GetRandomByFilter(cheapListFilter) )
					classification = 1
				endif


				if not contract
					TLogger.log("AdAgency.ReFillBlocks", "Not enough contracts to fill ad agency in list "+i+". Using absolutely random one without limitations.", LOG_ERROR)
					'try again without filter - to avoid "empty room"
					contract = new TAdContract.Create( GetAdContractBaseCollection().GetRandom() )
				endif
				
				'add new contract to slot
				if contract
					'set classification so contract knows its "origin"
					contract.adAgencyClassification = classification

					contract.owner = -1
					lists[j][i] = contract
				endif
			Next
		Next
	End Method



	'===================================
	'Ad Agency: Room screen
	'===================================

	'if players are in the agency during changes
	'to their programme collection, react to...
	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("adagency") then return FALSE

		GetInstance().RefreshGuiElements()
	End Function


	'in case of right mouse button click a dragged contract is
	'placed at its original spot again
	Function onClickContract:int(triggerEvent:TEventBase)
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiAdContract:TGuiAdContract= TGUIAdContract(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiAdContract or not guiAdContract.isDragged() then return FALSE

		'remove gui object
		guiAdContract.remove()
		guiAdContract = null

		'rebuild at correct spot
		GetInstance().RefreshGuiElements()

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	Function onMouseOverContract:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("adagency") then return FALSE

		local item:TGuiAdContract = TGuiAdContract(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiAdContract = item
		if item.isDragged() then draggedGuiAdContract = item

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropContractOnVendor:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("adagency") then return FALSE

		local guiBlock:TGuiAdContract = TGuiAdContract( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver or receiver <> VendorArea then return FALSE

		local parent:TGUIobject = guiBlock._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local senderList:TGUIAdContractSlotList = TGUIAdContractSlotList(parent)
		if not senderList then return FALSE

		'if coming from suitcase, try to remove it from the player
		if senderList = GuiListSuitcase
			if not GetInstance().TakeContractFromPlayer(guiBlock.contract, GetPlayer().playerID )
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
		guiBlock = null

		'something changed...refresh missing/obsolete...
		GetInstance().RefreshGuiElements()

		return TRUE
	End function


	'in this stage, the item is already added to the new gui list
	'we now just add or remove it to the player or vendor's list
	Function onDropContract:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("adagency") then return FALSE

		local guiAdContract:TGuiAdContract = TGuiAdContract(triggerEvent._sender)
		local receiverList:TGUIAdContractSlotList = TGUIAdContractSlotList(triggerEvent._receiver)
		if not guiAdContract or not receiverList then return FALSE

		'get current owner of the contract, as the field "owner" is set
		'during sign we cannot rely on it. So we check if the player has
		'the contract in the suitcaseContractList
		local owner:int = guiAdContract.contract.owner
		if owner <= 0 and GetPlayerProgrammeCollectionCollection().Get(GetPlayerCollection().playerID).HasUnsignedAdContractInSuitcase(guiAdContract.contract)
			owner = GetPlayerCollection().playerID
		endif

		'find out if we sell it to the vendor or drop it to our suitcase
		if receiverList <> GuiListSuitcase
			guiAdContract.InitAssets( guiAdContract.getAssetName(-1, FALSE ), guiAdContract.getAssetName(-1, TRUE ) )

			'no problem when dropping vendor programme to vendor..
			if owner <= 0 then return TRUE

			if not GetInstance().TakeContractFromPlayer(guiAdContract.contract, GetPlayerCollection().playerID )
				triggerEvent.setVeto()
				return FALSE
			endif

			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveContract(guiAdContract.contract)
			GetInstance().AddContract(guiAdContract.contract)
		else
			guiAdContract.InitAssets(guiAdContract.getAssetName(-1, TRUE ), guiAdContract.getAssetName(-1, TRUE ))
			'no problem when dropping own programme to suitcase..
			if owner = GetPlayerCollection().playerID then return TRUE
			if not GetInstance().GiveContractToPlayer(guiAdContract.contract, GetPlayerCollection().playerID)
				triggerEvent.setVeto()
				return FALSE
			endif
		endIf

		'2014/05/04 (Ronny): commented out, obsolete ?
		'something changed...refresh missing/obsolete...
		'GetInstance().RefreshGuiElements()


		return TRUE
	End Function


	Method onDrawRoom:int( triggerEvent:TEventBase )
		GetSpriteFromRegistry("gfx_screen_adagency_vendor").Draw(VendorArea.getScreenX(), VendorArea.getScreenY())
		GetSpriteFromRegistry("gfx_suitcase_big").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		'make suitcase/vendor highlighted if needed
		local highlightSuitcase:int = False
		local highlightVendor:int = False

		if draggedGuiAdContract
			if not GetPlayerProgrammeCollection(GetPlayerCollection().playerID).HasUnsignedAdContractInSuitcase(draggedGuiAdContract.contract)
				highlightSuitcase = True
			endif
			highlightVendor = True
		endif

		if highlightVendor or highlightSuitcase
			local oldCol:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * (0.4 + 0.2 * sin(Time.GetTimeGone() / 5))

			if highlightVendor then	GetSpriteFromRegistry("gfx_screen_adagency_vendor").Draw(VendorArea.getScreenX(), VendorArea.getScreenY())
			if highlightSuitcase then GetSpriteFromRegistry("gfx_suitcase_big").Draw(suitcasePos.GetX(), suitcasePos.GetY())

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		endif



		GUIManager.Draw("adagency")

		if hoveredGuiAdContract
			'draw the current sheet
			hoveredGuiAdContract.DrawSheet()
		endif
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		Game.cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiAdContract = null
		'reset dragged block too
		draggedGuiAdContract = null

		GUIManager.Update("adagency")
	End Method

End Type


'Script agency
Type RoomHandler_ScriptAgency extends TRoomHandler
	Global hoveredGuiScript:TGuiScript = null
	Global draggedGuiScript:TGuiScript = null

	Global VendorEntity:TSpriteEntity
	'allows registration of drop-event
	Global VendorArea:TGUISimpleRect

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listNormal:TScript[]
	Field listNormal2:TScript[]

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListNormal:TGUIScriptSlotList[]
	Global GuiListNormal2:TGUIScriptSlotList = null
	Global GuiListSuitcase:TGUIScriptSlotList = null

	'configuration
	Global suitcasePos:TVec2D = new TVec2D.Init(320,270)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(19,32)
	Global scriptsPerLine:int = 1
	Global scriptsNormalAmount:int = 4
	Global scriptsNormal2Amount:int	= 1

	Global _instance:RoomHandler_ScriptAgency
	Global _initDone:int = FALSE


	Function GetInstance:RoomHandler_ScriptAgency()
		if not _instance then _instance = new RoomHandler_ScriptAgency
		if not _initDone then _instance.Initialize()
		return _instance
	End Function


	Method Initialize:int()
		if _initDone then return FALSE
		_initDone = true

		'===== CREATE/RESIZE LISTS =====

		listNormal = listNormal[..scriptsNormalAmount]
		listNormal2 = listNormal2[..scriptsNormal2Amount]


		'===== CREATE GUI LISTS =====
		GuiListNormal	= GuiListNormal[..scriptsNormalAmount]
		local sprite:TSprite = GetSpriteFromRegistry("gfx_scripts_0")
		local spriteSuitcase:TSprite = GetSpriteFromRegistry("gfx_scripts_0_dragged")
		for local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i] = new TGUIScriptSlotList.Create(new TVec2D.Init(233 + (GuiListNormal.length-1 - i)*22, 143 + i*2), new TVec2D.Init(17, 52), "scriptagency")
			GuiListNormal[i].SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListNormal[i].SetItemLimit( scriptsNormalAmount / GuiListNormal.length  )
			GuiListNormal[i].Resize(sprite.area.GetW() * (scriptsNormalAmount / GuiListNormal.length), sprite.area.GetH() )
			GuiListNormal[i].SetSlotMinDimension(sprite.area.GetW(), sprite.area.GetH())
			GuiListNormal[i].SetAcceptDrop("TGuiScript")
			GuiListNormal[i].setZindex(i)
		Next

		GuiListSuitcase	= new TGUIScriptSlotlist.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(200,80), "scriptagency")
		GuiListSuitcase.SetAutofillSlots(true)

		GuiListNormal2 = new TGUIScriptSlotlist.Create(new TVec2D.Init(188, 240), new TVec2D.Init(10 + sprite.area.GetW()*scriptsNormal2Amount, sprite.area.GetH()), "scriptagency")
		GuiListNormal2.setEntriesBlockDisplacement(18, 11)

		GuiListNormal2.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
		GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

		GuiListNormal2.SetItemLimit(listNormal2.length)
		GuiListSuitcase.SetItemLimit(GameRules.maxScriptsInSuitcase)

		GuiListNormal2.SetSlotMinDimension(sprite.area.GetW(), sprite.area.GetH())
		GuiListSuitcase.SetSlotMinDimension(spriteSuitcase.area.GetW(), spriteSuitcase.area.GetH())

		GuiListNormal2.SetEntryDisplacement( -scriptsNormal2Amount * GuiListNormal[0]._slotMinDimension.x, 5)
		GuiListSuitcase.SetEntryDisplacement( 0, 0 )

		GuiListNormal2.SetAcceptDrop("TGuiScript")
		GuiListSuitcase.SetAcceptDrop("TGuiScript")


		VendorEntity = GetSpriteEntityFromRegistry("entity_scriptagency_vendor")
		'default vendor dimension
		local vendorAreaDimension:TVec2D = new TVec2D.Init(200,300)
		local vendorAreaPosition:TVec2D = new TVec2D.Init(350,100)
		if VendorEntity then vendorAreaDimension = VendorEntity.area.dimension.copy()
		if VendorEntity then vendorAreaPosition = VendorEntity.area.position.copy()

		VendorArea = new TGUISimpleRect.Create(vendorAreaPosition, vendorAreaDimension, "scriptagency" )
		'vendor should accept drop - else no recognition
		VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)


		'===== REGISTER EVENTS =====

		'to react on changes in the programmeCollection (eg. custom script finished)
		EventManager.registerListenerFunction( "programmecollection.addScript", onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.removeScript", onChangeProgrammeCollection )

		'instead of "guiobject.onDropOnTarget" the event "guiobject.onDropOnTargetAccepted"
		'is only emitted if the drop is successful (so it "visually" happened)
		'drop ... to vendor or suitcase
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropScript, "TGuiScript" )
		'drop on vendor - sell things
		EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropScriptOnVendor, "TGuiScript" )
		'we want to know if we hover a specific block - to show a datasheet
		EventManager.registerListenerFunction( "guiobject.OnMouseOver", onMouseOverScript, "TGuiScript" )

		'this lists want to delete the item if a right mouse click happens...
		EventManager.registerListenerFunction("guiobject.onClick", onClickScript, "TGuiScript")


		GetRoomHandlerCollection().SetHandler("scriptagency", self)
	End Method


	Method AbortScreenActions:Int()
		if draggedGuiScript
			'try to drop the licence back
			draggedGuiScript.dropBackToOrigin()
			draggedGuiScript = null
			hoveredGuiScript = null
		endif

		'change look to "stand on furniture look"
		For local i:int = 0 to GuiListNormal.length-1
			For Local obj:TGUIGameListItem = EachIn GuiListNormal[i]._slots
				obj.InitAssets(obj.getAssetName(-1, FALSE), obj.getAssetName(-1, TRUE))
			Next
		Next
		For Local obj:TGUIGameListItem = EachIn GuiListNormal2._slots
			obj.InitAssets(obj.getAssetName(-1, FALSE), obj.getAssetName(-1, TRUE))
		Next

	End Method


	Method onSaveGameBeginLoad:int( triggerEvent:TEventBase )
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
	End Method
	

	'run AFTER the savegame data got loaded
	'handle faulty adcontracts (after data got loaded)
	Method onSaveGameLoad:int( triggerEvent:TEventBase )
		'in the case of being empty (should not happen)
		GetInstance().RefillBlocks()
	End Method


	Method onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure then return FALSE

		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure.playerID then return False

		if figure = GetPlayerBase().GetFigure()
			GetInstance().ResetScriptOrder()
		endif

		'refill the empty blocks, also sets haveToRefreshGuiElements=true
		'so next call the gui elements will be redone
		GetInstance().ReFillBlocks()
	End Method


	'override
	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiScript
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Method


	'also fill empty blocks, remove gui elements
	Method onLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or not figure.playerID then return FALSE

		'add back the scripts from the suitcase?
		'currently this is done when entering the archive room


		return TRUE
	End Method



	'===================================
	'Script Agency: common Functions
	'===================================

	Method GetScriptsInStock:int()
		Local ret:Int = 0
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For Local script:TScript = EachIn lists[j]
				If script Then ret:+1
			Next
		Next
		return ret
	End Method


	Method GetScriptByPosition:TScript(position:int)
		if position > GetScriptsInStock() then return null
		local currentPosition:int = 0
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For Local script:TScript = EachIn lists[j]
				if script
					if currentPosition = position then return script
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Method


	Method HasScript:int(script:TScript)
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For Local s:TScript = EachIn lists[j]
				if s = script then return TRUE
			Next
		Next
		return FALSE
	End Method


	Method GetScriptByID:TScript(scriptID:int)
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For Local script:TScript = EachIn lists[j]
				if script and script.id = scriptID then return script
			Next
		Next
		return null
	End Method


	Method SellScriptToPlayer:int(script:TScript, playerID:int)
		if script.owner = playerID then return FALSE

		if not GetPlayerCollection().IsPlayer(playerID) then return FALSE

		'try to add to suitcase of player
		if not GetPlayerProgrammeCollection(playerID).AddScriptToSuitcase(script)
			return FALSE
		endif

		'remove from agency's lists
		local lists:TScript[][] = [listNormal2,listNormal]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = script then lists[j][i] = null
			Next
		Next

		return TRUE
	End Method


	Method BuyScriptFromPlayer:int(script:TScript)
		local buy:int = (script.owner > 0)

		'remove from player (lists and suitcase) - and give him money
		if GetPlayerCollection().IsPlayer(script.owner)
			GetPlayerProgrammeCollection(script.owner).RemoveScript(script, TRUE)
		endif

		'add to agency's lists - if not existing yet
		if not HasScript(script) then AddScript(script)

		return TRUE
	End Method


	Method ResetScriptOrder:int()
		local scripts:TList = CreateList()
		for local script:TScript = eachin listNormal
			scripts.addLast(script)
		Next
		for local script:TScript = eachin listNormal2
			scripts.addLast(script)
		Next
		listNormal = new TScript[listNormal.length]
		listNormal2 = new TScript[listNormal2.length]

		scripts.sort()

		'add again - so it gets sorted
		for local script:TScript = eachin scripts
			AddScript(script)
		Next

		RemoveAllGuiElements()
	End Method


	Method RemoveScript:int(script:TScript)
		local foundScript:int = FALSE
		'remove from agency's lists
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = script
					lists[j][i] = null
					foundScript = True
				endif
			Next
		Next

		return foundScript
	End Method


	Method AddScript:int(script:TScript)
		'try to fill the script into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TScript[][]

		lists = [listNormal,listNormal2]

		'loop through all lists - as soon as we find a spot
		'to place the programme - do so and return
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if lists[j][i] then continue
				GetScriptCollection().SetScriptOwner(script, -1)
				lists[j][i] = script
				return TRUE
			Next
		Next

		'there was no empty slot to place that script
		'so just give it back to the pool
		GetScriptCollection().SetScriptOwner(script, 0)

		return FALSE
	End Method



	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		For local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i].EmptyList()
		Next
		GuiListNormal2.EmptyList()
		GuiListSuitcase.EmptyList()
		For local guiScript:TGUIScript = eachin GuiManager.listDragged
			guiScript.remove()
			guiScript = null
		Next

		hoveredGuiScript = null
		draggedGuiScript = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Function


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with contracts the player does not have any longer

		'suitcase
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(GetPlayer().playerID)
		For local guiScript:TGUIScript = eachin GuiListSuitcase._slots
			'if the player has this script in suitcase or list, skip deletion
			if programmeCollection.HasScript(guiScript.script) then continue
			if programmeCollection.HasScriptInSuitcase(guiScript.script) then continue

			guiScript.remove()
			guiScript = null
		Next
		'agency lists
		For local i:int = 0 to GuiListNormal.length-1
			For local guiScript:TGUIScript = eachin GuiListNormal[i]._slots
				if not HasScript(guiScript.script)
					guiScript.remove()
					guiScript = null
				endif
			Next
		Next
		For local guiScript:TGUIScript = eachin GuiListNormal2._slots
			if not HasScript(guiScript.script)
				guiScript.remove()
				guiScript = null
			endif
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all contract-lists

		'normal list
		For local script:TScript = eachin listNormal
			if not script then continue
			local scriptAdded:int = FALSE

			'search the script in all of our lists...
			local scriptFound:int = FALSE
			For local i:int = 0 to GuiListNormal.length-1
				if scriptFound then continue
				if GuiListNormal[i].ContainsScript(script) then scriptFound = True
			Next

			'try to fill in one of the normalList-Parts
			if not scriptFound
				For local i:int = 0 to GuiListNormal.length-1
					if scriptAdded then continue
					if GuiListNormal[i].ContainsScript(script) then scriptAdded = True; Continue
					if GuiListNormal[i].getFreeSlot() < 0 then continue
					local block:TGUIScript = new TGUIScript.CreateWithScript(script)
					'change look
					block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

					'print "ADD guiListNormal #"+i+" missed new script: "+block.script.id + " -> "+ block.script.GetTitle()

					GuiListNormal[i].addItem(block, "-1")
					scriptAdded = true
				Next
				if not scriptAdded
					TLogger.log("ScriptAgency.RefreshGuiElements", "script exists but does not fit in GuiListNormal - script removed.", LOG_ERROR)
					RemoveScript(script)
				endif
			endif
		Next

		'normal2 list
		For local script:TScript = eachin listNormal2
			if not script then continue
			if GuiListNormal2.ContainsScript(script) then continue
			local block:TGUIScript = new TGUIScript.CreateWithScript(script)
			'change look
			block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

			'print "ADD guiListNormal2 missed new script: "+block.script.id + " -> "+ block.script.GetTitle()

			GuiListNormal2.addItem(block, "-1")
		Next

		'create missing gui elements for the players suitcase scripts
		For local script:TScript = eachin programmeCollection.suitcaseScripts
			if guiListSuitcase.ContainsScript(script) then continue
			local block:TGUIScript = new TGUIScript.CreateWithScript(script)
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			'print "ADD guiListSuitcase missed new script: "+block.script.id

			guiListSuitcase.addItem(block, "-1")
		Next

		haveToRefreshGuiElements = FALSE
	End Method


	'refills slots in the script agency
	'replaceOffer: remove (some) old scripts and place new there?
	Method ReFillBlocks:Int(replaceOffer:int=FALSE, replaceChance:float=1.0)
		local lists:TScript[][] = [listNormal,listNormal2]
		local script:TScript = null

		haveToRefreshGuiElements = TRUE

		'delete some random scripts
		if replaceOffer
			for local j:int = 0 to lists.length-1
				for local i:int = 0 to lists[j].length-1
					if not lists[j][i] then continue

					if RandRange(0,100) < replaceChance*100
						'with 30% chance the script gets trashed
						'and a completely new one will get created
						if RandRange(0,100) < 30
							GetScriptCollection().Remove(lists[j][i])
						'else just give it back to the collection
						'(reset owner)
						else
							GetScriptCollection().SetScriptOwner(lists[j][i], 0)
						endif
						'unlink from this list
						lists[j][i] = null
					endif
				Next
			Next
		endif


		'=== ACTUALLY CREATE SCRIPTS ===
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				'if exists and is valid...skip it
				if lists[j][i] then continue

				'get a new script
				script = GetScriptCollection().GetRandomAvailable()

				'add new script to slot
				if script
					GetScriptCollection().SetScriptOwner(script, -1)
					lists[j][i] = script
				endif
			Next
		Next
	End Method



	'===================================
	'Script Agency: Room screen
	'===================================

	'if players are in the agency during changes
	'to their programme collection, react to...
	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("scriptagency") then return FALSE

		GetInstance().RefreshGuiElements()
	End Function


	'in case of right mouse button click a dragged script is
	'placed at its original spot again
	Function onClickScript:int(triggerEvent:TEventBase)
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiScript:TGUIScript= TGUIScript(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiScript or not guiScript.isDragged() then return FALSE

		'remove gui object
		guiScript.remove()
		guiScript = null

		'rebuild at correct spot
		GetInstance().RefreshGuiElements()

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	Function onMouseOverScript:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("scriptagency") then return FALSE

		local item:TGUIScript = TGUIScript(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiScript = item
		if item.isDragged() then draggedGuiScript = item

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropScriptOnVendor:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("scriptagency") then return FALSE

		local guiBlock:TGUIScript = TGUIScript( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver or receiver <> VendorArea then return FALSE

		local parent:TGUIobject = guiBlock._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local senderList:TGUIScriptSlotList = TGUIScriptSlotList(parent)
		if not senderList then return FALSE

		'if coming from suitcase, try to remove it from the player
		if senderList = GuiListSuitcase
			if not GetInstance().BuyScriptFromPlayer(guiBlock.script)
				triggerEvent.setVeto()
				return FALSE
			endif
		else
			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveScript(guiBlock.script)
			GetInstance().AddScript(guiBlock.script)
		endif
		'remove the block, will get recreated if needed
		guiBlock.remove()
		guiBlock = null

		'something changed...refresh missing/obsolete...
		GetInstance().RefreshGuiElements()

		return TRUE
	End function


	'in this stage, the item is already added to the new gui list
	'we now just add or remove it to the player or vendor's list
	Function onDropScript:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("scriptagency") then return FALSE

		local guiScript:TGUIScript = TGUIScript(triggerEvent._sender)
		local receiverList:TGUIScriptSlotList = TGUIScriptSlotList(triggerEvent._receiver)
		if not guiScript or not receiverList then return FALSE

		'get current owner of the script, as the field "owner" is set
		'during buy we cannot rely on it. So we check if the player has
		'the script in the suitcaseScriptList
		local owner:int = guiScript.script.owner
		if owner <= 0 and GetPlayerProgrammeCollection(GetPlayerCollection().playerID).HasScriptInSuitcase(guiScript.script)
			owner = GetPlayerCollection().playerID
		endif

		'find out if we sell it to the vendor or drop it to our suitcase
		if receiverList <> GuiListSuitcase
			guiScript.InitAssets( guiScript.getAssetName(-1, FALSE ), guiScript.getAssetName(-1, TRUE ) )

			'no problem when dropping vendor programme to vendor..
			if owner <= 0 then return TRUE

			if not GetInstance().BuyScriptFromPlayer(guiScript.script)
				triggerEvent.setVeto()
				return FALSE
			endif

			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveScript(guiScript.script)
			GetInstance().AddScript(guiScript.script)
		else
			guiScript.InitAssets(guiScript.getAssetName(-1, TRUE ), guiScript.getAssetName(-1, TRUE ))
			'no problem when dropping own scripts to suitcase..
			if owner = GetPlayerCollection().playerID then return TRUE
			if not GetInstance().SellScriptToPlayer(guiScript.script, GetPlayerCollection().playerID)
				triggerEvent.setVeto()
				return FALSE
			endif
		endIf

		return TRUE
	End Function


	Method onDrawRoom:int( triggerEvent:TEventBase )
		if VendorEntity Then VendorEntity.Render()
		GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		'make suitcase/vendor highlighted if needed
		local highlightSuitcase:int = False
		local highlightVendor:int = False

		if draggedGuiScript and draggedGuiScript.isDragged()
			'if not GetPlayerProgrammeCollection(GetPlayerCollection().playerID).HasScriptInSuitcase(draggedGuiScript.script)
			if draggedGuiScript.script.owner <= 0
				highlightSuitcase = True
			else
				highlightVendor = True
			endif
		endif

		if highlightVendor or highlightSuitcase
			local oldCol:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * (0.4 + 0.2 * sin(Time.GetTimeGone() / 5))

			if VendorEntity and highlightVendor then VendorEntity.Render()
			if highlightSuitcase then GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		endif


		GUIManager.Draw("scriptagency")

		if hoveredGuiScript
			'draw the current sheet
			hoveredGuiScript.DrawSheet()
		endif
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		if VendorEntity Then VendorEntity.Update()

		Game.cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiScript = null
		'reset dragged block too
		draggedGuiScript = null

		GUIManager.Update("scriptagency")
	End Method

End Type

'Dies hier ist die Raumauswahl im Fahrstuhl.
Type RoomHandler_ElevatorPlan extends TRoomHandler
	Global _instance:RoomHandler_ElevatorPlan
	Global _initDone:int = False

	Function GetInstance:RoomHandler_ElevatorPlan()
		if not _instance then _instance = new RoomHandler_ElevatorPlan
		if not _initDone then _instance.Initialize()
		return _instance
	End Function

	
	Method Initialize:Int()
		if _initDone then return False
		_initDone = True

		GetRoomHandlerCollection().SetHandler("elevatorplan", self)

		'create an intial plan (might be empty if no doors are loaded yet)
		'so pay attention to run it once AFTER room creation/loading
		ReCreatePlan()
	End Method


	Function ReCreatePlan()
		GetRoomBoard().Reset()
		For local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().List
			'create the sign in the roomplan (if not "invisible door")
			If door.doorType >= 0 then new TRoomBoardSign.Init(door)
		Next
	End Function


	Method onDrawRoom:int( triggerEvent:TEventBase )
		GetRoomBoard().DrawSigns()
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		local mouseClicked:int = MouseManager.IsClicked(1)

		Game.cursorstate = 0

		'if possible, change the target to the clicked door
		if mouseClicked
			local sign:TRoomBoardSign = GetRoomBoard().GetSignByXY(MouseManager.x,MouseManager.y)
			if sign and sign.door then GetPlayer().GetFigure().SendToDoor(sign.door)
			if mouseClicked then MouseManager.ResetKey(1)
		endif

		GetRoomBoard().UpdateSigns(False)
	End Method
End Type


Type RoomHandler_Roomboard extends TRoomHandler

	Global _instance:RoomHandler_Roomboard
	Global _initDone:int = False

	Function GetInstance:RoomHandler_Roomboard()
		if not _instance then _instance = new RoomHandler_Roomboard
		if not _initDone then _instance.Initialize()
		return _instance
	End Function

	
	Method Initialize:Int()
		if _initDone then return False
		_initDone = True

		GetRoomHandlerCollection().SetHandler("roomboard", self)
	End Method


	Method AbortScreenActions:Int()
		GetRoomBoard().DropBackDraggedSigns()
		GetRoomBoard().UpdateSigns(False)
	End Method
	

	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent.GetSender())
		if not figure then return FALSE

		'only pay attention to players
		if figure.playerID
			'roomboard left without animation as soon as something dragged but leave forced
			If GetRoomBoard().AdditionallyDragged > 0
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		GetRoomBoard().DrawSigns()
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		Game.cursorstate = 0

		'only allow dragging of roomsigns when no exitapp-dialoge exists
'RONNY
'		if not TApp.ExitAppDialogue
			GetRoomBoard().UpdateSigns(True)
'		else
'			TRoomBoardSign.DropBackDraggedSigns()
'			TRoomBoardSign.UpdateAll(False)
'		endif
	End Method
End Type




'Betty
Type RoomHandler_Betty extends TRoomHandler
	Global _instance:RoomHandler_Betty
	Global _initDone:int = False

	Function GetInstance:RoomHandler_Betty()
		if not _instance then _instance = new RoomHandler_Betty
		if not _initDone then _instance.Initialize()
		return _instance
	End Function

	
	Method Initialize:Int()
		if _initDone then return False
		_initDone = True

		GetRoomHandlerCollection().SetHandler("betty", self)
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		For Local i:Int = 1 To 4
			local sprite:TSprite = GetSpriteFromRegistry("gfx_room_betty_picture1")
			Local picY:Int = 240
			Local picX:Int = 410 + i * (sprite.area.GetW() + 5)
			sprite.Draw( picX, picY )
			SetAlpha 0.4
			GetPlayerCollection().Get(i).color.copy().AdjustRelative(-0.5).SetRGB()
			DrawRect(picX + 2, picY + 8, 26, 28)
			SetColor 255, 255, 255
			SetAlpha 1.0
			local x:float = picX + Int(sprite.area.GetW() / 2) - Int(GetPlayerCollection().Get(i).Figure.Sprite.framew / 2)
			local y:float = picY + sprite.area.GetH() - 30
			GetPlayerCollection().Get(i).Figure.Sprite.DrawClipped(new TRectangle.Init(x, y, -1, sprite.area.GetH()-16), null, 8)
		Next

		TDialogue.DrawDialog("default", 440, 120, 280, 110, "StartLeftDown", 0, GetLocale("DIALOGUE_BETTY_WELCOME"), 0, GetBitmapFont("Default",14))
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'nothing yet
	End Method
End Type



'RoomAgency
Type RoomHandler_RoomAgency extends TRoomHandler
	Global _instance:RoomHandler_RoomAgency
	Global _initDone:int = False

	Function GetInstance:RoomHandler_RoomAgency()
		if not _instance then _instance = new RoomHandler_RoomAgency
		if not _initDone then _instance.Initialize()
		return _instance
	End Function

	
	Method Initialize:Int()
		if _initDone then return False
		_initDone = True	

		GetRoomHandlerCollection().SetHandler("roomagency", self)
	End Method


	Function RentRoom:int(room:TRoom, owner:int=0)
		print "RoomHandler_RoomAgency.RentRoom()"
		room.ChangeOwner(owner)
	End Function


	Function CancelRoom:int(room:TRoom)
		print "RoomHandler_RoomAgency.CancelRoom()"
		room.ChangeOwner(0)
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
	Global changeRoleTimer:TIntervalTimer = TIntervalTimer.Create(3200, 0)
	Global fadeTimer:TIntervalTimer = TIntervalTimer.Create(1000, 0)
	Global fadeMode:int = 0 '0 = fadein, 1=stay, 2=fadeout
	Global fadeRole:int = TRUE
	Global fadeValue:float = 0.0

	Global _instance:RoomHandler_Credits
	Global _initDone:int = False

	Function GetInstance:RoomHandler_Credits()
		if not _instance then _instance = new RoomHandler_Credits
		if not _initDone then _instance.Initialize()
		return _instance
	End Function

	
	Method Initialize:Int()
		if _initDone then return False
		_initDone = True	

		GetRoomHandlerCollection().SetHandler("credits", self)


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

		role = CreateRole("Handbuch", TColor.Create(170,210,250))
		role.addCast("Själe")

		role = CreateRole("Datenbank-Team", TColor.Create(210,120,250))
		role.addCast("Ronny Otto")
		role.addCast("Martin Rackow")
		role.addCast("Själe")
		role.addCast("SpeedMinister")
		role.addCast("u.a. Freiwillige")

		role = CreateRole("Tester", TColor.Create(160,180,250))
		role.addCast("...und Motivationsteam")
		'old testers (< 2007)
		'role.addCast("Ceddy")
		'role.addCast("dirkw")
		'role.addCast("djmetzger")
		role.addCast("Basti")
		role.addCast("domi")
		role.addCast("Kurt TV")
		role.addCast("red")
		role.addCast("Själe")
		role.addCast("SushiTV")
		role.addCast("Ulf")

		role.addCast("...und all die anderen Fehlermelder im Forum")


		role = CreateRole("", TColor.clWhite)
		role.addCast("")

		role = CreateRole("Besucht uns im Netz", TColor.clWhite)
		role.addCast("http://www.tvgigant.de")

		role = CreateRole("", TColor.clWhite)
		role.addCast("")

	End Method


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
	Method onEnterRoom:int( triggerEvent:TEventBase )
		'only handle the players figure
		if TFigure(triggerEvent.GetSender()) <> GetPlayer().figure then return False

		fadeTimer.Reset()
		changeRoleTimer.Reset()
		currentRolePosition = 0
		currentCastPosition = 0
		fadeMode = 0
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		SetAlpha fadeValue

		local fontRole:TBitmapFont = GetBitmapFont("Default",28, BOLDFONT)
		local fontCast:TBitmapFont = GetBitmapFont("Default",20, BOLDFONT)
		if not fadeRole then SetAlpha 1.0
		fontRole.DrawBlock(GetRole().name.ToUpper(), 20,180, GetGraphicsManager().GetWidth() - 40, 40, new TVec2D.Init(ALIGN_CENTER), GetRole().color, 2, 1, 0.6)
		SetAlpha fadeValue
		if GetCast() then fontCast.DrawBlock(GetCast(), 150,210, GetGraphicsManager().GetWidth() - 300, 80, new TVec2D.Init(ALIGN_CENTER), TColor.CreateGrey(230), 2, 1, 0.6)

		SetAlpha 1.0
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
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
	End Method
End Type



Function Init_ConnectRoomHandlers()
	'connect Update/Draw-Events
	RoomHandler_Office.GetInstance()
	RoomHandler_News.GetInstance()
	RoomHandler_Boss.GetInstance()
	RoomHandler_Archive.GetInstance()

	RoomHandler_Studio.GetInstance()

	RoomHandler_AdAgency.GetInstance()
	RoomHandler_ScriptAgency.GetInstance()
	RoomHandler_MovieAgency.GetInstance()
	RoomHandler_RoomAgency.GetInstance()

	RoomHandler_Betty.GetInstance()

	RoomHandler_ElevatorPlan.GetInstance()
	RoomHandler_Roomboard.GetInstance()

	RoomHandler_Credits.GetInstance()
End Function



Function Init_CreateAllRooms()
	local room:TRoom = null
	Local roomMap:TMap = TMap(GetRegistry().Get("rooms"))
	if not roomMap then Throw("ERROR: no room definition loaded!")

	'remove all previous rooms
	GetRoomCollection().Reset()

	For Local vars:TData = EachIn roomMap.Values()
		'==== ROOM ====
		local room:TRoom = new TRoom
		room.Init(..
			vars.GetString("roomname"),  ..
			[ ..
				vars.GetString("tooltip"), ..
				vars.GetString("tooltip2") ..
			], ..
			vars.GetInt("owner",-1),  ..
			vars.GetInt("size", 1)  ..
		)
		room.fakeRoom = vars.GetBool("fake", FALSE)
		room.screenName = vars.GetString("screen")


		'only add if not already there
		if not GetRoomCollection().Get(room.id)
			GetRoomCollection().Add(room)
		else
			room = GetRoomCollection().Get(room.id)
		endif

		'==== DOOR ====
		local door:TRoomDoor = new TRoomDoor
		door.Init(..
			room.id,..
			vars.GetInt("doorslot"), ..
			vars.GetInt("floor"), ..
			vars.GetInt("doortype") ..
		)
		GetRoomDoorBaseCollection().Add( door )
		'add the door to the building (sets parent etc)
		GetBuilding().AddDoor(door)

		'override defaults
		if not vars.GetBool("doortooltip") then door.showTooltip = False
		if vars.GetInt("doorwidth") > 0 then door.area.dimension.setX( vars.GetInt("doorwidth") )
		if vars.GetInt("x",-1000) <> -1000 then door.area.position.SetX(vars.GetInt("x"))



		'==== HOTSPOTS ====
		local hotSpots:TList = TList( vars.Get("hotspots") )
		if hotSpots
			for local conf:TData = eachin hotSpots
				local name:string 	= conf.GetString("name")
				local x:int			= conf.GetInt("x", -1)
				local y:int			= conf.GetInt("y", -1)
				local bottomy:int	= conf.GetInt("bottomy", 0)
				local floor:int 	= conf.GetInt("floor", -1)
				local width:int 	= conf.GetInt("width", 0)
				local height:int 	= conf.GetInt("height", 0)
				local tooltipText:string	 	= conf.GetString("tooltiptext")
				local tooltipDescription:string	= conf.GetString("tooltipdescription")

				'align at bottom of floor
				if floor >= 0 then y = TBuilding.GetFloorY2(floor) - height

				local hotspot:THotspot = new THotspot.Create( name, x, y - bottomy, width, height)
				hotspot.setTooltipText( GetLocale(tooltipText), GetLocale(tooltipDescription) )

				room.addHotspot( hotspot )
			next
		endif

	Next
End Function

