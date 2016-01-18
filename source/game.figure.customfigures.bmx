SuperStrict
Import "game.figure.bmx"
Import "game.modifier.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.player.programmecollection.bmx"
Import "game.player.programmeplan.bmx"


Type TFigurePostman Extends TFigure
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500, 0, 0, 5000)

	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigurePostman(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		Super.Create(FigureName, sprite, x, onFloor, speed)
		Return Self
	End Method


	'override to make the figure stay in the room for a random time
	Method FinishEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase)
		Super.FinishEnterRoom(room, door)

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

			'TLogger.Log("TFigurePostman", "nothing to do -> send to door of " + door.room.name, LOG_DEBUG | LOG_AI, True)
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
	Field currentAction:Int	= 0		'0=nothing,1=cleaning,...
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(2500,0, -500, 500) '500ms randomness
	Field nextActionTime:Int = 2500
	Field nextActionRandomTime:Int = 500
	Field useElevator:Int = True
	Field useDoors:Int = True
	Field BoredCleanChance:Int = 10
	Field NormalCleanChance:Int = 30
	Field MovementRangeMinX:Int	= 20
	Field MovementRangeMaxX:Int	= 420
	'how many seconds does the janitor wait at the elevator
	'until he goes to elsewhere
	Field WaitAtElevatorTimer:TIntervalTimer = TIntervalTimer.Create(20000)


	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigureJanitor(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		Super.Create(FigureName, sprite, x, onFloor, speed)
		area.dimension.setX(14)

		GetFrameAnimations().Set(TSpriteFrameAnimation.Create("cleanRight", [ [11,130], [12,130] ], -1, 0) )
		GetFrameAnimations().Set(TSpriteFrameAnimation.Create("cleanLeft", [ [13,130], [14,130] ], -1, 0) )

		Return Self
	End Method


	'override to make the figure stay in the room for a random time
	Method FinishEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase)
		Super.FinishEnterRoom(room, door)

		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	'overwrite original method
	Method getAnimationToUse:String()
		Local result:String = Super.getAnimationToUse()

		If currentAction = 1
			If result = "walkRight" Then result = "cleanRight" Else result="cleanLeft"
		EndIf
		Return result
	End Method


	'overwrite default to stop moving when cleaning
	Method GetVelocity:TVec2D()
		If currentAction = 1 Then Return New TVec2D
		Return velocity
	End Method


	Method UpdateCustom:Int()
		'waited to long - change target (returns false while in elevator)
		If hasToChangeFloor() And WaitAtElevatorTimer.isExpired()
			If ChangeTarget(Rand(MovementRangeMinX, MovementRangeMaxX), GetBuildingBase().GetFloorY2(GetFloor()))
				WaitAtElevatorTimer.Reset()
			EndIf
		EndIf

		'waited long enough in room ... go out
		If inRoom And nextActionTimer.isExpired()
			LeaveRoom()
		EndIf

		'reached target - and time to do something
		If IsIdling() And nextActionTimer.isExpired()
			If Not hasToChangeFloor()

				'reset is done later - we want to catch isExpired there too
				'nextActionTimer.Reset()

				Local zufall:Int = Rand(0, 100)	'what to do?
				Local zufallx:Int = 0			'where to go?

				'move to a spot further away than just some pixels
				Repeat
					zufallx = Rand(MovementRangeMinX, MovementRangeMaxX)
				Until Abs(area.GetX() - zufallx) > 75

				'move to a different floor (only if doing nothing special)
				If useElevator And currentAction=0 And zufall > 80 And Not IsAtElevator()
					Local sendToFloor:Int = GetFloor() + 1
					If sendToFloor > 13 Then sendToFloor = 0
					ChangeTarget(zufallx, GetBuildingBase().GetFloorY2(sendToFloor))
					WaitAtElevatorTimer.Reset()
				'move to a different X on same floor - if not cleaning now
				Else If currentAction=0
					ChangeTarget(zufallx, GetBuildingBase().GetFloorY2(GetFloor()))
				EndIf
			EndIf

		EndIf

		If Not inRoom And nextActionTimer.isExpired() And Not hasToChangeFloor()
			nextActionTimer.SetRandomness(-nextActionRandomTime / TEntity.globalWorldSpeedFactor, nextActionRandomTime * TEntity.globalWorldSpeedFactor)
			nextActionTimer.SetInterval(nextActionTime / TEntity.globalWorldSpeedFactor)
			nextActionTimer.Reset()

			
			currentAction = 0

			'chose actions
			'- only if not outside the building
			If area.position.GetX() > GetBuildingBase().leftWallX
				'only clean with a chance of 30% when on the way to something
				'and do not clean if target is a room near figure
				Local targetDoor:TRoomDoor = TRoomDoor(GetTarget())
				If GetTarget() And (Not targetDoor Or (20 < Abs(targetDoor.GetScreenX() - area.GetX()) Or targetDoor.GetOnFloor() <> GetFloor()))
					If Rand(0,100) < NormalCleanChance Then currentAction = 1
				EndIf
				'if just standing around give a chance to clean
				If Not GetTarget() And Rand(0,100) < BoredCleanChance Then currentAction = 1
			EndIf
		EndIf

		If GetTarget()
			If Not useDoors And TRoomDoor(GetTarget()) Then RemoveCurrentTarget()
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
	'time to wait between doing something
	Field nextActionTimer:TIntervalTimer = TIntervalTimer.Create(1500, 0, 0, 5000)


	'we need to overwrite it to have a custom type - with custom update routine
	Method Create:TFigureDeliveryBoy(FigureName:String, sprite:TSprite, x:Int, onFloor:Int = 13, speed:Int)
		Super.Create(FigureName, sprite, x, onFloor, speed)
		Return Self
	End Method


	'used in news effect function
	Function SendFigureToRoom(source:TGameModifierBase, params:TData)
		Local figure:TFigureDeliveryBoy = TFigureDeliveryBoy(source.GetData().Get("figure"))
		Local room:TRoomBase = TRoomBase(source.GetData().Get("room"))
		If Not figure Or Not room Then Return

		figure.SetDeliverToRoom(room)
	End Function


	'override to make the figure stay in the room for a random time
	Method FinishEnterRoom:Int(room:TRoomBase, door:TRoomDoorBase)
		Super.FinishEnterRoom(room, door)

		'figure now knows where to "deliver"
		If Not checkedRoomboard Then checkedRoomboard = True
		'figure entered the intended room -> delivery is finished
		If room = deliverToRoom Then deliveryDone = True
			
		'reset timer so figure stays in room for some time
		nextActionTimer.Reset()
	End Method


	'set the room the figure should go to.
	'DeliveryBoys do not know where the room will be, so they
	'go to the roomboard first
	Method SetDeliverToRoom:Int(room:TRoomBase)
		'to go to this room, we have to first visit the roomboard
		checkedRoomboard = False
		deliveryDone = False
		deliverToRoom = room
		intentedDeliverToRoom = room
	End Method


	Method HasToDeliver:Int() {_exposeToLua}
		Return Not deliveryDone
	End Method


	Method UpdateCustom:Int()
		'nothing to do - move to offscreen (leave building)
		If Not deliverToRoom And Not GetTarget()
			If Not IsOffScreen() Then SendToOffscreen()
		EndIf

		'figure is in building and without target waiting for orders
		If Not deliveryDone And IsIdling()
			'before directly going to a room, ask the roomboard where
			'to go
			If Not checkedRoomboard
				TLogger.Log("TFigureDeliveryBoy", Self.name+" is sent to roomboard", LOG_DEBUG | LOG_AI, True)
				SendToDoor(TRoomDoor.GetByDetails("roomboard", 0))
			Else
				'instead of sending the figure to the correct door, we
				'ask the roomsigns where to go to
				'1) search for a sign to the room
				Local roomSign:TRoomBoardSign = GetRoomBoard().GetFirstSignByRoom(deliverToRoom.id)
				'2) get sign which was originally at the same position
				'   as the sign we just found
				Local sign:TRoomBoardSign
				If roomSign
					sign = GetRoomBoard().GetSignByOriginalXY( roomSign.rect.GetX(), roomSign.rect.GetY() )
				endif

				If sign And sign.door
					intentedDeliverToRoom = deliverToRoom
					deliverToRoom = TRoomDoor(sign.door).GetRoom()
					local deliverText:string = deliverToRoom.name
					local intendedText:string = intentedDeliverToRoom.name
					if deliverToRoom.owner then deliverText :+ " #"+deliverToRoom.owner
					if intentedDeliverToRoom.owner then intendedText :+ " #"+intentedDeliverToRoom.owner

					TLogger.Log("TFigureDeliveryBoy", Self.name+" is sent to room "+deliverText+" (intended room: "+intendedText+")", LOG_DEBUG | LOG_AI, True)

					SendToDoor(sign.door)
				Else
					TLogger.Log("TFigureDeliveryBoy", Self.name+" cannot send to a room, sign of target over empty room slot (intended room: "+deliverToRoom.name+")", LOG_DEBUG | LOG_AI, True)
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
End Type



'person who confiscates licences/programmes
Type TFigureMarshal Extends TFigureDeliveryBoy
	'arrays containing information of GUID->owner (so it stores the
	'owner of the licence in the moment of the task creation)
	Field confiscateProgammeLicenceGUID:String[]
	Field confiscateProgammeLicenceFromOwner:Int[]

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
		SetDeliverToRoom(GetRoomCollection().GetFirstByDetails("archive", GetConfiscateProgrammeLicenceFromOwner()))
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

		If Not GetPlayerBaseCollection().isPlayer(roomOwner)
			'block room for x hours - like terror attack ?
		Else
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
			EventManager.triggerEvent( TEventSimple.Create("publicAuthorities.onConfiscateProgrammeLicence", New TData.AddString("targetProgrammeGUID", GetConfiscateProgrammeLicenceGUID() ).AddString("confiscatedProgrammeGUID", licence.GetGUID()), Null, GetPlayerBase(roomOwner)) )

			'switch used sprite - we confiscated something
			sprite = GetSpriteFromRegistry(GetBaseSpriteName()+".box")
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
End Type