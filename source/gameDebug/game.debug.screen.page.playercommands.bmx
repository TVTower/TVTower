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
			button.w = 120
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next

		texts = ["Enable AI", "Reload AI", "Pause AI"]
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], -510 + 130, position.y + 8)
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


		DrawBorderRect(position.x, 10, 129, 200)
		If player.playerAI
			titleFont.Draw("Start task:", position.x + 5, 10)
		Else
			titleFont.Draw("Go to room:", position.x + 5, 10)
		EndIf

		RenderPlayerEventQueue(playerID, 600, 20)
		RenderPlayerTaskList(playerID, 600, 160)

		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		DrawBorderRect(position.x + 131, 10, 130, 75)
		For Local i:Int = 0 Until aiButtons.length
			aiButtons[i].Render()
		Next
	End Method


	Method RenderPlayerEventQueue(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)

		If player.playerAI
			DrawBorderRect(x, y, 185, 10 * 10 + 25)

			Local textX:Int = x + 3
			Local textY:Int = y + 3 - 1
			
			textFont.Draw("Event Queue: " + player.playerAI.eventQueue.length + " event(s).", textX, textY)
			textY :+ 12

			Local eventNumber:Int = 0
			For Local aievent:TAIEvent = EachIn player.playerAI.eventQueue
				textFont.DrawBox(aievent.ID, textX, textY, 15, 13, sALIGN_RIGHT_TOP, SColor8.white)
				textFont.DrawBox(aievent.GetName(), textX + 18, textY, 179 - 18, 13, SColor8.white)
				textY :+ 10
				eventNumber :+ 1
				
				'only print up to 20 events ...
				If eventNumber > 10 Then Exit
			Next
		EndIf
	End Method


	Method RenderPlayerTaskList(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)

		If player.playerAI
			DrawBorderRect(x, y, 185, 155)

			Local textX:Int = x + 3
			Local textY:Int = y + 3 - 1

			Local assignmentType:Int = player.aiData.GetInt("currentTaskAssignmentType", 0)
			If assignmentType = 1
				textFont.Draw("Task: [F] " + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", textX, textY)
			ElseIf assignmentType = 2
				textFont.Draw("Task: [R]" + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", textX, textY)
			Else
				textFont.Draw("Task: " + player.aiData.GetString("currentTask") + " ["+player.aiData.GetString("currentTaskStatus")+"]", textX, textY)
			EndIf
			textY :+ 10
			textFont.Draw("Job:   " + player.aiData.GetString("currentTaskJob") + " ["+player.aiData.GetString("currentTaskJobStatus")+"]", textX, textY)
			textY :+ 13

			textFontBold.Draw("Task List: ", textX, textY)
			textFontBold.Draw("Prio ", textX + 90 + 22*0, textY)
			textFontBold.Draw("Bas", textX + 90 + 22*1, textY)
			textFontBold.Draw("Sit", textX + 90 + 22*2, textY)
			textFontBold.Draw("Req", textX + 90 + 22*3, textY)
			textY :+ 10 + 2

			For Local taskNumber:Int = 1 To player.aiData.GetInt("tasklist_count", 1)
				textFont.Draw(player.aiData.GetString("tasklist_name"+taskNumber).Replace("Task", ""), textX, textY)
				textFont.Draw(player.aiData.GetInt("tasklist_priority"+taskNumber), textX + 90 + 22*0, textY)
				textFont.Draw(player.aiData.GetInt("tasklist_basepriority"+taskNumber), textX + 90 + 22*1, textY)
				textFont.Draw(player.aiData.GetInt("tasklist_situationpriority"+taskNumber), textX + 90 + 22*2, textY)
				textFont.Draw(player.aiData.GetInt("tasklist_requisitionpriority"+taskNumber), textX + 90 + 22*3, textY)
				textY :+ 10
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
