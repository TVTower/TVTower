SuperStrict

Framework brl.StandardIO
Import "../source/Dig/base.util.graphicsmanager.bmx"
Import "../source/Dig/base.util.input.bmx"
Import "../source/game.world.bmx"

AppTitle = "TVT: Weather Sim Tester"

Local gm:TGraphicsManager = GetGraphicsManager()
GetGraphicsManager().SetResolution(900,600)
GetGraphicsManager().InitGraphics()

GetWorld().Initialize() 'weather!

'GetWorldTime()._daysPerSeason = 1
GetWorldTime().SetTimeGone( GetWorldTime().MakeTime(1985, 0, 0, 0, 0) )
GetWorldTime().SetTimeStart( GetWorldTime().MakeTime(1985, 0, 0, 0, 0) )
'set speed 10x realtime
'GetWorldTime().SetTimeFactor(3600*2)




Function Update:Int()
	MouseManager.Update()
	KeyManager.Update()

	EventManager.Update()
	
	if KeyHit(KEY_SPACE)
		GetWorld().Weather.SetPressure(-14)
		GetWorld().Weather.SetTemperature(-10)
	EndIf
	if KeyDown(KEY_RIGHT)
		GetWorldTime().SetTimeFactor(3600*60)
	Elseif KeyDown(KEY_LEFT)
		GetWorldTime().SetTimeFactor(3600*0)
	Else
		GetWorldTime().SetTimeFactor(3600*2)
	EndIf
	'update worldtime (eg. in games this is the ingametime)
	GetWorldTime().Update()
	GetWorld().Update()
End Function


Function Render:Int()
	SetClsColor 0,0,0
	SetAlpha 1.0
	Cls

	'=== RENDER HUD ===
	DrawText("worldTime: "+GetWorldTime().GetFormattedTime(-1, "h:i:s")+ " at day "+GetWorldTime().GetDayOfYear()+" in "+GetWorldTime().GetYear(), 20, 10)
	DrawText("Cursor Left:  Pause", 20, 570)
	DrawText("Cursor Right: Fast Forward", 20, 582)

	Local x:Int = 20
	Local y:Int = 40
	DrawText("Weather", x, y)
	y :+ 16
	DrawText("Time", x, y)
	DrawText("Seas", x + 180, y)
	DrawText("Temp", x + 230, y)
	DrawText("WindV", x + 300, y)
	DrawText("WindSp", x + 370, y)
	DrawText("Press", x + 440, y)
	DrawText("Okta", x + 520, y) 'Wolkendeckendichte
	DrawText("Sun", x + 570, y) 'Sonne sichtbar?
	DrawText("Rain", x + 610, y)
	DrawText("Storm", x + 650, y)
	DrawText("targetTemp", x + 710, y)
	DrawText("Text", x + 810, y)
	y :+ 14

	For local i:int = 0 until 24
		local weather:TWorldWeatherEntry = GetWorld().Weather.GetUpcomingWeather(i+1)
		if not weather then continue
		DrawText(GetWorldTime().GetFormattedGameDate(weather._time), x, y)
		DrawText(GetWorldTime().GetSeason(weather._time) + "/4", x + 180, y)
		DrawText(StringHelper.printf("%3.3f", [string(weather.GetTemperature())]), x + 230, y)
		If weather.GetWindVelocity() >= 0
			DrawText(" " + MathHelper.NumberToString(weather.GetWindVelocity(), 3), x + 300, y)
		Else
			DrawText(MathHelper.NumberToString(weather.GetWindVelocity(), 3), x + 300, y)
		EndIf
		DrawText(MathHelper.NumberToString(weather.GetWindSpeedKmh(), 0, True), x + 370, y)
		If weather.GetPressure() >= 0
			DrawText(" " + MathHelper.NumberToString(weather.GetPressure(), 3), x + 440, y)
		Else
			DrawText(MathHelper.NumberToString(weather.GetPressure(), 3), x + 440, y)
		EndIf
		DrawText(weather.GetCloudOkta(), x + 520, y)
		DrawText(weather.IsSunVisible(), x + 570, y)
		DrawText(weather.IsRaining(), x + 610, y)
		DrawText(weather.IsStorming(), x + 650, y)
		DrawText(weather._targetTemperature, x + 710, y)
		DrawText(weather.GetWorldWeatherText(), x + 810, y)
		y :+ 14
	Next
End Function



While Not KeyHit(KEY_ESCAPE) Or AppTerminate()
	Update()
	Cls
	Render()
	Flip
	Delay(2)
Wend