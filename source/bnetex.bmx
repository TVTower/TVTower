SuperStrict

Import pub.StdC
Import BRL.Socket
Import BRL.Stream
Import BRL.Math

'Import Brl.Stream
'Import Pub.StdC
?Linux
	Import "linux.c"
?

Private

?Win32
	Global selectex_:Int(ReadCount:Int,  ReadSockets:Int Ptr, ..
	                     WriteCount:Int, WriteSockets:Int Ptr, ..
	                     ExceptCount:Int, ExceptSockets:Int Ptr, ..
	                     Milliseconds:Int) = select_
?MacOs
	Global selectex_:Int(ReadCount:Int,  ReadSockets:Int Ptr, ..
	                     WriteCount:Int, WriteSockets:Int Ptr, ..
	                     ExceptCount:Int, ExceptSockets:Int Ptr, ..
	                     Milliseconds:Int) = select_
?Linux
	Extern "C"
		Function selectex_:Int(ReadCount:Int,  ReadSockets:Int Ptr, ..
		                       WriteCount:Int, WriteSockets:Int Ptr, ..
		                       ExceptCount:Int, ExceptSockets:Int Ptr, ..
		                       Milliseconds:Int) = "pselect_"
	End Extern
?

Type TSockAddr
	Field SinFamily : Short
	Field SinPort   : Short
	Field SinAddr   : Int
	Field SinZero   : Long
End Type

Extern "OS"
	Const INVALID_SOCKET_ : Int = -1

	?Win32
		Const FIONREAD    : Int   = $4004667F
		Const SOL_SOCKET_ : Int   = $FFFF
		Const SO_SNDBUF_  : Short = $1001
		Const SO_RCVBUF_  : Short = $1002

		Function ioctl_:Int(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctlsocket@12"
		Function inet_addr_:Int(Address$z) = "inet_addr@4"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa@4"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname@12"

	?MacOS
		Const FIONREAD    : Int   = $4004667F
		Const SOL_SOCKET_ : Int   = 1 ' Not sure!
		Const SO_SNDBUF_  : Short = 7 ' Not sure!
		Const SO_RCVBUF_  : Short = 8 ' Not sure!

		Function ioctl_(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctl"
		Function inet_addr_:Int(Address$z) = "inet_addr"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname"

	?Linux
		Const FIONREAD    : Int   = $0000541B
		Const SOL_SOCKET_ : Int   = 1
		Const SO_SNDBUF_  : Short = 7
		Const SO_RCVBUF_  : Short = 8

		Function ioctl_(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctl"
		Function inet_addr_:Int(Address$z) = "inet_addr"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname"
	?
End Extern

Public

Rem
	bbdoc: Network Type
	about: Einige Hilfsfunktionen im Umgang mit UDP/TCP
End Rem
Type TNetwork
	Rem
		bbdoc:   Gibt die IP-Adresse des angegebenen Hosts zur&uuml;ck
		returns: 0, wenn ein Fehler auftrat, ansonsten IP-Adresse des angegebenen Hosts
		about:   Ermittelt die erste IP-Adresse des angegebenen Hosts.<br />
			         Siehe auch: #GetHostIPs , #GetHostName, #StringIP
	End Rem
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

	Rem
		bbdoc:   Gibt die IP-Adressen des angegebenen Hosts zur&uuml;ck
		returns: Null, wenn ein Fehler auftrat, ansonsten IP-Adressen des angegebenen Hosts
		about:   Ein Host, z. B. "www.google.com" kann mehrere IP-Adressen gleichzeitig<br />
		         besitzen. Diese lassen sich mit dieser Funktion ermitteln.<br />
		         Siehe auch: #GetHostIP , #GetHostName, #StringIP
	End Rem
	Function GetHostIPs:Int[](HostName:String)
		Local Addresses:Byte Ptr Ptr, AddressType:Int, AddressLength:Int
		Local Count:Int, IPs:Int[], Index:Int
		Local PAddress:Byte Ptr, Address:Int

		Addresses = gethostbyname_(HostName, AddressType, AddressLength)
		If (Not Addresses) Or AddressType <> AF_INET_ Or AddressLength <> 4 Then Return Null

		Count = 0
		While Addresses[Count]
			Count :+ 1
		Wend

		IPs = New Int[Count]
		For Index = 0 Until Count
			PAddress = Addresses[Index]
			Address = (PAddress[0] Shl 24) | (PAddress[1] Shl 16) | ..
			          (PAddress[2] Shl 8) | PAddress[3]
			IPs[Index] = Address
		Next

		Return IPs
	End Function

	Rem
		bbdoc:   Gibt den Namen des angegebenen Hosts zur&uuml;ck
		returns: "", wenn ein Fehler auftrat, ansonsten den Namen des angegebenen Hosts
		about:   Siehe auch: #GetHostIP, #GetHostIPs
	End Rem
	Function GetHostName:String(HostIp:Int)
		Local Address:Int, Name:Byte Ptr

		Address = htonl_(HostIp)
		Name    = gethostbyaddr_(Varptr(Address), 4, AF_INET_)

		If Name Then
			Return String.FromCString(Name)
		Else
			Return ""
		EndIf
	End Function

	Rem
		bbdoc:   Wandelt Integer- in StringIP um
		returns: Umgewandelte StringIP
		about:   Es wird ein String in Form von "X.Y.Z.W" zur&uuml;ckgegeben.<br />
		         z. B. TNetwork.StringIP(2130706433) -> "127.0.0.1"<br />
		         Siehe auch: #IntIP
	End Rem
	Function StringIP:String(IP:Int)
		Return String.FromCString(inet_ntoa_(htonl_(IP)))
	End Function
	Rem
		bbdoc:   Wandelt Integer- in StringIP um
		returns: Umgewandelte StringIP
		about:   Es wird ein String in Form von "X.Y.Z.W" zur&uuml;ckgegeben.<br />
		         z. B. TNetwork.dottedIP(2130706433) -> "127.0.0.1"<br />
		         Siehe auch: #IntIP
	End Rem
	Function DottedIP:String(IP:Int)
		Return String.FromCString(inet_ntoa_(htonl_(IP)))
	End Function

	Rem
		bbdoc:   Wandelt String- in IntegerIP um
		returns: Umgewandelte IntegerIP
		about:   Die angegebene StringIP muss der Form "X.Y.Z.W" entsprechen.<br />
		         z. B. TNetwork.IntIP("127.0.0.1") -> 2130706433<br>
		         Sieh auch: #StringIP
	End Rem
	Function IntIP:Int(IP:String)
		Return htonl_(inet_addr_(IP))
	End Function
End Type

Rem
	bbdoc: Net-Stream Type
End Rem
Type TNetStream Extends TStream Abstract
	Field Socket      : Int
	Field RecvBuffer  : Byte Ptr
	Field SendBuffer  : Byte Ptr
	Field RecvSize    : Int
	Field SendSize    : Int

	Method New()
		Self.Socket      = INVALID_SOCKET_
		Self.RecvBuffer  = Null
		Self.SendBuffer  = Null
		Self.RecvSize    = 0
		Self.SendSize    = 0
	End Method

	Method Delete()
		Self.Close()
		If Self.RecvSize > 0 Then MemFree(Self.RecvBuffer)
		If Self.SendSize > 0 Then MemFree(Self.SendBuffer)
	End Method

	Method Init:Int() Abstract

	Method RecvMsg:Int() Abstract

	Method Read:Int(Buffer:Byte Ptr, Size:Int)
		Local Temp:Byte Ptr

		If Size > Self.RecvSize Then Size = Self.RecvSize
		If Size > 0 Then
			MemCopy(Buffer, Self.RecvBuffer, Size)
			If Size < Self.RecvSize Then
				Temp = MemAlloc(Self.RecvSize-Size)
				MemCopy(Temp, Self.RecvBuffer+Size, Self.RecvSize-Size)
				MemFree(Self.RecvBuffer)
				Self.RecvBuffer = Temp
				Self.RecvSize   :- Size
			Else
				MemFree(Self.RecvBuffer)
				Self.RecvSize = 0
			EndIf
		EndIf

		Return Size
	End Method

	Method SendMsg:Int() Abstract

	Method Write:Int(Buffer:Byte Ptr, Size:Int)
		Local Temp:Byte Ptr

		If Size <= 0 Then Return 0

		Temp = MemAlloc(Self.SendSize+Size)
		If Self.SendSize > 0 Then
			MemCopy(Temp, Self.SendBuffer, Self.SendSize)
			MemCopy(Temp+Self.SendSize, Buffer, Size)
			MemFree(Self.SendBuffer)
			Self.SendBuffer = Temp
			Self.SendSize  :+ Size
		Else
			MemCopy(Temp, Buffer, Size)
			Self.SendBuffer = Temp
			Self.SendSize   = Size
		EndIf

		Return Size
	End Method

	Rem
		bbdoc:   Stellt fest, ob Bytes ausgelesen werden k&ouml;nnen
		returns: False, wenn noch Bytes ausgelesen werden k&ouml;nnen, True wenn nicht
		about:   Diese Methode funktioniert auf Basis der #Size Methode und pr&uuml;ft somit<br />
		         die Gr&ouml;e des Empfangspuffers.<br />
		         Siehe auch: #Size
	End Rem
	Method Eof:Int()
		Return Self.RecvSize = 0
	End Method

	Rem
		bbdoc:   Gibt die Anzahl an empfangenen Bytes zur&uuml;ck
		returns: Anzahl an empfangenen Bytes
		about:   Nach jedem #RecvMsg wird eine Nachricht in den Empfangspuffer angehngt.<br />
		         Diese Methode gibt zur&uuml;ck, wieviel Bytes noch mit den allgemeinen Stream-<br />
		         befehlen, wie z. B. #ReadLine , aus diesen ausgelesen werden k&ouml;nnen.<br>
		         Siehe auch: #RecvAvail
	End Rem
	Method Size:Int()
		Return Self.RecvSize
	End Method

	Rem
		bbdoc:   Lscht den internen Sende- und Empfangspuffer.
		returns: -
		about:   Die empfangenen und gesendeten Daten werden gel&ouml;scht und die internen<br />
			     Sende- und Empfangsgr&ouml;&szlig;en zu 0 gesetzt.<br />
		         Diese Methode verhindert nicht, dass Nachrichten per #RecvMsg empfangen<br />
		         werden k&ouml;nnen oder &uuml;ber die allgemeinen Streambefehle, wie z. B. <br />
		         #WriteLine , der Sendepuffer beschrieben werden kann.<br />
		         Siehe auch: #Close , #Size , #Eof
	End Rem
	Method Flush()
		If Self.RecvSize > 0 Then MemFree(Self.RecvBuffer)
		If Self.SendSize > 0 Then MemFree(Self.SendBuffer)
		Self.RecvSize = 0
		Self.SendSize = 0
	End Method

	Rem
		bbdoc:   Beendet einen Netzstream
		returns: -
		about:   Der mit dem Netzstream verbundene Socket wird geschlossen. &Uuml;ber ihn<br />
		         kann nichtmehr gesendet und/oder empfangen werden.
	End Rem
	Method Close()
		If Self.Socket <> INVALID_SOCKET_ Then
			' No receiving and sending
			shutdown_(Self.Socket, SD_BOTH)
			closesocket_(Self.Socket)

			Self.Socket = INVALID_SOCKET_
		EndIf
	End Method

	Rem
		bbdoc:   Gibt die Anzahl an empfangbaren Bytes zur&uuml;ck
		returns: -1, wenn ein Fehler auftrat, ansonsten Anzahl an empfangbaren Bytes
		about:   Diese Methode gibt dar&uuml;ber Auskunft, ob eine Nachricht empfangbar ist.<br />
		         Empfangen wird sie &uuml;ber #RecvMsg . Die Methode #Size hingegen, gibt die<br />
		         Anzahl an empfangenen Bytes zur&uuml;ck.<br />
		         Siehe auch: #RecvMsg , #Size
	End Rem
	Method RecvAvail:Int()
		Local Size:Int

		' Socket does not exist?
		If Self.Socket = INVALID_SOCKET_ Then Return -1

		' How many bytes are in the network buffer?
		If ioctl_(Self.Socket, FIONREAD, Varptr(Size)) = SOCKET_ERROR_ Then
			Return -1
		Else
			Return Size
		EndIf
	End Method
End Type

Rem
	bbdoc: UDP-Stream Type
	about: Type f&uuml;r verbindungslose Kommunikation
End Rem
Type TUDPStream Extends TNetStream
	Field LocalIP     : Int
	Field LocalPort   : Short
	Field RemotePort  : Short
	Field RemoteIP    : Int
	Field MessageIP   : Int
	Field MessagePort : Short

	Field RecvTimeout : Int
	Field SendTimeout : Int
	Field fSpeed       : Float = 0
	Field fDataGot     : Float = 0
	Field fDataSent    : Float = 0
	Field fDataSum     : Float = 0
	Field fLastSecond  : Float = 0

	Method New()
		Self.LocalPort   = 0
		Self.LocalIP     = 0
		Self.RemotePort  = 0
		Self.RemoteIP    = 0
		Self.MessageIP   = 0
		Self.MessagePort = 0

		Self.RecvTimeout = 0
		Self.SendTimeout = 0
	End Method

	Rem
		bbdoc:   Initialisiert den UDPStream
		returns: False, wenn ein Fehler auftrat, ansonsten True
		about:   Intern wird ein neuer Socket erstellt.
	End Rem
	Method Init:Int()
		Local Size : Int

		Self.Socket = socket_(AF_INET_, SOCK_DGRAM_, 0)
		If Self.Socket = INVALID_SOCKET_ Then Return False

		' 2^16 - 1 Byte - 8 Byte UDP Overhead
		Size = 1% Shl 16 - 9
		If setsockopt_(Self.Socket, SOL_SOCKET_, SO_RCVBUF_, Varptr(Size), 4) = SOCKET_ERROR_ Or ..
		   setsockopt_(Self.Socket, SOL_SOCKET_, SO_SNDBUF_, Varptr(Size), 4) = SOCKET_ERROR_ Then
			closesocket_(Self.Socket)
			Return False
		EndIf

		Return True
	End Method

	Rem
		bbdoc:   Setzt den lokalen Port
		returns: False, wenn ein Fehler auftrat, ansonsten True
		about:   Wenn bei Port 0 angegeben wurde, so sucht das Betriebssystem einen <br />
		         freihen Port. Diesen kann man mit #GetLocalPort ermittelt werden.<br />
		         Dies ist nur der lokale Port, und muss NICHT mit dem Port des Empfngers <br />
		         &uuml;bereinstimmen.<br />
		         Siehe auch: #GetLocalPort , #GetLocalIP
	End Rem
	Method SetLocalPort:Int(Port:Short=0)
		Local Address:TSockAddr, NameLen:Int

		' Socket does not exist?
		If Self.Socket = INVALID_SOCKET_ Then Return False

		' Bind to Port
		If bind_(Self.Socket, AF_INET_, Port) = SOCKET_ERROR_ Then
			Return False
		Else
			' Update Local IP and Port
			Address = New TSockAddr
			NameLen = 16
			If getsockname_(Self.Socket, Address, Varptr(NameLen)) = SOCKET_ERROR_ Then
				Return False
			Else
				Self.LocalIP   = ntohl_(Address.SinAddr)
				Self.LocalPort = ntohs_(Address.SinPort)
				Return True
			EndIf
		EndIf
	End Method

	Rem
		bbdoc:   Gibt den lokalen Port zur&uuml;ck
		returns: lokaler Port
		about:   Siehe auch: #SetLocalPort, #GetLocalIP
	End Rem
	Method GetLocalPort:Short()
		Return Self.LocalPort
	End Method

	Rem
		bbdoc:   Gibt die lokale IP-Adresse in Integerform zur&uuml;ck
		returns: IntegerIP
		about:   Damit lsst sich NICHT die globale IP ermitteln.<br />
		         Diese Methode ist erst nach #SetLocalPort einsatzbereit.<br />
		         Siehe auch: #SetLocalPort , #GetLocalPort
	End Rem
	Method GetLocalIP:Int()
		Return Self.LocalIP
	End Method

	Rem
		bbdoc:   Setzt den Empfngerport
		returns: -
		about:   An diesen Port wird die k&uuml;nftige Nachricht mit #SendMsg geschickt.<br />
		         Dieser Port muss NICHT mit dem lokalen Port &uuml;bereinstimmen.<br />
		         Benutze diese Methode in Zusammenhang mit #SetRemoteIP.<br />
		         Siehe auch: #GetRemotePort
	End Rem
	Method SetRemotePort(Port:Short)
		Self.RemotePort = Port
	End Method

	Rem
		bbdoc:   Gibt den Empfngerport zur&uuml;ck
		returns: Empfngerport
		about:   An diesen Port wird die k&uuml;nftige Nachricht mit #SendMsg geschickt.<br />
		         Dieser Port muss NICHT mit dem lokalen Port &uuml;bereinstimmen.<br />
		         Siehe auch: #SetRemotePort
	End Rem
	Method GetRemotePort:Short()
		Return Self.RemotePort
	End Method

	Rem
		bbdoc:   Setzt die EmpfngerIP
		returns: -
		about:   An diese IP-Adresse wird die k&uuml;nftige Nachricht mit #SendMsg geschickt.<br />
		         Benutze diese Methode in Zusammenhang mit SetRemotePort.<br />
		         Siehe auch: #GetRemoteIP , #GetSetRemotePort
	End Rem
	Method SetRemoteIP(IP:Int)
		Self.RemoteIP = IP
	End Method

	Rem
		bbdoc:   Gibt die EmpfngerIP zur&uuml;ck
		returns: EmpfngerIP
		about:   An diese IP-Adresse wird die k&uuml;nftige Nachricht mit #SendMsg geschickt.<br />
		         Dieser Port muss NICHT mit dem lokalen Port &uuml;bereinstimmen.<br />
		         Siehe auch: #SetRemotePort
	End Rem
	Method GetRemoteIP:Int()
		Return Self.RemoteIP
	End Method

	Rem
		bbdoc:   Gibt den Port der letzten empfangenen Nachricht zur&uuml;ck
		returns: Port der letzten empfangenen Nachricht
		about:   Wird nach #RecvMsg aktualisiert.<br />
		         Siehe auch: #GetMsgIP
	End Rem
	Method GetMsgPort:Short()
		Return Self.MessagePort
	End Method

	Rem
		bbdoc:   Gibt die IP-Adresse der letzten empfangenen Nachricht zur&uuml;ck
		returns: IP-Adresse der letzten empfangenen Nachricht
		about:   Wird nach #RecvMsg aktualisiert.<br />
		         Siehe auch: #GetMsgPort
	End Rem
	Method GetMsgIP:Int()
		Return Self.MessageIP
	End Method

	Rem
		bbdoc:   Setzt Abbruchszeiten f&uuml;r das Empfangen und Senden
		returns: -
		about:   Bestimmt, wie lange #RecvMsg und #SendMsg max. warten d&uuml;rfen.<br />
		         Angaben in Millisekunden<br />
		         Siehe auch: #GetRecvTimeout , #GetSendTimeout
	End Rem
	Method SetTimeouts(RecvMillisecs:Int, SendMillisecs:Int)
		Self.RecvTimeout = RecvMillisecs
		Self.SendTimeout = SendMillisecs
	End Method

	Rem
		bbdoc:   Gibt Abbruchszeit f&uuml;r das Empfangen zur&uuml;ck
		returns: Abbruchszeit in Millisekunden
		about:   Siehe auch: #SetTimeouts , #GetSendTimeout
	End Rem
	Method GetRecvTimeout:Int()
		Return Self.RecvTimeout
	End Method

	Rem
		bbdoc:   Gibt Abbruchszeit f&uuml;r das Senden zur&uuml;ck
		returns: Abbruchszeit in Millisekunden
		about:   Siehe auch: #SetTimeouts , #GetRecvTimeout
	End Rem
	Method GetSendTimeout:Int()
		Return Self.SendTimeout
	End Method

	Rem
		bbdoc:   Empfngt eine Nachricht
		returns: Anzahl der empfangenen Bytes.
		about:   Empfngt eine eingehende Nachricht. Ob eine Nachricht vorliegt,<br />
		         kann mit #RecvAvail gepr&uuml;ft werden. Die AbsenderIP sowie der Absenderport<br />
		         k&ouml;nnen mit #GetMsgIP und #GetMsgPort ermittelt werden.<br />
		         Die Nachricht wird in einem Puffer gelagert.<br />
		         Das Auslesen der Nachricht erfolgt &uuml;ber &uuml;bliche Streambefehle wie #ReadLine .<br />
		         Siehe auch: #SendMsg , #GetMsgIP , #GetMsgPort , #RecvAvail
	End Rem
	Method RecvMsg:Int()
		Local Read:Int, Result:Int, Size:Int, MessageIP:Int, MessagePort:Int
		Local Temp:Byte Ptr

		If Self.Socket = INVALID_SOCKET_ Then Return 0

		Read = Self.Socket
		If selectex_(1, Varptr(Read), 0, Null, 0, Null, Self.RecvTimeout) <> 1 ..
		   Then Return 0

		If ioctl_(Self.Socket, FIONREAD, Varptr(Size)) = SOCKET_ERROR_ ..
		   Then Return 0

		If Size <= 0 Then Return 0

		If Self.RecvSize > 0 Then
			Temp = MemAlloc(Self.RecvSize+Size)
			MemCopy(Temp, Self.RecvBuffer, Self.RecvSize)
			MemFree(Self.RecvBuffer)
			Self.RecvBuffer = Temp
			'speed measurement
			If Floor(MilliSecs()/1000) <> Self.fLastSecond
			  Self.fDataSum  = Self.fDataGot + Self.fDataSent
			  Self.fLastSecond = Floor(MilliSecs() / 1000)
			  Self.fDataGot  = 0
			  Self.fDataSent = 0
			EndIf
			Self.fDataGot :+ Self.RecvSize
			'end speed
		Else
			Self.RecvBuffer = MemAlloc(Size)
		EndIf

		Result = recvfrom_(Self.Socket, Self.RecvBuffer+Self.RecvSize, ..
		                   Size, 0, MessageIP, MessagePort)

		If Result = SOCKET_ERROR_ Or Result = 0 Then
			Return 0
		Else
			Self.MessageIP   = MessageIP
			Self.MessagePort = Short(MessagePort)
			Self.RecvSize   :+ Result
			Return Result
		EndIf
	End Method


	Method SendUDPMsg:Int(iIP:Int, shPort:Short = 0)
      Local oldIP:Int = Self.remoteIP
	  Local oldPort:Short = Self.RemotePort
	  Self.RemoteIP = iIP
	  Self.RemotePort = shPort
	  Local returnvalue:Int = Self.SendMsg()
	  Self.RemoteIP = oldIP
	  Self.RemotePort = oldPort
	  Return returnvalue
	End Method

	Rem
		bbdoc:   Sendet eine Nachricht
		returns: Anzahl der versendeten Bytes.
		about:   Sendet eine Nachricht an den mit #SetRemoteIP und #SetRemotePort festgelegten<br/>
		         Empfnger. Dazu sollte sich eine Nachricht schon im Sendepuffer befinden.<br />
		         Dieser lsst sich mit den &uuml;blichen Streambefehlen wie<br />
		         #WriteLine beschreiben.<br />
		         Siehe auch: #RecvMsg , #SetRemotePort , #SetRemoteIP
	End Rem
	Method SendMsg:Int()
		Local Write:Int, Result:Int, Temp:Byte Ptr

		If Self.Socket = INVALID_SOCKET_ Or ..
		   Self.SendSize = 0 Then Return 0

		Write = Self.Socket
		If selectex_(0, Null, 1, Varptr(Write), 0, Null, 0) <> 1 ..
		   Then Return 0

		Result = sendto_(Self.Socket, Self.SendBuffer, Self.SendSize, ..
		                 0, Self.RemoteIP, Self.RemotePort)

		If Result = SOCKET_ERROR_ Or Result = 0 Then
			Return 0
		Else
			If Result = Self.SendSize Then
				MemFree(Self.SendBuffer)
				Self.SendSize = 0
			Else
				Temp = MemAlloc(Self.SendSize-Result)
				MemCopy(Temp, Self.SendBuffer+Result, Self.SendSize-Result)
				MemFree(Self.SendBuffer)
				Self.SendBuffer = Temp
				Self.SendSize :- Result
				'speed measurement
				If Floor(MilliSecs()/1000) <> Self.fLastSecond
				Self.fDataSum  = Self.fDataGot + Self.fDataSent
				Self.fLastSecond = Floor(MilliSecs() / 1000)
				Self.fDataGot  = 0
				Self.fDataSent = 0
				EndIf
				Self.fDataSent :+ (Self.Sendsize- Result)
				'end speed
			EndIf

			Return Result
		EndIf
	End Method

	Method UDPSpeedString:String()
	 If Self.fDataSum > 1024 Then Return ((Int(Self.fDataSum*10/1024))/10)+"kb/s"
	 If Self.fDataSum <= 1024 Then Return Int(Self.fDataSum)+"b/s"
	End Method
End Type


Rem
	bbdoc: TCP-Stream Type
	about: Type f&uuml;r verbindungsorientierte Kommunikation.<br />
	       F&uuml;r TCP-Server und Client gleichemraen zu benutzen
End Rem
Type TTCPStream Extends TNetStream
	Field LocalIP       : Int
	Field LocalPort     : Short
	Field RemoteIP      : Int
	Field RemotePort    : Short

	Field RecvTimeout   : Int
	Field SendTimeout   : Int
	Field AcceptTimeout : Int

	Method New()
		Self.LocalIP       = 0
		Self.LocalPort     = 0
		Self.RemoteIP      = 0
		Self.RemotePort    = 0

		Self.RecvTimeout   = 0
		Self.SendTimeout   = 0
		Self.AcceptTimeout = 0
	End Method

	Rem
		bbdoc:   Initialisiert den TCPStream
		returns: False, wenn ein Fehler auftrat, ansonsten True
		about:   Intern wird ein neuer Socket erstellt.
	End Rem
	Method Init:Int()
		Local Size : Int

		Self.Socket = socket_(AF_INET_, SOCK_STREAM_, 0)
		If Self.Socket = INVALID_SOCKET_ Then Return False

		' 2^16 - 1 Byte
		Size = 1% Shl 16 - 1
		If setsockopt_(Self.Socket, SOL_SOCKET_, SO_RCVBUF_, Varptr(Size), 4) = SOCKET_ERROR_ Or ..
		   setsockopt_(Self.Socket, SOL_SOCKET_, SO_SNDBUF_, Varptr(Size), 4) = SOCKET_ERROR_ Then
			closesocket_(Self.Socket)
			Return False
		EndIf

		Return True
	End Method

	Rem
		bbdoc:   Setzt den lokalen Port
		returns: False, wenn ein Fehler auftrat, ansonsten True
		about:   Wenn bei Port 0 angegeben wurde, so sucht das Betriebssystem einen <br />
		         freihen Port. Diesen kann man mit #GetLocalPort herausbekommen.<br />
		         Dies ist nur der lokale Port, und muss NICHT mit dem Port des Empfngers <br />
		         &uuml;bereinstimmen.<br />
		         Siehe auch: #GetLocalPort , #GetLocalIP
	End Rem
	Method SetLocalPort:Int(Port:Short=0)
		Local Address:TSockAddr, NameLen:Int

		' Socket does not exist?
		If Self.Socket = INVALID_SOCKET_ Then Return False

		' Bind to Port
		If bind_(Self.Socket, AF_INET_, Port) = SOCKET_ERROR_ Then
			Return False
		Else
			' Update Local IP and Port
			Address = New TSockAddr
			NameLen = 16
			If getsockname_(Self.Socket, Address, Varptr(NameLen)) = SOCKET_ERROR_ Then
				Return False
			Else
				Self.LocalIP   = ntohl_(Address.SinAddr)
				Self.LocalPort = ntohs_(Address.SinPort)
				Return True
			EndIf
		EndIf
	End Method

	Rem
		bbdoc:   Gibt den lokalen Port zur&uuml;ck
		returns: lokaler Port
		about:   Siehe auch: #SetLocalPort
	End Rem
	Method GetLocalPort:Short()
		Return Self.LocalPort
	End Method

	Rem
		bbdoc:   Gibt die lokale IP in Integerform zur&uuml;ck
		returns: IntegerIP
		about:   Damit lsst sich NICHT die globale IP herausfinden. Diese Methode<br />
		         ist erst nach #SetLocalPort einsatzbereit.<br />
		         Siehe auch: #SetLocalPort , #GetLocalPort
	End Rem
	Method GetLocalIP:Int()
		Return Self.LocalIP
	End Method

	Rem
		bbdoc:   Setzt den Empfngerport
		returns: -
		about:   Zu diesen Port wird der TCPStream nach #Connect verbunden. Dieser Port<br />
		         muss NICHT mit dem lokalen Port &uuml;bereinstimmen. Benutze diese Methode in<br />
		         Zusammenhang mit #SetRemoteIP.<br />
		         Siehe auch: #GetRemotePort
	End Rem
	Method SetRemotePort(Port:Short)
		Self.RemotePort = Port
	End Method

	Rem
		bbdoc:   Gibt den Empfngerport zur&uuml;ck
		returns: Empfngerport
		about:   Zu diesen Port ist der TCPStream entweder verbunden oder muss noch<br />
		         mit #Connect verbunden werden. Dieser Port muss NICHT mit dem lokalen<br />
		         Port &uuml;bereinstimmen.<br />
		         Siehe auch: #SetRemotePort
	End Rem
	Method GetRemotePort:Short()
		Return Self.RemotePort
	End Method

	Rem
		bbdoc:   Setzt die EmpfngerIP
		returns: -
		about:   Zu dieser IP-Adresse wird der TCPStream nach #Connect verbunden.<br />
		         Benutze diese Methode in Zusammenhang mit #SetRemotePort.<br />
		         Siehe auch: #GetRemotePort
	End Rem
	Method SetRemoteIP(IP:Int)
		Self.RemoteIP = IP
	End Method

	Rem
		bbdoc:   Gibt die EmpfngerIP in Integerform zur&uuml;ck
		returns: EmpfngerIP
		about:   Zu dieser IP-Adresse ist der TCPStream entweder verbunden oder muss noch<br />
		         mit #Connect verbunden werden.<br />
		         Siehe auch: #SetRemotePort
	End Rem
	Method GetRemoteIP:Int()
		Return Self.RemoteIP
	End Method

	Rem
		bbdoc:   Setzt Abbruchszeiten f&uuml;r das Empfangen, Senden und Verbinden
		returns: -
		about:   Bestimmt, wie lange #RecvMsg, #SendMsg und #Accept max. warten d&uuml;rfen.<br />
		         Angaben in Millisekunden<br />
		         Siehe auch: #GetRecvTimeout , #GetSendTimeout , #GetAcceptTimeout
	End Rem
	Method SetTimeouts(RecvMillisecs:Int, SendMillisecs:Int, AcceptMillisecs:Int=0)
		Self.RecvTimeout   = RecvMillisecs
		Self.SendTimeout   = SendMillisecs
		Self.AcceptTimeout = AcceptMillisecs
	End Method

	Rem
		bbdoc:   Gibt Abbruchszeit f&uuml;r das Empfangen zur&uuml;ck
		returns: Abbruchszeit in Millisekunden
		about:   Siehe auch: #SetTimeouts , #GetSendTimeout , #GetAcceptTimeout
	End Rem
	Method GetRecvTimeout:Int()
		Return Self.RecvTimeout
	End Method

	Rem
		bbdoc:   Gibt Abbruchszeit f&uuml;r das Senden zur&uuml;ck
		returns: Abbruchszeit in Millisekunden
		about:   Siehe auch: #SetTimeouts , #GetRecvTimeout , #GetAcceptTimeout
	End Rem
	Method GetSendTimeout:Int()
		Return Self.SendTimeout
	End Method

	Rem
		bbdoc:   Gibt Abbruchszeit f&uuml;r das Verbinden zur&uuml;ck
		returns: Abbruchszeit in Millisekunden
		about:   Siehe auch: #SetTimeouts , #GetRecvTimeout , #GetSendTimeout
	End Rem
	Method GetAcceptTimeout:Int()
		Return Self.AcceptTimeout
	End Method

	Rem
		bbdoc:   Baut eine Verbindung zum Server auf
		returns: False, wenn ein Fehler auftrat, ansonsten True
		about:   Wenn der TCPStream als Client agiert, so wird zum angebenen<br />
		         Server eine Verbindung aufgebaut. Der Server kann mit #SetRemoteIP sowie<br />
		         #SetRemotePort angegeben werden.<br />
		         Siehe auch: #SetRemotePort , #SetRemoteIP , #SetLocalPort
	End Rem
	Method Connect:Int()
		Local Address:Int

		' Socket does not exist?
		If Self.Socket = INVALID_SOCKET_ Then Return False

		' Try to connect Remote
		Address = htonl_(Self.RemoteIP)
		If connect_(Self.Socket, Varptr(Address), AF_INET_, 4, Self.RemotePort) ..
		   = SOCKET_ERROR_ Then
			Return False
		Else
			Return True
		EndIf
	End Method

	Rem
		bbdoc:   Aktiviert den Server
		returns: False, wenn ein Fehler auftrat, ansonsten True
		about:   Wenn der TCPStream als Server agiert, so kann von nun an eine Verbindung<br />
		         zu ihm aufgebaut werden. Erst danach k&ouml;nnen auch Clients mit #Accept <br />
		         abgefragt werden. Der Server muss zuerst mit #SetLocalPort an einen Port<br />
		         gebunden sein.<br />
		         Siehe auch: #Accept, #SetLocalPort
	End Rem
	Method Listen:Int(MaxClients:Int=32)
		' Socket does not exist?
		If Self.Socket = INVALID_SOCKET_ Then Return False

		' Try to set in listen mode
		If listen_(Self.Socket, MaxClients) = SOCKET_ERROR_ Then
			Return False
		Else
			Return True
		EndIf
	End Method

	Rem
		bbdoc:   Pr&uuml;ft, ob ein Client eine Verbindung zum Server aufgebaut hat
		returns: Null, wenn kein Client vorliegt, ansonsten TCPStream des neuen Client<br />
		about:   Jeder Client verbindet sich nur einmal mit dem Server, danach muss sein<br />
		         Clientstream auf eintreffende Nachricht gepr&uuml;ft werden.<br />
		         Der Server muss zuvor mit #Listen "aktiviert" werden.<br />
		         Siehe auch: #Listen
	End Rem
	Method Accept:TTCPStream()
		Local Read:Int, Result:Int, Address:TSockAddr, AddrLen:Int
		Local Client:TTCPStream

		' Socket does not exist?
		If Self.Socket = INVALID_SOCKET_ Then Return Null

		' Things to read?
		Read = Self.Socket
		If selectex_(1, Varptr(Read), 0, Null, 0, Null, Self.AcceptTimeout) <> 1 ..
		   Then Return Null

		Address = New TSockAddr
		AddrLen = SizeOf(Address)

		' Client avariable?
		Result = accept_(Self.Socket, Address, Varptr(AddrLen))
		If Result = SOCKET_ERROR_ Then Return Null

		' Set Local IP and Port
		Client = New TTCPStream
		Client.Socket    = Result
		Client.LocalIP   = ntohl_(Address.SinAddr)
		Client.LocalPort = ntohs_(Address.SinPort)

		' Set Remote IP and Port
		AddrLen = SizeOf(Address)
		If getsockname_(Client.Socket, Address, Varptr(AddrLen)) = SOCKET_ERROR_ Then
			Client.Close()
			Return Null
		EndIf

		Client.RemoteIP   = ntohl_(Address.SinAddr)
		Client.RemotePort = ntohs_(Address.SinPort)

		Return Client
	End Method

	Rem
		bbdoc:   Empfngt eine Nachricht
		returns: Anzahl der empfangenen Bytes.
		about:   Empfngt eine eingehende Nachricht. Ob eine Nachricht vorliegt,<br />
		         kann mit #RecvAvail gepr&uuml;ft werden. Die Nachricht wird in einem<br />
		         Puffer gelagert. Das Auslesen der Nachricht erfolgt &uuml;ber &uuml;bliche <br />
		         Streambefehle wie #ReadLine .<br />
		         Siehe auch: #SendMsg , #RecvAvail
	End Rem
	Method RecvMsg:Int()
		Local Result:Int, Read:Int, Size:Int, Temp:Byte Ptr

		' If Socket does not exist
		If Self.Socket = INVALID_SOCKET_ Then Return 0

		' Try to receive
		Read = Self.Socket
		If selectex_(1, Varptr(Read), 0, Null, 0, Null, Self.RecvTimeout) <> 1 ..
		   Then Return 0

		If ioctl_(Self.Socket, FIONREAD, Varptr(Size)) = SOCKET_ERROR_ ..
		   Then Return 0

		If Size <= 0 Then Return 0

		If Self.RecvSize > 0 Then
			Temp = MemAlloc(Self.RecvSize+Size)
			MemCopy(Temp, Self.RecvBuffer, Self.RecvSize)
			MemFree(Self.RecvBuffer)
			Self.RecvBuffer = Temp
		Else
			Self.RecvBuffer = MemAlloc(Size)
		EndIf

		Result = recv_(Self.Socket, Self.RecvBuffer+Self.RecvSize, Size, 0)

		If Result = SOCKET_ERROR_ Then
			Return 0
		Else
			Self.RecvSize :+ Result
			Return Result
		EndIf
	End Method

	Rem
		bbdoc:   Sendet eine Nachricht
		returns: Anzahl der versendeten Bytes.
		about:   Sendet eine Nachricht an den Client bzw. an den verbundenen Server. Dazu<br />
		         sollte sich eine Nachricht schon im Sendepuffer befinden.<br />
		         Dieser lsst sich mit den &uuml;blichen Streambefehlen wie #WriteLine<br />
		         beschreiben.<br />
		         Siehe auch: #RecvMsg
	End Rem
	Method SendMsg:Int()
		Local Write:Int, Result:Int, Temp:Byte Ptr

		' If Socket does not exist
		If Self.Socket = INVALID_SOCKET_ Then Return 0

		If Self.SendSize < 0 Then Return 0

		' Try to receive
		Write = Self.Socket
		If selectex_(0, Null, 1, Varptr(Write), 0, Null, Self.SendTimeout) <> 1 ..
		   Then Return 0

		Result = send_(Self.Socket, Self.SendBuffer, Self.SendSize, 0)

		If Result = SOCKET_ERROR_ Or Result = 0 Then
			Return 0
		Else
			If Result = Self.SendSize Then
				MemFree(Self.SendBuffer)
				Self.SendSize = 0
			Else
				Temp = MemAlloc(Self.SendSize-Result)
				MemCopy(Temp, Self.SendBuffer+Result, Self.SendSize-Result)
				MemFree(Self.SendBuffer)
				Self.SendBuffer = Temp
				Self.SendSize :- Result
			EndIf

			Return Result
		EndIf
	End Method

	Rem
		bbdoc:   Gibt den Zustand des TCPStreams zur&uuml;ck
		returns: -1, wenn ein Fehler auftrat, 0 wenn Verbindung getrennt wurde oder</ br>
		         1 wenn alle in Ordnung ist
		about:   Siehe auch: #RecvAvail
	End Rem
	Method GetState:Int()
		Local Read:Int, Result:Int, Size:Int

		If Self.Socket = INVALID_SOCKET_ Then Return -1

		Read   = Self.Socket
		Result = selectex_(1, Varptr(Read), 0, Null, 0, Null, 0)

		If Result = SOCKET_ERROR_ Then
			' Error
			Self.Close()
			Return -1
		ElseIf Result = 1
			Size = Self.RecvAvail()
			If Size = SOCKET_ERROR_ Then
				' Error
				Self.Close()
				Return -1
			ElseIf Size = 0 Then
				' Disconnected
				Self.Close()
				Return 0
			Else
				' All right
				Return 1
			EndIf
		Else
			' All right
			Return 1
		EndIf
	End Method
End Type