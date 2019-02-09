SuperStrict
Import "Dig/base.util.deltatimer.bmx"
Import "Dig/base.util.graphicsmanagerbase.bmx"

Import "game.world.worldlighting.bmx"
Import "game.world.worldtime.bmx"
Import "game.world.worldweather.bmx"
Import "game.world.weathereffects.bmx"

Type TWorld
	Field weather:TWorldWeather
	Field lighting:TWorldLighting
	Field area:TRectangle

	'=== RAIN ===
	'rain effect (rain drops)
	Field rainEffect:TWeatherEffectRain {nosave}
	'snow effect (flakes)
	Field snowEffect:TWeatherEffectSnow {nosave}
	'lightning effects
	Field lightningEffect:TWeatherEffectLightning {nosave}
	'adjust DayNightCycle-color according this weather color
	Field rainColorFadeState:TFadingState = New TFadingState
	Field rainColorFadeDuration:Int = 1000

	'=== CLOUDS ===
	Field cloudEffect:TWeatherEffectClouds {nosave}
	Field cloudColorFadeState:TFadingState = New TFadingState
	Field cloudColorFadeDuration:Int = 1000

	'=== STARS ===
	Field starsBrightness:Int = 150
	Field stars:TVec3D[60]						{nosave}


	'point sun and moon rotate around
	Field centerPoint:TVec2D
	'starting point of the sun - defines distance to centerPoint
	Field sunPoint:TVec2D
	'starting point of the moon - defines distance to centerPoint
	Field moonPoint:TVec2D

	'the skyGradient draws a little gradient at the background eg. to
	'indicate a sunrise
	Field skyGradient:TSprite {nosave}
	Field skyMoon:TSprite {nosave}
	Field skySun:TSprite {nosave}
	Field skySunRays:TSprite {nosave}

	Field currentCloudColor:TColor
	Field currentWindVelocity:Float
	Field newWindVelocity:Float

	Field showRain:Int = True
	Field showLightning:Int = True
	Field showSnow:Int = True
	Field showClouds:Int = True
	Field showSun:Int = True
	Field showStars:Int = True
	Field showMoon:Int = True
	Field showSkyGradient:Int = True

	'disable if rendering effects on your own (other layer)
	Field autoRenderRain:Int = True
	Field autoRenderSnow:Int = True
	Field autoRenderClouds:Int = True
	Field autoRenderLightning:Int = True

	Global useClsMethod:Int = True
	'reference to a world configuration data set
	Global _config:TData
	Global _instance:TWorld


	Function GetInstance:TWorld()
		If Not _instance Then _instance = New TWorld
		Return _instance
	End Function


	Method Initialize:Int()
		area = New TRectangle.Init(0,0,800,385)
		centerPoint = New TVec2D.Init(400, 570 + area.GetY())
		sunPoint = New TVec2D.Init(400, 1100 + area.GetY())
		moonPoint =  New TVec2D.Init(400, 100 + area.GetY())

		If Not weather Then weather = New TWorldWeather
		If Not lighting Then lighting = New TWorldLighting
		weather.Init(0, 18, 0, 3600)
		lighting.Init()

		'adjust effect display
		RenewConfiguration()

		'we do not save stars in savegames, so we externalized
		'initialization to make it more convenient to call
		InitStars(GetConfiguration().GetInt("starsAmount", 60))
	End Method


	Method SetSpeed:Int(newSpeed:Int)
		'newSpeed = Min(50000, Max(1, newSpeed))
		GetWorldTime().SetTimeFactor(newSpeed)
	End Method


	Function SetConfiguration:Int(config:TData)
		_config = config

		GetInstance().RenewConfiguration()
	End Function


	Function GetConfiguration:TData()
		If Not _config Then _config = New TData
		Return _config
	End Function


	'renews settings whether to display certain effects
	Method RenewConfiguration:Int(config:TData = Null)
		If Not config Then config = GetConfiguration()

		showRain = config.GetBool("showRain", True)
		showLightning = config.GetBool("showLightning", True)
		showSnow = config.GetBool("showSnow", True)
		showClouds = config.GetBool("showClouds", True)
		showSun = config.GetBool("showSun", True)
		showStars = config.GetBool("showStars", True)
		showMoon = config.GetBool("showMoon", True)
		showSkyGradient = config.GetBool("showSkyGradient", True)
	End Method


	Method InitSky:Int(gradient:TSprite, moon:TSprite, sun:TSprite, sunRays:TSprite)
		skyGradient = gradient
		skyMoon = moon
		skySun = sun
		skySunRays = sunRays
	End Method


	Method InitSnowEffect:Int(startFlakes:Int = 10, sprites:TSprite[])
		'to make effect start "offscreen" we increase size a bit
		Local effectArea:TRectangle = area.copy()
		effectArea.position.AddX(-50)
		effectArea.dimension.AddX(50)
		snowEffect = New TWeatherEffectSnow.Init(effectArea, startFlakes, sprites)
	End Method


	Method InitRainEffect:Int(layers:Int = 2, sprites:TSprite[])
		'to make effect start "offscreen" we increase size a bit
		Local effectArea:TRectangle = area.copy()
		effectArea.position.AddX(-50)
		effectArea.dimension.AddX(50)
		rainEffect = New TWeatherEffectRain.Init(effectArea, layers, sprites)
	End Method


	Method InitLightningEffect:Int(sprites:TSprite[], spritesSide:TSprite[])
		lightningEffect = New TWeatherEffectLightning.Init(area.copy(), 1, sprites, spritesSide)
	End Method


	Method InitCloudEffect:Int(cloudAmount:Int = 30, sprites:TSprite[])
		cloudEffect = New TWeatherEffectClouds.Init(area.copy(), cloudAmount, sprites)
	End Method


	Method InitStars:Int(starCount:Int = 60)
		stars = stars[..starCount]

		'=== SETUP STARS ===
		For Local i:Int = 0 Until stars.length
			stars[i] = New TVec3D.Init(Rand(Int(area.GetX()), Int(area.GetX2())), Rand(Int(area.GetY()), Int(area.GetY2())), 50+Rand(0,StarsBrightness-50))
		Next
	End Method


	Method UpdateEffects:Int()
		'=== RAIN ===
		If showRain And rainEffect
			'stop rain if it is too cold for water. Snow does the
			'opposite thing
			If Weather.GetTemperature() < 0
				If rainEffect.IsActive() Then rainEffect.Stop()
			Else
				'means rain and snow
				If Weather.IsRaining()
					If Not rainEffect.IsActive() Then rainEffect.Start()
				Else
					If rainEffect.IsActive() Then rainEffect.Stop()
				EndIf
			EndIf

			'inform rain about current wind
			rainEffect.windVelocity = Weather.GetWindVelocity()

			rainEffect.Update()
		EndIf


		'=== SNOW ===
		If showSnow And snowEffect
			'stop snow if it is too warm for ice. Rain does the
			'opposite thing
			If Weather.GetTemperature() >= 0
				If snowEffect.IsActive() Then snowEffect.Stop()
			Else
				'means rain and snow
				If Weather.IsRaining()
					If Not snowEffect.IsActive() Then snowEffect.Start()
				Else
					If snowEffect.IsActive() Then snowEffect.Stop()
				EndIf
			EndIf
			snowEffect.Update()
		EndIf


		'=== LIGHTNING ===
		If showLightning And lightningEffect
			'storm or severe storm?
			If Weather.IsRaining() >= 4
				If Not lightningEffect.IsActive() Then lightningEffect.Start()
			Else
				If lightningEffect.IsActive() Then lightningEffect.Stop()
			EndIf

			lightningEffect.Update()
		EndIf


		'=== ADJUST CLOUD COLOR ===
		If showClouds And cloudEffect
			cloudEffect.skyBrightness = lighting.GetSkyBrightness()

			'brightness changed?
			If Weather.GetCloudBrightness() <> cloudEffect.cloudBrightness
				If Not cloudColorFadeState.GetState()
					'start fader
					cloudColorFadeState.SetState(True, cloudColorFadeDuration)
				Else
					'reset fade state
					cloudColorFadeState.SetState(False, 0)
					'set new brightness
					cloudEffect.cloudBrightness = Weather.GetCloudBrightness()
				EndIf

				If cloudColorFadeState.IsFading() Or cloudEffect.cloudBrightness = 100
					Local factor:Float = cloudColorFadeState.GetFadeProgress()
					If cloudColorFadeState.IsFadingOff() Then factor = 1.0 - factor

					factor = cloudEffect.cloudBrightness*(1.0-factor) + Weather.GetCloudBrightNess()*factor
					factor :/ 100.0
					'if simple grey clouds:
					'cloudColor = TColor.CreateGrey(factor * 255)
					'or advanced:
					cloudEffect.cloudColor = cloudEffect.cloudColorBase.copy().AdjustRelative(-1 + factor)
				EndIf
			EndIf


			'=== ADJUST CLOUDS MOVEMENT ===
			Local wrapClouds:Int = Weather.GetWeather() <> Weather.WEATHER_CLEAR
			Local windStrength:Float = Weather.GetWindVelocity() * 0.5
			If windStrength = 0.0 Then windStrength = 0.1

			cloudEffect.AdjustCloudMovement(windStrength, Int(weather.GetTimeSinceUpdate()), wrapClouds)
		EndIf
	End Method


	Method UpdateWeather:Int()
		'time for another weather update?
		If Weather And Weather.NeedsUpdate()
			'to always have 48 hours "prediction" we need
			'updateWeatherEvery/3600 * 24 entries
			Weather.GenerateUpcomingWeather(Int(Weather.weatherInterval/3600.0 * 24))

			'update the weather
			Weather.Update()

			'store current velocity
			If cloudEffect Then cloudEffect.StoreCloudVelocity()
		EndIf
	End Method


	Method UpdateEnvironment:Int()
		lighting.Update()

		'=== ADJUST SKY COLOR ===
		If Weather.IsRaining() And Not rainColorFadeState.GetState()
			rainColorFadeState.SetState(True, rainColorFadeDuration)
		EndIf
		If Not Weather.IsRaining() And rainColorFadeState.GetState()
			rainColorFadeState.SetState(False, rainColorFadeDuration)
		EndIf
		If rainColorFadeState.IsOn() Or rainColorFadeState.IsFading()
			Local factor:Float = rainColorFadeState.GetFadeProgress()
			If rainColorFadeState.IsFadingOff() Then factor = 1.0 - factor


			'desaturate the background color according cloud brightness
			lighting.currentLight.AdjustSaturation(0.75 * Weather.GetCloudBrightness()/100.0 * factor)
			'even make the sky darker
			lighting.currentLight.AdjustRelative( -0.25 * Weather.GetCloudBrightness()/100.0 * factor )
			'desaturate the background fog color by up to 80%
			lighting.currentFogColor.AdjustSaturation(Weather.GetCloudBrightness()/100.0 * factor * 0.5)
		EndIf
	End Method


	Method Update:Int()
		'updates weather
		UpdateWeather()

		'updates lighing
		UpdateEnvironment()

		'updates rain/snow/clouds...
		UpdateEffects()
	End Method


	Method Render:Int()
		Local vpX:Int, vpY:Int, vpW:Int, vpH:Int
		GetGraphicsManager().GetViewport(vpX, vpY, vpW, vpH)
'		GetGraphicsManager().SetViewPort(int(area.GetX()), int(area.GetY()), int(area.GetW()), int(area.GetH()))

		'=== BACKGROUND ===
		Local skyColor:TColor = lighting.currentLight.copy()
		If rainEffect Then rainEffect.ModifySkyColor(skyColor)
		If lightningEffect Then lightningEffect.ModifySkyColor(skyColor)

		If useClsMethod
			SetClsColor skyColor.r, skyColor.g, skyColor.b
			Cls
		Else
			skyColor.SetRGB()
			DrawRect(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
			SetColor 255,255,255
		EndIf

		'=== GRADIENT ===
		If showSkyGradient And skyGradient
			lighting.currentFogColor.SetRGB()
			skyGradient.DrawArea(area.GetX(), area.GetY2()-300, area.GetW(), 300)
			SetColor(255,255,255)
		EndIf

		'=== STARS ===
		If showStars Then RenderStars()

		'=== SUN ===
		If showSun Then RenderSun()

		'=== MOON ===
		If showMoon Then RenderMoon()

		'=== LIGHTNING ===
		If autoRenderLightning Then RenderLightning()

		'=== CLOUDS ===
		If autoRenderClouds Then RenderClouds()

		'=== RAIN ===
		If autoRenderRain Then RenderRain()

		'=== SNOW ===
		If autoRenderSnow Then RenderSnow()

		'reset viewport
		GetGraphicsManager().SetViewport(vpX, vpY, vpW, vpH)
		'GetGraphicsManager().SetViewPort(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
	End Method


	Method RenderLightning:Int()
		If showLightning And lightningEffect Then lightningEffect.Render()
	End Method


	Method RenderClouds:Int()
		If showClouds And cloudEffect Then cloudEffect.Render()
	End Method


	Method RenderSnow:Int()
		If showSnow And snowEffect Then snowEffect.Render()
	End Method


	Method RenderRain:Int()
		If showRain And rainEffect Then rainEffect.Render()
	End Method


	Method RenderStars:Int()
		If stars.length = 0 Then InitStars(60)
		If Not stars[0] Then InitStars(stars.length)

		Local dayPhase:Int = GetWorldTime().GetDayPhase()
		'no stars during a day
		If dayPhase = GetWorldTime().DAYPHASE_DAY Then Return False

		Local alpha:Float = 0.0

		Select dayPhase
			Case GetWorldTime().DAYPHASE_NIGHT
				alpha = 1.0

			Case GetWorldTime().DAYPHASE_DAWN
				'first 50% used to fade out
				alpha = 1.0 - (GetWorldTime().GetDayPhaseProgress() * 2.0)
				'skip rendering if invisible
				If alpha < 0 Then Return False
			Case GetWorldTime().DAYPHASE_DUSK
				'last 50% used to fade in
				alpha = (GetWorldTime().GetDayPhaseProgress() - 0.50) * 2.0
				'skip rendering if invisible
				If alpha < 0 Then Return False
		End Select

		Local oldCol:TColor = New TColor.Get()
		alpha = Min(1.0, Max(0, alpha))

		Local dayMinute:Int = GetWorldTime().GetDayMinute()
		For Local i:Int = 0 Until stars.length
			'adjust background of some stars - randomly one of 5
			If ((i+dayMinute) Mod 5 = 0) And (dayMinute Mod 5 = 0)
			 	stars[i].z = stars[i].z + Rand(-30, 30)
			 	If stars[i].z > 200 Then stars[i].z :- 30
			 	If stars[i].z < 0
					'place at another spot with new color
					stars[i].z = 50+Rand(0, starsBrightness-50)
					stars[i].x = Rand(Int(area.GetX()), Int(area.GetX2()))
					stars[i].y = Rand(Int(area.GetY()), Int(area.GetY2()))
				EndIf
			EndIf
			'some get a blue-ish color
			If ((stars[i].x * stars[i].y) Mod 3) = 0
				SetColor(Int(stars[i].z), Int(stars[i].z), Int(stars[i].z + 50))
			Else
				SetColor(Int(stars[i].z), Int(stars[i].z), Int(stars[i].z))
			EndIf
			Plot(Int(stars[i].x) , Int(stars[i].y) )
		Next
		oldCol.SetRGBA()
	End Method


	Method RenderMoon:Int()
		Local oldAlpha:Float = GetAlpha()
		Local modifyAlpha:Float = 0.5 + 0.5*Weather.IsSunVisible()
		Local rotation:Float = 360.0 * GetWorldTime().GetDayProgress()
		Local movedMoonPoint:TVec2D = moonPoint.Copy().RotateAroundPoint(centerPoint, rotation)
		SetAlpha(oldAlpha * modifyAlpha)
		If skyMoon
			'show a different frame each day
			Local phase:Int = (skyMoon.frames -1) - ( GetWorldTime().GetDay(GetWorldTime().GetTimeGone() + 6*3600)) Mod skyMoon.frames
			skyMoon.Draw(movedMoonPoint.x, movedMoonPoint.y, phase, ALIGN_CENTER_CENTER, Float(0.95+0.05*Sin(Time.GetAppTimeGone()/10)))
		Else
			DrawOval(Int(movedMoonPoint.x-15), Int(movedMoonPoint.y-15), 30,30)
		EndIf
		SetAlpha(oldAlpha)
	End Method


	Method RenderSun:Int()
		Local rotation:Float = 360.0 * GetWorldTime().GetDayProgress()
		Local movedSunPoint:TVec2D = sunPoint.Copy().RotateAroundPoint(centerPoint, rotation)
		Local oldAlpha:Float = GetAlpha()
		Local modifyAlpha:Float = 0.1 + 0.9*Weather.IsSunVisible()

		If skySun
			SetAlpha(oldAlpha * modifyAlpha)

			SetRotation(rotation*3)
			If skySunRays Then skySunRays.Draw(movedSunPoint.x, movedSunPoint.y, -1, ALIGN_CENTER_CENTER, Float(1.0 + 0.10*Sin(Time.GetAppTimeGone()/10)))

			SetRotation(rotation*1)
			skySun.Draw(movedSunPoint.x, movedSunPoint.y, -1, ALIGN_CENTER_CENTER, Float(0.95+0.05*Sin(Time.GetAppTimeGone()/10)))

			SetRotation(0)
		Else
			SetColor 255,250,210
			Local stepSize:Int = 10
			For Local i:Int = 1 To 5
				SetAlpha (0.8 - i*0.1) * oldAlpha * modifyAlpha
				DrawOval(movedSunPoint.x-25-i*stepSize, movedSunPoint.y-25-i*stepSize, 50+i*2*stepSize,50+i*2*stepSize)
			Next
			SetAlpha oldAlpha * modifyAlpha
			DrawOval(movedSunPoint.x-25, movedSunPoint.y-25, 50,50)
		EndIf
		SetAlpha oldAlpha
	End Method


	Method RenderDebug:Int(x:Float = 0, y:Float = 0, width:Int=200, height:Int=180)
		SetColor 0,0,0
		SetAlpha GetAlpha()*0.5
		DrawRect(x,y,width,height)
		SetAlpha GetAlpha()*2.0
		SetColor 255,255,255
		Local dy:Int = 5
		DrawText("== World Data ==", x + 10, y + dy)
		dy :+ 12
		DrawText("time: "+GetWorldTime().GetFormattedTime()+" "+GetWorldTime().GetDayPhaseText(), x + 10, y + dy)
		dy :+ 12
		DrawText("date: "+GetWorldTime().GetFormattedDate(), x + 10, y+ dy)
		dy :+ 12
		DrawText("day: "+GetWorldTime().GetDay(), x + 10, y+ dy)
		dy :+ 12
		DrawText("day: "+GetWorldTime().GetDayOfMonth()+" of month: "+GetWorldTime().GetMonth(), x + 10, y+ dy)
		dy :+ 12
		DrawText("day: "+GetWorldTime().GetDayOfYear()+" of year: "+GetWorldTime().GetYear(), x + 10, y+ dy)
		dy :+ 12
		DrawText("season: "+GetWorldTime().GetSeason()+"/4", x + 10, y + dy)
		dy :+ 12
		DrawText("weather: "+Weather.GetWeatherText(), x + 10, y + dy)
		dy :+ 12
		DrawText("wind: "+MathHelper.NumberToString(Weather.GetWindVelocity(),4), x + 10, y + dy)
		dy :+ 12
		DrawText("temp: "+MathHelper.NumberToString(Weather.GetTemperature(),4), x + 10, y + dy)
		dy :+ 12
		DrawText("speed: "+Int(GetWorldTime().GetTimeFactor()), x + 10, y + dy)
		dy :+ 12
rem
		Local sunrise:Int = GetWorldTime().GetSunRise()
		Local sunset:Int = GetWorldTime().GetSunSet()
		Local sunRiseString:String = ""
		If sunrise/3600 < 10 Then sunRiseString = "0"
		sunRiseString:+(sunrise/3600)
		sunRiseString:+":"
		If (sunrise Mod 3600)/60 < 10 Then sunRiseString :+ "0"
		sunRiseString:+(sunrise Mod 3600)/60

		Local sunSetString:String = ""
		If sunset/3600 < 10 Then sunSetString = "0"
		sunSetString:+(sunset/3600)
		sunSetString:+":"
		If (sunset Mod 3600)/60 < 10 Then sunSetString :+ "0"
		sunSetString:+(sunset Mod 3600)/60
endrem
		Local sunRiseString:String = GetWorldTime().GetFormattedDate(GetWorldTime().GetSunRise(), "h:i")
		Local sunSetString:String = GetWorldTime().GetFormattedDate(GetWorldTime().GetsunSet(), "h:i")

		DrawText("rise: "+sunRiseString+"  set: "+sunSetString, x + 10, y+ dy)

		dy :+ 12

		Local dawnString:String = GetWorldTime().GetFormattedDate(GetWorldTime().GetDawnPhaseBegin(), "h:i")
		Local duskString:String = GetWorldTime().GetFormattedDate(GetWorldTime().GetDuskPhaseBegin(), "h:i")
		DrawText("dawn: "+dawnString+"  dusk: "+duskString, x + 10, y+ dy)
	End Method
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetWorld:TWorld()
	Return TWorld.GetInstance()
End Function