	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_bufferedglmax2d_renderbuffer
	extrn	__bb_glgraphics_glgraphics
	extrn	__bb_max2d_max2d
	extrn	__bb_retro_retro
	extrn	_bb_TRenderBuffer_AddVerticesEx
	extrn	_bb_TRenderBuffer_Render
	extrn	_bb_TRenderBuffer_Reset
	extrn	_bb_TRenderBuffer_SetAlphaFunc
	extrn	_bb_TRenderBuffer_SetBlendFunc
	extrn	_bb_TRenderBuffer_SetLineWidth
	extrn	_bb_TRenderBuffer_SetMode
	extrn	_bb_TRenderBuffer_SetScissorTest
	extrn	_bb_TRenderBuffer_SetTexture
	extrn	_bb_TRenderState_RestoreState
	extrn	_bb_TRenderState_SetTexture
	extrn	_brl_max2d_TImageFrame_Delete
	extrn	_brl_max2d_TImageFrame_New
	extrn	_brl_max2d_TMax2DDriver_Delete
	extrn	_brl_max2d_TMax2DDriver_New
	extrn	bbArrayNew1D
	extrn	bbArraySlice
	extrn	bbCos
	extrn	bbEmptyArray
	extrn	bbExThrow
	extrn	bbFloatMax
	extrn	bbFloatMin
	extrn	bbFloatToInt
	extrn	bbGCFree
	extrn	bbIntMax
	extrn	bbIntMin
	extrn	bbMemAlloc
	extrn	bbMemFree
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
	extrn	bbSin
	extrn	bbStringClass
	extrn	bb_TRenderBuffer
	extrn	brl_glgraphics_GLGraphicsDriver
	extrn	brl_graphics_GraphicsSeq
	extrn	brl_max2d_TImageFrame
	extrn	brl_max2d_TMax2DDriver
	extrn	brl_max2d_TMax2DGraphics
	extrn	brl_pixmap_BytesPerPixel
	extrn	brl_pixmap_CreatePixmap
	extrn	brl_pixmap_ResizePixmap
	extrn	brl_pixmap_YFlipPixmap
	extrn	glClear
	extrn	glClearColor
	extrn	glDeleteTextures
	extrn	glDrawPixels
	extrn	glEnableClientState
	extrn	glGenTextures
	extrn	glGetIntegerv
	extrn	glGetTexLevelParameteriv
	extrn	glLoadIdentity
	extrn	glMatrixMode
	extrn	glOrtho
	extrn	glPixelStorei
	extrn	glRasterPos2i
	extrn	glReadPixels
	extrn	glTexImage2D
	extrn	glTexParameteri
	extrn	glTexSubImage2D
	extrn	glewInit
	public	__bb_bufferedglmax2d_bufferedglmax2d
	public	_bb_TBufferedGLMax2DDriver_AttachGraphics
	public	_bb_TBufferedGLMax2DDriver_Cls
	public	_bb_TBufferedGLMax2DDriver_CreateFrameFromPixmap
	public	_bb_TBufferedGLMax2DDriver_CreateGraphics
	public	_bb_TBufferedGLMax2DDriver_Delete
	public	_bb_TBufferedGLMax2DDriver_DrawLine
	public	_bb_TBufferedGLMax2DDriver_DrawOval
	public	_bb_TBufferedGLMax2DDriver_DrawPixmap
	public	_bb_TBufferedGLMax2DDriver_DrawPoly
	public	_bb_TBufferedGLMax2DDriver_DrawRect
	public	_bb_TBufferedGLMax2DDriver_Flip
	public	_bb_TBufferedGLMax2DDriver_GrabPixmap
	public	_bb_TBufferedGLMax2DDriver_GraphicsModes
	public	_bb_TBufferedGLMax2DDriver_MinimumTextureHeight
	public	_bb_TBufferedGLMax2DDriver_MinimumTextureWidth
	public	_bb_TBufferedGLMax2DDriver_New
	public	_bb_TBufferedGLMax2DDriver_Plot
	public	_bb_TBufferedGLMax2DDriver_RenderBuffer
	public	_bb_TBufferedGLMax2DDriver_Reset
	public	_bb_TBufferedGLMax2DDriver_SetAlpha
	public	_bb_TBufferedGLMax2DDriver_SetBlend
	public	_bb_TBufferedGLMax2DDriver_SetClsColor
	public	_bb_TBufferedGLMax2DDriver_SetColor
	public	_bb_TBufferedGLMax2DDriver_SetGraphics
	public	_bb_TBufferedGLMax2DDriver_SetLineWidth
	public	_bb_TBufferedGLMax2DDriver_SetResolution
	public	_bb_TBufferedGLMax2DDriver_SetTransform
	public	_bb_TBufferedGLMax2DDriver_SetViewport
	public	_bb_TBufferedGLMax2DDriver_ToString
	public	_bb_TBufferedGLMax2DDriver___blend_funcs
	public	_bb_TBufferedGLMax2DDriver__rectPoints
	public	_bb_TGLBufferedImageFrame_Delete
	public	_bb_TGLBufferedImageFrame_Draw
	public	_bb_TGLBufferedImageFrame_Init
	public	_bb_TGLBufferedImageFrame_New
	public	_bb_TGLPackedTexture_Buffer
	public	_bb_TGLPackedTexture_Delete
	public	_bb_TGLPackedTexture_GetUnused
	public	_bb_TGLPackedTexture_MergeEmpty
	public	_bb_TGLPackedTexture_MinPackingSize
	public	_bb_TGLPackedTexture_Name
	public	_bb_TGLPackedTexture_New
	public	_bb_TGLPackedTexture_Unload
	public	_bb_TGLTexturePack_Bind
	public	_bb_TGLTexturePack_Delete
	public	_bb_TGLTexturePack_GetUnused
	public	_bb_TGLTexturePack_Init
	public	_bb_TGLTexturePack_MergeEmpty
	public	_bb_TGLTexturePack_Name
	public	_bb_TGLTexturePack_New
	public	_bb_TGLTexturePack_Reset
	public	bb_BufferedGLMax2DDriver
	public	bb_TBufferedGLMax2DDriver
	public	bb_TGLBufferedImageFrame
	public	bb_TGLPackedTexture
	public	bb_TGLTexturePack
	section	"code" executable
__bb_bufferedglmax2d_bufferedglmax2d:
	push	ebp
	mov	ebp,esp
	cmp	dword [_404],0
	je	_405
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_405:
	mov	dword [_404],1
	call	__bb_blitz_blitz
	call	__bb_max2d_max2d
	call	__bb_glgraphics_glgraphics
	call	__bb_retro_retro
	call	__bb_bufferedglmax2d_renderbuffer
	push	bb_TGLPackedTexture
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TGLTexturePack
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TGLBufferedImageFrame
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,dword [_401]
	and	eax,1
	cmp	eax,0
	jne	_402
	push	20
	push	_42
	call	bbArrayNew1D
	add	esp,8
	mov	dword [eax+24],1
	mov	dword [eax+28],0
	mov	dword [eax+32],518
	mov	dword [eax+36],1
	mov	dword [eax+40],1
	mov	dword [eax+44],0
	mov	dword [eax+48],519
	mov	dword [eax+52],0
	mov	dword [eax+56],770
	mov	dword [eax+60],771
	mov	dword [eax+64],519
	mov	dword [eax+68],0
	mov	dword [eax+72],770
	mov	dword [eax+76],1
	mov	dword [eax+80],519
	mov	dword [eax+84],0
	mov	dword [eax+88],774
	mov	dword [eax+92],0
	mov	dword [eax+96],519
	mov	dword [eax+100],0
	inc	dword [eax+4]
	mov	dword [_bb_TBufferedGLMax2DDriver___blend_funcs],eax
	or	dword [_401],1
_402:
	push	bb_TBufferedGLMax2DDriver
	call	bbObjectRegisterType
	add	esp,4
	call	bb_BufferedGLMax2DDriver
	mov	eax,0
	jmp	_161
_161:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLPackedTexture_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TGLPackedTexture
	mov	dword [ebx+8],0
	fldz
	fstp	dword [ebx+12]
	fldz
	fstp	dword [ebx+16]
	fldz
	fstp	dword [ebx+20]
	fldz
	fstp	dword [ebx+24]
	mov	dword [ebx+28],0
	mov	dword [ebx+32],0
	mov	dword [ebx+36],0
	mov	dword [ebx+40],0
	mov	dword [ebx+44],0
	mov	dword [ebx+48],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+52],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+56],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+60],eax
	mov	eax,0
	jmp	_164
_164:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLPackedTexture_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_167:
	mov	eax,dword [ebx+60]
	dec	dword [eax+4]
	jnz	_411
	push	eax
	call	bbGCFree
	add	esp,4
_411:
	mov	eax,dword [ebx+56]
	dec	dword [eax+4]
	jnz	_413
	push	eax
	call	bbGCFree
	add	esp,4
_413:
	mov	eax,dword [ebx+52]
	dec	dword [eax+4]
	jnz	_415
	push	eax
	call	bbGCFree
	add	esp,4
_415:
	mov	eax,0
	jmp	_409
_409:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLPackedTexture_GetUnused:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	ebx,dword [_bb_TGLPackedTexture_MinPackingSize]
	push	dword [ebp+16]
	push	dword [ebp+12]
	call	bbIntMin
	add	esp,8
	cmp	ebx,eax
	setle	al
	movzx	eax,al
	cmp	eax,0
	je	_416
	push	dword [edi+40]
	push	dword [edi+36]
	call	bbIntMin
	add	esp,8
	cmp	eax,dword [_bb_TGLPackedTexture_MinPackingSize]
	setle	al
	movzx	eax,al
_416:
	cmp	eax,0
	je	_418
	mov	edx,bbNullObject
	jmp	_172
_418:
	mov	eax,dword [edi+8]
	cmp	eax,0
	jne	_419
	mov	eax,dword [edi+36]
	cmp	eax,dword [ebp+12]
	setl	al
	movzx	eax,al
_419:
	cmp	eax,0
	jne	_421
	mov	eax,dword [edi+40]
	cmp	eax,dword [ebp+16]
	setl	al
	movzx	eax,al
_421:
	cmp	eax,0
	je	_423
	mov	edx,bbNullObject
	mov	eax,dword [edi+56]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_425
	mov	eax,dword [edi+60]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
_425:
	cmp	eax,0
	je	_429
	mov	eax,dword [edi+60]
	mov	eax,dword [eax+8]
	cmp	eax,0
	jne	_427
	mov	eax,dword [edi+56]
	mov	eax,dword [eax+8]
_427:
	cmp	eax,0
	sete	al
	movzx	eax,al
_429:
	cmp	eax,0
	je	_431
	mov	eax,dword [ebp+16]
	cmp	dword [ebp+12],eax
	jl	_432
	mov	eax,dword [edi+60]
	mov	edx,dword [eax+36]
	sub	edx,dword [ebp+12]
	xor	eax,eax
	cmp	eax,edx
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_434
	mov	eax,dword [edi+56]
	mov	eax,dword [eax+36]
	sub	eax,dword [ebp+12]
	cmp	edx,eax
	setl	al
	movzx	eax,al
_434:
	cmp	eax,0
	je	_436
	mov	eax,dword [edi+60]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
	cmp	edx,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_438
	mov	eax,dword [edi+56]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
_438:
	jmp	_440
_436:
	mov	eax,dword [edi+56]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
	cmp	edx,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_442
	mov	eax,dword [edi+60]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
_442:
_440:
	jmp	_444
_432:
	mov	eax,dword [edi+60]
	mov	edx,dword [eax+40]
	sub	edx,dword [ebp+16]
	xor	eax,eax
	cmp	eax,edx
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_446
	mov	eax,dword [edi+56]
	mov	eax,dword [eax+40]
	sub	eax,dword [ebp+16]
	cmp	edx,eax
	setl	al
	movzx	eax,al
_446:
	cmp	eax,0
	je	_448
	mov	eax,dword [edi+60]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
	cmp	edx,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_450
	mov	eax,dword [edi+56]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
_450:
	jmp	_452
_448:
	mov	eax,dword [edi+56]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
	cmp	edx,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_454
	mov	eax,dword [edi+60]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
_454:
_452:
_444:
	jmp	_456
_431:
	cmp	edx,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_457
	mov	eax,dword [edi+56]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
_457:
	cmp	eax,0
	je	_459
	mov	eax,dword [edi+56]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
_459:
	cmp	edx,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_461
	mov	eax,dword [edi+60]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
_461:
	cmp	eax,0
	je	_463
	mov	eax,dword [edi+60]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edx,eax
_463:
_456:
	jmp	_172
_423:
	mov	eax,dword [edi+56]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_465
	mov	eax,dword [edi+60]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
_465:
	cmp	eax,0
	je	_467
	mov	eax,dword [edi+40]
	sub	eax,dword [ebp+16]
	mov	esi,eax
	mov	eax,dword [edi+36]
	sub	eax,dword [ebp+12]
	mov	dword [ebp-4],eax
	mov	eax,esi
	cmp	eax,0
	jne	_470
	mov	eax,dword [edi+60]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
_470:
	cmp	eax,0
	je	_472
	push	bb_TGLPackedTexture
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	dword [ebx+40],esi
	mov	eax,dword [edi+36]
	mov	dword [ebx+36],eax
	mov	eax,dword [edi+60]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+60]
	dec	dword [eax+4]
	jnz	_477
	push	eax
	call	bbGCFree
	add	esp,4
_477:
	mov	dword [ebx+60],esi
	mov	eax,dword [edi+52]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+52]
	dec	dword [eax+4]
	jnz	_481
	push	eax
	call	bbGCFree
	add	esp,4
_481:
	mov	dword [ebx+52],esi
	inc	dword [ebx+4]
	mov	eax,dword [edi+60]
	dec	dword [eax+4]
	jnz	_485
	push	eax
	call	bbGCFree
	add	esp,4
_485:
	mov	dword [edi+60],ebx
_472:
	mov	eax,dword [ebp-4]
	cmp	eax,0
	jne	_486
	mov	eax,dword [edi+56]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
_486:
	cmp	eax,0
	je	_488
	push	bb_TGLPackedTexture
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [ebp+16]
	mov	dword [ebx+40],eax
	mov	eax,dword [ebp-4]
	mov	dword [ebx+36],eax
	mov	eax,dword [edi+56]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+56]
	dec	dword [eax+4]
	jnz	_493
	push	eax
	call	bbGCFree
	add	esp,4
_493:
	mov	dword [ebx+56],esi
	mov	eax,dword [edi+52]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+52]
	dec	dword [eax+4]
	jnz	_497
	push	eax
	call	bbGCFree
	add	esp,4
_497:
	mov	dword [ebx+52],esi
	inc	dword [ebx+4]
	mov	eax,dword [edi+56]
	dec	dword [eax+4]
	jnz	_501
	push	eax
	call	bbGCFree
	add	esp,4
_501:
	mov	dword [edi+56],ebx
_488:
	jmp	_502
_467:
	push	bb_TGLPackedTexture
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [edi+56]
	dec	dword [eax+4]
	jnz	_506
	push	eax
	call	bbGCFree
	add	esp,4
_506:
	mov	dword [edi+56],ebx
	push	bb_TGLPackedTexture
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [edi+60]
	dec	dword [eax+4]
	jnz	_510
	push	eax
	call	bbGCFree
	add	esp,4
_510:
	mov	dword [edi+60],ebx
	mov	edx,dword [edi+40]
	sub	edx,dword [ebp+16]
	mov	eax,dword [edi+36]
	sub	eax,dword [ebp+12]
	cmp	edx,eax
	jge	_511
	mov	edx,dword [edi+56]
	mov	eax,dword [edi+36]
	sub	eax,dword [ebp+12]
	mov	dword [edx+36],eax
	mov	edx,dword [edi+56]
	mov	eax,dword [ebp+16]
	mov	dword [edx+40],eax
	mov	edx,dword [edi+60]
	mov	eax,dword [edi+36]
	mov	dword [edx+36],eax
	mov	edx,dword [edi+60]
	mov	eax,dword [edi+40]
	sub	eax,dword [ebp+16]
	mov	dword [edx+40],eax
	jmp	_512
_511:
	mov	edx,dword [edi+56]
	mov	eax,dword [edi+36]
	sub	eax,dword [ebp+12]
	mov	dword [edx+36],eax
	mov	edx,dword [edi+56]
	mov	eax,dword [edi+40]
	mov	dword [edx+40],eax
	mov	edx,dword [edi+60]
	mov	eax,dword [ebp+12]
	mov	dword [edx+36],eax
	mov	edx,dword [edi+60]
	mov	eax,dword [edi+40]
	sub	eax,dword [ebp+16]
	mov	dword [edx+40],eax
_512:
_502:
	mov	edx,dword [edi+56]
	mov	eax,dword [edi+28]
	add	eax,dword [ebp+12]
	mov	dword [edx+28],eax
	mov	edx,dword [edi+56]
	mov	eax,dword [edi+32]
	mov	dword [edx+32],eax
	mov	edx,dword [edi+60]
	mov	eax,dword [edi+28]
	mov	dword [edx+28],eax
	mov	edx,dword [edi+60]
	mov	eax,dword [edi+32]
	add	eax,dword [ebp+16]
	mov	dword [edx+32],eax
	mov	ebx,dword [edi+52]
	inc	dword [ebx+4]
	mov	eax,dword [edi+56]
	mov	eax,dword [eax+52]
	dec	dword [eax+4]
	jnz	_516
	push	eax
	call	bbGCFree
	add	esp,4
_516:
	mov	eax,dword [edi+56]
	mov	dword [eax+52],ebx
	mov	ebx,dword [edi+52]
	inc	dword [ebx+4]
	mov	eax,dword [edi+60]
	mov	eax,dword [eax+52]
	dec	dword [eax+4]
	jnz	_520
	push	eax
	call	bbGCFree
	add	esp,4
_520:
	mov	eax,dword [edi+60]
	mov	dword [eax+52],ebx
	mov	eax,dword [ebp+12]
	mov	dword [edi+36],eax
	mov	eax,dword [ebp+16]
	mov	dword [edi+40],eax
	mov	edx,edi
	jmp	_172
_172:
	mov	eax,edx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLPackedTexture_Buffer:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+12]
	mov	eax,dword [ebp+8]
	mov	dword [eax+8],1
	mov	edx,dword [ebx+12]
	mov	eax,dword [ebp+8]
	mov	dword [eax+44],edx
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebp+8]
	mov	dword [eax+48],edx
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	fmul	dword [eax+32]
	mov	eax,dword [ebp+8]
	fstp	dword [eax+12]
	mov	eax,dword [ebp+8]
	fld	dword [eax+12]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+44]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	fmul	dword [eax+32]
	faddp	st1,st0
	mov	eax,dword [ebp+8]
	fstp	dword [eax+20]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	fmul	dword [eax+36]
	mov	eax,dword [ebp+8]
	fstp	dword [eax+16]
	mov	eax,dword [ebp+8]
	fld	dword [eax+16]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+48]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	fmul	dword [eax+36]
	faddp	st1,st0
	mov	eax,dword [ebp+8]
	fstp	dword [eax+24]
	push	ebx
	call	_15
	add	esp,4
	mov	dword [ebp-16],eax
	mov	dword [ebp-12],0
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+8]
	mov	edi,dword [eax+32]
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	push	eax
	call	_bb_TRenderState_SetTexture
	add	esp,4
	mov	dword [ebp-4],0
	lea	eax,dword [ebp-4]
	push	eax
	push	3314
	call	glGetIntegerv
	add	esp,8
_6:
_4:
	mov	esi,dword [brl_pixmap_BytesPerPixel]
	mov	ecx,dword [ebx+24]
	mov	eax,dword [ebx+20]
	cdq
	idiv	dword [esi+ecx*4+24]
	push	eax
	push	3314
	call	glPixelStorei
	add	esp,8
	push	dword [ebx+8]
	push	5121
	push	dword [ebp-16]
	push	dword [ebx+16]
	push	dword [ebx+12]
	push	edi
	push	dword [ebp-8]
	push	dword [ebp-12]
	push	3553
	call	glTexSubImage2D
	add	esp,36
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	mov	eax,dword [eax+28]
	and	eax,4
	cmp	eax,0
	jne	_527
	jmp	_5
_527:
	mov	eax,dword [ebx+12]
	cmp	eax,1
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_528
	mov	eax,dword [ebx+16]
	cmp	eax,1
	sete	al
	movzx	eax,al
_528:
	cmp	eax,0
	je	_530
	jmp	_5
_530:
	add	dword [ebp-12],1
	mov	eax,dword [ebp-8]
	cdq
	and	edx,1
	add	eax,edx
	sar	eax,1
	mov	dword [ebp-8],eax
	mov	eax,edi
	cdq
	and	edx,1
	add	eax,edx
	sar	eax,1
	mov	edi,eax
	mov	eax,dword [ebx+12]
	cdq
	and	edx,1
	add	eax,edx
	sar	eax,1
	mov	ecx,eax
	cmp	ecx,0
	jne	_531
	mov	ecx,1
_531:
	mov	eax,dword [ebx+16]
	cdq
	and	edx,1
	add	eax,edx
	sar	eax,1
	cmp	eax,0
	jne	_533
	mov	eax,1
_533:
	push	eax
	push	ecx
	push	ebx
	call	brl_pixmap_ResizePixmap
	add	esp,12
	mov	ebx,eax
	jmp	_6
_5:
	push	dword [ebp-4]
	push	3314
	call	glPixelStorei
	add	esp,8
	mov	eax,0
	jmp	_176
_176:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLPackedTexture_Name:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+52]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	jmp	_179
_179:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLPackedTexture_Unload:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	dword [eax+8],0
	mov	eax,dword [eax+52]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	mov	eax,0
	jmp	_182
_182:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLPackedTexture_MergeEmpty:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	cmp	dword [esi+56],bbNullObject
	je	_537
	mov	eax,dword [esi+56]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,4
_537:
	cmp	dword [esi+60],bbNullObject
	je	_539
	mov	eax,dword [esi+60]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,4
_539:
	cmp	dword [esi+8],0
	je	_541
	mov	eax,0
	jmp	_185
_541:
	cmp	dword [esi+56],bbNullObject
	je	_542
	mov	eax,dword [esi+56]
	mov	eax,dword [eax+8]
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_543
	mov	eax,dword [esi+56]
	mov	eax,dword [eax+40]
	cmp	eax,dword [esi+40]
	sete	al
	movzx	eax,al
_543:
	cmp	eax,0
	je	_545
	mov	eax,dword [esi+56]
	mov	eax,dword [eax+36]
	add	dword [esi+36],eax
	mov	eax,dword [esi+56]
	mov	ebx,dword [eax+56]
	inc	dword [ebx+4]
	mov	eax,dword [esi+56]
	dec	dword [eax+4]
	jnz	_549
	push	eax
	call	bbGCFree
	add	esp,4
_549:
	mov	dword [esi+56],ebx
_545:
	mov	eax,dword [esi+60]
	mov	eax,dword [eax+8]
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_550
	mov	eax,dword [esi+60]
	mov	eax,dword [eax+36]
	cmp	eax,dword [esi+36]
	sete	al
	movzx	eax,al
_550:
	cmp	eax,0
	je	_552
	mov	eax,dword [esi+60]
	mov	eax,dword [eax+40]
	add	dword [esi+40],eax
	mov	eax,dword [esi+60]
	mov	ebx,dword [eax+60]
	inc	dword [ebx+4]
	mov	eax,dword [esi+60]
	dec	dword [eax+4]
	jnz	_556
	push	eax
	call	bbGCFree
	add	esp,4
_556:
	mov	dword [esi+60],ebx
_552:
_542:
	cmp	dword [esi+60],bbNullObject
	je	_557
	mov	eax,dword [esi+60]
	mov	eax,dword [eax+8]
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_558
	mov	eax,dword [esi+60]
	mov	eax,dword [eax+36]
	cmp	eax,dword [esi+36]
	sete	al
	movzx	eax,al
_558:
	cmp	eax,0
	je	_560
	mov	eax,dword [esi+60]
	mov	eax,dword [eax+40]
	add	dword [esi+40],eax
	mov	eax,dword [esi+60]
	mov	ebx,dword [eax+60]
	inc	dword [ebx+4]
	mov	eax,dword [esi+60]
	dec	dword [eax+4]
	jnz	_564
	push	eax
	call	bbGCFree
	add	esp,4
_564:
	mov	dword [esi+60],ebx
_560:
	mov	eax,dword [esi+56]
	mov	eax,dword [eax+8]
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_565
	mov	eax,dword [esi+56]
	mov	eax,dword [eax+40]
	cmp	eax,dword [esi+40]
	sete	al
	movzx	eax,al
_565:
	cmp	eax,0
	je	_567
	mov	eax,dword [esi+56]
	mov	eax,dword [eax+36]
	add	dword [esi+36],eax
	mov	eax,dword [esi+56]
	mov	ebx,dword [eax+56]
	inc	dword [ebx+4]
	mov	eax,dword [esi+56]
	dec	dword [eax+4]
	jnz	_571
	push	eax
	call	bbGCFree
	add	esp,4
_571:
	mov	dword [esi+56],ebx
_567:
_557:
	mov	eax,0
	jmp	_185
_185:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLTexturePack_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TGLTexturePack
	mov	dword [ebx+8],0
	mov	dword [ebx+12],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	dword [ebx+28],-1
	fldz
	fstp	dword [ebx+32]
	fldz
	fstp	dword [ebx+36]
	mov	eax,0
	jmp	_188
_188:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLTexturePack_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [brl_graphics_GraphicsSeq]
	cmp	dword [ebx+8],eax
	jne	_573
	lea	eax,dword [ebx+12]
	push	eax
	push	1
	call	glDeleteTextures
	add	esp,8
_573:
	mov	dword [ebx+12],0
	mov	dword [ebx+8],0
_191:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_576
	push	eax
	call	bbGCFree
	add	esp,4
_576:
	mov	eax,0
	jmp	_574
_574:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLTexturePack_Name:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	jmp	_194
_194:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLTexturePack_Bind:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	dword [eax+12]
	call	_bb_TRenderState_SetTexture
	add	esp,4
	mov	eax,0
	jmp	_197
_197:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLTexturePack_Reset:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	eax,dword [esi+8]
	cmp	dword [brl_graphics_GraphicsSeq],eax
	jne	_577
	lea	eax,dword [esi+12]
	push	eax
	push	1
	call	glDeleteTextures
	add	esp,8
_577:
	mov	eax,dword [brl_graphics_GraphicsSeq]
	mov	dword [esi+8],eax
	mov	dword [esi+12],0
	mov	edi,dword [esi+20]
	mov	ebx,dword [esi+24]
	lea	eax,dword [esi+12]
	push	eax
	push	1
	call	glGenTextures
	add	esp,8
	push	dword [esi+12]
	call	_bb_TRenderState_SetTexture
	add	esp,4
	push	0
	push	5121
	push	6406
	push	0
	push	dword [esi+24]
	push	dword [esi+20]
	push	32856
	push	0
	push	32868
	call	glTexImage2D
	add	esp,36
	mov	dword [ebp-4],0
	lea	eax,dword [ebp-4]
	push	eax
	push	4096
	push	0
	push	32868
	call	glGetTexLevelParameteriv
	add	esp,16
	cmp	dword [ebp-4],0
	jne	_581
	push	0
	call	_bb_TRenderState_SetTexture
	add	esp,4
	lea	eax,dword [esi+12]
	push	eax
	push	1
	call	glDeleteTextures
	add	esp,8
	push	_7
	call	bbExThrow
	add	esp,4
	mov	eax,0
	jmp	_200
_581:
	mov	eax,9728
	mov	dword [ebp-8],9728
	mov	edx,dword [esi+28]
	and	edx,2
	cmp	edx,0
	je	_584
	mov	eax,9729
	mov	edx,dword [esi+28]
	and	edx,4
	cmp	edx,0
	je	_585
	mov	dword [ebp-8],9987
	jmp	_586
_585:
	mov	dword [ebp-8],9729
_586:
	jmp	_587
_584:
	mov	edx,dword [esi+28]
	and	edx,4
	cmp	edx,0
	je	_588
	mov	dword [ebp-8],9984
_588:
_587:
	push	eax
	push	10240
	push	3553
	call	glTexParameteri
	add	esp,12
	push	dword [ebp-8]
	push	10241
	push	3553
	call	glTexParameteri
	add	esp,12
	mov	eax,edi
	imul	eax,ebx
	push	eax
	call	bbMemAlloc
	add	esp,4
	mov	dword [ebp-12],eax
	mov	esi,0
_10:
_8:
	push	dword [ebp-12]
	push	5121
	push	6406
	push	0
	push	ebx
	push	edi
	push	32856
	push	esi
	push	3553
	call	glTexImage2D
	add	esp,36
	cmp	edi,1
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_591
	cmp	ebx,1
	sete	al
	movzx	eax,al
_591:
	cmp	eax,0
	je	_593
	jmp	_9
_593:
	add	esi,1
	mov	eax,edi
	cdq
	and	edx,1
	add	eax,edx
	sar	eax,1
	cmp	eax,0
	jne	_594
	mov	eax,1
_594:
	mov	edi,eax
	mov	eax,ebx
	cdq
	and	edx,1
	add	eax,edx
	sar	eax,1
	cmp	eax,0
	jne	_596
	mov	eax,1
_596:
	mov	ebx,eax
	jmp	_10
_9:
	push	dword [ebp-12]
	call	bbMemFree
	add	esp,4
	mov	eax,0
	jmp	_200
_200:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLTexturePack_Init:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	ecx,dword [ebp+12]
	mov	edx,dword [ebp+16]
	mov	eax,dword [ebp+20]
	mov	dword [ebx+20],ecx
	mov	dword [ebx+24],edx
	mov	dword [ebx+28],eax
	fld	dword [_892]
	mov	eax,dword [ebx+20]
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	fdivp	st1,st0
	fstp	dword [ebx+32]
	fld	dword [_893]
	mov	eax,dword [ebx+24]
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	fdivp	st1,st0
	fstp	dword [ebx+36]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	push	bb_TGLPackedTexture
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_602
	push	eax
	call	bbGCFree
	add	esp,4
_602:
	mov	dword [ebx+16],esi
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+20]
	mov	dword [edx+36],eax
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+24]
	mov	dword [edx+40],eax
	mov	eax,dword [ebx+16]
	mov	dword [eax+28],0
	mov	eax,dword [ebx+16]
	mov	dword [eax+32],0
	inc	dword [ebx+4]
	mov	esi,ebx
	mov	eax,dword [ebx+16]
	mov	eax,dword [eax+52]
	dec	dword [eax+4]
	jnz	_606
	push	eax
	call	bbGCFree
	add	esp,4
_606:
	mov	eax,dword [ebx+16]
	mov	dword [eax+52],esi
	mov	eax,ebx
	jmp	_206
_206:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLTexturePack_GetUnused:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	ecx,dword [ebp+12]
	mov	edx,dword [ebp+16]
	cmp	ecx,dword [ebx+20]
	setg	al
	movzx	eax,al
	cmp	eax,0
	jne	_607
	cmp	edx,dword [ebx+24]
	setg	al
	movzx	eax,al
_607:
	cmp	eax,0
	je	_609
	mov	eax,bbNullObject
	jmp	_211
_609:
	mov	eax,dword [ebx+16]
	push	edx
	push	ecx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	jmp	_211
_211:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLTexturePack_MergeEmpty:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,4
	mov	eax,0
	jmp	_214
_214:
	mov	esp,ebp
	pop	ebp
	ret
_11:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,1
	jmp	_12
_14:
	shl	eax,1
_12:
	cmp	eax,edx
	jl	_14
_13:
	jmp	_217
_217:
	mov	esp,ebp
	pop	ebp
	ret
_15:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+24]
	cmp	eax,2
	je	_615
	cmp	eax,1
	je	_616
	cmp	eax,4
	je	_617
	cmp	eax,3
	je	_618
	cmp	eax,5
	je	_619
	mov	eax,6408
	jmp	_220
_615:
	mov	eax,32828
	jmp	_220
_616:
	mov	eax,32832
	jmp	_220
_617:
	mov	eax,6407
	jmp	_220
_618:
	mov	eax,32992
	jmp	_220
_619:
	mov	eax,32993
	jmp	_220
_220:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLBufferedImageFrame_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_brl_max2d_TImageFrame_New
	add	esp,4
	mov	dword [ebx],bb_TGLBufferedImageFrame
	mov	dword [ebx+8],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	push	8
	push	_621
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	eax,0
	jmp	_223
_223:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLBufferedImageFrame_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebx+8],0
	cmp	dword [ebx+12],bbNullObject
	je	_623
	mov	eax,dword [ebx+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
_623:
_226:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_627
	push	eax
	call	bbGCFree
	add	esp,4
_627:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_629
	push	eax
	call	bbGCFree
	add	esp,4
_629:
	mov	dword [ebx],brl_max2d_TImageFrame
	push	ebx
	call	_brl_max2d_TImageFrame_Delete
	add	esp,4
	mov	eax,0
	jmp	_625
_625:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLBufferedImageFrame_Init:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	eax,dword [brl_graphics_GraphicsSeq]
	mov	dword [esi+8],eax
	inc	dword [ebx+4]
	mov	eax,dword [esi+12]
	dec	dword [eax+4]
	jnz	_633
	push	eax
	call	bbGCFree
	add	esp,4
_633:
	mov	dword [esi+12],ebx
	mov	eax,esi
	jmp	_230
_230:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TGLBufferedImageFrame_Draw:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebx+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	push	eax
	mov	eax,dword [_403]
	push	dword [eax+8]
	call	_bb_TRenderBuffer_SetTexture
	add	esp,8
	push	5
	mov	eax,dword [_403]
	push	dword [eax+8]
	call	_bb_TRenderBuffer_SetMode
	add	esp,8
	fldz
	fld	dword [ebp+36]
	fucompp
	fnstsw	ax
	sahf
	setnz	al
	movzx	eax,al
	cmp	eax,0
	jne	_635
	fldz
	fld	dword [ebp+40]
	fucompp
	fnstsw	ax
	sahf
	setnz	al
	movzx	eax,al
_635:
	cmp	eax,0
	jne	_637
	mov	eax,dword [ebx+12]
	mov	eax,dword [eax+44]
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	fld	dword [ebp+44]
	fucompp
	fnstsw	ax
	sahf
	setnz	al
	movzx	eax,al
_637:
	cmp	eax,0
	jne	_639
	mov	eax,dword [ebx+12]
	mov	eax,dword [eax+48]
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	fld	dword [ebp+48]
	fucompp
	fnstsw	ax
	sahf
	setnz	al
	movzx	eax,al
_639:
	cmp	eax,0
	je	_641
	mov	eax,dword [ebx+12]
	fld	dword [eax+12]
	fld	dword [ebp+36]
	mov	eax,dword [ebx+12]
	mov	eax,dword [eax+52]
	fmul	dword [eax+32]
	faddp	st1,st0
	fld	st0
	fld	dword [ebp+44]
	mov	eax,dword [ebx+12]
	mov	eax,dword [eax+52]
	fmul	dword [eax+32]
	faddp	st1,st0
	mov	eax,dword [ebx+12]
	fld	dword [eax+16]
	fld	dword [ebp+40]
	mov	eax,dword [ebx+12]
	mov	eax,dword [eax+52]
	fmul	dword [eax+36]
	faddp	st1,st0
	fld	st0
	fld	dword [ebp+48]
	mov	eax,dword [ebx+12]
	mov	eax,dword [eax+52]
	fmul	dword [eax+36]
	faddp	st1,st0
	mov	eax,dword [ebx+16]
	fxch	st3
	fst	dword [eax+24]
	mov	eax,dword [ebx+16]
	fxch	st1
	fst	dword [eax+4+24]
	mov	eax,dword [ebx+16]
	fxch	st2
	fst	dword [eax+8+24]
	mov	eax,dword [ebx+16]
	fxch	st2
	fstp	dword [eax+12+24]
	mov	eax,dword [ebx+16]
	fstp	dword [eax+16+24]
	mov	eax,dword [ebx+16]
	fxch	st1
	fst	dword [eax+20+24]
	mov	eax,dword [ebx+16]
	fxch	st1
	fstp	dword [eax+24+24]
	mov	eax,dword [ebx+16]
	fstp	dword [eax+28+24]
	jmp	_646
_641:
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+12]
	fld	dword [eax+12]
	fstp	dword [edx+24]
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+12]
	fld	dword [eax+16]
	fstp	dword [edx+4+24]
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+12]
	fld	dword [eax+20]
	fstp	dword [edx+8+24]
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+12]
	fld	dword [eax+16]
	fstp	dword [edx+12+24]
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+12]
	fld	dword [eax+12]
	fstp	dword [edx+16+24]
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+12]
	fld	dword [eax+24]
	fstp	dword [edx+20+24]
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+12]
	fld	dword [eax+20]
	fstp	dword [edx+24+24]
	mov	edx,dword [ebx+16]
	mov	eax,dword [ebx+12]
	fld	dword [eax+24]
	fstp	dword [edx+28+24]
_646:
	mov	eax,dword [_403]
	push	dword [ebp+32]
	push	dword [ebp+28]
	push	dword [ebp+24]
	push	dword [ebp+20]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,28
	mov	dword [ebp-4],eax
	mov	eax,dword [_403]
	mov	eax,dword [eax+76]
	lea	eax,byte [eax+24]
	push	eax
	mov	eax,dword [ebx+16]
	lea	eax,byte [eax+24]
	push	eax
	mov	eax,dword [ebp-4]
	lea	eax,byte [eax+24]
	push	eax
	push	4
	mov	eax,dword [_403]
	push	dword [eax+8]
	call	_bb_TRenderBuffer_AddVerticesEx
	add	esp,20
	mov	eax,0
	jmp	_243
_243:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_brl_max2d_TMax2DDriver_New
	add	esp,4
	mov	dword [ebx],bb_TBufferedGLMax2DDriver
	push	bb_TRenderBuffer
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	byte [ebx+12],0
	mov	byte [ebx+13],0
	mov	byte [ebx+14],0
	mov	byte [ebx+15],0
	fld1
	fstp	dword [ebx+16]
	fldz
	fstp	dword [ebx+20]
	fldz
	fstp	dword [ebx+24]
	fld1
	fstp	dword [ebx+28]
	mov	dword [ebx+32],0
	mov	dword [ebx+36],0
	mov	dword [ebx+40],-2
	mov	dword [ebx+44],-1
	push	16
	push	_650
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [ebx+48],eax
	mov	dword [ebx+52],0
	mov	dword [ebx+56],-1
	mov	dword [ebx+60],0
	mov	dword [ebx+64],0
	mov	dword [ebx+68],0
	push	36
	push	_652
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [ebx+72],eax
	push	36
	push	_654
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [ebx+76],eax
	fld	dword [_938]
	fstp	dword [ebx+80]
	fld	dword [_939]
	fstp	dword [ebx+84]
	mov	eax,0
	jmp	_246
_246:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_249:
	mov	eax,dword [ebx+76]
	dec	dword [eax+4]
	jnz	_658
	push	eax
	call	bbGCFree
	add	esp,4
_658:
	mov	eax,dword [ebx+72]
	dec	dword [eax+4]
	jnz	_660
	push	eax
	call	bbGCFree
	add	esp,4
_660:
	mov	eax,dword [ebx+48]
	dec	dword [eax+4]
	jnz	_662
	push	eax
	call	bbGCFree
	add	esp,4
_662:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_664
	push	eax
	call	bbGCFree
	add	esp,4
_664:
	mov	dword [ebx],brl_max2d_TMax2DDriver
	push	ebx
	call	_brl_max2d_TMax2DDriver_Delete
	add	esp,4
	mov	eax,0
	jmp	_656
_656:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_Reset:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	call	glewInit
	push	32884
	call	glEnableClientState
	add	esp,4
	push	32886
	call	glEnableClientState
	add	esp,4
	push	32888
	call	glEnableClientState
	add	esp,4
	push	bbNullObject
	call	_bb_TRenderState_RestoreState
	add	esp,4
	mov	eax,edi
	push	dword [edi+84]
	push	dword [edi+80]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+132]
	add	esp,12
	mov	esi,0
	mov	eax,dword [edi+48]
	mov	eax,dword [eax+20]
	mov	dword [ebp-4],eax
	jmp	_667
_20:
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [edi+48]
	mov	eax,dword [eax+esi*4+24]
	dec	dword [eax+4]
	jnz	_672
	push	eax
	call	bbGCFree
	add	esp,4
_672:
	mov	eax,dword [edi+48]
	mov	dword [eax+esi*4+24],ebx
_18:
	add	esi,1
_667:
	cmp	esi,dword [ebp-4]
	jl	_20
_19:
	mov	eax,0
	jmp	_252
_252:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver__rectPoints:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	mov	eax,dword [ebp+8]
	fld	dword [ebp+12]
	fld	dword [ebp+16]
	fld	dword [ebp+20]
	fld	dword [ebp+24]
	fld	dword [ebp+28]
	fld	dword [ebp+32]
	fld	st5
	fmul	dword [eax+16]
	fstp	dword [ebp-12]
	fxch	st5
	fmul	dword [eax+24]
	fstp	dword [ebp-16]
	fld	st2
	fmul	dword [eax+16]
	fxch	st3
	fmul	dword [eax+24]
	fld	st4
	fmul	dword [eax+20]
	fxch	st5
	fmul	dword [eax+28]
	fstp	dword [ebp-8]
	fld	st2
	fmul	dword [eax+20]
	fxch	st3
	fmul	dword [eax+28]
	fstp	dword [ebp-4]
	mov	edx,dword [eax+72]
	fld	dword [ebp-12]
	fadd	st0,st5
	fadd	st0,st2
	fstp	dword [edx+24]
	mov	edx,dword [eax+72]
	fld	dword [ebp-16]
	fadd	dword [ebp-8]
	fadd	st0,st6
	fstp	dword [edx+4+24]
	mov	edx,dword [eax+72]
	fld	st3
	faddp	st5,st0
	fxch	st4
	fadd	st0,st1
	fstp	dword [edx+8+24]
	mov	edx,dword [eax+72]
	fld	st3
	fadd	dword [ebp-8]
	fadd	st0,st5
	fstp	dword [edx+12+24]
	mov	edx,dword [eax+72]
	fld	dword [ebp-12]
	fadd	st0,st2
	fadd	st0,st1
	fstp	dword [edx+16+24]
	mov	edx,dword [eax+72]
	fld	dword [ebp-16]
	fadd	dword [ebp-4]
	fadd	st0,st5
	fstp	dword [edx+20+24]
	mov	edx,dword [eax+72]
	fxch	st1
	faddp	st2,st0
	faddp	st1,st0
	fstp	dword [edx+24+24]
	mov	edx,dword [eax+72]
	fadd	dword [ebp-4]
	faddp	st1,st0
	fstp	dword [edx+28+24]
	mov	eax,dword [eax+72]
	jmp	_261
_261:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_GraphicsModes:
	push	ebp
	mov	ebp,esp
	call	brl_glgraphics_GLGraphicsDriver
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	jmp	_264
_264:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_AttachGraphics:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	edi,dword [ebp+16]
	call	brl_glgraphics_GLGraphicsDriver
	push	edi
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,12
	cmp	eax,bbNullObject
	je	_684
	push	esi
	push	eax
	call	dword [brl_max2d_TMax2DGraphics+80]
	add	esp,8
	jmp	_269
_684:
	mov	eax,bbNullObject
	jmp	_269
_269:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_CreateGraphics:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	edi,dword [ebp+16]
	call	brl_glgraphics_GLGraphicsDriver
	push	dword [ebp+28]
	push	dword [ebp+24]
	push	dword [ebp+20]
	push	edi
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,24
	cmp	eax,bbNullObject
	je	_687
	push	esi
	push	eax
	call	dword [brl_max2d_TMax2DGraphics+80]
	add	esp,8
	jmp	_277
_687:
	mov	eax,bbNullObject
	jmp	_277
_277:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_SetGraphics:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	edx,dword [ebp+12]
	cmp	edx,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_688
	call	dword [brl_max2d_TMax2DGraphics+72]
	call	brl_glgraphics_GLGraphicsDriver
	push	bbNullObject
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	mov	eax,0
	jmp	_281
_688:
	push	brl_max2d_TMax2DGraphics
	push	edx
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	call	brl_glgraphics_GLGraphicsDriver
	push	dword [ebx+132]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+136]
	add	esp,4
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	mov	eax,0
	jmp	_281
_281:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_Flip:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	push	dword [esi+8]
	call	_bb_TRenderBuffer_Render
	add	esp,4
	call	brl_glgraphics_GLGraphicsDriver
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	push	dword [esi+8]
	call	_bb_TRenderBuffer_Reset
	add	esp,4
	call	glLoadIdentity
	mov	eax,0
	jmp	_285
_285:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_CreateFrameFromPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	dword [ebp-4],0
	lea	eax,dword [ebp-4]
	push	eax
	push	3379
	call	glGetIntegerv
	add	esp,8
	mov	eax,dword [_bb_TBufferedGLMax2DDriver_MinimumTextureWidth]
	cmp	dword [ebp-4],eax
	jge	_698
	mov	eax,dword [ebp-4]
	mov	dword [_bb_TBufferedGLMax2DDriver_MinimumTextureWidth],eax
_698:
	mov	eax,dword [_bb_TBufferedGLMax2DDriver_MinimumTextureHeight]
	cmp	dword [ebp-4],eax
	jge	_699
	mov	eax,dword [ebp-4]
	mov	dword [_bb_TBufferedGLMax2DDriver_MinimumTextureHeight],eax
_699:
	mov	eax,dword [ebp+12]
	cmp	dword [eax+24],6
	je	_700
	mov	eax,dword [ebp+12]
	push	6
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebp+12],eax
_700:
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+16]
	add	eax,4
	push	eax
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+12]
	add	eax,4
	push	eax
	call	bbIntMax
	add	esp,8
	cmp	dword [ebp-4],eax
	jg	_702
	mov	eax,dword [ebp-4]
	mov	dword [ebp+-28],eax
	fild	dword [ebp+-28]
	fstp	dword [ebp-8]
	mov	eax,dword [ebp+12]
	push	dword [eax+16]
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	call	bbIntMax
	add	esp,8
	mov	dword [ebp+-28],eax
	fild	dword [ebp+-28]
	fld	dword [ebp-8]
	fdivrp	st1,st0
	fstp	dword [ebp-8]
	fld	dword [ebp-8]
	fadd	dword [_965]
	fstp	dword [ebp-12]
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+16]
	add	eax,4
	mov	dword [ebp+-28],eax
	fild	dword [ebp+-28]
	fmul	dword [ebp-12]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+12]
	add	eax,4
	mov	dword [ebp+-28],eax
	fild	dword [ebp+-28]
	fmul	dword [ebp-12]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	dword [ebp+12]
	call	brl_pixmap_ResizePixmap
	add	esp,12
	mov	dword [ebp+12],eax
_702:
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+12]
	add	eax,4
	push	eax
	call	_11
	add	esp,4
	mov	dword [ebp-20],eax
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+16]
	add	eax,4
	push	eax
	call	_11
	add	esp,4
	mov	dword [ebp-24],eax
	mov	edi,bbNullObject
	mov	ebx,0
	mov	eax,dword [esi+52]
	mov	dword [ebp-16],eax
	jmp	_708
_23:
	mov	eax,dword [esi+48]
	mov	eax,dword [eax+ebx*4+24]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_710
	jmp	_22
_710:
	mov	eax,dword [esi+48]
	mov	edx,dword [eax+ebx*4+24]
	mov	eax,dword [ebp+16]
	cmp	dword [edx+28],eax
	jne	_711
	mov	eax,dword [esi+48]
	mov	edx,dword [eax+ebx*4+24]
	mov	eax,dword [ebp+12]
	push	dword [eax+16]
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+64]
	add	esp,12
	mov	edi,eax
_711:
_21:
	add	ebx,1
_708:
	cmp	ebx,dword [ebp-16]
	jl	_23
_22:
	cmp	edi,bbNullObject
	jne	_713
	mov	eax,dword [esi+48]
	mov	eax,dword [eax+20]
	cmp	dword [esi+52],eax
	jne	_714
	mov	eax,dword [esi+48]
	mov	eax,dword [eax+20]
	shl	eax,1
	push	eax
	push	0
	push	dword [esi+48]
	push	_55
	call	bbArraySlice
	add	esp,16
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [esi+48]
	dec	dword [eax+4]
	jnz	_718
	push	eax
	call	bbGCFree
	add	esp,4
_718:
	mov	dword [esi+48],ebx
_714:
	push	bb_TGLTexturePack
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	push	dword [ebp+16]
	push	dword [_bb_TBufferedGLMax2DDriver_MinimumTextureHeight]
	push	dword [ebp-24]
	call	bbIntMax
	add	esp,8
	push	eax
	push	dword [_bb_TBufferedGLMax2DDriver_MinimumTextureWidth]
	push	dword [ebp-20]
	call	bbIntMax
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,16
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	edx,dword [esi+48]
	mov	eax,dword [esi+52]
	mov	eax,dword [edx+eax*4+24]
	dec	dword [eax+4]
	jnz	_723
	push	eax
	call	bbGCFree
	add	esp,4
_723:
	mov	edx,dword [esi+48]
	mov	eax,dword [esi+52]
	mov	dword [edx+eax*4+24],ebx
	mov	edx,dword [esi+48]
	mov	eax,dword [esi+52]
	mov	eax,dword [edx+eax*4+24]
	mov	edx,dword [ebp+12]
	mov	edx,dword [edx+16]
	add	edx,4
	push	edx
	mov	edx,dword [ebp+12]
	mov	edx,dword [edx+12]
	add	edx,4
	push	edx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,12
	mov	edi,eax
	add	dword [esi+52],1
_713:
	mov	eax,edi
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,8
	push	bb_TGLBufferedImageFrame
	call	bbObjectNew
	add	esp,4
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,8
	jmp	_290
_290:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_SetBlend:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	cmp	ebx,dword [esi+56]
	jne	_729
	mov	eax,0
	jmp	_294
_729:
	mov	dword [esi+56],ebx
	sub	ebx,1
	shl	ebx,2
	mov	edx,dword [_bb_TBufferedGLMax2DDriver___blend_funcs]
	mov	eax,ebx
	add	eax,1
	push	dword [edx+eax*4+24]
	mov	eax,dword [_bb_TBufferedGLMax2DDriver___blend_funcs]
	push	dword [eax+ebx*4+24]
	push	dword [esi+8]
	call	_bb_TRenderBuffer_SetBlendFunc
	add	esp,12
	mov	edx,dword [_bb_TBufferedGLMax2DDriver___blend_funcs]
	mov	eax,ebx
	add	eax,3
	mov	eax,dword [edx+eax*4+24]
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	fmul	dword [_977]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [_bb_TBufferedGLMax2DDriver___blend_funcs]
	add	ebx,2
	push	dword [eax+ebx*4+24]
	push	dword [esi+8]
	call	_bb_TRenderBuffer_SetAlphaFunc
	add	esp,12
	mov	eax,0
	jmp	_294
_294:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_SetAlpha:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	fld	dword [ebp+12]
	lea	eax,byte [ebx+12]
	mov	esi,dword [eax]
	fld1
	sub	esp,8
	fstp	qword [esp]
	fldz
	sub	esp,8
	fstp	qword [esp]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatMax
	add	esp,16
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatMin
	add	esp,16
	fmul	dword [_981]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebx+15],al
	lea	eax,byte [ebx+12]
	mov	edi,dword [eax]
	cmp	esi,edi
	jne	_732
	mov	eax,0
	jmp	_298
_732:
	mov	eax,dword [ebx+76]
	lea	eax,byte [eax+24]
	mov	esi,eax
	mov	ecx,0
	mov	eax,dword [ebx+76]
	mov	eax,dword [eax+20]
	cdq
	and	edx,3
	add	eax,edx
	sar	eax,2
	jmp	_735
_28:
	mov	dword [esi+ecx*4],edi
_26:
	add	ecx,1
_735:
	cmp	ecx,eax
	jl	_28
_27:
	mov	eax,0
	jmp	_298
_298:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_SetColor:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	esi,dword [ebp+16]
	mov	edi,dword [ebp+20]
	lea	edx,byte [ebx+12]
	mov	edx,dword [edx]
	mov	dword [ebp-4],edx
	push	255
	push	0
	push	eax
	call	bbIntMax
	add	esp,8
	push	eax
	call	bbIntMin
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebx+12],al
	push	255
	push	0
	push	esi
	call	bbIntMax
	add	esp,8
	push	eax
	call	bbIntMin
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebx+13],al
	push	255
	push	0
	push	edi
	call	bbIntMax
	add	esp,8
	push	eax
	call	bbIntMin
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebx+14],al
	lea	eax,byte [ebx+12]
	mov	edi,dword [eax]
	cmp	dword [ebp-4],edi
	jne	_739
	mov	eax,0
	jmp	_304
_739:
	mov	eax,dword [ebx+76]
	lea	eax,byte [eax+24]
	mov	esi,eax
	mov	ecx,0
	mov	eax,dword [ebx+76]
	mov	eax,dword [eax+20]
	cdq
	and	edx,3
	add	eax,edx
	sar	eax,2
	jmp	_742
_31:
	mov	dword [esi+ecx*4],edi
_29:
	add	ecx,1
_742:
	cmp	ecx,eax
	jl	_31
_30:
	mov	eax,0
	jmp	_304
_304:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_SetClsColor:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	ecx,dword [ebp+16]
	mov	edx,dword [ebp+20]
	mov	eax,dword [esi+60]
	cmp	eax,ebx
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_744
	mov	eax,dword [esi+64]
	cmp	eax,ecx
	sete	al
	movzx	eax,al
_744:
	cmp	eax,0
	je	_746
	mov	eax,dword [esi+68]
	cmp	eax,edx
	sete	al
	movzx	eax,al
_746:
	cmp	eax,0
	je	_748
	mov	eax,0
	jmp	_310
_748:
	mov	dword [esi+60],ebx
	mov	dword [esi+64],ecx
	mov	dword [esi+68],edx
	push	1065353216
	mov	dword [ebp+-4],edx
	fild	dword [ebp+-4]
	fdiv	dword [_988]
	sub	esp,4
	fstp	dword [esp]
	mov	dword [ebp+-4],ecx
	fild	dword [ebp+-4]
	fdiv	dword [_989]
	sub	esp,4
	fstp	dword [esp]
	mov	dword [ebp+-4],ebx
	fild	dword [ebp+-4]
	fdiv	dword [_990]
	sub	esp,4
	fstp	dword [esp]
	call	glClearColor
	add	esp,16
	mov	eax,0
	jmp	_310
_310:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_SetViewport:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+16]
	mov	ecx,dword [ebp+20]
	mov	edx,dword [ebp+24]
	mov	eax,dword [ebp+12]
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_749
	cmp	edi,0
	sete	al
	movzx	eax,al
_749:
	cmp	eax,0
	je	_751
	mov	dword [ebp+-4],ecx
	fild	dword [ebp+-4]
	fld	dword [esi+80]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setz	al
	movzx	eax,al
_751:
	mov	ebx,eax
	cmp	ebx,0
	je	_753
	mov	dword [ebp+-4],edx
	fild	dword [ebp+-4]
	fld	dword [esi+84]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setz	al
	movzx	eax,al
	mov	ebx,eax
_753:
	push	edx
	push	ecx
	fld	dword [esi+84]
	mov	eax,edi
	add	eax,edx
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	fsubp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	dword [ebp+12]
	cmp	ebx,0
	sete	al
	movzx	eax,al
	push	eax
	push	dword [esi+8]
	call	_bb_TRenderBuffer_SetScissorTest
	add	esp,24
	mov	eax,0
	jmp	_317
_317:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_SetTransform:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	fld	dword [ebp+12]
	fld	dword [ebp+16]
	fld	dword [ebp+20]
	fld	dword [ebp+24]
	fxch	st3
	fstp	dword [eax+16]
	fxch	st1
	fstp	dword [eax+20]
	fstp	dword [eax+24]
	fstp	dword [eax+28]
	mov	eax,0
	jmp	_324
_324:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_SetLineWidth:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	fld	dword [ebp+12]
	sub	esp,4
	fstp	dword [esp]
	push	dword [eax+8]
	call	_bb_TRenderBuffer_SetLineWidth
	add	esp,8
	mov	eax,0
	jmp	_328
_328:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_Cls:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	dword [eax+8]
	call	_bb_TRenderBuffer_Reset
	add	esp,4
	push	16384
	call	glClear
	add	esp,4
	mov	eax,0
	jmp	_331
_331:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_Plot:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	0
	push	dword [ebx+8]
	call	_bb_TRenderBuffer_SetTexture
	add	esp,8
	push	0
	push	dword [ebx+8]
	call	_bb_TRenderBuffer_SetMode
	add	esp,8
	mov	eax,dword [ebx+72]
	fld	dword [ebp+12]
	fstp	dword [eax+24]
	mov	eax,dword [ebx+72]
	fld	dword [ebp+16]
	fstp	dword [eax+4+24]
	mov	eax,dword [ebx+76]
	lea	eax,byte [eax+24]
	push	eax
	push	0
	mov	eax,dword [ebx+72]
	lea	eax,byte [eax+24]
	push	eax
	push	1
	push	dword [ebx+8]
	call	_bb_TRenderBuffer_AddVerticesEx
	add	esp,20
	mov	eax,0
	jmp	_336
_336:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_DrawLine:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	0
	push	dword [ebx+8]
	call	_bb_TRenderBuffer_SetTexture
	add	esp,8
	push	1
	push	dword [ebx+8]
	call	_bb_TRenderBuffer_SetMode
	add	esp,8
	mov	eax,dword [ebx+72]
	fld	dword [ebp+12]
	fmul	dword [ebx+16]
	fld	dword [ebp+16]
	fmul	dword [ebx+20]
	faddp	st1,st0
	fadd	dword [ebp+28]
	fadd	dword [_1009]
	fstp	dword [eax+24]
	mov	eax,dword [ebx+72]
	fld	dword [ebp+12]
	fmul	dword [ebx+24]
	fld	dword [ebp+16]
	fmul	dword [ebx+28]
	faddp	st1,st0
	fsub	dword [_1010]
	fadd	dword [ebp+32]
	fadd	dword [_1011]
	fstp	dword [eax+4+24]
	mov	eax,dword [ebx+72]
	fld	dword [ebp+20]
	fmul	dword [ebx+16]
	fld	dword [ebp+24]
	fmul	dword [ebx+20]
	faddp	st1,st0
	fadd	dword [ebp+28]
	fadd	dword [_1012]
	fstp	dword [eax+8+24]
	mov	eax,dword [ebx+72]
	fld	dword [ebp+20]
	fmul	dword [ebx+24]
	fld	dword [ebp+24]
	fmul	dword [ebx+28]
	faddp	st1,st0
	fsub	dword [_1013]
	fadd	dword [ebp+32]
	fadd	dword [_1014]
	fstp	dword [eax+12+24]
	mov	eax,dword [ebx+76]
	lea	eax,byte [eax+24]
	push	eax
	push	0
	mov	eax,dword [ebx+72]
	lea	eax,byte [eax+24]
	push	eax
	push	2
	push	dword [ebx+8]
	call	_bb_TRenderBuffer_AddVerticesEx
	add	esp,20
	mov	eax,0
	jmp	_345
_345:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_DrawRect:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	ebx,dword [ebp+8]
	push	0
	push	dword [ebx+8]
	call	_bb_TRenderBuffer_SetTexture
	add	esp,8
	push	5
	push	dword [ebx+8]
	call	_bb_TRenderBuffer_SetMode
	add	esp,8
	push	dword [ebp+32]
	push	dword [ebp+28]
	push	dword [ebp+24]
	push	dword [ebp+20]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,28
	mov	dword [ebp-4],eax
	mov	eax,dword [ebx+76]
	lea	eax,byte [eax+24]
	push	eax
	push	0
	mov	eax,dword [ebp-4]
	lea	eax,byte [eax+24]
	push	eax
	push	4
	push	dword [ebx+8]
	call	_bb_TRenderBuffer_AddVerticesEx
	add	esp,20
	mov	eax,0
	jmp	_354
_354:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_DrawOval:
	push	ebp
	mov	ebp,esp
	sub	esp,32
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	fld	dword [ebp+20]
	fld	dword [ebp+24]
	fxch	st1
	fsub	dword [ebp+12]
	fmul	dword [_1019]
	fstp	dword [ebp-12]
	fsub	dword [ebp+16]
	fmul	dword [_1020]
	fstp	dword [ebp-16]
	fld	dword [ebp-16]
	sub	esp,8
	fstp	qword [esp]
	fld	dword [ebp-12]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatMax
	add	esp,16
	fmul	dword [_1021]
	fsub	dword [_1022]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	dword [ebp-28],eax
	mov	edx,dword [esi+72]
	mov	eax,dword [ebp-28]
	shl	eax,1
	cmp	dword [edx+20],eax
	jge	_760
	mov	eax,dword [ebp-28]
	shl	eax,1
	push	eax
	push	_761
	call	bbArrayNew1D
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [esi+72]
	dec	dword [eax+4]
	jnz	_765
	push	eax
	call	bbGCFree
	add	esp,4
_765:
	mov	dword [esi+72],ebx
	mov	eax,dword [ebp-28]
	shl	eax,2
	push	eax
	push	_766
	call	bbArrayNew1D
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [esi+76]
	dec	dword [eax+4]
	jnz	_770
	push	eax
	call	bbGCFree
	add	esp,4
_770:
	mov	dword [esi+76],ebx
_760:
	fld	dword [_1023]
	mov	eax,dword [ebp-28]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fdivp	st1,st0
	fstp	dword [ebp-8]
	mov	eax,dword [esi+76]
	lea	eax,byte [eax+24]
	mov	edi,eax
	lea	eax,byte [esi+12]
	mov	eax,dword [eax]
	mov	dword [ebp-20],eax
	mov	ebx,0
	mov	eax,dword [ebp-28]
	mov	dword [ebp-24],eax
	jmp	_775
_34:
	mov	dword [ebp+-32],ebx
	fild	dword [ebp+-32]
	fmul	dword [ebp-8]
	sub	esp,8
	fstp	qword [esp]
	call	bbSin
	add	esp,8
	fld	dword [ebp-12]
	fmulp	st1,st0
	fstp	dword [ebp-4]
	mov	dword [ebp+-32],ebx
	fild	dword [ebp+-32]
	fmul	dword [ebp-8]
	sub	esp,8
	fstp	qword [esp]
	call	bbCos
	add	esp,8
	fld	dword [ebp-16]
	fmulp	st1,st0
	fld	dword [ebp+12]
	fadd	dword [ebp-12]
	fadd	dword [ebp-4]
	fld	dword [ebp+16]
	fadd	dword [ebp-16]
	faddp	st2,st0
	mov	eax,ebx
	shl	eax,1
	mov	edx,dword [esi+72]
	fmul	dword [esi+16]
	fld	st1
	fmul	dword [esi+20]
	faddp	st1,st0
	fadd	dword [ebp+28]
	fstp	dword [edx+eax*4+24]
	mov	edx,dword [esi+72]
	add	eax,1
	fld	st0
	fmul	dword [esi+24]
	fxch	st1
	fmul	dword [esi+28]
	faddp	st1,st0
	fadd	dword [ebp+32]
	fstp	dword [edx+eax*4+24]
	mov	eax,dword [ebp-20]
	mov	dword [edi+ebx*4],eax
_32:
	add	ebx,1
_775:
	cmp	ebx,dword [ebp-24]
	jl	_34
_33:
	push	9
	push	dword [esi+8]
	call	_bb_TRenderBuffer_SetMode
	add	esp,8
	push	0
	push	dword [esi+8]
	call	_bb_TRenderBuffer_SetTexture
	add	esp,8
	mov	eax,dword [esi+76]
	lea	eax,byte [eax+24]
	push	eax
	push	0
	mov	eax,dword [esi+72]
	lea	eax,byte [eax+24]
	push	eax
	push	dword [ebp-28]
	push	dword [esi+8]
	call	_bb_TRenderBuffer_AddVerticesEx
	add	esp,20
	mov	eax,0
	jmp	_363
_363:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_DrawPoly:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+12]
	mov	dword [ebp-4],eax
	push	0
	mov	eax,dword [ebp+8]
	push	dword [eax+8]
	call	_bb_TRenderBuffer_SetTexture
	add	esp,8
	push	9
	mov	eax,dword [ebp+8]
	push	dword [eax+8]
	call	_bb_TRenderBuffer_SetMode
	add	esp,8
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+76]
	mov	eax,dword [eax+20]
	cdq
	and	edx,1
	add	eax,edx
	sar	eax,1
	mov	edx,dword [ebp-4]
	cmp	eax,dword [edx+20]
	jge	_782
	push	24
	mov	eax,dword [ebp-4]
	push	dword [eax+20]
	call	bbIntMin
	add	esp,8
	shl	eax,1
	push	eax
	push	_783
	call	bbArrayNew1D
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+76]
	dec	dword [eax+4]
	jnz	_787
	push	eax
	call	bbGCFree
	add	esp,4
_787:
	mov	eax,dword [ebp+8]
	mov	dword [eax+76],ebx
_782:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+76]
	lea	eax,byte [eax+24]
	mov	ebx,eax
	mov	eax,dword [ebp+8]
	lea	eax,byte [eax+12]
	mov	edi,dword [eax]
	mov	esi,0
	mov	eax,dword [ebp-4]
	mov	ecx,dword [eax+20]
	jmp	_791
_37:
	mov	eax,esi
	cdq
	mov	eax,esi
	cdq
	and	edx,1
	add	eax,edx
	sar	eax,1
	mov	dword [ebx+eax*4],edi
_35:
	add	esi,2
_791:
	cmp	esi,ecx
	jl	_37
_36:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+76]
	lea	eax,byte [eax+24]
	push	eax
	push	0
	mov	eax,dword [ebp-4]
	lea	eax,byte [eax+24]
	push	eax
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+20]
	cdq
	and	edx,1
	add	eax,edx
	sar	eax,1
	push	eax
	mov	eax,dword [ebp+8]
	push	dword [eax+8]
	call	_bb_TRenderBuffer_AddVerticesEx
	add	esp,20
	mov	eax,0
	jmp	_371
_371:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_DrawPixmap:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	edi,dword [ebp+16]
	push	dword [esi+8]
	call	_bb_TRenderBuffer_Render
	add	esp,4
	push	dword [esi+8]
	call	_bb_TRenderBuffer_Reset
	add	esp,4
	push	dword [ebp+20]
	push	edi
	call	glRasterPos2i
	add	esp,8
	push	ebx
	call	brl_pixmap_YFlipPixmap
	add	esp,4
	mov	ebx,eax
	push	dword [ebx+8]
	push	5121
	push	ebx
	call	_15
	add	esp,4
	push	eax
	push	dword [ebx+16]
	push	dword [ebx+12]
	call	glDrawPixels
	add	esp,20
	mov	eax,0
	jmp	_377
_377:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_GrabPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+24]
	push	dword [esi+8]
	call	_bb_TRenderBuffer_Render
	add	esp,4
	push	dword [esi+8]
	call	_bb_TRenderBuffer_Reset
	add	esp,4
	push	4
	push	6
	push	edi
	push	dword [ebp+20]
	call	brl_pixmap_CreatePixmap
	add	esp,16
	mov	ebx,eax
	push	dword [ebx+8]
	push	5121
	push	6408
	push	edi
	push	dword [ebp+20]
	fld	dword [esi+84]
	mov	eax,dword [ebp+16]
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	fsubp	st1,st0
	mov	dword [ebp+-4],edi
	fild	dword [ebp+-4]
	fsubp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	dword [ebp+12]
	call	glReadPixels
	add	esp,28
	push	ebx
	call	brl_pixmap_YFlipPixmap
	add	esp,4
	mov	ebx,eax
	mov	eax,ebx
	jmp	_384
_384:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_SetResolution:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	fld	dword [ebp+12]
	fstp	dword [eax+80]
	fld	dword [ebp+16]
	fstp	dword [eax+84]
	push	5889
	call	glMatrixMode
	add	esp,4
	call	glLoadIdentity
	fld	qword [_1037]
	sub	esp,8
	fstp	qword [esp]
	fld	qword [_1038]
	sub	esp,8
	fstp	qword [esp]
	fldz
	sub	esp,8
	fstp	qword [esp]
	fld	dword [ebp+16]
	sub	esp,8
	fstp	qword [esp]
	fld	dword [ebp+12]
	sub	esp,8
	fstp	qword [esp]
	fldz
	sub	esp,8
	fstp	qword [esp]
	call	glOrtho
	add	esp,48
	push	5888
	call	glMatrixMode
	add	esp,4
	call	glLoadIdentity
	mov	eax,0
	jmp	_389
_389:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_ToString:
	push	ebp
	mov	ebp,esp
	mov	eax,_38
	jmp	_392
_392:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedGLMax2DDriver_RenderBuffer:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	jmp	_395
_395:
	mov	esp,ebp
	pop	ebp
	ret
bb_BufferedGLMax2DDriver:
	push	ebp
	mov	ebp,esp
	push	ebx
	cmp	dword [_797],0
	jne	_798
	mov	dword [_797],1
	call	brl_glgraphics_GLGraphicsDriver
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_799
	mov	eax,bbNullObject
	jmp	_397
_799:
	push	bb_TBufferedGLMax2DDriver
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [_403]
	dec	dword [eax+4]
	jnz	_803
	push	eax
	call	bbGCFree
	add	esp,4
_803:
	mov	dword [_403],ebx
_798:
	mov	eax,dword [_403]
	jmp	_397
_397:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_404:
	dd	0
	align	4
_bb_TGLPackedTexture_MinPackingSize:
	dd	3
_40:
	db	"TGLPackedTexture",0
_41:
	db	"_filled",0
_42:
	db	"i",0
_43:
	db	"_u0",0
_44:
	db	"f",0
_45:
	db	"_v0",0
_46:
	db	"_u1",0
_47:
	db	"_v1",0
_48:
	db	"_x",0
_49:
	db	"_y",0
_50:
	db	"_width",0
_51:
	db	"_height",0
_52:
	db	"_pwidth",0
_53:
	db	"_pheight",0
_54:
	db	"_owner",0
_55:
	db	":TGLTexturePack",0
_56:
	db	"_p_right",0
_57:
	db	":TGLPackedTexture",0
_58:
	db	"_p_bottom",0
_59:
	db	"New",0
_60:
	db	"()i",0
_61:
	db	"Delete",0
_62:
	db	"GetUnused",0
_63:
	db	"(i,i):TGLPackedTexture",0
_64:
	db	"Buffer",0
_65:
	db	"(:brl.pixmap.TPixmap)i",0
_66:
	db	"Name",0
_67:
	db	"Unload",0
_68:
	db	"MergeEmpty",0
	align	4
_39:
	dd	2
	dd	_40
	dd	3
	dd	_41
	dd	_42
	dd	8
	dd	3
	dd	_43
	dd	_44
	dd	12
	dd	3
	dd	_45
	dd	_44
	dd	16
	dd	3
	dd	_46
	dd	_44
	dd	20
	dd	3
	dd	_47
	dd	_44
	dd	24
	dd	3
	dd	_48
	dd	_42
	dd	28
	dd	3
	dd	_49
	dd	_42
	dd	32
	dd	3
	dd	_50
	dd	_42
	dd	36
	dd	3
	dd	_51
	dd	_42
	dd	40
	dd	3
	dd	_52
	dd	_42
	dd	44
	dd	3
	dd	_53
	dd	_42
	dd	48
	dd	3
	dd	_54
	dd	_55
	dd	52
	dd	3
	dd	_56
	dd	_57
	dd	56
	dd	3
	dd	_58
	dd	_57
	dd	60
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_62
	dd	_63
	dd	48
	dd	6
	dd	_64
	dd	_65
	dd	52
	dd	6
	dd	_66
	dd	_60
	dd	56
	dd	6
	dd	_67
	dd	_60
	dd	60
	dd	6
	dd	_68
	dd	_60
	dd	64
	dd	0
	align	4
bb_TGLPackedTexture:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_39
	dd	64
	dd	_bb_TGLPackedTexture_New
	dd	_bb_TGLPackedTexture_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TGLPackedTexture_GetUnused
	dd	_bb_TGLPackedTexture_Buffer
	dd	_bb_TGLPackedTexture_Name
	dd	_bb_TGLPackedTexture_Unload
	dd	_bb_TGLPackedTexture_MergeEmpty
_70:
	db	"TGLTexturePack",0
_71:
	db	"_gseq",0
_72:
	db	"_name",0
_73:
	db	"_root",0
_74:
	db	"_flags",0
_75:
	db	"_wscale",0
_76:
	db	"_hscale",0
_77:
	db	"Bind",0
_78:
	db	"Reset",0
_79:
	db	"Init",0
_80:
	db	"(i,i,i):TGLTexturePack",0
	align	4
_69:
	dd	2
	dd	_70
	dd	3
	dd	_71
	dd	_42
	dd	8
	dd	3
	dd	_72
	dd	_42
	dd	12
	dd	3
	dd	_73
	dd	_57
	dd	16
	dd	3
	dd	_50
	dd	_42
	dd	20
	dd	3
	dd	_51
	dd	_42
	dd	24
	dd	3
	dd	_74
	dd	_42
	dd	28
	dd	3
	dd	_75
	dd	_44
	dd	32
	dd	3
	dd	_76
	dd	_44
	dd	36
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_66
	dd	_60
	dd	48
	dd	6
	dd	_77
	dd	_60
	dd	52
	dd	6
	dd	_78
	dd	_60
	dd	56
	dd	6
	dd	_79
	dd	_80
	dd	60
	dd	6
	dd	_62
	dd	_63
	dd	64
	dd	6
	dd	_68
	dd	_60
	dd	68
	dd	0
	align	4
bb_TGLTexturePack:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_69
	dd	40
	dd	_bb_TGLTexturePack_New
	dd	_bb_TGLTexturePack_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TGLTexturePack_Name
	dd	_bb_TGLTexturePack_Bind
	dd	_bb_TGLTexturePack_Reset
	dd	_bb_TGLTexturePack_Init
	dd	_bb_TGLTexturePack_GetUnused
	dd	_bb_TGLTexturePack_MergeEmpty
_82:
	db	"TGLBufferedImageFrame",0
_83:
	db	"_texture",0
_84:
	db	"uv",0
_85:
	db	"[]f",0
_86:
	db	"(:TGLPackedTexture):TGLBufferedImageFrame",0
_87:
	db	"Draw",0
_88:
	db	"(f,f,f,f,f,f,f,f,f,f)i",0
	align	4
_81:
	dd	2
	dd	_82
	dd	3
	dd	_71
	dd	_42
	dd	8
	dd	3
	dd	_83
	dd	_57
	dd	12
	dd	3
	dd	_84
	dd	_85
	dd	16
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_79
	dd	_86
	dd	52
	dd	6
	dd	_87
	dd	_88
	dd	48
	dd	0
	align	4
bb_TGLBufferedImageFrame:
	dd	brl_max2d_TImageFrame
	dd	bbObjectFree
	dd	_81
	dd	20
	dd	_bb_TGLBufferedImageFrame_New
	dd	_bb_TGLBufferedImageFrame_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TGLBufferedImageFrame_Draw
	dd	_bb_TGLBufferedImageFrame_Init
	align	4
_bb_TBufferedGLMax2DDriver_MinimumTextureWidth:
	dd	1024
	align	4
_bb_TBufferedGLMax2DDriver_MinimumTextureHeight:
	dd	1024
	align	4
_401:
	dd	0
	align	4
_bb_TBufferedGLMax2DDriver___blend_funcs:
	dd	bbEmptyArray
_90:
	db	"TBufferedGLMax2DDriver",0
_91:
	db	"_buffer",0
_92:
	db	":TRenderBuffer",0
_93:
	db	"_cr",0
_94:
	db	"b",0
_95:
	db	"_cg",0
_96:
	db	"_cb",0
_97:
	db	"_ca",0
_98:
	db	"_txx",0
_99:
	db	"_txy",0
_100:
	db	"_tyx",0
_101:
	db	"_tyy",0
_102:
	db	"_view_x",0
_103:
	db	"_view_y",0
_104:
	db	"_view_w",0
_105:
	db	"_view_h",0
_106:
	db	"_texPackages",0
_107:
	db	"[]:TGLTexturePack",0
_108:
	db	"_numPackages",0
_109:
	db	"_blend",0
_110:
	db	"_clr_r",0
_111:
	db	"_clr_g",0
_112:
	db	"_clr_b",0
_113:
	db	"_poly_xy",0
_114:
	db	"_poly_colors",0
_115:
	db	"[]b",0
_116:
	db	"_r_width",0
_117:
	db	"_r_height",0
_118:
	db	"_rectPoints",0
_119:
	db	"(f,f,f,f,f,f)[]f",0
_120:
	db	"GraphicsModes",0
_121:
	db	"()[]:brl.graphics.TGraphicsMode",0
_122:
	db	"AttachGraphics",0
_123:
	db	"(i,i):brl.graphics.TGraphics",0
_124:
	db	"CreateGraphics",0
_125:
	db	"(i,i,i,i,i):brl.graphics.TGraphics",0
_126:
	db	"SetGraphics",0
_127:
	db	"(:brl.graphics.TGraphics)i",0
_128:
	db	"Flip",0
_129:
	db	"(i)i",0
_130:
	db	"CreateFrameFromPixmap",0
_131:
	db	"(:brl.pixmap.TPixmap,i):brl.max2d.TImageFrame",0
_132:
	db	"SetBlend",0
_133:
	db	"SetAlpha",0
_134:
	db	"(f)i",0
_135:
	db	"SetColor",0
_136:
	db	"(i,i,i)i",0
_137:
	db	"SetClsColor",0
_138:
	db	"SetViewport",0
_139:
	db	"(i,i,i,i)i",0
_140:
	db	"SetTransform",0
_141:
	db	"(f,f,f,f)i",0
_142:
	db	"SetLineWidth",0
_143:
	db	"Cls",0
_144:
	db	"Plot",0
_145:
	db	"(f,f)i",0
_146:
	db	"DrawLine",0
_147:
	db	"(f,f,f,f,f,f)i",0
_148:
	db	"DrawRect",0
_149:
	db	"DrawOval",0
_150:
	db	"DrawPoly",0
_151:
	db	"([]f,f,f,f,f)i",0
_152:
	db	"DrawPixmap",0
_153:
	db	"(:brl.pixmap.TPixmap,i,i)i",0
_154:
	db	"GrabPixmap",0
_155:
	db	"(i,i,i,i):brl.pixmap.TPixmap",0
_156:
	db	"SetResolution",0
_157:
	db	"ToString",0
_158:
	db	"()$",0
_159:
	db	"RenderBuffer",0
_160:
	db	"():TRenderBuffer",0
	align	4
_89:
	dd	2
	dd	_90
	dd	3
	dd	_91
	dd	_92
	dd	8
	dd	3
	dd	_93
	dd	_94
	dd	12
	dd	3
	dd	_95
	dd	_94
	dd	13
	dd	3
	dd	_96
	dd	_94
	dd	14
	dd	3
	dd	_97
	dd	_94
	dd	15
	dd	3
	dd	_98
	dd	_44
	dd	16
	dd	3
	dd	_99
	dd	_44
	dd	20
	dd	3
	dd	_100
	dd	_44
	dd	24
	dd	3
	dd	_101
	dd	_44
	dd	28
	dd	3
	dd	_102
	dd	_42
	dd	32
	dd	3
	dd	_103
	dd	_42
	dd	36
	dd	3
	dd	_104
	dd	_42
	dd	40
	dd	3
	dd	_105
	dd	_42
	dd	44
	dd	3
	dd	_106
	dd	_107
	dd	48
	dd	3
	dd	_108
	dd	_42
	dd	52
	dd	3
	dd	_109
	dd	_42
	dd	56
	dd	3
	dd	_110
	dd	_42
	dd	60
	dd	3
	dd	_111
	dd	_42
	dd	64
	dd	3
	dd	_112
	dd	_42
	dd	68
	dd	3
	dd	_113
	dd	_85
	dd	72
	dd	3
	dd	_114
	dd	_115
	dd	76
	dd	3
	dd	_116
	dd	_44
	dd	80
	dd	3
	dd	_117
	dd	_44
	dd	84
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_78
	dd	_60
	dd	136
	dd	6
	dd	_118
	dd	_119
	dd	140
	dd	6
	dd	_120
	dd	_121
	dd	48
	dd	6
	dd	_122
	dd	_123
	dd	52
	dd	6
	dd	_124
	dd	_125
	dd	56
	dd	6
	dd	_126
	dd	_127
	dd	60
	dd	6
	dd	_128
	dd	_129
	dd	64
	dd	6
	dd	_130
	dd	_131
	dd	68
	dd	6
	dd	_132
	dd	_129
	dd	72
	dd	6
	dd	_133
	dd	_134
	dd	76
	dd	6
	dd	_135
	dd	_136
	dd	80
	dd	6
	dd	_137
	dd	_136
	dd	84
	dd	6
	dd	_138
	dd	_139
	dd	88
	dd	6
	dd	_140
	dd	_141
	dd	92
	dd	6
	dd	_142
	dd	_134
	dd	96
	dd	6
	dd	_143
	dd	_60
	dd	100
	dd	6
	dd	_144
	dd	_145
	dd	104
	dd	6
	dd	_146
	dd	_147
	dd	108
	dd	6
	dd	_148
	dd	_147
	dd	112
	dd	6
	dd	_149
	dd	_147
	dd	116
	dd	6
	dd	_150
	dd	_151
	dd	120
	dd	6
	dd	_152
	dd	_153
	dd	124
	dd	6
	dd	_154
	dd	_155
	dd	128
	dd	6
	dd	_156
	dd	_145
	dd	132
	dd	6
	dd	_157
	dd	_158
	dd	24
	dd	6
	dd	_159
	dd	_160
	dd	144
	dd	0
	align	4
bb_TBufferedGLMax2DDriver:
	dd	brl_max2d_TMax2DDriver
	dd	bbObjectFree
	dd	_89
	dd	88
	dd	_bb_TBufferedGLMax2DDriver_New
	dd	_bb_TBufferedGLMax2DDriver_Delete
	dd	_bb_TBufferedGLMax2DDriver_ToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TBufferedGLMax2DDriver_GraphicsModes
	dd	_bb_TBufferedGLMax2DDriver_AttachGraphics
	dd	_bb_TBufferedGLMax2DDriver_CreateGraphics
	dd	_bb_TBufferedGLMax2DDriver_SetGraphics
	dd	_bb_TBufferedGLMax2DDriver_Flip
	dd	_bb_TBufferedGLMax2DDriver_CreateFrameFromPixmap
	dd	_bb_TBufferedGLMax2DDriver_SetBlend
	dd	_bb_TBufferedGLMax2DDriver_SetAlpha
	dd	_bb_TBufferedGLMax2DDriver_SetColor
	dd	_bb_TBufferedGLMax2DDriver_SetClsColor
	dd	_bb_TBufferedGLMax2DDriver_SetViewport
	dd	_bb_TBufferedGLMax2DDriver_SetTransform
	dd	_bb_TBufferedGLMax2DDriver_SetLineWidth
	dd	_bb_TBufferedGLMax2DDriver_Cls
	dd	_bb_TBufferedGLMax2DDriver_Plot
	dd	_bb_TBufferedGLMax2DDriver_DrawLine
	dd	_bb_TBufferedGLMax2DDriver_DrawRect
	dd	_bb_TBufferedGLMax2DDriver_DrawOval
	dd	_bb_TBufferedGLMax2DDriver_DrawPoly
	dd	_bb_TBufferedGLMax2DDriver_DrawPixmap
	dd	_bb_TBufferedGLMax2DDriver_GrabPixmap
	dd	_bb_TBufferedGLMax2DDriver_SetResolution
	dd	_bb_TBufferedGLMax2DDriver_Reset
	dd	_bb_TBufferedGLMax2DDriver__rectPoints
	dd	_bb_TBufferedGLMax2DDriver_RenderBuffer
	align	4
_403:
	dd	bbNullObject
	align	4
_7:
	dd	bbStringClass
	dd	2147483647
	dd	34
	dw	85,110,97,98,108,101,32,116,111,32,99,114,101,97,116,101
	dw	32,116,101,120,116,117,114,101,32,102,111,114,32,105,109,97
	dw	103,101
	align	4
_892:
	dd	0x3f800000
	align	4
_893:
	dd	0x3f800000
_621:
	db	"f",0
_650:
	db	":TGLTexturePack",0
_652:
	db	"f",0
_654:
	db	"b",0
	align	4
_938:
	dd	0x44200000
	align	4
_939:
	dd	0x43f00000
	align	4
_965:
	dd	0x40800000
	align	4
_977:
	dd	0x3f000000
	align	4
_981:
	dd	0x437f0000
	align	4
_988:
	dd	0x437f0000
	align	4
_989:
	dd	0x437f0000
	align	4
_990:
	dd	0x437f0000
	align	4
_1009:
	dd	0x3f000000
	align	4
_1010:
	dd	0x3f800000
	align	4
_1011:
	dd	0x3f000000
	align	4
_1012:
	dd	0x3f000000
	align	4
_1013:
	dd	0x3f800000
	align	4
_1014:
	dd	0x3f000000
	align	4
_1019:
	dd	0x3f000000
	align	4
_1020:
	dd	0x3f000000
	align	4
_1021:
	dd	0x40800000
	align	4
_1022:
	dd	0x3f800000
_761:
	db	"f",0
_766:
	db	"b",0
	align	4
_1023:
	dd	0x43b40000
_783:
	db	"b",0
	align	8
_1037:
	dd	0x0,0x40400000
	align	8
_1038:
	dd	0x0,0xc0400000
	align	4
_38:
	dd	bbStringClass
	dd	2147483647
	dd	17
	dw	79,112,101,110,71,76,32,40,66,117,102,102,101,114,101,100
	dw	41
	align	4
_797:
	dd	0
