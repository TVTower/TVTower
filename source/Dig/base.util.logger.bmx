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

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

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
Import "base.util.string.bmx"

'create a basic log file
Global AppLog:TLogFile = TLogFile.Create("App Log v1.0", "log.app.txt")
Global AppErrorLog:TLogFile = TLogFile.Create("App Log v1.0", "log.app.error.txt")

Const LOG_ERROR:int		= 1
Const LOG_WARNING:int	= 2
Const LOG_INFO:int		= 4
Const LOG_DEBUG:int		= 8
Const LOG_DEV:int		= 16
Const LOG_TESTING:int	= 32
Const LOG_LOADING:int	= 64
Const LOG_GAME:int		= 128
Const LOG_AI:int		= 256
Const LOG_XML:int		= 512
Const LOG_NETWORK:int	= 1024
Const LOG_SAVELOAD:int	= 2048
'all but debug/dev/testing/ai
Const LOG_ALL_NORMAL:int	= 1|2|4| 0 | 0 | 0 |64|128| 0 |512|1024|2048
Const LOG_ALL:int			= 1|2|4| 8 |16 |32 |64|128|256|512|1024|2048


'by default EVERYTHING is logged
TLogger.setLogMode(LOG_ALL)
TLogger.setPrintMode(LOG_ALL)

Type TLogger
	global printMode:int = 0 'print nothing
	global logMode:int = 0 'log nothing
	global lastLoggedMode:int =0
	global lastPrintMode:int =0
	global lastLoggedFunction:string=""
	global lastPrintFunction:string=""
	const MODE_LENGTH:int = 8


	'replace print mode flags
	Function setPrintMode(flag:int=0)
		printMode = flag
	End Function


	'replace logfile mode flags
	Function setLogMode(flag:int=0)
		logMode = flag
	End Function


	'change an existing print mode (add or remove flag)
	Function changePrintMode(flag:int=0, enable:int=TRUE)
		if enable
			printMode :| flag
		else
			printMode :& ~flag
		endif
	End Function

	'change an existing logfile mode (add or remove flag)
	Function changeLogMode(flag:int=0, enable:int=TRUE)
		if enable
			logMode :| flag
		else
			logMode :& ~flag
		endif
	End Function


	'outputs a string to stdout and/or logfile
	'exactTypeRequired: requires the mode to exactly contain the debugType
	'                   so a LOG_AI|LOG_DEBUG will only get logged if BOTH are enabled
	Function Log(functiontext:String = "", message:String, debugType:int=LOG_DEBUG, exactTypeRequired:int=FALSE)
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

		local showFunctionText:string = ""
		local doLog:int = FALSE
		local doPrint:int = FALSE
		'means ALL GIVEN TYPES have to fit
		if exactTypeRequired
			doLog = ((logMode & debugType) = debugType)
			doPrint = ((printMode & debugType) = debugType)
		'only one of the given types has to fit
		else
			doLog = (logMode & debugType)
			doPrint = (printMode & debugType)
		endif

		if doLog
			if debugType = lastLoggedMode and functiontext = lastLoggedFunction
				showFunctionText = LSet("", len(lastLoggedFunction))
			else
				lastLoggedFunction = functiontext
				lastLoggedMode = debugType
				showFunctionText = functiontext
			endif

			AppLog.AddLog("[" + CurrentTime() + "] " + debugtext + Upper(showFunctionText) + ": " + message)
			'store errors in an extra file
			if debugType & LOG_ERROR
				AppErrorLog.AddLog("[" + CurrentTime() + "] " + debugtext + Upper(showFunctionText) + ": " + message)
			endif
		endif

		if doPrint
			if debugType = lastPrintMode and functiontext = lastPrintFunction
				showFunctionText = LSet("", len(lastPrintFunction))
			else
				lastPrintFunction = functiontext
				lastPrintMode = debugType
				showFunctionText = functiontext
			endif

			'message = StringHelper.UTF8toISO8859(message)
'			?Win32
'			message = StringHelper.RemoveUmlauts(message)
'			?
			message = StringHelper.RemoveUmlauts(message)

			local text:string = "[" + CurrentTime() + "] " + debugtext + Upper(showFunctionText) + ": " + message
			?android
				if debugType & LOG_DEBUG
					'debug not shown in normal logcat
					'LogDebug(SDL_LOG_CATEGORY_APPLICATION, text)
					LogInfo(SDL_LOG_CATEGORY_APPLICATION, text)
				elseif debugType & LOG_WARNING
					LogWarn(SDL_LOG_CATEGORY_APPLICATION, text)
				else
					LogInfo(SDL_LOG_CATEGORY_APPLICATION, text)
				endif
			?not android
				print text
			?
		endif
	End Function

End Type




Type TLogFile
	Field Strings:TList = CreateList()
	Field title:string = ""
	Field filename:string = ""
	Field headerWritten:int = False
	Field immediateWrite:int = True

	Global logs:TList = CreateList()


	'immediateWrite decides whether a added log is immediately written
	'to the log file or not
	Function Create:TLogFile(title:string, filename:string, immediateWrite:int = True)
		local obj:TLogFile = new TLogFile
		obj.title = title
		?android
			'prefix with the path to the internal storage
			filename = AndroidGetInternalStoragePath()+"/"+filename
		?
		obj.filename = filename
		obj.immediateWrite = immediateWrite

		'create the file ("renew" it)
		CreateFile(filename)

		TLogfile.logs.addLast(obj)

		return obj
	End Function


	Function DumpLogs()
		For local logfile:TLogFile = eachin TLogFile.logs
			'in all cases, just dump down the file again regardless
			'of the mode (you might have manipulated logs meanwhile)
			'try to create the file
			CreateFile(logfile.filename)
			Local file:TStream = WriteFile( logfile.filename )

			WriteLine(file, logfile.title)
			For Local line:String = EachIn logfile.Strings
				WriteLine(file, line)
			Next

			CloseFile(file)
		Next
	End Function


	Method AddLog:int(text:String, addDateTime:int=FALSE)
		if addDateTime then text = "[" + CurrentTime() + "] " + text
		Strings.AddLast(text)

		if immediateWrite
			local size:int = filesize(filename)
			if size = -1
				if not CreateFile(filename)
					Throw "Cannot create logfile: "+filename
				endif
			endif
			local file:TStream = OpenFile(filename)


			if not headerWritten
				WriteLine(file, title)
				headerWritten = True
			'if we already have written the header, move to the end of
			'the file
			else
				file.Seek(size)
			endif
			WriteLine(file, text)

			CloseFile(file)
		endif
		return TRUE
	End Method
End Type
