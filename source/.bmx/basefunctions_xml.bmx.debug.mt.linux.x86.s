	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_source_basefunctions_zip
	extrn	bbEmptyString
	extrn	bbExThrow
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
	extrn	bbStringConcat
	extrn	bbStringFromChar
	extrn	bbStringFromInt
	extrn	bbStringSlice
	extrn	bbStringToLower
	extrn	bb_ZipWriter
	extrn	brl_bank_TBank
	extrn	brl_blitz_ArrayBoundsError
	extrn	brl_blitz_NullObjectError
	extrn	brl_blitz_RuntimeError
	extrn	brl_filesystem_DeleteFile
	extrn	brl_linkedlist_TList
	extrn	brl_retro_Trim
	extrn	brl_standardio_Print
	extrn	brl_stream_OpenStream
	public	__bb_source_basefunctions_xml
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
	push	ebx
	cmp	dword [_673],0
	je	_674
	mov	eax,0
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_674:
	mov	dword [_673],1
	push	ebp
	push	_594
	call	dword [bbOnDebugEnterScope]
	add	esp,8
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
	push	_583
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_586
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_588
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_590
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_592
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	jmp	_358
_358:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_676
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_xmlDocument
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbNullObject
	push	ebp
	push	_675
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_361
_361:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,4
_364:
	mov	eax,0
	jmp	_679
_679:
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Create:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	movzx	eax,byte [ebp+12]
	mov	eax,eax
	mov	byte [ebp-4],al
	mov	dword [ebp-12],bbNullObject
	push	ebp
	push	_689
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_680
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_xmlDocument
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-12],eax
	push	_682
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],_1
	je	_683
	push	ebp
	push	_687
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_684
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_686
	call	brl_blitz_NullObjectError
_686:
	movzx	eax,byte [ebp-4]
	push	eax
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_683:
	push	_688
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_368
_368:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Root:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_749
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_695
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_697
	call	brl_blitz_NullObjectError
_697:
	cmp	dword [ebx+8],bbNullObject
	jne	_698
	push	ebp
	push	_745
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_699
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_701
	call	brl_blitz_NullObjectError
_701:
	push	bb_xmlNode
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+8],eax
	push	_703
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_705
	call	brl_blitz_NullObjectError
_705:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_707
	call	brl_blitz_NullObjectError
_707:
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+24],eax
	push	_709
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_711
	call	brl_blitz_NullObjectError
_711:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_713
	call	brl_blitz_NullObjectError
_713:
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+28],eax
	push	_715
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_717
	call	brl_blitz_NullObjectError
_717:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_719
	call	brl_blitz_NullObjectError
_719:
	mov	dword [ebx+20],0
	push	_721
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_723
	call	brl_blitz_NullObjectError
_723:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_725
	call	brl_blitz_NullObjectError
_725:
	mov	dword [ebx+16],bbNullObject
	push	_727
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_729
	call	brl_blitz_NullObjectError
_729:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_731
	call	brl_blitz_NullObjectError
_731:
	mov	dword [ebx+8],_3
	push	_733
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_735
	call	brl_blitz_NullObjectError
_735:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_737
	call	brl_blitz_NullObjectError
_737:
	mov	dword [ebx+12],_1
	push	_739
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_741
	call	brl_blitz_NullObjectError
_741:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_743
	call	brl_blitz_NullObjectError
_743:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+36],eax
	call	dword [bbOnDebugLeaveScope]
_698:
	push	_746
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_748
	call	brl_blitz_NullObjectError
_748:
	mov	ebx,dword [ebx+8]
	jmp	_371
_371:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Load:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-12],eax
	movzx	eax,byte [ebp+16]
	mov	eax,eax
	mov	byte [ebp-4],al
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],0
	push	ebp
	push	_816
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_750
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_752
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	push	_754
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_755
	push	ebp
	push	_762
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_756
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbStringClass
	push	dword [ebp-12]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_758
	mov	eax,bbEmptyString
_758:
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
	mov	dword [ebp-16],eax
	push	_759
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_761
	call	brl_blitz_NullObjectError
_761:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	push	eax
	call	bbStringFromInt
	add	esp,4
	push	eax
	call	brl_standardio_Print
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	jmp	_763
_755:
	push	ebp
	push	_765
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_764
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	1
	push	dword [ebp-12]
	call	brl_stream_OpenStream
	add	esp,12
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
_763:
	push	_766
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],1
	push	_767
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],bbNullObject
	jne	_768
	push	ebp
	push	_772
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_769
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbStringClass
	push	dword [ebp-12]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_771
	mov	eax,bbEmptyString
_771:
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
	call	dword [bbOnDebugLeaveScope]
_768:
	push	_773
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_775
	call	brl_blitz_NullObjectError
_775:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,216
	jne	_776
	push	ebp
	push	_788
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_777
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_779
	call	brl_blitz_NullObjectError
_779:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,241
	jne	_780
	push	ebp
	push	_787
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_781
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_783
	call	brl_blitz_NullObjectError
_783:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,188
	jne	_784
	push	ebp
	push	_786
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_785
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],2
	call	dword [bbOnDebugLeaveScope]
_784:
	call	dword [bbOnDebugLeaveScope]
_780:
	call	dword [bbOnDebugLeaveScope]
_776:
	push	_789
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_791
	call	brl_blitz_NullObjectError
_791:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	_792
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-20]
	cmp	eax,1
	je	_795
	cmp	eax,2
	je	_796
	jmp	_794
_795:
	push	ebp
	push	_802
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_797
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	push	eax
	push	dword [ebp-12]
	call	_204
	add	esp,8
	push	_798
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_800
	call	brl_blitz_NullObjectError
_800:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	_801
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbNullObject
	push	dword [ebp-8]
	call	_205
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	jmp	_794
_796:
	push	ebp
	push	_808
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_803
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	call	_195
	add	esp,4
	push	_804
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_806
	call	brl_blitz_NullObjectError
_806:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	_807
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbNullObject
	push	dword [ebp-8]
	call	_197
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	jmp	_794
_794:
	push	_809
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],_8
	jne	_810
	push	ebp
	push	_815
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_811
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_8
	call	brl_filesystem_DeleteFile
	add	esp,4
	cmp	eax,0
	jne	_812
	push	ebp
	push	_814
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_813
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_9
	call	brl_standardio_Print
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_812:
	call	dword [bbOnDebugLeaveScope]
_810:
	mov	ebx,0
	jmp	_376
_376:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Save:
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
	mov	dword [ebp-20],bbNullObject
	mov	dword [ebp-24],bbNullObject
	push	ebp
	push	_889
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_819
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],bbNullObject
	push	_821
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_ZipWriter
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-24],eax
	push	_823
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_824
	push	ebp
	push	_826
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_825
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],_8
	call	dword [bbOnDebugLeaveScope]
_824:
	push	_827
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	0
	push	dword [ebp-12]
	call	brl_stream_OpenStream
	add	esp,12
	mov	dword [ebp-20],eax
	push	_828
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	cmp	eax,1
	je	_831
	cmp	eax,2
	je	_832
	jmp	_830
_831:
	push	ebp
	push	_844
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_833
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_835
	call	brl_blitz_NullObjectError
_835:
	push	_10
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+144]
	add	esp,8
	push	_836
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_838
	call	brl_blitz_NullObjectError
_838:
	cmp	dword [ebx+8],bbNullObject
	je	_839
	push	ebp
	push	_843
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_840
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_842
	call	brl_blitz_NullObjectError
_842:
	push	dword [ebx+8]
	push	dword [ebp-20]
	call	_175
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_839:
	call	dword [bbOnDebugLeaveScope]
	jmp	_830
_832:
	push	ebp
	push	_862
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_845
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_847
	call	brl_blitz_NullObjectError
_847:
	push	216
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+96]
	add	esp,8
	push	_848
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_850
	call	brl_blitz_NullObjectError
_850:
	push	241
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+96]
	add	esp,8
	push	_851
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_853
	call	brl_blitz_NullObjectError
_853:
	push	188
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+96]
	add	esp,8
	push	_854
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_856
	call	brl_blitz_NullObjectError
_856:
	cmp	dword [ebx+8],bbNullObject
	je	_857
	push	ebp
	push	_861
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_858
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_860
	call	brl_blitz_NullObjectError
_860:
	push	dword [ebx+8]
	push	dword [ebp-20]
	call	_188
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_857:
	call	dword [bbOnDebugLeaveScope]
	jmp	_830
_830:
	push	_863
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_865
	call	brl_blitz_NullObjectError
_865:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	push	_866
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_867
	push	ebp
	push	_888
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_868
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_870
	call	brl_blitz_NullObjectError
_870:
	push	0
	push	_11
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,12
	cmp	eax,0
	je	_871
	push	ebp
	push	_880
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_872
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_874
	call	brl_blitz_NullObjectError
_874:
	push	bbStringClass
	push	dword [ebp-12]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_876
	mov	eax,bbEmptyString
_876:
	push	_1
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,12
	push	_877
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_879
	call	brl_blitz_NullObjectError
_879:
	push	_1
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+92]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_871:
	push	_881
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	1
	push	0
	push	dword [ebp-12]
	call	brl_stream_OpenStream
	add	esp,12
	mov	dword [ebp-20],eax
	push	_882
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_884
	call	brl_blitz_NullObjectError
_884:
	push	0
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+96]
	add	esp,8
	push	_885
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_887
	call	brl_blitz_NullObjectError
_887:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_867:
	mov	ebx,0
	jmp	_382
_382:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_NodeCount:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_895
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_892
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_894
	call	brl_blitz_NullObjectError
_894:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	_266
	add	esp,4
	mov	ebx,eax
	jmp	_385
_385:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_SetEncryptionKey:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	push	ebp
	push	_896
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	mov	ebx,0
	jmp	_389
_389:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlDocument_Clear:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_908
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_898
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_900
	call	brl_blitz_NullObjectError
_900:
	cmp	dword [ebx+8],bbNullObject
	je	_901
	push	ebp
	push	_907
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_902
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_904
	call	brl_blitz_NullObjectError
_904:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_906
	call	brl_blitz_NullObjectError
_906:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+80]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_901:
	mov	ebx,0
	jmp	_392
_392:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_910
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_xmlNode
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbEmptyString
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],bbEmptyString
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],0
	mov	eax,dword [ebp-4]
	mov	dword [eax+24],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+28],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+32],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+36],bbNullObject
	push	ebp
	push	_909
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_395
_395:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_AddNode:
	push	ebp
	mov	ebp,esp
	sub	esp,16
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
	push	_985
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_911
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_913
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_xmlNode
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-16],eax
	push	_914
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_916
	call	brl_blitz_NullObjectError
_916:
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+24],eax
	push	_918
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_920
	call	brl_blitz_NullObjectError
_920:
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+28],eax
	push	_922
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_924
	call	brl_blitz_NullObjectError
_924:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_927
	call	brl_blitz_NullObjectError
_927:
	mov	eax,dword [esi+36]
	mov	dword [ebx+36],eax
	push	_928
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_930
	call	brl_blitz_NullObjectError
_930:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+8],eax
	push	_932
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_934
	call	brl_blitz_NullObjectError
_934:
	mov	dword [ebx+12],_1
	push	_936
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,1
	je	_939
	cmp	eax,2
	je	_940
	jmp	_938
_939:
	mov	eax,ebp
	push	eax
	push	_955
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_941
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_943
	call	brl_blitz_NullObjectError
_943:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+16],eax
	push	_945
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_947
	call	brl_blitz_NullObjectError
_947:
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_950
	call	brl_blitz_NullObjectError
_950:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_952
	call	brl_blitz_NullObjectError
_952:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_954
	call	brl_blitz_NullObjectError
_954:
	push	dword [ebp-16]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+32],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_938
_940:
	mov	eax,ebp
	push	eax
	push	_980
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_956
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_958
	call	brl_blitz_NullObjectError
_958:
	cmp	dword [ebx+16],bbNullObject
	jne	_959
	mov	eax,ebp
	push	eax
	push	_961
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_960
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_13
	push	dword [ebp-8]
	push	_12
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_959:
	push	_962
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_964
	call	brl_blitz_NullObjectError
_964:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_967
	call	brl_blitz_NullObjectError
_967:
	mov	eax,dword [esi+16]
	mov	dword [ebx+16],eax
	push	_968
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_970
	call	brl_blitz_NullObjectError
_970:
	mov	edi,ebx
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_973
	call	brl_blitz_NullObjectError
_973:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_975
	call	brl_blitz_NullObjectError
_975:
	mov	esi,dword [ebx+28]
	cmp	esi,bbNullObject
	jne	_977
	call	brl_blitz_NullObjectError
_977:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_979
	call	brl_blitz_NullObjectError
_979:
	push	dword [ebx+32]
	push	dword [ebp-16]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+100]
	add	esp,12
	mov	dword [edi+32],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_938
_938:
	push	_981
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_983
	call	brl_blitz_NullObjectError
_983:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+184]
	add	esp,4
	push	_984
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	jmp	_400
_400:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_MoveTo:
	push	ebp
	mov	ebp,esp
	sub	esp,16
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
	push	_1077
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_988
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_990
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_992
	call	brl_blitz_NullObjectError
_992:
	cmp	dword [ebx+16],bbNullObject
	jne	_993
	mov	eax,ebp
	push	eax
	push	_1002
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_994
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],1
	jne	_995
	mov	eax,ebp
	push	eax
	push	_997
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_996
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_14
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_995:
	push	_998
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],2
	jne	_999
	mov	eax,ebp
	push	eax
	push	_1001
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1000
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_15
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_999:
	call	dword [bbOnDebugLeaveScope]
_993:
	push	_1003
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	dword [ebp-8],eax
	jne	_1004
	mov	eax,ebp
	push	eax
	push	_1006
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1005
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_405
_1004:
	push	_1007
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [ebp-16],eax
	push	_1008
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_18:
	mov	eax,ebp
	push	eax
	push	_1023
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1009
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1011
	call	brl_blitz_NullObjectError
_1011:
	mov	eax,dword [ebx+16]
	mov	dword [ebp-16],eax
	push	_1012
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	dword [ebp-16],eax
	jne	_1013
	mov	eax,ebp
	push	eax
	push	_1022
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1014
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],1
	jne	_1015
	mov	eax,ebp
	push	eax
	push	_1017
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1016
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_19
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1015:
	push	_1018
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],2
	jne	_1019
	mov	eax,ebp
	push	eax
	push	_1021
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1020
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_20
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1019:
	call	dword [bbOnDebugLeaveScope]
_1013:
	call	dword [bbOnDebugLeaveScope]
_16:
	cmp	dword [ebp-16],bbNullObject
	jne	_18
_17:
	push	_1024
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1026
	call	brl_blitz_NullObjectError
_1026:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1028
	call	brl_blitz_NullObjectError
_1028:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	push	_1029
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,1
	je	_1032
	cmp	eax,2
	je	_1033
	jmp	_1031
_1032:
	mov	eax,ebp
	push	eax
	push	_1048
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1034
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1036
	call	brl_blitz_NullObjectError
_1036:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+16],eax
	push	_1038
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1040
	call	brl_blitz_NullObjectError
_1040:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1043
	call	brl_blitz_NullObjectError
_1043:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_1045
	call	brl_blitz_NullObjectError
_1045:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1047
	call	brl_blitz_NullObjectError
_1047:
	push	dword [ebp-4]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+32],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1031
_1033:
	mov	eax,ebp
	push	eax
	push	_1073
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1049
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1051
	call	brl_blitz_NullObjectError
_1051:
	cmp	dword [ebx+16],bbNullObject
	jne	_1052
	mov	eax,ebp
	push	eax
	push	_1054
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1053
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_21
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1052:
	push	_1055
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1057
	call	brl_blitz_NullObjectError
_1057:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_1060
	call	brl_blitz_NullObjectError
_1060:
	mov	eax,dword [esi+16]
	mov	dword [ebx+16],eax
	push	_1061
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1063
	call	brl_blitz_NullObjectError
_1063:
	mov	edi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1066
	call	brl_blitz_NullObjectError
_1066:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_1068
	call	brl_blitz_NullObjectError
_1068:
	mov	esi,dword [ebx+28]
	cmp	esi,bbNullObject
	jne	_1070
	call	brl_blitz_NullObjectError
_1070:
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1072
	call	brl_blitz_NullObjectError
_1072:
	push	dword [ebx+32]
	push	dword [ebp-4]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+100]
	add	esp,12
	mov	dword [edi+32],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1031
_1031:
	push	_1074
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1076
	call	brl_blitz_NullObjectError
_1076:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+184]
	add	esp,4
	mov	ebx,0
	jmp	_405
_405:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_CopyTo:
	push	ebp
	mov	ebp,esp
	sub	esp,16
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
	push	_1163
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1080
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1082
	call	brl_blitz_NullObjectError
_1082:
	cmp	dword [ebx+16],bbNullObject
	jne	_1083
	mov	eax,ebp
	push	eax
	push	_1092
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1084
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],1
	jne	_1085
	mov	eax,ebp
	push	eax
	push	_1087
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1086
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_22
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1085:
	push	_1088
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],2
	jne	_1089
	mov	eax,ebp
	push	eax
	push	_1091
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1090
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_23
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1089:
	call	dword [bbOnDebugLeaveScope]
_1083:
	push	_1093
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	dword [ebp-8],eax
	jne	_1094
	mov	eax,ebp
	push	eax
	push	_1103
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1095
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],1
	jne	_1096
	mov	eax,ebp
	push	eax
	push	_1098
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1097
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_24
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1096:
	push	_1099
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],2
	jne	_1100
	mov	eax,ebp
	push	eax
	push	_1102
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1101
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_25
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1100:
	call	dword [bbOnDebugLeaveScope]
_1094:
	push	_1104
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_1106
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1108
	call	brl_blitz_NullObjectError
_1108:
	push	bbNullObject
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
	mov	dword [ebp-16],eax
	push	_1109
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1111
	call	brl_blitz_NullObjectError
_1111:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1113
	call	brl_blitz_NullObjectError
_1113:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	push	_1114
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,1
	je	_1117
	cmp	eax,2
	je	_1118
	jmp	_1116
_1117:
	mov	eax,ebp
	push	eax
	push	_1133
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1119
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1121
	call	brl_blitz_NullObjectError
_1121:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+16],eax
	push	_1123
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1125
	call	brl_blitz_NullObjectError
_1125:
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_1128
	call	brl_blitz_NullObjectError
_1128:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_1130
	call	brl_blitz_NullObjectError
_1130:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1132
	call	brl_blitz_NullObjectError
_1132:
	push	dword [ebp-16]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+32],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1116
_1118:
	mov	eax,ebp
	push	eax
	push	_1158
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1134
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1136
	call	brl_blitz_NullObjectError
_1136:
	cmp	dword [ebx+16],bbNullObject
	jne	_1137
	mov	eax,ebp
	push	eax
	push	_1139
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1138
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_26
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1137:
	push	_1140
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1142
	call	brl_blitz_NullObjectError
_1142:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_1145
	call	brl_blitz_NullObjectError
_1145:
	mov	eax,dword [esi+16]
	mov	dword [ebx+16],eax
	push	_1146
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1148
	call	brl_blitz_NullObjectError
_1148:
	mov	edi,ebx
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1151
	call	brl_blitz_NullObjectError
_1151:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_1153
	call	brl_blitz_NullObjectError
_1153:
	mov	esi,dword [ebx+28]
	cmp	esi,bbNullObject
	jne	_1155
	call	brl_blitz_NullObjectError
_1155:
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1157
	call	brl_blitz_NullObjectError
_1157:
	push	dword [ebx+32]
	push	dword [ebp-16]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+100]
	add	esp,12
	mov	dword [edi+32],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1116
_1116:
	push	_1159
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1161
	call	brl_blitz_NullObjectError
_1161:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+184]
	add	esp,4
	push	_1162
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	jmp	_410
_410:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_Copy:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],bbNullObject
	mov	dword [ebp-24],bbNullObject
	mov	eax,ebp
	push	eax
	push	_1284
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1165
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1167
	call	brl_blitz_NullObjectError
_1167:
	cmp	dword [ebx+16],bbNullObject
	jne	_1168
	mov	eax,ebp
	push	eax
	push	_1170
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1169
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_27
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1168:
	push	_1171
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],bbNullObject
	push	_1174
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_xmlNode
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-12],eax
	push	_1175
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1177
	call	brl_blitz_NullObjectError
_1177:
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+28],eax
	push	_1179
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1181
	call	brl_blitz_NullObjectError
_1181:
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	mov	dword [ebx+24],eax
	push	_1183
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1185
	call	brl_blitz_NullObjectError
_1185:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1188
	call	brl_blitz_NullObjectError
_1188:
	mov	eax,dword [esi+8]
	mov	dword [ebx+8],eax
	push	_1189
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1191
	call	brl_blitz_NullObjectError
_1191:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1194
	call	brl_blitz_NullObjectError
_1194:
	mov	eax,dword [esi+12]
	mov	dword [ebx+12],eax
	push	_1195
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	jne	_1196
	mov	eax,ebp
	push	eax
	push	_1203
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1197
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1199
	call	brl_blitz_NullObjectError
_1199:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1202
	call	brl_blitz_NullObjectError
_1202:
	mov	eax,dword [esi+16]
	mov	dword [ebx+16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1204
_1196:
	mov	eax,ebp
	push	eax
	push	_1209
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1205
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1207
	call	brl_blitz_NullObjectError
_1207:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+16],eax
	call	dword [bbOnDebugLeaveScope]
_1204:
	push	_1210
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1212
	call	brl_blitz_NullObjectError
_1212:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1215
	call	brl_blitz_NullObjectError
_1215:
	mov	eax,dword [esi+20]
	mov	dword [ebx+20],eax
	push	_1216
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1218
	call	brl_blitz_NullObjectError
_1218:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_1221
	call	brl_blitz_NullObjectError
_1221:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_1223
	call	brl_blitz_NullObjectError
_1223:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1225
	call	brl_blitz_NullObjectError
_1225:
	push	dword [ebp-12]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+32],eax
	push	_1226
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],bbNullObject
	mov	dword [ebp-24],bbNullObject
	push	_1229
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1231
	call	brl_blitz_NullObjectError
_1231:
	mov	eax,dword [ebx+24]
	mov	dword [ebp-28],eax
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_1234
	call	brl_blitz_NullObjectError
_1234:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_28
_30:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1239
	call	brl_blitz_NullObjectError
_1239:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],bbNullObject
	je	_28
	mov	eax,ebp
	push	eax
	push	_1267
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1240
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_xmlAttribute
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-24],eax
	push	_1241
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1243
	call	brl_blitz_NullObjectError
_1243:
	mov	esi,ebx
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1246
	call	brl_blitz_NullObjectError
_1246:
	mov	eax,dword [ebx+8]
	mov	dword [esi+8],eax
	push	_1247
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1249
	call	brl_blitz_NullObjectError
_1249:
	mov	esi,ebx
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1252
	call	brl_blitz_NullObjectError
_1252:
	mov	eax,dword [ebx+12]
	mov	dword [esi+12],eax
	push	_1253
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1255
	call	brl_blitz_NullObjectError
_1255:
	mov	esi,ebx
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1258
	call	brl_blitz_NullObjectError
_1258:
	mov	eax,dword [ebx+16]
	mov	dword [esi+16],eax
	push	_1259
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_1261
	call	brl_blitz_NullObjectError
_1261:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_1264
	call	brl_blitz_NullObjectError
_1264:
	mov	esi,dword [esi+24]
	cmp	esi,bbNullObject
	jne	_1266
	call	brl_blitz_NullObjectError
_1266:
	push	dword [ebp-20]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+20],eax
	call	dword [bbOnDebugLeaveScope]
_28:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1237
	call	brl_blitz_NullObjectError
_1237:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_30
_29:
	push	_1268
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1270
	call	brl_blitz_NullObjectError
_1270:
	mov	edi,dword [ebx+28]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1273
	call	brl_blitz_NullObjectError
_1273:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_31
_33:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1278
	call	brl_blitz_NullObjectError
_1278:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-16],eax
	cmp	dword [ebp-16],bbNullObject
	je	_31
	mov	eax,ebp
	push	eax
	push	_1282
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1279
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1281
	call	brl_blitz_NullObjectError
_1281:
	push	dword [ebp-12]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_31:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1276
	call	brl_blitz_NullObjectError
_1276:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_33
_32:
	push	_1283
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_414
_414:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SwapWith:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],bbNullObject
	mov	dword [ebp-24],0
	mov	dword [ebp-28],bbNullObject
	mov	eax,ebp
	push	eax
	push	_1508
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1290
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	push	_1292
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	dword [ebp-8],eax
	jne	_1293
	mov	eax,ebp
	push	eax
	push	_1295
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1294
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_418
_1293:
	push	_1296
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [ebp-12],eax
	push	_1297
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_36:
	mov	eax,ebp
	push	eax
	push	_1305
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1298
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1300
	call	brl_blitz_NullObjectError
_1300:
	mov	eax,dword [ebx+16]
	mov	dword [ebp-12],eax
	push	_1301
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	dword [ebp-12],eax
	jne	_1302
	mov	eax,ebp
	push	eax
	push	_1304
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1303
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_37
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1302:
	call	dword [bbOnDebugLeaveScope]
_34:
	cmp	dword [ebp-12],bbNullObject
	jne	_36
_35:
	push	_1306
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [ebp-12],eax
	push	_1307
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_40:
	mov	eax,ebp
	push	eax
	push	_1315
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1308
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1310
	call	brl_blitz_NullObjectError
_1310:
	mov	eax,dword [ebx+16]
	mov	dword [ebp-12],eax
	push	_1311
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	cmp	dword [ebp-12],eax
	jne	_1312
	mov	eax,ebp
	push	eax
	push	_1314
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1313
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_41
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1312:
	call	dword [bbOnDebugLeaveScope]
_38:
	cmp	dword [ebp-12],bbNullObject
	jne	_40
_39:
	push	_1316
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1318
	call	brl_blitz_NullObjectError
_1318:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1320
	call	brl_blitz_NullObjectError
_1320:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_1322
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1324
	call	brl_blitz_NullObjectError
_1324:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1326
	call	brl_blitz_NullObjectError
_1326:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	mov	dword [ebp-20],eax
	push	_1328
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_1330
	call	brl_blitz_NullObjectError
_1330:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1332
	call	brl_blitz_NullObjectError
_1332:
	mov	eax,dword [esi+16]
	cmp	eax,dword [ebx+16]
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_1335
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1334
	call	brl_blitz_NullObjectError
_1334:
	mov	eax,dword [ebx+16]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
_1335:
	cmp	eax,0
	je	_1337
	mov	eax,ebp
	push	eax
	push	_1384
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1338
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1340
	call	brl_blitz_NullObjectError
_1340:
	mov	eax,dword [ebx+32]
	cmp	dword [ebp-20],eax
	jne	_1341
	mov	eax,ebp
	push	eax
	push	_1360
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1342
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1344
	call	brl_blitz_NullObjectError
_1344:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1346
	call	brl_blitz_NullObjectError
_1346:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	push	_1347
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1349
	call	brl_blitz_NullObjectError
_1349:
	mov	edi,ebx
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1352
	call	brl_blitz_NullObjectError
_1352:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_1354
	call	brl_blitz_NullObjectError
_1354:
	mov	esi,dword [ebx+28]
	cmp	esi,bbNullObject
	jne	_1356
	call	brl_blitz_NullObjectError
_1356:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1358
	call	brl_blitz_NullObjectError
_1358:
	push	dword [ebx+32]
	push	dword [ebp-8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+100]
	add	esp,12
	mov	dword [edi+32],eax
	push	_1359
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_418
_1341:
	push	_1361
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1363
	call	brl_blitz_NullObjectError
_1363:
	mov	eax,dword [ebx+32]
	cmp	dword [ebp-16],eax
	jne	_1364
	mov	eax,ebp
	push	eax
	push	_1383
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1365
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1367
	call	brl_blitz_NullObjectError
_1367:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1369
	call	brl_blitz_NullObjectError
_1369:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	push	_1370
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1372
	call	brl_blitz_NullObjectError
_1372:
	mov	edi,ebx
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1375
	call	brl_blitz_NullObjectError
_1375:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_1377
	call	brl_blitz_NullObjectError
_1377:
	mov	esi,dword [ebx+28]
	cmp	esi,bbNullObject
	jne	_1379
	call	brl_blitz_NullObjectError
_1379:
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1381
	call	brl_blitz_NullObjectError
_1381:
	push	dword [ebx+32]
	push	dword [ebp-4]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+100]
	add	esp,12
	mov	dword [edi+32],eax
	push	_1382
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_418
_1364:
	call	dword [bbOnDebugLeaveScope]
_1337:
	push	_1385
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1387
	call	brl_blitz_NullObjectError
_1387:
	cmp	dword [ebx+16],bbNullObject
	je	_1388
	mov	eax,ebp
	push	eax
	push	_1394
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1389
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1391
	call	brl_blitz_NullObjectError
_1391:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1393
	call	brl_blitz_NullObjectError
_1393:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1388:
	push	_1395
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1397
	call	brl_blitz_NullObjectError
_1397:
	cmp	dword [ebx+16],bbNullObject
	je	_1398
	mov	eax,ebp
	push	eax
	push	_1404
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1399
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1401
	call	brl_blitz_NullObjectError
_1401:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1403
	call	brl_blitz_NullObjectError
_1403:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1398:
	push	_1405
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1407
	call	brl_blitz_NullObjectError
_1407:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1409
	call	brl_blitz_NullObjectError
_1409:
	mov	eax,dword [esi+16]
	cmp	dword [ebx+16],eax
	je	_1410
	mov	eax,ebp
	push	eax
	push	_1439
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1411
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1413
	call	brl_blitz_NullObjectError
_1413:
	mov	eax,dword [ebx+20]
	mov	dword [ebp-24],eax
	push	_1415
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1417
	call	brl_blitz_NullObjectError
_1417:
	mov	eax,dword [ebx+16]
	mov	dword [ebp-28],eax
	push	_1419
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1421
	call	brl_blitz_NullObjectError
_1421:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1424
	call	brl_blitz_NullObjectError
_1424:
	mov	eax,dword [esi+20]
	mov	dword [ebx+20],eax
	push	_1425
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1427
	call	brl_blitz_NullObjectError
_1427:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1430
	call	brl_blitz_NullObjectError
_1430:
	mov	eax,dword [esi+16]
	mov	dword [ebx+16],eax
	push	_1431
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1433
	call	brl_blitz_NullObjectError
_1433:
	mov	eax,dword [ebp-24]
	mov	dword [ebx+20],eax
	push	_1435
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1437
	call	brl_blitz_NullObjectError
_1437:
	mov	eax,dword [ebp-28]
	mov	dword [ebx+16],eax
	call	dword [bbOnDebugLeaveScope]
_1410:
	push	_1442
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1444
	call	brl_blitz_NullObjectError
_1444:
	cmp	dword [ebx+16],bbNullObject
	je	_1445
	mov	eax,ebp
	push	eax
	push	_1471
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1446
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-20],bbNullObject
	jne	_1447
	mov	eax,ebp
	push	eax
	push	_1458
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1448
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1450
	call	brl_blitz_NullObjectError
_1450:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_1453
	call	brl_blitz_NullObjectError
_1453:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_1455
	call	brl_blitz_NullObjectError
_1455:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1457
	call	brl_blitz_NullObjectError
_1457:
	push	dword [ebp-8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebx+32],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1459
_1447:
	mov	eax,ebp
	push	eax
	push	_1470
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1460
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1462
	call	brl_blitz_NullObjectError
_1462:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_1465
	call	brl_blitz_NullObjectError
_1465:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_1467
	call	brl_blitz_NullObjectError
_1467:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1469
	call	brl_blitz_NullObjectError
_1469:
	push	dword [ebp-20]
	push	dword [ebp-8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+100]
	add	esp,12
	mov	dword [ebx+32],eax
	call	dword [bbOnDebugLeaveScope]
_1459:
	call	dword [bbOnDebugLeaveScope]
_1445:
	push	_1472
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1474
	call	brl_blitz_NullObjectError
_1474:
	cmp	dword [ebx+16],bbNullObject
	je	_1475
	mov	eax,ebp
	push	eax
	push	_1501
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1476
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],bbNullObject
	jne	_1477
	mov	eax,ebp
	push	eax
	push	_1488
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1478
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1480
	call	brl_blitz_NullObjectError
_1480:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1483
	call	brl_blitz_NullObjectError
_1483:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_1485
	call	brl_blitz_NullObjectError
_1485:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1487
	call	brl_blitz_NullObjectError
_1487:
	push	dword [ebp-4]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+64]
	add	esp,8
	mov	dword [ebx+32],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1489
_1477:
	mov	eax,ebp
	push	eax
	push	_1500
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1490
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1492
	call	brl_blitz_NullObjectError
_1492:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1495
	call	brl_blitz_NullObjectError
_1495:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_1497
	call	brl_blitz_NullObjectError
_1497:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1499
	call	brl_blitz_NullObjectError
_1499:
	push	dword [ebp-16]
	push	dword [ebp-4]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+100]
	add	esp,12
	mov	dword [ebx+32],eax
	call	dword [bbOnDebugLeaveScope]
_1489:
	call	dword [bbOnDebugLeaveScope]
_1475:
	push	_1502
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1504
	call	brl_blitz_NullObjectError
_1504:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+184]
	add	esp,4
	push	_1505
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_1507
	call	brl_blitz_NullObjectError
_1507:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+184]
	add	esp,4
	mov	ebx,0
	jmp	_418
_418:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_GetIndex:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],bbNullObject
	push	ebp
	push	_1524
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1511
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	push	_1513
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1515
	call	brl_blitz_NullObjectError
_1515:
	mov	eax,dword [ebx+32]
	mov	dword [ebp-12],eax
	push	_1517
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_44:
	push	ebp
	push	_1522
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1518
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_1520
	call	brl_blitz_NullObjectError
_1520:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	mov	dword [ebp-12],eax
	push	_1521
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [ebp-8],1
	call	dword [bbOnDebugLeaveScope]
_42:
	cmp	dword [ebp-12],bbNullObject
	jne	_44
_43:
	push	_1523
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	jmp	_421
_421:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SetIndex:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbNullObject
	push	ebp
	push	_1570
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1526
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1528
	call	brl_blitz_NullObjectError
_1528:
	cmp	dword [ebx+16],bbNullObject
	jne	_1529
	push	ebp
	push	_1531
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1530
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_46
	push	dword [ebp-8]
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
	call	dword [bbOnDebugLeaveScope]
_1529:
	push	_1532
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],1
	jge	_1533
	push	ebp
	push	_1535
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1534
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_47
	push	dword [ebp-8]
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
	call	dword [bbOnDebugLeaveScope]
_1533:
	push	_1536
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	push	_1538
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1540
	call	brl_blitz_NullObjectError
_1540:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_1542
	call	brl_blitz_NullObjectError
_1542:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1544
	call	brl_blitz_NullObjectError
_1544:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_1546
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],1
	mov	ebx,dword [ebp-8]
	sub	ebx,1
	jmp	_1547
_50:
	push	ebp
	push	_1554
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1549
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_1551
	call	brl_blitz_NullObjectError
_1551:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_1552
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],bbNullObject
	jne	_1553
	push	_51
	push	dword [ebp-8]
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
	call	brl_blitz_RuntimeError
	add	esp,4
_1553:
	call	dword [bbOnDebugLeaveScope]
_48:
	add	dword [ebp-12],1
_1547:
	cmp	dword [ebp-12],ebx
	jle	_50
_49:
	push	_1555
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1557
	call	brl_blitz_NullObjectError
_1557:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1559
	call	brl_blitz_NullObjectError
_1559:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	push	_1560
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1562
	call	brl_blitz_NullObjectError
_1562:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_1565
	call	brl_blitz_NullObjectError
_1565:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_1567
	call	brl_blitz_NullObjectError
_1567:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1569
	call	brl_blitz_NullObjectError
_1569:
	push	dword [ebp-16]
	push	dword [ebp-4]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+96]
	add	esp,12
	mov	dword [ebx+32],eax
	mov	ebx,0
	jmp	_425
_425:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_IsRoot:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1581
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1572
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1574
	call	brl_blitz_NullObjectError
_1574:
	cmp	dword [ebx+16],bbNullObject
	jne	_1575
	push	ebp
	push	_1577
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1576
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	jmp	_428
_1575:
	push	ebp
	push	_1580
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1579
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_428
_428:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_Free:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1626
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1582
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_52
_54:
	push	ebp
	push	_1594
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1587
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1589
	call	brl_blitz_NullObjectError
_1589:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1591
	call	brl_blitz_NullObjectError
_1591:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_1593
	call	brl_blitz_NullObjectError
_1593:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+80]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_52:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1584
	call	brl_blitz_NullObjectError
_1584:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1586
	call	brl_blitz_NullObjectError
_1586:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_54
_53:
	push	_1595
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_55
_57:
	push	ebp
	push	_1607
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1600
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1602
	call	brl_blitz_NullObjectError
_1602:
	mov	ebx,dword [ebx+24]
	cmp	ebx,bbNullObject
	jne	_1604
	call	brl_blitz_NullObjectError
_1604:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_1606
	call	brl_blitz_NullObjectError
_1606:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_55:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1597
	call	brl_blitz_NullObjectError
_1597:
	mov	ebx,dword [ebx+24]
	cmp	ebx,bbNullObject
	jne	_1599
	call	brl_blitz_NullObjectError
_1599:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_57
_56:
	push	_1608
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1610
	call	brl_blitz_NullObjectError
_1610:
	cmp	dword [ebx+16],bbNullObject
	je	_1611
	push	ebp
	push	_1617
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1612
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1614
	call	brl_blitz_NullObjectError
_1614:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_1616
	call	brl_blitz_NullObjectError
_1616:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_1611:
	push	_1618
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1620
	call	brl_blitz_NullObjectError
_1620:
	mov	dword [ebx+16],bbNullObject
	push	_1622
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1624
	call	brl_blitz_NullObjectError
_1624:
	mov	dword [ebx+32],bbNullObject
	mov	ebx,0
	jmp	_431
_431:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_HasChildren:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1638
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1627
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1629
	call	brl_blitz_NullObjectError
_1629:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1631
	call	brl_blitz_NullObjectError
_1631:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1632
	push	ebp
	push	_1634
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1633
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_434
_1632:
	push	ebp
	push	_1637
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1636
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	jmp	_434
_434:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FirstChild:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1654
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1639
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1641
	call	brl_blitz_NullObjectError
_1641:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1643
	call	brl_blitz_NullObjectError
_1643:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1644
	push	ebp
	push	_1646
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1645
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_437
_1644:
	push	ebp
	push	_1653
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1648
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1650
	call	brl_blitz_NullObjectError
_1650:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1652
	call	brl_blitz_NullObjectError
_1652:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_437
_437:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_LastChild:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1670
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1655
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1657
	call	brl_blitz_NullObjectError
_1657:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1659
	call	brl_blitz_NullObjectError
_1659:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1660
	push	ebp
	push	_1662
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1661
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_440
_1660:
	push	ebp
	push	_1669
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1664
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1666
	call	brl_blitz_NullObjectError
_1666:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1668
	call	brl_blitz_NullObjectError
_1668:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_440
_440:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_GetChild:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbNullObject
	push	ebp
	push	_1695
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1671
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],1
	jge	_1672
	push	ebp
	push	_1674
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1673
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_47
	push	dword [ebp-8]
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
	call	dword [bbOnDebugLeaveScope]
_1672:
	push	_1675
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	push	_1677
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1679
	call	brl_blitz_NullObjectError
_1679:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1681
	call	brl_blitz_NullObjectError
_1681:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_1683
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],1
	mov	ebx,dword [ebp-8]
	sub	ebx,1
	jmp	_1684
_60:
	push	ebp
	push	_1691
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1686
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_1688
	call	brl_blitz_NullObjectError
_1688:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_1689
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],bbNullObject
	jne	_1690
	push	_51
	push	dword [ebp-8]
	call	bbStringFromInt
	add	esp,4
	push	eax
	push	_61
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_blitz_RuntimeError
	add	esp,4
_1690:
	call	dword [bbOnDebugLeaveScope]
_58:
	add	dword [ebp-12],1
_1684:
	cmp	dword [ebp-12],ebx
	jle	_60
_59:
	push	_1692
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_1694
	call	brl_blitz_NullObjectError
_1694:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_444
_444:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_ChildCount:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_1701
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1696
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1698
	call	brl_blitz_NullObjectError
_1698:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1700
	call	brl_blitz_NullObjectError
_1700:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+112]
	add	esp,4
	mov	ebx,eax
	jmp	_447
_447:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FindChild:
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
	mov	dword [ebp-20],bbNullObject
	mov	dword [ebp-24],bbNullObject
	mov	eax,ebp
	push	eax
	push	_1785
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1702
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],bbNullObject
	mov	dword [ebp-24],bbNullObject
	push	_1705
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1707
	call	brl_blitz_NullObjectError
_1707:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1709
	call	brl_blitz_NullObjectError
_1709:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1710
	mov	eax,ebp
	push	eax
	push	_1712
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1711
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_453
_1710:
	push	_1713
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],0
	je	_1714
	mov	eax,ebp
	push	eax
	push	_1733
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1715
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1717
	call	brl_blitz_NullObjectError
_1717:
	mov	edi,dword [ebx+28]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1720
	call	brl_blitz_NullObjectError
_1720:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_62
_64:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1725
	call	brl_blitz_NullObjectError
_1725:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],bbNullObject
	je	_62
	mov	eax,ebp
	push	eax
	push	_1732
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1726
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1728
	call	brl_blitz_NullObjectError
_1728:
	push	dword [ebp-8]
	push	dword [ebx+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1729
	mov	eax,ebp
	push	eax
	push	_1731
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1730
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_453
_1729:
	call	dword [bbOnDebugLeaveScope]
_62:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1723
	call	brl_blitz_NullObjectError
_1723:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_64
_63:
	call	dword [bbOnDebugLeaveScope]
	jmp	_1734
_1714:
	mov	eax,ebp
	push	eax
	push	_1754
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1735
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_1736
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1738
	call	brl_blitz_NullObjectError
_1738:
	mov	edi,dword [ebx+28]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1741
	call	brl_blitz_NullObjectError
_1741:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_65
_67:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1746
	call	brl_blitz_NullObjectError
_1746:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],bbNullObject
	je	_65
	mov	eax,ebp
	push	eax
	push	_1753
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1747
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_1749
	call	brl_blitz_NullObjectError
_1749:
	push	dword [ebp-8]
	push	dword [ebx+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1750
	mov	eax,ebp
	push	eax
	push	_1752
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1751
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_453
_1750:
	call	dword [bbOnDebugLeaveScope]
_65:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1744
	call	brl_blitz_NullObjectError
_1744:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_67
_66:
	call	dword [bbOnDebugLeaveScope]
_1734:
	push	_1755
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	je	_1756
	mov	eax,ebp
	push	eax
	push	_1783
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1757
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1759
	call	brl_blitz_NullObjectError
_1759:
	mov	edi,dword [ebx+28]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1762
	call	brl_blitz_NullObjectError
_1762:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_68
_70:
	cmp	ebx,bbNullObject
	jne	_1767
	call	brl_blitz_NullObjectError
_1767:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-20],eax
	cmp	dword [ebp-20],bbNullObject
	je	_68
	mov	eax,ebp
	push	eax
	push	_1782
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1768
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-20]
	cmp	esi,bbNullObject
	jne	_1770
	call	brl_blitz_NullObjectError
_1770:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1772
	call	brl_blitz_NullObjectError
_1772:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	jne	_1773
	mov	eax,ebp
	push	eax
	push	_1781
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1774
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-20]
	cmp	esi,bbNullObject
	jne	_1776
	call	brl_blitz_NullObjectError
_1776:
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+104]
	add	esp,16
	mov	dword [ebp-24],eax
	push	_1777
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-24],bbNullObject
	je	_1778
	mov	eax,ebp
	push	eax
	push	_1780
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1779
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-24]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_453
_1778:
	call	dword [bbOnDebugLeaveScope]
_1773:
	call	dword [bbOnDebugLeaveScope]
_68:
	cmp	ebx,bbNullObject
	jne	_1765
	call	brl_blitz_NullObjectError
_1765:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_70
_69:
	call	dword [bbOnDebugLeaveScope]
_1756:
	push	_1784
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	jmp	_453
_453:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FindChildEx:
	push	ebp
	mov	ebp,esp
	sub	esp,36
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
	mov	dword [ebp-28],bbNullObject
	mov	dword [ebp-32],bbNullObject
	mov	dword [ebp-36],bbNullObject
	mov	eax,ebp
	push	eax
	push	_1894
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1788
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-28],bbNullObject
	mov	dword [ebp-32],bbNullObject
	mov	dword [ebp-36],bbNullObject
	push	_1792
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1794
	call	brl_blitz_NullObjectError
_1794:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1796
	call	brl_blitz_NullObjectError
_1796:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_1797
	mov	eax,ebp
	push	eax
	push	_1799
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1798
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_461
_1797:
	push	_1800
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-24],0
	je	_1801
	mov	eax,ebp
	push	eax
	push	_1831
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1802
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1804
	call	brl_blitz_NullObjectError
_1804:
	mov	edi,dword [ebx+28]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1807
	call	brl_blitz_NullObjectError
_1807:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_71
_73:
	cmp	ebx,bbNullObject
	jne	_1812
	call	brl_blitz_NullObjectError
_1812:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-28],eax
	cmp	dword [ebp-28],bbNullObject
	je	_71
	mov	eax,ebp
	push	eax
	push	_1830
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1813
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-28]
	cmp	esi,bbNullObject
	jne	_1815
	call	brl_blitz_NullObjectError
_1815:
	push	dword [ebp-8]
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1816
	mov	eax,ebp
	push	eax
	push	_1829
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1817
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-28]
	cmp	esi,bbNullObject
	jne	_1819
	call	brl_blitz_NullObjectError
_1819:
	push	1
	push	dword [ebp-12]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+176]
	add	esp,12
	mov	dword [ebp-32],eax
	push	_1820
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-32],bbNullObject
	je	_1821
	mov	eax,ebp
	push	eax
	push	_1828
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1822
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-32]
	cmp	esi,bbNullObject
	jne	_1824
	call	brl_blitz_NullObjectError
_1824:
	push	dword [ebp-16]
	push	dword [esi+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1825
	mov	eax,ebp
	push	eax
	push	_1827
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1826
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_461
_1825:
	call	dword [bbOnDebugLeaveScope]
_1821:
	call	dword [bbOnDebugLeaveScope]
_1816:
	call	dword [bbOnDebugLeaveScope]
_71:
	cmp	ebx,bbNullObject
	jne	_1810
	call	brl_blitz_NullObjectError
_1810:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_73
_72:
	call	dword [bbOnDebugLeaveScope]
	jmp	_1832
_1801:
	mov	eax,ebp
	push	eax
	push	_1863
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1833
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_1834
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1836
	call	brl_blitz_NullObjectError
_1836:
	mov	edi,dword [ebx+28]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1839
	call	brl_blitz_NullObjectError
_1839:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_74
_76:
	cmp	ebx,bbNullObject
	jne	_1844
	call	brl_blitz_NullObjectError
_1844:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-28],eax
	cmp	dword [ebp-28],bbNullObject
	je	_74
	mov	eax,ebp
	push	eax
	push	_1862
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1845
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-28]
	cmp	esi,bbNullObject
	jne	_1847
	call	brl_blitz_NullObjectError
_1847:
	push	dword [ebp-8]
	push	dword [esi+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1848
	mov	eax,ebp
	push	eax
	push	_1861
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1849
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-28]
	cmp	esi,bbNullObject
	jne	_1851
	call	brl_blitz_NullObjectError
_1851:
	push	0
	push	dword [ebp-12]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+176]
	add	esp,12
	mov	dword [ebp-32],eax
	push	_1852
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-32],bbNullObject
	je	_1853
	mov	eax,ebp
	push	eax
	push	_1860
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1854
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-32]
	cmp	esi,bbNullObject
	jne	_1856
	call	brl_blitz_NullObjectError
_1856:
	push	dword [ebp-16]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [esi+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_1857
	mov	eax,ebp
	push	eax
	push	_1859
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1858
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_461
_1857:
	call	dword [bbOnDebugLeaveScope]
_1853:
	call	dword [bbOnDebugLeaveScope]
_1848:
	call	dword [bbOnDebugLeaveScope]
_74:
	cmp	ebx,bbNullObject
	jne	_1842
	call	brl_blitz_NullObjectError
_1842:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_76
_75:
	call	dword [bbOnDebugLeaveScope]
_1832:
	push	_1864
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-20],0
	je	_1865
	mov	eax,ebp
	push	eax
	push	_1892
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1866
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1868
	call	brl_blitz_NullObjectError
_1868:
	mov	edi,dword [ebx+28]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1871
	call	brl_blitz_NullObjectError
_1871:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_77
_79:
	cmp	ebx,bbNullObject
	jne	_1876
	call	brl_blitz_NullObjectError
_1876:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-28],eax
	cmp	dword [ebp-28],bbNullObject
	je	_77
	mov	eax,ebp
	push	eax
	push	_1891
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1877
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-28]
	cmp	esi,bbNullObject
	jne	_1879
	call	brl_blitz_NullObjectError
_1879:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_1881
	call	brl_blitz_NullObjectError
_1881:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	jne	_1882
	mov	eax,ebp
	push	eax
	push	_1890
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1883
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-28]
	cmp	esi,bbNullObject
	jne	_1885
	call	brl_blitz_NullObjectError
_1885:
	push	dword [ebp-24]
	push	dword [ebp-20]
	push	dword [ebp-16]
	push	dword [ebp-12]
	push	dword [ebp-8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+108]
	add	esp,24
	mov	dword [ebp-36],eax
	push	_1886
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-36],bbNullObject
	je	_1887
	mov	eax,ebp
	push	eax
	push	_1889
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1888
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_461
_1887:
	call	dword [bbOnDebugLeaveScope]
_1882:
	call	dword [bbOnDebugLeaveScope]
_77:
	cmp	ebx,bbNullObject
	jne	_1874
	call	brl_blitz_NullObjectError
_1874:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_79
_78:
	call	dword [bbOnDebugLeaveScope]
_1865:
	push	_1893
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	jmp	_461
_461:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SortChildren:
	push	ebp
	mov	ebp,esp
	sub	esp,60
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
	mov	dword [ebp-20],bbNullObject
	mov	dword [ebp-28],bbNullObject
	mov	dword [ebp-32],0
	mov	dword [ebp-36],bbNullObject
	mov	dword [ebp-40],bbEmptyString
	mov	dword [ebp-44],bbEmptyString
	mov	dword [ebp-48],bbNullObject
	mov	dword [ebp-52],bbNullObject
	mov	dword [ebp-56],bbNullObject
	mov	dword [ebp-60],bbNullObject
	mov	dword [ebp-24],bbNullObject
	mov	eax,ebp
	push	eax
	push	_2120
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1898
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1900
	call	brl_blitz_NullObjectError
_1900:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1902
	call	brl_blitz_NullObjectError
_1902:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-20],eax
	push	_1904
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_82:
_80:
	mov	eax,ebp
	push	eax
	push	_2097
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1905
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_1907
	call	brl_blitz_NullObjectError
_1907:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_1909
	call	brl_blitz_NullObjectError
_1909:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_1911
	call	brl_blitz_NullObjectError
_1911:
	mov	eax,dword [ebx+12]
	mov	dword [ebp-28],eax
	push	_1913
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],1
	push	_1915
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_85:
_83:
	mov	eax,ebp
	push	eax
	push	_2088
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1916
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_1918
	call	brl_blitz_NullObjectError
_1918:
	mov	eax,dword [ebx+12]
	mov	dword [ebp-36],eax
	push	_1920
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-20]
	cmp	dword [ebp-36],eax
	jne	_1921
	mov	eax,ebp
	push	eax
	push	_1923
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1922
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_84
_1921:
	push	_1924
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-40],bbEmptyString
	mov	dword [ebp-44],bbEmptyString
	push	_1927
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-48],bbNullObject
	mov	dword [ebp-52],bbNullObject
	push	_1930
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	cmp	eax,1
	je	_1933
	cmp	eax,2
	je	_1934
	cmp	eax,3
	je	_1935
	cmp	eax,4
	je	_1936
	jmp	_1932
_1933:
	mov	eax,ebp
	push	eax
	push	_1947
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1937
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_1939
	call	brl_blitz_NullObjectError
_1939:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_1941
	call	brl_blitz_NullObjectError
_1941:
	push	dword [ebx+8]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-40],eax
	push	_1942
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_1944
	call	brl_blitz_NullObjectError
_1944:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_1946
	call	brl_blitz_NullObjectError
_1946:
	push	dword [ebx+8]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1932
_1934:
	mov	eax,ebp
	push	eax
	push	_1958
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1948
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_1950
	call	brl_blitz_NullObjectError
_1950:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_1952
	call	brl_blitz_NullObjectError
_1952:
	push	dword [ebx+12]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-40],eax
	push	_1953
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_1955
	call	brl_blitz_NullObjectError
_1955:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_1957
	call	brl_blitz_NullObjectError
_1957:
	push	dword [ebx+12]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1932
_1935:
	mov	eax,ebp
	push	eax
	push	_1999
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1959
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-40],_1
	push	_1960
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_1962
	call	brl_blitz_NullObjectError
_1962:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	push	_1963
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_1965
	call	brl_blitz_NullObjectError
_1965:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1968
	call	brl_blitz_NullObjectError
_1968:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_86
_88:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1973
	call	brl_blitz_NullObjectError
_1973:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-48],eax
	cmp	dword [ebp-48],bbNullObject
	je	_86
	mov	eax,ebp
	push	eax
	push	_1977
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1974
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-48]
	cmp	ebx,bbNullObject
	jne	_1976
	call	brl_blitz_NullObjectError
_1976:
	push	dword [ebx+8]
	push	dword [ebp-40]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-40],eax
	call	dword [bbOnDebugLeaveScope]
_86:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1971
	call	brl_blitz_NullObjectError
_1971:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_88
_87:
	push	_1978
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-40]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-40],eax
	push	_1979
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-44],_1
	push	_1980
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_1982
	call	brl_blitz_NullObjectError
_1982:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	push	_1983
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_1985
	call	brl_blitz_NullObjectError
_1985:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_1988
	call	brl_blitz_NullObjectError
_1988:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_89
_91:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1993
	call	brl_blitz_NullObjectError
_1993:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-48],eax
	cmp	dword [ebp-48],bbNullObject
	je	_89
	mov	eax,ebp
	push	eax
	push	_1997
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_1994
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-48]
	cmp	ebx,bbNullObject
	jne	_1996
	call	brl_blitz_NullObjectError
_1996:
	push	dword [ebx+8]
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
_89:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_1991
	call	brl_blitz_NullObjectError
_1991:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_91
_90:
	push	_1998
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-44]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1932
_1936:
	mov	eax,ebp
	push	eax
	push	_2040
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2000
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-40],_1
	push	_2001
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_2003
	call	brl_blitz_NullObjectError
_2003:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	push	_2004
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2006
	call	brl_blitz_NullObjectError
_2006:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2009
	call	brl_blitz_NullObjectError
_2009:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_92
_94:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2014
	call	brl_blitz_NullObjectError
_2014:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-48],eax
	cmp	dword [ebp-48],bbNullObject
	je	_92
	mov	eax,ebp
	push	eax
	push	_2018
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2015
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-48]
	cmp	ebx,bbNullObject
	jne	_2017
	call	brl_blitz_NullObjectError
_2017:
	push	dword [ebx+12]
	push	dword [ebp-40]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-40],eax
	call	dword [bbOnDebugLeaveScope]
_92:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2012
	call	brl_blitz_NullObjectError
_2012:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_94
_93:
	push	_2019
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-40]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-40],eax
	push	_2020
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-44],_1
	push	_2021
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_2023
	call	brl_blitz_NullObjectError
_2023:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	push	_2024
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2026
	call	brl_blitz_NullObjectError
_2026:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2029
	call	brl_blitz_NullObjectError
_2029:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_95
_97:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2034
	call	brl_blitz_NullObjectError
_2034:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-48],eax
	cmp	dword [ebp-48],bbNullObject
	je	_95
	mov	eax,ebp
	push	eax
	push	_2038
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2035
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-48]
	cmp	ebx,bbNullObject
	jne	_2037
	call	brl_blitz_NullObjectError
_2037:
	push	dword [ebx+12]
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
_95:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2032
	call	brl_blitz_NullObjectError
_2032:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_97
_96:
	push	_2039
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-44]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_1932
_1932:
	push	_2041
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-44]
	push	dword [ebp-40]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_2042
	mov	eax,dword [ebp-16]
_2042:
	cmp	eax,0
	jne	_2046
	push	dword [ebp-44]
	push	dword [ebp-40]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_2044
	mov	eax,dword [ebp-16]
	cmp	eax,0
	sete	al
	movzx	eax,al
_2044:
_2046:
	cmp	eax,0
	je	_2048
	mov	eax,ebp
	push	eax
	push	_2082
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2049
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_2051
	call	brl_blitz_NullObjectError
_2051:
	mov	eax,dword [ebx+16]
	mov	dword [ebp-56],eax
	push	_2053
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_2055
	call	brl_blitz_NullObjectError
_2055:
	mov	eax,dword [ebx+12]
	mov	dword [ebp-60],eax
	push	_2057
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	cmp	ebx,bbNullObject
	jne	_2059
	call	brl_blitz_NullObjectError
_2059:
	mov	eax,dword [ebp-36]
	mov	dword [ebx+12],eax
	push	_2061
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_2063
	call	brl_blitz_NullObjectError
_2063:
	mov	eax,dword [ebp-28]
	mov	dword [ebx+12],eax
	push	_2065
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_2067
	call	brl_blitz_NullObjectError
_2067:
	mov	eax,dword [ebp-56]
	mov	dword [ebx+16],eax
	push	_2069
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_2071
	call	brl_blitz_NullObjectError
_2071:
	mov	eax,dword [ebp-60]
	mov	dword [ebx+12],eax
	push	_2073
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-28]
	cmp	ebx,bbNullObject
	jne	_2075
	call	brl_blitz_NullObjectError
_2075:
	mov	eax,dword [ebp-36]
	mov	dword [ebx+16],eax
	push	_2077
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-60]
	cmp	ebx,bbNullObject
	jne	_2079
	call	brl_blitz_NullObjectError
_2079:
	mov	eax,dword [ebp-28]
	mov	dword [ebx+16],eax
	push	_2081
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],0
	call	dword [bbOnDebugLeaveScope]
	jmp	_2085
_2048:
	mov	eax,ebp
	push	eax
	push	_2087
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2086
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-36]
	mov	dword [ebp-28],eax
	call	dword [bbOnDebugLeaveScope]
_2085:
	call	dword [bbOnDebugLeaveScope]
	jmp	_85
_84:
	push	_2092
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-32],0
	je	_2093
	mov	eax,ebp
	push	eax
	push	_2095
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2094
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_467
_2093:
	push	_2096
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-28]
	mov	dword [ebp-20],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_82
_467:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SortChildrenEx:
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
	mov	eax,dword [ebp+24]
	mov	dword [ebp-20],eax
	mov	dword [ebp-24],bbNullObject
	mov	dword [ebp-32],bbNullObject
	mov	dword [ebp-36],0
	mov	dword [ebp-40],bbNullObject
	mov	dword [ebp-44],bbEmptyString
	mov	dword [ebp-48],bbEmptyString
	mov	dword [ebp-52],bbNullObject
	mov	dword [ebp-56],bbNullObject
	mov	dword [ebp-60],bbNullObject
	mov	dword [ebp-64],bbNullObject
	mov	dword [ebp-28],bbNullObject
	mov	eax,ebp
	push	eax
	push	_2445
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2124
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2126
	call	brl_blitz_NullObjectError
_2126:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2128
	call	brl_blitz_NullObjectError
_2128:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-24],eax
	push	_2130
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_103:
_101:
	mov	eax,ebp
	push	eax
	push	_2424
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2131
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2133
	call	brl_blitz_NullObjectError
_2133:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2135
	call	brl_blitz_NullObjectError
_2135:
	mov	ebx,dword [ebx+8]
	cmp	ebx,bbNullObject
	jne	_2137
	call	brl_blitz_NullObjectError
_2137:
	mov	eax,dword [ebx+12]
	mov	dword [ebp-32],eax
	push	_2139
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-36],1
	push	_2141
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_106:
_104:
	mov	eax,ebp
	push	eax
	push	_2417
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2142
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2144
	call	brl_blitz_NullObjectError
_2144:
	mov	eax,dword [ebx+12]
	mov	dword [ebp-40],eax
	push	_2146
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-24]
	cmp	dword [ebp-40],eax
	jne	_2147
	mov	eax,ebp
	push	eax
	push	_2149
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2148
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_105
_2147:
	push	_2150
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-44],bbEmptyString
	mov	dword [ebp-48],bbEmptyString
	push	_2153
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-52],bbNullObject
	mov	dword [ebp-56],bbNullObject
	push	_2156
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-44],_1
	push	_2157
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-48],_1
	push	_2158
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	cmp	eax,1
	je	_2161
	cmp	eax,2
	je	_2162
	cmp	eax,3
	je	_2163
	cmp	eax,4
	je	_2164
	jmp	_2160
_2161:
	mov	eax,ebp
	push	eax
	push	_2175
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2165
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2167
	call	brl_blitz_NullObjectError
_2167:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2169
	call	brl_blitz_NullObjectError
_2169:
	push	dword [ebx+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	push	_2170
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2172
	call	brl_blitz_NullObjectError
_2172:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2174
	call	brl_blitz_NullObjectError
_2174:
	push	dword [ebx+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-48]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_2160
_2162:
	mov	eax,ebp
	push	eax
	push	_2186
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2176
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2178
	call	brl_blitz_NullObjectError
_2178:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2180
	call	brl_blitz_NullObjectError
_2180:
	push	dword [ebx+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	push	_2181
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2183
	call	brl_blitz_NullObjectError
_2183:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2185
	call	brl_blitz_NullObjectError
_2185:
	push	dword [ebx+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-48]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_2160
_2163:
	mov	eax,ebp
	push	eax
	push	_2225
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2187
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2189
	call	brl_blitz_NullObjectError
_2189:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-56],eax
	push	_2190
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	cmp	ebx,bbNullObject
	jne	_2192
	call	brl_blitz_NullObjectError
_2192:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2195
	call	brl_blitz_NullObjectError
_2195:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_107
_109:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2200
	call	brl_blitz_NullObjectError
_2200:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	cmp	dword [ebp-52],bbNullObject
	je	_107
	mov	eax,ebp
	push	eax
	push	_2204
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2201
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2203
	call	brl_blitz_NullObjectError
_2203:
	push	dword [ebx+8]
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
_107:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2198
	call	brl_blitz_NullObjectError
_2198:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_109
_108:
	push	_2205
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-44]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-44],eax
	push	_2206
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2208
	call	brl_blitz_NullObjectError
_2208:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-56],eax
	push	_2209
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	cmp	ebx,bbNullObject
	jne	_2211
	call	brl_blitz_NullObjectError
_2211:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2214
	call	brl_blitz_NullObjectError
_2214:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_110
_112:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2219
	call	brl_blitz_NullObjectError
_2219:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	cmp	dword [ebp-52],bbNullObject
	je	_110
	mov	eax,ebp
	push	eax
	push	_2223
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2220
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2222
	call	brl_blitz_NullObjectError
_2222:
	push	dword [ebx+8]
	push	dword [ebp-48]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
_110:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2217
	call	brl_blitz_NullObjectError
_2217:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_112
_111:
	push	_2224
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_2160
_2164:
	mov	eax,ebp
	push	eax
	push	_2264
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2226
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2228
	call	brl_blitz_NullObjectError
_2228:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-56],eax
	push	_2229
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	cmp	ebx,bbNullObject
	jne	_2231
	call	brl_blitz_NullObjectError
_2231:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2234
	call	brl_blitz_NullObjectError
_2234:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_113
_115:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2239
	call	brl_blitz_NullObjectError
_2239:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	cmp	dword [ebp-52],bbNullObject
	je	_113
	mov	eax,ebp
	push	eax
	push	_2243
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2240
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2242
	call	brl_blitz_NullObjectError
_2242:
	push	dword [ebx+12]
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
_113:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2237
	call	brl_blitz_NullObjectError
_2237:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_115
_114:
	push	_2244
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-44]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-44],eax
	push	_2245
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2247
	call	brl_blitz_NullObjectError
_2247:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-56],eax
	push	_2248
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	cmp	ebx,bbNullObject
	jne	_2250
	call	brl_blitz_NullObjectError
_2250:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2253
	call	brl_blitz_NullObjectError
_2253:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_116
_118:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2258
	call	brl_blitz_NullObjectError
_2258:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	cmp	dword [ebp-52],bbNullObject
	je	_116
	mov	eax,ebp
	push	eax
	push	_2262
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2259
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2261
	call	brl_blitz_NullObjectError
_2261:
	push	dword [ebx+12]
	push	dword [ebp-48]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
_116:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2256
	call	brl_blitz_NullObjectError
_2256:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_118
_117:
	push	_2263
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_2160
_2160:
	push	_2265
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,1
	je	_2268
	cmp	eax,2
	je	_2269
	cmp	eax,3
	je	_2270
	cmp	eax,4
	je	_2271
	jmp	_2267
_2268:
	mov	eax,ebp
	push	eax
	push	_2282
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2272
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2274
	call	brl_blitz_NullObjectError
_2274:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2276
	call	brl_blitz_NullObjectError
_2276:
	push	dword [ebx+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	push	_2277
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2279
	call	brl_blitz_NullObjectError
_2279:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2281
	call	brl_blitz_NullObjectError
_2281:
	push	dword [ebx+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-48]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_2267
_2269:
	mov	eax,ebp
	push	eax
	push	_2293
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2283
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2285
	call	brl_blitz_NullObjectError
_2285:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2287
	call	brl_blitz_NullObjectError
_2287:
	push	dword [ebx+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	push	_2288
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2290
	call	brl_blitz_NullObjectError
_2290:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2292
	call	brl_blitz_NullObjectError
_2292:
	push	dword [ebx+12]
	call	bbStringToLower
	add	esp,4
	push	eax
	push	dword [ebp-48]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_2267
_2270:
	mov	eax,ebp
	push	eax
	push	_2332
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2294
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2296
	call	brl_blitz_NullObjectError
_2296:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-56],eax
	push	_2297
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	cmp	ebx,bbNullObject
	jne	_2299
	call	brl_blitz_NullObjectError
_2299:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2302
	call	brl_blitz_NullObjectError
_2302:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_119
_121:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2307
	call	brl_blitz_NullObjectError
_2307:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	cmp	dword [ebp-52],bbNullObject
	je	_119
	mov	eax,ebp
	push	eax
	push	_2311
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2308
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2310
	call	brl_blitz_NullObjectError
_2310:
	push	dword [ebx+8]
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
_119:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2305
	call	brl_blitz_NullObjectError
_2305:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_121
_120:
	push	_2312
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-44]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-44],eax
	push	_2313
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2315
	call	brl_blitz_NullObjectError
_2315:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-56],eax
	push	_2316
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	cmp	ebx,bbNullObject
	jne	_2318
	call	brl_blitz_NullObjectError
_2318:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2321
	call	brl_blitz_NullObjectError
_2321:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_122
_124:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2326
	call	brl_blitz_NullObjectError
_2326:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	cmp	dword [ebp-52],bbNullObject
	je	_122
	mov	eax,ebp
	push	eax
	push	_2330
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2327
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2329
	call	brl_blitz_NullObjectError
_2329:
	push	dword [ebx+8]
	push	dword [ebp-48]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
_122:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2324
	call	brl_blitz_NullObjectError
_2324:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_124
_123:
	push	_2331
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_2267
_2271:
	mov	eax,ebp
	push	eax
	push	_2371
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2333
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2335
	call	brl_blitz_NullObjectError
_2335:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-56],eax
	push	_2336
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	cmp	ebx,bbNullObject
	jne	_2338
	call	brl_blitz_NullObjectError
_2338:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2341
	call	brl_blitz_NullObjectError
_2341:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_125
_127:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2346
	call	brl_blitz_NullObjectError
_2346:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	cmp	dword [ebp-52],bbNullObject
	je	_125
	mov	eax,ebp
	push	eax
	push	_2350
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2347
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2349
	call	brl_blitz_NullObjectError
_2349:
	push	dword [ebx+12]
	push	dword [ebp-44]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-44],eax
	call	dword [bbOnDebugLeaveScope]
_125:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2344
	call	brl_blitz_NullObjectError
_2344:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_127
_126:
	push	_2351
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-44]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-44],eax
	push	_2352
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2354
	call	brl_blitz_NullObjectError
_2354:
	push	bb_xmlNode
	push	dword [ebx+8]
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-56],eax
	push	_2355
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-56]
	cmp	ebx,bbNullObject
	jne	_2357
	call	brl_blitz_NullObjectError
_2357:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2360
	call	brl_blitz_NullObjectError
_2360:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_128
_130:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2365
	call	brl_blitz_NullObjectError
_2365:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-52],eax
	cmp	dword [ebp-52],bbNullObject
	je	_128
	mov	eax,ebp
	push	eax
	push	_2369
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2366
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-52]
	cmp	ebx,bbNullObject
	jne	_2368
	call	brl_blitz_NullObjectError
_2368:
	push	dword [ebx+12]
	push	dword [ebp-48]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
_128:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2363
	call	brl_blitz_NullObjectError
_2363:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_130
_129:
	push	_2370
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-48],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_2267
_2267:
	push	_2372
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-48]
	push	dword [ebp-44]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_2373
	mov	eax,dword [ebp-20]
_2373:
	cmp	eax,0
	jne	_2377
	push	dword [ebp-48]
	push	dword [ebp-44]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setl	al
	movzx	eax,al
	cmp	eax,0
	je	_2375
	mov	eax,dword [ebp-20]
	cmp	eax,0
	sete	al
	movzx	eax,al
_2375:
_2377:
	cmp	eax,0
	je	_2379
	mov	eax,ebp
	push	eax
	push	_2413
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2380
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2382
	call	brl_blitz_NullObjectError
_2382:
	mov	eax,dword [ebx+16]
	mov	dword [ebp-60],eax
	push	_2384
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2386
	call	brl_blitz_NullObjectError
_2386:
	mov	eax,dword [ebx+12]
	mov	dword [ebp-64],eax
	push	_2388
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-60]
	cmp	ebx,bbNullObject
	jne	_2390
	call	brl_blitz_NullObjectError
_2390:
	mov	eax,dword [ebp-40]
	mov	dword [ebx+12],eax
	push	_2392
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2394
	call	brl_blitz_NullObjectError
_2394:
	mov	eax,dword [ebp-32]
	mov	dword [ebx+12],eax
	push	_2396
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-40]
	cmp	ebx,bbNullObject
	jne	_2398
	call	brl_blitz_NullObjectError
_2398:
	mov	eax,dword [ebp-60]
	mov	dword [ebx+16],eax
	push	_2400
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2402
	call	brl_blitz_NullObjectError
_2402:
	mov	eax,dword [ebp-64]
	mov	dword [ebx+12],eax
	push	_2404
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2406
	call	brl_blitz_NullObjectError
_2406:
	mov	eax,dword [ebp-40]
	mov	dword [ebx+16],eax
	push	_2408
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-64]
	cmp	ebx,bbNullObject
	jne	_2410
	call	brl_blitz_NullObjectError
_2410:
	mov	eax,dword [ebp-32]
	mov	dword [ebx+16],eax
	push	_2412
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-36],0
	call	dword [bbOnDebugLeaveScope]
	jmp	_2414
_2379:
	mov	eax,ebp
	push	eax
	push	_2416
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2415
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-40]
	mov	dword [ebp-32],eax
	call	dword [bbOnDebugLeaveScope]
_2414:
	call	dword [bbOnDebugLeaveScope]
	jmp	_106
_105:
	push	_2419
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-36],0
	je	_2420
	mov	eax,ebp
	push	eax
	push	_2422
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2421
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_474
_2420:
	push	_2423
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-32]
	mov	dword [ebp-24],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_103
_474:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_MoveChildrenTo:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	push	ebp
	push	_2481
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2448
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,1
	je	_2451
	cmp	eax,2
	je	_2452
	jmp	_2450
_2451:
	push	ebp
	push	_2466
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2453
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_134
_136:
	push	ebp
	push	_2465
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2458
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2460
	call	brl_blitz_NullObjectError
_2460:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2462
	call	brl_blitz_NullObjectError
_2462:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2464
	call	brl_blitz_NullObjectError
_2464:
	push	1
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_134:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2455
	call	brl_blitz_NullObjectError
_2455:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2457
	call	brl_blitz_NullObjectError
_2457:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_136
_135:
	call	dword [bbOnDebugLeaveScope]
	jmp	_2450
_2452:
	push	ebp
	push	_2480
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2467
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_137
_139:
	push	ebp
	push	_2479
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2472
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2474
	call	brl_blitz_NullObjectError
_2474:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2476
	call	brl_blitz_NullObjectError
_2476:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2478
	call	brl_blitz_NullObjectError
_2478:
	push	2
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_137:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2469
	call	brl_blitz_NullObjectError
_2469:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2471
	call	brl_blitz_NullObjectError
_2471:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_139
_138:
	call	dword [bbOnDebugLeaveScope]
	jmp	_2450
_2450:
	mov	ebx,0
	jmp	_479
_479:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_CopyChildrenTo:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	push	ebp
	push	_2515
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2482
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,1
	je	_2485
	cmp	eax,2
	je	_2486
	jmp	_2484
_2485:
	push	ebp
	push	_2500
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2487
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_140
_142:
	push	ebp
	push	_2499
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2492
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2494
	call	brl_blitz_NullObjectError
_2494:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2496
	call	brl_blitz_NullObjectError
_2496:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2498
	call	brl_blitz_NullObjectError
_2498:
	push	1
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_140:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2489
	call	brl_blitz_NullObjectError
_2489:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2491
	call	brl_blitz_NullObjectError
_2491:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_142
_141:
	call	dword [bbOnDebugLeaveScope]
	jmp	_2484
_2486:
	push	ebp
	push	_2514
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2501
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_143
_145:
	push	ebp
	push	_2513
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2506
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2508
	call	brl_blitz_NullObjectError
_2508:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2510
	call	brl_blitz_NullObjectError
_2510:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2512
	call	brl_blitz_NullObjectError
_2512:
	push	2
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	call	dword [bbOnDebugLeaveScope]
_143:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2503
	call	brl_blitz_NullObjectError
_2503:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2505
	call	brl_blitz_NullObjectError
_2505:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_145
_144:
	call	dword [bbOnDebugLeaveScope]
	jmp	_2484
_2484:
	mov	ebx,0
	jmp	_484
_484:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FreeChildren:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_2529
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2516
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_146
_148:
	push	ebp
	push	_2528
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2521
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2523
	call	brl_blitz_NullObjectError
_2523:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2525
	call	brl_blitz_NullObjectError
_2525:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_2527
	call	brl_blitz_NullObjectError
_2527:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+80]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_146:
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2518
	call	brl_blitz_NullObjectError
_2518:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2520
	call	brl_blitz_NullObjectError
_2520:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_148
_147:
	mov	ebx,0
	jmp	_487
_487:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_NextSibling:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_2552
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2530
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2532
	call	brl_blitz_NullObjectError
_2532:
	cmp	dword [ebx+16],bbNullObject
	jne	_2533
	push	ebp
	push	_2535
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2534
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_490
_2533:
	push	_2536
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbNullObject
	push	_2538
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2540
	call	brl_blitz_NullObjectError
_2540:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_2542
	call	brl_blitz_NullObjectError
_2542:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-8],eax
	push	_2543
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	jne	_2544
	push	ebp
	push	_2546
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2545
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_490
_2544:
	push	ebp
	push	_2551
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2548
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2550
	call	brl_blitz_NullObjectError
_2550:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_490
_490:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_PrevSibling:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_2576
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2554
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2556
	call	brl_blitz_NullObjectError
_2556:
	cmp	dword [ebx+16],bbNullObject
	jne	_2557
	push	ebp
	push	_2559
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2558
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_493
_2557:
	push	_2560
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbNullObject
	push	_2562
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2564
	call	brl_blitz_NullObjectError
_2564:
	mov	ebx,dword [ebx+32]
	cmp	ebx,bbNullObject
	jne	_2566
	call	brl_blitz_NullObjectError
_2566:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	mov	dword [ebp-8],eax
	push	_2567
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	jne	_2568
	push	ebp
	push	_2570
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2569
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_493
_2568:
	push	ebp
	push	_2575
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2572
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2574
	call	brl_blitz_NullObjectError
_2574:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_493
_493:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FirstSibling:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_2590
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2577
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2579
	call	brl_blitz_NullObjectError
_2579:
	cmp	dword [ebx+16],bbNullObject
	jne	_2580
	push	ebp
	push	_2582
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2581
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	call	dword [bbOnDebugLeaveScope]
	jmp	_496
_2580:
	push	_2583
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2585
	call	brl_blitz_NullObjectError
_2585:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_2587
	call	brl_blitz_NullObjectError
_2587:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2589
	call	brl_blitz_NullObjectError
_2589:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_496
_496:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_LastSibling:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_2604
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2591
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2593
	call	brl_blitz_NullObjectError
_2593:
	cmp	dword [ebx+16],bbNullObject
	jne	_2594
	push	ebp
	push	_2596
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2595
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	call	dword [bbOnDebugLeaveScope]
	jmp	_499
_2594:
	push	_2597
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2599
	call	brl_blitz_NullObjectError
_2599:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_2601
	call	brl_blitz_NullObjectError
_2601:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2603
	call	brl_blitz_NullObjectError
_2603:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_499
_499:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_GetSibling:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbNullObject
	push	ebp
	push	_2637
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2605
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2607
	call	brl_blitz_NullObjectError
_2607:
	cmp	dword [ebx+16],bbNullObject
	jne	_2608
	push	ebp
	push	_2614
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2609
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],1
	jne	_2610
	push	ebp
	push	_2612
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2611
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_503
_2610:
	push	_2613
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_150
	push	dword [ebp-8]
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
	call	dword [bbOnDebugLeaveScope]
_2608:
	push	_2615
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	push	_2617
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2619
	call	brl_blitz_NullObjectError
_2619:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_2621
	call	brl_blitz_NullObjectError
_2621:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2623
	call	brl_blitz_NullObjectError
_2623:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_2625
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],1
	mov	ebx,dword [ebp-8]
	sub	ebx,1
	jmp	_2626
_153:
	push	ebp
	push	_2633
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2628
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_2630
	call	brl_blitz_NullObjectError
_2630:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_2631
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-16],bbNullObject
	jne	_2632
	push	_51
	push	dword [ebp-8]
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
	call	brl_blitz_RuntimeError
	add	esp,4
_2632:
	call	dword [bbOnDebugLeaveScope]
_151:
	add	dword [ebp-12],1
_2626:
	cmp	dword [ebp-12],ebx
	jle	_153
_152:
	push	_2634
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_2636
	call	brl_blitz_NullObjectError
_2636:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	jmp	_503
_503:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_SiblingCount:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_2651
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2638
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2640
	call	brl_blitz_NullObjectError
_2640:
	cmp	dword [ebx+16],bbNullObject
	jne	_2641
	push	ebp
	push	_2643
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2642
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	jmp	_506
_2641:
	push	_2644
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2646
	call	brl_blitz_NullObjectError
_2646:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_2648
	call	brl_blitz_NullObjectError
_2648:
	mov	ebx,dword [ebx+28]
	cmp	ebx,bbNullObject
	jne	_2650
	call	brl_blitz_NullObjectError
_2650:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+112]
	add	esp,4
	mov	ebx,eax
	jmp	_506
_506:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FindSibling:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	eax,dword [ebp+16]
	mov	dword [ebp-12],eax
	push	ebp
	push	_2670
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2652
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2654
	call	brl_blitz_NullObjectError
_2654:
	cmp	dword [ebx+16],bbNullObject
	jne	_2655
	push	ebp
	push	_2664
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2656
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],1
	jne	_2657
	push	ebp
	push	_2659
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2658
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_155
	push	dword [ebp-8]
	push	_154
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_2657:
	push	_2660
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	jne	_2661
	push	ebp
	push	_2663
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2662
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_156
	push	dword [ebp-8]
	push	_154
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_2661:
	call	dword [bbOnDebugLeaveScope]
_2655:
	push	_2665
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2667
	call	brl_blitz_NullObjectError
_2667:
	mov	ebx,dword [ebx+16]
	cmp	ebx,bbNullObject
	jne	_2669
	call	brl_blitz_NullObjectError
_2669:
	push	dword [ebp-12]
	push	0
	push	dword [ebp-8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+104]
	add	esp,16
	mov	ebx,eax
	jmp	_511
_511:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_HasAttribute:
	push	ebp
	mov	ebp,esp
	sub	esp,16
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
	push	_2715
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2671
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_2673
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	je	_2674
	mov	eax,ebp
	push	eax
	push	_2693
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2675
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2677
	call	brl_blitz_NullObjectError
_2677:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2680
	call	brl_blitz_NullObjectError
_2680:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_157
_159:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2685
	call	brl_blitz_NullObjectError
_2685:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-16],eax
	cmp	dword [ebp-16],bbNullObject
	je	_157
	mov	eax,ebp
	push	eax
	push	_2692
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2686
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_2688
	call	brl_blitz_NullObjectError
_2688:
	push	dword [ebp-8]
	push	dword [ebx+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_2689
	mov	eax,ebp
	push	eax
	push	_2691
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2690
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_516
_2689:
	call	dword [bbOnDebugLeaveScope]
_157:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2683
	call	brl_blitz_NullObjectError
_2683:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_159
_158:
	call	dword [bbOnDebugLeaveScope]
	jmp	_2694
_2674:
	mov	eax,ebp
	push	eax
	push	_2714
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2695
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_2696
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2698
	call	brl_blitz_NullObjectError
_2698:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2701
	call	brl_blitz_NullObjectError
_2701:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_160
_162:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2706
	call	brl_blitz_NullObjectError
_2706:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-16],eax
	cmp	dword [ebp-16],bbNullObject
	je	_160
	mov	eax,ebp
	push	eax
	push	_2713
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2707
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_2709
	call	brl_blitz_NullObjectError
_2709:
	push	dword [ebp-8]
	push	dword [ebx+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_2710
	mov	eax,ebp
	push	eax
	push	_2712
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2711
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_516
_2710:
	call	dword [bbOnDebugLeaveScope]
_160:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2704
	call	brl_blitz_NullObjectError
_2704:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_162
_161:
	call	dword [bbOnDebugLeaveScope]
_2694:
	mov	ebx,0
	jmp	_516
_516:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_HasAttributes:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_2727
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2716
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2718
	call	brl_blitz_NullObjectError
_2718:
	mov	ebx,dword [ebx+24]
	cmp	ebx,bbNullObject
	jne	_2720
	call	brl_blitz_NullObjectError
_2720:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_2721
	push	ebp
	push	_2723
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2722
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_519
_2721:
	push	ebp
	push	_2726
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2725
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	jmp	_519
_519:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_FirstAttribute:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_2743
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2728
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2730
	call	brl_blitz_NullObjectError
_2730:
	mov	ebx,dword [ebx+24]
	cmp	ebx,bbNullObject
	jne	_2732
	call	brl_blitz_NullObjectError
_2732:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_2733
	push	ebp
	push	_2735
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2734
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_522
_2733:
	push	ebp
	push	_2742
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2737
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2739
	call	brl_blitz_NullObjectError
_2739:
	mov	ebx,dword [ebx+24]
	cmp	ebx,bbNullObject
	jne	_2741
	call	brl_blitz_NullObjectError
_2741:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_522
_522:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_LastAttribute:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_2759
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2744
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2746
	call	brl_blitz_NullObjectError
_2746:
	mov	ebx,dword [ebx+24]
	cmp	ebx,bbNullObject
	jne	_2748
	call	brl_blitz_NullObjectError
_2748:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	cmp	eax,0
	je	_2749
	push	ebp
	push	_2751
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2750
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_525
_2749:
	push	ebp
	push	_2758
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2753
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2755
	call	brl_blitz_NullObjectError
_2755:
	mov	ebx,dword [ebx+24]
	cmp	ebx,bbNullObject
	jne	_2757
	call	brl_blitz_NullObjectError
_2757:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+76]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_525
_525:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_Attribute:
	push	ebp
	mov	ebp,esp
	sub	esp,16
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
	push	_2826
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2760
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],bbNullObject
	push	_2762
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],0
	je	_2763
	mov	eax,ebp
	push	eax
	push	_2782
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2764
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2766
	call	brl_blitz_NullObjectError
_2766:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2769
	call	brl_blitz_NullObjectError
_2769:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_163
_165:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2774
	call	brl_blitz_NullObjectError
_2774:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-16],eax
	cmp	dword [ebp-16],bbNullObject
	je	_163
	mov	eax,ebp
	push	eax
	push	_2781
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2775
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_2777
	call	brl_blitz_NullObjectError
_2777:
	push	dword [ebp-8]
	push	dword [ebx+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_2778
	mov	eax,ebp
	push	eax
	push	_2780
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2779
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_530
_2778:
	call	dword [bbOnDebugLeaveScope]
_163:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2772
	call	brl_blitz_NullObjectError
_2772:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_165
_164:
	call	dword [bbOnDebugLeaveScope]
	jmp	_2783
_2763:
	mov	eax,ebp
	push	eax
	push	_2803
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2784
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	bbStringToLower
	add	esp,4
	mov	dword [ebp-8],eax
	push	_2785
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2787
	call	brl_blitz_NullObjectError
_2787:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2790
	call	brl_blitz_NullObjectError
_2790:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_166
_168:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2795
	call	brl_blitz_NullObjectError
_2795:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-16],eax
	cmp	dword [ebp-16],bbNullObject
	je	_166
	mov	eax,ebp
	push	eax
	push	_2802
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2796
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_2798
	call	brl_blitz_NullObjectError
_2798:
	push	dword [ebp-8]
	push	dword [ebx+8]
	call	bbStringToLower
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_2799
	mov	eax,ebp
	push	eax
	push	_2801
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2800
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_530
_2799:
	call	dword [bbOnDebugLeaveScope]
_166:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2793
	call	brl_blitz_NullObjectError
_2793:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_168
_167:
	call	dword [bbOnDebugLeaveScope]
_2783:
	push	_2804
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_xmlAttribute
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-16],eax
	push	_2805
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_2807
	call	brl_blitz_NullObjectError
_2807:
	mov	eax,dword [ebp-8]
	mov	dword [ebx+8],eax
	push	_2809
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_2811
	call	brl_blitz_NullObjectError
_2811:
	mov	dword [ebx+12],_1
	push	_2813
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_2815
	call	brl_blitz_NullObjectError
_2815:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+16],eax
	push	_2817
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_2819
	call	brl_blitz_NullObjectError
_2819:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_2822
	call	brl_blitz_NullObjectError
_2822:
	mov	esi,dword [esi+24]
	cmp	esi,bbNullObject
	jne	_2824
	call	brl_blitz_NullObjectError
_2824:
	push	dword [ebp-16]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+20],eax
	push	_2825
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	jmp	_530
_530:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode_CleanAttributes:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	mov	eax,ebp
	push	eax
	push	_2853
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2827
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbNullObject
	push	_2829
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2831
	call	brl_blitz_NullObjectError
_2831:
	mov	edi,dword [ebx+24]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2834
	call	brl_blitz_NullObjectError
_2834:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_169
_171:
	cmp	ebx,bbNullObject
	jne	_2839
	call	brl_blitz_NullObjectError
_2839:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-8],eax
	cmp	dword [ebp-8],bbNullObject
	je	_169
	mov	eax,ebp
	push	eax
	push	_2852
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2840
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_2842
	call	brl_blitz_NullObjectError
_2842:
	push	_1
	push	dword [esi+8]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_2845
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_2844
	call	brl_blitz_NullObjectError
_2844:
	push	_1
	push	dword [esi+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_2845:
	cmp	eax,0
	je	_2847
	mov	eax,ebp
	push	eax
	push	_2851
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2848
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_2850
	call	brl_blitz_NullObjectError
_2850:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+56]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_2847:
	call	dword [bbOnDebugLeaveScope]
_169:
	cmp	ebx,bbNullObject
	jne	_2837
	call	brl_blitz_NullObjectError
_2837:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_171
_170:
	mov	ebx,0
	jmp	_533
_533:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlNode__UpdateVars:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	mov	eax,ebp
	push	eax
	push	_2884
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2854
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2856
	call	brl_blitz_NullObjectError
_2856:
	cmp	dword [ebx+16],bbNullObject
	je	_2857
	mov	eax,ebp
	push	eax
	push	_2866
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2858
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2860
	call	brl_blitz_NullObjectError
_2860:
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_2863
	call	brl_blitz_NullObjectError
_2863:
	mov	esi,dword [esi+16]
	cmp	esi,bbNullObject
	jne	_2865
	call	brl_blitz_NullObjectError
_2865:
	mov	eax,dword [esi+20]
	add	eax,1
	mov	dword [ebx+20],eax
	call	dword [bbOnDebugLeaveScope]
_2857:
	push	_2867
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbNullObject
	push	_2869
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2871
	call	brl_blitz_NullObjectError
_2871:
	mov	edi,dword [ebx+28]
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2874
	call	brl_blitz_NullObjectError
_2874:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	esi,eax
	jmp	_172
_174:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2879
	call	brl_blitz_NullObjectError
_2879:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-8],eax
	cmp	dword [ebp-8],bbNullObject
	je	_172
	mov	eax,ebp
	push	eax
	push	_2883
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2880
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2882
	call	brl_blitz_NullObjectError
_2882:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+184]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_172:
	mov	ebx,esi
	cmp	ebx,bbNullObject
	jne	_2877
	call	brl_blitz_NullObjectError
_2877:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_174
_173:
	mov	ebx,0
	jmp	_536
_536:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlAttribute_New:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_2886
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	dword [ebp-4]
	call	bbObjectCtor
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [eax],bb_xmlAttribute
	mov	eax,dword [ebp-4]
	mov	dword [eax+8],bbEmptyString
	mov	eax,dword [ebp-4]
	mov	dword [eax+12],bbEmptyString
	mov	eax,dword [ebp-4]
	mov	dword [eax+16],bbNullObject
	mov	eax,dword [ebp-4]
	mov	dword [eax+20],bbNullObject
	push	ebp
	push	_2885
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	mov	ebx,0
	jmp	_539
_539:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlAttribute_NextAttr:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_2903
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2887
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbNullObject
	push	_2889
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2891
	call	brl_blitz_NullObjectError
_2891:
	mov	ebx,dword [ebx+20]
	cmp	ebx,bbNullObject
	jne	_2893
	call	brl_blitz_NullObjectError
_2893:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-8],eax
	push	_2894
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	jne	_2895
	push	ebp
	push	_2897
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2896
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_542
_2895:
	push	ebp
	push	_2902
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2899
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2901
	call	brl_blitz_NullObjectError
_2901:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_542
_542:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlAttribute_PrevAttr:
	push	ebp
	mov	ebp,esp
	sub	esp,8
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	push	ebp
	push	_2920
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2904
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbNullObject
	push	_2906
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2908
	call	brl_blitz_NullObjectError
_2908:
	mov	ebx,dword [ebx+20]
	cmp	ebx,bbNullObject
	jne	_2910
	call	brl_blitz_NullObjectError
_2910:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,4
	mov	dword [ebp-8],eax
	push	_2911
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	jne	_2912
	push	ebp
	push	_2914
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2913
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,bbNullObject
	call	dword [bbOnDebugLeaveScope]
	jmp	_545
_2912:
	push	ebp
	push	_2919
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2916
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2918
	call	brl_blitz_NullObjectError
_2918:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_545
_545:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_xmlAttribute_Free:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_2926
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2921
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2923
	call	brl_blitz_NullObjectError
_2923:
	mov	ebx,dword [ebx+20]
	cmp	ebx,bbNullObject
	jne	_2925
	call	brl_blitz_NullObjectError
_2925:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,4
	mov	ebx,0
	jmp	_548
_548:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_175:
	push	ebp
	mov	ebp,esp
	sub	esp,32
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],bbEmptyString
	mov	dword [ebp-16],bbEmptyString
	mov	dword [ebp-20],bbEmptyString
	mov	dword [ebp-24],bbNullObject
	mov	dword [ebp-28],bbNullObject
	mov	eax,ebp
	push	eax
	push	_3015
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2927
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbEmptyString
	mov	dword [ebp-16],bbEmptyString
	mov	dword [ebp-20],bbEmptyString
	push	_2931
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],bbNullObject
	mov	dword [ebp-28],bbNullObject
	push	_2934
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2936
	call	brl_blitz_NullObjectError
_2936:
	mov	eax,dword [ebx+8]
	mov	dword [ebp-12],eax
	push	_2937
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2939
	call	brl_blitz_NullObjectError
_2939:
	mov	eax,dword [ebx+24]
	mov	dword [ebp-32],eax
	mov	ebx,dword [ebp-32]
	cmp	ebx,bbNullObject
	jne	_2942
	call	brl_blitz_NullObjectError
_2942:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_176
_178:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2947
	call	brl_blitz_NullObjectError
_2947:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-24],eax
	cmp	dword [ebp-24],bbNullObject
	je	_176
	mov	eax,ebp
	push	eax
	push	_2953
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2948
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-24]
	cmp	esi,bbNullObject
	jne	_2950
	call	brl_blitz_NullObjectError
_2950:
	mov	ebx,dword [ebp-24]
	cmp	ebx,bbNullObject
	jne	_2952
	call	brl_blitz_NullObjectError
_2952:
	push	_181
	push	dword [ebx+12]
	call	_255
	add	esp,4
	push	eax
	push	_180
	push	dword [esi+8]
	push	_179
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
	mov	dword [ebp-12],eax
	call	dword [bbOnDebugLeaveScope]
_176:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_2945
	call	brl_blitz_NullObjectError
_2945:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_178
_177:
	push	_2954
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2956
	call	brl_blitz_NullObjectError
_2956:
	mov	eax,dword [ebx+20]
	shl	eax,1
	push	eax
	push	0
	push	dword [ebp-16]
	call	bbStringSlice
	add	esp,12
	mov	dword [ebp-16],eax
	push	_2957
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2959
	call	brl_blitz_NullObjectError
_2959:
	mov	eax,dword [ebx+20]
	add	eax,1
	shl	eax,1
	push	eax
	push	0
	push	dword [ebp-20]
	call	bbStringSlice
	add	esp,12
	mov	dword [ebp-20],eax
	push	_2960
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2962
	call	brl_blitz_NullObjectError
_2962:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,4
	cmp	eax,0
	jne	_2963
	mov	eax,ebp
	push	eax
	push	_2981
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2964
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2966
	call	brl_blitz_NullObjectError
_2966:
	push	_1
	push	dword [ebx+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_2967
	mov	eax,ebp
	push	eax
	push	_2971
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2968
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2970
	call	brl_blitz_NullObjectError
_2970:
	push	_183
	push	dword [ebp-12]
	push	_182
	push	dword [ebp-16]
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
	call	dword [bbOnDebugLeaveScope]
	jmp	_2972
_2967:
	mov	eax,ebp
	push	eax
	push	_2980
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2973
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	edi,dword [ebp-4]
	cmp	edi,bbNullObject
	jne	_2975
	call	brl_blitz_NullObjectError
_2975:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_2977
	call	brl_blitz_NullObjectError
_2977:
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2979
	call	brl_blitz_NullObjectError
_2979:
	push	_2
	push	dword [ebx+8]
	push	_184
	push	dword [esi+12]
	call	_255
	add	esp,4
	push	eax
	push	_2
	push	dword [ebp-12]
	push	_182
	push	dword [ebp-16]
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
	push	edi
	mov	eax,dword [edi]
	call	dword [eax+144]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_2972:
	call	dword [bbOnDebugLeaveScope]
	jmp	_2982
_2963:
	mov	eax,ebp
	push	eax
	push	_3014
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2983
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2985
	call	brl_blitz_NullObjectError
_2985:
	push	_2
	push	dword [ebp-12]
	push	_182
	push	dword [ebp-16]
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
	push	_2986
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2988
	call	brl_blitz_NullObjectError
_2988:
	push	_1
	push	dword [ebx+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_2989
	mov	eax,ebp
	push	eax
	push	_2995
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_2990
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_2992
	call	brl_blitz_NullObjectError
_2992:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_2994
	call	brl_blitz_NullObjectError
_2994:
	push	dword [esi+12]
	call	_255
	add	esp,4
	push	eax
	push	dword [ebp-20]
	call	bbStringConcat
	add	esp,8
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+144]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_2989:
	push	_2996
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_2998
	call	brl_blitz_NullObjectError
_2998:
	mov	esi,dword [ebx+28]
	cmp	esi,bbNullObject
	jne	_3001
	call	brl_blitz_NullObjectError
_3001:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_185
_187:
	cmp	ebx,bbNullObject
	jne	_3006
	call	brl_blitz_NullObjectError
_3006:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-28],eax
	cmp	dword [ebp-28],bbNullObject
	je	_185
	mov	eax,ebp
	push	eax
	push	_3008
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3007
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-28]
	push	dword [ebp-4]
	call	_175
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_185:
	cmp	ebx,bbNullObject
	jne	_3004
	call	brl_blitz_NullObjectError
_3004:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_187
_186:
	push	_3009
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_3011
	call	brl_blitz_NullObjectError
_3011:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_3013
	call	brl_blitz_NullObjectError
_3013:
	push	_2
	push	dword [esi+8]
	push	_184
	push	dword [ebp-16]
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
	call	dword [bbOnDebugLeaveScope]
_2982:
	mov	ebx,0
	jmp	_552
_552:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_188:
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
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],bbNullObject
	mov	eax,ebp
	push	eax
	push	_3104
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3022
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],bbNullObject
	push	_3025
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_3027
	call	brl_blitz_NullObjectError
_3027:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_3029
	call	brl_blitz_NullObjectError
_3029:
	mov	eax,dword [esi+8]
	push	dword [eax+8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+112]
	add	esp,8
	push	_3030
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_3032
	call	brl_blitz_NullObjectError
_3032:
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3034
	call	brl_blitz_NullObjectError
_3034:
	push	dword [ebx+8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+152]
	add	esp,8
	push	_3035
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_3037
	call	brl_blitz_NullObjectError
_3037:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_3039
	call	brl_blitz_NullObjectError
_3039:
	mov	eax,dword [esi+12]
	push	dword [eax+8]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+112]
	add	esp,8
	push	_3040
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_3042
	call	brl_blitz_NullObjectError
_3042:
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3044
	call	brl_blitz_NullObjectError
_3044:
	push	dword [ebx+12]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+152]
	add	esp,8
	push	_3045
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_3047
	call	brl_blitz_NullObjectError
_3047:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_3049
	call	brl_blitz_NullObjectError
_3049:
	mov	esi,dword [esi+24]
	cmp	esi,bbNullObject
	jne	_3051
	call	brl_blitz_NullObjectError
_3051:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+112]
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+112]
	add	esp,8
	push	_3052
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3054
	call	brl_blitz_NullObjectError
_3054:
	mov	eax,dword [ebx+24]
	mov	dword [ebp-20],eax
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_3057
	call	brl_blitz_NullObjectError
_3057:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+140]
	add	esp,4
	mov	edi,eax
	jmp	_189
_191:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_3062
	call	brl_blitz_NullObjectError
_3062:
	push	bb_xmlAttribute
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-12],eax
	cmp	dword [ebp-12],bbNullObject
	je	_189
	mov	eax,ebp
	push	eax
	push	_3083
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3063
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_3065
	call	brl_blitz_NullObjectError
_3065:
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_3067
	call	brl_blitz_NullObjectError
_3067:
	mov	eax,dword [ebx+8]
	push	dword [eax+8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+112]
	add	esp,8
	push	_3068
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_3070
	call	brl_blitz_NullObjectError
_3070:
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_3072
	call	brl_blitz_NullObjectError
_3072:
	push	dword [ebx+8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+152]
	add	esp,8
	push	_3073
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_3075
	call	brl_blitz_NullObjectError
_3075:
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_3077
	call	brl_blitz_NullObjectError
_3077:
	mov	eax,dword [ebx+12]
	push	dword [eax+8]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+112]
	add	esp,8
	push	_3078
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	cmp	esi,bbNullObject
	jne	_3080
	call	brl_blitz_NullObjectError
_3080:
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_3082
	call	brl_blitz_NullObjectError
_3082:
	push	dword [ebx+12]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+152]
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_189:
	mov	ebx,edi
	cmp	ebx,bbNullObject
	jne	_3060
	call	brl_blitz_NullObjectError
_3060:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_191
_190:
	push	_3084
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_3086
	call	brl_blitz_NullObjectError
_3086:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_3088
	call	brl_blitz_NullObjectError
_3088:
	mov	esi,dword [esi+28]
	cmp	esi,bbNullObject
	jne	_3090
	call	brl_blitz_NullObjectError
_3090:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+112]
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+112]
	add	esp,8
	push	_3091
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3093
	call	brl_blitz_NullObjectError
_3093:
	mov	esi,dword [ebx+28]
	cmp	esi,bbNullObject
	jne	_3096
	call	brl_blitz_NullObjectError
_3096:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+140]
	add	esp,4
	mov	ebx,eax
	jmp	_192
_194:
	cmp	ebx,bbNullObject
	jne	_3101
	call	brl_blitz_NullObjectError
_3101:
	push	bb_xmlNode
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-16],eax
	cmp	dword [ebp-16],bbNullObject
	je	_192
	mov	eax,ebp
	push	eax
	push	_3103
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3102
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-16]
	push	dword [ebp-4]
	call	_188
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_192:
	cmp	ebx,bbNullObject
	jne	_3099
	call	brl_blitz_NullObjectError
_3099:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,4
	cmp	eax,0
	jne	_194
_193:
	mov	ebx,0
	jmp	_556
_556:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_195:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	push	ebp
	push	_3132
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3106
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	0
	push	1
	push	dword [ebp-4]
	call	brl_stream_OpenStream
	add	esp,12
	mov	dword [_585],eax
	push	_3107
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [_585],bbNullObject
	jne	_3108
	push	ebp
	push	_3112
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3109
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbStringClass
	push	dword [ebp-4]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_3111
	mov	eax,bbEmptyString
_3111:
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
	call	dword [bbOnDebugLeaveScope]
_3108:
	push	_3113
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3115
	call	brl_blitz_NullObjectError
_3115:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,216
	jne	_3116
	push	ebp
	push	_3128
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3117
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3119
	call	brl_blitz_NullObjectError
_3119:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,241
	jne	_3120
	push	ebp
	push	_3127
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3121
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3123
	call	brl_blitz_NullObjectError
_3123:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+92]
	add	esp,4
	cmp	eax,188
	jne	_3124
	push	ebp
	push	_3126
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3125
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_559
_3124:
	call	dword [bbOnDebugLeaveScope]
_3120:
	call	dword [bbOnDebugLeaveScope]
_3116:
	push	_3129
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbStringClass
	push	dword [ebp-4]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_3131
	mov	eax,bbEmptyString
_3131:
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
	mov	ebx,0
	jmp	_559
_559:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_197:
	push	ebp
	mov	ebp,esp
	sub	esp,40
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	mov	dword [ebp-24],bbEmptyString
	mov	dword [ebp-28],bbEmptyString
	mov	dword [ebp-32],0
	mov	dword [ebp-36],bbNullObject
	mov	dword [ebp-40],0
	mov	eax,ebp
	push	eax
	push	_3227
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3134
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	push	_3138
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],bbEmptyString
	mov	dword [ebp-28],bbEmptyString
	push	_3141
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3143
	call	brl_blitz_NullObjectError
_3143:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+108]
	add	esp,4
	mov	dword [ebp-20],eax
	push	_3144
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3146
	call	brl_blitz_NullObjectError
_3146:
	push	dword [ebp-20]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+148]
	add	esp,8
	mov	dword [ebp-24],eax
	push	_3147
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3149
	call	brl_blitz_NullObjectError
_3149:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+108]
	add	esp,4
	mov	dword [ebp-20],eax
	push	_3150
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3152
	call	brl_blitz_NullObjectError
_3152:
	push	dword [ebp-20]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+148]
	add	esp,8
	mov	dword [ebp-28],eax
	push	_3153
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	je	_3154
	mov	eax,ebp
	push	eax
	push	_3162
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3155
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3157
	call	brl_blitz_NullObjectError
_3157:
	push	1
	push	dword [ebp-24]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,12
	mov	dword [ebp-12],eax
	push	_3158
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_3160
	call	brl_blitz_NullObjectError
_3160:
	mov	eax,dword [ebp-28]
	mov	dword [ebx+12],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3163
_3154:
	mov	eax,ebp
	push	eax
	push	_3175
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3164
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_3166
	call	brl_blitz_NullObjectError
_3166:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-12],eax
	push	_3167
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_3169
	call	brl_blitz_NullObjectError
_3169:
	mov	eax,dword [ebp-24]
	mov	dword [ebx+8],eax
	push	_3171
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	cmp	ebx,bbNullObject
	jne	_3173
	call	brl_blitz_NullObjectError
_3173:
	mov	eax,dword [ebp-28]
	mov	dword [ebx+12],eax
	call	dword [bbOnDebugLeaveScope]
_3163:
	push	_3176
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-32],0
	mov	dword [ebp-36],bbNullObject
	push	_3179
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3181
	call	brl_blitz_NullObjectError
_3181:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+108]
	add	esp,4
	mov	dword [ebp-32],eax
	push	_3182
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],1
	mov	edi,dword [ebp-32]
	jmp	_3183
_200:
	mov	eax,ebp
	push	eax
	push	_3216
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3185
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_xmlAttribute
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-36],eax
	push	_3186
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_3188
	call	brl_blitz_NullObjectError
_3188:
	mov	eax,dword [ebp-12]
	mov	dword [ebx+16],eax
	push	_3190
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_3192
	call	brl_blitz_NullObjectError
_3192:
	mov	esi,dword [ebp-12]
	cmp	esi,bbNullObject
	jne	_3195
	call	brl_blitz_NullObjectError
_3195:
	mov	esi,dword [esi+24]
	cmp	esi,bbNullObject
	jne	_3197
	call	brl_blitz_NullObjectError
_3197:
	push	dword [ebp-36]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+20],eax
	push	_3198
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3200
	call	brl_blitz_NullObjectError
_3200:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+108]
	add	esp,4
	mov	dword [ebp-20],eax
	push	_3201
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_3203
	call	brl_blitz_NullObjectError
_3203:
	mov	esi,ebx
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3206
	call	brl_blitz_NullObjectError
_3206:
	push	dword [ebp-20]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+148]
	add	esp,8
	mov	dword [esi+8],eax
	push	_3207
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3209
	call	brl_blitz_NullObjectError
_3209:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+108]
	add	esp,4
	mov	dword [ebp-20],eax
	push	_3210
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-36]
	cmp	ebx,bbNullObject
	jne	_3212
	call	brl_blitz_NullObjectError
_3212:
	mov	esi,ebx
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3215
	call	brl_blitz_NullObjectError
_3215:
	push	dword [ebp-20]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+148]
	add	esp,8
	mov	dword [esi+12],eax
	call	dword [bbOnDebugLeaveScope]
_198:
	add	dword [ebp-16],1
_3183:
	cmp	dword [ebp-16],edi
	jle	_200
_199:
	push	_3217
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-40],0
	push	_3219
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_585]
	cmp	ebx,bbNullObject
	jne	_3221
	call	brl_blitz_NullObjectError
_3221:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+108]
	add	esp,4
	mov	dword [ebp-40],eax
	push	_3222
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],1
	mov	ebx,dword [ebp-40]
	jmp	_3223
_203:
	mov	eax,ebp
	push	eax
	push	_3226
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3225
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	push	dword [ebp-4]
	call	_197
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
_201:
	add	dword [ebp-16],1
_3223:
	cmp	dword [ebp-16],ebx
	jle	_203
_202:
	mov	ebx,0
	jmp	_563
_563:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_204:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-8],eax
	movzx	eax,byte [ebp+12]
	mov	eax,eax
	mov	byte [ebp-4],al
	mov	dword [ebp-12],bbNullObject
	push	ebp
	push	_3255
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3232
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [_587],_1
	push	_3233
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	movzx	eax,byte [ebp-4]
	cmp	eax,0
	je	_3234
	push	ebp
	push	_3241
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3235
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],bbNullObject
	push	_3237
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbStringClass
	push	dword [ebp-8]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_3239
	mov	eax,bbEmptyString
_3239:
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
	mov	dword [ebp-12],eax
	push	_3240
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-12]
	call	dword [brl_bank_TBank+136]
	add	esp,4
	mov	dword [_589],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3242
_3234:
	push	ebp
	push	_3244
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3243
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	dword [brl_bank_TBank+136]
	add	esp,4
	mov	dword [_589],eax
	call	dword [bbOnDebugLeaveScope]
_3242:
	push	_3245
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [_589],bbNullObject
	jne	_3246
	push	ebp
	push	_3250
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3247
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bbStringClass
	push	dword [ebp-8]
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_3249
	mov	eax,bbEmptyString
_3249:
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
	call	dword [bbOnDebugLeaveScope]
_3246:
	push	_3251
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [_591],-1
	push	_3252
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3254
	call	brl_blitz_NullObjectError
_3254:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,4
	mov	dword [_593],eax
	mov	ebx,0
	jmp	_567
_567:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_205:
	push	ebp
	mov	ebp,esp
	sub	esp,24
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+12]
	mov	dword [ebp-8],eax
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],bbNullObject
	mov	dword [ebp-24],bbEmptyString
	push	ebp
	push	_3407
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3257
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbNullObject
	mov	dword [ebp-20],bbNullObject
	push	_3261
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],_1
	push	_3263
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_208:
_206:
	push	ebp
	push	_3406
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3264
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	_223
	mov	dword [ebp-12],eax
	push	_3265
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	eax,1
	je	_3268
	cmp	eax,3
	je	_3269
	cmp	eax,6
	je	_3270
	cmp	eax,8
	je	_3271
	cmp	eax,5
	je	_3272
	cmp	eax,2
	je	_3273
	cmp	eax,4
	je	_3273
	cmp	eax,-1
	je	_3274
	jmp	_3267
_3268:
	push	ebp
	push	_3335
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3275
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	je	_3276
	push	ebp
	push	_3280
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3277
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3279
	call	brl_blitz_NullObjectError
_3279:
	push	1
	push	dword [_587]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+48]
	add	esp,12
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3281
_3276:
	push	ebp
	push	_3289
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3282
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_3284
	call	brl_blitz_NullObjectError
_3284:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebp-16],eax
	push	_3285
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	cmp	ebx,bbNullObject
	jne	_3287
	call	brl_blitz_NullObjectError
_3287:
	mov	eax,dword [_587]
	mov	dword [ebx+8],eax
	call	dword [bbOnDebugLeaveScope]
_3281:
	push	_3290
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	_223
	mov	dword [ebp-12],eax
	push	_3291
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_209
_211:
	push	ebp
	push	_3324
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3292
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	bb_xmlAttribute
	call	bbObjectNew
	add	esp,4
	mov	dword [ebp-20],eax
	push	_3293
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_3295
	call	brl_blitz_NullObjectError
_3295:
	mov	eax,dword [ebp-16]
	mov	dword [ebx+16],eax
	push	_3297
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_3299
	call	brl_blitz_NullObjectError
_3299:
	mov	esi,dword [ebp-16]
	cmp	esi,bbNullObject
	jne	_3302
	call	brl_blitz_NullObjectError
_3302:
	mov	esi,dword [esi+24]
	cmp	esi,bbNullObject
	jne	_3304
	call	brl_blitz_NullObjectError
_3304:
	push	dword [ebp-20]
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+68]
	add	esp,8
	mov	dword [ebx+20],eax
	push	_3305
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_3307
	call	brl_blitz_NullObjectError
_3307:
	push	dword [_587]
	call	brl_retro_Trim
	add	esp,4
	mov	dword [ebx+8],eax
	push	_3309
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	_223
	mov	dword [ebp-12],eax
	push	_3310
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],5
	je	_3311
	push	ebp
	push	_3313
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3312
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_212
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_3311:
	push	_3314
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	_223
	mov	dword [ebp-12],eax
	push	_3315
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],7
	je	_3316
	push	ebp
	push	_3318
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3317
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_213
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_3316:
	push	_3319
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-20]
	cmp	ebx,bbNullObject
	jne	_3321
	call	brl_blitz_NullObjectError
_3321:
	mov	eax,dword [_587]
	mov	dword [ebx+12],eax
	push	_3323
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	_223
	mov	dword [ebp-12],eax
	call	dword [bbOnDebugLeaveScope]
_209:
	cmp	dword [ebp-12],6
	je	_211
_210:
	push	_3325
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],2
	jne	_3326
	push	ebp
	push	_3328
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3327
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-16]
	push	dword [ebp-4]
	call	_205
	add	esp,8
	call	dword [bbOnDebugLeaveScope]
	jmp	_3329
_3326:
	push	ebp
	push	_3334
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3330
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],4
	je	_3331
	push	ebp
	push	_3333
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3332
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_214
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_3331:
	call	dword [bbOnDebugLeaveScope]
_3329:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3267
_3269:
	push	ebp
	push	_3354
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3336
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	jne	_3337
	push	ebp
	push	_3339
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3338
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_215
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	jmp	_3340
_3337:
	push	ebp
	push	_3347
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3341
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3343
	call	brl_blitz_NullObjectError
_3343:
	push	dword [ebx+8]
	push	dword [_587]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_3344
	push	ebp
	push	_3346
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3345
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_216
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_3344:
	call	dword [bbOnDebugLeaveScope]
_3340:
	push	_3348
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	_223
	mov	dword [ebp-12],eax
	push	_3349
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-12],2
	je	_3350
	push	ebp
	push	_3352
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3351
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_217
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_3350:
	push	_3353
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_571
_3270:
	push	ebp
	push	_3379
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3355
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	jne	_3356
	push	ebp
	push	_3358
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3357
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [_587]
	push	_218
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	jmp	_3359
_3356:
	push	ebp
	push	_3378
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3360
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3362
	call	brl_blitz_NullObjectError
_3362:
	push	_1
	push	dword [ebx+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_3363
	push	ebp
	push	_3368
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3364
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3366
	call	brl_blitz_NullObjectError
_3366:
	mov	eax,dword [_587]
	mov	dword [ebx+12],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3369
_3363:
	push	ebp
	push	_3376
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3370
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3372
	call	brl_blitz_NullObjectError
_3372:
	mov	esi,dword [ebp-8]
	cmp	esi,bbNullObject
	jne	_3375
	call	brl_blitz_NullObjectError
_3375:
	push	dword [_587]
	push	dword [ebp-24]
	push	dword [esi+12]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	mov	dword [ebx+12],eax
	call	dword [bbOnDebugLeaveScope]
_3369:
	push	_3377
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],_179
	call	dword [bbOnDebugLeaveScope]
_3359:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3267
_3271:
	push	ebp
	push	_3387
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3380
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_179
	push	dword [ebp-24]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_3381
	push	ebp
	push	_3383
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3382
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],_219
	call	dword [bbOnDebugLeaveScope]
	jmp	_3384
_3381:
	push	ebp
	push	_3386
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3385
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_219
	push	dword [ebp-24]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-24],eax
	call	dword [bbOnDebugLeaveScope]
_3384:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3267
_3272:
	push	ebp
	push	_3395
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3388
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_179
	push	dword [ebp-24]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_3389
	push	ebp
	push	_3391
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3390
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-24],_220
	call	dword [bbOnDebugLeaveScope]
	jmp	_3392
_3389:
	push	ebp
	push	_3394
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3393
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_220
	push	dword [ebp-24]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-24],eax
	call	dword [bbOnDebugLeaveScope]
_3392:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3267
_3273:
	push	ebp
	push	_3397
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3396
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_221
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	jmp	_3267
_3274:
	push	ebp
	push	_3405
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3398
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-8],bbNullObject
	jne	_3399
	push	ebp
	push	_3401
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3400
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_571
_3399:
	push	ebp
	push	_3404
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3403
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_222
	call	bbExThrow
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
_3402:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3267
_3267:
	call	dword [bbOnDebugLeaveScope]
	jmp	_208
_571:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_223:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	mov	dword [ebp-4],0
	push	ebp
	push	_3417
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3411
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],0
	push	_3413
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_226:
	push	ebp
	push	_3415
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3414
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	_227
	mov	dword [ebp-4],eax
	call	dword [bbOnDebugLeaveScope]
_224:
	cmp	dword [ebp-4],0
	je	_226
_225:
	push	_3416
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	jmp	_573
_573:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_227:
	push	ebp
	mov	ebp,esp
	sub	esp,20
	push	ebx
	mov	dword [ebp-4],0
	mov	dword [ebp-8],bbEmptyString
	mov	dword [ebp-12],0
	mov	dword [ebp-16],0
	mov	dword [ebp-20],0
	push	ebp
	push	_3861
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3419
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],0
	push	_3421
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbEmptyString
	push	_3423
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_593]
	mov	dword [ebp-12],eax
	push	_3425
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3426
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	dword [_591],eax
	jl	_3427
	push	ebp
	push	_3429
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3428
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,-1
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3427:
	push	_3430
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3432
	call	brl_blitz_NullObjectError
_3432:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	push	_3433
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	eax,60
	je	_3436
	cmp	eax,47
	je	_3437
	cmp	eax,62
	je	_3438
	cmp	eax,61
	je	_3439
	cmp	eax,34
	je	_3440
	cmp	eax,32
	je	_3441
	cmp	eax,13
	je	_3441
	cmp	eax,10
	je	_3441
	cmp	eax,9
	je	_3441
	push	ebp
	push	_3586
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3442
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],_1
	push	_3443
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_251:
	push	ebp
	push	_3574
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3444
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-4],38
	jne	_3445
	push	ebp
	push	_3564
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3446
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3448
	call	brl_blitz_NullObjectError
_3448:
	mov	eax,dword [_591]
	add	eax,1
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,108
	je	_3451
	cmp	eax,103
	je	_3452
	cmp	eax,97
	je	_3453
	cmp	eax,113
	je	_3454
	cmp	eax,35
	je	_3455
	jmp	_3450
_3451:
	push	ebp
	push	_3468
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3456
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3458
	call	brl_blitz_NullObjectError
_3458:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_3459
	push	ebp
	push	_3467
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3460
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3462
	call	brl_blitz_NullObjectError
_3462:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3463
	push	ebp
	push	_3466
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3464
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],60
	push	_3465
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],3
	call	dword [bbOnDebugLeaveScope]
_3463:
	call	dword [bbOnDebugLeaveScope]
_3459:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3450
_3452:
	push	ebp
	push	_3481
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3469
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3471
	call	brl_blitz_NullObjectError
_3471:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_3472
	push	ebp
	push	_3480
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3473
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3475
	call	brl_blitz_NullObjectError
_3475:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3476
	push	ebp
	push	_3479
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3477
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],62
	push	_3478
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],3
	call	dword [bbOnDebugLeaveScope]
_3476:
	call	dword [bbOnDebugLeaveScope]
_3472:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3450
_3453:
	push	ebp
	push	_3523
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3482
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3484
	call	brl_blitz_NullObjectError
_3484:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,112
	jne	_3485
	push	ebp
	push	_3503
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3486
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3488
	call	brl_blitz_NullObjectError
_3488:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,111
	jne	_3489
	push	ebp
	push	_3502
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3490
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3492
	call	brl_blitz_NullObjectError
_3492:
	mov	eax,dword [_591]
	add	eax,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,115
	jne	_3493
	push	ebp
	push	_3501
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3494
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3496
	call	brl_blitz_NullObjectError
_3496:
	mov	eax,dword [_591]
	add	eax,5
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3497
	push	ebp
	push	_3500
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3498
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],39
	push	_3499
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],5
	call	dword [bbOnDebugLeaveScope]
_3497:
	call	dword [bbOnDebugLeaveScope]
_3493:
	call	dword [bbOnDebugLeaveScope]
_3489:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3504
_3485:
	push	ebp
	push	_3522
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3505
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3507
	call	brl_blitz_NullObjectError
_3507:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,109
	jne	_3508
	push	ebp
	push	_3521
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3509
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3511
	call	brl_blitz_NullObjectError
_3511:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,112
	jne	_3512
	push	ebp
	push	_3520
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3513
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3515
	call	brl_blitz_NullObjectError
_3515:
	mov	eax,dword [_591]
	add	eax,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3516
	push	ebp
	push	_3519
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3517
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],38
	push	_3518
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],4
	call	dword [bbOnDebugLeaveScope]
_3516:
	call	dword [bbOnDebugLeaveScope]
_3512:
	call	dword [bbOnDebugLeaveScope]
_3508:
	call	dword [bbOnDebugLeaveScope]
_3504:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3450
_3454:
	push	ebp
	push	_3546
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3524
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3526
	call	brl_blitz_NullObjectError
_3526:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,117
	jne	_3527
	push	ebp
	push	_3545
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3528
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3530
	call	brl_blitz_NullObjectError
_3530:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,111
	jne	_3531
	push	ebp
	push	_3544
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3532
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3534
	call	brl_blitz_NullObjectError
_3534:
	mov	eax,dword [_591]
	add	eax,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_3535
	push	ebp
	push	_3543
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3536
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3538
	call	brl_blitz_NullObjectError
_3538:
	mov	eax,dword [_591]
	add	eax,5
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3539
	push	ebp
	push	_3542
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3540
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],34
	push	_3541
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],5
	call	dword [bbOnDebugLeaveScope]
_3539:
	call	dword [bbOnDebugLeaveScope]
_3535:
	call	dword [bbOnDebugLeaveScope]
_3531:
	call	dword [bbOnDebugLeaveScope]
_3527:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3450
_3455:
	push	ebp
	push	_3562
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3547
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],0
	push	_3549
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],0
	push	_3550
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],2
	push	_3551
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3553
	call	brl_blitz_NullObjectError
_3553:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-16],eax
	push	_3554
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_252
_254:
	push	ebp
	push	_3561
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3555
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	imul	eax,10
	mov	dword [ebp-4],eax
	push	_3556
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-16]
	and	eax,15
	add	dword [ebp-4],eax
	push	_3557
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3558
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3560
	call	brl_blitz_NullObjectError
_3560:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
_252:
	cmp	dword [ebp-16],59
	jne	_254
_253:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3450
_3450:
	call	dword [bbOnDebugLeaveScope]
_3445:
	push	_3565
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-8],eax
	push	_3566
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3567
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-12]
	cmp	dword [_591],eax
	jl	_3568
	push	ebp
	push	_3570
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3569
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_250
_3568:
	push	_3571
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3573
	call	brl_blitz_NullObjectError
_3573:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	call	dword [bbOnDebugLeaveScope]
_249:
	mov	eax,dword [ebp-4]
	cmp	eax,60
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_3575
	mov	eax,dword [ebp-4]
	cmp	eax,47
	sete	al
	movzx	eax,al
_3575:
	cmp	eax,0
	jne	_3577
	mov	eax,dword [ebp-4]
	cmp	eax,61
	sete	al
	movzx	eax,al
_3577:
	cmp	eax,0
	jne	_3579
	mov	eax,dword [ebp-4]
	cmp	eax,62
	sete	al
	movzx	eax,al
_3579:
	cmp	eax,0
	jne	_3581
	mov	eax,dword [ebp-4]
	cmp	eax,13
	sete	al
	movzx	eax,al
_3581:
	cmp	eax,0
	je	_251
_250:
	push	_3583
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	sub	dword [_591],1
	push	_3584
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [_587],eax
	push	_3585
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,6
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3436:
	push	ebp
	push	_3687
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3587
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3588
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3590
	call	brl_blitz_NullObjectError
_3590:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	push	_3591
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	eax,47
	je	_3594
	cmp	eax,45
	je	_3595
	cmp	eax,63
	je	_3596
	push	ebp
	push	_3623
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3597
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],_1
	push	_3598
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_237
_239:
	push	ebp
	push	_3614
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3605
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-8],eax
	push	_3606
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3607
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_593]
	cmp	dword [_591],eax
	jne	_3608
	push	ebp
	push	_3610
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3609
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_238
_3608:
	push	_3611
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3613
	call	brl_blitz_NullObjectError
_3613:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	call	dword [bbOnDebugLeaveScope]
_237:
	mov	eax,dword [ebp-4]
	cmp	eax,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_3599
	mov	eax,dword [ebp-4]
	cmp	eax,62
	setne	al
	movzx	eax,al
_3599:
	cmp	eax,0
	je	_3601
	mov	eax,dword [ebp-4]
	cmp	eax,47
	setne	al
	movzx	eax,al
_3601:
	cmp	eax,0
	je	_3603
	mov	eax,dword [ebp-4]
	cmp	eax,9
	setne	al
	movzx	eax,al
_3603:
	cmp	eax,0
	jne	_239
_238:
	push	_3615
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	eax,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_3616
	mov	eax,dword [ebp-4]
	cmp	eax,9
	setne	al
	movzx	eax,al
_3616:
	cmp	eax,0
	je	_3618
	push	ebp
	push	_3620
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3619
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	sub	dword [_591],1
	call	dword [bbOnDebugLeaveScope]
_3618:
	push	_3621
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [_587],eax
	push	_3622
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,1
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3594:
	push	ebp
	push	_3654
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3624
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3625
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3627
	call	brl_blitz_NullObjectError
_3627:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	push	_3628
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],_1
	push	_3629
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_228
_230:
	push	ebp
	push	_3645
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3636
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-8],eax
	push	_3637
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3638
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_593]
	cmp	dword [_591],eax
	jne	_3639
	push	ebp
	push	_3641
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3640
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_229
_3639:
	push	_3642
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3644
	call	brl_blitz_NullObjectError
_3644:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	call	dword [bbOnDebugLeaveScope]
_228:
	mov	eax,dword [ebp-4]
	cmp	eax,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_3630
	mov	eax,dword [ebp-4]
	cmp	eax,62
	setne	al
	movzx	eax,al
_3630:
	cmp	eax,0
	je	_3632
	mov	eax,dword [ebp-4]
	cmp	eax,47
	setne	al
	movzx	eax,al
_3632:
	cmp	eax,0
	je	_3634
	mov	eax,dword [ebp-4]
	cmp	eax,9
	setne	al
	movzx	eax,al
_3634:
	cmp	eax,0
	jne	_230
_229:
	push	_3646
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	cmp	eax,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_3647
	mov	eax,dword [ebp-4]
	cmp	eax,9
	setne	al
	movzx	eax,al
_3647:
	cmp	eax,0
	je	_3649
	push	ebp
	push	_3651
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3650
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	sub	dword [_591],1
	call	dword [bbOnDebugLeaveScope]
_3649:
	push	_3652
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [_587],eax
	push	_3653
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,3
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3595:
	push	ebp
	push	_3670
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3655
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3656
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3658
	call	brl_blitz_NullObjectError
_3658:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	push	_3659
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_231
_233:
	push	ebp
	push	_3668
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3660
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3661
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_593]
	cmp	dword [_591],eax
	jne	_3662
	push	ebp
	push	_3664
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3663
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_232
_3662:
	push	_3665
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3667
	call	brl_blitz_NullObjectError
_3667:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	call	dword [bbOnDebugLeaveScope]
_231:
	cmp	dword [ebp-4],62
	jne	_233
_232:
	push	_3669
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3596:
	push	ebp
	push	_3686
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3671
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3672
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3674
	call	brl_blitz_NullObjectError
_3674:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	push	_3675
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_234
_236:
	push	ebp
	push	_3684
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3676
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3677
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_593]
	cmp	dword [_591],eax
	jne	_3678
	push	ebp
	push	_3680
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3679
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_235
_3678:
	push	_3681
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3683
	call	brl_blitz_NullObjectError
_3683:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	call	dword [bbOnDebugLeaveScope]
_234:
	cmp	dword [ebp-4],62
	jne	_236
_235:
	push	_3685
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3437:
	push	ebp
	push	_3698
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3688
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3689
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3691
	call	brl_blitz_NullObjectError
_3691:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	push	_3692
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-4],62
	jne	_3693
	push	ebp
	push	_3695
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3694
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3693:
	push	_3696
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	sub	dword [_591],1
	push	_3697
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,8
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3438:
	push	ebp
	push	_3700
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3699
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,2
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3439:
	push	ebp
	push	_3702
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3701
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,5
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3440:
	push	ebp
	push	_3841
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3703
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3704
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3706
	call	brl_blitz_NullObjectError
_3706:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	push	_3707
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],_1
	push	_3708
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_240
_242:
	push	ebp
	push	_3838
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3709
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	cmp	dword [ebp-4],38
	jne	_3710
	push	ebp
	push	_3828
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3711
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3713
	call	brl_blitz_NullObjectError
_3713:
	mov	eax,dword [_591]
	add	eax,1
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,108
	je	_3716
	cmp	eax,103
	je	_3717
	cmp	eax,97
	je	_3718
	cmp	eax,113
	je	_3719
	cmp	eax,35
	je	_3720
	jmp	_3715
_3716:
	push	ebp
	push	_3733
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3721
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3723
	call	brl_blitz_NullObjectError
_3723:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_3724
	push	ebp
	push	_3732
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3725
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3727
	call	brl_blitz_NullObjectError
_3727:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3728
	push	ebp
	push	_3731
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3729
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],60
	push	_3730
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],3
	call	dword [bbOnDebugLeaveScope]
_3728:
	call	dword [bbOnDebugLeaveScope]
_3724:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3715
_3717:
	push	ebp
	push	_3746
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3734
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3736
	call	brl_blitz_NullObjectError
_3736:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_3737
	push	ebp
	push	_3745
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3738
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3740
	call	brl_blitz_NullObjectError
_3740:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3741
	push	ebp
	push	_3744
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3742
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],62
	push	_3743
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],3
	call	dword [bbOnDebugLeaveScope]
_3741:
	call	dword [bbOnDebugLeaveScope]
_3737:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3715
_3718:
	push	ebp
	push	_3788
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3747
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3749
	call	brl_blitz_NullObjectError
_3749:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,112
	jne	_3750
	push	ebp
	push	_3768
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3751
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3753
	call	brl_blitz_NullObjectError
_3753:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,111
	jne	_3754
	push	ebp
	push	_3767
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3755
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3757
	call	brl_blitz_NullObjectError
_3757:
	mov	eax,dword [_591]
	add	eax,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,115
	jne	_3758
	push	ebp
	push	_3766
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3759
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3761
	call	brl_blitz_NullObjectError
_3761:
	mov	eax,dword [_591]
	add	eax,5
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3762
	push	ebp
	push	_3765
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3763
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],39
	push	_3764
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],5
	call	dword [bbOnDebugLeaveScope]
_3762:
	call	dword [bbOnDebugLeaveScope]
_3758:
	call	dword [bbOnDebugLeaveScope]
_3754:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3769
_3750:
	push	ebp
	push	_3787
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3770
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3772
	call	brl_blitz_NullObjectError
_3772:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,109
	jne	_3773
	push	ebp
	push	_3786
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3774
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3776
	call	brl_blitz_NullObjectError
_3776:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,112
	jne	_3777
	push	ebp
	push	_3785
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3778
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3780
	call	brl_blitz_NullObjectError
_3780:
	mov	eax,dword [_591]
	add	eax,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3781
	push	ebp
	push	_3784
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3782
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],38
	push	_3783
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],4
	call	dword [bbOnDebugLeaveScope]
_3781:
	call	dword [bbOnDebugLeaveScope]
_3777:
	call	dword [bbOnDebugLeaveScope]
_3773:
	call	dword [bbOnDebugLeaveScope]
_3769:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3715
_3719:
	push	ebp
	push	_3811
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3789
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3791
	call	brl_blitz_NullObjectError
_3791:
	mov	eax,dword [_591]
	add	eax,2
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,117
	jne	_3792
	push	ebp
	push	_3810
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3793
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3795
	call	brl_blitz_NullObjectError
_3795:
	mov	eax,dword [_591]
	add	eax,3
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,111
	jne	_3796
	push	ebp
	push	_3809
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3797
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3799
	call	brl_blitz_NullObjectError
_3799:
	mov	eax,dword [_591]
	add	eax,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,116
	jne	_3800
	push	ebp
	push	_3808
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3801
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3803
	call	brl_blitz_NullObjectError
_3803:
	mov	eax,dword [_591]
	add	eax,5
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	cmp	eax,59
	jne	_3804
	push	ebp
	push	_3807
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3805
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],34
	push	_3806
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],5
	call	dword [bbOnDebugLeaveScope]
_3804:
	call	dword [bbOnDebugLeaveScope]
_3800:
	call	dword [bbOnDebugLeaveScope]
_3796:
	call	dword [bbOnDebugLeaveScope]
_3792:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3715
_3720:
	push	ebp
	push	_3827
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3812
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-20],0
	push	_3814
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-4],0
	push	_3815
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],2
	push	_3816
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3818
	call	brl_blitz_NullObjectError
_3818:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-20],eax
	push	_3819
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_243
_245:
	push	ebp
	push	_3826
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3820
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	imul	eax,10
	mov	dword [ebp-4],eax
	push	_3821
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-20]
	and	eax,15
	add	dword [ebp-4],eax
	push	_3822
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3823
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3825
	call	brl_blitz_NullObjectError
_3825:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-20],eax
	call	dword [bbOnDebugLeaveScope]
_243:
	cmp	dword [ebp-20],59
	jne	_245
_244:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3715
_3715:
	call	dword [bbOnDebugLeaveScope]
_3710:
	push	_3829
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-4]
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	dword [ebp-8]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-8],eax
	push	_3830
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3831
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_593]
	cmp	dword [_591],eax
	jne	_3832
	push	ebp
	push	_3834
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3833
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_241
_3832:
	push	_3835
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3837
	call	brl_blitz_NullObjectError
_3837:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	call	dword [bbOnDebugLeaveScope]
_240:
	cmp	dword [ebp-4],34
	jne	_242
_241:
	push	_3839
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-8]
	mov	dword [_587],eax
	push	_3840
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,7
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_3441:
	push	ebp
	push	_3860
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3842
	call	dword [bbOnDebugEnterStm]
	add	esp,4
_248:
	push	ebp
	push	_3851
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3843
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	add	dword [_591],1
	push	_3844
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [_593]
	cmp	dword [_591],eax
	jne	_3845
	push	ebp
	push	_3847
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3846
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	call	dword [bbOnDebugLeaveScope]
	call	dword [bbOnDebugLeaveScope]
	jmp	_247
_3845:
	push	_3848
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [_589]
	cmp	ebx,bbNullObject
	jne	_3850
	call	brl_blitz_NullObjectError
_3850:
	push	dword [_591]
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+84]
	add	esp,8
	mov	dword [ebp-4],eax
	call	dword [bbOnDebugLeaveScope]
_246:
	mov	eax,dword [ebp-4]
	cmp	eax,32
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_3852
	mov	eax,dword [ebp-4]
	cmp	eax,13
	setne	al
	movzx	eax,al
_3852:
	cmp	eax,0
	je	_3854
	mov	eax,dword [ebp-4]
	cmp	eax,10
	setne	al
	movzx	eax,al
_3854:
	cmp	eax,0
	je	_3856
	mov	eax,dword [ebp-4]
	cmp	eax,9
	setne	al
	movzx	eax,al
_3856:
	cmp	eax,0
	je	_248
_247:
	push	_3858
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	sub	dword [_591],1
	push	_3859
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,0
	call	dword [bbOnDebugLeaveScope]
	jmp	_575
_575:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_255:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	push	edi
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	mov	dword [ebp-16],bbEmptyString
	mov	eax,ebp
	push	eax
	push	_3924
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3865
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	dword [ebp-12],0
	push	_3868
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-16],_1
	push	_3870
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	eax,dword [eax+8]
	mov	dword [ebp-12],eax
	push	_3871
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],0
	mov	eax,dword [ebp-12]
	sub	eax,1
	mov	edi,eax
	jmp	_3872
_258:
	mov	eax,ebp
	push	eax
	push	_3922
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3874
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+8]
	jb	_3877
	call	brl_blitz_ArrayBoundsError
_3877:
	movzx	eax,word [esi+ebx*2+12]
	mov	eax,eax
	cmp	eax,60
	je	_3880
	cmp	eax,62
	je	_3881
	cmp	eax,34
	je	_3882
	cmp	eax,39
	je	_3883
	cmp	eax,38
	je	_3884
	mov	eax,ebp
	push	eax
	push	_3911
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3885
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+8]
	jb	_3888
	call	brl_blitz_ArrayBoundsError
_3888:
	movzx	eax,word [esi+ebx*2+12]
	mov	eax,eax
	cmp	eax,32
	setl	al
	movzx	eax,al
	cmp	eax,0
	jne	_3892
	mov	esi,dword [ebp-4]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+8]
	jb	_3891
	call	brl_blitz_ArrayBoundsError
_3891:
	movzx	eax,word [esi+ebx*2+12]
	mov	eax,eax
	cmp	eax,126
	setg	al
	movzx	eax,al
_3892:
	cmp	eax,0
	je	_3897
	mov	esi,dword [ebp-4]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+8]
	jb	_3896
	call	brl_blitz_ArrayBoundsError
_3896:
	movzx	eax,word [esi+ebx*2+12]
	mov	eax,eax
	cmp	eax,255
	setle	al
	movzx	eax,al
_3897:
	cmp	eax,0
	je	_3899
	mov	eax,ebp
	push	eax
	push	_3904
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3900
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+8]
	jb	_3903
	call	brl_blitz_ArrayBoundsError
_3903:
	push	_265
	movzx	eax,word [esi+ebx*2+12]
	mov	eax,eax
	push	eax
	call	bbStringFromInt
	add	esp,4
	push	eax
	push	_264
	push	dword [ebp-16]
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	push	eax
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3905
_3899:
	mov	eax,ebp
	push	eax
	push	_3910
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3906
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	esi,dword [ebp-4]
	mov	ebx,dword [ebp-8]
	cmp	ebx,dword [esi+8]
	jb	_3909
	call	brl_blitz_ArrayBoundsError
_3909:
	movzx	eax,word [esi+ebx*2+12]
	mov	eax,eax
	push	eax
	call	bbStringFromChar
	add	esp,4
	push	eax
	push	dword [ebp-16]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
_3905:
	call	dword [bbOnDebugLeaveScope]
	jmp	_3879
_3880:
	mov	eax,ebp
	push	eax
	push	_3913
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3912
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_259
	push	dword [ebp-16]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3879
_3881:
	mov	eax,ebp
	push	eax
	push	_3915
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3914
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_260
	push	dword [ebp-16]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3879
_3882:
	mov	eax,ebp
	push	eax
	push	_3917
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3916
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_261
	push	dword [ebp-16]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3879
_3883:
	mov	eax,ebp
	push	eax
	push	_3919
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3918
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_262
	push	dword [ebp-16]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3879
_3884:
	mov	eax,ebp
	push	eax
	push	_3921
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3920
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	_263
	push	dword [ebp-16]
	call	bbStringConcat
	add	esp,8
	mov	dword [ebp-16],eax
	call	dword [bbOnDebugLeaveScope]
	jmp	_3879
_3879:
	call	dword [bbOnDebugLeaveScope]
_256:
	add	dword [ebp-8],1
_3872:
	cmp	dword [ebp-8],edi
	jle	_258
_257:
	push	_3923
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-16]
	jmp	_578
_578:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_266:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	dword [ebp-8],bbNullObject
	mov	dword [ebp-12],0
	push	ebp
	push	_3943
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3929
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-8],bbNullObject
	mov	dword [ebp-12],0
	push	_3932
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	dword [ebp-12],1
	push	_3933
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-4]
	cmp	ebx,bbNullObject
	jne	_3935
	call	brl_blitz_NullObjectError
_3935:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+88]
	add	esp,4
	mov	dword [ebp-8],eax
	push	_3936
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	jmp	_267
_269:
	push	ebp
	push	_3941
	call	dword [bbOnDebugEnterScope]
	add	esp,8
	push	_3937
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	push	dword [ebp-8]
	call	_266
	add	esp,4
	add	dword [ebp-12],eax
	push	_3938
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-8]
	cmp	ebx,bbNullObject
	jne	_3940
	call	brl_blitz_NullObjectError
_3940:
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+132]
	add	esp,4
	mov	dword [ebp-8],eax
	call	dword [bbOnDebugLeaveScope]
_267:
	cmp	dword [ebp-8],bbNullObject
	jne	_269
_268:
	push	_3942
	call	dword [bbOnDebugEnterStm]
	add	esp,4
	mov	ebx,dword [ebp-12]
	jmp	_581
_581:
	call	dword [bbOnDebugLeaveScope]
	mov	eax,ebx
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_673:
	dd	0
_595:
	db	"basefunctions_xml",0
_596:
	db	"APPEND_STATUS_CREATE",0
_296:
	db	"i",0
	align	4
_597:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	48
_598:
	db	"APPEND_STATUS_CREATEAFTER",0
	align	4
_599:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	49
_600:
	db	"APPEND_STATUS_ADDINZIP",0
	align	4
_601:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	50
_602:
	db	"Z_DEFLATED",0
	align	4
_603:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	56
_604:
	db	"Z_NO_COMPRESSION",0
_605:
	db	"Z_BEST_SPEED",0
_606:
	db	"Z_BEST_COMPRESSION",0
	align	4
_607:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	57
_608:
	db	"Z_DEFAULT_COMPRESSION",0
	align	4
_609:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,49
_610:
	db	"UNZ_CASE_CHECK",0
_611:
	db	"UNZ_NO_CASE_CHECK",0
_612:
	db	"UNZ_OK",0
_613:
	db	"UNZ_END_OF_LIST_OF_FILE",0
	align	4
_614:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,48
_615:
	db	"UNZ_EOF",0
_616:
	db	"UNZ_PARAMERROR",0
	align	4
_617:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,50
_618:
	db	"UNZ_BADZIPFILE",0
	align	4
_619:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,51
_620:
	db	"UNZ_INTERNALERROR",0
	align	4
_621:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,52
_622:
	db	"UNZ_CRCERROR",0
	align	4
_623:
	dd	bbStringClass
	dd	2147483646
	dd	4
	dw	45,49,48,53
_624:
	db	"ZLIB_FILEFUNC_SEEK_CUR",0
_625:
	db	"ZLIB_FILEFUNC_SEEK_END",0
_626:
	db	"ZLIB_FILEFUNC_SEEK_SET",0
_627:
	db	"Z_OK",0
_628:
	db	"Z_STREAM_END",0
_629:
	db	"Z_NEED_DICT",0
_630:
	db	"Z_ERRNO",0
_631:
	db	"Z_STREAM_ERROR",0
	align	4
_632:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,50
_633:
	db	"Z_DATA_ERROR",0
	align	4
_634:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,51
_635:
	db	"Z_MEM_ERROR",0
	align	4
_636:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,52
_637:
	db	"Z_BUF_ERROR",0
	align	4
_638:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,53
_639:
	db	"Z_VERSION_ERROR",0
	align	4
_640:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	45,54
_641:
	db	"ZIP_INFO_IN_DATA_DESCRIPTOR",0
_642:
	db	"s",0
_643:
	db	"AS_CHILD",0
_644:
	db	"AS_SIBLING",0
_645:
	db	"FORMAT_XML",0
_646:
	db	"FORMAT_BINARY",0
_647:
	db	"SORTBY_NODE_NAME",0
_648:
	db	"SORTBY_NODE_VALUE",0
_649:
	db	"SORTBY_ATTR_NAME",0
	align	4
_650:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	51
_651:
	db	"SORTBY_ATTR_VALUE",0
	align	4
_652:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	52
_653:
	db	"TOKEN_EOF",0
_654:
	db	"TOKEN_NONE",0
_655:
	db	"TOKEN_BEGIN_TAG",0
_656:
	db	"TOKEN_END_TAG",0
_657:
	db	"TOKEN_BEGIN_SLASHTAG",0
_658:
	db	"TOKEN_END_SLASHTAG",0
_659:
	db	"TOKEN_EQUALS",0
	align	4
_660:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	53
_661:
	db	"TOKEN_TEXT",0
	align	4
_662:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	54
_663:
	db	"TOKEN_QUOTEDTEXT",0
	align	4
_664:
	dd	bbStringClass
	dd	2147483646
	dd	1
	dw	55
_665:
	db	"TOKEN_SLASH",0
_666:
	db	"BinaryFile",0
_667:
	db	":brl.stream.TStream",0
	align	4
_585:
	dd	bbNullObject
_668:
	db	"TokenValue",0
_292:
	db	"$",0
	align	4
_587:
	dd	bbEmptyString
_669:
	db	"TokenBuffer",0
_670:
	db	":brl.bank.TBank",0
	align	4
_589:
	dd	bbNullObject
_671:
	db	"TokenBufferPos",0
	align	4
_591:
	dd	0
_672:
	db	"TokenBufferLen",0
	align	4
_593:
	dd	0
	align	4
_594:
	dd	1
	dd	_595
	dd	1
	dd	_596
	dd	_296
	dd	_597
	dd	1
	dd	_598
	dd	_296
	dd	_599
	dd	1
	dd	_600
	dd	_296
	dd	_601
	dd	1
	dd	_602
	dd	_296
	dd	_603
	dd	1
	dd	_604
	dd	_296
	dd	_597
	dd	1
	dd	_605
	dd	_296
	dd	_599
	dd	1
	dd	_606
	dd	_296
	dd	_607
	dd	1
	dd	_608
	dd	_296
	dd	_609
	dd	1
	dd	_610
	dd	_296
	dd	_599
	dd	1
	dd	_611
	dd	_296
	dd	_601
	dd	1
	dd	_612
	dd	_296
	dd	_597
	dd	1
	dd	_613
	dd	_296
	dd	_614
	dd	1
	dd	_615
	dd	_296
	dd	_597
	dd	1
	dd	_616
	dd	_296
	dd	_617
	dd	1
	dd	_618
	dd	_296
	dd	_619
	dd	1
	dd	_620
	dd	_296
	dd	_621
	dd	1
	dd	_622
	dd	_296
	dd	_623
	dd	1
	dd	_624
	dd	_296
	dd	_599
	dd	1
	dd	_625
	dd	_296
	dd	_601
	dd	1
	dd	_626
	dd	_296
	dd	_597
	dd	1
	dd	_627
	dd	_296
	dd	_597
	dd	1
	dd	_628
	dd	_296
	dd	_599
	dd	1
	dd	_629
	dd	_296
	dd	_601
	dd	1
	dd	_630
	dd	_296
	dd	_609
	dd	1
	dd	_631
	dd	_296
	dd	_632
	dd	1
	dd	_633
	dd	_296
	dd	_634
	dd	1
	dd	_635
	dd	_296
	dd	_636
	dd	1
	dd	_637
	dd	_296
	dd	_638
	dd	1
	dd	_639
	dd	_296
	dd	_640
	dd	1
	dd	_641
	dd	_642
	dd	_603
	dd	1
	dd	_643
	dd	_296
	dd	_599
	dd	1
	dd	_644
	dd	_296
	dd	_601
	dd	1
	dd	_645
	dd	_296
	dd	_599
	dd	1
	dd	_646
	dd	_296
	dd	_601
	dd	1
	dd	_647
	dd	_296
	dd	_599
	dd	1
	dd	_648
	dd	_296
	dd	_601
	dd	1
	dd	_649
	dd	_296
	dd	_650
	dd	1
	dd	_651
	dd	_296
	dd	_652
	dd	1
	dd	_653
	dd	_296
	dd	_609
	dd	1
	dd	_654
	dd	_296
	dd	_597
	dd	1
	dd	_655
	dd	_296
	dd	_599
	dd	1
	dd	_656
	dd	_296
	dd	_601
	dd	1
	dd	_657
	dd	_296
	dd	_650
	dd	1
	dd	_658
	dd	_296
	dd	_652
	dd	1
	dd	_659
	dd	_296
	dd	_660
	dd	1
	dd	_661
	dd	_296
	dd	_662
	dd	1
	dd	_663
	dd	_296
	dd	_664
	dd	1
	dd	_665
	dd	_296
	dd	_603
	dd	4
	dd	_666
	dd	_667
	dd	_585
	dd	4
	dd	_668
	dd	_292
	dd	_587
	dd	4
	dd	_669
	dd	_670
	dd	_589
	dd	4
	dd	_671
	dd	_296
	dd	_591
	dd	4
	dd	_672
	dd	_296
	dd	_593
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
_293:
	db	"Value",0
_294:
	db	"Parent",0
_295:
	db	"Level",0
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
	dd	bbObjectDtor
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
	dd	bbObjectDtor
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_xmlAttribute_NextAttr
	dd	_bb_xmlAttribute_PrevAttr
	dd	_bb_xmlAttribute_Free
_584:
	db	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/basefunctions_xml.bmx",0
	align	4
_583:
	dd	_584
	dd	1297
	dd	1
	align	4
_586:
	dd	_584
	dd	1354
	dd	1
	align	4
_588:
	dd	_584
	dd	1356
	dd	1
	align	4
_590:
	dd	_584
	dd	1357
	dd	1
	align	4
_592:
	dd	_584
	dd	1358
	dd	1
_677:
	db	"Self",0
	align	4
_676:
	dd	1
	dd	_274
	dd	2
	dd	_677
	dd	_303
	dd	-4
	dd	0
	align	4
_675:
	dd	3
	dd	0
	dd	0
_690:
	db	"Url",0
_691:
	db	":Object",0
_692:
	db	"zipped",0
_693:
	db	"b",0
_694:
	db	"doc",0
	align	4
_689:
	dd	1
	dd	_277
	dd	2
	dd	_690
	dd	_691
	dd	-8
	dd	2
	dd	_692
	dd	_693
	dd	-4
	dd	2
	dd	_694
	dd	_303
	dd	-12
	dd	0
	align	4
_680:
	dd	_584
	dd	56
	dd	3
	align	4
_682:
	dd	_584
	dd	57
	dd	3
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_687:
	dd	3
	dd	0
	dd	0
	align	4
_684:
	dd	_584
	dd	57
	dd	21
	align	4
_688:
	dd	_584
	dd	58
	dd	3
	align	4
_749:
	dd	1
	dd	_279
	dd	2
	dd	_677
	dd	_303
	dd	-4
	dd	0
	align	4
_695:
	dd	_584
	dd	69
	dd	3
	align	4
_745:
	dd	3
	dd	0
	dd	0
	align	4
_699:
	dd	_584
	dd	70
	dd	4
	align	4
_703:
	dd	_584
	dd	71
	dd	4
	align	4
_709:
	dd	_584
	dd	72
	dd	4
	align	4
_715:
	dd	_584
	dd	73
	dd	4
	align	4
_721:
	dd	_584
	dd	74
	dd	4
	align	4
_727:
	dd	_584
	dd	75
	dd	4
	align	4
_3:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	114,111,111,116
	align	4
_733:
	dd	_584
	dd	76
	dd	4
	align	4
_739:
	dd	_584
	dd	77
	dd	4
	align	4
_746:
	dd	_584
	dd	80
	dd	3
_817:
	db	"File",0
_818:
	db	"Format",0
	align	4
_816:
	dd	1
	dd	_281
	dd	2
	dd	_677
	dd	_303
	dd	-8
	dd	2
	dd	_690
	dd	_691
	dd	-12
	dd	2
	dd	_692
	dd	_693
	dd	-4
	dd	2
	dd	_817
	dd	_667
	dd	-16
	dd	2
	dd	_818
	dd	_296
	dd	-20
	dd	0
	align	4
_750:
	dd	_584
	dd	91
	dd	3
	align	4
_752:
	dd	_584
	dd	92
	dd	3
	align	4
_754:
	dd	_584
	dd	93
	dd	3
	align	4
_762:
	dd	3
	dd	0
	dd	0
	align	4
_756:
	dd	_584
	dd	98
	dd	5
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
_759:
	dd	_584
	dd	99
	dd	5
	align	4
_765:
	dd	3
	dd	0
	dd	0
	align	4
_764:
	dd	_584
	dd	102
	dd	4
	align	4
_766:
	dd	_584
	dd	105
	dd	3
	align	4
_767:
	dd	_584
	dd	106
	dd	3
	align	4
_772:
	dd	3
	dd	0
	dd	0
	align	4
_769:
	dd	_584
	dd	106
	dd	23
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
_773:
	dd	_584
	dd	107
	dd	3
	align	4
_788:
	dd	3
	dd	0
	dd	0
	align	4
_777:
	dd	_584
	dd	108
	dd	4
	align	4
_787:
	dd	3
	dd	0
	dd	0
	align	4
_781:
	dd	_584
	dd	109
	dd	5
	align	4
_786:
	dd	3
	dd	0
	dd	0
	align	4
_785:
	dd	_584
	dd	110
	dd	6
	align	4
_789:
	dd	_584
	dd	114
	dd	3
	align	4
_792:
	dd	_584
	dd	116
	dd	3
	align	4
_802:
	dd	3
	dd	0
	dd	0
	align	4
_797:
	dd	_584
	dd	119
	dd	5
	align	4
_798:
	dd	_584
	dd	122
	dd	5
	align	4
_801:
	dd	_584
	dd	125
	dd	5
	align	4
_808:
	dd	3
	dd	0
	dd	0
	align	4
_803:
	dd	_584
	dd	129
	dd	5
	align	4
_804:
	dd	_584
	dd	132
	dd	5
	align	4
_807:
	dd	_584
	dd	135
	dd	5
	align	4
_809:
	dd	_584
	dd	138
	dd	3
	align	4
_8:
	dd	bbStringClass
	dd	2147483647
	dd	12
	dw	115,97,118,101,103,97,109,101,46,116,109,112
	align	4
_815:
	dd	3
	dd	0
	dd	0
	align	4
_811:
	dd	_584
	dd	139
	dd	4
	align	4
_814:
	dd	3
	dd	0
	dd	0
	align	4
_813:
	dd	_584
	dd	139
	dd	43
	align	4
_9:
	dd	bbStringClass
	dd	2147483647
	dd	48
	dw	70,101,104,108,101,114,32,98,101,105,109,32,76,111,101,115
	dw	99,104,101,110,32,100,101,114,32,84,101,109,112,100,97,116
	dw	101,105,32,115,97,118,101,103,97,109,101,46,116,109,112,32
_890:
	db	"zwObject",0
_891:
	db	":ZipWriter",0
	align	4
_889:
	dd	1
	dd	_283
	dd	2
	dd	_677
	dd	_303
	dd	-8
	dd	2
	dd	_690
	dd	_691
	dd	-12
	dd	2
	dd	_818
	dd	_296
	dd	-16
	dd	2
	dd	_692
	dd	_693
	dd	-4
	dd	2
	dd	_817
	dd	_667
	dd	-20
	dd	2
	dd	_890
	dd	_891
	dd	-24
	dd	0
	align	4
_819:
	dd	_584
	dd	150
	dd	3
	align	4
_821:
	dd	_584
	dd	151
	dd	3
	align	4
_823:
	dd	_584
	dd	153
	dd	3
	align	4
_826:
	dd	3
	dd	0
	dd	0
	align	4
_825:
	dd	_584
	dd	153
	dd	18
	align	4
_827:
	dd	_584
	dd	154
	dd	5
	align	4
_828:
	dd	_584
	dd	156
	dd	3
	align	4
_844:
	dd	3
	dd	0
	dd	0
	align	4
_833:
	dd	_584
	dd	159
	dd	5
	align	4
_10:
	dd	bbStringClass
	dd	2147483647
	dd	21
	dw	60,63,120,109,108,32,118,101,114,115,105,111,110,61,34,49
	dw	46,48,34,63,62
	align	4
_836:
	dd	_584
	dd	162
	dd	5
	align	4
_843:
	dd	3
	dd	0
	dd	0
	align	4
_840:
	dd	_584
	dd	163
	dd	6
	align	4
_862:
	dd	3
	dd	0
	dd	0
	align	4
_845:
	dd	_584
	dd	168
	dd	5
	align	4
_848:
	dd	_584
	dd	169
	dd	5
	align	4
_851:
	dd	_584
	dd	170
	dd	5
	align	4
_854:
	dd	_584
	dd	173
	dd	5
	align	4
_861:
	dd	3
	dd	0
	dd	0
	align	4
_858:
	dd	_584
	dd	174
	dd	6
	align	4
_863:
	dd	_584
	dd	179
	dd	3
	align	4
_866:
	dd	_584
	dd	180
	dd	3
	align	4
_888:
	dd	3
	dd	0
	dd	0
	align	4
_868:
	dd	_584
	dd	181
	dd	4
	align	4
_11:
	dd	bbStringClass
	dd	2147483647
	dd	12
	dw	115,97,118,101,103,97,109,101,46,122,105,112
	align	4
_880:
	dd	3
	dd	0
	dd	0
	align	4
_872:
	dd	_584
	dd	182
	dd	5
	align	4
_877:
	dd	_584
	dd	183
	dd	5
	align	4
_881:
	dd	_584
	dd	185
	dd	6
	align	4
_882:
	dd	_584
	dd	186
	dd	4
	align	4
_885:
	dd	_584
	dd	187
	dd	4
	align	4
_895:
	dd	1
	dd	_285
	dd	2
	dd	_677
	dd	_303
	dd	-4
	dd	0
	align	4
_892:
	dd	_584
	dd	196
	dd	3
_897:
	db	"Key",0
	align	4
_896:
	dd	1
	dd	_286
	dd	2
	dd	_677
	dd	_303
	dd	-4
	dd	2
	dd	_897
	dd	_292
	dd	-8
	dd	0
	align	4
_908:
	dd	1
	dd	_288
	dd	2
	dd	_677
	dd	_303
	dd	-4
	dd	0
	align	4
_898:
	dd	_584
	dd	211
	dd	3
	align	4
_907:
	dd	3
	dd	0
	dd	0
	align	4
_902:
	dd	_584
	dd	211
	dd	29
	align	4
_910:
	dd	1
	dd	_274
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_909:
	dd	3
	dd	0
	dd	0
_986:
	db	"Position",0
_987:
	db	"newnode",0
	align	4
_985:
	dd	1
	dd	_304
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_291
	dd	_292
	dd	-8
	dd	2
	dd	_986
	dd	_296
	dd	-12
	dd	2
	dd	_987
	dd	_273
	dd	-16
	dd	0
	align	4
_911:
	dd	_584
	dd	273
	dd	6
	align	4
_913:
	dd	_584
	dd	275
	dd	3
	align	4
_914:
	dd	_584
	dd	276
	dd	3
	align	4
_918:
	dd	_584
	dd	277
	dd	3
	align	4
_922:
	dd	_584
	dd	279
	dd	3
	align	4
_928:
	dd	_584
	dd	281
	dd	3
	align	4
_932:
	dd	_584
	dd	282
	dd	3
	align	4
_936:
	dd	_584
	dd	285
	dd	3
	align	4
_955:
	dd	3
	dd	0
	dd	0
	align	4
_941:
	dd	_584
	dd	287
	dd	5
	align	4
_945:
	dd	_584
	dd	288
	dd	5
	align	4
_980:
	dd	3
	dd	0
	dd	0
	align	4
_956:
	dd	_584
	dd	291
	dd	5
	align	4
_961:
	dd	3
	dd	0
	dd	0
	align	4
_960:
	dd	_584
	dd	291
	dd	27
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
_962:
	dd	_584
	dd	292
	dd	5
	align	4
_968:
	dd	_584
	dd	293
	dd	5
	align	4
_981:
	dd	_584
	dd	297
	dd	3
	align	4
_984:
	dd	_584
	dd	299
	dd	3
_1078:
	db	"Dest",0
_1079:
	db	"temp",0
	align	4
_1077:
	dd	1
	dd	_306
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_1078
	dd	_273
	dd	-8
	dd	2
	dd	_986
	dd	_296
	dd	-12
	dd	2
	dd	_1079
	dd	_273
	dd	-16
	dd	0
	align	4
_988:
	dd	_584
	dd	310
	dd	6
	align	4
_990:
	dd	_584
	dd	311
	dd	6
	align	4
_1002:
	dd	3
	dd	0
	dd	0
	align	4
_994:
	dd	_584
	dd	312
	dd	7
	align	4
_997:
	dd	3
	dd	0
	dd	0
	align	4
_996:
	dd	_584
	dd	312
	dd	35
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
_998:
	dd	_584
	dd	313
	dd	7
	align	4
_1001:
	dd	3
	dd	0
	dd	0
	align	4
_1000:
	dd	_584
	dd	313
	dd	37
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
_1003:
	dd	_584
	dd	315
	dd	6
	align	4
_1006:
	dd	3
	dd	0
	dd	0
	align	4
_1005:
	dd	_584
	dd	315
	dd	26
	align	4
_1007:
	dd	_584
	dd	316
	dd	6
	align	4
_1008:
	dd	_584
	dd	323
	dd	6
	align	4
_1023:
	dd	3
	dd	0
	dd	0
	align	4
_1009:
	dd	_584
	dd	318
	dd	7
	align	4
_1012:
	dd	_584
	dd	319
	dd	7
	align	4
_1022:
	dd	3
	dd	0
	dd	0
	align	4
_1014:
	dd	_584
	dd	320
	dd	8
	align	4
_1017:
	dd	3
	dd	0
	dd	0
	align	4
_1016:
	dd	_584
	dd	320
	dd	36
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
_1018:
	dd	_584
	dd	321
	dd	8
	align	4
_1021:
	dd	3
	dd	0
	dd	0
	align	4
_1020:
	dd	_584
	dd	321
	dd	38
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
_1024:
	dd	_584
	dd	326
	dd	3
	align	4
_1029:
	dd	_584
	dd	329
	dd	3
	align	4
_1048:
	dd	3
	dd	0
	dd	0
	align	4
_1034:
	dd	_584
	dd	331
	dd	5
	align	4
_1038:
	dd	_584
	dd	332
	dd	5
	align	4
_1073:
	dd	3
	dd	0
	dd	0
	align	4
_1049:
	dd	_584
	dd	335
	dd	5
	align	4
_1054:
	dd	3
	dd	0
	dd	0
	align	4
_1053:
	dd	_584
	dd	335
	dd	32
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
_1055:
	dd	_584
	dd	336
	dd	5
	align	4
_1061:
	dd	_584
	dd	337
	dd	5
	align	4
_1074:
	dd	_584
	dd	341
	dd	3
_1164:
	db	"this",0
	align	4
_1163:
	dd	1
	dd	_308
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_1078
	dd	_273
	dd	-8
	dd	2
	dd	_986
	dd	_296
	dd	-12
	dd	2
	dd	_1164
	dd	_273
	dd	-16
	dd	0
	align	4
_1080:
	dd	_584
	dd	354
	dd	6
	align	4
_1092:
	dd	3
	dd	0
	dd	0
	align	4
_1084:
	dd	_584
	dd	355
	dd	7
	align	4
_1087:
	dd	3
	dd	0
	dd	0
	align	4
_1086:
	dd	_584
	dd	355
	dd	35
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
_1088:
	dd	_584
	dd	356
	dd	7
	align	4
_1091:
	dd	3
	dd	0
	dd	0
	align	4
_1090:
	dd	_584
	dd	356
	dd	37
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
_1093:
	dd	_584
	dd	358
	dd	6
	align	4
_1103:
	dd	3
	dd	0
	dd	0
	align	4
_1095:
	dd	_584
	dd	359
	dd	7
	align	4
_1098:
	dd	3
	dd	0
	dd	0
	align	4
_1097:
	dd	_584
	dd	359
	dd	35
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
_1099:
	dd	_584
	dd	360
	dd	7
	align	4
_1102:
	dd	3
	dd	0
	dd	0
	align	4
_1101:
	dd	_584
	dd	360
	dd	37
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
_1104:
	dd	_584
	dd	364
	dd	6
	align	4
_1106:
	dd	_584
	dd	365
	dd	6
	align	4
_1109:
	dd	_584
	dd	368
	dd	3
	align	4
_1114:
	dd	_584
	dd	371
	dd	3
	align	4
_1133:
	dd	3
	dd	0
	dd	0
	align	4
_1119:
	dd	_584
	dd	373
	dd	5
	align	4
_1123:
	dd	_584
	dd	374
	dd	5
	align	4
_1158:
	dd	3
	dd	0
	dd	0
	align	4
_1134:
	dd	_584
	dd	377
	dd	5
	align	4
_1139:
	dd	3
	dd	0
	dd	0
	align	4
_1138:
	dd	_584
	dd	377
	dd	32
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
_1140:
	dd	_584
	dd	378
	dd	5
	align	4
_1146:
	dd	_584
	dd	379
	dd	5
	align	4
_1159:
	dd	_584
	dd	383
	dd	3
	align	4
_1162:
	dd	_584
	dd	385
	dd	3
_1285:
	db	"_Parent",0
_1286:
	db	"tempnode",0
_1287:
	db	"attr",0
_1288:
	db	":xmlAttribute",0
_1289:
	db	"newattr",0
	align	4
_1284:
	dd	1
	dd	_310
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_1285
	dd	_273
	dd	-8
	dd	2
	dd	_987
	dd	_273
	dd	-12
	dd	2
	dd	_1286
	dd	_273
	dd	-16
	dd	2
	dd	_1287
	dd	_1288
	dd	-20
	dd	2
	dd	_1289
	dd	_1288
	dd	-24
	dd	0
	align	4
_1165:
	dd	_584
	dd	395
	dd	3
	align	4
_1170:
	dd	3
	dd	0
	dd	0
	align	4
_1169:
	dd	_584
	dd	395
	dd	30
	align	4
_27:
	dd	bbStringClass
	dd	2147483647
	dd	38
	dw	120,109,108,78,111,100,101,46,67,111,112,121,40,41,58,32
	dw	67,97,110,110,111,116,32,99,111,112,121,32,114,111,111,116
	dw	32,110,111,100,101,46
	align	4
_1171:
	dd	_584
	dd	397
	dd	3
	align	4
_1174:
	dd	_584
	dd	399
	dd	3
	align	4
_1175:
	dd	_584
	dd	400
	dd	3
	align	4
_1179:
	dd	_584
	dd	401
	dd	3
	align	4
_1183:
	dd	_584
	dd	404
	dd	3
	align	4
_1189:
	dd	_584
	dd	405
	dd	3
	align	4
_1195:
	dd	_584
	dd	406
	dd	3
	align	4
_1203:
	dd	3
	dd	0
	dd	0
	align	4
_1197:
	dd	_584
	dd	406
	dd	26
	align	4
_1209:
	dd	3
	dd	0
	dd	0
	align	4
_1205:
	dd	_584
	dd	406
	dd	60
	align	4
_1210:
	dd	_584
	dd	407
	dd	3
	align	4
_1216:
	dd	_584
	dd	408
	dd	3
	align	4
_1226:
	dd	_584
	dd	411
	dd	3
	align	4
_1229:
	dd	_584
	dd	412
	dd	3
	align	4
_1267:
	dd	3
	dd	0
	dd	0
	align	4
_1240:
	dd	_584
	dd	413
	dd	4
	align	4
_1241:
	dd	_584
	dd	414
	dd	4
	align	4
_1247:
	dd	_584
	dd	415
	dd	4
	align	4
_1253:
	dd	_584
	dd	416
	dd	4
	align	4
_1259:
	dd	_584
	dd	417
	dd	4
	align	4
_1268:
	dd	_584
	dd	421
	dd	3
	align	4
_1282:
	dd	3
	dd	0
	dd	0
	align	4
_1279:
	dd	_584
	dd	422
	dd	4
	align	4
_1283:
	dd	_584
	dd	425
	dd	3
_1509:
	db	"BeforeNode",0
_1510:
	db	"BeforeSelf",0
	align	4
_1508:
	dd	1
	dd	_312
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_354
	dd	_273
	dd	-8
	dd	2
	dd	_1079
	dd	_273
	dd	-12
	dd	2
	dd	_1509
	dd	_301
	dd	-16
	dd	2
	dd	_1510
	dd	_301
	dd	-20
	dd	0
	align	4
_1290:
	dd	_584
	dd	435
	dd	6
	align	4
_1292:
	dd	_584
	dd	437
	dd	6
	align	4
_1295:
	dd	3
	dd	0
	dd	0
	align	4
_1294:
	dd	_584
	dd	438
	dd	7
	align	4
_1296:
	dd	_584
	dd	442
	dd	6
	align	4
_1297:
	dd	_584
	dd	446
	dd	6
	align	4
_1305:
	dd	3
	dd	0
	dd	0
	align	4
_1298:
	dd	_584
	dd	444
	dd	7
	align	4
_1301:
	dd	_584
	dd	445
	dd	7
	align	4
_1304:
	dd	3
	dd	0
	dd	0
	align	4
_1303:
	dd	_584
	dd	445
	dd	27
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
_1306:
	dd	_584
	dd	447
	dd	6
	align	4
_1307:
	dd	_584
	dd	451
	dd	6
	align	4
_1315:
	dd	3
	dd	0
	dd	0
	align	4
_1308:
	dd	_584
	dd	449
	dd	7
	align	4
_1311:
	dd	_584
	dd	450
	dd	7
	align	4
_1314:
	dd	3
	dd	0
	dd	0
	align	4
_1313:
	dd	_584
	dd	450
	dd	27
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
_1316:
	dd	_584
	dd	453
	dd	3
	align	4
_1322:
	dd	_584
	dd	454
	dd	3
	align	4
_1328:
	dd	_584
	dd	457
	dd	6
	align	4
_1384:
	dd	3
	dd	0
	dd	0
	align	4
_1338:
	dd	_584
	dd	458
	dd	7
	align	4
_1360:
	dd	3
	dd	0
	dd	0
	align	4
_1342:
	dd	_584
	dd	459
	dd	8
	align	4
_1347:
	dd	_584
	dd	460
	dd	8
	align	4
_1359:
	dd	_584
	dd	461
	dd	8
	align	4
_1361:
	dd	_584
	dd	463
	dd	7
	align	4
_1383:
	dd	3
	dd	0
	dd	0
	align	4
_1365:
	dd	_584
	dd	464
	dd	8
	align	4
_1370:
	dd	_584
	dd	465
	dd	8
	align	4
_1382:
	dd	_584
	dd	466
	dd	8
	align	4
_1385:
	dd	_584
	dd	471
	dd	3
	align	4
_1394:
	dd	3
	dd	0
	dd	0
	align	4
_1389:
	dd	_584
	dd	471
	dd	31
	align	4
_1395:
	dd	_584
	dd	472
	dd	3
	align	4
_1404:
	dd	3
	dd	0
	dd	0
	align	4
_1399:
	dd	_584
	dd	472
	dd	31
	align	4
_1405:
	dd	_584
	dd	474
	dd	6
_1440:
	db	"tempLevel",0
_1441:
	db	"tempParent",0
	align	4
_1439:
	dd	3
	dd	0
	dd	2
	dd	_1440
	dd	_296
	dd	-24
	dd	2
	dd	_1441
	dd	_273
	dd	-28
	dd	0
	align	4
_1411:
	dd	_584
	dd	475
	dd	4
	align	4
_1415:
	dd	_584
	dd	476
	dd	4
	align	4
_1419:
	dd	_584
	dd	478
	dd	4
	align	4
_1425:
	dd	_584
	dd	479
	dd	4
	align	4
_1431:
	dd	_584
	dd	480
	dd	4
	align	4
_1435:
	dd	_584
	dd	481
	dd	4
	align	4
_1442:
	dd	_584
	dd	485
	dd	3
	align	4
_1471:
	dd	3
	dd	0
	dd	0
	align	4
_1446:
	dd	_584
	dd	486
	dd	4
	align	4
_1458:
	dd	3
	dd	0
	dd	0
	align	4
_1448:
	dd	_584
	dd	487
	dd	5
	align	4
_1470:
	dd	3
	dd	0
	dd	0
	align	4
_1460:
	dd	_584
	dd	489
	dd	5
	align	4
_1472:
	dd	_584
	dd	492
	dd	3
	align	4
_1501:
	dd	3
	dd	0
	dd	0
	align	4
_1476:
	dd	_584
	dd	493
	dd	4
	align	4
_1488:
	dd	3
	dd	0
	dd	0
	align	4
_1478:
	dd	_584
	dd	494
	dd	5
	align	4
_1500:
	dd	3
	dd	0
	dd	0
	align	4
_1490:
	dd	_584
	dd	496
	dd	5
	align	4
_1502:
	dd	_584
	dd	500
	dd	3
	align	4
_1505:
	dd	_584
	dd	501
	dd	3
_1525:
	db	"Indx",0
	align	4
_1524:
	dd	1
	dd	_314
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_1525
	dd	_296
	dd	-8
	dd	2
	dd	_1079
	dd	_301
	dd	-12
	dd	0
	align	4
_1511:
	dd	_584
	dd	511
	dd	3
	align	4
_1513:
	dd	_584
	dd	512
	dd	3
	align	4
_1517:
	dd	_584
	dd	517
	dd	3
	align	4
_1522:
	dd	3
	dd	0
	dd	0
	align	4
_1518:
	dd	_584
	dd	515
	dd	4
	align	4
_1521:
	dd	_584
	dd	516
	dd	4
	align	4
_1523:
	dd	_584
	dd	519
	dd	3
_1571:
	db	"Index",0
	align	4
_1570:
	dd	1
	dd	_315
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_1571
	dd	_296
	dd	-8
	dd	2
	dd	_296
	dd	_296
	dd	-12
	dd	2
	dd	_1079
	dd	_301
	dd	-16
	dd	0
	align	4
_1526:
	dd	_584
	dd	529
	dd	3
	align	4
_1531:
	dd	3
	dd	0
	dd	0
	align	4
_1530:
	dd	_584
	dd	529
	dd	25
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
_1532:
	dd	_584
	dd	530
	dd	3
	align	4
_1535:
	dd	3
	dd	0
	dd	0
	align	4
_1534:
	dd	_584
	dd	530
	dd	21
	align	4
_47:
	dd	bbStringClass
	dd	2147483647
	dd	32
	dw	41,58,32,73,110,100,101,120,32,109,97,121,32,110,111,116
	dw	32,98,101,32,108,101,115,115,32,116,104,97,110,32,49,46
	align	4
_1536:
	dd	_584
	dd	532
	dd	3
	align	4
_1538:
	dd	_584
	dd	533
	dd	3
	align	4
_1546:
	dd	_584
	dd	535
	dd	3
	align	4
_1554:
	dd	3
	dd	0
	dd	0
	align	4
_1549:
	dd	_584
	dd	536
	dd	4
	align	4
_1552:
	dd	_584
	dd	537
	dd	4
	align	4
_51:
	dd	bbStringClass
	dd	2147483647
	dd	22
	dw	41,58,32,73,110,100,101,120,32,111,117,116,32,111,102,32
	dw	114,97,110,103,101,46
	align	4
_1555:
	dd	_584
	dd	540
	dd	3
	align	4
_1560:
	dd	_584
	dd	541
	dd	3
	align	4
_1581:
	dd	1
	dd	_317
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_1572:
	dd	_584
	dd	551
	dd	3
	align	4
_1577:
	dd	3
	dd	0
	dd	0
	align	4
_1576:
	dd	_584
	dd	551
	dd	25
	align	4
_1580:
	dd	3
	dd	0
	dd	0
	align	4
_1579:
	dd	_584
	dd	551
	dd	42
	align	4
_1626:
	dd	1
	dd	_318
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_1582:
	dd	_584
	dd	562
	dd	3
	align	4
_1594:
	dd	3
	dd	0
	dd	0
	align	4
_1587:
	dd	_584
	dd	563
	dd	4
	align	4
_1595:
	dd	_584
	dd	566
	dd	3
	align	4
_1607:
	dd	3
	dd	0
	dd	0
	align	4
_1600:
	dd	_584
	dd	567
	dd	4
	align	4
_1608:
	dd	_584
	dd	570
	dd	3
	align	4
_1617:
	dd	3
	dd	0
	dd	0
	align	4
_1612:
	dd	_584
	dd	570
	dd	31
	align	4
_1618:
	dd	_584
	dd	571
	dd	3
	align	4
_1622:
	dd	_584
	dd	572
	dd	3
	align	4
_1638:
	dd	1
	dd	_319
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_1627:
	dd	_584
	dd	588
	dd	3
	align	4
_1634:
	dd	3
	dd	0
	dd	0
	align	4
_1633:
	dd	_584
	dd	588
	dd	31
	align	4
_1637:
	dd	3
	dd	0
	dd	0
	align	4
_1636:
	dd	_584
	dd	588
	dd	49
	align	4
_1654:
	dd	1
	dd	_320
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_1639:
	dd	_584
	dd	597
	dd	3
	align	4
_1646:
	dd	3
	dd	0
	dd	0
	align	4
_1645:
	dd	_584
	dd	597
	dd	31
	align	4
_1653:
	dd	3
	dd	0
	dd	0
	align	4
_1648:
	dd	_584
	dd	597
	dd	48
	align	4
_1670:
	dd	1
	dd	_321
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_1655:
	dd	_584
	dd	606
	dd	3
	align	4
_1662:
	dd	3
	dd	0
	dd	0
	align	4
_1661:
	dd	_584
	dd	606
	dd	31
	align	4
_1669:
	dd	3
	dd	0
	dd	0
	align	4
_1664:
	dd	_584
	dd	606
	dd	48
	align	4
_1695:
	dd	1
	dd	_322
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_1571
	dd	_296
	dd	-8
	dd	2
	dd	_296
	dd	_296
	dd	-12
	dd	2
	dd	_1079
	dd	_301
	dd	-16
	dd	0
	align	4
_1671:
	dd	_584
	dd	616
	dd	3
	align	4
_1674:
	dd	3
	dd	0
	dd	0
	align	4
_1673:
	dd	_584
	dd	616
	dd	21
	align	4
_1675:
	dd	_584
	dd	618
	dd	3
	align	4
_1677:
	dd	_584
	dd	619
	dd	3
	align	4
_1683:
	dd	_584
	dd	621
	dd	3
	align	4
_1691:
	dd	3
	dd	0
	dd	0
	align	4
_1686:
	dd	_584
	dd	622
	dd	4
	align	4
_1689:
	dd	_584
	dd	623
	dd	4
	align	4
_61:
	dd	bbStringClass
	dd	2147483647
	dd	17
	dw	120,109,108,78,111,100,101,46,71,101,116,67,104,105,108,100
	dw	40
	align	4
_1692:
	dd	_584
	dd	626
	dd	3
	align	4
_1701:
	dd	1
	dd	_324
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_1696:
	dd	_584
	dd	636
	dd	3
_1786:
	db	"Recurse",0
_1787:
	db	"MatchCase",0
	align	4
_1785:
	dd	1
	dd	_325
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_291
	dd	_292
	dd	-8
	dd	2
	dd	_1786
	dd	_296
	dd	-12
	dd	2
	dd	_1787
	dd	_296
	dd	-16
	dd	2
	dd	_354
	dd	_273
	dd	-20
	dd	2
	dd	_1079
	dd	_273
	dd	-24
	dd	0
	align	4
_1702:
	dd	_584
	dd	649
	dd	3
	align	4
_1705:
	dd	_584
	dd	651
	dd	3
	align	4
_1712:
	dd	3
	dd	0
	dd	0
	align	4
_1711:
	dd	_584
	dd	651
	dd	31
	align	4
_1713:
	dd	_584
	dd	653
	dd	3
	align	4
_1733:
	dd	3
	dd	0
	dd	0
	align	4
_1715:
	dd	_584
	dd	654
	dd	4
	align	4
_1732:
	dd	3
	dd	0
	dd	0
	align	4
_1726:
	dd	_584
	dd	655
	dd	5
	align	4
_1731:
	dd	3
	dd	0
	dd	0
	align	4
_1730:
	dd	_584
	dd	655
	dd	30
	align	4
_1754:
	dd	3
	dd	0
	dd	0
	align	4
_1735:
	dd	_584
	dd	658
	dd	4
	align	4
_1736:
	dd	_584
	dd	659
	dd	4
	align	4
_1753:
	dd	3
	dd	0
	dd	0
	align	4
_1747:
	dd	_584
	dd	660
	dd	5
	align	4
_1752:
	dd	3
	dd	0
	dd	0
	align	4
_1751:
	dd	_584
	dd	660
	dd	40
	align	4
_1755:
	dd	_584
	dd	664
	dd	3
	align	4
_1783:
	dd	3
	dd	0
	dd	0
	align	4
_1757:
	dd	_584
	dd	665
	dd	4
	align	4
_1782:
	dd	3
	dd	0
	dd	0
	align	4
_1768:
	dd	_584
	dd	666
	dd	5
	align	4
_1781:
	dd	3
	dd	0
	dd	0
	align	4
_1774:
	dd	_584
	dd	667
	dd	6
	align	4
_1777:
	dd	_584
	dd	668
	dd	6
	align	4
_1780:
	dd	3
	dd	0
	dd	0
	align	4
_1779:
	dd	_584
	dd	668
	dd	27
	align	4
_1784:
	dd	_584
	dd	673
	dd	3
_1895:
	db	"AttrName",0
_1896:
	db	"AttrValue",0
_1897:
	db	"Attr",0
	align	4
_1894:
	dd	1
	dd	_327
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_291
	dd	_292
	dd	-8
	dd	2
	dd	_1895
	dd	_292
	dd	-12
	dd	2
	dd	_1896
	dd	_292
	dd	-16
	dd	2
	dd	_1786
	dd	_296
	dd	-20
	dd	2
	dd	_1787
	dd	_296
	dd	-24
	dd	2
	dd	_354
	dd	_273
	dd	-28
	dd	2
	dd	_1897
	dd	_1288
	dd	-32
	dd	2
	dd	_1079
	dd	_273
	dd	-36
	dd	0
	align	4
_1788:
	dd	_584
	dd	684
	dd	3
	align	4
_1792:
	dd	_584
	dd	686
	dd	3
	align	4
_1799:
	dd	3
	dd	0
	dd	0
	align	4
_1798:
	dd	_584
	dd	686
	dd	31
	align	4
_1800:
	dd	_584
	dd	688
	dd	3
	align	4
_1831:
	dd	3
	dd	0
	dd	0
	align	4
_1802:
	dd	_584
	dd	689
	dd	4
	align	4
_1830:
	dd	3
	dd	0
	dd	0
	align	4
_1813:
	dd	_584
	dd	690
	dd	5
	align	4
_1829:
	dd	3
	dd	0
	dd	0
	align	4
_1817:
	dd	_584
	dd	691
	dd	6
	align	4
_1820:
	dd	_584
	dd	692
	dd	6
	align	4
_1828:
	dd	3
	dd	0
	dd	0
	align	4
_1822:
	dd	_584
	dd	692
	dd	27
	align	4
_1827:
	dd	3
	dd	0
	dd	0
	align	4
_1826:
	dd	_584
	dd	692
	dd	58
	align	4
_1863:
	dd	3
	dd	0
	dd	0
	align	4
_1833:
	dd	_584
	dd	696
	dd	4
	align	4
_1834:
	dd	_584
	dd	697
	dd	4
	align	4
_1862:
	dd	3
	dd	0
	dd	0
	align	4
_1845:
	dd	_584
	dd	698
	dd	5
	align	4
_1861:
	dd	3
	dd	0
	dd	0
	align	4
_1849:
	dd	_584
	dd	699
	dd	6
	align	4
_1852:
	dd	_584
	dd	700
	dd	6
	align	4
_1860:
	dd	3
	dd	0
	dd	0
	align	4
_1854:
	dd	_584
	dd	700
	dd	27
	align	4
_1859:
	dd	3
	dd	0
	dd	0
	align	4
_1858:
	dd	_584
	dd	700
	dd	78
	align	4
_1864:
	dd	_584
	dd	705
	dd	3
	align	4
_1892:
	dd	3
	dd	0
	dd	0
	align	4
_1866:
	dd	_584
	dd	706
	dd	4
	align	4
_1891:
	dd	3
	dd	0
	dd	0
	align	4
_1877:
	dd	_584
	dd	707
	dd	5
	align	4
_1890:
	dd	3
	dd	0
	dd	0
	align	4
_1883:
	dd	_584
	dd	708
	dd	6
	align	4
_1886:
	dd	_584
	dd	709
	dd	6
	align	4
_1889:
	dd	3
	dd	0
	dd	0
	align	4
_1888:
	dd	_584
	dd	709
	dd	27
	align	4
_1893:
	dd	_584
	dd	714
	dd	3
_2121:
	db	"Mode",0
_2122:
	db	"Ascending",0
_2123:
	db	"term",0
	align	4
_2120:
	dd	1
	dd	_329
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_2121
	dd	_296
	dd	-8
	dd	2
	dd	_1786
	dd	_296
	dd	-12
	dd	2
	dd	_2122
	dd	_296
	dd	-16
	dd	2
	dd	_2123
	dd	_301
	dd	-20
	dd	2
	dd	_354
	dd	_273
	dd	-24
	dd	0
	align	4
_1898:
	dd	_584
	dd	725
	dd	3
	align	4
_1904:
	dd	_584
	dd	784
	dd	3
_2098:
	db	"link",0
_2099:
	db	"sorted",0
	align	4
_2097:
	dd	3
	dd	0
	dd	2
	dd	_2098
	dd	_301
	dd	-28
	dd	2
	dd	_2099
	dd	_296
	dd	-32
	dd	0
	align	4
_1905:
	dd	_584
	dd	727
	dd	4
	align	4
_1913:
	dd	_584
	dd	728
	dd	4
	align	4
_1915:
	dd	_584
	dd	781
	dd	4
_2089:
	db	"succ",0
_2090:
	db	"a",0
_2091:
	db	"node",0
	align	4
_2088:
	dd	3
	dd	0
	dd	2
	dd	_2089
	dd	_301
	dd	-36
	dd	2
	dd	_2090
	dd	_292
	dd	-40
	dd	2
	dd	_693
	dd	_292
	dd	-44
	dd	2
	dd	_1287
	dd	_1288
	dd	-48
	dd	2
	dd	_2091
	dd	_273
	dd	-52
	dd	0
	align	4
_1916:
	dd	_584
	dd	730
	dd	5
	align	4
_1920:
	dd	_584
	dd	731
	dd	5
	align	4
_1923:
	dd	3
	dd	0
	dd	0
	align	4
_1922:
	dd	_584
	dd	731
	dd	18
	align	4
_1924:
	dd	_584
	dd	732
	dd	5
	align	4
_1927:
	dd	_584
	dd	733
	dd	5
	align	4
_1930:
	dd	_584
	dd	734
	dd	5
	align	4
_1947:
	dd	3
	dd	0
	dd	0
	align	4
_1937:
	dd	_584
	dd	736
	dd	7
	align	4
_1942:
	dd	_584
	dd	737
	dd	7
	align	4
_1958:
	dd	3
	dd	0
	dd	0
	align	4
_1948:
	dd	_584
	dd	739
	dd	7
	align	4
_1953:
	dd	_584
	dd	740
	dd	7
	align	4
_1999:
	dd	3
	dd	0
	dd	0
	align	4
_1959:
	dd	_584
	dd	742
	dd	7
	align	4
_1960:
	dd	_584
	dd	743
	dd	7
	align	4
_1963:
	dd	_584
	dd	744
	dd	7
	align	4
_1977:
	dd	3
	dd	0
	dd	0
	align	4
_1974:
	dd	_584
	dd	745
	dd	8
	align	4
_1978:
	dd	_584
	dd	747
	dd	7
	align	4
_1979:
	dd	_584
	dd	748
	dd	7
	align	4
_1980:
	dd	_584
	dd	749
	dd	7
	align	4
_1983:
	dd	_584
	dd	750
	dd	7
	align	4
_1997:
	dd	3
	dd	0
	dd	0
	align	4
_1994:
	dd	_584
	dd	751
	dd	8
	align	4
_1998:
	dd	_584
	dd	753
	dd	7
	align	4
_2040:
	dd	3
	dd	0
	dd	0
	align	4
_2000:
	dd	_584
	dd	755
	dd	7
	align	4
_2001:
	dd	_584
	dd	756
	dd	7
	align	4
_2004:
	dd	_584
	dd	757
	dd	7
	align	4
_2018:
	dd	3
	dd	0
	dd	0
	align	4
_2015:
	dd	_584
	dd	758
	dd	8
	align	4
_2019:
	dd	_584
	dd	760
	dd	7
	align	4
_2020:
	dd	_584
	dd	761
	dd	7
	align	4
_2021:
	dd	_584
	dd	762
	dd	7
	align	4
_2024:
	dd	_584
	dd	763
	dd	7
	align	4
_2038:
	dd	3
	dd	0
	dd	0
	align	4
_2035:
	dd	_584
	dd	764
	dd	8
	align	4
_2039:
	dd	_584
	dd	766
	dd	7
	align	4
_2041:
	dd	_584
	dd	768
	dd	5
_2083:
	db	"link_pred",0
_2084:
	db	"succ_succ",0
	align	4
_2082:
	dd	3
	dd	0
	dd	2
	dd	_2083
	dd	_301
	dd	-56
	dd	2
	dd	_2084
	dd	_301
	dd	-60
	dd	0
	align	4
_2049:
	dd	_584
	dd	769
	dd	6
	align	4
_2053:
	dd	_584
	dd	770
	dd	6
	align	4
_2057:
	dd	_584
	dd	771
	dd	6
	align	4
_2061:
	dd	_584
	dd	772
	dd	6
	align	4
_2065:
	dd	_584
	dd	773
	dd	6
	align	4
_2069:
	dd	_584
	dd	774
	dd	6
	align	4
_2073:
	dd	_584
	dd	775
	dd	6
	align	4
_2077:
	dd	_584
	dd	776
	dd	6
	align	4
_2081:
	dd	_584
	dd	777
	dd	6
	align	4
_2087:
	dd	3
	dd	0
	dd	0
	align	4
_2086:
	dd	_584
	dd	779
	dd	6
	align	4
_2092:
	dd	_584
	dd	782
	dd	4
	align	4
_2095:
	dd	3
	dd	0
	dd	0
	align	4
_2094:
	dd	_584
	dd	782
	dd	14
	align	4
_2096:
	dd	_584
	dd	783
	dd	4
_2446:
	db	"PrimaryMode",0
_2447:
	db	"SecondaryMode",0
	align	4
_2445:
	dd	1
	dd	_331
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_2446
	dd	_296
	dd	-8
	dd	2
	dd	_2447
	dd	_296
	dd	-12
	dd	2
	dd	_1786
	dd	_296
	dd	-16
	dd	2
	dd	_2122
	dd	_296
	dd	-20
	dd	2
	dd	_2123
	dd	_301
	dd	-24
	dd	2
	dd	_354
	dd	_273
	dd	-28
	dd	0
	align	4
_2124:
	dd	_584
	dd	804
	dd	3
	align	4
_2130:
	dd	_584
	dd	895
	dd	3
	align	4
_2424:
	dd	3
	dd	0
	dd	2
	dd	_2098
	dd	_301
	dd	-32
	dd	2
	dd	_2099
	dd	_296
	dd	-36
	dd	0
	align	4
_2131:
	dd	_584
	dd	806
	dd	4
	align	4
_2139:
	dd	_584
	dd	807
	dd	4
	align	4
_2141:
	dd	_584
	dd	892
	dd	4
_2418:
	db	"NODE",0
	align	4
_2417:
	dd	3
	dd	0
	dd	2
	dd	_2089
	dd	_301
	dd	-40
	dd	2
	dd	_2090
	dd	_292
	dd	-44
	dd	2
	dd	_693
	dd	_292
	dd	-48
	dd	2
	dd	_1287
	dd	_1288
	dd	-52
	dd	2
	dd	_2418
	dd	_273
	dd	-56
	dd	0
	align	4
_2142:
	dd	_584
	dd	809
	dd	5
	align	4
_2146:
	dd	_584
	dd	810
	dd	5
	align	4
_2149:
	dd	3
	dd	0
	dd	0
	align	4
_2148:
	dd	_584
	dd	810
	dd	18
	align	4
_2150:
	dd	_584
	dd	811
	dd	5
	align	4
_2153:
	dd	_584
	dd	812
	dd	5
	align	4
_2156:
	dd	_584
	dd	814
	dd	5
	align	4
_2157:
	dd	_584
	dd	815
	dd	5
	align	4
_2158:
	dd	_584
	dd	817
	dd	5
	align	4
_2175:
	dd	3
	dd	0
	dd	0
	align	4
_2165:
	dd	_584
	dd	819
	dd	7
	align	4
_2170:
	dd	_584
	dd	820
	dd	7
	align	4
_2186:
	dd	3
	dd	0
	dd	0
	align	4
_2176:
	dd	_584
	dd	822
	dd	7
	align	4
_2181:
	dd	_584
	dd	823
	dd	7
	align	4
_2225:
	dd	3
	dd	0
	dd	0
	align	4
_2187:
	dd	_584
	dd	825
	dd	7
	align	4
_2190:
	dd	_584
	dd	826
	dd	7
	align	4
_2204:
	dd	3
	dd	0
	dd	0
	align	4
_2201:
	dd	_584
	dd	827
	dd	8
	align	4
_2205:
	dd	_584
	dd	829
	dd	7
	align	4
_2206:
	dd	_584
	dd	830
	dd	7
	align	4
_2209:
	dd	_584
	dd	831
	dd	7
	align	4
_2223:
	dd	3
	dd	0
	dd	0
	align	4
_2220:
	dd	_584
	dd	832
	dd	8
	align	4
_2224:
	dd	_584
	dd	834
	dd	7
	align	4
_2264:
	dd	3
	dd	0
	dd	0
	align	4
_2226:
	dd	_584
	dd	836
	dd	7
	align	4
_2229:
	dd	_584
	dd	837
	dd	7
	align	4
_2243:
	dd	3
	dd	0
	dd	0
	align	4
_2240:
	dd	_584
	dd	838
	dd	8
	align	4
_2244:
	dd	_584
	dd	840
	dd	7
	align	4
_2245:
	dd	_584
	dd	841
	dd	7
	align	4
_2248:
	dd	_584
	dd	842
	dd	7
	align	4
_2262:
	dd	3
	dd	0
	dd	0
	align	4
_2259:
	dd	_584
	dd	843
	dd	8
	align	4
_2263:
	dd	_584
	dd	845
	dd	7
	align	4
_2265:
	dd	_584
	dd	848
	dd	5
	align	4
_2282:
	dd	3
	dd	0
	dd	0
	align	4
_2272:
	dd	_584
	dd	850
	dd	7
	align	4
_2277:
	dd	_584
	dd	851
	dd	7
	align	4
_2293:
	dd	3
	dd	0
	dd	0
	align	4
_2283:
	dd	_584
	dd	853
	dd	7
	align	4
_2288:
	dd	_584
	dd	854
	dd	7
	align	4
_2332:
	dd	3
	dd	0
	dd	0
	align	4
_2294:
	dd	_584
	dd	856
	dd	7
	align	4
_2297:
	dd	_584
	dd	857
	dd	7
	align	4
_2311:
	dd	3
	dd	0
	dd	0
	align	4
_2308:
	dd	_584
	dd	858
	dd	8
	align	4
_2312:
	dd	_584
	dd	860
	dd	7
	align	4
_2313:
	dd	_584
	dd	861
	dd	7
	align	4
_2316:
	dd	_584
	dd	862
	dd	7
	align	4
_2330:
	dd	3
	dd	0
	dd	0
	align	4
_2327:
	dd	_584
	dd	863
	dd	8
	align	4
_2331:
	dd	_584
	dd	865
	dd	7
	align	4
_2371:
	dd	3
	dd	0
	dd	0
	align	4
_2333:
	dd	_584
	dd	867
	dd	7
	align	4
_2336:
	dd	_584
	dd	868
	dd	7
	align	4
_2350:
	dd	3
	dd	0
	dd	0
	align	4
_2347:
	dd	_584
	dd	869
	dd	8
	align	4
_2351:
	dd	_584
	dd	871
	dd	7
	align	4
_2352:
	dd	_584
	dd	872
	dd	7
	align	4
_2355:
	dd	_584
	dd	873
	dd	7
	align	4
_2369:
	dd	3
	dd	0
	dd	0
	align	4
_2366:
	dd	_584
	dd	874
	dd	8
	align	4
_2370:
	dd	_584
	dd	876
	dd	7
	align	4
_2372:
	dd	_584
	dd	879
	dd	5
	align	4
_2413:
	dd	3
	dd	0
	dd	2
	dd	_2083
	dd	_301
	dd	-60
	dd	2
	dd	_2084
	dd	_301
	dd	-64
	dd	0
	align	4
_2380:
	dd	_584
	dd	880
	dd	6
	align	4
_2384:
	dd	_584
	dd	881
	dd	6
	align	4
_2388:
	dd	_584
	dd	882
	dd	6
	align	4
_2392:
	dd	_584
	dd	883
	dd	6
	align	4
_2396:
	dd	_584
	dd	884
	dd	6
	align	4
_2400:
	dd	_584
	dd	885
	dd	6
	align	4
_2404:
	dd	_584
	dd	886
	dd	6
	align	4
_2408:
	dd	_584
	dd	887
	dd	6
	align	4
_2412:
	dd	_584
	dd	888
	dd	6
	align	4
_2416:
	dd	3
	dd	0
	dd	0
	align	4
_2415:
	dd	_584
	dd	890
	dd	6
	align	4
_2419:
	dd	_584
	dd	893
	dd	4
	align	4
_2422:
	dd	3
	dd	0
	dd	0
	align	4
_2421:
	dd	_584
	dd	893
	dd	14
	align	4
_2423:
	dd	_584
	dd	894
	dd	4
	align	4
_2481:
	dd	1
	dd	_333
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_1078
	dd	_273
	dd	-8
	dd	2
	dd	_986
	dd	_296
	dd	-12
	dd	0
	align	4
_2448:
	dd	_584
	dd	913
	dd	3
	align	4
_2466:
	dd	3
	dd	0
	dd	0
	align	4
_2453:
	dd	_584
	dd	915
	dd	5
	align	4
_2465:
	dd	3
	dd	0
	dd	0
	align	4
_2458:
	dd	_584
	dd	916
	dd	6
	align	4
_2480:
	dd	3
	dd	0
	dd	0
	align	4
_2467:
	dd	_584
	dd	919
	dd	5
	align	4
_2479:
	dd	3
	dd	0
	dd	0
	align	4
_2472:
	dd	_584
	dd	920
	dd	6
	align	4
_2515:
	dd	1
	dd	_334
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_354
	dd	_273
	dd	-8
	dd	2
	dd	_986
	dd	_296
	dd	-12
	dd	0
	align	4
_2482:
	dd	_584
	dd	933
	dd	3
	align	4
_2500:
	dd	3
	dd	0
	dd	0
	align	4
_2487:
	dd	_584
	dd	935
	dd	5
	align	4
_2499:
	dd	3
	dd	0
	dd	0
	align	4
_2492:
	dd	_584
	dd	936
	dd	6
	align	4
_2514:
	dd	3
	dd	0
	dd	0
	align	4
_2501:
	dd	_584
	dd	939
	dd	5
	align	4
_2513:
	dd	3
	dd	0
	dd	0
	align	4
_2506:
	dd	_584
	dd	940
	dd	6
	align	4
_2529:
	dd	1
	dd	_335
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_2516:
	dd	_584
	dd	953
	dd	3
	align	4
_2528:
	dd	3
	dd	0
	dd	0
	align	4
_2521:
	dd	_584
	dd	954
	dd	4
_2553:
	db	"lnk",0
	align	4
_2552:
	dd	1
	dd	_336
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_2553
	dd	_301
	dd	-8
	dd	0
	align	4
_2530:
	dd	_584
	dd	973
	dd	3
	align	4
_2535:
	dd	3
	dd	0
	dd	0
	align	4
_2534:
	dd	_584
	dd	973
	dd	25
	align	4
_2536:
	dd	_584
	dd	975
	dd	3
	align	4
_2538:
	dd	_584
	dd	976
	dd	3
	align	4
_2543:
	dd	_584
	dd	977
	dd	3
	align	4
_2546:
	dd	3
	dd	0
	dd	0
	align	4
_2545:
	dd	_584
	dd	977
	dd	22
	align	4
_2551:
	dd	3
	dd	0
	dd	0
	align	4
_2548:
	dd	_584
	dd	977
	dd	39
	align	4
_2576:
	dd	1
	dd	_337
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_2553
	dd	_301
	dd	-8
	dd	0
	align	4
_2554:
	dd	_584
	dd	987
	dd	3
	align	4
_2559:
	dd	3
	dd	0
	dd	0
	align	4
_2558:
	dd	_584
	dd	987
	dd	25
	align	4
_2560:
	dd	_584
	dd	989
	dd	3
	align	4
_2562:
	dd	_584
	dd	990
	dd	3
	align	4
_2567:
	dd	_584
	dd	991
	dd	3
	align	4
_2570:
	dd	3
	dd	0
	dd	0
	align	4
_2569:
	dd	_584
	dd	991
	dd	22
	align	4
_2575:
	dd	3
	dd	0
	dd	0
	align	4
_2572:
	dd	_584
	dd	991
	dd	39
	align	4
_2590:
	dd	1
	dd	_338
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_2577:
	dd	_584
	dd	1001
	dd	3
	align	4
_2582:
	dd	3
	dd	0
	dd	0
	align	4
_2581:
	dd	_584
	dd	1001
	dd	25
	align	4
_2583:
	dd	_584
	dd	1002
	dd	3
	align	4
_2604:
	dd	1
	dd	_339
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_2591:
	dd	_584
	dd	1012
	dd	3
	align	4
_2596:
	dd	3
	dd	0
	dd	0
	align	4
_2595:
	dd	_584
	dd	1012
	dd	25
	align	4
_2597:
	dd	_584
	dd	1013
	dd	3
	align	4
_2637:
	dd	1
	dd	_340
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_1571
	dd	_296
	dd	-8
	dd	2
	dd	_296
	dd	_296
	dd	-12
	dd	2
	dd	_1079
	dd	_301
	dd	-16
	dd	0
	align	4
_2605:
	dd	_584
	dd	1023
	dd	3
	align	4
_2614:
	dd	3
	dd	0
	dd	0
	align	4
_2609:
	dd	_584
	dd	1024
	dd	4
	align	4
_2612:
	dd	3
	dd	0
	dd	0
	align	4
_2611:
	dd	_584
	dd	1024
	dd	22
	align	4
_2613:
	dd	_584
	dd	1025
	dd	4
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
_2615:
	dd	_584
	dd	1028
	dd	3
	align	4
_2617:
	dd	_584
	dd	1029
	dd	3
	align	4
_2625:
	dd	_584
	dd	1031
	dd	3
	align	4
_2633:
	dd	3
	dd	0
	dd	0
	align	4
_2628:
	dd	_584
	dd	1032
	dd	4
	align	4
_2631:
	dd	_584
	dd	1033
	dd	4
	align	4
_2634:
	dd	_584
	dd	1036
	dd	3
	align	4
_2651:
	dd	1
	dd	_341
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_2638:
	dd	_584
	dd	1047
	dd	3
	align	4
_2643:
	dd	3
	dd	0
	dd	0
	align	4
_2642:
	dd	_584
	dd	1047
	dd	25
	align	4
_2644:
	dd	_584
	dd	1048
	dd	3
	align	4
_2670:
	dd	1
	dd	_342
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_291
	dd	_292
	dd	-8
	dd	2
	dd	_1787
	dd	_296
	dd	-12
	dd	0
	align	4
_2652:
	dd	_584
	dd	1059
	dd	3
	align	4
_2664:
	dd	3
	dd	0
	dd	0
	align	4
_2656:
	dd	_584
	dd	1060
	dd	4
	align	4
_2659:
	dd	3
	dd	0
	dd	0
	align	4
_2658:
	dd	_584
	dd	1060
	dd	29
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
_2660:
	dd	_584
	dd	1061
	dd	4
	align	4
_2663:
	dd	3
	dd	0
	dd	0
	align	4
_2662:
	dd	_584
	dd	1061
	dd	30
	align	4
_156:
	dd	bbStringClass
	dd	2147483647
	dd	41
	dw	34,44,32,70,97,108,115,101,41,58,32,84,104,101,32,114
	dw	111,111,116,32,110,111,100,101,32,104,97,115,32,110,111,32
	dw	115,105,98,108,105,110,103,115,46
	align	4
_2665:
	dd	_584
	dd	1064
	dd	3
	align	4
_2715:
	dd	1
	dd	_343
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_291
	dd	_292
	dd	-8
	dd	2
	dd	_1787
	dd	_296
	dd	-12
	dd	2
	dd	_1287
	dd	_1288
	dd	-16
	dd	0
	align	4
_2671:
	dd	_584
	dd	1078
	dd	3
	align	4
_2673:
	dd	_584
	dd	1080
	dd	3
	align	4
_2693:
	dd	3
	dd	0
	dd	0
	align	4
_2675:
	dd	_584
	dd	1081
	dd	4
	align	4
_2692:
	dd	3
	dd	0
	dd	0
	align	4
_2686:
	dd	_584
	dd	1082
	dd	5
	align	4
_2691:
	dd	3
	dd	0
	dd	0
	align	4
_2690:
	dd	_584
	dd	1082
	dd	30
	align	4
_2714:
	dd	3
	dd	0
	dd	0
	align	4
_2695:
	dd	_584
	dd	1085
	dd	4
	align	4
_2696:
	dd	_584
	dd	1086
	dd	4
	align	4
_2713:
	dd	3
	dd	0
	dd	0
	align	4
_2707:
	dd	_584
	dd	1087
	dd	5
	align	4
_2712:
	dd	3
	dd	0
	dd	0
	align	4
_2711:
	dd	_584
	dd	1087
	dd	40
	align	4
_2727:
	dd	1
	dd	_345
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_2716:
	dd	_584
	dd	1098
	dd	3
	align	4
_2723:
	dd	3
	dd	0
	dd	0
	align	4
_2722:
	dd	_584
	dd	1098
	dd	35
	align	4
_2726:
	dd	3
	dd	0
	dd	0
	align	4
_2725:
	dd	_584
	dd	1098
	dd	53
	align	4
_2743:
	dd	1
	dd	_346
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_2728:
	dd	_584
	dd	1107
	dd	3
	align	4
_2735:
	dd	3
	dd	0
	dd	0
	align	4
_2734:
	dd	_584
	dd	1107
	dd	35
	align	4
_2742:
	dd	3
	dd	0
	dd	0
	align	4
_2737:
	dd	_584
	dd	1107
	dd	52
	align	4
_2759:
	dd	1
	dd	_347
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	0
	align	4
_2744:
	dd	_584
	dd	1116
	dd	3
	align	4
_2751:
	dd	3
	dd	0
	dd	0
	align	4
_2750:
	dd	_584
	dd	1116
	dd	35
	align	4
_2758:
	dd	3
	dd	0
	dd	0
	align	4
_2753:
	dd	_584
	dd	1116
	dd	52
	align	4
_2826:
	dd	1
	dd	_348
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_291
	dd	_292
	dd	-8
	dd	2
	dd	_1787
	dd	_296
	dd	-12
	dd	2
	dd	_1287
	dd	_1288
	dd	-16
	dd	0
	align	4
_2760:
	dd	_584
	dd	1127
	dd	3
	align	4
_2762:
	dd	_584
	dd	1130
	dd	3
	align	4
_2782:
	dd	3
	dd	0
	dd	0
	align	4
_2764:
	dd	_584
	dd	1131
	dd	4
	align	4
_2781:
	dd	3
	dd	0
	dd	0
	align	4
_2775:
	dd	_584
	dd	1132
	dd	5
	align	4
_2780:
	dd	3
	dd	0
	dd	0
	align	4
_2779:
	dd	_584
	dd	1132
	dd	30
	align	4
_2803:
	dd	3
	dd	0
	dd	0
	align	4
_2784:
	dd	_584
	dd	1135
	dd	4
	align	4
_2785:
	dd	_584
	dd	1136
	dd	4
	align	4
_2802:
	dd	3
	dd	0
	dd	0
	align	4
_2796:
	dd	_584
	dd	1137
	dd	5
	align	4
_2801:
	dd	3
	dd	0
	dd	0
	align	4
_2800:
	dd	_584
	dd	1137
	dd	40
	align	4
_2804:
	dd	_584
	dd	1142
	dd	3
	align	4
_2805:
	dd	_584
	dd	1143
	dd	3
	align	4
_2809:
	dd	_584
	dd	1144
	dd	3
	align	4
_2813:
	dd	_584
	dd	1145
	dd	3
	align	4
_2817:
	dd	_584
	dd	1146
	dd	3
	align	4
_2825:
	dd	_584
	dd	1147
	dd	3
	align	4
_2853:
	dd	1
	dd	_350
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_1287
	dd	_1288
	dd	-8
	dd	0
	align	4
_2827:
	dd	_584
	dd	1156
	dd	3
	align	4
_2829:
	dd	_584
	dd	1158
	dd	3
	align	4
_2852:
	dd	3
	dd	0
	dd	0
	align	4
_2840:
	dd	_584
	dd	1159
	dd	4
	align	4
_2851:
	dd	3
	dd	0
	dd	0
	align	4
_2848:
	dd	_584
	dd	1159
	dd	46
	align	4
_2884:
	dd	1
	dd	_351
	dd	2
	dd	_677
	dd	_273
	dd	-4
	dd	2
	dd	_354
	dd	_273
	dd	-8
	dd	0
	align	4
_2854:
	dd	_584
	dd	1167
	dd	3
	align	4
_2866:
	dd	3
	dd	0
	dd	0
	align	4
_2858:
	dd	_584
	dd	1167
	dd	26
	align	4
_2867:
	dd	_584
	dd	1169
	dd	3
	align	4
_2869:
	dd	_584
	dd	1170
	dd	3
	align	4
_2883:
	dd	3
	dd	0
	dd	0
	align	4
_2880:
	dd	_584
	dd	1171
	dd	4
	align	4
_2886:
	dd	1
	dd	_274
	dd	2
	dd	_677
	dd	_1288
	dd	-4
	dd	0
	align	4
_2885:
	dd	3
	dd	0
	dd	0
	align	4
_2903:
	dd	1
	dd	_355
	dd	2
	dd	_677
	dd	_1288
	dd	-4
	dd	2
	dd	_2553
	dd	_301
	dd	-8
	dd	0
	align	4
_2887:
	dd	_584
	dd	1212
	dd	3
	align	4
_2889:
	dd	_584
	dd	1213
	dd	3
	align	4
_2894:
	dd	_584
	dd	1214
	dd	3
	align	4
_2897:
	dd	3
	dd	0
	dd	0
	align	4
_2896:
	dd	_584
	dd	1214
	dd	22
	align	4
_2902:
	dd	3
	dd	0
	dd	0
	align	4
_2899:
	dd	_584
	dd	1214
	dd	39
	align	4
_2920:
	dd	1
	dd	_357
	dd	2
	dd	_677
	dd	_1288
	dd	-4
	dd	2
	dd	_2553
	dd	_301
	dd	-8
	dd	0
	align	4
_2904:
	dd	_584
	dd	1223
	dd	3
	align	4
_2906:
	dd	_584
	dd	1224
	dd	3
	align	4
_2911:
	dd	_584
	dd	1225
	dd	3
	align	4
_2914:
	dd	3
	dd	0
	dd	0
	align	4
_2913:
	dd	_584
	dd	1225
	dd	22
	align	4
_2919:
	dd	3
	dd	0
	dd	0
	align	4
_2916:
	dd	_584
	dd	1225
	dd	39
	align	4
_2926:
	dd	1
	dd	_318
	dd	2
	dd	_677
	dd	_1288
	dd	-4
	dd	0
	align	4
_2921:
	dd	_584
	dd	1234
	dd	3
_3016:
	db	"_WriteNode",0
_3017:
	db	"NodeContents",0
_3018:
	db	"Indent",0
_3019:
	db	"Indent2",0
_3020:
	db	"TempAttr",0
_3021:
	db	"TempNode",0
	align	4
_3015:
	dd	1
	dd	_3016
	dd	2
	dd	_817
	dd	_667
	dd	-4
	dd	2
	dd	_354
	dd	_273
	dd	-8
	dd	2
	dd	_3017
	dd	_292
	dd	-12
	dd	2
	dd	_3018
	dd	_292
	dd	-16
	dd	2
	dd	_3019
	dd	_292
	dd	-20
	dd	2
	dd	_3020
	dd	_1288
	dd	-24
	dd	2
	dd	_3021
	dd	_273
	dd	-28
	dd	0
	align	4
_2927:
	dd	_584
	dd	1246
	dd	2
	align	4
_2931:
	dd	_584
	dd	1247
	dd	2
	align	4
_2934:
	dd	_584
	dd	1249
	dd	2
	align	4
_2937:
	dd	_584
	dd	1250
	dd	2
	align	4
_2953:
	dd	3
	dd	0
	dd	0
	align	4
_2948:
	dd	_584
	dd	1251
	dd	3
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
_2954:
	dd	_584
	dd	1254
	dd	2
	align	4
_2957:
	dd	_584
	dd	1255
	dd	2
	align	4
_2960:
	dd	_584
	dd	1257
	dd	2
	align	4
_2981:
	dd	3
	dd	0
	dd	0
	align	4
_2964:
	dd	_584
	dd	1258
	dd	3
	align	4
_2971:
	dd	3
	dd	0
	dd	0
	align	4
_2968:
	dd	_584
	dd	1259
	dd	4
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
_2980:
	dd	3
	dd	0
	dd	0
	align	4
_2973:
	dd	_584
	dd	1261
	dd	7
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
_3014:
	dd	3
	dd	0
	dd	0
	align	4
_2983:
	dd	_584
	dd	1264
	dd	3
	align	4
_2986:
	dd	_584
	dd	1265
	dd	3
	align	4
_2995:
	dd	3
	dd	0
	dd	0
	align	4
_2990:
	dd	_584
	dd	1265
	dd	28
	align	4
_2996:
	dd	_584
	dd	1267
	dd	3
	align	4
_3008:
	dd	3
	dd	0
	dd	0
	align	4
_3007:
	dd	_584
	dd	1268
	dd	4
	align	4
_3009:
	dd	_584
	dd	1271
	dd	3
_3105:
	db	"_WriteNode_Binary",0
	align	4
_3104:
	dd	1
	dd	_3105
	dd	2
	dd	_817
	dd	_667
	dd	-4
	dd	2
	dd	_354
	dd	_273
	dd	-8
	dd	2
	dd	_3020
	dd	_1288
	dd	-12
	dd	2
	dd	_3021
	dd	_273
	dd	-16
	dd	0
	align	4
_3022:
	dd	_584
	dd	1276
	dd	2
	align	4
_3025:
	dd	_584
	dd	1279
	dd	2
	align	4
_3030:
	dd	_584
	dd	1279
	dd	34
	align	4
_3035:
	dd	_584
	dd	1280
	dd	2
	align	4
_3040:
	dd	_584
	dd	1280
	dd	35
	align	4
_3045:
	dd	_584
	dd	1283
	dd	2
	align	4
_3052:
	dd	_584
	dd	1284
	dd	2
	align	4
_3083:
	dd	3
	dd	0
	dd	0
	align	4
_3063:
	dd	_584
	dd	1285
	dd	3
	align	4
_3068:
	dd	_584
	dd	1285
	dd	39
	align	4
_3073:
	dd	_584
	dd	1286
	dd	3
	align	4
_3078:
	dd	_584
	dd	1286
	dd	40
	align	4
_3084:
	dd	_584
	dd	1290
	dd	2
	align	4
_3091:
	dd	_584
	dd	1291
	dd	2
	align	4
_3103:
	dd	3
	dd	0
	dd	0
	align	4
_3102:
	dd	_584
	dd	1292
	dd	3
_3133:
	db	"_InitLoader_Binary",0
	align	4
_3132:
	dd	1
	dd	_3133
	dd	2
	dd	_690
	dd	_691
	dd	-4
	dd	0
	align	4
_3106:
	dd	_584
	dd	1300
	dd	2
	align	4
_3107:
	dd	_584
	dd	1302
	dd	2
	align	4
_3112:
	dd	3
	dd	0
	dd	0
	align	4
_3109:
	dd	_584
	dd	1302
	dd	28
	align	4
_3113:
	dd	_584
	dd	1303
	dd	2
	align	4
_3128:
	dd	3
	dd	0
	dd	0
	align	4
_3117:
	dd	_584
	dd	1304
	dd	3
	align	4
_3127:
	dd	3
	dd	0
	dd	0
	align	4
_3121:
	dd	_584
	dd	1305
	dd	4
	align	4
_3126:
	dd	3
	dd	0
	dd	0
	align	4
_3125:
	dd	_584
	dd	1306
	dd	5
	align	4
_3129:
	dd	_584
	dd	1310
	dd	2
	align	4
_196:
	dd	bbStringClass
	dd	2147483647
	dd	53
	dw	34,41,58,32,84,114,105,101,100,32,116,111,32,108,111,97
	dw	100,32,97,32,110,111,110,45,98,105,110,97,114,121,32,102
	dw	105,108,101,32,97,115,32,97,32,98,105,110,97,114,121,32
	dw	102,105,108,101,46
_3228:
	db	"_Load_Binary",0
_3229:
	db	"parent",0
_3230:
	db	"Length",0
_3231:
	db	"AttributeCount",0
	align	4
_3227:
	dd	1
	dd	_3228
	dd	2
	dd	_694
	dd	_303
	dd	-4
	dd	2
	dd	_3229
	dd	_273
	dd	-8
	dd	2
	dd	_354
	dd	_273
	dd	-12
	dd	2
	dd	_296
	dd	_296
	dd	-16
	dd	2
	dd	_3230
	dd	_296
	dd	-20
	dd	2
	dd	_291
	dd	_292
	dd	-24
	dd	2
	dd	_293
	dd	_292
	dd	-28
	dd	2
	dd	_3231
	dd	_296
	dd	-32
	dd	2
	dd	_1897
	dd	_1288
	dd	-36
	dd	2
	dd	_324
	dd	_296
	dd	-40
	dd	0
	align	4
_3134:
	dd	_584
	dd	1314
	dd	2
	align	4
_3138:
	dd	_584
	dd	1317
	dd	2
	align	4
_3141:
	dd	_584
	dd	1319
	dd	2
	align	4
_3144:
	dd	_584
	dd	1319
	dd	33
	align	4
_3147:
	dd	_584
	dd	1320
	dd	2
	align	4
_3150:
	dd	_584
	dd	1320
	dd	33
	align	4
_3153:
	dd	_584
	dd	1322
	dd	2
	align	4
_3162:
	dd	3
	dd	0
	dd	0
	align	4
_3155:
	dd	_584
	dd	1323
	dd	3
	align	4
_3158:
	dd	_584
	dd	1324
	dd	3
	align	4
_3175:
	dd	3
	dd	0
	dd	0
	align	4
_3164:
	dd	_584
	dd	1326
	dd	3
	align	4
_3167:
	dd	_584
	dd	1327
	dd	3
	align	4
_3171:
	dd	_584
	dd	1328
	dd	3
	align	4
_3176:
	dd	_584
	dd	1332
	dd	2
	align	4
_3179:
	dd	_584
	dd	1334
	dd	2
	align	4
_3182:
	dd	_584
	dd	1335
	dd	2
	align	4
_3216:
	dd	3
	dd	0
	dd	0
	align	4
_3185:
	dd	_584
	dd	1336
	dd	3
	align	4
_3186:
	dd	_584
	dd	1337
	dd	3
	align	4
_3190:
	dd	_584
	dd	1338
	dd	3
	align	4
_3198:
	dd	_584
	dd	1339
	dd	3
	align	4
_3201:
	dd	_584
	dd	1339
	dd	34
	align	4
_3207:
	dd	_584
	dd	1340
	dd	3
	align	4
_3210:
	dd	_584
	dd	1340
	dd	34
	align	4
_3217:
	dd	_584
	dd	1344
	dd	2
	align	4
_3219:
	dd	_584
	dd	1346
	dd	2
	align	4
_3222:
	dd	_584
	dd	1347
	dd	2
	align	4
_3226:
	dd	3
	dd	0
	dd	0
	align	4
_3225:
	dd	_584
	dd	1348
	dd	3
_3256:
	db	"_InitTokenizer",0
	align	4
_3255:
	dd	1
	dd	_3256
	dd	2
	dd	_690
	dd	_691
	dd	-8
	dd	2
	dd	_692
	dd	_693
	dd	-4
	dd	0
	align	4
_3232:
	dd	_584
	dd	1373
	dd	2
	align	4
_3233:
	dd	_584
	dd	1374
	dd	3
	align	4
_3241:
	dd	3
	dd	0
	dd	2
	dd	_817
	dd	_667
	dd	-12
	dd	0
	align	4
_3235:
	dd	_584
	dd	1375
	dd	4
	align	4
_3237:
	dd	_584
	dd	1376
	dd	5
	align	4
_3240:
	dd	_584
	dd	1377
	dd	5
	align	4
_3244:
	dd	3
	dd	0
	dd	0
	align	4
_3243:
	dd	_584
	dd	1379
	dd	4
	align	4
_3245:
	dd	_584
	dd	1381
	dd	2
	align	4
_3250:
	dd	3
	dd	0
	dd	0
	align	4
_3247:
	dd	_584
	dd	1381
	dd	29
	align	4
_3251:
	dd	_584
	dd	1382
	dd	2
	align	4
_3252:
	dd	_584
	dd	1383
	dd	2
_3408:
	db	"_Parse",0
_3409:
	db	"tok",0
_3410:
	db	"TextSeperator",0
	align	4
_3407:
	dd	1
	dd	_3408
	dd	2
	dd	_694
	dd	_303
	dd	-4
	dd	2
	dd	_3229
	dd	_273
	dd	-8
	dd	2
	dd	_3409
	dd	_296
	dd	-12
	dd	2
	dd	_354
	dd	_273
	dd	-16
	dd	2
	dd	_1287
	dd	_1288
	dd	-20
	dd	2
	dd	_3410
	dd	_292
	dd	-24
	dd	0
	align	4
_3257:
	dd	_584
	dd	1387
	dd	2
	align	4
_3261:
	dd	_584
	dd	1388
	dd	2
	align	4
_3263:
	dd	_584
	dd	1493
	dd	2
	align	4
_3406:
	dd	3
	dd	0
	dd	0
	align	4
_3264:
	dd	_584
	dd	1391
	dd	3
	align	4
_3265:
	dd	_584
	dd	1393
	dd	3
	align	4
_3335:
	dd	3
	dd	0
	dd	0
	align	4
_3275:
	dd	_584
	dd	1396
	dd	5
	align	4
_3280:
	dd	3
	dd	0
	dd	0
	align	4
_3277:
	dd	_584
	dd	1397
	dd	6
	align	4
_3289:
	dd	3
	dd	0
	dd	0
	align	4
_3282:
	dd	_584
	dd	1399
	dd	6
	align	4
_3285:
	dd	_584
	dd	1400
	dd	6
	align	4
_3290:
	dd	_584
	dd	1418
	dd	5
	align	4
_3291:
	dd	_584
	dd	1419
	dd	5
	align	4
_3324:
	dd	3
	dd	0
	dd	0
	align	4
_3292:
	dd	_584
	dd	1420
	dd	6
	align	4
_3293:
	dd	_584
	dd	1421
	dd	6
	align	4
_3297:
	dd	_584
	dd	1422
	dd	6
	align	4
_3305:
	dd	_584
	dd	1424
	dd	6
	align	4
_3309:
	dd	_584
	dd	1425
	dd	6
	align	4
_3310:
	dd	_584
	dd	1426
	dd	6
	align	4
_3313:
	dd	3
	dd	0
	dd	0
	align	4
_3312:
	dd	_584
	dd	1426
	dd	34
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
_3314:
	dd	_584
	dd	1428
	dd	6
	align	4
_3315:
	dd	_584
	dd	1429
	dd	6
	align	4
_3318:
	dd	3
	dd	0
	dd	0
	align	4
_3317:
	dd	_584
	dd	1429
	dd	38
	align	4
_213:
	dd	bbStringClass
	dd	2147483647
	dd	43
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,69,120,112,101,99,116,105,110,103,32,97,116,116,114,105
	dw	98,117,116,101,32,118,97,108,117,101,46
	align	4
_3319:
	dd	_584
	dd	1431
	dd	6
	align	4
_3323:
	dd	_584
	dd	1433
	dd	6
	align	4
_3325:
	dd	_584
	dd	1437
	dd	5
	align	4
_3328:
	dd	3
	dd	0
	dd	0
	align	4
_3327:
	dd	_584
	dd	1438
	dd	7
	align	4
_3334:
	dd	3
	dd	0
	dd	0
	align	4
_3330:
	dd	_584
	dd	1440
	dd	6
	align	4
_3333:
	dd	3
	dd	0
	dd	0
	align	4
_3332:
	dd	_584
	dd	1440
	dd	40
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
_3354:
	dd	3
	dd	0
	dd	0
	align	4
_3336:
	dd	_584
	dd	1445
	dd	5
	align	4
_3339:
	dd	3
	dd	0
	dd	0
	align	4
_3338:
	dd	_584
	dd	1446
	dd	6
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
_3347:
	dd	3
	dd	0
	dd	0
	align	4
_3341:
	dd	_584
	dd	1448
	dd	6
	align	4
_3346:
	dd	3
	dd	0
	dd	0
	align	4
_3345:
	dd	_584
	dd	1448
	dd	40
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
_3348:
	dd	_584
	dd	1452
	dd	5
	align	4
_3349:
	dd	_584
	dd	1453
	dd	5
	align	4
_3352:
	dd	3
	dd	0
	dd	0
	align	4
_3351:
	dd	_584
	dd	1453
	dd	34
	align	4
_217:
	dd	bbStringClass
	dd	2147483647
	dd	45
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,85,110,99,108,111,115,101,100,32,116,97,103,32,40,101
	dw	120,112,101,99,116,105,110,103,32,34,62,34,41
	align	4
_3353:
	dd	_584
	dd	1455
	dd	5
	align	4
_3379:
	dd	3
	dd	0
	dd	0
	align	4
_3355:
	dd	_584
	dd	1458
	dd	5
	align	4
_3358:
	dd	3
	dd	0
	dd	0
	align	4
_3357:
	dd	_584
	dd	1459
	dd	6
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
_3378:
	dd	3
	dd	0
	dd	0
	align	4
_3360:
	dd	_584
	dd	1461
	dd	6
	align	4
_3368:
	dd	3
	dd	0
	dd	0
	align	4
_3364:
	dd	_584
	dd	1462
	dd	7
	align	4
_3376:
	dd	3
	dd	0
	dd	0
	align	4
_3370:
	dd	_584
	dd	1464
	dd	7
	align	4
_3377:
	dd	_584
	dd	1466
	dd	6
	align	4
_3387:
	dd	3
	dd	0
	dd	0
	align	4
_3380:
	dd	_584
	dd	1470
	dd	5
	align	4
_3383:
	dd	3
	dd	0
	dd	0
	align	4
_3382:
	dd	_584
	dd	1471
	dd	6
	align	4
_219:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	47
	align	4
_3386:
	dd	3
	dd	0
	dd	0
	align	4
_3385:
	dd	_584
	dd	1473
	dd	6
	align	4
_3395:
	dd	3
	dd	0
	dd	0
	align	4
_3388:
	dd	_584
	dd	1477
	dd	5
	align	4
_3391:
	dd	3
	dd	0
	dd	0
	align	4
_3390:
	dd	_584
	dd	1478
	dd	6
	align	4
_220:
	dd	bbStringClass
	dd	2147483647
	dd	1
	dw	61
	align	4
_3394:
	dd	3
	dd	0
	dd	0
	align	4
_3393:
	dd	_584
	dd	1480
	dd	6
	align	4
_3397:
	dd	3
	dd	0
	dd	0
	align	4
_3396:
	dd	_584
	dd	1484
	dd	5
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
_3405:
	dd	3
	dd	0
	dd	0
	align	4
_3398:
	dd	_584
	dd	1487
	dd	5
	align	4
_3401:
	dd	3
	dd	0
	dd	0
	align	4
_3400:
	dd	_584
	dd	1488
	dd	6
	align	4
_3404:
	dd	3
	dd	0
	dd	0
	align	4
_3403:
	dd	_584
	dd	1490
	dd	6
	align	4
_222:
	dd	bbStringClass
	dd	2147483647
	dd	56
	dw	88,77,76,32,80,97,114,115,101,32,69,114,114,111,114,58
	dw	32,85,110,99,108,111,115,101,100,32,110,111,100,101,32,116
	dw	97,103,32,40,114,101,97,99,104,101,100,32,101,110,100,32
	dw	111,102,32,102,105,108,101,41
_3418:
	db	"_NextToken",0
	align	4
_3417:
	dd	1
	dd	_3418
	dd	2
	dd	_3409
	dd	_296
	dd	-4
	dd	0
	align	4
_3411:
	dd	_584
	dd	1497
	dd	2
	align	4
_3413:
	dd	_584
	dd	1500
	dd	2
	align	4
_3415:
	dd	3
	dd	0
	dd	0
	align	4
_3414:
	dd	_584
	dd	1499
	dd	3
	align	4
_3416:
	dd	_584
	dd	1501
	dd	2
_3862:
	db	"__NextToken",0
_3863:
	db	"ch",0
_3864:
	db	"_TokenBufferLen",0
	align	4
_3861:
	dd	1
	dd	_3862
	dd	2
	dd	_3863
	dd	_296
	dd	-4
	dd	2
	dd	_293
	dd	_292
	dd	-8
	dd	2
	dd	_3864
	dd	_296
	dd	-12
	dd	0
	align	4
_3419:
	dd	_584
	dd	1505
	dd	2
	align	4
_3421:
	dd	_584
	dd	1507
	dd	2
	align	4
_3423:
	dd	_584
	dd	1508
	dd	2
	align	4
_3425:
	dd	_584
	dd	1510
	dd	2
	align	4
_3426:
	dd	_584
	dd	1511
	dd	2
	align	4
_3429:
	dd	3
	dd	0
	dd	0
	align	4
_3428:
	dd	_584
	dd	1511
	dd	44
	align	4
_3430:
	dd	_584
	dd	1512
	dd	2
	align	4
_3433:
	dd	_584
	dd	1515
	dd	2
	align	4
_3586:
	dd	3
	dd	0
	dd	0
	align	4
_3442:
	dd	_584
	dd	1691
	dd	4
	align	4
_3443:
	dd	_584
	dd	1758
	dd	4
	align	4
_3574:
	dd	3
	dd	0
	dd	0
	align	4
_3444:
	dd	_584
	dd	1694
	dd	5
	align	4
_3564:
	dd	3
	dd	0
	dd	0
	align	4
_3446:
	dd	_584
	dd	1695
	dd	6
	align	4
_3468:
	dd	3
	dd	0
	dd	0
	align	4
_3456:
	dd	_584
	dd	1697
	dd	8
	align	4
_3467:
	dd	3
	dd	0
	dd	0
	align	4
_3460:
	dd	_584
	dd	1698
	dd	9
	align	4
_3466:
	dd	3
	dd	0
	dd	0
	align	4
_3464:
	dd	_584
	dd	1699
	dd	10
	align	4
_3465:
	dd	_584
	dd	1700
	dd	10
	align	4
_3481:
	dd	3
	dd	0
	dd	0
	align	4
_3469:
	dd	_584
	dd	1704
	dd	8
	align	4
_3480:
	dd	3
	dd	0
	dd	0
	align	4
_3473:
	dd	_584
	dd	1705
	dd	9
	align	4
_3479:
	dd	3
	dd	0
	dd	0
	align	4
_3477:
	dd	_584
	dd	1706
	dd	10
	align	4
_3478:
	dd	_584
	dd	1707
	dd	10
	align	4
_3523:
	dd	3
	dd	0
	dd	0
	align	4
_3482:
	dd	_584
	dd	1711
	dd	8
	align	4
_3503:
	dd	3
	dd	0
	dd	0
	align	4
_3486:
	dd	_584
	dd	1712
	dd	9
	align	4
_3502:
	dd	3
	dd	0
	dd	0
	align	4
_3490:
	dd	_584
	dd	1713
	dd	10
	align	4
_3501:
	dd	3
	dd	0
	dd	0
	align	4
_3494:
	dd	_584
	dd	1714
	dd	11
	align	4
_3500:
	dd	3
	dd	0
	dd	0
	align	4
_3498:
	dd	_584
	dd	1715
	dd	12
	align	4
_3499:
	dd	_584
	dd	1716
	dd	12
	align	4
_3522:
	dd	3
	dd	0
	dd	0
	align	4
_3505:
	dd	_584
	dd	1720
	dd	13
	align	4
_3521:
	dd	3
	dd	0
	dd	0
	align	4
_3509:
	dd	_584
	dd	1721
	dd	9
	align	4
_3520:
	dd	3
	dd	0
	dd	0
	align	4
_3513:
	dd	_584
	dd	1722
	dd	10
	align	4
_3519:
	dd	3
	dd	0
	dd	0
	align	4
_3517:
	dd	_584
	dd	1723
	dd	11
	align	4
_3518:
	dd	_584
	dd	1724
	dd	11
	align	4
_3546:
	dd	3
	dd	0
	dd	0
	align	4
_3524:
	dd	_584
	dd	1729
	dd	8
	align	4
_3545:
	dd	3
	dd	0
	dd	0
	align	4
_3528:
	dd	_584
	dd	1730
	dd	9
	align	4
_3544:
	dd	3
	dd	0
	dd	0
	align	4
_3532:
	dd	_584
	dd	1731
	dd	10
	align	4
_3543:
	dd	3
	dd	0
	dd	0
	align	4
_3536:
	dd	_584
	dd	1732
	dd	11
	align	4
_3542:
	dd	3
	dd	0
	dd	0
	align	4
_3540:
	dd	_584
	dd	1733
	dd	12
	align	4
_3541:
	dd	_584
	dd	1734
	dd	12
_3563:
	db	"tempCH",0
	align	4
_3562:
	dd	3
	dd	0
	dd	2
	dd	_3563
	dd	_296
	dd	-16
	dd	0
	align	4
_3547:
	dd	_584
	dd	1740
	dd	8
	align	4
_3549:
	dd	_584
	dd	1741
	dd	8
	align	4
_3550:
	dd	_584
	dd	1742
	dd	8
	align	4
_3551:
	dd	_584
	dd	1743
	dd	8
	align	4
_3554:
	dd	_584
	dd	1744
	dd	8
	align	4
_3561:
	dd	3
	dd	0
	dd	0
	align	4
_3555:
	dd	_584
	dd	1745
	dd	9
	align	4
_3556:
	dd	_584
	dd	1746
	dd	9
	align	4
_3557:
	dd	_584
	dd	1747
	dd	9
	align	4
_3558:
	dd	_584
	dd	1748
	dd	9
	align	4
_3565:
	dd	_584
	dd	1753
	dd	5
	align	4
_3566:
	dd	_584
	dd	1754
	dd	5
	align	4
_3567:
	dd	_584
	dd	1755
	dd	5
	align	4
_3570:
	dd	3
	dd	0
	dd	0
	align	4
_3569:
	dd	_584
	dd	1755
	dd	47
	align	4
_3571:
	dd	_584
	dd	1756
	dd	5
	align	4
_3583:
	dd	_584
	dd	1759
	dd	4
	align	4
_3584:
	dd	_584
	dd	1760
	dd	4
	align	4
_3585:
	dd	_584
	dd	1761
	dd	4
	align	4
_3687:
	dd	3
	dd	0
	dd	0
	align	4
_3587:
	dd	_584
	dd	1518
	dd	4
	align	4
_3588:
	dd	_584
	dd	1519
	dd	4
	align	4
_3591:
	dd	_584
	dd	1521
	dd	4
	align	4
_3623:
	dd	3
	dd	0
	dd	0
	align	4
_3597:
	dd	_584
	dd	1569
	dd	6
	align	4
_3598:
	dd	_584
	dd	1570
	dd	6
	align	4
_3614:
	dd	3
	dd	0
	dd	0
	align	4
_3605:
	dd	_584
	dd	1571
	dd	7
	align	4
_3606:
	dd	_584
	dd	1572
	dd	7
	align	4
_3607:
	dd	_584
	dd	1573
	dd	7
	align	4
_3610:
	dd	3
	dd	0
	dd	0
	align	4
_3609:
	dd	_584
	dd	1573
	dd	47
	align	4
_3611:
	dd	_584
	dd	1574
	dd	7
	align	4
_3615:
	dd	_584
	dd	1577
	dd	6
	align	4
_3620:
	dd	3
	dd	0
	dd	0
	align	4
_3619:
	dd	_584
	dd	1577
	dd	35
	align	4
_3621:
	dd	_584
	dd	1578
	dd	6
	align	4
_3622:
	dd	_584
	dd	1580
	dd	6
	align	4
_3654:
	dd	3
	dd	0
	dd	0
	align	4
_3624:
	dd	_584
	dd	1524
	dd	6
	align	4
_3625:
	dd	_584
	dd	1525
	dd	6
	align	4
_3628:
	dd	_584
	dd	1527
	dd	6
	align	4
_3629:
	dd	_584
	dd	1528
	dd	6
	align	4
_3645:
	dd	3
	dd	0
	dd	0
	align	4
_3636:
	dd	_584
	dd	1529
	dd	7
	align	4
_3637:
	dd	_584
	dd	1530
	dd	7
	align	4
_3638:
	dd	_584
	dd	1531
	dd	7
	align	4
_3641:
	dd	3
	dd	0
	dd	0
	align	4
_3640:
	dd	_584
	dd	1531
	dd	47
	align	4
_3642:
	dd	_584
	dd	1532
	dd	7
	align	4
_3646:
	dd	_584
	dd	1535
	dd	6
	align	4
_3651:
	dd	3
	dd	0
	dd	0
	align	4
_3650:
	dd	_584
	dd	1535
	dd	35
	align	4
_3652:
	dd	_584
	dd	1536
	dd	6
	align	4
_3653:
	dd	_584
	dd	1538
	dd	6
	align	4
_3670:
	dd	3
	dd	0
	dd	0
	align	4
_3655:
	dd	_584
	dd	1542
	dd	6
	align	4
_3656:
	dd	_584
	dd	1543
	dd	6
	align	4
_3659:
	dd	_584
	dd	1544
	dd	6
	align	4
_3668:
	dd	3
	dd	0
	dd	0
	align	4
_3660:
	dd	_584
	dd	1545
	dd	7
	align	4
_3661:
	dd	_584
	dd	1546
	dd	7
	align	4
_3664:
	dd	3
	dd	0
	dd	0
	align	4
_3663:
	dd	_584
	dd	1546
	dd	47
	align	4
_3665:
	dd	_584
	dd	1547
	dd	7
	align	4
_3669:
	dd	_584
	dd	1549
	dd	6
	align	4
_3686:
	dd	3
	dd	0
	dd	0
	align	4
_3671:
	dd	_584
	dd	1556
	dd	6
	align	4
_3672:
	dd	_584
	dd	1557
	dd	6
	align	4
_3675:
	dd	_584
	dd	1558
	dd	6
	align	4
_3684:
	dd	3
	dd	0
	dd	0
	align	4
_3676:
	dd	_584
	dd	1559
	dd	7
	align	4
_3677:
	dd	_584
	dd	1560
	dd	7
	align	4
_3680:
	dd	3
	dd	0
	dd	0
	align	4
_3679:
	dd	_584
	dd	1560
	dd	47
	align	4
_3681:
	dd	_584
	dd	1561
	dd	7
	align	4
_3685:
	dd	_584
	dd	1564
	dd	6
	align	4
_3698:
	dd	3
	dd	0
	dd	0
	align	4
_3688:
	dd	_584
	dd	1585
	dd	4
	align	4
_3689:
	dd	_584
	dd	1586
	dd	4
	align	4
_3692:
	dd	_584
	dd	1588
	dd	4
	align	4
_3695:
	dd	3
	dd	0
	dd	0
	align	4
_3694:
	dd	_584
	dd	1589
	dd	5
	align	4
_3696:
	dd	_584
	dd	1591
	dd	4
	align	4
_3697:
	dd	_584
	dd	1592
	dd	4
	align	4
_3700:
	dd	3
	dd	0
	dd	0
	align	4
_3699:
	dd	_584
	dd	1596
	dd	4
	align	4
_3702:
	dd	3
	dd	0
	dd	0
	align	4
_3701:
	dd	_584
	dd	1600
	dd	4
	align	4
_3841:
	dd	3
	dd	0
	dd	0
	align	4
_3703:
	dd	_584
	dd	1604
	dd	4
	align	4
_3704:
	dd	_584
	dd	1605
	dd	4
	align	4
_3707:
	dd	_584
	dd	1607
	dd	4
	align	4
_3708:
	dd	_584
	dd	1608
	dd	4
	align	4
_3838:
	dd	3
	dd	0
	dd	0
	align	4
_3709:
	dd	_584
	dd	1610
	dd	5
	align	4
_3828:
	dd	3
	dd	0
	dd	0
	align	4
_3711:
	dd	_584
	dd	1611
	dd	6
	align	4
_3733:
	dd	3
	dd	0
	dd	0
	align	4
_3721:
	dd	_584
	dd	1613
	dd	8
	align	4
_3732:
	dd	3
	dd	0
	dd	0
	align	4
_3725:
	dd	_584
	dd	1614
	dd	9
	align	4
_3731:
	dd	3
	dd	0
	dd	0
	align	4
_3729:
	dd	_584
	dd	1615
	dd	10
	align	4
_3730:
	dd	_584
	dd	1616
	dd	10
	align	4
_3746:
	dd	3
	dd	0
	dd	0
	align	4
_3734:
	dd	_584
	dd	1620
	dd	8
	align	4
_3745:
	dd	3
	dd	0
	dd	0
	align	4
_3738:
	dd	_584
	dd	1621
	dd	9
	align	4
_3744:
	dd	3
	dd	0
	dd	0
	align	4
_3742:
	dd	_584
	dd	1622
	dd	10
	align	4
_3743:
	dd	_584
	dd	1623
	dd	10
	align	4
_3788:
	dd	3
	dd	0
	dd	0
	align	4
_3747:
	dd	_584
	dd	1627
	dd	8
	align	4
_3768:
	dd	3
	dd	0
	dd	0
	align	4
_3751:
	dd	_584
	dd	1628
	dd	9
	align	4
_3767:
	dd	3
	dd	0
	dd	0
	align	4
_3755:
	dd	_584
	dd	1629
	dd	10
	align	4
_3766:
	dd	3
	dd	0
	dd	0
	align	4
_3759:
	dd	_584
	dd	1630
	dd	11
	align	4
_3765:
	dd	3
	dd	0
	dd	0
	align	4
_3763:
	dd	_584
	dd	1631
	dd	12
	align	4
_3764:
	dd	_584
	dd	1632
	dd	12
	align	4
_3787:
	dd	3
	dd	0
	dd	0
	align	4
_3770:
	dd	_584
	dd	1636
	dd	13
	align	4
_3786:
	dd	3
	dd	0
	dd	0
	align	4
_3774:
	dd	_584
	dd	1637
	dd	9
	align	4
_3785:
	dd	3
	dd	0
	dd	0
	align	4
_3778:
	dd	_584
	dd	1638
	dd	10
	align	4
_3784:
	dd	3
	dd	0
	dd	0
	align	4
_3782:
	dd	_584
	dd	1639
	dd	11
	align	4
_3783:
	dd	_584
	dd	1640
	dd	11
	align	4
_3811:
	dd	3
	dd	0
	dd	0
	align	4
_3789:
	dd	_584
	dd	1645
	dd	8
	align	4
_3810:
	dd	3
	dd	0
	dd	0
	align	4
_3793:
	dd	_584
	dd	1646
	dd	9
	align	4
_3809:
	dd	3
	dd	0
	dd	0
	align	4
_3797:
	dd	_584
	dd	1647
	dd	10
	align	4
_3808:
	dd	3
	dd	0
	dd	0
	align	4
_3801:
	dd	_584
	dd	1648
	dd	11
	align	4
_3807:
	dd	3
	dd	0
	dd	0
	align	4
_3805:
	dd	_584
	dd	1649
	dd	12
	align	4
_3806:
	dd	_584
	dd	1650
	dd	12
	align	4
_3827:
	dd	3
	dd	0
	dd	2
	dd	_3563
	dd	_296
	dd	-20
	dd	0
	align	4
_3812:
	dd	_584
	dd	1656
	dd	8
	align	4
_3814:
	dd	_584
	dd	1657
	dd	8
	align	4
_3815:
	dd	_584
	dd	1658
	dd	8
	align	4
_3816:
	dd	_584
	dd	1659
	dd	8
	align	4
_3819:
	dd	_584
	dd	1660
	dd	8
	align	4
_3826:
	dd	3
	dd	0
	dd	0
	align	4
_3820:
	dd	_584
	dd	1661
	dd	9
	align	4
_3821:
	dd	_584
	dd	1662
	dd	9
	align	4
_3822:
	dd	_584
	dd	1663
	dd	9
	align	4
_3823:
	dd	_584
	dd	1664
	dd	9
	align	4
_3829:
	dd	_584
	dd	1669
	dd	5
	align	4
_3830:
	dd	_584
	dd	1670
	dd	5
	align	4
_3831:
	dd	_584
	dd	1671
	dd	5
	align	4
_3834:
	dd	3
	dd	0
	dd	0
	align	4
_3833:
	dd	_584
	dd	1671
	dd	45
	align	4
_3835:
	dd	_584
	dd	1672
	dd	5
	align	4
_3839:
	dd	_584
	dd	1675
	dd	4
	align	4
_3840:
	dd	_584
	dd	1676
	dd	4
	align	4
_3860:
	dd	3
	dd	0
	dd	0
	align	4
_3842:
	dd	_584
	dd	1685
	dd	4
	align	4
_3851:
	dd	3
	dd	0
	dd	0
	align	4
_3843:
	dd	_584
	dd	1681
	dd	5
	align	4
_3844:
	dd	_584
	dd	1682
	dd	5
	align	4
_3847:
	dd	3
	dd	0
	dd	0
	align	4
_3846:
	dd	_584
	dd	1682
	dd	45
	align	4
_3848:
	dd	_584
	dd	1683
	dd	5
	align	4
_3858:
	dd	_584
	dd	1686
	dd	4
	align	4
_3859:
	dd	_584
	dd	1687
	dd	4
_3925:
	db	"_AddEscapeCodes",0
_3926:
	db	"text",0
_3927:
	db	"ln",0
_3928:
	db	"rtext",0
	align	4
_3924:
	dd	1
	dd	_3925
	dd	2
	dd	_3926
	dd	_292
	dd	-4
	dd	2
	dd	_296
	dd	_296
	dd	-8
	dd	2
	dd	_3927
	dd	_296
	dd	-12
	dd	2
	dd	_3928
	dd	_292
	dd	-16
	dd	0
	align	4
_3865:
	dd	_584
	dd	1769
	dd	2
	align	4
_3868:
	dd	_584
	dd	1770
	dd	2
	align	4
_3870:
	dd	_584
	dd	1771
	dd	2
	align	4
_3871:
	dd	_584
	dd	1773
	dd	2
	align	4
_3922:
	dd	3
	dd	0
	dd	0
	align	4
_3874:
	dd	_584
	dd	1774
	dd	3
	align	4
_3911:
	dd	3
	dd	0
	dd	0
	align	4
_3885:
	dd	_584
	dd	1781
	dd	5
	align	4
_3904:
	dd	3
	dd	0
	dd	0
	align	4
_3900:
	dd	_584
	dd	1782
	dd	6
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
_3910:
	dd	3
	dd	0
	dd	0
	align	4
_3906:
	dd	_584
	dd	1784
	dd	6
	align	4
_3913:
	dd	3
	dd	0
	dd	0
	align	4
_3912:
	dd	_584
	dd	1775
	dd	12
	align	4
_259:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	38,108,116,59
	align	4
_3915:
	dd	3
	dd	0
	dd	0
	align	4
_3914:
	dd	_584
	dd	1776
	dd	12
	align	4
_260:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	38,103,116,59
	align	4
_3917:
	dd	3
	dd	0
	dd	0
	align	4
_3916:
	dd	_584
	dd	1777
	dd	12
	align	4
_261:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	38,113,117,111,116,59
	align	4
_3919:
	dd	3
	dd	0
	dd	0
	align	4
_3918:
	dd	_584
	dd	1778
	dd	12
	align	4
_262:
	dd	bbStringClass
	dd	2147483647
	dd	6
	dw	38,97,112,111,115,59
	align	4
_3921:
	dd	3
	dd	0
	dd	0
	align	4
_3920:
	dd	_584
	dd	1779
	dd	12
	align	4
_263:
	dd	bbStringClass
	dd	2147483647
	dd	5
	dw	38,97,109,112,59
	align	4
_3923:
	dd	_584
	dd	1789
	dd	2
_3944:
	db	"_CountNodes",0
_3945:
	db	"subnode",0
_3946:
	db	"count",0
	align	4
_3943:
	dd	1
	dd	_3944
	dd	2
	dd	_2091
	dd	_273
	dd	-4
	dd	2
	dd	_3945
	dd	_273
	dd	-8
	dd	2
	dd	_3946
	dd	_296
	dd	-12
	dd	0
	align	4
_3929:
	dd	_584
	dd	1794
	dd	2
	align	4
_3932:
	dd	_584
	dd	1797
	dd	2
	align	4
_3933:
	dd	_584
	dd	1800
	dd	2
	align	4
_3936:
	dd	_584
	dd	1801
	dd	2
	align	4
_3941:
	dd	3
	dd	0
	dd	0
	align	4
_3937:
	dd	_584
	dd	1802
	dd	3
	align	4
_3938:
	dd	_584
	dd	1803
	dd	3
	align	4
_3942:
	dd	_584
	dd	1806
	dd	2
