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
Import "base.util.longmap.bmx"
Import "base.util.time.bmx"
Import "base.util.string.bmx"
Import "external/string_comp.bmx"


Type TProfilerCall
	Field parent:TProfilerCall = Null
	Field depth:Int = -1
	Field pathID:UInt 'hash of "parentPath+"::"+name
	Field path:String
	Field name:String
	Field start:Long
	Field firstStart:Long
	Field timeTotal:Int
	Field timeMax:Int
	Field calls:Int
	Field id:Int = 0
	Field historyTime:Long[]
	Field historyDuration:Int[]
	Field historyIndex:Int = 0

	Global callID:Int = 0


	Method New()
		firstStart = Time.GetTimeGone()
		callID :+ 1
		id = callID
	End Method


	Method GetDepth:Int()
		If depth < 0
			depth = 0
			If parent Then depth = parent.GetDepth() + 1
		EndIf
		
		Return depth
	End Method


	Method GetPath:String()
		If not path
			If parent
				path = parent.GetPath() + "::" + name.ToLower()
			Else
				path = name.ToLower()
			EndIf
		EndIf
		
		Return path
	End Method


	Method GetPathID:UInt()
		if pathID = 0
			pathID = GetPath().HashCode()
		endif

		Return pathID
	End Method


	Method GetParentTimeTotal:Int()
		If parent Then Return parent.timeTotal
		Return 0
	End Method
End Type




Type TProfiler
	Global activated:Int = 1
	Global calls:TLongMap = New TLongMap
	Global lastCall:TProfilerCall = Null
	Global accessMutex:TMutex = CreateMutex()


	Function GetLog:String()
		Local result:String = ""
		result :+ ".-------------------------------------------------------------------------------------------------."+"~n"
		result :+ "| AppProfiler |                                                                                   |"+"~n"
		result :+ "|-------------------------------------------------------------------------------------------------|"+"~n"
		result :+ "| FUNCTION                            |   CALLS |     TOTAL |        MAX |    AVERAGE | OF PARENT |"+"~n"

		Local totalTime:Int = 0
		Local entryNumber:Int = 1

		'somehow adding to a tmap bugs out (think numbering sorting with
		'prepended "0" in a string is buggy)
		'so we just create an array from 0-maxID and add all calls to it
		Local idSortedCalls:TProfilerCall[] = New TProfilerCall[TProfilerCall.callID+1]

		For Local c:TProfilerCall = EachIn calls.Values()
			If idSortedCalls.length <= c.id Then idSortedCalls = idSortedCalls[.. c.id +1]
			idSortedCalls[c.id] = c
		Next

		For Local c:TProfilerCall = EachIn idSortedCalls
			Local funcName:String = c.name
			If not funcName then funcName = "unknown"
			
			Local depth:Int = c.GetDepth()

			If depth > 0
				funcName = "'-"+funcName
				If depth >=2
					'prepend spaces
					For Local i:Int = 0 To depth - 2
						funcName = "  "+funcName
					Next
				EndIf
			EndIf

			Local percentageOfParent:String
			rem
			If c.GetParentTimeTotal() > 0
				percentageOfParent = LSet(100 * c.timeTotal/Float(c.GetParentTimeTotal()), 4)+"%"
			Else
				percentageOfParent = RSet("100",4)+"%"
			EndIf
			Local AvgTime:String = String( Floor(Int(1000.0*(Float(c.timeTotal) / Float(c.calls)))) / 1000.0 )
			result :+ "| " + LSet(funcName, 35) + " | " + RSet(c.calls, 7) + " | " + LSet(String(c.timeTotal / 1000.0), 5)+"s" + " | " + RSet(c.timeMax,6)+"ms" + " | " + LSet(AvgTime,5)+"ms"+ " |     "+percentageOfParent+" |" + "~n"
			endrem

			Local parentTotalTime:Int = c.GetParentTimeTotal()
			if parentTotalTime > 0
				if c.timeTotal/Float(parentTotalTime) <= 1.0
					percentageOfParent = StringHelper.printf("%3.2f", [string(100 * c.timeTotal/Float(parentTotalTime))])
				else
					percentageOfParent = "THREAD?"
				endif
			else
				percentageOfParent = "100.00%"
			endif

			result :+ "| " + LSet(funcName, 35)
			result :+ " | " + RSet(c.calls, 7)
			result :+ " | " + RSet(StringHelper.printf("%6.2f", [string(c.timeTotal / 1000.0)]), 8)+"s"
			result :+ " | " + RSet(StringHelper.printf("%7.1f", [string(c.timeMax)]), 8)+"ms"
			result :+ " | " + RSet(StringHelper.printf("%5.2f", [string(float(c.timeTotal) / c.calls)]), 8)+"ms"
			result :+ " | " + RSet(percentageOfParent, 9)+" |" + "~n"

			entryNumber :+1
		Next
		If Not activated
			result :+ "| Profiler deactivated                                                                            |" +"~n"
		EndIf
		result :+ "'-------------------------------------------------------------------------------------------------'" +"~n"


		Return result
	End Function


	Function GetCall:TProfilerCall(pathID:Long)
		Return TProfilerCall(calls.ValueForKey(pathID))
	End Function
	

	Function GetCall:TProfilerCall(callName:Object)
		If TLowerString(callName)
			Return TProfilerCall(calls.ValueForKey(Long(callName.ToString().HashCode())))
		Else
			Return TProfilerCall(calls.ValueForKey(Long(string(callName).ToLower().HashCode())))
		EndIf
	End Function


	Function DumpLog( file:String )
		Local fi:TStream = WriteFile( file )
		fi.WriteString(GetLog())
		CloseFile fi
	End Function



	Function Enter:Int(func:Object, storeAbsolutePath:Int = True)
		If Not TProfiler.activated Then Return False

		'wait for the mutex to get access to child variables
		LockMutex(accessMutex)


		Local pathID:Long
		Local pathStr:String
		If TLowerString(func)
			pathStr = TLowerString(func).ToString()
		Else
			pathStr = String(func).ToLower()
		EndIf
		'try to fetch call from list
		If lastCall and storeAbsolutePath
			pathID = (lastCall.GetPath() + "::" + pathStr).HashCode()
		Else
			pathID = pathStr.HashCode()
		EndIf

				
		Local call:TProfilerCall = TProfilerCall(calls.ValueForKey(pathID))
		'create new if not existing yet
		If call = Null
			call = New TProfilerCall
			call.calls = 0
			call.parent	= TProfiler.lastCall
			call.name = pathStr

			calls.insert(pathID, call)
		EndIf

		call.start	= Time.GetTimeGone()
		call.calls	:+1

		'set as last run call
		TProfiler.lastCall = call


		'wait for the mutex to get access to child variables
		UnlockMutex(accessMutex)
	End Function


	Function Leave:Int( func:Object, historyMax:Int = 1, storeAbsolutePath:Int = True)
		If Not TProfiler.activated Then Return False

		'wait for the mutex to get access to child variables
		LockMutex(accessMutex)

		'just move 1 upwards
		If Not TLowerString(func) And Not String(func)
			If TProfiler.lastCall Then TProfiler.lastCall = TProfiler.lastCall.parent
		Else
			Local pathID:Long
			Local pathStr:String
			If TLowerString(func)
				pathStr = TLowerString(func).ToString()
			Else
				pathStr = String(func).ToLower()
			EndIf
			'try to fetch call from list
			If lastCall and storeAbsolutePath
				pathID = (lastCall.GetPath() + "::" + pathStr).HashCode()
			Else
				pathID = pathStr.HashCode()
			EndIf

			Local call:TProfilerCall = TProfilerCall(calls.ValueForKey(pathID))

			If call
				If call.historyTime.length < historyMax
					call.historyTime = call.historyTime[ .. historyMax]
					call.historyDuration = call.historyDuration[ .. historyMax]
				EndIf
				call.historyIndex = Min(call.historyIndex, historyMax-1)
				call.historyTime[ call.historyIndex ] = call.start
				call.historyDuration[ call.historyIndex ] = Int(Time.GetTimeGone() - call.start)

				'save time call took
				call.timeTotal :+ (call.historyDuration[ call.historyIndex ])
				call.timeMax = Max(call.timeMax, call.historyDuration[ call.historyIndex ])

				'move on to next history slot
				call.historyIndex = (call.historyIndex + 1) Mod Max(1, historyMax)

				'set last call to parent (if there is one)
				TProfiler.lastCall = call.parent
			EndIf
		EndIf

		'wait for the mutex to get access to child variables
		UnlockMutex(accessMutex)

		Return True
	End Function
End Type
