'=== Struktur des Elevators ===
'Ziel der Überarbeitung war es u.a. auch die Lesbarkeit und Aufteilung des Codes zu optimieren.
'Auch die Reduzierung der vielen komplexen Prüfungen sollte erreicht werden... dies wird vor allem durch den Ablauf des "ElevatorStatus" realisiert.

'TElevator: Grundlegende Klasse zur Darstellung und Steuerung des Fahrstuhls. Die Logik der Routensteuerung ist in TElevatorRouteLogic ausgelagert
'TElevatorRouteLogic: Ableitungen dieser abstrakten Klasse können die Logik für die Routenberechnung implementieren
'TFloorRoute: In dieser Klasse werden die Routen-Daten die Calls und Sends des Fahrstuhls abgelegt.

'Die Standard-Logikimplementierung ist "TElevatorSmartStrategy" zu finden. Diese benötigt die Klasse "TSmartFloorRoute" eine Ableitung von 'TFloorRoute

Type TElevator
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
	Field CurrentFloor:Int = 0
	'Hier fährt der Fahrstuhl hin
	Field TargetFloor:Int = 0
	'Aktuelle/letzte Bewegungsrichtung: -1 = nach unten; +1 = nach oben; 0 = gibt es nicht
	Field Direction:Int	= 1
	'während der ElevatorStatus 4, 5 und 0 möglich.
	Field ReadyForBoarding:int = false
	'Aktuelle Position - difference to x/y of building
	Field Pos:TPoint = new TPoint.Init(131 + 230,115)

	'=== EINSTELLUNGEN ===
	'pixels per second ;D
	Field Speed:Float = 120

	'=== TIMER ===
	'Wie lange (Millisekunden) werden die Türen offen gelassen
	'(alt: 650)
	Field WaitAtFloorTimer:TIntervalTimer = null
	'Der Fahrstuhl wartet so lange, bis diese Zeit erreicht ist (in
	'Millisekunden - basierend auf Time.GetTimeGone() + waitAtFloorTime)
	Field WaitAtFloorTime:Int = 1700

	'=== GRAFIKELEMENTE ===
	'Das Türensprite und seine Animationen
	Field door:TSpriteEntity
	'Das Sprite des Innenraums
	Field SpriteInner:TSprite
	'Damit nicht alle auf einem Haufen stehen, gibt es für die Figures
	'ein paar Offsets im Fahrstuhl
	Field PassengerOffset:TPoint[]
	'Hier wird abgelegt, welches Offset schon in Benutzung ist und von
	'welcher Figur
	Field PassengerPosition:TFigure[]

	'globals are not saved
	Global _soundSource:TElevatorSoundSource
	Global _initDone:int = FALSE
	Global _instance:TElevator


	'===== Konstruktor, Speichern, Laden =====
	Function GetInstance:TElevator()
		if not _instance then _instance = new TElevator
		return _instance
	End Function



	Method Init:TElevator()
		'limit speed between 50 - 240 pixels per second, default 120
		Speed = Max(50, Min(240, App.devConfig.GetInt("DEV_ELEVATOR_SPEED", self.speed)))
		'adjust wait at floor time : 1000 - 2000 ms, default 1700
		WaitAtFloorTime = Max(1000, Min(2000, App.devConfig.GetInt("DEV_ELEVATOR_WAITTIME", self.WaitAtFloorTime)))

		'adjust animation speed (per frame) 30-100, default 70
		local animSpeed:int = Max(30, Min(100, App.devConfig.GetInt("DEV_ELEVATOR_ANIMSPEED", 70)))

		'create timer
		WaitAtFloorTimer = TIntervalTimer.Create(WaitAtFloorTime)


		PassengerPosition  = PassengerPosition[..6]
		PassengerOffset    = PassengerOffset[..6]
		PassengerOffset[0] = new TPoint.Init(0, 0)
		PassengerOffset[1] = new TPoint.Init(-12, 0)
		PassengerOffset[2] = new TPoint.Init(-6, 0)
		PassengerOffset[3] = new TPoint.Init(3, 0)
		PassengerOffset[4] = new TPoint.Init(-3, 0)
		PassengerOffset[5] = new TPoint.Init(-8, 0)

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
		TLogger.Log("TElevator", "Savegame loaded - reassigning sprites", LOG_DEBUG | LOG_SAVELOAD)
		'instance holds the object created when loading
		GetInstance().InitSprites()
	End Function


	'should get run as soon as sprites might be invalid (loading, graphics reset)
	Method InitSprites()
		door.SetSprite(GetSpriteFromRegistry("gfx_building_Fahrstuhl_oeffnend"))
		spriteInner	= GetSpriteFromRegistry("gfx_building_Fahrstuhl_Innen")  'gfx_building_elevator_inner
	End Method


	Method GetSoundSource:TElevatorSoundSource()
		if not _soundSource then _soundSource = TElevatorSoundSource.Create(self, true)
		return _soundSource
	End Method


	'===== Öffentliche Methoden damit die Figuren den Fahrstuhl steuern können =====

	Method CallElevator(figure:TFigure)
		AddFloorRoute(figure.GetFloor(), 1, figure)
	End Method

	Method SendElevator(targetFloor:int, figure:TFigure)
		AddFloorRoute(targetFloor, 0, figure)
	End Method

	Method EnterTheElevator:int(figure:TFigure, myTargetFloor:int=-1) 'bzw. einsteigen
		If Not IsAllowedToEnterToElevator(figure, myTargetFloor) Then Return False
		If Not Passengers.Contains(figure)
			Passengers.AddLast(figure)
			SetFigureOffset(figure)
			RemoveRouteOfPlayer(figure, 1) 'Call-Route entfernen
			Return true
		Endif
		Return false
	End Method

	Method LeaveTheElevator(figure:TFigure) 'aussteigen
		RemoveFigureOffset(figure)		'Das Offset auf jeden Fall zurücksetzen
		RemoveRouteOfPlayer(figure, 0)  'Send-Route entfernen
		Passengers.remove(figure)		'Aus der Passagierliste entfernen
	End Method


	'===== Externe Hilfsmethoden für Figuren =====

	Method IsFigureInFrontOfDoor:Int(figure:TFigure)
		Return (GetDoorCenterX() = figure.area.getX())
	End Method

	Method IsFigureInElevator:Int(figure:TFigure)
		Return passengers.Contains(figure)
	End Method

	Method GetDoorCenterX:int()
		Return GetBuilding().area.position.x + Pos.x + door.sprite.framew/2
	End Method

	Method GetDoorWidth:int()
		Return door.sprite.framew
	End Method

	'===== Hilfsmethoden =====

	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigure)
		If Not ElevatorCallIsDuplicate(floornumber, who) Then 'Prüfe auf Duplikate
			FloorRouteList.AddLast(RouteLogic.CreateFloorRoute(floornumber, call, who))
			RouteLogic.AddFloorRoute(floornumber, call, who)
		EndIf
	End Method

	Method RemoveRouteOfPlayer(figure:TFigure, call:int)
		RemoveRoute(GetRouteByPassenger(figure, call))
	End Method

	Method RemoveRoute(route:TFloorRoute)
		if (route <> null)
			FloorRouteList.remove(route)
			RouteLogic.RemoveRouteOfPlayer(route)
		Endif
	End Method

	Method RemoveIgnoredRoutes() 'Entfernt alle (Call-)Routen die nicht wahrgenommen wurden
		For Local route:TFloorRoute = EachIn FloorRouteList
			If route.floornumber = CurrentFloor And route.call = 1
				If Passengers.Contains(route.who)
					throw "Logic-Exception: Person is in passengers-list, but the call-task still exists." 'Diesen Fehler lassen... er zeigt das noch ein Programmierfehler vorliegt der sonst "verschluckt" werden würde
				Else
					RemoveRoute(route)
				Endif
			Endif
		Next
	End Method

	Method IsAllowedToEnterToElevator:int(figure:TFigure, myTargetFloor:int=-1)
		Return RouteLogic.IsAllowedToEnterToElevator(figure, myTargetFloor)
	End Method

	Method ElevatorCallIsDuplicate:Int(floornumber:Int, who:TFigure)
		For Local DupeRoute:TFloorRoute = EachIn FloorRouteList
			If DupeRoute.who.id = who.id And DupeRoute.floornumber = floornumber Then Return True
		Next
		Return False
	End Method

	Method GetRouteByPassenger:TFloorRoute(passenger:TFigure, isCallRoute:int)
		For Local route:TFloorRoute = EachIn FloorRouteList
			If route.who = passenger And route.call = isCallRoute Then Return route
		Next
		Return null
	End Method

	Method CalculateNextTarget:int()
		Return RouteLogic.CalculateNextTarget()
	End Method

	Method GetElevatorCenterPos:TPoint()
		Return new TPoint.Init(GetBuilding().area.position.x + Pos.x + door.sprite.framew/2, Pos.y + door.sprite.frameh/2 + 56, -25) '-25 = z-Achse für Audio. Der Fahrstuhl liegt etwas im Hintergrund
	End Method

	'===== Offset-Funktionen =====

	Method SetFigureOffset(figure:TFigure)
		for local i:int = 0 to len(PassengerOffset) -1
			If PassengerPosition[i] = null Then PassengerPosition[i] = figure; Exit
		next
	End Method

	Method RemoveFigureOffset(figure:TFigure)
		for local i:int = 0 to len(PassengerOffset) -1
			If PassengerPosition[i] = figure Then PassengerPosition[i] = null; Exit
		next
		figure.PosOffset.SetXY(0, 0)
	End Method

	Method MovePassengerToPosition() 'Aktualisiert das Offset und bewegt die Figur an die richtige Position
		for local i:int = 0 to len(PassengerPosition) - 1
			local figure:TFigure = PassengerPosition[i]
			If figure <> null
				local offset:TPoint = PassengerOffset[i]
				If figure.PosOffset.getX() <> offset.getX()
					'set to 1 -> indicator we are moving in the elevator (boarding)
					figure.boardingState = 1

					'avoid rounding errors ("jittering") and set to target if distance is smaller than movement
					'we only do that if offsets differ to avoid doing it if no offset is set
					if abs(figure.PosOffset.getX() - offset.getX()) <= 0.4
						'set x to the target so it settles to that value
						figure.PosOffset.setX( offset.getX())
						'set state to 0 so figures can recognize they reached the displaced x
						figure.boardingState = 0
					else
					if figure.PosOffset.getX() > offset.getX() Then figure.PosOffset.setX(figure.PosOffset.getX() -0.4) Else figure.PosOffset.setX(figure.PosOffset.getX() +0.4)
					endif
				Endif
			Endif
		next
	End Method

	Method MoveDeboardingPassengersToCenter() 'Aktualisiert das Offset und bewegt die Figur zum Ausgang
		for local i:int = 0 to len(PassengerPosition) - 1
			local figure:TFigure = PassengerPosition[i]
			If figure <> null
				If GetRouteByPassenger(figure, 0).floornumber = CurrentFloor 'Will die Person aussteigen?
					If figure.PosOffset.getX() <> 0
						'set state to -1 -> indicator we are moving in the elevator but from Offset to 0 (different to boarding)
						figure.boardingState = -1

						'avoid rounding errors ("jittering") and set to target if distance is smaller than movement
						'we only do that if offsets differ to avoid doing it if no offset is set
						if abs(figure.PosOffset.getX()) <= 0.5
							'set x to 0 so it settles to that value
							'set "y" to 0 so figures can recognize they reached the displaced x
							figure.PosOffset.setX( 0 )
							'set state to 0 so figures can recognize they reached the displaced x
							figure.boardingState = 0
						else
						if figure.PosOffset.getX() > 0 Then figure.PosOffset.setX(figure.PosOffset.getX() -0.5) Else figure.PosOffset.setX(figure.PosOffset.getX() +0.5)
						endif
					Endif
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

	Method Update(deltaTime:Float=1.0)
		'Aktualisierung des current floors - mv: da ich hier nicht durchblicke lass ich's so wie's ist ;)
		If Abs(TBuilding.GetFloorY(GetBuilding().GetFloor(GetBuilding().area.position.y + Pos.y + spriteInner.area.GetH() - 1)) - (Pos.y + spriteInner.area.GetH())) <= 1
			'the -1 is used for displace the object one pixel higher, so it has to reach the first pixel of the floor
			'until the function returns the new one, instead of positioning it directly on the floorground
			CurrentFloor = GetBuilding().GetFloor(GetBuilding().area.position.y + Pos.y + spriteInner.area.GetH() - 1)
		EndIf

		If ElevatorStatus = 0 '0 = warte auf nächsten Auftrag
			TargetFloor = CalculateNextTarget() 'Nächstes Ziel in der Route
			If CurrentFloor <> TargetFloor 'neues Ziel gefunden
				ReadyForBoarding = false
				ElevatorStatus = 1 'Türen schließen
			Endif
		Endif

		If ElevatorStatus = 1 '1 = Türen schließen
			If doorStatus <> 0 And doorStatus <> 3 And waitAtFloorTimer.isExpired() Then CloseDoor() 'Wenn die Wartezeit vorbei ist, dann Türen schließen

			'Warten bis die Türanimation fertig ist
			If door.GetFrameAnimations().getCurrentAnimationName() = "closedoor"
				If door.GetFrameAnimations().getCurrent().isFinished()
					door.GetFrameAnimations().SetCurrent("closed")
					doorStatus = 0 'closed
					ElevatorStatus = 2 '2 = Fahren
					GetSoundSource().PlayRandomSfx("elevator_engine")
				EndIf
			EndIf
		Endif

		If ElevatorStatus = 2 '2 = Fahren
			TargetFloor = CalculateNextTarget() 'Nochmal prüfen ob es vielleicht ein neueres Ziel gibt das unterwegs eingeladen werden muss

			if CurrentFloor = TargetFloor 'Ist der Fahrstuhl da/angekommen, aber die Türen sind noch geschlossen? Dann öffnen!
				ElevatorStatus = 3 'Türen öffnen
'				Direction = 0
			Else
				If (CurrentFloor < TargetFloor) then Direction = 1 else Direction = -1

				'Fahren - Position ändern
				If Direction = 1
					Pos.y	= Max(Pos.y - deltaTime * Speed, TBuilding.GetFloorY(TargetFloor) - spriteInner.area.GetH()) 'hoch fahren
				Else
					Pos.y	= Min(Pos.y + deltaTime * Speed, TBuilding.GetFloorY(TargetFloor) - spriteInner.area.GetH()) 'runter fahren
				EndIf

				'Begrenzungen: Nicht oben oder unten rausfahren ;)
				If Pos.y + spriteInner.area.GetH() < TBuilding.GetFloorY(13) Then Pos.y = TBuilding.GetFloorY(13) - spriteInner.area.GetH()
				If Pos.y + spriteInner.area.GetH() > TBuilding.GetFloorY( 0) Then Pos.y = TBuilding.GetFloorY(0) - spriteInner.area.GetH()

				'Die Figuren im Fahrstuhl mit der Kabine mitbewegen
				For Local figure:TFigure = EachIn Passengers
					figure.area.position.setY( self.Pos.y + spriteInner.area.GetH())
				Next
			EndIf
		Endif

		If ElevatorStatus = 3 '3 = Türen öffnen
			If doorStatus = 0
				OpenDoor()
				'wie lange die Türen mindestens offen bleiben.
				waitAtFloorTimer.SetInterval(waitAtFloorTime, true)
			Endif

			'Türanimationen für das Öffnen fortsetzen... aber auch Passagiere ausladen, wenn es fertig ist
			If door.GetFrameAnimations().getCurrentAnimationName() = "opendoor"
				MoveDeboardingPassengersToCenter() 'Während der Tür-öffnen-Animation bewegen sich die betroffenen Figuren zum Ausgang
				If door.GetFrameAnimations().GetCurrent().isFinished()
					ElevatorStatus = 4 'entladen
					door.GetFrameAnimations().SetCurrent("open")
					doorStatus = 1 'open
				EndIf
			EndIf
		Endif

		If ElevatorStatus = 4 '4 = entladen / einsteigen
			If ReadyForBoarding = false
				ReadyForBoarding = true
			Else 'ist im Else-Zweig damit die Update-Loop nochmal zu den Figuren wechseln kann um ein-/auszusteigen
				'Wenn die Wartezeit um ist, dann nach nem neuen Ziel suchen
				If waitAtFloorTimer.isExpired()
					RemoveIgnoredRoutes() 'Entferne nicht wahrgenommene routen
					ElevatorStatus = 0 '0 = warte auf nächsten Auftrag
					RouteLogic.BoardingDone()
				endif
			Endif
		Endif

		If ElevatorStatus <> 3 Then MovePassengerToPosition() 'Die Passagiere an ihre Position bewegen wenn notwendig. Natürlich nicht während des Aussteigens

		door.Update() 'Türe animieren

		TRoomDoor.UpdateToolTips() 'Tooltips aktualisieren ----  TODO: Ist das an dieser Stelle wirklich notwendig? Begründen
	End Method


	Method Draw() 'needs to be restructured (some test-lines within)
		SetBlend ALPHABLEND

		'draw the door the elevator is currently at (eg. for animation)
		door.RenderAt(GetBuilding().area.position.x + pos.x, GetBuilding().area.position.y + TBuilding.GetFloorY(CurrentFloor) - 50)

		'draw elevator position above the doors
		For Local i:Int = 0 To 13
			Local locy:Int = GetBuilding().area.position.y + TBuilding.GetFloorY(i) - door.sprite.area.GetH() - 8
			If locy < 410 And locy > -50
				SetColor 200,0,0
				DrawRect(GetBuilding().area.position.x+Pos.x-4 + 10 + (CurrentFloor)*2, locy + 3, 2,2)
				SetColor 255,255,255
			EndIf
		Next

		'draw call state next to the doors
		For Local FloorRoute:TFloorRoute = EachIn FloorRouteList
			Local locy:Int = GetBuilding().area.position.y + TBuilding.GetFloorY(floorroute.floornumber) - spriteInner.area.GetH() + 26
			If floorroute.call
				'elevator is called to this floor
				SetColor 220,240,40
				SetAlpha 0.55
				DrawRect(GetBuilding().area.position.x + Pos.x + 44, locy, 3,2)
				SetAlpha 1.0
				DrawRect(GetBuilding().area.position.x + Pos.x + 44, locy, 3,1)
			Else
				'elevator will stop there (destination)
				SetColor 220,120,50
				SetAlpha 0.85
				DrawRect(GetBuilding().area.position.x + Pos.x + 44, locy+3, 3,2)
				SetColor 250,150,80
				SetAlpha 1.0
				DrawRect(GetBuilding().area.position.x + Pos.x + 44, locy+4, 3,1)
				SetAlpha 1.0
			EndIf
			SetColor 255,255,255
		Next

		SetBlend ALPHABLEND
	End Method


	Method DrawFloorDoors()
		'Innenraum zeichen (BG)     =>   elevatorBG without image -> black
		SetColor 0,0,0
		DrawRect(GetBuilding().area.position.x + 360, Max(GetBuilding().area.position.y, 10) , 44, 373)
		SetColor 255, 255, 255
		spriteInner.Draw(GetBuilding().area.position.x + Pos.x, GetBuilding().area.position.y + Pos.y + 3.0)


		'Zeichne Figuren
		If Not passengers.IsEmpty()
			For Local passenger:TFigure = EachIn passengers
				passenger.Draw()
				passenger.alreadydrawn = 1
			Next
		Endif

		'Zeichne Türen in allen Stockwerken (außer im aktuellen)
		For Local i:Int = 0 To 13
			Local locy:Int = GetBuilding().area.position.y + TBuilding.GetFloorY(i) - door.sprite.area.GetH()
			If locy < 410 And locy > - 50 And i <> CurrentFloor Then
				door.RenderAt(GetBuilding().area.position.x + Pos.x, locy, "closed")
			Endif
		Next
	End Method

	'===== Netzwerk-Methoden =====

	Method Network_SendRouteChange(floornumber:Int, call:Int=0, who:Int, First:Int=False)
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method

	Method Network_ReceiveRouteChange( obj:TNetworkObject )
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method

	Method Network_SendSynchronize()
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method

	Method Network_ReceiveSynchronize( obj:TNetworkObject )
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method
End Type


Type TElevatorRouteLogic
	Method CreateFloorRoute:TFloorRoute(floornumber:Int, call:Int=0, who:TFigure=null) abstract
	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigure) abstract
	Method RemoveRouteOfPlayer(currentRoute:TFloorRoute) abstract
	Method IsAllowedToEnterToElevator:int(figure:TFigure, myTargetFloor:int=-1) abstract
	Method CalculateNextTarget:int() abstract
	Method BoardingDone() abstract
	Method GetSortedRouteList:TList() abstract
End Type


'an elevator, contains rules how to draw and functions when to move
Type TFloorRoute
	Field elevator:TElevator
	Field floornumber:Int
	Field call:Int
	Field who:TFigure

	Method Save()
	End Method

	Function Load:TFloorRoute(loadfile:TStream)
	End Function

	Function Create:TFloorRoute(elevator:TElevator, floornumber:Int, call:Int=0, who:TFigure=null)
		Local floorRoute:TFloorRoute = New TFloorRoute
		floorRoute.elevator = elevator
		floorRoute.floornumber = floornumber
		floorRoute.call = call
		floorRoute.who = who
		Return floorRoute
	End Function

	Method ToStringX:string(prefix:string)
		Return ""
	End Method
End Type



'###############################################################
'###############################################################
'###############################################################
'Hier beginnt die konkrete Implementierung der TElevatorSmartLogic


Type TElevatorSmartLogic Extends TElevatorRouteLogic
	Field Elevator:TElevator					'Die Referenz zum Fahrstuhl
	Field TemporaryRouteList:TList				'Die temporäre RouteList. Sie ist so lange aktuell, bis sich etwas an FloorRouteList ändert, dann wird TemporaryRouteList auf null gesetzt
	Field TopTurningPointForSort:int = -1		'Das aktuell höchste Stockwerk das es zu erreichen gibt
	Field BottomTurningPointForSort:int = -1	'Das aktuell tiefste Stockwerk das es zu erreichen gibt
	Field PrivilegePlayerMode:int = False		'Ist dieser Modus aktiv werden die Spieler durch einen Wechsel der Fahrtrichtung bevorzugt.

	Function Create:TElevatorSmartLogic(elevator:TElevator, privilegePlayerMode:int)
		local strategy:TElevatorSmartLogic = new TElevatorSmartLogic
		strategy.Elevator = elevator
		strategy.PrivilegePlayerMode = privilegePlayerMode
		Return strategy
	End Function

	'===== Externe Methoden =====

	Method CreateFloorRoute:TFloorRoute(floornumber:Int, call:Int=0, who:TFigure=null)
		Return TSmartFloorRoute.Create(Elevator, floornumber, call, who)
	End Method

	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigure)
		TemporaryRouteList = null 'Das null-setzten zwingt die Routenberechnung zur Aktualisierung
	End Method

	Method RemoveRouteOfPlayer(currentRoute:TFloorRoute)
		If TemporaryRouteList <> null Then TemporaryRouteList.remove(currentRoute)
	End Method

	Method IsAllowedToEnterToElevator:int(figure:TFigure, myTargetFloor:int=-1)
		'Man darf auch einsteigen wenn man eigentlich in ne andere Richtung wollte... ist der Parameter aber dabei, dann wird geprüft
		If myTargetFloor = -1 Then Return True
		local e:TElevator = Elevator
		'ron: if the elevator moves to nowhere... the calculated direction
		'     should not matter. Prior you were not able to enter the elevator
		'     if it stopped at your floor but was in a "different direction mode".
		'     Now we only check direction if we are on a route
		if Elevator.FloorRouteList.count()=0 then return TRUE
		'temporaryRouteList gets emptied on route change... so better use floorroutelist
		'if not TemporaryRouteList or TemporaryRouteList.count()=0 then return TRUE

		If e.Direction = CalcDirection(e.CurrentFloor, myTargetFloor) then return TRUE
		If e.CurrentFloor = TopTurningPointForSort And e.Direction = 1 then return TRUE
		if e.CurrentFloor = BottomTurningPointForSort And e.Direction = -1 then return TRUE

		Return False
	End Method

	Method BoardingDone()
		TemporaryRouteList = null 'Das null-setzten zwingt die Routenberechnung zur Aktualisierung
	End Method

	Method GetSortedRouteList:TList()
		Return TemporaryRouteList
	End Method

	Method CalculateNextTarget:int()
		'Die Berechnung der Reihenfolge finden nur dann statt, wenn TemporaryRouteList auf null gesetzt wird. Dies ist dann der Fall, wenn es eine neue Route gibt.
		if TemporaryRouteList = null
			Local startDirection:int = Elevator.Direction

			CalcBottomAndTopTurningPoint() 'Berechnet das aktuell höchste und tiefste Stockwerk und schreibt dies in TopTuringPointForSort und BottomTuringPointForSort
			FixDirection() 'Das oberste und unterste Stockwerk legen fest ob ein Richtungswechsel ansteht... das zu wissen ist für die aktuelle Berechnung
			CalcSortNumbers() 'Berechnet die Sortiernummer neu

			If PrivilegePlayerMode 'TODO: Eventuell auf einen Modus Spieler + KI erweitern... so das nur die Boten und der Hausmeister benachteiligt werden.
				If Elevator.ElevatorStatus <> 2 'Während dem fahren darf man die Richtung dann aber doch nicht ändern... erst bei der nächsten Station erhält man den Vorteil
					Elevator.Direction = GetPlayerPreferenceDirection() 'Neue Richtung bestimmen bzw. alte bestätigen... um den Spieler zu bevorzugen
					if startDirection <> Elevator.Direction 'Für diesen Modus muss FixDirection und CalcSortNumbers nochmal ausgeführt werden wenn sich die Direction geändert hat
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

		'Den ersten Eintrag zurückgeben oder das aktuelle Stockwert wenn nichts gefunden wurde
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
		'Das oberste und unterste Stockwerk legen fest ob ein Richtungswechsel ansteht... das zu wissen ist für die aktuelle Berechnung

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

	Function GetRouteIndexOfFigure:int(figure:TFigure)
		local index:int = 0
		For Local route:TFloorRoute = EachIn GetBuilding().Elevator.FloorRouteList
			If route.who = figure Then Return index
		Next
		Return -1
	End Function

	Method GetPlayerPreferenceDirection:int() 'Sortiert die Liste nach aktiven Spielern und deren Klickreihenfolge... und dann nach deren Sortiernummer
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


'Diese Klasse ist eine Erweiterung von TFloorRoute um die Sortiernummer besser zu berechnen.
'TODO: Später kann vielleicht auch TElevatorSmartLogic diese Sortiernummer berechnen... dann braucht man TSmartFloorRoute nicht mehr, wenn TFloorRoute dafür die reine Nummer bekommt.
Type TSmartFloorRoute Extends TFloorRoute
	Field SortNumber:Int = -1

	Method Save()
	End Method

	Function Load:TFloorRoute(loadfile:TStream)
	End Function

	Function Create:TSmartFloorRoute(elevator:TElevator, floornumber:Int, call:Int=0, who:TFigure=null)
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
		Return who.getFloor(who.target)
	End Method

	Method IntendedDirection:int()
		If call = 1
			If floornumber < IntendedFollowingTarget() Then Return 1 Else Return -1
		Endif
		Return 0
	End Method

	Method CalcSortNumber() 'Berechnet eine Nummer für die Gewichtung die dann sortiert werden kann.
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
		If ( sortNumber >= 20000 ) 'nur auf dem Rückweg zu bekommen
			sortNumber = sortNumber + CalcSortNumberForPath( currentPathTarget, returnPathTarget , 30000, 40000 )
			If ( sortNumber >= 60000 ) 'Hat zu spät gecalled für die Fahrt in diese Richtung. Liegt hinter der Fahrtrichtung
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

		If call And direction <> IntendedDirection() Then Return False 'Ist die geplante Fahrtrichtung korrekt?

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
		Elseif floornumber = toFloor 'Stehe am Wendepunkt des Fahrstuhls und passe sonst in keine Kategorie
			Return turningPointPenalty + GetDistance( fromFloor, floornumber ) * 100
		Else
			Return notInPathPenalty
		Endif
	End Method

	Method ToStringX:string(prefix:string)
		If call = 1
			Return prefix + self.ToString() + " C   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		Else
			Return prefix + self.ToString() + " S   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		Endif
	End Method
End Type