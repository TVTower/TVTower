
'Summary: Type of building, area around it and doors,...
Type TBuilding Extends TStaticEntity
	Field buildingDisplaceX:Int = 127			'px at which the building starts (leftside added is the door)
	Field innerLeft:Int			= 127 + 40
	Field innerRight:Int		= 127 + 468
	Field skycolor:Float 		= 0
	Field ufo_normal:TSpriteEntity 			{nosave}
	Field ufo_beaming:TSpriteEntity			{nosave}
	Field Elevator:TElevator

	Field Moon_Path:TCatmullRomSpline	= New TCatmullRomSpline {nosave}
	Field Moon_PathCurrentDistanceOld:Float= 0.0
	Field Moon_PathCurrentDistance:Float= 0.0
	Field Moon_MovementStarted:Int		= False
	Field Moon_MovementBaseSpeed:Float	= 0.0		'so that the whole path moved within time

	Field UFO_Path:TCatmullRomSpline	= New TCatmullRomSpline {nosave}
	Field UFO_PathCurrentDistanceOld:Float	= 0.0
	Field UFO_PathCurrentDistance:Float		= 0.0
	Field UFO_MovementStarted:Int		= False
	Field UFO_MovementBaseSpeed:Float	= 0.0
	Field UFO_DoBeamAnimation:Int		= False
	Field UFO_BeamAnimationDone:Int		= False

	Field Clouds:TSpriteEntity[7]					{nosave}
	Field CloudsAlpha:Float[7]						{nosave}

	Field TimeColor:Double
	Field DezimalTime:Float
	Field ActHour:Int
	Field initDone:Int					= False
	Field gfx_bgBuildings:TSprite[6]				{nosave}
	Field gfx_building:TSprite					{nosave}
	Field gfx_buildingEntrance:TSprite			{nosave}
	Field gfx_buildingEntranceWall:TSprite		{nosave}
	Field gfx_buildingFence:TSprite				{nosave}
	Field gfx_buildingRoof:TSprite				{nosave}

	Field room:TRoom					= Null		'the room used for the building
	Field roomUsedTooltip:TTooltip		= Null
	Field Stars:TPoint[60]							{nosave}

	Global _instance:TBuilding
	Global _backgroundModified:int		= FALSE
	Global _eventsRegistered:int 		= FALSE


	Method New()
		_instance = self

		area.position.SetX(20)

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
		'call to set graphics, paths for objects and other
		'stuff not gameplay relevant
		InitGraphics()

		area.position.SetY(0 - gfx_building.area.GetH() + 5 * 73 + 20)	' 20 = interfacetop, 373 = raumhoehe
		Elevator = new TElevator.Create()
		Elevator.Pos.SetY(GetFloorY(Elevator.CurrentFloor) - Elevator.spriteInner.area.GetH())

		Elevator.RouteLogic = TElevatorSmartLogic.Create(Elevator, 0) 'Die Logik die im Elevator verwendet wird. 1 heißt, dass der PrivilegePlayerMode aktiv ist... mMn macht's nur so wirklich Spaß

		Return self
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TBuilding", "Savegame loaded - reassign sprites, recreate movement paths for gfx.", LOG_DEBUG | LOG_SAVELOAD)
		GetInstance().InitGraphics()
		'reassign the elevator - should not be needed
		'GetInstance().Elevator = TElevator.GetInstance()

		'reposition hotspots
		GetInstance().Init()
	End Function


	Method InitGraphics()
		'==== MOON ====
		'movement
		Moon_Path = New TCatmullRomSpline
		Moon_Path.addXY( -50, 640 )
		Moon_Path.addXY( -50, 190 )
		Moon_Path.addXY( 400,  10 )
		Moon_Path.addXY( 850, 190 )
		Moon_Path.addXY( 850, 640 )

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

		'==== CLOUDS ====
		For Local i:Int = 0 To Clouds.length-1
			Clouds[i] = New TSpriteEntity
			Clouds[i].SetSprite(GetSpriteFromRegistry("gfx_building_BG_clouds"))
			Clouds[i].area.position.SetXY(- 200 * i + (i + 1) * Rand(0,400), - 30 + Rand(0,30))
			Clouds[i].velocity.SetXY(2 + Rand(0, 6),0)
			CloudsAlpha[i] = Float(Rand(80,100))/100.0
		Next

		'==== STARS ====
		For Local j:Int = 0 To 29
			Stars[j] = new TPoint.Init( 10+Rand(0,150), 20+Rand(0,273), 50+Rand(0,150) )
		Next
		For Local j:Int = 30 To 59
			Stars[j] = new TPoint.Init( 650+Rand(0,150), 20+Rand(0,273), 50+Rand(0,150) )
		Next


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
	End Method


	Method Update()
		'66 = 13th floor height, 2 floors normal = 1*73, 50 = roof
		If Game.GetPlayer().Figure.inRoom = Null
			'working for player as center
			area.position.y =  1 * 66 + 1 * 73 + 50 - Game.GetPlayer().Figure.area.GetY()
		Endif


		local deltaTime:float = GetDeltaTimer().GetDelta()
		area.position.y = Clamp(area.position.y, - 637, 88)
		UpdateBackground(deltaTime)


		'update hotspot tooltips
		If room
			For Local hotspot:THotspot = EachIn room.hotspots
				hotspot.update(area.GetX(), area.GetY())
			Next
		EndIf


		If roomUsedTooltip Then roomUsedTooltip.Update()


		'handle player target changes
		If Not Game.GetPlayer().Figure.inRoom
			If MOUSEMANAGER.isClicked(1) And Not GUIManager._ignoreMouse
				If Not Game.GetPlayer().Figure.isChangingRoom
					If THelper.IsIn(MouseManager.x, MouseManager.y, 20, 10, 760, 373)
						Game.GetPlayer().Figure.ChangeTarget(MouseManager.x, MouseManager.y)
						MOUSEMANAGER.resetKey(1)
					EndIf
				EndIf
			EndIf
		EndIf
	End Method

	Method Init:Int()
		If initDone Then Return True

		if not _backgroundModified
			Local locy13:Int	= GetFloorY(13)
			Local locy3:Int		= GetFloorY(3)
			Local locy0:Int		= GetFloorY(0)
			Local locy12:Int	= GetFloorY(12)

			Local Pix:TPixmap = LockImage(gfx_building.parent.image)
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Pflanze4").GetImage(), Pix, -buildingDisplaceX + innerleft + 40, locy12 - GetSpriteFromRegistry("gfx_building_Pflanze4").area.GetH())
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Pflanze6").GetImage(), Pix, -buildingDisplaceX + innerRight - 95, locy12 - GetSpriteFromRegistry("gfx_building_Pflanze6").area.GetH())
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Pflanze2").GetImage(), Pix, -buildingDisplaceX + innerleft + 105, locy13 - GetSpriteFromRegistry("gfx_building_Pflanze2").area.GetH())
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Pflanze3").GetImage(), Pix, -buildingDisplaceX + innerRight - 105, locy13 - GetSpriteFromRegistry("gfx_building_Pflanze3").area.GetH())
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerleft + 125, locy0 - GetSpriteFromRegistry("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerRight - 125 - GetSpriteFromRegistry("gfx_building_Wandlampe").area.GetW(), locy0 - GetSpriteFromRegistry("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerleft + 125, locy13 - GetSpriteFromRegistry("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerRight - 125 - GetSpriteFromRegistry("gfx_building_Wandlampe").area.GetW(), locy13 - GetSpriteFromRegistry("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerleft + 125, locy3 - GetSpriteFromRegistry("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(GetSpriteFromRegistry("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerRight - 125 - GetSpriteFromRegistry("gfx_building_Wandlampe").area.GetW(), locy3 - GetSpriteFromRegistry("gfx_building_Wandlampe").area.GetH())
			UnlockImage(gfx_building.parent.image)
			Pix = Null

			_backgroundModified = TRUE
		endif

		'assign room
		room = RoomCollection.GetFirstByDetails("building")

		'move elevatorplan hotspots to the elevator
		For Local hotspot:THotspot = EachIn room.hotspots
			If hotspot.name = "elevatorplan"
				hotspot.area.position.setX( Elevator.pos.getX() )
				hotspot.area.dimension.setXY( Elevator.GetDoorWidth(), 58 )
			EndIf
		Next

		initDone = True
	End Method


	Function onReachTarget:Int( triggerEvent:TEventBase )
		Local figure:TFigure = TFigure( triggerEvent._sender )
		If Not figure Then Return False

		Local hotspot:THotspot = THotspot( triggerEvent.getData().get("hotspot") )
		'we are only interested in hotspots
		If Not hotspot Then Return False


		If hotspot.name = "elevatorplan"
			'Print "figure "+figure.name+" reached elevatorplan"

			Local room:TRoom = RoomCollection.GetFirstByDetails("elevatorplan")
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

		Game.getPlayer().figure.changeTarget( GetInstance().area.GetX() + hotspot.area.getX() + hotspot.area.getW()/2, GetInstance().area.GetY() + hotspot.area.getY() )
		Game.getPlayer().figure.targetHotspot = hotspot

		MOUSEMANAGER.ResetKey(1)
	End Function


	Method Render:int(xOffset:Float = 0, yOffset:Float = 0)
		'=== DRAW SKY ===
		SetColor Int(190 * timecolor), Int(215 * timecolor), Int(230 * timecolor)
		DrawRect(20, 10, 140, 373)
		If area.position.y > 10 Then DrawRect(150, 10, 500, 200)
		DrawRect(650, 10, 130, 373)
		SetColor 255, 255, 255


		TProfiler.Enter("Draw-Building-Background")
		DrawBackground()
		TProfiler.Leave("Draw-Building-Background")


		'reset drawn for all figures... so they can get drawn
		'correct at their "z-indexes" (behind building, elevator or on floor )
		For Local Figure:TFigure = EachIn FigureCollection.list
			Figure.alreadydrawn = False
		Next

		If GetFloor(Game.GetPlayer().Figure.area.GetY()) >= 8
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
		Elevator.Draw()

		SetBlend ALPHABLEND

		For Local Figure:TFigure = EachIn FigureCollection.list
			'draw figure later if outside of building
			If figure.area.GetX() < area.GetX() + buildingDisplaceX Then Continue
			If Not Figure.alreadydrawn Then Figure.Draw()
			Figure.alreadydrawn = True
		Next

		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(area.GetX() + innerRight - 130, area.GetY() + GetFloorY(9), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(area.GetX() + innerLeft + 150, area.GetY() + GetFloorY(13), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		GetSpriteFromRegistry("gfx_building_Pflanze2").Draw(area.GetX() + innerRight - 110, area.GetY() + GetFloorY(9), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		GetSpriteFromRegistry("gfx_building_Pflanze2").Draw(area.GetX() + innerLeft + 150, area.GetY() + GetFloorY(6), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		GetSpriteFromRegistry("gfx_building_Pflanze6").Draw(area.GetX() + innerRight - 85, area.GetY() + GetFloorY(8), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		GetSpriteFromRegistry("gfx_building_Pflanze3a").Draw(area.GetX() + innerLeft + 60, area.GetY() + GetFloorY(1), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		GetSpriteFromRegistry("gfx_building_Pflanze3a").Draw(area.GetX() + innerLeft + 60, area.GetY() + GetFloorY(12), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		GetSpriteFromRegistry("gfx_building_Pflanze3b").Draw(area.GetX() + innerLeft + 150, area.GetY() + GetFloorY(12), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		GetSpriteFromRegistry("gfx_building_Pflanze1").Draw(area.GetX() + innerRight - 70, area.GetY() + GetFloorY(3), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		GetSpriteFromRegistry("gfx_building_Pflanze2").Draw(area.GetX() + innerRight - 75, area.GetY() + GetFloorY(12), - 1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))

		'draw entrance on top of figures
		If GetFloor(Game.GetPlayer().Figure.area.GetY()) <= 4
			SetColor Int(205 * timecolor) + 150, Int(205 * timecolor) + 150, Int(205 * timecolor) + 150
			'draw figures outside the wall
			For Local Figure:TFigure = EachIn FigureCollection.list
				If Not Figure.alreadydrawn Then Figure.Draw()
			Next
			gfx_buildingEntrance.Draw(area.GetX(), area.GetY() + 1024 - gfx_buildingEntrance.area.GetH() - 3)

			SetColor 255,255,255
			'draw wall
			gfx_buildingEntranceWall.Draw(area.GetX() + gfx_buildingEntrance.area.GetW(), area.GetY() + 1024 - gfx_buildingEntranceWall.area.GetH() - 3)
			'draw fence
			gfx_buildingFence.Draw(area.GetX() + buildingDisplaceX + 507, area.GetY() + 1024 - gfx_buildingFence.area.GetH() - 3)
		EndIf

		TRoomDoor.DrawAllTooltips()

		'draw hotspot tooltips
		For Local hotspot:THotspot = EachIn room.hotspots
			hotspot.Render(area.GetX(), area.GetY())
		Next

		If roomUsedTooltip Then roomUsedTooltip.Render()

	End Method


	Method UpdateBackground(deltaTime:Float)
		ActHour = Game.GetHour()
		DezimalTime = Float(ActHour*60 + Game.GetMinute())/60.0

		If 9 <= ActHour And Acthour < 18 Then TimeColor = 1
		If 5 <= ActHour And Acthour <= 9 		'overlapping to avoid colorjumps
			skycolor = DezimalTime
			TimeColor = (skycolor - 5) / 4
			If TimeColor > 1 Then TimeColor = 1
			If skycolor >= 350 Then skycolor = 350
		EndIf
		If 18 <= ActHour And Acthour <= 23 	'overlapping to avoid colorjumps
			skycolor = DezimalTime
			TimeColor = 1 - (skycolor - 18) / 5
			If TimeColor < 0 Then TimeColor = 0
			If skycolor <= 0 Then skycolor = 0
		EndIf


		'compute moon position
		If ActHour > 18 Or ActHour < 7
			'compute current distance
			If Not Moon_MovementStarted
				'we have 15 hrs to "see the moon" - so we have add them accordingly
				'this means - we have to calculate the hours "gone" since 18:00
				Local minutesPassed:Int = 0
				If ActHour>18
					minutesPassed = (ActHour-18)*60 + Game.GetMinute()
				Else
					minutesPassed = (ActHour+7)*60 + Game.GetMinute()
				EndIf

				'calculate the base speed needed so that the moon would move
				'the whole path within 15 hrs (15*60 minutes)
				'this means: after 15hrs 100% of distance are reached
				Moon_MovementBaseSpeed = 1.0 / (15*60)

				Moon_PathCurrentDistance = minutesPassed * Moon_MovementBaseSpeed

				Moon_MovementStarted = True
			EndIf

			'backup for tweening
			Moon_PathCurrentDistanceOld = Moon_PathCurrentDistance
			Moon_PathCurrentDistance:+ deltaTime * Moon_MovementBaseSpeed * Game.GetGameMinutesPerSecond()
		Else
			Moon_MovementStarted = False
			'set to beginning
			Moon_PathCurrentDistanceOld = 0.0
			Moon_PathCurrentDistance = 0.0
		EndIf


		'compute ufo
		'-----------
		'only happens between...
		If Game.GetDay() Mod 2 = 0 And (DezimalTime > 18 Or DezimalTime < 7)
			UFO_MovementBaseSpeed = 1.0 / 60.0 '30 minutes for whole path

			'only continue moving if not doing the beamanimation
			If Not UFO_DoBeamAnimation Or UFO_BeamAnimationDone
				UFO_PathCurrentDistanceOld = UFO_PathCurrentDistance
				UFO_PathCurrentDistance:+ deltaTime * UFO_MovementBaseSpeed * Game.GetGameMinutesPerSecond()

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

		For Local i:Int = 0 To Clouds.length-1
			Clouds[i].Update()
		Next
	End Method

	'Summary: Draws background of the mainscreen (stars, buildings, moon...)
	Method DrawBackground(tweenValue:Float=1.0)
		Local BuildingHeight:Int = gfx_building.area.GetH() + 56

		If DezimalTime > 18 Or DezimalTime < 7
			If DezimalTime > 18 And DezimalTime < 19 Then SetAlpha (1.0- (19.0 - DezimalTime))
			If DezimalTime > 6 And DezimalTime < 8 Then SetAlpha (4.0 - DezimalTime / 2.0)
			'stars
			SetBlend MASKBLEND
			Local minute:Float = Game.GetMinute()
			For Local i:Int = 0 To 59
				If i Mod 6 = 0 And minute Mod 2 = 0 Then Stars[i].z = Rand(0, Max(1,Stars[i].z) )
				SetColor Stars[i].z , Stars[i].z , Stars[i].z
				Plot(Stars[i].x , Stars[i].y )
			Next

			SetColor 255, 255, 255
'			DezimalTime:+3
			If DezimalTime > 24 Then DezimalTime:-24

			SetBlend ALPHABLEND

			Local tweenDistance:Float = GetTweenResult(Moon_PathCurrentDistance, Moon_PathCurrentDistanceOld, True)
			Local moonPos:TPoint = Moon_Path.GetTweenPoint(tweenDistance, True)
			'draw moon - frame is from +6hrs (so day has already changed at 18:00)
			'GetSpriteFromRegistry("gfx_building_BG_moon").Draw(40, 40, 12 - ( Game.GetDay(Game.GetTimeGone()+6*60) Mod 12) )
			GetSpriteFromRegistry("gfx_building_BG_moon").Draw(moonPos.x, 0.10 * (area.GetY()) + moonPos.y, 12 - ( Game.GetDay(Game.GetTimeGone()+6*60) Mod 12) )
		EndIf

		For Local i:Int = 0 To Clouds.length - 1
			SetColor Int(205 * timecolor) + 80*CloudsAlpha[i], Int(205 * timecolor) + 80*CloudsAlpha[i], Int(205 * timecolor) + 80*CloudsAlpha[i]
			SetAlpha CloudsAlpha[i]
			'draw a bit offset - parallax effect
			Clouds[i].Render(0, Clouds[i].area.GetY() + 0.2*area.GetY())
		Next
		SetAlpha 1.0

		SetColor Int(205 * timecolor) + 175, Int(205 * timecolor) + 175, Int(205 * timecolor) + 175
		SetBlend ALPHABLEND
		'draw UFO
		If DezimalTime > 18 Or DezimalTime < 7
'			If Game.GetDay() Mod 2 = 0
				'compute and draw Ufo
				Local tweenDistance:Float = GetTweenResult(UFO_PathCurrentDistance, UFO_PathCurrentDistanceOld, True)
				Local UFOPos:TPoint = UFO_Path.GetTweenPoint(tweenDistance, True)
				'print UFO_PathCurrentDistance
				If UFO_DoBeamAnimation And Not UFO_BeamAnimationDone
					ufo_beaming.area.position.SetXY(UFOPos.x, 0.25 * (area.GetY() + BuildingHeight - gfx_bgBuildings[0].area.GetH()) + UFOPos.y)
					ufo_beaming.Render()
				Else
					GetSpriteFromRegistry("gfx_building_BG_ufo").Draw( UFOPos.x, 0.25 * (area.GetY() + BuildingHeight - gfx_bgBuildings[0].area.GetH()) + UFOPos.y, ufo_normal.GetFrameAnimations().GetCurrent().GetCurrentFrame())
				EndIf
'			EndIf
		EndIf

		SetBlend MASKBLEND

		Local baseBrightness:Int = 75

		SetColor Int(225 * timecolor) + baseBrightness, Int(225 * timecolor) + baseBrightness, Int(225 * timecolor) + baseBrightness
		gfx_bgBuildings[0].Draw(area.GetX(), 105 + 0.25 * (area.GetY() + 5 + BuildingHeight - gfx_bgBuildings[0].area.GetH()), - 1)
		gfx_bgBuildings[1].Draw(area.GetX() + 634, 105 + 0.25 * (area.GetY() + 5 + BuildingHeight - gfx_bgBuildings[1].area.GetH()), - 1)

		SetColor Int(215 * timecolor) + baseBrightness+15, Int(215 * timecolor) + baseBrightness+15, Int(215 * timecolor) + baseBrightness+15
		gfx_bgBuildings[2].Draw(area.GetX(), 120 + 0.35 * (area.GetY() + BuildingHeight - gfx_bgBuildings[2].area.GetH()), - 1)
		gfx_bgBuildings[3].Draw(area.GetX() + 636, 120 + 0.35 * (area.GetY() + 60 + BuildingHeight - gfx_bgBuildings[3].area.GetH()), - 1)

		SetColor Int(205 * timecolor) + baseBrightness+30, Int(205 * timecolor) + baseBrightness+30, Int(205 * timecolor) + baseBrightness+30
		gfx_bgBuildings[4].Draw(area.GetX(), 45 + 0.80 * (area.GetY() + BuildingHeight - gfx_bgBuildings[4].area.GetH()), - 1)
		gfx_bgBuildings[5].Draw(area.GetX() + 634, 45 + 0.80 * (area.GetY() + BuildingHeight - gfx_bgBuildings[5].area.GetH()), - 1)

		SetColor 255, 255, 255
		SetAlpha 1.0
	End Method


	Method CreateRoomUsedTooltip:Int(door:TRoomDoor, room:TRoom = null)
		'if no door was given, use main door of room
		if not door and room then door = TRoomDoor.GetMainDoorToRoom(room)
		if not door then return FALSE

		roomUsedTooltip			= TTooltip.Create("Besetzt", "In diesem Raum ist schon jemand", 0,0,-1,-1,2000)
		roomUsedTooltip.area.position.SetY(area.GetY() + GetFloorY(door.Pos.y))
		roomUsedTooltip.area.position.SetX(door.Pos.x + door.doorDimension.x/2 - roomUsedTooltip.GetWidth()/2)
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
		Return Clamp(14 - Ceil((y - area.position.y) / 73),0,13) 'TODO/FIXIT mv 10.11.2012 scheint nicht zu funktionieren!!! Liefert immer die gleiche Zahl egal in welchem Stockwerk man ist
	End Method


	Function getFloorByPixelExactPoint:Int(point:TPoint) 'point ist hier NICHT zwischen 0 und 13... sondern pixelgenau... also zwischen 0 und ~ 1000
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