Const NET_PACKET_RELIABLE:int	= 1
CONST NET_PACKET_HEADER:int		= 1317

'message states
Const NET_STATE_ALL:int			= 0
Const NET_STATE_CREATED:int		= 1
Const NET_STATE_MODIFIED:int	= 2
Const NET_STATE_CLOSED:int		= 3
Const NET_STATE_SYNCED:int		= 4
Const NET_STATE_MESSAGE:int		= 5
Const NET_STATE_FOREVER:int		= 6
Const NET_STATE_ZOMBIE:int		=-1
'types
Const NET_TYPE_STRING:int		= 1
Const NET_TYPE_INT:int			= 2
Const NET_TYPE_UINT8:int		= 3
Const NET_TYPE_UINT16:int		= 4
Const NET_TYPE_FLOAT16:int		= 5
Const NET_TYPE_FLOAT32:int		= 6

'packets
Const NET_ACK:Int					= 1					' ALL: ACKnowledge
Const NET_JOIN:Int					= 2					' ALL: Join Attempt
Const NET_PING:Int					= 3					' Ping
Const NET_PONG:Int					= 4					' Pong
Const NET_UPDATE:Int				= 5					' Update
Const NET_STATE:Int					= 6					' State update only
Const NET_QUIT:Int					= 7					' ALL:    Quit
Const NET_ANNOUNCEGAME:Int			= 8					' SERVER: Announce a game
Const NET_SETSLOT:Int				= 9					' SERVER: command from server to set to a given playerslot
Const NET_SLOTSET:Int				= 10				' ALL: 	  response to all, that IP uses slot X now
Const NET_PLAYERLIST:Int			= 11				' SERVER: List of all players in our game
Const NET_CHATMESSAGE:Int			= 12				' ALL:    a sent chatmessage ;D
Const NET_PEERDATA:Int				= 13				' Packet contains IPs of all four Players/peers
Const NET_PLAYERDETAILS:Int			= 14				' ALL:    name, channelname...
Const NET_PLAYERPOSITION:Int		= 15				' ALL:    x,y,room,target...
Const NET_SENDPROGRAMME:Int			= 16				' SERVER: sends a Programme to a user for adding this to the players collection
Const NET_GAMEREADY:Int				= 17				' ALL:    sends a ReadyFlag
Const NET_STARTGAME:Int				= 18				' SERVER: sends a StartFlag
Const NET_PLAN_PROGRAMMECHANGE:Int	= 19				' ALL:    playerprogramme has changed (added, removed and so on)
Const NET_STATIONCHANGE:Int			= 20				' ALL:    stations have changes (added ...)
Const NET_ELEVATORROUTECHANGE:Int	= 21				' ALL:    elevator routes have changed
Const NET_ELEVATORSYNCHRONIZE:Int	= 22				' SERVER: synchronizing the elevator
Const NET_PLAN_ADCHANGE:Int			= 23				' ALL:    playerprogramme has changed (added, removed and so on)
Const NET_SENDCONTRACT:Int			= 24				' SERVER: sends a Contract to a user for adding this to the players collection
Const NET_PROGRAMMECOLLECTION_CHANGE:Int = 25			' ALL:    programmecollection was changed (removed, sold...)
Const NET_SENDNEWS:Int				= 26				' SERVER: creates and sends news
Const NET_NEWSSUBSCRIPTIONLEVEL:Int	= 27				' ALL: sends Changes in subscription levels of news-agencies
Const NET_PLAN_NEWSCHANGE:Int		= 28				' ALL: sends Changes of news in the players newsstudio
Const NET_MOVIEAGENCY_CHANGE:Int	= 29				' ALL: sends changes of programme in movieshop

Const NET_DELETE:Int				= 0
Const NET_ADD:Int					= 1000
Const NET_CHANGE:Int				= 2000
Const NET_BUY:Int					= 3000
Const NET_SELL:Int					= 4000
Const NET_BID:Int					= 5000
Const NET_SWITCH:Int				= 6000



'--from gnet.bmx
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
		For local i:int = 0 To 9          'find the leading 1-bit
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
'--

Type TNetworkObject
	field sender:int
	field receiver:int
	field data:byte[]
	field state:int
	field evType:int
	field id:int
	Field slots:TNetworkObjectSlot[32]
	field modified:int
	field target:object 'remote ?
	field reliable:int = 0		'sync packets reliable?

	Method new()
		For Local i:int = 0 Until 32
			self.slots[i] = New TNetworkObjectSlot
		Next
	End Method

	Function Create:TNetworkObject( id:int,state:int, evType:int, sender:int = null, receiver:int = null, reliable:int=0 )
		Local obj:TNetworkObject=New TNetworkObject
		obj.id		= id
		obj.state	= state
		obj.evType	= evType
		obj.sender	= sender
		obj.receiver= receiver
		obj.reliable= reliable
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

	Method GetInt:int( index:int, defaultValue:int=null )
		Return slots[index].GetInt( defaultValue )
	End Method

	Method GetFloat:float( index:int, defaultValue:float=null )
		Return slots[index].GetFloat( defaultValue )
	End Method

	Method GetString:string( index:int, defaultValue:string=null)
		Return slots[index].GetString( defaultValue )
	End Method

	Method WriteSlot:TNetworkObjectSlot( index:int )
		Assert state<>NET_STATE_CLOSED And state<>NET_STATE_ZOMBIE Else "Object has been closed"
		modified :|1 Shl index
		If state = NET_STATE_SYNCED OR NET_STATE_FOREVER then state=NET_STATE_MODIFIED
		Return slots[index]
	End Method

	Method Sync:TNetworkMessage()
		Select state
			Case NET_STATE_SYNCED, NET_STATE_ZOMBIE 	Return null
		End Select

		Local msg:TNetworkMessage = new TNetworkMessage

		'local
		If Not receiver OR receiver = 255
			msg.id		= id
			msg.state	= state
			msg.evType	= evType
			msg.reliable= reliable
			msg.data	= PackSlots( modified )
		EndIf

		modified=0

		Select state
			Case NET_STATE_CREATED,NET_STATE_MODIFIED
				state=NET_STATE_SYNCED
			Case NET_STATE_CLOSED
				target=Null
				state=NET_STATE_ZOMBIE
		End Select
		Return msg
	End Method

	Function CreateTemporary:TNetworkObject(msg:TNetworkMessage, reliable:int = 0)
		local obj:TNetworkObject = new TNetworkObject
		obj.id			= msg.id
		obj.reliable	= reliable
		obj.Update(msg)
		return obj
	End Function


	Method Update( msg:TNetworkMessage )
		Assert id=msg.id
		self.UnpackSlots(msg.data)
		state = msg.state
	End Method

	Method CreateMessage:TNetworkMessage(messageType:int=0)
		select messageType
			case NET_STATE_CREATED, NET_STATE_MESSAGE
					return TNetworkMessage.Create(id, messageType, evType, PackSlots( ~0 ))
			case NET_STATE_CLOSED
					return TNetworkMessage.Create(id, messageType, evType, PackSlots( 0 ))
		end select
	End Method

	Method PackSlots:Byte[]( mask:int )
		Local size:int
		For Local index:int = 0 Until 32
			If Not (mask & 1 Shl index) then Continue
			Select slots[index].slottype
				Case false, 0			continue
				Case NET_TYPE_INT		size:+5
				Case NET_TYPE_UINT8		size:+2
				Case NET_TYPE_UINT16	size:+3
				Case NET_TYPE_FLOAT16	size:+3
				Case NET_TYPE_FLOAT32	size:+5
				Case NET_TYPE_STRING	size:+3+GetString(index).length
			End Select
		Next
		If size>$fff0 Throw "NetworkMessage data too large"
		Local data:Byte[size]
		Local p:Byte Ptr=data
		For Local index:int = 0 Until 32
			If Not (mask & 1 Shl index) Continue
			Select slots[index].slottype
				Case false, 0			continue
				Case NET_TYPE_INT		Local n:int = GetInt( index )
										p[0]=NET_TYPE_INT Shl 5 | index
										p[1]=n Shr 24
										p[2]=n Shr 16
										p[3]=n Shr 8
										p[4]=n Shr 0
										p:+5
				Case NET_TYPE_UINT8		Local n:int = GetInt( index )
										p[0]=NET_TYPE_UINT8 Shl 5 | index
										p[1]=n
										p:+2
				Case NET_TYPE_UINT16	Local n:int = GetInt( index )
										p[0]=NET_TYPE_UINT16 Shl 5 | index
										p[1]=n Shr 8
										p[2]=n Shr 0
										p:+3
				Case NET_TYPE_FLOAT16	Local n:int = PackFloat16( GetFloat(index) )
										p[0]=NET_TYPE_FLOAT16 Shl 5 | index
										p[1]=n Shr 8
										p[2]=n Shr 0
										p:+3
				Case NET_TYPE_FLOAT32	Local n:int = PackFloat32( GetFloat(index) )
										p[0]=NET_TYPE_FLOAT32 Shl 5 | index
										p[1]=n Shr 24
										p[2]=n Shr 16
										p[3]=n Shr 8
										p[4]=n Shr 0
										p:+5
				Case NET_TYPE_STRING	Local data:string =GetString( index )
										Local n:int=data.length
										p[0]=NET_TYPE_STRING Shl 5 | index
										p[1]=n Shr 8
										p[2]=n Shr 0
										Local t:Byte Ptr=data.ToCString()
										MemCopy p+3,t,n
										MemFree t
										p:+3+n
				Default					Throw "Invalid TNetworkObjectSlot data type"
			End Select
		Next
		Return data
	End Method

	Method UnpackSlots( data:Byte[] )
		Local p:Byte Ptr=data
		Local e:Byte Ptr=p+data.length
		While p<e
			Local typ:int=p[0] Shr 5
			Local index:int =p[0] & 31
			p:+1
			Select typ
				Case NET_TYPE_INT		SetInt index,p[0] Shl 24 | p[1] Shl 16 | p[2] Shl 8 | p[3]
										p:+4
				Case NET_TYPE_UINT8		SetInt index,p[0]
										p:+1
				Case NET_TYPE_UINT16	SetInt index,p[0] Shl 8 | p[1]
										p:+2
				Case NET_TYPE_FLOAT16	SetFloat index, UnpackFloat16( p[0] Shl 8 | p[1] )
										p:+2
				Case NET_TYPE_FLOAT32	SetFloat index, UnpackFloat32( p[0] Shl 24 | p[1] Shl 16 | p[2] Shl 8 | p[3] )
										p:+4
				Case NET_TYPE_STRING	local length:int = p[0] Shl 8 | p[1]
										SetString index, String.FromBytes( p+2, length )
										p:+2 +length
				Default					Throw "Invalid NetworkObjectSlot data type"
			End Select
		Wend
		If p<>e Throw "Corrupt NetworkObject message"
	End Method
End Type

Type TNetworkObjectSlot
	Field slottype:int
	Field _int:int
	Field _float:float
	Field _string:string

	Method SetInt( data:int )
		if data = null then return
		Assert slottype = 0 Or slottype=NET_TYPE_INT Or slottype=NET_TYPE_UINT8 Or slottype=NET_TYPE_UINT16
		_int=data
		If data<0
			slottype=NET_TYPE_INT
		Else If data<=255
			slottype=NET_TYPE_UINT8
		Else If data<=65535
			slottype=NET_TYPE_UINT16
		Else
			slottype=NET_TYPE_INT
		EndIf
	End Method

	Method SetFloat( data:float )
		if data = null then return
		Assert slottype=0 Or slottype=NET_TYPE_FLOAT32
		_float	= data
		slottype= NET_TYPE_FLOAT32
	End Method

	Method SetString( data:string )
		if data = null then return
		Assert slottype=0 Or slottype=NET_TYPE_STRING
		_string	= data
		slottype= NET_TYPE_STRING
	End Method

	Method GetInt:int(defaultValue:int=0)
		Assert slottype=NET_TYPE_INT Or slottype=NET_TYPE_UINT8 Or slottype=NET_TYPE_UINT16
		Return _int
	End Method

	Method GetFloat:float(defaultValue:float=0.0)
		Assert slottype = NET_TYPE_FLOAT32
		Return _float
	End Method

	Method GetString:string(defaultValue:string="")
		Assert slottype = NET_TYPE_STRING
		Return _string
	End Method

End Type


Type TNetworkMessage
	Field id:int
	Field state:int
	Field evType:int
	Field reliable:int = 0
	Field data:Byte[]

	Function Create:TNetworkMessage(id:int, state:int, evType:int, data:byte[], reliable:int = 0)
		local obj:TNetworkMessage = new TNetworkMessage
		obj.id = id
		obj.state = state
		obj.evType= evType
		obj.data = data
		obj.reliable = reliable
		return obj
	End Function
End Type

'all players wo take part in a game
Type TNetworkPeer
	field ip:int							'ip of remote peer
	field port:int							'port of remote peer
	Field playerID:int
	Field ping:int = 0
	Field pingTime:int = 0

	Function Create:TNetworkPeer(ip:int, port:int, playerID:int=-1)
		local obj:TNetworkPeer = new TNetworkPeer
		obj.ip			= ip
		obj.port		= port
		obj.playerID	= playerID
		return obj
	End Function

	Method GetPlayerID:int()
		return playerID
	End Method

	Method GetIP:int()
		return self.ip
	End Method

	Method GetDottedIP:string()
		return TNetwork.stringIP(self.ip)
	End Method

	Method SendNetworkMessage( msg:TNetworkmessage )
		Network.SendNetworkMessageToIP( msg, ip, port)
	End Method

End Type

Type TNetworkPacket
	field msg:TNetworkMessage
	field reliable:int
	field IP:Int
	field Port:Int

	Global sent:TList = CreateList()
	Global received:TList = CreateList()

	function Create:TNetworkPacket(msg:TNetworkMessage, ip:int, port:int, isReceivedPacket:int = 0)
		local obj:TNetworkPacket = new TNetworkPacket
		if msg = null then return null
		obj.msg		= msg
		obj.ip		= ip
		obj.port	= port
		obj.reliable= msg.reliable
		if isReceivedPacket then obj.received.addLast(obj) else obj.sent.addLast(obj)
		return obj
	End function
End Type


'base of all networkevents...
'added to the base networking functions are all methods to send and receive data from clients
'including playerposition, programmesending, changes of elevatorpositions etc.
Type TTVGNetwork
	' // Network Specific Declares
	Field isServer:int				= False    				' Are you hosting or joining?
	Field IsConnected:int			= False   				' Are you connected?

	field host:TNetworkPeer			= new TNetworkPeer		' my ip/port

	Field Stream:TUDPStream      							' UDP Stream
	Field PingTimer:Int =0  ' Ping and Ping Timer
	Field UpdateTime:Int         							' Update Timer
	Field MainSyncTime:Int       							' Main Update Timer
	Field AnnounceTime:Int       							' Main Announcement Timer
	Global ObjID:int, SendID%, RecvID%, lastRecv:Int[52] 				' Packet IDs and Duplicate checking Array

'myID is now in TNetworkPeer.playerID
'	Field MyID:Int 					= -1					' which playernumber is mine? - so which line of the iparray and so on
'	Field IP:int[4], Port:Int[4] 							' Client IP and Port
	Field debugmode:Byte			= True					' Toggles the display of debug messages
	Field bSentFull:Byte         							' Full update boolean
	Field n:NetObj, netList:TList = New TList	 			' Packet Object and List
	Field LastOnlineRequestTimer:Int	= 0
	Field LastOnlineRequestTime:Int		= 10000   			'time until next action (getlist, announce...)
	Field LastOnlineHashCode:String		= ""
	Field OnlineIP:String				= ""                ' ip for internet
	Field intOnlineIP:Int				= 0					' int version of ip for internet
	Field ChatSpamTime:Int				= 0					' // Networking Constants
	Global LOCALPORT:int				= 4544

	Global MyStream:TStream				= New TStream
	Global MyBank:TBank					= New TBank
	Global BackupStreamPtr:Byte Ptr
	Global BackupStreamSize:Int = 0

	Field MaxPeers:int = 4
	field peers:TList	= CreateList()						' List of connected peers
	Field objects:TList = CreateList()						' List of hold TNetworkObjects

	?Linux
	Global LastBroadcastIP:int = 0
	?
	Global intBroadcastIP:int			= 0					' only for lan

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

	Method BackupStream(toBank:TBank)
		If BackupStreamSize > 0 Then MemFree(BackupStreamPtr)
		BackupStreamPtr = MemAlloc(stream.SendSize)
		BackupStreamSize= stream.SendSize
		If BackupStreamSize > 0 Then
			MemCopy(BackupStreamPtr, stream.SendBuffer, BackupStreamSize)
	    EndIf
	End Method

	Method RestoreStream(fromBank:TBank)
	    If BackupStreamSize >0 Then
		  MemCopy(stream.SendBuffer, BackupStreamPtr, BackupStreamSize)
		  stream.SendSize = BackupStreamSize
	    End If
	End Method

	Method GetUniqueID:int()
		ObjID:+1
		return ObjID
	End Method

	Method GetSendID:int()
		SendID:+1
		return SendID
	End Method

	Method Init:int(fallbackip:String)
		If host.ip = 0
			?not linux
			host.ip		= TNetwork.GetHostIP("")
			?
			?linux
'			Network.host.ip	= TNetwork.GetHostIP("eth0")
			host.ip	= TNetwork.GetHostIP("")
			?
		endif

		If host.ip = 0
			print "NET: using fallback IP " +fallbackip
			host.ip	= TNetwork.IntIP(fallbackip)
		EndIf
		self.removePeers()

		Network.host.port		= Game.userport
'		Network.host.playerID	= 1
		self.addPeer(self.host)
	End Method

	Method GetFreeSlot:Int()
		'4 = max peers
		return Max(0, 4-self.peers.count())
	End Method

	Method GetObjects:TList()
		return self.objects
	End Method

	Method FindPeerByIP:TNetworkPeer(ip:int, port:int, createIfNotFound:int = false)
		for local peer:TNetworkPeer = eachin self.peers
			if peer.ip = ip and peer.port = port then return peer
		Next
		if createIfNotFound then return TNetworkPeer.Create(ip, port)
		return null
	End Method


	Function GetBroadcastIPs:int[](intIP:int)
		local ip:string = DottedIP(intIP)
		If Len(ip$)>6
			ip$=ip$
			Local lastperiod:Int=1
			Local period:Int =0
			For Local t:Int=1 To 3				    '; 4 Zahlengruppen, aber die letzte muss weg
				period=Instr(ip,".",lastperiod)
				lastperiod=period+1
			Next
			local ip:string = Left(ip,period)
			local ips:int[254]
			for local i:int = 1 to 254 '255 is broadcast itself
				ips[i-1] = TNetwork.intIP(ip+i)
			Next

			return ips
		Else
			Return null
		EndIf
	End Function

	Function GetBroadcastIP:String(intIP:int)
		local ip:string = DottedIP(intIP)
		If Len(ip$)>6
			ip$=ip$
			Local lastperiod:Int=1
			Local period:Int =0
			For Local t:Int=1 To 3				    '; 4 Zahlengruppen, aber die letzte muss weg
				period=Instr(ip,".",lastperiod)
				lastperiod=period+1
			Next
			local res:string = Left(ip,period)+"255"
			TTVGNetwork.intBroadcastIP = TNetwork.intIP(res)
			return res
		Else
			TTVGNetwork.intBroadcastIP = 0
			Return ""
		EndIf
	End Function

	'if just a event has to be send
	Method CreateSimpleMessage(evType:int)
		TNetworkMessage.Create(GetUniqueID(), NET_STATE_MESSAGE, evType, null)
	End Method

	Method CreateSimplePacket:TNetworkObject(evType:int, reliable:int=0)
		return TNetworkObject.Create(GetUniqueID(), NET_STATE_FOREVER, evType, null, 255, reliable)
	End Method

	'modier of sync speed
	Method GetSyncSpeedFactor:float()
		If game.onlinegame Then return 1.0 else return 0.5
	End Method

  Method GetMyIP:Int()
	If Game.onlinegame Then Return intOnlineIP else Return host.port
  End Method

  Method GetMyPort:Int()
	If Game.onlinegame Then Return host.port else return LOCALPORT
  End Method

	'sends to all
	Method SendPing()
		for local peer:TNetworkPeer = eachin self.peers
			peer.pingTime = MilliSecs()
		Next
		PingTimer = MilliSecs()

		'print "send ping to all"
		local obj:TNetworkObject = self.CreateSimplePacket(NET_PING, not NET_PACKET_RELIABLE)
		obj.setInt(1, Game.PlayerID)
		self.BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	'respond to ping sender
	Method SendPong(peer:TNetworkPeer)
		'print "send pong to peer "+TNetwork.DottedIP(peer.ip)
		local obj:TNetworkObject = self.CreateSimplePacket(NET_PONG, not NET_PACKET_RELIABLE)
		obj.setInt(1, Game.PlayerID)
		peer.SendNetworkMessage( obj.sync() )
	End Method


	Method SendChatMessage(ChatMessage:String = "")
		local obj:TNetworkObject = self.CreateSimplePacket(NET_CHATMESSAGE, NET_PACKET_RELIABLE)
		obj.setInt(1, Game.PlayerID)
		obj.setString(2, ChatMessage)
		self.BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	Method SendPeerData()
		if not self.isServer then return
		'set all players computer controlled (eg if one lost connection)
		for local i:int = 1 to 4
			Players[i].Figure.ControlledByID = 0
		Next

		local obj:TNetworkObject = self.CreateSimplePacket(NET_PEERDATA, NET_PACKET_RELIABLE)
		obj.setInt(1, self.peers.count())
		local peerNumber:int = 0
 		for local peer:TNetworkPeer = eachin self.peers
			if PeerNumber < MaxPeers 'max 4 peers
				'begin with 4 +1
				obj.setInt(peerNumber*4+2, peerNumber)
				obj.setInt(peerNumber*4+3, peer.ip)
				obj.setInt(peerNumber*4+4, peer.port)
				obj.setInt(peerNumber*4+5, peer.playerID)
				print "peer "+(peerNumber+1)+" "+dottedIP(peer.ip)+":"+peer.port+" hat playerID " + peer.playerID
				local player:TPlayer = TPlayer.getByID( peer.playerID )
				if player <> null then player.Figure.ControlledByID = peer.PlayerID
'				else
'					print "peer "+peerNumber+" has unassigned playerID id:"+peer.playerID
'				endif

			else
				exit
			endif
			peerNumber:+1
		Next
		BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	Method SendGameAnnouncement()
		if GetFreeSlot() = 0 then return

		local obj:TNetworkObject = self.CreateSimplePacket(NET_ANNOUNCEGAME, not NET_PACKET_RELIABLE)
		If Game.gamestate = 0 then return 'no announcement when already in game
		If Not Game.onlinegame
			'Print "NET: announcing a LAN game to " +GetBroadcastIP(host.ip)
			obj.setInt(1, GetFreeSlot())
			obj.setString(2, Game.title)
			self.BroadcastNetworkMessageToLan( obj.sync() )
		Else
			Print "NET: announcing a ONLINE game "
			Local Onlinestream:TStream = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=AddGame&Titel="+UrlEncode(Game.title)+"&IP="+OnlineIP+"&Port="+host.port+"&Spieler="+Self.getFreeSlot()+"&Hashcode="+LastOnlineHashCode)
			Local timeouttimer:Int = MilliSecs()+5000 '5 seconds okay?
			Local timeout:Byte = False
			If Not Onlinestream Then Throw ("Not Online?")

			While Not Eof(Onlinestream) Or timeout
				If timeouttimer < MilliSecs() Then timeout = True
				Local responsestring:String = ReadLine(Onlinestream)
				If responsestring <> Null AND responsestring <> "UPDATEDGAME" Then LastOnlineHashCode = responsestring
			Wend
			CloseStream Onlinestream
		EndIf
  End Method

	Method SendPlayerDetails:Byte()
'		print "Send Player Details to all but me ("+TNetwork.dottedIP(host.ip)+")"
		'send packets indivual - no need to have multiple entities in one packet
		for local player:TPlayer = eachin TPlayer.list
			'it's me or i'm hosting and its an AI player
			if player.playerID = host.playerID OR (isServer and Player.isAI())
				'Print "NET: send playerdetails of ME and IF I'm the host also from AI players"

				'if not isServer then
				print host.playerID +" send player details: playerid="+player.playerID+" color="+Player.color.toInt()+" figurebase="+Player.figurebase
				local obj:TNetworkObject = self.CreateSimplePacket(NET_PLAYERDETAILS, not NET_PACKET_RELIABLE)
				obj.SetInt(	1, player.playerID )
				obj.SetString( 2, Player.name )			'name
				obj.SetString( 3, Player.channelname )	'...
				obj.SetInt(	4, Player.color.toInt() )
				obj.SetInt(	5, Player.figurebase )
				BroadcastNetworkMessage( obj.sync(), self.host)
			EndIf
		Next
	End Method

	Method SendPlayerPosition()
		Print "NET: send playerposition of SELF (hosting: AI players too)"

		For Local i:Int = 1 To 4
			'it's me or i'm hosting and its an AI player
			if i = host.playerID OR (isServer and Players[i].isAI())
				local obj:TNetworkObject = self.CreateSimplePacket(NET_PLAYERPOSITION, not NET_PACKET_RELIABLE)
				obj.SetInt(	1, i )						'playerID
				obj.SetInt(	2, Players[i].Figure.pos.x )	'pos.x
				obj.SetInt(	3, Players[i].Figure.pos.y )	'...
				obj.SetInt(	4, Players[i].Figure.target.x )
				obj.SetInt(	5, Players[i].Figure.target.y )
				if Players[i].Figure.inRoom <> null 			then obj.setInt( 6, Players[i].Figure.inRoom.uniqueID)
				if Players[i].Figure.clickedToRoom <> null	then obj.setInt( 7, Players[i].Figure.clickedToRoom.uniqueID)
				if Players[i].Figure.toRoom <> null 			then obj.setInt( 8, Players[i].Figure.toRoom.uniqueID)
				if Players[i].Figure.fromRoom <> null 		then obj.setInt( 9, Players[i].Figure.fromRoom.uniqueID)
				self.BroadcastNetworkMessage( obj.sync(), self.host)
				Print "sent position of player:"+i
			EndIf
		Next
	End Method

	Method AddProgrammesToPlayer(playerID:Int, programme:TProgramme[])
		local obj:TNetworkObject = self.CreateSimplePacket(NET_SENDPROGRAMME, NET_PACKET_RELIABLE)
		obj.setInt(1, playerID)

		'store in one field
		local IDstring:string=""
		For Local i:Int = 0 To programme.length-1
			IDstring :+ programme[i].id+","
		Next
		obj.setString(2, IDstring)

		BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	Method SendMovieAgencyChange(methodtype:int, playerID:Int, newID:Int=-1, slot:Int=-1, programme:TProgramme)
		local obj:TNetworkObject = self.CreateSimplePacket(NET_MOVIEAGENCY_CHANGE, NET_PACKET_RELIABLE)
		obj.setInt(1, playerID)
		obj.setInt(2, methodtype)
		obj.setInt(3, newid)
		obj.setInt(4, slot)
		obj.setInt(5, programme.id)
		BroadcastNetworkMessage( obj.sync(), self.host )
		Print "send newID"+newID
	End Method

	Method SendGameReady(playerID:Int, onlyTo:Int=-1)
		local obj:TNetworkObject = Self.CreateSimplePacket(NET_GAMEREADY, NET_PACKET_RELIABLE)
		obj.setInt(1, playerID)
		local msg:TNetworkMessage = obj.sync()

		for local peer:TNetworkPeer = eachin self.peers
			if onlyTo < 0 OR peer.playerID = onlyTo
				peer.SendNetworkMessage( msg )
			EndIf
		Next
		Print "NET: sent GameReadyFlag (my PlayerID: "+playerID+")"
	End Method

	Method SendGameStart()
		print "send game start to all (also me)"
		self.BroadcastNetworkMessage( Self.CreateSimplePacket( NET_STARTGAME, NET_PACKET_RELIABLE).sync() )
	End Method

	'add = 1 - added, add = 0 - removed
	Method SendPlanProgrammeChange(playerID:Int, block:TProgrammeBlock, add:int=1)
		local obj:TNetworkObject = self.CreateSimplePacket( NET_PLAN_PROGRAMMECHANGE, NET_PACKET_RELIABLE)
		obj.setInt(1, playerID)
		obj.setInt(2, add)
		obj.setInt(3, block.id)
		obj.setFloat(4, block.Pos.x)
		obj.setFloat(5, block.Pos.y)
		obj.setFloat(6, block.StartPos.x)
		obj.setFloat(7, block.StartPos.y)
		obj.setInt(8, block.sendhour)
		obj.setInt(10, block.Programme.id)
		self.BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	Method AddContractsToPlayer(playerID:Int, contract:TContract[])
		local obj:TNetworkObject = self.CreateSimplePacket(NET_SENDCONTRACT, NET_PACKET_RELIABLE)
		obj.setInt(1, playerID)

		'store in one field
		local IDstring:string=""
		For Local i:Int = 0 To contract.length-1
			IDstring :+ contract[i].id+","
		Next
		obj.setString(2, IDstring)

		BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	Method SendPlanAdChange(playerID:Int, block:TAdBlock, add:int=1)
		local obj:TNetworkObject = self.CreateSimplePacket( NET_PLAN_ADCHANGE, NET_PACKET_RELIABLE)
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
		self.BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	Method SendStationChange(playerID:Int, station:TStation, newaudience:Int, add:int=1)
		local obj:TNetworkObject = self.CreateSimplePacket( NET_STATIONCHANGE, NET_PACKET_RELIABLE)
		obj.setInt(1, playerID)
		obj.setInt(2, add)
		obj.setFloat(3, station.Pos.x)
		obj.setFloat(4, station.Pos.y)
		obj.setInt(5, station.reach)
		obj.setInt(6, station.price)
		obj.setInt(7, newaudience)
		self.BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	Method SendNewsSubscriptionLevel(playerID:Int, genre:int, level:int)
		local obj:TNetworkObject = self.CreateSimplePacket( NET_NEWSSUBSCRIPTIONLEVEL, NET_PACKET_RELIABLE)
		obj.setInt(1, playerID)
		obj.setInt(2, genre)
		obj.setInt(3, level)
		self.BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	Method SendNews(playerID:Int, news:TNews)
		local obj:TNetworkObject = self.CreateSimplePacket( NET_SENDNEWS, NET_PACKET_RELIABLE)
		obj.setInt(1, playerID)
		obj.setInt(2, news.id)
		self.BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	'add = 1 - added, add = 0 - removed
	Method SendPlanNewsChange(playerID:Int, block:TNewsBlock, remove:int=0)
		local obj:TNetworkObject = self.CreateSimplePacket( NET_PLAN_NEWSCHANGE, NET_PACKET_RELIABLE)
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
		self.BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	Method GotPacket_SendMovieAgencyChange(_IP:Int, _Port:int)
    Local RemotePlayerID:Int 	= ReadByte(stream)
	Local methodtype:Byte 		= ReadByte(stream)
	Local newid:Int 			= ReadInt (stream)
	Local slot:Int 				= ReadInt (stream)
    Local IsMovie:Byte 			= ReadByte(stream)
    Local ProgrammeID:Int		= ReadInt (stream)
	Local tmpID:Int = -1
	Local oldX:Int, oldY:Int
    Select methodtype
		Case NET_SWITCH
				Local tmpBlock:TMovieAgencyBlocks[3]
				For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			      If locobject.Programme <> Null
				    If locobject.Programme.id = ProgrammeID then tmpBlock[0] = locObject
				    If locobject.Programme.id = newID then tmpBlock[1] = locObject
				  EndIf
			    Next
				'Print "had to switch ID"+ProgrammeID+ " with ID"+newID+"/"+tmpBlock[1].programme.id
				If tmpBlock[0] <> Null And tmpBlock[1] <> Null
					tmpBlock[0].SwitchBlock(tmpBlock[1])
				EndIf
		Case NET_BUY
				For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			      If locobject.Programme <> Null
				    If locobject.Programme.id = ProgrammeID
					  Players[ RemotePlayerID ].ProgrammeCollection.AddProgramme(TProgramme.GetProgramme(ProgrammeID))
					  locObject.Programme = TProgramme.GetProgramme(newID)
					EndIf
				  EndIf
			    Next
		Case NET_BID
				For Local locObj:TAuctionProgrammeBlocks  = EachIn TAuctionProgrammeBlocks.List
			      If locobj.Programme <> Null
				    If locobj.Programme.id = ProgrammeID
					  locObj.SetBid(RemotePlayerID, newID) 'newID = nextBid
					EndIf
				  EndIf
			    Next

		Default Print "SendMovieAgencyChange: no method mentioned"
    End Select
'    If isMovie Then Players[ RemotePlayerID ].ProgrammeCollection.AddMovie(TProgramme.GetMovie(ProgrammeID))
'    If Not isMovie Then Players[ RemotePlayerID ].ProgrammeCollection.AddSerie(TProgramme.GetSeries(ProgrammeID))
  End Method

  Method GotPacket_Plan_NewsChange(_IP:Int, _Port:Int)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local remove:Int = ReadInt(Stream)
    Local x:Int = ReadInt(Stream)
    Local y:Int = ReadInt(Stream)
    Local startrectx:Int = ReadInt(Stream)
    Local startrecty:Int = ReadInt(Stream)
    Local newsblockID:Int = ReadInt(stream)
    Local paid:Int = ReadInt(stream)
    Local newsID:Int = ReadInt(stream)
    Local sendslot:Int = ReadInt(stream)

	Local newsblock:TNewsblock = Players[RemotePlayerID].ProgrammePlan.getNewsBlock(newsblockID)
    If newsblock <> Null Then
		if remove then Players[RemotePlayerID].ProgrammePlan.removeNewsBlock(newsBlock)
		If Not newsblock.paid Then newsblock.Pay()
		newsblock.sendslot = sendslot
		newsblock.owner = RemotePlayerID
		newsblock.Pos.SetXY(x, y)
		newsblock.StartPos.SetXY(startrectx, startrecty)
	EndIf
 End Method

  Method GotPacket_NewsSubscriptionLevel(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(stream)
    Local genre:Int = ReadByte(stream)
    Local level:Int = ReadByte(stream)
    Players[ RemotePlayerID ].newsabonnements[genre] = level
	Print "set genre "+genre+" to level "+level+" for player "+RemotePlayerID
  End Method


  Method GotPacket_SendNews(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(stream)
    Local newsID:Int = ReadInt(stream)
	Local news:TNews = TNews.GetNews(newsID)
    If news <> Null
      TNewsBlock.Create("",0,-100, RemotePlayerID , 60*(3-Players[ RemotePlayerID ].newsabonnements[news.genre]), news)
      Print "net: added news (id:"+newsID+") to Player:"+RemotePlayerID
	Else
      Print "net: news to add NOT FOUND (id:"+newsID+") for Player:"+RemotePlayerID
	EndIf
  End Method

  Method GotPacket_ProgrammeCollectionChange(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local programmeID:Int = ReadInt(stream)
    Local isMovie:Byte = ReadByte(stream)
    Local typ:Byte = ReadByte(stream)
    Local programme:TProgramme = Null
    If     isMovie Then programme = TProgramme.GetMovie(programmeID)
    If Not isMovie Then programme = TProgramme.GetSeries(programmeID)
	If programme <> Null
        If typ = 2
			Players[ RemotePlayerID ].ProgrammeCollection.AddProgramme(Programme)
          TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, RemoteplayerID)
		EndIf
		If typ = 0
 	      Players[ RemotePlayerID ].finances[Game.getWeekday()].SellMovie(Programme.ComputePrice())
          TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, RemoteplayerID)
		EndIf
	    'remove from Plan (Archive - ProgrammeToSuitcase)
	    If typ = 1 Then Players[ RemotePlayerID ].ProgrammePlan.RemoveProgramme(programme)
        'remove from Collection (Archive - RemoveProgramme)
		If typ = 3 Then Players[ RemotePlayerID ].ProgrammeCollection.RemoveProgramme( programme )
    EndIf
 End Method

  Method GotPacket_ElevatorRouteChange(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local call:Int = ReadInt(Stream)
    Local floornumber:Int = ReadInt(Stream)
    Local who:Int = ReadInt(Stream)
    Local First:Int = ReadByte(Stream)
    Print "net: got floorroute:"+floornumber
    Building.Elevator.AddFloorRoute(floornumber, call, who, First, True)
    If First Then Building.Elevator.passenger = Players[ RemotePlayerID ].figure
  End Method

  Method GotPacket_ElevatorSynchronize(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(Stream)
	Local Sendtime:Float = ReadFloat(stream)
    Building.Elevator.upwards = ReadInt(stream)
    Building.Elevator.Pos.x = ReadFloat(stream)
    Local myY:Float = ReadFloat(stream)
    Building.Elevator.onFloor = ReadInt(stream)
    Building.Elevator.open = ReadInt(stream)
    Local passenger:Int = ReadInt(stream)
	'Building.Elevator.passenger = passenger
'    Building.Elevator.waitAtFloorTime = Readint(Stream)
'    Building.Elevator.waitAtFloorTimer = Readint(Stream)

'    If building.Elevator.onFloor <> building.Elevator.toFloor And Building.Elevator.open=0
'	  If Building.Elevator.upwards
'	    Building.Elevator.y = myY - (Building.Elevator.speed*(game.timeSinceBegin-SendTime))
'	  Else
'	    Building.Elevator.y = myY + (Building.Elevator.speed*(game.timeSinceBegin-SendTime))
 '     End If
'	Else
'	    Building.Elevator.y = myY
'	EndIf
	If Building.Elevator.passenger <> null Then Building.Elevator.Pos.y = myY
	Local FloorCount:Int = ReadInt(stream)
    building.Elevator.FloorRouteList.Clear()
    'Print "synchronizing elevator"
	If FloorCount > 0
		For Local i:Int = 0 To FloorCount-1
		Local call:Int = ReadInt(stream)
		Local direction:Int = ReadInt(stream)
		Local floornumber:Int = ReadInt(stream)
		Local who:Int = ReadInt(stream)
		Building.Elevator.AddFloorRoute(floornumber, call, who, False, True)
		Next
	EndIf
    'Print "----END synchronizing elevator"
  End Method

  Method GotPacket_StationChange(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local add:Byte = ReadByte(Stream)
    Local x:Int = ReadInt(Stream)
    Local y:Int = ReadInt(Stream)
    Local reach:Int = ReadInt(Stream)
    Local price:Int = ReadInt(Stream)
    Local newaudience:Int = ReadInt(Stream)
    If add
      Local station:TStation = TStation.Create(x,y,reach,price,remoteplayerID)
      Players[remoteplayerID].finances[Game.getWeekday()].PayStation(price)
      'Player[remoteplayerID].maxaudience = newaudience
      Players[remoteplayerID].maxaudience = StationMap.CalculateAudienceSum(remoteplayerID)
      StationMap.StationList.AddLast(station)
      Print "NET: ADDED station to Player:"+RemotePlayerID
    EndIf
 End Method

  Method GotPacket_Plan_AdChange(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local add:Byte = ReadByte(Stream)
    Local x:Int = ReadInt(Stream)
    Local y:Int = ReadInt(Stream)
    Local startrectx:Int = ReadInt(Stream)
    Local startrecty:Int = ReadInt(Stream)
    Local sendtime:Int = ReadInt(Stream)
    Local senddate:Int = ReadInt(Stream)
    Local AdblockID:Int = ReadInt(Stream)
    Local ContractID:Int = ReadInt(Stream)
    Local Adblock:TAdBlock = TAdBlock.getBlock(AdBlockID)
    If Adblock = Null
      Local Contract:TContract = Players[ RemotePlayerID ].ProgrammeCollection.getContract(ContractID)
      If contract <> Null Then
        Adblock = TAdblock.CreateDragged(Contract,RemotePlayerID)
        'Print "NET: CREATED NEW Adblock: "+contract.Title
        Adblock.dragged = 0
      Else
        Print "ERROR: NET: AdChange: contract not found"
      EndIf
    EndIf
    Adblock.senddate = senddate
    Adblock.sendtime = sendtime
    Adblock.contract.senddate = senddate
    Adblock.contract.sendtime = sendtime
	AdBlock.Pos.SetXY(x, y)
	AdBlock.StartPos.SetXY(startrectx, startrecty)
    'Print "NET: set adblock on new position: "+adblock.Title
    Players[ remotePlayerID ].ProgrammePlan.RefreshAdPlan(senddate)
    If add
      Players[ RemotePlayerID ].ProgrammePlan.AddContract(adblock.contract)
      'Print "NET: ADDED adblock:"+Adblock.Title+" to Player:"+RemotePlayerID
    Else
      Players[ RemotePlayerID ].ProgrammePlan.RemoveContract(adblock.contract)
      'Print "NET: REMOVED adblock:"+Adblock.Title+" from Player:"+RemotePlayerID
    EndIf
 End Method

  Method GotPacket_Plan_ProgrammeChange(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local add:Byte = ReadByte(Stream)
    Local x:Int = ReadInt(Stream)
    Local y:Int = ReadInt(Stream)
    Local startrectx:Int = ReadInt(Stream)
    Local startrecty:Int = ReadInt(Stream)
    Local sendhour:Int = ReadInt(Stream)
    Local programmeblockID:Int = ReadInt(Stream)
    Local ParentProgrammeID:Int = ReadInt(Stream)
    Local ProgrammeID:Int = ReadInt(Stream)
    Local programmeblock:TProgrammeBlock = Players[RemotePlayerID].ProgrammePlan.GetProgrammeBlock(programmeBlockID)
    If programmeblock = Null Then
      Local ParentProgramme:TProgramme = Null
      Local Programme:TProgramme = Null
	  Print "Try to fetch ID:"+programmeID+" (parentprogrammeID:"+ParentProgrammeID+")"
      If ParentProgrammeID >= 0  Then ParentProgramme = TProgramme.GetSeries(ParentProgrammeID) 'Player[ RemotePlayerID ].ProgrammeCollection.getSeries(ParentProgrammeID)
      Programme = TProgramme.GetProgramme(programmeID)
      If Programme = Null Then Print "programme not found"
	  Print "got new programme:"+programme.title
	  programmeBlock = TProgrammeBlock.CreateDragged(programme, RemotePlayerID)
      'Print "NET: ADDED NEW programme"
      ProgrammeBlock.dragged = 0
    EndIf
    programmeBlock.sendhour = sendhour
	ProgrammeBlock.Pos.SetXY(x, y)
	ProgrammeBlock.StartPos.SetXY(startrectx, startrecty)
    If add
      'Player[ RemotePlayerID ].ProgrammePlan.AddProgramme(Programmeblock.programme)
      'Print "NET: ADDED programme:"+Programmeblock.programme.Title+" to Player:"+RemotePlayerID
      'Print "---  id:"+programmeblock.uniqueid+"("+programmeblockid+") Sendtime:"+Programmeblock.programme.sendtime+" to Player:"+RemotePlayerID
    Else
'      Players[ RemotePlayerID ].ProgrammePlan.RemoveProgramme(Programmeblock.programme)
      'Print "NET: REMOVED programme:"+Programmeblock.programme.Title+" from Player:"+RemotePlayerID
    EndIf
 End Method

	Method GotPacket_GameReady( packet:TNetworkPacket )
		local obj:TNetworkObject	= TNetworkObject.CreateTemporary(packet.msg)
		Local remotePlayerID:Int	= obj.getInt(1)
		Game.gamestate = 4
		Players[ RemotePlayerID ].networkstate = 1 'ready
		Print "NET: got GameReadyFlag from Player:"+Players[ RemotePlayerID ].name + " ("+RemotePlayerID+")"

		'if server then wait until all players are ready... then send startcommand
		If self.isServer
			local allReady:int = 1
			for local peer:TNetworkPeer = eachin self.peers
				if not Players[ peer.playerID ].networkstate then allReady = false
			Next
			if allReady
				SendGameStart()
				Print "NET: send startcommand"
				return
			endif
		EndIf
		'all players have their start programme?
		local allReady:int = 1
		for local i:int = 1 to 4
			if Players[i].ProgrammeCollection.movielist.count() < Game.startMovieAmount then allReady = false;exit
			if Players[i].ProgrammeCollection.contractlist.count() < Game.startAdAmount then allReady = false;exit
		Next
		if allReady
			Players[ RemotePlayerID ].networkstate = 1
			SendGameReady( RemotePlayerID, 0)
		endif
  End Method


  Method GotPacket_SendContract(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(Stream)
	Local ContractCount:Int = ReadInt(stream)
    Local contractID:Int
    For Local i:Int = 0 To ContractCount-1
      contractID:Int = ReadInt(stream)
      Players[ RemotePlayerID ].ProgrammeCollection.AddContract(TContract.getContract(contractID))
	Next
    Print "net: added contract (id:"+contractID+") to Player:"+RemotePlayerID
  End Method

  Method GotPacket_SendProgramme(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(stream)
	Local ProgrammeCount:Int = ReadInt(stream)
    Local IsMovie:Byte
    Local ProgrammeID:Int
    For Local i:Int = 0 To ProgrammeCount-1
	  IsMovie:Byte = ReadByte(stream)
      ProgrammeID:Int = ReadInt(stream)
      Players[ RemotePlayerID ].ProgrammeCollection.AddProgramme(TProgramme.GetProgramme(ProgrammeID))
    Next
	Print "got "+ProgrammeCount+" programmes for player:"+RemotePlayerID
	'Print "NET: added programme with ID:"+ProgrammeID+" to Player "+RemotePlayerID
    'Print "--->Programme:"+TProgramme.GetMovie(ProgrammeID).Title
  End Method

  Method GotPacket_PlayerPosition(_IP:Int, _Port:int)
     Local RemotePlayerID:Int = ReadByte(Stream)
     If Players[ RemotePlayerID] = Null Then Print "Player "+RemotePlayerID+" not found"
     Local x:Float = ReadFloat(stream)
     Local y:Float = ReadFloat(stream)

	 Players[ RemotePlayerID ].Figure.dx					= ReadInt(stream)
     Players[ RemotePlayerID ].Figure.AnimPos			= ReadInt(Stream)
     Players[ RemotePlayerID ].Figure.target.x			= ReadInt(stream)
     Players[ RemotePlayerID ].Figure.inElevator			= ReadInt(stream)

     'only synchronize position when not in Elevator
	 If Building.Elevator.passenger <> Players[ RemotePlayerID ].figure 'Not Players[ RemotePlayerID ].Figure.inElevator
	   Players[ RemotePlayerID ].Figure.pos.x               = x
	   Players[ RemotePlayerID ].Figure.pos.y               = y
	 End If

     If Players[ RemotePlayerID ].Figure.inElevator
	   Building.Elevator.passenger = Players[ RemotePlayerID ].Figure
	   Players[ RemotePlayerID ].Figure.pos.x =  Int(Building.Elevator.GetDoorCenter() - Int(Players[ RemotePlayerID ].Figure.FrameWidth/2) - 3)
	 EndIf

	 Local RoomID:Int = ReadInt(stream)
     Local ClickedRoomID:Int = ReadInt(Stream)
     Local toRoomID:Int = ReadInt(stream)
     Local fromRoomID:Int = ReadInt(stream)
		If RoomID = 0 Then Players[RemotePlayerID].Figure.inRoom = Null
		If Players[RemotePlayerID].figure.inroom <> Null Then
			If RoomID > 0 Then If Players[RemotePlayerID].Figure.inRoom.uniqueID <> RoomID Then
				Players[RemotePlayerID].Figure.inRoom = TRooms.GetRoomFromID(RoomID)
				If Players[RemotePlayerID].Figure.inRoom.name = "elevator" Then
					Building.Elevator.waitAtFloorTimer = MilliSecs() + Building.Elevator.PlanTime
				EndIf
			EndIf
		EndIf
     If ClickedRoomID = 0 Then Players[ RemotePlayerID ].Figure.clickedToRoom = Null
     If ClickedRoomID > 0 Then
         Players[ RemotePlayerID ].Figure.clickedToRoom = TRooms.GetRoomFromID(ClickedRoomID)
     EndIf
     If toRoomID = 0 Then Players[ RemotePlayerID ].Figure.toRoom = Null
     If toRoomID > 0 Then Players[ RemotePlayerID ].Figure.toRoom = TRooms.GetRoomFromID(toRoomID)
     If fromRoomID = 0 Then Players[ RemotePlayerID ].Figure.fromRoom = Null
     If fromRoomID > 0 And Players[ RemotePlayerID ].figure.fromroom <> Null Then
	   If Players[ RemotePlayerID ].Figure.fromRoom.uniqueID <> fromRoomID
         Players[ RemotePlayerID ].Figure.fromRoom = TRooms.GetRoomFromID(fromRoomID)
	   EndIf
     EndIf
  End Method

	Method GotPacket_PlayerDetails( packet:TNetworkPacket )
		Print "NET: got PlayerDetails"

'triggert nur bei nicht server - evtl "an anderem paket" angehangen

		local obj:TNetworkObject	= TNetworkObject.CreateTemporary(packet.msg)
		Local playerID:Int			= obj.getInt(1)
		Local name:string			= obj.getString(2)
		Local channelName:string	= obj.getString(3)
		Local color:int				= obj.getInt(4)
		Local figureBase:int		= obj.getInt(5)

		local player:TPlayer = TPlayer.getByID( playerID )
		if player = null then print "but playerID not correct"
		if player = null then return

		If figureBase <> player.figurebase Then player.UpdateFigureBase(figureBase)
		If player.color.toInt() <> color
			player.color.fromInt(color)
			player.RecolorFigure()
		EndIf
		If playerID <> game.playerID
			player.name			= name
			player.channelname	= channelName
			MenuPlayerNames[ playerID-1 ].value	 = name
			MenuChannelNames[ playerID-1 ].value = channelName
		EndIf
	End Method

	Method GotPacket_Peerdata( packet:TNetworkPacket )
		'print "GotPacket PeerData from "+dottedIP(packet.ip)
		'server already has the peer
		if isServer then return

		local obj:TNetworkObject	= TNetworkObject.CreateTemporary(packet.msg)
		Local peerCount:Int		= obj.getInt(1)
		for local i:int = 0 to peerCount-1
			Local peerNumber:Int	= obj.getInt((i*4)+2)
			Local peerIP:Int		= obj.getInt((i*4)+3)
			Local peerPort:Int		= obj.getInt((i*4)+4)
			Local playerID:Int		= obj.getInt((i*4)+5)
			local peer:TNetworkPeer = self.FindPeerByIP(peerIP, peerPort)
			if peer = null
				print "added new peer: "+peerIP
				peer = self.AddPeer(TNetworkPeer.Create(peerIP, peerPort))
			endif
			peer.playerID = playerID
			if Game.IsPlayerID(playerID)
				Players[peer.playerID].Figure.ControlledByID = peer.playerID
			endif
		Next
		'Print "NET: got PeerData"
	End Method

	Method GotPacket_Join( packet:TNetworkPacket )
		'only servers should accept a join request
		if not isServer then return

		local obj:TNetworkObject	= TNetworkObject.CreateTemporary(packet.msg)

		'it's the user acting as server knocking on the door
		If Not IsConnected
			print "join acked"
			'NetAck (RecvID, _IP, _Port)	' Send ACK
			IsConnected = True        		' Connected
		EndIf

		'someone wants to join
		If self.FindPeerByIP(packet.ip,packet.port) <> self.host
			'sends to joining user, which ip is now on slot X
			Print "NET: "+DottedIP(packet.ip)+":"+packet.port+" wants to join - Send setslot "+GetFreeSlot()

			local obj:TNetworkObject = self.CreateSimplePacket(NET_SETSLOT, NET_PACKET_RELIABLE)
			obj.SetInt(1, packet.ip )		'IP can be online ip instead of local - so we
			obj.SetInt(2, packet.port )		'inform client this time
			obj.SetInt(3, GetFreeSlot() )
			SendNetworkMessageToIP( obj.sync() , packet.ip, packet.port)
			return
		EndIf
		Print "NET: got again a join from "+DottedIP(packet.ip)+":"+packet.port
	End Method

	Method GotPacket_AnnounceGame( packet:TNetworkPacket )
		local obj:TNetworkObject	= TNetworkObject.CreateTemporary(packet.msg)
		Local teamamount:Int		= obj.getInt(1)
		Local title:String			= obj.getString(2)
		'If _ip <> intLocalIP then
		'print "got announce : "+title
		NetgameLobby_gamelist.addUniqueEntry(title, title+"  (Spieler: "+(4-teamamount)+" von 4)","",DottedIP(packet.ip),packet.port,0, "HOSTGAME")
	End Method

	Method GotPacket_ChatMessage( packet:TNetworkPacket )
		If packet.ip = self.host.ip Then return

		local obj:TNetworkObject	= TNetworkObject.CreateTemporary(packet.msg)
		Local RemotePlayerID:Int	= obj.getInt(1) 'not by IP as it could be AI player
		Local ChatMessage:String	= obj.getString(2)
		If Game.gamestate = 3 Or Game.gamestate = 4
			GameSettings_Chat.AddEntry("", ChatMessage, RemotePlayerID,"", "", MilliSecs())
		Else
			InGame_Chat.AddEntry("",ChatMessage, RemotePlayerID,"", "", MilliSecs())
		EndIf
	End Method

	Method GotPacket_SetSlot( packet:TNetworkPacket )
		local obj:TNetworkObject	= TNetworkObject.CreateTemporary(packet.msg)

		self.host.ip		= obj.getInt(1) 'my ip could be an dialup ip
		self.host.port		= obj.getInt(2)
		Local slot:int		= MaxPeers - obj.getInt(3) +1
		print "CLIENT: server asked me to set slot to "+slot
		host.playerID					= slot
		game.playerID					= slot
		Players[slot].name				= game.username
		MenuPlayerNames[slot-1].value	= game.username
		MenuChannelNames[slot-1].value	= game.userchannelname
		Local OldRecvID:Int = RecvID

		intOnlineIP = self.host.ip						'on server the ip was another one - may be from the dialup-networkcard
		onlineIP	= DottedIP(intOnlineIP)

		Game.gamestate=3
		NetAck (RecvID, packet.ip, packet.port)                 ' Send ACK

		IsConnected = True

		'send answer to SetSlot -> SlotSet
		obj:TNetworkObject = Self.CreateSimplePacket(NET_SLOTSET, not NET_PACKET_RELIABLE)
		obj.setInt(1, slot)
		obj.setInt(2, OldRecvID)
		obj.setString(3, game.username)
		obj.setString(4, game.userchannelname)
		Self.SendNetworkMessageToIP( obj.sync(), packet.ip, packet.port )
		Print "NET: set to slot "+slot+" and send slotset to server"
	End Method

	Method GotPacket_SlotSet( packet:TNetworkPacket )
		local obj:TNetworkObject	= TNetworkObject.CreateTemporary(packet.msg)
		Local slot:int			= obj.getInt(1, -1)
		Local OldRecvID:Int		= obj.getInt(2, -1)
		Local name:String		= obj.getString(3, "Defaultname")
		Local channel:String	= obj.getString(4, "Defaultchannel")

		local peer:TNetworkPeer = self.findPeerByIP(packet.ip, packet.port, false)
		if peer = null then peer = self.AddPeer( TNetworkPeer.Create(packet.ip,packet.port) )
		peer.playerID = slot


'ronny zum debuggen auskommentiert TReliableUDP.GotAckPacket(OldRecvID, packet.ip, packet.port)
		GameSettings_Chat.AddEntry("", name+" hat sich in das Spiel eingeklinkt (Sender: "+channel+")", 0,"", "", MilliSecs())
		Print "SERVER: got slotset from " dottedIP(peer.ip)
		Print "     -> sending peer data"
		'If self.isServer Then SendPeerData()
	End Method

	Method SendState()
		if not self.isServer then return

		local obj:TNetworkObject = Self.CreateSimplePacket(NET_STATE, not NET_PACKET_RELIABLE)
		obj.setInt(1, Game.minutesOfDayGone)
		obj.setInt(2, Game.speed)
		Self.BroadcastNetworkMessage( obj.sync(), self.host )
	End Method

	'sends a broadcast message to x.x.x.255 (for linux it works a bit different)
	Method BroadcastNetworkMessageToLan( msg:TNetworkMessage )
		self.SendNetworkMessageToIP(msg, TNetwork.intIP(GetBroadcastIP(self.host.ip)), self.host.port)
	End Method

	Method BroadcastNetworkMessage( msg:TNetworkMessage, notToPeer:TNetworkPeer = null)
		for local peer:TNetworkPeer = eachin self.peers
			if peer <> notToPeer then peer.SendNetworkMessage( msg )
		Next
	End Method

	'sends a bytepacked message to a certain ip/port
	Method SendNetworkMessageToIP( msg:TNetworkmessage, ip:int, port:int)
		if msg = null then return

		stream.writeInt(NET_PACKET_HEADER)
		stream.writeInt(msg.id)
		stream.writeInt(msg.state)
		stream.writeInt(msg.evType)
		stream.writeInt(msg.reliable) 'evtl hier auf "isReliable(msg.evType)" Funktion?
		stream.writeInt(msg.data.length) 'evtl hier auf "isReliable(msg.evType)" Funktion?


		Local length:int	= msg.data.length
		Local buf:Byte Ptr	= MemAlloc( length )
		If length then MemCopy buf,msg.data,length
		if length > 0 and not stream.write(buf, length) then throw "Net: Error writing to Networkmessage buffer " + length
'fix reliable
		if msg.reliable = 5
			if not SendReliableUDPtoIP( ip, port, 100, 5,"") then throw "Net: Error sending reliable udp message"
		else
			if not stream.SendUDPMsg( ip, port ) then throw "Net: Error sending udp message to " + ip + " " + dottedIP(ip)+ " :" + port
			SendID:+1	         ' Increment send counter
		endif
		MemFree buf
	End Method

	Method UpdateUDP(fromNotConnectedPlayer:Int = 0)
		while stream.RecvAvail() > 0  ' Then
			While Stream.RecvMsg() ; Wend
			if Stream.Size()
				local header:int		= stream.ReadInt()
				if header <> NET_PACKET_HEADER then return
'				if header <> NET_PACKET_HEADER then print "unknown packet with id: "+header+" received";return

				local msg:TNetworkMessage = new TNetworkMessage
				msg.id					= stream.ReadInt()
				msg.state				= stream.ReadInt()
				msg.evType				= stream.ReadInt()
				msg.reliable			= stream.ReadInt()
				local dataLength:int	= stream.ReadInt()
				local rawdata:byte ptr	= stream.RecvBuffer
				If Stream.Size() >= dataLength
					msg.data=New Byte[ dataLength ]
					MemCopy msg.data,rawdata, dataLength
				EndIf
				if Stream.Size() >= dataLength + 4 then print "next INT:"+stream.ReadInt()
				'If msg.state<>NET_STATE_MODIFIED then
				'print "RecvMsg id="+msg.id+", state="+msg.state+", evType="+msg.evType+" size="+length

				TNetworkPacket.Create(msg, stream.MessageIP, stream.MessagePort, true)
				stream.Flush()
			endif
		Wend

		local packet:TNetworkPacket = null
		While not TNetworkPacket.received.IsEmpty()
			packet = TNetworkPacket(TNetworkPacket.received.RemoveFirst())
			if packet = null then exit
			print "packet id="+packet.msg.id+", state="+packet.msg.state+", evType="+packet.msg.evType+" size="+packet.msg.data.length

			RecvID					= packet.msg.id					'used in reliable udp
			Local _IP:Int     		= packet.ip
			Local _Port:Int   		= packet.port

			Select packet.msg.evType' mod 1000 'only base event - floor(msg.evType/1000) gives ADD/CHANGE...
				Case NET_JOIN					GotPacket_Join(packet)				' JOIN PACKET
				Case NET_ANNOUNCEGAME			GotPacket_AnnounceGame(packet)		' A game was announced
				Case NET_SETSLOT				GotPacket_SetSlot(packet)		' Answer of join-request, only sent to join-sender
												IsConnected = True 						' we have connected and server send setslot
				Case NET_PEERDATA				GotPacket_Peerdata(packet)		' synchronizing PlayerIPs and Ports
				Case NET_PLAYERDETAILS			GotPacket_PlayerDetails(packet)		' name, channelname and so on
				Case NET_PLAYERPOSITION			GotPacket_PlayerPosition(_IP, _Port)	' x,y, room, target...
				Case NET_CHATMESSAGE			GotPacket_ChatMessage(packet)		' someone has written something into the chat
				Case NET_MOVIEAGENCY_CHANGE		GotPacket_SendMovieAgencyChange(_IP,_Port) ' got change of programmes in MovieAgency from Server
				Case NET_SENDPROGRAMME			GotPacket_SendProgramme(_IP,_Port)		' got StartupProgramme from Server
				Case NET_SENDCONTRACT			GotPacket_SendContract(_IP,_Port)       ' got StartupContract from Server
				Case NET_SENDNEWS				GotPacket_SendNEWS(_IP,_Port)	       ' got News from Server
				Case NET_NEWSSUBSCRIPTIONLEVEL	GotPacket_NewsSubscriptionLevel(_IP, _Port)
				Case NET_GAMEREADY				GotPacket_GameReady(packet)				' got readyflag
				Case NET_STARTGAME				Game.networkgameready = 1					' got startcommand
				Case NET_PLAN_PROGRAMMECHANGE	GotPacket_Plan_ProgrammeChange(_IP,_Port)	' got flag to change Programme of Player
				Case NET_PLAN_NEWSCHANGE		GotPacket_Plan_NewsChange(_IP,_Port)		' got flag to change Programme of Player
				Case NET_PROGRAMMECOLLECTION_CHANGE
												GotPacket_ProgrammeCollectionChange(_IP,_Port)	'got change of programme (remove, readd, remove from plan ...)
				Case NET_PLAN_ADCHANGE		    GotPacket_Plan_AdChange(_IP,_Port)			' got flag to change Programme of Player
				Case NET_STATIONCHANGE			GotPacket_StationChange(_IP,_Port)			' got flag to change Programme of Player
				Case NET_ELEVATORSYNCHRONIZE	GotPacket_ElevatorSynchronize(_IP,_Port)	' got flag to change Programme of Player
				Case NET_ELEVATORROUTECHANGE	GotPacket_ElevatorRouteChange(_IP,_Port)	' got flag to change Programme of Player
				Case NET_SLOTSET				GotPacket_SlotSet(packet)
				Case NET_PING					SendPong( self.FindPeerByIP(_IP, _Port, true) )
				Case NET_PONG					local peer:TNetworkPeer = self.FindPeerByIP(_IP, _Port)
												if peer <> null
													'ping send every 5 seconds
													peer.ping = (MilliSecs() - peer.pingTime) /5.0 / 2.0
												endif
'				Case NET_ACK				    Local AckForSendID:Int = ReadInt(Stream)	' ACK PACKET
'												TReliableUDP.GotAckPacket(AckForSendID, _IP, _Port)
'												RemoveNetObj AckForSendID   				' Remove Reliable Packet (ACK has been received)
'				Case NET_STATE		 	        Game.minutesOfDayGone = ReadFloat(Stream)
'												Game.speed = ReadFloat(Stream)
												' State Update
'				Case NET_UPDATE					Local remotePlayerID:Int = ReadInt(Stream)	' Full update, align
'												Players[remotePlayerID].Figure.pos.x = ReadFloat(stream)          ' X
'												Players[remotePlayerID].Figure.pos.y = ReadFloat(stream)          ' Y
				Case NET_QUIT					local peer:TNetworkPeer = self.FindPeerByIP(_IP, _Port, true)
												Players[peer.playerID].Figure.ControlledByID=-1
												TReliableUDP.DeletePacketsForIP(_IP,_Port)
												Print "Player "+peer.playerID+" left the game..."
												peer = null
				End Select
				'if reliablePacket then	NetAck (RecvID, _IP, _Port)
			Wend 'Endif
	'	TReliableUDP.ReSend() 'send again all not ACKed packets

		If IsConnected Or fromNotConnectedPlayer ' Updates
			'eventuell die "time > now bla" vergleiche
			'auslagern in die jeweiligen Methoden mit Param "now"...

			local nowTime:int = Millisecs()

			'SERVER: Aller 1500ms einen Status rueberschicken (unbestaetigt)
			If isServer And nowTime >= MainSyncTime+ 1500.0*self.GetSyncSpeedFactor()
				SendPeerData()
				'if Abs(MilliSecs() - Building.Elevator.Network_LastSynchronize)>500 Then Building.Elevator.Network_SendSynchronize()
				'SendState()
				MainSyncTime = nowTime
			EndIf

			'Aller 4000ms einen Status rueberschicken (unbestaetigt)
			If nowTime >= UpdateTime + 4000*self.GetSyncSpeedFactor()
				'only for server SendState()
				print "time to send player details"
				SendPlayerDetails()
				UpdateTime = nowTime
			EndIf

			'online: 2 sec, lan: 1 sec
			If nowTime >= UpdateTime + 2000*self.GetSyncSpeedFactor()
'				if Game.gamestate = 0 then SendPlayerPosition()
			endif

			'Ping aller 1 Sekunde absetzen (unbestaetigt)
			If nowTime >= PingTimer + 5000 '*self.GetSyncSpeedFactor()
				SendPing()
			EndIf
		EndIf 'is connected

		If GameSettingsOkButton_Announce.iscrossed() And isServer And MilliSecs() >=  AnnounceTime + (Game.onlinegame+1)*1000*self.GetSyncSpeedFactor() + 2000
			AnnounceTime = MilliSecs()
			SendGameAnnouncement()
		EndIf

  End Method

  Method ClearLastRecv()
    For Local i:Int = 0 To 31
	  lastRecv[i] = -1  ' Doppelte Arrayeintraege loeschen
	Next
  End Method


	'IsMsgNew gibt zurueck, ob das UDP-Paket ein Duplikat oder ein Altes ist
	Method IsMsgNew:Byte(id:Int, data:Int = 0, _IP:Int, _Port:int)
		For Local i:Int = 50 To 0 Step -1
			lastRecv[i + 1] = lastRecv[ i ]
		Next
		lastRecv[0] = id

		For Local i:Int = 1 To 51
			If lastRecv[ i ] = lastRecv[0] ' Duplicate
				Select data ' ACK Anyway (Reliable packets only)
					Case NET_QUIT, NET_SENDCONTRACT		NetAck (RecvID, _IP, _Port)
														If debugmode Then Print "*** Received duplicate packet ("+data+"), resending ACK ***"
					Case NET_JOIN 						Return True
					Case NET_GAMEREADY 					Print "*** got gameready"
														Return True
				End Select
				Return False
			EndIf
		Next
		Return True
	End Method

	' // RemoveNetObj removes reliable UDP packets from the queue once an ACK has been received
	Method RemoveNetObj(AckID:Int)
		For n:NetObj = EachIn netList
			If n.SID = AckID
				Local tmpID:Int = n.id
				netList.Remove n
				For n:NetObj = EachIn netList                                ' Remove old entries
					If n.id = tmpID And n.SID <= AckID Then netList.Remove n
				Next
				Exit
			EndIf
		Next
	End Method

	'NetAck sends ACKnowledge packet to client
	Method NetAck(RecvID:Int, _IP:Int, _Port:int)
	print "ack disabled"
return

		stream.writeInt(NET_PACKET_HEADER)
		stream.writeInt(RecvID)
		stream.writeInt(NET_STATE_CLOSED)
		stream.writeInt(NET_ACK)
		stream.writeInt(not NET_PACKET_RELIABLE) 'evtl hier auf "isReliable(msg.evType)" Funktion?
		'SendUDP
		stream.SendUDPMsg  _IP, _Port
		SendID:+1	         ' Increment send counter
	End Method

  'sends the current packet to player i
  'and adds it to the reliableUDP-packets which are handled automatically
  'If MaxRetry is <0 then it will be tried forever
	Method SendReliableUDP:int(peer:TNetworkPeer, retrytime:Int = 200, MaxRetry:Int = -1, desc:String="")
		return self.SendReliableUDPtoIP(peer.ip, peer.port, retrytime, MaxRetry, desc)
	End Method

	Method SendReliableUDPtoIP:int(_IP:Int, _Port:int,retrytime:Int = 200, MaxRetry:Int = -1, desc:String="")
		print "sendreliableudptoip disabled"
return 0
		BackupStream(MyBank)
		TReliableUDP.Create(SendID, _IP, _Port, MyBank, retrytime, MaxRetry, desc)
		local result:int = stream.SendUDPMsg(_IP, _Port)
		BackupStream(MyBank)
'		SendID:+1	         ' Increment send counter
		return result
	End Method

	Method RemovePeers()
		for local peer:TNetworkPeer = eachin self.peers
			print "NET: implement disconnect peers"
		Next
	End Method

	Method AddPeer:TNetworkPeer(peer:TNetworkPeer)
		self.peers.AddLast(peer)
		return peer
	End Method

	'NetConnect attempts to connect client to host
	Method NetConnect:int(ip:int, port:int)
		Print "try to connect to: "+DottedIP(ip)
		self.removePeers()
		self.isServer	= False
		self.AddPeer(TNetworkPeer.Create(ip,port,1))

		Local waittime:Int = MilliSecs() + 2500
		SetClsColor 0, 0, 0

		self.SendNetworkMessageToIP( self.CreateSimplePacket(NET_JOIN, true).sync(), ip, port )

		Repeat
			DrawText "Verbinde...", 5, 5
			UpdateUDP(True)
		Until IsConnected = True Or waittime - MilliSecs() < 0

		'hoster will be number 1 until slot packet
		if isConnected then self.host.playerID = 1

		return isConnected
	End Method

  ' // NetDisconnect schliesst eine Netzwerkverbindung
  Method NetDisconnect(RealQuit:Byte=True)
 return
    Local QuitID:Int = 0
        QuitID = SendID
		stream.writeInt(NET_PACKET_HEADER)
		stream.writeInt(SendID)
		stream.writeInt(NET_STATE_MESSAGE)
		stream.writeInt(NET_QUIT)
		stream.writeInt(NET_PACKET_RELIABLE) 'evtl hier auf "isReliable(msg.evType)" Funktion?
        stream.writeInt(Game.playerID)
		SendReliableUDP(self.host, 250,10, "NetDisconnect")
	Local tmpConn:Int = 0

    Local timeOutTime:Int = MilliSecs()
    SetClsColor 0, 0, 0
    Repeat
	  SetColor 100,100,100
	  DrawRect(200,200,400,200)
	  SetColor 255,255,255
	  FontManager.GetFont("Default",16, ITALICFONT).drawBlock("Trenne die Verbindung zum Host...", 200,200,400,200,1,200,150,150)
      While stream.RecvMsg() ' Neues UDP-Paket erhalten
        RecvID = ReadInt(stream)
	    Local data:Int   = ReadByte(stream)
  	    Local _IP:Int     = ReadInt(stream)
 	    Local _Port:Int   = ReadInt(stream)
	    If Not Game.onlinegame
	      _IP:Int     = stream.GetMsgIP()
 	      _Port:Int   = stream.GetMsgPort()
	    End If

		  Select data
		    Case NET_ACK                  						' ACK PACKET
		      Local AckForSendID:Int = ReadInt(stream)
		      If AckForSendID = QuitID Then
			    TReliableUDP.GotAckPacket(QuitID, _IP,_Port)  	' Remove Reliable Packet (ACK has been received)
				TReliableUDP.List.Clear()
		        tmpConn = 1                						' We have disconnected
			    Print "got ack for my quit attempt #"+RecvID
			  EndIf
	      End Select

      Wend
	  Stream.Flush()
  	  If MilliSecs() >= timeOutTime + 2000 Then tmpConn = 2 	' No response received in 2 seconds, bail
      Flip
      Cls
	  TReliableUDP.ReSend()
    Until tmpConn <> 0
    IsConnected = False
    Game.playerID = 0
	If RealQuit Then
      CloseStream stream
      stream = Null
	EndIf
  End Method
End Type
Global Network:TTVGNetwork = new TTVGNetwork



'class which provides a self-regulated kind of resending packets which aren't known to be received
'from the clients. Until an Packet is ACKnowledged by the receipient, it will be resend for a given time.
Type TReliableUDP
  Field id:Int
  Field SendID:Int
  Field LastSent:Int =0
  Field desc:String = ""
  Field Retry:Int = 0
  Field MaxRetry:Int = -1 'indefinite if under 0
  Field content:TBank
  Field targetIP:Int
  Field targetPort:Int
  Field retrytime:Int = 200
  Global LastID:Int =0
  Global List:TList = CreateList()

  Function Create:TReliableUDP(SendID:Int, IP:Int, Port:Int, content:TBank, retrytime:Int=200, MaxRetry:Int = -1, desc:String="")
    Local ReliableUDP:TReliableUDP = New TReliableUDP

    ReliableUDP.SendID    = SendID
    ReliableUDP.targetIP  = IP
    ReliableUDP.targetPort= Port
    ReliableUDP.content   = content
    ReliableUDP.retrytime = retrytime*Network.GetSyncSpeedFactor()
    ReliableUDP.MaxRetry = MaxRetry
    ReliableUDP.desc = desc

    ReliableUDP.id = TReliableUDP.LastID
    TReliableUDP.LastID:+1

    TReliableUDP.List.AddLast(ReliableUDP)
    Return ReliableUDP
  End Function

  'we got an ACK-packet, now find the corresponding and delete it...
  '-> we made our reliable udp-packet being received ;D
  Function GotAckPacket:Int(SendID:Int, fromIP:Int, fromPort:Int)
  	For Local ReliableUDP:TReliableUDP = EachIn TReliableUDP.List
     If ReliableUDP.SendID = SendID And ReliableUDP.targetIP = fromIP And ReliableUDP.targetPort = fromPort
       If ReliableUDP.Retry >=3 Then Print "UDP: recv ACK and deleted:"+ReliableUDP.SendID+" for:"+DottedIP(fromIP)

       TReliableUDP.List.Remove(ReliableUDP)
       Return 1
     EndIf
    Next
    Return 0
  End Function

  'send all packets which are not ACKed up to now but are requested to be reliable
  Function ReSend()
 ' print "resend disabled"
	'ron
return

  	For Local ReliableUDP:TReliableUDP = EachIn TReliableUDP.List
  	  If ReliableUDP.LastSent + ReliableUDP.retrytime < MilliSecs() Then
  	    Network.RestoreStream(ReliableUDP.content)
  	    Network.stream.SendUDPMsg ReliableUDP.targetIP, ReliableUDP.targetPort
		ReliableUDP.Retry:+1
		ReliableUDP.LastSent = MilliSecs()
  	    if ReliableUDP.Retry >=4 then Print "UDP: Re-sent:"+ReliableUDP.SendID+" ("+ReliableUDP.desc+")->"+DottedIP(ReliableUDP.targetIP)+":"+ReliableUDP.targetPort
  	    If ReliableUDP.MaxRetry > 0 And ReliableUDP.MaxRetry - ReliableUDP.Retry <=0
  	      Print "UDP:maxRetry reached for Packet:"+ReliableUDP.SendID+" ("+ReliableUDP.desc+") ->deleted"
          TReliableUDP.List.Remove(ReliableUDP)
  	    End If
  	  EndIf
  	Next
  End Function

  Function DeletePacketsForIP(_IP:Int, _Port:int)
  	For Local ReliableUDP:TReliableUDP = EachIn TReliableUDP.List
	  If ReliableUDP.targetIP = _IP And ReliableUDP.targetPort = _Port
		TReliableUDP.List.Remove(ReliableUDP)
	  End If
	Next
	Print "cleared ReliablePackeList from IP:"+DottedIP(_IP)
  End Function

  Function DeletePacketsWithCommand:Int(desc:String)
  	For Local ReliableUDP:TReliableUDP = EachIn TReliableUDP.List
	  If ReliableUDP.desc = desc
		TReliableUDP.List.Remove(ReliableUDP)
	  End If
	Next
	Print "cleared ReliablePackeList from '"+desc+"'"
  End Function
End Type

' NetObj Type (Makes UDP Packets reliable)
Type NetObj
  Field id:Int, SID:Int, T:Int, Retry:Int   ' Packet ID, SendID, Timer, Retry

	Function Create:NetObj(id:Int)
  print "createnetobj"
return null
		If Network.Stream = Null Then Return Null

		Local n:NetObj = New NetObj ' Create Packet
		n.id = id             ' Packet ID
		n.SID = Network.SendID        ' Send ID

		Select id
			Case 2            ' Quit Packet
				WriteInt Network.Stream, NET_PACKET_HEADER
				WriteInt Network.Stream, n.SID
				WriteByte Network.Stream, NET_QUIT
				WriteByte Network.Stream, Game.playerID
		End Select
print "reimplement send"
'		Network.SendUDP			' Send UDP Message
		n.T = MilliSecs()		' Set Timer
		Return n
	End Function

  ' Resends Packets
	Method handle:Int()
  print "handle disabled"
return 0
		If Network.Stream = Null Then Return 0

		Select id
			Case 2 ' Quit Attempt (Never Drops)
				If MilliSecs() >= T + 100 					' Resend every 100ms
					WriteInt Network.Stream, NET_PACKET_HEADER
				    WriteInt Network.Stream, SID
					WriteByte Network.Stream, NET_QUIT
					WriteByte Network.Stream, Game.playerID
'rint "reimplement send"
'					Network.SendUDP
					T = MilliSecs()
					If Retry < 15		' Retry (20 times every 100ms = 2 seconds)
						Retry:+1
						If Network.debugmode = True Then Print "*** Resent quit packet ***"
					EndIf
	      			If Retry >= 15
	        			If Network.debugmode = True Then Print MilliSecs()+">="+(T+100)+"*** Dropped QUIT packet ***"
						Network.netList.Remove Network.n  ' Drop Packet
					EndIf
				EndIf
		End Select
	End Method
End Type