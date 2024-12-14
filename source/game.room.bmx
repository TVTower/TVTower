SuperStrict
Import "Dig/base.util.helper.bmx"
Import "common.misc.screen.bmx" 'screencollection
Import "game.room.base.bmx"
Import "game.player.base.bmx"
Import "game.figure.base.bmx"




Type TRoomCollection Extends TRoomBaseCollection

	Function GetInstance:TRoomCollection()
		if not _instance
			_instance = new TRoomCollection

		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		'==== ATTENTION =====
		'NEVER store _instance somewhere without paying attention
		'to this "whacky hack"
		elseif not TRoomCollection(_instance)
			local oldInstance:TRoomBaseCollection = _instance
			_instance = New TRoomCollection
			'now the new collection is the instance
			THelper.TakeOverObjectValues(oldInstance, _instance)
		endif
		return TRoomCollection(_instance)
	End Function


	Method Get:TRoom(ID:int)
		Return TRoom(Super.Get(ID))
	End Method


	Method GetRandom:TRoom()
		Return TRoom(Super.GetRandom())
	End Method


	Method GetByGUID:TRoom(LS_guid:TLowerString)
		Return TRoom(Super.GetByGUID(LS_guid))
	End Method


	'returns all room fitting to the given details
	Function GetAllByDetails:TRoom[]( name:String, nameRaw:string="", owner:Int=-1000, limit:int = 0 ) {_exposeToLua}
		local rooms:TRoomBase[] = Super.GetAllByDetails(name, nameRaw, owner, limit)
		local result:TRoom[]
		For Local room:TRoom = EachIn rooms
			result :+ [room]
		Next
		Return result
	End Function


	Function GetFirstByDetails:TRoom( name:String, nameRaw:string="", owner:Int=-1000 ) {_exposeToLua}
		return TRoom(Super.GetFirstByDetails(name, nameRaw, owner))
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetRoomCollection:TRoomCollection()
	Return TRoomCollection.GetInstance()
End Function




'container for data describing the room
'without data attached which is used for visual representation
'(tooltip, signs...) -> they are now in TRoomDoor
'usage examples:
' - RoomAgency
' - Multiple "Doors" to the same room
Type TRoom extends TRoomBase {_exposeToLua="selected"}
	Method New()
		'do not add the room automatically ... it might lead to
		'duplicates in the collection when loading games
		'GetRoomCollection().Add(self)
	End Method


	'init a room with basic variables
	Method Init:TRoom(name:String="unknown", description:String[], owner:int, size:int=1)
		Super.Init(name, description, owner, size)
		return self
	End Method


	'override
	'ask figures whether they allow other figures to enter
	Method HasOccupantDisallowingEnteringEntity:int(entity:TEntity)
		'ask all the occupying players whether they are not ok with
		'the entity
		for local f:TFigureBase = eachIn occupants
			if not f.IsAcceptingEntityInSameRoom(entity, self) then return True
		Next

		return False
	End Method


	'override
	'ask entities whether they allow other figures in the room
	Method HasEnteringEntityDisallowingOccupants:int(entity:TEntity)
		if not TFigureBase(entity) then return True

		'ask the entity/figure if it is not ok with the occupants
		for local occupant:TEntity = eachIn occupants
			if not TFigureBase(entity).IsAcceptingEntityInSameRoom(occupant, self) then return True
		Next
		return False
	End Method


	'override to add screen draw
	Method Draw:int()
		'if not self.screen then Throw "ERROR: room.draw() - screen missing";return 0
		'draw current screen
		'ScreenCollection.DrawCurrent(App.timer.getTween())
		'emit event so custom functions can run after screen draw, sender = screen
		TriggerBaseEvent(GameEventKeys.Room_OnScreenDraw, new TData.Add("room", self).Add("owner", self.owner) , ScreenCollection.GetCurrentScreen() )

		return Super.Draw()
	End Method


	'override to add screen update
	Method Update:Int()
		'emit event so custom functions can run after screen update, sender = screen
		'also this event has "room" as payload
		TriggerBaseEvent(GameEventKeys.Room_OnScreenUpdate, new TData.Add("room", self).Add("owner", self.owner) , ScreenCollection.GetCurrentScreen() )

		return Super.Update()
	End Method


	'override to actually kick figures
	Method KickOccupants:int(kickingEntity:TEntity = null)
		For local occupant:TFigureBase = EachIn occupants
			occupant.KickOutOfRoom(TFigureBase(kickingEntity))
		Next
	End Method


	Method GetOwnerPlayerName:string()
		If GetPlayerBaseCollection().IsPlayer(owner)
			Return GetPlayerBase(owner).name
		Endif
		Return "UNKNOWN PLAYER"
	End Method


	Method GetOwnerChannelName:string()
		If GetPlayerBaseCollection().IsPlayer(owner)
			Return GetPlayerBase(owner).channelName
		Endif
		Return "UNKNOWN CHANNEL"
	End Method


	'override
	Method GetDescriptionLocalized:TLocalizedString()
		local res:TLocalizedString = Super.GetDescriptionLocalized()
		res = res.Replace("%PLAYERNAME%", GetOwnerPlayerName())
		res = res.Replace("%CHANNELNAME%", GetOwnerChannelName())

		return res
	End Method


	'override to add playername/channelname replacement
	Method GetDescription:string(lineNumber:int=1, raw:int=False) {_exposeToLua}
		local res:String = Super.GetDescription(lineNumber, raw)
		if res.Find("%") = -1 then return res

		res = res.Replace("%PLAYERNAME%", GetOwnerPlayerName())
		res = res.Replace("%CHANNELNAME%", GetOwnerChannelName())

		return res
	End Method
End Type
