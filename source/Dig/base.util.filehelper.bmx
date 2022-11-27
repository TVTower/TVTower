Rem
	====================================================================
	File helper functions
	====================================================================

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2022-now Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict

Import Brl.IO 'MaxIO
Import Brl.Filesystem


Type TFileHelper
	Function EnsureWriteableDirectoryExists:Int(path:String)
		Local folderExists:int = (FileType(path) = FILETYPE_DIR)
		'folder might exist in read-only "app dir" already compared
		'to write-dir. If "writeDir" is earlier in the search path it
		'would return the write directory as real directory in case of
		'the path's existence.
		If MaxIO.ioInitialized 
			Local writeDir:String = MaxIO.GetWriteDir()
			if MaxIO.GetRealDir(path).Find(writeDir) <> 0
				folderExists = False
			EndIf
		EndIf

		If not folderExists and not CreateDir(path) 
			Throw "TFileHelper: Failed to create directory: ~q" + path + "~q."
		EndIf

		'folder exists now but did not before: return True
		If Not folderExists Then Return True
		Return True
	End Function
End Type