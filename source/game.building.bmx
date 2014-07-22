
'Summary: Type of building, area around it and doors,...
Type TBuilding Extends TStaticEntity
	'px at which the building starts (leftside added is the door)
	Field buildingDisplaceX:Int = 127
	Field innerLeft:Int	= 127 + 40
	Field innerRight:Int = 127 + 468
	Field ufo_normal:TSpriteEntity 				{nosave}
	Field ufo_beaming:TSpriteEntity				{nosave}
	Field Elevator:TElevator

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

			'we want to get information about figures reaching their desired target
			'(this can be "room", "hotspot" ... )
			EventManager.registerListenerFunction( "figure.onReachTarget", onReachTarget)

			_eventsRegistered = TRUE
		Endif
	End Method


	Function GetInstance:TBuilding()
		if not _instance then _instance = new TBuilding.Create()
		return _instance
	End Function


	Method Create:TBuilding()
		area.position.SetX(20)

		'call to set graphics, paths for objects and other stuff
		InitGraphics()

		area.position.SetY(0 - gfx_building.area.GetH() + 5 * 73 + 20)	' 20 = interfacetop, 373 = raumhoehe
		Elevator = TElevator.GetInstance().Init()
		Elevator.area.position.SetY(GetFloorY(Elevator.CurrentFloor) - Elevator.spriteInner.area.GetH())

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

		'reposition hotspots
		GetInstance().Init()
	End Function


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
		gfx_buildingRoof = GetSpriteFromRegistry("gfx_building_Dach")


		'=== BACKGROUND DECORATION ===
		'draw sprites directly on the building sprite if not done yet
		if not _backgroundModified
			Local Pix:TPixmap = LockImage(gfx_building.parent.image)
			local itemX:int

			'=== DRAW NECESSARY ITEMS ===
			'credits sign on floor 13
			GetSpriteFromRegistry("gfx_building_credits").DrawOnImage(Pix, -buildingDisplaceX + innerRight - 5, GetFloorY(13), -1, ALIGN_RIGHT_BOTTOM)
			'roomboard on floor 0
			GetSpriteFromRegistry("gfx_building_roomboard").DrawOnImage(Pix, -buildingDisplaceX + innerRight - 30, GetFloorY(0), -1, ALIGN_RIGHT_BOTTOM)


			'=== DRAW DECORATION ===
			'floor 0
			GetSpriteFromRegistry("gfx_building_Wandlampe").DrawOnImage(Pix, -buildingDisplaceX + innerleft + 125, GetFloorY(0), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Wandlampe").DrawOnImage(Pix, -buildingDisplaceX + innerRight - 125, GetFloorY(0), -1, ALIGN_RIGHT_BOTTOM)
			'floor 1
			itemX = -buildingDisplaceX + innerRight - 30
			GetSpriteFromRegistry("gfx_building_picture2").DrawOnImage(Pix, itemX, GetFloorY(1), -1, ALIGN_CENTER_BOTTOM)
			GetSpriteFromRegistry("gfx_building_standlightSmall").DrawOnImage(Pix, itemX, GetFloorY(1), -1, ALIGN_CENTER_BOTTOM)
			'floor 3
			itemX = -buildingDisplaceX + innerRight - 80
			GetSpriteFromRegistry("gfx_building_picture1").DrawOnImage(Pix, itemX, GetFloorY(3), -1, ALIGN_CENTER_BOTTOM)
			GetSpriteFromRegistry("gfx_building_standlightSmall").DrawOnImage(Pix, itemX - 20, GetFloorY(3), -1, ALIGN_CENTER_BOTTOM)
			GetSpriteFromRegistry("gfx_building_standlightSmall").DrawOnImage(Pix, itemX + 20, GetFloorY(3), -1, ALIGN_CENTER_BOTTOM)
			'floor 4
			GetSpriteFromRegistry("gfx_building_Pflanze5").DrawOnImage(Pix, -buildingDisplaceX + innerRight - 67, GetFloorY(4), -1, ALIGN_LEFT_BOTTOM)
			'floor 12
			GetSpriteFromRegistry("gfx_building_picture2").DrawOnImage(Pix, -buildingDisplaceX + innerRight - 50, GetFloorY(12), -1, ALIGN_CENTER_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Pflanze4").DrawOnImage(Pix, -buildingDisplaceX + innerleft + 40, GetFloorY(12), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Pflanze6").DrawOnImage(Pix, -buildingDisplaceX + innerRight - 95, GetFloorY(12), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Pflanze2").DrawOnImage(Pix, -buildingDisplaceX + innerleft + 105, GetFloorY(7), -1, ALIGN_LEFT_BOTTOM)
			'floor 13
			GetSpriteFromRegistry("gfx_building_Pflanze2").DrawOnImage(Pix, -buildingDisplaceX + innerleft + 105, GetFloorY(13), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Pflanze3").DrawOnImage(Pix, -buildingDisplaceX + innerRight - 105, GetFloorY(13), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Wandlampe").DrawOnImage(Pix, -buildingDisplaceX + innerleft + 125, GetFloorY(13), -1, ALIGN_LEFT_BOTTOM)
			GetSpriteFromRegistry("gfx_building_Wandlampe").DrawOnImage(Pix, -buildingDisplaceX + innerRight - 125, GetFloorY(13), -1, ALIGN_RIGHT_BOTTOM)

			UnlockImage(gfx_building.parent.image)
			Pix = Null

			_backgroundModified = TRUE
		endif		
	End Method


	Method Init:Int()
		'assign room
		room = GetRoomCollection().GetFirstByDetails("building")

		'move elevatorplan hotspots to the elevator
		For Local hotspot:THotspot = EachIn room.hotspots
			If hotspot.name = "elevatorplan"
				hotspot.area.position.setX( Elevator.area.getX() )
				hotspot.area.dimension.setXY( Elevator.GetDoorWidth(), 58 )
			EndIf
		Next
	End Method


	Function onReachTarget:Int( triggerEvent:TEventBase )
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

		GetPlayerCollection().Get().figure.changeTarget( GetInstance().area.GetX() + hotspot.area.getX() + hotspot.area.getW()/2, GetInstance().area.GetY() + hotspot.area.getY() )
		GetPlayerCollection().Get().figure.targetObj = hotspot

		MOUSEMANAGER.ResetKey(1)
	End Function


	Method ActivateSoftdrinkMachine:int()
		softDrinkMachineActive = True
	End Method
	

	Method Update()
		'update softdrinkmachine
		softDrinkMachine.Update()
	
		'66 = 13th floor height, 2 floors normal = 1*73, 50 = roof
		If GetPlayerCollection().Get().Figure.inRoom = Null
			'working for player as center
			area.position.y =  1 * 66 + 1 * 73 + 50 - GetPlayerCollection().Get().Figure.area.GetY()
		Endif


		local deltaTime:float = GetDeltaTimer().GetDelta()
		area.position.y = MathHelper.Clamp(area.position.y, - 637, 88)
		UpdateBackground(deltaTime)


		'update hotspot tooltips
		If room
			For Local hotspot:THotspot = EachIn room.hotspots
				hotspot.update(area.GetX(), area.GetY())
			Next
		EndIf


		If roomUsedTooltip Then roomUsedTooltip.Update()


		'handle player target changes
		If Not GetPlayerCollection().Get().Figure.inRoom
			If MOUSEMANAGER.isClicked(1) And Not GUIManager._ignoreMouse
				If Not GetPlayerCollection().Get().Figure.isChangingRoom
					If THelper.IsIn(MouseManager.x, MouseManager.y, 20, 10, 760, 373)
						GetPlayerCollection().Get().Figure.ChangeTarget(MouseManager.x, MouseManager.y)
						MOUSEMANAGER.resetKey(1)
					EndIf
				EndIf
			EndIf
		EndIf
	End Method


	Method Render:int(xOffset:Float = 0, yOffset:Float = 0)
		'=== DRAW WORLD ===
'		world.Render()

		TProfiler.Enter("Draw-Building-Background")
		DrawBackground()
		TProfiler.Leave("Draw-Building-Background")

		SetBlend AlphaBlend
		if not GetWorld().autoRenderSnow then GetWorld().RenderSnow()
		if not GetWorld().autoRenderRain then GetWorld().RenderRain()



		'reset drawn for all figures... so they can get drawn
		'correct at their "z-indexes" (behind building, elevator or on floor )
		For Local Figure:TFigure = EachIn GetFigureCollection().list
			Figure.alreadydrawn = False
		Next

		If GetFloor(GetPlayerCollection().Get().Figure.area.GetY()) >= 8
			SetColor 255, 255, 255
			SetBlend ALPHABLEND
			gfx_buildingRoof.Draw(area.GetX() + buildingDisplaceX, area.GetY() - gfx_buildingRoof.area.GetH())
		EndIf

		SetBlend MASKBLEND
		elevator.DrawFloorDoors()

		GetSpriteFromRegistry("gfx_building").draw(area.GetX() + buildingDisplaceX, area.GetY())

		SetBlend MASKBLEND

		'draw overlay - open doors are drawn over "background-image-doors" etc.
		TRoomDoor.DrawAll()
		'draw elevator parts
		Elevator.Render()
		'draw softdrinkmachine
		softDrinkMachine.RenderAt(area.GetX() + innerRight - 60, area.GetY() + GetFloorY(6), "", ALIGN_LEFT_BOTTOM)

		if not softDrinkMachineActive
			softDrinkMachine.GetFrameAnimations().SetCurrent("use")
			softDrinkMachineActive = True
		Endif

		SetBlend ALPHABLEND

		For Local Figure:TFigure = EachIn GetFigureCollection().list
			'draw figure later if outside of building
			If figure.area.GetX() < area.GetX() + buildingDisplaceX Then Continue
			If Not Figure.alreadydrawn Then Figure.Draw()
			Figure.alreadydrawn = True
		Next

		'floor 1
		GetSpriteFromRegistry("gfx_building_Pflanze3a").Draw(area.GetX() + innerLeft + 60, area.GetY() + GetFloorY(1), - 1, ALIGN_LEFT_BOTTOM)
		'floor 2	- between rooms
		GetSpriteFromRegistry("gfx_building_Pflanze4").Draw(area.GetX() + innerRight - 105, area.GetY() + GetFloorY(2), - 1, ALIGN_LEFT_BOTTOM)
		'floor 3
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(area.GetX() + innerRight - 60, area.GetY() + GetFloorY(3), - 1, ALIGN_LEFT_BOTTOM)
		'floor 4
		GetSpriteFromRegistry("gfx_building_Pflanze6").Draw(area.GetX() + innerRight - 60, area.GetY() + GetFloorY(4), - 1, ALIGN_RIGHT_BOTTOM)
		'floor 6
		GetSpriteFromRegistry("gfx_building_Pflanze2").Draw(area.GetX() + innerLeft + 150, area.GetY() + GetFloorY(6), - 1, ALIGN_LEFT_BOTTOM)
		'floor 8
		GetSpriteFromRegistry("gfx_building_Pflanze6").Draw(area.GetX() + innerRight - 85, area.GetY() + GetFloorY(8), - 1, ALIGN_LEFT_BOTTOM)
		'floor 9
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(area.GetX() + innerRight - 130, area.GetY() + GetFloorY(9), - 1, ALIGN_LEFT_BOTTOM)
		GetSpriteFromRegistry("gfx_building_Pflanze2").Draw(area.GetX() + innerRight - 110, area.GetY() + GetFloorY(9), - 1, ALIGN_LEFT_BOTTOM)
		'floor 11
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(area.GetX() + innerLeft + 85, area.GetY() + GetFloorY(11), - 1, ALIGN_LEFT_BOTTOM)
		'floor 12
		GetSpriteFromRegistry("gfx_building_Pflanze3a").Draw(area.GetX() + innerLeft + 60, area.GetY() + GetFloorY(12), - 1, ALIGN_LEFT_BOTTOM)
		GetSpriteFromRegistry("gfx_building_Pflanze3b").Draw(area.GetX() + innerLeft + 150, area.GetY() + GetFloorY(12), - 1, ALIGN_LEFT_BOTTOM)
		GetSpriteFromRegistry("gfx_building_Pflanze2").Draw(area.GetX() + innerRight - 75, area.GetY() + GetFloorY(12), - 1, ALIGN_LEFT_BOTTOM)
		'floor 13
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(area.GetX() + innerLeft + 150, area.GetY() + GetFloorY(13), - 1, ALIGN_LEFT_BOTTOM)
		GetSpriteFromRegistry("gfx_building_Pflanze3b").Draw(area.GetX() + innerLeft + 150, area.GetY() + GetFloorY(12), - 1, ALIGN_LEFT_BOTTOM)


		'draw entrance on top of figures
		If GetFloor(GetPlayerCollection().Get().Figure.area.GetY()) <= 4
			'mix entrance color so it is a mixture of current sky colors
			'brightness and full brightness (white)
			TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 0.7).SetRGB()
			'draw figures outside the wall
			For Local Figure:TFigure = EachIn GetFigureCollection().list
				If Not Figure.alreadydrawn Then Figure.Draw()
			Next
			gfx_buildingEntrance.Draw(area.GetX(), area.GetY() + 1024 - gfx_buildingEntrance.area.GetH() - 3)

			TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 0.9).SetRGB()
			'draw wall
			gfx_buildingEntranceWall.Draw(area.GetX() + gfx_buildingEntrance.area.GetW(), area.GetY() + 1024 - gfx_buildingEntranceWall.area.GetH() - 3)
			'draw fence
			gfx_buildingFence.Draw(area.GetX() + buildingDisplaceX + 507, area.GetY() + 1024 - gfx_buildingFence.area.GetH() - 3)
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
		gfx_bgBuildings[0].Draw(area.GetX(), 105 + 0.25 * (area.GetY() + 5 + BuildingHeight - gfx_bgBuildings[0].area.GetH()), - 1)
		gfx_bgBuildings[1].Draw(area.GetX() + 634, 105 + 0.25 * (area.GetY() + 5 + BuildingHeight - gfx_bgBuildings[1].area.GetH()), - 1)

		skyInfluence = 0.5
		TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 1.0 - skyInfluence).SetRGB()
		gfx_bgBuildings[2].Draw(area.GetX(), 120 + 0.35 * (area.GetY() + BuildingHeight - gfx_bgBuildings[2].area.GetH()), - 1)
		gfx_bgBuildings[3].Draw(area.GetX() + 636, 120 + 0.35 * (area.GetY() + 60 + BuildingHeight - gfx_bgBuildings[3].area.GetH()), - 1)

		skyInfluence = 0.3
		TColor.CreateGrey(GetWorld().lighting.GetSkyBrightness() * 255).Mix(TColor.clWhite, 1.0 - skyInfluence).SetRGB()
		gfx_bgBuildings[4].Draw(area.GetX(), 45 + 0.80 * (area.GetY() + BuildingHeight - gfx_bgBuildings[4].area.GetH()), - 1)
		gfx_bgBuildings[5].Draw(area.GetX() + 634, 45 + 0.80 * (area.GetY() + BuildingHeight - gfx_bgBuildings[5].area.GetH()), - 1)

		SetColor 255, 255, 255
		SetAlpha 1.0
	End Method


	Method CreateRoomUsedTooltip:Int(door:TRoomDoor, room:TRoom = null)
		'if no door was given, use main door of room
		if not door and room then door = TRoomDoor.GetMainDoorToRoom(room)
		if not door then return FALSE

		roomUsedTooltip	= TTooltip.Create("Besetzt", "In diesem Raum ist schon jemand", 0,0,-1,-1,2000)
		roomUsedTooltip.area.position.SetY(area.GetY() + GetFloorY(door.area.GetY()))
		roomUsedTooltip.area.position.SetX(door.area.GetX() + door.area.GetW()/2 - roomUsedTooltip.GetWidth()/2)
		roomUsedTooltip.enabled = 1

		return TRUE
	End Method


	Method CreateRoomBlockedTooltip:Int(door:TRoomDoor, room:TRoom = null)
		'if no door was given, use main door of room
		if not door and room then door = TRoomDoor.GetMainDoorToRoom(room)
		if not door then return FALSE

		roomUsedTooltip = TTooltip.Create(GetLocale("BLOCKED"), GetLocale("ACCESS_TO_THIS_ROOM_IS_CURRENTLY_NOT_POSSIBLE"), 0,0,-1,-1,2000)
		roomUsedTooltip.area.position.SetY(area.GetY() + GetFloorY(door.area.GetY()))
		roomUsedTooltip.area.position.SetX(door.area.GetX() + door.area.GetW()/2 - roomUsedTooltip.GetWidth()/2)
		roomUsedTooltip.enabled = 1

		return TRUE
	End Method


	Method CenterToFloor:Int(floornumber:Int)
		area.position.y = ((13 - (floornumber)) * 73) - 115
	End Method


	'Summary: returns y which has to be added to building.y, so its the difference
	Function GetFloorY:Int(floornumber:Int)
		Return (66 + 1 + (13 - floornumber) * 73)		  ' +10 = interface
	End Function


	Method GetFloor:Int(y:Int)
		Return MathHelper.Clamp(14 - Ceil((y - area.position.y) / 73),0,13) 'TODO/FIXIT mv 10.11.2012 scheint nicht zu funktionieren!!! Liefert immer die gleiche Zahl egal in welchem Stockwerk man ist
	End Method


	'point ist hier NICHT zwischen 0 und 13... sondern pixelgenau...
	'also zwischen 0 und ~ 1000
	Function getFloorByPixelExactPoint:Int(point:TVec2D)
		For Local i:Int = 0 To 13
			If GetFloorY(i) < point.y Then Return i
		Next
		Return -1
	End Function
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetBuilding:TBuilding()
	return TBuilding.GetInstance()
End Function