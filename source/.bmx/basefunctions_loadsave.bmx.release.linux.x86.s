	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_reflection_reflection
	extrn	__bb_source_basefunctions_xml
	extrn	bbArrayNew1D
	extrn	bbEmptyString
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
	extrn	bbStringFromInt
	extrn	bb_xmlDocument
	extrn	brl_blitz_NullFunctionError
	extrn	brl_linkedlist_TList
	extrn	brl_reflection_ArrayTypeId
	extrn	brl_reflection_TField
	extrn	brl_reflection_TTypeId
	extrn	brl_retro_Upper
	extrn	brl_standardio_Print
	public	__bb_source_basefunctions_loadsave
	public	_bb_TSaveFile_Create
	public	_bb_TSaveFile_Delete
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
	cmp	dword [_113],0
	je	_114
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_114:
	mov	dword [_113],1
	call	__bb_blitz_blitz
	call	__bb_source_basefunctions_xml
	call	__bb_reflection_reflection
	push	bb_TSaveFile
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,dword [_111]
	and	eax,1
	cmp	eax,0
	jne	_112
	call	dword [bb_TSaveFile+48]
	inc	dword [eax+4]
	mov	dword [bb_LoadSaveFile],eax
	or	dword [_111],1
_112:
	mov	eax,0
	jmp	_62
_62:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TSaveFile
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+20],eax
	push	10
	push	_119
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [ebx+24],eax
	mov	dword [ebx+28],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+32],eax
	mov	eax,0
	jmp	_65
_65:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_68:
	mov	eax,dword [ebx+32]
	dec	dword [eax+4]
	jnz	_124
	push	eax
	call	bbGCFree
	add	esp,4
_124:
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_126
	push	eax
	call	bbGCFree
	add	esp,4
_126:
	mov	eax,dword [ebx+20]
	dec	dword [eax+4]
	jnz	_128
	push	eax
	call	bbGCFree
	add	esp,4
_128:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_130
	push	eax
	call	bbGCFree
	add	esp,4
_130:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_132
	push	eax
	call	bbGCFree
	add	esp,4
_132:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_134
	push	eax
	call	bbGCFree
	add	esp,4
_134:
	mov	eax,0
	jmp	_122
_122:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_Create:
	push	ebp
	mov	ebp,esp
	push	bb_TSaveFile
	call	bbObjectNew
	add	esp,4
	jmp	_70
_70:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_InitSave:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	push	bb_xmlDocument
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_139
	push	eax
	call	bbGCFree
	add	esp,4
_139:
	mov	dword [esi+8],ebx
	mov	eax,dword [esi+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+20]
	dec	dword [eax+4]
	jnz	_144
	push	eax
	call	bbGCFree
	add	esp,4
_144:
	mov	dword [esi+20],ebx
	mov	ebx,_3
	inc	dword [ebx+4]
	mov	eax,dword [esi+20]
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_148
	push	eax
	call	bbGCFree
	add	esp,4
_148:
	mov	eax,dword [esi+20]
	mov	dword [eax+8],ebx
	mov	ebx,dword [esi+20]
	inc	dword [ebx+4]
	mov	eax,dword [esi+24]
	mov	eax,dword [eax+24]
	dec	dword [eax+4]
	jnz	_152
	push	eax
	call	bbGCFree
	add	esp,4
_152:
	mov	eax,dword [esi+24]
	mov	dword [eax+24],ebx
	mov	ebx,dword [esi+20]
	inc	dword [ebx+4]
	mov	eax,dword [esi+32]
	dec	dword [eax+4]
	jnz	_156
	push	eax
	call	bbGCFree
	add	esp,4
_156:
	mov	dword [esi+32],ebx
	mov	eax,0
	jmp	_73
_73:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_InitLoad:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	edx,dword [ebp+12]
	movzx	eax,byte [ebp+16]
	mov	eax,eax
	mov	byte [ebp-4],al
	movzx	eax,byte [ebp-4]
	push	eax
	push	edx
	call	dword [bb_xmlDocument+48]
	add	esp,8
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_160
	push	eax
	call	bbGCFree
	add	esp,4
_160:
	mov	dword [esi+8],ebx
	mov	eax,dword [esi+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+20]
	dec	dword [eax+4]
	jnz	_165
	push	eax
	call	bbGCFree
	add	esp,4
_165:
	mov	dword [esi+20],ebx
	mov	ebx,dword [esi+20]
	inc	dword [ebx+4]
	mov	eax,dword [esi+12]
	dec	dword [eax+4]
	jnz	_169
	push	eax
	call	bbGCFree
	add	esp,4
_169:
	mov	dword [esi+12],ebx
	mov	eax,0
	jmp	_78
_78:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_xmlWrite:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	edx,dword [ebp+12]
	movzx	eax,byte [ebp+20]
	mov	eax,eax
	mov	byte [ebp-4],al
	mov	ecx,dword [ebp+24]
	cmp	ecx,-1
	setle	al
	movzx	eax,al
	cmp	eax,0
	jne	_170
	cmp	ecx,10
	setge	al
	movzx	eax,al
_170:
	cmp	eax,0
	je	_172
	mov	ecx,dword [edi+28]
_172:
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_173
	mov	eax,dword [edi+24]
	mov	eax,dword [eax+ecx*4+24]
	push	1
	push	edx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	edx,dword [edi+24]
	mov	eax,dword [edi+28]
	add	eax,1
	mov	eax,dword [edx+eax*4+24]
	dec	dword [eax+4]
	jnz	_178
	push	eax
	call	bbGCFree
	add	esp,4
_178:
	mov	edx,dword [edi+24]
	mov	eax,dword [edi+28]
	add	eax,1
	mov	dword [edx+eax*4+24],ebx
	mov	edx,dword [edi+24]
	mov	eax,dword [edi+28]
	add	eax,1
	mov	eax,dword [edx+eax*4+24]
	push	1
	push	_6
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+176]
	add	esp,12
	mov	esi,eax
	mov	eax,dword [ebp+16]
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+12]
	dec	dword [eax+4]
	jnz	_184
	push	eax
	call	bbGCFree
	add	esp,4
_184:
	mov	dword [esi+12],ebx
	add	dword [edi+28],1
	jmp	_185
_173:
	mov	eax,dword [edi+24]
	mov	eax,dword [eax+ecx*4+24]
	push	1
	push	edx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	push	1
	push	_6
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+176]
	add	esp,12
	mov	esi,eax
	mov	ebx,dword [ebp+16]
	inc	dword [ebx+4]
	mov	eax,dword [esi+12]
	dec	dword [eax+4]
	jnz	_192
	push	eax
	call	bbGCFree
	add	esp,4
_192:
	mov	dword [esi+12],ebx
_185:
	mov	eax,0
	jmp	_85
_85:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_xmlCloseNode:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	sub	dword [eax+28],1
	mov	eax,0
	jmp	_88
_88:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_xmlBeginNode:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	ecx,dword [ebp+12]
	mov	edx,dword [ebx+24]
	mov	eax,dword [ebx+28]
	mov	eax,dword [edx+eax*4+24]
	push	1
	push	ecx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	inc	dword [eax+4]
	mov	esi,eax
	mov	edx,dword [ebx+24]
	mov	eax,dword [ebx+28]
	add	eax,1
	mov	eax,dword [edx+eax*4+24]
	dec	dword [eax+4]
	jnz	_197
	push	eax
	call	bbGCFree
	add	esp,4
_197:
	mov	edx,dword [ebx+24]
	mov	eax,dword [ebx+28]
	add	eax,1
	mov	dword [edx+eax*4+24],esi
	add	dword [ebx+28],1
	mov	eax,0
	jmp	_92
_92:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_xmlSave:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	movzx	eax,byte [ebp+16]
	mov	eax,eax
	mov	byte [ebp-4],al
	push	_7
	push	ebx
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_198
	mov	eax,dword [esi+8]
	push	eax
	mov	eax,dword [eax]
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
	jmp	_200
_198:
	mov	edx,dword [esi+8]
	movzx	eax,byte [ebp-4]
	push	eax
	push	1
	push	ebx
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+60]
	add	esp,16
_200:
	mov	eax,0
	jmp	_97
_97:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_SaveObject:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	push	dword [ebp+16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	push	brl_linkedlist_TList
	push	dword [ebp+12]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_204
	push	brl_linkedlist_TList
	push	dword [ebp+12]
	call	bbObjectDowncast
	add	esp,8
	mov	edi,eax
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-8],eax
	jmp	_9
_11:
	mov	eax,dword [ebp-8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_9
	mov	ebx,dword [ebp+8]
	push	dword [ebp+20]
	push	_12
	push	dword [ebp+16]
	call	bbStringConcat
	add	esp,8
	push	eax
	push	esi
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,16
_9:
	mov	eax,dword [ebp-8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_11
_10:
	jmp	_212
_204:
	push	dword [ebp+12]
	call	dword [brl_reflection_TTypeId+128]
	add	esp,4
	mov	dword [ebp-20],eax
	mov	eax,dword [ebp-20]
	push	bbNullObject
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+96]
	add	esp,8
	mov	dword [ebp-16],eax
	mov	eax,dword [ebp-16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-12],eax
	jmp	_13
_15:
	mov	eax,dword [ebp-12]
	push	brl_reflection_TField
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	je	_13
	mov	eax,ebx
	push	_17
	push	_16
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_222
	mov	eax,ebx
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	dword [brl_reflection_TTypeId+128]
	add	esp,4
	mov	esi,eax
	mov	eax,esi
	push	dword [brl_reflection_ArrayTypeId]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	cmp	eax,0
	je	_226
	mov	eax,esi
	push	0
	push	dword [ebp-20]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+108]
	add	esp,12
	cmp	eax,0
	jle	_228
	mov	eax,esi
	push	_20
	push	eax
	mov	eax,dword [eax]
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
_228:
_226:
	mov	eax,ebx
	push	brl_linkedlist_TList
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_232
	mov	eax,ebx
	push	brl_linkedlist_TList
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	edi,eax
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-4],eax
	jmp	_21
_23:
	mov	eax,dword [ebp-4]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_21
	push	_24
	call	brl_standardio_Print
	add	esp,4
	mov	ebx,dword [ebp+8]
	push	dword [ebp+20]
	push	_12
	push	dword [ebp+16]
	call	bbStringConcat
	add	esp,8
	push	eax
	push	esi
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,16
_21:
	mov	eax,dword [ebp-4]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_23
_22:
	jmp	_242
_232:
	mov	esi,dword [ebp+8]
	mov	eax,ebx
	push	bbStringClass
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_247
	mov	eax,bbEmptyString
_247:
	push	-1
	push	0
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	brl_retro_Upper
	add	esp,4
	push	eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+60]
	add	esp,20
_242:
_222:
_13:
	mov	eax,dword [ebp-12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_15
_14:
	cmp	dword [ebp+20],brl_blitz_NullFunctionError
	je	_248
	push	dword [ebp+12]
	call	dword [ebp+20]
	add	esp,4
_248:
_212:
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,4
	mov	eax,0
	jmp	_103
_103:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TSaveFile_LoadObject:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+88]
	add	esp,4
	mov	dword [ebp-8],eax
	jmp	_25
_27:
	mov	dword [ebp-4],_1
	mov	eax,dword [ebp-8]
	push	0
	push	_6
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+160]
	add	esp,12
	cmp	eax,0
	je	_254
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	push	1
	push	_6
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+176]
	add	esp,12
	mov	eax,dword [eax+12]
	mov	dword [ebp-4],eax
_254:
	push	dword [ebp+12]
	call	dword [brl_reflection_TTypeId+128]
	add	esp,4
	push	bbNullObject
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+96]
	add	esp,8
	mov	ebx,eax
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_28
_30:
	mov	eax,edi
	push	brl_reflection_TField
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_28
	mov	eax,esi
	push	_17
	push	_16
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,8
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_266
	mov	eax,esi
	mov	edx,dword [ebp-8]
	push	dword [edx+8]
	push	eax
	mov	eax,dword [eax]
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
_266:
	cmp	eax,0
	je	_268
	mov	eax,esi
	push	dword [ebp-4]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+88]
	add	esp,12
_268:
_28:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_30
_29:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+132]
	add	esp,4
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_274
	push	eax
	call	bbGCFree
	add	esp,4
_274:
	mov	eax,dword [ebp+8]
	mov	dword [eax+12],ebx
	cmp	dword [ebp+16],brl_blitz_NullFunctionError
	je	_275
	push	dword [ebp-8]
	push	dword [ebp+12]
	call	dword [ebp+16]
	add	esp,8
_275:
_25:
	cmp	dword [ebp-8],bbNullObject
	jne	_27
_26:
	mov	eax,dword [ebp+12]
	jmp	_108
_108:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_113:
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
_42:
	db	"i",0
_43:
	db	"lastNode",0
_44:
	db	"New",0
_45:
	db	"()i",0
_46:
	db	"Delete",0
_47:
	db	"Create",0
_48:
	db	"():TSaveFile",0
_49:
	db	"InitSave",0
_50:
	db	"InitLoad",0
_51:
	db	"($,b)i",0
_52:
	db	"xmlWrite",0
_53:
	db	"($,$,b,i)i",0
_54:
	db	"xmlCloseNode",0
_55:
	db	"xmlBeginNode",0
_56:
	db	"($)i",0
_57:
	db	"xmlSave",0
_58:
	db	"SaveObject",0
_59:
	db	"(:Object,$,(:Object)i)i",0
_60:
	db	"LoadObject",0
_61:
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
	dd	6
	dd	_46
	dd	_45
	dd	20
	dd	7
	dd	_47
	dd	_48
	dd	48
	dd	6
	dd	_49
	dd	_45
	dd	52
	dd	6
	dd	_50
	dd	_51
	dd	56
	dd	6
	dd	_52
	dd	_53
	dd	60
	dd	6
	dd	_54
	dd	_45
	dd	64
	dd	6
	dd	_55
	dd	_56
	dd	68
	dd	6
	dd	_57
	dd	_51
	dd	72
	dd	6
	dd	_58
	dd	_59
	dd	76
	dd	6
	dd	_60
	dd	_61
	dd	80
	dd	0
	align	4
bb_TSaveFile:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_31
	dd	36
	dd	_bb_TSaveFile_New
	dd	_bb_TSaveFile_Delete
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
	align	4
_111:
	dd	0
	align	4
bb_LoadSaveFile:
	dd	bbNullObject
_119:
	db	":xmlNode",0
	align	4
_3:
	dd	bbStringClass
	dd	2147483647
	dd	8
	dw	115,97,118,101,103,97,109,101
	align	4
_6:
	dd	bbStringClass
	dd	2147483647
	dd	3
	dw	118,97,114
	align	4
_7:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	45
	align	4
_8:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	110,111,100,101,115,58
	align	4
_12:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	95,67,72,73,76,68
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
_24:
	dd	bbStringClass
	dd	2147483647
	dd	23
	dw	115,97,118,105,110,103,32,108,105,115,116,32,99,104,105,108
	dw	100,114,101,110,46,46,46
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
