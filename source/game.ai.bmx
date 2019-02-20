SuperStrict
Import "Dig/base.util.logger.bmx"
Import "Dig/base.gfx.gui.chat.bmx"
Import "game.ai.base.bmx"
Import "game.gamerules.bmx"
Import "game.gameconstants.bmx"
Import "game.room.bmx"
Import "game.room.roomdoor.bmx"
Import "game.broadcast.audience.bmx"
Import "game.programme.adcontract.bmx"
Import "game.programme.programmelicence.bmx"
'Import "game.programme.newsevent.bmx"
Import "game.broadcastmaterial.advertisement.bmx"

Import "game.player.programmeplan.bmx"
Import "game.player.boss.bmx"

Import "game.newsagency.bmx"

Import "game.misc.roomboardsign.bmx"
Import "game.game.base.bmx"

Import "game.achievements.base.bmx"
Import "game.award.base.bmx"

Import "game.roomhandler.movieagency.bmx"
Import "game.roomhandler.adagency.bmx"


Global AiLog:TLogFile[4]
For local i:int = 0 to 3
	AiLog[i] = TLogFile.Create("AI Log v1.0", "log.ai"+(i+1)+".txt", True)
Next


Type TAi extends TAiBase
	'override
	Method Create:TAi(playerID:Int, luaScriptFileName:String)
		Super.Create(playerID, luaScriptFileName)
		Return self
	End Method


	Method Start()
		Super.Start()

		'=== LINK SPECIAL OBJECTS ===
		local LuaEngine:TLuaEngine = GetLuaEngine()

		'own functions for player
		LuaEngine.RegisterBlitzmaxObject("TVT", TLuaFunctions.Create(PlayerID))
		'the player
		LuaEngine.RegisterBlitzmaxObject("MY", GetPlayerBase(PlayerID))
		'the game object
		LuaEngine.RegisterBlitzmaxObject("Game", GetGameBase())
		'the game object
		LuaEngine.RegisterBlitzmaxObject("WorldTime", GetWorldTime())

		'register source and available objects
		LuaEngine.RegisterToLua()
	End Method


	'override
	Method AddLog(title:string, text:string, logLevel:int)
		Super.AddLog(title, text, logLevel)
		AiLog[Self.playerID-1].AddLog(text, True)
	End Method


	'only calls the AI "onTick" if the calculated interval passed
	'in our case this is:
	'- more than 1 RealTime second passed since last tick
	'or
	'- another InGameMinute passed since last tick
	Method ConditionalCallOnTick()
		'time between two ticks = time between two GameMinutes or maximum
		'1 second (eg. if speed is 0)
		local tickInterval:Long = 1000
		'if GetWorldTime().GetVirtualMinutesPerSecond() > 0
		'	tickInterval = Min(1000.0 , 1000.0 / GetWorldTime().GetVirtualMinutesPerSecond())
		'endif

		'more time gone than the set interval?
		if abs(Time.GetTimeGone() - LastTickTime) > tickInterval or LastTickMinute <> GetWorldTime().GetDayMinute()
			'store time/minute of this tick so waiting-period starts
			'all over
			LastTickTime = Time.GetTimeGone()
			LastTickMinute = GetWorldTime().GetDayMinute()

			Ticks :+ 1

			if not AiRunning then return

			Local args:Object[2]
			args[0] = String(LastTickTime)
			args[1] = String(Ticks)

			CallLuaFunction("OnTick", args)
		endif
	End Method


	Method CallOnLoadState()
		'load/save regardless of running-state
		'if not AiRunning then return

		Local args:Object[1]
		args[0] = self.scriptSaveState

		CallLuaFunction("OnLoadState", args)
	End Method


	Method CallOnSaveState()
		'load/save regardless of running-state
		'if not AiRunning then return

		'reset
		ResetObjectsUsedInLua()
		'reset (potential old) save state
		scriptSaveState = ""

		Local args:Object[1]
		args[0] = string(GetWorldTime().GetTimeGone())

		scriptSaveState = string(CallLuaFunction("OnSaveState", args))
	End Method


	'for now OnLoad and OnSave are equal to OnLoadState and OnSaveState
	Method CallOnLoad()
		'load/save regardless of running-state
		'if not AiRunning then return

		Local args:Object[1]
		args[0] = self.scriptSaveState

		CallLuaFunction("OnLoad", args)
	End Method


	Method CallOnSave()
		'load/save regardless of running-state
		'if not AiRunning then return

		'reset
		ResetObjectsUsedInLua()
		'reset (potential old) save state
		scriptSaveState = ""

		Local args:Object[1]
		args[0] = string(GetWorldTime().GetTimeGone())

		scriptSaveState = string(CallLuaFunction("OnSave", args))
	End Method


	Method CallOnRealtimeSecond(millisecondsGone:Int=0)
		if not AiRunning then return

		Local args:Object[1]
		args[0] = String(millisecondsGone)

		CallLuaFunction("OnRealTimeSecond", args)
	End Method


	Method CallOnMinute(minute:Int=0)
		if not AiRunning then return

		Local args:Object[1]
		args[0] = String(minute)

		CallLuaFunction("OnMinute", args)
	End Method


	'use this if one talks in the chat
	'channelType defines if "public" or "private" chat
	Method CallOnChat(fromID:int=0, text:String = "", chatType:int = 0, channels:int = 0)
		if not AiRunning then return

		Local args:Object[4]
		args[0] = text
		args[1] = string(fromID)
		args[2] = string(chatType)
		args[3] = string(channels)

		CallLuaFunction("OnChat", args)
	End Method


	Method CallOnProgrammeLicenceAuctionGetOutbid(licence:object, bid:int, bidderID:int)
		if not AiRunning then return

		Local args:Object[3]
		args[0] = TProgrammeLicence(licence)
		args[1] = string(bid)
		args[2] = string(bidderID)

		CallLuaFunction("OnProgrammeLicenceAuctionGetOutbid", args)
	End Method


	Method CallOnProgrammeLicenceAuctionWin(licence:object, bid:int)
		if not AiRunning then return

		Local args:Object[2]
		args[0] = TProgrammeLicence(licence)
		args[1] = string(bid)

		CallLuaFunction("OnProgrammeLicenceAuctionWin", args)
	End Method


	Method CallOnBossCalls(latestWorldTime:Double=0)
		if not AiRunning then return

		Local args:Object[1]
		args[0] = String(latestWorldTime)

		CallLuaFunction("OnBossCalls", args)
	End Method


	Method CallOnBossCallsForced()
		if not AiRunning then return

		CallLuaFunction("OnBossCallsForced", Null)
	End Method


	Method CallOnPublicAuthoritiesStopXRatedBroadcast()
		if not AiRunning then return

		CallLuaFunction("OnPublicAuthoritiesStopXRatedBroadcast", Null)
	End Method


	Method CallOnPublicAuthoritiesConfiscateProgrammeLicence(confiscatedLicence:object, targetLicence:object)
		if not AiRunning then return

		Local args:Object[2]
		args[0] = TProgrammeLicence(confiscatedLicence)
		args[1] = TProgrammeLicence(targetLicence)

		CallLuaFunction("OnPublicAuthoritiesConfiscateProgrammeLicence", args)
	End Method


	Method CallOnAchievementCompleted(achievement:object)
		if not AiRunning then return

		Local args:Object[1]
		args[0] = TAchievement(achievement)

		CallLuaFunction("CallOnAchievementCompleted", args)
	End Method


	Method CallOnWonAward(award:object)
		if not AiRunning then return

		Local args:Object[1]
		args[0] = TAward(award)

		CallLuaFunction("CallOnWonAward", args)
	End Method


	Method CallOnLeaveRoom(roomId:int)
		if not AiRunning then return

		Local args:Object[1]
		args[0] = String(roomId)

		CallLuaFunction("OnLeaveRoom", args)
	End Method


	Method CallOnReachRoom(roomId:Int)
		if not AiRunning then return

		Local args:Object[1]
		args[0] = String(roomId)

		CallLuaFunction("OnReachRoom", args)
	End Method


	Method CallOnBeginEnterRoom(roomId:int, result:int)
		if not AiRunning then return

		Local args:Object[2]
		args[0] = String(roomId)
		args[1] = String(result)

		CallLuaFunction("OnBeginEnterRoom", args)
	End Method


	Method CallOnEnterRoom(roomId:int)
		if not AiRunning then return

		Local args:Object[1]
		args[0] = String(roomId)

		CallLuaFunction("OnEnterRoom", args)
	End Method


	Method CallOnReachTarget(target:object)
		if not AiRunning then return

		local targetText:string = "unknown"
		if TRoomDoor(target) then targetText = TRoomDoor(target).roomId
		if TVec2D(target) then targetText = "Building (x="+TVec2D(target).GetIntX()+" floor="+ GetBuildingBase().GetFloor( TVec2D(target).GetIntY() )+")"

		Local args:Object[2]
		args[0] = target
		args[1] = targetText

		CallLuaFunction("OnReachTarget", args)
	End Method


	Method CallOnDayBegins()
		if not AiRunning then return

		CallLuaFunction("OnDayBegins", Null)
	End Method


	Method CallOnGameBegins()
		if not AiRunning then return

		CallLuaFunction("OnGameBegins", Null)
	End Method


	Method CallOnInit()
		if not AiRunning then return

		CallLuaFunction("OnInit", Null)
	End Method


	Method CallOnMoneyChanged(value:int, reason:int, reference:object)
		if not AiRunning then return

		Local args:Object[3]
		args[0] = String(value)
		args[1] = String(reason)
		args[2] = TNamedGameObject(reference)

		CallLuaFunction("OnMoneyChanged", args)
	End Method


	Method CallOnMalfunction()
		if not AiRunning then return

		CallLuaFunction("OnMalfunction", Null)
	End Method


	Method CallOnPlayerGoesBankrupt(playerID:int)
		'ignore whether it runs or not - so they can reset their
		'stats regardless of inactive or not
		'if not AiRunning then return

		Local args:Object[1]
		args[0] = String(playerID)

		CallLuaFunction("OnPlayerGoesBankrupt", args)
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

	Method DataArray:object[]()
		if object[](data).length = 0
			return new object[0]
		else
			return object[](data)
		endif
	End Method
End Type




Type TLuaFunctions extends TLuaFunctionsBase {_exposeToLua}
	'=== CONST + HELPERS

	'convenience access to game rules (constants)
	Field Rules:TGameRules
	'convenience access to game constants (constants)
	Field Constants:TVTGameConstants
	'gets instantiated during "new"
	Field ME:Int

	Field audiencePredictor:TBroadcastAudiencePrediction = new TBroadcastAudiencePrediction

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

	Method _PlayerInRoom:Int(roomname:String) {_private}
		'If checkFromRoom
			'from room has to be set AND inroom <> null (no building!)
		'	GetPlayer(Self.ME).isComingFromRoom(roomname) and GetPlayer(Self.ME).isInRoom()
		'Else
			Return GetPlayerBase(Self.ME).isInRoom(roomname)
		'EndIf
	End Method


	Method _PlayerOwnsRoom:Int() {_private}
		Return Self.ME = TFigure(GetPlayerBase(Self.ME).GetFigure()).inRoom.owner
	End Method


	Function Create:TLuaFunctions(pPlayerId:Int) {_private}
		Local ret:TLuaFunctions = New TLuaFunctions

		ret.Rules = GameRules
		ret.Constants = GameConstants

		ret.ME = pPlayerId

		ret.ROOM_MOVIEAGENCY = GetRoomCollection().GetFirstByDetails("", "movieagency").id
		ret.ROOM_ADAGENCY = GetRoomCollection().GetFirstByDetails("", "adagency").id
		ret.ROOM_ROOMBOARD = GetRoomCollection().GetFirstByDetails("", "roomboard").id
		ret.ROOM_PORTER = GetRoomCollection().GetFirstByDetails("", "porter").id
		ret.ROOM_BETTY = GetRoomCollection().GetFirstByDetails("", "betty").id
		ret.ROOM_SUPERMARKET = GetRoomCollection().GetFirstByDetails("", "supermarket").id
		ret.ROOM_ROOMAGENCY = GetRoomCollection().GetFirstByDetails("", "roomagency").id
		ret.ROOM_PEACEBROTHERS = GetRoomCollection().GetFirstByDetails("", "peacebrothers").id
		ret.ROOM_SCRIPTAGENCY = GetRoomCollection().GetFirstByDetails("", "scriptagency").id
		ret.ROOM_NOTOBACCO = GetRoomCollection().GetFirstByDetails("", "notobacco").id
		ret.ROOM_TOBACCOLOBBY = GetRoomCollection().GetFirstByDetails("", "tobaccolobby").id
		ret.ROOM_GUNSAGENCY = GetRoomCollection().GetFirstByDetails("", "gunsagency").id
		ret.ROOM_VRDUBAN = GetRoomCollection().GetFirstByDetails("", "vrduban").id
		ret.ROOM_FRDUBAN = GetRoomCollection().GetFirstByDetails("", "frduban").id

		ret.ROOM_ARCHIVE_PLAYER_ME = GetRoomCollection().GetFirstByDetails("", "archive", pPlayerId).id
		ret.ROOM_NEWSAGENCY_PLAYER_ME = GetRoomCollection().GetFirstByDetails("", "news", pPlayerId).id
		ret.ROOM_BOSS_PLAYER_ME = GetRoomCollection().GetFirstByDetails("", "boss", pPlayerId).id
		ret.ROOM_OFFICE_PLAYER_ME = GetRoomCollection().GetFirstByDetails("", "office", pPlayerId).id

		Return ret
	End Function


	'use this to save blitzmax objects from within a lua script to its AI
	Method SaveExternalObject:int(o:object)
		return GetPlayerBase(Self.ME).PlayerAI.AddObjectUsedInLua(o)
	End Method

	Method RestoreExternalObject:object(index:int)
		return GetPlayerBase(Self.ME).PlayerAI.GetObjectUsedInLua(index)
	End Method


	Method GetArchiveIdOfPlayer:Int(id:Int)
		Return GetRoomCollection().GetFirstByDetails("", "archive", id).id
	End Method

	Method GetNewsAgencyIdOfPlayer:Int(id:Int)
		Return GetRoomCollection().GetFirstByDetails("", "news", id).id
	End Method

	Method GetBossOfficeIdOfPlayer:Int(id:Int)
		Return GetRoomCollection().GetFirstByDetails("", "boss", id).id
	End Method

	Method GetOfficeIdOfPlayer:Int(id:Int)
		Return GetRoomCollection().GetFirstByDetails("", "office", id).id
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
		return GetRoomCollection().GetFirstByDetails("", roomName, owner)
	End Method


	Method GetRoomsByDetails:TRoom[](roomName:String, owner:Int=-1000)
		return GetRoomCollection().GetAllByDetails("", roomName, owner)
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
		Local roomID:int = GetPlayerBase(self.ME).GetFigure().GetInRoomID()
		If roomID Then Return roomID

		Return self.RESULT_NOTFOUND
	End Method


	Method getPlayerTargetRoom:Int()
		local roomDoor:TRoomDoor = TRoomDoor(GetPlayerBase(self.ME).GetFigure().GetTargetObject())
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


	Method isControllableFigure:Int()
		return GetPlayerBase(self.ME).GetFigure().IsControllable()
	End Method


	'send figure to a specific room
	'attention: the first found door is used
	Method doGoToRoom:Int(roomId:Int = 0)
		Local room:TRoom = GetRoomCollection().Get(roomId)
		If room
			Local door:TRoomDoorBase = GetRoomDoorCollection().GetMainDoorToRoom(room.id)
			If door
				if TFigure(GetPlayerBase(self.ME).GetFigure()).SendToDoor(door)
					Return self.RESULT_OK
				else
					Return self.RESULT_NOTALLOWED
				endif
			EndIf
		endif

		Return self.RESULT_NOTFOUND
	End Method


	Method doGoToRelative:Int(relX:Int = 0, relYFloor:Int = 0) 'Nur x wird unterstuetzt. Negativ: Nach links; Positiv: nach rechts
		TFigure(GetPlayerBase(self.ME).GetFigure()).GoToCoordinatesRelative(relX, relYFloor)
		Return self.RESULT_OK
	End Method


	Method isRoomUnused:Int(roomId:Int = 0)
		Local Room:TRoom = GetRoomCollection().Get(roomId)
		If not Room then return self.RESULT_NOTFOUND
		if not Room.hasOccupant() then return self.RESULT_OK

		If Room.isOccupant( GetPlayerBase(self.ME).GetFigure() ) then Return -1
		Return self.RESULT_INUSE
	End Method


	'returns how many time is gone since game/app start
	Method getTimeGone:Int()
		Return Time.GetTimeGone()
	End Method


	Method GetMillisecs:Long()
		Return Time.MilliSecsLong()
	End Method


	Method addToLog:int(text:string)
		text = StringHelper.RemoveUmlauts(text)
		'text = StringHelper.UTF8toISO8859(text)

		'print "AILog "+Self.ME+": "+text
		return AiLog[Self.ME-1].AddLog(text, True)
	End Method


	Method AreEqual:int(o1:object, o2:object)
		return o1 = o2
	End Method


	Method getPotentialAudiencePercentage:Float(day:int = - 1, hour:int = -1)
		if day = -1 then day = GetWorldTime().GetDay()
		if hour = -1 then hour = GetWorldTime().GetDayHour()
		local time:Long = GetWorldTime().MakeTime(0, day, hour, 0, 0)
		'percentage of each population group watching now
		'local percentage:TAudience = TBroadcast.GetPotentialAudiencePercentageForHour(hour).GetAvg()

		'percentage of each group in the population
		local population:TAudience = new TAudience.InitWithBreakdown(1)
		'GetPotentialAudienceModifier returns percentage watching now
		population.Multiply(TBroadcast.GetPotentialAudienceModifier(time))

		'-> GetTotalSum() contains the total percentage of the population
		'   watching TV now
		return population.GetTotalSum()
	End Method


	'only for DEBUG
	'allows access to information of OTHER PLAYERS !!
	Method getBroadcastedProgrammeQuality:Float(day:int = - 1, hour:int = -1, playerID:int)
		local plan:TPlayerProgrammePlan = GetPlayerProgrammePlan(playerID)
		if not plan then return 0.0

		local broadcastMaterial:TBroadcastMaterial = plan.GetProgramme(day, hour)
		if not broadcastMaterial then return 0.0

		if TAdvertisement(broadcastMaterial)
			return 0.6 * broadcastMaterial.GetQuality()
		endif
		return broadcastMaterial.GetQuality()
	End Method


	Method getAudienceAttraction:string(hour:int, broadcastMaterial:TBroadcastMaterial, lastMovieAttraction:TAudienceAttraction = null, lastNewsShowAttraction:TAudienceAttraction = null, withSequenceEffect:Int=False, withLuckEffect:Int=False)
		if not broadcastMaterial then return ""
		return broadcastMaterial.GetAudienceAttraction(hour, broadcastMaterial.currentBlockBroadcasting, lastMovieAttraction, lastNewsShowAttraction, withSequenceEffect, withLuckEffect).ToString()
	End Method


	Method getExclusiveMaxAudience:int()
		return GetStationMapCollection().GetTotalChannelExclusiveAudience(self.ME)
	End Method


	Method getMoney:int()
		return GetPlayerFinance(self.ME, -1).money
	End Method

	Method convertToAdContract:TAdContract(obj:object)
		return TAdContract(obj)
	End Method

	Method convertToAdContracts:TAdContract[](obj:object)
		return TAdContract[](obj)
	End Method

	Method convertToProgrammeLicence:TProgrammeLicence(obj:object)
		return TProgrammeLicence(obj)
	End Method

	Method convertToProgrammeLicences:TProgrammeLicence[](obj:object)
		return TProgrammeLicence[](obj)
	End Method


	'helper to allow modification of a predicted audience attraction
	'without affecting the original one
	Method CopyBasicAudienceAttraction:TAudienceAttraction(attraction:TAudienceAttraction, multiplyFactor:Float = 1.0)
		if not attraction then return null
		local copyAttraction:TAudienceAttraction = attraction.CopyStaticBaseAttraction()
		if multiplyFactor <> 1.0 then copyAttraction.MultiplyAttrFactor(multiplyFactor)
		return copyAttraction
	End Method


	'=== GENERIC INFORMATION RETRIEVERS ===
	'player could eg. see in interface / tooltips

	Method GetRoomBlockedTime:Long(roomID:int)
		local room:TRoomBase = GetRoomBase(roomID)
		if not room then return -1
		return room.GetBlockedTime()
	End Method


	Method GetCurrentProgramme:TBroadcastMaterial()
		return GetPlayerProgrammePlan(self.ME).GetProgramme()
	End Method


	Method GetCurrentProgrammeQuality:Float(playerID:int = 0)
		if playerID <= 0 or not GetPlayerProgrammePlan(playerID) then playerID = self.ME
		local prog:TBroadcastMaterial = GetPlayerProgrammePlan(playerID).GetProgramme()

		if prog then return prog.GetQuality()
		return 0.0
	End Method


	'player could eg. see in interface / tooltips
	Method GetCurrentNewsShow:TBroadcastMaterial()
		return GetPlayerProgrammePlan(self.ME).GetNewsShow()
	End Method


	Method GetCurrentAdvertisement:TBroadcastMaterial()
		return GetPlayerProgrammePlan(self.ME).GetAdvertisement()
	End Method


	Method GetCurrentAdvertisementMinAudience:int()
		local ad:TAdvertisement = TAdvertisement(GetCurrentAdvertisement())
		if ad then return ad.contract.GetMinAudience()
		return 0
	End Method


	'TODO: remove by storing "programme plan information" within the AI
	'      itself (a table in lua, refreshed manually when in office or
	'      editing the programme plan)
	Method IsBroadcastMaterialInProgrammePlan:int(materialGUID:string, day:int, hour:int)
		local bm:TBroadcastMaterial = GetPlayerProgrammePlan(self.ME).GetProgramme(day, hour)
		if not bm then return False
		if bm then return bm.GetGUID() = materialGUID
	End Method
	'same here
	Method GetBroadcastMaterialGUIDInProgrammePlan:string(materialGUID:string, day:int, hour:int)
		local bm:TBroadcastMaterial = GetPlayerProgrammePlan(self.ME).GetProgramme(day, hour)
		if bm then return bm.GetGUID()
		return ""
	End Method


	Method GetProgrammeLicenceCount:Int()
		Return GetPlayerProgrammeCollection(Self.ME).GetProgrammeLicenceCount()
	End Method


	Method GetAdContractCount:Int()
		Return GetPlayerProgrammeCollection(Self.ME).GetAdContractCount()
	End Method


	Method GetCurrentProgrammeAudience:TAudience()
		return GetBroadcastManager().GetCurrentAudienceObject(Self.ME)
rem
		local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(GetWorldTime().GetDay(), GetWorldTime.GetDayHour())
		If stat
			local audienceResult:TAudienceResultBase = stat.GetAudienceResult(Self.ME, GetWorldTime().GetDayHour(), false)
			if audienceResult
				return audienceResult.Audience
			endif
		endif

		Return new TAudience.InitValue(0)
endrem
	End Method


	'TODO: really expose that information to the player?
	Method GetCurrentProgrammeAudienceAttraction:TAudienceAttraction()
		local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(GetWorldTime().GetDay(), GetWorldTime().GetDayHour())
		if not stat then return null
		local audienceResult:TAudienceResult = TAudienceResult(stat.GetNewsAudienceResult(Self.ME, GetWorldTime().GetDayHour(), false))
		If Not audienceResult Then Return null
		Return audienceResult.AudienceAttraction
	End Method


	Method GetCurrentNewsAudience:TAudience()
		local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(GetWorldTime().GetDay(), GetWorldTime().GetDayHour())
		if stat
			local audienceResult:TAudienceResultBase = stat.GetNewsAudienceResult(Self.ME, GetWorldTime().GetDayHour(), false)
			If audienceResult
				return audienceResult.Audience
			endif
		endif
		return new TAudience.InitValue(0, 0)
	End Method


	Method GetCurrentNewsAudienceAttraction:TAudienceAttraction()
		local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(GetWorldTime().GetDay(), GetWorldTime().GetDayHour())
		if not stat then return null
		local audienceResult:TAudienceResult = TAudienceResult(stat.GetNewsAudienceResult(Self.ME, GetWorldTime().GetDayHour(), false))
		If Not audienceResult Then Return null
		Return audienceResult.AudienceAttraction
	End Method


	'=== OFFICE ===
	'players bureau
	Method of_IsModifyableProgrammePlanSlot:int(slotType:int, day:int, hour:int)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if GetPlayerProgrammePlan(self.ME).IsModifyableSlot(slotType, day, hour)
			return self.RESULT_OK
		endif
		return self.RESULT_NOTALLOWED
	End Method


	Method of_getAudience:Int(day:int, hour:int)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		local broadcastStat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day)
		if not broadcastStat then return 0
		local audience:TAudienceResultBase = broadcastStat.GetAudienceResult(self.ME, hour, false)
		if not audience then return 0
		Return audience.audience.GetTotalSum()
	End Method


	Method of_getNewsAudience:Int(day:int, hour:int)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		local broadcastStat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day)
		if not broadcastStat then return 0
		local audience:TAudienceResultBase = broadcastStat.GetNewsAudienceResult(self.ME, hour, false)
		if not audience then return 0
		Return audience.audience.GetTotalSum()
	End Method


	'== STATIONMAP ==

	'compatibility
	Method of_buyStation:int(x:int, y:int)
		return of_buyAntennaStation(x, y)
	End Method


	Method of_buyAntennaStation:int(x:int, y:int)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if GetStationMap(ME).BuyAntennaStation(x, y)
			Return self.RESULT_OK
		else
			Return self.RESULT_FAILED
		endif
	End Method


	Method of_buyCableNetworkStation:int(federalStateName:string)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if GetStationMap(ME).BuyCableNetworkUplinkStationBySectionName(federalStateName)
			Return self.RESULT_OK
		else
			Return self.RESULT_FAILED
		endif
	End Method


	Method of_buyCableNetworkStationByCableNetworkIndex:int(index:int)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if GetStationMap(ME).BuyCableNetworkUplinkStation(index)
			Return self.RESULT_OK
		else
			Return self.RESULT_FAILED
		endif
	End Method


	Method of_buySatelliteStation:int(satelliteNumber:int)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if GetStationMap(ME).BuySatelliteUplinkStation(satelliteNumber)
			Return self.RESULT_OK
		else
			Return self.RESULT_FAILED
		endif
	End Method


	Method of_sellStation:int(listPosition:int)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if GetStationMap(self.ME).SellStationAtPosition(listPosition)
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


	Method of_getStationAtIndex:TStationBase(playerID:int = -1, arrayIndex:Int = -1)
		If Not _PlayerInRoom("office") Then Return Null

		if playerID = -1 then playerID = self.ME

		Return GetStationMap(playerID).GetStationAtIndex(arrayIndex)
	End Method


	Method of_getCableNetworkCount:int()
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		'also returns not yet launched ones!
		return GetStationMapCollection().GetCableNetworkCount()
	End Method


	Method of_getCableNetworkAtIndex:TStationMap_BroadcastProvider(arrayIndex:int)
		If Not _PlayerInRoom("office") Then Return null

		return GetStationMapCollection().GetCableNetworkAtIndex(arrayIndex)
	End Method


	Method of_getSatelliteCount:int()
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		'also returns not yet launched ones!
		return GetStationMapCollection().GetSatelliteCount()
	End Method


	Method of_getSatelliteAtIndex:TStationMap_BroadcastProvider(arrayIndex:int)
		If Not _PlayerInRoom("office") Then Return null

		return GetStationMapCollection().GetSatelliteAtIndex(arrayIndex)
	End Method



	'== PROGRAMME PLAN ==

	'counts how many times a licence is planned as programme (this
	'includes infomercials and movies/series/programmes)
	Method of_GetBroadcastMaterialInProgrammePlanCount:Int(referenceID:Int, day:Int=-1, includePlanned:Int=False, includeStartedYesterday:Int=True, slotType:int = 0)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		if slotType = 0 then slotType = TVTBroadcastMaterialType.PROGRAMME

		return GetPlayerProgrammePlan(self.ME).GetBroadcastMaterialInPlanCount(referenceID, day, includePlanned, includeStartedYesterday, slotType)
	End Method


	Method of_GetBroadcastMaterialInTimeSpan:TLuaFunctionResult(objectType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True, requireSameType:Int=False)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local bm:TBroadcastMaterial[] = GetPlayerProgrammePlan(self.ME).GetObjectsInTimeSpan(objectType, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject, requireSameType)
		Return TLuaFunctionResult.Create(self.RESULT_OK, bm)
	End Method


	Method of_GetBroadcastMaterialProgrammedCountInTimeSpan:int(materialSource:TBroadcastMaterialSource, slotType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1)
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		Return GetPlayerProgrammePlan(self.ME).GetBroadcastMaterialSourceProgrammedCountInTimeSpan(materialSource, slotType, dayStart, hourStart, dayEnd, hourEnd)
	End Method


	'returns the broadcast material (in result.data) at the given slot
	Method of_getAdvertisementSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		Local material:TBroadcastMaterial = GetPlayerProgrammePlan(self.ME).GetAdvertisement(day, hour)
		If material
			Return TLuaFunctionResult.Create(self.RESULT_OK, material)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method of_getAdContractCount:Int()
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		Return GetPlayerProgrammeCollection(Self.ME).GetAdContractCount()
	End Method


	Method of_getAdContracts:TLuaFunctionResult()
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local contracts:TAdContract[] = GetPlayerProgrammeCollection(self.ME).GetAdContractsArray()
		If contracts
			Return TLuaFunctionResult.Create(self.RESULT_OK, contracts)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method



	Method of_getAdContractAtIndex:TAdContract(arrayIndex:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Local obj:TAdContract = GetPlayerProgrammeCollection(self.ME).GetAdContractAtIndex(arrayIndex)
		If obj Then Return obj Else Return Null
	End Method


	Method of_getAdContractByID:TAdContract(id:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Local obj:TAdContract = GetPlayerProgrammeCollection(self.ME).GetAdContract(id)
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
		local broadcastMaterial:TBroadcastMaterial = GetPlayerProgrammeCollection(self.ME).GetBroadcastMaterial(materialSource)
		if not broadcastMaterial then return self.RESULT_FAILED

		'skip setting the slot if already done
		Local existingMaterial:TBroadcastMaterial = GetPlayerProgrammePlan(self.ME).GetAdvertisement(day, hour)
		if existingMaterial
			if broadcastMaterial.GetReferenceID() = existingMaterial.GetReferenceID() and broadcastMaterial.materialType = existingMaterial.materialType
				return self.RESULT_SKIPPED
			endif
		endif


		if GetPlayerProgrammePlan(self.ME).SetAdvertisementSlot(broadcastMaterial, day, hour)
			return self.RESULT_OK
		else
			return self.RESULT_NOTALLOWED
		endif
	End Method


	'returns the broadcast material (in result.data) at the given slot
	Method of_getProgrammeSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		Local material:TBroadcastMaterial = GetPlayerProgrammePlan(self.ME).GetProgramme(day, hour)
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
		local broadcastMaterial:TBroadcastMaterial = GetPlayerProgrammeCollection(self.ME).GetBroadcastMaterial(materialSource)
		if not broadcastMaterial then return self.RESULT_FAILED

		'skip setting the slot if already done
		Local existingMaterial:TBroadcastMaterial = GetPlayerProgrammePlan(self.ME).GetProgramme(day, hour)
		if existingMaterial
			if broadcastMaterial.GetReferenceID() = existingMaterial.GetReferenceID() and broadcastMaterial.materialType = existingMaterial.materialType
				return self.RESULT_SKIPPED
			endif
		endif


		if GetPlayerProgrammePlan(self.ME).SetProgrammeSlot(broadcastMaterial, day, hour)
			return self.RESULT_OK
		else
			return self.RESULT_NOTALLOWED
		endif
	End Method


	Method of_getProgrammeLicenceByID:TProgrammeLicence(id:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Local obj:TProgrammeLicence = GetPlayerProgrammeCollection(self.ME).GetProgrammeLicence(id)
		If obj Then Return obj Else Return Null
	End Method


	Method of_getProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM

		Return getProgrammeLicenceCount()
	End Method


	Method of_getProgrammeLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Local obj:TProgrammeLicence = GetPlayerProgrammeCollection(Self.ME).GetProgrammeLicenceAtIndex(arrayIndex)
		If obj Then Return obj Else Return Null
	End Method


	'=== NEWS ROOM ===

	Method ne_getTotalNewsAbonnementFees:Int()
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return self.RESULT_WRONGROOM

		return GetPlayerBase(self.ME).GetTotalNewsAbonnementFees()
	End Method


	Method ne_getNewsAbonnementFee:Int(newsGenreID:int, level:int)
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return self.RESULT_WRONGROOM

		return GetNewsAgency().GetNewsAbonnementPrice(self.ME, newsGenreID, level)
	End Method


	Method ne_getNewsAbonnement:Int(newsGenreID:int)
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return self.RESULT_WRONGROOM

		return GetPlayerBase(self.ME).GetNewsAbonnement(newsGenreID)
	End Method


	Method ne_setNewsAbonnement:Int(newsGenreID:int, level:int)
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return self.RESULT_WRONGROOM

		if GetPlayerBase(self.ME).SetNewsAbonnement(newsGenreID, level)
			return self.RESULT_OK
		endif
	End Method

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


	Method ne_getAllAvailableNews:TLuaFunctionResult()
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local availableNews:TNews[] = GetPlayerProgrammeCollection(self.ME).GetNewsArray()
		If availableNews
			Return TLuaFunctionResult.Create(self.RESULT_OK, availableNews)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method ne_getAvailableNews:TLuaFunctionResult(arrayIndex:Int=-1)
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local availableNews:TNews = GetPlayerProgrammeCollection(self.ME).GetNewsAtIndex(arrayIndex)
		If availableNews
			Return TLuaFunctionResult.Create(self.RESULT_OK, availableNews)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method ne_getAllBroadcastedNews:TLuaFunctionResult()
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local broadcastedNews:TNews[] = TNews[](GetPlayerProgrammePlan(self.ME).GetNewsArray())
		If broadcastedNews
			Return TLuaFunctionResult.Create(self.RESULT_OK, broadcastedNews)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method ne_getBroadcastedNews:TLuaFunctionResult(arrayIndex:Int=-1)
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local broadcastedNews:TNews = TNews(GetPlayerProgrammePlan(self.ME).GetNewsAtIndex(arrayIndex))
		If broadcastedNews
			Return TLuaFunctionResult.Create(self.RESULT_OK, broadcastedNews)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method ne_doRemoveNewsFromPlan:Int(slot:int = 0, objectGUID:String = "")
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return self.RESULT_WRONGROOM

		local player:TPlayerBase = GetPlayerBase(self.ME)

		'It does not matter if a player has a master key for the room,
		'only observing is allowed for them
		If Self.ME <> TFigure(player.GetFigure()).inRoom.owner Then Return self.RESULT_WRONGROOM


		Local newsObject:TNews
		if objectGUID
			'news has to be in plan, not collection
			newsObject = TNews(GetPlayerProgrammePlan(self.ME).GetNews(objectGUID))
		elseif slot >= 0
			newsObject = TNews(GetPlayerProgrammePlan(self.ME).GetNewsAtIndex(slot))
		endif
		If not newsObject then Return self.RESULT_NOTFOUND

		if GetPlayerProgrammePlan(self.ME).RemoveNews(newsObject, slot)
			Return self.RESULT_OK
		else
			Return self.RESULT_NOTFOUND
		endif
	End Method


	Method ne_doNewsInPlan:Int(slot:int = 0, objectGUID:String = "")
		If Not (_PlayerInRoom("newsroom") or _PlayerInRoom("news")) Then Return self.RESULT_WRONGROOM

		local player:TPlayerBase = GetPlayerBase(self.ME)

		'It does not matter if a player has a master key for the room,
		'only observing is allowed for them
		If Self.ME <> TFigure(player.GetFigure()).inRoom.owner Then Return self.RESULT_WRONGROOM


		'news has to be in collection, not plan
		Local news:TNews = TNews(GetPlayerProgrammeCollection(self.ME).GetNews(objectGUID))
		If not news
			'if not found, someone is switching from plan slot x to slot y?
			news = TNews(GetPlayerProgrammePlan(self.ME).GetNews(objectGUID))
			if not news then Return self.RESULT_NOTFOUND
		endif

		'skip if on same slot
		if GetPlayerProgrammePlan(self.ME).GetNewsAtIndex(slot) = news
			Return self.RESULT_OK
		endif


		'place it (and remove from other slots before - if needed)
		if not GetPlayerProgrammePlan(self.ME).SetNews(news, slot)
			return self.RESULT_FAILED
		else
			Return self.RESULT_OK
		endif
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


	'SIGN the spot with the corresponding ID
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method sa_doBuySpot:Int(contractID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		local contract:TAdContract = RoomHandler_AdAgency.GetInstance().GetContractByID(contractID)
		'this DOES sign in that moment
		if contract
			if RoomHandler_AdAgency.GetInstance().GiveContractToPlayer( contract, self.ME, TRUE )
				return self.RESULT_OK
			else
				return self.RESULT_NOTALLOWED
			endif
		endif
		Return self.RESULT_NOTFOUND
	End Method


	'TAKE the spot with the corresponding ID (NOT signed yet)
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method sa_doTakeSpot:Int(contractID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		local contract:TAdContract = RoomHandler_AdAgency.GetInstance().GetContractByID(contractID)
		'this DOES NOT sign - signing is done when leaving the room!
		if contract
			if RoomHandler_AdAgency.GetInstance().GiveContractToPlayer( contract, self.ME )
				return self.RESULT_OK
			else
				return self.RESULT_NOTALLOWED
			endif
		endif
		Return self.RESULT_NOTFOUND
	End Method


	'GIVE BACK the spot with the corresponding ID (if not signed yet)
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method sa_doGiveBackSpot:Int(contractID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		local contract:TAdContract = GetPlayerProgrammeCollection(self.ME).GetUnsignedAdContractFromSuitcase(contractID)

		if contract and RoomHandler_AdAgency.GetInstance().TakeContractFromPlayer( contract, self.ME )
			Return self.RESULT_OK
		else
			Return self.RESULT_NOTFOUND
		endif
	End Method



	'=== MOVIE AGENCY ===
	'main screen

	'Get Amount of licences available at the movie agency
	'Returns: amount
	Method md_getProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		Return RoomHandler_MovieAgency.GetInstance().GetProgrammeLicencesInStock()
	End Method


	'Get licence at a specific position from movie agency
	'Returns: LuaFunctionResult (resultID, licence)
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


	'Get all licences from movie agency
	'Returns: LuaFunctionResult (resultID, licences)
	Method md_getProgrammeLicences:TLuaFunctionResult()
		If Not _PlayerInRoom("movieagency") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)


		local licences:TProgrammeLicence[] = RoomHandler_MovieAgency.GetInstance().GetProgrammeLicences()
		If licences and licences.length > 0
			Return TLuaFunctionResult.Create(self.RESULT_OK, licences)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	'BUY a programme licence with the corresponding ID
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method md_doBuyProgrammeLicence:Int(licenceID:Int=-1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local licence:TProgrammeLicence = RoomHandler_MovieAgency.GetInstance().GetProgrammeLicenceByID(licenceID)
		if Licence then return RoomHandler_MovieAgency.GetInstance().SellProgrammeLicenceToPlayer(licence, self.ME)

		Return self.RESULT_NOTFOUND
	End Method


	'SELL a programme licence with the corresponding ID
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method md_doSellProgrammeLicence:Int(licenceID:Int=-1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		For local licence:TProgrammeLicence = eachin GetPlayerProgrammeCollection(self.ME).suitcaseProgrammeLicences
			if licence.id = licenceID then return RoomHandler_MovieAgency.GetInstance().BuyProgrammeLicenceFromPlayer(licence)
		Next
		Return self.RESULT_NOTFOUND
	End Method



	'=== MOVIE DEALER ===
	'Movie Agency - Auctions

	'GET an auction programme block at the given array position
	'Returns: TAuctionProgrammeBlocks
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
		If Block and Block.GetLicence() then Return Block.GetNextBid(self.ME) else Return self.RESULT_NOTFOUND
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


	Method bo_GetCurrentAwardType:int()
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		local award:TAward = GetAwardCollection().GetCurrentAward()
		if award then return award.awardType

		return self.RESULT_NOTFOUND
	End Method


	Method bo_GetCurrentAwardStartTime:Long()
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		local award:TAward = GetAwardCollection().GetCurrentAward()
		if award then return award.GetStartTime()

		return self.RESULT_NOTFOUND
	End Method


	Method bo_GetCurrentAwardEndTime:Long()
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		local award:TAward = GetAwardCollection().GetCurrentAward()
		if award then return award.GetEndTime()

		return self.RESULT_NOTFOUND
	End Method


	Method bo_GetNextAwardType:int()
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		local award:TAward = GetAwardCollection().GetNextAward()
		if award then return award.awardType

		return self.RESULT_NOTFOUND
	End Method


	Method bo_GetNextAwardStartTime:Long()
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		local award:TAward = GetAwardCollection().GetNextAward()
		if award then return award.GetStartTime()

		return self.RESULT_NOTFOUND
	End Method


	Method bo_GetNextAwardEndTime:Long()
		If Not _PlayerInRoom("boss") Then Return self.RESULT_WRONGROOM

		local award:TAward = GetAwardCollection().GetNextAward()
		if award then return award.GetEndTime()

		return self.RESULT_NOTFOUND
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

		If GetRoomBoard().SwitchSignPositions(slotA, floorA, slotB, floorB, self.ME)
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

	'=== CHANNEL PROGRAMME ARCHIVE ===

	'move licence from archive to suitcase
	'ATTENTION: if you move multiple licences, position will shift!
	Method ar_AddProgrammeLicenceToSuitcase:Int(position:Int = -1)
		If Not _PlayerInRoom("archive") Then Return self.RESULT_WRONGROOM

		local licence:TProgrammeLicence = GetPlayerProgrammeCollection(self.ME).GetProgrammeLicenceAtIndex(position)
		if not licence then return self.RESULT_NOTFOUND
		'Skip series episodes or collection elements
		if licence.HasParentLicence() then return self.RESULT_NOTALLOWED

		Return GetPlayerProgrammeCollection(self.ME).AddProgrammeLicenceToSuitcase(licence)
	End Method


	'move licence from archive to suitcase
	Method ar_AddProgrammeLicenceToSuitcaseByGUID:Int(guid:string)
		If Not _PlayerInRoom("archive") Then Return self.RESULT_WRONGROOM

		local licence:TProgrammeLicence = GetPlayerProgrammeCollection(self.ME).GetProgrammeLicenceByGUID(guid)
		if not licence then return self.RESULT_NOTFOUND
		'Skip series episodes or collection elements
		if licence.HasParentLicence() then return self.RESULT_NOTALLOWED

		Return GetPlayerProgrammeCollection(self.ME).AddProgrammeLicenceToSuitcase(licence)
	End Method


	'move licence from suitcase to archive
	'ATTENTION: if you move multiple licences, position will shift!
	Method ar_RemoveProgrammeLicenceFromSuitcase:Int(position:Int = -1)
		If Not _PlayerInRoom("archive") Then Return self.RESULT_WRONGROOM

		local licence:TProgrammeLicence = GetPlayerProgrammeCollection(self.ME).GetSuitcaseProgrammeLicenceAtIndex(position)
		if not licence then return self.RESULT_NOTFOUND

		Return GetPlayerProgrammeCollection(self.ME).RemoveProgrammeLicenceFromSuitcase(licence)
	End Method


	'move licence from suitcase to archive
	Method ar_RemoveProgrammeLicenceFromSuitcaseByGUID:Int(guid:string)
		If Not _PlayerInRoom("archive") Then Return self.RESULT_WRONGROOM

		local licence:TProgrammeLicence = GetPlayerProgrammeCollection(self.ME).GetSuitcaseProgrammeLicenceByGUID(guid)
		if not licence then return self.RESULT_NOTFOUND

		Return GetPlayerProgrammeCollection(self.ME).RemoveProgrammeLicenceFromSuitcase(licence)
	End Method


	'returns count of available programme licences in the archive
	Method ar_GetProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("archive") Then Return self.RESULT_WRONGROOM

		Return GetPlayerProgrammeCollection(self.ME).GetProgrammeLicenceCount()
	End Method


	'returns the specified licence (if possible)
	Method ar_GetProgrammeLicence:TLuaFunctionResult(position:Int = -1)
		If Not _PlayerInRoom("archive") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local licence:TProgrammeLicence = GetPlayerProgrammeCollection(self.ME).GetProgrammeLicenceAtIndex(position)
		If licence
			Return TLuaFunctionResult.Create(self.RESULT_OK, licence)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	'returns amount of licences in suitcase
	Method ar_GetSuitcaseProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("archive") Then Return self.RESULT_WRONGROOM

		Return GetPlayerProgrammeCollection(self.ME).GetSuitcaseProgrammeLicenceCount()
	End Method


	'returns the specified licence (if possible)
	Method ar_GetSuitcaseProgrammeLicence:TLuaFunctionResult(position:Int = -1)
		If Not _PlayerInRoom("archive") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local licence:TProgrammeLicence = GetPlayerProgrammeCollection(self.ME).GetSuitcaseProgrammeLicenceAtIndex(position)
		If licence
			Return TLuaFunctionResult.Create(self.RESULT_OK, licence)
		else
			Return TLuaFunctionResult.Create(self.RESULT_NOTFOUND, null)
		endif
	End Method


	Method ar_GetSuitcaseProgrammeLicences:TLuaFunctionResult()
		If Not _PlayerInRoom("archive") Then Return TLuaFunctionResult.Create(self.RESULT_WRONGROOM, null)

		local licences:TProgrammeLicence[] = GetPlayerProgrammeCollection(self.ME).GetSuitcaseProgrammeLicencesArray()
		Return TLuaFunctionResult.Create(self.RESULT_OK, licences)
	End Method
End Type
