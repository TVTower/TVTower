
'Summary: Type of building, area around it and doors,...
Type TBuilding Extends TRenderable
	Field pos:TPoint = TPoint.Create(20,0)
	Field buildingDisplaceX:Int = 127			'px at which the building starts (leftside added is the door)
	Field innerLeft:Int			= 127 + 40
	Field innerRight:Int		= 127 + 468
	Field skycolor:Float 		= 0
	Field ufo_normal:TMoveableAnimSprites 			{nosave}
	Field ufo_beaming:TMoveableAnimSprites 			{nosave}
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

	Field Clouds:TMoveableAnimSprites[7]			{nosave}
	Field CloudsAlpha:Float[7]						{nosave}

	Field TimeColor:Double
	Field DezimalTime:Float
	Field ActHour:Int
	Field initDone:Int					= False
	Field gfx_bgBuildings:TGW_Sprite[6]				{nosave}
	Field gfx_building:TGW_Sprite					{nosave}
	Field gfx_buildingEntrance:TGW_Sprite			{nosave}
	Field gfx_buildingEntranceWall:TGW_Sprite		{nosave}
	Field gfx_buildingFence:TGW_Sprite				{nosave}
	Field gfx_buildingRoof:TGW_Sprite				{nosave}

	Field room:TRoom					= Null		'the room used for the building
	Field roomUsedTooltip:TTooltip		= Null
	Field Stars:TPoint[60]							{nosave}

	Global _instance:TBuilding
	Global _backgroundModified:int		= FALSE
	Global _eventsRegistered:int 		= FALSE


	Method New()
		_instance = self

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
		EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", new TData.AddString("text", "Create Building").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )

		'call to set graphics, paths for objects and other
		'stuff not gameplay relevant
		InitGraphics()

		pos.y			= 0 - gfx_building.area.GetH() + 5 * 73 + 20	' 20 = interfacetop, 373 = raumhoehe
		Elevator		= new TElevator.Create()
		Elevator.Pos.SetY(GetFloorY(Elevator.CurrentFloor) - Elevator.spriteInner.area.GetH())

		Elevator.RouteLogic = TElevatorSmartLogic.Create(Elevator, 0) 'Die Logik die im Elevator verwendet wird. 1 heißt, dass der PrivilegePlayerMode aktiv ist... mMn macht's nur so wirklich Spaß

		Return self
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TDevHelper.Log("TBuilding", "Savegame loaded - reassign sprites, recreate movement paths for gfx.", LOG_DEBUG | LOG_SAVELOAD)
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
		ufo_normal	= New TMoveableAnimSprites.Create(Assets.GetSprite("gfx_building_BG_ufo"), 9, 100).SetupMoveable(0, 100, 0,0)
		ufo_beaming	= New TMoveableAnimSprites.Create(Assets.GetSprite("gfx_building_BG_ufo2"), 9, 100).SetupMoveable(0, 100, 0,0)
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
			Clouds[i] = New TMoveableAnimSprites.Create(Assets.GetSprite("gfx_building_BG_clouds"), 1,0).SetupMoveable(- 200 * i + (i + 1) * Rand(0,400), - 30 + Rand(0,30), 2 + Rand(0, 6),0)
			CloudsAlpha[i] = Float(Rand(80,100))/100.0
		Next

		'==== STARS ====
		For Local j:Int = 0 To 29
			Stars[j] = TPoint.Create( 10+Rand(0,150), 20+Rand(0,273), 50+Rand(0,150) )
		Next
		For Local j:Int = 30 To 59
			Stars[j] = TPoint.Create( 650+Rand(0,150), 20+Rand(0,273), 50+Rand(0,150) )
		Next


		'==== BACKGROUND BUILDINGS ====
		gfx_bgBuildings[0] = Assets.GetSprite("gfx_building_BG_Ebene3L")
		gfx_bgBuildings[1] = Assets.GetSprite("gfx_building_BG_Ebene3R")
		gfx_bgBuildings[2] = Assets.GetSprite("gfx_building_BG_Ebene2L")
		gfx_bgBuildings[3] = Assets.GetSprite("gfx_building_BG_Ebene2R")
		gfx_bgBuildings[4] = Assets.GetSprite("gfx_building_BG_Ebene1L")
		gfx_bgBuildings[5] = Assets.GetSprite("gfx_building_BG_Ebene1R")

		'building assets
		gfx_building				= Assets.GetSprite("gfx_building")
		gfx_buildingEntrance		= Assets.GetSprite("gfx_building_Eingang")
		gfx_buildingEntranceWall	= Assets.GetSprite("gfx_building_EingangWand")
		gfx_buildingFence			= Assets.GetSprite("gfx_building_Zaun")
		gfx_buildingRoof			= Assets.GetSprite("gfx_building_Dach")
	End Method


	Method Update(deltaTime:Float=1.0)
		pos.y = Clamp(pos.y, - 637, 88)
		UpdateBackground(deltaTime)


		'update hotspot tooltips
		If room
			For Local hotspot:THotspot = EachIn room.hotspots
				hotspot.update(Self.pos.x, Self.pos.y)
			Next
		EndIf


		If Self.roomUsedTooltip <> Null Then Self.roomUsedTooltip.Update(deltaTime)


		'handle player target changes
		If Not Game.GetPlayer().Figure.inRoom
			If MOUSEMANAGER.isClicked(1) And Not GUIManager.modalActive
				If Not Game.GetPlayer().Figure.isChangingRoom
					If TFunctions.IsIn(MouseManager.x, MouseManager.y, 20, 10, 760, 373)
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
			DrawImageOnImage(Assets.GetSprite("gfx_building_Pflanze4").GetImage(), Pix, -buildingDisplaceX + innerleft + 40, locy12 - Assets.GetSprite("gfx_building_Pflanze4").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Pflanze6").GetImage(), Pix, -buildingDisplaceX + innerRight - 95, locy12 - Assets.GetSprite("gfx_building_Pflanze6").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Pflanze2").GetImage(), Pix, -buildingDisplaceX + innerleft + 105, locy13 - Assets.GetSprite("gfx_building_Pflanze2").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Pflanze3").GetImage(), Pix, -buildingDisplaceX + innerRight - 105, locy13 - Assets.GetSprite("gfx_building_Pflanze3").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerleft + 125, locy0 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerRight - 125 - Assets.GetSprite("gfx_building_Wandlampe").area.GetW(), locy0 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerleft + 125, locy13 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerRight - 125 - Assets.GetSprite("gfx_building_Wandlampe").area.GetW(), locy13 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerleft + 125, locy3 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			DrawImageOnImage(Assets.GetSprite("gfx_building_Wandlampe").GetImage(), Pix, -buildingDisplaceX + innerRight - 125 - Assets.GetSprite("gfx_building_Wandlampe").area.GetW(), locy3 - Assets.GetSprite("gfx_building_Wandlampe").area.GetH())
			UnlockImage(gfx_building.parent.image)
			Pix = Null

			_backgroundModified = TRUE
		endif

		'assign room
		room = TRoom.GetFirstByDetails("building")

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

			Local room:TRoom = TRoom.GetFirstByDetails("elevatorplan")
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

		Game.getPlayer().figure.changeTarget( GetInstance().pos.x + hotspot.area.getX() + hotspot.area.getW()/2, GetInstance().pos.y + hotspot.area.getY() )
		Game.getPlayer().figure.targetHotspot = hotspot

		MOUSEMANAGER.ResetKey(1)
	End Function


	Method Draw(tweenValue:Float=1.0)
		pos.y = Clamp(pos.y, - 637, 88)

		TProfiler.Enter("Draw-Building-Background")
		DrawBackground(tweenValue)
		TProfiler.Leave("Draw-Building-Background")

		'reset drawn for all figures... so they can get drawn
		'correct at their "z-indexes" (behind building, elevator or on floor )
		For Local Figure:TFigure = EachIn FigureCollection.list
			Figure.alreadydrawn = False
		Next

		If Building.GetFloor(Game.Players[Game.playerID].Figure.rect.GetY()) >= 8
			SetColor 255, 255, 255
			SetBlend ALPHABLEND
			Building.gfx_buildingRoof.Draw(pos.x + buildingDisplaceX, pos.y - Building.gfx_buildingRoof.area.GetH())
		EndIf

		SetBlend MASKBLEND
		elevator.DrawFloorDoors()

		Assets.GetSprite("gfx_building").draw(pos.x + buildingDisplaceX, pos.y)

		SetBlend MASKBLEND

		'draw overlay - open doors are drawn over "background-image-doors" etc.
		TRoomDoor.DrawAll()
		'draw elevator parts
		Elevator.Draw()

		SetBlend ALPHABLEND

		For Local Figure:TFigure = EachIn FigureCollection.list
			'draw figure later if outside of building
			If figure.rect.GetX() < pos.x + buildingDisplaceX Then Continue
			If Not Figure.alreadydrawn Then Figure.Draw()
			Figure.alreadydrawn = True
		Next

		Local pack:TGW_Spritepack = Assets.getSpritePack("gfx_hochhauspack")
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + innerRight - 130, pos.y + GetFloorY(9), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + innerLeft + 150, pos.y + GetFloorY(13), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + innerRight - 110, pos.y + GetFloorY(9), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + innerLeft + 150, pos.y + GetFloorY(6), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze6").Draw(pos.x + innerRight - 85, pos.y + GetFloorY(8), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze3a").Draw(pos.x + innerLeft + 60, pos.y + GetFloorY(1), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze3a").Draw(pos.x + innerLeft + 60, pos.y + GetFloorY(12), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze3b").Draw(pos.x + innerLeft + 150, pos.y + GetFloorY(12), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze1").Draw(pos.x + innerRight - 70, pos.y + GetFloorY(3), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		pack.GetSprite("gfx_building_Pflanze2").Draw(pos.x + innerRight - 75, pos.y + GetFloorY(12), - 1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))

		'draw entrance on top of figures
		If Building.GetFloor(Game.Players[Game.playerID].Figure.rect.GetY()) <= 4
			SetColor Int(205 * timecolor) + 150, Int(205 * timecolor) + 150, Int(205 * timecolor) + 150
			'draw figures outside the wall
			For Local Figure:TFigure = EachIn FigureCollection.list
				If Not Figure.alreadydrawn Then Figure.Draw()
			Next
			Building.gfx_buildingEntrance.Draw(pos.x, pos.y + 1024 - Building.gfx_buildingEntrance.area.GetH() - 3)

			SetColor 255,255,255
			'draw wall
			Building.gfx_buildingEntranceWall.Draw(pos.x + Building.gfx_buildingEntrance.area.GetW(), pos.y + 1024 - Building.gfx_buildingEntranceWall.area.GetH() - 3)
			'draw fence
			Building.gfx_buildingFence.Draw(pos.x + buildingDisplaceX + 507, pos.y + 1024 - Building.gfx_buildingFence.area.GetH() - 3)
		EndIf

		TRoomDoor.DrawAllTooltips()

		'draw hotspot tooltips
		For Local hotspot:THotspot = EachIn room.hotspots
			hotspot.draw( Self.pos.x, Self.pos.y)
		Next

		If Self.roomUsedTooltip Then Self.roomUsedTooltip.Draw()

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
				If ufo_beaming.getCurrentAnimation().isFinished()
					UFO_BeamAnimationDone = True
					UFO_DoBeamAnimation = False
				EndIf
				ufo_beaming.update(deltaTime)
			EndIf

		Else
			'reset beam enabler anyways
			UFO_DoBeamAnimation = False
			UFO_BeamAnimationDone=False
		EndIf

		For Local i:Int = 0 To Building.Clouds.length-1
			Clouds[i].Update(deltaTime)
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
			'Assets.GetSprite("gfx_building_BG_moon").Draw(40, 40, 12 - ( Game.GetDay(Game.GetTimeGone()+6*60) Mod 12) )
			Assets.GetSprite("gfx_building_BG_moon").Draw(moonPos.x, 0.10 * (pos.y) + moonPos.y, 12 - ( Game.GetDay(Game.GetTimeGone()+6*60) Mod 12) )
		EndIf

		For Local i:Int = 0 To Building.Clouds.length - 1
			SetColor Int(205 * timecolor) + 80*CloudsAlpha[i], Int(205 * timecolor) + 80*CloudsAlpha[i], Int(205 * timecolor) + 80*CloudsAlpha[i]
			SetAlpha CloudsAlpha[i]
			Clouds[i].Draw(Null, Clouds[i].rect.position.Y + 0.2*pos.y) 'parallax
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
					ufo_beaming.rect.position.SetXY(UFOPos.x, 0.25 * (pos.y + BuildingHeight - gfx_bgBuildings[0].area.GetH()) + UFOPos.y)
					ufo_beaming.Draw()
				Else
					Assets.GetSprite("gfx_building_BG_ufo").Draw( UFOPos.x, 0.25 * (pos.y + BuildingHeight - gfx_bgBuildings[0].area.GetH()) + UFOPos.y, ufo_normal.GetCurrentFrame())
				EndIf
'			EndIf
		EndIf

		SetBlend MASKBLEND

		Local baseBrightness:Int = 75

		SetColor Int(225 * timecolor) + baseBrightness, Int(225 * timecolor) + baseBrightness, Int(225 * timecolor) + baseBrightness
		gfx_bgBuildings[0].Draw(pos.x		, 105 + 0.25 * (pos.y + 5 + BuildingHeight - gfx_bgBuildings[0].area.GetH()), - 1)
		gfx_bgBuildings[1].Draw(pos.x + 634	, 105 + 0.25 * (pos.y + 5 + BuildingHeight - gfx_bgBuildings[1].area.GetH()), - 1)

		SetColor Int(215 * timecolor) + baseBrightness+15, Int(215 * timecolor) + baseBrightness+15, Int(215 * timecolor) + baseBrightness+15
		gfx_bgBuildings[2].Draw(pos.x		, 120 + 0.35 * (pos.y 		+ BuildingHeight - gfx_bgBuildings[2].area.GetH()), - 1)
		gfx_bgBuildings[3].Draw(pos.x + 636	, 120 + 0.35 * (pos.y + 60	+ BuildingHeight - gfx_bgBuildings[3].area.GetH()), - 1)

		SetColor Int(205 * timecolor) + baseBrightness+30, Int(205 * timecolor) + baseBrightness+30, Int(205 * timecolor) + baseBrightness+30
		gfx_bgBuildings[4].Draw(pos.x		, 45 + 0.80 * (pos.y + BuildingHeight - gfx_bgBuildings[4].area.GetH()), - 1)
		gfx_bgBuildings[5].Draw(pos.x + 634	, 45 + 0.80 * (pos.y + BuildingHeight - gfx_bgBuildings[5].area.GetH()), - 1)

		SetColor 255, 255, 255
		SetAlpha 1.0
	End Method


	Method CreateRoomUsedTooltip:Int(door:TRoomDoor, room:TRoom = null)
		'if no door was given, use main door of room
		if not door and room then door = TRoomDoor.GetMainDoorToRoom(room)
		if not door then return FALSE

		roomUsedTooltip			= TTooltip.Create("Besetzt", "In diesem Raum ist schon jemand", 0,0,-1,-1,2000)
		roomUsedTooltip.area.position.SetY(pos.y + GetFloorY(door.Pos.y))
		roomUsedTooltip.area.position.SetX(door.Pos.x + door.doorDimension.x/2 - roomUsedTooltip.GetWidth()/2)
		roomUsedTooltip.enabled = 1

		return TRUE
	End Method


	Method CenterToFloor:Int(floornumber:Int)
		pos.y = ((13 - (floornumber)) * 73) - 115
	End Method

	'Summary: returns y which has to be added to building.y, so its the difference
	Function GetFloorY:Int(floornumber:Int)
		Return (66 + 1 + (13 - floornumber) * 73)		  ' +10 = interface
	End Function

	Method GetFloor:Int(_y:Int)
		Return Clamp(14 - Ceil((_y - pos.y) / 73),0,13) 'TODO/FIXIT mv 10.11.2012 scheint nicht zu funktionieren!!! Liefert immer die gleiche Zahl egal in welchem Stockwerk man ist
	End Method

	Method getFloorByPixelExactPoint:Int(point:TPoint) 'point ist hier NICHT zwischen 0 und 13... sondern pixelgenau... also zwischen 0 und ~ 1000
		For Local i:Int = 0 To 13
			If Building.GetFloorY(i) < point.y Then Return i
		Next
		Return -1
	End Method
End Type
