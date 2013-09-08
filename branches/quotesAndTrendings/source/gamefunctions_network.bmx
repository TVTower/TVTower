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
'now handled by PROGRAMMECOLLECTIONCHANGE
'Const NET_SENDPROGRAMME:Int			= 108				' SERVER: sends a Programme to a user for adding this to the players collection
'Const NET_SENDCONTRACT:Int				= 109				' SERVER: sends a Contract to a user for adding this to the players collection
'Const NET_SENDNEWS:Int					= 110				' SERVER: creates and sends news
Const NET_ELEVATORSYNCHRONIZE:Int		= 111				' SERVER: synchronizing the elevator
Const NET_ELEVATORROUTECHANGE:Int		= 112				' ALL:    elevator routes have changed
Const NET_NEWSSUBSCRIPTIONCHANGE:Int	= 113				' ALL: sends Changes in subscription levels of news-agencies
Const NET_STATIONMAPCHANGE:Int			= 114				' ALL:    stations have changes (added ...)
Const NET_MOVIEAGENCYCHANGE:Int			= 115				' ALL: sends changes of programme in movieshop
Const NET_PROGRAMMECOLLECTIONCHANGE:Int = 116				' ALL:    programmecollection was changed (removed, sold...)
Const NET_PLAN_PROGRAMMECHANGE:Int		= 117				' ALL:    playerprogramme has changed (added, removed and so on)
Const NET_PLAN_ADCHANGE:Int				= 118				' ALL:    playerprogramme has changed (added, removed and so on)
Const NET_PLAN_NEWSCHANGE:Int			= 119				' ALL: sends Changes of news in the players newsstudio
Const NET_GAMESETTINGS:Int				= 120				' SERVER: send extra settings (random seed value etc.)

Const NET_DELETE:Int					= 0
Const NET_ADD:Int						= 1000

Const NET_CHANGE:Int					= 3000
Const NET_BUY:Int						= 4000
Const NET_SELL:Int						= 5000
Const NET_BID:Int						= 6000
Const NET_SWITCH:Int					= 7000
Const NET_TOSUITCASE:Int				= 8000
Const NET_FROMSUITCASE:Int				= 9000

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
			if Game.isPlayer(playerID) then Game.Players[playerID].Figure.ControlledByID = playerID

			'send others all important extra game data
			local gameData:TNetworkObject = TNetworkObject.Create( NET_GAMESETTINGS )
			gameData.setInt(1, Game.playerID)
			gameData.setInt(2, Game.GetRandomizerBase() )
			Network.BroadcastNetworkObject( gameData, NET_PACKET_RELIABLE )

		case NET_JOINRESPONSE
			if not Network.client.joined then return
			if Network.isServer then return
			'we are not the gamemaster and got a playerID
			local joined:int		= NetworkObject.getInt(1)
			local playerID:int		= NetworkObject.getInt(2)
			if Game.isPlayer(playerID)
				Game.playerID			= playerID
				Network.client.playerID = playerID
			endif

		case NET_GAMESETTINGS
			if not Network.client.joined then return
			if Network.isServer then return
			'we are not the gamemaster and got a playerID
			local hostPlayerID:int = NetworkObject.getInt(1)
			local randomSeedValue:int = NetworkObject.getInt(2)
			Game.SetRandomizerBase( randomSeedValue )

		case NET_STARTGAME					Game.networkgameready = 1
		case NET_GAMEREADY					NetworkHelper.ReceiveGameReady( networkObject )
		case NET_SENDGAMESTATE				NetworkHelper.ReceiveGameState( networkObject )
		case NET_PLAYERDETAILS				NetworkHelper.ReceivePlayerDetails( networkObject )
		case NET_FIGUREPOSITION				NetworkHelper.ReceiveFigurePosition( networkObject )

'untested

		case NET_CHATMESSAGE				NetworkHelper.ReceiveChatMessage( networkObject )

		'not working yet
		case NET_ELEVATORROUTECHANGE		Building.Elevator.Network_ReceiveRouteChange( networkObject )
		case NET_ELEVATORSYNCHRONIZE		Building.Elevator.Network_ReceiveSynchronize( networkObject )

		case NET_NEWSSUBSCRIPTIONCHANGE		NetworkHelper.ReceiveNewsSubscriptionChange( networkObject )
		case NET_MOVIEAGENCYCHANGE			NetworkHelper.ReceiveMovieAgencyChange( networkObject )
		case NET_PROGRAMMECOLLECTIONCHANGE	NetworkHelper.ReceiveProgrammeCollectionChange( networkObject )
		case NET_STATIONMAPCHANGE			NetworkHelper.ReceiveStationmapChange( networkObject )

		case NET_PLAN_PROGRAMMECHANGE		NetworkHelper.ReceivePlanProgrammeChange( networkObject )
		case NET_PLAN_NEWSCHANGE			NetworkHelper.ReceivePlanNewsChange( networkObject )
		case NET_PLAN_ADCHANGE				NetworkHelper.ReceivePlanAdChange( networkObject )

		default 							if networkObject.evType>=100 then print "client got unused event:" + networkObject.evType
	EndSelect

End Function

Function InfoChannelEventHandler(networkObject:TNetworkObject)
'	print "infochannel: got event: "+networkObject.evType
	if networkObject.evType = NET_ANNOUNCEGAME
		Local slotsUsed:Int			= networkObject.getInt(1)
		Local slotsMax:Int			= networkObject.getInt(2)
		local _hostIP:int			= networkObject.getInt(3)		'could differ from senderIP
		local _hostPort:int			= networkObject.getInt(4)		'differs from senderPort (info channel)
		Local _hostName:String		= networkObject.getString(5)
		Local gameTitle:String		= networkObject.getString(6)

		NetgameLobbyGamelist.addItem( new TGUIGameEntry.CreateSimple(DottedIP(_hostIP), _hostPort,_hostName,gameTitle,slotsUsed,slotsMax) )
	endif
End Function




Type TNetworkHelper
	field registeredEvents:int = FALSE

	Method Create:TNetworkHelper()
		'self.RegisterEventListeners()
		return self
	End Method

	Method RegisterEventListeners:int()
		if registeredEvents then return FALSE

		EventManager.registerListenerFunction( "programmeplan.SetNewsBlockSlot",	TNetworkHelper.onChangeNewsBlock )
'		EventManager.registerListenerFunction( "programmeplan.addNewsBlock",		TNetworkHelper.onChangeNewsBlock )
		EventManager.registerListenerFunction( "programmeplan.removeNewsBlock",		TNetworkHelper.onChangeNewsBlock )
		'someone adds a chatline
		EventManager.registerListenerFunction( "chat.onAddEntry",	TNetworkHelper.OnChatAddEntry )
		'changes to the player's stationmap
		EventManager.registerListenerFunction( "stationmap.removeProgramme",	TNetworkHelper.onChangeStationmap )
		EventManager.registerListenerFunction( "stationmap.addProgramme",		TNetworkHelper.onChangeStationmap )

		'changes to the player's programmecollection
		EventManager.registerListenerFunction( "programmecollection.removeProgramme",	TNetworkHelper.onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.addProgramme",		TNetworkHelper.onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.removeContract",	TNetworkHelper.onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.addContract",		TNetworkHelper.onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.removeProgrammeFromSuitcase",	TNetworkHelper.onChangeProgrammeCollection )
		EventManager.registerListenerFunction( "programmecollection.addProgrammeToSuitcase",		TNetworkHelper.onChangeProgrammeCollection )

		registeredEvents = true
	End Method

	'connect GUI with normal handling
	Function onChangeNewsBlock:int( triggerEvent:TEventBase )
		local newsBlock:TNewsBlock = TNewsBlock(triggerEvent._sender)
		if not newsBlock then return 0

		local blockOwner:int = newsBlock.owner

		'ignore ai player's events if no gameleader
		if Game.isAiPlayer(blockOwner) and not Game.isGameLeader() then return false
		'do not allow events from players for other players objects
		if blockOwner <> Game.playerID and not Game.isGameLeader() then return FALSE

		local action:int = -1
		if triggerEvent.isTrigger("programmeplan.SetNewsBlockSlot") then action = NET_CHANGE
'		if triggerEvent.isTrigger("programmeplan.addNewsBlock") then action = NET_ADD
		if triggerEvent.isTrigger("programmeplan.removeNewsBlock") then action = NET_DELETE
		if action = -1 then return FALSE

		NetworkHelper.SendPlanNewsChange(Game.playerID, newsBlock, action)
	End Function


	'connect GUI with normal handling
	Function onChangeStationmap:int( triggerEvent:TEventBase )
		local stationmap:TStationMap = TStationMap(triggerEvent._sender)
		if not stationmap then return FALSE

		local station:TStation = TStation( triggerEvent.getData().get("station") )
		if not station then return FALSE

		'ignore ai player's events if no gameleader
		if Game.isAiPlayer(station.owner) and not Game.isGameLeader() then return false
		'do not allow events from players for other players objects
		if station.owner <> Game.playerID and not Game.isGameLeader() then return FALSE

		local action:int = -1
		if triggerEvent.isTrigger("stationmap.addStation") then action = NET_ADD
		if triggerEvent.isTrigger("stationmap.removeStation") then action = NET_DELETE
		if action = -1 then return FALSE

		NetworkHelper.SendStationmapChange(station, action)
	End Function

	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		local programmeCollection:TPlayerProgrammeCollection = TPlayerProgrammeCollection(triggerEvent._sender)
		if not programmeCollection then return 0

		local owner:int = programmeCollection.parent.playerID
		'ignore ai player's events if no gameleader
		if Game.isAiPlayer(owner) and not Game.isGameLeader() then return false
		'do not allow events from players for other players objects
		if owner <> Game.playerID and not Game.isGameLeader() then return FALSE

		select triggerEvent.getTrigger()
			case "programmecollection.removeprogramme"
					local programme:TProgramme = TProgramme(triggerEvent.GetData().get("programme"))
					local sell:int = triggerEvent.GetData().getInt("sell",FALSE)
					if sell
						NetworkHelper.SendProgrammeCollectionProgrammeChange(owner, programme, NET_SELL)
					else
						NetworkHelper.SendProgrammeCollectionProgrammeChange(owner, programme, NET_DELETE)
					endif
			case "programmecollection.addprogramme"
					local programme:TProgramme = TProgramme(triggerEvent.GetData().get("programme"))
					local buy:int = triggerEvent.GetData().getInt("buy",FALSE)
					if buy
						NetworkHelper.SendProgrammeCollectionProgrammeChange(owner, programme, NET_BUY)
					else
						NetworkHelper.SendProgrammeCollectionProgrammeChange(owner, programme, NET_ADD)
					endif

			case "programmecollection.addprogrammetosuitcase"
					local programme:TProgramme = TProgramme(triggerEvent.GetData().get("programme"))
					NetworkHelper.SendProgrammeCollectionProgrammeChange(owner, programme, NET_TOSUITCASE)
			case "programmecollection.removeprogrammefromsuitcase"
					local programme:TProgramme = TProgramme(triggerEvent.GetData().get("programme"))
					NetworkHelper.SendProgrammeCollectionProgrammeChange(owner, programme, NET_FROMSUITCASE)

			case "programmecollection.removecontract"
					local contract:TContract = TContract(triggerEvent.GetData().get("contract"))
					NetworkHelper.SendProgrammeCollectionContractChange(owner, contract, NET_DELETE)
			case "programmecollection.addcontract"
					local contract:TContract = TContract(triggerEvent.GetData().get("contract"))
					NetworkHelper.SendProgrammeCollectionContractChange(owner, contract, NET_ADD)
		end select

		return FALSE
	End Function


	Method SendGameState()
		local obj:TNetworkObject = TNetworkObject.Create( NET_SENDGAMESTATE )
		obj.setInt(1, Game.playerID)
		obj.setFloat(2, game.speed)
		obj.setFloat(3, game.minutesOfDayGone) 'lastminutes not stored - so clients can catch up
		obj.setFloat(4, game.timeGone)
		Network.BroadcastNetworkObject( obj, not NET_PACKET_RELIABLE )
	End Method

	Method ReceiveGameState( obj:TNetworkObject )
		Local playerID:Int		= obj.getInt(1)
		'must be a player DIFFERENT to me
		if not Game.isPlayer(playerID) or playerID = game.playerID then return

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
		Game.timeGone			= obj.getFloat(4) + correction
	End Method

'checked
	Method SendPlayerDetails()
		'print "Send Player Details to all but me ("+TNetwork.dottedIP(host.ip)+")"
		'send packets indivual - no need to have multiple entities in one packet

		for local player:TPlayer = eachin TPlayer.list
			'it's me or i'm hosting and its an AI player
			if player.playerID = Network.client.playerID OR (Network.isServer and Player.isAI())
				'Print "[NET] send playerdetails of ME and IF I'm the host also from AI players"

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
		obj.SetFloat(	2, figure.rect.GetX() )	'position.x
		obj.SetFloat(	3, figure.rect.GetY() )	'...
		obj.SetFloat(	4, figure.target.x )
		obj.SetFloat(	5, figure.target.y )
		if figure.inRoom <> null 			then obj.setInt( 6, figure.inRoom.id)
		if figure.targetRoom <> null		then obj.setInt( 7, figure.targetRoom.id)
		if figure.fromRoom <> null 			then obj.setInt( 8, figure.fromRoom.id)
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
		local inRoomID:int			= obj.getInt(6, -1,TRUE)
		local targetRoomID:int		= obj.getInt(7, -1,TRUE)
		local fromRoomID:int		= obj.getInt(8, -1,TRUE)

		If not figure.IsInElevator()
			'only set X if wrong floor or x differs > 10 pixels
			if posY = targetY
				if Abs(posX - targetX) > 10 then figure.rect.position.setXY(posX,posY)
			else
				figure.rect.position.setXY(posX,posY)
			endif
		endif
		figure.target.setXY(targetX,targetY)

		If inRoomID <= 0 Then figure.inRoom = Null
		If figure.inroom <> Null
			If inRoomID > 0 and figure.inRoom.id <> inRoomID
				figure.inRoom = TRooms.GetRoom(inRoomID)
			EndIf
		EndIf

		figure.targetRoom = TRooms.GetRoom( targetRoomID )

		If fromRoomID <= 0 Then figure.fromRoom = Null
		If fromRoomID > 0 And figure.fromroom <> Null
			If figure.fromRoom.id <> fromRoomID then figure.fromRoom = TRooms.GetRoom(fromRoomID)
		EndIf
	End Method



'checked
	Method SendGameReady(playerID:Int, onlyTo:Int=-1)
		local obj:TNetworkObject = TNetworkObject.Create( NET_GAMEREADY )
		obj.setInt(1, playerID)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )

		Game.SetGamestate(GAMESTATE_STARTMULTIPLAYER)
		'self ready
		Game.Players[ playerID ].networkstate = 1

		for local i:int = 1 to 4
			'set AI players ready
			if Game.Players[ i ].figure.controlledByID = 0 then Game.Players[ i ].networkstate = 1
		Next

		if Network.isServer

			local allReady:int = 1
			for local otherclient:TNetworkclient = eachin Network.server.clients
				if not Game.Players[ otherclient.playerID ].networkstate then allReady = false
			Next
			if allReady
				'send game start
				Game.networkgameready = 1
				print "[NET] allReady so send game start to all others"
				Network.BroadcastNetworkObject( TNetworkObject.Create( NET_STARTGAME ), NET_PACKET_RELIABLE )
				return
			endif
		endif
	End Method

	Method ReceiveGameReady( obj:TNetworkObject )
print "[NET] ReceiveGameReady"
		local remotePlayerID:int = obj.getInt(1)
		Game.Players[ remotePlayerID ].networkstate = 1

		'all players have their start programme?
		local allReady:int = 1
		for local i:int = 1 to 4
			if Game.Players[i].ProgrammeCollection.movielist.count() < Game.startMovieAmount
				print "movie missing player("+i+") " + Game.Players[i].ProgrammeCollection.movielist.count() + " < " + Game.startMovieAmount
				allReady = false
				exit
			endif
			if Game.Players[i].ProgrammeCollection.serieslist.count() < Game.startSeriesAmount
				print "serie missing player("+i+") " + Game.Players[i].ProgrammeCollection.seriesList.count() + " < " + Game.startSeriesAmount
				allReady = false
				exit
			endif
			if Game.Players[i].ProgrammeCollection.contractlist.count() < Game.startAdAmount
				print "ad missing player("+i+") " + Game.Players[i].ProgrammeCollection.contractList.count() + " < " + Game.startAdAmount
				allReady = false
				exit
			endif
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
		'print "[NET] ReceiveNewsSubscriptionChange: player="+playerID+", genre="+genre+", level="+level
		Game.Players[ playerID ].setNewsAbonnement(genre, level, false)
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
			Case NET_BID
								For Local locObj:TAuctionProgrammeBlocks  = EachIn TAuctionProgrammeBlocks.List
									If not locObj.Programme then continue
									If locobj.Programme.id = ProgrammeID
										locObj.SetBid( PlayerID )
										print "[NET] MovieAgency auction bid "+methodtype+" obj:"+locobj.programme.title
										exit
									endif
								Next
			Default
								Print "SendMovieAgencyChange: no method mentioned"
		End Select
	End Method




	Method SendStationmapChange(station:TStation, action:int=0)
		local obj:TNetworkObject = TNetworkObject.Create( NET_STATIONMAPCHANGE )
		obj.SetInt(1, station.owner)
		obj.SetInt(2, action)
		obj.SetFloat(3, station.pos.x)
		obj.SetFloat(4, station.pos.y)
		obj.SetInt(5, station.radius)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveStationmapChange:int( obj:TNetworkObject)
		local playerID:int		= obj.getInt(1)
		local action:int		= obj.getInt(2)
		local pos:TPoint		= TPoint.Create( obj.getFloat(3), obj.getFloat(4) )
		local radius:int		= obj.getInt(5)
		if not Game.isPlayer(playerID) then return FALSE

		local station:TStation	= Game.Players[playerID].StationMap.getStation(pos.x, pos.y)

		'disable events - ignore it to avoid recursion
		TStationMap.fireEvents = FALSE

		select action
			case NET_ADD
					'create the station if not existing
					if not station then TStation.Create(pos,-1, radius, playerID)

					Game.Players[playerID].Stationmap.AddStation( station, FALSE )
					print "[NET] StationMap player "+playerID+" - add station "+station.pos.GetIntX()+","+station.pos.GetIntY()

					return TRUE
			case NET_DELETE
					if not station then return FALSE

					Game.Players[playerID].Stationmap.RemoveStation( station, FALSE)
					print "[NET] StationMap player "+playerID+" - removed station "+station.pos.GetIntX()+","+station.pos.GetIntY()
					return TRUE
		EndSelect
		TStationMap.fireEvents = TRUE
	End Method




	Method SendProgrammeCollectionProgrammeChange(playerID:int= -1, programme:TProgramme, action:int=0)
		self.SendProgrammeCollectionChange(playerID, 1, programme.id, action)
	End Method
	Method SendProgrammeCollectionContractChange(playerID:int= -1, contract:TContract, action:int=0)
		local id:int = contract.id
		'when adding a new contract, we do not send the contract id
		'itself (it is useless for others)
		'but the contractbase.id so the remote client can reconstruct
		if action = NET_ADD then id = contract.contractBase.id

		self.SendProgrammeCollectionChange(playerID, 2, id, action)
	End Method

	Method SendProgrammeCollectionChange(playerID:int= -1, objectType:int=0, objectID:int=0, action:int=0)
		local obj:TNetworkObject = TNetworkObject.Create( NET_PROGRAMMECOLLECTIONCHANGE )
		obj.SetInt(1, playerID)
		obj.SetInt(2, objectType)
		obj.SetInt(3, objectID)
		obj.SetInt(4, action)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveProgrammeCollectionChange:int( obj:TNetworkObject)
		local playerID:int		= obj.getInt(1)
		local objectType:int	= obj.getInt(2)
		local objectID:int		= obj.getInt(3)
		local action:int		= obj.getInt(4)
		if not Game.isPlayer(playerID) then return FALSE

		select objectType
			'Programme
			case 1
					Local programme:TProgramme = TProgramme.GetProgramme( objectID )
					if not programme then return FALSE

					'disable events - ignore it to avoid recursion
					TPlayerProgrammeCollection.fireEvents = FALSE

					select action
						case NET_ADD
								Game.Players[ playerID ].ProgrammeCollection.AddProgramme( programme, FALSE )
								print "[NET] PCollection"+playerID+" - add programme "+programme.title
						'remove from Collection (Archive - RemoveProgramme)
						case NET_DELETE
								Game.Players[ playerID ].ProgrammeCollection.RemoveProgramme( programme, FALSE )
								print "[NET] PCollection"+playerID+" - remove programme "+programme.title
						case NET_BUY
								Game.Players[ playerID ].ProgrammeCollection.AddProgramme( programme, TRUE )
								print "[NET] PCollection"+playerID+" - buy programme "+programme.title
						case NET_SELL
								Game.Players[ playerID ].ProgrammeCollection.RemoveProgramme( programme, TRUE )
								print "[NET] PCollection"+playerID+" - sell programme "+programme.title
						case NET_TOSUITCASE
								Game.Players[ playerID ].ProgrammeCollection.AddProgrammeToSuitcase( programme )
								print "[NET] PCollection"+playerID+" - to suitcase - programme "+programme.title
						case NET_FROMSUITCASE
								Game.Players[ playerID ].ProgrammeCollection.RemoveProgrammeFromSuitcase( programme )
								print "[NET] PCollection"+playerID+" - from suitcase - programme "+programme.title
					EndSelect

					TPlayerProgrammeCollection.fireEvents = TRUE
			'Contract
			case 2
					Local contractbase:TContractBase = TContractBase.Get( objectID )
					if not contractbase then return FALSE

					'disable events - ignore it to avoid recursion
					TPlayerProgrammeCollection.fireEvents = FALSE

					select action
						case NET_ADD
								Game.Players[ playerID ].ProgrammeCollection.AddContract( TContract.Create(contractBase) )
								print "[NET] PCollection"+playerID+" - add contract "+contractbase.title
						case NET_DELETE
								local contract:TContract = Game.Players[ playerID ].ProgrammeCollection.GetContractByBase( contractBase.id )
								if contract
									Game.Players[ playerID ].ProgrammeCollection.RemoveContract( contract )
									print "[NET] PCollection"+playerID+" - remove contract "+contractbase.title
								endif
					EndSelect

					TPlayerProgrammeCollection.fireEvents = TRUE
		EndSelect
	End Method




	'****************************
	' send/receive chat messages
	'****************************

	'the event to fetch new messages to send
	Function onChatAddEntry:int( triggerEvent:TEventBase )
		local senderID:int 		= triggerEvent.GetData().getInt("senderID",-1)
		local sendToChannels:int= triggerEvent.GetData().getInt("channels", 0)
		local chatMessage:string= triggerEvent.GetData().getString("text", "")
		local fromRemote:string	= triggerEvent.GetData().getInt("remoteSource",0)

		'only send if not already coming from the network
		if fromRemote = 0
			NetworkHelper.SendChatMessage(chatMessage, senderID, sendToChannels)
		else
			print "received chat event FROM NETWORK -> ignoring"
		endif
	End Function

	'send new messages
	Method SendChatMessage:int(ChatMessage:String = "", senderID:int=-1, sendToChannels:int=0)
		if senderID < 0 then return FALSE
		if sendToChannels = CHAT_CHANNEL_NONE then return FALSE
		'limit to game host sending for others (AI)
		if senderID <> Game.playerID and not Game.IsGameLeader() then return FALSE

		local obj:TNetworkObject = TNetworkObject.Create( NET_CHATMESSAGE)
		obj.setInt(1, Game.playerID)	'so we know the origin of the packet
		obj.setInt(2, senderID)			'author of the message
		obj.setString(3, ChatMessage)
		obj.setInt(4, sendToChannels)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE  )
	End Method

	'receive new messages
	Method ReceiveChatMessage:int( obj:TNetworkObject )
		Local originID:Int			= obj.getInt(1)
		Local senderID:Int			= obj.getInt(2)
		Local chatMessage:String	= obj.getString(3)
		Local sendToChannels:Int	= obj.getInt(4)

		'if we got back our own message, we do not want to emit
		'a new event - as we would then also will send/receive
		'it again and again and... This should not happen (but broadcasts...)
		if originID = Game.playerID
			print "ERROR: ReceiveChatMessage - got back my own message!!"
			return FALSE
		endif

		'emit an event, we received a chat message
		'- add a "remoteSource=1" so others may recognize it
		EventManager.triggerEvent( TEventSimple.Create( "chat.onAddEntry", TData.Create().AddNumber("senderID", senderID).AddNumber("channels", sendToChannels).AddString("text",chatMessage).AddNumber("remoteSource",1) , null ) )
	End Method





	Method SendStationChange(playerID:Int, station:TStation, newaudience:Int, add:int=1)
		local obj:TNetworkObject = TNetworkObject.Create( NET_STATIONMAPCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, add)
		obj.setFloat(3, station.Pos.x)
		obj.setFloat(4, station.Pos.y)
		obj.setInt(5, station.reach)
		obj.setInt(6, station.price)
		obj.setInt(7, newaudience)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method


	Method SendPlanNewsChange(senderPlayerID:Int, block:TNewsBlock, action:int=0)
		'actions: 0=add | 1=remove | 2=setslot/move

		local obj:TNetworkObject = TNetworkObject.Create( NET_PLAN_NEWSCHANGE )

		obj.setInt(1, senderPlayerID)
		obj.setInt(2, action)
		obj.setInt(3, block.id)
		obj.setInt(4, block.owner)
		obj.setInt(8, block.news.happenedtime)
		obj.setInt(9, block.news.id)
		obj.setInt(10, block.slot)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )

		print "[NET] SendPlanNewsChange: senderPlayer="+senderPlayerID+", blockowner="+block.owner+", block="+block.id+", news="+block.news.id+", action="+action
	End Method


	Method ReceivePlanNewsChange:int( obj:TNetworkObject )
		local sendingPlayerID:int = obj.getInt(1)

		if not Game.isPlayer(sendingPlayerID) then return NULL

		local action:int			= obj.getInt(2)
		local blockID:int			= obj.getInt(3)
		local blockOwnerID:int		= obj.getInt(4)
		local newsHappenedtime:int	= obj.getInt(8)
		local newsID:int			= obj.getInt(9)
		local slot:int				= obj.getInt(10)

		Local newsBlock:TNewsblock = Game.Players[ blockOwnerID ].ProgrammePlan.getNewsBlock(blockID)
		if not newsBlock or newsBlock.news.id <> newsID
			'do not automagically create new blocks for others...
			'all do it independently from each other (for intact randomizer base )
			return TRUE

			rem
				'that block does not exist yet, create it (is new block)
				'attention: normally a news will be send before but maybe it
				'did not receive yet (udp...) so we may have to create a news too
				local news:TNews = TNews.GetNews(newsID)
				if not news
					print "[NET] ReceivePlanNewsChange: NEWS DOES NOT EXIST: "+newsID
					return FALSE
				endif
				'set time when news really happened
				news.happenedtime = newsHappenedTime

				'create the block
				'-> would emit an addNewsBlock event - ignore it to avoid recursion
				TPlayerProgrammePlan.fireEvents = FALSE
				newsBlock = TNewsBlock.Create("", blockOwnerID, Game.Players[ blockOwnerID ].GetNewsAbonnementDelay(news.genre), news)
				TPlayerProgrammePlan.fireEvents = TRUE
			endrem
		endif

		'deactivate events for that moment - avoid recursion
		TPlayerProgrammePlan.fireEvents = FALSE

		'no need to react on "add" as this is automatically done if the block does not exist
		'if action=NET_ADD then Game.Players[ playerID ].ProgrammePlan.addNewsBlock(newsBlock)
		if action=NET_DELETE then Game.Players[ blockOwnerID ].ProgrammePlan.removeNewsBlock(newsBlock)
		if action=NET_CHANGE then Game.Players[ blockOwnerID ].ProgrammePlan.SetNewsBlockSlot(newsBlock, slot)

		TPlayerProgrammePlan.fireEvents = TRUE

		print "[NET] ReceivePlanNewsChange: sendingPlayer="+sendingPlayerID+", blockowner="+blockOwnerID+", block="+newsBlock.id+", news="+newsBlock.news.id+", action="+action
	End Method



'checked
	Method SendPlanAdChange(playerID:Int, block:TAdBlock, add:int=1)
		local obj:TNetworkObject = TNetworkObject.Create( NET_PLAN_ADCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, add)
		obj.setInt(3, block.id)
		obj.setFloat(4, block.rect.GetX())
		obj.setFloat(5, block.rect.GetY())
		obj.setFloat(6, block.StartPos.x)
		obj.setFloat(7, block.StartPos.y)
		obj.setInt(8, block.senddate)
		obj.setInt(9, block.sendtime)
		obj.setInt(10, block.contract.id)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceivePlanAdChange( obj:TNetworkObject )
		local playerID:int		= obj.getInt(1)
		if not Game.isPlayer(playerID) then return

		local add:int			= obj.getInt(2)
		local blockID:int		= obj.getInt(3)
		local pos:TPoint 	= TPoint.Create( obj.getFloat(4), obj.getFloat(5) )
		local startpos:TPoint= TPoint.Create( obj.getFloat(6), obj.getFloat(7) )
		local senddate:int		= obj.getInt(8)
		local sendtime:int		= obj.getInt(9)
		local contractID:int	= obj.getInt(10)

		Local Adblock:TAdBlock	= TAdBlock.getBlock( playerID, blockID )
		if not Adblock
			Local Contract:TContract = Game.Players[ playerID ].ProgrammeCollection.getContract( contractID )
			If not contract then return

			Adblock = TAdblock.CreateDragged( Contract,playerID )
			Adblock.dragged = 0
			'Print "NET: CREATED NEW Adblock: "+contract.Title
		endif

		Adblock.senddate			= senddate
		Adblock.sendtime			= sendtime
		AdBlock.rect.position		= pos
		AdBlock.StartPos			= startpos

		Game.Players[ playerID ].ProgrammePlan.RefreshAdPlan( senddate )
		If add
			Game.Players[ playerID ].ProgrammePlan.AddAdBlock( adblock )
			'Print "NET: ADDED adblock:"+Adblock.contract.Title+" to Player:"+playerID
		Else
			Game.Players[ playerID ].ProgrammePlan.RemoveAdBlock( adblock )
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
		obj.setFloat(4, block.rect.GetX())
		obj.setFloat(5, block.rect.GetY())
		obj.setFloat(6, block.StartPos.x)
		obj.setFloat(7, block.StartPos.y)
		obj.setInt(8, block.sendhour)
		obj.setInt(10, block.Programme.id)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceivePlanProgrammeChange( obj:TNetworkObject )
		local playerID:int		= obj.getInt(1)
		if not Game.isPlayer(playerID) then return

		local add:int			= obj.getInt(2)
		local blockID:int		= obj.getInt(3)
		local pos:TPoint 		= TPoint.Create( obj.getFloat(4), obj.getFloat(5) )
		local startpos:TPoint	= TPoint.Create( obj.getFloat(6), obj.getFloat(7) )

		local sendhour:int		= obj.getInt(8)
		'leave int 9 alone
		local programmeID:int	= obj.getInt(10)

		Local programmeblock:TProgrammeBlock = Game.Players[ playerID ].ProgrammePlan.GetProgrammeBlock( blockID )
		If not programmeblock
			Local Programme:TProgramme = TProgramme.GetProgramme( programmeID )
			If Programme = Null Then Print "programme not found";return
			programmeBlock			= TProgrammeBlock.CreateDragged( programme, playerID )
			ProgrammeBlock.dragged	= 0
			'Print "NET: ADDED NEW programme"
		endif

		programmeBlock.sendhour 		= sendhour
		programmeBlock.rect.position	= pos
		programmeBlock.StartPos			= startpos

		If add
			Game.Players[ playerID ].ProgrammePlan.AddProgrammeBlock( Programmeblock )
			Print "[NET] ReceivePlanProgrammeChange: ADDED programme:"+Programmeblock.programme.Title+" to Player:"+playerID
		Else
			Game.Players[ playerID ].ProgrammePlan.RemoveProgramme( Programmeblock.programme )
			Print "[NET] ReceivePlanProgrammeChange: REMOVED programme:"+Programmeblock.programme.Title+" from Player:"+playerID
		EndIf
	End Method

End Type
Global NetworkHelper:TNetworkHelper = new TNetworkHelper.Create()