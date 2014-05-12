REM
	===========================================================
	class for non-wrapping Millisecs()
	===========================================================

	BRL Millisecs() can "wrap" to a negative value (if your uptime
	is bigger than 25 days).

	This class provides an alternative function to Millisecs() called
	MillisecsLong().


ENDREM
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