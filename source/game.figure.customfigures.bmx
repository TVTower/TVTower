SuperStrict
Import "game.figure.bmx"
Import "game.modifier.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.player.programmecollection.bmx"
Import "game.player.programmeplan.bmx"


Type TFigurePostman Extends TFigure
	Field nextActionInterval:int = 7500
	Field nextActionTimer:TBuildingIntervalTimer = new TBuildingIntervalTimer.Init(5000, 0, 0, 5000)

	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigurePostman(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		Super.Create(FigureName, sprite, x, onFloor, speed)
		Return Self
	End Method


	'override to make the figure stay in the room for a random time
	'ATTENTION: use BeginEnterRoom instead of FinishEnterRoom()
	'           to avoid "resets" while Entering
	Method BeginEnterRoom:int(door:TRoomDoorBase, room:TRoomBase)
		Super.BeginEnterRoom(door, room)

		if room and room.GetOwner() <= 0 'and not room.IsFreehold()
			'wait a bit longer in "studio rooms"
			nextActionTimer.SetInterval(nextActionInterval + RandRange(2500, 7500))
		else
			nextActionTimer.SetInterval(nextActionInterval)
		endif

		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	Method UpdateCustom:Int()
		'figure is in building and without target waiting for orders
		If IsIdling()
			Local door:TRoomDoorBase
			'search for a visible door
			Repeat
				door = GetRoomDoorBaseCollection().GetRandom()
			Until door.doorType > 0

			'TLogger.Log("TFigurePostman", "nothing to do -> send to door of " + door.roomID, LOG_DEBUG | LOG_AI, True)
			SendToDoor(door)
		EndIf

		If inRoom And nextActionTimer.isExpired()
			nextActionTimer.Reset()
			'switch "with" and "without" letter
			If sprite.name = "BotePost"
				sprite = GetSpriteFromRegistry("BoteLeer")
			Else
				sprite = GetSpriteFromRegistry("BotePost")
			EndIf

			'leave that room so we can find a new target
			leaveRoom()
		EndIf
	End Method
End Type


Type TFigureJanitor Extends TFigure
	Field currentJanitorAction:Int = 0		'0=nothing,1=cleaning,...
	Field nextActionTimer:TBuildingIntervalTimer = new TBuildingIntervalTimer.Init(7500,0, -1000, 1500)
	Field nextActionTime:Int = 2500
	Field nextActionRandomTime:Int = 500
	Field useElevator:Int = True
	Field useDoors:Int = True
	Field BoredCleanChance:Int = 10
	Field NormalCleanChance:Int = 30
	Field MovementRangeMinX:Int	= 20
	Field MovementRangeMaxX:Int	= 420
	Field LastRoomBoardSignResetDay:Int = 0 {nosave}
	'how many seconds does the janitor waits at the elevator
	'until he goes to elsewhere
	Field WaitAtElevatorTimer:TBuildingIntervalTimer = new TBuildingIntervalTimer.Init(35000, 0, -10000, 10000)


	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigureJanitor(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		Super.Create(FigureName, sprite, x, onFloor, speed)
		area.SetW(14)

		GetFrameAnimations().Add(new TSpriteFrameAnimation("cleanRight", [ [11,130], [12,130] ], -1, 0) )
		GetFrameAnimations().Add(new TSpriteFrameAnimation("cleanLeft", [ [13,130], [14,130] ], -1, 0) )

		Return Self
	End Method


	'override to make the figure stay in the room for a random time
	'ATTENTION: use BeginEnterRoom instead of FinishEnterRoom()
	'           to avoid "resets" while Entering
	Method BeginEnterRoom:int(door:TRoomDoorBase, room:TRoomBase)
		Super.BeginEnterRoom(door, room)

		'janitor resets signs once a day (and after a detonation)
		'print "janitor visiting " + room.GetNameRaw()
		If room And room.GetNameRaw() = "roomboard"
			Local daysRun:Int = GetWorldTime().GetDaysRun()
			If daysRun > LastRoomBoardSignResetDay
				'print "janitor resetting board positions"
				GetRoomBoard().ResetPositions()
				LastRoomBoardSignResetDay = daysRun
			EndIf
		EndIf

		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	'overwrite original method
	Method getAnimationToUse:String()
		Local result:String = Super.getAnimationToUse()

		If currentJanitorAction = 1
			If result = "walkRight" Then result = "cleanRight" Else result="cleanLeft"
		EndIf
		Return result
	End Method


	'override default to stop moving when cleaning
	Method GetVelocity:SVec2F() override
		If currentJanitorAction = 1 Then Return New SVec2F(0,0)
		Return New SVec2F(velocity.x, velocity.y)
	End Method


	Method onReachElevator:int()
		WaitAtElevatorTimer.Reset()
		nextActionTimer.isExpired()
	End Method


	Method UpdateCustom:Int()
		'waited to long - change target (returns false while in elevator)
		If hasToChangeFloor() And IsAtElevator() And WaitAtElevatorTimer.isExpired()
			If ChangeTarget(RandRange(MovementRangeMinX, MovementRangeMaxX), GetBuildingBase().GetFloorY2(GetFloor()))
				WaitAtElevatorTimer.Reset()
			EndIf
		EndIf

		'waited long enough in room ... go out
		If inRoom and not IsChangingRoom() And nextActionTimer.isExpired()
			LeaveRoom()
		EndIf

		'reached target - and time to do something
		If IsIdling() And nextActionTimer.isExpired()
			If Not hasToChangeFloor()
				'what to do?
				Local randomAction:Int = RandRange(0, 100)
				'where to go?
				Local randomX:Int = 0

				'move to a spot further away than just some pixels
				Repeat
					randomX = RandRange(MovementRangeMinX, MovementRangeMaxX)
				Until Abs(area.GetX() - randomX) > 75

				'move to a different floor (only if doing nothing special)
				If useElevator And currentJanitorAction = 0 And randomAction > 80 And Not IsAtElevator()
					Local sendToFloor:Int = GetFloor() + 1
					If sendToFloor > 13
						sendToFloor = 0
						randomX = MovementRangeMaxX 'increase chance of visiting roomboard
					EndIf
					ChangeTarget(randomX, GetBuildingBase().GetFloorY2(sendToFloor))
				'move to a different X on same floor - if not cleaning now
				ElseIf currentJanitorAction = 0
					ChangeTarget(randomX, GetBuildingBase().GetFloorY2(GetFloor()))
				EndIf
			EndIf

		EndIf

		If Not inRoom And nextActionTimer.isExpired() And Not hasToChangeFloor()
			nextActionTimer.SetRandomness(-nextActionRandomTime, nextActionRandomTime)
			nextActionTimer.SetInterval(nextActionTime)
			nextActionTimer.Reset()

			currentJanitorAction = 0

			'chose actions
			'- only if not outside the building
			If area.x > GetBuildingBase().leftWallX
				'only clean with a chance of 30% when on the way to something
				'and do not clean if target is a room near figure
				Local targetDoor:TRoomDoor = TRoomDoor(GetTargetObject())
				If GetTarget() And (Not targetDoor Or (20 < Abs(targetDoor.GetScreenX() - area.x) Or targetDoor.GetOnFloor() <> GetFloor()))
					If RandRange(0,100) < NormalCleanChance Then currentJanitorAction = 1
				EndIf
				'if just standing around give a chance to clean
				If Not GetTarget() And RandRange(0,100) < BoredCleanChance Then currentJanitorAction = 1
			EndIf
		EndIf

		If GetTarget()
			If Not useDoors And TRoomDoor(GetTargetObject()) Then FinishCurrentTarget()
		EndIf
	End Method
End Type


'base figure type for figures coming from outside the building looking
'for a room at the roomboard etc.
Type TFigureDeliveryBoy Extends TFigure
	'did the figure check the roomboard where to go to?
	Field checkedRoomboard:Int = False
	'the room the figure delivers to (after checking the roomboard)
	Field deliverToRoom:TRoomBase
	'the room the figure intends to deliver to
	Field intentedDeliverToRoom:TRoomBase
	'was the "package" delivered already?
	Field deliveryDone:Int = True
	Field enterRoomTryCount:int = 0
	'-1 to disable any limit and wait forever
	Field enterRoomTryCountMax:int = 3
	'time to wait for another try to visit a room
	Field enterRoomTryTimer:TBuildingIntervalTimer = new TBuildingIntervalTimer.Init(5000, 0, 0, 2500)
	'time to wait between doing something
	Field nextActionTimer:TBuildingIntervalTimer = new TBuildingIntervalTimer.Init(7500, 0, 0, 5000)

	Field scheduledDeliverRooms:TRoomBase[]
	Field scheduledDeliverTime:Long[]

	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigureDeliveryBoy(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		Super.Create(FigureName, sprite, x, onFloor, speed)
		Return Self
	End Method


	'used in news effect function
	Function SendFigureToRoom:int(source:TGameModifierBase, params:TData)
		Local figure:TFigureDeliveryBoy = TFigureDeliveryBoy(source.GetData().Get("figure"))
		Local room:TRoomBase = TRoomBase(source.GetData().Get("room"))
		If Not figure Or Not room Then Return False


		'-1 = deliver as soon as possible
		local scheduledTime:Long = -1
		if params and params.GetInt("delayTime") > 0
			scheduledTime = GetWorldTime().GetTimeGone() + params.GetInt("delayTime")
		endif
		'print "AddDeliverToRoom "
		'Var 1) let the figure finish other scheduled deliveries first
		figure.AddDeliverToRoom(room, scheduledTime)
		'Var 2) send direct?
		'figure.SetDeliverToRoom(room)


		return True
	End Function


	Method AddDeliverToRoom:int(room:TRoomBase, deliverTime:Long = -1)
		scheduledDeliverRooms :+ [room]
		scheduledDeliverTime :+ [deliverTime]
	End Method


	'override to make the figure stay in the room for a random time
	'ATTENTION: use BeginEnterRoom instead of FinishEnterRoom()
	'           to avoid "resets" while Entering
	Method BeginEnterRoom:int(door:TRoomDoorBase, room:TRoomBase)
		Super.BeginEnterRoom(door, room)

		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	'only set checkedRoomboard/delivery if we succesfully entered a room
	Method FinishEnterRoom:int()
		Super.FinishEnterRoom()

		'figure entered the intended room -> delivery is finished
		If inRoom = deliverToRoom Then deliveryDone = True

		enterRoomTryCount = 0
		enterRoomTryTimer.Reset()

		'figure now knows where to "deliver"
		If Not checkedRoomboard Then checkedRoomboard = True
	End Method


	'set the room the figure should go to.
	'DeliveryBoys do not know where the room will be, so they
	'go to the roomboard first
	Method SetDeliverToRoom:Int(room:TRoomBase, replaceExistingDeliveryTarget:int = False)
		'delay current delivery target by adding it back to the schedule
		if deliverToRoom and not replaceExistingDeliveryTarget
			scheduledDeliverRooms = [deliverToRoom] + scheduledDeliverRooms
			scheduledDeliverTime = [-1:Long] + scheduledDeliverTime
		endif

		'to go to this room, we have to first visit the roomboard
		checkedRoomboard = False
		deliveryDone = False
		deliverToRoom = room
		intentedDeliverToRoom = room

		enterRoomTryCount = 0
		enterRoomTryTimer.Reset()
	End Method


	Method HasToDeliver:Int() {_exposeToLua}
		Return Not deliveryDone
	End Method


	'override to react to it
	Method FailEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase, reason:String)
		local result:int = Super.FailEnterRoom(room, door, reason:String)

		if reason = "locked"
			'send home again
			TLogger.Log("TFigureDeliveryBoy", "Delivery failed: room locked. " + Self.name+" is returning back home.", LOG_DEBUG | LOG_AI, True)
			deliveryDone = True
			SendToOffscreen()
			return result
		endif

		if reason = "blocked"
			'stop waiting if the room is blocked for too long
			if room.blockedUntil - GetWorldTime().GetTimeGone() > 600 * TWorldTime.SECONDLENGTH
				TLogger.Log("TFigureDeliveryBoy", "Delivery failed: room blocked for longer than 600s. " + Self.name+" is returning back home.", LOG_DEBUG | LOG_AI, True)
				deliveryDone = True
				SendToOffscreen()
				return result
			endif

			'else we will wait
		endif

		'in use? wait a bit
		enterRoomTryCount :+ 1
		enterRoomTryTimer.Reset()

		return result
	End Method


	Method UpdateCustom:Int()
		'nothing to do - move to offscreen (leave building)
		'or set next target if already offscreen
		If Not deliverToRoom And Not GetTarget()
			If Not IsOffScreen() Then SendToOffscreen()

			'find the next target
			if scheduledDeliverRooms.length > 0 and scheduledDeliverTime.length > 0
				if scheduledDeliverTime[0] < GetWorldTime().GetTimeGone()
					TLogger.Log("TFigureDeliveryBoy", Self.name+" delivers to next scheduled room: " + scheduledDeliverRooms[0].name +".", LOG_DEBUG | LOG_AI, True)
					SetDeliverToRoom( scheduledDeliverRooms[0] )
					scheduledDeliverRooms = scheduledDeliverRooms[1..]
					scheduledDeliverTime = scheduledDeliverTime[1..]
				endif
			endif
		EndIf


		'figure is in building and without target waiting for orders
		If Not deliveryDone And IsIdling()

			if enterRoomTryCount > 0 and enterRoomTryCountMax > 0 and enterRoomTryCount > enterRoomTryCountMax
				TLogger.Log("TFigureDeliveryBoy", Self.name+" cannot enter a room, Aborting the job, going home.", LOG_DEBUG | LOG_AI, True)
				'send home again
				deliveryDone = True
				SendToOffscreen()
			endif


			'before directly going to a room, ask the roomboard where
			'to go
			If Not checkedRoomboard 'and IsIdling()
				if enterRoomTryCount = 0
					TLogger.Log("TFigureDeliveryBoy", Self.name+" is sent to roomboard", LOG_DEBUG | LOG_AI, True)
					SendToDoor(GetRoomDoorBasecollection().GetFirstByDetails("roomboard", 0))
				elseif enterRoomTryTimer.isExpired() and not IsWaitingToEnter()
					TLogger.Log("TFigureDeliveryBoy", Self.name+" is trying again to enter roomboard", LOG_DEBUG | LOG_AI, True)
					SendToDoor(GetRoomDoorBasecollection().GetFirstByDetails("roomboard", 0))
					'enterRoomTryTimer.Reset()
				endif
			'checkedRoomboard is set when entering the first room (board)
			Else
				'instead of sending the figure to the correct door, we
				'ask the roomsigns where to go to
				'1) search for a sign to the room
				Local roomSign:TRoomBoardSign = GetRoomBoard().GetFirstSignByRoom(deliverToRoom.id)
				'2) get sign which was originally at the same position
				'   as the sign we just found
				Local sign:TRoomBoardSign
				If roomSign
					sign = GetRoomBoard().GetSignByOriginalXY( int(roomSign.rect.GetX()), int(roomSign.rect.GetY()) )
				endif

				If sign And sign.door
					intentedDeliverToRoom = deliverToRoom
					deliverToRoom = TRoomDoor(sign.door).GetRoom()
					local deliverText:string = deliverToRoom.GetName()
					local intendedText:string = intentedDeliverToRoom.GetName()
					if deliverToRoom.owner then deliverText :+ " #"+deliverToRoom.owner
					if intentedDeliverToRoom.owner then intendedText :+ " #"+intentedDeliverToRoom.owner

					TLogger.Log("TFigureDeliveryBoy", Self.name+" is sent to room "+deliverText+" (intended room: "+intendedText+")", LOG_DEBUG | LOG_AI, True)

					SendToDoor(sign.door)
				Else
					TLogger.Log("TFigureDeliveryBoy", Self.name+" cannot send to a room, sign of target over empty room slot (intended room: "+deliverToRoom.GetName()+")", LOG_DEBUG | LOG_AI, True)
					'send home again
					deliveryDone = True
					SendToOffscreen()
				EndIf
			EndIf
		EndIf

		If inRoom And nextActionTimer.isExpired()
			nextActionTimer.Reset()

			'delivery finished - send home again
			If deliveryDone
				FinishDelivery()

				deliverToRoom = Null
				intentedDeliverToRoom = Null
			EndIf

			'leave that room so we can find a new target
			leaveRoom()
		EndIf
	End Method


	Method FinishDelivery:Int()
		'nothing
	End Method
End Type



Type TFigureTerrorist Extends TFigureDeliveryBoy

	Method New()
		nextActionTimer.Init(1500, 0, 0, 5000)

		'really wait a bit longer than normal delivery boys
		enterRoomTryCountMax:int = 15
	End Method


	'override to place a bomb when delivered
	Method FinishDelivery:Int()
		'place bomb
		deliverToRoom.PlaceBomb()

		SendToOffscreen()
	End Method


	'override: terrorist do like nobody
	Method GetGreetingTypeForFigure:Int(figure:TFigure)
		'0 = grrLeft
		'1 = hiLeft
		'2 = ?!left

		'depending on floor use "grr" or "?!"
		Return 0 + 2*((1 + GetBuildingBase().GetFloor(area.GetY()) Mod 2)-1)
	End Method


	'override
	'do not accept others, once the terrorist is in a room
	'so behave "normal" if asked from outside of a room regarding
	'persons in the room
	Method IsAcceptingEntityInSameRoom:int(entity:TEntity, room:object)
		if not GetInRoom()
			local r:TRoomBase = TRoomBase(room)
			'if going into a fake room (eg. "room board") just accept it
			'so the terrorist cannot get blocked by others
			if r and r.HasFlag(TVTRoomFlag.FAKE_ROOM) then return true

			return Super.IsAcceptingEntityInSameRoom(entity, room)
		endif

		'when in a room, we do no longer accept others to join (we
		'want to place a bomb...)
		return False
	End Method
End Type



'person who confiscates licences/programmes
Type TFigureMarshal Extends TFigureDeliveryBoy
	'arrays containing information of GUID->owner (so it stores the
	'owner of the licence in the moment of the task creation)
	Field confiscateProgammeLicenceGUID:String[]
	Field confiscateProgammeLicenceFromOwner:Int[]


	Method New()
		'really wait a bit longer than normal delivery boys
		enterRoomTryCountMax:int = 15
	End Method


	'used in news effect function
	Function CreateConfiscationJob(data:TData, params:TData)
		Local figure:TFigureMarshal = TFigureMarshal(data.Get("figure"))
		Local licenceGUID:String = data.GetString("confiscateProgrammeLicenceGUID")
		If Not figure Or Not licenceGUID Then Return

		figure.AddConfiscationJob(licenceGUID)
	End Function


	Method AddConfiscationJob:Int(confiscateGUID:String, owner:Int=-1)
		Local licence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(confiscateGUID)
		'if licence belongs to series/collection - confiscate the whole thing
		if licence.parentLicenceGUID
			licence = GetProgrammeLicenceCollection().GetByGUID(licence.parentLicenceGUID)
		endif

		'no valid licence found
		If Not licence
			TLogger.Log("AddConfiscationJob()", "invalid licence " + confiscateGUID, LOG_DEBUG)
			Return False
		EndIf

		If owner = -1 Then owner = licence.owner
		'only confiscate from players ?
		If Not GetPlayerBaseCollection().isPlayer(owner) Then Return False

		confiscateProgammeLicenceGUID :+ [licence.GetGUID()]
		confiscateProgammeLicenceFromOwner :+ [owner]
		Return True
	End Method


	Method StartNextConfiscationJob:Int()
		If Not HasNextConfiscationJob() Then Return False

		'remove invalid jobs (eg after loading a savegame)
		If GetConfiscateProgrammeLicenceGUID() = ""
			RemoveCurrentConfiscationJob()
			Return False
		EndIf

		'when confiscating programmes: start with your authorization
		'letter
		sprite = GetSpriteFromRegistry(GetBaseSpriteName()+".letter")

		'send figure to the archive of the stored owner
		SetDeliverToRoom(GetRoomCollection().GetFirstByDetails("archive", "", GetConfiscateProgrammeLicenceFromOwner()))
	End Method


	Method HasNextConfiscationJob:Int()
		Return confiscateProgammeLicenceFromOwner.length > 0
	End Method


	Method RemoveCurrentConfiscationJob()
		confiscateProgammeLicenceGUID = confiscateProgammeLicenceGUID[1..]
		confiscateProgammeLicenceFromOwner = confiscateProgammeLicenceFromOwner[1..]
	End Method


	Method GetConfiscateProgrammeLicenceGUID:String()
		If confiscateProgammeLicenceGUID.length = 0 Then Return ""
		Return confiscateProgammeLicenceGUID[0]
	End Method


	Method GetConfiscateProgrammeLicenceFromOwner:Int()
		If confiscateProgammeLicenceFromOwner.length = 0 Then Return -1
		Return confiscateProgammeLicenceFromOwner[0]
	End Method


	Method GetBaseSpriteName:String()
		Local dotPosition:Int = sprite.GetName().Find(".")
		If dotPosition > 0
			Return Left(sprite.GetName(), dotPosition)
		Else
			Return sprite.GetName()
		EndIf
	End Method


	'override to try to fetch the programme they should confiscate
	Method FinishDelivery:Int()
		'try to get the licence from the owner of the room we are now in
		Local roomOwner:Int = -1
		If inRoom Then roomOwner = inRoom.owner

		'when entering an archive, confiscate a licence
		If inRoom And inRoom.name = "archive" And GetPlayerBaseCollection().isPlayer(roomOwner)
			local pc:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(roomOwner)
			'try to get the licence from the player - if that player does
			'not own the licence (eg. someone switched roomSigns), take
			'a random one ... :p
			Local licence:TProgrammeLicence = pc.GetProgrammeLicenceByGUID( GetConfiscateProgrammeLicenceGUID() )
			rem
			if not licence
				print "finish2 - no licence " + GetConfiscateProgrammeLicenceGUID()
			else
				print "finish2 - " + licence.GetTitle()
			endif
			endrem
			If Not licence Then licence = pc.GetRandomProgrammeLicence()

			'hmm player does not have programme licences at all...skip
			'removal in that case
			If Not licence Then Return False

			pc.RemoveProgrammeLicence(licence)
			GetPlayerProgrammePlan(roomOwner).RemoveProgrammeInstancesByLicence(licence, True)

			'inform others - including taken and originally intended
			'licence (so we see if the right one was took ... to inform
			'players correctly)
			TriggerBaseEvent(GameEventKeys.PublicAuthorities_OnConfiscateProgrammeLicence, New TData.AddString("targetProgrammeGUID", GetConfiscateProgrammeLicenceGUID() ).AddString("confiscatedProgrammeGUID", licence.GetGUID()), Null, GetPlayerBase(roomOwner))

			'switch used sprite - we confiscated something
			sprite = GetSpriteFromRegistry(GetBaseSpriteName()+".box")
		EndIf

		'always block room
		If inRoom
			inRoom.SetBlocked(RandRange(120,240)*TWorldTime.MINUTELENGTH ,TRoomBase.BLOCKEDSTATE_MARSHAL)
		EndIf

		'remove the current job, we are done with it
		RemoveCurrentConfiscationJob()

		'send to offscreen again when finished
		SendToOffscreen()
	End Method


	Method UpdateCustom:Int()
		'try to start another job when doing nothing
		If isOffscreen() And IsIdling() Then StartNextConfiscationJob()

		Super.UpdateCustom()
	End Method


	'override
	'do not accept others, once the marshal is in a room
	'so behave "normal" if asked from outside of a room regarding
	'persons in the room
	Method IsAcceptingEntityInSameRoom:int(entity:TEntity, room:object)
		if not GetInRoom()
			'does not like to use things like the room board while others
			'are using it too (or talking to the porter)
			local r:TRoomBase = TRoomBase(room)
			if r and r.HasFlag(TVTRoomFlag.FAKE_ROOM) then return False

			return Super.IsAcceptingEntityInSameRoom(entity, room)
		endif

		'when in a room, we do no longer accept others to join (eg. we
		'are confiscating something and do not want to have that put into
		'a suitcase before ...)
		return False
	End Method
End Type