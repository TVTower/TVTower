	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_math_math
	extrn	__bb_socket_socket
	extrn	__bb_stdc_stdc
	extrn	__bb_stream_stream
	extrn	_brl_stream_TIO_Delete
	extrn	_brl_stream_TIO_Pos
	extrn	_brl_stream_TIO_Seek
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
	extrn	bbObjectDtor
	extrn	bbObjectFree
	extrn	bbObjectNew
	extrn	bbObjectRegisterType
	extrn	bbObjectReserved
	extrn	bbObjectSendMessage
	extrn	bbObjectToString
	extrn	bbOnDebugEnterScope
	extrn	bbOnDebugEnterStm
	extrn	bbOnDebugLeaveScope
	extrn	bbStringClass
	extrn	bbStringConcat
	extrn	bbStringFromCString
	extrn	bbStringFromInt
	extrn	bbStringToCString
	extrn	bind_
	extrn	brl_blitz_ArrayBoundsError
	extrn	brl_blitz_NullMethodError
	extrn	brl_blitz_NullObjectError
	extrn	brl_stream_TIO
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
	public	_bb_TNetwork_DottedIP
	public	_bb_TNetwork_GetHostIP
	public	_bb_TNetwork_GetHostIPs
	public	_bb_TNetwork_GetHostName
	public	_bb_TNetwork_IntIP
	public	_bb_TNetwork_New
	public	_bb_TNetwork_StringIP
	public	_bb_TSockAddr_New
	public	_bb_TTCPStream_Accept
	public	_bb_TTCPStream_Connect
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
	push	ebx
	cmp	dword [_293],0
	je	_294
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_294:
	mov	dword [_293],1
	push	ebp
	push	_281
	call	dword [bbOnDebugEnterScope]
	add	esp,8
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
	mov	ebx,0
	jmp	_99
_99:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSockAddr_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_296
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],_2
	mov	eax,dword [ebp-4]
	mov	word [eax+8],0
	mov	eax,dword [ebp-4]
	mov	word [eax+10],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],0
	push	ebp
	push	_295
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_102
_102:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_300
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TNetwork
	push	ebp
	push	_299
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_105
_105:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_GetHostIP:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	push	ebp
	push	_328
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_302
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	push	_307
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	push	_310
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	lea	eax,dword [ebp-16]
	push	eax
	lea	eax,dword [ebp-12]
	push	eax
	push	dword [ebp-4]
	call	gethostbyname_
	add	esp,12
	mov	dword [ebp-8],eax
	push	_311
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	cmp	eax,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_312
	mov	eax,dword [ebp-12]
	cmp	eax,2
	setne	al
	movzx	eax,al
_312:
	cmp	eax,0
	jne	_314
	mov	eax,dword [ebp-16]
	cmp	eax,4
	setne	al
	movzx	eax,al
_314:
	cmp	eax,0
	je	_316
	push	ebp
	push	_318
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_317
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_108
_316:
	push	_319
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	cmp	dword [eax],0
	je	_320
	push	ebp
	push	_324
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_321
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax]
	mov	dword [ebp-20],eax
	push	_322
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-20]
	movzx	eax,byte [eax]
	mov	edx,eax
	shl	edx,24
	mov	eax,dword [ebp-20]
	movzx	eax,byte [eax+1]
	mov	eax,eax
	shl	eax,16
	or	edx,eax
	mov	eax,dword [ebp-20]
	movzx	eax,byte [eax+2]
	mov	eax,eax
	shl	eax,8
	or	edx,eax
	mov	eax,dword [ebp-20]
	movzx	eax,byte [eax+3]
	mov	eax,eax
	or	edx,eax
	mov	dword [ebp-24],edx
	push	_323
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	call	dword [bbOnDebugLeaveScope]
	jmp	_108
_320:
	push	ebp
	push	_327
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_326
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_108
_108:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_GetHostIPs:
	push	ebp
	mov	ebp,esp
	sub	esp,36
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	mov	dword [ebp-24],bbEmptyArray
	mov	dword [ebp-28],0
	mov	dword [ebp-32],0
	mov	dword [ebp-36],0
	push	ebp
	push	_374
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_337
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	push	_341
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	mov	dword [ebp-24],bbEmptyArray
	mov	dword [ebp-28],0
	push	_345
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],0
	mov	dword [ebp-36],0
	push	_348
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	lea	eax,dword [ebp-16]
	push	eax
	lea	eax,dword [ebp-12]
	push	eax
	push	dword [ebp-4]
	call	gethostbyname_
	add	esp,12
	mov	dword [ebp-8],eax
	push	_349
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	cmp	eax,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_350
	mov	eax,dword [ebp-12]
	cmp	eax,2
	setne	al
	movzx	eax,al
_350:
	cmp	eax,0
	jne	_352
	mov	eax,dword [ebp-16]
	cmp	eax,4
	setne	al
	movzx	eax,al
_352:
	cmp	eax,0
	je	_354
	push	ebp
	push	_356
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_355
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbEmptyArray
	call	dword [bbOnDebugLeaveScope]
	jmp	_111
_354:
	push	_357
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	push	_358
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_3
_5:
	push	ebp
	push	_360
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_359
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [ebp-20],1
	call	dword [bbOnDebugLeaveScope]
_3:
	mov	edx,dword [ebp-8]
	mov	eax,dword [ebp-20]
	cmp	dword [edx+eax*4],0
	jne	_5
_4:
	push	_361
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-20]
	push	_362
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebp-24],eax
	push	_363
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-28],0
	mov	ebx,dword [ebp-20]
	jmp	_364
_8:
	push	ebp
	push	_372
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_366
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edx,dword [ebp-8]
	mov	eax,dword [ebp-28]
	mov	eax,dword [edx+eax*4]
	mov	dword [ebp-32],eax
	push	_367
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	movzx	eax,byte [eax]
	mov	edx,eax
	shl	edx,24
	mov	eax,dword [ebp-32]
	movzx	eax,byte [eax+1]
	mov	eax,eax
	shl	eax,16
	or	edx,eax
	mov	eax,dword [ebp-32]
	movzx	eax,byte [eax+2]
	mov	eax,eax
	shl	eax,8
	or	edx,eax
	mov	eax,dword [ebp-32]
	movzx	eax,byte [eax+3]
	mov	eax,eax
	or	edx,eax
	mov	dword [ebp-36],edx
	push	_368
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-28]
	mov	eax,dword [ebp-24]
	cmp	esi,dword [eax+20]
	jb	_370
	call	brl_blitz_ArrayBoundsError
_370:
	mov	eax,dword [ebp-24]
	shl	esi,2
	add	eax,esi
	mov	edx,dword [ebp-36]
	mov	dword [eax+24],edx
	call	dword [bbOnDebugLeaveScope]
_6:
	add	dword [ebp-28],1
_364:
	cmp	dword [ebp-28],ebx
	jl	_8
_7:
	push	_373
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	jmp	_111
_111:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_GetHostName:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	push	ebp
	push	_391
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_379
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	push	_382
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	htonl_
	add	esp,4
	mov	dword [ebp-8],eax
	push	_383
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	2
	push	4
	lea	eax,dword [ebp-8]
	push	eax
	call	gethostbyaddr_
	add	esp,12
	mov	dword [ebp-12],eax
	push	_384
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	je	_385
	push	ebp
	push	_387
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_386
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	call	bbStringFromCString
	add	esp,4
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_114
_385:
	push	ebp
	push	_390
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_389
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,_1
	call	dword [bbOnDebugLeaveScope]
	jmp	_114
_114:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_StringIP:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_395
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_394
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	htonl_
	add	esp,4
	push	eax
	call	inet_ntoa
	add	esp,4
	push	eax
	call	bbStringFromCString
	add	esp,4
	mov	ebx,eax
	jmp	_117
_117:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_DottedIP:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_398
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_397
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	htonl_
	add	esp,4
	push	eax
	call	inet_ntoa
	add	esp,4
	push	eax
	call	bbStringFromCString
	add	esp,4
	mov	ebx,eax
	jmp	_120
_120:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetwork_IntIP:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_402
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_399
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
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
	mov	ebx,eax
	jmp	_123
_123:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_424
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	_brl_stream_TStream_New
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TNetStream
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+24],0
	push	ebp
	push	_423
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_403
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_405
	call	brl_blitz_NullObjectError
_405:
	mov	dword [ebx+8],-1
	push	_407
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_409
	call	brl_blitz_NullObjectError
_409:
	mov	dword [ebx+12],0
	push	_411
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_413
	call	brl_blitz_NullObjectError
_413:
	mov	dword [ebx+16],0
	push	_415
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_417
	call	brl_blitz_NullObjectError
_417:
	mov	dword [ebx+20],0
	push	_419
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_421
	call	brl_blitz_NullObjectError
_421:
	mov	dword [ebx+24],0
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_126
_126:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
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
	jle	_427
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
_427:
	cmp	dword [ebx+24],0
	jle	_428
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
_428:
_129:
	mov	dword [ebx],brl_stream_TIO
	push	ebx
	call	_brl_stream_TIO_Delete
	add	esp,4
	mov	eax,0
	jmp	_429
_429:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Read:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	dword [ebp-16],0
	push	ebp
	push	_480
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_430
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],0
	push	_432
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_434
	call	brl_blitz_NullObjectError
_434:
	mov	eax,dword [ebx+20]
	cmp	dword [ebp-12],eax
	jle	_435
	push	ebp
	push	_439
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_436
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_438
	call	brl_blitz_NullObjectError
_438:
	mov	eax,dword [ebx+20]
	mov	dword [ebp-12],eax
	call	dword [bbOnDebugLeaveScope]
_435:
	push	_440
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	jle	_441
	push	ebp
	push	_478
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_442
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_444
	call	brl_blitz_NullObjectError
_444:
	push	dword [ebp-12]
	push	dword [ebx+12]
	push	dword [ebp-8]
	call	bbMemCopy
	add	esp,12
	push	_445
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_447
	call	brl_blitz_NullObjectError
_447:
	mov	eax,dword [ebx+20]
	cmp	dword [ebp-12],eax
	jge	_448
	push	ebp
	push	_468
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_449
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_451
	call	brl_blitz_NullObjectError
_451:
	mov	eax,dword [ebx+20]
	sub	eax,dword [ebp-12]
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebp-16],eax
	push	_452
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_454
	call	brl_blitz_NullObjectError
_454:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_456
	call	brl_blitz_NullObjectError
_456:
	mov	eax,dword [esi+20]
	sub	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebx+12]
	add	eax,dword [ebp-12]
	push	eax
	push	dword [ebp-16]
	call	bbMemCopy
	add	esp,12
	push	_457
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_459
	call	brl_blitz_NullObjectError
_459:
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
	push	_460
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_462
	call	brl_blitz_NullObjectError
_462:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+12],eax
	push	_464
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_466
	call	brl_blitz_NullObjectError
_466:
	mov	eax,dword [ebp-12]
	sub	dword [ebx+20],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_469
_448:
	push	ebp
	push	_477
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_470
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_472
	call	brl_blitz_NullObjectError
_472:
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
	push	_473
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_475
	call	brl_blitz_NullObjectError
_475:
	mov	dword [ebx+20],0
	call	dword [bbOnDebugLeaveScope]
_469:
	call	dword [bbOnDebugLeaveScope]
_441:
	push	_479
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_134
_134:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Write:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	dword [ebp-16],0
	push	ebp
	push	_528
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_483
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],0
	push	_485
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	jg	_486
	push	ebp
	push	_488
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_487
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_139
_486:
	push	_489
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_491
	call	brl_blitz_NullObjectError
_491:
	mov	eax,dword [ebx+24]
	add	eax,dword [ebp-12]
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebp-16],eax
	push	_492
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_494
	call	brl_blitz_NullObjectError
_494:
	cmp	dword [ebx+24],0
	jle	_495
	push	ebp
	push	_515
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_496
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_498
	call	brl_blitz_NullObjectError
_498:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_500
	call	brl_blitz_NullObjectError
_500:
	push	dword [ebx+24]
	push	dword [esi+16]
	push	dword [ebp-16]
	call	bbMemCopy
	add	esp,12
	push	_501
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_503
	call	brl_blitz_NullObjectError
_503:
	push	dword [ebp-12]
	push	dword [ebp-8]
	mov	eax,dword [ebp-16]
	add	eax,dword [ebx+24]
	push	eax
	call	bbMemCopy
	add	esp,12
	push	_504
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_506
	call	brl_blitz_NullObjectError
_506:
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
	push	_507
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_509
	call	brl_blitz_NullObjectError
_509:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+16],eax
	push	_511
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_513
	call	brl_blitz_NullObjectError
_513:
	mov	eax,dword [ebp-12]
	add	dword [ebx+24],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_516
_495:
	push	ebp
	push	_526
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_517
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	push	dword [ebp-8]
	push	dword [ebp-16]
	call	bbMemCopy
	add	esp,12
	push	_518
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_520
	call	brl_blitz_NullObjectError
_520:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+16],eax
	push	_522
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_524
	call	brl_blitz_NullObjectError
_524:
	mov	eax,dword [ebp-12]
	mov	dword [ebx+24],eax
	call	dword [bbOnDebugLeaveScope]
_516:
	push	_527
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_139
_139:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Eof:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_532
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_529
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_531
	call	brl_blitz_NullObjectError
_531:
	mov	eax,dword [ebx+20]
	cmp	eax,0
	sete	al
	movzx	eax,al
	mov	ebx,eax
	jmp	_142
_142:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Size:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_536
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_533
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_535
	call	brl_blitz_NullObjectError
_535:
	mov	ebx,dword [ebx+20]
	jmp	_145
_145:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Flush:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_561
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_537
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_539
	call	brl_blitz_NullObjectError
_539:
	cmp	dword [ebx+20],0
	jle	_540
	push	ebp
	push	_544
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_541
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_543
	call	brl_blitz_NullObjectError
_543:
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_540:
	push	_545
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_547
	call	brl_blitz_NullObjectError
_547:
	cmp	dword [ebx+24],0
	jle	_548
	push	ebp
	push	_552
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_549
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_551
	call	brl_blitz_NullObjectError
_551:
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_548:
	push	_553
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_555
	call	brl_blitz_NullObjectError
_555:
	mov	dword [ebx+20],0
	push	_557
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_559
	call	brl_blitz_NullObjectError
_559:
	mov	dword [ebx+24],0
	mov	ebx,0
	jmp	_148
_148:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_Close:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_577
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_562
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_564
	call	brl_blitz_NullObjectError
_564:
	cmp	dword [ebx+8],-1
	je	_565
	push	ebp
	push	_576
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_566
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_568
	call	brl_blitz_NullObjectError
_568:
	push	2
	push	dword [ebx+8]
	call	shutdown_
	add	esp,8
	push	_569
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_571
	call	brl_blitz_NullObjectError
_571:
	push	dword [ebx+8]
	call	closesocket_
	add	esp,4
	push	_572
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_574
	call	brl_blitz_NullObjectError
_574:
	mov	dword [ebx+8],-1
	call	dword [bbOnDebugLeaveScope]
_565:
	mov	ebx,0
	jmp	_151
_151:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TNetStream_RecvAvail:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	push	ebp
	push	_595
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_578
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	push	_580
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_582
	call	brl_blitz_NullObjectError
_582:
	cmp	dword [ebx+8],-1
	jne	_583
	push	ebp
	push	_585
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_584
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,-1
	call	dword [bbOnDebugLeaveScope]
	jmp	_154
_583:
	push	_586
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_588
	call	brl_blitz_NullObjectError
_588:
	lea	eax,dword [ebp-8]
	push	eax
	push	21531
	push	dword [ebx+8]
	call	ioctl
	add	esp,12
	cmp	eax,-1
	jne	_589
	push	ebp
	push	_591
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_590
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,-1
	call	dword [bbOnDebugLeaveScope]
	jmp	_154
_589:
	push	ebp
	push	_594
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_593
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	call	dword [bbOnDebugLeaveScope]
	jmp	_154
_154:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_629
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	_bb_TNetStream_New
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TUDPStream
	mov	eax,dword [ebp-4]
	mov	dword [eax+28],0
	mov	eax,dword [ebp-4]
	mov	word [eax+32],0
	mov	eax,dword [ebp-4]
	mov	word [eax+34],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+36],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+40],0
	mov	eax,dword [ebp-4]
	mov	word [eax+44],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+48],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+52],0
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+56]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+60]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+64]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+68]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+72]
	push	ebp
	push	_628
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_596
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_598
	call	brl_blitz_NullObjectError
_598:
	mov	word [ebx+32],0
	push	_600
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_602
	call	brl_blitz_NullObjectError
_602:
	mov	dword [ebx+28],0
	push	_604
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_606
	call	brl_blitz_NullObjectError
_606:
	mov	word [ebx+34],0
	push	_608
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_610
	call	brl_blitz_NullObjectError
_610:
	mov	dword [ebx+36],0
	push	_612
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_614
	call	brl_blitz_NullObjectError
_614:
	mov	dword [ebx+40],0
	push	_616
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_618
	call	brl_blitz_NullObjectError
_618:
	mov	word [ebx+44],0
	push	_620
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_622
	call	brl_blitz_NullObjectError
_622:
	mov	dword [ebx+48],0
	push	_624
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_626
	call	brl_blitz_NullObjectError
_626:
	mov	dword [ebx+52],0
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_157
_157:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_Init:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	push	ebp
	push	_658
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_631
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	push	_633
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_635
	call	brl_blitz_NullObjectError
_635:
	push	0
	push	2
	push	2
	call	socket_
	add	esp,12
	mov	dword [ebx+8],eax
	push	_637
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_639
	call	brl_blitz_NullObjectError
_639:
	cmp	dword [ebx+8],-1
	jne	_640
	push	ebp
	push	_642
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_641
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_160
_640:
	push	_643
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],65527
	push	_644
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_646
	call	brl_blitz_NullObjectError
_646:
	push	4
	lea	eax,dword [ebp-8]
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
	jne	_649
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_648
	call	brl_blitz_NullObjectError
_648:
	push	4
	lea	eax,dword [ebp-8]
	push	eax
	push	7
	push	1
	push	dword [ebx+8]
	call	setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
_649:
	cmp	eax,0
	je	_651
	push	ebp
	push	_656
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_652
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_654
	call	brl_blitz_NullObjectError
_654:
	push	dword [ebx+8]
	call	closesocket_
	add	esp,4
	push	_655
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_160
_651:
	push	_657
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_160
_160:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],0
	push	ebp
	push	_699
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_659
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],0
	push	_662
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_664
	call	brl_blitz_NullObjectError
_664:
	cmp	dword [ebx+8],-1
	jne	_665
	push	ebp
	push	_667
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_666
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_164
_665:
	push	_668
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_670
	call	brl_blitz_NullObjectError
_670:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	push	eax
	push	2
	push	dword [ebx+8]
	call	bind_
	add	esp,12
	cmp	eax,-1
	jne	_671
	push	ebp
	push	_673
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_672
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_164
_671:
	push	ebp
	push	_698
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_675
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_2
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-12],eax
	push	_676
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],16
	push	_677
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_679
	call	brl_blitz_NullObjectError
_679:
	lea	eax,dword [ebp-16]
	push	eax
	mov	eax,dword [ebp-12]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	getsockname
	add	esp,12
	cmp	eax,-1
	jne	_680
	push	ebp
	push	_682
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_681
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_164
_680:
	push	ebp
	push	_697
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_684
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_686
	call	brl_blitz_NullObjectError
_686:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_689
	call	brl_blitz_NullObjectError
_689:
	push	dword [esi+12]
	call	ntohl_
	add	esp,4
	mov	dword [ebx+28],eax
	push	_690
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_692
	call	brl_blitz_NullObjectError
_692:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_695
	call	brl_blitz_NullObjectError
_695:
	movzx	eax,word [esi+10]
	mov	eax,eax
	push	eax
	call	ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+32],ax
	push	_696
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_164
_164:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_705
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_702
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_704
	call	brl_blitz_NullObjectError
_704:
	movzx	eax,word [ebx+32]
	mov	eax,eax
	mov	word [ebp-8],ax
	jmp	_167
_167:
	call	dword [bbOnDebugLeaveScope]
	movzx	eax,word [ebp-8]
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetLocalIP:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_709
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_706
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_708
	call	brl_blitz_NullObjectError
_708:
	mov	ebx,dword [ebx+28]
	jmp	_170
_170:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SetRemotePort:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	push	ebp
	push	_714
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_710
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_712
	call	brl_blitz_NullObjectError
_712:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	mov	word [ebx+34],ax
	mov	ebx,0
	jmp	_174
_174:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetRemotePort:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_718
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_715
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_717
	call	brl_blitz_NullObjectError
_717:
	movzx	eax,word [ebx+34]
	mov	eax,eax
	mov	word [ebp-8],ax
	jmp	_177
_177:
	call	dword [bbOnDebugLeaveScope]
	movzx	eax,word [ebp-8]
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SetRemoteIP:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_723
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_719
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_721
	call	brl_blitz_NullObjectError
_721:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+36],eax
	mov	ebx,0
	jmp	_181
_181:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetRemoteIP:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_727
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_724
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_726
	call	brl_blitz_NullObjectError
_726:
	mov	ebx,dword [ebx+36]
	jmp	_184
_184:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetMsgPort:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_731
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_728
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_730
	call	brl_blitz_NullObjectError
_730:
	movzx	eax,word [ebx+44]
	mov	eax,eax
	mov	word [ebp-8],ax
	jmp	_187
_187:
	call	dword [bbOnDebugLeaveScope]
	movzx	eax,word [ebp-8]
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetMsgIP:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_735
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_732
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_734
	call	brl_blitz_NullObjectError
_734:
	mov	ebx,dword [ebx+40]
	jmp	_190
_190:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SetTimeouts:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	push	ebp
	push	_744
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_736
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_738
	call	brl_blitz_NullObjectError
_738:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+48],eax
	push	_740
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_742
	call	brl_blitz_NullObjectError
_742:
	mov	eax,dword [ebp-12]
	mov	dword [ebx+52],eax
	mov	ebx,0
	jmp	_195
_195:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetRecvTimeout:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_750
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_747
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_749
	call	brl_blitz_NullObjectError
_749:
	mov	ebx,dword [ebx+48]
	jmp	_198
_198:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_GetSendTimeout:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_754
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_751
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_753
	call	brl_blitz_NullObjectError
_753:
	mov	ebx,dword [ebx+52]
	jmp	_201
_201:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_RecvMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,32
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	mov	dword [ebp-28],0
	mov	eax,ebp
	push	eax
	push	_873
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_755
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	push	_761
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-28],0
	push	_763
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_765
	call	brl_blitz_NullObjectError
_765:
	cmp	dword [ebx+8],-1
	jne	_766
	mov	eax,ebp
	push	eax
	push	_768
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_767
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_204
_766:
	push	_769
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_771
	call	brl_blitz_NullObjectError
_771:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-8],eax
	push	_772
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_774
	call	brl_blitz_NullObjectError
_774:
	push	dword [ebx+48]
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
	je	_775
	mov	eax,ebp
	push	eax
	push	_777
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_776
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_204
_775:
	push	_778
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_780
	call	brl_blitz_NullObjectError
_780:
	lea	eax,dword [ebp-16]
	push	eax
	push	21531
	push	dword [ebx+8]
	call	ioctl
	add	esp,12
	cmp	eax,-1
	jne	_781
	mov	eax,ebp
	push	eax
	push	_783
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_782
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_204
_781:
	push	_784
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],0
	jg	_785
	mov	eax,ebp
	push	eax
	push	_787
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_786
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_204
_785:
	push	_788
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_790
	call	brl_blitz_NullObjectError
_790:
	cmp	dword [ebx+20],0
	jle	_791
	mov	eax,ebp
	push	eax
	push	_838
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_792
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_794
	call	brl_blitz_NullObjectError
_794:
	mov	eax,dword [ebx+20]
	add	eax,dword [ebp-16]
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebp-28],eax
	push	_795
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_797
	call	brl_blitz_NullObjectError
_797:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_799
	call	brl_blitz_NullObjectError
_799:
	push	dword [ebx+20]
	push	dword [esi+12]
	push	dword [ebp-28]
	call	bbMemCopy
	add	esp,12
	push	_800
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_802
	call	brl_blitz_NullObjectError
_802:
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
	push	_803
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_805
	call	brl_blitz_NullObjectError
_805:
	mov	eax,dword [ebp-28]
	mov	dword [ebx+12],eax
	push	_807
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_809
	call	brl_blitz_NullObjectError
_809:
	mov	ebx,1000
	call	bbMilliSecs
	cdq
	idiv	ebx
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
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
	jne	_810
	mov	eax,ebp
	push	eax
	push	_831
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_811
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_813
	call	brl_blitz_NullObjectError
_813:
	mov	edi,ebx
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_816
	call	brl_blitz_NullObjectError
_816:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_818
	call	brl_blitz_NullObjectError
_818:
	fld	dword [esi+60]
	fadd	dword [ebx+64]
	fstp	dword [edi+68]
	push	_819
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_821
	call	brl_blitz_NullObjectError
_821:
	mov	ebx,1000
	call	bbMilliSecs
	cdq
	idiv	ebx
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloor
	add	esp,8
	fstp	dword [esi+72]
	push	_823
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_825
	call	brl_blitz_NullObjectError
_825:
	fldz
	fstp	dword [ebx+60]
	push	_827
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_829
	call	brl_blitz_NullObjectError
_829:
	fldz
	fstp	dword [ebx+64]
	call	dword [bbOnDebugLeaveScope]
_810:
	push	_832
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_834
	call	brl_blitz_NullObjectError
_834:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_837
	call	brl_blitz_NullObjectError
_837:
	fld	dword [ebx+60]
	mov	eax,dword [esi+20]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	faddp	st1,st0
	fstp	dword [ebx+60]
	call	dword [bbOnDebugLeaveScope]
	jmp	_839
_791:
	mov	eax,ebp
	push	eax
	push	_844
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_840
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_842
	call	brl_blitz_NullObjectError
_842:
	push	dword [ebp-16]
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebx+12],eax
	call	dword [bbOnDebugLeaveScope]
_839:
	push	_845
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_847
	call	brl_blitz_NullObjectError
_847:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_849
	call	brl_blitz_NullObjectError
_849:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_851
	call	brl_blitz_NullObjectError
_851:
	lea	eax,dword [ebp-24]
	push	eax
	lea	eax,dword [ebp-20]
	push	eax
	push	0
	push	dword [ebp-16]
	mov	eax,dword [esi+12]
	add	eax,dword [ebx+20]
	push	eax
	push	dword [edi+8]
	call	recvfrom_
	add	esp,24
	mov	dword [ebp-12],eax
	push	_852
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_853
	mov	eax,dword [ebp-12]
	cmp	eax,0
	sete	al
	movzx	eax,al
_853:
	cmp	eax,0
	je	_855
	mov	eax,ebp
	push	eax
	push	_857
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_856
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_204
_855:
	mov	eax,ebp
	push	eax
	push	_872
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_859
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_861
	call	brl_blitz_NullObjectError
_861:
	mov	eax,dword [ebp-20]
	mov	dword [ebx+40],eax
	push	_863
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_865
	call	brl_blitz_NullObjectError
_865:
	mov	eax,dword [ebp-24]
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+44],ax
	push	_867
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_869
	call	brl_blitz_NullObjectError
_869:
	mov	eax,dword [ebp-12]
	add	dword [ebx+20],eax
	push	_871
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	call	dword [bbOnDebugLeaveScope]
	jmp	_204
_204:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SendUDPMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-16],eax
	movzx	eax,word [ebp+16]
	mov	eax,eax
	mov	word [ebp-4],ax
	mov	dword [ebp-20],0
	mov	word [ebp-8],0
	mov	dword [ebp-24],0
	push	ebp
	push	_904
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_875
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_877
	call	brl_blitz_NullObjectError
_877:
	mov	eax,dword [ebx+36]
	mov	dword [ebp-20],eax
	push	_879
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_881
	call	brl_blitz_NullObjectError
_881:
	movzx	eax,word [ebx+34]
	mov	eax,eax
	mov	word [ebp-8],ax
	push	_883
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_885
	call	brl_blitz_NullObjectError
_885:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+36],eax
	push	_887
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_889
	call	brl_blitz_NullObjectError
_889:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	mov	word [ebx+34],ax
	push	_891
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_893
	call	brl_blitz_NullObjectError
_893:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+172]
	add	esp,4
	mov	dword [ebp-24],eax
	push	_895
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_897
	call	brl_blitz_NullObjectError
_897:
	mov	eax,dword [ebp-20]
	mov	dword [ebx+36],eax
	push	_899
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_901
	call	brl_blitz_NullObjectError
_901:
	movzx	eax,word [ebp-8]
	mov	eax,eax
	mov	word [ebx+34],ax
	push	_903
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	jmp	_209
_209:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_SendMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	eax,ebp
	push	eax
	push	_1015
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_910
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	push	_914
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_916
	call	brl_blitz_NullObjectError
_916:
	mov	eax,dword [ebx+8]
	cmp	eax,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_919
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_918
	call	brl_blitz_NullObjectError
_918:
	mov	eax,dword [ebx+24]
	cmp	eax,0
	sete	al
	movzx	eax,al
_919:
	cmp	eax,0
	je	_921
	mov	eax,ebp
	push	eax
	push	_923
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_922
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_212
_921:
	push	_924
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_926
	call	brl_blitz_NullObjectError
_926:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-8],eax
	push	_927
	call	dword [bbOnDebugEnterStm]
	add	esp,4
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
	je	_928
	mov	eax,ebp
	push	eax
	push	_930
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_929
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_212
_928:
	push	_931
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [ebp-24],eax
	cmp	dword [ebp-24],bbNullObject
	jne	_933
	call	brl_blitz_NullObjectError
_933:
	mov	eax,dword [ebp-4]
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],bbNullObject
	jne	_935
	call	brl_blitz_NullObjectError
_935:
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_937
	call	brl_blitz_NullObjectError
_937:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_939
	call	brl_blitz_NullObjectError
_939:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_941
	call	brl_blitz_NullObjectError
_941:
	movzx	eax,word [ebx+34]
	mov	eax,eax
	push	eax
	push	dword [esi+36]
	push	0
	push	dword [edi+24]
	mov	eax,dword [ebp-20]
	push	dword [eax+16]
	mov	eax,dword [ebp-24]
	push	dword [eax+8]
	call	sendto_
	add	esp,24
	mov	dword [ebp-12],eax
	push	_942
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_943
	mov	eax,dword [ebp-12]
	cmp	eax,0
	sete	al
	movzx	eax,al
_943:
	cmp	eax,0
	je	_945
	mov	eax,ebp
	push	eax
	push	_947
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_946
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_212
_945:
	mov	eax,ebp
	push	eax
	push	_1014
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_949
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_951
	call	brl_blitz_NullObjectError
_951:
	mov	eax,dword [ebx+24]
	cmp	dword [ebp-12],eax
	jne	_952
	mov	eax,ebp
	push	eax
	push	_960
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_953
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_955
	call	brl_blitz_NullObjectError
_955:
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
	push	_956
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_958
	call	brl_blitz_NullObjectError
_958:
	mov	dword [ebx+24],0
	call	dword [bbOnDebugLeaveScope]
	jmp	_961
_952:
	mov	eax,ebp
	push	eax
	push	_1012
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_962
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_964
	call	brl_blitz_NullObjectError
_964:
	mov	eax,dword [ebx+24]
	sub	eax,dword [ebp-12]
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebp-16],eax
	push	_965
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_967
	call	brl_blitz_NullObjectError
_967:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_969
	call	brl_blitz_NullObjectError
_969:
	mov	eax,dword [esi+24]
	sub	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebx+16]
	add	eax,dword [ebp-12]
	push	eax
	push	dword [ebp-16]
	call	bbMemCopy
	add	esp,12
	push	_970
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_972
	call	brl_blitz_NullObjectError
_972:
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
	push	_973
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_975
	call	brl_blitz_NullObjectError
_975:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+16],eax
	push	_977
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_979
	call	brl_blitz_NullObjectError
_979:
	mov	eax,dword [ebp-12]
	sub	dword [ebx+24],eax
	push	_981
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_983
	call	brl_blitz_NullObjectError
_983:
	mov	ebx,1000
	call	bbMilliSecs
	cdq
	idiv	ebx
	mov	dword [ebp+-28],eax
	fild	dword [ebp+-28]
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
	jne	_984
	mov	eax,ebp
	push	eax
	push	_1005
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_985
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_987
	call	brl_blitz_NullObjectError
_987:
	mov	edi,ebx
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_990
	call	brl_blitz_NullObjectError
_990:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_992
	call	brl_blitz_NullObjectError
_992:
	fld	dword [esi+60]
	fadd	dword [ebx+64]
	fstp	dword [edi+68]
	push	_993
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_995
	call	brl_blitz_NullObjectError
_995:
	mov	ebx,1000
	call	bbMilliSecs
	cdq
	idiv	ebx
	mov	dword [ebp+-28],eax
	fild	dword [ebp+-28]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloor
	add	esp,8
	fstp	dword [esi+72]
	push	_997
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_999
	call	brl_blitz_NullObjectError
_999:
	fldz
	fstp	dword [ebx+60]
	push	_1001
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1003
	call	brl_blitz_NullObjectError
_1003:
	fldz
	fstp	dword [ebx+64]
	call	dword [bbOnDebugLeaveScope]
_984:
	push	_1006
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1008
	call	brl_blitz_NullObjectError
_1008:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1011
	call	brl_blitz_NullObjectError
_1011:
	fld	dword [ebx+64]
	mov	eax,dword [esi+24]
	sub	eax,dword [ebp-12]
	mov	dword [ebp+-28],eax
	fild	dword [ebp+-28]
	faddp	st1,st0
	fstp	dword [ebx+64]
	call	dword [bbOnDebugLeaveScope]
_961:
	push	_1013
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	call	dword [bbOnDebugLeaveScope]
	jmp	_212
_212:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TUDPStream_UDPSpeedString:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1032
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1016
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1018
	call	brl_blitz_NullObjectError
_1018:
	fld	dword [ebx+68]
	fld	dword [_1790]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setbe	al
	movzx	eax,al
	cmp	eax,0
	jne	_1019
	push	ebp
	push	_1023
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1020
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1022
	call	brl_blitz_NullObjectError
_1022:
	push	_9
	mov	ebx,10
	fld	dword [esi+68]
	fmul	dword [_1791]
	fdiv	dword [_1792]
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
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_215
_1019:
	push	_1024
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1026
	call	brl_blitz_NullObjectError
_1026:
	fld	dword [ebx+68]
	fld	dword [_1793]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	seta	al
	movzx	eax,al
	cmp	eax,0
	jne	_1027
	push	ebp
	push	_1031
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1028
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1030
	call	brl_blitz_NullObjectError
_1030:
	push	_10
	fld	dword [ebx+68]
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
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_215
_1027:
	mov	ebx,bbEmptyString
	jmp	_215
_215:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1062
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	_bb_TNetStream_New
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TTCPStream
	mov	eax,dword [ebp-4]
	mov	dword [eax+28],0
	mov	eax,dword [ebp-4]
	mov	word [eax+32],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+36],0
	mov	eax,dword [ebp-4]
	mov	word [eax+40],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+44],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+48],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+52],0
	push	ebp
	push	_1061
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1033
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1035
	call	brl_blitz_NullObjectError
_1035:
	mov	dword [ebx+28],0
	push	_1037
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1039
	call	brl_blitz_NullObjectError
_1039:
	mov	word [ebx+32],0
	push	_1041
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1043
	call	brl_blitz_NullObjectError
_1043:
	mov	dword [ebx+36],0
	push	_1045
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1047
	call	brl_blitz_NullObjectError
_1047:
	mov	word [ebx+40],0
	push	_1049
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1051
	call	brl_blitz_NullObjectError
_1051:
	mov	dword [ebx+44],0
	push	_1053
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1055
	call	brl_blitz_NullObjectError
_1055:
	mov	dword [ebx+48],0
	push	_1057
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1059
	call	brl_blitz_NullObjectError
_1059:
	mov	dword [ebx+52],0
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_218
_218:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Init:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	push	ebp
	push	_1091
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1064
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	push	_1066
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1068
	call	brl_blitz_NullObjectError
_1068:
	push	0
	push	1
	push	2
	call	socket_
	add	esp,12
	mov	dword [ebx+8],eax
	push	_1070
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1072
	call	brl_blitz_NullObjectError
_1072:
	cmp	dword [ebx+8],-1
	jne	_1073
	push	ebp
	push	_1075
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1074
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_221
_1073:
	push	_1076
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],65535
	push	_1077
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1079
	call	brl_blitz_NullObjectError
_1079:
	push	4
	lea	eax,dword [ebp-8]
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
	jne	_1082
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1081
	call	brl_blitz_NullObjectError
_1081:
	push	4
	lea	eax,dword [ebp-8]
	push	eax
	push	7
	push	1
	push	dword [ebx+8]
	call	setsockopt_
	add	esp,20
	cmp	eax,-1
	sete	al
	movzx	eax,al
_1082:
	cmp	eax,0
	je	_1084
	push	ebp
	push	_1089
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1085
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1087
	call	brl_blitz_NullObjectError
_1087:
	push	dword [ebx+8]
	call	closesocket_
	add	esp,4
	push	_1088
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_221
_1084:
	push	_1090
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_221
_221:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],0
	push	ebp
	push	_1132
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1092
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],0
	push	_1095
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1097
	call	brl_blitz_NullObjectError
_1097:
	cmp	dword [ebx+8],-1
	jne	_1098
	push	ebp
	push	_1100
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1099
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_225
_1098:
	push	_1101
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1103
	call	brl_blitz_NullObjectError
_1103:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	push	eax
	push	2
	push	dword [ebx+8]
	call	bind_
	add	esp,12
	cmp	eax,-1
	jne	_1104
	push	ebp
	push	_1106
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1105
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_225
_1104:
	push	ebp
	push	_1131
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1108
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_2
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-12],eax
	push	_1109
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],16
	push	_1110
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1112
	call	brl_blitz_NullObjectError
_1112:
	lea	eax,dword [ebp-16]
	push	eax
	mov	eax,dword [ebp-12]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	getsockname
	add	esp,12
	cmp	eax,-1
	jne	_1113
	push	ebp
	push	_1115
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1114
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_225
_1113:
	push	ebp
	push	_1130
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1117
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1119
	call	brl_blitz_NullObjectError
_1119:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_1122
	call	brl_blitz_NullObjectError
_1122:
	push	dword [esi+12]
	call	ntohl_
	add	esp,4
	mov	dword [ebx+28],eax
	push	_1123
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1125
	call	brl_blitz_NullObjectError
_1125:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_1128
	call	brl_blitz_NullObjectError
_1128:
	movzx	eax,word [esi+10]
	mov	eax,eax
	push	eax
	call	ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+32],ax
	push	_1129
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_225
_225:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetLocalPort:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1136
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1133
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1135
	call	brl_blitz_NullObjectError
_1135:
	movzx	eax,word [ebx+32]
	mov	eax,eax
	mov	word [ebp-8],ax
	jmp	_228
_228:
	call	dword [bbOnDebugLeaveScope]
	movzx	eax,word [ebp-8]
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetLocalIP:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1140
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1137
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1139
	call	brl_blitz_NullObjectError
_1139:
	mov	ebx,dword [ebx+28]
	jmp	_231
_231:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SetRemotePort:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	movzx	eax,word [ebp+12]
	mov	eax,eax
	mov	word [ebp-4],ax
	push	ebp
	push	_1145
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1141
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1143
	call	brl_blitz_NullObjectError
_1143:
	movzx	eax,word [ebp-4]
	mov	eax,eax
	mov	word [ebx+40],ax
	mov	ebx,0
	jmp	_235
_235:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetRemotePort:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1149
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1146
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1148
	call	brl_blitz_NullObjectError
_1148:
	movzx	eax,word [ebx+40]
	mov	eax,eax
	mov	word [ebp-8],ax
	jmp	_238
_238:
	call	dword [bbOnDebugLeaveScope]
	movzx	eax,word [ebp-8]
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SetRemoteIP:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_1154
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1150
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1152
	call	brl_blitz_NullObjectError
_1152:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+36],eax
	mov	ebx,0
	jmp	_242
_242:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetRemoteIP:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1158
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1155
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1157
	call	brl_blitz_NullObjectError
_1157:
	mov	ebx,dword [ebx+36]
	jmp	_245
_245:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SetTimeouts:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+20]
	mov	dword [ebp-16],eax
	push	ebp
	push	_1171
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1159
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1161
	call	brl_blitz_NullObjectError
_1161:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+44],eax
	push	_1163
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1165
	call	brl_blitz_NullObjectError
_1165:
	mov	eax,dword [ebp-12]
	mov	dword [ebx+48],eax
	push	_1167
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1169
	call	brl_blitz_NullObjectError
_1169:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+52],eax
	mov	ebx,0
	jmp	_251
_251:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetRecvTimeout:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1176
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1173
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1175
	call	brl_blitz_NullObjectError
_1175:
	mov	ebx,dword [ebx+44]
	jmp	_254
_254:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetSendTimeout:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1180
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1177
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1179
	call	brl_blitz_NullObjectError
_1179:
	mov	ebx,dword [ebx+48]
	jmp	_257
_257:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetAcceptTimeout:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1184
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1181
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1183
	call	brl_blitz_NullObjectError
_1183:
	mov	ebx,dword [ebx+52]
	jmp	_260
_260:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Connect:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	push	ebp
	push	_1207
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1185
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	push	_1187
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1189
	call	brl_blitz_NullObjectError
_1189:
	cmp	dword [ebx+8],-1
	jne	_1190
	push	ebp
	push	_1192
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1191
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_263
_1190:
	push	_1193
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1195
	call	brl_blitz_NullObjectError
_1195:
	push	dword [ebx+36]
	call	htonl_
	add	esp,4
	mov	dword [ebp-8],eax
	push	_1196
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1198
	call	brl_blitz_NullObjectError
_1198:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1200
	call	brl_blitz_NullObjectError
_1200:
	movzx	eax,word [esi+40]
	mov	eax,eax
	push	eax
	push	4
	push	2
	lea	eax,dword [ebp-8]
	push	eax
	push	dword [ebx+8]
	call	connect_
	add	esp,20
	cmp	eax,-1
	jne	_1201
	push	ebp
	push	_1203
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1202
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_263
_1201:
	push	ebp
	push	_1206
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1205
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	jmp	_263
_263:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Listen:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_1223
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1208
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1210
	call	brl_blitz_NullObjectError
_1210:
	cmp	dword [ebx+8],-1
	jne	_1211
	push	ebp
	push	_1213
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1212
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_267
_1211:
	push	_1214
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1216
	call	brl_blitz_NullObjectError
_1216:
	push	dword [ebp-8]
	push	dword [ebx+8]
	call	listen_
	add	esp,8
	cmp	eax,-1
	jne	_1217
	push	ebp
	push	_1219
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1218
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_267
_1217:
	push	ebp
	push	_1222
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1221
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	jmp	_267
_267:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_Accept:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],0
	mov	dword [ebp-24],bbNullObject
	push	ebp
	push	_1296
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1225
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],0
	push	_1230
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],bbNullObject
	push	_1232
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1234
	call	brl_blitz_NullObjectError
_1234:
	cmp	dword [ebx+8],-1
	jne	_1235
	push	ebp
	push	_1237
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1236
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_270
_1235:
	push	_1238
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1240
	call	brl_blitz_NullObjectError
_1240:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-8],eax
	push	_1241
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1243
	call	brl_blitz_NullObjectError
_1243:
	push	dword [ebx+52]
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
	je	_1244
	push	ebp
	push	_1246
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1245
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_270
_1244:
	push	_1247
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_2
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-16],eax
	push	_1248
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],16
	push	_1249
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1251
	call	brl_blitz_NullObjectError
_1251:
	lea	eax,dword [ebp-20]
	push	eax
	mov	eax,dword [ebp-16]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	accept_
	add	esp,12
	mov	dword [ebp-12],eax
	push	_1252
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],-1
	jne	_1253
	push	ebp
	push	_1255
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1254
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_270
_1253:
	push	_1256
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TTCPStream
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-24],eax
	push	_1257
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1259
	call	brl_blitz_NullObjectError
_1259:
	mov	eax,dword [ebp-12]
	mov	dword [ebx+8],eax
	push	_1261
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1263
	call	brl_blitz_NullObjectError
_1263:
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_1266
	call	brl_blitz_NullObjectError
_1266:
	push	dword [esi+12]
	call	ntohl_
	add	esp,4
	mov	dword [ebx+28],eax
	push	_1267
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1269
	call	brl_blitz_NullObjectError
_1269:
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_1272
	call	brl_blitz_NullObjectError
_1272:
	movzx	eax,word [esi+10]
	mov	eax,eax
	push	eax
	call	ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+32],ax
	push	_1273
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],16
	push	_1274
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1276
	call	brl_blitz_NullObjectError
_1276:
	lea	eax,dword [ebp-20]
	push	eax
	mov	eax,dword [ebp-16]
	lea	eax,dword [eax+8]
	push	eax
	push	dword [ebx+8]
	call	getsockname
	add	esp,12
	cmp	eax,-1
	jne	_1277
	push	ebp
	push	_1282
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1278
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1280
	call	brl_blitz_NullObjectError
_1280:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	_1281
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_270
_1277:
	push	_1283
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1285
	call	brl_blitz_NullObjectError
_1285:
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_1288
	call	brl_blitz_NullObjectError
_1288:
	push	dword [esi+12]
	call	ntohl_
	add	esp,4
	mov	dword [ebx+36],eax
	push	_1289
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1291
	call	brl_blitz_NullObjectError
_1291:
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_1294
	call	brl_blitz_NullObjectError
_1294:
	movzx	eax,word [esi+10]
	mov	eax,eax
	push	eax
	call	ntohs_
	add	esp,4
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [ebx+40],ax
	push	_1295
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	jmp	_270
_270:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_RecvMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	mov	eax,ebp
	push	eax
	push	_1373
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1299
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	push	_1304
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1306
	call	brl_blitz_NullObjectError
_1306:
	cmp	dword [ebx+8],-1
	jne	_1307
	mov	eax,ebp
	push	eax
	push	_1309
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1308
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_273
_1307:
	push	_1310
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1312
	call	brl_blitz_NullObjectError
_1312:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-12],eax
	push	_1313
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1315
	call	brl_blitz_NullObjectError
_1315:
	push	dword [ebx+44]
	push	0
	push	0
	push	0
	push	0
	lea	eax,dword [ebp-12]
	push	eax
	push	1
	call	pselect_
	add	esp,28
	cmp	eax,1
	je	_1316
	mov	eax,ebp
	push	eax
	push	_1318
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1317
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_273
_1316:
	push	_1319
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1321
	call	brl_blitz_NullObjectError
_1321:
	lea	eax,dword [ebp-16]
	push	eax
	push	21531
	push	dword [ebx+8]
	call	ioctl
	add	esp,12
	cmp	eax,-1
	jne	_1322
	mov	eax,ebp
	push	eax
	push	_1324
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1323
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_273
_1322:
	push	_1325
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],0
	jg	_1326
	mov	eax,ebp
	push	eax
	push	_1328
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1327
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_273
_1326:
	push	_1329
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1331
	call	brl_blitz_NullObjectError
_1331:
	cmp	dword [ebx+20],0
	jle	_1332
	mov	eax,ebp
	push	eax
	push	_1348
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1333
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1335
	call	brl_blitz_NullObjectError
_1335:
	mov	eax,dword [ebx+20]
	add	eax,dword [ebp-16]
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebp-20],eax
	push	_1336
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1338
	call	brl_blitz_NullObjectError
_1338:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1340
	call	brl_blitz_NullObjectError
_1340:
	push	dword [ebx+20]
	push	dword [esi+12]
	push	dword [ebp-20]
	call	bbMemCopy
	add	esp,12
	push	_1341
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1343
	call	brl_blitz_NullObjectError
_1343:
	push	dword [ebx+12]
	call	bbMemFree
	add	esp,4
	push	_1344
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1346
	call	brl_blitz_NullObjectError
_1346:
	mov	eax,dword [ebp-20]
	mov	dword [ebx+12],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1349
_1332:
	mov	eax,ebp
	push	eax
	push	_1354
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1350
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1352
	call	brl_blitz_NullObjectError
_1352:
	push	dword [ebp-16]
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebx+12],eax
	call	dword [bbOnDebugLeaveScope]
_1349:
	push	_1355
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_1357
	call	brl_blitz_NullObjectError
_1357:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1359
	call	brl_blitz_NullObjectError
_1359:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1361
	call	brl_blitz_NullObjectError
_1361:
	push	0
	push	dword [ebp-16]
	mov	eax,dword [esi+12]
	add	eax,dword [ebx+20]
	push	eax
	push	dword [edi+8]
	call	recv_
	add	esp,16
	mov	dword [ebp-8],eax
	push	_1362
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],-1
	jne	_1363
	mov	eax,ebp
	push	eax
	push	_1365
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1364
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_273
_1363:
	mov	eax,ebp
	push	eax
	push	_1372
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1367
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1369
	call	brl_blitz_NullObjectError
_1369:
	mov	eax,dword [ebp-8]
	add	dword [ebx+20],eax
	push	_1371
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	call	dword [bbOnDebugLeaveScope]
	jmp	_273
_273:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_SendMsg:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	eax,ebp
	push	eax
	push	_1448
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1374
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	push	_1378
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1380
	call	brl_blitz_NullObjectError
_1380:
	cmp	dword [ebx+8],-1
	jne	_1381
	mov	eax,ebp
	push	eax
	push	_1383
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1382
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_276
_1381:
	push	_1384
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1386
	call	brl_blitz_NullObjectError
_1386:
	cmp	dword [ebx+24],0
	jge	_1387
	mov	eax,ebp
	push	eax
	push	_1389
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1388
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_276
_1387:
	push	_1390
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1392
	call	brl_blitz_NullObjectError
_1392:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-8],eax
	push	_1393
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1395
	call	brl_blitz_NullObjectError
_1395:
	push	dword [ebx+48]
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
	je	_1396
	mov	eax,ebp
	push	eax
	push	_1398
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1397
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_276
_1396:
	push	_1399
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_1401
	call	brl_blitz_NullObjectError
_1401:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1403
	call	brl_blitz_NullObjectError
_1403:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1405
	call	brl_blitz_NullObjectError
_1405:
	push	0
	push	dword [ebx+24]
	push	dword [esi+16]
	push	dword [edi+8]
	call	send_
	add	esp,16
	mov	dword [ebp-12],eax
	push	_1406
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,-1
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_1407
	mov	eax,dword [ebp-12]
	cmp	eax,0
	sete	al
	movzx	eax,al
_1407:
	cmp	eax,0
	je	_1409
	mov	eax,ebp
	push	eax
	push	_1411
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1410
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_276
_1409:
	mov	eax,ebp
	push	eax
	push	_1447
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1413
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1415
	call	brl_blitz_NullObjectError
_1415:
	mov	eax,dword [ebx+24]
	cmp	dword [ebp-12],eax
	jne	_1416
	mov	eax,ebp
	push	eax
	push	_1424
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1417
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1419
	call	brl_blitz_NullObjectError
_1419:
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
	push	_1420
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1422
	call	brl_blitz_NullObjectError
_1422:
	mov	dword [ebx+24],0
	call	dword [bbOnDebugLeaveScope]
	jmp	_1425
_1416:
	mov	eax,ebp
	push	eax
	push	_1445
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1426
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1428
	call	brl_blitz_NullObjectError
_1428:
	mov	eax,dword [ebx+24]
	sub	eax,dword [ebp-12]
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebp-16],eax
	push	_1429
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1431
	call	brl_blitz_NullObjectError
_1431:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1433
	call	brl_blitz_NullObjectError
_1433:
	mov	eax,dword [esi+24]
	sub	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [ebx+16]
	add	eax,dword [ebp-12]
	push	eax
	push	dword [ebp-16]
	call	bbMemCopy
	add	esp,12
	push	_1434
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1436
	call	brl_blitz_NullObjectError
_1436:
	push	dword [ebx+16]
	call	bbMemFree
	add	esp,4
	push	_1437
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1439
	call	brl_blitz_NullObjectError
_1439:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+16],eax
	push	_1441
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1443
	call	brl_blitz_NullObjectError
_1443:
	mov	eax,dword [ebp-12]
	sub	dword [ebx+24],eax
	call	dword [bbOnDebugLeaveScope]
_1425:
	push	_1446
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	call	dword [bbOnDebugLeaveScope]
	jmp	_276
_276:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TTCPStream_GetState:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	push	ebp
	push	_1500
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1449
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	push	_1453
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1455
	call	brl_blitz_NullObjectError
_1455:
	cmp	dword [ebx+8],-1
	jne	_1456
	push	ebp
	push	_1458
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1457
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,-1
	call	dword [bbOnDebugLeaveScope]
	jmp	_279
_1456:
	push	_1459
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1461
	call	brl_blitz_NullObjectError
_1461:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-8],eax
	push	_1462
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	0
	push	0
	push	0
	push	0
	lea	eax,dword [ebp-8]
	push	eax
	push	1
	call	pselect_
	add	esp,28
	mov	dword [ebp-12],eax
	push	_1463
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],-1
	jne	_1464
	push	ebp
	push	_1469
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1465
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1467
	call	brl_blitz_NullObjectError
_1467:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	_1468
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,-1
	call	dword [bbOnDebugLeaveScope]
	jmp	_279
_1464:
	push	ebp
	push	_1499
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1471
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],1
	jne	_1472
	push	ebp
	push	_1495
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1473
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1475
	call	brl_blitz_NullObjectError
_1475:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+176]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_1476
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],-1
	jne	_1477
	push	ebp
	push	_1482
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1478
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1480
	call	brl_blitz_NullObjectError
_1480:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	_1481
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,-1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_279
_1477:
	push	ebp
	push	_1494
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1484
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],0
	jne	_1485
	push	ebp
	push	_1490
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1486
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1488
	call	brl_blitz_NullObjectError
_1488:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	_1489
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_279
_1485:
	push	ebp
	push	_1493
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1492
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_279
_1472:
	push	ebp
	push	_1498
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1497
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_279
_279:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_293:
	dd	0
_282:
	db	"bnetex",0
_283:
	db	"INVALID_SOCKET_",0
_17:
	db	"i",0
	align	4
_284:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,49
_285:
	db	"FIONREAD",0
	align	4
_286:
	dd	bbStringClass
	dd	2147483646
	dd	5
	dw	50,49,53,51,49
_287:
	db	"SOL_SOCKET_",0
	align	4
_288:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	49
_289:
	db	"SO_SNDBUF_",0
_14:
	db	"s",0
	align	4
_290:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	55
_291:
	db	"SO_RCVBUF_",0
	align	4
_292:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	56
	align	4
_281:
	dd	1
	dd	_282
	dd	1
	dd	_283
	dd	_17
	dd	_284
	dd	1
	dd	_285
	dd	_17
	dd	_286
	dd	1
	dd	_287
	dd	_17
	dd	_288
	dd	1
	dd	_289
	dd	_14
	dd	_290
	dd	1
	dd	_291
	dd	_14
	dd	_292
	dd	0
_12:
	db	"TSockAddr",0
_13:
	db	"SinFamily",0
_15:
	db	"SinPort",0
_16:
	db	"SinAddr",0
_18:
	db	"SinZero",0
_19:
	db	"l",0
_20:
	db	"New",0
_21:
	db	"()i",0
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
	dd	0
	align	4
_2:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_11
	dd	24
	dd	_bb_TSockAddr_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
_23:
	db	"TNetwork",0
_24:
	db	"GetHostIP",0
_25:
	db	"($)i",0
_26:
	db	"GetHostIPs",0
_27:
	db	"($)[]i",0
_28:
	db	"GetHostName",0
_29:
	db	"(i)$",0
_30:
	db	"StringIP",0
_31:
	db	"DottedIP",0
_32:
	db	"IntIP",0
	align	4
_22:
	dd	2
	dd	_23
	dd	6
	dd	_20
	dd	_21
	dd	16
	dd	7
	dd	_24
	dd	_25
	dd	48
	dd	7
	dd	_26
	dd	_27
	dd	52
	dd	7
	dd	_28
	dd	_29
	dd	56
	dd	7
	dd	_30
	dd	_29
	dd	60
	dd	7
	dd	_31
	dd	_29
	dd	64
	dd	7
	dd	_32
	dd	_25
	dd	68
	dd	0
	align	4
bb_TNetwork:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_22
	dd	8
	dd	_bb_TNetwork_New
	dd	bbObjectDtor
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
_34:
	db	"TNetStream",0
_35:
	db	"Socket",0
_36:
	db	"RecvBuffer",0
_37:
	db	"*b",0
_38:
	db	"SendBuffer",0
_39:
	db	"RecvSize",0
_40:
	db	"SendSize",0
_41:
	db	"Delete",0
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
_33:
	dd	2
	dd	_34
	dd	3
	dd	_35
	dd	_17
	dd	8
	dd	3
	dd	_36
	dd	_37
	dd	12
	dd	3
	dd	_38
	dd	_37
	dd	16
	dd	3
	dd	_39
	dd	_17
	dd	20
	dd	3
	dd	_40
	dd	_17
	dd	24
	dd	6
	dd	_20
	dd	_21
	dd	16
	dd	6
	dd	_41
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
	dd	_33
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
_297:
	db	"Self",0
_298:
	db	":TSockAddr",0
	align	4
_296:
	dd	1
	dd	_20
	dd	2
	dd	_297
	dd	_298
	dd	-4
	dd	0
	align	4
_295:
	dd	3
	dd	0
	dd	0
_301:
	db	":TNetwork",0
	align	4
_300:
	dd	1
	dd	_20
	dd	2
	dd	_297
	dd	_301
	dd	-4
	dd	0
	align	4
_299:
	dd	3
	dd	0
	dd	0
_329:
	db	"HostName",0
_330:
	db	"$",0
_331:
	db	"Addresses",0
_332:
	db	"**b",0
_333:
	db	"AddressType",0
_334:
	db	"AddressLength",0
_335:
	db	"PAddress",0
_336:
	db	"Address",0
	align	4
_328:
	dd	1
	dd	_24
	dd	2
	dd	_329
	dd	_330
	dd	-4
	dd	2
	dd	_331
	dd	_332
	dd	-8
	dd	2
	dd	_333
	dd	_17
	dd	-12
	dd	2
	dd	_334
	dd	_17
	dd	-16
	dd	2
	dd	_335
	dd	_37
	dd	-20
	dd	2
	dd	_336
	dd	_17
	dd	-24
	dd	0
_303:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/bnetex.bmx",0
	align	4
_302:
	dd	_303
	dd	94
	dd	3
	align	4
_307:
	dd	_303
	dd	95
	dd	3
	align	4
_310:
	dd	_303
	dd	97
	dd	3
	align	4
_311:
	dd	_303
	dd	98
	dd	3
	align	4
_318:
	dd	3
	dd	0
	dd	0
	align	4
_317:
	dd	_303
	dd	98
	dd	76
	align	4
_319:
	dd	_303
	dd	100
	dd	3
	align	4
_324:
	dd	3
	dd	0
	dd	0
	align	4
_321:
	dd	_303
	dd	101
	dd	4
	align	4
_322:
	dd	_303
	dd	102
	dd	4
	align	4
_323:
	dd	_303
	dd	104
	dd	4
	align	4
_327:
	dd	3
	dd	0
	dd	0
	align	4
_326:
	dd	_303
	dd	106
	dd	4
_375:
	db	"Count",0
_376:
	db	"IPs",0
_377:
	db	"[]i",0
_378:
	db	"Index",0
	align	4
_374:
	dd	1
	dd	_26
	dd	2
	dd	_329
	dd	_330
	dd	-4
	dd	2
	dd	_331
	dd	_332
	dd	-8
	dd	2
	dd	_333
	dd	_17
	dd	-12
	dd	2
	dd	_334
	dd	_17
	dd	-16
	dd	2
	dd	_375
	dd	_17
	dd	-20
	dd	2
	dd	_376
	dd	_377
	dd	-24
	dd	2
	dd	_378
	dd	_17
	dd	-28
	dd	2
	dd	_335
	dd	_37
	dd	-32
	dd	2
	dd	_336
	dd	_17
	dd	-36
	dd	0
	align	4
_337:
	dd	_303
	dd	118
	dd	3
	align	4
_341:
	dd	_303
	dd	119
	dd	3
	align	4
_345:
	dd	_303
	dd	120
	dd	3
	align	4
_348:
	dd	_303
	dd	122
	dd	3
	align	4
_349:
	dd	_303
	dd	123
	dd	3
	align	4
_356:
	dd	3
	dd	0
	dd	0
	align	4
_355:
	dd	_303
	dd	123
	dd	76
	align	4
_357:
	dd	_303
	dd	125
	dd	3
	align	4
_358:
	dd	_303
	dd	126
	dd	3
	align	4
_360:
	dd	3
	dd	0
	dd	0
	align	4
_359:
	dd	_303
	dd	127
	dd	4
	align	4
_361:
	dd	_303
	dd	130
	dd	3
_362:
	db	"i",0
	align	4
_363:
	dd	_303
	dd	131
	dd	3
	align	4
_372:
	dd	3
	dd	0
	dd	0
	align	4
_366:
	dd	_303
	dd	132
	dd	4
	align	4
_367:
	dd	_303
	dd	133
	dd	4
	align	4
_368:
	dd	_303
	dd	135
	dd	4
	align	4
_373:
	dd	_303
	dd	138
	dd	3
_392:
	db	"HostIp",0
_393:
	db	"Name",0
	align	4
_391:
	dd	1
	dd	_28
	dd	2
	dd	_392
	dd	_17
	dd	-4
	dd	2
	dd	_336
	dd	_17
	dd	-8
	dd	2
	dd	_393
	dd	_37
	dd	-12
	dd	0
	align	4
_379:
	dd	_303
	dd	147
	dd	3
	align	4
_382:
	dd	_303
	dd	149
	dd	3
	align	4
_383:
	dd	_303
	dd	150
	dd	3
	align	4
_384:
	dd	_303
	dd	152
	dd	3
	align	4
_387:
	dd	3
	dd	0
	dd	0
	align	4
_386:
	dd	_303
	dd	153
	dd	4
	align	4
_390:
	dd	3
	dd	0
	dd	0
	align	4
_389:
	dd	_303
	dd	155
	dd	4
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
_396:
	db	"IP",0
	align	4
_395:
	dd	1
	dd	_30
	dd	2
	dd	_396
	dd	_17
	dd	-4
	dd	0
	align	4
_394:
	dd	_303
	dd	167
	dd	3
	align	4
_398:
	dd	1
	dd	_31
	dd	2
	dd	_396
	dd	_17
	dd	-4
	dd	0
	align	4
_397:
	dd	_303
	dd	177
	dd	3
	align	4
_402:
	dd	1
	dd	_32
	dd	2
	dd	_396
	dd	_330
	dd	-4
	dd	0
	align	4
_399:
	dd	_303
	dd	188
	dd	3
_425:
	db	":TNetStream",0
	align	4
_424:
	dd	1
	dd	_20
	dd	2
	dd	_297
	dd	_425
	dd	-4
	dd	0
	align	4
_423:
	dd	3
	dd	0
	dd	0
	align	4
_403:
	dd	_303
	dd	203
	dd	3
	align	4
_407:
	dd	_303
	dd	204
	dd	3
	align	4
_411:
	dd	_303
	dd	205
	dd	3
	align	4
_415:
	dd	_303
	dd	206
	dd	3
	align	4
_419:
	dd	_303
	dd	207
	dd	3
_481:
	db	"Buffer",0
_482:
	db	"Temp",0
	align	4
_480:
	dd	1
	dd	_44
	dd	2
	dd	_297
	dd	_425
	dd	-4
	dd	2
	dd	_481
	dd	_37
	dd	-8
	dd	2
	dd	_49
	dd	_17
	dd	-12
	dd	2
	dd	_482
	dd	_37
	dd	-16
	dd	0
	align	4
_430:
	dd	_303
	dd	221
	dd	3
	align	4
_432:
	dd	_303
	dd	223
	dd	3
	align	4
_439:
	dd	3
	dd	0
	dd	0
	align	4
_436:
	dd	_303
	dd	223
	dd	32
	align	4
_440:
	dd	_303
	dd	224
	dd	3
	align	4
_478:
	dd	3
	dd	0
	dd	0
	align	4
_442:
	dd	_303
	dd	225
	dd	4
	align	4
_445:
	dd	_303
	dd	226
	dd	4
	align	4
_468:
	dd	3
	dd	0
	dd	0
	align	4
_449:
	dd	_303
	dd	227
	dd	5
	align	4
_452:
	dd	_303
	dd	228
	dd	5
	align	4
_457:
	dd	_303
	dd	229
	dd	5
	align	4
_460:
	dd	_303
	dd	230
	dd	5
	align	4
_464:
	dd	_303
	dd	231
	dd	5
	align	4
_477:
	dd	3
	dd	0
	dd	0
	align	4
_470:
	dd	_303
	dd	233
	dd	5
	align	4
_473:
	dd	_303
	dd	234
	dd	5
	align	4
_479:
	dd	_303
	dd	238
	dd	3
	align	4
_528:
	dd	1
	dd	_47
	dd	2
	dd	_297
	dd	_425
	dd	-4
	dd	2
	dd	_481
	dd	_37
	dd	-8
	dd	2
	dd	_49
	dd	_17
	dd	-12
	dd	2
	dd	_482
	dd	_37
	dd	-16
	dd	0
	align	4
_483:
	dd	_303
	dd	244
	dd	3
	align	4
_485:
	dd	_303
	dd	246
	dd	3
	align	4
_488:
	dd	3
	dd	0
	dd	0
	align	4
_487:
	dd	_303
	dd	246
	dd	21
	align	4
_489:
	dd	_303
	dd	248
	dd	3
	align	4
_492:
	dd	_303
	dd	249
	dd	3
	align	4
_515:
	dd	3
	dd	0
	dd	0
	align	4
_496:
	dd	_303
	dd	250
	dd	4
	align	4
_501:
	dd	_303
	dd	251
	dd	4
	align	4
_504:
	dd	_303
	dd	252
	dd	4
	align	4
_507:
	dd	_303
	dd	253
	dd	4
	align	4
_511:
	dd	_303
	dd	254
	dd	4
	align	4
_526:
	dd	3
	dd	0
	dd	0
	align	4
_517:
	dd	_303
	dd	256
	dd	4
	align	4
_518:
	dd	_303
	dd	257
	dd	4
	align	4
_522:
	dd	_303
	dd	258
	dd	4
	align	4
_527:
	dd	_303
	dd	261
	dd	3
	align	4
_532:
	dd	1
	dd	_48
	dd	2
	dd	_297
	dd	_425
	dd	-4
	dd	0
	align	4
_529:
	dd	_303
	dd	272
	dd	3
	align	4
_536:
	dd	1
	dd	_49
	dd	2
	dd	_297
	dd	_425
	dd	-4
	dd	0
	align	4
_533:
	dd	_303
	dd	284
	dd	3
	align	4
_561:
	dd	1
	dd	_50
	dd	2
	dd	_297
	dd	_425
	dd	-4
	dd	0
	align	4
_537:
	dd	_303
	dd	298
	dd	3
	align	4
_544:
	dd	3
	dd	0
	dd	0
	align	4
_541:
	dd	_303
	dd	298
	dd	29
	align	4
_545:
	dd	_303
	dd	299
	dd	3
	align	4
_552:
	dd	3
	dd	0
	dd	0
	align	4
_549:
	dd	_303
	dd	299
	dd	29
	align	4
_553:
	dd	_303
	dd	300
	dd	3
	align	4
_557:
	dd	_303
	dd	301
	dd	3
	align	4
_577:
	dd	1
	dd	_51
	dd	2
	dd	_297
	dd	_425
	dd	-4
	dd	0
	align	4
_562:
	dd	_303
	dd	311
	dd	3
	align	4
_576:
	dd	3
	dd	0
	dd	0
	align	4
_566:
	dd	_303
	dd	313
	dd	4
	align	4
_569:
	dd	_303
	dd	314
	dd	4
	align	4
_572:
	dd	_303
	dd	316
	dd	4
	align	4
_595:
	dd	1
	dd	_52
	dd	2
	dd	_297
	dd	_425
	dd	-4
	dd	2
	dd	_49
	dd	_17
	dd	-8
	dd	0
	align	4
_578:
	dd	_303
	dd	329
	dd	3
	align	4
_580:
	dd	_303
	dd	332
	dd	3
	align	4
_585:
	dd	3
	dd	0
	dd	0
	align	4
_584:
	dd	_303
	dd	332
	dd	41
	align	4
_586:
	dd	_303
	dd	335
	dd	3
	align	4
_591:
	dd	3
	dd	0
	dd	0
	align	4
_590:
	dd	_303
	dd	336
	dd	4
	align	4
_594:
	dd	3
	dd	0
	dd	0
	align	4
_593:
	dd	_303
	dd	338
	dd	4
_630:
	db	":TUDPStream",0
	align	4
_629:
	dd	1
	dd	_20
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_628:
	dd	3
	dd	0
	dd	0
	align	4
_596:
	dd	_303
	dd	364
	dd	3
	align	4
_600:
	dd	_303
	dd	365
	dd	3
	align	4
_604:
	dd	_303
	dd	366
	dd	3
	align	4
_608:
	dd	_303
	dd	367
	dd	3
	align	4
_612:
	dd	_303
	dd	368
	dd	3
	align	4
_616:
	dd	_303
	dd	369
	dd	3
	align	4
_620:
	dd	_303
	dd	371
	dd	3
	align	4
_624:
	dd	_303
	dd	372
	dd	3
	align	4
_658:
	dd	1
	dd	_42
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	2
	dd	_49
	dd	_17
	dd	-8
	dd	0
	align	4
_631:
	dd	_303
	dd	381
	dd	3
	align	4
_633:
	dd	_303
	dd	383
	dd	3
	align	4
_637:
	dd	_303
	dd	384
	dd	3
	align	4
_642:
	dd	3
	dd	0
	dd	0
	align	4
_641:
	dd	_303
	dd	384
	dd	41
	align	4
_643:
	dd	_303
	dd	387
	dd	3
	align	4
_644:
	dd	_303
	dd	388
	dd	3
	align	4
_656:
	dd	3
	dd	0
	dd	0
	align	4
_652:
	dd	_303
	dd	390
	dd	4
	align	4
_655:
	dd	_303
	dd	391
	dd	4
	align	4
_657:
	dd	_303
	dd	394
	dd	3
_700:
	db	"Port",0
_701:
	db	"NameLen",0
	align	4
_699:
	dd	1
	dd	_69
	dd	2
	dd	_297
	dd	_630
	dd	-8
	dd	2
	dd	_700
	dd	_14
	dd	-4
	dd	2
	dd	_336
	dd	_298
	dd	-12
	dd	2
	dd	_701
	dd	_17
	dd	-16
	dd	0
	align	4
_659:
	dd	_303
	dd	407
	dd	3
	align	4
_662:
	dd	_303
	dd	410
	dd	3
	align	4
_667:
	dd	3
	dd	0
	dd	0
	align	4
_666:
	dd	_303
	dd	410
	dd	41
	align	4
_668:
	dd	_303
	dd	413
	dd	3
	align	4
_673:
	dd	3
	dd	0
	dd	0
	align	4
_672:
	dd	_303
	dd	414
	dd	4
	align	4
_698:
	dd	3
	dd	0
	dd	0
	align	4
_675:
	dd	_303
	dd	417
	dd	4
	align	4
_676:
	dd	_303
	dd	418
	dd	4
	align	4
_677:
	dd	_303
	dd	419
	dd	4
	align	4
_682:
	dd	3
	dd	0
	dd	0
	align	4
_681:
	dd	_303
	dd	420
	dd	5
	align	4
_697:
	dd	3
	dd	0
	dd	0
	align	4
_684:
	dd	_303
	dd	422
	dd	5
	align	4
_690:
	dd	_303
	dd	423
	dd	5
	align	4
_696:
	dd	_303
	dd	424
	dd	5
	align	4
_705:
	dd	1
	dd	_71
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_702:
	dd	_303
	dd	435
	dd	3
	align	4
_709:
	dd	1
	dd	_73
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_706:
	dd	_303
	dd	446
	dd	3
	align	4
_714:
	dd	1
	dd	_74
	dd	2
	dd	_297
	dd	_630
	dd	-8
	dd	2
	dd	_700
	dd	_14
	dd	-4
	dd	0
	align	4
_710:
	dd	_303
	dd	458
	dd	3
	align	4
_718:
	dd	1
	dd	_75
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_715:
	dd	_303
	dd	469
	dd	3
	align	4
_723:
	dd	1
	dd	_76
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	2
	dd	_396
	dd	_17
	dd	-8
	dd	0
	align	4
_719:
	dd	_303
	dd	480
	dd	3
	align	4
_727:
	dd	1
	dd	_78
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_724:
	dd	_303
	dd	491
	dd	3
	align	4
_731:
	dd	1
	dd	_79
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_728:
	dd	_303
	dd	501
	dd	3
	align	4
_735:
	dd	1
	dd	_80
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_732:
	dd	_303
	dd	511
	dd	3
_745:
	db	"RecvMillisecs",0
_746:
	db	"SendMillisecs",0
	align	4
_744:
	dd	1
	dd	_81
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	2
	dd	_745
	dd	_17
	dd	-8
	dd	2
	dd	_746
	dd	_17
	dd	-12
	dd	0
	align	4
_736:
	dd	_303
	dd	522
	dd	3
	align	4
_740:
	dd	_303
	dd	523
	dd	3
	align	4
_750:
	dd	1
	dd	_83
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_747:
	dd	_303
	dd	532
	dd	3
	align	4
_754:
	dd	1
	dd	_84
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_751:
	dd	_303
	dd	541
	dd	3
_874:
	db	"Result",0
	align	4
_873:
	dd	1
	dd	_43
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	2
	dd	_44
	dd	_17
	dd	-8
	dd	2
	dd	_874
	dd	_17
	dd	-12
	dd	2
	dd	_49
	dd	_17
	dd	-16
	dd	2
	dd	_59
	dd	_17
	dd	-20
	dd	2
	dd	_60
	dd	_17
	dd	-24
	dd	2
	dd	_482
	dd	_37
	dd	-28
	dd	0
	align	4
_755:
	dd	_303
	dd	555
	dd	3
	align	4
_761:
	dd	_303
	dd	556
	dd	3
	align	4
_763:
	dd	_303
	dd	558
	dd	3
	align	4
_768:
	dd	3
	dd	0
	dd	0
	align	4
_767:
	dd	_303
	dd	558
	dd	41
	align	4
_769:
	dd	_303
	dd	560
	dd	3
	align	4
_772:
	dd	_303
	dd	561
	dd	3
	align	4
_777:
	dd	3
	dd	0
	dd	0
	align	4
_776:
	dd	_303
	dd	562
	dd	11
	align	4
_778:
	dd	_303
	dd	564
	dd	3
	align	4
_783:
	dd	3
	dd	0
	dd	0
	align	4
_782:
	dd	_303
	dd	565
	dd	11
	align	4
_784:
	dd	_303
	dd	567
	dd	3
	align	4
_787:
	dd	3
	dd	0
	dd	0
	align	4
_786:
	dd	_303
	dd	567
	dd	21
	align	4
_788:
	dd	_303
	dd	569
	dd	3
	align	4
_838:
	dd	3
	dd	0
	dd	0
	align	4
_792:
	dd	_303
	dd	570
	dd	4
	align	4
_795:
	dd	_303
	dd	571
	dd	4
	align	4
_800:
	dd	_303
	dd	572
	dd	4
	align	4
_803:
	dd	_303
	dd	573
	dd	4
	align	4
_807:
	dd	_303
	dd	575
	dd	4
	align	4
_831:
	dd	3
	dd	0
	dd	0
	align	4
_811:
	dd	_303
	dd	576
	dd	6
	align	4
_819:
	dd	_303
	dd	577
	dd	6
	align	4
_823:
	dd	_303
	dd	578
	dd	6
	align	4
_827:
	dd	_303
	dd	579
	dd	6
	align	4
_832:
	dd	_303
	dd	581
	dd	4
	align	4
_844:
	dd	3
	dd	0
	dd	0
	align	4
_840:
	dd	_303
	dd	584
	dd	4
	align	4
_845:
	dd	_303
	dd	587
	dd	3
	align	4
_852:
	dd	_303
	dd	590
	dd	3
	align	4
_857:
	dd	3
	dd	0
	dd	0
	align	4
_856:
	dd	_303
	dd	591
	dd	4
	align	4
_872:
	dd	3
	dd	0
	dd	0
	align	4
_859:
	dd	_303
	dd	593
	dd	4
	align	4
_863:
	dd	_303
	dd	594
	dd	4
	align	4
_867:
	dd	_303
	dd	595
	dd	4
	align	4
_871:
	dd	_303
	dd	596
	dd	4
_905:
	db	"iIP",0
_906:
	db	"shPort",0
_907:
	db	"oldIP",0
_908:
	db	"oldPort",0
_909:
	db	"returnvalue",0
	align	4
_904:
	dd	1
	dd	_85
	dd	2
	dd	_297
	dd	_630
	dd	-12
	dd	2
	dd	_905
	dd	_17
	dd	-16
	dd	2
	dd	_906
	dd	_14
	dd	-4
	dd	2
	dd	_907
	dd	_17
	dd	-20
	dd	2
	dd	_908
	dd	_14
	dd	-8
	dd	2
	dd	_909
	dd	_17
	dd	-24
	dd	0
	align	4
_875:
	dd	_303
	dd	602
	dd	7
	align	4
_879:
	dd	_303
	dd	603
	dd	4
	align	4
_883:
	dd	_303
	dd	604
	dd	4
	align	4
_887:
	dd	_303
	dd	605
	dd	4
	align	4
_891:
	dd	_303
	dd	606
	dd	4
	align	4
_895:
	dd	_303
	dd	607
	dd	4
	align	4
_899:
	dd	_303
	dd	608
	dd	4
	align	4
_903:
	dd	_303
	dd	609
	dd	4
	align	4
_1015:
	dd	1
	dd	_46
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	2
	dd	_47
	dd	_17
	dd	-8
	dd	2
	dd	_874
	dd	_17
	dd	-12
	dd	2
	dd	_482
	dd	_37
	dd	-16
	dd	0
	align	4
_910:
	dd	_303
	dd	622
	dd	3
	align	4
_914:
	dd	_303
	dd	624
	dd	3
	align	4
_923:
	dd	3
	dd	0
	dd	0
	align	4
_922:
	dd	_303
	dd	625
	dd	29
	align	4
_924:
	dd	_303
	dd	627
	dd	3
	align	4
_927:
	dd	_303
	dd	628
	dd	3
	align	4
_930:
	dd	3
	dd	0
	dd	0
	align	4
_929:
	dd	_303
	dd	629
	dd	11
	align	4
_931:
	dd	_303
	dd	631
	dd	3
	align	4
_942:
	dd	_303
	dd	634
	dd	3
	align	4
_947:
	dd	3
	dd	0
	dd	0
	align	4
_946:
	dd	_303
	dd	635
	dd	4
	align	4
_1014:
	dd	3
	dd	0
	dd	0
	align	4
_949:
	dd	_303
	dd	637
	dd	4
	align	4
_960:
	dd	3
	dd	0
	dd	0
	align	4
_953:
	dd	_303
	dd	638
	dd	5
	align	4
_956:
	dd	_303
	dd	639
	dd	5
	align	4
_1012:
	dd	3
	dd	0
	dd	0
	align	4
_962:
	dd	_303
	dd	641
	dd	5
	align	4
_965:
	dd	_303
	dd	642
	dd	5
	align	4
_970:
	dd	_303
	dd	643
	dd	5
	align	4
_973:
	dd	_303
	dd	644
	dd	5
	align	4
_977:
	dd	_303
	dd	645
	dd	5
	align	4
_981:
	dd	_303
	dd	647
	dd	5
	align	4
_1005:
	dd	3
	dd	0
	dd	0
	align	4
_985:
	dd	_303
	dd	648
	dd	5
	align	4
_993:
	dd	_303
	dd	649
	dd	5
	align	4
_997:
	dd	_303
	dd	650
	dd	5
	align	4
_1001:
	dd	_303
	dd	651
	dd	5
	align	4
_1006:
	dd	_303
	dd	653
	dd	5
	align	4
_1013:
	dd	_303
	dd	657
	dd	4
	align	4
_1032:
	dd	1
	dd	_87
	dd	2
	dd	_297
	dd	_630
	dd	-4
	dd	0
	align	4
_1016:
	dd	_303
	dd	662
	dd	3
	align	4
_1790:
	dd	0x44800000
	align	4
_1023:
	dd	3
	dd	0
	dd	0
	align	4
_1020:
	dd	_303
	dd	662
	dd	32
	align	4
_9:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	107,98,47,115
	align	4
_1791:
	dd	0x41200000
	align	4
_1792:
	dd	0x44800000
	align	4
_1024:
	dd	_303
	dd	663
	dd	3
	align	4
_1793:
	dd	0x44800000
	align	4
_1031:
	dd	3
	dd	0
	dd	0
	align	4
_1028:
	dd	_303
	dd	663
	dd	33
	align	4
_10:
	dd	bbStringClass
	dd	2147483647
	dd	3
	dw	98,47,115
_1063:
	db	":TTCPStream",0
	align	4
_1062:
	dd	1
	dd	_20
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	0
	align	4
_1061:
	dd	3
	dd	0
	dd	0
	align	4
_1033:
	dd	_303
	dd	684
	dd	3
	align	4
_1037:
	dd	_303
	dd	685
	dd	3
	align	4
_1041:
	dd	_303
	dd	686
	dd	3
	align	4
_1045:
	dd	_303
	dd	687
	dd	3
	align	4
_1049:
	dd	_303
	dd	689
	dd	3
	align	4
_1053:
	dd	_303
	dd	690
	dd	3
	align	4
_1057:
	dd	_303
	dd	691
	dd	3
	align	4
_1091:
	dd	1
	dd	_42
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	2
	dd	_49
	dd	_17
	dd	-8
	dd	0
	align	4
_1064:
	dd	_303
	dd	700
	dd	3
	align	4
_1066:
	dd	_303
	dd	702
	dd	3
	align	4
_1070:
	dd	_303
	dd	703
	dd	3
	align	4
_1075:
	dd	3
	dd	0
	dd	0
	align	4
_1074:
	dd	_303
	dd	703
	dd	41
	align	4
_1076:
	dd	_303
	dd	706
	dd	3
	align	4
_1077:
	dd	_303
	dd	707
	dd	3
	align	4
_1089:
	dd	3
	dd	0
	dd	0
	align	4
_1085:
	dd	_303
	dd	709
	dd	4
	align	4
_1088:
	dd	_303
	dd	710
	dd	4
	align	4
_1090:
	dd	_303
	dd	713
	dd	3
	align	4
_1132:
	dd	1
	dd	_69
	dd	2
	dd	_297
	dd	_1063
	dd	-8
	dd	2
	dd	_700
	dd	_14
	dd	-4
	dd	2
	dd	_336
	dd	_298
	dd	-12
	dd	2
	dd	_701
	dd	_17
	dd	-16
	dd	0
	align	4
_1092:
	dd	_303
	dd	726
	dd	3
	align	4
_1095:
	dd	_303
	dd	729
	dd	3
	align	4
_1100:
	dd	3
	dd	0
	dd	0
	align	4
_1099:
	dd	_303
	dd	729
	dd	41
	align	4
_1101:
	dd	_303
	dd	732
	dd	3
	align	4
_1106:
	dd	3
	dd	0
	dd	0
	align	4
_1105:
	dd	_303
	dd	733
	dd	4
	align	4
_1131:
	dd	3
	dd	0
	dd	0
	align	4
_1108:
	dd	_303
	dd	736
	dd	4
	align	4
_1109:
	dd	_303
	dd	737
	dd	4
	align	4
_1110:
	dd	_303
	dd	738
	dd	4
	align	4
_1115:
	dd	3
	dd	0
	dd	0
	align	4
_1114:
	dd	_303
	dd	739
	dd	5
	align	4
_1130:
	dd	3
	dd	0
	dd	0
	align	4
_1117:
	dd	_303
	dd	741
	dd	5
	align	4
_1123:
	dd	_303
	dd	742
	dd	5
	align	4
_1129:
	dd	_303
	dd	743
	dd	5
	align	4
_1136:
	dd	1
	dd	_71
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	0
	align	4
_1133:
	dd	_303
	dd	754
	dd	3
	align	4
_1140:
	dd	1
	dd	_73
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	0
	align	4
_1137:
	dd	_303
	dd	765
	dd	3
	align	4
_1145:
	dd	1
	dd	_74
	dd	2
	dd	_297
	dd	_1063
	dd	-8
	dd	2
	dd	_700
	dd	_14
	dd	-4
	dd	0
	align	4
_1141:
	dd	_303
	dd	777
	dd	3
	align	4
_1149:
	dd	1
	dd	_75
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	0
	align	4
_1146:
	dd	_303
	dd	789
	dd	3
	align	4
_1154:
	dd	1
	dd	_76
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	2
	dd	_396
	dd	_17
	dd	-8
	dd	0
	align	4
_1150:
	dd	_303
	dd	800
	dd	3
	align	4
_1158:
	dd	1
	dd	_78
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	0
	align	4
_1155:
	dd	_303
	dd	811
	dd	3
_1172:
	db	"AcceptMillisecs",0
	align	4
_1171:
	dd	1
	dd	_81
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	2
	dd	_745
	dd	_17
	dd	-8
	dd	2
	dd	_746
	dd	_17
	dd	-12
	dd	2
	dd	_1172
	dd	_17
	dd	-16
	dd	0
	align	4
_1159:
	dd	_303
	dd	822
	dd	3
	align	4
_1163:
	dd	_303
	dd	823
	dd	3
	align	4
_1167:
	dd	_303
	dd	824
	dd	3
	align	4
_1176:
	dd	1
	dd	_83
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	0
	align	4
_1173:
	dd	_303
	dd	833
	dd	3
	align	4
_1180:
	dd	1
	dd	_84
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	0
	align	4
_1177:
	dd	_303
	dd	842
	dd	3
	align	4
_1184:
	dd	1
	dd	_93
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	0
	align	4
_1181:
	dd	_303
	dd	851
	dd	3
	align	4
_1207:
	dd	1
	dd	_94
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	2
	dd	_336
	dd	_17
	dd	-8
	dd	0
	align	4
_1185:
	dd	_303
	dd	863
	dd	3
	align	4
_1187:
	dd	_303
	dd	866
	dd	3
	align	4
_1192:
	dd	3
	dd	0
	dd	0
	align	4
_1191:
	dd	_303
	dd	866
	dd	41
	align	4
_1193:
	dd	_303
	dd	869
	dd	3
	align	4
_1196:
	dd	_303
	dd	870
	dd	3
	align	4
_1203:
	dd	3
	dd	0
	dd	0
	align	4
_1202:
	dd	_303
	dd	872
	dd	4
	align	4
_1206:
	dd	3
	dd	0
	dd	0
	align	4
_1205:
	dd	_303
	dd	874
	dd	4
_1224:
	db	"MaxClients",0
	align	4
_1223:
	dd	1
	dd	_95
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	2
	dd	_1224
	dd	_17
	dd	-8
	dd	0
	align	4
_1208:
	dd	_303
	dd	889
	dd	3
	align	4
_1213:
	dd	3
	dd	0
	dd	0
	align	4
_1212:
	dd	_303
	dd	889
	dd	41
	align	4
_1214:
	dd	_303
	dd	892
	dd	3
	align	4
_1219:
	dd	3
	dd	0
	dd	0
	align	4
_1218:
	dd	_303
	dd	893
	dd	4
	align	4
_1222:
	dd	3
	dd	0
	dd	0
	align	4
_1221:
	dd	_303
	dd	895
	dd	4
_1297:
	db	"AddrLen",0
_1298:
	db	"Client",0
	align	4
_1296:
	dd	1
	dd	_96
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	2
	dd	_44
	dd	_17
	dd	-8
	dd	2
	dd	_874
	dd	_17
	dd	-12
	dd	2
	dd	_336
	dd	_298
	dd	-16
	dd	2
	dd	_1297
	dd	_17
	dd	-20
	dd	2
	dd	_1298
	dd	_1063
	dd	-24
	dd	0
	align	4
_1225:
	dd	_303
	dd	908
	dd	3
	align	4
_1230:
	dd	_303
	dd	909
	dd	3
	align	4
_1232:
	dd	_303
	dd	912
	dd	3
	align	4
_1237:
	dd	3
	dd	0
	dd	0
	align	4
_1236:
	dd	_303
	dd	912
	dd	41
	align	4
_1238:
	dd	_303
	dd	915
	dd	3
	align	4
_1241:
	dd	_303
	dd	916
	dd	3
	align	4
_1246:
	dd	3
	dd	0
	dd	0
	align	4
_1245:
	dd	_303
	dd	917
	dd	11
	align	4
_1247:
	dd	_303
	dd	919
	dd	3
	align	4
_1248:
	dd	_303
	dd	920
	dd	3
	align	4
_1249:
	dd	_303
	dd	923
	dd	3
	align	4
_1252:
	dd	_303
	dd	924
	dd	3
	align	4
_1255:
	dd	3
	dd	0
	dd	0
	align	4
_1254:
	dd	_303
	dd	924
	dd	34
	align	4
_1256:
	dd	_303
	dd	927
	dd	3
	align	4
_1257:
	dd	_303
	dd	928
	dd	3
	align	4
_1261:
	dd	_303
	dd	929
	dd	3
	align	4
_1267:
	dd	_303
	dd	930
	dd	3
	align	4
_1273:
	dd	_303
	dd	933
	dd	3
	align	4
_1274:
	dd	_303
	dd	934
	dd	3
	align	4
_1282:
	dd	3
	dd	0
	dd	0
	align	4
_1278:
	dd	_303
	dd	935
	dd	4
	align	4
_1281:
	dd	_303
	dd	936
	dd	4
	align	4
_1283:
	dd	_303
	dd	939
	dd	3
	align	4
_1289:
	dd	_303
	dd	940
	dd	3
	align	4
_1295:
	dd	_303
	dd	942
	dd	3
	align	4
_1373:
	dd	1
	dd	_43
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	2
	dd	_874
	dd	_17
	dd	-8
	dd	2
	dd	_44
	dd	_17
	dd	-12
	dd	2
	dd	_49
	dd	_17
	dd	-16
	dd	2
	dd	_482
	dd	_37
	dd	-20
	dd	0
	align	4
_1299:
	dd	_303
	dd	955
	dd	3
	align	4
_1304:
	dd	_303
	dd	958
	dd	3
	align	4
_1309:
	dd	3
	dd	0
	dd	0
	align	4
_1308:
	dd	_303
	dd	958
	dd	41
	align	4
_1310:
	dd	_303
	dd	961
	dd	3
	align	4
_1313:
	dd	_303
	dd	962
	dd	3
	align	4
_1318:
	dd	3
	dd	0
	dd	0
	align	4
_1317:
	dd	_303
	dd	963
	dd	11
	align	4
_1319:
	dd	_303
	dd	965
	dd	3
	align	4
_1324:
	dd	3
	dd	0
	dd	0
	align	4
_1323:
	dd	_303
	dd	966
	dd	11
	align	4
_1325:
	dd	_303
	dd	968
	dd	3
	align	4
_1328:
	dd	3
	dd	0
	dd	0
	align	4
_1327:
	dd	_303
	dd	968
	dd	21
	align	4
_1329:
	dd	_303
	dd	970
	dd	3
	align	4
_1348:
	dd	3
	dd	0
	dd	0
	align	4
_1333:
	dd	_303
	dd	971
	dd	4
	align	4
_1336:
	dd	_303
	dd	972
	dd	4
	align	4
_1341:
	dd	_303
	dd	973
	dd	4
	align	4
_1344:
	dd	_303
	dd	974
	dd	4
	align	4
_1354:
	dd	3
	dd	0
	dd	0
	align	4
_1350:
	dd	_303
	dd	976
	dd	4
	align	4
_1355:
	dd	_303
	dd	979
	dd	3
	align	4
_1362:
	dd	_303
	dd	981
	dd	3
	align	4
_1365:
	dd	3
	dd	0
	dd	0
	align	4
_1364:
	dd	_303
	dd	982
	dd	4
	align	4
_1372:
	dd	3
	dd	0
	dd	0
	align	4
_1367:
	dd	_303
	dd	984
	dd	4
	align	4
_1371:
	dd	_303
	dd	985
	dd	4
	align	4
_1448:
	dd	1
	dd	_46
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	2
	dd	_47
	dd	_17
	dd	-8
	dd	2
	dd	_874
	dd	_17
	dd	-12
	dd	2
	dd	_482
	dd	_37
	dd	-16
	dd	0
	align	4
_1374:
	dd	_303
	dd	999
	dd	3
	align	4
_1378:
	dd	_303
	dd	1002
	dd	3
	align	4
_1383:
	dd	3
	dd	0
	dd	0
	align	4
_1382:
	dd	_303
	dd	1002
	dd	41
	align	4
_1384:
	dd	_303
	dd	1004
	dd	3
	align	4
_1389:
	dd	3
	dd	0
	dd	0
	align	4
_1388:
	dd	_303
	dd	1004
	dd	29
	align	4
_1390:
	dd	_303
	dd	1007
	dd	3
	align	4
_1393:
	dd	_303
	dd	1008
	dd	3
	align	4
_1398:
	dd	3
	dd	0
	dd	0
	align	4
_1397:
	dd	_303
	dd	1009
	dd	11
	align	4
_1399:
	dd	_303
	dd	1011
	dd	3
	align	4
_1406:
	dd	_303
	dd	1013
	dd	3
	align	4
_1411:
	dd	3
	dd	0
	dd	0
	align	4
_1410:
	dd	_303
	dd	1014
	dd	4
	align	4
_1447:
	dd	3
	dd	0
	dd	0
	align	4
_1413:
	dd	_303
	dd	1016
	dd	4
	align	4
_1424:
	dd	3
	dd	0
	dd	0
	align	4
_1417:
	dd	_303
	dd	1017
	dd	5
	align	4
_1420:
	dd	_303
	dd	1018
	dd	5
	align	4
_1445:
	dd	3
	dd	0
	dd	0
	align	4
_1426:
	dd	_303
	dd	1020
	dd	5
	align	4
_1429:
	dd	_303
	dd	1021
	dd	5
	align	4
_1434:
	dd	_303
	dd	1022
	dd	5
	align	4
_1437:
	dd	_303
	dd	1023
	dd	5
	align	4
_1441:
	dd	_303
	dd	1024
	dd	5
	align	4
_1446:
	dd	_303
	dd	1027
	dd	4
	align	4
_1500:
	dd	1
	dd	_98
	dd	2
	dd	_297
	dd	_1063
	dd	-4
	dd	2
	dd	_44
	dd	_17
	dd	-8
	dd	2
	dd	_874
	dd	_17
	dd	-12
	dd	2
	dd	_49
	dd	_17
	dd	-16
	dd	0
	align	4
_1449:
	dd	_303
	dd	1038
	dd	3
	align	4
_1453:
	dd	_303
	dd	1040
	dd	3
	align	4
_1458:
	dd	3
	dd	0
	dd	0
	align	4
_1457:
	dd	_303
	dd	1040
	dd	41
	align	4
_1459:
	dd	_303
	dd	1042
	dd	3
	align	4
_1462:
	dd	_303
	dd	1043
	dd	3
	align	4
_1463:
	dd	_303
	dd	1045
	dd	3
	align	4
_1469:
	dd	3
	dd	0
	dd	0
	align	4
_1465:
	dd	_303
	dd	1047
	dd	4
	align	4
_1468:
	dd	_303
	dd	1048
	dd	4
	align	4
_1499:
	dd	3
	dd	0
	dd	0
	align	4
_1471:
	dd	_303
	dd	1049
	dd	3
	align	4
_1495:
	dd	3
	dd	0
	dd	0
	align	4
_1473:
	dd	_303
	dd	1050
	dd	4
	align	4
_1476:
	dd	_303
	dd	1051
	dd	4
	align	4
_1482:
	dd	3
	dd	0
	dd	0
	align	4
_1478:
	dd	_303
	dd	1053
	dd	5
	align	4
_1481:
	dd	_303
	dd	1054
	dd	5
	align	4
_1494:
	dd	3
	dd	0
	dd	0
	align	4
_1484:
	dd	_303
	dd	1055
	dd	4
	align	4
_1490:
	dd	3
	dd	0
	dd	0
	align	4
_1486:
	dd	_303
	dd	1057
	dd	5
	align	4
_1489:
	dd	_303
	dd	1058
	dd	5
	align	4
_1493:
	dd	3
	dd	0
	dd	0
	align	4
_1492:
	dd	_303
	dd	1061
	dd	5
	align	4
_1498:
	dd	3
	dd	0
	dd	0
	align	4
_1497:
	dd	_303
	dd	1065
	dd	4
