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
		local result:TSfxSettings = new TSfxSettings
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
		If figure = Players[Game.playerID].Figure 'Dieser Code nur für den aktiven Spieler
			If Not IsGamePlayerAction 'Wenn wir uns noch nicht im Spezialmodus befinden, dann weiter
				If sfx = SFX_OPEN_DOOR 'Nur der Open-Sound kann den Spezialmodus starten
					'print "Room.used: " + Room.used
					'If Room.used <> 0 'Raum ist auch wirklich leer 
						If DoorTimer.isExpired() 
							IsGamePlayerAction = true
							If Players[Game.playerID].Figure.inRoom = null
								If Room.used >= 0 Then IsGamePlayerAction = false
								PlaySfx(sfx, GetPlayerBeforeDoorSettings()) 'den Sound abspielen
							Else
								'print "1 drinnen -> draußen #############################"
								PlaySfx(sfx, GetPlayerBehindDoorSettings()) 'den Sound abspielen
							Endif						
							DoorTimer.reset() 'den Close auf Timer setzen... 
						Else
							DoorTimer.reset()
						Endif			

					'Endif
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
			If DoorTimer.isExpired() Then	
				If Players[Game.playerID].Figure.inRoom = null
					'print "2 draußen #############################"
					PlaySfx(SFX_CLOSE_DOOR, GetPlayerBeforeDoorSettings())
				Else
					'print "2 drinnen #############################"
					PlaySfx(SFX_CLOSE_DOOR, GetPlayerBehindDoorSettings())
				Endif
				Print "Time close##########################"
				PlayDoorSfx(SFX_CLOSE_DOOR, null)
				IsGamePlayerAction = false
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
		result.nearbyRangeVolume = 0.5
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