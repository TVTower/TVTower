	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_max2d_max2d
	extrn	__bb_random_random
	extrn	__bb_reflection_reflection
	extrn	__bb_source_basefunctions_image
	extrn	__bb_source_basefunctions_sprites
	extrn	__bb_source_basefunctions_xml
	extrn	__bb_threads_threads
	extrn	bbEmptyString
	extrn	bbExThrow
	extrn	bbFloatToInt
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
	extrn	bbObjectToString
	extrn	bbOnDebugEnterScope
	extrn	bbOnDebugEnterStm
	extrn	bbOnDebugLeaveScope
	extrn	bbStringClass
	extrn	bbStringCompare
	extrn	bbStringConcat
	extrn	bb_KEYMANAGER
	extrn	bb_KEYWRAPPER
	extrn	bb_LastSeekPos
	extrn	bb_LoadSaveFile
	extrn	bb_MOUSEMANAGER
	extrn	bb_TAsset
	extrn	bb_TBigImage
	extrn	bb_TGW_SpritePack
	extrn	bb_TGW_Sprites
	extrn	bb_functions
	extrn	bb_tRenderERROR
	extrn	brl_blitz_NullObjectError
	extrn	brl_map_CreateMap
	extrn	brl_map_TMap
	extrn	brl_max2d_TImage
	extrn	brl_max2d_TImageFont
	extrn	brl_retro_Lower
	extrn	brl_standardio_Print
	extrn	brl_threads_CreateMutex
	extrn	brl_threads_CreateThread
	extrn	brl_threads_LockMutex
	extrn	brl_threads_ThreadRunning
	extrn	brl_threads_UnlockMutex
	public	__bb_source_basefunctions_resourcemanager
	public	_bb_TAssetManager_Add
	public	_bb_TAssetManager_AddImageAsSprite
	public	_bb_TAssetManager_AddSet
	public	_bb_TAssetManager_AddToLoadAsset
	public	_bb_TAssetManager_AssetsLoadThread
	public	_bb_TAssetManager_AssetsLoadedLock
	public	_bb_TAssetManager_AssetsToLoad
	public	_bb_TAssetManager_AssetsToLoadLock
	public	_bb_TAssetManager_ConvertImageToSprite
	public	_bb_TAssetManager_Create
	public	_bb_TAssetManager_GetBigImage
	public	_bb_TAssetManager_GetFont
	public	_bb_TAssetManager_GetImage
	public	_bb_TAssetManager_GetMap
	public	_bb_TAssetManager_GetObject
	public	_bb_TAssetManager_GetSprite
	public	_bb_TAssetManager_GetSpritePack
	public	_bb_TAssetManager_LoadAssetsInThread
	public	_bb_TAssetManager_New
	public	_bb_TAssetManager_PrintAssets
	public	_bb_TAssetManager_SetContent
	public	_bb_TAssetManager_StartLoadingAssets
	public	_bb_TAssetManager_content
	public	bb_Assets
	public	bb_TAssetManager
	section	"code" executable
__bb_source_basefunctions_resourcemanager:
	push	ebp
	mov	ebp,esp
	push	ebx
	cmp	dword [_276],0
	je	_277
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_277:
	mov	dword [_276],1
	push	ebp
	push	_165
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	__bb_blitz_blitz
	call	__bb_max2d_max2d
	call	__bb_random_random
	call	__bb_reflection_reflection
	call	__bb_threads_threads
	call	__bb_source_basefunctions_xml
	call	__bb_source_basefunctions_image
	call	__bb_source_basefunctions_sprites
	push	_152
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_154]
	and	eax,1
	cmp	eax,0
	jne	_155
	call	brl_map_CreateMap
	mov	dword [_bb_TAssetManager_content],eax
	or	dword [_154],1
_155:
	push	_156
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_154]
	and	eax,2
	cmp	eax,0
	jne	_157
	call	brl_map_CreateMap
	mov	dword [_bb_TAssetManager_AssetsToLoad],eax
	or	dword [_154],2
_157:
	push	_158
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_154]
	and	eax,4
	cmp	eax,0
	jne	_159
	call	brl_threads_CreateMutex
	mov	dword [_bb_TAssetManager_AssetsLoadedLock],eax
	or	dword [_154],4
_159:
	push	_160
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_154]
	and	eax,8
	cmp	eax,0
	jne	_161
	call	brl_threads_CreateMutex
	mov	dword [_bb_TAssetManager_AssetsToLoadLock],eax
	or	dword [_154],8
_161:
	push	_162
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TAssetManager
	call	bbObjectRegisterType
	add	esp,4
	push	_163
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_154]
	and	eax,16
	cmp	eax,0
	jne	_164
	push	1
	push	bbNullObject
	call	dword [bb_TAssetManager+60]
	add	esp,8
	mov	dword [bb_Assets],eax
	or	dword [_154],16
_164:
	mov	ebx,0
	jmp	_73
_73:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_278
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TAssetManager
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],0
	mov	ebx,0
	jmp	_76
_76:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_LoadAssetsInThread:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbEmptyString
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],bbNullObject
	mov	eax,ebp
	push	eax
	push	_321
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_280
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbEmptyString
	mov	ebx,dword [_bb_TAssetManager_AssetsToLoad]
	cmp	ebx,bbNullObject
	jne	_283
	call	brl_blitz_NullObjectError
_283:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	mov	dword [ebp-20],eax
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_286
	call	brl_blitz_NullObjectError
_286:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	mov	edi,eax
	jmp	_8
_10:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_291
	call	brl_blitz_NullObjectError
_291:
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
	je	_8
	push	_292
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_TAssetManager_AssetsToLoad]
	cmp	ebx,bbNullObject
	jne	_294
	call	brl_blitz_NullObjectError
_294:
	push	bb_TAsset
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-12],eax
	push	_296
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_298
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_300
	call	brl_blitz_NullObjectError
_300:
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_302
	call	brl_blitz_NullObjectError
_302:
	push	_13
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	eax
	push	_12
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+52]
	add	esp,4
	push	eax
	push	_11
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
	push	_303
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_305
	call	brl_blitz_NullObjectError
_305:
	push	_14
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_306
	push	_307
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	call	dword [bb_TGW_Sprites+88]
	add	esp,4
	mov	dword [ebp-16],eax
_306:
	push	_308
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_310
	call	brl_blitz_NullObjectError
_310:
	push	_15
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_311
	push	_312
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	call	dword [bb_TGW_Sprites+88]
	add	esp,4
	mov	dword [ebp-16],eax
_311:
	push	_313
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [_bb_TAssetManager_AssetsLoadedLock]
	call	brl_threads_LockMutex
	add	esp,4
	push	_314
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [_bb_TAssetManager_content]
	cmp	esi,bbNullObject
	jne	_316
	call	brl_blitz_NullObjectError
_316:
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_318
	call	brl_blitz_NullObjectError
_318:
	push	dword [ebp-16]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+56]
	add	esp,12
	push	_319
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [_bb_TAssetManager_AssetsLoadedLock]
	call	brl_threads_UnlockMutex
	add	esp,4
	push	_320
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	bbGCCollect
_8:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_289
	call	brl_blitz_NullObjectError
_289:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_10
_9:
	mov	ebx,bbNullObject
	jmp	_79
_79:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_StartLoadingAssets:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_336
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_328
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_bb_TAssetManager_AssetsLoadThread]
	cmp	eax,bbNullObject
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_329
	push	dword [_bb_TAssetManager_AssetsLoadThread]
	call	brl_threads_ThreadRunning
	add	esp,4
	cmp	eax,0
	sete	al
	movzx	eax,al
_329:
	cmp	eax,0
	je	_331
	push	_332
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_16
	call	brl_standardio_Print
	add	esp,4
	push	_333
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_17
	call	brl_standardio_Print
	add	esp,4
	push	_334
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_16
	call	brl_standardio_Print
	add	esp,4
	push	_335
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbNullObject
	push	dword [bb_TAssetManager+48]
	call	brl_threads_CreateThread
	add	esp,8
	mov	dword [_bb_TAssetManager_AssetsLoadThread],eax
_331:
	mov	ebx,0
	jmp	_82
_82:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_AddToLoadAsset:
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
	push	_343
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_337
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_TAssetManager_AssetsToLoad]
	cmp	ebx,bbNullObject
	jne	_339
	call	brl_blitz_NullObjectError
_339:
	push	dword [ebp-12]
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	push	_340
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_342
	call	brl_blitz_NullObjectError
_342:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	ebx,0
	jmp	_87
_87:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_Create:
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
	push	_356
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_346
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TAssetManager
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-12],eax
	push	_348
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-4],bbNullObject
	je	_349
	push	_350
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [_bb_TAssetManager_content],eax
_349:
	push	_351
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_353
	call	brl_blitz_NullObjectError
_353:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+8],eax
	push	_355
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_91
_91:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_AddSet:
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
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],bbEmptyString
	mov	eax,ebp
	push	eax
	push	_393
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_359
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	push	_361
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_363
	call	brl_blitz_NullObjectError
_363:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	mov	dword [ebp-28],eax
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_366
	call	brl_blitz_NullObjectError
_366:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	mov	dword [ebp-24],eax
	jmp	_18
_20:
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_371
	call	brl_blitz_NullObjectError
_371:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-12],eax
	cmp	dword [ebp-12],bbNullObject
	je	_18
	push	_372
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_374
	call	brl_blitz_NullObjectError
_374:
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-16],eax
	push	_376
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],_21
	push	_378
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TAsset
	push	dword [ebp-16]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_379
	push	_380
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_382
	call	brl_blitz_NullObjectError
_382:
	push	bbStringClass
	push	dword [ebp-12]
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	jne	_384
	mov	esi,bbEmptyString
_384:
	push	bb_TAsset
	push	dword [ebp-16]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_386
	call	brl_blitz_NullObjectError
_386:
	push	dword [ebx+8]
	push	bb_TAsset
	push	dword [ebp-16]
	call	bbObjectDowncast
	add	esp,8
	push	eax
	push	esi
	call	brl_retro_Lower
	add	esp,4
	push	eax
	push	edi
	mov	eax,dword [edi]
	call	dword [eax+76]
	add	esp,16
	jmp	_387
_379:
	push	_388
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_390
	call	brl_blitz_NullObjectError
_390:
	push	bbStringClass
	push	dword [ebp-12]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_392
	mov	ebx,bbEmptyString
_392:
	push	dword [ebp-20]
	push	dword [ebp-20]
	push	dword [ebp-16]
	call	dword [bb_TAsset+48]
	add	esp,8
	push	eax
	push	ebx
	call	brl_retro_Lower
	add	esp,4
	push	eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+76]
	add	esp,16
_387:
_18:
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_369
	call	brl_blitz_NullObjectError
_369:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_20
_19:
	mov	ebx,0
	jmp	_95
_95:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_PrintAssets:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbEmptyString
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],bbNullObject
	mov	eax,ebp
	push	eax
	push	_428
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_396
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],_1
	push	_398
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	push	_400
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	mov	ebx,dword [_bb_TAssetManager_content]
	cmp	ebx,bbNullObject
	jne	_403
	call	brl_blitz_NullObjectError
_403:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	mov	dword [ebp-24],eax
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_406
	call	brl_blitz_NullObjectError
_406:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	mov	edi,eax
	jmp	_22
_24:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_411
	call	brl_blitz_NullObjectError
_411:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-16],eax
	cmp	dword [ebp-16],bbNullObject
	je	_22
	push	_412
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_TAssetManager_content]
	cmp	ebx,bbNullObject
	jne	_414
	call	brl_blitz_NullObjectError
_414:
	push	dword [ebp-16]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-20],eax
	push	_416
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbStringClass
	push	dword [ebp-16]
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	jne	_418
	mov	esi,bbEmptyString
_418:
	push	bb_TAsset
	push	dword [ebp-20]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_420
	call	brl_blitz_NullObjectError
_420:
	push	_13
	push	dword [ebx+8]
	push	_25
	push	esi
	push	_6
	push	dword [ebp-8]
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
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-8],eax
	push	_421
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [ebp-12],1
	push	_422
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],5
	jl	_423
	push	_424
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	push	_425
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_426
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-8],eax
_423:
_22:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_409
	call	brl_blitz_NullObjectError
_409:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_24
_23:
	push	_427
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_standardio_Print
	add	esp,4
	mov	ebx,0
	jmp	_98
_98:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_SetContent:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_432
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_431
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [_bb_TAssetManager_content],eax
	mov	ebx,0
	jmp	_102
_102:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_Add:
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
	push	_455
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_433
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_434
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_436
	call	brl_blitz_NullObjectError
_436:
	push	_15
	push	dword [ebx+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_437
	push	_438
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_440
	call	brl_blitz_NullObjectError
_440:
	push	brl_max2d_TImage
	push	dword [ebx+12]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_441
	push	_442
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_444
	call	brl_blitz_NullObjectError
_444:
	push	bb_TGW_Sprites
	push	dword [ebx+12]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_445
	push	_446
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_26
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	jmp	_447
_445:
	push	_448
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_27
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
_447:
_441:
	push	_449
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_451
	call	brl_blitz_NullObjectError
_451:
	push	-1
	push	dword [ebp-8]
	push	brl_max2d_TImage
	push	dword [ebx+12]
	call	bbObjectDowncast
	add	esp,8
	push	eax
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax]
	call	dword [eax+80]
	add	esp,12
	mov	dword [ebp-12],eax
_437:
	push	_452
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_TAssetManager_content]
	cmp	ebx,bbNullObject
	jne	_454
	call	brl_blitz_NullObjectError
_454:
	push	dword [ebp-12]
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	mov	ebx,0
	jmp	_108
_108:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_ConvertImageToSprite:
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
	mov	eax,ebp
	push	eax
	push	_474
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_459
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_28
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	push	eax
	push	dword [ebp-4]
	call	dword [bb_TGW_SpritePack+84]
	add	esp,8
	mov	dword [ebp-16],eax
	push	_461
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-16]
	cmp	edi,bbNullObject
	jne	_463
	call	brl_blitz_NullObjectError
_463:
	mov	eax,dword [ebp-4]
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],bbNullObject
	jne	_465
	call	brl_blitz_NullObjectError
_465:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_467
	call	brl_blitz_NullObjectError
_467:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_469
	call	brl_blitz_NullObjectError
_469:
	push	dword [ebp-12]
	mov	eax,dword [ebx+44]
	push	dword [eax+20]
	push	dword [esi+12]
	mov	eax,dword [ebp-20]
	push	dword [eax+8]
	push	0
	push	0
	push	dword [ebp-8]
	push	edi
	mov	eax,dword [edi]
	call	dword [eax+104]
	add	esp,32
	push	_470
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	bbGCCollect
	push	_471
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_473
	call	brl_blitz_NullObjectError
_473:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+96]
	add	esp,8
	mov	ebx,eax
	jmp	_113
_113:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_AddImageAsSprite:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+20]
	mov	dword [ebp-16],eax
	mov	dword [ebp-20],bbNullObject
	push	ebp
	push	_502
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_481
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],bbNullObject
	jne	_482
	push	_483
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	push	_29
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	jmp	_484
_482:
	push	_485
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	push	dword [ebp-8]
	push	dword [ebp-12]
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax]
	call	dword [eax+80]
	add	esp,12
	mov	dword [ebp-20],eax
	push	_487
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],0
	jle	_488
	push	_489
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_491
	call	brl_blitz_NullObjectError
_491:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+56],eax
	push	_493
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_495
	call	brl_blitz_NullObjectError
_495:
	mov	esi,dword [ebp-20]
	cmp	esi,bbNullObject
	jne	_498
	call	brl_blitz_NullObjectError
_498:
	fld	dword [esi+40]
	mov	eax,dword [ebp-16]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	fdivp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	dword [ebx+48],eax
_488:
	push	_499
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_TAssetManager_content]
	cmp	ebx,bbNullObject
	jne	_501
	call	brl_blitz_NullObjectError
_501:
	push	dword [ebp-20]
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
_484:
	mov	ebx,0
	jmp	_119
_119:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetObject:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+20]
	mov	dword [ebp-16],eax
	mov	dword [ebp-20],bbNullObject
	push	ebp
	push	_554
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_507
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_508
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_510
	call	brl_blitz_NullObjectError
_510:
	cmp	dword [ebx+8],0
	je	_511
	push	_512
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_TAssetManager_content]
	cmp	ebx,bbNullObject
	jne	_514
	call	brl_blitz_NullObjectError
_514:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_515
	push	_1
	push	dword [ebp-16]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
_515:
	cmp	eax,0
	je	_519
	mov	ebx,dword [_bb_TAssetManager_content]
	cmp	ebx,bbNullObject
	jne	_518
	call	brl_blitz_NullObjectError
_518:
	push	dword [ebp-16]
	call	brl_retro_Lower
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
_519:
	cmp	eax,0
	je	_521
	push	_522
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-16]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
_521:
	push	_523
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_TAssetManager_content]
	cmp	ebx,bbNullObject
	jne	_525
	call	brl_blitz_NullObjectError
_525:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
	cmp	eax,0
	je	_526
	push	_527
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_TAssetManager_content]
	cmp	ebx,bbNullObject
	jne	_529
	call	brl_blitz_NullObjectError
_529:
	push	bb_TAsset
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-20],eax
	push	_531
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_1
	push	dword [ebp-12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_532
	push	_533
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_535
	call	brl_blitz_NullObjectError
_535:
	push	dword [ebx+8]
	push	dword [ebp-12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_536
	push	_537
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	jmp	_125
_536:
	push	_539
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_31
	push	dword [ebp-12]
	push	_30
	push	dword [ebp-8]
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
	push	_540
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_31
	push	dword [ebp-12]
	push	_30
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	push	_541
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	jmp	_125
_532:
	push	_543
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	jmp	_125
_526:
	push	_545
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_547
	call	brl_blitz_NullObjectError
_547:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	_548
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_32
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	push	_549
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_32
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	push	_550
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	jmp	_125
_511:
	push	_551
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_TAssetManager_content]
	cmp	ebx,bbNullObject
	jne	_553
	call	brl_blitz_NullObjectError
_553:
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	mov	ebx,eax
	jmp	_125
_125:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetSprite:
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
	push	_564
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_556
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_557
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_559
	call	brl_blitz_NullObjectError
_559:
	mov	dword [ebx+8],1
	push	_561
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_563
	call	brl_blitz_NullObjectError
_563:
	push	bb_TGW_Sprites
	push	dword [ebp-12]
	push	_14
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_130
_130:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetMap:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_572
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_566
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_567
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_569
	call	brl_blitz_NullObjectError
_569:
	push	bb_TAsset
	push	_1
	push	_33
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_571
	call	brl_blitz_NullObjectError
_571:
	push	brl_map_TMap
	push	dword [ebx+12]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_134
_134:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetSpritePack:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_581
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_573
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_574
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_576
	call	brl_blitz_NullObjectError
_576:
	mov	dword [ebx+8],1
	push	_578
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_580
	call	brl_blitz_NullObjectError
_580:
	push	bb_TGW_SpritePack
	push	_1
	push	_34
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_138
_138:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetFont:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_586
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_582
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_583
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_585
	call	brl_blitz_NullObjectError
_585:
	push	brl_max2d_TImageFont
	push	_1
	push	_35
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_142
_142:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetImage:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_595
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_587
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_588
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_590
	call	brl_blitz_NullObjectError
_590:
	mov	dword [ebx+8],1
	push	_592
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_594
	call	brl_blitz_NullObjectError
_594:
	push	brl_max2d_TImage
	push	_1
	push	_1
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_146
_146:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetBigImage:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_604
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_596
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_597
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_599
	call	brl_blitz_NullObjectError
_599:
	mov	dword [ebx+8],1
	push	_601
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_603
	call	brl_blitz_NullObjectError
_603:
	push	bb_TBigImage
	push	_1
	push	_1
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_150
_150:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_276:
	dd	0
_166:
	db	"basefunctions_resourcemanager",0
_167:
	db	"APPEND_STATUS_CREATE",0
_39:
	db	"i",0
	align	4
_168:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	48
_169:
	db	"APPEND_STATUS_CREATEAFTER",0
	align	4
_170:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	49
_171:
	db	"APPEND_STATUS_ADDINZIP",0
	align	4
_172:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	50
_173:
	db	"Z_DEFLATED",0
	align	4
_174:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	56
_175:
	db	"Z_NO_COMPRESSION",0
_176:
	db	"Z_BEST_SPEED",0
_177:
	db	"Z_BEST_COMPRESSION",0
	align	4
_178:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	57
_179:
	db	"Z_DEFAULT_COMPRESSION",0
	align	4
_180:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,49
_181:
	db	"UNZ_CASE_CHECK",0
_182:
	db	"UNZ_NO_CASE_CHECK",0
_183:
	db	"UNZ_OK",0
_184:
	db	"UNZ_END_OF_LIST_OF_FILE",0
	align	4
_185:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,48
_186:
	db	"UNZ_EOF",0
_187:
	db	"UNZ_PARAMERROR",0
	align	4
_188:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,50
_189:
	db	"UNZ_BADZIPFILE",0
	align	4
_190:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,51
_191:
	db	"UNZ_INTERNALERROR",0
	align	4
_192:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,52
_193:
	db	"UNZ_CRCERROR",0
	align	4
_194:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,53
_195:
	db	"ZLIB_FILEFUNC_SEEK_CUR",0
_196:
	db	"ZLIB_FILEFUNC_SEEK_END",0
_197:
	db	"ZLIB_FILEFUNC_SEEK_SET",0
_198:
	db	"Z_OK",0
_199:
	db	"Z_STREAM_END",0
_200:
	db	"Z_NEED_DICT",0
_201:
	db	"Z_ERRNO",0
_202:
	db	"Z_STREAM_ERROR",0
	align	4
_203:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,50
_204:
	db	"Z_DATA_ERROR",0
	align	4
_205:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,51
_206:
	db	"Z_MEM_ERROR",0
	align	4
_207:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,52
_208:
	db	"Z_BUF_ERROR",0
	align	4
_209:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,53
_210:
	db	"Z_VERSION_ERROR",0
	align	4
_211:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,54
_212:
	db	"ZIP_INFO_IN_DATA_DESCRIPTOR",0
_213:
	db	"s",0
_214:
	db	"AS_CHILD",0
_215:
	db	"AS_SIBLING",0
_216:
	db	"FORMAT_XML",0
_217:
	db	"FORMAT_BINARY",0
_218:
	db	"SORTBY_NODE_NAME",0
_219:
	db	"SORTBY_NODE_VALUE",0
_220:
	db	"SORTBY_ATTR_NAME",0
	align	4
_221:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	51
_222:
	db	"SORTBY_ATTR_VALUE",0
	align	4
_223:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	52
_224:
	db	"KEY_STATE_NORMAL",0
_225:
	db	"KEY_STATE_HIT",0
_226:
	db	"KEY_STATE_DOWN",0
_227:
	db	"KEY_STATE_UP",0
_228:
	db	"KEYWRAP_ALLOW_HIT",0
_229:
	db	"KEYWRAP_ALLOW_HOLD",0
_230:
	db	"KEYWRAP_ALLOW_BOTH",0
_231:
	db	"MOUSEMANAGER",0
_232:
	db	":TMouseManager",0
_233:
	db	"KEYMANAGER",0
_234:
	db	":TKeyManager",0
_235:
	db	"KEYWRAPPER",0
_236:
	db	":TKeyWrapper",0
_237:
	db	"LoadSaveFile",0
_238:
	db	":TSaveFile",0
_239:
	db	"DEBUG_ALL",0
_240:
	db	"b",0
	align	4
_241:
	dd	bbStringClass
	dd	2147483646
	dd	3
	dw	49,50,56
_242:
	db	"DEBUG_SAVELOAD",0
	align	4
_243:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	54,52
_244:
	db	"DEBUG_NO",0
_245:
	db	"DEBUG_NETWORK",0
	align	4
_246:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	51,50
_247:
	db	"DEBUG_XML",0
	align	4
_248:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	49,54
_249:
	db	"DEBUG_LUA",0
_250:
	db	"DEBUG_LOADING",0
_251:
	db	"DEBUG_UPDATES",0
_252:
	db	"DEBUG_NEWS",0
_253:
	db	"DEBUG_START",0
_254:
	db	"DEBUG_IMAGES",0
	align	4
_255:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	53
_256:
	db	"LastSeekPos",0
_257:
	db	"functions",0
_258:
	db	":TFunctions",0
_259:
	db	"MINFRAGSIZE",0
_260:
	db	"MAXFRAGSIZE",0
	align	4
_261:
	dd	bbStringClass
	dd	2147483646
	dd	3
	dw	50,53,54
_262:
	db	"DDERR_INVALIDSURFACETYPE",0
	align	4
_263:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,48,48,53,53,51,50,48,56,48
_264:
	db	"DDERR_INVALIDPARAMS",0
	align	4
_265:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,49,52,55,48,50,52,56,48,57
_266:
	db	"DDERR_INVALIDOBJECT",0
	align	4
_267:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,48,48,53,53,51,50,53,52,50
_268:
	db	"DDERR_NOTFOUND",0
	align	4
_269:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,48,48,53,53,51,50,52,49,55
_270:
	db	"DDERR_SURFACELOST",0
	align	4
_271:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,48,48,53,53,51,50,50,50,50
_272:
	db	"tRenderERROR",0
_273:
	db	"$",0
_274:
	db	"Assets",0
_275:
	db	":TAssetManager",0
	align	4
bb_Assets:
	dd	bbNullObject
	align	4
_165:
	dd	1
	dd	_166
	dd	1
	dd	_167
	dd	_39
	dd	_168
	dd	1
	dd	_169
	dd	_39
	dd	_170
	dd	1
	dd	_171
	dd	_39
	dd	_172
	dd	1
	dd	_173
	dd	_39
	dd	_174
	dd	1
	dd	_175
	dd	_39
	dd	_168
	dd	1
	dd	_176
	dd	_39
	dd	_170
	dd	1
	dd	_177
	dd	_39
	dd	_178
	dd	1
	dd	_179
	dd	_39
	dd	_180
	dd	1
	dd	_181
	dd	_39
	dd	_170
	dd	1
	dd	_182
	dd	_39
	dd	_172
	dd	1
	dd	_183
	dd	_39
	dd	_168
	dd	1
	dd	_184
	dd	_39
	dd	_185
	dd	1
	dd	_186
	dd	_39
	dd	_168
	dd	1
	dd	_187
	dd	_39
	dd	_188
	dd	1
	dd	_189
	dd	_39
	dd	_190
	dd	1
	dd	_191
	dd	_39
	dd	_192
	dd	1
	dd	_193
	dd	_39
	dd	_194
	dd	1
	dd	_195
	dd	_39
	dd	_170
	dd	1
	dd	_196
	dd	_39
	dd	_172
	dd	1
	dd	_197
	dd	_39
	dd	_168
	dd	1
	dd	_198
	dd	_39
	dd	_168
	dd	1
	dd	_199
	dd	_39
	dd	_170
	dd	1
	dd	_200
	dd	_39
	dd	_172
	dd	1
	dd	_201
	dd	_39
	dd	_180
	dd	1
	dd	_202
	dd	_39
	dd	_203
	dd	1
	dd	_204
	dd	_39
	dd	_205
	dd	1
	dd	_206
	dd	_39
	dd	_207
	dd	1
	dd	_208
	dd	_39
	dd	_209
	dd	1
	dd	_210
	dd	_39
	dd	_211
	dd	1
	dd	_212
	dd	_213
	dd	_174
	dd	1
	dd	_214
	dd	_39
	dd	_170
	dd	1
	dd	_215
	dd	_39
	dd	_172
	dd	1
	dd	_216
	dd	_39
	dd	_170
	dd	1
	dd	_217
	dd	_39
	dd	_172
	dd	1
	dd	_218
	dd	_39
	dd	_170
	dd	1
	dd	_219
	dd	_39
	dd	_172
	dd	1
	dd	_220
	dd	_39
	dd	_221
	dd	1
	dd	_222
	dd	_39
	dd	_223
	dd	1
	dd	_224
	dd	_39
	dd	_168
	dd	1
	dd	_225
	dd	_39
	dd	_170
	dd	1
	dd	_226
	dd	_39
	dd	_172
	dd	1
	dd	_227
	dd	_39
	dd	_221
	dd	1
	dd	_228
	dd	_39
	dd	_170
	dd	1
	dd	_229
	dd	_39
	dd	_172
	dd	1
	dd	_230
	dd	_39
	dd	_221
	dd	4
	dd	_231
	dd	_232
	dd	bb_MOUSEMANAGER
	dd	4
	dd	_233
	dd	_234
	dd	bb_KEYMANAGER
	dd	4
	dd	_235
	dd	_236
	dd	bb_KEYWRAPPER
	dd	4
	dd	_237
	dd	_238
	dd	bb_LoadSaveFile
	dd	1
	dd	_239
	dd	_240
	dd	_241
	dd	1
	dd	_242
	dd	_240
	dd	_243
	dd	1
	dd	_244
	dd	_240
	dd	_168
	dd	1
	dd	_245
	dd	_240
	dd	_246
	dd	1
	dd	_247
	dd	_240
	dd	_248
	dd	1
	dd	_249
	dd	_240
	dd	_174
	dd	1
	dd	_250
	dd	_240
	dd	_223
	dd	1
	dd	_251
	dd	_240
	dd	_172
	dd	1
	dd	_252
	dd	_240
	dd	_170
	dd	1
	dd	_253
	dd	_240
	dd	_221
	dd	1
	dd	_254
	dd	_240
	dd	_255
	dd	4
	dd	_256
	dd	_39
	dd	bb_LastSeekPos
	dd	4
	dd	_257
	dd	_258
	dd	bb_functions
	dd	1
	dd	_259
	dd	_39
	dd	_243
	dd	1
	dd	_260
	dd	_39
	dd	_261
	dd	1
	dd	_262
	dd	_39
	dd	_263
	dd	1
	dd	_264
	dd	_39
	dd	_265
	dd	1
	dd	_266
	dd	_39
	dd	_267
	dd	1
	dd	_268
	dd	_39
	dd	_269
	dd	1
	dd	_270
	dd	_39
	dd	_271
	dd	4
	dd	_272
	dd	_273
	dd	bb_tRenderERROR
	dd	4
	dd	_274
	dd	_275
	dd	bb_Assets
	dd	0
_153:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_resourcemanager.bmx",0
	align	4
_152:
	dd	_153
	dd	17
	dd	2
	align	4
_154:
	dd	0
	align	4
_bb_TAssetManager_content:
	dd	bbNullObject
	align	4
_156:
	dd	_153
	dd	20
	dd	2
	align	4
_bb_TAssetManager_AssetsToLoad:
	dd	bbNullObject
	align	4
_158:
	dd	_153
	dd	23
	dd	2
	align	4
_bb_TAssetManager_AssetsLoadedLock:
	dd	bbNullObject
	align	4
_160:
	dd	_153
	dd	24
	dd	2
	align	4
_bb_TAssetManager_AssetsToLoadLock:
	dd	bbNullObject
	align	4
_162:
	dd	_153
	dd	25
	dd	2
	align	4
_bb_TAssetManager_AssetsLoadThread:
	dd	bbNullObject
_37:
	db	"TAssetManager",0
_38:
	db	"checkExistence",0
_40:
	db	"New",0
_41:
	db	"()i",0
_42:
	db	"LoadAssetsInThread",0
_43:
	db	"(:Object):Object",0
_44:
	db	"StartLoadingAssets",0
_45:
	db	"AddToLoadAsset",0
_46:
	db	"($,:Object)i",0
_47:
	db	"Create",0
_48:
	db	"(:brl.map.TMap,i):TAssetManager",0
_49:
	db	"AddSet",0
_50:
	db	"(:brl.map.TMap)i",0
_51:
	db	"PrintAssets",0
_52:
	db	"SetContent",0
_53:
	db	"Add",0
_54:
	db	"($,:TAsset,$)i",0
_55:
	db	"ConvertImageToSprite",0
_56:
	db	"(:brl.max2d.Timage,$,i):TGW_Sprites",0
_57:
	db	"AddImageAsSprite",0
_58:
	db	"($,:brl.max2d.TImage,i)i",0
_59:
	db	"GetObject",0
_60:
	db	"($,$,$):Object",0
_61:
	db	"GetSprite",0
_62:
	db	"($,$):TGW_Sprites",0
_63:
	db	"GetMap",0
_64:
	db	"($):brl.map.TMap",0
_65:
	db	"GetSpritePack",0
_66:
	db	"($):TGW_SpritePack",0
_67:
	db	"GetFont",0
_68:
	db	"($):brl.max2d.TImageFont",0
_69:
	db	"GetImage",0
_70:
	db	"($):brl.max2d.TImage",0
_71:
	db	"GetBigImage",0
_72:
	db	"($):TBigImage",0
	align	4
_36:
	dd	2
	dd	_37
	dd	3
	dd	_38
	dd	_39
	dd	8
	dd	6
	dd	_40
	dd	_41
	dd	16
	dd	7
	dd	_42
	dd	_43
	dd	48
	dd	6
	dd	_44
	dd	_41
	dd	52
	dd	6
	dd	_45
	dd	_46
	dd	56
	dd	7
	dd	_47
	dd	_48
	dd	60
	dd	6
	dd	_49
	dd	_50
	dd	64
	dd	6
	dd	_51
	dd	_41
	dd	68
	dd	6
	dd	_52
	dd	_50
	dd	72
	dd	6
	dd	_53
	dd	_54
	dd	76
	dd	7
	dd	_55
	dd	_56
	dd	80
	dd	6
	dd	_57
	dd	_58
	dd	84
	dd	6
	dd	_59
	dd	_60
	dd	88
	dd	6
	dd	_61
	dd	_62
	dd	92
	dd	6
	dd	_63
	dd	_64
	dd	96
	dd	6
	dd	_65
	dd	_66
	dd	100
	dd	6
	dd	_67
	dd	_68
	dd	104
	dd	6
	dd	_69
	dd	_70
	dd	108
	dd	6
	dd	_71
	dd	_72
	dd	112
	dd	0
	align	4
bb_TAssetManager:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_36
	dd	12
	dd	_bb_TAssetManager_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TAssetManager_LoadAssetsInThread
	dd	_bb_TAssetManager_StartLoadingAssets
	dd	_bb_TAssetManager_AddToLoadAsset
	dd	_bb_TAssetManager_Create
	dd	_bb_TAssetManager_AddSet
	dd	_bb_TAssetManager_PrintAssets
	dd	_bb_TAssetManager_SetContent
	dd	_bb_TAssetManager_Add
	dd	_bb_TAssetManager_ConvertImageToSprite
	dd	_bb_TAssetManager_AddImageAsSprite
	dd	_bb_TAssetManager_GetObject
	dd	_bb_TAssetManager_GetSprite
	dd	_bb_TAssetManager_GetMap
	dd	_bb_TAssetManager_GetSpritePack
	dd	_bb_TAssetManager_GetFont
	dd	_bb_TAssetManager_GetImage
	dd	_bb_TAssetManager_GetBigImage
	align	4
_163:
	dd	_153
	dd	14
	dd	1
_279:
	db	"Self",0
	align	4
_278:
	dd	1
	dd	_40
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	0
_322:
	db	"Input",0
_323:
	db	":Object",0
_324:
	db	"key",0
_325:
	db	"obj",0
_326:
	db	":TAsset",0
_327:
	db	"loadedObject",0
	align	4
_321:
	dd	1
	dd	_42
	dd	2
	dd	_322
	dd	_323
	dd	-4
	dd	2
	dd	_324
	dd	_273
	dd	-8
	dd	2
	dd	_325
	dd	_326
	dd	-12
	dd	2
	dd	_327
	dd	_326
	dd	-16
	dd	0
	align	4
_280:
	dd	_153
	dd	29
	dd	3
	align	4
_292:
	dd	_153
	dd	30
	dd	4
	align	4
_296:
	dd	_153
	dd	31
	dd	4
	align	4
_298:
	dd	_153
	dd	33
	dd	4
	align	4
_13:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	93
	align	4
_12:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	32,91
	align	4
_11:
	dd	bbStringClass
	dd	2147483647
	dd	20
	dw	76,111,97,100,65,115,115,101,116,115,73,110,84,104,114,101
	dw	97,100,58,32
	align	4
_303:
	dd	_153
	dd	37
	dd	4
	align	4
_14:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	83,80,82,73,84,69
	align	4
_307:
	dd	_153
	dd	37
	dd	37
	align	4
_308:
	dd	_153
	dd	38
	dd	4
	align	4
_15:
	dd	bbStringClass
	dd	2147483647
	dd	5
	dw	73,77,65,71,69
	align	4
_312:
	dd	_153
	dd	38
	dd	36
	align	4
_313:
	dd	_153
	dd	42
	dd	5
	align	4
_314:
	dd	_153
	dd	44
	dd	4
	align	4
_319:
	dd	_153
	dd	48
	dd	5
	align	4
_320:
	dd	_153
	dd	50
	dd	4
	align	4
_336:
	dd	1
	dd	_44
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	0
	align	4
_328:
	dd	_153
	dd	56
	dd	4
	align	4
_332:
	dd	_153
	dd	57
	dd	5
	align	4
_16:
	dd	bbStringClass
	dd	2147483647
	dd	25
	dw	32,45,32,45,32,45,32,45,32,45,32,45,32,45,32,45
	dw	32,45,32,45,32,45,32,45,32
	align	4
_333:
	dd	_153
	dd	58
	dd	5
	align	4
_17:
	dd	bbStringClass
	dd	2147483647
	dd	33
	dw	83,116,97,114,116,76,111,97,100,105,110,103,65,115,115,101
	dw	116,115,58,32,99,114,101,97,116,101,32,116,104,114,101,97
	dw	100
	align	4
_334:
	dd	_153
	dd	59
	dd	5
	align	4
_335:
	dd	_153
	dd	60
	dd	5
_344:
	db	"resourceName",0
_345:
	db	"resource",0
	align	4
_343:
	dd	1
	dd	_45
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_344
	dd	_273
	dd	-8
	dd	2
	dd	_345
	dd	_323
	dd	-12
	dd	0
	align	4
_337:
	dd	_153
	dd	69
	dd	3
	align	4
_340:
	dd	_153
	dd	70
	dd	3
_357:
	db	"initialContent",0
_358:
	db	":brl.map.TMap",0
	align	4
_356:
	dd	1
	dd	_47
	dd	2
	dd	_357
	dd	_358
	dd	-4
	dd	2
	dd	_38
	dd	_39
	dd	-8
	dd	2
	dd	_325
	dd	_275
	dd	-12
	dd	0
	align	4
_346:
	dd	_153
	dd	74
	dd	3
	align	4
_348:
	dd	_153
	dd	75
	dd	3
	align	4
_350:
	dd	_153
	dd	75
	dd	34
	align	4
_351:
	dd	_153
	dd	76
	dd	3
	align	4
_355:
	dd	_153
	dd	77
	dd	3
_394:
	db	"content",0
_395:
	db	"objType",0
	align	4
_393:
	dd	1
	dd	_49
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_394
	dd	_358
	dd	-8
	dd	2
	dd	_324
	dd	_323
	dd	-12
	dd	2
	dd	_325
	dd	_323
	dd	-16
	dd	2
	dd	_395
	dd	_273
	dd	-20
	dd	0
	align	4
_359:
	dd	_153
	dd	81
	dd	3
	align	4
_361:
	dd	_153
	dd	82
	dd	3
	align	4
_372:
	dd	_153
	dd	83
	dd	4
	align	4
_376:
	dd	_153
	dd	84
	dd	4
	align	4
_21:
	dd	bbStringClass
	dd	2147483647
	dd	7
	dw	85,78,75,78,79,87,78
	align	4
_378:
	dd	_153
	dd	85
	dd	4
	align	4
_380:
	dd	_153
	dd	86
	dd	5
	align	4
_388:
	dd	_153
	dd	88
	dd	5
_429:
	db	"res",0
_430:
	db	"count",0
	align	4
_428:
	dd	1
	dd	_51
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_429
	dd	_273
	dd	-8
	dd	2
	dd	_430
	dd	_39
	dd	-12
	dd	2
	dd	_324
	dd	_323
	dd	-16
	dd	2
	dd	_325
	dd	_323
	dd	-20
	dd	0
	align	4
_396:
	dd	_153
	dd	94
	dd	3
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_398:
	dd	_153
	dd	95
	dd	3
	align	4
_400:
	dd	_153
	dd	96
	dd	3
	align	4
_412:
	dd	_153
	dd	97
	dd	4
	align	4
_416:
	dd	_153
	dd	98
	dd	4
	align	4
_25:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	91
	align	4
_6:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	32
	align	4
_421:
	dd	_153
	dd	99
	dd	4
	align	4
_422:
	dd	_153
	dd	100
	dd	4
	align	4
_424:
	dd	_153
	dd	100
	dd	23
	align	4
_425:
	dd	_153
	dd	100
	dd	31
	align	4
_426:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	13
	align	4
_427:
	dd	_153
	dd	102
	dd	3
	align	4
_432:
	dd	1
	dd	_52
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_394
	dd	_358
	dd	-8
	dd	0
	align	4
_431:
	dd	_153
	dd	106
	dd	3
_456:
	db	"assetName",0
_457:
	db	"asset",0
_458:
	db	"assetType",0
	align	4
_455:
	dd	1
	dd	_53
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_456
	dd	_273
	dd	-8
	dd	2
	dd	_457
	dd	_326
	dd	-12
	dd	2
	dd	_458
	dd	_273
	dd	-16
	dd	0
	align	4
_433:
	dd	_153
	dd	110
	dd	3
	align	4
_434:
	dd	_153
	dd	111
	dd	3
	align	4
_438:
	dd	_153
	dd	112
	dd	4
	align	4
_442:
	dd	_153
	dd	113
	dd	5
	align	4
_446:
	dd	_153
	dd	114
	dd	6
	align	4
_26:
	dd	bbStringClass
	dd	2147483647
	dd	29
	dw	58,32,105,109,97,103,101,32,105,115,32,110,117,108,108,32
	dw	98,117,116,32,105,115,32,83,80,82,73,84,69
	align	4
_448:
	dd	_153
	dd	116
	dd	6
	align	4
_27:
	dd	bbStringClass
	dd	2147483647
	dd	15
	dw	58,32,105,109,97,103,101,32,105,115,32,110,117,108,108
	align	4
_449:
	dd	_153
	dd	119
	dd	4
	align	4
_452:
	dd	_153
	dd	122
	dd	3
_475:
	db	"img",0
_476:
	db	":brl.max2d.Timage",0
_477:
	db	"spriteName",0
_478:
	db	"spriteID",0
_479:
	db	"spritepack",0
_480:
	db	":TGW_SpritePack",0
	align	4
_474:
	dd	1
	dd	_55
	dd	2
	dd	_475
	dd	_476
	dd	-4
	dd	2
	dd	_477
	dd	_273
	dd	-8
	dd	2
	dd	_478
	dd	_39
	dd	-12
	dd	2
	dd	_479
	dd	_480
	dd	-16
	dd	0
	align	4
_459:
	dd	_153
	dd	126
	dd	3
	align	4
_28:
	dd	bbStringClass
	dd	2147483647
	dd	5
	dw	95,112,97,99,107
	align	4
_461:
	dd	_153
	dd	127
	dd	3
	align	4
_470:
	dd	_153
	dd	128
	dd	3
	align	4
_471:
	dd	_153
	dd	129
	dd	3
_503:
	db	":brl.max2d.TImage",0
_504:
	db	"animCount",0
_505:
	db	"result",0
_506:
	db	":TGW_Sprites",0
	align	4
_502:
	dd	1
	dd	_57
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_456
	dd	_273
	dd	-8
	dd	2
	dd	_475
	dd	_503
	dd	-12
	dd	2
	dd	_504
	dd	_39
	dd	-16
	dd	2
	dd	_505
	dd	_506
	dd	-20
	dd	0
	align	4
_481:
	dd	_153
	dd	133
	dd	3
	align	4
_483:
	dd	_153
	dd	134
	dd	4
	align	4
_29:
	dd	bbStringClass
	dd	2147483647
	dd	34
	dw	65,100,100,73,109,97,103,101,65,115,83,112,114,105,116,101
	dw	32,45,32,110,117,108,108,32,105,109,97,103,101,32,102,111
	dw	114,32
	align	4
_485:
	dd	_153
	dd	136
	dd	4
	align	4
_487:
	dd	_153
	dd	137
	dd	4
	align	4
_489:
	dd	_153
	dd	138
	dd	5
	align	4
_493:
	dd	_153
	dd	139
	dd	5
	align	4
_499:
	dd	_153
	dd	141
	dd	4
_555:
	db	"defaultAssetName",0
	align	4
_554:
	dd	1
	dd	_59
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_456
	dd	_273
	dd	-8
	dd	2
	dd	_458
	dd	_273
	dd	-12
	dd	2
	dd	_555
	dd	_273
	dd	-16
	dd	2
	dd	_505
	dd	_326
	dd	-20
	dd	0
	align	4
_507:
	dd	_153
	dd	148
	dd	3
	align	4
_508:
	dd	_153
	dd	149
	dd	3
	align	4
_512:
	dd	_153
	dd	150
	dd	4
	align	4
_522:
	dd	_153
	dd	151
	dd	5
	align	4
_523:
	dd	_153
	dd	153
	dd	4
	align	4
_527:
	dd	_153
	dd	154
	dd	5
	align	4
_531:
	dd	_153
	dd	155
	dd	5
	align	4
_533:
	dd	_153
	dd	156
	dd	6
	align	4
_537:
	dd	_153
	dd	157
	dd	7
	align	4
_539:
	dd	_153
	dd	160
	dd	7
	align	4
_31:
	dd	bbStringClass
	dd	2147483647
	dd	64
	dw	39,32,110,111,116,32,102,111,117,110,100,44,32,109,105,115
	dw	115,105,110,103,32,97,32,88,77,76,32,99,111,110,102,105
	dw	103,117,114,97,116,105,111,110,32,102,105,108,101,32,111,114
	dw	32,109,105,115,112,101,108,108,101,100,32,110,97,109,101,63
	align	4
_30:
	dd	bbStringClass
	dd	2147483647
	dd	12
	dw	32,119,105,116,104,32,116,121,112,101,32,39
	align	4
_540:
	dd	_153
	dd	161
	dd	7
	align	4
_541:
	dd	_153
	dd	162
	dd	7
	align	4
_543:
	dd	_153
	dd	165
	dd	6
	align	4
_545:
	dd	_153
	dd	169
	dd	5
	align	4
_548:
	dd	_153
	dd	170
	dd	5
	align	4
_32:
	dd	bbStringClass
	dd	2147483647
	dd	63
	dw	32,110,111,116,32,102,111,117,110,100,44,32,109,105,115,115
	dw	105,110,103,32,97,32,88,77,76,32,99,111,110,102,105,103
	dw	117,114,97,116,105,111,110,32,102,105,108,101,32,111,114,32
	dw	109,105,115,112,101,108,108,101,100,32,110,97,109,101,63
	align	4
_549:
	dd	_153
	dd	171
	dd	5
	align	4
_550:
	dd	_153
	dd	172
	dd	5
	align	4
_551:
	dd	_153
	dd	176
	dd	3
_565:
	db	"defaultName",0
	align	4
_564:
	dd	1
	dd	_61
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_456
	dd	_273
	dd	-8
	dd	2
	dd	_565
	dd	_273
	dd	-12
	dd	0
	align	4
_556:
	dd	_153
	dd	180
	dd	3
	align	4
_557:
	dd	_153
	dd	181
	dd	3
	align	4
_561:
	dd	_153
	dd	182
	dd	3
	align	4
_572:
	dd	1
	dd	_63
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_456
	dd	_273
	dd	-8
	dd	0
	align	4
_566:
	dd	_153
	dd	186
	dd	3
	align	4
_567:
	dd	_153
	dd	187
	dd	3
	align	4
_33:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	84,77,65,80
	align	4
_581:
	dd	1
	dd	_65
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_456
	dd	_273
	dd	-8
	dd	0
	align	4
_573:
	dd	_153
	dd	191
	dd	3
	align	4
_574:
	dd	_153
	dd	192
	dd	3
	align	4
_578:
	dd	_153
	dd	193
	dd	3
	align	4
_34:
	dd	bbStringClass
	dd	2147483647
	dd	10
	dw	83,80,82,73,84,69,80,65,67,75
	align	4
_586:
	dd	1
	dd	_67
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_456
	dd	_273
	dd	-8
	dd	0
	align	4
_582:
	dd	_153
	dd	197
	dd	3
	align	4
_583:
	dd	_153
	dd	198
	dd	3
	align	4
_35:
	dd	bbStringClass
	dd	2147483647
	dd	9
	dw	73,77,65,71,69,70,79,78,84
	align	4
_595:
	dd	1
	dd	_69
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_456
	dd	_273
	dd	-8
	dd	0
	align	4
_587:
	dd	_153
	dd	202
	dd	3
	align	4
_588:
	dd	_153
	dd	203
	dd	3
	align	4
_592:
	dd	_153
	dd	204
	dd	3
	align	4
_604:
	dd	1
	dd	_71
	dd	2
	dd	_279
	dd	_275
	dd	-4
	dd	2
	dd	_456
	dd	_273
	dd	-8
	dd	0
	align	4
_596:
	dd	_153
	dd	208
	dd	3
	align	4
_597:
	dd	_153
	dd	209
	dd	3
	align	4
_601:
	dd	_153
	dd	210
	dd	3
