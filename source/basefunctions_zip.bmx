SuperStrict

'Rem
'bbdoc: Zip Engine
'End Rem
'Module Pub.zipengine

'ModuleInfo "Version: 2.06"
'ModuleInfo "Author: gman"
'ModuleInfo "License: Public Domain"
'ModuleInfo "Credit: This mod makes use if the ZLib C functions by Gilles Vollant (http://www.winimage.com/zLibDll/unzip.html)"
'ModuleInfo "Credit: This mod was initially created by Thomas Mayer"
'ModuleInfo "Credit: Smurftra for his DateTime functions (http://www.blitzbasic.com/codearcs/codearcs.php?code=1726)"
'ModuleInfo "History: 2005/11/14 GG - updated to be compatible with BMAX v1.12"
'ModuleInfo "History: 2005/12/05 GG - updated to be compatible with BMAX v1.14"
'ModuleInfo "History: 2005/12/07 GG - created new ZipRamStream and updated extractfile() to use new stream"
'ModuleInfo "History: 2005/12/14 GG - fixed bug in readFileList() where it was trying to read from an empty (new) file"
'ModuleInfo "History: 2005/12/14 GG - changed to SuperStrict and fixed all missing declarations"
'ModuleInfo "History: 2005/12/17 GG - added clearing of filename and filelist in closezip()"
'ModuleInfo "History: 2006/07/15 GG - added datetime stamps to zipped file information (reported by Grisu)"
'ModuleInfo "History: 2006/07/15 GG - fixed filecount not counting added files (reported by Lomat)"
'ModuleInfo "History: 2006/07/15 GG - added AddStream() method to allow adding a stream as a file"

Import brl.filesystem
Import brl.map


Import Pub.ZLib
Import brl.basic
Import BRL.Stream
Import BRL.System
Import BRL.Retro
Import "zip.c"
Import "unzip.c"
Import "ioapi.c"
Import "bmxsupport.c"

Rem
bbdoc: Append Modes
End Rem
Const APPEND_STATUS_CREATE:Int			= 0
Const APPEND_STATUS_CREATEAFTER:Int		= 1
Const APPEND_STATUS_ADDINZIP:Int		= 2

Rem
bbdoc: Compression methods
End Rem
Const Z_DEFLATED:Int					= 8

Rem
bbdoc: Compression levels
End Rem
Const Z_NO_COMPRESSION:Int				= 0
Const Z_BEST_SPEED:Int				= 1
Const Z_BEST_COMPRESSION:Int			= 9
Const Z_DEFAULT_COMPRESSION:Int		= -1

Rem
bbdoc: Compare modes
End Rem
Const UNZ_CASE_CHECK:Int				= 1
Const UNZ_NO_CASE_CHECK:Int			= 2

Rem
bbdoc: Result Codes
End Rem
Const UNZ_OK:Int						= 0
Const UNZ_END_OF_LIST_OF_FILE:Int		= -100
Const UNZ_EOF:Int						= 0
Const UNZ_PARAMERROR:Int				= -102
Const UNZ_BADZIPFILE:Int				= -103
Const UNZ_INTERNALERROR:Int			= -104
Const UNZ_CRCERROR:Int				= -105

Const ZLIB_FILEFUNC_SEEK_CUR% = 1
Const ZLIB_FILEFUNC_SEEK_END% = 2
Const ZLIB_FILEFUNC_SEEK_SET% = 0

Rem
Return codes for the compression/decompression functions. Negative
values are errors, positive values are used for special but normal events.
EndRem
Const Z_OK:Int = 0
Const Z_STREAM_END:Int = 1
Const Z_NEED_DICT:Int = 2
Const Z_ERRNO:Int = -1
Const Z_STREAM_ERROR:Int = -2
Const Z_DATA_ERROR:Int = -3
Const Z_MEM_ERROR:Int = -4
Const Z_BUF_ERROR:Int = -5
Const Z_VERSION_ERROR:Int = -6

Extern

Rem
Open a zip file for unzip, using the specified IO functions
End Rem
Function unzOpen2:Byte Ptr(zipFileName$z, pzlib_filefunc_def:Byte Ptr)

Rem
Give the current position in uncompressed data
End Rem
Function unztell:Int(file:Byte Ptr)





'Rem
'Set the current file offset
'End Rem
'Function unzSetOffset:Int(zipFilePtr:Byte Ptr, pos:Int)

'Rem
'Get the current file offset
'EndRem
'Function unzGetOffset:Int(zipFilePtr:Byte Ptr)

EndExtern


Type TBufferedStream Extends TStream
	Field innerStream:TStream
	Field pos_%, start_%, end_%
	Field buf:Byte[]
	Field bufPtr:Byte Ptr
	Field bias1%
	Field bias2%
	
	?bmxng
	Method Pos:Long()
	?not bmxng
	Method Pos:Int()
	?
		Return pos_
	End Method

	?bmxng
	Method Size:Long()
	?not bmxng
	Method Size:Int()
	?
		Return innerStream.Size()
	End Method

?Not bmxng
	Method Seek:Int(pos:Int)
?bmxng
	Method Seek:Long( pos:Long, whence:Int = SEEK_SET_ )
?
		pos_ = pos
		If pos_ < start_ Then
			start_ = Max(pos_ - bias1, 0)
			innerStream.Seek(start_)
			end_ = start_ + innerStream.Read(bufPtr, buf.Length)
		ElseIf pos_ > end_ Then
			start_ = pos_ - bias2
			innerStream.Seek(start_)
			end_ = start_ + innerStream.Read(bufPtr, buf.Length)
		EndIf
		Return pos_
	End Method

?Not bmxng
	Method Read:Int(dst:Byte Ptr, count:Int)
?bmxng
	Method Read:Long(dst:Byte Ptr, count:Long)
?
		' NOTE: no doubt it could be optimized further, but hey, if it works
?Debug
		Local countBackup% = count
?
		Local initialPos% = pos_
		Assert pos_ >= start_ And pos_ <= end_ Else "Invalid position (" + pos_ + ", should be in [" + start_ + "," + end_ + "] )"
		Assert count >= 0 Else "Negative count"
		Repeat
			
			Assert(pos_ >= start_ And pos_ <= end_)
			If count <= end_-pos_ Then
				' All data already in the buffer, copy it and return
				MemCopy(dst, bufPtr+(pos_-start_), count)
				pos_ :+ count
?Debug
				Assert (pos_ - initialPos) <= countBackup
?				
				Return pos_ - initialPos
			Else
				If end_-pos_ > 0 Then
					MemCopy(dst, bufPtr+(pos_-start_), end_-pos_)
					count :- end_-pos_
					dst :+ end_-pos_
					pos_ = end_
					start_ = end_
				EndIf
					
				If count >= buf.Length Then
					' Read data right into the target buffer
					Local readBytes% = innerStream.Read(dst, buf.Length)
					dst :+ readBytes
					pos_ :+ readBytes
					start_ = pos_
					end_ = pos_
					count :- readBytes
					If readBytes < buf.Length Then
						' The underlying stream couldn't read everything, so we  return
?Debug
						Assert (pos_ - initialPos) <= countBackup
?				
						Return pos_ - initialPos
					EndIf
				Else
					' Read more data into temp buffer
					start_ = pos_
					Local readBytes% = innerStream.Read(bufPtr, buf.length)
					end_ = pos_ + readBytes
					' Copy data to target buffer
					Local cnt% = Min(count, readBytes)
					MemCopy(dst, bufPtr, cnt)
					pos_ :+ cnt
					count :- cnt
					dst :+ cnt
					Return pos_ - initialPos
				EndIf
			EndIf
		Forever
	End Method

?Not bmxng
	Method Write:Int(buf:Byte Ptr, count:Int)
?bmxng
	Method Write:Long(buf:Byte Ptr, count:Long)
?
		RuntimeError "Stream is not writeable"
		Return 0	
	End Method

	Method Flush:Int()
		Return innerStream.Flush()
	End Method

	Method Close:Int()
		Return innerStream.Close()
	End Method
End Type

Rem
bbdoc: 	Creates and return a buffered stream from around an existing stream (or url). 
		If the stream to wrap is already a buffered stream, returns the stream unchanged 
		(unless you set bForce to True).
		To change the size of the buffer, modify the value of bufSize (specified in bytes).
		Making the buffer bigger can enhance performance, at the expense of memory consumption.
EndRem
Function CreateBufferedStream:TStream(url:Object, bufSize%=4096, bForce%=False)
	Local stream:TStream = TStream(url)
	If stream = Null Then
		stream = ReadStream(url)
	EndIf
	If stream = Null Then
		Return Null
	ElseIf TBufferedStream(stream) = Null Then
		Return CreateBufferedStreamImpl(stream, bufSize)
	Else
		Return stream
	EndIf
End Function

Private

Function CreateBufferedStreamImpl:TBufferedStream(innerStream:TStream, bufSize%=8192)
	If bufSize < 1024 Then
		bufSize = 1024
	EndIf
	Local s:TBufferedStream = New TBufferedStream
	s.innerStream = innerStream
	s.buf = New Byte[bufSize]
	s.bufPtr = s.buf
	s.bias1 = (s.buf.Length/3)*2
	s.bias2 = (s.buf.Length/3)
	s.pos_ = innerStream.Pos()
	
	Return s
End Function

Type TBufferedStreamFactory Extends TStreamFactory
	Method CreateStream:TStream (url:Object, proto:String, path:String, readable:Int, writeable:Int)
		If proto="buf" And writeable = False
			Local innerStream:TStream = ReadStream(path)
			If innerStream <> Null Then
				Return CreateBufferedStream(innerStream)
			EndIf
		EndIf
	End Method
End Type

New TBufferedStreamFactory






Type TZLibFileFuncDef
	Field open_file_func:Byte Ptr(bmxStream:TStream, filename:Byte Ptr, mode:Int)
	Field read_file_func:Int(bmxStream:TStream, stream:Byte Ptr, buf:Byte Ptr, size:Int)
	Field write_file_func:Int(bmxStream:TStream, stream:Byte Ptr, buf:Byte Ptr, size:Int)
	Field tell_file_func:Int(bmxStream:TStream, stream:Byte Ptr)
	Field seek_file_func:Int(bmxStream:TStream, stream:Byte Ptr, offset:Int, origin:Int)
	Field close_file_func:Int(bmxStream:TStream, stream:Byte Ptr)
	Field testerror_file_func:Int(bmxStream:TStream, stream:Byte Ptr)
	Field bmxStream:TStream
End Type


Type TZipStream Extends TStream
	Field innerStream:TStream
	Field unzfile:Byte Ptr
	Field ioFileFuncDef:TZLibFileFuncDef
	Field size_:Int
	Field pos_:Int
	Field zipUrl$
	Global trash:Byte[] = New Byte[1024]
	
	Global gPasswordMap:TMap = New TMap
	
	Function GetCanonicalZipPath$(zipPath$)
		If zipPath.Find("::") < 0 Then
			' No protocol specified, we get the absolute path to be able to handle correctly the use of relative file pathes
			zipPath = RealPath(zipPath)
		EndIf
?Win32			
		zipPath = zipPath.ToLower().Replace("/", "\\")
?
		Return zipPath
	End Function
	
	Function SetPassword(zipPath$, password$)
		gPasswordMap.Insert(GetCanonicalZipPath(zipPath), password)
	End Function
	
	Function ClearPassword(zipPath$)
		gPasswordMap.Remove(GetCanonicalZipPath(zipPath))
	End Function
	
	Function GetPassword$(zipPath$)
		Return String(gPasswordMap.ValueForKey(GetCanonicalZipPath(zipPath)))
	End Function
	
	Method OpenCurrentFile_:Int()
		Local password$ = GetPassword(zipUrl)
		If password <> "" Then
			Return unzOpenCurrentFilePassword(unzfile, password)
		Else
			Return unzOpenCurrentFile(unzfile)
		EndIf
	End Method
	
	Method Open_:TZipStream(zipUrl$, fileUrl$, innerStream:TStream)		
		Self.zipUrl = zipUrl
		'DebugLog "Open_" + zipUrl + " # " + fileUrl
		Local filePath$ = fileUrl
		Local lastProtoPos% = filePath.FindLast("::")
		If lastProtoPos >= 0 Then
			' Remove the protocols, non meaningful here
			filePath = filePath[lastProtoPos+2..]
		EndIf
		
		
		ioFileFuncDef = New TZLibFileFuncDef
		ioFileFuncDef.open_file_func = open_file_func 
		ioFileFuncDef.read_file_func = read_file_func 
		ioFileFuncDef.tell_file_func = tell_file_func 
		ioFileFuncDef.seek_file_func = seek_file_func 
		ioFileFuncDef.close_file_func = close_file_func 
		ioFileFuncDef.testerror_file_func = testerror_file_func
		
		ioFileFuncDef.bmxStream = innerStream

		'Print Int(Byte Ptr(ioFileFuncDef.bmxStream))'!!!
		
		unzfile = unzOpen2(zipUrl, ioFileFuncDef) ' NOTE: zipUrl not really useful here
		If unzfile = Null Then
			'DebugLog ("KO: " + zipUrl)
			Return Null
		Else
			If unzLocateFile(unzfile , filepath, 0) <> 0 Then
				'DebugLog ("unzLocateFile KO: " + filePath)
				Return Null
			EndIf
			Local password$ = GetPassword(zipUrl)
			'Local openRet%
			'If password <> "" Then
			'	openRet = unzOpenCurrentFilePassword(unzfile, password)
			'Else
			'	openRet = unzOpenCurrentFile(unzfile)
			'EndIf
			'If openRet = 0 Then
			If OpenCurrentFile_() = 0 Then
				'DebugLog ("OK: " + filePath)
				size_ = unzGetCurrentFileSize (unzfile)
				Self.innerStream = innerStream ' Just to keep the GC from collecting it
				Return Self
			Else
				Return Null
			EndIf
		EndIf
	End Method
	
	Function open_file_func:Byte Ptr(bmxStream:TStream, filename:Byte Ptr, mode:Int)
		' Do nothing, stream already open
		'DebugLog "open_file_func" + Int(Byte Ptr(bmxStream))
		Return Byte Ptr(bmxStream) ' return dummy address
	End Function
	
	Function read_file_func:Int(bmxStream:TStream, stream:Byte Ptr, buf:Byte Ptr, size:Int)
		'DebugLog "read_file_func"
		Return bmxStream.Read(buf, size)
	End Function
	
	Function write_file_func:Int(bmxStream:TStream, stream:Byte Ptr, buf:Byte Ptr, size:Int)
		' Do nothing (not writeable)
		'DebugLog "write_file_func"
	End Function
	
	Function tell_file_func:Int(bmxStream:TStream, stream:Byte Ptr)
		'DebugLog "tell_file_func"
		Return bmxStream.Pos()
	End Function
	
	Function seek_file_func:Int(bmxStream:TStream, stream:Byte Ptr, offset:Int, origin:Int)
		'DebugLog "seek_file_func"
		'Print Int(Byte Ptr(bmxStream))'!!!
		Select origin
			Case ZLIB_FILEFUNC_SEEK_SET
				bmxStream.Seek(offset)
			Case ZLIB_FILEFUNC_SEEK_CUR
				bmxStream.Seek(bmxStream.Pos()+offset)
			Case ZLIB_FILEFUNC_SEEK_END
				bmxStream.Seek(bmxStream.Size()-offset)
			Default
				RuntimeError("Invalid seek origin")
		End Select
		Return 0
	End Function
	
	Function close_file_func:Int(bmxStream:TStream, stream:Byte Ptr)
		'DebugLog "close_file_func"
		bmxStream.Close()
		Return 0
	End Function
	
	Function testerror_file_func:Int(bmxStream:TStream, stream:Byte Ptr)
		'DebugLog "testerror_file_func"
		'Return bmxStream.Eof() ' !!! ?
		Return 0
	End Function
		
	?bmxng
	Method Pos:Long()
	?not bmxng
	Method Pos:Int()
	?
		'DebugLog "Pos " + unztell(unzfile)
		'Return unztell(unzfile)
		Return pos_
	End Method

?Not bmxng
	Method Size:Int()
?bmxng
	Method Size:Long()
?
		'DebugLog "Size " + size_
		Return size_
	End Method

?Not bmxng
	Method Seek:Int(newPos:Int)
?bmxng
	Method Seek:Long( newPos:Long, whence:Int = SEEK_SET_ )
?
		If newPos <> pos_ Then
			' WARN: this implementation of Seek is extremely inefficient 
			' (we reopen the file - if needed - and then read and discard the needed amount of bytes)
			' For this reason, the "zip" protocol adds a TBufferedStream on top of the TZipStream, in order to
			' amortize the cost of seeking (and of reading itself).
			' Thanks to the buffered stream, small files will be entirely loaded in memory, giving a fast access,
			' and big files will be loaded blocks by blocks, allowing a fast access without the downside of 
			' allocating big chunks of memory.
			If newPos < pos_ Then
				unzCloseCurrentFile(unzfile)	' Close the file
				OpenCurrentFile_()				' Reopen it
				pos_ = 0
			EndIf
			DiscardBytes_( int(newPos - pos_) )
		EndIf
		Assert Pos() = newPos Else "TZipStream.Seek : Pos() should be " + newPos + " but is " + Pos()
		Return Pos()
	End Method
	
	Method DiscardBytes_(count%)
		Assert count >= 0 Else "TZipStream.DiscardBytes_ : negative count (" + count + ")"
		Repeat
			If count > trash.Length Then
				Read(trash, trash.Length)
				count :- trash.Length
			Else
				If count > 0 Then
					Read(trash, count)
				EndIf
				Exit
			EndIf			
		Forever
	End Method

?Not bmxng
	Method Read:Int(buf:Byte Ptr, count:Int)
?bmxng
	Method Read:Long(buf:Byte Ptr, count:Long)
?
		'DebugLog "Read"
		'DebugStop
		Assert unzfile Else "Attempt to read from closed stream"
		Local ret% = unzReadCurrentFile(unzfile , buf, int(count))
		'DebugLog "Read(post) " + ret
		CheckZlibError(ret)
		pos_ :+ ret
		Return ret
	End Method

?Not bmxng
	Method Write:Int(buf:Byte Ptr, count:Int)
?bmxng
	Method Write:Long(buf:Byte Ptr, count:Long)
?
		'DebugLog "Write"
		RuntimeError "Stream is not writeable"
		Return 0	
	End Method

	Method Flush:Int()
		'DebugLog "Flush"
	End Method

	Method Close:Int()
		'DebugLog "Close"
		If unzfile <> Null Then
			unzCloseCurrentFile(unzfile)
			unzClose(unzfile)
		EndIf
	End Method
	
	
	Function CheckZLibError(code%)
		Local msg$
		Select code
			Case Z_ERRNO        	msg$ = "Zip file error"
			Case Z_STREAM_ERROR 	msg$ = "Zip stream error"
			Case Z_DATA_ERROR   	msg$ = "Zip data error"
			Case Z_MEM_ERROR    	msg$ = "Zip memory error"
			Case Z_BUF_ERROR    	msg$ = "Zip buffer error"
			Case Z_VERSION_ERROR 	msg$ = "Zip version error"
			Default	
				' No error, retrun silently
				Return
		End Select
		
		Local ex:TZipStreamReadException = New TZipStreamReadException
		ex.msg = msg
		Throw ex
	End Function
End Type



Type TZipStreamFactory Extends TStreamFactory
	Method CreateStream:TStream (url:Object, proto:String, path:String, readable:Int, writeable:Int)
		'DebugStop
		If (proto="zip" Or proto="zip?") And writeable = False
			Local sepPos:Int = path.Find("//")
			If sepPos >= 0 Then
				Local zipUrl$ = path$[0..sepPos]
?Win32				
				zipUrl = zipUrl.Replace("/", "\\")
?
				Local innerStream:TStream = ReadStream(zipUrl)
				If innerStream <> Null Then
					Local filePath$ = path$[sepPos+2..]
					Local zipStream:TStream = (New TZipStream).Open_(zipUrl, filePath, innerStream)
					If zipStream <> Null Then
						Return CreateBufferedStream(zipStream)
					Else
						If proto="zip?" Then
							'Special protocol "zip?" means "attempt to find it in zip, or else attempt other protocols
							Return ReadStream(filePath)
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	End Method
End Type

New TZipStreamFactory

Public

Rem
bbdoc: This exception is thrown  in the event of read error in a zip file.
EndRem
Type TZipStreamReadException Extends TStreamReadException
	Field msg$

	Method ToString$()
		Return msg
	End Method
End Type


Rem
bbdoc: Registers a password for a given zip file. Must be done before attempting to read any password protected zip file (or else, a TZipStreamReadException is thrown)
End Rem
Function SetZipStreamPasssword(zipUrl$, password$)
	TZipStream.SetPassword(zipUrl, password)
End Function

Rem
bbdoc: Clears a password for a given zip file.
End Rem
Function ClearZipStreamPasssword(zipUrl$)
	TZipStream.ClearPassword(zipUrl)
End Function


Extern

Rem
bbdoc: Open new zip file (returns zipFile pointer)
End Rem
Function zipOpen:Byte Ptr( fileName$z, append:Int )

Rem
bbdoc: Closes an open zip file
End Rem
Function zipClose( zipFilePtr:Byte Ptr, archiveName$z )

Rem
bbdoc: Open a file inside the zip file
End Rem
Function zipOpenNewFileInZip( zipFilePtr:Byte Ptr, fileName$z, zip_fileinfo:Byte Ptr, ..
							extrafield_local:Byte Ptr, size_extrafield_local:Int, ..
							extrafield_global:Byte Ptr, size_extrafield_global:Int, ..
							comment$z, compressionMethod:Int, ..
							level:Int )
							
Rem
bbdoc: Open a file inside the zip file using a password
End Rem
Function zipOpenNewFileWithPassword( zipFilePtr:Byte Ptr, fileName$z, zip_fileinfo:Byte Ptr, ..
							extrafield_local:Byte Ptr, size_extrafield_local:Int, ..
							extrafield_global:Byte Ptr, size_extrafield_global:Int, ..
							comment$z, compressionMethod:Int, ..
							level:Int, password$z )

Rem
bbdoc: Write into a zip file
End Rem
Function zipWriteInFileInZip( zipFilePtr:Byte Ptr, buffer:Byte Ptr, bufferLength:Int )

Rem
bbdoc: Open a zip file for unzip
End Rem
Function unzOpen:Byte Ptr( zipFileName$z )

Rem
bbdoc: Return status of desired file and sets the unzipped focus to it
End Rem
Function unzLocateFile:Int( zipFilePtr:Byte Ptr, fileName$z, caseCheck:Int )

Rem
bbdoc: Opens the currently focused file
End Rem
Function unzOpenCurrentFile:Int( zipFilePtr:Byte Ptr )

Rem
Gets info about the current file
End Rem
Function unzGetCurrentFileSize:Int( file:Byte Ptr )


Rem
bbdoc: Opens the currently focused file using a password
End Rem
Function unzOpenCurrentFilePassword:Int(file:Byte Ptr, password$z)


Rem
bbdoc: Read current file, returns number of bytes
End Rem
Function unzReadCurrentFile:Int( zipFilePtr:Byte Ptr, buffer:Byte Ptr, size:Int )

Rem
bbdoc: Close current file
End Rem
Function unzCloseCurrentFile( zipFilePtr:Byte Ptr )

Rem
bbdoc: Close unzip zip file
End Rem
Function unzClose( zipFilePtr:Byte Ptr )



EndExtern

Type ZipFile Abstract
	Field m_name:String
	Field m_zipFileList:TZipFileList=Null

	Rem
		bbdoc: Stores information about the files in a zip file into a list
	End Rem	
	Method readFileList()
		clearFileList()
		If m_name.length>0 And FileSize(m_name)>0 ' check to make sure the file isnt empty
			Local read:TStream=ReadFile(m_name)
			If read<>Null
				m_zipFileList=TZipFileList.Create(read,False,False)
				CloseStream(read)
			EndIf	
		EndIf
	EndMethod
	
	Rem
		bbdoc: Clears the stored list of file information
	End Rem	
	Method clearFileList()
		m_zipFileList=Null
	EndMethod
	
	Rem
		bbdoc: Returns the # of files contained in the zip file
	End Rem	
	Method getFileCount:Int()
		If m_zipFileList Then Return m_zipFileList.getFileCount() Else Return 0
	EndMethod

	Rem
		bbdoc: Stores the name of the current zip file
	End Rem		
	Method setName(zipName:String)
		m_name=zipName
	EndMethod
	
	Rem
		bbdoc: Returns the name of the name of the zip
	End Rem		
	Method getName:String()
		Return m_name
	EndMethod

	Rem
		bbdoc: Returns the SZipFileEntry object information for a file entry in the ZIP 
	End Rem
	Method getFileInfo:SZipFileEntry(index:Int)
		Return m_zipFileList.getFileInfo(index)
	EndMethod

	Rem
		bbdoc: Locates a file entry by name and returns its SZipFileEntry
	EndRem
	Method getFileInfoByName:SZipFileEntry(simpleFilename:String)
		Return m_zipFileList.findFile(simpleFilename)
	EndMethod

EndType

Type ZipWriter Extends ZipFile
	Field m_zipFile:Byte Ptr = Null
	Field m_compressionLevel:Int = Z_DEFAULT_COMPRESSION
	
	Rem
		bbdoc: Opens a zip file for writing
	End Rem
	Method OpenZip:Int( name:String, append:Int )
		If ( append ) Then
			m_zipFile = zipOpen( name, APPEND_STATUS_ADDINZIP )
		Else
			m_zipFile = zipOpen( name, APPEND_STATUS_CREATE )
		End If
		
		If ( m_zipFile ) Then
			setName(name)  ' store the name
			readFileList() ' read in the file information
			Return True
		Else
			Return False
		End If
	End Method

	Rem
		bbdoc: Set level of compression
	End Rem
	Method SetCompressionLevel( level:Int )
		If ( m_zipFile ) Then
			m_compressionLevel = level
		End If
	End Method

	Rem
		bbdoc: Adds a file to the zip
	End Rem
	Method AddFile( fileName:String, password:String="" )
		If ( m_zipFile ) Then
			Local inFile:TStream = OpenFile( fileName )
			
			If ( inFile ) Then
				Local inSize:Int = StreamSize(inFile)

				Local ftime : Int = FileTime(fileName)
				Local pointer : Int Ptr = Int Ptr(localtime_(Varptr(ftime)))

				' populate the info structure with datetime
				Local info:zip_fileinfo=New zip_fileinfo
				info.tmz_date.tm_sec=pointer[0]
				info.tmz_date.tm_min=pointer[1]
				info.tmz_date.tm_hour=pointer[2]
				info.tmz_date.tm_mday=pointer[3]
				info.tmz_date.tm_mon=pointer[4]
				info.tmz_date.tm_year=(pointer[5]+1900)
				
				' create the bank for passing the structure to the C func
				Local info_b:TBank=info.getBank()

				If password.length=0
					' Open the test.txt as a new entry inside the zip
					zipOpenNewFileInZip( m_zipFile, fileName, BankBuf(info_b), Null, Null, Null, Null, Null, ..
										Z_DEFLATED, m_compressionLevel )
				Else
					' Open the test.txt as a new entry inside the zip
					zipOpenNewFileWithPassword( m_zipFile, fileName, BankBuf(info_b), Null, Null, Null, Null, Null, ..
										Z_DEFLATED, m_compressionLevel, password )
				EndIf
		
				' Write the file into the zip
				zipWriteInFileInZip( m_zipFile, LoadByteArray(inFile), inSize )
				
				' add this file to the file list
				Local entry:SZipFileEntry=SZipFileEntry.Create()
				entry.zipFileName=fileName
				entry.simpleFileName=StripDir(fileName)
				entry.path=ExtractDir(fileName)
				
				If Not m_zipFileList Then m_zipFileList=New TZipFileList
				m_zipFileList.FileList.AddLast(entry)				
			End If			
		End If
	End Method

	Rem
		bbdoc: Adds a file to the zip from a stream
	End Rem
	Method AddStream( data:TStream, fileName:String, password:String="" )
		If ( m_zipFile ) Then
			Local inFile:TStream = data
			
			If ( inFile ) Then
				Local inSize:Int = StreamSize(inFile)

				Local tDate:String = CurrentDate()
				Local tTime:String = CurrentTime()
				
				Local ftime : Int = FileTime(fileName)
'				Local pointer : Int Ptr = Int Ptr(localtime_(Varptr(ftime)))

				' populate the info structure with datetime
				Local info:zip_fileinfo=New zip_fileinfo
				info.tmz_date.tm_sec=Int(tTime[7..])
				info.tmz_date.tm_min=Int(tTime[3..6])
				info.tmz_date.tm_hour=Int(tTime[..2])
				info.tmz_date.tm_mday=Int(tDate[..2])
				info.tmz_date.tm_mon=(Instr("JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC", tDate[3..6].ToUpper(), 1) / 3)
				info.tmz_date.tm_year=Int(tDate[tDate.length - 4..])
				
				' create the bank for passing the structure to the C func
				Local info_b:TBank=info.getBank()

				If password.length=0
					' Open the test.txt as a new entry inside the zip
					zipOpenNewFileInZip( m_zipFile, fileName, BankBuf(info_b), Null, Null, Null, Null, Null, ..
										Z_DEFLATED, m_compressionLevel )
				Else
					' Open the test.txt as a new entry inside the zip
					zipOpenNewFileWithPassword( m_zipFile, fileName, BankBuf(info_b), Null, Null, Null, Null, Null, ..
										Z_DEFLATED, m_compressionLevel, password )
				EndIf
		
				' Write the file into the zip
				zipWriteInFileInZip( m_zipFile, LoadByteArray(inFile), inSize )
				
				' add this file to the file list
				Local entry:SZipFileEntry=SZipFileEntry.Create()
				entry.zipFileName=fileName
				entry.simpleFileName=StripDir(fileName)
				entry.path=ExtractDir(fileName)
				
				If Not m_zipFileList Then m_zipFileList=New TZipFileList
				m_zipFileList.FileList.AddLast(entry)				
			End If			
		End If
	End Method

	Rem
		bbdoc: Closes a zip file
	End Rem
	Method CloseZip( description:String = "" )
		If ( m_zipFile ) Then
			zipClose( m_zipFile, description )				
		End If
		setName("") ' clear out the name
		clearFileList() ' clear out the header info
	End Method
End Type

Type ZipReader Extends ZipFile

	Field m_zipFile:Byte Ptr = Null
	
	Rem
		bbdoc: Opens a zip file for reading
	End Rem
	Method OpenZip:Int( name:String )
		m_zipFile = unzOpen( name )
		
		If ( m_zipFile ) Then
			setName(name)  ' store the name
			readFileList() ' read in the file information
			Return True
		Else
			Return False
		End If
	End Method

	Rem
		bbdoc: Extracts a file from the zip to RAM
	End Rem
	Method ExtractFile:TRamStream( fileName:String, caseSensitive:Int = False, password:String="" )
		If ( m_zipFile ) Then
			Local result:Int
			
			If ( caseSensitive ) Then
				result = unzLocateFile( m_zipFile, fileName, UNZ_CASE_CHECK )
			Else
				result = unzLocateFile( m_zipFile, fileName, UNZ_NO_CASE_CHECK )
			End If
					
			If ( result = UNZ_OK ) Then
				If password.length=0
					result = unzOpenCurrentFile( m_zipFile)
				Else
					result = unzOpenCurrentFilePassword( m_zipFile, password)
				EndIf
				
				If ( result = UNZ_OK ) Then
					Local entrySize:Int = unzGetCurrentFileSize( m_zipFile )
					
					Local stream:TRamStream=ZipRamStream.ZCreate(entrySize,True,False)
			'		Local numberOfBytes:Int = unzReadCurrentFile ( m_zipFile, stream._buf, entrySize )
					
					Return stream
				Else
					Return Null
				End If												
			Else
				Return Null
			End If
		End If
	End Method

	Rem
		bbdoc: Extracts a file from the zip to disk
	End Rem
	Method ExtractFileToDisk( fileName:String, outputFileName:String, caseSensitive:Int = False, password:String="" )
		Local outFile:TStream = WriteFile ( outputFileName )
		Local extractedFile:TRamStream = ExtractFile ( fileName, caseSensitive, password )
		
		If ( outFile And extractedFile ) Then
			CopyStream( extractedFile, outFile )
		End If 

		CloseStream( outFile )
	End Method

	Rem
		bbdoc: Closes a zip file
	End Rem
	Method CloseZip()
		If ( m_zipFile ) Then
			unzClose( m_zipFile )	
		End If
		setName("") ' clear out the name
		clearFileList() ' clear out the header info
	End Method
End Type

' ----------------------------------------------------------------
' the supporting cast
' ----------------------------------------------------------------

Type ZipRamStream Extends TRamStream
	Field _data:Byte[]
	
	Function ZCreate:TRamStream( size:Int,readable:Int,writeable:Int )
		Local stream:ZipRamStream=New ZipRamStream
		stream._data=New Byte[size]
		stream._pos=0
		stream._size=size
		stream._buf=Varptr(stream._data[0])
		stream._read=readable
		stream._write=writeable
		Return stream
	End Function	
EndType

Type TZipFileList

	Field zipFile:TStream
	Field FileList:TList ' core::array<SZipFileEntry>
	Field IgnoreCase:Int
	Field IgnorePaths:Int

	Method New()
		FileList=New TList
	EndMethod

	Rem
		bbdoc: Creates a new TZipFileList object
	End Rem
	Function Create:TZipFileList(file:TStream,bIgnoreCase:Int,bIgnorePaths:Int)
		If Not file Then Return Null
		
		Local retval:TZipFileList=New TZipFileList
		retval.zipFile=file
		retval.IgnoreCase=bIgnoreCase
		retval.IgnorePaths=bIgnorePaths

		' scan Local headers
		While retval.scanLocalHeader() Wend

		' prepare file index For binary search
		retval.FileList.sort()
		Return retval		
	EndFunction
	
	Rem
		bbdoc: Returns count of files in archive
	End Rem
	Method getFileCount:Int()
		Return FileList.Count()
	EndMethod

	Rem
		bbdoc: Returns information about a file entry in the ZIP
	End Rem
	Method getFileInfo:SZipFileEntry(index:Int)
		If index<0 Or index>=FileList.Count() Then RuntimeError "TZipReader.getFileInfo(): Invalid index "+index
		Return SZipFileEntry(FileList.ValueAtIndex(index))
	EndMethod

	Rem
		bbdoc: Locates a file entry by name and returns its SZipFileEntry
	EndRem
	Method findFile:SZipFileEntry(simpleFilename:String)
		Local retval:SZipFileEntry=Null
		
		Local entry:SZipFileEntry=SZipFileEntry.Create()
		entry.simpleFileName = simpleFilename
	
		If (IgnoreCase) Then entry.simpleFileName=entry.simpleFileName.ToLower()
	
		If (IgnorePaths) Then deletePathFromFilename(entry.simpleFileName)

		Local link:TLink=FileList.FindLink(entry)
		
		If link
			retval=SZipFileEntry(link.Value())
		Else
			?Debug
			For Local i:Int=0 To FileList.Count()-1
				If (getFileInfo(i).simpleFileName = entry.simpleFileName)
					DebugLog("File "+entry.simpleFileName+" in archive but Not found.")
					Exit
				EndIf
			Next
			?
		EndIf
		
		Return retval
	EndMethod

	Rem
		bbdoc: Scans for a local header, returns false if there is no more local file header.
	EndRem
	Method scanLocalHeader:Int()

	'	Local tempbank:TBank
	
		Local entry:SZipFileEntry=SZipFileEntry.Create()
		entry.fileDataPosition = 0
		
		' populate the header with what was read		
		entry.header.fillFromReader(zipFile,SZIPFileHeader.size,0,0)
						
		If entry.header.Sig <> $04034b50 Then Return False ' Local file headers End here.
	
		' read filename
		entry.zipFileName=ReadString(zipFile,entry.header.FilenameLength)

		extractFilename(entry)
				
		' move forward length of extra field.
		If (entry.header.ExtraFieldLength)	
			SeekStream(zipFile,StreamPos(zipFile)+entry.header.ExtraFieldLength)
		EndIf
		
		' If bit 3 was set, read DataDescriptor, following after the compressed data
		If (entry.header.GeneralBitFlag & ZIP_INFO_IN_DATA_DESCRIPTOR)
			' read data descriptor
			entry.header.DataDescriptor.fillFromReader(zipFile,SZIPFileDataDescriptor.size,0,0)
		EndIf
				
		' store position in file
		entry.fileDataPosition = StreamPos(zipFile)
		
		'DebugLog(StreamPos(zipFile)+entry.header.DataDescriptor.CompressedSize)
		
		' move forward length of data
		SeekStream(zipFile,StreamPos(zipFile)+entry.header.DataDescriptor.CompressedSize)
		
		?Debug
		DebugLog("added file "+entry.simpleFileName+" from archive")
		?
		
		FileList.AddLast(entry)
	
		Return True
	EndMethod

	Rem
		bbdoc: Splits filename from zip file into useful filenames And paths
	EndRem
	Method extractFilename(entry:SZipFileEntry)

		' check length of filename
		If Not entry.header.FilenameLength Then Return
	
		' change the case if ignore is on
		If (IgnoreCase) Then entry.zipFileName=entry.zipFileName.ToLower()
	
		' make sure there is a path
		Local thereIsAPath:Int=(ExtractDir(entry.zipFileName)<>"<bad_dir>")
	
		' store just the filename
		entry.simpleFileName = StripDir(entry.zipFileName)
		
		' store an empty path
		If (thereIsAPath) Then entry.path = ExtractDir(entry.zipFileName) Else entry.path=""
	
		' simpleFileName must be zipFileName if not to ignore paths
		If Not IgnorePaths
			entry.simpleFileName = entry.zipFileName  ' thanks To Pr3t3nd3r For this fix
		EndIf
	EndMethod

	Rem
		bbdoc: Deletes the path from a filename
	EndRem
	Method deletePathFromFilename(filename:String Var)
		filename=StripDir(filename)
	EndMethod

EndType

' the fields crc-32, compressed size
' And uncompressed size are set To zero in the Local
' header
Const ZIP_INFO_IN_DATA_DESCRIPTOR:Short = $0008  

'/* tm_zip contain date/time info */
Type tm_zip
    Field tm_sec:Int	'/* seconds after the minute - [0,59] */
    Field tm_min:Int    '/* minutes after the hour - [0,59] */
    Field tm_hour:Int   '/* hours since midnight - [0,23] */
    Field tm_mday:Int   '/* day of the month - [1,31] */
    Field tm_mon:Int    '/* months since January - [0,11] */
    Field tm_year:Int   '/* years - [1980..2044] */
EndType
															
Type zip_fileinfo
	Field tmz_date:tm_zip=New tm_zip	'/* date in understandable format           */
	Field dosDate:Long					'/* If dos_date == 0, tmu_date is used      */
	Field internal_fa:Long				'/* internal file attributes        2 bytes */
	Field external_fa:Long				'/* external file attributes        4 bytes */
	
	Method getBank:TBank()
		Local retval:TBank=CreateBank(48)
		
		' tm_zip
		PokeInt(retval,0,tmz_date.tm_sec)
		PokeInt(retval,4,tmz_date.tm_min)
		PokeInt(retval,8,tmz_date.tm_hour)
		PokeInt(retval,12,tmz_date.tm_mday)
		PokeInt(retval,16,tmz_date.tm_mon)
		PokeInt(retval,20,tmz_date.tm_year)

		' fileinfo fields
		PokeLong(retval,24,dosDate)
		PokeLong(retval,32,internal_fa)
		PokeLong(retval,40,external_fa)
						
		Return retval
	EndMethod
EndType
																	    																
Type SZIPFileDataDescriptor Extends PACK_STRUCT
	Const size:Int=12
	
	Field CRC32:Int
	Field CompressedSize:Int
	Field UncompressedSize:Int
	
	Method fillFromBank(databank:TBank,offset:Int=0)
		If BankSize(databank)<(offset+size)-1 Then RuntimeError "fillFromBank out of bounds"
		
		CRC32=PeekInt(databank,offset)
		CompressedSize=PeekInt(databank,offset+4)
		UncompressedSize=PeekInt(databank,offset+8)
	EndMethod
EndType

Type SZIPFileHeader Extends PACK_STRUCT
	Const size:Int=30

	Field Sig:Int
	Field VersionToExtract:Short
	Field GeneralBitFlag:Short
	Field CompressionMethod:Short
	Field LastModFileTime:Short
	Field LastModFileDate:Short
	Field DataDescriptor:SZIPFileDataDescriptor
	Field FilenameLength:Short
	Field ExtraFieldLength:Short
	
	Method New()
		DataDescriptor=New SZIPFileDataDescriptor
	EndMethod
	
	Method fillFromBank(databank:TBank,offset:Int=0)
		If BankSize(databank)<(offset+size)-1 Then RuntimeError "fillFromBank out of bounds"
		Sig=PeekInt(databank,offset)
		VersionToExtract=PeekShort(databank,offset+4)
		GeneralBitFlag=PeekShort(databank,offset+6)
		CompressionMethod=PeekShort(databank,offset+8)
		LastModFileTime=PeekShort(databank,offset+10)
		LastModFileDate=PeekShort(databank,offset+12)
		DataDescriptor.CRC32=PeekInt(databank,offset+14)
		DataDescriptor.CompressedSize=PeekInt(databank,offset+18)
		DataDescriptor.UncompressedSize=PeekInt(databank,offset+22)
		FilenameLength=PeekShort(databank,offset+26)
		ExtraFieldLength=PeekShort(databank,offset+28)
	EndMethod		
EndType

Type SZipFileEntry
	Field zipFileName:String
	Field simpleFileName:String
	Field path:String
	Field fileDataPosition:Int  ' position of compressed data in file
	Field header:SZIPFileHeader

	Function Create:SZipFileEntry()
		Return New SZipFileEntry
	EndFunction

	Method New()
		header=New SZipFileHeader
	EndMethod

	Method Less:Int(other:SZipFileEntry)
		Return simpleFileName.Compare(other.simpleFileName)<0
	EndMethod

	Method EqEq:Int(other:SZipFileEntry)
		Return simpleFileName.Compare(other.simpleFileName)=0
	EndMethod
	
	Method Compare:Int(other:Object)
		If SZipFileEntry(other) Return simpleFileName.Compare(SZipFileEntry(other).simpleFileName) Else Return -1
	EndMethod
EndType

' generic type for reading in PACK_STRUCT structures from files
Type PACK_STRUCT
	Global size:Int=0
			
	Method fillFromBank(bank:TBank,start:Int)
	EndMethod

	' returns true if successful
	Method fillFromReader:Int(fileToRead:TStream,tbsize:Int,readeroffset:Int=0,bankoffset:Int=0)
		If Not fileToRead Or ((StreamPos(fileToRead)+tbSize)>StreamSize(fileToRead)) Then Return False
		
		' create the bank
		Local structbank:TBank=CreateBank(tbsize)
		
		' read from the file
		structbank.Read(fileToRead,readeroffset,tbsize)
		
		' populate the STRUCT with what was read
		fillFromBank(structbank,bankoffset)
		
		' clear out the bank
		structbank=Null
		
		Return True
	EndMethod
	
	Method getBank:TBank()
		Return Null
	EndMethod	
EndType
