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
Import Collections.ArrayList
Import BRL.Retro		'for lset()
Import BRL.System		'for currenttime()
?android
'needed to be able to retrieve android's internal storage path
Import Sdl.sdl
?
Import Brl.Threads
Import "base.util.string.bmx"
Import "base.util.filehelper.bmx"

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

TLogger.Init()
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
	Global printMutex:TMutex = CreateMutex()
	Const MODE_LENGTH:Int = 8

	'create a basic log file
	'but ensure directory exists
	Const LOG_DIRECTORY:String = "logfiles"
	Global AppLog:TLogFile
	Global AppErrorLog:TLogFile

	'can files be written there (now) (useful for virtual filesystems
	'to buffer until it is configured
	Global logDirectoryUsable:Int = False
	Global logs:TArrayList<TLogFile>


	Function Init()
		logs = New TArrayList<TLogFile>

		AppLog = New TLogFile("App Log v2.0", "log.app.txt")
		AppErrorLog = New TLogFile("App Log v2.0", "log.app.error.txt")
		AddManaged(AppLog)
		AddManaged(AppErrorLog)
	End Function
	

	Function AddManaged(logFile:TLogFile)
		If Not logs.Contains(logFile)
			logs.Add(logFile)
		EndIf
	End Function
	

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

	
	Function DumpLogs(appendDump:Int = True)
		'guess we can assume now, saving is possible?
		TLogger.SetLogDirectoryUsable()

		For Local logfile:TLogFile = EachIn logs
			logFile.DumpLog(appendDump)
		Next
	End Function
	
		
	
	Function SetLogDirectoryUsable()
		logDirectoryUsable = True

		'(Try to) remove old log
		For Local logfile:TLogFile = EachIn logs
			If Not logfile.existingOldLogDeleted
				DeleteFile(logfile.GetFilePath())
				'if maxio was enabled, the original location could
				'still contain this file too - so we skip checking here
				logfile.existingOldLogDeleted = True
			EndIf
		Next
		
		For Local logfile:TLogFile = EachIn logs
			If logfile.immediateWrite
				logfile.lineWritten = logfile.DumpLog(False)
			EndIf
		Next
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
		debugtext = LSet(debugtext, MODE_LENGTH) + " | "

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

			message = StringHelper.RemoveUmlauts(message)

			Local text:String = "[" + CurrentTime() + "] " + debugtext + showFunctionText + ": " + message
			LockMutex(printMutex)
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
			UnLockMutex(printMutex)
		EndIf
	End Function
End Type




Type TLogFile
	'logged content
	Field lines:TArrayList<string> = New TArrayList<string>
	'line number (not index) which was written last. 0 = none
	Field lineWritten:Int
	Field linesMutex:TMutex = CreateMutex()
	
	Field header:String

	'storage location
	Field fileName:String = ""
	Field fileObj:TStream
	Field fileMutex:TMutex = CreateMutex()

	Field immediateWrite:Int = True
	Field keepFileOpen:Int = True
	Field existingOldLogDeleted:Int = False


	'immediateWrite decides whether a added log is immediately written
	'to the log file or not
	Method New(header:String, fileName:String, immediateWrite:Int = True, keepFileOpen:Int = True)
		?android
			'prefix with the path to the internal storage
			fileName = AndroidGetInternalStoragePath()+"/"+fileName
		?
		self.fileName = fileName

		self.immediateWrite = immediateWrite
		self.keepFileOpen = keepFileOpen

		self.header = header
	End Method
	

	Method GetFilePath:String()
		Local filePath:String = fileName
		if TLogger.LOG_DIRECTORY Then filePath = TLogger.LOG_DIRECTORY + "/" + fileName
		Return filePath
	End Method


	Method OpenLogFile:Int(clearFile:Int = True)
		fileMutex.Lock()
		
		Local filePath:String = GetFilePath()

		'already opened?
		If fileObj And clearFile
			fileObj.Close()
		EndIf

		Local dir:String = ExtractDir(filePath)
		If dir
			TFileHelper.EnsureWriteableDirectoryExists(dir)
		EndIf

		If clearFile
			fileObj = WriteStream(filePath)
		ElseIf not fileObj
			fileObj = AppendStream(filePath)
		EndIf

		fileMutex.Unlock()
		
		Return fileObj <> Null
	End Method


	Method DumpLog:Int(appendDump:Int = True)
		'print only what was not printed yet?
		If appendDump
			local newLinesWritten:Int = DumpLogLines(lineWritten, -1, False, lineWritten = 0)
			lineWritten :+ newLinesWritten
			Return newLinesWritten
		Else
			Return DumpLogLines(0, -1, True, True)
		EndIf
	End Method
		
	
	Method DumpLogLines:Int(startIndex:Int, endIndex:Int = -1, clearFile:Int = True, includeHeader:Int = False)
		If Not OpenLogFile(clearFile) Then Return 0
		
		Local linesWritten:Int
		
		fileMutex.Lock()
		
		If includeHeader
			fileObj.WriteLine(header)
		EndIf

		linesMutex.Lock()
		If startIndex < 0 Then startIndex = 0
		If endIndex = -1 Then endIndex = lines.Count()
		For local lineIndex:Int = startIndex until endIndex
			fileObj.WriteLine(lines[lineIndex])
			linesWritten :+ 1
		Next
		fileObj.Flush()
		linesMutex.Unlock()

		'close file to allow access by other processes
		If Not keepFileOpen Then fileObj.Close()

		fileMutex.Unlock()
		
		Return linesWritten
	End Method
		

	Method AddLog:Int(text:String, addDateTime:Int=False)
		If addDateTime Then text = "[" + CurrentTime() + "] " + text

		linesMutex.Lock()
		lines.Add(text)
		linesMutex.Unlock()

		If immediateWrite and TLogger.logDirectoryUsable
			Local newLinesWritten:Int = DumpLogLines(lineWritten, -1, False, False)
			lineWritten :+ newLinesWritten
		EndIf
		Return True
	End Method
End Type
