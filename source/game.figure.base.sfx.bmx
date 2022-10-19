SuperStrict
Import "Dig/base.sfx.soundmanager.base.bmx"
Import "game.figure.base.bmx"
Import "game.player.base.bmx"
Import "game.building.base.sfx.bmx"


Type TFigureBaseSoundSource Extends TSoundSourceElement
	Field figureID:int
	Field ChannelInitialized:Int = 0

	Function Create:TFigureBaseSoundSource (_figure:TFigureBase)
		Local result:TFigureBaseSoundSource = New TFigureBaseSoundSource
		result.figureID = _figure.id
		'result.AddDynamicSfxChannel("Steps" + result.Figure.name)

		Return result
	End Function

	Method GetClassIdentifier:String()
		Return "Figure" ' + figureID
	End Method


	Method GetCenter:SVec3D() override
		local f:TFigureBase = GetFigureBaseCollection().Get(figureID)
		if f
			local centerVec:SVec2D = f.area.GetAbsoluteCenterSVec()
			return new SVec3D(centerVec.x, centerVec.y, 0)
		EndIf

		Return new SVec3D
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
