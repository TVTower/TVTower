Type TSfxFloorSoundBarrierSettings Extends TSfxSettings

	Method GetVolumeByDistance:Float(source:TSoundSourceElement, receiver:TSoundSourcePosition)
		Local floorNumberSource:Int = TBuilding.getFloorByPixelExactPoint(source.GetCenter())
		Local floorNumberTarget:Int = TBuilding.getFloorByPixelExactPoint(receiver.GetCenter())
		Local floorDistance:Int = TPoint.DistanceOfValues(floorNumberSource, floorNumberTarget)
'		print "floorDistance: " + floorDistance + " - " + Exponential(0.5, floorDistance) + " # " + floorNumberSource + " $ " + floorNumberTarget
		Return Super.GetVolumeByDistance(source, receiver) * Exponential(0.5, floorDistance)
	End Method

	Method Exponential:Float(base:Float, expo:Float)
'		print "Exponential1: " + base + " - " + expo
		Local result:Float = base
		If expo >= 2
			For Local i:Int = 1 To expo - 1
				result = result * base
			Next
		EndIf
'		print "Exponential2: " + result
		Return result
	End Method

End Type

Type TPlayerSoundSourcePosition Extends TSoundSourcePosition
	Function Create:TPlayerSoundSourcePosition ()
		Return New TPlayerSoundSourcePosition
	End Function

	Method GetID:String()
		Return "Player"
	End Method

	Method GetCenter:TPoint()
		Return GetPlayerCollection().Get().Figure.area.GetAbsoluteCenterPoint()
	End Method

	Method GetIsVisible:Int()
		Return True
	End Method

	Method IsMovable:Int()
		Return False 'Bedeutet das es nicht überwacht wird. Speziell beim Player
	End Method
End Type


Type TElevatorSoundSource Extends TSoundSourceElement
	Field Elevator:TElevator = Null
	Field Movable:Int = True

	Function Create:TElevatorSoundSource(_elevator:TElevator, _movable:Int)
		Local result:TElevatorSoundSource  = New TElevatorSoundSource
		result.Elevator = _elevator
		result.Movable = ­_movable

		result.AddDynamicSfxChannel("Main")
		result.AddDynamicSfxChannel("Door")

		Return result
	End Function

	Method GetID:String()
		Return "Elevator"
	End Method

	Method GetCenter:TPoint()
		Return Elevator.GetElevatorCenterPos()
	End Method

	Method IsMovable:Int()
		Return ­Movable
	End Method

	Method GetIsHearable:Int()
		Return (GetPlayerCollection().Get().Figure.inRoom = Null)
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

Type TDoorSoundSource Extends TSoundSourceElement
	Field door:TRoomDoor
	Field IsGamePlayerAction:Int
	Field DoorTimer:TIntervalTimer = TIntervalTimer.Create(1000) '500

	Function Create:TDoorSoundSource(door:TRoomDoor)
		Local result:TDoorSoundSource = New TDoorSoundSource
		result.door = door

		'instead of pre-registering all events and channels, we do it
		'during requesting a channel
		'result.AddDynamicSfxChannel(SFX_OPEN_DOOR, True)
		'result.AddDynamicSfxChannel(SFX_CLOSE_DOOR, True)

		Return result
	End Function

	Method PlayOpenDoorSfx(figure:TFigure)
		'Die Türsound brauchen eine spezielle Behandlung wenn es sich dabei um einen Spieler handelt der einen Raum betritt oder verlässt.
		'Diese spezielle Behandlung (der Modus) wird durch IsGamePlayerAction = true gekenntzeichnet.
		'Ist dieser Modus aktiv wird ein Timer gestartet welcher das Schließen der Türe nach einiger Zeit abspielt (siehe Update).
		'Dies ist nötig da im normalen Codeablauf das "CloseDoor" von TRooms zu schnell kommt. Dieser Schließensound aus CloseDoor muss in diesem Modus abgefangen werden

		If figure = GetPlayerCollection().Get().Figure 'Dieser Code nur für den aktiven Spieler
			If Not IsGamePlayerAction 'Wenn wir uns noch nicht im Spezialmodus befinden, dann weiter prüfen ob man ihn gleich aktiv schalten muss
				If DoorTimer.isExpired() 'Ist der Timer abgelaufen?
					IsGamePlayerAction = True 'Den Modus starten
					If GetPlayerCollection().Get().Figure.inRoom = Null 'von draußen (Flur) nach drinen (Raum)
						If door.room.hasOccupant() Then IsGamePlayerAction = False 'Ein kleiner Hack: Wenn der Raum besetzt ist, dann soll das mit dem Modus doch nicht durchgeführt werden
						PlayRandomSfx("door_open", GetPlayerBeforeDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler vor der Türe (Depth)
					Else 'von drinnen (Raum) nach draußen (Flur)
						PlayRandomSfx("door_close", GetPlayerBehindDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler hinter der Türe (Depth) (im Raum)
					EndIf
					DoorTimer.reset() 'den Close auf Timer setzen...
				Else 'In dem Fall ist die Türe also noch offen
					DoorTimer.reset() 'Den Schließen-Sound verschieben.
				EndIf
			EndIf
		Else
			PlayRandomSfx("door_open")
		EndIf
	End Method


	Method PlayCloseDoorSfx(figure:TFigure)
		'Die Türsound brauchen eine spezielle Behandlung wenn es sich dabei um einen Spieler handelt der einen Raum betritt oder verlässt.
		'Diese spezielle Behandlung (der Modus) wird durch IsGamePlayerAction = true gekenntzeichnet.
		'Ist dieser Modus aktiv wird ein Timer gestartet welcher das Schließen der Türe nach einiger Zeit abspielt (siehe Update).
		'Dies ist nötig da im normalen Codeablauf das "CloseDoor" von TRooms zu schnell kommt. Dieser Schließensound aus CloseDoor muss in diesem Modus abgefangen werden

		 'Dieser Code nur für den aktiven Spieler
		If figure = GetPlayerCollection().Get().Figure
			If Not IsGamePlayerAction then PlayRandomSfx("door_close")
		Else
			PlayRandomSfx("door_close")
		EndIf
	End Method


	Method Update()
		If IsGamePlayerAction
			If DoorTimer.isExpired() 'Wenn der Timer abgelaufen, dann den Türschließsound spielen
				If GetPlayerCollection().Get().Figure.inRoom = Null
					PlayRandomSfx("door_close", GetPlayerBeforeDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler vor der Türe (Depth)
				Else
					PlayRandomSfx("door_close", GetPlayerBehindDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler hinter der Türe (Depth) (im Raum)
				EndIf
				IsGamePlayerAction = False 'Modus beenden
			EndIf
		EndIf

		Super.Update()
	End Method

	Method GetID:String()
		Return "Door"
	End Method

	Method GetCenter:TPoint()
		'print "DoorCenter: " + Room.Pos.x + "/" + Room.Pos.y + " => " + (Room.Pos.x + Room.doorwidth/2) + "/" + (Building.GetFloorY(Room.Pos.y) - Room.doorheight/2) + "    GetFloorY: " + TBuilding.GetFloorY(Room.Pos.y) + " ... GetFloor: " + Building.GetFloor(Room.Pos.y)
		Return new TPoint.Init(door.area.GetX() + door.area.GetW()/2, TBuilding.GetFloorY(door.area.GetY()) - door.area.GetH()/2, -15)
	End Method

	Method IsMovable:Int()
		Return False
	End Method

	Method GetIsHearable:Int()
		If not door.isVisible() then Return False
		'If door.room.name = "" Or door.room.name = "roomboard" Or Room.name = "credits" Or Room.name = "porter" Then Return False
		Return GetPlayerCollection().Get().Figure.inRoom = Null Or IsGamePlayerAction
	End Method

	Method GetChannelForSfx:TSfxChannel(sfx:String)
		local result:TSfxChannel = GetSfxChannelByName(sfx)
		if result = null
			'TLogger.log("TDoorSoundSource.GetChannelForSfx()", "SFX ~q"+sfx+"~q was not defined for room ~q"+self.room.name+"~q yet. Registered Channel for this SFX.", LOG_DEBUG)
			result = self.AddDynamicSfxChannel(sfx, True)
		endif
		return result
	End Method

	Method GetSfxSettings:TSfxSettings(sfx:String)
		Return GetDoorOptions()
	End Method

	Method OnPlaySfx:Int(sfx:String)
		Return True
	End Method

	Method GetDoorOptions:TSfxSettings()
		Local result:TSfxSettings = New TSfxFloorSoundBarrierSettings
		result.nearbyDistanceRange = 60
		result.maxDistanceRange = 500
		result.nearbyRangeVolume = 0.25
		result.midRangeVolume = 0.12
		result.minVolume = 0
		Return result
	End Method

	Method GetPlayerBeforeDoorSettings:TSfxSettings()
		Local result:TSfxSettings = GetDoorOptions()
		result.forceVolume = True
		result.forcePan = True
		result.forceDepth = True
		result.defaultVolume = 0.3
		result.defaultPan = 0
		result.defaultDepth = -1
		Return result
	End Method

	Method GetPlayerBehindDoorSettings:TSfxSettings()
		Local result:TSfxSettings = GetDoorOptions()
		result.forceVolume = True
		result.forcePan = True
		result.forceDepth = True
		result.defaultVolume = 0.3
		result.defaultPan = 0
		result.defaultDepth = 1
		Return result
	End Method

End Type

Type TFigureSoundSource Extends TSoundSourceElement
	Field Figure:TFigure
	Field ChannelInitialized:Int = 0

	Function Create:TFigureSoundSource (_figure:TFigure)
		Local result:TFigureSoundSource = New TFigureSoundSource
		result.Figure= ­_figure
		'result.AddDynamicSfxChannel("Steps" + result.Figure.name)

		Return result
	End Function

	Method GetID:String()
		Return "Figure" + Figure.id
	End Method

	Method GetCenter:TPoint()
		Return Figure.area.GetAbsoluteCenterPoint()
	End Method

	Method IsMovable:Int()
		Return ­True
	End Method

	Method GetIsHearable:Int()
		Return (GetPlayerCollection().Get().Figure.inRoom = Null)
	End Method

	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Select sfx
			Case "steps"
				If Not Self.ChannelInitialized
					Self.AddDynamicSfxChannel("Steps" + Self.GetID()) 'Channel erst hier hinzufügen... am Anfang hat Figure noch keine id
					Self.ChannelInitialized = True
				EndIf

				Return GetSfxChannelByName("Steps" + Self.GetID())
		EndSelect
	End Method

	Method GetSfxSettings:TSfxSettings(sfx:String)
		Select sfx
			Case "steps"
				Return GetStepsSettings()
		EndSelect
	End Method

	Method OnPlaySfx:Int(sfx:String)
		Return True
	End Method

	Method GetStepsSettings:TSfxSettings()
		Local result:TSfxSettings = New TSfxFloorSoundBarrierSettings
		result.nearbyDistanceRange = 60
		result.maxDistanceRange = 300
		result.nearbyRangeVolume = 0.3
		result.midRangeVolume = 0.1

		'result.nearbyRangeVolume = 0.15
		'result.midRangeVolume = 0.05
		result.minVolume = 0
		Return result
	End Method
End Type



Type TSimpleSoundSource extends TSoundSourceElement
	Field SfxChannels:TMap = CreateMap()

	Function Create:TSimpleSoundSource()
		return New TSimpleSoundSource
	End Function

	Method GetSfxChannelByName:TSfxChannel(name:String)
		Return TSfxChannel(MapValueForKey(SfxChannels, name))
	End Method

	'override default behaviour
	Method PlaySfxOrPlaylist(name:String, sfxSettings:TSfxSettings=Null, playlistMode:int=FALSE)
		TSoundManager.GetInstance().RegisterSoundSource(Self)

		'add channel if not done yet
		if not TSfxChannel(SfxChannels.ValueForKey(name))
			SfxChannels.insert(name, TSfxChannel.Create())
		endif

		Local channel:TSfxChannel = GetChannelForSfx(name)
		Local settings:TSfxSettings = sfxSettings
		If settings = Null Then settings = GetSfxSettings(name)

		if playlistMode
			channel.PlayRandomSfx(name, settings)
		else
			channel.PlaySfx(name, settings)
		endif

		'print GetID() + " # End PlaySfx: " + name
	End Method


	Method Stop(sfx:String)
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		channel.Stop()
	End Method

	Method GetSfxSettings:TSfxSettings(sfx:String)
		local settings:TSfxSettings = TSfxSettings.Create()
		settings.defaultVolume = 1.50
		return settings
	End Method


	Method GetIsHearable:Int()
		return true
	End Method

	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Return GetSfxChannelByName(sfx)
	End Method

	Method GetID:String()
		Return "SimpleSfx"
	End Method

	Method GetCenter:TPoint()
		'print "DoorCenter: " + Room.Pos.x + "/" + Room.Pos.y + " => " + (Room.Pos.x + Room.doorwidth/2) + "/" + (Building.GetFloorY(Room.Pos.y) - Room.doorheight/2) + "    GetFloorY: " + TBuilding.GetFloorY(Room.Pos.y) + " ... GetFloor: " + Building.GetFloor(Room.Pos.y)
		Return new TPoint.Init(GetGraphicsManager().GetWidth()/2, GetGraphicsManager().GetHeight()/2)
	End Method

	Method IsMovable:Int()
		Return False
	End Method

	Method OnPlaySfx:Int(sfx:String)
		return TRUE
	end Method

End Type