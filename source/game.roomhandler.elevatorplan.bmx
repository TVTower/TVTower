SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.player.base.bmx"




'Dies hier ist die Raumauswahl im Fahrstuhl.
Type RoomHandler_ElevatorPlan extends TRoomHandler
	Global _eventListeners:TEventListenerBase[]
	Global _instance:RoomHandler_ElevatorPlan


	Function GetInstance:RoomHandler_ElevatorPlan()
		if not _instance then _instance = new RoomHandler_ElevatorPlan
		return _instance
	End Function


	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()

		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		'

		'=== remove obsolete gui elements ===
		'

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("elevatorplan", GetInstance())
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		GetElevatorRoomBoard().DrawSigns(False)
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'if possible, change the target to the clicked door
		if MouseManager.IsClicked(1)
			local sign:TRoomBoardSign = GetElevatorRoomBoard().GetSignByOriginalXY(MouseManager.GetPosition().GetIntX(),MouseManager.GetPosition().GetIntY())
			if sign and sign.door
				TFigure(GetPlayerBase().GetFigure()).SendToDoor(sign.door)
			endif

			'handled left click
			MouseManager.SetClickHandled(1)
		endif

		GetElevatorRoomBoard().UpdateSigns(False)
	End Method
End Type


Type TElevatorRoomBoard extends TRoomBoardBase
	Global _eventListeners:TEventListenerBase[]
	Global _instance:TElevatorRoomBoard


	Function GetInstance:TElevatorRoomBoard()
		if not _instance then _instance = new TElevatorRoomBoard
		return _instance
	End Function


	Method AddBoardSigns:int() override
		'just adding NEW board signs would remove the information of
		'switched positions
		'so better COPY each sign of the original room plan

		rem
		For local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().List
			'create the sign in the roomplan (if not "invisible door")
			If door.doorType >= 0
				local sign:TRoomBoardSign = new TRoomBoardSign.Init(door)
				AddSign(sign)
			endif
		Next
		endrem

		For local sign:TRoomBoardSign = EachIn GetRoomBoard().list
			AddSign( sign.Copy() )
		Next
	End Method


	Method Initialize:int()
		Reset()
		AddBoardSigns()

		'=== EVENTS ===
		'=== remove all registered event listeners
		'disabled: no methods
		'EventManager.UnregisterListenersArray(_eventListeners)
		'_eventListeners = new TEventListenerBase[0]

		if not _eventListeners or _eventListeners.length = 0
			'invalidate caches of signs - so they get redone
			_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnLoad, onSavegameLoad) ]
			_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.App_OnSetLanguage, onSetLanguage) ]
			_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Room_OnBeginRental, onChangeRoomOwner) ]
			_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Room_OnCancelRental, onChangeRoomOwner) ]

			'figure enters screen - reset the guilists, limit listening to the 4 rooms
			Local screen:TScreen = ScreenCollection.GetScreen("screen_elevatorplan")
			_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginEnter, onEnterElevatorPlanScreen, Null, screen) ]
		endif
	End Method


	Function onEnterElevatorPlanScreen:Int(triggerEvent:TEventBase)
		GetInstance().Reset()
		GetInstance().AddBoardSigns()
	End Function


	Function onSavegameLoad:Int(triggerEvent:TEventBase)
		GetInstance().ResetImageCaches()
	End Function

	Function onSetLanguage:Int(triggerEvent:TEventBase)
		GetInstance().ResetImageCaches()
	End Function


	'recreate image cache if a room owner changes
	Function onChangeRoomOwner:Int(triggerEvent:TEventBase)
		'reset caches of the affected signs
		Local roomOwner:Int = triggerEvent.GetData().GetInt("owner")
		GetInstance().ResetImageCaches(roomOwner)
	End Function
End Type


Function GetElevatorRoomBoard:TElevatorRoomBoard()
	return TElevatorRoomBoard.GetInstance()
End Function
