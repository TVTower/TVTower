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
	'contains the code used to reinitialize the AI
	Field scriptSaveState:string
	'time in milliseconds of the last "onTick"-call
	Field LastTickTime:Long


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
		LuaEngine.RegisterBlitzmaxObject("TVT", TLuaFunctions.Create(PlayerID))
		'the player
		LuaEngine.RegisterBlitzmaxObject("MY", GetPlayerCollection().Get(PlayerID))
		'the game object
		LuaEngine.RegisterBlitzmaxObject("Game", Game)
		'the game object
		LuaEngine.RegisterBlitzmaxObject("GameRules", GameRules)
		'the game object
		LuaEngine.RegisterBlitzmaxObject("WorldTime", GetWorldTime())

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
		If not GetPlayerCollection().Get(PlayerID)
			TLogger.log("KI.LoadScript()", "TPlayer "+PlayerID+" not found.", LOG_ERROR)
			return FALSE
		endif

		Local loadingStopWatch:TStopWatch = new TStopWatch.Init()
		'load content
		LuaEngine.SetSource(LoadText(scriptFileName))

		'if there is content set, print it
		If LuaEngine.GetSource() <> ""
			TLogger.log("KI.LoadScript", "ReLoaded LUA AI for player "+playerID+". Loading Time: " + loadingStopWatch.GetTime() + "ms", LOG_DEBUG | LOG_LOADING)
		else
			TLogger.log("KI.LoadScript", "Loaded LUA AI for player "+playerID+". Loading Time: " + loadingStopWatch.GetTime() + "ms", LOG_DEBUG | LOG_LOADING)
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
			TLogger.log("KI.CallOnLoad", "Script "+scriptFileName+" does not contain function ~qOnLoad~q.", LOG_ERROR)
		End Try
	End Method


	Method CallOnSave:string()
		'reset (potential old) save state
		scriptSaveState = ""

	    Try
			Local args:Object[1]
			args[0] = string(GetWorldTime().GetTimeGone())
			if (KIRunning) then scriptSaveState = string(LuaEngine.CallLuaFunction("OnSave", args))
		Catch ex:Object
			TLogger.log("KI.CallOnSave", "Script "+scriptFileName+" does not contain function ~qOnSave~q.", LOG_ERROR)
		End Try

		return scriptSaveState
	End Method


	'only calls the AI "onTick" if the calculated interval passed
	'in our case this is:
	'- more than 1 RealTime second passed since last tick
	'or
	'- another InGameMinute passed since last tick
	Method ConditionalCallOnTick:Int()
		'time between two ticks = time between two GameMinutes or maximum
		'1 second (eg. if speed is 0)
		local tickInterval:Long = 1000
		if GetWorldTime().GetVirtualMinutesPerSecond() > 0
			tickInterval = Min(1000.0 , 1000.0 / GetWorldTime().GetVirtualMinutesPerSecond())
		endif

		'more time gone than the set interval?
		if abs(Time.GetTimeGone() - LastTickTime) > tickInterval
			'store time of this tick
			LastTickTime = Time.GetTimeGone()

			Local args:Object[] = [String(LastTickTime)]
			if KIRunning then LuaEngine.CallLuaFunction("OnTick", args)
		endif
	End Method


	Method CallOnRealtimeSecond(millisecondsGone:Int=0)
		Local args:Object[1]
		args[0] = String(millisecondsGone)
		if KIRunning then LuaEngine.CallLuaFunction("OnRealTimeSecond", args)
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
			TLogger.log("KI.CallOnChat", "Script "+scriptFileName+" does not contain function ~qOnChat~q.", LOG_ERROR)
		End Try
	End Method


	Method CallOnBossCalls(latestWorldTime:int=0)
		Local args:Object[1]
		args[0] = String(latestWorldTime)
		if (KIRunning) then LuaEngine.CallLuaFunction("OnBossCalls", args)
	End Method


	Method CallOnBossCallsForced()
		if (KIRunning) then LuaEngine.CallLuaFunction("OnBossCallsForced")
	End Method


	Method CallOnPublicAuthoritiesStopXRatedBroadcast()
		if (KIRunning) then LuaEngine.CallLuaFunction("OnPublicAuthoritiesStopXRatedBroadcast")
	End Method


	Method CallOnPublicAuthoritiesConfiscateProgrammeLicence(confiscatedLicence:TProgrammeLicence, targetLicence:TProgrammeLicence)
		Local args:Object[2]
		args[0] = confiscatedLicence
		args[1] = targetLicence
		if (KIRunning) then LuaEngine.CallLuaFunction("OnPublicAuthoritiesConfiscateProgrammeLicence")
	End Method


	Method CallOnLeaveRoom(roomId:int)
	    Try
			Local args:Object[1]
			args[0] = String(roomId)
			if (KIRunning) then LuaEngine.CallLuaFunction("OnLeaveRoom", args)
		Catch ex:Object
			TLogger.log("KI.CallOnLeaveRoom", "Script "+scriptFileName+" does not contain function ~qOnLeaveRoom~q.", LOG_ERROR)
		End Try
	End Method


	Method CallOnReachRoom(roomId:Int)
	    Try
			Local args:Object[1]
			args[0] = String(roomId)
			if (KIRunning) then LuaEngine.CallLuaFunction("OnReachRoom", args)
		Catch ex:Object
			TLogger.log("KI.CallOnReachRoom", "Script "+scriptFileName+" does not contain function ~qOnReachRoom~q.", LOG_ERROR)
		End Try
	End Method



	Method CallOnBeginEnterRoom(roomId:int, result:int)
	    Try
			Local args:Object[2]
			args[0] = String(roomId)
			args[1] = String(result)
			if (KIRunning) then LuaEngine.CallLuaFunction("OnBeginEnterRoom", args)
		Catch ex:Object
			TLogger.log("KI.CallOnBeginEnterRoom", "Script "+scriptFileName+" does not contain function ~qOnBeginEnterRoom~q.", LOG_ERROR)
		End Try
	End Method
	

	Method CallOnEnterRoom(roomId:int)
	    Try
			Local args:Object[1]
			args[0] = String(roomId)
			if (KIRunning) then LuaEngine.CallLuaFunction("OnEnterRoom", args)
		Catch ex:Object
			TLogger.log("KI.CallOnEnterRoom", "Script "+scriptFileName+" does not contain function ~qOnEnterRoom~q.", LOG_ERROR)
		End Try
	End Method

	
	Method CallOnDayBegins()
	    Try
			if (KIRunning) then LuaEngine.CallLuaFunction("OnDayBegins", Null)
		Catch ex:Object
			TLogger.log("KI.CallOnDayBegins", "Script "+scriptFileName+" does not contain function ~qOnDayBegins~q.", LOG_ERROR)
		End Try
	End Method
	

	Method CallOnMoneyChanged()
	    Try
			if (KIRunning) then LuaEngine.CallLuaFunction("OnMoneyChanged", Null)
		Catch ex:Object
			TLogger.log("KI.CallOnMoneyChanged", "Script "+scriptFileName+" does not contain function ~qOnMoneyChanged~q.", LOG_ERROR)
		End Try
	End Method

	Method CallOnMalfunction()
	    Try
			if (KIRunning) then LuaEngine.CallLuaFunction("OnMalfunction", Null)
		Catch ex:Object
			TLogger.log("KI.CallOnMalfunction", "Script "+scriptFileName+" does not contain function ~qOnMalfunction~q.", LOG_ERROR)
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
rem
	unused
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
endrem
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
			GetRoomCollection().GetFirstByDetails(...)  - get the first found room
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
		Return GetPlayerCollection().Get(Self.ME).isInRoom(roomname, checkFromRoom)
	End Method


	Method _PlayerOwnsRoom:Int()
		Return Self.ME = GetPlayerCollection().Get(Self.ME).GetFigure().inRoom.owner
	End Method


	Function Create:TLuaFunctions(pPlayerId:Int)
		Local ret:TLuaFunctions = New TLuaFunctions

		ret.ME = pPlayerId

		ret.ROOM_MOVIEAGENCY = GetRoomCollection().GetFirstByDetails("movieagency").id
		ret.ROOM_ADAGENCY = GetRoomCollection().GetFirstByDetails("adagency").id
		ret.ROOM_ROOMBOARD = GetRoomCollection().GetFirstByDetails("roomboard").id
		ret.ROOM_PORTER = GetRoomCollection().GetFirstByDetails("porter").id
		ret.ROOM_BETTY = GetRoomCollection().GetFirstByDetails("betty").id
		ret.ROOM_SUPERMARKET = GetRoomCollection().GetFirstByDetails("supermarket").id
		ret.ROOM_ROOMAGENCY = GetRoomCollection().GetFirstByDetails("roomagency").id
		ret.ROOM_PEACEBROTHERS = GetRoomCollection().GetFirstByDetails("peacebrothers").id
		ret.ROOM_SCRIPTAGENCY = GetRoomCollection().GetFirstByDetails("scriptagency").id
		ret.ROOM_NOTOBACCO = GetRoomCollection().GetFirstByDetails("notobacco").id
		ret.ROOM_TOBACCOLOBBY = GetRoomCollection().GetFirstByDetails("tobaccolobby").id
		ret.ROOM_GUNSAGENCY = GetRoomCollection().GetFirstByDetails("gunsagency").id
		ret.ROOM_VRDUBAN = GetRoomCollection().GetFirstByDetails("vrduban").id
		ret.ROOM_FRDUBAN = GetRoomCollection().GetFirstByDetails("frduban").id

		ret.ROOM_ARCHIVE_PLAYER_ME = GetRoomCollection().GetFirstByDetails("archive", pPlayerId).id
		ret.ROOM_NEWSAGENCY_PLAYER_ME = GetRoomCollection().GetFirstByDetails("news", pPlayerId).id
		ret.ROOM_BOSS_PLAYER_ME = GetRoomCollection().GetFirstByDetails("boss", pPlayerId).id
		ret.ROOM_OFFICE_PLAYER_ME = GetRoomCollection().GetFirstByDetails("office", pPlayerId).id

		REM
		ret.ROOM_START_STUDIO_PLAYER_ME = GetRoomCollection().GetFirstByDetails("studio", pPlayerId).id

		ret.ROOM_ARCHIVE_PLAYER1 = GetRoomCollection().GetFirstByDetails("archive", 1).id
		ret.ROOM_NEWSAGENCY_PLAYER1 = GetRoomCollection().GetFirstByDetails("news", 1).id
		ret.ROOM_BOSS_PLAYER1 = GetRoomCollection().GetFirstByDetails("boss", 1).id
		ret.ROOM_OFFICE_PLAYER1 = GetRoomCollection().GetFirstByDetails("office", 1).id
		ret.ROOM_START_STUDIO_PLAYER1 = GetRoomCollection().GetFirstByDetails("studio", 1).id

		ret.ROOM_ARCHIVE_PLAYER2 = GetRoomCollection().GetFirstByDetails("archive", 2).id
		ret.ROOM_NEWSAGENCY_PLAYER2 = GetRoomCollection().GetFirstByDetails("news", 2).id
		ret.ROOM_BOSS_PLAYER2 = GetRoomCollection().GetFirstByDetails("boss", 2).id
		ret.ROOM_OFFICE_PLAYER2 = GetRoomCollection().GetFirstByDetails("office", 2).id
		ret.ROOM_START_STUDIO_PLAYER2 = GetRoomCollection().GetFirstByDetails("studio", 2).id

		ret.ROOM_ARCHIVE_PLAYER3 = GetRoomCollection().GetFirstByDetails("archive", 3).id
		ret.ROOM_NEWSAGENCY_PLAYER3 = GetRoomCollection().GetFirstByDetails("news", 3).id
		ret.ROOM_BOSS_PLAYER3 = GetRoomCollection().GetFirstByDetails("boss", 3).id
		ret.ROOM_OFFICE_PLAYER3 = GetRoomCollection().GetFirstByDetails("office", 3).id
		ret.ROOM_START_STUDIO_PLAYER3 = GetRoomCollection().GetFirstByDetails("studio", 3).id

		ret.ROOM_ARCHIVE_PLAYER4 = GetRoomCollection().GetFirstByDetails("archive", 4).id
		ret.ROOM_NEWSAGENCY_PLAYER4 = GetRoomCollection().GetFirstByDetails("news", 4).id
		ret.ROOM_BOSS_PLAYER4 = GetRoomCollection().GetFirstByDetails("boss", 4).id
		ret.ROOM_OFFICE_PLAYER4 = GetRoomCollection().GetFirstByDetails("office", 4).id
		ret.ROOM_START_STUDIO_PLAYER4 = GetRoomCollection().GetFirstByDetails("studio", 4).id
		End Rem

		Return ret
	End Function


	Method PrintOut:Int(text:String)
		text = StringHelper.RemoveUmlauts(text)
		'text = StringHelper.UTF8toISO8859(text)

		TLogger.log("AI "+self.ME, text, LOG_AI)
		Return self.RESULT_OK
	EndMethod


	'only printed if TLogger.setPrintMode(LOG_AI | LOG_DEBUG) is set
	Method PrintOutDebug:int(text:string)
		text = StringHelper.RemoveUmlauts(text)

		TLogger.log("AI "+self.ME+" DEBUG", text, LOG_AI & LOG_DEBUG)
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
		return GetRoomCollection().GetFirstByDetails(roomName, owner)
	End Method

	Method GetRoom:TRoom(id:int)
		return GetRoomCollection().Get(id)
	End Method


	Method SendToChat:Int(ChatText:String)
		'emit an event, we received a chat message
		local sendToChannels:int = TGUIChat.GetChannelsFromText(ChatText)
		EventManager.triggerEvent( TEventSimple.Create( "chat.onAddEntry", new TData.AddNumber("senderID", self.ME).AddNumber("channels", sendToChannels).AddString("text",ChatText) ) )

		Return 1
	EndMethod


	Method getPlayerRoom:Int()
		Local room:TRoomBase = GetPlayerCollection().Get(self.ME).GetFigure().inRoom
		If room <> Null Then Return room.id Else Return self.RESULT_NOTFOUND
	End Method


	Method getPlayerTargetRoom:Int()
		local player:TPlayer = GetPlayerCollection().Get(self.ME)
		local roomDoor:TRoomDoor = TRoomDoor(player.figure.GetTarget())
		
		If roomDoor and roomDoor.GetRoom() then Return roomDoor.GetRoom().id

		Return self.RESULT_NOTFOUND
	End Method


	'return the floor of a room
	'attention: the floor of the first found door is returned
	Method getRoomFloor:Int(roomId:Int = 0)
		Local room:TRoom = GetRoomCollection().Get(roomId)
		if room
			Local door:TRoomDoorBase = TRoomDoor.GetMainDoorToRoom(room)
			If door Then Return door.GetOnFloor()
		endif
		Return self.RESULT_NOTFOUND
	End Method


	'send figure to a specific room
	'attention: the first found door is used
	Method doGoToRoom:Int(roomId:Int = 0)
		Local room:TRoom = GetRoomCollection().Get(roomId)

		Local door:TRoomDoorBase = TRoomDoor.GetMainDoorToRoom(room)
		If door
			GetPlayerCollection().Get(self.ME).GetFigure().SendToDoor(door)
			Return self.RESULT_OK
		endif

		Return self.RESULT_NOTFOUND
	End Method


	Method doGoToRelative:Int(relX:Int = 0, relYFloor:Int = 0) 'Nur x wird unterstuetzt. Negativ: Nach links; Positiv: nach rechts
		GetPlayerCollection().Get(self.ME).GetFigure().GoToCoordinatesRelative(relX, relYFloor)
		Return self.RESULT_OK
	End Method


	Method isRoomUnused:Int(roomId:Int = 0)
		Local Room:TRoom = GetRoomCollection().Get(roomId)
		If not Room then return self.RESULT_NOTFOUND
		if not Room.hasOccupant() then return self.RESULT_OK

		If Room.isOccupant( GetPlayerCollection().Get(Self.ME).figure ) then Return -1
		Return self.RESULT_INUSE
	End Method


	'returns how many time is gone since game/app start
	Method getTimeGone:Int()
		Return Time.GetTimeGone()
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
	Method of_buyStation:int(x:int, y:int)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if GetStationMapCollection().GetMap(ME).BuyStation(x, y)
			Return self.RESULT_OK
		else
			Return self.RESULT_FAILED
		endif
	End Method


	Method of_sellStation:int(listPosition:int)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if GetStationMapCollection().GetMap(ME).SellStation(listPosition)
			Return self.RESULT_OK
		else
			Return self.RESULT_FAILED
		endif
	End Method


	'returns the broadcast material (in result.data) at the given slot
	Method of_getAdvertisementSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		Local material:TBroadcastMaterial = GetPlayerCollection().Get(Self.ME).GetProgrammePlan().GetAdvertisement(day, hour)
		If material
			Return TLuaFunctionResult.Create(self.RESULT_OK, material)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method of_getAdContractCount:Int()
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		Return GetPlayerProgrammeCollectionCollection().Get(Self.ME).GetAdContractCount()
	End Method


	Method of_getAdContractAtIndex:TAdContract(arrayIndex:Int=-1)
		If Not _PlayerInRoom("office", True) Then Return Null

		Local obj:TAdContract = GetPlayerCollection().Get(Self.ME).GetProgrammeCollection().GetAdContractAtIndex(arrayIndex)
		If obj Then Return obj Else Return Null
	End Method


	Method of_getAdContractByID:TAdContract(id:Int=-1)
		If Not _PlayerInRoom("office", True) Then Return Null

		Local obj:TAdContract = GetPlayerCollection().Get(Self.ME).GetProgrammeCollection().GetAdContract(id)
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
		local broadcastMaterial:TBroadcastMaterial = GetPlayerCollection().Get(self.ME).GetProgrammeCollection().GetBroadcastMaterial(materialSource)

		if GetPlayerCollection().Get(self.ME).GetProgrammePlan().SetAdvertisementSlot(broadcastMaterial, day, hour)
			return self.RESULT_OK
		else
			return self.RESULT_NOTALLOWED
		endif
	End Method


	'returns the broadcast material (in result.data) at the given slot
	Method of_getProgrammeSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		Local material:TBroadcastMaterial = GetPlayerCollection().Get(Self.ME).GetProgrammePlan().GetProgramme(day, hour)
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
		local broadcastMaterial:TBroadcastMaterial = GetPlayerCollection().Get(self.ME).GetProgrammeCollection().GetBroadcastMaterial(materialSource)

		if GetPlayerCollection().Get(self.ME).GetProgrammePlan().SetProgrammeSlot(broadcastMaterial, day, hour)
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

		local player:TPlayer = GetPlayerCollection().Get(self.ME)

		'Es ist egal ob ein Spieler einen Schluessel fuer den Raum hat,
		'Es ist nur schauen erlaubt fuer "Fremde"
		If Self.ME <> player.GetFigure().inRoom.owner Then Return self.RESULT_WRONGROOM

		If ObjectID = 0 'News bei slotID loeschen
			if player.GetProgrammePlan().RemoveNews(null, slot)
				Return self.RESULT_OK
			else
				Return self.RESULT_NOTFOUND
			endif
		Else
			Local news:TBroadcastMaterial = player.GetProgrammeCollection().GetNews(ObjectID)
			If not news or not TNews(news) then Return self.RESULT_NOTFOUND
			player.GetProgrammePlan().SetNews(TNews(news), slot)

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

		local contract:TAdContract = GetPlayerCollection().Get(self.ME).GetProgrammeCollection().GetUnsignedAdContractFromSuitcase(contractID)
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

		For local licence:TProgrammeLicence = eachin GetPlayerCollection().Get(self.ME).GetProgrammeCollection().suitcaseProgrammeLicences
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