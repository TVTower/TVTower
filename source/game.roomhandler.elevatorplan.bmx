SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.player.base.bmx"




'Dies hier ist die Raumauswahl im Fahrstuhl.
Type RoomHandler_ElevatorPlan extends TRoomHandler
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


		'=== CREATE ELEMENTS ===
		'create an intial plan (might be empty if no doors are loaded yet)
		'so pay attention to run it once AFTER room creation/loading
		ReCreatePlan()

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
	


	Function ReCreatePlan()
		GetRoomBoard().Initialize()
		For local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().List
			'create the sign in the roomplan (if not "invisible door")
			If door.doorType >= 0 then new TRoomBoardSign.Init(door)
		Next
	End Function


	Method onDrawRoom:int( triggerEvent:TEventBase )
		GetRoomBoard().DrawSigns()
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		local mouseClicked:int = MouseManager.IsClicked(1)

		'if possible, change the target to the clicked door
		if mouseClicked
			local sign:TRoomBoardSign = GetRoomBoard().GetSignByOriginalXY(MouseManager.GetPosition().GetIntX(),MouseManager.GetPosition().GetIntY())
			if sign and sign.door
				TFigure(GetPlayerBase().GetFigure()).SendToDoor(sign.door)
			endif
			MouseManager.ResetKey(1)
		endif

		GetRoomBoard().UpdateSigns(False)
	End Method
End Type
