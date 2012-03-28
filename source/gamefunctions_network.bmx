'handles network events

'first 100 ids reserved for base network events
Const NET_SETSLOT:Int				= 101					' SERVER: command from server to set to a given playerslot
Const NET_SLOTSET:Int				= 102				' ALL: 	  response to all, that IP uses slot X now
Const NET_CHATMESSAGE:Int			= 104				' ALL:    a sent chatmessage ;D
Const NET_PEERDATA:Int				= 105				' Packet contains IPs of all four Players/peers
	Const NET_PLAYERDETAILS:Int			= 106				' ALL:    name, channelname...
Const NET_PLAYERPOSITION:Int		= 107				' ALL:    x,y,room,target...
Const NET_SENDPROGRAMME:Int			= 108				' SERVER: sends a Programme to a user for adding this to the players collection
	Const NET_GAMEREADY:Int				= 109				' ALL:    sends a ReadyFlag
Const NET_STARTGAME:Int				= 110				' SERVER: sends a StartFlag
Const NET_PLAN_PROGRAMMECHANGE:Int	= 111				' ALL:    playerprogramme has changed (added, removed and so on)
Const NET_STATIONCHANGE:Int			= 112				' ALL:    stations have changes (added ...)
Const NET_ELEVATORROUTECHANGE:Int	= 113				' ALL:    elevator routes have changed
Const NET_ELEVATORSYNCHRONIZE:Int	= 114				' SERVER: synchronizing the elevator
Const NET_PLAN_ADCHANGE:Int			= 115				' ALL:    playerprogramme has changed (added, removed and so on)
Const NET_SENDCONTRACT:Int			= 116				' SERVER: sends a Contract to a user for adding this to the players collection
Const NET_PROGRAMMECOLLECTION_CHANGE:Int = 117			' ALL:    programmecollection was changed (removed, sold...)
Const NET_SENDNEWS:Int				= 118				' SERVER: creates and sends news
Const NET_NEWSSUBSCRIPTIONCHANGE:Int= 119				' ALL: sends Changes in subscription levels of news-agencies
Const NET_PLAN_NEWSCHANGE:Int		= 120				' ALL: sends Changes of news in the players newsstudio
Const NET_MOVIEAGENCY_CHANGE:Int	= 121				' ALL: sends changes of programme in movieshop

rem

Const NET_DELETE:Int				= 0
Const NET_ADD:Int					= 1000
Const NET_CHANGE:Int				= 2000
Const NET_BUY:Int					= 3000
Const NET_SELL:Int					= 4000
Const NET_BID:Int					= 5000
Const NET_SWITCH:Int				= 6000
endrem

Network.callbackServer		= ServerEventHandler
Network.callbackClient		= ClientEventHandler
Network.callbackInfoChannel	= InfoChannelEventHandler

Function ServerEventHandler(server:TNetworkServer,client:TNetworkclient,id:Int, networkObject:TNetworkObject)
	print "Server got event:" + networkObject.evType
	Select networkObject.evType
		'player joined, send player data to all
		case NET_PLAYERJOINED 		NetworkHelper.SendPlayerDetails()
	EndSelect
End Function

Function ClientEventHandler(client:TNetworkclient,id:Int, networkObject:TNetworkObject)
	print "client got event:" + networkObject.evType
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

		case NET_PLAYERDETAILS		NetworkHelper.ReceivePlayerDetails( networkObject )
		case NET_GAMEREADY			NetworkHelper.ReceiveGameReady( networkObject )
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
	Method AddContractsToPlayer(playerID:Int, contract:TContract[])
		local obj:TNetworkObject = TNetworkObject.Create( NET_SENDCONTRACT )
		obj.setInt(1, playerID)

		'store in one field
		local IDstring:string=""
		For Local i:Int = 0 To contract.length-1
			IDstring :+ contract[i].id+","
		Next
		obj.setString(2, IDstring)

		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method AddProgrammesToPlayer(playerID:Int, programme:TProgramme[])
		local obj:TNetworkObject = TNetworkObject.Create( NET_SENDPROGRAMME )
		obj.setInt(1, playerID)

		'store in one field
		local IDstring:string=""
		For Local i:Int = 0 To programme.length-1
			IDstring :+ programme[i].id+","
		Next
		obj.setString(2, IDstring)

		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
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

	Method SendPlayerPosition()
		Print "NET: send playerposition of SELF (hosting: AI players too)"

		For Local i:Int = 1 To 4
			'it's me or i'm hosting and its an AI player
			if i = Network.client.playerID OR (Network.isServer and Players[i].isAI())
				local obj:TNetworkObject = TNetworkObject.Create( NET_PLAYERPOSITION )
				obj.SetInt(	1, i )							'playerID
				obj.SetInt(	2, Players[i].Figure.pos.x )	'pos.x
				obj.SetInt(	3, Players[i].Figure.pos.y )	'...
				obj.SetInt(	4, Players[i].Figure.target.x )
				obj.SetInt(	5, Players[i].Figure.target.y )
				if Players[i].Figure.inRoom <> null 			then obj.setInt( 6, Players[i].Figure.inRoom.uniqueID)
				if Players[i].Figure.clickedToRoom <> null		then obj.setInt( 7, Players[i].Figure.clickedToRoom.uniqueID)
				if Players[i].Figure.toRoom <> null 			then obj.setInt( 8, Players[i].Figure.toRoom.uniqueID)
				if Players[i].Figure.fromRoom <> null 			then obj.setInt( 9, Players[i].Figure.fromRoom.uniqueID)
				Network.BroadcastNetworkObject( obj )
			EndIf
		Next
	End Method

	Method SendGameReady(playerID:Int, onlyTo:Int=-1)
		local obj:TNetworkObject = TNetworkObject.Create( NET_GAMEREADY )
		obj.setInt(1, playerID)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveGameReady( obj:TNetworkObject )
		local playerID:int = obj.getInt(1)
		Print "NET: got GameReadyFlag from Player:"+Players[ playerID ].name + " ("+playerID+")"
	End Method



	Method SendNews(playerID:Int, news:TNews)
		local obj:TNetworkObject = TNetworkObject.Create( NET_SENDNEWS )
		obj.setInt(1, playerID)
		obj.setInt(2, news.id)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method SendChatMessage(ChatMessage:String = "")
		local obj:TNetworkObject = TNetworkObject.Create( NET_CHATMESSAGE)
		obj.setInt(1, Game.PlayerID)
		obj.setString(2, ChatMessage)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE  )
	End Method




	Method SendNewsSubscriptionChange(playerID:Int, genre:int, level:int)
		local obj:TNetworkObject = TNetworkObject.Create( NET_NEWSSUBSCRIPTIONCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, genre)
		obj.setInt(3, level)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
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

	Method SendMovieAgencyChange(methodtype:int, playerID:Int, newID:Int=-1, slot:Int=-1, programme:TProgramme)
		local obj:TNetworkObject = TNetworkObject.Create( NET_MOVIEAGENCY_CHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, methodtype)
		obj.setInt(3, newid)
		obj.setInt(4, slot)
		obj.setInt(5, programme.id)
		Network.BroadcastNetworkObject( obj,  NET_PACKET_RELIABLE )
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

End Type
Global NetworkHelper:TNetworkHelper = new TNetworkHelper