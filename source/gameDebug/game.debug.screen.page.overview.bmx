SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"

Type TDebugScreenPage_Overview extends TDebugScreenPage
	Global _instance:TDebugScreenPage_Overview
	Global _profilerKey_AI_MINUTE:TLowerString[] = [New TLowerString.Create("PLAYER_AI1_MINUTE"), New TLowerString.Create("PLAYER_AI2_MINUTE"), New TLowerString.Create("PLAYER_AI3_MINUTE"), New TLowerString.Create("PLAYER_AI4_MINUTE")]


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_Overview()
		If Not _instance Then new TDebugScreenPage_Overview
		Return _instance
	End Function


	Method Init:TDebugScreenPage_Overview()
		Return self
	End Method


	Method Reset()
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
	End Method


	Method Render()
		Local x:Int = position.x + 5
		'RenderPlayerPositions(x, 15) 'shown in FigureInformation!
		RenderElevatorState(x, 15)

		Local sideInfoW:Int = 160
		For Local i:Int = 0 To 3
			RenderFigureInformation( GetPlayer(i+1).GetFigure(), x + 140, position.y + i*55)
			RenderBossMood(i+1, x + 140 + 200 + 2, position.y + i*55, sideInfoW, 30)
'			textFont.Draw("Image #"+i+": "+TFunctions.NumberToString(GetPublicImageCollection().Get(i+1).GetAverageImage(), 4)+" %", 10, 320 + i*13)

			If TProfiler.activated And GetPlayer(i+1).IsLocalAI()
				DrawBorderRect(x + 140 + 150 + 2, 15 + i*75 + 33, sideInfoW, 37)
				DrawProfilerCallHistory(TProfiler.GetCall(_profilerKey_AI_MINUTE[i]), x + 140 + 150 + 5, 10 + i*75 + 33 + 5, sideInfoW - 2*4, 28, "AI " + (i+1))
			EndIf

		Next

		RenderWorldInformation(x + 500, position.y)
	End Method


	Method RenderPlayerPositions(x:Int, y:Int)
		Local contentRect:SRectI = DrawWindow(x, y, 130, 70, "Player Positions")

		Local roomName:String = ""
		Local fig:TFigure
		For Local i:Int = 0 To 3
			fig = GetPlayer(i+1).GetFigure()

			Local change:String = ""
			If fig.isChangingRoom()
				If fig.inRoom
					change = " " + Chr(11013) + "[]"
				Else
					change = " []" + Chr(10145)
				EndIf
			EndIf

			roomName = "Building"
			If fig.inRoom
				roomName = fig.inRoom.GetName()
			ElseIf fig.IsInElevator()
				roomName = "InElevator"
			ElseIf fig.IsAtElevator()
				roomName = "AtElevator"
			EndIf
			If fig.isControllable()
				textFont.draw((i + 1) + ": "+roomName + change , contentRect.x, contentRect.y + i * 10 - 1)
			Else
				textFont.draw((i + 1) + ": "+roomName + change +" (forced)" , contentRect.x, contentRect.y + i * 10 - 1)
			EndIf
		Next
	End Method


	Method RenderElevatorState(x:Int, y:Int)
		Local contentRect:SRectI = DrawWindow(x, y, 130, 210, "Elevator Routes")

		Local routepos:Int = 0
		Local callType:String = ""

		textFont.draw("floor: " + RSet(GetElevator().currentFloor,2).Replace(" ", "|color=175,175,175|0|/color|") + " " + Chr(10142) +" " + RSet(GetElevator().targetFloor,2).Replace(" ", "|color=175,175,175|0|/color|"), contentRect.x, contentRect.y)
		textFont.draw("status: " + GetElevator().ElevatorStatus, contentRect.x + 75, contentRect.y)

		If GetElevator().RouteLogic.GetSortedRouteList()
			For Local FloorRoute:TFloorRoute = EachIn GetElevator().RouteLogic.GetSortedRouteList()
				If floorroute.call = 0 Then callType = "send" Else callType= "call"
				textFont.draw(RSet(FloorRoute.floorNumber,2).Replace(" ", "|color=175,175,175|0|/color|"), contentRect.x, contentRect.y + 15 + routepos * 11)
				textFont.draw(callType, contentRect.x + 15, contentRect.y + 15 + routepos * 11)
				textFont.draw(FloorRoute.who.Name, contentRect.x + 43, contentRect.y + 15 + routepos * 11)
				routepos :+ 1
			Next
		Else
			textFont.draw("recalculate", contentRect.x, contentRect.y + 15)
		EndIf
	End Method


	Method RenderFigureInformation(figure:TFigure, x:Int, y:Int)
		Local name:String = "unknown"
		Local contentRect:SRectI
		If figure
			Local subTitle:String
			If Not figure.CanMove() then subTitle = "can't move"
			contentRect = DrawWindow(x, y, 190, 45, figure.name, subTitle, 0.0)
		Else
			contentRect = DrawWindow(x, y, 190, 45, "unknown")
			Return
		EndIf
		

		Local oldCol:SColor8; GetColor(oldCol)

		Local usedDoorText:String = ""
		Local targetText:String = ""
		If TRoomDoor(figure.usedDoor) Then usedDoorText = TRoomDoor(figure.usedDoor).GetRoom().GetName()
		If figure.GetTarget()
			Local t:Object = figure.GetTarget()
			If TRoomDoor(figure.GetTargetObject())
				targetText = TRoomDoor(figure.GetTargetObject()).GetRoom().GetName()
			ElseIf THotSpot(figure.GetTargetObject())
				targetText = "Hotspot " + figure.GetMoveToPosition().ToString()
			Else
				targetText = "Building " + figure.GetMoveToPosition().ToString()
			EndIf
		EndIf


		Local roomName:String = "in Building"
		If figure.inRoom
			roomName = StringHelper.UCFirst(figure.inRoom.GetName())
		ElseIf figure.IsInElevator()
			roomName = "in Elevator"
		ElseIf figure.IsAtElevator()
			roomName = "at Elevator"
		EndIf
		If figure.isChangingRoom()
			If figure.inRoom
				roomName :+ " " + Chr(11013) + "[]"
			Else
				roomName :+ " []" + Chr(10145)
			EndIf
		EndIf

		If Not figure.isControllable() Then roomName :+" (f)"


		SetColor 255,255,255
		textFont.DrawSimple(roomName, contentRect.x, contentRect.y)
		If targetText 
			textFont.DrawBox(Chr(10145) + targetText, contentRect.x, contentRect.y, contentRect.w, 20, sALIGN_RIGHT_TOP, SColor8.White)
		EndIf

		SetColor(oldCol)
	End Method


	Method RenderBossMood(playerID:Int, x:Int, y:Int, w:Int, h:Int)
		Local boss:TPlayerBoss = GetPlayerBoss(playerID)
		If Not boss Then Return

		Local contentRect:SRectI = DrawWindow(x, y, 150, 45, "Boss #" + boss.playerID)
		Local barWidth:Int = 70
		Local oldCol:SColor8; GetColor(oldCol)

		textFont.draw("Mood: " + TFunctions.NumberToString(boss.GetMood(), 2), contentRect.x, contentRect.y)
		SetColor 150,150,150
		DrawRect(contentRect.x + 75, contentRect.y + 2, barWidth, 10 )
		SetColor 0,0,0
		DrawRect(contentRect.x + 75 + 1, contentRect.y + 2 + 1, barWidth - 2, 10 - 2)
		SetColor 190,150,150
		Local handleX:Int = MathHelper.Clamp(boss.GetMoodPercentage()*(barWidth-2) - 2, 0, (barWidth-2) - 4)
		DrawRect(contentRect.x + 75 + 1 + handleX , contentRect.y + 2 + 1, 4, 10 - 2 )

		SetColor(oldCol)
	End Method
	
	
	Method RenderWorldInformation(x:Int, y:Int)
		Local contentRect:SRectI = DrawWindow(x, y, 140, 210, "World Data")

		Local dy:Int = 0
		Local wt:TWorldTime = GetWorldTime()
		Local weather:TWorldWeather = GetWorld().Weather
		dy :+ textFont.DrawSimple("Time: " + wt.GetFormattedTime() + " " + wt.GetDayPhaseText(), contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("Date: " + wt.GetFormattedDate(), contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("Day: " + wt.GetDay(), contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("Day: " + wt.GetDayOfMonth() + " of month: " + wt.GetMonth(), contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("Day: " + wt.GetDayOfYear()+" of year: "+wt.GetYear(), contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("Season: " + wt.GetSeason()+"/4", contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("Weather: " + weather.GetWeatherText(), contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("  Wind: " + TFunctions.NumberToString(weather.GetWindVelocity(),4), contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("  Temp.: " + TFunctions.NumberToString(weather.GetTemperature(),4), contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("  TargetTemp.: " + TFunctions.NumberToString(weather.currentWeather._targetTemperature,4), contentRect.x, contentRect.y + dy).y
		dy :+ textFont.DrawSimple("Speed.: " + wt.GetTimeFactor(), contentRect.x, contentRect.y + dy).y

		Local sunRiseString:String = GetWorldTime().GetFormattedDate(GetWorldTime().GetSunRise(), "h:i")
		Local sunSetString:String = GetWorldTime().GetFormattedDate(GetWorldTime().GetSunSet(), "h:i")
		dy :+ textFont.DrawSimple("Rise: " + sunRiseString + "   set:" + sunSetString, contentRect.x, contentRect.y + dy).y

		Local dawnString:String = GetWorldTime().GetFormattedDate(GetWorldTime().GetDawnPhaseBegin(), "h:i")
		Local duskString:String = GetWorldTime().GetFormattedDate(GetWorldTime().GetDuskPhaseBegin(), "h:i")
		dy :+ textFont.DrawSimple("Dawn: " + dawnString + "   dusk:" + duskString, contentRect.x, contentRect.y + dy).y
	End Method
	

	Function DrawProfilerCallHistory(profilerCall:TProfilerCall, x:Int, y:Int, w:Int, h:Int, label:String, drawType:Int=0)
		SetAlpha 0.5
		SetColor 150,150,150
		DrawRect(x,y,w,h)

		SetAlpha 0.75
		SetColor 200,200,200
		DrawLine(x,y,x,y+h)
		DrawLine(x+w,y,x+w,y+h)
		DrawLine(x,y,x+w,y)
		DrawLine(x,y+h,x+w,y+h)

		SetAlpha 1.0

		If profilerCall And profilerCall.historyDuration.length > 0
			Local durationMax:Float = profilerCall.historyDuration[0]
			Local durationMin:Float = profilerCall.historyDuration[0]
			Local durationAvg:Float = profilerCall.historyDuration[0]
			Local timeMin:Double = profilerCall.historyTime[0]
			Local timeMax:Double = profilerCall.historyTime[ profilerCall.historyTime.length - 1 ]
			Local timeSpan:Double

			Local canvasW:Int = w - 2
			Local canvasH:Int = h - 2 - 10 '-10 for label

			'find max / calc avg
			For Local i:Int = 0 Until profilerCall.historyDuration.length
				If durationMax < profilerCall.historyDuration[i] Then durationMax = profilerCall.historyDuration[i]
				If durationMin > profilerCall.historyDuration[i] Then durationMin = profilerCall.historyDuration[i]
				If timeMin > profilerCall.historyTime[i] Then timeMin = profilerCall.historyTime[i]
				If timeMax < profilerCall.historyTime[i] Then timeMax = profilerCall.historyTime[i]
				durationAvg :+ profilerCall.historyDuration[i]
			Next
			durationAvg :/ profilerCall.historyDuration.length

			timeSpan = timeMax - timeMin


			SetColor 150,150,150
			For Local i:Int = 0 Until profilerCall.historyTime.length
				Local aboveAvg:Float = profilerCall.historyDuration[i] / durationAvg
				SetColor 150 + Int(MathHelper.Clamp(100*(aboveAvg-1), 0, 100)),150,150

				Local px:Float = x + 1 + canvasW * (profilerCall.historyTime[i] - timeMin) / timeSpan
				Local py:Float = y + h - 1 - canvasH * profilerCall.historyDuration[i] / durationMax
				Select drawType
					Case 0
						DrawLine(px, py, px, y + h - 1)
					Default
						Plot(px, py)
				End Select
			Next

			SetColor 255,255,255
			GetBitmapFont("Default", 9).DrawBox(TFunctions.NumberToString(durationMax, 4), x+2, y+2, w-4, 20, sALIGN_RIGHT_TOP, SColor8.White)
		EndIf
		GetBitmapFont("Default", 9).DrawBox(label, x+2, y+2, w-4, 20, sALIGN_LEFT_TOP, SColor8.White)
	End Function
End Type
