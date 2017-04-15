SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.player.base.bmx"




'Dies hier ist die Raumauswahl im Fahrstuhl.
Type RoomHandler_ElevatorPlan extends TRoomHandler
	Global _eventListeners:TLink[]
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
		GetElevatorRoomBoard().DrawSigns()
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		local mouseClicked:int = MouseManager.IsClicked(1)

		'if possible, change the target to the clicked door
		if mouseClicked
			local sign:TRoomBoardSign = GetElevatorRoomBoard().GetSignByOriginalXY(MouseManager.GetPosition().GetIntX(),MouseManager.GetPosition().GetIntY())
			if sign and sign.door
				TFigure(GetPlayerBase().GetFigure()).SendToDoor(sign.door)
			endif
			MouseManager.ResetKey(1)
		endif

		GetElevatorRoomBoard().UpdateSigns(False)
	End Method
End Type


Type TElevatorRoomBoard extends TRoomBoardBase
	Global _eventListeners:TLink[]
	Global _instance:TElevatorRoomBoard


	Function GetInstance:TElevatorRoomBoard()
		if not _instance then _instance = new TElevatorRoomBoard
		return _instance
	End Function


	Method AddBoardSigns:int()
		'instead of adding new signs for each door, we copy the signs of the
		'current room  plan
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
		'EventManager.unregisterListenersByLinks(_eventListeners)
		'_eventListeners = new TLink[0]

		if not _eventListeners or _eventListeners.length = 0
			'invalidate caches of signs - so they get redone
			_eventListeners :+ [ EventManager.registerListenerFunction("SaveGame.OnLoad", onSavegameLoad) ]
			_eventListeners :+ [ EventManager.registerListenerFunction("Language.onSetLanguage", onSetLanguage) ]

			'figure enters screen - reset the guilists, limit listening to the 4 rooms
			Local screen:TScreen = ScreenCollection.GetScreen("screen_elevatorplan")
			_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterElevatorPlanScreen, screen) ]
		endif
	End Method


	Function onEnterElevatorPlanScreen:Int(triggerEvent:TEventBase)
		print "REFRESHING ELEVATOR"
		GetInstance().Reset()
		GetInstance().AddBoardSigns()

		print "REFRESHED ELEVATOR"
	End Function


	Function onSavegameLoad:Int(triggerEvent:TEventBase)
		GetInstance().ResetImageCaches()
	End Function

	Function onSetLanguage:Int(triggerEvent:TEventBase)
		GetInstance().ResetImageCaches()
	End Function
End Type


Function GetElevatorRoomBoard:TElevatorRoomBoard()
	return TElevatorRoomBoard.GetInstance()
End Function
