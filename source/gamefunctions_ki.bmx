'**************************************************************************************************
' This program was written with BLIde
' Application:
' Author:
' License:
'**************************************************************************************************

Global AiLog:TLogFile[4]
For local i:int = 0 to 3
	AiLog[i] = TLogFile.Create("KI Log v1.0", "log.ki"+(i+1)+".txt")
Next

Global KIRunning:Int = true

'SuperStrict
Type KI
	Field playerID:int
	Field LuaEngine:TLuaEngine {nosave}
	Field scriptFileName:String
	Field scriptSaveState:string 'contains the code used to reinitialize the AI


	Method Create:KI(playerID:Int, luaScriptFileName:String)
		self.playerID		= playerID
		self.scriptFileName = luaScriptFileName
		Return self
	End Method


	Method OnCreate()
		Local args:Object[1]
		args[0] = String(playerID)
		if (KIRunning) then LuaEngine.CallLuaFunction("OnCreate", args)
	End Method


	Method Start()
		'register engine and functions
		if not LuaEngine then LuaEngine = TLuaEngine.Create("")

		'load lua file
		LoadScript(scriptFileName)

		'==== LINK SPECIAL OBJECTS
		'own functions for player
		LuaEngine.RegisterBlitzmaxObject(TLuaFunctions.Create(PlayerID), "TVT")
		'the player
		LuaEngine.RegisterBlitzmaxObject(Game.GetPlayer(PlayerID), "MY")
		'the game object
		LuaEngine.RegisterBlitzmaxObject(Game, "Game")

		'register source and available objects
		LuaEngine.RegisterToLua()
	End Method


	Method Stop()
'		scriptEnv.ShutDown()
'		KI_EventManager.unregisterKI(Self)
	End Method


	'loads a .lua-file and registers needed objects
	Method LoadScript:int(luaScriptFileName:string)
		if luaScriptFileName <> "" then scriptFileName = luaScriptFileName
		if scriptFileName = "" then return FALSE

		'only load for existing players
		If not Game.GetPlayer(PlayerID)
			TDevHelper.log("KI.LoadScript()", "TPlayer "+PlayerID+" not found.", LOG_ERROR)
			return FALSE
		endif

		Local loadtime:Int = MilliSecs()
		'load content
		LuaEngine.SetSource(LoadText(scriptFileName))

		'if there is content set, print it
		If LuaEngine.GetSource() <> ""
			TDevHelper.log("KI.LoadScript", "ReLoaded LUA AI for player "+playerID+". Loading Time: " + (MilliSecs() - loadtime) + "ms", LOG_DEBUG | LOG_LOADING)
		else
			TDevHelper.log("KI.LoadScript", "Loaded LUA AI for player "+playerID+". Loading Time: " + (MilliSecs() - loadtime) + "ms", LOG_DEBUG | LOG_LOADING)
		endif
	End Method


	'loads the current file again
	Method ReloadScript:int()
		if scriptFileName="" then return FALSE
		LoadScript(scriptFileName)
	End Method


	Method CallOnLoad()
	    Try
			Local args:Object[1]
			args[0] = self.scriptSaveState
			if (KIRunning) then LuaEngine.CallLuaFunction("OnLoad", args)
		Catch ex:Object
			TDevHelper.log("KI.CallOnLoad", "Script "+scriptFileName+" does not contain function ~qOnLoad~q.", LOG_ERROR)
		End Try
	End Method


	Method CallOnSave:string()
		'reset (potential old) save state
		scriptSaveState = ""

	    Try
			Local args:Object[1]
			args[0] = string(Game.GetTimeGone())
			if (KIRunning) then scriptSaveState = string(LuaEngine.CallLuaFunction("OnSave", args))
		Catch ex:Object
			TDevHelper.log("KI.CallOnSave", "Script "+scriptFileName+" does not contain function ~qOnSave~q.", LOG_ERROR)
		End Try

		return scriptSaveState
	End Method


	Method CallOnMinute(minute:Int=0)
		Local args:Object[1]
		args[0] = String(minute)
		if (KIRunning) then LuaEngine.CallLuaFunction("OnMinute", args)
	End Method


	'eg. use this if one whispers to the AI
	Method CallOnChat(fromID:int=0, text:String = "")
	    Try
			Local args:Object[2]
			args[0] = text
			args[1] = string(fromID)
			LuaEngine.CallLuaFunction("OnChat", args)
		Catch ex:Object
			TDevHelper.log("KI.CallOnChat", "Script "+scriptFileName+" does not contain function ~qOnChat~q.", LOG_ERROR)
		End Try
	End Method


	Method CallOnReachRoom(roomId:Int)
	    Try
			Local args:Object[1]
			args[0] = String(roomId)
			if (KIRunning) then LuaEngine.CallLuaFunction("OnReachRoom", args)
		Catch ex:Object
			TDevHelper.log("KI.CallOnReachRoom", "Script "+scriptFileName+" does not contain function ~qOnReachRoom~q.", LOG_ERROR)
		End Try
	End Method

	Method CallOnLeaveRoom()
	    Try
			if (KIRunning) then LuaEngine.CallLuaFunction("OnLeaveRoom", Null)
		Catch ex:Object
			TDevHelper.log("KI.CallOnLeaveRoom", "Script "+scriptFileName+" does not contain function ~qOnLeaveRoom~q.", LOG_ERROR)
		End Try
	End Method

	Method CallOnDayBegins()
	    Try
			if (KIRunning) then LuaEngine.CallLuaFunction("OnDayBegins", Null)
		Catch ex:Object
			TDevHelper.log("KI.CallOnDayBegins", "Script "+scriptFileName+" does not contain function ~qOnDayBegins~q.", LOG_ERROR)
		End Try
	End Method

	Method CallOnMoneyChanged()
	    Try
			if (KIRunning) then LuaEngine.CallLuaFunction("OnMoneyChanged", Null)
		Catch ex:Object
			TDevHelper.log("KI.CallOnMoneyChanged", "Script "+scriptFileName+" does not contain function ~qOnMoneyChanged~q.", LOG_ERROR)
		End Try
	End Method
End Type


'wrapper for result-type/ID + data
Type TLuaFunctionResult {_exposeToLua}
	Field result:int = 0
	Field data:object

	Function Create:TLuaFunctionResult(result:int, data:object)
		local obj:TLuaFunctionResult = new TLuaFunctionResult
		obj.result = result
		obj.data = data
		return obj
	End Function
End Type


Type TLuaFunctions {_exposeToLua}
	'have to do this as "field" because Lua cannot access const/globals
	Const RESULT_OK:int				=   1
	Const RESULT_FAILED:int			=   0
	Const RESULT_WRONGROOM:int		=  -2
	Const RESULT_NOKEY:int			=  -4
	Const RESULT_NOTFOUND:int		=  -8
	Const RESULT_NOTALLOWED:int		= -16
	Const RESULT_INUSE:int			= -32

	Const MOVIE_GENRE_ACTION:Int		= 0
	Const MOVIE_GENRE_THRILLER:Int		= 1
	Const MOVIE_GENRE_SCIFI:Int			= 2
	Const MOVIE_GENRE_COMEDY:Int		= 3
	Const MOVIE_GENRE_HORROR:Int		= 4
	Const MOVIE_GENRE_LOVE:Int			= 5
	Const MOVIE_GENRE_EROTIC:Int		= 6
	Const MOVIE_GENRE_WESTERN:Int		= 7
	Const MOVIE_GENRE_LIVE:Int			= 8
	Const MOVIE_GENRE_KIDS:Int			= 9
	Const MOVIE_GENRE_CARTOON:Int		= 10
	Const MOVIE_GENRE_MUSIC:Int			= 11
	Const MOVIE_GENRE_SPORT:Int			= 12
	Const MOVIE_GENRE_CULTURE:Int		= 13
	Const MOVIE_GENRE_FANTASY:Int		= 14
	Const MOVIE_GENRE_YELLOWPRESS:Int	= 15
	Const MOVIE_GENRE_NEWS:Int			= 16
	Const MOVIE_GENRE_SHOW:Int			= 17
	Const MOVIE_GENRE_MONUMENTAL:Int	= 18

	Const NEWS_GENRE_POLITICS:Int		= 0
	Const NEWS_GENRE_SHOWBIZ:Int		= 1
	Const NEWS_GENRE_SPORT:Int			= 2
	Const NEWS_GENRE_TECHNICS:Int		= 3
	Const NEWS_GENRE_CURRENTS:Int		= 4


	Field ME:Int 'Wird initialisiert


	'Die Räume werden alle initialisiert
	Field ROOM_TOWER:Int = 0
	Field ROOM_MOVIEAGENCY:Int
	Field ROOM_ADAGENCY:Int
	Field ROOM_ROOMBOARD:Int
	Field ROOM_PORTER:Int
	Field ROOM_BETTY:Int
	Field ROOM_SUPERMARKET:Int
	Field ROOM_ROOMAGENCY:Int
	Field ROOM_PEACEBROTHERS:Int
	Field ROOM_SCRIPTAGENCY:Int
	Field ROOM_NOTOBACCO:Int
	Field ROOM_TOBACCOLOBBY:Int
	Field ROOM_GUNSAGENCY:Int
	Field ROOM_VRDUBAN:Int
	Field ROOM_FRDUBAN:Int

	Field ROOM_OFFICE_PLAYER_ME:Int
	Field ROOM_BOSS_PLAYER_ME:Int
	Field ROOM_NEWSAGENCY_PLAYER_ME:Int
	Field ROOM_ARCHIVE_PLAYER_ME:Int

	Rem
		DO NOT use this constants (even "_ME" should be deprecated)
		a) avoids modability
		b) AI can request room using
			TRoom.GetFirstByDetails(...)  - get the first found room
			TRoom.GetByDetails(...) - get array of found rooms
		    ID is room.GetID()
		c) a player can have multiple studios - how to handle this with const?
		d) rooms could change "content" and no longer exist

		Field ROOM_START_STUDIO_PLAYER_ME:Int
		Field ROOM_ARCHIVE_PLAYER1:Int
		Field ROOM_NEWSAGENCY_PLAYER1:Int
		Field ROOM_BOSS_PLAYER1:Int
		Field ROOM_OFFICE_PLAYER1:Int
		Field ROOM_STUDIOSIZE_PLAYER1:Int

		Field ROOM_ARCHIVE_PLAYER2:Int
		Field ROOM_NEWSAGENCY_PLAYER2:Int
		Field ROOM_BOSS_PLAYER2:Int
		Field ROOM_OFFICE_PLAYER2:Int
		Field ROOM_STUDIOSIZE_PLAYER2:Int

		Field ROOM_ARCHIVE_PLAYER3:Int
		Field ROOM_NEWSAGENCY_PLAYER3:Int
		Field ROOM_BOSS_PLAYER3:Int
		Field ROOM_OFFICE_PLAYER3:Int
		Field ROOM_STUDIOSIZE_PLAYER3:Int

		Field ROOM_ARCHIVE_PLAYER4:Int
		Field ROOM_NEWSAGENCY_PLAYER4:Int
		Field ROOM_BOSS_PLAYER4:Int
		Field ROOM_OFFICE_PLAYER4:Int
		Field ROOM_START_STUDIO_PLAYER4:Int
	EndRem

	Method _PlayerInRoom:Int(roomname:String, checkFromRoom:Int = False)
		Return Game.getPlayer(Self.ME).isInRoom(roomname, checkFromRoom)
	End Method


	Method _PlayerOwnsRoom:Int()
		Return Self.ME = Game.getPlayer(Self.ME).Figure.inRoom.owner
	End Method


	Function Create:TLuaFunctions(pPlayerId:Int)
		Local ret:TLuaFunctions = New TLuaFunctions

		ret.ME = pPlayerId

		ret.ROOM_MOVIEAGENCY = TRoom.GetFirstByDetails("movieagency").id
		ret.ROOM_ADAGENCY = TRoom.GetFirstByDetails("adagency").id
		ret.ROOM_ROOMBOARD = TRoom.GetFirstByDetails("roomboard").id
		ret.ROOM_PORTER = TRoom.GetFirstByDetails("porter").id
		ret.ROOM_BETTY = TRoom.GetFirstByDetails("betty").id
		ret.ROOM_SUPERMARKET = TRoom.GetFirstByDetails("supermarket").id
		ret.ROOM_ROOMAGENCY = TRoom.GetFirstByDetails("roomagency").id
		ret.ROOM_PEACEBROTHERS = TRoom.GetFirstByDetails("peacebrothers").id
		ret.ROOM_SCRIPTAGENCY = TRoom.GetFirstByDetails("scriptagency").id
		ret.ROOM_NOTOBACCO = TRoom.GetFirstByDetails("notobacco").id
		ret.ROOM_TOBACCOLOBBY = TRoom.GetFirstByDetails("tobaccolobby").id
		ret.ROOM_GUNSAGENCY = TRoom.GetFirstByDetails("gunsagency").id
		ret.ROOM_VRDUBAN = TRoom.GetFirstByDetails("vrduban").id
		ret.ROOM_FRDUBAN = TRoom.GetFirstByDetails("frduban").id

		ret.ROOM_ARCHIVE_PLAYER_ME = TRoom.GetFirstByDetails("archive", pPlayerId).id
		ret.ROOM_NEWSAGENCY_PLAYER_ME = TRoom.GetFirstByDetails("news", pPlayerId).id
		ret.ROOM_BOSS_PLAYER_ME = TRoom.GetFirstByDetails("chief", pPlayerId).id
		ret.ROOM_OFFICE_PLAYER_ME = TRoom.GetFirstByDetails("office", pPlayerId).id

		REM
		ret.ROOM_START_STUDIO_PLAYER_ME = TRoom.GetFirstByDetails("studio", pPlayerId).id

		ret.ROOM_ARCHIVE_PLAYER1 = TRoom.GetFirstByDetails("archive", 1).id
		ret.ROOM_NEWSAGENCY_PLAYER1 = TRoom.GetFirstByDetails("news", 1).id
		ret.ROOM_BOSS_PLAYER1 = TRoom.GetFirstByDetails("chief", 1).id
		ret.ROOM_OFFICE_PLAYER1 = TRoom.GetFirstByDetails("office", 1).id
		ret.ROOM_START_STUDIO_PLAYER1 = TRoom.GetFirstByDetails("studio", 1).id

		ret.ROOM_ARCHIVE_PLAYER2 = TRoom.GetFirstByDetails("archive", 2).id
		ret.ROOM_NEWSAGENCY_PLAYER2 = TRoom.GetFirstByDetails("news", 2).id
		ret.ROOM_BOSS_PLAYER2 = TRoom.GetFirstByDetails("chief", 2).id
		ret.ROOM_OFFICE_PLAYER2 = TRoom.GetFirstByDetails("office", 2).id
		ret.ROOM_START_STUDIO_PLAYER2 = TRoom.GetFirstByDetails("studio", 2).id

		ret.ROOM_ARCHIVE_PLAYER3 = TRoom.GetFirstByDetails("archive", 3).id
		ret.ROOM_NEWSAGENCY_PLAYER3 = TRoom.GetFirstByDetails("news", 3).id
		ret.ROOM_BOSS_PLAYER3 = TRoom.GetFirstByDetails("chief", 3).id
		ret.ROOM_OFFICE_PLAYER3 = TRoom.GetFirstByDetails("office", 3).id
		ret.ROOM_START_STUDIO_PLAYER3 = TRoom.GetFirstByDetails("studio", 3).id

		ret.ROOM_ARCHIVE_PLAYER4 = TRoom.GetFirstByDetails("archive", 4).id
		ret.ROOM_NEWSAGENCY_PLAYER4 = TRoom.GetFirstByDetails("news", 4).id
		ret.ROOM_BOSS_PLAYER4 = TRoom.GetFirstByDetails("chief", 4).id
		ret.ROOM_OFFICE_PLAYER4 = TRoom.GetFirstByDetails("office", 4).id
		ret.ROOM_START_STUDIO_PLAYER4 = TRoom.GetFirstByDetails("studio", 4).id
		End Rem

		Return ret
	End Function


	Method PrintOut:Int(text:String)
		TDevHelper.log("AI "+self.ME, text, LOG_AI)
		Return self.RESULT_OK
	EndMethod


	'only printed if TDevHelper.setPrintMode(LOG_AI | LOG_DEBUG) is set
	Method PrintOutDebug:int(text:string)
		TDevHelper.log("AI "+self.ME+" DEBUG", text, LOG_AI & LOG_DEBUG)
		Return self.RESULT_OK
	End Method

rem
	'do not give raw access to ALL programmes in the database
	'AI has to use the normal "go into room, get data there" approach
	Method GetProgramme:TProgramme( id:int ) {_exposeToLua}
		return TProgramme.getProgramme( id )
	End Method

	Method GetContract:TAdContract( id:int ) {_exposeToLua}
		return TAdContract.Get( id )
	End Method
endrem

	Method GetFirstRoomByDetails:TRoom(roomName:String, owner:Int=-1000)
		return TRoom.GetFirstByDetails(roomName, owner)
	End Method

	Method GetRoom:TRoom(id:int)
		return TRoom.Get(id)
	End Method


	Method SendToChat:Int(ChatText:String)
		If Game.Players[ Self.ME ] <> Null
			'emit an event, we received a chat message
			local sendToChannels:int = TGUIChat.GetChannelsFromText(ChatText)
			EventManager.triggerEvent( TEventSimple.Create( "chat.onAddEntry", new TData.AddNumber("senderID", self.ME).AddNumber("channels", sendToChannels).AddString("text",ChatText) ) )
		EndIf
		Return 1
	EndMethod


	Method getPlayerRoom:Int()
		Local room:TRoom = Game.Players[ Self.ME ].figure.inRoom
		If room <> Null Then Return room.id Else Return self.RESULT_NOTFOUND
	End Method


	Method getPlayerTargetRoom:Int()
		If Game.Players[ Self.ME ].figure.targetDoor
			if Game.Players[ Self.ME ].figure.targetDoor.room
				Return Game.Players[ Self.ME ].figure.targetDoor.room.id
			Endif
		Endif
		Return self.RESULT_NOTFOUND
	End Method


	'return the floor of a room
	'attention: the floor of the first found door is returned
	Method getRoomFloor:Int(roomId:Int = 0)
		Local room:TRoom = TRoom.Get(roomId)
		if room
			Local door:TRoomDoor = TRoomDoor.GetMainDoorToRoom(room)
			If door Then Return door.Pos.y
		endif
		Return self.RESULT_NOTFOUND
	End Method


	'send figure to a specific room
	'attention: the first found door is used
	Method doGoToRoom:Int(roomId:Int = 0)
		Local room:TRoom = TRoom.Get(roomId)

		Local door:TRoomDoor = TRoomDoor.GetMainDoorToRoom(room)
		If door
			Game.Players[ Self.ME ].Figure.SendToDoor(door)
			Return self.RESULT_OK
		endif

		Return self.RESULT_NOTFOUND
	End Method


	Method doGoToRelative:Int(relX:Int = 0, relYFloor:Int = 0) 'Nur x wird unterstützt. Negativ: Nach links; Positiv: nach rechts
		Game.Players[ Self.ME ].Figure.GoToCoordinatesRelative(relX, relYFloor)
		Return self.RESULT_OK
	End Method


	Method isRoomUnused:Int(roomId:Int = 0)
		Local Room:TRoom = TRoom.Get(roomId)
		If not Room then return self.RESULT_NOTFOUND
		if not Room.hasOccupant() then return self.RESULT_OK

		If Room.isOccupant( Game.GetPlayer(Self.ME).figure ) then Return -1
		Return self.RESULT_INUSE
	End Method


	Method getMillisecs:Int()
		Return MilliSecs()
	End Method


	Method addToLog:int(text:string)
		return AiLog[Self.ME-1].AddLog(text)
	End Method


	Method convertToAdContract:TAdContract(obj:object)
		return TAdContract(obj)
	End Method

	Method convertToProgrammeLicence:TProgrammeLicence(obj:object)
		return TProgrammeLicence(obj)
	End Method



'- - - - - -
' Office
'- - - - - -
	'returns the broadcast material (in result.data) at the given slot
	Method of_getAdvertisementSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		Local material:TBroadcastMaterial = Game.getPlayer(Self.ME).ProgrammePlan.GetAdvertisement(day, hour)
		If material
			Return TLuaFunctionResult.Create(self.RESULT_OK, material)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method of_getAdContractCount:Int()
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		Return Game.getPlayer(Self.ME).ProgrammeCollection.GetAdContractCount()
	End Method


	Method of_getAdContractAtIndex:TAdContract(arrayIndex:Int=-1)
		If Not _PlayerInRoom("office", True) Then Return Null

		Local obj:TAdContract = Game.getPlayer(Self.ME).ProgrammeCollection.GetAdContractAtIndex(arrayIndex)
		If obj Then Return obj Else Return Null
	End Method


	Method of_getAdContractByID:TAdContract(id:Int=-1)
		If Not _PlayerInRoom("office", True) Then Return Null

		Local obj:TAdContract = Game.getPlayer(Self.ME).ProgrammeCollection.GetAdContract(id)
		If obj Then Return obj Else Return Null
	End Method

	'Set content of a programme slot
	'=====
	'materialSource might be "null" to clear a time slot
	'or of types: "TProgrammeLicence" or "TAdContract"
	'returns: (TVT.)RESULT_OK, RESULT_WRONGROOM, RESULT_NOTFOUND
	Method of_setAdvertisementSlot:Int(materialSource:object, day:Int=-1, hour:Int=-1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM
		'even if player has access to room, only owner can manage things here
		If Not _PlayerOwnsRoom() Then Return self.RESULT_WRONGROOM

		'create a broadcast material out of the given source
		local broadcastMaterial:TBroadcastMaterial = Game.getPlayer(self.ME).ProgrammeCollection.GetBroadcastMaterial(materialSource)

		if Game.getPlayer(self.ME).ProgrammePlan.SetAdvertisementSlot(broadcastMaterial, day, hour)
			return self.RESULT_OK
		else
			return self.RESULT_NOTALLOWED
		endif
	End Method


	'returns the broadcast material (in result.data) at the given slot
	Method of_getProgrammeSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		Local material:TBroadcastMaterial = Game.getPlayer(Self.ME).ProgrammePlan.GetProgramme(day, hour)
		If material
			Return TLuaFunctionResult.Create(self.RESULT_OK, material)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	'Set content of a programme slot
	'=====
	'materialSource might be "null" to clear a time slot
	'or of types: "TProgrammeLicence" or "TAdContract"
	'returns: (TVT.)RESULT_OK, RESULT_WRONGROOM, RESULT_NOTFOUND
	Method of_SetProgrammeSlot:Int(materialSource:object, day:Int=-1, hour:Int=-1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM
		'even if player has access to room, only owner can manage things here
		If Not _PlayerOwnsRoom() Then Return self.RESULT_WRONGROOM

		'create a broadcast material out of the given source
		local broadcastMaterial:TBroadcastMaterial = Game.getPlayer(self.ME).ProgrammeCollection.GetBroadcastMaterial(materialSource)

		if Game.getPlayer(self.ME).ProgrammePlan.SetProgrammeSlot(broadcastMaterial, day, hour)
			return self.RESULT_OK
		else
			return self.RESULT_NOTALLOWED
		endif
	End Method


	Method getEvaluatedAudienceQuote:Int(hour:Int = -1, licenceID:Int = -1, lastQuotePercentage:Float = 0.1, audiencePercentageBasedOnHour:Float=-1)
		'TODO: Statt dem audiencePercentageBasedOnHour-Parameter könnte auch das noch unbenutzte "hour" den generellen Quotenwert in der
		'angegebenen Stunde mit einem etwas umgebauten "calculateMaxAudiencePercentage" (ohne Zufallswerte und ohne die globale Variable zu verändern) errechnen.

		Print "MANUEL: Für KI wieder rein machen!"
		'Local licence:TProgrammeLicence = TProgrammeLicence.Get(licenceID)
		'If licence and licence.getData()
		'	Local Quote:Int = Floor(licence.getData().getAudienceQuote(lastQuotePercentage, audiencePercentageBasedOnHour) * 100)
		'	Print "quote:" + Quote + "%"
		'	Return Quote
		'EndIf
		'0 percent - no programme
		return 0
	End Method

	'
	'LUA_isHoliday
	'
	'LUA_of_getPlayerMoviecount
	'LUA_of_getPlayerMovie
	'LUA_of_getPlayerSpot
	'
	'LUA_ne_getPlayerNewscount
	'LUA_ne_getPlayernews
	'LUA_ne_getPossibleNewscount
	'LUA_ne_getPossibleNews
	'LUA_ne_DelayNewsagency
	'LUA_ne_doActivatenewsagency
	'LUA_ne_doNewsInProgram


	Method ne_doNewsInPlan:Int(slot:int=1, ObjectID:Int = -1)
		If Not (_PlayerInRoom("newsroom", True) or _PlayerInRoom("news", True)) Then Return self.RESULT_WRONGROOM

		'Es ist egal ob ein Spieler einen Schluessel fuer den Raum hat,
		'Es ist nur schauen erlaubt fuer "Fremde"
		If Self.ME <> Game.Players[self.ME].Figure.inRoom.owner Then Return self.RESULT_WRONGROOM

		If ObjectID = 0 'News bei slotID loeschen
			if Game.getPlayer(self.ME).ProgrammePlan.RemoveNews(null, slot)
				Return self.RESULT_OK
			else
				Return self.RESULT_NOTFOUND
			endif
		Else
			Local news:TBroadcastMaterial = Game.Players[self.ME].ProgrammeCollection.GetNews(ObjectID)
			If not news or not TNews(news) then Return self.RESULT_NOTFOUND
			Game.Players[self.ME].ProgrammePlan.SetNews(TNews(news), slot)

			Return self.RESULT_OK
		EndIf
	End Method



	'
	'LUA_be_getSammyPoints
	'LUA_be_getBettyLove
	'LUA_be_getSammyGenre
	'

'- - - - - -
' Spot Agency
'- - - - - -
'untested
	Method sa_getSpotCount:Int()
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		Return RoomHandler_AdAgency.GetInstance().GetContractsInStock()
	End Method


	Method sa_getSpot:TLuaFunctionResult(position:Int=-1)
		If Not _PlayerInRoom("adagency") then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		'out of bounds?
		If position >= RoomHandler_AdAgency.GetInstance().GetContractsInStock() Or position < 0 then Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)

		local contract:TAdContract = RoomHandler_AdAgency.GetInstance().GetContractByPosition(position)
		If contract
			Return TLuaFunctionResult.Create(self.RESULT_OK, contract)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method sa_doBuySpot:Int(contractID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		local contract:TAdContract = RoomHandler_AdAgency.GetInstance().GetContractByID(contractID)
		'this DOES sign in that moment
		if contract and RoomHandler_AdAgency.GetInstance().GiveContractToPlayer( contract, self.ME, TRUE )
			return self.RESULT_OK
		endif
		Return self.RESULT_NOTFOUND
	End Method


	Method sa_doTakeSpot:Int(contractID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		local contract:TAdContract = RoomHandler_AdAgency.GetInstance().GetContractByID(contractID)
		'this DOES NOT sign - signing is done when leaving the room!
		if contract and RoomHandler_AdAgency.GetInstance().GiveContractToPlayer( contract, self.ME )
			return self.RESULT_OK
		endif
		Return self.RESULT_NOTFOUND
	End Method

	Method sa_doGiveBackSpot:Int(contractID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		local contract:TAdContract = Game.getPlayer(self.ME).ProgrammeCollection.GetUnsignedAdContractFromSuitcase(contractID)
		'this does not sign - signing is done when leaving the room!
		if contract and RoomHandler_AdAgency.GetInstance().TakeContractFromPlayer( contract, self.ME )
			Return self.RESULT_OK
		else
			Return self.RESULT_NOTFOUND
		endif
	End Method


'- - - - - -
' Movie Dealer - Movie Agency
'- - - - - -
	Method md_getProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		Return RoomHandler_MovieAgency.GetInstance().GetProgrammeLicencesInStock()
	End Method


	Method md_getProgrammeLicence:TLuaFunctionResult(position:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		'out of bounds?
		If position >= RoomHandler_MovieAgency.GetInstance().GetProgrammeLicencesInStock() Or position < 0 then Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)

		local licence:TProgrammeLicence = RoomHandler_MovieAgency.GetInstance().GetProgrammeLicenceByPosition(position)
		If licence
			Return TLuaFunctionResult.Create(self.RESULT_OK, licence)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method md_doBuyProgrammeLicence:Int(licenceID:Int=-1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local licence:TProgrammeLicence = RoomHandler_MovieAgency.GetInstance().GetProgrammeLicenceByID(licenceID)
		if Licence then return RoomHandler_MovieAgency.GetInstance().SellProgrammeLicenceToPlayer(licence, self.ME)

		Return self.RESULT_NOTFOUND
	End Method


	Method md_doSellProgrammeLicence:Int(licenceID:Int=-1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		For local licence:TProgrammeLicence = eachin Game.getPlayer(self.ME).ProgrammeCollection.suitcaseProgrammeLicences
			if licence.id = licenceID then return RoomHandler_MovieAgency.GetInstance().BuyProgrammeLicenceFromPlayer(licence)
		Next
		Return self.RESULT_NOTFOUND
	End Method

'- - - - - -
' Movie Dealer - Movie Agency - Auctions
'- - - - - -
'untested
	Method md_getAuctionMovieBlock:TAuctionProgrammeBlocks(ArrayID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return null
		If ArrayID >= TAuctionProgrammeBlocks.List.Count() Or arrayID < 0 Then Return null

		Local Block:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(TAuctionProgrammeBlocks.List.ValueAtIndex(ArrayID))
		If Block Then Return Block Else Return null
	End Method

'untested
	Method md_getAuctionProgrammeLicence:Int(ArrayID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		If ArrayID >= TAuctionProgrammeBlocks.List.Count() Or arrayID < 0 Then Return -2
		Local Block:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(TAuctionProgrammeBlocks.List.ValueAtIndex(ArrayID))
		If Block Then Return Block.licence.id Else Return self.RESULT_NOTFOUND
	End Method

'untested
	Method md_getAuctionProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		return TAuctionProgrammeBlocks.List.count()
	End Method

'untested
	Method md_doBidAuctionProgrammeLicence:Int(ArrayID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local Block:TAuctionProgrammeBlocks = self.md_getAuctionMovieBlock(ArrayID)
		If Block then Return Block.SetBid( self.ME ) else Return self.RESULT_NOTFOUND
	End Method

'untested
	Method md_GetAuctionProgrammeLicenceNextBid:Int(ArrayID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local Block:TAuctionProgrammeBlocks = self.md_getAuctionMovieBlock(ArrayID)
		If Block then Return Block.GetNextBid() else Return self.RESULT_NOTFOUND
	End Method

'untested
	Method md_GetAuctionProgrammeLicenceHighestBidder:Int(ArrayID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local Block:TAuctionProgrammeBlocks = self.md_getAuctionMovieBlock(ArrayID)
		If Block then Return Block.bestBidder else Return self.RESULT_NOTFOUND
	End Method


	'LUA_ar_getMovieInBagCount
	'LUA_ar_getMovieInBag
	'LUA_ar_doMovieInBag
	'LUA_ar_doMovieOutBag
	'
	'LUA_bo_doPayCredit
End Type

Global LuaFunctions:TLuaFunctions = new TLuaFunctions