SuperStrict
Import "game.roomhandler.base.bmx"


'RoomAgency
Type RoomHandler_RoomAgency extends TRoomHandler
	Global _instance:RoomHandler_RoomAgency


	Function GetInstance:RoomHandler_RoomAgency()
		if not _instance then _instance = new RoomHandler_RoomAgency
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
		GetRoomHandlerCollection().SetHandler("roomagency", GetInstance())
	End Method
	

	Function RentRoom:int(room:TRoom, owner:int=0)
		print "RoomHandler_RoomAgency.RentRoom()"
		room.ChangeOwner(owner)
	End Function


	Function CancelRoom:int(room:TRoom)
		print "RoomHandler_RoomAgency.CancelRoom()"
		room.ChangeOwner(0)
	End Function
End Type