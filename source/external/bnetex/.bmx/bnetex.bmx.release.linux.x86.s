	format	ELF
	extrn	GetNetworkAdapter
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_stream_stream
	extrn	_brl_stream_TIO_Pos
	extrn	_brl_stream_TIO_Seek
	extrn	_brl_stream_TStream_Delete
	extrn	_brl_stream_TStream_New
	extrn	_brl_stream_TStream_ReadByte
	extrn	_brl_stream_TStream_ReadBytes
	extrn	_brl_stream_TStream_ReadDouble
	extrn	_brl_stream_TStream_ReadFloat
	extrn	_brl_stream_TStream_ReadInt
	extrn	_brl_stream_TStream_ReadLine
	extrn	_brl_stream_TStream_ReadLong
	extrn	_brl_stream_TStream_ReadObject
	extrn	_brl_stream_TStream_ReadShort
	extrn	_brl_stream_TStream_ReadString
	extrn	_brl_stream_TStream_SkipBytes
	extrn	_brl_stream_TStream_WriteByte
	extrn	_brl_stream_TStream_WriteBytes
	extrn	_brl_stream_TStream_WriteDouble
	extrn	_brl_stream_TStream_WriteFloat
	extrn	_brl_stream_TStream_WriteInt
	extrn	_brl_stream_TStream_WriteLine
	extrn	_brl_stream_TStream_WriteLong
	extrn	_brl_stream_TStream_WriteObject
	extrn	_brl_stream_TStream_WriteShort
	extrn	_brl_stream_TStream_WriteString
	extrn	accept_
	extrn	bbArrayNew1D
	extrn	bbEmptyArray
	extrn	bbEmptyString
	extrn	bbFloor
	extrn	bbGCFree
	extrn	bbLongAdd
	extrn	bbLongAnd
	extrn	bbLongNot
	extrn	bbLongShr
	extrn	bbMemAlloc
	extrn	bbMemCopy
	extrn	bbMemFree
	extrn	bbMilliSecs
	extrn	bbNullObject
	extrn	bbObjectClass
	extrn	bbObjectCompare
	extrn	bbObjectCtor
	extrn	bbObjectFree
	extrn	bbObjectNew
	extrn	bbObjectRegisterType
	extrn	bbObjectReserved
	extrn	bbObjectSendMessage
	extrn	bbObjectToString
	extrn	bbStringClass
	extrn	bbStringConcat
	extrn	bbStringFromCString
	extrn	bbStringFromChar
	extrn	bbStringSlice
	extrn	bbStringToCString
	extrn	bind_
	extrn	brl_blitz_NullMethodError
	extrn	brl_stream_TStream
	extrn	closesocket_
	extrn	connect_
	extrn	gethostbyaddr_
	extrn	gethostbyname_
	extrn	getpid
	extrn	getsockname
	extrn	getsockopt_
	extrn	htonl_
	extrn	htons_
	extrn	inet_addr
	extrn	inet_ntoa
	extrn	ioctl
	extrn	listen_
	extrn	ntohl_
	extrn	ntohs_
	extrn	pselect_
	extrn	recv_
	extrn	recvfrom_
	extrn	send_
	extrn	sendto_
	extrn	setsockopt_
	extrn	shutdown_
	extrn	socket_
	public	__bb_bnetex_bnetex
	public	_bb_TAdapterInfo_Delete
	public	_bb_TAdapterInfo_New
	public	_bb_TICMP_BuildChecksum
	public	_bb_TICMP_Delete
	public	_bb_TICMP_New
	public	_bb_TNetStream_Close
	public	_bb_TNetStream_Delete
	public	_bb_TNetStream_Eof
	public	_bb_TNetStream_Flush
	public	_bb_TNetStream_New
	public	_bb_TNetStream_Read
	public	_bb_TNetStream_RecvAvail
	public	_bb_TNetStream_Size
	public	_bb_TNetStream_Write
	public	_bb_TNetwork_Delete
	public	_bb_TNetwork_GetAdapterInfo
	public	_bb_TNetwork_GetHostIP
	public	_bb_TNetwork_GetHostIPs
	public	_bb_TNetwork_GetHostName
	public	_bb_TNetwork_IntIP
	public	_bb_TNetwork_New
	public	_bb_TNetwork_Ping
	public	_bb_TNetwork_StringIP
	public	_bb_TNetwork_StringMAC
	public	_bb_TSockAddr_Delete
	public	_bb_TSockAddr_New
	public	_bb_TTCPStream_Accept
	public	_bb_TTCPStream_Connect
	public	_bb_TTCPStream_Delete
	public	_bb_TTCPStream_GetAcceptTimeout
	public	_bb_TTCPStream_GetLocalIP
	public	_bb_TTCPStream_GetLocalPort
	public	_bb_TTCPStream_GetRecvTimeout
	public	_bb_TTCPStream_GetRemoteIP
	public	_bb_TTCPStream_GetRemotePort
	public	_bb_TTCPStream_GetSendTimeout
	public	_bb_TTCPStream_GetState
	public	_bb_TTCPStream_Init
	public	_bb_TTCPStream_Listen
	public	_bb_TTCPStream_New
	public	_bb_TTCPStream_RecvMsg
	public	_bb_TTCPStream_SendMsg
	public	_bb_TTCPStream_SetLocalPort
	public	_bb_TTCPStream_SetRemoteIP
	public	_bb_TTCPStream_SetRemotePort
	public	_bb_TTCPStream_SetTimeouts
	public	_bb_TUDPStream_Delete
	public	_bb_TUDPStream_GetBroadcast
	public	_bb_TUDPStream_GetLocalIP
	public	_bb_TUDPStream_GetLocalPort
	public	_bb_TUDPStream_GetMsgIP
	public	_bb_TUDPStream_GetMsgPort
	public	_bb_TUDPStream_GetRecvTimeout
	public	_bb_TUDPStream_GetRemoteIP
	public	_bb_TUDPStream_GetRemotePort
	public	_bb_TUDPStream_GetSendTimeout
	public	_bb_TUDPStream_Init
	public	_bb_TUDPStream_New
	public	_bb_TUDPStream_RecvMsg
	public	_bb_TUDPStream_SendMsg
	public	_bb_TUDPStream_SendUDPMsg
	public	_bb_TUDPStream_SetBroadcast
	public	_bb_TUDPStream_SetLocalPort
	public	_bb_TUDPStream_SetRemoteIP
	public	_bb_TUDPStream_SetRemotePort
	public	_bb_TUDPStream_SetTimeouts
	public	bb_TAdapterInfo
	public	bb_TNetStream
	public	bb_TNetwork
	public	bb_TTCPStream
	public	bb_TUDPStream
	section	"code" executable
__bb_bnetex_bnetex:
	push	ebp
	mov	ebp,esp
	cmp	dword [_355],0
	je	_356
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_356:
	mov	dword [_355],1
	call	__bb_blitz_blitz
	call	__bb_stream_stream
	call	__bb_glmax2d_glmax2d
	push	_2
	call	bbObjectRegisterType
	add	esp,4
	push	_3
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TAdapterInfo
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TNetwork
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TNetStream
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TUDPStream
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TTCPStream
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,0
	jmp	_131
_131:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSockAddr_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],_2
	mov	word [ebx+8],0
	mov	word [ebx+10],0
	mov	dword [ebx+12],0
	mov	dword [ebx+16],0
	mov	dword [ebx+20],0
	mov	eax,0
	jmp	_134
_134:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSockAddr_Delete:
	push	ebp
	mov	ebp,esp
_137:
	mov	eax,0
	jmp	_357
_357:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TICMP_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],_3
	mov	byte [ebx+8],0
	mov	byte [ebx+9],0
	mov	word [ebx+10],0
	mov	word [ebx+12],0
	mov	word [ebx+14],0
	mov	eax,0
	jmp	_140
_140:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TICMP_Delete:
	push	ebp
	mov	ebp,esp
_143:
	mov	eax,0
	jmp	_358
_358:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TICMP_BuildChecksum:
	push	ebp
	mov	ebp,esp
	sub	esp,60
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	dword [ebp-8],0
	mov	dword [ebp-4],0
	jmp	_4
_6:
	movzx	eax,word [esi]
	mov	eax,eax
	mov	dword [ebp-20],eax
	mov	dword [ebp-16],0
	push	dword [ebp-16]
	push	dword [ebp-20]
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-8]
	push	eax
	call	bbLongAdd
	add	esp,20
	add	esi,2
	sub	ebx,2
_4:
	cmp	ebx,1
	jg	_6
_5:
	cmp	ebx,0
	je	_360
	movzx	eax,byte [esi]
	mov	eax,eax
	mov	dword [ebp-28],eax
	mov	dword [ebp-24],0
	push	dword [ebp-24]
	push	dword [ebp-28]
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-8]
	push	eax
	call	bbLongAdd
	add	esp,20
_360:
	push	0
	push	16
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-36]
	push	eax
	call	bbLongShr
	add	esp,20
	push	0
	push	65535
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-44]
	push	eax
	call	bbLongAnd
	add	esp,20
	push	dword [ebp-40]
	push	dword [ebp-44]
	push	dword [ebp-32]
	push	dword [ebp-36]
	lea	eax,dword [ebp-8]
	push	eax
	call	bbLongAdd
	add	esp,20
	push	0
	push	16
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-52]
	push	eax
	call	bbLongShr
	add	esp,20
	push	dword [ebp-48]
	push	dword [ebp-52]
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-8]
	push	eax
	call	bbLongAdd
	add	esp,20
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-60]
	push	eax
	call	bbLongNot
	add	esp,12
	push	dword [ebp-60]
	call	htons_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebp-12],ax
	jmp	_147
_147:
	movzx	eax,word [ebp-12]
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAdapterInfo_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TAdapterInfo
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	push	6
	push	_362
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	dword [ebx+16],0
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	eax,0
	jmp	_150
_150:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAdapterInfo_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_153:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_366
	push	eax
	call	bbGCFree
	add	esp,4
_366:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_368
	push	eax
	call	bbGCFree
	add	esp,4
_368:
	mov	eax,0
	jmp	_364
_364:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TNetwork
	mov	eax,0
	jmp	_156
_156:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_Delete:
	push	ebp
	mov	ebp,esp
_159:
	mov	eax,0
	jmp	_369
_369:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_GetHostIP:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	mov	edx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],0
	lea	eax,dword [ebp-8]
	push	eax
	lea	eax,dword [ebp-4]
	push	eax
	push	edx
	call	gethostbyname_
	add	esp,12
	mov	edx,eax
	cmp	edx,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_375
	mov	eax,dword [ebp-4]
	cmp	eax,2
	setne	al
	movzx	eax,al
_375:
	cmp	eax,0
	jne	_377
	mov	eax,dword [ebp-8]
	cmp	eax,4
	setne	al
	movzx	eax,al
_377:
	cmp	eax,0
	je	_379
	mov	eax,0
	jmp	_162
_379:
	cmp	dword [edx],0
	je	_380
	mov	ecx,dword [edx]
	movzx	eax,byte [ecx]
	mov	eax,eax
	shl	eax,24
	movzx	edx,byte [ecx+1]
	mov	edx,edx
	shl	edx,16
	or	eax,edx
	movzx	edx,byte [ecx+2]
	mov	edx,edx
	shl	edx,8
	or	eax,edx
	movzx	edx,byte [ecx+3]
	mov	edx,edx
	or	eax,edx
	jmp	_162
_380:
	mov	eax,0
	jmp	_162
_162:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_GetHostIPs:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	edx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],0
	lea	eax,dword [ebp-8]
	push	eax
	lea	eax,dword [ebp-4]
	push	eax
	push	edx
	call	gethostbyname_
	add	esp,12
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp-12]
	cmp	eax,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_390
	mov	eax,dword [ebp-4]
	cmp	eax,2
	setne	al
	movzx	eax,al
_390:
	cmp	eax,0
	jne	_392
	mov	eax,dword [ebp-8]
	cmp	eax,4
	setne	al
	movzx	eax,al
_392:
	cmp	eax,0
	je	_394
	mov	eax,bbEmptyArray
	jmp	_165
_394:
	mov	ebx,0
	jmp	_7
_9:
	add	ebx,1
_7:
	mov	eax,dword [ebp-12]
	cmp	dword [eax+ebx*4],0
	jne	_9
_8:
	push	ebx
	push	_395
	call	bbArrayNew1D
	add	esp,8
	mov	edx,eax
	mov	eax,0
	mov	edi,ebx
	jmp	_396
_12:
	mov	ecx,dword [ebp-12]
	mov	ecx,dword [ecx+eax*4]
	movzx	ebx,byte [ecx]
	mov	ebx,ebx
	shl	ebx,24
	movzx	esi,byte [ecx+1]
	mov	esi,esi
	shl	esi,16
	or	ebx,esi
	movzx	esi,byte [ecx+2]
	mov	esi,esi
	shl	esi,8
	or	ebx,esi
	movzx	ecx,byte [ecx+3]
	mov	ecx,ecx
	or	ebx,ecx
	mov	dword [edx+eax*4+24],ebx
_10:
	add	eax,1
_396:
	cmp	eax,edi
	jl	_12
_11:
	mov	eax,edx
	jmp	_165
_165:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_GetHostName:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],0
	push	eax
	call	htonl_
	add	esp,4
	mov	dword [ebp-4],eax
	push	2
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	call	gethostbyaddr_
	add	esp,12
	cmp	eax,0
	je	_400
	push	eax
	call	bbStringFromCString
	add	esp,4
	jmp	_168
_400:
	mov	eax,_1
	jmp	_168
_168:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_StringIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	call	htonl_
	add	esp,4
	push	eax
	call	inet_ntoa
	add	esp,4
	push	eax
	call	bbStringFromCString
	add	esp,4
	jmp	_171
_171:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_StringMAC:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,bbEmptyString
	mov	byte [ebp-4],0
	mov	byte [ebp-8],0
	mov	ebx,0
	jmp	_406
_15:
	movzx	eax,byte [edi+ebx+24]
	mov	eax,eax
	and	eax,240
	shr	eax,4
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-4],al
	movzx	eax,byte [edi+ebx+24]
	mov	eax,eax
	and	eax,15
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-8],al
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	cmp	eax,10
	jge	_407
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	add	eax,48
	push	eax
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	esi
	call	bbStringConcat
	add	esp,8
	mov	esi,eax
	jmp	_408
_407:
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	add	eax,55
	push	eax
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	esi
	call	bbStringConcat
	add	esp,8
	mov	esi,eax
_408:
	movzx	eax,byte [ebp-8]
	mov	eax,eax
	cmp	eax,10
	jge	_409
	movzx	eax,byte [ebp-8]
	mov	eax,eax
	add	eax,48
	push	eax
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	esi
	call	bbStringConcat
	add	esp,8
	mov	esi,eax
	jmp	_410
_409:
	movzx	eax,byte [ebp-8]
	mov	eax,eax
	add	eax,55
	push	eax
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	esi
	call	bbStringConcat
	add	esp,8
	mov	esi,eax
_410:
	push	_16
	push	esi
	call	bbStringConcat
	add	esp,8
	mov	esi,eax
_13:
	add	ebx,1
_406:
	cmp	ebx,5
	jle	_15
_14:
	mov	eax,dword [esi+8]
	sub	eax,1
	push	eax
	push	0
	push	esi
	call	bbStringSlice
	add	esp,12
	jmp	_174
_174:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_IntIP:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	push	eax
	call	bbStringToCString
	add	esp,4
	mov	ebx,eax
	push	ebx
	call	inet_addr
	add	esp,4
	mov	esi,eax
	push	ebx
	call	bbMemFree
	add	esp,4
	push	esi
	call	htonl_
	add	esp,4
	jmp	_177
_177:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_Ping:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+12]
	mov	esi,dword [ebp+20]
	mov	dword [ebp-4],bbNullObject
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	push	1
	push	3
	push	2
	call	socket_
	add	esp,12
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],-1
	jne	_424
	mov	eax,-1
	jmp	_184
_424:
	call	getpid
	mov	dword [ebp-24],eax
	push	_3
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	mov	byte [eax+8],8
	mov	eax,dword [ebp-4]
	mov	byte [eax+9],0
	mov	eax,dword [ebp-4]
	mov	word [eax+10],0
	mov	edx,dword [ebp-4]
	mov	eax,dword [ebp-24]
	and	eax,0xffff
	mov	eax,eax
	mov	word [edx+12],ax
	mov	edx,dword [ebp-4]
	mov	eax,esi
	and	eax,0xffff
	mov	eax,eax
	mov	word [edx+14],ax
	push	65536
	call	bbMemAlloc
	add	esp,4
	mov	edi,eax
	push	8
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	push	edi
	call	bbMemCopy
	add	esp,12
	push	dword [ebp+16]
	push	ebx
	mov	eax,edi
	add	eax,8
	push	eax
	call	bbMemCopy
	add	esp,12
	mov	eax,dword [ebp+16]
	add	eax,8
	push	eax
	push	edi
	call	dword [_3+48]
	add	esp,8
	mov	eax,eax
	push	eax
	call	htons_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [edi+2],ax
	mov	eax,dword [ebp-20]
	mov	dword [ebp-8],eax
	push	0
	push	0
	push	0
	lea	eax,dword [ebp-8]
	push	eax
	push	1
	push	0
	push	0
	call	pselect_
	add	esp,28
	cmp	eax,1
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_425
	push	0
	push	dword [ebp+8]
	push	0
	mov	eax,dword [ebp+16]
	add	eax,8
	push	eax
	push	edi
	push	dword [ebp-20]
	call	sendto_
	add	esp,24
	cmp	eax,-1
	sete	al
	movzx	eax,al
_425:
	cmp	eax,0
	je	_427
	push	edi
	call	bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	closesocket_
	add	esp,4
	mov	eax,-1
	jmp	_184
_427:
	call	bbMilliSecs
	mov	dword [ebp-28],eax
_19:
_17:
	mov	eax,dword [ebp-20]
	mov	dword [ebp-8],eax
	push	dword [ebp+24]
	push	0
	push	0
	push	0
	push	0
	lea	eax,dword [ebp-8]
	push	eax
	push	1
	call	pselect_
	add	esp,28
	cmp	eax,1
	je	_428
	push	edi
	call	bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	closesocket_
	add	esp,4
	mov	eax,-1
	jmp	_184
_428:
	lea	eax,dword [ebp-16]
	push	eax
	lea	eax,dword [ebp-12]
	push	eax
	push	0
	push	65536
	push	edi
	push	dword [ebp-20]
	call	recvfrom_
	add	esp,24
	mov	ebx,eax
	call	bbMilliSecs
	mov	esi,eax
	cmp	ebx,-1
	jne	_429
	push	edi
	call	bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	closesocket_
	add	esp,4
	mov	eax,-1
	jmp	_184
_429:
	movzx	eax,byte [edi]
	mov	eax,eax
	and	eax,15
	shl	eax,2
	push	8
	mov	edx,edi
	add	edx,eax
	push	edx
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	bbMemCopy
	add	esp,12
	mov	eax,dword [ebp-4]
	movzx	eax,word [eax+12]
	mov	eax,eax
	cmp	eax,dword [ebp-24]
	je	_430
	jmp	_17
_430:
	mov	eax,dword [ebp-4]
	movzx	eax,byte [eax+8]
	mov	eax,eax
	cmp	eax,3
	jne	_432
	mov	eax,dword [ebp-4]
	movzx	eax,byte [eax+9]
	mov	eax,eax
	cmp	eax,1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_433
	mov	eax,dword [ebp-4]
	movzx	eax,byte [eax+9]
	mov	eax,eax
	cmp	eax,0
	sete	al
	movzx	eax,al
_433:
	cmp	eax,0
	je	_435
	push	edi
	call	bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	closesocket_
	add	esp,4
	mov	eax,-1
	jmp	_184
_435:
	jmp	_436
_432:
	mov	eax,dword [ebp-4]
	movzx	eax,byte [eax+9]
	mov	eax,eax
	cmp	eax,0
	jne	_437
	jmp	_18
_437:
_436:
_431:
	jmp	_19
_18:
	push	edi
	call	bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	closesocket_
	add	esp,4
	mov	eax,esi
	sub	eax,dword [ebp-28]
	jmp	_184
_184:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_GetAdapterInfo:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebx]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_439
	push	bb_TAdapterInfo
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx]
	dec	dword [eax+4]
	jnz	_443
	push	eax
	call	bbGCFree
	add	esp,4
_443:
	mov	dword [ebx],esi
_439:
	push	256
	call	bbMemAlloc
	add	esp,4
	mov	esi,eax
	mov	eax,dword [ebx]
	lea	eax,dword [eax+20]
	push	eax
	mov	eax,dword [ebx]
	lea	eax,dword [eax+24]
	push	eax
	mov	eax,dword [ebx]
	lea	eax,dword [eax+16]
	push	eax
	mov	eax,dword [ebx]
	mov	eax,dword [eax+12]
	lea	eax,byte [eax+24]
	push	eax
	push	esi
	call	GetNetworkAdapter
	add	esp,20
	cmp	eax,0
	jne	_444
	mov	eax,0
	jmp	_187
_444:
	push	esi
	call	bbStringFromCString
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx]
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_448
	push	eax
	call	bbGCFree
	add	esp,4
_448:
	mov	eax,dword [ebx]
	mov	dword [eax+8],esi
	mov	eax,1
	jmp	_187
_187:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_brl_stream_TStream_New
	add	esp,4
	mov	dword [ebx],bb_TNetStream
	mov	dword [ebx+8],0
	mov	dword [ebx+12],0
	mov	dword [ebx+16],0
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	dword [ebx+8],-1
	mov	dword [ebx+12],0
	mov	dword [ebx+16],0
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	eax,0
	jmp	_190
_190:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	cmp	dword [ebx+20],0
	jle	_450
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
_450:
	cmp	dword [ebx+24],0
	jle	_451
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
_451:
_193:
	mov	dword [ebx],brl_stream_TStream
	push	ebx
	call	_brl_stream_TStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_452
_452:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Read:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	edi,dword [ebp+16]
	cmp	edi,dword [esi+20]
	jle	_454
	mov	edi,dword [esi+20]
_454:
	cmp	edi,0
	jle	_455
	push	edi
	push	dword [esi+12]
	push	eax
	call	bbMemCopy
	add	esp,12
	cmp	edi,dword [esi+20]
	jge	_456
	mov	eax,dword [esi+20]
	sub	eax,edi
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [esi+20]
	sub	eax,edi
	push	eax
	mov	eax,dword [esi+12]
	add	eax,edi
	push	eax
	push	ebx
	call	bbMemCopy
	add	esp,12
	push	dword [esi+12]
	call	bbMemFree
	add	esp,4
	mov	dword [esi+12],ebx
	sub	dword [esi+20],edi
	jmp	_457
_456:
	push	dword [esi+12]
	call	bbMemFree
	add	esp,4
	mov	dword [esi+20],0
_457:
_455:
	mov	eax,edi
	jmp	_198
_198:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Write:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+16]
	cmp	edi,0
	jg	_459
	mov	eax,0
	jmp	_203
_459:
	mov	eax,dword [esi+24]
	add	eax,edi
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	ebx,eax
	cmp	dword [esi+24],0
	jle	_460
	push	dword [esi+24]
	push	dword [esi+16]
	push	ebx
	call	bbMemCopy
	add	esp,12
	push	edi
	push	dword [ebp+12]
	mov	eax,ebx
	add	eax,dword [esi+24]
	push	eax
	call	bbMemCopy
	add	esp,12
	push	dword [esi+16]
	call	bbMemFree
	add	esp,4
	mov	dword [esi+16],ebx
	add	dword [esi+24],edi
	jmp	_461
_460:
	push	edi
	push	dword [ebp+12]
	push	ebx
	call	bbMemCopy
	add	esp,12
	mov	dword [esi+16],ebx
	mov	dword [esi+24],edi
_461:
	mov	eax,edi
	jmp	_203
_203:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Eof:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+20]
	cmp	eax,0
	sete	al
	movzx	eax,al
	jmp	_206
_206:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Size:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+20]
	jmp	_209
_209:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Flush:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	cmp	dword [ebx+20],0
	jle	_462
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
_462:
	cmp	dword [ebx+24],0
	jle	_463
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
_463:
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	eax,0
	jmp	_212
_212:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Close:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	cmp	dword [ebx+8],-1
	je	_464
	push	2
	push	dword [ebx+8]
	call	shutdown_
	add	esp,8
	push	dword [ebx+8]
	call	closesocket_
	add	esp,4
	mov	dword [ebx+8],-1
_464:
	mov	eax,0
	jmp	_215
_215:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_RecvAvail:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	edx,dword [ebp+8]
	mov	dword [ebp-4],0
	cmp	dword [edx+8],-1
	jne	_466
	mov	eax,-1
	jmp	_218
_466:
	lea	eax,dword [ebp-4]
	push	eax
	push	21531
	push	dword [edx+8]
	call	ioctl
	add	esp,12
	cmp	eax,-1
	jne	_467
	mov	eax,-1
	jmp	_218
_467:
	mov	eax,dword [ebp-4]
	jmp	_218
_218:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_TNetStream_New
	add	esp,4
	mov	dword [ebx],bb_TUDPStream
	mov	dword [ebx+28],0
	mov	word [ebx+32],0
	mov	word [ebx+34],0
	mov	dword [ebx+36],0
	mov	dword [ebx+40],0
	mov	word [ebx+44],0
	mov	dword [ebx+48],0
	mov	dword [ebx+52],0
	fldz
	fstp	dword [ebx+56]
	fldz
	fstp	dword [ebx+60]
	fldz
	fstp	dword [ebx+64]
	fldz
	fstp	dword [ebx+68]
	fldz
	fstp	dword [ebx+72]
	mov	word [ebx+32],0
	mov	dword [ebx+28],0
	mov	word [ebx+34],0
	mov	dword [ebx+36],0
	mov	dword [ebx+40],0
	mov	word [ebx+44],0
	mov	dword [ebx+48],0
	mov	dword [ebx+52],0
	mov	eax,0
	jmp	_221
_221:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_224:
	mov	dword [eax],bb_TNetStream
	push	eax
	call	_bb_TNetStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_469
_469:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_Init:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	push	0
	push	2
	push	2
	call	socket_
	add	esp,12
	mov	dword [ebx+8],eax
	cmp	dword [ebx+8],-1
	jne	_471
	mov	eax,0
	jmp	_227
_471:
	mov	dword [ebp-4],65527
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	8
	push	1
	push	dword [ebx+8]
	call	setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_472
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	7
	push	1
	push	dword [ebx+8]
	call	setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
_472:
	cmp	eax,0
	je	_474
	push	dword [ebx+8]
	call	closesocket_
	add	esp,4
	mov	eax,0
	jmp	_227
_474:
	mov	eax,1
	jmp	_227
_227:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	ebx,dword [ebp+8]
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	mov	dword [ebp-8],bbNullObject
	mov	dword [ebp-12],0
	cmp	dword [ebx+8],-1
	jne	_477
	mov	eax,0
	jmp	_231
_477:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	push	eax
	push	2
	push	dword [ebx+8]
	call	bind_
	add	esp,12
	cmp	eax,-1
	jne	_478
	mov	eax,0
	jmp	_231
_478:
	push	_2
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],16
	lea	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	getsockname
	add	esp,12
	cmp	eax,-1
	jne	_480
	mov	eax,0
	jmp	_231
_480:
	mov	eax,dword [ebp-8]
	push	dword [eax+12]
	call	ntohl_
	add	esp,4
	mov	dword [ebx+28],eax
	mov	eax,dword [ebp-8]
	movzx	eax,word [eax+10]
	mov	eax,eax
	push	eax
	call	ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+32],ax
	mov	eax,1
	jmp	_231
_231:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	movzx	eax,word [eax+32]
	mov	eax,eax
	mov	word [ebp-4],ax
	jmp	_234
_234:
	movzx	eax,word [ebp-4]
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetLocalIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	jmp	_237
_237:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SetRemotePort:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	edx,dword [ebp+8]
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	movzx	eax,word [ebp-4]
	mov	eax,eax
	mov	word [edx+34],ax
	mov	eax,0
	jmp	_241
_241:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetRemotePort:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	movzx	eax,word [eax+34]
	mov	eax,eax
	mov	word [ebp-4],ax
	jmp	_244
_244:
	movzx	eax,word [ebp-4]
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SetRemoteIP:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	dword [edx+36],eax
	mov	eax,0
	jmp	_248
_248:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetRemoteIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+36]
	jmp	_251
_251:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SetBroadcast:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	dword [ebp-4],eax
	cmp	dword [edx+8],-1
	jne	_482
	mov	eax,0
	jmp	_255
_482:
	cmp	dword [ebp-4],0
	je	_483
	mov	dword [ebp-4],1
_483:
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	6
	push	1
	push	dword [edx+8]
	call	setsockopt_
	add	esp,20
	cmp	eax,-1
	jne	_484
	mov	eax,0
	jmp	_255
_484:
	mov	eax,1
	jmp	_255
_255:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetBroadcast:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	mov	edx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],0
	cmp	dword [edx+8],-1
	jne	_487
	mov	eax,0
	jmp	_258
_487:
	mov	dword [ebp-8],4
	lea	eax,dword [ebp-8]
	push	eax
	lea	eax,dword [ebp-4]
	push	eax
	push	6
	push	1
	push	dword [edx+8]
	call	getsockopt_
	add	esp,20
	cmp	eax,-1
	jne	_488
	mov	eax,-1
	jmp	_258
_488:
	mov	eax,dword [ebp-4]
	jmp	_258
_258:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetMsgPort:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	movzx	eax,word [eax+44]
	mov	eax,eax
	mov	word [ebp-4],ax
	jmp	_261
_261:
	movzx	eax,word [ebp-4]
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetMsgIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+40]
	jmp	_264
_264:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SetTimeouts:
	push	ebp
	mov	ebp,esp
	mov	ecx,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [ebp+16]
	mov	dword [ecx+48],edx
	mov	dword [ecx+52],eax
	mov	eax,0
	jmp	_269
_269:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetRecvTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+48]
	jmp	_272
_272:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetSendTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	jmp	_275
_275:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_RecvMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	cmp	dword [esi+8],-1
	jne	_495
	mov	edx,0
	jmp	_278
_495:
	mov	eax,dword [esi+8]
	mov	dword [ebp-4],eax
	push	dword [esi+48]
	push	0
	push	0
	push	0
	push	0
	lea	eax,dword [ebp-4]
	push	eax
	push	1
	call	pselect_
	add	esp,28
	cmp	eax,1
	je	_496
	mov	edx,0
	jmp	_278
_496:
	lea	eax,dword [ebp-8]
	push	eax
	push	21531
	push	dword [esi+8]
	call	ioctl
	add	esp,12
	cmp	eax,-1
	jne	_497
	mov	edx,0
	jmp	_278
_497:
	cmp	dword [ebp-8],0
	jg	_498
	mov	edx,0
	jmp	_278
_498:
	cmp	dword [esi+20],0
	jle	_499
	mov	eax,dword [esi+20]
	add	eax,dword [ebp-8]
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	ebx,eax
	push	dword [esi+20]
	push	dword [esi+12]
	push	ebx
	call	bbMemCopy
	add	esp,12
	push	dword [esi+12]
	call	bbMemFree
	add	esp,4
	mov	dword [esi+12],ebx
	mov	ebx,1000
	call	bbMilliSecs
	cdq
	idiv	ebx
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloor
	add	esp,8
	fld	dword [esi+72]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setz	al
	movzx	eax,al
	cmp	eax,0
	jne	_500
	fld	dword [esi+60]
	fadd	dword [esi+64]
	fstp	dword [esi+68]
	mov	ebx,1000
	call	bbMilliSecs
	cdq
	idiv	ebx
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloor
	add	esp,8
	fstp	dword [esi+72]
	fldz
	fstp	dword [esi+60]
	fldz
	fstp	dword [esi+64]
_500:
	fld	dword [esi+60]
	mov	eax,dword [esi+20]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	faddp	st1,st0
	fstp	dword [esi+60]
	jmp	_501
_499:
	push	dword [ebp-8]
	call	bbMemAlloc
	add	esp,4
	mov	dword [esi+12],eax
_501:
	lea	eax,dword [ebp-16]
	push	eax
	lea	eax,dword [ebp-12]
	push	eax
	push	0
	push	dword [ebp-8]
	mov	eax,dword [esi+12]
	add	eax,dword [esi+20]
	push	eax
	push	dword [esi+8]
	call	recvfrom_
	add	esp,24
	mov	edx,eax
	cmp	edx,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_502
	cmp	edx,0
	sete	al
	movzx	eax,al
_502:
	cmp	eax,0
	je	_504
	mov	edx,0
	jmp	_278
_504:
	mov	eax,dword [ebp-12]
	mov	dword [esi+40],eax
	mov	eax,dword [ebp-16]
	and	eax,0xffff
	mov	eax,eax
	mov	word [esi+44],ax
	add	dword [esi+20],edx
	jmp	_278
_278:
	mov	eax,edx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SendUDPMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	edi,dword [ebp+16]
	mov	eax,dword [esi+36]
	mov	dword [ebp-8],eax
	movzx	eax,word [esi+34]
	mov	eax,eax
	mov	word [ebp-4],ax
	mov	eax,esi
	push	1
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+208]
	add	esp,8
	mov	dword [esi+36],ebx
	mov	eax,edi
	and	eax,0xffff
	mov	eax,eax
	mov	word [esi+34],ax
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+172]
	add	esp,4
	mov	edx,eax
	mov	eax,dword [ebp-8]
	mov	dword [esi+36],eax
	movzx	eax,word [ebp-4]
	mov	eax,eax
	mov	word [esi+34],ax
	jmp	_283
_283:
	mov	eax,edx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SendMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	eax,dword [ebx+8]
	cmp	eax,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_514
	mov	eax,dword [ebx+24]
	cmp	eax,0
	sete	al
	movzx	eax,al
_514:
	cmp	eax,0
	je	_516
	mov	eax,0
	jmp	_286
_516:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-4],eax
	push	0
	push	0
	push	0
	lea	eax,dword [ebp-4]
	push	eax
	push	1
	push	0
	push	0
	call	pselect_
	add	esp,28
	cmp	eax,1
	je	_517
	mov	eax,0
	jmp	_286
_517:
	movzx	eax,word [ebx+34]
	mov	eax,eax
	push	eax
	push	dword [ebx+36]
	push	0
	push	dword [ebx+24]
	push	dword [ebx+16]
	push	dword [ebx+8]
	call	sendto_
	add	esp,24
	mov	edi,eax
	cmp	edi,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_518
	cmp	edi,0
	sete	al
	movzx	eax,al
_518:
	cmp	eax,0
	je	_520
	mov	eax,0
	jmp	_286
_520:
	cmp	edi,dword [ebx+24]
	jne	_522
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
	mov	dword [ebx+24],0
	jmp	_523
_522:
	mov	eax,dword [ebx+24]
	sub	eax,edi
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	esi,eax
	mov	eax,dword [ebx+24]
	sub	eax,edi
	push	eax
	mov	eax,dword [ebx+16]
	add	eax,edi
	push	eax
	push	esi
	call	bbMemCopy
	add	esp,12
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
	mov	dword [ebx+16],esi
	sub	dword [ebx+24],edi
	mov	esi,1000
	call	bbMilliSecs
	cdq
	idiv	esi
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloor
	add	esp,8
	fld	dword [ebx+72]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setz	al
	movzx	eax,al
	cmp	eax,0
	jne	_524
	fld	dword [ebx+60]
	fadd	dword [ebx+64]
	fstp	dword [ebx+68]
	mov	esi,1000
	call	bbMilliSecs
	cdq
	idiv	esi
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloor
	add	esp,8
	fstp	dword [ebx+72]
	fldz
	fstp	dword [ebx+60]
	fldz
	fstp	dword [ebx+64]
_524:
	fld	dword [ebx+64]
	mov	eax,dword [ebx+24]
	sub	eax,edi
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	faddp	st1,st0
	fstp	dword [ebx+64]
_523:
	mov	eax,edi
	jmp	_286
_286:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_TNetStream_New
	add	esp,4
	mov	dword [ebx],bb_TTCPStream
	mov	dword [ebx+28],0
	mov	word [ebx+32],0
	mov	dword [ebx+36],0
	mov	word [ebx+40],0
	mov	dword [ebx+44],0
	mov	dword [ebx+48],0
	mov	dword [ebx+52],0
	mov	dword [ebx+28],0
	mov	word [ebx+32],0
	mov	dword [ebx+36],0
	mov	word [ebx+40],0
	mov	dword [ebx+44],0
	mov	dword [ebx+48],0
	mov	dword [ebx+52],0
	mov	eax,0
	jmp	_289
_289:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_292:
	mov	dword [eax],bb_TNetStream
	push	eax
	call	_bb_TNetStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_525
_525:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Init:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	push	0
	push	1
	push	2
	call	socket_
	add	esp,12
	mov	dword [ebx+8],eax
	cmp	dword [ebx+8],-1
	jne	_527
	mov	eax,0
	jmp	_295
_527:
	mov	dword [ebp-4],65535
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	8
	push	1
	push	dword [ebx+8]
	call	setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_528
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	7
	push	1
	push	dword [ebx+8]
	call	setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
_528:
	cmp	eax,0
	je	_530
	push	dword [ebx+8]
	call	closesocket_
	add	esp,4
	mov	eax,0
	jmp	_295
_530:
	mov	eax,1
	jmp	_295
_295:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	ebx,dword [ebp+8]
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	mov	dword [ebp-8],bbNullObject
	mov	dword [ebp-12],0
	cmp	dword [ebx+8],-1
	jne	_533
	mov	eax,0
	jmp	_299
_533:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	push	eax
	push	2
	push	dword [ebx+8]
	call	bind_
	add	esp,12
	cmp	eax,-1
	jne	_534
	mov	eax,0
	jmp	_299
_534:
	push	_2
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],16
	lea	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	getsockname
	add	esp,12
	cmp	eax,-1
	jne	_536
	mov	eax,0
	jmp	_299
_536:
	mov	eax,dword [ebp-8]
	push	dword [eax+12]
	call	ntohl_
	add	esp,4
	mov	dword [ebx+28],eax
	mov	eax,dword [ebp-8]
	movzx	eax,word [eax+10]
	mov	eax,eax
	push	eax
	call	ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+32],ax
	mov	eax,1
	jmp	_299
_299:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	movzx	eax,word [eax+32]
	mov	eax,eax
	mov	word [ebp-4],ax
	jmp	_302
_302:
	movzx	eax,word [ebp-4]
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetLocalIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	jmp	_305
_305:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SetRemotePort:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	edx,dword [ebp+8]
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	movzx	eax,word [ebp-4]
	mov	eax,eax
	mov	word [edx+40],ax
	mov	eax,0
	jmp	_309
_309:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetRemotePort:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	movzx	eax,word [eax+40]
	mov	eax,eax
	mov	word [ebp-4],ax
	jmp	_312
_312:
	movzx	eax,word [ebp-4]
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SetRemoteIP:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	dword [edx+36],eax
	mov	eax,0
	jmp	_316
_316:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetRemoteIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+36]
	jmp	_319
_319:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SetTimeouts:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	ecx,dword [ebp+12]
	mov	edx,dword [ebp+16]
	mov	eax,dword [ebp+20]
	mov	dword [ebx+44],ecx
	mov	dword [ebx+48],edx
	mov	dword [ebx+52],eax
	mov	eax,0
	jmp	_325
_325:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetRecvTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+44]
	jmp	_328
_328:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetSendTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+48]
	jmp	_331
_331:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetAcceptTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	jmp	_334
_334:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Connect:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	cmp	dword [ebx+8],-1
	jne	_539
	mov	eax,0
	jmp	_337
_539:
	push	dword [ebx+36]
	call	htonl_
	add	esp,4
	mov	dword [ebp-4],eax
	movzx	eax,word [ebx+40]
	mov	eax,eax
	push	eax
	push	4
	push	2
	lea	eax,dword [ebp-4]
	push	eax
	push	dword [ebx+8]
	call	connect_
	add	esp,20
	cmp	eax,-1
	jne	_540
	mov	eax,0
	jmp	_337
_540:
	mov	eax,1
	jmp	_337
_337:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Listen:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	cmp	dword [edx+8],-1
	jne	_542
	mov	eax,0
	jmp	_341
_542:
	push	eax
	push	dword [edx+8]
	call	listen_
	add	esp,8
	cmp	eax,-1
	jne	_543
	mov	eax,0
	jmp	_341
_543:
	mov	eax,1
	jmp	_341
_341:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Accept:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],bbNullObject
	mov	dword [ebp-12],0
	cmp	dword [ebx+8],-1
	jne	_550
	mov	ebx,bbNullObject
	jmp	_344
_550:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-4],eax
	push	dword [ebx+52]
	push	0
	push	0
	push	0
	push	0
	lea	eax,dword [ebp-4]
	push	eax
	push	1
	call	pselect_
	add	esp,28
	cmp	eax,1
	je	_551
	mov	ebx,bbNullObject
	jmp	_344
_551:
	push	_2
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],16
	lea	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	accept_
	add	esp,12
	mov	esi,eax
	cmp	esi,-1
	jne	_552
	mov	ebx,bbNullObject
	jmp	_344
_552:
	push	bb_TTCPStream
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	dword [ebx+8],esi
	mov	eax,dword [ebp-8]
	push	dword [eax+12]
	call	ntohl_
	add	esp,4
	mov	dword [ebx+28],eax
	mov	eax,dword [ebp-8]
	movzx	eax,word [eax+10]
	mov	eax,eax
	push	eax
	call	ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+32],ax
	mov	dword [ebp-12],16
	lea	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	getsockname
	add	esp,12
	cmp	eax,-1
	jne	_553
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	ebx,bbNullObject
	jmp	_344
_553:
	mov	eax,dword [ebp-8]
	push	dword [eax+12]
	call	ntohl_
	add	esp,4
	mov	dword [ebx+36],eax
	mov	eax,dword [ebp-8]
	movzx	eax,word [eax+10]
	mov	eax,eax
	push	eax
	call	ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+40],ax
	jmp	_344
_344:
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_RecvMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],0
	cmp	dword [ebx+8],-1
	jne	_559
	mov	eax,0
	jmp	_347
_559:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-4],eax
	push	dword [ebx+44]
	push	0
	push	0
	push	0
	push	0
	lea	eax,dword [ebp-4]
	push	eax
	push	1
	call	pselect_
	add	esp,28
	cmp	eax,1
	je	_560
	mov	eax,0
	jmp	_347
_560:
	lea	eax,dword [ebp-8]
	push	eax
	push	21531
	push	dword [ebx+8]
	call	ioctl
	add	esp,12
	cmp	eax,-1
	jne	_561
	mov	eax,0
	jmp	_347
_561:
	cmp	dword [ebp-8],0
	jg	_562
	mov	eax,0
	jmp	_347
_562:
	cmp	dword [ebx+20],0
	jle	_563
	mov	eax,dword [ebx+20]
	add	eax,dword [ebp-8]
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	esi,eax
	push	dword [ebx+20]
	push	dword [ebx+12]
	push	esi
	call	bbMemCopy
	add	esp,12
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
	mov	dword [ebx+12],esi
	jmp	_564
_563:
	push	dword [ebp-8]
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebx+12],eax
_564:
	push	0
	push	dword [ebp-8]
	mov	eax,dword [ebx+12]
	add	eax,dword [ebx+20]
	push	eax
	push	dword [ebx+8]
	call	recv_
	add	esp,16
	cmp	eax,-1
	jne	_565
	mov	eax,0
	jmp	_347
_565:
	add	dword [ebx+20],eax
	jmp	_347
_347:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SendMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	dword [ebp-4],0
	cmp	dword [esi+8],-1
	jne	_570
	mov	eax,0
	jmp	_350
_570:
	cmp	dword [esi+24],0
	jge	_571
	mov	eax,0
	jmp	_350
_571:
	mov	eax,dword [esi+8]
	mov	dword [ebp-4],eax
	push	dword [esi+48]
	push	0
	push	0
	lea	eax,dword [ebp-4]
	push	eax
	push	1
	push	0
	push	0
	call	pselect_
	add	esp,28
	cmp	eax,1
	je	_572
	mov	eax,0
	jmp	_350
_572:
	push	0
	push	dword [esi+24]
	push	dword [esi+16]
	push	dword [esi+8]
	call	send_
	add	esp,16
	mov	edi,eax
	cmp	edi,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_573
	cmp	edi,0
	sete	al
	movzx	eax,al
_573:
	cmp	eax,0
	je	_575
	mov	eax,0
	jmp	_350
_575:
	cmp	edi,dword [esi+24]
	jne	_577
	push	dword [esi+16]
	call	bbMemFree
	add	esp,4
	mov	dword [esi+24],0
	jmp	_578
_577:
	mov	eax,dword [esi+24]
	sub	eax,edi
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [esi+24]
	sub	eax,edi
	push	eax
	mov	eax,dword [esi+16]
	add	eax,edi
	push	eax
	push	ebx
	call	bbMemCopy
	add	esp,12
	push	dword [esi+16]
	call	bbMemFree
	add	esp,4
	mov	dword [esi+16],ebx
	sub	dword [esi+24],edi
_578:
	mov	eax,edi
	jmp	_350
_350:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetState:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	cmp	dword [ebx+8],-1
	jne	_582
	mov	eax,-1
	jmp	_353
_582:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-4],eax
	push	0
	push	0
	push	0
	push	0
	push	0
	lea	eax,dword [ebp-4]
	push	eax
	push	1
	call	pselect_
	add	esp,28
	cmp	eax,-1
	jne	_583
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,-1
	jmp	_353
_583:
	cmp	eax,1
	jne	_586
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+176]
	add	esp,4
	cmp	eax,-1
	jne	_588
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,-1
	jmp	_353
_588:
	cmp	eax,0
	jne	_591
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,0
	jmp	_353
_591:
	mov	eax,1
	jmp	_353
_586:
	mov	eax,1
	jmp	_353
_353:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_355:
	dd	0
_21:
	db	"TSockAddr",0
_22:
	db	"SinFamily",0
_23:
	db	"s",0
_24:
	db	"SinPort",0
_25:
	db	"SinAddr",0
_26:
	db	"i",0
_27:
	db	"SinZero",0
_28:
	db	"l",0
_29:
	db	"New",0
_30:
	db	"()i",0
_31:
	db	"Delete",0
	align	4
_20:
	dd	2
	dd	_21
	dd	3
	dd	_22
	dd	_23
	dd	8
	dd	3
	dd	_24
	dd	_23
	dd	10
	dd	3
	dd	_25
	dd	_26
	dd	12
	dd	3
	dd	_27
	dd	_28
	dd	16
	dd	6
	dd	_29
	dd	_30
	dd	16
	dd	6
	dd	_31
	dd	_30
	dd	20
	dd	0
	align	4
_2:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_20
	dd	24
	dd	_bb_TSockAddr_New
	dd	_bb_TSockAddr_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
_33:
	db	"TICMP",0
_34:
	db	"_Type",0
_35:
	db	"b",0
_36:
	db	"Code",0
_37:
	db	"Checksum",0
_38:
	db	"ID",0
_39:
	db	"Sequence",0
_40:
	db	"BuildChecksum",0
_41:
	db	"(*s,i)s",0
	align	4
_32:
	dd	2
	dd	_33
	dd	3
	dd	_34
	dd	_35
	dd	8
	dd	3
	dd	_36
	dd	_35
	dd	9
	dd	3
	dd	_37
	dd	_23
	dd	10
	dd	3
	dd	_38
	dd	_23
	dd	12
	dd	3
	dd	_39
	dd	_23
	dd	14
	dd	6
	dd	_29
	dd	_30
	dd	16
	dd	6
	dd	_31
	dd	_30
	dd	20
	dd	7
	dd	_40
	dd	_41
	dd	48
	dd	0
	align	4
_3:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_32
	dd	16
	dd	_bb_TICMP_New
	dd	_bb_TICMP_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TICMP_BuildChecksum
_43:
	db	"TAdapterInfo",0
_44:
	db	"Device",0
_45:
	db	"$",0
_46:
	db	"MAC",0
_47:
	db	"[]b",0
_48:
	db	"Address",0
_49:
	db	"Broadcast",0
_50:
	db	"Netmask",0
	align	4
_42:
	dd	2
	dd	_43
	dd	3
	dd	_44
	dd	_45
	dd	8
	dd	3
	dd	_46
	dd	_47
	dd	12
	dd	3
	dd	_48
	dd	_26
	dd	16
	dd	3
	dd	_49
	dd	_26
	dd	20
	dd	3
	dd	_50
	dd	_26
	dd	24
	dd	6
	dd	_29
	dd	_30
	dd	16
	dd	6
	dd	_31
	dd	_30
	dd	20
	dd	0
	align	4
bb_TAdapterInfo:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_42
	dd	28
	dd	_bb_TAdapterInfo_New
	dd	_bb_TAdapterInfo_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
_52:
	db	"TNetwork",0
_53:
	db	"GetHostIP",0
_54:
	db	"($)i",0
_55:
	db	"GetHostIPs",0
_56:
	db	"($)[]i",0
_57:
	db	"GetHostName",0
_58:
	db	"(i)$",0
_59:
	db	"StringIP",0
_60:
	db	"StringMAC",0
_61:
	db	"([]b)$",0
_62:
	db	"IntIP",0
_63:
	db	"Ping",0
_64:
	db	"(i,*b,i,i,i)i",0
_65:
	db	"GetAdapterInfo",0
_66:
	db	"(*:TAdapterInfo)i",0
	align	4
_51:
	dd	2
	dd	_52
	dd	6
	dd	_29
	dd	_30
	dd	16
	dd	6
	dd	_31
	dd	_30
	dd	20
	dd	7
	dd	_53
	dd	_54
	dd	48
	dd	7
	dd	_55
	dd	_56
	dd	52
	dd	7
	dd	_57
	dd	_58
	dd	56
	dd	7
	dd	_59
	dd	_58
	dd	60
	dd	7
	dd	_60
	dd	_61
	dd	64
	dd	7
	dd	_62
	dd	_54
	dd	68
	dd	7
	dd	_63
	dd	_64
	dd	72
	dd	7
	dd	_65
	dd	_66
	dd	76
	dd	0
	align	4
bb_TNetwork:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_51
	dd	8
	dd	_bb_TNetwork_New
	dd	_bb_TNetwork_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TNetwork_GetHostIP
	dd	_bb_TNetwork_GetHostIPs
	dd	_bb_TNetwork_GetHostName
	dd	_bb_TNetwork_StringIP
	dd	_bb_TNetwork_StringMAC
	dd	_bb_TNetwork_IntIP
	dd	_bb_TNetwork_Ping
	dd	_bb_TNetwork_GetAdapterInfo
_68:
	db	"TNetStream",0
_69:
	db	"Socket",0
_70:
	db	"RecvBuffer",0
_71:
	db	"*b",0
_72:
	db	"SendBuffer",0
_73:
	db	"RecvSize",0
_74:
	db	"SendSize",0
_75:
	db	"Init",0
_76:
	db	"RecvMsg",0
_77:
	db	"Read",0
_78:
	db	"(*b,i)i",0
_79:
	db	"SendMsg",0
_80:
	db	"Write",0
_81:
	db	"Eof",0
_82:
	db	"Size",0
_83:
	db	"Flush",0
_84:
	db	"Close",0
_85:
	db	"RecvAvail",0
	align	4
_67:
	dd	2
	dd	_68
	dd	3
	dd	_69
	dd	_26
	dd	8
	dd	3
	dd	_70
	dd	_71
	dd	12
	dd	3
	dd	_72
	dd	_71
	dd	16
	dd	3
	dd	_73
	dd	_26
	dd	20
	dd	3
	dd	_74
	dd	_26
	dd	24
	dd	6
	dd	_29
	dd	_30
	dd	16
	dd	6
	dd	_31
	dd	_30
	dd	20
	dd	6
	dd	_75
	dd	_30
	dd	164
	dd	6
	dd	_76
	dd	_30
	dd	168
	dd	6
	dd	_77
	dd	_78
	dd	72
	dd	6
	dd	_79
	dd	_30
	dd	172
	dd	6
	dd	_80
	dd	_78
	dd	76
	dd	6
	dd	_81
	dd	_30
	dd	48
	dd	6
	dd	_82
	dd	_30
	dd	56
	dd	6
	dd	_83
	dd	_30
	dd	64
	dd	6
	dd	_84
	dd	_30
	dd	68
	dd	6
	dd	_85
	dd	_30
	dd	176
	dd	0
	align	4
bb_TNetStream:
	dd	brl_stream_TStream
	dd	bbObjectFree
	dd	_67
	dd	28
	dd	_bb_TNetStream_New
	dd	_bb_TNetStream_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TNetStream_Eof
	dd	_brl_stream_TIO_Pos
	dd	_bb_TNetStream_Size
	dd	_brl_stream_TIO_Seek
	dd	_bb_TNetStream_Flush
	dd	_bb_TNetStream_Close
	dd	_bb_TNetStream_Read
	dd	_bb_TNetStream_Write
	dd	_brl_stream_TStream_ReadBytes
	dd	_brl_stream_TStream_WriteBytes
	dd	_brl_stream_TStream_SkipBytes
	dd	_brl_stream_TStream_ReadByte
	dd	_brl_stream_TStream_WriteByte
	dd	_brl_stream_TStream_ReadShort
	dd	_brl_stream_TStream_WriteShort
	dd	_brl_stream_TStream_ReadInt
	dd	_brl_stream_TStream_WriteInt
	dd	_brl_stream_TStream_ReadLong
	dd	_brl_stream_TStream_WriteLong
	dd	_brl_stream_TStream_ReadFloat
	dd	_brl_stream_TStream_WriteFloat
	dd	_brl_stream_TStream_ReadDouble
	dd	_brl_stream_TStream_WriteDouble
	dd	_brl_stream_TStream_ReadLine
	dd	_brl_stream_TStream_WriteLine
	dd	_brl_stream_TStream_ReadString
	dd	_brl_stream_TStream_WriteString
	dd	_brl_stream_TStream_ReadObject
	dd	_brl_stream_TStream_WriteObject
	dd	brl_blitz_NullMethodError
	dd	brl_blitz_NullMethodError
	dd	brl_blitz_NullMethodError
	dd	_bb_TNetStream_RecvAvail
_87:
	db	"TUDPStream",0
_88:
	db	"LocalIP",0
_89:
	db	"LocalPort",0
_90:
	db	"RemotePort",0
_91:
	db	"RemoteIP",0
_92:
	db	"MessageIP",0
_93:
	db	"MessagePort",0
_94:
	db	"RecvTimeout",0
_95:
	db	"SendTimeout",0
_96:
	db	"fSpeed",0
_97:
	db	"f",0
_98:
	db	"fDataGot",0
_99:
	db	"fDataSent",0
_100:
	db	"fDataSum",0
_101:
	db	"fLastSecond",0
_102:
	db	"SetLocalPort",0
_103:
	db	"(s)i",0
_104:
	db	"GetLocalPort",0
_105:
	db	"()s",0
_106:
	db	"GetLocalIP",0
_107:
	db	"SetRemotePort",0
_108:
	db	"GetRemotePort",0
_109:
	db	"SetRemoteIP",0
_110:
	db	"(i)i",0
_111:
	db	"GetRemoteIP",0
_112:
	db	"SetBroadcast",0
_113:
	db	"GetBroadcast",0
_114:
	db	"GetMsgPort",0
_115:
	db	"GetMsgIP",0
_116:
	db	"SetTimeouts",0
_117:
	db	"(i,i)i",0
_118:
	db	"GetRecvTimeout",0
_119:
	db	"GetSendTimeout",0
_120:
	db	"SendUDPMsg",0
	align	4
_86:
	dd	2
	dd	_87
	dd	3
	dd	_88
	dd	_26
	dd	28
	dd	3
	dd	_89
	dd	_23
	dd	32
	dd	3
	dd	_90
	dd	_23
	dd	34
	dd	3
	dd	_91
	dd	_26
	dd	36
	dd	3
	dd	_92
	dd	_26
	dd	40
	dd	3
	dd	_93
	dd	_23
	dd	44
	dd	3
	dd	_94
	dd	_26
	dd	48
	dd	3
	dd	_95
	dd	_26
	dd	52
	dd	3
	dd	_96
	dd	_97
	dd	56
	dd	3
	dd	_98
	dd	_97
	dd	60
	dd	3
	dd	_99
	dd	_97
	dd	64
	dd	3
	dd	_100
	dd	_97
	dd	68
	dd	3
	dd	_101
	dd	_97
	dd	72
	dd	6
	dd	_29
	dd	_30
	dd	16
	dd	6
	dd	_31
	dd	_30
	dd	20
	dd	6
	dd	_75
	dd	_30
	dd	164
	dd	6
	dd	_102
	dd	_103
	dd	180
	dd	6
	dd	_104
	dd	_105
	dd	184
	dd	6
	dd	_106
	dd	_30
	dd	188
	dd	6
	dd	_107
	dd	_103
	dd	192
	dd	6
	dd	_108
	dd	_105
	dd	196
	dd	6
	dd	_109
	dd	_110
	dd	200
	dd	6
	dd	_111
	dd	_30
	dd	204
	dd	6
	dd	_112
	dd	_110
	dd	208
	dd	6
	dd	_113
	dd	_30
	dd	212
	dd	6
	dd	_114
	dd	_105
	dd	216
	dd	6
	dd	_115
	dd	_30
	dd	220
	dd	6
	dd	_116
	dd	_117
	dd	224
	dd	6
	dd	_118
	dd	_30
	dd	228
	dd	6
	dd	_119
	dd	_30
	dd	232
	dd	6
	dd	_76
	dd	_30
	dd	168
	dd	6
	dd	_120
	dd	_117
	dd	236
	dd	6
	dd	_79
	dd	_30
	dd	172
	dd	0
	align	4
bb_TUDPStream:
	dd	bb_TNetStream
	dd	bbObjectFree
	dd	_86
	dd	76
	dd	_bb_TUDPStream_New
	dd	_bb_TUDPStream_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TNetStream_Eof
	dd	_brl_stream_TIO_Pos
	dd	_bb_TNetStream_Size
	dd	_brl_stream_TIO_Seek
	dd	_bb_TNetStream_Flush
	dd	_bb_TNetStream_Close
	dd	_bb_TNetStream_Read
	dd	_bb_TNetStream_Write
	dd	_brl_stream_TStream_ReadBytes
	dd	_brl_stream_TStream_WriteBytes
	dd	_brl_stream_TStream_SkipBytes
	dd	_brl_stream_TStream_ReadByte
	dd	_brl_stream_TStream_WriteByte
	dd	_brl_stream_TStream_ReadShort
	dd	_brl_stream_TStream_WriteShort
	dd	_brl_stream_TStream_ReadInt
	dd	_brl_stream_TStream_WriteInt
	dd	_brl_stream_TStream_ReadLong
	dd	_brl_stream_TStream_WriteLong
	dd	_brl_stream_TStream_ReadFloat
	dd	_brl_stream_TStream_WriteFloat
	dd	_brl_stream_TStream_ReadDouble
	dd	_brl_stream_TStream_WriteDouble
	dd	_brl_stream_TStream_ReadLine
	dd	_brl_stream_TStream_WriteLine
	dd	_brl_stream_TStream_ReadString
	dd	_brl_stream_TStream_WriteString
	dd	_brl_stream_TStream_ReadObject
	dd	_brl_stream_TStream_WriteObject
	dd	_bb_TUDPStream_Init
	dd	_bb_TUDPStream_RecvMsg
	dd	_bb_TUDPStream_SendMsg
	dd	_bb_TNetStream_RecvAvail
	dd	_bb_TUDPStream_SetLocalPort
	dd	_bb_TUDPStream_GetLocalPort
	dd	_bb_TUDPStream_GetLocalIP
	dd	_bb_TUDPStream_SetRemotePort
	dd	_bb_TUDPStream_GetRemotePort
	dd	_bb_TUDPStream_SetRemoteIP
	dd	_bb_TUDPStream_GetRemoteIP
	dd	_bb_TUDPStream_SetBroadcast
	dd	_bb_TUDPStream_GetBroadcast
	dd	_bb_TUDPStream_GetMsgPort
	dd	_bb_TUDPStream_GetMsgIP
	dd	_bb_TUDPStream_SetTimeouts
	dd	_bb_TUDPStream_GetRecvTimeout
	dd	_bb_TUDPStream_GetSendTimeout
	dd	_bb_TUDPStream_SendUDPMsg
_122:
	db	"TTCPStream",0
_123:
	db	"AcceptTimeout",0
_124:
	db	"(i,i,i)i",0
_125:
	db	"GetAcceptTimeout",0
_126:
	db	"Connect",0
_127:
	db	"Listen",0
_128:
	db	"Accept",0
_129:
	db	"():TTCPStream",0
_130:
	db	"GetState",0
	align	4
_121:
	dd	2
	dd	_122
	dd	3
	dd	_88
	dd	_26
	dd	28
	dd	3
	dd	_89
	dd	_23
	dd	32
	dd	3
	dd	_91
	dd	_26
	dd	36
	dd	3
	dd	_90
	dd	_23
	dd	40
	dd	3
	dd	_94
	dd	_26
	dd	44
	dd	3
	dd	_95
	dd	_26
	dd	48
	dd	3
	dd	_123
	dd	_26
	dd	52
	dd	6
	dd	_29
	dd	_30
	dd	16
	dd	6
	dd	_31
	dd	_30
	dd	20
	dd	6
	dd	_75
	dd	_30
	dd	164
	dd	6
	dd	_102
	dd	_103
	dd	180
	dd	6
	dd	_104
	dd	_105
	dd	184
	dd	6
	dd	_106
	dd	_30
	dd	188
	dd	6
	dd	_107
	dd	_103
	dd	192
	dd	6
	dd	_108
	dd	_105
	dd	196
	dd	6
	dd	_109
	dd	_110
	dd	200
	dd	6
	dd	_111
	dd	_30
	dd	204
	dd	6
	dd	_116
	dd	_124
	dd	208
	dd	6
	dd	_118
	dd	_30
	dd	212
	dd	6
	dd	_119
	dd	_30
	dd	216
	dd	6
	dd	_125
	dd	_30
	dd	220
	dd	6
	dd	_126
	dd	_30
	dd	224
	dd	6
	dd	_127
	dd	_110
	dd	228
	dd	6
	dd	_128
	dd	_129
	dd	232
	dd	6
	dd	_76
	dd	_30
	dd	168
	dd	6
	dd	_79
	dd	_30
	dd	172
	dd	6
	dd	_130
	dd	_30
	dd	236
	dd	0
	align	4
bb_TTCPStream:
	dd	bb_TNetStream
	dd	bbObjectFree
	dd	_121
	dd	56
	dd	_bb_TTCPStream_New
	dd	_bb_TTCPStream_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TNetStream_Eof
	dd	_brl_stream_TIO_Pos
	dd	_bb_TNetStream_Size
	dd	_brl_stream_TIO_Seek
	dd	_bb_TNetStream_Flush
	dd	_bb_TNetStream_Close
	dd	_bb_TNetStream_Read
	dd	_bb_TNetStream_Write
	dd	_brl_stream_TStream_ReadBytes
	dd	_brl_stream_TStream_WriteBytes
	dd	_brl_stream_TStream_SkipBytes
	dd	_brl_stream_TStream_ReadByte
	dd	_brl_stream_TStream_WriteByte
	dd	_brl_stream_TStream_ReadShort
	dd	_brl_stream_TStream_WriteShort
	dd	_brl_stream_TStream_ReadInt
	dd	_brl_stream_TStream_WriteInt
	dd	_brl_stream_TStream_ReadLong
	dd	_brl_stream_TStream_WriteLong
	dd	_brl_stream_TStream_ReadFloat
	dd	_brl_stream_TStream_WriteFloat
	dd	_brl_stream_TStream_ReadDouble
	dd	_brl_stream_TStream_WriteDouble
	dd	_brl_stream_TStream_ReadLine
	dd	_brl_stream_TStream_WriteLine
	dd	_brl_stream_TStream_ReadString
	dd	_brl_stream_TStream_WriteString
	dd	_brl_stream_TStream_ReadObject
	dd	_brl_stream_TStream_WriteObject
	dd	_bb_TTCPStream_Init
	dd	_bb_TTCPStream_RecvMsg
	dd	_bb_TTCPStream_SendMsg
	dd	_bb_TNetStream_RecvAvail
	dd	_bb_TTCPStream_SetLocalPort
	dd	_bb_TTCPStream_GetLocalPort
	dd	_bb_TTCPStream_GetLocalIP
	dd	_bb_TTCPStream_SetRemotePort
	dd	_bb_TTCPStream_GetRemotePort
	dd	_bb_TTCPStream_SetRemoteIP
	dd	_bb_TTCPStream_GetRemoteIP
	dd	_bb_TTCPStream_SetTimeouts
	dd	_bb_TTCPStream_GetRecvTimeout
	dd	_bb_TTCPStream_GetSendTimeout
	dd	_bb_TTCPStream_GetAcceptTimeout
	dd	_bb_TTCPStream_Connect
	dd	_bb_TTCPStream_Listen
	dd	_bb_TTCPStream_Accept
	dd	_bb_TTCPStream_GetState
_362:
	db	"b",0
_395:
	db	"i",0
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_16:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	45
