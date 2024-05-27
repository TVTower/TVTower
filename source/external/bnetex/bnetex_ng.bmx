SuperStrict
Import Brl.Stream
Import Brl.Math
Import Pub.StdC

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
rem
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
endrem
End Type


Function GetNetworkAdapter:Int(Device:Byte Ptr, MAC:Byte Ptr, ..
	                           Address:Int Ptr, Netmask:Int Ptr, ..
	                           Broadcast:Int Ptr)
	return 0
End Function


?win32 and ptr64
	Global selectex_:Int(ReadCount:Int, ReadSockets:Long Ptr, WriteCount:Int, WriteSockets:Long Ptr, ExceptCount:Int, ExceptSockets:Long Ptr, Milliseconds:Int) = select_
?win32 and ptr32
	Global selectex_:Int(ReadCount:Int, ReadSockets:Int Ptr, WriteCount:Int, WriteSockets:Int Ptr, ExceptCount:Int, ExceptSockets:Int Ptr, Milliseconds:Int) = select_
?not win32
	Global selectex_:Int(ReadCount:Int, ReadSockets:Int Ptr, WriteCount:Int, WriteSockets:Int Ptr, ExceptCount:Int, ExceptSockets:Int Ptr, Milliseconds:Int) = select_
?
Public

Type TAdapterInfo
	Field Device    : String
	Field MAC       : Byte[6]
	Field Address   : Int
	Field Broadcast : Int
	Field Netmask   : Int
End Type

Type TNetwork

	Function GetHostIP:Int(HostName:String)
		return 0
	End Function

	Function GetHostIPs:Int[](HostName:String)
		Local IPs:Int[]
		Return IPs
	End Function

	Function GetHostName:String(HostIp:Int)
		return ""
	End Function

	Function StringIP:String(IP:Int)
		return ""
	End Function

	Function StringMAC:String(MAC:Byte[])
		return ""
	End Function

	Function IntIP:Int(IP:String)
		return 0
	End Function

	Function Ping:Int(RemoteIP:Int, Data:Byte Ptr, Size:Int, Sequence:Int = 0, ..
	                  Timeout:Int = 5000)
		Return 0
	End Function

	Function GetAdapterInfo:Int(Info:TAdapterInfo Var)
		Return True
	End Function
End Type

Type TNetStream Extends TStream Abstract
	Field Socket      : Int
	Field RecvBuffer  : Byte Ptr
	Field SendBuffer  : Byte Ptr
	Field RecvSize    : Int
	Field SendSize    : Int

	Method New()
	End Method

	Method Delete()
		Self.Close()
	End Method

	Method Init:Int() Abstract

	Method RecvMsg:Int() Abstract


	Method Read:Long(Buffer:Byte Ptr, Size:Long)
		Return 0
	End Method

	Method SendMsg:Int() Abstract

	Method Write:Long(Buffer:Byte Ptr, Size:Long)
		return 0
	End Method

	Method Eof:Int()
		return 0
	End Method

	Method Size:Long()
		return 0
	End Method

	Method Flush()
	End Method

	Method Close()
	End Method

	Method RecvAvail:Int()
		return 0
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

	Method Init:Int()
		Return True
	End Method

	Method SetLocalPort:Int(Port:Short=0)
		return true
	End Method

	Method GetLocalPort:Short()
		Return Self.LocalPort
	End Method

	Method GetLocalIP:Int()
		Return Self.LocalIP
	End Method

	Method SetRemotePort(Port:Short)
	End Method

	Method GetRemotePort:Short()
		return 0
	End Method

	Method SetRemoteIP(IP:Int)
	End Method

	Method GetRemoteIP:Int()
		return 0
	End Method

	Method SetBroadcast:Int(Enable:Int)
		Return True
	End Method

	Method GetBroadcast:Int()
		Return True
	End Method

	Method GetMsgPort:Short()
		return 0
	End Method

	Method GetMsgIP:Int()
		Return Self.MessageIP
	End Method

	Method SetTimeouts(RecvMillisecs:Int, SendMillisecs:Int)
	End Method

	Method GetRecvTimeout:Int()
		Return Self.RecvTimeout
	End Method

	Method GetSendTimeout:Int()
		Return Self.SendTimeout
	End Method

	Method RecvMsg:Int()
		Return 0
	End Method

	Method SendUDPMsg:Int(IP:Int, Port:Int = 0)
		Return 0
	End Method

	Method SendMsg:Int()
		Return 0
	End Method
End Type

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

	Method Init:Int()
		Return True
	End Method

	Method SetLocalPort:Int(Port:Short=0)
		Return True
	End Method

	Method GetLocalPort:Short()
		Return Self.LocalPort
	End Method

	Method GetLocalIP:Int()
		Return Self.LocalIP
	End Method

	Method SetRemotePort(Port:Short)
		Self.RemotePort = Port
	End Method

	Method GetRemotePort:Short()
		Return Self.RemotePort
	End Method

	Method SetRemoteIP(IP:Int)
		Self.RemoteIP = IP
	End Method

	Method GetRemoteIP:Int()
		Return Self.RemoteIP
	End Method

	Method SetTimeouts(RecvMillisecs:Int, SendMillisecs:Int, AcceptMillisecs:Int=0)
	End Method

	Method GetRecvTimeout:Int()
		Return Self.RecvTimeout
	End Method

	Method GetSendTimeout:Int()
		Return Self.SendTimeout
	End Method

	Method GetAcceptTimeout:Int()
		Return Self.AcceptTimeout
	End Method

	Method Connect:Int()
		Return True
	End Method

	Method Listen:Int(MaxClients:Int=32)
		Return True
	End Method

	Method Accept:TTCPStream()
		Return new TTCPStream
	End Method

	Method RecvMsg:Int()
		Return 0
	End Method

	Method SendMsg:Int()
		Return 0
	End Method

	Method GetState:Int()
		return 0
	End Method
End Type
