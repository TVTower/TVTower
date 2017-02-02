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

	Global awardCreatorFunctions:TMap = new TMap
	Global awardCreatorFunctionCount:int = 0
	Global _instance:TAwardCollection


	Method New()
		'create the basic award creator ("UNDEFINED")
		if awardCreatorFunctionCount = 0
			print "Creating ~qundefined~q-award!"
			AddAwardCreatorFunction("undefined", TAward.CreateAward )
		endif
	End Method
	
	
	'override
	Function GetInstance:TAwardCollection()
		if not _instance then _instance = new TAwardCollection
		return _instance
	End Function


	Method Initialize:TAwardCollection()
		Super.Initialize()

		return self
	End Method


	Method GetByGUID:TAward(GUID:String)
		Return TAward( Super.GetByGUID(GUID) )
	End Method


	Method CreateAward:TAward(awardType:int)
		return RunAwardCreatorFunction( TVTAwardType.GetAsString(awardType) )
	End Method


	Method SetCurrentAward(award:TAward)
		'add if not done yet
		Add(award)

		Self.currentAward = award
	End Method


	Method GetCurrentAward:TAward()
		return Self.currentAward
	End Method


	Method AddUpcoming(award:TAward)
		upcomingAwards.AddLast(award)
	End Method


	Method RemoveUpcoming(award:TAward)
		upcomingAwards.Remove(award)
	End Method


	Method GetNextAward:TAward()
		if not upcomingAwards then return Null
		
		return TAward(upcomingAwards.First())
	End Method


	Method UpdateAwards()
		'if new day, not start day
'		If GetWorldTime().GetDaysRun() >= 1
		If GetWorldTime().GetDaysRun() >= 0
print "RONNY: UpdateAwards() GerDaysRun zurueckstellen!!"

			'=== FINISH CURRENT AWARD ===
			If currentAward and currentAward.GetEndTime() < GetWorldTime().GetTimeGone()
				'announce the winner and set time for next start
				if currentAward
					currentAward.Finish()
					currentAward = null
				endif
			EndIf


			'=== CREATE NEW AWARD ===
			If not currentAward and nextAwardTime <= GetWorldTime().GetTimeGone()
				local nextAward:TAward = GetNextAward()

				'create or fetch next award
				if nextAward
					RemoveUpcoming(nextAward)
				else
					local awardType:int
					'avoid AwardCustomProduction as first award in a game
					if GetCount() = 0
						Repeat
							awardType = RandRange(1, TVTAwardType.count)
						Until awardType <> TVTAwardType.CUSTOMPRODUCTION
					else
						awardType = RandRange(1, TVTAwardType.count)
					endif

					awardType = TVTAwardType.CULTURE
					nextAward = CreateAward(awardType)
				endif

				'adjust next award config
				nextAward.SetStartTime( nextAwardTime )
				nextAward.SetEndTime( nextAward.CalculateEndTime(nextAwardTime) )

				'set current award
				SetCurrentAward(nextAward)

				'pre-create the next award if needed
				if not GetNextAward()
					local awardType:int = RandRange(1, TVTAwardType.count)
					
					AddUpcoming( CreateAward(awardType) )
				endif


				'calculate next award time

				'set random waiting time for next award 
				timeBetweenAwards = TWorldTime.HOURLENGTH * RandRange(12,36)

				'set time to the next 0:00 coming _after the waiting
				'time is gone (or use that midnight if exactly 0:00)
				local nextTimeExact:Long = nextAward.GetEndTime() + timeBetweenAwards
				if GetWorldTime().GetDayHour(nextTimeExact) = 0 and GetWorldTime().GetDayMinute(nextTimeExact) = 0
					nextAwardTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(nextTimeExact), 0, 0)
				else
					nextAwardTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(nextTimeExact)+1, 0, 0)
				endif


				if nextAward
					local awardTypeString:string = TVTAwardType.GetAsString(nextAward.awardType)
					print "SetCurrentAward: type="+awardTypeString+" ["+nextAward.awardType+"] "+"  ends="+ GetWorldTime().GetFormattedGameDate(nextAward.GetEndTime()) +"  now="+GetWorldTime().GetFormattedGameDate()
					print "                 next="+GetWorldTime().GetFormattedGameDate(nextAwardTime)
				endif
			End If
		endif
	End Method


	Function AddAwardCreatorFunction(awardKey:string, func:TAward())
		awardKey = awardKey.ToLower()

		if not awardCreatorFunctions.Contains(awardKey)
			awardCreatorFunctionCount :+ 1
		endif
		local wrapper:TAwardCreatorFunctionWrapper = TAwardCreatorFunctionWrapper.Create(func)
		awardCreatorFunctions.Insert(awardKey.ToLower(), wrapper)
	End Function


	Function HasAwardCreatorFunction:int(awardKey:string)
		return awardCreatorFunctions.Contains(awardKey.ToLower())
	End Function


	Function RunAwardCreatorFunction:TAward(awardKey:string)
		local wrapper:TAwardCreatorFunctionWrapper = TAwardCreatorFunctionWrapper(awardCreatorFunctions.ValueForKey(awardKey.ToLower()))
		if wrapper and wrapper.func then return wrapper.func()

		print "RunAwardCreatorFunction: unknown awardKey ~q"+awardKey+"~q. Cannot create award instance."
		return null
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
		local obj:TAwardCreatorFunctionWrapper = new TAwardCreatorFunctionWrapper
		obj.func = func
		return obj
	End Function
End Type




Type TAward extends TGameObject
	Field scores:Int[4]
	Field awardType:Int = 0
	Field startTime:Long = -1
	Field endTime:Long = -1
	Field duration:Int = -1
	'basic prices all awards offer
	Field priceMoney:int = 50000
	Field priceImage:Float = 2.5

	Field _scoreSum:int = -1 {nosave}
	Field scoringMode:int = 1

	'adding/subtracting scores does not change other scores
	Const SCORINGMODE_ABSOLUTE:int = 1
	'adding/subtracting scores changes values for other players
	Const SCORINGMODE_AFFECT_OTHERS:int = 2

	

	Method New()
		awardType = TVTAwardType.UNDEFINED
	End Method


	Function CreateAward:TAward()
		return new TAward
	End Function


	Method GenerateGUID:string()
		return "award-"+id
	End Method


	Method GetTitle:string()
		return GetLocale("AWARDNAME_"+TVTAwardType.GetAsString(awardType))
	End Method


	Method GetText:string()
		return ""
	End Method


	Method GetRewardText:string()
		local result:string =""
		if priceImage <> 0
			if priceImage > 0 then result :+ chr(9654) + " " +GetLocale("CHANNEL_IMAGE")+": |color=0,125,0|+" + MathHelper.NumberToString(priceImage, 2)+"%|/color|"
			if priceImage < 0 then result :+ chr(9654) + " " +GetLocale("CHANNEL_IMAGE")+": |color=125,0,0|" + MathHelper.NumberToString(priceImage, 2)+"%|/color|"
		endif

		if priceMoney <> 0
			if result <> "" then result :+ "~n"
			if priceMoney > 0 then result :+ chr(9654) + " " +GetLocale("MONEY")+": |color=0,125,0|+" + MathHelper.DottedValue(priceMoney)+getLocale("CURRENCY")+"|/color|"
			if priceMoney < 0 then result :+ chr(9654) + " " +GetLocale("MONEY")+": |color=125,0,0|" + MathHelper.DottedValue(priceMoney)+getLocale("CURRENCY")+"|/color|"
		endif
		return result
	End Method


	Method Reset()
		scores = new Int[4]
		startTime = -1
		endTime = -1

		_scoreSum = -1
	End Method


	Method Finish:int()
		print "finish award"

		local winningPlayerID:int = GetCurrentWinner()
		EventManager.triggerEvent(TEventSimple.Create("Award.OnFinish", New TData.addNumber("winningPlayerID", winningPlayerID), Self))

		if winningPlayerID > 0
			local modifier:TGameModifierBase
			'increase image
			modifier = GetGameModifierManager().CreateAndInit("ModifyChannelPublicImage", new TData.AddNumber("value", priceImage))
			if modifier then modifier.Run(new TData.AddNumber("playerID", winningPlayerID) )

			'increase money
			modifier = GetGameModifierManager().CreateAndInit("ModifyChannelMoney", new TData.AddNumber("value", priceMoney))
			if modifier then modifier.Run(new TData.AddNumber("playerID", winningPlayerID) )

			'alternatively:
			'GetPublicImage(winnerID).Modify(0.5)
			'GetPlayerFinance(winnerID).EarnGrantedBenefits( priceMoney )
		endif
	
		return True
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
		local wt:TWorldTime = GetWorldTime()
		local durationHours:int = wt.GetHour(GetDuration())

		'round now to full hour
		local now:Long = GetWorldTime().MakeTime( 0, 0, wt.GetHour(nowTime) + (wt.GetDayMinute(nowTime)>0), 0, 0)

		'end time is minute before next full hour
		return GetWorldtime().ModifyTime(now, 0, 0, Max(0, durationHours-1), 59)
	End Method


	Method SetDuration(duration:Int)
		Self.duration = duration
	End Method


	Method GetDuration:int()
		if duration = -1
			'1 day
			duration = GetWorldTime().MakeTime(0, 1, 0, 0) 
		endif
		return duration
	End Method


	Method ResetScore(playerID:int)
		scores[playerID] = 0

		_scoreSum = -1
	End Method

	
	Method GetScoreSummary:string()
		local res:string
		for local i:int = 1 to 4
			res :+ RSet(GetScore(i),3)+" ("+RSet(MathHelper.NumberToString(GetScoreShare(i)*100,2)+"%",7)+")~t"
		Next
		return res
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
		if _scoreSum = -1
			_scoreSum = 0
			For local s:int = EachIn Self.scores
				_scoreSum :+ s
			Next
		endif

		return _scoreSum
	End Method


	Method AdjustScore(PlayerID:Int, amount:Int)
		'you cannot subtract more than what is there
		if amount < 0 then amount = - Min(abs(amount), abs(Self.scores[PlayerID-1]))

		Self.scores[PlayerID-1] = Max(0, Self.scores[PlayerID-1] + amount)
		'print "AdjustScore("+PlayerID+", "+amount+")"

		if scoringMode = SCORINGMODE_AFFECT_OTHERS
			'if score of a player _increases_ score of others will decrease
			'if score _decreases_, it increases score of others!
			local change:int = (0.5 * amount) / (Self.scores.length-1)
			For Local i:Int = 1 to Self.scores.length
				if i = PlayerID then continue
				Self.scores[i-1] = Max(0, Self.scores[i-1] - change)
			Next
		endif
		

		'reset cache
		Self._scoreSum = -1
	End Method


	Method GetAwardTypeString:String()
		return TVTAwardType.GetAsString(awardType)
	End Method


	Method GetStartTime:Long()
		return endTime
	End Method


	Method GetEndTime:Long()
		return endTime
	End Method
	

	Method GetDaysLeft:Int()
		Return GetWorldTime().GetDay() - GetWorldTime().GetDay(endTime)
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
