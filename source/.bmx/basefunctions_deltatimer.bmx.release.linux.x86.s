	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_source_basefunctions_events
	extrn	bbDelay
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
	extrn	bbStringFromFloat
	extrn	bb_EventManager
	extrn	bb_TEventSimple
	public	__bb_source_basefunctions_deltatimer
	public	_bb_TDeltaTimer_Create
	public	_bb_TDeltaTimer_Delete
	public	_bb_TDeltaTimer_Loop
	public	_bb_TDeltaTimer_New
	public	_bb_TDeltaTimer_getDeltaTime
	public	_bb_TDeltaTimer_getTween
	public	bb_TDeltaTimer
	section	"code" executable
__bb_source_basefunctions_deltatimer:
	push	ebp
	mov	ebp,esp
	cmp	dword [_54],0
	je	_55
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_55:
	mov	dword [_54],1
	call	__bb_blitz_blitz
	call	__bb_source_basefunctions_events
	push	bb_TDeltaTimer
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,0
	jmp	_34
_34:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TDeltaTimer
	mov	dword [ebx+8],0
	mov	dword [ebx+12],0
	fld	dword [_66]
	fstp	dword [ebx+16]
	fld	dword [_67]
	fstp	dword [ebx+20]
	fldz
	fstp	dword [ebx+24]
	fldz
	fstp	dword [ebx+28]
	mov	dword [ebx+32],0
	mov	dword [ebx+36],0
	fldz
	fstp	dword [ebx+40]
	mov	dword [ebx+44],0
	mov	dword [ebx+48],0
	fldz
	fstp	dword [ebx+52]
	fldz
	fstp	dword [ebx+56]
	mov	eax,0
	jmp	_37
_37:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_Delete:
	push	ebp
	mov	ebp,esp
_40:
	mov	eax,0
	jmp	_56
_56:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	push	bb_TDeltaTimer
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	fld	dword [_72]
	mov	dword [ebp+-4],esi
	fild	dword [ebp+-4]
	fdivp	st1,st0
	fstp	dword [ebx+20]
	call	bbMilliSecs
	mov	dword [ebx+8],eax
	mov	dword [ebx+12],0
	mov	eax,ebx
	jmp	_43
_43:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_Loop:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	call	bbMilliSecs
	mov	dword [esi+8],eax
	mov	eax,dword [esi+12]
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	fldz
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setnz	al
	movzx	eax,al
	cmp	eax,0
	jne	_58
	mov	eax,dword [esi+8]
	sub	eax,1
	mov	dword [esi+12],eax
_58:
	fld	dword [esi+52]
	mov	eax,dword [esi+8]
	sub	eax,dword [esi+12]
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	faddp	st1,st0
	fstp	dword [esi+52]
	mov	eax,dword [esi+8]
	sub	eax,dword [esi+12]
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	fdiv	dword [_76]
	fstp	dword [esi+16]
	mov	eax,dword [esi+8]
	mov	dword [esi+12],eax
	fld	dword [esi+52]
	fld	dword [_77]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
	cmp	eax,0
	jne	_59
	fldz
	fstp	dword [esi+52]
	mov	eax,dword [esi+44]
	mov	dword [esi+32],eax
	mov	eax,dword [esi+48]
	mov	dword [esi+36],eax
	fldz
	fstp	dword [esi+40]
	mov	dword [esi+44],0
	mov	dword [esi+48],0
_59:
	fld	dword [esi+16]
	fld	dword [_78]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setbe	al
	movzx	eax,al
	cmp	eax,0
	jne	_60
	fld	dword [_79]
	fstp	dword [esi+16]
_60:
	fld	dword [esi+24]
	fadd	dword [esi+16]
	fstp	dword [esi+24]
	jmp	_3
_5:
	fld	dword [esi+56]
	fadd	dword [esi+20]
	fstp	dword [esi+56]
	fld	dword [esi+24]
	fsub	dword [esi+20]
	fstp	dword [esi+24]
	add	dword [esi+48],1
	mov	ebx,dword [bb_EventManager]
	push	bbNullObject
	push	_6
	call	dword [bb_TEventSimple+56]
	add	esp,8
	push	eax
	push	_6
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,12
_3:
	fld	dword [esi+24]
	fld	dword [esi+20]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_5
_4:
	fld	dword [esi+24]
	fdiv	dword [esi+20]
	fstp	dword [esi+28]
	add	dword [esi+44],1
	mov	ebx,dword [bb_EventManager]
	push	dword [esi+28]
	call	bbStringFromFloat
	add	esp,4
	push	eax
	push	_7
	call	dword [bb_TEventSimple+56]
	add	esp,8
	push	eax
	push	_7
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,12
	push	1
	call	bbDelay
	add	esp,4
	mov	eax,0
	jmp	_46
_46:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_getTween:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	fld	dword [eax+28]
	jmp	_49
_49:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_getDeltaTime:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	fld	dword [eax+20]
	jmp	_52
_52:
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_54:
	dd	0
_9:
	db	"TDeltaTimer",0
_10:
	db	"newTime",0
_11:
	db	"i",0
_12:
	db	"oldTime",0
_13:
	db	"loopTime",0
_14:
	db	"f",0
_15:
	db	"deltaTime",0
_16:
	db	"accumulator",0
_17:
	db	"tweenValue",0
_18:
	db	"fps",0
_19:
	db	"ups",0
_20:
	db	"deltas",0
_21:
	db	"timesDrawn",0
_22:
	db	"timesUpdated",0
_23:
	db	"secondGone",0
_24:
	db	"totalTime",0
_25:
	db	"New",0
_26:
	db	"()i",0
_27:
	db	"Delete",0
_28:
	db	"Create",0
_29:
	db	"(i):TDeltaTimer",0
_30:
	db	"Loop",0
_31:
	db	"getTween",0
_32:
	db	"()f",0
_33:
	db	"getDeltaTime",0
	align	4
_8:
	dd	2
	dd	_9
	dd	3
	dd	_10
	dd	_11
	dd	8
	dd	3
	dd	_12
	dd	_11
	dd	12
	dd	3
	dd	_13
	dd	_14
	dd	16
	dd	3
	dd	_15
	dd	_14
	dd	20
	dd	3
	dd	_16
	dd	_14
	dd	24
	dd	3
	dd	_17
	dd	_14
	dd	28
	dd	3
	dd	_18
	dd	_11
	dd	32
	dd	3
	dd	_19
	dd	_11
	dd	36
	dd	3
	dd	_20
	dd	_14
	dd	40
	dd	3
	dd	_21
	dd	_11
	dd	44
	dd	3
	dd	_22
	dd	_11
	dd	48
	dd	3
	dd	_23
	dd	_14
	dd	52
	dd	3
	dd	_24
	dd	_14
	dd	56
	dd	6
	dd	_25
	dd	_26
	dd	16
	dd	6
	dd	_27
	dd	_26
	dd	20
	dd	7
	dd	_28
	dd	_29
	dd	48
	dd	6
	dd	_30
	dd	_26
	dd	52
	dd	6
	dd	_31
	dd	_32
	dd	56
	dd	6
	dd	_33
	dd	_32
	dd	60
	dd	0
	align	4
bb_TDeltaTimer:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_8
	dd	60
	dd	_bb_TDeltaTimer_New
	dd	_bb_TDeltaTimer_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TDeltaTimer_Create
	dd	_bb_TDeltaTimer_Loop
	dd	_bb_TDeltaTimer_getTween
	dd	_bb_TDeltaTimer_getDeltaTime
	align	4
_66:
	dd	0x3dcccccd
	align	4
_67:
	dd	0x3dcccccd
	align	4
_72:
	dd	0x3f800000
	align	4
_76:
	dd	0x447a0000
	align	4
_77:
	dd	0x447a0000
	align	4
_78:
	dd	0x3e800000
	align	4
_79:
	dd	0x3e800000
	align	4
_6:
	dd	bbStringClass
	dd	2147483647
	dd	12
	dw	65,112,112,46,111,110,85,112,100,97,116,101
	align	4
_7:
	dd	bbStringClass
	dd	2147483647
	dd	10
	dw	65,112,112,46,111,110,68,114,97,119
