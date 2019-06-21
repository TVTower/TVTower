Rem
	====================================================================
	Profiler Class
	====================================================================

	Assistant for profiling function calls / loop times.

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
Import Brl.Map
?Threaded
Import Brl.Threads
?
Import "base.util.time.bmx"

Type TProfilerCall
	Field parent:TProfilerCall = null
	Field name:String
	Field start:Long
	Field firstStart:Long
	Field timeTotal:Int
	Field timeMax:Int
	Field calls:Int
	Field id:int = 0
	Field historyTime:Long[]
	Field historyDuration:Int[]
	Field historyIndex:int = 0

	Global callID:int = 0

	Method New()
		firstStart = Time.GetTimeGone()
		callID :+ 1
		id = callID
	End Method
		

	Method GetDepth:int()
		if parent then return parent.GetDepth() + 1
		return 0
	End Method


	Method GetCallPath:string()
		if parent then return parent.GetCallPath() + "::" + name

		return name
	End Method


	Method GetParentTimeTotal:Int()
		if parent then return parent.timeTotal
		return 0
	End Method
End Type


Type TProfiler
	Global activated:Int = 1
	Global calls:TStringMap = new TStringMap
	Global lastCall:TProfilerCall = null
	?Threaded
	Global accessMutex:TMutex = CreateMutex()
	?


	Function GetLog:string()
		local result:string = ""
		result :+ ".-----------------------------------------------------------------------------------------."+"~n"
		result :+ "| AppProfiler |                                                                           |"+"~n"
		result :+ "|-----------------------------------------------------------------------------------------|"+"~n"
		result :+ "| FUNCTION                            |   CALLS |  TOTAL |    MAX   | AVERAGE | OF PARENT |"+"~n"

		local totalTime:int = 0
		local entryNumber:int = 1

		'somehow adding to a tmap bugs out (think numbering sorting with
		'prepended "0" in a string is buggy)
		'so we just create an array from 0-maxID and add all calls to it
		local idSortedCalls:TProfilerCall[] = new TProfilerCall[TProfilerCall.callID+1]

		For Local c:TProfilerCall = EachIn calls.Values()
			if idSortedCalls.length <= c.id then idSortedCalls = idSortedCalls[.. c.id +1]
			idSortedCalls[c.id] = c
		Next

		For Local c:TProfilerCall = EachIn idSortedCalls
			local funcName:string = c.Name
			if c.GetDepth() > 0
				funcName = "'-"+funcName
				if c.GetDepth() >=2
					'prepend spaces
					for local i:int = 0 to c.GetDepth() - 2
						funcName = "  "+funcName
					Next
				endif
			endif
			local AvgTime:string = String( floor(int(1000.0*(Float(c.timeTotal) / Float(c.calls)))) / 1000.0 )

			local percentageOfParent:string
			if c.GetParentTimeTotal() > 0
				percentageOfParent = LSet(100 * c.timeTotal/float(c.GetParentTimeTotal()), 4)+"%"
			else
				percentageOfParent = RSet("100",4)+"%"
			endif

			result :+ "| " + LSet(funcName, 35) + " | " + RSet(c.calls, 7) + " | " + LSet(String(c.timeTotal / 1000.0), 5)+"s" + " | " + RSet(c.timeMax,6)+"ms" + " | " + LSet(AvgTime,5)+"ms"+ " |     "+percentageOfParent+" |" + "~n"
			entryNumber :+1
		Next
		If not activated
			result :+ "| Profiler deactivated                                                                    |" +"~n"
		EndIf
		result :+ "'-----------------------------------------------------------------------------------------'" +"~n"
		

		return result
	End Function
	
	
	Function GetCall:TProfilerCall(callName:string)
		return TProfilerCall(calls.ValueForKey(callName))
	End Function


	Function DumpLog( file:String )
		Local fi:TStream = WriteFile( file )
		fi.WriteString(GetLog())
		CloseFile fi
	End Function


	Function GetCallPath:string(functionName:string)
		if lastCall
			if lastCall.name <> functionName
				return lastCall.GetCallPath() + "::" + functionName
			else
				return lastCall.GetCallPath()
			endif
		endif

		return functionName
	End Function


	Function Enter:int(func:String, obtainCallPath:int = True)
		If not TProfiler.activated then return False

		?Threaded
'			return TRUE
			'wait for the mutex to get access to child variables
			LockMutex(accessMutex)
		?

		'try to fetch call from list
		local funcKey:String
		if obtainCallPath
			funcKey = GetCallPath(func)
		else
			funcKey = func
		endif
		Local call:TProfilerCall = TProfilerCall(calls.ValueForKey(funcKey))

		'create new if not existing yet
		if call = null
			call = New TProfilerCall
			call.calls = 0
			call.parent	= TProfiler.lastCall
			call.name = func

			calls.insert(funcKey, call)
		endif
		
		call.start	= Time.GetTimeGone()
		call.calls	:+1

		'set as last run call
		TProfiler.lastCall = call


		?Threaded
			'wait for the mutex to get access to child variables
			UnLockMutex(accessMutex)
		?
	End Function


	Function Leave:int( func:String, historyMax:int = 1, obtainCallPath:int = True)
		If not TProfiler.activated then return False

		?Threaded
			'wait for the mutex to get access to child variables
			LockMutex(accessMutex)
		?

		'just move 1 upwards
		if func = ""
			if TProfiler.lastCall then TProfiler.lastCall = TProfiler.lastCall.parent
		else
			'try to fetch call from list
			local funcKey:String
			if obtainCallPath
				funcKey = GetCallPath(func)
			else
				funcKey = func
			endif
			Local call:TProfilerCall = TProfilerCall(calls.ValueForKey(funcKey))

			If call <> null
				If call.historyTime.length < historyMax
					call.historyTime = call.historyTime[ .. historyMax]
					call.historyDuration = call.historyDuration[ .. historyMax]
				EndIf
				call.historyIndex = Min(call.historyIndex, historyMax-1)
				call.historyTime[ call.historyIndex ] = call.start
				call.historyDuration[ call.historyIndex ] = int(Time.GetTimeGone() - call.start)

				'save time call took
				call.timeTotal :+ (call.historyDuration[ call.historyIndex ])
				call.timeMax = Max(call.timeMax, call.historyDuration[ call.historyIndex ])

				'move on to next history slot
				call.historyIndex = (call.historyIndex + 1) mod Max(1, historyMax)

				'set last call to parent (if there is one)
				TProfiler.lastCall = call.parent
			EndIf
		endif

		?Threaded
			'wait for the mutex to get access to child variables
			UnLockMutex(accessMutex)
		?

		return True
	End Function
End Type
