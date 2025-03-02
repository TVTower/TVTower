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
		textFont.draw("Renderer: "+GetGraphicsManager().GetRendererName(), 5, 360)
		If ScreenCollection.GetCurrentScreen()
			textFont.draw("onScreen: "+ScreenCollection.GetCurrentScreen().name, 5, 360 + 11)
		Else
			textFont.draw("onScreen: Main", 5, 360 + 11)
		EndIf


		Local x:Int = position.x + 5
		RenderPlayerPositions(x, 10)
		RenderElevatorState(x, 100)

		Local sideInfoW:Int = 160
		For Local i:Int = 0 To 3
			RenderFigureInformation( GetPlayer(i+1).GetFigure(), x + 140, 10 + i*75)
			RenderBossMood(i+1, x + 140 + 150 + 2, 10 + i*75, sideInfoW, 30)
'			textFont.Draw("Image #"+i+": "+MathHelper.NumberToString(GetPublicImageCollection().Get(i+1).GetAverageImage(), 4)+" %", 10, 320 + i*13)

			If TProfiler.activated And GetPlayer(i+1).IsLocalAI()
				DrawOutlineRect(x + 140 + 150 + 2, 10 + i*75 + 33, sideInfoW, 37)
				DrawProfilerCallHistory(TProfiler.GetCall(_profilerKey_AI_MINUTE[i]), x + 140 + 150 + 5, 10 + i*75 + 33 + 5, sideInfoW - 2*4, 28, "AI " + (i+1))
			EndIf

		Next

		DrawOutlineRect(x + 5 + 500, 10, 140, 180)
		GetWorld().RenderDebug(x + 5 + 500, 10, 140, 180)
	End Method


	Method RenderPlayerPositions(x:Int, y:Int)
		DrawOutlineRect(x, y, 130, 70)

		titleFont.draw("Player positions:", x + 5, y + 5)

		Local roomName:String = ""
		Local fig:TFigure
		For Local i:Int = 0 To 3
			fig = GetPlayer(i+1).GetFigure()

			Local change:String = ""
			If fig.isChangingRoom()
				If fig.inRoom
					change = "<-[]" 'Chr(8646)
				Else
					change = "->[]" 'Chr(8646)
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
				textFont.draw((i + 1) + ": "+roomName + change , x + 5, y + 20 + i * 10 - 1)
			Else
				textFont.draw((i + 1) + ": "+roomName + change +" (forced)" , x + 5, y + 20 + i * 10 - 1)
			EndIf
		Next
	End Method


	Method RenderElevatorState(x:Int, y:Int)
		DrawOutlineRect(x, y, 130, 160)

		titleFont.draw("Elevator routes:", x + 5, y + 5)
		Local routepos:Int = 0
		Local startY:Int = y + 20 - 1
		Local callType:String = ""

		'Local directionString:String = "up"
		'If GetElevator().Direction = 1 Then directionString = "down"

		textFont.draw("floor: " + GetElevator().currentFloor + "->" + GetElevator().targetFloor, x + 5, startY)
		textFont.draw("status:"+GetElevator().ElevatorStatus, x + 5 + 65, startY)

		If GetElevator().RouteLogic.GetSortedRouteList()
			For Local FloorRoute:TFloorRoute = EachIn GetElevator().RouteLogic.GetSortedRouteList()
				If floorroute.call = 0 Then callType = "send" Else callType= "call"
				textFont.draw(FloorRoute.floornumber, x + 5, startY + 15 + routepos * 11)
				textFont.draw(callType, x + 18, startY + 15 + routepos * 11)
				textFont.draw(FloorRoute.who.Name, x + 46, startY + 15 + routepos * 11)
				routepos :+ 1
			Next
		Else
			textFont.draw("recalculate", x + 5, startY + 15)
		EndIf
	End Method


	Method RenderFigureInformation(figure:TFigure, x:Int, y:Int)
		DrawOutlineRect(x, y, 150, 70)

		Local oldCol:SColor8; GetColor(oldCol)

		Local usedDoorText:String = ""
		Local targetText:String = ""
		If TRoomDoor(figure.usedDoor) Then usedDoorText = TRoomDoor(figure.usedDoor).GetRoom().GetName()
		If figure.GetTarget()
			Local t:Object = figure.GetTarget()
			If TRoomDoor(figure.GetTargetObject())
				targetText = TRoomDoor(figure.GetTargetObject()).GetRoom().GetName()
			ElseIf THotSpot(figure.GetTargetObject())
				targetText = "Hotspot"
			Else
				targetText = "Building"
			EndIf
			targetText :+ " (" + figure.GetMoveToPosition().ToString() + ")"
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
				roomName :+ "<-[]" 'Chr(8646)
			Else
				roomName :+ "->[]" 'Chr(8646)
			EndIf
		EndIf

		If Not figure.isControllable() Then roomName :+" (f)"


		SetColor 255,255,255
		Local textY:Int = y + 5 - 1
		titleFont.Draw(figure.name, x + 5, textY)
		If Not figure.CanMove() Then textFont.DrawBox("cannot move", x, textY, 150 - 3, 14, sALIGN_RIGHT_TOP, SColor8.White)
		textY :+ 10
		textFont.DrawSimple(roomName, x + 5, textY)
		textY :+ 10
		If targetText Then textFont.DrawSimple("-> " + targetText, x + 5, textY)
		'textY :+ 10
		'textFont.draw("usedDoor: " + usedDoorText, x + 5, textY)

		SetColor(oldCol)
	End Method


	Method RenderBossMood(playerID:Int, x:Int, y:Int, w:Int, h:Int)
		Local boss:TPlayerBoss = GetPlayerBoss(playerID)
		If Not boss Then Return


		DrawOutlineRect(x,y,w,h)
		Local textY:Int = y + 5

		titleFont.draw("Boss #"  + boss.playerID, x + 5, textY - 1)
		textY :+ 12
		textFont.draw("Mood: " + MathHelper.NumberToString(boss.GetMood(), 2), x + 5, textY - 1)
		SetColor 150,150,150
		DrawRect(x + 70, textY, 70, 10 )
		SetColor 0,0,0
		DrawRect(x + 70 + 1, textY + 1, 70 - 2, 10 - 2)
		SetColor 190,150,150
		Local handleX:Int = MathHelper.Clamp(boss.GetMoodPercentage()*68 - 2, 0, 68 - 4)
		DrawRect(x + 70 + 1 + handleX , textY + 1, 4, 10 - 2 )
		SetColor 255,255,255
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
			GetBitmapFont("Default", 10).DrawBox(MathHelper.NumberToString(durationMax, 4), x+2, y+2, w-4, 20, sALIGN_RIGHT_TOP, SColor8.White)
		EndIf
		GetBitmapFont("Default", 10).DrawBox(label, x+2, y+2, w-4, 20, sALIGN_LEFT_TOP, SColor8.White)
	End Function
End Type
