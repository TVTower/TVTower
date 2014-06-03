Rem
	====================================================================
	Time related helpers
	====================================================================

	Time:
	BRL Millisecs() can "wrap" to a negative value (if your uptime
	is bigger than 25 days).

	This class provides an alternative function to Millisecs() called
	MillisecsLong().

	TStopWatch:
	Also a class TStopWatch is provided for easing the process of
	measuring the interval of between a starting time and now.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2014 Ronny Otto, digidea.de

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
Import Brl.retro



Type Time
	'=== GETTIMEGONE ===
	Global startTime:Long = 0

	'=== MILLISECSLONG
	Global MilliSeconds:Long=0
	Global LastMilliSeconds:Long = Time.MilliSecsLong()


	'returns the time gone since the computer was started
	Function MilliSecsLong:Long()
		'code from:
		'http://www.blitzbasic.com/Community/post.php?topic=84114&post=950107

		'Convert to 32-bit unsigned
		Local Milli:Long = Long(Millisecs()) + 2147483648
		 'Accumulate 2^32
		If Milli < LastMilliSeconds Then MilliSeconds :+ 4294967296

		LastMilliSeconds = Milli
		Return MilliSeconds + Milli
	End Function


	'returns the time gone since the first call to "GetTimeGone()"
	Function GetTimeGone:int()
		if startTime = 0 then startTime = MilliSecsLong()

		return (MilliSecsLong() - startTime)
	End Function


	Function GetSystemTime:String(format:String="%d %B %Y")
		Local time:Byte[256]
		Local buff:Byte[256]
		time_(time)
		strftime_(buff, 256, format, localtime_(time))
		Return String.FromCString(buff)
	End Function
End Type



'a simple stop watch to measure a time interval
Type TStopWatch
	Field startTime:int = -1


	Method Init:TStopWatch()
		Reset()

		return self
	End Method


	Method Reset:int()
		startTime = Time.GetTimeGone()
	End Method


	Method GetTime:int()
		if startTime = -1 then return 0
		return (Time.GetTimeGone() - startTime)
	End Method
End Type