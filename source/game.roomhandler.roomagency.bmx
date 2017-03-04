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


	Method onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure or not figure.playerID then return FALSE

		GetInstance().FigureEntersRoom(figure)
	End Method



	Method FigureEntersRoom:int(figure:TFigureBase)
		'=== FOR ALL PLAYERS ===

rem
		'refill the empty blocks, also sets haveToRefreshGuiElements=true
		'so next call the gui elements will be redone
		ReFillBlocks()


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			'reorder AFTER refilling
			ResetContractOrder()
		endif
endrem
	End Method


	Method UpdateEmptyRooms()
		For local r:TRoomBase = EachIn GetRoomBaseCollection().list
			'ignore non-rentable rooms
			if r.IsFreehold() or r.IsRented() then continue

			'room empty for a long time?
			if r.rentalChangeTime + 12*3600 < GetWorldTime().GetTimeGone()
				'let original owner rent it
				r.BeginRental(0)
				print "RoomHandler_RoomAgency.UpdateEmptyRooms(): re-rented. " + r.GetDescription(1) 
			endif
		Next
	End Method


	Method GetTotalRent:int(playerID:int)
		local result:int = 0
		For local r:TRoomBase = EachIn GetRoomBaseCollection().list
			if r.GetOwner() <> playerID then continue

		'	r.GetRent()
		Next
	End Method
	

	Function BeginRoomRental:int(room:TRoomBase, owner:int=0)
		if room.IsRented() then return False

		print "RoomHandler_RoomAgency.BeginRoomRental()"
		room.BeginRental(owner)
		
		return True
	End Function


	Function CancelRoomRental:int(room:TRoomBase)
		if not room.IsRented() then return False
		
		print "RoomHandler_RoomAgency.CancelRoomRental()"
		room.CancelRental()

		return True
	End Function
End Type

