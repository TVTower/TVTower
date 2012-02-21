	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_max2d_max2d
	extrn	__bb_random_random
	extrn	__bb_reflection_reflection
	extrn	__bb_source_basefunctions_image
	extrn	__bb_source_basefunctions_sprites
	extrn	__bb_source_basefunctions_xml
	extrn	bbEmptyString
	extrn	bbExThrow
	extrn	bbFloatToInt
	extrn	bbGCCollect
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
	extrn	bb_TAsset
	extrn	bb_TBigImage
	extrn	bb_TGW_SpritePack
	extrn	bb_TGW_Sprites
	extrn	brl_map_CreateMap
	extrn	brl_map_TMap
	extrn	brl_max2d_TImage
	extrn	brl_max2d_TImageFont
	extrn	brl_retro_Lower
	extrn	brl_standardio_Print
	public	__bb_source_basefunctions_resourcemanager
	public	_bb_TAssetManager_Add
	public	_bb_TAssetManager_AddImageAsSprite
	public	_bb_TAssetManager_AddSet
	public	_bb_TAssetManager_AddToLoadAsset
	public	_bb_TAssetManager_AssetsToLoad
	public	_bb_TAssetManager_ConvertImageToSprite
	public	_bb_TAssetManager_Create
	public	_bb_TAssetManager_Delete
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
	cmp	dword [_161],0
	je	_162
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_162:
	mov	dword [_161],1
	call	__bb_blitz_blitz
	call	__bb_max2d_max2d
	call	__bb_random_random
	call	__bb_reflection_reflection
	call	__bb_source_basefunctions_xml
	call	__bb_source_basefunctions_image
	call	__bb_source_basefunctions_sprites
	mov	eax,dword [_155]
	and	eax,1
	cmp	eax,0
	jne	_156
	call	brl_map_CreateMap
	inc	dword [eax+4]
	mov	dword [_bb_TAssetManager_content],eax
	or	dword [_155],1
_156:
	mov	eax,dword [_155]
	and	eax,2
	cmp	eax,0
	jne	_158
	call	brl_map_CreateMap
	inc	dword [eax+4]
	mov	dword [_bb_TAssetManager_AssetsToLoad],eax
	or	dword [_155],2
_158:
	push	bb_TAssetManager
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,dword [_155]
	and	eax,4
	cmp	eax,0
	jne	_160
	push	1
	push	bbNullObject
	call	dword [bb_TAssetManager+60]
	add	esp,8
	inc	dword [eax+4]
	mov	dword [bb_Assets],eax
	or	dword [_155],4
_160:
	mov	eax,0
	jmp	_72
_72:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TAssetManager
	mov	dword [ebx+8],0
	mov	eax,0
	jmp	_75
_75:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_Delete:
	push	ebp
	mov	ebp,esp
_78:
	mov	eax,0
	jmp	_163
_163:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_LoadAssetsInThread:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [_bb_TAssetManager_AssetsToLoad]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	dword [ebp-8],eax
	jmp	_8
_10:
	mov	eax,dword [ebp-8]
	push	bbStringClass
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_8
	mov	edx,dword [_bb_TAssetManager_AssetsToLoad]
	push	bb_TAsset
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	mov	edi,bbNullObject
	mov	ebx,esi
	mov	eax,esi
	push	_13
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	push	eax
	push	_12
	push	ebx
	mov	eax,dword [ebx]
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
	mov	eax,esi
	push	_14
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_177
	push	esi
	call	dword [bb_TGW_Sprites+88]
	add	esp,4
	mov	edi,eax
_177:
	mov	eax,esi
	push	_15
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_179
	push	esi
	call	dword [bb_TGW_Sprites+88]
	add	esp,4
	mov	edi,eax
_179:
	mov	ebx,dword [_bb_TAssetManager_content]
	mov	eax,esi
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	call	bbGCCollect
_8:
	mov	eax,dword [ebp-8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_10
_9:
	mov	eax,bbNullObject
	jmp	_81
_81:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_StartLoadingAssets:
	push	ebp
	mov	ebp,esp
	push	bbNullObject
	call	dword [bb_TAssetManager+48]
	add	esp,4
	mov	eax,0
	jmp	_84
_84:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_AddToLoadAsset:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	ecx,dword [ebp+12]
	mov	edx,dword [ebp+16]
	mov	eax,dword [_bb_TAssetManager_AssetsToLoad]
	push	edx
	push	ecx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,12
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	eax,0
	jmp	_89
_89:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_Create:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	push	bb_TAssetManager
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	cmp	esi,bbNullObject
	je	_185
	mov	eax,esi
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [_bb_TAssetManager_content]
	dec	dword [eax+4]
	jnz	_189
	push	eax
	call	bbGCFree
	add	esp,4
_189:
	mov	dword [_bb_TAssetManager_content],esi
_185:
	mov	dword [ebx+8],edi
	mov	eax,ebx
	jmp	_93
_93:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_AddSet:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp-8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	dword [ebp-12],eax
	jmp	_16
_18:
	mov	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_16
	mov	eax,dword [ebp+12]
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-4],eax
	mov	edi,_19
	push	bb_TAsset
	push	dword [ebp-4]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_200
	push	bbStringClass
	push	esi
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	jne	_203
	mov	esi,bbEmptyString
_203:
	push	bb_TAsset
	push	dword [ebp-4]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+8]
	push	bb_TAsset
	push	dword [ebp-4]
	call	bbObjectDowncast
	add	esp,8
	push	eax
	push	esi
	call	brl_retro_Lower
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,16
	jmp	_204
_200:
	push	bbStringClass
	push	esi
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	jne	_207
	mov	esi,bbEmptyString
_207:
	push	edi
	push	edi
	push	dword [ebp-4]
	call	dword [bb_TAsset+48]
	add	esp,8
	push	eax
	push	esi
	call	brl_retro_Lower
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,16
_204:
_16:
	mov	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_18
_17:
	mov	eax,0
	jmp	_97
_97:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_PrintAssets:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	dword [ebp-4],_1
	mov	edi,0
	mov	eax,dword [_bb_TAssetManager_content]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp-8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	dword [ebp-12],eax
	jmp	_20
_22:
	mov	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_20
	mov	eax,dword [_bb_TAssetManager_content]
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	mov	ebx,eax
	push	bbStringClass
	push	esi
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	jne	_220
	mov	esi,bbEmptyString
_220:
	push	_13
	push	bb_TAsset
	push	ebx
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+8]
	push	_23
	push	esi
	push	_6
	push	dword [ebp-4]
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
	mov	dword [ebp-4],eax
	add	edi,1
	cmp	edi,5
	jl	_221
	mov	edi,0
	push	_222
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_221:
_20:
	mov	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_22
_21:
	push	dword [ebp-4]
	call	brl_standardio_Print
	add	esp,4
	mov	eax,0
	jmp	_100
_100:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_SetContent:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+12]
	inc	dword [ebx+4]
	mov	eax,dword [_bb_TAssetManager_content]
	dec	dword [eax+4]
	jnz	_226
	push	eax
	call	bbGCFree
	add	esp,4
_226:
	mov	dword [_bb_TAssetManager_content],ebx
	mov	eax,0
	jmp	_104
_104:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_Add:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	push	esi
	call	brl_retro_Lower
	add	esp,4
	mov	esi,eax
	push	_15
	push	dword [ebx+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_227
	push	brl_max2d_TImage
	push	dword [ebx+12]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_228
	push	bb_TGW_Sprites
	push	dword [ebx+12]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_229
	push	_24
	push	esi
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	jmp	_230
_229:
	push	_25
	push	esi
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
_230:
_228:
	push	-1
	push	esi
	push	brl_max2d_TImage
	push	dword [ebx+12]
	call	bbObjectDowncast
	add	esp,8
	push	eax
	mov	eax,dword [edi]
	call	dword [eax+80]
	add	esp,12
	mov	ebx,eax
_227:
	mov	eax,dword [_bb_TAssetManager_content]
	push	ebx
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,12
	mov	eax,0
	jmp	_110
_110:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_ConvertImageToSprite:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	push	_26
	push	ebx
	call	bbStringConcat
	add	esp,8
	push	eax
	push	esi
	call	dword [bb_TGW_SpritePack+84]
	add	esp,8
	mov	edi,eax
	mov	eax,edi
	push	dword [ebp+16]
	mov	edx,dword [esi+44]
	push	dword [edx+20]
	push	dword [esi+12]
	push	dword [esi+8]
	push	0
	push	0
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+104]
	add	esp,32
	call	bbGCCollect
	mov	eax,edi
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+96]
	add	esp,8
	jmp	_115
_115:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_AddImageAsSprite:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edx,dword [ebp+8]
	mov	edi,dword [ebp+12]
	mov	eax,dword [ebp+16]
	mov	esi,dword [ebp+20]
	cmp	eax,bbNullObject
	jne	_235
	push	edi
	push	_27
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	jmp	_236
_235:
	push	-1
	push	edi
	push	eax
	mov	eax,dword [edx]
	call	dword [eax+80]
	add	esp,12
	mov	ebx,eax
	cmp	esi,0
	jle	_238
	mov	dword [ebx+56],esi
	fld	dword [ebx+40]
	mov	dword [ebp+-4],esi
	fild	dword [ebp+-4]
	fdivp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	dword [ebx+48],eax
_238:
	mov	eax,dword [_bb_TAssetManager_content]
	push	ebx
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,12
_236:
	mov	eax,0
	jmp	_121
_121:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetObject:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+12]
	mov	edi,dword [ebp+20]
	push	esi
	call	brl_retro_Lower
	add	esp,4
	mov	esi,eax
	mov	eax,dword [ebp+8]
	cmp	dword [eax+8],0
	je	_240
	mov	eax,dword [_bb_TAssetManager_content]
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_242
	push	_1
	push	edi
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
_242:
	cmp	eax,0
	je	_245
	mov	ebx,dword [_bb_TAssetManager_content]
	push	edi
	call	brl_retro_Lower
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
_245:
	cmp	eax,0
	je	_247
	push	edi
	call	brl_retro_Lower
	add	esp,4
	mov	esi,eax
_247:
	mov	eax,dword [_bb_TAssetManager_content]
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	cmp	eax,0
	je	_249
	mov	eax,dword [_bb_TAssetManager_content]
	push	bb_TAsset
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	push	_1
	push	dword [ebp+16]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_252
	push	dword [ebx+8]
	push	dword [ebp+16]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_253
	jmp	_127
_253:
	push	_29
	push	dword [ebp+16]
	push	_28
	push	esi
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
	push	_29
	push	dword [ebp+16]
	push	_28
	push	esi
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
	mov	ebx,bbNullObject
	jmp	_127
_252:
	jmp	_127
_249:
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	push	_30
	push	esi
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_standardio_Print
	add	esp,4
	push	_30
	push	esi
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	mov	ebx,bbNullObject
	jmp	_127
_240:
	mov	eax,dword [_bb_TAssetManager_content]
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	mov	ebx,eax
	jmp	_127
_127:
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetSprite:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	esi,dword [ebp+16]
	push	eax
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebx+8],1
	push	bb_TGW_Sprites
	push	esi
	push	_14
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_132
_132:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetMap:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	eax
	call	brl_retro_Lower
	add	esp,4
	push	brl_map_TMap
	push	bb_TAsset
	push	_1
	push	_31
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+12]
	call	bbObjectDowncast
	add	esp,8
	jmp	_136
_136:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetSpritePack:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	eax
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebx+8],1
	push	bb_TGW_SpritePack
	push	_1
	push	_32
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_140
_140:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetFont:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	eax
	call	brl_retro_Lower
	add	esp,4
	push	brl_max2d_TImageFont
	push	_1
	push	_33
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_144
_144:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetImage:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	eax
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebx+8],1
	push	brl_max2d_TImage
	push	_1
	push	_1
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_148
_148:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAssetManager_GetBigImage:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	eax
	call	brl_retro_Lower
	add	esp,4
	mov	dword [ebx+8],1
	push	bb_TBigImage
	push	_1
	push	_1
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,16
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_152
_152:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_161:
	dd	0
	align	4
_155:
	dd	0
	align	4
_bb_TAssetManager_content:
	dd	bbNullObject
	align	4
_bb_TAssetManager_AssetsToLoad:
	dd	bbNullObject
_35:
	db	"TAssetManager",0
_36:
	db	"checkExistence",0
_37:
	db	"i",0
_38:
	db	"New",0
_39:
	db	"()i",0
_40:
	db	"Delete",0
_41:
	db	"LoadAssetsInThread",0
_42:
	db	"(:Object):Object",0
_43:
	db	"StartLoadingAssets",0
_44:
	db	"AddToLoadAsset",0
_45:
	db	"($,:Object)i",0
_46:
	db	"Create",0
_47:
	db	"(:brl.map.TMap,i):TAssetManager",0
_48:
	db	"AddSet",0
_49:
	db	"(:brl.map.TMap)i",0
_50:
	db	"PrintAssets",0
_51:
	db	"SetContent",0
_52:
	db	"Add",0
_53:
	db	"($,:TAsset,$)i",0
_54:
	db	"ConvertImageToSprite",0
_55:
	db	"(:brl.max2d.Timage,$,i):TGW_Sprites",0
_56:
	db	"AddImageAsSprite",0
_57:
	db	"($,:brl.max2d.TImage,i)i",0
_58:
	db	"GetObject",0
_59:
	db	"($,$,$):Object",0
_60:
	db	"GetSprite",0
_61:
	db	"($,$):TGW_Sprites",0
_62:
	db	"GetMap",0
_63:
	db	"($):brl.map.TMap",0
_64:
	db	"GetSpritePack",0
_65:
	db	"($):TGW_SpritePack",0
_66:
	db	"GetFont",0
_67:
	db	"($):brl.max2d.TImageFont",0
_68:
	db	"GetImage",0
_69:
	db	"($):brl.max2d.TImage",0
_70:
	db	"GetBigImage",0
_71:
	db	"($):TBigImage",0
	align	4
_34:
	dd	2
	dd	_35
	dd	3
	dd	_36
	dd	_37
	dd	8
	dd	6
	dd	_38
	dd	_39
	dd	16
	dd	6
	dd	_40
	dd	_39
	dd	20
	dd	7
	dd	_41
	dd	_42
	dd	48
	dd	6
	dd	_43
	dd	_39
	dd	52
	dd	6
	dd	_44
	dd	_45
	dd	56
	dd	7
	dd	_46
	dd	_47
	dd	60
	dd	6
	dd	_48
	dd	_49
	dd	64
	dd	6
	dd	_50
	dd	_39
	dd	68
	dd	6
	dd	_51
	dd	_49
	dd	72
	dd	6
	dd	_52
	dd	_53
	dd	76
	dd	7
	dd	_54
	dd	_55
	dd	80
	dd	6
	dd	_56
	dd	_57
	dd	84
	dd	6
	dd	_58
	dd	_59
	dd	88
	dd	6
	dd	_60
	dd	_61
	dd	92
	dd	6
	dd	_62
	dd	_63
	dd	96
	dd	6
	dd	_64
	dd	_65
	dd	100
	dd	6
	dd	_66
	dd	_67
	dd	104
	dd	6
	dd	_68
	dd	_69
	dd	108
	dd	6
	dd	_70
	dd	_71
	dd	112
	dd	0
	align	4
bb_TAssetManager:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_34
	dd	12
	dd	_bb_TAssetManager_New
	dd	_bb_TAssetManager_Delete
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
bb_Assets:
	dd	bbNullObject
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
_14:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	83,80,82,73,84,69
	align	4
_15:
	dd	bbStringClass
	dd	2147483647
	dd	5
	dw	73,77,65,71,69
	align	4
_19:
	dd	bbStringClass
	dd	2147483647
	dd	7
	dw	85,78,75,78,79,87,78
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_23:
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
_222:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	13
	align	4
_24:
	dd	bbStringClass
	dd	2147483647
	dd	29
	dw	58,32,105,109,97,103,101,32,105,115,32,110,117,108,108,32
	dw	98,117,116,32,105,115,32,83,80,82,73,84,69
	align	4
_25:
	dd	bbStringClass
	dd	2147483647
	dd	15
	dw	58,32,105,109,97,103,101,32,105,115,32,110,117,108,108
	align	4
_26:
	dd	bbStringClass
	dd	2147483647
	dd	5
	dw	95,112,97,99,107
	align	4
_27:
	dd	bbStringClass
	dd	2147483647
	dd	34
	dw	65,100,100,73,109,97,103,101,65,115,83,112,114,105,116,101
	dw	32,45,32,110,117,108,108,32,105,109,97,103,101,32,102,111
	dw	114,32
	align	4
_29:
	dd	bbStringClass
	dd	2147483647
	dd	64
	dw	39,32,110,111,116,32,102,111,117,110,100,44,32,109,105,115
	dw	115,105,110,103,32,97,32,88,77,76,32,99,111,110,102,105
	dw	103,117,114,97,116,105,111,110,32,102,105,108,101,32,111,114
	dw	32,109,105,115,112,101,108,108,101,100,32,110,97,109,101,63
	align	4
_28:
	dd	bbStringClass
	dd	2147483647
	dd	12
	dw	32,119,105,116,104,32,116,121,112,101,32,39
	align	4
_30:
	dd	bbStringClass
	dd	2147483647
	dd	63
	dw	32,110,111,116,32,102,111,117,110,100,44,32,109,105,115,115
	dw	105,110,103,32,97,32,88,77,76,32,99,111,110,102,105,103
	dw	117,114,97,116,105,111,110,32,102,105,108,101,32,111,114,32
	dw	109,105,115,112,101,108,108,101,100,32,110,97,109,101,63
	align	4
_31:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	84,77,65,80
	align	4
_32:
	dd	bbStringClass
	dd	2147483647
	dd	10
	dw	83,80,82,73,84,69,80,65,67,75
	align	4
_33:
	dd	bbStringClass
	dd	2147483647
	dd	9
	dw	73,77,65,71,69,70,79,78,84
