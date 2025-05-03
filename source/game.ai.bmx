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
Import "game.roomhandler.scriptagency.bmx"
Import "game.roomhandler.studio.bmx"
Import "game.roomagency.bmx"
Import "game.programmeproducer.bmx"


Global AiLog:TLogFile[4]
For Local i:Int = 0 To 3
	AiLog[i] = TLogFile.Create("AI Log v1.0", "log.ai"+(i+1)+".txt", True)
Next


Type TAi Extends TAiBase

	Method Create:TAi(playerID:Int, luaScriptFileName:String) override
		Super.Create(playerID, luaScriptFileName)
		Return Self
	End Method


	Method RegisterSharedObjects() override
		'=== LINK SPECIAL OBJECTS ===
		'own functions for player
		_luaEngine.RegisterObject("TVT", TLuaFunctions.Create(PlayerID))
		'the player
		_luaEngine.RegisterObject("MY", GetPlayerBase(PlayerID))
		'the game object
		_luaEngine.RegisterObject("Game", GetGameBase())
		'world time
		_luaEngine.RegisterObject("WorldTime", GetWorldTime())

		super.RegisterSharedObjects()
	End Method


	'override to additionally disable AI when game is paused
	Method IsActive:Int()
		If Not Super.IsActive() Then Return False

		If GetGameBase().IsPaused() Then Return False

		Return True
	End Method


	Method AddLog(title:String, text:String, logLevel:Int) override
		Super.AddLog(title, text, logLevel)
		AiLog[Self.playerID-1].AddLog(text, True)
	End Method
	
	
	Method GetTotalTicks:Int()
		Return ticks + realtimeSecondTicks + internalTicks
	End Method


	Method CallUpdate()
		if GetNextEventCount() = 0
			delay(1)
			return
		endif

		Local nextEvent:TAIEvent = PopNextEvent()
		While nextEvent
			HandleAIEvent(nextEvent)
			nextEvent = PopNextEvent()
		Wend
	End Method
	
	
	'inform AI about a tick - could come from realtimeSecond, internal
	'or default CallOnTick()
	Method _CallOnTick:Int(realTimeGone:Long, gameTimeGone:Long)
		If AiRunning
			Local args:Object[4]
			args[0] = String(realTimeGone)
			args[1] = String(gameTimeGone)
			'ticks for system
			args[2] = String(ticks)
			'total ticks for the AI (so including scheduled inner ticks and realtime second ticks)
			args[3] = String(GetTotalTicks())

			CallLuaFunction("OnTick", args)

			Return True
		EndIf
		Return False
	End Method


	'only calls the AI "onTick" if the calculated interval passed
	'- more than 1 RealTime second passed since last tick
	Method CallOnRealtimeSecondTick(realTimeGone:Long, gameTimeGone:Long) override
		'increase ticks count
		realtimeSecondTicks :+ 1

'print "ai"+self.playerID+": realtimesecond tick. time=" + GetWorldTime().GetFormattedTime(gameTimeGone) + "    ticks=" + ticks + "  internalTicks="+internalTicks + "  processedGameMinute="+processedGameMinute+ "  gameTime="+GetWorldTime().GetFormattedTime(gameTimeGone)
		_CallOnTick(realTimeGone, gameTimeGone)
	End Method


	'game minute based tick
	Method CallOnTick(gameTimeGone:Long) override
		'increase ticks count
		ticks :+ 1

		'store minute as it might change during "lua function call"
		local processingGameMinute:Int = GetWorldTime().GetTimeGoneAsMinute(True, gameTimeGone)

'print "ai"+self.playerID+": ontick. time=" + GetWorldTime().GetFormattedTime(gameTimeGone) + "    ticks=" + Ticks + "  processedGameMinute="+processedGameMinute + "   goneTimeAsMinute="+GetWorldTime().GetTimeGoneAsMinute(True, gameTimeGone)
		_CallOnTick(Time.GetTimeGone(), gameTimeGone)

		'store processed minute of this tick now we are done with it
		processedGameMinute = processingGameMinute
	End Method


	Method CallOnInternalTick(gameTimeGone:Long) override
		'increase internal ticks count
		internalTicks :+ 1

'print "ai"+self.playerID+": internaltick. time=" + GetWorldTime().GetFormattedTime(gameTimeGone) + "    ticks=" + Ticks + "  processedGameMinute="+processedGameMinute + "   goneTimeAsMinute="+GetWorldTime().GetTimeGoneAsMinute(True, gameTimeGone)

		_CallOnTick(Time.GetTimeGone(), gameTimeGone)
	End Method


	Method CallOnLoadState()
		'load/save regardless of running-state
		'if not AiRunning then return

		Local args:Object[1]
		args[0] = Self.scriptSaveState

		CallLuaFunction("OnLoadState", args)
	End Method


	Method CallOnSaveState()
		'load/save regardless of running-state
		'if not AiRunning then return

		'reset (potential old) save state
		scriptSaveState = ""

		Local args:Object[1]
		args[0] = String(GetWorldTime().GetTimeGone())

		scriptSaveState = String(CallLuaFunction("OnSaveState", args, true))
	End Method


	'for now OnLoad and OnSave are equal to OnLoadState and OnSaveState
	Method CallOnLoad()
		'load/save regardless of running-state
		'if not AiRunning then return

		Local args:Object[1]
		args[0] = Self.scriptSaveState

		CallLuaFunction("OnLoad", args)
	End Method


	Method CallOnSave()
		'load/save regardless of running-state
		'if not AiRunning then return

		'reset (potential old) save state
		scriptSaveState = ""

		Local args:Object[1]
		args[0] = String(GetWorldTime().GetTimeGone())

		scriptSaveState = String(CallLuaFunction("OnSave", args, true))
	End Method


	Method CallOnInit()
		If Not AiRunning Then Return

		CallLuaFunction("OnInit", Null)
	End Method
End Type


'wrapper for result-type/ID + data
Type TLuaFunctionResult {_exposeToLua}
	Field result:Int = 0
	Field data:Object

	Function Create:TLuaFunctionResult(result:Int, data:Object)
		Local obj:TLuaFunctionResult = New TLuaFunctionResult
		obj.result = result
		obj.data = data
		Return obj
	End Function

	Method DataArray:Object[]()
		If Object[](data).length = 0
			Return New Object[0]
		Else
			Return Object[](data)
		EndIf
	End Method
End Type




Type TLuaFunctions Extends TLuaFunctionsBase {_exposeToLua}
	'=== CONST + HELPERS

	'convenience access to game rules (constants)
	Field Rules:TGameRules
	'convenience access to game constants (constants)
	Field Constants:TVTGameConstants
	'gets instantiated during "new"
	Field ME:Int

	Field audiencePredictor:TBroadcastAudiencePrediction = New TBroadcastAudiencePrediction

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
		Return GetPlayerBase(Self.ME).isInRoom(roomname)
	End Method


	Method _PlayerOwnsRoom:Int() {_private}
		Local figure:TFigure = TFigure(GetPlayerBase(Self.ME).GetFigure())
		If figure 
			Local room:TRoomBase = figure.inRoom
			if room and room.owner = Self.ME
				Return True
			Else
				Return False
			EndIf
		Else
			Return False
		EndIF
	End Method


	Method _GetPlayerStationMap:TStationMap() {_private}
		local map:TStationMap = GetStationMap(Self.ME)
		If not map Then Throw "No StationMap assigned for player " + Self.ME
		Return map
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
	Method SaveExternalObject:Int(o:Object)
		Return GetPlayerBase(Self.ME).PlayerAI.AddObjectUsedInLua(o)
	End Method

	Method RestoreExternalObject:Object(index:Int)
		Return GetPlayerBase(Self.ME).PlayerAI.GetObjectUsedInLua(index)
	End Method


	Method PopNextEvent:TAIEvent()
		Return GetPlayerBase(Self.ME).PlayerAI.PopNextEvent()
	End Method


	Method GetNextEventCount:Int()
		Return GetPlayerBase(Self.ME).PlayerAI.GetNextEventCount()
	End Method
	

	Method ScheduleNextOnTick()
		GetPlayerBase(Self.ME).PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnInternalTick).AddLong(Time.GetTimeGone()).AddLong(GetWorldTime().GetTimeGone()))
	End Method


	Method IsActive:Int()
		Return GetPlayerBase(Self.ME).PlayerAI.IsActive()
	End Method


	'use this to send the threaded AI to sleep for a while
	Method Sleep:Int(milliseconds:Int)
		Delay(milliseconds)
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

		TLogger.Log("AI "+Self.ME, text, LOG_AI)
		Return Self.RESULT_OK
	End Method


	'only printed if TLogger.setPrintMode(LOG_AI | LOG_DEBUG) is set
	Method PrintOutDebug:Int(text:String)
		text = StringHelper.RemoveUmlauts(text)

		TLogger.Log("AI "+Self.ME+" DEBUG", text, LOG_AI & LOG_DEBUG)
		Return Self.RESULT_OK
	End Method


	Method GetFirstRoomByDetails:TRoom(roomName:String, owner:Int)
		Return GetRoomCollection().GetFirstByDetails("", roomName, owner)
	End Method


	Method GetRoomsByDetails:TRoom[](roomName:String, owner:Int)
		'return by current name, not original one, so that all studios are found
		Return GetRoomCollection().GetAllByDetails(roomName, "", owner)
	End Method


	Method GetRoom:TRoom(id:Int)
		Return GetRoomCollection().Get(id)
	End Method


	'returns the id of the (first) hotspot, door ... leading to the given room (id)
	Method GetTargetIDToRoomID:Int(roomID:Int)
		Local room:TRoomBase = GetRoomBaseCollection().Get(roomID)
		If Not room 
			Return Self.RESULT_NOTFOUND
		Else
			Return GetTargetID(room.name, room.owner, -1, TVTBuildingTargetType.NONE)
		EnDIf
	End Method	

	
	'returns the id of an hotspot, door ... suiting to the given params
	'targetOwner = -1 to not limit the owner
	'targetFloor = -1 to not limit the floor of the target
	'targetType  = 0 to not limit the target type, else TVT.constants.buildingTargetType.ROOM / HOTSPOT
	Method GetTargetID:Int(targetName:String, targetOwner:Int, targetFloor:Int, targetType:Int)
		Local targetID:Int = GetBuildingBase().GetTargetID(targetName, targetOwner, targetFloor, targetType)
		If targetID = -1
			Return Self.RESULT_NOTFOUND
		Else
			Return targetID
		EndIf
	End Method


	Method SendToChat:Int(ChatText:String)
		'emit an event, we received a chat message
		Local sendToChannels:Int = TGUIChat.GetChannelsFromText(ChatText)
		TriggerBaseEvent(GameEventKeys.Chat_OnAddEntry, New TData.AddNumber("senderID", Self.ME).AddNumber("channels", sendToChannels).AddString("text",ChatText) )

		Return 1
	EndMethod


	Method getPlayerRoom:Int()
		Local roomID:Int = GetPlayerBase(Self.ME).GetFigure().GetInRoomID()
		If roomID Then Return roomID

		Return Self.RESULT_NOTFOUND
	End Method


	Method getPlayerTargetRoom:Int()
		Local roomDoor:TRoomDoor = TRoomDoor(GetPlayerBase(Self.ME).GetFigure().GetTargetObject())
		If roomDoor 
			local room:TRoomBase = roomDoor.GetRoom()
			If room and room.id
				Return room.id
			EndIf
		EndIf

		Return Self.RESULT_NOTFOUND
	End Method


	'return the floor of a room
	'attention: the floor of the first found door is returned
	Method getRoomFloor:Int(roomId:Int = 0)
		Local room:TRoom = GetRoomCollection().Get(roomId)
		If room
			Local door:TRoomDoorBase = GetRoomDoorCollection().GetMainDoorToRoom(room.id)
			If door Then Return door.GetOnFloor()
		EndIf

		Return Self.RESULT_NOTFOUND
	End Method


	Method isControllableFigure:Int()
		Return GetPlayerBase(Self.ME).GetFigure().IsControllable()
	End Method


	'returns if figure is really on a floor (not just moving "through")
	Method isFigureOnFloor:Int()
		Return TFigure(GetPlayerBase(Self.ME).GetFigure()).IsOnFloor()
	End Method
	
	
	Method getFigureFloor:Int()
		Return GetPlayerBase(Self.ME).GetFigure().GetFloor()
	End Method
	
	
	'send figure to a specific target (room, hotspot, ...)
	Method doGoToTarget:Int(targetID:Int = 0)
		Local t:Object = GetBuildingBase().GetTarget(targetID)
		if t
			If TFigure(GetPlayerBase(Self.ME).GetFigure()).SendToTarget(t)
				Return Self.RESULT_OK
			Else
				Return Self.RESULT_NOTALLOWED
			EndIf
		EndIf

		Return Self.RESULT_NOTFOUND
	End Method


	'send figure to a specific room
	'attention: the first found door is used
	Method doGoToRoom:Int(roomId:Int = 0)
		Local room:TRoom = GetRoomCollection().Get(roomId)
		If room
			Local door:TRoomDoorBase = GetRoomDoorCollection().GetMainDoorToRoom(room.id)
			If door
				If TFigure(GetPlayerBase(Self.ME).GetFigure()).SendToDoor(door)
					Return Self.RESULT_OK
				Else
					Return Self.RESULT_NOTALLOWED
				EndIf
			EndIf
		EndIf

		Return Self.RESULT_NOTFOUND
	End Method


	'set forceLeave to "True" to forcefully leave the room
	Method doLeaveRoom:Int(forceLeave:Int)
		If TFigure(GetPlayerBase(Self.ME).GetFigure()).LeaveRoom(forceLeave)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	Method canLeaveRoom:Int()
		Local f:TFigure = TFigure(GetPlayerBase(Self.ME).GetFigure())
		'cache inRoom (in case of concurrent modification)
		Local inRoom:TRoomBase = f.inRoom
		If Not inRoom Then Return Self.RESULT_WRONGROOM
		
		If f.CanLeaveRoom(inRoom)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_NOTALLOWED
		EndIf
	End Method


	Method doGoToRelative:Int(relX:Int = 0, relYFloor:Int = 0) 'Nur x wird unterstuetzt. Negativ: Nach links; Positiv: nach rechts
		TFigure(GetPlayerBase(Self.ME).GetFigure()).GoToCoordinatesRelative(relX, relYFloor)
		Return Self.RESULT_OK
	End Method


	Method isRoomUnused:Int(roomId:Int = 0)
		Local room:TRoom = GetRoomCollection().Get(roomId)
		If Not room Then Return Self.RESULT_NOTFOUND
		If Not room.hasOccupant() Then Return Self.RESULT_OK

		If room.isOccupant( GetPlayerBase(Self.ME).GetFigure() ) Then Return -1
		Return Self.RESULT_INUSE
	End Method


	Method isRoomPotentialStudio:Int(roomId:Int = 0)
		Local room:TRoom = GetRoomCollection().Get(roomId)
		If Not room Then Return Self.RESULT_NOTFOUND
		If room.IsUsableAsStudio() And room.getNameRaw() <> "studio"
			Return Self.RESULT_OK
		EndIf
		Return Self.RESULT_FAILED
	End Method


	'returns how many time is gone since game/app start
	'we return texts as FOR NOW 32bit builds fail to pass LONG via
	'reflection.mod
	Method GetAppTimeGoneString:String()
		Return String(Time.GetTimeGone())
	End Method


	'we return texts as FOR NOW 32bit builds fail to pass LONG via
	'reflection.mod
	Method GetMillisecsString:String()
		Return String(Time.MilliSecsLong())
	End Method


	'we return texts as FOR NOW 32bit builds fail to pass LONG via
	'reflection.mod
	Method GetTimeGoneString:String()	
		Return GetWorldTime().GetTimeGone()
	End Method

	
	Method GetTimeGoneInSeconds:Int()
		Return GetWorldTime().GetTimeGone() / TWorldTime.SECONDLENGTH
	End Method

	Method GetTimeGoneInSecondsForTime:Int(useTime:String)	'String not Long, until Long-bug is fixed	
		If Long(useTime) <= 0
			Return GetWorldTime().GetTimeGone() / TWorldTime.SECONDLENGTH
		Else
			Return Long(useTime) / TWorldTime.SECONDLENGTH
		EndIf
	End Method


	Method GetTimeGoneInMinutes:Int()
		Return GetWorldTime().GetTimeGone() / TWorldTime.MINUTELENGTH
	End Method

	Method GetTimeGoneInMinutesForTime:Int(useTime:String)	'String not Long, until Long-bug is fixed	
		If Long(useTime) <= 0
			Return GetWorldTime().GetTimeGone() / TWorldTime.MINUTELENGTH
		Else
			Return Long(useTime) / TWorldTime.MINUTELENGTH
		EndIf
	End Method


	Method GetDaysRun:Int()
		Return GetWorldTime().GetDaysRun()
	End Method

	Method GetDaysRunForTime:Int(useTime:String)	'String not Long, until Long-bug is fixed
		Return GetWorldTime().GetDaysRun(Long(useTime))
	End Method


	Method GetDay:Int()
		Return GetWorldTime().GetDay()
	End Method

	Method GetDayForTime:Int(useTime:String)	'String not Long, until Long-bug is fixed
		Return GetWorldTime().GetDay(Long(useTime))
	End Method


	Method GetDayHour:Int()
		Return GetWorldTime().GetDayHour()
	End Method

	Method GetDayHourForTime:Int(useTime:String)	'String not Long, until Long-bug is fixed
		Return GetWorldTime().GetDayHour(Long(useTime))
	End Method


	Method GetDayMinute:Int()
		Return GetWorldTime().GetDayMinute()
	End Method

	Method GetDayMinuteForTime:Int(useTime:String)	'String not Long, until Long-bug is fixed
		Return GetWorldTime().GetDayMinute(Long(useTime))
	End Method


	Method GetStartDay:Int()	
		Return GetWorldTime().GetStartDay()
	End Method


	Method GetFormattedTime:String(format:String)
		Return GetWorldTime().GetFormattedTime(format)
	End Method


	Method GetFormattedTimeForTime:String(useTime:String, format:String) 'String not Long, until Long-bug is fixed
		Return GetWorldTime().GetFormattedTime(Long(useTime), format)
	End Method

	
	Method TimeToSeconds:Int(time:String)
		Return Long(time) / TWorldTime.SECONDLENGTH
	End Method


	Method TimeToMinutes:Int(time:String)
		Return Long(time) / TWorldTime.MINUTELENGTH
	End Method


	Method TimeToHours:Int(time:String)
		Return Long(time) / TWorldTime.HOURLENGTH
	End Method


	Method TimeToDays:Int(time:String)
		Return Long(time) / TWorldTime.DAYLENGTH
	End Method


	Method TimeToYears:Int(time:String)
		Return Long(time) / (GetWorldTime().DAYLENGTH * GetWorldTime().GetDaysPerYear())
	End Method




	Method addToLog:Int(text:String)
		text = StringHelper.RemoveUmlauts(text)
		'text = StringHelper.UTF8toISO8859(text)

		'print "AILog "+Self.ME+": "+text
		Return AiLog[Self.ME-1].AddLog(GetWorldTime().GetFormattedTime()+" - "+text, True)
	End Method


	Method getPotentialAudiencePercentage:Float(day:Int = - 1, hour:Int = -1)
		If day = -1 Then day = GetWorldTime().GetDay()
		If hour = -1 Then hour = GetWorldTime().GetDayHour()
		Local time:Long = GetWorldTime().GetTimeGoneForGameTime(0, day, hour, 0, 0)

		'fetch a struct copy
		Local population:SAudience = AudienceManager.GetAudienceBreakdown().data
		'GetPotentialAudienceModifier returns percentage watching now
		population.Multiply(TBroadcast.GetPotentialAudienceModifier(time))

		'GetTotalSum() contains the total percentage of the 
		'population watching TV now
		Return population.GetTotalSum()
	End Method


	'only for DEBUG
	'allows access to information of OTHER PLAYERS !!
	Method getBroadcastedProgrammeQuality:Float(day:Int = - 1, hour:Int = -1, playerID:Int)
		Local plan:TPlayerProgrammePlan = GetPlayerProgrammePlan(playerID)
		If Not plan Then Return 0.0

		Local broadcastMaterial:TBroadcastMaterial = plan.GetProgramme(day, hour)
		If Not broadcastMaterial Then Return 0.0

		If TAdvertisement(broadcastMaterial)
			Return 0.6 * broadcastMaterial.GetQuality()
		EndIf
		Return broadcastMaterial.GetQuality()
	End Method


	Method getAudienceAttraction:String(hour:Int, broadcastMaterial:TBroadcastMaterial, lastMovieAttraction:TAudienceAttraction = Null, lastNewsShowAttraction:TAudienceAttraction = Null, withSequenceEffect:Int=False, withLuckEffect:Int=False)
		If Not broadcastMaterial Then Return ""
		Return broadcastMaterial.GetAudienceAttraction(hour, broadcastMaterial.currentBlockBroadcasting, lastMovieAttraction, lastNewsShowAttraction, withSequenceEffect, withLuckEffect).ToString()
	End Method


	'reachable whole time -> player could use audience tooltip
	Method getReceivers:Int()
		Return _GetPlayerStationMap().GetReceivers()
	End Method


	Method getMoney:Int()
		Return GetPlayerFinance(Self.ME, -1).money
	End Method

	Method getImage:Int(player:Int)
		Return GetPublicImage(player).GetAverageImage()
	End Method


	Method convertToAdContract:TAdContract(obj:Object)
		Return TAdContract(obj)
	End Method

	Method convertToAdContracts:TAdContract[](obj:Object)
		Return TAdContract[](obj)
	End Method

	Method convertToProgrammeLicence:TProgrammeLicence(obj:Object)
		Return TProgrammeLicence(obj)
	End Method

	Method convertToProgrammeLicences:TProgrammeLicence[](obj:Object)
		Return TProgrammeLicence[](obj)
	End Method


	'helper to allow modification of a predicted audience attraction
	'without affecting the original one
	'ATTENTION:
	' multiplyFactorAsString read as "string" instead of as "float"
	' required until brl.reflection correctly handles "float parameters" 
	' in release and debug builds)
	' GREP-key: "brlreflectionbug"
	Method CopyBasicAudienceAttraction:TAudienceAttraction(attraction:TAudienceAttraction, multiplyFactorAsString:String)
		Local multiplyFactor:Float = Float(multiplyFactorAsString)

		If Not attraction Then Return Null
		Local copyAttraction:TAudienceAttraction = attraction.CopyStaticBaseAttraction()
		If multiplyFactor <> 1.0 Then copyAttraction.MultiplyAttrFactor(multiplyFactor)
		Return copyAttraction
	End Method


	'=== GENERIC INFORMATION RETRIEVERS ===
	'player could eg. see in interface / tooltips
	'or stuff "static" over the whole game - so during a second game this
	'is known to a player (eg. fees for a news abonnement level)

	Method GetNewsAbonnementFee:Int(newsGenreID:Int, level:Int)
		Return GetNewsAgency().GetNewsAbonnementPrice(Self.ME, newsGenreID, level)
	End Method


	'we return texts as FOR NOW 32bit builds fail to pass LONG via
	'reflection.mod
	Method GetRoomBlockedTimeString:String(roomID:Int)
		Local room:TRoomBase = GetRoomBase(roomID)
		If Not room Then Return -1
		Return room.GetBlockedTime()
	End Method


	Method IsRoomBlocked:Int(roomID:Int)
		Local room:TRoomBase = GetRoomBase(roomID)
		If Not room Then Return -1
		Return room.IsBlocked()
	End Method


	Method GetCurrentProgramme:TBroadcastMaterial()
		Return GetPlayerProgrammePlan(Self.ME).GetProgramme()
	End Method


	Method GetCurrentProgrammeQuality:Float(playerID:Int = 0)
		If playerID <= 0 Or Not GetPlayerProgrammePlan(playerID) Then playerID = Self.ME
		Local prog:TBroadcastMaterial = GetPlayerProgrammePlan(playerID).GetProgramme()

		If prog Then Return prog.GetQuality()
		Return 0.0
	End Method


	'player could eg. see in interface / tooltips
	Method GetCurrentNewsShow:TBroadcastMaterial()
		Return GetPlayerProgrammePlan(Self.ME).GetNewsShow()
	End Method


	Method GetCurrentAdvertisement:TBroadcastMaterial()
		Return GetPlayerProgrammePlan(Self.ME).GetAdvertisement()
	End Method


	Method CurrentAdvertisementRequirementsPassed:Int()
		Local ad:TAdvertisement = TAdvertisement(GetCurrentAdvertisement())
		If ad
			Local audience:TAudienceResult = GetBroadcastManager().GetAudienceResult(Self.ME)
			If ad.IsPassingRequirements(audience) = "OK" Then Return Self.RESULT_OK
		Else
			return Self.RESULT_NOTFOUND
		EndIf
		return Self.RESULT_FAILED
	End Method


	'TODO: remove by storing "programme plan information" within the AI
	'      itself (a table in lua, refreshed manually when in office or
	'      editing the programme plan)
	Method IsBroadcastMaterialInProgrammePlan:Int(materialGUID:String, day:Int, hour:Int)
		Local bm:TBroadcastMaterial = GetPlayerProgrammePlan(Self.ME).GetProgramme(day, hour)
		If Not bm Then Return False
		If bm Then Return bm.GetGUID() = materialGUID
	End Method
	'same here
	Method GetBroadcastMaterialGUIDInProgrammePlan:String(materialGUID:String, day:Int, hour:Int)
		Local bm:TBroadcastMaterial = GetPlayerProgrammePlan(Self.ME).GetProgramme(day, hour)
		If bm Then Return bm.GetGUID()
		Return ""
	End Method


	'helper
	Method CreateBroadcastMaterialFromSource:TBroadcastMaterial(materialSource:TBroadcastMaterialSource)
		'create a broadcast material out of the given source
		Return GetPlayerProgrammeCollection(Self.ME).GetBroadcastMaterial(materialSource)
	End Method


	Method GetProgrammeLicenceCount:Int()
		Return GetPlayerProgrammeCollection(Self.ME).GetProgrammeLicenceCount()
	End Method


	Method GetProgrammeLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=-1)
		Try
			Local obj:TProgrammeLicence = GetPlayerProgrammeCollection(Self.ME).GetProgrammeLicenceAtIndex(arrayIndex)
			If obj Then Return obj
		Catch ex:Object
			TLogger.Log("AI", "GetProgrammeLicenceAtIndex exception", LOG_ERROR)
		End Try
		Return Null
	End Method


	Method GetAdContractCount:Int()
		Return GetPlayerProgrammeCollection(Self.ME).GetAdContractCount()
	End Method


	Method GetCurrentProgrammeAudienceResult:TAudienceResult()
		Return GetBroadcastManager().GetAudienceResult(Self.ME)
Rem
		local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(GetWorldTime().GetDay(), GetWorldTime.GetDayHour())
		If stat
			local audienceResult:TAudienceResultBase = stat.GetAudienceResult(Self.ME, GetWorldTime().GetDayHour(), false)
			if audienceResult
				return audienceResult.Audience
			endif
		endif

		Return New TAudience.Set(0)
endrem
	End Method


	'TODO: really expose that information to the player?
	Method GetCurrentProgrammeAudienceAttraction:TAudienceAttraction()
		Local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(GetWorldTime().GetDay(), GetWorldTime().GetDayHour())
		If Not stat Then Return Null
		Local audienceResult:TAudienceResult = TAudienceResult(stat.GetNewsAudienceResult(Self.ME, GetWorldTime().GetDayHour(), False))
		If Not audienceResult Then Return Null
		Return audienceResult.AudienceAttraction
	End Method


	Method GetCurrentNewsAudience:TAudience()
		Local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(GetWorldTime().GetDay(), GetWorldTime().GetDayHour())
		If stat
			Local audienceResult:TAudienceResultBase = stat.GetNewsAudienceResult(Self.ME, GetWorldTime().GetDayHour(), False)
			If audienceResult
				Return audienceResult.Audience
			EndIf
		EndIf
		Return New TAudience.Set(0, 0)
	End Method


	Method GetCurrentNewsAudienceAttraction:TAudienceAttraction()
		Local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(GetWorldTime().GetDay(), GetWorldTime().GetDayHour())
		If Not stat Then Return Null
		Local audienceResult:TAudienceResult = TAudienceResult(stat.GetNewsAudienceResult(Self.ME, GetWorldTime().GetDayHour(), False))
		If Not audienceResult Then Return Null
		Return audienceResult.AudienceAttraction
	End Method


	'=== OFFICE ===
	'player's office

	Method of_GetRandomAntennaCoordinateInPlayerSections:TVec2I()
		If Not _PlayerInRoom("office") Then Return Null
		
		Return new TVec2I.CopyFrom(_GetPlayerStationMap().GetRandomAntennaCoordinateInPlayerSections())
	End Method

	Method of_GetRandomAntennaCoordinateInSections:TVec2I(sectionNames:string[], allowSectionCrossing:Int = True)
		If Not _PlayerInRoom("office") Then Return Null
		
		Return new TVec2I.CopyFrom(_GetPlayerStationMap().GetRandomAntennaCoordinateInSections(sectionNames, allowSectionCrossing))
	End Method

	Method of_GetRandomAntennaCoordinateInSection:TVec2I(sectionName:string, allowSectionCrossing:Int = True)
		If Not _PlayerInRoom("office") Then Return Null

		Return new TVec2I.CopyFrom(_GetPlayerStationMap().GetRandomAntennaCoordinateInSection(sectionName, allowSectionCrossing))
	End Method

	Method of_GetRandomAntennaCoordinateOnMap:TVec2I(checkBroadcastPermission:Int=True, requiredBroadcastPermissionState:Int=True)
		If Not _PlayerInRoom("office") Then Return Null
		
		Local coords:SVec2I = _GetPlayerStationMap().GetRandomAntennaCoordinateOnMap(checkBroadcastPermission, requiredBroadcastPermissionState)
		If coords.x = -1 and coords.y = -1 Then Return Null
		
		Return new TVec2I.CopyFrom(coords)
	End Method

	Method of_GetTemporaryCableNetworkUplinkStation:TStationBase(cableNetworkIndex:Int)
		If Not _PlayerInRoom("office") Then Return Null
		
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkAtIndex(cableNetworkIndex)
		If Not cableNetwork Or Not cableNetwork.launched Then Return Null

		Return New TStationCableNetworkUplink.Init(cableNetwork, self.ME, True)
	End Method

	'less calculation-expensive variant for determining if obtaining a temporary antenna makes sense
	'-8 = no section, -1 = no permission possible yet, 0 = permission already present, permission price otherwise
	Method of_GetBroadCastPermisionCosts:Int(dataX:Int,dataY:Int)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByDataXY(dataX, dataY)
		If Not section Then Return Self.RESULT_NOTFOUND
		If section.HasBroadCastPermission(Self.ME, TVTStationType.ANTENNA) Then Return 0
		If Not section.NeedsBroadcastPermission(Self.ME, TVTStationType.ANTENNA) Then Return 0
		If Not section.CanGetBroadcastPermission(Self.ME) Return -1
		Local price:Int = section.GetBroadcastPermissionPrice(Self.ME, TVTStationType.ANTENNA)
		Return price
	End Method

	Method of_GetTemporaryAntennaStation:TStationBase(dataX:Int, dataY:Int)
		If Not _PlayerInRoom("office") Then Return Null

		Return New TStationAntenna.Init(New SVec2I(dataX, dataY), self.ME)
	End Method


	Method of_GetTemporarySatelliteUplinkStation:TStationBase(satelliteIndex:Int)
		If Not _PlayerInRoom("office") Then Return Null

		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteAtIndex(satelliteIndex)
		If Not satellite Or Not satellite.launched Then Return Null

		Return New TStationSatelliteUplink.Init(satellite, self.ME, True)
	End Method


	Method of_GetStationCosts:Int()
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		Return _GetPlayerStationMap().CalculateStationCosts()
	End Method


	Method of_IsModifyableProgrammePlanSlot:Int(slotType:Int, day:Int, hour:Int)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		If GetPlayerProgrammePlan(Self.ME).IsModifiableSlot(slotType, day, hour)
			Return Self.RESULT_OK
		EndIf
		Return Self.RESULT_NOTALLOWED
	End Method


	Method of_getAudience:Int(day:Int, hour:Int)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		Local broadcastStat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day)
		If Not broadcastStat Then Return 0
		Local audience:TAudienceResultBase = broadcastStat.GetAudienceResult(Self.ME, hour, False)
		If Not audience Then Return 0
		Return audience.audience.GetTotalSum()
	End Method


	Method of_getNewsAudience:Int(day:Int, hour:Int)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		Local broadcastStat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day)
		If Not broadcastStat Then Return 0
		Local audience:TAudienceResultBase = broadcastStat.GetNewsAudienceResult(Self.ME, hour, False)
		If Not audience Then Return 0
		Return audience.audience.GetTotalSum()
	End Method


	'== STATIONMAP ==

	'compatibility
	Method of_buyStation:Int(x:Int, y:Int)
		Return of_buyAntennaStation(x, y)
	End Method


	Method of_buyAntennaStation:Int(x:Int, y:Int)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM
		
		Local map:TStationMap = _GetPlayerStationMap()
		Local station:TStationAntenna = New TStationAntenna.Init(New SVec2I(x, y), self.ME)

		If map.GetAntennaByXY(x,y,True)
			'prevent buying antenna in same position
			Return Self.RESULT_FAILED
		ElseIf map.AddStation( station, True )
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	Method of_buyCableNetworkStation:Int(federalStateName:String)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM
		
		Local station:TStationCableNetworkUplink = New TStationCableNetworkUplink.Init(federalStateName, self.ME, True)
		If _GetPlayerStationMap().AddStation(station, True)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	Method of_buyCableNetworkStationByCableNetworkIndex:Int(cableNetworkIndex:Int)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM
		
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkAtIndex(cableNetworkIndex)
		If Not cableNetwork Or Not cableNetwork.launched Then Return Self.RESULT_FAILED

		Local station:TStationCableNetworkUplink = New TStationCableNetworkUplink.Init(cableNetwork, self.ME, True)
		If _GetPlayerStationMap().AddStation(station, True)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	Method of_buySatelliteStation:Int(satelliteIndex:Int)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM
		
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteAtIndex(satelliteIndex)
		If Not satellite Then Return Self.RESULT_FAILED

		Local station:TStationSatelliteUplink = New TStationSatelliteUplink.Init(satellite, self.ME, True)
		If _GetPlayerStationMap().AddStation(station, True)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	Method of_sellStation:Int(listPosition:Int)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		If _GetPlayerStationMap().SellStationAtPosition(listPosition)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	Method of_getStationCount:Int(playerID:Int = -1)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		If playerID = -1 Then playerID = Self.ME

		Return _GetPlayerStationMap().GetStationCount()
	End Method


	Method of_getStationAtIndex:TStationBase(playerID:Int = -1, arrayIndex:Int = -1)
		If Not _PlayerInRoom("office") Then Return Null

		If playerID = -1 Then playerID = Self.ME

		Return _GetPlayerStationMap().GetStationAtIndex(arrayIndex)
	End Method


	Method of_getCableNetworkCount:Int()
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		'also returns not yet launched ones!
		Return GetStationMapCollection().GetCableNetworkCount()
	End Method


	Method of_getCableNetworkAtIndex:TStationMap_BroadcastProvider(arrayIndex:Int)
		If Not _PlayerInRoom("office") Then Return Null

		Return GetStationMapCollection().GetCableNetworkAtIndex(arrayIndex)
	End Method


	Method of_getSatelliteCount:Int()
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		'also returns not yet launched ones!
		Return GetStationMapCollection().GetSatelliteCount()
	End Method


	Method of_getSatellite:TStationMap_BroadcastProvider(satelliteID:Int)
		If Not _PlayerInRoom("office") Then Return Null
		
		Return GetStationMapCollection().GetSatellite(satelliteID)
	End Method


	Method of_getSatelliteAtIndex:TStationMap_BroadcastProvider(arrayIndex:Int)
		If Not _PlayerInRoom("office") Then Return Null

		Return GetStationMapCollection().GetSatelliteAtIndex(arrayIndex)
	End Method


	Method of_getPlayerReceivers:Int(playerID:Int)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		If playerID <= 0 Then playerID = Self.ME
		
		Return GetStationMapCollection().GetReceivers(playerID)
	End Method


	Method of_getMapPopulation:Int()
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		Return GetStationMapCollection().GetPopulation()
	End Method


	Method of_getMapReceivers:Int()
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		Return GetStationMapCollection().GetReceivers()
	End Method


	'returns (usable) width of the map
	Method of_getMapWidth:Int()
		Return GetStationMapCollection().surfaceData.width
	End Method


	'returns (usable) height of the map
	Method of_getMapHeight:Int()
		Return GetStationMapCollection().surfaceData.height
	End Method


	'== PROGRAMME PLAN ==

	'counts how many times a licence is planned as programme (this
	'includes infomercials and movies/series/programmes)
	Method of_GetBroadcastMaterialInProgrammePlanCount:Int(referenceID:Int, day:Int=-1, includePlanned:Int=False, includeStartedYesterday:Int=True, slotType:Int = 0)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		If slotType = 0 Then slotType = TVTBroadcastMaterialType.PROGRAMME

		Return GetPlayerProgrammePlan(Self.ME).GetBroadcastMaterialInPlanCount(referenceID, day, includePlanned, includeStartedYesterday, slotType)
	End Method


	'return all broadcastmaterials within the defined timespan
	Method of_GetBroadcastMaterialInTimeSpan:TLuaFunctionResult(objectType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1, includeStartingEarlierObject:Int=True, requireSameType:Int=False)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local bm:TBroadcastMaterial[] = GetPlayerProgrammePlan(Self.ME).GetObjectsInTimeSpan(objectType, dayStart, hourStart, dayEnd, hourEnd, includeStartingEarlierObject, requireSameType)
		Return TLuaFunctionResult.Create(Self.RESULT_OK, bm)
	End Method


	'return an array with broadcastmaterial (or null on outages!) for each
	'time slot within the defined timespan! 
	Method of_GetBroadcastMaterialSlotsInTimeSpan:TLuaFunctionResult(objectType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local bm:TBroadcastMaterial[] = GetPlayerProgrammePlan(Self.Me).GetObjectSlotsInTimeSpan(objectType, dayStart, hourStart, dayEnd, hourEnd)
		Return TLuaFunctionResult.Create(Self.RESULT_OK, bm)
	End Method


	Method of_GetBroadcastMaterialProgrammedCountInTimeSpan:Int(materialSource:TBroadcastMaterialSource, slotType:Int=0, dayStart:Int=-1, hourStart:Int=-1, dayEnd:Int=-1, hourEnd:Int=-1)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		Return GetPlayerProgrammePlan(Self.ME).GetBroadcastMaterialSourceProgrammedCountInTimeSpan(materialSource, slotType, dayStart, hourStart, dayEnd, hourEnd)
	End Method


	'returns the broadcast material (in result.data) at the given slot
	Method of_getAdvertisementSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local material:TBroadcastMaterial = GetPlayerProgrammePlan(Self.ME).GetAdvertisement(day, hour)
		If material
			Return TLuaFunctionResult.Create(Self.RESULT_OK, material)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	Method of_getAdContractCount:Int()
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		Return GetPlayerProgrammeCollection(Self.ME).GetAdContractCount()
	End Method


	Method of_getAdContracts:TLuaFunctionResult()
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local contracts:TAdContract[] = GetPlayerProgrammeCollection(Self.ME).GetAdContractsArray()
		If contracts
			Return TLuaFunctionResult.Create(Self.RESULT_OK, contracts)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method



	Method of_getAdContractAtIndex:TAdContract(arrayIndex:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Local obj:TAdContract = GetPlayerProgrammeCollection(Self.ME).GetAdContractAtIndex(arrayIndex)
		If obj Then Return obj Else Return Null
	End Method


	Method of_getAdContractByID:TAdContract(id:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Local obj:TAdContract = GetPlayerProgrammeCollection(Self.ME).GetAdContract(id)
		If obj Then Return obj Else Return Null
	End Method


	'Set content of a programme slot
	'=====
	'materialSource might be "null" to clear a time slot
	'or of types: "TProgrammeLicence" or "TAdContract"
	'returns: (TVT.)RESULT_OK, RESULT_WRONGROOM, RESULT_NOTFOUND
	Method of_setAdvertisementSlot:Int(materialSource:Object, day:Int=-1, hour:Int=-1)
'		If Not _PlayerInRoom("office") Then Return self.RESULT_WRONGROOM
		'even if player has access to room, only owner can manage things here
'		If Not _PlayerOwnsRoom() Then Return self.RESULT_WRONGROOM

		Local broadcastMaterial:TBroadcastMaterial
		'create a broadcast material out of the given source
		If materialSource
			broadcastMaterial = GetPlayerProgrammeCollection(Self.ME).GetBroadcastMaterial(materialSource)
			If Not broadcastMaterial Then Return Self.RESULT_FAILED
		EndIf

		'skip setting the slot if already done
		Local existingMaterial:TBroadcastMaterial = GetPlayerProgrammePlan(Self.ME).GetAdvertisement(day, hour)
		If existingMaterial And broadcastMaterial
			If broadcastMaterial.GetReferenceID() = existingMaterial.GetReferenceID() And broadcastMaterial.materialType = existingMaterial.materialType
				Return Self.RESULT_SKIPPED
			EndIf
		Else
			'both empty
			If Not existingMaterial And Not broadcastMaterial
				Return Self.RESULT_SKIPPED
			EndIf
		EndIf


		If GetPlayerProgrammePlan(Self.ME).SetAdvertisementSlot(broadcastMaterial, day, hour)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_NOTALLOWED
		EndIf
	End Method


	'returns the broadcast material (in result.data) at the given slot
	Method of_getProgrammeSlot:TLuaFunctionResult(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local material:TBroadcastMaterial = GetPlayerProgrammePlan(Self.ME).GetProgramme(day, hour)
		If material
			Return TLuaFunctionResult.Create(Self.RESULT_OK, material)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	'Set content of a programme slot
	'=====
	'materialSource might be "null" to clear a time slot
	'or of types: "TProgrammeLicence" or "TAdContract"
	'returns: (TVT.)RESULT_OK, RESULT_WRONGROOM, RESULT_NOTFOUND
	Method of_SetProgrammeSlot:Int(materialSource:Object, day:Int=-1, hour:Int=-1)
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM
		'even if player has access to room, only owner can manage things here
		If Not _PlayerOwnsRoom() Then Return Self.RESULT_WRONGROOM

		'create a broadcast material out of the given source
		Local broadcastMaterial:TBroadcastMaterial
		If materialSource
			broadcastMaterial = GetPlayerProgrammeCollection(Self.ME).GetBroadcastMaterial(materialSource)
			If Not broadcastMaterial Then Return Self.RESULT_FAILED
		EndIf

		'skip setting the slot if already done
		Local existingMaterial:TBroadcastMaterial = GetPlayerProgrammePlan(Self.ME).GetProgramme(day, hour)
		If existingMaterial and broadcastMaterial
			If broadcastMaterial.GetReferenceID() = existingMaterial.GetReferenceID() And broadcastMaterial.materialType = existingMaterial.materialType
				TPlayerProgrammePlan.FixDayHour(day, hour)
				If existingMaterial.programmedDay = day and existingMaterial.programmedHour = hour
					Return Self.RESULT_SKIPPED
				EndIf
			EndIf
		EndIf


		If GetPlayerProgrammePlan(Self.ME).SetProgrammeSlot(broadcastMaterial, day, hour)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_NOTALLOWED
		EndIf
	End Method


	Method of_getProgrammeLicenceByID:TProgrammeLicence(id:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Local obj:TProgrammeLicence = GetPlayerProgrammeCollection(Self.ME).GetProgrammeLicence(id)
		If obj Then Return obj Else Return Null
	End Method


	Method of_getProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("office") Then Return Self.RESULT_WRONGROOM

		Return getProgrammeLicenceCount()
	End Method


	Method of_getProgrammeLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=-1)
		If Not _PlayerInRoom("office") Then Return Null

		Return GetProgrammeLicenceAtIndex(arrayIndex)
	End Method


	'=== NEWS ROOM ===

	Method ne_getTotalNewsAbonnementFees:Int()
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return Self.RESULT_WRONGROOM

		Return GetPlayerBase(Self.ME).GetTotalNewsAbonnementFees()
	End Method


	Method ne_getNewsAbonnementFee:Int(newsGenreID:Int)
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return Self.RESULT_WRONGROOM

		Return GetNewsAbonnementFee(newsGenreID, GetPlayerBase(Self.ME).GetNewsAbonnement(newsGenreID))
	End Method


	Method ne_getNewsAbonnement:Int(newsGenreID:Int)
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return Self.RESULT_WRONGROOM

		Return GetPlayerBase(Self.ME).GetNewsAbonnement(newsGenreID)
	End Method


	Method ne_setNewsAbonnement:Int(newsGenreID:Int, level:Int)
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return Self.RESULT_WRONGROOM

		If GetPlayerBase(Self.ME).SetNewsAbonnement(newsGenreID, level)
			Return Self.RESULT_OK
		EndIf
	End Method


	'returns the aggression level of the given terrorist group.
	'Invalid groups return the maximum of all.
	'Currently valid are "0" and "1"
	Method ne_getTerroristAggressionLevel:Int(terroristGroup:Int=-1)
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return Self.RESULT_WRONGROOM

		Return GetNewsAgency().GetTerroristAggressionLevel(terroristGroup)
	End Method


	'returns the maximum level the aggression of terrorists could have
	Method ne_getTerroristAggressionLevelMax:Int()
		Return GetNewsAgency().terroristAggressionLevelMax
	End Method


	Method ne_getAllAvailableNews:TLuaFunctionResult()
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local availableNews:TNews[] = GetPlayerProgrammeCollection(Self.ME).GetNewsArray()
		If availableNews
			Return TLuaFunctionResult.Create(Self.RESULT_OK, availableNews)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	Method ne_getAvailableNews:TLuaFunctionResult(arrayIndex:Int=-1)
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local availableNews:TNews = GetPlayerProgrammeCollection(Self.ME).GetNewsAtIndex(arrayIndex)
		If availableNews
			Return TLuaFunctionResult.Create(Self.RESULT_OK, availableNews)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	Method ne_getAllBroadcastedNews:TLuaFunctionResult()
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local broadcastedNews:TNews[] = TNews[](GetPlayerProgrammePlan(Self.ME).GetNewsArray())
		If broadcastedNews
			Return TLuaFunctionResult.Create(Self.RESULT_OK, broadcastedNews)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	Method ne_getBroadcastedNews:TLuaFunctionResult(arrayIndex:Int=-1)
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local broadcastedNews:TNews = TNews(GetPlayerProgrammePlan(Self.ME).GetNewsAtIndex(arrayIndex))
		If broadcastedNews
			Return TLuaFunctionResult.Create(Self.RESULT_OK, broadcastedNews)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	Method ne_doRemoveNewsFromPlan:Int(slot:Int = 0, objectGUID:String = "")
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return Self.RESULT_WRONGROOM

		Local player:TPlayerBase = GetPlayerBase(Self.ME)

		'It does not matter if a player has a master key for the room,
		'only observing is allowed for them
		're-check inRoom (in case of concurrent modification)
		Local inRoom:TRoomBase = TFigure(player.GetFigure()).inRoom
		If Not inRoom or Self.ME <> inRoom.owner Then Return Self.RESULT_WRONGROOM


		Local newsObject:TNews
		If objectGUID
			'news has to be in plan, not collection
			newsObject = TNews(GetPlayerProgrammePlan(Self.ME).GetNews(objectGUID))
		ElseIf slot >= 0
			newsObject = TNews(GetPlayerProgrammePlan(Self.ME).GetNewsAtIndex(slot))
		EndIf
		If Not newsObject Then Return Self.RESULT_NOTFOUND

		If GetPlayerProgrammePlan(Self.ME).RemoveNews(newsObject, slot)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_NOTFOUND
		EndIf
	End Method


	Method ne_doNewsInPlan:Int(slot:Int = 0, objectGUID:String = "")
		If Not (_PlayerInRoom("newsroom") Or _PlayerInRoom("news")) Then Return Self.RESULT_WRONGROOM

		Local player:TPlayerBase = GetPlayerBase(Self.ME)

		'It does not matter if a player has a master key for the room,
		'only observing is allowed for them
		're-check inRoom (in case of concurrent modification)
		Local inRoom:TRoomBase = TFigure(player.GetFigure()).inRoom
		If Not inRoom or Self.ME <> inRoom.owner Then Return Self.RESULT_WRONGROOM


		'news has to be in collection, not plan
		Local news:TNews = TNews(GetPlayerProgrammeCollection(Self.ME).GetNews(objectGUID))
		If Not news
			'if not found, someone is switching from plan slot x to slot y?
			news = TNews(GetPlayerProgrammePlan(Self.ME).GetNews(objectGUID))
			If Not news Then Return Self.RESULT_NOTFOUND
		EndIf

		'skip if on same slot
		If GetPlayerProgrammePlan(Self.ME).GetNewsAtIndex(slot) = news
			Return Self.RESULT_OK
		EndIf


		'place it (and remove from other slots before - if needed)
		If Not GetPlayerProgrammePlan(Self.ME).SetNews(news, slot)
			Return Self.RESULT_FAILED
		Else
			Return Self.RESULT_OK
		EndIf
	End Method



	'=== SPOT AGENCY ===
	Method sa_getSignedAdContractCount:Int()
		If Not _PlayerInRoom("adagency") Then Return Self.RESULT_WRONGROOM

		Return GetPlayerProgrammeCollection(Self.ME).GetAdContractCount()
	End Method


	Method sa_getSignedAdContracts:TLuaFunctionResult()
		If Not _PlayerInRoom("adagency") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local contracts:TAdContract[] = GetPlayerProgrammeCollection(Self.ME).GetAdContractsArray()
		If contracts
			Return TLuaFunctionResult.Create(Self.RESULT_OK, contracts)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method



	Method sa_getSignedAdContractAtIndex:TAdContract(arrayIndex:Int=-1)
		If Not _PlayerInRoom("adagency") Then Return Null

		Local obj:TAdContract = GetPlayerProgrammeCollection(Self.ME).GetAdContractAtIndex(arrayIndex)
		If obj Then Return obj Else Return Null
	End Method


	Method sa_getSignedAdContractByID:TAdContract(id:Int=-1)
		If Not _PlayerInRoom("adagency") Then Return Null

		Local obj:TAdContract = GetPlayerProgrammeCollection(Self.ME).GetAdContract(id)
		If obj Then Return obj Else Return Null
	End Method


	' spots from the vendor
	Method sa_getSpotCount:Int()
		If Not _PlayerInRoom("adagency") Then Return Self.RESULT_WRONGROOM

		Return RoomHandler_AdAgency.GetInstance().GetContractsInStockCount()
	End Method


	Method sa_getSpot:TLuaFunctionResult(position:Int=-1)
		If Not _PlayerInRoom("adagency") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		'out of bounds?
		If position >= RoomHandler_AdAgency.GetInstance().GetContractsInStockCount() Or position < 0 Then Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)

		Local contract:TAdContract = RoomHandler_AdAgency.GetInstance().GetContractByPosition(position)
		If contract
			Return TLuaFunctionResult.Create(Self.RESULT_OK, contract)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	'SIGN the spot with the corresponding ID
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method sa_doBuySpot:Int(contractID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return Self.RESULT_WRONGROOM

		Local contract:TAdContract = RoomHandler_AdAgency.GetInstance().GetContractByID(contractID)
		'this DOES sign in that moment
		If contract
			If RoomHandler_AdAgency.GetInstance().GiveContractToPlayer( contract, Self.ME, True )
				Return Self.RESULT_OK
			Else
				Return Self.RESULT_NOTALLOWED
			EndIf
		EndIf
		Return Self.RESULT_NOTFOUND
	End Method


	'TAKE the spot with the corresponding ID (NOT signed yet)
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method sa_doTakeSpot:Int(contractID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return Self.RESULT_WRONGROOM

		Local contract:TAdContract = RoomHandler_AdAgency.GetInstance().GetContractByID(contractID)
		'this DOES NOT sign - signing is done when leaving the room!
		If contract
			If RoomHandler_AdAgency.GetInstance().GiveContractToPlayer( contract, Self.ME )
				Return Self.RESULT_OK
			Else
				Return Self.RESULT_NOTALLOWED
			EndIf
		EndIf
		Return Self.RESULT_NOTFOUND
	End Method


	'GIVE BACK the spot with the corresponding ID (if not signed yet)
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method sa_doGiveBackSpot:Int(contractID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return Self.RESULT_WRONGROOM

		Local contract:TAdContract = GetPlayerProgrammeCollection(Self.ME).GetUnsignedAdContractFromSuitcase(contractID)

		If contract And RoomHandler_AdAgency.GetInstance().TakeContractFromPlayer( contract, Self.ME )
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_NOTFOUND
		EndIf
	End Method

	'=== SCRIPT AGENCY ===

	'Get all scripts from script agency
	'Returns: LuaFunctionResult (resultID, scripts)
	Method da_getScripts:TLuaFunctionResult()
		If Not _PlayerInRoom("scriptagency") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local scripts:TList = RoomHandler_ScriptAgency.GetInstance().GetScriptsInStock()
		If scripts
			Return TLuaFunctionResult.Create(Self.RESULT_OK, scripts)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method

	'BUY a script
	'Returns result-ID: WRONGROOM / OK / FAILED
	Method da_buyScript:Int(script:TScript)
		If Not _PlayerInRoom("scriptagency") Then Return Self.RESULT_WRONGROOM

		Return RoomHandler_ScriptAgency.GetInstance().SellScriptToPlayer(script, Self.ME, False)
	End Method

	'Get number of jobs - may be too expensive due to big cast
	Method da_getJobCount:Int(script:TScript)
		If Not _PlayerInRoom("scriptagency") Then Return Self.RESULT_WRONGROOM

		Return script.GetJobs().length
	End Method

	'=== STUDIO ===

	'Ensure a script is placed in the studio; get all possible concepts
	'if there is no script at all (studio or suitcase) return NOTFOUND to indicate a script must be purchased
	Method st_dropScriptAndGetConcepts:Int()
		If Not _PlayerInRoom("studio") Then Return Self.RESULT_WRONGROOM

		local room:Int = getPlayerRoom()
		local script:TScript = RoomHandler_Studio.GetInstance().GetCurrentStudioScript(room)

		If not script
			local scripts:TList = GetPlayerProgrammeCollection(Self.ME).suitcaseScripts
			'TODO may be more than one - choose most suitable - consider room size and potential
			If Not scripts.IsEmpty()
				script:TScript = TScript(scripts.first())
			EndIf
		EndIf

		If script
			Local pcc:TProductionConceptCollection = TProductionConceptCollection.GetInstance()
			Local rh:RoomHandler_Studio = RoomHandler_Studio.GetInstance()
			rh.SetCurrentStudioScript(script, room, False)

			If script.IsSeries()
				For Local i:Int = 0 To script.GetEpisodes()-1
					Local subScript:TScript = TScript(script.GetSubScriptAtIndex(i))
					If pcc.CanCreateProductionConcept(subScript) then rh.CreateProductionConcept(Self.ME, subScript)
				Next
			Else
				If pcc.CanCreateProductionConcept(script) then rh.CreateProductionConcept(Self.ME, script)
			EndIf
			Return Self.RESULT_OK
		EndIf
		Return Self.RESULT_NOTFOUND
	End Method

	'Start a production
	'Returns result-ID: WRONGROOM / OK / FAILED / NOT_FOUND
	Method st_StartProduction:Int()
		If Not _PlayerInRoom("studio") Then Return Self.RESULT_WRONGROOM

		local room:Int = getPlayerRoom()
		local script:TScript = RoomHandler_Studio.GetInstance().GetCurrentStudioScript(room)
		If script
			If GetProductionManager().StartProductionInStudio(room, script) > 0
				Return Self.RESULT_OK
			else
				Return Self.RESULT_FAILED
			EndIf
		Else
			Return Self.RESULT_NOTFOUND
		EndIf
	End Method

	'=== SUPERMARKET ===

	'plan all potential productions; handle already planned productions gracefully
	'Returns result-ID: WRONGROOM / OK / FAILED / NOT_FOUND
	'ATTENTION:
	' oneBlockBudgetFactor read as "string" instead of as "float"
	' required until brl.reflection correctly handles "float parameters" 
	' in release and debug builds)
	' GREP-key: "brlreflectionbug"
	Method sm_PlanProduction:Int(budget:Int, oneBlockBudgetFactorAsString:String)
		Local oneBlockBudgetFactor:Float = Float(oneBlockBudgetFactorAsString)

		If Not _PlayerInRoom("supermarket") Then Return Self.RESULT_WRONGROOM
		Local result:Int = Self.RESULT_NOTFOUND
		Local producer:TProgrammeProducer = new TProgrammeProducer
		For Local pc:TProductionConcept = eachin GetPlayerProgrammeCollection(Self.ME).GetProductionConcepts()
			If pc
				If pc.IsDepositPaid()
					'nothing to plan
					result = Self.RESULT_OK
				Else
					Local budgetToUse:Int = budget
					result = Self.RESULT_FAILED
					If pc.script.GetBlocks() = 1 then budgetToUse = budgetToUse * oneBlockBudgetFactor
					producer.budget = budgetToUse
					producer.experience = 75
					If budgetToUse < 400000 then producer.preferCelebrityCastRateSupportingRole = 60
					Local maxCost:Int = 0
					Local pcCost:Int=-1
					For Local i:Int = 1 To 15
						producer.ChooseProductionCompany(pc, pc.script)
						producer.ChooseCast(pc, pc.script)
						producer.ChooseFocusPoints(pc, pc.script)
						pcCost = pc.GetTotalCost()
						If pcCost <= budgetToUse and pcCost > maxCost Then maxCost = pcCost
						'in order to inspect the concept, do not pay the deposit and do not return OK
						'then you can send the AI to the supermarket multiple times

						'If the costs are (much) below budget, maybe more money can't be spent
						'do another round trying to reach the maximum budget used so far
						If pcCost >= budgetToUse * 0.75 and pcCost <= budgetToUse and pc.PayDeposit() = True
							result = Self.RESULT_OK
							Exit
						EndIf
					Next
					If maxCost > 0 
						producer.experience = 90
						For Local i:Int = 1 To 15
							producer.ChooseProductionCompany(pc, pc.script)
							producer.ChooseCast(pc, pc.script)
							producer.ChooseFocusPoints(pc, pc.script)
							pcCost = pc.GetTotalCost()
							If pcCost>= maxCost * 0.8 and pcCost <= maxCost and pc.PayDeposit() = True
								result = Self.RESULT_OK
								Exit
							EndIf
						Next
					EndIf
				EndIf
			EndIf
		Next

		Return result
	End Method

	'=== MOVIE AGENCY ===
	'main screen

	'Get Amount of licences available at the movie agency
	'Returns: amount
	Method md_getProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("movieagency") Then Return Self.RESULT_WRONGROOM

		Return RoomHandler_MovieAgency.GetInstance().GetProgrammeLicencesInStock()
	End Method


	'Get licence at a specific position from movie agency
	'Returns: LuaFunctionResult (resultID, licence)
	Method md_getProgrammeLicence:TLuaFunctionResult(position:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		'out of bounds?
		If position >= RoomHandler_MovieAgency.GetInstance().GetProgrammeLicencesInStock() Or position < 0 Then Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)

		Local licence:TProgrammeLicence = RoomHandler_MovieAgency.GetInstance().GetProgrammeLicenceByPosition(position)
		If licence
			Return TLuaFunctionResult.Create(Self.RESULT_OK, licence)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	'Get all licences from movie agency
	'Returns: LuaFunctionResult (resultID, licences)
	Method md_getProgrammeLicences:TLuaFunctionResult()
		If Not _PlayerInRoom("movieagency") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)


		Local licences:TProgrammeLicence[] = RoomHandler_MovieAgency.GetInstance().GetProgrammeLicences()
		If licences And licences.length > 0
			Return TLuaFunctionResult.Create(Self.RESULT_OK, licences)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	'BUY a programme licence with the corresponding ID
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method md_doBuyProgrammeLicence:Int(licenceID:Int=-1)
		If Not _PlayerInRoom("movieagency") Then Return Self.RESULT_WRONGROOM

		Local licence:TProgrammeLicence = RoomHandler_MovieAgency.GetInstance().GetProgrammeLicenceByID(licenceID)
		If Licence Then Return RoomHandler_MovieAgency.GetInstance().SellProgrammeLicenceToPlayer(licence, Self.ME)

		Return Self.RESULT_NOTFOUND
	End Method


	'SELL a programme licence with the corresponding ID
	'Returns result-IDs: WRONGROOM / OK / NOTFOUND
	Method md_doSellProgrammeLicence:Int(licenceID:Int=-1)
		If Not _PlayerInRoom("movieagency") Then Return Self.RESULT_WRONGROOM

		For Local licence:TProgrammeLicence = EachIn GetPlayerProgrammeCollection(Self.ME).suitcaseProgrammeLicences
			If licence.id = licenceID Then Return RoomHandler_MovieAgency.GetInstance().BuyProgrammeLicenceFromPlayer(licence)
		Next
		Return Self.RESULT_NOTFOUND
	End Method



	'=== MOVIE DEALER ===
	'Movie Agency - Auctions

	'GET an auction programme block at the given array position
	'Returns: TAuctionProgrammeBlocks
	Method md_getAuctionProgrammeLicenceBlock:TAuctionProgrammeBlocks(ArrayID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return Null
		If ArrayID >= TAuctionProgrammeBlocks.List.Count() Or arrayID < 0 Then Return Null

		Local Block:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(TAuctionProgrammeBlocks.List.ValueAtIndex(ArrayID))
		If Block And Block.GetLicence() Then Return Block Else Return Null
	End Method


	Method md_getAuctionProgrammeLicenceBlockIndex:Int(licenceID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return Null

		Local block:TAuctionProgrammeBlocks
		For Local i:Int = 0 Until TAuctionProgrammeBlocks.List.Count()
			block = TAuctionProgrammeBlocks(TAuctionProgrammeBlocks.List.ValueAtIndex(i))
 			If block.GetLicence() And block.licence.GetReferenceID() = licenceID Then Return i
		Next

		Return Self.RESULT_NOTFOUND
	End Method


	Method md_getAuctionProgrammeLicence:TLuaFunctionResult(ArrayID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		If ArrayID >= TAuctionProgrammeBlocks.List.Count() Or arrayID < 0 Then Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)

		Local Block:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(TAuctionProgrammeBlocks.List.ValueAtIndex(ArrayID))
		If Block And Block.licence
			Return TLuaFunctionResult.Create(Self.RESULT_OK, Block.licence)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	Method md_getAuctionProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("movieagency") Then Return Self.RESULT_WRONGROOM

		Return TAuctionProgrammeBlocks.List.count()
	End Method


	Method md_doBidAuctionProgrammeLicence:Int(licenceID:Int= -1)
		If Not _PlayerInRoom("movieagency") Then Return Self.RESULT_WRONGROOM

		For Local Block:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			If Block.GetLicence() And Block.licence.GetReferenceID() = licenceID Then Return Block.SetBid( Self.ME )
		Next

		Return Self.RESULT_NOTFOUND
	End Method


	Method md_doBidAuctionProgrammeLicenceAtIndex:Int(ArrayID:Int= -1)
		If Not _PlayerInRoom("movieagency") Then Return Self.RESULT_WRONGROOM

		Local Block:TAuctionProgrammeBlocks = Self.md_getAuctionProgrammeLicenceBlock(ArrayID)
		If Block And Block.GetLicence() Then Return Block.SetBid( Self.ME ) Else Return Self.RESULT_NOTFOUND
	End Method


	Method md_GetAuctionProgrammeLicenceNextBid:Int(ArrayID:Int= -1)
		If Not _PlayerInRoom("movieagency") Then Return Self.RESULT_WRONGROOM

		Local Block:TAuctionProgrammeBlocks = Self.md_getAuctionProgrammeLicenceBlock(ArrayID)
		If Block And Block.GetLicence() Then Return Block.GetNextBid(Self.ME) Else Return Self.RESULT_NOTFOUND
	End Method


	Method md_GetAuctionProgrammeLicenceHighestBidder:Int(ArrayID:Int= -1)
		If Not _PlayerInRoom("movieagency") Then Return Self.RESULT_WRONGROOM

		Local Block:TAuctionProgrammeBlocks = Self.md_getAuctionProgrammeLicenceBlock(ArrayID)
		If Block And Block.GetLicence() Then Return Block.bestBidder Else Return Self.RESULT_NOTFOUND
	End Method



	'=== BOSS ROOM ===

	'returns maximum credit limit (regardless of already taken credit)
	Method bo_getCreditMaximum:Int()
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		Return GetPlayerBoss(Self.ME).GetCreditMaximum()
	End Method


	'returns how much credit the boss will give (maximum minus taken credit)
	Method bo_getCreditAvailable:Int()
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		Return GetPlayerBase(Self.ME).GetCreditAvailable()
	End Method


	'amounts bigger than the available credit just take all possible
	Method bo_doTakeCredit:Int(amount:Int)
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		If GetPlayerBoss(Self.ME).PlayerTakesCredit(amount)
			Return True
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	'amounts bigger than the credit taken will repay everything
	'amounts bigger than the owned money will fail
	Method bo_doRepayCredit:Int(amount:Int)
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		If GetPlayerBoss(Self.ME).PlayerRepaysCredit(amount)
			Return True
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method

	'returns the mood of the boss - rounded to 10% steps
	'(makes it a bit harder for the AI)
	'TODO: remove step rounding if players get a exact value displayed
	'      somehow
	Method bo_getBossMoodlevel:Int()
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM
		Return Int(GetPlayerBoss(Self.ME).GetMood()) / 10
	End Method


	Method bo_GetCurrentAwardType:Int()
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		Local award:TAward = GetAwardCollection().GetCurrentAward()
		If award Then Return award.awardType

		Return Self.RESULT_NOTFOUND
	End Method


	'we return texts as FOR NOW 32bit builds fail to pass LONG via
	'reflection.mod
	Method bo_GetCurrentAwardStartTimeString:String()
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		Local award:TAward = GetAwardCollection().GetCurrentAward()
		If award Then Return award.GetStartTime()

		Return Self.RESULT_NOTFOUND
	End Method


	'we return texts as FOR NOW 32bit builds fail to pass LONG via
	'reflection.mod
	Method bo_GetCurrentAwardEndTimeString:String()
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		Local award:TAward = GetAwardCollection().GetCurrentAward()
		If award Then Return award.GetEndTime()

		Return Self.RESULT_NOTFOUND
	End Method


	Method bo_GetNextAwardType:Int()
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		Local award:TAward = GetAwardCollection().GetNextAward()
		If award Then Return award.awardType

		Return Self.RESULT_NOTFOUND
	End Method


	'we return texts as FOR NOW 32bit builds fail to pass LONG via
	'reflection.mod
	Method bo_GetNextAwardStartTimeString:String()
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		Local award:TAward = GetAwardCollection().GetNextAward()
		If award Then Return award.GetStartTime()

		Return Self.RESULT_NOTFOUND
	End Method


	'we return texts as FOR NOW 32bit builds fail to pass LONG via
	'reflection.mod
	Method bo_GetNextAwardEndTimeString:String()
		If Not _PlayerInRoom("boss") Then Return Self.RESULT_WRONGROOM

		Local award:TAward = GetAwardCollection().GetNextAward()
		If award Then Return award.GetEndTime()

		Return Self.RESULT_NOTFOUND
	End Method

	'=== ELEVATOR PLAN ===

	Method ep_GetSignCount:Int()
		If Not _PlayerInRoom("elevatorplan") Then Return Self.RESULT_WRONGROOM

		Return GetRoomBoard().GetSignCount()
	End Method


	Method ep_GetSignAtIndex:TLuaFunctionResult(arrayIndex:Int = -1)
		If Not _PlayerInRoom("elevatorplan") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local Sign:TRoomBoardSign = GetRoomBoard().GetSignAtIndex(arrayIndex)
		If Sign
			Return TLuaFunctionResult.Create(Self.RESULT_OK, Sign)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	Method ep_IsRentableStudio:Int(sign:TRoomBoardSign)
		If _PlayerInRoom("elevatorplan") And sign
			Local roomId:Int = sign.GetRoomId()
			If roomId
				Local room:TRoom = GetRoomCollection().Get(roomId)
				If room
					If room.IsUsableAsStudio() And room.IsRentable() Then return room.GetSize()
				EndIf
			EndIf
		EndIf
		Return 0
	End Method


	'=== ROOM AGENCY ===
	Method ra_rentStudio:Int(roomId:Int)
		If Not _PlayerInRoom("roomagency") Then Return Self.RESULT_WRONGROOM

		If roomId
			Local room:TRoom = GetRoomCollection().Get(roomId)
			If room.HasOwner() Then Return Self.RESULT_NOTALLOWED
			If room And GetRoomAgency().BeginRoomRental(room, Self.ME, False) Then Return Self.RESULT_OK
		EndIf
		Return Self.RESULT_FAILED
	End Method

	'=== ROOM BOARD ===
	'the plan on the basement which enables switching room signs

	Method rb_GetSignCount:Int()
		If Not _PlayerInRoom("roomboard") Then Return Self.RESULT_WRONGROOM

		Return GetRoomBoard().GetSignCount()
	End Method


	Method rb_GetSignAtIndex:TLuaFunctionResult(arrayIndex:Int = -1)
		If Not _PlayerInRoom("roomboard") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local Sign:TRoomBoardSign = GetRoomBoard().GetSignAtIndex(arrayIndex)
		If Sign
			Return TLuaFunctionResult.Create(Self.RESULT_OK, Sign)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	'returns the sign at the given position
	Method rb_GetSignAtPosition:TLuaFunctionResult(signSlot:Int, signFloor:Int)
		If Not _PlayerInRoom("roomboard") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local Sign:TRoomBoardSign = GetRoomBoard().GetSignByCurrentPosition(signSlot, signFloor)
		If Sign
			Return TLuaFunctionResult.Create(Self.RESULT_OK, Sign)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	'returns the sign which originally was at the given position
	'(might be the same if it wasnt switched)
	Method rb_GetOriginalSignAtPosition:TLuaFunctionResult(signSlot:Int, signFloor:Int)
		If Not _PlayerInRoom("roomboard") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local Sign:TRoomBoardSign = GetRoomBoard().GetSignByOriginalPosition(signSlot, signFloor)
		If Sign
			Return TLuaFunctionResult.Create(Self.RESULT_OK, Sign)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	'returns the first sign leading to the given room(ID)
	Method rb_GetFirstSignOfRoom:TLuaFunctionResult(roomID:Int)
		If Not _PlayerInRoom("roomboard") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local Sign:TRoomBoardSign = GetRoomBoard().GetFirstSignByRoom(roomID)
		If Sign
			Return TLuaFunctionResult.Create(Self.RESULT_OK, Sign)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	'switch two existing signs on the board
	Method rb_SwitchSigns:Int(signA:TRoomBoardSign, signB:TRoomBoardSign)
		If Not _PlayerInRoom("roomboard") Then Return Self.RESULT_WRONGROOM

		If GetRoomBoard().SwitchSigns(signA, signB)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	'switch two existing signs on the board
	Method rb_SwitchSignsByID:Int(signAId:Int, signBId:Int)
		If Not _PlayerInRoom("roomboard") Then Return Self.RESULT_WRONGROOM

		Local signA:TRoomBoardSign = GetRoomBoard().GetSignById(signAId)
		Local signB:TRoomBoardSign = GetRoomBoard().GetSignById(signBId)

		If GetRoomBoard().SwitchSigns(signA, signB)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	'switch signs on the given positions.
	'a potential sign on slotA/floorA will get moved to slotB/floorB
	'and vice versa. It is NOT needed to have to valid signs on there
	Method rb_SwitchSignPositions:Int(slotA:Int, floorA:Int, slotB:Int, floorB:Int)
		If Not _PlayerInRoom("roomboard") Then Return Self.RESULT_WRONGROOM

		If GetRoomBoard().SwitchSignPositions(slotA, floorA, slotB, floorB, Self.ME)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	Method rb_GetSignSlotCount:Int()
		Return GetRoomBoard().slotMax
	End Method


	Method rb_GetSignFloorCount:Int()
		Return GetRoomBoard().floorMax
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
		If Not _PlayerInRoom("archive") Then Return Self.RESULT_WRONGROOM

		Local licence:TProgrammeLicence = GetPlayerProgrammeCollection(Self.ME).GetProgrammeLicenceAtIndex(position)
		If Not licence Then Return Self.RESULT_NOTFOUND
		'Skip series episodes or collection elements
		If licence.HasParentLicence() Then Return Self.RESULT_NOTALLOWED

		If GetPlayerProgrammeCollection(Self.ME).AddProgrammeLicenceToSuitcase(licence)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	'move licence from archive to suitcase
	Method ar_AddProgrammeLicenceToSuitcaseByGUID:Int(guid:String)
		If Not _PlayerInRoom("archive") Then Return Self.RESULT_WRONGROOM

		Local licence:TProgrammeLicence = GetPlayerProgrammeCollection(Self.ME).GetProgrammeLicenceByGUID(guid)
		If Not licence Then Return Self.RESULT_NOTFOUND
		'Skip series episodes or collection elements
		If licence.HasParentLicence() Then Return Self.RESULT_NOTALLOWED

		If GetPlayerProgrammeCollection(Self.ME).AddProgrammeLicenceToSuitcase(licence)
			Return Self.RESULT_OK
		Else
			Return Self.RESULT_FAILED
		EndIf
	End Method


	'move licence from suitcase to archive
	'ATTENTION: if you move multiple licences, position will shift!
	Method ar_RemoveProgrammeLicenceFromSuitcase:Int(position:Int = -1)
		If Not _PlayerInRoom("archive") Then Return Self.RESULT_WRONGROOM

		Local licence:TProgrammeLicence = GetPlayerProgrammeCollection(Self.ME).GetSuitcaseProgrammeLicenceAtIndex(position)
		If Not licence Then Return Self.RESULT_NOTFOUND

		Return GetPlayerProgrammeCollection(Self.ME).RemoveProgrammeLicenceFromSuitcase(licence)
	End Method


	'move licence from suitcase to archive
	Method ar_RemoveProgrammeLicenceFromSuitcaseByGUID:Int(guid:String)
		If Not _PlayerInRoom("archive") Then Return Self.RESULT_WRONGROOM

		Local licence:TProgrammeLicence = GetPlayerProgrammeCollection(Self.ME).GetSuitcaseProgrammeLicenceByGUID(guid)
		If Not licence Then Return Self.RESULT_NOTFOUND

		Return GetPlayerProgrammeCollection(Self.ME).RemoveProgrammeLicenceFromSuitcase(licence)
	End Method


	'returns count of available programme licences in the archive
	Method ar_GetProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("archive") Then Return Self.RESULT_WRONGROOM

		Return GetProgrammeLicenceCount()
	End Method


	'returns the specified licence (if possible)
	Method ar_GetProgrammeLicence:TLuaFunctionResult(position:Int = -1)
		If Not _PlayerInRoom("archive") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local licence:TProgrammeLicence = GetProgrammeLicenceAtIndex(position)
		If licence
			Return TLuaFunctionResult.Create(Self.RESULT_OK, licence)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	'returns amount of licences in suitcase
	Method ar_GetSuitcaseProgrammeLicenceCount:Int()
		If Not _PlayerInRoom("archive") Then Return Self.RESULT_WRONGROOM

		Return GetPlayerProgrammeCollection(Self.ME).GetSuitcaseProgrammeLicenceCount()
	End Method


	'returns the specified licence (if possible)
	Method ar_GetSuitcaseProgrammeLicence:TLuaFunctionResult(position:Int = -1)
		If Not _PlayerInRoom("archive") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local licence:TProgrammeLicence = GetPlayerProgrammeCollection(Self.ME).GetSuitcaseProgrammeLicenceAtIndex(position)
		If licence
			Return TLuaFunctionResult.Create(Self.RESULT_OK, licence)
		Else
			Return TLuaFunctionResult.Create(Self.RESULT_NOTFOUND, Null)
		EndIf
	End Method


	Method ar_GetSuitcaseProgrammeLicences:TLuaFunctionResult()
		If Not _PlayerInRoom("archive") Then Return TLuaFunctionResult.Create(Self.RESULT_WRONGROOM, Null)

		Local licences:TProgrammeLicence[] = GetPlayerProgrammeCollection(Self.ME).GetSuitcaseProgrammeLicencesArray()
		Return TLuaFunctionResult.Create(Self.RESULT_OK, licences)
	End Method
End Type
