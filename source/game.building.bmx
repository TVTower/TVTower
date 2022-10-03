SuperStrict
Import "basefunctions.bmx" 'catmullromspline
Import "Dig/base.framework.tooltip.bmx"
Import "Dig/base.util.profiler.bmx"
Import "Dig/base.util.registry.spriteentityloader.bmx"
Import "common.misc.hotspot.bmx"
Import "game.building.base.bmx"
Import "game.building.elevator.bmx"
Import "game.player.base.bmx"
Import "game.room.bmx"
Import "game.room.roomdoor.bmx"
Import "game.world.bmx"
Import "game.gameconfig.bmx"
Import "game.figure.bmx" 'TFigureTarget with hotspot support


'TODO: split TBuilding into TBuilding + TBuildingArea
'      TBuildingArea then contains background buildings, ufo ...


'Summary: Type of building, area around it and doors,...
Type TBuilding Extends TBuildingBase

	Field ufo_normal:TSpriteEntity 				{nosave}
	Field ufo_beaming:TSpriteEntity				{nosave}

	Field UFO_Path:TCatmullRomSpline = New TCatmullRomSpline {nosave}
	Field UFO_PathCurrentDistanceOld:Float = 0.0
	Field UFO_PathCurrentDistance:Float = 0.0
	Field UFO_MovementStarted:Int = False
	Field UFO_MovementBaseSpeed:Float = 0.0
	Field UFO_DoBeamAnimation:Int = False
	Field UFO_BeamAnimationDone:Int	= False

	Field christmasTree1:TSpriteEntity			{nosave}
	Field christmasTree2:TSpriteEntity			{nosave}

	Field gfx_bgBuildings:TSprite[6]			{nosave}
	Field gfx_building:TSprite					{nosave}
	Field gfx_buildingEntrance:TSprite			{nosave}
	Field gfx_buildingEntranceWall:TSprite		{nosave}
	Field gfx_buildingFence:TSprite				{nosave}
	Field gfx_buildingRoof:TSprite				{nosave}

	Field gfx_plant3a:TSprite					{nosave}
	Field gfx_plant3b:TSprite					{nosave}
	Field gfx_plant1:TSprite					{nosave}
	Field gfx_plant2:TSprite					{nosave}
	Field gfx_plant4:TSprite					{nosave}
	Field gfx_plant6:TSprite					{nosave}

	'the room used for the building
	Field room:TRoomBase = Null
	Field roomUsedTooltip:TTooltip = Null

	Global softDrinkMachineActive:Int = False
	Global softDrinkMachine:TSpriteEntity

	Global _backgroundModified:Int = False
	Global _eventListeners:TEventListenerBase[]

	Global _profilerKey_DrawBuildingBG:TLowerString = new TLowerString.Create("Draw-Building-Background")


	'override - create a Building instead of BuildingBase
	Function GetInstance:TBuilding()
		'we skip reusing field data because we "initialize" it anyways
		'if not done already
		if not TBuilding(_instance)
			_instance = new TBuilding
			'else we would take over values here
		endif
		Return TBuilding(_instance)
	End Function


	Method Initialize:Int()
		area.position.SetX(0)
		area.dimension.SetXY(800, floorCount * floorHeight + 50) 'occupy full area

		'create an entity spawning the complete inner area of the building
		'this entity can be used as parent for other entities - which
		'want to layout to the "inner area" of the building (eg. doors)
		If Not buildingInner
			buildingInner = New TRenderableEntity
			buildingInner.area.position.SetXY(leftWallX + innerX, 0)
			'subtract missing "splitter wall" of last floor
			buildingInner.area.dimension.SetXY(floorWidth, floorCount * floorHeight - 7)
			'set building as parent for proper alignment
			buildingInner.SetParent(Self)
		EndIf

		'call to set graphics, paths for objects and other stuff
		InitGraphics()

		'now "gfx_building" exists and we can displace the building
		area.position.SetY(0 - gfx_building.area.GetH() + 5 * floorHeight)

		'=== SETUP ELEVATOR ===
		GetElevator().Initialize()
		'we want all players to alreay wait in front of the elevator
		'and not only 1 player sending it while all others wait
		'so we move the elevator to a higher floor, so it just
		'reaches floor 0 when all are already waiting
		'floor 9 is just enough for the players
		GetElevator().currentFloor = 9

		GetElevator().SetParent(Self.buildingInner)
		GetElevator().area.position.SetX(floorWidth/2 - GetElevator().GetDoorWidth()/2)
		GetElevator().area.position.SetY(GetFloorY2(GetElevator().CurrentFloor) - GetElevator().spriteInner.area.GetH())
		'the logic to use for the elevator
		'param = 1: PrivilegePlayerMode active
		'param = 0: do not lift players on the same route
		GetElevator().RouteLogic = TElevatorSmartLogic.Create(GetElevator(), 0)


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]


		'=== register event listeners
		'handle savegame loading (assign sprites)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnLoad, onSaveGameLoad) ]
		'react on clicks to hotspots (elevator, softdrink machine)
		_eventListeners :+ [ EventManager.registerListenerFunction(THotSpot.eventKey_Hotspot_OnClick, onClickHotspot) ]
		'we want to get information about figures entering their desired target
		'(this can be "room", "hotspot" ... )
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Figure_OnEnterTarget, onEnterTarget) ]
	End Method


	'run when loading finished
	Function onSaveGameLoad:int(triggerEvent:TEventBase)
		TLogger.Log("TBuilding", "Savegame loaded - reassign sprites, recreate movement paths for gfx.", LOG_DEBUG | LOG_SAVELOAD)
		GetInstance().InitGraphics()

		local savedSaveGameVersion:Int = triggerEvent.GetData().GetInt("saved_savegame_version")
		'before version 19 rooms and doors could have same IDs
		'as one extended from TGameObject and the other from TEntityBase
		'with version 19 both extend from TEntityBase and this means
		'they have unique IDs then.
		'Here we give doors and hotspots new IDs just to avoid hickups
		If savedSaveGameVersion < 19
			For Local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().List
				'GUID can be kept (does not contain the ID) 
				TRoomDoorBase.LastID :+ 1 'this is actually TEntityBase
				door.id = LastID
			Next
			
			Local room:TRoomBase = GetRoomBaseCollection().GetFirstByDetails("building")

			For Local hotspot:THotspot = EachIn room.hotspots
				'GUID can be kept (does not contain the ID) 
				THotspot.LastID :+ 1 'this is actually TEntityBase
				hotspot.id = LastID
				hotspot.SetGUID()
			Next
		EndIf

		'reassign self as parent to all doors
		'-> just re-add them
		For Local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().List
			GetInstance().AddDoor(door)
		Next

		'reposition hotspots, prepare building sprite...
		GetInstance().Init()

		return True
	End Function


	Method PrepareBuildingSprite:Int()
		'TODO: copy original building sprite (empty) before modifying
		'      the first time - so it allows various layouts of room

		'=== BACKGROUND DECORATION ===
		'draw sprites directly on the building sprite if not done yet
		If Not _backgroundModified
			Local Pix:TPixmap = LockImage(gfx_building.parent.image)

			'=== DRAW NECESSARY ITEMS ===
			'credits sign on floor 13
			GetSpriteFromRegistry("gfx_building_credits").DrawOnImage(Pix, innerX2 - 5, GetFloorY2(13), -1, ALIGN_RIGHT_BOTTOM)
			'roomboard on floor 0
			GetSpriteFromRegistry("gfx_building_roomboard").DrawOnImage(Pix, innerX2 - 30, GetFloorY2(0), -1, ALIGN_RIGHT_BOTTOM)

			'=== DRAW ELEVATOR BORDER ===
			Local elevatorBorder:TSprite= GetSpriteFromRegistry("gfx_building_Fahrstuhl_Rahmen")
			For Local i:Int = 0 To 13
				DrawImageOnImage(elevatorBorder.getImage(), Pix, 250, 67 - Int(elevatorBorder.area.GetH()) + floorHeight*i)
				DrawImageOnImage(elevatorBorder.getImage(), Pix, 250, 67 - Int(elevatorBorder.area.GetH()) + floorHeight*i)
			Next

			'=== DRAW DOORS ===
			For Local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().List
				'skip invisible doors (without door-sprite)
				If Not door.IsVisible() Then Continue

				Local sprite:TSprite = door.GetSprite()
				If Not sprite Then Continue

				sprite.DrawOnImage(pix, Int(innerX + door.area.GetX()), Int(door.area.GetY()), Int(MathHelper.Clamp(door.doorType, 0,5)), ALIGN_LEFT_BOTTOM)
			Next


			'=== DRAW DECORATION ===
			'floor 0
			GetSpriteFromRegistry("gfx_building_Wandlampe").DrawOnImage(Pix, innerX + 145, GetFloorY2(0), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Wandlampe").DrawOnImage(Pix, innerX2 - 145, GetFloorY2(0), -1, ALIGN_RIGHT_BOTTOM)
			'floor 1
			GetSpriteFromRegistry("gfx_building_picture2").DrawOnImage(Pix, innerX2 - 70, GetFloorY2(1), -1, ALIGN_CENTER_BOTTOM)
			GetSpriteFromRegistry("gfx_building_standlightSmall").DrawOnImage(Pix, innerX2 - 70, GetFloorY2(1), -1, ALIGN_CENTER_BOTTOM)
			'floor 3
			GetSpriteFromRegistry("gfx_building_picture1").DrawOnImage(Pix, innerX2 - 80, GetFloorY2(3), -1, ALIGN_CENTER_BOTTOM)
			GetSpriteFromRegistry("gfx_building_standlightSmall").DrawOnImage(Pix, innerX2 - 100, GetFloorY2(3), -1, ALIGN_CENTER_BOTTOM)
			GetSpriteFromRegistry("gfx_building_standlightSmall").DrawOnImage(Pix, innerX2 - 60, GetFloorY2(3), -1, ALIGN_CENTER_BOTTOM)
			'floor 4
			GetSpriteFromRegistry("gfx_building_Pflanze5").DrawOnImage(Pix, innerX2 - 85, GetFloorY2(4), -1, ALIGN_LEFT_BOTTOM)
			'floor 7
			GetSpriteFromRegistry("gfx_building_Pflanze2").DrawOnImage(Pix, innerX + 45, GetFloorY2(7), -1, ALIGN_LEFT_BOTTOM)
			'floor 12
			GetSpriteFromRegistry("gfx_building_picture2").DrawOnImage(Pix, innerX2 - 50, GetFloorY2(12), -1, ALIGN_CENTER_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Pflanze4").DrawOnImage(Pix, innerX + 40, GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Pflanze6").DrawOnImage(Pix, innerX2 - 95, GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)
			'floor 13
			GetSpriteFromRegistry("gfx_building_Pflanze2").DrawOnImage(Pix, innerX + 105, GetFloorY2(13), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Pflanze3").DrawOnImage(Pix, innerX2 - 105, GetFloorY2(13), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Wandlampe").DrawOnImage(Pix, innerX + 125, GetFloorY2(13), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Wandlampe").DrawOnImage(Pix, innerX2 - 125, GetFloorY2(13), -1, ALIGN_RIGHT_BOTTOM)

			UnlockImage(gfx_building.parent.image)
			Pix = Null

			_backgroundModified = True
		EndIf
	End Method


	Method InitGraphics()
		'==== UFO ====
		'sprites
		ufo_normal	= New TSpriteEntity
		ufo_normal.SetSprite(GetSpriteFromRegistry("gfx_building_BG_ufo"))
		ufo_normal.area.position.SetXY(0,100)
		ufo_normal.GetFrameAnimations().Set(TSpriteFrameAnimation.CreateSimple("default", 9, 100))

		ufo_beaming	= New TSpriteEntity
		ufo_beaming.SetSprite(GetSpriteFromRegistry("gfx_building_BG_ufo2"))
		ufo_beaming.area.position.SetXY(0,100)
		ufo_beaming.GetFrameAnimations().Set(TSpriteFrameAnimation.CreateSimple("default", 9, 100))

		'movement
		Local displaceY:Int = 280, displaceX:Int = 5
		UFO_Path = New TCatmullRomSpline
		UFO_path.addXY( -60 +displaceX, -410 +displaceY)
		UFO_path.addXY( -50 +displaceX, -400 +displaceY)
		UFO_path.addXY(  50 +displaceX, -350 +displaceY)
		UFO_path.addXY(-100 +displaceX, -300 +displaceY)
		UFO_path.addXY( 100 +displaceX, -250 +displaceY)
		UFO_path.addXY(  40 +displaceX, -200 +displaceY)
		UFO_path.addXY(  50 +displaceX, -190 +displaceY)
		UFO_path.addXY(  60 +displaceX, -200 +displaceY)
		UFO_path.addXY(  70 +displaceX, -250 +displaceY)
		UFO_path.addXY( 400 +displaceX, -700 +displaceY)
		UFO_path.addXY( 410 +displaceX, -710 +displaceY)


		'==== CHRISTMAS TREES ====
		christmasTree1 = GetSpriteEntityFromRegistry("entity_building_christmastree1")
		christmasTree2 = GetSpriteEntityFromRegistry("entity_building_christmastree2")


		'==== BACKGROUND BUILDINGS ====
		gfx_bgBuildings[0] = GetSpriteFromRegistry("gfx_building_BG_Ebene3L")
		gfx_bgBuildings[1] = GetSpriteFromRegistry("gfx_building_BG_Ebene3R")
		gfx_bgBuildings[2] = GetSpriteFromRegistry("gfx_building_BG_Ebene2L")
		gfx_bgBuildings[3] = GetSpriteFromRegistry("gfx_building_BG_Ebene2R")
		gfx_bgBuildings[4] = GetSpriteFromRegistry("gfx_building_BG_Ebene1L")
		gfx_bgBuildings[5] = GetSpriteFromRegistry("gfx_building_BG_Ebene1R")

		'building assets
		gfx_building = GetSpriteFromRegistry("gfx_building")
		gfx_buildingEntrance = GetSpriteFromRegistry("gfx_building_Eingang")
		gfx_buildingEntranceWall = GetSpriteFromRegistry("gfx_building_EingangWand")
		gfx_buildingFence = GetSpriteFromRegistry("gfx_building_Zaun")
		gfx_buildingRoof = GetSpriteFromRegistry("gfx_building_roof")

		gfx_plant3a = GetSpriteFromRegistry("gfx_building_Pflanze3a")
		gfx_plant3b = GetSpriteFromRegistry("gfx_building_Pflanze3b")
		gfx_plant1 = GetSpriteFromRegistry("gfx_building_Pflanze1")
		gfx_plant2 = GetSpriteFromRegistry("gfx_building_Pflanze2")
		gfx_plant4 = GetSpriteFromRegistry("gfx_building_Pflanze4")
		gfx_plant6 = GetSpriteFromRegistry("gfx_building_Pflanze6")

		'=== SETUP SOFTDRINK MACHINE ===
		softDrinkMachine = New TSpriteEntity
		softDrinkMachine.SetSprite(GetSpriteFromRegistry("gfx_building_softdrinkmachine"))
		softDrinkMachine.GetFrameAnimations().Set(TSpriteFrameAnimation.Create("default", [ [0,70] ], 0, 0) )
		softDrinkMachine.GetFrameAnimations().Set(TSpriteFrameAnimation.CreateSimple("use", 15, 50))
		softDrinkMachineActive = False
	End Method


	Method Init:Int()
		'assign room
		room = GetRoomBaseCollection().GetFirstByDetails("building")

		For Local hotspot:THotspot = EachIn room.hotspots
			'set building inner as parent, so "getScreenX/Y()" can
			'layout properly)
			hotspot.setParent(Self.buildingInner)

			'move elevatorplan hotspots to the elevator
			'also make them enterable
			If hotspot.name = "elevatorplan"
				hotspot.SetEnterable(True)
				hotspot.area.position.setX( GetElevator().area.getX() )
				hotspot.area.dimension.setXY( GetElevator().GetDoorWidth(), 58 )
			EndIf
		Next

		For Local figure:TFigureBase = EachIn GetFigureBaseCollection()
			figure.setParent(Self.buildingInner)
		Next

		PrepareBuildingSprite()
	End Method


	Method GetTargetID:Int(name:String, owner:Int, onFloor:Int, buildingTargetType:Int) override
		If buildingTargetType = TVTBuildingTargetType.NONE or buildingTargetType = TVTBuildingTargetType.DOOR
			local door:TRoomDoorBase = GetRoomDoorBaseCollection().GetFirstByDetails(name, owner, onFloor)
			If door Then Return door.GetID()
		EndIf
		
		If buildingTargetType = TVTBuildingTargetType.NONE or buildingTargetType = TVTBuildingTargetType.HOTSPOT
			If Not room then room = GetRoomBaseCollection().GetFirstByDetails("building")

			For Local hotspot:THotspot = EachIn room.hotspots
				If hotspot.name <> name Then Continue
				If onFloor >= 0 and GetFloor(hotspot.area.GetY()) <> onFloor Then Continue
				
				Return hotspot.GetID()
			Next
		EndIf
		
		Return -1
	End Method
	
	
	Method GetTarget:Object(name:String, owner:Int, onFloor:Int, buildingTargetType:Int) override
		If buildingTargetType = TVTBuildingTargetType.NONE or buildingTargetType = TVTBuildingTargetType.DOOR
			local door:TRoomDoorBase = GetRoomDoorBaseCollection().GetFirstByDetails(name, owner, onFloor)
			If door Then Return door
		EndIf
		
		If buildingTargetType = TVTBuildingTargetType.NONE or buildingTargetType = TVTBuildingTargetType.HOTSPOT
			If Not room then room = GetRoomBaseCollection().GetFirstByDetails("building")

			For Local hotspot:THotspot = EachIn room.hotspots
				If hotspot.name <> name Then Continue
				If onFloor >= 0 and GetFloor(hotspot.area.GetY()) <> onFloor Then Continue
				
				Return hotspot
			Next
		EndIf
		
		Return Null
	End Method


	Method GetTarget:Object(id:Int)
		If Not room Then room = GetRoomBaseCollection().GetFirstByDetails("building")

		For local h:THotspot = EachIn room.hotspots
			if h.GetID() = id Then Return h
		Next

		For local r:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().List
			if r.GetID() = id Then Return r
		Next
		
		Return Null
	End Method


	Method AddDoor:Int(door:TRoomDoorBase)
		If Not door Then Return False
		'add to innerBuilding, so doors can properly layout in the
		'inner area
		door.SetParent(Self.buildingInner)
		'move door accordingly (only if a slot is defined)
		if door.doorSlot > 0
			door.area.position.SetX(GetDoorXFromDoorSlot(door.doorSlot))
		EndIf
		door.area.position.SetY(GetFloorY2(door.onFloor))
	End Method


	Function onEnterTarget:Int( triggerEvent:TEventBase )
		Local figure:TFigureBase = TFigureBase( triggerEvent._sender )
		If Not figure Then Return False

		'we are only interested in hotspots
		Local hotspot:THotSpot = THotSpot(triggerEvent.GetReceiver())
		If Not hotspot Then Return False

		If hotspot.name = "elevatorplan"
			'Print "figure "+figure.name+" reached elevatorplan"

			Local room:TRoomBase = GetRoomBaseCollection().GetFirstByDetails("elevatorplan")
			If Not room Then Print "[ERROR] room: elevatorplan not not defined. Cannot enter that room.";Return False

			figure.EnterLocation(room)
			Return True
		EndIf

		Return False
	End Function


	Function onClickHotspot:Int( triggerEvent:TEventBase )
		Local hotspot:THotspot = THotspot( triggerEvent._sender )
		If Not hotspot Then Return False 'or hotspot.name <> "elevatorplan" then return FALSE
		'not interested in others
		If Not GetInstance().room.hotspots.contains(hotspot) Then Return False

		'hotspot position is LOCAL to building, so no transition needed
		GetPlayerBase().GetFigure().changeTarget( Int(hotspot.area.getX() + hotspot.area.getW()/2), Int(hotspot.area.getY()) )
		'ignore clicks to elevator plans on OTHER floors
		'in this case just move to the target, but do not "enter" the room
		If hotspot.name <> "elevatorplan" Or GetInstance().GetFloor(hotspot.area.GetY()) = GetInstance().GetFloor(GetPlayerBase().GetFigure().area.GetY())
			GetPlayerBase().GetFigure().SetTarget( new TFigureTarget.Init(hotspot) )
		EndIf

		'handled left click
		MouseManager.SetClickHandled(1)

		return True
	End Function


	'override
	Method GetTravelDuration:int(entity:TEntity, targetX:int, targetFloor:int)
		if not TFigureBase(entity) then return Super.GetTravelDuration(entity, targetX, targetFloor)

		local figure:TFigureBase = TFigureBase(entity)

		'same floor ?
		if figure.GetFloor() = targetFloor
			local pixelsPerSecond:Float = figure.initialdx * GetBuildingTime().GetTimeFactor()
			local pixelDistance:int = int(abs(figure.area.GetX() - targetX))
			local buildingSeconds:Float = pixelDistance / pixelsPerSecond
'Ausrechnen, wie "Haussekunden" sich in "Spielsekunden" ausdruecken lassen
'(Verhaeltnis)
			return figure.initialdx * GetBuildingTime().GetTimeFactor()
		endif

		'other floor:
		'- check elevator and its current route-list
		'- if figure is on the list already (and target floor is the same)
		'  then use this in the calculation !
		'  Wichtig: wenn Fahrstuhl zu nutzen: Hinweg + Rueckweg



		return 0
	End Method
	
	
	Method GetElevatorPlanHotspot:THotspot(forFloor:Int)
		if not room then room = GetRoomBaseCollection().GetFirstByDetails("building")

		Local planX:Int = GetElevator().GetDoorCenterX()
		Local planY:Int = GetFloorY2(forFloor)
		For Local hotspot:THotspot = EachIn room.hotspots
			If hotspot.name <> "elevatorplan" Then Continue
			If GetFloor(hotspot.area.GetY()) <> forFloor Then Continue

			Return hotspot
		Next
		Return Null
	End Method


	Method ActivateSoftdrinkMachine:Int()
		softDrinkMachineActive = True
	End Method


	Method CenterToPlayer()
		if not TVTGhostBuildingScrollMode
			'something observed?
			local entity:TSpriteEntity = TSpriteEntity(GameConfig.observedObject)
			if not entity or not GameConfig.observerMode
				entity = GetPlayerBase().GetFigure()
			endif

			'subtract 7 because of missing "wall" in last floor
			area.position.y =  2 * floorHeight - 7 + 50 - entity.area.GetY()
			'add 50 for roof
		else
			if MouseManager.y <= 20 then area.position.y :+ ((20 - MouseManager.y) * 0.75)
			if MouseManager.y >= GetGraphicsManager().GetHeight() - 20 then area.position.y :- ((20 - (GetGraphicsManager().GetHeight() - MouseManager.y)) * 0.75)
'				ghostScrollingPosition = MathHelper.Clamp(ghostScrollingPosition, - 637, 88)

'				area.position.y = ghostScrollingPosition
		endif
	End Method


	Method Update:Int()
		'update softdrinkmachine
		softDrinkMachine.Update()

		if GameConfig.isChristmasTime
			christmasTree1.Update()
			christmasTree2.Update()
		endif

		'center player
		If not GetPlayerBase().GetFigure().IsInRoom() or GetPlayerBase().GetFigure().IsChangingRoom() or GameConfig.observerMode
			CenterToPlayer()
		EndIf


		Local deltaTime:Float = GetDeltaTimer().GetDelta()
		area.position.y = MathHelper.Clamp(area.position.y, - 637, 88)
		UpdateBackground(deltaTime)


		'update hotspot tooltips
		If room
			'for now: instead of checking each hotspot versus a the area
			'without the interface, we just check if the mouse is not
			'at the interface area and skip updating at all
			if GameConfig.nonInterfaceRect.ContainsVec( MouseManager.GetPosition() )
				For Local hotspot:THotspot = EachIn room.hotspots
					'disable elevatorplan hotspot tooltips in other floors
					If hotspot.name = "elevatorplan"
						If GetFloor(hotspot.area.GetY()) <> GetFloor(GetPlayerBase().GetFigure().area.GetY())
							hotspot.tooltipEnabled = False
						Else
							hotspot.tooltipEnabled = True
						EndIf
					EndIf
					hotspot.update()
				Next
			endif
		EndIf


		If roomUsedTooltip Then roomUsedTooltip.Update()
		'update room/door tooltips
		GetRoomDoorCollection().UpdateToolTips()
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		TProfiler.Enter(_profilerKey_DrawBuildingBG)
		DrawBackground()
		TProfiler.Leave(_profilerKey_DrawBuildingBG)

		SetBlend AlphaBlend
		If Not GetWorld().autoRenderSnow Then GetWorld().RenderSnow()
		If Not GetWorld().autoRenderRain Then GetWorld().RenderRain()



		'reset drawn for all figures... so they can get drawn
		'correct at their "z-indexes" (behind building, elevator or on floor )
		For Local Figure:TFigureBase = EachIn GetFigureBaseCollection()
			Figure.alreadydrawn = False
		Next

		GetElevator().DrawFloorDoors()
		gfx_building.draw(GetScreenRect().GetX() + leftWallX, area.GetY())

		'only draw the building roof if the player figure (or ghost view)
		'is in a specific area
		If area.GetY() >= 0
			SetColor 255, 255, 255
			gfx_buildingRoof.Draw(GetScreenRect().GetX() + leftWallX, area.GetY(), 0, ALIGN_LEFT_BOTTOM)
		EndIf

		'draw owner signs next to doors,
		'draw open doors overlaying the doors drawn directly on the bg sprite
		'draw overlay - open doors are drawn over "background-image-doors" etc.
		GetRoomDoorBaseCollection().DrawAllDoors()

		'draw elevator parts
		GetElevator().Render()
		'draw softdrinkmachine
		softDrinkMachine.Render(buildingInner.GetScreenRect().GetX() + innerX2 - 90, buildingInner.GetScreenRect().GetY() + GetFloorY2(6), ALIGN_LEFT_BOTTOM)

		'draw christmas trees
		if GameConfig.isChristmasTime
			christmasTree1.Render(buildingInner.GetScreenRect().GetX() + innerX2 - 180, buildingInner.GetScreenRect().GetY() + GetFloorY2(0), ALIGN_LEFT_BOTTOM)
			christmasTree1.Render(buildingInner.GetScreenRect().GetX() + 45, buildingInner.GetScreenRect().GetY() + GetFloorY2(4), ALIGN_LEFT_BOTTOM)
			christmasTree2.Render(buildingInner.GetScreenRect().GetX() + 30, buildingInner.GetScreenRect().GetY() + GetFloorY2(9), ALIGN_LEFT_BOTTOM)
		endif

		If Not softDrinkMachineActive
			softDrinkMachine.GetFrameAnimations().SetCurrent("use")
			softDrinkMachineActive = True
		EndIf


		For Local figure:TFigureBase = EachIn GetFigureBaseCollection()
			'draw figure later if outside of building
'			If figure.GetScreenRect().GetX() < GetScreenRect().GetX() + 127 Then Continue
			If figure.GetScreenRect().GetX() + figure.GetScreenRect().GetW() < buildingInner.GetScreenRect().GetX() Then Continue
			If Not Figure.alreadydrawn Then Figure.Draw()
			Figure.alreadydrawn = True
		Next

		'floor 1
		gfx_plant3a.Draw(buildingInner.GetScreenRect().GetX() + 60, buildingInner.GetScreenRect().GetY() + GetFloorY2(1), -1, ALIGN_LEFT_BOTTOM)
		'floor 2	- between rooms
		gfx_plant4.Draw(buildingInner.GetScreenRect().GetX() + floorWidth - 105, buildingInner.GetScreenRect().GetY() + GetFloorY2(2), -1, ALIGN_LEFT_BOTTOM)
		'floor 3
		gfx_plant1.Draw(buildingInner.GetScreenRect().GetX() + floorWidth - 60, buildingInner.GetScreenRect().GetY() + GetFloorY2(3), -1, ALIGN_LEFT_BOTTOM)
		'floor 4
		gfx_plant6.Draw(buildingInner.GetScreenRect().GetX() + floorWidth - 60, buildingInner.GetScreenRect().GetY() + GetFloorY2(4), -1, ALIGN_RIGHT_BOTTOM)
		'floor 6
		gfx_plant2.Draw(buildingInner.GetScreenRect().GetX() + 150, buildingInner.GetScreenRect().GetY() + GetFloorY2(6), -1, ALIGN_LEFT_BOTTOM)
		'floor 8
		gfx_plant6.Draw(buildingInner.GetScreenRect().GetX() + floorWidth - 95, buildingInner.GetScreenRect().GetY() + GetFloorY2(8), -1, ALIGN_LEFT_BOTTOM)
		'floor 9
		gfx_plant1.Draw(buildingInner.GetScreenRect().GetX() + floorWidth - 130, buildingInner.GetScreenRect().GetY() + GetFloorY2(9), -1, ALIGN_LEFT_BOTTOM)
		gfx_plant2.Draw(buildingInner.GetScreenRect().GetX() + floorWidth - 110, buildingInner.GetScreenRect().GetY() + GetFloorY2(9), -1, ALIGN_LEFT_BOTTOM)
		'floor 11
		gfx_plant1.Draw(buildingInner.GetScreenRect().GetX() + 85, buildingInner.GetScreenRect().GetY() + GetFloorY2(11), -1, ALIGN_LEFT_BOTTOM)
		'floor 12
		gfx_plant3a.Draw(buildingInner.GetScreenRect().GetX() + 60, buildingInner.GetScreenRect().GetY() + GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)
		gfx_plant3b.Draw(buildingInner.GetScreenRect().GetX() + 150, buildingInner.GetScreenRect().GetY() + GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)
		gfx_plant2.Draw(buildingInner.GetScreenRect().GetX() + floorWidth - 75, buildingInner.GetScreenRect().GetY() + GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)
		'floor 13
		gfx_plant1.Draw(buildingInner.GetScreenRect().GetX() + 150, buildingInner.GetScreenRect().GetY() + GetFloorY2(13), -1, ALIGN_LEFT_BOTTOM)
		gfx_plant3b.Draw(buildingInner.GetScreenRect().GetX() + 150, buildingInner.GetScreenRect().GetY() + GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)


		'draw entrance on top of figures
		If area.GetY() < -500
			'mix entrance color so it is a mixture of current sky colors
			'brightness and full brightness (white)
			Local grey:Int = int(GetWorld().lighting.GetSkyBrightness() * 255)
			Local greyColor:SColor8 = new SColor8(grey, grey, grey)
			SetColor( SColor8Helper.Mix(greyColor, SColor8.White, 0.7) )

			'draw figures outside the wall
			For Local Figure:TFigureBase = EachIn GetFigureBaseCollection().entries.Values()
				If Not Figure.alreadydrawn Then Figure.Draw()
			Next

			'the bottom elements (entrance, fence ...) are using offsets
			'to properly align with the building

			gfx_buildingEntrance.Draw(GetScreenRect().GetX(), GetScreenRect().GetY())

			SetColor( SColor8Helper.Mix(greyColor, SColor8.White, 0.9) )
			'draw wall
			gfx_buildingEntranceWall.Draw(GetScreenRect().GetX(), GetScreenRect().GetY())
			'draw fence
			gfx_buildingFence.Draw(GetScreenRect().GetX(), GetScreenRect().GetY())
		EndIf
		SetColor(255,255,255)
		GetRoomDoorCollection().DrawTooltips()

		'draw hotspot tooltips
		For Local hotspot:THotspot = EachIn room.hotspots
			'skip if not visible in "game area"
			'attention: check screenrect, not area
			if not GameConfig.nonInterfaceRect.Intersects( hotspot.GetScreenArea() ) then continue

			hotspot.Render(area.GetX(), area.GetY())
		Next

		If roomUsedTooltip Then roomUsedTooltip.Render()
	End Method


	Method UpdateBackground(deltaTime:Float)
		'compute ufo
		'-----------
		'only happens between...
		If GetWorldTime().GetDay() Mod 2 = 0 And (GetWorldTime().GetDayHour() > 18 Or GetWorldTime().GetDayHour() < 7)
			UFO_MovementBaseSpeed = 1.0 / 60.0 '30 minutes for whole path

			'only continue moving if not doing the beamanimation
			If Not UFO_DoBeamAnimation Or UFO_BeamAnimationDone
				UFO_PathCurrentDistanceOld = UFO_PathCurrentDistance
				UFO_PathCurrentDistance:+ deltaTime * UFO_MovementBaseSpeed * GetWorldTime().GetVirtualMinutesPerSecond()

				'do beaming now
				If UFO_PathCurrentDistance > 0.50 And Not UFO_BeamAnimationDone
					UFO_DoBeamAnimation = True
				EndIf
			EndIf
			If UFO_DoBeamAnimation And Not UFO_BeamAnimationDone
				If ufo_beaming.GetFrameAnimations().getCurrent().isFinished()
					UFO_BeamAnimationDone = True
					UFO_DoBeamAnimation = False
				EndIf
				ufo_beaming.update()
			EndIf

		Else
			'reset beam enabler anyways
			UFO_DoBeamAnimation = False
			UFO_BeamAnimationDone = False
		EndIf
	End Method


	'Summary: Draws background of the mainscreen (stars, buildings, moon...)
	Method DrawBackground(tweenValue:Float=1.0)
		Local BuildingHeight:Int = gfx_building.area.GetH() + 56

		Local skyInfluence:Float
		Local grey:Int = int(GetWorld().lighting.GetSkyBrightness() * 255)
		Local greyColor:SColor8 = new SColor8(grey, grey, grey)
		
		skyInfluence = 0.7
		SetColor( SColor8Helper.Mix(greyColor, SColor8.White, 1.0 - skyInfluence) )

		SetBlend ALPHABLEND
		'draw UFO
		If GetWorldTime().GetDayHour() > 18 Or GetWorldTime().GetDayHour() < 7
			If GetWorldTime().GetDay() Mod 2 = 0
				'compute and draw Ufo
				Local tweenDistance:Float = MathHelper.Tween(UFO_PathCurrentDistanceOld, UFO_PathCurrentDistance, GetDeltaTimer().GetTween())
				Local UFOPos:TVec2D = UFO_Path.GetTweenPoint(tweenDistance, True)
				'print UFO_PathCurrentDistance
				If UFO_DoBeamAnimation And Not UFO_BeamAnimationDone
					ufo_beaming.area.position.SetXY(UFOPos.x, 0.25 * (area.GetY() + BuildingHeight - gfx_bgBuildings[0].area.GetH()) + UFOPos.y)
					ufo_beaming.Render()
				Else
					GetSpriteFromRegistry("gfx_building_BG_ufo").Draw( UFOPos.x, 0.25 * (area.GetY() + BuildingHeight - gfx_bgBuildings[0].area.GetH()) + UFOPos.y, ufo_normal.GetFrameAnimations().GetCurrent().GetCurrentFrame())
				EndIf
			EndIf
		EndIf

		SetBlend MASKBLEND

		skyInfluence = 0.7
		SetColor( SColor8Helper.Mix(greyColor, SColor8.White, 1.0 - skyInfluence) )
		gfx_bgBuildings[0].Draw(GetScreenRect().GetX(), 105 + 0.25 * (area.GetY() + 5 + BuildingHeight - gfx_bgBuildings[0].area.GetH()), - 1)
		gfx_bgBuildings[1].Draw(GetScreenRect().GetX() + 674, 105 + 0.25 * (area.GetY() + 5 + BuildingHeight - gfx_bgBuildings[1].area.GetH()), - 1)

		skyInfluence = 0.5
		SetColor( SColor8Helper.Mix(greyColor, SColor8.White, 1.0 - skyInfluence) )
		gfx_bgBuildings[2].Draw(GetScreenRect().GetX(), 120 + 0.35 * (area.GetY() + BuildingHeight - gfx_bgBuildings[2].area.GetH()), - 1)
		gfx_bgBuildings[3].Draw(GetScreenRect().GetX() + 676, 120 + 0.35 * (area.GetY() + 60 + BuildingHeight - gfx_bgBuildings[3].area.GetH()), - 1)

		skyInfluence = 0.3
		SetColor( SColor8Helper.Mix(greyColor, SColor8.White, 1.0 - skyInfluence) )
		gfx_bgBuildings[4].Draw(GetScreenRect().GetX(), 45 + 0.80 * (area.GetY() + BuildingHeight - gfx_bgBuildings[4].area.GetH()), - 1)
		gfx_bgBuildings[5].Draw(GetScreenRect().GetX() + 674, 45 + 0.80 * (area.GetY() + BuildingHeight - gfx_bgBuildings[5].area.GetH()), - 1)

		SetColor 255, 255, 255
		SetAlpha 1.0
	End Method


	Method CreateRoomUsedTooltip:Int(door:TRoomDoorBase, room:TRoomBase = Null)
		'if no door was given, use main door of room
		If Not door And room Then door = GetRoomDoorCollection().GetMainDoorToRoom(room.id)
		If Not door Then Return False
		roomUsedTooltip	= TTooltip.Create(GetLocale("ROOM_IS_OCCUPIED"), GetLocale("ROOM_THERE_IS_ALREADY_SOMEONE_IN_THE_ROOM"), 0,0,-1,-1, 2000)
		roomUsedTooltip.area.position.SetY(door.GetScreenRect().GetY() - door.area.GetH() - roomUsedTooltip.GetHeight())
		roomUsedTooltip.area.position.SetX(door.GetScreenRect().GetX() + door.area.GetW()/2 - roomUsedTooltip.GetWidth()/2)
		roomUsedTooltip.enabled = 1

		Return True
	End Method


	Method CreateRoomBlockedTooltip:Int(door:TRoomDoorBase, room:TRoomBase = Null)
		'if no door was given, use main door of room
		If Not door And room Then door = GetRoomDoorCollection().GetMainDoorToRoom(room.id)
		If Not door Then Return False
		roomUsedTooltip = TTooltip.Create(GetLocale("BLOCKED"), GetLocale("ACCESS_TO_THIS_ROOM_IS_CURRENTLY_NOT_POSSIBLE"), 0,0,-1,-1,2000)
		roomUsedTooltip.area.position.SetY(door.GetScreenRect().GetY() - door.area.GetH() - roomUsedTooltip.GetHeight())
		roomUsedTooltip.area.position.SetX(door.GetScreenRect().GetX() + door.area.GetW()/2 - roomUsedTooltip.GetWidth()/2)
		roomUsedTooltip.enabled = 1

		Return True
	End Method


	Method CreateRoomLockedTooltip:Int(door:TRoomDoorBase, room:TRoomBase = Null)
		'if no door was given, use main door of room
		If Not door And room Then door = GetRoomDoorCollection().GetMainDoorToRoom(room.id)
		If Not door Then Return False
		roomUsedTooltip = TTooltip.Create(GetLocale("LOCKED"), GetLocale("ACCESS_TO_THIS_ROOM_IS_ONLY_POSSIBLE_WITH_THE_RIGHT_KEY"), 0,0,-1,-1,2000)
		roomUsedTooltip.area.position.SetY(door.GetScreenRect().GetY() - door.area.GetH() - roomUsedTooltip.GetHeight())
		roomUsedTooltip.area.position.SetX(door.GetScreenRect().GetX() + door.area.GetW()/2 - roomUsedTooltip.GetWidth()/2)
		roomUsedTooltip.enabled = 1

		Return True
	End Method
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetBuilding:TBuilding()
	Return TBuilding.GetInstance()
End Function