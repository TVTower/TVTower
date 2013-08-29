Type TSfxFloorSoundBarrierSettings Extends TSfxSettings

	Method GetVolumeByDistance:Float(source:TSoundSourceElement, receiver:TElementPosition)
		Local floorNumberSource:Int = Building.getFloorByPixelExactPoint(source.GetCenter())
		Local floorNumberTarget:Int = Building.getFloorByPixelExactPoint(receiver.GetCenter())
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

Type TPlayerElementPosition Extends TElementPosition
	Function Create:TPlayerElementPosition ()
		Return New TPlayerElementPosition
	End Function

	Method GetID:String()
		Return "Player"
	End Method

	Method GetCenter:TPoint()
		Return Game.Players[Game.playerID].Figure.rect.GetAbsoluteCenterPoint()
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

	Method PlaySfx(sfx:String, sfxSettings:TSfxSettings=Null)
		'print "aa1: " + GetCenter().x + "/" + GetCenter().y + " - " + Building.getFloorByPixelExactPoint(GetCenter())
		Super.PlaySfx(sfx)
	End Method

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
		Return (Game.Players[Game.playerID].Figure.inRoom = Null)
	End Method

	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Select sfx
			Case SFX_ELEVATOR_OPENDOOR
				Return GetSfxChannelByName("Door")
			Case SFX_ELEVATOR_CLOSEDOOR
				Return GetSfxChannelByName("Door")
			Case SFX_ELEVATOR_ENGINE
				Return GetSfxChannelByName("Main")
		EndSelect
	End Method

	Method GetSfxSettings:TSfxSettings(sfx:String)
		Select sfx
			Case SFX_ELEVATOR_OPENDOOR
				Return GetDoorOptions()
			Case SFX_ELEVATOR_CLOSEDOOR
				Return GetDoorOptions()
			Case SFX_ELEVATOR_ENGINE
				Return GetEngineOptions()
		EndSelect
	End Method

	Method OnPlaySfx:Int(sfx:String)
		Select sfx
			Case SFX_ELEVATOR_OPENDOOR
				Local engineChannel:TSfxChannel = GetChannelForSfx(SFX_ELEVATOR_ENGINE)
				engineChannel.Stop()
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
	Field Room:TRooms			'Die Raum dieser Türe
	Field IsGamePlayerAction:Int	'
	Field DoorTimer:TIntervalTimer		= TIntervalTimer.Create(1000)'500

	Function Create:TDoorSoundSource(_room:TRooms)
		Local result:TDoorSoundSource = New TDoorSoundSource
		result.Room = _room

		result.AddDynamicSfxChannel(SFX_OPEN_DOOR, True)
		result.AddDynamicSfxChannel(SFX_CLOSE_DOOR, True)

		Return result
	End Function

	Method PlayDoorSfx(sfx:String, figure:TFigures)
		'Die Türsound brauchen eine spezielle Behandlung wenn es sich dabei um einen Spieler handelt der einen Raum betritt oder verlässt.
		'Diese spezielle Behandlung (der Modus) wird durch IsGamePlayerAction = true gekenntzeichnet.
		'Ist dieser Modus aktiv wird ein Timer gestartet welcher das Schließen der Türe nach einiger Zeit abspielt (siehe Update).
		'Dies ist nötig da im normalen Codeablauf das "CloseDoor" von TRooms zu schnell kommt. Dieser Schließensound aus CloseDoor muss in diesem Modus abgefangen werden

		If figure = Game.Players[Game.playerID].Figure 'Dieser Code nur für den aktiven Spieler
			If Not IsGamePlayerAction 'Wenn wir uns noch nicht im Spezialmodus befinden, dann weiter prüfen ob man ihn gleich aktiv schalten muss
				If sfx = SFX_OPEN_DOOR 'Nur der Open-Sound kann den Spezialmodus starten
					If DoorTimer.isExpired() 'Ist der Timer abgelaufen?
						IsGamePlayerAction = True 'Den Modus starten
						If Game.Players[Game.playerID].Figure.inRoom = Null 'von draußen (Flur) nach drinen (Raum)
							If Room.occupant Then IsGamePlayerAction = False 'Ein kleiner Hack: Wenn der Raum besetzt ist, dann soll das mit dem Modus doch nicht durchgeführt werden
							PlaySfx(sfx, GetPlayerBeforeDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler vor der Türe (Depth)
						Else 'von drinnen (Raum) nach draußen (Flur)
							PlaySfx(sfx, GetPlayerBehindDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler hinter der Türe (Depth) (im Raum)
						EndIf
						DoorTimer.reset() 'den Close auf Timer setzen...
					Else 'In dem Fall ist die Türe also noch offen
						DoorTimer.reset() 'Den Schließen-Sound verschieben.
					EndIf
				ElseIf sfx = SFX_CLOSE_DOOR
					PlaySfx(sfx)
				EndIf
			EndIf
		Else
			PlaySfx(sfx)
		EndIf
	End Method

	Method Update()
		If IsGamePlayerAction
			If DoorTimer.isExpired() 'Wenn der Timer abgelaufen, dann den Türschließsound spielen
				If Game.Players[Game.playerID].Figure.inRoom = Null
					PlaySfx(SFX_CLOSE_DOOR, GetPlayerBeforeDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler vor der Türe (Depth)
				Else
					PlaySfx(SFX_CLOSE_DOOR, GetPlayerBehindDoorSettings()) 'den Sound abspielen... mit den Settings als wäre der Spieler hinter der Türe (Depth) (im Raum)
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
		'print "DoorCenter: " + Room.Pos.x + "/" + Room.Pos.y + " => " + (Room.Pos.x + Room.doorwidth/2) + "/" + (Building.GetFloorY(Room.Pos.y) - Room.doorheight/2) + "    GetFloorY: " + Building.GetFloorY(Room.Pos.y) + " ... GetFloor: " + Building.GetFloor(Room.Pos.y)
		Return TPoint.Create(Room.Pos.x + Room.doorDimension.x/2, Building.GetFloorY(Room.Pos.y) - Room.doorDimension.y/2, -15)
	End Method

	Method IsMovable:Int()
		Return False
	End Method

	Method GetIsHearable:Int()
		If Room.name = "" Or Room.name = "roomboard" Or Room.name = "credits" Or Room.name = "porter" Then Return False
		Return (Game.Players[Game.playerID].Figure.inRoom = Null) Or IsGamePlayerAction
	End Method

	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Select sfx
			Case SFX_OPEN_DOOR
				Return GetSfxChannelByName(SFX_OPEN_DOOR)
			Case SFX_CLOSE_DOOR
				Return GetSfxChannelByName(SFX_CLOSE_DOOR)
		EndSelect
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
	Field Figure:TFigures
	Field ChannelInitialized:Int = 0

	Function Create:TFigureSoundSource (_figure:TFigures)
		Local result:TFigureSoundSource = New TFigureSoundSource
		result.Figure= ­_figure
		'result.AddDynamicSfxChannel("Steps" + result.Figure.name)

		Return result
	End Function

	Method GetID:String()
		Return "Figure" + Figure.id
	End Method

	Method GetCenter:TPoint()
		Return Figure.rect.GetAbsoluteCenterPoint()
	End Method

	Method IsMovable:Int()
		Return ­True
	End Method

	Method GetIsHearable:Int()
		Return (Game.Players[Game.playerID].Figure.inRoom = Null)
	End Method

	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Select sfx
			Case SFX_STEPS
				If Not Self.ChannelInitialized
					Self.AddDynamicSfxChannel("Steps" + Self.GetID()) 'Channel erst hier hinzufügen... am Anfang hat Figure noch keine id
					Self.ChannelInitialized = True
				EndIf

				Return GetSfxChannelByName("Steps" + Self.GetID())
		EndSelect
	End Method

	Method GetSfxSettings:TSfxSettings(sfx:String)
		Select sfx
			Case SFX_STEPS
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