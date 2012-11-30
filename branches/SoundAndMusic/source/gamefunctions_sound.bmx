Type TSfxFloorSoundBarrierSettings Extends TSfxSettings

	Method GetVolumeByDistance:float(source:TSoundSourceElement, receiver:TElementPosition)
		local floorNumberSource:int = Building.getFloorByPixelExactPoint(source.GetCenter())
		local floorNumberTarget:int = Building.getFloorByPixelExactPoint(receiver.GetCenter())
		local floorDistance:int = TPoint.DistanceOfValues(floorNumberSource, floorNumberTarget)
'		print "floorDistance: " + floorDistance + " - " + Exponential(0.5, floorDistance) + " # " + floorNumberSource + " $ " + floorNumberTarget
		Return super.GetVolumeByDistance(source, receiver) * Exponential(0.5, floorDistance)
	End Method

	Method Exponential:float(base:float, expo:float)
'		print "Exponential1: " + base + " - " + expo
		local result:float = base
		If expo >= 2
			for local i:int = 1 to expo - 1
				result = result * base
			next
		Endif
'		print "Exponential2: " + result
		Return result
	End Method

End Type

Type TPlayerElementPosition Extends TElementPosition
	Function Create:TPlayerElementPosition ()
		return new TPlayerElementPosition
	End Function

	Method GetID:string()
		Return "Player"
	End Method

	Method GetCenter:TPoint()	
		Return Players[Game.playerID].Figure.rect.GetAbsoluteCenterPoint()
	End Method

	Method GetIsVisible:int()
		Return true
	End Method

	Method IsMovable:int()
		Return false 'Bedeutet das es nicht überwacht wird. Speziell beim Player
	End Method
End Type

Type TElevatorSoundSource Extends TSoundSourceElement
	Field Elevator:TElevator = null
	Field Movable:int = true

	Function Create:TElevatorSoundSource(_elevator:TElevator, _movable:int)
		local result:TElevatorSoundSource  = new TElevatorSoundSource
		result.Elevator = _elevator
		result.Movable = ­_movable
		
		result.AddDynamicSfxChannel("Main")
		result.AddDynamicSfxChannel("Door")
		
		return result
	End Function
	
	Method PlaySfx(sfx:string, sfxSettings:TSfxSettings=null)			
		'print "aa1: " + GetCenter().x + "/" + GetCenter().y + " - " + Building.getFloorByPixelExactPoint(GetCenter())	
		super.PlaySfx(sfx)
	End Method	

	Method GetID:string()
		Return "Elevator"
	End Method

	Method GetCenter:TPoint()
		Return Elevator.GetElevatorCenterPos()
	End Method

	Method IsMovable:int()
		Return ­Movable
	End Method
	
	Method GetIsHearable:int()
		Return (Players[Game.playerID].Figure.inRoom = null)
	End Method
	
	Method GetChannelForSfx:TSfxChannel(sfx:string)
		Select sfx
			Case SFX_ELEVATOR_OPENDOOR
				Return GetSfxChannelByName("Door")
			Case SFX_ELEVATOR_CLOSEDOOR
				Return GetSfxChannelByName("Door")
			Case SFX_ELEVATOR_ENGINE
				Return GetSfxChannelByName("Main")
		EndSelect		
	End Method
	
	Method GetSfxSettings:TSfxSettings(sfx:string)
		Select sfx
			Case SFX_ELEVATOR_OPENDOOR
				Return GetDoorOptions()
			Case SFX_ELEVATOR_CLOSEDOOR
				Return GetDoorOptions()
			Case SFX_ELEVATOR_ENGINE
				Return GetEngineOptions()
		EndSelect						
	End Method
	
	Method OnPlaySfx:int(sfx:string)
		Select sfx
			Case SFX_ELEVATOR_OPENDOOR
				local engineChannel:TSfxChannel = GetChannelForSfx(SFX_ELEVATOR_ENGINE)
				engineChannel.Stop()
		EndSelect
		
		Return True
	End Method
	
	Method GetDoorOptions:TSfxSettings()
		local result:TSfxSettings = new TSfxFloorSoundBarrierSettings
		result.nearbyDistanceRange = 50
		result.maxDistanceRange = 500			
		result.nearbyRangeVolume = 1
		result.midRangeVolume = 0.5
		result.minVolume = 0
		Return result
	End Method

	Method GetEngineOptions:TSfxSettings()
		local result:TSfxSettings = new TSfxSettings
		result.nearbyDistanceRange = 0
		result.maxDistanceRange = 500
		result.nearbyRangeVolume = 0.5
		result.midRangeVolume = 0.25
		result.minVolume = 0.05
		Return result
	End Method	
End Type

Type TDoorSoundSource Extends TSoundSourceElement
	Field Room:TRooms			'Die Raum dieser Türe
	Field IsGamePlayerAction:int	'
	Field DoorTimer:TTimer		= TTimer.Create(1000)'500

	Function Create:TDoorSoundSource(_room:TRooms)
		local result:TDoorSoundSource = new TDoorSoundSource
		result.Room = _room
		
		result.AddDynamicSfxChannel(SFX_OPEN_DOOR, true)
		result.AddDynamicSfxChannel(SFX_CLOSE_DOOR, true)
		
		return result
	End Function

	Method PlayDoorSfx(sfx:string, figure:TFigures)
		'Die Türsound brauchen eine spezielle Behandlung wenn es sich dabei um einen Spieler handelt der einen Raum betritt oder verlässt.
		'Diese spezielle Behandlung (der Modus) wird durch IsGamePlayerAction = true gekenntzeichnet.
		'Ist dieser Modus aktiv wird ein Timer gestartet welcher das Schließen der Türe nach einiger Zeit abspielt (siehe Update).
		'Dies ist nötig da im normalen Codeablauf das "CloseDoor" von TRooms zu schnell kommt. Dieser Schließensound aus CloseDoor muss in diesem Modus abgefangen werden
	
		If figure = Players[Game.playerID].Figure 'Dieser Code nur für den aktiven Spieler
			If Not IsGamePlayerAction 'Wenn wir uns noch nicht im Spezialmodus befinden, dann weiter prüfen ob man ihn gleich aktiv schalten muss
				If sfx = SFX_OPEN_DOOR 'Nur der Open-Sound kann den Spezialmodus starten
					If DoorTimer.isExpired() 'Ist der Timer abgelaufen?
						IsGamePlayerAction = true 'Den Modus starten
						If Players[Game.playerID].Figure.inRoom = null 'von draußen (Flur) nach drinen (Raum)
							If Room.used >= 0 Then IsGamePlayerAction = false 'Ein kleiner Hack: Wenn der Raum besetzt ist, dann soll das mit dem Modus doch nicht durchgeführt werden
							PlaySfx(sfx, GetPlayerBeforeDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler vor der Türe (Depth)
						Else 'von drinnen (Raum) nach draußen (Flur)
							PlaySfx(sfx, GetPlayerBehindDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler hinter der Türe (Depth) (im Raum)
						Endif	
						DoorTimer.reset() 'den Close auf Timer setzen... 
					Else 'In dem Fall ist die Türe also noch offen
						DoorTimer.reset() 'Den Schließen-Sound verschieben.
					Endif			
				Elseif sfx = SFX_CLOSE_DOOR
					PlaySfx(sfx)
				Endif
			Endif		
		Else
			PlaySfx(sfx)
		Endif		
	End Method
	
	Method Update()
		If IsGamePlayerAction
			If DoorTimer.isExpired() 'Wenn der Timer abgelaufen, dann den Türschließsound spielen
				If Players[Game.playerID].Figure.inRoom = null
					PlaySfx(SFX_CLOSE_DOOR, GetPlayerBeforeDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler vor der Türe (Depth)
				Else
					PlaySfx(SFX_CLOSE_DOOR, GetPlayerBehindDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler hinter der Türe (Depth) (im Raum)
				Endif
				IsGamePlayerAction = false 'Modus beenden
			Endif
		Endif
		
		super.Update()		
	End Method	
	
	Method GetID:string()
		Return "Door"
	End Method

	Method GetCenter:TPoint()
		'print "DoorCenter: " + Room.Pos.x + "/" + Room.Pos.y + " => " + (Room.Pos.x + Room.doorwidth/2) + "/" + (Building.GetFloorY(Room.Pos.y) - Room.doorheight/2) + "    GetFloorY: " + Building.GetFloorY(Room.Pos.y) + " ... GetFloor: " + Building.GetFloor(Room.Pos.y)
		Return TPoint.Create(Room.Pos.x + Room.doorwidth/2, Building.GetFloorY(Room.Pos.y) - Room.doorheight/2, -15)
	End Method

	Method IsMovable:int()
		Return False
	End Method
	
	Method GetIsHearable:int()
		if Room.name = "" OR Room.name = "roomboard" OR Room.name = "credits" OR Room.name = "porter" then Return false	
		Return (Players[Game.playerID].Figure.inRoom = null) or IsGamePlayerAction
	End Method
	
	Method GetChannelForSfx:TSfxChannel(sfx:string)
		Select sfx
			Case SFX_OPEN_DOOR
				Return GetSfxChannelByName(SFX_OPEN_DOOR)
			Case SFX_CLOSE_DOOR
				Return GetSfxChannelByName(SFX_CLOSE_DOOR)
		EndSelect		
	End Method
	
	Method GetSfxSettings:TSfxSettings(sfx:string)
		Return GetDoorOptions()
	End Method
	
	Method OnPlaySfx:int(sfx:string)
		Return True
	End Method	
	
	Method GetDoorOptions:TSfxSettings()
		local result:TSfxSettings = new TSfxFloorSoundBarrierSettings
		result.nearbyDistanceRange = 60
		result.maxDistanceRange = 500
		result.nearbyRangeVolume = 0.6
		result.midRangeVolume = 0.2
		result.minVolume = 0
		Return result
	End Method
	
	Method GetPlayerBeforeDoorSettings:TSfxSettings()
		local result:TSfxSettings = GetDoorOptions()
		result.forceVolume = true
		result.forcePan = true
		result.forceDepth = true		
		result.defaultVolume = 0.5
		result.defaultPan = 0
		result.defaultDepth = -1
		Return result	
	End Method
	
	Method GetPlayerBehindDoorSettings:TSfxSettings()
		local result:TSfxSettings = GetDoorOptions()
		result.forceVolume = true
		result.forcePan = true
		result.forceDepth = true		
		result.defaultVolume = 0.5
		result.defaultPan = 0
		result.defaultDepth = 1
		Return result	
	End Method
	
End Type

Type TFigureSoundSource Extends TSoundSourceElement
	Field Figure:TFigures
	
	Function Create:TFigureSoundSource (_figure:TFigures)
		local result:TFigureSoundSource = new TFigureSoundSource 
		result.Figure= ­_figure
		
		result.AddDynamicSfxChannel("Steps")
		
		return result
	End Function
	
	Method GetID:string()
		Return "Figure: " + Figure.name
	End Method

	Method GetCenter:TPoint()
		Return Figure.rect.GetAbsoluteCenterPoint()
	End Method

	Method IsMovable:int()
		Return ­true
	End Method
	
	Method GetIsHearable:int()
		Return (Players[Game.playerID].Figure.inRoom = null)
	End Method
	
	Method GetChannelForSfx:TSfxChannel(sfx:string)
		Select sfx
			Case SFX_STEPS
				Return GetSfxChannelByName("Steps")
		EndSelect		
	End Method
	
	Method GetSfxSettings:TSfxSettings(sfx:string)
		Select sfx
			Case SFX_STEPS
				Return GetStepsSettings()
		EndSelect						
	End Method
	
	Method OnPlaySfx:int(sfx:string)
		Return true
	End Method
	
	Method GetStepsSettings:TSfxSettings()
		local result:TSfxSettings = new TSfxFloorSoundBarrierSettings
		result.nearbyDistanceRange = 60
		result.maxDistanceRange = 300
		result.nearbyRangeVolume = 0.15
		result.midRangeVolume = 0.05
		result.minVolume = 0
		Return result
	End Method	
End Type