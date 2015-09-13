SuperStrict
Import "Dig/base.util.data.bmx"
Import "game.popularity.bmx"


Type TPersonPopularity Extends TPopularity
	Function Create:TPersonPopularity(referenceGUID:string, popularity:Float = 0.0, longTermPopularity:Float = 0.0)
		Local obj:TPersonPopularity = New TPersonPopularity

		obj.LongTermPopularityLowerBound		= -50
		obj.LongTermPopularityUpperBound		= 50

		obj.SurfeitLowerBoundAdd				= -30
		obj.SurfeitUpperBoundAdd				= 35
		obj.SurfeitTrendMalus					= 5
		obj.SurfeitCounterUpperBoundAdd			= 3

		obj.TrendLowerBound						= -10
		obj.TrendUpperBound						= 10
		obj.TrendAdjustDivider					= 5
		obj.TrendRandRangLower					= -15
		obj.TrendRandRangUpper					= 15

		obj.ChanceToChangeCompletely			= 2
		obj.ChanceToChange						= 15
		obj.ChanceToAdjustLongTermPopularity	= 25

		obj.ChangeLowerBound					= -35
		obj.ChangeUpperBound					= 35

		obj.referenceGUID = referenceGUID
		obj.SetPopularity(popularity)
		obj.SetLongTermPopularity(longTermPopularity)
		'obj.LogFile = TLogFile.Create("GenrePopularity Log", "GenrePopularityLog" + contentId + ".txt")

		Return obj
	End Function


	'a programme just got produced with the person in the cast
	Method FinishProgrammeProduction(data:TData)
		local now:Long = GetWorldTime().GetTimeGone()
		Local time:Long = data.GetLong("time", now)
		Local quality:Float = data.GetFloat("quality", 0)
		Local jobID:int = data.GetInt("job", 0)
		local ageInDays:Int = (time - now)/ TWorldTime.DAYLENGTH 

		Local changeVal:Float = quality

		'affected by time since production end
		if ageInDays < 10
			changeVal :* 1.0
		elseif ageInDays < 20
			changeVal :* 0.75
		elseif ageInDays < 30
			changeVal :* 0.5
		elseif ageInDays < 40
			changeVal :* 0.25
		else
			changeVal = 0
		endif


		'decrease effect by the importance of a job
		Select jobID
			Case TVTProgrammePersonJob.DIRECTOR
				changeVal :* 0.8
			Case TVTProgrammePersonJob.ACTOR
				changeVal :* 1.0
			Case TVTProgrammePersonJob.SCRIPTWRITER
				changeVal :* 0.4
			Case TVTProgrammePersonJob.HOST
				changeVal :* 1.0
			Case TVTProgrammePersonJob.MUSICIAN
				changeVal :* 0.4
			Case TVTProgrammePersonJob.SUPPORTINGACTOR
				changeVal :* 0.3
			Case TVTProgrammePersonJob.GUEST
				changeVal :* 0.3
			Case TVTProgrammePersonJob.REPORTER
				changeVal :* 0.8
			Default
				changeVal :* 0.1
		End Select

	

		'maximum adjustment is 1.5% ?
		changeVal = Min(Max(changeVal, 0), 1.5)

		if changeVal = 0 then return

		ChangeTrend(changeVal)
		'Print "FinishProgrammeProduction: Change Trend '" + referenceGUID + "': " + changeVal +". New Trend: "+ Popularity
	End Method


	'finished broacasting a programme (as programme, not trailer)
	Method FinishBroadcastingProgramme(data:TData)
		'scale audiencefactor (decrease total number by *0.75)
		Local quality:Float = data.GetFloat("quality", 0)
		Local audienceFactor:Float = Math.Clamp(data.GetInt("audienceSum", 0) / (data.GetInt("audienceMax", 1)), 0, 1)

		Local changeVal:Float = Math.Clamp(quality * audienceFactor, 0, 1.5)
		if changeVal = 0 then return 

		ChangeTrend(changeVal)
		'Print "FinishBroadcastingProgramme: Change Trend '" + referenceGUID + "': " + changeVal +"  newsSlot:"+newsSlot +". New Trend: "+ Popularity
	End Method
End Type