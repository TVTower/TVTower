SuperStrict
Import "Dig/base.util.data.bmx"
Import "Dig/base.util.math.bmx"
Import "game.gameconstants.bmx"
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
		changeVal :* TVTProgrammePersonJob.GetJobImportanceMod(jobID)


		'maximum adjustment is 1.5% ?
		changeVal = Min(Max(changeVal, 0), 1.5)

		if changeVal = 0 then return

		'Print "FinishProgrammeProduction: Change Trend '" + referenceGUID + "': " + changeVal +"  quality:"+quality +". Current Popularity: "+ Popularity
		ChangeTrend(changeVal)
	End Method


	'finished broacasting a programme (as programme, not trailer)
	Method FinishBroadcastingProgramme(data:TData)
		Local attractionQuality:Float = data.GetFloat("attractionQuality", 0)
		Local audienceFactor:Float = MathHelper.Clamp(data.GetFloat("audienceWholeMarketQuote", 0), 0, 1)

		Local changeVal:Float = MathHelper.Clamp(attractionQuality * audienceFactor, 0, 1.5)
		if changeVal = 0 then return

		'Print "FinishBroadcastingProgramme: Change Trend '" + referenceGUID + "': " + changeVal +"  attractionQuality:"+attractionQuality +"  audienceFactor:"+audienceFactor+". Current Popularity: "+ Popularity
		ChangeTrend(changeVal)
	End Method
End Type




'=== POPULARITY MODIFIERS ===

Type TGameModifierPopularity_ModifyPersonPopularity extends TGameModifierBase
	Field personGUID:string = ""
	'value is divided by 100 - so 1000 becomes 10, 50 becomes 0.5)
	Field valueMin:Float = 0
	Field valueMax:Float = 0
	Field modifyProbability:int = 100


	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierPopularity_ModifyPersonPopularity()
		return new TGameModifierPopularity_ModifyPersonPopularity
	End Function


	Method Copy:TGameModifierPopularity_ModifyPersonPopularity()
		local clone:TGameModifierPopularity_ModifyPersonPopularity = new TGameModifierPopularity_ModifyPersonPopularity
		clone.CopyBaseFrom(self)
		clone.personGUID = self.personGUID
		clone.valueMin = self.valueMin
		clone.valueMax = self.valueMax
		clone.modifyProbability = self.modifyProbability
		return clone
	End Method


	Method Init:TGameModifierPopularity_ModifyPersonPopularity(data:TData, extra:TData=null)
		if not data then return null

		'local source:TNewsEvent = TNewsEvent(data.get("source"))
		local index:string = ""
		if extra and extra.GetInt("childIndex") > 0 then index = extra.GetInt("childIndex")

		personGUID = data.GetString("guid"+index, data.GetString("guid", ""))
		if personGUID = ""
			TLogger.Log("TGameModifierPopularity_ModifyPersonPopularity", "Init() failed - no personGUID given.", LOG_ERROR)
			return Null
		endif

		valueMin = data.GetFloat("valueMin"+index, 0.0)
		valueMax = data.GetFloat("valueMax"+index, 0.0)
		modifyProbability = data.GetInt("probability"+index, 100)

		return self
	End Method


	Method ToString:string()
		local name:string = data.GetString("name", "default")
		return "TGameModifierPopularity_ModifyPersonPopularity ("+name+")"
	End Method


	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		'skip if probability is missed
		if modifyProbability <> 100 and RandRange(0, 100) > modifyProbability then return False

		local popularity:TPopularity = GetPopularityManager().GetByGUID(personGUID)
		if not popularity
			TLogger.Log("TGameModifierPopularity_ModifyPersonPopularity", "cannot find popularity to trigger: "+personGUID + " (maybe insignificant person)", LOG_ERROR)
			return false
		endif
		local changeBy:Float = RandRange(int(valueMin*1000), int(valueMax*1000))/1000.0
		'does adjust the "trend" (growth direction of popularity) not
		'popularity directly
		popularity.ChangeTrend(changeBy)
		popularity.SetPopularity(popularity.popularity + changeBy)
		'print "TGameModifierPopularity_ModifyPersonPopularity: changed trend for ~q"+personGUID+"~q by "+changeBy+" to " + popularity.Popularity+"."

		return True
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("ModifyPersonPopularity", TGameModifierPopularity_ModifyPersonPopularity.CreateNewInstance)
