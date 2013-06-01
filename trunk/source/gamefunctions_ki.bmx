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

		'Print "LUA: Registering <LuaFunctions> as <TVT> AND <Player> as <MY>"
		LuaEngine.RegisterBlitzmaxObject(LuaFunctions, "TVT")

		If TPlayer.getById(Self.PlayerID) <> Null
			'Print "LUA: Registering <Player> as <MY>"
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
	Const RESULT_OK:int				=   1
	Const RESULT_WRONGROOM:int		=  -2
	Const RESULT_NOKEY:int			=  -4
	Const RESULT_NOTFOUND:int		=  -8
	Const RESULT_NOTALLOWED:int		= -16
	Const RESULT_INUSE:int			= -32

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

	Field NEWS_GENRE_TECHNICS:Int = 3
	Field NEWS_GENRE_POLITICS:Int = 0
	Field NEWS_GENRE_SHOWBIZ:Int = 1
	Field NEWS_GENRE_SPORT:Int = 2
	Field NEWS_GENRE_CURRENTS:Int = 4

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

		ret.ROOM_MOVIEAGENCY = TRooms.GetRoomByDetails("movieagency", 0).id
		ret.ROOM_ADAGENCY = TRooms.GetRoomByDetails("adagency", 0).id
		ret.ROOM_ROOMBOARD = TRooms.GetRoomByDetails("roomboard", - 1).id
		ret.ROOM_PORTER = TRooms.GetRoomByDetails("porter", - 1).id
		ret.ROOM_BETTY = TRooms.GetRoomByDetails("betty", 0).id
		ret.ROOM_SUPERMARKET = TRooms.GetRoomByDetails("supermarket", 0).id
		ret.ROOM_ROOMAGENCY = TRooms.GetRoomByDetails("roomagency", 0).id
		ret.ROOM_PEACEBROTHERS = TRooms.GetRoomByDetails("peacebrothers", - 1).id
		ret.ROOM_SCRIPTAGENCY = TRooms.GetRoomByDetails("scriptagency", 0).id
		ret.ROOM_NOTOBACCO = TRooms.GetRoomByDetails("notobacco", - 1).id
		ret.ROOM_TOBACCOLOBBY = TRooms.GetRoomByDetails("tobaccolobby", - 1).id
		ret.ROOM_GUNSAGENCY = TRooms.GetRoomByDetails("gunsagency", - 1).id
		ret.ROOM_VRDUBAN = TRooms.GetRoomByDetails("vrduban", - 1).id
		ret.ROOM_FRDUBAN = TRooms.GetRoomByDetails("frduban", - 1).id

		ret.ROOM_OFFICE_PLAYER_ME = TRooms.GetRoomByDetails("office", pPlayerId).id
		ret.ROOM_STUDIOSIZE1_PLAYER_ME = TRooms.GetRoomByDetails("studiosize1", pPlayerId).id
		ret.ROOM_BOSS_PLAYER_ME = TRooms.GetRoomByDetails("chief", pPlayerId).id
		ret.ROOM_NEWSAGENCY_PLAYER_ME = TRooms.GetRoomByDetails("news", pPlayerId).id
		ret.ROOM_ARCHIVE_PLAYER_ME = TRooms.GetRoomByDetails("archive", pPlayerId).id

		ret.ROOM_ARCHIVE_PLAYER1 = TRooms.GetRoomByDetails("archive", 1).id
		ret.ROOM_NEWSAGENCY_PLAYER1 = TRooms.GetRoomByDetails("news", 1).id
		ret.ROOM_BOSS_PLAYER1 = TRooms.GetRoomByDetails("chief", 1).id
		ret.ROOM_OFFICE_PLAYER1 = TRooms.GetRoomByDetails("office", 1).id
		ret.ROOM_STUDIOSIZE_PLAYER1 = TRooms.GetRoomByDetails("studiosize1", 1).id

		ret.ROOM_ARCHIVE_PLAYER2 = TRooms.GetRoomByDetails("archive", 2).id
		ret.ROOM_NEWSAGENCY_PLAYER2 = TRooms.GetRoomByDetails("news", 2).id
		ret.ROOM_BOSS_PLAYER2 = TRooms.GetRoomByDetails("chief", 2).id
		ret.ROOM_OFFICE_PLAYER2 = TRooms.GetRoomByDetails("office", 2).id
		ret.ROOM_STUDIOSIZE_PLAYER2 = TRooms.GetRoomByDetails("studiosize1", 2).id

		ret.ROOM_ARCHIVE_PLAYER3 = TRooms.GetRoomByDetails("archive", 3).id
		ret.ROOM_NEWSAGENCY_PLAYER3 = TRooms.GetRoomByDetails("news", 3).id
		ret.ROOM_BOSS_PLAYER3 = TRooms.GetRoomByDetails("chief", 3).id
		ret.ROOM_OFFICE_PLAYER3 = TRooms.GetRoomByDetails("office", 3).id
		ret.ROOM_STUDIOSIZE_PLAYER3 = TRooms.GetRoomByDetails("studiosize1", 3).id

		ret.ROOM_ARCHIVE_PLAYER4 = TRooms.GetRoomByDetails("archive", 4).id
		ret.ROOM_NEWSAGENCY_PLAYER4 = TRooms.GetRoomByDetails("news", 4).id
		ret.ROOM_BOSS_PLAYER4 = TRooms.GetRoomByDetails("chief", 4).id
		ret.ROOM_OFFICE_PLAYER4 = TRooms.GetRoomByDetails("office", 4).id
		ret.ROOM_STUDIOSIZE_PLAYER4 = TRooms.GetRoomByDetails("studiosize1", 4).id

		Return ret
	End Function

	Method PrintOut:Int(text:String)
		Print text
		Return self.RESULT_OK
	EndMethod

	Method GetProgramme:TProgramme( id:int ) {_exposeToLua}
		return TProgramme.getProgramme( id )
	End Method

	Method GetContract:TContract( id:int ) {_exposeToLua}
		return TContract.getContract( id )
	End Method

	Method GetRoomByDetails:TRooms(roomName:String, playerID:Int)
		return TRooms.GetRoomByDetails(roomName, playerID, 0) '0 = not strict
	End Method

	Method GetRoom:TRooms(id:int)
		return TRooms.GetRoom( id )
	End Method


	Method SendToChat:Int(ChatText:String)
		If Players[ Self.ME ] <> Null
			InGame_Chat.list.AddEntry("", ChatText, Self.ME, "", 0, MilliSecs())
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
		If Not Game.isPlayerID( PlayerID ) Then Return self.RESULT_NOTALLOWED Else Return Floor(Players[ PlayerID ].figure.rect.GetX() )
	End Method

	Method GetPlayerTargetPosX:Int(PlayerID:Int = Null)
		print "VERALTET: GetPlayerTargetPosX -> math.floor( MY.Figure.Target.GetIntX() ) ... bzw GetX() fuer float"
		If Not Game.isPlayerID( PlayerID ) Then Return self.RESULT_NOTALLOWED Else Return Floor(Players[ PlayerID ].figure.target.GetX() )
	End Method

	Method SetPlayerTargetPosX:Int(PlayerID:Int = Null, newTargetX:Int = 0)
		print "VERALTET: SetPlayerTargetPosX -> MY.Figure.changeTarget(x, y=null)"
		If Not Game.isPlayerID( PlayerID ) OR Not Players[PlayerID].isAi() Then Return self.RESULT_NOTALLOWED Else Return Players[PlayerID].figure.changeTarget(newTargetX,Null)
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
		If room <> Null Then Return room.id Else Return self.RESULT_NOTFOUND
	End Method

	Method getPlayerTargetRoom:Int()
		Local room:TRooms = Players[ Self.ME ].figure.toRoom
		If room <> Null Then Return room.id Else Return self.RESULT_NOTFOUND
	End Method

	Method getPlayerFloor:Int()
		Print "VERALTET: TVT.getPlayerFloor() -> MY.Figure.GetFloor()"
		Return Players[ Self.ME ].figure.GetFloor()
	End Method

	Method getRoomFloor:Int(roomId:Int = 0)
		Local Room:TRooms = TRooms.GetRoom(roomId)
		If Room <> Null Then Return Room.Pos.y Else Return self.RESULT_NOTFOUND
	End Method

	Method doGoToRoom:Int(roomId:Int = 0)
		Local Room:TRooms = TRooms.GetRoom(roomId)
		If Room <> Null Then Players[ Self.ME ].Figure.SendToRoom(Room)
	    Return self.RESULT_OK
	End Method



	Method getMillisecs:Int()
		Return MilliSecs()
	End Method

	Method getTime:Int()
		Return Game.timeSinceBegin
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
	    If obj Then Return obj.episodeList.count() Else Return self.RESULT_NOTFOUND
	End Method

	Method MovieFromSerie:Int(serieId:Int = -1, episodeNumber:Int = 0)
		Print "VERALTET: TVT.MovieFromSerie -> Programmeobject.GetEpisode(episode)"
		Local obj:TProgramme = TProgramme.GetProgramme(serieId)
		If obj Then obj = obj.GetEpisode(episodeNumber)
	End Method

	Method MoviePrice:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MoviePrice -> Programmeobject.GetPrice()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
		If obj Then Return obj.getPrice() Else Return self.RESULT_NOTFOUND
	End Method

	Method MovieGenre:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieGenre -> Programmeobject.GetGenre() (bzw. GetGenreString() fuer Textwert)"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
		If obj Then Return obj.Genre Else Return self.RESULT_NOTFOUND
	End Method

	Method MovieLength:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieLength -> Programmeobject.GetBlocks()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
		If obj Then Return obj.blocks Else Return self.RESULT_NOTFOUND
	End Method

	Method MovieXRated:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieXRated -> Programmeobject.GetXRated()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
		If obj Then Return (obj.fsk18 <> "") Else Return self.RESULT_NOTFOUND
	End Method

	Method MovieProfit:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieProfit -> Programmeobject.GetOutcome()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
	    If obj Then Return obj.Outcome Else Return self.RESULT_NOTFOUND
	End Method

	Method MovieSpeed:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieSpeed -> Programmeobject.GetSpeed()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
	    If obj Then Return obj.speed Else Return self.RESULT_NOTFOUND
	End Method

	Method MovieReview:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieReview -> Programmeobject.GetReview()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
	    If obj Then Return obj.review Else Return self.RESULT_NOTFOUND
	End Method

	Method MovieTopicality:Int(movieId:Int = -1)
		Print "VERALTET: TVT.MovieTopicality -> Programmeobject.GetTopicality()"
		Local obj:TProgramme = TProgramme.GetProgramme(movieId)
	    If obj Then Return obj.topicality Else Return self.RESULT_NOTFOUND
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
' Office
'- - - - - -
	Method of_getMovie:Int(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		Local obj:TProgramme	= Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammePlan.GetActualProgramme(hour, day)
		If obj Then Return obj.id Else Return self.RESULT_NOTFOUND
	End Method

	Method of_getSpot:Int(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		Local obj:TAdBlock = Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammePlan.GetActualAdBlock(hour, day)
		If obj Then Return obj.contract.id Else Return self.RESULT_NOTFOUND
	End Method

	Method of_getPlayerSpotCount:Int()
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		Return Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammeCollection.ContractList.Count() - 1
	End Method

	Method of_getPlayerSpot:Int(arraynumber:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		Local owner:Int = Players[ Self.ME ].Figure.inRoom.owner
		If arraynumber >= 0 And arraynumber <= Players[ owner ].ProgrammeCollection.ContractList.Count() - 1
			Local obj:TContract = TContract(Players[ owner ].ProgrammeCollection.ContractList.ValueAtIndex(arraynumber))
			If obj Then Return obj.id Else Return self.RESULT_NOTFOUND
		EndIf
	End Method

	Method of_getSpotWillBeSent:Int(day:Int = -1, hour:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		Local obj:TAdBlock = Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammePlan.GetActualAdBlock(hour, day)
		If obj Then Return obj.GetSpotNumber() Else Return self.RESULT_NOTFOUND
	End Method

	Method of_getSpotBeenSent:Int(contractID:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		Local contractObj:TContract = Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammeCollection.GetContract(contractID)
		If Not contractObj Then Return self.RESULT_NOTFOUND

		Local obj:TAdBlock = TAdBlock.GetBlockByContract( contractObj )
		If obj Then Return obj.contract.GetSpotsSent() Else Return self.RESULT_NOTFOUND
	End Method

	Method of_getSpotDaysLeft:Int(contractID:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		Local contractObj:TContract = Players[ Players[ Self.ME ].Figure.inRoom.owner ].ProgrammeCollection.GetContract(contractID)
		If contractObj Then Return contractobj.getDaysLeft() Else Return self.RESULT_NOTFOUND
	End Method

	'Setzen/Entfernen von Programmobjekten im Planer
	'Rueckgabewerte: (TVT.)RESULT_OK, RESULT_WRONGROOM, RESULT_NOTFOUND
	Method of_doMovieInPlan:Int(day:Int = -1, hour:Int = -1, ObjectID:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		'wenn user schluessel fuer den Raum haben sollte,
		'ist dies hier egal -> nur schauen erlaubt fuer "Fremde"
		If Self.ME <> Players[ Self.ME ].Figure.inRoom.owner Then Return self.RESULT_WRONGROOM

		If ObjectID = 0 'Film bei Day,hour loeschen
			If day = Game.day And hour = Game.GetHour() And Game.GetMinute() > 5 Then Return self.RESULT_INUSE

			Local Obj:TProgrammeBlock = Players[ self.ME ].ProgrammePlan.GetActualProgrammeBlock(hour, day)
			if not Obj then Return self.RESULT_NOTFOUND

			Obj.DeleteBlock()
			Return self.RESULT_OK
		'platzieren
		Else
			Local Obj:TProgramme = Players[ self.ME ].ProgrammeCollection.GetProgramme(ObjectID)
			if not Obj then Return self.RESULT_NOTFOUND

			If Players[ self.ME ].ProgrammePlan.ProgrammePlaceable(Obj, hour, day)
				Local objBlock:TProgrammeBlock	= TProgrammeBlock.CreateDragged(obj, self.ME)
				objBlock.sendHour				= day*24 + hour
				objBlock.dragged				= 0
				ObjBlock.SetBasePos(ObjBlock.GetSlotXY(hour))
				Return self.RESULT_OK
			Else
				Return self.RESULT_NOTALLOWED
			EndIf
		EndIf
	End Method


	Method of_doSpotInPlan:Int(day:Int = -1, hour:Int = -1, ObjectID:Int = -1)
		If Not _PlayerInRoom("office", True) Then Return self.RESULT_WRONGROOM

		'wenn user schluessel fuer den Raum haben sollte,
		'ist dies hier egal -> nur schauen erlaubt fuer "Fremde"
		If Self.ME <> Players[ Self.ME ].Figure.inRoom.owner Then Return self.RESULT_WRONGROOM

		If ObjectID = 0 'Spot bei Day,hour loeschen
			If day = Game.day And hour = Game.GetHour() Then Return -2

			Local Obj:TAdBlock = Players[ self.ME ].ProgrammePlan.GetActualAdBlock(hour, day)
			If not Obj then Return self.RESULT_NOTFOUND

			Obj.RemoveFromPlan()
			Return self.RESULT_OK
		Else
			Local contract:TContract = Players[ self.ME ].ProgrammeCollection.GetContract(ObjectID)
			if not contract then Return self.RESULT_NOTFOUND
			If Players[ self.ME ].ProgrammePlan.AdBlockPlaceable(hour, day)
				Local obj:TAdBlock = TAdBlock.create(contract, TAdBlock.GetBlockX(hour),TAdBlock.GetBlockY(hour), self.ME)
				obj.senddate	= day
				obj.sendtime	= hour
				obj.AddToPlan()
				Return self.RESULT_OK
			Else
				Return self.RESULT_NOTALLOWED
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
		If Self.ME <> Players[ Self.ME ].Figure.inRoom.owner Then Return self.RESULT_WRONGROOM

		If ObjectID = 0 'News bei slotID loeschen
			Local Obj:TNewsBlock = Players[ self.ME ].ProgrammePlan.GetNewsBlockFromSlot(slot)
			If not Obj then Return self.RESULT_NOTFOUND

			'Players[ self.ME ].ProgrammePlan.RemoveNewsBlock(obj)

			Return self.RESULT_OK
		Else
			Local obj:TNewsBlock = Players[ self.ME ].ProgrammePlan.GetNewsBlock(ObjectID)
			If not obj then Return self.RESULT_NOTFOUND
			Players[ self.ME ].ProgrammePlan.SetNewsBlockSlot(obj, slot)
			
			Return self.RESULT_OK
		EndIf
	End Method


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
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		For Local Block:TContractBlock = EachIn TContractBlock.list
			If Block.contract.id = ObjektID And Block.owner <= 0
				Block.SignContract( Self.ME )
				Return self.RESULT_OK
			endif
		Next
		Return self.RESULT_NOTFOUND
	End Method

	Method sa_getSpotCount:Int()
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		local ret:int = 0
		For Local Block:TContractBlock = EachIn TContractBlock.List
			If Block.owner <= 0 Then ret:+1
		Next
		Return ret
	End Method

	Method sa_getSpot:Int(ArrayID:Int = -1)
		If Not _PlayerInRoom("adagency") Then Return self.RESULT_WRONGROOM

		If ArrayID >= TContractBlock.List.Count() Or ArrayID < 0 Then Return self.RESULT_NOTFOUND

		Local Block:TContractBlock = TContractBlock(TContractBlock.List.ValueAtIndex(ArrayID))
		If Block Then Return Block.contract.id Else Return self.RESULT_NOTFOUND
	End Method
	
'- - - - - -
' Movie Dealer - Movie Agency
'- - - - - -
	Method md_getMovieCount:Int()
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		Local ret:Int = 0
		For Local Block:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If Block.owner <> Self.ME Then ret:+1
		Next
		Return ret
	End Method

	Method md_getMovie:Int(ArrayID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		If ArrayID >= TMovieAgencyBlocks.List.Count() Or arrayID < 0 Then Return -2
		Local Block:TMovieAgencyBlocks = TMovieAgencyBlocks(TMovieAgencyBlocks.List.ValueAtIndex(ArrayID))
		If Block Then Return Block.Programme.id Else Return self.RESULT_NOTFOUND
	End Method

	Method md_doBuyMovie:Int(ObjektID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		For Local Block:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If Block.Programme.id = ObjektID Then Return Block.Buy( Self.ME )
		Next
		Return self.RESULT_NOTFOUND
	End Method

'untested
	Method md_doSellMovie:Int(ObjektID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		For Local Block:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If Block.Programme.id = ObjektID Then Return Block.Sell( Self.ME )
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
	Method md_getAuctionMovie:Int(ArrayID:Int = -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		If ArrayID >= TAuctionProgrammeBlocks.List.Count() Or arrayID < 0 Then Return -2
		Local Block:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(TAuctionProgrammeBlocks.List.ValueAtIndex(ArrayID))
		If Block Then Return Block.Programme.id Else Return self.RESULT_NOTFOUND
	End Method

'untested
	Method md_getAuctionMovieCount:Int()
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		return TAuctionProgrammeBlocks.List.count()
	End Method

'untested
	Method md_doBidAuctionMovie:Int(ArrayID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local Block:TAuctionProgrammeBlocks = self.md_getAuctionMovieBlock(ArrayID)
		If Block then Return Block.SetBid( self.ME ) else Return self.RESULT_NOTFOUND
	End Method

'untested
	Method md_GetAuctionMovieNextBid:Int(ArrayID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local Block:TAuctionProgrammeBlocks = self.md_getAuctionMovieBlock(ArrayID)
		If Block then Return Block.GetNextBid() else Return self.RESULT_NOTFOUND
	End Method

'untested
	Method md_GetAuctionMovieHighestBidder:Int(ArrayID:int= -1)
		If Not _PlayerInRoom("movieagency") Then Return self.RESULT_WRONGROOM

		local Block:TAuctionProgrammeBlocks = self.md_getAuctionMovieBlock(ArrayID)
		If Block then Return Block.GetHighestBidder() else Return self.RESULT_NOTFOUND
	End Method


	'LUA_ar_getMovieInBagCount
	'LUA_ar_getMovieInBag
	'LUA_ar_doMovieInBag
	'LUA_ar_doMovieOutBag
	'
	'LUA_bo_doPayCredit
End Type