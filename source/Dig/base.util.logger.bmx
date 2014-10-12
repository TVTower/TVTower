REM
	===========================================================
	class handling filtered Log/Console output
	===========================================================
ENDREM
SuperStrict
Import BRL.LinkedList
Import BRL.Retro		'for lset()
Import BRL.System		'for currenttime()
Import "base.util.string.bmx"

'create a basic log file
Global AppLog:TLogFile = TLogFile.Create("App Log v1.0", "log.app.txt")

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
		If debugType & LOG_ERROR Then debugtext :+ "ERROR "
		If debugType & LOG_WARNING Then debugtext :+ "WARNING "
		If debugType & LOG_INFO Then debugtext :+ "INFO "
		If debugType & LOG_DEV Then debugtext :+ "DEV "
		If debugType & LOG_DEBUG Then debugtext :+ "DEBUG "
		If debugType & LOG_LOADING Then debugtext :+ "LOAD "
		If debugType & LOG_GAME Then debugtext :+ "GAME "
		If debugType & LOG_AI Then debugtext :+ "AI "
		If debugType & LOG_XML Then debugtext :+ "XML "
		If debugType & LOG_NETWORK Then debugtext :+ "NET "
		If debugType & LOG_SAVELOAD Then debugtext :+  "SAVELOAD "
		if len(debugText) < MODE_LENGTH
			debugtext = LSet(debugtext, MODE_LENGTH) + " | "
		else
			debugtext = debugtext + " | "
		endif

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
		endif

		if doPrint
			if debugType = lastPrintMode and functiontext = lastPrintFunction
				showFunctionText = LSet("", len(lastPrintFunction))
			else
				lastPrintFunction = functiontext
				lastPrintMode = debugType
				showFunctionText = functiontext
			endif

			rem
			message = message.replace("ü", "ue")
			message = message.replace("Ü", "Ue")
			message = message.replace("ö", "oe")
			message = message.replace("Ö", "Oe")
			message = message.replace("ä", "ae")
			message = message.replace("Ä", "Ae")
			message = message.replace("ß", "ss")
			endrem
			message = StringHelper.UTF8toISO8859(message)

			print "[" + CurrentTime() + "] " + debugtext + Upper(showFunctionText) + ": " + message
		endif
	End Function

End Type




Type TLogFile
	Field Strings:TList		= CreateList()
	Field title:string		= ""
	Field filename:string	= ""
	Global logs:TList		= CreateList()


	Function Create:TLogFile(title:string, filename:string)
		local obj:TLogFile = new TLogFile
		obj.title = title
		obj.filename = filename
		TLogfile.logs.addLast(obj)
		return obj
	End Function


	Function DumpLogs()
		For local logfile:TLogFile = eachin TLogFile.logs
			Local fi:TStream = WriteFile( logfile.filename )
			WriteLine fi, logfile.title
			For Local line:String = EachIn logfile.Strings
				WriteLine fi, line
			Next
			CloseFile fi
		Next
	End Function


	Method AddLog:int(text:String, addDateTime:int=FALSE)
		if addDateTime then text = "[" + CurrentTime() + "] " + text
		Strings.AddLast(text)
		return TRUE
	End Method
End Type
