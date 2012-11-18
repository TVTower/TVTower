Type TSfxFloorSoundBarrierSettings Extends TSfxSettings

	Method GetVolumeByDistance:float(source:TSoundSourceElement, receiver:TElementPosition)
		local currentDistance:int = source.GetCenter().DistanceTo(receiver.getCenter())
	
		local result:float = midRangeVolume
		If (currentDistance <> -1) Then
			If currentDistance > Self.maxDistanceRange Then 'zu weit weg
				result = Self.minVolume
			Elseif currentDistance < Self.nearbyDistanceRange Then 'sehr nah dran
				result = Self.nearbyRangeVolume
			Else 'irgendwo dazwischen
				result = midRangeVolume * (float(Self.maxDistanceRange) - float(currentDistance)) / float(Self.maxDistanceRange)
			Endif
		Endif

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
	
	Method PlaySfx(sfx:string)		
		print "Quelle: " + GetCenter().x + "/" + GetCenter().y + "/" + GetCenter().z + " = " + sfx
		print "Meine Methode1: " + Building.getFloorByPoint(GetCenter())
		print "getFloor: " + Building.getFloor(GetCenter().y)
	
		super.PlaySfx(sfx)
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

	Function Create:TDoorSoundSource(_room:TRooms)
		local result:TDoorSoundSource = new TDoorSoundSource
		result.Room = _room
		
		result.AddDynamicSfxChannel(SFX_OPEN_DOOR)
		result.AddDynamicSfxChannel(SFX_CLOSE_DOOR)
		
		return result
	End Function

	Method GetID:string()
		Return "Door"
	End Method

	Method GetCenter:TPoint()
		Return TPoint.Create(Room.Pos.x + Room.doorwidth/2, Building.pos.y + Building.GetFloorY(Room.Pos.y) - Room.doorheight/2, -15)
	End Method

	Method IsMovable:int()
		Return False
	End Method
	
	Method GetIsHearable:int()
		Return (Players[Game.playerID].Figure.inRoom = null)
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
'		local position:TPoint = GetCenter()
'		local floorY:int = Building.pos.y + Building.GetFloorY(Room.Pos.y)				
				
		local result:TSfxSettings = new TSfxSettings
		result.nearbyDistanceRange = 60
'		result.nearbyDistanceRangeTopY = (floorY - position.y - 73) * -1 '73 = Stockwerkhöhe
'		result.nearbyDistanceRangeBottomY = floorY - position.y
		result.maxDistanceRange = 100			
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