	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_polledinput_polledinput
	extrn	__bb_system_system
	extrn	bbArrayNew
	extrn	bbArrayNew1D
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
	extrn	brl_blitz_ArrayBoundsError
	extrn	brl_blitz_NullObjectError
	extrn	brl_polledinput_KeyDown
	extrn	brl_polledinput_MouseDown
	extrn	brl_polledinput_MouseHit
	extrn	brl_polledinput_MouseX
	extrn	brl_polledinput_MouseY
	public	__bb_source_basefunctions_keymanager
	public	_bb_TKeyManager_IsDown
	public	_bb_TKeyManager_IsHit
	public	_bb_TKeyManager_New
	public	_bb_TKeyManager_changeStatus
	public	_bb_TKeyManager_getStatus
	public	_bb_TKeyManager_isNormal
	public	_bb_TKeyManager_isUp
	public	_bb_TKeyManager_resetKey
	public	_bb_TKeyWrapper_New
	public	_bb_TKeyWrapper_allowKey
	public	_bb_TKeyWrapper_hitKey
	public	_bb_TKeyWrapper_holdKey
	public	_bb_TKeyWrapper_pressedKey
	public	_bb_TKeyWrapper_resetKey
	public	_bb_TMouseManager_IsDown
	public	_bb_TMouseManager_IsHit
	public	_bb_TMouseManager_New
	public	_bb_TMouseManager_SetDown
	public	_bb_TMouseManager_changeStatus
	public	_bb_TMouseManager_getStatus
	public	_bb_TMouseManager_isNormal
	public	_bb_TMouseManager_isUp
	public	_bb_TMouseManager_resetKey
	public	bb_KEYMANAGER
	public	bb_KEYWRAPPER
	public	bb_MOUSEMANAGER
	public	bb_TKeyManager
	public	bb_TKeyWrapper
	public	bb_TMouseManager
	section	"code" executable
__bb_source_basefunctions_keymanager:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	cmp	dword [_171],0
	je	_172
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_172:
	mov	dword [_171],1
	mov	dword [ebp-4],0
	push	ebp
	push	_151
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	__bb_blitz_blitz
	call	__bb_system_system
	call	__bb_polledinput_polledinput
	call	__bb_glmax2d_glmax2d
	push	bb_TMouseManager
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TKeyManager
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TKeyWrapper
	call	bbObjectRegisterType
	add	esp,4
	push	_136
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_138]
	and	eax,1
	cmp	eax,0
	jne	_139
	push	bb_TMouseManager
	call	bbObjectNew
	add	esp,4
	mov	dword [bb_MOUSEMANAGER],eax
	or	dword [_138],1
_139:
	push	_140
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_138]
	and	eax,2
	cmp	eax,0
	jne	_141
	push	bb_TKeyManager
	call	bbObjectNew
	add	esp,4
	mov	dword [bb_KEYMANAGER],eax
	or	dword [_138],2
_141:
	push	_142
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_138]
	and	eax,4
	cmp	eax,0
	jne	_143
	push	bb_TKeyWrapper
	call	bbObjectNew
	add	esp,4
	mov	dword [bb_KEYWRAPPER],eax
	or	dword [_138],4
_143:
	push	_144
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],0
	push	_146
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],0
	jmp	_147
_4:
	push	_148
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [bb_KEYWRAPPER]
	cmp	ebx,bbNullObject
	jne	_150
	call	brl_blitz_NullObjectError
_150:
	push	100
	push	600
	push	3
	push	dword [ebp-4]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,20
_2:
	add	dword [ebp-4],1
_147:
	cmp	dword [ebp-4],255
	jle	_4
_3:
	mov	ebx,0
	jmp	_43
_43:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_174
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TMouseManager
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],0
	mov	eax,dword [ebp-4]
	mov	byte [eax+16],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],0
	mov	ebx,dword [ebp-4]
	push	4
	push	_173
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebx+24],eax
	mov	ebx,0
	jmp	_46
_46:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_isNormal:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_186
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_176
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_178
	call	brl_blitz_NullObjectError
_178:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_181
	call	brl_blitz_ArrayBoundsError
_181:
	cmp	dword [esi+ebx*4+24],0
	jne	_182
	push	_183
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_50
_182:
	push	_185
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_50
_50:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_IsHit:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_198
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_188
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_190
	call	brl_blitz_NullObjectError
_190:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_193
	call	brl_blitz_ArrayBoundsError
_193:
	cmp	dword [esi+ebx*4+24],1
	jne	_194
	push	_195
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_54
_194:
	push	_197
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_54
_54:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_IsDown:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_209
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_199
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_201
	call	brl_blitz_NullObjectError
_201:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_204
	call	brl_blitz_ArrayBoundsError
_204:
	cmp	dword [esi+ebx*4+24],2
	jne	_205
	push	_206
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_58
_205:
	push	_208
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_58
_58:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_isUp:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_220
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_210
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_212
	call	brl_blitz_NullObjectError
_212:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_215
	call	brl_blitz_ArrayBoundsError
_215:
	cmp	dword [esi+ebx*4+24],3
	jne	_216
	push	_217
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_62
_216:
	push	_219
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_62
_62:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_SetDown:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_228
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_221
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_223
	call	brl_blitz_NullObjectError
_223:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_226
	call	brl_blitz_ArrayBoundsError
_226:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],2
	mov	ebx,0
	jmp	_66
_66:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_changeStatus:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],0
	mov	eax,ebp
	push	eax
	push	_333
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_229
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_231
	call	brl_blitz_NullObjectError
_231:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+20],eax
	push	_233
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_235
	call	brl_blitz_NullObjectError
_235:
	mov	byte [ebx+16],0
	push	_237
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_239
	call	brl_blitz_NullObjectError
_239:
	mov	ebx,dword [ebx+8]
	call	brl_polledinput_MouseX
	cmp	ebx,eax
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_242
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_241
	call	brl_blitz_NullObjectError
_241:
	mov	ebx,dword [ebx+12]
	call	brl_polledinput_MouseY
	cmp	ebx,eax
	setne	al
	movzx	eax,al
_242:
	cmp	eax,0
	je	_244
	push	_245
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_247
	call	brl_blitz_NullObjectError
_247:
	mov	byte [ebx+16],1
	push	_249
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_251
	call	brl_blitz_NullObjectError
_251:
	call	brl_polledinput_MouseX
	mov	dword [ebx+8],eax
	push	_253
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_255
	call	brl_blitz_NullObjectError
_255:
	call	brl_polledinput_MouseY
	mov	dword [ebx+12],eax
_244:
	push	_257
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	mov	dword [ebp-12],1
	jmp	_259
_7:
	push	_260
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_262
	call	brl_blitz_NullObjectError
_262:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_265
	call	brl_blitz_ArrayBoundsError
_265:
	cmp	dword [esi+ebx*4+24],0
	jne	_266
	push	_267
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	call	brl_polledinput_MouseHit
	add	esp,4
	cmp	eax,0
	je	_268
	push	_269
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_271
	call	brl_blitz_NullObjectError
_271:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_274
	call	brl_blitz_ArrayBoundsError
_274:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],1
_268:
	jmp	_276
_266:
	push	_277
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_279
	call	brl_blitz_NullObjectError
_279:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_282
	call	brl_blitz_ArrayBoundsError
_282:
	cmp	dword [esi+ebx*4+24],1
	jne	_283
	push	_284
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	call	brl_polledinput_MouseDown
	add	esp,4
	cmp	eax,0
	je	_285
	push	_286
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_288
	call	brl_blitz_NullObjectError
_288:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_291
	call	brl_blitz_ArrayBoundsError
_291:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],2
	jmp	_293
_285:
	push	_294
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_296
	call	brl_blitz_NullObjectError
_296:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_299
	call	brl_blitz_ArrayBoundsError
_299:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],3
_293:
	jmp	_301
_283:
	push	_302
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_304
	call	brl_blitz_NullObjectError
_304:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_307
	call	brl_blitz_ArrayBoundsError
_307:
	cmp	dword [esi+ebx*4+24],2
	jne	_308
	push	_309
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	call	brl_polledinput_MouseDown
	add	esp,4
	cmp	eax,0
	jne	_310
	push	_311
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_313
	call	brl_blitz_NullObjectError
_313:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_316
	call	brl_blitz_ArrayBoundsError
_316:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],3
_310:
	jmp	_318
_308:
	push	_319
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_321
	call	brl_blitz_NullObjectError
_321:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_324
	call	brl_blitz_ArrayBoundsError
_324:
	cmp	dword [esi+ebx*4+24],3
	jne	_325
	push	_326
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_328
	call	brl_blitz_NullObjectError
_328:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_331
	call	brl_blitz_ArrayBoundsError
_331:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],0
_325:
_318:
_301:
_276:
_5:
	add	dword [ebp-12],1
_259:
	cmp	dword [ebp-12],3
	jle	_7
_6:
	mov	ebx,0
	jmp	_70
_70:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_resetKey:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_348
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_335
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_337
	call	brl_blitz_NullObjectError
_337:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_340
	call	brl_blitz_ArrayBoundsError
_340:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],3
	push	_342
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_344
	call	brl_blitz_NullObjectError
_344:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_347
	call	brl_blitz_ArrayBoundsError
_347:
	mov	ebx,dword [esi+ebx*4+24]
	jmp	_74
_74:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_getStatus:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_355
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_349
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_351
	call	brl_blitz_NullObjectError
_351:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_354
	call	brl_blitz_ArrayBoundsError
_354:
	mov	ebx,dword [esi+ebx*4+24]
	jmp	_78
_78:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_357
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TKeyManager
	mov	ebx,dword [ebp-4]
	push	256
	push	_356
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebx+8],eax
	mov	ebx,0
	jmp	_81
_81:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_isNormal:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_368
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_358
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_360
	call	brl_blitz_NullObjectError
_360:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_363
	call	brl_blitz_ArrayBoundsError
_363:
	cmp	dword [esi+ebx*4+24],0
	jne	_364
	push	_365
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_85
_364:
	push	_367
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_85
_85:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_IsHit:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_379
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_369
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_371
	call	brl_blitz_NullObjectError
_371:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_374
	call	brl_blitz_ArrayBoundsError
_374:
	cmp	dword [esi+ebx*4+24],1
	jne	_375
	push	_376
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_89
_375:
	push	_378
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_89
_89:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_IsDown:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_390
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_380
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_382
	call	brl_blitz_NullObjectError
_382:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_385
	call	brl_blitz_ArrayBoundsError
_385:
	cmp	dword [esi+ebx*4+24],2
	jne	_386
	push	_387
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_93
_386:
	push	_389
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_93
_93:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_isUp:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_401
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_391
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_393
	call	brl_blitz_NullObjectError
_393:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_396
	call	brl_blitz_ArrayBoundsError
_396:
	cmp	dword [esi+ebx*4+24],3
	jne	_397
	push	_398
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_97
_397:
	push	_400
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_97
_97:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_changeStatus:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	eax,ebp
	push	eax
	push	_478
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_402
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-8],1
	jmp	_404
_10:
	push	_405
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_407
	call	brl_blitz_NullObjectError
_407:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_410
	call	brl_blitz_ArrayBoundsError
_410:
	cmp	dword [esi+ebx*4+24],0
	jne	_411
	push	_412
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_polledinput_KeyDown
	add	esp,4
	cmp	eax,0
	je	_413
	push	_414
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_416
	call	brl_blitz_NullObjectError
_416:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_419
	call	brl_blitz_ArrayBoundsError
_419:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],1
_413:
	jmp	_421
_411:
	push	_422
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_424
	call	brl_blitz_NullObjectError
_424:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_427
	call	brl_blitz_ArrayBoundsError
_427:
	cmp	dword [esi+ebx*4+24],1
	jne	_428
	push	_429
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_polledinput_KeyDown
	add	esp,4
	cmp	eax,0
	je	_430
	push	_431
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_433
	call	brl_blitz_NullObjectError
_433:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_436
	call	brl_blitz_ArrayBoundsError
_436:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],2
	jmp	_438
_430:
	push	_439
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_441
	call	brl_blitz_NullObjectError
_441:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_444
	call	brl_blitz_ArrayBoundsError
_444:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],3
_438:
	jmp	_446
_428:
	push	_447
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_449
	call	brl_blitz_NullObjectError
_449:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_452
	call	brl_blitz_ArrayBoundsError
_452:
	cmp	dword [esi+ebx*4+24],2
	jne	_453
	push	_454
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_polledinput_KeyDown
	add	esp,4
	cmp	eax,0
	jne	_455
	push	_456
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_458
	call	brl_blitz_NullObjectError
_458:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_461
	call	brl_blitz_ArrayBoundsError
_461:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],3
_455:
	jmp	_463
_453:
	push	_464
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_466
	call	brl_blitz_NullObjectError
_466:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_469
	call	brl_blitz_ArrayBoundsError
_469:
	cmp	dword [esi+ebx*4+24],3
	jne	_470
	push	_471
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_473
	call	brl_blitz_NullObjectError
_473:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_476
	call	brl_blitz_ArrayBoundsError
_476:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],0
_470:
_463:
_446:
_421:
_8:
	add	dword [ebp-8],1
_404:
	cmp	dword [ebp-8],255
	jle	_10
_9:
	mov	ebx,0
	jmp	_100
_100:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_getStatus:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_485
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_479
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_481
	call	brl_blitz_NullObjectError
_481:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_484
	call	brl_blitz_ArrayBoundsError
_484:
	mov	ebx,dword [esi+ebx*4+24]
	jmp	_104
_104:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_resetKey:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_499
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_486
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_488
	call	brl_blitz_NullObjectError
_488:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_491
	call	brl_blitz_ArrayBoundsError
_491:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],3
	push	_493
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_495
	call	brl_blitz_NullObjectError
_495:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_498
	call	brl_blitz_ArrayBoundsError
_498:
	mov	ebx,dword [esi+ebx*4+24]
	jmp	_108
_108:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_501
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TKeyWrapper
	mov	ebx,dword [ebp-4]
	push	4
	push	256
	push	2
	push	_500
	call	bbArrayNew
	add	esp,16
	mov	dword [ebx+8],eax
	mov	ebx,0
	jmp	_111
_111:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_allowKey:
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
	mov	eax,dword [ebp+20]
	mov	dword [ebp-16],eax
	mov	eax,dword [ebp+24]
	mov	dword [ebp-20],eax
	mov	eax,ebp
	push	eax
	push	_533
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_502
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_504
	call	brl_blitz_NullObjectError
_504:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_507
	call	brl_blitz_ArrayBoundsError
_507:
	mov	ebx,0
	cmp	ebx,dword [esi+24]
	jb	_509
	call	brl_blitz_ArrayBoundsError
_509:
	mov	eax,esi
	mov	edx,edi
	add	edx,ebx
	shl	edx,2
	add	eax,edx
	mov	edx,dword [ebp-12]
	mov	dword [eax+28],edx
	push	_511
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	and	eax,1
	cmp	eax,0
	je	_512
	push	_513
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_515
	call	brl_blitz_NullObjectError
_515:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_518
	call	brl_blitz_ArrayBoundsError
_518:
	mov	ebx,1
	cmp	ebx,dword [esi+24]
	jb	_520
	call	brl_blitz_ArrayBoundsError
_520:
	mov	eax,esi
	mov	edx,edi
	add	edx,ebx
	shl	edx,2
	add	eax,edx
	mov	edx,dword [ebp-16]
	mov	dword [eax+28],edx
_512:
	push	_522
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	and	eax,2
	cmp	eax,0
	je	_523
	push	_524
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_526
	call	brl_blitz_NullObjectError
_526:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_529
	call	brl_blitz_ArrayBoundsError
_529:
	mov	ebx,2
	cmp	ebx,dword [esi+24]
	jb	_531
	call	brl_blitz_ArrayBoundsError
_531:
	mov	eax,esi
	mov	edx,edi
	add	edx,ebx
	shl	edx,2
	add	eax,edx
	mov	edx,dword [ebp-20]
	mov	dword [eax+28],edx
_523:
	mov	ebx,0
	jmp	_118
_118:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_pressedKey:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	eax,ebp
	push	eax
	push	_569
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_537
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [bb_KEYMANAGER]
	cmp	ebx,bbNullObject
	jne	_539
	call	brl_blitz_NullObjectError
_539:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebp-12],eax
	push	_541
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_543
	call	brl_blitz_NullObjectError
_543:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_546
	call	brl_blitz_ArrayBoundsError
_546:
	mov	ebx,0
	cmp	ebx,dword [esi+24]
	jb	_548
	call	brl_blitz_ArrayBoundsError
_548:
	mov	eax,edi
	add	eax,ebx
	mov	eax,dword [esi+eax*4+28]
	mov	dword [ebp-16],eax
	push	_550
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_551
	mov	eax,dword [ebp-12]
	cmp	eax,3
	sete	al
	movzx	eax,al
_551:
	cmp	eax,0
	je	_553
	push	_554
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_122
_553:
	push	_555
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	and	eax,1
	cmp	eax,0
	je	_556
	mov	eax,dword [ebp-12]
	cmp	eax,1
	sete	al
	movzx	eax,al
_556:
	cmp	eax,0
	je	_558
	push	_559
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_561
	call	brl_blitz_NullObjectError
_561:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,8
	mov	ebx,eax
	jmp	_122
_558:
	push	_563
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	and	eax,2
	cmp	eax,0
	je	_564
	push	_565
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_567
	call	brl_blitz_NullObjectError
_567:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
	mov	ebx,eax
	jmp	_122
_564:
_562:
	push	_568
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_122
_122:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_hitKey:
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
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	eax,ebp
	push	eax
	push	_604
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_571
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_573
	call	brl_blitz_NullObjectError
_573:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_576
	call	brl_blitz_ArrayBoundsError
_576:
	mov	ebx,0
	cmp	ebx,dword [esi+24]
	jb	_578
	call	brl_blitz_ArrayBoundsError
_578:
	mov	eax,edi
	add	eax,ebx
	mov	eax,dword [esi+eax*4+28]
	mov	dword [ebp-12],eax
	push	_580
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],1
	je	_582
	push	_583
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_126
_582:
	push	_584
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	and	eax,1
	cmp	eax,0
	je	_585
	push	_586
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_588
	call	brl_blitz_NullObjectError
_588:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_591
	call	brl_blitz_ArrayBoundsError
_591:
	mov	ebx,3
	cmp	ebx,dword [esi+24]
	jb	_593
	call	brl_blitz_ArrayBoundsError
_593:
	mov	eax,esi
	mov	edx,edi
	add	edx,ebx
	shl	edx,2
	add	eax,edx
	mov	dword [ebp-20],eax
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_596
	call	brl_blitz_NullObjectError
_596:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_599
	call	brl_blitz_ArrayBoundsError
_599:
	mov	ebx,1
	cmp	ebx,dword [esi+24]
	jb	_601
	call	brl_blitz_ArrayBoundsError
_601:
	call	bbMilliSecs
	mov	edx,edi
	add	edx,ebx
	add	eax,dword [esi+edx*4+28]
	mov	edx,dword [ebp-20]
	mov	dword [edx+28],eax
	push	_602
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_126
_585:
	push	_603
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_126
_126:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_holdKey:
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
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	eax,ebp
	push	eax
	push	_645
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_605
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_607
	call	brl_blitz_NullObjectError
_607:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_610
	call	brl_blitz_ArrayBoundsError
_610:
	mov	ebx,0
	cmp	ebx,dword [esi+24]
	jb	_612
	call	brl_blitz_ArrayBoundsError
_612:
	mov	eax,edi
	add	eax,ebx
	mov	eax,dword [esi+eax*4+28]
	mov	dword [ebp-12],eax
	push	_614
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	and	eax,2
	cmp	eax,0
	je	_615
	push	_616
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_618
	call	brl_blitz_NullObjectError
_618:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_621
	call	brl_blitz_ArrayBoundsError
_621:
	mov	ebx,3
	cmp	ebx,dword [esi+24]
	jb	_623
	call	brl_blitz_ArrayBoundsError
_623:
	mov	eax,edi
	add	eax,ebx
	mov	eax,dword [esi+eax*4+28]
	mov	dword [ebp-16],eax
	push	_625
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	bbMilliSecs
	cmp	eax,dword [ebp-16]
	jle	_626
	push	_627
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_629
	call	brl_blitz_NullObjectError
_629:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_632
	call	brl_blitz_ArrayBoundsError
_632:
	mov	ebx,3
	cmp	ebx,dword [esi+24]
	jb	_634
	call	brl_blitz_ArrayBoundsError
_634:
	mov	eax,esi
	mov	edx,edi
	add	edx,ebx
	shl	edx,2
	add	eax,edx
	mov	dword [ebp-20],eax
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_637
	call	brl_blitz_NullObjectError
_637:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_640
	call	brl_blitz_ArrayBoundsError
_640:
	mov	ebx,2
	cmp	ebx,dword [esi+24]
	jb	_642
	call	brl_blitz_ArrayBoundsError
_642:
	call	bbMilliSecs
	mov	edx,edi
	add	edx,ebx
	add	eax,dword [esi+edx*4+28]
	mov	edx,dword [ebp-20]
	mov	dword [edx+28],eax
	push	_643
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_130
_626:
_615:
	push	_644
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_130
_130:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_resetKey:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,ebp
	push	eax
	push	_683
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_647
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_649
	call	brl_blitz_NullObjectError
_649:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_652
	call	brl_blitz_ArrayBoundsError
_652:
	mov	ebx,0
	cmp	ebx,dword [esi+24]
	jb	_654
	call	brl_blitz_ArrayBoundsError
_654:
	mov	eax,esi
	mov	edx,edi
	add	edx,ebx
	shl	edx,2
	add	eax,edx
	mov	dword [eax+28],0
	push	_656
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_658
	call	brl_blitz_NullObjectError
_658:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_661
	call	brl_blitz_ArrayBoundsError
_661:
	mov	ebx,1
	cmp	ebx,dword [esi+24]
	jb	_663
	call	brl_blitz_ArrayBoundsError
_663:
	mov	eax,esi
	mov	edx,edi
	add	edx,ebx
	shl	edx,2
	add	eax,edx
	mov	dword [eax+28],0
	push	_665
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_667
	call	brl_blitz_NullObjectError
_667:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_670
	call	brl_blitz_ArrayBoundsError
_670:
	mov	ebx,2
	cmp	ebx,dword [esi+24]
	jb	_672
	call	brl_blitz_ArrayBoundsError
_672:
	mov	eax,esi
	mov	edx,edi
	add	edx,ebx
	shl	edx,2
	add	eax,edx
	mov	dword [eax+28],0
	push	_674
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_676
	call	brl_blitz_NullObjectError
_676:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-8]
	imul	eax,dword [esi+24]
	mov	edi,eax
	cmp	edi,dword [esi+20]
	jb	_679
	call	brl_blitz_ArrayBoundsError
_679:
	mov	ebx,3
	cmp	ebx,dword [esi+24]
	jb	_681
	call	brl_blitz_ArrayBoundsError
_681:
	mov	eax,esi
	mov	edx,edi
	add	edx,ebx
	shl	edx,2
	add	eax,edx
	mov	dword [eax+28],0
	mov	ebx,0
	jmp	_134
_134:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_171:
	dd	0
_152:
	db	"basefunctions_keymanager",0
_153:
	db	"KEY_STATE_NORMAL",0
_14:
	db	"i",0
	align	4
_154:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	48
_155:
	db	"KEY_STATE_HIT",0
	align	4
_156:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	49
_157:
	db	"KEY_STATE_DOWN",0
	align	4
_158:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	50
_159:
	db	"KEY_STATE_UP",0
	align	4
_160:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	51
_161:
	db	"KEYWRAP_ALLOW_HIT",0
_162:
	db	"KEYWRAP_ALLOW_HOLD",0
_163:
	db	"KEYWRAP_ALLOW_BOTH",0
_164:
	db	"MOUSEMANAGER",0
_165:
	db	":TMouseManager",0
	align	4
bb_MOUSEMANAGER:
	dd	bbNullObject
_166:
	db	"KEYMANAGER",0
_167:
	db	":TKeyManager",0
	align	4
bb_KEYMANAGER:
	dd	bbNullObject
_168:
	db	"KEYWRAPPER",0
_169:
	db	":TKeyWrapper",0
	align	4
bb_KEYWRAPPER:
	dd	bbNullObject
_170:
	db	"keyi",0
	align	4
_151:
	dd	1
	dd	_152
	dd	1
	dd	_153
	dd	_14
	dd	_154
	dd	1
	dd	_155
	dd	_14
	dd	_156
	dd	1
	dd	_157
	dd	_14
	dd	_158
	dd	1
	dd	_159
	dd	_14
	dd	_160
	dd	1
	dd	_161
	dd	_14
	dd	_156
	dd	1
	dd	_162
	dd	_14
	dd	_158
	dd	1
	dd	_163
	dd	_14
	dd	_160
	dd	4
	dd	_164
	dd	_165
	dd	bb_MOUSEMANAGER
	dd	4
	dd	_166
	dd	_167
	dd	bb_KEYMANAGER
	dd	4
	dd	_168
	dd	_169
	dd	bb_KEYWRAPPER
	dd	2
	dd	_170
	dd	_14
	dd	-4
	dd	0
_12:
	db	"TMouseManager",0
_13:
	db	"LastMouseX",0
_15:
	db	"LastMouseY",0
_16:
	db	"MousePosChanged",0
_17:
	db	"b",0
_18:
	db	"errorboxes",0
_19:
	db	"_iKeyStatus",0
_20:
	db	"[]i",0
_21:
	db	"New",0
_22:
	db	"()i",0
_23:
	db	"isNormal",0
_24:
	db	"(i)i",0
_25:
	db	"IsHit",0
_26:
	db	"IsDown",0
_27:
	db	"isUp",0
_28:
	db	"SetDown",0
_29:
	db	"changeStatus",0
_30:
	db	"resetKey",0
_31:
	db	"getStatus",0
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
	dd	12
	dd	3
	dd	_16
	dd	_17
	dd	16
	dd	3
	dd	_18
	dd	_14
	dd	20
	dd	3
	dd	_19
	dd	_20
	dd	24
	dd	6
	dd	_21
	dd	_22
	dd	16
	dd	6
	dd	_23
	dd	_24
	dd	48
	dd	6
	dd	_25
	dd	_24
	dd	52
	dd	6
	dd	_26
	dd	_24
	dd	56
	dd	6
	dd	_27
	dd	_24
	dd	60
	dd	6
	dd	_28
	dd	_24
	dd	64
	dd	6
	dd	_29
	dd	_24
	dd	68
	dd	6
	dd	_30
	dd	_24
	dd	72
	dd	6
	dd	_31
	dd	_24
	dd	76
	dd	0
	align	4
bb_TMouseManager:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_11
	dd	28
	dd	_bb_TMouseManager_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TMouseManager_isNormal
	dd	_bb_TMouseManager_IsHit
	dd	_bb_TMouseManager_IsDown
	dd	_bb_TMouseManager_isUp
	dd	_bb_TMouseManager_SetDown
	dd	_bb_TMouseManager_changeStatus
	dd	_bb_TMouseManager_resetKey
	dd	_bb_TMouseManager_getStatus
_33:
	db	"TKeyManager",0
	align	4
_32:
	dd	2
	dd	_33
	dd	3
	dd	_19
	dd	_20
	dd	8
	dd	6
	dd	_21
	dd	_22
	dd	16
	dd	6
	dd	_23
	dd	_24
	dd	48
	dd	6
	dd	_25
	dd	_24
	dd	52
	dd	6
	dd	_26
	dd	_24
	dd	56
	dd	6
	dd	_27
	dd	_24
	dd	60
	dd	6
	dd	_29
	dd	_22
	dd	64
	dd	6
	dd	_31
	dd	_24
	dd	68
	dd	6
	dd	_30
	dd	_24
	dd	72
	dd	0
	align	4
bb_TKeyManager:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_32
	dd	12
	dd	_bb_TKeyManager_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TKeyManager_isNormal
	dd	_bb_TKeyManager_IsHit
	dd	_bb_TKeyManager_IsDown
	dd	_bb_TKeyManager_isUp
	dd	_bb_TKeyManager_changeStatus
	dd	_bb_TKeyManager_getStatus
	dd	_bb_TKeyManager_resetKey
_35:
	db	"TKeyWrapper",0
_36:
	db	"_iKeySet",0
_37:
	db	"[,]i",0
_38:
	db	"allowKey",0
_39:
	db	"(i,i,i,i)i",0
_40:
	db	"pressedKey",0
_41:
	db	"hitKey",0
_42:
	db	"holdKey",0
	align	4
_34:
	dd	2
	dd	_35
	dd	3
	dd	_36
	dd	_37
	dd	8
	dd	6
	dd	_21
	dd	_22
	dd	16
	dd	6
	dd	_38
	dd	_39
	dd	48
	dd	6
	dd	_40
	dd	_24
	dd	52
	dd	6
	dd	_41
	dd	_24
	dd	56
	dd	6
	dd	_42
	dd	_24
	dd	60
	dd	6
	dd	_30
	dd	_24
	dd	64
	dd	0
	align	4
bb_TKeyWrapper:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_34
	dd	12
	dd	_bb_TKeyWrapper_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TKeyWrapper_allowKey
	dd	_bb_TKeyWrapper_pressedKey
	dd	_bb_TKeyWrapper_hitKey
	dd	_bb_TKeyWrapper_holdKey
	dd	_bb_TKeyWrapper_resetKey
_137:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_keymanager.bmx",0
	align	4
_136:
	dd	_137
	dd	3
	dd	1
	align	4
_138:
	dd	0
	align	4
_140:
	dd	_137
	dd	4
	dd	1
	align	4
_142:
	dd	_137
	dd	5
	dd	1
	align	4
_144:
	dd	_137
	dd	13
	dd	1
	align	4
_146:
	dd	_137
	dd	14
	dd	1
	align	4
_148:
	dd	_137
	dd	15
	dd	3
_175:
	db	"Self",0
	align	4
_174:
	dd	1
	dd	_21
	dd	2
	dd	_175
	dd	_165
	dd	-4
	dd	0
_173:
	db	"i",0
_187:
	db	"iKey",0
	align	4
_186:
	dd	1
	dd	_23
	dd	2
	dd	_175
	dd	_165
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_176:
	dd	_137
	dd	28
	dd	7
	align	4
_183:
	dd	_137
	dd	28
	dd	59
	align	4
_185:
	dd	_137
	dd	28
	dd	76
	align	4
_198:
	dd	1
	dd	_25
	dd	2
	dd	_175
	dd	_165
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_188:
	dd	_137
	dd	32
	dd	7
	align	4
_195:
	dd	_137
	dd	32
	dd	56
	align	4
_197:
	dd	_137
	dd	32
	dd	73
	align	4
_209:
	dd	1
	dd	_26
	dd	2
	dd	_175
	dd	_165
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_199:
	dd	_137
	dd	36
	dd	7
	align	4
_206:
	dd	_137
	dd	36
	dd	57
	align	4
_208:
	dd	_137
	dd	36
	dd	74
	align	4
_220:
	dd	1
	dd	_27
	dd	2
	dd	_175
	dd	_165
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_210:
	dd	_137
	dd	40
	dd	7
	align	4
_217:
	dd	_137
	dd	40
	dd	55
	align	4
_219:
	dd	_137
	dd	40
	dd	72
	align	4
_228:
	dd	1
	dd	_28
	dd	2
	dd	_175
	dd	_165
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_221:
	dd	_137
	dd	44
	dd	7
_334:
	db	"_errorboxes",0
	align	4
_333:
	dd	1
	dd	_29
	dd	2
	dd	_175
	dd	_165
	dd	-4
	dd	2
	dd	_334
	dd	_14
	dd	-8
	dd	2
	dd	_14
	dd	_14
	dd	-12
	dd	0
	align	4
_229:
	dd	_137
	dd	51
	dd	4
	align	4
_233:
	dd	_137
	dd	52
	dd	4
	align	4
_237:
	dd	_137
	dd	53
	dd	4
	align	4
_245:
	dd	_137
	dd	54
	dd	6
	align	4
_249:
	dd	_137
	dd	55
	dd	3
	align	4
_253:
	dd	_137
	dd	56
	dd	3
	align	4
_257:
	dd	_137
	dd	59
	dd	7
	align	4
_260:
	dd	_137
	dd	60
	dd	10
	align	4
_267:
	dd	_137
	dd	61
	dd	13
	align	4
_269:
	dd	_137
	dd	61
	dd	35
	align	4
_277:
	dd	_137
	dd	62
	dd	10
	align	4
_284:
	dd	_137
	dd	63
	dd	13
	align	4
_286:
	dd	_137
	dd	63
	dd	36
	align	4
_294:
	dd	_137
	dd	63
	dd	75
	align	4
_302:
	dd	_137
	dd	64
	dd	10
	align	4
_309:
	dd	_137
	dd	65
	dd	13
	align	4
_311:
	dd	_137
	dd	65
	dd	40
	align	4
_319:
	dd	_137
	dd	66
	dd	10
	align	4
_326:
	dd	_137
	dd	67
	dd	13
	align	4
_348:
	dd	1
	dd	_30
	dd	2
	dd	_175
	dd	_165
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_335:
	dd	_137
	dd	75
	dd	7
	align	4
_342:
	dd	_137
	dd	76
	dd	7
	align	4
_355:
	dd	1
	dd	_31
	dd	2
	dd	_175
	dd	_165
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_349:
	dd	_137
	dd	80
	dd	7
	align	4
_357:
	dd	1
	dd	_21
	dd	2
	dd	_175
	dd	_167
	dd	-4
	dd	0
_356:
	db	"i",0
	align	4
_368:
	dd	1
	dd	_23
	dd	2
	dd	_175
	dd	_167
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_358:
	dd	_137
	dd	95
	dd	7
	align	4
_365:
	dd	_137
	dd	95
	dd	59
	align	4
_367:
	dd	_137
	dd	95
	dd	76
	align	4
_379:
	dd	1
	dd	_25
	dd	2
	dd	_175
	dd	_167
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_369:
	dd	_137
	dd	99
	dd	7
	align	4
_376:
	dd	_137
	dd	99
	dd	56
	align	4
_378:
	dd	_137
	dd	99
	dd	73
	align	4
_390:
	dd	1
	dd	_26
	dd	2
	dd	_175
	dd	_167
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_380:
	dd	_137
	dd	103
	dd	7
	align	4
_387:
	dd	_137
	dd	103
	dd	57
	align	4
_389:
	dd	_137
	dd	103
	dd	74
	align	4
_401:
	dd	1
	dd	_27
	dd	2
	dd	_175
	dd	_167
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_391:
	dd	_137
	dd	107
	dd	7
	align	4
_398:
	dd	_137
	dd	107
	dd	55
	align	4
_400:
	dd	_137
	dd	107
	dd	72
	align	4
_478:
	dd	1
	dd	_29
	dd	2
	dd	_175
	dd	_167
	dd	-4
	dd	2
	dd	_14
	dd	_14
	dd	-8
	dd	0
	align	4
_402:
	dd	_137
	dd	117
	dd	7
	align	4
_405:
	dd	_137
	dd	118
	dd	10
	align	4
_412:
	dd	_137
	dd	119
	dd	13
	align	4
_414:
	dd	_137
	dd	119
	dd	34
	align	4
_422:
	dd	_137
	dd	120
	dd	10
	align	4
_429:
	dd	_137
	dd	121
	dd	13
	align	4
_431:
	dd	_137
	dd	121
	dd	34
	align	4
_439:
	dd	_137
	dd	121
	dd	73
	align	4
_447:
	dd	_137
	dd	122
	dd	10
	align	4
_454:
	dd	_137
	dd	123
	dd	13
	align	4
_456:
	dd	_137
	dd	123
	dd	38
	align	4
_464:
	dd	_137
	dd	124
	dd	10
	align	4
_471:
	dd	_137
	dd	125
	dd	13
	align	4
_485:
	dd	1
	dd	_31
	dd	2
	dd	_175
	dd	_167
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_479:
	dd	_137
	dd	132
	dd	7
	align	4
_499:
	dd	1
	dd	_30
	dd	2
	dd	_175
	dd	_167
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_486:
	dd	_137
	dd	136
	dd	7
	align	4
_493:
	dd	_137
	dd	137
	dd	7
	align	4
_501:
	dd	1
	dd	_21
	dd	2
	dd	_175
	dd	_169
	dd	-4
	dd	0
_500:
	db	"i",0
_534:
	db	"iRule",0
_535:
	db	"iHitTime",0
_536:
	db	"iHoldtime",0
	align	4
_533:
	dd	1
	dd	_38
	dd	2
	dd	_175
	dd	_169
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	2
	dd	_534
	dd	_14
	dd	-12
	dd	2
	dd	_535
	dd	_14
	dd	-16
	dd	2
	dd	_536
	dd	_14
	dd	-20
	dd	0
	align	4
_502:
	dd	_137
	dd	157
	dd	7
	align	4
_511:
	dd	_137
	dd	158
	dd	7
	align	4
_513:
	dd	_137
	dd	159
	dd	10
	align	4
_522:
	dd	_137
	dd	162
	dd	7
	align	4
_524:
	dd	_137
	dd	163
	dd	10
_570:
	db	"iKeyState",0
	align	4
_569:
	dd	1
	dd	_40
	dd	2
	dd	_175
	dd	_169
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	2
	dd	_570
	dd	_14
	dd	-12
	dd	2
	dd	_534
	dd	_14
	dd	-16
	dd	0
	align	4
_537:
	dd	_137
	dd	169
	dd	7
	align	4
_541:
	dd	_137
	dd	170
	dd	7
	align	4
_550:
	dd	_137
	dd	172
	dd	7
	align	4
_554:
	dd	_137
	dd	172
	dd	72
	align	4
_555:
	dd	_137
	dd	175
	dd	7
	align	4
_559:
	dd	_137
	dd	176
	dd	10
	align	4
_563:
	dd	_137
	dd	177
	dd	7
	align	4
_565:
	dd	_137
	dd	178
	dd	10
	align	4
_568:
	dd	_137
	dd	180
	dd	7
	align	4
_604:
	dd	1
	dd	_41
	dd	2
	dd	_175
	dd	_169
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	2
	dd	_534
	dd	_14
	dd	-12
	dd	2
	dd	_570
	dd	_14
	dd	-16
	dd	0
	align	4
_571:
	dd	_137
	dd	184
	dd	7
	align	4
_580:
	dd	_137
	dd	185
	dd	7
	align	4
_583:
	dd	_137
	dd	185
	dd	42
	align	4
_584:
	dd	_137
	dd	187
	dd	7
	align	4
_586:
	dd	_137
	dd	189
	dd	10
	align	4
_602:
	dd	_137
	dd	190
	dd	10
	align	4
_603:
	dd	_137
	dd	192
	dd	7
_646:
	db	"iTime",0
	align	4
_645:
	dd	1
	dd	_42
	dd	2
	dd	_175
	dd	_169
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	2
	dd	_534
	dd	_14
	dd	-12
	dd	2
	dd	_646
	dd	_14
	dd	-16
	dd	0
	align	4
_605:
	dd	_137
	dd	196
	dd	7
	align	4
_614:
	dd	_137
	dd	198
	dd	7
	align	4
_616:
	dd	_137
	dd	200
	dd	10
	align	4
_625:
	dd	_137
	dd	201
	dd	10
	align	4
_627:
	dd	_137
	dd	203
	dd	13
	align	4
_643:
	dd	_137
	dd	204
	dd	13
	align	4
_644:
	dd	_137
	dd	207
	dd	7
	align	4
_683:
	dd	1
	dd	_30
	dd	2
	dd	_175
	dd	_169
	dd	-4
	dd	2
	dd	_187
	dd	_14
	dd	-8
	dd	0
	align	4
_647:
	dd	_137
	dd	212
	dd	7
	align	4
_656:
	dd	_137
	dd	213
	dd	7
	align	4
_665:
	dd	_137
	dd	214
	dd	7
	align	4
_674:
	dd	_137
	dd	215
	dd	7
