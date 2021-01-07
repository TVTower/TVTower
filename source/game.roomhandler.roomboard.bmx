SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.misc.roomboardsign.bmx"



Type RoomHandler_Roomboard extends TRoomHandler
	Global _instance:RoomHandler_Roomboard


	Function GetInstance:RoomHandler_Roomboard()
		if not _instance then _instance = new RoomHandler_Roomboard
		return _instance
	End Function

	
	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS =====
		'nothing up to now


		'=== EVENTS ===
		'nothing up to now


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
		GetRoomHandlerCollection().SetHandler("roomboard", GetInstance())
	End Method
	

	Method AbortScreenActions:Int()
		local abortedAction:int = False

		if GetRoomBoard().DropBackDraggedSigns() then abortedAction = True
		GetRoomBoard().UpdateSigns(False)

		return abortedAction
	End Method
	

	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		local figure:TFigureBase = TFigureBase( triggerEvent.GetSender())
		if not figure then return FALSE

		'only pay attention to players
		if figure.playerID
			'roomboard left without animation as soon as something dragged but leave forced
			If GetRoomBoard().draggedSign
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		GetRoomBoard().DrawSigns(True)
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'only allow dragging of roomsigns when no exitapp-dialoge exists
'RONNY
'		if not TApp.ExitAppDialogue
			GetRoomBoard().UpdateSigns(True)
'		else
'			TRoomBoardSign.DropBackDraggedSigns()
'			TRoomBoardSign.UpdateAll(False)
'		endif
	End Method
End Type
