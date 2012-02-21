	format	ELF
	extrn	__bb_basic_basic
	extrn	__bb_blitz_blitz
	extrn	__bb_filesystem_filesystem
	extrn	__bb_glmax2d_glmax2d
	extrn	__bb_map_map
	extrn	__bb_retro_retro
	extrn	__bb_system_system
	extrn	__bb_zlib_zlib
	extrn	_brl_ramstream_TRamStream_Create
	extrn	_brl_ramstream_TRamStream_Delete
	extrn	_brl_ramstream_TRamStream_New
	extrn	_brl_ramstream_TRamStream_Pos
	extrn	_brl_ramstream_TRamStream_Read
	extrn	_brl_ramstream_TRamStream_Seek
	extrn	_brl_ramstream_TRamStream_Size
	extrn	_brl_ramstream_TRamStream_Write
	extrn	_brl_stream_TIO_Close
	extrn	_brl_stream_TIO_Eof
	extrn	_brl_stream_TIO_Flush
	extrn	_brl_stream_TStreamFactory_Delete
	extrn	_brl_stream_TStreamFactory_New
	extrn	_brl_stream_TStreamReadException_Delete
	extrn	_brl_stream_TStreamReadException_New
	extrn	_brl_stream_TStream_Delete
	extrn	_brl_stream_TStream_New
	extrn	_brl_stream_TStream_ReadByte
	extrn	_brl_stream_TStream_ReadBytes
	extrn	_brl_stream_TStream_ReadDouble
	extrn	_brl_stream_TStream_ReadFloat
	extrn	_brl_stream_TStream_ReadInt
	extrn	_brl_stream_TStream_ReadLine
	extrn	_brl_stream_TStream_ReadLong
	extrn	_brl_stream_TStream_ReadObject
	extrn	_brl_stream_TStream_ReadShort
	extrn	_brl_stream_TStream_ReadString
	extrn	_brl_stream_TStream_SkipBytes
	extrn	_brl_stream_TStream_WriteByte
	extrn	_brl_stream_TStream_WriteBytes
	extrn	_brl_stream_TStream_WriteDouble
	extrn	_brl_stream_TStream_WriteFloat
	extrn	_brl_stream_TStream_WriteInt
	extrn	_brl_stream_TStream_WriteLine
	extrn	_brl_stream_TStream_WriteLong
	extrn	_brl_stream_TStream_WriteObject
	extrn	_brl_stream_TStream_WriteShort
	extrn	_brl_stream_TStream_WriteString
	extrn	bbArrayNew1D
	extrn	bbEmptyArray
	extrn	bbEmptyString
	extrn	bbExThrow
	extrn	bbGCFree
	extrn	bbIntMax
	extrn	bbIntMin
	extrn	bbMemCopy
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
	extrn	bbStringClass
	extrn	bbStringCompare
	extrn	bbStringConcat
	extrn	bbStringFind
	extrn	bbStringFindLast
	extrn	bbStringFromInt
	extrn	bbStringSlice
	extrn	bbStringToCString
	extrn	bbStringToInt
	extrn	bbStringToLower
	extrn	bbStringToUpper
	extrn	brl_bank_BankBuf
	extrn	brl_bank_BankSize
	extrn	brl_bank_CreateBank
	extrn	brl_bank_PeekInt
	extrn	brl_bank_PeekShort
	extrn	brl_bank_PokeInt
	extrn	brl_bank_PokeLong
	extrn	brl_blitz_NullFunctionError
	extrn	brl_blitz_RuntimeError
	extrn	brl_filesystem_ExtractDir
	extrn	brl_filesystem_FileSize
	extrn	brl_filesystem_FileTime
	extrn	brl_filesystem_OpenFile
	extrn	brl_filesystem_ReadFile
	extrn	brl_filesystem_RealPath
	extrn	brl_filesystem_StripDir
	extrn	brl_filesystem_WriteFile
	extrn	brl_linkedlist_CompareObjects
	extrn	brl_linkedlist_TList
	extrn	brl_map_TMap
	extrn	brl_ramstream_TRamStream
	extrn	brl_retro_Instr
	extrn	brl_stream_CloseStream
	extrn	brl_stream_CopyStream
	extrn	brl_stream_LoadByteArray
	extrn	brl_stream_ReadStream
	extrn	brl_stream_ReadString
	extrn	brl_stream_SeekStream
	extrn	brl_stream_StreamPos
	extrn	brl_stream_StreamSize
	extrn	brl_stream_TStream
	extrn	brl_stream_TStreamFactory
	extrn	brl_stream_TStreamReadException
	extrn	brl_system_CurrentDate
	extrn	brl_system_CurrentTime
	extrn	localtime_
	extrn	unzClose
	extrn	unzCloseCurrentFile
	extrn	unzGetCurrentFileSize
	extrn	unzLocateFile
	extrn	unzOpen
	extrn	unzOpen2
	extrn	unzOpenCurrentFile
	extrn	unzOpenCurrentFilePassword
	extrn	unzReadCurrentFile
	extrn	zipClose
	extrn	zipOpen
	extrn	zipOpenNewFileInZip
	extrn	zipOpenNewFileWithPassword
	extrn	zipWriteInFileInZip
	public	__bb_source_basefunctions_zip
	public	_bb_PACK_STRUCT_Delete
	public	_bb_PACK_STRUCT_New
	public	_bb_PACK_STRUCT_fillFromBank
	public	_bb_PACK_STRUCT_fillFromReader
	public	_bb_PACK_STRUCT_getBank
	public	_bb_PACK_STRUCT_size
	public	_bb_SZIPFileDataDescriptor_Delete
	public	_bb_SZIPFileDataDescriptor_New
	public	_bb_SZIPFileDataDescriptor_fillFromBank
	public	_bb_SZIPFileHeader_Delete
	public	_bb_SZIPFileHeader_New
	public	_bb_SZIPFileHeader_fillFromBank
	public	_bb_SZipFileEntry_Compare
	public	_bb_SZipFileEntry_Delete
	public	_bb_SZipFileEntry_EqEq
	public	_bb_SZipFileEntry_Less
	public	_bb_SZipFileEntry_New
	public	_bb_SZipFileEntry_create
	public	_bb_TBufferedStreamFactory_CreateStream
	public	_bb_TBufferedStreamFactory_Delete
	public	_bb_TBufferedStreamFactory_New
	public	_bb_TBufferedStream_Close
	public	_bb_TBufferedStream_Delete
	public	_bb_TBufferedStream_Flush
	public	_bb_TBufferedStream_New
	public	_bb_TBufferedStream_Pos
	public	_bb_TBufferedStream_Read
	public	_bb_TBufferedStream_Seek
	public	_bb_TBufferedStream_Size
	public	_bb_TBufferedStream_Write
	public	_bb_TZLibFileFuncDef_Delete
	public	_bb_TZLibFileFuncDef_New
	public	_bb_TZipFileList_Delete
	public	_bb_TZipFileList_New
	public	_bb_TZipFileList_create
	public	_bb_TZipFileList_deletePathFromFilename
	public	_bb_TZipFileList_extractFilename
	public	_bb_TZipFileList_findFile
	public	_bb_TZipFileList_getFileCount
	public	_bb_TZipFileList_getFileInfo
	public	_bb_TZipFileList_scanLocalHeader
	public	_bb_TZipStreamFactory_CreateStream
	public	_bb_TZipStreamFactory_Delete
	public	_bb_TZipStreamFactory_New
	public	_bb_TZipStreamReadException_Delete
	public	_bb_TZipStreamReadException_New
	public	_bb_TZipStreamReadException_ToString
	public	_bb_TZipStream_CheckZLibError
	public	_bb_TZipStream_ClearPassword
	public	_bb_TZipStream_Close
	public	_bb_TZipStream_Delete
	public	_bb_TZipStream_DiscardBytes_
	public	_bb_TZipStream_Flush
	public	_bb_TZipStream_GetCanonicalZipPath
	public	_bb_TZipStream_GetPassword
	public	_bb_TZipStream_New
	public	_bb_TZipStream_OpenCurrentFile_
	public	_bb_TZipStream_Open_
	public	_bb_TZipStream_Pos
	public	_bb_TZipStream_Read
	public	_bb_TZipStream_Seek
	public	_bb_TZipStream_SetPassword
	public	_bb_TZipStream_Size
	public	_bb_TZipStream_Write
	public	_bb_TZipStream_close_file_func
	public	_bb_TZipStream_gPasswordMap
	public	_bb_TZipStream_open_file_func
	public	_bb_TZipStream_read_file_func
	public	_bb_TZipStream_seek_file_func
	public	_bb_TZipStream_tell_file_func
	public	_bb_TZipStream_testerror_file_func
	public	_bb_TZipStream_trash
	public	_bb_TZipStream_write_file_func
	public	_bb_ZipFile_Delete
	public	_bb_ZipFile_New
	public	_bb_ZipFile_clearFileList
	public	_bb_ZipFile_getFileCount
	public	_bb_ZipFile_getFileInfo
	public	_bb_ZipFile_getFileInfoByName
	public	_bb_ZipFile_getName
	public	_bb_ZipFile_readFileList
	public	_bb_ZipFile_setName
	public	_bb_ZipRamStream_Delete
	public	_bb_ZipRamStream_New
	public	_bb_ZipRamStream_ZCreate
	public	_bb_ZipReader_CloseZip
	public	_bb_ZipReader_Delete
	public	_bb_ZipReader_ExtractFile
	public	_bb_ZipReader_ExtractFileToDisk
	public	_bb_ZipReader_New
	public	_bb_ZipReader_OpenZip
	public	_bb_ZipWriter_AddFile
	public	_bb_ZipWriter_AddStream
	public	_bb_ZipWriter_CloseZip
	public	_bb_ZipWriter_Delete
	public	_bb_ZipWriter_New
	public	_bb_ZipWriter_OpenZip
	public	_bb_ZipWriter_SetCompressionLevel
	public	_bb_tm_zip_Delete
	public	_bb_tm_zip_New
	public	_bb_zip_fileinfo_Delete
	public	_bb_zip_fileinfo_New
	public	_bb_zip_fileinfo_getBank
	public	bb_ClearZipStreamPasssword
	public	bb_CreateBufferedStream
	public	bb_PACK_STRUCT
	public	bb_SZIPFileDataDescriptor
	public	bb_SZIPFileHeader
	public	bb_SZipFileEntry
	public	bb_SetZipStreamPasssword
	public	bb_TBufferedStream
	public	bb_TZipFileList
	public	bb_TZipStreamReadException
	public	bb_ZipFile
	public	bb_ZipRamStream
	public	bb_ZipReader
	public	bb_ZipWriter
	public	bb_tm_zip
	public	bb_zip_fileinfo
	section	"code" executable
__bb_source_basefunctions_zip:
	push	ebp
	mov	ebp,esp
	cmp	dword [_628],0
	je	_629
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_629:
	mov	dword [_628],1
	call	__bb_blitz_blitz
	call	__bb_filesystem_filesystem
	call	__bb_map_map
	call	__bb_zlib_zlib
	call	__bb_basic_basic
	call	__bb_system_system
	call	__bb_retro_retro
	call	__bb_glmax2d_glmax2d
	push	bb_TBufferedStream
	call	bbObjectRegisterType
	add	esp,4
	push	_14
	call	bbObjectRegisterType
	add	esp,4
	push	_16
	call	bbObjectRegisterType
	add	esp,4
	mov	eax,dword [_624]
	and	eax,1
	cmp	eax,0
	jne	_625
	push	1024
	push	_622
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [_bb_TZipStream_trash],eax
	or	dword [_624],1
_625:
	mov	eax,dword [_624]
	and	eax,2
	cmp	eax,0
	jne	_627
	push	brl_map_TMap
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	dword [_bb_TZipStream_gPasswordMap],eax
	or	dword [_624],2
_627:
	push	_17
	call	bbObjectRegisterType
	add	esp,4
	push	_34
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TZipStreamReadException
	call	bbObjectRegisterType
	add	esp,4
	push	bb_ZipFile
	call	bbObjectRegisterType
	add	esp,4
	push	bb_ZipWriter
	call	bbObjectRegisterType
	add	esp,4
	push	bb_ZipReader
	call	bbObjectRegisterType
	add	esp,4
	push	bb_ZipRamStream
	call	bbObjectRegisterType
	add	esp,4
	push	bb_TZipFileList
	call	bbObjectRegisterType
	add	esp,4
	push	bb_tm_zip
	call	bbObjectRegisterType
	add	esp,4
	push	bb_zip_fileinfo
	call	bbObjectRegisterType
	add	esp,4
	push	bb_SZIPFileDataDescriptor
	call	bbObjectRegisterType
	add	esp,4
	push	bb_SZIPFileHeader
	call	bbObjectRegisterType
	add	esp,4
	push	bb_SZipFileEntry
	call	bbObjectRegisterType
	add	esp,4
	push	bb_PACK_STRUCT
	call	bbObjectRegisterType
	add	esp,4
	push	_14
	call	bbObjectNew
	add	esp,4
	push	_34
	call	bbObjectNew
	add	esp,4
	mov	eax,0
	jmp	_225
_225:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStream_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_brl_stream_TStream_New
	add	esp,4
	mov	dword [ebx],bb_TBufferedStream
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	dword [ebx+12],0
	mov	dword [ebx+16],0
	mov	dword [ebx+20],0
	mov	eax,bbEmptyArray
	inc	dword [eax+4]
	mov	dword [ebx+24],eax
	mov	dword [ebx+28],0
	mov	dword [ebx+32],0
	mov	dword [ebx+36],0
	mov	eax,0
	jmp	_228
_228:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStream_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_231:
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_634
	push	eax
	call	bbGCFree
	add	esp,4
_634:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_636
	push	eax
	call	bbGCFree
	add	esp,4
_636:
	mov	dword [ebx],brl_stream_TStream
	push	ebx
	call	_brl_stream_TStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_632
_632:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStream_Pos:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	jmp	_234
_234:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStream_Size:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	jmp	_237
_237:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStream_Seek:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	dword [esi+12],eax
	mov	eax,dword [esi+16]
	cmp	dword [esi+12],eax
	jge	_638
	push	0
	mov	eax,dword [esi+12]
	sub	eax,dword [esi+32]
	push	eax
	call	bbIntMax
	add	esp,8
	mov	dword [esi+16],eax
	mov	eax,dword [esi+8]
	push	dword [esi+16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	mov	edx,dword [esi+8]
	mov	ebx,dword [esi+16]
	mov	eax,dword [esi+24]
	push	dword [eax+20]
	push	dword [esi+28]
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+72]
	add	esp,12
	add	ebx,eax
	mov	dword [esi+20],ebx
	jmp	_641
_638:
	mov	eax,dword [esi+20]
	cmp	dword [esi+12],eax
	jle	_642
	mov	eax,dword [esi+12]
	sub	eax,dword [esi+36]
	mov	dword [esi+16],eax
	mov	eax,dword [esi+8]
	push	dword [esi+16]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	mov	edx,dword [esi+8]
	mov	ebx,dword [esi+16]
	mov	eax,dword [esi+24]
	push	dword [eax+20]
	push	dword [esi+28]
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+72]
	add	esp,12
	add	ebx,eax
	mov	dword [esi+20],ebx
_642:
_641:
	mov	eax,dword [esi+12]
	jmp	_241
_241:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStream_Read:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	mov	eax,dword [esi+12]
	mov	dword [ebp-4],eax
_10:
_8:
	mov	eax,dword [esi+20]
	sub	eax,dword [esi+12]
	cmp	ebx,eax
	jg	_650
	push	ebx
	mov	edx,dword [esi+28]
	mov	eax,dword [esi+12]
	sub	eax,dword [esi+16]
	add	edx,eax
	push	edx
	push	edi
	call	bbMemCopy
	add	esp,12
	add	dword [esi+12],ebx
	mov	eax,dword [esi+12]
	sub	eax,dword [ebp-4]
	jmp	_246
_650:
	mov	eax,dword [esi+20]
	sub	eax,dword [esi+12]
	cmp	eax,0
	jle	_652
	mov	eax,dword [esi+20]
	sub	eax,dword [esi+12]
	push	eax
	mov	edx,dword [esi+28]
	mov	eax,dword [esi+12]
	sub	eax,dword [esi+16]
	add	edx,eax
	push	edx
	push	edi
	call	bbMemCopy
	add	esp,12
	mov	eax,dword [esi+20]
	sub	eax,dword [esi+12]
	sub	ebx,eax
	mov	eax,dword [esi+20]
	sub	eax,dword [esi+12]
	add	edi,eax
	mov	eax,dword [esi+20]
	mov	dword [esi+12],eax
	mov	eax,dword [esi+20]
	mov	dword [esi+16],eax
_652:
	mov	eax,dword [esi+24]
	cmp	ebx,dword [eax+20]
	jl	_653
	mov	edx,dword [esi+8]
	mov	eax,dword [esi+24]
	push	dword [eax+20]
	push	edi
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+72]
	add	esp,12
	add	edi,eax
	add	dword [esi+12],eax
	mov	edx,dword [esi+12]
	mov	dword [esi+16],edx
	mov	edx,dword [esi+12]
	mov	dword [esi+20],edx
	sub	ebx,eax
	mov	edx,dword [esi+24]
	cmp	eax,dword [edx+20]
	jge	_656
	mov	eax,dword [esi+12]
	sub	eax,dword [ebp-4]
	jmp	_246
_656:
	jmp	_657
_653:
	mov	eax,dword [esi+12]
	mov	dword [esi+16],eax
	mov	edx,dword [esi+8]
	mov	eax,dword [esi+24]
	push	dword [eax+20]
	push	dword [esi+28]
	push	edx
	mov	eax,dword [edx]
	call	dword [eax+72]
	add	esp,12
	mov	edx,dword [esi+12]
	add	edx,eax
	mov	dword [esi+20],edx
	push	eax
	push	ebx
	call	bbIntMin
	add	esp,8
	mov	ebx,eax
	push	ebx
	push	dword [esi+28]
	push	edi
	call	bbMemCopy
	add	esp,12
	add	dword [esi+12],ebx
	mov	eax,dword [esi+12]
	sub	eax,dword [ebp-4]
	jmp	_246
_657:
_651:
	jmp	_10
_246:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStream_Write:
	push	ebp
	mov	ebp,esp
	push	_12
	call	brl_blitz_RuntimeError
	add	esp,4
	mov	eax,0
	jmp	_251
_251:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStream_Flush:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,4
	jmp	_254
_254:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStream_Close:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	jmp	_257
_257:
	mov	esp,ebp
	pop	ebp
	ret
bb_CreateBufferedStream:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	push	brl_stream_TStream
	push	esi
	call	bbObjectDowncast
	add	esp,8
	mov	ebx,eax
	cmp	ebx,bbNullObject
	jne	_664
	push	esi
	call	brl_stream_ReadStream
	add	esp,4
	mov	ebx,eax
_664:
	cmp	ebx,bbNullObject
	jne	_665
	mov	eax,bbNullObject
	jmp	_262
_665:
	push	bb_TBufferedStream
	push	ebx
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_667
	push	edi
	push	ebx
	call	_13
	add	esp,8
	jmp	_262
_667:
	mov	eax,ebx
	jmp	_262
_262:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_13:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+12]
	cmp	esi,1024
	jge	_669
	mov	esi,1024
_669:
	push	bb_TBufferedStream
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [ebp+8]
	inc	dword [eax+4]
	mov	edi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_674
	push	eax
	call	bbGCFree
	add	esp,4
_674:
	mov	dword [ebx+8],edi
	push	esi
	push	_675
	call	bbArrayNew1D
	add	esp,8
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_679
	push	eax
	call	bbGCFree
	add	esp,4
_679:
	mov	dword [ebx+24],esi
	mov	eax,dword [ebx+24]
	lea	eax,byte [eax+24]
	mov	dword [ebx+28],eax
	mov	ecx,3
	mov	eax,dword [ebx+24]
	mov	eax,dword [eax+20]
	cdq
	idiv	ecx
	shl	eax,1
	mov	dword [ebx+32],eax
	mov	ecx,3
	mov	eax,dword [ebx+24]
	mov	eax,dword [eax+20]
	cdq
	idiv	ecx
	mov	dword [ebx+36],eax
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	dword [ebx+12],eax
	mov	eax,ebx
	jmp	_266
_266:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStreamFactory_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_brl_stream_TStreamFactory_New
	add	esp,4
	mov	dword [ebx],_14
	mov	eax,0
	jmp	_269
_269:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStreamFactory_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_272:
	mov	dword [eax],brl_stream_TStreamFactory
	push	eax
	call	_brl_stream_TStreamFactory_Delete
	add	esp,4
	mov	eax,0
	jmp	_681
_681:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TBufferedStreamFactory_CreateStream:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	eax,dword [ebp+16]
	mov	ebx,dword [ebp+20]
	mov	esi,dword [ebp+28]
	push	_15
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	je	_682
	cmp	esi,0
	sete	al
	movzx	eax,al
_682:
	cmp	eax,0
	je	_684
	push	ebx
	call	brl_stream_ReadStream
	add	esp,4
	cmp	eax,bbNullObject
	je	_686
	push	0
	push	4096
	push	eax
	call	bb_CreateBufferedStream
	add	esp,12
	jmp	_280
_686:
_684:
	mov	eax,bbNullObject
	jmp	_280
_280:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZLibFileFuncDef_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],_16
	mov	dword [ebx+8],brl_blitz_NullFunctionError
	mov	dword [ebx+12],brl_blitz_NullFunctionError
	mov	dword [ebx+16],brl_blitz_NullFunctionError
	mov	dword [ebx+20],brl_blitz_NullFunctionError
	mov	dword [ebx+24],brl_blitz_NullFunctionError
	mov	dword [ebx+28],brl_blitz_NullFunctionError
	mov	dword [ebx+32],brl_blitz_NullFunctionError
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+36],eax
	mov	eax,0
	jmp	_283
_283:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZLibFileFuncDef_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_286:
	mov	eax,dword [eax+36]
	dec	dword [eax+4]
	jnz	_690
	push	eax
	call	bbGCFree
	add	esp,4
_690:
	mov	eax,0
	jmp	_688
_688:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_brl_stream_TStream_New
	add	esp,4
	mov	dword [ebx],_17
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	dword [ebx+12],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+28],eax
	mov	eax,0
	jmp	_289
_289:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_292:
	mov	eax,dword [ebx+28]
	dec	dword [eax+4]
	jnz	_696
	push	eax
	call	bbGCFree
	add	esp,4
_696:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_698
	push	eax
	call	bbGCFree
	add	esp,4
_698:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_700
	push	eax
	call	bbGCFree
	add	esp,4
_700:
	mov	dword [ebx],brl_stream_TStream
	push	ebx
	call	_brl_stream_TStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_694
_694:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_GetCanonicalZipPath:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	0
	push	_18
	push	ebx
	call	bbStringFind
	add	esp,12
	cmp	eax,0
	jge	_701
	push	ebx
	call	brl_filesystem_RealPath
	add	esp,4
	mov	ebx,eax
_701:
	mov	eax,ebx
	jmp	_295
_295:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_SetPassword:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	mov	ebx,dword [_bb_TZipStream_gPasswordMap]
	push	eax
	push	edx
	call	dword [_17+164]
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+56]
	add	esp,12
	mov	eax,0
	jmp	_299
_299:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_ClearPassword:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	eax,dword [ebp+8]
	mov	ebx,dword [_bb_TZipStream_gPasswordMap]
	push	eax
	call	dword [_17+164]
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+68]
	add	esp,8
	mov	eax,0
	jmp	_302
_302:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_GetPassword:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	eax,dword [ebp+8]
	mov	ebx,dword [_bb_TZipStream_gPasswordMap]
	push	bbStringClass
	push	eax
	call	dword [_17+164]
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+64]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	jne	_706
	mov	eax,bbEmptyString
_706:
	jmp	_305
_305:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_OpenCurrentFile_:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	push	dword [esi+28]
	mov	eax,dword [esi]
	call	dword [eax+176]
	add	esp,4
	mov	ebx,eax
	push	_1
	push	ebx
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	je	_708
	push	ebx
	call	bbStringToCString
	add	esp,4
	mov	ebx,eax
	push	ebx
	push	dword [esi+12]
	call	unzOpenCurrentFilePassword
	add	esp,8
	mov	esi,eax
	push	ebx
	call	bbMemFree
	add	esp,4
	jmp	_308
_708:
	push	dword [esi+12]
	call	unzOpenCurrentFile
	add	esp,4
	mov	esi,eax
	jmp	_308
_308:
	mov	eax,esi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_Open_:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+16]
	mov	eax,dword [ebp+12]
	inc	dword [eax+4]
	mov	edi,eax
	mov	eax,dword [esi+28]
	dec	dword [eax+4]
	jnz	_715
	push	eax
	call	bbGCFree
	add	esp,4
_715:
	mov	dword [esi+28],edi
	mov	dword [ebp-4],ebx
	push	0
	push	_18
	push	dword [ebp-4]
	call	bbStringFindLast
	add	esp,12
	cmp	eax,0
	jl	_718
	mov	edx,dword [ebp-4]
	push	dword [edx+8]
	add	eax,2
	push	eax
	push	dword [ebp-4]
	call	bbStringSlice
	add	esp,12
	mov	dword [ebp-4],eax
_718:
	push	_16
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [esi+16]
	dec	dword [eax+4]
	jnz	_722
	push	eax
	call	bbGCFree
	add	esp,4
_722:
	mov	dword [esi+16],ebx
	mov	edx,dword [esi+16]
	mov	eax,dword [esi]
	mov	eax,dword [eax+188]
	mov	dword [edx+8],eax
	mov	edx,dword [esi+16]
	mov	eax,dword [esi]
	mov	eax,dword [eax+192]
	mov	dword [edx+12],eax
	mov	edx,dword [esi+16]
	mov	eax,dword [esi]
	mov	eax,dword [eax+200]
	mov	dword [edx+20],eax
	mov	edx,dword [esi+16]
	mov	eax,dword [esi]
	mov	eax,dword [eax+204]
	mov	dword [edx+24],eax
	mov	edx,dword [esi+16]
	mov	eax,dword [esi]
	mov	eax,dword [eax+208]
	mov	dword [edx+28],eax
	mov	edx,dword [esi+16]
	mov	eax,dword [esi]
	mov	eax,dword [eax+212]
	mov	dword [edx+32],eax
	mov	ebx,dword [ebp+20]
	inc	dword [ebx+4]
	mov	eax,dword [esi+16]
	mov	eax,dword [eax+36]
	dec	dword [eax+4]
	jnz	_726
	push	eax
	call	bbGCFree
	add	esp,4
_726:
	mov	eax,dword [esi+16]
	mov	dword [eax+36],ebx
	push	dword [ebp+12]
	call	bbStringToCString
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [esi+16]
	lea	eax,dword [eax+8]
	push	eax
	push	ebx
	call	unzOpen2
	add	esp,8
	mov	edi,eax
	push	ebx
	call	bbMemFree
	add	esp,4
	mov	dword [esi+12],edi
	cmp	dword [esi+12],0
	jne	_729
	mov	eax,bbNullObject
	jmp	_314
_729:
	push	dword [ebp-4]
	call	bbStringToCString
	add	esp,4
	mov	ebx,eax
	push	0
	push	ebx
	push	dword [esi+12]
	call	unzLocateFile
	add	esp,12
	mov	edi,eax
	push	ebx
	call	bbMemFree
	add	esp,4
	cmp	edi,0
	je	_733
	mov	eax,bbNullObject
	jmp	_314
_733:
	push	dword [ebp+12]
	mov	eax,dword [esi]
	call	dword [eax+176]
	add	esp,4
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+180]
	add	esp,4
	cmp	eax,0
	jne	_736
	push	dword [esi+12]
	call	unzGetCurrentFileSize
	add	esp,4
	mov	dword [esi+20],eax
	mov	ebx,dword [ebp+20]
	inc	dword [ebx+4]
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_740
	push	eax
	call	bbGCFree
	add	esp,4
_740:
	mov	dword [esi+8],ebx
	mov	eax,esi
	jmp	_314
_736:
	mov	eax,bbNullObject
	jmp	_314
_314:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_open_file_func:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	mov	eax,dword [ebp+8]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp-4]
	lea	eax,dword [eax+8]
	jmp	_319
_319:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_read_file_func:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	ecx,dword [ebp+16]
	mov	edx,dword [ebp+20]
	push	edx
	push	ecx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,12
	jmp	_325
_325:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_write_file_func:
	push	ebp
	mov	ebp,esp
	mov	eax,0
	jmp	_331
_331:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_tell_file_func:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	jmp	_335
_335:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_seek_file_func:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+16]
	mov	eax,dword [ebp+20]
	cmp	eax,0
	je	_746
	cmp	eax,1
	je	_747
	cmp	eax,2
	je	_748
	push	_19
	call	brl_blitz_RuntimeError
	add	esp,4
	jmp	_745
_746:
	push	ebx
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+60]
	add	esp,8
	jmp	_745
_747:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	add	eax,ebx
	push	eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+60]
	add	esp,8
	jmp	_745
_748:
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,4
	sub	eax,ebx
	push	eax
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+60]
	add	esp,8
	jmp	_745
_745:
	mov	eax,0
	jmp	_341
_341:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_close_file_func:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,4
	mov	eax,0
	jmp	_345
_345:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_testerror_file_func:
	push	ebp
	mov	ebp,esp
	mov	eax,0
	jmp	_349
_349:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_Pos:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+24]
	jmp	_352
_352:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_Size:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+20]
	jmp	_355
_355:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_Seek:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	cmp	ebx,dword [esi+24]
	je	_755
	cmp	ebx,dword [esi+24]
	jge	_756
	push	dword [esi+12]
	call	unzCloseCurrentFile
	add	esp,4
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+180]
	add	esp,4
	mov	dword [esi+24],0
_756:
	sub	ebx,dword [esi+24]
	push	ebx
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+216]
	add	esp,8
_755:
	push	esi
	mov	eax,dword [esi]
	call	dword [eax+52]
	add	esp,4
	jmp	_359
_359:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_DiscardBytes_:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	esi,dword [ebp+12]
_26:
_24:
	mov	eax,dword [_bb_TZipStream_trash]
	cmp	esi,dword [eax+20]
	jle	_762
	mov	eax,dword [_bb_TZipStream_trash]
	push	dword [eax+20]
	mov	eax,dword [_bb_TZipStream_trash]
	lea	eax,byte [eax+24]
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,12
	mov	eax,dword [_bb_TZipStream_trash]
	sub	esi,dword [eax+20]
	jmp	_764
_762:
	cmp	esi,0
	jle	_765
	push	esi
	mov	eax,dword [_bb_TZipStream_trash]
	lea	eax,byte [eax+24]
	push	eax
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+72]
	add	esp,12
_765:
	jmp	_25
_764:
	jmp	_26
_25:
	mov	eax,0
	jmp	_363
_363:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_Read:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [ebp+16]
	push	eax
	push	edx
	push	dword [ebx+12]
	call	unzReadCurrentFile
	add	esp,12
	mov	esi,eax
	push	esi
	mov	eax,dword [ebx]
	call	dword [eax+220]
	add	esp,4
	add	dword [ebx+24],esi
	mov	eax,esi
	jmp	_368
_368:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_Write:
	push	ebp
	mov	ebp,esp
	push	_12
	call	brl_blitz_RuntimeError
	add	esp,4
	mov	eax,0
	jmp	_373
_373:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_Flush:
	push	ebp
	mov	ebp,esp
	mov	eax,0
	jmp	_376
_376:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_Close:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	cmp	dword [ebx+12],0
	je	_768
	push	dword [ebx+12]
	call	unzCloseCurrentFile
	add	esp,4
	push	dword [ebx+12]
	call	unzClose
	add	esp,4
_768:
	mov	eax,0
	jmp	_379
_379:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStream_CheckZLibError:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	eax,dword [ebp+8]
	cmp	eax,-1
	je	_772
	cmp	eax,-2
	je	_773
	cmp	eax,-3
	je	_774
	cmp	eax,-4
	je	_775
	cmp	eax,-5
	je	_776
	cmp	eax,-6
	je	_777
	mov	eax,0
	jmp	_382
_772:
	mov	ebx,_28
	jmp	_771
_773:
	mov	ebx,_29
	jmp	_771
_774:
	mov	ebx,_30
	jmp	_771
_775:
	mov	ebx,_31
	jmp	_771
_776:
	mov	ebx,_32
	jmp	_771
_777:
	mov	ebx,_33
	jmp	_771
_771:
	push	bb_TZipStreamReadException
	call	bbObjectNew
	add	esp,4
	mov	esi,eax
	inc	dword [ebx+4]
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_782
	push	eax
	call	bbGCFree
	add	esp,4
_782:
	mov	dword [esi+8],ebx
	push	esi
	call	bbExThrow
	add	esp,4
	mov	eax,0
	jmp	_382
_382:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStreamFactory_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_brl_stream_TStreamFactory_New
	add	esp,4
	mov	dword [ebx],_34
	mov	eax,0
	jmp	_385
_385:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStreamFactory_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_388:
	mov	dword [eax],brl_stream_TStreamFactory
	push	eax
	call	_brl_stream_TStreamFactory_Delete
	add	esp,4
	mov	eax,0
	jmp	_783
_783:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStreamFactory_CreateStream:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+28]
	push	_35
	push	dword [ebp+16]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_784
	push	_36
	push	dword [ebp+16]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
_784:
	cmp	eax,0
	je	_786
	cmp	ebx,0
	sete	al
	movzx	eax,al
_786:
	cmp	eax,0
	je	_788
	push	0
	push	_37
	push	dword [ebp+20]
	call	bbStringFind
	add	esp,12
	mov	edi,eax
	cmp	edi,0
	jl	_790
	push	edi
	push	0
	push	dword [ebp+20]
	call	bbStringSlice
	add	esp,12
	mov	esi,eax
	push	esi
	call	brl_stream_ReadStream
	add	esp,4
	mov	ebx,eax
	cmp	ebx,bbNullObject
	je	_793
	mov	eax,dword [ebp+20]
	push	dword [eax+8]
	mov	eax,edi
	add	eax,2
	push	eax
	push	dword [ebp+20]
	call	bbStringSlice
	add	esp,12
	mov	edi,eax
	push	_17
	call	bbObjectNew
	add	esp,4
	push	ebx
	push	edi
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+184]
	add	esp,16
	cmp	eax,bbNullObject
	je	_797
	push	0
	push	4096
	push	eax
	call	bb_CreateBufferedStream
	add	esp,12
	jmp	_396
_797:
	push	_36
	push	dword [ebp+16]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	jne	_799
	push	edi
	call	brl_stream_ReadStream
	add	esp,4
	jmp	_396
_799:
_798:
_793:
_790:
_788:
	mov	eax,bbNullObject
	jmp	_396
_396:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStreamReadException_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_brl_stream_TStreamReadException_New
	add	esp,4
	mov	dword [ebx],bb_TZipStreamReadException
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,0
	jmp	_399
_399:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStreamReadException_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_402:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_803
	push	eax
	call	bbGCFree
	add	esp,4
_803:
	mov	dword [ebx],brl_stream_TStreamReadException
	push	ebx
	call	_brl_stream_TStreamReadException_Delete
	add	esp,4
	mov	eax,0
	jmp	_801
_801:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipStreamReadException_ToString:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	jmp	_405
_405:
	mov	esp,ebp
	pop	ebp
	ret
bb_SetZipStreamPasssword:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	eax
	push	edx
	call	dword [_17+168]
	add	esp,8
	mov	eax,0
	jmp	_409
_409:
	mov	esp,ebp
	pop	ebp
	ret
bb_ClearZipStreamPasssword:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	push	eax
	call	dword [_17+172]
	add	esp,4
	mov	eax,0
	jmp	_412
_412:
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipFile_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_ZipFile
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	eax,0
	jmp	_415
_415:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipFile_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_418:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_808
	push	eax
	call	bbGCFree
	add	esp,4
_808:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_810
	push	eax
	call	bbGCFree
	add	esp,4
_810:
	mov	eax,0
	jmp	_806
_806:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipFile_readFileList:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	mov	eax,dword [edi+8]
	mov	eax,dword [eax+8]
	cmp	eax,0
	setg	al
	movzx	eax,al
	cmp	eax,0
	je	_812
	push	dword [edi+8]
	call	brl_filesystem_FileSize
	add	esp,4
	cmp	eax,0
	setg	al
	movzx	eax,al
_812:
	cmp	eax,0
	je	_814
	push	dword [edi+8]
	call	brl_filesystem_ReadFile
	add	esp,4
	mov	esi,eax
	cmp	esi,bbNullObject
	je	_816
	push	0
	push	0
	push	esi
	call	dword [bb_TZipFileList+48]
	add	esp,12
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [edi+12]
	dec	dword [eax+4]
	jnz	_820
	push	eax
	call	bbGCFree
	add	esp,4
_820:
	mov	dword [edi+12],ebx
	push	esi
	call	brl_stream_CloseStream
	add	esp,4
_816:
_814:
	mov	eax,0
	jmp	_421
_421:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipFile_clearFileList:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,bbNullObject
	inc	dword [ebx+4]
	mov	eax,dword [esi+12]
	dec	dword [eax+4]
	jnz	_824
	push	eax
	call	bbGCFree
	add	esp,4
_824:
	mov	dword [esi+12],ebx
	mov	eax,0
	jmp	_424
_424:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipFile_getFileCount:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	cmp	dword [eax+12],bbNullObject
	je	_825
	mov	eax,dword [eax+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,4
	jmp	_427
_825:
	mov	eax,0
	jmp	_427
_427:
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipFile_setName:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	inc	dword [ebx+4]
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_831
	push	eax
	call	bbGCFree
	add	esp,4
_831:
	mov	dword [esi+8],ebx
	mov	eax,0
	jmp	_431
_431:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipFile_getName:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+8]
	jmp	_434
_434:
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipFile_getFileInfo:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+12]
	push	edx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+56]
	add	esp,8
	jmp	_438
_438:
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipFile_getFileInfoByName:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [eax+12]
	push	edx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	jmp	_442
_442:
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipWriter_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_ZipFile_New
	add	esp,4
	mov	dword [ebx],bb_ZipWriter
	mov	dword [ebx+16],0
	mov	dword [ebx+20],-1
	mov	eax,0
	jmp	_445
_445:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipWriter_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_448:
	mov	dword [eax],bb_ZipFile
	push	eax
	call	_bb_ZipFile_Delete
	add	esp,4
	mov	eax,0
	jmp	_834
_834:
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipWriter_OpenZip:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	eax,dword [ebp+16]
	cmp	eax,0
	je	_835
	push	dword [ebp+12]
	call	bbStringToCString
	add	esp,4
	mov	esi,eax
	push	2
	push	esi
	call	zipOpen
	add	esp,8
	mov	ebx,eax
	push	esi
	call	bbMemFree
	add	esp,4
	mov	dword [edi+16],ebx
	jmp	_838
_835:
	push	dword [ebp+12]
	call	bbStringToCString
	add	esp,4
	mov	esi,eax
	push	0
	push	esi
	call	zipOpen
	add	esp,8
	mov	ebx,eax
	push	esi
	call	bbMemFree
	add	esp,4
	mov	dword [edi+16],ebx
_838:
	cmp	dword [edi+16],0
	je	_841
	mov	eax,edi
	push	dword [ebp+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	mov	eax,edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	eax,1
	jmp	_453
_841:
	mov	eax,0
	jmp	_453
_453:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipWriter_SetCompressionLevel:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	cmp	dword [edx+16],0
	je	_845
	mov	dword [edx+20],eax
_845:
	mov	eax,0
	jmp	_457
_457:
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipWriter_AddFile:
	push	ebp
	mov	ebp,esp
	sub	esp,16
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+16]
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],0
	je	_846
	push	1
	push	1
	push	dword [ebp+12]
	call	brl_filesystem_OpenFile
	add	esp,12
	mov	dword [ebp-12],eax
	cmp	dword [ebp-12],bbNullObject
	je	_848
	push	dword [ebp-12]
	call	brl_stream_StreamSize
	add	esp,4
	mov	dword [ebp-16],eax
	push	dword [ebp+12]
	call	brl_filesystem_FileTime
	add	esp,4
	mov	dword [ebp-4],eax
	lea	eax,dword [ebp-4]
	push	eax
	call	localtime_
	add	esp,4
	mov	esi,eax
	push	bb_zip_fileinfo
	call	bbObjectNew
	add	esp,4
	mov	ecx,dword [eax+8]
	mov	edx,dword [esi]
	mov	dword [ecx+8],edx
	mov	ecx,dword [eax+8]
	mov	edx,dword [esi+4]
	mov	dword [ecx+12],edx
	mov	ecx,dword [eax+8]
	mov	edx,dword [esi+8]
	mov	dword [ecx+16],edx
	mov	ecx,dword [eax+8]
	mov	edx,dword [esi+12]
	mov	dword [ecx+20],edx
	mov	ecx,dword [eax+8]
	mov	edx,dword [esi+16]
	mov	dword [ecx+24],edx
	mov	ecx,dword [eax+8]
	mov	edx,dword [esi+20]
	add	edx,1900
	mov	dword [ecx+28],edx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	edi,eax
	cmp	dword [ebx+8],0
	jne	_855
	push	dword [ebp+12]
	call	bbStringToCString
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [ebp+8]
	push	dword [eax+20]
	push	8
	push	0
	push	0
	push	0
	push	0
	push	0
	push	edi
	call	brl_bank_BankBuf
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebp+8]
	push	dword [eax+16]
	call	zipOpenNewFileInZip
	add	esp,40
	push	ebx
	call	bbMemFree
	add	esp,4
	jmp	_858
_855:
	push	dword [ebp+12]
	call	bbStringToCString
	add	esp,4
	mov	esi,eax
	push	ebx
	call	bbStringToCString
	add	esp,4
	mov	ebx,eax
	push	ebx
	mov	eax,dword [ebp+8]
	push	dword [eax+20]
	push	8
	push	0
	push	0
	push	0
	push	0
	push	0
	push	edi
	call	brl_bank_BankBuf
	add	esp,4
	push	eax
	push	esi
	mov	eax,dword [ebp+8]
	push	dword [eax+16]
	call	zipOpenNewFileWithPassword
	add	esp,44
	push	esi
	call	bbMemFree
	add	esp,4
	push	ebx
	call	bbMemFree
	add	esp,4
_858:
	push	dword [ebp-12]
	call	brl_stream_LoadByteArray
	add	esp,4
	mov	dword [ebp-8],eax
	push	dword [ebp-16]
	mov	eax,dword [ebp-8]
	lea	eax,byte [eax+24]
	push	eax
	mov	eax,dword [ebp+8]
	push	dword [eax+16]
	call	zipWriteInFileInZip
	add	esp,12
	call	dword [bb_SZipFileEntry+48]
	mov	ebx,eax
	mov	esi,dword [ebp+12]
	inc	dword [esi+4]
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_867
	push	eax
	call	bbGCFree
	add	esp,4
_867:
	mov	dword [ebx+8],esi
	push	dword [ebp+12]
	call	brl_filesystem_StripDir
	add	esp,4
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_871
	push	eax
	call	bbGCFree
	add	esp,4
_871:
	mov	dword [ebx+12],esi
	push	dword [ebp+12]
	call	brl_filesystem_ExtractDir
	add	esp,4
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_875
	push	eax
	call	bbGCFree
	add	esp,4
_875:
	mov	dword [ebx+16],esi
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_876
	push	bb_TZipFileList
	call	bbObjectNew
	add	esp,4
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_880
	push	eax
	call	bbGCFree
	add	esp,4
_880:
	mov	eax,dword [ebp+8]
	mov	dword [eax+12],esi
_876:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	mov	eax,dword [eax+12]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
_848:
_846:
	mov	eax,0
	jmp	_462
_462:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipWriter_AddStream:
	push	ebp
	mov	ebp,esp
	sub	esp,28
	push	ebx
	push	esi
	push	edi
	mov	edx,dword [ebp+12]
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],0
	je	_882
	mov	dword [ebp-24],edx
	cmp	dword [ebp-24],bbNullObject
	je	_884
	push	dword [ebp-24]
	call	brl_stream_StreamSize
	add	esp,4
	mov	dword [ebp-28],eax
	call	brl_system_CurrentDate
	mov	esi,eax
	call	brl_system_CurrentTime
	mov	edi,eax
	push	dword [ebp+16]
	call	brl_filesystem_FileTime
	add	esp,4
	push	bb_zip_fileinfo
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [ebx+8]
	mov	dword [ebp-8],eax
	push	dword [edi+8]
	push	7
	push	edi
	call	bbStringSlice
	add	esp,12
	push	eax
	call	bbStringToInt
	add	esp,4
	mov	edx,dword [ebp-8]
	mov	dword [edx+8],eax
	mov	eax,dword [ebx+8]
	mov	dword [ebp-12],eax
	push	6
	push	3
	push	edi
	call	bbStringSlice
	add	esp,12
	push	eax
	call	bbStringToInt
	add	esp,4
	mov	edx,dword [ebp-12]
	mov	dword [edx+12],eax
	mov	eax,dword [ebx+8]
	mov	dword [ebp-16],eax
	push	2
	push	0
	push	edi
	call	bbStringSlice
	add	esp,12
	push	eax
	call	bbStringToInt
	add	esp,4
	mov	edx,dword [ebp-16]
	mov	dword [edx+16],eax
	mov	edi,dword [ebx+8]
	push	2
	push	0
	push	esi
	call	bbStringSlice
	add	esp,12
	push	eax
	call	bbStringToInt
	add	esp,4
	mov	dword [edi+20],eax
	mov	edi,dword [ebx+8]
	mov	dword [ebp-20],3
	push	1
	push	6
	push	3
	push	esi
	call	bbStringSlice
	add	esp,12
	push	eax
	call	bbStringToUpper
	add	esp,4
	push	eax
	push	_38
	call	brl_retro_Instr
	add	esp,12
	cdq
	cdq
	idiv	dword [ebp-20]
	mov	dword [edi+24],eax
	mov	edi,dword [ebx+8]
	push	dword [esi+8]
	mov	eax,dword [esi+8]
	sub	eax,4
	push	eax
	push	esi
	call	bbStringSlice
	add	esp,12
	push	eax
	call	bbStringToInt
	add	esp,4
	mov	dword [edi+28],eax
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	edi,eax
	mov	eax,dword [ebp+20]
	cmp	dword [eax+8],0
	jne	_892
	push	dword [ebp+16]
	call	bbStringToCString
	add	esp,4
	mov	ebx,eax
	mov	eax,dword [ebp+8]
	push	dword [eax+20]
	push	8
	push	0
	push	0
	push	0
	push	0
	push	0
	push	edi
	call	brl_bank_BankBuf
	add	esp,4
	push	eax
	push	ebx
	mov	eax,dword [ebp+8]
	push	dword [eax+16]
	call	zipOpenNewFileInZip
	add	esp,40
	push	ebx
	call	bbMemFree
	add	esp,4
	jmp	_895
_892:
	push	dword [ebp+16]
	call	bbStringToCString
	add	esp,4
	mov	esi,eax
	push	dword [ebp+20]
	call	bbStringToCString
	add	esp,4
	mov	ebx,eax
	push	ebx
	mov	eax,dword [ebp+8]
	push	dword [eax+20]
	push	8
	push	0
	push	0
	push	0
	push	0
	push	0
	push	edi
	call	brl_bank_BankBuf
	add	esp,4
	push	eax
	push	esi
	mov	eax,dword [ebp+8]
	push	dword [eax+16]
	call	zipOpenNewFileWithPassword
	add	esp,44
	push	esi
	call	bbMemFree
	add	esp,4
	push	ebx
	call	bbMemFree
	add	esp,4
_895:
	push	dword [ebp-24]
	call	brl_stream_LoadByteArray
	add	esp,4
	mov	dword [ebp-4],eax
	push	dword [ebp-28]
	mov	eax,dword [ebp-4]
	lea	eax,byte [eax+24]
	push	eax
	mov	eax,dword [ebp+8]
	push	dword [eax+16]
	call	zipWriteInFileInZip
	add	esp,12
	call	dword [bb_SZipFileEntry+48]
	mov	ebx,eax
	mov	esi,dword [ebp+16]
	inc	dword [esi+4]
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_904
	push	eax
	call	bbGCFree
	add	esp,4
_904:
	mov	dword [ebx+8],esi
	push	dword [ebp+16]
	call	brl_filesystem_StripDir
	add	esp,4
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_908
	push	eax
	call	bbGCFree
	add	esp,4
_908:
	mov	dword [ebx+12],esi
	push	dword [ebp+16]
	call	brl_filesystem_ExtractDir
	add	esp,4
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_912
	push	eax
	call	bbGCFree
	add	esp,4
_912:
	mov	dword [ebx+16],esi
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_913
	push	bb_TZipFileList
	call	bbObjectNew
	add	esp,4
	mov	esi,eax
	inc	dword [esi+4]
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	dec	dword [eax+4]
	jnz	_917
	push	eax
	call	bbGCFree
	add	esp,4
_917:
	mov	eax,dword [ebp+8]
	mov	dword [eax+12],esi
_913:
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	mov	eax,dword [eax+12]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
_884:
_882:
	mov	eax,0
	jmp	_468
_468:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipWriter_CloseZip:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	cmp	dword [ebx+16],0
	je	_919
	push	eax
	call	bbStringToCString
	add	esp,4
	mov	esi,eax
	push	esi
	push	dword [ebx+16]
	call	zipClose
	add	esp,8
	push	esi
	call	bbMemFree
	add	esp,4
_919:
	push	_1
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	eax,0
	jmp	_472
_472:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipReader_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_ZipFile_New
	add	esp,4
	mov	dword [ebx],bb_ZipReader
	mov	dword [ebx+16],0
	mov	eax,0
	jmp	_475
_475:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipReader_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_478:
	mov	dword [eax],bb_ZipFile
	push	eax
	call	_bb_ZipFile_Delete
	add	esp,4
	mov	eax,0
	jmp	_924
_924:
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipReader_OpenZip:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	push	edi
	call	bbStringToCString
	add	esp,4
	mov	ebx,eax
	push	ebx
	call	unzOpen
	add	esp,4
	mov	dword [ebp-4],eax
	push	ebx
	call	bbMemFree
	add	esp,4
	mov	eax,dword [ebp-4]
	mov	dword [esi+16],eax
	cmp	dword [esi+16],0
	je	_927
	mov	eax,esi
	push	edi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+60]
	add	esp,8
	mov	eax,esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	mov	eax,1
	jmp	_482
_927:
	mov	eax,0
	jmp	_482
_482:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipReader_ExtractFile:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	edx,dword [ebp+12]
	mov	eax,dword [ebp+16]
	cmp	dword [edi+16],0
	je	_931
	cmp	eax,0
	je	_933
	push	edx
	call	bbStringToCString
	add	esp,4
	mov	esi,eax
	push	1
	push	esi
	push	dword [edi+16]
	call	unzLocateFile
	add	esp,12
	mov	ebx,eax
	push	esi
	call	bbMemFree
	add	esp,4
	mov	eax,ebx
	jmp	_936
_933:
	push	edx
	call	bbStringToCString
	add	esp,4
	mov	esi,eax
	push	2
	push	esi
	push	dword [edi+16]
	call	unzLocateFile
	add	esp,12
	mov	ebx,eax
	push	esi
	call	bbMemFree
	add	esp,4
	mov	eax,ebx
_936:
	cmp	eax,0
	jne	_939
	mov	eax,dword [ebp+20]
	cmp	dword [eax+8],0
	jne	_940
	push	dword [edi+16]
	call	unzOpenCurrentFile
	add	esp,4
	jmp	_941
_940:
	push	dword [ebp+20]
	call	bbStringToCString
	add	esp,4
	mov	esi,eax
	push	esi
	push	dword [edi+16]
	call	unzOpenCurrentFilePassword
	add	esp,8
	mov	ebx,eax
	push	esi
	call	bbMemFree
	add	esp,4
	mov	eax,ebx
_941:
	cmp	eax,0
	jne	_944
	push	dword [edi+16]
	call	unzGetCurrentFileSize
	add	esp,4
	push	0
	push	1
	push	eax
	call	dword [bb_ZipRamStream+168]
	add	esp,12
	jmp	_488
_944:
	mov	eax,bbNullObject
	jmp	_488
_939:
	mov	eax,bbNullObject
	jmp	_488
_931:
	mov	eax,bbNullObject
	jmp	_488
_488:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipReader_ExtractFileToDisk:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+12]
	mov	eax,dword [ebp+16]
	mov	ebx,dword [ebp+20]
	mov	edi,dword [ebp+24]
	push	eax
	call	brl_filesystem_WriteFile
	add	esp,4
	mov	dword [ebp-4],eax
	mov	eax,dword [ebp+8]
	push	edi
	push	ebx
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+80]
	add	esp,16
	mov	edx,eax
	mov	eax,dword [ebp-4]
	cmp	eax,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	je	_952
	cmp	edx,bbNullObject
	setne	al
	movzx	eax,al
_952:
	cmp	eax,0
	je	_954
	push	4096
	push	dword [ebp-4]
	push	edx
	call	brl_stream_CopyStream
	add	esp,12
_954:
	push	dword [ebp-4]
	call	brl_stream_CloseStream
	add	esp,4
	mov	eax,0
	jmp	_495
_495:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipReader_CloseZip:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	cmp	dword [ebx+16],0
	je	_955
	push	dword [ebx+16]
	call	unzClose
	add	esp,4
_955:
	push	_1
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+60]
	add	esp,8
	push	ebx
	mov	eax,dword [ebx]
	call	dword [eax+52]
	add	esp,4
	mov	eax,0
	jmp	_498
_498:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipRamStream_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_brl_ramstream_TRamStream_New
	add	esp,4
	mov	dword [ebx],bb_ZipRamStream
	mov	eax,bbEmptyArray
	inc	dword [eax+4]
	mov	dword [ebx+28],eax
	mov	eax,0
	jmp	_501
_501:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipRamStream_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_504:
	mov	eax,dword [ebx+28]
	dec	dword [eax+4]
	jnz	_961
	push	eax
	call	bbGCFree
	add	esp,4
_961:
	mov	dword [ebx],brl_ramstream_TRamStream
	push	ebx
	call	_brl_ramstream_TRamStream_Delete
	add	esp,4
	mov	eax,0
	jmp	_959
_959:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_ZipRamStream_ZCreate:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+12]
	push	bb_ZipRamStream
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	push	esi
	push	_963
	call	bbArrayNew1D
	add	esp,8
	inc	dword [eax+4]
	mov	dword [ebp-4],eax
	mov	eax,dword [ebx+28]
	dec	dword [eax+4]
	jnz	_967
	push	eax
	call	bbGCFree
	add	esp,4
_967:
	mov	eax,dword [ebp-4]
	mov	dword [ebx+28],eax
	mov	dword [ebx+8],0
	mov	dword [ebx+12],esi
	mov	eax,dword [ebx+28]
	lea	eax,byte [eax+24]
	mov	dword [ebx+16],eax
	mov	dword [ebx+20],edi
	mov	eax,dword [ebp+16]
	mov	dword [ebx+24],eax
	mov	eax,ebx
	jmp	_509
_509:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipFileList_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_TZipFileList
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	dword [ebx+16],0
	mov	dword [ebx+20],0
	push	brl_linkedlist_TList
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_973
	push	eax
	call	bbGCFree
	add	esp,4
_973:
	mov	dword [ebx+12],esi
	mov	eax,0
	jmp	_512
_512:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipFileList_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_515:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_976
	push	eax
	call	bbGCFree
	add	esp,4
_976:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_978
	push	eax
	call	bbGCFree
	add	esp,4
_978:
	mov	eax,0
	jmp	_974
_974:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipFileList_create:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	esi,dword [ebp+8]
	mov	edi,dword [ebp+16]
	cmp	esi,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	jne	_979
	mov	eax,bbNullObject
	jmp	_520
_979:
	push	bb_TZipFileList
	call	bbObjectNew
	add	esp,4
	mov	ebx,eax
	mov	eax,esi
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_984
	push	eax
	call	bbGCFree
	add	esp,4
_984:
	mov	dword [ebx+8],esi
	mov	eax,dword [ebp+12]
	mov	dword [ebx+16],eax
	mov	dword [ebx+20],edi
	jmp	_39
_41:
_39:
	mov	eax,ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+64]
	add	esp,4
	cmp	eax,0
	jne	_41
_40:
	mov	eax,dword [ebx+12]
	push	brl_linkedlist_CompareObjects
	push	1
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+136]
	add	esp,12
	mov	eax,ebx
	jmp	_520
_520:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipFileList_getFileCount:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
	mov	eax,dword [eax+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,4
	jmp	_523
_523:
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipFileList_getFileInfo:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	esi,dword [ebp+8]
	mov	ebx,dword [ebp+12]
	cmp	ebx,0
	setl	al
	movzx	eax,al
	cmp	eax,0
	jne	_989
	mov	eax,dword [esi+12]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+112]
	add	esp,4
	cmp	ebx,eax
	setge	al
	movzx	eax,al
_989:
	cmp	eax,0
	je	_991
	push	ebx
	call	bbStringFromInt
	add	esp,4
	push	eax
	push	_42
	call	bbStringConcat
	add	esp,8
	push	eax
	call	brl_blitz_RuntimeError
	add	esp,4
_991:
	mov	eax,dword [esi+12]
	push	bb_SZipFileEntry
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+108]
	add	esp,8
	push	eax
	call	bbObjectDowncast
	add	esp,8
	jmp	_527
_527:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipFileList_findFile:
	push	ebp
	mov	ebp,esp
	sub	esp,4
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+12]
	mov	dword [ebp-4],bbNullObject
	call	dword [bb_SZipFileEntry+48]
	mov	ebx,eax
	mov	eax,esi
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_998
	push	eax
	call	bbGCFree
	add	esp,4
_998:
	mov	dword [ebx+12],esi
	cmp	dword [edi+16],0
	je	_999
	push	dword [ebx+12]
	call	bbStringToLower
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_1003
	push	eax
	call	bbGCFree
	add	esp,4
_1003:
	mov	dword [ebx+12],esi
_999:
	cmp	dword [edi+20],0
	je	_1004
	mov	eax,edi
	lea	edx,dword [ebx+12]
	push	edx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+72]
	add	esp,8
_1004:
	mov	eax,dword [edi+12]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+104]
	add	esp,8
	cmp	eax,bbNullObject
	je	_1008
	push	bb_SZipFileEntry
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,4
	push	eax
	call	bbObjectDowncast
	add	esp,8
	mov	dword [ebp-4],eax
	jmp	_1010
_1008:
_1010:
	mov	eax,dword [ebp-4]
	jmp	_531
_531:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipFileList_scanLocalHeader:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	call	dword [bb_SZipFileEntry+48]
	mov	esi,eax
	mov	dword [esi+20],0
	mov	eax,dword [esi+24]
	push	0
	push	0
	push	30
	push	dword [edi+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,20
	mov	eax,dword [esi+24]
	cmp	dword [eax+8],67324752
	je	_1013
	mov	eax,0
	jmp	_534
_1013:
	mov	eax,dword [esi+24]
	movzx	eax,word [eax+28]
	mov	eax,eax
	push	eax
	push	dword [edi+8]
	call	brl_stream_ReadString
	add	esp,8
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [esi+8]
	dec	dword [eax+4]
	jnz	_1017
	push	eax
	call	bbGCFree
	add	esp,4
_1017:
	mov	dword [esi+8],ebx
	mov	eax,edi
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	eax,dword [esi+24]
	movzx	eax,word [eax+30]
	cmp	eax,0
	je	_1019
	push	dword [edi+8]
	call	brl_stream_StreamPos
	add	esp,4
	mov	edx,dword [esi+24]
	movzx	edx,word [edx+30]
	mov	edx,edx
	add	eax,edx
	push	eax
	push	dword [edi+8]
	call	brl_stream_SeekStream
	add	esp,8
_1019:
	mov	eax,dword [esi+24]
	movzx	eax,word [eax+14]
	mov	eax,eax
	and	eax,8
	cmp	eax,0
	je	_1020
	mov	eax,dword [esi+24]
	mov	eax,dword [eax+24]
	push	0
	push	0
	push	12
	push	dword [edi+8]
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+52]
	add	esp,20
_1020:
	push	dword [edi+8]
	call	brl_stream_StreamPos
	add	esp,4
	mov	dword [esi+20],eax
	push	dword [edi+8]
	call	brl_stream_StreamPos
	add	esp,4
	mov	edx,dword [esi+24]
	mov	edx,dword [edx+24]
	add	eax,dword [edx+12]
	push	eax
	push	dword [edi+8]
	call	brl_stream_SeekStream
	add	esp,8
	mov	eax,dword [edi+12]
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+68]
	add	esp,8
	mov	eax,1
	jmp	_534
_534:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipFileList_extractFilename:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+12]
	mov	eax,dword [edi+24]
	movzx	eax,word [eax+28]
	cmp	eax,0
	jne	_1023
	mov	eax,0
	jmp	_538
_1023:
	mov	eax,dword [ebp+8]
	cmp	dword [eax+16],0
	je	_1024
	push	dword [edi+8]
	call	bbStringToLower
	add	esp,4
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [edi+8]
	dec	dword [eax+4]
	jnz	_1028
	push	eax
	call	bbGCFree
	add	esp,4
_1028:
	mov	dword [edi+8],ebx
_1024:
	push	_43
	push	dword [edi+8]
	call	brl_filesystem_ExtractDir
	add	esp,4
	push	eax
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setne	al
	movzx	eax,al
	mov	esi,eax
	push	dword [edi+8]
	call	brl_filesystem_StripDir
	add	esp,4
	inc	dword [eax+4]
	mov	ebx,eax
	mov	eax,dword [edi+12]
	dec	dword [eax+4]
	jnz	_1033
	push	eax
	call	bbGCFree
	add	esp,4
_1033:
	mov	dword [edi+12],ebx
	cmp	esi,0
	je	_1034
	push	dword [edi+8]
	call	brl_filesystem_ExtractDir
	add	esp,4
	mov	ebx,eax
	inc	dword [ebx+4]
	mov	eax,dword [edi+16]
	dec	dword [eax+4]
	jnz	_1038
	push	eax
	call	bbGCFree
	add	esp,4
_1038:
	mov	dword [edi+16],ebx
	jmp	_1039
_1034:
	mov	ebx,_1
	inc	dword [ebx+4]
	mov	eax,dword [edi+16]
	dec	dword [eax+4]
	jnz	_1043
	push	eax
	call	bbGCFree
	add	esp,4
_1043:
	mov	dword [edi+16],ebx
_1039:
	mov	eax,dword [ebp+8]
	cmp	dword [eax+20],0
	jne	_1044
	mov	ebx,dword [edi+8]
	inc	dword [ebx+4]
	mov	eax,dword [edi+12]
	dec	dword [eax+4]
	jnz	_1048
	push	eax
	call	bbGCFree
	add	esp,4
_1048:
	mov	dword [edi+12],ebx
_1044:
	mov	eax,0
	jmp	_538
_538:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_TZipFileList_deletePathFromFilename:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+12]
	push	dword [ebx]
	call	brl_filesystem_StripDir
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx]
	dec	dword [eax+4]
	jnz	_1052
	push	eax
	call	bbGCFree
	add	esp,4
_1052:
	mov	dword [ebx],esi
	mov	eax,0
	jmp	_542
_542:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tm_zip_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_tm_zip
	mov	dword [ebx+8],0
	mov	dword [ebx+12],0
	mov	dword [ebx+16],0
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	dword [ebx+28],0
	mov	eax,0
	jmp	_545
_545:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_tm_zip_Delete:
	push	ebp
	mov	ebp,esp
_548:
	mov	eax,0
	jmp	_1053
_1053:
	mov	esp,ebp
	pop	ebp
	ret
_bb_zip_fileinfo_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_zip_fileinfo
	push	bb_tm_zip
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	dword [ebx+16],0
	mov	dword [ebx+20],0
	mov	dword [ebx+24],0
	mov	dword [ebx+28],0
	mov	dword [ebx+32],0
	mov	dword [ebx+36],0
	mov	eax,0
	jmp	_551
_551:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_zip_fileinfo_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_554:
	mov	eax,dword [eax+8]
	dec	dword [eax+4]
	jnz	_1057
	push	eax
	call	bbGCFree
	add	esp,4
_1057:
	mov	eax,0
	jmp	_1055
_1055:
	mov	esp,ebp
	pop	ebp
	ret
_bb_zip_fileinfo_getBank:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	push	48
	call	brl_bank_CreateBank
	add	esp,4
	mov	esi,eax
	mov	eax,dword [ebx+8]
	push	dword [eax+8]
	push	0
	push	esi
	call	brl_bank_PokeInt
	add	esp,12
	mov	eax,dword [ebx+8]
	push	dword [eax+12]
	push	4
	push	esi
	call	brl_bank_PokeInt
	add	esp,12
	mov	eax,dword [ebx+8]
	push	dword [eax+16]
	push	8
	push	esi
	call	brl_bank_PokeInt
	add	esp,12
	mov	eax,dword [ebx+8]
	push	dword [eax+20]
	push	12
	push	esi
	call	brl_bank_PokeInt
	add	esp,12
	mov	eax,dword [ebx+8]
	push	dword [eax+24]
	push	16
	push	esi
	call	brl_bank_PokeInt
	add	esp,12
	mov	eax,dword [ebx+8]
	push	dword [eax+28]
	push	20
	push	esi
	call	brl_bank_PokeInt
	add	esp,12
	push	dword [ebx+20]
	push	dword [ebx+16]
	push	24
	push	esi
	call	brl_bank_PokeLong
	add	esp,16
	push	dword [ebx+28]
	push	dword [ebx+24]
	push	32
	push	esi
	call	brl_bank_PokeLong
	add	esp,16
	push	dword [ebx+36]
	push	dword [ebx+32]
	push	40
	push	esi
	call	brl_bank_PokeLong
	add	esp,16
	mov	eax,esi
	jmp	_557
_557:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZIPFileDataDescriptor_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_PACK_STRUCT_New
	add	esp,4
	mov	dword [ebx],bb_SZIPFileDataDescriptor
	mov	dword [ebx+8],0
	mov	dword [ebx+12],0
	mov	dword [ebx+16],0
	mov	eax,0
	jmp	_560
_560:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZIPFileDataDescriptor_Delete:
	push	ebp
	mov	ebp,esp
	mov	eax,dword [ebp+8]
_563:
	mov	dword [eax],bb_PACK_STRUCT
	push	eax
	call	_bb_PACK_STRUCT_Delete
	add	esp,4
	mov	eax,0
	jmp	_1059
_1059:
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZIPFileDataDescriptor_fillFromBank:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	push	esi
	call	brl_bank_BankSize
	add	esp,4
	mov	edx,ebx
	add	edx,12
	sub	edx,1
	cmp	eax,edx
	jge	_1060
	push	_44
	call	brl_blitz_RuntimeError
	add	esp,4
_1060:
	push	ebx
	push	esi
	call	brl_bank_PeekInt
	add	esp,8
	mov	dword [edi+8],eax
	mov	eax,ebx
	add	eax,4
	push	eax
	push	esi
	call	brl_bank_PeekInt
	add	esp,8
	mov	dword [edi+12],eax
	mov	eax,ebx
	add	eax,8
	push	eax
	push	esi
	call	brl_bank_PeekInt
	add	esp,8
	mov	dword [edi+16],eax
	mov	eax,0
	jmp	_568
_568:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZIPFileHeader_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	push	ebx
	call	_bb_PACK_STRUCT_New
	add	esp,4
	mov	dword [ebx],bb_SZIPFileHeader
	mov	dword [ebx+8],0
	mov	word [ebx+12],0
	mov	word [ebx+14],0
	mov	word [ebx+16],0
	mov	word [ebx+18],0
	mov	word [ebx+20],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+24],eax
	mov	word [ebx+28],0
	mov	word [ebx+30],0
	push	bb_SZIPFileDataDescriptor
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_1065
	push	eax
	call	bbGCFree
	add	esp,4
_1065:
	mov	dword [ebx+24],esi
	mov	eax,0
	jmp	_571
_571:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZIPFileHeader_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_574:
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_1068
	push	eax
	call	bbGCFree
	add	esp,4
_1068:
	mov	dword [ebx],bb_PACK_STRUCT
	push	ebx
	call	_bb_PACK_STRUCT_Delete
	add	esp,4
	mov	eax,0
	jmp	_1066
_1066:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZIPFileHeader_fillFromBank:
	push	ebp
	mov	ebp,esp
	sub	esp,12
	push	ebx
	push	esi
	push	edi
	mov	edi,dword [ebp+8]
	mov	esi,dword [ebp+12]
	mov	ebx,dword [ebp+16]
	push	esi
	call	brl_bank_BankSize
	add	esp,4
	mov	edx,ebx
	add	edx,30
	sub	edx,1
	cmp	eax,edx
	jge	_1069
	push	_44
	call	brl_blitz_RuntimeError
	add	esp,4
_1069:
	push	ebx
	push	esi
	call	brl_bank_PeekInt
	add	esp,8
	mov	dword [edi+8],eax
	mov	eax,ebx
	add	eax,4
	push	eax
	push	esi
	call	brl_bank_PeekShort
	add	esp,8
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [edi+12],ax
	mov	eax,ebx
	add	eax,6
	push	eax
	push	esi
	call	brl_bank_PeekShort
	add	esp,8
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [edi+14],ax
	mov	eax,ebx
	add	eax,8
	push	eax
	push	esi
	call	brl_bank_PeekShort
	add	esp,8
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [edi+16],ax
	mov	eax,ebx
	add	eax,10
	push	eax
	push	esi
	call	brl_bank_PeekShort
	add	esp,8
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [edi+18],ax
	mov	eax,ebx
	add	eax,12
	push	eax
	push	esi
	call	brl_bank_PeekShort
	add	esp,8
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [edi+20],ax
	mov	eax,dword [edi+24]
	mov	dword [ebp-4],eax
	mov	eax,ebx
	add	eax,14
	push	eax
	push	esi
	call	brl_bank_PeekInt
	add	esp,8
	mov	edx,dword [ebp-4]
	mov	dword [edx+8],eax
	mov	eax,dword [edi+24]
	mov	dword [ebp-8],eax
	mov	eax,ebx
	add	eax,18
	push	eax
	push	esi
	call	brl_bank_PeekInt
	add	esp,8
	mov	edx,dword [ebp-8]
	mov	dword [edx+12],eax
	mov	eax,dword [edi+24]
	mov	dword [ebp-12],eax
	mov	eax,ebx
	add	eax,22
	push	eax
	push	esi
	call	brl_bank_PeekInt
	add	esp,8
	mov	edx,dword [ebp-12]
	mov	dword [edx+16],eax
	mov	eax,ebx
	add	eax,26
	push	eax
	push	esi
	call	brl_bank_PeekShort
	add	esp,8
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [edi+28],ax
	mov	eax,ebx
	add	eax,28
	push	eax
	push	esi
	call	brl_bank_PeekShort
	add	esp,8
	mov	eax,eax
	and	eax,0xffff
	mov	eax,eax
	mov	word [edi+30],ax
	mov	eax,0
	jmp	_579
_579:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZipFileEntry_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_SZipFileEntry
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+8],eax
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+12],eax
	mov	eax,bbEmptyString
	inc	dword [eax+4]
	mov	dword [ebx+16],eax
	mov	dword [ebx+20],0
	mov	eax,bbNullObject
	inc	dword [eax+4]
	mov	dword [ebx+24],eax
	push	bb_SZIPFileHeader
	call	bbObjectNew
	add	esp,4
	inc	dword [eax+4]
	mov	esi,eax
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_1077
	push	eax
	call	bbGCFree
	add	esp,4
_1077:
	mov	dword [ebx+24],esi
	mov	eax,0
	jmp	_582
_582:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZipFileEntry_Delete:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
_585:
	mov	eax,dword [ebx+24]
	dec	dword [eax+4]
	jnz	_1080
	push	eax
	call	bbGCFree
	add	esp,4
_1080:
	mov	eax,dword [ebx+16]
	dec	dword [eax+4]
	jnz	_1082
	push	eax
	call	bbGCFree
	add	esp,4
_1082:
	mov	eax,dword [ebx+12]
	dec	dword [eax+4]
	jnz	_1084
	push	eax
	call	bbGCFree
	add	esp,4
_1084:
	mov	eax,dword [ebx+8]
	dec	dword [eax+4]
	jnz	_1086
	push	eax
	call	bbGCFree
	add	esp,4
_1086:
	mov	eax,0
	jmp	_1078
_1078:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZipFileEntry_create:
	push	ebp
	mov	ebp,esp
	push	bb_SZipFileEntry
	call	bbObjectNew
	add	esp,4
	jmp	_587
_587:
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZipFileEntry_Less:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	push	dword [edx+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	setl	al
	movzx	eax,al
	jmp	_591
_591:
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZipFileEntry_EqEq:
	push	ebp
	mov	ebp,esp
	mov	edx,dword [ebp+8]
	mov	eax,dword [ebp+12]
	push	dword [eax+12]
	push	dword [edx+12]
	call	bbStringCompare
	add	esp,8
	cmp	eax,0
	sete	al
	movzx	eax,al
	jmp	_595
_595:
	mov	esp,ebp
	pop	ebp
	ret
_bb_SZipFileEntry_Compare:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	mov	ebx,dword [ebp+8]
	mov	esi,dword [ebp+12]
	push	bb_SZipFileEntry
	push	esi
	call	bbObjectDowncast
	add	esp,8
	cmp	eax,bbNullObject
	je	_1087
	push	bb_SZipFileEntry
	push	esi
	call	bbObjectDowncast
	add	esp,8
	push	dword [eax+12]
	push	dword [ebx+12]
	call	bbStringCompare
	add	esp,8
	jmp	_599
_1087:
	mov	eax,-1
	jmp	_599
_599:
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_PACK_STRUCT_New:
	push	ebp
	mov	ebp,esp
	push	ebx
	mov	ebx,dword [ebp+8]
	push	ebx
	call	bbObjectCtor
	add	esp,4
	mov	dword [ebx],bb_PACK_STRUCT
	mov	eax,0
	jmp	_602
_602:
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_PACK_STRUCT_Delete:
	push	ebp
	mov	ebp,esp
_605:
	mov	eax,0
	jmp	_1089
_1089:
	mov	esp,ebp
	pop	ebp
	ret
_bb_PACK_STRUCT_fillFromBank:
	push	ebp
	mov	ebp,esp
	mov	eax,0
	jmp	_610
_610:
	mov	esp,ebp
	pop	ebp
	ret
_bb_PACK_STRUCT_fillFromReader:
	push	ebp
	mov	ebp,esp
	push	ebx
	push	esi
	push	edi
	mov	ebx,dword [ebp+12]
	mov	edi,dword [ebp+16]
	cmp	ebx,bbNullObject
	setne	al
	movzx	eax,al
	cmp	eax,0
	sete	al
	movzx	eax,al
	cmp	eax,0
	jne	_1090
	push	ebx
	call	brl_stream_StreamPos
	add	esp,4
	mov	esi,eax
	add	esi,edi
	push	ebx
	call	brl_stream_StreamSize
	add	esp,4
	cmp	esi,eax
	setg	al
	movzx	eax,al
_1090:
	cmp	eax,0
	je	_1092
	mov	eax,0
	jmp	_617
_1092:
	push	edi
	call	brl_bank_CreateBank
	add	esp,4
	mov	esi,eax
	mov	eax,esi
	push	edi
	push	dword [ebp+20]
	push	ebx
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+76]
	add	esp,16
	mov	eax,dword [ebp+8]
	push	dword [ebp+24]
	push	esi
	push	eax
	mov	eax,dword [eax]
	call	dword [eax+48]
	add	esp,12
	mov	eax,1
	jmp	_617
_617:
	pop	edi
	pop	esi
	pop	ebx
	mov	esp,ebp
	pop	ebp
	ret
_bb_PACK_STRUCT_getBank:
	push	ebp
	mov	ebp,esp
	mov	eax,bbNullObject
	jmp	_620
_620:
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_628:
	dd	0
_46:
	db	"TBufferedStream",0
_47:
	db	"innerStream",0
_48:
	db	":brl.stream.TStream",0
_49:
	db	"pos_",0
_50:
	db	"i",0
_51:
	db	"start_",0
_52:
	db	"end_",0
_53:
	db	"buf",0
_54:
	db	"[]b",0
_55:
	db	"bufPtr",0
_56:
	db	"*b",0
_57:
	db	"bias1",0
_58:
	db	"bias2",0
_59:
	db	"New",0
_60:
	db	"()i",0
_61:
	db	"Delete",0
_62:
	db	"Pos",0
_63:
	db	"Size",0
_64:
	db	"Seek",0
_65:
	db	"(i)i",0
_66:
	db	"Read",0
_67:
	db	"(*b,i)i",0
_68:
	db	"Write",0
_69:
	db	"Flush",0
_70:
	db	"Close",0
	align	4
_45:
	dd	2
	dd	_46
	dd	3
	dd	_47
	dd	_48
	dd	8
	dd	3
	dd	_49
	dd	_50
	dd	12
	dd	3
	dd	_51
	dd	_50
	dd	16
	dd	3
	dd	_52
	dd	_50
	dd	20
	dd	3
	dd	_53
	dd	_54
	dd	24
	dd	3
	dd	_55
	dd	_56
	dd	28
	dd	3
	dd	_57
	dd	_50
	dd	32
	dd	3
	dd	_58
	dd	_50
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
	dd	_62
	dd	_60
	dd	52
	dd	6
	dd	_63
	dd	_60
	dd	56
	dd	6
	dd	_64
	dd	_65
	dd	60
	dd	6
	dd	_66
	dd	_67
	dd	72
	dd	6
	dd	_68
	dd	_67
	dd	76
	dd	6
	dd	_69
	dd	_60
	dd	64
	dd	6
	dd	_70
	dd	_60
	dd	68
	dd	0
	align	4
bb_TBufferedStream:
	dd	brl_stream_TStream
	dd	bbObjectFree
	dd	_45
	dd	40
	dd	_bb_TBufferedStream_New
	dd	_bb_TBufferedStream_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_brl_stream_TIO_Eof
	dd	_bb_TBufferedStream_Pos
	dd	_bb_TBufferedStream_Size
	dd	_bb_TBufferedStream_Seek
	dd	_bb_TBufferedStream_Flush
	dd	_bb_TBufferedStream_Close
	dd	_bb_TBufferedStream_Read
	dd	_bb_TBufferedStream_Write
	dd	_brl_stream_TStream_ReadBytes
	dd	_brl_stream_TStream_WriteBytes
	dd	_brl_stream_TStream_SkipBytes
	dd	_brl_stream_TStream_ReadByte
	dd	_brl_stream_TStream_WriteByte
	dd	_brl_stream_TStream_ReadShort
	dd	_brl_stream_TStream_WriteShort
	dd	_brl_stream_TStream_ReadInt
	dd	_brl_stream_TStream_WriteInt
	dd	_brl_stream_TStream_ReadLong
	dd	_brl_stream_TStream_WriteLong
	dd	_brl_stream_TStream_ReadFloat
	dd	_brl_stream_TStream_WriteFloat
	dd	_brl_stream_TStream_ReadDouble
	dd	_brl_stream_TStream_WriteDouble
	dd	_brl_stream_TStream_ReadLine
	dd	_brl_stream_TStream_WriteLine
	dd	_brl_stream_TStream_ReadString
	dd	_brl_stream_TStream_WriteString
	dd	_brl_stream_TStream_ReadObject
	dd	_brl_stream_TStream_WriteObject
_72:
	db	"TBufferedStreamFactory",0
_73:
	db	"CreateStream",0
_74:
	db	"(:Object,$,$,i,i):brl.stream.TStream",0
	align	4
_71:
	dd	2
	dd	_72
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_73
	dd	_74
	dd	48
	dd	0
	align	4
_14:
	dd	brl_stream_TStreamFactory
	dd	bbObjectFree
	dd	_71
	dd	12
	dd	_bb_TBufferedStreamFactory_New
	dd	_bb_TBufferedStreamFactory_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TBufferedStreamFactory_CreateStream
_76:
	db	"TZLibFileFuncDef",0
_77:
	db	"open_file_func",0
_78:
	db	"(:brl.stream.TStream,*b,i)*b",0
_79:
	db	"read_file_func",0
_80:
	db	"(:brl.stream.TStream,*b,*b,i)i",0
_81:
	db	"write_file_func",0
_82:
	db	"tell_file_func",0
_83:
	db	"(:brl.stream.TStream,*b)i",0
_84:
	db	"seek_file_func",0
_85:
	db	"(:brl.stream.TStream,*b,i,i)i",0
_86:
	db	"close_file_func",0
_87:
	db	"testerror_file_func",0
_88:
	db	"bmxStream",0
	align	4
_75:
	dd	2
	dd	_76
	dd	3
	dd	_77
	dd	_78
	dd	8
	dd	3
	dd	_79
	dd	_80
	dd	12
	dd	3
	dd	_81
	dd	_80
	dd	16
	dd	3
	dd	_82
	dd	_83
	dd	20
	dd	3
	dd	_84
	dd	_85
	dd	24
	dd	3
	dd	_86
	dd	_83
	dd	28
	dd	3
	dd	_87
	dd	_83
	dd	32
	dd	3
	dd	_88
	dd	_48
	dd	36
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	0
	align	4
_16:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_75
	dd	40
	dd	_bb_TZLibFileFuncDef_New
	dd	_bb_TZLibFileFuncDef_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	align	4
_624:
	dd	0
_622:
	db	"b",0
	align	4
_bb_TZipStream_trash:
	dd	bbEmptyArray
	align	4
_bb_TZipStream_gPasswordMap:
	dd	bbNullObject
_90:
	db	"TZipStream",0
_91:
	db	"unzfile",0
_92:
	db	"ioFileFuncDef",0
_93:
	db	":TZLibFileFuncDef",0
_94:
	db	"size_",0
_95:
	db	"zipUrl",0
_96:
	db	"$",0
_97:
	db	"GetCanonicalZipPath",0
_98:
	db	"($)$",0
_99:
	db	"SetPassword",0
_100:
	db	"($,$)i",0
_101:
	db	"ClearPassword",0
_102:
	db	"($)i",0
_103:
	db	"GetPassword",0
_104:
	db	"OpenCurrentFile_",0
_105:
	db	"Open_",0
_106:
	db	"($,$,:brl.stream.TStream):TZipStream",0
_107:
	db	"DiscardBytes_",0
_108:
	db	"CheckZLibError",0
	align	4
_89:
	dd	2
	dd	_90
	dd	3
	dd	_47
	dd	_48
	dd	8
	dd	3
	dd	_91
	dd	_56
	dd	12
	dd	3
	dd	_92
	dd	_93
	dd	16
	dd	3
	dd	_94
	dd	_50
	dd	20
	dd	3
	dd	_49
	dd	_50
	dd	24
	dd	3
	dd	_95
	dd	_96
	dd	28
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	7
	dd	_97
	dd	_98
	dd	164
	dd	7
	dd	_99
	dd	_100
	dd	168
	dd	7
	dd	_101
	dd	_102
	dd	172
	dd	7
	dd	_103
	dd	_98
	dd	176
	dd	6
	dd	_104
	dd	_60
	dd	180
	dd	6
	dd	_105
	dd	_106
	dd	184
	dd	7
	dd	_77
	dd	_78
	dd	188
	dd	7
	dd	_79
	dd	_80
	dd	192
	dd	7
	dd	_81
	dd	_80
	dd	196
	dd	7
	dd	_82
	dd	_83
	dd	200
	dd	7
	dd	_84
	dd	_85
	dd	204
	dd	7
	dd	_86
	dd	_83
	dd	208
	dd	7
	dd	_87
	dd	_83
	dd	212
	dd	6
	dd	_62
	dd	_60
	dd	52
	dd	6
	dd	_63
	dd	_60
	dd	56
	dd	6
	dd	_64
	dd	_65
	dd	60
	dd	6
	dd	_107
	dd	_65
	dd	216
	dd	6
	dd	_66
	dd	_67
	dd	72
	dd	6
	dd	_68
	dd	_67
	dd	76
	dd	6
	dd	_69
	dd	_60
	dd	64
	dd	6
	dd	_70
	dd	_60
	dd	68
	dd	7
	dd	_108
	dd	_65
	dd	220
	dd	0
	align	4
_17:
	dd	brl_stream_TStream
	dd	bbObjectFree
	dd	_89
	dd	32
	dd	_bb_TZipStream_New
	dd	_bb_TZipStream_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_brl_stream_TIO_Eof
	dd	_bb_TZipStream_Pos
	dd	_bb_TZipStream_Size
	dd	_bb_TZipStream_Seek
	dd	_bb_TZipStream_Flush
	dd	_bb_TZipStream_Close
	dd	_bb_TZipStream_Read
	dd	_bb_TZipStream_Write
	dd	_brl_stream_TStream_ReadBytes
	dd	_brl_stream_TStream_WriteBytes
	dd	_brl_stream_TStream_SkipBytes
	dd	_brl_stream_TStream_ReadByte
	dd	_brl_stream_TStream_WriteByte
	dd	_brl_stream_TStream_ReadShort
	dd	_brl_stream_TStream_WriteShort
	dd	_brl_stream_TStream_ReadInt
	dd	_brl_stream_TStream_WriteInt
	dd	_brl_stream_TStream_ReadLong
	dd	_brl_stream_TStream_WriteLong
	dd	_brl_stream_TStream_ReadFloat
	dd	_brl_stream_TStream_WriteFloat
	dd	_brl_stream_TStream_ReadDouble
	dd	_brl_stream_TStream_WriteDouble
	dd	_brl_stream_TStream_ReadLine
	dd	_brl_stream_TStream_WriteLine
	dd	_brl_stream_TStream_ReadString
	dd	_brl_stream_TStream_WriteString
	dd	_brl_stream_TStream_ReadObject
	dd	_brl_stream_TStream_WriteObject
	dd	_bb_TZipStream_GetCanonicalZipPath
	dd	_bb_TZipStream_SetPassword
	dd	_bb_TZipStream_ClearPassword
	dd	_bb_TZipStream_GetPassword
	dd	_bb_TZipStream_OpenCurrentFile_
	dd	_bb_TZipStream_Open_
	dd	_bb_TZipStream_open_file_func
	dd	_bb_TZipStream_read_file_func
	dd	_bb_TZipStream_write_file_func
	dd	_bb_TZipStream_tell_file_func
	dd	_bb_TZipStream_seek_file_func
	dd	_bb_TZipStream_close_file_func
	dd	_bb_TZipStream_testerror_file_func
	dd	_bb_TZipStream_DiscardBytes_
	dd	_bb_TZipStream_CheckZLibError
_110:
	db	"TZipStreamFactory",0
	align	4
_109:
	dd	2
	dd	_110
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_73
	dd	_74
	dd	48
	dd	0
	align	4
_34:
	dd	brl_stream_TStreamFactory
	dd	bbObjectFree
	dd	_109
	dd	12
	dd	_bb_TZipStreamFactory_New
	dd	_bb_TZipStreamFactory_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TZipStreamFactory_CreateStream
_112:
	db	"TZipStreamReadException",0
_113:
	db	"msg",0
_114:
	db	"ToString",0
_115:
	db	"()$",0
	align	4
_111:
	dd	2
	dd	_112
	dd	3
	dd	_113
	dd	_96
	dd	8
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_114
	dd	_115
	dd	24
	dd	0
	align	4
bb_TZipStreamReadException:
	dd	brl_stream_TStreamReadException
	dd	bbObjectFree
	dd	_111
	dd	12
	dd	_bb_TZipStreamReadException_New
	dd	_bb_TZipStreamReadException_Delete
	dd	_bb_TZipStreamReadException_ToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
_117:
	db	"ZipFile",0
_118:
	db	"m_name",0
_119:
	db	"m_zipFileList",0
_120:
	db	":TZipFileList",0
_121:
	db	"readFileList",0
_122:
	db	"clearFileList",0
_123:
	db	"getFileCount",0
_124:
	db	"setName",0
_125:
	db	"getName",0
_126:
	db	"getFileInfo",0
_127:
	db	"(i):SZipFileEntry",0
_128:
	db	"getFileInfoByName",0
_129:
	db	"($):SZipFileEntry",0
	align	4
_116:
	dd	2
	dd	_117
	dd	3
	dd	_118
	dd	_96
	dd	8
	dd	3
	dd	_119
	dd	_120
	dd	12
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_121
	dd	_60
	dd	48
	dd	6
	dd	_122
	dd	_60
	dd	52
	dd	6
	dd	_123
	dd	_60
	dd	56
	dd	6
	dd	_124
	dd	_102
	dd	60
	dd	6
	dd	_125
	dd	_115
	dd	64
	dd	6
	dd	_126
	dd	_127
	dd	68
	dd	6
	dd	_128
	dd	_129
	dd	72
	dd	0
	align	4
bb_ZipFile:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_116
	dd	16
	dd	_bb_ZipFile_New
	dd	_bb_ZipFile_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_ZipFile_readFileList
	dd	_bb_ZipFile_clearFileList
	dd	_bb_ZipFile_getFileCount
	dd	_bb_ZipFile_setName
	dd	_bb_ZipFile_getName
	dd	_bb_ZipFile_getFileInfo
	dd	_bb_ZipFile_getFileInfoByName
_131:
	db	"ZipWriter",0
_132:
	db	"m_zipFile",0
_133:
	db	"m_compressionLevel",0
_134:
	db	"OpenZip",0
_135:
	db	"($,i)i",0
_136:
	db	"SetCompressionLevel",0
_137:
	db	"AddFile",0
_138:
	db	"AddStream",0
_139:
	db	"(:brl.stream.TStream,$,$)i",0
_140:
	db	"CloseZip",0
	align	4
_130:
	dd	2
	dd	_131
	dd	3
	dd	_132
	dd	_56
	dd	16
	dd	3
	dd	_133
	dd	_50
	dd	20
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_134
	dd	_135
	dd	76
	dd	6
	dd	_136
	dd	_65
	dd	80
	dd	6
	dd	_137
	dd	_100
	dd	84
	dd	6
	dd	_138
	dd	_139
	dd	88
	dd	6
	dd	_140
	dd	_102
	dd	92
	dd	0
	align	4
bb_ZipWriter:
	dd	bb_ZipFile
	dd	bbObjectFree
	dd	_130
	dd	24
	dd	_bb_ZipWriter_New
	dd	_bb_ZipWriter_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_ZipFile_readFileList
	dd	_bb_ZipFile_clearFileList
	dd	_bb_ZipFile_getFileCount
	dd	_bb_ZipFile_setName
	dd	_bb_ZipFile_getName
	dd	_bb_ZipFile_getFileInfo
	dd	_bb_ZipFile_getFileInfoByName
	dd	_bb_ZipWriter_OpenZip
	dd	_bb_ZipWriter_SetCompressionLevel
	dd	_bb_ZipWriter_AddFile
	dd	_bb_ZipWriter_AddStream
	dd	_bb_ZipWriter_CloseZip
_142:
	db	"ZipReader",0
_143:
	db	"ExtractFile",0
_144:
	db	"($,i,$):brl.ramstream.TRamStream",0
_145:
	db	"ExtractFileToDisk",0
_146:
	db	"($,$,i,$)i",0
	align	4
_141:
	dd	2
	dd	_142
	dd	3
	dd	_132
	dd	_56
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
	dd	_134
	dd	_102
	dd	76
	dd	6
	dd	_143
	dd	_144
	dd	80
	dd	6
	dd	_145
	dd	_146
	dd	84
	dd	6
	dd	_140
	dd	_60
	dd	88
	dd	0
	align	4
bb_ZipReader:
	dd	bb_ZipFile
	dd	bbObjectFree
	dd	_141
	dd	20
	dd	_bb_ZipReader_New
	dd	_bb_ZipReader_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_ZipFile_readFileList
	dd	_bb_ZipFile_clearFileList
	dd	_bb_ZipFile_getFileCount
	dd	_bb_ZipFile_setName
	dd	_bb_ZipFile_getName
	dd	_bb_ZipFile_getFileInfo
	dd	_bb_ZipFile_getFileInfoByName
	dd	_bb_ZipReader_OpenZip
	dd	_bb_ZipReader_ExtractFile
	dd	_bb_ZipReader_ExtractFileToDisk
	dd	_bb_ZipReader_CloseZip
_148:
	db	"ZipRamStream",0
_149:
	db	"_data",0
_150:
	db	"ZCreate",0
_151:
	db	"(i,i,i):brl.ramstream.TRamStream",0
	align	4
_147:
	dd	2
	dd	_148
	dd	3
	dd	_149
	dd	_54
	dd	28
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	7
	dd	_150
	dd	_151
	dd	168
	dd	0
	align	4
bb_ZipRamStream:
	dd	brl_ramstream_TRamStream
	dd	bbObjectFree
	dd	_147
	dd	32
	dd	_bb_ZipRamStream_New
	dd	_bb_ZipRamStream_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_brl_stream_TIO_Eof
	dd	_brl_ramstream_TRamStream_Pos
	dd	_brl_ramstream_TRamStream_Size
	dd	_brl_ramstream_TRamStream_Seek
	dd	_brl_stream_TIO_Flush
	dd	_brl_stream_TIO_Close
	dd	_brl_ramstream_TRamStream_Read
	dd	_brl_ramstream_TRamStream_Write
	dd	_brl_stream_TStream_ReadBytes
	dd	_brl_stream_TStream_WriteBytes
	dd	_brl_stream_TStream_SkipBytes
	dd	_brl_stream_TStream_ReadByte
	dd	_brl_stream_TStream_WriteByte
	dd	_brl_stream_TStream_ReadShort
	dd	_brl_stream_TStream_WriteShort
	dd	_brl_stream_TStream_ReadInt
	dd	_brl_stream_TStream_WriteInt
	dd	_brl_stream_TStream_ReadLong
	dd	_brl_stream_TStream_WriteLong
	dd	_brl_stream_TStream_ReadFloat
	dd	_brl_stream_TStream_WriteFloat
	dd	_brl_stream_TStream_ReadDouble
	dd	_brl_stream_TStream_WriteDouble
	dd	_brl_stream_TStream_ReadLine
	dd	_brl_stream_TStream_WriteLine
	dd	_brl_stream_TStream_ReadString
	dd	_brl_stream_TStream_WriteString
	dd	_brl_stream_TStream_ReadObject
	dd	_brl_stream_TStream_WriteObject
	dd	_brl_ramstream_TRamStream_Create
	dd	_bb_ZipRamStream_ZCreate
_153:
	db	"TZipFileList",0
_154:
	db	"zipFile",0
_155:
	db	"FileList",0
_156:
	db	":brl.linkedlist.TList",0
_157:
	db	"IgnoreCase",0
_158:
	db	"IgnorePaths",0
_159:
	db	"create",0
_160:
	db	"(:brl.stream.TStream,i,i):TZipFileList",0
_161:
	db	"findFile",0
_162:
	db	"scanLocalHeader",0
_163:
	db	"extractFilename",0
_164:
	db	"(:SZipFileEntry)i",0
_165:
	db	"deletePathFromFilename",0
_166:
	db	"(*$)i",0
	align	4
_152:
	dd	2
	dd	_153
	dd	3
	dd	_154
	dd	_48
	dd	8
	dd	3
	dd	_155
	dd	_156
	dd	12
	dd	3
	dd	_157
	dd	_50
	dd	16
	dd	3
	dd	_158
	dd	_50
	dd	20
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	7
	dd	_159
	dd	_160
	dd	48
	dd	6
	dd	_123
	dd	_60
	dd	52
	dd	6
	dd	_126
	dd	_127
	dd	56
	dd	6
	dd	_161
	dd	_129
	dd	60
	dd	6
	dd	_162
	dd	_60
	dd	64
	dd	6
	dd	_163
	dd	_164
	dd	68
	dd	6
	dd	_165
	dd	_166
	dd	72
	dd	0
	align	4
bb_TZipFileList:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_152
	dd	24
	dd	_bb_TZipFileList_New
	dd	_bb_TZipFileList_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_TZipFileList_create
	dd	_bb_TZipFileList_getFileCount
	dd	_bb_TZipFileList_getFileInfo
	dd	_bb_TZipFileList_findFile
	dd	_bb_TZipFileList_scanLocalHeader
	dd	_bb_TZipFileList_extractFilename
	dd	_bb_TZipFileList_deletePathFromFilename
_168:
	db	"tm_zip",0
_169:
	db	"tm_sec",0
_170:
	db	"tm_min",0
_171:
	db	"tm_hour",0
_172:
	db	"tm_mday",0
_173:
	db	"tm_mon",0
_174:
	db	"tm_year",0
	align	4
_167:
	dd	2
	dd	_168
	dd	3
	dd	_169
	dd	_50
	dd	8
	dd	3
	dd	_170
	dd	_50
	dd	12
	dd	3
	dd	_171
	dd	_50
	dd	16
	dd	3
	dd	_172
	dd	_50
	dd	20
	dd	3
	dd	_173
	dd	_50
	dd	24
	dd	3
	dd	_174
	dd	_50
	dd	28
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	0
	align	4
bb_tm_zip:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_167
	dd	32
	dd	_bb_tm_zip_New
	dd	_bb_tm_zip_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
_176:
	db	"zip_fileinfo",0
_177:
	db	"tmz_date",0
_178:
	db	":tm_zip",0
_179:
	db	"dosDate",0
_180:
	db	"l",0
_181:
	db	"internal_fa",0
_182:
	db	"external_fa",0
_183:
	db	"getBank",0
_184:
	db	"():brl.bank.TBank",0
	align	4
_175:
	dd	2
	dd	_176
	dd	3
	dd	_177
	dd	_178
	dd	8
	dd	3
	dd	_179
	dd	_180
	dd	16
	dd	3
	dd	_181
	dd	_180
	dd	24
	dd	3
	dd	_182
	dd	_180
	dd	32
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_183
	dd	_184
	dd	48
	dd	0
	align	4
bb_zip_fileinfo:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_175
	dd	40
	dd	_bb_zip_fileinfo_New
	dd	_bb_zip_fileinfo_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_zip_fileinfo_getBank
_222:
	db	"PACK_STRUCT",0
_192:
	db	"fillFromBank",0
_193:
	db	"(:brl.bank.TBank,i)i",0
_223:
	db	"fillFromReader",0
_224:
	db	"(:brl.stream.TStream,i,i,i)i",0
	align	4
_221:
	dd	2
	dd	_222
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_192
	dd	_193
	dd	48
	dd	6
	dd	_223
	dd	_224
	dd	52
	dd	6
	dd	_183
	dd	_184
	dd	56
	dd	0
	align	4
bb_PACK_STRUCT:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_221
	dd	8
	dd	_bb_PACK_STRUCT_New
	dd	_bb_PACK_STRUCT_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_PACK_STRUCT_fillFromBank
	dd	_bb_PACK_STRUCT_fillFromReader
	dd	_bb_PACK_STRUCT_getBank
_186:
	db	"SZIPFileDataDescriptor",0
_187:
	db	"size",0
	align	4
_188:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	49,50
_189:
	db	"CRC32",0
_190:
	db	"CompressedSize",0
_191:
	db	"UncompressedSize",0
	align	4
_185:
	dd	2
	dd	_186
	dd	1
	dd	_187
	dd	_50
	dd	_188
	dd	3
	dd	_189
	dd	_50
	dd	8
	dd	3
	dd	_190
	dd	_50
	dd	12
	dd	3
	dd	_191
	dd	_50
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
	dd	_192
	dd	_193
	dd	48
	dd	0
	align	4
bb_SZIPFileDataDescriptor:
	dd	bb_PACK_STRUCT
	dd	bbObjectFree
	dd	_185
	dd	20
	dd	_bb_SZIPFileDataDescriptor_New
	dd	_bb_SZIPFileDataDescriptor_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_SZIPFileDataDescriptor_fillFromBank
	dd	_bb_PACK_STRUCT_fillFromReader
	dd	_bb_PACK_STRUCT_getBank
_195:
	db	"SZIPFileHeader",0
	align	4
_196:
	dd	bbStringClass
	dd	2147483646
	dd	2
	dw	51,48
_197:
	db	"Sig",0
_198:
	db	"VersionToExtract",0
_199:
	db	"s",0
_200:
	db	"GeneralBitFlag",0
_201:
	db	"CompressionMethod",0
_202:
	db	"LastModFileTime",0
_203:
	db	"LastModFileDate",0
_204:
	db	"DataDescriptor",0
_205:
	db	":SZIPFileDataDescriptor",0
_206:
	db	"FilenameLength",0
_207:
	db	"ExtraFieldLength",0
	align	4
_194:
	dd	2
	dd	_195
	dd	1
	dd	_187
	dd	_50
	dd	_196
	dd	3
	dd	_197
	dd	_50
	dd	8
	dd	3
	dd	_198
	dd	_199
	dd	12
	dd	3
	dd	_200
	dd	_199
	dd	14
	dd	3
	dd	_201
	dd	_199
	dd	16
	dd	3
	dd	_202
	dd	_199
	dd	18
	dd	3
	dd	_203
	dd	_199
	dd	20
	dd	3
	dd	_204
	dd	_205
	dd	24
	dd	3
	dd	_206
	dd	_199
	dd	28
	dd	3
	dd	_207
	dd	_199
	dd	30
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	6
	dd	_192
	dd	_193
	dd	48
	dd	0
	align	4
bb_SZIPFileHeader:
	dd	bb_PACK_STRUCT
	dd	bbObjectFree
	dd	_194
	dd	32
	dd	_bb_SZIPFileHeader_New
	dd	_bb_SZIPFileHeader_Delete
	dd	bbObjectToString
	dd	bbObjectCompare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_SZIPFileHeader_fillFromBank
	dd	_bb_PACK_STRUCT_fillFromReader
	dd	_bb_PACK_STRUCT_getBank
_209:
	db	"SZipFileEntry",0
_210:
	db	"zipFileName",0
_211:
	db	"simpleFileName",0
_212:
	db	"path",0
_213:
	db	"fileDataPosition",0
_214:
	db	"header",0
_215:
	db	":SZIPFileHeader",0
_216:
	db	"():SZipFileEntry",0
_217:
	db	"Less",0
_218:
	db	"EqEq",0
_219:
	db	"Compare",0
_220:
	db	"(:Object)i",0
	align	4
_208:
	dd	2
	dd	_209
	dd	3
	dd	_210
	dd	_96
	dd	8
	dd	3
	dd	_211
	dd	_96
	dd	12
	dd	3
	dd	_212
	dd	_96
	dd	16
	dd	3
	dd	_213
	dd	_50
	dd	20
	dd	3
	dd	_214
	dd	_215
	dd	24
	dd	6
	dd	_59
	dd	_60
	dd	16
	dd	6
	dd	_61
	dd	_60
	dd	20
	dd	7
	dd	_159
	dd	_216
	dd	48
	dd	6
	dd	_217
	dd	_164
	dd	52
	dd	6
	dd	_218
	dd	_164
	dd	56
	dd	6
	dd	_219
	dd	_220
	dd	28
	dd	0
	align	4
bb_SZipFileEntry:
	dd	bbObjectClass
	dd	bbObjectFree
	dd	_208
	dd	28
	dd	_bb_SZipFileEntry_New
	dd	_bb_SZipFileEntry_Delete
	dd	bbObjectToString
	dd	_bb_SZipFileEntry_Compare
	dd	bbObjectSendMessage
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	bbObjectReserved
	dd	_bb_SZipFileEntry_create
	dd	_bb_SZipFileEntry_Less
	dd	_bb_SZipFileEntry_EqEq
	align	4
_bb_PACK_STRUCT_size:
	dd	0
	align	4
_12:
	dd	bbStringClass
	dd	2147483647
	dd	23
	dw	83,116,114,101,97,109,32,105,115,32,110,111,116,32,119,114
	dw	105,116,101,97,98,108,101
_675:
	db	"b",0
	align	4
_15:
	dd	bbStringClass
	dd	2147483647
	dd	3
	dw	98,117,102
	align	4
_18:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	58,58
	align	4
_1:
	dd	bbStringClass
	dd	2147483647
	dd	0
	align	4
_19:
	dd	bbStringClass
	dd	2147483647
	dd	19
	dw	73,110,118,97,108,105,100,32,115,101,101,107,32,111,114,105
	dw	103,105,110
	align	4
_28:
	dd	bbStringClass
	dd	2147483647
	dd	14
	dw	90,105,112,32,102,105,108,101,32,101,114,114,111,114
	align	4
_29:
	dd	bbStringClass
	dd	2147483647
	dd	16
	dw	90,105,112,32,115,116,114,101,97,109,32,101,114,114,111,114
	align	4
_30:
	dd	bbStringClass
	dd	2147483647
	dd	14
	dw	90,105,112,32,100,97,116,97,32,101,114,114,111,114
	align	4
_31:
	dd	bbStringClass
	dd	2147483647
	dd	16
	dw	90,105,112,32,109,101,109,111,114,121,32,101,114,114,111,114
	align	4
_32:
	dd	bbStringClass
	dd	2147483647
	dd	16
	dw	90,105,112,32,98,117,102,102,101,114,32,101,114,114,111,114
	align	4
_33:
	dd	bbStringClass
	dd	2147483647
	dd	17
	dw	90,105,112,32,118,101,114,115,105,111,110,32,101,114,114,111
	dw	114
	align	4
_35:
	dd	bbStringClass
	dd	2147483647
	dd	3
	dw	122,105,112
	align	4
_36:
	dd	bbStringClass
	dd	2147483647
	dd	4
	dw	122,105,112,63
	align	4
_37:
	dd	bbStringClass
	dd	2147483647
	dd	2
	dw	47,47
	align	4
_38:
	dd	bbStringClass
	dd	2147483647
	dd	36
	dw	74,65,78,70,69,66,77,65,82,65,80,82,77,65,89,74
	dw	85,78,74,85,76,65,85,71,83,69,80,79,67,84,78,79
	dw	86,68,69,67
_963:
	db	"b",0
	align	4
_42:
	dd	bbStringClass
	dd	2147483647
	dd	40
	dw	84,90,105,112,82,101,97,100,101,114,46,103,101,116,70,105
	dw	108,101,73,110,102,111,40,41,58,32,73,110,118,97,108,105
	dw	100,32,105,110,100,101,120,32
	align	4
_43:
	dd	bbStringClass
	dd	2147483647
	dd	9
	dw	60,98,97,100,95,100,105,114,62
	align	4
_44:
	dd	bbStringClass
	dd	2147483647
	dd	26
	dw	102,105,108,108,70,114,111,109,66,97,110,107,32,111,117,116
	dw	32,111,102,32,98,111,117,110,100,115
