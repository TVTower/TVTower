'handles network events

'first 100 ids reserved for base network events
'Const NET_SETSLOT:Int					= 101				' SERVER: command from server to set to a given playerslot
'Const NET_SLOTSET:Int					= 102				' ALL: 	  response to all, that IP uses slot X now

Const NET_SENDGAMESTATE:Int				= 102				' ALL:    sends a ReadyFlag
Const NET_GAMEREADY:Int					= 103				' ALL:    sends a ReadyFlag
Const NET_STARTGAME:Int					= 104				' SERVER: sends a StartFlag
Const NET_CHATMESSAGE:Int				= 105				' ALL:    a sent chatmessage ;D
Const NET_PLAYERDETAILS:Int				= 106				' ALL:    name, channelname...
Const NET_FIGUREPOSITION:Int			= 107				' ALL:    x,y,room,target...
Const NET_SENDPROGRAMME:Int				= 108				' SERVER: sends a Programme to a user for adding this to the players collection
Const NET_SENDCONTRACT:Int				= 109				' SERVER: sends a Contract to a user for adding this to the players collection
Const NET_SENDNEWS:Int					= 110				' SERVER: creates and sends news
Const NET_ELEVATORSYNCHRONIZE:Int		= 111				' SERVER: synchronizing the elevator
Const NET_ELEVATORROUTECHANGE:Int		= 112				' ALL:    elevator routes have changed
Const NET_NEWSSUBSCRIPTIONCHANGE:Int	= 113				' ALL: sends Changes in subscription levels of news-agencies
Const NET_STATIONCHANGE:Int				= 114				' ALL:    stations have changes (added ...)
Const NET_MOVIEAGENCYCHANGE:Int			= 115				' ALL: sends changes of programme in movieshop
Const NET_PROGRAMMECOLLECTIONCHANGE:Int = 116				' ALL:    programmecollection was changed (removed, sold...)
Const NET_PLAN_PROGRAMMECHANGE:Int		= 117				' ALL:    playerprogramme has changed (added, removed and so on)
Const NET_PLAN_ADCHANGE:Int				= 118				' ALL:    playerprogramme has changed (added, removed and so on)
Const NET_PLAN_NEWSCHANGE:Int			= 119				' ALL: sends Changes of news in the players newsstudio

Const NET_DELETE:Int					= 0
Const NET_ADD:Int						= 1000
Const NET_CHANGE:Int					= 2000
Const NET_BUY:Int						= 3000
Const NET_SELL:Int						= 4000
Const NET_BID:Int						= 5000
Const NET_SWITCH:Int					= 6000

Network.callbackServer		= ServerEventHandler
Network.callbackClient		= ClientEventHandler
Network.callbackInfoChannel	= InfoChannelEventHandler

Function ServerEventHandler(server:TNetworkServer,client:TNetworkclient,id:Int, networkObject:TNetworkObject)
	Select networkObject.evType
		'player joined, send player data to all
		case NET_PLAYERJOINED 		NetworkHelper.SendPlayerDetails()
'		default 					print "server got unused event:" + networkObject.evType
	EndSelect
End Function

Function ClientEventHandler(client:TNetworkclient,id:Int, networkObject:TNetworkObject)
	Select networkObject.evType
		case NET_PLAYERJOINED
			local playerID:int		= NetworkObject.getInt(1)
			local playerName:string	= NetworkObject.getString(2)
			if Game.isPlayerID(playerID) then Players[playerID].Figure.ControlledByID = playerID

		case NET_JOINRESPONSE
			if not Network.client.joined then return
			if Network.isServer then return
			'we are not the gamemaster and got a playerID
			local joined:int		= NetworkObject.getInt(1)
			local playerID:int		= NetworkObject.getInt(2)
			if Game.isPlayerID(playerID)
				Game.playerID			= playerID
				Network.client.playerID = playerID
			endif

		case NET_STARTGAME					print "got: startgame"
											Game.gamestate = GAMESTATE_RUNNING
											Game.networkgameready = 1 'start the game
		case NET_PLAYERDETAILS				NetworkHelper.ReceivePlayerDetails( networkObject )
		case NET_FIGUREPOSITION				NetworkHelper.ReceiveFigurePosition( networkObject )
		case NET_GAMEREADY					NetworkHelper.ReceiveGameReady( networkObject )
		case NET_SENDCONTRACT				NetworkHelper.ReceiveContractsToPlayer( networkObject )
		case NET_SENDPROGRAMME				NetworkHelper.ReceiveProgrammesToPlayer( networkObject )
		case NET_SENDNEWS					NetworkHelper.ReceiveNews( networkObject )
		case NET_SENDGAMESTATE				NetworkHelper.ReceiveGameState( networkObject )

		case NET_CHATMESSAGE				NetworkHelper.ReceiveChatMessage( networkObject )

		case NET_ELEVATORROUTECHANGE		Building.Elevator.Network_ReceiveRouteChange( networkObject )
		case NET_ELEVATORSYNCHRONIZE		Building.Elevator.Network_ReceiveSynchronize( networkObject )

		case NET_NEWSSUBSCRIPTIONCHANGE		NetworkHelper.ReceiveNewsSubscriptionChange( networkObject )
		case NET_MOVIEAGENCYCHANGE			NetworkHelper.ReceiveMovieAgencyChange( networkObject )
		case NET_PROGRAMMECOLLECTIONCHANGE	NetworkHelper.ReceiveProgrammeCollectionChange( networkObject )
		case NET_STATIONCHANGE				NetworkHelper.ReceiveStationChange( networkObject )

		case NET_PLAN_PROGRAMMECHANGE		NetworkHelper.ReceivePlanProgrammeChange( networkObject )
		case NET_PLAN_NEWSCHANGE			NetworkHelper.ReceivePlanNewsChange( networkObject )
		case NET_PLAN_ADCHANGE				NetworkHelper.ReceivePlanAdChange( networkObject )

		default 							if networkObject.evType>=100 then print "client got unused event:" + networkObject.evType
	EndSelect

End Function

Function InfoChannelEventHandler(networkObject:TNetworkObject)
'	print "infochannel: got event: "+networkObject.evType
	if networkObject.evType = NET_ANNOUNCEGAME
		Local teamamount:Int		= networkObject.getInt(1)
		Local title:String			= networkObject.getString(2)
		local IP:int				= networkObject.getInt(3)		'could differ from senderIP
		local Port:int				= networkObject.getInt(4)		'differs from senderPort (info channel)
		'If _ip <> intLocalIP then
		NetgameLobby_gamelist.addUniqueEntry(title, title+"  (Spieler: "+(4-teamamount)+" von 4)","",DottedIP(IP), Port,0, "HOSTGAME")
	endif
End Function




Type TNetworkHelper
	Method SendGameState()
		local obj:TNetworkObject = TNetworkObject.Create( NET_SENDGAMESTATE )
		obj.setInt(1, Game.playerID)
		obj.setFloat(2, game.speed)
		obj.setFloat(3, game.minutesOfDayGone) 'lastminutes not stored - so clients can catch up
		obj.setFloat(4, game.timeSinceBegin)
		Network.BroadcastNetworkObject( obj, not NET_PACKET_RELIABLE )
	End Method

	Method ReceiveGameState( obj:TNetworkObject )
		Local playerID:Int		= obj.getInt(1)
		'must be a player DIFFERENT to me
		if not Game.IsPlayerID(playerID) or playerID = game.playerID then return

		'60 upd per second = -> App.Timer.getDeltaTime() => 16ms
		'ping in ms -> latency/2 -> 0.5*latency/16ms = "1,3 updates bis ping ankommt"
		'pro Update: zeiterhoehung von "game.speed/10.0"
		'-> bereinigung: "0.5*latency/16" * "game.speed/10.0"
		local correction:float = 0.5*Network.client.latency / App.Timer.getDeltaTime()   *   game.speed/10.0
		'we want it in s not in ms
		correction :/ 1000.0
'		print obj.getFloat(3) + "  + "+correction

		Game.speed 				= obj.getFloat(2)
		Game.minutesOfDayGone	= obj.getFloat(3) + correction
		Game.timeSinceBegin		= obj.getFloat(4) + correction
	End Method


'checked
	Method SendContractsToPlayer(playerID:Int, contract:TContract[])
		local obj:TNetworkObject = TNetworkObject.Create( NET_SENDCONTRACT )
		obj.setInt(1, playerID)

		'store in one field
		local IDstring:string=""
		if contract.length > 0
			For Local i:Int = 0 To contract.length-1
				IDstring :+ contract[i].id+","
			Next
		endif
		obj.setString(2, IDstring)

		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveContractsToPlayer( obj:TNetworkObject )
		Local remotePlayerID:Int		= obj.getInt(1)
		local IDs:string[]				= obj.getString(2).split(",")
		for local id:string = eachin IDs
			if id <> "" and int(id) > 0
				Players[ remotePlayerID ].ProgrammeCollection.AddContract(TContract.getContract( int(id) ))
			endif
		Next
	End Method



'checked
	Method SendProgrammesToPlayer(playerID:Int, programme:TProgramme[])
		local obj:TNetworkObject = TNetworkObject.Create( NET_SENDPROGRAMME )
		obj.setInt(1, playerID)

		'store in one field
		local IDstring:string=""
		if programme.length > 0
			For Local i:Int = 0 To programme.length-1
				if programme[i] = null
					print "programme "+i+" is null"
				else
					'print "send programme - id:"+ programme[i].id + "	title:"+programme[i].title
					IDstring :+ programme[i].id+","
				endif
			Next
		endif
		obj.setString(2, IDstring)

		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveProgrammesToPlayer( obj:TNetworkObject )
		Local remotePlayerID:Int		= obj.getInt(1)
		local IDs:string[]				= obj.getString(2).split(",")
		for local id:string = eachin IDs
			if id <> "" and int(id) > 0
				'print "get programme - id:"+ int(id) + "	title:"+TProgramme.GetProgramme( int(id) ).title
				Players[ remotePlayerID ].ProgrammeCollection.AddProgramme(TProgramme.GetProgramme( int(id) ))
			endif
		Next
	End Method



'checked
	Method SendPlayerDetails()
		'print "Send Player Details to all but me ("+TNetwork.dottedIP(host.ip)+")"
		'send packets indivual - no need to have multiple entities in one packet

		for local player:TPlayer = eachin TPlayer.list
			'it's me or i'm hosting and its an AI player
			if player.playerID = Network.client.playerID OR (Network.isServer and Player.isAI())
				'Print "NET: send playerdetails of ME and IF I'm the host also from AI players"

				local obj:TNetworkObject = TNetworkObject.Create( NET_PLAYERDETAILS )
				obj.SetInt(	1, player.playerID )
				obj.SetString( 2, Player.name )			'name
				obj.SetString( 3, Player.channelname )	'...
				obj.SetInt(	4, Player.color.toInt() )
				obj.SetInt(	5, Player.figurebase )
				obj.SetInt(	6, Player.figure.controlledByID )

				Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
			EndIf
		Next
	End Method

	Method ReceivePlayerDetails( obj:TNetworkObject )
		Local playerID:Int			= obj.getInt(1)
		local player:TPlayer		= TPlayer.getByID( playerID )
		if player = null then return

		Local name:string			= obj.getString(2)
		Local channelName:string	= obj.getString(3)
		Local color:int				= obj.getInt(4)
		Local figureBase:int		= obj.getInt(5)
		Local controlledByID:int	= obj.getInt(6)

		If figureBase <> player.figurebase Then player.UpdateFigureBase(figureBase)
		If player.color.toInt() <> color
			player.color.fromInt(color)
			player.RecolorFigure()
		EndIf
		If playerID <> game.playerID
			player.name								= name
			player.channelname						= channelName
			MenuPlayerNames[ playerID-1 ].value		= name
			MenuChannelNames[ playerID-1 ].value	= channelName
			player.figure.controlledByID			= controlledByID
		EndIf
	End Method



'checked
	Method SendFigurePosition(figure:TFigures)
		'no player figures can only be send from Master
		if figure.ParentPlayer = null and not Network.isServer then return

		local obj:TNetworkObject = TNetworkObject.Create( NET_FIGUREPOSITION )
		obj.SetInt(		1, figure.id )		'playerID
		obj.SetFloat(	2, figure.pos.x )	'pos.x
		obj.SetFloat(	3, figure.pos.y )	'...
		obj.SetFloat(	4, figure.target.x )
		obj.SetFloat(	5, figure.target.y )
		if figure.inRoom <> null 			then obj.setInt( 6, figure.inRoom.uniqueID)
		if figure.clickedToRoom <> null		then obj.setInt( 7, figure.clickedToRoom.uniqueID)
		if figure.toRoom <> null 			then obj.setInt( 8, figure.toRoom.uniqueID)
		if figure.fromRoom <> null 			then obj.setInt( 9, figure.fromRoom.uniqueID)
		Network.BroadcastNetworkObject( obj )
	End Method

	Method ReceiveFigurePosition( obj:TNetworkObject )
		Local figureID:Int		= obj.getInt(1)
		local figure:TFigures	= TFigures.getByID( figureID )
		if figure = null then return

		local posX:Float			= obj.getFloat(2)
		local posY:Float			= obj.getFloat(3)
		local targetX:Float			= obj.getFloat(4)
		local targetY:Float			= obj.getFloat(5)
		local inRoomID:int			= obj.getInt(6, -1)
		local clickedRoomID:int		= obj.getInt(7, -1)
		local toRoomID:int			= obj.getInt(8, -1)
		local fromRoomID:int		= obj.getInt(9, -1)

		If not figure.IsInElevator()
			'only set X if wrong floor or x differs > 10 pixels
			if posY = targetY
				if Abs(posX - targetX) > 10 then figure.pos.setXY(posX,posY)
			else
				figure.pos.setXY(posX,posY)
			endif
		endif
		figure.target.setXY(targetX,targetY)

		If inRoomID <= 0 Then figure.inRoom = Null
		If figure.inroom <> Null
			If inRoomID > 0 and figure.inRoom.uniqueID <> inRoomID
				figure.inRoom = TRooms.GetRoomFromID(inRoomID)
				If figure.inRoom.name = "elevator" then Building.Elevator.waitAtFloorTimer = MilliSecs() + Building.Elevator.PlanTime
			EndIf
		EndIf

		If clickedRoomID <= 0 Then figure.clickedToRoom = Null
		If clickedRoomID > 0 Then figure.clickedToRoom = TRooms.GetRoomFromID( clickedRoomID )

		If toRoomID <= 0 Then figure.toRoom = Null
		If toRoomID > 0 Then figure.toRoom = TRooms.GetRoomFromID( toRoomID )

		If fromRoomID <= 0 Then figure.fromRoom = Null
		If fromRoomID > 0 And figure.fromroom <> Null
			If figure.fromRoom.uniqueID <> fromRoomID then figure.fromRoom = TRooms.GetRoomFromID(fromRoomID)
		EndIf
	End Method



'checked
	Method SendGameReady(playerID:Int, onlyTo:Int=-1)
		print "sendGameReady "+playerID
		local obj:TNetworkObject = TNetworkObject.Create( NET_GAMEREADY )
		obj.setInt(1, playerID)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )

		Game.gamestate = GAMESTATE_STARTMULTIPLAYER
		'self ready
		Players[ playerID ].networkstate = 1

		for local i:int = 1 to 4
			'set AI players ready
			if Players[ i ].figure.controlledByID = 0 then Players[ i ].networkstate = 1
		NExt

		if Network.isServer

			local allReady:int = 1
			for local otherclient:TNetworkclient = eachin Network.server.clients
				if not Players[ otherclient.playerID ].networkstate then allReady = false
			Next
			if allReady
				'send game start
				Game.networkgameready = 1
				Game.gamestate = GAMESTATE_RUNNING
				GameSettingsOkButton_Announce.crossed = False

				print "NET: send game start to all others"
				Network.BroadcastNetworkObject( TNetworkObject.Create( NET_STARTGAME ), NET_PACKET_RELIABLE )
				return
			endif
		endif
	End Method

	Method ReceiveGameReady( obj:TNetworkObject )
		local remotePlayerID:int = obj.getInt(1)
		Players[ remotePlayerID ].networkstate = 1

		'all players have their start programme?
		local allReady:int = 1
		for local i:int = 1 to 4
			if Players[i].ProgrammeCollection.movielist.count() < Game.startMovieAmount
				print "movie missing player("+i+") " + Players[i].ProgrammeCollection.movielist.count() + " < " + Game.startMovieAmount
				allReady = false
				exit
			endif
			if Players[i].ProgrammeCollection.serieslist.count() < Game.startSeriesAmount
				print "serie missing player("+i+") " + Players[i].ProgrammeCollection.movielist.count() + " < " + Game.startMovieAmount
				allReady = false
				exit
			endif
			if Players[i].ProgrammeCollection.contractlist.count() < Game.startAdAmount then print "ad missing";allReady = false;exit
		Next
		if allReady and Game.GAMESTATE <> GAMESTATE_RUNNING
			SendGameReady( Game.PlayerID, 0)
		endif
	End Method



'checked
	Method SendNewsSubscriptionChange(playerID:Int, genre:int, level:int)
		local obj:TNetworkObject = TNetworkObject.Create( NET_NEWSSUBSCRIPTIONCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, genre)
		obj.setInt(3, level)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveNewsSubscriptionChange( obj:TNetworkObject )
		Local playerID:Int			= obj.getInt(1)
		local player:TPlayer		= TPlayer.getByID( playerID )
		if player = null then return

		Local genre:Int				= obj.getInt(2)
		Local level:Int				= obj.getInt(3)
		Players[ playerID ].setNewsAbonnement(genre, level, false)
	End Method




	Method SendMovieAgencyChange(methodtype:int, playerID:Int, newID:Int=-1, slot:Int=-1, programme:TProgramme)
		local obj:TNetworkObject = TNetworkObject.Create( NET_MOVIEAGENCYCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, methodtype)
		obj.setInt(3, newid)
		obj.setInt(4, slot)
		obj.setInt(5, programme.id)
		Network.BroadcastNetworkObject( obj,  NET_PACKET_RELIABLE )
	End Method

	Method ReceiveMovieAgencyChange( obj:TNetworkObject )
		Local playerID:Int			= obj.getInt(1)
		Local methodtype:Int		= obj.getInt(2)
		Local newid:Int 			= obj.getInt(3)
		Local slot:Int 				= obj.getInt(4)
		Local programmeID:Int		= obj.getInt(5)

		Local tmpID:Int = -1
		Local oldX:Int, oldY:Int
		Select methodtype
			Case NET_SWITCH
								Local tmpBlock:TMovieAgencyBlocks[3]
								For Local locObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
									If not locObj.Programme then continue
									If locObj.Programme.id = ProgrammeID then tmpBlock[0] = locObj
									If locObj.Programme.id = newID then tmpBlock[1] = locObj
								Next
								Print "had to switch ID"+ProgrammeID+ " with ID"+newID+"/"+tmpBlock[1].programme.id
								If tmpBlock[0] <> Null And tmpBlock[1] <> Null then tmpBlock[0].SwitchBlock(tmpBlock[1])
			Case NET_BUY, NET_SELL
								For Local locObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
									If not locObj.Programme then continue
									If locObj.Programme.id = ProgrammeID
										if methodtype = NET_BUY then locObj.Buy( playerID, true)
										if methodtype = NET_SELL then locObj.Sell( playerID, true)
										print "NET: MovieAgency "+methodtype+" obj:"+locobj.programme.title
										exit
									EndIf
								Next
			Case NET_BID
								For Local locObj:TAuctionProgrammeBlocks  = EachIn TAuctionProgrammeBlocks.List
									If not locObj.Programme then continue
									If locobj.Programme.id = ProgrammeID
										locObj.SetBid( PlayerID, programmeID)
										print "NET: MovieAgency auction bid "+methodtype+" obj:"+locobj.programme.title
										exit
									endif
								Next
			Default
								Print "SendMovieAgencyChange: no method mentioned"
		End Select
	End Method




	'typ = 1 - remove from plan, typ = 0 - sell, typ = 2 - readd, typ = 3 - remove from collection
	Method SendProgrammeCollectionChange(playerID:int= -1, programme:TProgramme, typ:int=0)
		local obj:TNetworkObject = TNetworkObject.Create( NET_PROGRAMMECOLLECTIONCHANGE )
		obj.SetInt(1, playerID)
		obj.SetInt(2, programme.id)
		obj.SetInt(3, typ)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveProgrammeCollectionChange( obj:TNetworkObject)
		local playerID:int		= obj.getInt(1)
		local programmeID:int	= obj.getInt(2)
		local typ:int			= obj.getInt(3)

		Local programme:TProgramme = TProgramme.GetProgramme( programmeID )
		if not programme or not Game.isPlayerID(playerID) then return

		select typ
			'readd
			case 2	Players[ playerID ].ProgrammeCollection.AddProgramme(Programme)
					TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, playerID)
					print "NET: PCollection - readd "+programme.title
			'sell
			case 0	Players[ playerID ].finances[Game.getWeekday()].SellMovie(Programme.ComputePrice())
					TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, playerID)
					print "NET: PCollection - sell "+programme.title

			'remove from Plan (Archive - ProgrammeToSuitcase)
			case 1	Players[ playerID ].ProgrammePlan.RemoveProgramme( programme )
					print "NET: PCollection - remove from plan "+programme.title

			'remove from Collection (Archive - RemoveProgramme)
			case 3	Players[ playerID ].ProgrammeCollection.RemoveProgramme( programme )
					print "NET: PCollection - remove from collection "+programme.title
		EndSelect
	End Method



'checked
	Method SendNews(playerID:Int, news:TNews)
		local obj:TNetworkObject = TNetworkObject.Create( NET_SENDNEWS )
		obj.setInt(1, playerID)
		obj.setInt(2, news.id)
		print "sende news: "+news.id+" - "+news.title
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveNews( obj:TNetworkObject )
		Local playerID:Int	= obj.getInt(1)
		Local newsID:Int	= obj.getInt(2)
		Local news:TNews	= TNews.GetNews(newsID)
		If not news or not Game.isPlayerID(playerID) then return
		NewsAgency.AddNewsToPlayer(news, playerID, true)

		Print "net: added news (id:"+newsID+") to Player:"+playerID
	End Method



'checked
	Method SendChatMessage(ChatMessage:String = "")
		local obj:TNetworkObject = TNetworkObject.Create( NET_CHATMESSAGE)
		obj.setInt(1, Game.PlayerID)
		obj.setString(2, ChatMessage)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE  )
	End Method

	Method ReceiveChatMessage( obj:TNetworkObject )
		Local playerID:Int			= obj.getInt(1)
		Local chatMessage:String	= obj.getString(2)
		If Game.gamestate = GAMESTATE_RUNNING
			InGame_Chat.AddEntry("",ChatMessage, playerID,"", "", MilliSecs())
		Else
			GameSettings_Chat.AddEntry("", ChatMessage, playerID,"", "", MilliSecs())
		EndIf
	End Method




	Method SendStationChange(playerID:Int, station:TStation, newaudience:Int, add:int=1)
		local obj:TNetworkObject = TNetworkObject.Create( NET_STATIONCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, add)
		obj.setFloat(3, station.Pos.x)
		obj.setFloat(4, station.Pos.y)
		obj.setInt(5, station.reach)
		obj.setInt(6, station.price)
		obj.setInt(7, newaudience)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveStationChange( obj:TNetworkObject )
		Local playerID:Int	= obj.getInt(1)
		if not Game.isPlayerID( playerID ) then return

		Local add:int		= obj.getInt(2)
		Local pos:TPosition	= TPosition.Create( obj.getFloat(3), obj.getFloat(4) )
		Local reach:Int		= obj.getInt(5)
		Local price:Int		= obj.getInt(6)
		Local newaudience:Int= obj.getInt(7)
		If add
			StationMap.Buy(pos.x,pos.y, playerID, true)
			Print "NET: ADDED station to Player:"+playerID
		else
			StationMap.SellByPos(pos, reach, playerID )
			Print "NET: REMVOED station from Player:"+playerID
		EndIf
	End Method



	'add = 1 - added, add = 0 - removed
	Method SendPlanNewsChange(playerID:Int, block:TNewsBlock, remove:int=0)
		local obj:TNetworkObject = TNetworkObject.Create( NET_PLAN_NEWSCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, remove)
		obj.setInt(3, block.id)
		obj.setFloat(4, block.Pos.x)
		obj.setFloat(5, block.Pos.y)
		obj.setFloat(6, block.StartPos.x)
		obj.setFloat(7, block.StartPos.y)
		obj.setInt(8, block.paid)
		obj.setInt(9, block.news.id)
		obj.setInt(10, block.sendslot)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceivePlanNewsChange( obj:TNetworkObject )
		local playerID:int		= obj.getInt(1)
		if not Game.IsPlayerID(playerID) then return

		local remove:int		= obj.getInt(2)
		local blockID:int		= obj.getInt(3)
		local pos:TPosition 	= TPosition.Create( obj.getFloat(4), obj.getFloat(5) )
		local startpos:TPosition= TPosition.Create( obj.getFloat(6), obj.getFloat(7) )
		local paid:int			= obj.getInt(8)
		local newsID:int		= obj.getInt(9)
		local sendslot:int		= obj.getInt(10)

		Local newsblock:TNewsblock = Players[ playerID ].ProgrammePlan.getNewsBlock(blockID)
		if not newsblock or newsblock.news.id <> newsID then return

		if remove then Players[ playerID ].ProgrammePlan.removeNewsBlock(newsBlock)
		If Not paid Then newsblock.Pay()
		newsblock.sendslot	= sendslot
		newsblock.owner		= playerID
		newsblock.Pos		= pos
		newsblock.StartPos	= startpos
		print "NET: NewsChange - "+remove+": "+newsblock.news.title
	End Method



'checked
	Method SendPlanAdChange(playerID:Int, block:TAdBlock, add:int=1)
		local obj:TNetworkObject = TNetworkObject.Create( NET_PLAN_ADCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, add)
		obj.setInt(3, block.id)
		obj.setFloat(4, block.Pos.x)
		obj.setFloat(5, block.Pos.y)
		obj.setFloat(6, block.StartPos.x)
		obj.setFloat(7, block.StartPos.y)
		obj.setInt(8, block.senddate)
		obj.setInt(9, block.sendtime)
		obj.setInt(10, block.contract.id)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceivePlanAdChange( obj:TNetworkObject )
		local playerID:int		= obj.getInt(1)
		if not Game.IsPlayerID(playerID) then return

		local add:int			= obj.getInt(2)
		local blockID:int		= obj.getInt(3)
		local pos:TPosition 	= TPosition.Create( obj.getFloat(4), obj.getFloat(5) )
		local startpos:TPosition= TPosition.Create( obj.getFloat(6), obj.getFloat(7) )
		local senddate:int		= obj.getInt(8)
		local sendtime:int		= obj.getInt(9)
		local contractID:int	= obj.getInt(10)

		Local Adblock:TAdBlock	= TAdBlock.getBlock( blockID )
		if not Adblock
			Local Contract:TContract = Players[ playerID ].ProgrammeCollection.getContract( contractID )
			If not contract then return

			Adblock = TAdblock.CreateDragged( Contract,playerID )
			Adblock.dragged = 0
			'Print "NET: CREATED NEW Adblock: "+contract.Title
		endif

		Adblock.senddate			= senddate
		Adblock.sendtime			= sendtime
		Adblock.contract.senddate	= senddate
		Adblock.contract.sendtime	= sendtime
		AdBlock.Pos					= pos
		AdBlock.StartPos			= startpos

		Players[ playerID ].ProgrammePlan.RefreshAdPlan( senddate )
		If add
			Players[ playerID ].ProgrammePlan.AddContract( adblock.contract )
			'Print "NET: ADDED adblock:"+Adblock.contract.Title+" to Player:"+playerID
		Else
			Players[ playerID ].ProgrammePlan.RemoveContract( adblock.contract )
			'Print "NET: REMOVED adblock:"+Adblock.contract.Title+" from Player:"+playerID
		EndIf
	End Method



'checked
	'add = 1 - added, add = 0 - removed
	Method SendPlanProgrammeChange(playerID:Int, block:TProgrammeBlock, add:int=1)
		local obj:TNetworkObject = TNetworkObject.Create( NET_PLAN_PROGRAMMECHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, add)
		obj.setInt(3, block.id)
		obj.setFloat(4, block.Pos.x)
		obj.setFloat(5, block.Pos.y)
		obj.setFloat(6, block.StartPos.x)
		obj.setFloat(7, block.StartPos.y)
		obj.setInt(8, block.sendhour)
		obj.setInt(10, block.Programme.id)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceivePlanProgrammeChange( obj:TNetworkObject )
		local playerID:int		= obj.getInt(1)
		if not Game.IsPlayerID(playerID) then return

		local add:int			= obj.getInt(2)
		local blockID:int		= obj.getInt(3)
		local pos:TPosition 	= TPosition.Create( obj.getFloat(4), obj.getFloat(5) )
		local startpos:TPosition= TPosition.Create( obj.getFloat(6), obj.getFloat(7) )

		local sendhour:int		= obj.getInt(8)
		'leave int 9 alone
		local programmeID:int	= obj.getInt(10)

		Local programmeblock:TProgrammeBlock = Players[ playerID ].ProgrammePlan.GetProgrammeBlock( blockID )
		If not programmeblock
			Local Programme:TProgramme = TProgramme.GetProgramme( programmeID )
			If Programme = Null Then Print "programme not found";return
			programmeBlock			= TProgrammeBlock.CreateDragged( programme, playerID )
			ProgrammeBlock.dragged	= 0
			'Print "NET: ADDED NEW programme"
		endif

		programmeBlock.sendhour = sendhour
		programmeBlock.Pos		= pos
		programmeBlock.StartPos	= startpos

		If add
			Players[ playerID ].ProgrammePlan.AddProgrammeBlock( Programmeblock )
			'Print "NET: ADDED programme:"+Programmeblock.programme.Title+" to Player:"+playerID
		Else
			Players[ playerID ].ProgrammePlan.RemoveProgramme( Programmeblock.programme )
			'Print "NET: REMOVED programme:"+Programmeblock.programme.Title+" from Player:"+playerID
		EndIf
	End Method

End Type
Global NetworkHelper:TNetworkHelper = new TNetworkHelper