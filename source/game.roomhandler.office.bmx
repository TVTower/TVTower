SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.screen.office.programmeplanner.bmx"
Import "game.screen.office.stationmap.bmx"
Import "game.screen.office.achievements.bmx"
Import "game.screen.office.archivedmessages.bmx"
Import "game.screen.office.statistics.bmx"
Import "game.screen.office.financials.bmx"

Import "game.misc.archivedmessage.bmx"


Import "game.screen.office.financials.bmx"
'Office: handling the players room
Type RoomHandler_Office extends TRoomHandler
	Field archivedMessageTotalCount:int
	Field archivedMessageUnreadCount:int

	'=== OFFICE ROOM ===
	Global roomOwner:int

	Global StationsToolTip:TTooltip
	Global PlannerToolTip:TTooltip
	Global SafeToolTip:TTooltip
	Global MessagesToolTip:TTooltip

	Global _instance:RoomHandler_Office
	Global _initDone:int = False
	Global _globalEventListeners:TEventListenerBase[]
	Global _localEventListeners:TEventListenerBase[]


	Function GetInstance:RoomHandler_Office()
		if not _instance then _instance = new RoomHandler_Office
		return _instance
	End Function


	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'reset/initialize screens (event connection etc.)
		TScreenHandler_Financials.Initialize()
		TScreenHandler_ProgrammePlanner.Initialize()
		TScreenHandler_StationMap.Initialize()
		TScreenHandler_OfficeStatistics.GetInstance().Initialize()
		TScreenHandler_OfficeAchievements.GetInstance().Initialize()
		TScreenHandler_OfficeArchivedMessages.GetInstance().Initialize()


		'=== REGISTER HANDLER ===
		RegisterHandler()

		ReloadMessageCount()

		local screen:TScreen = ScreenCollection.GetScreen("screen_office")

		' === REGISTER EVENTS ===

		' remove old listeners
		EventManager.UnregisterListenersArray(_globalEventListeners)
		EventManager.UnregisterListenersArray(_localEventListeners)
		_globalEventListeners = new TEventListenerBase[0]
		_localEventListeners = new TEventListenerBase[0]

		' register new global listeners
		'handle the "office" itself (not computer etc)
		'using this approach avoids "tooltips" to be visible in subscreens
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginEnter, onEnterScreen, screen) ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ArchivedMessageCollection_OnAdd, onAddOrRemoveArchivedMessage) ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ArchivedMessageCollection_OnRemove, onAddOrRemoveArchivedMessage) ]


		' === REGISTER CALLBACKS ===

		' to update/draw the screen
		screen.AddUpdateCallback(onUpdateScreen)
		screen.AddDrawCallback(onDrawScreen)


		'(re-)localize content
		'disabled as the screens are setting their language during "initialize()"
		'too.
		'reenable if doing more localization there
		'SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		StationsToolTip = null
		PlannerToolTip = null
		SafeToolTip = null
		MessagesToolTip = null

		'=== remove obsolete gui elements ===
		'

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("office", GetInstance())
	End Method


	Method SetLanguage()
		TScreenHandler_Financials.SetLanguage()
		TScreenHandler_ProgrammePlanner.SetLanguage()
		TScreenHandler_StationMap.SetLanguage()
		TScreenHandler_OfficeStatistics.GetInstance().SetLanguage()
		TScreenHandler_OfficeAchievements.GetInstance().SetLanguage()
		TScreenHandler_OfficeArchivedMessages.GetInstance().SetLanguage()
	End Method


	'override: clear the screen (remove dragged elements)
	Method AbortScreenActions:Int()
		'abort handling dragged elements in the planner
		TScreenHandler_ProgrammePlanner.AbortScreenActions()

		return False
	End Method


	Method ReloadMessageCount:int()
		archivedMessageTotalCount = 0
		archivedMessageUnreadCount = 0

		For local message:TArchivedMessage = EachIn GetArchivedMessageCollection().entries.values()
			archivedMessageTotalCount :+ 1
			if not message.IsRead(roomOwner) then archivedMessageUnreadCount :+ 1
		Next
	End Method


	Function onAddOrRemoveArchivedMessage:int( triggerEvent:TEventBase )
		local archivedMessage:TArchivedMessage = TArchivedMessage(triggerEvent.GetReceiver())
		if not archivedMessage then return False

		if GetInstance().roomOwner = archivedMessage.owner or archivedMessage.owner <= 0
			GetInstance().ReloadMessageCount()
		endif
	End Function


	Function onEnterScreen:int( triggerEvent:TEventBase )
		GetInstance().ReloadMessageCount()
	End Function


	Method onDrawRoom:int( triggerEvent:TEventBase )
		'
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'
	End Method



	Function onDrawScreen:Int(sender:TScreen, tweenValue:Float)
		Local ingameScreen:TInGameScreen_Room = TInGameScreen_Room(sender)
		Local room:TRoomBase = GetRoomBaseCollection().Get(ingameScreen.currentRoomID)

		roomOwner = room.owner

		local spriteLevel:int = 0
		if GetInstance().archivedMessageTotalCount >  0 then spriteLevel = 1
		if GetInstance().archivedMessageTotalCount > 10 then spriteLevel = 2
		if GetInstance().archivedMessageTotalCount > 25 then spriteLevel = 3
		if GetInstance().archivedMessageTotalCount > 50 then spriteLevel = 4
		if spriteLevel > 0
			GetSpriteFromRegistry("screen_office_messages"+spriteLevel).Draw(0,0)
		endif
		if GetInstance().archivedMessageUnreadCount > 0
			GetSpriteFromRegistry("screen_office_messages_unread").Draw(0,0)
		endif

		'allowed for owner only - or with key
		If GetPlayer().HasMasterKey() OR IsPlayersRoom(room)
			'allowed for all - if having keys
			If StationsToolTip Then StationsToolTip.Render()
			If PlannerToolTip Then PlannerToolTip.Render()
			If SafeToolTip Then SafeToolTip.Render()

			If MessagesToolTip Then MessagesToolTip.Render()

			'safe
			If THelper.MouseIn(165,85,70,100)
				GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
			'planner - reachable for all
			ElseIf THelper.MouseIn(600,140,128,210)
				GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
			'archived messages
			ElseIf THelper.MouseIn(395,210,195,65)
				GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
			'stationmap
			ElseIf THelper.MouseIn(732,45,160,170) AND IsPlayersRoom(room)
				GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
			EndIf
		EndIf
	End Function


	Function onUpdateScreen:Int(sender:TScreen, deltaTime:Float)
		Local ingameScreen:TInGameScreen_Room = TInGameScreen_Room(sender)
		Local room:TRoomBase = GetRoomBaseCollection().Get(ingameScreen.currentRoomID)

		roomOwner = room.owner

		'clicked door?
		If MouseManager.IsClicked(1) and THelper.MouseIn(25,40,150,295)
			GetPlayer().GetFigure().LeaveRoom()

			MouseManager.SetClickHandled(1)
		EndIf


		'allowed for owner only - or with key
		If GetPlayer().HasMasterKey() OR IsPlayersRoom(room)

			'only if player does not want to leave room
			if not MouseManager.IsClicked(2)
				'safe - reachable for all
				If THelper.MouseIn(165,85,70,100)
					If not SafeToolTip Then SafeToolTip = TTooltip.Create(GetLocale("ROOM_SAFE"), GetLocale("FOR_PRIVATE_AFFAIRS"), 140, 100,-1,-1)
					SafeToolTip.enabled = 1
					SafeToolTip.SetMinTitleAndContentWidth(90, 120)
					SafeToolTip.Hover()

					If MouseManager.IsClicked(1) and not GetPlayer().GetFigure().IsChangingRoom()
						'handled click
						MouseManager.SetClickHandled(1)

						ScreenCollection.GoToSubScreen("screen_office_safe")
					endif
				EndIf

				'planner - reachable for all
				If THelper.MouseIn(600,140,128,210)
					If not PlannerToolTip
						PlannerToolTip = TTooltip.Create(GetLocale("ROOM_PROGRAMMEPLANNER"), GetLocale("AND_STATISTICS"), 580, 140)
						PlannerTooltip._minContentWidth = 150
					endif
					PlannerToolTip.enabled = 1
					PlannerToolTip.Hover()

					If MouseManager.IsClicked(1) and not GetPlayer().GetFigure().IsChangingRoom()
						'handled click
						MouseManager.SetClickHandled(1)
						ScreenCollection.GoToSubScreen("screen_office_programmeplanner")
					endif
				EndIf

				'archived messages
				If THelper.MouseIn(395,210,195,65)
					If not MessagesToolTip
						MessagesToolTip = TTooltip.Create(GetLocale("ARCHIVED_MESSAGES"), GetLocale("READ_MESSAGES_YOU_MIGHT_HAVE_MISSED"), 390, 160)
						MessagesToolTip._minContentWidth = 180
					endif
					MessagesToolTip.enabled = 1
					MessagesToolTip.Hover()

					If MouseManager.IsClicked(1) and not GetPlayer().GetFigure().IsChangingRoom()
						'handled click
						MouseManager.SetClickHandled(1)
						ScreenCollection.GoToSubScreen("screen_office_archivedmessages")
					endif
				EndIf

				If THelper.MouseIn(732,45,160,170)
					If not StationsToolTip
						StationsToolTip = TTooltip.Create(GetLocale("ROOM_STATIONMAP"), GetLocale("BUY_AND_SELL"), 650, 80, 0, 0)
						StationsToolTip._minContentWidth = 150
					endif

					StationsToolTip.enabled = 1
					StationsToolTip.Hover()

					If MouseManager.IsClicked(1) and not GetPlayer().GetFigure().IsChangingRoom() ' AND IsPlayersRoom(room)
						'handled click
						MouseManager.SetClickHandled(1)
						ScreenCollection.GoToSubScreen("screen_office_stationmap")
					endif
				EndIf
			endif

			If StationsToolTip Then StationsToolTip.Update()
			If PlannerToolTip Then PlannerToolTip.Update()
			If SafeToolTip Then SafeToolTip.Update()
			If MessagesToolTip Then MessagesToolTip.Update()
		EndIf
	End Function
End Type
