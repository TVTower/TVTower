Const NET_PACKET_RELIABLE:int	= 1


'message states
Const NET_STATE_ALL:int			= 0
Const NET_STATE_CREATED:int		= 1
Const NET_STATE_MODIFIED:int	= 2
Const NET_STATE_CLOSED:int		= 3
Const NET_STATE_SYNCED:int		= 4
Const NET_STATE_MESSAGE:int		= 5
Const NET_STATE_ZOMBIE:int		=-1
'types
Const NET_TYPE_STRING:int		= 1
Const NET_TYPE_INT:int			= 2
Const NET_TYPE_UINT8:int		= 3
Const NET_TYPE_UINT16:int		= 4
Const NET_TYPE_FLOAT16:int		= 5
Const NET_TYPE_FLOAT32:int		= 6


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
	field id:int
	Field slots:TNetworkObjectSlot[32]
	field modified:int
	field target:object 'remote ?

	Function Create:TNetworkObject( id:int,state:int,sender:int, receiver:int )
		Local obj:TNetworkObject=New TNetworkObject
		obj.id		= id
		obj.state	= state
		obj.sender	= sender
		obj.receiver= receiver
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

	Method GetInt:int( index:int )
		Return slots[index].GetInt()
	End Method

	Method GetFloat:float( index:int )
		Return slots[index].GetFloat()
	End Method

	Method GetString:string( index:int )
		Return slots[index].GetString()
	End Method

	Method WriteSlot:TNetworkObjectSlot( index:int )
		Assert state<>NET_STATE_CLOSED And state<>NET_STATE_ZOMBIE Else "Object has been closed"
		modified :|1 Shl index
		If state = NET_STATE_SYNCED then state=NET_STATE_MODIFIED
		Return slots[index]
	End Method

	Method Sync:TNetworkMessage()
		Select state
			Case NET_STATE_SYNCED, NET_STATE_ZOMBIE 	Return null
		End Select

		Local msg:TNetworkMessage

		'local
		If Not receiver
			msg			= New TNetworkMessage
			msg.id		= id
			msg.state	= state
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


	Method Update( msg:TNetworkMessage )
		Assert id=msg.id
		self.UnpackSlots(msg.data)
		state = msg.state
	End Method

	Method CreateMessage:TNetworkMessage(messageType:int=0)
		select messageType
			case NET_STATE_CREATED, NET_STATE_MESSAGE
					return TNetworkMessage.Create(id, messageType, PackSlots( ~0 ))
			case NET_STATE_CLOSED
					return TNetworkMessage.Create(id, messageType, PackSlots( 0 ))
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
				Case NET_TYPE_FLOAT32	SetFloat index,UnpackFloat32( p[0] Shl 24 | p[1] Shl 16 | p[2] Shl 8 | p[3] )
										p:+4
				Case NET_TYPE_STRING	local length:int = p[0] Shl 8 | p[1]
										SetString index, String.FromBytes( p+2, length )
										p:+2 +length
				Default					Throw "Invalid NetworkObjectSlot data type"
			End Select
		Wend
		If p<>e Throw "Corrupt NEtworkObject message"
	End Method
End Type

Type TNetworkObjectSlot
	Field slottype:int
	Field _int:int
	Field _float:float
	Field _string:string

	Method SetInt( data:int )
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
		Assert slottype=0 Or slottype=NET_TYPE_FLOAT32
		_float	= data
		slottype= NET_TYPE_FLOAT32
	End Method

	Method SetString( data:string )
		Assert slottype=0 Or slottype=NET_TYPE_STRING
		_string	= data
		slottype= NET_TYPE_STRING
	End Method

	Method GetInt:int()
		Assert slottype=NET_TYPE_INT Or slottype=NET_TYPE_UINT8 Or slottype=NET_TYPE_UINT16
		Return _int
	End Method

	Method GetFloat:float()
		Assert slottype = NET_TYPE_FLOAT32
		Return _float
	End Method

	Method GetString:string()
		Assert slottype = NET_TYPE_STRING
		Return _string
	End Method

End Type


Type TNetworkMessage
	Field id:int
	Field state:int
	Field data:Byte[]

	Function Create:TNetworkMessage(id:int, state:int, data:byte[])
		local obj:TNetworkMessage = new TNetworkMessage
		obj.id = id
		obj.state = state
		obj.data = data
		return obj
	End Function
End Type








'base of all networkevents...
'added to the base networking functions are all methods to send and receive data from clients
'including playerposition, programmesending, changes of elevatorpositions etc.
Type TTVGNetwork
	' // Network Specific Declares
	Field isHost:int				= False    				' Are you hosting or joining?
	Field IsConnected:int			= False   				' Are you connected?
	Field localIP:string				= ""					' my local IP
	Field intLocalIP:int				= 0						' Int of server IP
	Field Stream:TUDPStream      							' UDP Stream
	Field myPing:Int[4], PingTime:Int[4], PingTimer:Int =0  ' Ping and Ping Timer
	Field UpdateTime:Int         							' Update Timer
	Field MainSyncTime:Int       							' Main Update Timer
	Field AnnounceTime:Int       							' Main Announcement Timer
	Field SendID%, RecvID%, lastRecv:Int[52] 				' Packet IDs and Duplicate checking Array
	Field MyID:Int 					= -1					' which playernumber is mine? - so which line of the iparray and so on
	Field IP:int[4], Port:Int[4] 							' Client IP and Port
	Field debugmode:Byte			= True					' Toggles the display of debug messages
	Field bSentFull:Byte         							' Full update boolean
	Field n:NetObj, netList:TList = New TList	 			' Packet Object and List
	Field LastOnlineRequestTimer:Int	= 0
	Field LastOnlineRequestTime:Int		= 10000   			'time until next action (getlist, announce...)
	Field LastOnlineHashCode:String		= ""
	Field OnlineIP:String				= ""                ' ip for internet
	Field intOnlineIP:Int				= 0					' int version of ip for internet
	Field ChatSpamTime:Int				= 0					' // Networking Constants
	Global HOSTPORT:int					= 4544              ' * IMPORTANT * This UDP port must not be blocked by
	Global ONLINEPORT:int				= 4544            	' a router or firewall, or CreateUDPStream will fail
	Global LOCALPORT:int				= 4544
	Global NET_ACK:Byte					= 1					' ALL: ACKnowledge
	Global NET_JOIN:Byte				= 2					' ALL: Join Attempt
	Global NET_PING:Byte				= 3					' Ping
	Global NET_PONG:Byte				= 4					' Pong
	Global NET_UPDATE:Byte				= 5					' Update
	Global NET_STATE:Byte				= 6					' State update only
	Global NET_QUIT:Byte				= 7					' ALL:    Quit
	Global NET_ANNOUNCEGAME:Byte		= 8					' SERVER: Announce a game
	Global NET_SETSLOT:Byte				= 9					' SERVER: command from server to set to a given playerslot
	Global NET_SLOTSET:Byte				= 10				' ALL: 	  response to all, that IP uses slot X now
	Global NET_PLAYERLIST:Byte			= 11				' SERVER: List of all players in our game
	Global NET_CHATMESSAGE:Byte			= 12				' ALL:    a sent chatmessage ;D
	Global NET_PLAYERIPS:Byte			= 13				' Packet contains IPs of all four Players
	Global NET_PLAYERDETAILS:Byte		= 14				' ALL:    name, channelname...
	Global NET_PLAYERPOSITION:Byte		= 15				' ALL:    x,y,room,target...
	Global NET_SENDPROGRAMME:Byte		= 16				' SERVER: sends a Programme to a user for adding this to the players collection
	Global NET_GAMEREADY:Byte			= 17				' ALL:    sends a ReadyFlag
	Global NET_STARTGAME:Byte			= 18				' SERVER: sends a StartFlag
	Global NET_PLAN_PROGRAMMECHANGE:Byte= 19				' ALL:    playerprogramme has changed (added, removed and so on)
	Global NET_STATIONCHANGE:Byte		= 20				' ALL:    stations have changes (added ...)
	Global NET_ELEVATORROUTECHANGE:Byte	= 21				' ALL:    elevator routes have changed
	Global NET_ELEVATORSYNCHRONIZE:Byte	= 22				' SERVER: synchronizing the elevator
	Global NET_PLAN_ADCHANGE:Byte		= 23				' ALL:    playerprogramme has changed (added, removed and so on)
	Global NET_SENDCONTRACT:Byte		= 24				' SERVER: sends a Contract to a user for adding this to the players collection
	Global NET_PROGRAMMECOLLECTION_CHANGE:Byte = 25		' ALL:    programmecollection was changed (removed, sold...)
	Global NET_SENDNEWS:Byte			= 26				' SERVER: creates and sends news
	Global NET_NEWSSUBSCRIPTIONLEVEL:Byte = 27				' ALL: sends Changes in subscription levels of news-agencies
	Global NET_PLAN_NEWSCHANGE:Byte		= 28				' ALL: sends Changes of news in the players newsstudio
	Global NET_MOVIEAGENCY_CHANGE:Byte	= 29				' ALL: sends changes of programme in movieshop
	Global NET_DELETE:Byte				= 0
	Global NET_ADD:Byte					= 1
	Global NET_CHANGE:Byte				= 2
	Global NET_BUY:Byte					= 3
	Global NET_SELL:Byte				= 4
	Global NET_BID:Byte					= 5
	Global NET_SWITCH:Byte				= 6
	Global MyStream:TStream				= New TStream
	Global MyBank:TBank					= New TBank
	Global LastElevatorSynchronize:Int	= 0
	Global BackupStreamPtr:Byte Ptr
	Global BackupStreamSize:Int = 0

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

	Function Create:TTVGNetwork(fallbackip:String)
		Local Network:TTVGNetwork = New TTVGNetwork

		If Network.intlocalIP = 0
			?not linux
			Network.localIP		= TNetwork.DottedIP(TNetwork.GetHostIP(""))
			?
			?linux
'			Network.LocalIP	= TNetwork.DottedIP(TNetwork.GetHostIP("eth0"))
			Network.LocalIP	= TNetwork.DottedIP(TNetwork.GetHostIP(""))
			?
			Network.intLocalIP	= TNetwork.IntIP(Network.localIP)
		endif

		If Network.intlocalIP = 0
			print "NET: using fallback IP " +fallbackip
			Network.localIP		= fallbackip
			Network.intlocalIP	= TNetwork.IntIP(fallbackip)
		EndIf
		Return Network
	End Function

	Method GetFreeSlot:Int()
		For Local i:Int = 0 To 3
			If IP[i] = 0 Then Return i+1
		Next
		Return -1
	End Method


  Function GetBroadcastIPs:String[](ip:String)
	If Len(ip$)>6
		ip$=ip$
		Local lastperiod:Int=1
		Local period:Int =0
		For Local t:Int=1 To 3				    '; 4 Zahlengruppen, aber die letzte muss weg
			period=Instr(ip,".",lastperiod)
			lastperiod=period+1
		Next
		local ip:string = Left(ip,period)
		local ips:string[254]
		for local i:int = 1 to 254 '255 is broadcast itself
			ips[i-1] = ip+i
		Next
		return ips
	Else
		Return null
	EndIf
  End Function

  Function GetBroadcastIP:String(ip:String)
	If Len(ip$)>6
		ip$=ip$
		Local lastperiod:Int=1
		Local period:Int =0
		For Local t:Int=1 To 3				    '; 4 Zahlengruppen, aber die letzte muss weg
			period=Instr(ip,".",lastperiod)
			lastperiod=period+1
		Next
		Return Left(ip,period)+"255"
	Else
		Return ""
	EndIf
  End Function

  Method IsNoComputerNorMe:Byte(_IP:Int, _Port:int)
    If _IP = Null Or _IP = 0 Then Return False 'it a computerplayer
    If IP[ Game.playerID-1 ] = _IP And Port[ Game.playerID-1 ] = _Port Then Return False 'it's me ;D
	Return True
  End Method

  Method WriteMyIP()
    If Not Game.onlinegame
      WriteInt stream, intLocalIP
  	  WriteInt stream, HOSTPORT
	Else
      WriteInt stream, intOnlineIP
  	  WriteInt stream, ONLINEPORT
	EndIf
  End Method

	'modier of sync speed
	Method GetSyncSpeedFactor:int()
		If game.onlinegame Then return 1.0 else return 0.1
	End Method

  Method GetMyIP:Int()
	If Game.onlinegame Then Return intOnlineIP
	Return intLocalIP
  End Method

  Method GetMyPort:Int()
	If Game.onlinegame Then Return ONLINEPORT
	Return LOCALPORT
  End Method

  Method SendChatMessage(ChatMessage:String = "")
    For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i]) 'IP[i]<> Null And IP[i] <> intMyIP
      WriteInt Stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
      WriteByte Stream, NET_CHATMESSAGE
	  WriteMyIP()
      WriteInt Stream, Game.playerID
      WriteInt Stream, Len(ChatMessage)
      WriteString Stream, ChatMessage
      'SendUDP(i)
	  SendReliableUDP(i, 150, -1, "SendChatMessage")
	  Print "send chat to playerIP:"+TNetwork.DottedIP(IP[i])
     EndIf
    Next
  End Method

  Method SendPlayerIPs()
    For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i], Port[i]) 'And IP[i] <> intMyIP
       WriteInt Stream, SendID
		WriteInt Stream, not NET_PACKET_RELIABLE
       WriteByte stream, NET_PLAYERIPS
	   WriteMyIP()
       WriteInt Stream, IP[0]
       WriteInt Stream, Port[0]
       WriteInt Stream, IP[1]
       WriteInt Stream, Port[1]
       WriteInt Stream, IP[2]
       WriteInt Stream, Port[2]
       WriteInt Stream, IP[3]
       WriteInt Stream, Port[3]
       SendUDP(i)
   '    SendID:+1
     EndIf
      If IP[ i ] <> Null Then Player[i+1].Figure.ControlledByID= i+1
      If IP[ i ] = Null Or IP[ i ]=0 Then Player[i+1].Figure.ControlledByID= 0
    Next
  End Method

  Method SendJoin()
      WriteInt stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
      WriteByte stream, NET_JOIN
	  WriteMyIP()
      SendReliableUDP(0, 100,5, "SendJoin")
  End Method

	Method SendGameAnnouncement()
		If Game.gamestate = 0 then return 'no announcement when already in game
		If Not Game.onlinegame
			Print "NET: announcing a LAN game to " +GetBroadcastIP(localIP)
			local ips:string[] = GetBroadcastIPs(localIP)
			if ips = null then print "no ips";return
			for local i:int = 1 to len(ips)-1
				WriteInt   stream, SendID
				WriteByte  stream, not NET_PACKET_RELIABLE
				WriteByte  stream, NET_ANNOUNCEGAME
				WriteMyIP()
				WriteByte  stream, (GetFreeSlot()-1)
				WriteByte  stream, Len(Game.title)
				WriteString stream, Game.title
				stream.SendUDPMsg TNetwork.IntIP(ips[i]), Network.HOSTPORT
			Next
'			stream.SendUDPMsg TNetwork.IntIP(GetBroadcastIP(localIP)), Network.HOSTPORT
'			stream.SendUDPMsg intLocalIP, Network.HOSTPORT
			SendID:+1
		Else
			Print "NET: announcing a ONLINE game "
			Local Onlinestream:TStream = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=AddGame&Titel="+UrlEncode(Game.title)+"&IP="+OnlineIP+"&Port="+ONLINEPORT+"&Spieler="+Self.getFreeSlot()+"&Hashcode="+LastOnlineHashCode)
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
    ' Print "NET: sent playerdetails"
   For Local i:Int = 0 To 3
     If MyID <> game.playerID Then MyID = game.playerID
	 If Player[MyID] = Null Then Print "mein spieler fehlt"+MyID; Return Null
     If IsNoComputerNorMe(IP[i], Port[i]) And Player[Game.playerid]<>Null
       WriteInt Stream, SendID
       WriteByte Stream, NET_PLAYERDETAILS
 	   WriteMyIP()
       WriteByte Stream, MyID
       WriteInt Stream, Len(Player[MyID].name)
       WriteString Stream, Player[MyID].name
       WriteInt Stream, Len(Player[MyID].channelname)
       WriteString Stream, Player[MyID].channelname
       WriteByte Stream, Player[MyID].color.colR
       WriteByte Stream, Player[MyID].color.colG
       WriteByte Stream, Player[MyID].color.colB
       WriteByte Stream, Player[MyID].figurebase
       SendUDP(i)
     EndIf
	 If Game.playerID = 1 And IP[ i ] = Null Then
       For Local j:Int = 0 To 3
         If (IP[j] = 0 Or IP[j]=Null)
			WriteInt stream, SendID
			WriteByte Stream, NET_PLAYERDETAILS
			WriteMyIP()
			WriteByte stream, j+1
			WriteInt stream, Len(Player[j+1].name)
			WriteString stream, Player[j+1].name
			WriteInt stream, Len(Player[j+1].channelname)
			WriteString stream, Player[j+1].channelname
			WriteByte stream, Player[j+1].color.colR
			WriteByte stream, Player[j+1].color.colG
			WriteByte stream, Player[j+1].color.colB
			WriteByte stream, Player[j+1].figurebase
			SendUDP(i)
         EndIf
	   Next
	 EndIf
    Next
  End Method

  Method SendPlayerPosition()
   ' Print "NET: sent playerposition"
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i]) 'IP[i]<> Null And IP[i] <> GetMyIP() And Port[i] <> GetMyPort()' and Player[MyID]<>Null
       'Stream.Flush
       WriteInt Stream, SendID
       WriteByte Stream, NET_PLAYERPOSITION
 	   WriteMyIP()
       WriteByte Stream, MyID
       WriteFloat stream, Player[MyID].Figure.pos.x
       WriteFloat stream, Player[MyID].Figure.pos.y
       WriteInt stream, Player[MyID].Figure.dx
       WriteInt Stream, Player[MyID].Figure.AnimPos
       WriteInt Stream, Player[MyID].Figure.target.x
       WriteInt Stream, Player[MyID].Figure.inElevator
       If (Player[MyID].Figure.inRoom <> Null) Then WriteInt Stream, Player[MyID].Figure.inRoom.uniqueID Else WriteInt Stream, 0
       If (Player[MyID].Figure.clickedToRoom <> Null) Then WriteInt stream, Player[MyID].Figure.clickedToRoom.uniqueID Else WriteInt stream, 0
       If (Player[MyID].Figure.toRoom <> Null) Then WriteInt stream, Player[MyID].Figure.toRoom.uniqueID Else WriteInt stream, 0
       If (Player[MyID].Figure.fromRoom <> Null) Then WriteInt stream, Player[MyID].Figure.fromRoom.uniqueID Else WriteInt stream, 0
       SendUDP(i)
	   'Print "send position to player:"+(i+1)

	   If MyID = 1
         For Local j:Int = 0 To 3
           If (IP[j] = 0 Or IP[j]=Null)
             'Print "send position of CPUplayer "+i
             'stream.Flush
	         WriteInt stream, SendID
	         WriteByte stream, NET_PLAYERPOSITION
		     WriteMyIP()
	         WriteByte stream, j+1
	         WriteInt stream, Player[j+1].Figure.pos.x
	         WriteInt stream, Player[j+1].Figure.pos.y
	         WriteInt stream, Player[j+1].Figure.dx
	         WriteInt stream, Player[j+1].Figure.AnimPos
	         WriteInt stream, Player[j+1].Figure.target.x
	         WriteInt stream, Player[j+1].Figure.inElevator
             If (Player[j+1].Figure.inRoom <> Null) Then WriteInt stream, Player[j+1].Figure.inRoom.uniqueID Else WriteInt stream, 0
             If (Player[j+1].Figure.clickedToRoom <> Null) Then WriteInt stream, Player[j+1].Figure.clickedToRoom.uniqueID Else WriteInt stream, 0
             If (Player[j+1].Figure.toRoom <> Null) Then WriteInt stream, Player[j+1].Figure.toRoom.uniqueID Else WriteInt stream, 0
             If (Player[j+1].Figure.fromRoom <> Null) Then WriteInt stream, Player[j+1].Figure.fromRoom.uniqueID Else WriteInt stream, 0
             SendUDP(i)
	       EndIf
         Next
       EndIf
	 EndIf
   Next
  End Method

  Method SendProgramme(playerID:Int, programme:TProgramme[])
   For Local i:Int = 0 To 3
     If IP[i]<> Null
     ' Stream.Flush
       WriteInt Stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte Stream, NET_SENDPROGRAMME
 	   WriteMyIP()
       WriteByte stream, playerID
	   WriteInt stream, programme.length
	   For Local i:Int = 0 To programme.length-1
         WriteByte stream, programme[i].isMovie
         WriteInt stream, programme[i].id
       Next
	   SendReliableUDP(i, 250, -1, "SendProgramme")
     EndIf
   Next
  End Method


  Method SendMovieAgencyChange(methodtype:Byte, playerID:Int, newID:Int=-1, slot:Int=-1, programme:TProgramme)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i], Port[i])
       WriteInt Stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte stream, NET_MOVIEAGENCY_CHANGE
 	   WriteMyIP()
       WriteByte stream, playerID
       WriteByte stream, methodtype
       WriteInt stream, newid
       WriteInt stream, slot
       WriteByte stream, programme.isMovie
       WriteInt stream, programme.id
       SendReliableUDP(i, 250, 10, "SendMovieAgencyChange")
	   Print "send newID"+newID
     EndIf
   Next
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
					  Player[ RemotePlayerID ].ProgrammeCollection.AddProgramme(TProgramme.GetProgramme(ProgrammeID))
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
'    If isMovie Then Player[ RemotePlayerID ].ProgrammeCollection.AddMovie(TProgramme.GetMovie(ProgrammeID))
'    If Not isMovie Then Player[ RemotePlayerID ].ProgrammeCollection.AddSerie(TProgramme.GetSeries(ProgrammeID))
  End Method

  Method SendGameReady(playerID:Int, onlyTo:Int=-1)
   For Local i:Int = 0 To 3
     If IP[i]<> Null
      If onlyto <0 Or onlyto=i Then
       WriteInt Stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte Stream, NET_GAMEREADY
 	   WriteMyIP()
       WriteByte Stream, playerID
       SendReliableUDP(i, 1000, 5, "SendGameReady")
      EndIf
     EndIf
   Next
   Print "NET: sent GameReadyFlag (my PlayerID: "+playerID+")"
  End Method

  Method SendGameStart()
   For Local i:Int = 0 To 3
     If IP[i]<> Null
       'Stream.Flush
       WriteInt Stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte Stream, NET_STARTGAME
 	   WriteMyIP()
       SendReliableUDP(i, 100, -1, "SendGameStart")
'       SendUDP(i)
     EndIf
   Next
  End Method

  'add = 1 - added, add = 0 - removed
  Method SendPlanProgrammeChange(playerID:Int, programmeBlock:TProgrammeBlock, add:Byte=1)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i])
       'Stream.Flush
       WriteInt Stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte Stream, NET_PLAN_PROGRAMMECHANGE
 	   WriteMyIP()
       WriteByte Stream, playerID
       WriteByte Stream, add
       WriteInt stream,  programmeBlock.Pos.x
       WriteInt stream,  programmeBlock.Pos.y
       WriteInt stream,  programmeBlock.StartPos.x
       WriteInt stream,  programmeBlock.StartPos.y
       WriteInt Stream, programmeBlock.sendhour
       WriteInt Stream, programmeblock.id
       WriteInt stream, programmeblock.Programme.id
       SendUDP(i)
     EndIf
   Next
  End Method

  Method SendContract(playerID:Int, contract:TContract[])
   If contract <>Null
     For Local i:Int = 0 To 3
       If IP[i]<> Null
       ' Stream.Flush
         WriteInt stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
         WriteByte stream, NET_SENDCONTRACT
         WriteMyIP()
         WriteByte stream, playerID
	     WriteInt stream, contract.length
	   For Local i:Int = 0 To contract.length-1
         WriteInt stream, contract[i].id
       Next
         SendReliableUDP(i, 250, -1, "SendContract")
       EndIf
     Next
   EndIf
   'Print "net: send contract width id:"+contract.id
  End Method

  Method SendPlanAdChange(playerID:Int, AdBlock:TAdBlock, add:Byte=1)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i])
       'Stream.Flush
       WriteInt Stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte Stream, NET_PLAN_ADCHANGE
 	   WriteMyIP()
       WriteByte Stream, playerID
       WriteByte Stream, add
       WriteInt stream,  adblock.Pos.x
       WriteInt stream,  adblock.Pos.y
       WriteInt stream,  adblock.StartPos.x
       WriteInt stream,  adblock.StartPos.y
       WriteInt Stream, adblock.senddate
       WriteInt Stream, adblock.senddate
       WriteInt Stream, adblock.id
       WriteInt Stream, adblock.contract.id
       SendUDP(i)
       Print "send change: adblock"+adblock.id
     EndIf
   Next
  End Method

  Method SendStationChange(playerID:Int, station:TStation, newaudience:Int, add:Byte=1)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i])
       'Stream.Flush
       WriteInt Stream, SendID
		WriteInt Stream, not NET_PACKET_RELIABLE
       WriteByte Stream, NET_STATIONCHANGE
 	   WriteMyIP()
       WriteByte Stream, playerID
       WriteByte Stream, add
       WriteInt Stream,  station.pos.x
       WriteInt Stream,  station.pos.y
       WriteInt Stream,  station.reach
       WriteInt Stream,  station.price
       WriteInt Stream,  newaudience
       SendUDP(i)
     EndIf
   Next
  End Method

  Method SendElevatorSynchronize()
   ' Print "NET: sent playerposition"
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i]) And game.playerID=1 'IP[i]<> Null And IP[i] <> intMyIP And Player[MyID]<>Null And game.playerID=1
       WriteInt stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte Stream, NET_ELEVATORSYNCHRONIZE
 	   WriteMyIP()
       WriteByte  stream, MyID
	   WriteFloat stream, game.timeSinceBegin
       WriteInt   stream, Building.Elevator.upwards
       WriteFloat stream, Building.Elevator.Pos.x
       WriteFloat stream, Building.Elevator.Pos.y
       WriteInt   stream, Building.Elevator.open
	   Local FloorCount:Int = Building.Elevator.FloorRouteList.Count()
	   WriteInt stream, FloorCount
	   If FloorCount > 0
		 For Local FloorRoute:TFloorRoute = EachIn Building.Elevator.FloorRouteList
           WriteInt stream, FloorRoute.call
           WriteInt stream, FloorRoute.direction
	       WriteInt stream, FloorRoute.floornumber
	       WriteInt stream, FloorRoute.who
	     Next
	   EndIf
	   SendReliableUDP(i, 150,1, "SendElevatorSynchronize")
	   LastElevatorSynchronize = MilliSecs()
'  	   SendUDP(i)
     EndIf
   Next
  End Method

  Method SendElevatorRouteChange(floornumber:Int, call:Int=0, who:Int, First:Byte=False)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i]) And Player[MyID]<>Null
       WriteInt Stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte Stream, NET_ELEVATORROUTECHANGE
 	   WriteMyIP()
       WriteByte Stream, MyID
       WriteInt Stream, call
       WriteInt Stream, floornumber
       WriteInt Stream, who
       WriteByte Stream, First
  	   SendReliableUDP(i, 150, 5, "SendElevatorRouteChange")
     EndIf
   Next
  End Method

  'typ = 1 - remove from plan, typ = 0 - sell, typ = 2 - readd, typ = 3 - remove from collection
  Method SendProgrammeCollectionChange(playerID:Int, programme:TProgramme, typ:Byte=0)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i])
       'Stream.Flush
       WriteInt Stream, SendID
		WriteInt Stream, not NET_PACKET_RELIABLE
       WriteByte stream, NET_PROGRAMMECOLLECTION_CHANGE
 	   WriteMyIP()
       WriteByte stream, playerID
       WriteInt stream, programme.id
       If     programme.isMovie Then WriteByte stream, 1
       If Not programme.isMovie Then WriteByte stream, 0
       WriteByte stream, typ
       SendUDP(i)
     EndIf
   Next
  End Method


  Method SendNewsSubscriptionLevel(playerID:Int, genre:Byte, level:Byte)
   For Local i:Int = 0 To 3
    If IsNoComputerNorMe(IP[i],Port[i])
       WriteInt  stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte stream, NET_NEWSSUBSCRIPTIONLEVEL
 	   WriteMyIP()
       WriteByte Stream, playerID
       WriteByte stream, genre
       WriteByte stream, level
       SendReliableUDP(i, 250, 100, "SendNewsSubscriptionLevel")
     EndIf
   Next
  End Method

  Method SendNews(playerID:Int, news:TNews)
   For Local i:Int = 0 To 3
    If IsNoComputerNorMe(IP[i],Port[i])
       WriteInt  stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte stream, NET_SENDNEWS
 	   WriteMyIP()
       WriteByte Stream, playerID
       WriteInt  stream, news.id
       SendReliableUDP(i, 250, -1, "SendNews")
     EndIf
   Next
  End Method

  'add = 1 - added, add = 0 - removed
  Method SendPlanNewsChange(playerID:Int, newsBlock:TNewsBlock, remove:int=0)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i])
       WriteInt stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
       WriteByte stream, NET_PLAN_NEWSCHANGE
 	   WriteMyIP()
       WriteByte stream, playerID
       WriteInt stream,  remove
       WriteInt stream,  newsBlock.Pos.x
       WriteInt stream,  newsBlock.Pos.y
       WriteInt stream,  newsBlock.startPos.x
       WriteInt stream,  newsBlock.startPos.y
       WriteInt stream,  newsBlock.id
       WriteInt stream,  newsBlock.paid
       WriteInt stream,  newsBlock.news.id
       WriteInt stream, newsBlock.sendslot
       SendReliableUDP(i, 250, -1, "SendPlanNewsChange")
     EndIf
   Next
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

	Local newsblock:TNewsblock = Player[RemotePlayerID].ProgrammePlan.getNewsBlock(newsblockID)
    If newsblock <> Null Then
		if remove then Player[RemotePlayerID].ProgrammePlan.removeNewsBlock(newsBlock)
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
    Player[ RemotePlayerID ].newsabonnements[genre] = level
	Print "set genre "+genre+" to level "+level+" for player "+RemotePlayerID
  End Method


  Method GotPacket_SendNews(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(stream)
    Local newsID:Int = ReadInt(stream)
	Local news:TNews = TNews.GetNews(newsID)
    If news <> Null
      TNewsBlock.Create("",0,-100, RemotePlayerID , 60*(3-Player[ RemotePlayerID ].newsabonnements[news.genre]), news)
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
			Player[ RemotePlayerID ].ProgrammeCollection.AddProgramme(Programme)
          TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, RemoteplayerID)
		EndIf
		If typ = 0
 	      Player[ RemotePlayerID ].finances[Game.getWeekday()].SellMovie(Programme.ComputePrice())
          TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, RemoteplayerID)
		EndIf
	    'remove from Plan (Archive - ProgrammeToSuitcase)
	    If typ = 1 Then Player[ RemotePlayerID ].ProgrammePlan.RemoveProgramme(programme)
        'remove from Collection (Archive - RemoveProgramme)
		If typ = 3 Then Player[ RemotePlayerID ].ProgrammeCollection.RemoveProgramme( programme )
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
    If First Then Building.Elevator.passenger = Player[ RemotePlayerID ].figure
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
      Player[remoteplayerID].finances[Game.getWeekday()].PayStation(price)
      'Player[remoteplayerID].maxaudience = newaudience
      Player[remoteplayerID].maxaudience = StationMap.CalculateAudienceSum(remoteplayerID)
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
      Local Contract:TContract = Player[ RemotePlayerID ].ProgrammeCollection.getContract(ContractID)
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
    Player[ remotePlayerID ].ProgrammePlan.RefreshAdPlan(senddate)
    If add
      Player[ RemotePlayerID ].ProgrammePlan.AddContract(adblock.contract)
      'Print "NET: ADDED adblock:"+Adblock.Title+" to Player:"+RemotePlayerID
    Else
      Player[ RemotePlayerID ].ProgrammePlan.RemoveContract(adblock.contract)
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
    Local programmeblock:TProgrammeBlock = Player[RemotePlayerID].ProgrammePlan.GetProgrammeBlock(programmeBlockID)
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
'      Player[ RemotePlayerID ].ProgrammePlan.RemoveProgramme(Programmeblock.programme)
      'Print "NET: REMOVED programme:"+Programmeblock.programme.Title+" from Player:"+RemotePlayerID
    EndIf
 End Method

  Method GotPacket_GameReady(_IP:Int, _Port:int)
   Local RemotePlayerID:Int = ReadByte(Stream)
 '  Game.networkgameready = 1
   Game.gamestate = 4
   For Local i:Int = 0 To 3
     If IP[i]= Null And Game.playerID = 1
      Player[ i + 1 ].networkstate = 1
     EndIf
   Next
   Print "got game ready from "+RemotePlayerID
   Player[ RemotePlayerID ].networkstate = 1 'ready

   Print "NET: got GameReadyFlag from Player:"+Player[ RemotePlayerID ].name + " ("+RemotePlayerID+")"

   'if server then wait until all players are ready... then send startcommand
   If Game.playerID = 1 Then
     If Player[ 1 ].networkstate = 1 And Player[ 2 ].networkstate = 1 And Player[ 3 ].networkstate = 1 And Player[ 4 ].networkstate = 1
       SendGameStart()
       Print "NET: send startcommand"
     EndIf
   Else
     If Player[1].ProgrammeCollection.movielist.count() >= Game.startMovieAmount And..
        Player[2].ProgrammeCollection.movielist.count() >= Game.startMovieAmount And..
        Player[3].ProgrammeCollection.movielist.count() >= Game.startMovieAmount And..
        Player[4].ProgrammeCollection.movielist.count() >= Game.startMovieAmount And..
        Player[1].ProgrammeCollection.contractlist.count() >= Game.startAdAmount And..
        Player[2].ProgrammeCollection.contractlist.count() >= Game.startAdAmount And..
        Player[3].ProgrammeCollection.contractlist.count() >= Game.startAdAmount And..
        Player[4].ProgrammeCollection.contractlist.count() >= Game.startAdAmount Then
        Player[ Game.playerID ].networkstate = 1
        SendGameReady(Game.playerID, 0)
     EndIf
   EndIf
  End Method


  Method GotPacket_SendContract(_IP:Int, _Port:int)
    Local RemotePlayerID:Int = ReadByte(Stream)
	Local ContractCount:Int = ReadInt(stream)
    Local contractID:Int
    For Local i:Int = 0 To ContractCount-1
      contractID:Int = ReadInt(stream)
      Player[ RemotePlayerID ].ProgrammeCollection.AddContract(TContract.getContract(contractID))
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
      Player[ RemotePlayerID ].ProgrammeCollection.AddProgramme(TProgramme.GetProgramme(ProgrammeID))
    Next
	Print "got "+ProgrammeCount+" programmes for player:"+RemotePlayerID
	'Print "NET: added programme with ID:"+ProgrammeID+" to Player "+RemotePlayerID
    'Print "--->Programme:"+TProgramme.GetMovie(ProgrammeID).Title
  End Method

  Method GotPacket_PlayerPosition(_IP:Int, _Port:int)
     Local RemotePlayerID:Int = ReadByte(Stream)
     If Player[ RemotePlayerID] = Null Then Print "Player "+RemotePlayerID+" not found"
     Local x:Float = ReadFloat(stream)
     Local y:Float = ReadFloat(stream)

	 Player[ RemotePlayerID ].Figure.dx					= ReadInt(stream)
     Player[ RemotePlayerID ].Figure.AnimPos			= ReadInt(Stream)
     Player[ RemotePlayerID ].Figure.target.x			= ReadInt(stream)
     Player[ RemotePlayerID ].Figure.inElevator			= ReadInt(stream)

     'only synchronize position when not in Elevator
	 If Building.Elevator.passenger <> Player[ RemotePlayerID ].figure 'Not Player[ RemotePlayerID ].Figure.inElevator
	   Player[ RemotePlayerID ].Figure.pos.x               = x
	   Player[ RemotePlayerID ].Figure.pos.y               = y
	 End If

     If Player[ RemotePlayerID ].Figure.inElevator
	   Building.Elevator.passenger = Player[ RemotePlayerID ].Figure
	   Player[ RemotePlayerID ].Figure.pos.x =  Int(Building.Elevator.GetDoorCenter() - Int(Player[ RemotePlayerID ].Figure.FrameWidth/2) - 3)
	 EndIf

	 Local RoomID:Int = ReadInt(stream)
     Local ClickedRoomID:Int = ReadInt(Stream)
     Local toRoomID:Int = ReadInt(stream)
     Local fromRoomID:Int = ReadInt(stream)
		If RoomID = 0 Then Player[RemotePlayerID].Figure.inRoom = Null
		If Player[RemotePlayerID].figure.inroom <> Null Then
			If RoomID > 0 Then If Player[RemotePlayerID].Figure.inRoom.uniqueID <> RoomID Then
				Player[RemotePlayerID].Figure.inRoom = TRooms.GetRoomFromID(RoomID)
				If Player[RemotePlayerID].Figure.inRoom.name = "elevator" Then
					Building.Elevator.waitAtFloorTimer = MilliSecs() + Building.Elevator.PlanTime
				EndIf
			EndIf
		EndIf
     If ClickedRoomID = 0 Then Player[ RemotePlayerID ].Figure.clickedToRoom = Null
     If ClickedRoomID > 0 Then
         Player[ RemotePlayerID ].Figure.clickedToRoom = TRooms.GetRoomFromID(ClickedRoomID)
     EndIf
     If toRoomID = 0 Then Player[ RemotePlayerID ].Figure.toRoom = Null
     If toRoomID > 0 Then Player[ RemotePlayerID ].Figure.toRoom = TRooms.GetRoomFromID(toRoomID)
     If fromRoomID = 0 Then Player[ RemotePlayerID ].Figure.fromRoom = Null
     If fromRoomID > 0 And Player[ RemotePlayerID ].figure.fromroom <> Null Then
	   If Player[ RemotePlayerID ].Figure.fromRoom.uniqueID <> fromRoomID
         Player[ RemotePlayerID ].Figure.fromRoom = TRooms.GetRoomFromID(fromRoomID)
	   EndIf
     EndIf
  End Method

  Method GotPacket_PlayerDetails(_IP:Int, _Port:int)
     Local RemotePlayerID:Int = ReadByte(Stream)
     Local tmplen:Int
     tmplen = ReadInt(Stream);Local playername:String = ReadString(Stream, tmplen)
     tmplen = ReadInt(Stream);Local channelname:String = ReadString(Stream, tmplen)
     Local colR:Byte = ReadByte(Stream)
     Local colG:Byte = ReadByte(Stream)
     Local colB:Byte = ReadByte(Stream)
     Local figurebase:Byte = ReadByte(Stream)
     If figurebase <> Player[ RemotePlayerID].figurebase Then Player[ RemotePlayerID].UpdateFigureBase(figurebase)
     If Player[ RemotePlayerID].color.colR <> colR Or..
        Player[ RemotePlayerID].color.colG <> colG Or..
        Player[ RemotePlayerID].color.colB <> colB
       Player[ RemotePlayerID].color.setCOlor(colR, colG, colB)
       Player[ RemotePlayerID].RecolorFigure(TPlayerColor.GetColor(colR, colG,colB))
     EndIf
     If RemotePlayerID <> game.playerID
	   Player[ RemotePlayerID ].name = playername
       Player[ RemotePlayerID ].channelname = channelname

	   MenuPlayerNames[RemotePlayerID-1].value = playername
       MenuChannelNames[RemotePlayerID-1].value = channelname
     EndIf
	'if debugmode Print "NET: got PlayerDetails"
  End Method

	Method GotPacket_PlayerIPs(_IP:Int, _Port:int)
		For Local i:Int = 0 To 3
			IP[ i ]   = ReadInt(Stream)
			Port[ i ] = ReadInt(Stream)
			If IP[ i ] <> Null
				Player[i+1].Figure.ControlledByID= i+1
			else
				Player[i+1].Figure.ControlledByID= 0
			endif
		Next
		'if debugmode Print "NET: got synchronize PlayerIP-packet"
	End Method

	Method GotPacket_Join(_IP:Int, _Port:int)
		Print "got join from "+TNetwork.DottedIP(_IP)+":"+_Port
		'it's the user acting as server knocking on the door
	If Not IsConnected And isHost Then
	  NetAck (RecvID, _IP, _Port)             ' Send ACK
      IsConnected = True        ' Connected
	EndIf

    'someone wants to join
    If _IP <> GetMyIP() Or _Port <> GetMyPort() Then
      'sends to joining user, which ip is now on slot X
      'Print "NET: "+TNetwork.DottedIP(_IP)+" ("+_PORT+") wants to join - Send setslot"
      WriteInt Stream, SendID
		WriteInt Stream, NET_PACKET_RELIABLE
      WriteByte Stream, NET_SETSLOT
      WriteMyIP()
      WriteInt Stream, _IP
      WriteInt Stream, _Port
      WriteByte Stream, GetFreeSlot()
	  SendReliableUDPtoIP(_IP, _Port,  150, -1, "SetSlot (Got Join)")
    EndIf
  End Method

	Method GotPacket_AnnounceGame(_IP:Int, _Port:int)
		Local teamamount:Int	= ReadByte(Stream)
		Local titlelength:Byte	= ReadByte(stream)
		Local title:String		= ReadString(stream, titlelength)
		print "got announcement from" + _IP
		'If _ip <> intLocalIP then NetgameLobby_gamelist.addUniqueEntry(title, title+"  (Spieler: "+teamamount+" von 4)","",TNetwork.DottedIP(_ip),_Port,0, "HOSTGAME")
	End Method

  Method GotPacket_ChatMessage(_IP:Int, _Port:int)
    If _IP <> intLocalIP Then
     Local RemotePlayerID:Int = ReadInt(Stream)
     Local ChatMessageLen:Int = ReadInt(Stream)
     Local ChatMessage:String = ReadString(Stream, ChatMessageLen)
 	  Local teamamount:Int = ReadByte(Stream)
      If Game.gamestate = 3 Or Game.gamestate = 4 Then
        GameSettings_Chat.AddEntry("", ChatMessage, RemotePlayerID,"", "", MilliSecs())
      Else
        InGame_Chat.AddEntry("",ChatMessage, RemotePlayerID,"", "", MilliSecs())
      EndIf
      NetAck (RecvID, _IP, _Port)                 ' Send ACK
    EndIf
  End Method

  Method GotPacket_SetSlot(_IP:Int, _Port:int)
             Local aimedIP:Int = ReadInt(Stream)
             Local aimedPort:Int = ReadInt(Stream)
   			 Local slot:Byte   = ReadByte(Stream)
             ip[slot-1] = aimedIP
             Port[slot-1] = aimedPort
			 Player[slot].name = game.username
			 MenuPlayerNames[slot-1].value = game.username
			 MenuChannelNames[slot-1] .value = game.userchannelname
			 Local OldRecvID:Int = RecvID
             If     Game.onlinegame Then intOnlineIP = aimedIP  'on server the ip was another one - may be from the dialup-networkcard
             If Not Game.onlinegame Then intLocalIP = aimedIP  'on server the ip was another one - may be from the dialup-networkcard
             localIP = TNetwork.DottedIP(aimedIP)
             Game.gamestate=3
		     NetAck (RecvID, _IP, _Port)                 ' Send ACK
             MyID = slot
             Game.playerID = slot
             IsConnected = True
           '   Stream.Flush 'alten Mist raushauen, neuen rein
	         'sends to server, which ip is now on slot X
	          WriteInt Stream, SendID
					WriteInt Stream, not NET_PACKET_RELIABLE
  	          WriteByte Stream, NET_SLOTSET
 	          WriteMyIP()
	          WriteByte stream, slot
	          WriteInt stream, OldRecvID
	          WriteInt stream, Len(game.userchannelname)
	          WriteInt stream, Len(game.username)
	          WriteString stream, game.userchannelname
	          WriteString stream, game.username
'			  SendUDP(0)
	          stream.SendUDPMsg  _IP, _Port
              SendID:+1
              If debugmode Print "NET: set to slot "+slot+" and send slotset to server"
  End Method

  Method SendState()
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i], Port[i]) And Game.playerID = 1
	    WriteInt Stream, SendID
		WriteInt Stream, not NET_PACKET_RELIABLE
	    WriteByte Stream, NET_STATE
  	    WriteMyIP()
	    WriteFloat Stream, Game.minutesOfDayGone
	    WriteFloat Stream, Game.speed
	  SendUDP(i)
	 EndIf
   Next
  End Method

	Method UpdateUDP(fromNotConnectedPlayer:Int = 0)
		If IsConnected Or fromNotConnectedPlayer ' Updates

			'Aller 1500ms einen Status rueberschicken (unbestaetigt)
			If isHost And MilliSecs() >= MainSyncTime+ 1500*self.GetSyncSpeedFactor()
				SendPlayerIPs()
				'if Abs(MilliSecs() - LastElevatorSynchronize)>500 Then SendElevatorSynchronize()
				SendState()
				MainSyncTime = MilliSecs()
			EndIf

			'Aller 4000ms einen Status rueberschicken (unbestaetigt)
			If MilliSecs() >= UpdateTime + 4000*self.GetSyncSpeedFactor()
				SendState()
				SendPlayerDetails()
				UpdateTime = MilliSecs()
			EndIf

			'Ping aller 1 Sekunde absetzen (unbestaetigt)
			If MilliSecs() >= PingTimer + 1000*self.GetSyncSpeedFactor()
				SendPlayerPosition()
				For Local i:Int = 0 To 3
					If IP[i]<> Null And IP[i] <> IP[Game.playerID-1]
						WriteInt stream, SendID
							WriteInt Stream, not NET_PACKET_RELIABLE
						WriteByte stream, NET_PING
						WriteMyIP()
						WriteInt stream, game.playerID
						SendUDP(i)
					EndIf
					PingTime[ i ] = MilliSecs()
				Next
				PingTimer = MilliSecs()
			EndIf
		EndIf 'is connected

		If GameSettingsOkButton_Announce.iscrossed() And isHost And MilliSecs() >=  AnnounceTime + Game.onlinegame*4000*self.GetSyncSpeedFactor() + 1000
			AnnounceTime = MilliSecs()
			SendGameAnnouncement()
		EndIf

		Local bMsgIsNew:Int
		While stream.RecvAvail() ' Then
			stream.RecvMsg()
			RecvID = ReadInt(Stream)
			Local data:Int   		= ReadByte(Stream)
			Local reliablePacket:Int= ReadInt(stream)
			Local _IP:Int     		= ReadInt(stream)
			Local _Port:Int   		= ReadInt(stream)
			print "Pakete warten " + data + " " + RecvID + " IP:"+_IP + " " + TNetwork.DottedIP(_IP)
'			If Not Game.onlinegame
'				_IP:Int     = stream.GetMsgIP()
'				_Port:Int   = stream.GetMsgPort()
'			EndIf

	    Select data
			Case NET_JOIN					GotPacket_Join(_IP,_Port)				' JOIN PACKET
			Case NET_ANNOUNCEGAME			GotPacket_AnnounceGame(_IP, _Port)		' A game was announced
			Case NET_SETSLOT				GotPacket_SetSlot(_IP,_Port)			' Answer of join-request, only sent to join-sender
											IsConnected = True 						' we have connected and server send setslot
			Case NET_PLAYERIPS				GotPacket_PlayerIPs(_IP,_Port)			' synchronizing PlayerIPs and Ports
			Case NET_PLAYERDETAILS			GotPacket_PlayerDetails(_IP, _Port)		' name, channelname and so on
			Case NET_PLAYERPOSITION			GotPacket_PlayerPosition(_IP, _Port)	' x,y, room, target...
			Case NET_CHATMESSAGE			GotPacket_ChatMessage(_IP,_Port)		' someone has written something into the chat
			Case NET_MOVIEAGENCY_CHANGE		GotPacket_SendMovieAgencyChange(_IP,_Port) ' got change of programmes in MovieAgency from Server
			Case NET_SENDPROGRAMME			GotPacket_SendProgramme(_IP,_Port)		' got StartupProgramme from Server
			Case NET_SENDCONTRACT			GotPacket_SendContract(_IP,_Port)       ' got StartupContract from Server
			Case NET_SENDNEWS				GotPacket_SendNEWS(_IP,_Port)	       ' got News from Server
			Case NET_NEWSSUBSCRIPTIONLEVEL	GotPacket_NewsSubscriptionLevel(_IP, _Port)
			Case NET_GAMEREADY				GotPacket_GameReady(_IP,_Port)				' got readyflag
			Case NET_STARTGAME				Game.networkgameready = 1					' got startcommand
			Case NET_PLAN_PROGRAMMECHANGE	GotPacket_Plan_ProgrammeChange(_IP,_Port)	' got flag to change Programme of Player
			Case NET_PLAN_NEWSCHANGE		GotPacket_Plan_NewsChange(_IP,_Port)		' got flag to change Programme of Player
			Case NET_PROGRAMMECOLLECTION_CHANGE
											GotPacket_ProgrammeCollectionChange(_IP,_Port)	'got change of programme (remove, readd, remove from plan ...)
			Case NET_PLAN_ADCHANGE		    GotPacket_Plan_AdChange(_IP,_Port)			' got flag to change Programme of Player
        	Case NET_STATIONCHANGE			GotPacket_StationChange(_IP,_Port)			' got flag to change Programme of Player
			Case NET_ELEVATORSYNCHRONIZE	GotPacket_ElevatorSynchronize(_IP,_Port)	' got flag to change Programme of Player
			Case NET_ELEVATORROUTECHANGE	GotPacket_ElevatorRouteChange(_IP,_Port)	' got flag to change Programme of Player
			Case NET_SLOTSET			    Local slot:Byte			= ReadByte(Stream)-1
											Local OldRecvID:Int		= ReadInt(stream)
											Local channellen:Int	= ReadInt(stream)
											Local namelen:Int		= ReadInt(stream)
											Local channel:String	= ReadString(stream, channellen)
											Local name:String		= ReadString(stream, namelen)
											ip[slot]	= _IP
											Port[slot]	= _Port
											TReliableUDP.GotAckPacket(OldRecvID, _IP, _Port)
											GameSettings_Chat.AddEntry("", name+" hat sich in das Spiel eingeklinkt (Sender: "+channel+")", 0,"", "", MilliSecs())
											If Game.playerID = 1 Then SendPlayerIPs()
			Case NET_PING					Local RemotePlayerID:Int = ReadInt(stream)	' Received Ping, Send Pong
											WriteInt stream, SendID
											WriteInt Stream, not NET_PACKET_RELIABLE
											WriteByte stream, NET_PONG
											WriteMyIP()
											WriteInt stream, MyID
											SendUDP(RemotePlayerID-1)
			Case NET_PONG				    Local RemotePlayerID:Int = ReadInt(stream)	' Ping / Pong - Calculate Ping
											If IP[ RemotePlayerID-1 ] = _IP
												myPing[ RemotePlayerID ] = (MilliSecs() - PingTime[ RemotePlayerID ]) / 2
											EndIf
											'Game.time:+ Int(myPing / 1000)
			Case NET_ACK				    Local AckForSendID:Int = ReadInt(Stream)	' ACK PACKET
											TReliableUDP.GotAckPacket(AckForSendID, _IP, _Port)
											RemoveNetObj AckForSendID   				' Remove Reliable Packet (ACK has been received)
			Case NET_STATE		 	        Game.minutesOfDayGone = ReadFloat(Stream)
											Game.speed = ReadFloat(Stream)
											' State Update
			Case NET_UPDATE					Local remotePlayerID:Int = ReadInt(Stream)	' Full update, align
											Player[remotePlayerID].Figure.pos.x = ReadFloat(stream)          ' X
											Player[remotePlayerID].Figure.pos.y = ReadFloat(stream)          ' Y
			Case NET_QUIT			        Local remotePlayerID:Byte = ReadByte(Stream)	' Player Quits
											IP[remoteplayerid - 1] =0
											Port[remoteplayerid - 1] =0
											Player[remoteplayerid].Figure.ControlledByID=-1
											TReliableUDP.DeletePacketsForIP(_IP,_Port)
											Print "Player "+remoteplayerid+" left the game..."
											'IsConnected = 2                     ' Quit
			End Select

			if reliablePacket then	NetAck (RecvID, _IP, _Port)

		Wend 'Endif
		stream.Flush()
		TReliableUDP.ReSend() 'send again all not ACKed packets
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
		WriteInt Stream, SendID
		WriteInt Stream, not NET_PACKET_RELIABLE
		WriteByte stream, NET_ACK
		WriteMyIP()
		WriteInt Stream, RecvID
		'SendUDP
		stream.SendUDPMsg  _IP, _Port
		SendID:+1	         ' Increment send counter
	End Method

  'sends the current packet to player i
  Method SendUDP(i:Int=0)
    stream.SendUDPMsg IP[i], Port[i]
	SendID:+1	         ' Increment send counter
  End Method

  'sends the current packet to player i
  'and adds it to the reliableUDP-packets which are handled automatically
  'If MaxRetry is <0 then it will be tried forever
  Method SendReliableUDP(peerID:Int=0, retrytime:Int = 200, MaxRetry:Int = -1, desc:String="")
    BackupStream(MyBank)
    TReliableUDP.Create(SendID, IP[peerID], Port[peerID], MyBank, retrytime, MaxRetry, desc)
    stream.SendUDPMsg IP[peerID], Port[peerID]
    BackupStream(MyBank)
	SendID:+1	         ' Increment send counter
  End Method

  Method SendReliableUDPtoIP(_IP:Int, _Port:int,retrytime:Int = 200, MaxRetry:Int = -1, desc:String="")
    BackupStream(MyBank)
    TReliableUDP.Create(SendID, _IP, _Port, MyBank, retrytime, MaxRetry, desc)
    stream.SendUDPMsg _IP, _Port
    BackupStream(MyBank)
	SendID:+1	         ' Increment send counter
  End Method

  ' // NetConnect attempts to connect client to host
  Method NetConnect()
    Local waittime:Int = MilliSecs() + 2500
    SetClsColor 0, 0, 0
    SendJoin()
    Print "isconnected:"+IsConnected
    Repeat
	  DrawText "Verbinde...", 5, 5
	  UpdateUDP(True)
    Until IsConnected = True Or waittime - MilliSecs() < 0
  End Method

  ' // NetDisconnect schliesst eine Netzwerkverbindung
  Method NetDisconnect(RealQuit:Byte=True)
    Local QuitID:Int = 0
        QuitID = SendID
		WriteInt Network.stream, SendID
	    WriteByte Network.stream, NET_QUIT
		WriteMyIP()
        WriteByte Network.stream, Game.playerID
		SendReliableUDP(0, 250,10, "NetDisconnect")

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
       If ReliableUDP.Retry >=3 Then Print "UDP: recv ACK and deleted:"+ReliableUDP.SendID+" for:"+TNetwork.DottedIP(fromIP)

       TReliableUDP.List.Remove(ReliableUDP)
       Return 1
     EndIf
    Next
    Return 0
  End Function

  'send all packets which are not ACKed up to now but are requested to be reliable
  Function ReSend()
  	For Local ReliableUDP:TReliableUDP = EachIn TReliableUDP.List
  	  If ReliableUDP.LastSent + ReliableUDP.retrytime < MilliSecs() Then
  	    Network.RestoreStream(ReliableUDP.content)
  	    Network.stream.SendUDPMsg ReliableUDP.targetIP, ReliableUDP.targetPort
		ReliableUDP.Retry:+1
		ReliableUDP.LastSent = MilliSecs()
  	    if ReliableUDP.Retry >=4 then Print "UDP: Re-sent:"+ReliableUDP.SendID+" ("+ReliableUDP.desc+")->"+TNetwork.DottedIP(ReliableUDP.targetIP)+":"+ReliableUDP.targetPort
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
	Print "cleared ReliablePackeList from IP:"+TNetwork.DottedIP(_IP)
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
		If Network.Stream = Null Then Return Null

		Local n:NetObj = New NetObj ' Create Packet
		n.id = id             ' Packet ID
		n.SID = Network.SendID        ' Send ID

		Select id
			Case 2            ' Quit Packet
				WriteInt Network.Stream, n.SID
				WriteByte Network.Stream, Network.NET_QUIT
				WriteByte Network.Stream, Game.playerID
		End Select

		Network.SendUDP			' Send UDP Message
		n.T = MilliSecs()		' Set Timer
		Return n
	End Function

  ' Resends Packets
	Method handle:Int()
		If Network.Stream = Null Then Return 0

		Select id
			Case 2 ' Quit Attempt (Never Drops)
				If MilliSecs() >= T + 100 					' Resend every 100ms
				    WriteInt Network.Stream, SID
					WriteByte Network.Stream, Network.NET_QUIT
					WriteByte Network.Stream, Game.playerID
					Network.SendUDP
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