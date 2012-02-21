'**************************************************************************************************
' This program was written with BLIde
' Application:
' Author:
' License:
'**************************************************************************************************

Type TNewLuaEngine
	Function Create:TNewLuaEngine()
		Local obj:TNewLuaEngine = New TNewLuaEngine
		' Create the Lua state
		' Load base, math, table, and os libraries
		Return obj
	End Function

	Function LuaState:Byte Ptr()
		Global _luaState:Byte Ptr
		If Not _luaState
			_luaState=luaL_newstate()
'			luaL_openlibs _luaState
			luaopen_base(_luaState)
			luaopen_math(_luaState)
			luaopen_table(_luaState)
			luaopen_os(_luaState)
		EndIf
		Return _luaState
	End Function

	Method KillLuaState()
		If Self.LuaState() Then
			lua_close(Self.LuaState())
			'_luaState = Null
		EndIf
	End Method

	Method RegisterFunction:Int(functionName:String, _func:Byte Ptr)
		lua_register( Self.LuaState(), functionName, _func)
	End Method

	Method RegisterConstantInt(variableName:String, _variable:Int)
		lua_pushinteger( Self.LuaState(), _variable)
		lua_setglobal( Self.LuaState(), variableName )
	End Method

	Method RegisterConstantFloat(variableName:String, _variable:Double)
		lua_pushnumber( Self.LuaState(), _variable)
		lua_setglobal( Self.LuaState(), variableName )
	End Method

	Method LoadScript:Int(scriptFile:String)
		' Run the script so it can set things up
	    If luaL_dofile(Self.LuaState(),scriptFile)
			Local error:String = lua_tostring(Self.LuaState(), -1 )
			Print error
			lua_pop( Self.LuaState(), 1 )
			RuntimeError(error)
			Return False
		Else
			Print "loaded "+scriptFile
			Return True
		EndIf
	End Method

	Method CallFunction:Int(functionName:String)
		Local result:Int = 0
		print "LUA: CallFunction: "+functionName
		lua_getglobal( Self.LuaState(), functionName )
		If lua_type( Self.LuaState(), -1 ) = LUA_TFUNCTION Then
			If lua_pcall( Self.LuaState(), 0, 1, 0 ) Then
				Local error:String = lua_tostring( Self.LuaState(), -1 )
				lua_pop( Self.LuaState(), 1 )
				RuntimeError(error)
			Else
				' Get the result
				result = lua_toboolean( Self.LuaState(), -1 )
			EndIf
		EndIf
		lua_pop( Self.LuaState(), 1 )
		Return result
	End Method

	Method fileToString:String(filename:String)
		Local file:TStream = OpenStream(filename, True, False)
		Return file.ReadString(file.Size())
		file.Close()
	End Method

rem
	Method RegisterType:Int(L:Byte Ptr)
		Local _objects:Int = luaL_optint( L, 1, 1 )
		For Local i:Int = 1 To _objects
			' Push the handle as a light userdata
			lua_pushlightuserdata( L, Byte Ptr(HandleFromObject(New TTYPE)) )
		Next
		Return _objects
	End Method

	Method ReleaseType:Int(L:Byte Ptr)
		For Local stackidx:Int = 1 To lua_gettop(L)
			If lua_islightuserdata( L, stackidx ) Then
				Local handle:Int = Int(lua_touserdata( L, stackidx ))
				Assert TTYpe(HandleToObject(handle)) Else "Attempt to release handle for object that is not a TType"
				Release handle
			EndIf
		Next
		Return 0
	End Method

endrem
End Type
rem
Function killLua()
	NewLuaEngine.KillLuaState()
End Function

Function Test(param:Byte Ptr)
	Print String.FromCString(lua_tostring(NewLuaEngine.LuaState(), -1))
End Function

Global NewLuaEngine:TNewLuaEngine = New TNewLuaEngine
' Kill Lua state once the program ends
OnEnd(killLua)
Global LuaFunctions:TLuaFunctions = New TLuaFunctions
NewLuaEngine.RegisterFunction("PrintOut",Test)
NewLuaEngine.LoadScript("test.lua")
endrem


Type TLuaEngine
	Field _LuaClass:TLuaClass
	Field _LuaInstance:TLuaObject

	Function Create:TLuaEngine()
		Local obj:TLuaEngine = New TLuaEngine
		obj._LuaClass = New TLuaClass
		obj._LuaInstance = TLuaObject.Create( obj._LuaClass,Null )
		Return obj
	End Function

	Method LoadSource(source:String)
		Self._LuaClass.SetSourceCode(source)
		Self._LuaInstance = TLuaObject.Create( Self._LuaClass,Null )
	End Method

	Method CallLuaFunction(name:String, params:Object[] = Null)
		Self._LuaInstance.Invoke name,params
	End Method

	'Once registered, the object can be accessed from within Lua scripts using the @ObjName identifer.
	Method RegisterBlitzmaxObject(Obj:Object, ObjName:String)
		LuaRegisterObject Obj, ObjName
	End Method
End Type


'SuperStrict
Global activeKI:KI = Null

'Function getScriptEnv:TLuaScriptEngine()
'	Return activeKI.scriptEnv
'End Function

Function getLuaEngine:TLuaEngine()
	Return activeKI.LuaEngine
End Function

Type KI
	Field playerId:Byte
	Field LuaEngine:TLuaEngine
	Field scriptName:String
	Field scriptAsString:String
	Field scriptConstants:String
	Field MyLuaState:Byte Ptr
	Field inRoom:Byte
	Field LastErrorNumber:Int = 0


	Function Create:KI(pId:Byte, script:String)
		Local loadtime:Int = MilliSecs()
		Local ret:KI = New KI
		ret.playerId = pId
'		ret.MyLuaState = lual_newstate()
		ret.LuaEngine = TLuaEngine.Create()
		ret.scriptName = script
		ret.reloadScript()
		KI_EventManager.registerKI(ret)
		Print "Player " + pId + ": AI loaded in " + Float(MilliSecs() - loadtime) + "ms"
		Return ret
	End Function

	Method PrintErrors()
'		If Self.scriptEnv.GetLastErrorNumber() <> LastErrorNumber
'			Print "[LUA ERROR #" + Self.scriptEnv.GetLastErrorNumber() + "] " + Self.scriptEnv.GetLastErrorString()
'		EndIf
'		Self.LastErrorNumber = Self.scriptEnv.GetLastErrorNumber()
	End Method

	Method Stop()
'		scriptEnv.ShutDown()
		KI_EventManager.unregisterKI(Self)
	End Method

	Method reloadScript()
		scriptAsString = fileToString(scriptName)
		'initScriptFunctions()
		initScriptVariables()
		Local str:String = scriptConstants + Chr:String(10) + Chr:String(13) + scriptAsString
		Self.LuaEngine.LoadSource(str)
	End Method



	Method initScriptVariables()
		Global LuaFunctions:TLuaFunctions = New TLuaFunctions
		Self.LuaEngine.RegisterBlitzmaxObject(LuaFunctions, "TVT")

		scriptConstants = ""
		addScriptConstant("PLAYER1", 1)
		addScriptConstant("PLAYER2", 2)
		addScriptConstant("PLAYER3", 3)
		addScriptConstant("PLAYER4", 4)
		addScriptConstant("ME", playerid)

		addScriptConstant("MAXMOVIES", 50)
		addScriptConstant("MAXMOVIESPARGENRE", 8)
		addScriptConstant("MAXSPOTS", Game.maxContractsAllowed)


		addScriptConstant("MOVIE_GENRE_ACTION", 0)
		addScriptConstant("MOVIE_GENRE_THRILLER", 1)
		addScriptConstant("MOVIE_GENRE_SCIFI", 2)
		addScriptConstant("MOVIE_GENRE_COMEDY", 3)
		addScriptConstant("MOVIE_GENRE_HORROR", 4)
		addScriptConstant("MOVIE_GENRE_LOVE", 5)
		addScriptConstant("MOVIE_GENRE_EROTIC", 6)
		addScriptConstant("MOVIE_GENRE_WESTERN", 7)
		addScriptConstant("MOVIE_GENRE_LIVE", 8)
		addScriptConstant("MOVIE_GENRE_KIDS", 9)
		addScriptConstant("MOVIE_GENRE_CARTOON", 10)
		addScriptConstant("MOVIE_GENRE_MUSIC", 11)
		addScriptConstant("MOVIE_GENRE_SPORT", 12)
		addScriptConstant("MOVIE_GENRE_CULTURE", 13)
		addScriptConstant("MOVIE_GENRE_FANTASY", 14)
		addScriptConstant("MOVIE_GENRE_YELLOWPRESS", 15)
		addScriptConstant("MOVIE_GENRE_NEWS", 16)
		addScriptConstant("MOVIE_GENRE_SHOW", 17)
		addScriptConstant("MOVIE_GENRE_MONUMENTAL", 18)

		addScriptConstant("NEWS_GENRE_TECHNICS", 3)
		addScriptConstant("NEWS_GENRE_POLITICS", 0)
		addScriptConstant("NEWS_GENRE_SHOWBIZ", 1)
		addScriptConstant("NEWS_GENRE_SPORT", 2)
		addScriptConstant("NEWS_GENRE_CURRENTS", 4)

		addScriptConstant("ROOM_TOWER", 0)
		addScriptConstant("ROOM_MOVIEAGENCY", TRooms.GetRoom("movieagency", 0).uniqueID)
		addScriptConstant("ROOM_ADAGENCY", TRooms.GetRoom("adagency", 0).uniqueID)
		addScriptConstant("ROOM_ROOMBOARD", TRooms.GetRoom("roomboard", - 1).uniqueID)
		addScriptConstant("ROOM_PORTER", TRooms.GetRoom("porter", - 1).uniqueID)
		addScriptConstant("ROOM_BETTY", TRooms.GetRoom("betty", 0).uniqueID)
		addScriptConstant("ROOM_SUPERMARKET", TRooms.GetRoom("supermarket", 0).uniqueID)
		addScriptConstant("ROOM_ROOMAGENCY", TRooms.GetRoom("roomagency", 0).uniqueID)
		addScriptConstant("ROOM_PEACEBROTHERS", TRooms.GetRoom("peacebrothers", - 1).uniqueID)
		addScriptConstant("ROOM_SCRIPTAGENCY", TRooms.GetRoom("scriptagency", 0).uniqueID)
		addScriptConstant("ROOM_NOTOBACCO", TRooms.GetRoom("notobacco", - 1).uniqueID)
		addScriptConstant("ROOM_TOBACCOLOBBY", TRooms.GetRoom("tobaccolobby", - 1).uniqueID)
		addScriptConstant("ROOM_GUNSAGENCY", TRooms.GetRoom("gunsagency", - 1).uniqueID)
		addScriptConstant("ROOM_VRDUBAN", TRooms.GetRoom("vrduban", - 1).uniqueID)
		addScriptConstant("ROOM_FRDUBAN", TRooms.GetRoom("frduban", - 1).uniqueID)

		addScriptConstant("ROOM_OFFICE_PLAYER_ME", TRooms.GetRoom("office", playerid).uniqueID)
		addScriptConstant("ROOM_STUDIOSIZE1_PLAYER_ME", TRooms.GetRoom("studiosize1", playerid).uniqueID)
		addScriptConstant("ROOM_BOSS_PLAYER_ME", TRooms.GetRoom("chief", playerid).uniqueID)
		addScriptConstant("ROOM_NEWSAGENCY_PLAYER_ME", TRooms.GetRoom("news", playerid).uniqueID)
		addScriptConstant("ROOM_ARCHIVE_PLAYER_ME", TRooms.GetRoom("archive", playerid).uniqueID)


		Local i:Int = 0
		For i = 1 To 4
			addScriptConstant("ROOM_ARCHIVE_PLAYER" + i, TRooms.GetRoom("archive", i).uniqueID)
			addScriptConstant("ROOM_NEWSAGENCY_PLAYER" + i, TRooms.GetRoom("news", i).uniqueID)
			addScriptConstant("ROOM_BOSS_PLAYER" + i, TRooms.GetRoom("chief", i).uniqueID)
			addScriptConstant("ROOM_OFFICE_PLAYER" + i, TRooms.GetRoom("office", i).uniqueID)
			addScriptConstant("ROOM_STUDIOSIZE_PLAYER" + i, TRooms.GetRoom("studiosize1", i).uniqueID)
		Next
	End Method

	Method CallOnLoad(savedluascript:String="")
	    activeKI = Self
		Local args:Object[1]
		args[0] = savedluascript
		Self.LuaEngine.CallLuaFunction("OnLoad", args)
	'	Self.PrintErrors()
	End Method

	Method CallOnSave()
	    activeKI = Self
		Local args:Object[1]
		args[0] = "5.0"
		Self.LuaEngine.CallLuaFunction("OnSave", args)
	'	Self.PrintErrors()
	End Method

	Method CallOnMinute()
	    activeKI = Self
		Local args:Object[1]
		args[0] = "5.0"
		'print "KI call on Minute"
		Self.LuaEngine.CallLuaFunction("OnMinute", args)
	'	Self.PrintErrors()
	End Method

	Method CallOnChat(text:String = "")
	    activeKI = Self
	    Try
			Local args:Object[1]
			args[0] = text
			Self.LuaEngine.CallLuaFunction("OnChat", args)
	'		Self.PrintErrors()
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion onChat nicht"
		End Try
	End Method

	Method CallOnReachRoom(roomId:Byte)
	    activeKI = Self
	    inRoom = roomId
	    Try
	'	    Self.scriptEnv.BeginLUAFunctionCall()
	'		Self.scriptEnv.AddNumberParameter(roomId)
	'		Self.scriptEnv.CallFunction("OnReachRoom", 0)
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion OnReachRoom nicht"
		End Try
	End Method

	Method CallOnLeaveRoom()
	    activeKI = Self
	    inRoom = -1
	    Try
	'	    Self.scriptEnv.BeginLUAFunctionCall()
	'		Self.scriptEnv.CallFunction("OnLeaveRoom", 0)
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion OnLeaveRoom nicht"
		End Try
	End Method

	Method CallOnDayBegins()
	    activeKI = Self
	    Try
	'	    Self.scriptEnv.BeginLUAFunctionCall()
	'		Self.scriptEnv.CallFunction("OnDayBegins", 0)
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion OnDayBegins nicht"
		End Try
	End Method

	Method CallOnMoneyChanged()
	    activeKI = Self
	    Try
	'	    Self.scriptEnv.BeginLUAFunctionCall()
	'		Self.scriptEnv.CallFunction("OnMoneyChanged", 0)
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion OnMoneyChanged nicht"
		End Try
	End Method

	Method fileToString:String(filename:String)
		Local file:TStream = OpenStream(filename, True, False)
		Return file.ReadString(file.Size())
		file.Close()
rem
		Local file:TStream = ReadFile(filename)
		Local line:String
		Local ret:String

		While Not Eof(file)
        	line = ReadLine(file)
			ret = ret + line + Chr$(10) + Chr$(13)
    	Wend

		file.Close()
		Return ret
endrem
	End Method

	Method addScriptConstant(name$, value$)
		scriptConstants = scriptConstants + Chr:String(10) + Chr:String(13) + name + " = " + value
		'
	End Method
End Type

Type TLuaFunctions
	Function Lua_GetString:String(luaState:Byte Ptr)
	 Return String.FromCString(lua_tostring(luaState, -1))
	End Function

	'getInt ist nicht moeglich, da Lua "number" zurueckgibt, was standardmaessig dem Double entspricht
	Function Lua_GetDouble:Double(luaState:Byte Ptr)
	 Return lua_toNumber(luaState, -1)
	End Function

	Method PrintOut:Int(text:String)
		Print text
		Return 1
	EndMethod

	Method SendToChat:Int(ChatText:String)
		Local PlayerID:Int = activeKI.playerId
		If Player[PlayerID] <> Null
			InGame_Chat.AddEntry("", ChatText, PlayerID, "", "", MilliSecs())
			Local KIcommand:Int = 0
			If PlayerID = 1
				If ChatText.Length > 4
				If Left(ChatText, 1) = "/"
					KIcommand = 1
					Local KIPlayerID:Int = Int(Mid(chattext, 2,1))
					If Player[KIPlayerID] <> Null
						If Player[KIplayerID].Figure.IsAI()
							Local chatvalue:String = Right(chattext, chattext.Length - 3)
							Print chatvalue
							Player[KIplayerID].PlayerKI.CallOnChat(chatvalue)
						End If
					EndIf
				End If
				EndIf
			End If

		End If
		Return 1
	EndMethod


	Method GetPlayerPosX:Int(PlayerID:Int = Null)
		If Player[PlayerID] <> Null
		  ' ReturnNumberToLua gibt dem Befehl des Luascriptes (GetPlayerPosX)
		  ' einen Wert zurueck...
		  Return(Floor(Player[PlayerID].figure.pos.x))
		EndIf
		Return - 1
	End Method

	Method GetPlayerTargetPosX:Int(PlayerID:Int = Null)
		If Player[PlayerID] <> Null
		  Return(Floor(Player[PlayerID].figure.targetx))
		EndIf
		Return - 1
	End Method

	Method SetPlayerTargetPosX:Int(PlayerID:Int = Null, newTargetX:Int = 0)
		If Player[PlayerID] <> Null
		  Player[PlayerID].figure.changeTarget(newTargetX, Building.y + Building.GetFloorY(Player[PlayerID].figure.onfloor))
		Else
			Return - 1
		EndIf
	End Method
	' ###########################################################

	Method getMillisecs:Int()
		Return MilliSecs()
	End Method

	Method getTime:Int()
		Return Game.timeSinceBegin
	End Method

	Method getPlayerMaxAudience:Int()
		Local PlayerID:Int = activeKI.playerId
		If Player[PlayerID] <> Null
			Return Player[PlayerID].maxaudience
		Else
			Return 1
		EndIf
	End Method

	Method getPlayerAudience:Int()
		Local PlayerID:Int = activeKI.playerId
		If Player[PlayerID] <> Null
			Return Player[PlayerID].audience
		Else
			Return 0
		EndIf
	End Method

	Method getPlayerCredit:Int()
		Local PlayerID:Int = activeKI.playerId
		If Player[PlayerID] <> Null
			Return Player[PlayerID].finances[TFinancials.GetDayArray(Game.day)].credit
		Else
			Return 0
		EndIf
	End Method

	Method getPlayerMoney:Int()
		Local PlayerID:Int = activeKI.playerId
		If Player[PlayerID] <> Null
			Return Player[PlayerID].finances[TFinancials.GetDayArray(game.day)].money
		Else
			Return 0
		EndIf
	End Method

	Method getPlayerRoom:Int()
		Local PlayerID:Int = activeKI.playerId
		If Player[PlayerID] <> Null
			Local room:TRooms = Player[PlayerID].figure.inRoom
			If room <> Null
		  		Return room.uniqueId
			Else
				Return 0
			EndIf
		Else
			Return 0
		EndIf
	End Method

	Method getPlayerTargetRoom:Int()
		Local PlayerID:Int = activeKI.playerId
		If Player[PlayerID] <> Null
			Local room:TRooms = Player[PlayerID].figure.toRoom
			If room <> Null
		  		Return room.uniqueId
			Else
				Return 0
			EndIf
		Else
			Return 0
		EndIf
	End Method

	Method getPlayerFloor:Int()
		Local PlayerID:Int = activeKI.playerId
		If Player[PlayerID] <> Null
			Return Player[PlayerID].figure.onFloor
		Else
			Return 0
		EndIf
	End Method

	Method getRoomFloor:Int(roomId:Int = 0)
		Local Room:TRooms = TRooms.GetRoomFromID(roomId)
		If Room <> Null
			Return Room.Pos.y
		Else
			Return 11
		EndIf
	End Method

	Method doGoToRoom:Int(roomId:Int = 0)
		Local PlayerID:Int = activeKI.playerId
		Local Room:TRooms = TRooms.GetRoomFromID(roomId)
		If Room <> Null Then Player[PlayerID].Figure.SendToRoom(Room)
	    Return 1
	End Method
	' ###########################################################

	Method Day:Int(_time:Int = 0)
		Return Game.GetActualDay(_time)
	End Method

	Method Hour:Int(_time:Int = 0)
		Return Game.GetActualHour(_time)
	End Method

	Method Minute:Int(_time:Int = 0)
		Return Game.GetActualHour(_time)
	End Method

	Method Weekday:Int(_time:Int = 0)
		Return ((Game.GetActualDay(_time) - 1) Mod 7)
	End Method
	' ###########################################################

	Method MovieSequels:Int(movieId:Int = -1)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(movieId)
	    If tmpObj <> Null
			Return tmpObj.episodecount
		Else
			Return - 1
		EndIf
	End Method

	Method MovieFromSerie:Int(serieId:Int = -1, episode:Int = 0)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(serieId)
		If tmpObj <> Null Then tmpObj = TProgramme.GetEpisode(tmpObj, episode)
	    If tmpObj <> Null
			Return tmpObj.pid
		Else
			Return - 1
		EndIf
	End Method

	Method MoviePrice:Int(movieId:Int = -1)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(movieId)
		If tmpObj <> Null
			Return tmpObj.ComputePrice()
		Else
			Return - 1
		EndIf
	End Method

	Method MovieGenre:Int(movieId:Int = -1)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(movieId)
		If tmpObj <> Null
			Return tmpObj.Genre
		Else
			Return - 1
		EndIf
	End Method

	Method MovieLength:Int(movieId:Int = -1)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(movieId)
		If tmpObj <> Null
			Return tmpObj.blocks
		Else
			Return - 1
		EndIf
	End Method

	Method MovieXRated:Int(movieId:Int = -1)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(movieId)
		If tmpObj <> Null
			If tmpObj.fsk18 <> ""
				Return False
			Else
				Return True
			EndIf
		Else
			Return - 1
		EndIf
	End Method

	Method MovieProfit:Int(movieId:Int = -1)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(movieId)
	    If tmpObj <> Null
			Return tmpObj.Outcome
		Else
			Return - 1
		EndIf
	End Method

	Method MovieSpeed:Int(movieId:Int = -1)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(movieId)
	    If tmpObj <> Null
			Return tmpObj.speed
		Else
			Return - 1
		EndIf
	End Method

	Method LUA_MovieReview:Int(movieId:Int = -1)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(movieId)
	    If tmpObj <> Null
			Return tmpObj.review
		Else
			Return - 1
		EndIf

	End Method

	Method MovieTopicality:Int(movieId:Int = -1)
		Local tmpObj:TProgramme = TProgramme.GetProgramme(movieId)
	    If tmpObj <> Null
			Return tmpObj.topicality
		Else
			Return - 1
		EndIf
	End Method
	' ###########################################################

	Method SpotAudience:Int(spotId:Int = -1)
		Local tmpObj:TContract = TContract.GetContract(spotId)
	    If tmpObj <> Null
			Return Int(tmpObj.CalculateMinAudience())
		Else
			Return - 1
		EndIf
	End Method

	Method SpotToSend:Int(spotId:Int = -1)
		Local tmpObj:TContract = TContract.GetContract(spotId)
	    If tmpObj <> Null
			Return Int(tmpObj.spotcount)
		Else
			Return - 1
		EndIf
	End Method

	Method SpotMaxDays:Int(spotId:Int = -1)
		Local tmpObj:TContract = TContract.GetContract(spotId)
	    If tmpObj <> Null Then
			Return Int(tmpObj.daystofinish)
		Else
			Return - 1
		EndIf
	End Method

	Method LUA_SpotProfit:Int(spotId:Int = -1)
		Local tmpObj:TContract = TContract.GetContract(spotId)
	    If tmpObj <> Null
			Return Int(tmpObj.CalculatePrice(tmpObj.profit))
		Else
			Return - 1
		EndIf
	End Method

	Method SpotPenalty:Int(spotId:Int = -1)
		Local tmpObj:TContract = TContract.GetContract(spotId)
	    If tmpObj <> Null Then
			Return Int(tmpObj.CalculatePrice(tmpObj.penalty))
		Else
			Return - 1
		EndIf
	End Method

	Method SpotTargetgroup:Int(spotId:Int = -1)
		Local tmpObj:TContract = TContract.GetContract(spotId)
	    If tmpObj <> Null
			Return Int(tmpObj.targetgroup)
		Else
			Return - 1
		EndIf
	End Method
	' ###########################################################

	Method of_getMovie:Int(day:Int = -1, hour:Int = -1)
		Local playerId:Int = activeKI.playerId

		If Player[playerId] <> Null
			If Player[playerId].Figure.inRoom.Name <> "office"
				Return - 1
			Else
				Local owner:Int = Player[PlayerID].Figure.inRoom.owner
				Local Programme:TProgramme = Player[owner].ProgrammePlan.GetActualProgramme(hour, day)
				If Programme <> Null
					Return Programme.pid
				Else
					Return 0
				EndIf
			EndIf
		Else
			Return - 1
		EndIf
	End Method

	Method of_getSpot:Int(day:Int = -1, hour:Int = -1)
		Local playerId:Int = activeKI.playerId

		If Player[playerId] <> Null
			If Player[PlayerID].Figure.inRoom.name <> "office"
				Return - 1
			Else
				Local owner:Int = Player[PlayerID].Figure.inRoom.owner
				Local obj:TAdBlock = Player[owner].ProgrammePlan.GetActualAdBlock(hour, day)
				If obj <> Null
					Return obj.contract.id
				Else
					Return 0
				EndIf
			EndIf
		Else
			Return - 1
		EndIf
	End Method

	Method of_getPlayerSpotCount:Int()
		Local playerId:Int = activeKI.playerId
		Local ret:Int = 0
		If Player[PlayerID] <> Null
			If Player[playerId].Figure.inRoom.Name <> "office"
				Return - 1
			Else
				Local owner:Int = Player[PlayerID].Figure.inRoom.owner
				Return Player[owner].ProgrammeCollection.ContractList.Count() - 1
			EndIf
		Else
			Return - 1
		EndIf
	End Method

	Method of_getPlayerSpot:Int(arraynumber:Int = -1)
		Local playerId:Int = activeKI.playerId
		Local ret:Int = 0
		If Player[PlayerID] <> Null
			If Player[playerId].Figure.inRoom.Name <> "office"
				Return - 1
			Else
				Local owner:Int = Player[PlayerID].Figure.inRoom.owner
				If arraynumber >= 0 & arraynumber <= Player[owner].ProgrammeCollection.ContractList.Count() - 1
					Local obj:TContract = TContract(Player[owner].ProgrammeCollection.ContractList.ValueAtIndex(arraynumber))
					If obj <> Null
						Return obj.id
					Else
						Return - 2
					EndIf
				EndIf
			EndIf
		Else
			Return - 1
		EndIf
	End Method

	Method of_getSpotWillBeSent:Int(day:Int = -1, hour:Int = -1)
		Local playerId:Int = activeKI.playerId

		Local ret:Int = -2
		If Player[PlayerID] <> Null
			If Player[playerId].Figure.inRoom.Name <> "office"
				Return - 1
			Else
				Local owner:Int = Player[PlayerID].Figure.inRoom.owner
				Local obj:TAdBlock = Player[owner].ProgrammePlan.GetActualAdBlock(hour, day)
				If obj <> Null
					Return obj.contract.spotnumber
				Else
					Return - 2
				EndIf
			EndIf
		Else
			Return - 1
		EndIf
	End Method

	Method of_getSpotBeenSent:Int(contractID:Int = -1)
		Local playerId:Int = activeKI.playerId

		If Player[PlayerID] <> Null
			If Player[playerId].Figure.inRoom.Name <> "office"
				Return - 1
			Else
				Local owner:Int = Player[PlayerID].Figure.inRoom.owner
				Local contractobj:TContract = Player[owner].ProgrammeCollection.GetContract(contractID)
				Local obj:TAdBlock = TAdBlock.GetBlockByContract(contractobj)
				If obj <> Null
					Return obj.GetSuccessfullSentContractCount()
				Else
					Return - 2
				EndIf
			EndIf
		Else
			Return - 1
		EndIf
	End Method

	Method of_getSpotDaysLeft:Int(contractID:Int = -1)
		Local playerId:Int = activeKI.playerId

		If Player[PlayerID] <> Null
			If Player[playerId].Figure.inRoom.Name <> "office"
				Return - 1
			Else
				Local owner:Int = Player[PlayerID].Figure.inRoom.owner
				Local contractobj:TContract = Player[owner].ProgrammeCollection.GetContract(contractID)
				If contractobj <> Null
					Return contractobj.getDaysToFinish()
				Else
					Return - 1
				EndIf
			EndIf
		Else
			Return - 1
		EndIf
	End Method

	Method of_doMovieInPlan:Int(day:Int = -1, hour:Int = -1, ObjectID:Int = -1)
		Local playerId:Int = activeKI.playerId

		If Player[playerId] <> Null
			If Player[PlayerID].Figure.inRoom <> Null
				If Player[PlayerID].Figure.inRoom.name = "office" Or Player[PlayerID].Figure.fromRoom.name = "office"
					Local owner:Int = Player[PlayerID].Figure.inRoom.owner
					'Schluessel da? - einfuegen!
					If playerId <> owner
						Return - 1
					Else
						If ObjectID = 0 'Film bei Day,hour löschen
							If day = Game.day And hour = Game.GetActualHour() And Game.GetActualMinute() > 5
								Return - 2
							Else
								Local Obj:TProgrammeBlock = TProgrammeBlock.GetActualProgrammeBlock(playerID, hour, day)
								If Obj <> Null
									Obj.DeleteBlock()
									Return 1
								Else
									Return - 3
								EndIf
							EndIf
						Else
							Local Obj:TProgramme = Player[playerID].ProgrammeCollection.GetProgramme(ObjectID)
							If Obj <> Null
								If Player[playerID].ProgrammePlan.ProgrammePlaceable(Obj, hour, day)
									Obj = Player[playerID].ProgrammePlan.CloneProgramme(Obj)
									Obj.senddate = day
									Obj.sendtime = hour
									Local objBlock:TProgrammeBlock = TProgrammeBlock.CreateDragged(obj, Null, playerId)
									objBlock.dragged = 0
									ObjBlock.SetBaseCoords(ObjBlock.GetBlockX(hour), ObjBlock.GetBlockY(hour))
									Return 1
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			Return - 1
		EndIf
	End Method



	Method doSpotInPlan:Int(day:Int = -1, hour:Int = -1, ObjectID:Int = -1)
		Local playerId:Int = activeKI.playerId

		If Player[playerId] <> Null
			If Player[playerId].Figure.inRoom <> Null
				If Player[PlayerID].Figure.inRoom.name = "office" Or Player[PlayerID].Figure.fromRoom.name = "office"
					Local owner:Int = Player[PlayerID].Figure.inRoom.owner
					'Schluessel da? - einfuegen!
					If playerId <> owner
						Return - 1
					Else
						If ObjectID = 0 'Film bei Day,hour löschen
							If day = Game.day And hour = Game.GetActualHour()
								Return - 2
							Else
								Local Obj:TAdBlock = TAdBlock.GetActualAdBlock(playerID, hour, day)
								If Obj <> Null
									Obj.RemoveBlock()
									Return 1
								Else
									Return - 3
								EndIf
							EndIf
						Else
							Local Obj:TContract = Player[playerID].ProgrammeCollection.GetContract(ObjectID)
							If Obj <> Null
								If Player[playerID].ProgrammePlan.ContractPlaceable(Obj, hour, day)
									Obj = Player[playerID].ProgrammePlan.CloneContract(Obj)
									Obj.senddate = day
									Obj.sendtime = hour
									Local objBlock:TAdBlock = TAdBlock.createDragged(obj, playerId)
									objBlock.dragged = 0
									ObjBlock.SetBaseCoords(ObjBlock.GetBlockX(hour), ObjBlock.GetBlockY(hour))
									Return 1
								EndIf
							Else
								Return - 3
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			Return - 1
		EndIf
	End Method

	Method getEvaluatedAudienceQuote:Int(hour:Int = -1, ObjectID:Int = -1)
		Local playerId:Int = activeKI.playerId

		If Player[PlayerID] <> Null
			Local Programme:TProgramme = TProgramme.GetProgramme(ObjectID)
			If Programme <> Null
	'			Local maxAudiencePercentage:Float = 0.0
	'			  If hour < 6 And hour > 1 Then maxAudiencePercentage = Float(RandRange(5, 15)) / 100
	'			  If hour >= 6 And hour < 18 Then maxAudiencePercentage = Float(RandRange(10, 10 + hour)) / 100
	'		  	  If hour >= 18 Or hour <= 1 Then maxAudiencePercentage = Float(RandRange(15, 20 + hour)) / 100
	'	        Local Quote:Int = Floor((Programme.ComputeAudienceQuote(Player[playerID].audience / Player[playerID].maxaudience) / 1000 / maxAudiencePercentage) * 1000 * 100)
				Local Quote:Int = Floor(Programme.ComputeAudienceQuote(0.5) * 100 / Game.maxAudiencePercentage)
				Print "quote:" + Quote
				Return Quote
			EndIf
		EndIf
		Return 0
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
	'
	'LUA_br_getPlayerStationcount
	'LUA_br_getPlayerStation
	'LUA_br_getStationIdX
	'LUA_br_getStationIdY

	'LUA_br_getStationAudience
	'LUA_br_getStationAudienceIncrease
	'LUA_br_getStationPrice
	'LUA_Kaufe Sender
	'LUA_Verkaufe Sender
	'
	'LUA_be_getSammyPoints
	'LUA_be_getBettyLove
	'LUA_be_getSammyGenre
	'
	'LUA_sa_doBuySpot
	'
	Method sa_getSpotCount:Int()
		Local playerId:Int = activeKI.playerId

		Local ret:Int = 0
		If Player[PlayerID] <> Null
			If Player[PlayerID].Figure.inRoom.name <> "adagency"
				Return - 1
			Else
				For Local Block:TContractBlocks = EachIn TContractBlocks.List
					If Block.owner <> PlayerID
						ret:+1
					End If
				Next
				Return ret
			EndIf
		EndIf
		Return - 1
	End Method

	Method sa_getSpot:Int(ArrayID:Int = -1)
		Local playerId:Int = activeKI.playerId

		Local ret:Int = 0
		If Player[PlayerID] <> Null
			If Player[playerId].Figure.inRoom.Name <> "adagency"
				Return - 1
			Else
				If ArrayID >= TContractBlocks.List.Count() Or ArrayID < 0
					Return - 2
				Else
					Local Block:TContractBlocks = TContractBlocks(TContractBlocks.List.ValueAtIndex(ArrayID))
					If Block <> Null
						Return Block.contract.id
					Else
						Return - 3
					EndIf
				End If
			EndIf
		EndIf
		Return - 1
	End Method

	'#############

	Method md_getMovieCount:Int()
		Local playerId:Int = activeKI.playerId

		Local ret:Int = 0
		If Player[PlayerID] <> Null
			If Player[PlayerID].Figure.inRoom.name <> "movieagency"
				Return - 1
			Else
				For Local Block:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
					If Block.owner <> PlayerID
						ret:+1
					End If
				Next
				Return ret
			EndIf
		EndIf
		Return - 1
	End Method

	Method md_getMovie:Int(ArrayID:Int = -1)
		Local playerId:Int = activeKI.playerId

		Local ret:Int = 0
		If Player[PlayerID] <> Null
			If Player[PlayerID].Figure.inRoom.name <> "movieagency"
				Return - 1
			Else
				If ArrayID >= TMovieAgencyBlocks.List.Count() Or arrayID < 0
					Return - 2
				Else
					Local Block:TMovieAgencyBlocks = TMovieAgencyBlocks(TMovieAgencyBlocks.List.ValueAtIndex(ArrayID))
					If Block <> Null
						Return Block.Programme.pid
					Else
						Return - 3
					End If
				End If
			EndIf
		EndIf
		Return - 1
	End Method

	Method md_doBuyMovie:Int(ObjektID:Int = -1)
		Local playerId:Int = activeKI.playerId

		Local ret:Int = 0
		If Player[playerId] <> Null
			If Player[PlayerID].Figure.inRoom.name <> "movieagency"
				Return - 1
			Else
				For Local Block:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
					If Block.Programme.pid = ObjektID
						ret = Block.Buy(PlayerID)
						If ret = 1 Then Block.Pos.y = 241
						Return 1
						Exit
					End If
				Next
				Return - 2
			EndIf
		EndIf
		Return - 1
	End Method

	'LUA_md_doSellMovie
	'
	'LUA_ma_getMoviecount
	'LUA_ma_getMovie
	'LUA_ma_doBidMovie
	'
	'LUA_ar_getMovieInBagCount
	'LUA_ar_getMovieInBag
	'LUA_ar_doMovieInBag
	'LUA_ar_doMovieOutBag
	'
	'LUA_bo_doPayCredit
End Type

Type KI_EventManager
	Global registeredKIs:TList = New TList

	Function getKIByPlayerId:KI(playerId:Byte)
		Local i:Byte
		For Local ki:KI = EachIn registeredKIs
			'Print "ups"
			If ki.playerId = playerId Then
				PrintDebug("KI_EventManager.getKIByPlayerId()", "Spieler mit " + KI.playerId + " gefunden", DEBUG_LUA)
				Return KI
			End If
		Next

		PrintDebug("KI_EventManager.getKIByPlayerId()", "FEHLER: Spieler mit PlayerID " + playerId + " nicht gefunden", DEBUG_LUA)
		Return Null
	End Function

	Function registerKI(ki:KI)
		PrintDebug("KI_EventManager.registerKI()", "Neue KI registriert fuer PlayerID " + KI.playerId, DEBUG_LUA)
		registeredKIs.AddLast(KI)
	End Function

	Function unregisterKI(ki:KI)
		PrintDebug("KI_EventManager.unregisterKI()", "KI Registrierung entfernt fuer PlayerID " + KI.playerId, DEBUG_LUA)
	    registeredKIs.Remove(ki)
	End Function

	Function onMinute(playerId:Byte)
		Local ki:KI = getKIByPlayerId(playerId)
		If ki = Null Then
			Return
		EndIf
		ki.CallOnMinute()
	End Function

	Function onReachRoom(playerId:Byte, roomId:Byte)
	    Local ki:KI = getKIByPlayerId(playerId)
		If ki = Null Then
			Return
		End If
		'ki.CallOnReachRoom(roomId)
	End Function

	Function onLeaveRoom(playerId:Byte, roomId:Byte)
		Local ki:KI = getKIByPlayerId(playerId)
		If ki = Null Then
			Return
		End If
		'ki.CallOnLeaveRoom()
	End Function

	Function onDayBegins(playerId:Byte)
		Local ki:KI = getKIByPlayerId(playerId)
		If ki = Null Then
			Return
		End If
		'ki.CallOnDayBegins()
	End Function

	Method onMoneyChanged(playerId:Byte)
		Local ki:KI = getKIByPlayerId(playerId)
		If ki = Null Then
			Return
		End If
		'ki.CallOnMoneyChanged()
	End Method
End Type

