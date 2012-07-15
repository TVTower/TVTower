'**************************************************************************************************
' This program was written with BLIde
' Application:
' Author:
' License:
'**************************************************************************************************

'SuperStrict
Type KI
	Field playerId:Byte
	Field LuaEngine:TLuaEngine
	Field scriptName:String
	Field scriptAsString:String = ""
	Field scriptConstants:String
	Field MyLuaState:Byte Ptr
	Field LastErrorNumber:Int = 0

	Field LuaFunctions:TLuaFunctions


	Function Create:KI(pId:Byte, script:String)
		Local loadtime:Int = MilliSecs()
		Local ret:KI = New KI
		ret.playerId		= pId
		ret.LuaFunctions	= TLuaFunctions.Create(pId)		'own functions for player
		ret.LuaEngine		= TLuaEngine.Create("")			'register engine and functions
		ret.scriptName		= script
		ret.reloadScript()
		Print "Player " + pId + " (ME:"+ret.LuaFunctions.ME+"): AI loaded in " + Float(MilliSecs() - loadtime) + "ms"
		Return ret
	End Function

	Method OnCreate()
		Local args:Object[1]
		args[0] = String(Self.playerID)
		Self.LuaEngine.CallLuaFunction("OnCreate", args)
	End Method

	Method Stop()
'		scriptEnv.ShutDown()
'		KI_EventManager.unregisterKI(Self)
	End Method

	Method reloadScript()
		If Self.scriptAsString <> "" Then Print "Reloaded LUA AI for player "+Self.playerId
		Self.scriptAsString = LoadText(scriptName)

		Print "LUA: Registering <LuaFunctions> as <TVT>"
		LuaEngine.RegisterBlitzmaxObject(LuaFunctions, "TVT")

		If TPlayer.getById(Self.PlayerID) <> Null
			Print "LUA: Registering <Player> as <MY>"
			LuaEngine.RegisterBlitzmaxObject(TPlayer.getById(Self.PlayerID), "MY")
		Else
			Print "LUA: ERROR Registering <Player> as <MY> - player not found"
		EndIf
		Self.LuaEngine.setSource(scriptAsString)
	End Method

	Method CallOnLoad(savedluascript:String="")
		Local args:Object[1]
		args[0] = savedluascript
		Self.LuaEngine.CallLuaFunction("OnLoad", args)
	'	Self.PrintErrors()
	End Method

	Method CallOnSave()
		Local args:Object[1]
		args[0] = "5.0"
		Self.LuaEngine.CallLuaFunction("OnSave", args)
	'	Self.PrintErrors()
	End Method

	Method CallOnMinute(minute:Int=0)
		Local args:Object[1]
		args[0] = String(minute)
		Self.LuaEngine.CallLuaFunction("OnMinute", args)
	End Method

	Method CallOnChat(text:String = "")
	    Try
			Local args:Object[1]
			args[0] = text
			Self.LuaEngine.CallLuaFunction("OnChat", args)
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion onChat nicht"
		End Try
	End Method

	Method CallOnReachRoom(roomId:Int)
	    Try
			Local args:Object[1]
			args[0] = String(roomId)
			Self.LuaEngine.CallLuaFunction("OnReachRoom", args)
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion OnReachRoom nicht"
		End Try
	End Method

	Method CallOnLeaveRoom()
	    Try
			Self.LuaEngine.CallLuaFunction("OnLeaveRoom", Null)
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion OnLeaveRoom nicht"
		End Try
	End Method

	Method CallOnDayBegins()
	    Try
			Self.LuaEngine.CallLuaFunction("OnDayBegins", Null)
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion OnDayBegins nicht"
		End Try
	End Method

	Method CallOnMoneyChanged()
	    Try
			Self.LuaEngine.CallLuaFunction("OnMoneyChanged", Null)
		Catch ex:Object
		    Print "Script " + scriptName + " enthaelt die Funktion OnMoneyChanged nicht"
		End Try
	End Method
End Type

Type TLuaFunctions {_exposeToLua}
	Field PLAYER1:Int = 1
	Field PLAYER2:Int = 2
	Field PLAYER3:Int = 3
	Field PLAYER4:Int = 4
	Field ME:Int 'Wird initialisiert

	Field MAXMOVIES:Int = 50
	Field MAXMOVIESPARGENRE:Int = 8
	Field MAXSPOTS:Int 'Wird initialisiert

	Const MOVIE_GENRE_ACTION:Int = 0
	Const MOVIE_GENRE_THRILLER:Int = 1
	Const MOVIE_GENRE_SCIFI:Int = 2
	Const MOVIE_GENRE_COMEDY:Int = 3
	Const MOVIE_GENRE_HORROR:Int = 4
	Const MOVIE_GENRE_LOVE:Int = 5
	Const MOVIE_GENRE_EROTIC:Int = 6
	Const MOVIE_GENRE_WESTERN:Int = 7
	Const MOVIE_GENRE_LIVE:Int = 8
	Const MOVIE_GENRE_KIDS:Int = 9
	Const MOVIE_GENRE_CARTOON:Int = 10
	Const MOVIE_GENRE_MUSIC:Int = 11
	Const MOVIE_GENRE_SPORT:Int = 12
	Const MOVIE_GENRE_CULTURE:Int = 13
	Const MOVIE_GENRE_FANTASY:Int = 14
	Const MOVIE_GENRE_YELLOWPRESS:Int = 15
	Const MOVIE_GENRE_NEWS:Int = 16
	Const MOVIE_GENRE_SHOW:Int = 17
	Const MOVIE_GENRE_MONUMENTAL:Int = 18

	Const NEWS_GENRE_TECHNICS:Int = 3
	Const NEWS_GENRE_POLITICS:Int = 0
	Const NEWS_GENRE_SHOWBIZ:Int = 1
	Const NEWS_GENRE_SPORT:Int = 2
	Const NEWS_GENRE_CURRENTS:Int = 4

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
	Field ROOM_STUDIOSIZE1_PLAYER_ME:Int
	Field ROOM_BOSS_PLAYER_ME:Int
	Field ROOM_NEWSAGENCY_PLAYER_ME:Int
	Field ROOM_ARCHIVE_PLAYER_ME:Int

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
	Field ROOM_STUDIOSIZE_PLAYER4:Int


	Method getPlayerID:Int()
		print "VERALTET: TVT.getPlayerID -> MY.GetPlayerID()"

		Return Self.ME
	End Method

	Method _PlayerInRoom:Int(roomname:String, checkFromRoom:Int = False)
		If checkFromRoom
			'from room has to be set AND inroom <> null (no building!)
			Return (Players[ Self.ME ].Figure.inRoom And Players[ Self.ME ].Figure.inRoom.Name = roomname) Or (Players[ Self.ME ].Figure.inRoom And Players[ Self.ME ].Figure.fromRoom And Players[ Self.ME ].Figure.fromRoom.Name = roomname)
		Else
			Return (Players[ Self.ME ].Figure.inRoom And Players[ Self.ME ].Figure.inRoom.Name = roomname)
		EndIf
	End Method

	Function Create:TLuaFunctions(pPlayerId:Int)
		Local ret:TLuaFunctions = New TLuaFunctions

		ret.ME = pPlayerId

		ret.MAXSPOTS = Game.maxContractsAllowed

		ret.ROOM_MOVIEAGENCY = TRooms.GetRoom("movieagency", 0).uniqueID
		ret.ROOM_ADAGENCY = TRooms.GetRoom("adagency", 0).uniqueID
		ret.ROOM_ROOMBOARD = TRooms.GetRoom("roomboard", - 1).uniqueID
		ret.ROOM_PORTER = TRooms.GetRoom("porter", - 1).uniqueID
		ret.ROOM_BETTY = TRooms.GetRoom("betty", 0).uniqueID
		ret.ROOM_SUPERMARKET = TRooms.GetRoom("supermarket", 0).uniqueID
		ret.ROOM_ROOMAGENCY = TRooms.GetRoom("roomagency", 0).uniqueID
		ret.ROOM_PEACEBROTHERS = TRooms.GetRoom("peacebrothers", - 1).uniqueID
		ret.ROOM_SCRIPTAGENCY = TRooms.GetRoom("scriptagency", 0).uniqueID
		ret.ROOM_NOTOBACCO = TRooms.GetRoom("notobacco", - 1).uniqueID
		ret.ROOM_TOBACCOLOBBY = TRooms.GetRoom("tobaccolobby", - 1).uniqueID
		ret.ROOM_GUNSAGENCY = TRooms.GetRoom("gunsagency", - 1).uniqueID
		ret.ROOM_VRDUBAN = TRooms.GetRoom("vrduban", - 1).uniqueID
		ret.ROOM_FRDUBAN = TRooms.GetRoom("frduban", - 1).uniqueID

		ret.ROOM_OFFICE_PLAYER_ME = TRooms.GetRoom("office", pPlayerId).uniqueID
		ret.ROOM_STUDIOSIZE1_PLAYER_ME = TRooms.GetRoom("studiosize1", pPlayerId).uniqueID
		ret.ROOM_BOSS_PLAYER_ME = TRooms.GetRoom("chief", pPlayerId).uniqueID
		ret.ROOM_NEWSAGENCY_PLAYER_ME = TRooms.GetRoom("news", pPlayerId).uniqueID
		ret.ROOM_ARCHIVE_PLAYER_ME = TRooms.GetRoom("archive", pPlayerId).uniqueID

		ret.ROOM_ARCHIVE_PLAYER1 = TRooms.GetRoom("archive", 1).uniqueID
		ret.ROOM_NEWSAGENCY_PLAYER1 = TRooms.GetRoom("news", 1).uniqueID
		ret.ROOM_BOSS_PLAYER1 = TRooms.GetRoom("chief", 1).uniqueID
		ret.ROOM_OFFICE_PLAYER1 = TRooms.GetRoom("office", 1).uniqueID
		ret.ROOM_STUDIOSIZE_PLAYER1 = TRooms.GetRoom("studiosize1", 1).uniqueID

		ret.ROOM_ARCHIVE_PLAYER2 = TRooms.GetRoom("archive", 2).uniqueID
		ret.ROOM_NEWSAGENCY_PLAYER2 = TRooms.GetRoom("news", 2).uniqueID
		ret.ROOM_BOSS_PLAYER2 = TRooms.GetRoom("chief", 2).uniqueID
		ret.ROOM_OFFICE_PLAYER2 = TRooms.GetRoom("office", 2).uniqueID
		ret.ROOM_STUDIOSIZE_PLAYER2 = TRooms.GetRoom("studiosize1", 2).uniqueID

		ret.ROOM_ARCHIVE_PLAYER3 = TRooms.GetRoom("archive", 3).uniqueID
		ret.ROOM_NEWSAGENCY_PLAYER3 = TRooms.GetRoom("news", 3).uniqueID
		ret.ROOM_BOSS_PLAYER3 = TRooms.GetRoom("chief", 3).uniqueID
		ret.ROOM_OFFICE_PLAYER3 = TRooms.GetRoom("office", 3).uniqueID
		ret.ROOM_STUDIOSIZE_PLAYER3 = TRooms.GetRoom("studiosize1", 3).uniqueID

		ret.ROOM_ARCHIVE_PLAYER4 = TRooms.GetRoom("archive", 4).uniqueID
		ret.ROOM_NEWSAGENCY_PLAYER4 = TRooms.GetRoom("news", 4).uniqueID
		ret.ROOM_BOSS_PLAYER4 = TRooms.GetRoom("chief", 4).uniqueID
		ret.ROOM_OFFICE_PLAYER4 = TRooms.GetRoom("office", 4).uniqueID
		ret.ROOM_STUDIOSIZE_PLAYER4 = TRooms.GetRoom("studiosize1", 4).uniqueID

		Return ret
	End Function

	Method PrintOut:Int(text:String)
		Print text
		Return 1
	EndMethod

	Method GetProgramme:TProgramme( programmeID:int ) {_exposeToLua}
		return TProgramme.getProgramme( programmeID )
	End Method


	Method GetRoom:Int(roomName:String, playerID:Int)
		Local room:TRooms = TRooms.GetRoom(roomName, playerID, 0) '0 = not strict
		If room <> Null Then Return room.uniqueID Else Return -1
	End Method

	Method SendToChat:Int(ChatText:String)
		If Players[ Self.ME ] <> Null
			InGame_Chat.AddEntry("", ChatText, Self.ME, "", "", MilliSecs())
			If Game.IsGameLeader()
				If ChatText.Length > 4 And Left(ChatText, 1) = "/"
					Local KIPlayerID:Int = Int(Mid(chattext, 2,1))
					If Game.IsPlayerID( KIPlayerID ) And Players[ KIplayerID ].Figure.IsAI()
						Local chatvalue:String = Right(chattext, chattext.Length - 3)
						Print chatvalue
						Players[ KIplayerID ].PlayerKI.CallOnChat(chatvalue)
					EndIf
				EndIf
			EndIf
		EndIf
		Return 1
	EndMethod


	Method GetPlayerPosX:Int(PlayerID:Int = Null)
		'oder beibehalten - dann kann die AI schauen ob eine Figur in der Naehe ist
		'bspweise fuer Chat - "hey xy"
		print "VERALTET: GetPlayerPosX -> math.floor( MY.Figure.Pos.GetX() ) ... floor fuer float->int"
		If Not Game.isPlayerID( PlayerID ) Then Return -1 Else Return Floor(Players[ PlayerID ].figure.pos.x)
	End Method

	Method GetPlayerTargetPosX:Int(PlayerID:Int = Null)
		print "VERALTET: GetPlayerTargetPosX -> math.floor( MY.Figure.Target.GetIntX() ) ... bzw GetX() fuer float"
		If Not Game.isPlayerID( PlayerID ) Then Return -1 Else Return Floor(Players[ PlayerID ].figure.target.x)
	End Method

	Method SetPlayerTargetPosX:Int(PlayerID:Int = Null, newTargetX:Int = 0)
		print "VERALTET: SetPlayerTargetPosX -> MY.Figure.changeTarget(x, y=null)"
		If Not Game.isPlayerID( PlayerID ) OR Not Players[PlayerID].isAi() Then Return -1 Else Return Players[PlayerID].figure.changeTarget(newTargetX,Null)
	End Method


	Method getMillisecs:Int()
		Return MilliSecs()
	End Method

	Method getTime:Int()
		Return Game.timeSinceBegin
	End Method

	Method getPlayerMaxAudience:Int()
		Print "VERALTET: TVT.getPlayerMaxAudience() -> MY.GetMaxAudience()"
		Return Players[ Self.ME ].maxaudience
	End Method

	Method getPlayerAudience:Int()
		Print "VERALTET: TVT.getPlayerAudience() -> MY.GetAudience()"
		Return Players[ Self.ME ].audience
	End Method

	Method getPlayerCredit:Int()
		Print "VERALTET: TVT.getPlayerCredit() -> MY.GetCredit()"
		Return Players[ Self.ME ].finances[Game.getWeekday()].credit
	End Method

	Method getPlayerMoney:Int()
		Print "VERALTET: TVT.getPlayerMoney() -> MY.GetMoney()"
		Return Players[ Self.ME ].finances[Game.getWeekday()].money
	End Method

	Method getPlayerRoom:Int()
		Local room:TRooms = Players[ Self.ME ].figure.inRoom
		If room <> Null Then Return room.uniqueId Else Return 0
	End Method

	Method getPlayerTargetRoom:Int()
		Local room:TRooms = Players[ Self.ME ].figure.toRoom
		If room <> Null Then Return room.uniqueId Else Return 0
	End Method

	Method getPlayerFloor:Int()
		Print "VERALTET: TVT.getPlayerFloor() -> MY.Figure.GetFloor()"
		Return Players[ Self.ME ].figure.GetFloor()
	End Method

	Method getRoomFloor:Int(roomId:Int = 0)
		Local Room:TRooms = TRooms.GetRoomFromID(roomId)
		If Room <> Null Then Return Room.Pos.y Else Return 0
	End Method

	Method doGoToRoom:Int(roomId:Int = 0)
		Local Room:TRooms = TRooms.GetRoomFromID(roomId)
		If Room <> Null Then Players[ Self.ME ].Figure.SendToRoom(Room)
	    Return 1
	End Method



	Method Day:Int(_time:Int = 0)
		Return Game.GetDay(_time)
	End Method

	Method Hour:Int(_time:Int = 0)
		Return Game.GetHour(_time)
	End Method

	Method Minute:Int(_time:Int = 0)
		Return Game.GetMinute(_time)
	End Method

	Method Weekday:Int(_time:Int = 0)
		Return Game.GetWeekday(_time)
	End Method


'- - - - - -
' MOVIES
'- - - - - -
	Method MovieSequels:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieSequels -> Programmeobject.GetEpisodeCount()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
	    If obj Then Return obj.episodeList.count() Else Return -1
	End Method

	Method MovieFromSerie:Int(serieId:Int = -1, episodeNumber:Int = 0)
		Print "VERALTET: TVT.MovieFromSerie -> Programmeobject.GetEpisode(episode)"
		Local obj:TProgramme = TProgramme.GetProgramme(serieId)
		If obj Then obj = obj.GetEpisode(episodeNumber)
	End Method

	Method MoviePrice:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MoviePrice -> Programmeobject.GetPrice()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
		If obj Then Return obj.getPrice() Else Return -1
	End Method

	Method MovieGenre:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieGenre -> Programmeobject.GetGenre() (bzw. GetGenreString() fuer Textwert)"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
		If obj Then Return obj.Genre Else Return -1
	End Method

	Method MovieLength:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieLength -> Programmeobject.GetBlocks()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
		If obj Then Return obj.blocks Else Return -1
	End Method

	Method MovieXRated:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieXRated -> Programmeobject.GetXRated()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
		If obj Then Return (obj.fsk18 <> "") Else Return -1
	End Method

	Method MovieProfit:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieProfit -> Programmeobject.GetOutcome()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
	    If obj Then Return obj.Outcome Else Return -1
	End Method

	Method MovieSpeed:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieSpeed -> Programmeobject.GetSpeed()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
	    If obj Then Return obj.speed Else Return -1
	End Method

	Method MovieReview:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieReview -> Programmeobject.GetReview()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
	    If obj Then Return obj.review Else Return -1
	End Method

	Method MovieTopicality:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieTopicality -> Programmeobject.GetTopicality()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
	    If obj Then Return obj.topicality Else Return -1
	End Method

	'Ich hab mir diese Hilfmethode gebaut, damit ich die Qualitätsberechnung nicht in der KI nachbauen muss.
	'Es wäre zu kompliziert wenn die KI ihre Qualitätsprognose auf Grund einer riesigen Erfahrungsdatenbank durchführen müsste.
	Method getActualProgrammQuality:Int(objectID:Int = -1, lastQuotePercentage:Float = 0.1)
		Print "VERALTET: TVT.getActualProgrammQuality -> Programmeobject.getBaseAudienceQuote(lastQuotePercentage:float=0.1)"
		Local Programme:TProgramme = TProgramme.GetProgramme(objectID)
		If Programme <> Null
			Local Quote:Int = Floor(Programme.getBaseAudienceQuote(lastQuotePercentage) * 100)
			Return Quote
		EndIf
	End Method


'- - - - - -
' SPOTS
'- - - - - -
	Method SpotAudience:Int(spotId:Int = -1)
		Local obj:TContract = TContract.GetContract(spotId)
	    If obj Then Return Int(obj.getMinAudience(obj.owner)) Else Return -1
	End Method

	Method SpotToSend:Int(spotId:Int = -1)
		Local obj:TContract = TContract.GetContract(spotId)
	    If obj Then Return Int(obj.spotcount) Else Return -1
	End Method

	Method SpotMaxDays:Int(spotId:Int = -1)
		Local obj:TContract = TContract.GetContract(spotId)
	    If obj Then Return Int(obj.daystofinish) Else Return -1
	End Method

	Method SpotProfit:Int(spotId:Int = -1)
		Local obj:TContract = TContract.GetContract(spotId)
	    If obj Then Return Int(obj.CalculateProfit(obj.profit, obj.owner)) Else Return -1
	End Method

	Method SpotPenalty:Int(spotId:Int = -1)
		Local obj:TContract = TContract.GetContract(spotId)
	    If obj Then Return Int(obj.CalculatePenalty(obj.penalty, obj.owner)) Else Return -1
	End Method

	Method SpotTargetgroup:Int(spotId:Int = -1)
		Local obj:TContract = TContract.GetContract(spotId)
	    If obj Then Return Int(obj.targetgroup) Else Return -1
	End Method


'- - - - - -
' Office
'- - - - - -
	Method of_getMovie:Int(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return -1

		Local obj:TProgramme	= Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammePlan.GetActualProgramme(hour, day)
		If obj Then Return obj.id Else Return 0
	End Method

	Method of_getSpot:Int(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return -1

		Local obj:TAdBlock = Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammePlan.GetActualAdBlock(hour, day)
		If obj Then Return obj.contract.id Else Return 0
	End Method

	Method of_getPlayerSpotCount:Int()
		If Not _PlayerInRoom("office", True) Then Return -1

		Return Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammeCollection.ContractList.Count() - 1
	End Method

	Method of_getPlayerSpot:Int(arraynumber:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return -1

		Local owner:Int = Players[ Self.ME ].Figure.inRoom.owner
		If arraynumber >= 0 And arraynumber <= Players[ owner ].ProgrammeCollection.ContractList.Count() - 1
			Local obj:TContract = TContract(Players[ owner ].ProgrammeCollection.ContractList.ValueAtIndex(arraynumber))
			If obj Then Return obj.id Else Return -2
		EndIf
	End Method

	Method of_getSpotWillBeSent:Int(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return -1

		Local obj:TAdBlock = Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammePlan.GetActualAdBlock(hour, day)
		If obj Then Return obj.contract.spotnumber Else Return -2
	End Method

	Method of_getSpotBeenSent:Int(contractID:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return -1

		Local contractObj:TContract = Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammeCollection.GetContract(contractID)
		If Not contractObj Then Return -2

		Local obj:TAdBlock = TAdBlock.GetBlockByContract( contractObj )
		If obj Then Return obj.GetSuccessfulSentContractCount() Else Return -2
	End Method

	Method of_getSpotDaysLeft:Int(contractID:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return -1

		Local contractObj:TContract = Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammeCollection.GetContract(contractID)
		If contractObj Then Return contractobj.getDaysToFinish() Else Return - 1
	End Method

	Method of_doMovieInPlan:Int(day:Int = -1, hour:Int = -1, ObjectID:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return -1

		Local owner:Int = Players[ Self.ME ].Figure.inRoom.owner

		'wenn user schluessel haben sollte, dann muesste an dieser Stelle dies ueberprueft werden
		If Self.ME <> owner Then Return - 1

		If ObjectID = 0 'Film bei Day,hour löschen
			If day = Game.day And hour = Game.GetHour() And Game.GetMinute() > 5 Then Return -2

			Local Obj:TProgrammeBlock = Players[ owner ].ProgrammePlan.GetActualProgrammeBlock(hour, day)
			If Obj
				Obj.DeleteBlock()
				Return 1
			Else
				Return -3
			EndIf
		Else
			Local Obj:TProgramme = Players[ owner ].ProgrammeCollection.GetProgramme(ObjectID)
			If Obj And Players[ owner ].ProgrammePlan.ProgrammePlaceable(Obj, hour, day)
				Local objBlock:TProgrammeBlock	= TProgrammeBlock.CreateDragged(obj, owner)
				objBlock.sendHour				= day*24 + hour
				objBlock.dragged				= 0
				ObjBlock.SetBasePos(ObjBlock.GetSlotXY(hour))
				Return 1
			Else
				Return -3
			EndIf
		EndIf
	End Method


	Method of_doSpotInPlan:Int(day:Int = -1, hour:Int = -1, ObjectID:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return -1

		Local owner:Int = Players[ Self.ME ].Figure.inRoom.owner

		'wenn user schluessel haben sollte, dann muesste an dieser Stelle dies ueberprueft werden
		If Self.ME <> owner Then Return - 1

		If ObjectID = 0 'Film bei Day,hour löschen
			If day = Game.day And hour = Game.GetHour() Then Return -2

			Local Obj:TAdBlock = TAdBlock.GetActualAdBlock(owner, hour, day)
			If Obj
				Obj.RemoveBlock()
				Return 1
			Else
				Return -3
			EndIf
		Else
			Local Obj:TContract = Players[ owner ].ProgrammeCollection.GetContract(ObjectID)
			If Obj And Players[ owner ].ProgrammePlan.ContractPlaceable(Obj, hour, day)
				Obj						= Players[ owner ].ProgrammePlan.CloneContract(Obj)
				Obj.senddate			= day
				Obj.sendtime			= hour
				Local objBlock:TAdBlock = TAdBlock.createDragged(obj, owner)
				objBlock.dragged		= 0
				ObjBlock.SetBaseCoords(ObjBlock.GetBlockX(hour), ObjBlock.GetBlockY(hour))
				Return 1
			Else
				Return -3
			EndIf
		EndIf
	End Method


	Method getEvaluatedAudienceQuote:Int(hour:Int = -1, ObjectID:Int = -1, lastQuotePercentage:Float = 0.1, audiencePercentageBasedOnHour:Float=-1)
		'TODO: Statt dem audiencePercentageBasedOnHour-Parameter könnte auch das noch unbenutzte "hour" den generellen Quotenwert in der
		'angegebenen Stunde mit einem etwas umgebauten "calculateMaxAudiencePercentage" (ohne Zufallswerte und ohne die globale Variable zu verändern) errechnen.
		Local Programme:TProgramme = TProgramme.GetProgramme(ObjectID)
		If Programme <> Null
			Local Quote:Int = Floor(Programme.getAudienceQuote(lastQuotePercentage, audiencePercentageBasedOnHour) * 100)
			Print "quote:" + Quote + "%"
			Return Quote
		EndIf
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

'- - - - - -
' Spot Agency
'- - - - - -
'untested
	Method sa_doBuySpot:Int(ObjektID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return -1

		Local ret:Int = 0
		For Local Block:TContractBlock = EachIn TContractBlock.list
			If Block.contract.id = ObjektID And Block.owner <= 0 Then Return Block.SignContract( Self.ME )
		Next
		Return -2
	End Method

	Method sa_getSpotCount:Int()
		If Not _PlayerInRoom("adagency") Then Return -1

		Local ret:Int = 0
		For Local Block:TContractBlock = EachIn TContractBlock.List
			If Block.owner <= 0 Then ret:+1
		Next
		Return ret
	End Method

	Method sa_getSpot:Int(ArrayID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return -1

		If ArrayID >= TContractBlock.List.Count() Or ArrayID < 0 Then Return -2

		Local Block:TContractBlock = TContractBlock(TContractBlock.List.ValueAtIndex(ArrayID))
		If Block Then Return Block.contract.id Else Return -3
	End Method

'- - - - - -
' Movie Dealer - Movie Agency
'- - - - - -
	Method md_getMovieCount:Int()
		If Not _PlayerInRoom("movieagency") Then Return -1

		Local ret:Int = 0
		For Local Block:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If Block.owner <> Self.ME Then ret:+1
		Next
		Return ret
	End Method

	Method md_getMovie:Int(ArrayID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return -1

		If ArrayID >= TMovieAgencyBlocks.List.Count() Or arrayID < 0 Then Return -2
		Local Block:TMovieAgencyBlocks = TMovieAgencyBlocks(TMovieAgencyBlocks.List.ValueAtIndex(ArrayID))
		If Block Then Return Block.Programme.id Else Return -3
	End Method

	Method md_doBuyMovie:Int(ObjektID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return -1

		For Local Block:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If Block.Programme.id = ObjektID Then Return Block.Buy( Self.ME )
		Next
		Return -2
	End Method

	Method PrivateTest() {_private}
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