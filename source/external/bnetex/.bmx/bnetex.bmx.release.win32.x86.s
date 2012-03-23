	format	MS COFF
	extrn	_GetCurrentProcessId@0
	extrn	_GetNetworkAdapter
	extrn	___bb_blitz_blitz
	extrn	___bb_glmax2d_glmax2d
	extrn	___bb_stream_stream
	extrn	__brl_stream_TIO_Pos
	extrn	__brl_stream_TIO_Seek
	extrn	__brl_stream_TStream_Delete
	extrn	__brl_stream_TStream_New
	extrn	__brl_stream_TStream_ReadByte
	extrn	__brl_stream_TStream_ReadBytes
	extrn	__brl_stream_TStream_ReadDouble
	extrn	__brl_stream_TStream_ReadFloat
	extrn	__brl_stream_TStream_ReadInt
	extrn	__brl_stream_TStream_ReadLine
	extrn	__brl_stream_TStream_ReadLong
	extrn	__brl_stream_TStream_ReadObject
	extrn	__brl_stream_TStream_ReadShort
	extrn	__brl_stream_TStream_ReadString
	extrn	__brl_stream_TStream_SkipBytes
	extrn	__brl_stream_TStream_WriteByte
	extrn	__brl_stream_TStream_WriteBytes
	extrn	__brl_stream_TStream_WriteDouble
	extrn	__brl_stream_TStream_WriteFloat
	extrn	__brl_stream_TStream_WriteInt
	extrn	__brl_stream_TStream_WriteLine
	extrn	__brl_stream_TStream_WriteLong
	extrn	__brl_stream_TStream_WriteObject
	extrn	__brl_stream_TStream_WriteShort
	extrn	__brl_stream_TStream_WriteString
	extrn	_accept_
	extrn	_bbArrayNew1D
	extrn	_bbEmptyArray
	extrn	_bbEmptyString
	extrn	_bbFloor
	extrn	_bbGCFree
	extrn	_bbLongAdd
	extrn	_bbLongAnd
	extrn	_bbLongNot
	extrn	_bbLongShr
	extrn	_bbMemAlloc
	extrn	_bbMemCopy
	extrn	_bbMemFree
	extrn	_bbMilliSecs
	extrn	_bbNullObject
	extrn	_bbObjectClass
	extrn	_bbObjectCompare
	extrn	_bbObjectCtor
	extrn	_bbObjectFree
	extrn	_bbObjectNew
	extrn	_bbObjectRegisterType
	extrn	_bbObjectReserved
	extrn	_bbObjectSendMessage
	extrn	_bbObjectToString
	extrn	_bbStringClass
	extrn	_bbStringConcat
	extrn	_bbStringFromCString
	extrn	_bbStringFromChar
	extrn	_bbStringSlice
	extrn	_bbStringToCString
	extrn	_bind_
	extrn	_brl_blitz_NullMethodError
	extrn	_brl_stream_TStream
	extrn	_closesocket_
	extrn	_connect_
	extrn	_gethostbyaddr_
	extrn	_gethostbyname_
	extrn	_getsockname@12
	extrn	_getsockopt_
	extrn	_htonl_
	extrn	_htons_
	extrn	_inet_addr@4
	extrn	_inet_ntoa@4
	extrn	_ioctlsocket@12
	extrn	_listen_
	extrn	_ntohl_
	extrn	_ntohs_
	extrn	_recv_
	extrn	_recvfrom_
	extrn	_select_
	extrn	_send_
	extrn	_sendto_
	extrn	_setsockopt_
	extrn	_shutdown_
	extrn	_socket_
	public	___bb_bnetex_bnetex
	public	__bb_TAdapterInfo_Delete
	public	__bb_TAdapterInfo_New
	public	__bb_TICMP_BuildChecksum
	public	__bb_TICMP_Delete
	public	__bb_TICMP_New
	public	__bb_TNetStream_Close
	public	__bb_TNetStream_Delete
	public	__bb_TNetStream_Eof
	public	__bb_TNetStream_Flush
	public	__bb_TNetStream_New
	public	__bb_TNetStream_Read
	public	__bb_TNetStream_RecvAvail
	public	__bb_TNetStream_Size
	public	__bb_TNetStream_Write
	public	__bb_TNetwork_Delete
	public	__bb_TNetwork_GetAdapterInfo
	public	__bb_TNetwork_GetHostIP
	public	__bb_TNetwork_GetHostIPs
	public	__bb_TNetwork_GetHostName
	public	__bb_TNetwork_IntIP
	public	__bb_TNetwork_New
	public	__bb_TNetwork_Ping
	public	__bb_TNetwork_StringIP
	public	__bb_TNetwork_StringMAC
	public	__bb_TSockAddr_Delete
	public	__bb_TSockAddr_New
	public	__bb_TTCPStream_Accept
	public	__bb_TTCPStream_Connect
	public	__bb_TTCPStream_Delete
	public	__bb_TTCPStream_GetAcceptTimeout
	public	__bb_TTCPStream_GetLocalIP
	public	__bb_TTCPStream_GetLocalPort
	public	__bb_TTCPStream_GetRecvTimeout
	public	__bb_TTCPStream_GetRemoteIP
	public	__bb_TTCPStream_GetRemotePort
	public	__bb_TTCPStream_GetSendTimeout
	public	__bb_TTCPStream_GetState
	public	__bb_TTCPStream_Init
	public	__bb_TTCPStream_Listen
	public	__bb_TTCPStream_New
	public	__bb_TTCPStream_RecvMsg
	public	__bb_TTCPStream_SendMsg
	public	__bb_TTCPStream_SetLocalPort
	public	__bb_TTCPStream_SetRemoteIP
	public	__bb_TTCPStream_SetRemotePort
	public	__bb_TTCPStream_SetTimeouts
	public	__bb_TUDPStream_Delete
	public	__bb_TUDPStream_GetBroadcast
	public	__bb_TUDPStream_GetLocalIP
	public	__bb_TUDPStream_GetLocalPort
	public	__bb_TUDPStream_GetMsgIP
	public	__bb_TUDPStream_GetMsgPort
	public	__bb_TUDPStream_GetRecvTimeout
	public	__bb_TUDPStream_GetRemoteIP
	public	__bb_TUDPStream_GetRemotePort
	public	__bb_TUDPStream_GetSendTimeout
	public	__bb_TUDPStream_Init
	public	__bb_TUDPStream_New
	public	__bb_TUDPStream_RecvMsg
	public	__bb_TUDPStream_SendMsg
	public	__bb_TUDPStream_SendUDPMsg
	public	__bb_TUDPStream_SetBroadcast
	public	__bb_TUDPStream_SetLocalPort
	public	__bb_TUDPStream_SetRemoteIP
	public	__bb_TUDPStream_SetRemotePort
	public	__bb_TUDPStream_SetTimeouts
	public	_bb_TAdapterInfo
	public	_bb_TNetStream
	public	_bb_TNetwork
	public	_bb_TTCPStream
	public	_bb_TUDPStream
	section	"code" code
___bb_bnetex_bnetex:
	push	ebp
	mov	ebp,esp
	cmp	dword [_356],0
	je	_357
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_357:
	mov	dword [_356],1
	call	___bb_blitz_blitz
	call	___bb_stream_stream
	call	___bb_glmax2d_glmax2d
	push	_2
	call	_bbObjectRegisterType
	add	esp,4
	push	_3
	call	_bbObjectRegisterType
	add	esp,4
	push	_bb_TAdapterInfo
	call	_bbObjectRegisterType
	add	esp,4
	push	_bb_TNetwork
	call	_bbObjectRegisterType
	add	esp,4
	push	_bb_TNetStream
	call	_bbObjectRegisterType
	add	esp,4
	push	_bb_TUDPStream
	call	_bbObjectRegisterType
	add	esp,4
	push	_bb_TTCPStream
	call	_bbObjectRegisterType
	add	esp,4
	mov	eax,0
	jmp	_131
_131:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TSockAddr_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bbObjectCtor
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
__bb_TSockAddr_Delete:
	push	ebp
	mov	ebp,esp
_137:
	mov	eax,0
	jmp	_358
_358:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TICMP_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bbObjectCtor
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
__bb_TICMP_Delete:
	push	ebp
	mov	ebp,esp
_143:
	mov	eax,0
	jmp	_359
_359:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TICMP_BuildChecksum:
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
	call	_bbLongAdd
	add	esp,20
	add	esi,2
	sub	ebx,2
_4:
	cmp	ebx,1
	jg	_6
_5:
	cmp	ebx,0
	je	_361
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
	call	_bbLongAdd
	add	esp,20
_361:
	push	0
	push	16
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-36]
	push	eax
	call	_bbLongShr
	add	esp,20
	push	0
	push	65535
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-44]
	push	eax
	call	_bbLongAnd
	add	esp,20
	push	dword [ebp-40]
	push	dword [ebp-44]
	push	dword [ebp-32]
	push	dword [ebp-36]
	lea	eax,dword [ebp-8]
	push	eax
	call	_bbLongAdd
	add	esp,20
	push	0
	push	16
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-52]
	push	eax
	call	_bbLongShr
	add	esp,20
	push	dword [ebp-48]
	push	dword [ebp-52]
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-8]
	push	eax
	call	_bbLongAdd
	add	esp,20
	push	dword [ebp-4]
	push	dword [ebp-8]
	lea	eax,dword [ebp-60]
	push	eax
	call	_bbLongNot
	add	esp,12
	push	dword [ebp-60]
	call	_htons_
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
__bb_TAdapterInfo_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bbObjectCtor
	add	esp,4
	mov	dword [ebx],_bb_TAdapterInfo
	mov	eax,_bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	push	6
	push	_363
	call	_bbArrayNew1D
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
__bb_TAdapterInfo_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_153:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_367
	push	eax
	call	_bbGCFree
	add	esp,4
_367:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_369
	push	eax
	call	_bbGCFree
	add	esp,4
_369:
	mov	eax,0
	jmp	_365
_365:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetwork_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bbObjectCtor
	add	esp,4
	mov	dword [ebx],_bb_TNetwork
	mov	eax,0
	jmp	_156
_156:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetwork_Delete:
	push	ebp
	mov	ebp,esp
_159:
	mov	eax,0
	jmp	_370
_370:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetwork_GetHostIP:
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
	call	_gethostbyname_
	add	esp,12
	mov	edx,eax
	cmp	edx,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_376
	mov	eax,dword [ebp-4]
	cmp	eax,2
	setne	al
	movzx	eax,al
_376:
	cmp	eax,0
	jne	_378
	mov	eax,dword [ebp-8]
	cmp	eax,4
	setne	al
	movzx	eax,al
_378:
	cmp	eax,0
	je	_380
	mov	eax,0
	jmp	_162
_380:
	cmp	dword [edx],0
	je	_381
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
_381:
	mov	eax,0
	jmp	_162
_162:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetwork_GetHostIPs:
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
	call	_gethostbyname_
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
	jne	_391
	mov	eax,dword [ebp-4]
	cmp	eax,2
	setne	al
	movzx	eax,al
_391:
	cmp	eax,0
	jne	_393
	mov	eax,dword [ebp-8]
	cmp	eax,4
	setne	al
	movzx	eax,al
_393:
	cmp	eax,0
	je	_395
	mov	eax,_bbEmptyArray
	jmp	_165
_395:
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
	push	_396
	call	_bbArrayNew1D
	add	esp,8
	mov	edx,eax
	mov	eax,0
	mov	edi,ebx
	jmp	_397
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
_397:
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
__bb_TNetwork_GetHostName:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],0
	push	eax
	call	_htonl_
	add	esp,4
	mov	dword [ebp-4],eax
	push	2
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	call	_gethostbyaddr_
	add	esp,12
	cmp	eax,0
	je	_401
	push	eax
	call	_bbStringFromCString
	add	esp,4
	jmp	_168
_401:
	mov	eax,_1
	jmp	_168
_168:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetwork_StringIP:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	push	eax
	call	_htonl_
	add	esp,4
	push	eax
	call	_inet_ntoa@4
	push	eax
	call	_bbStringFromCString
	add	esp,4
	jmp	_171
_171:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetwork_StringMAC:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,_bbEmptyString
	mov	byte [ebp-4],0
	mov	byte [ebp-8],0
	mov	ebx,0
	jmp	_407
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
	jge	_408
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	add	eax,48
	push	eax
	call	_bbStringFromChar
	add	esp,4
	push	eax
	push	esi
	call	_bbStringConcat
	add	esp,8
	mov	esi,eax
	jmp	_409
_408:
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	add	eax,55
	push	eax
	call	_bbStringFromChar
	add	esp,4
	push	eax
	push	esi
	call	_bbStringConcat
	add	esp,8
	mov	esi,eax
_409:
	movzx	eax,byte [ebp-8]
	mov	eax,eax
	cmp	eax,10
	jge	_410
	movzx	eax,byte [ebp-8]
	mov	eax,eax
	add	eax,48
	push	eax
	call	_bbStringFromChar
	add	esp,4
	push	eax
	push	esi
	call	_bbStringConcat
	add	esp,8
	mov	esi,eax
	jmp	_411
_410:
	movzx	eax,byte [ebp-8]
	mov	eax,eax
	add	eax,55
	push	eax
	call	_bbStringFromChar
	add	esp,4
	push	eax
	push	esi
	call	_bbStringConcat
	add	esp,8
	mov	esi,eax
_411:
	push	_16
	push	esi
	call	_bbStringConcat
	add	esp,8
	mov	esi,eax
_13:
	add	ebx,1
_407:
	cmp	ebx,5
	jle	_15
_14:
	mov	eax,dword [esi+8]
	sub	eax,1
	push	eax
	push	0
	push	esi
	call	_bbStringSlice
	add	esp,12
	jmp	_174
_174:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetwork_IntIP:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	push	eax
	call	_bbStringToCString
	add	esp,4
	mov	ebx,eax
	push	ebx
	call	_inet_addr@4
	mov	esi,eax
	push	ebx
	call	_bbMemFree
	add	esp,4
	push	esi
	call	_htonl_
	add	esp,4
	jmp	_177
_177:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetwork_Ping:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+12]
	mov	esi,dword [ebp+20]
	mov	dword [ebp-4],_bbNullObject
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	push	1
	push	3
	push	2
	call	_socket_
	add	esp,12
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],-1
	jne	_425
	mov	eax,-1
	jmp	_184
_425:
	call	_GetCurrentProcessId@0
	mov	dword [ebp-24],eax
	push	_3
	call	_bbObjectNew
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
	call	_bbMemAlloc
	add	esp,4
	mov	edi,eax
	push	8
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	push	edi
	call	_bbMemCopy
	add	esp,12
	push	dword [ebp+16]
	push	ebx
	mov	eax,edi
	add	eax,8
	push	eax
	call	_bbMemCopy
	add	esp,12
	mov	eax,dword [ebp+16]
	add	eax,8
	push	eax
	push	edi
	call	dword [_3+48]
	add	esp,8
	mov	eax,eax
	push	eax
	call	_htons_
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
	call	dword [_355]
	add	esp,28
	cmp	eax,1
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_426
	push	0
	push	dword [ebp+8]
	push	0
	mov	eax,dword [ebp+16]
	add	eax,8
	push	eax
	push	edi
	push	dword [ebp-20]
	call	_sendto_
	add	esp,24
	cmp	eax,-1
	sete	al
	movzx	eax,al
_426:
	cmp	eax,0
	je	_428
	push	edi
	call	_bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	_closesocket_
	add	esp,4
	mov	eax,-1
	jmp	_184
_428:
	call	_bbMilliSecs
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
	call	dword [_355]
	add	esp,28
	cmp	eax,1
	je	_429
	push	edi
	call	_bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	_closesocket_
	add	esp,4
	mov	eax,-1
	jmp	_184
_429:
	lea	eax,dword [ebp-16]
	push	eax
	lea	eax,dword [ebp-12]
	push	eax
	push	0
	push	65536
	push	edi
	push	dword [ebp-20]
	call	_recvfrom_
	add	esp,24
	mov	ebx,eax
	call	_bbMilliSecs
	mov	esi,eax
	cmp	ebx,-1
	jne	_430
	push	edi
	call	_bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	_closesocket_
	add	esp,4
	mov	eax,-1
	jmp	_184
_430:
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
	call	_bbMemCopy
	add	esp,12
	mov	eax,dword [ebp-4]
	movzx	eax,word [eax+12]
	mov	eax,eax
	cmp	eax,dword [ebp-24]
	je	_431
	jmp	_17
_431:
	mov	eax,dword [ebp-4]
	movzx	eax,byte [eax+8]
	mov	eax,eax
	cmp	eax,3
	jne	_433
	mov	eax,dword [ebp-4]
	movzx	eax,byte [eax+9]
	mov	eax,eax
	cmp	eax,1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_434
	mov	eax,dword [ebp-4]
	movzx	eax,byte [eax+9]
	mov	eax,eax
	cmp	eax,0
	sete	al
	movzx	eax,al
_434:
	cmp	eax,0
	je	_436
	push	edi
	call	_bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	_closesocket_
	add	esp,4
	mov	eax,-1
	jmp	_184
_436:
	jmp	_437
_433:
	mov	eax,dword [ebp-4]
	movzx	eax,byte [eax+9]
	mov	eax,eax
	cmp	eax,0
	jne	_438
	jmp	_18
_438:
_437:
_432:
	jmp	_19
_18:
	push	edi
	call	_bbMemFree
	add	esp,4
	push	dword [ebp-20]
	call	_closesocket_
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
__bb_TNetwork_GetAdapterInfo:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebx]
	cmp	eax,_bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_440
	push	_bb_TAdapterInfo
	call	_bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx]
	dec	dword [eax+4]
	jnz	_444
	push	eax
	call	_bbGCFree
	add	esp,4
_444:
	mov	dword [ebx],esi
_440:
	push	256
	call	_bbMemAlloc
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
	call	_GetNetworkAdapter
	add	esp,20
	cmp	eax,0
	jne	_445
	mov	eax,0
	jmp	_187
_445:
	push	esi
	call	_bbStringFromCString
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx]
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_449
	push	eax
	call	_bbGCFree
	add	esp,4
_449:
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
__bb_TNetStream_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	__brl_stream_TStream_New
	add	esp,4
	mov	dword [ebx],_bb_TNetStream
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
__bb_TNetStream_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	cmp	dword [ebx+20],0
	jle	_451
	push	dword [ebx+12]
	call	_bbMemFree
	add	esp,4
_451:
	cmp	dword [ebx+24],0
	jle	_452
	push	dword [ebx+16]
	call	_bbMemFree
	add	esp,4
_452:
_193:
	mov	dword [ebx],_brl_stream_TStream
	push	ebx
	call	__brl_stream_TStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_453
_453:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetStream_Read:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	edi,dword [ebp+16]
	cmp	edi,dword [esi+20]
	jle	_455
	mov	edi,dword [esi+20]
_455:
	cmp	edi,0
	jle	_456
	push	edi
	push	dword [esi+12]
	push	eax
	call	_bbMemCopy
	add	esp,12
	cmp	edi,dword [esi+20]
	jge	_457
	mov	eax,dword [esi+20]
	sub	eax,edi
	push	eax
	call	_bbMemAlloc
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [esi+20]
	sub	eax,edi
	push	eax
	mov	eax,dword [esi+12]
	add	eax,edi
	push	eax
	push	ebx
	call	_bbMemCopy
	add	esp,12
	push	dword [esi+12]
	call	_bbMemFree
	add	esp,4
	mov	dword [esi+12],ebx
	sub	dword [esi+20],edi
	jmp	_458
_457:
	push	dword [esi+12]
	call	_bbMemFree
	add	esp,4
	mov	dword [esi+20],0
_458:
_456:
	mov	eax,edi
	jmp	_198
_198:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetStream_Write:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+16]
	cmp	edi,0
	jg	_460
	mov	eax,0
	jmp	_203
_460:
	mov	eax,dword [esi+24]
	add	eax,edi
	push	eax
	call	_bbMemAlloc
	add	esp,4
	mov	ebx,eax
	cmp	dword [esi+24],0
	jle	_461
	push	dword [esi+24]
	push	dword [esi+16]
	push	ebx
	call	_bbMemCopy
	add	esp,12
	push	edi
	push	dword [ebp+12]
	mov	eax,ebx
	add	eax,dword [esi+24]
	push	eax
	call	_bbMemCopy
	add	esp,12
	push	dword [esi+16]
	call	_bbMemFree
	add	esp,4
	mov	dword [esi+16],ebx
	add	dword [esi+24],edi
	jmp	_462
_461:
	push	edi
	push	dword [ebp+12]
	push	ebx
	call	_bbMemCopy
	add	esp,12
	mov	dword [esi+16],ebx
	mov	dword [esi+24],edi
_462:
	mov	eax,edi
	jmp	_203
_203:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetStream_Eof:
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
__bb_TNetStream_Size:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+20]
	jmp	_209
_209:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetStream_Flush:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	cmp	dword [ebx+20],0
	jle	_463
	push	dword [ebx+12]
	call	_bbMemFree
	add	esp,4
_463:
	cmp	dword [ebx+24],0
	jle	_464
	push	dword [ebx+16]
	call	_bbMemFree
	add	esp,4
_464:
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	eax,0
	jmp	_212
_212:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetStream_Close:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	cmp	dword [ebx+8],-1
	je	_465
	push	2
	push	dword [ebx+8]
	call	_shutdown_
	add	esp,8
	push	dword [ebx+8]
	call	_closesocket_
	add	esp,4
	mov	dword [ebx+8],-1
_465:
	mov	eax,0
	jmp	_215
_215:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TNetStream_RecvAvail:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edx,dword [ebp+8]
	mov	dword [ebp-4],0
	cmp	dword [edx+8],-1
	jne	_467
	mov	eax,-1
	jmp	_218
_467:
	lea	eax,dword [ebp-4]
	push	eax
	push	1074030207
	push	dword [edx+8]
	call	_ioctlsocket@12
	cmp	eax,-1
	jne	_468
	mov	eax,-1
	jmp	_218
_468:
	mov	eax,dword [ebp-4]
	jmp	_218
_218:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	__bb_TNetStream_New
	add	esp,4
	mov	dword [ebx],_bb_TUDPStream
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
__bb_TUDPStream_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_224:
	mov	dword [eax],_bb_TNetStream
	push	eax
	call	__bb_TNetStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_470
_470:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_Init:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	push	0
	push	2
	push	2
	call	_socket_
	add	esp,12
	mov	dword [ebx+8],eax
	cmp	dword [ebx+8],-1
	jne	_472
	mov	eax,0
	jmp	_227
_472:
	mov	dword [ebp-4],65527
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	4098
	push	65535
	push	dword [ebx+8]
	call	_setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_473
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	4097
	push	65535
	push	dword [ebx+8]
	call	_setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
_473:
	cmp	eax,0
	je	_475
	push	dword [ebx+8]
	call	_closesocket_
	add	esp,4
	mov	eax,0
	jmp	_227
_475:
	mov	eax,1
	jmp	_227
_227:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_SetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	mov	dword [ebp-8],_bbNullObject
	mov	dword [ebp-12],0
	cmp	dword [ebx+8],-1
	jne	_478
	mov	eax,0
	jmp	_231
_478:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	push	eax
	push	2
	push	dword [ebx+8]
	call	_bind_
	add	esp,12
	cmp	eax,-1
	jne	_479
	mov	eax,0
	jmp	_231
_479:
	push	_2
	call	_bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],16
	lea	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	_getsockname@12
	cmp	eax,-1
	jne	_481
	mov	eax,0
	jmp	_231
_481:
	mov	eax,dword [ebp-8]
	push	dword [eax+12]
	call	_ntohl_
	add	esp,4
	mov	dword [ebx+28],eax
	mov	eax,dword [ebp-8]
	movzx	eax,word [eax+10]
	mov	eax,eax
	push	eax
	call	_ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+32],ax
	mov	eax,1
	jmp	_231
_231:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_GetLocalPort:
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
__bb_TUDPStream_GetLocalIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	jmp	_237
_237:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_SetRemotePort:
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
__bb_TUDPStream_GetRemotePort:
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
__bb_TUDPStream_SetRemoteIP:
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
__bb_TUDPStream_GetRemoteIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+36]
	jmp	_251
_251:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_SetBroadcast:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	dword [ebp-4],eax
	cmp	dword [edx+8],-1
	jne	_483
	mov	eax,0
	jmp	_255
_483:
	cmp	dword [ebp-4],0
	je	_484
	mov	dword [ebp-4],1
_484:
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	32
	push	65535
	push	dword [edx+8]
	call	_setsockopt_
	add	esp,20
	cmp	eax,-1
	jne	_485
	mov	eax,0
	jmp	_255
_485:
	mov	eax,1
	jmp	_255
_255:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_GetBroadcast:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	mov	edx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],0
	cmp	dword [edx+8],-1
	jne	_488
	mov	eax,0
	jmp	_258
_488:
	mov	dword [ebp-8],4
	lea	eax,dword [ebp-8]
	push	eax
	lea	eax,dword [ebp-4]
	push	eax
	push	32
	push	65535
	push	dword [edx+8]
	call	_getsockopt_
	add	esp,20
	cmp	eax,-1
	jne	_489
	mov	eax,-1
	jmp	_258
_489:
	mov	eax,dword [ebp-4]
	jmp	_258
_258:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_GetMsgPort:
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
__bb_TUDPStream_GetMsgIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+40]
	jmp	_264
_264:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_SetTimeouts:
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
__bb_TUDPStream_GetRecvTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+48]
	jmp	_272
_272:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_GetSendTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	jmp	_275
_275:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_RecvMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	cmp	dword [esi+8],-1
	jne	_496
	mov	edx,0
	jmp	_278
_496:
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
	call	dword [_355]
	add	esp,28
	cmp	eax,1
	je	_497
	mov	edx,0
	jmp	_278
_497:
	lea	eax,dword [ebp-8]
	push	eax
	push	1074030207
	push	dword [esi+8]
	call	_ioctlsocket@12
	cmp	eax,-1
	jne	_498
	mov	edx,0
	jmp	_278
_498:
	cmp	dword [ebp-8],0
	jg	_499
	mov	edx,0
	jmp	_278
_499:
	cmp	dword [esi+20],0
	jle	_500
	mov	eax,dword [esi+20]
	add	eax,dword [ebp-8]
	push	eax
	call	_bbMemAlloc
	add	esp,4
	mov	ebx,eax
	push	dword [esi+20]
	push	dword [esi+12]
	push	ebx
	call	_bbMemCopy
	add	esp,12
	push	dword [esi+12]
	call	_bbMemFree
	add	esp,4
	mov	dword [esi+12],ebx
	mov	ebx,1000
	call	_bbMilliSecs
	cdq
	idiv	ebx
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,8
	fstp	qword [esp]
	call	_bbFloor
	add	esp,8
	fld	dword [esi+72]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setz	al
	movzx	eax,al
	cmp	eax,0
	jne	_501
	fld	dword [esi+60]
	fadd	dword [esi+64]
	fstp	dword [esi+68]
	mov	ebx,1000
	call	_bbMilliSecs
	cdq
	idiv	ebx
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,8
	fstp	qword [esp]
	call	_bbFloor
	add	esp,8
	fstp	dword [esi+72]
	fldz
	fstp	dword [esi+60]
	fldz
	fstp	dword [esi+64]
_501:
	fld	dword [esi+60]
	mov	eax,dword [esi+20]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	faddp	st1,st0
	fstp	dword [esi+60]
	jmp	_502
_500:
	push	dword [ebp-8]
	call	_bbMemAlloc
	add	esp,4
	mov	dword [esi+12],eax
_502:
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
	call	_recvfrom_
	add	esp,24
	mov	edx,eax
	cmp	edx,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_503
	cmp	edx,0
	sete	al
	movzx	eax,al
_503:
	cmp	eax,0
	je	_505
	mov	edx,0
	jmp	_278
_505:
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
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TUDPStream_SendUDPMsg:
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
__bb_TUDPStream_SendMsg:
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
	jne	_515
	mov	eax,dword [ebx+24]
	cmp	eax,0
	sete	al
	movzx	eax,al
_515:
	cmp	eax,0
	je	_517
	mov	eax,0
	jmp	_286
_517:
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
	call	dword [_355]
	add	esp,28
	cmp	eax,1
	je	_518
	mov	eax,0
	jmp	_286
_518:
	movzx	eax,word [ebx+34]
	mov	eax,eax
	push	eax
	push	dword [ebx+36]
	push	0
	push	dword [ebx+24]
	push	dword [ebx+16]
	push	dword [ebx+8]
	call	_sendto_
	add	esp,24
	mov	edi,eax
	cmp	edi,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_519
	cmp	edi,0
	sete	al
	movzx	eax,al
_519:
	cmp	eax,0
	je	_521
	mov	eax,0
	jmp	_286
_521:
	cmp	edi,dword [ebx+24]
	jne	_523
	push	dword [ebx+16]
	call	_bbMemFree
	add	esp,4
	mov	dword [ebx+24],0
	jmp	_524
_523:
	mov	eax,dword [ebx+24]
	sub	eax,edi
	push	eax
	call	_bbMemAlloc
	add	esp,4
	mov	esi,eax
	mov	eax,dword [ebx+24]
	sub	eax,edi
	push	eax
	mov	eax,dword [ebx+16]
	add	eax,edi
	push	eax
	push	esi
	call	_bbMemCopy
	add	esp,12
	push	dword [ebx+16]
	call	_bbMemFree
	add	esp,4
	mov	dword [ebx+16],esi
	sub	dword [ebx+24],edi
	mov	esi,1000
	call	_bbMilliSecs
	cdq
	idiv	esi
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	_bbFloor
	add	esp,8
	fld	dword [ebx+72]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setz	al
	movzx	eax,al
	cmp	eax,0
	jne	_525
	fld	dword [ebx+60]
	fadd	dword [ebx+64]
	fstp	dword [ebx+68]
	mov	esi,1000
	call	_bbMilliSecs
	cdq
	idiv	esi
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	_bbFloor
	add	esp,8
	fstp	dword [ebx+72]
	fldz
	fstp	dword [ebx+60]
	fldz
	fstp	dword [ebx+64]
_525:
	fld	dword [ebx+64]
	mov	eax,dword [ebx+24]
	sub	eax,edi
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	faddp	st1,st0
	fstp	dword [ebx+64]
_524:
	mov	eax,edi
	jmp	_286
_286:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	__bb_TNetStream_New
	add	esp,4
	mov	dword [ebx],_bb_TTCPStream
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
__bb_TTCPStream_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_292:
	mov	dword [eax],_bb_TNetStream
	push	eax
	call	__bb_TNetStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_526
_526:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_Init:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	push	0
	push	1
	push	2
	call	_socket_
	add	esp,12
	mov	dword [ebx+8],eax
	cmp	dword [ebx+8],-1
	jne	_528
	mov	eax,0
	jmp	_295
_528:
	mov	dword [ebp-4],65535
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	4098
	push	65535
	push	dword [ebx+8]
	call	_setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_529
	push	4
	lea	eax,dword [ebp-4]
	push	eax
	push	4097
	push	65535
	push	dword [ebx+8]
	call	_setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
_529:
	cmp	eax,0
	je	_531
	push	dword [ebx+8]
	call	_closesocket_
	add	esp,4
	mov	eax,0
	jmp	_295
_531:
	mov	eax,1
	jmp	_295
_295:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_SetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	mov	dword [ebp-8],_bbNullObject
	mov	dword [ebp-12],0
	cmp	dword [ebx+8],-1
	jne	_534
	mov	eax,0
	jmp	_299
_534:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	push	eax
	push	2
	push	dword [ebx+8]
	call	_bind_
	add	esp,12
	cmp	eax,-1
	jne	_535
	mov	eax,0
	jmp	_299
_535:
	push	_2
	call	_bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],16
	lea	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	_getsockname@12
	cmp	eax,-1
	jne	_537
	mov	eax,0
	jmp	_299
_537:
	mov	eax,dword [ebp-8]
	push	dword [eax+12]
	call	_ntohl_
	add	esp,4
	mov	dword [ebx+28],eax
	mov	eax,dword [ebp-8]
	movzx	eax,word [eax+10]
	mov	eax,eax
	push	eax
	call	_ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+32],ax
	mov	eax,1
	jmp	_299
_299:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_GetLocalPort:
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
__bb_TTCPStream_GetLocalIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	jmp	_305
_305:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_SetRemotePort:
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
__bb_TTCPStream_GetRemotePort:
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
__bb_TTCPStream_SetRemoteIP:
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
__bb_TTCPStream_GetRemoteIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+36]
	jmp	_319
_319:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_SetTimeouts:
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
__bb_TTCPStream_GetRecvTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+44]
	jmp	_328
_328:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_GetSendTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+48]
	jmp	_331
_331:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_GetAcceptTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	jmp	_334
_334:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_Connect:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	cmp	dword [ebx+8],-1
	jne	_540
	mov	eax,0
	jmp	_337
_540:
	push	dword [ebx+36]
	call	_htonl_
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
	call	_connect_
	add	esp,20
	cmp	eax,-1
	jne	_541
	mov	eax,0
	jmp	_337
_541:
	mov	eax,1
	jmp	_337
_337:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_Listen:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	cmp	dword [edx+8],-1
	jne	_543
	mov	eax,0
	jmp	_341
_543:
	push	eax
	push	dword [edx+8]
	call	_listen_
	add	esp,8
	cmp	eax,-1
	jne	_544
	mov	eax,0
	jmp	_341
_544:
	mov	eax,1
	jmp	_341
_341:
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_Accept:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],_bbNullObject
	mov	dword [ebp-12],0
	cmp	dword [ebx+8],-1
	jne	_551
	mov	ebx,_bbNullObject
	jmp	_344
_551:
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
	call	dword [_355]
	add	esp,28
	cmp	eax,1
	je	_552
	mov	ebx,_bbNullObject
	jmp	_344
_552:
	push	_2
	call	_bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],16
	lea	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	_accept_
	add	esp,12
	mov	esi,eax
	cmp	esi,-1
	jne	_553
	mov	ebx,_bbNullObject
	jmp	_344
_553:
	push	_bb_TTCPStream
	call	_bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	dword [ebx+8],esi
	mov	eax,dword [ebp-8]
	push	dword [eax+12]
	call	_ntohl_
	add	esp,4
	mov	dword [ebx+28],eax
	mov	eax,dword [ebp-8]
	movzx	eax,word [eax+10]
	mov	eax,eax
	push	eax
	call	_ntohs_
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
	call	_getsockname@12
	cmp	eax,-1
	jne	_554
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	ebx,_bbNullObject
	jmp	_344
_554:
	mov	eax,dword [ebp-8]
	push	dword [eax+12]
	call	_ntohl_
	add	esp,4
	mov	dword [ebx+36],eax
	mov	eax,dword [ebp-8]
	movzx	eax,word [eax+10]
	mov	eax,eax
	push	eax
	call	_ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+40],ax
	jmp	_344
_344:
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_RecvMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],0
	cmp	dword [ebx+8],-1
	jne	_560
	mov	eax,0
	jmp	_347
_560:
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
	call	dword [_355]
	add	esp,28
	cmp	eax,1
	je	_561
	mov	eax,0
	jmp	_347
_561:
	lea	eax,dword [ebp-8]
	push	eax
	push	1074030207
	push	dword [ebx+8]
	call	_ioctlsocket@12
	cmp	eax,-1
	jne	_562
	mov	eax,0
	jmp	_347
_562:
	cmp	dword [ebp-8],0
	jg	_563
	mov	eax,0
	jmp	_347
_563:
	cmp	dword [ebx+20],0
	jle	_564
	mov	eax,dword [ebx+20]
	add	eax,dword [ebp-8]
	push	eax
	call	_bbMemAlloc
	add	esp,4
	mov	esi,eax
	push	dword [ebx+20]
	push	dword [ebx+12]
	push	esi
	call	_bbMemCopy
	add	esp,12
	push	dword [ebx+12]
	call	_bbMemFree
	add	esp,4
	mov	dword [ebx+12],esi
	jmp	_565
_564:
	push	dword [ebp-8]
	call	_bbMemAlloc
	add	esp,4
	mov	dword [ebx+12],eax
_565:
	push	0
	push	dword [ebp-8]
	mov	eax,dword [ebx+12]
	add	eax,dword [ebx+20]
	push	eax
	push	dword [ebx+8]
	call	_recv_
	add	esp,16
	cmp	eax,-1
	jne	_566
	mov	eax,0
	jmp	_347
_566:
	add	dword [ebx+20],eax
	jmp	_347
_347:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_SendMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	dword [ebp-4],0
	cmp	dword [esi+8],-1
	jne	_571
	mov	eax,0
	jmp	_350
_571:
	cmp	dword [esi+24],0
	jge	_572
	mov	eax,0
	jmp	_350
_572:
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
	call	dword [_355]
	add	esp,28
	cmp	eax,1
	je	_573
	mov	eax,0
	jmp	_350
_573:
	push	0
	push	dword [esi+24]
	push	dword [esi+16]
	push	dword [esi+8]
	call	_send_
	add	esp,16
	mov	edi,eax
	cmp	edi,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_574
	cmp	edi,0
	sete	al
	movzx	eax,al
_574:
	cmp	eax,0
	je	_576
	mov	eax,0
	jmp	_350
_576:
	cmp	edi,dword [esi+24]
	jne	_578
	push	dword [esi+16]
	call	_bbMemFree
	add	esp,4
	mov	dword [esi+24],0
	jmp	_579
_578:
	mov	eax,dword [esi+24]
	sub	eax,edi
	push	eax
	call	_bbMemAlloc
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [esi+24]
	sub	eax,edi
	push	eax
	mov	eax,dword [esi+16]
	add	eax,edi
	push	eax
	push	ebx
	call	_bbMemCopy
	add	esp,12
	push	dword [esi+16]
	call	_bbMemFree
	add	esp,4
	mov	dword [esi+16],ebx
	sub	dword [esi+24],edi
_579:
	mov	eax,edi
	jmp	_350
_350:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
__bb_TTCPStream_GetState:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	cmp	dword [ebx+8],-1
	jne	_583
	mov	eax,-1
	jmp	_353
_583:
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
	call	dword [_355]
	add	esp,28
	cmp	eax,-1
	jne	_584
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,-1
	jmp	_353
_584:
	cmp	eax,1
	jne	_587
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+176]
	add	esp,4
	cmp	eax,-1
	jne	_589
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,-1
	jmp	_353
_589:
	cmp	eax,0
	jne	_592
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,0
	jmp	_353
_592:
	mov	eax,1
	jmp	_353
_587:
	mov	eax,1
	jmp	_353
_353:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" data writeable align 8
	align	4
_356:
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
	dd	_bbObjectClass
	dd	_bbObjectFree
	dd	_20
	dd	24
	dd	__bb_TSockAddr_New
	dd	__bb_TSockAddr_Delete
	dd	_bbObjectToString
	dd	_bbObjectCompare
	dd	_bbObjectSendMessage
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	_bbObjectReserved
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
	dd	_bbObjectClass
	dd	_bbObjectFree
	dd	_32
	dd	16
	dd	__bb_TICMP_New
	dd	__bb_TICMP_Delete
	dd	_bbObjectToString
	dd	_bbObjectCompare
	dd	_bbObjectSendMessage
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	__bb_TICMP_BuildChecksum
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
_bb_TAdapterInfo:
	dd	_bbObjectClass
	dd	_bbObjectFree
	dd	_42
	dd	28
	dd	__bb_TAdapterInfo_New
	dd	__bb_TAdapterInfo_Delete
	dd	_bbObjectToString
	dd	_bbObjectCompare
	dd	_bbObjectSendMessage
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	_bbObjectReserved
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
_bb_TNetwork:
	dd	_bbObjectClass
	dd	_bbObjectFree
	dd	_51
	dd	8
	dd	__bb_TNetwork_New
	dd	__bb_TNetwork_Delete
	dd	_bbObjectToString
	dd	_bbObjectCompare
	dd	_bbObjectSendMessage
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	__bb_TNetwork_GetHostIP
	dd	__bb_TNetwork_GetHostIPs
	dd	__bb_TNetwork_GetHostName
	dd	__bb_TNetwork_StringIP
	dd	__bb_TNetwork_StringMAC
	dd	__bb_TNetwork_IntIP
	dd	__bb_TNetwork_Ping
	dd	__bb_TNetwork_GetAdapterInfo
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
_bb_TNetStream:
	dd	_brl_stream_TStream
	dd	_bbObjectFree
	dd	_67
	dd	28
	dd	__bb_TNetStream_New
	dd	__bb_TNetStream_Delete
	dd	_bbObjectToString
	dd	_bbObjectCompare
	dd	_bbObjectSendMessage
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	__bb_TNetStream_Eof
	dd	__brl_stream_TIO_Pos
	dd	__bb_TNetStream_Size
	dd	__brl_stream_TIO_Seek
	dd	__bb_TNetStream_Flush
	dd	__bb_TNetStream_Close
	dd	__bb_TNetStream_Read
	dd	__bb_TNetStream_Write
	dd	__brl_stream_TStream_ReadBytes
	dd	__brl_stream_TStream_WriteBytes
	dd	__brl_stream_TStream_SkipBytes
	dd	__brl_stream_TStream_ReadByte
	dd	__brl_stream_TStream_WriteByte
	dd	__brl_stream_TStream_ReadShort
	dd	__brl_stream_TStream_WriteShort
	dd	__brl_stream_TStream_ReadInt
	dd	__brl_stream_TStream_WriteInt
	dd	__brl_stream_TStream_ReadLong
	dd	__brl_stream_TStream_WriteLong
	dd	__brl_stream_TStream_ReadFloat
	dd	__brl_stream_TStream_WriteFloat
	dd	__brl_stream_TStream_ReadDouble
	dd	__brl_stream_TStream_WriteDouble
	dd	__brl_stream_TStream_ReadLine
	dd	__brl_stream_TStream_WriteLine
	dd	__brl_stream_TStream_ReadString
	dd	__brl_stream_TStream_WriteString
	dd	__brl_stream_TStream_ReadObject
	dd	__brl_stream_TStream_WriteObject
	dd	_brl_blitz_NullMethodError
	dd	_brl_blitz_NullMethodError
	dd	_brl_blitz_NullMethodError
	dd	__bb_TNetStream_RecvAvail
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
_bb_TUDPStream:
	dd	_bb_TNetStream
	dd	_bbObjectFree
	dd	_86
	dd	76
	dd	__bb_TUDPStream_New
	dd	__bb_TUDPStream_Delete
	dd	_bbObjectToString
	dd	_bbObjectCompare
	dd	_bbObjectSendMessage
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	__bb_TNetStream_Eof
	dd	__brl_stream_TIO_Pos
	dd	__bb_TNetStream_Size
	dd	__brl_stream_TIO_Seek
	dd	__bb_TNetStream_Flush
	dd	__bb_TNetStream_Close
	dd	__bb_TNetStream_Read
	dd	__bb_TNetStream_Write
	dd	__brl_stream_TStream_ReadBytes
	dd	__brl_stream_TStream_WriteBytes
	dd	__brl_stream_TStream_SkipBytes
	dd	__brl_stream_TStream_ReadByte
	dd	__brl_stream_TStream_WriteByte
	dd	__brl_stream_TStream_ReadShort
	dd	__brl_stream_TStream_WriteShort
	dd	__brl_stream_TStream_ReadInt
	dd	__brl_stream_TStream_WriteInt
	dd	__brl_stream_TStream_ReadLong
	dd	__brl_stream_TStream_WriteLong
	dd	__brl_stream_TStream_ReadFloat
	dd	__brl_stream_TStream_WriteFloat
	dd	__brl_stream_TStream_ReadDouble
	dd	__brl_stream_TStream_WriteDouble
	dd	__brl_stream_TStream_ReadLine
	dd	__brl_stream_TStream_WriteLine
	dd	__brl_stream_TStream_ReadString
	dd	__brl_stream_TStream_WriteString
	dd	__brl_stream_TStream_ReadObject
	dd	__brl_stream_TStream_WriteObject
	dd	__bb_TUDPStream_Init
	dd	__bb_TUDPStream_RecvMsg
	dd	__bb_TUDPStream_SendMsg
	dd	__bb_TNetStream_RecvAvail
	dd	__bb_TUDPStream_SetLocalPort
	dd	__bb_TUDPStream_GetLocalPort
	dd	__bb_TUDPStream_GetLocalIP
	dd	__bb_TUDPStream_SetRemotePort
	dd	__bb_TUDPStream_GetRemotePort
	dd	__bb_TUDPStream_SetRemoteIP
	dd	__bb_TUDPStream_GetRemoteIP
	dd	__bb_TUDPStream_SetBroadcast
	dd	__bb_TUDPStream_GetBroadcast
	dd	__bb_TUDPStream_GetMsgPort
	dd	__bb_TUDPStream_GetMsgIP
	dd	__bb_TUDPStream_SetTimeouts
	dd	__bb_TUDPStream_GetRecvTimeout
	dd	__bb_TUDPStream_GetSendTimeout
	dd	__bb_TUDPStream_SendUDPMsg
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
_bb_TTCPStream:
	dd	_bb_TNetStream
	dd	_bbObjectFree
	dd	_121
	dd	56
	dd	__bb_TTCPStream_New
	dd	__bb_TTCPStream_Delete
	dd	_bbObjectToString
	dd	_bbObjectCompare
	dd	_bbObjectSendMessage
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	_bbObjectReserved
	dd	__bb_TNetStream_Eof
	dd	__brl_stream_TIO_Pos
	dd	__bb_TNetStream_Size
	dd	__brl_stream_TIO_Seek
	dd	__bb_TNetStream_Flush
	dd	__bb_TNetStream_Close
	dd	__bb_TNetStream_Read
	dd	__bb_TNetStream_Write
	dd	__brl_stream_TStream_ReadBytes
	dd	__brl_stream_TStream_WriteBytes
	dd	__brl_stream_TStream_SkipBytes
	dd	__brl_stream_TStream_ReadByte
	dd	__brl_stream_TStream_WriteByte
	dd	__brl_stream_TStream_ReadShort
	dd	__brl_stream_TStream_WriteShort
	dd	__brl_stream_TStream_ReadInt
	dd	__brl_stream_TStream_WriteInt
	dd	__brl_stream_TStream_ReadLong
	dd	__brl_stream_TStream_WriteLong
	dd	__brl_stream_TStream_ReadFloat
	dd	__brl_stream_TStream_WriteFloat
	dd	__brl_stream_TStream_ReadDouble
	dd	__brl_stream_TStream_WriteDouble
	dd	__brl_stream_TStream_ReadLine
	dd	__brl_stream_TStream_WriteLine
	dd	__brl_stream_TStream_ReadString
	dd	__brl_stream_TStream_WriteString
	dd	__brl_stream_TStream_ReadObject
	dd	__brl_stream_TStream_WriteObject
	dd	__bb_TTCPStream_Init
	dd	__bb_TTCPStream_RecvMsg
	dd	__bb_TTCPStream_SendMsg
	dd	__bb_TNetStream_RecvAvail
	dd	__bb_TTCPStream_SetLocalPort
	dd	__bb_TTCPStream_GetLocalPort
	dd	__bb_TTCPStream_GetLocalIP
	dd	__bb_TTCPStream_SetRemotePort
	dd	__bb_TTCPStream_GetRemotePort
	dd	__bb_TTCPStream_SetRemoteIP
	dd	__bb_TTCPStream_GetRemoteIP
	dd	__bb_TTCPStream_SetTimeouts
	dd	__bb_TTCPStream_GetRecvTimeout
	dd	__bb_TTCPStream_GetSendTimeout
	dd	__bb_TTCPStream_GetAcceptTimeout
	dd	__bb_TTCPStream_Connect
	dd	__bb_TTCPStream_Listen
	dd	__bb_TTCPStream_Accept
	dd	__bb_TTCPStream_GetState
	align	4
_355:
	dd	_select_
_363:
	db	"b",0
_396:
	db	"i",0
	align	4
_1:
	dd	_bbStringClass
	dd	2147483647
	dd	0
	align	4
_16:
	dd	_bbStringClass
	dd	2147483647
	dd	1
	dw	45
