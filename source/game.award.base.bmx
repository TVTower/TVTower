SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.logger.bmx"
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.math.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameconstants.bmx"
Import "game.gameobject.bmx"
Import "game.modifier.base.bmx"
Import "game.gameeventkeys.bmx"


Type TAwardCollection Extends TGameObjectCollection
	Field currentAward:TAward
	Field lastAwards:TList
	Field upcomingAwards:TList = CreateList()
	
	Global awardCreatorFunctions:TMap = New TMap
	Global awardCreatorFunctionCount:Int = 0
	Global _instance:TAwardCollection


	Method New()
		'create the basic award creator ("UNDEFINED")
		If awardCreatorFunctionCount = 0
			Print "Creating ~qundefined~q-award!"
			AddAwardCreatorFunction("undefined", TAward.CreateAward )
		EndIf
	End Method
	
	
	'override
	Function GetInstance:TAwardCollection()
		If Not _instance Then _instance = New TAwardCollection
		Return _instance
	End Function


	Method Initialize:TAwardCollection()
		Super.Initialize()
		
		upcomingAwards.Clear()
		if lastAwards then lastAwards.Clear()
		currentAward = Null

		Return Self
	End Method


	Method GetByGUID:TAward(GUID:String)
		Return TAward( Super.GetByGUID(GUID) )
	End Method


	Method CreateAward:TAward(awardType:Int)
		Return RunAwardCreatorFunction( TVTAwardType.GetAsString(awardType) )
	End Method


	Method SetCurrentAward(award:TAward, startTime:Long = -1)
		'add if not done yet
		Add(award)
		
		if self.currentAward <> award
			Self.currentAward = award
			Self.currentAward.Start()
		EndIf
	End Method


	Method GetCurrentAward:TAward()
		Return Self.currentAward
	End Method


	Method AddUpcoming(award:TAward)
		upcomingAwards.AddLast(award)
	End Method


	Method RemoveUpcoming(award:TAward)
		upcomingAwards.Remove(award)
	End Method
	
	
	Method PopNextAward:TAward()
		If Not upcomingAwards Then Return Null
		
		Return TAward(upcomingAwards.RemoveFirst())
	End Method
	

	Method GetNextAward:TAward()
		If Not upcomingAwards Then Return Null
		
		Return TAward(upcomingAwards.First())
	End Method


	Method GetNextAwardTime:Long()
		Local nextAward:TAward = TAward(upcomingAwards.First())
		If nextAward Then Return nextAward.GetStartTime()

		Return -1
	End Method


	Method FinishCurrentAward(overrideWinnerID:Int = -1)
		'announce the winner and set time for next start
		If currentAward
			currentAward.Finish(overrideWinnerID)

			if not lastAwards then lastAwards = new TList
			lastAwards.AddLast(currentAward)

			currentAward = Null
		EndIf
	End Method
	
	
	Method GenerateUpcomingAward(awardType:Int, forbiddenAwardTypes:Int[], startTime:Long = -1)
		If awardType <= 0
			Repeat
				awardType = RandRange(1, TVTAwardType.count)
			Until not MathHelper.InIntArray(awardType, forbiddenAwardTypes)
		EndIf

		if startTime = -1
			Local previousAward:TAward = TAward(upcomingAwards.Last())
			if not previousAward then previousAward = currentAward

			Local previousEndTime:Long
			if previousAward 
				previousEndTime = previousAward.GetEndTime()
			Else
				previousEndTime = GetWorldTime().GetTimeGone()
			EndIf

			'set time to the next 0:00 coming _after the waiting
			'time is gone (or use that midnight if exactly 0:00)
			'set random waiting time for next award 
			Local startTimeExact:Long = previousEndTime + TWorldTime.HOURLENGTH * RandRange(24,96)
			If GetWorldTime().GetDayHour(startTimeExact) = 0 And GetWorldTime().GetDayMinute(startTimeExact) = 0
				startTime = GetWorldTime().GetTimeGoneForGameTime(0, GetWorldTime().GetDay(startTimeExact), 0, 0)
			Else
				startTime = GetWorldTime().GetTimeGoneForGameTime(0, GetWorldTime().GetDay(startTimeExact)+1, 0, 0)
			EndIf
		EndIf


		Local award:TAward = CreateAward(awardType)
		award.SetStartTime( startTime )
		award.SetEndTime( award.CalculateEndTime(startTime) )
		If lastAwards
			Local awardCount:Int = 0
			For Local a:TAward = EachIn lastAwards
				If a.awardType = awardType then awardCount:+ 1
			Next
			award.priceImage = Max(0.5, award.priceImage - awardCount * 0.25)
		EndIf
		AddUpcoming( award )
		TLogger.Log("TAwardCollection.GenerateUpcomingAward()", "Generated ~qupcoming~q award: type="+TVTAwardType.GetAsString(award.awardType)+" ["+award.awardType+"] "+"  timeframe="+GetWorldTime().GetFormattedGameDate(award.GetStartTime()) +"  -  " + GetWorldTime().GetFormattedGameDate(award.GetEndTime()) +"  now="+GetWorldTime().GetFormattedGameDate(), LOG_DEBUG)
	End Method

	

	Method UpdateAwards()
		'=== CREATE UPCOMING AWARD ===
		If not GetNextAward()
			'avoid AwardCustomProduction as first award in a game
			If GetWorldTime().GetDaysRun() = 0
				GenerateUpcomingAward(-1, [TVTAwardType.CUSTOMPRODUCTION], GetWorldTime().GetTimeGoneForGameTime(0, GetWorldTime().GetDay()+1, 0, 0))
			Else
				GenerateUpcomingAward(-1, Null)
			EndIf
		EndIf
		

		'=== FINISH CURRENT AWARD ===
		If currentAward And currentAward.GetEndTime() < GetWorldTime().GetTimeGone()
			FinishCurrentAward()
		EndIf


		'=== ACTIVATE NEXT AWARD ===
		If Not currentAward And GetNextAwardTime() <= GetWorldTime().GetTimeGone()
			SetCurrentAward( PopNextAward() )
		EndIf
	End Method


	Function AddAwardCreatorFunction(awardKey:String, func:TAward())
		awardKey = awardKey.ToLower()

		If Not awardCreatorFunctions.Contains(awardKey)
			awardCreatorFunctionCount :+ 1
		EndIf
		Local wrapper:TAwardCreatorFunctionWrapper = TAwardCreatorFunctionWrapper.Create(func)
		awardCreatorFunctions.Insert(awardKey.ToLower(), wrapper)
	End Function


	Function HasAwardCreatorFunction:Int(awardKey:String)
		Return awardCreatorFunctions.Contains(awardKey.ToLower())
	End Function


	Function RunAwardCreatorFunction:TAward(awardKey:String)
		Local wrapper:TAwardCreatorFunctionWrapper = TAwardCreatorFunctionWrapper(awardCreatorFunctions.ValueForKey(awardKey.ToLower()))
		If wrapper And wrapper.func Then Return wrapper.func()

		Print "RunAwardCreatorFunction: unknown awardKey ~q"+awardKey+"~q. Cannot create award instance."
		Return Null
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAwardCollection:TAwardCollection()
	Return TAwardCollection.GetInstance()
End Function




Type TAwardCreatorFunctionWrapper
	Field func:TAward()

	Function Create:TAwardCreatorFunctionWrapper(func:TAward())
		Local obj:TAwardCreatorFunctionWrapper = New TAwardCreatorFunctionWrapper
		obj.func = func
		Return obj
	End Function
End Type




Type TAward Extends TGameObject
	Field scores:Int[4]
	Field awardType:Int = 0
	Field startTime:Long = -1
	Field endTime:Long = -1
	Field duration:Long = -1
	'basic prices all awards offer
	Field priceMoney:Int = 50000
	Field priceImage:Float = 1.5
	Field priceBettyLove:Int = 0

	Field _scoreSum:Int = -1 {nosave}
	Field scoringMode:Int = 1
	Field winningPlayerID:Int = -1

	'adding/subtracting scores does not change other scores
	Const SCORINGMODE_ABSOLUTE:Int = 1
	'adding/subtracting scores changes values for other players
	Const SCORINGMODE_AFFECT_OTHERS:Int = 2


	Method New()
		awardType = TVTAwardType.UNDEFINED
	End Method


	Function CreateAward:TAward()
		Return New TAward
	End Function


	Method GenerateGUID:String()
		Return "award-"+id
	End Method


	Method GetTitle:String()
		Return GetLocale("AWARDNAME_"+TVTAwardType.GetAsString(awardType))
	End Method


	Method GetText:String()
		Return ""
	End Method


	Method GetRewardText:String()
		Local result:String =""
		If priceImage <> 0
			If priceImage > 0 Then result :+ Chr(9654) + " " +GetLocale("CHANNEL_IMAGE")+": |color=0,125,0|+" + MathHelper.NumberToString(priceImage, 2)+"%|/color|"
			If priceImage < 0 Then result :+ Chr(9654) + " " +GetLocale("CHANNEL_IMAGE")+": |color=125,0,0|" + MathHelper.NumberToString(priceImage, 2)+"%|/color|"
		EndIf

		rem
		'deactivated - do not directly mention a betty-love-gain
		If priceBettyLove <> 0
			If result <> "" Then result :+ "~n"
			If priceBettyLove > 0 Then result :+ Chr(9654) + " Betty: |color=0,125,0|+" + priceBettyLove + "|/color|"
			If priceBettyLove < 0 Then result :+ Chr(9654) + " Betty: |color=125,0,0|" + priceBettyLove + "|/color|"
		EndIf
		endrem

		If priceMoney <> 0
			If result <> "" Then result :+ "~n"
			If priceMoney > 0 Then result :+ Chr(9654) + " " +GetLocale("MONEY")+": |color=0,125,0|+" + GetFormattedCurrency(priceMoney)+"|/color|"
			If priceMoney < 0 Then result :+ Chr(9654) + " " +GetLocale("MONEY")+": |color=125,0,0|" + GetFormattedCurrency(priceMoney)+"|/color|"
		EndIf

		Return result
	End Method


	Method Reset()
		scores = New Int[4]
		startTime = -1
		endTime = -1

		_scoreSum = -1
	End Method
	
	
	Method Start:Int()
		SetStartTime( GetWorldTime().GetTimeGone() )
		SetEndTime( CalculateEndTime(startTime) )

		TLogger.Log("TAward.Start()", "Started award: type="+TVTAwardType.GetAsString(awardType)+" ["+awardType+"] "+"  timeframe="+GetWorldTime().GetFormattedGameDate(GetStartTime()) +"  -  " + GetWorldTime().GetFormattedGameDate(GetEndTime()) +"  now="+GetWorldTime().GetFormattedGameDate(), LOG_DEBUG)
	End Method


	Method Finish:Int(overrideWinnerID:Int = -1)
		'end time might differ (earlier finish)
		SetEndTime( GetWorldTime().GetTimeGone() )
		'store winner
		If overrideWinnerID > -1
			winningPlayerID = overrideWinnerID
		Else
			winningPlayerID = GetCurrentWinner()
		EndIf

		TLogger.Log("TAward.Finish()", "Finishing award. winner="+winningPlayerID, LOG_DEBUG)

		TriggerBaseEvent(GameEventKeys.Award_OnFinish, New TData.Add("winningPlayerID", winningPlayerID), Self)

		If winningPlayerID > 0
			Local modifier:TGameModifierBase
			'increase image
			modifier = GetGameModifierManager().CreateAndInit("ModifyChannelPublicImage", New TData.Add("value", priceImage))
			If modifier Then modifier.Run(New TData.Add("playerID", winningPlayerID) )

			'increase money
			modifier = GetGameModifierManager().CreateAndInit("ModifyChannelMoney", New TData.Add("value", priceMoney))
			If modifier Then modifier.Run(New TData.Add("playerID", winningPlayerID) )
			
			'increase betty's love to you
			modifier = GetGameModifierManager().CreateAndInit("ModifyBettyLove", New TData.Add("value", priceBettyLove))
			If modifier Then modifier.Run(New TData.Add("playerID", winningPlayerID) )

			'alternatively:
			'GetPublicImage(winnerID).Modify(0.5)
			'GetPlayerFinance(winnerID).EarnGrantedBenefits( priceMoney )
		EndIf
	
		Return True
	End Method


	Method SetAwardType(awardType:Int)
		Self.awardType = awardType
	End Method


	Method SetStartTime(time:Long)
		Self.startTime = time
	End Method


	Method SetEndTime(time:Long)
		Self.endTime = time
	End Method


	Method CalculateEndTime:Long(nowTime:Long = -1)
		Local wt:TWorldTime = GetWorldTime()
		Local durationHours:Int = wt.GetHour(GetDuration())

		'round now to full hour
		Local now:Long = GetWorldTime().GetTimeGoneForGameTime( 0, 0, wt.GetHour(nowTime) + (wt.GetDayMinute(nowTime)>0), 0, 0)

		'end time is minute before next full hour
		Return GetWorldtime().ModifyTime(now, 0, 0, Max(0, durationHours-1), 59)
	End Method


	Method SetDuration(duration:Long)
		Self.duration = duration
	End Method


	Method GetDuration:Long()
		If duration = -1
			'1 day
			duration = GetWorldTime().GetTimeGoneForGameTime(0, 1, 0, 0) 
		EndIf
		Return duration
	End Method


	Method ResetScore(playerID:Int)
		scores[playerID-1] = 0

		_scoreSum = -1
	End Method

	
	Method GetScoreSummary:String()
		Local res:String
		For Local i:Int = 1 To 4
			res :+ RSet(GetScore(i),3)+" ("+RSet(MathHelper.NumberToString(GetScoreShare(i)*100,2)+"%",7)+")~t"
		Next
		Return res
	End Method


	'returns a value how score is shared between players
	Method GetScoreShare:Float(PlayerID:Int)
		If GetScoreSum() > 0 
			Return Max(0.0, Min(1.0, Self.scores[PlayerID -1] / Float( GetScoreSum() )))
		Else
			Return 1.0 / Self.scores.length
		EndIf
	End Method


	Method GetScore:Int(PlayerID:Int)
		Return Self.scores[PlayerID-1]
	End Method


	Method GetScoreSum:Int()
		If _scoreSum = -1
			_scoreSum = 0
			For Local s:Int = EachIn Self.scores
				_scoreSum :+ s
			Next
		EndIf

		Return _scoreSum
	End Method


	Method AdjustScore(PlayerID:Int, amount:Int)
		'you cannot subtract more than what is there
		If amount < 0 Then amount = - Min(Abs(amount), Abs(Self.scores[PlayerID-1]))

		Self.scores[PlayerID-1] = Max(0, Self.scores[PlayerID-1] + amount)
		'print "AdjustScore("+PlayerID+", "+amount+")"

		If scoringMode = SCORINGMODE_AFFECT_OTHERS And Self.scores.length > 1
			'if score of a player _increases_ score of others will decrease
			'if score _decreases_, it increases score of others!
			Local change:Int = (0.5 * amount) / (Self.scores.length-1)
			For Local i:Int = 1 To Self.scores.length
				If i = PlayerID Then Continue
				Self.scores[i-1] = Max(0, Self.scores[i-1] - change)
			Next
		EndIf
		

		'reset cache
		Self._scoreSum = -1
	End Method


	Method GetAwardTypeString:String()
		Return TVTAwardType.GetAsString(awardType)
	End Method


	Method GetStartTime:Long()
		Return startTime
	End Method


	Method GetEndTime:Long()
		Return endTime
	End Method
	

	Method GetDaysLeft:Int()
		Return GetWorldTime().GetDay() - GetWorldTime().GetDay(endTime)
	End Method


	Method GetCurrentRank:Int(playerID:Int)
		If playerID < 1 Or playerID > Self.scores.length Then Return 0

		Local rank:Int = 1
		Local myScore:Int = Self.scores[playerID-1]
		For Local i:Int = 1 To scores.length
			If i = playerID Then Continue
			If Self.scores[i-1] > myScore
				rank :+ 1
			EndIf
		Next
		Return rank
	End Method


	Method GetRanks:Int()
		Return Self.scores.length
	End Method
	

	Method GetCurrentWinner:Int()
		Local bestScore:Int = 0
		Local bestPlayer:Int = 0
		For Local i:Int = 1 To scores.length
			If Self.scores[i-1] > bestScore
				bestScore = Self.scores[i-1]
				bestPlayer = i
			EndIf
		Next
		Return bestPlayer
	End Method
End Type
