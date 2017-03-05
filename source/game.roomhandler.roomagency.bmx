SuperStrict
Import "game.roomhandler.base.bmx"


'RoomAgency
Type RoomHandler_RoomAgency extends TRoomHandler
	rem
	'unused for now
	'contains contracts for rented rooms
	Field rentalContracts:TList = CreateList()
	endrem

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

	rem
	'unused for now

	Method AddRentalContract:int(rentalContract:TRoomRentalContract)
		if rentalContract.Contains(rentalContract) then return False
		rentalContracts.AddLast(rentalContract)
	End Method


	Method GetRentalContract:TRoomRentalContract(contractGUID:string)
		For local c:TRoomRentalContract = Eachin rentalContracts
			if c.IsGUID(contractGUID) then return c
		Next
		return null
	End Method


	Method GetRentalContractByDetails:TRoomRentalContract(roomGUID:string, owner:int)
		For local c:TRoomRentalContract = Eachin rentalContracts
			if c.roomGUID = roomGUID and c.owner = owner then return c
		Next
		return null
	End Method
	endrem


 	Method UpdateEmptyRooms()
		For local r:TRoomBase = EachIn GetRoomBaseCollection().list
			'ignore non-rentable rooms
			if not r.IsRentable() then continue
			'we cannot give back empty rooms to players ... so only
			're-rent if it is originally owned by a non-player
			if r.originalOwner > 0 then continue
	

			'room empty for a long time?
			if r.rentalChangeTime + GameRules.roomReRentTime < GetWorldTime().GetTimeGone()
				'let original owner rent it
				r.BeginRental(0, r.GetRent())
				print "RoomHandler_RoomAgency.UpdateEmptyRooms(): re-rented. " + r.GetName() + "  " + r.GetDescription(1) 
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

		local rent:int = room.GetRent()

		'=== PAY COURTAGE ===
		if GetPlayerBaseCollection().IsPlayer(owner)
			local courtage:int = TFunctions.RoundToBeautifulValue(rent * 0.5) 
			if not GetPlayerFinance(owner).CanAfford(courtage)
				TLogger.Log("RoomHandler_RoomAgency.BeginRoomRental()", "Failed to rent room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner+". Not enough money to pay courtage.", LOG_DEBUG)
			else
				'pay a courtage
				GetPlayerFinance(owner).PayRent(courtage, room)
			endif
		endif

		'TODO: modify rent by sympathy
		'rent :* sympathyMod(owner)

		'=== RENT THE ROOM ===
		if room.BeginRental(owner, rent)
			rem
			'unused for now
			local contract:TRoomRentalContract = new TRoomRentalContract.Init(room.GetGUID(), owner, room.GetRent())
			AddRentalContract(contract)
			endrem
			
			TLogger.Log("RoomHandler_RoomAgency.BeginRoomRental()", "Rented room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner, LOG_DEBUG)
			return True
		else
			TLogger.Log("RoomHandler_RoomAgency.BeginRoomRental()", "Failed to rent room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner, LOG_DEBUG)
			return False
		endif
	End Function


	Function CancelRoomRental:int(room:TRoomBase, owner:int=0)
		if not room.IsRented() then return False

		local roomOwner:int = room.owner
		'fetch rent before cancelling!
		local roomRent:int = room.GetRent()

		if room.CancelRental()
			'have to pay a bit of rent for the already begun day?
			'1:  0- 6hrs = 25%
			'2:  7-12hrs = 50%
			'3: 13-18hrs = 75%
			'4: 19-24hrs = 100%
			local hourStep:int = floor(GetWorldTime().GetDayHour() / 6)+1
			local toPay:int = TFunctions.RoundToBeautifulValue(hourStep*0.25 * roomRent)

			if GetPlayerBaseCollection().IsPlayer(roomOwner)
				GetPlayerFinance(roomOwner).PayRent(toPay, room)
			Endif
			
			rem
			'unused for now (done already - see above)
			local contract:TRoomRentalContract = GetRentalContractByDetails(room.GetGUID(), roomOwner)
			if contract
				RemoveRentalContract(contract)
				print "removed contract"
			endif
			endrem

			TLogger.Log("RoomHandler_RoomAgency.BeginRoomRental()", "Cancelled rental of room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner+". Room owner "+roomOwner+" paid an outstanding rent of "+TFunctions.DottedValue(toPay)+".", LOG_DEBUG)
			return True
		else
			TLogger.Log("RoomHandler_RoomAgency.BeginRoomRental()", "Failed to cancel rental of room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner+" [roomOwner="+roomOwner+"]", LOG_DEBUG)
			return False
		endif
	End Function
End Type



rem
Type TRoomRentalContract extends TGameObject
	'which room
	Field roomGUID:string
	'what was agreed to as rent?
	Field rent:int
	'rented by?
	Field owner:int
	Field timeOfSign:Long
End Type
endrem