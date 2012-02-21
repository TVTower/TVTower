	format	ELF
	extrn	__bb_basic_basic
	extrn	__bb_blitz_blitz
	extrn	__bb_font_font
	extrn	__bb_glmax2d_glmax2d
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
	extrn	brl_linkedlist_CreateList
	extrn	brl_max2d_LoadImageFont
	public	__bb_source_basefunctions_text
	public	_bb_TGW_FontManager_AddFont
	public	_bb_TGW_FontManager_Create
	public	_bb_TGW_FontManager_Delete
	public	_bb_TGW_FontManager_GW_GetFont
	public	_bb_TGW_FontManager_New
	public	_bb_TGW_Font_Create
	public	_bb_TGW_Font_Delete
	public	_bb_TGW_Font_New
	public	bb_TGW_Font
	public	bb_TGW_FontManager
	section	"code" executable
__bb_source_basefunctions_text:
	push	ebp
	mov	ebp,esp
	cmp	dword [_67],0
	je	_68
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_68:
	mov	dword [_67],1
	call	__bb_blitz_blitz
	call	__bb_font_font
	call	__bb_basic_basic
	call	__bb_glmax2d_glmax2d
	push	bb_TGW_FontManager
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TGW_Font
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,0
	jmp	_32
_32:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_FontManager_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TGW_FontManager
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	call	brl_linkedlist_CreateList
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	eax,0
	jmp	_35
_35:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_FontManager_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_38:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_73
	push	eax
	call	bbGCFree
	add	esp,4
_73:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_75
	push	eax
	call	bbGCFree
	add	esp,4
_75:
	mov	eax,0
	jmp	_71
_71:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_FontManager_Create:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	bb_TGW_FontManager
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	call	brl_linkedlist_CreateList
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_80
	push	eax
	call	bbGCFree
	add	esp,4
_80:
	mov	dword [ebx+12],esi
	mov	eax,ebx
	jmp	_40
_40:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_FontManager_GW_GetFont:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	push	_3
	push	dword [ebp+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_81
	mov	eax,dword [ebp+16]
	cmp	eax,-1
	sete	al
	movzx	eax,al
_81:
	cmp	eax,0
	je	_83
	mov	eax,dword [ebp+20]
	cmp	eax,-1
	sete	al
	movzx	eax,al
_83:
	cmp	eax,0
	je	_85
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	mov	eax,dword [eax+24]
	jmp	_46
_85:
	cmp	dword [ebp+16],-1
	jne	_86
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	mov	eax,dword [eax+16]
	mov	dword [ebp+16],eax
_86:
	cmp	dword [ebp+20],-1
	jne	_87
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	mov	eax,dword [eax+20]
	mov	dword [ebp+20],eax
	jmp	_88
_87:
	add	dword [ebp+20],4
_88:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	mov	eax,dword [eax+12]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+8]
	mov	ebx,dword [eax+12]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_4
_6:
	mov	eax,edi
	push	bb_TGW_Font
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_4
	push	dword [ebp+12]
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_96
	mov	eax,dword [esi+20]
	cmp	eax,dword [ebp+20]
	sete	al
	movzx	eax,al
_96:
	cmp	eax,0
	je	_98
	mov	eax,dword [esi+12]
	mov	dword [ebp-4],eax
_98:
	push	dword [ebp+12]
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_99
	mov	eax,dword [esi+16]
	cmp	eax,dword [ebp+16]
	sete	al
	movzx	eax,al
_99:
	cmp	eax,0
	je	_101
	mov	eax,dword [esi+20]
	cmp	eax,dword [ebp+20]
	sete	al
	movzx	eax,al
_101:
	cmp	eax,0
	je	_103
	mov	eax,dword [esi+24]
	jmp	_46
_103:
_4:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_6
_5:
	mov	eax,dword [ebp+8]
	push	dword [ebp+20]
	push	dword [ebp+16]
	push	dword [ebp-4]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,20
	mov	eax,dword [eax+24]
	jmp	_46
_46:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_FontManager_AddFont:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+16]
	mov	edi,dword [ebp+20]
	cmp	edi,-1
	jne	_105
	mov	eax,dword [esi+8]
	mov	edi,dword [eax+16]
_105:
	cmp	dword [ebp+24],-1
	jne	_106
	mov	eax,dword [esi+8]
	mov	eax,dword [eax+20]
	mov	dword [ebp+24],eax
_106:
	push	_1
	push	ebx
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_107
	mov	eax,dword [esi+8]
	mov	ebx,dword [eax+12]
_107:
	push	dword [ebp+24]
	push	edi
	push	ebx
	push	dword [ebp+12]
	call	dword [bb_TGW_Font+48]
	add	esp,16
	mov	ebx,eax
	mov	eax,dword [esi+12]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	jmp	_53
_53:
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_Font_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TGW_Font
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	dword [ebx+16],0
	mov	dword [ebx+20],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+24],eax
	mov	eax,0
	jmp	_56
_56:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_Font_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_59:
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_115
	push	eax
	call	bbGCFree
	add	esp,4
_115:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_117
	push	eax
	call	bbGCFree
	add	esp,4
_117:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_119
	push	eax
	call	bbGCFree
	add	esp,4
_119:
	mov	eax,0
	jmp	_113
_113:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_Font_Create:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	push	bb_TGW_Font
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,esi
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_124
	push	eax
	call	bbGCFree
	add	esp,4
_124:
	mov	dword [ebx+8],esi
	mov	eax,edi
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_128
	push	eax
	call	bbGCFree
	add	esp,4
_128:
	mov	dword [ebx+12],esi
	mov	eax,dword [ebp+16]
	mov	dword [ebx+16],eax
	mov	eax,dword [ebp+20]
	mov	dword [ebx+20],eax
	mov	eax,dword [ebp+20]
	add	eax,4
	push	eax
	push	dword [ebp+16]
	push	edi
	call	brl_max2d_LoadImageFont
	add	esp,12
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_132
	push	eax
	call	bbGCFree
	add	esp,4
_132:
	mov	dword [ebx+24],esi
	mov	eax,ebx
	jmp	_65
_65:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_67:
	dd	0
_8:
	db	"TGW_FontManager",0
_9:
	db	"DefaultFont",0
_10:
	db	":TGW_Font",0
_11:
	db	"List",0
_12:
	db	":brl.linkedlist.TList",0
_13:
	db	"New",0
_14:
	db	"()i",0
_15:
	db	"Delete",0
_16:
	db	"Create",0
_17:
	db	"():TGW_FontManager",0
_18:
	db	"GW_GetFont",0
_19:
	db	"($,i,i):brl.max2d.TImageFont",0
_20:
	db	"AddFont",0
_21:
	db	"($,$,i,i):TGW_Font",0
	align	4
_7:
	dd	2
	dd	_8
	dd	3
	dd	_9
	dd	_10
	dd	8
	dd	3
	dd	_11
	dd	_12
	dd	12
	dd	6
	dd	_13
	dd	_14
	dd	16
	dd	6
	dd	_15
	dd	_14
	dd	20
	dd	7
	dd	_16
	dd	_17
	dd	48
	dd	6
	dd	_18
	dd	_19
	dd	52
	dd	6
	dd	_20
	dd	_21
	dd	56
	dd	0
	align	4
bb_TGW_FontManager:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_7
	dd	16
	dd	_bb_TGW_FontManager_New
	dd	_bb_TGW_FontManager_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TGW_FontManager_Create
	dd	_bb_TGW_FontManager_GW_GetFont
	dd	_bb_TGW_FontManager_AddFont
_23:
	db	"TGW_Font",0
_24:
	db	"FName",0
_25:
	db	"$",0
_26:
	db	"FFile",0
_27:
	db	"FSize",0
_28:
	db	"i",0
_29:
	db	"FStyle",0
_30:
	db	"FFont",0
_31:
	db	":brl.max2d.TImageFont",0
	align	4
_22:
	dd	2
	dd	_23
	dd	3
	dd	_24
	dd	_25
	dd	8
	dd	3
	dd	_26
	dd	_25
	dd	12
	dd	3
	dd	_27
	dd	_28
	dd	16
	dd	3
	dd	_29
	dd	_28
	dd	20
	dd	3
	dd	_30
	dd	_31
	dd	24
	dd	6
	dd	_13
	dd	_14
	dd	16
	dd	6
	dd	_15
	dd	_14
	dd	20
	dd	7
	dd	_16
	dd	_21
	dd	48
	dd	0
	align	4
bb_TGW_Font:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_22
	dd	28
	dd	_bb_TGW_Font_New
	dd	_bb_TGW_Font_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TGW_Font_Create
	align	4
_3:
	dd	bbStringClass
	dd	2147483647
	dd	7
	dw	68,101,102,97,117,108,116
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
