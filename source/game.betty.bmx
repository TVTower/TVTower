SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.logger.bmx"
Import "game.world.worldtime.bmx"




Type TBetty
	Field InLove:Long[4]
	Field LoveSum:Long
	Field AwardWinner:Long[4]
	Field AwardSum:Float = 0.0
	Field CurrentAwardType:Int = 0
	Field AwardEndingAtDay:Int = 0
	Field MaxAwardTypes:Int = 3
	Field AwardDuration:Int = 3
	Field LastAwardWinner:Int = 0
	Field LastAwardType:Int = 0
	Global _instance:TBetty
	Const LOVE_MAXIMUM:int = 10000


	Function GetInstance:TBetty()
		if not _instance then _instance = new TBetty
		return _instance
	End Function


	Method Initialize:int()
		InLove = new Long[4]
		LoveSum = 0
		AwardWinner = new Long[4]
		AwardSum = 0.0
		CurrentAwardType = 0
		AwardEndingAtDay = 0
		MaxAwardTypes = 3
		AwardDuration = 3
		LastAwardWinner = 0
		LastAwardType = 0
	End Method


	Method GivePresent:int(playerID:int, present:TBettyPresent)
		if not present then return False
		'TODO: collect times betty got this present
		'      each time decreases "effect" ...
		
		AdjustLove(playerId, present.bettyValue)

		TLogger.Log("Betty", "Player "+playerID+" gave Betty a present ~q"+present.GetName()+"~q.", LOG_DEBUG)
		return True
	End Method

	
	Method GetLoveSummary:string()
		local res:string
		res :+ RSet(GetInLove(1),5)+" ("+RSet(LSet(GetInLoveShare(1),4)+"%",7)+")~t"
		res :+ RSet(GetInLove(2),5)+" ("+RSet(LSet(GetInLoveShare(2),4)+"%",7)+")~t"
		res :+ RSet(GetInLove(3),5)+" ("+RSet(LSet(GetInLoveShare(3),4)+"%",7)+")~t"
		res :+ RSet(GetInLove(4),5)+" ("+RSet(LSet(GetInLoveShare(4),4)+"%",7)+")~t"
		return res
	End Method
	

	Method AdjustLove(PlayerID:Int, Amount:Int)
		'modify each players love amount (eg. subtract) 
		For Local i:Int = 0 until 4
			Self.InLove[i] :- Amount / 4
		Next

		'add back the "lost" sum to the player + 25%
		Self.InLove[PlayerID-1] :+ Amount * 5 / 4

		Self.LoveSum = 0

		For Local i:Int = 0 Until 4
			'only add positive ones
			Self.LoveSum :+ Max(0, Self.InLove[i])
		Next
	End Method


	Method AdjustAward(PlayerID:Int, Amount:Float)
		For Local i:Int = 0 Until 4
			Self.AwardWinner[i] :-Amount / 4
		Next
		Self.AwardWinner[PlayerID-1] :+ Amount * 5 / 4
		Self.AwardSum = 0
		For Local i:Int = 0 Until 4
			Self.AwardSum :+ Self.AwardWinner[i]
		Next
	End Method


	Method GetAwardTypeString:String(AwardType:Int = 0)
		If AwardType = 0 Then AwardType = CurrentAwardType
		Select AwardType
			Case 0 Return "NONE"
			Case 1 Return "News"
			Case 2 Return "Kultur"
			Case 3 Return "Quoten"
		End Select
	End Method


	Method SetAwardType(AwardType:Int = 0, SetEndingDay:Int = 0, Duration:Int = 0)
		If Duration = 0 Then Duration = Self.AwardDuration
		CurrentAwardType = AwardType
		If SetEndingDay = True Then AwardEndingAtDay = GetWorldTime().GetDay() + Duration
	End Method


	Method GetAwardEnding:Int()
		Return AwardEndingAtDay
	End Method


	Method GetInLove:Int(PlayerID:Int)
		Return Self.InLove[PlayerID -1]
	End Method


	Method GetInLovePercentage:Float(PlayerID:Int)
		Return Self.InLove[PlayerID -1] / Float(LOVE_MAXIMUM)
	End Method


	'returns a value how love is shared between players
	Method GetInLoveShare:Float(PlayerID:Int)
		If Self.LoveSum <= 0 then return 0
		Return Max(0.0, Min(1.0, Self.InLove[PlayerID -1] / Float(self.LoveSum)))
	End Method


	Method GetLastAwardWinner:Int()
		Local HighestAmount:Float = 0.0
		Local HighestPlayer:Int = 0
		For Local i:Int = 1 To 4
			If Self.GetRealAward(i) > HighestAmount Then HighestAmount = Self.GetRealAward(i) ;HighestPlayer = i
		Next
		LastAwardWinner = HighestPlayer
		Return HighestPlayer
	End Method


	Method GetRealAward:Int(PlayerID:Int)
		If Self.AwardSum < 100 Then Return Ceil(100 * Self.AwardWinner[PlayerID] / 100)
		Return Ceil(100 * Self.AwardWinner[PlayerID] / Self.AwardSum)
	End Method
End Type

Function GetBetty:TBetty()
	Return TBetty.GetInstance()
End Function



Type TBettyPresent
	'price for the player
	Field price:int
	'value for betty
	Field bettyValue:int
	'locale key for GetLocale(key)
	Field localeKey:string 

	Global presents:TBettyPresent[10]


	Function Initialize()
		'feet spray
		presents[0] = new TBettyPresent.Init("BETTY_PRESENT_1",      99, -250)
		'dinner
		presents[1] = new TBettyPresent.Init("BETTY_PRESENT_2",     500,   10)
		'nose operation
		presents[2] = new TBettyPresent.Init("BETTY_PRESENT_3",    1000, -500)
		'custom written script / novel
		presents[3] = new TBettyPresent.Init("BETTY_PRESENT_4",   30000,  100)
		'pearl necklace
		presents[4] = new TBettyPresent.Init("BETTY_PRESENT_5",   60000,  150)
		'coat (negative!)
		presents[5] = new TBettyPresent.Init("BETTY_PRESENT_6",   80000, -500)
		'diamond necklace
		presents[6] = new TBettyPresent.Init("BETTY_PRESENT_7",  100000, -700)
		'sports car
		presents[7] = new TBettyPresent.Init("BETTY_PRESENT_8",  250000,  350)
		'ring
		presents[8] = new TBettyPresent.Init("BETTY_PRESENT_9",  500000,  450)
		'boat/yacht
		presents[9] = new TBettyPresent.Init("BETTY_PRESENT_10",1000000,  500)
	End Function


	Function GetPresent:TBettyPresent(index:int)
		if not presents[0] then Initialize()
		if index < 0 or index >= presents.length then return Null

		return presents[index]
	End Function


	Method Init:TBettyPresent(localeKey:string, price:int, bettyValue:int)
		self.localeKey = localeKey
		self.price = price
		self.bettyValue = bettyValue
		return self
	End Method


	Method GetName:string()
		return GetLocale(localeKey)
	End Method
End Type

