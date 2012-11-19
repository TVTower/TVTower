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
	
	Method PlaySfx(sfx:string)			
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
	Field Room:TRooms
	Field IsPlayerAction:int
	Field DoorTimer:TTimer		= TTimer.Create(1000)'500
	Field CloseDoorSoundInRoom:int

	Function Create:TDoorSoundSource(_room:TRooms)
		local result:TDoorSoundSource = new TDoorSoundSource
		result.Room = _room
		
		result.AddDynamicSfxChannel(SFX_OPEN_DOOR, true)
		result.AddDynamicSfxChannel(SFX_CLOSE_DOOR, true)
		
		return result
	End Function

	Method PlayDoorSfx(sfx:string, figure:TFigures)
		If figure <> null Then print "PlayDoorSfx: " + sfx + " = " + room.name +  " (" + figure.name + ")" Else print "PlayDoorSfx: " + sfx + " = " + room.name + " (none)"
		If figure = Players[Game.playerID].Figure
			If IsPlayerAction
				Print "Überhört"
			Else
				If sfx = SFX_OPEN_DOOR
					CloseDoorSoundInRoom = (not (Players[Game.playerID].Figure.inRoom = Room))
					IsPlayerAction = true
					print "IsPlayerAction = true"
					PlaySfx(sfx)
					DoorTimer.reset()
				Elseif sfx = SFX_CLOSE_DOOR
				print "üüü"	
				Endif			
			Endif		
		Else
			PlaySfx(sfx)
		Endif		
	End Method
	
	Method Update()
		If IsPlayerAction
			If DoorTimer.isExpired() Then	
				If CloseDoorSoundInRoom = (Players[Game.playerID].Figure.inRoom = Room)
					PlayDoorSfx(SFX_CLOSE_DOOR, null)
				Endif
				IsPlayerAction = false
				print "IsPlayerAction = false"
				print "----------------------------------------"
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
		Return (Players[Game.playerID].Figure.inRoom = null) or IsPlayerAction
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
		result.nearbyRangeVolume = 1
		result.midRangeVolume = 0.25
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