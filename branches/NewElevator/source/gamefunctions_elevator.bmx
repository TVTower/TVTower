Type TElevator
	'Referenzen
	Field Building :TBuilding				= null		'Das Gebäude
	Field Passengers:TList					= CreateList()	'Alle aktuellen Passagiere als TFigures			
	Field Strategy:TElevatorDefaultStrategy = TElevatorDefaultStrategy.Create(self)		
	Field FloorRouteList:TList				= CreateList() 'Die Liste mit allen Fahrstuhlanfragen und Sendekommandos in der Reihenfolge in der sie gestellt wurden
	
	'Aktueller Status (zu speichern)
	Field ElevatorStatus:Int				= 0			'0 = warte auf nächsten Auftrag, 1 = Türen schließen, 2 = Fahren, 3 = Türen öffnen, 4 = entladen/beladen, 5 = warte auf Nutzereingabe	
	Field DoorStatus:Int 					= 0    		'0 = closed, 1 = open, 2 = opening, 3 = closing	
	Field CurrentFloor:Int					= 0			'Aktuelles Stockwerk
	Field TargetFloor:Int					= 0			'Hier fährt der Fahrstuhl hin	
	Field Direction:Int						= 1			'Aktuelle/letzte Bewegungsrichtung: -1 = nach unten; +1 = nach oben; 0 = gibt es nicht
	Field ReadyForBoarding:int				= false		'während der ElevatorStatus 4, 5 und 0 möglich.
	Field BlockedByFigureUsingPlan:Int		= -1		'player using plan / Spieler-ID oder -1
	Field Pos:TPoint						= TPoint.Create(131+230,115) 	'Aktuelle Position - difference to x/y of building								

	'Einstellungen
	Field Speed:Float 						= 120		'pixels per second ;D
	
	'Timer
	Field PlanTime:Int						= 4000 		'TODOX muss geklärt werden was das ist					
'	Field WaitAtFloorTime:Int				= 5000 		'Wie lange (Millisekunden) werden die Türen offen gelassen	
	Field WaitAtFloorTime:Int				= 650 		'Wie lange (Millisekunden) werden die Türen offen gelassen
	Field WaitAtFloorTimer:Int				= 0			'Der Fahrstuhl wartet so lange, bis diese Zeit erreicht ist (in Millisekunden - basierend auf MilliSecs() + waitAtFloorTime)
		
	'Grafikelemente	
	Field SpriteDoor:TAnimSprites						'Das Türensprite und seine Animationen
	Field SpriteInner:TGW_Sprites						'Ds Sprite des Innenraums
	
	'===== Konstrukor, Speichern, Laden =====
	
	Function Create:TElevator(building:TBuilding)
		Local obj:TElevator = New TElevator		
		obj.spriteDoor = new TAnimSprites.Create(Assets.GetSprite("gfx_building_Fahrstuhl_oeffnend"), 8, 150)
		obj.spriteDoor.insertAnimation("default", TAnimation.Create([ [0,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("closed", TAnimation.Create([ [0,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("open", TAnimation.Create([ [7,70] ], 0, 0) )
		obj.spriteDoor.insertAnimation("opendoor", TAnimation.Create([ [0,70],[1,70],[2,70],[3,70],[4,70],[5,70],[6,70],[7,70] ], 0, 1) )
		obj.spriteDoor.insertAnimation("closedoor", TAnimation.Create([ [7,70],[6,70],[5,70],[4,70],[3,70],[2,70],[1,70],[0,70] ], 0, 1) )
		obj.spriteInner	= Assets.GetSprite("gfx_building_Fahrstuhl_Innen")  'gfx_building_elevator_inner
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
			RemoveRouteOfPlayer(figure, 1) 'Call-Route entfernen
			Return true
		Endif
		
		Return false
	End Method
	
	Method LeaveTheElevator(figure:TFigures) 'aussteigen
		RemoveRouteOfPlayer(figure, 0) 'Send-Route entfernen
		Passengers.remove(figure)
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
			FloorRouteList.AddLast(TFloorRoute.Create(self, floornumber, call, who))
			Strategy.AddFloorRoute(floornumber, call, who)
		EndIf		
	End Method
							
	Method RemoveRouteOfPlayer(figure:TFigures, call:int)
		RemoveRoute(GetRouteByPassenger(figure, call))
	End Method	
	
	Method RemoveRoute(route:TFloorRoute)
		if (route <> null)
			FloorRouteList.remove(route)
			Strategy.RemoveRouteOfPlayer(route)
		Endif
	End Method		
	
	Method RemoveIgnoredRoutes()
		Local tempList:TList = FloorRouteList.Copy()
		For Local route:TFloorRoute = EachIn tempList
			If route.floornumber = CurrentFloor And route.call = 1
				If Passengers.Contains(route.who)					
					throw "Logic-Exception: Person is in passengers-list, but the call-task still exists"
				Else
					RemoveRoute(route)
				Endif															
			Endif
		Next
	End Method	
	
	Method IsAllowedToEnterToElevator:int(figure:TFigures, myTargetFloor:int=-1)		
		Return Strategy.IsAllowedToEnterToElevator(figure:TFigures, myTargetFloor:int=-1)
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
		Return Strategy.CalculateNextTarget()
	End Method	
	
	'===== Fahrstuhl steuern =====
	
	Method OpenDoor()
		Self.spriteDoor.setCurrentAnimation("opendoor", True)
		print "++++++++++++++++++++++++++++++++ opendoor"
		DoorStatus = 2 'wird geoeffnet
	End Method	
	
	Method CloseDoor()
		Self.spriteDoor.setCurrentAnimation("closedoor", True)
		print "++++++++++++++++++++++++++++++++ closedoor"
		DoorStatus = 3 'closing
	End Method
	
	'===== Aktualisierungs-Methoden =====
					
	Method Update(deltaTime:Float=1.0)					
		'Aktualisierung des current floors
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
			If doorStatus <> 0 And doorStatus <> 3 And waitAtFloorTimer <= MilliSecs() Then CloseDoor() 'Wenn die Wartezeit vorbei ist, dann Türen schließen
			
			'Türanimation für das Schließen fortsetzen
			If spriteDoor.getCurrentAnimationName() = "closedoor"
				If spriteDoor.getCurrentAnimation().isFinished()					
					spriteDoor.setCurrentAnimation("closed")
					print "++++++++++++++++++++++++++++++++ closed"
					doorStatus = 0 'closed
					ElevatorStatus = 2 '2 = Fahren
				EndIf
			EndIf									
		Endif
		
		If ElevatorStatus = 2 '2 = Fahren		
			TargetFloor = CalculateNextTarget() 'Nochmal prüfen ob es ein neueres Ziel gibt.
			
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
				For Local Figure:TFigures = EachIn Passengers
					Figure.rect.position.setY ( Building.Elevator.Pos.y + spriteInner.h)
				Next					
			EndIf						
		Endif		
		
		If ElevatorStatus = 3 '3 = Türen öffnen
			If doorStatus = 0
				OpenDoor()
				waitAtFloorTimer = MilliSecs() + waitAtFloorTime 'Es wird bestimmt wie lange die Türen mindestens offen bleiben.
			Endif
		
			'Türanimationen für das Öffnen fortsetzen... aber auch Passagiere ausladen, wenn es fertig ist
			If spriteDoor.getCurrentAnimationName() = "opendoor"
				If spriteDoor.getCurrentAnimation().isFinished()
					ElevatorStatus = 4 'entladen					
					print "door open"
					spriteDoor.setCurrentAnimation("open")
					doorStatus = 1 'open
				EndIf
			EndIf		
		Endif
		
		If ElevatorStatus = 4 '4 = entladen		
			If ReadyForBoarding = false
				print "aussteigen / einsteigen"
				'Deboarding() 'Jetzt aussteigen
				ReadyForBoarding = true
			Else 'ist im Else-Zweig damit die Update-Loop nochmal zu den Figuren wechseln kann um ein-/auszusteigen
				'Wenn die Wartezeit um ist, dann nach nem neuen Ziel suchen
				If waitAtFloorTimer <= MilliSecs() Then				
					print "Entferne nicht wahrgenommene routen"
					RemoveIgnoredRoutes()	
					ElevatorStatus = 0
					Strategy.TemporaryRouteList = null
				endif			
			Endif
		Endif
		
		'if ElevatorStatus = 1 or ElevatorStatus = 3 Then 
		spriteDoor.Update(deltaTime) 'Türe animieren
		
		'Tooltips aktualisieren
		TRooms.UpdateDoorToolTips(deltaTime) 'Wirklich notwendig?
	End Method
								
	Method Draw() 'needs to be restructured (some test-lines within)
		SetBlend MASKBLEND
		'TODOX: Warum werden hier die anderen Türen gezeichnet? Vielleicht wieder rein machen
		'TRooms.DrawDoors() 'draw overlay -open doors etc.   

		'Die fehlende Tür zeichnen... also da wo der Fahrstuhl ist
		'If spriteDoor.getCurrentAnimationName() = "open" print "Elevator 1"
		spriteDoor.Draw(Building.pos.x + pos.x, Building.pos.y + Building.GetFloorY(CurrentFloor) - 50)
		'If spriteDoor.getCurrentAnimationName() = "open" print "Elevator 2"
		
		'Fahrstuhlanzeige über den Türen
		For Local i:Int = 0 To 13
			Local locy:Int = Building.pos.y + Building.GetFloorY(i) - Self.spriteDoor.sprite.h - 8
			If locy < 410 And locy > -50
				SetColor 200,0,0
				DrawRect(Building.pos.x+Pos.x-4 + 10 + (CurrentFloor)*2, locy + 3, 2,2)
				SetColor 255,255,255
			EndIf
		Next

		'TODOX: Muss wohl überarbeitet werden, da sich ja auch die Routen ändern
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
	
	Method Network_SendRouteChange(floornumber:Int, call:Int=0, who:Int, First:Int=False)
		'TODOX
	End Method

	Method Network_ReceiveRouteChange( obj:TNetworkObject )
		'TODOX
	End Method

	Method Network_SendSynchronize()
		'TODOX
	End Method

	Method Network_ReceiveSynchronize( obj:TNetworkObject )
		'TODOX
	End Method		
	
End Type

'an elevator, contains rules how to draw and functions when to move
Type TFloorRoute
	Field elevator:TElevator
	Field floornumber:Int
	Field call:Int
	Field who:TFigures
	
	Field sortNumber:Int = -1
	
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

	Method IntendedFollowingTarget:int()
		Return who.getFloor(who.target)
	End Method

	Method IntendedDirection:int()
		If call = 1
			If floornumber < IntendedFollowingTarget() Then Return 1 Else Return -1			
		Endif
		Return 0
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
	
	Method CalcSortNumber:int()
		If sortNumber = -1	
			local currentPathTarget:int = 0, returnPathTarget:int = 0
			sortNumber = 0
			
			If elevator.Direction = 1
				currentPathTarget = elevator.Strategy.TopTuringPointForSort
				returnPathTarget = elevator.Strategy.BottomTuringPointForSort
			else
				currentPathTarget = elevator.Strategy.BottomTuringPointForSort
				returnPathTarget = elevator.Strategy.TopTuringPointForSort	
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
		Endif
		Return sortNumber
	End Method

	'Method Compare:Int(otherObject:Object)	
	'	If otherObject = null Then Return 1
	'	Return CalcSortNumber() - TFloorRoute(otherObject).CalcSortNumber();
	'End Method	
	
	Method ToStringX:string(prefix:string)
		If call = 1
			Return prefix + self.ToString() + " C   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		Else
			Return prefix + self.ToString() + " S   " + Elevator.CurrentFloor + " -> " + floornumber + " ( -> " + IntendedFollowingTarget() + " | " + IntendedDirection() + ")    " + CalcSortNumber() + "   = " + who.name + " (" + who.id + ")"
		Endif		
	End Method		
End Type

Type TElevatorDefaultStrategy
	Field Elevator:TElevator
	Field TemporaryRouteList:TList			= null		'Die temporäre RouteList. Sie ist so lange aktuell, bis sich etwas an FloorRouteList ändert, dann wird TemporaryRouteList auf null gesetzt
	Field TopTuringPointForSort:int = -1
	Field BottomTuringPointForSort:int = -1

	Function Create:TElevatorDefaultStrategy(elevator:TElevator)		
		local strategy:TElevatorDefaultStrategy = new TElevatorDefaultStrategy
		strategy.Elevator = elevator
		Return strategy
	End Function
	
	Method CalcDirection:int(fromFloor:int, toFloor:int)
		If fromFloor = toFloor Then Return 0
		If fromFloor < toFloor Then Return 1 Else Return -1
	End Method
	
	Method IsAllowedToEnterToElevator:int(figure:TFigures, myTargetFloor:int=-1)		
		'Man darf auch einsteigen wenn man eigentlich in ne andere Richtung wollte... ist der Parameter aber dabei, dann wird geprüft				
		If myTargetFloor = -1 Then Return True
		local e:TElevator = Elevator
		If (e.Direction = CalcDirection(e.CurrentFloor, myTargetFloor) Or (e.CurrentFloor = TopTuringPointForSort And e.Direction = 1) Or (e.CurrentFloor = BottomTuringPointForSort And e.Direction = -1))
			Return True
		Endif
		Return False
	End Method	
	
	Method AddFloorRoute:Int(floornumber:Int, call:Int = 0, who:TFigures)
		TemporaryRouteList = null 'Das null-setzten zwingt die Routenberechnung zur Aktualisierung
	End Method	
	
	Method RemoveRouteOfPlayer(currentRoute:TFloorRoute)
		If TemporaryRouteList <> null Then TemporaryRouteList.remove(currentRoute)
	End Method		




	Method CalculateNextTarget:int()
		if TemporaryRouteList = null		
			TopTuringPointForSort= -1;
			BottomTuringPointForSort= 20;

			For Local route:TFloorRoute = EachIn Elevator.FloorRouteList
				If route.floornumber < BottomTuringPointForSort Then BottomTuringPointForSort = route.floornumber
				If route.floornumber > TopTuringPointForSort Then TopTuringPointForSort = route.floornumber
				route.sortNumber = -1
			Next	
			print "..........................................................................A: " + Elevator.Direction 
			If Elevator.ElevatorStatus <> 2
				Elevator.Direction = GetPlayerPreferenceDirection()			
				print "..........................................................................B: " + Elevator.Direction 
				
				For Local route:TFloorRoute = EachIn Elevator.FloorRouteList
					route.sortNumber = -1
				Next			
			Endif
			
			If Elevator.CurrentFloor >= TopTuringPointForSort Then Elevator.Direction = -1
			If Elevator.CurrentFloor <= BottomTuringPointForSort Then Elevator.Direction = 1			
		
			local tempList:TList = Elevator.FloorRouteList.Copy()												
			SortList(tempList, True, DefaultRouteSort)
			TemporaryRouteList = tempList
			
			Print ">>>>>>>>>>>>>>>"
			print "Direction: " + Elevator.Direction
			print "CurrentFloor: " + Elevator.CurrentFloor + "     ( " + BottomTuringPointForSort + "->" + TopTuringPointForSort + ")"
			print "==="
			For Local figure:TFigures = EachIn Elevator.Passengers
				print figure.name
			Next
			print "==="			
			For Local route:TFloorRoute = EachIn TemporaryRouteList 
				print route.ToStringX("")
			Next
			Print "<<<<<<<<<<<<<<<"
		Endif
		
		Local nextTarget:TFloorRoute = TFloorRoute(TemporaryRouteList.First())
		If nextTarget <> null
			'If (nextTarget.floornumber < TargetFloor And Direction = 1) Or (nextTarget.floornumber > TargetFloor And Direction = -1) 'Ein Richtungswechsel... bitte neu berechnen			
			Return nextTarget.floornumber
		Else
			Return Elevator.TargetFloor
		Endif
	End Method


	
	
	
	Function DefaultRouteSort:Int( o1:Object, o2:Object )
		Return TFloorRoute(o1).CalcSortNumber() - TFloorRoute(o2).CalcSortNumber()
	End Function				
	
	Function PlayerPreferenceRouteSort:Int( o1:Object, o2:Object )
		local route1:TFloorRoute = TFloorRoute(o1)
		local route2:TFloorRoute = TFloorRoute(o2)
'		print "PlayerPreferenceRouteSort1: " + route1.who.id + " - " + route2.who.id
		If route1.who.IsActivePlayer()			
			If route2.who.IsActivePlayer()
'				print "PlayerPreferenceRouteSort2: " + (GetRouteIndexOfFigure(route1.who) - GetRouteIndexOfFigure(route2.who))
				Return GetRouteIndexOfFigure(route1.who) - GetRouteIndexOfFigure(route2.who)
			Else
'				print "PlayerPreferenceRouteSort3: -1"
				Return -1
			Endif			
		Else
			If route2.who.IsActivePlayer()
				'print "PlayerPreferenceRouteSort4: 1"
				Return 1
			Endif
		Endif
	
'		print "PlayerPreferenceRouteSort5: " + (route1.CalcSortNumber() - route2.CalcSortNumber())
		Return route1.CalcSortNumber() - route2.CalcSortNumber()
	End Function	
	
	Function GetRouteIndexOfFigure:int(figure:TFigures)
		local index:int = 0
		For Local route:TFloorRoute = EachIn Building.Elevator.FloorRouteList
			If route.who = figure Then Return index
		Next
		Return -1
	End Function		
	
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
End Type