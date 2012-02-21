	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	bbNullObject
	extrn	bbObjectClass
	extrn	bbObjectCompare
	extrn	bbObjectCtor
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
	extrn	brl_blitz_NullObjectError
	public	__bb_source_basefunctions_asset
	public	_bb_TAsset_CreateBaseAsset
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
	push	ebx
	cmp	dword [_71],0
	je	_72
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_72:
	mov	dword [_71],1
	push	ebp
	push	_69
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	__bb_blitz_blitz
	call	__bb_glmax2d_glmax2d
	push	bb_TAsset
	call	bbObjectRegisterType
	add	esp,4
	mov	ebx,0
	jmp	_32
_32:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_74
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TAsset
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],_2
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],_3
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+24],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+28],0
	push	ebp
	push	_73
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_35
_35:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_CreateBaseAsset:
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
	push	_93
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_77
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TAsset
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-12],eax
	push	_80
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_82
	call	brl_blitz_NullObjectError
_82:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+8],eax
	push	_84
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_86
	call	brl_blitz_NullObjectError
_86:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+12],eax
	push	_88
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_90
	call	brl_blitz_NullObjectError
_90:
	mov	dword [ebx+20],0
	push	_92
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_39
_39:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_GetName:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_100
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_97
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_99
	call	brl_blitz_NullObjectError
_99:
	mov	ebx,dword [ebx+16]
	jmp	_42
_42:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_SetName:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_105
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_101
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_103
	call	brl_blitz_NullObjectError
_103:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+16],eax
	mov	ebx,0
	jmp	_46
_46:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_GetUrl:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_110
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_107
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_109
	call	brl_blitz_NullObjectError
_109:
	mov	ebx,dword [ebx+24]
	jmp	_49
_49:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_SetUrl:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_115
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_111
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_113
	call	brl_blitz_NullObjectError
_113:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+24],eax
	mov	ebx,0
	jmp	_53
_53:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_GetType:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_120
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_117
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_119
	call	brl_blitz_NullObjectError
_119:
	mov	ebx,dword [ebx+8]
	jmp	_56
_56:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_SetType:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_125
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_121
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_123
	call	brl_blitz_NullObjectError
_123:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+8],eax
	mov	ebx,0
	jmp	_60
_60:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_GetLoaded:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_129
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_126
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_128
	call	brl_blitz_NullObjectError
_128:
	mov	ebx,dword [ebx+20]
	jmp	_63
_63:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TAsset_SetLoaded:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_134
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_130
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_132
	call	brl_blitz_NullObjectError
_132:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+20],eax
	mov	ebx,0
	jmp	_67
_67:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_71:
	dd	0
_70:
	db	"basefunctions_asset",0
	align	4
_69:
	dd	1
	dd	_70
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
	db	"CreateBaseAsset",0
_18:
	db	"(:Object,$):TAsset",0
_19:
	db	"GetName",0
_20:
	db	"()$",0
_21:
	db	"SetName",0
_22:
	db	"($)i",0
_23:
	db	"GetUrl",0
_24:
	db	"():Object",0
_25:
	db	"SetUrl",0
_26:
	db	"(:Object)i",0
_27:
	db	"GetType",0
_28:
	db	"SetType",0
_29:
	db	"GetLoaded",0
_30:
	db	"SetLoaded",0
_31:
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
	dd	7
	dd	_17
	dd	_18
	dd	48
	dd	6
	dd	_19
	dd	_20
	dd	52
	dd	6
	dd	_21
	dd	_22
	dd	56
	dd	6
	dd	_23
	dd	_24
	dd	60
	dd	6
	dd	_25
	dd	_26
	dd	64
	dd	6
	dd	_27
	dd	_20
	dd	68
	dd	6
	dd	_28
	dd	_22
	dd	72
	dd	6
	dd	_29
	dd	_16
	dd	76
	dd	6
	dd	_30
	dd	_31
	dd	80
	dd	0
	align	4
bb_TAsset:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_4
	dd	32
	dd	_bb_TAsset_New
	dd	bbObjectDtor
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
_75:
	db	"Self",0
_76:
	db	":TAsset",0
	align	4
_74:
	dd	1
	dd	_15
	dd	2
	dd	_75
	dd	_76
	dd	-4
	dd	0
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
	align	4
_73:
	dd	3
	dd	0
	dd	0
_94:
	db	"obj",0
_95:
	db	"objtype",0
_96:
	db	"tmpobj",0
	align	4
_93:
	dd	1
	dd	_17
	dd	2
	dd	_94
	dd	_9
	dd	-4
	dd	2
	dd	_95
	dd	_7
	dd	-8
	dd	2
	dd	_96
	dd	_76
	dd	-12
	dd	0
_78:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_asset.bmx",0
	align	4
_77:
	dd	_78
	dd	13
	dd	3
	align	4
_80:
	dd	_78
	dd	14
	dd	3
	align	4
_84:
	dd	_78
	dd	15
	dd	3
	align	4
_88:
	dd	_78
	dd	16
	dd	3
	align	4
_92:
	dd	_78
	dd	17
	dd	3
	align	4
_100:
	dd	1
	dd	_19
	dd	2
	dd	_75
	dd	_76
	dd	-4
	dd	0
	align	4
_97:
	dd	_78
	dd	21
	dd	3
_106:
	db	"name",0
	align	4
_105:
	dd	1
	dd	_21
	dd	2
	dd	_75
	dd	_76
	dd	-4
	dd	2
	dd	_106
	dd	_7
	dd	-8
	dd	0
	align	4
_101:
	dd	_78
	dd	25
	dd	3
	align	4
_110:
	dd	1
	dd	_23
	dd	2
	dd	_75
	dd	_76
	dd	-4
	dd	0
	align	4
_107:
	dd	_78
	dd	29
	dd	3
_116:
	db	"url",0
	align	4
_115:
	dd	1
	dd	_25
	dd	2
	dd	_75
	dd	_76
	dd	-4
	dd	2
	dd	_116
	dd	_9
	dd	-8
	dd	0
	align	4
_111:
	dd	_78
	dd	33
	dd	3
	align	4
_120:
	dd	1
	dd	_27
	dd	2
	dd	_75
	dd	_76
	dd	-4
	dd	0
	align	4
_117:
	dd	_78
	dd	37
	dd	3
	align	4
_125:
	dd	1
	dd	_28
	dd	2
	dd	_75
	dd	_76
	dd	-4
	dd	2
	dd	_106
	dd	_7
	dd	-8
	dd	0
	align	4
_121:
	dd	_78
	dd	41
	dd	3
	align	4
_129:
	dd	1
	dd	_29
	dd	2
	dd	_75
	dd	_76
	dd	-4
	dd	0
	align	4
_126:
	dd	_78
	dd	45
	dd	3
_135:
	db	"loaded",0
	align	4
_134:
	dd	1
	dd	_30
	dd	2
	dd	_75
	dd	_76
	dd	-4
	dd	2
	dd	_135
	dd	_12
	dd	-8
	dd	0
	align	4
_130:
	dd	_78
	dd	49
	dd	3
