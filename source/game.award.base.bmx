SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.logger.bmx"
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.math.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameconstants.bmx"
Import "game.gameobject.bmx"
Import "game.modifier.base.bmx"


Type TAwardCollection Extends TGameObjectCollection
	Field currentAward:TAward
	Field upcomingAwards:TList = CreateList()
	Field nextAwardTime:Long = -1
	Field timeBetweenAwards:Int = 0
	Field lastAwardWinner:Int = 0
	Field lastAwardType:Int = 0

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

		Return Self
	End Method


	Method GetByGUID:TAward(GUID:String)
		Return TAward( Super.GetByGUID(GUID) )
	End Method


	Method CreateAward:TAward(awardType:Int)
		Return RunAwardCreatorFunction( TVTAwardType.GetAsString(awardType) )
	End Method


	Method SetCurrentAward(award:TAward)
		'add if not done yet
		Add(award)

		Self.currentAward = award
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


	Method GetNextAward:TAward()
		If Not upcomingAwards Then Return Null
		
		Return TAward(upcomingAwards.First())
	End Method


	Method GetNextAwardTime:Long()
		Return nextAwardTime
	End Method


	Method UpdateAwards()
		'=== CREATE INITIAL AWARD ===
		If GetWorldTime().GetDaysRun() = 0 And Not GetNextAward()
			'avoid AwardCustomProduction as first award in a game
			Local awardType:Int = 0
			Repeat
				awardType = RandRange(1, TVTAwardType.count)
			Until awardType <> TVTAwardType.CUSTOMPRODUCTION
			'awardType = TVTAwardType.CULTURE

			'set to start next day
			nextAwardTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay()+1, 0, 0)
			Local award:TAward = CreateAward(awardType)
			award.SetStartTime( nextAwardTime )
			award.SetEndTime( award.CalculateEndTime(nextAwardTime) )
			AddUpcoming( award )
			TLogger.Log("TAwardCollection.UpdateAwards()", "Set initial ~qnext~q award: type="+TVTAwardType.GetAsString(award.awardType)+" ["+award.awardType+"] "+"  timeframe="+GetWorldTime().GetFormattedGameDate(award.GetStartTime()) +"  -  " + GetWorldTime().GetFormattedGameDate(award.GetEndTime()) +"  now="+GetWorldTime().GetFormattedGameDate(), LOG_DEBUG)
		EndIf
		

		'=== FINISH CURRENT AWARD ===
		If currentAward And currentAward.GetEndTime() < GetWorldTime().GetTimeGone()
			'announce the winner and set time for next start
			If currentAward
				TLogger.Log("TAwardCollection.UpdateAwards()", "Finish current award award: type="+TVTAwardType.GetAsString(currentAward.awardType)+" ["+currentAward.awardType+"] "+"  timeframe="+GetWorldTime().GetFormattedGameDate(currentAward.GetStartTime()) +"  -  " + GetWorldTime().GetFormattedGameDate(currentAward.GetEndTime()) +"  now="+GetWorldTime().GetFormattedGameDate(), LOG_DEBUG)
				currentAward.Finish()
				currentAward = Null
			EndIf
		EndIf


		'=== CREATE NEW AWARD ===
		If Not currentAward And GetNextAwardTime() <= GetWorldTime().GetTimeGone()
			Local nextAward:TAward = GetNextAward()

			'create or fetch next award
			If nextAward
				RemoveUpcoming(nextAward)
			Else
				Local awardType:Int = RandRange(1, TVTAwardType.count)
				nextAward = CreateAward(awardType)
			EndIf

			'adjust next award config
			nextAward.SetStartTime( nextAwardTime )
			nextAward.SetEndTime( nextAward.CalculateEndTime(nextAwardTime) )

			'set current award
			SetCurrentAward(nextAward)
			nextAward = Null


			'pre-create the next award if needed
			If Not GetNextAward()
				Local awardType:Int = RandRange(1, TVTAwardType.count)
				nextAward = CreateAward(awardType)

				AddUpcoming( nextAward )
			EndIf

			'calculate next award time

			'set random waiting time for next award 
			timeBetweenAwards = TWorldTime.HOURLENGTH * RandRange(12,36)

			'set time to the next 0:00 coming _after the waiting
			'time is gone (or use that midnight if exactly 0:00)
			Local nextTimeExact:Long = currentAward.GetEndTime() + timeBetweenAwards
			If GetWorldTime().GetDayHour(nextTimeExact) = 0 And GetWorldTime().GetDayMinute(nextTimeExact) = 0
				nextAwardTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(nextTimeExact), 0, 0)
			Else
				nextAwardTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(nextTimeExact)+1, 0, 0)
			EndIf
			If nextAward
				nextAward.SetStartTime( nextAwardTime )
			EndIf


			TLogger.Log("TAwardCollection.UpdateAwards()", "Set current award: type="+TVTAwardType.GetAsString(currentAward.awardType)+" ["+currentAward.awardType+"] "+"  timeframe="+GetWorldTime().GetFormattedGameDate(currentAward.GetStartTime()) +"  -  " + GetWorldTime().GetFormattedGameDate(currentAward.GetEndTime()) +"  now="+GetWorldTime().GetFormattedGameDate(), LOG_DEBUG)
			If nextAward
				TLogger.Log("TAwardCollection.UpdateAwards()", "Set next award: type="+TVTAwardType.GetAsString(nextAward.awardType)+" ["+nextAward.awardType+"] "+"  timeframe="+GetWorldTime().GetFormattedGameDate(nextAward.GetStartTime()) +"  -  " + GetWorldTime().GetFormattedGameDate(nextAward.GetEndTime()), LOG_DEBUG)
			EndIf
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
	Field duration:Int = -1
	'basic prices all awards offer
	Field priceMoney:Int = 50000
	Field priceImage:Float = 2.5

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

		If priceMoney <> 0
			If result <> "" Then result :+ "~n"
			If priceMoney > 0 Then result :+ Chr(9654) + " " +GetLocale("MONEY")+": |color=0,125,0|+" + MathHelper.DottedValue(priceMoney)+getLocale("CURRENCY")+"|/color|"
			If priceMoney < 0 Then result :+ Chr(9654) + " " +GetLocale("MONEY")+": |color=125,0,0|" + MathHelper.DottedValue(priceMoney)+getLocale("CURRENCY")+"|/color|"
		EndIf
		Return result
	End Method


	Method Reset()
		scores = New Int[4]
		startTime = -1
		endTime = -1

		_scoreSum = -1
	End Method


	Method Finish:Int()
		Print "finish award"

		'store winner
		winningPlayerID = GetCurrentWinner()
		EventManager.triggerEvent(TEventSimple.Create("Award.OnFinish", New TData.addNumber("winningPlayerID", winningPlayerID), Self))

		If winningPlayerID > 0
			Local modifier:TGameModifierBase
			'increase image
			modifier = GetGameModifierManager().CreateAndInit("ModifyChannelPublicImage", New TData.AddNumber("value", priceImage))
			If modifier Then modifier.Run(New TData.AddNumber("playerID", winningPlayerID) )

			'increase money
			modifier = GetGameModifierManager().CreateAndInit("ModifyChannelMoney", New TData.AddNumber("value", priceMoney))
			If modifier Then modifier.Run(New TData.AddNumber("playerID", winningPlayerID) )

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
		Local now:Long = GetWorldTime().MakeTime( 0, 0, wt.GetHour(nowTime) + (wt.GetDayMinute(nowTime)>0), 0, 0)

		'end time is minute before next full hour
		Return GetWorldtime().ModifyTime(now, 0, 0, Max(0, durationHours-1), 59)
	End Method


	Method SetDuration(duration:Int)
		Self.duration = duration
	End Method


	Method GetDuration:Int()
		If duration = -1
			'1 day
			duration = GetWorldTime().MakeTime(0, 1, 0, 0) 
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
