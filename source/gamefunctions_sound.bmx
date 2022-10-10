Type TPlayerSoundSourcePosition Extends TSoundSourcePosition
	Function Create:TPlayerSoundSourcePosition ()
		Return New TPlayerSoundSourcePosition
	End Function


	Method GetClassIdentifier:String()
		Return "Player"
	End Method
	

	Method GetCenter:SVec3D()
		Local centerVec:SVec2D = GetPlayer().Figure.area.GetAbsoluteCenterSVec()
		Return new SVec3D(centerVec.x, centerVec.y, 0)
	End Method


	Method GetIsVisible:Int()
		Return True
	End Method

	Method IsMovable:Int()
		Return False 'Bedeutet das es nicht überwacht wird. Speziell beim Player
	End Method
End Type




Type TSimpleSoundSource Extends TSoundSourceElement
	Field SfxChannels:TMap = CreateMap()
	Global channelsMutex:TMutex = CreateMutex()

	Function Create:TSimpleSoundSource()
		Return New TSimpleSoundSource
	End Function

	Method GetSfxChannelByName:TSfxChannel(name:String)
		Local channel:TSfxChannel
		LockMutex(channelsMutex)
			channel = TSfxChannel(MapValueForKey(SfxChannels, name))
		UnlockMutex(channelsMutex)
		return channel
	End Method
	
	
	Method AddChannel(name:String, channel:TSfxChannel)
		LockMutex(channelsMutex)
			SfxChannels.insert(name, channel)
		UnlockMutex(channelsMutex)
	End Method

	'override default behaviour
	Method PlaySfxOrPlaylist(name:String, sfxSettings:TSfxSettings=Null, playlistMode:Int=False)
		TSoundManager.GetInstance().RegisterSoundSource(Self)

		Local channel:TSfxChannel = GetChannelForSfx(name)
		'add channel if not done yet
		If not channel 
			channel = TSfxChannel.Create()
			'if channel getter and creator failed, just return silently
			if not channel then return

			AddChannel(name, TSfxChannel.Create())
		EndIf

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
		if channel then channel.Stop()
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

	Method GetCenter:SVec3D()
		'print "DoorCenter: " + Room.Pos.x + "/" + Room.Pos.y + " => " + (Room.Pos.x + Room.doorwidth/2) + "/" + (Building.GetFloorY2(Room.Pos.y) - Room.doorheight/2) + "    GetFloorY: " + TBuilding.GetFloorY2(Room.Pos.y) + " ... GetFloor: " + Building.GetFloor(Room.Pos.y)
		Return New SVec3D(GetGraphicsManager().GetWidth()/2, GetGraphicsManager().GetHeight()/2, 0)
	End Method

	Method IsMovable:Int()
		Return False
	End Method

	Method OnPlaySfx:Int(sfx:String)
		Return True
	End Method

End Type
