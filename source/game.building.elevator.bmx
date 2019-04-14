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
Import "Dig/base.sfx.soundmanager.base.bmx"
'Import "game.figure.base.bmx"
Import "game.player.base.bmx" 'includes figureBase too
Import "game.building.base.bmx"
Import "game.building.base.sfx.bmx" 'for floorbarriersettings
Import "game.gamerules.bmx"



Type TElevator Extends TEntity
	'=== Referenzen ===
	'Alle aktuellen Passagiere als GUID->TFigure
	Field Passengers:TMap = CreateMap()
	Field RouteLogic:TElevatorRouteLogic = Null
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
	Field WaitAtFloorTimer:TBuildingIntervalTimer = null
	'Der Fahrstuhl wartet so lange, bis diese Zeit erreicht ist (in
	'Millisekunden - basierend auf BuildingTime.GetTimeGone() + waitAtFloorTime)
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
	'welcher Figur(GUID)

	Field PassengerPosition:String[]


	'globals are not saved
	Global _soundSource:TSoundSourceElement
	Global _initDone:Int = False
	Global _instance:TElevator

	Const DOOR_CLOSED:int = 0
	Const DOOR_OPEN:int = 1
	Const DOOR_OPENING:int = 2
	Const DOOR_CLOSING:int = 3
	Const ELEVATOR_AWAITING_TASK:int = 0
	Const ELEVATOR_CLOSING_DOOR:int = 1
	Const ELEVATOR_MOVING:int = 2
	Const ELEVATOR_OPENING_DOOR:int = 3
	Const ELEVATOR_BOARDING:int = 4


	'===== Konstruktor, Speichern, Laden =====
	Function GetInstance:TElevator()
		If Not _instance Then _instance = New TElevator
		Return _instance
	End Function
	

	'override
	'elevator uses building time and not game time
	'Method GetCustomSpeedFactorFunc:Float()()
	'	return GetBuildingTimeTimeFactor
	'End Method

	'until BMX-NG allows for returned function pointers
	Method HasCustomSpeedFactorFunc:int()
		return True
	End Method

	Method RunCustomSpeedFactorFunc:float()
		return TBuildingTime.GetInstance().GetTimeFactor()
	End Method
	

	Method Initialize:TElevator()
		ElevatorStatus = ELEVATOR_AWAITING_TASK
		DoorStatus = DOOR_CLOSED
		CurrentFloor = 8
		TargetFloor = 0
		Direction:Int = 1
		ReadyForBoarding = False
		Speed = GameRules.elevatorSpeed
		WaitAtFloorTime = GameRules.elevatorWaitAtFloorTime

		'adjust animation speed (per frame) 30-100, default 70
		Local animSpeed:Int = GameRules.elevatorAnimSpeed

		'create timer
		WaitAtFloorTimer = new TBuildingIntervalTimer.Init(WaitAtFloorTime)

		'reset floor route list and passengers
		FloorRouteList.Clear()
		Passengers.Clear()
	
		PassengerPosition  = New String[6]
		PassengerOffset    = New TVec2D[6]
		PassengerOffset[0] = New TVec2D.Init(0, 0)
		PassengerOffset[1] = New TVec2D.Init(-13, 0)
		PassengerOffset[2] = New TVec2D.Init(12, 0)
		PassengerOffset[3] = New TVec2D.Init(-7, 0)
		PassengerOffset[4] = New TVec2D.Init(8, 0)
		PassengerOffset[5] = New TVec2D.Init(-3, 0)

		'create door
		door = New TSpriteEntity
		door.SetSprite(GetSpriteFromRegistry("gfx_building_Fahrstuhl_oeffnend"))
		door.GetFrameAnimations().Set(TSpriteFrameAnimation.Create("default", [ [0,70] ], 0, 0) )
		door.GetFrameAnimations().Set(TSpriteFrameAnimation.Create("closed", [ [0,70] ], 0, 0) )
		door.GetFrameAnimations().Set(TSpriteFrameAnimation.Create("open", [ [7,70] ], 0, 0) )
		door.GetFrameAnimations().Set(TSpriteFrameAnimation.Create("opendoor", [ [0,animSpeed],[1,animSpeed],[2,animSpeed],[3,animSpeed],[4,animSpeed],[5,animSpeed],[6,animSpeed],[7,animSpeed] ], 0, 1) )
		door.GetFrameAnimations().Set(TSpriteFrameAnimation.Create("closedoor", [ [7,animSpeed],[6,animSpeed],[5,animSpeed],[4,animSpeed],[3,animSpeed],[2,animSpeed],[1,animSpeed],[0,animSpeed] ], 0, 1) )

		InitSprites()

		door.GetFrameAnimations().SetCurrent("open")
		doorStatus = DOOR_OPEN 'open
		ElevatorStatus	= 0

		If Not _initDone
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			_initDone = True
		EndIf

		Return Self
	End Method


	'run when loading finished
	Function onSaveGameLoad:int(triggerEvent:TEventBase)
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
		Return TElevatorSoundSource.GetInstance()
	End Method


	'===== Öffentliche Methoden damit die Figuren den Fahrstuhl steuern können =====

	Method CallElevator(figure:TFigureBase)
		AddFloorRoute(figure.GetFloor(), 1, figure)
	End Method


	Method SendElevator(targetFloor:Int, figure:TFigureBase)
		AddFloorRoute(targetFloor, 0, figure)
	End Method


	Method EnterTheElevator:Int(figure:TFigureBase, myTargetFloor:Int=-1) 'bzw. einsteigen
		If Not IsAllowedToEnterToElevator(figure, myTargetFloor) Then Return False

		if AddPassenger(figure)
			figure.boardingState = 0
			return true
		else
			return false
		endif
	End Method


	'aussteigen
	Method LeaveTheElevator:Int(figure:TFigureBase)
		if RemovePassenger(figure)
			figure.boardingState = 0
			return true
		else
			return false
		endif
	End Method


	'===== Externe Hilfsmethoden fÃ¼r Figuren =====

	Method IsFigureInFrontOfDoor:Int(figure:TFigureBase)
		Return (GetDoorCenterX() = figure.area.getX())
	End Method


	Method GetDoorCenterX:Int()
		Return area.GetX() + GetDoorWidth()/2
	End Method
	

	Method GetDoorWidth:Int()
		if not door then return 0
		Return door.sprite.framew
	End Method


	Method GetInnerHeight:int()
		if not spriteInner then return 0
		Return spriteInner.area.GetH()
	End Method

	'===== Hilfsmethoden =====

	Method AddPassenger:Int(figure:TFigureBase)
		If Passengers.Contains(figure.GetGUID()) Then Return False

		Passengers.Insert(figure.GetGUID(), figure)
		SetFigureOffset(figure)
		RemoveRouteOfPlayer(figure, 1) 'Call-Route entfernen
		Return True
	End Method


	Method RemovePassenger:Int(figure:TFigureBase)
		'Das Offset auf jeden Fall zurÃ¼cksetzen
		RemoveFigureOffset(figure)
		'Send-Route entfernen
		RemoveRouteOfPlayer(figure, 0)
		'Aus der Passagierliste entfernen
		Passengers.remove(figure.GetGUID())
	End Method
	

	Method HasPassenger:Int(figure:TFigureBase)
		Return passengers.Contains(figure.GetGUID())
	End Method


	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigureBase)
		'PrÃ¼fe auf Duplikate
		If Not ElevatorCallIsDuplicate(floornumber, who)
			FloorRouteList.AddLast(RouteLogic.CreateFloorRoute(floornumber, call, who))
			RouteLogic.AddFloorRoute(floornumber, call, who)
		EndIf
	End Method
	

	Method RemoveRouteOfPlayer(figure:TFigureBase, call:Int)
		RemoveRoute(GetRouteByPassenger(figure, call))
	End Method


	Method RemoveRoute(route:TFloorRoute)
		If (route <> Null)
			FloorRouteList.remove(route)
			RouteLogic.RemoveRouteOfPlayer(route)
		EndIf
	End Method
	

	'Entfernt alle (Call-)Routen die nicht wahrgenommen wurden
	Method RemoveIgnoredRoutes()
		'traverse along a list copy to avoid concurrent modification
		For Local route:TFloorRoute = EachIn FloorRouteList.Copy()
			If route.floornumber = CurrentFloor And route.call = 1
				If HasPassenger(route.who)

					'Diesen Fehler lassen... er zeigt das noch ein
					'Programmierfehler vorliegt der sonst "verschluckt"
					'werden wÃ¼rde
					Throw "Logic-Exception: Person is in passengers-list, but the call-task still exists."
				Else
					RemoveRoute(route)
				EndIf
			EndIf
		Next
	End Method
	

	Method IsAllowedToEnterToElevator:Int(figure:TFigureBase, myTargetFloor:Int=-1)
		Return RouteLogic.IsAllowedToEnterToElevator(figure, myTargetFloor)
	End Method
	

	Method ElevatorCallIsDuplicate:Int(floornumber:Int, who:TFigureBase)
		For Local DupeRoute:TFloorRoute = EachIn FloorRouteList
			If DupeRoute.who.id = who.id And DupeRoute.floornumber = floornumber Then Return True
		Next
		Return False
	End Method
	

	Method GetRouteByPassenger:TFloorRoute(passenger:TFigureBase, isCallRoute:Int)
		For Local route:TFloorRoute = EachIn FloorRouteList
			If route.who = passenger And route.call = isCallRoute Then Return route
		Next
		Return Null
	End Method


	Method CalculateNextTarget:Int()
		Return RouteLogic.CalculateNextTarget()
	End Method
	

	Method GetElevatorCenterPos:TVec3D()
		'-25 = z-Achse fuer Audio. Der Fahrstuhl liegt etwas im Hintergrund
		If parent
			Return New TVec3D.Init(parent.area.GetX() + area.GetX() + door.sprite.framew/2, area.GetY() + door.sprite.frameh/2 + 56, -25)
		Else
			Return New TVec3D.Init(area.GetX() + door.sprite.framew/2, area.GetY() + door.sprite.frameh/2 + 56, -25)
		EndIf
	End Method


	'===== Offset-Funktionen =====

	Method SetFigureOffset:Int(figure:TFigureBase)
		For Local i:Int = 0 Until Len(PassengerOffset)
			'skip occupied slots
			If PassengerPosition[i] <> "" Then Continue

			PassengerPosition[i] = figure.GetGUID()
			Return i
		Next
		Return -1
	End Method


	Method RemoveFigureOffset:Int(figure:TFigureBase)
		Local offset:Int = -1
		For Local i:Int = 0 Until Len(PassengerOffset)
			'skip other passengers
			If PassengerPosition[i] <> figure.GetGUID() Then Continue

			PassengerPosition[i] = ""
			offset = i
			Exit
		Next
		figure.PosOffset.SetXY(0, 0)
		Return offset
	End Method


	Method HasDeboardingPassengers:Int()
		For Local i:Int = 0 To Len(PassengerPosition) - 1
			Local figureGUID:String = PassengerPosition[i]
			If Not figureGUID Then Continue

			Local figure:TFigureBase = GetFigureBaseCollection().GetByGUID(figureGUID)
			If Not figure Then Continue

			If figure.boardingState = -1 Then Return True
		Next
		Return False
	End Method


	'checks if figure wants to deboard, but boardingState is bugged
	'in that case it corrects the boardingState
	Method FixDeboardingPassengers:Int()
		Local fixedSomething:Int = False
		For Local i:Int = 0 To Len(PassengerPosition) - 1
			Local figureGUID:String = PassengerPosition[i]
			If Not figureGUID Then Continue

			Local figure:TFigureBase = GetFigureBaseCollection().GetByGUID(figureGUID)
			If Not figure Then Continue

			'skip correctly deboarding figures
			If figure.boardingState = -1 Then Continue

			'fetch "send" route ... if existing
			Local route:TFloorRoute = GetRouteByPassenger(figure, 0)

			if not route
				TLogger.Log("FixDeboardingPassengers", "Figure "+figure.name+" ("+figure.GetGUID()+") has no route!", LOG_ERROR)
				figure.boardingState = -1
				fixedsomething = true
			endif
			
			'-> elevator on same floor
			If route And route.floornumber = CurrentFloor
				TLogger.Log("FixDeboardingPassengers", "Figure "+figure.name+" ("+figure.GetGUID()+") had borked boarding state. Fixed!", LOG_DEBUG)
				'fix boarding state -> set to deboarding
				figure.boardingState = -1
				fixedSomething = True
			EndIf
		Next
		Return fixedSomething
	End Method


	'Aktualisiert das Offset und bewegt die Figur an die richtige Position
	Method MovePassengerToPosition()
		Local deltaTime:Float = GetDeltaTime()

		For Local i:Int = 0 To Len(PassengerPosition) - 1
			Local figureGUID:String = PassengerPosition[i]
			If Not figureGUID Then Continue

			Local figure:TFigureBase = GetFigureBaseCollection().GetByGUID(figureGUID)
			If Not figure Then Continue
			'ignore _deboarding_ ones
			if figure.boardingState = -1 then continue

			'move with 50% of normal movement speed
			Local moveX:Float = 0.5 * figure.initialDX * deltaTime

			If figure.PosOffset.getIntX() <> PassengerOffset[i].getIntX()
				'set to 1 -> indicator we are moving in the elevator (boarding)
				figure.boardingState = 1

				'avoid rounding errors ("jittering") and set to target
				'if distance is smaller than movement
				'we only do that if offsets differ to avoid doing it if
				'no offset is set
				If Abs(figure.PosOffset.getX() - PassengerOffset[i].getX()) <= moveX
					'set x to the target so it settles to that value
					figure.PosOffset.setX( PassengerOffset[i].getX())
				Else
					If figure.PosOffset.getX() > PassengerOffset[i].getX()
						figure.PosOffset.AddX( -moveX )
					Else
						figure.PosOffset.AddX( +moveX )
					EndIf
				EndIf
			EndIf

			'unset boarding state in all cases - to avoid keeping
			'"boarding" when loading a savegame
			if figure.boardingState <> 0
				If figure.PosOffset.getIntX() = PassengerOffset[i].getIntX()
					figure.boardingState = 0
				EndIf
			endif
		Next
	End Method


	'Aktualisiert das Offset und bewegt die Figur zum Ausgang
	Method MoveDeboardingPassengersToCenter:int(useFloor:int = -1, limitSimultanoeusDeboardingPersonsTo:int=-1)
		if useFloor = -1 then useFloor = CurrentFloor

		Local deltaTime:Float = GetDeltaTime()
		local deboardingPersons:int = 0
	
		For Local i:Int = 0 To Len(PassengerPosition) - 1
			Local figureGUID:String = PassengerPosition[i]
			If Not figureGUID Then Continue

			Local figure:TFigureBase = GetFigureBaseCollection().GetByGUID(figureGUID)
			If Not figure Then Continue
			'ignore _boarding_ ones
			if figure.boardingState = 1 then continue

			'move with 75% of normal movement speed
			Local moveX:Float = 0.75 * figure.initialDX * deltaTime


			Local route:TFloorRoute = GetRouteByPassenger(figure, 0)
			'Will die Person aussteigen?
			'-> elevator on same floor and route is a "SEND"-route
			If route And route.floornumber = useFloor And route.call = 0 
				If figure.PosOffset.getIntX() <> 0
					local reachedPos:int = False
					
					'set state to -1 -> indicator we are moving in the
					'elevator but from Offset to 0 (different to boarding)
					figure.boardingState = -1

					'avoid rounding errors ("jittering") and set to
					'target if movement will reach target (or reached)
					If (Abs(figure.PosOffset.getX()) - moveX) < 0
'						print "reachedCenter " + figure.name
						reachedPos = True
					Else
'						print "moveToCenter " + figure.name
						If figure.PosOffset.getIntX() > 0
							figure.PosOffset.AddX( -moveX )
							if figure.PosOffset.getIntX() <= 0 then reachedPos = True
						Else
							figure.PosOffset.AddX( +moveX )
							if figure.PosOffset.getIntX() >= 0 then reachedPos = True
						EndIf
					EndIf

					'set x to 0 so it settles to that value
					if reachedPos
						figure.PosOffset.setX( 0 )
					'at least one passenger is deboarding
					else
						deboardingPersons :+ 1
						'only deboard x persons per turn?
						if limitSimultanoeusDeboardingPersonsTo <> -1 and deboardingPersons >= limitSimultanoeusDeboardingPersonsTo
							return deboardingPersons
						endif
					endif
				EndIf

				'leave if door open and figure on its way
				If doorStatus = DOOR_OPEN and figure.PosOffset.getIntX() = 0
					'print "DEBOARDING: LEAVE figure: "+ figure.name+ "  offset: "+figure.PosOffset.getX()
					'set state to 0 so figures can recognize they
					'reached the displaced x
					figure.boardingState = 0
					'manually call leaving because figure only calls
					'if they have no target
					LeaveTheElevator(figure)
				EndIf
			EndIf
		Next
	End Method


	'===== Fahrstuhl steuern =====

	Method OpenDoor()
		if not GetBuildingTime().TooFastForSound()
			GetSoundSource().PlayRandomSfx("elevator_door_open")
		endif
		door.GetFrameAnimations().SetCurrent("opendoor", True)
		DoorStatus = DOOR_OPENING
	End Method


	Method CloseDoor()
		if not GetBuildingTime().TooFastForSound()
			GetSoundSource().PlayRandomSfx("elevator_door_close")
		endif
		door.GetFrameAnimations().SetCurrent("closedoor", True)
		DoorStatus = DOOR_CLOSING
	End Method


	Method GetDeltaTime:Float()
		return GetDeltaTimer().GetDelta() * GetBuildingTime().GetTimeFactor()
	End Method


	'===== Aktualisierungs-Methoden =====

	Method Update:Int()
		Local deltaTime:Float = GetDeltaTime()

		'the -1 is used for displace the object one pixel higher, so
		'it has to reach the first pixel of the floor until the
		'function returns the new one, instead of positioning it
		'directly on the floorground
		Local tmpCurrentFloor:Int = GetBuildingBase().GetFloor(int(area.GetY() + GetInnerHeight() - 1))
		Local tmpFloorY:Int = TBuildingBase.GetFloorY2(tmpCurrentFloor)
		Local tmpElevatorBottomY:Int = area.GetY() + GetInnerHeight()

		'direction = -1 => downwards
		'direction = +1 => upwards
		If (direction < 0 And tmpFloorY <= tmpElevatorBottomY) Or ..
		   (direction > 0 And tmpFloorY >= tmpElevatorBottomY)
			CurrentFloor = tmpCurrentFloor
		EndIf


		If ElevatorStatus = ELEVATOR_AWAITING_TASK
			If waitAtFloorTimer.isExpired()
'print Millisecs()+"  Elevator: 0) wait for next Task - expired"
				'fix potentially borked deboarding states
				If FixDeboardingPassengers()
'print Millisecs()+"  Elevator: 0) fixed - delay waiting timer"
					'if there was something to fix - wait a bit more
					waitAtFloorTimer.SetInterval(int(0.5 * waitAtFloorTime), True)
				EndIf
			EndIf

			'do we still have deboarding passengers?
			'-> let them deboard before starting the next route
			local canCloseDoors:int = True
			If HasDeboardingPassengers() 'and not  waitAtFloorTimer.isExpired()
				canCloseDoors = False
'print Millisecs()+"  Elevator: 0) move deboarding"
				if not MoveDeboardingPassengersToCenter(-1, -1) 'no deboarding limit
					canCloseDoors = True
				endif
			endif

			if canCloseDoors
'print Millisecs()+"  Elevator: 0) get next target"
				'get next target on a route
				TargetFloor = CalculateNextTarget()
				'found new target
				If CurrentFloor <> TargetFloor
'print Millisecs()+"  Elevator: 0) new target -> 1)"
					ReadyForBoarding = False
					ElevatorStatus = ELEVATOR_CLOSING_DOOR
				EndIf
			EndIf
		EndIf


		If ElevatorStatus = ELEVATOR_CLOSING_DOOR
'print Millisecs()+"  Elevator: 1) closing door - doorStatus="+doorStatus
			'Wenn die Wartezeit vorbei ist, dann Tueren schliessen
			If doorStatus <> DOOR_CLOSED And doorStatus <> DOOR_CLOSING
				If waitAtFloorTimer.isExpired() Then CloseDoor()
			EndIf

			'wait until door animation finished
			If door.GetFrameAnimations().getCurrentAnimationName() = "closedoor"
				If door.GetFrameAnimations().getCurrent().isFinished()
'print Millisecs()+"  Elevator: 1) closed -> 2)"
					door.GetFrameAnimations().SetCurrent("closed")
					doorStatus = DOOR_CLOSED
					ElevatorStatus = ELEVATOR_MOVING
					GetSoundSource().PlayOrContinueRandomSFX("elevator_engine")
				EndIf
			EndIf
		EndIf


		If ElevatorStatus = ELEVATOR_MOVING
'print Millisecs()+"  Elevator: 2) moving"
			'Check again if there is a new target which can get a lift
			'on this route
			TargetFloor = CalculateNextTarget()


			'has the elevator arrived but the doors are still closed?
			'open them!
			If CurrentFloor = TargetFloor
'print Millisecs()+"  Elevator: 2) reached floor -> 3)"
				'open doors
				ElevatorStatus = ELEVATOR_OPENING_DOOR
				'Direction = 0
			Else
				'backup for tweening
				oldPosition.SetXY(area.position.x, area.position.y)

				If (CurrentFloor < TargetFloor) Then Direction = 1 Else Direction = -1
				'set velocity according (negative) direction
				SetVelocity(0, -Direction * Speed)

				'set new position
				area.position.AddXY( deltaTime * GetVelocity().x, deltaTime * GetVelocity().y )


				'do not move further than the target floor
				Local tmpTargetFloorY:Int = TBuildingBase.GetFloorY2(TargetFloor) - GetInnerHeight()
				
				If (direction < 0 And area.GetY() > tmpTargetFloorY) Or ..
				   (direction > 0 And area.GetY() < tmpTargetFloorY)
					area.position.y = tmpTargetFloorY
				EndIf

				'move figures in elevator together with the inner part
				For Local figure:TFigureBase = EachIn Passengers.Values()
					figure.area.position.setY( area.GetY() + GetInnerHeight())
				Next
			EndIf

			'reaching target soon - begin deboarding movement
			if 5 > Abs(area.GetY() - (TBuildingBase.GetFloorY2(TargetFloor) + GetInnerHeight()))
				',1 = move each passenger one after another, not simultaneously
				MoveDeboardingPassengersToCenter(TargetFloor, 1)
			endif
		EndIf

		If ElevatorStatus = ELEVATOR_OPENING_DOOR
			If doorStatus = DOOR_CLOSED
'print Millisecs()+"  Elevator: 3) open door"
				OpenDoor()
				'set time for the doors to keep open
				'adjust this by worldSpeedFactor at that time
				'so a higher factor shortens time to wait
				waitAtFloorTimer.SetInterval(int(waitAtFloorTime), True)
			EndIf

			'continue door animation for opening doors
			'also deboard passengers as soon as finished
			If door.GetFrameAnimations().getCurrentAnimationName() = "opendoor"
'print Millisecs()+"  Elevator: 3) opening..."
				'while the door animation is active, the deboarding
				'figures will move to the exit/door (one after another)
				MoveDeboardingPassengersToCenter(-1, 1)
				
				If door.GetFrameAnimations().GetCurrent().isFinished()
'print Millisecs()+"  Elevator: 3) opened -> 4)"
					ElevatorStatus = ELEVATOR_BOARDING
					door.GetFrameAnimations().SetCurrent("open")
					doorStatus = DOOR_OPEN
				EndIf
			EndIf
		EndIf

		'(de-)boarding
		If ElevatorStatus = ELEVATOR_BOARDING
'print Millisecs()+"  Elevator: 4) boarding"
			'continue deboarding (if needed)
			MoveDeboardingPassengersToCenter()

			If ReadyForBoarding = False
				ReadyForBoarding = True
			'happens in Else-part so the Update-loop could switch back
			'to the figures again for (de-)boarding
			Else
				'if the waiting time is expired, search a new target
				If waitAtFloorTimer.isExpired()
'print Millisecs()+"  Elevator: 4) timer expired, searching new target -> 0)"
					'remove unused routes
					RemoveIgnoredRoutes()
					'0 = wait for next task
					ElevatorStatus = ELEVATOR_AWAITING_TASK
					RouteLogic.BoardingDone()
				EndIf
			EndIf
		EndIf

		'move passengers to their positions if needed.
		'Of course do not so if de/boarding.
		If ElevatorStatus <> ELEVATOR_OPENING_DOOR
'			print "move"
			MovePassengerToPosition()
		endif

		'animate doors
		door.Update()
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		SetBlend ALPHABLEND

		Local parentY:Int = GetScreenY()
		If parent Then parentY = parent.GetScreenY()

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
			Local locy:Int = parentY + TBuildingBase.GetFloorY2(floorroute.floornumber) - GetInnerHeight() + 26
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
		Local parentY:Int = GetScreenY()
		If parent Then parentY = parent.GetScreenY()
		
		'draw inner (BG) => elevatorBG without image -> black
		SetColor 0,0,0
		DrawRect(GetScreenX(), Max(parentY, 0) , 44, 385)
		SetColor 255, 255, 255
		spriteInner.Draw(GetScreenX(), GetScreenY() + 3.0)

		'Draw Figures
		If Not passengers.IsEmpty()
			For Local passenger:TFigureBase = EachIn Passengers.Values()

				passenger.Draw()
				passenger.alreadydrawn = 1
			Next
		EndIf

		'Draw (elevator-)doors on all floors (except the current one)
		For Local i:Int = 0 To 13
			Local locy:Int = parentY + TBuildingBase.GetFloorY2(i) - door.sprite.area.GetH()
			If locy < 410 And locy > - 50 And i <> CurrentFloor
				door.RenderAnimationAt(GetScreenX(), locy, "closed")
			EndIf
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return elevator instance
Function GetElevator:TElevator()
	Return TElevator.GetInstance()
End Function




Type TElevatorRouteLogic
	Method CreateFloorRoute:TFloorRoute(floornumber:Int, call:Int=0, who:TFigureBase=Null) Abstract
	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigureBase) Abstract
	Method RemoveRouteOfPlayer(currentRoute:TFloorRoute) Abstract
	Method IsAllowedToEnterToElevator:Int(figure:TFigureBase, myTargetFloor:Int=-1) Abstract
	Method CalculateNextTarget:Int() Abstract
	Method BoardingDone() Abstract
	Method GetSortedRouteList:TList() Abstract
End Type




Type TFloorRoute
	Field elevator:TElevator
	Field floornumber:Int
	Field call:Int
	Field who:TFigureBase


	Function Create:TFloorRoute(elevator:TElevator, floornumber:Int, call:Int=0, who:TFigureBase=Null)
		Local floorRoute:TFloorRoute = New TFloorRoute
		floorRoute.elevator = elevator
		floorRoute.floornumber = floornumber
		floorRoute.call = call
		floorRoute.who = who
		Return floorRoute
	End Function


	Method ToString:String()
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
	Field BottomTurningPointForSort:Int = -1
	'Ist dieser Modus aktiv werden die Spieler durch einen Wechsel der
	'Fahrtrichtung bevorzugt.
	Field PrivilegePlayerMode:Int = False


	Function Create:TElevatorSmartLogic(elevator:TElevator, privilegePlayerMode:Int)
		Local strategy:TElevatorSmartLogic = New TElevatorSmartLogic
		strategy.Elevator = elevator
		strategy.PrivilegePlayerMode = privilegePlayerMode
		Return strategy
	End Function


	'===== Externe Methoden =====

	Method CreateFloorRoute:TFloorRoute(floornumber:Int, call:Int=0, who:TFigureBase=Null)
		Return TSmartFloorRoute.Create(Elevator, floornumber, call, who)
	End Method


	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigureBase)
		'Das null-setzten zwingt die Routenberechnung zur Aktualisierung
		TemporaryRouteList = Null
	End Method


	Method RemoveRouteOfPlayer(currentRoute:TFloorRoute)
		If TemporaryRouteList <> Null Then TemporaryRouteList.remove(currentRoute)
	End Method


	Method IsAllowedToEnterToElevator:Int(figure:TFigureBase, myTargetFloor:Int=-1)
		'Man darf auch einsteigen wenn man eigentlich in ne andere
		'Richtung wollte... ist der Parameter aber dabei, dann wird geprÃ¼ft
		If myTargetFloor = -1 Then Return True
		Local e:TElevator = Elevator
		'Ron: We only check direction if we are on a route. This allows
		'     entering a stopped elevator which targets another direction
		If Elevator.FloorRouteList.count()=0 Then Return True
		'temporaryRouteList gets emptied on route change... so better
		'use floorroutelist
		'if not TemporaryRouteList or TemporaryRouteList.count()=0 then return TRUE

		If e.Direction = CalcDirection(e.CurrentFloor, myTargetFloor) Then Return True
		If e.CurrentFloor = TopTurningPointForSort And e.Direction = 1 Then Return True
		If e.CurrentFloor = BottomTurningPointForSort And e.Direction = -1 Then Return True

		Return False
	End Method


	Method BoardingDone()
		'Das null-setzten zwingt die Routenberechnung zur Aktualisierung
		TemporaryRouteList = Null
	End Method


	Method GetSortedRouteList:TList()
		Return TemporaryRouteList
	End Method


	Method CalculateNextTarget:Int()
		'Die Berechnung der Reihenfolge finden nur dann statt, wenn
		'TemporaryRouteList auf null gesetzt wird. Dies ist dann der
		'Fall, wenn es eine neue Route gibt.
		If TemporaryRouteList = Null
			Local startDirection:Int = Elevator.Direction

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
				If Elevator.ElevatorStatus <> TElevator.ELEVATOR_MOVING
					'Neue Richtung bestimmen bzw. alte bestätigen... um
					'den Spieler zu bevorzugen
					Elevator.Direction = GetPlayerPreferenceDirection()
					'Für diesen Modus muss FixDirection und
					'CalcSortNumbers nochmal ausgeführt werden wenn sich
					'die Direction geändert hat
					if startDirection <> Elevator.Direction
						FixDirection()
						CalcSortNumbers()
					EndIf
				EndIf
			EndIf

			'Die Sortierung ausführen (anhand der Sortiernummer)
			local tempList:TList = Elevator.FloorRouteList.Copy()
			SortList(tempList, True, DefaultRouteSort)
			TemporaryRouteList = tempList
		EndIf

		'Den ersten Eintrag zurückgeben oder das aktuelle Stockwert wenn
		'nichts gefunden wurde
		Local nextTarget:TFloorRoute = TFloorRoute(TemporaryRouteList.First())
		If nextTarget <> Null
			Return nextTarget.floornumber
		Else
			Return Elevator.TargetFloor
		EndIf
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
		'Richtungswechsel ansteht... das zu wissen ist fÃ¼r die aktuelle
		'Berechnung
		If Elevator.CurrentFloor >= TopTurningPointForSort Then Elevator.Direction = -1
		If Elevator.CurrentFloor <= BottomTurningPointForSort Then Elevator.Direction = 1
	End Method
	

	Method CalcSortNumbers()
		For Local route:TSmartFloorRoute = EachIn Elevator.FloorRouteList
			route.CalcSortNumber()
		Next
	End Method


	Method CalcDirection:Int(fromFloor:Int, toFloor:Int)
		If fromFloor = toFloor Then Return 0
		If fromFloor < toFloor Then Return 1 Else Return -1
	End Method


	Function GetRouteIndexOfFigure:Int(figure:TFigureBase)
		Local index:Int = 0
		For Local route:TFloorRoute = EachIn GetElevator().FloorRouteList
			If route.who = figure Then Return index
		Next
		Return -1
	End Function
	

	'Sortiert die Liste nach aktiven Spielern und deren
	'Klickreihenfolge... und dann nach deren Sortiernummer
	Method GetPlayerPreferenceDirection:Int()
		Local tempList:TList = Elevator.FloorRouteList.Copy()
		If Not tempList.IsEmpty()
			SortList(tempList, True, PlayerPreferenceRouteSort)
			Local currRoute:TFloorRoute = TFloorRoute(tempList.First())
			If currRoute <> Null
				If currRoute.who = GetPlayerBase().GetFigure()
					Local target:Int = currRoute.floornumber

					If Elevator.CurrentFloor = target
						Return Elevator.Direction
					ElseIf Elevator.CurrentFloor < target
						Return 1
					Else
						Return -1
					EndIf
				EndIf
			EndIf
		EndIf
		Return Elevator.Direction
	End Method


	'===== Sortiermethoden =====

	Function DefaultRouteSort:Int( o1:Object, o2:Object )
		Return TSmartFloorRoute(o1).SortNumber - TSmartFloorRoute(o2).SortNumber
	End Function
	

	Function PlayerPreferenceRouteSort:Int( o1:Object, o2:Object )
		Local route1:TSmartFloorRoute = TSmartFloorRoute(o1)
		Local route2:TSmartFloorRoute = TSmartFloorRoute(o2)
		If route1.who = GetPlayerBase().GetFigure()
			If route2.who = route1.who
				Return GetRouteIndexOfFigure(route1.who) - GetRouteIndexOfFigure(route2.who)
			Else
				Return -1
			EndIf
		Else
			If route2.who = GetPlayerBase().GetFigure()
				Return 1
			EndIf
		EndIf

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


	Function Create:TSmartFloorRoute(elevator:TElevator, floornumber:Int, call:Int=0, who:TFigureBase=Null)
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
	

	Method IntendedFollowingTarget:Int()
		If who.GetTarget()
			Return who.getFloor(who.GetTargetMoveToPosition())
		Else
			Return who.getFloor(New TVec2D.Init())
		EndIf
	End Method
	

	Method IntendedDirection:Int()
		If call = 1
			If floornumber < IntendedFollowingTarget() Then Return 1 Else Return -1
		EndIf
		Return 0
	End Method


	'Berechnet eine Nummer für die Gewichtung die dann sortiert werden
	'kann.
	Method CalcSortNumber:Int()
		Local currentPathTarget:Int = 0, returnPathTarget:Int = 0
		sortNumber = 0

		If elevator.Direction = 1
			currentPathTarget = GetSmartLogic().TopTurningPointForSort
			returnPathTarget = GetSmartLogic().BottomTurningPointForSort
		Else
			currentPathTarget = GetSmartLogic().BottomTurningPointForSort
			returnPathTarget = GetSmartLogic().TopTurningPointForSort
		EndIf

		'Hinweg
		sortNumber = sortNumber + CalcSortNumberForPath( elevator.CurrentFloor, currentPathTarget, 10000, 20000)
		'nur auf dem Rückweg zu bekommen
		If ( sortNumber >= 20000 )
			sortNumber = sortNumber + CalcSortNumberForPath( currentPathTarget, returnPathTarget , 30000, 40000 )
			'Hat zu spät gecalled für die Fahrt in diese Richtung. Liegt
			'hinter der Fahrtrichtung
			If ( sortNumber >= 60000 )
				sortNumber = sortNumber + GetDistance( returnPathTarget , elevator.CurrentFloor ) * 100
			EndIf
		EndIf

		'Zur konstanteren Sortierung... kann man eventuell auch weglassen
		sortNumber = sortNumber + GetDistance( floornumber, IntendedFollowingTarget() );
	End Method
	

	Method IsAcceptableForPath:Int(fromFloor:Int, toFloor:Int)
		Local direction:Int = GetDirectionOf(fromFloor, toFloor)

		If direction = 1 'nach oben
			If Not (floornumber >= fromFloor And floornumber <= toFloor) Then Return False
		Else
			If Not (floornumber <= fromFloor And floornumber >= toFloor) Then Return False
		EndIf

		'Ist die geplante Fahrtrichtung korrekt?
		If call And direction <> IntendedDirection() Then Return False

		Return True
	End Method
	

	Method GetDirectionOf:Int(fromFloor:Int, toFloor:Int)
		If fromFloor = toFloor Then Return 0
		If fromFloor < toFloor Then Return 1 Else Return -1
	End Method
	

	Method GetDistance:Int( value1:Int, value2:Int)
		If value1 = value2
			Return 0
		ElseIf value1 > value2
			Return value1 - value2
		Else
			Return value2 - value1
		EndIf
	End Method
	

	Method CalcSortNumberForPath:Int(fromFloor:Int, toFloor:Int, turningPointPenalty:Int, notInPathPenalty:Int)
		If IsAcceptableForPath(fromFloor, toFloor)
			Return GetDistance( fromFloor, floornumber ) * 100
		'Stehe am Wendepunkt des Fahrstuhls und passe sonst in keine
		'Kategorie
		ElseIf floornumber = toFloor
			Return turningPointPenalty + GetDistance( fromFloor, floornumber ) * 100
		Else
			Return notInPathPenalty
		EndIf
	End Method


	Method ToString:String()
		If call = 1
			Return " C   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		Else
			Return " S   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		EndIf
	End Method
End Type




Type TElevatorSoundSource Extends TSoundSourceElement
	Field Movable:Int = True
	Global _instance:TElevatorSoundSource


	Function Create:TElevatorSoundSource(_movable:Int)
		Local result:TElevatorSoundSource  = New TElevatorSoundSource
		result.Movable = _movable

		result.AddDynamicSfxChannel("Main")
		result.AddDynamicSfxChannel("Door")

		'there is only ONE elevator - so ignore "ID" in the GUID
		result.SetGUID("elevatorsoundsource")

		Return result
	End Function


	Function GetInstance:TElevatorSoundSource()
		If Not _instance Then _instance = TElevatorSoundSource.Create(True)
		Return _instance
	End Function


	Method GetClassIdentifier:String()
		Return "Elevator"
	End Method


	Method GetCenter:TVec3D()
		Return GetElevator().GetElevatorCenterPos()
	End Method


	Method IsMovable:Int()
		Return movable
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