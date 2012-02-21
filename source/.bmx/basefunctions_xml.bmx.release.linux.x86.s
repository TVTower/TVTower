	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_source_basefunctions_zip
	extrn	bbEmptyString
	extrn	bbExThrow
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
	extrn	bbStringConcat
	extrn	bbStringFromChar
	extrn	bbStringFromInt
	extrn	bbStringSlice
	extrn	bbStringToLower
	extrn	bb_ZipWriter
	extrn	brl_bank_TBank
	extrn	brl_filesystem_DeleteFile
	extrn	brl_linkedlist_TList
	extrn	brl_retro_Trim
	extrn	brl_standardio_Print
	extrn	brl_stream_OpenStream
	public	__bb_source_basefunctions_xml
	public	_bb_xmlAttribute_Delete
	public	_bb_xmlAttribute_Free
	public	_bb_xmlAttribute_New
	public	_bb_xmlAttribute_NextAttr
	public	_bb_xmlAttribute_PrevAttr
	public	_bb_xmlDocument_Clear
	public	_bb_xmlDocument_Create
	public	_bb_xmlDocument_Delete
	public	_bb_xmlDocument_Load
	public	_bb_xmlDocument_New
	public	_bb_xmlDocument_NodeCount
	public	_bb_xmlDocument_Root
	public	_bb_xmlDocument_Save
	public	_bb_xmlDocument_SetEncryptionKey
	public	_bb_xmlNode_AddNode
	public	_bb_xmlNode_Attribute
	public	_bb_xmlNode_ChildCount
	public	_bb_xmlNode_CleanAttributes
	public	_bb_xmlNode_Copy
	public	_bb_xmlNode_CopyChildrenTo
	public	_bb_xmlNode_CopyTo
	public	_bb_xmlNode_Delete
	public	_bb_xmlNode_FindChild
	public	_bb_xmlNode_FindChildEx
	public	_bb_xmlNode_FindSibling
	public	_bb_xmlNode_FirstAttribute
	public	_bb_xmlNode_FirstChild
	public	_bb_xmlNode_FirstSibling
	public	_bb_xmlNode_Free
	public	_bb_xmlNode_FreeChildren
	public	_bb_xmlNode_GetChild
	public	_bb_xmlNode_GetIndex
	public	_bb_xmlNode_GetSibling
	public	_bb_xmlNode_HasAttribute
	public	_bb_xmlNode_HasAttributes
	public	_bb_xmlNode_HasChildren
	public	_bb_xmlNode_IsRoot
	public	_bb_xmlNode_LastAttribute
	public	_bb_xmlNode_LastChild
	public	_bb_xmlNode_LastSibling
	public	_bb_xmlNode_MoveChildrenTo
	public	_bb_xmlNode_MoveTo
	public	_bb_xmlNode_New
	public	_bb_xmlNode_NextSibling
	public	_bb_xmlNode_PrevSibling
	public	_bb_xmlNode_SetIndex
	public	_bb_xmlNode_SiblingCount
	public	_bb_xmlNode_SortChildren
	public	_bb_xmlNode_SortChildrenEx
	public	_bb_xmlNode_SwapWith
	public	_bb_xmlNode__UpdateVars
	public	bb_xmlAttribute
	public	bb_xmlDocument
	public	bb_xmlNode
	section	"code" executable
__bb_source_basefunctions_xml:
	push	ebp
	mov	ebp,esp
	cmp	dword [_594],0
	je	_595
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_595:
	mov	dword [_594],1
	call	__bb_blitz_blitz
	call	__bb_source_basefunctions_zip
	push	bb_xmlDocument
	call	bbObjectRegisterType
	add	esp,4
	push	bb_xmlNode
	call	bbObjectRegisterType
	add	esp,4
	push	bb_xmlAttribute
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,0
	jmp	_358
_358:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_xmlDocument
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,0
	jmp	_361
_361:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
_364:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_600
	push	eax
	call	bbGCFree
	add	esp,4
_600:
	mov	eax,0
	jmp	_598
_598:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	movzx	eax,byte [ebp+12]
	mov	eax,eax
	mov	byte [ebp-4],al
	push	bb_xmlDocument
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	cmp	esi,_1
	je	_602
	movzx	eax,byte [ebp-4]
	push	eax
	push	esi
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
_602:
	mov	eax,ebx
	jmp	_368
_368:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Root:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	cmp	dword [esi+8],bbNullObject
	jne	_604
	push	bb_xmlNode
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_608
	push	eax
	call	bbGCFree
	add	esp,4
_608:
	mov	dword [esi+8],ebx
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+8]
	mov	eax,dword [eax+24]
	dec	dword [eax+4]
	jnz	_612
	push	eax
	call	bbGCFree
	add	esp,4
_612:
	mov	eax,dword [esi+8]
	mov	dword [eax+24],ebx
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+8]
	mov	eax,dword [eax+28]
	dec	dword [eax+4]
	jnz	_616
	push	eax
	call	bbGCFree
	add	esp,4
_616:
	mov	eax,dword [esi+8]
	mov	dword [eax+28],ebx
	mov	eax,dword [esi+8]
	mov	dword [eax+20],0
	mov	ebx,bbNullObject
	inc	dword [ebx+4]
	mov	eax,dword [esi+8]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_620
	push	eax
	call	bbGCFree
	add	esp,4
_620:
	mov	eax,dword [esi+8]
	mov	dword [eax+16],ebx
	mov	ebx,_3
	inc	dword [ebx+4]
	mov	eax,dword [esi+8]
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_624
	push	eax
	call	bbGCFree
	add	esp,4
_624:
	mov	eax,dword [esi+8]
	mov	dword [eax+8],ebx
	mov	ebx,_1
	inc	dword [ebx+4]
	mov	eax,dword [esi+8]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_628
	push	eax
	call	bbGCFree
	add	esp,4
_628:
	mov	eax,dword [esi+8]
	mov	dword [eax+12],ebx
	inc	dword [esi+4]
	mov	ebx,esi
	mov	eax,dword [esi+8]
	mov	eax,dword [eax+36]
	dec	dword [eax+4]
	jnz	_632
	push	eax
	call	bbGCFree
	add	esp,4
_632:
	mov	eax,dword [esi+8]
	mov	dword [eax+36],ebx
_604:
	mov	eax,dword [esi+8]
	jmp	_371
_371:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Load:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+12]
	movzx	eax,byte [ebp+16]
	mov	eax,eax
	mov	byte [ebp-4],al
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_635
	push	bbStringClass
	push	esi
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_637
	mov	eax,bbEmptyString
_637:
	push	0
	push	1
	push	_5
	push	eax
	push	_4
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_stream_OpenStream
	add	esp,12
	mov	ebx,eax
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	push	eax
	call	bbStringFromInt
	add	esp,4
	push	eax
	call	brl_standardio_Print
	add	esp,4
	jmp	_639
_635:
	push	0
	push	1
	push	esi
	call	brl_stream_OpenStream
	add	esp,12
	mov	ebx,eax
_639:
	mov	edi,1
	cmp	ebx,bbNullObject
	jne	_640
	push	bbStringClass
	push	esi
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_642
	mov	eax,bbEmptyString
_642:
	push	_7
	push	eax
	push	_6
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_640:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,216
	jne	_644
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,241
	jne	_646
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,188
	jne	_648
	mov	edi,2
_648:
_646:
_644:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	mov	eax,edi
	cmp	eax,1
	je	_652
	cmp	eax,2
	je	_653
	jmp	_651
_652:
	movzx	eax,byte [ebp-4]
	push	eax
	push	esi
	call	_204
	add	esp,8
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	bbNullObject
	push	dword [ebp+8]
	call	_205
	add	esp,8
	jmp	_651
_653:
	push	esi
	call	_195
	add	esp,4
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	bbNullObject
	push	dword [ebp+8]
	call	_197
	add	esp,8
	jmp	_651
_651:
	cmp	esi,_8
	jne	_656
	push	_8
	call	brl_filesystem_DeleteFile
	add	esp,4
	cmp	eax,0
	jne	_657
	push	_9
	call	brl_standardio_Print
	add	esp,4
_657:
_656:
	mov	eax,0
	jmp	_376
_376:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Save:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+16]
	movzx	eax,byte [ebp+20]
	mov	eax,eax
	mov	byte [ebp-4],al
	push	bb_ZipWriter
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-8],eax
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_660
	mov	dword [ebp+12],_8
_660:
	push	1
	push	0
	push	dword [ebp+12]
	call	brl_stream_OpenStream
	add	esp,12
	mov	ebx,eax
	mov	eax,esi
	cmp	eax,1
	je	_663
	cmp	eax,2
	je	_664
	jmp	_662
_663:
	mov	eax,ebx
	push	_10
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+144]
	add	esp,8
	cmp	dword [edi+8],bbNullObject
	je	_666
	push	dword [edi+8]
	push	ebx
	call	_175
	add	esp,8
_666:
	jmp	_662
_664:
	mov	eax,ebx
	push	216
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+96]
	add	esp,8
	mov	eax,ebx
	push	241
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+96]
	add	esp,8
	mov	eax,ebx
	push	188
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+96]
	add	esp,8
	cmp	dword [edi+8],bbNullObject
	je	_670
	push	dword [edi+8]
	push	ebx
	call	_188
	add	esp,8
_670:
	jmp	_662
_662:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_672
	mov	eax,dword [ebp-8]
	push	0
	push	_11
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+76]
	add	esp,12
	cmp	eax,0
	je	_674
	mov	ebx,dword [ebp-8]
	push	bbStringClass
	push	dword [ebp+12]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_677
	mov	eax,bbEmptyString
_677:
	push	_1
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,12
	mov	eax,dword [ebp-8]
	push	_1
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+92]
	add	esp,8
_674:
	push	1
	push	0
	push	dword [ebp+12]
	call	brl_stream_OpenStream
	add	esp,12
	mov	ebx,eax
	mov	eax,ebx
	push	0
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+96]
	add	esp,8
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
_672:
	mov	eax,0
	jmp	_382
_382:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_NodeCount:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	_266
	add	esp,4
	jmp	_385
_385:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_SetEncryptionKey:
	push	ebp
	mov	ebp,esp
	mov	eax,0
	jmp	_389
_389:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Clear:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	cmp	dword [eax+8],bbNullObject
	je	_682
	mov	eax,dword [eax+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+80]
	add	esp,4
_682:
	mov	eax,0
	jmp	_392
_392:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_xmlNode
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	dword [ebx+20],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+24],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+28],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+32],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+36],eax
	mov	eax,0
	jmp	_395
_395:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_398:
	mov	eax,dword [ebx+36]
	dec	dword [eax+4]
	jnz	_693
	push	eax
	call	bbGCFree
	add	esp,4
_693:
	mov	eax,dword [ebx+32]
	dec	dword [eax+4]
	jnz	_695
	push	eax
	call	bbGCFree
	add	esp,4
_695:
	mov	eax,dword [ebx+28]
	dec	dword [eax+4]
	jnz	_697
	push	eax
	call	bbGCFree
	add	esp,4
_697:
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_699
	push	eax
	call	bbGCFree
	add	esp,4
_699:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_701
	push	eax
	call	bbGCFree
	add	esp,4
_701:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_703
	push	eax
	call	bbGCFree
	add	esp,4
_703:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_705
	push	eax
	call	bbGCFree
	add	esp,4
_705:
	mov	eax,0
	jmp	_691
_691:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_AddNode:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	push	bb_xmlNode
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_710
	push	eax
	call	bbGCFree
	add	esp,4
_710:
	mov	dword [ebx+24],esi
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+28]
	dec	dword [eax+4]
	jnz	_714
	push	eax
	call	bbGCFree
	add	esp,4
_714:
	mov	dword [ebx+28],esi
	mov	eax,dword [edi+36]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+36]
	dec	dword [eax+4]
	jnz	_718
	push	eax
	call	bbGCFree
	add	esp,4
_718:
	mov	dword [ebx+36],esi
	mov	eax,dword [ebp+12]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_722
	push	eax
	call	bbGCFree
	add	esp,4
_722:
	mov	dword [ebx+8],esi
	mov	eax,_1
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_726
	push	eax
	call	bbGCFree
	add	esp,4
_726:
	mov	dword [ebx+12],esi
	mov	eax,dword [ebp+16]
	cmp	eax,1
	je	_729
	cmp	eax,2
	je	_730
	jmp	_728
_729:
	mov	esi,edi
	inc	dword [esi+4]
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_734
	push	eax
	call	bbGCFree
	add	esp,4
_734:
	mov	dword [ebx+16],esi
	mov	eax,dword [ebx+16]
	mov	eax,dword [eax+28]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+32]
	dec	dword [eax+4]
	jnz	_739
	push	eax
	call	bbGCFree
	add	esp,4
_739:
	mov	dword [ebx+32],esi
	jmp	_728
_730:
	cmp	dword [edi+16],bbNullObject
	jne	_740
	push	_13
	push	dword [ebp+12]
	push	_12
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_740:
	mov	eax,dword [edi+16]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_744
	push	eax
	call	bbGCFree
	add	esp,4
_744:
	mov	dword [ebx+16],esi
	mov	eax,dword [ebx+16]
	mov	eax,dword [eax+28]
	push	dword [edi+32]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+100]
	add	esp,12
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+32]
	dec	dword [eax+4]
	jnz	_749
	push	eax
	call	bbGCFree
	add	esp,4
_749:
	mov	dword [ebx+32],esi
	jmp	_728
_728:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+184]
	add	esp,4
	mov	eax,ebx
	jmp	_403
_403:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_MoveTo:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+16]
	cmp	dword [edi+16],bbNullObject
	jne	_752
	cmp	esi,1
	jne	_753
	push	_14
	call	bbExThrow
	add	esp,4
_753:
	cmp	esi,2
	jne	_754
	push	_15
	call	bbExThrow
	add	esp,4
_754:
_752:
	cmp	dword [ebp+12],edi
	jne	_755
	mov	eax,0
	jmp	_408
_755:
	mov	ebx,dword [ebp+12]
_18:
	mov	ebx,dword [ebx+16]
	cmp	ebx,edi
	jne	_756
	cmp	esi,1
	jne	_757
	push	_19
	call	bbExThrow
	add	esp,4
_757:
	cmp	esi,2
	jne	_758
	push	_20
	call	bbExThrow
	add	esp,4
_758:
_756:
_16:
	cmp	ebx,bbNullObject
	jne	_18
_17:
	mov	eax,dword [edi+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
	mov	eax,esi
	cmp	eax,1
	je	_762
	cmp	eax,2
	je	_763
	jmp	_761
_762:
	mov	ebx,dword [ebp+12]
	inc	dword [ebx+4]
	mov	eax,dword [edi+16]
	dec	dword [eax+4]
	jnz	_767
	push	eax
	call	bbGCFree
	add	esp,4
_767:
	mov	dword [edi+16],ebx
	mov	eax,dword [edi+16]
	mov	eax,dword [eax+28]
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [edi+32]
	dec	dword [eax+4]
	jnz	_772
	push	eax
	call	bbGCFree
	add	esp,4
_772:
	mov	dword [edi+32],ebx
	jmp	_761
_763:
	mov	eax,dword [ebp+12]
	cmp	dword [eax+16],bbNullObject
	jne	_773
	push	_21
	call	bbExThrow
	add	esp,4
_773:
	mov	eax,dword [ebp+12]
	mov	ebx,dword [eax+16]
	inc	dword [ebx+4]
	mov	eax,dword [edi+16]
	dec	dword [eax+4]
	jnz	_777
	push	eax
	call	bbGCFree
	add	esp,4
_777:
	mov	dword [edi+16],ebx
	mov	eax,dword [edi+16]
	mov	edx,dword [eax+28]
	mov	eax,dword [ebp+12]
	push	dword [eax+32]
	push	edi
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+100]
	add	esp,12
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [edi+32]
	dec	dword [eax+4]
	jnz	_782
	push	eax
	call	bbGCFree
	add	esp,4
_782:
	mov	dword [edi+32],ebx
	jmp	_761
_761:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+184]
	add	esp,4
	mov	eax,0
	jmp	_408
_408:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_CopyTo:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	mov	edi,dword [ebp+12]
	mov	esi,dword [ebp+16]
	cmp	dword [ebx+16],bbNullObject
	jne	_784
	cmp	esi,1
	jne	_785
	push	_22
	call	bbExThrow
	add	esp,4
_785:
	cmp	esi,2
	jne	_786
	push	_23
	call	bbExThrow
	add	esp,4
_786:
_784:
	cmp	edi,ebx
	jne	_787
	cmp	esi,1
	jne	_788
	push	_24
	call	bbExThrow
	add	esp,4
_788:
	cmp	esi,2
	jne	_789
	push	_25
	call	bbExThrow
	add	esp,4
_789:
_787:
	mov	eax,ebx
	push	bbNullObject
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	mov	ebx,eax
	mov	eax,dword [ebx+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
	mov	eax,esi
	cmp	eax,1
	je	_795
	cmp	eax,2
	je	_796
	jmp	_794
_795:
	mov	esi,edi
	inc	dword [esi+4]
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_800
	push	eax
	call	bbGCFree
	add	esp,4
_800:
	mov	dword [ebx+16],esi
	mov	eax,dword [ebx+16]
	mov	eax,dword [eax+28]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+32]
	dec	dword [eax+4]
	jnz	_805
	push	eax
	call	bbGCFree
	add	esp,4
_805:
	mov	dword [ebx+32],esi
	jmp	_794
_796:
	cmp	dword [edi+16],bbNullObject
	jne	_806
	push	_26
	call	bbExThrow
	add	esp,4
_806:
	mov	eax,dword [edi+16]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_810
	push	eax
	call	bbGCFree
	add	esp,4
_810:
	mov	dword [ebx+16],esi
	mov	eax,dword [ebx+16]
	mov	eax,dword [eax+28]
	push	dword [edi+32]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+100]
	add	esp,12
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+32]
	dec	dword [eax+4]
	jnz	_815
	push	eax
	call	bbGCFree
	add	esp,4
_815:
	mov	dword [ebx+32],esi
	jmp	_794
_794:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+184]
	add	esp,4
	mov	eax,ebx
	jmp	_413
_413:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_Copy:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+12]
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	jne	_817
	push	_27
	call	bbExThrow
	add	esp,4
_817:
	push	bb_xmlNode
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-12],eax
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+28]
	dec	dword [eax+4]
	jnz	_823
	push	eax
	call	bbGCFree
	add	esp,4
_823:
	mov	eax,dword [ebp-12]
	mov	dword [eax+28],esi
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+24]
	dec	dword [eax+4]
	jnz	_827
	push	eax
	call	bbGCFree
	add	esp,4
_827:
	mov	eax,dword [ebp-12]
	mov	dword [eax+24],esi
	mov	eax,dword [ebp+8]
	mov	esi,dword [eax+8]
	inc	dword [esi+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_831
	push	eax
	call	bbGCFree
	add	esp,4
_831:
	mov	eax,dword [ebp-12]
	mov	dword [eax+8],esi
	mov	eax,dword [ebp+8]
	mov	esi,dword [eax+12]
	inc	dword [esi+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_835
	push	eax
	call	bbGCFree
	add	esp,4
_835:
	mov	eax,dword [ebp-12]
	mov	dword [eax+12],esi
	cmp	ebx,bbNullObject
	jne	_836
	mov	eax,dword [ebp+8]
	mov	ebx,dword [eax+16]
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_840
	push	eax
	call	bbGCFree
	add	esp,4
_840:
	mov	eax,dword [ebp-12]
	mov	dword [eax+16],ebx
	jmp	_841
_836:
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_845
	push	eax
	call	bbGCFree
	add	esp,4
_845:
	mov	eax,dword [ebp-12]
	mov	dword [eax+16],ebx
_841:
	mov	eax,dword [ebp+8]
	mov	edx,dword [eax+20]
	mov	eax,dword [ebp-12]
	mov	dword [eax+20],edx
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	dword [ebp-12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+32]
	dec	dword [eax+4]
	jnz	_850
	push	eax
	call	bbGCFree
	add	esp,4
_850:
	mov	eax,dword [ebp-12]
	mov	dword [eax+32],ebx
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+24]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-8],eax
	jmp	_28
_30:
	mov	eax,dword [ebp-8]
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	edi,eax
	cmp	edi,bbNullObject
	je	_28
	push	bb_xmlAttribute
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [edi+8]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_861
	push	eax
	call	bbGCFree
	add	esp,4
_861:
	mov	dword [ebx+8],esi
	mov	eax,dword [edi+12]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_865
	push	eax
	call	bbGCFree
	add	esp,4
_865:
	mov	dword [ebx+12],esi
	mov	eax,dword [edi+16]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_869
	push	eax
	call	bbGCFree
	add	esp,4
_869:
	mov	dword [ebx+16],esi
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+24]
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+20]
	dec	dword [eax+4]
	jnz	_874
	push	eax
	call	bbGCFree
	add	esp,4
_874:
	mov	dword [ebx+20],esi
_28:
	mov	eax,dword [ebp-8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_30
_29:
	mov	eax,dword [ebp+8]
	mov	esi,dword [eax+28]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_31
_33:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_31
	push	dword [ebp-12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
_31:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_33
_32:
	mov	eax,dword [ebp-12]
	jmp	_417
_417:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SwapWith:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	cmp	dword [ebp+12],eax
	jne	_882
	mov	eax,0
	jmp	_421
_882:
	mov	ebx,dword [ebp+12]
_36:
	mov	ebx,dword [ebx+16]
	cmp	ebx,dword [ebp+8]
	jne	_883
	push	_37
	call	bbExThrow
	add	esp,4
_883:
_34:
	cmp	ebx,bbNullObject
	jne	_36
_35:
	mov	ebx,dword [ebp+8]
_40:
	mov	ebx,dword [ebx+16]
	cmp	ebx,dword [ebp+12]
	jne	_884
	push	_41
	call	bbExThrow
	add	esp,4
_884:
_38:
	cmp	ebx,bbNullObject
	jne	_40
_39:
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	edx,dword [eax+16]
	mov	eax,dword [ebp+8]
	cmp	edx,dword [eax+16]
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_889
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+16]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
_889:
	cmp	eax,0
	je	_891
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+32]
	cmp	dword [ebp-4],eax
	jne	_892
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+16]
	mov	edx,dword [eax+28]
	mov	eax,dword [ebp+8]
	push	dword [eax+32]
	push	dword [ebp+12]
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+100]
	add	esp,12
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+32]
	dec	dword [eax+4]
	jnz	_898
	push	eax
	call	bbGCFree
	add	esp,4
_898:
	mov	eax,dword [ebp+12]
	mov	dword [eax+32],ebx
	mov	eax,0
	jmp	_421
_892:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	cmp	dword [ebp-8],eax
	jne	_899
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	mov	edx,dword [eax+28]
	mov	eax,dword [ebp+12]
	push	dword [eax+32]
	push	dword [ebp+8]
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+100]
	add	esp,12
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	dec	dword [eax+4]
	jnz	_905
	push	eax
	call	bbGCFree
	add	esp,4
_905:
	mov	eax,dword [ebp+8]
	mov	dword [eax+32],ebx
	mov	eax,0
	jmp	_421
_899:
_891:
	mov	eax,dword [ebp+12]
	cmp	dword [eax+16],bbNullObject
	je	_906
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
_906:
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	je	_908
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
_908:
	mov	eax,dword [ebp+8]
	mov	edx,dword [eax+16]
	mov	eax,dword [ebp+12]
	cmp	dword [eax+16],edx
	je	_910
	mov	eax,dword [ebp+12]
	mov	esi,dword [eax+20]
	mov	eax,dword [ebp+12]
	mov	edi,dword [eax+16]
	mov	eax,dword [ebp+8]
	mov	edx,dword [eax+20]
	mov	eax,dword [ebp+12]
	mov	dword [eax+20],edx
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_916
	push	eax
	call	bbGCFree
	add	esp,4
_916:
	mov	eax,dword [ebp+12]
	mov	dword [eax+16],ebx
	mov	eax,dword [ebp+8]
	mov	dword [eax+20],esi
	mov	ebx,edi
	inc	dword [ebx+4]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_920
	push	eax
	call	bbGCFree
	add	esp,4
_920:
	mov	eax,dword [ebp+8]
	mov	dword [eax+16],ebx
_910:
	mov	eax,dword [ebp+12]
	cmp	dword [eax+16],bbNullObject
	je	_921
	cmp	dword [ebp-4],bbNullObject
	jne	_922
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+32]
	dec	dword [eax+4]
	jnz	_927
	push	eax
	call	bbGCFree
	add	esp,4
_927:
	mov	eax,dword [ebp+12]
	mov	dword [eax+32],ebx
	jmp	_928
_922:
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	dword [ebp-4]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+100]
	add	esp,12
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+32]
	dec	dword [eax+4]
	jnz	_933
	push	eax
	call	bbGCFree
	add	esp,4
_933:
	mov	eax,dword [ebp+12]
	mov	dword [eax+32],ebx
_928:
_921:
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	je	_934
	cmp	dword [ebp-8],bbNullObject
	jne	_935
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	dec	dword [eax+4]
	jnz	_940
	push	eax
	call	bbGCFree
	add	esp,4
_940:
	mov	eax,dword [ebp+8]
	mov	dword [eax+32],ebx
	jmp	_941
_935:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	dword [ebp-8]
	push	dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+100]
	add	esp,12
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	dec	dword [eax+4]
	jnz	_946
	push	eax
	call	bbGCFree
	add	esp,4
_946:
	mov	eax,dword [ebp+8]
	mov	dword [eax+32],ebx
_941:
_934:
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+184]
	add	esp,4
	mov	eax,dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+184]
	add	esp,4
	mov	eax,0
	jmp	_421
_421:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_GetIndex:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	eax,dword [ebp+8]
	mov	ebx,0
	mov	eax,dword [eax+32]
_44:
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	add	ebx,1
_42:
	cmp	eax,bbNullObject
	jne	_44
_43:
	mov	eax,ebx
	jmp	_424
_424:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SetIndex:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+12]
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	jne	_952
	push	_46
	push	edi
	call	bbStringFromInt
	add	esp,4
	push	eax
	push	_45
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_952:
	cmp	edi,1
	jge	_953
	push	_47
	push	edi
	call	bbStringFromInt
	add	esp,4
	push	eax
	push	_45
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_953:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+88]
	add	esp,4
	mov	ebx,eax
	mov	esi,1
	mov	eax,edi
	sub	eax,1
	mov	edi,eax
	jmp	_957
_50:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	ebx,eax
_48:
	add	esi,1
_957:
	cmp	esi,edi
	jle	_50
_49:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	ebx
	push	dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+96]
	add	esp,12
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+32]
	dec	dword [eax+4]
	jnz	_965
	push	eax
	call	bbGCFree
	add	esp,4
_965:
	mov	eax,dword [ebp+8]
	mov	dword [eax+32],ebx
	mov	eax,0
	jmp	_428
_428:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_IsRoot:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	jne	_966
	mov	eax,1
	jmp	_431
_966:
	mov	eax,0
	jmp	_431
_431:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_Free:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	jmp	_52
_54:
	mov	eax,dword [esi+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+80]
	add	esp,4
_52:
	mov	eax,dword [esi+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_54
_53:
	jmp	_55
_57:
	mov	eax,dword [esi+24]
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
_55:
	mov	eax,dword [esi+24]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_57
_56:
	cmp	dword [esi+16],bbNullObject
	je	_974
	mov	eax,dword [esi+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
_974:
	mov	ebx,bbNullObject
	inc	dword [ebx+4]
	mov	eax,dword [esi+16]
	dec	dword [eax+4]
	jnz	_979
	push	eax
	call	bbGCFree
	add	esp,4
_979:
	mov	dword [esi+16],ebx
	mov	ebx,bbNullObject
	inc	dword [ebx+4]
	mov	eax,dword [esi+32]
	dec	dword [eax+4]
	jnz	_983
	push	eax
	call	bbGCFree
	add	esp,4
_983:
	mov	dword [esi+32],ebx
	mov	eax,0
	jmp	_434
_434:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_HasChildren:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_985
	mov	eax,0
	jmp	_437
_985:
	mov	eax,1
	jmp	_437
_437:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FirstChild:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebx+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_988
	mov	eax,bbNullObject
	jmp	_440
_988:
	mov	eax,dword [ebx+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_440
_440:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_LastChild:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebx+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_992
	mov	eax,bbNullObject
	jmp	_443
_992:
	mov	eax,dword [ebx+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_443
_443:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_GetChild:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	esi,dword [ebp+12]
	cmp	esi,1
	jge	_995
	push	_47
	push	esi
	call	bbStringFromInt
	add	esp,4
	push	eax
	push	_45
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_995:
	mov	eax,dword [ebx+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+88]
	add	esp,4
	mov	ebx,1
	sub	esi,1
	jmp	_999
_60:
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
_58:
	add	ebx,1
_999:
	cmp	ebx,esi
	jle	_60
_59:
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_447
_447:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_ChildCount:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,4
	jmp	_450
_450:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FindChild:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1007
	mov	eax,bbNullObject
	jmp	_456
_1007:
	cmp	dword [ebp+20],0
	je	_1008
	mov	eax,dword [ebp+8]
	mov	ebx,dword [eax+28]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_62
_64:
	mov	eax,edi
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_62
	push	dword [ebp+12]
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1014
	mov	eax,esi
	jmp	_456
_1014:
_62:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_64
_63:
	jmp	_1015
_1008:
	push	dword [ebp+12]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp+12],eax
	mov	eax,dword [ebp+8]
	mov	ebx,dword [eax+28]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_65
_67:
	mov	eax,edi
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_65
	push	dword [ebp+12]
	push	dword [esi+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1021
	mov	eax,esi
	jmp	_456
_1021:
_65:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_67
_66:
_1015:
	cmp	dword [ebp+16],0
	je	_1022
	mov	eax,dword [ebp+8]
	mov	ebx,dword [eax+28]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_68
_70:
	mov	eax,edi
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_68
	mov	eax,dword [esi+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	jne	_1029
	mov	eax,esi
	push	dword [ebp+20]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+104]
	add	esp,16
	cmp	eax,bbNullObject
	je	_1031
	jmp	_456
_1031:
_1029:
_68:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_70
_69:
_1022:
	mov	eax,bbNullObject
	jmp	_456
_456:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FindChildEx:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1036
	mov	eax,bbNullObject
	jmp	_464
_1036:
	cmp	dword [ebp+28],0
	je	_1037
	mov	eax,dword [ebp+8]
	mov	edi,dword [eax+28]
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-4],eax
	jmp	_71
_73:
	mov	eax,dword [ebp-4]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_71
	push	dword [ebp+12]
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1043
	mov	eax,esi
	push	1
	push	dword [ebp+16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+176]
	add	esp,12
	mov	ebx,eax
	cmp	ebx,bbNullObject
	je	_1045
	push	dword [ebp+20]
	push	dword [ebx+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1046
	mov	eax,esi
	jmp	_464
_1046:
_1045:
_1043:
_71:
	mov	eax,dword [ebp-4]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_73
_72:
	jmp	_1047
_1037:
	push	dword [ebp+12]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp+12],eax
	mov	eax,dword [ebp+8]
	mov	edi,dword [eax+28]
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-8],eax
	jmp	_74
_76:
	mov	eax,dword [ebp-8]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_74
	push	dword [ebp+12]
	push	dword [esi+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1053
	mov	eax,esi
	push	0
	push	dword [ebp+16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+176]
	add	esp,12
	mov	ebx,eax
	cmp	ebx,bbNullObject
	je	_1055
	push	dword [ebp+20]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebx+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1056
	mov	eax,esi
	jmp	_464
_1056:
_1055:
_1053:
_74:
	mov	eax,dword [ebp-8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_76
_75:
_1047:
	cmp	dword [ebp+24],0
	je	_1057
	mov	eax,dword [ebp+8]
	mov	ebx,dword [eax+28]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_77
_79:
	mov	eax,edi
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_77
	mov	eax,dword [esi+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	jne	_1064
	mov	eax,esi
	push	dword [ebp+28]
	push	dword [ebp+24]
	push	dword [ebp+20]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+108]
	add	esp,24
	cmp	eax,bbNullObject
	je	_1066
	jmp	_464
_1066:
_1064:
_77:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_79
_78:
_1057:
	mov	eax,bbNullObject
	jmp	_464
_464:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SortChildren:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	mov	eax,dword [eax+8]
	mov	dword [ebp-20],eax
_82:
_80:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	mov	eax,dword [eax+8]
	mov	eax,dword [eax+12]
	mov	dword [ebp-12],eax
	mov	dword [ebp-16],1
_85:
_83:
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp-20]
	cmp	dword [ebp-8],eax
	jne	_1071
	jmp	_84
_1071:
	mov	dword [ebp-4],bbEmptyString
	mov	edi,bbEmptyString
	mov	eax,dword [ebp+12]
	cmp	eax,1
	je	_1078
	cmp	eax,2
	je	_1079
	cmp	eax,3
	je	_1080
	cmp	eax,4
	je	_1081
	jmp	_1077
_1078:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+8]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-4],eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+8]
	call	bbStringToLower
	add	esp,4
	mov	edi,eax
	jmp	_1077
_1079:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+12]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-4],eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+12]
	call	bbStringToLower
	add	esp,4
	mov	edi,eax
	jmp	_1077
_1080:
	mov	dword [ebp-4],_1
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_86
_88:
	mov	eax,esi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_86
	push	dword [eax+8]
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_86:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_88
_87:
	push	dword [ebp-4]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-4],eax
	mov	edi,_1
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	esi,dword [eax+24]
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_89
_91:
	mov	eax,ebx
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_89
	push	dword [eax+8]
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
_89:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_91
_90:
	push	edi
	call	bbStringToLower
	add	esp,4
	mov	edi,eax
	jmp	_1077
_1081:
	mov	dword [ebp-4],_1
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_92
_94:
	mov	eax,esi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_92
	push	dword [eax+12]
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_92:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_94
_93:
	push	dword [ebp-4]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-4],eax
	mov	edi,_1
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	esi,dword [eax+24]
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_95
_97:
	mov	eax,ebx
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_95
	push	dword [eax+12]
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
_95:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_97
_96:
	push	edi
	call	bbStringToLower
	add	esp,4
	mov	edi,eax
	jmp	_1077
_1077:
	push	edi
	push	dword [ebp-4]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_1102
	mov	eax,dword [ebp+20]
_1102:
	cmp	eax,0
	jne	_1106
	push	edi
	push	dword [ebp-4]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_1104
	mov	eax,dword [ebp+20]
	cmp	eax,0
	sete	al
	movzx	eax,al
_1104:
_1106:
	cmp	eax,0
	je	_1108
	mov	eax,dword [ebp-12]
	mov	ebx,dword [eax+16]
	mov	eax,dword [ebp-8]
	mov	edi,dword [eax+12]
	mov	eax,dword [ebp-8]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_1114
	push	eax
	call	bbGCFree
	add	esp,4
_1114:
	mov	dword [ebx+12],esi
	mov	eax,dword [ebp-12]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_1118
	push	eax
	call	bbGCFree
	add	esp,4
_1118:
	mov	eax,dword [ebp-8]
	mov	dword [eax+12],esi
	inc	dword [ebx+4]
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_1122
	push	eax
	call	bbGCFree
	add	esp,4
_1122:
	mov	eax,dword [ebp-8]
	mov	dword [eax+16],ebx
	mov	ebx,edi
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_1126
	push	eax
	call	bbGCFree
	add	esp,4
_1126:
	mov	eax,dword [ebp-12]
	mov	dword [eax+12],ebx
	mov	ebx,dword [ebp-8]
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_1130
	push	eax
	call	bbGCFree
	add	esp,4
_1130:
	mov	eax,dword [ebp-12]
	mov	dword [eax+16],ebx
	mov	ebx,dword [ebp-12]
	inc	dword [ebx+4]
	mov	eax,dword [edi+16]
	dec	dword [eax+4]
	jnz	_1134
	push	eax
	call	bbGCFree
	add	esp,4
_1134:
	mov	dword [edi+16],ebx
	mov	dword [ebp-16],0
	jmp	_1135
_1108:
	mov	eax,dword [ebp-8]
	mov	dword [ebp-12],eax
_1135:
	jmp	_85
_84:
	cmp	dword [ebp-16],0
	je	_1136
	mov	eax,0
	jmp	_470
_1136:
	mov	eax,dword [ebp-12]
	mov	dword [ebp-20],eax
	jmp	_82
_470:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SortChildrenEx:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	mov	eax,dword [eax+8]
	mov	dword [ebp-20],eax
_103:
_101:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+28]
	mov	eax,dword [eax+8]
	mov	eax,dword [eax+12]
	mov	dword [ebp-12],eax
	mov	dword [ebp-16],1
_106:
_104:
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp-20]
	cmp	dword [ebp-8],eax
	jne	_1149
	jmp	_105
_1149:
	mov	edi,_1
	mov	dword [ebp-4],_1
	mov	eax,dword [ebp+12]
	cmp	eax,1
	je	_1156
	cmp	eax,2
	je	_1157
	cmp	eax,3
	je	_1158
	cmp	eax,4
	je	_1159
	jmp	_1155
_1156:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
	jmp	_1155
_1157:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
	jmp	_1155
_1158:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_107
_109:
	mov	eax,esi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_107
	push	dword [eax+8]
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
_107:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_109
_108:
	push	edi
	call	bbStringToLower
	add	esp,4
	mov	edi,eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_110
_112:
	mov	eax,esi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_110
	push	dword [eax+8]
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_110:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_112
_111:
	push	dword [ebp-4]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-4],eax
	jmp	_1155
_1159:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_113
_115:
	mov	eax,esi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_113
	push	dword [eax+12]
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
_113:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_115
_114:
	push	edi
	call	bbStringToLower
	add	esp,4
	mov	edi,eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_116
_118:
	mov	eax,esi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_116
	push	dword [eax+12]
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_116:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_118
_117:
	push	dword [ebp-4]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-4],eax
	jmp	_1155
_1155:
	mov	eax,dword [ebp+16]
	cmp	eax,1
	je	_1182
	cmp	eax,2
	je	_1183
	cmp	eax,3
	je	_1184
	cmp	eax,4
	je	_1185
	jmp	_1181
_1182:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
	jmp	_1181
_1183:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
	jmp	_1181
_1184:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_119
_121:
	mov	eax,esi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_119
	push	dword [eax+8]
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
_119:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_121
_120:
	push	edi
	call	bbStringToLower
	add	esp,4
	mov	edi,eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_122
_124:
	mov	eax,esi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_122
	push	dword [eax+8]
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_122:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_124
_123:
	push	dword [ebp-4]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-4],eax
	jmp	_1181
_1185:
	push	bb_xmlNode
	mov	eax,dword [ebp-12]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	esi,dword [eax+24]
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_125
_127:
	mov	eax,ebx
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_125
	push	dword [eax+12]
	push	edi
	call	bbStringConcat
	add	esp,8
	mov	edi,eax
_125:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_127
_126:
	push	edi
	call	bbStringToLower
	add	esp,4
	mov	edi,eax
	push	bb_xmlNode
	mov	eax,dword [ebp-8]
	push	dword [eax+8]
	call	bbObjectDowncast
	add	esp,8
	mov	esi,dword [eax+24]
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_128
_130:
	mov	eax,ebx
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_128
	push	dword [eax+12]
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_128:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_130
_129:
	push	dword [ebp-4]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-4],eax
	jmp	_1181
_1181:
	push	dword [ebp-4]
	push	edi
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_1206
	mov	eax,dword [ebp+24]
_1206:
	cmp	eax,0
	jne	_1210
	push	dword [ebp-4]
	push	edi
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_1208
	mov	eax,dword [ebp+24]
	cmp	eax,0
	sete	al
	movzx	eax,al
_1208:
_1210:
	cmp	eax,0
	je	_1212
	mov	eax,dword [ebp-12]
	mov	ebx,dword [eax+16]
	mov	eax,dword [ebp-8]
	mov	edi,dword [eax+12]
	mov	eax,dword [ebp-8]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_1218
	push	eax
	call	bbGCFree
	add	esp,4
_1218:
	mov	dword [ebx+12],esi
	mov	eax,dword [ebp-12]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_1222
	push	eax
	call	bbGCFree
	add	esp,4
_1222:
	mov	eax,dword [ebp-8]
	mov	dword [eax+12],esi
	inc	dword [ebx+4]
	mov	eax,dword [ebp-8]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_1226
	push	eax
	call	bbGCFree
	add	esp,4
_1226:
	mov	eax,dword [ebp-8]
	mov	dword [eax+16],ebx
	mov	ebx,edi
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_1230
	push	eax
	call	bbGCFree
	add	esp,4
_1230:
	mov	eax,dword [ebp-12]
	mov	dword [eax+12],ebx
	mov	ebx,dword [ebp-8]
	inc	dword [ebx+4]
	mov	eax,dword [ebp-12]
	mov	eax,dword [eax+16]
	dec	dword [eax+4]
	jnz	_1234
	push	eax
	call	bbGCFree
	add	esp,4
_1234:
	mov	eax,dword [ebp-12]
	mov	dword [eax+16],ebx
	mov	ebx,dword [ebp-12]
	inc	dword [ebx+4]
	mov	eax,dword [edi+16]
	dec	dword [eax+4]
	jnz	_1238
	push	eax
	call	bbGCFree
	add	esp,4
_1238:
	mov	dword [edi+16],ebx
	mov	dword [ebp-16],0
	jmp	_1239
_1212:
	mov	eax,dword [ebp-8]
	mov	dword [ebp-12],eax
_1239:
	jmp	_106
_105:
	cmp	dword [ebp-16],0
	je	_1240
	mov	eax,0
	jmp	_477
_1240:
	mov	eax,dword [ebp-12]
	mov	dword [ebp-20],eax
	jmp	_103
_477:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_MoveChildrenTo:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	eax,dword [ebp+16]
	cmp	eax,1
	je	_1251
	cmp	eax,2
	je	_1252
	jmp	_1250
_1251:
	jmp	_134
_136:
	mov	eax,dword [esi+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	push	1
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,12
_134:
	mov	eax,dword [esi+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_136
_135:
	jmp	_1250
_1252:
	jmp	_137
_139:
	mov	eax,dword [esi+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	push	2
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,12
_137:
	mov	eax,dword [esi+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_139
_138:
	jmp	_1250
_1250:
	mov	eax,0
	jmp	_482
_482:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_CopyChildrenTo:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	mov	eax,dword [ebp+16]
	cmp	eax,1
	je	_1261
	cmp	eax,2
	je	_1262
	jmp	_1260
_1261:
	jmp	_140
_142:
	mov	eax,dword [esi+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	push	1
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,12
_140:
	mov	eax,dword [esi+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_142
_141:
	jmp	_1260
_1262:
	jmp	_143
_145:
	mov	eax,dword [esi+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	push	2
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,12
_143:
	mov	eax,dword [esi+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_145
_144:
	jmp	_1260
_1260:
	mov	eax,0
	jmp	_487
_487:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FreeChildren:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	jmp	_146
_148:
	mov	eax,dword [ebx+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+80]
	add	esp,4
_146:
	mov	eax,dword [ebx+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_148
_147:
	mov	eax,0
	jmp	_490
_490:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_NextSibling:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	jne	_1272
	mov	eax,bbNullObject
	jmp	_493
_1272:
	mov	eax,dword [eax+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	cmp	eax,bbNullObject
	jne	_1275
	mov	eax,bbNullObject
	jmp	_493
_1275:
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_493
_493:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_PrevSibling:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	jne	_1278
	mov	eax,bbNullObject
	jmp	_496
_1278:
	mov	eax,dword [eax+32]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,bbNullObject
	jne	_1281
	mov	eax,bbNullObject
	jmp	_496
_1281:
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_496
_496:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FirstSibling:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	jne	_1284
	jmp	_499
_1284:
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_499
_499:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_LastSibling:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	jne	_1286
	jmp	_502
_1286:
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_502
_502:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_GetSibling:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	esi,dword [ebp+12]
	cmp	dword [ebx+16],bbNullObject
	jne	_1288
	cmp	esi,1
	jne	_1289
	jmp	_506
_1289:
	push	_150
	push	esi
	call	bbStringFromInt
	add	esp,4
	push	eax
	push	_149
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_1288:
	mov	eax,dword [ebx+16]
	mov	eax,dword [eax+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+88]
	add	esp,4
	mov	ebx,1
	sub	esi,1
	jmp	_1293
_153:
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
_151:
	add	ebx,1
_1293:
	cmp	ebx,esi
	jle	_153
_152:
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_506
_506:
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SiblingCount:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],bbNullObject
	jne	_1297
	mov	eax,1
	jmp	_509
_1297:
	mov	eax,dword [eax+16]
	mov	eax,dword [eax+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,4
	jmp	_509
_509:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FindSibling:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	cmp	dword [edi+16],bbNullObject
	jne	_1299
	cmp	ebx,1
	jne	_1300
	push	_155
	push	esi
	push	_154
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_1300:
	cmp	ebx,0
	jne	_1301
	push	_156
	push	esi
	push	_154
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_1301:
_1299:
	mov	eax,dword [edi+16]
	push	ebx
	push	0
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+104]
	add	esp,16
	jmp	_514
_514:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_HasAttribute:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+8]
	mov	edi,dword [ebp+12]
	mov	eax,dword [ebp+16]
	cmp	eax,0
	je	_1304
	mov	esi,dword [ebx+24]
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_157
_159:
	mov	eax,ebx
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_157
	push	edi
	push	dword [eax+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1310
	mov	eax,1
	jmp	_519
_1310:
_157:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_159
_158:
	jmp	_1311
_1304:
	push	edi
	call	bbStringToLower
	add	esp,4
	mov	edi,eax
	mov	esi,dword [ebx+24]
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_160
_162:
	mov	eax,ebx
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_160
	push	edi
	push	dword [eax+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1317
	mov	eax,1
	jmp	_519
_1317:
_160:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_162
_161:
_1311:
	mov	eax,0
	jmp	_519
_519:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_HasAttributes:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+24]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1319
	mov	eax,0
	jmp	_522
_1319:
	mov	eax,1
	jmp	_522
_522:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FirstAttribute:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebx+24]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1322
	mov	eax,bbNullObject
	jmp	_525
_1322:
	mov	eax,dword [ebx+24]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_525
_525:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_LastAttribute:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebx+24]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1326
	mov	eax,bbNullObject
	jmp	_528
_1326:
	mov	eax,dword [ebx+24]
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_528
_528:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_Attribute:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+16]
	cmp	eax,0
	je	_1330
	mov	eax,dword [ebp+8]
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_163
_165:
	mov	eax,edi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_163
	push	dword [ebp+12]
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1336
	mov	eax,esi
	jmp	_533
_1336:
_163:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_165
_164:
	jmp	_1337
_1330:
	push	dword [ebp+12]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp+12],eax
	mov	eax,dword [ebp+8]
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_166
_168:
	mov	eax,edi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_166
	push	dword [ebp+12]
	push	dword [esi+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1343
	mov	eax,esi
	jmp	_533
_1343:
_166:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_168
_167:
_1337:
	push	bb_xmlAttribute
	call	bbObjectNew
	add	esp,4
	mov	esi,eax
	mov	ebx,dword [ebp+12]
	inc	dword [ebx+4]
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_1347
	push	eax
	call	bbGCFree
	add	esp,4
_1347:
	mov	dword [esi+8],ebx
	mov	ebx,_1
	inc	dword [ebx+4]
	mov	eax,dword [esi+12]
	dec	dword [eax+4]
	jnz	_1351
	push	eax
	call	bbGCFree
	add	esp,4
_1351:
	mov	dword [esi+12],ebx
	mov	ebx,dword [ebp+8]
	inc	dword [ebx+4]
	mov	eax,dword [esi+16]
	dec	dword [eax+4]
	jnz	_1355
	push	eax
	call	bbGCFree
	add	esp,4
_1355:
	mov	dword [esi+16],ebx
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+24]
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [esi+20]
	dec	dword [eax+4]
	jnz	_1360
	push	eax
	call	bbGCFree
	add	esp,4
_1360:
	mov	dword [esi+20],ebx
	mov	eax,esi
	jmp	_533
_533:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_CleanAttributes:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_169
_171:
	mov	eax,edi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_169
	push	_1
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_1367
	push	_1
	push	dword [esi+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_1367:
	cmp	eax,0
	je	_1369
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
_1369:
_169:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_171
_170:
	mov	eax,0
	jmp	_536
_536:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode__UpdateVars:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	edx,dword [ebp+8]
	cmp	dword [edx+16],bbNullObject
	je	_1371
	mov	eax,dword [edx+16]
	mov	eax,dword [eax+20]
	add	eax,1
	mov	dword [edx+20],eax
_1371:
	mov	esi,dword [edx+28]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_172
_174:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_172
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+184]
	add	esp,4
_172:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_174
_173:
	mov	eax,0
	jmp	_539
_539:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlAttribute_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_xmlAttribute
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+20],eax
	mov	eax,0
	jmp	_542
_542:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlAttribute_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_545:
	mov	eax,dword [ebx+20]
	dec	dword [eax+4]
	jnz	_1385
	push	eax
	call	bbGCFree
	add	esp,4
_1385:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_1387
	push	eax
	call	bbGCFree
	add	esp,4
_1387:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_1389
	push	eax
	call	bbGCFree
	add	esp,4
_1389:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_1391
	push	eax
	call	bbGCFree
	add	esp,4
_1391:
	mov	eax,0
	jmp	_1383
_1383:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlAttribute_NextAttr:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+20]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	cmp	eax,bbNullObject
	jne	_1394
	mov	eax,bbNullObject
	jmp	_548
_1394:
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_548
_548:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlAttribute_PrevAttr:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+20]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,bbNullObject
	jne	_1399
	mov	eax,bbNullObject
	jmp	_551
_1399:
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_551
_551:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlAttribute_Free:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+20]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,4
	mov	eax,0
	jmp	_554
_554:
	mov	esp,ebp
	pop	ebp
	ret
_175:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	dword [ebp-12],bbEmptyString
	mov	dword [ebp-8],bbEmptyString
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	ebx,dword [eax+24]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_176
_178:
	mov	eax,edi
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_176
	push	_181
	push	dword [esi+12]
	call	_255
	add	esp,4
	push	eax
	push	_180
	push	dword [esi+8]
	push	_179
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_176:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_178
_177:
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+20]
	shl	eax,1
	push	eax
	push	0
	push	dword [ebp-12]
	call	bbStringSlice
	add	esp,12
	mov	dword [ebp-12],eax
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+20]
	add	eax,1
	shl	eax,1
	push	eax
	push	0
	push	dword [ebp-8]
	call	bbStringSlice
	add	esp,12
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,4
	cmp	eax,0
	jne	_1414
	push	_1
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1415
	mov	ebx,dword [ebp+8]
	push	_183
	push	dword [ebp-4]
	push	_182
	push	dword [ebp-12]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+144]
	add	esp,8
	jmp	_1417
_1415:
	mov	ebx,dword [ebp+8]
	push	_2
	mov	eax,dword [ebp+12]
	push	dword [eax+8]
	push	_184
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	call	_255
	add	esp,4
	push	eax
	push	_2
	push	dword [ebp-4]
	push	_182
	push	dword [ebp-12]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+144]
	add	esp,8
_1417:
	jmp	_1419
_1414:
	mov	ebx,dword [ebp+8]
	push	_2
	push	dword [ebp-4]
	push	_182
	push	dword [ebp-12]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+144]
	add	esp,8
	push	_1
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_1421
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	call	_255
	add	esp,4
	push	eax
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+144]
	add	esp,8
_1421:
	mov	eax,dword [ebp+12]
	mov	esi,dword [eax+28]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_185
_187:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_185
	push	eax
	push	dword [ebp+8]
	call	_175
	add	esp,8
_185:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_187
_186:
	mov	ebx,dword [ebp+8]
	push	_2
	mov	eax,dword [ebp+12]
	push	dword [eax+8]
	push	_184
	push	dword [ebp-12]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+144]
	add	esp,8
_1419:
	mov	eax,0
	jmp	_558
_558:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_188:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	eax,esi
	mov	edx,dword [ebp+12]
	mov	edx,dword [edx+8]
	push	dword [edx+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,8
	mov	eax,esi
	mov	edx,dword [ebp+12]
	push	dword [edx+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+152]
	add	esp,8
	mov	eax,esi
	mov	edx,dword [ebp+12]
	mov	edx,dword [edx+12]
	push	dword [edx+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,8
	mov	eax,esi
	mov	edx,dword [ebp+12]
	push	dword [edx+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+152]
	add	esp,8
	mov	ebx,esi
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+24]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+112]
	add	esp,8
	mov	eax,dword [ebp+12]
	mov	edi,dword [eax+24]
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	dword [ebp-4],eax
	jmp	_189
_191:
	mov	eax,dword [ebp-4]
	push	bb_xmlAttribute
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	je	_189
	mov	eax,esi
	mov	edx,dword [ebx+8]
	push	dword [edx+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,8
	mov	eax,esi
	push	dword [ebx+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+152]
	add	esp,8
	mov	eax,esi
	mov	edx,dword [ebx+12]
	push	dword [edx+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,8
	mov	eax,esi
	push	dword [ebx+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+152]
	add	esp,8
_189:
	mov	eax,dword [ebp-4]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_191
_190:
	mov	ebx,esi
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+28]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+112]
	add	esp,8
	mov	eax,dword [ebp+12]
	mov	ebx,dword [eax+28]
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_192
_194:
	mov	eax,edi
	push	bb_xmlNode
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_192
	push	eax
	push	esi
	call	_188
	add	esp,8
_192:
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_194
_193:
	mov	eax,0
	jmp	_562
_562:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_195:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	push	0
	push	1
	push	ebx
	call	brl_stream_OpenStream
	add	esp,12
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [_589]
	dec	dword [eax+4]
	jnz	_1456
	push	eax
	call	bbGCFree
	add	esp,4
_1456:
	mov	dword [_589],esi
	cmp	dword [_589],bbNullObject
	jne	_1457
	push	bbStringClass
	push	ebx
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_1459
	mov	eax,bbEmptyString
_1459:
	push	_7
	push	eax
	push	_6
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_1457:
	mov	eax,dword [_589]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,216
	jne	_1461
	mov	eax,dword [_589]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,241
	jne	_1463
	mov	eax,dword [_589]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,188
	jne	_1465
	mov	eax,0
	jmp	_565
_1465:
_1463:
_1461:
	push	bbStringClass
	push	ebx
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_1467
	mov	eax,bbEmptyString
_1467:
	push	_196
	push	eax
	push	_6
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	mov	eax,0
	jmp	_565
_565:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_197:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+12]
	mov	eax,dword [_589]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+108]
	add	esp,4
	mov	edx,dword [_589]
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+148]
	add	esp,8
	mov	ebx,eax
	mov	eax,dword [_589]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+108]
	add	esp,4
	mov	edx,dword [_589]
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+148]
	add	esp,8
	mov	edi,eax
	cmp	esi,bbNullObject
	je	_1477
	mov	eax,esi
	push	1
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	dword [ebp-4],eax
	mov	ebx,edi
	inc	dword [ebx+4]
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_1482
	push	eax
	call	bbGCFree
	add	esp,4
_1482:
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],ebx
	jmp	_1483
_1477:
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-4],eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_1488
	push	eax
	call	bbGCFree
	add	esp,4
_1488:
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],ebx
	mov	ebx,edi
	inc	dword [ebx+4]
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_1492
	push	eax
	call	bbGCFree
	add	esp,4
_1492:
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],ebx
_1483:
	mov	eax,dword [_589]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+108]
	add	esp,4
	mov	edi,1
	mov	dword [ebp-8],eax
	jmp	_1496
_200:
	push	bb_xmlAttribute
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [ebp-4]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_1501
	push	eax
	call	bbGCFree
	add	esp,4
_1501:
	mov	dword [ebx+16],esi
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+24]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+20]
	dec	dword [eax+4]
	jnz	_1506
	push	eax
	call	bbGCFree
	add	esp,4
_1506:
	mov	dword [ebx+20],esi
	mov	eax,dword [_589]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+108]
	add	esp,4
	mov	edx,dword [_589]
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+148]
	add	esp,8
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_1512
	push	eax
	call	bbGCFree
	add	esp,4
_1512:
	mov	dword [ebx+8],esi
	mov	eax,dword [_589]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+108]
	add	esp,4
	mov	edx,dword [_589]
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+148]
	add	esp,8
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_1518
	push	eax
	call	bbGCFree
	add	esp,4
_1518:
	mov	dword [ebx+12],esi
_198:
	add	edi,1
_1496:
	cmp	edi,dword [ebp-8]
	jle	_200
_199:
	mov	eax,dword [_589]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+108]
	add	esp,4
	mov	ebx,eax
	mov	edi,1
	jmp	_1521
_203:
	push	dword [ebp-4]
	push	dword [ebp+8]
	call	_197
	add	esp,8
_201:
	add	edi,1
_1521:
	cmp	edi,ebx
	jle	_203
_202:
	mov	eax,0
	jmp	_569
_569:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_204:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	movzx	eax,byte [ebp+12]
	mov	eax,eax
	mov	byte [ebp-4],al
	mov	ebx,_1
	inc	dword [ebx+4]
	mov	eax,dword [_590]
	dec	dword [eax+4]
	jnz	_1526
	push	eax
	call	bbGCFree
	add	esp,4
_1526:
	mov	dword [_590],ebx
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_1527
	push	bbStringClass
	push	esi
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_1530
	mov	eax,bbEmptyString
_1530:
	push	0
	push	1
	push	_5
	push	eax
	push	_4
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_stream_OpenStream
	add	esp,12
	push	eax
	call	dword [brl_bank_TBank+136]
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [_591]
	dec	dword [eax+4]
	jnz	_1534
	push	eax
	call	bbGCFree
	add	esp,4
_1534:
	mov	dword [_591],ebx
	jmp	_1535
_1527:
	push	esi
	call	dword [brl_bank_TBank+136]
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [_591]
	dec	dword [eax+4]
	jnz	_1539
	push	eax
	call	bbGCFree
	add	esp,4
_1539:
	mov	dword [_591],ebx
_1535:
	cmp	dword [_591],bbNullObject
	jne	_1540
	push	bbStringClass
	push	esi
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_1542
	mov	eax,bbEmptyString
_1542:
	push	_7
	push	eax
	push	_6
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
_1540:
	mov	dword [_592],-1
	mov	eax,dword [_591]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,4
	mov	dword [_593],eax
	mov	eax,0
	jmp	_573
_573:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_205:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	dword [ebp-4],_1
_208:
_206:
	call	_223
	cmp	eax,1
	je	_1550
	cmp	eax,3
	je	_1551
	cmp	eax,6
	je	_1552
	cmp	eax,8
	je	_1553
	cmp	eax,5
	je	_1554
	cmp	eax,2
	je	_1555
	cmp	eax,4
	je	_1555
	cmp	eax,-1
	je	_1556
	jmp	_1549
_1550:
	cmp	dword [ebp+12],bbNullObject
	je	_1557
	mov	eax,dword [ebp+12]
	push	1
	push	dword [_590]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	edi,eax
	jmp	_1559
_1557:
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	edi,eax
	mov	ebx,dword [_590]
	inc	dword [ebx+4]
	mov	eax,dword [edi+8]
	dec	dword [eax+4]
	jnz	_1564
	push	eax
	call	bbGCFree
	add	esp,4
_1564:
	mov	dword [edi+8],ebx
_1559:
	call	_223
	jmp	_209
_211:
	push	bb_xmlAttribute
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,edi
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_1568
	push	eax
	call	bbGCFree
	add	esp,4
_1568:
	mov	dword [ebx+16],esi
	mov	eax,dword [edi+24]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+20]
	dec	dword [eax+4]
	jnz	_1573
	push	eax
	call	bbGCFree
	add	esp,4
_1573:
	mov	dword [ebx+20],esi
	push	dword [_590]
	call	brl_retro_Trim
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_1577
	push	eax
	call	bbGCFree
	add	esp,4
_1577:
	mov	dword [ebx+8],esi
	call	_223
	cmp	eax,5
	je	_1578
	push	_212
	call	bbExThrow
	add	esp,4
_1578:
	call	_223
	cmp	eax,7
	je	_1579
	push	_213
	call	bbExThrow
	add	esp,4
_1579:
	mov	eax,dword [_590]
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_1583
	push	eax
	call	bbGCFree
	add	esp,4
_1583:
	mov	dword [ebx+12],esi
	call	_223
_209:
	cmp	eax,6
	je	_211
_210:
	cmp	eax,2
	jne	_1584
	push	edi
	push	dword [ebp+8]
	call	_205
	add	esp,8
	jmp	_1585
_1584:
	cmp	eax,4
	je	_1586
	push	_214
	call	bbExThrow
	add	esp,4
_1586:
_1585:
	jmp	_1549
_1551:
	cmp	dword [ebp+12],bbNullObject
	jne	_1587
	push	_215
	call	bbExThrow
	add	esp,4
	jmp	_1588
_1587:
	mov	eax,dword [ebp+12]
	push	dword [eax+8]
	push	dword [_590]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_1589
	push	_216
	call	bbExThrow
	add	esp,4
_1589:
_1588:
	call	_223
	cmp	eax,2
	je	_1590
	push	_217
	call	bbExThrow
	add	esp,4
_1590:
	mov	eax,0
	jmp	_577
_1552:
	cmp	dword [ebp+12],bbNullObject
	jne	_1591
	push	dword [_590]
	push	_218
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	jmp	_1592
_1591:
	push	_1
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1593
	mov	ebx,dword [_590]
	inc	dword [ebx+4]
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_1597
	push	eax
	call	bbGCFree
	add	esp,4
_1597:
	mov	eax,dword [ebp+12]
	mov	dword [eax+12],ebx
	jmp	_1598
_1593:
	push	dword [_590]
	push	dword [ebp-4]
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [ebp+12]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_1602
	push	eax
	call	bbGCFree
	add	esp,4
_1602:
	mov	eax,dword [ebp+12]
	mov	dword [eax+12],ebx
_1598:
	mov	dword [ebp-4],_179
_1592:
	jmp	_1549
_1553:
	push	_179
	push	dword [ebp-4]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1603
	mov	dword [ebp-4],_219
	jmp	_1604
_1603:
	push	_219
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_1604:
	jmp	_1549
_1554:
	push	_179
	push	dword [ebp-4]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1605
	mov	dword [ebp-4],_220
	jmp	_1606
_1605:
	push	_220
	push	dword [ebp-4]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-4],eax
_1606:
	jmp	_1549
_1555:
	push	_221
	call	bbExThrow
	add	esp,4
	jmp	_1549
_1556:
	cmp	dword [ebp+12],bbNullObject
	jne	_1607
	mov	eax,0
	jmp	_577
_1607:
	push	_222
	call	bbExThrow
	add	esp,4
_1608:
	jmp	_1549
_1549:
	jmp	_208
_577:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_223:
	push	ebp
	mov	ebp,esp
_226:
	call	_227
_224:
	cmp	eax,0
	je	_226
_225:
	jmp	_579
_579:
	mov	esp,ebp
	pop	ebp
	ret
_227:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [_593]
	add	dword [_592],1
	cmp	dword [_592],edi
	jl	_1613
	mov	eax,-1
	jmp	_581
_1613:
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
	mov	eax,esi
	cmp	eax,60
	je	_1617
	cmp	eax,47
	je	_1618
	cmp	eax,62
	je	_1619
	cmp	eax,61
	je	_1620
	cmp	eax,34
	je	_1621
	cmp	eax,32
	je	_1622
	cmp	eax,13
	je	_1622
	cmp	eax,10
	je	_1622
	cmp	eax,9
	je	_1622
	mov	ebx,_1
_251:
	cmp	esi,38
	jne	_1623
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,1
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,108
	je	_1627
	cmp	eax,103
	je	_1628
	cmp	eax,97
	je	_1629
	cmp	eax,113
	je	_1630
	cmp	eax,35
	je	_1631
	jmp	_1626
_1627:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_1633
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1635
	mov	esi,60
	add	dword [_592],3
_1635:
_1633:
	jmp	_1626
_1628:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_1637
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1639
	mov	esi,62
	add	dword [_592],3
_1639:
_1637:
	jmp	_1626
_1629:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,112
	jne	_1641
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,111
	jne	_1643
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,4
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,115
	jne	_1645
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,5
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1647
	mov	esi,39
	add	dword [_592],5
_1647:
_1645:
_1643:
	jmp	_1648
_1641:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,109
	jne	_1650
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,112
	jne	_1652
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,4
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1654
	mov	esi,38
	add	dword [_592],4
_1654:
_1652:
_1650:
_1648:
	jmp	_1626
_1630:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,117
	jne	_1656
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,111
	jne	_1658
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,4
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_1660
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,5
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1662
	mov	esi,34
	add	dword [_592],5
_1662:
_1660:
_1658:
_1656:
	jmp	_1626
_1631:
	mov	esi,0
	add	dword [_592],2
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	jmp	_252
_254:
	mov	edx,esi
	imul	edx,10
	mov	esi,edx
	and	eax,15
	add	esi,eax
	add	dword [_592],1
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
_252:
	cmp	eax,59
	jne	_254
_253:
	jmp	_1626
_1626:
_1623:
	push	esi
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	add	dword [_592],1
	cmp	dword [_592],edi
	jl	_1666
	jmp	_250
_1666:
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
_249:
	cmp	esi,60
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_1668
	cmp	esi,47
	sete	al
	movzx	eax,al
_1668:
	cmp	eax,0
	jne	_1670
	cmp	esi,61
	sete	al
	movzx	eax,al
_1670:
	cmp	eax,0
	jne	_1672
	cmp	esi,62
	sete	al
	movzx	eax,al
_1672:
	cmp	eax,0
	jne	_1674
	cmp	esi,13
	sete	al
	movzx	eax,al
_1674:
	cmp	eax,0
	je	_251
_250:
	sub	dword [_592],1
	inc	dword [ebx+4]
	mov	eax,dword [_590]
	dec	dword [eax+4]
	jnz	_1679
	push	eax
	call	bbGCFree
	add	esp,4
_1679:
	mov	dword [_590],ebx
	mov	eax,6
	jmp	_581
_1617:
	add	dword [_592],1
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
	mov	eax,esi
	cmp	eax,47
	je	_1683
	cmp	eax,45
	je	_1684
	cmp	eax,63
	je	_1685
	mov	ebx,_1
	jmp	_237
_239:
	push	esi
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	add	dword [_592],1
	mov	eax,dword [_593]
	cmp	dword [_592],eax
	jne	_1692
	jmp	_238
_1692:
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
_237:
	cmp	esi,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_1686
	cmp	esi,62
	setne	al
	movzx	eax,al
_1686:
	cmp	eax,0
	je	_1688
	cmp	esi,47
	setne	al
	movzx	eax,al
_1688:
	cmp	eax,0
	je	_1690
	cmp	esi,9
	setne	al
	movzx	eax,al
_1690:
	cmp	eax,0
	jne	_239
_238:
	cmp	esi,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_1694
	cmp	esi,9
	setne	al
	movzx	eax,al
_1694:
	cmp	eax,0
	je	_1696
	sub	dword [_592],1
_1696:
	inc	dword [ebx+4]
	mov	eax,dword [_590]
	dec	dword [eax+4]
	jnz	_1700
	push	eax
	call	bbGCFree
	add	esp,4
_1700:
	mov	dword [_590],ebx
	mov	eax,1
	jmp	_581
_1683:
	add	dword [_592],1
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
	mov	ebx,_1
	jmp	_228
_230:
	push	esi
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	add	dword [_592],1
	mov	eax,dword [_593]
	cmp	dword [_592],eax
	jne	_1708
	jmp	_229
_1708:
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
_228:
	cmp	esi,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_1702
	cmp	esi,62
	setne	al
	movzx	eax,al
_1702:
	cmp	eax,0
	je	_1704
	cmp	esi,47
	setne	al
	movzx	eax,al
_1704:
	cmp	eax,0
	je	_1706
	cmp	esi,9
	setne	al
	movzx	eax,al
_1706:
	cmp	eax,0
	jne	_230
_229:
	cmp	esi,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_1710
	cmp	esi,9
	setne	al
	movzx	eax,al
_1710:
	cmp	eax,0
	je	_1712
	sub	dword [_592],1
_1712:
	inc	dword [ebx+4]
	mov	eax,dword [_590]
	dec	dword [eax+4]
	jnz	_1716
	push	eax
	call	bbGCFree
	add	esp,4
_1716:
	mov	dword [_590],ebx
	mov	eax,3
	jmp	_581
_1684:
	add	dword [_592],1
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
	jmp	_231
_233:
	add	dword [_592],1
	mov	eax,dword [_593]
	cmp	dword [_592],eax
	jne	_1718
	jmp	_232
_1718:
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
_231:
	cmp	esi,62
	jne	_233
_232:
	mov	eax,0
	jmp	_581
_1685:
	add	dword [_592],1
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
	jmp	_234
_236:
	add	dword [_592],1
	mov	eax,dword [_593]
	cmp	dword [_592],eax
	jne	_1721
	jmp	_235
_1721:
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
_234:
	cmp	esi,62
	jne	_236
_235:
	mov	eax,0
	jmp	_581
_1618:
	add	dword [_592],1
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
	cmp	esi,62
	jne	_1724
	mov	eax,4
	jmp	_581
_1724:
	sub	dword [_592],1
	mov	eax,8
	jmp	_581
_1619:
	mov	eax,2
	jmp	_581
_1620:
	mov	eax,5
	jmp	_581
_1621:
	add	dword [_592],1
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
	mov	ebx,_1
	jmp	_240
_242:
	cmp	esi,38
	jne	_1726
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,1
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,108
	je	_1730
	cmp	eax,103
	je	_1731
	cmp	eax,97
	je	_1732
	cmp	eax,113
	je	_1733
	cmp	eax,35
	je	_1734
	jmp	_1729
_1730:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_1736
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1738
	mov	esi,60
	add	dword [_592],3
_1738:
_1736:
	jmp	_1729
_1731:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_1740
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1742
	mov	esi,62
	add	dword [_592],3
_1742:
_1740:
	jmp	_1729
_1732:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,112
	jne	_1744
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,111
	jne	_1746
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,4
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,115
	jne	_1748
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,5
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1750
	mov	esi,39
	add	dword [_592],5
_1750:
_1748:
_1746:
	jmp	_1751
_1744:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,109
	jne	_1753
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,112
	jne	_1755
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,4
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1757
	mov	esi,38
	add	dword [_592],4
_1757:
_1755:
_1753:
_1751:
	jmp	_1729
_1733:
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,2
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,117
	jne	_1759
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,3
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,111
	jne	_1761
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,4
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_1763
	mov	edx,dword [_591]
	mov	eax,dword [_592]
	add	eax,5
	push	eax
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_1765
	mov	esi,34
	add	dword [_592],5
_1765:
_1763:
_1761:
_1759:
	jmp	_1729
_1734:
	mov	esi,0
	add	dword [_592],2
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	jmp	_243
_245:
	mov	edx,esi
	imul	edx,10
	mov	esi,edx
	and	eax,15
	add	esi,eax
	add	dword [_592],1
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
_243:
	cmp	eax,59
	jne	_245
_244:
	jmp	_1729
_1729:
_1726:
	push	esi
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	add	dword [_592],1
	mov	eax,dword [_593]
	cmp	dword [_592],eax
	jne	_1769
	jmp	_241
_1769:
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
_240:
	cmp	esi,34
	jne	_242
_241:
	inc	dword [ebx+4]
	mov	eax,dword [_590]
	dec	dword [eax+4]
	jnz	_1774
	push	eax
	call	bbGCFree
	add	esp,4
_1774:
	mov	dword [_590],ebx
	mov	eax,7
	jmp	_581
_1622:
_248:
	add	dword [_592],1
	mov	eax,dword [_593]
	cmp	dword [_592],eax
	jne	_1775
	jmp	_247
_1775:
	mov	eax,dword [_591]
	push	dword [_592]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+84]
	add	esp,8
	mov	esi,eax
_246:
	cmp	esi,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_1777
	cmp	esi,13
	setne	al
	movzx	eax,al
_1777:
	cmp	eax,0
	je	_1779
	cmp	esi,10
	setne	al
	movzx	eax,al
_1779:
	cmp	eax,0
	je	_1781
	cmp	esi,9
	setne	al
	movzx	eax,al
_1781:
	cmp	eax,0
	je	_248
_247:
	sub	dword [_592],1
	mov	eax,0
	jmp	_581
_581:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_255:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	ebx,_1
	mov	eax,dword [edi+8]
	mov	esi,0
	sub	eax,1
	mov	dword [ebp-4],eax
	jmp	_1786
_258:
	movzx	eax,word [edi+esi*2+12]
	mov	eax,eax
	cmp	eax,60
	je	_1790
	cmp	eax,62
	je	_1791
	cmp	eax,34
	je	_1792
	cmp	eax,39
	je	_1793
	cmp	eax,38
	je	_1794
	movzx	eax,word [edi+esi*2+12]
	mov	eax,eax
	cmp	eax,32
	setl	al
	movzx	eax,al
	cmp	eax,0
	jne	_1795
	movzx	eax,word [edi+esi*2+12]
	mov	eax,eax
	cmp	eax,126
	setg	al
	movzx	eax,al
_1795:
	cmp	eax,0
	je	_1797
	movzx	eax,word [edi+esi*2+12]
	mov	eax,eax
	cmp	eax,255
	setle	al
	movzx	eax,al
_1797:
	cmp	eax,0
	je	_1799
	push	_265
	movzx	eax,word [edi+esi*2+12]
	mov	eax,eax
	push	eax
	call	bbStringFromInt
	add	esp,4
	push	eax
	push	_264
	push	ebx
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	jmp	_1800
_1799:
	movzx	eax,word [edi+esi*2+12]
	mov	eax,eax
	push	eax
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
_1800:
	jmp	_1789
_1790:
	push	_259
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	jmp	_1789
_1791:
	push	_260
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	jmp	_1789
_1792:
	push	_261
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	jmp	_1789
_1793:
	push	_262
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	jmp	_1789
_1794:
	push	_263
	push	ebx
	call	bbStringConcat
	add	esp,8
	mov	ebx,eax
	jmp	_1789
_1789:
_256:
	add	esi,1
_1786:
	cmp	esi,dword [ebp-4]
	jle	_258
_257:
	mov	eax,ebx
	jmp	_584
_584:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_266:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	esi,1
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+88]
	add	esp,4
	mov	ebx,eax
	jmp	_267
_269:
	push	ebx
	call	_266
	add	esp,4
	add	esi,eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+132]
	add	esp,4
	mov	ebx,eax
_267:
	cmp	ebx,bbNullObject
	jne	_269
_268:
	mov	eax,esi
	jmp	_587
_587:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_594:
	dd	0
_271:
	db	"xmlDocument",0
_272:
	db	"_RootNode",0
_273:
	db	":xmlNode",0
_274:
	db	"New",0
_275:
	db	"()i",0
_276:
	db	"Delete",0
_277:
	db	"Create",0
_278:
	db	"(:Object,b):xmlDocument",0
_279:
	db	"Root",0
_280:
	db	"():xmlNode",0
_281:
	db	"Load",0
_282:
	db	"(:Object,b)i",0
_283:
	db	"Save",0
_284:
	db	"(:Object,i,b)i",0
_285:
	db	"NodeCount",0
_286:
	db	"SetEncryptionKey",0
_287:
	db	"($)i",0
_288:
	db	"Clear",0
	align	4
_270:
	dd	2
	dd	_271
	dd	3
	dd	_272
	dd	_273
	dd	8
	dd	6
	dd	_274
	dd	_275
	dd	16
	dd	6
	dd	_276
	dd	_275
	dd	20
	dd	7
	dd	_277
	dd	_278
	dd	48
	dd	6
	dd	_279
	dd	_280
	dd	52
	dd	6
	dd	_281
	dd	_282
	dd	56
	dd	6
	dd	_283
	dd	_284
	dd	60
	dd	6
	dd	_285
	dd	_275
	dd	64
	dd	6
	dd	_286
	dd	_287
	dd	68
	dd	6
	dd	_288
	dd	_275
	dd	72
	dd	0
	align	4
bb_xmlDocument:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_270
	dd	12
	dd	_bb_xmlDocument_New
	dd	_bb_xmlDocument_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_xmlDocument_Create
	dd	_bb_xmlDocument_Root
	dd	_bb_xmlDocument_Load
	dd	_bb_xmlDocument_Save
	dd	_bb_xmlDocument_NodeCount
	dd	_bb_xmlDocument_SetEncryptionKey
	dd	_bb_xmlDocument_Clear
_290:
	db	"xmlNode",0
_291:
	db	"Name",0
_292:
	db	"$",0
_293:
	db	"Value",0
_294:
	db	"Parent",0
_295:
	db	"Level",0
_296:
	db	"i",0
_297:
	db	"AttributeList",0
_298:
	db	":brl.linkedlist.TList",0
_299:
	db	"ChildList",0
_300:
	db	"_Link",0
_301:
	db	":brl.linkedlist.TLink",0
_302:
	db	"_Doc",0
_303:
	db	":xmlDocument",0
_304:
	db	"AddNode",0
_305:
	db	"($,i):xmlNode",0
_306:
	db	"MoveTo",0
_307:
	db	"(:xmlNode,i)i",0
_308:
	db	"CopyTo",0
_309:
	db	"(:xmlNode,i):xmlNode",0
_310:
	db	"Copy",0
_311:
	db	"(:xmlNode):xmlNode",0
_312:
	db	"SwapWith",0
_313:
	db	"(:xmlNode)i",0
_314:
	db	"GetIndex",0
_315:
	db	"SetIndex",0
_316:
	db	"(i)i",0
_317:
	db	"IsRoot",0
_318:
	db	"Free",0
_319:
	db	"HasChildren",0
_320:
	db	"FirstChild",0
_321:
	db	"LastChild",0
_322:
	db	"GetChild",0
_323:
	db	"(i):xmlNode",0
_324:
	db	"ChildCount",0
_325:
	db	"FindChild",0
_326:
	db	"($,i,i):xmlNode",0
_327:
	db	"FindChildEx",0
_328:
	db	"($,$,$,i,i):xmlNode",0
_329:
	db	"SortChildren",0
_330:
	db	"(i,i,i)i",0
_331:
	db	"SortChildrenEx",0
_332:
	db	"(i,i,i,i)i",0
_333:
	db	"MoveChildrenTo",0
_334:
	db	"CopyChildrenTo",0
_335:
	db	"FreeChildren",0
_336:
	db	"NextSibling",0
_337:
	db	"PrevSibling",0
_338:
	db	"FirstSibling",0
_339:
	db	"LastSibling",0
_340:
	db	"GetSibling",0
_341:
	db	"SiblingCount",0
_342:
	db	"FindSibling",0
_343:
	db	"HasAttribute",0
_344:
	db	"($,i)i",0
_345:
	db	"HasAttributes",0
_346:
	db	"FirstAttribute",0
_347:
	db	"LastAttribute",0
_348:
	db	"Attribute",0
_349:
	db	"($,i):xmlAttribute",0
_350:
	db	"CleanAttributes",0
_351:
	db	"_UpdateVars",0
	align	4
_289:
	dd	2
	dd	_290
	dd	3
	dd	_291
	dd	_292
	dd	8
	dd	3
	dd	_293
	dd	_292
	dd	12
	dd	3
	dd	_294
	dd	_273
	dd	16
	dd	3
	dd	_295
	dd	_296
	dd	20
	dd	3
	dd	_297
	dd	_298
	dd	24
	dd	3
	dd	_299
	dd	_298
	dd	28
	dd	3
	dd	_300
	dd	_301
	dd	32
	dd	3
	dd	_302
	dd	_303
	dd	36
	dd	6
	dd	_274
	dd	_275
	dd	16
	dd	6
	dd	_276
	dd	_275
	dd	20
	dd	6
	dd	_304
	dd	_305
	dd	48
	dd	6
	dd	_306
	dd	_307
	dd	52
	dd	6
	dd	_308
	dd	_309
	dd	56
	dd	6
	dd	_310
	dd	_311
	dd	60
	dd	6
	dd	_312
	dd	_313
	dd	64
	dd	6
	dd	_314
	dd	_275
	dd	68
	dd	6
	dd	_315
	dd	_316
	dd	72
	dd	6
	dd	_317
	dd	_275
	dd	76
	dd	6
	dd	_318
	dd	_275
	dd	80
	dd	6
	dd	_319
	dd	_275
	dd	84
	dd	6
	dd	_320
	dd	_280
	dd	88
	dd	6
	dd	_321
	dd	_280
	dd	92
	dd	6
	dd	_322
	dd	_323
	dd	96
	dd	6
	dd	_324
	dd	_275
	dd	100
	dd	6
	dd	_325
	dd	_326
	dd	104
	dd	6
	dd	_327
	dd	_328
	dd	108
	dd	6
	dd	_329
	dd	_330
	dd	112
	dd	6
	dd	_331
	dd	_332
	dd	116
	dd	6
	dd	_333
	dd	_307
	dd	120
	dd	6
	dd	_334
	dd	_307
	dd	124
	dd	6
	dd	_335
	dd	_275
	dd	128
	dd	6
	dd	_336
	dd	_280
	dd	132
	dd	6
	dd	_337
	dd	_280
	dd	136
	dd	6
	dd	_338
	dd	_280
	dd	140
	dd	6
	dd	_339
	dd	_280
	dd	144
	dd	6
	dd	_340
	dd	_323
	dd	148
	dd	6
	dd	_341
	dd	_275
	dd	152
	dd	6
	dd	_342
	dd	_305
	dd	156
	dd	6
	dd	_343
	dd	_344
	dd	160
	dd	6
	dd	_345
	dd	_275
	dd	164
	dd	6
	dd	_346
	dd	_280
	dd	168
	dd	6
	dd	_347
	dd	_280
	dd	172
	dd	6
	dd	_348
	dd	_349
	dd	176
	dd	6
	dd	_350
	dd	_275
	dd	180
	dd	6
	dd	_351
	dd	_275
	dd	184
	dd	0
	align	4
bb_xmlNode:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_289
	dd	40
	dd	_bb_xmlNode_New
	dd	_bb_xmlNode_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_xmlNode_AddNode
	dd	_bb_xmlNode_MoveTo
	dd	_bb_xmlNode_CopyTo
	dd	_bb_xmlNode_Copy
	dd	_bb_xmlNode_SwapWith
	dd	_bb_xmlNode_GetIndex
	dd	_bb_xmlNode_SetIndex
	dd	_bb_xmlNode_IsRoot
	dd	_bb_xmlNode_Free
	dd	_bb_xmlNode_HasChildren
	dd	_bb_xmlNode_FirstChild
	dd	_bb_xmlNode_LastChild
	dd	_bb_xmlNode_GetChild
	dd	_bb_xmlNode_ChildCount
	dd	_bb_xmlNode_FindChild
	dd	_bb_xmlNode_FindChildEx
	dd	_bb_xmlNode_SortChildren
	dd	_bb_xmlNode_SortChildrenEx
	dd	_bb_xmlNode_MoveChildrenTo
	dd	_bb_xmlNode_CopyChildrenTo
	dd	_bb_xmlNode_FreeChildren
	dd	_bb_xmlNode_NextSibling
	dd	_bb_xmlNode_PrevSibling
	dd	_bb_xmlNode_FirstSibling
	dd	_bb_xmlNode_LastSibling
	dd	_bb_xmlNode_GetSibling
	dd	_bb_xmlNode_SiblingCount
	dd	_bb_xmlNode_FindSibling
	dd	_bb_xmlNode_HasAttribute
	dd	_bb_xmlNode_HasAttributes
	dd	_bb_xmlNode_FirstAttribute
	dd	_bb_xmlNode_LastAttribute
	dd	_bb_xmlNode_Attribute
	dd	_bb_xmlNode_CleanAttributes
	dd	_bb_xmlNode__UpdateVars
_353:
	db	"xmlAttribute",0
_354:
	db	"Node",0
_355:
	db	"NextAttr",0
_356:
	db	"():xmlAttribute",0
_357:
	db	"PrevAttr",0
	align	4
_352:
	dd	2
	dd	_353
	dd	3
	dd	_291
	dd	_292
	dd	8
	dd	3
	dd	_293
	dd	_292
	dd	12
	dd	3
	dd	_354
	dd	_273
	dd	16
	dd	3
	dd	_300
	dd	_301
	dd	20
	dd	6
	dd	_274
	dd	_275
	dd	16
	dd	6
	dd	_276
	dd	_275
	dd	20
	dd	6
	dd	_355
	dd	_356
	dd	48
	dd	6
	dd	_357
	dd	_356
	dd	52
	dd	6
	dd	_318
	dd	_275
	dd	56
	dd	0
	align	4
bb_xmlAttribute:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_352
	dd	24
	dd	_bb_xmlAttribute_New
	dd	_bb_xmlAttribute_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_xmlAttribute_NextAttr
	dd	_bb_xmlAttribute_PrevAttr
	dd	_bb_xmlAttribute_Free
	align	4
_589:
	dd	bbNullObject
	align	4
_590:
	dd	bbEmptyString
	align	4
_591:
	dd	bbNullObject
	align	4
_592:
	dd	0
	align	4
_593:
	dd	0
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_3:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	114,111,111,116
	align	4
_5:
	dd	bbStringClass
	dd	2147483647
	dd	14
	dw	47,47,115,97,118,101,103,97,109,101,46,116,109,112
	align	4
_4:
	dd	bbStringClass
	dd	2147483647
	dd	5
	dw	122,105,112,58,58
	align	4
_7:
	dd	bbStringClass
	dd	2147483647
	dd	26
	dw	34,41,58,32,67,97,110,110,111,116,32,114,101,97,100,32
	dw	102,114,111,109,32,102,105,108,101,46
	align	4
_6:
	dd	bbStringClass
	dd	2147483647
	dd	18
	dw	120,109,108,68,111,99,117,109,101,110,116,46,76,111,97,100
	dw	40,34
	align	4
_8:
	dd	bbStringClass
	dd	2147483647
	dd	12
	dw	115,97,118,101,103,97,109,101,46,116,109,112
	align	4
_9:
	dd	bbStringClass
	dd	2147483647
	dd	48
	dw	70,101,104,108,101,114,32,98,101,105,109,32,76,111,101,115
	dw	99,104,101,110,32,100,101,114,32,84,101,109,112,100,97,116
	dw	101,105,32,115,97,118,101,103,97,109,101,46,116,109,112,32
	align	4
_10:
	dd	bbStringClass
	dd	2147483647
	dd	21
	dw	60,63,120,109,108,32,118,101,114,115,105,111,110,61,34,49
	dw	46,48,34,63,62
	align	4
_11:
	dd	bbStringClass
	dd	2147483647
	dd	12
	dw	115,97,118,101,103,97,109,101,46,122,105,112
	align	4
_13:
	dd	bbStringClass
	dd	2147483647
	dd	52
	dw	34,44,32,65,83,95,83,73,66,76,73,78,71,41,58,32
	dw	84,104,101,32,114,111,111,116,32,110,111,100,101,32,109,97
	dw	121,32,110,111,116,32,104,97,118,101,32,115,105,98,108,105
	dw	110,103,115,46
	align	4
_12:
	dd	bbStringClass
	dd	2147483647
	dd	17
	dw	120,109,108,78,111,100,101,46,65,100,100,78,111,100,101,40
	dw	34
	align	4
_14:
	dd	bbStringClass
	dd	2147483647
	dd	57
	dw	120,109,108,78,111,100,101,46,77,111,118,101,84,111,40,120
	dw	109,108,78,111,100,101,44,32,65,83,95,67,72,73,76,68
	dw	41,58,32,67,97,110,110,111,116,32,109,111,118,101,32,114
	dw	111,111,116,32,110,111,100,101,46
	align	4
_15:
	dd	bbStringClass
	dd	2147483647
	dd	59
	dw	120,109,108,78,111,100,101,46,77,111,118,101,84,111,40,120
	dw	109,108,78,111,100,101,44,32,65,83,95,83,73,66,76,73
	dw	78,71,41,58,32,67,97,110,110,111,116,32,109,111,118,101
	dw	32,114,111,111,116,32,110,111,100,101,46
	align	4
_19:
	dd	bbStringClass
	dd	2147483647
	dd	80
	dw	120,109,108,78,111,100,101,46,77,111,118,101,84,111,40,120
	dw	109,108,78,111,100,101,44,32,65,83,95,67,72,73,76,68
	dw	41,58,32,67,97,110,110,111,116,32,109,111,118,101,32,97
	dw	32,110,111,100,101,32,105,110,116,111,32,111,110,101,32,111
	dw	102,32,105,116,39,115,32,99,104,105,108,100,114,101,110,46
	align	4
_20:
	dd	bbStringClass
	dd	2147483647
	dd	80
	dw	120,109,108,78,111,100,101,46,77,111,118,101,84,111,40,120
	dw	109,108,78,111,100,101,44,32,65,83,95,83,73,66,76,73
	dw	78,71,41,58,32,67,97,110,110,111,116,32,109,111,118,101
	dw	32,97,32,110,111,100,101,32,116,111,32,111,110,101,32,111
	dw	102,32,105,116,39,115,32,99,104,105,108,100,114,101,110,46
	align	4
_21:
	dd	bbStringClass
	dd	2147483647
	dd	73
	dw	120,109,108,78,111,100,101,46,77,111,118,101,84,111,40,120
	dw	109,108,78,111,100,101,44,32,65,83,95,83,73,66,76,73
	dw	78,71,41,58,32,84,104,101,32,114,111,111,116,32,110,111
	dw	100,101,32,109,97,121,32,110,111,116,32,104,97,118,101,32
	dw	115,105,98,108,105,110,103,115,46
	align	4
_22:
	dd	bbStringClass
	dd	2147483647
	dd	57
	dw	120,109,108,78,111,100,101,46,67,111,112,121,84,111,40,120
	dw	109,108,78,111,100,101,44,32,65,83,95,67,72,73,76,68
	dw	41,58,32,67,97,110,110,111,116,32,99,111,112,121,32,114
	dw	111,111,116,32,110,111,100,101,46
	align	4
_23:
	dd	bbStringClass
	dd	2147483647
	dd	59
	dw	120,109,108,78,111,100,101,46,67,111,112,121,84,111,40,120
	dw	109,108,78,111,100,101,44,32,65,83,95,83,73,66,76,73
	dw	78,71,41,58,32,67,97,110,110,111,116,32,99,111,112,121
	dw	32,114,111,111,116,32,110,111,100,101,46
	align	4
_24:
	dd	bbStringClass
	dd	2147483647
	dd	65
	dw	120,109,108,78,111,100,101,46,67,111,112,121,84,111,40,67
	dw	111,112,121,84,111,44,32,65,83,95,67,72,73,76,68,41
	dw	58,32,67,97,110,110,111,116,32,109,111,118,101,32,97,32
	dw	99,111,112,121,32,105,110,116,111,32,105,116,115,101,108,102
	dw	46
	align	4
_25:
	dd	bbStringClass
	dd	2147483647
	dd	68
	dw	120,109,108,78,111,100,101,46,67,111,112,121,84,111,40,67
	dw	111,112,121,84,111,44,32,65,83,95,83,73,66,76,73,78
	dw	71,41,58,32,67,97,110,110,111,116,32,109,111,118,101,32
	dw	97,32,99,111,112,121,32,117,110,100,101,114,32,105,116,115
	dw	101,108,102,46
	align	4
_26:
	dd	bbStringClass
	dd	2147483647
	dd	73
	dw	120,109,108,78,111,100,101,46,67,111,112,121,84,111,40,120
	dw	109,108,78,111,100,101,44,32,65,83,95,83,73,66,76,73
	dw	78,71,41,58,32,84,104,101,32,114,111,111,116,32,110,111
	dw	100,101,32,109,97,121,32,110,111,116,32,104,97,118,101,32
	dw	115,105,98,108,105,110,103,115,46
	align	4
_27:
	dd	bbStringClass
	dd	2147483647
	dd	38
	dw	120,109,108,78,111,100,101,46,67,111,112,121,40,41,58,32
	dw	67,97,110,110,111,116,32,99,111,112,121,32,114,111,111,116
	dw	32,110,111,100,101,46
	align	4
_37:
	dd	bbStringClass
	dd	2147483647
	dd	72
	dw	120,109,108,78,111,100,101,46,83,119,97,112,87,105,116,104
	dw	40,120,109,108,78,111,100,101,41,58,32,67,97,110,110,111
	dw	116,32,115,119,97,112,32,97,32,110,111,100,101,32,119,105
	dw	116,104,32,111,110,101,32,111,102,32,105,116,39,115,32,99
	dw	104,105,108,100,114,101,110,46
	align	4
_41:
	dd	bbStringClass
	dd	2147483647
	dd	71
	dw	120,109,108,78,111,100,101,46,83,119,97,112,87,105,116,104
	dw	40,120,109,108,78,111,100,101,41,58,32,67,97,110,110,111
	dw	116,32,115,119,97,112,32,97,32,110,111,100,101,32,119,105
	dw	116,104,32,111,110,101,32,111,102,32,105,116,39,115,32,112
	dw	97,114,101,110,116,115,46
	align	4
_46:
	dd	bbStringClass
	dd	2147483647
	dd	41
	dw	41,58,32,67,97,110,110,111,116,32,115,101,116,32,116,104
	dw	101,32,105,110,100,101,120,32,111,102,32,116,104,101,32,114
	dw	111,111,116,32,110,111,100,101,46
	align	4
_45:
	dd	bbStringClass
	dd	2147483647
	dd	17
	dw	120,109,108,78,111,100,101,46,83,101,116,73,110,100,101,120
	dw	40
	align	4
_47:
	dd	bbStringClass
	dd	2147483647
	dd	32
	dw	41,58,32,73,110,100,101,120,32,109,97,121,32,110,111,116
	dw	32,98,101,32,108,101,115,115,32,116,104,97,110,32,49,46
	align	4
_150:
	dd	bbStringClass
	dd	2147483647
	dd	32
	dw	41,58,32,84,104,101,32,114,111,111,116,32,110,111,100,101
	dw	32,104,97,115,32,110,111,32,115,105,98,108,105,110,103,115
	align	4
_149:
	dd	bbStringClass
	dd	2147483647
	dd	19
	dw	120,109,108,78,111,100,101,46,71,101,116,83,105,98,108,105
	dw	110,103,40
	align	4
_155:
	dd	bbStringClass
	dd	2147483647
	dd	34
	dw	34,41,58,32,84,104,101,32,114,111,111,116,32,110,111,100
	dw	101,32,104,97,115,32,110,111,32,115,105,98,108,105,110,103
	dw	115,46
	align	4
_154:
	dd	bbStringClass
	dd	2147483647
	dd	17
	dw	120,109,108,78,111,100,101,46,120,109,108,78,111,100,101,40
	dw	34
	align	4
_156:
	dd	bbStringClass
	dd	2147483647
	dd	41
	dw	34,44,32,70,97,108,115,101,41,58,32,84,104,101,32,114
	dw	111,111,116,32,110,111,100,101,32,104,97,115,32,110,111,32
	dw	115,105,98,108,105,110,103,115,46
	align	4
_181:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	34
	align	4
_180:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	61,34
	align	4
_179:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	32
	align	4
_183:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	47,62
	align	4
_182:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	60
	align	4
_2:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	62
	align	4
_184:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	60,47
	align	4
_196:
	dd	bbStringClass
	dd	2147483647
	dd	53
	dw	34,41,58,32,84,114,105,101,100,32,116,111,32,108,111,97
	dw	100,32,97,32,110,111,110,45,98,105,110,97,114,121,32,102
	dw	105,108,101,32,97,115,32,97,32,98,105,110,97,114,121,32
	dw	102,105,108,101,46
	align	4
_212:
	dd	bbStringClass
	dd	2147483647
	dd	59
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,69,120,112,101,99,116,105,110,103,32,101,113,117,97,108
	dw	115,32,40,61,41,32,97,102,116,101,114,32,97,116,116,114
	dw	105,98,117,116,101,32,110,97,109,101,46
	align	4
_213:
	dd	bbStringClass
	dd	2147483647
	dd	43
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,69,120,112,101,99,116,105,110,103,32,97,116,116,114,105
	dw	98,117,116,101,32,118,97,108,117,101,46
	align	4
_214:
	dd	bbStringClass
	dd	2147483647
	dd	53
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,85,110,99,108,111,115,101,100,32,116,97,103,32,40,101
	dw	120,112,101,99,116,105,110,103,32,34,47,62,34,32,111,114
	dw	32,34,62,34,41
	align	4
_215:
	dd	bbStringClass
	dd	2147483647
	dd	63
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,77,105,115,112,108,97,99,101,100,32,99,108,111,115,105
	dw	110,103,32,116,97,103,32,40,110,111,32,116,97,103,32,104
	dw	97,115,32,98,101,101,110,32,111,112,101,110,101,100,41
	align	4
_216:
	dd	bbStringClass
	dd	2147483647
	dd	56
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,67,108,111,115,105,110,103,32,116,97,103,32,100,111,101
	dw	115,32,110,111,116,32,109,97,116,99,104,32,111,112,101,110
	dw	105,110,103,32,116,97,103,46
	align	4
_217:
	dd	bbStringClass
	dd	2147483647
	dd	45
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,85,110,99,108,111,115,101,100,32,116,97,103,32,40,101
	dw	120,112,101,99,116,105,110,103,32,34,62,34,41
	align	4
_218:
	dd	bbStringClass
	dd	2147483647
	dd	60
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,77,105,115,112,108,97,99,101,100,32,116,101,120,116,32
	dw	40,112,111,115,115,105,98,108,121,32,110,111,116,32,97,110
	dw	32,120,109,108,32,102,105,108,101,41,58,32
	align	4
_219:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	47
	align	4
_220:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	61
	align	4
_221:
	dd	bbStringClass
	dd	2147483647
	dd	63
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,77,105,115,112,108,97,99,101,100,32,116,97,103,32,101
	dw	110,100,32,40,101,120,112,101,99,116,105,110,103,32,116,97
	dw	103,32,111,114,32,116,97,103,32,100,97,116,97,41,46
	align	4
_222:
	dd	bbStringClass
	dd	2147483647
	dd	56
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,85,110,99,108,111,115,101,100,32,110,111,100,101,32,116
	dw	97,103,32,40,114,101,97,99,104,101,100,32,101,110,100,32
	dw	111,102,32,102,105,108,101,41
	align	4
_265:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	59
	align	4
_264:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	38,35
	align	4
_259:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	38,108,116,59
	align	4
_260:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	38,103,116,59
	align	4
_261:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	38,113,117,111,116,59
	align	4
_262:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	38,97,112,111,115,59
	align	4
_263:
	dd	bbStringClass
	dd	2147483647
	dd	5
	dw	38,97,109,112,59
