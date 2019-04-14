SuperStrict
Import "Dig/base.sfx.soundmanager.base.bmx"
Import "game.figure.base.bmx"
Import "game.player.base.bmx"
Import "game.building.base.sfx.bmx"


Type TFigureBaseSoundSource Extends TSoundSourceElement
	Field Figure:TFigureBase
	Field ChannelInitialized:Int = 0

	Function Create:TFigureBaseSoundSource (_figure:TFigureBase)
		Local result:TFigureBaseSoundSource = New TFigureBaseSoundSource
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
		Return (GetPlayerBase() and not GetPlayerBase().IsInRoom())
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
