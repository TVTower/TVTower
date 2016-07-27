SuperStrict
Import "Dig/base.util.helper.bmx"
Import "common.misc.screen.bmx" 'screencollection
Import "game.room.base.bmx"
Import "game.player.base.bmx"




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


	Function Get:TRoom(ID:int)
		Return TRoom(Super.Get(ID))
	End Function


	Function GetRandom:TRoom()
		Return TRoom(Super.GetRandom())
	End Function


	'returns all room fitting to the given details
	Function GetAllByDetails:TRoom[]( name:String, owner:Int=-1000 ) {_exposeToLua}
		local rooms:TRoomBase[] = Super.GetAllByDetails(name, owner)
		local result:TRoom[]
		For Local room:TRoom = EachIn rooms
			result :+ [room]
		Next
		Return result
	End Function


	Function GetFirstByDetails:TRoom( name:String, owner:Int=-1000 ) {_exposeToLua}
		return TRoom(Super.GetFirstByDetails(name, owner))
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


	'override to add screen draw
	Method Draw:int()
		'if not self.screen then Throw "ERROR: room.draw() - screen missing";return 0
		'draw current screen
		'ScreenCollection.DrawCurrent(App.timer.getTween())
		'emit event so custom functions can run after screen draw, sender = screen
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenDraw", new TData.Add("room", self) , ScreenCollection.GetCurrentScreen() ) )

		return Super.Draw()
	End Method


	'override to add screen update
	Method Update:Int()
		'emit event so custom functions can run after screen update, sender = screen
		'also this event has "room" as payload
		EventManager.triggerEvent( TEventSimple.Create("room.onScreenUpdate", new TData.Add("room", self) , ScreenCollection.GetCurrentScreen() ) )

		return Super.Update()
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
	Method GetDescription:string(lineNumber:int=1) {_exposeToLua}
		local res:String = Super.GetDescription(lineNumber)
		if res.Find("%") = -1 then return res

		res = res.Replace("%PLAYERNAME%", GetOwnerPlayerName())
		res = res.Replace("%CHANNELNAME%", GetOwnerChannelName())

		return res
	End Method
End Type
