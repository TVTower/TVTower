	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_math_math
	extrn	__bb_socket_socket
	extrn	__bb_stdc_stdc
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
	extrn	bbFloatToInt
	extrn	bbFloor
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
	extrn	bbStringFromInt
	extrn	bbStringToCString
	extrn	bind_
	extrn	brl_blitz_NullMethodError
	extrn	brl_stream_TStream
	extrn	closesocket_
	extrn	connect_
	extrn	gethostbyaddr_
	extrn	gethostbyname_
	extrn	getsockname
	extrn	htonl_
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
	public	__bb_source_bnetex
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
	public	_bb_TNetwork_DottedIP
	public	_bb_TNetwork_GetHostIP
	public	_bb_TNetwork_GetHostIPs
	public	_bb_TNetwork_GetHostName
	public	_bb_TNetwork_IntIP
	public	_bb_TNetwork_New
	public	_bb_TNetwork_StringIP
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
	public	_bb_TUDPStream_SetLocalPort
	public	_bb_TUDPStream_SetRemoteIP
	public	_bb_TUDPStream_SetRemotePort
	public	_bb_TUDPStream_SetTimeouts
	public	_bb_TUDPStream_UDPSpeedString
	public	bb_TNetStream
	public	bb_TNetwork
	public	bb_TTCPStream
	public	bb_TUDPStream
	section	"code" executable
__bb_source_bnetex:
	push	ebp
	mov	ebp,esp
	cmp	dword [_293],0
	je	_294
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_294:
	mov	dword [_293],1
	call	__bb_blitz_blitz
	call	__bb_stdc_stdc
	call	__bb_socket_socket
	call	__bb_stream_stream
	call	__bb_math_math
	call	__bb_glmax2d_glmax2d
	push	_2
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
	jmp	_99
_99:
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
	jmp	_102
_102:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSockAddr_Delete:
	push	ebp
	mov	ebp,esp
_105:
	mov	eax,0
	jmp	_295
_295:
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
	jmp	_108
_108:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_Delete:
	push	ebp
	mov	ebp,esp
_111:
	mov	eax,0
	jmp	_296
_296:
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
	jne	_302
	mov	eax,dword [ebp-4]
	cmp	eax,2
	setne	al
	movzx	eax,al
_302:
	cmp	eax,0
	jne	_304
	mov	eax,dword [ebp-8]
	cmp	eax,4
	setne	al
	movzx	eax,al
_304:
	cmp	eax,0
	je	_306
	mov	eax,0
	jmp	_114
_306:
	cmp	dword [edx],0
	je	_307
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
	jmp	_114
_307:
	mov	eax,0
	jmp	_114
_114:
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
	jne	_317
	mov	eax,dword [ebp-4]
	cmp	eax,2
	setne	al
	movzx	eax,al
_317:
	cmp	eax,0
	jne	_319
	mov	eax,dword [ebp-8]
	cmp	eax,4
	setne	al
	movzx	eax,al
_319:
	cmp	eax,0
	je	_321
	mov	eax,bbEmptyArray
	jmp	_117
_321:
	mov	ebx,0
	jmp	_3
_5:
	add	ebx,1
_3:
	mov	eax,dword [ebp-12]
	cmp	dword [eax+ebx*4],0
	jne	_5
_4:
	push	ebx
	push	_322
	call	bbArrayNew1D
	add	esp,8
	mov	edx,eax
	mov	eax,0
	mov	edi,ebx
	jmp	_323
_8:
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
_6:
	add	eax,1
_323:
	cmp	eax,edi
	jl	_8
_7:
	mov	eax,edx
	jmp	_117
_117:
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
	je	_327
	push	eax
	call	bbStringFromCString
	add	esp,4
	jmp	_120
_327:
	mov	eax,_1
	jmp	_120
_120:
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
	jmp	_123
_123:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_DottedIP:
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
	jmp	_126
_126:
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
	jmp	_129
_129:
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
	jmp	_132
_132:
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
	jle	_332
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
_332:
	cmp	dword [ebx+24],0
	jle	_333
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
_333:
_135:
	mov	dword [ebx],brl_stream_TStream
	push	ebx
	call	_brl_stream_TStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_334
_334:
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
	jle	_336
	mov	edi,dword [esi+20]
_336:
	cmp	edi,0
	jle	_337
	push	edi
	push	dword [esi+12]
	push	eax
	call	bbMemCopy
	add	esp,12
	cmp	edi,dword [esi+20]
	jge	_338
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
	jmp	_339
_338:
	push	dword [esi+12]
	call	bbMemFree
	add	esp,4
	mov	dword [esi+20],0
_339:
_337:
	mov	eax,edi
	jmp	_140
_140:
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
	jg	_341
	mov	eax,0
	jmp	_145
_341:
	mov	eax,dword [esi+24]
	add	eax,edi
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	ebx,eax
	cmp	dword [esi+24],0
	jle	_342
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
	jmp	_343
_342:
	push	edi
	push	dword [ebp+12]
	push	ebx
	call	bbMemCopy
	add	esp,12
	mov	dword [esi+16],ebx
	mov	dword [esi+24],edi
_343:
	mov	eax,edi
	jmp	_145
_145:
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
	jmp	_148
_148:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Size:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+20]
	jmp	_151
_151:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Flush:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	cmp	dword [ebx+20],0
	jle	_344
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
_344:
	cmp	dword [ebx+24],0
	jle	_345
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
_345:
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	eax,0
	jmp	_154
_154:
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
	je	_346
	push	2
	push	dword [ebx+8]
	call	shutdown_
	add	esp,8
	push	dword [ebx+8]
	call	closesocket_
	add	esp,4
	mov	dword [ebx+8],-1
_346:
	mov	eax,0
	jmp	_157
_157:
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
	jne	_348
	mov	eax,-1
	jmp	_160
_348:
	lea	eax,dword [ebp-4]
	push	eax
	push	21531
	push	dword [edx+8]
	call	ioctl
	add	esp,12
	cmp	eax,-1
	jne	_349
	mov	eax,-1
	jmp	_160
_349:
	mov	eax,dword [ebp-4]
	jmp	_160
_160:
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
	jmp	_163
_163:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_166:
	mov	dword [eax],bb_TNetStream
	push	eax
	call	_bb_TNetStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_351
_351:
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
	jne	_353
	mov	eax,0
	jmp	_169
_353:
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
	jne	_354
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
_354:
	cmp	eax,0
	je	_356
	push	dword [ebx+8]
	call	closesocket_
	add	esp,4
	mov	eax,0
	jmp	_169
_356:
	mov	eax,1
	jmp	_169
_169:
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
	jne	_359
	mov	eax,0
	jmp	_173
_359:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	push	eax
	push	2
	push	dword [ebx+8]
	call	bind_
	add	esp,12
	cmp	eax,-1
	jne	_360
	mov	eax,0
	jmp	_173
_360:
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
	jne	_362
	mov	eax,0
	jmp	_173
_362:
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
	jmp	_173
_173:
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
	jmp	_176
_176:
	movzx	eax,word [ebp-4]
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetLocalIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	jmp	_179
_179:
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
	jmp	_183
_183:
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
	jmp	_186
_186:
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
	jmp	_190
_190:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetRemoteIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+36]
	jmp	_193
_193:
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
	jmp	_196
_196:
	movzx	eax,word [ebp-4]
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetMsgIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+40]
	jmp	_199
_199:
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
	jmp	_204
_204:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetRecvTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+48]
	jmp	_207
_207:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetSendTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	jmp	_210
_210:
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
	jne	_370
	mov	edx,0
	jmp	_213
_370:
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
	je	_371
	mov	edx,0
	jmp	_213
_371:
	lea	eax,dword [ebp-8]
	push	eax
	push	21531
	push	dword [esi+8]
	call	ioctl
	add	esp,12
	cmp	eax,-1
	jne	_372
	mov	edx,0
	jmp	_213
_372:
	cmp	dword [ebp-8],0
	jg	_373
	mov	edx,0
	jmp	_213
_373:
	cmp	dword [esi+20],0
	jle	_374
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
	jne	_375
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
_375:
	fld	dword [esi+60]
	mov	eax,dword [esi+20]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	faddp	st1,st0
	fstp	dword [esi+60]
	jmp	_376
_374:
	push	dword [ebp-8]
	call	bbMemAlloc
	add	esp,4
	mov	dword [esi+12],eax
_376:
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
	jne	_377
	cmp	edx,0
	sete	al
	movzx	eax,al
_377:
	cmp	eax,0
	je	_379
	mov	edx,0
	jmp	_213
_379:
	mov	eax,dword [ebp-12]
	mov	dword [esi+40],eax
	mov	eax,dword [ebp-16]
	and	eax,0xffff
	mov	eax,eax
	mov	word [esi+44],ax
	add	dword [esi+20],edx
	jmp	_213
_213:
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
	mov	esi,dword [ebp+8]
	mov	edx,dword [ebp+12]
	movzx	eax,word [ebp+16]
	mov	eax,eax
	mov	word [ebp-4],ax
	mov	ebx,dword [esi+36]
	movzx	eax,word [esi+34]
	mov	eax,eax
	mov	word [ebp-8],ax
	mov	dword [esi+36],edx
	movzx	eax,word [ebp-4]
	mov	eax,eax
	mov	word [esi+34],ax
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+172]
	add	esp,4
	mov	edx,eax
	mov	dword [esi+36],ebx
	movzx	eax,word [ebp-8]
	mov	eax,eax
	mov	word [esi+34],ax
	jmp	_218
_218:
	mov	eax,edx
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
	jne	_388
	mov	eax,dword [ebx+24]
	cmp	eax,0
	sete	al
	movzx	eax,al
_388:
	cmp	eax,0
	je	_390
	mov	eax,0
	jmp	_221
_390:
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
	je	_391
	mov	eax,0
	jmp	_221
_391:
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
	jne	_392
	cmp	edi,0
	sete	al
	movzx	eax,al
_392:
	cmp	eax,0
	je	_394
	mov	eax,0
	jmp	_221
_394:
	cmp	edi,dword [ebx+24]
	jne	_396
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
	mov	dword [ebx+24],0
	jmp	_397
_396:
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
	jne	_398
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
_398:
	fld	dword [ebx+64]
	mov	eax,dword [ebx+24]
	sub	eax,edi
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	faddp	st1,st0
	fstp	dword [ebx+64]
_397:
	mov	eax,edi
	jmp	_221
_221:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_UDPSpeedString:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	edx,dword [ebp+8]
	fld	dword [edx+68]
	fld	dword [_614]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setbe	al
	movzx	eax,al
	cmp	eax,0
	jne	_399
	push	_9
	mov	ebx,10
	fld	dword [edx+68]
	fmul	dword [_615]
	fdiv	dword [_616]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	cdq
	idiv	ebx
	push	eax
	call	bbStringFromInt
	add	esp,4
	push	eax
	call	bbStringConcat
	add	esp,8
	jmp	_224
_399:
	fld	dword [edx+68]
	fld	dword [_617]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	seta	al
	movzx	eax,al
	cmp	eax,0
	jne	_400
	push	_10
	fld	dword [edx+68]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	call	bbStringFromInt
	add	esp,4
	push	eax
	call	bbStringConcat
	add	esp,8
	jmp	_224
_400:
	mov	eax,bbEmptyString
	jmp	_224
_224:
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
	jmp	_227
_227:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_230:
	mov	dword [eax],bb_TNetStream
	push	eax
	call	_bb_TNetStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_401
_401:
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
	jne	_403
	mov	eax,0
	jmp	_233
_403:
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
	jne	_404
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
_404:
	cmp	eax,0
	je	_406
	push	dword [ebx+8]
	call	closesocket_
	add	esp,4
	mov	eax,0
	jmp	_233
_406:
	mov	eax,1
	jmp	_233
_233:
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
	jne	_409
	mov	eax,0
	jmp	_237
_409:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	push	eax
	push	2
	push	dword [ebx+8]
	call	bind_
	add	esp,12
	cmp	eax,-1
	jne	_410
	mov	eax,0
	jmp	_237
_410:
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
	jne	_412
	mov	eax,0
	jmp	_237
_412:
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
	jmp	_237
_237:
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
	jmp	_240
_240:
	movzx	eax,word [ebp-4]
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetLocalIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	jmp	_243
_243:
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
	jmp	_247
_247:
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
	jmp	_250
_250:
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
	jmp	_254
_254:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetRemoteIP:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+36]
	jmp	_257
_257:
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
	jmp	_263
_263:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetRecvTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+44]
	jmp	_266
_266:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetSendTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+48]
	jmp	_269
_269:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetAcceptTimeout:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	jmp	_272
_272:
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
	jne	_415
	mov	eax,0
	jmp	_275
_415:
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
	jne	_416
	mov	eax,0
	jmp	_275
_416:
	mov	eax,1
	jmp	_275
_275:
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
	jne	_418
	mov	eax,0
	jmp	_279
_418:
	push	eax
	push	dword [edx+8]
	call	listen_
	add	esp,8
	cmp	eax,-1
	jne	_419
	mov	eax,0
	jmp	_279
_419:
	mov	eax,1
	jmp	_279
_279:
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
	jne	_426
	mov	ebx,bbNullObject
	jmp	_282
_426:
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
	je	_427
	mov	ebx,bbNullObject
	jmp	_282
_427:
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
	jne	_428
	mov	ebx,bbNullObject
	jmp	_282
_428:
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
	jne	_429
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	ebx,bbNullObject
	jmp	_282
_429:
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
	jmp	_282
_282:
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
	jne	_435
	mov	eax,0
	jmp	_285
_435:
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
	je	_436
	mov	eax,0
	jmp	_285
_436:
	lea	eax,dword [ebp-8]
	push	eax
	push	21531
	push	dword [ebx+8]
	call	ioctl
	add	esp,12
	cmp	eax,-1
	jne	_437
	mov	eax,0
	jmp	_285
_437:
	cmp	dword [ebp-8],0
	jg	_438
	mov	eax,0
	jmp	_285
_438:
	cmp	dword [ebx+20],0
	jle	_439
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
	jmp	_440
_439:
	push	dword [ebp-8]
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebx+12],eax
_440:
	push	0
	push	dword [ebp-8]
	mov	eax,dword [ebx+12]
	add	eax,dword [ebx+20]
	push	eax
	push	dword [ebx+8]
	call	recv_
	add	esp,16
	cmp	eax,-1
	jne	_441
	mov	eax,0
	jmp	_285
_441:
	add	dword [ebx+20],eax
	jmp	_285
_285:
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
	jne	_446
	mov	eax,0
	jmp	_288
_446:
	cmp	dword [esi+24],0
	jge	_447
	mov	eax,0
	jmp	_288
_447:
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
	je	_448
	mov	eax,0
	jmp	_288
_448:
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
	jne	_449
	cmp	edi,0
	sete	al
	movzx	eax,al
_449:
	cmp	eax,0
	je	_451
	mov	eax,0
	jmp	_288
_451:
	cmp	edi,dword [esi+24]
	jne	_453
	push	dword [esi+16]
	call	bbMemFree
	add	esp,4
	mov	dword [esi+24],0
	jmp	_454
_453:
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
_454:
	mov	eax,edi
	jmp	_288
_288:
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
	jne	_458
	mov	eax,-1
	jmp	_291
_458:
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
	jne	_459
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,-1
	jmp	_291
_459:
	cmp	eax,1
	jne	_462
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+176]
	add	esp,4
	cmp	eax,-1
	jne	_464
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,-1
	jmp	_291
_464:
	cmp	eax,0
	jne	_467
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,0
	jmp	_291
_467:
	mov	eax,1
	jmp	_291
_462:
	mov	eax,1
	jmp	_291
_291:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_293:
	dd	0
_12:
	db	"TSockAddr",0
_13:
	db	"SinFamily",0
_14:
	db	"s",0
_15:
	db	"SinPort",0
_16:
	db	"SinAddr",0
_17:
	db	"i",0
_18:
	db	"SinZero",0
_19:
	db	"l",0
_20:
	db	"New",0
_21:
	db	"()i",0
_22:
	db	"Delete",0
	align	4
_11:
	dd	2
	dd	_12
	dd	3
	dd	_13
	dd	_14
	dd	8
	dd	3
	dd	_15
	dd	_14
	dd	10
	dd	3
	dd	_16
	dd	_17
	dd	12
	dd	3
	dd	_18
	dd	_19
	dd	16
	dd	6
	dd	_20
	dd	_21
	dd	16
	dd	6
	dd	_22
	dd	_21
	dd	20
	dd	0
	align	4
_2:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_11
	dd	24
	dd	_bb_TSockAddr_New
	dd	_bb_TSockAddr_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
_24:
	db	"TNetwork",0
_25:
	db	"GetHostIP",0
_26:
	db	"($)i",0
_27:
	db	"GetHostIPs",0
_28:
	db	"($)[]i",0
_29:
	db	"GetHostName",0
_30:
	db	"(i)$",0
_31:
	db	"StringIP",0
_32:
	db	"DottedIP",0
_33:
	db	"IntIP",0
	align	4
_23:
	dd	2
	dd	_24
	dd	6
	dd	_20
	dd	_21
	dd	16
	dd	6
	dd	_22
	dd	_21
	dd	20
	dd	7
	dd	_25
	dd	_26
	dd	48
	dd	7
	dd	_27
	dd	_28
	dd	52
	dd	7
	dd	_29
	dd	_30
	dd	56
	dd	7
	dd	_31
	dd	_30
	dd	60
	dd	7
	dd	_32
	dd	_30
	dd	64
	dd	7
	dd	_33
	dd	_26
	dd	68
	dd	0
	align	4
bb_TNetwork:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_23
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
	dd	_bb_TNetwork_DottedIP
	dd	_bb_TNetwork_IntIP
_35:
	db	"TNetStream",0
_36:
	db	"Socket",0
_37:
	db	"RecvBuffer",0
_38:
	db	"*b",0
_39:
	db	"SendBuffer",0
_40:
	db	"RecvSize",0
_41:
	db	"SendSize",0
_42:
	db	"Init",0
_43:
	db	"RecvMsg",0
_44:
	db	"Read",0
_45:
	db	"(*b,i)i",0
_46:
	db	"SendMsg",0
_47:
	db	"Write",0
_48:
	db	"Eof",0
_49:
	db	"Size",0
_50:
	db	"Flush",0
_51:
	db	"Close",0
_52:
	db	"RecvAvail",0
	align	4
_34:
	dd	2
	dd	_35
	dd	3
	dd	_36
	dd	_17
	dd	8
	dd	3
	dd	_37
	dd	_38
	dd	12
	dd	3
	dd	_39
	dd	_38
	dd	16
	dd	3
	dd	_40
	dd	_17
	dd	20
	dd	3
	dd	_41
	dd	_17
	dd	24
	dd	6
	dd	_20
	dd	_21
	dd	16
	dd	6
	dd	_22
	dd	_21
	dd	20
	dd	6
	dd	_42
	dd	_21
	dd	164
	dd	6
	dd	_43
	dd	_21
	dd	168
	dd	6
	dd	_44
	dd	_45
	dd	72
	dd	6
	dd	_46
	dd	_21
	dd	172
	dd	6
	dd	_47
	dd	_45
	dd	76
	dd	6
	dd	_48
	dd	_21
	dd	48
	dd	6
	dd	_49
	dd	_21
	dd	56
	dd	6
	dd	_50
	dd	_21
	dd	64
	dd	6
	dd	_51
	dd	_21
	dd	68
	dd	6
	dd	_52
	dd	_21
	dd	176
	dd	0
	align	4
bb_TNetStream:
	dd	brl_stream_TStream
	dd	bbObjectFree
	dd	_34
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
_54:
	db	"TUDPStream",0
_55:
	db	"LocalIP",0
_56:
	db	"LocalPort",0
_57:
	db	"RemotePort",0
_58:
	db	"RemoteIP",0
_59:
	db	"MessageIP",0
_60:
	db	"MessagePort",0
_61:
	db	"RecvTimeout",0
_62:
	db	"SendTimeout",0
_63:
	db	"fSpeed",0
_64:
	db	"f",0
_65:
	db	"fDataGot",0
_66:
	db	"fDataSent",0
_67:
	db	"fDataSum",0
_68:
	db	"fLastSecond",0
_69:
	db	"SetLocalPort",0
_70:
	db	"(s)i",0
_71:
	db	"GetLocalPort",0
_72:
	db	"()s",0
_73:
	db	"GetLocalIP",0
_74:
	db	"SetRemotePort",0
_75:
	db	"GetRemotePort",0
_76:
	db	"SetRemoteIP",0
_77:
	db	"(i)i",0
_78:
	db	"GetRemoteIP",0
_79:
	db	"GetMsgPort",0
_80:
	db	"GetMsgIP",0
_81:
	db	"SetTimeouts",0
_82:
	db	"(i,i)i",0
_83:
	db	"GetRecvTimeout",0
_84:
	db	"GetSendTimeout",0
_85:
	db	"SendUDPMsg",0
_86:
	db	"(i,s)i",0
_87:
	db	"UDPSpeedString",0
_88:
	db	"()$",0
	align	4
_53:
	dd	2
	dd	_54
	dd	3
	dd	_55
	dd	_17
	dd	28
	dd	3
	dd	_56
	dd	_14
	dd	32
	dd	3
	dd	_57
	dd	_14
	dd	34
	dd	3
	dd	_58
	dd	_17
	dd	36
	dd	3
	dd	_59
	dd	_17
	dd	40
	dd	3
	dd	_60
	dd	_14
	dd	44
	dd	3
	dd	_61
	dd	_17
	dd	48
	dd	3
	dd	_62
	dd	_17
	dd	52
	dd	3
	dd	_63
	dd	_64
	dd	56
	dd	3
	dd	_65
	dd	_64
	dd	60
	dd	3
	dd	_66
	dd	_64
	dd	64
	dd	3
	dd	_67
	dd	_64
	dd	68
	dd	3
	dd	_68
	dd	_64
	dd	72
	dd	6
	dd	_20
	dd	_21
	dd	16
	dd	6
	dd	_22
	dd	_21
	dd	20
	dd	6
	dd	_42
	dd	_21
	dd	164
	dd	6
	dd	_69
	dd	_70
	dd	180
	dd	6
	dd	_71
	dd	_72
	dd	184
	dd	6
	dd	_73
	dd	_21
	dd	188
	dd	6
	dd	_74
	dd	_70
	dd	192
	dd	6
	dd	_75
	dd	_72
	dd	196
	dd	6
	dd	_76
	dd	_77
	dd	200
	dd	6
	dd	_78
	dd	_21
	dd	204
	dd	6
	dd	_79
	dd	_72
	dd	208
	dd	6
	dd	_80
	dd	_21
	dd	212
	dd	6
	dd	_81
	dd	_82
	dd	216
	dd	6
	dd	_83
	dd	_21
	dd	220
	dd	6
	dd	_84
	dd	_21
	dd	224
	dd	6
	dd	_43
	dd	_21
	dd	168
	dd	6
	dd	_85
	dd	_86
	dd	228
	dd	6
	dd	_46
	dd	_21
	dd	172
	dd	6
	dd	_87
	dd	_88
	dd	232
	dd	0
	align	4
bb_TUDPStream:
	dd	bb_TNetStream
	dd	bbObjectFree
	dd	_53
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
	dd	_bb_TUDPStream_GetMsgPort
	dd	_bb_TUDPStream_GetMsgIP
	dd	_bb_TUDPStream_SetTimeouts
	dd	_bb_TUDPStream_GetRecvTimeout
	dd	_bb_TUDPStream_GetSendTimeout
	dd	_bb_TUDPStream_SendUDPMsg
	dd	_bb_TUDPStream_UDPSpeedString
_90:
	db	"TTCPStream",0
_91:
	db	"AcceptTimeout",0
_92:
	db	"(i,i,i)i",0
_93:
	db	"GetAcceptTimeout",0
_94:
	db	"Connect",0
_95:
	db	"Listen",0
_96:
	db	"Accept",0
_97:
	db	"():TTCPStream",0
_98:
	db	"GetState",0
	align	4
_89:
	dd	2
	dd	_90
	dd	3
	dd	_55
	dd	_17
	dd	28
	dd	3
	dd	_56
	dd	_14
	dd	32
	dd	3
	dd	_58
	dd	_17
	dd	36
	dd	3
	dd	_57
	dd	_14
	dd	40
	dd	3
	dd	_61
	dd	_17
	dd	44
	dd	3
	dd	_62
	dd	_17
	dd	48
	dd	3
	dd	_91
	dd	_17
	dd	52
	dd	6
	dd	_20
	dd	_21
	dd	16
	dd	6
	dd	_22
	dd	_21
	dd	20
	dd	6
	dd	_42
	dd	_21
	dd	164
	dd	6
	dd	_69
	dd	_70
	dd	180
	dd	6
	dd	_71
	dd	_72
	dd	184
	dd	6
	dd	_73
	dd	_21
	dd	188
	dd	6
	dd	_74
	dd	_70
	dd	192
	dd	6
	dd	_75
	dd	_72
	dd	196
	dd	6
	dd	_76
	dd	_77
	dd	200
	dd	6
	dd	_78
	dd	_21
	dd	204
	dd	6
	dd	_81
	dd	_92
	dd	208
	dd	6
	dd	_83
	dd	_21
	dd	212
	dd	6
	dd	_84
	dd	_21
	dd	216
	dd	6
	dd	_93
	dd	_21
	dd	220
	dd	6
	dd	_94
	dd	_21
	dd	224
	dd	6
	dd	_95
	dd	_77
	dd	228
	dd	6
	dd	_96
	dd	_97
	dd	232
	dd	6
	dd	_43
	dd	_21
	dd	168
	dd	6
	dd	_46
	dd	_21
	dd	172
	dd	6
	dd	_98
	dd	_21
	dd	236
	dd	0
	align	4
bb_TTCPStream:
	dd	bb_TNetStream
	dd	bbObjectFree
	dd	_89
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
_322:
	db	"i",0
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_614:
	dd	0x44800000
	align	4
_9:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	107,98,47,115
	align	4
_615:
	dd	0x41200000
	align	4
_616:
	dd	0x44800000
	align	4
_617:
	dd	0x44800000
	align	4
_10:
	dd	bbStringClass
	dd	2147483647
	dd	3
	dw	98,47,115
