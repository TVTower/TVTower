SuperStrict

Import pub.enet
Import Brl.Map
Import Brl.Stream
Import Brl.Retro
'for direct udp messages
Import "external/bnetex/bnetex.bmx"
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.logger.bmx"


Const NET_PACKET_RELIABLE:int = 1
Const NET_PACKET_HEADER:int	  = 1317

'=== MESSAGE STATES ===
Const NET_STATE_ALL:int      = 0
Const NET_STATE_CREATED:int  = 1
Const NET_STATE_MODIFIED:int = 2
Const NET_STATE_CLOSED:int   = 3
Const NET_STATE_SYNCED:int   = 4
Const NET_STATE_MESSAGE:int  = 5
Const NET_STATE_FOREVER:int  = 6
Const NET_STATE_ZOMBIE:int   =-1

'=== PACKET SLOT TYPES ===
Const NET_TYPE_STRING:int  = 1
Const NET_TYPE_INT:int     = 2
Const NET_TYPE_UINT8:int   = 3
Const NET_TYPE_UINT16:int  = 4
Const NET_TYPE_FLOAT16:int = 5
Const NET_TYPE_FLOAT32:int = 6

'=== NETWORK PACKET TYPES ===
Const NET_CONNECT:Int           = 1      ' ALL: Connect Attempt
Const NET_DISCONNECT:Int        = 2      ' ALL: DISCONNECT
Const NET_PINGREQUEST:Int       = 3      ' Ping
Const NET_PINGRESPONSE:Int      = 4      ' Pong
Const NET_JOINREQUEST:Int       = 5      ' ALL: Join Attempt
Const NET_JOINRESPONSE:Int      = 6      ' ALL: Join Attempt - Response
Const NET_LEAVEGAME:Int         = 7
Const NET_LEAVEGAMEREQUEST:Int  = 8
Const NET_LEAVEGAMERESPONSE:Int = 9
CONST NET_PLAYERLEFT:int        = 10
CONST NET_PLAYERJOINED:int      = 11
Const NET_ANNOUNCEGAME:Int      = 12     ' SERVER: Announce a game


Extern "OS"
	?Win32
		Const FIONREAD      : Int   = $4004667F
		Const SOL_SOCKET_   : Int   = $FFFF
		Const SO_BROADCAST_ : Short = $20
		Const SO_SNDBUF_    : Short = $1001
		Const SO_RCVBUF_    : Short = $1002
	?MacOS
		Const FIONREAD      : Int   = $4004667F
		Const SOL_SOCKET_   : Int   = $FFFF
		Const SO_BROADCAST_ : Short = $20
		Const SO_SNDBUF_    : Short = $1001
		Const SO_RCVBUF_    : Short = $1002
	?Linux
		Const FIONREAD      : Int   = $0000541B
		Const SOL_SOCKET_   : Int   = 1
		Const SO_BROADCAST_ : Short = 6
		Const SO_SNDBUF_    : Short = 7
		Const SO_RCVBUF_    : Short = 8
	?Win32
		Function ioctl_:Int(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctlsocket@12"
		Function inet_addr_:Int(Address$z) = "inet_addr@4"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa@4"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname@12"
		Function GetCurrentProcessId:Int() = "GetCurrentProcessId@0"
	?MacOS
		Function ioctl_(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctl"
		Function inet_addr_:Int(Address$z) = "inet_addr"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname"
		Function GetCurrentProcessId:Int() = "getpid"
	?Linux
		Function ioctl_(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctl"
		Function inet_addr_:Int(Address$z) = "inet_addr"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname"
		Function GetCurrentProcessId:Int() = "getpid"
	?
End Extern




'all players wo take part in a game
Type TNetworkClient extends TNetworkConnection
	Global list:TList = New TList
	Global maxClients:Int = 1

	Field name:String = "Mr.X"
	Field server:TNetworkServer
	Field link:TLink
	Field playerID:int =-1
	Field playerName:string	= ""

	Field callback(client:TNetworkClient,evType:Int,networkObject:TNetworkObject)
	Field latency:Int


	Method GetPlayerID:int()
		return playerID
	End Method


	Method Free()
		If link
			link.remove()
			link=Null
		EndIf
		Super.Free()
	End Method


	Function Find:TNetworkClient(ip:Int,port:Int)
		Local client:TNetworkClient
		For client=EachIn list
			If client.ip=ip And client.port=port then Return client
		Next
		client		= New TNetworkClient
		client.ip	= ip
		client.port	= port
		client.link	= list.addlast(client)
		Return client
	EndFunction


	Function Create:TNetworkClient(port:int, playerID:int=-1, asServer:int=0)
		local portRange:int = 20
		Local addr:Byte Ptr
		Local client:TNetworkClient=New TNetworkClient
		client.playerID	= playerID

		If portRange<=1
			client.ip		= ENET_HOST_ANY
			client.port		= port
			addr			= enet_address_create( client.ip,client.port )
			client.enethost	= enet_host_create( addr,maxClients,0,0 )
			enet_address_destroy(addr)
			If Not client.enethost Return Null
			client.link		= list.addlast(client)
		Else
			If port=0 then port=4544
			For Local n:Int=port To port+portrange-1
				addr			= enet_address_create( ENET_HOST_ANY,n )
				client.enethost	= enet_host_create( addr,maxClients,0,0 )
				enet_address_destroy(addr)
				If client.enethost then client.port = port;exit
			Next
		EndIf

		Return client
	End Function

	Method Disconnect(force:Int = False)
		Const disconnecttimeout:Int=10000

		If Not Self.enethost then RuntimeError "Can't update a remote server."

		If Server
			If force
				enet_peer_reset(Server.enetpeer)
			Else
				SendEvent(NET_LEAVEGAMEREQUEST,NET_PACKET_RELIABLE)
				Local ev:ENetEvent=New ENetEvent
				Local start:Int = Time.GetTimeGone()
				Repeat
					If Time.GetTimeGone() - start > disconnecttimeout then Exit

					if not enet_host_service(self.enethost,ev,100) then Exit

					Select ev.event
						Case ENET_EVENT_TYPE_RECEIVE
							If ev.packet
								Local packet:TNetworkPacket
								Local size:Int=enet_packet_size(ev.packet)
								Local data:Byte[size]
								If size
									packet=New TNetworkPacket
									packet._bank.resize(size)
									MemCopy(packet._bank.buf(),enet_packet_data(ev.packet),size)
								EndIf
								local obj:TNetworkObject = TNetworkObject.FromPacket(packet)

								if obj.evType = NET_LEAVEGAMERESPONSE then exit
							EndIf
					EndSelect
				Forever
				enet_peer_disconnect(server.enetpeer)
			EndIf
			server=Null
		EndIf
		joined=False
		print ""
		print "- - - - - - - - - -"
		print "| DISCONNECTED !! |"
		print "- - - - - - - - - -"
		print ""
	End Method

	Method Connect:int(ip:Int, port:Int, timeout:int = 0)
'host ueberschreiben ?
'		If enethost then Return 'we are a server or alreay connected
'		enethost = enet_host_create( Null,32,0,0 )

		If Not enethost then RuntimeError "Remote client cannot connect to server."
		if Server then self.disconnect()

		server = New TNetworkServer
		server.ip = ip
		server.port	= port

		Local addr:Byte Ptr = enet_address_create(server.ip, server.port)
		server.enetpeer	= enet_host_connect(enethost, addr, channels)
		enet_address_destroy( addr )

		If server.enetpeer = Null
		print "connection failed"
			server = Null
			Return 0
		EndIf
		return 1
	End Method


	Method SendEvent:Int(_event:int=Null,flags:Int=0,channel:Int=0)
		if _event = null then print "null event"
		local obj:TNetworkObject = TNetworkObject.Create(_event )
		self.send( obj, flags)
	End Method


	'sends a packet from this client to the connected server
	Method Send:Int(NetworkObject:TNetworkObject=Null,flags:Int=0,channel:Int=0)
		if not NetworkObject then return 0
		local packet:TNetworkPacket = NetworkObject.ToPacket()
		if not packet then return 0


		If Not connected then Return 0

		If packet and packet._bank.size()=0 then packet=Null

		Local result:Int
		If packet
			Local data:Byte[] = New Byte[packet._bank.size()]
			MemCopy(Varptr data[0],packet._bank.buf(),packet._bank.size())
			Local enetpacket:Byte Ptr = enet_packet_create(data,data.length,flags)
			'send to this peer / connection
			result = (enet_peer_send(server.enetpeer,channel,enetpacket)=0)
		endif
		return result
	End Method


	Method EvaluateEvent(evType:Int,packet:TNetworkPacket,enetpeer:Byte Ptr)
		local response:TNetworkObject = TNetworkObject.fromPacket(packet)
		if response = null then response = TNetworkObject.Create(0)
		if evType = 0 then evType = response.evType
		enet_peer_address( enetpeer , response.senderIP , response.senderPort )
		'print "<-- client receives packet from="+dottedIP(response.senderIP)+", evType="+evType

		Select evType
			Case NET_CONNECT
				if not joined
					TLogger.Log("Network.EvaluateEvent()", "New client connects.", LOG_DEBUG | LOG_NETWORK)

					Self.connected	= 1
					local obj:TNetworkObject = TNetworkObject.Create(NET_JOINREQUEST )
					obj.setString(1,"Name")
					self.Send(obj)
				endif
				
			Case NET_JOINRESPONSE
				TLogger.Log("Network.EvaluateEvent()", "Got join response.", LOG_DEBUG | LOG_NETWORK)
				'got join - if ok then also set playerID
				joined = response.getInt(1)
				local playerID:int = response.getInt(2)
				If not joined OR playerID > self.maxClients
					Disconnect()
				else
					self.playerID = Max(0,playerID)
				endif
				
			Case NET_PINGREQUEST
				'change ev type from ping request to response
				response.evType = NET_PINGRESPONSE
				Send(response)
				
			Case NET_PINGRESPONSE
				latency = Time.GetTimeGone() - response.getInt(1)
				response.setInt(2, response.senderIP)
				response.setInt(3, response.senderPort)
				If enetpeer=pingpeer
					enet_peer_disconnect(pingpeer)
					pingpeer=Null
				EndIf
		EndSelect
		
		'run extension callback
		If callback then callback(Self,evType, response)
	End Method


	Method Ping:Int(ip:Int=0,port:Int=0)
		local obj:TNetworkObject = TNetworkObject.Create(NET_PINGREQUEST)
		obj.setInt(1, Time.GetTimeGone())
		Return Send(obj)
rem
		Const disconnecttimeout:Int=1000
		Local packet:TNetworkPacket=New TNetworkPacket,addr:Byte Ptr,eneTNetworkPacket:Byte Ptr,ev:EnetEvent,result:Int,id:Int,start:Int

		'ping local ?
		If self.ip=ip And self.port=port then ip=0

		If Not enethost then RuntimeError("Can't ping remote client.")
		If ip > 0
			If pingpeer
				enet_peer_disconnect(pingpeer)
				pingpeer=Null
			EndIf

			ev		= New EnetEvent
			addr	= enet_address_create(ip,port)
			pingpeer= enet_host_connect(enethost,addr,1)
			enet_address_destroy(addr)
			If pingpeer
				start = Time.GetTimeGone()
				Repeat
					If Time.GetTimeGone() - start > disconnecttimeout
						enet_peer_disconnect(pingpeer)
						pingpeer=Null
						'Print "Connect timeout"
						Return 0
					EndIf
					If enet_host_service(enethost,ev,0)
						id=ConvertEvent(ev,packet)
						if id = NET_CONNECT then exit
					EndIf
				Forever
				local obj:TNetworkObject = CreateNetworkObject(NET_PINGREQUEST)
				obj.setInt(1, Time.GetTimeGone() )

				packet = obj.ToPacket()
				If packet
					Local data:Byte[] = New Byte[packet._bank.size()]
					MemCopy(Varptr data[0],packet._bank.buf(),packet._bank.size())
					eneTNetworkPacket=enet_packet_create(data,data.length,0)
					If enet_peer_send(pingpeer,0,eneTNetworkPacket)=0
						Return 1
					Else
						enet_peer_disconnect(pingpeer)
						pingpeer=Null
						'Print "can't send packet"
						Return 0
					EndIf
				endif
			Else
				'Print "Cant connect to peer at "+ip+", "+port
				Return 0
			EndIf
		Else
			local response:TNetworkObject = CreateNetworkObject(NET_PINGREQUEST)
			response.setInt(1, Time.GetTimeGone())
			Return Send(response)
		EndIf
endrem
	End Method
End Type



Type TNetworkServer Extends TNetworkConnection
	Field clients:TList=New TList
	Field clientmap:TMap = CreateMap()
	Field callback(server:TNetworkServer,client:TNetworkclient,id:Int, networkObject:TNetworkObject)
	Field bannedips:Int[]

	Function Create:TNetworkServer(port:Int=0,portRange:Int=40)
		Local addr:Byte Ptr
		local server:TNetworkServer=New TNetworkServer
		server.ip = ENET_HOST_ANY

		If portrange <= 1
			addr = enet_address_create( server.ip,server.port )
			server.enethost	= enet_host_create( addr,32,0,0 )
			enet_address_destroy(addr)
		Else
			If port=0 then port=4544
			For Local n:Int=port To port+portrange-1
				addr = enet_address_create( ENET_HOST_ANY,n )
				server.enethost	= enet_host_create( addr,64,0,0 )
				enet_address_destroy(addr)
				If server.enethost
					server.port = n
					Exit
				Endif
			Next
		EndIf
		If Not server.enethost then Return Null
		Return server
	End Function


	Method FindClientByName:TNetworkClient(name:String)
		Return TNetworkClient( clientmap.valueforkey(name) )
	End Method


	Method FindClientByPeer:TNetworkclient(peer:Byte Ptr)
		Local client:TNetworkclient
		For client=EachIn clients
			If client.enetpeer = peer then Return client
		Next
		return Null
	End Method
	

	Method FindClient:TNetworkClient(ip:Int,port:Int)
		Local client:TNetworkClient
		For client=EachIn clients
			If client.ip = ip And client.port = port then Return client
		Next
		return Null
	End Method


	Method EvaluateEvent(evType:Int,packet:TNetworkPacket,enetpeer:Byte Ptr)
		Local client:TNetworkClient=FindClient(enet_peer_ip(enetpeer),enet_peer_port(enetpeer))
		local response:TNetworkObject = TNetworkObject.fromPacket(packet)

		'should we only act as relay (client broadcasting)
		local toRelay:int = floor(response.evType / 10000)
		if toRelay
			response.evType :mod 10000
			'print "Server got relay event:" + response.evType
			'at the moment broadcasts are reliable
	'self.broadcast(response, null, NET_PACKET_RELIABLE)
			self.broadcast(response, client, NET_PACKET_RELIABLE)
			return
		endif




		Local answer:TNetworkObject
		enet_peer_address( enetpeer , response.senderIP , response.senderPort )
	'	print "<-- server receives packet from="+dottedIP(response.senderIP)+", evType="+evType

		if evType = 0 then evType = response.evType

		Select evType
			Case NET_PINGRESPONSE
				client.latency = Time.GetTimeGone() - response.getInt(1)

			Case NET_LEAVEGAMEREQUEST
				If client
					client.SendEvent(NET_LEAVEGAMERESPONSE, NET_PACKET_RELIABLE)
					answer = TNetworkObject.Create(NET_PLAYERLEFT)
					answer.setInt(1, client.playerID)
					answer.setString(2, client.name)
					Broadcast(answer, null, NET_PACKET_RELIABLE)
					clients.remove(client)
					If clientmap.valueforkey(client.name)=client then clientmap.remove(client.name)
				EndIf

			Case NET_JOINREQUEST
				If client
					Disconnect(client,1)
					answer = TNetworkObject.Create(NET_PLAYERLEFT)
					answer.setInt(1, client.playerID)
					Broadcast(answer)
				EndIf
				client = TNetworkClient.Find(enet_peer_ip(enetpeer),enet_peer_port(enetpeer))
				client.enetpeer=enetpeer

				'check if IP is banned/not allowed to join
				If IPBanned(client.ip)
					Disconnect(client,0)
					Return
				Endif
				
				'handle join
				client.name = response.GetString(1)
				'duplicate name "boon" => "boon (1)"
				If FindClientByName(client.name)
					local addNum:int=0
					while FindClientByName(client.name+" ("+addNum+")")
						addNum:+1
					Wend
					client.name = client.name + " ("+addNum+")"

					TLogger.Log("Network.EvaluateEvent()", "Handle join: clients name already taken, renamed to "+client.name, LOG_DEBUG | LOG_NETWORK)
				endif

				If not FindClientByName(client.name)
					clientmap.insert(client.name,client)
					clients.AddLast(client)
					client.playerID = clients.count()
					'answer the clients join request
					answer = TNetworkObject.Create(NET_JOINRESPONSE)
					answer.setInt(1, 1)
					answer.setInt(2, clients.count()) 'change to GetSlot() or so
					SendToClient(client, answer,NET_PACKET_RELIABLE)
					TLogger.Log("Network.EvaluateEvent()", "Handle join: send back accepted join packet", LOG_DEBUG | LOG_NETWORK)

					'send peer data
					'Tell everyone new client joined
					answer = TNetworkObject.Create(NET_PLAYERJOINED)
					answer.setInt(1, clients.count()) 'change to GetSlot() or so
					answer.setString(2, client.name)

					'inform callback about playerjoined
					If callback then callback(Self, client, evType, answer)

					Broadcast(answer, null, NET_PACKET_RELIABLE)
				Else
					TLogger.Log("Network.EvaluateEvent()", "Handle join: client cannot join, no name already taken. Rename not possible.", LOG_DEBUG | LOG_NETWORK)
					answer = TNetworkObject.Create(NET_JOINRESPONSE)
					answer.setInt(1, 0) 'no, you can't joint
					answer.setInt(2, 1) 'reason: name already taken
					client.Send(answer,NET_PACKET_RELIABLE)
					Return
				EndIf

			Case NET_CONNECT
				Return

			Case NET_DISCONNECT
				If client
					clients.remove(client)
					If clientmap.valueforkey(client.name)=client then clientmap.remove(client.name)
					If Not client.enethost then client.free()
				EndIf

			Case NET_PINGREQUEST
				If Not client
					client			= New TNetworkClient
					client.enetpeer	= enetpeer
				EndIf
				response.evType = NET_PINGRESPONSE
				SendToClient(client, response)
				response.evType = NET_PINGREQUEST
				'Return
		EndSelect

		If callback then callback(Self,client,evType, response )
	End Method

	Method BroadcastEvent:Int(_event:int=Null, exceptClient:TNetworkClient=null, flags:Int=0,channel:Int=0)
		self.Broadcast(CreateNetworkObject(_event), exceptClient, flags, channel)
	End Method

	Method Broadcast:Int(NetworkObject:TNetworkObject=Null, exceptClient:TNetworkClient=null, flags:Int=0,channel:Int=0)
		if not NetworkObject then return 0
		local packet:TNetworkPacket = NetworkObject.ToPacket()
		Local result:Int=1
		For Local client:TNetworkClient=EachIn clients
			if client <> exceptClient
'				if not client.send(NetworkObject, flags, channel) then result = 0
				if Not SendPacketToClient(client, packet,flags,channel) then result=0
			endif
		Next
		Return result
	End Method

	Method Send:Int(NetworkObject:TNetworkObject=Null,flags:Int=0,channel:Int=0)
		if not NetworkObject then return 0
		local packet:TNetworkPacket = NetworkObject.ToPacket()
		if not packet then return 0

		If packet and packet._bank.size()=0 then packet=Null

		Local result:Int
		If packet
			Local data:Byte[] = New Byte[packet._bank.size()]
			MemCopy(Varptr data[0],packet._bank.buf(),packet._bank.size())
			Local enetpacket:Byte Ptr = enet_packet_create(data,data.length,flags)
			'send to this peer / connection
			result = (enet_peer_send(self.enetpeer,channel,enetpacket)=0)
		endif
		return result
	End Method

	'send packet - so for broadcast we dont need "topacket" for each client
	Method SendPacketToClient:Int(client:TNetworkClient, packet:TNetworkPacket=Null,flags:Int=0,channel:Int=0)
		if not packet then return 0
		If packet and packet._bank.size()=0 then packet=Null
		If Not client.enetpeer then RuntimeError "Can't send to local client."

		Local result:Int
		If packet
			Local data:Byte[] = New Byte[packet._bank.size()]
			MemCopy(Varptr data[0],packet._bank.buf(),packet._bank.size())
			Local enetpacket:Byte Ptr = enet_packet_create(data,data.length,flags)
			'send to this peer / connection
			result = (enet_peer_send(client.enetpeer,channel,enetpacket)=0)
		endif
		return result
	End Method

	Method SendToClient:Int(client:TNetworkClient, NetworkObject:TNetworkObject=Null,flags:Int=0,channel:Int=0)
		if not NetworkObject then return 0
		local packet:TNetworkPacket = NetworkObject.ToPacket()
		return self.SendPacketToClient(client, packet, flags, channel)
	End Method


	Method Disconnect(client:TNetworkClient,force:Int=False)
		If client.enetpeer
			If force
				enet_peer_reset(client.enetpeer)
			Else
				enet_peer_disconnect(client.enetpeer)
			EndIf
			clients.remove(client)
			If Not client.enethost then client.link.remove()
			If clientmap.valueforkey(client.name)=client then clientmap.remove(client.name)
			client.enetpeer=Null
		EndIf
	End Method

	Method BanIP(ip:Int)
		bannedips=bannedips[..bannedips.length+1]
		bannedips[bannedips.length-1]=ip
	End Method

	Method IPBanned:Int(ip:Int)
		For Local n:Int=0 To bannedips.length-1
			If ip=bannedips[n] Return True
		Next
		Return False
	End Method

	Method Kick(client:TNetworkClient)
		BanIP(client.ip)
		Disconnect(client)
	End Method

EndType



Function CreateNetworkObject:TNetworkObject(evType:int)
	return TNetworkObject.Create(evType)
End Function


Type TNetworkPacket Extends TBankStream
	field ip:int
	field port:int

	Method New()
		_bank=New TBank
	End Method

EndType



'base of all networkevents...
'added to the base networking functions are all methods to send and receive data from clients
'including playerposition, programmesending, changes of elevatorpositions etc.
Type TDigNetwork
	Global localFallbackIP:int = 0
	Global localPort:int = 4544
	' only for lan (up to now) - announcements
	Global infoPort:int	= 4543
	Global maxPlayers:int = 4
	field fallbackip:String	= "192.168.0.3"

	'=== to interact with clients/host ===
	Field infoStream:TUDPStream	= Null
	Field callbackClient(client:TNetworkClient,evType:Int,networkObject:TNetworkObject)
	Field client:TNetworkClient	= Null
	Field callbackServer(server:TNetworkServer,client:TNetworkclient,id:Int,networkObject:TNetworkObject)
	Field server:TNetworkServer	= Null

	'=== runtime variables ===
	' Are you hosting or joining?
	Field isServer:int = False
	' Are you connected?
	Field IsConnected:int = False
	' Are we already playing?
	Field inGame:int = False
	' ip for internet
	Field OnlineIP:String = ""
	' int version of ip for internet
	Field intOnlineIP:Int = 0

	'=== game announcements ===
	Field announceEnabled:int = 0
	' title used when announcing
	Field announceTitle:string = "unknown"
	' Main Announcement Timer
	Field announceTime:Int = -1
	' Main Announcement Timer time
	Field announceTimer:Int = 750
	Field announceToLan:int = 1

	' Ping Timer
	Field pingTime:Int = 0
	' Ping Timer
	Field pingTimer:Int = 4000
	' Update Timer
	Field UpdateTime:Int
	' Main Update Timer
	Field MainSyncTime:Int
	Field LastOnlineRequestTimer:Int = 0
	'time until next action (getlist, announce...)
	Field LastOnlineRequestTime:Int = 10000
	Field LastOnlineHashCode:String = ""
	' // Networking Constants
	Field ChatSpamTime:Int = 0


	Method New()
		TNetworkClient.maxClients = self.maxPlayers
	End Method


	Method InitInfoStream()
		if infoStream then return
		If infoStream = Null Then infoStream = new TUDPStream
		if infoStream = null then RuntimeError "Couldn't create UDP stream for LAN game announcements"
		infoStream.Init()
		infoStream.SetLocalPort(self.infoPort)
		infoStream.SetRemotePort(self.infoPort)
	End Method


	Method StopAnnouncing:int()
		self.announceEnabled = false
	End Method


	Method StartAnnouncing(title:string, toLan:int = 1)
		self.InitInfoStream()
		self.announceEnabled = true
		self.announceTitle = title
		self.announceTime = Time.GetTimeGone()
		self.announceToLan = toLan
	End Method

	
	Method FindGames()
		if inGame then return
		if not infoStream
			TLogger.Log("Network.FindGames()", "Initialized info stream.", LOG_DEBUG | LOG_NETWORK)
			self.InitInfoStream()
		endif
		
		local packet:TNetworkPacket = self.ReceiveInfoPackets()
		if packet
			local obj:TNetworkObject = TNetworkObject.FromPacket(packet)
			if not obj then return

			if obj.evType = NET_ANNOUNCEGAME
				'only emit event for clients (not the server)
				if not server
					local evData:TData = new TData
					evData.AddNumber("slotsUsed", obj.getInt(1))
					evData.AddNumber("slotsMax", obj.getInt(2))
					'could differ from senderIP
					evData.AddNumber("hostIP", obj.getInt(3))
					'differs from senderPort (info channel)
					evData.AddNumber("hostPort", obj.getInt(4))
					evData.AddString("hostName", obj.getString(5))
					evData.AddString("gameTitle", obj.getString(6))

					TEventSimple.Create("network.onReceiveAnnounceGame", evData).trigger()
					'print "...announce from: "+ GetDottedIP(obj.getInt(3))
				endif
			endif
		endif
	End Method


	Method DisconnectFromServer()
		if not server then return
		if not client then return
		server.Disconnect(client) ' Disconnect
	End Method


	Method StartServer:int( )
		if not server then server = TNetworkServer.Create(localPort, 20)
		if server
			self.isServer = true
			self.server.callback = self.callbackServer
			TEventSimple.Create("network.onCreateServer", new TData.AddNumber("successful", true)).trigger()

			TLogger.Log("Network.StartServer()", "created server : "+GetDottedIP(GetMyIP())+":"+server.port, LOG_DEBUG | LOG_NETWORK)
			return true
		else
			TEventSimple.Create("network.onCreateServer", new TData.AddNumber("successful", false)).trigger()

			return false
		endif
	End Method


	Method StopServer:int( )
		self.isServer = false
		server.free()
		client.free()
		self.server = null
		self.client = null

		TEventSimple.Create("network.onStopServer", null).trigger()
	End Method
	

	Method GetMyIP:int()
		local MyIP:int = GetHostIP("")
		If MyIP = 0 then MyIP = self.localFallbackIP
		return MyIP
	End Method


	Function GetDottedIP:string(ip:int)
		'results differ with DottedIP() !!
		'return DottedIP(ip)
		return (ip Shr 24)+"."+(ip Shr 16 & 255)+"."+(ip Shr 8 & 255 )+"."+(ip & 255)
	End Function
	

	Method ConnectToLocalServer:int()
		if not client then client = TNetworkClient.Create(localPort, 20)
		self.client.callback = self.callbackClient
		self.isConnected = client.Connect(getMyIP(), localPort)
		return self.isConnected
	End Method


	Method ConnectToServer:int( ip:int, port:int )

		if not client then client = TNetworkClient.Create(localPort, 20)
		self.client.callback = self.callbackClient
		self.isConnected = client.Connect(ip, port)

		TEventSimple.Create("network.onConnectToServer", new TData.AddNumber("successful", isConnected)).trigger()

		TLogger.Log("Network.ConnectToServer()", "connect to "+GetDottedIP(ip)+":"+port, LOG_DEBUG | LOG_NETWORK)
		return self.isConnected
	End Method


	'client wants to broadcast - so we send a relaypacket to server
	Method BroadcastNetworkObject(obj:TNetworkObject, flags:int = 0)
		if not client then return
		'add 10000 so we see its for relaying
		obj.evType = obj.evType + 10000
		'client sends to server
		client.send(obj, flags)
	End Method


	Method Update:int()
		if self.isServer then self.SendGameAnnouncement()
		self.FindGames()


		if self.server then self.server.Update()
		if self.client
			if self.pingTime < Time.GetTimeGone()
				self.client.Ping()
				self.pingTime = Time.GetTimeGone() + self.pingTimer
			endif
			self.client.Update()
		endif
	End Method


	Function URLEncode:String(txt:String)
		txt=Replace(txt,"%","%25")
		txt=Replace(txt,"+","%2B")
		txt=Replace(txt," ","%20")
		txt=Replace(txt,"@","%40")
		txt=Replace(txt,"ß","%DF")
		txt=Replace(txt,"?","%3F")
		txt=Replace(txt,"=","%3D")
		txt=Replace(txt,")","%29")
		txt=Replace(txt,"(","%28")
		txt=Replace(txt,"/","%2F")
		txt=Replace(txt,"&","%26")
		txt=Replace(txt,"$","%24")
		txt=Replace(txt,"§","%A7")
		txt=Replace(txt,Chr(34),"%22")
		txt=Replace(txt,"!","%21")
		txt=Replace(txt,"^","%5E")
		txt=Replace(txt,"#","%23")
		txt=Replace(txt,"<","%3C")
		txt=Replace(txt,">","%3E")
		txt=Replace(txt,"{","%7B")
		txt=Replace(txt,"}","%7D")
		txt=Replace(txt,"[","%5B")
		txt=Replace(txt,"]","%5D")
		Return txt
	End Function


	Function URLDecode:String(txt:String)
		txt=Replace(txt,"%25","%")
		txt=Replace(txt,"%2B","+")
		txt=Replace(txt,"%20"," ")
		txt=Replace(txt,"%40","@")
		txt=Replace(txt,"%DF","ß")
		txt=Replace(txt,"%3F","?")
		txt=Replace(txt,"%3D","=")
		txt=Replace(txt,"%29",")")
		txt=Replace(txt,"%28","(")
		txt=Replace(txt,"%2F","/")
		txt=Replace(txt,"%26","&")
		txt=Replace(txt,"%24","$")
		txt=Replace(txt,"%A7","§")
		txt=Replace(txt,"%22",Chr(34))
		txt=Replace(txt,"%21","!")
		txt=Replace(txt,"%5E","^")
		txt=Replace(txt,"%23","#")
		txt=Replace(txt,"%3C","<")
		txt=Replace(txt,"%3E",">")
		txt=Replace(txt,"%7B","{")
		txt=Replace(txt,"%7D","}")
		txt=Replace(txt,"%5B","[")
		txt=Replace(txt,"%5D","]")
		Return txt
	End Function


	Function GetHostIP:Int(HostName:String)
		Local Addresses:Byte Ptr Ptr, AddressType:Int, AddressLength:Int
		Local PAddress:Byte Ptr, Address:Int

		Addresses = gethostbyname_(HostName, AddressType, AddressLength)
		If (Not Addresses) Or AddressType <> AF_INET_ Or AddressLength <> 4 Then Return 0

		If Addresses[0] Then
			PAddress = Addresses[0]
			Address = (PAddress[0] Shl 24) | (PAddress[1] Shl 16) | ..
			          (PAddress[2] Shl 8) | PAddress[3]
			Return  Address
		Else
			Return 0
		EndIf
	End Function
	

	Function GetBroadcastIP:String(intIP:int)
		local ip:string = DottedIP(intIP)
		If Len(ip$)>6
			Local lastperiod:Int=1
			Local period:Int =0
			For Local t:Int=1 To 3				    '; 4 Zahlengruppen, aber die letzte muss weg
				period=Instr(ip,".",lastperiod)
				lastperiod=period+1
			Next
			local res:string = Left(ip,period)+"255"
			return res
		Else
			Return ""
		EndIf
	End Function


	Method GetFreeSlot:Int()
		'4 = max peers
		return Max(0, self.maxPlayers-self.server.clients.count())
	End Method


	Method GetUsedSlots:Int()
		return self.server.clients.count()
	End Method


	Method GetMaxSlots:Int()
		return self.maxPlayers
	End Method


	'modier of sync speed
	Method GetSyncSpeedFactor:float()
		return 1.0 'If game.onlinegame Then return 1.0 else return 0.5
	End Method


	Method SendGameAnnouncement()
		if not self.announceEnabled then return
		if self.announceTime > Time.GetTimeGone() then return
		if self.GetFreeSlot() = 0 then return

		self.announceTime = Time.GetTimeGone() + self.announceTimer
		local obj:TNetworkObject = TNetworkObject.Create(NET_ANNOUNCEGAME)
		If self.announceToLan
			'TLogger.Log("Network.SendGameAnnouncement()", "Announcing LAN game to "+GetBroadcastIP(GetMyIP()), LOG_DEBUG | LOG_NETWORK)

			obj.setInt(1, self.GetUsedSlots())
			obj.setInt(2, self.GetMaxSlots())
			obj.setInt(3, self.GetMyIP())
			obj.setInt(4, self.localPort)
			obj.setString(5, client.playerName)
			obj.setString(6, self.announceTitle)
		
			self.SendInfoPacket(obj.toPacket(), GetBroadcastIP(self.GetMyIP()), self.infoPort)
		Else
rem

			TLogger.Log("Network.SendGameAnnouncement()", "Announcing ONLINE game", LOG_DEBUG | LOG_NETWORK)
			Local Onlinestream:TStream = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=AddGame&Titel="+UrlEncode(Game.title)+"&IP="+OnlineIP+"&Port="+host.port+"&Spieler="+Self.getFreeSlot()+"&Hashcode="+LastOnlineHashCode)
			Local timeouttimer:Int = Time.GetTimeGone() + 5000 '5 seconds okay?
			Local timeout:Byte = False
			If Not Onlinestream Then Throw ("Not Online?")

			While Not Eof(Onlinestream) Or timeout
				If timeouttimer < Time.GetTimeGone() Then timeout = True
				Local responsestring:String = ReadLine(Onlinestream)
				If responsestring <> Null AND responsestring <> "UPDATEDGAME" Then LastOnlineHashCode = responsestring
			Wend
			CloseStream Onlinestream
endrem
		EndIf
	End Method


	Method ReceiveInfoPackets:TNetworkPacket()
		if infoStream.RecvAvail()
			While infoStream.RecvMsg()
				'
			Wend

			Local size:Int = infoStream.Size()
			If size
				Local data:Byte[size]
				local packet:TNetworkPacket = New TNetworkPacket
				packet._bank.resize(size)
				MemCopy(packet._bank.buf(),infoStream.RecvBuffer,size)
				infoStream.Flush()
				packet.ip = infoStream.MessageIP
				packet.port	= infoStream.MessagePort
				return packet
			EndIf
		endif
		return null
	End Method


	Method SendInfoPacket:int(packet:TNetworkPacket, ip:string, port:int)
		'set broadcast (for linux)
		infoStream.SetBroadcast(true)

		if packet and packet._bank.size()
			Local length:int	= packet._bank.size()
			if length > 0 and not infoStream.write(packet._bank.buf(), length) then throw "Net: Error writing to Networkmessage buffer " + length
			if not infoStream.SendUDPMsg( HostIP(ip), port ) then throw "Net: Error sending udp message to " + ip+ " :" + port
		endif
		return true

rem
		local broadcast:int = true
		If setsockopt_(self.announceSocket._socket, 1, 6, Varptr(broadcast), 4) = SOCKET_ERROR_ Then print "Problem broadcasting"
		if packet and packet._bank.size()
			Local sent:int = sendto_(self.announceSocket._socket, packet._bank._buf, packet._bank.size(), 0, HostIp(ip), port)
			return sent
		endif
		return false
endrem
	End Method


End Type
Global Network:TDigNetwork = new TDigNetwork







Const ENET_PACKET_FLAG_UNSEQUENCED:Int = 2


Function enet_host_port:Int( peer:Byte Ptr  )
	Local ip:Int=(Int Ptr peer)[1]
	Local port:Int=(Short Ptr peer)[4]
	?LittleEndian
	ip=(ip Shr 24) | (ip Shr 8 & $ff00) | (ip Shl 8 & $ff0000) | (ip Shl 24)
	?
	Return port
EndFunction

Function enet_host_ip:Int( peer:Byte Ptr  )
	Local ip:Int=(Int Ptr peer)[1]
	Local port:Int=(Short Ptr peer)[4]
	?LittleEndian
	ip=(ip Shr 24) | (ip Shr 8 & $ff00) | (ip Shl 8 & $ff0000) | (ip Shl 24)
	?
	Return ip
EndFunction

Function enet_peer_port:Int( peer:Byte Ptr  )
	Local ip:Int=(Int Ptr peer)[3]
	Local port:Int=(Short Ptr peer)[8]
	?LittleEndian
	ip=(ip Shr 24) | (ip Shr 8 & $ff00) | (ip Shl 8 & $ff0000) | (ip Shl 24)
	?
	Return port
EndFunction

Function enet_peer_ip:Int( peer:Byte Ptr  )
	Local ip:Int=(Int Ptr peer)[3]
	Local port:Int=(Short Ptr peer)[8]
	?LittleEndian
	ip=(ip Shr 24) | (ip Shr 8 & $ff00) | (ip Shl 8 & $ff0000) | (ip Shl 24)
	?
	Return ip
EndFunction




Type TNetworkObject
	Field senderIP:int = 0
	Field senderPort:int =0
	Field data:byte[]
	Field state:int
	Field evType:int
	Field slots:TNetworkObjectSlot[32]
	Field modified:int
	Field target:object 'remote ?


	Method new()
		For Local i:int = 0 Until 32
			self.slots[i] = New TNetworkObjectSlot
		Next
	End Method


	Function Create:TNetworkObject( evType:int )
		Local obj:TNetworkObject = New TNetworkObject
		obj.state = NET_STATE_MESSAGE
		obj.evType = evType
		if Network.server and Network.server.enetpeer
			obj.senderIP = enet_host_ip(Network.server.enetpeer)
			obj.senderPort = enet_host_port(Network.server.enetpeer)
		endif
		Return obj
	End Function
	

	Method SetInt( index:int,data:int )
		WriteSlot( index ).SetInt data
	End Method


	Method SetFloat( index:int, data:float )
		WriteSlot( index ).SetFloat data
	End Method


	Method SetString( index:int, data:string )
		WriteSlot( index ).SetString data
	End Method


	Method GetInt:int( index:int, defaultValue:int=0, defaultProvided:int=FALSE )
		Return slots[index].GetInt( defaultValue, defaultProvided )
	End Method


	Method GetFloat:float( index:int, defaultValue:float=0.0, defaultProvided:int=FALSE  )
		Return slots[index].GetFloat( defaultValue, defaultProvided )
	End Method


	Method GetString:string( index:int, defaultValue:string="", defaultProvided:int=FALSE )
		Return slots[index].GetString( defaultValue, defaultProvided )
	End Method


	Method WriteSlot:TNetworkObjectSlot( index:int )
		Assert state<>NET_STATE_CLOSED And state<>NET_STATE_ZOMBIE Else "Object has been closed"
		modified :|1 Shl index
		If state = NET_STATE_SYNCED OR NET_STATE_FOREVER then state=NET_STATE_MODIFIED
		Return slots[index]
	End Method


	Method ToPacket:TNetworkPacket()
		local packet:TNetworkPacket = New TNetworkPacket
		packet.writeInt(NET_PACKET_HEADER)
		packet.writeInt(state)
		packet.writeInt(evType)
		packet.writeInt(self.senderIP)
		packet.writeInt(self.senderPort)
		local packedData:byte[] = PackSlots( modified )
		packet.writeBytes( packedData, len(packedData) )
		return packet
	End Method


	Function FromPacket:TNetworkObject( packet:TNetworkPacket )
		if not packet then return TNetworkObject.Create(0)

		packet.seek(0)
		local obj:TNetworkObject = new TNetworkObject
		if packet.size() >= 20 '5 ints
			local header:int = packet.readInt()
			if header <> NET_PACKET_HEADER then return null
			obj.state	= packet.readInt()
			obj.evType	= packet.readInt()
			obj.senderIP= packet.readInt()
			obj.senderPort= packet.readInt()

			if obj.senderIP = 0 then obj.senderIP = packet.ip
			if obj.senderPort = 0 then obj.senderPort = packet.port

			if packet.Size() > 20
				local rawdata:byte ptr = MemAlloc( packet.Size()-20 )
				local packdata:byte[] = New Byte[ packet.Size()-20 ]
				packet.readbytes(rawdata, packet.Size()-20 )
				MemCopy packdata,rawdata, packet.Size()-20
				MemFree rawdata
				obj.UnpackSlots(packdata)
				packdata = null
			else
				For Local i:int = 0 Until 32
					obj.slots[i] = New TNetworkObjectSlot
				Next
			endif
		endif
		return obj
	End Function


	Method Sync:TNetworkMessage()
		Select state
			Case NET_STATE_SYNCED, NET_STATE_ZOMBIE
				Return null
		End Select

		Local msg:TNetworkMessage = new TNetworkMessage

		'local
		msg.state = state
		msg.evType = evType
		msg.data = PackSlots( modified )

		modified = 0

		Select state
			Case NET_STATE_CREATED,NET_STATE_MODIFIED
				state=NET_STATE_SYNCED
			Case NET_STATE_CLOSED
				target=Null
				state=NET_STATE_ZOMBIE
		End Select
		Return msg
	End Method


	Method Update( msg:TNetworkMessage )
		self.UnpackSlots(msg.data)
		state = msg.state
	End Method


	Method PackSlots:Byte[]( mask:int )
		Local size:int
		For Local index:int = 0 Until 32
			If Not (mask & 1 Shl index) then Continue
			Select slots[index].slottype
				Case false, 0           continue
				Case NET_TYPE_INT       size:+5
				Case NET_TYPE_UINT8     size:+2
				Case NET_TYPE_UINT16    size:+3
				Case NET_TYPE_FLOAT16   size:+3
				Case NET_TYPE_FLOAT32   size:+5
				Case NET_TYPE_STRING    size:+3+GetString(index).length
			End Select
		Next
		If size > $fff0 then Throw "NetworkMessage data too large"
		Local data:Byte[size]
		Local p:Byte Ptr = data
		local n:int = 0
		For local index:int = 0 Until 32
			If Not (mask & 1 Shl index) then Continue
			Select slots[index].slottype
				Case false, 0
					continue
				Case NET_TYPE_INT
					n = GetInt( index )
				    p[0]=NET_TYPE_INT Shl 5 | index
				    p[1]=n Shr 24
					p[2]=n Shr 16
					p[3]=n Shr 8
					p[4]=n Shr 0
					p:+5
				Case NET_TYPE_UINT8
					n = GetInt( index )
					p[0]=NET_TYPE_UINT8 Shl 5 | index
					p[1]=n
					p:+2
				Case NET_TYPE_UINT16
					n = GetInt( index )
					p[0]=NET_TYPE_UINT16 Shl 5 | index
					p[1]=n Shr 8
					p[2]=n Shr 0
					p:+3
				Case NET_TYPE_FLOAT16
					n = PackFloat16( GetFloat(index) )
					p[0]=NET_TYPE_FLOAT16 Shl 5 | index
					p[1]=n Shr 8
					p[2]=n Shr 0
					p:+3
				Case NET_TYPE_FLOAT32
					n = PackFloat32( GetFloat(index) )
					p[0]=NET_TYPE_FLOAT32 Shl 5 | index
					p[1]=n Shr 24
					p[2]=n Shr 16
					p[3]=n Shr 8
					p[4]=n Shr 0
					p:+5
				Case NET_TYPE_STRING
					local dataStr:string =GetString( index )
					n = dataStr.length
					p[0]=NET_TYPE_STRING Shl 5 | index
					p[1]=n Shr 8
					p[2]=n Shr 0
					Local t:Byte Ptr=dataStr.ToCString()
					MemCopy(p+3, t, n)
					MemFree(t)
					p:+3+n
				Default
					Throw "Invalid TNetworkObjectSlot data type"
			End Select
		Next
		Return data
	End Method


	Method UnpackSlots( data:Byte[] )
		Local p:Byte Ptr = data
		Local e:Byte Ptr = p + data.length
		While p < e
			Local typ:int = p[0] Shr 5
			Local index:int = p[0] & 31
			p :+ 1
			Select typ
				Case NET_TYPE_INT
					SetInt(index, p[0] Shl 24 | p[1] Shl 16 | p[2] Shl 8 | p[3])
					p:+4
					'print "slot "+index+" is type "+typ+" (int)"
				Case NET_TYPE_UINT8
					SetInt(index, p[0])
					p:+1
					'print "slot "+index+" is type "+typ+" (uint8)"
				Case NET_TYPE_UINT16
					SetInt(index, p[0] Shl 8 | p[1])
					p:+2
					'print "slot "+index+" is type "+typ+" (uint16)"
				Case NET_TYPE_FLOAT16
					SetFloat(index, UnpackFloat16( p[0] Shl 8 | p[1] ))
					p:+2
					'print "slot "+index+" is type "+typ+" (float16)"
				Case NET_TYPE_FLOAT32
					SetFloat(index, UnpackFloat32( p[0] Shl 24 | p[1] Shl 16 | p[2] Shl 8 | p[3] ))
					p:+4
					'print "slot "+index+" is type "+typ+" (float32)"
				Case NET_TYPE_STRING
					local length:int = p[0] Shl 8 | p[1]
					SetString(index, String.FromBytes( p+2, length ))
					p:+2 +length
					'print "slot "+index+" is type "+typ+" (string)"
				Default
					Throw "Invalid NetworkObjectSlot data type"
			End Select
		Wend
		'If p<>e Throw "Corrupt NetworkObject message"
		If p < e then print "Corrupt NetworkObject message - shorter than expected"
		If p > e then print "Corrupt NetworkObject message - longer than expected"
	End Method



	'=== FROM gnet.bmx ===

	Function PackFloat16:int( f:float )
		Local i:int=(Int Ptr Varptr f)[0]
		If i=$00000000 Return $0000	'+0
		If i=$80000000 Return $8000	'-0
		Local M:int=i Shl 9
		Local S:int=i Shr 31
		Local E:int=(i Shr 23 & $ff)-127
		If E=128
			If M then Return $ffff		'NaN
			Return S Shl 15 | $7c00	'+/-Infinity
		EndIf
		M:+$00200000
		If Not (M & $ffe00000) then E:+1
		If E>15
			Return S Shl 15 | $7c00	'+/-Infinity
		Else If E<-15
			Return S Shl 15			'+/- 0
		EndIf
		Return S Shl 15 | (E+15) Shl 10 | M Shr 22
	End Function

	Function UnpackFloat16:float( i:int )
		i:&$ffff
		If i=$0000 Return +0.0
		If i=$8000 Return -0.0
		Local M:int=i Shl 22
		Local S:int=i Shr 15
		Local E:int=(i Shr 10 & $1f)-15
		If E=16
			If M Return 0.0/0.0		'NaN
			If S Return -1.0/0.0	'-Infinity
			Return +1.0/0.0			'+Infinity
		Else If E = -15				'denormal as float16, but normal as float32.
			For local j:int = 0 To 9          'find the leading 1-bit
				Local bit:int = M & $80000000
				M:Shl 1
				If bit then Exit
			Next
			E:-i
		EndIf
		Local n:int =S Shl 31 | (E+127) Shl 23 | M Shr 9
		Return (Float Ptr Varptr n)[0]
	End Function

	Function PackFloat32:int( f:float )
		Return (Int Ptr Varptr f)[0]
	End Function

	Function UnpackFloat32:float( i:int )
		Return (Float Ptr Varptr i)[0]
	End Function
	
	'=== / END FROM gnet.bmx ===
End Type




Type TNetworkObjectSlot
	Field slottype:int
	Field _int:int
	Field _float:float
	Field _string:string


	Method SetInt( data:int )
		Assert slottype = 0 Or slottype=NET_TYPE_INT Or slottype=NET_TYPE_UINT8 Or slottype=NET_TYPE_UINT16
		_int = data
		If data < 0
			slottype = NET_TYPE_INT
		Else If data <= 255
			slottype = NET_TYPE_UINT8
		Else If data <= 65535
			slottype = NET_TYPE_UINT16
		Else
			slottype = NET_TYPE_INT
		EndIf
	End Method


	Method SetFloat( data:float )
		Assert slottype=0 Or slottype = NET_TYPE_FLOAT32
		_float = data
		slottype = NET_TYPE_FLOAT32
	End Method


	Method SetString( data:string )
		Assert slottype = 0 Or slottype = NET_TYPE_STRING
		_string	= data
		slottype = NET_TYPE_STRING
	End Method


	'we have to add a "defaultProvided" as integers have no "null"
	'(0 is null too!)
	Method GetInt:int(defaultValue:int = 0, defaultProvided:int = FALSE)
		'if a defaultValue is set we return that as long as
		'the type of the field is differing
		if defaultProvided
			Select slottype
				case NET_TYPE_INT, NET_TYPE_UINT8, NET_TYPE_UINT16
					Return _int
				default
					Return defaultValue
			End Select
		else
			Assert slottype = NET_TYPE_INT Or slottype = NET_TYPE_UINT8 Or slottype = NET_TYPE_UINT16, "Wrong slot type. No INT but "+slottype
			Return _int
		endif
	End Method


	Method GetFloat:float(defaultValue:float=0.0, defaultProvided:int=FALSE)
		'float/int/string don't have real NULL, so we have to rely on
		'defaultProvided
		'if a defaultValue is set, return it as long as field type is
		'differing
		if defaultProvided
			if slottype = NET_TYPE_FLOAT32
				Return _float
			else
				Return defaultValue
			endif
		else
			Assert slottype = NET_TYPE_FLOAT32, "Wrong slot type. No FLOAT but "+slottype
			Return _float
		endif
	End Method

	Method GetString:string(defaultValue:string="", defaultProvided:int=FALSE)
		'float/int/string don't have real NULL, so we have to rely on
		'defaultProvided
		'if a defaultValue is set, return it as long as field type is
		'differing
		if defaultProvided
			if slottype = NET_TYPE_STRING
				Return _string
			else
				Return defaultValue
			endif
		else
			Assert slottype = NET_TYPE_STRING, "Wrong slot type. No STRING but "+slottype
			Return _string
		endif
	End Method
End Type




Type TNetworkMessage
	Field id:int
	Field state:int
	Field evType:int
	Field data:Byte[]

	Function Create:TNetworkMessage(id:int, state:int, evType:int, data:byte[])
		local obj:TNetworkMessage = new TNetworkMessage
		obj.id = id
		obj.state = state
		obj.evType= evType
		obj.data = data
		return obj
	End Function
End Type



Type TNetworkConnection
	'ip of remote peer
	Field ip:int
	'port of remote peer
	Field port:int
	Field link:TLink
	Field connected:Int
	Field joined:Int = 0
	Field channels:Int = 16
	Field enetpeer:Byte Ptr
	Field enethost:Byte Ptr
	Field pingpeer:Byte Ptr
	Global PacketID:int = 0


	Function GetUniqueID:int()
		PacketID:+1
		return PacketID
	End Function


	Method Delete()
		Free()
	End Method


	Method Free()
		If enethost
			enet_host_destroy(enethost)
			enethost = Null
		EndIf

		If link
			link.remove()
			link = Null
		EndIf
	End Method


	Method GetIP:int()
		return self.ip
	End Method
	

	Method GetDottedIP:string()
		'return DottedIP(ip)
		return TDigNetwork.GetDottedIP(ip)
	End Method


	'fetch all packets
	Method Update()
		local ev:ENetEvent = New ENetEvent
		local id:int
		local packet:TNetworkPacket = null

		If Not Self.enethost
			RuntimeError "Can't update a remote server."
			return
		endif
		
		Repeat
			If not enet_host_service(Self.enethost, ev, 0) then exit

			Select ev.event
				Case ENET_EVENT_TYPE_CONNECT
					id=NET_CONNECT
				Case ENET_EVENT_TYPE_DISCONNECT
					id=NET_DISCONNECT
				Case ENET_EVENT_TYPE_RECEIVE
					local obj:TNetworkObject
					Local size:Int=enet_packet_size(ev.packet)
					Local data:Byte[size]
					If size
						packet=New TNetworkPacket
						packet._bank.resize(size)
						MemCopy(packet._bank.buf(),enet_packet_data(ev.packet),size)

						obj = TNetworkObject.FromPacket(packet)
						id = obj.evType
					EndIf

				Default
					Continue

			EndSelect
			EvaluateEvent(id,packet,ev.peer)

			'this is not the same!!!
			'If not self.enethost then Exit
			If self.enethost=Null then Exit
		Forever
	End Method
	

	Function ConvertEvent:Int(ev:EnetEvent,packet:TNetworkPacket)
		Select ev.event
			Case ENET_EVENT_TYPE_CONNECT
				Return NET_CONNECT
			Case ENET_EVENT_TYPE_DISCONNECT
				Return NET_DISCONNECT
			Case ENET_EVENT_TYPE_RECEIVE
				If ev.packet
					Local size:Int=enet_packet_size(ev.packet)
					If size
						packet._bank.resize(size)
						MemCopy(packet._bank.buf(),enet_packet_data(ev.packet),size)
					EndIf
					enet_packet_destroy(ev.packet)
					local obj:TNetworkObject = TNetworkObject.FromPacket(packet)
					return obj.evType
					'Return id
				EndIf
		EndSelect
	EndFunction


	Method EvaluateEvent(evType:Int,packet:TNetworkPacket,enetpeer:Byte Ptr) abstract
rem without rem geany bugs display of source code
	end Method
endRem

End Type
