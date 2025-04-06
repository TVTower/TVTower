SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.debug.screen.page.misc.bmx"
Import "../game.game.bmx"
Import "../game.newsagency.bmx"

Type TDebugScreenPage_PlayerCommands extends TDebugScreenPage
	Global _instance:TDebugScreenPage_PlayerCommands
	Field aiButtons:TDebugControlsButton[]


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_PlayerCommands()
		If Not _instance Then new TDebugScreenPage_PlayerCommands
		Return _instance
	End Function


	Method Init:TDebugScreenPage_PlayerCommands()
		Local texts:String[] = ["Ad Agency", "Archive", "Boss", "Movie Agency", "News Studio", "Programme Schedule", "CheckSigns","Roomboard", "Station Map", "Scripts"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], -510, position.y + 8)
			'custom position
			button.x = 8
			button.y = 14 + 2 + i * (button.h + 2)

			button.w = 120
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next

		texts = ["Enable AI", "Reload AI", "Pause AI"]
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], -510 + 130, position.y + 8)
			'custom position
			button.x = 8 + 130
			button.y = 14 + 2 + i * (button.h + 2)

			button.w = 120
			button._onClickHandler = OnPlayerCommandAIButtonClickHandler

			aiButtons :+ [button]
		Next

		Return self
	End Method


	Method MoveBy(dx:Int, dy:Int) override
		'move buttons
		For Local b:TDebugControlsButton = EachIn buttons
			b.x :+ dx
			b.y :+ dy
		Next
		For Local b:TDebugControlsButton = EachIn aiButtons
			b.x :+ dx
			b.y :+ dy
		Next
	End Method


	Method Reset()
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		'switch off unavailable commands and update labels
		Local playerID:Int = GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)

		If player.isLocalHuman() Or player.isLocalAI()
			aiButtons[0].visible = True
		Else
			aiButtons[0].visible = False
		EndIf
		If player.isLocalAI()
			aiButtons[1].visible = True
			buttons[6].visible = True
		Else
			aiButtons[1].visible = False
			buttons[6].visible = False
		EndIf
		If player.isLocalAI()
			aiButtons[2].visible = True
			If player.PlayerAI.paused
				aiButtons[2].text = "Resume AI"
			Else
				aiButtons[2].text = "Pause AI"
			EndIf
		Else
			aiButtons[2].visible = False
		EndIf
		If player.IsLocalHuman() Or player.IsLocalAI()
			If player.IsLocalAI()
				aiButtons[0].text = "Disable AI"
			Else
				aiButtons[0].text = "Enable AI"
			EndIf
		EndIf

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
		For Local b:TDebugControlsButton = EachIn aiButtons
			b.Update()
		Next
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)

		Local contentRect:SRectI

		If player.playerAI
			contentRect = DrawWindow(position.x + 5, 15, 125, 200, "Start Task")
		Else
			contentRect = DrawWindow(position.x + 5, 15, 125, 200, "Go To Room")
		EndIf

		RenderPlayerEventQueue(playerID, 600, 15)
		RenderPlayerTaskList(playerID, 400, 15)

		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		DrawWindow(position.x + 135, 15, 125, 75, "AI Mode")
		For Local i:Int = 0 Until aiButtons.length
			aiButtons[i].Render()
		Next
	End Method


	Method RenderPlayerEventQueue(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)

		If player.playerAI
			Local contentRect:SRectI = DrawWindow(x, y, 190, 200, "Event Queue", player.playerAI.eventQueue.length + " event(s).")

			Local eventNumber:Int = 0
			Local textY:Int = contentRect.y
			For Local aievent:TAIEvent = EachIn player.playerAI.eventQueue
				textFont.DrawBox(aievent.ID, contentRect.x, textY, 15, 13, sALIGN_RIGHT_TOP, SColor8.white)
				textFont.DrawBox(aievent.GetName(), contentRect.x + 18, textY, 179 - 18, 13, SColor8.white)
				textY :+ 11
				eventNumber :+ 1
				
				'only print up to 15 events ...
				If eventNumber > 15 Then Exit
			Next
		EndIf
	End Method


	Method RenderPlayerTaskList(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)

		If player.playerAI
			Local contentRect:SRectI = DrawWindow(x, y, 190, 200, "Task List", player.aiData.GetInt("tasklist_count", 1) + " task(s).")

			Local textY:Int = contentRect.y

			Local assignmentType:Int = player.aiData.GetInt("currentTaskAssignmentType", 0)
			If assignmentType = 1
				textFont.Draw("Task: [F] " + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", contentRect.x, textY)
			ElseIf assignmentType = 2
				textFont.Draw("Task: [R]" + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", contentRect.x, textY)
			Else
				textFont.Draw("Task: " + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", contentRect.x, textY)
			EndIf
			textY :+ 12
			textFont.Draw("Job:   " + player.aiData.GetString("currentTaskJob") + " ["+player.aiData.GetString("currentTaskJobStatus")+"]", contentRect.x, textY)
			textY :+ 15

			textFontBold.Draw("Task List: ", contentRect.x, textY)
			textFontBold.Draw("Prio ", contentRect.x + 90 + 22*0, textY)
			textFontBold.Draw("Bas", contentRect.x + 90 + 22*1, textY)
			textFontBold.Draw("Sit", contentRect.x + 90 + 22*2, textY)
			textFontBold.Draw("Req", contentRect.x + 90 + 22*3, textY)
			textY :+ 11 + 2

			For Local taskNumber:Int = 1 To player.aiData.GetInt("tasklist_count", 1)
				textFont.Draw(player.aiData.GetString("tasklist_name"+taskNumber).Replace("Task", ""), contentRect.x, textY)
				textFont.Draw(player.aiData.GetInt("tasklist_priority"+taskNumber), contentRect.x + 90 + 22*0, textY)
				textFont.Draw(player.aiData.GetInt("tasklist_basepriority"+taskNumber), contentRect.x + 90 + 22*1, textY)
				textFont.Draw(player.aiData.GetInt("tasklist_situationpriority"+taskNumber), contentRect.x + 90 + 22*2, textY)
				textFont.Draw(player.aiData.GetInt("tasklist_requisitionpriority"+taskNumber), contentRect.x + 90 + 22*3, textY)
				textY :+ 11
			Next
		EndIf
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Local playerID:Int = GetInstance().GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)

		Local taskName:String =""
		Select sender.dataInt
			Case 0	taskName = "AdAgency"
			Case 1	taskName = "Archive"
			Case 2	taskName = "Boss"
			Case 3	taskName = "MovieDistributor"
			Case 4	taskName = "NewsAgency"
			Case 5	taskName = "Schedule"
			Case 6	taskName = "CheckSigns"
			Case 7	taskName = "RoomBoard"
			Case 8	taskName = "StationMap"
			Case 9	taskName = "Scripts"
		End Select

		If taskName
			If player.playerAI
				'player.PlayerAI.CallLuaFunction("OnForceNextTask", null)
				'GetPlayerBase(2).PlayerAI.CallOnChat(1, "CMD_forcetask " + taskName +" 1000", CHAT_COMMAND_WHISPER)
				player.playerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnChat).AddInt(1).AddString("CMD_forcetask " + taskName +" 1000").AddInt(CHAT_COMMAND_WHISPER))
			Else
				'send player to the room of the task
				Local room:TRoom
				Select sender.dataInt
					Case 0	 room = GetRoomCollection().GetFirstByDetails("", "adagency")
					Case 1	 room = GetRoomCollection().GetFirstByDetails("", "archive", playerID)
					Case 2	 room = GetRoomCollection().GetFirstByDetails("", "boss", playerID)
					Case 3	 room = GetRoomCollection().GetFirstByDetails("", "movieagency")
					Case 4	 room = GetRoomCollection().GetFirstByDetails("", "news", playerID)
					Case 5	 room = GetRoomCollection().GetFirstByDetails("", "office", playerID)
'					Case 6	 room = GetRoomCollection().GetFirstByDetails("", "elevatorPlan")
					Case 7	 room = GetRoomCollection().GetFirstByDetails("", "roomboard")
					Case 8	 room = GetRoomCollection().GetFirstByDetails("", "office", playerID)
					Case 9	 room = GetRoomCollection().GetFirstByDetails("", "scriptagency")
				End Select
				If room
					Local door:TRoomDoorBase = GetRoomDoorCollection().GetMainDoorToRoom(room.id)
					If door
						player.GetFigure().LeaveRoom(True)
						player.GetFigure().SendToDoor(door)
					EndIf
				EndIf
			EndIf

		EndIf

		'handled
		sender.clicked = False
		sender.selected = False
	End Function

	Function OnPlayerCommandAIButtonClickHandler(sender:TDebugControlsButton)
'		print "clicked " + sender.dataInt

		Local playerID:Int = GetInstance().GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)
		Local newButtonState:Int = False

		Local taskName:String =""
		Select sender.dataInt
			Case 0
				If player.IsLocalHuman() Or player.IsLocalAI()
					TDebugScreenPage_Misc.GetInstance().Dev_SetPlayerAI(playerID, Not player.IsLocalAI())
					If player.IsLocalAI()
						newButtonState = True
					EndIf
				EndIf
			Case 1
				If GetPlayer(playerID).isLocalAI() Then GetPlayer(playerID).PlayerAI.reloadScript()
			Case 2
				If GetPlayer(playerID).isLocalAI() Then GetPlayer(playerID).PlayerAI.paused = 1 - GetPlayer(playerID).PlayerAI.paused 
		End Select

		'handled
		sender.clicked = False
		sender.selected = newButtonState
	End Function
End Type
