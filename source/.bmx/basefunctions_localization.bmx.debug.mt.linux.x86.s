	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_map_map
	extrn	__bb_retro_retro
	extrn	bbEmptyArray
	extrn	bbEmptyString
	extrn	bbExThrow
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
	extrn	bbStringTrim
	extrn	brl_blitz_NullMethodError
	extrn	brl_blitz_NullObjectError
	extrn	brl_filesystem_ExtractDir
	extrn	brl_filesystem_LoadDir
	extrn	brl_filesystem_ReadFile
	extrn	brl_linkedlist_TList
	extrn	brl_map_TMap
	extrn	brl_retro_Instr
	extrn	brl_retro_Left
	extrn	brl_retro_Mid
	extrn	brl_retro_Right
	extrn	brl_stream_Eof
	extrn	brl_stream_ReadLine
	public	__bb_source_basefunctions_localization
	public	_bb_LocalizationMemoryResource_Close
	public	_bb_LocalizationMemoryResource_Delete
	public	_bb_LocalizationMemoryResource_GetString
	public	_bb_LocalizationMemoryResource_New
	public	_bb_LocalizationMemoryResource_open
	public	_bb_LocalizationResource_New
	public	_bb_LocalizationStreamingResource_Close
	public	_bb_LocalizationStreamingResource_Delete
	public	_bb_LocalizationStreamingResource_GetString
	public	_bb_LocalizationStreamingResource_New
	public	_bb_LocalizationStreamingResource_open
	public	_bb_Localization_AddLanguages
	public	_bb_Localization_Dispose
	public	_bb_Localization_GetLanguageFromFilename
	public	_bb_Localization_GetResourceFiles
	public	_bb_Localization_GetString
	public	_bb_Localization_Language
	public	_bb_Localization_LoadResource
	public	_bb_Localization_LoadResources
	public	_bb_Localization_New
	public	_bb_Localization_OpenResource
	public	_bb_Localization_OpenResources
	public	_bb_Localization_Resources
	public	_bb_Localization_SetLanguage
	public	_bb_Localization_currentLanguage
	public	_bb_Localization_supportedLanguages
	public	bb_Localization
	public	bb_LocalizationMemoryResource
	public	bb_LocalizationResource
	public	bb_LocalizationStreamingResource
	section	"code" executable
__bb_source_basefunctions_localization:
	push	ebp
	mov	ebp,esp
	push	ebx
	cmp	dword [_169],0
	je	_170
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_170:
	mov	dword [_169],1
	push	ebp
	push	_167
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	__bb_blitz_blitz
	call	__bb_retro_retro
	call	__bb_map_map
	call	__bb_glmax2d_glmax2d
	push	_161
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_163
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_164
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_Localization
	call	bbObjectRegisterType
	add	esp,4
	push	bb_LocalizationResource
	call	bbObjectRegisterType
	add	esp,4
	push	bb_LocalizationStreamingResource
	call	bbObjectRegisterType
	add	esp,4
	push	bb_LocalizationMemoryResource
	call	bbObjectRegisterType
	add	esp,4
	push	_165
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [_bb_Localization_Resources],eax
	push	_166
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [_bb_Localization_supportedLanguages],eax
	mov	ebx,0
	jmp	_85
_85:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_172
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_Localization
	push	ebp
	push	_171
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_88
_88:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_SetLanguage:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbEmptyString
	push	ebp
	push	_193
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_175
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbEmptyString
	mov	esi,dword [_bb_Localization_supportedLanguages]
	cmp	esi,bbNullObject
	jne	_179
	call	brl_blitz_NullObjectError
_179:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_3
_5:
	cmp	ebx,bbNullObject
	jne	_184
	call	brl_blitz_NullObjectError
_184:
	push	bbStringClass
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-8],eax
	cmp	dword [ebp-8],bbNullObject
	je	_3
	push	ebp
	push	_190
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_185
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	push	dword [ebp-4]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_186
	push	ebp
	push	_189
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_187
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [_bb_Localization_currentLanguage],eax
	push	_188
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_91
_186:
	call	dword [bbOnDebugLeaveScope]
_3:
	cmp	ebx,bbNullObject
	jne	_182
	call	brl_blitz_NullObjectError
_182:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_5
_4:
	push	_192
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_91
_91:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_Language:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	ebp
	push	_195
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_194
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_Localization_currentLanguage]
	jmp	_93
_93:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_AddLanguages:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	push	ebp
	push	_215
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_196
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	_6
	push	dword [ebp-4]
	call	brl_retro_Instr
	add	esp,12
	mov	dword [ebp-8],eax
	push	_198
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],0
	jne	_199
	push	ebp
	push	_204
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_200
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_Localization_supportedLanguages]
	cmp	ebx,bbNullObject
	jne	_202
	call	brl_blitz_NullObjectError
_202:
	push	dword [ebp-4]
	call	bbStringTrim
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	push	_203
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_96
_199:
	push	_205
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_7
_9:
	push	ebp
	push	_211
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_206
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_Localization_supportedLanguages]
	cmp	ebx,bbNullObject
	jne	_208
	call	brl_blitz_NullObjectError
_208:
	mov	eax,dword [ebp-8]
	sub	eax,1
	push	eax
	push	dword [ebp-4]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringTrim
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	push	_209
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	mov	eax,dword [ebp-8]
	add	eax,1
	push	eax
	push	dword [ebp-4]
	call	brl_retro_Mid
	add	esp,12
	mov	dword [ebp-4],eax
	push	_210
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	_6
	push	dword [ebp-4]
	call	brl_retro_Instr
	add	esp,12
	mov	dword [ebp-8],eax
	call	dword [bbOnDebugLeaveScope]
_7:
	cmp	dword [ebp-8],0
	jg	_9
_8:
	push	_212
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_Localization_supportedLanguages]
	cmp	ebx,bbNullObject
	jne	_214
	call	brl_blitz_NullObjectError
_214:
	push	dword [ebp-4]
	call	bbStringTrim
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	mov	ebx,0
	jmp	_96
_96:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_OpenResource:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_220
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_219
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-4]
	call	dword [bb_LocalizationStreamingResource+56]
	add	esp,8
	mov	ebx,0
	jmp	_99
_99:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_LoadResource:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_223
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_222
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-4]
	call	dword [bb_LocalizationMemoryResource+56]
	add	esp,8
	mov	ebx,0
	jmp	_102
_102:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_OpenResources:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbEmptyString
	push	ebp
	push	_237
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_224
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbEmptyString
	push	dword [ebp-4]
	call	dword [bb_Localization+84]
	add	esp,4
	mov	esi,eax
	cmp	esi,bbNullObject
	jne	_228
	call	brl_blitz_NullObjectError
_228:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_10
_12:
	cmp	ebx,bbNullObject
	jne	_233
	call	brl_blitz_NullObjectError
_233:
	push	bbStringClass
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-8],eax
	cmp	dword [ebp-8],bbNullObject
	je	_10
	push	ebp
	push	_235
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_234
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	dword [bb_Localization+60]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_10:
	cmp	ebx,bbNullObject
	jne	_231
	call	brl_blitz_NullObjectError
_231:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_12
_11:
	mov	ebx,0
	jmp	_105
_105:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_LoadResources:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbEmptyString
	push	ebp
	push	_251
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_239
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbEmptyString
	push	dword [ebp-4]
	call	dword [bb_Localization+84]
	add	esp,4
	mov	esi,eax
	cmp	esi,bbNullObject
	jne	_243
	call	brl_blitz_NullObjectError
_243:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_13
_15:
	cmp	ebx,bbNullObject
	jne	_248
	call	brl_blitz_NullObjectError
_248:
	push	bbStringClass
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-8],eax
	cmp	dword [ebp-8],bbNullObject
	je	_13
	push	ebp
	push	_250
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_249
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	dword [bb_Localization+64]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_13:
	cmp	ebx,bbNullObject
	jne	_246
	call	brl_blitz_NullObjectError
_246:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_15
_14:
	mov	ebx,0
	jmp	_108
_108:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_GetString:
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
	mov	dword [ebp-16],bbNullObject
	mov	eax,ebp
	push	eax
	push	_281
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_252
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],_1
	push	_254
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	mov	edi,dword [_bb_Localization_Resources]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_258
	call	brl_blitz_NullObjectError
_258:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_16
_18:
	cmp	ebx,bbNullObject
	jne	_263
	call	brl_blitz_NullObjectError
_263:
	push	bb_LocalizationResource
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-16],eax
	cmp	dword [ebp-16],bbNullObject
	je	_16
	mov	eax,ebp
	push	eax
	push	_277
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_264
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_266
	call	brl_blitz_NullObjectError
_266:
	push	dword [_bb_Localization_currentLanguage]
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_267
	mov	eax,ebp
	push	eax
	push	_269
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_268
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_16
_267:
	push	_270
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_272
	call	brl_blitz_NullObjectError
_272:
	push	dword [ebp-8]
	push	dword [ebp-4]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+48]
	add	esp,12
	mov	dword [ebp-12],eax
	push	_273
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_274
	mov	eax,ebp
	push	eax
	push	_276
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_275
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_112
_274:
	call	dword [bbOnDebugLeaveScope]
_16:
	cmp	ebx,bbNullObject
	jne	_261
	call	brl_blitz_NullObjectError
_261:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_18
_17:
	push	_280
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_112
_112:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_GetLanguageFromFilename:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	push	ebp
	push	_308
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_285
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	push	_287
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	_19
	push	dword [ebp-4]
	call	brl_retro_Instr
	add	esp,12
	mov	dword [ebp-12],eax
	push	_289
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_20
_22:
	push	ebp
	push	_292
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_290
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	mov	dword [ebp-8],eax
	push	_291
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	add	eax,1
	push	eax
	push	_19
	push	dword [ebp-4]
	call	brl_retro_Instr
	add	esp,12
	mov	dword [ebp-12],eax
	call	dword [bbOnDebugLeaveScope]
_20:
	cmp	dword [ebp-12],0
	jg	_22
_21:
	push	_293
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],0
	jle	_294
	push	ebp
	push	_306
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_295
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	add	eax,1
	push	eax
	push	_19
	push	dword [ebp-4]
	call	brl_retro_Instr
	add	esp,12
	mov	dword [ebp-12],eax
	push	_296
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	jle	_297
	push	ebp
	push	_299
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_298
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	sub	eax,dword [ebp-8]
	sub	eax,1
	push	eax
	mov	eax,dword [ebp-8]
	add	eax,1
	push	eax
	push	dword [ebp-4]
	call	brl_retro_Mid
	add	esp,12
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_115
_297:
	push	_300
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	add	eax,1
	push	eax
	push	_23
	push	dword [ebp-4]
	call	brl_retro_Instr
	add	esp,12
	mov	dword [ebp-12],eax
	push	_301
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	jle	_302
	push	ebp
	push	_304
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_303
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	sub	eax,dword [ebp-8]
	sub	eax,1
	push	eax
	mov	eax,dword [ebp-8]
	add	eax,1
	push	eax
	push	dword [ebp-4]
	call	brl_retro_Mid
	add	esp,12
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_115
_302:
	push	_305
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	mov	eax,dword [ebp-8]
	add	eax,1
	push	eax
	push	dword [ebp-4]
	call	brl_retro_Mid
	add	esp,12
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_115
_294:
	push	_307
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbEmptyString
	jmp	_115
_115:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_GetResourceFiles:
	push	ebp
	mov	ebp,esp
	sub	esp,36
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbEmptyString
	mov	dword [ebp-20],bbEmptyString
	mov	dword [ebp-24],bbEmptyString
	mov	dword [ebp-28],bbEmptyArray
	mov	dword [ebp-32],bbEmptyString
	mov	eax,ebp
	push	eax
	push	_358
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_310
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	push	_312
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	_24
	push	dword [ebp-4]
	call	brl_retro_Instr
	add	esp,12
	mov	dword [ebp-12],eax
	push	_314
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	jle	_315
	mov	eax,ebp
	push	eax
	push	_351
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_316
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	sub	eax,1
	push	eax
	push	dword [ebp-4]
	call	brl_retro_Left
	add	esp,8
	mov	dword [ebp-16],eax
	push	_318
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	mov	eax,dword [ebp-12]
	add	eax,1
	push	eax
	push	dword [ebp-4]
	call	brl_retro_Mid
	add	esp,12
	mov	dword [ebp-20],eax
	push	_320
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	brl_filesystem_ExtractDir
	add	esp,4
	mov	dword [ebp-24],eax
	push	_322
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	dword [ebp-24]
	call	brl_filesystem_LoadDir
	add	esp,8
	mov	dword [ebp-28],eax
	push	_324
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	mov	eax,dword [ebp-24]
	mov	eax,dword [eax+8]
	add	eax,1
	push	eax
	push	dword [ebp-16]
	call	brl_retro_Mid
	add	esp,12
	mov	dword [ebp-16],eax
	push	_325
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_25
	push	1
	push	dword [ebp-16]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_326
	push	_26
	push	1
	push	dword [ebp-16]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_326:
	cmp	eax,0
	je	_328
	mov	eax,ebp
	push	eax
	push	_330
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_329
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	push	2
	push	dword [ebp-16]
	call	brl_retro_Mid
	add	esp,12
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
_328:
	push	_331
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],bbEmptyString
	mov	edi,dword [ebp-28]
	mov	eax,edi
	add	eax,24
	mov	esi,eax
	mov	eax,esi
	add	eax,dword [edi+16]
	mov	dword [ebp-36],eax
	jmp	_27
_29:
	mov	eax,dword [esi]
	mov	dword [ebp-32],eax
	add	esi,4
	cmp	dword [ebp-32],bbNullObject
	je	_27
	mov	eax,ebp
	push	eax
	push	_350
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_337
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	mov	edx,dword [eax+8]
	mov	eax,dword [ebp-16]
	cmp	edx,dword [eax+8]
	setge	al
	movzx	eax,al
	cmp	eax,0
	je	_338
	push	dword [ebp-16]
	mov	eax,dword [ebp-16]
	push	dword [eax+8]
	push	dword [ebp-32]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_338:
	cmp	eax,0
	je	_340
	mov	eax,ebp
	push	eax
	push	_349
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_341
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	mov	eax,dword [eax+8]
	mov	edx,dword [ebp-16]
	mov	ecx,dword [edx+8]
	mov	edx,dword [ebp-20]
	add	ecx,dword [edx+8]
	cmp	eax,ecx
	setge	al
	movzx	eax,al
	cmp	eax,0
	je	_342
	push	dword [ebp-20]
	mov	eax,dword [ebp-20]
	push	dword [eax+8]
	push	dword [ebp-32]
	call	brl_retro_Right
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_342:
	cmp	eax,0
	je	_344
	mov	eax,ebp
	push	eax
	push	_348
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_345
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_347
	call	brl_blitz_NullObjectError
_347:
	push	dword [ebp-32]
	push	_25
	push	dword [ebp-24]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_344:
	call	dword [bbOnDebugLeaveScope]
_340:
	call	dword [bbOnDebugLeaveScope]
_27:
	cmp	esi,dword [ebp-36]
	jne	_29
_28:
	call	dword [bbOnDebugLeaveScope]
_315:
	push	_357
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
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
_bb_Localization_Dispose:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	dword [ebp-4],bbNullObject
	mov	eax,ebp
	push	eax
	push	_379
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_360
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],bbNullObject
	mov	edi,dword [_bb_Localization_Resources]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_364
	call	brl_blitz_NullObjectError
_364:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_30
_32:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_369
	call	brl_blitz_NullObjectError
_369:
	push	bb_LocalizationResource
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-4],eax
	cmp	dword [ebp-4],bbNullObject
	je	_30
	mov	eax,ebp
	push	eax
	push	_373
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_370
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_372
	call	brl_blitz_NullObjectError
_372:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_30:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_367
	call	brl_blitz_NullObjectError
_367:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_32
_31:
	push	_374
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_Localization_Resources]
	cmp	ebx,bbNullObject
	jne	_376
	call	brl_blitz_NullObjectError
_376:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	_377
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [_bb_Localization_Resources],bbNullObject
	push	_378
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [_bb_Localization_supportedLanguages],bbNullObject
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
_bb_LocalizationResource_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_381
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_LocalizationResource
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbEmptyString
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],bbNullObject
	push	ebp
	push	_380
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_123
_123:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationStreamingResource_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_383
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	_bb_LocalizationResource_New
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_LocalizationStreamingResource
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],bbNullObject
	push	ebp
	push	_382
	call	dword [bbOnDebugEnterScope]
	add	esp,8
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
_bb_LocalizationStreamingResource_open:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],bbNullObject
	push	ebp
	push	_415
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_385
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_386
	push	ebp
	push	_392
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_387
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	dword [bb_Localization+80]
	add	esp,4
	mov	dword [ebp-8],eax
	push	_388
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_389
	push	ebp
	push	_391
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_390
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_33
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_389:
	call	dword [bbOnDebugLeaveScope]
_386:
	push	_393
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	brl_filesystem_ReadFile
	add	esp,4
	mov	dword [ebp-12],eax
	push	_395
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],bbNullObject
	jne	_396
	push	ebp
	push	_398
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_397
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_35
	push	dword [ebp-4]
	push	_34
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_396:
	push	_399
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_LocalizationStreamingResource
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-16],eax
	push	_401
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_403
	call	brl_blitz_NullObjectError
_403:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+8],eax
	push	_405
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_407
	call	brl_blitz_NullObjectError
_407:
	mov	eax,dword [ebp-12]
	mov	dword [ebx+16],eax
	push	_409
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_411
	call	brl_blitz_NullObjectError
_411:
	mov	esi,dword [_bb_Localization_Resources]
	cmp	esi,bbNullObject
	jne	_414
	call	brl_blitz_NullObjectError
_414:
	push	dword [ebp-16]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+12],eax
	mov	ebx,bbNullObject
	jmp	_130
_130:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationStreamingResource_GetString:
	push	ebp
	mov	ebp,esp
	sub	esp,32
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	dword [ebp-16],bbEmptyString
	mov	dword [ebp-20],bbEmptyString
	mov	dword [ebp-24],bbEmptyString
	mov	dword [ebp-28],0
	mov	dword [ebp-32],0
	push	ebp
	push	_476
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_416
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_418
	call	brl_blitz_NullObjectError
_418:
	cmp	dword [ebx+16],bbNullObject
	jne	_419
	push	ebp
	push	_421
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_420
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbEmptyString
	call	dword [bbOnDebugLeaveScope]
	jmp	_135
_419:
	push	_422
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_424
	call	brl_blitz_NullObjectError
_424:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_426
	call	brl_blitz_NullObjectError
_426:
	push	0
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
	push	_427
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbEmptyString
	push	_429
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],bbEmptyString
	push	_431
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],bbEmptyString
	push	_433
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-28],0
	push	_435
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],0
	push	_437
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_36
_38:
	push	ebp
	push	_474
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_440
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_442
	call	brl_blitz_NullObjectError
_442:
	push	dword [ebx+16]
	call	brl_stream_ReadLine
	add	esp,4
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-16],eax
	push	_443
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_444
	push	ebp
	push	_463
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_445
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-28]
	cmp	eax,0
	je	_446
	push	_39
	push	1
	push	dword [ebp-16]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
_446:
	cmp	eax,0
	je	_448
	push	ebp
	push	_450
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_449
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_36
_448:
	push	_451
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_39
	push	1
	push	dword [ebp-16]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_452
	push	_40
	push	1
	push	dword [ebp-16]
	call	brl_retro_Right
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_452:
	cmp	eax,0
	je	_454
	push	ebp
	push	_462
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_455
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	mov	eax,dword [ebp-16]
	mov	eax,dword [eax+8]
	sub	eax,2
	push	eax
	push	2
	push	dword [ebp-16]
	call	brl_retro_Mid
	add	esp,12
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_456
	push	ebp
	push	_458
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_457
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-28],1
	call	dword [bbOnDebugLeaveScope]
	jmp	_459
_456:
	push	ebp
	push	_461
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_460
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-28],0
	call	dword [bbOnDebugLeaveScope]
_459:
	call	dword [bbOnDebugLeaveScope]
_454:
	call	dword [bbOnDebugLeaveScope]
_444:
	push	_464
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	_41
	push	dword [ebp-16]
	call	brl_retro_Instr
	add	esp,12
	mov	dword [ebp-32],eax
	push	_465
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-32],0
	jle	_466
	push	ebp
	push	_469
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_467
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	sub	eax,1
	push	eax
	push	dword [ebp-16]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-20],eax
	push	_468
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	mov	eax,dword [ebp-32]
	add	eax,1
	push	eax
	push	dword [ebp-16]
	call	brl_retro_Mid
	add	esp,12
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-24],eax
	call	dword [bbOnDebugLeaveScope]
_466:
	push	_470
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	push	dword [ebp-20]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_471
	push	ebp
	push	_473
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_472
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_135
_471:
	call	dword [bbOnDebugLeaveScope]
_36:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_439
	call	brl_blitz_NullObjectError
_439:
	push	dword [ebx+16]
	call	brl_stream_Eof
	add	esp,4
	cmp	eax,0
	je	_38
_37:
	push	_475
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbEmptyString
	jmp	_135
_135:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationStreamingResource_Close:
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
	push	_481
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_483
	call	brl_blitz_NullObjectError
_483:
	cmp	dword [ebx+12],bbNullObject
	je	_484
	push	ebp
	push	_490
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_485
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_487
	call	brl_blitz_NullObjectError
_487:
	mov	ebx,dword [ebx+12]
	cmp	ebx,bbNullObject
	jne	_489
	call	brl_blitz_NullObjectError
_489:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_484:
	push	_491
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_493
	call	brl_blitz_NullObjectError
_493:
	cmp	dword [ebx+16],bbNullObject
	je	_494
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
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_499
	call	brl_blitz_NullObjectError
_499:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_494:
	mov	ebx,0
	jmp	_138
_138:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationStreamingResource_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
_141:
	mov	eax,0
	jmp	_503
_503:
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_505
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	_bb_LocalizationResource_New
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_LocalizationMemoryResource
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],bbNullObject
	push	ebp
	push	_504
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_144
_144:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_open:
	push	ebp
	mov	ebp,esp
	sub	esp,36
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],bbEmptyString
	mov	dword [ebp-24],bbEmptyString
	mov	dword [ebp-28],bbEmptyString
	mov	dword [ebp-32],0
	mov	dword [ebp-36],bbEmptyString
	push	ebp
	push	_600
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_507
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_508
	push	ebp
	push	_514
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_509
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	dword [bb_Localization+80]
	add	esp,4
	mov	dword [ebp-8],eax
	push	_510
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_511
	push	ebp
	push	_513
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_512
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_33
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_511:
	call	dword [bbOnDebugLeaveScope]
_508:
	push	_515
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	brl_filesystem_ReadFile
	add	esp,4
	mov	dword [ebp-12],eax
	push	_517
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],bbNullObject
	jne	_518
	push	ebp
	push	_520
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_519
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_35
	push	dword [ebp-4]
	push	_34
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_518:
	push	_521
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_LocalizationMemoryResource
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-16],eax
	push	_523
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_525
	call	brl_blitz_NullObjectError
_525:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+8],eax
	push	_527
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_529
	call	brl_blitz_NullObjectError
_529:
	push	brl_map_TMap
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+16],eax
	push	_531
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_533
	call	brl_blitz_NullObjectError
_533:
	mov	esi,dword [_bb_Localization_Resources]
	cmp	esi,bbNullObject
	jne	_536
	call	brl_blitz_NullObjectError
_536:
	push	dword [ebp-16]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+12],eax
	push	_537
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],bbEmptyString
	push	_539
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],bbEmptyString
	push	_541
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-28],bbEmptyString
	push	_543
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],0
	push	_545
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-36],_1
	push	_547
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_42
_44:
	push	ebp
	push	_595
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_548
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	call	brl_stream_ReadLine
	add	esp,4
	mov	dword [ebp-20],eax
	push	_549
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_39
	push	1
	push	dword [ebp-20]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_550
	push	_40
	push	1
	push	dword [ebp-20]
	call	brl_retro_Right
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_550:
	cmp	eax,0
	je	_552
	push	ebp
	push	_554
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_553
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-20]
	mov	eax,dword [eax+8]
	sub	eax,2
	push	eax
	push	2
	push	dword [ebp-20]
	call	brl_retro_Mid
	add	esp,12
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-36],eax
	call	dword [bbOnDebugLeaveScope]
_552:
	push	_555
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	_41
	push	dword [ebp-20]
	call	brl_retro_Instr
	add	esp,12
	mov	dword [ebp-32],eax
	push	_556
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-32],0
	jle	_557
	push	ebp
	push	_560
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_558
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	sub	eax,1
	push	eax
	push	dword [ebp-20]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-24],eax
	push	_559
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	mov	eax,dword [ebp-32]
	add	eax,1
	push	eax
	push	dword [ebp-20]
	call	brl_retro_Mid
	add	esp,12
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-28],eax
	call	dword [bbOnDebugLeaveScope]
_557:
	push	_561
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-24]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_562
	push	_1
	push	dword [ebp-24]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
_562:
	cmp	eax,0
	je	_564
	push	ebp
	push	_594
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_565
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-36]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_566
	push	_1
	push	dword [ebp-36]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
_566:
	cmp	eax,0
	je	_568
	push	ebp
	push	_586
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_569
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_571
	call	brl_blitz_NullObjectError
_571:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_573
	call	brl_blitz_NullObjectError
_573:
	push	dword [ebp-28]
	push	dword [ebp-24]
	push	_45
	push	dword [ebp-36]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	push	_574
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_576
	call	brl_blitz_NullObjectError
_576:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_578
	call	brl_blitz_NullObjectError
_578:
	push	dword [ebp-24]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	cmp	eax,bbNullObject
	jne	_579
	push	ebp
	push	_585
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_580
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_582
	call	brl_blitz_NullObjectError
_582:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_584
	call	brl_blitz_NullObjectError
_584:
	push	dword [ebp-28]
	push	dword [ebp-24]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_579:
	call	dword [bbOnDebugLeaveScope]
	jmp	_587
_568:
	push	ebp
	push	_593
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_588
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_590
	call	brl_blitz_NullObjectError
_590:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_592
	call	brl_blitz_NullObjectError
_592:
	push	dword [ebp-28]
	push	dword [ebp-24]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_587:
	call	dword [bbOnDebugLeaveScope]
_564:
	call	dword [bbOnDebugLeaveScope]
_42:
	push	dword [ebp-12]
	call	brl_stream_Eof
	add	esp,4
	cmp	eax,0
	je	_44
_43:
	push	_596
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_598
	call	brl_blitz_NullObjectError
_598:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	_599
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	jmp	_148
_148:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_GetString:
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
	push	_625
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_601
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_603
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbEmptyString
	push	dword [ebp-12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_604
	push	ebp
	push	_610
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
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_609
	call	brl_blitz_NullObjectError
_609:
	push	dword [ebp-8]
	push	_45
	push	dword [ebp-12]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_611
_604:
	push	ebp
	push	_617
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_612
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_614
	call	brl_blitz_NullObjectError
_614:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_616
	call	brl_blitz_NullObjectError
_616:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
_611:
	push	_618
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],bbNullObject
	jne	_619
	push	ebp
	push	_621
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_620
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	call	dword [bbOnDebugLeaveScope]
	jmp	_153
_619:
	push	_622
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbStringClass
	push	dword [ebp-16]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_624
	mov	eax,bbEmptyString
_624:
	mov	ebx,eax
	jmp	_153
_153:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_Close:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_647
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_627
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_629
	call	brl_blitz_NullObjectError
_629:
	cmp	dword [ebx+12],bbNullObject
	je	_630
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
	mov	ebx,dword [ebx+12]
	cmp	ebx,bbNullObject
	jne	_635
	call	brl_blitz_NullObjectError
_635:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_630:
	push	_637
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_639
	call	brl_blitz_NullObjectError
_639:
	cmp	dword [ebx+16],bbNullObject
	je	_640
	push	ebp
	push	_646
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_641
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_643
	call	brl_blitz_NullObjectError
_643:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_645
	call	brl_blitz_NullObjectError
_645:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_640:
	mov	ebx,0
	jmp	_156
_156:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
_159:
	mov	eax,0
	jmp	_649
_649:
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_169:
	dd	0
_168:
	db	"basefunctions_localization",0
	align	4
_167:
	dd	1
	dd	_168
	dd	0
_162:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_localization.bmx",0
	align	4
_161:
	dd	_162
	dd	6
	dd	4
	align	4
_bb_Localization_currentLanguage:
	dd	bbEmptyString
	align	4
_163:
	dd	_162
	dd	7
	dd	4
	align	4
_bb_Localization_supportedLanguages:
	dd	bbNullObject
	align	4
_164:
	dd	_162
	dd	8
	dd	4
	align	4
_bb_Localization_Resources:
	dd	bbNullObject
_47:
	db	"Localization",0
_48:
	db	"New",0
_49:
	db	"()i",0
_50:
	db	"SetLanguage",0
_51:
	db	"($)i",0
_52:
	db	"Language",0
_53:
	db	"()$",0
_54:
	db	"AddLanguages",0
_55:
	db	"OpenResource",0
_56:
	db	"LoadResource",0
_57:
	db	"OpenResources",0
_58:
	db	"LoadResources",0
_59:
	db	"GetString",0
_60:
	db	"($,$)$",0
_61:
	db	"GetLanguageFromFilename",0
_62:
	db	"($)$",0
_63:
	db	"GetResourceFiles",0
_64:
	db	"($):brl.linkedlist.TList",0
_65:
	db	"Dispose",0
	align	4
_46:
	dd	2
	dd	_47
	dd	6
	dd	_48
	dd	_49
	dd	16
	dd	7
	dd	_50
	dd	_51
	dd	48
	dd	7
	dd	_52
	dd	_53
	dd	52
	dd	7
	dd	_54
	dd	_51
	dd	56
	dd	7
	dd	_55
	dd	_51
	dd	60
	dd	7
	dd	_56
	dd	_51
	dd	64
	dd	7
	dd	_57
	dd	_51
	dd	68
	dd	7
	dd	_58
	dd	_51
	dd	72
	dd	7
	dd	_59
	dd	_60
	dd	76
	dd	7
	dd	_61
	dd	_62
	dd	80
	dd	7
	dd	_63
	dd	_64
	dd	84
	dd	7
	dd	_65
	dd	_49
	dd	88
	dd	0
	align	4
bb_Localization:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_46
	dd	8
	dd	_bb_Localization_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_Localization_SetLanguage
	dd	_bb_Localization_Language
	dd	_bb_Localization_AddLanguages
	dd	_bb_Localization_OpenResource
	dd	_bb_Localization_LoadResource
	dd	_bb_Localization_OpenResources
	dd	_bb_Localization_LoadResources
	dd	_bb_Localization_GetString
	dd	_bb_Localization_GetLanguageFromFilename
	dd	_bb_Localization_GetResourceFiles
	dd	_bb_Localization_Dispose
_67:
	db	"LocalizationResource",0
_68:
	db	"language",0
_69:
	db	"$",0
_70:
	db	"_link",0
_71:
	db	":brl.linkedlist.TLink",0
_72:
	db	"Close",0
	align	4
_66:
	dd	2
	dd	_67
	dd	3
	dd	_68
	dd	_69
	dd	8
	dd	3
	dd	_70
	dd	_71
	dd	12
	dd	6
	dd	_48
	dd	_49
	dd	16
	dd	6
	dd	_59
	dd	_60
	dd	48
	dd	6
	dd	_72
	dd	_49
	dd	52
	dd	0
	align	4
bb_LocalizationResource:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_66
	dd	16
	dd	_bb_LocalizationResource_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	brl_blitz_NullMethodError
	dd	brl_blitz_NullMethodError
_74:
	db	"LocalizationStreamingResource",0
_75:
	db	"Stream",0
_76:
	db	":brl.stream.TStream",0
_77:
	db	"open",0
_78:
	db	"($,$):LocalizationStreamingResource",0
_79:
	db	"Delete",0
	align	4
_73:
	dd	2
	dd	_74
	dd	3
	dd	_75
	dd	_76
	dd	16
	dd	6
	dd	_48
	dd	_49
	dd	16
	dd	7
	dd	_77
	dd	_78
	dd	56
	dd	6
	dd	_59
	dd	_60
	dd	48
	dd	6
	dd	_72
	dd	_49
	dd	52
	dd	6
	dd	_79
	dd	_49
	dd	20
	dd	0
	align	4
bb_LocalizationStreamingResource:
	dd	bb_LocalizationResource
	dd	bbObjectFree
	dd	_73
	dd	20
	dd	_bb_LocalizationStreamingResource_New
	dd	_bb_LocalizationStreamingResource_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_LocalizationStreamingResource_GetString
	dd	_bb_LocalizationStreamingResource_Close
	dd	_bb_LocalizationStreamingResource_open
_81:
	db	"LocalizationMemoryResource",0
_82:
	db	"map",0
_83:
	db	":brl.map.TMap",0
_84:
	db	"($,$):LocalizationMemoryResource",0
	align	4
_80:
	dd	2
	dd	_81
	dd	3
	dd	_82
	dd	_83
	dd	16
	dd	6
	dd	_48
	dd	_49
	dd	16
	dd	7
	dd	_77
	dd	_84
	dd	56
	dd	6
	dd	_59
	dd	_60
	dd	48
	dd	6
	dd	_72
	dd	_49
	dd	52
	dd	6
	dd	_79
	dd	_49
	dd	20
	dd	0
	align	4
bb_LocalizationMemoryResource:
	dd	bb_LocalizationResource
	dd	bbObjectFree
	dd	_80
	dd	20
	dd	_bb_LocalizationMemoryResource_New
	dd	_bb_LocalizationMemoryResource_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_LocalizationMemoryResource_GetString
	dd	_bb_LocalizationMemoryResource_Close
	dd	_bb_LocalizationMemoryResource_open
	align	4
_165:
	dd	_162
	dd	163
	dd	1
	align	4
_166:
	dd	_162
	dd	164
	dd	1
_173:
	db	"Self",0
_174:
	db	":Localization",0
	align	4
_172:
	dd	1
	dd	_48
	dd	2
	dd	_173
	dd	_174
	dd	-4
	dd	0
	align	4
_171:
	dd	3
	dd	0
	dd	0
	align	4
_193:
	dd	1
	dd	_50
	dd	2
	dd	_68
	dd	_69
	dd	-4
	dd	0
	align	4
_175:
	dd	_162
	dd	13
	dd	7
_191:
	db	"lang",0
	align	4
_190:
	dd	3
	dd	0
	dd	2
	dd	_191
	dd	_69
	dd	-8
	dd	0
	align	4
_185:
	dd	_162
	dd	14
	dd	10
	align	4
_189:
	dd	3
	dd	0
	dd	0
	align	4
_187:
	dd	_162
	dd	15
	dd	13
	align	4
_188:
	dd	_162
	dd	16
	dd	13
	align	4
_192:
	dd	_162
	dd	20
	dd	7
	align	4
_195:
	dd	1
	dd	_52
	dd	0
	align	4
_194:
	dd	_162
	dd	27
	dd	7
_216:
	db	"languages",0
_217:
	db	"Pos",0
_218:
	db	"i",0
	align	4
_215:
	dd	1
	dd	_54
	dd	2
	dd	_216
	dd	_69
	dd	-4
	dd	2
	dd	_217
	dd	_218
	dd	-8
	dd	0
	align	4
_196:
	dd	_162
	dd	33
	dd	7
	align	4
_6:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	44
	align	4
_198:
	dd	_162
	dd	34
	dd	7
	align	4
_204:
	dd	3
	dd	0
	dd	0
	align	4
_200:
	dd	_162
	dd	35
	dd	10
	align	4
_203:
	dd	_162
	dd	36
	dd	10
	align	4
_205:
	dd	_162
	dd	39
	dd	7
	align	4
_211:
	dd	3
	dd	0
	dd	0
	align	4
_206:
	dd	_162
	dd	40
	dd	10
	align	4
_209:
	dd	_162
	dd	41
	dd	10
	align	4
_210:
	dd	_162
	dd	42
	dd	10
	align	4
_212:
	dd	_162
	dd	45
	dd	7
_221:
	db	"filename",0
	align	4
_220:
	dd	1
	dd	_55
	dd	2
	dd	_221
	dd	_69
	dd	-4
	dd	0
	align	4
_219:
	dd	_162
	dd	51
	dd	7
	align	4
_223:
	dd	1
	dd	_56
	dd	2
	dd	_221
	dd	_69
	dd	-4
	dd	0
	align	4
_222:
	dd	_162
	dd	57
	dd	7
_238:
	db	"filter",0
	align	4
_237:
	dd	1
	dd	_57
	dd	2
	dd	_238
	dd	_69
	dd	-4
	dd	0
	align	4
_224:
	dd	_162
	dd	63
	dd	7
_236:
	db	"file",0
	align	4
_235:
	dd	3
	dd	0
	dd	2
	dd	_236
	dd	_69
	dd	-8
	dd	0
	align	4
_234:
	dd	_162
	dd	64
	dd	10
	align	4
_251:
	dd	1
	dd	_58
	dd	2
	dd	_238
	dd	_69
	dd	-4
	dd	0
	align	4
_239:
	dd	_162
	dd	71
	dd	7
	align	4
_250:
	dd	3
	dd	0
	dd	2
	dd	_236
	dd	_69
	dd	-8
	dd	0
	align	4
_249:
	dd	_162
	dd	72
	dd	10
_282:
	db	"Key",0
_283:
	db	"group",0
_284:
	db	"ret",0
	align	4
_281:
	dd	1
	dd	_59
	dd	2
	dd	_282
	dd	_69
	dd	-4
	dd	2
	dd	_283
	dd	_69
	dd	-8
	dd	2
	dd	_284
	dd	_69
	dd	-12
	dd	0
	align	4
_252:
	dd	_162
	dd	79
	dd	7
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_254:
	dd	_162
	dd	81
	dd	7
_278:
	db	"r",0
_279:
	db	":LocalizationResource",0
	align	4
_277:
	dd	3
	dd	0
	dd	2
	dd	_278
	dd	_279
	dd	-16
	dd	0
	align	4
_264:
	dd	_162
	dd	82
	dd	10
	align	4
_269:
	dd	3
	dd	0
	dd	0
	align	4
_268:
	dd	_162
	dd	82
	dd	48
	align	4
_270:
	dd	_162
	dd	83
	dd	10
	align	4
_273:
	dd	_162
	dd	84
	dd	10
	align	4
_276:
	dd	3
	dd	0
	dd	0
	align	4
_275:
	dd	_162
	dd	84
	dd	30
	align	4
_280:
	dd	_162
	dd	87
	dd	7
_309:
	db	"lastpos",0
	align	4
_308:
	dd	1
	dd	_61
	dd	2
	dd	_221
	dd	_69
	dd	-4
	dd	2
	dd	_309
	dd	_218
	dd	-8
	dd	2
	dd	_217
	dd	_218
	dd	-12
	dd	0
	align	4
_285:
	dd	_162
	dd	93
	dd	10
	align	4
_287:
	dd	_162
	dd	94
	dd	10
	align	4
_19:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	95
	align	4
_289:
	dd	_162
	dd	97
	dd	10
	align	4
_292:
	dd	3
	dd	0
	dd	0
	align	4
_290:
	dd	_162
	dd	98
	dd	13
	align	4
_291:
	dd	_162
	dd	99
	dd	13
	align	4
_293:
	dd	_162
	dd	102
	dd	10
	align	4
_306:
	dd	3
	dd	0
	dd	0
	align	4
_295:
	dd	_162
	dd	103
	dd	13
	align	4
_296:
	dd	_162
	dd	104
	dd	13
	align	4
_299:
	dd	3
	dd	0
	dd	0
	align	4
_298:
	dd	_162
	dd	105
	dd	16
	align	4
_300:
	dd	_162
	dd	108
	dd	13
	align	4
_23:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	46
	align	4
_301:
	dd	_162
	dd	109
	dd	13
	align	4
_304:
	dd	3
	dd	0
	dd	0
	align	4
_303:
	dd	_162
	dd	110
	dd	16
	align	4
_305:
	dd	_162
	dd	113
	dd	13
	align	4
_307:
	dd	_162
	dd	116
	dd	10
_359:
	db	":brl.linkedlist.TList",0
	align	4
_358:
	dd	1
	dd	_63
	dd	2
	dd	_238
	dd	_69
	dd	-4
	dd	2
	dd	_284
	dd	_359
	dd	-8
	dd	2
	dd	_217
	dd	_218
	dd	-12
	dd	0
	align	4
_310:
	dd	_162
	dd	122
	dd	7
	align	4
_312:
	dd	_162
	dd	123
	dd	7
	align	4
_24:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	42
	align	4
_314:
	dd	_162
	dd	125
	dd	7
_352:
	db	"prefix",0
_353:
	db	"suffix",0
_354:
	db	"dir",0
_355:
	db	"dir_content",0
_356:
	db	"[]$",0
	align	4
_351:
	dd	3
	dd	0
	dd	2
	dd	_352
	dd	_69
	dd	-16
	dd	2
	dd	_353
	dd	_69
	dd	-20
	dd	2
	dd	_354
	dd	_69
	dd	-24
	dd	2
	dd	_355
	dd	_356
	dd	-28
	dd	0
	align	4
_316:
	dd	_162
	dd	127
	dd	10
	align	4
_318:
	dd	_162
	dd	128
	dd	10
	align	4
_320:
	dd	_162
	dd	130
	dd	10
	align	4
_322:
	dd	_162
	dd	131
	dd	10
	align	4
_324:
	dd	_162
	dd	133
	dd	10
	align	4
_325:
	dd	_162
	dd	134
	dd	10
	align	4
_25:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	47
	align	4
_26:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	92
	align	4
_330:
	dd	3
	dd	0
	dd	0
	align	4
_329:
	dd	_162
	dd	134
	dd	65
	align	4
_331:
	dd	_162
	dd	136
	dd	10
	align	4
_350:
	dd	3
	dd	0
	dd	2
	dd	_236
	dd	_69
	dd	-32
	dd	0
	align	4
_337:
	dd	_162
	dd	137
	dd	13
	align	4
_349:
	dd	3
	dd	0
	dd	0
	align	4
_341:
	dd	_162
	dd	138
	dd	16
	align	4
_348:
	dd	3
	dd	0
	dd	0
	align	4
_345:
	dd	_162
	dd	139
	dd	19
	align	4
_357:
	dd	_162
	dd	146
	dd	7
	align	4
_379:
	dd	1
	dd	_65
	dd	0
	align	4
_360:
	dd	_162
	dd	152
	dd	7
	align	4
_373:
	dd	3
	dd	0
	dd	2
	dd	_278
	dd	_279
	dd	-4
	dd	0
	align	4
_370:
	dd	_162
	dd	153
	dd	10
	align	4
_374:
	dd	_162
	dd	156
	dd	7
	align	4
_377:
	dd	_162
	dd	157
	dd	7
	align	4
_378:
	dd	_162
	dd	158
	dd	7
	align	4
_381:
	dd	1
	dd	_48
	dd	2
	dd	_173
	dd	_279
	dd	-4
	dd	0
	align	4
_380:
	dd	3
	dd	0
	dd	0
_384:
	db	":LocalizationStreamingResource",0
	align	4
_383:
	dd	1
	dd	_48
	dd	2
	dd	_173
	dd	_384
	dd	-4
	dd	0
	align	4
_382:
	dd	3
	dd	0
	dd	0
	align	4
_415:
	dd	1
	dd	_77
	dd	2
	dd	_221
	dd	_69
	dd	-4
	dd	2
	dd	_68
	dd	_69
	dd	-8
	dd	2
	dd	_236
	dd	_76
	dd	-12
	dd	2
	dd	_278
	dd	_384
	dd	-16
	dd	0
	align	4
_385:
	dd	_162
	dd	190
	dd	7
	align	4
_392:
	dd	3
	dd	0
	dd	0
	align	4
_387:
	dd	_162
	dd	191
	dd	10
	align	4
_388:
	dd	_162
	dd	192
	dd	10
	align	4
_391:
	dd	3
	dd	0
	dd	0
	align	4
_390:
	dd	_162
	dd	192
	dd	34
	align	4
_33:
	dd	bbStringClass
	dd	2147483647
	dd	217
	dw	78,111,32,108,97,110,103,117,97,103,101,32,119,97,115,32
	dw	115,112,101,99,105,102,105,101,100,32,102,111,114,32,108,111
	dw	97,100,105,110,103,32,116,104,101,32,114,101,115,111,117,114
	dw	99,101,32,102,105,108,101,32,97,110,100,32,116,104,101,32
	dw	108,97,110,103,117,97,103,101,32,99,111,117,108,100,32,110
	dw	111,116,32,98,101,32,100,101,116,101,99,116,101,100,32,102
	dw	114,111,109,32,116,104,101,32,102,105,108,101,110,97,109,101
	dw	32,105,116,115,101,108,102,46,13,10,80,108,101,97,115,101
	dw	32,115,112,101,99,105,102,121,32,116,104,101,32,108,97,110
	dw	103,117,97,103,101,32,111,114,32,117,115,101,32,116,104,101
	dw	32,102,111,114,109,97,116,32,34,110,97,109,101,95,108,97
	dw	110,103,117,97,103,101,46,101,120,116,101,110,115,105,111,110
	dw	34,32,102,111,114,32,116,104,101,32,114,101,115,111,117,114
	dw	99,101,32,102,105,108,101,115,46
	align	4
_393:
	dd	_162
	dd	195
	dd	7
	align	4
_395:
	dd	_162
	dd	196
	dd	7
	align	4
_398:
	dd	3
	dd	0
	dd	0
	align	4
_397:
	dd	_162
	dd	196
	dd	27
	align	4
_35:
	dd	bbStringClass
	dd	2147483647
	dd	51
	dw	34,32,119,97,115,32,110,111,116,32,102,111,117,110,100,32
	dw	111,114,32,99,111,117,108,100,32,110,111,116,32,98,101,32
	dw	111,112,101,110,101,100,32,102,111,114,32,114,101,97,100,105
	dw	110,103,46
	align	4
_34:
	dd	bbStringClass
	dd	2147483647
	dd	19
	dw	84,104,101,32,114,101,115,111,117,114,99,101,32,102,105,108
	dw	101,32,34
	align	4
_399:
	dd	_162
	dd	198
	dd	7
	align	4
_401:
	dd	_162
	dd	199
	dd	7
	align	4
_405:
	dd	_162
	dd	200
	dd	7
	align	4
_409:
	dd	_162
	dd	201
	dd	7
_477:
	db	"line",0
_478:
	db	"_key",0
_479:
	db	"value",0
_480:
	db	"skip",0
	align	4
_476:
	dd	1
	dd	_59
	dd	2
	dd	_173
	dd	_384
	dd	-4
	dd	2
	dd	_282
	dd	_69
	dd	-8
	dd	2
	dd	_283
	dd	_69
	dd	-12
	dd	2
	dd	_477
	dd	_69
	dd	-16
	dd	2
	dd	_478
	dd	_69
	dd	-20
	dd	2
	dd	_479
	dd	_69
	dd	-24
	dd	2
	dd	_480
	dd	_218
	dd	-28
	dd	2
	dd	_217
	dd	_218
	dd	-32
	dd	0
	align	4
_416:
	dd	_162
	dd	207
	dd	7
	align	4
_421:
	dd	3
	dd	0
	dd	0
	align	4
_420:
	dd	_162
	dd	207
	dd	29
	align	4
_422:
	dd	_162
	dd	208
	dd	7
	align	4
_427:
	dd	_162
	dd	210
	dd	7
	align	4
_429:
	dd	_162
	dd	211
	dd	7
	align	4
_431:
	dd	_162
	dd	212
	dd	7
	align	4
_433:
	dd	_162
	dd	213
	dd	7
	align	4
_435:
	dd	_162
	dd	214
	dd	7
	align	4
_437:
	dd	_162
	dd	216
	dd	7
	align	4
_474:
	dd	3
	dd	0
	dd	0
	align	4
_440:
	dd	_162
	dd	217
	dd	10
	align	4
_443:
	dd	_162
	dd	220
	dd	10
	align	4
_463:
	dd	3
	dd	0
	dd	0
	align	4
_445:
	dd	_162
	dd	222
	dd	13
	align	4
_39:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	91
	align	4
_450:
	dd	3
	dd	0
	dd	0
	align	4
_449:
	dd	_162
	dd	222
	dd	51
	align	4
_451:
	dd	_162
	dd	224
	dd	13
	align	4
_40:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	93
	align	4
_462:
	dd	3
	dd	0
	dd	0
	align	4
_455:
	dd	_162
	dd	225
	dd	16
	align	4
_458:
	dd	3
	dd	0
	dd	0
	align	4
_457:
	dd	_162
	dd	226
	dd	19
	align	4
_461:
	dd	3
	dd	0
	dd	0
	align	4
_460:
	dd	_162
	dd	228
	dd	19
	align	4
_464:
	dd	_162
	dd	236
	dd	10
	align	4
_41:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	61
	align	4
_465:
	dd	_162
	dd	237
	dd	10
	align	4
_469:
	dd	3
	dd	0
	dd	0
	align	4
_467:
	dd	_162
	dd	238
	dd	13
	align	4
_468:
	dd	_162
	dd	239
	dd	13
	align	4
_470:
	dd	_162
	dd	242
	dd	10
	align	4
_473:
	dd	3
	dd	0
	dd	0
	align	4
_472:
	dd	_162
	dd	242
	dd	30
	align	4
_475:
	dd	_162
	dd	246
	dd	7
	align	4
_501:
	dd	1
	dd	_72
	dd	2
	dd	_173
	dd	_384
	dd	-4
	dd	0
	align	4
_481:
	dd	_162
	dd	252
	dd	7
	align	4
_490:
	dd	3
	dd	0
	dd	0
	align	4
_485:
	dd	_162
	dd	252
	dd	29
	align	4
_491:
	dd	_162
	dd	253
	dd	7
	align	4
_500:
	dd	3
	dd	0
	dd	0
	align	4
_495:
	dd	_162
	dd	253
	dd	30
_506:
	db	":LocalizationMemoryResource",0
	align	4
_505:
	dd	1
	dd	_48
	dd	2
	dd	_173
	dd	_506
	dd	-4
	dd	0
	align	4
_504:
	dd	3
	dd	0
	dd	0
	align	4
_600:
	dd	1
	dd	_77
	dd	2
	dd	_221
	dd	_69
	dd	-4
	dd	2
	dd	_68
	dd	_69
	dd	-8
	dd	2
	dd	_236
	dd	_76
	dd	-12
	dd	2
	dd	_278
	dd	_506
	dd	-16
	dd	2
	dd	_477
	dd	_69
	dd	-20
	dd	2
	dd	_282
	dd	_69
	dd	-24
	dd	2
	dd	_479
	dd	_69
	dd	-28
	dd	2
	dd	_217
	dd	_218
	dd	-32
	dd	2
	dd	_283
	dd	_69
	dd	-36
	dd	0
	align	4
_507:
	dd	_162
	dd	271
	dd	7
	align	4
_514:
	dd	3
	dd	0
	dd	0
	align	4
_509:
	dd	_162
	dd	272
	dd	10
	align	4
_510:
	dd	_162
	dd	273
	dd	10
	align	4
_513:
	dd	3
	dd	0
	dd	0
	align	4
_512:
	dd	_162
	dd	273
	dd	34
	align	4
_515:
	dd	_162
	dd	276
	dd	7
	align	4
_517:
	dd	_162
	dd	277
	dd	7
	align	4
_520:
	dd	3
	dd	0
	dd	0
	align	4
_519:
	dd	_162
	dd	277
	dd	27
	align	4
_521:
	dd	_162
	dd	279
	dd	7
	align	4
_523:
	dd	_162
	dd	280
	dd	7
	align	4
_527:
	dd	_162
	dd	281
	dd	7
	align	4
_531:
	dd	_162
	dd	282
	dd	7
	align	4
_537:
	dd	_162
	dd	284
	dd	7
	align	4
_539:
	dd	_162
	dd	285
	dd	7
	align	4
_541:
	dd	_162
	dd	286
	dd	7
	align	4
_543:
	dd	_162
	dd	287
	dd	7
	align	4
_545:
	dd	_162
	dd	288
	dd	7
	align	4
_547:
	dd	_162
	dd	291
	dd	7
	align	4
_595:
	dd	3
	dd	0
	dd	0
	align	4
_548:
	dd	_162
	dd	292
	dd	10
	align	4
_549:
	dd	_162
	dd	294
	dd	10
	align	4
_554:
	dd	3
	dd	0
	dd	0
	align	4
_553:
	dd	_162
	dd	295
	dd	13
	align	4
_555:
	dd	_162
	dd	298
	dd	10
	align	4
_556:
	dd	_162
	dd	299
	dd	10
	align	4
_560:
	dd	3
	dd	0
	dd	0
	align	4
_558:
	dd	_162
	dd	300
	dd	13
	align	4
_559:
	dd	_162
	dd	301
	dd	13
	align	4
_561:
	dd	_162
	dd	304
	dd	10
	align	4
_594:
	dd	3
	dd	0
	dd	0
	align	4
_565:
	dd	_162
	dd	305
	dd	13
	align	4
_586:
	dd	3
	dd	0
	dd	0
	align	4
_569:
	dd	_162
	dd	306
	dd	16
	align	4
_45:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	58,58
	align	4
_574:
	dd	_162
	dd	307
	dd	16
	align	4
_585:
	dd	3
	dd	0
	dd	0
	align	4
_580:
	dd	_162
	dd	307
	dd	54
	align	4
_593:
	dd	3
	dd	0
	dd	0
	align	4
_588:
	dd	_162
	dd	309
	dd	16
	align	4
_596:
	dd	_162
	dd	314
	dd	7
	align	4
_599:
	dd	_162
	dd	316
	dd	7
_626:
	db	":Object",0
	align	4
_625:
	dd	1
	dd	_59
	dd	2
	dd	_173
	dd	_506
	dd	-4
	dd	2
	dd	_282
	dd	_69
	dd	-8
	dd	2
	dd	_283
	dd	_69
	dd	-12
	dd	2
	dd	_284
	dd	_626
	dd	-16
	dd	0
	align	4
_601:
	dd	_162
	dd	322
	dd	7
	align	4
_603:
	dd	_162
	dd	324
	dd	7
	align	4
_610:
	dd	3
	dd	0
	dd	0
	align	4
_605:
	dd	_162
	dd	325
	dd	10
	align	4
_617:
	dd	3
	dd	0
	dd	0
	align	4
_612:
	dd	_162
	dd	327
	dd	10
	align	4
_618:
	dd	_162
	dd	330
	dd	7
	align	4
_621:
	dd	3
	dd	0
	dd	0
	align	4
_620:
	dd	_162
	dd	330
	dd	26
	align	4
_622:
	dd	_162
	dd	331
	dd	7
	align	4
_647:
	dd	1
	dd	_72
	dd	2
	dd	_173
	dd	_506
	dd	-4
	dd	0
	align	4
_627:
	dd	_162
	dd	337
	dd	7
	align	4
_636:
	dd	3
	dd	0
	dd	0
	align	4
_631:
	dd	_162
	dd	337
	dd	29
	align	4
_637:
	dd	_162
	dd	338
	dd	7
	align	4
_646:
	dd	3
	dd	0
	dd	0
	align	4
_641:
	dd	_162
	dd	338
	dd	27
