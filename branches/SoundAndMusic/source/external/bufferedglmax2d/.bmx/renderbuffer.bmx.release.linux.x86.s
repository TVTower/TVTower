	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_glew_glew
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_graphics_graphics
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
	extrn	rb_add_vertices
	extrn	rb_destroy
	extrn	rb_init
	extrn	rb_lock_buffers
	extrn	rb_render
	extrn	rb_reset
	extrn	rb_set_alpha_func
	extrn	rb_set_blend_func
	extrn	rb_set_line_width
	extrn	rb_set_mode
	extrn	rb_set_scissor_test
	extrn	rb_set_texture
	extrn	rb_unlock_buffers
	extrn	rs_bind
	extrn	rs_copy
	extrn	rs_init
	extrn	rs_restore
	extrn	rs_set_texture
	public	__bb_bufferedglmax2d_renderbuffer
	public	_bb_TRenderBuffer_AddVerticesEx
	public	_bb_TRenderBuffer_Delete
	public	_bb_TRenderBuffer_LockBuffers
	public	_bb_TRenderBuffer_New
	public	_bb_TRenderBuffer_Render
	public	_bb_TRenderBuffer_Reset
	public	_bb_TRenderBuffer_SetAlphaFunc
	public	_bb_TRenderBuffer_SetBlendFunc
	public	_bb_TRenderBuffer_SetLineWidth
	public	_bb_TRenderBuffer_SetMode
	public	_bb_TRenderBuffer_SetScissorTest
	public	_bb_TRenderBuffer_SetTexture
	public	_bb_TRenderBuffer_UnlockBuffers
	public	_bb_TRenderState_Bind
	public	_bb_TRenderState_Clone
	public	_bb_TRenderState_Delete
	public	_bb_TRenderState_New
	public	_bb_TRenderState_Restore
	public	_bb_TRenderState_RestoreState
	public	_bb_TRenderState_SetTexture
	public	bb_TRenderBuffer
	public	bb_TRenderState
	section	"code" executable
__bb_bufferedglmax2d_renderbuffer:
	push	ebp
	mov	ebp,esp
	cmp	dword [_141],0
	je	_142
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_142:
	mov	dword [_141],1
	call	__bb_blitz_blitz
	call	__bb_graphics_graphics
	call	__bb_glew_glew
	call	__bb_glmax2d_glmax2d
	push	bb_TRenderState
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TRenderBuffer
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,0
	jmp	_63
_63:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderState_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TRenderState
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+24],0
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+28]
	mov	eax,dword [ebp-4]
	mov	dword [eax+32],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+36],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+40],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+44],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+48],0
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+52]
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rs_init
	add	esp,4
	mov	eax,0
	jmp	_66
_66:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderState_Delete:
	push	ebp
	mov	ebp,esp
_69:
	mov	eax,0
	jmp	_143
_143:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderState_Bind:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rs_bind
	add	esp,4
	mov	eax,0
	jmp	_72
_72:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderState_Restore:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rs_restore
	add	esp,4
	mov	eax,0
	jmp	_75
_75:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderState_Clone:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	bb_TRenderState
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rs_copy
	add	esp,8
	mov	eax,dword [ebp-8]
	jmp	_78
_78:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderState_SetTexture:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	call	rs_set_texture
	add	esp,4
	mov	eax,0
	jmp	_81
_81:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderState_RestoreState:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	cmp	dword [ebp-4],bbNullObject
	jne	_145
	push	0
	call	rs_restore
	add	esp,4
	jmp	_146
_145:
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rs_restore
	add	esp,4
_146:
	mov	eax,0
	jmp	_84
_84:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TRenderBuffer
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+24],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+28],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+32],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+36],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+40],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+44],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+48],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+52],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+56],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+60],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+64],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+68],0
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_init
	add	esp,4
	mov	eax,0
	jmp	_87
_87:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_Delete:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_destroy
	add	esp,4
_90:
	mov	eax,0
	jmp	_147
_147:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_SetTexture:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	push	eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_set_texture
	add	esp,8
	mov	eax,0
	jmp	_94
_94:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_SetMode:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	push	eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_set_mode
	add	esp,8
	mov	eax,0
	jmp	_98
_98:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_SetBlendFunc:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	edx,dword [ebp+12]
	mov	eax,dword [ebp+16]
	push	eax
	push	edx
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_set_blend_func
	add	esp,12
	mov	eax,0
	jmp	_103
_103:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_SetAlphaFunc:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	fld	dword [ebp+16]
	sub	esp,4
	fstp	dword [esp]
	push	eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_set_alpha_func
	add	esp,12
	mov	eax,0
	jmp	_108
_108:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_SetScissorTest:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	esi,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	mov	ecx,dword [ebp+20]
	mov	edx,dword [ebp+24]
	mov	eax,dword [ebp+28]
	push	eax
	push	edx
	push	ecx
	push	ebx
	push	esi
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_set_scissor_test
	add	esp,24
	mov	eax,0
	jmp	_116
_116:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_SetLineWidth:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_set_line_width
	add	esp,8
	mov	eax,0
	jmp	_120
_120:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_AddVerticesEx:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	ebx,dword [ebp+12]
	mov	ecx,dword [ebp+16]
	mov	edx,dword [ebp+20]
	mov	eax,dword [ebp+24]
	push	eax
	push	edx
	push	ecx
	push	ebx
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_add_vertices
	add	esp,20
	mov	eax,0
	jmp	_127
_127:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_LockBuffers:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_lock_buffers
	add	esp,4
	mov	eax,0
	jmp	_130
_130:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_UnlockBuffers:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_unlock_buffers
	add	esp,4
	mov	eax,0
	jmp	_133
_133:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_Render:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_render
	add	esp,4
	mov	eax,0
	jmp	_136
_136:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TRenderBuffer_Reset:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	rb_reset
	add	esp,4
	mov	eax,0
	jmp	_139
_139:
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_141:
	dd	0
_3:
	db	"TRenderState",0
_4:
	db	"texture_name",0
_5:
	db	"i",0
_6:
	db	"render_mode",0
_7:
	db	"blend_source",0
_8:
	db	"blend_dest",0
_9:
	db	"alpha_func",0
_10:
	db	"alpha_ref",0
_11:
	db	"f",0
_12:
	db	"sc_enabled",0
_13:
	db	"sc_x",0
_14:
	db	"sc_y",0
_15:
	db	"sc_w",0
_16:
	db	"sc_h",0
_17:
	db	"line_width",0
_18:
	db	"New",0
_19:
	db	"()i",0
_20:
	db	"Delete",0
_21:
	db	"Bind",0
_22:
	db	"Restore",0
_23:
	db	"Clone",0
_24:
	db	"():TRenderState",0
_25:
	db	"SetTexture",0
_26:
	db	"(i)i",0
_27:
	db	"RestoreState",0
_28:
	db	"(:TRenderState)i",0
	align	4
_2:
	dd	2
	dd	_3
	dd	3
	dd	_4
	dd	_5
	dd	8
	dd	3
	dd	_6
	dd	_5
	dd	12
	dd	3
	dd	_7
	dd	_5
	dd	16
	dd	3
	dd	_8
	dd	_5
	dd	20
	dd	3
	dd	_9
	dd	_5
	dd	24
	dd	3
	dd	_10
	dd	_11
	dd	28
	dd	3
	dd	_12
	dd	_5
	dd	32
	dd	3
	dd	_13
	dd	_5
	dd	36
	dd	3
	dd	_14
	dd	_5
	dd	40
	dd	3
	dd	_15
	dd	_5
	dd	44
	dd	3
	dd	_16
	dd	_5
	dd	48
	dd	3
	dd	_17
	dd	_11
	dd	52
	dd	6
	dd	_18
	dd	_19
	dd	_bb_TRenderState_New
	dd	6
	dd	_20
	dd	_19
	dd	_bb_TRenderState_Delete
	dd	6
	dd	_21
	dd	_19
	dd	_bb_TRenderState_Bind
	dd	6
	dd	_22
	dd	_19
	dd	_bb_TRenderState_Restore
	dd	6
	dd	_23
	dd	_24
	dd	_bb_TRenderState_Clone
	dd	7
	dd	_25
	dd	_26
	dd	_bb_TRenderState_SetTexture
	dd	7
	dd	_27
	dd	_28
	dd	_bb_TRenderState_RestoreState
	dd	0
	align	4
bb_TRenderState:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_2
	dd	56
	dd	_bb_TRenderState_New
	dd	_bb_TRenderState_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TRenderState_Bind
	dd	_bb_TRenderState_Restore
	dd	_bb_TRenderState_Clone
	dd	_bb_TRenderState_SetTexture
	dd	_bb_TRenderState_RestoreState
_30:
	db	"TRenderBuffer",0
_31:
	db	"_vertices",0
_32:
	db	"*b",0
_33:
	db	"_texcoords",0
_34:
	db	"_colors",0
_35:
	db	"_vertices_len",0
_36:
	db	"_texcoords_len",0
_37:
	db	"_colors_len",0
_38:
	db	"_index",0
_39:
	db	"_sets",0
_40:
	db	"_indices",0
_41:
	db	"_counts",0
_42:
	db	"_indices_length",0
_43:
	db	"_lock",0
_44:
	db	"_render_indices",0
_45:
	db	"_render_states",0
_46:
	db	"_state_capacity",0
_47:
	db	"_states_top",0
_48:
	db	"SetMode",0
_49:
	db	"SetBlendFunc",0
_50:
	db	"(i,i)i",0
_51:
	db	"SetAlphaFunc",0
_52:
	db	"(i,f)i",0
_53:
	db	"SetScissorTest",0
_54:
	db	"(i,i,i,i,i)i",0
_55:
	db	"SetLineWidth",0
_56:
	db	"(f)i",0
_57:
	db	"AddVerticesEx",0
_58:
	db	"(i,*b,*b,*b)i",0
_59:
	db	"LockBuffers",0
_60:
	db	"UnlockBuffers",0
_61:
	db	"Render",0
_62:
	db	"Reset",0
	align	4
_29:
	dd	2
	dd	_30
	dd	3
	dd	_31
	dd	_32
	dd	8
	dd	3
	dd	_33
	dd	_32
	dd	12
	dd	3
	dd	_34
	dd	_32
	dd	16
	dd	3
	dd	_35
	dd	_5
	dd	20
	dd	3
	dd	_36
	dd	_5
	dd	24
	dd	3
	dd	_37
	dd	_5
	dd	28
	dd	3
	dd	_38
	dd	_5
	dd	32
	dd	3
	dd	_39
	dd	_5
	dd	36
	dd	3
	dd	_40
	dd	_32
	dd	40
	dd	3
	dd	_41
	dd	_32
	dd	44
	dd	3
	dd	_42
	dd	_5
	dd	48
	dd	3
	dd	_43
	dd	_5
	dd	52
	dd	3
	dd	_44
	dd	_32
	dd	56
	dd	3
	dd	_45
	dd	_32
	dd	60
	dd	3
	dd	_46
	dd	_5
	dd	64
	dd	3
	dd	_47
	dd	_5
	dd	68
	dd	6
	dd	_18
	dd	_19
	dd	_bb_TRenderBuffer_New
	dd	6
	dd	_20
	dd	_19
	dd	_bb_TRenderBuffer_Delete
	dd	6
	dd	_25
	dd	_26
	dd	_bb_TRenderBuffer_SetTexture
	dd	6
	dd	_48
	dd	_26
	dd	_bb_TRenderBuffer_SetMode
	dd	6
	dd	_49
	dd	_50
	dd	_bb_TRenderBuffer_SetBlendFunc
	dd	6
	dd	_51
	dd	_52
	dd	_bb_TRenderBuffer_SetAlphaFunc
	dd	6
	dd	_53
	dd	_54
	dd	_bb_TRenderBuffer_SetScissorTest
	dd	6
	dd	_55
	dd	_56
	dd	_bb_TRenderBuffer_SetLineWidth
	dd	6
	dd	_57
	dd	_58
	dd	_bb_TRenderBuffer_AddVerticesEx
	dd	6
	dd	_59
	dd	_19
	dd	_bb_TRenderBuffer_LockBuffers
	dd	6
	dd	_60
	dd	_19
	dd	_bb_TRenderBuffer_UnlockBuffers
	dd	6
	dd	_61
	dd	_19
	dd	_bb_TRenderBuffer_Render
	dd	6
	dd	_62
	dd	_19
	dd	_bb_TRenderBuffer_Reset
	dd	0
	align	4
bb_TRenderBuffer:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_29
	dd	72
	dd	_bb_TRenderBuffer_New
	dd	_bb_TRenderBuffer_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TRenderBuffer_SetTexture
	dd	_bb_TRenderBuffer_SetMode
	dd	_bb_TRenderBuffer_SetBlendFunc
	dd	_bb_TRenderBuffer_SetAlphaFunc
	dd	_bb_TRenderBuffer_SetScissorTest
	dd	_bb_TRenderBuffer_SetLineWidth
	dd	_bb_TRenderBuffer_AddVerticesEx
	dd	_bb_TRenderBuffer_LockBuffers
	dd	_bb_TRenderBuffer_UnlockBuffers
	dd	_bb_TRenderBuffer_Render
	dd	_bb_TRenderBuffer_Reset
