superstrict

import brl.gnet

'each client
Type TNetworkConnection
	Field isServer:int					= 0
	Field isConnected:int				= 0
	Field localIP:string				= ""				' my local IP
	Field intLocalIP:int				= 0					' Int of server IP
	Field onlineIP:String				= ""                ' ip for internet - get from inet-lobby (http...)
	Field intOnlineIP:Int				= 0					' int version of ip for internet

'	Global remotePort:Byte				= 4567              ' Port the host uses

	Global ONLINEPORT:Byte				= 4567            	' Port for Online games
	Global LOCALPORT:Byte				= 4567				' Port for LAN games

	field host:TGnetHost

	Method new()
		self.host = CreateGNetHost()
	End Method

	'listen to myself ... if broadcasted i should receive it
	Method ListenToLan:int()
		If Not GNetListen( self.host, self.LOCALPORT ) Notify "ListenToLan: Listen to host failed"
	End Method

	Method AnnounceOnLan:int()

		'method ?

	End Method

End Type
