	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	bbGCFree
	extrn	bbNullObject
	extrn	bbObjectClass
	extrn	bbObjectCompare
	extrn	bbObjectCtor
	extrn	bbObjectFree
	extrn	bbObjectNew
	extrn	bbObjectRegisterType
	extrn	bbObjectReserved
	extrn	bbObjectSendMessage
	extrn	bbObjectToString
	extrn	bbStringClass
	public	__bb_source_basefunctions_asset
	public	_bb_TAsset_CreateBaseAsset
	public	_bb_TAsset_Delete
	public	_bb_TAsset_GetLoaded
	public	_bb_TAsset_GetName
	public	_bb_TAsset_GetType
	public	_bb_TAsset_GetUrl
	public	_bb_TAsset_New
	public	_bb_TAsset_SetLoaded
	public	_bb_TAsset_SetName
	public	_bb_TAsset_SetType
	public	_bb_TAsset_SetUrl
	public	bb_TAsset
	section	"code" executable
__bb_source_basefunctions_asset:
	push	ebp
	mov	ebp,esp
	cmp	dword [_73],0
	je	_74
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_74:
	mov	dword [_73],1
	call	__bb_blitz_blitz
	call	__bb_glmax2d_glmax2d
	push	bb_TAsset
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,0
	jmp	_33
_33:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TAsset
	mov	eax,_2
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	eax,_3
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	dword [ebx+20],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+24],eax
	mov	dword [ebx+28],0
	mov	eax,0
	jmp	_36
_36:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_39:
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_81
	push	eax
	call	bbGCFree
	add	esp,4
_81:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_83
	push	eax
	call	bbGCFree
	add	esp,4
_83:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_85
	push	eax
	call	bbGCFree
	add	esp,4
_85:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_87
	push	eax
	call	bbGCFree
	add	esp,4
_87:
	mov	eax,0
	jmp	_79
_79:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_CreateBaseAsset:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+12]
	push	bb_TAsset
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,esi
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_92
	push	eax
	call	bbGCFree
	add	esp,4
_92:
	mov	dword [ebx+8],esi
	mov	esi,edi
	inc	dword [esi+4]
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_96
	push	eax
	call	bbGCFree
	add	esp,4
_96:
	mov	dword [ebx+12],esi
	mov	dword [ebx+20],0
	mov	eax,ebx
	jmp	_43
_43:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_GetName:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	jmp	_46
_46:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_SetName:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	inc	dword [ebx+4]
	mov	eax,dword [esi+16]
	dec	dword [eax+4]
	jnz	_100
	push	eax
	call	bbGCFree
	add	esp,4
_100:
	mov	dword [esi+16],ebx
	mov	eax,0
	jmp	_50
_50:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_GetUrl:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+24]
	jmp	_53
_53:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_SetUrl:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	inc	dword [ebx+4]
	mov	eax,dword [esi+24]
	dec	dword [eax+4]
	jnz	_104
	push	eax
	call	bbGCFree
	add	esp,4
_104:
	mov	dword [esi+24],ebx
	mov	eax,0
	jmp	_57
_57:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_GetType:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	jmp	_60
_60:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_SetType:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	inc	dword [ebx+4]
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_108
	push	eax
	call	bbGCFree
	add	esp,4
_108:
	mov	dword [esi+8],ebx
	mov	eax,0
	jmp	_64
_64:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_GetLoaded:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+20]
	jmp	_67
_67:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_SetLoaded:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	dword [edx+20],eax
	mov	eax,0
	jmp	_71
_71:
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_73:
	dd	0
_5:
	db	"TAsset",0
_6:
	db	"_type",0
_7:
	db	"$",0
_8:
	db	"_object",0
_9:
	db	":Object",0
_10:
	db	"_name",0
_11:
	db	"_loaded",0
_12:
	db	"i",0
_13:
	db	"_url",0
_14:
	db	"_flags",0
_15:
	db	"New",0
_16:
	db	"()i",0
_17:
	db	"Delete",0
_18:
	db	"CreateBaseAsset",0
_19:
	db	"(:Object,$):TAsset",0
_20:
	db	"GetName",0
_21:
	db	"()$",0
_22:
	db	"SetName",0
_23:
	db	"($)i",0
_24:
	db	"GetUrl",0
_25:
	db	"():Object",0
_26:
	db	"SetUrl",0
_27:
	db	"(:Object)i",0
_28:
	db	"GetType",0
_29:
	db	"SetType",0
_30:
	db	"GetLoaded",0
_31:
	db	"SetLoaded",0
_32:
	db	"(i)i",0
	align	4
_4:
	dd	2
	dd	_5
	dd	3
	dd	_6
	dd	_7
	dd	8
	dd	3
	dd	_8
	dd	_9
	dd	12
	dd	3
	dd	_10
	dd	_7
	dd	16
	dd	3
	dd	_11
	dd	_12
	dd	20
	dd	3
	dd	_13
	dd	_9
	dd	24
	dd	3
	dd	_14
	dd	_12
	dd	28
	dd	6
	dd	_15
	dd	_16
	dd	16
	dd	6
	dd	_17
	dd	_16
	dd	20
	dd	7
	dd	_18
	dd	_19
	dd	48
	dd	6
	dd	_20
	dd	_21
	dd	52
	dd	6
	dd	_22
	dd	_23
	dd	56
	dd	6
	dd	_24
	dd	_25
	dd	60
	dd	6
	dd	_26
	dd	_27
	dd	64
	dd	6
	dd	_28
	dd	_21
	dd	68
	dd	6
	dd	_29
	dd	_23
	dd	72
	dd	6
	dd	_30
	dd	_16
	dd	76
	dd	6
	dd	_31
	dd	_32
	dd	80
	dd	0
	align	4
bb_TAsset:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_4
	dd	32
	dd	_bb_TAsset_New
	dd	_bb_TAsset_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TAsset_CreateBaseAsset
	dd	_bb_TAsset_GetName
	dd	_bb_TAsset_SetName
	dd	_bb_TAsset_GetUrl
	dd	_bb_TAsset_SetUrl
	dd	_bb_TAsset_GetType
	dd	_bb_TAsset_SetType
	dd	_bb_TAsset_GetLoaded
	dd	_bb_TAsset_SetLoaded
	align	4
_2:
	dd	bbStringClass
	dd	2147483647
	dd	11
	dw	117,110,107,110,111,119,110,84,121,112,101
	align	4
_3:
	dd	bbStringClass
	dd	2147483647
	dd	7
	dw	117,110,107,110,111,119,110
