	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_d3d7max2d_d3d7max2d
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_graphics_graphics
	extrn	__bb_source_basefunctions
	extrn	__bb_standardio_standardio
	extrn	bbArrayNew1D
	extrn	bbEmptyString
	extrn	bbExThrow
	extrn	bbFloatToInt
	extrn	bbMemCopy
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
	extrn	bb_ARGB_Alpha
	extrn	bb_ARGB_Blue
	extrn	bb_ARGB_Color
	extrn	bb_ARGB_Green
	extrn	bb_ARGB_Red
	extrn	bb_KEYMANAGER
	extrn	bb_KEYWRAPPER
	extrn	bb_LastSeekPos
	extrn	bb_LoadSaveFile
	extrn	bb_MOUSEMANAGER
	extrn	bb_functions
	extrn	bb_isMonochrome
	extrn	brl_blitz_ArrayBoundsError
	extrn	brl_blitz_NullObjectError
	extrn	brl_glmax2d_TGLImageFrame
	extrn	brl_graphics_GraphicsHeight
	extrn	brl_graphics_GraphicsSeq
	extrn	brl_graphics_GraphicsWidth
	extrn	brl_linkedlist_CreateList
	extrn	brl_linkedlist_ListAddLast
	extrn	brl_max2d_CreateImage
	extrn	brl_max2d_DrawImage
	extrn	brl_max2d_DrawImageRect
	extrn	brl_max2d_DrawPixmap
	extrn	brl_max2d_DrawSubImageRect
	extrn	brl_max2d_DrawText
	extrn	brl_max2d_GetColor
	extrn	brl_max2d_GetViewport
	extrn	brl_max2d_GrabPixmap
	extrn	brl_max2d_ImageHeight
	extrn	brl_max2d_ImageWidth
	extrn	brl_max2d_LoadAnimImage
	extrn	brl_max2d_LoadImage
	extrn	brl_max2d_LockImage
	extrn	brl_max2d_SetColor
	extrn	brl_max2d_SetScale
	extrn	brl_max2d_TImage
	extrn	brl_max2d_TextHeight
	extrn	brl_max2d_TextWidth
	extrn	brl_max2d_UnlockImage
	extrn	brl_pixmap_ConvertPixmap
	extrn	brl_pixmap_CopyPixmap
	extrn	brl_pixmap_PixmapWindow
	extrn	brl_pixmap_ReadPixel
	extrn	brl_pixmap_TPixmap
	extrn	brl_pixmap_WritePixel
	extrn	glBindTexture
	extrn	glClear
	extrn	glClearColor
	extrn	glCopyTexImage2D
	extrn	glLoadIdentity
	extrn	glMatrixMode
	extrn	glOrtho
	extrn	glPushMatrix
	extrn	glScalef
	extrn	glTranslatef
	extrn	glViewport
	extrn	gluOrtho2D
	public	__bb_source_basefunctions_image
	public	_bb_ImageFragment_New
	public	_bb_ImageFragment_create
	public	_bb_ImageFragment_render
	public	_bb_ImageFragment_renderInViewPort
	public	_bb_TBigImage_CreateFromImage
	public	_bb_TBigImage_CreateFromPixmap
	public	_bb_TBigImage_Load
	public	_bb_TBigImage_New
	public	_bb_TBigImage_RestorePixmap
	public	_bb_TBigImage_create
	public	_bb_TBigImage_render
	public	_bb_TBigImage_renderInViewPort
	public	_bb_tRender_BackBufferRender_Begin
	public	_bb_tRender_BackBufferRender_End
	public	_bb_tRender_Cls
	public	_bb_tRender_Create
	public	_bb_tRender_DX
	public	_bb_tRender_GLFrame
	public	_bb_tRender_Height
	public	_bb_tRender_Image
	public	_bb_tRender_Initialise
	public	_bb_tRender_New
	public	_bb_tRender_Pow2Size
	public	_bb_tRender_TextureRender_Begin
	public	_bb_tRender_TextureRender_End
	public	_bb_tRender_ViewportSet
	public	_bb_tRender_Width
	public	_bb_tRender_o_b
	public	_bb_tRender_o_g
	public	_bb_tRender_o_r
	public	bb_ClipImageToViewport
	public	bb_ColorizeImage
	public	bb_ColorizePixmap
	public	bb_ColorizeTImage
	public	bb_ColorizedImage
	public	bb_CopyImage
	public	bb_DrawImageArea
	public	bb_DrawImageAreaPow2Size
	public	bb_DrawImageInViewPort
	public	bb_DrawOnPixmap
	public	bb_DrawPixmapOnPixmap
	public	bb_DrawTextOnPixmap
	public	bb_ImageFragment
	public	bb_TBigImage
	public	bb_blurPixel
	public	bb_blurPixmap
	public	bb_tRTTError
	public	bb_tRender
	public	bb_tRenderERROR
	section	"code" executable
__bb_source_basefunctions_image:
	push	ebp
	mov	ebp,esp
	push	ebx
	cmp	dword [_442],0
	je	_443
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_443:
	mov	dword [_442],1
	push	ebp
	push	_333
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	__bb_blitz_blitz
	call	__bb_graphics_graphics
	call	__bb_d3d7max2d_d3d7max2d
	call	__bb_glmax2d_glmax2d
	call	__bb_standardio_standardio
	call	__bb_source_basefunctions
	push	bb_ImageFragment
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TBigImage
	call	bbObjectRegisterType
	add	esp,4
	push	_323
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_325
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_326
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_327]
	and	eax,1
	cmp	eax,0
	jne	_328
	push	-1
	push	1
	push	1
	push	1
	call	brl_max2d_CreateImage
	add	esp,16
	mov	dword [_bb_tRender_Image],eax
	or	dword [_327],1
_328:
	push	_329
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_330
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_331
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_tRender
	call	bbObjectRegisterType
	add	esp,4
	push	_332
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_129
_129:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawImageArea:
	push	ebp
	mov	ebp,esp
	sub	esp,32
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	fstp	dword [ebp-8]
	fld	dword [ebp+16]
	fstp	dword [ebp-12]
	fld	dword [ebp+20]
	fstp	dword [ebp-16]
	fld	dword [ebp+24]
	fstp	dword [ebp-20]
	fld	dword [ebp+28]
	fstp	dword [ebp-24]
	fld	dword [ebp+32]
	fstp	dword [ebp-28]
	mov	eax,dword [ebp+36]
	mov	dword [ebp-32],eax
	push	ebp
	push	_445
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_444
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-32]
	push	0
	push	0
	push	dword [ebp-28]
	push	dword [ebp-24]
	push	dword [ebp-20]
	push	dword [ebp-16]
	push	dword [ebp-28]
	push	dword [ebp-24]
	push	dword [ebp-12]
	push	dword [ebp-8]
	push	dword [ebp-4]
	call	brl_max2d_DrawSubImageRect
	add	esp,48
	mov	ebx,0
	jmp	_139
_139:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawImageAreaPow2Size:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_460
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_453
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	sub	dword [ebp-4],1
	push	_454
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	shr	eax,1
	or	dword [ebp-4],eax
	push	_455
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	shr	eax,2
	or	dword [ebp-4],eax
	push	_456
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	shr	eax,4
	or	dword [ebp-4],eax
	push	_457
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	shr	eax,8
	or	dword [ebp-4],eax
	push	_458
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	shr	eax,16
	or	dword [ebp-4],eax
	push	_459
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	add	ebx,1
	jmp	_142
_142:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_ClipImageToViewport:
	push	ebp
	mov	ebp,esp
	sub	esp,68
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	fstp	dword [ebp-8]
	fld	dword [ebp+16]
	fstp	dword [ebp-12]
	fld	dword [ebp+20]
	fstp	dword [ebp-16]
	fld	dword [ebp+24]
	fstp	dword [ebp-20]
	fld	dword [ebp+28]
	fstp	dword [ebp-24]
	fld	dword [ebp+32]
	fstp	dword [ebp-28]
	fld	dword [ebp+36]
	fstp	dword [ebp-32]
	fld	dword [ebp+40]
	fstp	dword [ebp-36]
	mov	eax,dword [ebp+44]
	mov	dword [ebp-40],eax
	mov	dword [ebp-44],0
	mov	dword [ebp-48],0
	fldz
	fstp	dword [ebp-52]
	fldz
	fstp	dword [ebp-56]
	fldz
	fstp	dword [ebp-60]
	fldz
	fstp	dword [ebp-64]
	push	ebp
	push	_505
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_463
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	brl_max2d_ImageWidth
	add	esp,4
	mov	dword [ebp-44],eax
	push	_465
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	brl_max2d_ImageHeight
	add	esp,4
	mov	dword [ebp-48],eax
	push	_467
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-8]
	mov	eax,dword [ebp-44]
	mov	dword [ebp+-68],eax
	fild	dword [ebp+-68]
	faddp	st1,st0
	fld	dword [ebp-16]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	je	_468
	fld	dword [ebp-8]
	mov	eax,dword [ebp-44]
	mov	dword [ebp+-68],eax
	fild	dword [ebp+-68]
	fsubp	st1,st0
	fld	dword [ebp-16]
	fadd	dword [ebp-24]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
_468:
	cmp	eax,0
	je	_470
	fld	dword [ebp-12]
	mov	eax,dword [ebp-48]
	mov	dword [ebp+-68],eax
	fild	dword [ebp+-68]
	faddp	st1,st0
	fld	dword [ebp-20]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
_470:
	cmp	eax,0
	je	_472
	fld	dword [ebp-12]
	mov	eax,dword [ebp-48]
	mov	dword [ebp+-68],eax
	fild	dword [ebp+-68]
	fsubp	st1,st0
	fld	dword [ebp-20]
	fadd	dword [ebp-28]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
_472:
	cmp	eax,0
	je	_474
	push	ebp
	push	_500
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_475
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-16]
	fsub	dword [ebp-8]
	fstp	dword [ebp-52]
	push	_477
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-20]
	fsub	dword [ebp-12]
	fstp	dword [ebp-56]
	push	_479
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-52]
	fldz
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_480
	push	ebp
	push	_482
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_481
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fldz
	fstp	dword [ebp-52]
	call	dword [bbOnDebugLeaveScope]
_480:
	push	_483
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-56]
	fldz
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_484
	push	ebp
	push	_486
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_485
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fldz
	fstp	dword [ebp-56]
	call	dword [bbOnDebugLeaveScope]
_484:
	push	_487
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-8]
	mov	eax,dword [ebp-44]
	mov	dword [ebp+-68],eax
	fild	dword [ebp+-68]
	faddp	st1,st0
	fld	dword [ebp-16]
	fadd	dword [ebp-24]
	fsubp	st1,st0
	fstp	dword [ebp-60]
	push	_489
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-12]
	mov	eax,dword [ebp-48]
	mov	dword [ebp+-68],eax
	fild	dword [ebp+-68]
	faddp	st1,st0
	fld	dword [ebp-20]
	fadd	dword [ebp-28]
	fsubp	st1,st0
	fstp	dword [ebp-64]
	push	_491
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-60]
	fldz
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_492
	push	ebp
	push	_494
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_493
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fldz
	fstp	dword [ebp-60]
	call	dword [bbOnDebugLeaveScope]
_492:
	push	_495
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-64]
	fldz
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_496
	push	ebp
	push	_498
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_497
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fldz
	fstp	dword [ebp-64]
	call	dword [bbOnDebugLeaveScope]
_496:
	push	_499
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-40]
	mov	eax,dword [ebp-48]
	mov	dword [ebp+-68],eax
	fild	dword [ebp+-68]
	fsub	dword [ebp-56]
	fsub	dword [ebp-64]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-44]
	mov	dword [ebp+-68],eax
	fild	dword [ebp+-68]
	fsub	dword [ebp-52]
	fsub	dword [ebp-60]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-56]
	push	dword [ebp-52]
	fld	dword [ebp-12]
	fadd	dword [ebp-56]
	fadd	dword [ebp-36]
	sub	esp,4
	fstp	dword [esp]
	fld	dword [ebp-8]
	fadd	dword [ebp-52]
	fadd	dword [ebp-32]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-4]
	call	bb_DrawImageArea
	add	esp,32
	call	dword [bbOnDebugLeaveScope]
_474:
	mov	ebx,0
	jmp	_154
_154:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawImageInViewPort:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-16],eax
	movzx	eax,byte [ebp+20]
	mov	eax,eax
	mov	byte [ebp-4],al
	mov	eax,dword [ebp+24]
	mov	dword [ebp-20],eax
	push	ebp
	push	_530
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_515
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	cmp	eax,10
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_516
	mov	ebx,dword [ebp-16]
	push	dword [ebp-8]
	call	brl_max2d_ImageHeight
	add	esp,4
	sub	ebx,eax
	cmp	ebx,383
	setl	al
	movzx	eax,al
_516:
	cmp	eax,0
	je	_518
	push	ebp
	push	_529
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_519
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	cmp	eax,0
	jne	_520
	push	ebp
	push	_522
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_521
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-20]
	mov	ebx,dword [ebp-16]
	push	dword [ebp-8]
	call	brl_max2d_ImageHeight
	add	esp,4
	sub	ebx,eax
	mov	dword [ebp+-24],ebx
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-12]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-8]
	call	brl_max2d_DrawImage
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
	jmp	_523
_520:
	push	ebp
	push	_528
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_524
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	cmp	eax,1
	jne	_525
	push	ebp
	push	_527
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_526
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-20]
	mov	ebx,dword [ebp-16]
	push	dword [ebp-8]
	call	brl_max2d_ImageHeight
	add	esp,4
	sub	ebx,eax
	mov	dword [ebp+-24],ebx
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	mov	ebx,dword [ebp-12]
	push	dword [ebp-8]
	call	brl_max2d_ImageWidth
	add	esp,4
	sub	ebx,eax
	mov	dword [ebp+-24],ebx
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-8]
	call	brl_max2d_DrawImage
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_525:
	call	dword [bbOnDebugLeaveScope]
_523:
	call	dword [bbOnDebugLeaveScope]
_518:
	mov	ebx,0
	jmp	_161
_161:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawOnPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,92
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
	mov	eax,dword [ebp+24]
	mov	dword [ebp-20],eax
	fld	dword [ebp+28]
	fstp	dword [ebp-24]
	fld	dword [ebp+32]
	fstp	dword [ebp-28]
	mov	eax,dword [ebp+36]
	mov	dword [ebp-32],eax
	mov	dword [ebp-36],bbNullObject
	mov	dword [ebp-40],0
	mov	dword [ebp-44],0
	mov	dword [ebp-48],0
	mov	dword [ebp-52],0
	fldz
	fstp	dword [ebp-56]
	fldz
	fstp	dword [ebp-60]
	fldz
	fstp	dword [ebp-64]
	fldz
	fstp	dword [ebp-68]
	fldz
	fstp	dword [ebp-72]
	fldz
	fstp	dword [ebp-76]
	fldz
	fstp	dword [ebp-80]
	fldz
	fstp	dword [ebp-84]
	mov	dword [ebp-88],0
	mov	eax,ebp
	push	eax
	push	_636
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_537
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-36],bbNullObject
	push	_539
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-4],bbNullObject
	jne	_540
	mov	eax,ebp
	push	eax
	push	_542
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_541
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_6
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_540:
	push	_543
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],0
	jne	_544
	mov	eax,ebp
	push	eax
	push	_546
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_545
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	1
	push	0
	push	dword [ebp-4]
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-36],eax
	call	dword [bbOnDebugLeaveScope]
_544:
	push	_547
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],0
	jle	_548
	mov	eax,ebp
	push	eax
	push	_550
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_549
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	1
	push	dword [ebp-8]
	push	dword [ebp-4]
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-36],eax
	call	dword [bbOnDebugLeaveScope]
_548:
	push	_551
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-40],0
	mov	dword [ebp-40],0
	push	dword [ebp-4]
	call	brl_max2d_ImageWidth
	add	esp,4
	sub	eax,1
	mov	edi,eax
	jmp	_553
_9:
	mov	eax,ebp
	push	eax
	push	_627
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_555
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-44],0
	mov	dword [ebp-44],0
	push	dword [ebp-4]
	call	brl_max2d_ImageHeight
	add	esp,4
	sub	eax,1
	mov	ebx,eax
	jmp	_557
_12:
	mov	eax,ebp
	push	eax
	push	_625
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_559
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_561
	call	brl_blitz_NullObjectError
_561:
	mov	eax,dword [ebp-16]
	add	eax,dword [ebp-40]
	cmp	eax,dword [esi+12]
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_564
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_563
	call	brl_blitz_NullObjectError
_563:
	mov	eax,dword [ebp-20]
	add	eax,dword [ebp-44]
	cmp	eax,dword [esi+16]
	setl	al
	movzx	eax,al
_564:
	cmp	eax,0
	je	_566
	mov	eax,ebp
	push	eax
	push	_613
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_567
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-44]
	push	dword [ebp-40]
	push	dword [ebp-36]
	call	brl_pixmap_ReadPixel
	add	esp,12
	mov	dword [ebp-48],eax
	push	_569
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-20]
	add	eax,dword [ebp-44]
	push	eax
	mov	eax,dword [ebp-16]
	add	eax,dword [ebp-40]
	push	eax
	push	dword [ebp-12]
	call	brl_pixmap_ReadPixel
	add	esp,12
	mov	dword [ebp-52],eax
	push	_571
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-52]
	call	bb_ARGB_Alpha
	add	esp,4
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fstp	dword [ebp-56]
	push	_573
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	call	bb_ARGB_Alpha
	add	esp,4
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fmul	dword [ebp-24]
	fstp	dword [ebp-60]
	push	_575
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-60]
	fld	dword [_1590]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setnz	al
	movzx	eax,al
	cmp	eax,0
	jne	_576
	mov	eax,ebp
	push	eax
	push	_578
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_577
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fldz
	fstp	dword [ebp-56]
	call	dword [bbOnDebugLeaveScope]
_576:
	push	_579
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-52]
	call	bb_ARGB_Red
	add	esp,4
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fstp	dword [ebp-64]
	push	_581
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-52]
	call	bb_ARGB_Green
	add	esp,4
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fstp	dword [ebp-68]
	push	_583
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-52]
	call	bb_ARGB_Blue
	add	esp,4
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fstp	dword [ebp-72]
	push	_585
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	call	bb_ARGB_Red
	add	esp,4
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fstp	dword [ebp-76]
	push	_587
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	call	bb_ARGB_Green
	add	esp,4
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fstp	dword [ebp-80]
	push	_589
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	call	bb_ARGB_Blue
	add	esp,4
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fstp	dword [ebp-84]
	push	_591
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-56]
	fadd	dword [ebp-60]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	dword [ebp-88],eax
	push	_593
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-32],1
	jne	_594
	mov	eax,ebp
	push	eax
	push	_598
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_595
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-76]
	fmul	dword [ebp-28]
	fmul	dword [ebp-60]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fld	dword [ebp-56]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fld	dword [ebp-64]
	fmul	dword [ebp-56]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fmulp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-76]
	push	_596
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-80]
	fmul	dword [ebp-28]
	fmul	dword [ebp-60]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fld	dword [ebp-56]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fld	dword [ebp-68]
	fmul	dword [ebp-56]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fmulp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-80]
	push	_597
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-84]
	fmul	dword [ebp-28]
	fmul	dword [ebp-60]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fld	dword [ebp-56]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fld	dword [ebp-72]
	fmul	dword [ebp-56]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fmulp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-84]
	call	dword [bbOnDebugLeaveScope]
	jmp	_599
_594:
	mov	eax,ebp
	push	eax
	push	_603
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_600
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-76]
	fmul	dword [ebp-28]
	fmul	dword [ebp-60]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fld	dword [ebp-64]
	fmul	dword [ebp-56]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-76]
	push	_601
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-80]
	fmul	dword [ebp-28]
	fmul	dword [ebp-60]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fld	dword [ebp-68]
	fmul	dword [ebp-56]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-80]
	push	_602
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-84]
	fmul	dword [ebp-28]
	fmul	dword [ebp-60]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	fld	dword [ebp-72]
	fmul	dword [ebp-56]
	mov	eax,dword [ebp-88]
	mov	dword [ebp+-92],eax
	fild	dword [ebp+-92]
	fdivp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-84]
	call	dword [bbOnDebugLeaveScope]
_599:
	push	_604
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-88],255
	jle	_605
	mov	eax,ebp
	push	eax
	push	_607
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_606
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-88],255
	call	dword [bbOnDebugLeaveScope]
_605:
	push	_608
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-84]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp-80]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp-76]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	dword [ebp-88]
	call	bb_ARGB_Color
	add	esp,16
	mov	dword [ebp-48],eax
	push	_609
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-60]
	fldz
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setz	al
	movzx	eax,al
	cmp	eax,0
	jne	_610
	mov	eax,ebp
	push	eax
	push	_612
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_611
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	mov	eax,dword [ebp-20]
	add	eax,dword [ebp-44]
	push	eax
	mov	eax,dword [ebp-16]
	add	eax,dword [ebp-40]
	push	eax
	push	dword [ebp-12]
	call	brl_pixmap_WritePixel
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_610:
	call	dword [bbOnDebugLeaveScope]
_566:
	call	dword [bbOnDebugLeaveScope]
_10:
	add	dword [ebp-44],1
_557:
	cmp	dword [ebp-44],ebx
	jle	_12
_11:
	call	dword [bbOnDebugLeaveScope]
_7:
	add	dword [ebp-40],1
_553:
	cmp	dword [ebp-40],edi
	jle	_9
_8:
	push	_628
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],0
	jne	_629
	mov	eax,ebp
	push	eax
	push	_631
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_630
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	dword [ebp-4]
	call	brl_max2d_UnlockImage
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_629:
	push	_632
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],0
	jle	_633
	mov	eax,ebp
	push	eax
	push	_635
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_634
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	push	dword [ebp-4]
	call	brl_max2d_UnlockImage
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_633:
	mov	ebx,0
	jmp	_171
_171:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawPixmapOnPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,64
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
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	mov	dword [ebp-28],0
	mov	dword [ebp-32],0
	mov	dword [ebp-36],0
	mov	dword [ebp-40],0
	mov	dword [ebp-44],0
	mov	dword [ebp-48],0
	mov	dword [ebp-52],0
	mov	dword [ebp-56],0
	mov	dword [ebp-60],0
	mov	eax,ebp
	push	eax
	push	_700
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_644
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	mov	dword [ebp-20],0
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_647
	call	brl_blitz_NullObjectError
_647:
	mov	eax,dword [ebx+12]
	sub	eax,1
	mov	edi,eax
	jmp	_648
_15:
	mov	eax,ebp
	push	eax
	push	_699
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_650
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],0
	mov	dword [ebp-24],0
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_653
	call	brl_blitz_NullObjectError
_653:
	mov	eax,dword [ebx+16]
	sub	eax,1
	mov	ebx,eax
	jmp	_654
_18:
	mov	eax,ebp
	push	eax
	push	_698
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_656
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_658
	call	brl_blitz_NullObjectError
_658:
	mov	eax,dword [ebp-12]
	add	eax,1
	cmp	eax,dword [esi+12]
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_661
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_660
	call	brl_blitz_NullObjectError
_660:
	mov	eax,dword [ebp-16]
	add	eax,dword [ebp-24]
	cmp	eax,dword [esi+16]
	setl	al
	movzx	eax,al
_661:
	cmp	eax,0
	je	_663
	mov	eax,ebp
	push	eax
	push	_697
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_664
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-24]
	push	dword [ebp-20]
	push	dword [ebp-4]
	call	brl_pixmap_ReadPixel
	add	esp,12
	mov	dword [ebp-28],eax
	push	_666
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	add	eax,dword [ebp-24]
	push	eax
	mov	eax,dword [ebp-12]
	add	eax,dword [ebp-20]
	push	eax
	push	dword [ebp-8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	mov	dword [ebp-32],eax
	push	_668
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-28]
	call	bb_ARGB_Alpha
	add	esp,4
	mov	dword [ebp-36],eax
	push	_670
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-36],-1
	je	_671
	mov	eax,ebp
	push	eax
	push	_692
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_672
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-36],-1
	jge	_673
	mov	eax,ebp
	push	eax
	push	_675
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_674
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-36]
	neg	eax
	mov	dword [ebp-36],eax
	call	dword [bbOnDebugLeaveScope]
_673:
	push	_676
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-32]
	call	bb_ARGB_Red
	add	esp,4
	mov	dword [ebp-40],eax
	push	_678
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-32]
	call	bb_ARGB_Green
	add	esp,4
	mov	dword [ebp-44],eax
	push	_680
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-32]
	call	bb_ARGB_Blue
	add	esp,4
	mov	dword [ebp-48],eax
	push	_682
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-28]
	call	bb_ARGB_Red
	add	esp,4
	mov	dword [ebp-52],eax
	push	_684
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-28]
	call	bb_ARGB_Green
	add	esp,4
	mov	dword [ebp-56],eax
	push	_686
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-28]
	call	bb_ARGB_Blue
	add	esp,4
	mov	dword [ebp-60],eax
	push	_688
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-36]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fdiv	dword [_1606]
	mov	eax,dword [ebp-52]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	esi,eax
	mov	eax,255
	sub	eax,dword [ebp-36]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fdiv	dword [_1607]
	mov	eax,dword [ebp-40]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	add	esi,eax
	mov	dword [ebp-52],esi
	push	_689
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-36]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fdiv	dword [_1608]
	mov	eax,dword [ebp-56]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	esi,eax
	mov	eax,255
	sub	eax,dword [ebp-36]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fdiv	dword [_1609]
	mov	eax,dword [ebp-44]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	add	esi,eax
	mov	dword [ebp-56],esi
	push	_690
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-36]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fdiv	dword [_1610]
	mov	eax,dword [ebp-60]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	esi,eax
	mov	eax,255
	sub	eax,dword [ebp-36]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fdiv	dword [_1611]
	mov	eax,dword [ebp-48]
	mov	dword [ebp+-64],eax
	fild	dword [ebp+-64]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	add	esi,eax
	mov	dword [ebp-60],esi
	push	_691
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-60]
	push	dword [ebp-56]
	push	dword [ebp-52]
	push	255
	call	bb_ARGB_Color
	add	esp,16
	mov	dword [ebp-28],eax
	call	dword [bbOnDebugLeaveScope]
_671:
	push	_693
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-36],0
	je	_694
	mov	eax,ebp
	push	eax
	push	_696
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_695
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-28]
	mov	eax,dword [ebp-16]
	add	eax,dword [ebp-24]
	push	eax
	mov	eax,dword [ebp-12]
	add	eax,dword [ebp-20]
	push	eax
	push	dword [ebp-8]
	call	brl_pixmap_WritePixel
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_694:
	call	dword [bbOnDebugLeaveScope]
_663:
	call	dword [bbOnDebugLeaveScope]
_16:
	add	dword [ebp-24],1
_654:
	cmp	dword [ebp-24],ebx
	jle	_18
_17:
	call	dword [bbOnDebugLeaveScope]
_13:
	add	dword [ebp-20],1
_648:
	cmp	dword [ebp-20],edi
	jle	_15
_14:
	mov	ebx,0
	jmp	_177
_177:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_blurPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,40
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	fstp	dword [ebp-8]
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	mov	dword [ebp-28],0
	mov	dword [ebp-32],0
	mov	dword [ebp-36],0
	mov	dword [ebp-40],0
	mov	eax,ebp
	push	eax
	push	_762
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_703
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	mov	dword [ebp-12],1
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_706
	call	brl_blitz_NullObjectError
_706:
	mov	esi,dword [ebx+12]
	sub	esi,1
	jmp	_707
_21:
	mov	eax,ebp
	push	eax
	push	_718
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_709
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],0
	mov	dword [ebp-16],0
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_712
	call	brl_blitz_NullObjectError
_712:
	mov	ebx,dword [ebx+16]
	sub	ebx,1
	jmp	_713
_24:
	mov	eax,ebp
	push	eax
	push	_716
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_715
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	push	dword [ebp-16]
	mov	eax,dword [ebp-12]
	sub	eax,1
	push	eax
	push	dword [ebp-4]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-4]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	call	bb_blurPixel
	add	esp,12
	push	eax
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-4]
	call	brl_pixmap_WritePixel
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_22:
	add	dword [ebp-16],1
_713:
	cmp	dword [ebp-16],ebx
	jle	_24
_23:
	call	dword [bbOnDebugLeaveScope]
_19:
	add	dword [ebp-12],1
_707:
	cmp	dword [ebp-12],esi
	jle	_21
_20:
	push	_719
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_722
	call	brl_blitz_NullObjectError
_722:
	mov	eax,dword [ebx+12]
	sub	eax,3
	mov	dword [ebp-20],eax
	jmp	_723
_27:
	mov	eax,ebp
	push	eax
	push	_732
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_724
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],0
	mov	dword [ebp-24],0
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_727
	call	brl_blitz_NullObjectError
_727:
	mov	ebx,dword [ebx+16]
	sub	ebx,1
	jmp	_728
_30:
	mov	eax,ebp
	push	eax
	push	_731
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_730
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	push	dword [ebp-24]
	mov	eax,dword [ebp-20]
	add	eax,1
	push	eax
	push	dword [ebp-4]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	push	dword [ebp-24]
	push	dword [ebp-20]
	push	dword [ebp-4]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	call	bb_blurPixel
	add	esp,12
	push	eax
	push	dword [ebp-24]
	push	dword [ebp-20]
	push	dword [ebp-4]
	call	brl_pixmap_WritePixel
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_28:
	add	dword [ebp-24],1
_728:
	cmp	dword [ebp-24],ebx
	jle	_30
_29:
	call	dword [bbOnDebugLeaveScope]
_25:
	add	dword [ebp-20],-1
_723:
	cmp	dword [ebp-20],0
	jge	_27
_26:
	push	_733
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-28],0
	mov	dword [ebp-28],0
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_736
	call	brl_blitz_NullObjectError
_736:
	mov	esi,dword [ebx+12]
	sub	esi,1
	jmp	_737
_33:
	mov	eax,ebp
	push	eax
	push	_747
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_739
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],0
	mov	dword [ebp-32],1
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_742
	call	brl_blitz_NullObjectError
_742:
	mov	ebx,dword [ebx+16]
	sub	ebx,1
	jmp	_743
_36:
	mov	eax,ebp
	push	eax
	push	_746
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_745
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	mov	eax,dword [ebp-32]
	sub	eax,1
	push	eax
	push	dword [ebp-28]
	push	dword [ebp-4]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	push	dword [ebp-32]
	push	dword [ebp-28]
	push	dword [ebp-4]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	call	bb_blurPixel
	add	esp,12
	push	eax
	push	dword [ebp-32]
	push	dword [ebp-28]
	push	dword [ebp-4]
	call	brl_pixmap_WritePixel
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_34:
	add	dword [ebp-32],1
_743:
	cmp	dword [ebp-32],ebx
	jle	_36
_35:
	call	dword [bbOnDebugLeaveScope]
_31:
	add	dword [ebp-28],1
_737:
	cmp	dword [ebp-28],esi
	jle	_33
_32:
	push	_748
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-36],0
	mov	dword [ebp-36],0
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_751
	call	brl_blitz_NullObjectError
_751:
	mov	ebx,dword [ebx+12]
	sub	ebx,1
	jmp	_752
_39:
	mov	eax,ebp
	push	eax
	push	_761
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_754
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-40],0
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_757
	call	brl_blitz_NullObjectError
_757:
	mov	eax,dword [esi+16]
	sub	eax,3
	mov	dword [ebp-40],eax
	jmp	_758
_42:
	mov	eax,ebp
	push	eax
	push	_760
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_759
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	mov	eax,dword [ebp-40]
	add	eax,1
	push	eax
	push	dword [ebp-36]
	push	dword [ebp-4]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	push	dword [ebp-40]
	push	dword [ebp-36]
	push	dword [ebp-4]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	call	bb_blurPixel
	add	esp,12
	push	eax
	push	dword [ebp-40]
	push	dword [ebp-36]
	push	dword [ebp-4]
	call	brl_pixmap_WritePixel
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_40:
	add	dword [ebp-40],-1
_758:
	cmp	dword [ebp-40],0
	jge	_42
_41:
	call	dword [bbOnDebugLeaveScope]
_37:
	add	dword [ebp-36],1
_752:
	cmp	dword [ebp-36],ebx
	jle	_39
_38:
	mov	ebx,0
	jmp	_181
_181:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_blurPixel:
	push	ebp
	mov	ebp,esp
	sub	esp,44
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-32],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-36],eax
	fld	dword [ebp+16]
	fstp	dword [ebp-40]
	mov	byte [ebp-4],0
	mov	byte [ebp-8],0
	mov	byte [ebp-12],0
	mov	byte [ebp-16],0
	mov	byte [ebp-20],0
	mov	byte [ebp-24],0
	mov	byte [ebp-28],0
	push	ebp
	push	_784
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_766
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	shr	eax,24
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-4],al
	push	_768
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	shr	eax,16
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-8],al
	push	_770
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	shr	eax,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-12],al
	push	_772
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-16],al
	push	_774
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-36]
	shr	eax,16
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-20],al
	push	_776
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-36]
	shr	eax,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-24],al
	push	_778
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-36]
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-28],al
	push	_780
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-20]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	fld	dword [_1633]
	fsub	dword [ebp-40]
	fmulp	st1,st0
	movzx	eax,byte [ebp-8]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	fmul	dword [ebp-40]
	faddp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-8],al
	push	_781
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-24]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	fld	dword [_1634]
	fsub	dword [ebp-40]
	fmulp	st1,st0
	movzx	eax,byte [ebp-12]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	fmul	dword [ebp-40]
	faddp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-12],al
	push	_782
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-28]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	fld	dword [_1635]
	fsub	dword [ebp-40]
	fmulp	st1,st0
	movzx	eax,byte [ebp-16]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	fmul	dword [ebp-40]
	faddp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-16],al
	push	_783
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	mov	ebx,eax
	shl	ebx,24
	movzx	eax,byte [ebp-8]
	mov	eax,eax
	shl	eax,16
	or	ebx,eax
	movzx	eax,byte [ebp-12]
	mov	eax,eax
	shl	eax,8
	or	ebx,eax
	movzx	eax,byte [ebp-16]
	mov	eax,eax
	or	ebx,eax
	jmp	_186
_186:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawTextOnPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,44
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-16],eax
	mov	eax,dword [ebp+20]
	mov	dword [ebp-20],eax
	movzx	eax,byte [ebp+24]
	mov	eax,eax
	mov	byte [ebp-4],al
	mov	dword [ebp-32],0
	mov	dword [ebp-36],0
	mov	dword [ebp-40],0
	mov	dword [ebp-24],0
	mov	dword [ebp-28],bbNullObject
	push	ebp
	push	_826
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_794
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_795
	push	ebp
	push	_805
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_796
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],0
	mov	dword [ebp-36],0
	mov	dword [ebp-40],0
	push	_800
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	lea	eax,dword [ebp-40]
	push	eax
	lea	eax,dword [ebp-36]
	push	eax
	lea	eax,dword [ebp-32]
	push	eax
	call	brl_max2d_GetColor
	add	esp,12
	push	_801
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	50
	push	50
	push	50
	call	brl_max2d_SetColor
	add	esp,12
	push	_802
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	sub	eax,1
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-12]
	sub	eax,1
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-8]
	call	brl_max2d_DrawText
	add	esp,12
	push	_803
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	add	eax,1
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-12]
	add	eax,1
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-8]
	call	brl_max2d_DrawText
	add	esp,12
	push	_804
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-40]
	push	dword [ebp-36]
	push	dword [ebp-32]
	call	brl_max2d_SetColor
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
	jmp	_808
_795:
	push	ebp
	push	_810
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_809
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-12]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-8]
	call	brl_max2d_DrawText
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_808:
	push	_811
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_max2d_TextWidth
	add	esp,4
	mov	dword [ebp-24],eax
	push	_813
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_max2d_TextHeight
	add	esp,4
	add	eax,4
	push	eax
	mov	eax,dword [ebp-24]
	add	eax,4
	push	eax
	mov	eax,dword [ebp-16]
	sub	eax,2
	push	eax
	mov	eax,dword [ebp-12]
	sub	eax,2
	push	eax
	call	brl_max2d_GrabPixmap
	add	esp,16
	mov	dword [ebp-28],eax
	push	_815
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	4
	push	dword [ebp-28]
	call	brl_pixmap_ConvertPixmap
	add	esp,8
	mov	dword [ebp-28],eax
	push	_816
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_817
	push	ebp
	push	_824
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_818
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1056964608
	push	dword [ebp-28]
	call	bb_blurPixmap
	add	esp,8
	push	_819
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	4
	push	dword [ebp-28]
	call	brl_pixmap_ConvertPixmap
	add	esp,8
	mov	dword [ebp-28],eax
	push	_820
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	sub	eax,2
	push	eax
	mov	eax,dword [ebp-12]
	sub	eax,2
	push	eax
	push	dword [ebp-28]
	call	brl_max2d_DrawPixmap
	add	esp,12
	push	_821
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-12]
	mov	dword [ebp+-44],eax
	fild	dword [ebp+-44]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-8]
	call	brl_max2d_DrawText
	add	esp,12
	push	_822
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	brl_max2d_TextHeight
	add	esp,4
	add	eax,4
	push	eax
	mov	eax,dword [ebp-24]
	add	eax,4
	push	eax
	mov	eax,dword [ebp-16]
	sub	eax,2
	push	eax
	mov	eax,dword [ebp-12]
	sub	eax,2
	push	eax
	call	brl_max2d_GrabPixmap
	add	esp,16
	mov	dword [ebp-28],eax
	push	_823
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	4
	push	dword [ebp-28]
	call	brl_pixmap_ConvertPixmap
	add	esp,8
	mov	dword [ebp-28],eax
	call	dword [bbOnDebugLeaveScope]
_817:
	push	_825
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	sub	eax,10
	push	eax
	mov	eax,dword [ebp-12]
	sub	eax,20
	push	eax
	push	dword [ebp-20]
	push	dword [ebp-28]
	call	bb_DrawPixmapOnPixmap
	add	esp,16
	mov	ebx,0
	jmp	_193
_193:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ImageFragment_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_832
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_ImageFragment
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbNullObject
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+12]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+16]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+20]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+24]
	push	ebp
	push	_831
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_196
_196:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ImageFragment_create:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	fstp	dword [ebp-8]
	fld	dword [ebp+16]
	fstp	dword [ebp-12]
	fld	dword [ebp+20]
	fstp	dword [ebp-16]
	fld	dword [ebp+24]
	fstp	dword [ebp-20]
	mov	dword [ebp-24],bbNullObject
	push	ebp
	push	_858
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_835
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_ImageFragment
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-24],eax
	push	_837
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_839
	call	brl_blitz_NullObjectError
_839:
	push	0
	fld	dword [ebp-20]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp-16]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp-12]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp-8]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	dword [ebp-4]
	call	brl_pixmap_PixmapWindow
	add	esp,20
	push	eax
	call	brl_max2d_LoadImage
	add	esp,8
	mov	dword [ebx+8],eax
	push	_841
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_843
	call	brl_blitz_NullObjectError
_843:
	fld	dword [ebp-8]
	fstp	dword [ebx+12]
	push	_845
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_847
	call	brl_blitz_NullObjectError
_847:
	fld	dword [ebp-12]
	fstp	dword [ebx+16]
	push	_849
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_851
	call	brl_blitz_NullObjectError
_851:
	fld	dword [ebp-16]
	fstp	dword [ebx+20]
	push	_853
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_855
	call	brl_blitz_NullObjectError
_855:
	fld	dword [ebp-20]
	fstp	dword [ebx+24]
	push	_857
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	jmp	_203
_203:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ImageFragment_render:
	push	ebp
	mov	ebp,esp
	sub	esp,32
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	fstp	dword [ebp-8]
	fld	dword [ebp+16]
	fstp	dword [ebp-12]
	fld	dword [ebp+20]
	fstp	dword [ebp-16]
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	mov	dword [ebp-28],0
	mov	eax,ebp
	push	eax
	push	_884
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_861
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	mov	dword [ebp-28],0
	push	_865
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	lea	eax,dword [ebp-28]
	push	eax
	lea	eax,dword [ebp-20]
	push	eax
	lea	eax,dword [ebp-24]
	push	eax
	lea	eax,dword [ebp-20]
	push	eax
	call	brl_max2d_GetViewport
	add	esp,16
	push	_866
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_868
	call	brl_blitz_NullObjectError
_868:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_870
	call	brl_blitz_NullObjectError
_870:
	fld	dword [ebp-12]
	fld	dword [ebp-16]
	fmul	dword [esi+16]
	faddp	st1,st0
	fadd	dword [ebx+24]
	fldz
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	seta	al
	movzx	eax,al
	cmp	eax,0
	je	_873
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_872
	call	brl_blitz_NullObjectError
_872:
	fld	dword [ebp-12]
	fld	dword [ebp-16]
	fmul	dword [ebx+16]
	faddp	st1,st0
	mov	eax,dword [ebp-24]
	add	eax,dword [ebp-28]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
_873:
	cmp	eax,0
	je	_875
	mov	eax,ebp
	push	eax
	push	_883
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_876
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_878
	call	brl_blitz_NullObjectError
_878:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_880
	call	brl_blitz_NullObjectError
_880:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_882
	call	brl_blitz_NullObjectError
_882:
	push	0
	fld	dword [ebp-12]
	fld	dword [ebp-16]
	fmul	dword [ebx+16]
	faddp	st1,st0
	sub	esp,4
	fstp	dword [esp]
	fld	dword [ebp-8]
	fld	dword [ebp-16]
	fmul	dword [esi+12]
	faddp	st1,st0
	sub	esp,4
	fstp	dword [esp]
	push	dword [edi+8]
	call	brl_max2d_DrawImage
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_875:
	mov	ebx,0
	jmp	_209
_209:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ImageFragment_renderInViewPort:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	fstp	dword [ebp-8]
	fld	dword [ebp+16]
	fstp	dword [ebp-12]
	fld	dword [ebp+20]
	fstp	dword [ebp-16]
	fld	dword [ebp+24]
	fstp	dword [ebp-20]
	fld	dword [ebp+28]
	fstp	dword [ebp-24]
	fld	dword [ebp+32]
	fstp	dword [ebp-28]
	mov	eax,ebp
	push	eax
	push	_898
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_891
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_893
	call	brl_blitz_NullObjectError
_893:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_895
	call	brl_blitz_NullObjectError
_895:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_897
	call	brl_blitz_NullObjectError
_897:
	push	0
	push	0
	push	0
	push	dword [ebp-28]
	push	dword [ebp-24]
	push	dword [ebp-20]
	push	dword [ebp-16]
	fld	dword [ebp-12]
	fadd	dword [ebx+16]
	sub	esp,4
	fstp	dword [esp]
	fld	dword [ebp-8]
	fadd	dword [esi+12]
	sub	esp,4
	fstp	dword [esp]
	push	dword [edi+8]
	call	bb_ClipImageToViewport
	add	esp,40
	mov	ebx,0
	jmp	_218
_218:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_901
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_TBigImage
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbNullObject
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+12]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+16]
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],bbNullObject
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+24]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+28]
	mov	eax,dword [ebp-4]
	mov	dword [eax+32],0
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+36]
	mov	eax,dword [ebp-4]
	fldz
	fstp	dword [eax+40]
	push	ebp
	push	_900
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_221
_221:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_CreateFromImage:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_911
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_903
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_905
	call	brl_blitz_NullObjectError
_905:
	mov	esi,dword [ebx+40]
	mov	ebx,0
	cmp	ebx,dword [esi+20]
	jb	_908
	call	brl_blitz_ArrayBoundsError
_908:
	mov	eax,dword [esi+ebx*4+24]
	mov	dword [ebp-8],eax
	push	_910
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	dword [bb_TBigImage+56]
	add	esp,4
	mov	ebx,eax
	jmp	_224
_224:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_CreateFromPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_914
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_913
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	dword [bb_TBigImage+56]
	add	esp,4
	mov	ebx,eax
	jmp	_227
_227:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_create:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_951
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_915
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_TBigImage
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	push	_917
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_919
	call	brl_blitz_NullObjectError
_919:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+8],eax
	push	_921
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_923
	call	brl_blitz_NullObjectError
_923:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_926
	call	brl_blitz_NullObjectError
_926:
	mov	eax,dword [esi+12]
	mov	dword [ebp+-12],eax
	fild	dword [ebp+-12]
	fstp	dword [ebx+24]
	push	_927
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_929
	call	brl_blitz_NullObjectError
_929:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_932
	call	brl_blitz_NullObjectError
_932:
	mov	eax,dword [esi+16]
	mov	dword [ebp+-12],eax
	fild	dword [ebp+-12]
	fstp	dword [ebx+28]
	push	_933
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_935
	call	brl_blitz_NullObjectError
_935:
	call	brl_linkedlist_CreateList
	mov	dword [ebx+20],eax
	push	_937
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_939
	call	brl_blitz_NullObjectError
_939:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,4
	push	_940
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_942
	call	brl_blitz_NullObjectError
_942:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_945
	call	brl_blitz_NullObjectError
_945:
	mov	eax,dword [esi+24]
	mov	dword [ebx+32],eax
	push	_946
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_948
	call	brl_blitz_NullObjectError
_948:
	mov	dword [ebx+8],bbNullObject
	push	_950
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_230
_230:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_RestorePixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	mov	dword [ebp-12],bbNullObject
	mov	eax,ebp
	push	eax
	push	_984
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_954
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_956
	call	brl_blitz_NullObjectError
_956:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_958
	call	brl_blitz_NullObjectError
_958:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_960
	call	brl_blitz_NullObjectError
_960:
	push	4
	push	dword [ebx+32]
	fld	dword [esi+28]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [edi+24]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	call	dword [brl_pixmap_TPixmap+80]
	add	esp,16
	mov	dword [ebp-8],eax
	push	_962
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_965
	call	brl_blitz_NullObjectError
_965:
	mov	eax,dword [ebx+20]
	mov	dword [ebp-20],eax
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_968
	call	brl_blitz_NullObjectError
_968:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-16],eax
	jmp	_43
_45:
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_973
	call	brl_blitz_NullObjectError
_973:
	push	bb_ImageFragment
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-12],eax
	cmp	dword [ebp-12],bbNullObject
	je	_43
	mov	eax,ebp
	push	eax
	push	_981
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_974
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-12]
	cmp	edi,bbNullObject
	jne	_976
	call	brl_blitz_NullObjectError
_976:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_978
	call	brl_blitz_NullObjectError
_978:
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_980
	call	brl_blitz_NullObjectError
_980:
	push	0
	push	1065353216
	push	1065353216
	fld	dword [ebx+16]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [esi+12]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	dword [ebp-8]
	push	0
	push	dword [edi+8]
	call	bb_DrawOnPixmap
	add	esp,32
	call	dword [bbOnDebugLeaveScope]
_43:
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_971
	call	brl_blitz_NullObjectError
_971:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_45
_44:
	push	_983
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_233
_233:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_Load:
	push	ebp
	mov	ebp,esp
	sub	esp,32
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	fldz
	fstp	dword [ebp-12]
	fldz
	fstp	dword [ebp-16]
	mov	byte [ebp-4],0
	mov	dword [ebp-20],0
	mov	dword [ebp-24],0
	mov	dword [ebp-28],bbNullObject
	push	ebp
	push	_1048
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_986
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fldz
	fstp	dword [ebp-12]
	push	_988
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fldz
	fstp	dword [ebp-16]
	push	_990
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	byte [ebp-4],1
	push	_992
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_46
_48:
	push	ebp
	push	_1046
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_993
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],256
	push	_995
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],256
	push	_997
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_999
	call	brl_blitz_NullObjectError
_999:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_1001
	call	brl_blitz_NullObjectError
_1001:
	mov	eax,dword [ebx+12]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fsub	dword [ebp-12]
	fld	dword [_1705]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_1002
	push	ebp
	push	_1008
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1003
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1005
	call	brl_blitz_NullObjectError
_1005:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_1007
	call	brl_blitz_NullObjectError
_1007:
	mov	eax,dword [ebx+12]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fsub	dword [ebp-12]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	dword [ebp-20],eax
	call	dword [bbOnDebugLeaveScope]
_1002:
	push	_1009
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1011
	call	brl_blitz_NullObjectError
_1011:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_1013
	call	brl_blitz_NullObjectError
_1013:
	mov	eax,dword [ebx+16]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fsub	dword [ebp-16]
	fld	dword [_1706]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_1014
	push	ebp
	push	_1020
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1015
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1017
	call	brl_blitz_NullObjectError
_1017:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_1019
	call	brl_blitz_NullObjectError
_1019:
	mov	eax,dword [ebx+16]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fsub	dword [ebp-16]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	dword [ebp-24],eax
	call	dword [bbOnDebugLeaveScope]
_1014:
	push	_1021
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1023
	call	brl_blitz_NullObjectError
_1023:
	mov	eax,dword [ebp-24]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-20]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebx+8]
	call	dword [bb_ImageFragment+48]
	add	esp,20
	mov	dword [ebp-28],eax
	push	_1025
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1027
	call	brl_blitz_NullObjectError
_1027:
	push	dword [ebp-28]
	push	dword [ebx+20]
	call	brl_linkedlist_ListAddLast
	add	esp,8
	push	_1028
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-12]
	fadd	dword [_1707]
	fstp	dword [ebp-12]
	push	_1029
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1031
	call	brl_blitz_NullObjectError
_1031:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_1033
	call	brl_blitz_NullObjectError
_1033:
	fld	dword [ebp-12]
	mov	eax,dword [ebx+12]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
	cmp	eax,0
	jne	_1034
	push	ebp
	push	_1045
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1035
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fldz
	fstp	dword [ebp-12]
	push	_1036
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-16]
	fadd	dword [_1708]
	fstp	dword [ebp-16]
	push	_1037
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1039
	call	brl_blitz_NullObjectError
_1039:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_1041
	call	brl_blitz_NullObjectError
_1041:
	fld	dword [ebp-16]
	mov	eax,dword [ebx+16]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
	cmp	eax,0
	jne	_1042
	push	ebp
	push	_1044
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1043
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	byte [ebp-4],0
	call	dword [bbOnDebugLeaveScope]
_1042:
	call	dword [bbOnDebugLeaveScope]
_1034:
	call	dword [bbOnDebugLeaveScope]
_46:
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	jne	_48
_47:
	mov	ebx,0
	jmp	_236
_236:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_render:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	fstp	dword [ebp-8]
	fld	dword [ebp+16]
	fstp	dword [ebp-12]
	fld	dword [ebp+20]
	fstp	dword [ebp-16]
	mov	dword [ebp-20],bbNullObject
	mov	eax,ebp
	push	eax
	push	_1066
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1050
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],bbNullObject
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1053
	call	brl_blitz_NullObjectError
_1053:
	mov	edi,dword [ebx+20]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1056
	call	brl_blitz_NullObjectError
_1056:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_49
_51:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1061
	call	brl_blitz_NullObjectError
_1061:
	push	bb_ImageFragment
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],bbNullObject
	je	_49
	mov	eax,ebp
	push	eax
	push	_1065
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1062
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1064
	call	brl_blitz_NullObjectError
_1064:
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,16
	call	dword [bbOnDebugLeaveScope]
_49:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1059
	call	brl_blitz_NullObjectError
_1059:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_51
_50:
	mov	ebx,0
	jmp	_242
_242:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_renderInViewPort:
	push	ebp
	mov	ebp,esp
	sub	esp,32
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	fstp	dword [ebp-8]
	fld	dword [ebp+16]
	fstp	dword [ebp-12]
	fld	dword [ebp+20]
	fstp	dword [ebp-16]
	fld	dword [ebp+24]
	fstp	dword [ebp-20]
	fld	dword [ebp+28]
	fstp	dword [ebp-24]
	fld	dword [ebp+32]
	fstp	dword [ebp-28]
	mov	dword [ebp-32],bbNullObject
	mov	eax,ebp
	push	eax
	push	_1083
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1067
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],bbNullObject
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1070
	call	brl_blitz_NullObjectError
_1070:
	mov	edi,dword [ebx+20]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1073
	call	brl_blitz_NullObjectError
_1073:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_52
_54:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1078
	call	brl_blitz_NullObjectError
_1078:
	push	bb_ImageFragment
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-32],eax
	cmp	dword [ebp-32],bbNullObject
	je	_52
	mov	eax,ebp
	push	eax
	push	_1082
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1079
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_1081
	call	brl_blitz_NullObjectError
_1081:
	push	dword [ebp-28]
	push	dword [ebp-24]
	push	dword [ebp-20]
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,28
	call	dword [bbOnDebugLeaveScope]
_52:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1076
	call	brl_blitz_NullObjectError
_1076:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_54
_53:
	mov	ebx,0
	jmp	_251
_251:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_tRTTError:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1102
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1084
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	eax,-2005532080
	je	_1087
	cmp	eax,-2147024809
	je	_1088
	cmp	eax,-2005532542
	je	_1089
	cmp	eax,-2005532417
	je	_1090
	cmp	eax,-2005532222
	je	_1091
	jmp	_1086
_1087:
	push	ebp
	push	_1093
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1092
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,_55
	call	dword [bbOnDebugLeaveScope]
	jmp	_254
_1088:
	push	ebp
	push	_1095
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1094
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,_56
	call	dword [bbOnDebugLeaveScope]
	jmp	_254
_1089:
	push	ebp
	push	_1097
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1096
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,_57
	call	dword [bbOnDebugLeaveScope]
	jmp	_254
_1090:
	push	ebp
	push	_1099
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1098
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,_58
	call	dword [bbOnDebugLeaveScope]
	jmp	_254
_1091:
	push	ebp
	push	_1101
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1100
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,_59
	call	dword [bbOnDebugLeaveScope]
	jmp	_254
_1086:
	mov	ebx,bbEmptyString
	jmp	_254
_254:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1106
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_tRender
	push	ebp
	push	_1105
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_257
_257:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_Initialise:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	ebp
	push	_1110
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1108
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [_bb_tRender_DX],0
	push	_1109
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_259
_259:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	mov	dword [ebp-16],bbNullObject
	mov	eax,ebp
	push	eax
	push	_1183
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1111
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	brl_max2d_TImage
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-16],eax
	push	_1113
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1115
	call	brl_blitz_NullObjectError
_1115:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+8],eax
	push	_1117
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1119
	call	brl_blitz_NullObjectError
_1119:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+12],eax
	push	_1121
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1123
	call	brl_blitz_NullObjectError
_1123:
	mov	eax,dword [ebp-12]
	mov	dword [ebx+16],eax
	push	_1125
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1127
	call	brl_blitz_NullObjectError
_1127:
	mov	dword [ebx+20],0
	push	_1129
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1131
	call	brl_blitz_NullObjectError
_1131:
	mov	dword [ebx+24],0
	push	_1133
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1135
	call	brl_blitz_NullObjectError
_1135:
	mov	dword [ebx+28],0
	push	_1137
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1139
	call	brl_blitz_NullObjectError
_1139:
	push	1
	push	_1141
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebx+40],eax
	push	_1142
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1144
	call	brl_blitz_NullObjectError
_1144:
	push	1
	push	_1146
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebx+44],eax
	push	_1147
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1149
	call	brl_blitz_NullObjectError
_1149:
	push	1
	push	_1151
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebx+48],eax
	push	_1152
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1154
	call	brl_blitz_NullObjectError
_1154:
	mov	ebx,dword [ebx+40]
	mov	esi,0
	cmp	esi,dword [ebx+20]
	jb	_1157
	call	brl_blitz_ArrayBoundsError
_1157:
	shl	esi,2
	add	ebx,esi
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_1160
	call	brl_blitz_NullObjectError
_1160:
	push	0
	push	1
	push	0
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+56]
	add	esp,16
	mov	dword [ebx+24],eax
	push	_1161
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1163
	call	brl_blitz_NullObjectError
_1163:
	mov	esi,dword [ebx+48]
	mov	ebx,0
	cmp	ebx,dword [esi+20]
	jb	_1166
	call	brl_blitz_ArrayBoundsError
_1166:
	shl	ebx,2
	add	esi,ebx
	mov	eax,dword [brl_graphics_GraphicsSeq]
	mov	dword [esi+24],eax
	push	_1168
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1170
	call	brl_blitz_NullObjectError
_1170:
	mov	esi,dword [ebx+44]
	mov	ebx,0
	cmp	ebx,dword [esi+20]
	jb	_1173
	call	brl_blitz_ArrayBoundsError
_1173:
	shl	ebx,2
	add	esi,ebx
	mov	dword [ebp-20],esi
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1176
	call	brl_blitz_NullObjectError
_1176:
	mov	edi,dword [ebx+40]
	mov	esi,0
	cmp	esi,dword [edi+20]
	jb	_1179
	call	brl_blitz_ArrayBoundsError
_1179:
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1181
	call	brl_blitz_NullObjectError
_1181:
	push	dword [ebx+16]
	push	dword [edi+esi*4+24]
	call	dword [brl_glmax2d_TGLImageFrame+52]
	add	esp,8
	mov	edx,dword [ebp-20]
	mov	dword [edx+24],eax
	push	_1182
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	jmp	_264
_264:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_ViewportSet:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-16],eax
	mov	eax,dword [ebp+20]
	mov	dword [ebp-20],eax
	movzx	eax,byte [ebp+24]
	mov	eax,eax
	mov	byte [ebp-4],al
	push	ebp
	push	_1208
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1188
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_1189
	push	ebp
	push	_1198
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1190
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-20]
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-8]
	call	glViewport
	add	esp,16
	push	_1191
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	5889
	call	glMatrixMode
	add	esp,4
	push	_1192
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	glPushMatrix
	push	_1193
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	glLoadIdentity
	push	_1194
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,8
	fstp	qword [esp]
	call	brl_graphics_GraphicsHeight
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,8
	fstp	qword [esp]
	call	brl_graphics_GraphicsWidth
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,8
	fstp	qword [esp]
	mov	eax,dword [ebp-8]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,8
	fstp	qword [esp]
	call	gluOrtho2D
	add	esp,32
	push	_1195
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1065353216
	push	-1082130432
	push	1065353216
	call	glScalef
	add	esp,12
	push	_1196
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	call	brl_graphics_GraphicsHeight
	neg	eax
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	push	0
	call	glTranslatef
	add	esp,12
	push	_1197
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	5888
	call	glMatrixMode
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	jmp	_1199
_1189:
	push	ebp
	push	_1206
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1200
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-20]
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-8]
	call	glViewport
	add	esp,16
	push	_1201
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	5889
	call	glMatrixMode
	add	esp,4
	push	_1202
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	glLoadIdentity
	push	_1203
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld1
	sub	esp,8
	fstp	qword [esp]
	fld	qword [_1784]
	sub	esp,8
	fstp	qword [esp]
	mov	eax,dword [ebp-12]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,8
	fstp	qword [esp]
	call	brl_graphics_GraphicsHeight
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,8
	fstp	qword [esp]
	call	brl_graphics_GraphicsWidth
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,8
	fstp	qword [esp]
	mov	eax,dword [ebp-8]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,8
	fstp	qword [esp]
	call	glOrtho
	add	esp,48
	push	_1204
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	5888
	call	glMatrixMode
	add	esp,4
	push	_1205
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	glLoadIdentity
	call	dword [bbOnDebugLeaveScope]
_1199:
	push	_1207
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_271
_271:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_TextureRender_Begin:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	movzx	eax,byte [ebp+12]
	mov	eax,eax
	mov	byte [ebp-4],al
	push	ebp
	push	_1238
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1212
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	brl_graphics_GraphicsHeight
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	fstp	dword [ebp-12]
	push	dword [ebp-8]
	call	brl_max2d_ImageHeight
	add	esp,4
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	fld	dword [ebp-12]
	fdivrp	st1,st0
	fstp	dword [ebp-12]
	push	dword [ebp-12]
	call	brl_graphics_GraphicsWidth
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	fstp	dword [ebp-16]
	push	dword [ebp-8]
	call	brl_max2d_ImageWidth
	add	esp,4
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	fld	dword [ebp-16]
	fdivrp	st1,st0
	fstp	dword [ebp-16]
	push	dword [ebp-16]
	call	brl_max2d_SetScale
	add	esp,8
	push	_1213
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [_bb_tRender_Image],eax
	push	_1214
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_1215
	push	ebp
	push	_1222
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1216
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1218
	call	brl_blitz_NullObjectError
_1218:
	mov	eax,dword [ebx+8]
	mov	dword [_bb_tRender_Width],eax
	push	_1219
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1221
	call	brl_blitz_NullObjectError
_1221:
	mov	eax,dword [ebx+12]
	mov	dword [_bb_tRender_Height],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1223
_1215:
	push	ebp
	push	_1226
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1224
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	brl_graphics_GraphicsWidth
	mov	dword [_bb_tRender_Width],eax
	push	_1225
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	brl_graphics_GraphicsHeight
	mov	dword [_bb_tRender_Height],eax
	call	dword [bbOnDebugLeaveScope]
_1223:
	push	_1227
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [_bb_tRender_DX],1
	jne	_1228
	push	ebp
	push	_1230
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1229
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	dword [_bb_tRender_Height]
	push	dword [_bb_tRender_Width]
	push	0
	push	0
	call	dword [bb_tRender+56]
	add	esp,20
	call	dword [bbOnDebugLeaveScope]
	jmp	_1231
_1228:
	push	ebp
	push	_1233
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1232
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	dword [_bb_tRender_Height]
	push	dword [_bb_tRender_Width]
	push	0
	push	0
	call	dword [bb_tRender+56]
	add	esp,20
	call	dword [bbOnDebugLeaveScope]
_1231:
	push	_1234
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1236
	call	brl_blitz_NullObjectError
_1236:
	push	brl_glmax2d_TGLImageFrame
	push	0
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [_bb_tRender_GLFrame],eax
	push	_1237
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_275
_275:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_Cls:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fldz
	fstp	dword [ebp-8]
	fldz
	fstp	dword [ebp-12]
	fldz
	fstp	dword [ebp-16]
	fldz
	fstp	dword [ebp-20]
	push	ebp
	push	_1251
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1241
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	shr	eax,16
	and	eax,255
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	fstp	dword [ebp-8]
	push	_1243
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	shr	eax,8
	and	eax,255
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	fstp	dword [ebp-12]
	push	_1245
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	and	eax,255
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	fstp	dword [ebp-16]
	push	_1247
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	shr	eax,24
	and	eax,255
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	fstp	dword [ebp-20]
	push	_1249
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	fld	dword [ebp-20]
	fdiv	dword [_1797]
	sub	esp,4
	fstp	dword [esp]
	fld	dword [ebp-16]
	fdiv	dword [_1798]
	sub	esp,4
	fstp	dword [esp]
	fld	dword [ebp-12]
	fdiv	dword [_1799]
	sub	esp,4
	fstp	dword [esp]
	fld	dword [ebp-8]
	fdiv	dword [_1800]
	sub	esp,4
	fstp	dword [esp]
	call	glClearColor
	add	esp,16
	push	_1250
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	16384
	call	glClear
	add	esp,4
	mov	ebx,0
	jmp	_278
_278:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_Pow2Size:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	push	ebp
	push	_1263
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1257
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],1
	push	_1259
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_60
_62:
	push	ebp
	push	_1261
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1260
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	shl	eax,1
	mov	dword [ebp-8],eax
	call	dword [bbOnDebugLeaveScope]
_60:
	mov	eax,dword [ebp-4]
	cmp	dword [ebp-8],eax
	jl	_62
_61:
	push	_1262
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_281
_281:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_TextureRender_End:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	ebp
	push	_1273
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1264
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1065353216
	push	1065353216
	call	brl_max2d_SetScale
	add	esp,8
	push	_1265
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_bb_tRender_GLFrame]
	cmp	ebx,bbNullObject
	jne	_1267
	call	brl_blitz_NullObjectError
_1267:
	push	dword [ebx+32]
	push	3553
	call	glBindTexture
	add	esp,8
	push	_1268
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	dword [_bb_tRender_Height]
	call	dword [bb_tRender+68]
	add	esp,4
	push	eax
	push	dword [_bb_tRender_Width]
	call	dword [bb_tRender+68]
	add	esp,4
	push	eax
	push	0
	push	0
	push	6408
	push	0
	push	3553
	call	glCopyTexImage2D
	add	esp,32
	push	_1269
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	3553
	call	glBindTexture
	add	esp,8
	push	_1270
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	call	brl_graphics_GraphicsHeight
	push	eax
	call	brl_graphics_GraphicsWidth
	push	eax
	push	0
	push	0
	call	dword [bb_tRender+56]
	add	esp,20
	push	_1271
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	1065353216
	push	1065353216
	push	-990248960
	push	-990248960
	push	dword [_bb_tRender_Image]
	call	brl_max2d_DrawImageRect
	add	esp,24
	push	_1272
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_283
_283:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_BackBufferRender_Begin:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	ebp
	push	_1276
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1274
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	call	brl_graphics_GraphicsHeight
	push	eax
	call	brl_graphics_GraphicsWidth
	push	eax
	push	0
	push	0
	call	dword [bb_tRender+56]
	add	esp,20
	push	_1275
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_285
_285:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_BackBufferRender_End:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	ebp
	push	_1279
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1277
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	3553
	call	glBindTexture
	add	esp,8
	push	_1278
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	jmp	_287
_287:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_ColorizedImage:
	push	ebp
	mov	ebp,esp
	sub	esp,40
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	fld	dword [ebp+12]
	fstp	dword [ebp-8]
	fld	dword [ebp+16]
	fstp	dword [ebp-12]
	fld	dword [ebp+20]
	fstp	dword [ebp-16]
	mov	dword [ebp-20],bbNullObject
	mov	dword [ebp-24],0
	mov	dword [ebp-28],0
	mov	dword [ebp-32],0
	mov	dword [ebp-36],0
	push	ebp
	push	_1337
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1280
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	1
	push	0
	push	dword [ebp-4]
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-20],eax
	push	_1282
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1284
	call	brl_blitz_NullObjectError
_1284:
	cmp	dword [ebx+24],6
	je	_1285
	push	ebp
	push	_1289
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1286
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1288
	call	brl_blitz_NullObjectError
_1288:
	push	6
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_1285:
	push	_1290
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	dword [ebp-4]
	call	brl_max2d_UnlockImage
	add	esp,8
	push	_1291
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1293
	call	brl_blitz_NullObjectError
_1293:
	push	0
	push	0
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,12
	mov	dword [ebp-24],eax
	push	_1295
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-24]
	mov	dword [ebp-28],eax
	push	_1297
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],0
	mov	dword [ebp-32],0
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1300
	call	brl_blitz_NullObjectError
_1300:
	mov	esi,dword [ebp-20]
	cmp	esi,bbNullObject
	jne	_1302
	call	brl_blitz_NullObjectError
_1302:
	mov	ebx,dword [ebx+12]
	imul	ebx,dword [esi+16]
	jmp	_1303
_65:
	push	ebp
	push	_1321
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1305
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-24]
	push	dword [eax]
	call	bb_isMonochrome
	add	esp,4
	mov	dword [ebp-36],eax
	push	_1307
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-36],0
	jle	_1308
	push	ebp
	push	_1313
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1309
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-24]
	cmp	dword [eax],0
	je	_1310
	push	ebp
	push	_1312
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1311
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-24]
	mov	eax,dword [ebp-36]
	mov	dword [ebp+-40],eax
	fild	dword [ebp+-40]
	fmul	dword [ebp-16]
	fdiv	dword [_1816]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	eax,dword [ebp-36]
	mov	dword [ebp+-40],eax
	fild	dword [ebp+-40]
	fmul	dword [ebp-12]
	fdiv	dword [_1817]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	eax,dword [ebp-36]
	mov	dword [ebp+-40],eax
	fild	dword [ebp+-40]
	fmul	dword [ebp-8]
	fdiv	dword [_1818]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	eax,dword [ebp-24]
	push	dword [eax]
	call	bb_ARGB_Alpha
	add	esp,4
	push	eax
	call	bb_ARGB_Color
	add	esp,16
	mov	dword [esi],eax
	call	dword [bbOnDebugLeaveScope]
_1310:
	call	dword [bbOnDebugLeaveScope]
_1308:
	push	_1314
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [ebp-24],4
	push	_1315
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-20]
	cmp	esi,bbNullObject
	jne	_1317
	call	brl_blitz_NullObjectError
_1317:
	mov	edx,dword [ebp-28]
	mov	eax,dword [esi+20]
	shr	eax,2
	shl	eax,2
	add	edx,eax
	cmp	dword [ebp-24],edx
	jne	_1318
	push	ebp
	push	_1320
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1319
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-24]
	mov	dword [ebp-28],eax
	call	dword [bbOnDebugLeaveScope]
_1318:
	call	dword [bbOnDebugLeaveScope]
_63:
	add	dword [ebp-32],1
_1303:
	cmp	dword [ebp-32],ebx
	jle	_65
_64:
	push	_1324
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1326
	call	brl_blitz_NullObjectError
_1326:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1329
	call	brl_blitz_NullObjectError
_1329:
	mov	eax,dword [esi+12]
	mov	dword [ebx+16],eax
	push	_1330
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1332
	call	brl_blitz_NullObjectError
_1332:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1335
	call	brl_blitz_NullObjectError
_1335:
	mov	eax,dword [esi+8]
	mov	dword [ebx+12],eax
	push	_1336
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	push	dword [ebp-20]
	call	brl_max2d_LoadImage
	add	esp,8
	mov	ebx,eax
	jmp	_293
_293:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_ColorizePixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,48
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	fld	dword [ebp+16]
	fstp	dword [ebp-12]
	fld	dword [ebp+20]
	fstp	dword [ebp-16]
	fld	dword [ebp+24]
	fstp	dword [ebp-20]
	mov	dword [ebp-24],bbNullObject
	mov	dword [ebp-28],bbNullObject
	mov	dword [ebp-32],0
	mov	dword [ebp-36],0
	mov	dword [ebp-40],0
	mov	dword [ebp-44],0
	mov	eax,ebp
	push	eax
	push	_1402
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1344
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-4],bbNullObject
	je	_1345
	mov	eax,ebp
	push	eax
	push	_1400
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1346
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	1
	push	dword [ebp-8]
	push	dword [ebp-4]
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-24],eax
	push	_1348
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1350
	call	brl_blitz_NullObjectError
_1350:
	cmp	dword [ebx+24],6
	je	_1351
	mov	eax,ebp
	push	eax
	push	_1355
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1352
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1354
	call	brl_blitz_NullObjectError
_1354:
	push	6
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_1351:
	push	_1356
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-24]
	cmp	edi,bbNullObject
	jne	_1358
	call	brl_blitz_NullObjectError
_1358:
	mov	esi,dword [ebp-24]
	cmp	esi,bbNullObject
	jne	_1360
	call	brl_blitz_NullObjectError
_1360:
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1362
	call	brl_blitz_NullObjectError
_1362:
	push	1
	push	dword [ebx+24]
	push	dword [esi+16]
	push	dword [edi+12]
	call	dword [brl_pixmap_TPixmap+80]
	add	esp,16
	mov	dword [ebp-28],eax
	push	_1364
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1366
	call	brl_blitz_NullObjectError
_1366:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	mov	dword [ebp-28],eax
	push	_1367
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_1369
	call	brl_blitz_NullObjectError
_1369:
	push	0
	push	0
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,12
	mov	dword [ebp-32],eax
	push	_1371
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	mov	dword [ebp-36],eax
	push	_1373
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-40],0
	mov	dword [ebp-40],0
	mov	esi,dword [ebp-28]
	cmp	esi,bbNullObject
	jne	_1376
	call	brl_blitz_NullObjectError
_1376:
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_1378
	call	brl_blitz_NullObjectError
_1378:
	mov	esi,dword [esi+12]
	imul	esi,dword [ebx+16]
	jmp	_1379
_68:
	mov	eax,ebp
	push	eax
	push	_1396
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1381
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	push	dword [eax]
	call	bb_isMonochrome
	add	esp,4
	mov	dword [ebp-44],eax
	push	_1383
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-44]
	cmp	eax,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_1384
	mov	eax,dword [ebp-32]
	mov	eax,dword [eax]
	cmp	eax,0
	setne	al
	movzx	eax,al
_1384:
	cmp	eax,0
	je	_1386
	mov	eax,ebp
	push	eax
	push	_1388
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1387
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	mov	eax,dword [ebp-44]
	mov	dword [ebp+-48],eax
	fild	dword [ebp+-48]
	fmul	dword [ebp-20]
	fdiv	dword [_1836]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	eax,dword [ebp-44]
	mov	dword [ebp+-48],eax
	fild	dword [ebp+-48]
	fmul	dword [ebp-16]
	fdiv	dword [_1837]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	eax,dword [ebp-44]
	mov	dword [ebp+-48],eax
	fild	dword [ebp+-48]
	fmul	dword [ebp-12]
	fdiv	dword [_1838]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	eax,dword [ebp-32]
	push	dword [eax]
	call	bb_ARGB_Alpha
	add	esp,4
	push	eax
	call	bb_ARGB_Color
	add	esp,16
	mov	dword [ebx],eax
	call	dword [bbOnDebugLeaveScope]
_1386:
	push	_1389
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [ebp-32],4
	push	_1390
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_1392
	call	brl_blitz_NullObjectError
_1392:
	mov	edx,dword [ebp-36]
	mov	eax,dword [ebx+20]
	shr	eax,2
	shl	eax,2
	add	edx,eax
	cmp	dword [ebp-32],edx
	jne	_1393
	mov	eax,ebp
	push	eax
	push	_1395
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1394
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	mov	dword [ebp-36],eax
	call	dword [bbOnDebugLeaveScope]
_1393:
	call	dword [bbOnDebugLeaveScope]
_66:
	add	dword [ebp-40],1
_1379:
	cmp	dword [ebp-40],esi
	jle	_68
_67:
	push	_1398
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	push	dword [ebp-4]
	call	brl_max2d_UnlockImage
	add	esp,8
	push	_1399
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	call	dword [bbOnDebugLeaveScope]
	jmp	_300
_1345:
	mov	ebx,bbNullObject
	jmp	_300
_300:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_ColorizeImage:
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
	mov	dword [ebp-20],bbNullObject
	push	ebp
	push	_1409
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1405
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	1
	push	0
	mov	eax,dword [ebp-16]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-12]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-8]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	push	-1
	push	dword [ebp-4]
	call	brl_max2d_LoadImage
	add	esp,8
	push	eax
	call	bb_ColorizedImage
	add	esp,16
	push	eax
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-20],eax
	push	_1407
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	mov	eax,dword [ebp-16]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-12]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp-8]
	mov	dword [ebp+-24],eax
	fild	dword [ebp+-24]
	sub	esp,4
	fstp	dword [esp]
	push	-1
	push	dword [ebp-4]
	call	brl_max2d_LoadImage
	add	esp,8
	push	eax
	call	bb_ColorizedImage
	add	esp,16
	push	eax
	call	brl_max2d_UnlockImage
	add	esp,8
	push	_1408
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	jmp	_306
_306:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_CopyImage:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	eax,ebp
	push	eax
	push	_1483
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1416
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-4],bbNullObject
	jne	_1417
	mov	eax,ebp
	push	eax
	push	_1419
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1418
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_309
_1417:
	push	_1420
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	brl_max2d_TImage
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	push	_1422
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	44
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	call	bbMemCopy
	add	esp,12
	push	_1423
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1425
	call	brl_blitz_NullObjectError
_1425:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1429
	call	brl_blitz_NullObjectError
_1429:
	mov	eax,dword [esi+40]
	push	dword [eax+20]
	push	_1427
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebx+40],eax
	push	_1430
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1432
	call	brl_blitz_NullObjectError
_1432:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1436
	call	brl_blitz_NullObjectError
_1436:
	mov	eax,dword [esi+44]
	push	dword [eax+20]
	push	_1434
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebx+44],eax
	push	_1437
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1439
	call	brl_blitz_NullObjectError
_1439:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1443
	call	brl_blitz_NullObjectError
_1443:
	mov	eax,dword [esi+48]
	push	dword [eax+20]
	push	_1441
	call	bbArrayNew1D
	add	esp,8
	mov	dword [ebx+48],eax
	push	_1444
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	mov	dword [ebp-12],0
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1447
	call	brl_blitz_NullObjectError
_1447:
	mov	eax,dword [ebx+40]
	mov	eax,dword [eax+20]
	sub	eax,1
	mov	dword [ebp-28],eax
	jmp	_1448
_71:
	mov	eax,ebp
	push	eax
	push	_1462
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1450
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1452
	call	brl_blitz_NullObjectError
_1452:
	mov	ebx,dword [ebx+40]
	mov	esi,dword [ebp-12]
	cmp	esi,dword [ebx+20]
	jb	_1455
	call	brl_blitz_ArrayBoundsError
_1455:
	shl	esi,2
	add	ebx,esi
	mov	edi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1458
	call	brl_blitz_NullObjectError
_1458:
	mov	esi,dword [ebx+40]
	mov	ebx,dword [ebp-12]
	cmp	ebx,dword [esi+20]
	jb	_1461
	call	brl_blitz_ArrayBoundsError
_1461:
	push	dword [esi+ebx*4+24]
	call	brl_pixmap_CopyPixmap
	add	esp,4
	mov	dword [edi+24],eax
	call	dword [bbOnDebugLeaveScope]
_69:
	add	dword [ebp-12],1
_1448:
	mov	eax,dword [ebp-28]
	cmp	dword [ebp-12],eax
	jle	_71
_70:
	push	_1463
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],0
	mov	dword [ebp-16],0
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1466
	call	brl_blitz_NullObjectError
_1466:
	mov	eax,dword [ebx+44]
	mov	ebx,dword [eax+20]
	sub	ebx,1
	jmp	_1467
_74:
	mov	eax,ebp
	push	eax
	push	_1472
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1469
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_1471
	call	brl_blitz_NullObjectError
_1471:
	push	dword [ebp-16]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+52]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_72:
	add	dword [ebp-16],1
_1467:
	cmp	dword [ebp-16],ebx
	jle	_74
_73:
	push	_1473
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1475
	call	brl_blitz_NullObjectError
_1475:
	mov	eax,dword [ebx+48]
	mov	dword [ebp-20],eax
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1478
	call	brl_blitz_NullObjectError
_1478:
	mov	eax,dword [ebx+48]
	mov	dword [ebp-24],eax
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1481
	call	brl_blitz_NullObjectError
_1481:
	mov	eax,dword [ebx+48]
	push	dword [eax+16]
	mov	eax,dword [ebp-24]
	lea	eax,byte [eax+24]
	push	eax
	mov	eax,dword [ebp-20]
	lea	eax,byte [eax+24]
	push	eax
	call	bbMemCopy
	add	esp,12
	push	_1482
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_309
_309:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_ColorizeTImage:
	push	ebp
	mov	ebp,esp
	sub	esp,68
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
	mov	eax,dword [ebp+24]
	mov	dword [ebp-20],eax
	mov	eax,dword [ebp+28]
	mov	dword [ebp-24],eax
	mov	eax,dword [ebp+32]
	mov	dword [ebp-28],eax
	mov	eax,dword [ebp+36]
	mov	dword [ebp-32],eax
	mov	eax,dword [ebp+40]
	mov	dword [ebp-36],eax
	mov	eax,dword [ebp+44]
	mov	dword [ebp-40],eax
	mov	dword [ebp-44],0
	mov	dword [ebp-48],bbNullObject
	mov	dword [ebp-52],bbNullObject
	mov	dword [ebp-56],0
	mov	dword [ebp-60],0
	mov	dword [ebp-64],0
	mov	dword [ebp-68],0
	mov	eax,ebp
	push	eax
	push	_1557
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1487
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-4],bbNullObject
	je	_1488
	mov	eax,ebp
	push	eax
	push	_1555
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1489
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [ebp-44],eax
	push	_1491
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	mov	dword [ebp-8],eax
	push	_1492
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-44]
	mov	dword [ebp-16],eax
	push	_1493
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	1
	push	0
	push	dword [ebp-4]
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-48],eax
	push	_1495
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-48]
	cmp	ebx,bbNullObject
	jne	_1497
	call	brl_blitz_NullObjectError
_1497:
	cmp	dword [ebx+24],6
	je	_1498
	mov	eax,ebp
	push	eax
	push	_1502
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1499
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-48]
	cmp	ebx,bbNullObject
	jne	_1501
	call	brl_blitz_NullObjectError
_1501:
	push	6
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_1498:
	push	_1503
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_1505
	call	brl_blitz_NullObjectError
_1505:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1507
	call	brl_blitz_NullObjectError
_1507:
	mov	ebx,dword [ebp-48]
	cmp	ebx,bbNullObject
	jne	_1509
	call	brl_blitz_NullObjectError
_1509:
	push	1
	push	dword [ebx+24]
	push	dword [esi+12]
	push	dword [edi+8]
	call	dword [brl_pixmap_TPixmap+80]
	add	esp,16
	mov	dword [ebp-52],eax
	push	_1511
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-48]
	cmp	ebx,bbNullObject
	jne	_1513
	call	brl_blitz_NullObjectError
_1513:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	mov	dword [ebp-52],eax
	push	_1514
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	dword [ebp-4]
	call	brl_max2d_UnlockImage
	add	esp,8
	push	_1515
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_1517
	call	brl_blitz_NullObjectError
_1517:
	push	0
	push	0
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,12
	mov	dword [ebp-56],eax
	push	_1519
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-56]
	mov	dword [ebp-60],eax
	push	_1521
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-64],0
	mov	dword [ebp-64],0
	mov	esi,dword [ebp-52]
	cmp	esi,bbNullObject
	jne	_1524
	call	brl_blitz_NullObjectError
_1524:
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_1526
	call	brl_blitz_NullObjectError
_1526:
	mov	eax,dword [esi+12]
	imul	eax,dword [ebx+16]
	mov	esi,eax
	jmp	_1527
_77:
	mov	eax,ebp
	push	eax
	push	_1544
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1529
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-56]
	push	dword [eax]
	call	bb_isMonochrome
	add	esp,4
	mov	dword [ebp-68],eax
	push	_1531
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-68]
	cmp	eax,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_1532
	mov	eax,dword [ebp-56]
	mov	eax,dword [eax]
	cmp	eax,0
	setne	al
	movzx	eax,al
_1532:
	cmp	eax,0
	je	_1534
	mov	eax,ebp
	push	eax
	push	_1536
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1535
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	mov	ecx,255
	mov	eax,dword [ebp-68]
	imul	eax,dword [ebp-16]
	cdq
	idiv	ecx
	push	eax
	mov	ecx,255
	mov	eax,dword [ebp-68]
	imul	eax,dword [ebp-12]
	cdq
	idiv	ecx
	push	eax
	mov	ecx,255
	mov	eax,dword [ebp-68]
	imul	eax,dword [ebp-8]
	cdq
	idiv	ecx
	push	eax
	mov	eax,dword [ebp-56]
	push	dword [eax]
	call	bb_ARGB_Alpha
	add	esp,4
	push	eax
	call	bb_ARGB_Color
	add	esp,16
	mov	dword [ebx],eax
	call	dword [bbOnDebugLeaveScope]
_1534:
	push	_1537
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [ebp-56],4
	push	_1538
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_1540
	call	brl_blitz_NullObjectError
_1540:
	mov	edx,dword [ebp-60]
	mov	eax,dword [ebx+20]
	shr	eax,2
	shl	eax,2
	add	edx,eax
	cmp	dword [ebp-56],edx
	jne	_1541
	mov	eax,ebp
	push	eax
	push	_1543
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1542
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-56]
	mov	dword [ebp-60],eax
	call	dword [bbOnDebugLeaveScope]
_1541:
	call	dword [bbOnDebugLeaveScope]
_75:
	add	dword [ebp-64],1
_1527:
	cmp	dword [ebp-64],esi
	jle	_77
_76:
	push	_1545
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-48],bbNullObject
	push	_1546
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-20]
	cmp	eax,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_1547
	mov	eax,dword [ebp-32]
	cmp	eax,0
	setg	al
	movzx	eax,al
_1547:
	cmp	eax,0
	je	_1549
	mov	eax,dword [ebp-40]
_1549:
	cmp	eax,0
	je	_1551
	mov	eax,ebp
	push	eax
	push	_1553
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1552
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-36]
	push	dword [ebp-32]
	push	dword [ebp-28]
	push	dword [ebp-24]
	push	dword [ebp-20]
	push	dword [ebp-52]
	call	brl_max2d_LoadAnimImage
	add	esp,24
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_321
_1551:
	push	_1554
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	-1
	push	dword [ebp-52]
	call	brl_max2d_LoadImage
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_321
_1488:
	mov	ebx,bbNullObject
	jmp	_321
_321:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_442:
	dd	0
_334:
	db	"basefunctions_image",0
_335:
	db	"APPEND_STATUS_CREATE",0
_106:
	db	"i",0
	align	4
_336:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	48
_337:
	db	"APPEND_STATUS_CREATEAFTER",0
	align	4
_338:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	49
_339:
	db	"APPEND_STATUS_ADDINZIP",0
	align	4
_340:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	50
_341:
	db	"Z_DEFLATED",0
	align	4
_342:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	56
_343:
	db	"Z_NO_COMPRESSION",0
_344:
	db	"Z_BEST_SPEED",0
_345:
	db	"Z_BEST_COMPRESSION",0
	align	4
_346:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	57
_347:
	db	"Z_DEFAULT_COMPRESSION",0
	align	4
_348:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,49
_349:
	db	"UNZ_CASE_CHECK",0
_350:
	db	"UNZ_NO_CASE_CHECK",0
_351:
	db	"UNZ_OK",0
_352:
	db	"UNZ_END_OF_LIST_OF_FILE",0
	align	4
_353:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,48
_354:
	db	"UNZ_EOF",0
_355:
	db	"UNZ_PARAMERROR",0
	align	4
_356:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,50
_357:
	db	"UNZ_BADZIPFILE",0
	align	4
_358:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,51
_359:
	db	"UNZ_INTERNALERROR",0
	align	4
_360:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,52
_361:
	db	"UNZ_CRCERROR",0
	align	4
_362:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,53
_363:
	db	"ZLIB_FILEFUNC_SEEK_CUR",0
_364:
	db	"ZLIB_FILEFUNC_SEEK_END",0
_365:
	db	"ZLIB_FILEFUNC_SEEK_SET",0
_366:
	db	"Z_OK",0
_367:
	db	"Z_STREAM_END",0
_368:
	db	"Z_NEED_DICT",0
_369:
	db	"Z_ERRNO",0
_370:
	db	"Z_STREAM_ERROR",0
	align	4
_371:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,50
_372:
	db	"Z_DATA_ERROR",0
	align	4
_373:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,51
_374:
	db	"Z_MEM_ERROR",0
	align	4
_375:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,52
_376:
	db	"Z_BUF_ERROR",0
	align	4
_377:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,53
_378:
	db	"Z_VERSION_ERROR",0
	align	4
_379:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,54
_380:
	db	"ZIP_INFO_IN_DATA_DESCRIPTOR",0
_381:
	db	"s",0
_382:
	db	"KEY_STATE_NORMAL",0
_383:
	db	"KEY_STATE_HIT",0
_384:
	db	"KEY_STATE_DOWN",0
_385:
	db	"KEY_STATE_UP",0
	align	4
_386:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	51
_387:
	db	"KEYWRAP_ALLOW_HIT",0
_388:
	db	"KEYWRAP_ALLOW_HOLD",0
_389:
	db	"KEYWRAP_ALLOW_BOTH",0
_390:
	db	"MOUSEMANAGER",0
_391:
	db	":TMouseManager",0
_392:
	db	"KEYMANAGER",0
_393:
	db	":TKeyManager",0
_394:
	db	"KEYWRAPPER",0
_395:
	db	":TKeyWrapper",0
_396:
	db	"AS_CHILD",0
_397:
	db	"AS_SIBLING",0
_398:
	db	"FORMAT_XML",0
_399:
	db	"FORMAT_BINARY",0
_400:
	db	"SORTBY_NODE_NAME",0
_401:
	db	"SORTBY_NODE_VALUE",0
_402:
	db	"SORTBY_ATTR_NAME",0
_403:
	db	"SORTBY_ATTR_VALUE",0
	align	4
_404:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	52
_405:
	db	"LoadSaveFile",0
_406:
	db	":TSaveFile",0
_407:
	db	"DEBUG_ALL",0
_408:
	db	"b",0
	align	4
_409:
	dd	bbStringClass
	dd	2147483646
	dd	3
	dw	49,50,56
_410:
	db	"DEBUG_SAVELOAD",0
	align	4
_411:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	54,52
_412:
	db	"DEBUG_NO",0
_413:
	db	"DEBUG_NETWORK",0
	align	4
_414:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	51,50
_415:
	db	"DEBUG_XML",0
	align	4
_416:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	49,54
_417:
	db	"DEBUG_LUA",0
_418:
	db	"DEBUG_LOADING",0
_419:
	db	"DEBUG_UPDATES",0
_420:
	db	"DEBUG_NEWS",0
_421:
	db	"DEBUG_START",0
_422:
	db	"DEBUG_IMAGES",0
	align	4
_423:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	53
_424:
	db	"LastSeekPos",0
_425:
	db	"functions",0
_426:
	db	":TFunctions",0
_427:
	db	"MINFRAGSIZE",0
_428:
	db	"MAXFRAGSIZE",0
	align	4
_429:
	dd	bbStringClass
	dd	2147483646
	dd	3
	dw	50,53,54
_430:
	db	"DDERR_INVALIDSURFACETYPE",0
	align	4
_431:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,48,48,53,53,51,50,48,56,48
_432:
	db	"DDERR_INVALIDPARAMS",0
	align	4
_433:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,49,52,55,48,50,52,56,48,57
_434:
	db	"DDERR_INVALIDOBJECT",0
	align	4
_435:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,48,48,53,53,51,50,53,52,50
_436:
	db	"DDERR_NOTFOUND",0
	align	4
_437:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,48,48,53,53,51,50,52,49,55
_438:
	db	"DDERR_SURFACELOST",0
	align	4
_439:
	dd	bbStringClass
	dd	2147483646
	dd	11
	dw	45,50,48,48,53,53,51,50,50,50,50
_440:
	db	"tRenderERROR",0
_441:
	db	"$",0
	align	4
bb_tRenderERROR:
	dd	bbEmptyString
	align	4
_333:
	dd	1
	dd	_334
	dd	1
	dd	_335
	dd	_106
	dd	_336
	dd	1
	dd	_337
	dd	_106
	dd	_338
	dd	1
	dd	_339
	dd	_106
	dd	_340
	dd	1
	dd	_341
	dd	_106
	dd	_342
	dd	1
	dd	_343
	dd	_106
	dd	_336
	dd	1
	dd	_344
	dd	_106
	dd	_338
	dd	1
	dd	_345
	dd	_106
	dd	_346
	dd	1
	dd	_347
	dd	_106
	dd	_348
	dd	1
	dd	_349
	dd	_106
	dd	_338
	dd	1
	dd	_350
	dd	_106
	dd	_340
	dd	1
	dd	_351
	dd	_106
	dd	_336
	dd	1
	dd	_352
	dd	_106
	dd	_353
	dd	1
	dd	_354
	dd	_106
	dd	_336
	dd	1
	dd	_355
	dd	_106
	dd	_356
	dd	1
	dd	_357
	dd	_106
	dd	_358
	dd	1
	dd	_359
	dd	_106
	dd	_360
	dd	1
	dd	_361
	dd	_106
	dd	_362
	dd	1
	dd	_363
	dd	_106
	dd	_338
	dd	1
	dd	_364
	dd	_106
	dd	_340
	dd	1
	dd	_365
	dd	_106
	dd	_336
	dd	1
	dd	_366
	dd	_106
	dd	_336
	dd	1
	dd	_367
	dd	_106
	dd	_338
	dd	1
	dd	_368
	dd	_106
	dd	_340
	dd	1
	dd	_369
	dd	_106
	dd	_348
	dd	1
	dd	_370
	dd	_106
	dd	_371
	dd	1
	dd	_372
	dd	_106
	dd	_373
	dd	1
	dd	_374
	dd	_106
	dd	_375
	dd	1
	dd	_376
	dd	_106
	dd	_377
	dd	1
	dd	_378
	dd	_106
	dd	_379
	dd	1
	dd	_380
	dd	_381
	dd	_342
	dd	1
	dd	_382
	dd	_106
	dd	_336
	dd	1
	dd	_383
	dd	_106
	dd	_338
	dd	1
	dd	_384
	dd	_106
	dd	_340
	dd	1
	dd	_385
	dd	_106
	dd	_386
	dd	1
	dd	_387
	dd	_106
	dd	_338
	dd	1
	dd	_388
	dd	_106
	dd	_340
	dd	1
	dd	_389
	dd	_106
	dd	_386
	dd	4
	dd	_390
	dd	_391
	dd	bb_MOUSEMANAGER
	dd	4
	dd	_392
	dd	_393
	dd	bb_KEYMANAGER
	dd	4
	dd	_394
	dd	_395
	dd	bb_KEYWRAPPER
	dd	1
	dd	_396
	dd	_106
	dd	_338
	dd	1
	dd	_397
	dd	_106
	dd	_340
	dd	1
	dd	_398
	dd	_106
	dd	_338
	dd	1
	dd	_399
	dd	_106
	dd	_340
	dd	1
	dd	_400
	dd	_106
	dd	_338
	dd	1
	dd	_401
	dd	_106
	dd	_340
	dd	1
	dd	_402
	dd	_106
	dd	_386
	dd	1
	dd	_403
	dd	_106
	dd	_404
	dd	4
	dd	_405
	dd	_406
	dd	bb_LoadSaveFile
	dd	1
	dd	_407
	dd	_408
	dd	_409
	dd	1
	dd	_410
	dd	_408
	dd	_411
	dd	1
	dd	_412
	dd	_408
	dd	_336
	dd	1
	dd	_413
	dd	_408
	dd	_414
	dd	1
	dd	_415
	dd	_408
	dd	_416
	dd	1
	dd	_417
	dd	_408
	dd	_342
	dd	1
	dd	_418
	dd	_408
	dd	_404
	dd	1
	dd	_419
	dd	_408
	dd	_340
	dd	1
	dd	_420
	dd	_408
	dd	_338
	dd	1
	dd	_421
	dd	_408
	dd	_386
	dd	1
	dd	_422
	dd	_408
	dd	_423
	dd	4
	dd	_424
	dd	_106
	dd	bb_LastSeekPos
	dd	4
	dd	_425
	dd	_426
	dd	bb_functions
	dd	1
	dd	_427
	dd	_106
	dd	_411
	dd	1
	dd	_428
	dd	_106
	dd	_429
	dd	1
	dd	_430
	dd	_106
	dd	_431
	dd	1
	dd	_432
	dd	_106
	dd	_433
	dd	1
	dd	_434
	dd	_106
	dd	_435
	dd	1
	dd	_436
	dd	_106
	dd	_437
	dd	1
	dd	_438
	dd	_106
	dd	_439
	dd	4
	dd	_440
	dd	_441
	dd	bb_tRenderERROR
	dd	0
_79:
	db	"ImageFragment",0
_80:
	db	"img",0
_81:
	db	":brl.max2d.TImage",0
_82:
	db	"x",0
_83:
	db	"f",0
_84:
	db	"y",0
_85:
	db	"w",0
_86:
	db	"h",0
_87:
	db	"New",0
_88:
	db	"()i",0
_89:
	db	"create",0
_90:
	db	"(:brl.pixmap.TPixmap,f,f,f,f):ImageFragment",0
_91:
	db	"render",0
_92:
	db	"(f,f,f)i",0
_93:
	db	"renderInViewPort",0
_94:
	db	"(f,f,f,f,f,f)i",0
	align	4
_78:
	dd	2
	dd	_79
	dd	3
	dd	_80
	dd	_81
	dd	8
	dd	3
	dd	_82
	dd	_83
	dd	12
	dd	3
	dd	_84
	dd	_83
	dd	16
	dd	3
	dd	_85
	dd	_83
	dd	20
	dd	3
	dd	_86
	dd	_83
	dd	24
	dd	6
	dd	_87
	dd	_88
	dd	16
	dd	7
	dd	_89
	dd	_90
	dd	48
	dd	6
	dd	_91
	dd	_92
	dd	52
	dd	6
	dd	_93
	dd	_94
	dd	56
	dd	0
	align	4
bb_ImageFragment:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_78
	dd	28
	dd	_bb_ImageFragment_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_ImageFragment_create
	dd	_bb_ImageFragment_render
	dd	_bb_ImageFragment_renderInViewPort
_96:
	db	"TBigImage",0
_97:
	db	"pixmap",0
_98:
	db	":brl.pixmap.TPixmap",0
_99:
	db	"px",0
_100:
	db	"py",0
_101:
	db	"fragments",0
_102:
	db	":brl.linkedlist.TList",0
_103:
	db	"width",0
_104:
	db	"height",0
_105:
	db	"PixFormat",0
_107:
	db	"CreateFromImage",0
_108:
	db	"(:brl.max2d.TImage):TBigImage",0
_109:
	db	"CreateFromPixmap",0
_110:
	db	"(:brl.pixmap.TPixmap):TBigImage",0
_111:
	db	"RestorePixmap",0
_112:
	db	"():brl.pixmap.TPixmap",0
_113:
	db	"Load",0
	align	4
_95:
	dd	2
	dd	_96
	dd	3
	dd	_97
	dd	_98
	dd	8
	dd	3
	dd	_99
	dd	_83
	dd	12
	dd	3
	dd	_100
	dd	_83
	dd	16
	dd	3
	dd	_101
	dd	_102
	dd	20
	dd	3
	dd	_103
	dd	_83
	dd	24
	dd	3
	dd	_104
	dd	_83
	dd	28
	dd	3
	dd	_105
	dd	_106
	dd	32
	dd	3
	dd	_82
	dd	_83
	dd	36
	dd	3
	dd	_84
	dd	_83
	dd	40
	dd	6
	dd	_87
	dd	_88
	dd	16
	dd	7
	dd	_107
	dd	_108
	dd	48
	dd	7
	dd	_109
	dd	_110
	dd	52
	dd	7
	dd	_89
	dd	_110
	dd	56
	dd	6
	dd	_111
	dd	_112
	dd	60
	dd	6
	dd	_113
	dd	_88
	dd	64
	dd	6
	dd	_91
	dd	_92
	dd	68
	dd	6
	dd	_93
	dd	_94
	dd	72
	dd	0
	align	4
bb_TBigImage:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_95
	dd	44
	dd	_bb_TBigImage_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TBigImage_CreateFromImage
	dd	_bb_TBigImage_CreateFromPixmap
	dd	_bb_TBigImage_create
	dd	_bb_TBigImage_RestorePixmap
	dd	_bb_TBigImage_Load
	dd	_bb_TBigImage_render
	dd	_bb_TBigImage_renderInViewPort
_324:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_image.bmx",0
	align	4
_323:
	dd	_324
	dd	397
	dd	2
	align	4
_bb_tRender_GLFrame:
	dd	bbNullObject
	align	4
_325:
	dd	_324
	dd	398
	dd	2
	align	4
_bb_tRender_DX:
	dd	0
	align	4
_326:
	dd	_324
	dd	399
	dd	2
	align	4
_327:
	dd	0
	align	4
_bb_tRender_Image:
	dd	bbNullObject
	align	4
_329:
	dd	_324
	dd	400
	dd	2
	align	4
_bb_tRender_Width:
	dd	0
	align	4
_330:
	dd	_324
	dd	401
	dd	2
	align	4
_bb_tRender_Height:
	dd	0
	align	4
_331:
	dd	_324
	dd	402
	dd	2
	align	4
_bb_tRender_o_r:
	dd	0
	align	4
_bb_tRender_o_g:
	dd	0
	align	4
_bb_tRender_o_b:
	dd	0
_115:
	db	"tRender",0
_116:
	db	"Initialise",0
_117:
	db	"Create",0
_118:
	db	"(i,i,i):brl.max2d.TImage",0
_119:
	db	"ViewportSet",0
_120:
	db	"(i,i,i,i,b)i",0
_121:
	db	"TextureRender_Begin",0
_122:
	db	"(:brl.max2d.TImage,b)i",0
_123:
	db	"Cls",0
_124:
	db	"(i)i",0
_125:
	db	"Pow2Size",0
_126:
	db	"TextureRender_End",0
_127:
	db	"BackBufferRender_Begin",0
_128:
	db	"BackBufferRender_End",0
	align	4
_114:
	dd	2
	dd	_115
	dd	6
	dd	_87
	dd	_88
	dd	16
	dd	7
	dd	_116
	dd	_88
	dd	48
	dd	7
	dd	_117
	dd	_118
	dd	52
	dd	7
	dd	_119
	dd	_120
	dd	56
	dd	7
	dd	_121
	dd	_122
	dd	60
	dd	7
	dd	_123
	dd	_124
	dd	64
	dd	7
	dd	_125
	dd	_124
	dd	68
	dd	7
	dd	_126
	dd	_88
	dd	72
	dd	7
	dd	_127
	dd	_88
	dd	76
	dd	7
	dd	_128
	dd	_88
	dd	80
	dd	0
	align	4
bb_tRender:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_114
	dd	8
	dd	_bb_tRender_New
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_tRender_Initialise
	dd	_bb_tRender_Create
	dd	_bb_tRender_ViewportSet
	dd	_bb_tRender_TextureRender_Begin
	dd	_bb_tRender_Cls
	dd	_bb_tRender_Pow2Size
	dd	_bb_tRender_TextureRender_End
	dd	_bb_tRender_BackBufferRender_Begin
	dd	_bb_tRender_BackBufferRender_End
	align	4
_332:
	dd	_324
	dd	364
	dd	1
_446:
	db	"DrawImageArea",0
_447:
	db	"image",0
_448:
	db	"rx",0
_449:
	db	"ry",0
_450:
	db	"rw",0
_451:
	db	"rh",0
_452:
	db	"theframe",0
	align	4
_445:
	dd	1
	dd	_446
	dd	2
	dd	_447
	dd	_81
	dd	-4
	dd	2
	dd	_82
	dd	_83
	dd	-8
	dd	2
	dd	_84
	dd	_83
	dd	-12
	dd	2
	dd	_448
	dd	_83
	dd	-16
	dd	2
	dd	_449
	dd	_83
	dd	-20
	dd	2
	dd	_450
	dd	_83
	dd	-24
	dd	2
	dd	_451
	dd	_83
	dd	-28
	dd	2
	dd	_452
	dd	_106
	dd	-32
	dd	0
	align	4
_444:
	dd	_324
	dd	17
	dd	2
_461:
	db	"DrawImageAreaPow2Size",0
_462:
	db	"n",0
	align	4
_460:
	dd	1
	dd	_461
	dd	2
	dd	_462
	dd	_106
	dd	-4
	dd	0
	align	4
_453:
	dd	_324
	dd	21
	dd	2
	align	4
_454:
	dd	_324
	dd	22
	dd	2
	align	4
_455:
	dd	_324
	dd	23
	dd	2
	align	4
_456:
	dd	_324
	dd	24
	dd	2
	align	4
_457:
	dd	_324
	dd	25
	dd	2
	align	4
_458:
	dd	_324
	dd	26
	dd	2
	align	4
_459:
	dd	_324
	dd	27
	dd	2
_506:
	db	"ClipImageToViewport",0
_507:
	db	"imagex",0
_508:
	db	"imagey",0
_509:
	db	"ViewportX",0
_510:
	db	"ViewPortY",0
_511:
	db	"ViewPortW",0
_512:
	db	"ViewPortH",0
_513:
	db	"offsetx",0
_514:
	db	"offsety",0
	align	4
_505:
	dd	1
	dd	_506
	dd	2
	dd	_447
	dd	_81
	dd	-4
	dd	2
	dd	_507
	dd	_83
	dd	-8
	dd	2
	dd	_508
	dd	_83
	dd	-12
	dd	2
	dd	_509
	dd	_83
	dd	-16
	dd	2
	dd	_510
	dd	_83
	dd	-20
	dd	2
	dd	_511
	dd	_83
	dd	-24
	dd	2
	dd	_512
	dd	_83
	dd	-28
	dd	2
	dd	_513
	dd	_83
	dd	-32
	dd	2
	dd	_514
	dd	_83
	dd	-36
	dd	2
	dd	_452
	dd	_106
	dd	-40
	dd	2
	dd	_85
	dd	_106
	dd	-44
	dd	2
	dd	_86
	dd	_106
	dd	-48
	dd	0
	align	4
_463:
	dd	_324
	dd	36
	dd	2
	align	4
_465:
	dd	_324
	dd	37
	dd	2
	align	4
_467:
	dd	_324
	dd	39
	dd	2
_501:
	db	"startx",0
_502:
	db	"starty",0
_503:
	db	"endx",0
_504:
	db	"endy",0
	align	4
_500:
	dd	3
	dd	0
	dd	2
	dd	_501
	dd	_83
	dd	-52
	dd	2
	dd	_502
	dd	_83
	dd	-56
	dd	2
	dd	_503
	dd	_83
	dd	-60
	dd	2
	dd	_504
	dd	_83
	dd	-64
	dd	0
	align	4
_475:
	dd	_324
	dd	42
	dd	3
	align	4
_477:
	dd	_324
	dd	43
	dd	3
	align	4
_479:
	dd	_324
	dd	44
	dd	3
	align	4
_482:
	dd	3
	dd	0
	dd	0
	align	4
_481:
	dd	_324
	dd	44
	dd	20
	align	4
_483:
	dd	_324
	dd	45
	dd	3
	align	4
_486:
	dd	3
	dd	0
	dd	0
	align	4
_485:
	dd	_324
	dd	45
	dd	20
	align	4
_487:
	dd	_324
	dd	47
	dd	3
	align	4
_489:
	dd	_324
	dd	48
	dd	3
	align	4
_491:
	dd	_324
	dd	49
	dd	3
	align	4
_494:
	dd	3
	dd	0
	dd	0
	align	4
_493:
	dd	_324
	dd	49
	dd	18
	align	4
_495:
	dd	_324
	dd	50
	dd	3
	align	4
_498:
	dd	3
	dd	0
	dd	0
	align	4
_497:
	dd	_324
	dd	50
	dd	18
	align	4
_499:
	dd	_324
	dd	51
	dd	3
_531:
	db	"DrawImageInViewPort",0
_532:
	db	"_image",0
_533:
	db	"_x",0
_534:
	db	"_yItStandsOn",0
_535:
	db	"align",0
_536:
	db	"Frame",0
	align	4
_530:
	dd	1
	dd	_531
	dd	2
	dd	_532
	dd	_81
	dd	-8
	dd	2
	dd	_533
	dd	_106
	dd	-12
	dd	2
	dd	_534
	dd	_106
	dd	-16
	dd	2
	dd	_535
	dd	_408
	dd	-4
	dd	2
	dd	_536
	dd	_106
	dd	-20
	dd	0
	align	4
_515:
	dd	_324
	dd	57
	dd	5
	align	4
_529:
	dd	3
	dd	0
	dd	0
	align	4
_519:
	dd	_324
	dd	58
	dd	4
	align	4
_522:
	dd	3
	dd	0
	dd	0
	align	4
_521:
	dd	_324
	dd	59
	dd	6
	align	4
_528:
	dd	3
	dd	0
	dd	0
	align	4
_524:
	dd	_324
	dd	60
	dd	4
	align	4
_527:
	dd	3
	dd	0
	dd	0
	align	4
_526:
	dd	_324
	dd	61
	dd	6
_637:
	db	"DrawOnPixmap",0
_638:
	db	"framenr",0
_639:
	db	"Pixmap",0
_640:
	db	"alpha",0
_641:
	db	"light",0
_642:
	db	"multiply",0
_643:
	db	"TempPix",0
	align	4
_636:
	dd	1
	dd	_637
	dd	2
	dd	_447
	dd	_81
	dd	-4
	dd	2
	dd	_638
	dd	_106
	dd	-8
	dd	2
	dd	_639
	dd	_98
	dd	-12
	dd	2
	dd	_82
	dd	_106
	dd	-16
	dd	2
	dd	_84
	dd	_106
	dd	-20
	dd	2
	dd	_640
	dd	_83
	dd	-24
	dd	2
	dd	_641
	dd	_83
	dd	-28
	dd	2
	dd	_642
	dd	_106
	dd	-32
	dd	2
	dd	_643
	dd	_98
	dd	-36
	dd	0
	align	4
_537:
	dd	_324
	dd	68
	dd	7
	align	4
_539:
	dd	_324
	dd	69
	dd	4
	align	4
_542:
	dd	3
	dd	0
	dd	0
	align	4
_541:
	dd	_324
	dd	69
	dd	25
	align	4
_6:
	dd	bbStringClass
	dd	2147483647
	dd	18
	dw	105,109,97,103,101,32,100,111,101,115,110,116,32,101,120,105
	dw	115,116
	align	4
_543:
	dd	_324
	dd	70
	dd	4
	align	4
_546:
	dd	3
	dd	0
	dd	0
	align	4
_545:
	dd	_324
	dd	70
	dd	24
	align	4
_547:
	dd	_324
	dd	71
	dd	7
	align	4
_550:
	dd	3
	dd	0
	dd	0
	align	4
_549:
	dd	_324
	dd	71
	dd	27
	align	4
_551:
	dd	_324
	dd	72
	dd	4
	align	4
_627:
	dd	3
	dd	0
	dd	2
	dd	_106
	dd	_106
	dd	-40
	dd	0
	align	4
_555:
	dd	_324
	dd	73
	dd	6
_626:
	db	"j",0
	align	4
_625:
	dd	3
	dd	0
	dd	2
	dd	_626
	dd	_106
	dd	-44
	dd	0
	align	4
_559:
	dd	_324
	dd	74
	dd	5
_614:
	db	"sourcepixel",0
_615:
	db	"destpixel",0
_616:
	db	"destA",0
_617:
	db	"sourceA",0
_618:
	db	"destR",0
_619:
	db	"destG",0
_620:
	db	"destB",0
_621:
	db	"SourceR",0
_622:
	db	"SourceG",0
_623:
	db	"SourceB",0
_624:
	db	"AlphaSum",0
	align	4
_613:
	dd	3
	dd	0
	dd	2
	dd	_614
	dd	_106
	dd	-48
	dd	2
	dd	_615
	dd	_106
	dd	-52
	dd	2
	dd	_616
	dd	_83
	dd	-56
	dd	2
	dd	_617
	dd	_83
	dd	-60
	dd	2
	dd	_618
	dd	_83
	dd	-64
	dd	2
	dd	_619
	dd	_83
	dd	-68
	dd	2
	dd	_620
	dd	_83
	dd	-72
	dd	2
	dd	_621
	dd	_83
	dd	-76
	dd	2
	dd	_622
	dd	_83
	dd	-80
	dd	2
	dd	_623
	dd	_83
	dd	-84
	dd	2
	dd	_624
	dd	_106
	dd	-88
	dd	0
	align	4
_567:
	dd	_324
	dd	75
	dd	4
	align	4
_569:
	dd	_324
	dd	77
	dd	4
	align	4
_571:
	dd	_324
	dd	78
	dd	4
	align	4
_573:
	dd	_324
	dd	79
	dd	4
	align	4
_575:
	dd	_324
	dd	80
	dd	4
	align	4
_1590:
	dd	0x437f0000
	align	4
_578:
	dd	3
	dd	0
	dd	0
	align	4
_577:
	dd	_324
	dd	80
	dd	26
	align	4
_579:
	dd	_324
	dd	84
	dd	5
	align	4
_581:
	dd	_324
	dd	85
	dd	5
	align	4
_583:
	dd	_324
	dd	86
	dd	5
	align	4
_585:
	dd	_324
	dd	87
	dd	5
	align	4
_587:
	dd	_324
	dd	88
	dd	5
	align	4
_589:
	dd	_324
	dd	89
	dd	5
	align	4
_591:
	dd	_324
	dd	90
	dd	6
	align	4
_593:
	dd	_324
	dd	91
	dd	6
	align	4
_598:
	dd	3
	dd	0
	dd	0
	align	4
_595:
	dd	_324
	dd	92
	dd	7
	align	4
_596:
	dd	_324
	dd	93
	dd	7
	align	4
_597:
	dd	_324
	dd	94
	dd	7
	align	4
_603:
	dd	3
	dd	0
	dd	0
	align	4
_600:
	dd	_324
	dd	96
	dd	7
	align	4
_601:
	dd	_324
	dd	97
	dd	7
	align	4
_602:
	dd	_324
	dd	98
	dd	7
	align	4
_604:
	dd	_324
	dd	100
	dd	6
	align	4
_607:
	dd	3
	dd	0
	dd	0
	align	4
_606:
	dd	_324
	dd	100
	dd	29
	align	4
_608:
	dd	_324
	dd	101
	dd	6
	align	4
_609:
	dd	_324
	dd	103
	dd	4
	align	4
_612:
	dd	3
	dd	0
	dd	0
	align	4
_611:
	dd	_324
	dd	103
	dd	25
	align	4
_628:
	dd	_324
	dd	107
	dd	4
	align	4
_631:
	dd	3
	dd	0
	dd	0
	align	4
_630:
	dd	_324
	dd	107
	dd	19
	align	4
_632:
	dd	_324
	dd	108
	dd	4
	align	4
_635:
	dd	3
	dd	0
	dd	0
	align	4
_634:
	dd	_324
	dd	108
	dd	19
_701:
	db	"DrawPixmapOnPixmap",0
_702:
	db	"Source",0
	align	4
_700:
	dd	1
	dd	_701
	dd	2
	dd	_702
	dd	_98
	dd	-4
	dd	2
	dd	_639
	dd	_98
	dd	-8
	dd	2
	dd	_82
	dd	_106
	dd	-12
	dd	2
	dd	_84
	dd	_106
	dd	-16
	dd	0
	align	4
_644:
	dd	_324
	dd	112
	dd	4
	align	4
_699:
	dd	3
	dd	0
	dd	2
	dd	_106
	dd	_106
	dd	-20
	dd	0
	align	4
_650:
	dd	_324
	dd	113
	dd	6
	align	4
_698:
	dd	3
	dd	0
	dd	2
	dd	_626
	dd	_106
	dd	-24
	dd	0
	align	4
_656:
	dd	_324
	dd	114
	dd	5
	align	4
_697:
	dd	3
	dd	0
	dd	2
	dd	_614
	dd	_106
	dd	-28
	dd	2
	dd	_615
	dd	_106
	dd	-32
	dd	2
	dd	_617
	dd	_106
	dd	-36
	dd	0
	align	4
_664:
	dd	_324
	dd	115
	dd	4
	align	4
_666:
	dd	_324
	dd	116
	dd	4
	align	4
_668:
	dd	_324
	dd	118
	dd	4
	align	4
_670:
	dd	_324
	dd	119
	dd	4
	align	4
_692:
	dd	3
	dd	0
	dd	2
	dd	_618
	dd	_106
	dd	-40
	dd	2
	dd	_619
	dd	_106
	dd	-44
	dd	2
	dd	_620
	dd	_106
	dd	-48
	dd	2
	dd	_621
	dd	_106
	dd	-52
	dd	2
	dd	_622
	dd	_106
	dd	-56
	dd	2
	dd	_623
	dd	_106
	dd	-60
	dd	0
	align	4
_672:
	dd	_324
	dd	120
	dd	5
	align	4
_675:
	dd	3
	dd	0
	dd	0
	align	4
_674:
	dd	_324
	dd	120
	dd	25
	align	4
_676:
	dd	_324
	dd	121
	dd	5
	align	4
_678:
	dd	_324
	dd	122
	dd	5
	align	4
_680:
	dd	_324
	dd	123
	dd	5
	align	4
_682:
	dd	_324
	dd	124
	dd	5
	align	4
_684:
	dd	_324
	dd	125
	dd	5
	align	4
_686:
	dd	_324
	dd	126
	dd	5
	align	4
_688:
	dd	_324
	dd	127
	dd	5
	align	4
_1606:
	dd	0x437f0000
	align	4
_1607:
	dd	0x437f0000
	align	4
_689:
	dd	_324
	dd	128
	dd	5
	align	4
_1608:
	dd	0x437f0000
	align	4
_1609:
	dd	0x437f0000
	align	4
_690:
	dd	_324
	dd	129
	dd	5
	align	4
_1610:
	dd	0x437f0000
	align	4
_1611:
	dd	0x437f0000
	align	4
_691:
	dd	_324
	dd	130
	dd	5
	align	4
_693:
	dd	_324
	dd	132
	dd	4
	align	4
_696:
	dd	3
	dd	0
	dd	0
	align	4
_695:
	dd	_324
	dd	132
	dd	25
_763:
	db	"blurPixmap",0
_764:
	db	"pm",0
_765:
	db	"k",0
	align	4
_762:
	dd	1
	dd	_763
	dd	2
	dd	_764
	dd	_98
	dd	-4
	dd	2
	dd	_765
	dd	_83
	dd	-8
	dd	0
	align	4
_703:
	dd	_324
	dd	144
	dd	2
	align	4
_718:
	dd	3
	dd	0
	dd	2
	dd	_82
	dd	_106
	dd	-12
	dd	0
	align	4
_709:
	dd	_324
	dd	145
	dd	6
_717:
	db	"z",0
	align	4
_716:
	dd	3
	dd	0
	dd	2
	dd	_717
	dd	_106
	dd	-16
	dd	0
	align	4
_715:
	dd	_324
	dd	146
	dd	4
	align	4
_719:
	dd	_324
	dd	150
	dd	5
	align	4
_732:
	dd	3
	dd	0
	dd	2
	dd	_82
	dd	_106
	dd	-20
	dd	0
	align	4
_724:
	dd	_324
	dd	151
	dd	6
	align	4
_731:
	dd	3
	dd	0
	dd	2
	dd	_717
	dd	_106
	dd	-24
	dd	0
	align	4
_730:
	dd	_324
	dd	152
	dd	4
	align	4
_733:
	dd	_324
	dd	156
	dd	5
	align	4
_747:
	dd	3
	dd	0
	dd	2
	dd	_82
	dd	_106
	dd	-28
	dd	0
	align	4
_739:
	dd	_324
	dd	157
	dd	6
	align	4
_746:
	dd	3
	dd	0
	dd	2
	dd	_717
	dd	_106
	dd	-32
	dd	0
	align	4
_745:
	dd	_324
	dd	158
	dd	4
	align	4
_748:
	dd	_324
	dd	162
	dd	5
	align	4
_761:
	dd	3
	dd	0
	dd	2
	dd	_82
	dd	_106
	dd	-36
	dd	0
	align	4
_754:
	dd	_324
	dd	163
	dd	6
	align	4
_760:
	dd	3
	dd	0
	dd	2
	dd	_717
	dd	_106
	dd	-40
	dd	0
	align	4
_759:
	dd	_324
	dd	164
	dd	4
_785:
	db	"blurPixel",0
_786:
	db	"px2",0
_787:
	db	"pxa",0
_788:
	db	"pxb",0
_789:
	db	"pxg",0
_790:
	db	"pxr",0
_791:
	db	"px2b",0
_792:
	db	"px2g",0
_793:
	db	"px2r",0
	align	4
_784:
	dd	1
	dd	_785
	dd	2
	dd	_99
	dd	_106
	dd	-32
	dd	2
	dd	_786
	dd	_106
	dd	-36
	dd	2
	dd	_765
	dd	_83
	dd	-40
	dd	2
	dd	_787
	dd	_408
	dd	-4
	dd	2
	dd	_788
	dd	_408
	dd	-8
	dd	2
	dd	_789
	dd	_408
	dd	-12
	dd	2
	dd	_790
	dd	_408
	dd	-16
	dd	2
	dd	_791
	dd	_408
	dd	-20
	dd	2
	dd	_792
	dd	_408
	dd	-24
	dd	2
	dd	_793
	dd	_408
	dd	-28
	dd	0
	align	4
_766:
	dd	_324
	dd	176
	dd	2
	align	4
_768:
	dd	_324
	dd	177
	dd	2
	align	4
_770:
	dd	_324
	dd	178
	dd	2
	align	4
_772:
	dd	_324
	dd	179
	dd	2
	align	4
_774:
	dd	_324
	dd	182
	dd	2
	align	4
_776:
	dd	_324
	dd	183
	dd	2
	align	4
_778:
	dd	_324
	dd	184
	dd	2
	align	4
_780:
	dd	_324
	dd	187
	dd	2
	align	4
_1633:
	dd	0x3f800000
	align	4
_781:
	dd	_324
	dd	188
	dd	2
	align	4
_1634:
	dd	0x3f800000
	align	4
_782:
	dd	_324
	dd	189
	dd	2
	align	4
_1635:
	dd	0x3f800000
	align	4
_783:
	dd	_324
	dd	191
	dd	2
_827:
	db	"DrawTextOnPixmap",0
_828:
	db	"Text",0
_829:
	db	"blur",0
_830:
	db	"TxtWidth",0
	align	4
_826:
	dd	1
	dd	_827
	dd	2
	dd	_828
	dd	_441
	dd	-8
	dd	2
	dd	_82
	dd	_106
	dd	-12
	dd	2
	dd	_84
	dd	_106
	dd	-16
	dd	2
	dd	_639
	dd	_98
	dd	-20
	dd	2
	dd	_829
	dd	_408
	dd	-4
	dd	2
	dd	_830
	dd	_106
	dd	-24
	dd	2
	dd	_702
	dd	_98
	dd	-28
	dd	0
	align	4
_794:
	dd	_324
	dd	196
	dd	1
_806:
	db	"r",0
_807:
	db	"g",0
	align	4
_805:
	dd	3
	dd	0
	dd	2
	dd	_806
	dd	_106
	dd	-32
	dd	2
	dd	_807
	dd	_106
	dd	-36
	dd	2
	dd	_408
	dd	_106
	dd	-40
	dd	0
	align	4
_796:
	dd	_324
	dd	197
	dd	2
	align	4
_800:
	dd	_324
	dd	198
	dd	2
	align	4
_801:
	dd	_324
	dd	199
	dd	2
	align	4
_802:
	dd	_324
	dd	200
	dd	2
	align	4
_803:
	dd	_324
	dd	201
	dd	2
	align	4
_804:
	dd	_324
	dd	202
	dd	2
	align	4
_810:
	dd	3
	dd	0
	dd	0
	align	4
_809:
	dd	_324
	dd	204
	dd	2
	align	4
_811:
	dd	_324
	dd	206
	dd	2
	align	4
_813:
	dd	_324
	dd	207
	dd	5
	align	4
_815:
	dd	_324
	dd	208
	dd	2
	align	4
_816:
	dd	_324
	dd	209
	dd	1
	align	4
_824:
	dd	3
	dd	0
	dd	0
	align	4
_818:
	dd	_324
	dd	210
	dd	2
	align	4
_819:
	dd	_324
	dd	211
	dd	2
	align	4
_820:
	dd	_324
	dd	212
	dd	2
	align	4
_821:
	dd	_324
	dd	213
	dd	2
	align	4
_822:
	dd	_324
	dd	214
	dd	5
	align	4
_823:
	dd	_324
	dd	215
	dd	2
	align	4
_825:
	dd	_324
	dd	217
	dd	5
_833:
	db	"Self",0
_834:
	db	":ImageFragment",0
	align	4
_832:
	dd	1
	dd	_87
	dd	2
	dd	_833
	dd	_834
	dd	-4
	dd	0
	align	4
_831:
	dd	3
	dd	0
	dd	0
_859:
	db	"pmap",0
_860:
	db	"frag",0
	align	4
_858:
	dd	1
	dd	_89
	dd	2
	dd	_859
	dd	_98
	dd	-4
	dd	2
	dd	_82
	dd	_83
	dd	-8
	dd	2
	dd	_84
	dd	_83
	dd	-12
	dd	2
	dd	_85
	dd	_83
	dd	-16
	dd	2
	dd	_86
	dd	_83
	dd	-20
	dd	2
	dd	_860
	dd	_834
	dd	-24
	dd	0
	align	4
_835:
	dd	_324
	dd	232
	dd	9
	align	4
_837:
	dd	_324
	dd	233
	dd	9
	align	4
_841:
	dd	_324
	dd	234
	dd	9
	align	4
_845:
	dd	_324
	dd	235
	dd	9
	align	4
_849:
	dd	_324
	dd	236
	dd	9
	align	4
_853:
	dd	_324
	dd	237
	dd	9
	align	4
_857:
	dd	_324
	dd	239
	dd	9
_885:
	db	"xoff",0
_886:
	db	"yoff",0
_887:
	db	"Scale",0
_888:
	db	"vx",0
_889:
	db	"vy",0
_890:
	db	"vh",0
	align	4
_884:
	dd	1
	dd	_91
	dd	2
	dd	_833
	dd	_834
	dd	-4
	dd	2
	dd	_885
	dd	_83
	dd	-8
	dd	2
	dd	_886
	dd	_83
	dd	-12
	dd	2
	dd	_887
	dd	_83
	dd	-16
	dd	2
	dd	_888
	dd	_106
	dd	-20
	dd	2
	dd	_889
	dd	_106
	dd	-24
	dd	2
	dd	_890
	dd	_106
	dd	-28
	dd	0
	align	4
_861:
	dd	_324
	dd	247
	dd	6
	align	4
_865:
	dd	_324
	dd	248
	dd	6
	align	4
_866:
	dd	_324
	dd	249
	dd	3
	align	4
_883:
	dd	3
	dd	0
	dd	0
	align	4
_876:
	dd	_324
	dd	250
	dd	11
_899:
	db	"vw",0
	align	4
_898:
	dd	1
	dd	_93
	dd	2
	dd	_833
	dd	_834
	dd	-4
	dd	2
	dd	_885
	dd	_83
	dd	-8
	dd	2
	dd	_886
	dd	_83
	dd	-12
	dd	2
	dd	_888
	dd	_83
	dd	-16
	dd	2
	dd	_889
	dd	_83
	dd	-20
	dd	2
	dd	_899
	dd	_83
	dd	-24
	dd	2
	dd	_890
	dd	_83
	dd	-28
	dd	0
	align	4
_891:
	dd	_324
	dd	257
	dd	3
_902:
	db	":TBigImage",0
	align	4
_901:
	dd	1
	dd	_87
	dd	2
	dd	_833
	dd	_902
	dd	-4
	dd	0
	align	4
_900:
	dd	3
	dd	0
	dd	0
_912:
	db	"pix",0
	align	4
_911:
	dd	1
	dd	_107
	dd	2
	dd	_106
	dd	_81
	dd	-4
	dd	2
	dd	_912
	dd	_98
	dd	-8
	dd	0
	align	4
_903:
	dd	_324
	dd	277
	dd	4
	align	4
_910:
	dd	_324
	dd	278
	dd	4
	align	4
_914:
	dd	1
	dd	_109
	dd	2
	dd	_106
	dd	_98
	dd	-4
	dd	0
	align	4
_913:
	dd	_324
	dd	282
	dd	4
_952:
	db	"p",0
_953:
	db	"bi",0
	align	4
_951:
	dd	1
	dd	_89
	dd	2
	dd	_952
	dd	_98
	dd	-4
	dd	2
	dd	_953
	dd	_902
	dd	-8
	dd	0
	align	4
_915:
	dd	_324
	dd	287
	dd	9
	align	4
_917:
	dd	_324
	dd	288
	dd	9
	align	4
_921:
	dd	_324
	dd	289
	dd	9
	align	4
_927:
	dd	_324
	dd	290
	dd	9
	align	4
_933:
	dd	_324
	dd	291
	dd	9
	align	4
_937:
	dd	_324
	dd	292
	dd	9
	align	4
_940:
	dd	_324
	dd	293
	dd	3
	align	4
_946:
	dd	_324
	dd	294
	dd	3
	align	4
_950:
	dd	_324
	dd	295
	dd	9
_985:
	db	"Pix",0
	align	4
_984:
	dd	1
	dd	_111
	dd	2
	dd	_833
	dd	_902
	dd	-4
	dd	2
	dd	_985
	dd	_98
	dd	-8
	dd	0
	align	4
_954:
	dd	_324
	dd	300
	dd	4
	align	4
_962:
	dd	_324
	dd	301
	dd	4
_982:
	db	"ImgFrag",0
	align	4
_981:
	dd	3
	dd	0
	dd	2
	dd	_982
	dd	_834
	dd	-12
	dd	0
	align	4
_974:
	dd	_324
	dd	302
	dd	6
	align	4
_983:
	dd	_324
	dd	304
	dd	4
_1049:
	db	"loading",0
	align	4
_1048:
	dd	1
	dd	_113
	dd	2
	dd	_833
	dd	_902
	dd	-8
	dd	2
	dd	_99
	dd	_83
	dd	-12
	dd	2
	dd	_100
	dd	_83
	dd	-16
	dd	2
	dd	_1049
	dd	_408
	dd	-4
	dd	0
	align	4
_986:
	dd	_324
	dd	313
	dd	9
	align	4
_988:
	dd	_324
	dd	314
	dd	9
	align	4
_990:
	dd	_324
	dd	315
	dd	9
	align	4
_992:
	dd	_324
	dd	317
	dd	9
_1047:
	db	"f1",0
	align	4
_1046:
	dd	3
	dd	0
	dd	2
	dd	_85
	dd	_106
	dd	-20
	dd	2
	dd	_86
	dd	_106
	dd	-24
	dd	2
	dd	_1047
	dd	_834
	dd	-28
	dd	0
	align	4
_993:
	dd	_324
	dd	318
	dd	13
	align	4
_995:
	dd	_324
	dd	319
	dd	13
	align	4
_997:
	dd	_324
	dd	320
	dd	13
	align	4
_1705:
	dd	0x43800000
	align	4
_1008:
	dd	3
	dd	0
	dd	0
	align	4
_1003:
	dd	_324
	dd	320
	dd	53
	align	4
_1009:
	dd	_324
	dd	321
	dd	13
	align	4
_1706:
	dd	0x43800000
	align	4
_1020:
	dd	3
	dd	0
	dd	0
	align	4
_1015:
	dd	_324
	dd	321
	dd	54
	align	4
_1021:
	dd	_324
	dd	322
	dd	13
	align	4
_1025:
	dd	_324
	dd	324
	dd	13
	align	4
_1028:
	dd	_324
	dd	325
	dd	13
	align	4
_1707:
	dd	0x43800000
	align	4
_1029:
	dd	_324
	dd	326
	dd	13
	align	4
_1045:
	dd	3
	dd	0
	dd	0
	align	4
_1035:
	dd	_324
	dd	327
	dd	17
	align	4
_1036:
	dd	_324
	dd	328
	dd	17
	align	4
_1708:
	dd	0x43800000
	align	4
_1037:
	dd	_324
	dd	329
	dd	17
	align	4
_1044:
	dd	3
	dd	0
	dd	0
	align	4
_1043:
	dd	_324
	dd	329
	dd	45
	align	4
_1066:
	dd	1
	dd	_91
	dd	2
	dd	_833
	dd	_902
	dd	-4
	dd	2
	dd	_82
	dd	_83
	dd	-8
	dd	2
	dd	_84
	dd	_83
	dd	-12
	dd	2
	dd	_887
	dd	_83
	dd	-16
	dd	0
	align	4
_1050:
	dd	_324
	dd	340
	dd	9
	align	4
_1065:
	dd	3
	dd	0
	dd	2
	dd	_83
	dd	_834
	dd	-20
	dd	0
	align	4
_1062:
	dd	_324
	dd	341
	dd	13
	align	4
_1083:
	dd	1
	dd	_93
	dd	2
	dd	_833
	dd	_902
	dd	-4
	dd	2
	dd	_82
	dd	_83
	dd	-8
	dd	2
	dd	_84
	dd	_83
	dd	-12
	dd	2
	dd	_888
	dd	_83
	dd	-16
	dd	2
	dd	_889
	dd	_83
	dd	-20
	dd	2
	dd	_899
	dd	_83
	dd	-24
	dd	2
	dd	_890
	dd	_83
	dd	-28
	dd	0
	align	4
_1067:
	dd	_324
	dd	349
	dd	9
	align	4
_1082:
	dd	3
	dd	0
	dd	2
	dd	_83
	dd	_834
	dd	-32
	dd	0
	align	4
_1079:
	dd	_324
	dd	350
	dd	13
_1103:
	db	"tRTTError",0
_1104:
	db	"err",0
	align	4
_1102:
	dd	1
	dd	_1103
	dd	2
	dd	_1104
	dd	_106
	dd	-4
	dd	0
	align	4
_1084:
	dd	_324
	dd	368
	dd	2
	align	4
_1093:
	dd	3
	dd	0
	dd	0
	align	4
_1092:
	dd	_324
	dd	370
	dd	4
	align	4
_55:
	dd	bbStringClass
	dd	2147483647
	dd	24
	dw	68,68,69,82,82,95,73,78,86,65,76,73,68,83,85,82
	dw	70,65,67,69,84,89,80,69
	align	4
_1095:
	dd	3
	dd	0
	dd	0
	align	4
_1094:
	dd	_324
	dd	373
	dd	4
	align	4
_56:
	dd	bbStringClass
	dd	2147483647
	dd	19
	dw	68,68,69,82,82,95,73,78,86,65,76,73,68,80,65,82
	dw	65,77,83
	align	4
_1097:
	dd	3
	dd	0
	dd	0
	align	4
_1096:
	dd	_324
	dd	376
	dd	4
	align	4
_57:
	dd	bbStringClass
	dd	2147483647
	dd	19
	dw	68,68,69,82,82,95,73,78,86,65,76,73,68,79,66,74
	dw	69,67,84
	align	4
_1099:
	dd	3
	dd	0
	dd	0
	align	4
_1098:
	dd	_324
	dd	379
	dd	4
	align	4
_58:
	dd	bbStringClass
	dd	2147483647
	dd	14
	dw	68,68,69,82,82,95,78,79,84,70,79,85,78,68
	align	4
_1101:
	dd	3
	dd	0
	dd	0
	align	4
_1100:
	dd	_324
	dd	382
	dd	4
	align	4
_59:
	dd	bbStringClass
	dd	2147483647
	dd	17
	dw	68,68,69,82,82,95,83,85,82,70,65,67,69,76,79,83
	dw	84
_1107:
	db	":tRender",0
	align	4
_1106:
	dd	1
	dd	_87
	dd	2
	dd	_833
	dd	_1107
	dd	-4
	dd	0
	align	4
_1105:
	dd	3
	dd	0
	dd	0
	align	4
_1110:
	dd	1
	dd	_116
	dd	0
	align	4
_1108:
	dd	_324
	dd	421
	dd	4
	align	4
_1109:
	dd	_324
	dd	428
	dd	3
_1184:
	db	"Width",0
_1185:
	db	"Height",0
_1186:
	db	"Flags",0
_1187:
	db	"t",0
	align	4
_1183:
	dd	1
	dd	_117
	dd	2
	dd	_1184
	dd	_106
	dd	-4
	dd	2
	dd	_1185
	dd	_106
	dd	-8
	dd	2
	dd	_1186
	dd	_106
	dd	-12
	dd	2
	dd	_1187
	dd	_81
	dd	-16
	dd	0
	align	4
_1111:
	dd	_324
	dd	445
	dd	3
	align	4
_1113:
	dd	_324
	dd	446
	dd	3
	align	4
_1117:
	dd	_324
	dd	447
	dd	3
	align	4
_1121:
	dd	_324
	dd	448
	dd	3
	align	4
_1125:
	dd	_324
	dd	449
	dd	3
	align	4
_1129:
	dd	_324
	dd	450
	dd	3
	align	4
_1133:
	dd	_324
	dd	451
	dd	3
	align	4
_1137:
	dd	_324
	dd	452
	dd	3
_1141:
	db	":brl.pixmap.TPixmap",0
	align	4
_1142:
	dd	_324
	dd	453
	dd	3
_1146:
	db	":brl.max2d.TImageFrame",0
	align	4
_1147:
	dd	_324
	dd	454
	dd	3
_1151:
	db	"i",0
	align	4
_1152:
	dd	_324
	dd	455
	dd	3
	align	4
_1161:
	dd	_324
	dd	456
	dd	3
	align	4
_1168:
	dd	_324
	dd	466
	dd	4
	align	4
_1182:
	dd	_324
	dd	475
	dd	3
_1209:
	db	"X",0
_1210:
	db	"Y",0
_1211:
	db	"FlipY",0
	align	4
_1208:
	dd	1
	dd	_119
	dd	2
	dd	_1209
	dd	_106
	dd	-8
	dd	2
	dd	_1210
	dd	_106
	dd	-12
	dd	2
	dd	_1184
	dd	_106
	dd	-16
	dd	2
	dd	_1185
	dd	_106
	dd	-20
	dd	2
	dd	_1211
	dd	_408
	dd	-4
	dd	0
	align	4
_1188:
	dd	_324
	dd	568
	dd	4
	align	4
_1198:
	dd	3
	dd	0
	dd	0
	align	4
_1190:
	dd	_324
	dd	569
	dd	5
	align	4
_1191:
	dd	_324
	dd	570
	dd	5
	align	4
_1192:
	dd	_324
	dd	571
	dd	5
	align	4
_1193:
	dd	_324
	dd	572
	dd	5
	align	4
_1194:
	dd	_324
	dd	573
	dd	5
	align	4
_1195:
	dd	_324
	dd	574
	dd	5
	align	4
_1196:
	dd	_324
	dd	575
	dd	5
	align	4
_1197:
	dd	_324
	dd	576
	dd	5
	align	4
_1206:
	dd	3
	dd	0
	dd	0
	align	4
_1200:
	dd	_324
	dd	578
	dd	5
	align	4
_1201:
	dd	_324
	dd	579
	dd	5
	align	4
_1202:
	dd	_324
	dd	580
	dd	5
	align	4
_1203:
	dd	_324
	dd	581
	dd	5
	align	8
_1784:
	dd	0x0,0xbff00000
	align	4
_1204:
	dd	_324
	dd	582
	dd	5
	align	4
_1205:
	dd	_324
	dd	583
	dd	5
	align	4
_1207:
	dd	_324
	dd	589
	dd	3
_1239:
	db	"Image1",0
_1240:
	db	"Viewport",0
	align	4
_1238:
	dd	1
	dd	_121
	dd	2
	dd	_1239
	dd	_81
	dd	-8
	dd	2
	dd	_1240
	dd	_408
	dd	-4
	dd	0
	align	4
_1212:
	dd	_324
	dd	602
	dd	2
	align	4
_1213:
	dd	_324
	dd	605
	dd	3
	align	4
_1214:
	dd	_324
	dd	606
	dd	3
	align	4
_1222:
	dd	3
	dd	0
	dd	0
	align	4
_1216:
	dd	_324
	dd	607
	dd	4
	align	4
_1219:
	dd	_324
	dd	608
	dd	4
	align	4
_1226:
	dd	3
	dd	0
	dd	0
	align	4
_1224:
	dd	_324
	dd	610
	dd	4
	align	4
_1225:
	dd	_324
	dd	611
	dd	4
	align	4
_1227:
	dd	_324
	dd	613
	dd	3
	align	4
_1230:
	dd	3
	dd	0
	dd	0
	align	4
_1229:
	dd	_324
	dd	615
	dd	4
	align	4
_1233:
	dd	3
	dd	0
	dd	0
	align	4
_1232:
	dd	_324
	dd	619
	dd	4
	align	4
_1234:
	dd	_324
	dd	632
	dd	4
	align	4
_1237:
	dd	_324
	dd	638
	dd	3
_1252:
	db	"col",0
_1253:
	db	"Red",0
_1254:
	db	"Green",0
_1255:
	db	"Blue",0
_1256:
	db	"Alpha",0
	align	4
_1251:
	dd	1
	dd	_123
	dd	2
	dd	_1252
	dd	_106
	dd	-4
	dd	2
	dd	_1253
	dd	_83
	dd	-8
	dd	2
	dd	_1254
	dd	_83
	dd	-12
	dd	2
	dd	_1255
	dd	_83
	dd	-16
	dd	2
	dd	_1256
	dd	_83
	dd	-20
	dd	0
	align	4
_1241:
	dd	_324
	dd	651
	dd	5
	align	4
_1243:
	dd	_324
	dd	652
	dd	5
	align	4
_1245:
	dd	_324
	dd	653
	dd	5
	align	4
_1247:
	dd	_324
	dd	654
	dd	5
	align	4
_1249:
	dd	_324
	dd	656
	dd	5
	align	4
_1797:
	dd	0x437f0000
	align	4
_1798:
	dd	0x437f0000
	align	4
_1799:
	dd	0x437f0000
	align	4
_1800:
	dd	0x437f0000
	align	4
_1250:
	dd	_324
	dd	657
	dd	5
	align	4
_1263:
	dd	1
	dd	_125
	dd	2
	dd	_462
	dd	_106
	dd	-4
	dd	2
	dd	_1187
	dd	_106
	dd	-8
	dd	0
	align	4
_1257:
	dd	_324
	dd	714
	dd	4
	align	4
_1259:
	dd	_324
	dd	715
	dd	4
	align	4
_1261:
	dd	3
	dd	0
	dd	0
	align	4
_1260:
	dd	_324
	dd	716
	dd	5
	align	4
_1262:
	dd	_324
	dd	718
	dd	4
	align	4
_1273:
	dd	1
	dd	_126
	dd	0
	align	4
_1264:
	dd	_324
	dd	724
	dd	2
	align	4
_1265:
	dd	_324
	dd	733
	dd	4
	align	4
_1268:
	dd	_324
	dd	734
	dd	4
	align	4
_1269:
	dd	_324
	dd	736
	dd	4
	align	4
_1270:
	dd	_324
	dd	740
	dd	3
	align	4
_1271:
	dd	_324
	dd	741
	dd	3
	align	4
_1272:
	dd	_324
	dd	743
	dd	3
	align	4
_1276:
	dd	1
	dd	_127
	dd	0
	align	4
_1274:
	dd	_324
	dd	761
	dd	3
	align	4
_1275:
	dd	_324
	dd	763
	dd	3
	align	4
_1279:
	dd	1
	dd	_128
	dd	0
	align	4
_1277:
	dd	_324
	dd	776
	dd	4
	align	4
_1278:
	dd	_324
	dd	781
	dd	3
_1338:
	db	"ColorizedImage",0
_1339:
	db	"imagea",0
_1340:
	db	"mypixmap2",0
_1341:
	db	"mypixelptr2",0
_1342:
	db	"*i",0
_1343:
	db	"mypixelptr2backup",0
	align	4
_1337:
	dd	1
	dd	_1338
	dd	2
	dd	_1339
	dd	_81
	dd	-4
	dd	2
	dd	_806
	dd	_83
	dd	-8
	dd	2
	dd	_807
	dd	_83
	dd	-12
	dd	2
	dd	_408
	dd	_83
	dd	-16
	dd	2
	dd	_1340
	dd	_98
	dd	-20
	dd	2
	dd	_1341
	dd	_1342
	dd	-24
	dd	2
	dd	_1343
	dd	_1342
	dd	-28
	dd	0
	align	4
_1280:
	dd	_324
	dd	792
	dd	3
	align	4
_1282:
	dd	_324
	dd	793
	dd	3
	align	4
_1289:
	dd	3
	dd	0
	dd	0
	align	4
_1286:
	dd	_324
	dd	793
	dd	43
	align	4
_1290:
	dd	_324
	dd	795
	dd	3
	align	4
_1291:
	dd	_324
	dd	796
	dd	3
	align	4
_1295:
	dd	_324
	dd	797
	dd	3
	align	4
_1297:
	dd	_324
	dd	798
	dd	3
_1322:
	db	"my_x",0
_1323:
	db	"graycolor",0
	align	4
_1321:
	dd	3
	dd	0
	dd	2
	dd	_1322
	dd	_106
	dd	-32
	dd	2
	dd	_1323
	dd	_106
	dd	-36
	dd	0
	align	4
_1305:
	dd	_324
	dd	800
	dd	4
	align	4
_1307:
	dd	_324
	dd	801
	dd	6
	align	4
_1313:
	dd	3
	dd	0
	dd	0
	align	4
_1309:
	dd	_324
	dd	802
	dd	10
	align	4
_1312:
	dd	3
	dd	0
	dd	0
	align	4
_1311:
	dd	_324
	dd	802
	dd	38
	align	4
_1816:
	dd	0x42c80000
	align	4
_1817:
	dd	0x42c80000
	align	4
_1818:
	dd	0x42c80000
	align	4
_1314:
	dd	_324
	dd	804
	dd	6
	align	4
_1315:
	dd	_324
	dd	805
	dd	6
	align	4
_1320:
	dd	3
	dd	0
	dd	0
	align	4
_1319:
	dd	_324
	dd	806
	dd	10
	align	4
_1324:
	dd	_324
	dd	809
	dd	3
	align	4
_1330:
	dd	_324
	dd	810
	dd	3
	align	4
_1336:
	dd	_324
	dd	811
	dd	3
_1403:
	db	"ColorizePixmap",0
_1404:
	db	"frame",0
	align	4
_1402:
	dd	1
	dd	_1403
	dd	2
	dd	_532
	dd	_81
	dd	-4
	dd	2
	dd	_1404
	dd	_106
	dd	-8
	dd	2
	dd	_806
	dd	_83
	dd	-12
	dd	2
	dd	_807
	dd	_83
	dd	-16
	dd	2
	dd	_408
	dd	_83
	dd	-20
	dd	0
	align	4
_1344:
	dd	_324
	dd	816
	dd	1
_1401:
	db	"mypixmap",0
	align	4
_1400:
	dd	3
	dd	0
	dd	2
	dd	_1401
	dd	_98
	dd	-24
	dd	2
	dd	_1340
	dd	_98
	dd	-28
	dd	2
	dd	_1341
	dd	_1342
	dd	-32
	dd	2
	dd	_1343
	dd	_1342
	dd	-36
	dd	0
	align	4
_1346:
	dd	_324
	dd	818
	dd	3
	align	4
_1348:
	dd	_324
	dd	819
	dd	3
	align	4
_1355:
	dd	3
	dd	0
	dd	0
	align	4
_1352:
	dd	_324
	dd	819
	dd	42
	align	4
_1356:
	dd	_324
	dd	820
	dd	3
	align	4
_1364:
	dd	_324
	dd	821
	dd	3
	align	4
_1367:
	dd	_324
	dd	822
	dd	3
	align	4
_1371:
	dd	_324
	dd	823
	dd	3
	align	4
_1373:
	dd	_324
	dd	824
	dd	3
_1397:
	db	"colortone",0
	align	4
_1396:
	dd	3
	dd	0
	dd	2
	dd	_1322
	dd	_106
	dd	-40
	dd	2
	dd	_1397
	dd	_106
	dd	-44
	dd	0
	align	4
_1381:
	dd	_324
	dd	826
	dd	6
	align	4
_1383:
	dd	_324
	dd	827
	dd	6
	align	4
_1388:
	dd	3
	dd	0
	dd	0
	align	4
_1387:
	dd	_324
	dd	828
	dd	8
	align	4
_1836:
	dd	0x437f0000
	align	4
_1837:
	dd	0x437f0000
	align	4
_1838:
	dd	0x437f0000
	align	4
_1389:
	dd	_324
	dd	830
	dd	6
	align	4
_1390:
	dd	_324
	dd	831
	dd	6
	align	4
_1395:
	dd	3
	dd	0
	dd	0
	align	4
_1394:
	dd	_324
	dd	832
	dd	10
	align	4
_1398:
	dd	_324
	dd	835
	dd	3
	align	4
_1399:
	dd	_324
	dd	836
	dd	3
_1410:
	db	"ColorizeImage",0
_1411:
	db	"imgpath",0
_1412:
	db	"cr",0
_1413:
	db	"cg",0
_1414:
	db	"cb",0
_1415:
	db	"colorpixmap",0
	align	4
_1409:
	dd	1
	dd	_1410
	dd	2
	dd	_1411
	dd	_441
	dd	-4
	dd	2
	dd	_1412
	dd	_106
	dd	-8
	dd	2
	dd	_1413
	dd	_106
	dd	-12
	dd	2
	dd	_1414
	dd	_106
	dd	-16
	dd	2
	dd	_1415
	dd	_98
	dd	-20
	dd	0
	align	4
_1405:
	dd	_324
	dd	842
	dd	3
	align	4
_1407:
	dd	_324
	dd	843
	dd	3
	align	4
_1408:
	dd	_324
	dd	844
	dd	3
_1484:
	db	"CopyImage",0
_1485:
	db	"src",0
_1486:
	db	"dst",0
	align	4
_1483:
	dd	1
	dd	_1484
	dd	2
	dd	_1485
	dd	_81
	dd	-4
	dd	2
	dd	_1486
	dd	_81
	dd	-8
	dd	0
	align	4
_1416:
	dd	_324
	dd	849
	dd	4
	align	4
_1419:
	dd	3
	dd	0
	dd	0
	align	4
_1418:
	dd	_324
	dd	849
	dd	23
	align	4
_1420:
	dd	_324
	dd	851
	dd	4
	align	4
_1422:
	dd	_324
	dd	852
	dd	4
	align	4
_1423:
	dd	_324
	dd	854
	dd	4
_1427:
	db	":brl.pixmap.TPixmap",0
	align	4
_1430:
	dd	_324
	dd	855
	dd	4
_1434:
	db	":brl.max2d.TImageFrame",0
	align	4
_1437:
	dd	_324
	dd	856
	dd	4
_1441:
	db	"i",0
	align	4
_1444:
	dd	_324
	dd	858
	dd	4
	align	4
_1462:
	dd	3
	dd	0
	dd	2
	dd	_106
	dd	_106
	dd	-12
	dd	0
	align	4
_1450:
	dd	_324
	dd	859
	dd	7
	align	4
_1463:
	dd	_324
	dd	862
	dd	4
	align	4
_1472:
	dd	3
	dd	0
	dd	2
	dd	_106
	dd	_106
	dd	-16
	dd	0
	align	4
_1469:
	dd	_324
	dd	863
	dd	7
	align	4
_1473:
	dd	_324
	dd	866
	dd	4
	align	4
_1482:
	dd	_324
	dd	868
	dd	4
_1558:
	db	"ColorizeTImage",0
_1559:
	db	"cell_width",0
_1560:
	db	"cell_height",0
_1561:
	db	"first_cell",0
_1562:
	db	"cell_count",0
_1563:
	db	"flag",0
_1564:
	db	"loadAnimated",0
	align	4
_1557:
	dd	1
	dd	_1558
	dd	2
	dd	_532
	dd	_81
	dd	-4
	dd	2
	dd	_806
	dd	_106
	dd	-8
	dd	2
	dd	_807
	dd	_106
	dd	-12
	dd	2
	dd	_408
	dd	_106
	dd	-16
	dd	2
	dd	_1559
	dd	_106
	dd	-20
	dd	2
	dd	_1560
	dd	_106
	dd	-24
	dd	2
	dd	_1561
	dd	_106
	dd	-28
	dd	2
	dd	_1562
	dd	_106
	dd	-32
	dd	2
	dd	_1563
	dd	_106
	dd	-36
	dd	2
	dd	_1564
	dd	_106
	dd	-40
	dd	0
	align	4
_1487:
	dd	_324
	dd	873
	dd	2
_1556:
	db	"d",0
	align	4
_1555:
	dd	3
	dd	0
	dd	2
	dd	_1556
	dd	_106
	dd	-44
	dd	2
	dd	_1401
	dd	_98
	dd	-48
	dd	2
	dd	_1340
	dd	_98
	dd	-52
	dd	2
	dd	_1341
	dd	_1342
	dd	-56
	dd	2
	dd	_1343
	dd	_1342
	dd	-60
	dd	0
	align	4
_1489:
	dd	_324
	dd	874
	dd	3
	align	4
_1491:
	dd	_324
	dd	875
	dd	3
	align	4
_1492:
	dd	_324
	dd	875
	dd	9
	align	4
_1493:
	dd	_324
	dd	876
	dd	3
	align	4
_1495:
	dd	_324
	dd	877
	dd	3
	align	4
_1502:
	dd	3
	dd	0
	dd	0
	align	4
_1499:
	dd	_324
	dd	877
	dd	42
	align	4
_1503:
	dd	_324
	dd	878
	dd	3
	align	4
_1511:
	dd	_324
	dd	879
	dd	3
	align	4
_1514:
	dd	_324
	dd	880
	dd	3
	align	4
_1515:
	dd	_324
	dd	881
	dd	3
	align	4
_1519:
	dd	_324
	dd	882
	dd	3
	align	4
_1521:
	dd	_324
	dd	883
	dd	3
	align	4
_1544:
	dd	3
	dd	0
	dd	2
	dd	_1322
	dd	_106
	dd	-64
	dd	2
	dd	_1397
	dd	_106
	dd	-68
	dd	0
	align	4
_1529:
	dd	_324
	dd	884
	dd	4
	align	4
_1531:
	dd	_324
	dd	885
	dd	4
	align	4
_1536:
	dd	3
	dd	0
	dd	0
	align	4
_1535:
	dd	_324
	dd	886
	dd	5
	align	4
_1537:
	dd	_324
	dd	888
	dd	4
	align	4
_1538:
	dd	_324
	dd	889
	dd	4
	align	4
_1543:
	dd	3
	dd	0
	dd	0
	align	4
_1542:
	dd	_324
	dd	890
	dd	5
	align	4
_1545:
	dd	_324
	dd	893
	dd	3
	align	4
_1546:
	dd	_324
	dd	894
	dd	3
	align	4
_1553:
	dd	3
	dd	0
	dd	0
	align	4
_1552:
	dd	_324
	dd	894
	dd	62
	align	4
_1554:
	dd	_324
	dd	895
	dd	3
