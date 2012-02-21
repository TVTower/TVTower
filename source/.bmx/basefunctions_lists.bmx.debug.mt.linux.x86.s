	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	_bbExEnter
	extrn	bbArraySlice
	extrn	bbEmptyArray
	extrn	bbEmptyString
	extrn	bbExEnter
	extrn	bbExLeave
	extrn	bbExThrow
	extrn	bbGCCollect
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
	extrn	bbOnDebugEnterScope
	extrn	bbOnDebugEnterStm
	extrn	bbOnDebugLeaveScope
	extrn	bbOnDebugPopExState
	extrn	bbOnDebugPushExState
	extrn	bbStringClass
	extrn	bbStringConcat
	extrn	brl_blitz_ArrayBoundsError
	extrn	brl_blitz_NullObjectError
	extrn	brl_blitz_RuntimeError
	public	__bb_source_basefunctions_lists
	public	_bb_TObjectList_AddFirst
	public	_bb_TObjectList_AddLast
	public	_bb_TObjectList_Clear
	public	_bb_TObjectList_Contains
	public	_bb_TObjectList_Count
	public	_bb_TObjectList_Create
	public	_bb_TObjectList_Destroy
	public	_bb_TObjectList_Free
	public	_bb_TObjectList_FromObjectArray
	public	_bb_TObjectList_GetStepSize
	public	_bb_TObjectList_Insert
	public	_bb_TObjectList_New
	public	_bb_TObjectList_RemoveByIndex
	public	_bb_TObjectList_RemoveByObject
	public	_bb_TObjectList_SetStepSize
	public	_bb_TObjectList_Sort
	public	_bb_TObjectList_SwapByIndex
	public	_bb_TObjectList_SwapByVal
	public	_bb_TObjectList_ToArray
	public	_bb_TObjectList_ToDelimString
	public	_bb_TObjectList_ToList
	public	_bb_TObjectList_ToString
	public	bb_TObjectList
	section	"code" executable
__bb_source_basefunctions_lists:
	push	ebp
	mov	ebp,esp
	push	ebx
	cmp	dword [_153],0
	je	_154
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_154:
	mov	dword [_153],1
	push	ebp
	push	_151
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	__bb_blitz_blitz
	call	__bb_glmax2d_glmax2d
	push	bb_TObjectList
	call	bbObjectRegisterType
	add	esp,4
	mov	ebx,0
	jmp	_67
_67:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_156
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TObjectList
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbEmptyArray
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],0
	push	ebp
	push	_155
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_70
_70:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_AddFirst:
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
	mov	eax,ebp
	push	eax
	push	_209
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_159
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	push	_162
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_164
	call	brl_blitz_NullObjectError
_164:
	add	dword [ebx+12],1
	push	_166
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_168
	call	brl_blitz_NullObjectError
_168:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_170
	call	brl_blitz_NullObjectError
_170:
	mov	edx,dword [esi+8]
	mov	eax,dword [ebx+12]
	cmp	dword [edx+20],eax
	jge	_171
	mov	eax,ebp
	push	eax
	push	_183
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_172
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_174
	call	brl_blitz_NullObjectError
_174:
	mov	dword [ebp-20],ebx
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_177
	call	brl_blitz_NullObjectError
_177:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_179
	call	brl_blitz_NullObjectError
_179:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_181
	call	brl_blitz_NullObjectError
_181:
	mov	eax,dword [esi+12]
	add	eax,dword [ebx+16]
	push	eax
	push	0
	push	dword [edi+8]
	push	_182
	call	bbArraySlice
	add	esp,16
	mov	edx,dword [ebp-20]
	mov	dword [edx+8],eax
	call	dword [bbOnDebugLeaveScope]
_171:
	push	_184
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],1
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_186
	call	brl_blitz_NullObjectError
_186:
	mov	eax,dword [ebx+12]
	sub	eax,1
	mov	dword [ebp-16],eax
	jmp	_187
_4:
	mov	eax,ebp
	push	eax
	push	_201
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_189
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_191
	call	brl_blitz_NullObjectError
_191:
	mov	ebx,dword [ebx+8]
	mov	esi,dword [ebp-12]
	cmp	esi,dword [ebx+20]
	jb	_194
	call	brl_blitz_ArrayBoundsError
_194:
	shl	esi,2
	add	ebx,esi
	mov	edi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_197
	call	brl_blitz_NullObjectError
_197:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-12]
	sub	eax,1
	mov	ebx,eax
	cmp	ebx,dword [esi+20]
	jb	_200
	call	brl_blitz_ArrayBoundsError
_200:
	mov	eax,dword [esi+ebx*4+24]
	mov	dword [edi+24],eax
	call	dword [bbOnDebugLeaveScope]
_2:
	add	dword [ebp-12],1
_187:
	mov	eax,dword [ebp-16]
	cmp	dword [ebp-12],eax
	jle	_4
_3:
	push	_202
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_204
	call	brl_blitz_NullObjectError
_204:
	mov	esi,dword [ebx+8]
	mov	ebx,0
	cmp	ebx,dword [esi+20]
	jb	_207
	call	brl_blitz_ArrayBoundsError
_207:
	shl	ebx,2
	add	esi,ebx
	mov	eax,dword [ebp-8]
	mov	dword [esi+24],eax
	mov	ebx,0
	jmp	_74
_74:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_AddLast:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,ebp
	push	eax
	push	_244
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_211
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_213
	call	brl_blitz_NullObjectError
_213:
	add	dword [ebx+12],1
	push	_215
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_217
	call	brl_blitz_NullObjectError
_217:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_219
	call	brl_blitz_NullObjectError
_219:
	mov	edx,dword [esi+8]
	mov	eax,dword [ebx+12]
	cmp	dword [edx+20],eax
	jge	_220
	mov	eax,ebp
	push	eax
	push	_231
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
	mov	dword [ebp-12],ebx
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_226
	call	brl_blitz_NullObjectError
_226:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_228
	call	brl_blitz_NullObjectError
_228:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_230
	call	brl_blitz_NullObjectError
_230:
	mov	eax,dword [esi+12]
	add	eax,dword [ebx+16]
	push	eax
	push	0
	push	dword [edi+8]
	push	_182
	call	bbArraySlice
	add	esp,16
	mov	edx,dword [ebp-12]
	mov	dword [edx+8],eax
	call	dword [bbOnDebugLeaveScope]
_220:
	push	_232
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_234
	call	brl_blitz_NullObjectError
_234:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_237
	call	brl_blitz_NullObjectError
_237:
	mov	ebx,dword [ebx+12]
	sub	ebx,1
	cmp	ebx,dword [esi+20]
	jb	_239
	call	brl_blitz_ArrayBoundsError
_239:
	shl	ebx,2
	add	esi,ebx
	mov	eax,dword [ebp-8]
	mov	dword [esi+24],eax
	push	_241
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_243
	call	brl_blitz_NullObjectError
_243:
	mov	ebx,dword [ebx+12]
	jmp	_78
_78:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_ToDelimString:
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
	mov	dword [ebp-12],bbEmptyString
	mov	dword [ebp-16],0
	mov	eax,ebp
	push	eax
	push	_274
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_245
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],_1
	push	_247
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],0
	push	_249
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],0
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_251
	call	brl_blitz_NullObjectError
_251:
	mov	eax,dword [ebx+12]
	sub	eax,2
	mov	edi,eax
	jmp	_252
_7:
	mov	eax,ebp
	push	eax
	push	_262
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_254
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_256
	call	brl_blitz_NullObjectError
_256:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-16]
	cmp	ebx,dword [esi+20]
	jb	_259
	call	brl_blitz_ArrayBoundsError
_259:
	mov	ebx,dword [esi+ebx*4+24]
	cmp	ebx,bbNullObject
	jne	_261
	call	brl_blitz_NullObjectError
_261:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+24]
	add	esp,4
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	dword [ebp-12]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-12],eax
	call	dword [bbOnDebugLeaveScope]
_5:
	add	dword [ebp-16],1
_252:
	cmp	dword [ebp-16],edi
	jle	_7
_6:
	push	_263
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_265
	call	brl_blitz_NullObjectError
_265:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_268
	call	brl_blitz_NullObjectError
_268:
	mov	ebx,dword [ebx+12]
	sub	ebx,1
	cmp	ebx,dword [esi+20]
	jb	_270
	call	brl_blitz_ArrayBoundsError
_270:
	mov	ebx,dword [esi+ebx*4+24]
	cmp	ebx,bbNullObject
	jne	_272
	call	brl_blitz_NullObjectError
_272:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+24]
	add	esp,4
	push	eax
	push	dword [ebp-12]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-12],eax
	push	_273
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_82
_82:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_ToString:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_281
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_278
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_280
	call	brl_blitz_NullObjectError
_280:
	push	_1
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,8
	mov	ebx,eax
	jmp	_85
_85:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Count:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_285
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_282
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_284
	call	brl_blitz_NullObjectError
_284:
	mov	ebx,dword [ebx+12]
	jmp	_88
_88:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Contains:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],0
	mov	eax,ebp
	push	eax
	push	_304
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_286
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	push	_288
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_290
	call	brl_blitz_NullObjectError
_290:
	mov	eax,dword [ebx+12]
	sub	eax,1
	mov	edi,eax
	jmp	_291
_10:
	mov	eax,ebp
	push	eax
	push	_302
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_293
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_295
	call	brl_blitz_NullObjectError
_295:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_298
	call	brl_blitz_ArrayBoundsError
_298:
	mov	eax,dword [esi+ebx*4+24]
	cmp	dword [ebp-8],eax
	jne	_299
	mov	eax,ebp
	push	eax
	push	_301
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_300
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_92
_299:
	call	dword [bbOnDebugLeaveScope]
_8:
	add	dword [ebp-12],1
_291:
	cmp	dword [ebp-12],edi
	jle	_10
_9:
	push	_303
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,-1
	jmp	_92
_92:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_FromObjectArray:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_322
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_305
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	10
	call	dword [bb_TObjectList+124]
	add	esp,4
	mov	dword [ebp-8],eax
	push	_307
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugPushExState]
	call	bbExEnter
	mov	esi,eax
	push	esi
	call	_bbExEnter
	add	esp,4
	mov	esi,eax
	cmp	esi,0
	jne	_309
	push	ebp
	push	_315
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_311
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_313
	call	brl_blitz_NullObjectError
_313:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+8],eax
	call	dword [bbOnDebugLeaveScope]
	call	bbExLeave
	call	dword [bbOnDebugPopExState]
	jmp	_310
_309:
	call	dword [bbOnDebugPopExState]
	push	bbStringClass
	push	esi
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_316
	push	esi
	call	bbExThrow
	add	esp,4
_316:
	push	ebp
	push	_320
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_318
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	ebx
	push	_11
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_blitz_RuntimeError
	add	esp,4
	push	_319
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_95
_310:
	push	_321
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_95
_95:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Insert:
	push	ebp
	mov	ebp,esp
	sub	esp,28
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
	mov	dword [ebp-20],0
	mov	eax,ebp
	push	eax
	push	_401
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_324
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	push	_326
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	jge	_327
	mov	eax,ebp
	push	eax
	push	_329
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_328
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_101
_327:
	push	_330
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_332
	call	brl_blitz_NullObjectError
_332:
	mov	eax,dword [ebx+12]
	cmp	dword [ebp-12],eax
	jle	_333
	mov	eax,ebp
	push	eax
	push	_344
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_334
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],0
	jne	_335
	mov	eax,ebp
	push	eax
	push	_337
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_336
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_101
_335:
	mov	eax,ebp
	push	eax
	push	_343
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_339
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_341
	call	brl_blitz_NullObjectError
_341:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,8
	push	_342
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_101
_333:
	push	_345
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_347
	call	brl_blitz_NullObjectError
_347:
	mov	eax,dword [ebx+12]
	cmp	dword [ebp-12],eax
	jne	_348
	mov	eax,ebp
	push	eax
	push	_353
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
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,8
	push	_352
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	jmp	_101
_348:
	push	_354
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_356
	call	brl_blitz_NullObjectError
_356:
	add	dword [ebx+12],1
	push	_358
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_360
	call	brl_blitz_NullObjectError
_360:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_362
	call	brl_blitz_NullObjectError
_362:
	mov	edx,dword [esi+8]
	mov	eax,dword [ebx+12]
	cmp	dword [edx+20],eax
	jge	_363
	mov	eax,ebp
	push	eax
	push	_374
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
	mov	dword [ebp-28],ebx
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_369
	call	brl_blitz_NullObjectError
_369:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_371
	call	brl_blitz_NullObjectError
_371:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_373
	call	brl_blitz_NullObjectError
_373:
	mov	eax,dword [esi+12]
	add	eax,dword [ebx+16]
	push	eax
	push	0
	push	dword [edi+8]
	push	_182
	call	bbArraySlice
	add	esp,16
	mov	edx,dword [ebp-28]
	mov	dword [edx+8],eax
	call	dword [bbOnDebugLeaveScope]
_363:
	push	_375
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_377
	call	brl_blitz_NullObjectError
_377:
	mov	eax,dword [ebx+12]
	sub	eax,1
	mov	dword [ebp-20],eax
	mov	eax,dword [ebp-12]
	add	eax,1
	mov	dword [ebp-24],eax
	jmp	_378
_14:
	mov	eax,ebp
	push	eax
	push	_392
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
	mov	ebx,dword [ebx+8]
	mov	esi,dword [ebp-20]
	cmp	esi,dword [ebx+20]
	jb	_385
	call	brl_blitz_ArrayBoundsError
_385:
	shl	esi,2
	add	ebx,esi
	mov	edi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_388
	call	brl_blitz_NullObjectError
_388:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-20]
	sub	eax,1
	mov	ebx,eax
	cmp	ebx,dword [esi+20]
	jb	_391
	call	brl_blitz_ArrayBoundsError
_391:
	mov	eax,dword [esi+ebx*4+24]
	mov	dword [edi+24],eax
	call	dword [bbOnDebugLeaveScope]
_12:
	add	dword [ebp-20],-1
_378:
	mov	eax,dword [ebp-24]
	cmp	dword [ebp-20],eax
	jge	_14
_13:
	push	_393
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_395
	call	brl_blitz_NullObjectError
_395:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_398
	call	brl_blitz_ArrayBoundsError
_398:
	shl	ebx,2
	add	esi,ebx
	mov	eax,dword [ebp-8]
	mov	dword [esi+24],eax
	push	_400
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_101
_101:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_RemoveByIndex:
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
	mov	eax,ebp
	push	eax
	push	_463
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_404
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	push	_406
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [ebp-12],eax
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_408
	call	brl_blitz_NullObjectError
_408:
	mov	eax,dword [ebx+12]
	sub	eax,2
	mov	dword [ebp-16],eax
	jmp	_409
_17:
	mov	eax,ebp
	push	eax
	push	_423
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_411
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_413
	call	brl_blitz_NullObjectError
_413:
	mov	ebx,dword [ebx+8]
	mov	esi,dword [ebp-12]
	cmp	esi,dword [ebx+20]
	jb	_416
	call	brl_blitz_ArrayBoundsError
_416:
	shl	esi,2
	add	ebx,esi
	mov	edi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_419
	call	brl_blitz_NullObjectError
_419:
	mov	esi,dword [ebx+8]
	mov	eax,dword [ebp-12]
	add	eax,1
	mov	ebx,eax
	cmp	ebx,dword [esi+20]
	jb	_422
	call	brl_blitz_ArrayBoundsError
_422:
	mov	eax,dword [esi+ebx*4+24]
	mov	dword [edi+24],eax
	call	dword [bbOnDebugLeaveScope]
_15:
	add	dword [ebp-12],1
_409:
	mov	eax,dword [ebp-16]
	cmp	dword [ebp-12],eax
	jle	_17
_16:
	push	_424
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_426
	call	brl_blitz_NullObjectError
_426:
	sub	dword [ebx+12],1
	push	_428
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_430
	call	brl_blitz_NullObjectError
_430:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_432
	call	brl_blitz_NullObjectError
_432:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_434
	call	brl_blitz_NullObjectError
_434:
	mov	eax,dword [esi+8]
	mov	edx,dword [eax+20]
	mov	eax,dword [ebx+16]
	shl	eax,1
	sub	edx,eax
	cmp	dword [edi+12],edx
	jge	_435
	mov	eax,ebp
	push	eax
	push	_444
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
	mov	edi,ebx
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_441
	call	brl_blitz_NullObjectError
_441:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_443
	call	brl_blitz_NullObjectError
_443:
	push	dword [ebx+12]
	push	0
	push	dword [esi+8]
	push	_182
	call	bbArraySlice
	add	esp,16
	mov	dword [edi+8],eax
	call	dword [bbOnDebugLeaveScope]
_435:
	push	_445
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_447
	call	brl_blitz_NullObjectError
_447:
	cmp	dword [ebx+12],0
	jge	_448
	mov	eax,ebp
	push	eax
	push	_453
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
	mov	dword [ebx+12],0
	call	dword [bbOnDebugLeaveScope]
_448:
	push	_454
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_456
	call	brl_blitz_NullObjectError
_456:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_459
	call	brl_blitz_NullObjectError
_459:
	mov	ebx,dword [ebx+12]
	cmp	ebx,dword [esi+20]
	jb	_461
	call	brl_blitz_ArrayBoundsError
_461:
	shl	ebx,2
	add	esi,ebx
	mov	dword [esi+24],bbNullObject
	mov	ebx,0
	jmp	_105
_105:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_RemoveByObject:
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
	mov	dword [ebp-16],0
	push	ebp
	push	_482
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_464
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],0
	push	_466
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_468
	call	brl_blitz_NullObjectError
_468:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-16],eax
	push	_469
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_18
_20:
	push	ebp
	push	_480
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
	push	dword [ebp-16]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,8
	push	_473
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	jne	_474
	push	ebp
	push	_476
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_475
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_19
_474:
	push	_477
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_479
	call	brl_blitz_NullObjectError
_479:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
_18:
	cmp	dword [ebp-16],-1
	jg	_20
_19:
	push	_481
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_110
_110:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Clear:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_494
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_484
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_486
	call	brl_blitz_NullObjectError
_486:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_489
	call	brl_blitz_NullObjectError
_489:
	push	0
	push	0
	push	dword [esi+8]
	push	_182
	call	bbArraySlice
	add	esp,16
	mov	dword [ebx+8],eax
	push	_490
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_492
	call	brl_blitz_NullObjectError
_492:
	mov	dword [ebx+12],0
	mov	ebx,0
	jmp	_113
_113:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_ToArray:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_500
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_495
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_497
	call	brl_blitz_NullObjectError
_497:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_499
	call	brl_blitz_NullObjectError
_499:
	mov	eax,dword [esi+12]
	sub	eax,1
	push	eax
	push	0
	push	dword [ebx+8]
	push	_182
	call	bbArraySlice
	add	esp,16
	mov	ebx,eax
	jmp	_116
_116:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_ToList:
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
	mov	dword [ebp-12],bbNullObject
	mov	eax,ebp
	push	eax
	push	_514
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_501
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_504
	call	brl_blitz_NullObjectError
_504:
	mov	edi,dword [ebx+8]
	mov	eax,edi
	add	eax,24
	mov	esi,eax
	mov	eax,esi
	add	eax,dword [edi+16]
	mov	dword [ebp-16],eax
	jmp	_21
_23:
	mov	eax,dword [esi]
	mov	dword [ebp-12],eax
	add	esi,4
	cmp	dword [ebp-12],bbNullObject
	je	_21
	mov	eax,ebp
	push	eax
	push	_512
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_509
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	ebx,dword [eax]
	cmp	ebx,bbNullObject
	jne	_511
	call	brl_blitz_NullObjectError
_511:
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_21:
	cmp	esi,dword [ebp-16]
	jne	_23
_22:
	mov	ebx,0
	jmp	_120
_120:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_GetStepSize:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_520
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_517
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_519
	call	brl_blitz_NullObjectError
_519:
	mov	ebx,dword [ebx+16]
	jmp	_123
_123:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_SetStepSize:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_529
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_521
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],1
	jge	_522
	push	ebp
	push	_524
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_523
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],1
	call	dword [bbOnDebugLeaveScope]
_522:
	push	_525
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_527
	call	brl_blitz_NullObjectError
_527:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+16],eax
	mov	ebx,0
	jmp	_127
_127:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Sort:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_530
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	mov	ebx,0
	jmp	_130
_130:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Free:
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
	push	_531
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	dword [bb_TObjectList+120]
	add	esp,4
	mov	ebx,0
	jmp	_133
_133:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_SwapByIndex:
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
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	dword [ebp-16],bbNullObject
	mov	eax,ebp
	push	eax
	push	_575
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_533
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	cmp	eax,0
	setl	al
	movzx	eax,al
	cmp	eax,0
	jne	_536
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_535
	call	brl_blitz_NullObjectError
_535:
	mov	edx,dword [ebp-8]
	mov	eax,dword [ebx+12]
	sub	eax,1
	cmp	edx,eax
	setg	al
	movzx	eax,al
_536:
	cmp	eax,0
	jne	_538
	mov	eax,dword [ebp-12]
	cmp	eax,0
	setl	al
	movzx	eax,al
_538:
	cmp	eax,0
	jne	_542
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_541
	call	brl_blitz_NullObjectError
_541:
	mov	edx,dword [ebp-12]
	mov	eax,dword [ebx+12]
	sub	eax,1
	cmp	edx,eax
	setg	al
	movzx	eax,al
_542:
	cmp	eax,0
	je	_544
	mov	eax,ebp
	push	eax
	push	_546
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_545
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_138
_544:
	push	_547
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_549
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_551
	call	brl_blitz_NullObjectError
_551:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+20]
	jb	_554
	call	brl_blitz_ArrayBoundsError
_554:
	mov	eax,dword [esi+ebx*4+24]
	mov	dword [ebp-16],eax
	push	_555
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_557
	call	brl_blitz_NullObjectError
_557:
	mov	ebx,dword [ebx+8]
	mov	esi,dword [ebp-8]
	cmp	esi,dword [ebx+20]
	jb	_560
	call	brl_blitz_ArrayBoundsError
_560:
	shl	esi,2
	add	ebx,esi
	mov	edi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_563
	call	brl_blitz_NullObjectError
_563:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_566
	call	brl_blitz_ArrayBoundsError
_566:
	mov	eax,dword [esi+ebx*4+24]
	mov	dword [edi+24],eax
	push	_567
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_569
	call	brl_blitz_NullObjectError
_569:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_572
	call	brl_blitz_ArrayBoundsError
_572:
	shl	ebx,2
	add	esi,ebx
	mov	eax,dword [ebp-16]
	mov	dword [esi+24],eax
	push	_574
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_138
_138:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_SwapByVal:
	push	ebp
	mov	ebp,esp
	sub	esp,24
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
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	mov	eax,ebp
	push	eax
	push	_628
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_579
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	cmp	eax,bbNullObject
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_580
	mov	eax,dword [ebp-12]
	cmp	eax,bbNullObject
	sete	al
	movzx	eax,al
_580:
	cmp	eax,0
	je	_582
	mov	eax,ebp
	push	eax
	push	_584
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_583
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_143
_582:
	push	_585
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_587
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	push	_590
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_592
	call	brl_blitz_NullObjectError
_592:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-20],eax
	push	_593
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_595
	call	brl_blitz_NullObjectError
_595:
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-24],eax
	push	_596
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-20]
	cmp	eax,-1
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_597
	mov	eax,dword [ebp-24]
	cmp	eax,-1
	setg	al
	movzx	eax,al
_597:
	cmp	eax,0
	je	_599
	mov	eax,ebp
	push	eax
	push	_626
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_600
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_602
	call	brl_blitz_NullObjectError
_602:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-20]
	cmp	ebx,dword [esi+20]
	jb	_605
	call	brl_blitz_ArrayBoundsError
_605:
	mov	eax,dword [esi+ebx*4+24]
	mov	dword [ebp-16],eax
	push	_606
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_608
	call	brl_blitz_NullObjectError
_608:
	mov	ebx,dword [ebx+8]
	mov	esi,dword [ebp-20]
	cmp	esi,dword [ebx+20]
	jb	_611
	call	brl_blitz_ArrayBoundsError
_611:
	shl	esi,2
	add	ebx,esi
	mov	edi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_614
	call	brl_blitz_NullObjectError
_614:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-24]
	cmp	ebx,dword [esi+20]
	jb	_617
	call	brl_blitz_ArrayBoundsError
_617:
	mov	eax,dword [esi+ebx*4+24]
	mov	dword [edi+24],eax
	push	_618
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_620
	call	brl_blitz_NullObjectError
_620:
	mov	esi,dword [ebx+8]
	mov	ebx,dword [ebp-24]
	cmp	ebx,dword [esi+20]
	jb	_623
	call	brl_blitz_ArrayBoundsError
_623:
	shl	ebx,2
	add	esi,ebx
	mov	eax,dword [ebp-16]
	mov	dword [esi+24],eax
	push	_625
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	jmp	_143
_599:
	push	_627
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_143
_143:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Destroy:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_636
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_631
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_633
	call	brl_blitz_NullObjectError
_633:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,4
	push	_634
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],bbNullObject
	push	_635
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	bbGCCollect
	mov	ebx,0
	jmp	_146
_146:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_644
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_637
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TObjectList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	push	_639
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_641
	call	brl_blitz_NullObjectError
_641:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+16],eax
	push	_643
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_149
_149:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_153:
	dd	0
_152:
	db	"basefunctions_lists",0
	align	4
_151:
	dd	1
	dd	_152
	dd	0
_25:
	db	"TObjectList",0
_26:
	db	"Items",0
_27:
	db	"[]:Object",0
_28:
	db	"_Size",0
_29:
	db	"i",0
_30:
	db	"StepSize",0
_31:
	db	"New",0
_32:
	db	"()i",0
_33:
	db	"AddFirst",0
_34:
	db	"(:Object)i",0
_35:
	db	"AddLast",0
_36:
	db	"ToDelimString",0
_37:
	db	"($)$",0
_38:
	db	"ToString",0
_39:
	db	"()$",0
_40:
	db	"Count",0
_41:
	db	"Contains",0
_42:
	db	"FromObjectArray",0
_43:
	db	"([]:Object):TObjectList",0
_44:
	db	"Insert",0
_45:
	db	"(:Object,i,i)i",0
_46:
	db	"RemoveByIndex",0
_47:
	db	"(i)i",0
_48:
	db	"RemoveByObject",0
_49:
	db	"(:Object,i)i",0
_50:
	db	"Clear",0
_51:
	db	"ToArray",0
_52:
	db	"()[]:Object",0
_53:
	db	"ToList",0
_54:
	db	"(*:brl.linkedlist.TList)i",0
_55:
	db	"GetStepSize",0
_56:
	db	"SetStepSize",0
_57:
	db	"Sort",0
_58:
	db	"Free",0
_59:
	db	"SwapByIndex",0
_60:
	db	"(i,i)i",0
_61:
	db	"SwapByVal",0
_62:
	db	"(:Object,:Object)i",0
_63:
	db	"Destroy",0
_64:
	db	"(:TObjectList)i",0
_65:
	db	"Create",0
_66:
	db	"(i):TObjectList",0
	align	4
_24:
	dd	2
	dd	_25
	dd	3
	dd	_26
	dd	_27
	dd	8
	dd	3
	dd	_28
	dd	_29
	dd	12
	dd	3
	dd	_30
	dd	_29
	dd	16
	dd	6
	dd	_31
	dd	_32
	dd	16
	dd	6
	dd	_33
	dd	_34
	dd	48
	dd	6
	dd	_35
	dd	_34
	dd	52
	dd	6
	dd	_36
	dd	_37
	dd	56
	dd	6
	dd	_38
	dd	_39
	dd	24
	dd	6
	dd	_40
	dd	_32
	dd	60
	dd	6
	dd	_41
	dd	_34
	dd	64
	dd	7
	dd	_42
	dd	_43
	dd	68
	dd	6
	dd	_44
	dd	_45
	dd	72
	dd	6
	dd	_46
	dd	_47
	dd	76
	dd	6
	dd	_48
	dd	_49
	dd	80
	dd	6
	dd	_50
	dd	_32
	dd	84
	dd	6
	dd	_51
	dd	_52
	dd	88
	dd	6
	dd	_53
	dd	_54
	dd	92
	dd	6
	dd	_55
	dd	_32
	dd	96
	dd	6
	dd	_56
	dd	_47
	dd	100
	dd	6
	dd	_57
	dd	_32
	dd	104
	dd	6
	dd	_58
	dd	_32
	dd	108
	dd	6
	dd	_59
	dd	_60
	dd	112
	dd	6
	dd	_61
	dd	_62
	dd	116
	dd	7
	dd	_63
	dd	_64
	dd	120
	dd	7
	dd	_65
	dd	_66
	dd	124
	dd	0
	align	4
bb_TObjectList:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_24
	dd	20
	dd	_bb_TObjectList_New
	dd	bbObjectDtor
	dd	_bb_TObjectList_ToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TObjectList_AddFirst
	dd	_bb_TObjectList_AddLast
	dd	_bb_TObjectList_ToDelimString
	dd	_bb_TObjectList_Count
	dd	_bb_TObjectList_Contains
	dd	_bb_TObjectList_FromObjectArray
	dd	_bb_TObjectList_Insert
	dd	_bb_TObjectList_RemoveByIndex
	dd	_bb_TObjectList_RemoveByObject
	dd	_bb_TObjectList_Clear
	dd	_bb_TObjectList_ToArray
	dd	_bb_TObjectList_ToList
	dd	_bb_TObjectList_GetStepSize
	dd	_bb_TObjectList_SetStepSize
	dd	_bb_TObjectList_Sort
	dd	_bb_TObjectList_Free
	dd	_bb_TObjectList_SwapByIndex
	dd	_bb_TObjectList_SwapByVal
	dd	_bb_TObjectList_Destroy
	dd	_bb_TObjectList_Create
_157:
	db	"Self",0
_158:
	db	":TObjectList",0
	align	4
_156:
	dd	1
	dd	_31
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	0
	align	4
_155:
	dd	3
	dd	0
	dd	0
_210:
	db	"val",0
_182:
	db	":Object",0
	align	4
_209:
	dd	1
	dd	_33
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_210
	dd	_182
	dd	-8
	dd	2
	dd	_29
	dd	_29
	dd	-12
	dd	0
_160:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_lists.bmx",0
	align	4
_159:
	dd	_160
	dd	22
	dd	3
	align	4
_162:
	dd	_160
	dd	26
	dd	3
	align	4
_166:
	dd	_160
	dd	28
	dd	3
	align	4
_183:
	dd	3
	dd	0
	dd	0
	align	4
_172:
	dd	_160
	dd	28
	dd	32
	align	4
_184:
	dd	_160
	dd	32
	dd	3
	align	4
_201:
	dd	3
	dd	0
	dd	0
	align	4
_189:
	dd	_160
	dd	33
	dd	4
	align	4
_202:
	dd	_160
	dd	36
	dd	3
	align	4
_244:
	dd	1
	dd	_35
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_210
	dd	_182
	dd	-8
	dd	0
	align	4
_211:
	dd	_160
	dd	44
	dd	3
	align	4
_215:
	dd	_160
	dd	46
	dd	3
	align	4
_231:
	dd	3
	dd	0
	dd	0
	align	4
_221:
	dd	_160
	dd	46
	dd	32
	align	4
_232:
	dd	_160
	dd	51
	dd	3
	align	4
_241:
	dd	_160
	dd	53
	dd	3
_275:
	db	"Delim",0
_276:
	db	"$",0
_277:
	db	"result",0
	align	4
_274:
	dd	1
	dd	_36
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_275
	dd	_276
	dd	-8
	dd	2
	dd	_277
	dd	_276
	dd	-12
	dd	2
	dd	_29
	dd	_29
	dd	-16
	dd	0
	align	4
_245:
	dd	_160
	dd	60
	dd	3
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_247:
	dd	_160
	dd	61
	dd	3
	align	4
_249:
	dd	_160
	dd	63
	dd	3
	align	4
_262:
	dd	3
	dd	0
	dd	0
	align	4
_254:
	dd	_160
	dd	64
	dd	4
	align	4
_263:
	dd	_160
	dd	66
	dd	3
	align	4
_273:
	dd	_160
	dd	68
	dd	3
	align	4
_281:
	dd	1
	dd	_38
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	0
	align	4
_278:
	dd	_160
	dd	73
	dd	3
	align	4
_285:
	dd	1
	dd	_40
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	0
	align	4
_282:
	dd	_160
	dd	79
	dd	3
	align	4
_304:
	dd	1
	dd	_41
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_210
	dd	_182
	dd	-8
	dd	2
	dd	_29
	dd	_29
	dd	-12
	dd	0
	align	4
_286:
	dd	_160
	dd	85
	dd	3
	align	4
_288:
	dd	_160
	dd	87
	dd	3
	align	4
_302:
	dd	3
	dd	0
	dd	0
	align	4
_293:
	dd	_160
	dd	88
	dd	4
	align	4
_301:
	dd	3
	dd	0
	dd	0
	align	4
_300:
	dd	_160
	dd	88
	dd	27
	align	4
_303:
	dd	_160
	dd	91
	dd	3
_323:
	db	"tempList",0
	align	4
_322:
	dd	1
	dd	_42
	dd	2
	dd	_210
	dd	_27
	dd	-4
	dd	2
	dd	_323
	dd	_158
	dd	-8
	dd	0
	align	4
_305:
	dd	_160
	dd	96
	dd	3
	align	4
_307:
	dd	_160
	dd	98
	dd	3
	align	4
_315:
	dd	3
	dd	0
	dd	0
	align	4
_311:
	dd	_160
	dd	99
	dd	4
	align	4
_320:
	dd	3
	dd	0
	dd	0
	align	4
_318:
	dd	_160
	dd	101
	dd	4
	align	4
_11:
	dd	bbStringClass
	dd	2147483647
	dd	64
	dw	69,114,114,111,114,32,119,104,101,110,32,99,111,110,118,101
	dw	114,116,105,110,103,32,102,114,111,109,32,79,98,106,101,99
	dw	116,32,65,114,114,97,121,32,116,111,32,84,79,98,106,101
	dw	99,116,76,105,115,116,44,32,101,114,114,111,114,58,32,10
	align	4
_319:
	dd	_160
	dd	102
	dd	4
	align	4
_321:
	dd	_160
	dd	105
	dd	3
_402:
	db	"index",0
_403:
	db	"AutoAddToEnd",0
	align	4
_401:
	dd	1
	dd	_44
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_210
	dd	_182
	dd	-8
	dd	2
	dd	_402
	dd	_29
	dd	-12
	dd	2
	dd	_403
	dd	_29
	dd	-16
	dd	2
	dd	_29
	dd	_29
	dd	-20
	dd	0
	align	4
_324:
	dd	_160
	dd	134
	dd	3
	align	4
_326:
	dd	_160
	dd	137
	dd	3
	align	4
_329:
	dd	3
	dd	0
	dd	0
	align	4
_328:
	dd	_160
	dd	137
	dd	21
	align	4
_330:
	dd	_160
	dd	138
	dd	3
	align	4
_344:
	dd	3
	dd	0
	dd	0
	align	4
_334:
	dd	_160
	dd	139
	dd	4
	align	4
_337:
	dd	3
	dd	0
	dd	0
	align	4
_336:
	dd	_160
	dd	140
	dd	5
	align	4
_343:
	dd	3
	dd	0
	dd	0
	align	4
_339:
	dd	_160
	dd	142
	dd	5
	align	4
_342:
	dd	_160
	dd	143
	dd	5
	align	4
_345:
	dd	_160
	dd	148
	dd	3
	align	4
_353:
	dd	3
	dd	0
	dd	0
	align	4
_349:
	dd	_160
	dd	149
	dd	4
	align	4
_352:
	dd	_160
	dd	150
	dd	4
	align	4
_354:
	dd	_160
	dd	155
	dd	3
	align	4
_358:
	dd	_160
	dd	157
	dd	3
	align	4
_374:
	dd	3
	dd	0
	dd	0
	align	4
_364:
	dd	_160
	dd	157
	dd	32
	align	4
_375:
	dd	_160
	dd	161
	dd	3
	align	4
_392:
	dd	3
	dd	0
	dd	0
	align	4
_380:
	dd	_160
	dd	162
	dd	4
	align	4
_393:
	dd	_160
	dd	167
	dd	3
	align	4
_400:
	dd	_160
	dd	168
	dd	3
	align	4
_463:
	dd	1
	dd	_46
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_402
	dd	_29
	dd	-8
	dd	2
	dd	_29
	dd	_29
	dd	-12
	dd	0
	align	4
_404:
	dd	_160
	dd	173
	dd	3
	align	4
_406:
	dd	_160
	dd	176
	dd	3
	align	4
_423:
	dd	3
	dd	0
	dd	0
	align	4
_411:
	dd	_160
	dd	177
	dd	4
	align	4
_424:
	dd	_160
	dd	182
	dd	3
	align	4
_428:
	dd	_160
	dd	185
	dd	3
	align	4
_444:
	dd	3
	dd	0
	dd	0
	align	4
_436:
	dd	_160
	dd	185
	dd	49
	align	4
_445:
	dd	_160
	dd	186
	dd	3
	align	4
_453:
	dd	3
	dd	0
	dd	0
	align	4
_449:
	dd	_160
	dd	186
	dd	21
	align	4
_454:
	dd	_160
	dd	188
	dd	3
_483:
	db	"RemoveAll",0
	align	4
_482:
	dd	1
	dd	_48
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_210
	dd	_182
	dd	-8
	dd	2
	dd	_483
	dd	_29
	dd	-12
	dd	2
	dd	_29
	dd	_29
	dd	-16
	dd	0
	align	4
_464:
	dd	_160
	dd	193
	dd	3
	align	4
_466:
	dd	_160
	dd	195
	dd	3
	align	4
_469:
	dd	_160
	dd	196
	dd	3
	align	4
_480:
	dd	3
	dd	0
	dd	0
	align	4
_470:
	dd	_160
	dd	198
	dd	4
	align	4
_473:
	dd	_160
	dd	199
	dd	4
	align	4
_476:
	dd	3
	dd	0
	dd	0
	align	4
_475:
	dd	_160
	dd	199
	dd	26
	align	4
_477:
	dd	_160
	dd	200
	dd	4
	align	4
_481:
	dd	_160
	dd	204
	dd	3
	align	4
_494:
	dd	1
	dd	_50
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	0
	align	4
_484:
	dd	_160
	dd	209
	dd	3
	align	4
_490:
	dd	_160
	dd	210
	dd	3
	align	4
_500:
	dd	1
	dd	_51
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	0
	align	4
_495:
	dd	_160
	dd	215
	dd	3
_515:
	db	"List",0
_516:
	db	":brl.linkedlist.TList",0
	align	4
_514:
	dd	1
	dd	_53
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	5
	dd	_515
	dd	_516
	dd	-8
	dd	0
	align	4
_501:
	dd	_160
	dd	220
	dd	3
_513:
	db	"s",0
	align	4
_512:
	dd	3
	dd	0
	dd	2
	dd	_513
	dd	_182
	dd	-12
	dd	0
	align	4
_509:
	dd	_160
	dd	221
	dd	4
	align	4
_520:
	dd	1
	dd	_55
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	0
	align	4
_517:
	dd	_160
	dd	227
	dd	3
	align	4
_529:
	dd	1
	dd	_56
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_210
	dd	_29
	dd	-8
	dd	0
	align	4
_521:
	dd	_160
	dd	231
	dd	3
	align	4
_524:
	dd	3
	dd	0
	dd	0
	align	4
_523:
	dd	_160
	dd	231
	dd	19
	align	4
_525:
	dd	_160
	dd	232
	dd	3
	align	4
_530:
	dd	1
	dd	_57
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	0
	align	4
_532:
	dd	1
	dd	_58
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	0
	align	4
_531:
	dd	_160
	dd	242
	dd	3
_576:
	db	"FirstIndex",0
_577:
	db	"SecondIndex",0
_578:
	db	"tempObject",0
	align	4
_575:
	dd	1
	dd	_59
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_576
	dd	_29
	dd	-8
	dd	2
	dd	_577
	dd	_29
	dd	-12
	dd	2
	dd	_578
	dd	_182
	dd	-16
	dd	0
	align	4
_533:
	dd	_160
	dd	247
	dd	3
	align	4
_546:
	dd	3
	dd	0
	dd	0
	align	4
_545:
	dd	_160
	dd	247
	dd	90
	align	4
_547:
	dd	_160
	dd	248
	dd	3
	align	4
_549:
	dd	_160
	dd	250
	dd	3
	align	4
_555:
	dd	_160
	dd	251
	dd	3
	align	4
_567:
	dd	_160
	dd	252
	dd	3
	align	4
_574:
	dd	_160
	dd	253
	dd	3
_629:
	db	"FirstObject",0
_630:
	db	"SecondObject",0
	align	4
_628:
	dd	1
	dd	_61
	dd	2
	dd	_157
	dd	_158
	dd	-4
	dd	2
	dd	_629
	dd	_182
	dd	-8
	dd	2
	dd	_630
	dd	_182
	dd	-12
	dd	2
	dd	_578
	dd	_182
	dd	-16
	dd	2
	dd	_576
	dd	_29
	dd	-20
	dd	2
	dd	_577
	dd	_29
	dd	-24
	dd	0
	align	4
_579:
	dd	_160
	dd	259
	dd	3
	align	4
_584:
	dd	3
	dd	0
	dd	0
	align	4
_583:
	dd	_160
	dd	259
	dd	51
	align	4
_585:
	dd	_160
	dd	260
	dd	3
	align	4
_587:
	dd	_160
	dd	261
	dd	3
	align	4
_590:
	dd	_160
	dd	263
	dd	3
	align	4
_593:
	dd	_160
	dd	264
	dd	3
	align	4
_596:
	dd	_160
	dd	266
	dd	3
	align	4
_626:
	dd	3
	dd	0
	dd	0
	align	4
_600:
	dd	_160
	dd	267
	dd	4
	align	4
_606:
	dd	_160
	dd	268
	dd	4
	align	4
_618:
	dd	_160
	dd	269
	dd	4
	align	4
_625:
	dd	_160
	dd	270
	dd	4
	align	4
_627:
	dd	_160
	dd	273
	dd	3
	align	4
_636:
	dd	1
	dd	_63
	dd	2
	dd	_515
	dd	_158
	dd	-4
	dd	0
	align	4
_631:
	dd	_160
	dd	278
	dd	3
	align	4
_634:
	dd	_160
	dd	279
	dd	3
	align	4
_635:
	dd	_160
	dd	280
	dd	3
	align	4
_644:
	dd	1
	dd	_65
	dd	2
	dd	_30
	dd	_29
	dd	-4
	dd	2
	dd	_323
	dd	_158
	dd	-8
	dd	0
	align	4
_637:
	dd	_160
	dd	285
	dd	3
	align	4
_639:
	dd	_160
	dd	286
	dd	3
	align	4
_643:
	dd	_160
	dd	287
	dd	3
