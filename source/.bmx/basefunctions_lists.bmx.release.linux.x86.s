	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	_bbExEnter
	extrn	bbArraySlice
	extrn	bbEmptyArray
	extrn	bbExEnter
	extrn	bbExLeave
	extrn	bbExThrow
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
	extrn	bbStringClass
	extrn	bbStringConcat
	extrn	brl_blitz_RuntimeError
	public	__bb_source_basefunctions_lists
	public	_bb_TObjectList_AddFirst
	public	_bb_TObjectList_AddLast
	public	_bb_TObjectList_Clear
	public	_bb_TObjectList_Contains
	public	_bb_TObjectList_Count
	public	_bb_TObjectList_Create
	public	_bb_TObjectList_Delete
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
	cmp	dword [_155],0
	je	_156
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_156:
	mov	dword [_155],1
	call	__bb_blitz_blitz
	call	__bb_glmax2d_glmax2d
	push	bb_TObjectList
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,0
	jmp	_68
_68:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TObjectList
	mov	eax,bbEmptyArray
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	dword [ebx+12],0
	mov	dword [ebx+16],0
	mov	eax,0
	jmp	_71
_71:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_74:
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_160
	push	eax
	call	bbGCFree
	add	esp,4
_160:
	mov	eax,0
	jmp	_158
_158:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_AddFirst:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	add	dword [edi+12],1
	mov	edx,dword [edi+8]
	mov	eax,dword [edi+12]
	cmp	dword [edx+20],eax
	jge	_162
	mov	eax,dword [edi+12]
	add	eax,dword [edi+16]
	push	eax
	push	0
	push	dword [edi+8]
	push	_163
	call	bbArraySlice
	add	esp,16
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [edi+8]
	dec	dword [eax+4]
	jnz	_167
	push	eax
	call	bbGCFree
	add	esp,4
_167:
	mov	dword [edi+8],ebx
_162:
	mov	esi,1
	mov	eax,dword [edi+12]
	sub	eax,1
	mov	dword [ebp-4],eax
	jmp	_168
_4:
	mov	edx,dword [edi+8]
	mov	eax,esi
	sub	eax,1
	mov	eax,dword [edx+eax*4+24]
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+esi*4+24]
	dec	dword [eax+4]
	jnz	_173
	push	eax
	call	bbGCFree
	add	esp,4
_173:
	mov	eax,dword [edi+8]
	mov	dword [eax+esi*4+24],ebx
_2:
	add	esi,1
_168:
	cmp	esi,dword [ebp-4]
	jle	_4
_3:
	mov	ebx,dword [ebp+12]
	inc	dword [ebx+4]
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+24]
	dec	dword [eax+4]
	jnz	_177
	push	eax
	call	bbGCFree
	add	esp,4
_177:
	mov	eax,dword [edi+8]
	mov	dword [eax+24],ebx
	mov	eax,0
	jmp	_78
_78:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_AddLast:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	add	dword [esi+12],1
	mov	edx,dword [esi+8]
	mov	eax,dword [esi+12]
	cmp	dword [edx+20],eax
	jge	_178
	mov	eax,dword [esi+12]
	add	eax,dword [esi+16]
	push	eax
	push	0
	push	dword [esi+8]
	push	_163
	call	bbArraySlice
	add	esp,16
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_182
	push	eax
	call	bbGCFree
	add	esp,4
_182:
	mov	dword [esi+8],ebx
_178:
	mov	ebx,edi
	inc	dword [ebx+4]
	mov	edx,dword [esi+8]
	mov	eax,dword [esi+12]
	sub	eax,1
	mov	eax,dword [edx+eax*4+24]
	dec	dword [eax+4]
	jnz	_186
	push	eax
	call	bbGCFree
	add	esp,4
_186:
	mov	edx,dword [esi+8]
	mov	eax,dword [esi+12]
	sub	eax,1
	mov	dword [edx+eax*4+24],ebx
	mov	eax,dword [esi+12]
	jmp	_82
_82:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_ToDelimString:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,_1
	mov	ebx,0
	mov	eax,dword [edi+12]
	sub	eax,2
	mov	dword [ebp-4],eax
	jmp	_189
_7:
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+ebx*4+24]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+24]
	add	esp,4
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	esi
	call	bbStringConcat
	add	esp,8
	mov	esi,eax
_5:
	add	ebx,1
_189:
	cmp	ebx,dword [ebp-4]
	jle	_7
_6:
	mov	edx,dword [edi+8]
	mov	eax,dword [edi+12]
	sub	eax,1
	mov	eax,dword [edx+eax*4+24]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+24]
	add	esp,4
	push	eax
	push	esi
	call	bbStringConcat
	add	esp,8
	mov	esi,eax
	mov	eax,esi
	jmp	_86
_86:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_ToString:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	_1
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,8
	jmp	_89
_89:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Count:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	jmp	_92
_92:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Contains:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	ecx,dword [ebp+12]
	mov	eax,0
	mov	edx,dword [ebx+12]
	sub	edx,1
	jmp	_195
_10:
	mov	esi,dword [ebx+8]
	cmp	ecx,dword [esi+eax*4+24]
	jne	_197
	jmp	_96
_197:
_8:
	add	eax,1
_195:
	cmp	eax,edx
	jle	_10
_9:
	mov	eax,-1
	jmp	_96
_96:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_FromObjectArray:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	push	10
	call	dword [bb_TObjectList+124]
	add	esp,4
	mov	edi,eax
	call	bbExEnter
	mov	ebx,eax
	push	ebx
	call	_bbExEnter
	add	esp,4
	mov	ebx,eax
	cmp	ebx,0
	jne	_200
	mov	ebx,esi
	inc	dword [ebx+4]
	mov	eax,dword [edi+8]
	dec	dword [eax+4]
	jnz	_205
	push	eax
	call	bbGCFree
	add	esp,4
_205:
	mov	dword [edi+8],ebx
	call	bbExLeave
	jmp	_201
_200:
	push	bbStringClass
	push	ebx
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	jne	_206
	push	ebx
	call	bbExThrow
	add	esp,4
_206:
	push	esi
	push	_11
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_blitz_RuntimeError
	add	esp,4
	mov	eax,bbNullObject
	jmp	_99
_201:
	mov	eax,edi
	jmp	_99
_99:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Insert:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	edx,dword [ebp+20]
	cmp	dword [ebp+16],0
	jge	_209
	mov	eax,0
	jmp	_105
_209:
	mov	eax,dword [edi+12]
	cmp	dword [ebp+16],eax
	jle	_210
	cmp	edx,0
	jne	_211
	mov	eax,0
	jmp	_105
_211:
	mov	eax,edi
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,8
	mov	eax,1
	jmp	_105
_210:
	mov	eax,dword [edi+12]
	cmp	dword [ebp+16],eax
	jne	_214
	mov	eax,edi
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,8
	mov	eax,1
	jmp	_105
_214:
	add	dword [edi+12],1
	mov	edx,dword [edi+8]
	mov	eax,dword [edi+12]
	cmp	dword [edx+20],eax
	jge	_216
	mov	eax,dword [edi+12]
	add	eax,dword [edi+16]
	push	eax
	push	0
	push	dword [edi+8]
	push	_163
	call	bbArraySlice
	add	esp,16
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [edi+8]
	dec	dword [eax+4]
	jnz	_220
	push	eax
	call	bbGCFree
	add	esp,4
_220:
	mov	dword [edi+8],ebx
_216:
	mov	eax,dword [edi+12]
	sub	eax,1
	mov	esi,eax
	mov	eax,dword [ebp+16]
	add	eax,1
	mov	dword [ebp-4],eax
	jmp	_221
_14:
	mov	edx,dword [edi+8]
	mov	eax,esi
	sub	eax,1
	mov	eax,dword [edx+eax*4+24]
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+esi*4+24]
	dec	dword [eax+4]
	jnz	_226
	push	eax
	call	bbGCFree
	add	esp,4
_226:
	mov	eax,dword [edi+8]
	mov	dword [eax+esi*4+24],ebx
_12:
	add	esi,-1
_221:
	cmp	esi,dword [ebp-4]
	jge	_14
_13:
	mov	ebx,dword [ebp+12]
	inc	dword [ebx+4]
	mov	edx,dword [edi+8]
	mov	eax,dword [ebp+16]
	mov	eax,dword [edx+eax*4+24]
	dec	dword [eax+4]
	jnz	_230
	push	eax
	call	bbGCFree
	add	esp,4
_230:
	mov	edx,dword [edi+8]
	mov	eax,dword [ebp+16]
	mov	dword [edx+eax*4+24],ebx
	mov	eax,1
	jmp	_105
_105:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_RemoveByIndex:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	esi,eax
	mov	eax,dword [edi+12]
	sub	eax,2
	mov	dword [ebp-4],eax
	jmp	_232
_17:
	mov	edx,dword [edi+8]
	mov	eax,esi
	add	eax,1
	mov	eax,dword [edx+eax*4+24]
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+esi*4+24]
	dec	dword [eax+4]
	jnz	_237
	push	eax
	call	bbGCFree
	add	esp,4
_237:
	mov	eax,dword [edi+8]
	mov	dword [eax+esi*4+24],ebx
_15:
	add	esi,1
_232:
	cmp	esi,dword [ebp-4]
	jle	_17
_16:
	sub	dword [edi+12],1
	mov	eax,dword [edi+8]
	mov	edx,dword [eax+20]
	mov	eax,dword [edi+16]
	shl	eax,1
	sub	edx,eax
	cmp	dword [edi+12],edx
	jge	_238
	push	dword [edi+12]
	push	0
	push	dword [edi+8]
	push	_163
	call	bbArraySlice
	add	esp,16
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [edi+8]
	dec	dword [eax+4]
	jnz	_242
	push	eax
	call	bbGCFree
	add	esp,4
_242:
	mov	dword [edi+8],ebx
_238:
	cmp	dword [edi+12],0
	jge	_243
	mov	dword [edi+12],0
_243:
	mov	ebx,bbNullObject
	inc	dword [ebx+4]
	mov	edx,dword [edi+8]
	mov	eax,dword [edi+12]
	mov	eax,dword [edx+eax*4+24]
	dec	dword [eax+4]
	jnz	_247
	push	eax
	call	bbGCFree
	add	esp,4
_247:
	mov	edx,dword [edi+8]
	mov	eax,dword [edi+12]
	mov	dword [edx+eax*4+24],ebx
	mov	eax,0
	jmp	_109
_109:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_RemoveByObject:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	edi,dword [ebp+16]
	mov	eax,esi
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	jmp	_18
_20:
	mov	edx,esi
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+76]
	add	esp,8
	cmp	edi,0
	jne	_251
	jmp	_19
_251:
	mov	eax,esi
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
_18:
	cmp	eax,-1
	jg	_20
_19:
	mov	eax,1
	jmp	_114
_114:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Clear:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	push	0
	push	0
	push	dword [ebx+8]
	push	_163
	call	bbArraySlice
	add	esp,16
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_256
	push	eax
	call	bbGCFree
	add	esp,4
_256:
	mov	dword [ebx+8],esi
	mov	dword [ebx+12],0
	mov	eax,0
	jmp	_117
_117:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_ToArray:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [edx+12]
	sub	eax,1
	push	eax
	push	0
	push	dword [edx+8]
	push	_163
	call	bbArraySlice
	add	esp,16
	jmp	_120
_120:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_ToList:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	esi,dword [eax+8]
	mov	eax,esi
	add	eax,24
	mov	ebx,eax
	mov	eax,ebx
	add	eax,dword [esi+16]
	mov	edi,eax
	jmp	_21
_23:
	mov	eax,dword [ebx]
	add	ebx,4
	cmp	eax,bbNullObject
	je	_21
	mov	edx,dword [ebp+12]
	mov	edx,dword [edx]
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+68]
	add	esp,8
_21:
	cmp	ebx,edi
	jne	_23
_22:
	mov	eax,0
	jmp	_124
_124:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_GetStepSize:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	jmp	_127
_127:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_SetStepSize:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	cmp	eax,1
	jge	_263
	mov	eax,1
_263:
	mov	dword [edx+16],eax
	mov	eax,0
	jmp	_131
_131:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Sort:
	push	ebp
	mov	ebp,esp
	mov	eax,0
	jmp	_134
_134:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Free:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	call	dword [bb_TObjectList+120]
	add	esp,4
	mov	eax,0
	jmp	_137
_137:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_SwapByIndex:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	eax,dword [ebp+12]
	cmp	eax,0
	setl	al
	movzx	eax,al
	cmp	eax,0
	jne	_264
	mov	edx,dword [edi+12]
	sub	edx,1
	mov	eax,dword [ebp+12]
	cmp	eax,edx
	setg	al
	movzx	eax,al
_264:
	cmp	eax,0
	jne	_266
	mov	eax,dword [ebp+16]
	cmp	eax,0
	setl	al
	movzx	eax,al
_266:
	cmp	eax,0
	jne	_268
	mov	edx,dword [edi+12]
	sub	edx,1
	mov	eax,dword [ebp+16]
	cmp	eax,edx
	setg	al
	movzx	eax,al
_268:
	cmp	eax,0
	je	_270
	mov	eax,0
	jmp	_142
_270:
	mov	edx,dword [edi+8]
	mov	eax,dword [ebp+12]
	mov	esi,dword [edx+eax*4+24]
	mov	edx,dword [edi+8]
	mov	eax,dword [ebp+16]
	mov	eax,dword [edx+eax*4+24]
	inc	dword [eax+4]
	mov	ebx,eax
	mov	edx,dword [edi+8]
	mov	eax,dword [ebp+12]
	mov	eax,dword [edx+eax*4+24]
	dec	dword [eax+4]
	jnz	_275
	push	eax
	call	bbGCFree
	add	esp,4
_275:
	mov	edx,dword [edi+8]
	mov	eax,dword [ebp+12]
	mov	dword [edx+eax*4+24],ebx
	mov	ebx,esi
	inc	dword [ebx+4]
	mov	edx,dword [edi+8]
	mov	eax,dword [ebp+16]
	mov	eax,dword [edx+eax*4+24]
	dec	dword [eax+4]
	jnz	_279
	push	eax
	call	bbGCFree
	add	esp,4
_279:
	mov	edx,dword [edi+8]
	mov	eax,dword [ebp+16]
	mov	dword [edx+eax*4+24],ebx
	mov	eax,1
	jmp	_142
_142:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_SwapByVal:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edx,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	cmp	edx,bbNullObject
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_280
	cmp	ebx,bbNullObject
	sete	al
	movzx	eax,al
_280:
	cmp	eax,0
	je	_282
	mov	eax,0
	jmp	_147
_282:
	mov	eax,dword [ebp+8]
	push	edx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	mov	edi,eax
	mov	eax,dword [ebp+8]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebp-4],eax
	cmp	edi,-1
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_288
	mov	eax,dword [ebp-4]
	cmp	eax,-1
	setg	al
	movzx	eax,al
_288:
	cmp	eax,0
	je	_290
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	mov	esi,dword [eax+edi*4+24]
	mov	eax,dword [ebp+8]
	mov	edx,dword [eax+8]
	mov	eax,dword [ebp-4]
	mov	eax,dword [edx+eax*4+24]
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	mov	eax,dword [eax+edi*4+24]
	dec	dword [eax+4]
	jnz	_294
	push	eax
	call	bbGCFree
	add	esp,4
_294:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	mov	dword [eax+edi*4+24],ebx
	mov	ebx,esi
	inc	dword [ebx+4]
	mov	eax,dword [ebp+8]
	mov	edx,dword [eax+8]
	mov	eax,dword [ebp-4]
	mov	eax,dword [edx+eax*4+24]
	dec	dword [eax+4]
	jnz	_298
	push	eax
	call	bbGCFree
	add	esp,4
_298:
	mov	eax,dword [ebp+8]
	mov	edx,dword [eax+8]
	mov	eax,dword [ebp-4]
	mov	dword [edx+eax*4+24],ebx
	mov	eax,1
	jmp	_147
_290:
	mov	eax,0
	jmp	_147
_147:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Destroy:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,4
	call	bbGCCollect
	mov	eax,0
	jmp	_150
_150:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TObjectList_Create:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	bb_TObjectList
	call	bbObjectNew
	add	esp,4
	mov	dword [eax+16],ebx
	jmp	_153
_153:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_155:
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
	db	"Delete",0
_34:
	db	"AddFirst",0
_35:
	db	"(:Object)i",0
_36:
	db	"AddLast",0
_37:
	db	"ToDelimString",0
_38:
	db	"($)$",0
_39:
	db	"ToString",0
_40:
	db	"()$",0
_41:
	db	"Count",0
_42:
	db	"Contains",0
_43:
	db	"FromObjectArray",0
_44:
	db	"([]:Object):TObjectList",0
_45:
	db	"Insert",0
_46:
	db	"(:Object,i,i)i",0
_47:
	db	"RemoveByIndex",0
_48:
	db	"(i)i",0
_49:
	db	"RemoveByObject",0
_50:
	db	"(:Object,i)i",0
_51:
	db	"Clear",0
_52:
	db	"ToArray",0
_53:
	db	"()[]:Object",0
_54:
	db	"ToList",0
_55:
	db	"(*:brl.linkedlist.TList)i",0
_56:
	db	"GetStepSize",0
_57:
	db	"SetStepSize",0
_58:
	db	"Sort",0
_59:
	db	"Free",0
_60:
	db	"SwapByIndex",0
_61:
	db	"(i,i)i",0
_62:
	db	"SwapByVal",0
_63:
	db	"(:Object,:Object)i",0
_64:
	db	"Destroy",0
_65:
	db	"(:TObjectList)i",0
_66:
	db	"Create",0
_67:
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
	dd	_32
	dd	20
	dd	6
	dd	_34
	dd	_35
	dd	48
	dd	6
	dd	_36
	dd	_35
	dd	52
	dd	6
	dd	_37
	dd	_38
	dd	56
	dd	6
	dd	_39
	dd	_40
	dd	24
	dd	6
	dd	_41
	dd	_32
	dd	60
	dd	6
	dd	_42
	dd	_35
	dd	64
	dd	7
	dd	_43
	dd	_44
	dd	68
	dd	6
	dd	_45
	dd	_46
	dd	72
	dd	6
	dd	_47
	dd	_48
	dd	76
	dd	6
	dd	_49
	dd	_50
	dd	80
	dd	6
	dd	_51
	dd	_32
	dd	84
	dd	6
	dd	_52
	dd	_53
	dd	88
	dd	6
	dd	_54
	dd	_55
	dd	92
	dd	6
	dd	_56
	dd	_32
	dd	96
	dd	6
	dd	_57
	dd	_48
	dd	100
	dd	6
	dd	_58
	dd	_32
	dd	104
	dd	6
	dd	_59
	dd	_32
	dd	108
	dd	6
	dd	_60
	dd	_61
	dd	112
	dd	6
	dd	_62
	dd	_63
	dd	116
	dd	7
	dd	_64
	dd	_65
	dd	120
	dd	7
	dd	_66
	dd	_67
	dd	124
	dd	0
	align	4
bb_TObjectList:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_24
	dd	20
	dd	_bb_TObjectList_New
	dd	_bb_TObjectList_Delete
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
_163:
	db	":Object",0
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_11:
	dd	bbStringClass
	dd	2147483647
	dd	64
	dw	69,114,114,111,114,32,119,104,101,110,32,99,111,110,118,101
	dw	114,116,105,110,103,32,102,114,111,109,32,79,98,106,101,99
	dw	116,32,65,114,114,97,121,32,116,111,32,84,79,98,106,101
	dw	99,116,76,105,115,116,44,32,101,114,114,111,114,58,32,10
