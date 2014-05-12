SuperStrict

Rem
	bbdoc: BNetEx
	about: Netzwerk Modul f&uuml;r UDP und TCP<br />
	       <br />
	       License:<br />
	       Permission is hereby granted, free of charge, to any person obtaining a copy of<br />
	       this software and associated documentation files (the "Software"), to deal in<br />
	       the Software without restriction, including without limitation the rights to<br />
	       use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of<br />
	       the Software, and to permit persons to whom the Software is furnished to do so,<br />
	       subject to the following conditions:<br />
	       <br />
	       The author Oliver Skawronek and the co-author Inkubus have to be by name mentioned.
End Rem
Rem
Module Vertex.BNetEx
ModuleInfo "Version: 1.70 Beta"
ModuleInfo "Author: Oliver Skawronek"
ModuleInfo "Additive Work: Inkubus"
ModuleInfo "License: Modified MIT"
ModuleInfo "Modserver: BlitzHelp"
endrem
Import Brl.Stream
Import Brl.Math
Import Pub.StdC
?Win32
	Import "windows.c"
	Import "libiphlpapi.a"
?Linux
	Import "linux.c"
	Import "bsd.c"
?MacOS
	Import "bsd.c"
?

Private

Type TSockAddr
	Field SinFamily : Short
	Field SinPort   : Short
	Field SinAddr   : Int
	Field SinZero   : Long
End Type

Type TICMP
	Field _Type    : Byte
	Field Code     : Byte
	Field Checksum : Short
	Field ID       : Short
	Field Sequence : Short

	Function BuildChecksum:Short(Buffer:Short Ptr, Size:Int)
		Local Checksum:Long

		While Size > 1
			Checksum :+ Buffer[0]
			Buffer :+ 1
			Size :- 2
		Wend
		If Size Then Checksum :+ (Byte Ptr(Buffer))[0]

		Checksum = (Checksum Shr 16) + (Checksum & $FFFF)
		Checksum :+ Checksum Shr 16
		Return htons_(~Checksum)
	End Function
End Type

Extern "OS"
	Const INVALID_SOCKET_ : Int = -1
	Const SOCK_RAW_       : Int = 3
	Const IPPROTO_ICMP    : Int = 1

	Const ICMP_ECHOREPLY   : Byte = 0
	Const ICMP_UNREACHABLE : Byte = 3
	Const ICMP_ECHO        : Byte = 8

	Const ICMP_CODE_NETWORK_UNREACHABLE : Byte = 0
	Const ICMP_CODE_HOST_UNREACHABLE    : Byte = 1

	?Win32
		Const FIONREAD      : Int   = $4004667F
		Const SOL_SOCKET_   : Int   = $FFFF
		Const SO_BROADCAST_ : Short = $20
		Const SO_SNDBUF_    : Short = $1001
		Const SO_RCVBUF_    : Short = $1002

		Function ioctl_:Int(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctlsocket@12"
		Function inet_addr_:Int(Address$z) = "inet_addr@4"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa@4"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname@12"
		Function GetCurrentProcessId:Int() = "GetCurrentProcessId@0"

	?MacOS
		Const FIONREAD      : Int   = $4004667F
		Const SOL_SOCKET_   : Int   = $FFFF
		Const SO_BROADCAST_ : Short = $20
		Const SO_SNDBUF_    : Short = $1001
		Const SO_RCVBUF_    : Short = $1002

		Function ioctl_(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctl"
		Function inet_addr_:Int(Address$z) = "inet_addr"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname"
		Function GetCurrentProcessId:Int() = "getpid"

	?Linux
		Const FIONREAD      : Int   = $0000541B
		Const SOL_SOCKET_   : Int   = 1
		Const SO_BROADCAST_ : Short = 6
		Const SO_SNDBUF_    : Short = 7
		Const SO_RCVBUF_    : Short = 8

		Function ioctl_(Socket:Int, Command:Int, Arguments:Byte Ptr) = "ioctl"
		Function inet_addr_:Int(Address$z) = "inet_addr"
		Function inet_ntoa_:Byte Ptr(Adress:Int) = "inet_ntoa"
		Function getsockname_:Int(Socket:Int, Name:Byte Ptr, NameLen:Int Ptr) = "getsockname"
		Function GetCurrentProcessId:Int() = "getpid"
	?
End Extern

Extern "C"
	?Linux
		Function selectex_:Int(ReadCount:Int, ReadSockets:Int Ptr, ..
		                       WriteCount:Int, WriteSockets:Int Ptr, ..
		                       ExceptCount:Int, ExceptSockets:Int Ptr, ..
		                       Milliseconds:Int) = "pselect_"
	?

	Function GetNetworkAdapter(Device:Byte Ptr, MAC:Byte Ptr, ..
	                           Address:Int Ptr, Netmask:Int Ptr, ..
	                           Broadcast:Int Ptr) = "GetNetworkAdapter"
End Extern

?Win32
	Global selectex_:Int(ReadCount:Int, ReadSockets:Int Ptr, ..
	                     WriteCount:Int, WriteSockets:Int Ptr, ..
	                     ExceptCount:Int, ExceptSockets:Int Ptr, ..
	                     Milliseconds:Int) = select_
?MacOS
	Global selectex_:Int(ReadCount:Int, ReadSockets:Int Ptr, ..
	                     WriteCount:Int, WriteSockets:Int Ptr, ..
	                     ExceptCount:Int, ExceptSockets:Int Ptr, ..
	                     Milliseconds:Int) = select_
?

Public

Rem
	bbdoc: Netzwerkadapter-Information
	about: Enth&auml;lt Informationen &uuml;ber einen Netzwerkadapter(ggf. Netzwerkkarte).<br />
	       Siehe auch: #GetNetworkAdapter
End Rem
Type TAdapterInfo
	Rem
		bbdoc: Name des Netzwerkadapters
	End Rem
	Field Device    : String
	Rem
		bbdoc: MAC-Adresse des Netzwerkadapters
		about: Siehe auch: #StringMAC
	End Rem
	Field MAC       : Byte[6]
	Rem
		bbdoc: IP-Adresse des Netzwerkadapters
		about: Siehe auch: #StringIP
	End Rem
	Field Address   : Int
	Rem
		bbdoc: Broadcast-Adresse des Netzwerkadapters
		about: Siehe auch: #StringIP
	End Rem
	Field Broadcast : Int
	Rem
		bbdoc: Netzmaske des Netzwerkadapters
		about: Siehe auch: #StringIP, #SetBroadcast
	End Rem
	Field Netmask   : Int
End Type

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
		bbdoc:   Wandelt Integer- in StringMAC um
		returns: Umgewandelte StringMAC
		about:   Es wird ein String in From von "AA:BB:CC:DD:EE:FF" zur&uuml;ckgegeben.<br />
		         AA, BB, CC, DD, EE und FF repr&auml;sentieren jeweils ein Byte in hexa-
		         dezimaler Schreibweise.<br />
		         Siehe auch: #TAdapterInfo, #GetNetworkAdapter
	End Rem
	Function StringMAC:String(MAC:Byte[])
		Local Out:String, Index:Int, Nibble1:Byte, Nibble2:Byte

		For Index = 0 To 5
			Nibble1 = (MAC[Index] & $F0) Shr 4
			Nibble2 = MAC[Index] & $0F

			If(Nibble1 < 10)
				Out :+ Chr(Nibble1 + 48)
			Else
				Out :+ Chr(Nibble1 + 55)
			EndIf

			If(Nibble2 < 10)
				Out :+ Chr(Nibble2 + 48)
			Else
				Out :+ Chr(Nibble2 + 55)
			EndIf

			Out :+ "-"
		Next

		Return Out[..Out.Length - 1]
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

	Rem
		bbdoc:   ICMP Ping
		returns: -1 falls ein Fehler auftrat, ansonsten die Zeit in Millisekunden,<br/>
		         vom Echo Request zum Echo Reply
		about:   Die Funktion emrittelt, wie lange es gedauert hat, bis der<br />
		         der Host RemoteIP die angegebenen Daten Data mit der Bytegr&ouml;&szlig;e<br />
		         Size empfangen und zurück gesendet hat. Erhält der Client keine<br />
		         Antwort innerhalb der Zeit Timeout, liefert die Funktion<br />
		         -1 zur&uuml;ck. Weitere Fehlerquellen können sein, dass die Funktion nicht<br />
		         mit Root/Administratorrechten ausgef&uuml;hrt wurde, das Netzwerk<br />
		         bzw. der Host nicht erreichbar ist oder der Host ICMP Pings nicht akzeptiert.
		         Siehe auch: #GetHostIP, #GetHostIPs, #IntIP
	End Rem
	Function Ping:Int(RemoteIP:Int, Data:Byte Ptr, Size:Int, Sequence:Int = 0, ..
	                  Timeout:Int = 5000)
		Local Socket:Int, ProcessID:Int, ICMP:TICMP, Buffer:Byte Ptr, Temp:Int, ..
		      Start:Int, Stop:Int, Result:Int, SenderIP:Int, SenderPort:Int, ..
		      IPSize:Int

		Socket = socket_(AF_INET_, SOCK_RAW_, IPPROTO_ICMP)
		If Socket = INVALID_SOCKET_ Then Return -1

		ProcessID = GetCurrentProcessID()

		ICMP = New TICMP
		ICMP._Type     = ICMP_ECHO
		ICMP.Code      = 0
		ICMP.Checksum  = 0
		ICMP.ID        = ProcessID
		ICMP.Sequence  = Sequence

		Buffer = MemAlloc(65536)
		MemCopy(Buffer, ICMP, 8)
		MemCopy(Buffer + 8, Data, Size)
		Short Ptr(Buffer)[1] = htons_(TICMP.BuildChecksum(Short Ptr(Buffer), 8 + Size))

		Temp = Socket
		If (selectex_(0, Null, 1, Varptr(Temp), 0, Null, 0) <> 1) Or ..
		   (sendto_(Socket, Buffer, 8 + Size, 0, RemoteIP, 0) = SOCKET_ERROR_) Then
			MemFree(Buffer)
			closesocket_(Socket)
			Return -1
		EndIf

		Start = MilliSecs()
		Repeat
			Temp = Socket
			If selectex_(1, Varptr(Temp), 0, Null, 0, Null, Timeout) <> 1 Then
				MemFree(Buffer)
				closesocket_(Socket)
				Return -1
			EndIf

			Result = recvfrom_(Socket, Buffer, 65536, 0, SenderIP, SenderPort)
			Stop = MilliSecs()
			If Result = SOCKET_ERROR_ Then
				MemFree(Buffer)
				closesocket_(Socket)
				Return -1
			EndIf

			?X86
				IPSize = (Buffer[0] & $0F)*4
			?PPC
				IPSize = (Buffer[0] & $F0)*4
			?
			MemCopy(ICMP, Buffer + IPSize, 8)

			If ICMP.ID <> ProcessID Then
				Continue
			ElseIf ICMP._Type = ICMP_UNREACHABLE Then
				If ICMP.Code = ICMP_CODE_HOST_UNREACHABLE Or ..
				   ICMP.Code = ICMP_CODE_NETWORK_UNREACHABLE Then
					MemFree(Buffer)
					closesocket_(Socket)
					Return -1
				EndIf
			ElseIf ICMP.Code = ICMP_ECHOREPLY Then
				Exit
			EndIf
		Forever

		MemFree(Buffer)
		closesocket_(Socket)

		'ronny: return Abs value if Stop and Start are negative
		'       values (>25 days uptime)
		Return Abs(Stop - Start)
	End Function

	Rem
		bbdoc:   F&uuml;llt eine Struktur mit Netzwerkadapter-Informationen
		returns: False, wenn ein Fehler auftrat, ansonsten True
		about:   Ermittelt den ersten Ethernet-Netzwerkadapter und f&uuml;llt die<br />
		         angegebene Struktur Info. Ist Info eine Nullreferenz so wird eine neue<br />
		         Instanz angelegt. Die Funktion muss mit Root/Administratorrechten ausgef&uuml;hrt<br />
		         werden.
		         Siehe auch: #TAdapterInfo
	End Rem
	Function GetAdapterInfo:Int(Info:TAdapterInfo Var)
		Local Device:Byte Ptr

		If Not Info Then Info = New TAdapterInfo

		Device = MemAlloc(256)
		If Not GetNetworkAdapter(Device, Info.MAC, Varptr(Info.Address), ..
			Varptr(Info.Netmask), Varptr(Info.Broadcast)) Then Return False
		Info.Device = String.FromCString(Device)

		Return True
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
		         die Gr&ouml;ße des Empfangspuffers.<br />
		         Siehe auch: #Size
	End Rem
	Method Eof:Int()
		Return Self.RecvSize = 0
	End Method

	Rem
		bbdoc:   Gibt die Anzahl an empfangenen Bytes zur&uuml;ck
		returns: Anzahl an empfangenen Bytes
		about:   Nach jedem #RecvMsg wird eine Nachricht in den Empfangspuffer angehängt.<br />
		         Diese Methode gibt zur&uuml;ck, wieviel Bytes noch mit den allgemeinen Stream-<br />
		         befehlen, wie z. B. #ReadLine , aus diesen ausgelesen werden k&ouml;nnen.<br>
		         Siehe auch: #RecvAvail
	End Rem
	Method Size:Int()
		Return Self.RecvSize
	End Method

	Rem
		bbdoc:   Löscht den internen Sende- und Empfangspuffer.
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

	'ron
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
		         Dies ist nur der lokale Port, und muss NICHT mit dem Port des Empfängers <br />
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
		about:   Damit lässt sich NICHT die globale IP ermitteln.<br />
		         Diese Methode ist erst nach #SetLocalPort einsatzbereit.<br />
		         Siehe auch: #SetLocalPort , #GetLocalPort
	End Rem
	Method GetLocalIP:Int()
		Return Self.LocalIP
	End Method

	Rem
		bbdoc:   Setzt den Empfängerport
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
		bbdoc:   Gibt den Empfängerport zur&uuml;ck
		returns: Empfängerport
		about:   An diesen Port wird die k&uuml;nftige Nachricht mit #SendMsg geschickt.<br />
		         Dieser Port muss NICHT mit dem lokalen Port &uuml;bereinstimmen.<br />
		         Siehe auch: #SetRemotePort
	End Rem
	Method GetRemotePort:Short()
		Return Self.RemotePort
	End Method

	Rem
		bbdoc:   Setzt die EmpfängerIP
		returns: -
		about:   An diese IP-Adresse wird die k&uuml;nftige Nachricht mit #SendMsg geschickt.<br />
		         Benutze diese Methode in Zusammenhang mit SetRemotePort.<br />
		         Siehe auch: #GetRemoteIP , #GetSetRemotePort
	End Rem
	Method SetRemoteIP(IP:Int)
		Self.RemoteIP = IP
	End Method

	Rem
		bbdoc:   Gibt die EmpfängerIP zur&uuml;ck
		returns: EmpfängerIP
		about:   An diese IP-Adresse wird die k&uuml;nftige Nachricht mit #SendMsg geschickt.<br />
		         Dieser Port muss NICHT mit dem lokalen Port &uuml;bereinstimmen.<br />
		         Siehe auch: #SetRemotePort
	End Rem
	Method GetRemoteIP:Int()
		Return Self.RemoteIP
	End Method

	Rem
		bbdoc:   Aktiviert/Deaktiviert das Senden und Empfangen von Broadcast-Nachrichten
		returns: False, wenn ein Fehler auftrat, ansonsten True.
		about:   Siehe auch: #GetAdapterInfo, #TAdapterInfo, #GetBroadcast
	End Rem
	Method SetBroadcast:Int(Enable:Int)
		If Self.Socket = INVALID_SOCKET_ Then Return False
		If Enable Then Enable = True

		If setsockopt_(Self.Socket, SOL_SOCKET_, SO_BROADCAST_, Varptr(Enable), 4) ..
			= SOCKET_ERROR_ Then Return False

		Return True
	End Method

	Rem
		bbdoc:   Gibt den aktuellen Broadcast-Zustand zur&uuml;ck
		returns: -1, wenn ein Fehler auftrat, True wenn Broadcasting aktiviert ist, <br>
		         False wenn broadcasting deaktiviert ist.
		about:   Siehe auch: #SetBroadcast
	End Rem
	Method GetBroadcast:Int()
		Local Enable:Int, Size:Int

		If Self.Socket = INVALID_SOCKET_ Then Return False

		Size = 4
		If getsockopt_(Self.Socket, SOL_SOCKET_, SO_BROADCAST_, Varptr(Enable), ..
		               Size)= SOCKET_ERROR_ Then Return -1

		Return Enable
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
		bbdoc:   Empfängt eine Nachricht
		returns: Anzahl der empfangenen Bytes.
		about:   Empfängt eine eingehende Nachricht. Ob eine Nachricht vorliegt,<br />
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

	Method SendUDPMsg:Int(IP:Int, Port:Int = 0)
		Local oldIP:Int = remoteIP
		Local oldPort:Short = RemotePort
		SetBroadcast(True)
		RemoteIP = IP
		RemotePort = Port
		Local _sendSize:Int = SendSize
		While SendMsg() ; Wend

'		Local returnvalue:Int = SendMsg()
		RemoteIP = oldIP
		RemotePort = oldPort
		Return _sendSize
	End Method


	Rem
		bbdoc:   Sendet eine Nachricht
		returns: Anzahl der versendeten Bytes.
		about:   Sendet eine Nachricht an den mit #SetRemoteIP und #SetRemotePort festgelegten<br/>
		         Empfänger. Dazu sollte sich eine Nachricht schon im Sendepuffer befinden.<br />
		         Dieser lässt sich mit den &uuml;blichen Streambefehlen wie<br />
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
			EndIf

				'speed measurement
				If Floor(MilliSecs()/1000) <> Self.fLastSecond
					Self.fDataSum  = Self.fDataGot + Self.fDataSent
					Self.fLastSecond = Floor(MilliSecs() / 1000)
					Self.fDataGot  = 0
					Self.fDataSent = 0
				EndIf
				Self.fDataSent :+ Result
				'end speed

			Return Result
		EndIf
	End Method
End Type

Rem
	bbdoc: TCP-Stream Type
	about: Type f&uuml;r verbindungsorientierte Kommunikation.<br />
	       F&uuml;r TCP-Server und Client gleichemraßen zu benutzen
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
		         Dies ist nur der lokale Port, und muss NICHT mit dem Port des Empfängers <br />
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
		about:   Damit lässt sich NICHT die globale IP herausfinden. Diese Methode<br />
		         ist erst nach #SetLocalPort einsatzbereit.<br />
		         Siehe auch: #SetLocalPort , #GetLocalPort
	End Rem
	Method GetLocalIP:Int()
		Return Self.LocalIP
	End Method

	Rem
		bbdoc:   Setzt den Empfängerport
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
		bbdoc:   Gibt den Empfängerport zur&uuml;ck
		returns: Empfängerport
		about:   Zu diesen Port ist der TCPStream entweder verbunden oder muss noch<br />
		         mit #Connect verbunden werden. Dieser Port muss NICHT mit dem lokalen<br />
		         Port &uuml;bereinstimmen.<br />
		         Siehe auch: #SetRemotePort
	End Rem
	Method GetRemotePort:Short()
		Return Self.RemotePort
	End Method

	Rem
		bbdoc:   Setzt die EmpfängerIP
		returns: -
		about:   Zu dieser IP-Adresse wird der TCPStream nach #Connect verbunden.<br />
		         Benutze diese Methode in Zusammenhang mit #SetRemotePort.<br />
		         Siehe auch: #GetRemotePort
	End Rem
	Method SetRemoteIP(IP:Int)
		Self.RemoteIP = IP
	End Method

	Rem
		bbdoc:   Gibt die EmpfängerIP in Integerform zur&uuml;ck
		returns: EmpfängerIP
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
		bbdoc:   Empfängt eine Nachricht
		returns: Anzahl der empfangenen Bytes.
		about:   Empfängt eine eingehende Nachricht. Ob eine Nachricht vorliegt,<br />
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
		         Dieser lässt sich mit den &uuml;blichen Streambefehlen wie #WriteLine<br />
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
