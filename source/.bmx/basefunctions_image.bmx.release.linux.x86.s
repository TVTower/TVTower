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
	extrn	bbGCFree
	extrn	bbMemCopy
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
	extrn	bb_ARGB_Alpha
	extrn	bb_ARGB_Blue
	extrn	bb_ARGB_Color
	extrn	bb_ARGB_Green
	extrn	bb_ARGB_Red
	extrn	bb_isMonochrome
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
	public	_bb_ImageFragment_Delete
	public	_bb_ImageFragment_New
	public	_bb_ImageFragment_create
	public	_bb_ImageFragment_render
	public	_bb_ImageFragment_renderInViewPort
	public	_bb_TBigImage_CreateFromImage
	public	_bb_TBigImage_CreateFromPixmap
	public	_bb_TBigImage_Delete
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
	public	_bb_tRender_Delete
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
	cmp	dword [_336],0
	je	_337
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_337:
	mov	dword [_336],1
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
	mov	eax,dword [_334]
	and	eax,1
	cmp	eax,0
	jne	_335
	push	-1
	push	1
	push	1
	push	1
	call	brl_max2d_CreateImage
	add	esp,16
	inc	dword [eax+4]
	mov	dword [_bb_tRender_Image],eax
	or	dword [_334],1
_335:
	push	bb_tRender
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,0
	jmp	_130
_130:
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawImageArea:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	fld	dword [ebp+12]
	fld	dword [ebp+16]
	fld	dword [ebp+20]
	fld	dword [ebp+24]
	fld	dword [ebp+28]
	fld	dword [ebp+32]
	mov	eax,dword [ebp+36]
	push	eax
	push	0
	push	0
	sub	esp,4
	fst	dword [esp]
	sub	esp,4
	fxch	st1
	fst	dword [esp]
	sub	esp,4
	fxch	st2
	fstp	dword [esp]
	sub	esp,4
	fxch	st2
	fstp	dword [esp]
	sub	esp,4
	fxch	st1
	fstp	dword [esp]
	sub	esp,4
	fstp	dword [esp]
	sub	esp,4
	fstp	dword [esp]
	sub	esp,4
	fstp	dword [esp]
	push	edx
	call	brl_max2d_DrawSubImageRect
	add	esp,48
	mov	eax,0
	jmp	_140
_140:
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawImageAreaPow2Size:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	sub	eax,1
	mov	edx,eax
	shr	edx,1
	or	eax,edx
	mov	edx,eax
	shr	edx,2
	or	eax,edx
	mov	edx,eax
	shr	edx,4
	or	eax,edx
	mov	edx,eax
	shr	edx,8
	or	eax,edx
	mov	edx,eax
	shr	edx,16
	or	eax,edx
	add	eax,1
	jmp	_143
_143:
	mov	esp,ebp
	pop	ebp
	ret
bb_ClipImageToViewport:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+44]
	push	esi
	call	brl_max2d_ImageWidth
	add	esp,4
	mov	ebx,eax
	push	esi
	call	brl_max2d_ImageHeight
	add	esp,4
	mov	edx,eax
	fld	dword [ebp+12]
	mov	dword [ebp+-4],ebx
	fild	dword [ebp+-4]
	faddp	st1,st0
	fld	dword [ebp+20]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	je	_340
	fld	dword [ebp+12]
	mov	dword [ebp+-4],ebx
	fild	dword [ebp+-4]
	fsubp	st1,st0
	fld	dword [ebp+20]
	fadd	dword [ebp+28]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
_340:
	cmp	eax,0
	je	_342
	fld	dword [ebp+16]
	mov	dword [ebp+-4],edx
	fild	dword [ebp+-4]
	faddp	st1,st0
	fld	dword [ebp+24]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
_342:
	cmp	eax,0
	je	_344
	fld	dword [ebp+16]
	mov	dword [ebp+-4],edx
	fild	dword [ebp+-4]
	fsubp	st1,st0
	fld	dword [ebp+24]
	fadd	dword [ebp+32]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
_344:
	cmp	eax,0
	je	_346
	fld	dword [ebp+20]
	fsub	dword [ebp+12]
	fld	dword [ebp+24]
	fsub	dword [ebp+16]
	fldz
	fxch	st2
	fucom	st2
	fxch	st2
	fstp	st0
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_349
	fxch	st1
	fstp	st0
	fld	dword [_662]
	fxch	st1
_349:
	fldz
	fxch	st1
	fucom	st1
	fxch	st1
	fstp	st0
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_350
	fstp	st0
	fld	dword [_663]
_350:
	fld	dword [ebp+12]
	mov	dword [ebp+-4],ebx
	fild	dword [ebp+-4]
	faddp	st1,st0
	fld	dword [ebp+20]
	fadd	dword [ebp+28]
	fsubp	st1,st0
	fld	dword [ebp+16]
	mov	dword [ebp+-4],edx
	fild	dword [ebp+-4]
	faddp	st1,st0
	fld	dword [ebp+24]
	fadd	dword [ebp+32]
	fsubp	st1,st0
	fldz
	fxch	st2
	fucom	st2
	fxch	st2
	fstp	st0
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_353
	fxch	st1
	fstp	st0
	fld	dword [_664]
	fxch	st1
_353:
	fldz
	fxch	st1
	fucom	st1
	fxch	st1
	fstp	st0
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_354
	fstp	st0
	fld	dword [_665]
_354:
	push	edi
	mov	dword [ebp+-4],edx
	fild	dword [ebp+-4]
	fsub	st0,st3
	fsubrp	st1,st0
	sub	esp,4
	fstp	dword [esp]
	mov	dword [ebp+-4],ebx
	fild	dword [ebp+-4]
	fsub	st0,st3
	fsubrp	st1,st0
	sub	esp,4
	fstp	dword [esp]
	sub	esp,4
	fst	dword [esp]
	sub	esp,4
	fxch	st1
	fst	dword [esp]
	fld	dword [ebp+16]
	faddp	st2,st0
	fxch	st1
	fadd	dword [ebp+40]
	sub	esp,4
	fstp	dword [esp]
	fld	dword [ebp+12]
	faddp	st1,st0
	fadd	dword [ebp+36]
	sub	esp,4
	fstp	dword [esp]
	push	esi
	call	bb_DrawImageArea
	add	esp,32
_346:
	mov	eax,0
	jmp	_155
_155:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawImageInViewPort:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+16]
	movzx	eax,byte [ebp+20]
	mov	eax,eax
	mov	byte [ebp-4],al
	cmp	edi,10
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_355
	mov	ebx,edi
	push	esi
	call	brl_max2d_ImageHeight
	add	esp,4
	sub	ebx,eax
	cmp	ebx,383
	setl	al
	movzx	eax,al
_355:
	cmp	eax,0
	je	_357
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	cmp	eax,0
	jne	_358
	push	dword [ebp+24]
	mov	ebx,edi
	push	esi
	call	brl_max2d_ImageHeight
	add	esp,4
	sub	ebx,eax
	mov	dword [ebp+-8],ebx
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp+12]
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	push	esi
	call	brl_max2d_DrawImage
	add	esp,16
	jmp	_359
_358:
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	cmp	eax,1
	jne	_360
	push	dword [ebp+24]
	mov	ebx,edi
	push	esi
	call	brl_max2d_ImageHeight
	add	esp,4
	sub	ebx,eax
	mov	dword [ebp+-8],ebx
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	mov	ebx,dword [ebp+12]
	push	esi
	call	brl_max2d_ImageWidth
	add	esp,4
	sub	ebx,eax
	mov	dword [ebp+-8],ebx
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	push	esi
	call	brl_max2d_DrawImage
	add	esp,16
_360:
_359:
_357:
	mov	eax,0
	jmp	_162
_162:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawOnPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,52
	push	ebx
	push	esi
	push	edi
	mov	dword [ebp-44],bbNullObject
	cmp	dword [ebp+8],bbNullObject
	jne	_362
	push	_6
	call	bbExThrow
	add	esp,4
_362:
	cmp	dword [ebp+12],0
	jne	_363
	push	1
	push	1
	push	0
	push	dword [ebp+8]
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-44],eax
_363:
	cmp	dword [ebp+12],0
	jle	_364
	push	1
	push	1
	push	dword [ebp+12]
	push	dword [ebp+8]
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-44],eax
_364:
	mov	dword [ebp-32],0
	push	dword [ebp+8]
	call	brl_max2d_ImageWidth
	add	esp,4
	sub	eax,1
	mov	dword [ebp-48],eax
	jmp	_366
_9:
	mov	edi,0
	push	dword [ebp+8]
	call	brl_max2d_ImageHeight
	add	esp,4
	sub	eax,1
	mov	dword [ebp-40],eax
	jmp	_369
_12:
	mov	edx,dword [ebp+20]
	add	edx,dword [ebp-32]
	mov	eax,dword [ebp+16]
	cmp	edx,dword [eax+12]
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_371
	mov	edx,dword [ebp+24]
	add	edx,edi
	mov	eax,dword [ebp+16]
	cmp	edx,dword [eax+16]
	setl	al
	movzx	eax,al
_371:
	cmp	eax,0
	je	_373
	push	edi
	push	dword [ebp-32]
	push	dword [ebp-44]
	call	brl_pixmap_ReadPixel
	add	esp,12
	mov	esi,eax
	mov	eax,dword [ebp+24]
	add	eax,edi
	push	eax
	mov	eax,dword [ebp+20]
	add	eax,dword [ebp-32]
	push	eax
	push	dword [ebp+16]
	call	brl_pixmap_ReadPixel
	add	esp,12
	mov	ebx,eax
	push	ebx
	call	bb_ARGB_Alpha
	add	esp,4
	mov	dword [ebp+-52],eax
	fild	dword [ebp+-52]
	fstp	dword [ebp-4]
	push	esi
	call	bb_ARGB_Alpha
	add	esp,4
	mov	dword [ebp+-52],eax
	fild	dword [ebp+-52]
	fmul	dword [ebp+28]
	fstp	dword [ebp-24]
	fld	dword [_682]
	fld	dword [ebp-24]
	fucompp
	fnstsw	ax
	sahf
	setnz	al
	movzx	eax,al
	cmp	eax,0
	jne	_378
	fld	dword [_683]
	fstp	dword [ebp-4]
_378:
	push	ebx
	call	bb_ARGB_Red
	add	esp,4
	mov	dword [ebp+-52],eax
	fild	dword [ebp+-52]
	fstp	dword [ebp-8]
	push	ebx
	call	bb_ARGB_Green
	add	esp,4
	mov	dword [ebp+-52],eax
	fild	dword [ebp+-52]
	fstp	dword [ebp-12]
	push	ebx
	call	bb_ARGB_Blue
	add	esp,4
	mov	dword [ebp+-52],eax
	fild	dword [ebp+-52]
	fstp	dword [ebp-16]
	push	esi
	call	bb_ARGB_Red
	add	esp,4
	mov	dword [ebp+-52],eax
	fild	dword [ebp+-52]
	fstp	dword [ebp-20]
	push	esi
	call	bb_ARGB_Green
	add	esp,4
	mov	dword [ebp+-52],eax
	fild	dword [ebp+-52]
	fstp	dword [ebp-28]
	push	esi
	call	bb_ARGB_Blue
	add	esp,4
	mov	dword [ebp+-52],eax
	fild	dword [ebp+-52]
	fstp	dword [ebp-36]
	fld	dword [ebp-4]
	fadd	dword [ebp-24]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	ebx,eax
	cmp	dword [ebp+36],1
	jne	_386
	fld	dword [ebp-20]
	fmul	dword [ebp+32]
	fmul	dword [ebp-24]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fld	dword [ebp-4]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fld	dword [ebp-8]
	fmul	dword [ebp-4]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fmulp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-20]
	fld	dword [ebp-28]
	fmul	dword [ebp+32]
	fmul	dword [ebp-24]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fld	dword [ebp-4]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fld	dword [ebp-12]
	fmul	dword [ebp-4]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fmulp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-28]
	fld	dword [ebp-36]
	fmul	dword [ebp+32]
	fmul	dword [ebp-24]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fld	dword [ebp-4]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fld	dword [ebp-16]
	fmul	dword [ebp-4]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fmulp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-36]
	jmp	_387
_386:
	fld	dword [ebp-20]
	fmul	dword [ebp+32]
	fmul	dword [ebp-24]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fld	dword [ebp-8]
	fmul	dword [ebp-4]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-20]
	fld	dword [ebp-28]
	fmul	dword [ebp+32]
	fmul	dword [ebp-24]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fld	dword [ebp-12]
	fmul	dword [ebp-4]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-28]
	fld	dword [ebp-36]
	fmul	dword [ebp+32]
	fmul	dword [ebp-24]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	fld	dword [ebp-16]
	fmul	dword [ebp-4]
	mov	dword [ebp+-52],ebx
	fild	dword [ebp+-52]
	fdivp	st1,st0
	faddp	st1,st0
	fstp	dword [ebp-36]
_387:
	cmp	ebx,255
	jle	_388
	mov	ebx,255
_388:
	fld	dword [ebp-36]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp-28]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp-20]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	ebx
	call	bb_ARGB_Color
	add	esp,16
	mov	esi,eax
	fldz
	fld	dword [ebp-24]
	fucompp
	fnstsw	ax
	sahf
	setz	al
	movzx	eax,al
	cmp	eax,0
	jne	_389
	push	esi
	mov	eax,dword [ebp+24]
	add	eax,edi
	push	eax
	mov	eax,dword [ebp+20]
	add	eax,dword [ebp-32]
	push	eax
	push	dword [ebp+16]
	call	brl_pixmap_WritePixel
	add	esp,16
_389:
_373:
_10:
	add	edi,1
_369:
	cmp	edi,dword [ebp-40]
	jle	_12
_11:
_7:
	add	dword [ebp-32],1
_366:
	mov	eax,dword [ebp-48]
	cmp	dword [ebp-32],eax
	jle	_9
_8:
	cmp	dword [ebp+12],0
	jne	_390
	push	0
	push	dword [ebp+8]
	call	brl_max2d_UnlockImage
	add	esp,8
_390:
	cmp	dword [ebp+12],0
	jle	_391
	push	dword [ebp+12]
	push	dword [ebp+8]
	call	brl_max2d_UnlockImage
	add	esp,8
_391:
	mov	eax,0
	jmp	_172
_172:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawPixmapOnPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,36
	push	ebx
	push	esi
	push	edi
	mov	dword [ebp-24],0
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	sub	eax,1
	mov	dword [ebp-32],eax
	jmp	_393
_15:
	mov	dword [ebp-20],0
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	sub	eax,1
	mov	dword [ebp-28],eax
	jmp	_396
_18:
	mov	edx,dword [ebp+16]
	add	edx,1
	mov	eax,dword [ebp+12]
	cmp	edx,dword [eax+12]
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_398
	mov	edx,dword [ebp+20]
	add	edx,dword [ebp-20]
	mov	eax,dword [ebp+12]
	cmp	edx,dword [eax+16]
	setl	al
	movzx	eax,al
_398:
	cmp	eax,0
	je	_400
	push	dword [ebp-20]
	push	dword [ebp-24]
	push	dword [ebp+8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	mov	ebx,eax
	mov	eax,dword [ebp+20]
	add	eax,dword [ebp-20]
	push	eax
	mov	eax,dword [ebp+16]
	add	eax,dword [ebp-24]
	push	eax
	push	dword [ebp+12]
	call	brl_pixmap_ReadPixel
	add	esp,12
	mov	esi,eax
	push	ebx
	call	bb_ARGB_Alpha
	add	esp,4
	mov	dword [ebp-4],eax
	cmp	dword [ebp-4],-1
	je	_404
	cmp	dword [ebp-4],-1
	jge	_405
	mov	eax,dword [ebp-4]
	neg	eax
	mov	dword [ebp-4],eax
_405:
	push	esi
	call	bb_ARGB_Red
	add	esp,4
	mov	dword [ebp-8],eax
	push	esi
	call	bb_ARGB_Green
	add	esp,4
	mov	dword [ebp-12],eax
	push	esi
	call	bb_ARGB_Blue
	add	esp,4
	mov	dword [ebp-16],eax
	push	ebx
	call	bb_ARGB_Red
	add	esp,4
	mov	edi,eax
	push	ebx
	call	bb_ARGB_Green
	add	esp,4
	mov	esi,eax
	push	ebx
	call	bb_ARGB_Blue
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [ebp-4]
	mov	dword [ebp+-36],eax
	fild	dword [ebp+-36]
	fdiv	dword [_697]
	mov	dword [ebp+-36],edi
	fild	dword [ebp+-36]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	edi,eax
	mov	eax,255
	sub	eax,dword [ebp-4]
	mov	dword [ebp+-36],eax
	fild	dword [ebp+-36]
	fdiv	dword [_698]
	mov	eax,dword [ebp-8]
	mov	dword [ebp+-36],eax
	fild	dword [ebp+-36]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	add	edi,eax
	mov	eax,dword [ebp-4]
	mov	dword [ebp+-36],eax
	fild	dword [ebp+-36]
	fdiv	dword [_699]
	mov	dword [ebp+-36],esi
	fild	dword [ebp+-36]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	esi,eax
	mov	eax,255
	sub	eax,dword [ebp-4]
	mov	dword [ebp+-36],eax
	fild	dword [ebp+-36]
	fdiv	dword [_700]
	mov	eax,dword [ebp-12]
	mov	dword [ebp+-36],eax
	fild	dword [ebp+-36]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	add	esi,eax
	mov	eax,dword [ebp-4]
	mov	dword [ebp+-36],eax
	fild	dword [ebp+-36]
	fdiv	dword [_701]
	mov	dword [ebp+-36],ebx
	fild	dword [ebp+-36]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	ebx,eax
	mov	eax,255
	sub	eax,dword [ebp-4]
	mov	dword [ebp+-36],eax
	fild	dword [ebp+-36]
	fdiv	dword [_702]
	mov	eax,dword [ebp-16]
	mov	dword [ebp+-36],eax
	fild	dword [ebp+-36]
	fmulp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	add	ebx,eax
	push	ebx
	push	esi
	push	edi
	push	255
	call	bb_ARGB_Color
	add	esp,16
	mov	ebx,eax
_404:
	cmp	dword [ebp-4],0
	je	_412
	push	ebx
	mov	eax,dword [ebp+20]
	add	eax,dword [ebp-20]
	push	eax
	mov	eax,dword [ebp+16]
	add	eax,dword [ebp-24]
	push	eax
	push	dword [ebp+12]
	call	brl_pixmap_WritePixel
	add	esp,16
_412:
_400:
_16:
	add	dword [ebp-20],1
_396:
	mov	eax,dword [ebp-28]
	cmp	dword [ebp-20],eax
	jle	_18
_17:
_13:
	add	dword [ebp-24],1
_393:
	mov	eax,dword [ebp-32]
	cmp	dword [ebp-24],eax
	jle	_15
_14:
	mov	eax,0
	jmp	_178
_178:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_blurPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	esi,1
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	sub	eax,1
	mov	dword [ebp-4],eax
	jmp	_414
_21:
	mov	ebx,0
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	sub	eax,1
	mov	edi,eax
	jmp	_417
_24:
	push	dword [ebp+12]
	push	ebx
	mov	eax,esi
	sub	eax,1
	push	eax
	push	dword [ebp+8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	push	ebx
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	call	bb_blurPixel
	add	esp,12
	push	eax
	push	ebx
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_WritePixel
	add	esp,16
_22:
	add	ebx,1
_417:
	cmp	ebx,edi
	jle	_24
_23:
_19:
	add	esi,1
_414:
	cmp	esi,dword [ebp-4]
	jle	_21
_20:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	sub	eax,3
	mov	esi,eax
	jmp	_420
_27:
	mov	ebx,0
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	sub	eax,1
	mov	edi,eax
	jmp	_422
_30:
	push	dword [ebp+12]
	push	ebx
	mov	eax,esi
	add	eax,1
	push	eax
	push	dword [ebp+8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	push	ebx
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	call	bb_blurPixel
	add	esp,12
	push	eax
	push	ebx
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_WritePixel
	add	esp,16
_28:
	add	ebx,1
_422:
	cmp	ebx,edi
	jle	_30
_29:
_25:
	add	esi,-1
_420:
	cmp	esi,0
	jge	_27
_26:
	mov	esi,0
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	sub	eax,1
	mov	dword [ebp-8],eax
	jmp	_425
_33:
	mov	ebx,1
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	sub	eax,1
	mov	edi,eax
	jmp	_428
_36:
	push	dword [ebp+12]
	mov	eax,ebx
	sub	eax,1
	push	eax
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	push	ebx
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	call	bb_blurPixel
	add	esp,12
	push	eax
	push	ebx
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_WritePixel
	add	esp,16
_34:
	add	ebx,1
_428:
	cmp	ebx,edi
	jle	_36
_35:
_31:
	add	esi,1
_425:
	cmp	esi,dword [ebp-8]
	jle	_33
_32:
	mov	esi,0
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	sub	eax,1
	mov	edi,eax
	jmp	_431
_39:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	sub	eax,3
	mov	ebx,eax
	jmp	_434
_42:
	push	dword [ebp+12]
	mov	eax,ebx
	add	eax,1
	push	eax
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	push	ebx
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_ReadPixel
	add	esp,12
	push	eax
	call	bb_blurPixel
	add	esp,12
	push	eax
	push	ebx
	push	esi
	push	dword [ebp+8]
	call	brl_pixmap_WritePixel
	add	esp,16
_40:
	add	ebx,-1
_434:
	cmp	ebx,0
	jge	_42
_41:
_37:
	add	esi,1
_431:
	cmp	esi,edi
	jle	_39
_38:
	mov	eax,0
	jmp	_182
_182:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_blurPixel:
	push	ebp
	mov	ebp,esp
	sub	esp,32
	mov	ecx,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,ecx
	shr	eax,24
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-4],al
	mov	eax,ecx
	shr	eax,16
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-8],al
	mov	eax,ecx
	shr	eax,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-12],al
	mov	eax,ecx
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-16],al
	mov	eax,edx
	shr	eax,16
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-20],al
	mov	eax,edx
	shr	eax,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-24],al
	mov	eax,edx
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-28],al
	movzx	eax,byte [ebp-20]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fld	dword [_712]
	fsub	dword [ebp+16]
	fmulp	st1,st0
	movzx	eax,byte [ebp-8]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fmul	dword [ebp+16]
	faddp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-8],al
	movzx	eax,byte [ebp-24]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fld	dword [_713]
	fsub	dword [ebp+16]
	fmulp	st1,st0
	movzx	eax,byte [ebp-12]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fmul	dword [ebp+16]
	faddp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-12],al
	movzx	eax,byte [ebp-28]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fld	dword [_714]
	fsub	dword [ebp+16]
	fmulp	st1,st0
	movzx	eax,byte [ebp-16]
	mov	dword [ebp+-32],eax
	fild	dword [ebp+-32]
	fmul	dword [ebp+16]
	faddp	st1,st0
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	eax,eax
	and	eax,0xff
	mov	eax,eax
	mov	byte [ebp-16],al
	movzx	eax,byte [ebp-4]
	mov	eax,eax
	shl	eax,24
	movzx	edx,byte [ebp-8]
	mov	edx,edx
	shl	edx,16
	or	eax,edx
	movzx	edx,byte [ebp-12]
	mov	edx,edx
	shl	edx,8
	or	eax,edx
	movzx	edx,byte [ebp-16]
	mov	edx,edx
	or	eax,edx
	jmp	_187
_187:
	mov	esp,ebp
	pop	ebp
	ret
bb_DrawTextOnPixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	movzx	eax,byte [ebp+24]
	mov	eax,eax
	mov	byte [ebp-4],al
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_442
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	lea	eax,dword [ebp-16]
	push	eax
	lea	eax,dword [ebp-12]
	push	eax
	lea	eax,dword [ebp-8]
	push	eax
	call	brl_max2d_GetColor
	add	esp,12
	push	50
	push	50
	push	50
	call	brl_max2d_SetColor
	add	esp,12
	mov	eax,dword [ebp+16]
	sub	eax,1
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp+12]
	sub	eax,1
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,4
	fstp	dword [esp]
	push	edi
	call	brl_max2d_DrawText
	add	esp,12
	mov	eax,dword [ebp+16]
	add	eax,1
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp+12]
	add	eax,1
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,4
	fstp	dword [esp]
	push	edi
	call	brl_max2d_DrawText
	add	esp,12
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-8]
	call	brl_max2d_SetColor
	add	esp,12
	jmp	_446
_442:
	mov	eax,dword [ebp+16]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp+12]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,4
	fstp	dword [esp]
	push	edi
	call	brl_max2d_DrawText
	add	esp,12
_446:
	push	edi
	call	brl_max2d_TextWidth
	add	esp,4
	mov	esi,eax
	push	edi
	call	brl_max2d_TextHeight
	add	esp,4
	add	eax,4
	push	eax
	mov	eax,esi
	add	eax,4
	push	eax
	mov	eax,dword [ebp+16]
	sub	eax,2
	push	eax
	mov	eax,dword [ebp+12]
	sub	eax,2
	push	eax
	call	brl_max2d_GrabPixmap
	add	esp,16
	mov	ebx,eax
	push	4
	push	ebx
	call	brl_pixmap_ConvertPixmap
	add	esp,8
	mov	ebx,eax
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_449
	push	1056964608
	push	ebx
	call	bb_blurPixmap
	add	esp,8
	push	4
	push	ebx
	call	brl_pixmap_ConvertPixmap
	add	esp,8
	mov	ebx,eax
	mov	eax,dword [ebp+16]
	sub	eax,2
	push	eax
	mov	eax,dword [ebp+12]
	sub	eax,2
	push	eax
	push	ebx
	call	brl_max2d_DrawPixmap
	add	esp,12
	mov	eax,dword [ebp+16]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,4
	fstp	dword [esp]
	mov	eax,dword [ebp+12]
	mov	dword [ebp+-20],eax
	fild	dword [ebp+-20]
	sub	esp,4
	fstp	dword [esp]
	push	edi
	call	brl_max2d_DrawText
	add	esp,12
	push	edi
	call	brl_max2d_TextHeight
	add	esp,4
	add	eax,4
	push	eax
	mov	eax,esi
	add	eax,4
	push	eax
	mov	eax,dword [ebp+16]
	sub	eax,2
	push	eax
	mov	eax,dword [ebp+12]
	sub	eax,2
	push	eax
	call	brl_max2d_GrabPixmap
	add	esp,16
	mov	ebx,eax
	push	4
	push	ebx
	call	brl_pixmap_ConvertPixmap
	add	esp,8
	mov	ebx,eax
_449:
	mov	eax,dword [ebp+16]
	sub	eax,10
	push	eax
	mov	eax,dword [ebp+12]
	sub	eax,20
	push	eax
	push	dword [ebp+20]
	push	ebx
	call	bb_DrawPixmapOnPixmap
	add	esp,16
	mov	eax,0
	jmp	_194
_194:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ImageFragment_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_ImageFragment
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	fldz
	fstp	dword [ebx+12]
	fldz
	fstp	dword [ebx+16]
	fldz
	fstp	dword [ebx+20]
	fldz
	fstp	dword [ebx+24]
	mov	eax,0
	jmp	_197
_197:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ImageFragment_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_200:
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_453
	push	eax
	call	bbGCFree
	add	esp,4
_453:
	mov	eax,0
	jmp	_451
_451:
	mov	esp,ebp
	pop	ebp
	ret
_bb_ImageFragment_create:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	push	bb_ImageFragment
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	push	0
	fld	dword [ebp+24]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp+20]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp+16]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebp+12]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	esi
	call	brl_pixmap_PixmapWindow
	add	esp,20
	push	eax
	call	brl_max2d_LoadImage
	add	esp,8
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_458
	push	eax
	call	bbGCFree
	add	esp,4
_458:
	mov	dword [ebx+8],esi
	fld	dword [ebp+12]
	fstp	dword [ebx+12]
	fld	dword [ebp+16]
	fstp	dword [ebx+16]
	fld	dword [ebp+20]
	fstp	dword [ebx+20]
	fld	dword [ebp+24]
	fstp	dword [ebx+24]
	mov	eax,ebx
	jmp	_207
_207:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ImageFragment_render:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	dword [ebp-4],0
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	lea	eax,dword [ebp-12]
	push	eax
	lea	eax,dword [ebp-4]
	push	eax
	lea	eax,dword [ebp-8]
	push	eax
	lea	eax,dword [ebp-4]
	push	eax
	call	brl_max2d_GetViewport
	add	esp,16
	fld	dword [ebp+16]
	fld	dword [ebp+20]
	fmul	dword [ebx+16]
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
	je	_462
	fld	dword [ebp+16]
	fld	dword [ebp+20]
	fmul	dword [ebx+16]
	faddp	st1,st0
	mov	eax,dword [ebp-8]
	add	eax,dword [ebp-12]
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
_462:
	cmp	eax,0
	je	_464
	push	0
	fld	dword [ebp+16]
	fld	dword [ebp+20]
	fmul	dword [ebx+16]
	faddp	st1,st0
	sub	esp,4
	fstp	dword [esp]
	fld	dword [ebp+12]
	fld	dword [ebp+20]
	fmul	dword [ebx+12]
	faddp	st1,st0
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebx+8]
	call	brl_max2d_DrawImage
	add	esp,16
_464:
	mov	eax,0
	jmp	_213
_213:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ImageFragment_renderInViewPort:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	fld	dword [ebp+12]
	fld	dword [ebp+16]
	fld	dword [ebp+20]
	fld	dword [ebp+24]
	fld	dword [ebp+28]
	fld	dword [ebp+32]
	push	0
	push	0
	push	0
	sub	esp,4
	fstp	dword [esp]
	sub	esp,4
	fstp	dword [esp]
	sub	esp,4
	fstp	dword [esp]
	sub	esp,4
	fstp	dword [esp]
	fadd	dword [eax+16]
	sub	esp,4
	fstp	dword [esp]
	fadd	dword [eax+12]
	sub	esp,4
	fstp	dword [esp]
	push	dword [eax+8]
	call	bb_ClipImageToViewport
	add	esp,40
	mov	eax,0
	jmp	_222
_222:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TBigImage
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	fldz
	fstp	dword [ebx+12]
	fldz
	fstp	dword [ebx+16]
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+20],eax
	fldz
	fstp	dword [ebx+24]
	fldz
	fstp	dword [ebx+28]
	mov	dword [ebx+32],0
	fldz
	fstp	dword [ebx+36]
	fldz
	fstp	dword [ebx+40]
	mov	eax,0
	jmp	_225
_225:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_228:
	mov	eax,dword [ebx+20]
	dec	dword [eax+4]
	jnz	_469
	push	eax
	call	bbGCFree
	add	esp,4
_469:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_471
	push	eax
	call	bbGCFree
	add	esp,4
_471:
	mov	eax,0
	jmp	_467
_467:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_CreateFromImage:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+40]
	mov	eax,dword [eax+24]
	push	eax
	call	dword [bb_TBigImage+56]
	add	esp,4
	jmp	_231
_231:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_CreateFromPixmap:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	call	dword [bb_TBigImage+56]
	add	esp,4
	jmp	_234
_234:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_create:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	push	bb_TBigImage
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,esi
	inc	dword [eax+4]
	mov	edi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_477
	push	eax
	call	bbGCFree
	add	esp,4
_477:
	mov	dword [ebx+8],edi
	mov	eax,dword [esi+12]
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	fstp	dword [ebx+24]
	mov	eax,dword [esi+16]
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	fstp	dword [ebx+28]
	call	brl_linkedlist_CreateList
	inc	dword [eax+4]
	mov	edi,eax
	mov	eax,dword [ebx+20]
	dec	dword [eax+4]
	jnz	_481
	push	eax
	call	bbGCFree
	add	esp,4
_481:
	mov	dword [ebx+20],edi
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,4
	mov	eax,dword [esi+24]
	mov	dword [ebx+32],eax
	mov	esi,bbNullObject
	inc	dword [esi+4]
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_486
	push	eax
	call	bbGCFree
	add	esp,4
_486:
	mov	dword [ebx+8],esi
	mov	eax,ebx
	jmp	_237
_237:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_RestorePixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	push	4
	push	dword [ebx+32]
	fld	dword [ebx+28]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	fld	dword [ebx+24]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	call	dword [brl_pixmap_TPixmap+80]
	add	esp,16
	mov	dword [ebp-4],eax
	mov	ebx,dword [ebx+20]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_43
_45:
	mov	eax,edi
	push	bb_ImageFragment
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_43
	push	0
	push	1065353216
	push	1065353216
	fld	dword [esi+16]
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
	push	dword [ebp-4]
	push	0
	push	dword [esi+8]
	call	bb_DrawOnPixmap
	add	esp,32
_43:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_45
_44:
	mov	eax,dword [ebp-4]
	jmp	_240
_240:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_Load:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	fld	dword [_752]
	fstp	dword [ebp-8]
	fld	dword [_753]
	fstp	dword [ebp-12]
	mov	byte [ebp-4],1
	jmp	_46
_48:
	mov	esi,256
	mov	ebx,256
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+12]
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fsub	dword [ebp-8]
	fld	dword [_754]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_499
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+12]
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fsub	dword [ebp-8]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	esi,eax
_499:
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+16]
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fsub	dword [ebp-12]
	fld	dword [_755]
	fxch	st1
	fucompp
	fnstsw	ax
	sahf
	setae	al
	movzx	eax,al
	cmp	eax,0
	jne	_500
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+16]
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fsub	dword [ebp-12]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	mov	ebx,eax
_500:
	mov	dword [ebp+-16],ebx
	fild	dword [ebp+-16]
	sub	esp,4
	fstp	dword [esp]
	mov	dword [ebp+-16],esi
	fild	dword [ebp+-16]
	sub	esp,4
	fstp	dword [esp]
	push	dword [ebp-12]
	push	dword [ebp-8]
	push	dword [edi+8]
	call	dword [bb_ImageFragment+48]
	add	esp,20
	push	eax
	push	dword [edi+20]
	call	brl_linkedlist_ListAddLast
	add	esp,8
	fld	dword [ebp-8]
	fadd	dword [_756]
	fstp	dword [ebp-8]
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+12]
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fld	dword [ebp-8]
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
	cmp	eax,0
	jne	_502
	fld	dword [_757]
	fstp	dword [ebp-8]
	fld	dword [ebp-12]
	fadd	dword [_758]
	fstp	dword [ebp-12]
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+16]
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fld	dword [ebp-12]
	fucompp
	fnstsw	ax
	sahf
	setb	al
	movzx	eax,al
	cmp	eax,0
	jne	_503
	mov	byte [ebp-4],0
_503:
_502:
_46:
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	jne	_48
_47:
	mov	eax,0
	jmp	_243
_243:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_render:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	esi,dword [eax+20]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_49
_51:
	push	bb_ImageFragment
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_49
	push	dword [ebp+20]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,16
_49:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_51
_50:
	mov	eax,0
	jmp	_249
_249:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBigImage_renderInViewPort:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	esi,dword [eax+20]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_52
_54:
	push	bb_ImageFragment
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_52
	push	dword [ebp+32]
	push	dword [ebp+28]
	push	dword [ebp+24]
	push	dword [ebp+20]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,28
_52:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_54
_53:
	mov	eax,0
	jmp	_258
_258:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_tRTTError:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	cmp	eax,-2005532080
	je	_520
	cmp	eax,-2147024809
	je	_521
	cmp	eax,-2005532542
	je	_522
	cmp	eax,-2005532417
	je	_523
	cmp	eax,-2005532222
	je	_524
	jmp	_519
_520:
	mov	eax,_55
	jmp	_261
_521:
	mov	eax,_56
	jmp	_261
_522:
	mov	eax,_57
	jmp	_261
_523:
	mov	eax,_58
	jmp	_261
_524:
	mov	eax,_59
	jmp	_261
_519:
	mov	eax,bbEmptyString
	jmp	_261
_261:
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_tRender
	mov	eax,0
	jmp	_264
_264:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_Delete:
	push	ebp
	mov	ebp,esp
_267:
	mov	eax,0
	jmp	_525
_525:
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_Initialise:
	push	ebp
	mov	ebp,esp
	mov	dword [_bb_tRender_DX],0
	mov	eax,1
	jmp	_269
_269:
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_Create:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	push	brl_max2d_TImage
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	dword [ebx+8],esi
	mov	dword [ebx+12],edi
	mov	eax,dword [ebp+16]
	mov	dword [ebx+16],eax
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	dword [ebx+28],0
	push	1
	push	_527
	call	bbArrayNew1D
	add	esp,8
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+40]
	dec	dword [eax+4]
	jnz	_531
	push	eax
	call	bbGCFree
	add	esp,4
_531:
	mov	dword [ebx+40],esi
	push	1
	push	_532
	call	bbArrayNew1D
	add	esp,8
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+44]
	dec	dword [eax+4]
	jnz	_536
	push	eax
	call	bbGCFree
	add	esp,4
_536:
	mov	dword [ebx+44],esi
	push	1
	push	_537
	call	bbArrayNew1D
	add	esp,8
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+48]
	dec	dword [eax+4]
	jnz	_541
	push	eax
	call	bbGCFree
	add	esp,4
_541:
	mov	dword [ebx+48],esi
	mov	eax,ebx
	push	0
	push	1
	push	0
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,16
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+40]
	mov	eax,dword [eax+24]
	dec	dword [eax+4]
	jnz	_546
	push	eax
	call	bbGCFree
	add	esp,4
_546:
	mov	eax,dword [ebx+40]
	mov	dword [eax+24],esi
	mov	edx,dword [ebx+48]
	mov	eax,dword [brl_graphics_GraphicsSeq]
	mov	dword [edx+24],eax
	push	dword [ebx+16]
	mov	eax,dword [ebx+40]
	push	dword [eax+24]
	call	dword [brl_glmax2d_TGLImageFrame+52]
	add	esp,8
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+44]
	mov	eax,dword [eax+24]
	dec	dword [eax+4]
	jnz	_550
	push	eax
	call	bbGCFree
	add	esp,4
_550:
	mov	eax,dword [ebx+44]
	mov	dword [eax+24],esi
	mov	eax,ebx
	jmp	_274
_274:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_ViewportSet:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	ecx,dword [ebp+16]
	mov	edx,dword [ebp+20]
	movzx	eax,byte [ebp+24]
	mov	eax,eax
	mov	byte [ebp-4],al
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_551
	push	edx
	push	ecx
	push	ebx
	push	esi
	call	glViewport
	add	esp,16
	push	5889
	call	glMatrixMode
	add	esp,4
	call	glPushMatrix
	call	glLoadIdentity
	mov	dword [ebp+-8],ebx
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	brl_graphics_GraphicsHeight
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	brl_graphics_GraphicsWidth
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	mov	dword [ebp+-8],esi
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	gluOrtho2D
	add	esp,32
	push	1065353216
	push	-1082130432
	push	1065353216
	call	glScalef
	add	esp,12
	push	0
	call	brl_graphics_GraphicsHeight
	neg	eax
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	push	0
	call	glTranslatef
	add	esp,12
	push	5888
	call	glMatrixMode
	add	esp,4
	jmp	_552
_551:
	push	edx
	push	ecx
	push	ebx
	push	esi
	call	glViewport
	add	esp,16
	push	5889
	call	glMatrixMode
	add	esp,4
	call	glLoadIdentity
	fld1
	sub	esp,8
	fstp	qword [esp]
	fld	qword [_793]
	sub	esp,8
	fstp	qword [esp]
	mov	dword [ebp+-8],ebx
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	brl_graphics_GraphicsHeight
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	brl_graphics_GraphicsWidth
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	mov	dword [ebp+-8],esi
	fild	dword [ebp+-8]
	sub	esp,8
	fstp	qword [esp]
	call	glOrtho
	add	esp,48
	push	5888
	call	glMatrixMode
	add	esp,4
	call	glLoadIdentity
_552:
	mov	eax,1
	jmp	_281
_281:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_TextureRender_Begin:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	movzx	eax,byte [ebp+12]
	mov	eax,eax
	mov	byte [ebp-4],al
	call	brl_graphics_GraphicsHeight
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fstp	dword [ebp-8]
	push	ebx
	call	brl_max2d_ImageHeight
	add	esp,4
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fld	dword [ebp-8]
	fdivrp	st1,st0
	fstp	dword [ebp-8]
	push	dword [ebp-8]
	call	brl_graphics_GraphicsWidth
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fstp	dword [ebp-12]
	push	ebx
	call	brl_max2d_ImageWidth
	add	esp,4
	mov	dword [ebp+-16],eax
	fild	dword [ebp+-16]
	fld	dword [ebp-12]
	fdivrp	st1,st0
	fstp	dword [ebp-12]
	push	dword [ebp-12]
	call	brl_max2d_SetScale
	add	esp,8
	inc	dword [ebx+4]
	mov	esi,ebx
	mov	eax,dword [_bb_tRender_Image]
	dec	dword [eax+4]
	jnz	_556
	push	eax
	call	bbGCFree
	add	esp,4
_556:
	mov	dword [_bb_tRender_Image],esi
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_557
	mov	eax,dword [ebx+8]
	mov	dword [_bb_tRender_Width],eax
	mov	eax,dword [ebx+12]
	mov	dword [_bb_tRender_Height],eax
	jmp	_558
_557:
	call	brl_graphics_GraphicsWidth
	mov	dword [_bb_tRender_Width],eax
	call	brl_graphics_GraphicsHeight
	mov	dword [_bb_tRender_Height],eax
_558:
	cmp	dword [_bb_tRender_DX],1
	jne	_559
	push	0
	push	dword [_bb_tRender_Height]
	push	dword [_bb_tRender_Width]
	push	0
	push	0
	call	dword [bb_tRender+56]
	add	esp,20
	jmp	_560
_559:
	push	1
	push	dword [_bb_tRender_Height]
	push	dword [_bb_tRender_Width]
	push	0
	push	0
	call	dword [bb_tRender+56]
	add	esp,20
_560:
	push	brl_glmax2d_TGLImageFrame
	push	0
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [_bb_tRender_GLFrame]
	dec	dword [eax+4]
	jnz	_565
	push	eax
	call	bbGCFree
	add	esp,4
_565:
	mov	dword [_bb_tRender_GLFrame],ebx
	mov	eax,1
	jmp	_285
_285:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_Cls:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	edx,dword [ebp+8]
	mov	eax,edx
	shr	eax,16
	and	eax,255
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	mov	eax,edx
	shr	eax,8
	and	eax,255
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	mov	eax,edx
	and	eax,255
	mov	dword [ebp+-4],eax
	fild	dword [ebp+-4]
	shr	edx,24
	and	edx,255
	mov	dword [ebp+-4],edx
	fild	dword [ebp+-4]
	fdiv	dword [_803]
	sub	esp,4
	fstp	dword [esp]
	fdiv	dword [_804]
	sub	esp,4
	fstp	dword [esp]
	fdiv	dword [_805]
	sub	esp,4
	fstp	dword [esp]
	fdiv	dword [_806]
	sub	esp,4
	fstp	dword [esp]
	call	glClearColor
	add	esp,16
	push	16384
	call	glClear
	add	esp,4
	mov	eax,0
	jmp	_288
_288:
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_Pow2Size:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,1
	jmp	_60
_62:
	shl	eax,1
_60:
	cmp	eax,edx
	jl	_62
_61:
	jmp	_291
_291:
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_TextureRender_End:
	push	ebp
	mov	ebp,esp
	push	1065353216
	push	1065353216
	call	brl_max2d_SetScale
	add	esp,8
	mov	eax,dword [_bb_tRender_GLFrame]
	push	dword [eax+32]
	push	3553
	call	glBindTexture
	add	esp,8
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
	push	0
	push	3553
	call	glBindTexture
	add	esp,8
	push	0
	call	brl_graphics_GraphicsHeight
	push	eax
	call	brl_graphics_GraphicsWidth
	push	eax
	push	0
	push	0
	call	dword [bb_tRender+56]
	add	esp,20
	push	0
	push	1065353216
	push	1065353216
	push	-990248960
	push	-990248960
	push	dword [_bb_tRender_Image]
	call	brl_max2d_DrawImageRect
	add	esp,24
	mov	eax,1
	jmp	_293
_293:
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_BackBufferRender_Begin:
	push	ebp
	mov	ebp,esp
	push	0
	call	brl_graphics_GraphicsHeight
	push	eax
	call	brl_graphics_GraphicsWidth
	push	eax
	push	0
	push	0
	call	dword [bb_tRender+56]
	add	esp,20
	mov	eax,1
	jmp	_295
_295:
	mov	esp,ebp
	pop	ebp
	ret
_bb_tRender_BackBufferRender_End:
	push	ebp
	mov	ebp,esp
	push	0
	push	3553
	call	glBindTexture
	add	esp,8
	mov	eax,1
	jmp	_297
_297:
	mov	esp,ebp
	pop	ebp
	ret
bb_ColorizedImage:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	push	edi
	push	1
	push	1
	push	0
	push	dword [ebp+8]
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp-8]
	cmp	dword [eax+24],6
	je	_572
	mov	eax,dword [ebp-8]
	push	6
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
_572:
	push	0
	push	dword [ebp+8]
	call	brl_max2d_UnlockImage
	add	esp,8
	mov	eax,dword [ebp-8]
	push	0
	push	0
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,12
	mov	esi,eax
	mov	dword [ebp-4],esi
	mov	edi,0
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+12]
	mov	edx,dword [ebp-8]
	imul	eax,dword [edx+16]
	mov	dword [ebp-12],eax
	jmp	_578
_65:
	push	dword [esi]
	call	bb_isMonochrome
	add	esp,4
	mov	ebx,eax
	cmp	ebx,0
	jle	_581
	cmp	dword [esi],0
	je	_582
	mov	dword [ebp+-16],ebx
	fild	dword [ebp+-16]
	fmul	dword [ebp+20]
	fdiv	dword [_821]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	dword [ebp+-16],ebx
	fild	dword [ebp+-16]
	fmul	dword [ebp+16]
	fdiv	dword [_822]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	dword [ebp+-16],ebx
	fild	dword [ebp+-16]
	fmul	dword [ebp+12]
	fdiv	dword [_823]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	dword [esi]
	call	bb_ARGB_Alpha
	add	esp,4
	push	eax
	call	bb_ARGB_Color
	add	esp,16
	mov	dword [esi],eax
_582:
_581:
	add	esi,4
	mov	edx,dword [ebp-4]
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+20]
	shr	eax,2
	shl	eax,2
	add	edx,eax
	cmp	esi,edx
	jne	_583
	mov	dword [ebp-4],esi
_583:
_63:
	add	edi,1
_578:
	cmp	edi,dword [ebp-12]
	jle	_65
_64:
	mov	eax,dword [ebp+8]
	mov	edx,dword [eax+12]
	mov	eax,dword [ebp-8]
	mov	dword [eax+16],edx
	mov	eax,dword [ebp+8]
	mov	edx,dword [eax+8]
	mov	eax,dword [ebp-8]
	mov	dword [eax+12],edx
	push	-1
	push	dword [ebp-8]
	call	brl_max2d_LoadImage
	add	esp,8
	jmp	_303
_303:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_ColorizePixmap:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	push	edi
	cmp	dword [ebp+8],bbNullObject
	je	_584
	push	1
	push	1
	push	dword [ebp+12]
	push	dword [ebp+8]
	call	brl_max2d_LockImage
	add	esp,16
	mov	ebx,eax
	cmp	dword [ebx+24],6
	je	_586
	push	6
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
_586:
	push	1
	push	dword [ebx+24]
	push	dword [ebx+16]
	push	dword [ebx+12]
	call	dword [brl_pixmap_TPixmap+80]
	add	esp,16
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp-8]
	push	0
	push	0
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,12
	mov	esi,eax
	mov	dword [ebp-4],esi
	mov	edi,0
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+12]
	mov	edx,dword [ebp-8]
	imul	eax,dword [edx+16]
	mov	dword [ebp-12],eax
	jmp	_594
_68:
	push	dword [esi]
	call	bb_isMonochrome
	add	esp,4
	mov	ebx,eax
	cmp	ebx,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_597
	mov	eax,dword [esi]
	cmp	eax,0
	setne	al
	movzx	eax,al
_597:
	cmp	eax,0
	je	_599
	mov	dword [ebp+-16],ebx
	fild	dword [ebp+-16]
	fmul	dword [ebp+24]
	fdiv	dword [_831]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	dword [ebp+-16],ebx
	fild	dword [ebp+-16]
	fmul	dword [ebp+20]
	fdiv	dword [_832]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	mov	dword [ebp+-16],ebx
	fild	dword [ebp+-16]
	fmul	dword [ebp+16]
	fdiv	dword [_833]
	sub	esp,8
	fstp	qword [esp]
	call	bbFloatToInt
	add	esp,8
	push	eax
	push	dword [esi]
	call	bb_ARGB_Alpha
	add	esp,4
	push	eax
	call	bb_ARGB_Color
	add	esp,16
	mov	dword [esi],eax
_599:
	add	esi,4
	mov	edx,dword [ebp-4]
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+20]
	shr	eax,2
	shl	eax,2
	add	edx,eax
	cmp	esi,edx
	jne	_600
	mov	dword [ebp-4],esi
_600:
_66:
	add	edi,1
_594:
	cmp	edi,dword [ebp-12]
	jle	_68
_67:
	push	dword [ebp+12]
	push	dword [ebp+8]
	call	brl_max2d_UnlockImage
	add	esp,8
	mov	eax,dword [ebp-8]
	jmp	_310
_584:
	mov	eax,bbNullObject
	jmp	_310
_310:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_ColorizeImage:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	push	1
	push	1
	push	0
	mov	eax,dword [ebp+20]
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	mov	dword [ebp+-8],ebx
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	mov	dword [ebp+-8],esi
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	push	-1
	push	edi
	call	brl_max2d_LoadImage
	add	esp,8
	push	eax
	call	bb_ColorizedImage
	add	esp,16
	push	eax
	call	brl_max2d_LockImage
	add	esp,16
	mov	dword [ebp-4],eax
	push	0
	mov	eax,dword [ebp+20]
	mov	dword [ebp+-8],eax
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	mov	dword [ebp+-8],ebx
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	mov	dword [ebp+-8],esi
	fild	dword [ebp+-8]
	sub	esp,4
	fstp	dword [esp]
	push	-1
	push	edi
	call	brl_max2d_LoadImage
	add	esp,8
	push	eax
	call	bb_ColorizedImage
	add	esp,16
	push	eax
	call	brl_max2d_UnlockImage
	add	esp,8
	mov	eax,dword [ebp-4]
	jmp	_316
_316:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_CopyImage:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	cmp	dword [ebp-8],bbNullObject
	jne	_602
	mov	eax,bbNullObject
	jmp	_319
_602:
	push	brl_max2d_TImage
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-4],eax
	push	44
	mov	eax,dword [ebp-8]
	lea	eax,dword [eax+8]
	push	eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	push	eax
	call	bbMemCopy
	add	esp,12
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+40]
	push	dword [eax+20]
	push	_604
	call	bbArrayNew1D
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+40]
	dec	dword [eax+4]
	jnz	_608
	push	eax
	call	bbGCFree
	add	esp,4
_608:
	mov	eax,dword [ebp-4]
	mov	dword [eax+40],ebx
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+44]
	push	dword [eax+20]
	push	_609
	call	bbArrayNew1D
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+44]
	dec	dword [eax+4]
	jnz	_613
	push	eax
	call	bbGCFree
	add	esp,4
_613:
	mov	eax,dword [ebp-4]
	mov	dword [eax+44],ebx
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+48]
	push	dword [eax+20]
	push	_614
	call	bbArrayNew1D
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+48]
	dec	dword [eax+4]
	jnz	_618
	push	eax
	call	bbGCFree
	add	esp,4
_618:
	mov	eax,dword [ebp-4]
	mov	dword [eax+48],ebx
	mov	esi,0
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+40]
	mov	eax,dword [eax+20]
	sub	eax,1
	mov	edi,eax
	jmp	_620
_71:
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+40]
	push	dword [eax+esi*4+24]
	call	brl_pixmap_CopyPixmap
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+40]
	mov	eax,dword [eax+esi*4+24]
	dec	dword [eax+4]
	jnz	_625
	push	eax
	call	bbGCFree
	add	esp,4
_625:
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+40]
	mov	dword [eax+esi*4+24],ebx
_69:
	add	esi,1
_620:
	cmp	esi,edi
	jle	_71
_70:
	mov	esi,0
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+44]
	mov	ebx,dword [eax+20]
	sub	ebx,1
	jmp	_627
_74:
	mov	eax,dword [ebp-4]
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,8
_72:
	add	esi,1
_627:
	cmp	esi,ebx
	jle	_74
_73:
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+48]
	push	dword [eax+16]
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+48]
	lea	eax,byte [eax+24]
	push	eax
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+48]
	lea	eax,byte [eax+24]
	push	eax
	call	bbMemCopy
	add	esp,12
	mov	eax,dword [ebp-4]
	jmp	_319
_319:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
bb_ColorizeTImage:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	cmp	ebx,bbNullObject
	je	_630
	mov	edx,dword [ebp+12]
	mov	eax,dword [ebp+20]
	mov	dword [ebp+12],eax
	mov	dword [ebp+20],edx
	push	1
	push	1
	push	0
	push	ebx
	call	brl_max2d_LockImage
	add	esp,16
	mov	esi,eax
	cmp	dword [esi+24],6
	je	_633
	push	6
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
_633:
	push	1
	push	dword [esi+24]
	push	dword [ebx+12]
	push	dword [ebx+8]
	call	dword [brl_pixmap_TPixmap+80]
	add	esp,16
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+60]
	add	esp,4
	mov	dword [ebp-12],eax
	push	0
	push	ebx
	call	brl_max2d_UnlockImage
	add	esp,8
	mov	eax,dword [ebp-12]
	push	0
	push	0
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,12
	mov	ebx,eax
	mov	dword [ebp-4],ebx
	mov	edi,0
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+12]
	mov	edx,dword [ebp-12]
	imul	eax,dword [edx+16]
	mov	dword [ebp-8],eax
	jmp	_641
_77:
	push	dword [ebx]
	call	bb_isMonochrome
	add	esp,4
	mov	ecx,eax
	cmp	ecx,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_644
	mov	eax,dword [ebx]
	cmp	eax,0
	setne	al
	movzx	eax,al
_644:
	cmp	eax,0
	je	_646
	mov	esi,255
	mov	eax,ecx
	imul	eax,dword [ebp+20]
	cdq
	idiv	esi
	push	eax
	mov	esi,255
	mov	eax,ecx
	imul	eax,dword [ebp+16]
	cdq
	idiv	esi
	push	eax
	mov	esi,255
	mov	eax,ecx
	imul	eax,dword [ebp+12]
	cdq
	idiv	esi
	push	eax
	push	dword [ebx]
	call	bb_ARGB_Alpha
	add	esp,4
	push	eax
	call	bb_ARGB_Color
	add	esp,16
	mov	dword [ebx],eax
_646:
	add	ebx,4
	mov	edx,dword [ebp-4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+20]
	shr	eax,2
	shl	eax,2
	add	edx,eax
	cmp	ebx,edx
	jne	_647
	mov	dword [ebp-4],ebx
_647:
_75:
	add	edi,1
_641:
	cmp	edi,dword [ebp-8]
	jle	_77
_76:
	mov	eax,dword [ebp+24]
	cmp	eax,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_648
	mov	eax,dword [ebp+36]
	cmp	eax,0
	setg	al
	movzx	eax,al
_648:
	cmp	eax,0
	je	_650
	mov	eax,dword [ebp+44]
_650:
	cmp	eax,0
	je	_652
	push	dword [ebp+40]
	push	dword [ebp+36]
	push	dword [ebp+32]
	push	dword [ebp+28]
	push	dword [ebp+24]
	push	dword [ebp-12]
	call	brl_max2d_LoadAnimImage
	add	esp,24
	jmp	_331
_652:
	push	-1
	push	dword [ebp-12]
	call	brl_max2d_LoadImage
	add	esp,8
	jmp	_331
_630:
	mov	eax,bbNullObject
	jmp	_331
_331:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_336:
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
	db	"Delete",0
_90:
	db	"create",0
_91:
	db	"(:brl.pixmap.TPixmap,f,f,f,f):ImageFragment",0
_92:
	db	"render",0
_93:
	db	"(f,f,f)i",0
_94:
	db	"renderInViewPort",0
_95:
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
	dd	6
	dd	_89
	dd	_88
	dd	20
	dd	7
	dd	_90
	dd	_91
	dd	48
	dd	6
	dd	_92
	dd	_93
	dd	52
	dd	6
	dd	_94
	dd	_95
	dd	56
	dd	0
	align	4
bb_ImageFragment:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_78
	dd	28
	dd	_bb_ImageFragment_New
	dd	_bb_ImageFragment_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_ImageFragment_create
	dd	_bb_ImageFragment_render
	dd	_bb_ImageFragment_renderInViewPort
_97:
	db	"TBigImage",0
_98:
	db	"pixmap",0
_99:
	db	":brl.pixmap.TPixmap",0
_100:
	db	"px",0
_101:
	db	"py",0
_102:
	db	"fragments",0
_103:
	db	":brl.linkedlist.TList",0
_104:
	db	"width",0
_105:
	db	"height",0
_106:
	db	"PixFormat",0
_107:
	db	"i",0
_108:
	db	"CreateFromImage",0
_109:
	db	"(:brl.max2d.TImage):TBigImage",0
_110:
	db	"CreateFromPixmap",0
_111:
	db	"(:brl.pixmap.TPixmap):TBigImage",0
_112:
	db	"RestorePixmap",0
_113:
	db	"():brl.pixmap.TPixmap",0
_114:
	db	"Load",0
	align	4
_96:
	dd	2
	dd	_97
	dd	3
	dd	_98
	dd	_99
	dd	8
	dd	3
	dd	_100
	dd	_83
	dd	12
	dd	3
	dd	_101
	dd	_83
	dd	16
	dd	3
	dd	_102
	dd	_103
	dd	20
	dd	3
	dd	_104
	dd	_83
	dd	24
	dd	3
	dd	_105
	dd	_83
	dd	28
	dd	3
	dd	_106
	dd	_107
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
	dd	6
	dd	_89
	dd	_88
	dd	20
	dd	7
	dd	_108
	dd	_109
	dd	48
	dd	7
	dd	_110
	dd	_111
	dd	52
	dd	7
	dd	_90
	dd	_111
	dd	56
	dd	6
	dd	_112
	dd	_113
	dd	60
	dd	6
	dd	_114
	dd	_88
	dd	64
	dd	6
	dd	_92
	dd	_93
	dd	68
	dd	6
	dd	_94
	dd	_95
	dd	72
	dd	0
	align	4
bb_TBigImage:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_96
	dd	44
	dd	_bb_TBigImage_New
	dd	_bb_TBigImage_Delete
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
	align	4
_bb_tRender_GLFrame:
	dd	bbNullObject
	align	4
_bb_tRender_DX:
	dd	0
	align	4
_334:
	dd	0
	align	4
_bb_tRender_Image:
	dd	bbNullObject
	align	4
_bb_tRender_Width:
	dd	0
	align	4
_bb_tRender_Height:
	dd	0
	align	4
_bb_tRender_o_r:
	dd	0
	align	4
_bb_tRender_o_g:
	dd	0
	align	4
_bb_tRender_o_b:
	dd	0
_116:
	db	"tRender",0
_117:
	db	"Initialise",0
_118:
	db	"Create",0
_119:
	db	"(i,i,i):brl.max2d.TImage",0
_120:
	db	"ViewportSet",0
_121:
	db	"(i,i,i,i,b)i",0
_122:
	db	"TextureRender_Begin",0
_123:
	db	"(:brl.max2d.TImage,b)i",0
_124:
	db	"Cls",0
_125:
	db	"(i)i",0
_126:
	db	"Pow2Size",0
_127:
	db	"TextureRender_End",0
_128:
	db	"BackBufferRender_Begin",0
_129:
	db	"BackBufferRender_End",0
	align	4
_115:
	dd	2
	dd	_116
	dd	6
	dd	_87
	dd	_88
	dd	16
	dd	6
	dd	_89
	dd	_88
	dd	20
	dd	7
	dd	_117
	dd	_88
	dd	48
	dd	7
	dd	_118
	dd	_119
	dd	52
	dd	7
	dd	_120
	dd	_121
	dd	56
	dd	7
	dd	_122
	dd	_123
	dd	60
	dd	7
	dd	_124
	dd	_125
	dd	64
	dd	7
	dd	_126
	dd	_125
	dd	68
	dd	7
	dd	_127
	dd	_88
	dd	72
	dd	7
	dd	_128
	dd	_88
	dd	76
	dd	7
	dd	_129
	dd	_88
	dd	80
	dd	0
	align	4
bb_tRender:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_115
	dd	8
	dd	_bb_tRender_New
	dd	_bb_tRender_Delete
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
bb_tRenderERROR:
	dd	bbEmptyString
	align	4
_662:
	dd	0x0
	align	4
_663:
	dd	0x0
	align	4
_664:
	dd	0x0
	align	4
_665:
	dd	0x0
	align	4
_6:
	dd	bbStringClass
	dd	2147483647
	dd	18
	dw	105,109,97,103,101,32,100,111,101,115,110,116,32,101,120,105
	dw	115,116
	align	4
_682:
	dd	0x437f0000
	align	4
_683:
	dd	0x0
	align	4
_697:
	dd	0x437f0000
	align	4
_698:
	dd	0x437f0000
	align	4
_699:
	dd	0x437f0000
	align	4
_700:
	dd	0x437f0000
	align	4
_701:
	dd	0x437f0000
	align	4
_702:
	dd	0x437f0000
	align	4
_712:
	dd	0x3f800000
	align	4
_713:
	dd	0x3f800000
	align	4
_714:
	dd	0x3f800000
	align	4
_752:
	dd	0x0
	align	4
_753:
	dd	0x0
	align	4
_754:
	dd	0x43800000
	align	4
_755:
	dd	0x43800000
	align	4
_756:
	dd	0x43800000
	align	4
_757:
	dd	0x0
	align	4
_758:
	dd	0x43800000
	align	4
_55:
	dd	bbStringClass
	dd	2147483647
	dd	24
	dw	68,68,69,82,82,95,73,78,86,65,76,73,68,83,85,82
	dw	70,65,67,69,84,89,80,69
	align	4
_56:
	dd	bbStringClass
	dd	2147483647
	dd	19
	dw	68,68,69,82,82,95,73,78,86,65,76,73,68,80,65,82
	dw	65,77,83
	align	4
_57:
	dd	bbStringClass
	dd	2147483647
	dd	19
	dw	68,68,69,82,82,95,73,78,86,65,76,73,68,79,66,74
	dw	69,67,84
	align	4
_58:
	dd	bbStringClass
	dd	2147483647
	dd	14
	dw	68,68,69,82,82,95,78,79,84,70,79,85,78,68
	align	4
_59:
	dd	bbStringClass
	dd	2147483647
	dd	17
	dw	68,68,69,82,82,95,83,85,82,70,65,67,69,76,79,83
	dw	84
_527:
	db	":brl.pixmap.TPixmap",0
_532:
	db	":brl.max2d.TImageFrame",0
_537:
	db	"i",0
	align	8
_793:
	dd	0x0,0xbff00000
	align	4
_803:
	dd	0x437f0000
	align	4
_804:
	dd	0x437f0000
	align	4
_805:
	dd	0x437f0000
	align	4
_806:
	dd	0x437f0000
	align	4
_821:
	dd	0x42c80000
	align	4
_822:
	dd	0x42c80000
	align	4
_823:
	dd	0x42c80000
	align	4
_831:
	dd	0x437f0000
	align	4
_832:
	dd	0x437f0000
	align	4
_833:
	dd	0x437f0000
_604:
	db	":brl.pixmap.TPixmap",0
_609:
	db	":brl.max2d.TImageFrame",0
_614:
	db	"i",0
