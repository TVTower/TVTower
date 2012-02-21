	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_map_map
	extrn	__bb_retro_retro
	extrn	bbGCFree
	extrn	bbNullObject
	extrn	bbObjectClass
	extrn	bbObjectCompare
	extrn	bbObjectCtor
	extrn	bbObjectDowncast
	extrn	bbObjectFree
	extrn	bbObjectNew
	extrn	bbObjectRegisterType
	extrn	bbObjectReserved
	extrn	bbObjectSendMessage
	extrn	bbObjectToString
	extrn	bbStringClass
	extrn	bbStringCompare
	extrn	bbStringConcat
	extrn	brl_blitz_NullFunctionError
	extrn	brl_blitz_NullMethodError
	extrn	brl_linkedlist_CreateList
	extrn	brl_linkedlist_TList
	extrn	brl_map_CreateMap
	extrn	brl_retro_Lower
	extrn	brl_standardio_Print
	public	__bb_source_basefunctions_events
	public	_bb_TEventBase_Compare
	public	_bb_TEventBase_Delete
	public	_bb_TEventBase_New
	public	_bb_TEventBase_getStartTime
	public	_bb_TEventBase_onEvent
	public	_bb_TEventListenerBase_Delete
	public	_bb_TEventListenerBase_New
	public	_bb_TEventListenerRunFunction_Create
	public	_bb_TEventListenerRunFunction_Delete
	public	_bb_TEventListenerRunFunction_New
	public	_bb_TEventListenerRunFunction_OnEvent
	public	_bb_TEventManager_Delete
	public	_bb_TEventManager_New
	public	_bb_TEventManager__processEvents
	public	_bb_TEventManager_getTicks
	public	_bb_TEventManager_isFinished
	public	_bb_TEventManager_isStarted
	public	_bb_TEventManager_registerEvent
	public	_bb_TEventManager_registerListener
	public	_bb_TEventManager_triggerEvent
	public	_bb_TEventManager_unregisterListener
	public	_bb_TEventManager_update
	public	_bb_TEventSimple_Create
	public	_bb_TEventSimple_Delete
	public	_bb_TEventSimple_New
	public	bb_EventManager
	public	bb_TEventBase
	public	bb_TEventListenerBase
	public	bb_TEventListenerRunFunction
	public	bb_TEventManager
	public	bb_TEventSimple
	section	"code" executable
__bb_source_basefunctions_events:
	push	ebp
	mov	ebp,esp
	cmp	dword [_144],0
	je	_145
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_145:
	mov	dword [_144],1
	call	__bb_blitz_blitz
	call	__bb_map_map
	call	__bb_retro_retro
	call	__bb_glmax2d_glmax2d
	push	bb_TEventManager
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TEventListenerBase
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TEventListenerRunFunction
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TEventBase
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TEventSimple
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,dword [_142]
	and	eax,1
	cmp	eax,0
	jne	_143
	push	bb_TEventManager
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	dword [bb_EventManager],eax
	or	dword [_142],1
_143:
	mov	eax,0
	jmp	_54
_54:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TEventManager
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	dword [ebx+12],-1
	call	brl_map_CreateMap
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	eax,0
	jmp	_57
_57:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_60:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_150
	push	eax
	call	bbGCFree
	add	esp,4
_150:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_152
	push	eax
	call	bbGCFree
	add	esp,4
_152:
	mov	eax,0
	jmp	_148
_148:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_getTicks:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	jmp	_63
_63:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_isStarted:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	cmp	eax,-1
	setne	al
	movzx	eax,al
	jmp	_66
_66:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_isFinished:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	jmp	_69
_69:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_registerListener:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+12]
	push	esi
	call	brl_retro_Lower
	add	esp,4
	mov	esi,eax
	push	esi
	push	_3
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	mov	eax,dword [edi+16]
	push	brl_linkedlist_TList
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_156
	call	brl_linkedlist_CreateList
	mov	ebx,eax
	mov	eax,dword [edi+16]
	push	ebx
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,12
_156:
	mov	eax,ebx
	push	dword [ebp+16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	eax,0
	jmp	_74
_74:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_unregisterListener:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	mov	esi,dword [edx+16]
	push	brl_linkedlist_TList
	push	eax
	call	brl_retro_Lower
	add	esp,4
	push	eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_161
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+116]
	add	esp,8
_161:
	mov	eax,0
	jmp	_79
_79:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_registerEvent:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+8]
	push	edx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	eax,0
	jmp	_83
_83:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_triggerEvent:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	edi,dword [ebp+16]
	mov	ebx,dword [edx+16]
	push	brl_linkedlist_TList
	push	eax
	call	brl_retro_Lower
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_166
	mov	esi,eax
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_4
_6:
	mov	eax,ebx
	push	bb_TEventListenerBase
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_4
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,8
_4:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_6
_5:
_166:
	mov	eax,0
	jmp	_88
_88:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_update:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+80]
	add	esp,4
	add	dword [ebx+12],1
	mov	eax,0
	jmp	_91
_91:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager__processEvents:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	eax,dword [esi+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	jne	_176
	mov	eax,dword [esi+8]
	push	bb_TEventBase
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	je	_179
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,dword [esi+12]
	jg	_182
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	_1
	push	dword [ebx+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_184
	push	ebx
	push	dword [ebx+12]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+72]
	add	esp,12
_184:
	mov	eax,dword [esi+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+80]
	add	esp,4
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+80]
	add	esp,4
_182:
_179:
_176:
	mov	eax,0
	jmp	_94
_94:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerBase_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TEventListenerBase
	mov	eax,0
	jmp	_97
_97:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerBase_Delete:
	push	ebp
	mov	ebp,esp
_100:
	mov	eax,0
	jmp	_188
_188:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerRunFunction_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_TEventListenerBase_New
	add	esp,4
	mov	dword [ebx],bb_TEventListenerRunFunction
	mov	dword [ebx+8],brl_blitz_NullFunctionError
	mov	eax,0
	jmp	_103
_103:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerRunFunction_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_106:
	mov	dword [eax],bb_TEventListenerBase
	push	eax
	call	_bb_TEventListenerBase_Delete
	add	esp,4
	mov	eax,0
	jmp	_189
_189:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerRunFunction_Create:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	bb_TEventListenerRunFunction
	call	bbObjectNew
	add	esp,4
	mov	dword [eax+8],ebx
	jmp	_109
_109:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerRunFunction_OnEvent:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	eax
	call	dword [edx+8]
	add	esp,4
	mov	eax,0
	jmp	_113
_113:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventBase_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TEventBase
	mov	dword [ebx+8],0
	mov	eax,_1
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	eax,0
	jmp	_116
_116:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventBase_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_119:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_195
	push	eax
	call	bbGCFree
	add	esp,4
_195:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_197
	push	eax
	call	bbGCFree
	add	esp,4
_197:
	mov	eax,0
	jmp	_193
_193:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventBase_getStartTime:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	jmp	_122
_122:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventBase_onEvent:
	push	ebp
	mov	ebp,esp
	mov	eax,0
	jmp	_125
_125:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventBase_Compare:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+12]
	push	bb_TEventBase
	push	esi
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_199
	push	esi
	push	edi
	call	bbObjectCompare
	add	esp,8
	jmp	_129
_199:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	esi,eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	esi,eax
	jle	_206
	mov	eax,1
	jmp	_129
_206:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	esi,eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	esi,eax
	jge	_210
	mov	eax,-1
	jmp	_129
_210:
	mov	eax,0
	jmp	_129
_129:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventSimple_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_TEventBase_New
	add	esp,4
	mov	dword [ebx],bb_TEventSimple
	mov	eax,0
	jmp	_132
_132:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventSimple_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_135:
	mov	dword [eax],bb_TEventBase
	push	eax
	call	_bb_TEventBase_Delete
	add	esp,4
	mov	eax,0
	jmp	_212
_212:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventSimple_Create:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	push	bb_TEventSimple
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,esi
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_217
	push	eax
	call	bbGCFree
	add	esp,4
_217:
	mov	dword [ebx+12],esi
	mov	esi,edi
	inc	dword [esi+4]
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_221
	push	eax
	call	bbGCFree
	add	esp,4
_221:
	mov	dword [ebx+16],esi
	mov	eax,ebx
	jmp	_139
_139:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_144:
	dd	0
_10:
	db	"TEventManager",0
_11:
	db	"_events",0
_12:
	db	":brl.linkedlist.TList",0
_13:
	db	"_ticks",0
_14:
	db	"i",0
_15:
	db	"_listeners",0
_16:
	db	":brl.map.TMap",0
_17:
	db	"New",0
_18:
	db	"()i",0
_19:
	db	"Delete",0
_20:
	db	"getTicks",0
_21:
	db	"isStarted",0
_22:
	db	"isFinished",0
_23:
	db	"registerListener",0
_24:
	db	"($,:TEventListenerBase)i",0
_25:
	db	"unregisterListener",0
_26:
	db	"registerEvent",0
_27:
	db	"(:TEventBase)i",0
_28:
	db	"triggerEvent",0
_29:
	db	"($,:TEventBase)i",0
_30:
	db	"update",0
_31:
	db	"_processEvents",0
	align	4
_9:
	dd	2
	dd	_10
	dd	3
	dd	_11
	dd	_12
	dd	8
	dd	3
	dd	_13
	dd	_14
	dd	12
	dd	3
	dd	_15
	dd	_16
	dd	16
	dd	6
	dd	_17
	dd	_18
	dd	16
	dd	6
	dd	_19
	dd	_18
	dd	20
	dd	6
	dd	_20
	dd	_18
	dd	48
	dd	6
	dd	_21
	dd	_18
	dd	52
	dd	6
	dd	_22
	dd	_18
	dd	56
	dd	6
	dd	_23
	dd	_24
	dd	60
	dd	6
	dd	_25
	dd	_24
	dd	64
	dd	6
	dd	_26
	dd	_27
	dd	68
	dd	6
	dd	_28
	dd	_29
	dd	72
	dd	6
	dd	_30
	dd	_18
	dd	76
	dd	6
	dd	_31
	dd	_18
	dd	80
	dd	0
	align	4
bb_TEventManager:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_9
	dd	20
	dd	_bb_TEventManager_New
	dd	_bb_TEventManager_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TEventManager_getTicks
	dd	_bb_TEventManager_isStarted
	dd	_bb_TEventManager_isFinished
	dd	_bb_TEventManager_registerListener
	dd	_bb_TEventManager_unregisterListener
	dd	_bb_TEventManager_registerEvent
	dd	_bb_TEventManager_triggerEvent
	dd	_bb_TEventManager_update
	dd	_bb_TEventManager__processEvents
_33:
	db	"TEventListenerBase",0
_34:
	db	"onEvent",0
	align	4
_32:
	dd	2
	dd	_33
	dd	6
	dd	_17
	dd	_18
	dd	16
	dd	6
	dd	_19
	dd	_18
	dd	20
	dd	6
	dd	_34
	dd	_27
	dd	48
	dd	0
	align	4
bb_TEventListenerBase:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_32
	dd	8
	dd	_bb_TEventListenerBase_New
	dd	_bb_TEventListenerBase_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	brl_blitz_NullMethodError
_36:
	db	"TEventListenerRunFunction",0
_37:
	db	"_function",0
_38:
	db	"Create",0
_39:
	db	"((:TEventBase)i):TEventListenerRunFunction",0
_40:
	db	"OnEvent",0
	align	4
_35:
	dd	2
	dd	_36
	dd	3
	dd	_37
	dd	_27
	dd	8
	dd	6
	dd	_17
	dd	_18
	dd	16
	dd	6
	dd	_19
	dd	_18
	dd	20
	dd	7
	dd	_38
	dd	_39
	dd	52
	dd	6
	dd	_40
	dd	_27
	dd	48
	dd	0
	align	4
bb_TEventListenerRunFunction:
	dd	bb_TEventListenerBase
	dd	bbObjectFree
	dd	_35
	dd	12
	dd	_bb_TEventListenerRunFunction_New
	dd	_bb_TEventListenerRunFunction_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TEventListenerRunFunction_OnEvent
	dd	_bb_TEventListenerRunFunction_Create
_42:
	db	"TEventBase",0
_43:
	db	"_startTime",0
_44:
	db	"_trigger",0
_45:
	db	"$",0
_46:
	db	"_data",0
_47:
	db	":Object",0
_48:
	db	"getStartTime",0
_49:
	db	"Compare",0
_50:
	db	"(:Object)i",0
	align	4
_41:
	dd	2
	dd	_42
	dd	3
	dd	_43
	dd	_14
	dd	8
	dd	3
	dd	_44
	dd	_45
	dd	12
	dd	3
	dd	_46
	dd	_47
	dd	16
	dd	6
	dd	_17
	dd	_18
	dd	16
	dd	6
	dd	_19
	dd	_18
	dd	20
	dd	6
	dd	_48
	dd	_18
	dd	48
	dd	6
	dd	_34
	dd	_18
	dd	52
	dd	6
	dd	_49
	dd	_50
	dd	28
	dd	0
	align	4
bb_TEventBase:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_41
	dd	20
	dd	_bb_TEventBase_New
	dd	_bb_TEventBase_Delete
	dd	bbObjectToString
	dd	_bb_TEventBase_Compare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TEventBase_getStartTime
	dd	_bb_TEventBase_onEvent
_52:
	db	"TEventSimple",0
_53:
	db	"($,:Object):TEventSimple",0
	align	4
_51:
	dd	2
	dd	_52
	dd	6
	dd	_17
	dd	_18
	dd	16
	dd	6
	dd	_19
	dd	_18
	dd	20
	dd	7
	dd	_38
	dd	_53
	dd	56
	dd	0
	align	4
bb_TEventSimple:
	dd	bb_TEventBase
	dd	bbObjectFree
	dd	_51
	dd	20
	dd	_bb_TEventSimple_New
	dd	_bb_TEventSimple_Delete
	dd	bbObjectToString
	dd	_bb_TEventBase_Compare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TEventBase_getStartTime
	dd	_bb_TEventBase_onEvent
	dd	_bb_TEventSimple_Create
	align	4
_142:
	dd	0
	align	4
bb_EventManager:
	dd	bbNullObject
	align	4
_3:
	dd	bbStringClass
	dd	2147483647
	dd	10
	dw	114,101,103,105,115,116,101,114,58,32
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
