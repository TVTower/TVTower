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
		LuaEngine.RegisterBlitzmaxObject("MY", GetPlayer(PlayerID))
		'the game object
		LuaEngine.RegisterBlitzmaxObject("Game", Game)
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
		If not GetPlayer(PlayerID)
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


	Method CallOnProgrammeLicenceAuctionGetOutbid(licence:TProgrammeLicence, bid:int, bidderID:int)
		Local args:Object[3]
		args[0] = licence
		args[1] = string(bid)
		args[2] = string(bidderID)
		if (KIRunning) then LuaEngine.CallLuaFunction("OnProgrammeLicenceAuctionGetOutbid", args)
	End Method


	Method CallOnProgrammeLicenceAuctionWin(licence:TProgrammeLicence, bid:int)
		Local args:Object[2]
		args[0] = licence
		args[1] = string(bid)
		if (KIRunning) then LuaEngine.CallLuaFunction("OnProgrammeLicenceAuctionWin", args)
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
		if (KIRunning) then LuaEngine.CallLuaFunction("OnPublicAuthoritiesConfiscateProgrammeLicence", args)
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
	

	Method CallOnMoneyChanged(value:int, reason:int, reference:TNamedGameObject)
	    Try
			Local args:Object[3]
			args[0] = String(value)
			args[1] = String(reason)
			args[2] = TNamedGameObject(reference)
			if (KIRunning) then LuaEngine.CallLuaFunction("OnMoneyChanged", args)
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
	Const RESULT_OK:int        =   1
	Const RESULT_FAILED:int    =   0
	Const RESULT_WRONGROOM:int =  -2
	Const RESULT_NOKEY:int     =  -4
	Const RESULT_NOTFOUND:int  =  -8
	Const RESULT_NOTALLOWED:int= -16
	Const RESULT_INUSE:int     = -32

	'const + helpers
	Field Rules:TGameRules
	Field Constants:TVTGameConstants

	'get instantiated during "new"
	Field ME:Int
	
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
		DO NOT use ROOM constants (even "room_ME" should be deprecated)
		a) avoids modability
		b) AI can request room using
			GetFirstRoomByDetails("office", playerNumber)  - get the first found room
			GetRoomsByDetails("office") - get array of found rooms
			GetRoom(roomID) 
		    ID is room.GetID()
		c) a player can have multiple studios - how to handle this with const?
		d) rooms could change "content" and no longer exist
	EndRem

	Method _PlayerInRoom:Int(roomname:String)
		'If checkFromRoom
			'from room has to be set AND inroom <> null (no building!)
		'	GetPlayer(Self.ME).isComingFromRoom(roomname) and GetPlayer(Self.ME).isInRoom()
		'Else
			Return GetPlayer(Self.ME).isInRoom(roomname)
		'EndIf
	End Method


	Method _PlayerOwnsRoom:Int()
		Return Self.ME = GetPlayer(Self.ME).GetFigure().inRoom.owner
	End Method


	Function Create:TLuaFunctions(pPlayerId:Int)
		Local ret:TLuaFunctions = New TLuaFunctions

		ret.Rules = GameRules
		ret.Constants = GameConstants

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

		Return ret
	End Function

	Method GetArchiveIdOfPlayer:Int(id:Int)
		Return GetRoomCollection().GetFirstByDetails("archive", id).id
	End Method

	Method GetNewsAgencyIdOfPlayer:Int(id:Int)
		Return GetRoomCollection().GetFirstByDetails("news", id).id
	End Method

	Method GetBossOfficeIdOfPlayer:Int(id:Int)
		Return GetRoomCollection().GetFirstByDetails("boss", id).id
	End Method

	Method GetOfficeIdOfPlayer:Int(id:Int)
		Return GetRoomCollection().GetFirstByDetails("office", id).id
	End Method


	Method PrintOut:Int(text:String)
		text = StringHelper.RemoveUmlauts(text)
		'text = StringHelper.UTF8toISO8859(text)

		TLogger.log("AI "+self.ME, text, LOG_AI)
		Return self.RESULT_OK
	End Method


	'only printed if TLogger.setPrintMode(LOG_AI | LOG_DEBUG) is set
	Method PrintOutDebug:int(text:string)
		text = StringHelper.RemoveUmlauts(text)

		TLogger.log("AI "+self.ME+" DEBUG", text, LOG_AI & LOG_DEBUG)
		Return self.RESULT_OK
	End Method


	Method GetFirstRoomByDetails:TRoom(roomName:String, owner:Int=-1000)
		return GetRoomCollection().GetFirstByDetails(roomName, owner)
	End Method


	Method GetRoomsByDetails:TRoom[](roomName:String, owner:Int=-1000)
		return GetRoomCollection().GetAllByDetails(roomName, owner)
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
		Local room:TRoomBase = GetPlayer(self.ME).GetFigure().inRoom
		If room Then Return room.id

		Return self.RESULT_NOTFOUND
	End Method


	Method getPlayerTargetRoom:Int()
		local roomDoor:TRoomDoor = TRoomDoor(GetPlayer(self.ME).GetFigure().GetTarget())
		If roomDoor and roomDoor.GetRoom() then Return roomDoor.GetRoom().id

		Return self.RESULT_NOTFOUND
	End Method


	'return the floor of a room
	'attention: the floor of the first found door is returned
	Method getRoomFloor:Int(roomId:Int = 0)
		Local room:TRoom = GetRoomCollection().Get(roomId)
		if room
			Local door:TRoomDoorBase = GetRoomDoorCollection().GetMainDoorToRoom(room.id)
			If door Then Return door.GetOnFloor()
		endif

		Return self.RESULT_NOTFOUND
	End Method


	'send figure to a specific room
	'attention: the first found door is used
	Method doGoToRoom:Int(roomId:Int = 0)
		Local room:TRoom = GetRoomCollection().Get(roomId)
		If room
			Local door:TRoomDoorBase = GetRoomDoorCollection().GetMainDoorToRoom(room.id)
			If door
				GetPlayer(self.ME).GetFigure().SendToDoor(door)
				Return self.RESULT_OK
			EndIf
		endif

		Return self.RESULT_NOTFOUND
	End Method


	Method doGoToRelative:Int(relX:Int = 0, relYFloor:Int = 0) 'Nur x wird unterstuetzt. Negativ: Nach links; Positiv: nach rechts
		GetPlayer(self.ME).GetFigure().GoToCoordinatesRelative(relX, relYFloor)
		Return self.RESULT_OK
	End Method


	Method isRoomUnused:Int(roomId:Int = 0)
		Local Room:TRoom = GetRoomCollection().Get(roomId)
		If not Room then return self.RESULT_NOTFOUND
		if not Room.hasOccupant() then return self.RESULT_OK

		If Room.isOccupant( GetPlayer(self.ME).figure ) then Return -1
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


	Method getPotentialAudiencePercentageForHour:Float(hour:int = -1)
		'percentage of each population group watching now
		'local percentage:TAudience = TBroadcast.GetPotentialAudiencePercentageForHour(hour).GetAvg()

		'percentage of each group in the population
		local population:TAudience = TAudience.CreateWithBreakdown(1.0)
		'GetPotentialAudienceForHour multiplies percentage watching now
		'with the given population percentage
		'-> GetSum() contains the total percentage of the population
		'   watching TV now
		return TBroadcast.GetPotentialAudienceForHour(population, hour).GetSum()
	End Method


	Method getEvaluatedAudienceQuote:Int(hour:Int = -1, licenceID:Int = -1, lastQuotePercentage:Float = 0.1, audiencePercentageBasedOnHour:Float=-1)
		'TODO: Statt dem audiencePercentageBasedOnHour-Parameter könnte
		'      auch das noch unbenutzte "hour" den generellen Quotenwert
		'      in der angegebenen Stunde mit einem etwas umgebauten
		'      "calculateMaxAudiencePercentage" (ohne Zufallswerte und
		'      ohne die globale Variable zu verändern) errechnen.

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


	Method convertToAdContract:TAdContract(obj:object)
		return TAdContract(obj)
	End Method

	Method convertToProgrammeLicence:TProgrammeLicence(obj:object)
		return TProgrammeLicence(obj)
	End Method



	'=== OFFICE ===
	'players bureau

	'== STATIONMAP ==
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

		if GetStationMap(self.ME).SellStation(listPosition)
			Return self.RESULT_OK
		else
			Return self.RESULT_FAILED
		endif
	End Method


	Method of_getStationCount:Int(playerID:int = -1)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if playerID = -1 then playerID = self.ME

		Return GetStationMap(playerID).GetStationCount()
	End Method


	Method of_getStationAtIndex:TStation(playerID:int = -1, arrayIndex:Int = -1)
		If Not _PlayerInRoom("office") Then Return Null

		if playerID = -1 then playerID = self.ME

		Return GetStationMap(playerID).GetStationAtIndex(arrayIndex)
	End Method



	'== PROGRAMME PLAN ==

	'returns the broadcast material (in result.data) at the given slot
	Method of_getAdvertisementSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		Local material:TBroadcastMaterial = GetPlayer(self.ME).GetProgrammePlan().GetAdvertisement(day, hour)
		If material
			Return TLuaFunctionResult.Create(self.RESULT_OK, material)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method of_getAdContractCount:Int()
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		Return GetPlayerProgrammeCollectionCollection().Get(Self.ME).GetAdContractCount()
	End Method


	Method of_getAdContractAtIndex:TAdContract(arrayIndex:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Local obj:TAdContract = GetPlayer(self.ME).GetProgrammeCollection().GetAdContractAtIndex(arrayIndex)
		If obj Then Return obj Else Return Null
	End Method


	Method of_getAdContractByID:TAdContract(id:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Local obj:TAdContract = GetPlayer(self.ME).GetProgrammeCollection().GetAdContract(id)
		If obj Then Return obj Else Return Null
	End Method

	'Set content of a programme slot
	'=====
	'materialSource might be "null" to clear a time slot
	'or of types: "TProgrammeLicence" or "TAdContract"
	'returns: (TVT.)RESULT_OK, RESULT_WRONGROOM, RESULT_NOTFOUND
	Method of_setAdvertisementSlot:Int(materialSource:object, day:Int=-1, hour:Int=-1)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM
		'even if player has access to room, only owner can manage things here
		If Not _PlayerOwnsRoom() Then Return self.RESULT_WRONGROOM

		'create a broadcast material out of the given source
		local broadcastMaterial:TBroadcastMaterial = GetPlayer(self.ME).GetProgrammeCollection().GetBroadcastMaterial(materialSource)

		if GetPlayer(self.ME).GetProgrammePlan().SetAdvertisementSlot(broadcastMaterial, day, hour)
			return self.RESULT_OK
		else
			return self.RESULT_NOTALLOWED
		endif
	End Method


	'returns the broadcast material (in result.data) at the given slot
	Method of_getProgrammeSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		Local material:TBroadcastMaterial = GetPlayer(self.ME).GetProgrammePlan().GetProgramme(day, hour)
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
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM
		'even if player has access to room, only owner can manage things here
		If Not _PlayerOwnsRoom() Then Return self.RESULT_WRONGROOM

		'create a broadcast material out of the given source
		local broadcastMaterial:TBroadcastMaterial = GetPlayer(self.ME).GetProgrammeCollection().GetBroadcastMaterial(materialSource)

		if GetPlayer(self.ME).GetProgrammePlan().SetProgrammeSlot(broadcastMaterial, day, hour)
			return self.RESULT_OK
		else
			return self.RESULT_NOTALLOWED
		endif
	End Method



	'=== NEWS ROOM ===

	'returns the aggression level of the given terrorist group.
	'Invalid groups return the maximum of all.
	'Currently valid are "0" and "1"
	Method ne_getTerroristAggressionLevel:Int(terroristGroup:int=-1)
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return self.RESULT_WRONGROOM

		return GetNewsAgency().GetTerroristAggressionLevel(terroristGroup)
	End Method

	
	'returns the maximum level the aggression of terrorists could have
	Method ne_getTerroristAggressionLevelMax:Int()
		return GetNewsAgency().terroristAggressionLevelMax
	End Method


	Method ne_doNewsInPlan:Int(slot:int=1, ObjectID:Int = -1)
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return self.RESULT_WRONGROOM

		local player:TPlayer = GetPlayer(self.ME)

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



	'=== SPOT AGENCY ===

	Method sa_getSpotCount:Int()
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		Return RoomHandler_AdAgency.GetInstance().GetContractsInStockCount()
	End Method


	Method sa_getSpot:TLuaFunctionResult(position:Int=-1)
		If Not _PlayerInRoom("adagency") then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		'out of bounds?
		If position >= RoomHandler_AdAgency.GetInstance().GetContractsInStockCount() Or position < 0 then Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)

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

		local contract:TAdContract = GetPlayer(self.ME).GetProgrammeCollection().GetUnsignedAdContractFromSuitcase(contractID)
		'this does not sign - signing is done when leaving the room!
		if contract and RoomHandler_AdAgency.GetInstance().TakeContractFromPlayer( contract, self.ME )
			Return self.RESULT_OK
		else
			Return self.RESULT_NOTFOUND
		endif
	End Method



	'=== MOVIE AGENCY ===
	'main screen
	
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

		For local licence:TProgrammeLicence = eachin GetPlayer(self.ME).GetProgrammeCollection().suitcaseProgrammeLicences
			if licence.id = licenceID then return RoomHandler_MovieAgency.GetInstance().BuyProgrammeLicenceFromPlayer(licence)
		Next
		Return self.RESULT_NOTFOUND
	End Method



	'=== MOVIE DEALER ===
	'Movie Agency - Auctions

	Method md_getAuctionMovieBlock:TAuctionProgrammeBlocks(ArrayID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return null
		If ArrayID >= TAuctionProgrammeBlocks.List.Count() Or arrayID < 0 Then Return null

		Local Block:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(TAuctionProgrammeBlocks.List.ValueAtIndex(ArrayID))
		If Block and Block.GetLicence() Then Return Block Else Return null
	End Method


	Method md_getAuctionProgrammeLicence:TLuaFunctionResult(ArrayID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		If ArrayID >= TAuctionProgrammeBlocks.List.Count() Or arrayID < 0 then Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)

		Local Block:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(TAuctionProgrammeBlocks.List.ValueAtIndex(ArrayID))
		If Block and Block.licence
			Return TLuaFunctionResult.Create(self.RESULT_OK, Block.licence)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif		
	End Method

'untested
	Method md_getAuctionProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		return TAuctionProgrammeBlocks.List.count()
	End Method


	Method md_doBidAuctionProgrammeLicence:Int(licenceID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM


		For local Block:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			If Block.GetLicence() and Block.licence.GetReferenceID() = licenceID Then Return Block.SetBid( self.ME )
		Next

		Return self.RESULT_NOTFOUND
	End Method


	Method md_doBidAuctionProgrammeLicenceAtIndex:Int(ArrayID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local Block:TAuctionProgrammeBlocks = self.md_getAuctionMovieBlock(ArrayID)
		If Block and Block.GetLicence() then Return Block.SetBid( self.ME ) else Return self.RESULT_NOTFOUND
	End Method

'untested
	Method md_GetAuctionProgrammeLicenceNextBid:Int(ArrayID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local Block:TAuctionProgrammeBlocks = self.md_getAuctionMovieBlock(ArrayID)
		If Block and Block.GetLicence() then Return Block.GetNextBid() else Return self.RESULT_NOTFOUND
	End Method

'untested
	Method md_GetAuctionProgrammeLicenceHighestBidder:Int(ArrayID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local Block:TAuctionProgrammeBlocks = self.md_getAuctionMovieBlock(ArrayID)
		If Block and Block.GetLicence() then Return Block.bestBidder else Return self.RESULT_NOTFOUND
	End Method



	'=== BOSS ROOM ===

	'returns maximum credit limit (regardless of already taken credit)
	Method bo_getCreditMaximum:int()
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		return GetPlayerBoss(self.ME).GetCreditMaximum()
	End Method


	'returns how much credit the boss will give (maximum minus taken credit)
	Method bo_getCreditAvailable:int()
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		return GetPlayerBase(self.ME).GetCreditAvailable()
	End Method


	'amounts bigger than the available credit just take all possible
	Method bo_doTakeCredit:int(amount:int)
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		if GetPlayerBoss(self.ME).PlayerTakesCredit(amount)
			return True
		else
			return self.RESULT_FAILED
		endif
	End Method


	'amounts bigger than the credit taken will repay everything
	'amounts bigger than the owned money will fail
	Method bo_doRepayCredit:int(amount:int)
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		if GetPlayerBoss(self.ME).PlayerTakesCredit(amount)
			return True
		else
			return self.RESULT_FAILED
		endif
	End Method

	'returns the mood of the boss - rounded to 10% steps
	'(makes it a bit harder for the AI)
	'TODO: remove step rounding if players get a exact value displayed
	'      somehow
	Method bo_getBossMoodlevel:int()
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM
		return int(GetPlayerBoss(Self.ME).GetMood()) / 10
	End Method


	'=== ROOM BOARD ===
	'the plan on the basement which enables switching room signs

	Method rb_GetSignCount:Int()
		If Not _PlayerInRoom("roomboard") Then Return self.RESULT_WRONGROOM

		return GetRoomBoard().GetSignCount()
	End Method


	Method rb_GetSignAtIndex:TLuaFunctionResult(arrayIndex:Int = -1)
		If Not _PlayerInRoom("roomboard") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		Local sign:TRoomBoardSign = GetRoomBoard().GetSignAtIndex(arrayIndex)
		If sign
			Return TLuaFunctionResult.Create(self.RESULT_OK, sign)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif		
	End Method


	'returns the sign at the given position
	Method rb_GetSignAtPosition:TLuaFunctionResult(signSlot:int, signFloor:int)
		If Not _PlayerInRoom("roomboard") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local sign:TRoomBoardSign = GetRoomBoard().GetSignByCurrentPosition(signSlot, signFloor)
		If sign
			Return TLuaFunctionResult.Create(self.RESULT_OK, sign)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif		
	End Method


	'returns the sign which originally was at the given position
	'(might be the same if it wasnt switched)
	Method rb_GetOriginalSignAtPosition:TLuaFunctionResult(signSlot:int, signFloor:int)
		If Not _PlayerInRoom("roomboard") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local sign:TRoomBoardSign = GetRoomBoard().GetSignByOriginalPosition(signSlot, signFloor)
		If sign
			Return TLuaFunctionResult.Create(self.RESULT_OK, sign)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif		
	End Method


	'returns the first sign leading to the given room(ID)
	Method rb_GetFirstSignOfRoom:TLuaFunctionResult(roomID:int)
		If Not _PlayerInRoom("roomboard") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local sign:TRoomBoardSign = GetRoomBoard().GetFirstSignByRoom(roomID)
		If sign
			Return TLuaFunctionResult.Create(self.RESULT_OK, sign)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif		
	End Method


	'switch two existing signs on the board
	Method rb_SwitchSigns:int(signA:TRoomBoardSign, signB:TRoomBoardSign)
		If Not _PlayerInRoom("roomboard") Then Return self.RESULT_WRONGROOM

		If GetRoomBoard().SwitchSigns(signA, signB)
			Return self.RESULT_OK
		Else
			Return self.RESULT_FAILED
		Endif
	End Method


	'switch two existing signs on the board
	Method rb_SwitchSignsByID:int(signAId:Int, signBId:Int)
		If Not _PlayerInRoom("roomboard") Then Return self.RESULT_WRONGROOM

		Local signA:TRoomBoardSign = GetRoomBoard().GetSignById(signAId)
		Local signB:TRoomBoardSign = GetRoomBoard().GetSignById(signBId)		

		If GetRoomBoard().SwitchSigns(signA, signB)
			Return self.RESULT_OK
		Else
			Return self.RESULT_FAILED
		Endif		
	End Method


	'switch signs on the given positions.
	'a potential sign on slotA/floorA will get moved to slotB/floorB
	'and vice versa. It is NOT needed to have to valid signs on there 
	Method rb_SwitchSignPositions:int(slotA:int, floorA:int, slotB:int, floorB:int)
		If Not _PlayerInRoom("roomboard") Then Return self.RESULT_WRONGROOM

		If GetRoomBoard().SwitchSignPositions(slotA, floorA, slotB, floorB)
			Return self.RESULT_OK
		Else
			Return self.RESULT_FAILED
		Endif		
	End Method


	Method rb_GetSignSlotCount:int()
		return GetRoomBoard().slotMax
	End Method


	Method rb_GetSignFloorCount:int()
		return GetRoomBoard().floorMax
	End Method


	'
	'LUA_be_getSammyPoints
	'LUA_be_getBettyLove
	'LUA_be_getSammyGenre
	'

	'LUA_ar_getMovieInBagCount
	'LUA_ar_getMovieInBag
	'LUA_ar_doMovieInBag
	'LUA_ar_doMovieOutBag
	'
End Type
