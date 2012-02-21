	format	ELF
	extrn	__bb_basic_basic
	extrn	__bb_blitz_blitz
	extrn	__bb_font_font
	extrn	__bb_glmax2d_glmax2d
	extrn	bbEmptyString
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
	extrn	brl_blitz_NullObjectError
	extrn	brl_linkedlist_CreateList
	extrn	brl_max2d_LoadImageFont
	public	__bb_source_basefunctions_text
	public	_bb_TGW_FontManager_AddFont
	public	_bb_TGW_FontManager_Create
	public	_bb_TGW_FontManager_GW_GetFont
	public	_bb_TGW_FontManager_New
	public	_bb_TGW_Font_Create
	public	_bb_TGW_Font_New
	public	bb_TGW_Font
	public	bb_TGW_FontManager
	section	"code" executable
__bb_source_basefunctions_text:
	push	ebp
	mov	ebp,esp
	push	ebx
	cmp	dword [_62],0
	je	_63
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_63:
	mov	dword [_62],1
	push	ebp
	push	_60
	call	dword [bbOnDebugEnterScope]
	add	esp,8
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
	mov	ebx,0
	jmp	_31
_31:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_FontManager_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_65
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TGW_FontManager
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbNullObject
	mov	ebx,dword [ebp-4]
	call	brl_linkedlist_CreateList
	mov	dword [ebx+12],eax
	push	ebp
	push	_64
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_34
_34:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_FontManager_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	dword [ebp-4],bbNullObject
	push	ebp
	push	_76
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_68
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TGW_FontManager
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-4],eax
	push	_71
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_73
	call	brl_blitz_NullObjectError
_73:
	call	brl_linkedlist_CreateList
	mov	dword [ebx+12],eax
	push	_75
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	jmp	_36
_36:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_FontManager_GW_GetFont:
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
	mov	eax,dword [ebp+20]
	mov	dword [ebp-16],eax
	mov	dword [ebp-20],bbEmptyString
	mov	dword [ebp-24],bbNullObject
	mov	eax,ebp
	push	eax
	push	_162
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_78
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_3
	push	dword [ebp-8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_79
	mov	eax,dword [ebp-12]
	cmp	eax,-1
	sete	al
	movzx	eax,al
_79:
	cmp	eax,0
	je	_81
	mov	eax,dword [ebp-16]
	cmp	eax,-1
	sete	al
	movzx	eax,al
_81:
	cmp	eax,0
	je	_83
	mov	eax,ebp
	push	eax
	push	_89
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_84
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_86
	call	brl_blitz_NullObjectError
_86:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_88
	call	brl_blitz_NullObjectError
_88:
	mov	ebx,dword [ebx+24]
	call	dword [bbOnDebugLeaveScope]
	jmp	_42
_83:
	push	_90
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],-1
	jne	_91
	mov	eax,ebp
	push	eax
	push	_97
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_92
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_94
	call	brl_blitz_NullObjectError
_94:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_96
	call	brl_blitz_NullObjectError
_96:
	mov	eax,dword [ebx+16]
	mov	dword [ebp-12],eax
	call	dword [bbOnDebugLeaveScope]
_91:
	push	_98
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],-1
	jne	_99
	mov	eax,ebp
	push	eax
	push	_105
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_100
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_102
	call	brl_blitz_NullObjectError
_102:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_104
	call	brl_blitz_NullObjectError
_104:
	mov	eax,dword [ebx+20]
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_106
_99:
	mov	eax,ebp
	push	eax
	push	_108
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_107
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [ebp-16],4
	call	dword [bbOnDebugLeaveScope]
_106:
	push	_109
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_111
	call	brl_blitz_NullObjectError
_111:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_113
	call	brl_blitz_NullObjectError
_113:
	mov	eax,dword [ebx+12]
	mov	dword [ebp-20],eax
	push	_115
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],bbNullObject
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_118
	call	brl_blitz_NullObjectError
_118:
	mov	edi,dword [ebx+12]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_121
	call	brl_blitz_NullObjectError
_121:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_4
_6:
	cmp	ebx,bbNullObject
	jne	_126
	call	brl_blitz_NullObjectError
_126:
	push	bb_TGW_Font
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-24],eax
	cmp	dword [ebp-24],bbNullObject
	je	_4
	mov	eax,ebp
	push	eax
	push	_155
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_127
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-24]
	cmp	esi,bbNullObject
	jne	_129
	call	brl_blitz_NullObjectError
_129:
	push	dword [ebp-8]
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_132
	mov	esi,dword [ebp-24]
	cmp	esi,bbNullObject
	jne	_131
	call	brl_blitz_NullObjectError
_131:
	mov	eax,dword [esi+20]
	cmp	eax,dword [ebp-16]
	sete	al
	movzx	eax,al
_132:
	cmp	eax,0
	je	_134
	mov	eax,ebp
	push	eax
	push	_138
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_135
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-24]
	cmp	esi,bbNullObject
	jne	_137
	call	brl_blitz_NullObjectError
_137:
	mov	eax,dword [esi+12]
	mov	dword [ebp-20],eax
	call	dword [bbOnDebugLeaveScope]
_134:
	push	_139
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-24]
	cmp	esi,bbNullObject
	jne	_141
	call	brl_blitz_NullObjectError
_141:
	push	dword [ebp-8]
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_144
	mov	esi,dword [ebp-24]
	cmp	esi,bbNullObject
	jne	_143
	call	brl_blitz_NullObjectError
_143:
	mov	eax,dword [esi+16]
	cmp	eax,dword [ebp-12]
	sete	al
	movzx	eax,al
_144:
	cmp	eax,0
	je	_148
	mov	esi,dword [ebp-24]
	cmp	esi,bbNullObject
	jne	_147
	call	brl_blitz_NullObjectError
_147:
	mov	eax,dword [esi+20]
	cmp	eax,dword [ebp-16]
	sete	al
	movzx	eax,al
_148:
	cmp	eax,0
	je	_150
	mov	eax,ebp
	push	eax
	push	_154
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_151
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_153
	call	brl_blitz_NullObjectError
_153:
	mov	ebx,dword [ebx+24]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_42
_150:
	call	dword [bbOnDebugLeaveScope]
_4:
	cmp	ebx,bbNullObject
	jne	_124
	call	brl_blitz_NullObjectError
_124:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_6
_5:
	push	_157
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_159
	call	brl_blitz_NullObjectError
_159:
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-20]
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,20
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_161
	call	brl_blitz_NullObjectError
_161:
	mov	ebx,dword [ebx+24]
	jmp	_42
_42:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_FontManager_AddFont:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+20]
	mov	dword [ebp-16],eax
	mov	eax,dword [ebp+24]
	mov	dword [ebp-20],eax
	mov	dword [ebp-24],bbNullObject
	push	ebp
	push	_199
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_167
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],-1
	jne	_168
	push	ebp
	push	_174
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_169
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_171
	call	brl_blitz_NullObjectError
_171:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_173
	call	brl_blitz_NullObjectError
_173:
	mov	eax,dword [ebx+16]
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
_168:
	push	_175
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-20],-1
	jne	_176
	push	ebp
	push	_182
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_177
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_179
	call	brl_blitz_NullObjectError
_179:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_181
	call	brl_blitz_NullObjectError
_181:
	mov	eax,dword [ebx+20]
	mov	dword [ebp-20],eax
	call	dword [bbOnDebugLeaveScope]
_176:
	push	_183
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_1
	push	dword [ebp-12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_184
	push	ebp
	push	_190
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_185
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_187
	call	brl_blitz_NullObjectError
_187:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_189
	call	brl_blitz_NullObjectError
_189:
	mov	eax,dword [ebx+12]
	mov	dword [ebp-12],eax
	call	dword [bbOnDebugLeaveScope]
_184:
	push	_191
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-20]
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-8]
	call	dword [bb_TGW_Font+48]
	add	esp,16
	mov	dword [ebp-24],eax
	push	_193
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_195
	call	brl_blitz_NullObjectError
_195:
	mov	ebx,dword [ebx+12]
	cmp	ebx,bbNullObject
	jne	_197
	call	brl_blitz_NullObjectError
_197:
	push	dword [ebp-24]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	push	_198
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	jmp	_49
_49:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_Font_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_202
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TGW_Font
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbEmptyString
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],bbEmptyString
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+24],bbNullObject
	push	ebp
	push	_201
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_52
_52:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGW_Font_Create:
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
	push	_226
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_203
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TGW_Font
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-20],eax
	push	_205
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_207
	call	brl_blitz_NullObjectError
_207:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+8],eax
	push	_209
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_211
	call	brl_blitz_NullObjectError
_211:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+12],eax
	push	_213
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_215
	call	brl_blitz_NullObjectError
_215:
	mov	eax,dword [ebp-12]
	mov	dword [ebx+16],eax
	push	_217
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_219
	call	brl_blitz_NullObjectError
_219:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+20],eax
	push	_221
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_223
	call	brl_blitz_NullObjectError
_223:
	mov	eax,dword [ebp-16]
	add	eax,4
	push	eax
	push	dword [ebp-12]
	push	dword [ebp-8]
	call	brl_max2d_LoadImageFont
	add	esp,12
	mov	dword [ebx+24],eax
	push	_225
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	jmp	_58
_58:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_62:
	dd	0
_61:
	db	"basefunctions_text",0
	align	4
_60:
	dd	1
	dd	_61
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
	db	"Create",0
_16:
	db	"():TGW_FontManager",0
_17:
	db	"GW_GetFont",0
_18:
	db	"($,i,i):brl.max2d.TImageFont",0
_19:
	db	"AddFont",0
_20:
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
	dd	7
	dd	_15
	dd	_16
	dd	48
	dd	6
	dd	_17
	dd	_18
	dd	52
	dd	6
	dd	_19
	dd	_20
	dd	56
	dd	0
	align	4
bb_TGW_FontManager:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_7
	dd	16
	dd	_bb_TGW_FontManager_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TGW_FontManager_Create
	dd	_bb_TGW_FontManager_GW_GetFont
	dd	_bb_TGW_FontManager_AddFont
_22:
	db	"TGW_Font",0
_23:
	db	"FName",0
_24:
	db	"$",0
_25:
	db	"FFile",0
_26:
	db	"FSize",0
_27:
	db	"i",0
_28:
	db	"FStyle",0
_29:
	db	"FFont",0
_30:
	db	":brl.max2d.TImageFont",0
	align	4
_21:
	dd	2
	dd	_22
	dd	3
	dd	_23
	dd	_24
	dd	8
	dd	3
	dd	_25
	dd	_24
	dd	12
	dd	3
	dd	_26
	dd	_27
	dd	16
	dd	3
	dd	_28
	dd	_27
	dd	20
	dd	3
	dd	_29
	dd	_30
	dd	24
	dd	6
	dd	_13
	dd	_14
	dd	16
	dd	7
	dd	_15
	dd	_20
	dd	48
	dd	0
	align	4
bb_TGW_Font:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_21
	dd	28
	dd	_bb_TGW_Font_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TGW_Font_Create
_66:
	db	"Self",0
_67:
	db	":TGW_FontManager",0
	align	4
_65:
	dd	1
	dd	_13
	dd	2
	dd	_66
	dd	_67
	dd	-4
	dd	0
	align	4
_64:
	dd	3
	dd	0
	dd	0
_77:
	db	"tmpObj",0
	align	4
_76:
	dd	1
	dd	_15
	dd	2
	dd	_77
	dd	_67
	dd	-4
	dd	0
_69:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_text.bmx",0
	align	4
_68:
	dd	_69
	dd	12
	dd	3
	align	4
_71:
	dd	_69
	dd	13
	dd	3
	align	4
_75:
	dd	_69
	dd	14
	dd	3
_163:
	db	"_FName",0
_164:
	db	"_FSize",0
_165:
	db	"_FStyle",0
_166:
	db	"defaultFontFile",0
	align	4
_162:
	dd	1
	dd	_17
	dd	2
	dd	_66
	dd	_67
	dd	-4
	dd	2
	dd	_163
	dd	_24
	dd	-8
	dd	2
	dd	_164
	dd	_27
	dd	-12
	dd	2
	dd	_165
	dd	_27
	dd	-16
	dd	2
	dd	_166
	dd	_24
	dd	-20
	dd	0
	align	4
_78:
	dd	_69
	dd	18
	dd	3
	align	4
_3:
	dd	bbStringClass
	dd	2147483647
	dd	7
	dw	68,101,102,97,117,108,116
	align	4
_89:
	dd	3
	dd	0
	dd	0
	align	4
_84:
	dd	_69
	dd	18
	dd	63
	align	4
_90:
	dd	_69
	dd	19
	dd	3
	align	4
_97:
	dd	3
	dd	0
	dd	0
	align	4
_92:
	dd	_69
	dd	19
	dd	23
	align	4
_98:
	dd	_69
	dd	20
	dd	3
	align	4
_105:
	dd	3
	dd	0
	dd	0
	align	4
_100:
	dd	_69
	dd	20
	dd	24
	align	4
_108:
	dd	3
	dd	0
	dd	0
	align	4
_107:
	dd	_69
	dd	20
	dd	58
	align	4
_109:
	dd	_69
	dd	22
	dd	3
	align	4
_115:
	dd	_69
	dd	23
	dd	3
_156:
	db	"Font",0
	align	4
_155:
	dd	3
	dd	0
	dd	2
	dd	_156
	dd	_10
	dd	-24
	dd	0
	align	4
_127:
	dd	_69
	dd	24
	dd	4
	align	4
_138:
	dd	3
	dd	0
	dd	0
	align	4
_135:
	dd	_69
	dd	24
	dd	58
	align	4
_139:
	dd	_69
	dd	25
	dd	4
	align	4
_154:
	dd	3
	dd	0
	dd	0
	align	4
_151:
	dd	_69
	dd	25
	dd	82
	align	4
_157:
	dd	_69
	dd	27
	dd	3
_200:
	db	"_FFile",0
	align	4
_199:
	dd	1
	dd	_19
	dd	2
	dd	_66
	dd	_67
	dd	-4
	dd	2
	dd	_163
	dd	_24
	dd	-8
	dd	2
	dd	_200
	dd	_24
	dd	-12
	dd	2
	dd	_164
	dd	_27
	dd	-16
	dd	2
	dd	_165
	dd	_27
	dd	-20
	dd	2
	dd	_156
	dd	_10
	dd	-24
	dd	0
	align	4
_167:
	dd	_69
	dd	31
	dd	3
	align	4
_174:
	dd	3
	dd	0
	dd	0
	align	4
_169:
	dd	_69
	dd	31
	dd	23
	align	4
_175:
	dd	_69
	dd	32
	dd	3
	align	4
_182:
	dd	3
	dd	0
	dd	0
	align	4
_177:
	dd	_69
	dd	32
	dd	24
	align	4
_183:
	dd	_69
	dd	33
	dd	3
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_190:
	dd	3
	dd	0
	dd	0
	align	4
_185:
	dd	_69
	dd	33
	dd	23
	align	4
_191:
	dd	_69
	dd	35
	dd	3
	align	4
_193:
	dd	_69
	dd	36
	dd	3
	align	4
_198:
	dd	_69
	dd	37
	dd	3
	align	4
_202:
	dd	1
	dd	_13
	dd	2
	dd	_66
	dd	_10
	dd	-4
	dd	0
	align	4
_201:
	dd	3
	dd	0
	dd	0
	align	4
_226:
	dd	1
	dd	_15
	dd	2
	dd	_163
	dd	_24
	dd	-4
	dd	2
	dd	_200
	dd	_24
	dd	-8
	dd	2
	dd	_164
	dd	_27
	dd	-12
	dd	2
	dd	_165
	dd	_27
	dd	-16
	dd	2
	dd	_77
	dd	_10
	dd	-20
	dd	0
	align	4
_203:
	dd	_69
	dd	49
	dd	3
	align	4
_205:
	dd	_69
	dd	50
	dd	3
	align	4
_209:
	dd	_69
	dd	51
	dd	3
	align	4
_213:
	dd	_69
	dd	52
	dd	3
	align	4
_217:
	dd	_69
	dd	53
	dd	3
	align	4
_221:
	dd	_69
	dd	54
	dd	3
	align	4
_225:
	dd	_69
	dd	55
	dd	3
