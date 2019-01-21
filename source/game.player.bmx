SuperStrict
Import "game.player.programmeplan.bmx"
'Import "game.broadcast.audienceresult.bmx"
'Import "game.publicimage.bmx"
Import "game.figure.bmx"
Import "game.building.bmx"
Import "game.newsagency.bmx"
Import "game.player.boss.bmx"


Type TPlayerCollection extends TPlayerBaseCollection
	Global _eventListeners:TLink[]
	Global _registeredEvents:int = False


	'override - create a PlayerCollection instead of PlayerBaseCollection
	Function GetInstance:TPlayerCollection()
		if not _instance
			_instance = new TPlayerCollection
		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		'==== ATTENTION =====
		'NEVER store _instance somewhere without paying attention
		'to this "whacky hack"
		elseif not TPlayerCollection(_instance)
			local collection:TPlayerCollection = new TPlayerCollection
			collection.players = _instance.players
			collection.playerID = _instance.playerID
			'now the new collection is the instance
			_instance = collection
		endif
		return TPlayerCollection(_instance)
	End Function


	'override
	Method Initialize:int()
		local result:int = Super.Initialize()

		'=== EVENTS ===
		'remove old listeners
		EventManager.unregisterListenersByLinks(_eventListeners)

		'register new listeners
		_eventListeners = new TLink[0]
		_eventListeners :+ [ EventManager.registerListenerFunction("figure.onFailEnterRoom", OnFigureFailEnterRoom) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("figure.onBeginEnterRoom", OnFigureBeginEnterRoom) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("figure.onFinishEnterRoom", OnFigureFinishEnterRoom) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("figure.onFinishLeaveRoom", OnFigureFinishLeaveRoom) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("figure.onReachTarget", OnFigureReachTarget) ]

		return result
	End Method


	Method Get:TPlayer(id:Int=-1)
		return TPlayer(Super.Get(id))
	End Method


	Method GetByFigure:TPlayer(figure:TFigure)
		'check all players if this was their figure
		For local player:TPlayer = EachIn players
			if player.figure = figure then return player
		Next
		return null
	End Method


	'override to return "true" only for TPlayer but not TPlayerBase
	Method IsPlayer:Int(number:Int)
		Return (number > 0 And number <= players.length And TPlayer(players[number-1]))
	End Method


	Method IsHuman:Int(number:Int)
		if not IsPlayer(number) then return False
		Return Get(number).IsLocalHuman() or Get(number).IsRemoteHuman()
	End Method


	Method IsLocalHuman:Int(number:Int)
		Return number = playerID and not (Get(number).IsLocalAI() or Get(number).IsRemoteAI())
	End Method


	Method IsRemoteHuman:Int(number:Int)
		Return (IsPlayer(number) And Get(number).IsRemoteHuman())
	End Method


	Method IsRemoteAI:Int(number:Int)
		Return (IsPlayer(number) And Get(number).IsRemoteAI())
	End Method


	Method IsLocalAI:Int(number:Int)
		Return (IsPlayer(number) And Get(number).IsLocalAI())
	End Method


	'=== EVENTS ===
	Function OnFigureReachTarget:int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or figure.playerID = 0 then return False
		local player:TPlayer = GetPlayer(figure.playerID)
		if not player then return False

		'=== REACH TARGET EVENT ===
		EventManager.triggerEvent( TEventSimple.Create("player.onReachTarget", null, player) )

		'inform player AI
		If player.isLocalAI()
			local target:TFigureTargetBase = TFigureTargetBase(triggerEvent.GetReceiver())
			if target
				player.PlayerAI.CallOnReachTarget( target.targetObj )
			endif
		endif


		'=== REACH ROOM EVENT ===
		'only interested in target of type "door" (rooms)
		local roomDoor:TRoomDoorBase = TRoomDoorBase(triggerEvent.GetReceiver())
		if not roomDoor then return False

		local room:TRoomBase = GetRoomBaseCollection().Get(roomDoor.roomID)
		if not room then return False

		EventManager.triggerEvent( TEventSimple.Create("player.onReachRoom", null, player, room) )

		'inform player AI
		If player.isLocalAI()
			player.PlayerAI.CallOnReachRoom(room.id)
		endif
	End Function


	Function OnFigureFinishLeaveRoom:int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or figure.playerID = 0 then return False
		local player:TPlayer = GetPlayer(figure.playerID)
		if not player then return False

		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())

		EventManager.triggerEvent( TEventSimple.Create("player.onLeaveRoom", null, player, room) )

		'inform player AI
		If player.isLocalAI()
			local roomID:int = 0
			if room then roomID = room.id
			player.PlayerAI.CallOnLeaveRoom(roomID)
		endif
	End Function


	Function OnFigureFailEnterRoom:int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or figure.playerID = 0 then return False
		local player:TPlayer = GetPlayer(figure.playerID)
		if not player then return False

		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())
		local door:TRoomDoorBase = TRoomDoorBase(triggerEvent.GetData().Get("door"))
		local reason:string = triggerEvent.GetData().GetString("reason", "")

		if reason = "inuse"
			'inform player AI
			If player.isLocalAI() then player.PlayerAI.CallOnBeginEnterRoom(room.id, TLuaFunctionsBase.RESULT_INUSE)
			'tooltip only for active user
			If player.isLocalHuman() then GetBuilding().CreateRoomUsedTooltip(door, room)
		elseif reason = "blocked"
			'inform player AI
			If player.isLocalAI() then player.PlayerAI.CallOnBeginEnterRoom(room.id, TLuaFunctionsBase.RESULT_NOTALLOWED)
			'tooltip only for active user
			If player.isLocalHuman() then GetBuilding().CreateRoomBlockedTooltip(door, room)
		elseif reason = "locked"
			'inform player AI
			If player.isLocalAI() then player.PlayerAI.CallOnBeginEnterRoom(room.id, TLuaFunctionsBase.RESULT_NOKEY)
			'tooltip only for active user
			If player.isLocalHuman() then GetBuilding().CreateRoomLockedTooltip(door, room)
		endif
	End Function


	Function OnFigureBeginEnterRoom:int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or figure.playerID = 0 then return False
		local player:TPlayer = GetPlayer(figure.playerID)
		if not player then return False

		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())

		'when entering something else then the movieagency
		if room
			local doEmpty:int = False
			'coming from the movieagency and entering another room
			if player.emptyProgrammeSuitcaseFromRoom = "movieagency" and room.GetName() <> "movieagency" then doEmpty = True
			'coming from archive - for now nothing!
			'if player.emptyProgrammeSuitcaseFromRoom = "archive" and room.name <> "archive" and room.name <> "movieagency" then doEmpty = True

			if doEmpty
				'try to empty the suitcase
				player.emptyProgrammeSuitcase = True
				player.emptyProgrammeSuitcaseTime = Time.GetTimeGone()

				player.EmptyProgrammeSuitcaseIfNeeded()
			else
				player.emptyProgrammeSuitcase = False
			endif
		endif

		EventManager.triggerEvent( TEventSimple.Create("player.onBeginEnterRoom", null, player, room) )

		'inform player AI
		If room and player.isLocalAI() then player.PlayerAI.CallOnBeginEnterRoom(room.id, TLuaFunctionsBase.RESULT_OK)
	End Function


	Function OnFigureFinishEnterRoom:int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or figure.playerID = 0 then return False

		'alternatively search by "playerID" - but maybe we delete that
		'property somewhen
		local player:TPlayer = GetInstance().GetByFigure(figure)
		if not player then return False

		'send out event: player entered room
		local door:object = triggerEvent.GetData().Get("door")
		local room:TRoom = TRoom(triggerEvent.GetData().Get("room"))
		if not room then return False
		EventManager.triggerEvent( TEventSimple.Create("player.onEnterRoom", new TData.Add("door", door), player, room) )

	 	'inform player AI that figure entered a room
	 	If player.isLocalAI() Then player.PlayerAI.CallOnEnterRoom(room.id)
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPlayerCollection:TPlayerCollection()
	Return TPlayerCollection.GetInstance()
End Function
'return specific player
Function GetPlayer:TPlayer(playerID:int=-1)
	Return TPlayer(TPlayerCollection.GetInstance().Get(playerID))
End Function



'class holding name, channelname, infos about the figure, programmeplan, programmecollection and so on - from a player
Type TPlayer extends TPlayerBase {_exposeToLua="selected"}
	'ID of a remote player who controls this (ai) player
	field playerControlledByID:int = -1
	Field aiData:TData = new TData {_exposeToLua}


	'override
	Method Initialize:int()
		local result:int = Super.Initialize()
		'reset "script external" data
		'(external objects for the lua scripts)
		if aiData then aiData = new TData

		return result
	End Method


	Method SetAIData(key:string, value:object) {_exposeToLua}
		aiData.Add(key, value)
	End Method

	Method SetAIStringData(key:string, value:string) {_exposeToLua}
		aiData.Add(key, value)
	End Method


	Method onLoad:int(triggerEvent:TEventBase)
		if IsLocalAi()
			'reconnect AI engine
			playerAI.Start()
			'load savestate
			playerAI.CallOnLoad()
		endif

		'reassign difficulty (and store in collection)
'		GetDifficulty()

		'repair broken figure sprites (eg. through savegame)
		'TODO: find out why this happens
		if not figure.sprite.parent.image then figure.OnLoad()
	End Method


	Method GetFigure:TFigure()
		return TFigure(figure)
	End Method


	Method GetStationMap:TStationMap() {_exposeToLua}
		'fetch from StationMap-list - or create if missing
		local map:TStationMap = GetStationMapCollection().GetMap(playerID, True)
		return map
	End Method


	'make public image available for AI/Lua
	Method GetPublicImage:TPublicImage() {_exposeToLua}
		return .GetPublicImage(playerID)
	End Method


	Method GetProgrammeCollection:TPlayerProgrammeCollection() {_exposeToLua}
		return GetPlayerProgrammeCollection(playerID)
	End Method


	Method GetProgrammePlan:TPlayerProgrammePlan() {_exposeToLua}
		return GetPlayerProgrammePlan(playerID)
	End Method


	Method GetMaxAudience:Int() {_exposeToLua}
		Return GetStationMap().GetReach()
	End Method


	'override
	Method GetAudienceReachLevel:Int() {_exposeToLua}
		Return GetStationMap().GetReachLevel( GetMaxAudience() )
	End Method


	Method isInRoom:Int(roomName:String="") {_exposeToLua}
		return GetFigure().IsInRoom(roomName)
rem
		If roomName <> ""
			Return (GetFigure().inRoom And GetFigure().inRoom.Name.toLower() = roomname.toLower())
		Else
			Return GetFigure().inRoom <> null
		EndIf
endrem
	End Method


	Method isComingFromRoom:Int(roomName:String="") {_exposeToLua}
		'check for specified room
		If roomName <> ""
			Return GetFigure().fromRoom And GetFigure().fromRoom.GetName().toLower() = roomname.toLower()
			'just check if we are in a unspecified room
		Else
			Return GetFigure().fromRoom <> null
		Endif
	End Method


	'Damit man GetFinance nicht in Lua verfügbar machen muss
	Method GetCreditInterest:int() {_exposeToLua}
		return GetFinance().GetCreditInterest()
	end Method


	Method GetTotalNewsAbonnementFees:int() {_exposeToLua}
		Local newsagencyfees:Int =0
		For Local i:Int = 0 until TVTNewsGenre.count
			newsagencyfees:+ TNewsAgency.GetNewsAbonnementPrice(playerID, TVTNewsGenre.GetAtIndex(i), GetNewsAbonnementDaysMax(i) )
		Next
		return newsagencyfees
	end Method


	'creates and returns a player
	'-creates the given playercolor and a figure with the given
	' figureimage, a programmecollection and a programmeplan
	Function Create:TPlayer(playerID:int, Name:String, channelname:String = "", sprite:TSprite, x:Int, onFloor:Int = 13, dx:Int, color:TPlayerColor, FigureName:String = "")
		Local Player:TPlayer = New TPlayer

		Player.Name	= Name
		Player.playerID	= playerID
		Player.color = color.SetOwner(playerID).AddToList()
		Player.channelname = channelname
		Player.Figure = New TFigure.Create(FigureName, sprite, x, onFloor, dx)
		Player.Figure.playerID = playerID

		'create a new boss for the player
		GetPlayerBossCollection().Set(playerID, new TPlayerBoss)

		Player.RecolorFigure(Player.color)

		Player.UpdateFigureBase(0)

		Return Player
	End Function


	Method EmptyProgrammeSuitcaseIfNeeded:int()
		if not emptyProgrammeSuitcase then return False

		if emptyProgrammeSuitcaseTime <= Time.GetTimeGone()
			GetPlayerProgrammeCollection(playerID).ReaddProgrammeLicencesFromSuitcase()

			emptyProgrammeSuitcase = False
			emptyProgrammeSuitcaseTime = Time.GetTimeGone()
			emptyProgrammeSuitcaseFromRoom = ""
			return True
		endif

		return False
	End Method


	'override
	Method Update:int()
		Super.Update()

		EmptyProgrammeSuitcaseIfNeeded()
	End Method


'	Method IsAI:Int() {_exposeToLua}
'		return IsLocalAI() or IsRemoteAI()
'	End Method


	Method SetLocalHumanControlled()
		playerAI = Null
		playerControlledByID = GetPlayerCollection().playerID
		SetPlayerType(PLAYERTYPE_LOCAL_HUMAN)
	End Method


	Method SetLocalAIControlled()
		playerControlledByID = GetPlayerCollection().playerID
		SetPlayerType(PLAYERTYPE_LOCAL_AI)
	End Method


	Method SetInactive()
		playerControlledByID = GetPlayerCollection().playerID
		SetPlayerType(PLAYERTYPE_INACTIVE)
	End Method


	Method SetRemoteHumanControlled(remotePlayerID:int)
		playerAI = Null
		playerControlledByID = remotePlayerID
		SetPlayerType(PLAYERTYPE_REMOTE_HUMAN)
	End Method


	Method SetRemoteAiControlled(remotePlayerID:int)
		playerAI = Null
		playerControlledByID = remotePlayerID
		SetPlayerType(PLAYERTYPE_REMOTE_AI)
	End Method


	Method InitAI(ai:TAiBase)
		PlayerAI = ai
		PlayerAI.Start()
		aiData = new TData
	End Method


	'remove this helper as soon as "player" class gets a single importable
	'file
	Method SendToBoss:Int()	{_exposeToLua}
		GetFigure().SendToDoor( TRoomDoor.GetByDetails("boss", playerID), True )

		'inform the boss that the player accepted the call
		GetPlayerBossCollection().Get(playerID).InformPlayerAcceptedCall()
	End Method


	Method SetNewsAbonnement:int(genre:Int, level:Int, sendToNetwork:Int = True) {_exposeToLua}
		If super.SetNewsAbonnement(genre, level, sendToNetwork)
			EventManager.triggerEvent( TEventSimple.Create("player.SetNewsAbonnement", new TData.AddNumber("genre", genre).AddNumber("level", level).AddNumber("sendToNetwork", sendToNetwork), self) )

			return True
		EndIf
		return False
	End Method


	'overridden
	Method GetCreditAvailable:Int() {_exposeToLua}
		Return Max(0, GetPlayerBoss(playerID).GetCreditMaximum() - GetFinance().GetCredit())
	End Method


	'overridden
	'returns formatted value of actual money
	Method GetMoneyFormatted:String(day:Int=-1)
		Return TFunctions.convertValue(GetFinance(day).money, 2)
	End Method


	'overridden
	Method GetMoney:Int(day:Int=-1) {_exposeToLua}
		Return GetFinance(day).money
	End Method


	'returns formatted value of actual credit
	Method GetCreditFormatted:String(day:Int=-1)
		Return TFunctions.convertValue(GetFinance(day).GetCredit(), 2)
	End Method

	'overridden
	Method GetCredit:Int(day:Int=-1) {_exposeToLua}
		Return GetFinance(day).GetCredit()
	End Method
End Type