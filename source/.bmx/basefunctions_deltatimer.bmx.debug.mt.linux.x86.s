	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_source_basefunctions_events
	extrn	bbDelay
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
	extrn	bbStringFromFloat
	extrn	bb_EventManager
	extrn	bb_TEventSimple
	extrn	brl_blitz_NullObjectError
	public	__bb_source_basefunctions_deltatimer
	public	_bb_TDeltaTimer_Create
	public	_bb_TDeltaTimer_Loop
	public	_bb_TDeltaTimer_New
	public	_bb_TDeltaTimer_getDeltaTime
	public	_bb_TDeltaTimer_getTween
	public	bb_TDeltaTimer
	section	"code" executable
__bb_source_basefunctions_deltatimer:
	push	ebp
	mov	ebp,esp
	push	ebx
	cmp	dword [_54],0
	je	_55
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_55:
	mov	dword [_54],1
	push	ebp
	push	_50
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	__bb_blitz_blitz
	call	__bb_source_basefunctions_events
	push	bb_TDeltaTimer
	call	bbObjectRegisterType
	add	esp,4
	mov	ebx,0
	jmp	_33
_33:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_57
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TDeltaTimer
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],0
	mov	eax,dword [ebp-4]
	fld	dword [_219]
	fstp	dword [eax+16]
	mov	eax,dword [ebp-4]
	fld	dword [_220]
	fstp	dword [eax+20]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+24]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+28]
	mov	eax,dword [ebp-4]
	mov	dword [eax+32],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+36],0
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+40]
	mov	eax,dword [ebp-4]
	mov	dword [eax+44],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+48],0
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+52]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+56]
	push	ebp
	push	_56
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_36
_36:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_76
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_60
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TDeltaTimer
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	push	_63
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_65
	call	brl_blitz_NullObjectError
_65:
	fld	dword [_223]
	mov	eax,dword [ebp-4]
	mov	dword [ebp+-12],eax
	fild	dword [ebp+-12]
	fdivp	st1,st0
	fstp	dword [ebx+20]
	push	_67
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_69
	call	brl_blitz_NullObjectError
_69:
	call	bbMilliSecs
	mov	dword [ebx+8],eax
	push	_71
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_73
	call	brl_blitz_NullObjectError
_73:
	mov	dword [ebx+12],0
	push	_75
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_39
_39:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_Loop:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,ebp
	push	eax
	push	_207
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_79
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_81
	call	brl_blitz_NullObjectError
_81:
	call	bbMilliSecs
	mov	dword [ebx+8],eax
	push	_83
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_85
	call	brl_blitz_NullObjectError
_85:
	mov	eax,dword [ebx+12]
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	fldz
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setnz	al
	movzx	eax,al
	cmp	eax,0
	jne	_86
	mov	eax,ebp
	push	eax
	push	_93
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_87
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_89
	call	brl_blitz_NullObjectError
_89:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_92
	call	brl_blitz_NullObjectError
_92:
	mov	eax,dword [esi+8]
	sub	eax,1
	mov	dword [ebx+12],eax
	call	dword [bbOnDebugLeaveScope]
_86:
	push	_94
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_96
	call	brl_blitz_NullObjectError
_96:
	mov	esi,ebx
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_99
	call	brl_blitz_NullObjectError
_99:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_101
	call	brl_blitz_NullObjectError
_101:
	fld	dword [esi+52]
	mov	eax,dword [edi+8]
	sub	eax,dword [ebx+12]
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	faddp	st1,st0
	fstp	dword [esi+52]
	push	_102
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_104
	call	brl_blitz_NullObjectError
_104:
	mov	edi,ebx
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_107
	call	brl_blitz_NullObjectError
_107:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_109
	call	brl_blitz_NullObjectError
_109:
	mov	eax,dword [esi+8]
	sub	eax,dword [ebx+12]
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	fdiv	dword [_230]
	fstp	dword [edi+16]
	push	_110
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_112
	call	brl_blitz_NullObjectError
_112:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_115
	call	brl_blitz_NullObjectError
_115:
	mov	eax,dword [esi+8]
	mov	dword [ebx+12],eax
	push	_116
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_118
	call	brl_blitz_NullObjectError
_118:
	fld	dword [ebx+52]
	fld	dword [_231]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
	cmp	eax,0
	jne	_119
	mov	eax,ebp
	push	eax
	push	_148
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_120
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_122
	call	brl_blitz_NullObjectError
_122:
	fldz
	fstp	dword [ebx+52]
	push	_124
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_126
	call	brl_blitz_NullObjectError
_126:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_129
	call	brl_blitz_NullObjectError
_129:
	mov	eax,dword [esi+44]
	mov	dword [ebx+32],eax
	push	_130
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_132
	call	brl_blitz_NullObjectError
_132:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_135
	call	brl_blitz_NullObjectError
_135:
	mov	eax,dword [esi+48]
	mov	dword [ebx+36],eax
	push	_136
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_138
	call	brl_blitz_NullObjectError
_138:
	fldz
	fstp	dword [ebx+40]
	push	_140
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_142
	call	brl_blitz_NullObjectError
_142:
	mov	dword [ebx+44],0
	push	_144
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_146
	call	brl_blitz_NullObjectError
_146:
	mov	dword [ebx+48],0
	call	dword [bbOnDebugLeaveScope]
_119:
	push	_149
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_151
	call	brl_blitz_NullObjectError
_151:
	fld	dword [ebx+16]
	fld	dword [_232]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setbe	al
	movzx	eax,al
	cmp	eax,0
	jne	_152
	mov	eax,ebp
	push	eax
	push	_157
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_153
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_155
	call	brl_blitz_NullObjectError
_155:
	fld	dword [_233]
	fstp	dword [ebx+16]
	call	dword [bbOnDebugLeaveScope]
_152:
	push	_158
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_160
	call	brl_blitz_NullObjectError
_160:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_163
	call	brl_blitz_NullObjectError
_163:
	fld	dword [ebx+24]
	fadd	dword [esi+16]
	fstp	dword [ebx+24]
	push	_164
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_3
_5:
	mov	eax,ebp
	push	eax
	push	_188
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_169
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_171
	call	brl_blitz_NullObjectError
_171:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_174
	call	brl_blitz_NullObjectError
_174:
	fld	dword [ebx+56]
	fadd	dword [esi+20]
	fstp	dword [ebx+56]
	push	_175
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_177
	call	brl_blitz_NullObjectError
_177:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_180
	call	brl_blitz_NullObjectError
_180:
	fld	dword [ebx+24]
	fsub	dword [esi+20]
	fstp	dword [ebx+24]
	push	_181
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_183
	call	brl_blitz_NullObjectError
_183:
	add	dword [ebx+48],1
	push	_185
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [bb_EventManager]
	cmp	ebx,bbNullObject
	jne	_187
	call	brl_blitz_NullObjectError
_187:
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
	call	dword [bbOnDebugLeaveScope]
_3:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_166
	call	brl_blitz_NullObjectError
_166:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_168
	call	brl_blitz_NullObjectError
_168:
	fld	dword [esi+24]
	fld	dword [ebx+20]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_5
_4:
	push	_189
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_191
	call	brl_blitz_NullObjectError
_191:
	mov	edi,ebx
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_194
	call	brl_blitz_NullObjectError
_194:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_196
	call	brl_blitz_NullObjectError
_196:
	fld	dword [esi+24]
	fdiv	dword [ebx+20]
	fstp	dword [edi+28]
	push	_197
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_199
	call	brl_blitz_NullObjectError
_199:
	add	dword [ebx+44],1
	push	_201
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [bb_EventManager]
	cmp	ebx,bbNullObject
	jne	_203
	call	brl_blitz_NullObjectError
_203:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_205
	call	brl_blitz_NullObjectError
_205:
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
	push	_206
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	call	bbDelay
	add	esp,4
	mov	ebx,0
	jmp	_42
_42:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_getTween:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_211
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_208
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_210
	call	brl_blitz_NullObjectError
_210:
	fld	dword [ebx+28]
	fstp	dword [ebp-8]
	jmp	_45
_45:
	call	dword [bbOnDebugLeaveScope]
	fld	dword [ebp-8]
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TDeltaTimer_getDeltaTime:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_215
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_212
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_214
	call	brl_blitz_NullObjectError
_214:
	fld	dword [ebx+20]
	fstp	dword [ebp-8]
	jmp	_48
_48:
	call	dword [bbOnDebugLeaveScope]
	fld	dword [ebp-8]
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_54:
	dd	0
_51:
	db	"basefunctions_deltatimer",0
_52:
	db	"EventManager",0
_53:
	db	":TEventManager",0
	align	4
_50:
	dd	1
	dd	_51
	dd	4
	dd	_52
	dd	_53
	dd	bb_EventManager
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
	db	"Create",0
_28:
	db	"(i):TDeltaTimer",0
_29:
	db	"Loop",0
_30:
	db	"getTween",0
_31:
	db	"()f",0
_32:
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
	dd	7
	dd	_27
	dd	_28
	dd	48
	dd	6
	dd	_29
	dd	_26
	dd	52
	dd	6
	dd	_30
	dd	_31
	dd	56
	dd	6
	dd	_32
	dd	_31
	dd	60
	dd	0
	align	4
bb_TDeltaTimer:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_8
	dd	60
	dd	_bb_TDeltaTimer_New
	dd	bbObjectDtor
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
_58:
	db	"Self",0
_59:
	db	":TDeltaTimer",0
	align	4
_57:
	dd	1
	dd	_25
	dd	2
	dd	_58
	dd	_59
	dd	-4
	dd	0
	align	4
_219:
	dd	0x3dcccccd
	align	4
_220:
	dd	0x3dcccccd
	align	4
_56:
	dd	3
	dd	0
	dd	0
_77:
	db	"physicsFps",0
_78:
	db	"obj",0
	align	4
_76:
	dd	1
	dd	_27
	dd	2
	dd	_77
	dd	_11
	dd	-4
	dd	2
	dd	_78
	dd	_59
	dd	-8
	dd	0
_61:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_deltatimer.bmx",0
	align	4
_60:
	dd	_61
	dd	23
	dd	3
	align	4
_63:
	dd	_61
	dd	24
	dd	3
	align	4
_223:
	dd	0x3f800000
	align	4
_67:
	dd	_61
	dd	25
	dd	3
	align	4
_71:
	dd	_61
	dd	26
	dd	3
	align	4
_75:
	dd	_61
	dd	27
	dd	3
	align	4
_207:
	dd	1
	dd	_29
	dd	2
	dd	_58
	dd	_59
	dd	-4
	dd	0
	align	4
_79:
	dd	_61
	dd	31
	dd	3
	align	4
_83:
	dd	_61
	dd	32
	dd	3
	align	4
_93:
	dd	3
	dd	0
	dd	0
	align	4
_87:
	dd	_61
	dd	32
	dd	30
	align	4
_94:
	dd	_61
	dd	33
	dd	3
	align	4
_102:
	dd	_61
	dd	34
	dd	3
	align	4
_230:
	dd	0x447a0000
	align	4
_110:
	dd	_61
	dd	35
	dd	3
	align	4
_116:
	dd	_61
	dd	37
	dd	3
	align	4
_231:
	dd	0x447a0000
	align	4
_148:
	dd	3
	dd	0
	dd	0
	align	4
_120:
	dd	_61
	dd	38
	dd	4
	align	4
_124:
	dd	_61
	dd	39
	dd	4
	align	4
_130:
	dd	_61
	dd	40
	dd	4
	align	4
_136:
	dd	_61
	dd	43
	dd	4
	align	4
_140:
	dd	_61
	dd	44
	dd	4
	align	4
_144:
	dd	_61
	dd	45
	dd	4
	align	4
_149:
	dd	_61
	dd	49
	dd	3
	align	4
_232:
	dd	0x3e800000
	align	4
_157:
	dd	3
	dd	0
	dd	0
	align	4
_153:
	dd	_61
	dd	49
	dd	32
	align	4
_233:
	dd	0x3e800000
	align	4
_158:
	dd	_61
	dd	50
	dd	3
	align	4
_164:
	dd	_61
	dd	53
	dd	3
	align	4
_188:
	dd	3
	dd	0
	dd	0
	align	4
_169:
	dd	_61
	dd	54
	dd	4
	align	4
_175:
	dd	_61
	dd	55
	dd	4
	align	4
_181:
	dd	_61
	dd	56
	dd	4
	align	4
_185:
	dd	_61
	dd	57
	dd	4
	align	4
_6:
	dd	bbStringClass
	dd	2147483647
	dd	12
	dw	65,112,112,46,111,110,85,112,100,97,116,101
	align	4
_189:
	dd	_61
	dd	60
	dd	3
	align	4
_197:
	dd	_61
	dd	63
	dd	3
	align	4
_201:
	dd	_61
	dd	64
	dd	3
	align	4
_7:
	dd	bbStringClass
	dd	2147483647
	dd	10
	dw	65,112,112,46,111,110,68,114,97,119
	align	4
_206:
	dd	_61
	dd	65
	dd	3
	align	4
_211:
	dd	1
	dd	_30
	dd	2
	dd	_58
	dd	_59
	dd	-4
	dd	0
	align	4
_208:
	dd	_61
	dd	72
	dd	3
	align	4
_215:
	dd	1
	dd	_32
	dd	2
	dd	_58
	dd	_59
	dd	-4
	dd	0
	align	4
_212:
	dd	_61
	dd	78
	dd	3
