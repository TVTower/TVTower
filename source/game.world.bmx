SuperStrict
Import "Dig/base.util.deltatimer.bmx"
Import "Dig/base.util.graphicsmanager.bmx"

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
	Field rainColorFadeState:TFadingState = new TFadingState
	Field rainColorFadeDuration:int = 1000

	'=== CLOUDS ===
	Field cloudEffect:TWeatherEffectClouds {nosave}
	Field cloudColorFadeState:TFadingState = new TFadingState
	Field cloudColorFadeDuration:int = 1000

	'=== STARS ===
	Field starsBrightness:int = 150
	Field stars:TVec3D[60]						{nosave}


	'point sun and moon rotate around
	Field centerPoint:TVec2D
	'starting point of the sun - defines distance to centerPoint
	Field sunPoint:TVec2D
	'starting point of the moon - defines distance to centerPoint
	Field moonPoint:TVec2D

	'the skyGradient draws a little gradient at the background eg. to
	'indicate a sunrise
	Field skyGradient:TSprite
	Field skyMoon:TSprite
	Field skySun:TSprite
	Field skySunRays:TSprite

	Field currentCloudColor:TColor
	Field currentWindVelocity:Float
	Field newWindVelocity:Float

	Field showRain:int = True
	Field showLightning:int = True
	Field showSnow:int = True
	Field showClouds:int = True
	Field showSun:int = True
	Field showStars:int = True
	Field showMoon:int = True
	Field showSkyGradient:int = True

	'disable if rendering effects on your own (other layer) 
	Field autoRenderRain:int = True
	Field autoRenderSnow:int = True
	Field autoRenderClouds:int = True
	Field autoRenderLightning:int = True

	Global useClsMethod:int = True
	'reference to a world configuration data set
	Global _config:TData
	Global _instance:TWorld


	Function GetInstance:TWorld()
		if not _instance then _instance = new TWorld
		return _instance
	End Function


	Method Initialize:int()
		area = new TRectangle.Init(0,0,800,385)
		centerPoint = new TVec2D.Init(400, 570 + area.GetY())
		sunPoint = new TVec2D.Init(400, 1100 + area.GetY())
		moonPoint =  new TVec2D.Init(400, 100 + area.GetY())

		if not weather then weather = new TWorldWeather
		if not lighting then lighting = new TWorldLighting
		weather.Init(0, 18, 0, 3600)
		lighting.Init()

		'adjust effect display
		RenewConfiguration()

		'we do not save stars in savegames, so we externalized
		'initialization to make it more convenient to call
		InitStars(GetConfiguration().GetInt("starsAmount", 60))
	End Method


	Method SetSpeed:int(newSpeed:int)
		'newSpeed = Min(50000, Max(1, newSpeed))
		GetWorldTime().SetTimeFactor(newSpeed)
	End Method


	Function SetConfiguration:Int(config:TData)
		_config = config

		GetInstance().RenewConfiguration()
	End Function


	Function GetConfiguration:TData()
		if not _config then _config = new TData
		return _config
	End Function


	'renews settings whether to display certain effects
	Method RenewConfiguration:int(config:TData = Null)
		if not config then config = GetConfiguration()

		showRain = config.GetBool("showRain", True)
		showLightning = config.GetBool("showLightning", True)
		showSnow = config.GetBool("showSnow", True)
		showClouds = config.GetBool("showClouds", True)
		showSun = config.GetBool("showSun", True)
		showStars = config.GetBool("showStars", True)
		showMoon = config.GetBool("showMoon", True)
		showSkyGradient = config.GetBool("showSkyGradient", True)
	End Method


	Method InitSky:int(gradient:TSprite, moon:TSprite, sun:TSprite, sunRays:TSprite)
		skyGradient = gradient
		skyMoon = moon
		skySun = sun
		skySunRays = sunRays
	End Method


	Method InitSnowEffect:int(startFlakes:int = 10, sprites:TSprite[])
		'to make effect start "offscreen" we increase size a bit
		local effectArea:TRectangle = area.copy()
		effectArea.position.AddX(-50)
		effectArea.dimension.AddX(50)
		snowEffect = new TWeatherEffectSnow.Init(effectArea, startFlakes, sprites)
	End Method


	Method InitRainEffect:int(layers:int = 2, sprites:TSprite[])
		'to make effect start "offscreen" we increase size a bit
		local effectArea:TRectangle = area.copy()
		effectArea.position.AddX(-50)
		effectArea.dimension.AddX(50)
		rainEffect = new TWeatherEffectRain.Init(effectArea, layers, sprites)
	End Method


	Method InitLightningEffect:int(sprites:TSprite[], spritesSide:TSprite[])
		lightningEffect = new TWeatherEffectLightning.Init(area.copy(), 1, sprites, spritesSide)
	End Method
	

	Method InitCloudEffect:int(cloudAmount:int = 30, sprites:TSprite[])
		cloudEffect = new TWeatherEffectClouds.Init(area.copy(), cloudAmount, sprites)
	End Method


	Method InitStars:int(starCount:int = 60)
		stars = stars[..starCount]
	
		'=== SETUP STARS ===
		For Local i:Int = 0 until stars.length
			stars[i] = new TVec3D.Init(Rand(area.GetX(), area.GetX2()), Rand(area.GetY(), area.GetY2()), 50+Rand(0,StarsBrightness-50))
		Next
	End Method
	

	Method UpdateEffects:int()
		'=== RAIN ===
		if showRain and rainEffect
			'stop rain if it is too cold for water. Snow does the
			'opposite thing
			if Weather.GetTemperature() < 0 
				if rainEffect.IsActive() then rainEffect.Stop()
			else
				'means rain and snow
				if Weather.IsRaining()
					if not rainEffect.IsActive() then rainEffect.Start()
				else
					if rainEffect.IsActive() then rainEffect.Stop()
				endif
			endif

			'inform rain about current wind
			rainEffect.windVelocity = Weather.GetWindVelocity()
			
			rainEffect.Update()
		endif


		'=== SNOW ===
		if showSnow and snowEffect
			'stop snow if it is too warm for ice. Rain does the
			'opposite thing
			if Weather.GetTemperature() >= 0 
				if snowEffect.IsActive() then snowEffect.Stop()
			else
				'means rain and snow
				if Weather.IsRaining()
					if not snowEffect.IsActive() then snowEffect.Start()
				else
					if snowEffect.IsActive() then snowEffect.Stop()
				endif
			endif
			snowEffect.Update()
		endif


		'=== LIGHTNING ===
		if showLightning and lightningEffect
			'storm or severe storm?
			if Weather.IsRaining() >= 4
				if not lightningEffect.IsActive() then lightningEffect.Start()
			else
				if lightningEffect.IsActive() then lightningEffect.Stop()
			endif

			lightningEffect.Update()
		endif


		'=== ADJUST CLOUD COLOR ===
		if showClouds and cloudEffect
			cloudEffect.skyBrightness = lighting.GetSkyBrightness()

			'brightness changed?
			if Weather.GetCloudBrightness() <> cloudEffect.cloudBrightness
				if not cloudColorFadeState.GetState()
					'start fader
					cloudColorFadeState.SetState(true, cloudColorFadeDuration)
				else
					'reset fade state
					cloudColorFadeState.SetState(False, 0)
					'set new brightness
					cloudEffect.cloudBrightness = Weather.GetCloudBrightness()
				endif

				if cloudColorFadeState.IsFading() or cloudEffect.cloudBrightness = 100
					local factor:float = cloudColorFadeState.GetFadeProgress()
					if cloudColorFadeState.IsFadingOff() then factor = 1.0 - factor

					factor = cloudEffect.cloudBrightness*(1.0-factor) + Weather.GetCloudBrightNess()*factor
					factor :/ 100.0
					'if simple grey clouds:
					'cloudColor = TColor.CreateGrey(factor * 255)
					'or advanced:
					cloudEffect.cloudColor = cloudEffect.cloudColorBase.copy().AdjustRelative(-1 + factor)
				endif
			endif
	

			'=== ADJUST CLOUDS MOVEMENT ===
			local wrapClouds:int = Weather.GetWeather() <> Weather.WEATHER_CLEAR
			local windStrength:Float = Weather.GetWindVelocity() * 0.5
			if windStrength = 0.0 then windStrength = 0.1
		
			cloudEffect.AdjustCloudMovement(windStrength, weather.GetTimeSinceUpdate(), wrapClouds)
		endif
	End Method


	Method UpdateWeather:int()
		'time for another weather update?
		If Weather and Weather.NeedsUpdate()
			'to always have 48 hours "prediction" we need
			'updateWeatherEvery/3600 * 24 entries
			Weather.GenerateUpcomingWeather(Weather.weatherInterval/3600.0 * 24)

			'update the weather
			Weather.Update()

			'store current velocity
			if cloudEffect then cloudEffect.StoreCloudVelocity()
		endif
	End Method


	Method UpdateEnvironment:int()
		lighting.Update()

		'=== ADJUST SKY COLOR ===
		if Weather.IsRaining() and not rainColorFadeState.GetState()
			rainColorFadeState.SetState(true, rainColorFadeDuration)
		EndIf
		if not Weather.IsRaining() and rainColorFadeState.GetState()
			rainColorFadeState.SetState(false, rainColorFadeDuration)
		EndIf
		if rainColorFadeState.IsOn() or rainColorFadeState.IsFading()
			local factor:float = rainColorFadeState.GetFadeProgress()
			if rainColorFadeState.IsFadingOff() then factor = 1.0 - factor


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
		GetGraphicsManager().SetViewPort(area.GetX(), area.GetY(), area.GetW(), area.GetH())

		'=== BACKGROUND ===
		local skyColor:TColor = lighting.currentLight.copy()
		if rainEffect then rainEffect.ModifySkyColor(skyColor)
		if lightningEffect then lightningEffect.ModifySkyColor(skyColor)

		if useClsMethod
			SetClsColor skyColor.r, skyColor.g, skyColor.b
			Cls
		else
			skyColor.SetRGB()
			DrawRect(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
			setColor 255,255,255
		endif

		'=== GRADIENT ===
		if showSkyGradient and skyGradient
			lighting.currentFogColor.SetRGB()
			skyGradient.DrawArea(area.GetX(), area.GetY2()-300, area.GetW(), 300)
			SetColor(255,255,255)
		endif
		
		'=== STARS ===
		if showStars then RenderStars()

		'=== SUN ===
		if showSun then RenderSun()
		
		'=== MOON ===
		if showMoon then RenderMoon()

		'=== LIGHTNING ===
		if autoRenderLightning then RenderLightning()
	
		'=== CLOUDS ===
		if autoRenderClouds then RenderClouds()

		'=== RAIN ===
		if autoRenderRain then RenderRain()

		'=== SNOW ===
		if autoRenderSnow then RenderSnow()

		'reset viewport
		GetGraphicsManager().SetViewPort(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
	End Method


	Method RenderLightning:int()
		if showLightning and lightningEffect then lightningEffect.Render()
	End Method


	Method RenderClouds:int()
		if showClouds and cloudEffect then cloudEffect.Render()
	End Method


	Method RenderSnow:int()
		if showSnow and snowEffect then snowEffect.Render()
	End Method


	Method RenderRain:int()
		if showRain and rainEffect then rainEffect.Render()
	End Method


	Method RenderStars:int()
		if stars.length = 0 then InitStars(60)
		if not stars[0] then InitStars(stars.length)
	
		local dayPhase:int = GetWorldTime().GetDayPhase()
		'no stars during a day
		if dayPhase = GetWorldTime().DAYPHASE_DAY then return False

		local alpha:Float = 0.0

		Select dayPhase
			case GetWorldTime().DAYPHASE_NIGHT
				alpha = 1.0

			case GetWorldTime().DAYPHASE_DAWN
				'first 50% used to fade out
				alpha = 1.0 - (GetWorldTime().GetDayPhaseProgress() * 2.0)
				'skip rendering if invisible
				if alpha < 0 then return False
			case GetWorldTime().DAYPHASE_DUSK
				'last 50% used to fade in
				alpha = (GetWorldTime().GetDayPhaseProgress() - 0.50) * 2.0
				'skip rendering if invisible
				if alpha < 0 then return False
		End Select

		local oldCol:TColor = new TColor.Get()
		alpha = Min(1.0, Max(0, alpha))

		local dayMinute:int = GetWorldTime().GetDayMinute()
		For Local i:Int = 0 until stars.length
			'adjust background of some stars - randomly one of 5
			if ((i+dayMinute) mod 5 = 0) and (dayMinute mod 5 = 0)
			 	stars[i].z = stars[i].z + Rand(-30, 30)
			 	if stars[i].z > 200 then stars[i].z :- 30
			 	if stars[i].z < 0
					'place at another spot with new color
					stars[i].z = 50+Rand(0, starsBrightness-50)
					stars[i].x = Rand(area.GetX(), area.GetX2())
					stars[i].y = Rand(area.GetY(), area.GetY2()) 
				endif
			endif
			'some get a blue-ish color
			if ((stars[i].x * stars[i].y) mod 3) = 0
				SetColor(stars[i].z , stars[i].z , stars[i].z +50)
			else
				SetColor(stars[i].z , stars[i].z , stars[i].z)
			endif
			Plot(stars[i].x , stars[i].y )
		Next
		oldCol.SetRGBA()
	End Method


	Method RenderMoon:int()
		local oldAlpha:Float = GetAlpha()
		local modifyAlpha:Float = 0.5 + 0.5*Weather.IsSunVisible()
		local rotation:Float = 360.0 * GetWorldTime().GetDayProgress()
		local movedMoonPoint:TVec2D = moonPoint.Copy().RotateAroundPoint(centerPoint, rotation)

		SetAlpha(oldAlpha * modifyAlpha)
		if skyMoon
			'show a different frame each day
			local phase:int = skyMoon.frames - ( GetWorldTime().GetDay(GetWorldTime().GetTimeGone() + 6*3600)) Mod skyMoon.frames
			
			skyMoon.Draw(movedMoonPoint.x, movedMoonPoint.y, phase, ALIGN_CENTER_CENTER, , 0.95+0.05*Sin(Time.GetAppTimeGone()/10))
		else
			DrawOval(movedMoonPoint.x-15, movedMoonPoint.y-15, 30,30)
		endif
		SetAlpha(oldAlpha)
	End Method


	Method RenderSun:int()
		local rotation:Float = 360.0 * GetWorldTime().GetDayProgress()
		local movedSunPoint:TVec2D = sunPoint.Copy().RotateAroundPoint(centerPoint, rotation)
		local oldAlpha:Float = GetAlpha()
		local modifyAlpha:Float = 0.1 + 0.9*Weather.IsSunVisible()

		if skySun
			SetAlpha(oldAlpha * modifyAlpha)

			SetRotation(rotation*3)
			if skySunRays then skySunRays.Draw(movedSunPoint.x, movedSunPoint.y, -1, ALIGN_CENTER_CENTER, 1.0 + 0.10*Sin(Time.GetAppTimeGone()/10))

			SetRotation(rotation*1)
			skySun.Draw(movedSunPoint.x, movedSunPoint.y, -1, ALIGN_CENTER_CENTER, 0.95+0.05*Sin(Time.GetAppTimeGone()/10))

			SetRotation(0)
		else
			SetColor 255,250,210
			local stepSize:int = 10
			For local i:int = 1 to 5
				SetAlpha (0.8 - i*0.1) * oldAlpha * modifyAlpha
				DrawOval(movedSunPoint.x-25-i*stepSize, movedSunPoint.y-25-i*stepSize, 50+i*2*stepSize,50+i*2*stepSize)
			Next
			SetAlpha oldAlpha * modifyAlpha
			DrawOval(movedSunPoint.x-25, movedSunPoint.y-25, 50,50)
		endif
		SetAlpha oldAlpha
	End Method
	

	Method RenderDebug:int(x:Float = 0, y:Float = 0, width:int=200, height:int=120)
		SetColor 0,0,0
		SetAlpha GetAlpha()*0.5
		DrawRect(x,y,width,height)
		SetAlpha GetAlpha()*2.0
		SetColor 255,255,255
		local dy:int = 5
		DrawText("== World Data ==", x + 10, y + dy)
		dy :+ 12
		local minute:string = GetWorldTime().GetDayMinute()
		if minute.length = 1 then minute = "0"+minute
		DrawText("time: "+GetWorldTime().GetDayHour()+":"+minute+" "+GetWorldTime().GetDayPhaseText(), x + 10, y + dy)
		dy :+ 12
		DrawText("year: "+GetWorldTime().GetYear()+"  season: "+GetWorldTime().GetSeason()+"/4", x + 10, y + dy)
		dy :+ 12
		DrawText("weather: "+Weather.GetWeatherText(), x + 10, y + dy)
		dy :+ 12
		DrawText("wind: "+Weather.GetWindVelocity(), x + 10, y + dy)
		dy :+ 12
		DrawText("temp: "+Weather.GetTemperature(), x + 10, y + dy)
		dy :+ 12
		DrawText("speed: "+int(GetWorldTime().GetTimeFactor()), x + 10, y + dy)
		dy :+ 12

		local sunrise:int = GetWorldTime().GetSunRise()
		local sunset:int = GetWorldTime().GetSunSet()
		local sunRiseString:string = ""
		if sunrise/3600 < 10 then sunRiseString = "0"
		sunRiseString:+(sunrise/3600)
		sunRiseString:+":"
		if (sunrise mod 3600)/60 < 10 then sunRiseString :+ "0"
		sunRiseString:+(sunrise mod 3600)/60

		local sunSetString:string = ""
		if sunset/3600 < 10 then sunSetString = "0"
		sunSetString:+(sunset/3600)
		sunSetString:+":"
		if (sunset mod 3600)/60 < 10 then sunSetString :+ "0"
		sunSetString:+(sunset mod 3600)/60
		
		DrawText("rise: "+sunRiseString+"  set: "+sunSetString, x + 10, y+ 89)
		DrawText("realDay: "+GetWorldTime().GetDayOfMonth()+"/"+GetWorldTime().GetMonth(), x + 10, y+ 101)
	End Method
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetWorld:TWorld()
	return TWorld.GetInstance()
End Function