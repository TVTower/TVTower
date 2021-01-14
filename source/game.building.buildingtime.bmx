SuperStrict
Import "Dig/base.util.deltatimer.bmx"
Import "game.world.worldtime.base.bmx"


Type TBuildingTime extends TWorldTimeBase {_exposeToLua="selected"}
	Global _instance:TBuildingTime


	Function GetInstance:TBuildingTime()
		if not _instance then _instance = new TBuildingTime
		return _instance
	End Function

	'override
	Method Init:TBuildingTime(timeGone:Long = 0)
		Super.Init(timeGone)

		return self
	End Method


	Method TooFastForSound:int()
		if _timeFactor > 5 then return True
		return False
	End Method
End Type
'endrem

'===== CONVENIENCE ACCESSOR =====
Function GetBuildingTime:TBuildingTime()
	Return TBuildingTime.GetInstance()
End Function





'for things happening every X moments
Type TBuildingIntervalTimer Extends TWorldTimeBaseIntervalTimer
	'override
	Method Init:TBuildingIntervalTimer(interval:int, actionTime:int = 0, randomnessMin:int = 0, randomnessMax:int = 0)
		Super.Init(interval, actionTime, randomnessMin, randomnessMax)

		return self
	End Method


	'override to access bulding time
	Method GetTime:TWorldTimeBase()
		Return GetBuildingTime()
	End Method
End Type