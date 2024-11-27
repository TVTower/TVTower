SuperStrict
Import "Dig/base.util.data.bmx"
Import "Dig/base.util.math.bmx"
Import "game.gameconstants.bmx"
Import "game.popularity.bmx"
Import "game.person.base.bmx"
Import "game.gamescriptexpression.bmx"


Type TPersonPopularity Extends TPopularity
	Function Create:TPersonPopularity(referenceID:Int, popularity:Float = 0.0, longTermPopularity:Float = 0.0)
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

		obj.referenceID = referenceID
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
		changeVal :* TVTPersonJob.GetCastJobImportanceMod(jobID)


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

Type TGameModifierPopularity_ModifyPersonPopularity extends TGameModifierPopularity_ModifyPopularity
	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierPopularity_ModifyPersonPopularity()
		return new TGameModifierPopularity_ModifyPersonPopularity
	End Function


	Method Copy:TGameModifierPopularity_ModifyPersonPopularity()
		local clone:TGameModifierPopularity_ModifyPersonPopularity = new TGameModifierPopularity_ModifyPersonPopularity
		
		clone.CopyBaseFrom(self)
		clone.CopyFrom(self)

		return clone
	End Method


	Method Init:TGameModifierPopularity_ModifyPersonPopularity(data:TData, extra:TData=null)
		Super.Init(data, extra)

		If data And data.GetString("time") Then self.data = data.copy()

		Return self
	End Method


	Method GetPopularity:TPopularity() override
		If popularityReferenceGUID And popularityReferenceGUID.contains("${")
			popularityReferenceGUID = GameScriptExpression.ParseLocalizedText(popularityReferenceGUID, new SScriptExpressionContext(null, 0, passedParams.get("variables"))).ToString()
		EndIf
		Local popularity:TPopularity = Super.GetPopularity()
		If Not popularity 
			Local person:TPersonBase
			If popularityReferenceID Then person = GetPerson(popularityReferenceID)
			If Not person And popularityReferenceGUID Then person = GetPersonByGUID(popularityReferenceGUID)
			
			If person and person.HasCustomPersonality()
				'the getter creates it if not done yet (so persons can
				'exist without "popularity" until it is required)
				popularity = person.GetPopularity()
			EndIf
		EndIf
		Return popularity
	End Method


	Method ToString:string()
		local name:string = ""
		if data then name = data.GetString("name", "default")
		return "TGameModifierPopularity_ModifyPersonPopularity ("+name+")"
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("ModifyPersonPopularity", TGameModifierPopularity_ModifyPersonPopularity.CreateNewInstance)
