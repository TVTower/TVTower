	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_map_map
	extrn	__bb_retro_retro
	extrn	bbEmptyString
	extrn	bbExThrow
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
	extrn	bbStringTrim
	extrn	brl_blitz_NullMethodError
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
	public	_bb_LocalizationResource_Delete
	public	_bb_LocalizationResource_New
	public	_bb_LocalizationStreamingResource_Close
	public	_bb_LocalizationStreamingResource_Delete
	public	_bb_LocalizationStreamingResource_GetString
	public	_bb_LocalizationStreamingResource_New
	public	_bb_LocalizationStreamingResource_open
	public	_bb_Localization_AddLanguages
	public	_bb_Localization_Delete
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
	cmp	dword [_175],0
	je	_176
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_176:
	mov	dword [_175],1
	call	__bb_blitz_blitz
	call	__bb_retro_retro
	call	__bb_map_map
	call	__bb_glmax2d_glmax2d
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
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [_bb_Localization_Resources]
	dec	dword [eax+4]
	jnz	_170
	push	eax
	call	bbGCFree
	add	esp,4
_170:
	mov	dword [_bb_Localization_Resources],ebx
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [_bb_Localization_supportedLanguages]
	dec	dword [eax+4]
	jnz	_174
	push	eax
	call	bbGCFree
	add	esp,4
_174:
	mov	dword [_bb_Localization_supportedLanguages],ebx
	mov	eax,0
	jmp	_85
_85:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_Localization
	mov	eax,0
	jmp	_88
_88:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_Delete:
	push	ebp
	mov	ebp,esp
_91:
	mov	eax,0
	jmp	_177
_177:
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_SetLanguage:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [_bb_Localization_supportedLanguages]
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_3
_5:
	mov	eax,ebx
	push	bbStringClass
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_3
	push	eax
	push	edi
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_184
	mov	ebx,edi
	inc	dword [ebx+4]
	mov	eax,dword [_bb_Localization_currentLanguage]
	dec	dword [eax+4]
	jnz	_188
	push	eax
	call	bbGCFree
	add	esp,4
_188:
	mov	dword [_bb_Localization_currentLanguage],ebx
	mov	eax,1
	jmp	_94
_184:
_3:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_5
_4:
	mov	eax,0
	jmp	_94
_94:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_Language:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [_bb_Localization_currentLanguage]
	jmp	_96
_96:
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_AddLanguages:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	push	1
	push	_6
	push	esi
	call	brl_retro_Instr
	add	esp,12
	mov	edi,eax
	cmp	edi,0
	jne	_190
	mov	ebx,dword [_bb_Localization_supportedLanguages]
	push	esi
	call	bbStringTrim
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	mov	eax,0
	jmp	_99
_190:
	jmp	_7
_9:
	mov	ebx,dword [_bb_Localization_supportedLanguages]
	mov	eax,edi
	sub	eax,1
	push	eax
	push	esi
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
	push	-1
	mov	eax,edi
	add	eax,1
	push	eax
	push	esi
	call	brl_retro_Mid
	add	esp,12
	mov	esi,eax
	push	1
	push	_6
	push	esi
	call	brl_retro_Instr
	add	esp,12
	mov	edi,eax
_7:
	cmp	edi,0
	jg	_9
_8:
	mov	ebx,dword [_bb_Localization_supportedLanguages]
	push	esi
	call	bbStringTrim
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	mov	eax,0
	jmp	_99
_99:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_OpenResource:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	bbEmptyString
	push	eax
	call	dword [bb_LocalizationStreamingResource+56]
	add	esp,8
	mov	eax,0
	jmp	_102
_102:
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_LoadResource:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	bbEmptyString
	push	eax
	call	dword [bb_LocalizationMemoryResource+56]
	add	esp,8
	mov	eax,0
	jmp	_105
_105:
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_OpenResources:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	push	eax
	call	dword [bb_Localization+84]
	add	esp,4
	mov	esi,eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_10
_12:
	push	bbStringClass
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_10
	push	eax
	call	dword [bb_Localization+60]
	add	esp,4
_10:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_12
_11:
	mov	eax,0
	jmp	_108
_108:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_LoadResources:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	push	eax
	call	dword [bb_Localization+84]
	add	esp,4
	mov	esi,eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_13
_15:
	push	bbStringClass
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_13
	push	eax
	call	dword [bb_Localization+64]
	add	esp,4
_13:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_15
_14:
	mov	eax,0
	jmp	_111
_111:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_GetString:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,_1
	mov	edi,dword [_bb_Localization_Resources]
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-4],eax
	jmp	_16
_18:
	mov	eax,dword [ebp-4]
	push	bb_LocalizationResource
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	je	_16
	push	dword [_bb_Localization_currentLanguage]
	push	dword [ebx+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_213
	jmp	_16
_213:
	mov	eax,ebx
	push	dword [ebp+12]
	push	dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	esi,eax
	push	bbEmptyString
	push	esi
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_215
	mov	eax,esi
	jmp	_115
_215:
_16:
	mov	eax,dword [ebp-4]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_18
_17:
	mov	eax,esi
	jmp	_115
_115:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_GetLanguageFromFilename:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,0
	push	1
	push	_19
	push	esi
	call	brl_retro_Instr
	add	esp,12
	jmp	_20
_22:
	mov	ebx,eax
	mov	eax,ebx
	add	eax,1
	push	eax
	push	_19
	push	esi
	call	brl_retro_Instr
	add	esp,12
_20:
	cmp	eax,0
	jg	_22
_21:
	cmp	ebx,0
	jle	_218
	mov	eax,ebx
	add	eax,1
	push	eax
	push	_19
	push	esi
	call	brl_retro_Instr
	add	esp,12
	cmp	eax,0
	jle	_219
	sub	eax,ebx
	sub	eax,1
	push	eax
	add	ebx,1
	push	ebx
	push	esi
	call	brl_retro_Mid
	add	esp,12
	jmp	_118
_219:
	mov	eax,ebx
	add	eax,1
	push	eax
	push	_23
	push	esi
	call	brl_retro_Instr
	add	esp,12
	cmp	eax,0
	jle	_220
	sub	eax,ebx
	sub	eax,1
	push	eax
	add	ebx,1
	push	ebx
	push	esi
	call	brl_retro_Mid
	add	esp,12
	jmp	_118
_220:
	push	-1
	add	ebx,1
	push	ebx
	push	esi
	call	brl_retro_Mid
	add	esp,12
	jmp	_118
_218:
	mov	eax,bbEmptyString
	jmp	_118
_118:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_GetResourceFiles:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-24],eax
	push	1
	push	_24
	push	esi
	call	brl_retro_Instr
	add	esp,12
	mov	ebx,eax
	cmp	ebx,0
	jle	_223
	mov	eax,ebx
	sub	eax,1
	push	eax
	push	esi
	call	brl_retro_Left
	add	esp,8
	mov	dword [ebp-8],eax
	push	-1
	add	ebx,1
	push	ebx
	push	esi
	call	brl_retro_Mid
	add	esp,12
	mov	dword [ebp-12],eax
	push	esi
	call	brl_filesystem_ExtractDir
	add	esp,4
	mov	dword [ebp-20],eax
	push	1
	push	dword [ebp-20]
	call	brl_filesystem_LoadDir
	add	esp,8
	mov	ebx,eax
	push	-1
	mov	eax,dword [ebp-20]
	mov	eax,dword [eax+8]
	add	eax,1
	push	eax
	push	dword [ebp-8]
	call	brl_retro_Mid
	add	esp,12
	mov	dword [ebp-8],eax
	push	_25
	push	1
	push	dword [ebp-8]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_228
	push	_26
	push	1
	push	dword [ebp-8]
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_228:
	cmp	eax,0
	je	_230
	push	-1
	push	2
	push	dword [ebp-8]
	call	brl_retro_Mid
	add	esp,12
	mov	dword [ebp-8],eax
_230:
	mov	dword [ebp-4],ebx
	mov	eax,dword [ebp-4]
	add	eax,24
	mov	edi,eax
	mov	edx,edi
	mov	eax,dword [ebp-4]
	add	edx,dword [eax+16]
	mov	dword [ebp-16],edx
	jmp	_27
_29:
	mov	esi,dword [edi]
	add	edi,4
	cmp	esi,bbNullObject
	je	_27
	mov	edx,dword [esi+8]
	mov	eax,dword [ebp-8]
	cmp	edx,dword [eax+8]
	setge	al
	movzx	eax,al
	cmp	eax,0
	je	_236
	push	dword [ebp-8]
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	push	esi
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_236:
	cmp	eax,0
	je	_238
	mov	eax,dword [esi+8]
	mov	edx,dword [ebp-8]
	mov	ecx,dword [edx+8]
	mov	edx,dword [ebp-12]
	add	ecx,dword [edx+8]
	cmp	eax,ecx
	setge	al
	movzx	eax,al
	cmp	eax,0
	je	_239
	push	dword [ebp-12]
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	push	esi
	call	brl_retro_Right
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_239:
	cmp	eax,0
	je	_241
	mov	ebx,dword [ebp-24]
	push	esi
	push	_25
	push	dword [ebp-20]
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
_241:
_238:
_27:
	cmp	edi,dword [ebp-16]
	jne	_29
_28:
_223:
	mov	eax,dword [ebp-24]
	jmp	_121
_121:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_Localization_Dispose:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [_bb_Localization_Resources]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_30
_32:
	push	bb_LocalizationResource
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_30
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
_30:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_32
_31:
	mov	eax,dword [_bb_Localization_Resources]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	ebx,bbNullObject
	inc	dword [ebx+4]
	mov	eax,dword [_bb_Localization_Resources]
	dec	dword [eax+4]
	jnz	_254
	push	eax
	call	bbGCFree
	add	esp,4
_254:
	mov	dword [_bb_Localization_Resources],ebx
	mov	ebx,bbNullObject
	inc	dword [ebx+4]
	mov	eax,dword [_bb_Localization_supportedLanguages]
	dec	dword [eax+4]
	jnz	_258
	push	eax
	call	bbGCFree
	add	esp,4
_258:
	mov	dword [_bb_Localization_supportedLanguages],ebx
	mov	eax,0
	jmp	_123
_123:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationResource_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_LocalizationResource
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	eax,0
	jmp	_126
_126:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationResource_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_129:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_263
	push	eax
	call	bbGCFree
	add	esp,4
_263:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_265
	push	eax
	call	bbGCFree
	add	esp,4
_265:
	mov	eax,0
	jmp	_261
_261:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationStreamingResource_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_LocalizationResource_New
	add	esp,4
	mov	dword [ebx],bb_LocalizationStreamingResource
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	eax,0
	jmp	_132
_132:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationStreamingResource_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
_135:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_270
	push	eax
	call	bbGCFree
	add	esp,4
_270:
	mov	dword [ebx],bb_LocalizationResource
	push	ebx
	call	_bb_LocalizationResource_Delete
	add	esp,4
	mov	eax,0
	jmp	_268
_268:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationStreamingResource_open:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	mov	esi,dword [ebp+12]
	push	bbEmptyString
	push	esi
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_271
	push	ebx
	call	dword [bb_Localization+80]
	add	esp,4
	mov	esi,eax
	push	bbEmptyString
	push	esi
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_272
	push	_33
	call	bbExThrow
	add	esp,4
_272:
_271:
	push	ebx
	call	brl_filesystem_ReadFile
	add	esp,4
	mov	edi,eax
	cmp	edi,bbNullObject
	jne	_274
	push	_35
	push	ebx
	push	_34
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_274:
	push	bb_LocalizationStreamingResource
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,esi
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_279
	push	eax
	call	bbGCFree
	add	esp,4
_279:
	mov	dword [ebx+8],esi
	mov	esi,edi
	inc	dword [esi+4]
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_283
	push	eax
	call	bbGCFree
	add	esp,4
_283:
	mov	dword [ebx+16],esi
	mov	eax,dword [_bb_Localization_Resources]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_288
	push	eax
	call	bbGCFree
	add	esp,4
_288:
	mov	dword [ebx+12],esi
	mov	eax,bbNullObject
	jmp	_139
_139:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationStreamingResource_GetString:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	jne	_289
	mov	eax,bbEmptyString
	jmp	_144
_289:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	push	0
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	mov	dword [ebp-4],bbEmptyString
	mov	dword [ebp-8],bbEmptyString
	mov	edi,0
	jmp	_36
_38:
	mov	eax,dword [ebp+8]
	push	dword [eax+16]
	call	brl_stream_ReadLine
	add	esp,4
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	esi,eax
	push	bbEmptyString
	push	dword [ebp+16]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_296
	mov	eax,edi
	cmp	eax,0
	je	_297
	push	_39
	push	1
	push	esi
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
_297:
	cmp	eax,0
	je	_299
	jmp	_36
_299:
	push	_39
	push	1
	push	esi
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_300
	push	_40
	push	1
	push	esi
	call	brl_retro_Right
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_300:
	cmp	eax,0
	je	_302
	push	dword [ebp+16]
	mov	eax,dword [esi+8]
	sub	eax,2
	push	eax
	push	2
	push	esi
	call	brl_retro_Mid
	add	esp,12
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_303
	mov	edi,1
	jmp	_304
_303:
	mov	edi,0
_304:
_302:
_296:
	push	1
	push	_41
	push	esi
	call	brl_retro_Instr
	add	esp,12
	mov	ebx,eax
	cmp	ebx,0
	jle	_305
	mov	eax,ebx
	sub	eax,1
	push	eax
	push	esi
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-4],eax
	push	-1
	mov	eax,ebx
	add	eax,1
	push	eax
	push	esi
	call	brl_retro_Mid
	add	esp,12
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-8],eax
_305:
	push	dword [ebp+12]
	push	dword [ebp-4]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_306
	mov	eax,dword [ebp-8]
	jmp	_144
_306:
_36:
	mov	eax,dword [ebp+8]
	push	dword [eax+16]
	call	brl_stream_Eof
	add	esp,4
	cmp	eax,0
	je	_38
_37:
	mov	eax,bbEmptyString
	jmp	_144
_144:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationStreamingResource_Close:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	cmp	dword [ebx+12],bbNullObject
	je	_307
	mov	eax,dword [ebx+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
_307:
	cmp	dword [ebx+16],bbNullObject
	je	_309
	mov	eax,dword [ebx+16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
_309:
	mov	eax,0
	jmp	_147
_147:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_LocalizationResource_New
	add	esp,4
	mov	dword [ebx],bb_LocalizationMemoryResource
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	eax,0
	jmp	_150
_150:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
_153:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_315
	push	eax
	call	bbGCFree
	add	esp,4
_315:
	mov	dword [ebx],bb_LocalizationResource
	push	ebx
	call	_bb_LocalizationResource_Delete
	add	esp,4
	mov	eax,0
	jmp	_313
_313:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_open:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	push	bbEmptyString
	push	ebx
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_316
	push	esi
	call	dword [bb_Localization+80]
	add	esp,4
	mov	ebx,eax
	push	bbEmptyString
	push	ebx
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_317
	push	_33
	call	bbExThrow
	add	esp,4
_317:
_316:
	push	esi
	call	brl_filesystem_ReadFile
	add	esp,4
	mov	dword [ebp-16],eax
	cmp	dword [ebp-16],bbNullObject
	jne	_319
	push	_35
	push	esi
	push	_34
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_319:
	push	bb_LocalizationMemoryResource
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-12],eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_324
	push	eax
	call	bbGCFree
	add	esp,4
_324:
	mov	eax,dword [ebp-12]
	mov	dword [eax+8],ebx
	push	brl_map_TMap
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_328
	push	eax
	call	bbGCFree
	add	esp,4
_328:
	mov	eax,dword [ebp-12]
	mov	dword [eax+16],ebx
	mov	eax,dword [_bb_Localization_Resources]
	push	dword [ebp-12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_333
	push	eax
	call	bbGCFree
	add	esp,4
_333:
	mov	eax,dword [ebp-12]
	mov	dword [eax+12],ebx
	mov	edi,bbEmptyString
	mov	dword [ebp-8],bbEmptyString
	mov	dword [ebp-4],_1
	jmp	_42
_44:
	push	dword [ebp-16]
	call	brl_stream_ReadLine
	add	esp,4
	mov	esi,eax
	push	_39
	push	1
	push	esi
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_339
	push	_40
	push	1
	push	esi
	call	brl_retro_Right
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_339:
	cmp	eax,0
	je	_341
	mov	eax,dword [esi+8]
	sub	eax,2
	push	eax
	push	2
	push	esi
	call	brl_retro_Mid
	add	esp,12
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-4],eax
_341:
	push	1
	push	_41
	push	esi
	call	brl_retro_Instr
	add	esp,12
	mov	ebx,eax
	cmp	ebx,0
	jle	_342
	mov	eax,ebx
	sub	eax,1
	push	eax
	push	esi
	call	brl_retro_Left
	add	esp,8
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	edi,eax
	push	-1
	mov	eax,ebx
	add	eax,1
	push	eax
	push	esi
	call	brl_retro_Mid
	add	esp,12
	push	eax
	call	bbStringTrim
	add	esp,4
	mov	dword [ebp-8],eax
_342:
	push	bbEmptyString
	push	edi
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_343
	push	_1
	push	edi
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
_343:
	cmp	eax,0
	je	_345
	push	bbEmptyString
	push	dword [ebp-4]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_346
	push	_1
	push	dword [ebp-4]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
_346:
	cmp	eax,0
	je	_348
	mov	eax,dword [ebp-12]
	mov	ebx,dword [eax+16]
	push	dword [ebp-8]
	push	edi
	push	_45
	push	dword [ebp-4]
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
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+16]
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	cmp	eax,bbNullObject
	jne	_351
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+16]
	push	dword [ebp-8]
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,12
_351:
	jmp	_353
_348:
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+16]
	push	dword [ebp-8]
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,12
_353:
_345:
_42:
	push	dword [ebp-16]
	call	brl_stream_Eof
	add	esp,4
	cmp	eax,0
	je	_44
_43:
	mov	eax,dword [ebp-16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	mov	eax,dword [ebp-12]
	jmp	_157
_157:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_GetString:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	push	bbEmptyString
	push	ebx
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_357
	mov	esi,dword [esi+16]
	push	edi
	push	_45
	push	ebx
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+64]
	add	esp,8
	jmp	_359
_357:
	mov	eax,dword [esi+16]
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
_359:
	cmp	eax,bbNullObject
	jne	_361
	mov	eax,edi
	jmp	_162
_361:
	push	bbStringClass
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_363
	mov	eax,bbEmptyString
_363:
	jmp	_162
_162:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_LocalizationMemoryResource_Close:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	cmp	dword [ebx+12],bbNullObject
	je	_364
	mov	eax,dword [ebx+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
_364:
	cmp	dword [ebx+16],bbNullObject
	je	_366
	mov	eax,dword [ebx+16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
_366:
	mov	eax,0
	jmp	_165
_165:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_175:
	dd	0
	align	4
_bb_Localization_currentLanguage:
	dd	bbEmptyString
	align	4
_bb_Localization_supportedLanguages:
	dd	bbNullObject
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
	db	"Delete",0
_51:
	db	"SetLanguage",0
_52:
	db	"($)i",0
_53:
	db	"Language",0
_54:
	db	"()$",0
_55:
	db	"AddLanguages",0
_56:
	db	"OpenResource",0
_57:
	db	"LoadResource",0
_58:
	db	"OpenResources",0
_59:
	db	"LoadResources",0
_60:
	db	"GetString",0
_61:
	db	"($,$)$",0
_62:
	db	"GetLanguageFromFilename",0
_63:
	db	"($)$",0
_64:
	db	"GetResourceFiles",0
_65:
	db	"($):brl.linkedlist.TList",0
_66:
	db	"Dispose",0
	align	4
_46:
	dd	2
	dd	_47
	dd	6
	dd	_48
	dd	_49
	dd	16
	dd	6
	dd	_50
	dd	_49
	dd	20
	dd	7
	dd	_51
	dd	_52
	dd	48
	dd	7
	dd	_53
	dd	_54
	dd	52
	dd	7
	dd	_55
	dd	_52
	dd	56
	dd	7
	dd	_56
	dd	_52
	dd	60
	dd	7
	dd	_57
	dd	_52
	dd	64
	dd	7
	dd	_58
	dd	_52
	dd	68
	dd	7
	dd	_59
	dd	_52
	dd	72
	dd	7
	dd	_60
	dd	_61
	dd	76
	dd	7
	dd	_62
	dd	_63
	dd	80
	dd	7
	dd	_64
	dd	_65
	dd	84
	dd	7
	dd	_66
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
	dd	_bb_Localization_Delete
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
_68:
	db	"LocalizationResource",0
_69:
	db	"language",0
_70:
	db	"$",0
_71:
	db	"_link",0
_72:
	db	":brl.linkedlist.TLink",0
_73:
	db	"Close",0
	align	4
_67:
	dd	2
	dd	_68
	dd	3
	dd	_69
	dd	_70
	dd	8
	dd	3
	dd	_71
	dd	_72
	dd	12
	dd	6
	dd	_48
	dd	_49
	dd	16
	dd	6
	dd	_50
	dd	_49
	dd	20
	dd	6
	dd	_60
	dd	_61
	dd	48
	dd	6
	dd	_73
	dd	_49
	dd	52
	dd	0
	align	4
bb_LocalizationResource:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_67
	dd	16
	dd	_bb_LocalizationResource_New
	dd	_bb_LocalizationResource_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	brl_blitz_NullMethodError
	dd	brl_blitz_NullMethodError
_75:
	db	"LocalizationStreamingResource",0
_76:
	db	"Stream",0
_77:
	db	":brl.stream.TStream",0
_78:
	db	"open",0
_79:
	db	"($,$):LocalizationStreamingResource",0
	align	4
_74:
	dd	2
	dd	_75
	dd	3
	dd	_76
	dd	_77
	dd	16
	dd	6
	dd	_48
	dd	_49
	dd	16
	dd	6
	dd	_50
	dd	_49
	dd	20
	dd	7
	dd	_78
	dd	_79
	dd	56
	dd	6
	dd	_60
	dd	_61
	dd	48
	dd	6
	dd	_73
	dd	_49
	dd	52
	dd	0
	align	4
bb_LocalizationStreamingResource:
	dd	bb_LocalizationResource
	dd	bbObjectFree
	dd	_74
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
	dd	6
	dd	_50
	dd	_49
	dd	20
	dd	7
	dd	_78
	dd	_84
	dd	56
	dd	6
	dd	_60
	dd	_61
	dd	48
	dd	6
	dd	_73
	dd	_49
	dd	52
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
_6:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	44
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_19:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	95
	align	4
_23:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	46
	align	4
_24:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	42
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
_39:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	91
	align	4
_40:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	93
	align	4
_41:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	61
	align	4
_45:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	58,58
