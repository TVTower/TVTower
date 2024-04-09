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
		Local dirs:String[] = path.Replace("\", "/").Split("/")
		Local currDir:String
		Local writeDir:String
		If MaxIO.ioInitialized 
			writeDir = MaxIO.GetWriteDir()
		EndIf

		Local folderExists:int
		local createdAFolder:int
		For Local dir:String = EachIn dirs
			If currDir Then currDir :+ "/"
			currDir :+ dir

			folderExists = (FileType(currDir) = FILETYPE_DIR)

			'folder might exist in read-only "app dir" already compared
			'to write-dir. If "writeDir" is earlier in the search path it
			'would return the write directory as real directory in case of
			'the path's existence.
			If MaxIO.ioInitialized 
				if MaxIO.GetRealDir(currDir).Find(writeDir) <> 0
					folderExists = False
				EndIf
			EndIf

			If Not folderExists
				If CreateDir(currDir) 
					createdAFolder = True
				Else
					Throw "TFileHelper: Failed to create directory: ~q" + currDir + "~q."
				EndIf
			EndIf
		Next

		'folder exists now but did not before: return True
		Return createdAFolder
	End Function
End Type