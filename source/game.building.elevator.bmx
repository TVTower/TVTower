'=== Struktur des Elevators ===
Rem
	TElevator:
	Grundlegende Klasse zur Darstellung und Steuerung des Fahrstuhls.
	Die Logik der Routensteuerung ist in TElevatorRouteLogic ausgelagert.

	TElevatorRouteLogic:
	Ableitungen dieser abstrakten Klasse können die Logik für die
	Routenberechnung implementieren.

	TFloorRoute:
	In dieser Klasse werden die Routen-Daten die Calls und Sends des
	Fahrstuhls abgelegt.

	Die Standard-Logikimplementierung ist "TElevatorSmartStrategy" zu
	finden. Diese benötigt die Klasse "TSmartFloorRoute" eine Ableitung
	von 'TFloorRoute.
EndRem
SuperStrict
Import "Dig/base.framework.entity.spriteentity.bmx"
Import "Dig/base.sfx.soundmanager.rtaudio.bmx"
Import "game.figure.base.bmx"
Import "game.player.base.bmx"
Import "game.building.base.bmx"
Import "game.building.base.sfx.bmx" 'for floorbarriersettings
Import "game.gamerules.bmx"



Type TElevator extends TEntity
	'=== Referenzen ===
	'Alle aktuellen Passagiere als TFigure
	Field Passengers:TList = CreateList()
	Field RouteLogic:TElevatorRouteLogic = null
	'Die Liste mit allen Fahrstuhlanfragen und Sendekommandos in der
	'Reihenfolge in der sie gestellt wurden
	Field FloorRouteList:TList = CreateList()

	'=== Aktueller Status (zu speichern) ===
	'0 = warte auf nächsten Auftrag,
	'1 = Türen schließen, 2 = Fahren, 3 = Türen öffnen,
	'4 = entladen/beladen
	Field ElevatorStatus:Int = 0
	'0 = closed, 1 = open, 2 = opening, 3 = closing
	Field DoorStatus:Int = 0
	'Aktuelles Stockwerk
	Field CurrentFloor:Int = 8
	'Hier fährt der Fahrstuhl hin
	Field TargetFloor:Int = 0
	'Aktuelle/letzte Bewegungsrichtung: -1 = nach unten; +1 = nach oben; 0 = gibt es nicht
	Field Direction:Int	= 1
	'während der ElevatorStatus 4, 5 und 0 möglich.
	Field ReadyForBoarding:int = false

	'=== EINSTELLUNGEN ===
	'pixels per second ;D
	Field Speed:Float = 130

	'=== TIMER ===
	'Wie lange (Millisekunden) werden die Türen offen gelassen
	'(alt: 650)
	Field WaitAtFloorTimer:TIntervalTimer = null
	'Der Fahrstuhl wartet so lange, bis diese Zeit erreicht ist (in
	'Millisekunden - basierend auf Time.GetTimeGone() + waitAtFloorTime)
	Field WaitAtFloorTime:Int = 1500

	'=== GRAFIKELEMENTE ===
	'Das Türensprite und seine Animationen
	Field door:TSpriteEntity
	'Das Sprite des Innenraums
	Field SpriteInner:TSprite
	'Damit nicht alle auf einem Haufen stehen, gibt es für die Figures
	'ein paar Offsets im Fahrstuhl
	Field PassengerOffset:TVec2D[]
	'Hier wird abgelegt, welches Offset schon in Benutzung ist und von
	'welcher Figur
	Field PassengerPosition:TFigureBase[]

	'globals are not saved
	Global _soundSource:TSoundSourceElement
	Global _initDone:int = FALSE
	Global _instance:TElevator


	'===== Konstruktor, Speichern, Laden =====
	Function GetInstance:TElevator()
		if not _instance then _instance = new TElevator
		return _instance
	End Function


	Method Initialize:TElevator()
		ElevatorStatus = 0
		DoorStatus = 0
		CurrentFloor = 8
		TargetFloor = 0
		Direction:Int = 1
		ReadyForBoarding = false
		Speed = 130
		WaitAtFloorTime = 1500

		'limit speed between 50 - 240 pixels per second, default 120
		Speed = Max(50, Min(240, GameRules.devConfig.GetInt("DEV_ELEVATOR_SPEED", self.speed)))
		'adjust wait at floor time : 1000 - 2000 ms, default 1700
		WaitAtFloorTime = Max(1000, Min(2000, GameRules.devConfig.GetInt("DEV_ELEVATOR_WAITTIME", self.WaitAtFloorTime)))

		'adjust animation speed (per frame) 30-100, default 70
		local animSpeed:int = Max(30, Min(100, GameRules.devConfig.GetInt("DEV_ELEVATOR_ANIMSPEED", 60)))

		'create timer
		WaitAtFloorTimer = TIntervalTimer.Create(WaitAtFloorTime)

		'reset floor route list and passengers
		FloorRouteList.Clear()
		Passengers.Clear()
	
		PassengerPosition  = PassengerPosition[..6]
		PassengerOffset    = PassengerOffset[..6]
		PassengerOffset[0] = new TVec2D.Init(0, 0)
		PassengerOffset[1] = new TVec2D.Init(-13, 0)
		PassengerOffset[2] = new TVec2D.Init(12, 0)
		PassengerOffset[3] = new TVec2D.Init(-7, 0)
		PassengerOffset[4] = new TVec2D.Init(8, 0)
		PassengerOffset[5] = new TVec2D.Init(-3, 0)

		'create door
		door = new TSpriteEntity
		door.SetSprite(GetSpriteFromRegistry("gfx_building_Fahrstuhl_oeffnend"))
		door.GetFrameAnimations().Set("default", TSpriteFrameAnimation.Create([ [0,70] ], 0, 0) )
		door.GetFrameAnimations().Set("closed", TSpriteFrameAnimation.Create([ [0,70] ], 0, 0) )
		door.GetFrameAnimations().Set("open", TSpriteFrameAnimation.Create([ [7,70] ], 0, 0) )
		door.GetFrameAnimations().Set("opendoor", TSpriteFrameAnimation.Create([ [0,animSpeed],[1,animSpeed],[2,animSpeed],[3,animSpeed],[4,animSpeed],[5,animSpeed],[6,animSpeed],[7,animSpeed] ], 0, 1) )
		door.GetFrameAnimations().Set("closedoor", TSpriteFrameAnimation.Create([ [7,animSpeed],[6,animSpeed],[5,animSpeed],[4,animSpeed],[3,animSpeed],[2,animSpeed],[1,animSpeed],[0,animSpeed] ], 0, 1) )

		InitSprites()

		door.GetFrameAnimations().SetCurrent("open")
		doorStatus = 1 'open
		ElevatorStatus	= 0

		if not _initDone
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			_initDone = TRUE
		endif

		Return self
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TElevator", "Savegame loaded - reassigning sprites and soundsource", LOG_DEBUG | LOG_SAVELOAD)
		'instance holds the object created when loading
		GetInstance().InitSprites()
	End Function


	'should get run as soon as sprites might be invalid (loading, graphics reset)
	Method InitSprites()
		door.SetSprite(GetSpriteFromRegistry("gfx_building_Fahrstuhl_oeffnend"))
		spriteInner	= GetSpriteFromRegistry("gfx_building_Fahrstuhl_Innen")  'gfx_building_elevator_inner
	End Method


	Method GetSoundSource:TElevatorSoundSource()
		return TElevatorSoundSource.GetInstance()
	End Method


	'===== Öffentliche Methoden damit die Figuren den Fahrstuhl steuern können =====

	Method CallElevator(figure:TFigureBase)
		AddFloorRoute(figure.GetFloor(), 1, figure)
	End Method


	Method SendElevator(targetFloor:int, figure:TFigureBase)
		AddFloorRoute(targetFloor, 0, figure)
	End Method


	Method EnterTheElevator:int(figure:TFigureBase, myTargetFloor:int=-1) 'bzw. einsteigen
		If Not IsAllowedToEnterToElevator(figure, myTargetFloor) Then Return False
		If Not Passengers.Contains(figure)
			Passengers.AddLast(figure)
			SetFigureOffset(figure)
			RemoveRouteOfPlayer(figure, 1) 'Call-Route entfernen
			Return true
		Endif
		Return false
	End Method


	'aussteigen
	Method LeaveTheElevator(figure:TFigureBase)
		'Das Offset auf jeden Fall zurücksetzen
		RemoveFigureOffset(figure)
		'Send-Route entfernen
		RemoveRouteOfPlayer(figure, 0)
		'Aus der Passagierliste entfernen
		Passengers.remove(figure)
	End Method


	'===== Externe Hilfsmethoden für Figuren =====

	Method IsFigureInFrontOfDoor:Int(figure:TFigureBase)
		Return (GetDoorCenterX() = figure.area.getX())
	End Method


	Method IsFigureInElevator:Int(figure:TFigureBase)
		Return passengers.Contains(figure)
	End Method
	

	Method GetDoorCenterX:int()
		Return area.GetX() + door.sprite.framew/2
	End Method
	

	Method GetDoorWidth:int()
		Return door.sprite.framew
	End Method
	

	'===== Hilfsmethoden =====

	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigureBase)
		If Not ElevatorCallIsDuplicate(floornumber, who) Then 'Prüfe auf Duplikate
			FloorRouteList.AddLast(RouteLogic.CreateFloorRoute(floornumber, call, who))
			RouteLogic.AddFloorRoute(floornumber, call, who)
		EndIf
	End Method
	

	Method RemoveRouteOfPlayer(figure:TFigureBase, call:int)
		RemoveRoute(GetRouteByPassenger(figure, call))
	End Method


	Method RemoveRoute(route:TFloorRoute)
		if (route <> null)
			FloorRouteList.remove(route)
			RouteLogic.RemoveRouteOfPlayer(route)
		Endif
	End Method
	

	'Entfernt alle (Call-)Routen die nicht wahrgenommen wurden
	Method RemoveIgnoredRoutes()
		For Local route:TFloorRoute = EachIn FloorRouteList
			If route.floornumber = CurrentFloor And route.call = 1
				If Passengers.Contains(route.who)
					'Diesen Fehler lassen... er zeigt das noch ein
					'Programmierfehler vorliegt der sonst "verschluckt"
					'werden würde
					throw "Logic-Exception: Person is in passengers-list, but the call-task still exists."
				Else
					RemoveRoute(route)
				Endif
			Endif
		Next
	End Method
	

	Method IsAllowedToEnterToElevator:int(figure:TFigureBase, myTargetFloor:int=-1)
		Return RouteLogic.IsAllowedToEnterToElevator(figure, myTargetFloor)
	End Method
	

	Method ElevatorCallIsDuplicate:Int(floornumber:Int, who:TFigureBase)
		For Local DupeRoute:TFloorRoute = EachIn FloorRouteList
			If DupeRoute.who.id = who.id And DupeRoute.floornumber = floornumber Then Return True
		Next
		Return False
	End Method
	

	Method GetRouteByPassenger:TFloorRoute(passenger:TFigureBase, isCallRoute:int)
		For Local route:TFloorRoute = EachIn FloorRouteList
			If route.who = passenger And route.call = isCallRoute Then Return route
		Next
		Return null
	End Method


	Method CalculateNextTarget:int()
		Return RouteLogic.CalculateNextTarget()
	End Method
	

	Method GetElevatorCenterPos:TVec3D()
		'-25 = z-Achse für Audio. Der Fahrstuhl liegt etwas im Hintergrund
		if parent
			Return new TVec3D.Init(parent.area.GetX() + area.GetX() + door.sprite.framew/2, area.GetY() + door.sprite.frameh/2 + 56, -25)
		else
			Return new TVec3D.Init(area.GetX() + door.sprite.framew/2, area.GetY() + door.sprite.frameh/2 + 56, -25)
		endif
	End Method


	'===== Offset-Funktionen =====

	Method SetFigureOffset(figure:TFigureBase)
		for local i:int = 0 to len(PassengerOffset) -1
			If PassengerPosition[i] = null Then PassengerPosition[i] = figure; Exit
		next
	End Method


	Method RemoveFigureOffset(figure:TFigureBase)
		for local i:int = 0 to len(PassengerOffset) -1
			If PassengerPosition[i] = figure Then PassengerPosition[i] = null; Exit
		next
		figure.PosOffset.SetXY(0, 0)
	End Method
	

	'Aktualisiert das Offset und bewegt die Figur an die richtige Position
	Method MovePassengerToPosition()
		local deltaTime:Float = GetDeltaTimer().GetDelta() * GetWorldSpeedFactor()

		for local i:int = 0 to len(PassengerPosition) - 1
			local figure:TFigureBase = PassengerPosition[i]
			If not figure then continue

			'move with 50% of normal movement speed
			local moveX:Float = 0.5 * figure.initialDX * deltaTime

			If figure.PosOffset.getX() <> PassengerOffset[i].getX()
				'set to 1 -> indicator we are moving in the elevator (boarding)
				figure.boardingState = 1

				'avoid rounding errors ("jittering") and set to target
				'if distance is smaller than movement
				'we only do that if offsets differ to avoid doing it if
				'no offset is set
				if abs(figure.PosOffset.getX() - PassengerOffset[i].getX()) <= moveX
					'set x to the target so it settles to that value
					figure.PosOffset.setX( PassengerOffset[i].getX())
					'set state to 0 so figures can recognize they
					'reached the displaced x
					figure.boardingState = 0
				else
					if figure.PosOffset.getX() > PassengerOffset[i].getX()
						figure.PosOffset.AddX( -moveX )
					else
						figure.PosOffset.AddX( +moveX )
					endif
				endif
			Endif
		next
	End Method


	'Aktualisiert das Offset und bewegt die Figur zum Ausgang
	Method MoveDeboardingPassengersToCenter()
		local deltaTime:Float = GetDeltaTimer().GetDelta() * GetWorldSpeedFactor()
	
		for local i:int = 0 to len(PassengerPosition) - 1
			local figure:TFigureBase = PassengerPosition[i]
			If not figure then continue

			'move with 50% of normal movement speed
			local moveX:Float = 0.5 * figure.initialDX * deltaTime

			'Will die Person aussteigen?
			If GetRouteByPassenger(figure, 0).floornumber = CurrentFloor
				If figure.PosOffset.getX() <> 0
					'set state to -1 -> indicator we are moving in the
					'elevator but from Offset to 0 (different to boarding)
					figure.boardingState = -1

					'avoid rounding errors ("jittering") and set to
					'target if distance is smaller than movement
					'we only do that if offsets differ to avoid doing it
					'if no offset is set
					if abs(figure.PosOffset.getX()) <= moveX
						'set x to 0 so it settles to that value
						'set "y" to 0 so figures can recognize they
						'reached the displaced x
						figure.PosOffset.setX( 0 )
						'set state to 0 so figures can recognize they
						'reached the displaced x
						figure.boardingState = 0
					else
						if figure.PosOffset.getX() > 0
							figure.PosOffset.AddX( -moveX )
						else
							figure.PosOffset.AddX( +moveX )
						endif
					endif
				Endif
			Endif
		next
	End Method


	'===== Fahrstuhl steuern =====

	Method OpenDoor()
		GetSoundSource().PlayRandomSfx("elevator_door_open")
		door.GetFrameAnimations().SetCurrent("opendoor", True)
		DoorStatus = 2 'wird geoeffnet
	End Method


	Method CloseDoor()
		GetSoundSource().PlayRandomSfx("elevator_door_close")
		door.GetFrameAnimations().SetCurrent("closedoor", True)
		DoorStatus = 3 'closing
	End Method


	'===== Aktualisierungs-Methoden =====

	Method Update:int()
		local deltaTime:Float = GetDeltaTimer().GetDelta() * GetWorldSpeedFactor()

		'the -1 is used for displace the object one pixel higher, so
		'it has to reach the first pixel of the floor until the
		'function returns the new one, instead of positioning it
		'directly on the floorground
		local tmpCurrentFloor:int = GetBuildingBase().GetFloor(area.GetY() + spriteInner.area.GetH() - 1)
		local tmpFloorY:int = TBuildingBase.GetFloorY2(tmpCurrentFloor)
		local tmpElevatorBottomY:int = area.GetY() + spriteInner.area.GetH()

		'direction = -1 => downwards
		'direction = +1 => upwards
		If (direction < 0 and tmpFloorY <= tmpElevatorBottomY) or ..
		   (direction > 0 and tmpFloorY >= tmpElevatorBottomY)
			CurrentFloor = tmpCurrentFloor
		EndIf


		'0 = wait for next task
		If ElevatorStatus = 0
			'get next target on a route
			TargetFloor = CalculateNextTarget()
			'found new target
			If CurrentFloor <> TargetFloor
				ReadyForBoarding = false
				'close doors
				ElevatorStatus = 1
			Endif
		Endif

		'1 = close doors
		If ElevatorStatus = 1
			If doorStatus <> 0 And doorStatus <> 3 And waitAtFloorTimer.isExpired() Then CloseDoor() 'Wenn die Wartezeit vorbei ist, dann Türen schließen

			'wait until door animation finished
			If door.GetFrameAnimations().getCurrentAnimationName() = "closedoor"
				If door.GetFrameAnimations().getCurrent().isFinished()
					door.GetFrameAnimations().SetCurrent("closed")
					'closed
					doorStatus = 0
					'2 = move
					ElevatorStatus = 2
					GetSoundSource().PlayRandomSfx("elevator_engine")
				EndIf
			EndIf
		Endif

		'2 = move
		If ElevatorStatus = 2
			'Check again if there is a new target which can get a lift
			'on this route
			TargetFloor = CalculateNextTarget()

			'has the elevator arrived but the doors are still closed?
			'open them!
			if CurrentFloor = TargetFloor
				'open doors
				ElevatorStatus = 3
				'Direction = 0
			Else
				'backup for tweening
				oldPosition.SetXY(area.position.x, area.position.y)

				If (CurrentFloor < TargetFloor) then Direction = 1 else Direction = -1
				'set velocity according (negative) direction
				SetVelocity(0, -Direction * Speed)

				'set new position
				area.position.AddXY( deltaTime * GetVelocity().x, deltaTime * GetVelocity().y )


				'do not move further than the target floor
				local tmpTargetFloorY:int = TBuildingBase.GetFloorY2(TargetFloor) - spriteInner.area.GetH()
				
				If (direction < 0 and area.GetY() > tmpTargetFloorY) or ..
				   (direction > 0 and area.GetY() < tmpTargetFloorY)
					area.position.y = tmpTargetFloorY
				endif

				'move figures in elevator together with the inner part
				For Local figure:TFigureBase = EachIn Passengers
					figure.area.position.setY( area.GetY() + spriteInner.area.GetH())
				Next
			EndIf
		Endif

		If ElevatorStatus = 3 '3 = Türen öffnen
			If doorStatus = 0
				OpenDoor()
				'set time for the doors to keep open
				'adjust this by worldSpeedFactor at that time
				'so a higher factor shortens time to wait
				waitAtFloorTimer.SetInterval(waitAtFloorTime / TEntity.globalWorldSpeedFactor, true)
			Endif

			'continue door animation for opening doors
			'also deboard passengers as soon as finished
			If door.GetFrameAnimations().getCurrentAnimationName() = "opendoor"
				'while the door animation is active, the deboarding
				'figures will move to the exit/door
				MoveDeboardingPassengersToCenter()
				
				If door.GetFrameAnimations().GetCurrent().isFinished()
					'deboarding
					ElevatorStatus = 4
					door.GetFrameAnimations().SetCurrent("open")
					'open
					doorStatus = 1
				EndIf
			EndIf
		Endif

		'4 = (de-)boarding
		If ElevatorStatus = 4
			If ReadyForBoarding = false
				ReadyForBoarding = true
			'happens in Else-part so the Update-loop could switch back
			'to the figures again for (de-)boarding
			Else
				'if the waiting time is expired, search a new target
				If waitAtFloorTimer.isExpired()
					'remove unused routes
					RemoveIgnoredRoutes()
					'0 = wait for next task
					ElevatorStatus = 0
					RouteLogic.BoardingDone()
				Endif
			Endif
		Endif

		'move passengers to their positions if needed.
		'Of course do not so if deboarding.
		If ElevatorStatus <> 3 Then MovePassengerToPosition()

		'animate doors
		door.Update()
	End Method


	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		SetBlend ALPHABLEND

		local parentY:int = GetScreenY()
		if parent then parentY = parent.GetScreenY()

		'draw the door the elevator is currently at (eg. for animation)
		'instead of using GetScreenY() we fix our y coordinate to the
		'current floor
		door.RenderAt(GetScreenX(), parentY + TBuildingBase.GetFloorY2(CurrentFloor) - 50)
		
		'draw elevator position above the doors
		For Local i:Int = 0 To 13
			Local locy:Int = parentY + TBuildingBase.GetFloorY2(i) - door.sprite.area.GetH() - 8
			If locy < 410 And locy > -50
				SetColor 200,0,0
				DrawRect(GetScreenX() - 4 + 10 + (CurrentFloor)*2, locy + 3, 2,2)
				SetColor 255,255,255
			EndIf
		Next

		'draw call state next to the doors
		For Local FloorRoute:TFloorRoute = EachIn FloorRouteList
			Local locy:Int = parentY + TBuildingBase.GetFloorY2(floorroute.floornumber) - spriteInner.area.GetH() + 26
			If floorroute.call
				'elevator is called to this floor
				SetColor 220,240,40
				SetAlpha 0.55
				DrawRect(GetScreenX() + 44, locy, 3,2)
				SetAlpha 1.0
				DrawRect(GetScreenX() + 44, locy, 3,1)
			Else
				'elevator will stop there (destination)
				SetColor 220,120,50
				SetAlpha 0.85
				DrawRect(GetScreenX() + 44, locy+3, 3,2)
				SetColor 250,150,80
				SetAlpha 1.0
				DrawRect(GetScreenX() + 44, locy+4, 3,1)
				SetAlpha 1.0
			EndIf
			SetColor 255,255,255
		Next

		SetBlend ALPHABLEND
	End Method


	Method DrawFloorDoors()
		local parentY:int = GetScreenY()
		if parent then parentY = parent.GetScreenY()
		
		'draw inner (BG) => elevatorBG without image -> black
		SetColor 0,0,0
		DrawRect(GetScreenX(), Max(parentY, 0) , 44, 385)
		SetColor 255, 255, 255
		spriteInner.Draw(GetScreenX(), GetScreenY() + 3.0)

		'Draw Figures
		If Not passengers.IsEmpty()
			For Local passenger:TFigureBase = EachIn passengers
				passenger.Draw()
				passenger.alreadydrawn = 1
			Next
		Endif

		'Draw (elevator-)doors on all floors (except the current one)
		For Local i:Int = 0 To 13
			Local locy:Int = parentY + TBuildingBase.GetFloorY2(i) - door.sprite.area.GetH()
			If locy < 410 And locy > - 50 And i <> CurrentFloor
				door.RenderAt(GetScreenX(), locy, "closed")
			Endif
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return elevator instance
Function GetElevator:TElevator()
	Return TElevator.GetInstance()
End Function




Type TElevatorRouteLogic
	Method CreateFloorRoute:TFloorRoute(floornumber:Int, call:Int=0, who:TFigureBase=null) abstract
	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigureBase) abstract
	Method RemoveRouteOfPlayer(currentRoute:TFloorRoute) abstract
	Method IsAllowedToEnterToElevator:int(figure:TFigureBase, myTargetFloor:int=-1) abstract
	Method CalculateNextTarget:int() abstract
	Method BoardingDone() abstract
	Method GetSortedRouteList:TList() abstract
End Type




Type TFloorRoute
	Field elevator:TElevator
	Field floornumber:Int
	Field call:Int
	Field who:TFigureBase


	Function Create:TFloorRoute(elevator:TElevator, floornumber:Int, call:Int=0, who:TFigureBase=null)
		Local floorRoute:TFloorRoute = New TFloorRoute
		floorRoute.elevator = elevator
		floorRoute.floornumber = floornumber
		floorRoute.call = call
		floorRoute.who = who
		Return floorRoute
	End Function


	Method ToString:string()
		Return "TFloorRoute"
	End Method
End Type




'###############################################################
'Hier beginnt die konkrete Implementierung der TElevatorSmartLogic


Type TElevatorSmartLogic Extends TElevatorRouteLogic
	'Die Referenz zum Fahrstuhl
	Field Elevator:TElevator
	'Die temporäre RouteList. Sie ist so lange aktuell, bis sich etwas
	'an FloorRouteList ändert, dann wird TemporaryRouteList auf null
	'gesetzt
	Field TemporaryRouteList:TList
	'Das aktuell höchste Stockwerk das es zu erreichen gibt
	Field TopTurningPointForSort:int = -1
	'Das aktuell tiefste Stockwerk das es zu erreichen gibt
	Field BottomTurningPointForSort:int = -1
	'Ist dieser Modus aktiv werden die Spieler durch einen Wechsel der
	'Fahrtrichtung bevorzugt.
	Field PrivilegePlayerMode:int = False


	Function Create:TElevatorSmartLogic(elevator:TElevator, privilegePlayerMode:int)
		local strategy:TElevatorSmartLogic = new TElevatorSmartLogic
		strategy.Elevator = elevator
		strategy.PrivilegePlayerMode = privilegePlayerMode
		Return strategy
	End Function


	'===== Externe Methoden =====

	Method CreateFloorRoute:TFloorRoute(floornumber:Int, call:Int=0, who:TFigureBase=null)
		Return TSmartFloorRoute.Create(Elevator, floornumber, call, who)
	End Method


	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigureBase)
		'Das null-setzten zwingt die Routenberechnung zur Aktualisierung
		TemporaryRouteList = null
	End Method


	Method RemoveRouteOfPlayer(currentRoute:TFloorRoute)
		If TemporaryRouteList <> null Then TemporaryRouteList.remove(currentRoute)
	End Method


	Method IsAllowedToEnterToElevator:int(figure:TFigureBase, myTargetFloor:int=-1)
		'Man darf auch einsteigen wenn man eigentlich in ne andere
		'Richtung wollte... ist der Parameter aber dabei, dann wird geprüft
		If myTargetFloor = -1 Then Return True
		local e:TElevator = Elevator
		'Ron: We only check direction if we are on a route. This allows
		'     entering a stopped elevator which targets another direction
		if Elevator.FloorRouteList.count()=0 then return TRUE
		'temporaryRouteList gets emptied on route change... so better
		'use floorroutelist
		'if not TemporaryRouteList or TemporaryRouteList.count()=0 then return TRUE

		If e.Direction = CalcDirection(e.CurrentFloor, myTargetFloor) then return TRUE
		If e.CurrentFloor = TopTurningPointForSort And e.Direction = 1 then return TRUE
		if e.CurrentFloor = BottomTurningPointForSort And e.Direction = -1 then return TRUE

		Return False
	End Method


	Method BoardingDone()
		'Das null-setzten zwingt die Routenberechnung zur Aktualisierung
		TemporaryRouteList = null
	End Method


	Method GetSortedRouteList:TList()
		Return TemporaryRouteList
	End Method


	Method CalculateNextTarget:int()
		'Die Berechnung der Reihenfolge finden nur dann statt, wenn
		'TemporaryRouteList auf null gesetzt wird. Dies ist dann der
		'Fall, wenn es eine neue Route gibt.
		if TemporaryRouteList = null
			Local startDirection:int = Elevator.Direction

			'Berechnet das aktuell höchste und tiefste Stockwerk und
			'schreibt dies in TopTuringPointForSort und
			'BottomTuringPointForSort
			CalcBottomAndTopTurningPoint()
			'Das oberste und unterste Stockwerk legen fest ob ein
			'Richtungswechsel ansteht... das zu wissen ist für die
			'aktuelle Berechnung
			FixDirection()
			'Berechnet die Sortiernummer neu
			CalcSortNumbers()

			'TODO: Eventuell auf einen Modus Spieler + KI erweitern...
			'      so das nur die Boten und der Hausmeister benachteiligt
			'      werden.
			If PrivilegePlayerMode
				'Während dem fahren darf man die Richtung dann aber doch
				'nicht ändern... erst bei der nächsten Station erhält
				'man den Vorteil
				If Elevator.ElevatorStatus <> 2
					'Neue Richtung bestimmen bzw. alte bestätigen... um
					'den Spieler zu bevorzugen
					Elevator.Direction = GetPlayerPreferenceDirection()
					'Für diesen Modus muss FixDirection und
					'CalcSortNumbers nochmal ausgeführt werden wenn sich
					'die Direction geändert hat
					if startDirection <> Elevator.Direction
						FixDirection()
						CalcSortNumbers()
					Endif
				Endif
			Endif

			'Die Sortierung ausführen (anhand der Sortiernummer)
			local tempList:TList = Elevator.FloorRouteList.Copy()
			SortList(tempList, True, DefaultRouteSort)
			TemporaryRouteList = tempList
		Endif

		'Den ersten Eintrag zurückgeben oder das aktuelle Stockwert wenn
		'nichts gefunden wurde
		Local nextTarget:TFloorRoute = TFloorRoute(TemporaryRouteList.First())
		If nextTarget <> null
			Return nextTarget.floornumber
		Else
			Return Elevator.TargetFloor
		Endif
	End Method


	'===== Hilfsmethoden =====

	Method CalcBottomAndTopTurningPoint()
		TopTurningPointForSort= -1;
		BottomTurningPointForSort= 20;

		For Local route:TSmartFloorRoute = EachIn Elevator.FloorRouteList
			If route.floornumber < BottomTurningPointForSort Then BottomTurningPointForSort = route.floornumber
			If route.floornumber > TopTurningPointForSort Then TopTurningPointForSort = route.floornumber
		Next
	End Method
	

	Method FixDirection()
		'Das oberste und unterste Stockwerk legen fest ob ein
		'Richtungswechsel ansteht... das zu wissen ist für die aktuelle
		'Berechnung
		If Elevator.CurrentFloor >= TopTurningPointForSort Then Elevator.Direction = -1
		If Elevator.CurrentFloor <= BottomTurningPointForSort Then Elevator.Direction = 1
	End Method
	

	Method CalcSortNumbers()
		For Local route:TSmartFloorRoute = EachIn Elevator.FloorRouteList
			route.CalcSortNumber()
		Next
	End Method


	Method CalcDirection:int(fromFloor:int, toFloor:int)
		If fromFloor = toFloor Then Return 0
		If fromFloor < toFloor Then Return 1 Else Return -1
	End Method


	Function GetRouteIndexOfFigure:int(figure:TFigureBase)
		local index:int = 0
		For Local route:TFloorRoute = EachIn GetElevator().FloorRouteList
			If route.who = figure Then Return index
		Next
		Return -1
	End Function
	

	'Sortiert die Liste nach aktiven Spielern und deren
	'Klickreihenfolge... und dann nach deren Sortiernummer
	Method GetPlayerPreferenceDirection:int()
		local tempList:TList = Elevator.FloorRouteList.Copy()
		If Not tempList.IsEmpty()
			SortList(tempList, True, PlayerPreferenceRouteSort)
			local currRoute:TFloorRoute = TFloorRoute(tempList.First())
			if currRoute <> null
				If currRoute.who.IsActivePlayer()
					local target:int = currRoute.floornumber

					If Elevator.CurrentFloor = target
						Return Elevator.Direction
					ElseIf Elevator.CurrentFloor < target
						Return 1
					Else
						Return -1
					Endif
				Endif
			Endif
		Endif
		Return Elevator.Direction
	End Method


	'===== Sortiermethoden =====

	Function DefaultRouteSort:Int( o1:Object, o2:Object )
		Return TSmartFloorRoute(o1).SortNumber - TSmartFloorRoute(o2).SortNumber
	End Function
	

	Function PlayerPreferenceRouteSort:Int( o1:Object, o2:Object )
		local route1:TSmartFloorRoute = TSmartFloorRoute(o1)
		local route2:TSmartFloorRoute = TSmartFloorRoute(o2)
		If route1.who.IsActivePlayer()
			If route2.who.IsActivePlayer()
				Return GetRouteIndexOfFigure(route1.who) - GetRouteIndexOfFigure(route2.who)
			Else
				Return -1
			Endif
		Else
			If route2.who.IsActivePlayer()
				Return 1
			Endif
		Endif

		Return route1.CalcSortNumber() - route2.CalcSortNumber()
	End Function
End Type




'Diese Klasse ist eine Erweiterung von TFloorRoute um die Sortiernummer
'besser zu berechnen.
'TODO: Später kann vielleicht auch TElevatorSmartLogic diese
'Sortiernummer berechnen... dann braucht man TSmartFloorRoute nicht
'mehr, wenn TFloorRoute dafür die reine Nummer bekommt.
Type TSmartFloorRoute Extends TFloorRoute
	Field SortNumber:Int = -1


	Function Create:TSmartFloorRoute(elevator:TElevator, floornumber:Int, call:Int=0, who:TFigureBase=null)
		Local floorRoute:TSmartFloorRoute = New TSmartFloorRoute
		floorRoute.elevator = elevator
		floorRoute.floornumber = floornumber
		floorRoute.call = call
		floorRoute.who = who
		Return floorRoute
	End Function


	Method GetSmartLogic:TElevatorSmartLogic()
		Return TElevatorSmartLogic(elevator.RouteLogic)
	End Method
	

	Method IntendedFollowingTarget:int()
		if who.GetTarget()
			Return who.getFloor(who.GetTargetMoveToPosition())
		else
			Return who.getFloor(new TVec2D.Init())
		endif
	End Method
	

	Method IntendedDirection:int()
		If call = 1
			If floornumber < IntendedFollowingTarget() Then Return 1 Else Return -1
		Endif
		Return 0
	End Method


	'Berechnet eine Nummer für die Gewichtung die dann sortiert werden
	'kann.
	Method CalcSortNumber()
		local currentPathTarget:int = 0, returnPathTarget:int = 0
		sortNumber = 0

		If elevator.Direction = 1
			currentPathTarget = GetSmartLogic().TopTurningPointForSort
			returnPathTarget = GetSmartLogic().BottomTurningPointForSort
		else
			currentPathTarget = GetSmartLogic().BottomTurningPointForSort
			returnPathTarget = GetSmartLogic().TopTurningPointForSort
		endif

		'Hinweg
		sortNumber = sortNumber + CalcSortNumberForPath( elevator.CurrentFloor, currentPathTarget, 10000, 20000)
		'nur auf dem Rückweg zu bekommen
		If ( sortNumber >= 20000 )
			sortNumber = sortNumber + CalcSortNumberForPath( currentPathTarget, returnPathTarget , 30000, 40000 )
			'Hat zu spät gecalled für die Fahrt in diese Richtung. Liegt
			'hinter der Fahrtrichtung
			If ( sortNumber >= 60000 )
				sortNumber = sortNumber + GetDistance( returnPathTarget , elevator.CurrentFloor ) * 100
			Endif
		Endif

		'Zur konstanteren Sortierung... kann man eventuell auch weglassen
		sortNumber = sortNumber + GetDistance( floornumber, IntendedFollowingTarget() );
	End Method
	

	Method IsAcceptableForPath:int(fromFloor:int, toFloor:int)
		local direction:int = GetDirectionOf(fromFloor, toFloor)

		If direction = 1 'nach oben
			If Not (floornumber >= fromFloor And floornumber <= toFloor) Then Return False
		Else
			If Not (floornumber <= fromFloor And floornumber >= toFloor) Then Return False
		Endif

		'Ist die geplante Fahrtrichtung korrekt?
		If call And direction <> IntendedDirection() Then Return False

		Return True
	End Method
	

	Method GetDirectionOf:int(fromFloor:int, toFloor:int)
		If fromFloor = toFloor Then Return 0
		If fromFloor < toFloor Then Return 1 Else Return -1
	End Method
	

	Method GetDistance:int( value1:int, value2:int)
		If value1 = value2
			Return 0
		Elseif value1 > value2
			Return value1 - value2
		Else
			Return value2 - value1
		Endif
	End Method
	

	Method CalcSortNumberForPath:int(fromFloor:int, toFloor:int, turningPointPenalty:int, notInPathPenalty:int)
		If IsAcceptableForPath(fromFloor, toFloor)
			Return GetDistance( fromFloor, floornumber ) * 100
		'Stehe am Wendepunkt des Fahrstuhls und passe sonst in keine
		'Kategorie
		Elseif floornumber = toFloor
			Return turningPointPenalty + GetDistance( fromFloor, floornumber ) * 100
		Else
			Return notInPathPenalty
		Endif
	End Method


	Method ToString:string()
		If call = 1
			Return " C   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		Else
			Return " S   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		Endif
	End Method
End Type




Type TElevatorSoundSource Extends TSoundSourceElement
	Field Movable:Int = True
	Global _instance:TElevatorSoundSource


	Function Create:TElevatorSoundSource(_movable:Int)
		Local result:TElevatorSoundSource  = New TElevatorSoundSource
		result.Movable = ­_movable

		result.AddDynamicSfxChannel("Main")
		result.AddDynamicSfxChannel("Door")

		'there is only ONE elevator - so ignore "ID" in the GUID
		result.SetGUID("elevatorsoundsource")

		Return result
	End Function


	Function GetInstance:TElevatorSoundSource()
		if not _instance then _instance = TElevatorSoundSource.Create(true)
		return _instance
	End Function


	Method GetClassIdentifier:String()
		Return "Elevator"
	End Method


	Method GetCenter:TVec3D()
		Return GetElevator().GetElevatorCenterPos()
	End Method


	Method IsMovable:Int()
		Return ­Movable
	End Method


	Method GetIsHearable:Int()
		Return GetPlayerBase().GetFigure().IsInBuilding()
	End Method


	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Select sfx
			Case "elevator_door_open"
				Return GetSfxChannelByName("Door")
			Case "elevator_door_close"
				Return GetSfxChannelByName("Door")
			Case "elevator_engine"
				Return GetSfxChannelByName("Main")
		EndSelect
	End Method
	

	Method GetSfxSettings:TSfxSettings(sfx:String)
		Select sfx
			Case "elevator_door_open"
				Return GetDoorOptions()
			Case "elevator_door_close"
				Return GetDoorOptions()
			Case "elevator_engine"
				Return GetEngineOptions()
		EndSelect
	End Method


	Method OnPlaySfx:Int(sfx:String)
		Select sfx
			Case "elevator_door_open"
				GetChannelForSfx("elevator_engine").stop()
		EndSelect

		Return True
	End Method


	Method GetDoorOptions:TSfxSettings()
		Local result:TSfxSettings = New TSfxFloorSoundBarrierSettings
		result.nearbyDistanceRange = 50
		result.maxDistanceRange = 500
		result.nearbyRangeVolume = 1
		result.midRangeVolume = 0.5
		result.minVolume = 0
		Return result
	End Method


	Method GetEngineOptions:TSfxSettings()
		Local result:TSfxSettings = New TSfxSettings
		result.nearbyDistanceRange = 0
		result.maxDistanceRange = 500
		result.nearbyRangeVolume = 0.5
		result.midRangeVolume = 0.25
		result.minVolume = 0.05
		Return result
	End Method
End Type