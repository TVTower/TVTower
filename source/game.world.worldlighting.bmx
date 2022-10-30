SuperStrict
Import Brl.Math
Import "Dig/base.util.color.bmx"
Import "game.world.worldtime.bmx"


Type TWorldLighting
	'scene ambient color used for full daylight.
	Field fullLight:SColor8
	'scene ambient color used for full night.
	Field fullDark:SColor8
	'scene fog color to use at dawn and dusk.
	Field dawnDuskFog:SColor8
	'scene fog color to use during the day.
	Field dayFog:SColor8
	'scene fog color to use at night.
	Field nightFog:SColor8

	'color to use now
	Field currentLight:TColor
	'fog color to use now
	Field currentFogColor:TColor

	Field _lightIntensity:Float
	Field _lightIntensityBase:Float = 1.0


	'Set values for an acceptable day/night cycle effect
	Method Init:TWorldLighting()
		'=== SETUP CONFIGURATION ===
		fullDark = new SColor8(32, 28, 46)
		fullLight = new SColor8(190, 215, 245)
		dawnDuskFog = new SColor8(240, 212, 171)
		dayFog = new SColor8(225, 240, 255)
		nightFog = new SColor8(15, 30, 80)

		currentLight = new TColor().CopyFrom(fullLight)
		currentFogColor = new TColor().CopyFrom(dayFog)

		return Self
	End Method


	'returns the brightness compared to full light brightness
	Method GetSkyBrightness:Float()
		return Max(0.0, Min(1.0, currentLight.GetBrightness() / SColor8Helper.GetBrightness(fullLight)))
	End Method


	'adjust environment light color between full dark and full light
	Method _UpdateDaylight()
		Select GetWorldTime().GetDayPhase()
			Case GetWorldTime().DAYPHASE_DAY
				_lightIntensity = _lightIntensityBase
				currentLight.CopyFrom(fullLight)

			Case GetWorldTime().DAYPHASE_NIGHT
				_lightIntensity = 0
				currentLight.CopyFrom(fullDark)

			Case GetWorldTime().DAYPHASE_DAWN
				local relativeTime:Float = GetWorldTime().GetDayTime() - GetWorldTime().GetDawnPhaseBegin()
				currentLight.CopyFrom( SColor8Helper.Mix(fullDark, fullLight, relativeTime / GetWorldTime().GetDawnDuration()) )
				_lightIntensity = _lightIntensityBase * (relativeTime / GetWorldTime().GetDawnDuration())

			Case GetWorldTime().DAYPHASE_DUSK
				local relativeTime:Float = GetWorldTime().GetDayTime() - GetWorldTime().GetDuskPhaseBegin()
				currentLight.CopyFrom( SColor8Helper.Mix(fullLight, fullDark, relativeTime / GetWorldTime().GetDuskDuration()) )
				_lightIntensity = _lightIntensityBase * (1.0 - (relativeTime / GetWorldTime().GetDuskDuration()))
		End Select
	End Method


	'Interpolates fog color between the specified phase colors during
	'each phase's transition.
	'eg. From DawnDusk to Day, Day to DawnDusk, DawnDusk to Night, and
	'    Night to DawnDusk
	Method _UpdateFog()
		local relativeTime:Float
		local progress:Float
		local time:TWorldtime = GetWorldTime()

		Select time.GetDayPhase()
			Case time.DAYPHASE_DAWN
				relativeTime = time.GetDayTime() - time.GetDawnPhaseBegin()

				if relativeTime / time.GetDawnDuration() < 0.25
					'fade from 50-100% (begun in night): 0.5 + x
					'x = max 0.5
					progress = 0.5 + 2* relativeTime / time.GetDawnDuration()
					progress :- 0.05
					currentFogColor.CopyFrom( SColor8Helper.Mix(nightFog, dawnDuskFog, progress) )
				elseif relativeTime / time.GetDawnDuration() < 0.75
					currentFogColor.CopyFrom( dawnDuskFog )
				else
					'fade from 0-50%
					progress = ((relativeTime / time.GetDawnDuration()) - 0.75) * 2
					currentFogColor.CopyFrom( SColor8Helper.Mix(dawnDuskFog, dayFog, progress) )
				endif

			Case time.DAYPHASE_DAY
				relativeTime = time.GetDayTime() - time.GetDayPhaseBegin()

				if relativeTime / time.GetDayDuration() < 0.25
					'fade from 50-100% (begun in night): 0.5 + x
					'x = max 0.5
					progress = 0.5 + 2* relativeTime / time.GetDayDuration()
					currentFogColor.CopyFrom( SColor8Helper.Mix(dawnDuskFog, dayFog, progress) )
				elseif relativeTime / time.GetDayDuration() < 0.75
					currentFogColor.CopyFrom( dayFog )
				else
					'fade from 0-50%
					progress = ((relativeTime / time.GetDayDuration()) - 3.0/4) * 2.0
					currentFogColor.CopyFrom( SColor8Helper.Mix(dayFog, dawnDuskFog, progress) )
				endif

			Case time.DAYPHASE_DUSK
				relativeTime = time.GetDayTime() - time.GetDuskPhaseBegin()

				if relativeTime / time.GetDuskDuration() < 0.25
					'fade from 50-100% (begun in night): 0.5 + x
					'x = max 0.5
					progress = 0.5 + 2* relativeTime / time.GetDuskDuration()
					currentFogColor.CopyFrom( SColor8Helper.Mix(dayFog, dawnDuskFog, progress) )
				elseif relativeTime / time.GetDuskDuration() < 0.75
					currentFogColor.CopyFrom( dawnDuskFog )
				else
					'fade from 0-50%
					progress = ((relativeTime / time.GetDuskDuration()) - 3.0/4) * 2.0
					currentFogColor.CopyFrom( SColor8Helper.Mix(dawnDuskFog, nightFog, progress) )
				endif

			Case time.DAYPHASE_NIGHT
				'the time from 0 - dawn
				if time.GetDayTime() < time.GetDawnPhaseBegin()
					relativeTime = time.GetDayTime() + time.DAYLENGTH - time.GetNightPhaseBegin()
				'the time from dusk - 0
				elseif time.GetDayTime() > time.GetDuskPhaseBegin()
					relativeTime = time.GetDayTime() - time.GetNightPhaseBegin()
				else
					relativeTime = 1.0
				endif

				if relativeTime / time.GetNightDuration() < 0.25
					'fade from 50-100% (begun in night): 0.5 + x
					'x = max 0.5
					progress = 0.5 + 2* relativeTime / time.GetNightDuration()
					currentFogColor.CopyFrom( SColor8Helper.Mix(dawnDuskFog, nightFog, progress) )
				elseif relativeTime / time.GetNightDuration() < 0.75
					currentFogColor.CopyFrom( nightFog )
				else
					'fade from 0-50%
					progress = ((relativeTime / time.GetNightDuration()) - 3.0/4) * 2.0
					currentFogColor.CopyFrom( SColor8Helper.Mix(nightFog, dawnDuskFog, progress) )
				endif
		End Select
	End Method


	Method Update:int()
		_UpdateDaylight()
		_UpdateFog()
	End Method
End Type