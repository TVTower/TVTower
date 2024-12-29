SuperStrict
Import "game.network.networkhelper.base.bmx"
'Import "game.figure.bmx" 'via game.player.bmx
Import "game.stationmap.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.player.programmecollection.bmx"
Import "game.player.bmx"
Import "game.roomhandler.movieagency.bmx"
Import "game.roomagency.bmx"
Import "game.screen.menu.bmx"
Import "game.gameeventkeys.bmx"

'handles network events

Network.callbackServer = ServerEventHandler
Network.callbackClient = ClientEventHandler

'override instance
TNetworkHelperBase._instance = new TNetworkHelper


'=== EVENTS FOR SERVER ===
Function ServerEventHandler(server:TNetworkServer,client:TNetworkclient,id:Int, networkObject:TNetworkObject)
	Select networkObject.evType
		'player joined, send player data to all
		case NET_PLAYERJOINED
			GetNetworkHelper().SendPlayerDetails()
'		default
'			print "server got unused event:" + networkObject.evType
	EndSelect
End Function


'=== EVENTS FOR CLIENT ===
Function ClientEventHandler(client:TNetworkclient,id:Int, networkObject:TNetworkObject)
	local inGame:int = GetGameBase().IsGameState(TGameBase.STATE_RUNNING)

	Select networkObject.evType
		case NET_PLAYERJOINED
			local playerID:int = NetworkObject.getInt(1)
			local playerName:string	= NetworkObject.getString(2)
			'skip invalid players
			if not GetPlayer(playerID) then return

			'a package from a REMOTE player, not me
			if GetPlayerCollection().playerID <> playerID
				GetPlayer(playerID).SetRemoteHumanControlled(playerID)
				print "set playerID " + playerID +" as remote human"
			endif

			'send others all important extra game data
			local gameData:TNetworkObject = TNetworkObject.Create( TNetworkHelperBase.NET_GAMESETTINGS )
			gameData.setInt(1, GetPlayerCollection().playerID)
			gameData.setInt(2, GetGameBase().GetRandomizerBase() )
			'TODO: add game settings/rules
			Network.BroadcastNetworkObject( gameData, NET_PACKET_RELIABLE )


		case NET_JOINRESPONSE
			'=== ONLY CLIENTS ===
			if Network.isServer then return
			if not Network.client.joined then return

			'we are not the gamemaster and got a playerID
			local joined:int = NetworkObject.getInt(1)
			local playerID:int = NetworkObject.getInt(2)
			if GetPlayer(playerID)
				GetPlayerCollection().playerID = playerID
				Network.client.playerID = playerID
				GetPlayerCollection().Get(playerID).SetLocalHumanControlled()

				TLogger.Log("Network.ClientEventHandler", "got join response. Server requested to to set playerID to "+playerID, LOG_DEBUG | LOG_NETWORK)
			else
				TLogger.Log("Network.ClientEventHandler", "got join response. Server request contained invalid playerID ~q"+playerID+"~q", LOG_DEBUG | LOG_NETWORK)
			endif


		case TNetworkHelperBase.NET_GAMESETTINGS
			'=== ONLY CLIENTS ===
			if Network.isServer then return
			if not Network.client.joined then return
			
			local hostPlayerID:int = NetworkObject.getInt(1)
			local randomSeedValue:int = NetworkObject.getInt(2)
			GetGameBase().SetRandomizerBase( randomSeedValue )


		case TNetworkHelperBase.NET_PREPAREGAME
				print "NET: received preparegame"
				GetGameBase().SetGameState(TGameBase.STATE_PREPAREGAMESTART)

		case TNetworkHelperBase.NET_STARTGAME
				print "NET: received startgame"
				GetGameBase().startNetworkGame = True

		case TNetworkHelperBase.NET_GAMEREADY
				GetNetworkHelper().ReceiveGameReady( networkObject )

		case TNetworkHelperBase.NET_SENDGAMESTATE
				GetNetworkHelper().ReceiveGameState( networkObject )

		case TNetworkHelperBase.NET_PLAYERDETAILS
				GetNetworkHelper().ReceivePlayerDetails( networkObject )

		case TNetworkHelperBase.NET_FIGUREPOSITION
				if inGame then GetNetworkHelper().ReceiveFigurePosition( networkObject )

		case TNetworkHelperBase.NET_FIGURECHANGETARGET
				if inGame then GetNetworkHelper().ReceiveFigureChangeTarget( networkObject )

		case TNetworkHelperBase.NET_CHATMESSAGE
			GetNetworkHelper().ReceiveChatMessage( networkObject )

		'not working yet
		case TNetworkHelperBase.NET_ELEVATORROUTECHANGE
				if inGame then GetNetworkHelper().ReceiveElevatorRouteChange( networkObject )
		case TNetworkHelperBase.NET_ELEVATORSYNCHRONIZE
				if inGame then GetNetworkHelper().ReceiveElevatorSynchronize( networkObject )

		case TNetworkHelperBase.NET_NEWSSUBSCRIPTIONCHANGE
				if inGame then GetNetworkHelper().ReceiveNewsSubscriptionChange( networkObject )
		case TNetworkHelperBase.NET_MOVIEAGENCYCHANGE
				if inGame then GetNetworkHelper().ReceiveMovieAgencyChange( networkObject )
		case TNetworkHelperBase.NET_ROOMAGENCYCHANGE
				if inGame then GetNetworkHelper().ReceiveRoomAgencyChange( networkObject )
		case TNetworkHelperBase.NET_PROGRAMMECOLLECTIONCHANGE
				if inGame then GetNetworkHelper().ReceiveProgrammeCollectionChange( networkObject )
		case TNetworkHelperBase.NET_STATIONMAPCHANGE
				if inGame then GetNetworkHelper().ReceiveStationmapChange( networkObject )

		case TNetworkHelperBase.NET_PROGRAMMEPLAN_CHANGE
				if inGame then GetNetworkHelper().ReceiveProgrammePlanChange(networkObject)
		case TNetworkHelperBase.NET_PLAN_SETNEWS
				if inGame then GetNetworkHelper().ReceivePlanSetNews( networkObject )

		default
				if networkObject.evType>=100
					TLogger.Log("Network.ClientEventHandler", "got unused event: "+networkObject.evType+".", LOG_DEBUG | LOG_NETWORK)
				endif
	EndSelect

End Function




'=== EVENTS FROM INFO CHANNEL ===
'redirect a networkobject as event so others may connect easily
Function InfoChannelEventHandler(networkObject:TNetworkObject)
'	print "infochannel: got event: "+networkObject.evType
	if networkObject.evType = NET_ANNOUNCEGAME
		local evData:TData = new TData
		evData.Add("slotsUsed", networkObject.getInt(1))
		evData.Add("slotsMax", networkObject.getInt(2))
		evData.Add("hostIP", networkObject.getInt(3)) 		'could differ from senderIP
		evData.Add("hostPort", networkObject.getInt(4)) 		'differs from senderPort (info channel)
		evData.Add("hostName", networkObject.getString(5))
		evData.Add("gameTitle", networkObject.getString(6))

		TriggerBaseEvent(GameEventKeys.Network_InfoChannel_OnReceiveAnnounceGame, evData, null)
	endif
End Function




Type TNetworkHelper extends TNetworkHelperBase
	field registeredEvents:int = FALSE
	'disable if functions get called which emit events 
	Global listenToEvents:int = FALSE


	Method Create:TNetworkHelper()
		'self.RegisterEventListeners()
		return self
	End Method


	Method RegisterEventListeners:int()
		if registeredEvents then return FALSE

		EventManager.registerListenerFunction(GameEventKeys.ProgrammePlan_SetNews, onPlanSetNews)
		'someone adds a chatline
		EventManager.registerListenerFunction(GameEventKeys.Chat_OnAddEntry, OnChatAddEntry)
		'changes to the player's stationmap
		EventManager.registerListenerFunction(GameEventKeys.StationMap_RemoveStation, onChangeStationmap)
		EventManager.registerListenerFunction(GameEventKeys.StationMap_AddStation, onChangeStationmap)

		'changes to rooms (eg. owner changes)
		EventManager.registerListenerFunction(GameEventKeys.Room_OnBeginRental, onChangeRoomOwner)
		EventManager.registerListenerFunction(GameEventKeys.Room_OnCancelRental, onChangeRoomOwner)

		'news subscription
		EventManager.registerListenerFunction(GameEventKeys.Player_SetNewsAbonnement, onPlayerSetNewsAbonnement)

		'changes to the player's programmecollection
		EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProgrammeLicence, onChangeProgrammeCollection)
		EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddProgrammeLicence, onChangeProgrammeCollection)
		EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveAdContract, onChangeProgrammeCollection)
		EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddAdContract,	onChangeProgrammeCollection)
		EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProgrammeLicenceFromSuitcase, onChangeProgrammeCollection)
		EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddProgrammeLicenceToSuitcase, onChangeProgrammeCollection)

		'listen to events to refresh figure position 
		EventManager.registerListenerFunction(GameEventKeys.Figure_OnSyncTimer, onFigurePositionChanged)
		EventManager.registerListenerFunction(GameEventKeys.Figure_OnReachTarget, onFigurePositionChanged)
		EventManager.registerListenerFunction(GameEventKeys.Figure_SetInRoom, onFigurePositionChanged)
		'as soon as a figure changes its target (add it to the "route")
		EventManager.registerListenerFunction(GameEventKeys.Figure_OnChangeTarget, onFigureChangeTarget)
		EventManager.registerListenerFunction(GameEventKeys.Figure_OnSetHasMasterKey, onFigureSetHasMasterkey)

		'changes in movieagency
		EventManager.registerListenerFunction(GameEventKeys.ProgrammeLicenceAuction_SetBid, onChangeMovieAgency)

		registeredEvents = true
	End Method


	Function onChangeRoomOwner:int( triggerEvent:TEventBase )
		if not listenToEvents then return False

		'only react if game leader / server
		'if not GetGameBase().isGameLeader() then return False
		if not Network.isServer then return False

		local room:TRoom = TRoom(triggerEvent.GetSender())
		if not room then return False

		local action:int = -1
		if triggerEvent.GetEventKey() = GameEventKeys.Room_OnBeginRental then action = NET_BUY
		if triggerEvent.GetEventKey() = GameEventKeys.Room_OnCancelRental then action = NET_SELL
		if action = -1 then return FALSE

		local owner:int = triggerEvent.GetData().GetInt("owner", 0)
		GetNetworkHelper().SendRoomAgencyChange(room.GetGUID(), action, owner)
	End Function
	

	'connect GUI with normal handling
	Function onPlanSetNews:int( triggerEvent:TEventBase )
		local news:TNews = TNews(triggerEvent._sender)
		if not news then return 0

		local slot:int = triggerEvent.getData().getInt("slot",-1)
		if slot < 0 then return 0

		'ignore ai player's events if no gameleader
		if not GetGameBase().isGameLeader() and GetPlayer(news.owner).isLocalAi() then return false
		'do not allow events from players for other players objects
		if news.owner <> GetPlayerCollection().playerID and not GetGameBase().isGameLeader() then return FALSE

		GetNetworkHelper().SendPlanSetNews(GetPlayerCollection().playerID, news.GetGUID(), slot)
	End Function


	'connect GUI with normal handling
	Function onChangeStationmap:int( triggerEvent:TEventBase )
		local stationmap:TStationMap = TStationMap(triggerEvent._sender)
		if not stationmap then return FALSE

		local station:TStationBase = TStationBase( triggerEvent.getData().get("station") )
		if not station then return FALSE

		'ignore ai player's events if no gameleader
		if not GetGameBase().isGameLeader() and GetPlayer(station.owner).isLocalAi() then return false
		'do not allow events from players for other players objects
		if station.owner <> GetPlayerCollection().playerID and not GetGameBase().isGameLeader() then return FALSE

		local action:int = -1
		if triggerEvent.GetEventKey() = GameEventKeys.StationMap_AddStation then action = NET_ADD
		if triggerEvent.GetEventKey() = GameEventKeys.StationMap_RemoveStation then action = NET_DELETE
		if action = -1 then return FALSE

		GetNetworkHelper().SendStationmapChange(station.owner, station.GetGUID())
	End Function


	Function onFigurePositionChanged:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure then return FALSE

		GetNetworkHelper().SendFigurePosition(figure.GetGUID())
	End Function


	Function onFigureSetHasMasterkey:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure then return FALSE

		'send position contains masterkey information too
		GetNetworkHelper().SendFigurePosition(figure.GetGUID())
	End Function
		

	Function onFigureChangeTarget:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure then return FALSE

		'only send changes for figures WE control
		local playerID:int = GetPlayerBaseCollection().playerID
		'other player ?
		if figure.playerID > 0 and figure.playerID <> playerID then return False
		'other figures are controlled by GameLeader
		if figure.playerID = 0 and not GetGameBase().IsGameLeader() then return False
	

		local x:int = triggerEvent.GetData().GetInt("x", 0)
		local y:int = triggerEvent.GetData().GetInt("y", 0)
		local forceChange:int = triggerEvent.GetData().GetInt("forceChange", 0)
		GetNetworkHelper().SendFigureChangeTarget(figure.GetGUID(), x, y, forceChange)
	End Function


	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		local programmeCollection:TPlayerProgrammeCollection = TPlayerProgrammeCollection(triggerEvent._sender)
		if not programmeCollection then return 0

		local owner:int = programmeCollection.owner
		'ignore ai player's events if no gameleader
		if GetPlayer(owner).isLocalAi() and not GetGameBase().isGameLeader() then return false
		'do not allow events from players for other players objects
		if owner <> GetPlayerCollection().playerID and not GetGameBase().isGameLeader() then return FALSE

		select triggerEvent.GetEventKey()
			case GameEventKeys.ProgrammeCollection_RemoveProgrammeLicence
					local Licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().get("programmeLicence"))
					local sell:int = triggerEvent.GetData().getInt("sell",FALSE)
					if sell
						GetNetworkHelper().SendProgrammeCollectionProgrammeLicenceChange(owner, Licence.GetGUID(), NET_SELL)
					else
						GetNetworkHelper().SendProgrammeCollectionProgrammeLicenceChange(owner, Licence.GetGUID(), NET_DELETE)
					endif
			case GameEventKeys.ProgrammeCollection_AddProgrammeLicence
					local Licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().get("programmeLicence"))
					local buy:int = triggerEvent.GetData().getInt("buy",FALSE)
					if buy
						GetNetworkHelper().SendProgrammeCollectionProgrammeLicenceChange(owner, Licence.GetGUID(), NET_BUY)
					else
						GetNetworkHelper().SendProgrammeCollectionProgrammeLicenceChange(owner, Licence.GetGUID(), NET_ADD)
					endif

			case GameEventKeys.ProgrammeCollection_AddProgrammeLicenceToSuitcase
					local licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().get("programmeLicence"))
					GetNetworkHelper().SendProgrammeCollectionProgrammeLicenceChange(owner, licence.GetGUID(), NET_TOSUITCASE)
			case GameEventKeys.ProgrammeCollection_RemoveProgrammeLicenceFromSuitcase
					local licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().get("programmeLicence"))
					GetNetworkHelper().SendProgrammeCollectionProgrammeLicenceChange(owner, licence.GetGUID(), NET_FROMSUITCASE)

			case GameEventKeys.ProgrammeCollection_RemoveAdContract
					local contract:TAdContract = TAdContract(triggerEvent.GetData().get("adcontract"))
					GetNetworkHelper().SendProgrammeCollectionContractChange(owner, contract.GetGUID(), NET_DELETE)
			case GameEventKeys.ProgrammeCollection_AddAdContract
					local contract:TAdContract = TAdContract(triggerEvent.GetData().get("adcontract"))
					GetNetworkHelper().SendProgrammeCollectionContractChange(owner, contract.GetGUID(), NET_ADD)
		end select

		return FALSE
	End Function


	Function onPlayerSetNewsAbonnement:int( triggerEvent:TEventBase )
		local genre:int = triggerEvent.GetData().GetInt("genre")
		local level:int = triggerEvent.GetData().GetInt("level")
		local sendToNetwork:int = triggerEvent.GetData().GetInt("sendToNetwork")
		local playerID:int = TPlayerBase(triggerEvent.GetSender()).playerID

		GetNetworkHelper().SendNewsSubscriptionChange(playerID, genre, level)
	End Function
	

	Function onChangeMovieAgency:int( triggerEvent:TEventBase )
		Select triggerEvent.GetEventKey()
			case GameEventKeys.ProgrammeLicenceAuction_SetBid
				local licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().get("licence"))
				local playerID:int = triggerEvent.GetData().getInt("bestBidder", -1)
				GetNetworkHelper().SendMovieAgencyChange(NET_BID, playerID, -1, -1, licence.GetGUID())
		End Select
	End Function


	Method SendGameState()
		local obj:TNetworkObject = TNetworkObject.Create( NET_SENDGAMESTATE )
		obj.setInt(1, GetPlayerCollection().playerID)
		obj.setDouble(2, GetWorldTime()._timeFactor)
		obj.setInt(3, GetWorldTime()._paused)
		obj.setDouble(4, GetWorldTime()._timeGoneLastUpdate) '- so clients can catch up
		obj.setDouble(5, GetWorldTime()._timeGone)
		Network.BroadcastNetworkObject( obj, not NET_PACKET_RELIABLE )
	End Method


	Method ReceiveGameState( obj:TNetworkObject )
		Local playerID:Int = obj.getInt(1)
		'must be a player DIFFERENT to me
		if not GetPlayerBaseCollection().IsPlayer(playerID) or playerID = GetPlayerBaseCollection().playerID then return

		'60 upd per second = -> GetDeltaTimer().GetDeltaTime() => 16ms
		'ping in ms -> latency/2 -> 0.5*latency/16ms = "1,3 updates bis ping ankommt"
		'pro Update: zeiterhoehung von "GetGameBase().speed/10.0"
		'-> bereinigung: "0.5*latency/16" * "GetGameBase().speed/10.0"
		local correction:Long = 0.5 * Network.client.latency / GetDeltaTimer().GetDelta() * GetWorldTime()._timeFactor/10.0
		'we want it in s not in ms
		correction :/ 1000.0
		'print obj.getFloat(3) + "  + "+correction

		GetWorldTime()._timeFactor = obj.getDouble(2)
		GetWorldTime()._paused = obj.getInt(3)
		GetWorldTime().SetTimeGone(Long(obj.getDouble(5) + correction))
	End Method

'checked
	Method SendPlayerDetails()
		'print "Send Player Details to all but me ("+TNetwork.dottedIP(host.ip)+")"
		'send packets indivual - no need to have multiple entities in one packet

		for local player:TPlayer = EachIn GetPlayerCollection().players
			'it's me or i'm hosting and its an AI player
			if player.playerID = Network.client.playerID OR (Network.isServer and Player.isLocalAI())
				'Print "[NET] send playerdetails of ME and IF I'm the host also from AI players"

				local obj:TNetworkObject = TNetworkObject.Create( NET_PLAYERDETAILS )
				obj.SetInt(	1, player.playerID )
				obj.SetString( 2, Player.name )
				obj.SetString( 3, Player.channelname )
				obj.SetInt(	4, Player.color.toInt() )
				obj.SetInt(	5, Player.figurebase )
				obj.SetInt(	6, Player.playerType )
				obj.SetInt(	7, Player.playerControlledByID )
				
				Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
			EndIf
		Next
	End Method

	Method ReceivePlayerDetails( obj:TNetworkObject )
		Local playerID:Int = obj.getInt(1)
		local player:TPlayer = GetPlayer(playerID)
		if not player then return

		Local name:string = obj.getString(2)
		Local channelName:string = obj.getString(3)
		Local color:int	= obj.getInt(4)
		Local figureBase:int = obj.getInt(5)
		Local playerType:int = obj.getInt(6)
		Local playerControlledByID:int = obj.getInt(7)

		'=== ADJUST PLAYER TYPE ===
		'do not adjust data for our very own player
		if playerID <> GetPlayerCollection().playerID
			Select playerType
				case TPlayer.PLAYERTYPE_REMOTE_AI
					'if the player is AI, check if we control it
					if playerControlledByID = GetPlayerCollection().playerID
						player.SetLocalAIControlled()
					endif
				case TPlayer.PLAYERTYPE_LOCAL_AI
					'this means, it is local to the game leader
					player.SetRemoteAIControlled(playerControlledByID)
				case TPlayer.PLAYERTYPE_LOCAL_HUMAN
					'this means, it is local to the game leader
					player.SetRemoteHumanControlled(playerControlledByID)
				case TPlayer.PLAYERTYPE_REMOTE_HUMAN
					'if the player is AI, check if we control it
					if playerControlledByID = GetPlayerCollection().playerID
						player.SetLocalHumanControlled()
					endif
			End Select
		endif
		
		'=== REFRESH PLAYER DATA ===
		'only refresh for players we do not control
		If playerControlledByID <> GetPlayerCollection().playerID 
			If figureBase <> player.figurebase
				player.UpdateFigureBase(figureBase)
			endif
			
			If player.color.toInt() <> color
				player.color.fromInt(color)
				player.RecolorFigure()
			EndIf

			player.name = name
			player.channelname = channelName
			local screen:TScreen_GameSettings = TScreen_GameSettings(ScreenCollection.GetScreen("GameSettings"))
			screen.guiPlayerNames[ playerID-1 ].value = name
			screen.guiChannelNames[ playerID-1 ].value = channelName
			player.figure.playerID = playerID
		EndIf
	End Method



'checked
	Method SendFigurePosition:int(figureGUID:string)
		local figure:TFigureBase = GetFigureBaseCollection().GetByGUID(figureGUID)
		if not figure then return False
		
		'"not-player" figures can only be send from Master
		if figure.playerID and not Network.isServer then return Null

		local obj:TNetworkObject = TNetworkObject.Create( NET_FIGUREPOSITION )
		obj.SetString( 1, figureGUID )
		obj.SetFloat( 2, figure.area.GetX() )	'position.x
		obj.SetFloat( 3, figure.area.GetY() )	'...
		obj.setInt( 4, figure.GetInRoomID())
		obj.setInt( 5, figure.GetUsedDoorID())
		obj.setInt( 6, figure.hasMasterKey)
		Network.BroadcastNetworkObject( obj )
	End Method
	

	Method ReceiveFigurePosition( obj:TNetworkObject )
		Local figureGUID:String = obj.getString(1)
		local figure:TFigure = GetFigureCollection().GetByGUID( figureGUID )
		if not figure then return

		local posX:Float = obj.getFloat(2)
		local posY:Float = obj.getFloat(3)
		local inRoomID:int = obj.getInt( 4, -1, TRUE )
		local usedDoorID:int = obj.getInt( 5, -1, TRUE )

		figure.hasMasterKey = obj.getInt( 6, false )

		If inRoomID <= 0 Then figure.inRoom = Null
		If figure.inRoom
			If inRoomID > 0 and figure.inRoom.id <> inRoomID
				figure.inRoom = GetRoomCollection().Get(inRoomID)
			EndIf
		EndIf
		figure.usedDoor = GetRoomDoorBaseCollection().Get( usedDoorID )


		if figure.GetTarget()
			If not figure.IsInElevator()
				local targetPos:SVec2I = figure.GetTargetMoveToPosition()
				'only set X if wrong floor or x differs > 10 pixels
				if posY = targetPos.x
					if Abs(posX - targetPos.x) > 10 then figure.area.SetXY(posX, posY)
				else
					figure.area.SetXY(posX, posY)
				endif
			endif
		endif
		
	End Method


	Method SendFigureChangeTarget:int(figureGUID:String, x:int, y:int, forceChange:int)
		local figure:TFigureBase = GetFigureBaseCollection().GetByGUID(figureGUID)
		if not figure then return False

		local obj:TNetworkObject = TNetworkObject.Create( NET_FIGURECHANGETARGET )
		obj.SetString( 1, figureGUID )

		'no target? send something so remote deletes potential targets too
		if not figure.GetTarget()
			obj.SetInt( 2,  0 )
			obj.SetInt( 3, -1 )
			obj.SetInt( 4, -1 )
			obj.SetInt( 5,  0 )
		else
			obj.SetInt( 2, 1 )
			obj.SetInt( 3, x )
			obj.SetInt( 4, y )
			obj.SetInt( 5, forceChange )
		endif
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveFigureChangeTarget( obj:TNetworkObject )
		Local figureGUID:String = obj.getString(1)
		local figure:TFigure = GetFigureCollection().GetByGUID( figureGUID )
		if not figure then return

		local add:Int = obj.getInt( 2, 0 )
		local posX:Int = obj.getInt( 3, -1 )
		local posY:Int = obj.getInt( 4, -1 )
		local forceChange:Int = obj.getInt( 5,  0 )
		if add
			figure._changeTarget(posX, posY, forceChange)
		else
			figure.ClearTargets()
		endif
	End Method
	

	Method SendPrepareGame()
		print "[NET] inform all to switch gamestate"
		Network.BroadcastNetworkObject( TNetworkObject.Create( NET_PREPAREGAME ), NET_PACKET_RELIABLE )
	End Method
	

	Method SendStartGame()
		local allReady:int = 1
		for local otherclient:TNetworkclient = eachin Network.server.clients
			if not GetPlayerCollection().Get(otherclient.playerID).networkstate then allReady = false
		Next
		if allReady
			'send game start - maybe wait for "receive" too
			GetGameBase().startNetworkGame = 1
			print "[NET] allReady so send game start to all others"
			Network.BroadcastNetworkObject( TNetworkObject.Create( NET_STARTGAME ), NET_PACKET_RELIABLE )
			return
		endif
	End Method

'checked
	'ask players if they are ready to start a game
	Method SendGameReady(playerID:Int, onlyTo:Int=-1)
		local obj:TNetworkObject = TNetworkObject.Create( NET_GAMEREADY )
		obj.setInt(1, playerID)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )

		'self ready
		GetPlayerCollection().Get(playerID).networkstate = 1

		for local i:int = 1 to 4
			'set AI players ready
			if GetPlayerCollection().IsLocalAi(i) then GetPlayerCollection().Get(i).networkstate = 1
		Next

		if Network.isServer then SendStartGame()
	End Method

	'server asks me if i am ready to start the game
	Method ReceiveGameReady( obj:TNetworkObject )
		print "[NET] ReceiveGameReady"

		'set remote player as ready
		local remotePlayerID:int = obj.getInt(1)
		GetPlayerCollection().Get(remotePlayerID).networkstate = 1

		if not GetGameBase().IsGameState(TGameBase.STATE_RUNNING)
			SendGameReady( GetPlayerCollection().playerID, 0 )
		endif
	End Method


	Method ReceiveElevatorRouteChange( obj:TNetworkObject )
		print "IMPLEMENT ReceiveElevatorRouteChange()"
	End Method


	Method ReceiveElevatorSynchronize( obj:TNetworkObject )
		print "IMPLEMENT ReceiveElevatorSynchronize()"
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
		Local playerID:Int = obj.getInt(1)
		local player:TPlayer = GetPlayerCollection().Get( playerID )
		if player = null then return

		Local genre:Int	= obj.getInt(2)
		Local level:Int	= obj.getInt(3)
		'print "[NET] ReceiveNewsSubscriptionChange: player="+playerID+", genre="+genre+", level="+level
		player.setNewsAbonnement(genre, level, false)
	End Method




	Method SendMovieAgencyChange(methodtype:int, playerID:Int, newID:Int=-1, slot:Int=-1, licenceGUID:string)
		local obj:TNetworkObject = TNetworkObject.Create( NET_MOVIEAGENCYCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, methodtype)
		obj.setInt(3, newid)
		obj.setInt(4, slot)
		obj.setString(5, licenceGUID)
		Network.BroadcastNetworkObject( obj,  NET_PACKET_RELIABLE )
	End Method

	Method ReceiveMovieAgencyChange( obj:TNetworkObject )
		Local playerID:Int = obj.getInt(1)
		Local methodtype:Int = obj.getInt(2)
		Local newid:Int = obj.getInt(3)
		Local slot:Int = obj.getInt(4)
		Local licenceGUID:String = obj.getString(5)

		Local tmpID:Int = -1
		Local oldX:Int, oldY:Int
		Select methodtype
			Case NET_BID
					local obj:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks.GetByLicence(null, licenceGUID)
					if obj
						obj.SetBid(playerID)
						print "[NET] MovieAgency auction bid "+methodtype+" obj:"+obj.licence.GetTitle()
					else
						print "[NET] ERROR: ReceiveMovieAgencyChange - licence not found."
					endif
			Default
					Print "SendMovieAgencyChange: no method mentioned"
		End Select
	End Method



	Method SendRoomAgencyChange(roomGUID:string, action:int=0, owner:int=0)
		local obj:TNetworkObject = TNetworkObject.Create( NET_ROOMAGENCYCHANGE )
		obj.SetString(1, roomGUID)
		obj.SetInt(2, action)
		obj.SetInt(3, owner)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveRoomAgencyChange:int(obj:TNetworkObject)
		local roomGUID:string = obj.getString(1)
		local action:int = obj.getInt(2)
		local newOwner:int = obj.getInt(3)

		local room:TRoom = GetRoomCollection().GetByGUID( TLowerString.Create(roomGUID) )
		if not room then return False

		'disable events - ignore it to avoid recursion
		listenToEvents = False

		select action
			case NET_BUY
					GetRoomAgency().BeginRoomRental(room, newOwner)
					print "[NET] RoomAgency: player "+newOwner+" rents room "+ room.GetName()

					return TRUE
			case NET_SELL
					local oldOwner:int = room.owner
					GetRoomAgency().CancelRoomRental(room, oldOwner)
					print "[NET] RoomAgency: player "+oldOwner+" stopped renting room "+room.GetName()
					return TRUE
		EndSelect

		listenToEvents = TRUE
	End Method


	Method SendStationmapChange(playerID:int, stationGUID:string, action:int=0)
		Local map:TStationMap = GetStationMap(playerID)
		If Not map Then Return
		local station:TStationBase = map.GetStation(stationGUID)
		if not station then return

		local obj:TNetworkObject = TNetworkObject.Create( NET_STATIONMAPCHANGE )
		obj.SetInt(1, playerID)
		obj.SetInt(2, action)
		obj.SetInt(3, station.stationType)
		obj.SetInt(4, station.x)
		obj.SetInt(5, station.y)
		if TStationAntenna(station)
			obj.SetInt(6, TStationAntenna(station).radius)
		else
			obj.SetInt(6, 0)
		endif
		obj.SetString(7, station.GetGUID())
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	'TODO: overhaul of the whole buy-thing
	Method ReceiveStationmapChange:int( obj:TNetworkObject)
		local playerID:int = obj.getInt(1)
		local action:int = obj.getInt(2)
		local stationType:int = obj.getInt(3)
		local posX:Int = obj.getInt(4)
		local posY:Int = obj.getInt(5)
		local radius:int = obj.getInt(6)
		local stationGUID:string = obj.getString(7)
		if not GetPlayerCollection().IsPlayer(playerID) then return FALSE

		Local map:TStationMap = GetStationMap(playerID)
		If Not map Then Return False

		local station:TStationBase = map.getStation(stationGUID)
		if not station then return False

		'disable events - ignore it to avoid recursion
		TStationMap.fireEvents = FALSE

		select action
			case NET_ADD
					'create the station if not existing
					if not station
'						Select stationType
'							case TVTStationType.ANTENNA
'								station = new TStation.Init(pos,-1, radius, playerID)
'							case TVTStationType.ANTENNA
'								station = new TStation.Init(pos,-1, radius, playerID)
'							default 'case TVTStationType.ANTENNA
								station = new TStationAntenna.Init(New SVec2I(posX, posY), playerID)
								TStationAntenna(station).radius = radius
'						End Select
					endif

					station.SetGUID(stationGUID)


					Local map:TStationMap = GetStationMap(playerID)
					If Not map Then Return False

					map.AddStation( station, FALSE )
					print "[NET] StationMap player "+playerID+" - add station "+station.x+","+station.y

					return TRUE
			case NET_DELETE
					if not station then return FALSE

					Local map:TStationMap = GetStationMap(playerID)
					If Not map Then Return False

					map.RemoveStation( station, FALSE )
					print "[NET] StationMap player "+playerID+" - removed station "+station.x+","+station.y
					return TRUE
		EndSelect
		TStationMap.fireEvents = TRUE
	End Method


	Method SendProgrammeCollectionProgrammeLicenceChange(playerID:int= -1, licenceGUID:string, action:int=0)
		self.SendProgrammeCollectionChange(playerID, 1, licenceGUID, action)
	End Method
	
	Method SendProgrammeCollectionContractChange(playerID:int= -1, contractGUID:string, action:int=0)
		'when adding a new contract, we do not send the contract id
		'itself (it is useless for others)
		'but the contractbase.id so the remote client can reconstruct
		'if action = NET_ADD then
		local contract:TAdContract = GetAdContractCollection().GetByGUID(contractGUID)
		local contractBaseGUID:string = contract.base.GetGUID()

		self.SendProgrammeCollectionChange(playerID, 2, contractBaseGUID, action)
	End Method

	Method SendProgrammeCollectionChange(playerID:int= -1, objectType:int=0, objectGUID:string, action:int=0)
		local obj:TNetworkObject = TNetworkObject.Create( NET_PROGRAMMECOLLECTIONCHANGE )
		obj.SetInt(1, playerID)
		obj.SetInt(2, objectType)
		obj.SetString(3, objectGUID)
		obj.SetInt(4, action)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method

	Method ReceiveProgrammeCollectionChange:int( obj:TNetworkObject)
		local playerID:int = obj.getInt(1)
		local objectType:int = obj.getInt(2)
		local objectGUID:string = obj.getString(3)
		local action:int = obj.getInt(4)
		local player:TPlayerBase = GetPlayerBase(playerID)
		if not player then return FALSE

		select objectType
			'ProgrammeLicence
			case 1
				Local licence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(objectGUID)
				if not licence then return FALSE

				'disable events - ignore it to avoid recursion
				TPlayerProgrammeCollection.fireEvents = FALSE

				Select action
					case NET_ADD
							GetPlayerProgrammeCollection(playerID).AddProgrammeLicence(licence, FALSE)
							print "[NET] PCollection"+playerID+" - add programme licence " + licence.GetTitle()
					'remove from Collection (Archive - RemoveProgrammeLicence)
					case NET_DELETE
							GetPlayerProgrammeCollection(playerID).RemoveProgrammeLicence(licence, FALSE)
							print "[NET] PCollection"+playerID+" - remove programme licence " + licence.GetTitle()
					case NET_BUY
							GetPlayerProgrammeCollection(playerID).AddProgrammeLicence(licence, TRUE)
							print "[NET] PCollection"+playerID+" - buy programme licence " + licence.GetTitle()
					case NET_SELL
							GetPlayerProgrammeCollection(playerID).RemoveProgrammeLicence(licence, TRUE)
							print "[NET] PCollection"+playerID+" - sell programme licence " + licence.GetTitle()
					case NET_TOSUITCASE
							GetPlayerProgrammeCollection(playerID).AddProgrammeLicenceToSuitcase(licence)
							print "[NET] PCollection"+playerID+" - to suitcase - programme " + licence.GetTitle()
					case NET_FROMSUITCASE
							GetPlayerProgrammeCollection(playerID).RemoveProgrammeLicenceFromSuitcase(licence)
							print "[NET] PCollection"+playerID+" - from suitcase - programme licence " + licence.GetTitle()
				EndSelect

					TPlayerProgrammeCollection.fireEvents = TRUE
			'Contract
			case 2
					'we received a contract base GUID, not the contract!
					Local contractbase:TAdContractBase = GetAdContractBaseCollection().GetByGUID( objectGUID )
					if not contractbase then return FALSE

					'disable events - ignore it to avoid recursion
					TPlayerProgrammeCollection.fireEvents = FALSE

					select action
						case NET_ADD
								GetPlayerProgrammeCollection(playerID).AddAdContract( new TAdContract.Create(contractBase) )
								print "[NET] PCollection"+playerID+" - add contract "+contractbase.GetTitle()
						case NET_DELETE
								local contract:TAdContract = GetPlayerProgrammeCollection(playerID).GetAdContractByBase( contractBase.id )
								if contract
									GetPlayerProgrammeCollection(playerID).RemoveAdContract( contract )
									print "[NET] PCollection"+playerID+" - remove contract "+contract.GetTitle()
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
			GetNetworkHelper().SendChatMessage(chatMessage, senderID, sendToChannels)
		else
			print "received chat event FROM NETWORK -> ignoring"
		endif
	End Function

	'send new messages
	Method SendChatMessage:int(ChatMessage:String = "", senderID:int=-1, sendToChannels:int=0)
		if senderID < 0 then return FALSE
		if sendToChannels = CHAT_CHANNEL_NONE then return FALSE
		'limit to game host sending for others (AI)
		if senderID <> GetPlayerCollection().playerID and not GetGameBase().IsGameLeader() then return FALSE

		local obj:TNetworkObject = TNetworkObject.Create( NET_CHATMESSAGE)
		obj.setInt(1, GetPlayerCollection().playerID)	'so we know the origin of the packet
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
		if originID = GetPlayerCollection().playerID
			print "ERROR: ReceiveChatMessage - got back my own message!!"
			return FALSE
		endif

		'emit an event, we received a chat message
		'- add a "remoteSource=1" so others may recognize it
		TriggerBaseEvent(GameEventKeys.Chat_OnAddEntry, new TData.Add("senderID", senderID).Add("channels", sendToChannels).Add("text",chatMessage).Add("remoteSource",1) , null )
	End Method





	Method SendStationChange(playerID:Int, stationGUID:string, newaudience:Int, add:int=1)
		Local map:TStationMap = GetStationMap(playerID)
		If Not map Then Return

		local station:TStationBase = map.GetStation(stationGUID)
		if not station
			print "SendStationChange failed, no station given"
			return
		endif
		
		local obj:TNetworkObject = TNetworkObject.Create( NET_STATIONMAPCHANGE )
		obj.setInt(1, playerID)
		obj.setInt(2, add)
		obj.setInt(3, station.stationType)
		obj.setInt(4, station.x)
		obj.setInt(5, station.y)
		if TStationAntenna(station)
			obj.setInt(6, TStationAntenna(station).radius)
		else
			obj.setInt(6, 0)
		endif
		obj.setString(7, station.GetGUID())
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )
	End Method


	Method SendPlanSetNews(senderPlayerID:Int, newsGUID:string, slot:int=0)
		local ppp:TPlayerProgrammePlan = GetPlayerProgrammePlan(senderPlayerID)
		if not ppp then return

		local news:TBroadcastMaterial = ppp.GetNews(newsGUID)
		if not news then return
	
		local obj:TNetworkObject = TNetworkObject.Create( NET_PLAN_SETNEWS )

		obj.setInt(1, senderPlayerID)
		obj.setString(2, newsGUID)
		obj.setInt(3, news.owner)
		obj.setInt(4, slot)
		Network.BroadcastNetworkObject( obj, NET_PACKET_RELIABLE )

		print "[NET] SendPlanSetNews: senderPlayer="+senderPlayerID+", newsOwner="+news.owner+", news="+news.GetGUID()+" slot="+slot
	End Method

	Method ReceivePlanSetNews:int( obj:TNetworkObject )
		local sendingPlayerID:int = obj.getInt(1)

		if not GetPlayerCollection().IsPlayer(sendingPlayerID) then return NULL

		local blockID:int = obj.getInt(2)
		local blockOwnerID:int = obj.getInt(3)
		local slot:int = obj.getInt(4)
		local owningPlayer:TPlayer = GetPlayerCollection().Get(blockOwnerID)
		if not owningPlayer then return Null

		Local news:TNews = owningPlayer.GetProgrammeCollection().getNewsAtIndex(blockID)
		'do not automagically create new blocks for others...
		'all do it independently from each other (for intact randomizer base )
		if not news then return TRUE

		'deactivate events for that moment - avoid recursion
		TPlayerProgrammePlan.fireEvents = FALSE

		owningPlayer.GetProgrammePlan().SetNews(news, slot)

		TPlayerProgrammePlan.fireEvents = TRUE

		print "[NET] ReceivePlanSetNewsSlot: sendingPlayer="+sendingPlayerID+", blockowner="+blockOwnerID+", block="+news.id+" slot="+slot
	End Method



'checked
	Method SendProgrammePlanChange(playerID:Int, broadcastMaterialType:int, broadcastReferenceGUID:string, slotType:int=0, day:int, hour:int)
		local obj:TNetworkObject = TNetworkObject.Create(NET_PROGRAMMEPLAN_CHANGE)
		obj.setInt(1, playerID)
		obj.setInt(2, broadcastMaterialType)
		if obj
			obj.setString(3, broadcastReferenceGUID)
		else
			obj.setString(3, "")
		endif
		obj.setInt(4, slotType)
		obj.setInt(5, day)
		obj.setInt(6, hour)
		Network.BroadcastNetworkObject(obj, NET_PACKET_RELIABLE)
	End Method

	Method ReceiveProgrammePlanChange:int( obj:TNetworkObject )
		if not GetPlayerCollection().IsPlayer(obj.getInt(1)) then return FALSE

		local playerID:int = obj.getInt(1)
		local broadcastMaterialType:int	= obj.getInt(2)
		local broadcastReferenceGUID:string = obj.getString(3)
		local slotType:int = obj.getInt(4)
		local day:int = obj.getInt(5)
		local hour:int = obj.getInt(6)

		'delete at given spot
		if broadcastReferenceGUID = ""
			return (null<> GetPlayerProgrammePlan(playerID).RemoveObject(null, slotType, day, hour))
		endif

		'add to given datetime
		local broadcastMaterial:TBroadcastMaterial
		Select broadcastMaterialType
			case TVTBroadcastMaterialType.PROGRAMME
				broadcastMaterial = TProgramme.Create(GetPlayerProgrammeCollection(playerID).GetProgrammeLicenceByGUID(broadcastReferenceGUID))
			case TVTBroadcastMaterialType.ADVERTISEMENT
				broadcastMaterial = new TAdvertisement.Create(GetPlayerProgrammeCollection(playerID).GetAdContractByGUID(broadcastReferenceGUID))
		End Select

		If not broadcastMaterial
			print "[NET] ReceiveProgrammePlanChange: cannot create object for referenced ~q"+broadcastReferenceGUID+"~q."
			return FALSE
		endif

		GetPlayerProgrammePlan(playerID).AddObject(broadcastMaterial, slotType, day, hour)
	End Method
End Type
