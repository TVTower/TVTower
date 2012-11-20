'=== Struktur des Elevators ===
'Ziel der Überarbeitung war es u.a. auch die Lesbarkeit und Aufteilung des Codes zu optimieren.
'Auch die Reduzierung der vielen komplexen Prüfungen sollte erreicht werden... dies wird vor allem durch den Ablauf des "ElevatorStatus" realisiert.

'TElevator: Grundlegende Klasse zur Darstellung und Steuerung des Fahrstuhls. Die Logik der Routensteuerung ist in TElevatorRouteLogic ausgelagert
'TElevatorRouteLogic: Ableitungen dieser abstrakten Klasse können die Logik für die Routenberechnung implementieren
'TFloorRoute: In dieser Klasse werden die Routen-Daten die Calls und Sends des Fahrstuhls abgelegt.

'Die Standard-Logikimplementierung ist "TElevatorSmartStrategy" zu finden. Diese benötigt die Klasse "TSmartFloorRoute" eine Ableitung von 'TFloorRoute

Type TElevator
	'Referenzen
	Field Building :TBuilding				= null		'Das Gebäude
	Field Passengers:TList					= CreateList()	'Alle aktuellen Passagiere als TFigures			
	Field RouteLogic:TElevatorRouteLogic	= null
	Field FloorRouteList:TList				= CreateList() 'Die Liste mit allen Fahrstuhlanfragen und Sendekommandos in der Reihenfolge in der sie gestellt wurden
	Field SoundSource:TElevatorSoundSource	= TElevatorSoundSource.Create(self, true)
	
	'Aktueller Status (zu speichern)
	Field ElevatorStatus:Int				= 0			'0 = warte auf nächsten Auftrag, 1 = Türen schließen, 2 = Fahren, 3 = Türen öffnen, 4 = entladen/beladen, 5 = warte auf Nutzereingabe (für den Plan)
	Field DoorStatus:Int 					= 0    		'0 = closed, 1 = open, 2 = opening, 3 = closing	
	Field CurrentFloor:Int					= 0			'Aktuelles Stockwerk
	Field TargetFloor:Int					= 0			'Hier fährt der Fahrstuhl hin	
	Field Direction:Int						= 1			'Aktuelle/letzte Bewegungsrichtung: -1 = nach unten; +1 = nach oben; 0 = gibt es nicht
	Field ReadyForBoarding:int				= false		'während der ElevatorStatus 4, 5 und 0 möglich.
	Field BlockedByFigureUsingPlan:Int		= -1		'player using plan / Spieler-ID oder -1
	Field Pos:TPoint						= TPoint.Create(131+230,115) 	'Aktuelle Position - difference to x/y of building
	Field FiguresUsingPlan:TList			= CreateList() 'Für das Netzwerkspiel... da können mehrere Spieler ein Ziel im Plan auswählen

	'Einstellungen
	Field Speed:Float 						= 120		'pixels per second ;D
	
	'Timer
	Field PlanTime:Int						= 4000 		'Zeit die ein Spieler im Raumplan verbringen kann bis er rausgeschmissen wird
	Field WaitAtFloorTimer:TTimer			= null 		'Wie lange (Millisekunden) werden die Türen offen gelassen (alt: 650)
	Field WaitAtFloorTime:Int				= 1700		'Der Fahrstuhl wartet so lange, bis diese Zeit erreicht ist (in Millisekunden - basierend auf MilliSecs() + waitAtFloorTime)
		
	'Grafikelemente	
	Field SpriteDoor:TAnimSprites						'Das Türensprite und seine Animationen
	Field SpriteInner:TGW_Sprites						'Das Sprite des Innenraums
	Field PassengerOffset:TPoint[]						'Damit nicht alle auf einem Haufen stehen, gibt es für die Figures ein paar Offsets im Fahrstuhl
	Field PassengerPosition:TFigures[]					'Hier wird abgelegt, welches Offset schon in Benutzung ist und von welcher Figur
	


	'===== Konstrukor, Speichern, Laden =====
	
	Function Create:TElevator(building:TBuilding)
		Local obj:TElevator = New TElevator		
		'create timer
		obj.WaitAtFloorTimer = TTimer.Create( obj.WaitAtFloorTime )
		'create sprite
		obj.spriteDoor = new TAnimSprites.Create(Assets.GetSprite("gfx_building_Fahrstuhl_oeffnend"), 8, 150)
		obj.spriteDoor.insertAnimation("default", TAnimation.Create([ [0,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("closed", TAnimation.Create([ [0,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("open", TAnimation.Create([ [7,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("opendoor", TAnimation.Create([ [0,70],[1,70],[2,70],[3,70],[4,70],[5,70],[6,70],[7,70] ], 0, 1) )
		obj.spriteDoor.insertAnimation("closedoor", TAnimation.Create([ [7,70],[6,70],[5,70],[4,70],[3,70],[2,70],[1,70],[0,70] ], 0, 1) )
		obj.spriteInner	= Assets.GetSprite("gfx_building_Fahrstuhl_Innen")  'gfx_building_elevator_inner
		
		obj.PassengerPosition  = obj.PassengerPosition[..6]
		obj.PassengerOffset    = obj.PassengerOffset[..6]
		obj.PassengerOffset[0] = TPoint.Create(0, 0)
		obj.PassengerOffset[1] = TPoint.Create(-12, 0)
		obj.PassengerOffset[2] = TPoint.Create(-6, 0)
		obj.PassengerOffset[3] = TPoint.Create(3, 0)
		obj.PassengerOffset[4] = TPoint.Create(-3, 0)		
		obj.PassengerOffset[5] = TPoint.Create(-8, 0)
		
		obj.Building = building
		obj.Pos.SetY(building.GetFloorY(obj.CurrentFloor) - obj.spriteInner.h)
		
		obj.spriteDoor.setCurrentAnimation("open")
		obj.doorStatus = 1 'open		
		obj.ElevatorStatus	= 0
		Return obj
	End Function
	
	Method Save()
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method	
	
	Method Load(loadfile:TStream)
		'TODO: Wollte Ronny ja eh noch überarbeiten
	End Method
	
	'===== Öffentliche Methoden damit die Figuren den Fahrstuhl steuern können =====
	
	Method CallElevator(figure:TFigures)
		AddFloorRoute(figure.GetFloor(), 1, figure)
	End Method
	
	Method SendElevator(targetFloor:int, figure:TFigures)
		AddFloorRoute(targetFloor, 0, figure)
	End Method	
	
	Method EnterTheElevator:int(figure:TFigures, myTargetFloor:int=-1) 'bzw. einsteigen		
		If Not IsAllowedToEnterToElevator(figure, myTargetFloor) Then Return False
		If Not Passengers.Contains(figure)
			Passengers.AddLast(figure)
			SetFigureOffset(figure)
			RemoveRouteOfPlayer(figure, 1) 'Call-Route entfernen
			Return true
		Endif		
		Return false
	End Method
	
	Method LeaveTheElevator(figure:TFigures) 'aussteigen
		RemoveFigureOffset(figure)		'Das Offset auf jeden Fall zurücksetzen
		RemoveRouteOfPlayer(figure, 0)  'Send-Route entfernen
		Passengers.remove(figure)		'Aus der Passagierliste entfernen
	End Method
	
	Method UsePlan(figure:TFigures)		
		ElevatorStatus = 5 'Den Wartestatus setzen
		If Not FiguresUsingPlan.Contains(figure)
			'Die Zeit zurücksetzen/verlängern
			waitAtFloorTimer.SetInterval(self.PlanTime, true)
			FiguresUsingPlan.AddLast(figure)
		Endif
	End Method
	
	Method PlanningFinished(figure:TFigures)
		FiguresUsingPlan.Remove(figure)
	End Method	
	
	'===== Externe Hilfsmethoden für Figuren =====

	Method IsFigureInFrontOfDoor:Int(figure:TFigures)
		Return (GetDoorCenterX() = figure.GetCenterX())
	End Method	
	
	Method IsFigureInElevator:Byte(figure:TFigures)
		Return passengers.Contains(figure)
	End Method

	Method GetDoorCenterX:int()
		Return Building.pos.x + Pos.x + spriteDoor.sprite.framew/2
	End Method
	
	Method GetDoorWidth:int()
		Return spriteDoor.sprite.framew
	End Method
	
	'===== Hilfsmethoden =====
											
	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigures)
		If Not ElevatorCallIsDuplicate(floornumber, who) Then 'Prüfe auf Duplikate			
			FloorRouteList.AddLast(RouteLogic.CreateFloorRoute(floornumber, call, who))
			RouteLogic.AddFloorRoute(floornumber, call, who)
		EndIf		
	End Method
							
	Method RemoveRouteOfPlayer(figure:TFigures, call:int)
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
	
	Method IsAllowedToEnterToElevator:int(figure:TFigures, myTargetFloor:int=-1)		
		Return RouteLogic.IsAllowedToEnterToElevator(figure, myTargetFloor)
	End Method		
						
	Method ElevatorCallIsDuplicate:Int(floornumber:Int, who:TFigures)
		For Local DupeRoute:TFloorRoute = EachIn FloorRouteList
			If DupeRoute.who.id = who.id And DupeRoute.floornumber = floornumber Then Return True
		Next
		Return False
	End Method
	
	Method GetRouteByPassenger:TFloorRoute(passenger:TFigures, isCallRoute:int)
		For Local route:TFloorRoute = EachIn FloorRouteList
			If route.who = passenger And route.call = isCallRoute Then Return route
		Next
		Return null
	End Method
	
	Method CalculateNextTarget:int()
		Return RouteLogic.CalculateNextTarget()
	End Method	
	
	Method GetElevatorCenterPos:TPoint()
		Return TPoint.Create(Building.pos.x + Pos.x + Self.spriteDoor.sprite.framew/2, Pos.y + Self.spriteDoor.sprite.frameh/2 + 56, -25) '-25 = z-Achse für Audio. Der Fahrstuhl liegt etwas im Hintergrund
	End Method	
	
	'===== Offset-Funktionen =====
	
	Method SetFigureOffset(figure:TFigures)
		for local i:int = 0 to len(PassengerOffset) -1
			If PassengerPosition[i] = null Then PassengerPosition[i] = figure; Exit
		next
	End Method
	
	Method RemoveFigureOffset(figure:TFigures)
		for local i:int = 0 to len(PassengerOffset) -1
			If PassengerPosition[i] = figure Then PassengerPosition[i] = null; Exit
		next
		figure.PosOffset.SetXY(0, 0)
	End Method
	
	Method MovePassengerToPosition() 'Aktualisiert das Offset und bewegt die Figur an die richtige Position
		for local i:int = 0 to len(PassengerPosition) - 1
			local figure:TFigures = PassengerPosition[i]				
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
			local figure:TFigures = PassengerPosition[i]			
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
		SoundSource.PlaySfx(SFX_ELEVATOR_OPENDOOR)
		Self.spriteDoor.setCurrentAnimation("opendoor", True)
		DoorStatus = 2 'wird geoeffnet
	End Method	
	
	Method CloseDoor()
		SoundSource.PlaySfx(SFX_ELEVATOR_CLOSEDOOR)
		Self.spriteDoor.setCurrentAnimation("closedoor", True)
		DoorStatus = 3 'closing
	End Method
	
	'===== Aktualisierungs-Methoden =====
					
	Method Update(deltaTime:Float=1.0)					
		'Aktualisierung des current floors - mv: da ich hier nicht durchblicke lass ich's so wie's ist ;)
		If Abs(Building.GetFloorY(Building.GetFloor(Building.pos.y + Pos.y + spriteInner.h - 1)) - (Pos.y + spriteInner.h)) <= 1
			'the -1 is used for displace the object one pixel higher, so it has to reach the first pixel of the floor
			'until the function returns the new one, instead of positioning it directly on the floorground
			CurrentFloor = Building.GetFloor(Building.pos.y + Pos.y + spriteInner.h - 1)
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
			If spriteDoor.getCurrentAnimationName() = "closedoor"				
				If spriteDoor.getCurrentAnimation().isFinished()					
					spriteDoor.setCurrentAnimation("closed")
					doorStatus = 0 'closed
					ElevatorStatus = 2 '2 = Fahren
					SoundSource.PlaySfx(SFX_ELEVATOR_ENGINE)
				EndIf
			EndIf									
		Endif
		
		If ElevatorStatus = 2 '2 = Fahren		
			TargetFloor = CalculateNextTarget() 'Nochmal prüfen ob es vielleicht ein neueres Ziel gibt das unterwegs eingeladen werden muss
			
			if CurrentFloor = TargetFloor 'Ist der Fahrstuhl da/angekommen, aber die Türen sind noch geschlossen? Dann öffnen!
				ElevatorStatus = 3 'Türen öffnen					
			Else
				If (CurrentFloor < TargetFloor) Then Direction = 1 Else Direction = -1
											
				'Fahren - Position ändern
				If Direction = 1
					Pos.y	= Max(Pos.y - deltaTime * Speed, Building.GetFloorY(TargetFloor) - spriteInner.h) 'hoch fahren
				Else
					Pos.y	= Min(Pos.y + deltaTime * Speed, Building.GetFloorY(TargetFloor) - spriteInner.h) 'runter fahren	
				EndIf

				'Begrenzungen: Nicht oben oder unten rausfahren ;)
				If Pos.y + spriteInner.h < Building.GetFloorY(13) Then Pos.y = Building.GetFloorY(13) - spriteInner.h
				If Pos.y + spriteInner.h > Building.GetFloorY( 0) Then Pos.y = Building.GetFloorY(0) - spriteInner.h		
				
				'Die Figuren im Fahrstuhl mit der Kabine mitbewegen
				For Local figure:TFigures = EachIn Passengers
					figure.rect.position.setY( self.Pos.y + spriteInner.h)
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
			If spriteDoor.getCurrentAnimationName() = "opendoor"
				MoveDeboardingPassengersToCenter() 'Während der Tür-öffnen-Animation bewegen sich die betroffenen Figuren zum Ausgang			
				If spriteDoor.getCurrentAnimation().isFinished()
					ElevatorStatus = 4 'entladen					
					spriteDoor.setCurrentAnimation("open")
					doorStatus = 1 'open
				EndIf
			EndIf		
		Endif
		
		If ElevatorStatus = 4 Or ElevatorStatus = 5 '4 = entladen / einsteigen UND 5 = warte auf Nutzereingabe (für den Plan)					
			If ReadyForBoarding = false
				ReadyForBoarding = true
			Else 'ist im Else-Zweig damit die Update-Loop nochmal zu den Figuren wechseln kann um ein-/auszusteigen
				'Eventuell die Wartezeit vorab beenden, wenn die Auswahl getätigt wurde. Aber nur wenn auch wirklich im Wartemodus
				If ElevatorStatus = 5 And FiguresUsingPlan.IsEmpty() Then waitAtFloorTimer.expire()
				'Wenn die Wartezeit um ist, dann nach nem neuen Ziel suchen
				If waitAtFloorTimer.isExpired()
					FiguresUsingPlan.Clear() 'Alle Figuren die den Plan genutzt haben werden jetzt rausgeworfen
					RemoveIgnoredRoutes() 'Entferne nicht wahrgenommene routen
					ElevatorStatus = 0 '0 = warte auf nächsten Auftrag
					RouteLogic.BoardingDone()
				endif			
			Endif
		Endif
		
		If ElevatorStatus <> 3 Then MovePassengerToPosition() 'Die Passagiere an ihre Position bewegen wenn notwendig. Natürlich nicht während des Aussteigens
				
		spriteDoor.Update(deltaTime) 'Türe animieren
				
		TRooms.UpdateDoorToolTips(deltaTime) 'Tooltips aktualisieren ----  TODO: Ist das an dieser Stelle wirklich notwendig? Begründen
	End Method
								
	Method Draw() 'needs to be restructured (some test-lines within)
		SetBlend MASKBLEND

		'Den leeren Schacht zeichnen... also da wo der Fahrstuhl war
		spriteDoor.Draw(Building.pos.x + pos.x, Building.pos.y + Building.GetFloorY(CurrentFloor) - 50)
		
		'Fahrstuhlanzeige über den Türen
		For Local i:Int = 0 To 13
			Local locy:Int = Building.pos.y + Building.GetFloorY(i) - Self.spriteDoor.sprite.h - 8
			If locy < 410 And locy > -50
				SetColor 200,0,0
				DrawRect(Building.pos.x+Pos.x-4 + 10 + (CurrentFloor)*2, locy + 3, 2,2)
				SetColor 255,255,255
			EndIf
		Next

		'Fahrstuhlanzeige über den Türen
		For Local FloorRoute:TFloorRoute = EachIn FloorRouteList
			Local locy:Int = Building.pos.y + Building.GetFloorY(floorroute.floornumber) - spriteInner.h + 23
			'elevator is called to this floor					'elevator will stop there (destination)
			If	 floorroute.call Then SetColor 200,220,20 	Else SetColor 100,220,20
			DrawRect(Building.pos.x + Pos.x + 44, locy, 3,3)
			SetColor 255,255,255
		Next

		SetBlend ALPHABLEND
	End Method
	
	Method DrawFloorDoors()				
		'Innenraum zeichen (BG)     =>   elevatorBG without image -> black
		SetColor 0,0,0
		DrawRect(Building.pos.x + 360, Max(Building.pos.y, 10) , 44, 373)
		SetColor 255, 255, 255		
		spriteInner.Draw(Building.pos.x + Pos.x, Building.pos.y + Pos.y + 3.0)
		
		
		'Zeichne Figuren
		If Not passengers.IsEmpty() Then
			For Local passenger:TFigures = EachIn passengers
				passenger.Draw()
				passenger.alreadydrawn = 1
			Next				
		Endif	

		'Zeichne Türen in allen Stockwerken (außer im aktuellen)
		For Local i:Int = 0 To 13
			Local locy:Int = Building.pos.y + Building.GetFloorY(i) - Self.spriteDoor.sprite.h
			If locy < 410 And locy > - 50 And i <> CurrentFloor Then
				Self.spriteDoor.Draw(Building.pos.x + Pos.x, locy, "closed")
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
	Method CreateFloorRoute:TFloorRoute(floornumber:Int, call:Int=0, who:TFigures=null) abstract
	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigures) abstract
	Method RemoveRouteOfPlayer(currentRoute:TFloorRoute) abstract
	Method IsAllowedToEnterToElevator:int(figure:TFigures, myTargetFloor:int=-1) abstract
	Method CalculateNextTarget:int() abstract
	Method BoardingDone() abstract
	Method GetSortedRouteList:TList() abstract
End Type


'an elevator, contains rules how to draw and functions when to move
Type TFloorRoute
	Field elevator:TElevator
	Field floornumber:Int
	Field call:Int
	Field who:TFigures	
	
	Method Save()
	End Method

	Function Load:TFloorRoute(loadfile:TStream)
	End Function
	
	Function Create:TFloorRoute(elevator:TElevator, floornumber:Int, call:Int=0, who:TFigures=null)
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
	
	Method CreateFloorRoute:TFloorRoute(floornumber:Int, call:Int=0, who:TFigures=null)
		Return TSmartFloorRoute.Create(Elevator, floornumber, call, who)
	End Method
	
	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigures)
		TemporaryRouteList = null 'Das null-setzten zwingt die Routenberechnung zur Aktualisierung
	End Method	
	
	Method RemoveRouteOfPlayer(currentRoute:TFloorRoute)
		If TemporaryRouteList <> null Then TemporaryRouteList.remove(currentRoute)
	End Method		
	
	Method IsAllowedToEnterToElevator:int(figure:TFigures, myTargetFloor:int=-1)		
		'Man darf auch einsteigen wenn man eigentlich in ne andere Richtung wollte... ist der Parameter aber dabei, dann wird geprüft				
		If myTargetFloor = -1 Then Return True
		local e:TElevator = Elevator
		If (e.Direction = CalcDirection(e.CurrentFloor, myTargetFloor) Or (e.CurrentFloor = TopTurningPointForSort And e.Direction = 1) Or (e.CurrentFloor = BottomTurningPointForSort And e.Direction = -1))
			Return True
		Endif
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
	
	Function GetRouteIndexOfFigure:int(figure:TFigures)
		local index:int = 0
		For Local route:TFloorRoute = EachIn Building.Elevator.FloorRouteList
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
	
	Function Create:TSmartFloorRoute(elevator:TElevator, floornumber:Int, call:Int=0, who:TFigures=null)
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