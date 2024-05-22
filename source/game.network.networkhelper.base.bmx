SuperStrict
Import "basefunctions_network.bmx"

Type TNetworkHelperBase
	Global _instance:TNetworkHelperBase

	'first 100 ids reserved for base network events
	'Const NET_SETSLOT:Int					= 101	' SERVER: command from server to set to a given playerslot
	'Const NET_SLOTSET:Int					= 102	' ALL: 	  response to all, that IP uses slot X now

	Const NET_SENDGAMESTATE:Int				= 102	' ALL:    sends a ReadyFlag
	Const NET_GAMEREADY:Int					= 103	' ALL:    sends a ReadyFlag
	Const NET_PREPAREGAME:Int				= 104	' SERVER: sends a request to change gamestate
	Const NET_STARTGAME:Int					= 105	' SERVER: sends a StartFlag
	Const NET_CHATMESSAGE:Int				= 106	' ALL:    a sent chatmessage ;D
	Const NET_PLAYERDETAILS:Int				= 107	' ALL:    name, channelname...
	Const NET_FIGUREPOSITION:Int			= 108	' ALL:    x,y,room,target...
	Const NET_FIGURECHANGETARGET:Int		= 109	' ALL:    coordinates of the new target...
	Const NET_FIGURESETHASMASTERKEY:Int		= 110	' ALL:    adjustments to figure property "hasMasterKey"
	Const NET_ELEVATORSYNCHRONIZE:Int		= 111	' SERVER: synchronizing the elevator
	Const NET_ELEVATORROUTECHANGE:Int		= 112	' ALL:    elevator routes have changed
	Const NET_NEWSSUBSCRIPTIONCHANGE:Int	= 113	' ALL:	  sends Changes in subscription levels of news-agencies
	Const NET_STATIONMAPCHANGE:Int			= 114	' ALL:    stations have changes (added ...)
	Const NET_MOVIEAGENCYCHANGE:Int			= 115	' ALL:    sends changes of programme in movieshop
	Const NET_ROOMAGENCYCHANGE:Int			= 116	' ALL:    sends changes to room details (owner changes etc.)
	Const NET_PROGRAMMECOLLECTIONCHANGE:Int = 117	' ALL:    programmecollection was changed (removed, sold...)
	Const NET_PROGRAMMEPLAN_CHANGE:Int		= 118	' ALL:    playerprogramme has changed (added, removed, ...movies,ads ...)
	Const NET_PLAN_SETNEWS:Int				= 119
	Const NET_GAMESETTINGS:Int				= 121	' SERVER: send extra settings (random seed value etc.)

	Const NET_DELETE:Int					= 0
	Const NET_ADD:Int						= 1000

	Const NET_CHANGE:Int					= 3000
	Const NET_BUY:Int						= 4000
	Const NET_SELL:Int						= 5000
	Const NET_BID:Int						= 6000
	Const NET_SWITCH:Int					= 7000
	Const NET_TOSUITCASE:Int				= 8000
	Const NET_FROMSUITCASE:Int				= 9000


	Function GetInstance:TNetworkHelperBase()
		return Null
		'creating an instance not allowed when having "abstract" methods
'		if not _instance then _instance = new TNetworkHelperBase
'		return _instance
	End Function


	Method RegisterEventListeners:int() abstract


	Method SendGameState() abstract
	Method ReceiveGameState( obj:TNetworkObject ) abstract

	Method SendPlayerDetails() abstract
	Method ReceivePlayerDetails( obj:TNetworkObject ) abstract

	Method SendFigurePosition:int(figureGUID:string) abstract
	Method ReceiveFigurePosition( obj:TNetworkObject ) abstract

	Method SendFigureChangeTarget:int(figureGUID:string, x:int, y:int, forceChange:int) abstract
	Method ReceiveFigureChangeTarget( obj:TNetworkObject ) abstract

	Method SendPrepareGame() abstract

	Method SendStartGame() abstract

	Method SendGameReady(playerID:Int, onlyTo:Int=-1) abstract
	Method ReceiveGameReady( obj:TNetworkObject ) abstract

	Method ReceiveElevatorRouteChange( obj:TNetworkObject ) abstract
	Method ReceiveElevatorSynchronize( obj:TNetworkObject ) abstract

	Method SendNewsSubscriptionChange(playerID:Int, genre:int, level:int) abstract
	Method ReceiveNewsSubscriptionChange( obj:TNetworkObject ) abstract

	Method SendMovieAgencyChange(methodtype:int, playerID:Int, newID:Int=-1, slot:Int=-1, licenceGUID:string) abstract
	Method ReceiveMovieAgencyChange( obj:TNetworkObject ) abstract

	Method SendRoomAgencyChange(roomGUID:string, action:int=0, owner:int=0) abstract
	Method ReceiveRoomAgencyChange:int(obj:TNetworkObject) abstract

	Method SendStationmapChange(playerID:int, stationGUID:string, action:int=0) abstract
	Method ReceiveStationmapChange:int( obj:TNetworkObject) abstract

	Method SendProgrammeCollectionProgrammeLicenceChange(playerID:int= -1, licenceGUID:string, action:int=0) abstract
	Method SendProgrammeCollectionContractChange(playerID:int= -1, contractGUID:string, action:int=0) abstract

	Method SendProgrammeCollectionChange(playerID:int= -1, objectType:int=0, objectGUID:string, action:int=0) abstract
	Method ReceiveProgrammeCollectionChange:int( obj:TNetworkObject) abstract

	Method SendChatMessage:int(ChatMessage:String = "", senderID:int=-1, sendToChannels:int=0) abstract
	Method ReceiveChatMessage:int( obj:TNetworkObject ) abstract

	Method SendStationChange(playerID:Int, stationGUID:string, newaudience:Int, add:int=1) abstract

	Method SendPlanSetNews(senderPlayerID:Int, newsGUID:string, slot:int=0) abstract
	Method ReceivePlanSetNews:int( obj:TNetworkObject ) abstract

	Method SendProgrammePlanChange(playerID:Int, broadcastMaterialType:int, broadcastReferenceGUID:string, slotType:int=0, day:int, hour:int) abstract
	Method ReceiveProgrammePlanChange:int( obj:TNetworkObject ) abstract
   
End Type


Function GetNetworkHelper:TNetworkHelperBase()
	return TNetworkHelperBase.GetInstance()
End Function