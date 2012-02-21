	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_polledinput_polledinput
	extrn	__bb_system_system
	extrn	bbArrayNew
	extrn	bbArrayNew1D
	extrn	bbGCFree
	extrn	bbMilliSecs
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
	extrn	brl_polledinput_KeyDown
	extrn	brl_polledinput_MouseDown
	extrn	brl_polledinput_MouseHit
	extrn	brl_polledinput_MouseX
	extrn	brl_polledinput_MouseY
	public	__bb_source_basefunctions_keymanager
	public	_bb_TKeyManager_Delete
	public	_bb_TKeyManager_IsDown
	public	_bb_TKeyManager_IsHit
	public	_bb_TKeyManager_New
	public	_bb_TKeyManager_changeStatus
	public	_bb_TKeyManager_getStatus
	public	_bb_TKeyManager_isNormal
	public	_bb_TKeyManager_isUp
	public	_bb_TKeyManager_resetKey
	public	_bb_TKeyWrapper_Delete
	public	_bb_TKeyWrapper_New
	public	_bb_TKeyWrapper_allowKey
	public	_bb_TKeyWrapper_hitKey
	public	_bb_TKeyWrapper_holdKey
	public	_bb_TKeyWrapper_pressedKey
	public	_bb_TKeyWrapper_resetKey
	public	_bb_TMouseManager_Delete
	public	_bb_TMouseManager_IsDown
	public	_bb_TMouseManager_IsHit
	public	_bb_TMouseManager_New
	public	_bb_TMouseManager_SetDown
	public	_bb_TMouseManager_changeStatus
	public	_bb_TMouseManager_getStatus
	public	_bb_TMouseManager_isNormal
	public	_bb_TMouseManager_isUp
	public	_bb_TMouseManager_resetKey
	public	bb_KEYMANAGER
	public	bb_KEYWRAPPER
	public	bb_MOUSEMANAGER
	public	bb_TKeyManager
	public	bb_TKeyWrapper
	public	bb_TMouseManager
	section	"code" executable
__bb_source_basefunctions_keymanager:
	push	ebp
	mov	ebp,esp
	push	ebx
	cmp	dword [_156],0
	je	_157
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_157:
	mov	dword [_156],1
	call	__bb_blitz_blitz
	call	__bb_system_system
	call	__bb_polledinput_polledinput
	call	__bb_glmax2d_glmax2d
	push	bb_TMouseManager
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TKeyManager
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TKeyWrapper
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,dword [_147]
	and	eax,1
	cmp	eax,0
	jne	_148
	push	bb_TMouseManager
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	dword [bb_MOUSEMANAGER],eax
	or	dword [_147],1
_148:
	mov	eax,dword [_147]
	and	eax,2
	cmp	eax,0
	jne	_150
	push	bb_TKeyManager
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	dword [bb_KEYMANAGER],eax
	or	dword [_147],2
_150:
	mov	eax,dword [_147]
	and	eax,4
	cmp	eax,0
	jne	_152
	push	bb_TKeyWrapper
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	dword [bb_KEYWRAPPER],eax
	or	dword [_147],4
_152:
	mov	ebx,0
	jmp	_154
_4:
	mov	eax,dword [bb_KEYWRAPPER]
	push	100
	push	600
	push	3
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,20
_2:
	add	ebx,1
_154:
	cmp	ebx,255
	jle	_4
_3:
	mov	eax,0
	jmp	_44
_44:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TMouseManager
	mov	dword [ebx+8],0
	mov	dword [ebx+12],0
	mov	byte [ebx+16],0
	mov	dword [ebx+20],0
	push	4
	push	_158
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [ebx+24],eax
	mov	eax,0
	jmp	_47
_47:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_50:
	mov	eax,dword [eax+24]
	dec	dword [eax+4]
	jnz	_162
	push	eax
	call	bbGCFree
	add	esp,4
_162:
	mov	eax,0
	jmp	_160
_160:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_isNormal:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+24]
	cmp	dword [eax+edx*4+24],0
	jne	_163
	mov	eax,1
	jmp	_54
_163:
	mov	eax,0
	jmp	_54
_54:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_IsHit:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+24]
	cmp	dword [eax+edx*4+24],1
	jne	_165
	mov	eax,1
	jmp	_58
_165:
	mov	eax,0
	jmp	_58
_58:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_IsDown:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+24]
	cmp	dword [eax+edx*4+24],2
	jne	_167
	mov	eax,1
	jmp	_62
_167:
	mov	eax,0
	jmp	_62
_62:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_isUp:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+24]
	cmp	dword [eax+edx*4+24],3
	jne	_169
	mov	eax,1
	jmp	_66
_169:
	mov	eax,0
	jmp	_66
_66:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_SetDown:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+24]
	mov	dword [eax+edx*4+24],2
	mov	eax,0
	jmp	_70
_70:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_changeStatus:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	dword [esi+20],eax
	mov	byte [esi+16],0
	mov	ebx,dword [esi+8]
	call	brl_polledinput_MouseX
	cmp	ebx,eax
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_171
	mov	ebx,dword [esi+12]
	call	brl_polledinput_MouseY
	cmp	ebx,eax
	setne	al
	movzx	eax,al
_171:
	cmp	eax,0
	je	_173
	mov	byte [esi+16],1
	call	brl_polledinput_MouseX
	mov	dword [esi+8],eax
	call	brl_polledinput_MouseY
	mov	dword [esi+12],eax
_173:
	mov	ebx,1
	jmp	_175
_7:
	mov	eax,dword [esi+24]
	cmp	dword [eax+ebx*4+24],0
	jne	_176
	push	ebx
	call	brl_polledinput_MouseHit
	add	esp,4
	cmp	eax,0
	je	_177
	mov	eax,dword [esi+24]
	mov	dword [eax+ebx*4+24],1
_177:
	jmp	_178
_176:
	mov	eax,dword [esi+24]
	cmp	dword [eax+ebx*4+24],1
	jne	_179
	push	ebx
	call	brl_polledinput_MouseDown
	add	esp,4
	cmp	eax,0
	je	_180
	mov	eax,dword [esi+24]
	mov	dword [eax+ebx*4+24],2
	jmp	_181
_180:
	mov	eax,dword [esi+24]
	mov	dword [eax+ebx*4+24],3
_181:
	jmp	_182
_179:
	mov	eax,dword [esi+24]
	cmp	dword [eax+ebx*4+24],2
	jne	_183
	push	ebx
	call	brl_polledinput_MouseDown
	add	esp,4
	cmp	eax,0
	jne	_184
	mov	eax,dword [esi+24]
	mov	dword [eax+ebx*4+24],3
_184:
	jmp	_185
_183:
	mov	eax,dword [esi+24]
	cmp	dword [eax+ebx*4+24],3
	jne	_186
	mov	eax,dword [esi+24]
	mov	dword [eax+ebx*4+24],0
_186:
_185:
_182:
_178:
_5:
	add	ebx,1
_175:
	cmp	ebx,3
	jle	_7
_6:
	mov	eax,0
	jmp	_74
_74:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_resetKey:
	push	ebp
	mov	ebp,esp
	mov	ecx,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [ecx+24]
	mov	dword [eax+edx*4+24],3
	mov	eax,dword [ecx+24]
	mov	eax,dword [eax+edx*4+24]
	jmp	_78
_78:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TMouseManager_getStatus:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+24]
	mov	eax,dword [eax+edx*4+24]
	jmp	_82
_82:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TKeyManager
	push	256
	push	_187
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,0
	jmp	_85
_85:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_88:
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_191
	push	eax
	call	bbGCFree
	add	esp,4
_191:
	mov	eax,0
	jmp	_189
_189:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_isNormal:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+8]
	cmp	dword [eax+edx*4+24],0
	jne	_192
	mov	eax,1
	jmp	_92
_192:
	mov	eax,0
	jmp	_92
_92:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_IsHit:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+8]
	cmp	dword [eax+edx*4+24],1
	jne	_194
	mov	eax,1
	jmp	_96
_194:
	mov	eax,0
	jmp	_96
_96:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_IsDown:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+8]
	cmp	dword [eax+edx*4+24],2
	jne	_196
	mov	eax,1
	jmp	_100
_196:
	mov	eax,0
	jmp	_100
_100:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_isUp:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+8]
	cmp	dword [eax+edx*4+24],3
	jne	_198
	mov	eax,1
	jmp	_104
_198:
	mov	eax,0
	jmp	_104
_104:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_changeStatus:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,1
	jmp	_201
_10:
	mov	eax,dword [esi+8]
	cmp	dword [eax+ebx*4+24],0
	jne	_202
	push	ebx
	call	brl_polledinput_KeyDown
	add	esp,4
	cmp	eax,0
	je	_203
	mov	eax,dword [esi+8]
	mov	dword [eax+ebx*4+24],1
_203:
	jmp	_204
_202:
	mov	eax,dword [esi+8]
	cmp	dword [eax+ebx*4+24],1
	jne	_205
	push	ebx
	call	brl_polledinput_KeyDown
	add	esp,4
	cmp	eax,0
	je	_206
	mov	eax,dword [esi+8]
	mov	dword [eax+ebx*4+24],2
	jmp	_207
_206:
	mov	eax,dword [esi+8]
	mov	dword [eax+ebx*4+24],3
_207:
	jmp	_208
_205:
	mov	eax,dword [esi+8]
	cmp	dword [eax+ebx*4+24],2
	jne	_209
	push	ebx
	call	brl_polledinput_KeyDown
	add	esp,4
	cmp	eax,0
	jne	_210
	mov	eax,dword [esi+8]
	mov	dword [eax+ebx*4+24],3
_210:
	jmp	_211
_209:
	mov	eax,dword [esi+8]
	cmp	dword [eax+ebx*4+24],3
	jne	_212
	mov	eax,dword [esi+8]
	mov	dword [eax+ebx*4+24],0
_212:
_211:
_208:
_204:
_8:
	add	ebx,1
_201:
	cmp	ebx,255
	jle	_10
_9:
	mov	eax,0
	jmp	_107
_107:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_getStatus:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+8]
	mov	eax,dword [eax+edx*4+24]
	jmp	_111
_111:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyManager_resetKey:
	push	ebp
	mov	ebp,esp
	mov	ecx,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [ecx+8]
	mov	dword [eax+edx*4+24],3
	mov	eax,dword [ecx+8]
	mov	eax,dword [eax+edx*4+24]
	jmp	_115
_115:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TKeyWrapper
	push	4
	push	256
	push	2
	push	_213
	call	bbArrayNew
	add	esp,16
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,0
	jmp	_118
_118:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_121:
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_217
	push	eax
	call	bbGCFree
	add	esp,4
_217:
	mov	eax,0
	jmp	_215
_215:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_allowKey:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edx,dword [ebp+8]
	mov	edi,dword [ebp+16]
	mov	eax,dword [ebp+20]
	mov	esi,dword [edx+8]
	mov	ebx,dword [ebp+12]
	mov	ecx,dword [edx+8]
	imul	ebx,dword [ecx+24]
	mov	dword [esi+ebx*4+28],edi
	mov	ecx,edi
	and	ecx,1
	cmp	ecx,0
	je	_218
	mov	esi,dword [edx+8]
	mov	ebx,dword [ebp+12]
	mov	ecx,dword [edx+8]
	imul	ebx,dword [ecx+24]
	mov	ecx,ebx
	add	ecx,1
	mov	dword [esi+ecx*4+28],eax
_218:
	mov	eax,edi
	and	eax,2
	cmp	eax,0
	je	_219
	mov	ecx,dword [edx+8]
	mov	eax,dword [ebp+12]
	mov	edx,dword [edx+8]
	imul	eax,dword [edx+24]
	add	eax,2
	mov	edx,dword [ebp+24]
	mov	dword [ecx+eax*4+28],edx
_219:
	mov	eax,0
	jmp	_128
_128:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_pressedKey:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	eax,dword [bb_KEYMANAGER]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	edx,eax
	mov	esi,dword [edi+8]
	mov	ecx,ebx
	mov	eax,dword [edi+8]
	imul	ecx,dword [eax+24]
	mov	ecx,dword [esi+ecx*4+28]
	cmp	edx,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_223
	cmp	edx,3
	sete	al
	movzx	eax,al
_223:
	cmp	eax,0
	je	_225
	mov	eax,0
	jmp	_132
_225:
	mov	eax,ecx
	and	eax,1
	cmp	eax,0
	je	_226
	cmp	edx,1
	sete	al
	movzx	eax,al
_226:
	cmp	eax,0
	je	_228
	mov	eax,edi
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,8
	jmp	_132
_228:
	and	ecx,2
	cmp	ecx,0
	je	_231
	mov	eax,edi
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	jmp	_132
_231:
_230:
	mov	eax,0
	jmp	_132
_132:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_hitKey:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edx,0
	mov	ebx,dword [esi+8]
	mov	ecx,dword [ebp+12]
	mov	eax,dword [esi+8]
	imul	ecx,dword [eax+24]
	mov	eax,dword [ebx+ecx*4+28]
	cmp	edx,1
	je	_235
	mov	eax,0
	jmp	_136
_235:
	and	eax,1
	cmp	eax,0
	je	_236
	mov	edi,dword [esi+8]
	mov	eax,dword [ebp+12]
	mov	edx,dword [esi+8]
	imul	eax,dword [edx+24]
	mov	ebx,eax
	add	ebx,3
	call	bbMilliSecs
	mov	ecx,eax
	mov	edx,dword [esi+8]
	mov	eax,dword [ebp+12]
	mov	esi,dword [esi+8]
	imul	eax,dword [esi+24]
	add	eax,1
	add	ecx,dword [edx+eax*4+28]
	mov	dword [edi+ebx*4+28],ecx
	mov	eax,1
	jmp	_136
_236:
	mov	eax,0
	jmp	_136
_136:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_holdKey:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	mov	ecx,dword [esi+8]
	mov	edx,edi
	mov	eax,dword [esi+8]
	imul	edx,dword [eax+24]
	mov	eax,dword [ecx+edx*4+28]
	and	eax,2
	cmp	eax,0
	je	_238
	mov	edx,dword [esi+8]
	mov	eax,edi
	mov	ecx,dword [esi+8]
	imul	eax,dword [ecx+24]
	add	eax,3
	mov	ebx,dword [edx+eax*4+28]
	call	bbMilliSecs
	cmp	eax,ebx
	jle	_240
	mov	eax,dword [esi+8]
	mov	dword [ebp-4],eax
	mov	eax,edi
	mov	edx,dword [esi+8]
	imul	eax,dword [edx+24]
	mov	ebx,eax
	add	ebx,3
	call	bbMilliSecs
	mov	edx,dword [esi+8]
	mov	ecx,edi
	mov	esi,dword [esi+8]
	imul	ecx,dword [esi+24]
	add	ecx,2
	add	eax,dword [edx+ecx*4+28]
	mov	edx,dword [ebp-4]
	mov	dword [edx+ebx*4+28],eax
	mov	eax,1
	jmp	_140
_240:
_238:
	mov	eax,0
	jmp	_140
_140:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TKeyWrapper_resetKey:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ecx,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	esi,dword [ecx+8]
	mov	ebx,edx
	mov	eax,dword [ecx+8]
	imul	ebx,dword [eax+24]
	mov	dword [esi+ebx*4+28],0
	mov	ebx,dword [ecx+8]
	mov	eax,edx
	mov	esi,dword [ecx+8]
	imul	eax,dword [esi+24]
	add	eax,1
	mov	dword [ebx+eax*4+28],0
	mov	ebx,dword [ecx+8]
	mov	eax,edx
	mov	esi,dword [ecx+8]
	imul	eax,dword [esi+24]
	add	eax,2
	mov	dword [ebx+eax*4+28],0
	mov	eax,dword [ecx+8]
	mov	ecx,dword [ecx+8]
	imul	edx,dword [ecx+24]
	add	edx,3
	mov	dword [eax+edx*4+28],0
	mov	eax,0
	jmp	_144
_144:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_156:
	dd	0
_12:
	db	"TMouseManager",0
_13:
	db	"LastMouseX",0
_14:
	db	"i",0
_15:
	db	"LastMouseY",0
_16:
	db	"MousePosChanged",0
_17:
	db	"b",0
_18:
	db	"errorboxes",0
_19:
	db	"_iKeyStatus",0
_20:
	db	"[]i",0
_21:
	db	"New",0
_22:
	db	"()i",0
_23:
	db	"Delete",0
_24:
	db	"isNormal",0
_25:
	db	"(i)i",0
_26:
	db	"IsHit",0
_27:
	db	"IsDown",0
_28:
	db	"isUp",0
_29:
	db	"SetDown",0
_30:
	db	"changeStatus",0
_31:
	db	"resetKey",0
_32:
	db	"getStatus",0
	align	4
_11:
	dd	2
	dd	_12
	dd	3
	dd	_13
	dd	_14
	dd	8
	dd	3
	dd	_15
	dd	_14
	dd	12
	dd	3
	dd	_16
	dd	_17
	dd	16
	dd	3
	dd	_18
	dd	_14
	dd	20
	dd	3
	dd	_19
	dd	_20
	dd	24
	dd	6
	dd	_21
	dd	_22
	dd	16
	dd	6
	dd	_23
	dd	_22
	dd	20
	dd	6
	dd	_24
	dd	_25
	dd	48
	dd	6
	dd	_26
	dd	_25
	dd	52
	dd	6
	dd	_27
	dd	_25
	dd	56
	dd	6
	dd	_28
	dd	_25
	dd	60
	dd	6
	dd	_29
	dd	_25
	dd	64
	dd	6
	dd	_30
	dd	_25
	dd	68
	dd	6
	dd	_31
	dd	_25
	dd	72
	dd	6
	dd	_32
	dd	_25
	dd	76
	dd	0
	align	4
bb_TMouseManager:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_11
	dd	28
	dd	_bb_TMouseManager_New
	dd	_bb_TMouseManager_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TMouseManager_isNormal
	dd	_bb_TMouseManager_IsHit
	dd	_bb_TMouseManager_IsDown
	dd	_bb_TMouseManager_isUp
	dd	_bb_TMouseManager_SetDown
	dd	_bb_TMouseManager_changeStatus
	dd	_bb_TMouseManager_resetKey
	dd	_bb_TMouseManager_getStatus
_34:
	db	"TKeyManager",0
	align	4
_33:
	dd	2
	dd	_34
	dd	3
	dd	_19
	dd	_20
	dd	8
	dd	6
	dd	_21
	dd	_22
	dd	16
	dd	6
	dd	_23
	dd	_22
	dd	20
	dd	6
	dd	_24
	dd	_25
	dd	48
	dd	6
	dd	_26
	dd	_25
	dd	52
	dd	6
	dd	_27
	dd	_25
	dd	56
	dd	6
	dd	_28
	dd	_25
	dd	60
	dd	6
	dd	_30
	dd	_22
	dd	64
	dd	6
	dd	_32
	dd	_25
	dd	68
	dd	6
	dd	_31
	dd	_25
	dd	72
	dd	0
	align	4
bb_TKeyManager:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_33
	dd	12
	dd	_bb_TKeyManager_New
	dd	_bb_TKeyManager_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TKeyManager_isNormal
	dd	_bb_TKeyManager_IsHit
	dd	_bb_TKeyManager_IsDown
	dd	_bb_TKeyManager_isUp
	dd	_bb_TKeyManager_changeStatus
	dd	_bb_TKeyManager_getStatus
	dd	_bb_TKeyManager_resetKey
_36:
	db	"TKeyWrapper",0
_37:
	db	"_iKeySet",0
_38:
	db	"[,]i",0
_39:
	db	"allowKey",0
_40:
	db	"(i,i,i,i)i",0
_41:
	db	"pressedKey",0
_42:
	db	"hitKey",0
_43:
	db	"holdKey",0
	align	4
_35:
	dd	2
	dd	_36
	dd	3
	dd	_37
	dd	_38
	dd	8
	dd	6
	dd	_21
	dd	_22
	dd	16
	dd	6
	dd	_23
	dd	_22
	dd	20
	dd	6
	dd	_39
	dd	_40
	dd	48
	dd	6
	dd	_41
	dd	_25
	dd	52
	dd	6
	dd	_42
	dd	_25
	dd	56
	dd	6
	dd	_43
	dd	_25
	dd	60
	dd	6
	dd	_31
	dd	_25
	dd	64
	dd	0
	align	4
bb_TKeyWrapper:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_35
	dd	12
	dd	_bb_TKeyWrapper_New
	dd	_bb_TKeyWrapper_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TKeyWrapper_allowKey
	dd	_bb_TKeyWrapper_pressedKey
	dd	_bb_TKeyWrapper_hitKey
	dd	_bb_TKeyWrapper_holdKey
	dd	_bb_TKeyWrapper_resetKey
	align	4
_147:
	dd	0
	align	4
bb_MOUSEMANAGER:
	dd	bbNullObject
	align	4
bb_KEYMANAGER:
	dd	bbNullObject
	align	4
bb_KEYWRAPPER:
	dd	bbNullObject
_158:
	db	"i",0
_187:
	db	"i",0
_213:
	db	"i",0
