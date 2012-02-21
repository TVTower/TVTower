	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_reflection_reflection
	extrn	__bb_source_basefunctions_xml
	extrn	bbArrayNew1D
	extrn	bbEmptyString
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
	extrn	bbStringFromInt
	extrn	bb_xmlDocument
	extrn	brl_blitz_ArrayBoundsError
	extrn	brl_blitz_NullFunctionError
	extrn	brl_blitz_NullObjectError
	extrn	brl_linkedlist_TList
	extrn	brl_reflection_ArrayTypeId
	extrn	brl_reflection_TField
	extrn	brl_reflection_TTypeId
	extrn	brl_retro_Upper
	extrn	brl_standardio_Print
	public	__bb_source_basefunctions_loadsave
	public	_bb_TSaveFile_Create
	public	_bb_TSaveFile_InitLoad
	public	_bb_TSaveFile_InitSave
	public	_bb_TSaveFile_LoadObject
	public	_bb_TSaveFile_New
	public	_bb_TSaveFile_SaveObject
	public	_bb_TSaveFile_xmlBeginNode
	public	_bb_TSaveFile_xmlCloseNode
	public	_bb_TSaveFile_xmlSave
	public	_bb_TSaveFile_xmlWrite
	public	bb_LoadSaveFile
	public	bb_TSaveFile
	section	"code" executable
__bb_source_basefunctions_loadsave:
	push	ebp
	mov	ebp,esp
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
	push	ebp
	push	_110
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	__bb_blitz_blitz
	call	__bb_source_basefunctions_xml
	call	__bb_reflection_reflection
	push	bb_TSaveFile
	call	bbObjectRegisterType
	add	esp,4
	push	_106
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_108]
	and	eax,1
	cmp	eax,0
	jne	_109
	call	dword [bb_TSaveFile+48]
	mov	dword [bb_LoadSaveFile],eax
	or	dword [_108],1
_109:
	mov	ebx,0
	jmp	_61
_61:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_175
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TSaveFile
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],bbNullObject
	mov	ebx,dword [ebp-4]
	push	10
	push	_173
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebx+24],eax
	mov	eax,dword [ebp-4]
	mov	dword [eax+28],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+32],bbNullObject
	push	ebp
	push	_174
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_64
_64:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	dword [ebp-4],bbNullObject
	push	ebp
	push	_180
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_177
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TSaveFile
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-4],eax
	push	_179
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	jmp	_66
_66:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_InitSave:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_215
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_182
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_184
	call	brl_blitz_NullObjectError
_184:
	push	bb_xmlDocument
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+8],eax
	push	_186
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_188
	call	brl_blitz_NullObjectError
_188:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_191
	call	brl_blitz_NullObjectError
_191:
	mov	esi,dword [esi+8]
	cmp	esi,bbNullObject
	jne	_193
	call	brl_blitz_NullObjectError
_193:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebx+20],eax
	push	_194
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_196
	call	brl_blitz_NullObjectError
_196:
	mov	ebx,dword [ebx+20]
	cmp	ebx,bbNullObject
	jne	_198
	call	brl_blitz_NullObjectError
_198:
	mov	dword [ebx+8],_3
	push	_200
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_202
	call	brl_blitz_NullObjectError
_202:
	mov	esi,dword [ebx+24]
	mov	ebx,0
	cmp	ebx,dword [esi+20]
	jb	_205
	call	brl_blitz_ArrayBoundsError
_205:
	shl	ebx,2
	add	esi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_208
	call	brl_blitz_NullObjectError
_208:
	mov	eax,dword [ebx+20]
	mov	dword [esi+24],eax
	push	_209
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_211
	call	brl_blitz_NullObjectError
_211:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_214
	call	brl_blitz_NullObjectError
_214:
	mov	eax,dword [esi+20]
	mov	dword [ebx+32],eax
	mov	ebx,0
	jmp	_69
_69:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_InitLoad:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-12],eax
	movzx	eax,byte [ebp+16]
	mov	eax,eax
	mov	byte [ebp-4],al
	push	ebp
	push	_234
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_216
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_218
	call	brl_blitz_NullObjectError
_218:
	movzx	eax,byte [ebp-4]
	push	eax
	push	dword [ebp-12]
	call	dword [bb_xmlDocument+48]
	add	esp,8
	mov	dword [ebx+8],eax
	push	_220
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_222
	call	brl_blitz_NullObjectError
_222:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_225
	call	brl_blitz_NullObjectError
_225:
	mov	esi,dword [esi+8]
	cmp	esi,bbNullObject
	jne	_227
	call	brl_blitz_NullObjectError
_227:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebx+20],eax
	push	_228
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_230
	call	brl_blitz_NullObjectError
_230:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_233
	call	brl_blitz_NullObjectError
_233:
	mov	eax,dword [esi+20]
	mov	dword [ebx+12],eax
	mov	ebx,0
	jmp	_74
_74:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_xmlWrite:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-16],eax
	movzx	eax,byte [ebp+20]
	mov	eax,eax
	mov	byte [ebp-4],al
	mov	eax,dword [ebp+24]
	mov	dword [ebp-20],eax
	mov	eax,ebp
	push	eax
	push	_298
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_239
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-20]
	cmp	eax,-1
	setle	al
	movzx	eax,al
	cmp	eax,0
	jne	_240
	mov	eax,dword [ebp-20]
	cmp	eax,10
	setge	al
	movzx	eax,al
_240:
	cmp	eax,0
	je	_242
	mov	eax,ebp
	push	eax
	push	_246
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_243
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_245
	call	brl_blitz_NullObjectError
_245:
	mov	eax,dword [ebx+28]
	mov	dword [ebp-20],eax
	call	dword [bbOnDebugLeaveScope]
_242:
	push	_247
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_248
	mov	eax,ebp
	push	eax
	push	_282
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_249
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_251
	call	brl_blitz_NullObjectError
_251:
	mov	ebx,dword [ebx+24]
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_254
	call	brl_blitz_NullObjectError
_254:
	mov	esi,dword [esi+28]
	add	esi,1
	cmp	esi,dword [ebx+20]
	jb	_256
	call	brl_blitz_ArrayBoundsError
_256:
	shl	esi,2
	add	ebx,esi
	mov	edi,ebx
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_259
	call	brl_blitz_NullObjectError
_259:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-20]
	cmp	ebx,dword [esi+20]
	jb	_262
	call	brl_blitz_ArrayBoundsError
_262:
	mov	ebx,dword [esi+ebx*4+24]
	cmp	ebx,bbNullObject
	jne	_264
	call	brl_blitz_NullObjectError
_264:
	push	1
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,12
	mov	dword [edi+24],eax
	push	_265
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_267
	call	brl_blitz_NullObjectError
_267:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_270
	call	brl_blitz_NullObjectError
_270:
	mov	ebx,dword [ebx+28]
	add	ebx,1
	cmp	ebx,dword [esi+20]
	jb	_272
	call	brl_blitz_ArrayBoundsError
_272:
	mov	ebx,dword [esi+ebx*4+24]
	cmp	ebx,bbNullObject
	jne	_274
	call	brl_blitz_NullObjectError
_274:
	push	1
	push	_6
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+176]
	add	esp,12
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_276
	call	brl_blitz_NullObjectError
_276:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+12],eax
	push	_278
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_280
	call	brl_blitz_NullObjectError
_280:
	add	dword [ebx+28],1
	call	dword [bbOnDebugLeaveScope]
	jmp	_283
_248:
	mov	eax,ebp
	push	eax
	push	_297
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_284
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_286
	call	brl_blitz_NullObjectError
_286:
	mov	esi,dword [ebx+24]
	mov	ebx,dword [ebp-20]
	cmp	ebx,dword [esi+20]
	jb	_289
	call	brl_blitz_ArrayBoundsError
_289:
	mov	ebx,dword [esi+ebx*4+24]
	cmp	ebx,bbNullObject
	jne	_291
	call	brl_blitz_NullObjectError
_291:
	push	1
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,12
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_293
	call	brl_blitz_NullObjectError
_293:
	push	1
	push	_6
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+176]
	add	esp,12
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_295
	call	brl_blitz_NullObjectError
_295:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+12],eax
	call	dword [bbOnDebugLeaveScope]
_283:
	mov	ebx,0
	jmp	_81
_81:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_xmlCloseNode:
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
	push	_303
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_305
	call	brl_blitz_NullObjectError
_305:
	sub	dword [ebx+28],1
	mov	ebx,0
	jmp	_84
_84:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_xmlBeginNode:
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
	push	_330
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
	mov	ebx,dword [ebx+24]
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_313
	call	brl_blitz_NullObjectError
_313:
	mov	esi,dword [esi+28]
	add	esi,1
	cmp	esi,dword [ebx+20]
	jb	_315
	call	brl_blitz_ArrayBoundsError
_315:
	shl	esi,2
	add	ebx,esi
	mov	edi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_318
	call	brl_blitz_NullObjectError
_318:
	mov	ebx,dword [ebx+24]
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_321
	call	brl_blitz_NullObjectError
_321:
	mov	esi,dword [esi+28]
	cmp	esi,dword [ebx+20]
	jb	_323
	call	brl_blitz_ArrayBoundsError
_323:
	mov	ebx,dword [ebx+esi*4+24]
	cmp	ebx,bbNullObject
	jne	_325
	call	brl_blitz_NullObjectError
_325:
	push	1
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,12
	mov	dword [edi+24],eax
	push	_326
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_328
	call	brl_blitz_NullObjectError
_328:
	add	dword [ebx+28],1
	mov	ebx,0
	jmp	_88
_88:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_xmlSave:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-12],eax
	movzx	eax,byte [ebp+16]
	mov	eax,eax
	mov	byte [ebp-4],al
	push	ebp
	push	_346
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_331
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_7
	push	dword [ebp-12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_332
	push	ebp
	push	_338
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_333
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_335
	call	brl_blitz_NullObjectError
_335:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_337
	call	brl_blitz_NullObjectError
_337:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,4
	push	eax
	call	bbStringFromInt
	add	esp,4
	push	eax
	push	_8
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	jmp	_339
_332:
	push	ebp
	push	_345
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_340
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_342
	call	brl_blitz_NullObjectError
_342:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_344
	call	brl_blitz_NullObjectError
_344:
	movzx	eax,byte [ebp-4]
	push	eax
	push	1
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_339:
	mov	ebx,0
	jmp	_93
_93:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_SaveObject:
	push	ebp
	mov	ebp,esp
	sub	esp,52
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
	mov	dword [ebp-20],bbEmptyString
	mov	dword [ebp-24],bbNullObject
	mov	dword [ebp-28],bbNullObject
	mov	dword [ebp-32],bbNullObject
	mov	dword [ebp-36],bbNullObject
	mov	dword [ebp-40],bbNullObject
	mov	dword [ebp-44],bbNullObject
	mov	eax,ebp
	push	eax
	push	_461
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_347
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],_1
	push	_349
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_351
	call	brl_blitz_NullObjectError
_351:
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	push	_352
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	brl_linkedlist_TList
	push	dword [ebp-8]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_353
	mov	eax,ebp
	push	eax
	push	_370
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_354
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],bbNullObject
	push	brl_linkedlist_TList
	push	dword [ebp-8]
	call	bbObjectDowncast
	add	esp,8
	mov	edi,eax
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_358
	call	brl_blitz_NullObjectError
_358:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_9
_11:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_363
	call	brl_blitz_NullObjectError
_363:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-24],eax
	cmp	dword [ebp-24],bbNullObject
	je	_9
	mov	eax,ebp
	push	eax
	push	_367
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_364
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_366
	call	brl_blitz_NullObjectError
_366:
	push	dword [ebp-16]
	push	_12
	push	dword [ebp-12]
	call	bbStringConcat
	add	esp,8
	push	eax
	push	dword [ebp-24]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_9:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_361
	call	brl_blitz_NullObjectError
_361:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_11
_10:
	call	dword [bbOnDebugLeaveScope]
	jmp	_371
_353:
	mov	eax,ebp
	push	eax
	push	_457
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_372
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	dword [brl_reflection_TTypeId+128]
	add	esp,4
	mov	dword [ebp-28],eax
	push	_374
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],bbNullObject
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_377
	call	brl_blitz_NullObjectError
_377:
	push	bbNullObject
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+96]
	add	esp,8
	mov	dword [ebp-48],eax
	mov	ebx,dword [ebp-48]
	cmp	ebx,bbNullObject
	jne	_380
	call	brl_blitz_NullObjectError
_380:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-52],eax
	jmp	_13
_15:
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_385
	call	brl_blitz_NullObjectError
_385:
	push	brl_reflection_TField
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-32],eax
	cmp	dword [ebp-32],bbNullObject
	je	_13
	mov	eax,ebp
	push	eax
	push	_450
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_386
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_388
	call	brl_blitz_NullObjectError
_388:
	push	_17
	push	_16
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_389
	mov	eax,ebp
	push	eax
	push	_447
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_390
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_392
	call	brl_blitz_NullObjectError
_392:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	dword [brl_reflection_TTypeId+128]
	add	esp,4
	mov	dword [ebp-36],eax
	push	_394
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_396
	call	brl_blitz_NullObjectError
_396:
	push	dword [brl_reflection_ArrayTypeId]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	cmp	eax,0
	je	_397
	mov	eax,ebp
	push	eax
	push	_408
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_398
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_400
	call	brl_blitz_NullObjectError
_400:
	push	0
	push	dword [ebp-28]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+108]
	add	esp,12
	cmp	eax,0
	jle	_401
	mov	eax,ebp
	push	eax
	push	_407
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_402
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_404
	call	brl_blitz_NullObjectError
_404:
	mov	esi,dword [ebp-36]
	cmp	esi,bbNullObject
	jne	_406
	call	brl_blitz_NullObjectError
_406:
	push	_20
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+48]
	add	esp,4
	push	eax
	push	_19
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	push	eax
	push	_18
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_401:
	call	dword [bbOnDebugLeaveScope]
_397:
	push	_409
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_411
	call	brl_blitz_NullObjectError
_411:
	push	brl_linkedlist_TList
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_412
	mov	eax,ebp
	push	eax
	push	_433
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_413
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_415
	call	brl_blitz_NullObjectError
_415:
	push	brl_linkedlist_TList
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-40],eax
	push	_417
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-44],bbNullObject
	mov	edi,dword [ebp-40]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_421
	call	brl_blitz_NullObjectError
_421:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_21
_23:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_426
	call	brl_blitz_NullObjectError
_426:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-44],eax
	cmp	dword [ebp-44],bbNullObject
	je	_21
	mov	eax,ebp
	push	eax
	push	_431
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_427
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_24
	call	brl_standardio_Print
	add	esp,4
	push	_428
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_430
	call	brl_blitz_NullObjectError
_430:
	push	dword [ebp-16]
	push	_12
	push	dword [ebp-12]
	call	bbStringConcat
	add	esp,8
	push	eax
	push	dword [ebp-44]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_21:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_424
	call	brl_blitz_NullObjectError
_424:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_23
_22:
	call	dword [bbOnDebugLeaveScope]
	jmp	_436
_412:
	mov	eax,ebp
	push	eax
	push	_446
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_437
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_439
	call	brl_blitz_NullObjectError
_439:
	mov	esi,dword [ebp-32]
	cmp	esi,bbNullObject
	jne	_441
	call	brl_blitz_NullObjectError
_441:
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_443
	call	brl_blitz_NullObjectError
_443:
	push	bbStringClass
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_445
	mov	eax,bbEmptyString
_445:
	push	-1
	push	0
	push	eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	brl_retro_Upper
	add	esp,4
	push	eax
	push	edi
	mov	eax,dword [edi]
	call	dword [eax+60]
	add	esp,20
	call	dword [bbOnDebugLeaveScope]
_436:
	call	dword [bbOnDebugLeaveScope]
_389:
	call	dword [bbOnDebugLeaveScope]
_13:
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_383
	call	brl_blitz_NullObjectError
_383:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_15
_14:
	push	_453
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],brl_blitz_NullFunctionError
	je	_454
	mov	eax,ebp
	push	eax
	push	_456
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_455
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	dword [ebp-16]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_454:
	call	dword [bbOnDebugLeaveScope]
_371:
	push	_458
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_460
	call	brl_blitz_NullObjectError
_460:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,4
	mov	ebx,0
	jmp	_99
_99:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_LoadObject:
	push	ebp
	mov	ebp,esp
	sub	esp,32
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
	mov	dword [ebp-20],bbEmptyString
	mov	dword [ebp-24],bbNullObject
	mov	dword [ebp-28],bbNullObject
	mov	eax,ebp
	push	eax
	push	_532
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_467
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_469
	call	brl_blitz_NullObjectError
_469:
	mov	ebx,dword [ebx+12]
	cmp	ebx,bbNullObject
	jne	_471
	call	brl_blitz_NullObjectError
_471:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_473
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],bbEmptyString
	push	_475
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_25
_27:
	mov	eax,ebp
	push	eax
	push	_530
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_476
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],_1
	push	_477
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_479
	call	brl_blitz_NullObjectError
_479:
	push	0
	push	_6
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+160]
	add	esp,12
	cmp	eax,0
	je	_480
	mov	eax,ebp
	push	eax
	push	_488
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_481
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_483
	call	brl_blitz_NullObjectError
_483:
	mov	ebx,dword [ebx+12]
	cmp	ebx,bbNullObject
	jne	_485
	call	brl_blitz_NullObjectError
_485:
	push	1
	push	_6
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+176]
	add	esp,12
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_487
	call	brl_blitz_NullObjectError
_487:
	mov	eax,dword [ebx+12]
	mov	dword [ebp-20],eax
	call	dword [bbOnDebugLeaveScope]
_480:
	push	_489
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	dword [brl_reflection_TTypeId+128]
	add	esp,4
	mov	dword [ebp-24],eax
	push	_491
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-28],bbNullObject
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_494
	call	brl_blitz_NullObjectError
_494:
	push	bbNullObject
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+96]
	add	esp,8
	mov	dword [ebp-32],eax
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_497
	call	brl_blitz_NullObjectError
_497:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_28
_30:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_502
	call	brl_blitz_NullObjectError
_502:
	push	brl_reflection_TField
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-28],eax
	cmp	dword [ebp-28],bbNullObject
	je	_28
	mov	eax,ebp
	push	eax
	push	_517
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_503
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_505
	call	brl_blitz_NullObjectError
_505:
	push	_17
	push	_16
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_510
	mov	esi,dword [ebp-28]
	cmp	esi,bbNullObject
	jne	_507
	call	brl_blitz_NullObjectError
_507:
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_509
	call	brl_blitz_NullObjectError
_509:
	push	dword [ebx+8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	brl_retro_Upper
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_510:
	cmp	eax,0
	je	_512
	mov	eax,ebp
	push	eax
	push	_516
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_513
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_515
	call	brl_blitz_NullObjectError
_515:
	push	dword [ebp-20]
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_512:
	call	dword [bbOnDebugLeaveScope]
_28:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_500
	call	brl_blitz_NullObjectError
_500:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_30
_29:
	push	_518
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_520
	call	brl_blitz_NullObjectError
_520:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_523
	call	brl_blitz_NullObjectError
_523:
	mov	esi,dword [esi+12]
	cmp	esi,bbNullObject
	jne	_525
	call	brl_blitz_NullObjectError
_525:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+132]
	add	esp,4
	mov	dword [ebx+12],eax
	push	_526
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],brl_blitz_NullFunctionError
	je	_527
	mov	eax,ebp
	push	eax
	push	_529
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_528
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-16]
	push	dword [ebp-8]
	call	dword [ebp-12]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_527:
	call	dword [bbOnDebugLeaveScope]
_25:
	cmp	dword [ebp-16],bbNullObject
	jne	_27
_26:
	push	_531
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_104
_104:
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
_111:
	db	"basefunctions_loadsave",0
_112:
	db	"APPEND_STATUS_CREATE",0
_42:
	db	"i",0
	align	4
_113:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	48
_114:
	db	"APPEND_STATUS_CREATEAFTER",0
	align	4
_115:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	49
_116:
	db	"APPEND_STATUS_ADDINZIP",0
	align	4
_117:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	50
_118:
	db	"Z_DEFLATED",0
	align	4
_119:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	56
_120:
	db	"Z_NO_COMPRESSION",0
_121:
	db	"Z_BEST_SPEED",0
_122:
	db	"Z_BEST_COMPRESSION",0
	align	4
_123:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	57
_124:
	db	"Z_DEFAULT_COMPRESSION",0
	align	4
_125:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,49
_126:
	db	"UNZ_CASE_CHECK",0
_127:
	db	"UNZ_NO_CASE_CHECK",0
_128:
	db	"UNZ_OK",0
_129:
	db	"UNZ_END_OF_LIST_OF_FILE",0
	align	4
_130:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,48
_131:
	db	"UNZ_EOF",0
_132:
	db	"UNZ_PARAMERROR",0
	align	4
_133:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,50
_134:
	db	"UNZ_BADZIPFILE",0
	align	4
_135:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,51
_136:
	db	"UNZ_INTERNALERROR",0
	align	4
_137:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,52
_138:
	db	"UNZ_CRCERROR",0
	align	4
_139:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,53
_140:
	db	"ZLIB_FILEFUNC_SEEK_CUR",0
_141:
	db	"ZLIB_FILEFUNC_SEEK_END",0
_142:
	db	"ZLIB_FILEFUNC_SEEK_SET",0
_143:
	db	"Z_OK",0
_144:
	db	"Z_STREAM_END",0
_145:
	db	"Z_NEED_DICT",0
_146:
	db	"Z_ERRNO",0
_147:
	db	"Z_STREAM_ERROR",0
	align	4
_148:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,50
_149:
	db	"Z_DATA_ERROR",0
	align	4
_150:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,51
_151:
	db	"Z_MEM_ERROR",0
	align	4
_152:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,52
_153:
	db	"Z_BUF_ERROR",0
	align	4
_154:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,53
_155:
	db	"Z_VERSION_ERROR",0
	align	4
_156:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,54
_157:
	db	"ZIP_INFO_IN_DATA_DESCRIPTOR",0
_158:
	db	"s",0
_159:
	db	"AS_CHILD",0
_160:
	db	"AS_SIBLING",0
_161:
	db	"FORMAT_XML",0
_162:
	db	"FORMAT_BINARY",0
_163:
	db	"SORTBY_NODE_NAME",0
_164:
	db	"SORTBY_NODE_VALUE",0
_165:
	db	"SORTBY_ATTR_NAME",0
	align	4
_166:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	51
_167:
	db	"SORTBY_ATTR_VALUE",0
	align	4
_168:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	52
_169:
	db	"LoadSaveFile",0
_170:
	db	":TSaveFile",0
	align	4
bb_LoadSaveFile:
	dd	bbNullObject
	align	4
_110:
	dd	1
	dd	_111
	dd	1
	dd	_112
	dd	_42
	dd	_113
	dd	1
	dd	_114
	dd	_42
	dd	_115
	dd	1
	dd	_116
	dd	_42
	dd	_117
	dd	1
	dd	_118
	dd	_42
	dd	_119
	dd	1
	dd	_120
	dd	_42
	dd	_113
	dd	1
	dd	_121
	dd	_42
	dd	_115
	dd	1
	dd	_122
	dd	_42
	dd	_123
	dd	1
	dd	_124
	dd	_42
	dd	_125
	dd	1
	dd	_126
	dd	_42
	dd	_115
	dd	1
	dd	_127
	dd	_42
	dd	_117
	dd	1
	dd	_128
	dd	_42
	dd	_113
	dd	1
	dd	_129
	dd	_42
	dd	_130
	dd	1
	dd	_131
	dd	_42
	dd	_113
	dd	1
	dd	_132
	dd	_42
	dd	_133
	dd	1
	dd	_134
	dd	_42
	dd	_135
	dd	1
	dd	_136
	dd	_42
	dd	_137
	dd	1
	dd	_138
	dd	_42
	dd	_139
	dd	1
	dd	_140
	dd	_42
	dd	_115
	dd	1
	dd	_141
	dd	_42
	dd	_117
	dd	1
	dd	_142
	dd	_42
	dd	_113
	dd	1
	dd	_143
	dd	_42
	dd	_113
	dd	1
	dd	_144
	dd	_42
	dd	_115
	dd	1
	dd	_145
	dd	_42
	dd	_117
	dd	1
	dd	_146
	dd	_42
	dd	_125
	dd	1
	dd	_147
	dd	_42
	dd	_148
	dd	1
	dd	_149
	dd	_42
	dd	_150
	dd	1
	dd	_151
	dd	_42
	dd	_152
	dd	1
	dd	_153
	dd	_42
	dd	_154
	dd	1
	dd	_155
	dd	_42
	dd	_156
	dd	1
	dd	_157
	dd	_158
	dd	_119
	dd	1
	dd	_159
	dd	_42
	dd	_115
	dd	1
	dd	_160
	dd	_42
	dd	_117
	dd	1
	dd	_161
	dd	_42
	dd	_115
	dd	1
	dd	_162
	dd	_42
	dd	_117
	dd	1
	dd	_163
	dd	_42
	dd	_115
	dd	1
	dd	_164
	dd	_42
	dd	_117
	dd	1
	dd	_165
	dd	_42
	dd	_166
	dd	1
	dd	_167
	dd	_42
	dd	_168
	dd	4
	dd	_169
	dd	_170
	dd	bb_LoadSaveFile
	dd	0
_32:
	db	"TSaveFile",0
_33:
	db	"file",0
_34:
	db	":xmlDocument",0
_35:
	db	"node",0
_36:
	db	":xmlNode",0
_37:
	db	"currentnode",0
_38:
	db	"root",0
_39:
	db	"Nodes",0
_40:
	db	"[]:xmlNode",0
_41:
	db	"NodeDepth",0
_43:
	db	"lastNode",0
_44:
	db	"New",0
_45:
	db	"()i",0
_46:
	db	"Create",0
_47:
	db	"():TSaveFile",0
_48:
	db	"InitSave",0
_49:
	db	"InitLoad",0
_50:
	db	"($,b)i",0
_51:
	db	"xmlWrite",0
_52:
	db	"($,$,b,i)i",0
_53:
	db	"xmlCloseNode",0
_54:
	db	"xmlBeginNode",0
_55:
	db	"($)i",0
_56:
	db	"xmlSave",0
_57:
	db	"SaveObject",0
_58:
	db	"(:Object,$,(:Object)i)i",0
_59:
	db	"LoadObject",0
_60:
	db	"(:Object,(:Object,:xmlnode)i):Object",0
	align	4
_31:
	dd	2
	dd	_32
	dd	3
	dd	_33
	dd	_34
	dd	8
	dd	3
	dd	_35
	dd	_36
	dd	12
	dd	3
	dd	_37
	dd	_36
	dd	16
	dd	3
	dd	_38
	dd	_36
	dd	20
	dd	3
	dd	_39
	dd	_40
	dd	24
	dd	3
	dd	_41
	dd	_42
	dd	28
	dd	3
	dd	_43
	dd	_36
	dd	32
	dd	6
	dd	_44
	dd	_45
	dd	16
	dd	7
	dd	_46
	dd	_47
	dd	48
	dd	6
	dd	_48
	dd	_45
	dd	52
	dd	6
	dd	_49
	dd	_50
	dd	56
	dd	6
	dd	_51
	dd	_52
	dd	60
	dd	6
	dd	_53
	dd	_45
	dd	64
	dd	6
	dd	_54
	dd	_55
	dd	68
	dd	6
	dd	_56
	dd	_50
	dd	72
	dd	6
	dd	_57
	dd	_58
	dd	76
	dd	6
	dd	_59
	dd	_60
	dd	80
	dd	0
	align	4
bb_TSaveFile:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_31
	dd	36
	dd	_bb_TSaveFile_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TSaveFile_Create
	dd	_bb_TSaveFile_InitSave
	dd	_bb_TSaveFile_InitLoad
	dd	_bb_TSaveFile_xmlWrite
	dd	_bb_TSaveFile_xmlCloseNode
	dd	_bb_TSaveFile_xmlBeginNode
	dd	_bb_TSaveFile_xmlSave
	dd	_bb_TSaveFile_SaveObject
	dd	_bb_TSaveFile_LoadObject
_107:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_loadsave.bmx",0
	align	4
_106:
	dd	_107
	dd	112
	dd	1
	align	4
_108:
	dd	0
_176:
	db	"Self",0
	align	4
_175:
	dd	1
	dd	_44
	dd	2
	dd	_176
	dd	_170
	dd	-4
	dd	0
_173:
	db	":xmlNode",0
	align	4
_174:
	dd	3
	dd	0
	dd	0
_181:
	db	"tmpobj",0
	align	4
_180:
	dd	1
	dd	_46
	dd	2
	dd	_181
	dd	_170
	dd	-4
	dd	0
	align	4
_177:
	dd	_107
	dd	15
	dd	4
	align	4
_179:
	dd	_107
	dd	16
	dd	2
	align	4
_215:
	dd	1
	dd	_48
	dd	2
	dd	_176
	dd	_170
	dd	-4
	dd	0
	align	4
_182:
	dd	_107
	dd	20
	dd	2
	align	4
_186:
	dd	_107
	dd	21
	dd	2
	align	4
_194:
	dd	_107
	dd	22
	dd	2
	align	4
_3:
	dd	bbStringClass
	dd	2147483647
	dd	8
	dw	115,97,118,101,103,97,109,101
	align	4
_200:
	dd	_107
	dd	23
	dd	5
	align	4
_209:
	dd	_107
	dd	24
	dd	2
_235:
	db	"filename",0
_236:
	db	"$",0
_237:
	db	"zipped",0
_238:
	db	"b",0
	align	4
_234:
	dd	1
	dd	_49
	dd	2
	dd	_176
	dd	_170
	dd	-8
	dd	2
	dd	_235
	dd	_236
	dd	-12
	dd	2
	dd	_237
	dd	_238
	dd	-4
	dd	0
	align	4
_216:
	dd	_107
	dd	28
	dd	5
	align	4
_220:
	dd	_107
	dd	29
	dd	2
	align	4
_228:
	dd	_107
	dd	30
	dd	2
_299:
	db	"typ",0
_300:
	db	"str",0
_301:
	db	"newDepth",0
_302:
	db	"depth",0
	align	4
_298:
	dd	1
	dd	_51
	dd	2
	dd	_176
	dd	_170
	dd	-8
	dd	2
	dd	_299
	dd	_236
	dd	-12
	dd	2
	dd	_300
	dd	_236
	dd	-16
	dd	2
	dd	_301
	dd	_238
	dd	-4
	dd	2
	dd	_302
	dd	_42
	dd	-20
	dd	0
	align	4
_239:
	dd	_107
	dd	34
	dd	2
	align	4
_246:
	dd	3
	dd	0
	dd	0
	align	4
_243:
	dd	_107
	dd	34
	dd	35
	align	4
_247:
	dd	_107
	dd	35
	dd	5
	align	4
_282:
	dd	3
	dd	0
	dd	0
	align	4
_249:
	dd	_107
	dd	36
	dd	3
	align	4
_265:
	dd	_107
	dd	37
	dd	3
	align	4
_6:
	dd	bbStringClass
	dd	2147483647
	dd	3
	dw	118,97,114
	align	4
_278:
	dd	_107
	dd	38
	dd	3
	align	4
_297:
	dd	3
	dd	0
	dd	0
	align	4
_284:
	dd	_107
	dd	40
	dd	3
	align	4
_307:
	dd	1
	dd	_53
	dd	2
	dd	_176
	dd	_170
	dd	-4
	dd	0
	align	4
_303:
	dd	_107
	dd	45
	dd	5
	align	4
_330:
	dd	1
	dd	_54
	dd	2
	dd	_176
	dd	_170
	dd	-4
	dd	2
	dd	_300
	dd	_236
	dd	-8
	dd	0
	align	4
_308:
	dd	_107
	dd	49
	dd	2
	align	4
_326:
	dd	_107
	dd	50
	dd	5
	align	4
_346:
	dd	1
	dd	_56
	dd	2
	dd	_176
	dd	_170
	dd	-8
	dd	2
	dd	_235
	dd	_236
	dd	-12
	dd	2
	dd	_237
	dd	_238
	dd	-4
	dd	0
	align	4
_331:
	dd	_107
	dd	54
	dd	2
	align	4
_7:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	45
	align	4
_338:
	dd	3
	dd	0
	dd	0
	align	4
_333:
	dd	_107
	dd	54
	dd	25
	align	4
_8:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	110,111,100,101,115,58
	align	4
_345:
	dd	3
	dd	0
	dd	0
	align	4
_340:
	dd	_107
	dd	54
	dd	67
_462:
	db	"obj",0
_369:
	db	":Object",0
_463:
	db	"nodename",0
_464:
	db	"_addfunc",0
_465:
	db	"(:Object)i",0
_466:
	db	"result",0
	align	4
_461:
	dd	1
	dd	_57
	dd	2
	dd	_176
	dd	_170
	dd	-4
	dd	2
	dd	_462
	dd	_369
	dd	-8
	dd	2
	dd	_463
	dd	_236
	dd	-12
	dd	2
	dd	_464
	dd	_465
	dd	-16
	dd	2
	dd	_466
	dd	_236
	dd	-20
	dd	0
	align	4
_347:
	dd	_107
	dd	59
	dd	3
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_349:
	dd	_107
	dd	60
	dd	6
	align	4
_352:
	dd	_107
	dd	62
	dd	4
	align	4
_370:
	dd	3
	dd	0
	dd	0
	align	4
_354:
	dd	_107
	dd	63
	dd	5
_368:
	db	"listobj",0
	align	4
_367:
	dd	3
	dd	0
	dd	2
	dd	_368
	dd	_369
	dd	-24
	dd	0
	align	4
_364:
	dd	_107
	dd	64
	dd	6
	align	4
_12:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	95,67,72,73,76,68
_449:
	db	":brl.reflection.TTypeId",0
	align	4
_457:
	dd	3
	dd	0
	dd	2
	dd	_299
	dd	_449
	dd	-28
	dd	0
	align	4
_372:
	dd	_107
	dd	68
	dd	5
	align	4
_374:
	dd	_107
	dd	69
	dd	5
_451:
	db	"t",0
_452:
	db	":brl.reflection.TField",0
	align	4
_450:
	dd	3
	dd	0
	dd	2
	dd	_451
	dd	_452
	dd	-32
	dd	0
	align	4
_386:
	dd	_107
	dd	70
	dd	6
	align	4
_17:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	110,111
	align	4
_16:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	115,108
_448:
	db	"fieldtype",0
	align	4
_447:
	dd	3
	dd	0
	dd	2
	dd	_448
	dd	_449
	dd	-36
	dd	0
	align	4
_390:
	dd	_107
	dd	71
	dd	7
	align	4
_394:
	dd	_107
	dd	72
	dd	7
	align	4
_408:
	dd	3
	dd	0
	dd	0
	align	4
_398:
	dd	_107
	dd	73
	dd	8
	align	4
_407:
	dd	3
	dd	0
	dd	0
	align	4
_402:
	dd	_107
	dd	74
	dd	9
	align	4
_20:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	39
	align	4
_19:
	dd	bbStringClass
	dd	2147483647
	dd	3
	dw	32,45,32
	align	4
_18:
	dd	bbStringClass
	dd	2147483647
	dd	7
	dw	97,114,114,97,121,32,39
	align	4
_409:
	dd	_107
	dd	77
	dd	7
_434:
	db	"liste",0
_435:
	db	":brl.linkedlist.TList",0
	align	4
_433:
	dd	3
	dd	0
	dd	2
	dd	_434
	dd	_435
	dd	-40
	dd	0
	align	4
_413:
	dd	_107
	dd	78
	dd	8
	align	4
_417:
	dd	_107
	dd	79
	dd	8
_432:
	db	"childobj",0
	align	4
_431:
	dd	3
	dd	0
	dd	2
	dd	_432
	dd	_369
	dd	-44
	dd	0
	align	4
_427:
	dd	_107
	dd	80
	dd	9
	align	4
_24:
	dd	bbStringClass
	dd	2147483647
	dd	23
	dw	115,97,118,105,110,103,32,108,105,115,116,32,99,104,105,108
	dw	100,114,101,110,46,46,46
	align	4
_428:
	dd	_107
	dd	81
	dd	9
	align	4
_446:
	dd	3
	dd	0
	dd	0
	align	4
_437:
	dd	_107
	dd	84
	dd	8
	align	4
_453:
	dd	_107
	dd	88
	dd	5
	align	4
_456:
	dd	3
	dd	0
	dd	0
	align	4
_455:
	dd	_107
	dd	88
	dd	30
	align	4
_458:
	dd	_107
	dd	90
	dd	3
_533:
	db	"_handleNodefunc",0
_534:
	db	"(:Object,:xmlnode)i",0
_535:
	db	"NODE",0
_536:
	db	"nodevalue",0
	align	4
_532:
	dd	1
	dd	_59
	dd	2
	dd	_176
	dd	_170
	dd	-4
	dd	2
	dd	_462
	dd	_369
	dd	-8
	dd	2
	dd	_533
	dd	_534
	dd	-12
	dd	2
	dd	_535
	dd	_36
	dd	-16
	dd	2
	dd	_536
	dd	_236
	dd	-20
	dd	0
	align	4
_467:
	dd	_107
	dd	95
	dd	3
	align	4
_473:
	dd	_107
	dd	96
	dd	3
	align	4
_475:
	dd	_107
	dd	97
	dd	3
	align	4
_530:
	dd	3
	dd	0
	dd	2
	dd	_299
	dd	_449
	dd	-24
	dd	0
	align	4
_476:
	dd	_107
	dd	98
	dd	4
	align	4
_477:
	dd	_107
	dd	99
	dd	4
	align	4
_488:
	dd	3
	dd	0
	dd	0
	align	4
_481:
	dd	_107
	dd	99
	dd	44
	align	4
_489:
	dd	_107
	dd	100
	dd	4
	align	4
_491:
	dd	_107
	dd	101
	dd	4
	align	4
_517:
	dd	3
	dd	0
	dd	2
	dd	_451
	dd	_452
	dd	-28
	dd	0
	align	4
_503:
	dd	_107
	dd	102
	dd	5
	align	4
_516:
	dd	3
	dd	0
	dd	0
	align	4
_513:
	dd	_107
	dd	103
	dd	6
	align	4
_518:
	dd	_107
	dd	106
	dd	4
	align	4
_526:
	dd	_107
	dd	107
	dd	4
	align	4
_529:
	dd	3
	dd	0
	dd	0
	align	4
_528:
	dd	_107
	dd	107
	dd	36
	align	4
_531:
	dd	_107
	dd	109
	dd	3
