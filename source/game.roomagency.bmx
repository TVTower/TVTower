SuperStrict
Import Brl.LinkedList
Import "game.gamerules.bmx"
Import "game.player.base.bmx"
Import "game.player.finance.bmx"
Import "game.room.base.bmx"
Import "basefunctions.bmx"




Type TRoomAgency
	'TODO:
	'- sympathy for channels
	'- gain/loose when sending certain programme genres
	'- assign random genres on each game start
	'- make genres "visible" via dialogue ?


	Global _eventListeners:TLink[]
	Global _instance:TRoomAgency


	Function GetInstance:TRoomAgency()
		if not _instance then _instance = new TRoomAgency
		return _instance
	End Function


	Method Initialize:int()
		'=== REGISTER EVENTS ===
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'react to bombs, marshals, ...
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onBombExplosion", onRoomBombExplosion) ]

	End Method


	Function onRoomBombExplosion:int( triggerEvent:TEventBase )
		local room:TRoomBase = TRoomBase(triggerEvent.GetSender())

		if room.IsRented() and room.IsUsableAsStudio() and room.GetOwner() <= 0
			GetInstance().CancelRoomRental(room)
			room.SetUsedAsStudio(False)
		endif
	End Function


 	Method UpdateEmptyRooms()
		For local r:TRoomBase = EachIn GetRoomBaseCollection().list
			'ignore non-rentable rooms
			if not r.IsRentable() then continue
			'we cannot give back empty rooms to players ... so only
			're-rent if it is originally owned by a non-player
			if r.originalOwner > 0 then continue


			'room empty for a long time?
			if r.GetRerentalTime() < GetWorldTime().GetTimeGone()
				'let original owner rent it
				r.BeginRental(0, r.GetRent())
				'print "RoomAgency.UpdateEmptyRooms(): re-rented. " + r.GetName() + "  " + r.GetDescription(1)
			endif
		Next
	End Method


	Method GetTotalRent:int(playerID:int)
		local result:int = 0
		For local r:TRoomBase = EachIn GetRoomBaseCollection().list
			if r.GetOwner() <> playerID then continue

			result :+ r.GetRent()
		Next
	End Method


	Method GetCourtage:int(room:TRoomBase)
		if not room then return 0

		local rent:int = room.GetRent()
		'TODO: add owner-sympathy / mood
		return TFunctions.RoundToBeautifulValue(rent * 3)
	End Method


	'get the owner-specific courtage
	Method GetCourtageForOwner:int(room:TRoomBase, forOwner:int=0)
		local courtage:int = GetCourtage(room)
		'incorporate difficulty
		 courtage :* GetPlayerDifficulty(string(forOwner)).roomRentMod

		'TODO: add owner-sympathy / mood

		return courtage
	End Method


	Method BeginRoomRental:int(room:TRoomBase, owner:int=0)
		if room.IsRented() then return False

		local rent:int = room.GetRent()

		'=== PAY COURTAGE ===
		if GetPlayerBaseCollection().IsPlayer(owner)
			local courtage:int = GetCourtageForOwner(room, owner)
			if not GetPlayerFinance(owner).CanAfford(courtage)
				TLogger.Log("RoomAgency.BeginRoomRental()", "Failed to rent room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner+". Not enough money to pay courtage.", LOG_DEBUG)
				return False
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

			TLogger.Log("RoomAgency.BeginRoomRental()", "Rented room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner, LOG_DEBUG)
			return True
		else
			TLogger.Log("RoomAgency.BeginRoomRental()", "Failed to rent room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner, LOG_DEBUG)
			return False
		endif
	End Method


	Method CancelRoomRentalsOfPlayer:int(owner:int)
		For local r:TRoomBase = EachIn GetRoomBaseCollection().list
			if r.GetOwner() <> owner then continue
			if r.IsFreehold() then continue

			CancelRoomRental(r, owner)
		Next
	End Method


	Method CancelRoomRental:int(room:TRoomBase, owner:int=0)
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

			TLogger.Log("RoomAgency.BeginRoomRental()", "Cancelled rental of room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner+". Room owner "+roomOwner+" paid an outstanding rent of "+TFunctions.DottedValue(toPay)+".", LOG_DEBUG)
			return True
		else
			TLogger.Log("RoomAgency.BeginRoomRental()", "Failed to cancel rental of room ~q"+room.GetDescription()+" ["+room.GetName()+"] by owner="+owner+" [roomOwner="+roomOwner+"]", LOG_DEBUG)
			return False
		endif
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return singleton instance
Function GetRoomAgency:TRoomAgency()
	Return TRoomAgency.GetInstance()
End Function