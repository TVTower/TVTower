'base of all networkevents...
'added to the base networking functions are all methods to send and receive data from clients
'including playerposition, programmesending, changes of elevatorpositions etc.
Type TTVGNetwork
	' // Network Specific Declares
	Field SpeedFactor:Double 		= 0.1
	Field SpeedFactorLan:Double 	= 0.1
	Field SpeedFactorOnline:Double	= 1.0
	Field isHost% 					= False    				' Are you hosting or joining?
	Field IsConnected% 				= False   				' Are you connected?
	Field ServerIP:Int				= 0						' if 0 then: wow, I'm the server
	Field ServerPort:Int			= 0
	Field MyIP$ 					= TNetwork.DottedIP(TNetwork.GetHostIP("")) ' my local IP
	Field intMyIP% 					= TNetwork.IntIP(MyIP$) ' Int of server IP
	Field Stream:TUDPStream      							' UDP Stream
	Field myPing:Int[4], PingTime:Int[4], PingTimer:Int =0  ' Ping and Ping Timer
	Field UpdateTime:Int         							' Update Timer
	Field MainSyncTime:Int       							' Main Update Timer
	Field AnnounceTime:Int       							' Main Announcement Timer
	Field SendID%, RecvID%, lastRecv:Int[52] 				' Packet IDs and Duplicate checking Array
	Field MyID:Int = -1 'which playernumber is mine? - so which line of the iparray and so on
	Field IP%[4], Port:Short[4]  							' Client IP and Port
	Field debugmode:Byte = True  							' Toggles the display of debug messages
	Field bSentFull:Byte         							' Full update boolean
	Field n:NetObj, netList:TList = New TList 			' Packet Object and List
	Field LastOnlineRequestTimer:Int = 0
	Field LastOnlineRequestTime:Int = 10000   			'time until next action (getlist, announce...)
	Field LastOnlineHashCode:String = ""
	Field OnlineIP:String= ""                				' ip for internet
	Field intOnlineIP:Int= 0                 				' int version of ip for internet
	Field ChatSpamTime:Int = 0
	' // Networking Constants
	Global HOSTPORT:Byte 				= 4544              ' * IMPORTANT * This UDP port must not be blocked by
	Global ONLINEPORT:Byte 			= 4544            	' a routeror firewall, or CreateUDPStream will fail
	Global LOCALPORT:Byte 			= 4544
	Global NET_ACK:Byte    			= 1					' ALL: ACKnowledge
	Global NET_JOIN:Byte   			= 2					' ALL: Join Attempt
	Global NET_PING:Byte   			= 3					' Ping
	Global NET_PONG:Byte   			= 4					' Pong
	Global NET_UPDATE:Byte 			= 5					' Update
	Global NET_STATE:Byte  			= 6					' State update only
	Global NET_QUIT:Byte   			= 7					' ALL:    Quit
	Global NET_ANNOUNCEGAME:Byte   	= 8					' SERVER: Announce a game
	Global NET_SETSLOT:Byte 			= 9					' SERVER: command from server to set to a given playerslot
	Global NET_SLOTSET:Byte 			= 10				' ALL: 	  response to all, that IP uses slot X now
	Global NET_PLAYERLIST:Byte 		= 11				' SERVER: List of all players in our game
	Global NET_CHATMESSAGE:Byte 		= 12				' ALL:    a sent chatmessage ;D
	Global NET_PLAYERIPS:Byte 		= 13				' Packet contains IPs of all four Players
	Global NET_PLAYERDETAILS:Byte 	= 14				' ALL:    name, channelname...
	Global NET_PLAYERPOSITION:Byte 	= 15				' ALL:    x,y,room,target...
	Global NET_SENDPROGRAMME:Byte 	= 16				' SERVER: sends a Programme to a user for adding this to the players collection
	Global NET_GAMEREADY:Byte			= 17				' ALL:    sends a ReadyFlag
	Global NET_STARTGAME:Byte			= 18				' SERVER: sends a StartFlag
	Global NET_PLAN_PROGRAMMECHANGE:Byte = 19				' ALL:    playerprogramme has changed (added, removed and so on)
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
	Global NET_DELETE:Byte = 0
	Global NET_ADD:Byte    = 1
	Global NET_CHANGE:Byte = 2
	Global NET_BUY:Byte	   = 3
	Global NET_SELL:Byte   = 4
	Global NET_BID:Byte	   = 5
	Global NET_SWITCH:Byte = 6
	Global MyStream:TStream = New TStream
	Global MyBank:TBank = New TBank
	Global LastElevatorSynchronize:Int =0
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
		If Network.intMyIP% = 0
			Network.MyIP$ = fallbackip
			Network.intMyIP% = TNetwork.IntIP(fallbackip)
		EndIf
		Return Network
	End Function

	Method GetFreeSlot:Int()
		For Local i:Int = 0 To 3
			If IP[i] = 0 Then Return i+1
		Next
		Return -1
	End Method

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

  Method IsNoComputerNorMe:Byte(_IP:Int, _Port:Short)
    If _IP = Null Or _IP = 0 Then Return False 'it a computerplayer
    If IP[ Game.playerID-1 ] = _IP And Port[ Game.playerID-1 ] = _Port Then Return False 'it's me ;D
	Return True
  End Method

  Method WriteMyIP()
    If Not Game.onlinegame
      WriteInt stream, intMyIP
  	  WriteShort stream, HOSTPORT
	Else
      WriteInt stream, intOnlineIP
  	  WriteShort stream, ONLINEPORT
	EndIf
  End Method

  Method GetMyIP:Int()
    If game.onlinegame Then SpeedFactor = SpeedFactorOnline
    If Not game.onlinegame Then SpeedFactor = SpeedFactorLan
	If Game.onlinegame Then Return intOnlineIP
	Return intMyIP
  End Method

  Method GetMyPort:Short()
	If Game.onlinegame Then Return ONLINEPORT
	Return LOCALPORT
  End Method

  Method SendChatMessage(ChatMessage:String = "")
    For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i]) 'IP[i]<> Null And IP[i] <> intMyIP
      WriteInt Stream, SendID
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
       WriteByte stream, NET_PLAYERIPS
	   WriteMyIP()
       WriteInt Stream, IP[0]
       WriteShort Stream, Port[0]
       WriteInt Stream, IP[1]
       WriteShort Stream, Port[1]
       WriteInt Stream, IP[2]
       WriteShort Stream, Port[2]
       WriteInt Stream, IP[3]
       WriteShort Stream, Port[3]
       SendUDP(i)
   '    SendID:+1
     EndIf
      If IP[ i ] <> Null Then Player[i+1].Figure.ControlledByID= i+1
      If IP[ i ] = Null Or IP[ i ]=0 Then Player[i+1].Figure.ControlledByID= 0
    Next
  End Method

  Method SendJoin()
      WriteInt stream, SendID
      WriteByte stream, NET_JOIN
	  WriteMyIP()
      SendReliableUDP(0, 100,5, "SendJoin")
  End Method

  Method SendGameAnnouncement()
'    if debugmode Print "NET: announcing a game"
    If Game.gamestate <> 0 Then	 'no announcement when already in game
      If Not Game.onlinegame
	    WriteInt   stream, SendID
	    WriteByte  stream, NET_ANNOUNCEGAME
	    WriteMyIP()
	    WriteByte  stream, (GetFreeSlot()-1)
	    WriteByte  stream, Len(Game.title)
	    WriteString stream, Game.title
        stream.SendUDPMsg TNetwork.IntIP(GetBroadcastIP(MyIP)), Network.HOSTPORT
        SendID:+1
	  Else
        Local Onlinestream:TStream = ReadStream("http::www.tvgigant.de/lobby/lobby.php?action=AddGame&Titel="+UrlEncode(Game.title)+"&IP="+OnlineIP+"&Port="+ONLINEPORT+"&Spieler="+Self.getFreeSlot()+"&Hashcode="+LastOnlineHashCode)
		Local timeouttimer:Int = MilliSecs()+5000 '5 seconds okay?
	    Local timeout:Byte = False
	    If Not Onlinestream Then Throw ("Not Online?")
	    While Not Eof(Onlinestream) Or timeout
	     If timeouttimer < MilliSecs() Then timeout = True
	      Local responsestring:String = ReadLine(Onlinestream)
		  If responsestring <> Null
		    If responsestring <> "UPDATEDGAME" Then LastOnlineHashCode = responsestring
		  EndIf
        Wend
        CloseStream Onlinestream
  	  EndIf
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
       WriteInt Stream, Player[MyID].Figure.targetx
       WriteInt Stream, Player[MyID].Figure.oldtargetx
       WriteInt Stream, Player[MyID].Figure.toFloor
       WriteInt Stream, Player[MyID].Figure.onFloor
       WriteInt Stream, Player[MyID].Figure.calledElevator
       WriteInt Stream, Player[MyID].Figure.clickedToFloor
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
	         WriteInt stream, Player[j+1].Figure.targetx
	         WriteInt stream, Player[j+1].Figure.oldtargetx
	         WriteInt stream, Player[j+1].Figure.toFloor
	         WriteInt stream, Player[j+1].Figure.onFloor
	         WriteInt stream, Player[j+1].Figure.calledElevator
	         WriteInt stream, Player[j+1].Figure.clickedToFloor
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
       WriteByte Stream, NET_SENDPROGRAMME
 	   WriteMyIP()
       WriteByte stream, playerID
	   WriteInt stream, programme.length
	   For Local i:Int = 0 To programme.length-1
         WriteByte stream, programme[i].isMovie
         WriteInt stream, programme[i].pid
       Next
	   SendReliableUDP(i, 250, -1, "SendProgramme")
     EndIf
   Next
  End Method


  Method SendMovieAgencyChange(methodtype:Byte, playerID:Int, newID:Int=-1, slot:Int=-1, programme:TProgramme)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i], Port[i])
       WriteInt Stream, SendID
       WriteByte stream, NET_MOVIEAGENCY_CHANGE
 	   WriteMyIP()
       WriteByte stream, playerID
       WriteByte stream, methodtype
       WriteInt stream, newid
       WriteInt stream, slot
       WriteByte stream, programme.isMovie
       WriteInt stream, programme.pid
       SendReliableUDP(i, 250, 10, "SendMovieAgencyChange")
	   Print "send newID"+newID
     EndIf
   Next
  End Method

  Method GotPacket_SendMovieAgencyChange(_IP:Int, _Port:Short)
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
				    If locobject.Programme.pid = ProgrammeID tmpBlock[0] = locObject
				    If locobject.Programme.pid = newID tmpBlock[1] = locObject
				  EndIf
			    Next
				'Print "had to switch ID"+ProgrammeID+ " with ID"+newID+"/"+tmpBlock[1].programme.id
				If tmpBlock[0] <> Null And tmpBlock[1] <> Null
					tmpBlock[0].SwitchBlock(tmpBlock[1])
				EndIf
		Case NET_BUY
				For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			      If locobject.Programme <> Null
				    If locobject.Programme.pid = ProgrammeID
					  If     isMovie Then Player[ RemotePlayerID ].ProgrammeCollection.AddMovie(TProgramme.GetMovie(ProgrammeID))
    				  If Not isMovie Then Player[ RemotePlayerID ].ProgrammeCollection.AddSerie(TProgramme.GetSeries(ProgrammeID))
					  locObject.Programme = TProgramme.GetProgramme(newID)
					EndIf
				  EndIf
			    Next
		Case NET_BID
				For Local locObj:TAuctionProgrammeBlocks  = EachIn TAuctionProgrammeBlocks.List
			      If locobj.Programme <> Null
				    If locobj.Programme.pid = ProgrammeID
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
       WriteByte Stream, NET_PLAN_PROGRAMMECHANGE
 	   WriteMyIP()
       WriteByte Stream, playerID
       WriteByte Stream, add
       WriteInt stream,  programmeBlock.Pos.x
       WriteInt stream,  programmeBlock.Pos.y
       WriteInt stream,  programmeBlock.StartPos.x
       WriteInt stream,  programmeBlock.StartPos.y
       WriteInt Stream, programmeBlock.programme.sendtime
       WriteInt Stream, programmeBlock.programme.senddate
       WriteInt Stream, programmeblock.uniqueID
       If programmeblock.ParentProgramme = Null Then
         WriteInt Stream, -1
       Else
         WriteInt stream, programmeblock.ParentProgramme.pid
       EndIf
       WriteInt stream, programmeblock.Programme.pid
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
       WriteInt Stream, adblock.uniqueID
       WriteInt Stream, adblock.contract.id
       SendUDP(i)
       Print "send change: adblock"+adblock.uniqueID
     EndIf
   Next
  End Method

  Method SendStationChange(playerID:Int, station:TStation, newaudience:Int, add:Byte=1)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i])
       'Stream.Flush
       WriteInt Stream, SendID
       WriteByte Stream, NET_STATIONCHANGE
 	   WriteMyIP()
       WriteByte Stream, playerID
       WriteByte Stream, add
       WriteInt Stream,  station.x
       WriteInt Stream,  station.y
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
       WriteByte Stream, NET_ELEVATORSYNCHRONIZE
 	   WriteMyIP()
       WriteByte  stream, MyID
	   WriteFloat stream, game.timeSinceBegin
       WriteInt   stream, Building.Elevator.upwards
       WriteFloat stream, Building.Elevator.Pos.x
       WriteFloat stream, Building.Elevator.Pos.y
       WriteInt   stream, Building.Elevator.onFloor
       WriteInt   stream, Building.Elevator.toFloor
       WriteInt   stream, Building.Elevator.open
       WriteInt   stream, Building.Elevator.passenger
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
       WriteByte stream, NET_PROGRAMMECOLLECTION_CHANGE
 	   WriteMyIP()
       WriteByte stream, playerID
       WriteInt stream, programme.pid
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
       WriteByte stream, NET_SENDNEWS
 	   WriteMyIP()
       WriteByte Stream, playerID
       WriteInt  stream, news.id
       SendReliableUDP(i, 250, -1, "SendNews")
     EndIf
   Next
  End Method

  'add = 1 - added, add = 0 - removed
  Method SendPlanNewsChange(playerID:Int, newsBlock:TNewsBlock, add:Byte=1)
   For Local i:Int = 0 To 3
     If IsNoComputerNorMe(IP[i],Port[i])
       WriteInt stream, SendID
       WriteByte stream, NET_PLAN_NEWSCHANGE
 	   WriteMyIP()
       WriteByte stream, playerID
       WriteByte Stream, add
       WriteInt stream,  newsBlock.Pos.x
       WriteInt stream,  newsBlock.Pos.y
       WriteInt stream,  newsBlock.startPos.x
       WriteInt stream,  newsBlock.startPos.y
       WriteInt stream,  newsBlock.uniqueID
       WriteInt stream,  newsBlock.paid
       WriteInt stream,  newsBlock.news.id
       WriteInt stream, newsBlock.sendslot
	   WriteInt stream, newsblock.news.sendposition
       SendReliableUDP(i, 250, -1, "SendPlanNewsChange")
     EndIf
   Next
  End Method

  Method GotPacket_Plan_NewsChange(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local add:Byte = ReadByte(Stream)
    Local x:Int = ReadInt(Stream)
    Local y:Int = ReadInt(Stream)
    Local startrectx:Int = ReadInt(Stream)
    Local startrecty:Int = ReadInt(Stream)
    Local newsblockID:Int = ReadInt(stream)
    Local paid:Int = ReadInt(stream)
    Local newsID:Int = ReadInt(stream)
    Local sendslot:Int = ReadInt(stream)
    Local newssendposition:Int = ReadInt(stream)

	Local newsblock:TNewsblock = TNewSBlock.getBlock(newsblockID)
    If newsblock <> Null Then
      newsblock.news.sendposition = newssendposition
      newsblock.sendslot = sendslot
	  newsblock.owner = RemotePlayerID
      newsblock.Pos.SetXY(x, y)
	  newsblock.StartPos.SetXY(startrectx, startrecty)
'      Player[ remotePlayerID ].ProgrammePlan.RefreshNewsPlan()
      If add=1 Then
	    Print "news add newsblock:"+newsblock.news.title+" to player "+remotePlayerID+"/"+newsblock.owner+" on sendslot"+sendslot
		Player[ remotePlayerID ].ProgrammePlan.AddNews(newsblock.news, sendslot)
		If Not newsblock.paid Then newsblock.Pay();
      EndIf
      If add=0 Then
	    Print "remove newsblock:"+newsblock.news.title+" from player "+remotePlayerID+"/"+newsblock.owner+" on sendslot"+sendslot
		Player[ remotePlayerID ].ProgrammePlan.RemoveNews( newsblock.news )
      EndIf
	  If add=2 Then
	    Print "deleted newsblock:"+newsblock.news.title+" from player "+remotePlayerID+"/"+newsblock.owner+" on sendslot"+sendslot
		Player[ remotePlayerID ].ProgrammePlan.RemoveNews( newsblock.news )
		If newsblock.owner = remotePlayerID Then ListRemove TNewsBlock.List,(NewsBlock)
      EndIf
	EndIf
 End Method

  Method GotPacket_NewsSubscriptionLevel(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(stream)
    Local genre:Int = ReadByte(stream)
    Local level:Int = ReadByte(stream)
    Player[ RemotePlayerID ].newsabonnements[genre] = level
	Print "set genre "+genre+" to level "+level+" for player "+RemotePlayerID
  End Method


  Method GotPacket_SendNews(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(stream)
    Local newsID:Int = ReadInt(stream)
	Local news:TNews = TNews.GetNews(newsID)
    If news <> Null
	  Player[ RemotePlayerID ].ProgrammeCollection.AddNews(news)
      TNewsBlock.Create("",0,-100, RemotePlayerID , 60*(3-Player[ RemotePlayerID ].newsabonnements[news.genre]), news)
      Print "net: added news (id:"+newsID+") to Player:"+RemotePlayerID
	Else
      Print "net: news to add NOT FOUND (id:"+newsID+") for Player:"+RemotePlayerID
	EndIf
  End Method

  Method GotPacket_ProgrammeCollectionChange(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local programmeID:Int = ReadInt(stream)
    Local isMovie:Byte = ReadByte(stream)
    Local typ:Byte = ReadByte(stream)
    Local programme:TProgramme = Null
    If     isMovie Then programme = TMovie.GetMovie(programmeID)
    If Not isMovie Then programme = TSeries.GetSeries(programmeID)
	If programme <> Null
        If typ = 2
 		  If isMovie
            Player[ RemotePlayerID ].ProgrammeCollection.AddMovie(Programme,RemoteplayerID)
	      Else
            Player[ RemotePlayerID ].ProgrammeCollection.AddSerie(Programme,RemoteplayerID)
	      EndIf
          TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, RemoteplayerID)
		EndIf
		If typ = 0
 	      Player[ RemotePlayerID ].finances[TFinancials.GetDayArray(Game.day)].SellMovie(Programme.ComputePrice())
          TMovieAgencyBlocks.RemoveBlockByProgramme(Programme, RemoteplayerID)
		EndIf
	    'remove from Plan (Archive - ProgrammeToSuitcase)
	    If typ = 1 Then Print "remove all instances";Player[ RemotePlayerID ].ProgrammePlan.RemoveAllProgrammeInstances(programme )
        'remove from Collection (Archive - RemoveProgramme)
		If typ = 3 Then Print "remove from collection";Player[ RemotePlayerID ].ProgrammeCollection.RemoveProgramme( programme )
    EndIf
 End Method

  Method GotPacket_ElevatorRouteChange(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local call:Int = ReadInt(Stream)
    Local floornumber:Int = ReadInt(Stream)
    Local who:Int = ReadInt(Stream)
    Local First:Int = ReadByte(Stream)
    Print "net: got floorroute:"+floornumber
    Building.Elevator.AddFloorRoute(floornumber, call, who, First, True)
    If First Then
  	  Player[ RemotePlayerID].Figure.clickedToFloor = -1
      Player[ RemotePlayerID].Figure.calledElevator = False
      Building.Elevator.passenger = RemotePlayerID
    End If
  End Method

  Method GotPacket_ElevatorSynchronize(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(Stream)
	Local Sendtime:Float = ReadFloat(stream)
    Building.Elevator.upwards = ReadInt(stream)
    Building.Elevator.Pos.x = ReadFloat(stream)
    Local myY:Float = ReadFloat(stream)
    Building.Elevator.onFloor = ReadInt(stream)
    Building.Elevator.toFloor = ReadInt(stream)
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
	If Building.Elevator.passenger >= 0 Then Building.Elevator.Pos.y = myY
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

  Method GotPacket_StationChange(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local add:Byte = ReadByte(Stream)
    Local x:Int = ReadInt(Stream)
    Local y:Int = ReadInt(Stream)
    Local reach:Int = ReadInt(Stream)
    Local price:Int = ReadInt(Stream)
    Local newaudience:Int = ReadInt(Stream)
    If add
      Local station:TStation = TStation.Create(x,y,reach,price,remoteplayerID)
      Player[remoteplayerID].finances[TFinancials.GetDayArray(Game.day)].PayStation(price)
      'Player[remoteplayerID].maxaudience = newaudience
      Player[remoteplayerID].maxaudience = StationMap.CalculateAudienceSum(remoteplayerID)
      StationMap.StationList.AddLast(station)
      Print "NET: ADDED station to Player:"+RemotePlayerID
    EndIf
 End Method

  Method GotPacket_Plan_AdChange(_IP:Int, _Port:Short)
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
        adblock.Title = contract.Title
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

  Method GotPacket_Plan_ProgrammeChange(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(Stream)
    Local add:Byte = ReadByte(Stream)
    Local x:Int = ReadInt(Stream)
    Local y:Int = ReadInt(Stream)
    Local startrectx:Int = ReadInt(Stream)
    Local startrecty:Int = ReadInt(Stream)
    Local sendtime:Int = ReadInt(Stream)
    Local senddate:Int = ReadInt(Stream)
    Local programmeblockID:Int = ReadInt(Stream)
    Local ParentProgrammeID:Int = ReadInt(Stream)
    Local ProgrammeID:Int = ReadInt(Stream)
    Local programmeblock:TProgrammeBlock = TProgrammeBlock.GetBlock(programmeBlockID)
    If programmeblock = Null Then
      Local ParentProgramme:TProgramme = Null
      Local Programme:TProgramme = Null
	  Print "Try to fetch ID:"+programmeID+" (parentprogrammeID:"+ParentProgrammeID+")"
      If ParentProgrammeID >= 0  Then ParentProgramme = TProgramme.GetSeries(ParentProgrammeID) 'Player[ RemotePlayerID ].ProgrammeCollection.getSeries(ParentProgrammeID)
      Programme = TProgramme.GetProgramme(programmeID)
      If Programme = Null Then Print "programme not found"
	  Print "got new programme:"+programme.title
	  programmeBlock = TProgrammeBlock.CreateDragged(programme, parentprogramme, RemotePlayerID)
      'Print "NET: ADDED NEW programme"
      ProgrammeBlock.dragged = 0
    EndIf
    programmeBlock.programme.senddate = senddate
    programmeBlock.programme.sendtime = sendtime
	ProgrammeBlock.Pos.SetXY(x, y)
	ProgrammeBlock.StartPos.SetXY(startrectx, startrecty)
    Player[remotePlayerID].ProgrammePlan.RefreshProgrammePlan(senddate)
    If add
      'Player[ RemotePlayerID ].ProgrammePlan.AddProgramme(Programmeblock.programme)
      'Print "NET: ADDED programme:"+Programmeblock.programme.Title+" to Player:"+RemotePlayerID
      'Print "---  id:"+programmeblock.uniqueid+"("+programmeblockid+") Sendtime:"+Programmeblock.programme.sendtime+" to Player:"+RemotePlayerID
    Else
'      Player[ RemotePlayerID ].ProgrammePlan.RemoveProgramme(Programmeblock.programme)
      'Print "NET: REMOVED programme:"+Programmeblock.programme.Title+" from Player:"+RemotePlayerID
    EndIf
 End Method

  Method GotPacket_GameReady(_IP:Int, _Port:Short)
   Local RemotePlayerID:Int = ReadByte(Stream)
 '  Game.networkgameready = 1
   Game.gamestate = 4
   For Local i:Int = 0 To 3
     If IP[i]= Null And Game.playerID = 1
      Player[ i + 1 ].networkstate = 1
     EndIf
   Next
   Print RemotePlayerID
   Player[ RemotePlayerID ].networkstate = 1 'ready

   Print "NET: got GameReadyFlag from Player:"+Player[ RemotePlayerID ].name + " ("+RemotePlayerID+")"

   'if server then wait until all players are ready... then send startcommand
   If Game.playerID = 1 Then
     If Player[ 1 ].networkstate = 1 And Player[ 2 ].networkstate = 1 And Player[ 3 ].networkstate = 1 And Player[ 4 ].networkstate = 1
       SendGameStart()
       Print "NET: send startcommand"
     EndIf
   Else
     If Player[1].ProgrammeCollection.movielist.count() >= Game.start_MovieAmount And..
        Player[2].ProgrammeCollection.movielist.count() >= Game.start_MovieAmount And..
        Player[3].ProgrammeCollection.movielist.count() >= Game.start_MovieAmount And..
        Player[4].ProgrammeCollection.movielist.count() >= Game.start_MovieAmount And..
        Player[1].ProgrammeCollection.contractlist.count() >= Game.start_AdAmount And..
        Player[2].ProgrammeCollection.contractlist.count() >= Game.start_AdAmount And..
        Player[3].ProgrammeCollection.contractlist.count() >= Game.start_AdAmount And..
        Player[4].ProgrammeCollection.contractlist.count() >= Game.start_AdAmount Then
        Player[ Game.playerID ].networkstate = 1
        SendGameReady(Game.playerID, 0)
     EndIf
   EndIf
  End Method


  Method GotPacket_SendContract(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(Stream)
	Local ContractCount:Int = ReadInt(stream)
    Local contractID:Int
    For Local i:Int = 0 To ContractCount-1
      contractID:Int = ReadInt(stream)
      Player[ RemotePlayerID ].ProgrammeCollection.AddContract(TContract.getContract(contractID))
	Next
    Print "net: added contract (id:"+contractID+") to Player:"+RemotePlayerID
  End Method

  Method GotPacket_SendProgramme(_IP:Int, _Port:Short)
    Local RemotePlayerID:Int = ReadByte(stream)
	Local ProgrammeCount:Int = ReadInt(stream)
    Local IsMovie:Byte
    Local ProgrammeID:Int
    For Local i:Int = 0 To ProgrammeCount-1
	  IsMovie:Byte = ReadByte(stream)
      ProgrammeID:Int = ReadInt(stream)
      If isMovie Then Player[ RemotePlayerID ].ProgrammeCollection.AddMovie(TProgramme.GetMovie(ProgrammeID))
      If Not isMovie Then Player[ RemotePlayerID ].ProgrammeCollection.AddSerie(TProgramme.GetSeries(ProgrammeID))
    Next
	Print "got "+ProgrammeCount+" programmes for player:"+RemotePlayerID
	'Print "NET: added programme with ID:"+ProgrammeID+" to Player "+RemotePlayerID
    'Print "--->Programme:"+TProgramme.GetMovie(ProgrammeID).Title
  End Method

  Method GotPacket_PlayerPosition(_IP:Int, _Port:Short)
     Local RemotePlayerID:Int = ReadByte(Stream)
     If Player[ RemotePlayerID] = Null Then Print "Player "+RemotePlayerID+" not found"
     Local x:Float = ReadFloat(stream)
     Local y:Float = ReadFloat(stream)

	 Player[ RemotePlayerID ].Figure.dx              = ReadInt(stream)
     Player[ RemotePlayerID ].Figure.AnimPos         = ReadInt(Stream)
     Player[ RemotePlayerID ].Figure.targetx         = ReadInt(stream)
     Player[ RemotePlayerID ].Figure.oldtargetx      = ReadInt(Stream)
     Player[ RemotePlayerID ].Figure.toFloor         = ReadInt(Stream)
     Player[ RemotePlayerID ].Figure.onFloor         = ReadInt(Stream)
     Player[ RemotePlayerID ].Figure.calledElevator  = ReadInt(Stream)
     Player[ RemotePlayerID ].Figure.clickedToFloor  = ReadInt(Stream)
     Player[ RemotePlayerID ].Figure.inElevator      = ReadInt(stream)

     'only synchronize position when not in Elevator
	 If Building.Elevator.passenger <> RemotePlayerID 'Not Player[ RemotePlayerID ].Figure.inElevator
	   Player[ RemotePlayerID ].Figure.pos.x               = x
	   Player[ RemotePlayerID ].Figure.pos.y               = y
	 End If

     If Player[ RemotePlayerID ].Figure.inElevator
	   Building.Elevator.passenger = Player[ RemotePlayerID ].Figure.id
	   Player[ RemotePlayerID ].Figure.pos.x =  Int(Building.x + Building.Elevator.Pos.x + Player[ RemotePlayerID ].Figure.xToElevator - Int(Player[ RemotePlayerID ].Figure.FrameWidth/2) - 3)
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

  Method GotPacket_PlayerDetails(_IP:Int, _Port:Short)
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
        Player[ RemotePlayerID].color.colB <> colB Then
       Player[ RemotePlayerID].color.colR = colR
       Player[ RemotePlayerID].color.colG = colG
       Player[ RemotePlayerID].color.colB = colB
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

  Method GotPacket_PlayerIPs(_IP:Int, _Port:Short)
    For Local i:Int = 0 To 3
      IP[ i ]   = ReadInt(Stream)
      Port[ i ] = ReadShort(Stream)
      If IP[ i ] <> Null Then Player[i+1].Figure.ControlledByID= i+1
      If IP[ i ] = Null Then Player[i+1].Figure.ControlledByID= 0
    Next
    'if debugmode Print "NET: got synchronize PlayerIP-packet"
  End Method

  Method GotPacket_Join(_IP:Int, _Port:Short)
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
      WriteByte Stream, NET_SETSLOT
      WriteMyIP()
      WriteInt Stream, _IP
      WriteShort Stream, _Port
      WriteByte Stream, GetFreeSlot()
	  SendReliableUDPtoIP(_IP, _Port,  150, -1, "SetSlot (Got Join)")
    EndIf
  End Method

  Method GotPacket_AnnounceGame(_IP:Int, _Port:Short)
    If _ip <> intMyIP Then
	  Local teamamount:Int = ReadByte(Stream)
	  Local titlelength:Byte = ReadByte(stream)
	  Local title:String = ReadString(stream, titlelength)
      NetgameLobby_gamelist.addUniqueEntry(title, title+"  (Spieler: "+teamamount+" von 4)","",TNetwork.DottedIP(_ip),_Port,0, "HOSTGAME")
    EndIf
  End Method

  Method GotPacket_ChatMessage(_IP:Int, _Port:Short)
    If _IP <> intMyIP Then
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

  Method GotPacket_SetSlot(_IP:Int, _Port:Short)
             Local aimedIP:Int = ReadInt(Stream)
             Local aimedPort:Int = ReadShort(Stream)
   			 Local slot:Byte   = ReadByte(Stream)
             ip[slot-1] = aimedIP
             Port[slot-1] = aimedPort
			 Player[slot].name = game.username
			 MenuPlayerNames[slot-1].value = game.username
			 MenuChannelNames[slot-1] .value = game.userchannelname
			 Local OldRecvID:Int = RecvID
             If     Game.onlinegame Then intOnlineIP = aimedIP  'on server the ip was another one - may be from the dialup-networkcard
             If Not Game.onlinegame Then intMyIP = aimedIP  'on server the ip was another one - may be from the dialup-networkcard
             MyIP = TNetwork.DottedIP(aimedIP)
             Game.gamestate=3
		     NetAck (RecvID, _IP, _Port)                 ' Send ACK
             MyID = slot
             Game.playerID = slot
             IsConnected = True
           '   Stream.Flush 'alten Mist raushauen, neuen rein
	         'sends to server, which ip is now on slot X
	          WriteInt Stream, SendID
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
	    WriteByte Stream, NET_STATE
  	    WriteMyIP()
	    WriteFloat Stream, Game.minutesOfDayGone
	    WriteFloat Stream, Game.speed
	  SendUDP(i)
	 EndIf
   Next
  End Method

  Method UpdateUDP(fromNotConnectedPlayer:Int = 0)
    If IsConnected Or fromNotConnectedPlayer Then ' Updates


      'Aller 1500ms einen Status rueberschicken (unbestaetigt)
      If isHost And MilliSecs() >= MainSyncTime+ 1500*Speedfactor
		SendPlayerIPs()
	'	If Abs(MilliSecs() - LastElevatorSynchronize)>500 Then SendElevatorSynchronize()
		SendState()
        MainSyncTime = MilliSecs()
	  EndIf

      'Aller 4000ms einen Status rueberschicken (unbestaetigt)
      If MilliSecs() >= UpdateTime + 4000*Speedfactor
	    SendState()
		SendPlayerDetails()
        UpdateTime = MilliSecs()
	  EndIf

      'Ping aller 1 Sekunde absetzen (unbestaetigt)
	  If MilliSecs() >= PingTimer + 1000*Speedfactor
		SendPlayerPosition()
        For Local i:Int = 0 To 3
          If IP[i]<> Null And IP[i] <> IP[Game.playerID-1]
	        WriteInt stream, SendID
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

    If GameSettingsOkButton_Announce.iscrossed() And..
	   isHost And MilliSecs() >=  AnnounceTime + Game.onlinegame*4000*Speedfactor + 1000
		AnnounceTime = MilliSecs()
        SendGameAnnouncement()
	EndIf

    Local bMsgIsNew:Int
    While stream.RecvAvail() ' Then
	  stream.RecvMsg()
  	  RecvID = ReadInt(Stream)
	  Local data:Int   = ReadByte(Stream)
	  Local _IP:Int     = ReadInt(stream)
 	  Local _Port:Int   = ReadShort(stream)
	  If Not Game.onlinegame
	    _IP:Int     = stream.GetMsgIP()
 	    _Port:Int   = stream.GetMsgPort()
	  End If

	    Select data
	      Case NET_JOIN                 ' JOIN PACKET
            GotPacket_Join(_IP,_Port)
       	  Case NET_ANNOUNCEGAME         ' A game was announced
			GotPacket_AnnounceGame(_IP, _Port)
       	  Case NET_SETSLOT         ' Answer of join-request, only sent to join-sender
            GotPacket_SetSlot(_IP,_Port)
            IsConnected = True 'we have connected and server send setslot
            NetAck (RecvID, _IP, _Port)
            Print "sending ack for setting slot"
       	  Case NET_PLAYERIPS         ' synchronizing PlayerIPs and Ports
            GotPacket_PlayerIPs(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_PLAYERDETAILS         ' name, channelname and so on
			GotPacket_PlayerDetails(_IP, _Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_PLAYERPOSITION         ' x,y, room, target...
			GotPacket_PlayerPosition(_IP, _Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_CHATMESSAGE         ' someone has written something into the chat
            GotPacket_ChatMessage(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_MOVIEAGENCY_CHANGE			' got change of programmes in MovieAgency from Server
            GotPacket_SendMovieAgencyChange(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_SENDPROGRAMME       ' got StartupProgramme from Server
            GotPacket_SendProgramme(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_SENDCONTRACT       ' got StartupContract from Server
            GotPacket_SendContract(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_SENDNEWS       ' got News from Server
            GotPacket_SendNEWS(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
		  Case NET_NEWSSUBSCRIPTIONLEVEL
		    GotPacket_NewsSubscriptionLevel(_IP, _Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_GAMEREADY       ' got readyflag
            GotPacket_GameReady(_IP,_Port)
            If Player[ Game.playerID ].networkstate = 1 Then NetAck (RecvID, _IP, _Port)
       	  Case NET_STARTGAME       ' got startcommand
            Game.networkgameready = 1
            NetAck (RecvID, _IP, _Port)
       	  Case NET_PLAN_PROGRAMMECHANGE  ' got flag to change Programme of Player
            GotPacket_Plan_ProgrammeChange(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_PLAN_NEWSCHANGE  ' got flag to change Programme of Player
            GotPacket_Plan_NewsChange(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
		  Case NET_PROGRAMMECOLLECTION_CHANGE  'got change of programme (remove, readd, remove from plan ...)
		    GotPacket_ProgrammeCollectionChange(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_PLAN_ADCHANGE  ' got flag to change Programme of Player
            GotPacket_Plan_AdChange(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_STATIONCHANGE  ' got flag to change Programme of Player
            GotPacket_StationChange(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_ELEVATORSYNCHRONIZE  ' got flag to change Programme of Player
            GotPacket_ElevatorSynchronize(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
       	  Case NET_ELEVATORROUTECHANGE   ' got flag to change Programme of Player
            GotPacket_ElevatorRouteChange(_IP,_Port)
            NetAck (RecvID, _IP, _Port)
		  Case NET_SLOTSET
 		    Local slot:Byte   = ReadByte(Stream)-1
 		    Local OldRecvID:Int = ReadInt(stream)
 		    Local channellen:Int = ReadInt(stream)
 		    Local namelen:Int = ReadInt(stream)
 		    Local channel:String = ReadString(stream, channellen)
 		    Local name:String = ReadString(stream, namelen)
 		    ip[slot] = _IP
 		    Port[slot] = _Port
			TReliableUDP.GotAckPacket(OldRecvID, _IP, _Port)
			GameSettings_Chat.AddEntry("", name+" hat sich in das Spiel eingeklinkt (Sender: "+channel+")", 0,"", "", MilliSecs())
		    'If debugmode Print "NET: IP "+_IP+" set to slot "+slot
		    If Game.playerID = 1 Then SendPlayerIPs()
 	      Case NET_PING                 ' Received Ping, Send Pong
		    Local RemotePlayerID:Int = ReadInt(stream)
		    WriteInt stream, SendID
		    WriteByte stream, NET_PONG
			WriteMyIP()
		    WriteInt stream, MyID
 	        SendUDP(RemotePlayerID-1)
		  Case NET_PONG                 ' Ping / Pong - Calculate Ping
		    Local RemotePlayerID:Int = ReadInt(stream)
			If IP[ RemotePlayerID-1 ] = _IP
		      myPing[ RemotePlayerID ] = (MilliSecs() - PingTime[ RemotePlayerID ]) / 2
		    EndIf
			'Game.time:+ Int(myPing / 1000)
		  Case NET_ACK                  ' ACK PACKET
		    Local AckForSendID:Int = ReadInt(Stream)
		    TReliableUDP.GotAckPacket(AckForSendID, _IP, _Port)
		    RemoveNetObj AckForSendID   ' Remove Reliable Packet (ACK has been received)
		  Case NET_STATE                ' State Update
 	        Game.minutesOfDayGone = ReadFloat(Stream)
 	        Game.speed = ReadFloat(Stream)
		  Case NET_UPDATE               ' Full update, align
	        Local remotePlayerID:Int = ReadInt(Stream)
		    Player[remotePlayerID].Figure.pos.x = ReadFloat(stream)          ' X
		    Player[remotePlayerID].Figure.pos.y = ReadFloat(stream)          ' Y
		    'DebugLog "NET: got update for Player "+remotePlayerID
		  Case NET_QUIT                 ' Player Quits
	        Local remotePlayerID:Byte = ReadByte(Stream)
		    IP[remoteplayerid - 1] =0
		    Port[remoteplayerid - 1] =0
		    Player[remoteplayerid].Figure.ControlledByID=-1
			TReliableUDP.DeletePacketsForIP(_IP,_Port)
		    Print "Player "+remoteplayerid+" left the game..."
		    'IsConnected = 2                     ' Quit
		    NetAck (RecvID, _IP, _Port)                 ' Send ACK
 	    End Select
    Wend 'Endif
	  stream.Flush()

      TReliableUDP.ReSend() 'send again all not ACKed packets
  End Method

  Method ClearLastRecv()
    For Local i:Int = 0 To 31
	  lastRecv[i] = -1  ' Doppelte Arrayeintraege loeschen
	Next
  End Method


  ' // IsMsgNew gibt zurueck, ob das UDP-Paket ein Duplikat oder ein Altes ist
  Method IsMsgNew:Byte(id:Int, data:Int = 0, _IP:Int, _Port:Short)
    For Local i:Int = 50 To 0 Step -1
        lastRecv[i + 1] = lastRecv[ i ]
    Next
    lastRecv[0] = id

    For Local i:Int = 1 To 51
      If lastRecv[ i ] = lastRecv[0] Then ' Duplicate
		Select data ' ACK Anyway (Reliable packets only)
	      Case NET_QUIT, NET_SENDCONTRACT
	      NetAck (RecvID, _IP, _Port)
	      If debugmode = True Then Print "*** Received duplicate packet ("+data+"), resending ACK ***"
   	    End Select
   	    If data = NET_JOIN Then Return True
   	    If data = NET_GAMEREADY Then Print "*** got gameready";Return True
        Return False
      EndIf
    Next
    Return True
  End Method

  ' // RemoveNetObj removes reliable UDP packets from the queue once an ACK has been received
  Method RemoveNetObj(AckID:Int)
    For n:NetObj = EachIn netList
      If n.SID = AckID Then
	    Local tmpID:Int = n.id
	    netList.Remove n
	    For n:NetObj = EachIn netList                                ' Remove old entries
	      If n.id = tmpID And n.SID <= AckID Then
            netList.Remove n
          EndIf
	    Next
        Exit
      EndIf
    Next
  End Method

  ' // NetAck sends ACKnowledge packet to client
  Method NetAck(RecvID:Int, _IP:Int, _Port:Short)
    WriteInt Stream, SendID
    WriteByte stream, NET_ACK
	WriteMyIP()
    WriteInt Stream, RecvID
'    SendUDP
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
  Method SendReliableUDP(i:Int=0, retrytime:Int = 200, MaxRetry:Int = -1, desc:String="")
    BackupStream(MyBank)
    TReliableUDP.Create(SendID, IP[i], Port[i], MyBank, retrytime, MaxRetry, desc)
    stream.SendUDPMsg IP[i], Port[i]
    BackupStream(MyBank)
	SendID:+1	         ' Increment send counter
  End Method

  Method SendReliableUDPtoIP(_IP:Int, _Port:Short,retrytime:Int = 200, MaxRetry:Int = -1, desc:String="")
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
 	    Local _Port:Int   = ReadShort(stream)
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
  Field targetPort:Short
  Field retrytime:Int = 200
  Global LastID:Int =0
  Global List:TList = CreateList()

  Function Create:TReliableUDP(SendID:Int, IP:Int, Port:Short, content:TBank, retrytime:Int=200, MaxRetry:Int = -1, desc:String="")
    Local ReliableUDP:TReliableUDP = New TReliableUDP

    ReliableUDP.SendID    = SendID
    ReliableUDP.targetIP  = IP
    ReliableUDP.targetPort= Port
    ReliableUDP.content   = content
    ReliableUDP.retrytime = retrytime*Network.Speedfactor
    ReliableUDP.MaxRetry = MaxRetry
    ReliableUDP.desc = desc

    ReliableUDP.id = TReliableUDP.LastID
    TReliableUDP.LastID:+1

    TReliableUDP.List.AddLast(ReliableUDP)
    Return ReliableUDP
  End Function

  'we got an ACK-packet, now find the corresponding and delete it...
  '-> we made our reliable udp-packet being received ;D
  Function GotAckPacket:Int(SendID:Int, fromIP:Int, fromPort:Short)
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

  Function DeletePacketsForIP(_IP:Int, _Port:Short)
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