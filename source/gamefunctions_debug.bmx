
Global debugAudienceInfo:TDebugAudienceInfo = New TDebugAudienceInfo
Global debugPlayerControls :TDebugPlayerControls = New TDebugPlayerControls

Global debugProfiler:TDebugProfiler = new TDebugProfiler


Type TDebugScreen
	Field _enabled:Int
	Field _lastEnabled:Int
	Field _mode:Int = 0
	Field _lastMode:Int
	Field currentPage:TDebugScreenPage
	
	Field sideButtons:TDebugControlsButton[]
	Field playerCommandTaskButtons:TDebugControlsButton[]
	Field playerCommandAIButtons:TDebugControlsButton[]
	Field buttonsPlayerFinancials:TDebugControlsButton[]
	Field buttonsBroadCast:TDebugControlsButton[]
	Field buttonsNewsAgency:TDebugControlsButton[]
	Field buttonsRoomAgency:TDebugControlsButton[]
	Field buttonsScriptAgency:TDebugControlsButton[]
	Field buttonsPolitics:TDebugControlsButton[]
	Field buttonsProducers:TDebugControlsButton[]
	Field buttonsSports:TDebugControlsButton[]
	Field buttonsMisc:TDebugControlsButton[]
	Field buttonsModifiers:TDebugControlsButton[]
	Field buttonsAwardControls:TDebugControlsButton[]
	Field sideButtonPanelWidth:Int = 130
	Field roomHighlight:TRoomBase
	Field roomHovered:TRoomBase
	Field scriptAgencyOfferHightlight:TScript
	
	
	Field pagePlayerFinancials:TDebugScreenPage_PlayerFinancials
	Field pagePlayerBroadcasts:TDebugScreenPage_PlayerBroadcasts
	Field pageAdAgency:TDebugScreenPage_AdAgency
	Field pageMovieAgency:TDebugScreenPage_MovieAgency
	
	Global titleFont:TBitmapFont
	Global textFont:TBitmapFont
	Global textFontBold:TBitmapFont

	Field FastForward_Active:Int = False
	Global FastForward_Continuous_Active:Int = False
	Global FastForwardSpeed:Int = 500
	Field FastForward_SwitchedPlayerToAI:Int = 0
	Global FastForward_TargetTime:Long = -1
	Field FastForward_SpeedFactorBackup:Float = 0.0
	Field FastForward_TimeFactorBackup:Float = 0.0
	Field FastForward_BuildingTimeSpeedFactorBackup:Float = 0.0
	Global _eventListeners:TEventListenerBase[]


	Method New()
		Local button:TDebugControlsButton


		Local texts:String[] = ["Overview", "Player Commands", "Player Financials", "Player Broadcasts", "-", "Ad Agency", "Movie Vendor", "News Agency", "Script Agency", "Room Agency", "-", "Politics Sim", "Producers", "Sports Sim", "Modifiers", "Misc"]
		Local mode:int = 0
		For Local i:Int = 0 Until texts.length
			if texts[i] = "-" then continue 'spacer
			button = New TDebugControlsButton
			button.w = 118
			button.h = 15
			button.x = 5
			button.y = 10 + i * (button.h + 3)
			button.dataInt = mode
			button.text = texts[i]
			button._onClickHandler = OnButtonClickHandler
			
			mode :+ 1

			sideButtons :+ [button]
		Next
		
		pagePlayerFinancials = new TDebugScreenPage_PlayerFinancials.Init()
		pagePlayerFinancials.SetPosition(sideButtonPanelWidth, 20)

		pagePlayerBroadcasts = TDebugScreenPage_PlayerBroadcasts.GetInstance().Init()
		pagePlayerBroadcasts.SetPosition(sideButtonPanelWidth, 20)

		pageAdAgency = TDebugScreenPage_AdAgency.GetInstance().Init()
		pageAdAgency.SetPosition(sideButtonPanelWidth, 20)

		pageMovieAgency = TDebugScreenPage_MovieAgency.GetInstance().Init()
		pageMovieAgency.SetPosition(sideButtonPanelWidth, 20)

		InitMode_Overview()
		InitMode_PlayerCommands()

		InitMode_NewsAgency()
		InitMode_ScriptAgency()
		InitMode_RoomAgency()
		InitMode_Politics()
		InitMode_Producers()
		InitMode_Sports()
		InitMode_Modifiers()
		InitMode_Misc()


		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnStart, onStartGame) ]
	End Method
	
	
	Method Reset()
		If pagePlayerFinancials Then pagePlayerFinancials.Reset()
		If pagePlayerBroadcasts Then TDebugScreenPage_PlayerBroadcasts.GetInstance().Reset()
		If pageAdAgency Then TDebugScreenPage_AdAgency.GetInstance().Reset()
		If pageMovieAgency Then TDebugScreenPage_MovieAgency.GetInstance().Reset()

		ResetMode_Overview()
		ResetMode_PlayerCommands()

		ResetMode_NewsAgency()
		ResetMode_ScriptAgency()
		ResetMode_RoomAgency()
		ResetMode_Politics()
		ResetMode_Producers()
		ResetMode_Sports()
		ResetMode_Modifiers()
		ResetMode_Misc()
	End Method
	
	
	'Call reset on new game / loaded game
	Function onStartGame:Int(triggerEvent:TEventBase)
		DebugScreen.Reset()
	End Function


	Method SetMode(newMode:Int)
		If newMode <> _mode
			_mode = newMode

			local newPage:TDebugScreenPage
			Select _mode
				Case 0	newPage = Null
				Case 1	newPage = Null
				Case 2	newPage = pagePlayerFinancials
				Case 3	newPage = pagePlayerBroadcasts
				Case 4	newPage = pageAdAgency
				Case 5	newPage = pageMovieAgency

				'Case 6	UpdateMode_NewsAgency()
				'Case 7	UpdateMode_ScriptAgency()
				'Case 8	UpdateMode_RoomAgency()
				'Case 9	UpdateMode_Politics()
				'Case 10	UpdateMode_Producers()
				'Case 11	UpdateMode_Sports()
				'Case 12	UpdateMode_Modifiers()
				'Case 13	UpdateMode_Misc()
				default newPage = Null
			End Select
			
			if newPage <> currentPage
				if currentPage then currentPage.Deactivate()
				if newPage then newPage.Activate()
				currentPage = newPage
			endif
		EndIf
	End Method

	Function OnButtonClickHandler(sender:TDebugControlsButton)
		DebugScreen.SetMode(sender.dataInt)
	End Function


	Method GetShownPlayerID:Int()
		Local playerID:Int = GetPlayerBaseCollection().GetObservedPlayerID()
		If GetInGameInterface().ShowChannel > 0
			playerID = GetInGameInterface().ShowChannel
		EndIf
		If playerID <= 0 Then playerID = GetPlayerBase().playerID
		Return playerID
	End Method

	
	'called no matter if debug screen is shown or not - use this for
	'stuff needing regular updates anyways (eg to reset values)
	Method UpdateSystem()
	
		If FastForward_Active and FastForward_TargetTime < GetWorldTime().GetTimeGone()
			Dev_StopFastForwardToTime()
		EndIf
		'continuous fast forward: save game and go to the end of the next day
		If FastForward_Continuous_Active and FastForward_TargetTime < GetWorldTime().GetTimeGone()
			GetGame().SetGameSpeed(0)
			Local savegameName:String = "savegames/AI-day-" + StringHelper.RSetChar((GetWorldTime().GetDaysRun() + 1),2,"0")+ ".xml"
			TSaveGame.Save(savegameName)
			FastForward_TargetTime = GetWorldTime().CalcTime_DaysFromNowAtHour(-1,1,1,23,23) + 56*TWorldTime.MINUTELENGTH
			GetGame().SetGameSpeed(FastForwardSpeed)
		EndIf
		
		
		If _enabled <> _lastEnabled
			if currentPage 
				If _enabled
					currentPage.Activate()
				Else
					currentPage.Deactivate()
				EndIf
			endif

			_lastEnabled = _enabled
		EndIf
	End Method


	Method Update()
		For Local b:TDebugControlsButton = EachIn sideButtons
			b.Update()

			If _mode = b.dataInt
				b.selected = True
			Else
				b.selected = False
			EndIf
		Next

		Select _mode
			Case 0	UpdateMode_Overview()
			Case 1	UpdateMode_PlayerCommands()

			Case 6	UpdateMode_NewsAgency()
			Case 7	UpdateMode_ScriptAgency()
			Case 8	UpdateMode_RoomAgency()
			Case 9	UpdateMode_Politics()
			Case 10	UpdateMode_Producers()
			Case 11	UpdateMode_Sports()
			Case 12	UpdateMode_Modifiers()
			Case 13	UpdateMode_Misc()
			default
				if currentPage then currentPage.Update()
		End Select
	End Method


	Method Render()
		if not titleFont
			titleFont = GetBitmapFont("default", 12, BOLDFONT)
			textFontBold = GetBitmapFont("default", 10, BOLDFONT)
			textFont = GetBitmapFont("default", 10)
			
			TDebugScreenPage.titleFont = titleFont
			TDebugScreenPage.textFontBold = textFontBold
			TDebugScreenPage.textFont = textFont
		endif

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
	
		SetColor 0,0,0
		SetAlpha(0.3 * oldColA)
		DrawRect(0,0, sideButtonPanelWidth, 383)
		SetAlpha(oldColA)
		DrawRect(sideButtonPanelWidth-2,0, 2, 383)
		SetColor 255,255,255
		For Local b:TDebugControlsButton = EachIn sideButtons
			b.Render()
		Next


		SetColor 0,0,0
		SetAlpha 0.2 * oldColA
		DrawRect(sideButtonPanelWidth,0, 800 - sideButtonPanelWidth, 383)
		SetColor(oldCol)
		SetAlpha(oldColA)
		
		Select _mode
			Case 0	RenderMode_Overview()
			Case 1	RenderMode_PlayerCommands()

			Case 6	RenderMode_NewsAgency()
			Case 7	RenderMode_ScriptAgency()
			Case 8	RenderMode_RoomAgency()
			Case 9	RenderMode_Politics()
			Case 10	RenderMode_Producers()
			Case 11	RenderMode_Sports()
			Case 12	RenderMode_Modifiers()
			Case 13	RenderMode_Misc()
			default
				if currentPage then currentPage.Render()
		End Select
	End Method

	Method RenderActionButtons(buttons:TDebugControlsButton[])
		DrawOutlineRect(sideButtonPanelWidth + 510, 13, 160, 150)
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next
	End Method


	'=== OVERVIEW ===
	Method InitMode_Overview()
	End Method


	Method ResetMode_Overview()
	End Method


	Method UpdateMode_Overview()
		Local playerID:Int = GetShownPlayerID()
	End Method


	Method RenderMode_Overview()
		Local playerID:Int = GetShownPlayerID()

		textFont.draw("Renderer: "+GetGraphicsManager().GetRendererName(), 5, 360)
		If ScreenCollection.GetCurrentScreen()
			textFont.draw("onScreen: "+ScreenCollection.GetCurrentScreen().name, 5, 360 + 11)
		Else
			textFont.draw("onScreen: Main", 5, 360 + 11)
		EndIf


		local x:int = sideButtonPanelWidth + 5
		RenderPlayerPositions(x, 10)
		RenderElevatorState(x, 100)

		local sideInfoW:int = 160
		for local i:int = 0 To 3
			RenderFigureInformation( GetPlayer(i+1).GetFigure(), x + 140, 10 + i*75)
			RenderBossMood(i+1, x + 140 + 150 + 2, 10 + i*75, sideInfoW, 30)
'			textFont.Draw("Image #"+i+": "+MathHelper.NumberToString(GetPublicImageCollection().Get(i+1).GetAverageImage(), 4)+" %", 10, 320 + i*13)

			if GetPlayer(i+1).IsLocalAI()
				DrawOutlineRect(x + 140 + 150 + 2, 10 + i*75 + 33, sideInfoW, 37)
				DrawProfilerCallHistory(TProfiler.GetCall(_profilerKey_AI_MINUTE[i]), x + 140 + 150 + 5, 10 + i*75 + 33 + 5, sideInfoW - 2*4, 28, "AI " + (i+1))
			endif

		next

		GetWorld().RenderDebug(x + 5 + 500, 20, 140, 180)
	End Method




	'=== PLAYER COMMANDS ===
	Method InitMode_PlayerCommands()
		Local IDs:Int[]      = [0,           1,         2,      3,              4,             5,                    6,           7]
		Local texts:String[] = ["Ad Agency", "Archive", "Boss", "Movie Agency", "News Studio", "Programme Schedule", "Roomboard", "Station Map"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = New TDebugControlsButton
			button.w = 120
			button.h = 15
			button.x = 0
			button.y = i * (button.h + 3)
			button.dataInt = IDs[i]
			button.text = texts[i]
			button._onClickHandler = OnPlayerCommandTaskButtonClickHandler

			playerCommandTaskButtons :+ [button]
		Next


		IDs   = [0,           1,           2]
		texts = ["Enable AI", "Reload AI", "Pause AI"]
		For Local i:Int = 0 Until texts.length
			button = New TDebugControlsButton
			button.w = 120
			button.h = 15
			button.x = 0
			button.y = i * (button.h + 3)
			button.dataInt = IDs[i]
			button.text = texts[i]
			button._onClickHandler = OnPlayerCommandAIButtonClickHandler

			playerCommandAIButtons :+ [button]
		Next
	End Method


	Method ResetMode_PlayerCommands()
	End Method


	Function OnPlayerCommandTaskButtonClickHandler(sender:TDebugControlsButton)
'		print "clicked " + sender.dataInt

		Local playerID:Int = DebugScreen.GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)

		Local taskName:String =""
		Select sender.dataInt
			Case 0	taskName = "AdAgency"
			Case 1	taskName = "Archive"
			Case 2	taskName = "Boss"
			Case 3	taskName = "MovieDistributor"
			Case 4	taskName = "NewsAgency"
			Case 5	taskName = "Schedule"
			Case 6	taskName = "RoomBoard"
			Case 7	taskName = "StationMap"
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
					Case 6	 room = GetRoomCollection().GetFirstByDetails("", "roomboard", playerID)
					Case 7	 room = GetRoomCollection().GetFirstByDetails("", "ofice", playerID)
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
		sender.selected = False
	End Function



	Function OnPlayerCommandAIButtonClickHandler(sender:TDebugControlsButton)
'		print "clicked " + sender.dataInt

		Local playerID:Int = DebugScreen.GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)
		Local newButtonState:Int = False

		Local taskName:String =""
		Select sender.dataInt
			Case 0
				if player.IsLocalHuman() or player.IsLocalAI()
					Dev_SetPlayerAI(playerID, not player.IsLocalAI())
					if player.IsLocalAI()
						newButtonState = True
					endif
				endif
			Case 1 
				If GetPlayer(playerID).isLocalAI() Then GetPlayer(playerID).PlayerAI.reloadScript()
			Case 2 
				If GetPlayer(playerID).isLocalAI() Then GetPlayer(playerID).PlayerAI.paused = 1 - GetPlayer(playerID).PlayerAI.paused 
		End Select
		sender.selected = newButtonState
	End Function


	Method UpdateMode_PlayerCommands()
'		local playerID:int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn playerCommandTaskButtons
			b.Update(sideButtonPanelWidth + 5, 30)
		Next
		For Local b:TDebugControlsButton = EachIn playerCommandAIButtons
			b.Update(sideButtonPanelWidth + 5 + 1*(120 + 10), 30)
		Next
		
		'switch off unavailable commands and update labels
		Local playerID:Int = GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)

		If player.isLocalHuman() or player.isLocalAI()
			playerCommandAIButtons[0].visible = True
		Else
			playerCommandAIButtons[0].visible = False
		EndIf
		If player.isLocalAI()
			playerCommandAIButtons[1].visible = True
		Else
			playerCommandAIButtons[1].visible = False
		EndIf
		If player.isLocalAI()
			playerCommandAIButtons[2].visible = True
			If player.PlayerAI.paused
				playerCommandAIButtons[2].text = "Resume AI"
			Else
				playerCommandAIButtons[2].text = "Pause AI"
			EndIf
		Else
			playerCommandAIButtons[2].visible = False
		EndIf
		If player.IsLocalHuman() or player.IsLocalAI()
			If player.IsLocalAI()
				playerCommandAIButtons[0].text = "Disable AI"
			Else
				playerCommandAIButtons[0].text = "Enable AI"
			EndIf
		EndIf
	End Method


	Method RenderMode_PlayerCommands()
		'local playerID:int = GetShownPlayerID()
		Local playerID:Int = DebugScreen.GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)

		Local oldCol:SColor8; GetColor(oldCol)
		SetColor 0,0,0
		DrawOutlineRect(sideButtonPanelWidth, 10, 130, 170, true, true, true, false, 0,0,0, 0.25, 0.25)
		SetColor 255,255,255

		If player.playerAI
			titleFont.Draw("Start task:", sideButtonPanelWidth + 5, 13)
		Else
			titleFont.Draw("Go to room:", sideButtonPanelWidth + 5, 13)
		EndIf
		SetColor(oldCol)

		For Local b:TDebugControlsButton = EachIn playerCommandTaskButtons
			b.Render(sideButtonPanelWidth + 5, 30)
		Next

		For Local b:TDebugControlsButton = EachIn playerCommandAIButtons
			b.Render(sideButtonPanelWidth + 5 + 1*(120 + 10), 30)
		Next


		RenderPlayerEventQueue(playerID, 600, 20)
		RenderPlayerTaskList(playerID, 600, 160)
	End Method



	Method CreateActionButton:TDebugControlsButton(index:int, text:String)
		Local button:TDebugControlsButton = New TDebugControlsButton
		button.h = 15
		button.w = 150
		button.x = sideButtonPanelWidth + 510 + 5
		button.y = 25 + index * (button.h + 3)
		button.dataInt = index
		button.text = text
		return button
	End Method




	'=== NEWS AGENCY ===

	Method InitMode_NewsAgency()
		Local texts:String[] = ["Announce News (no impl)"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_NewsAgency

			buttonsNewsAgency :+ [button]
		Next
	End Method


	Method ResetMode_NewsAgency()
	End Method


	Function OnButtonClickHandler_NewsAgency(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				'
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_NewsAgency()
		Local playerID:Int = GetShownPlayerID()

		UpdateNewsAgencyQueue(playerID, sideButtonPanelWidth + 5, 13, 410, 230)

		For Local b:TDebugControlsButton = EachIn buttonsNewsAgency
			b.Update()
		Next
	End Method


	Method RenderMode_NewsAgency()
		Local playerID:Int = GetShownPlayerID()

		RenderNewsAgencyQueue(playerID, sideButtonPanelWidth + 5, 13, 495, 190)
		RenderNewsAgencyGenreSchedule(playerID, sideButtonPanelWidth + 5, 13 + 190 + 10, 200, 140)
		RenderNewsAgencyInformation(playerID, sideButtonPanelWidth + 5 + 200 + 10, 13 + 190 + 10, 285, 140)

		RenderActionButtons(buttonsNewsAgency)
		For Local b:TDebugControlsButton = EachIn buttonsNewsAgency
			b.Render()
		Next

'		if newsAgencyNewsHighlight
'			newsAgencyNewsHighlight.ShowSheet(sideButtonPanelWidth + 5 + 250, 13, 0	, playerID)
'		endif
	End Method
	
	
	'=== Script AGENCY ===

	Method InitMode_ScriptAgency()
		Local texts:String[] = ["Refill Offers", "Replace Offers"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_ScriptAgency

			buttonsScriptAgency :+ [button]
		Next
	End Method


	Method ResetMode_ScriptAgency()
	End Method


	Function OnButtonClickHandler_ScriptAgency(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				RoomHandler_ScriptAgency.GetInstance().ReFillBlocks()
			case 1
				RoomHandler_ScriptAgency.GetInstance().ReFillBlocks(True, 1.0)
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_ScriptAgency()
		Local playerID:Int = GetShownPlayerID()
		
		UpdateScriptAgencyOffers(playerID, sideButtonPanelWidth + 5, 13 + 45 + 5)

		For Local b:TDebugControlsButton = EachIn buttonsScriptAgency
			b.Update()
		Next
	End Method


	Method RenderMode_ScriptAgency()
		Local playerID:Int = GetShownPlayerID()
		
		RenderScriptAgencyInformation(playerID, sideButtonPanelWidth + 5, 13, , 45)
		RenderScriptAgencyOffers(playerID, sideButtonPanelWidth + 5, 13 + 45 + 5)

		RenderActionButtons(buttonsScriptAgency)

		if scriptAgencyOfferHightlight
			scriptAgencyOfferHightlight.ShowSheet(sideButtonPanelWidth + 5 + 450, 13, 0, -1)
		endif
	End Method



	'=== Room AGENCY ===

	Method InitMode_RoomAgency()
		Local texts:String[] = ["Rent for player X", "Kick Renter", "Re-Rent", "Block for 1 Hour", "Remove Block"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_RoomAgency
			button.visible = False

			buttonsRoomAgency :+ [button]
		Next
		
		local slot1:Int = buttonsRoomAgency[0].y
		local slot2:Int = buttonsRoomAgency[1].y
		local slot3:Int = buttonsRoomAgency[2].y
		
		'move them together by "group"
		buttonsRoomAgency[1].y = slot2
		buttonsRoomAgency[2].y = slot2
		buttonsRoomAgency[3].y = slot3
		buttonsRoomAgency[4].y = slot3
	End Method


	Method ResetMode_RoomAgency()
		roomHovered = Null
	End Method


	Function OnButtonClickHandler_RoomAgency(sender:TDebugControlsButton)
		Local room:TRoomBase = DebugScreen.roomHighlight
		if not room Then print "click no room"; Return

		Select sender.dataInt
			case 0
				If room.IsRented() Then GetRoomAgency().CancelRoomRental(room, -1)
				GetRoomAgency().BeginRoomRental(room, DebugScreen.GetShownPlayerID())
				room.SetUsedAsStudio(True)

			case 1
				GetRoomAgency().CancelRoomRental(room, -1)
				room.SetUsedAsStudio(False)

			case 2
				room.BeginRental(room.originalOwner, room.GetRent())

			case 3
				'room.SetBlocked(TWorldTime.HOURLENGTH, TRoomBase.BLOCKEDSTATE_RENOVATION, False)
				'we want to see a "sign", so use a bomb :D
				room.SetBlocked(TWorldTime.HOURLENGTH, TRoomBase.BLOCKEDSTATE_BOMB, False)

			case 4
				room.SetUnblocked()
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_RoomAgency()
		Local playerID:Int = GetShownPlayerID()

		If roomHovered
			UpdateRoomAgencyRoomDetails(roomHovered, sideButtonPanelWidth + 510, 200)
		ElseIf roomHighlight
			UpdateRoomAgencyRoomDetails(roomHighlight, sideButtonPanelWidth + 510, 200)
		else
			UpdateRoomAgencyRoomDetails(Null, sideButtonPanelWidth + 510, 200)
		EndIf
		
		UpdateRoomAgencyRoomList(sideButtonPanelWidth + 5, 13)

		For Local b:TDebugControlsButton = EachIn buttonsRoomAgency
			b.Update()
		Next
	End Method


	Method RenderMode_RoomAgency()
		Local playerID:Int = GetShownPlayerID()

		RenderRoomAgencyRoomList(sideButtonPanelWidth + 5, 13)
		If roomHovered
			RenderRoomAgencyRoomDetails(roomHovered, sideButtonPanelWidth + 510, 200)
		ElseIf roomHighlight
			RenderRoomAgencyRoomDetails(roomHighlight, sideButtonPanelWidth + 510, 200)
		EndIf

		RenderActionButtons(buttonsRoomAgency)
	End Method
	

	Method UpdateRoomAgencyRoomDetails(room:TRoomBase, x:Int, y:Int, width:Int = 500, height:Int = 80)
		For Local button:TDebugControlsButton = EachIn buttonsRoomAgency
			button.visible = False
		Next

		if room
			buttonsRoomAgency[0].text  ="Rent for Player #" + GetShownPlayerID()

			If room.IsFreehold() or room.IsFake()
				buttonsRoomAgency[0].visible = False
				buttonsRoomAgency[1].visible = False
				buttonsRoomAgency[2].visible = False
			ElseIf room.IsRented() 
				buttonsRoomAgency[0].visible = False
				buttonsRoomAgency[1].visible = True
				buttonsRoomAgency[2].visible = False
			Else
				buttonsRoomAgency[0].visible = True
				buttonsRoomAgency[1].visible = False
				buttonsRoomAgency[2].visible = True
			EndIf
			
			If Not room.IsBlocked()
				buttonsRoomAgency[3].visible = True
				buttonsRoomAgency[4].visible = False
			Else
				buttonsRoomAgency[3].visible = False
				buttonsRoomAgency[4].visible = True
			EndIf
		EndIf
	End Method


	Method RenderRoomAgencyRoomDetails(room:TRoomBase, x:Int, y:Int, width:Int = 500, height:Int = 80)
		DrawOutlineRect(x, y, width, height)
		'offset content
		x:+ 5
		y:+ 5
		
		local textPosX:Int = x
		local textPosY:Int = y
		
		textFont.DrawSimple("Name: ", textPosX, textPosY)
		textFont.DrawSimple(room.GetDescription(1), textPosX + 50, textPosY)

		textPosY :+ 12
		textFont.DrawSimple("Size: ", textPosX, textPosY)
		textFont.DrawSimple(room.GetSize(), textPosX + 50, textPosY)
	
		textPosY :+ 12
		textFont.DrawSimple("Rentable: ", textPosX, textPosY)
		If room.IsRentable()
			textFont.DrawSimple("Yes", textPosX + 50, textPosY)
		ElseIf room.IsRentableIfNotRented()
			textFont.DrawSimple("If free", textPosX + 50, textPosY)
		Else
			textFont.DrawSimple("Never", textPosX + 50, textPosY)
		EndIf

		textPosY :+ 12
		textFont.DrawSimple("Blocked: ", textPosX, textPosY)
		If room.IsBlocked()
			textFont.DrawSimple("Yes", textPosX + 50, textPosY)
			textPosY :+ 12
			textFont.DrawSimple("till " + GetWorldTime().GetFormattedGameDate(room.GetBlockedUntilTime()), textPosX + 50, textPosY)
		Else
			textFont.DrawSimple("No", textPosX + 50, textPosY)
		EndIf
	End Method
	

	Method UpdateRoomAgencyRoomList(x:Int, y:Int)
		Local slotW:int = 118
		Local slotH:int = 16
		Local slotStepX:Int = 4
		Local slotCenterStepX:Int = 10
		Local slotStepY:Int = 4

		'offset content
		x:+ 5
		y:+ 5

		roomHovered = Null
		
		For local sign:TRoomBoardSign = EachIn GetRoomBoard().list
			local room:TRoomBase = TRoomDoor(sign.door).GetRoom()
			if not room then continue

			local slotX:int = x + (sign.GetOriginalSlot()-1) * (slotW + slotStepX)
			local slotY:int = y + (13 - sign.GetOriginalFloor()) * (slotH + slotStepY)
			if sign.GetOriginalSlot() > 2 then slotX :+ slotCenterStepX
			
			If THelper.MouseIn(slotX, slotY, slotW, slotH)
				roomHovered = room
				If MouseManager.IsClicked(1)
					roomHighlight = room
					'handle clicked
					MouseManager.SetClickHandled(1)

					exit
				EndIf
			EndIf
		Next		
	End Method
	
	
	Method RenderRoomAgencyRoomList(x:Int, y:Int)
		'- raeume
		'- selektierten "kick/block/rent" (aktueller Spieler)


		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		Local slotW:int = 118
		Local slotH:int = 16
		Local slotStepX:Int = 4
		Local slotCenterStepX:Int = 10
		Local slotStepY:Int = 4
		Local playerColors:TColor[4]
		For local i:int = 1 to 4
			playerColors[i-1] = TPlayerColor.getByOwner(i).copy().AdjustSaturation(-0.5)
		Next

		DrawOutlineRect(x, y, 4*slotW + (4-1)*slotStepX + slotCenterStepX + 10, 14 * slotH + (14-1) * slotStepY + 10)
		'offset content
		x:+ 5
		y:+ 5


		For local sign:TRoomBoardSign = EachIn GetRoomBoard().list
			local room:TRoomBase = TRoomDoor(sign.door).GetRoom()
			if not room then continue

			local slotX:int = x + (sign.GetOriginalSlot()-1) * (slotW + slotStepX)
			local slotY:int = y + (13 - sign.GetOriginalFloor()) * (slotH + slotStepY)
			if sign.GetOriginalSlot() > 2 then slotX :+ slotCenterStepX
			
			'ignore never-rentable rooms
			if room.IsFake() or room.IsFreeHold() 
				DrawOutlineRect(slotX, slotY, slotW, slotH, true, true, true, true, 0,0,0, 0.5, 0.0)
				SetAlpha oldColA * 0.45
			elseif room.GetOwner() <= 0 and not room.IsRentable()
				DrawOutlineRect(slotX, slotY, slotW, slotH, true, true, true, true, 50,0,0, 0.8, 0.0)
				SetAlpha oldColA * 0.80
			endif


			Select room.GetOwner()
				case 1,2,3,4
					If room.IsBlocked()
						playerColors[room.GetOwner() -1].Copy().AdjustBrightness(-0.2).SetRGBA()
					Else
						playerColors[room.GetOwner() -1].SetRGBA()
					EndIf
				default
					If room.IsBlocked()
						SetColor 50,50,50
					ElseIf room.IsFake() or room.IsFreeHold()
						SetColor 80,80,80
					Else
						SetColor 150,150,150
					EndIf
			End Select
				

			DrawRect(slotX + 1, slotY + 1, slotW - 2, slotH - 2) 
			SetAlpha oldColA
			textFont.DrawBox(sign.GetOwnerName(), slotX + 2, slotY + 2, slotW - 4, slotH - 2, SColor8.White)

			SetColor(oldCol)


			if room = roomHighlight
				SetBlend LIGHTBLEND
				SetAlpha 0.15
				SetColor 255,210,190
				DrawRect(slotX + 1, slotY + 1, slotW - 2, slotH - 2) 
				SetBlend ALPHABLEND
			endif
			if room = roomHovered
				SetBlend LIGHTBLEND
				SetAlpha 0.10
				DrawRect(slotX + 1, slotY + 1, slotW - 2, slotH - 2) 
				SetBlend ALPHABLEND
			endif

			SetColor(oldCol)
			SetAlpha(oldColA)
		Next		
	End Method
	

	'=== Politics screen ===

	Method InitMode_Politics()
		Local texts:String[] = ["Send Terrorist FR", "Send Terrorist VR", "Reset Terror Levels"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_Politics

			buttonsPolitics :+ [button]
		Next
	End Method


	Method ResetMode_Politics()
	End Method

	
	Function OnButtonClickHandler_Politics(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				If Not GetGame().networkGame
					TFigureTerrorist(GetGame().terrorists[0]).SetDeliverToRoom( GetRoomCollection().GetFirstByDetails("", "vrduban") )
				EndIf
			case 1
				If Not GetGame().networkGame
					TFigureTerrorist(GetGame().terrorists[1]).SetDeliverToRoom( GetRoomCollection().GetFirstByDetails("", "frduban") )
				EndIf
			case 2
				GetNewsAgency().SetTerroristAggressionLevel(0,0)
				GetNewsAgency().SetTerroristAggressionLevel(1,-1)
		End Select
'				if GetRoomAgency().CancelRoomRental(useRoom, GetPlayerBase().playerID)
'				GetRoomAgency().BeginRoomRental(useRoom, GetPlayerBase().playerID)

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_Politics()
		Local playerID:Int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn buttonsPolitics
			b.Update()
		Next
	End Method


	Method RenderMode_Politics()
		Local playerID:Int = GetShownPlayerID()

		RenderActionButtons(buttonsPolitics)
	End Method
	
	

	'=== Producers screen ===

	Method InitMode_Producers()
		Local texts:String[] = ["Produce Next (no impl)"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_Producers

			buttonsProducers :+ [button]
		Next
	End Method


	Method ResetMode_Producers()
	End Method


	Function OnButtonClickHandler_Producers(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
'
			case 1
'
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_Producers()
		For Local b:TDebugControlsButton = EachIn buttonsProducers
			b.Update()
		Next
	End Method


	Method RenderMode_Producers()
		RenderProducersList(sideButtonPanelWidth + 5, 13)

		RenderActionButtons(buttonsProducers)
	End Method
	
	
	Method RenderProducersList(x:Int, y:Int, w:Int=280, h:Int=363)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		Local mouseOverProducer:TProgrammeProducer

		titleFont.DrawSimple("Programme Producers: ", textX, textY)
		textY :+ 12 + 8

		For Local producer:TProgrammeProducerBase = EachIn GetProgrammeProducerCollection()
			textFont.DrawBox(producer.name + "  ("+producer.countryCode+")", textX, textY, w - 10 - 40, 15, sALIGN_LEFT_TOP, SColor8.White)
			textY :+ 10
			textFont.DrawBox("  " + TTypeID.ForObject(producer).name(), textX, textY, 150, 15, sALIGN_LEFT_TOP, new SColor8(220,220,220))
			textFont.DrawBox("XP: " + producer.experience, textX + 150, textY, 35, 15, sALIGN_LEFT_TOP, new SColor8(220,220,220))
			textFont.DrawBox("Budget: " + MathHelper.DottedValue(producer.budget), textX + 100 + 85, textY, 90, 15, sALIGN_LEFT_TOP, new SColor8(220,220,220))
			textY :+ 12
			if TProgrammeProducer(producer) 
				textY :- 2
				Local pp:TProgrammeProducer = TProgrammeProducer(producer)
				
				textFont.DrawBox("  Productions    Next: " + GetWorldTime().GetFormattedDate(pp.nextProductionTime, "g/h:i") , textX, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
				textFont.DrawBox("  Active: " + pp.activeProductions.Count() , textX + 130, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
				textFont.DrawBox("  Done: " + pp.producedProgrammeIDs.length, textX + 180, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
				textY :+ 10

				If pp.activeProductions.Count() > 0
					local listedProduction:int = 0
					local maxProductions:Int = Min(2, pp.activeProductions.Count())
					For local production:TProduction = EachIn pp.activeProductions
						if production and production.productionconcept.script.HasParentScript()
							textFont.DrawBox("  Prod: " + production.productionConcept.GetTitle() + " (Ep.)", textX, textY, w - 70, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
						Else
							textFont.DrawBox("  Prod: " + production.productionConcept.GetTitle(), textX, textY, w - 70, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
						EndIf
						if production.IsInProduction()
							textFont.DrawBox("End: " + GetWorldTime().GetFormattedDate(production.endTime, "g/h:i"), textX + w - 70, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
						else
							textFont.DrawBox("Start: " + GetWorldTime().GetFormattedDate(production.startTime, "g/h:i"), textX + w - 70, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
						endif

						textY :+ 10
						listedProduction :+ 1
						if listedProduction = maxProductions then exit
					Next
				EndIf
				If pp.producedProgrammeIDs.length > 0
					local listedLicences:int = 0
					local maxLicences:Int = Min(2, pp.producedProgrammeIDs.length)
					For local licenceID:Int = EachIn pp.producedProgrammeIDs
						local l:TProgrammeLicence = GetProgrammeLicenceCollection().Get(licenceID)
						if l and not l.IsEpisode()
							If l.IsSeries()
								textFont.DrawBox("  Lic: " + l.GetTitle() +" (Series, " + l.GetEpisodeCount() + " Ep.)", textX, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
							Else
								textFont.DrawBox("  Lic: " + l.GetTitle(), textX, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
							EndIf
							textY :+ 10
							listedLicences :+ 1
						endif
						if listedLicences = maxLicences then exit
					Next
				EndIf
			endif
			textY :+ 4
					
		Next
	End Method


	'=== Sports Sim screen ===

	Method InitMode_Sports()
		Local texts:String[] = ["Reset (no impl)"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_Sports

			buttonsSports :+ [button]
		Next
	End Method


	Method ResetMode_Sports()
	End Method


	Function OnButtonClickHandler_Sports(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
'
			case 1
'
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_Sports()
		For Local b:TDebugControlsButton = EachIn buttonsSports
			b.Update()
		Next
	End Method


	Method RenderMode_Sports()
		RenderActionButtons(buttonsSports)
		
		RenderSportsBlock(sideButtonPanelWidth + 5, 13)
	End Method
	
	
	Method RenderSportsBlock(x:Int, y:Int, w:Int=325, h:Int=300)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		
		
		Local mouseOverLeague:TNewsEventSportLeague

		titleFont.DrawSimple("Sport Leagues: ", textX, textY)
		textY :+ 12 + 8

		For Local sport:TNewsEventSport = EachIn GetNewsEventSportCollection()
			textFont.DrawBox(sport.name, textX, textY, w - 10 - 40, 15, sALIGN_LEFT_TOP, SColor8.White)
			textY :+ 12

			local seasonInfo:String
			if sport.IsSeasonStarted() then seasonInfo :+ "Started  "
			if sport.IsSeasonFinished() then seasonInfo :+ "Finished  "
			if sport.ReadyForNextSeason() then seasonInfo :+ "ReadyForNextSeason  "
			if sport.ArePlayoffsRunning() then seasonInfo :+ "Playoffs running  "
			if sport.ArePlayoffsFinished() then seasonInfo :+ "Playoffs finished  "
			textFont.DrawBox("  Season: " + seasonInfo, textX, textY, w, 15, sALIGN_LEFT_TOP, SColor8.White)
			textY :+ 12
			
			For local league:TNewsEventSportLeague = EachIn sport.leagues
				local col:SColor8 = SColor8.White

				if THelper.MouseIn(textX, textY, w, 12)
					mouseOverLeague = league 
					col = SColor8.Yellow
				endif
			
				textFont.DrawBox("  L: " + league.name, textX, textY, w, 15, sALIGN_LEFT_TOP, col)

				Local matchInfo:String
				matchInfo :+ "Matches " + GetWorldTime().GetFormattedDate(league.GetFirstMatchTime(), "g/h:i")
				matchInfo :+ " to " + GetWorldTime().GetFormattedDate(league.GetLastMatchTime(), "g/h:i")
				matchInfo :+ "   Next " + GetWorldTime().GetFormattedDate(league.GetNextMatchTime(), "g/h:i")
				textFont.DrawBox(matchInfo, textX + 115, textY, w - 100, 15, sALIGN_LEFT_TOP, col)
				If league.IsSeasonFinished() 
					textFont.DrawBox("FIN", textX + w - 35, textY, 25, 15, sALIGN_RIGHT_TOP, col)
				Else
					textFont.DrawBox(league.GetDoneMatchesCount() + "/" + league.GetMatchCount(), textX + w - 35, textY, 25, 15, sALIGN_RIGHT_TOP, col)
				EndIf

				textY :+ 12
			Next

			textY :+ 6
		Next
		
		
		if mouseOverLeague
			RenderSportsLeagueBlock(mouseOverLeague, x + w + 5, y)
		endif
	End Method


	Method RenderSportsLeagueBlock(league:TNewsEventSportLeague, x:Int, y:Int, w:Int=170, h:Int=300)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		
		titleFont.DrawSimple("Leaderboard", textX, textY)
		textY :+ 12 + 8
		
		For local rank:TNewsEventSportLeagueRank = EachIn league.GetLeaderboard()
			textFont.DrawBox(rank.team.GetTeamName(), textX, textY, w - 25, 15, sALIGN_LEFT_TOP, SColor8.White)
			textFont.DrawBox(rank.score, textX + w - 20, textY, 20, 15, sALIGN_LEFT_TOP, SColor8.White)
			textY :+ 12
			textFont.DrawBox("Attr: " + MathHelper.NumberToString(rank.team.GetAttractivity()*100,0) + "  Pwr: " + MathHelper.NumberToString(rank.team.GetPower()*100,0) + "  Skill: " + MathHelper.NumberToString(rank.Team.GetSkill()*100,0), textX, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(220,220,220))
			textY :+ 12 + 4 
		Next		
		
	End Method

	
	
	'=== MODIFIERS screen ===

	Method InitMode_Modifiers()
		rem
		 none for now
		Local texts:String[] = ["Nothing"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = New TDebugControlsButton
			button.w = 180
			button.h = 15
			button.x = sideButtonPanelWidth + 10
			button.y = 10 + i * (button.h + 3)
			button.dataInt = i
			button.text = texts[i]
			button._onClickHandler = OnButtonClickHandler_Modifiers

			buttonsModifiers :+ [button]
		Next
		endrem
	End Method


	Method ResetMode_Modifiers()
	End Method


	Function OnButtonClickHandler_Modifiers(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				'nothing
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_Modifiers()
		Local playerID:Int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn buttonsModifiers
			b.Update()
		Next
	End Method


	Method RenderMode_Modifiers()
		Local playerID:Int = GetShownPlayerID()

		RenderActionButtons(buttonsModifiers)

		RenderGameModifierList(playerID, sideButtonPanelWidth + 5, 13)
	End Method
	

	'=== MISC screen ===

	Method InitMode_Misc()
		Local texts:String[] = ["Print Ad Stats", "Print Player's Today Finance Overview", "Print All Players' Finance Overview", "Print Player's Today Broadcast Stats", "Print Total Broadcast Stats", "Print Performance Stats", "Print Player's Programme Plan", "AI Game", "Fast Forward One Day"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = New TDebugControlsButton
			button.w = 180
			button.h = 15
			button.x = sideButtonPanelWidth + 10
			button.y = 10 + i * (button.h + 3)
			button.dataInt = i
			button.text = texts[i]
			button._onClickHandler = OnButtonClickHandler_Misc

			buttonsMisc :+ [button]
		Next

		InitAwardStatusButtons()
	End Method


	Method ResetMode_Misc()
		FastForward_Continuous_Active = False
		FastForward_Active = False
		FastForwardSpeed = 500
		FastForward_SwitchedPlayerToAI = 0
		FastForward_TargetTime = -1
		FastForward_SpeedFactorBackup = 0.0
		FastForward_TimeFactorBackup = 0.0
		FastForward_BuildingTimeSpeedFactorBackup = 0.0
	End Method


	Function OnButtonClickHandler_Misc(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				Local adList:TList = CreateList()
				For Local a:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
					adList.AddLast(a)
				Next
				adList.Sort(True, TAdContractBase.SortByName)


				Print "==== AD CONTRACT OVERVIEW ===="
				Print ".---------------------------------.------------------.---------.----------.----------.-------.-------."
				Print "| Name                            | Audience       % |  Image  |  Profit  |  Penalty | Spots | Avail |"
				Print "|---------------------------------+------------------+---------+----------+----------|-------|-------|"

				'For local a:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
				For Local a:TAdContractBase = EachIn adList
					Local ad:TAdContract = New TAdContract
					'do NOT call ad.Create() as it adds to the adcollection
					ad.base = a
					Local title:String = LSet(a.GetTitle(), 30)
					Local audience:String = LSet( RSet(ad.GetMinAudience(), 7), 8)+"  "+RSet( MathHelper.NumberToString(100 * a.minAudienceBase,2)+"%", 6)
					Local image:String =  RSet(MathHelper.NumberToString(ad.GetMinImage()*100, 2)+"%", 7)
					Local profit:String =  RSet(ad.GetProfit(), 8)
					Local penalty:String =  RSet(ad.GetPenalty(), 8)
					Local spots:String = RSet(ad.GetSpotCount(), 5)
					Local availability:String = ""
					Local targetGroup:String = ""
					If ad.GetLimitedToTargetGroup() > 0
						targetGroup = "* "+ getLocale("AD_TARGETGROUP")+": "+ad.GetLimitedToTargetGroupString()
						title :+ "*"
					Else
						title :+ " "
					EndIf
					If ad.base.IsAvailable()
						availability = RSet("Yes", 5)
					Else
						availability = RSet("No", 5)
					EndIf

					Print "| "+title + " | " + audience + " | " + image + " | " + profit + " | " + penalty + " | " + spots+" | " + availability +" |" + targetgroup

				Next
				Print "'---------------------------------'------------------'---------'----------'----------'-------'-------'"
'
			case 1
				'single overview - only today
				Local text:String[] = GetPlayerFinanceOverviewText(GetPlayer().playerID, GetWorldTime().GetOnDay() -1 )
				For Local s:String = EachIn text
					Print s
				Next

			case 2
				Local playerIDs:Int[] = [1,2,3,4]

				Print "====== TOTAL FINANCE OVERVIEW ======" + "~n"
				Local result:String = ""
				For Local day:Int = GetWorldTime().GetStartDay() To GetworldTime().GetDay()
					For Local playerID:Int = EachIn playerIDs
						For Local s:String = EachIn GetPlayerFinanceOverviewText(playerID, day)
							result :+ s+"~n"
						Next
					Next
					result :+ "~n~n"
				Next

				Local logFile:TStream = WriteStream("utf8::" + "logfiles/log.financeoverview.txt")
				logFile.WriteString(result)
				logFile.close()
				Print result
				Print "===================================="

			case 3
				Print GetBroadcastOverviewString()

			case 4
				Print "====== TOTAL BROADCAST OVERVIEW ======" + "~n"
				Local result:String = ""
				For Local day:Int = GetWorldTime().GetStartDay() To GetworldTime().GetDay()
					result :+ GetBroadcastOverviewString(day)
				Next

				Local logFile:TStream = WriteStream("utf8::" + "logfiles/log.broadcastoverview.txt")
				logFile.WriteString(result)
				logFile.close()
				Print result
				Print "======================================"

			case 5
				Print "====== TOTAL PLAYER PERFORMANCE OVERVIEW ======" + "~n"
				Local result:String = ""
				For Local day:Int = GetWorldTime().GetStartDay() To GetworldTime().GetDay()
					Local text:String[] = GetPlayerPerformanceOverviewText(day)
					For Local s:String = EachIn text
						result :+ s + "~n"
					Next
				Next

				Local logFile:TStream = WriteStream("utf8::" + "logfiles/log.playerperformanceoverview.txt")
				logFile.WriteString(result)
				logFile.close()

				Print result
				Print "==============================================="
				
			case 6
				GetPlayer().GetProgrammePlan().printOverview()
			case 7
				'continuous fast forward: save game at the end of every day
				If FastForward_Continuous_Active then
					FastForward_Continuous_Active = False
					FastForward_TargetTime = -1
					GetGame().SetGameSpeedPreset(1)
				Else
					FastForward_Continuous_Active = True
					FastForward_TargetTime = GetWorldTime().CalcTime_DaysFromNowAtHour(-1,0,0,23,23) + 56*TWorldTime.MINUTELENGTH
					GetGame().SetGameSpeed(FastForwardSpeed)
				EndIf
			case 8
				DebugScreen.Dev_FastForwardToTime(GetWorldTime().GetTimeGone() + 1*TWorldTime.DAYLENGTH, DebugScreen.GetShownPlayerID())
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_Misc()
		Local playerID:Int = GetShownPlayerID()

		If FastForward_Continuous_Active then
			DebugScreen.buttonsMisc[7].text = "Stop AI Game"
		Else
			DebugScreen.buttonsMisc[7].text = "AI Game"
		EndIf

		For Local b:TDebugControlsButton = EachIn buttonsMisc
			b.Update()
		Next
		
		UpdateAwardStatus(sideButtonPanelWidth + 5 + 190, 13)
	End Method


	Method RenderMode_Misc()
		Local playerID:Int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn buttonsMisc
			b.Render()
		Next
		
		RenderAwardStatus(sideButtonPanelWidth + 5 + 190, 13)
	End Method




	'=== BLOCKS ===
	Method InitAwardStatusButtons()
		Local texts:String[] = ["Finish", "P1", "P2", "P3", "P4", "Start Next", "Random", "Audience", "Culture" ,"Custom Production", "News"]
		Local mode:int = 0
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			if texts[i] = "-" then continue 'spacer
			button = New TDebugControlsButton
			button.w = 145
			button.h = 15
			button.x = 5
			button.y = 10 + i * (button.h + 3)
			button.dataInt = mode
			button.text = texts[i]
			button._onClickHandler = OnButtonClickHandler_AwardStatusButtons
			
			mode :+ 1

			buttonsAwardControls :+ [button]
		Next
	End Method


	Function OnButtonClickHandler_AwardStatusButtons(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				'finish
				GetAwardCollection().FinishCurrentAward()
			case 1
				'finish P1
				GetAwardCollection().FinishCurrentAward(1)
			case 2
				'finish P2
				GetAwardCollection().FinishCurrentAward(2)
			case 3
				'finish P3
				GetAwardCollection().FinishCurrentAward(3)
			case 4
				'finish P4
				GetAwardCollection().FinishCurrentAward(4)
			case 5
				'start next (stop current first - if needed)
				if GetAwardCollection().GetCurrentAward()
					GetAwardCollection().FinishCurrentAward()
				Endif
				GetAwardCollection().SetCurrentAward( GetAwardCollection().PopNextAward() )
			case 6
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(-1, Null)
			case 7
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(TVTAwardType.AUDIENCE, Null)
			case 8
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(TVTAwardType.CULTURE, Null)
			case 9
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(TVTAwardType.CUSTOMPRODUCTION, Null)
			case 10
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(TVTAwardType.NEWS, Null)
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateAwardStatus(x:int, y:int, w:int = 200, h:int = 200)
		if buttonsAwardControls.length >= 6
			buttonsAwardControls[ 0].SetXY(x + 200              , y + 0 * 18 + 5).SetWH( 50, 15)
			buttonsAwardControls[ 1].SetXY(x + 200 + 54 + 0 * 22, y + 0 * 18 + 5).SetWH( 20, 15)
			buttonsAwardControls[ 2].SetXY(x + 200 + 54 + 1 * 22, y + 0 * 18 + 5).SetWH( 20, 15)
			buttonsAwardControls[ 3].SetXY(x + 200 + 54 + 2 * 22, y + 0 * 18 + 5).SetWH( 20, 15)
			buttonsAwardControls[ 4].SetXY(x + 200 + 54 + 3 * 22, y + 0 * 18 + 5).SetWH( 20, 15)
			buttonsAwardControls[ 5].SetXY(x + 200              , y + 0 * 18 + 5).SetWH(145, 15)
			'add award - genres
			buttonsAwardControls[ 6].SetXY(x + 200              , y + 2 * 18 + 5).SetWH(145, 15)
			buttonsAwardControls[ 7].SetXY(x + 200              , y + 3 * 18 + 5).SetWH(145, 15)
			buttonsAwardControls[ 8].SetXY(x + 200              , y + 4 * 18 + 5).SetWH(145, 15)
			buttonsAwardControls[ 9].SetXY(x + 200              , y + 5 * 18 + 5).SetWH(145, 15)
			buttonsAwardControls[10].SetXY(x + 200              , y + 6 * 18 + 5).SetWH(145, 15)
		
			if not GetAwardCollection().GetCurrentAward()
				buttonsAwardControls[0].visible = False
				buttonsAwardControls[1].visible = False
				buttonsAwardControls[2].visible = False
				buttonsAwardControls[3].visible = False
				buttonsAwardControls[4].visible = False
				buttonsAwardControls[5].visible = true
			else
				buttonsAwardControls[0].visible = True
				buttonsAwardControls[1].visible = True
				buttonsAwardControls[2].visible = True
				buttonsAwardControls[3].visible = True
				buttonsAwardControls[4].visible = True
				buttonsAwardControls[5].visible = False
			endif
			
			if not GetAwardCollection().GetCurrentAward() and not GetAwardCollection().GetNextAward()
				buttonsAwardControls[0].visible = False
				buttonsAwardControls[5].visible = False
			endif
		endif


		For Local b:TDebugControlsButton = EachIn buttonsAwardControls
			b.Update()
		Next
	End Method
	
	
	Method RenderAwardStatus(x:int, y:int, w:int = 350, h:int = 200)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		
		titleFont.DrawSimple("Award: ", textX, textY)
		textY :+ 12 + 3
		
		local currentAward:TAward = GetAwardCollection().GetCurrentAward()
		local nextAward:TAward = GetAwardCollection().GetNextAward()
		local nextAwardTime:Long = GetAwardCollection().GetNextAwardTime()

		textFont.DrawSimple("Current: ", textX, textY)
		If currentAward 
			textFont.DrawSimple(currentAward.GetTitle(), textX + 40, textY)
			textY :+ 12

			local rewards:String = currentAward.GetRewardText()
			if rewards.length > 0
				textY :+ textFont.DrawBox(rewards, textX + 40, textY, w - 150 - 40 - 10, 100, sALIGN_LEFT_TOP, SColor8.White, new SVec2F(0,0), EDrawTextOption.IgnoreColor).y
			Endif
			textFont.DrawSimple("Ends " + GetWorldTime().GetFormattedGameDate(currentAward.GetEndTime()), textX + 40, textY)
			textY :+ 12
			
			'ranking
			For Local i:Int = 1 To 4
				local myX:Int = textX + 40
				local myY:Int = textY
				if i = 2 or i = 4 then myX :+ 80
				if i = 3 or i = 4 then myY :+ 12
				textFont.DrawSimple("P"+i, myX, myY)
				textFont.DrawBox(currentAward.GetScore(i) +" (", myX, myY, 40, 100, sALIGN_RIGHT_TOP, SColor8.WHITE)
				textFont.DrawBox(int(currentAward.GetScoreShare(i)*100 + 0.5)+"%)", myX + 35, myY, 30, 100, sALIGN_RIGHT_TOP, SColor8.WHITE)
			Next
			textY :+ 2*12
			
		Else
			textFont.DrawSimple("--", textX + 40, textY)
			textY :+ 12
		endif
		textY :+ 3

		local nextCount:int = 0
		if GetAwardCollection().upcomingAwards.Count() = 0
			textFont.DrawSimple("Next:", textX, textY)
			textFont.DrawSimple("--", textX + 40, textY)
				textY :+ 12
		Else
			For local nextAward:TAward = EachIn GetAwardCollection().upcomingAwards
				textFont.DrawSimple("Next:", textX, textY)
				if nextAward
					textFont.DrawSimple(nextAward.GetTitle(), textX + 40, textY)
					textY :+ 12

					'only render details for very next
					if nextCount = 0
						local rewards:String = nextAward.GetRewardText()
						if rewards.length > 0
							textY :+ textFont.DrawBox(rewards, textX + 40, textY, w - 150 - 40 - 10, 100, sALIGN_LEFT_TOP, SColor8.white, New SVec2F(0,0), EDrawTextOption.IgnoreColor).y
						Endif
					endif
					textFont.DrawSimple("Begins " + GetWorldTime().GetFormattedGameDate(nextAward.GetStartTime()), textX + 40, textY)
					textY :+ 12
				Else
					textFont.DrawSimple("--", textX + 40, textY)
					textY :+ 12
				EndIf
				
				nextCount :+ 1
				'do not show more than 3
				if nextCount > 3 then exit
			Next
		EndIf


		textFont.DrawSimple("Add new award: ", buttonsAwardControls[6].x, buttonsAwardControls[6].y - 12)
		For Local b:TDebugControlsButton = EachIn buttonsAwardControls
			b.Render()
		Next
	End Method
	

	Method RenderGameModifierList(playerID:int, x:int, y:int, w:int = 300, h:int = 300)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		titleFont.DrawSimple("Game Modifiers: ", textX, textY)

		textY :+ 12 

		Local data:TData = GameConfig._modifiers
		If data
			For Local k:TLowerString = EachIn data.data.Keys()
				If textY + 12 > y + h Then Continue

				textFont.DrawBox(k.ToString(), textX, textY, w - 10 - 40, 15, sALIGN_LEFT_TOP, SColor8.White)
				textFont.DrawBox(MathHelper.NumberToString(data.GetFloat(k.ToString()), 3), textX, textY, w - 10, 15, sALIGN_RIGHT_TOP, SColor8.White)
				textY :+ 12
			Next
		EndIf
	End Method


	Method RenderScriptAgencyInformation(playerID:int, x:int, y:int, w:int = 200, h:int = 30)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		textFont.DrawSimple("Offer refill: " + GetGameBase().refillScriptAgencyTime +"min", x, y)
	End Method


	Method UpdateScriptAgencyOffers(playerID:int, x:int, y:int, w:int = 400, h:int = 150)
		scriptAgencyOfferHightlight = null


		Local textX:Int = x + 5
		Local textY:Int = y + 5

		textY :+ 15
		if not scriptAgencyOfferHightlight
			For local script:TScript = EachIn GetScriptCollection().GetUsedScriptList()
				if not script.isOwnedByVendor() continue
				if THelper.MouseIn(textX, textY, 200, 13)
					scriptAgencyOfferHightlight = script
					exit
				EndIf
				textY:+ 13
			Next
		endif

'		textY = y + 5
'		textX :+ 200
		textY :+ 15
		if not scriptAgencyOfferHightlight
			For local script:TScript = EachIn GetScriptCollection().GetAvailableScriptList()
				if THelper.MouseIn(textX, textY, 200, 13)
					scriptAgencyOfferHightlight = script
					exit
				EndIf
				textY:+ 13
			Next
		endif

	End Method


	Method RenderScriptAgencyOffers(playerID:int, x:int, y:int, w:int = 400, h:int = 150)
		DrawOutlineRect(x, y, w, h + 120)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		Local entryNum:Int = 0
		Local oldAlpha:Float = GetAlpha()
		Local barWidth:int = 180

		textFontBold.Draw("Offered:", textX, textY)
		textY :+ 14
		For local script:TScript = EachIn GetScriptCollection().GetUsedScriptList()
			If Not script.isOwnedByVendor() Then continue
			RenderScript(script, entryNum, textX, textY, barWidth, oldAlpha, scriptAgencyOfferHightlight)
			textY:+ 13
			entryNum :+ 1
		Next

		textY:+ 5
		textFontBold.Draw("Available:", textX, textY)
		textY :+ 15
		entryNum = 0
		For local script:TScript = EachIn GetScriptCollection().GetAvailableScriptList()
			RenderScript(script, entryNum, textX, textY, barWidth, oldAlpha, scriptAgencyOfferHightlight)
			textY:+ 13
			entryNum :+ 1
		Next

		textY = y + 5
		textX :+ 200
		textFontBold.Draw("Player owned:", textX, textY)
		textY :+ 15
		entryNum = 0
		For local script:TScript = EachIn GetScriptCollection().GetUsedScriptList()
			If Not script.IsOwnedByPlayer(GetShownPlayerID()) continue
			RenderScript(script, entryNum, textX, textY, barWidth, oldAlpha, scriptAgencyOfferHightlight)
			textY:+ 13
			entryNum :+ 1
		Next
		
		Function RenderScript(script:TScript, entryNum:Int, textX:Int, textY:Int, barWidth:Int, oldAlpha:Float, scriptAgencyOfferHightlight:Tscript)
			If entryNum Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 60,60,60
			EndIf
			SetAlpha 0.75 * oldAlpha
			DrawRect(textX, textY, barWidth, 12)

			SetColor 255,255,255
			SetAlpha oldAlpha

			if script = scriptAgencyOfferHightlight
				SetAlpha 0.25 * oldAlpha
				SetBlend LIGHTBLEND
				DrawRect(textX, textY, barWidth, 12)
				SetAlpha oldAlpha
				SetBlend ALPHABLEND
			endif

			textFont.DrawSimple(script.GetTitle(), textX, textY - 2)
		End Function
	End Method


	Method RenderNewsAgencyInformation(playerID:int, x:int, y:int, w:int = 180, h:int = 150)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		textFont.DrawSimple("Player News Subscriptions", textX, textY)
		textY :+ 12 + 3

		Local playerIndex:Int = 0
		Local textYBackup:Int = textY
		For local player:TPlayerBase = EachIn GetPlayerBaseCollection().players
			textFont.DrawSimple(player.name, textX + playerIndex * 70, textY, player.color.Copy().AdjustBrightness(0.5).ToSColor8())
			textY :+ 12 + 3
			For local genre:Int = 0 until player.newsabonnements.length
				Local currLevel:Int = player.GetNewsAbonnement(genre)
				Local maxLevel:Int = max(0, player.GetNewsAbonnementDaysMax(genre))
				if currLevel < maxLevel
					textFont.DrawSimple(currLevel + " / " + maxLevel + " @ " + GetWorldTime().GetFormattedDate(player.newsabonnementsSetTime[genre], "h:i"), textX + playerIndex * 70, textY, SColor8.white)
				ElseIf currLevel > maxLevel
					'add time until "fixation" (so "end time")
					textFont.DrawSimple(currLevel + " @ " + GetWorldTime().GetFormattedDate(player.newsabonnementsSetTime[genre] + GameRules.newsSubscriptionIncreaseFixTime, "h:i") + " / " + maxLevel, textX + playerIndex * 70, textY, SColor8.white)
				Else
					textFont.DrawSimple(currLevel + " / " + maxLevel, textX + playerIndex * 70, textY, SColor8.white)
				endif
				textY :+ 12
			Next

			textY = textYBackup
			playerIndex :+ 1
		Next
	End Method



	Method RenderNewsAgencyGenreSchedule(playerID:int, x:int, y:int, w:int = 200, h:int = 100)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		local upcomingCount:int[TVTNewsGenre.count+1]
		For local n:TNewsEvent = EachIn GetNewsEventCollection().GetUpcomingNewsList()
			upcomingCount[n.GetGenre()] :+ 1
		Next

		textFont.DrawSimple("Scheduled News", textX, textY)
		textY :+ 12 + 3
		textFont.DrawSimple("Genre", textX, textY)
		textFont.DrawSimple("Next", textX + 100, textY)
		textFont.DrawSimple("Upcoming", textX + 140, textY)
		textY :+ 12 + 3
		For local i:int = 0 until TVTNewsGenre.count
			textFont.DrawSimple(GetLocale("NEWS_"+TVTNewsGenre.GetAsString(i)), textX, textY)
			textFont.DrawSimple(GetWorldTime().GetFormattedTime(GetNewsAgency().NextEventTimes[i]), textX + 100, textY)
			textFont.DrawSimple(upcomingCount[i]+"x", textX + 140, textY)
			textY :+ 12
		Next
	End Method
	
	

	Method UpdateNewsAgencyQueue(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		'reset
		'newsAgencyNewsHighlight = null
	End Method


	Method RenderNewsAgencyQueue(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		
		Local upcoming:TList = GetNewsEventCollection().GetUpcomingNewsList()

		textFont.DrawSimple("Queue", textX, textY)
		textY :+ 12+3
		if upcoming.Count() = 0
			textFont.DrawSimple("--", textX, textY)
		else
			Local upcomingSorted:TList = upcoming.Copy()
			upcomingSorted.sort(True, TNewsEventCollection.SortByHappenedTime)

			local nCount:Int
			For local n:TNewsEvent = EachIn upcomingSorted
				textFont.DrawSimple(GetWorldTime().GetFormattedGameDate(n.happenedTime), textX, textY)
				textFont.DrawSimple(n.GetTitle() + "  ("+GetLocale("NEWS_"+TVTNewsGenre.GetAsString(n.GetGenre()))+")", textX + 100, textY)
				textY :+ 12
				nCount :+ 1
				if nCount > 12 then exit
			Next
		endif
	End Method


	Method RenderFigureInformation(figure:TFigure, x:int, y:int)
		DrawOutlineRect(x, y, 150, 70)

		Local oldCol:SColor8; GetColor(oldCol)

		local usedDoorText:string = ""
		local targetText:string = ""
		if TRoomDoor(figure.usedDoor) then usedDoorText = TRoomDoor(figure.usedDoor).GetRoom().GetName()
		if figure.GetTarget()
			local t:object = figure.GetTarget()
			if TRoomDoor(figure.GetTargetObject())
				targetText = TRoomDoor(figure.GetTargetObject()).GetRoom().GetName()
			elseif THotSpot(figure.GetTargetObject())
				targetText = "Hotspot"
			else
				targetText = "Building"
			endif
			targetText :+ " (" + figure.GetTargetMovetoPosition().ToString() + ")"
		endif


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

		If not figure.isControllable() then roomName :+" (f)"


		SetColor 255,255,255
		local textY:int = y + 5 - 1
		titleFont.Draw(figure.name, x + 5, textY)
		if not figure.CanMove() then textFont.DrawBox("cannot move", x, textY, 150 - 3, 14, sALIGN_RIGHT_TOP, SColor8.White)
		textY :+ 10
		textFont.DrawSimple(roomName, x + 5, textY)
		textY :+ 10
		if targetText then textFont.DrawSimple("-> " + targetText, x + 5, textY)
		'textY :+ 10
		'textFont.draw("usedDoor: " + usedDoorText, x + 5, textY)
		
		SetColor(oldCol)
	End Method


	Method RenderBossMood(playerID:Int, x:Int, y:Int, w:int, h:int)
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


	Method RenderPlayerTaskList(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)

		If player.playerAI
			SetColor 40,40,40
			DrawRect(x, y, 185, 135)
			SetColor 50,50,40
			DrawRect(x+1, y+1, 183, 23)
			SetColor 255,255,255

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


	Method RenderPlayerEventQueue(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)

		If player.playerAI
			SetColor 40,40,40
			DrawRect(x, y, 185, 10 * 10 + 25)
			SetColor 255,255,255

			Local textX:Int = x + 3
			Local textY:Int = y + 3 - 1
			
			textFont.Draw("Event Queue: " + player.playerAI.eventQueue.length + " event(s).", textX, textY)
			textY :+ 12

			local eventNumber:Int = 0
			For local aievent:TAIEvent = EachIn player.playerAI.eventQueue
				textFont.DrawBox(aievent.ID, textX, textY, 15, 13, sALIGN_RIGHT_TOP, SColor8.white)
				textFont.DrawBox(aievent.GetName(), textX + 18, textY, 179 - 18, 13, SColor8.white)
				textY :+ 10
				eventNumber :+ 1
				
				'only print up to 20 events ...
				if eventNumber > 10 then exit
			Next
		EndIf
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



	Function DrawOutlineRect(x:int, y:int, w:int, h:int, borderTop:int = True, borderRight:int = True, borderBottom:int = True, borderLeft:Int = True, r:int = 0, g:int = 0, b:int = 0, borderAlpha:Float = 0.5, bgAlpha:Float = 0.5)
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		SetColor(r, g, b)

		SetAlpha(bgAlpha * oldColA)
		DrawRect(x+2, y+2, w-4, h-4)

		SetAlpha(borderAlpha * oldColA)
		if borderTop then DrawRect(x, y, w, 2)
		if borderRight then DrawRect(x + w - 2, y, 2, h)
		if borderBottom then DrawRect(x, y + h - 2, w, 2)
		if borderLeft then DrawRect(x, y, 2, h)

		SetAlpha(oldColA)
		SetColor(oldCol)
	End Function


	Method Dev_StopFastForwardToTime()
		If FastForward_Active
			FastForward_Active = False
			
			If FastForward_SwitchedPlayerToAI > 0 
				DebugScreen.Dev_SetPlayerAI(FastForward_SwitchedPlayerToAI, False)
				FastForward_SwitchedPlayerToAI = 0
			EndIf

			TEntity.globalWorldSpeedFactor = FastForward_SpeedFactorBackup
			GetWorldTime().SetTimeFactor(FastForward_TimeFactorBackup)
			GetBuildingTime().SetTimeFactor(FastForward_BuildingTimeSpeedFactorBackup)
		EndIf
	End Method
	

	Method Dev_FastForwardToTime(time:Long, switchPlayerToAI:Int=0)
		'just update time? / avoid backupping the modified speeds
		If FastForward_Active
			FastForward_TargetTime = time
		Else
			FastForward_Active = True
			
			FastForward_TargetTime = time

			If switchPlayerToAI > 0 and GetPlayer(switchPlayerToAI).IsLocalHuman()
				FastForward_SwitchedPlayerToAI = switchPlayerToAI
				DebugScreen.Dev_SetPlayerAI(switchPlayerToAI, True)
			EndIf

			FastForward_SpeedFactorBackup = TEntity.globalWorldSpeedFactor
			FastForward_TimeFactorBackup = GetWorldTime()._timeFactor
			FastForward_BuildingTimeSpeedFactorBackup = GetBuildingTime()._timeFactor

			GetGame().SetGameSpeed( 150 * 60 )
		EndIf
	End Method


	Function Dev_MaxAudience(playerID:Int)
		GetStationMap(playerID).CheatMaxAudience()
		GetGame().SendSystemMessage("[DEV] Set Player #" + playerID + "'s maximum audience to " + GetStationMap(playerID).GetReach())
	End Function


	Function Dev_SetMasterKey(playerID:Int, bool:Int)
		Local player:TPlayer = GetPlayer(playerID)
		player.GetFigure().SetHasMasterkey(bool)
		If bool
			GetGame().SendSystemMessage("[DEV] Added masterkey to player '" + player.name +"' ["+player.playerID + "]!")
		Else
			GetGame().SendSystemMessage("[DEV] Removed masterkey from player '" + player.name +"' ["+player.playerID + "]!")
		EndIf
	End Function


	Function Dev_SetPlayerAI:Int(playerID:Int, bool:int)
		Local player:TPlayer = GetPlayer(playerID)
		if not player then return False

		If bool
			If Not player.IsLocalAI()
				player.SetLocalAIControlled()
				'reload ai - to avoid using "outdated" information
				player.InitAI( New TAI.Create(player.playerID, GetGame().GetPlayerAIFileURI(player.playerID)) )
				player.playerAI.CallOnInit()
				'player.PlayerAI.CallLuaFunction("OnForceNextTask", null)
				GetGame().SendSystemMessage("[DEV] Enabled AI for player "+player.playerID)
			Else
				GetGame().SendSystemMessage("[DEV] Already enabled AI for player "+player.playerID)
			EndIf
		Else
			If player.IsLocalAI()
				'calling "SetLocalHumanControlled()" deletes AI too
				player.SetLocalHumanControlled()
				GetGame().SendSystemMessage("[DEV] Disabled AI for player "+player.playerID)
			Else
				GetGame().SendSystemMessage("[DEV] Already disabled AI for player "+player.playerID)
			EndIf
		EndIf
	End Function
End Type
Global DebugScreen:TDebugScreen = New TDebugScreen



Type TDebugAudienceInfo
	Field currentStatement:TBroadcastFeedbackStatement
	Field lastCheckedMinute:Int
	
	
	Method Reset()
		currentStatement = Null
		lastCheckedMinute = 0
	End Method


	Method Update(playerID:Int, x:Int, y:Int)
	End Method


	Method Draw()
		SetColor 0,0,0
		DrawRect(0,0,800,385)
		SetColor 255, 255, 255

		'GetBitmapFontManager().baseFont.Draw("Bevölkerung", 25, startY)

		Local playerID:Int = TIngameInterface.GetInstance().ShowChannel
		If playerID <= 0 Then playerID = GetPlayerBaseCollection().playerID

		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( playerID )

		Local x:Int = 200
		Local y:Int = 25
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		GetBitmapFontManager().baseFont.DrawBox("|b|Taste |color=255,100,0|~qQ~q|/color| drücken|/b| um (Debug-)Quotenbildschirm wieder auszublenden. Spielerwechsel: TV-Kanalbuttons", 0, 360, GetGraphicsManager().GetWidth(), 25, sALIGN_CENTER_CENTER, SColor8.Red)

		font.DrawBox("Gesamt", x, y, 65, 25, sALIGN_RIGHT_TOP, SColor8.Red)
		font.DrawBox("Kinder", x + (70*1), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Jugendliche", x + (70*2), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Hausfrau.", x + (70*3), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Arbeitneh.", x + (70*4), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Arbeitslose", x + (70*5), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Manager", x + (70*6), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Rentner", x + (70*7), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)


		font.DrawSimple("Bevölkerung", 25, 50, SColor8.White)
		DrawAudience(audienceResult.WholeMarket, 200, 50)

		Local percent:String = MathHelper.NumberToString(audienceResult.GetPotentialMaxAudienceQuotePercentage()*100,2) + "%"
		font.DrawSimple("Potentielle Zuschauer", 25, 70, SColor8.White)
		font.DrawSimple(percent, 160, 70, SColor8.White)
		DrawAudience(audienceResult.PotentialMaxAudience, 200, 70)

		Local colorLight:SColor8 = new SColor8(150, 150, 150)

		'font.drawStyled("      davon Exklusive", 25, 90, TColor.clWhite)
		'DrawAudience(audienceResult.ExclusiveAudienceSum, 200, 90, true)

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 105, colorLight)
		'DrawAudience(audienceResult.AudienceFlowSum, 200, 105, true)

		'font.drawStyled("      davon Zapper", 25, 120, colorLight)
		'DrawAudience(audienceResult.ChannelSurferToShare, 200, 120, true)


		font.DrawSimple("Aktuelle Zuschauerzahl", 25, 90, SColor8.White)
		percent = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage()*100,2) + "%"
		font.DrawSimple(percent, 160, 90, SColor8.White)
		DrawAudience(audienceResult.Audience, 200, 90)

		'font.drawStyled("      davon Exklusive", 25, 155, colorLight)
		'DrawAudience(audienceResult.ExclusiveAudience, 200, 155, true)

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 170, colorLight)
		'DrawAudience(audienceResult.AudienceFlow, 200, 170, true)

		'font.drawStyled("      davon Zapper", 25, 185, colorLight)
		'DrawAudience(audienceResult.ChannelSurfer, 200, 185, true)





		Local attraction:TAudienceAttraction = audienceResult.AudienceAttraction
		Local genre:String = "kein Genre"
		Select attraction.BroadcastType
			Case TVTBroadcastMaterialType.PROGRAMME
				If (attraction.BaseAttraction <> Null And attraction.genreDefinition)
					genre = GetLocale("PROGRAMME_GENRE_"+TVTProgrammeGenre.GetAsString(attraction.genreDefinition.referenceID))
				EndIf
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				If (attraction.BaseAttraction <> Null)
					genre = GetLocale("INFOMERCIAL")
				EndIf
			Case TVTBroadcastMaterialType.NEWSSHOW
				If (attraction.BaseAttraction <> Null)
					genre = "News-Genre-Mix"
				EndIf
		End Select

		Local offset:Int = 110

		GetBitmapFontManager().baseFontBold.DrawSimple("Sendung: " + audienceResult.GetTitle() + "     (" + genre + ") [Spieler: "+playerID+"]", 25, offset, SColor8.Red)
		offset :+ 20

		font.DrawSimple("1. Programmqualität & Aktual.", 25, offset, SColor8.White)
		If attraction.Quality
			DrawAudiencePercent(New TAudience.InitValue(attraction.Quality,  attraction.Quality), 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("2. * Zielgruppenattraktivität", 25, offset, SColor8.White)
		If attraction.targetGroupAttractivity
			DrawAudiencePercent(attraction.targetGroupAttractivity, 200, offset, True, True)
		Else
'			print "   dyn: "+  attraction.GetTargetGroupAttractivity().ToString()
		EndIf
		offset :+ 20

		font.DrawSimple("3. * TrailerMod ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_TRAILER*100)+"%)", 25, offset, SColor8.White)
		If attraction.TrailerMod
			font.DrawBox(genre, 60, offset, 205, 25, sALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.TrailerMod.Copy().MultiplyFloat(TAudienceAttraction.MODINFLUENCE_TRAILER).AddFloat(1), 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("4. + Sonstige Mods ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_MISC*100)+"%)", 25, offset, SColor8.White)
		If attraction.MiscMod
			DrawAudiencePercent(attraction.MiscMod, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("5. + CastMod ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_CAST*100)+"%)", 25, offset, SColor8.White)
		DrawAudiencePercent(New TAudience.InitValue(attraction.CastMod,  attraction.CastMod), 200, offset, True, True)
		offset :+ 20

		font.DrawSimple("6. * SenderimageMod", 25, offset, SColor8.White)
		If attraction.PublicImageMod
			DrawAudiencePercent(attraction.PublicImageMod.Copy().AddFloat(1.0), 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("7. + Zuschauerentwicklung (inaktiv)", 25, offset, SColor8.White)
	'	DrawAudiencePercent(new TAudience.InitValue(-1, attraction.QualityOverTimeEffectMod), 200, offset, true, true)
		offset :+ 20

		font.DrawSimple("9. + Glück / Zufall", 25, offset, SColor8.White)
		If attraction.LuckMod
			DrawAudiencePercent(attraction.LuckMod, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("9. + Audience Flow Bonus", 25, offset, SColor8.White)
		If attraction.AudienceFlowBonus
			DrawAudiencePercent(attraction.AudienceFlowBonus, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("10. * Genreattraktivität (zeitabh.)", 25, offset, SColor8.White)
		If attraction.GetGenreAttractivity()
			DrawAudiencePercent(attraction.GetGenreAttractivity(), 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("11. + Sequence", 25, offset, SColor8.White)
		If attraction.SequenceEffect
			DrawAudiencePercent(attraction.SequenceEffect, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("Finale Attraktivität (Effektiv)", 25, offset, SColor8.White)
		If attraction.FinalAttraction
			DrawAudiencePercent(attraction.FinalAttraction, 200, offset, False, True)
		EndIf
Rem
		font.Draw("Basis-Attraktivität", 25, offset+230, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BaseAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BaseAttraction, 200, offset+230, false, true);
		Endif
		endrem
		Rem
		endrem

		Rem
		font.Draw("10. Nachrichteneinfluss", 25, offset+330, TColor.clWhite)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.NewsShowBonus Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.NewsShowBonus, 200, offset+330, true, true);
		Endif
		endrem

		Rem
		font.Draw("Block-Attraktivität", 25, offset+290, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BlockAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BlockAttraction, 200, offset+290, false, true);
		Endif
		endrem



		Rem
		font.Draw("Ausstrahlungs-Attraktivität", 25, offset+270, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BroadcastAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BroadcastAttraction, 200, offset+270, false, true);
		Endif
		endrem

		Local currBroadcast2:TBroadcast = GetBroadcastManager().GetCurrentBroadcast()
		Local feedback:TBroadcastFeedback = currBroadcast2.GetFeedback(playerID)

		Local minute:Int = GetWorldTime().GetDayMinute()

		If ((minute Mod 5) = 0)
			If Not (Self.lastCheckedMinute = minute)
				Self.lastCheckedMinute = minute
				currentStatement = Null
				'DebugStop
			End If
		EndIf

		If Not currentStatement Then
			currentStatement:TBroadcastFeedbackStatement = feedback.GetNextAudienceStatement()
		EndIf

		SetColor 0,0,0
		DrawRect(520,415,250,40)
		font.DrawSimple("Interest: " + feedback.AudienceInterest.ToStringMinimal(), 530, 420, SColor8.Red)
		font.DrawSimple("Statements: count=" + feedback.FeedbackStatements.Count(), 530, 430, SColor8.Red)
		If currentStatement Then
			font.DrawSimple(currentStatement.ToString(), 530, 440, SColor8.Red)
		EndIf

		SetColor 255,255,255


Rem
		font.Draw("Genre <> Sendezeit", 25, offset+240, TColor.clWhite)
		Local genreTimeMod:string = MathHelper.NumberToString(attraction.GenreTimeMod  * 100,2) + "%"
		Local genreTimeQuality:string = MathHelper.NumberToString(attraction.GenreTimeQuality * 100,2) + "%"
		font.Draw(genreTimeMod, 160, offset+240, TColor.clWhite)
		font.drawBlock(genreTimeQuality, 200, offset+240, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)

		'Nur vorübergehend
		font.Draw("Trailer-Mod", 25, offset+250, TColor.clWhite)
		Local trailerMod:String = MathHelper.NumberToString(attraction.TrailerMod  * 100,2) + "%"
		Local trailerQuality:String = MathHelper.NumberToString(attraction.TrailerQuality * 100,2) + "%"
		font.Draw(trailerMod, 160, offset+250, TColor.clWhite)
		font.drawBlock(trailerQuality, 200, offset+250, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)



		font.Draw("Image", 25, offset+295, TColor.clWhite);
		font.Draw("100%", 160, offset+295, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+295);

		font.Draw("Effektive Attraktivität", 25, offset+325, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+325)
endrem
	End Method


	Function DrawAudience(audience:TAudience, x:Int, y:Int, gray:Int = False)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		Local color:SColor8 = SColor8.White
		If gray Then color = new SColor8(150, 150, 150)

		val = TFunctions.convertValue(audience.GetTotalSum(), 2)
		If gray Then
			font.DrawBox(val, x, y, 65, 25, sALIGN_RIGHT_TOP, new SColor8(150, 80, 80))
		Else
			font.DrawBox(val, x, y, 65, 25, sALIGN_RIGHT_TOP, SColor8.Red)
		End If

		For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
			val = TFunctions.convertValue(audience.GetTotalValue(TVTTargetGroup.GetAtIndex(i)), 2)
			font.DrawBox(val, x2 + 70*(i-1), y, 65, 25, sALIGN_RIGHT_TOP, color)
		Next
	End Function


	Function DrawAudiencePercent(audience:TAudience, x:Int, y:Int, gray:Int = False, hideAverage:Int = False)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		Local color:SColor8 = SColor8.White
		If gray Then color = new SColor8(150, 150, 150)

		If Not hideAverage Then
			val = MathHelper.NumberToString(audience.GetWeightedAverage(),2)
			If gray Then
				font.DrawBox(val, x, y, 65, 25, sALIGN_RIGHT_TOP, new SColor8(150, 80, 80))
			Else
				font.DrawBox(val, x, y, 65, 25, sALIGN_RIGHT_TOP, SColor8.Red)
			End If
		End If

		For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
			val = MathHelper.NumberToString(0.5 * audience.GetTotalValue(TVTTargetGroup.GetAtIndex(i)),2)
			font.DrawBox(val, x2 + 70*(i-1), y, 65, 25, sALIGN_RIGHT_TOP, color)
		Next
	End Function
End Type





Type TDebugPlayerControls
	Method Update:Int(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)
		If Not player Then Return False

		Local buttonX:Int = 0
		If UpdateButton(buttonX, y, 120, 20)
			player.GetFigure().FinishCurrentTarget()
		EndIf

		buttonX :+ 120+5
		If UpdateButton(x+buttonX,y, 140, 20)
			'forecfully! leave the room
			player.GetFigure().LeaveRoom(True)
		EndIf
	End Method


	Method Draw:Int(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)
		If Not player Then Return False

		Local buttonX:Int = x
		If Not player.GetFigure().GetTarget()
			DrawButton("ohne Ziel", buttonX, y, 140, 20)
		Else
			If Not player.GetFigure().IsControllable()
				DrawButton("erzw. Ziel entfernen", buttonX, y, 140, 20)
			Else
				DrawButton("Ziel entfernen", buttonX, y, 140, 20)
			EndIf
		EndIf

		buttonX :+ 140+5
		If TRoomBase(player.GetFigure().GetInRoom())
			DrawButton("in Raum: "+ TRoomBase(player.GetFigure().GetInRoom()).GetName(), buttonX, y, 120, 20)
		Else
			DrawButton("im Hochhaus", buttonX, y, 120, 20)
		EndIf
	End Method


	Method DrawButton(text:String, x:Int, y:Int, w:Int, h:Int)
		SetColor 150,150,150
		DrawRect(x,y,w,h)
		If THelper.MouseIn(x,y,w,h)
			SetColor 50,50,50
		Else
			SetColor 0,0,0
		EndIf
		DrawRect(x+1,y+1,w-2,h-2)
		SetColor 255,255,255
		GetBitmapFont("default", 11).DrawBox(text, x,y,w,h, sALIGN_CENTER_CENTER, SColor8.White)
	End Method


	Method UpdateButton:Int(x:Int, y:Int, w:Int, h:Int)
		If THelper.MouseIn(x,y,w,h)
			If MouseManager.IsClicked(1)
				'handle clicked
				MouseManager.SetClickHandled(1)
				Return True
			EndIf
		EndIf
		Return False
	End Method
End Type






Type TDebugProfiler
	Field active:Int = False
	Field callNames:object[]
	
	Method ObserveCall(callName:Object)
		callNames :+ [callName]
	End Method
	
	
	Method Update(x:Int, y:Int)
	End Method


	Method Draw(x:Int, y:Int)
		If not active then Return
		
		Local textX:Int = x
		Local textY:Int = y
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float; oldColA = GetAlpha()
		Local font:TBitmapfont = GetBitmapFont("default", 10)

		SetColor 0,0,0
		SetAlpha 0.75*oldColA
		DrawRect(x, y, 220, 100)
		
		SetColor(255,255,255)
		font.Draw("Profiler", textX, textY)
		textY :+ 12
		For Local callName:object = EachIn callNames
			Local c:TProfilerCall = TProfiler.GetCall(callName)
			if c
				font.Draw(c.name.ToString() + "  " + c.calls + " calls, " + StringHelper.printf("%5.2f", [string(float(c.timeTotal) / c.calls)])+"ms avg.", textX, textY)
				textY :+ 12
			endif
		Next

		SetColor(oldCol)
		SetAlpha(oldColA)
	End Method
End Type