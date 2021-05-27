
Global debugAudienceInfos:TDebugAudienceInfos = New TDebugAudienceInfos
Global debugProgrammePlanInfos :TDebugProgrammePlanInfos = New TDebugProgrammePlanInfos
Global debugProgrammeCollectionInfos :TDebugProgrammeCollectionInfos = New TDebugProgrammeCollectionInfos
Global debugPlayerControls :TDebugPlayerControls = New TDebugPlayerControls
Global debugFinancialInfos :TDebugFinancialInfos = New TDebugFinancialInfos



Type TDebugScreen
	Field enabled:Int
	Field mode:Int = 0
	Field sideButtons:TDebugControlsButton[]
	Field playerCommandTaskButtons:TDebugControlsButton[]
	Field playerCommandAIButtons:TDebugControlsButton[]
	Field buttonsPlayerFinancials:TDebugControlsButton[]
	Field buttonsAdAgency:TDebugControlsButton[]
	Field buttonsMovieVendor:TDebugControlsButton[]
	Field buttonsNewsAgency:TDebugControlsButton[]
	Field buttonsRoomAgency:TDebugControlsButton[]
	Field buttonsScriptAgency:TDebugControlsButton[]
	Field buttonsPolitics:TDebugControlsButton[]
	Field buttonsMisc:TDebugControlsButton[]
	Field buttonsModifiers:TDebugControlsButton[]
	Field sideButtonPanelWidth:Int = 130
	Field scriptAgencyOfferHightlight:TScript
	Field adAgencyOfferHightlight:TAdContract
	Field movieVendorOfferHightlight:TProgrammeLicence
	Global titleFont:TBitmapFont
	Global textFont:TBitmapFont
	Global textFontBold:TBitmapFont

	Method New()
		Local button:TDebugControlsButton


		Local texts:String[] = ["Overview", "Player Commands", "Player Financials", "Player Broadcasts", "-", "Ad Agency", "Movie Vendor", "News Agency", "Script Agency", "Room Agency", "-", "Politics Sim", "Modifiers", "Misc"]
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

		InitMode_Overview()
		InitMode_PlayerCommands()
		InitMode_PlayerFinancials()
		InitMode_PlayerBroadcasts()
		InitMode_AdAgency()
		InitMode_MovieVendor()
		InitMode_NewsAgency()
		InitMode_ScriptAgency()
		InitMode_RoomAgency()
		InitMode_Politics()
		InitMode_Modifiers()
		InitMode_Misc()
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		DebugScreen.mode = sender.dataInt
	End Function


	Method GetShownPlayerID:Int()
		Local playerID:Int = GetPlayerBaseCollection().GetObservedPlayerID()
		If GetInGameInterface().ShowChannel > 0
			playerID = GetInGameInterface().ShowChannel
		EndIf
		If playerID <= 0 Then playerID = GetPlayerBase().playerID
		Return playerID
	End Method


	Method Update()
		For Local b:TDebugControlsButton = EachIn sideButtons
			b.Update()

			If mode = b.dataInt
				b.selected = True
			Else
				b.selected = False
			EndIf
		Next

		Select mode
			Case 0	UpdateMode_Overview()
			Case 1	UpdateMode_PlayerCommands()
			Case 2	UpdateMode_PlayerFinancials()
			Case 3	UpdateMode_PlayerBroadcasts()
			Case 4	UpdateMode_AdAgency()
			Case 5	UpdateMode_MovieVendor()
			Case 6	UpdateMode_NewsAgency()
			Case 7	UpdateMode_ScriptAgency()
			Case 8	UpdateMode_RoomAgency()
			Case 9	UpdateMode_Politics()
			Case 10	UpdateMode_Modifiers()
			Case 11	UpdateMode_Misc()
		End Select
	End Method


	Method Render()
		if not titleFont
			titleFont = GetBitmapFont("default", 12, BOLDFONT)
			textFontBold = GetBitmapFont("default", 10, BOLDFONT)
			textFont = GetBitmapFont("default", 10)
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
		
		Select mode
			Case 0	RenderMode_Overview()
			Case 1	RenderMode_PlayerCommands()
			Case 2	RenderMode_PlayerFinancials()
			Case 3	RenderMode_PlayerBroadcasts()
			Case 4	RenderMode_AdAgency()
			Case 5	RenderMode_MovieVendor()
			Case 6	RenderMode_NewsAgency()
			Case 7	RenderMode_ScriptAgency()
			Case 8	RenderMode_RoomAgency()
			Case 9	RenderMode_Politics()
			Case 10	RenderMode_Modifiers()
			Case 11	RenderMode_Misc()
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
				DrawProfilerCallHistory(TProfiler.GetCall(TApp._profilerKey_AI_MINUTE[i]), x + 140 + 150 + 5, 10 + i*75 + 33 + 5, sideInfoW - 2*4, 28, "AI " + (i+1))
			endif

		next

		GetWorld().RenderDebug(x + 5 + 500, 20, 140, 180)
	End Method



	'=== PLAYER FINANCIALS ===
	Method InitMode_PlayerFinancials()
		Local texts:String[] = ["Set Player 1 Bankrupt", "Set Player 2 Bankrupt", "Set Player 3 Bankrupt", "Set Player 4 Bankrupt"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_PlayerFinancials

			buttonsPlayerFinancials :+ [button]
		Next
	End Method


	Function OnButtonClickHandler_PlayerFinancials(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				GetGame().SetPlayerBankrupt(1)
			case 1
				GetGame().SetPlayerBankrupt(2)
			case 2
				GetGame().SetPlayerBankrupt(3)
			case 3
				GetGame().SetPlayerBankrupt(4)
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_PlayerFinancials()
		Local playerID:Int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn buttonsPlayerFinancials
			b.Update()
		Next
	End Method


	Method RenderMode_PlayerFinancials()
		Local playerID:Int = GetShownPlayerID()

		RenderActionButtons(buttonsPlayerFinancials)

		debugFinancialInfos.Draw(-1, sideButtonPanelWidth + 5, 20)

		RenderPlayerBudgets(playerID, sideButtonPanelWidth + 5, 150)
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


		IDs   = [0,           1]
		texts = ["Enable AI", "Reload AI"]
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
	End Function



	Function OnPlayerCommandAIButtonClickHandler(sender:TDebugControlsButton)
'		print "clicked " + sender.dataInt

		Local playerID:Int = DebugScreen.GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)

		Local taskName:String =""
		Select sender.dataInt
			Case 0
				if player.IsLocalHuman() or player.IsLocalAI()
					Dev_SetPlayerAI(playerID, not player.IsLocalAI())
					if player.IsLocalAI()
						DebugScreen.playerCommandAIButtons[0].text = "Disable AI"
					else
						DebugScreen.playerCommandAIButtons[0].text = "Enable AI"
					endif
				endif
			Case 1 
				If GetPlayer(playerID).isLocalAI() Then GetPlayer(playerID).PlayerAI.reloadScript()
		End Select
	End Function


	Method UpdateMode_PlayerCommands()
'		local playerID:int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn playerCommandTaskButtons
			b.Update(sideButtonPanelWidth + 5, 30)
		Next
		For Local b:TDebugControlsButton = EachIn playerCommandAIButtons
			b.Update(sideButtonPanelWidth + 5 + 1*(120 + 10), 30)
		Next
	End Method


	Method RenderMode_PlayerCommands()
		'local playerID:int = GetShownPlayerID()
		Local playerID:Int = DebugScreen.GetShownPlayerID()
		Local player:TPlayer = GetPlayer(playerID)


		Local oldCol:SColor8; GetColor(oldCol)
		SetColor 0,0,0
		DrawOutlineRect(sideButtonPanelWidth, 10, 130, 170, true, true, true, false, 0,0,0, 0.25)
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



	'=== PLAYER BROADCASTS ===

	Method InitMode_PlayerBroadcasts()
	End Method


	Method UpdateMode_PlayerBroadcasts()
		Local playerID:Int = GetShownPlayerID()

		debugProgrammePlanInfos.Update(playerID, sideButtonPanelWidth + 5, 13)
		debugProgrammeCollectionInfos.Update(playerID, sideButtonPanelWidth + 5 + 350, 13)
	End Method


	Method RenderMode_PlayerBroadcasts()
		Local playerID:Int = GetShownPlayerID()

		debugProgrammePlanInfos.Draw(playerID, sideButtonPanelWidth + 5, 13)
		debugProgrammeCollectionInfos.Draw(playerID, sideButtonPanelWidth + 5 + 350, 13)
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

	'=== AD AGENCY ===

	Method InitMode_AdAgency()
		Local texts:String[] = ["Refill Offers", "Replace Offers", "Change Mode"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_AdAgency
			buttonsAdAgency :+ [button]
		Next

		UpdateAdAgencyModeButton()
	End Method


	Function OnButtonClickHandler_AdAgency(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				RoomHandler_AdAgency.GetInstance().ReFillBlocks()
			case 1
				RoomHandler_AdAgency.GetInstance().ReFillBlocks(True, 1.0)
			case 2
				if RoomHandler_AdAgency.GetInstance()._setRefillMode = 2
					RoomHandler_AdAgency.GetInstance().SetRefillMode(1)
					DebugScreen.UpdateAdAgencyModeButton()
				else
					RoomHandler_AdAgency.GetInstance().SetRefillMode(2)
					DebugScreen.UpdateAdAgencyModeButton()
				endif
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateAdAgencyModeButton()
		Select RoomHandler_AdAgency.GetInstance()._setRefillMode
			case 1	buttonsAdAgency[2].text = "Change Mode: " + RoomHandler_AdAgency.GetInstance()._setRefillMode + "->2"
			case 2	buttonsAdAgency[2].text = "Change Mode: " + RoomHandler_AdAgency.GetInstance()._setRefillMode + "->1"
			default	buttonsAdAgency[2].text = "Change Mode: " + RoomHandler_AdAgency.GetInstance()._setRefillMode + "->2"
		End Select
	End Method


	Method UpdateMode_AdAgency()
		Local playerID:Int = GetShownPlayerID()

		'initial refill?
		'if RoomHandler_AdAgency.listNormal.length = 0 then ReFillBlocks()

		UpdateAdAgencyOffers(playerID, sideButtonPanelWidth + 5, 13, 250, 230)

		For Local b:TDebugControlsButton = EachIn buttonsAdAgency
			b.Update()
		Next

	End Method


	Method RenderMode_AdAgency()
		Local playerID:Int = GetShownPlayerID()

		RenderAdAgencyOffers(playerID, sideButtonPanelWidth + 5, 13, 250, 230)
		RenderAdAgencyInformation(playerID, sideButtonPanelWidth + 5 + 250 + 5, 13)

		RenderActionButtons(buttonsAdAgency)

		if adAgencyOfferHightlight
			adAgencyOfferHightlight.ShowSheet(sideButtonPanelWidth + 5 + 250, 13, 0, TVTBroadcastMaterialType.ADVERTISEMENT, playerID)
		endif
	End Method




	'=== MOVIE VENDOR ===

	Method InitMode_MovieVendor()
		Local texts:String[] = ["Refill Offers", "Replace Offers", "End Auctions"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_MovieVendor

			buttonsMovieVendor :+ [button]
		Next

	End Method


	Function OnButtonClickHandler_MovieVendor(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				RoomHandler_MovieAgency.GetInstance().ReFillBlocks()
			case 1
				RoomHandler_MovieAgency.GetInstance().ReFillBlocks(True, 1.0)
			case 2
				TAuctionProgrammeBlocks.EndAllAuctions()
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_MovieVendor()
		Local playerID:Int = GetShownPlayerID()

		'initial refill?
		'if RoomHandler_AdAgency.listNormal.length = 0 then ReFillBlocks()

		UpdateMovieVendorOffers(playerID, sideButtonPanelWidth + 5, 13, 410, 230)

		For Local b:TDebugControlsButton = EachIn buttonsMovieVendor
			b.Update()
		Next

	End Method


	Method RenderMode_MovieVendor()
		Local playerID:Int = GetShownPlayerID()

		RenderMovieVendorOffers(playerID, sideButtonPanelWidth + 5, 13, 430, 330)
'		RenderMovieVendorInformation(playerID, sideButtonPanelWidth + 5 + 250 + 250 + 5, 13)

		RenderMovieVendorNoLongerAvailable(playerID, sideButtonPanelWidth + 5 + 250 + 5 + 250, 13 + 150)

		RenderActionButtons(buttonsMovieVendor)

		if movieVendorOfferHightlight
			movieVendorOfferHightlight.ShowSheet(sideButtonPanelWidth + 5 + 250, 13, 0, TVTBroadcastMaterialType.PROGRAMME, playerID)
		endif
	End Method




	'=== NEWS AGENCY ===

	Method InitMode_NewsAgency()
		Local texts:String[] = ["Announce News"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_NewsAgency

			buttonsNewsAgency :+ [button]
		Next
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

		RenderNewsAgencyQueue(playerID, sideButtonPanelWidth + 5, 13, 410, 340)
		RenderNewsAgencyInformation(playerID, sideButtonPanelWidth + 5 + 250 + 250 + 5, 13)

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
		Local texts:String[] = ["Re-Rent", "Kick Renter"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_RoomAgency

			buttonsRoomAgency :+ [button]
		Next
	End Method


	Function OnButtonClickHandler_RoomAgency(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
'
			case 1
'					if GetRoomAgency().CancelRoomRental(useRoom, GetPlayerBase().playerID)
'				GetRoomAgency().BeginRoomRental(useRoom, GetPlayerBase().playerID)
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_RoomAgency()
		Local playerID:Int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn buttonsRoomAgency
			b.Update()
		Next
	End Method


	Method RenderMode_RoomAgency()
		Local playerID:Int = GetShownPlayerID()

		RenderActionButtons(buttonsRoomAgency)
	End Method


	'=== Politics screen ===

	Method InitMode_Politics()
		Local texts:String[] = ["Send Terrorist", "Reset Terror Levels"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i])
			button._onClickHandler = OnButtonClickHandler_Politics

			buttonsPolitics :+ [button]
		Next
	End Method


	Function OnButtonClickHandler_Politics(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				'send terrorist to a random room
				If Not GetGame().networkGame
					Global whichTerrorist:Int = 1
					whichTerrorist = 1 - whichTerrorist

					Local targetRoom:TRoom
					Repeat
						targetRoom = GetRoomCollection().GetRandom()
					Until targetRoom.GetName() <> "building"
					'Print TFigureTerrorist(GetGame().terrorists[whichTerrorist]).name +" - deliver to : "+targetRoom.GetName() + " [id="+targetRoom.id+", owner="+targetRoom.owner+"]"
					TFigureTerrorist(GetGame().terrorists[whichTerrorist]).SetDeliverToRoom( targetRoom )
				EndIf
				
'
			case 1
'					if GetRoomAgency().CancelRoomRental(useRoom, GetPlayerBase().playerID)
'				GetRoomAgency().BeginRoomRental(useRoom, GetPlayerBase().playerID)
		End Select

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
		Local texts:String[] = ["Print Ad Stats", "Print Players Today Finance Overview", "Print All Players Finance Overview", "Print Players Today Broadcast Stats", "Print Total Broadcast Stats", "Print Performance Stats"]
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
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateMode_Misc()
		Local playerID:Int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn buttonsMisc
			b.Update()
		Next
	End Method


	Method RenderMode_Misc()
		Local playerID:Int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn buttonsMisc
			b.Render()
		Next
	End Method




	'=== BLOCKS ===
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
'		DrawOutlineRect(x, y, w, h)
	End Method



	Method UpdateNewsAgencyQueue(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		'reset
		'newsAgencyNewsHighlight = null
	End Method


	Method RenderNewsAgencyQueue(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		textY :+ 12 + 10 + 5


		local upcomingCount:int[TVTNewsGenre.count+1]
		local upcomingCountTotal:int = 0

		local upcomingSorted:TList = GetNewsEventCollection().GetUpcomingNewsList().Copy()
		upcomingSorted.sort(True, TNewsEventCollection.SortByHappenedTime)

		For local n:TNewsEvent = EachIn upcomingSorted
			upcomingCountTotal :+ 1
			upcomingCount[n.GetGenre()] :+ 1
		Next


		textFont.DrawSimple(GetLocale("Genre"), textX, textY)
		textFont.DrawSimple("Next", textX + 100, textY)
		textFont.DrawSimple("Upcoming", textX + 200, textY)
		textY :+ 12+3
		For local i:int = 0 until TVTNewsGenre.count
			textFont.DrawSimple(GetLocale("NEWS_"+TVTNewsGenre.GetAsString(i)), textX, textY)
			textFont.DrawSimple(GetWorldTime().GetFormattedTime(GetNewsAgency().NextEventTimes[i]), textX + 100, textY)
			textFont.DrawSimple(upcomingCount[i]+"x", textX + 200, textY)
			textY :+ 12
		Next
		textY :+ 12

		textFont.DrawSimple("Queue", textX, textY)
		textY :+ 12+3
		if upcomingCountTotal = 0
			textFont.DrawSimple("--", textX, textY)
		else
			local nCount:Int
			For local n:TNewsEvent = EachIn upcomingSorted
				textFont.DrawSimple(GetWorldTime().GetFormattedGameDate(n.happenedTime), textX, textY)
				textFont.DrawSimple(n.GetTitle() + "  ("+GetLocale("NEWS_"+TVTNewsGenre.GetAsString(n.GetGenre()))+")", textX + 100, textY)
				textY :+ 12
				nCount :+ 1
				if nCount > 15 then exit
			Next
		endif

	End Method


	'stuff filtered out
	Method RenderMovieVendorNoLongerAvailable(playerID:Int, x:int, y:int, w:int = 200, h:int = 300)
		DrawOutlineRect(x, y, w, h)

		Local textX:Int = x + 5
		Local textY:Int = y + 5

		titleFont.Draw("Crap-filtered", textX, textY)
		textY :+ 12

		local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()

		For local pl:TProgrammeLicence = EachIn GetProgrammeLicenceCollection()._GetParentLicences().values()
			if not pl.IsReleased() then continue
'			if pl.GetMaxTopicality() > 0.15 then continue
'			if not (movieVendor.filterMoviesCheap.DoesFilter(pl) or movieVendor.filterMoviesGood.DoesFilter(pl) or movieVendor.filterSeries.DoesFilter(pl)) then continue
			if not movieVendor.filterCrap.DoesFilter(pl) then continue

			textFont.DrawBox(pl.GetTitle(), textX + 15, textY - 1, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
			textFont.DrawSimple(pl.GetPriceForPlayer(playerID), textX + 15 + 120, textY - 1)
			textFont.DrawBox(MathHelper.NumberToString(pl.GetMaxTopicality()*100,2)+"%", textX + 15 + 130, textY - 1, 45, 15, sALIGN_RIGHT_TOP, SColor8.White)
			textY :+ 10
		Next
'		filterMoviesGood
	End Method


	Method RenderMovieVendorInformation(playerID:int, x:int, y:int, w:int = 180, h:int = 150)
'		DrawOutlineRect(x, y, w, h)
	End Method



	Method UpdateMovieVendorOffers(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		'reset
		movieVendorOfferHightlight = null

		Local textX:Int = x + 5
		Local textY:Int = y + 5
		local barWidth:int = 200

		local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()
		textY :+ 12 + 10 + 5

		local textYStart:int = textY

		local licenceLists:TProgrammeLicence[][] = [movieVendor.listMoviesGood, movieVendor.listMoviesCheap, movieVendor.listSeries]
		local entryPos:int = 0
		For local listNumber:int = 0 until licenceLists.length
			if listNumber = 2
				textY = textYStart
				textX :+ barWidth + 10
			endif


			local licences:TProgrammeLicence[] = licenceLists[listNumber]
			textY :+ 10
			For local i:int = 0 until licences.length
				if THelper.MouseIn(textX, textY, barWidth, 10)
					movieVendorOfferHightlight = licences[i]
					exit
				endif

				textY :+ 10
				entryPos :+ 1
			Next
			if movieVendorOfferHightlight then exit

			textY :+ 5
		Next
	End Method


	Method RenderMovieVendorOffers(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		local barWidth:int = 200
		local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()

		titleFont.draw("MovieAgency", textX, textY)
		textY :+ 12
		textFont.Draw("Refilled on figure visit.", textX, textY)
		textY :+ 10
		textY :+ 5

		local textYStart:int = textY

		local licenceListsTitle:String[] = ["Good", "Cheap", "Series"]
		local licenceLists:TProgrammeLicence[][] = [movieVendor.listMoviesGood, movieVendor.listMoviesCheap, movieVendor.listSeries]
		local entryPos:int = 0
		local oldAlpha:Float = GetAlpha()
		For local listNumber:int = 0 until licenceLists.length
			if listNumber = 2
				textY = textYStart
				textX :+ barWidth + 10
			endif


			local licences:TProgrammeLicence[] = licenceLists[listNumber]

			textFontBold.Draw(licenceListsTitle[listNumber] + ":", textX, textY)
			textY :+ 10
			For local i:int = 0 until licences.length
				If entryPos Mod 2 = 0
					SetColor 0,0,0
				Else
					SetColor 60,60,60
				EndIf
				SetAlpha 0.75 * oldAlpha
				DrawRect(textX, textY, barWidth, 10)

				SetColor 255,255,255
				SetAlpha oldAlpha

				if licences[i] and licences[i] = movieVendorOfferHightlight
					SetAlpha 0.25 * oldAlpha
					SetBlend LIGHTBLEND
					DrawRect(textX, textY, barWidth, 10)
					SetAlpha oldAlpha
					SetBlend ALPHABLEND
				endif

				textFont.Draw(RSet(i, 2).Replace(" ", "0"), textX, textY)
				if licences[i]
					textFont.DrawBox(": " + licences[i].GetTitle(), textX + 15, textY - 1, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
					textFont.DrawSimple(MathHelper.DottedValue(licences[i].GetPriceForPlayer(playerID)), textX + 15 + 120, textY - 1)
					textFont.DrawBox(licences[i].data.GetYear(), textX + 15 + 120, textY - 1, barWidth - (15 + 120 + 5), 15, sALIGN_RIGHT_TOP, SColor8.White)
				else
					textFont.DrawSimple(": -", textX + 15, textY - 1)
				endif
				textY :+ 10

				entryPos :+ 1
			Next
			textY :+ 5
		Next
	End Method




	Method RenderAdAgencyInformation(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
'		DrawOutlineRect(x, y, w, h)
rem
		Local captionFont:TBitMapFont
			SetColor 0,0,0
			SetAlpha 0.6
			DrawRect(15,215, 380, 200)
			SetAlpha 1.0
			SetColor 255,255,255
			GetBitmapFont("default", 12).Draw("RefillMode:" + GameRules.adagencyRefillMode, 20, 220)
			GetBitmapFont("default", 12).Draw("Durchschnittsquoten:", 20, 240)
			Local y:Int = 260
			Local filterNum:Int = 0
			For Local filter:TAdContractBaseFilter = EachIn levelFilters
				filterNum :+ 1
				Local title:String = "#"+filterNum
				Select filterNum
					Case 1	title = "Schlechtester (Tag):~t"
					Case 2	title = "Schlechtester (Prime):"
					Case 3	title = "Durchschnitt (Tag):~t"
					Case 4	title = "Durchschnitt (Prime):"
					Case 5	title = "Bester Spieler (Tag):~t"
					Case 6	title = "Bester Spieler (Prime):"
				End Select
				GetBitmapFont("default", 12).Draw(title+"~tMinAudience = " + MathHelper.NumberToString(100 * filter.minAudienceMin,2)+"% - "+ MathHelper.NumberToString(100 * filter.minAudienceMax,2)+"%", 20, y)
				If filterNum Mod 2 = 0 Then y :+ 4
				y:+ 13
			Next
endrem
	End Method


	Method UpdateAdAgencyOffers(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		'reset
		adAgencyOfferHightlight = null

		Local textX:Int = x + 5
		Local textY:Int = y + 5
		local adAgency:RoomHandler_AdAgency = RoomHandler_AdAgency.GetInstance()
		textY :+ 12 + 10 + 5

		local adLists:TAdContract[][] = [adAgency.listNormal, adAgency.listCheap]
		local entryPos:int = 0
		For local listNumber:int = 0 until adLists.length
			local ads:TAdContract[] = adLists[listNumber]
			textY :+ 10
			For local i:int = 0 until ads.length
				if THelper.MouseIn(textX, textY, 240, 10)
					adAgencyOfferHightlight = ads[i]
					exit
				endif

				textY :+ 10
				entryPos :+ 1
			Next
			if adAgencyOfferHightlight then exit
		Next
	End Method


	Method RenderAdAgencyOffers(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		local adAgency:RoomHandler_AdAgency = RoomHandler_AdAgency.GetInstance()

		titleFont.draw("AdAgency", textX, textY - 1)
		textY :+ 12
		textFont.Draw("Refilled on figure visit.", textX, textY - 1)
		textY :+ 10
		textY :+ 5

		local adlistTitle:String[] = ["Normal", "Cheap"]
		local adLists:TAdContract[][] = [adAgency.listNormal, adAgency.listCheap]
		local entryPos:int = 0
		local oldAlpha:Float = GetAlpha()
		For local listNumber:int = 0 until adLists.length
			local ads:TAdContract[] = adLists[listNumber]

			textFontBold.Draw(adListTitle[listNumber] + ":", textX, textY - 1)
			textY :+ 10
			For local i:int = 0 until ads.length
				If entryPos Mod 2 = 0
					SetColor 0,0,0
				Else
					SetColor 60,60,60
				EndIf
				SetAlpha 0.75 * oldAlpha
				DrawRect(textX, textY, 240, 10)

				SetColor 255,255,255
				SetAlpha oldAlpha

				if ads[i] and ads[i] = adAgencyOfferHightlight
					SetAlpha 0.25 * oldAlpha
					SetBlend LIGHTBLEND
					DrawRect(textX, textY, 240, 10)
					SetAlpha oldAlpha
					SetBlend ALPHABLEND
				endif

				textFont.DrawSimple(RSet(i, 2).Replace(" ", "0"), textX, textY - 1)
				if ads[i]
					textFont.DrawBox(": " + ads[i].GetTitle(), textX + 15, textY - 1, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
					textFont.DrawSimple(MathHelper.DottedValue(ads[i].GetMinAudience(playerID)), textX + 15 + 120, textY - 1)
					if ads[i].GetLimitedToTargetGroup() > 0
						textFont.DrawBox(ads[i].GetLimitedToTargetGroupString(), textX + 15 + 120, textY - 1, 100, 15, sALIGN_RIGHT_TOP, SColor8.White)
					else
						SetAlpha 0.5
						textFont.DrawBox("no limit", textX + 15 + 120, textY - 1, 100, 15, sALIGN_RIGHT_TOP, SColor8.White)
						SetAlpha oldAlpha
					endif
				else
					textFont.DrawSimple(": -", textX + 15, textY - 1)
				endif
				textY :+ 10

				entryPos :+ 1
			Next
			textY :+ 5
		Next
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
			DrawRect(x, y, 185, Max(100, player.playerAI.eventQueue.length * 10 + 6))
			SetColor 255,255,255

			Local textX:Int = x + 3
			Local textY:Int = y + 3 - 1

			For local aievent:TAIEvent = EachIn player.playerAI.eventQueue
				textFont.Draw("event:   " + aievent.ID, textX, textY)
				textY :+ 10
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


	Method RenderPlayerBudgets(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)

		If player.playerAI
			Local colWidth:Int = 45
			Local labelWidth:Int = 80
			Local padding:Int = 15
			Local boxWidth:Int = labelWidth + padding + colWidth*3 + 2 '2 is border*2

			SetColor 40,40,40
			DrawRect(x, y, boxWidth, 140)
			SetColor 50,50,40
			DrawRect(x+1, y+1, boxWidth-2, 140)
			SetColor 255,255,255

			Local textX:Int = x + 3
			Local textY:Int = y + 3 - 1

			textFont.Draw("Investment Savings: " + MathHelper.DottedValue(player.aiData.GetInt("budget_investmentsavings")), textX, textY)
			textY :+ 10
			textFont.Draw("Savings Part: " + MathHelper.DottedValue(player.aiData.GetFloat("budget_savingpart")*100)+"%", textX, textY)
			textY :+ 10
			textFont.Draw("Extra fixed costs savings percentage: " + MathHelper.DottedValue(player.aiData.GetFloat("budget_extrafixedcostssavingspercentage")*100)+"%", textX, textY)
			textY :+ 10

			textFontBold.Draw("Budget List: ", textX, textY)
			textFontBold.Draw("Current", textX + labelWidth + padding + colWidth*0, textY)
			textFontBold.Draw("Max", textX + labelWidth + padding + colWidth*1, textY)
			textFontBold.Draw("Day", textX + labelWidth + padding + colWidth*2, textY)
			textY :+ 10 + 2

			For Local taskNumber:Int = 1 To player.aiData.GetInt("budget_task_count", 1)
				textFont.Draw(player.aiData.GetString("budget_task_name"+taskNumber).Replace("Task", ""), textX, textY)
				textFont.Draw(MathHelper.DottedValue(player.aiData.GetInt("budget_task_currentbudget"+taskNumber)), textX + labelWidth + padding + colWidth*0, textY)
				textFont.Draw(MathHelper.DottedValue(player.aiData.GetInt("budget_task_budgetmaximum"+taskNumber)), textX + labelWidth + padding + colWidth*1, textY)
				textFont.Draw(MathHelper.DottedValue(player.aiData.GetInt("budget_task_budgetwholeday"+taskNumber)), textX + labelWidth + padding + colWidth*2, textY)
				textY :+ 10
			Next
		EndIf
	End Method




	Function DrawOutlineRect(x:int, y:int, w:int, h:int, borderTop:int = True, borderRight:int = True, borderBottom:int = True, borderLeft:Int = True, r:int = 0, g:int = 0, b:int = 0, alpha:Float = 0.5)
		local oldCol:TColor = new TColor.get()
		SetColor r,g,b
		SetAlpha alpha * oldCol.a

		DrawRect(x, y, w, h)
		SetAlpha oldCol.a
		if borderTop then DrawRect(x, y, w, 2)
		if borderRight then DrawRect(x + w - 2, y, 2, h)
		if borderBottom then DrawRect(x, y + h - 2, w, 2)
		if borderLeft then DrawRect(x, y, 2, h)

		oldCol.SetRGBA()
	End Function


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



Type TDebugAudienceInfos
	Field currentStatement:TBroadcastFeedbackStatement
	Field lastCheckedMinute:Int


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




Type TDebugProgrammeCollectionInfos
	Field initialized:Int = False
	Global addedProgrammeLicences:TMap = CreateMap()
	Global removedProgrammeLicences:TMap = CreateMap()
	Global availableProgrammeLicences:TMap = CreateMap()
	Global addedAdContracts:TMap = CreateMap()
	Global removedAdContracts:TMap = CreateMap()
	Global availableAdContracts:TMap = CreateMap()
	Global oldestEntryTime:Long
	Global _eventListeners:TEventListenerBase[]


	Method New()
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveAdContract, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddAdContract, onChangeProgrammeCollection) ]
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddUnsignedAdContractToSuitcase, onChangeProgrammeCollection) ]
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveUnsignedAdContractFromSuitcase, onChangeProgrammeCollection) ]
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddProgrammeLicenceToSuitcase, onChangeProgrammeCollection) ]
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProgrammeLicenceFromSuitcase, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProgrammeLicence, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddProgrammeLicence, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnStart, onGameStart) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_PreparePlayer, onPreparePlayer) ]
	End Method


	Function onGameStart:Int(triggerEvent:TEventBase)
		debugProgrammeCollectionInfos.Initialize()
	End Function

	'called if a player restarts
	Function onPreparePlayer:Int(triggerEvent:TEventBase)
		debugProgrammeCollectionInfos.Initialize()
	End Function


	Function onChangeProgrammeCollection:Int(triggerEvent:TEventBase)
		Local prog:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().Get("programmelicence"))
		Local contract:TAdContract = TAdContract(triggerEvent.GetData().Get("adcontract"))
		Local broadcastSource:TBroadcastMaterialSource = prog
		If Not broadcastSource Then broadcastSource = contract

		If Not broadcastSource Then Print "TDebugProgrammeCollectionInfos.onChangeProgrammeCollection: invalid broadcastSourceMaterial."


		Local map:TMap = Null
		Select triggerEvent.GetEventKey()
			Case GameEventKeys.ProgrammeCollection_RemoveAdContract
				map = removedAdContracts
				'remove on outdated
				'availableAdContracts.Remove(broadcastSource.GetGUID())
			Case GameEventKeys.ProgrammeCollection_AddAdContract
				map = addedAdContracts
				availableAdContracts.Insert(broadcastSource.GetGUID(), broadcastSource)
	'		Case GameEventKeys.ProgrammeCollection_AddUnsignedAdContractToSuitcase
	'			map = addedAdContracts
	'		Case GameEventKeys.ProgrammeCollection_RemoveUnsignedAdContractFromSuitcase
	'			map = addedAdContracts
	'		Case GameEventKeys.ProgrammeCollection_AddProgrammeLicenceToSuitcase
	'			map = addedAdContracts
	'		Case GameEventKeys.ProgrammeCollection_RemoveProgrammeLicenceFromSuitcase
	'			map = addedAdContracts
			Case GameEventKeys.ProgrammeCollection_RemoveProgrammeLicence
				map = removedProgrammeLicences
				'remove on outdated
				'availableProgrammeLicences.Remove(broadcastSource.GetGUID())
			Case GameEventKeys.ProgrammeCollection_AddProgrammeLicence
				map = addedProgrammeLicences
				availableProgrammeLicences.Insert(broadcastSource.GetGUID(), broadcastSource)
		End Select
		If Not map Then Return False

		map.Insert(broadcastSource.GetGUID(), String(Time.GetTimeGone()) )

		RemoveOutdated()
	End Function


	Function RemoveOutdated()
		Local maps:TMap[] = [removedProgrammeLicences, removedAdContracts, addedProgrammeLicences, addedAdContracts]

		oldestEntryTime = -1

		'remove outdated ones (older than 30 seconds))
		For Local map:TMap = EachIn maps
			Local remove:String[]
			For Local guid:String = EachIn map.Keys()
				Local changeTime:Long = Long( String(map.ValueForKey(guid)) )

				If changeTime + 3000 < Time.GetTimeGone()
					remove :+ [guid]

					If map = removedProgrammeLicences Then availableProgrammeLicences.Remove(guid)
					If map = removedAdContracts Then availableAdContracts.Remove(guid)
					Continue
				EndIf

				If oldestEntryTime = -1 Then oldestEntryTime = changeTime
				oldestEntryTime = Min(oldestEntryTime, changeTime)
			Next

			For Local guid:String = EachIn remove
				map.Remove(guid)
			Next
		Next
	End Function



	Function GetAddedTime:Long(guid:String, materialType:Int=0)
		If materialType = TVTBroadcastMaterialType.PROGRAMME
			Return Int( String(addedProgrammeLicences.ValueForKey(guid)) )
		Else
			Return Int( String(addedAdContracts.ValueForKey(guid)) )
		EndIf
	End Function


	Function GetRemovedTime:Long(guid:String, materialType:Int=0)
		If materialType = TVTBroadcastMaterialType.PROGRAMME
			Return Int( String(removedProgrammeLicences.ValueForKey(guid)) )
		Else
			Return Int( String(removedAdContracts.ValueForKey(guid)) )
		EndIf
	End Function


	Function GetChangedTime:Long(guid:String, materialType:Int=0)
		Local addedTime:Long = GetAddedTime(guid, materialType)
		Local removedTime:Long = GetRemovedTime(guid, materialType)
		If addedTime <> 0 Then Return addedTime
		Return removedTime
	End Function


	Method Initialize:Int()
		availableProgrammeLicences.Clear()
		availableAdContracts.Clear()
		'on savegame loads, the maps would be empty without
		For Local i:Int = 1 To 4
			Local coll:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(i)
			For Local l:TProgrammeLicence = EachIn coll.GetProgrammeLicences()
				availableProgrammeLicences.insert(l.GetGUID(), l)
			Next
			For Local a:TAdContract = EachIn coll.GetAdContracts()
				availableAdContracts.insert(a.GetGUID(), a)
			Next
		Next

		initialized = True
	End Method


	Method Update(playerID:Int, x:Int, y:Int)
	End Method


	Method Draw(playerID:Int, x:Int, y:Int)
		If Not initialized Then Initialize()

		If playerID <= 0 Then playerID = GetPlayerBase().playerID
		Local lineHeight:Int = 12
		Local lineTextDY:Int = -3
		Local lineTextHeight:Int = 15
		Local lineWidth:Int = 160
		Local adLineWidth:Int = 145
		Local adLeftX:Int = 165
		Local font:TBitmapFont = GetBitmapFont("default", 10)

		'clean up if needed
		If oldestEntryTime >= 0 And oldestEntryTime + 3000 < Time.GetTimeGone() Then RemoveOutdated()

		Local collection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		Local secondLineCol:SColor8 = new SColor8(220, 220,220)

		Local entryPos:Int = 0
		Local oldAlpha:Float = GetAlpha()
		For Local l:TProgrammeLicence = EachIn availableProgrammeLicences.Values() 'collection.GetProgrammeLicences()
			If l.owner <> playerID Then Continue
			'skip starting programme
			If Not l.isControllable() Then Continue

			Local oldAlpha:Float = GetAlpha()
			If entryPos Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 60,60,60
			EndIf
			SetAlpha 0.75 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight, lineWidth, lineHeight-1)

			Local changedTime:Int = GetChangedTime(l.GetGUID(), TVTBroadcastMaterialType.PROGRAMME)
			If changedTime <> 0
				SetColor 255,235,20
				Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - changedTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(x, y + entryPos * lineHeight, lineWidth, lineHeight-1)
				SetBlend ALPHABLEND
			EndIf

			'draw in topicality
			SetColor 200,50,50
			SetAlpha 0.65 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight + lineHeight-3, lineWidth * l.GetMaxTopicality(), 2)
			SetColor 240,80,80
			SetAlpha 0.85 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight + lineHeight-3, lineWidth * l.GetTopicality(), 2)

			SetAlpha oldalpha
			SetColor 255,255,255

			Local progString:String = l.GetTitle()
			font.DrawBox( progString, x+2, y+1 + entryPos*lineHeight + lineTextDY, lineWidth - 30, lineTextHeight, sALIGN_LEFT_CENTER, SColor8.White)

			Local attString:String = ""
'			local s:string = string(GetPlayer(playerID).aiData.Get("licenceAudienceValue_" + l.GetGUID()))
			Local s:String = MathHelper.NumberToString(l.GetProgrammeTopicality() * l.GetQuality(), 4)
			If s Then attString = "|color=180,180,180|A|/color|"+ s + " "

			font.DrawBox(attString, x+2, y+1 + entryPos*lineHeight + lineTextDY, lineWidth-5, lineTextHeight, sALIGN_RIGHT_CENTER, SColor8.White)

			entryPos :+ 1
		Next

		lineHeight = 11
		entryPos = 0
		For Local a:TAdContract = EachIn availableAdContracts.Values() 'collection.GetAdContracts()
			If a.owner <> playerID Then Continue

			If entryPos Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 50,50,50
			EndIf
			SetAlpha 0.85 * oldAlpha
			DrawRect(x + adLeftX, y + entryPos * lineHeight*2, adLineWidth, lineHeight*2-1)

			Local changedTime:Int = GetChangedTime(a.GetGUID(), TVTBroadcastMaterialType.ADVERTISEMENT)
			If changedTime <> 0
				Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - changedTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND

				SetColor 255,235,20
				If GetRemovedTime(a.GetGUID(), TVTBroadcastMaterialType.ADVERTISEMENT) <> 0
					If a.state = a.STATE_FAILED
						SetColor 255,0,0
					ElseIf a.state = a.STATE_OK
						SetColor 0,255,0
					EndIf
				EndIf

				DrawRect(x + adLeftX, y + entryPos * lineHeight*2, adLineWidth, lineHeight*2-1)
				SetBlend ALPHABLEND
			EndIf
			SetAlpha oldalpha
			SetColor 255,255,255

			Local adString1a:String = a.GetTitle()
			Local adString1b:String = "R: "+(a.GetDaysLeft())+"D"
			If a.GetDaysLeft() = 1
				adString1b = "|color=220,180,50|"+adString1b+"|/color|"
			ElseIf a.GetDaysLeft() = 0
				adString1b = "|color=220,80,80|"+adString1b+"|/color|"
			EndIf
			Local adString2a:String = "Min: " +MathHelper.DottedValue(a.GetMinAudience())
			If a.GetLimitedToTargetGroup() > 0 Or a.GetLimitedToProgrammeGenre() > 0  Or a.GetLimitedToProgrammeFlag() > 0
				adString2a = "**" + adString2a
				'adString1a :+ a.GetLimitedToTargetGroup()+","+a.GetLimitedToProgrammeGenre()+","+a.GetLimitedToProgrammeFlag()
			EndIf
			adString1b :+ " Bl/D: "+a.SendMinimalBlocksToday()

			Local adString2b:String = "Acu: " +MathHelper.NumberToString(a.GetAcuteness()*100.0)
			Local adString2c:String = a.GetSpotsSent() + "/" + a.GetSpotCount()
			font.DrawBox( adString1a, x + adLeftX + 2, y+1 + entryPos*lineHeight*2 + lineHeight*0 + lineTextDY, adLeftX - 40, lineTextHeight, sALIGN_LEFT_CENTER, SColor8.White)
			font.DrawBox( adString1b, x + adLeftX + 2 + adLineWidth-60-2, y+1 + entryPos*lineHeight*2 + lineHeight*0 + lineTextDY, 60, lineTextHeight, sALIGN_RIGHT_CENTER, secondLineCol)

			font.DrawBox( adString2a, x + adLeftX + 2, y+1 + entryPos*lineHeight*2 + lineHeight*1 + lineTextDY, 60, lineTextHeight, sALIGN_LEFT_CENTER, secondLineCol)
			font.DrawBox( adString2b, x + adLeftX + 2 + 65, y+1 + entryPos*lineHeight*2 + lineHeight*1 + lineTextDY, 55, lineTextHeight, sALIGN_CENTER_CENTER, secondLineCol)
			font.DrawBox( adString2c, x + adLeftX + 2 + adLineWidth-55-2, y+1 + entryPos*lineHeight*2 + lineHeight*1 + lineTextDY, 55, lineTextHeight, sALIGN_RIGHT_CENTER, secondLineCol)

			entryPos :+ 1
		Next
		SetAlpha oldAlpha
		SetColor 255,255,255
	End Method
End Type



Type TDebugProgrammePlanInfos
	Global programmeBroadcasts:TMap = CreateMap()
	Global adBroadcasts:TMap = CreateMap()
	Global newsInShow:TMap = CreateMap()
	Global oldestEntryTime:Long
	Global _eventListeners:TEventListenerBase[]
	Global predictor:TBroadcastAudiencePrediction = New TBroadcastAudiencePrediction
	Global predictionCacheProgAudience:TAudience[24]
	Global predictionCacheProg:TAudienceAttraction[24]
	Global predictionCacheNews:TAudienceAttraction[24]
	Global currentPlayer:Int = 0
	Global adSlotWidth:Int = 120
	Global programmeSlotWidth:Int = 200
	Global clockSlotWidth:Int = 15
	Global slotPadding:Int = 3

	Method New()
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammePlan_AddObject, onChangeProgrammePlan) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammePlan_SetNews, onChangeNewsShow) ]
	End Method


	Function onChangeNewsShow:Int(triggerEvent:TEventBase)
		Local broadcast:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("news"))
		Local slot:Int = triggerEvent.GetData().GetInt("slot", -1)
		If Not broadcast Or slot < 0 Then Return False

		newsInShow.Insert(broadcast.GetGUID(), String(Time.GetTimeGone()) )

		RemoveOutdated()
	End Function


	Function onChangeProgrammePlan:Int(triggerEvent:TEventBase)
		Local broadcast:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("object"))
		Local slotType:Int = triggerEvent.GetData().GetInt("slotType", -1)
		If Not broadcast Or slotType <= 0 Then Return False

		If slotType = TVTBroadcastMaterialType.ADVERTISEMENT
			adBroadcasts.Insert(broadcast.GetGUID(), String(Time.GetTimeGone()) )
		Else
			programmeBroadcasts.Insert(broadcast.GetGUID(), String(Time.GetTimeGone()) )
		EndIf

		RemoveOutdated()
	End Function


	Function RemoveOutdated()
		Local maps:TMap[] = [programmeBroadcasts, adBroadcasts, newsInShow]

		oldestEntryTime = -1

		'remove outdated ones (older than 30 seconds))
		For Local map:TMap = EachIn maps
			Local remove:String[]
			For Local guid:String = EachIn map.Keys()
				Local broadcastTime:Long = Long( String(map.ValueForKey(guid)) )
				'old or not happened yet ?
				If broadcastTime + 8000 < Time.GetTimeGone() ' or broadcastTime > Time.GetTimeGone()
					remove :+ [guid]
					Continue
				EndIf

				If oldestEntryTime = -1 Then oldestEntryTime = broadcastTime
				oldestEntryTime = Min(oldestEntryTime, broadcastTime)
			Next

			For Local guid:String = EachIn remove
				map.Remove(guid)
			Next
		Next

		'reset cache
		ResetPredictionCache( GetWorldTime().GetDayHour()+1 )
	End Function


	Function ResetPredictionCache(minHour:Int = 0)
		If minHour = 0
			predictionCacheProgAudience = New TAudience[24]
			predictionCacheProg = New TAudienceAttraction[24]
			predictionCacheNews = New TAudienceAttraction[24]
		Else
			For Local hour:Int = minHour To 23
				predictionCacheProgAudience[hour] = Null
				predictionCacheProg[hour] = Null
				predictionCacheNews[hour] = Null
			Next
		EndIf
	End Function


	Function GetAddedTime:Long(guid:String, slotType:Int=0)
		Select slotType
			Case TVTBroadcastMaterialType.PROGRAMME
				Return Int( String(programmeBroadcasts.ValueForKey(guid)) )
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				Return Int( String(adBroadcasts.ValueForKey(guid)) )
			Case TVTBroadcastMaterialType.NEWS
				Return Int( String(newsInShow.ValueForKey(guid)) )
		End Select
		Return 0
	End Function


	Method Update(playerID:Int, x:Int, y:Int)
	End Method


	Function Draw(playerID:Int, x:Int, y:Int)
		If playerID <= 0 Then playerID = GetPlayerBase().playerID
		Local currDay:Int = GetWorldTime().GetDay()
		Local currHour:Int = GetWorldTime().GetDayHour()
		Local daysProgramme:TBroadcastMaterial[] = GetPlayerProgrammePlan( playerID ).GetProgrammeSlotsInTimeSpan(currDay, 0, currDay, 23)
		Local daysAdvertisements:TBroadcastMaterial[] = GetPlayerProgrammePlan( playerID ).GetAdvertisementSlotsInTimeSpan(currDay, 0, currDay, 23)
		Local lineHeight:Int = 12
		Local lineTextHeight:Int = 15
		Local lineTextDY:Int = -1
		Local programmeSlotX:Int = x + clockSlotWidth + slotPadding
		Local adSlotX:Int = programmeSlotX + programmeSlotWidth + slotPadding

		Local font:TBitmapFont = GetBitmapFont("default", 10)

		'statistic for today
		Local dailyBroadcastStatistic:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(currDay, True)

		'clean up if needed
		If oldestEntryTime >= 0 And oldestEntryTime + 10000 < Time.GetTimeGone() Then RemoveOutdated()


		If currentPlayer <> playerID
			currentPlayer = playerID
			ResetPredictionCache(0) 'predict all again
			predictor.RefreshMarkets() 'in case nobody did yet
		EndIf

		If GetWorldTime().GetTimeGone() Mod 5 = 0
			predictor.RefreshMarkets()
		EndIf


		Local s:String = "|color=200,255,200|PRED|/color|/|color=200,200,255|GUESS|/color|/|color=255,220,210|REAL|/color|"
		GetBitmapFont("default", 10).DrawBox( s, programmeSlotX, y + -1*lineHeight + lineTextDY, programmeSlotWidth, lineTextHeight, sALIGN_RIGHT_TOP, SColor8.White)


		For Local hour:Int = 0 Until daysProgramme.length
			Local audienceResult:TAudienceResultBase
			If hour <= currHour
				audienceResult = dailyBroadcastStatistic.GetAudienceResult(playerID, hour)
			EndIf

			Local adString:String = ""
			Local progString:String = ""
			Local adString2:String = ""
			Local progString2:String = ""

			'use "0" as day param because currentHour includes days already
			Local advertisement:TBroadcastMaterial = daysAdvertisements[hour]
			If advertisement
				Local spotNumber:String
				Local specialMarker:String = ""
				Local ad:TAdvertisement = TAdvertisement(advertisement)
				If ad
					If ad.IsState(TAdvertisement.STATE_FAILED)
						spotNumber = "-/" + ad.contract.GetSpotCount()
					Else
						spotNumber = GetPlayerProgrammePlan(advertisement.owner).GetAdvertisementSpotNumber(ad) + "/" + ad.contract.GetSpotCount()
					EndIf

					If ad.contract.GetLimitedToTargetGroup()>0 Or ad.contract.GetLimitedToProgrammeGenre()>0 Or ad.contract.GetLimitedToProgrammeFlag()>0
						specialMarker = "**"
					EndIf
				Else
					spotNumber = (hour - advertisement.programmedHour + 1) + "/" + advertisement.GetBlocks(TVTBroadcastMaterialType.ADVERTISEMENT)
				EndIf
				adString = advertisement.GetTitle()
				If ad Then adString = Int(ad.contract.GetMinAudience()/1000) +"k " + adString
				adString2 = specialMarker + "[" + spotNumber + "]"

				If TProgramme(advertisement) Then adString = "T: "+adString
			EndIf

			Local programme:TBroadcastMaterial = daysProgramme[hour]
			If programme
				progString = programme.GetTitle()
				If TAdvertisement(programme) Then progString = "I: "+progString

				progString2 = (hour - programme.programmedHour + 1) + "/" + programme.GetBlocks(TVTBroadcastMaterialType.PROGRAMME)
'				if currHour < hour
					'uncached
					If Not predictionCacheProgAudience[hour]
						For Local i:Int = 1 To 4
							Local prog:TBroadcastMaterial = GetPlayerProgrammePlan(i).GetProgramme(currDay, hour)
							If prog
								Local progBlock:Int = GetPlayerProgrammePlan(i).GetProgrammeBlock(currDay, hour)
								Local prevProg:TBroadcastMaterial = GetPlayerProgrammePlan(i).GetProgramme(currDay, hour-1)
								Local newsAttr:TAudienceAttraction = Null
								Local prevAttr:TAudienceAttraction = Null
								If prevProg And currDay
									Local prevProgBlock:Int = GetPlayerProgrammePlan(i).GetProgrammeBlock(currDay, (hour-1 + 24) Mod 24)
									If prevProgBlock > 0
										prevAttr = prevProg.GetAudienceAttraction((hour-1 + 24) Mod 24, prevProgBlock, Null, Null, True, True)
									EndIf
								EndIf
								Local newsAge:Int = 0
								Local newsshow:TBroadcastMaterial
								For Local hoursAgo:Int = 0 To 6
									newsshow = GetPlayerProgrammePlan(i).GetNewsShow(currDay, hour - hoursAgo)
									If newsshow Then Exit
									newsAge = hoursAgo
								Next
								If newsshow
									newsAttr = newsshow.GetAudienceAttraction(hour, 1, prevAttr, Null, True, True)
'									newsAttr.MultiplyFloat()
								EndIf
								Local attr:TAudienceAttraction = prog.GetAudienceAttraction(hour, progBlock, prevAttr, newsAttr, True, True)
								predictor.SetAttraction(i, attr)
							Else
								predictor.SetAverageValueAttraction(i, 0)
							EndIf
						Next
						predictor.RunPrediction(currDay, hour)
						predictionCacheProgAudience[hour] = predictor.GetAudience(playerID)
					EndIf

					progString2 :+ " |color=200,255,200|"+Int(predictionCacheProgAudience[hour].GetTotalSum()/1000)+"k|/color|"
'				endif

				Local player:TPlayer = GetPlayer(playerID)
				Local guessedAudience:TAudience
				If player Then guessedAudience = TAudience(player.aiData.Get("guessedaudience_"+currDay+"_"+hour, Null))
				If guessedAudience
					progString2 :+ " / |color=200,200,255|"+Int(guessedAudience.GetTotalSum()/1000)+"k|/color|"
				Else
					progString2 :+ " / |color=200,200,255|??|/color|"
				EndIf

				If audienceResult
					progString2 :+ " / |color=255,220,210|"+Int(audienceResult.audience.GetTotalSum()/1000) +"k|/color|"
				Else
					progString2 :+ " / |color=255,220,210|??|/color|"
				EndIf
			EndIf

			If progString = "" And GetWorldTime().GetDayHour() > hour Then progString = "PROGRAMME OUTAGE"
			If adString = "" And GetWorldTime().GetDayHour() > hour Then adString = "AD OUTAGE"

			Local oldAlpha:Float = GetAlpha()
			If hour Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 50,50,50
			EndIf
			SetAlpha 0.85 * oldAlpha
			DrawRect(x, y + hour * lineHeight, clockSlotWidth, lineHeight-1)
			DrawRect(programmeSlotX, y + hour * lineHeight, programmeSlotWidth, lineHeight-1)
			DrawRect(adSlotX, y + hour * lineHeight, adSlotWidth, lineHeight-1)


			Local progTime:Long = 0, adTime:Long = 0
			If advertisement Then adTime = GetAddedTime(advertisement.GetGUID(), TVTBroadcastMaterialType.ADVERTISEMENT)
			If programme Then progTime = GetAddedTime(programme.GetGUID(), TVTBroadcastMaterialType.PROGRAMME)

			SetColor 255,235,20
			If progTime <> 0
				Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - progTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(programmeSlotX, y + hour * lineHeight, programmeSlotWidth, lineHeight-1)
				SetBlend ALPHABLEND
			EndIf
			If adTime <> 0
				Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - adTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(adSlotX, y + hour * lineHeight, adSlotWidth, lineHeight-1)
				SetBlend ALPHABLEND
			EndIf

			'indicate reached / required audience
			If hour < currHour And TAdvertisement(advertisement) And audienceResult
				Local reachedAudience:Int = audienceResult.audience.GetTotalSum()
				Local adMinAudience:Int = TAdvertisement(advertisement).contract.GetMinAudience()
				If reachedAudience < adMinAudience
					SetColor 255,160,160
					SetAlpha 0.75 * oldAlpha
					DrawRect(adSlotX, y + hour * lineHeight + lineHeight - 4, adSlotWidth * Min(1.0,  reachedAudience / Float(adMinAudience)), 2)
				ElseIf reachedAudience > adMinAudience
					SetColor 160,160,255
					SetAlpha 0.75 * oldAlpha
					DrawRect(adSlotX, y + hour * lineHeight + lineHeight - 4, adSlotWidth * Min(1.0,  Float(adMinAudience) / reachedAudience), 2)
				Else
					SetColor 180,255,160
					SetAlpha 0.75 * oldAlpha
					DrawRect(adSlotX, y + hour * lineHeight + lineHeight - 4, adSlotWidth, 2)
				EndIf
			EndIf

			SetColor 255,255,255
			SetAlpha oldAlpha

			font.Draw( RSet(hour,2).Replace(" ", "0"), x + 2, y + hour*lineHeight + lineTextDY)
			If programme Then SetStateColor(programme)
			font.DrawBox( progString, programmeSlotX + 2, y + hour*lineHeight + lineTextDY, programmeSlotWidth - 60, lineTextHeight, sALIGN_LEFT_TOP, SColor8.White)
			font.DrawBox( progString2, programmeSlotX, y + hour*lineHeight + lineTextDY, programmeSlotWidth - 2, lineTextHeight, sALIGN_RIGHT_TOP, SColor8.White)
			If advertisement Then SetStateColor(advertisement)
			font.DrawBox( adString, adSlotX + 2, y + hour*lineHeight + lineTextDY, adSlotWidth - 30, lineTextHeight, sALIGN_LEFT_TOP, SColor8.White)
			font.DrawBox( adString2, adSlotX, y + hour*lineHeight + lineTextDY, adSlotWidth - 2, lineTextHeight, sALIGN_RIGHT_TOP, SColor8.White)
			SetColor 255,255,255
		Next

		'a bit space between programme plan and news show plan
		Local newsY:Int = y + daysProgramme.length * lineHeight + lineHeight
		For Local newsSlot:Int = 0 To 2
			Local news:TBroadcastMaterial = GetPlayerProgrammePlan( playerID ).GetNewsAtIndex(newsSlot)
			Local oldAlpha:Float = GetAlpha()
			If newsSlot Mod 2 = 0
				SetColor 0,0,40
			Else
				SetColor 50,50,90
			EndIf
			SetAlpha 0.85 * oldAlpha
			DrawRect(x, newsY + newsSlot * lineHeight, clockSlotWidth, lineHeight-1)
			DrawRect(programmeSlotX, newsY + newsSlot * lineHeight, programmeSlotWidth, lineHeight-1)


			If TNews(news)
				Local newsTime:Long = GetAddedTime(news.GetGUID(), TVTBroadcastMaterialType.NEWS)
				If newsTime <> 0
					Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - newsTime) / 5000.0))
					SetColor 255,255,255
					SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
					SetBlend LIGHTBLEND
					DrawRect(programmeSlotX, newsY + newsSlot * lineHeight, programmeSlotWidth, lineHeight-1)
					SetBlend ALPHABLEND
				EndIf

				SetColor 220,110,110
				SetAlpha 0.50 * oldAlpha
				DrawRect(programmeSlotX, newsY + newsSlot * lineHeight + lineHeight-3, programmeSlotWidth * TNews(news).GetNewsEvent().GetTopicality(), 2)
			EndIf

			SetColor 255,255,255
			SetAlpha oldAlpha

			font.DrawBox( newsSlot+1 , x + 2, newsY + newsSlot * lineHeight + lineTextDY, clockSlotWidth-2, lineTextHeight, sALIGN_CENTER_TOP, SColor8.White)
			If news
				font.DrawBox(news.GetTitle(), programmeSlotX + 2, newsY + newsSlot*lineHeight + lineTextDY, programmeSlotWidth - 4, lineTextHeight, sALIGN_LEFT_TOP, SColor8.White)
			Else
				font.DrawBox("NEWS OUTAGE", programmeSlotX + 2, newsY + newsSlot*lineHeight + lineTextDY, programmeSlotWidth - 4, lineTextHeight, sALIGN_LEFT_TOP, SColor8.Red)
			EndIf
		Next
	End Function


	Function SetStateColor(material:TBroadcastMaterial)
		If Not material
			SetColor 255,255,255
			Return
		EndIf

		Select material.state
			Case TBroadcastMaterial.STATE_RUNNING
				SetColor 255,230,120
			Case TBroadcastMaterial.STATE_OK
				SetColor 200,255,200
			Case TBroadcastMaterial.STATE_FAILED
				SetColor 250,150,120
			Default
				SetColor 255,255,255
		End Select
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




Type TDebugControlsButton
	Field data:Object
	Field dataInt:Int = -1
	Field text:String = "Button"
	Field x:Int = 0
	Field y:Int = 0
	Field w:Int = 150
	Field h:Int = 16
	Field selected:Int = False
	Field clicked:Int = False
	Field _onClickHandler(sender:TDebugControlsButton)


	Method Update:Int(offsetX:Int=0, offsetY:Int=0)
		If THelper.MouseIn(offsetX + x,offsetY + y,w,h)
			If MouseManager.IsClicked(1)
				onClick()
				'handle clicked
				MouseManager.SetClickHandled(1)
				Return True
			EndIf
		EndIf
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		SetColor 150,150,150
		DrawRect(offsetX + x,offsetY + y,w,h)
		If selected
			If THelper.MouseIn(offsetX + x,offsetY + y,w,h)
				SetColor 120,110,100
			Else
				SetColor 80,70,50
			EndIf
		ElseIf THelper.MouseIn(offsetX + x,offsetY + y,w,h)
			SetColor 50,50,50
		Else
			SetColor 0,0,0
		EndIf

		DrawRect(offsetX + x+1,offsetY + y+1,w-2,h-2)
		SetColor 255,255,255
		GetBitmapFont("default", 11).DrawBox(text, offsetX + x,offsetY + y,w,h, sALIGN_CENTER_CENTER, SColor8.White)
	End Method


	Method onClick()
		selected = True
		clicked = True

		If _onClickHandler Then _onClickHandler(Self)
	End Method
End Type




Type TDebugFinancialInfos
	Method Update(playerID:Int, x:Int, y:Int)
	End Method

	Method Draw(playerID:Int, x:Int, y:Int)
		If playerID = -1
			Draw(1, x, y + 30*0)
			Draw(2, x, y + 30*1)
			Draw(3, x + 125, y + 30*0)
			Draw(4, x + 125, y + 30*1)
			Return
		EndIf

		SetColor 0,0,0
		DrawRect(x, y, 123, 35)

		SetColor 255,255,255

		Local textX:Int = x+1
		Local textY:Int = y+1

		Local finance:TPlayerFinance = GetPlayerFinanceCollection().GetIgnoringStartDay(playerID, GetWorldTime().GetDay())
		Local financeTotal:TPlayerFinance = GetPlayerFinanceCollection().GetTotal(playerID)

		Local font:TBitmapfont = GetBitmapFont("default", 10)
		font.Draw("Money #"+playerID+": "+MathHelper.DottedValue(finance.money), textX, textY)
		textY :+ 9+1
		font.Draw("~tLic:~t~t|color=120,255,120|"+MathHelper.DottedValue(finance.income_programmeLicences)+"|/color| / |color=255,120,120|"+MathHelper.DottedValue(finance.expense_programmeLicences), textX, textY)
		textY :+ 9
		font.Draw("~tAd:~t~t|color=120,255,120|"+MathHelper.DottedValue(finance.income_ads)+"|/color| / |color=255,120,120|"+MathHelper.DottedValue(finance.expense_penalty), textX, textY)
	End Method
End Type
