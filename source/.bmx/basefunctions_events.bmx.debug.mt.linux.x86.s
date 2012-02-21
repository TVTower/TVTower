	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_map_map
	extrn	__bb_retro_retro
	extrn	bbNullObject
	extrn	bbObjectClass
	extrn	bbObjectCompare
	extrn	bbObjectCtor
	extrn	bbObjectDowncast
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
	extrn	bbStringCompare
	extrn	bbStringConcat
	extrn	brl_blitz_NullFunctionError
	extrn	brl_blitz_NullMethodError
	extrn	brl_blitz_NullObjectError
	extrn	brl_blitz_RuntimeError
	extrn	brl_linkedlist_CreateList
	extrn	brl_linkedlist_TList
	extrn	brl_map_CreateMap
	extrn	brl_retro_Lower
	extrn	brl_standardio_Print
	public	__bb_source_basefunctions_events
	public	_bb_TEventBase_Compare
	public	_bb_TEventBase_New
	public	_bb_TEventBase_getStartTime
	public	_bb_TEventBase_onEvent
	public	_bb_TEventListenerBase_New
	public	_bb_TEventListenerRunFunction_Create
	public	_bb_TEventListenerRunFunction_New
	public	_bb_TEventListenerRunFunction_OnEvent
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
	push	ebx
	cmp	dword [_133],0
	je	_134
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_134:
	mov	dword [_133],1
	push	ebp
	push	_129
	call	dword [bbOnDebugEnterScope]
	add	esp,8
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
	push	_125
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_127]
	and	eax,1
	cmp	eax,0
	jne	_128
	push	bb_TEventManager
	call	bbObjectNew
	add	esp,4
	mov	dword [bb_EventManager],eax
	or	dword [_127],1
_128:
	mov	ebx,0
	jmp	_53
_53:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_136
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TEventManager
	mov	ebx,dword [ebp-4]
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+8],eax
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],-1
	mov	ebx,dword [ebp-4]
	call	brl_map_CreateMap
	mov	dword [ebx+16],eax
	push	ebp
	push	_135
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_56
_56:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_getTicks:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_141
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_138
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_140
	call	brl_blitz_NullObjectError
_140:
	mov	ebx,dword [ebx+12]
	jmp	_59
_59:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_isStarted:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_145
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_142
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_144
	call	brl_blitz_NullObjectError
_144:
	mov	eax,dword [ebx+12]
	cmp	eax,-1
	setne	al
	movzx	eax,al
	mov	ebx,eax
	jmp	_62
_62:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_isFinished:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_151
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_146
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_148
	call	brl_blitz_NullObjectError
_148:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_150
	call	brl_blitz_NullObjectError
_150:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	mov	ebx,eax
	jmp	_65
_65:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_registerListener:
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
	mov	dword [ebp-16],bbNullObject
	push	ebp
	push	_172
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_152
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_153
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	push	_3
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	push	_154
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_156
	call	brl_blitz_NullObjectError
_156:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_158
	call	brl_blitz_NullObjectError
_158:
	push	brl_linkedlist_TList
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-16],eax
	push	_160
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],bbNullObject
	jne	_161
	push	ebp
	push	_168
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_162
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	brl_linkedlist_CreateList
	mov	dword [ebp-16],eax
	push	_163
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_165
	call	brl_blitz_NullObjectError
_165:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_167
	call	brl_blitz_NullObjectError
_167:
	push	dword [ebp-16]
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_161:
	push	_169
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_171
	call	brl_blitz_NullObjectError
_171:
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	mov	ebx,0
	jmp	_70
_70:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_unregisterListener:
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
	mov	dword [ebp-16],bbNullObject
	push	ebp
	push	_189
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_177
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_179
	call	brl_blitz_NullObjectError
_179:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_181
	call	brl_blitz_NullObjectError
_181:
	push	brl_linkedlist_TList
	push	dword [ebp-8]
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
	mov	dword [ebp-16],eax
	push	_183
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],bbNullObject
	je	_184
	push	ebp
	push	_188
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_185
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_187
	call	brl_blitz_NullObjectError
_187:
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+116]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_184:
	mov	ebx,0
	jmp	_75
_75:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_registerEvent:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_195
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_190
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_192
	call	brl_blitz_NullObjectError
_192:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_194
	call	brl_blitz_NullObjectError
_194:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	mov	ebx,0
	jmp	_79
_79:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_triggerEvent:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],bbNullObject
	mov	eax,ebp
	push	eax
	push	_222
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_198
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_200
	call	brl_blitz_NullObjectError
_200:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_202
	call	brl_blitz_NullObjectError
_202:
	push	brl_linkedlist_TList
	push	dword [ebp-8]
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
	mov	dword [ebp-16],eax
	push	_204
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],bbNullObject
	je	_205
	mov	eax,ebp
	push	eax
	push	_221
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_206
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],bbNullObject
	mov	edi,dword [ebp-16]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_210
	call	brl_blitz_NullObjectError
_210:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_4
_6:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_215
	call	brl_blitz_NullObjectError
_215:
	push	bb_TEventListenerBase
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],bbNullObject
	je	_4
	mov	eax,ebp
	push	eax
	push	_219
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_216
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_218
	call	brl_blitz_NullObjectError
_218:
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_4:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_213
	call	brl_blitz_NullObjectError
_213:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_6
_5:
	call	dword [bbOnDebugLeaveScope]
_205:
	mov	ebx,0
	jmp	_84
_84:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager_update:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_235
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_224
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_226
	call	brl_blitz_NullObjectError
_226:
	cmp	dword [ebx+12],0
	jge	_227
	push	_7
	call	brl_blitz_RuntimeError
	add	esp,4
_227:
	push	_228
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_230
	call	brl_blitz_NullObjectError
_230:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+80]
	add	esp,4
	push	_231
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_233
	call	brl_blitz_NullObjectError
_233:
	add	dword [ebx+12],1
	mov	ebx,0
	jmp	_87
_87:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventManager__processEvents:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	mov	dword [ebp-12],0
	push	ebp
	push	_287
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_236
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_238
	call	brl_blitz_NullObjectError
_238:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_240
	call	brl_blitz_NullObjectError
_240:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	jne	_241
	push	ebp
	push	_286
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_242
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_244
	call	brl_blitz_NullObjectError
_244:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_246
	call	brl_blitz_NullObjectError
_246:
	push	bb_TEventBase
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-8],eax
	push	_248
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	je	_249
	push	ebp
	push	_284
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_250
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_252
	call	brl_blitz_NullObjectError
_252:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	mov	dword [ebp-12],eax
	push	_254
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_256
	call	brl_blitz_NullObjectError
_256:
	mov	eax,dword [ebx+12]
	cmp	dword [ebp-12],eax
	jge	_257
	push	_8
	call	brl_blitz_RuntimeError
	add	esp,4
_257:
	push	_258
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_260
	call	brl_blitz_NullObjectError
_260:
	mov	eax,dword [ebx+12]
	cmp	dword [ebp-12],eax
	jg	_261
	push	ebp
	push	_283
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_262
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_264
	call	brl_blitz_NullObjectError
_264:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	_265
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_267
	call	brl_blitz_NullObjectError
_267:
	push	_1
	push	dword [ebx+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_268
	push	ebp
	push	_274
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_269
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_271
	call	brl_blitz_NullObjectError
_271:
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_273
	call	brl_blitz_NullObjectError
_273:
	push	dword [ebp-8]
	push	dword [ebx+12]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+72]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_268:
	push	_275
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_277
	call	brl_blitz_NullObjectError
_277:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_279
	call	brl_blitz_NullObjectError
_279:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+80]
	add	esp,4
	push	_280
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_282
	call	brl_blitz_NullObjectError
_282:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+80]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_261:
	call	dword [bbOnDebugLeaveScope]
_249:
	call	dword [bbOnDebugLeaveScope]
_241:
	mov	ebx,0
	jmp	_90
_90:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerBase_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_289
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TEventListenerBase
	push	ebp
	push	_288
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_93
_93:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerRunFunction_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_291
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	_bb_TEventListenerBase_New
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TEventListenerRunFunction
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],brl_blitz_NullFunctionError
	push	ebp
	push	_290
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_96
_96:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerRunFunction_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_300
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_293
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TEventListenerRunFunction
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	push	_295
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_297
	call	brl_blitz_NullObjectError
_297:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+8],eax
	push	_299
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_99
_99:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventListenerRunFunction_OnEvent:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_305
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_302
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_304
	call	brl_blitz_NullObjectError
_304:
	push	dword [ebp-8]
	call	dword [ebx+8]
	add	esp,4
	mov	ebx,0
	jmp	_103
_103:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventBase_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_307
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TEventBase
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],_1
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],bbNullObject
	push	ebp
	push	_306
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_106
_106:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventBase_getStartTime:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_311
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_308
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_310
	call	brl_blitz_NullObjectError
_310:
	mov	ebx,dword [ebx+8]
	jmp	_109
_109:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventBase_onEvent:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_312
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	mov	ebx,0
	jmp	_112
_112:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventBase_Compare:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	push	ebp
	push	_348
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_313
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TEventBase
	push	dword [ebp-8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-12],eax
	push	_315
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_316
	push	ebp
	push	_318
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_317
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	push	dword [ebp-4]
	call	bbObjectCompare
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_116
_316:
	push	_319
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_321
	call	brl_blitz_NullObjectError
_321:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_323
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_325
	call	brl_blitz_NullObjectError
_325:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	mov	dword [ebp-20],eax
	push	_327
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_329
	call	brl_blitz_NullObjectError
_329:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_331
	call	brl_blitz_NullObjectError
_331:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	mov	ebx,eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+48]
	add	esp,4
	cmp	ebx,eax
	jle	_332
	push	ebp
	push	_334
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_333
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	jmp	_116
_332:
	push	ebp
	push	_347
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_336
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_338
	call	brl_blitz_NullObjectError
_338:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_340
	call	brl_blitz_NullObjectError
_340:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	mov	ebx,eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+48]
	add	esp,4
	cmp	ebx,eax
	jge	_341
	push	ebp
	push	_343
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_342
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,-1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_116
_341:
	push	ebp
	push	_346
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_345
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_116
_116:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventSimple_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_353
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	_bb_TEventBase_New
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TEventSimple
	push	ebp
	push	_352
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_119
_119:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TEventSimple_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],bbNullObject
	push	ebp
	push	_366
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_355
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TEventSimple
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-12],eax
	push	_357
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_359
	call	brl_blitz_NullObjectError
_359:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+12],eax
	push	_361
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_363
	call	brl_blitz_NullObjectError
_363:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+16],eax
	push	_365
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_123
_123:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_133:
	dd	0
_130:
	db	"basefunctions_events",0
_131:
	db	"EventManager",0
_132:
	db	":TEventManager",0
	align	4
bb_EventManager:
	dd	bbNullObject
	align	4
_129:
	dd	1
	dd	_130
	dd	4
	dd	_131
	dd	_132
	dd	bb_EventManager
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
	db	"getTicks",0
_20:
	db	"isStarted",0
_21:
	db	"isFinished",0
_22:
	db	"registerListener",0
_23:
	db	"($,:TEventListenerBase)i",0
_24:
	db	"unregisterListener",0
_25:
	db	"registerEvent",0
_26:
	db	"(:TEventBase)i",0
_27:
	db	"triggerEvent",0
_28:
	db	"($,:TEventBase)i",0
_29:
	db	"update",0
_30:
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
	dd	48
	dd	6
	dd	_20
	dd	_18
	dd	52
	dd	6
	dd	_21
	dd	_18
	dd	56
	dd	6
	dd	_22
	dd	_23
	dd	60
	dd	6
	dd	_24
	dd	_23
	dd	64
	dd	6
	dd	_25
	dd	_26
	dd	68
	dd	6
	dd	_27
	dd	_28
	dd	72
	dd	6
	dd	_29
	dd	_18
	dd	76
	dd	6
	dd	_30
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
	dd	bbObjectDtor
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
_32:
	db	"TEventListenerBase",0
_33:
	db	"onEvent",0
	align	4
_31:
	dd	2
	dd	_32
	dd	6
	dd	_17
	dd	_18
	dd	16
	dd	6
	dd	_33
	dd	_26
	dd	48
	dd	0
	align	4
bb_TEventListenerBase:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_31
	dd	8
	dd	_bb_TEventListenerBase_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	brl_blitz_NullMethodError
_35:
	db	"TEventListenerRunFunction",0
_36:
	db	"_function",0
_37:
	db	"Create",0
_38:
	db	"((:TEventBase)i):TEventListenerRunFunction",0
_39:
	db	"OnEvent",0
	align	4
_34:
	dd	2
	dd	_35
	dd	3
	dd	_36
	dd	_26
	dd	8
	dd	6
	dd	_17
	dd	_18
	dd	16
	dd	7
	dd	_37
	dd	_38
	dd	52
	dd	6
	dd	_39
	dd	_26
	dd	48
	dd	0
	align	4
bb_TEventListenerRunFunction:
	dd	bb_TEventListenerBase
	dd	bbObjectFree
	dd	_34
	dd	12
	dd	_bb_TEventListenerRunFunction_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TEventListenerRunFunction_OnEvent
	dd	_bb_TEventListenerRunFunction_Create
_41:
	db	"TEventBase",0
_42:
	db	"_startTime",0
_43:
	db	"_trigger",0
_44:
	db	"$",0
_45:
	db	"_data",0
_46:
	db	":Object",0
_47:
	db	"getStartTime",0
_48:
	db	"Compare",0
_49:
	db	"(:Object)i",0
	align	4
_40:
	dd	2
	dd	_41
	dd	3
	dd	_42
	dd	_14
	dd	8
	dd	3
	dd	_43
	dd	_44
	dd	12
	dd	3
	dd	_45
	dd	_46
	dd	16
	dd	6
	dd	_17
	dd	_18
	dd	16
	dd	6
	dd	_47
	dd	_18
	dd	48
	dd	6
	dd	_33
	dd	_18
	dd	52
	dd	6
	dd	_48
	dd	_49
	dd	28
	dd	0
	align	4
bb_TEventBase:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_40
	dd	20
	dd	_bb_TEventBase_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	_bb_TEventBase_Compare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TEventBase_getStartTime
	dd	_bb_TEventBase_onEvent
_51:
	db	"TEventSimple",0
_52:
	db	"($,:Object):TEventSimple",0
	align	4
_50:
	dd	2
	dd	_51
	dd	6
	dd	_17
	dd	_18
	dd	16
	dd	7
	dd	_37
	dd	_52
	dd	56
	dd	0
	align	4
bb_TEventSimple:
	dd	bb_TEventBase
	dd	bbObjectFree
	dd	_50
	dd	20
	dd	_bb_TEventSimple_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	_bb_TEventBase_Compare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TEventBase_getStartTime
	dd	_bb_TEventBase_onEvent
	dd	_bb_TEventSimple_Create
_126:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_events.bmx",0
	align	4
_125:
	dd	_126
	dd	6
	dd	1
	align	4
_127:
	dd	0
_137:
	db	"Self",0
	align	4
_136:
	dd	1
	dd	_17
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	0
	align	4
_135:
	dd	3
	dd	0
	dd	0
	align	4
_141:
	dd	1
	dd	_19
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	0
	align	4
_138:
	dd	_126
	dd	14
	dd	3
	align	4
_145:
	dd	1
	dd	_20
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	0
	align	4
_142:
	dd	_126
	dd	18
	dd	3
	align	4
_151:
	dd	1
	dd	_21
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	0
	align	4
_146:
	dd	_126
	dd	22
	dd	3
_173:
	db	"trigger",0
_174:
	db	"eventListener",0
_175:
	db	":TEventListenerBase",0
_176:
	db	"listeners",0
	align	4
_172:
	dd	1
	dd	_22
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	2
	dd	_173
	dd	_44
	dd	-8
	dd	2
	dd	_174
	dd	_175
	dd	-12
	dd	2
	dd	_176
	dd	_12
	dd	-16
	dd	0
	align	4
_152:
	dd	_126
	dd	27
	dd	3
	align	4
_153:
	dd	_126
	dd	28
	dd	3
	align	4
_3:
	dd	bbStringClass
	dd	2147483647
	dd	10
	dw	114,101,103,105,115,116,101,114,58,32
	align	4
_154:
	dd	_126
	dd	29
	dd	3
	align	4
_160:
	dd	_126
	dd	30
	dd	3
	align	4
_168:
	dd	3
	dd	0
	dd	0
	align	4
_162:
	dd	_126
	dd	31
	dd	4
	align	4
_163:
	dd	_126
	dd	32
	dd	4
	align	4
_169:
	dd	_126
	dd	34
	dd	3
	align	4
_189:
	dd	1
	dd	_24
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	2
	dd	_173
	dd	_44
	dd	-8
	dd	2
	dd	_174
	dd	_175
	dd	-12
	dd	2
	dd	_176
	dd	_12
	dd	-16
	dd	0
	align	4
_177:
	dd	_126
	dd	39
	dd	3
	align	4
_183:
	dd	_126
	dd	40
	dd	3
	align	4
_188:
	dd	3
	dd	0
	dd	0
	align	4
_185:
	dd	_126
	dd	40
	dd	29
_196:
	db	"event",0
_197:
	db	":TEventBase",0
	align	4
_195:
	dd	1
	dd	_25
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	2
	dd	_196
	dd	_197
	dd	-8
	dd	0
	align	4
_190:
	dd	_126
	dd	47
	dd	3
_223:
	db	"triggeredByEvent",0
	align	4
_222:
	dd	1
	dd	_27
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	2
	dd	_173
	dd	_44
	dd	-8
	dd	2
	dd	_223
	dd	_197
	dd	-12
	dd	2
	dd	_176
	dd	_12
	dd	-16
	dd	0
	align	4
_198:
	dd	_126
	dd	51
	dd	3
	align	4
_204:
	dd	_126
	dd	52
	dd	3
	align	4
_221:
	dd	3
	dd	0
	dd	0
	align	4
_206:
	dd	_126
	dd	53
	dd	4
_220:
	db	"listener",0
	align	4
_219:
	dd	3
	dd	0
	dd	2
	dd	_220
	dd	_175
	dd	-20
	dd	0
	align	4
_216:
	dd	_126
	dd	54
	dd	5
	align	4
_235:
	dd	1
	dd	_29
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	0
	align	4
_224:
	dd	_126
	dd	60
	dd	3
	align	4
_7:
	dd	bbStringClass
	dd	2147483647
	dd	63
	dw	84,69,118,101,110,116,77,97,110,97,103,101,114,58,32,117
	dw	112,100,97,116,105,110,103,32,101,118,101,110,116,32,109,97
	dw	110,97,103,101,114,32,116,104,97,116,32,104,97,115,110,39
	dw	116,32,98,101,101,110,32,112,114,101,112,97,114,101,100
	align	4
_228:
	dd	_126
	dd	61
	dd	3
	align	4
_231:
	dd	_126
	dd	62
	dd	3
	align	4
_287:
	dd	1
	dd	_30
	dd	2
	dd	_137
	dd	_132
	dd	-4
	dd	0
	align	4
_236:
	dd	_126
	dd	66
	dd	3
	align	4
_286:
	dd	3
	dd	0
	dd	2
	dd	_196
	dd	_197
	dd	-8
	dd	0
	align	4
_242:
	dd	_126
	dd	67
	dd	4
	align	4
_248:
	dd	_126
	dd	68
	dd	4
_285:
	db	"startTime",0
	align	4
_284:
	dd	3
	dd	0
	dd	2
	dd	_285
	dd	_14
	dd	-12
	dd	0
	align	4
_250:
	dd	_126
	dd	69
	dd	5
	align	4
_254:
	dd	_126
	dd	70
	dd	5
	align	4
_8:
	dd	bbStringClass
	dd	2147483647
	dd	59
	dw	84,69,118,101,110,116,77,97,110,97,103,101,114,58,32,97
	dw	110,32,102,117,116,117,114,101,32,101,118,101,110,116,32,100
	dw	105,100,110,39,116,32,103,101,116,32,116,114,105,103,103,101
	dw	114,101,100,32,105,110,32,116,105,109,101
	align	4
_258:
	dd	_126
	dd	71
	dd	5
	align	4
_283:
	dd	3
	dd	0
	dd	0
	align	4
_262:
	dd	_126
	dd	72
	dd	6
	align	4
_265:
	dd	_126
	dd	73
	dd	6
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_274:
	dd	3
	dd	0
	dd	0
	align	4
_269:
	dd	_126
	dd	74
	dd	7
	align	4
_275:
	dd	_126
	dd	76
	dd	6
	align	4
_280:
	dd	_126
	dd	77
	dd	6
	align	4
_289:
	dd	1
	dd	_17
	dd	2
	dd	_137
	dd	_175
	dd	-4
	dd	0
	align	4
_288:
	dd	3
	dd	0
	dd	0
_292:
	db	":TEventListenerRunFunction",0
	align	4
_291:
	dd	1
	dd	_17
	dd	2
	dd	_137
	dd	_292
	dd	-4
	dd	0
	align	4
_290:
	dd	3
	dd	0
	dd	0
_301:
	db	"obj",0
	align	4
_300:
	dd	1
	dd	_37
	dd	2
	dd	_36
	dd	_26
	dd	-4
	dd	2
	dd	_301
	dd	_292
	dd	-8
	dd	0
	align	4
_293:
	dd	_126
	dd	92
	dd	3
	align	4
_295:
	dd	_126
	dd	93
	dd	3
	align	4
_299:
	dd	_126
	dd	94
	dd	3
	align	4
_305:
	dd	1
	dd	_39
	dd	2
	dd	_137
	dd	_292
	dd	-4
	dd	2
	dd	_27
	dd	_197
	dd	-8
	dd	0
	align	4
_302:
	dd	_126
	dd	98
	dd	3
	align	4
_307:
	dd	1
	dd	_17
	dd	2
	dd	_137
	dd	_197
	dd	-4
	dd	0
	align	4
_306:
	dd	3
	dd	0
	dd	0
	align	4
_311:
	dd	1
	dd	_47
	dd	2
	dd	_137
	dd	_197
	dd	-4
	dd	0
	align	4
_308:
	dd	_126
	dd	108
	dd	3
	align	4
_312:
	dd	1
	dd	_33
	dd	2
	dd	_137
	dd	_197
	dd	-4
	dd	0
_349:
	db	"other",0
_350:
	db	"mytime",0
_351:
	db	"theirtime",0
	align	4
_348:
	dd	1
	dd	_48
	dd	2
	dd	_137
	dd	_197
	dd	-4
	dd	2
	dd	_349
	dd	_46
	dd	-8
	dd	2
	dd	_196
	dd	_197
	dd	-12
	dd	2
	dd	_350
	dd	_14
	dd	-16
	dd	2
	dd	_351
	dd	_14
	dd	-20
	dd	0
	align	4
_313:
	dd	_126
	dd	116
	dd	3
	align	4
_315:
	dd	_126
	dd	117
	dd	3
	align	4
_318:
	dd	3
	dd	0
	dd	0
	align	4
_317:
	dd	_126
	dd	117
	dd	21
	align	4
_319:
	dd	_126
	dd	119
	dd	3
	align	4
_323:
	dd	_126
	dd	120
	dd	3
	align	4
_327:
	dd	_126
	dd	122
	dd	3
	align	4
_334:
	dd	3
	dd	0
	dd	0
	align	4
_333:
	dd	_126
	dd	122
	dd	54
	align	4
_347:
	dd	3
	dd	0
	dd	0
	align	4
_336:
	dd	_126
	dd	123
	dd	8
	align	4
_343:
	dd	3
	dd	0
	dd	0
	align	4
_342:
	dd	_126
	dd	123
	dd	59
	align	4
_346:
	dd	3
	dd	0
	dd	0
	align	4
_345:
	dd	_126
	dd	124
	dd	8
_354:
	db	":TEventSimple",0
	align	4
_353:
	dd	1
	dd	_17
	dd	2
	dd	_137
	dd	_354
	dd	-4
	dd	0
	align	4
_352:
	dd	3
	dd	0
	dd	0
_367:
	db	"data",0
	align	4
_366:
	dd	1
	dd	_37
	dd	2
	dd	_173
	dd	_44
	dd	-4
	dd	2
	dd	_367
	dd	_46
	dd	-8
	dd	2
	dd	_301
	dd	_354
	dd	-12
	dd	0
	align	4
_355:
	dd	_126
	dd	131
	dd	3
	align	4
_357:
	dd	_126
	dd	132
	dd	3
	align	4
_361:
	dd	_126
	dd	133
	dd	3
	align	4
_365:
	dd	_126
	dd	134
	dd	3
