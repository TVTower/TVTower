SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.logger.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx"


Type TAwardBaseCollection Extends TGameObjectCollection
	Field currentAward:TAwardBase
	Field upcomingAwards:TList = CreateList()
	Field lastAwardWinner:Int = 0
	Field lastAwardType:Int = 0

	Global _instance:TAwardBaseCollection

	
	'override
	Function GetInstance:TAwardBaseCollection()
		if not _instance then _instance = new TAwardBaseCollection
		return _instance
	End Function


	Method Initialize:TAwardBaseCollection()
		Super.Initialize()
		return self
	End Method


	Method GetByGUID:TAwardBase(GUID:String)
		Return TAwardBase( Super.GetByGUID(GUID) )
	End Method


	Method CreateAward:TAwardBase(awardType:int, endTime:int)
		'for now only basic award support

		local a:TAwardBase = new TAwardBase
		a.awardType = awardType
		a.SetEndTime(endTime)
		print "CreateAward:  type="+awardType+"  ends="+ GetWorldTime().GetFormattedGameDate(endTime) +"  now="+GetWorldTime().GetFormattedGameDate()

		return a
	End Method


	Method SetCurrentAward(award:TAwardBase)
		'add if not done yet
		Add(award)

		Self.currentAward = award
	End Method


	Method GetCurrentAward:TAwardBase()
		return Self.currentAward
	End Method


	Method AddUpcoming(award:TAwardBase)
		upcomingAwards.AddLast(award)
	End Method


	Method RemoveUpcoming(award:TAwardBase)
		upcomingAwards.Remove(award)
	End Method


	Function SortAwardsByBeginDate:int(o1:object, o2:object)
		local a1:TAwardBase = TAwardBase(o1)
		local a2:TAwardBase = TAwardBase(o2)
		if not a2 then return 1
		if not a1 then return -1

		if a1.startTime > a2.startTime then return 1
		if a1.startTime < a2.startTime then return -1

		return 0
	End Function


	Method GetNextAward:TAwardBase(sortUpcoming:int = False)
		if not upcomingAwards then return Null
		
		'sort upcoming awards so topmost is the next one
		'(do it here so it takes account of potentially adjusted
		' begin times of the contained awards)
		if sortUpcoming
			upcomingAwards.Sort(true, SortAwardsByBeginDate)
		endif
		
		return TAwardBase(upcomingAwards.First())
	End Method


	Method UpdateAwards()
		'if new day, not start day
		If GetWorldTime().GetDaysRun() >= 1
			'need to create a new award?
			If not currentAward or currentAward.GetEndTime() < GetWorldTime().GetTimeGone()
				'announce the winner
				if currentAward then currentAward.Finish()

				'fetch the next award (and sort upcoming list before)
				local nextAward:TAwardBase = GetNextAward(true)

				if nextAward
					RemoveUpcoming(nextAward)

				'create a new award if there is nothingplanned - or the
				'next one is later than X days
				else
					local awardType:int = RandRange(1, TVTAwardType.count)
					'end in ~3 days (2 days + 23h59m)
					local awardEndTime:Long = GetWorldTime().MakeTime( 0, GetWorldTime().GetOnDay() + 2, 23, 59)

					nextAward = CreateAward(awardType, awardEndTime)
				endif

				SetCurrentAward(nextAward)
			End If
		endif
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAwardBaseCollection:TAwardBaseCollection()
	Return TAwardBaseCollection.GetInstance()
End Function




Type TAwardBase extends TGameObject
	Field scores:Int[4]
	Field awardType:Int = 0
	Field startTime:Long = -1
	Field endTime:Long = -1
	'cached values
	Field _scoreSum:int = -1 {nosave}


	Method GenerateGUID:string()
		return "awardbase-"+id
	End Method


	Method Reset()
		scores = new Int[4]
		awardType = 0
		startTime = -1
		endTime = -1

		_scoreSum = -1
	End Method


	Method Finish()
		print "finish award"
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


	Method ResetScore(playerID:int)
		scores[playerID] = 0

		_scoreSum = -1
	End Method

	
	Method GetScoreSummary:string()
		local res:string
		for local i:int = 1 to 4
			res :+ RSet(GetScore(i),3)+" ("+RSet(MathHelper.NumberToString(GetScorePercentage(i)*100,2)+"%",7)+")~t"
		Next
		return res
	End Method


	Method GetScorePercentage:Float(PlayerID:Int)
		Return GetScore(PlayerID) / Float(GetScoreSum())
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

		'if score of a player _increases_ score of others will decrease
		'if score _decreases_, it increases score of others!
		local change:int = (0.5 * amount) / (Self.scores.length-1)
		For Local i:Int = 0 until Self.scores.length
			if i = PlayerID then continue
			Self.scores[i] = Max(0, Self.scores[i] - change)
		Next

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