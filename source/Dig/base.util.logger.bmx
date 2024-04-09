Rem
	====================================================================
	Class handling filtered Log/Console output
	====================================================================

	Allows to log things to file or screen (depending on the filter you
	set).

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-now Ronny Otto, digidea.de

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
Import BRL.LinkedList
Import BRL.Retro		'for lset()
Import BRL.System		'for currenttime()
?android
'needed to be able to retrieve android's internal storage path
Import Sdl.sdl
?
?threaded
Import Brl.Threads
?
Import "base.util.string.bmx"
Import "base.util.filehelper.bmx"

'create a basic log file
'but ensure directory exists
Const LOG_DIRECTORY:String = "logfiles"
Global AppLog:TLogFile = TLogFile.Create("App Log v1.0", "log.app.txt")
Global AppErrorLog:TLogFile = TLogFile.Create("App Log v1.0", "log.app.error.txt")

Const LOG_ERROR:Int		= 1
Const LOG_WARNING:Int	= 2
Const LOG_INFO:Int		= 4
Const LOG_DEBUG:Int		= 8
Const LOG_DEV:Int		= 16
Const LOG_TESTING:Int	= 32
Const LOG_LOADING:Int	= 64
Const LOG_GAME:Int		= 128
Const LOG_AI:Int		= 256
Const LOG_XML:Int		= 512
Const LOG_NETWORK:Int	= 1024
Const LOG_SAVELOAD:Int	= 2048
'all but debug/dev/testing/ai
Const LOG_ALL_NORMAL:Int	= 1|2|4| 0 | 0 | 0 |64|128| 0 |512|1024|2048
Const LOG_ALL:Int			= 1|2|4| 8 |16 |32 |64|128|256|512|1024|2048


'by default EVERYTHING is logged
TLogger.setLogMode(LOG_ALL)
TLogger.setPrintMode(LOG_ALL)

Type TLogger
	Global printMode:Int = 0 'print nothing
	Global logMode:Int = 0 'log nothing
	Global lastLoggedMode:Int =0
	Global lastPrintMode:Int =0
	Global lastLoggedFunction:String=""
	Global lastPrintFunction:String=""
	?threaded
	Global printMutex:TMutex = CreateMutex()
	?
	Const MODE_LENGTH:Int = 8


	'replace print mode flags
	Function setPrintMode(flag:Int=0)
		printMode = flag
	End Function


	'replace logfile mode flags
	Function setLogMode(flag:Int=0)
		logMode = flag
	End Function


	'change an existing print mode (add or remove flag)
	Function changePrintMode(flag:Int=0, enable:Int=True)
		If enable
			printMode :| flag
		Else
			printMode :& ~flag
		EndIf
	End Function

	'change an existing logfile mode (add or remove flag)
	Function changeLogMode(flag:Int=0, enable:Int=True)
		If enable
			logMode :| flag
		Else
			logMode :& ~flag
		EndIf
	End Function


	'outputs a string to stdout and/or logfile
	'exactTypeRequired: requires the mode to exactly contain the debugType
	'                   so a LOG_AI|LOG_DEBUG will only get logged if BOTH are enabled
	Function Log(functiontext:String = "", message:String, debugType:Int=LOG_DEBUG, exactTypeRequired:Int=False)
		Local debugtext:String = ""
		If debugType & LOG_LOADING Then debugtext :+ "LOAD "
		If debugType & LOG_GAME Then debugtext :+ "GAME "
		If debugType & LOG_AI Then debugtext :+ "AI "
		If debugType & LOG_XML Then debugtext :+ "XML "
		If debugType & LOG_NETWORK Then debugtext :+ "NET "
		If debugType & LOG_SAVELOAD Then debugtext :+  "SAVE "

		If debugType & LOG_DEV Then debugtext :+ "DEV "
		If debugType & LOG_DEBUG Then debugtext :+ "DBG "
		'can only be one of them - sorted by priority
		If debugType & LOG_ERROR
			debugtext :+ "ERR "
		ElseIf debugType & LOG_WARNING
			debugtext :+ "WRN "
		ElseIf debugType & LOG_INFO
			debugtext :+ "INFO "
		EndIf
'		if len(debugText) < MODE_LENGTH
			debugtext = LSet(debugtext, MODE_LENGTH) + " | "
'		else
'			debugtext = debugtext + " | "
'		endif

		Local showFunctionText:String = ""
		Local doLog:Int = False
		Local doPrint:Int = False
		'means ALL GIVEN TYPES have to fit
		If exactTypeRequired
			doLog = ((logMode & debugType) = debugType)
			doPrint = ((printMode & debugType) = debugType)
		'only one of the given types has to fit
		Else
			doLog = (logMode & debugType)
			doPrint = (printMode & debugType)
		EndIf

		If doLog
			If debugType = lastLoggedMode And upper(functiontext) = lastLoggedFunction
				showFunctionText = LSet("", Len(lastLoggedFunction))
			Else
				lastLoggedFunction = upper(functiontext)
				lastLoggedMode = debugType
				showFunctionText = lastLoggedFunction
			EndIf

			AppLog.AddLog("[" + CurrentTime() + "] " + debugtext + showFunctionText + ": " + message)
			'store errors in an extra file
			If debugType & LOG_ERROR
				AppErrorLog.AddLog("[" + CurrentTime() + "] " + debugtext + showFunctionText + ": " + message)
			EndIf
		EndIf

		If doPrint
			If debugType = lastPrintMode And upper(functiontext) = lastPrintFunction
				showFunctionText = LSet("", Len(lastPrintFunction))
			Else
				lastPrintFunction = upper(functiontext)
				lastPrintMode = debugType
				showFunctionText = lastPrintFunction
			EndIf

			'message = StringHelper.UTF8toISO8859(message)
'			?Win32
'			message = StringHelper.RemoveUmlauts(message)
'			?
			message = StringHelper.RemoveUmlauts(message)

			Local text:String = "[" + CurrentTime() + "] " + debugtext + showFunctionText + ": " + message
			?threaded
			LockMutex(printMutex)
			?
			?android
				If debugType & LOG_DEBUG
					'debug not shown in normal logcat
					'LogDebug(SDL_LOG_CATEGORY_APPLICATION, text)
					LogInfo(SDL_LOG_CATEGORY_APPLICATION, text)
				ElseIf debugType & LOG_WARNING
					LogWarn(SDL_LOG_CATEGORY_APPLICATION, text)
				Else
					LogInfo(SDL_LOG_CATEGORY_APPLICATION, text)
				EndIf
			?Not android
				Print text
			?
			?threaded
			UnLockMutex(printMutex)
			?
		EndIf
	End Function
End Type




Type TLogFile
	Field Strings:TList = CreateList()
	Field title:String = ""
	Field filename:String = ""
	Field headerWritten:Int = False
	Field immediateWrite:Int = True
	Field fileObj:TStream
	Field fileRenewed:Int = False
	Field keepFileOpen:Int = True
	?threaded
	Field fileMutex:TMutex = CreateMutex()
	?

	Global logs:TList = CreateList()


	'immediateWrite decides whether a added log is immediately written
	'to the log file or not
	Function Create:TLogFile(title:String, filename:String, immediateWrite:Int = True, keepFileOpen:Int = True)
		Local obj:TLogFile = New TLogFile
		obj.title = title
		if LOG_DIRECTORY 
			filename = LOG_DIRECTORY + "/" + filename
		EndIf
		?android
			'prefix with the path to the internal storage
			filename = AndroidGetInternalStoragePath()+"/"+filename
		?
		obj.filename = filename
		obj.immediateWrite = immediateWrite

		'(Try to) remove old log
		DeleteFile(filename)

		obj.keepFileOpen = keepFileOpen

		TLogfile.logs.addLast(obj)

		Return obj
	End Function
	
	
	Function DumpLogs()
		For Local logfile:TLogFile = EachIn TLogFile.logs
			'if the file is still open, close first
			If logfile.fileObj Then CloseFile(logfile.fileObj)

			?threaded
			LockMutex(logfile.fileMutex)
			?
			'in all cases, just dump down the file again regardless
			'of the mode (you might have manipulated logs meanwhile)
			'try to create the file
			TFileHelper.EnsureWriteableDirectoryExists(LOG_DIRECTORY)
			Local file:TStream = WriteFile( logfile.filename )
			If Not file 
				?threaded
				UnlockMutex(logfile.fileMutex)
				?
				Throw "Cannot open ~q" + logfile.filename + "~q to dump log to."
			EndIf

			'header
			WriteLine(file, logfile.title)
			'current logs
			For Local line:String = EachIn logfile.Strings
				WriteLine(file, line)
			Next

			CloseFile(file)
			?threaded
			UnlockMutex(logfile.fileMutex)
			?
		Next
	End Function
	
	
	Method AddLog:Int(text:String, addDateTime:Int=False)
		If addDateTime Then text = "[" + CurrentTime() + "] " + text
		Strings.AddLast(text)

		If immediateWrite
			?threaded
			LockMutex(fileMutex)
			?

			'open to append if not done yet
			If Not fileObj
				TFileHelper.EnsureWriteableDirectoryExists(LOG_DIRECTORY)

				If not fileRenewed
					fileObj = WriteStream(filename)
					fileRenewed = True
				Else
					fileObj = AppendStream(filename)
				EndIf
				If Not fileObj 
					?threaded
					UnlockMutex(fileMutex)
					?
					Throw "Cannot open ~q"+filename+"~q to append log entry to."
				EndIf
			EndIf

			'write the header if not done yet
			'(doing it here allows to adjust the title after creation)
			If Not headerWritten
				fileObj.WriteLine(title)
				headerWritten = True
			EndIf

			fileObj.WriteLine(text)
			fileObj.Flush()

			'close file to allow access by other processes
			If Not keepFileOpen Then CloseFile(fileObj)

			?threaded
			UnlockMutex(fileMutex)
			?
		EndIf
		Return True
	End Method
End Type
