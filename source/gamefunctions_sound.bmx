Type TPlayerSoundSourcePosition Extends TSoundSourcePosition
	Function Create:TPlayerSoundSourcePosition ()
		Return New TPlayerSoundSourcePosition
	End Function


	Method GetClassIdentifier:String()
		Return "Player"
	End Method
	

	Method GetCenter:TVec3D()
		Return GetPlayer().Figure.area.GetAbsoluteCenterVec().ToVec3D()
	End Method

	Method GetIsVisible:Int()
		Return True
	End Method

	Method IsMovable:Int()
		Return False 'Bedeutet das es nicht überwacht wird. Speziell beim Player
	End Method
End Type


Type TFigureSoundSource Extends TSoundSourceElement
	Field Figure:TFigure
	Field ChannelInitialized:Int = 0

	Function Create:TFigureSoundSource (_figure:TFigure)
		Local result:TFigureSoundSource = New TFigureSoundSource
		result.Figure = _figure
		'result.AddDynamicSfxChannel("Steps" + result.Figure.name)

		Return result
	End Function

	Method GetClassIdentifier:String()
		Return "Figure" ' + Figure.id
	End Method

	Method GetCenter:TVec3D()
		Return Figure.area.GetAbsoluteCenterVec().ToVec3D()
	End Method

	Method IsMovable:Int()
		Return True
	End Method

	Method GetIsHearable:Int()
		Return (GetPlayer() and GetPlayer().GetFigure().inRoom = Null)
	End Method

	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Select sfx
			Case "steps"
				If Not Self.ChannelInitialized
					'Channel erst hier hinzufügen... am Anfang hat Figure noch keine id
					Self.AddDynamicSfxChannel("Steps" + Self.GetGUID())
					Self.ChannelInitialized = True
				EndIf

				Return GetSfxChannelByName("Steps" + Self.GetGUID())
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



Type TSimpleSoundSource Extends TSoundSourceElement
	Field SfxChannels:TMap = CreateMap()

	Function Create:TSimpleSoundSource()
		Return New TSimpleSoundSource
	End Function

	Method GetSfxChannelByName:TSfxChannel(name:String)
		Return TSfxChannel(MapValueForKey(SfxChannels, name))
	End Method

	'override default behaviour
	Method PlaySfxOrPlaylist(name:String, sfxSettings:TSfxSettings=Null, playlistMode:Int=False)
		TSoundManager.GetInstance().RegisterSoundSource(Self)

		'add channel if not done yet
		If Not TSfxChannel(SfxChannels.ValueForKey(name))
			SfxChannels.insert(name, TSfxChannel.Create())
		EndIf

		Local channel:TSfxChannel = GetChannelForSfx(name)
		Local settings:TSfxSettings = sfxSettings
		If settings = Null Then settings = GetSfxSettings(name)

		If playlistMode
			channel.PlayRandomSfx(name, settings)
		Else
			channel.PlaySfx(name, settings)
		EndIf

		'print GetClassIdentifier() + " # End PlaySfx: " + name
	End Method


	Method Stop(sfx:String)
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		channel.Stop()
	End Method

	Method GetSfxSettings:TSfxSettings(sfx:String)
		Local settings:TSfxSettings = TSfxSettings.Create()
		settings.defaultVolume = 1.50
		Return settings
	End Method


	Method GetIsHearable:Int()
		Return True
	End Method

	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Return GetSfxChannelByName(sfx)
	End Method

	Method GetClassIdentifier:String()
		Return "SimpleSfx"
	End Method

	Method GetCenter:TVec3D()
		'print "DoorCenter: " + Room.Pos.x + "/" + Room.Pos.y + " => " + (Room.Pos.x + Room.doorwidth/2) + "/" + (Building.GetFloorY2(Room.Pos.y) - Room.doorheight/2) + "    GetFloorY: " + TBuilding.GetFloorY2(Room.Pos.y) + " ... GetFloor: " + Building.GetFloor(Room.Pos.y)
		Return New TVec3D.Init(GetGraphicsManager().GetWidth()/2, GetGraphicsManager().GetHeight()/2)
	End Method

	Method IsMovable:Int()
		Return False
	End Method

	Method OnPlaySfx:Int(sfx:String)
		Return True
	End Method

End Type