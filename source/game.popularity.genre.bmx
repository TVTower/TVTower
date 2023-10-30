SuperStrict
Import "Dig/base.util.data.bmx"
Import "game.popularity.bmx"


Type TGenrePopularity Extends TPopularity

	Field broadCastCountSinceUpdate:Int = 0

	Function Create:TGenrePopularity(referenceID:Int, popularity:Float = 0.0, longTermPopularity:Float = 0.0)
		Local obj:TGenrePopularity = New TGenrePopularity

		obj.LongTermPopularityLowerBound     = -50
		obj.LongTermPopularityUpperBound     =  50

		obj.SurfeitLowerBoundAdd             = -30
		obj.SurfeitUpperBoundAdd             =  35
		obj.SurfeitTrendMalus                =   5
		obj.SurfeitCounterUpperBoundAdd      =   3

		obj.TrendLowerBound                  = -10
		obj.TrendUpperBound                  =  10
		obj.TrendAdjustDivider               =   5
		obj.TrendRandRangLower               = -15
		obj.TrendRandRangUpper               =  15

		obj.ChanceToChangeCompletely         =   2
		obj.ChanceToChange                   =  15
		obj.ChanceToAdjustLongTermPopularity =  25

		obj.ChangeLowerBound                 = -35
		obj.ChangeUpperBound                 =  35

		obj.referenceID = referenceID
		obj.SetPopularity(popularity)
		obj.SetLongTermPopularity(longTermPopularity)

		Return obj
	End Function


	'a programme just finished airing
	Method FinishBroadcastingProgramme(data:TData, blocks:Int)
		Local quality:Float = data.GetFloat("attractionQuality", 0)
		'scale audiencefactor (decrease total number by *0.75)
		Local audienceFactor:Float = data.GetInt("audienceSum", 0) / (data.GetInt("broadcastTopAudience", 1) * 0.75)
		audienceFactor = Min(Max(audienceFactor, 0.1), 1)

		Local changeVal:Float = quality * audienceFactor
		select blocks
			case 1	changeVal :* 1
			case 2	changeVal :* 1.4
			case 3	changeVal :* 1.6
			default	changeVal :* 1.8
		end select

		changeVal = Min(Max(changeVal, 0.25), 1.5)

		ChangeTrend(changeVal)
		'Print "BroadcastedProgramme: Change Trend '" + referenceGUID + "': " + changeVal +". New Trend: "+ Popularity

		Local wholeMarketQuote:Float = data.GetFloat("audienceWholeMarketQuote")
		'do not count as broadcast if audience was too small
		If Not wholeMarketQuote Or wholeMarketQuote >= 0.005
			broadCastCountSinceUpdate:+ 1

			'decrease popularity a bit with each broadcast
			If Popularity > -5
				Local diff:Float = 0.8^(broadCastCountSinceUpdate-1)
				Popularity:- diff
			EndIf
		EndIf
		'decrease long term popularity with first broadcast
		If broadCastCountSinceUpdate = 1 And LongTermPopularity > -5 Then SetLongTermPopularity(LongTermPopularity - 1)
	End Method


	'a programme just finished airing
	Method FinishBroadcastingNews(data:TData, newsSlot:Int)
		'scale audiencefactor (decrease total number by *0.75)
		Local quality:Float = data.GetFloat("attractionQuality", 0)
		Local audienceFactor:Float = data.GetInt("audienceSum", 0) / (data.GetInt("broadcastTopAudience", 1) * 0.75)
		audienceFactor = Min(Max(audienceFactor, 0.1), 1)

		Local changeVal:Float = quality * audienceFactor

		'each news slot has less influence to the trends
		select newsSlot
			case 1	changeVal :* 0.6
			case 2	changeVal :* 0.4
			case 3	changeVal :* 0.2
		end select

		changeVal = Min(Max(changeVal, 0.25), 1.5)

		ChangeTrend(changeVal)
		'Print "BroadcastedNews: Change Trend '" + referenceGUID + "': " + changeVal +"  newsSlot:"+newsSlot +". New Trend: "+ Popularity
	End Method

	Method UpdatePopularity() override
		'Increase popularity of programme genres not broadcasted
		If broadCastCountSinceUpdate = 0 And referenceGUID.startsWith("moviegenre")
			If Popularity < 0
				Popularity:+ 5
			ElseIf Popularity < 20
				Popularity:+ 3
			Else
				Popularity:+ 1
			EndIf
			If LongTermPopularity < 0
				SetLongTermPopularity(LongTermPopularity + 5)
			ElseIf LongTermPopularity < 10
				SetLongTermPopularity(LongTermPopularity + 3)
			ElseIf LongTermPopularity < 20
				SetLongTermPopularity(LongTermPopularity + 1)
			EndIf
			'print "increasing popularity due to non-broadcast "+referenceGUID+ " "+ Popularity + " "+LongTermPopularity
		EndIf
		super.UpdatePopularity()
		broadCastCountSinceUpdate = 0
	EndMethod
End Type