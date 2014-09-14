
'TODO: split TBuilding into TBuilding + TBuildingArea
'      TBuildingArea then contains background buildings, ufo ...


'Summary: Type of building, area around it and doors,...
Type TBuilding Extends TStaticEntity
	
	Field ufo_normal:TSpriteEntity 				{nosave}
	Field ufo_beaming:TSpriteEntity				{nosave}
	Field Elevator:TElevator
	Field doors:TList = CreateList()

	Field UFO_Path:TCatmullRomSpline = New TCatmullRomSpline {nosave}
	Field UFO_PathCurrentDistanceOld:Float = 0.0
	Field UFO_PathCurrentDistance:Float = 0.0
	Field UFO_MovementStarted:Int = False
	Field UFO_MovementBaseSpeed:Float = 0.0
	Field UFO_DoBeamAnimation:Int = False
	Field UFO_BeamAnimationDone:Int	= False

	Field gfx_bgBuildings:TSprite[6]			{nosave}
	Field gfx_building:TSprite					{nosave}
	Field gfx_buildingEntrance:TSprite			{nosave}
	Field gfx_buildingEntranceWall:TSprite		{nosave}
	Field gfx_buildingFence:TSprite				{nosave}
	Field gfx_buildingRoof:TSprite				{nosave}

	'the room used for the building
	Field room:TRoom = Null
	Field roomUsedTooltip:TTooltip = Null

	'an entity with the area spawning the whole inner part of
	'the building (for proper alignment)
	Field buildingInner:TStaticEntity

	'position of the start of the left wall (aka the building sprite)
	Const leftWallX:int = 127
	'position of the inner left/right side of the building
	'measured from the beginning of the sprite/leftWallX
	Const innerX:Int = 40
	Const innerX2:Int = 508
	'default door width
	Const doorWidth:int	= 19
	'height of each floor
	Const floorWidth:int = 469
	Const floorHeight:int = 73
	Const floorCount:Int = 14 '0-13
	'start of the uppermost floor - eg. add roof height
	Const uppermostFloorTop:Int = 0
	'x coord of defined slots
	'x coord is relative to "leftWallX" 
	Const doorSlot0:int	= -10
	Const doorSlot1:int	= 19
	Const doorSlot2:int	= doorSlot1 + 97
	Const doorSlot3:int	= doorSlot1 + 283
	Const doorSlot4:int	= doorslot1 + 376


	Global softDrinkMachineActive:int = False
	Global softDrinkMachine:TSpriteEntity

	Global _instance:TBuilding
	Global _backgroundModified:int = FALSE
	Global _eventsRegistered:int = FALSE


	Method New()
		if not _eventsRegistered
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)

			EventManager.registerListenerFunction( "hotspot.onClick", onClickHotspot)

			'we want to get information about figures entering their desired target
			'(this can be "room", "hotspot" ... )
			EventManager.registerListenerFunction( "figure.onEnterTarget", onEnterTarget)

			_eventsRegistered = TRUE
		Endif
	End Method


	Function GetInstance:TBuilding()
		if not _instance then _instance = new TBuilding.Create()
		return _instance
	End Function


	Method Create:TBuilding()
		area.position.SetX(0)
		area.dimension.SetXY(800, floorCount * floorHeight + 50) 'occupy full area

		'create an entity spawning the complete inner area of the building
		'this entity can be used as parent for other entities - which
		'want to layout to the "inner area" of the building (eg. doors)
		buildingInner = new TStaticEntity
		buildingInner.area.position.SetXY(leftWallX + innerX, 0)
		'subtract missing "splitter wall" of last floor
		buildingInner.area.dimension.SetXY(floorWidth, floorCount * floorHeight - 7)
		'set building as parent for proper alignment
		buildingInner.SetParent(self)


		'call to set graphics, paths for objects and other stuff
		InitGraphics()

		area.position.SetY(0 - gfx_building.area.GetH() + 5 * floorHeight)
		Elevator = TElevator.GetInstance().Init()
		Elevator.SetParent(self.buildingInner)
		Elevator.area.position.SetX(floorWidth/2 - Elevator.GetDoorWidth()/2)
		Elevator.area.position.SetY(GetFloorY2(Elevator.CurrentFloor) - Elevator.spriteInner.area.GetH())

		Elevator.RouteLogic = TElevatorSmartLogic.Create(Elevator, 0) 'Die Logik die im Elevator verwendet wird. 1 heißt, dass der PrivilegePlayerMode aktiv ist... mMn macht's nur so wirklich Spaß


		'=== SETUP SOFTDRINK MACHINE ===
		softDrinkMachine = new TSpriteEntity
		softDrinkMachine.SetSprite(GetSpriteFromRegistry("gfx_building_softdrinkmachine"))
		softDrinkMachine.GetFrameAnimations().Set("default", TSpriteFrameAnimation.Create([ [0,70] ], 0, 0) )
		softDrinkMachine.GetFrameAnimations().Set("use", TSpriteFrameAnimation.CreateSimple(15, 50))
		softDrinkMachineActive = False
		
		Return self
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TBuilding", "Savegame loaded - reassign sprites, recreate movement paths for gfx.", LOG_DEBUG | LOG_SAVELOAD)
		GetInstance().InitGraphics()

		'reassign elevator from freshly loaded building to elevator instance
		TElevator._instance = GetInstance().Elevator

		'reposition hotspots, prepare building sprite...
		GetInstance().Init()
	End Function


	Method PrepareBuildingSprite:Int()
		'TODO: copy original building sprite (empty) before modifying
		'      the first time - so it allows various layouts of room
	
		'=== BACKGROUND DECORATION ===
		'draw sprites directly on the building sprite if not done yet
		if not _backgroundModified
			Local Pix:TPixmap = LockImage(gfx_building.parent.image)

			'=== DRAW NECESSARY ITEMS ===
			'credits sign on floor 13
			GetSpriteFromRegistry("gfx_building_credits").DrawOnImage(Pix, innerX2 - 5, GetFloorY2(13), -1, ALIGN_RIGHT_BOTTOM)
			'roomboard on floor 0
			GetSpriteFromRegistry("gfx_building_roomboard").DrawOnImage(Pix, innerX2 - 30, GetFloorY2(0), -1, ALIGN_RIGHT_BOTTOM)

			'=== DRAW ELEVATOR BORDER ===
			Local elevatorBorder:TSprite= GetSpriteFromRegistry("gfx_building_Fahrstuhl_Rahmen")
			For Local i:Int = 0 To 13
				DrawImageOnImage(elevatorBorder.getImage(), Pix, 250, 67 - elevatorBorder.area.GetH() + floorHeight*i)
				DrawImageOnImage(elevatorBorder.getImage(), Pix, 250, 67 - elevatorBorder.area.GetH() + floorHeight*i)
			Next

			'=== DRAW DOORS ===
			For Local door:TRoomDoorBase = EachIn doors
				'skip invisible doors (without door-sprite)
				If not door.IsVisible() then continue

				local sprite:TSprite = door.GetSprite()
				if not sprite then continue

				sprite.DrawOnImage(pix, innerX + door.area.GetX(), door.area.GetY(), MathHelper.Clamp(door.doorType, 0,5), ALIGN_LEFT_BOTTOM)
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

			_backgroundModified = TRUE
		endif
	End Method


	Method InitGraphics()
		'==== UFO ====
		'sprites
		ufo_normal	= New TSpriteEntity
		ufo_normal.SetSprite(GetSpriteFromRegistry("gfx_building_BG_ufo"))
		ufo_normal.area.position.SetXY(0,100)
		ufo_normal.GetFrameAnimations().Set("default", TSpriteFrameAnimation.CreateSimple(9, 100))

		ufo_beaming	= New TSpriteEntity
		ufo_beaming.SetSprite(GetSpriteFromRegistry("gfx_building_BG_ufo2"))
		ufo_beaming.area.position.SetXY(0,100)
		ufo_beaming.GetFrameAnimations().Set("default", TSpriteFrameAnimation.CreateSimple(9, 100))

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
	End Method


	Method Init:Int()
		'assign room
		room = GetRoomCollection().GetFirstByDetails("building")

		For Local hotspot:THotspot = EachIn room.hotspots
			'set building inner as parent, so "getScreenX/Y()" can
			'layout properly)
			hotspot.setParent(self.buildingInner)

			'move elevatorplan hotspots to the elevator
			If hotspot.name = "elevatorplan"
				hotspot.area.position.setX( Elevator.area.getX() )
				hotspot.area.dimension.setXY( Elevator.GetDoorWidth(), 58 )
			EndIf
		Next

		For local figure:TFigureBase = EachIn GetFigureBaseCollection().list
			figure.setParent(self.buildingInner)
		Next


		PrepareBuildingSprite()
	End Method


	Function GetDoorXFromDoorSlot:int(slot:int)
		select slot
			case 1	return doorSlot1
			case 2	return doorSlot2
			case 3	return doorSlot3
			case 4	return doorSlot4
		end select

		return 0
	End Function
	
	
	Method AddDoor:Int(door:TRoomDoorBase)
		if not door then return False
		'add to innerBuilding, so doors can properly layout in the
		'inner area
		door.SetParent(self.buildingInner)
		'move door accordingly
		door.area.position.SetX(GetDoorXFromDoorSlot(door.doorSlot))
		door.area.position.SetY(GetFloorY2(door.onFloor))

		'add to list
		doors.addLast(door)
	End Method


	Function onEnterTarget:Int( triggerEvent:TEventBase )
		Local figure:TFigure = TFigure( triggerEvent._sender )
		If Not figure Then Return False

		'we are only interested in hotspots
		Local hotspot:THotSpot = THotSpot(triggerEvent.GetReceiver())
		If Not hotspot Then Return False

		If hotspot.name = "elevatorplan"
			'Print "figure "+figure.name+" reached elevatorplan"

			Local room:TRoom = GetRoomCollection().GetFirstByDetails("elevatorplan")
			If Not room Then Print "[ERROR] room: elevatorplan not not defined. Cannot enter that room.";Return False

			figure.EnterRoom(null, room)
			Return True
		EndIf

		Return False
	End Function


	Function onClickHotspot:Int( triggerEvent:TEventBase )
		Local hotspot:THotspot = THotspot( triggerEvent._sender )
		If Not hotspot Then Return False 'or hotspot.name <> "elevatorplan" then return FALSE
		'not interested in others
		If not GetInstance().room.hotspots.contains(hotspot) then return False

		'hotspot position is LOCAL to building, so no transition needed
		GetPlayerCollection().Get().figure.changeTarget( hotspot.area.getX() + hotspot.area.getW()/2, hotspot.area.getY() )
		'ignore clicks to elevator plans on OTHER floors
		'in this case just move to the target, but do not "enter" the room
		If hotspot.name <> "elevatorplan" OR GetInstance().GetFloor(hotspot.area.GetY()) = GetInstance().GetFloor(GetPlayerCollection().Get().figure.area.GetY())
			GetPlayerCollection().Get().figure.targetObj = hotspot
		EndIf
		
		MOUSEMANAGER.ResetKey(1)
	End Function


	Method ActivateSoftdrinkMachine:int()
		softDrinkMachineActive = True
	End Method
	

	Method Update()
		'update softdrinkmachine
		softDrinkMachine.Update()
	
		'center player
		If GetPlayer().GetFigure().inRoom = Null
			'subtract 7 because of missing "wall" in last floor
			'add 50 for roof
			area.position.y =  2 * floorHeight - 7 + 50 - GetPlayer().figure.area.GetY()
		Endif


		local deltaTime:float = GetDeltaTimer().GetDelta()
		area.position.y = MathHelper.Clamp(area.position.y, - 637, 88)
		UpdateBackground(deltaTime)


		'update hotspot tooltips
		If room
			For Local hotspot:THotspot = EachIn room.hotspots
				'disable elevatorplan hotspot tooltips in other floors
				if hotspot.name = "elevatorplan"
					if GetFloor(hotspot.area.GetY()) <> GetFloor(GetPlayer().figure.area.GetY())
						hotspot.tooltipEnabled = False
					else
						hotspot.tooltipEnabled = True
					endif
				endif
				hotspot.update()
			Next
		EndIf


		If roomUsedTooltip Then roomUsedTooltip.Update()
		'Tooltips aktualisieren
		TRoomDoor.UpdateToolTips()


		'handle player target changes
		If Not GetPlayer().GetFigure().inRoom
			If MOUSEMANAGER.isClicked(1) And Not GUIManager._ignoreMouse
				If Not GetPlayer().GetFigure().isChangingRoom
					If THelper.IsIn(MouseManager.x, MouseManager.y, 0, 0, 800, 385)
						'convert mouse position to building-coordinates
						local x:int = MouseManager.x - buildingInner.GetScreenX()
						local y:int = MouseManager.y - buildingInner.GetScreenY()
						GetPlayerCollection().Get().Figure.ChangeTarget(x, y)
						MOUSEMANAGER.resetKey(1)
					EndIf
				EndIf
			EndIf
		EndIf
	End Method


	Method Render:int(xOffset:Float = 0, yOffset:Float = 0)
		TProfiler.Enter("Draw-Building-Background")
		DrawBackground()
		TProfiler.Leave("Draw-Building-Background")

		SetBlend AlphaBlend
		if not GetWorld().autoRenderSnow then GetWorld().RenderSnow()
		if not GetWorld().autoRenderRain then GetWorld().RenderRain()



		'reset drawn for all figures... so they can get drawn
		'correct at their "z-indexes" (behind building, elevator or on floor )
		For Local Figure:TFigureBase = EachIn GetFigureBaseCollection().list
			Figure.alreadydrawn = False
		Next

		'only draw the building roof if the player figure is in a specific
		'area
		If GetFloor(GetPlayer().figure.area.GetY()) >= 8
			SetColor 255, 255, 255
			gfx_buildingRoof.Draw(GetScreenX() + leftWallX, GetScreenY(), -1, ALIGN_LEFT_BOTTOM)
		EndIf

		elevator.DrawFloorDoors()
		gfx_building.draw(GetScreenX() + leftWallX, area.GetY())

		'draw owner signs next to doors,
		'draw open doors overlaying the doors drawn directly on the bg sprite
		'draw overlay - open doors are drawn over "background-image-doors" etc.
		GetRoomDoorBaseCollection().DrawAllDoors()

		'draw elevator parts
		Elevator.Render()
		'draw softdrinkmachine
		softDrinkMachine.RenderAt(buildingInner.GetScreenX() + innerX2 - 90, buildingInner.GetScreenY() + GetFloorY2(6), "", ALIGN_LEFT_BOTTOM)

		if not softDrinkMachineActive
			softDrinkMachine.GetFrameAnimations().SetCurrent("use")
			softDrinkMachineActive = True
		Endif


		For Local Figure:TFigureBase = EachIn GetFigureBaseCollection().list
			'draw figure later if outside of building
'			If figure.GetScreenX() < GetScreenX() + 127 Then Continue
			If figure.GetScreenX() + figure.GetScreenWidth() < buildingInner.GetScreenX() Then Continue
			If Not Figure.alreadydrawn Then Figure.Draw()
			Figure.alreadydrawn = True
		Next

		'floor 1
		GetSpriteFromRegistry("gfx_building_Pflanze3a").Draw(buildingInner.GetScreenX() + 60, buildingInner.GetScreenY() + GetFloorY2(1), -1, ALIGN_LEFT_BOTTOM)
		'floor 2	- between rooms
		GetSpriteFromRegistry("gfx_building_Pflanze4").Draw(buildingInner.GetScreenX() + floorWidth - 105, buildingInner.GetScreenY() + GetFloorY2(2), -1, ALIGN_LEFT_BOTTOM)
		'floor 3
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(buildingInner.GetScreenX() + floorWidth - 60, buildingInner.GetScreenY() + GetFloorY2(3), -1, ALIGN_LEFT_BOTTOM)
		'floor 4
		GetSpriteFromRegistry("gfx_building_Pflanze6").Draw(buildingInner.GetScreenX() + floorWidth - 60, buildingInner.GetScreenY() + GetFloorY2(4), -1, ALIGN_RIGHT_BOTTOM)
		'floor 6
		GetSpriteFromRegistry("gfx_building_Pflanze2").Draw(buildingInner.GetScreenX() + 150, buildingInner.GetScreenY() + GetFloorY2(6), -1, ALIGN_LEFT_BOTTOM)
		'floor 8
		GetSpriteFromRegistry("gfx_building_Pflanze6").Draw(buildingInner.GetScreenX() + floorWidth - 95, buildingInner.GetScreenY() + GetFloorY2(8), -1, ALIGN_LEFT_BOTTOM)
		'floor 9
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(buildingInner.GetScreenX() + floorWidth - 130, buildingInner.GetScreenY() + GetFloorY2(9), -1, ALIGN_LEFT_BOTTOM)
		GetSpriteFromRegistry("gfx_building_Pflanze2").Draw(buildingInner.GetScreenX() + floorWidth - 110, buildingInner.GetScreenY() + GetFloorY2(9), -1, ALIGN_LEFT_BOTTOM)
		'floor 11
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(buildingInner.GetScreenX() + 85, buildingInner.GetScreenY() + GetFloorY2(11), -1, ALIGN_LEFT_BOTTOM)
		'floor 12
		GetSpriteFromRegistry("gfx_building_Pflanze3a").Draw(buildingInner.GetScreenX() + 60, buildingInner.GetScreenY() + GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)
		GetSpriteFromRegistry("gfx_building_Pflanze3b").Draw(buildingInner.GetScreenX() + 150, buildingInner.GetScreenY() + GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)
		GetSpriteFromRegistry("gfx_building_Pflanze2").Draw(buildingInner.GetScreenX() + floorWidth - 75, buildingInner.GetScreenY() + GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)
		'floor 13
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(buildingInner.GetScreenX() + 150, buildingInner.GetScreenY() + GetFloorY2(13), -1, ALIGN_LEFT_BOTTOM)
		GetSpriteFromRegistry("gfx_building_Pflanze3b").Draw(buildingInner.GetScreenX() + 150, buildingInner.GetScreenY() + GetFloorY2(12), -1, ALIGN_LEFT_BOTTOM)

		'draw entrance on top of figures
		If GetFloor(GetPlayerCollection().Get().Figure.area.GetY()) <= 4
			'mix entrance color so it is a mixture of current sky colors
			'brightness and full brightness (white)
			TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 0.7).SetRGB()
			'draw figures outside the wall
			For Local Figure:TFigure = EachIn GetFigureCollection().list
				If Not Figure.alreadydrawn Then Figure.Draw()
			Next

			'the bottom elements (entrance, fence ...) are using offsets
			'to properly align with the building

			gfx_buildingEntrance.Draw(GetScreenX(), GetScreenY())

			TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 0.9).SetRGB()
			'draw wall
			gfx_buildingEntranceWall.Draw(GetScreenX(), GetScreenY())
			'draw fence
			gfx_buildingFence.Draw(GetScreenX(), GetScreenY())
		EndIf
		SetColor(255,255,255)
		TRoomDoor.DrawAllTooltips()

		'draw hotspot tooltips
		For Local hotspot:THotspot = EachIn room.hotspots
			hotspot.Render(area.GetX(), area.GetY())
		Next

		If roomUsedTooltip Then roomUsedTooltip.Render()
	End Method


	Method UpdateBackground(deltaTime:Float)
		'compute ufo
		'-----------
		'only happens between...
		If GetWorldTime().getDay() Mod 2 = 0 And (GetWorldTime().GetDayHour() > 18 Or GetWorldTime().GetDayHour() < 7)
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

		local skyInfluence:float = 0

		skyInfluence = 0.7
		TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 1.0 - skyInfluence).SetRGB()
		SetBlend ALPHABLEND
		'draw UFO
		If GetWorldTime().GetDayHour() > 18 Or GetWorldTime().GetDayHour() < 7
			If GetWorldTime().getDay() Mod 2 = 0
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
		TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 1.0 - skyInfluence).SetRGB()
		gfx_bgBuildings[0].Draw(GetScreenX(), 105 + 0.25 * (area.GetY() + 5 + BuildingHeight - gfx_bgBuildings[0].area.GetH()), - 1)
		gfx_bgBuildings[1].Draw(GetScreenX() + 674, 105 + 0.25 * (area.GetY() + 5 + BuildingHeight - gfx_bgBuildings[1].area.GetH()), - 1)

		skyInfluence = 0.5
		TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 1.0 - skyInfluence).SetRGB()
		gfx_bgBuildings[2].Draw(GetScreenX(), 120 + 0.35 * (area.GetY() + BuildingHeight - gfx_bgBuildings[2].area.GetH()), - 1)
		gfx_bgBuildings[3].Draw(GetScreenX() + 676, 120 + 0.35 * (area.GetY() + 60 + BuildingHeight - gfx_bgBuildings[3].area.GetH()), - 1)

		skyInfluence = 0.3
		TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 1.0 - skyInfluence).SetRGB()
		gfx_bgBuildings[4].Draw(GetScreenX(), 45 + 0.80 * (area.GetY() + BuildingHeight - gfx_bgBuildings[4].area.GetH()), - 1)
		gfx_bgBuildings[5].Draw(GetScreenX() + 674, 45 + 0.80 * (area.GetY() + BuildingHeight - gfx_bgBuildings[5].area.GetH()), - 1)

		SetColor 255, 255, 255
		SetAlpha 1.0
	End Method


	Method CreateRoomUsedTooltip:Int(door:TRoomDoorBase, room:TRoomBase = null)
		'if no door was given, use main door of room
		if not door and room then door = TRoomDoor.GetMainDoorToRoom(room)
		if not door then return FALSE

		roomUsedTooltip	= TTooltip.Create("Besetzt", "In diesem Raum ist schon jemand", 0,0,-1,-1,2000)
		roomUsedTooltip.area.position.SetY(door.GetScreenY() - door.area.GetH())
		roomUsedTooltip.area.position.SetX(door.GetScreenX() + door.area.GetW()/2 - roomUsedTooltip.GetWidth()/2)
		roomUsedTooltip.enabled = 1

		return TRUE
	End Method


	Method CreateRoomBlockedTooltip:Int(door:TRoomDoorBase, room:TRoomBase = null)
		'if no door was given, use main door of room
		if not door and room then door = TRoomDoor.GetMainDoorToRoom(room)
		if not door then return FALSE

		roomUsedTooltip = TTooltip.Create(GetLocale("BLOCKED"), GetLocale("ACCESS_TO_THIS_ROOM_IS_CURRENTLY_NOT_POSSIBLE"), 0,0,-1,-1,2000)
		roomUsedTooltip.area.position.SetY(door.GetScreenY() - door.area.GetH())
		roomUsedTooltip.area.position.SetX(door.GetScreenX() + door.area.GetW()/2 - roomUsedTooltip.GetWidth()/2)
		roomUsedTooltip.enabled = 1

		return TRUE
	End Method


	Method CenterToFloor:Int(floornumber:Int)
		area.position.y = ((13 - floornumber) * floorHeight) - 115
	End Method


	'returns y of the requested floors CEILING position (upper part)
	'	coordinate is local (difference to building coordinates)
	Function GetFloorY:Int(floorNumber:Int)
		'limit floornumber to 0-(floorCount-1)
		floorNumber = Max(0, Min(floornumber,floorCount-1))

		'subtract 7 because last floor has no "splitter wall"
		Return 1 + (floorCount-1 - floorNumber) * floorHeight - 7
	End Function


	'returns y of the requested floors GROUND position (lower part)
	'	coordinate is local (difference to building coordinates)
	Function GetFloorY2:Int(floorNumber:Int)
		return GetFloorY(floorNumber) + floorHeight
	End Function


	'returns floor of a given y-coordinate (local to building coordinates)
	Method GetFloor:Int(y:Int)
'		Return MathHelper.Clamp(14 - Ceil((y - area.GetY()) / 73),0,13)
		y :- uppermostFloorTop
		y = Ceil(y / floorHeight)
		return MathHelper.Clamp(13 - y, 0, 13)
	End Method


	'point ist hier NICHT zwischen 0 und 13... sondern pixelgenau...
	'also zwischen 0 und ~ 1000
	Function getFloorByPixelExactPoint:Int(point:TVec2D)
		For Local i:Int = 0 To 13
			If GetFloorY2(i) < point.y Then Return i
		Next
		Return -1
	End Function
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetBuilding:TBuilding()
	return TBuilding.GetInstance()
End Function