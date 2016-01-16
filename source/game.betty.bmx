SuperStrict
Import "game.world.worldtime.bmx"




Type TBetty
	Field InLove:Float[5]
	Field LoveSum:Float
	Field AwardWinner:Float[5]
	Field AwardSum:Float = 0.0
	Field CurrentAwardType:Int = 0
	Field AwardEndingAtDay:Int = 0
	Field MaxAwardTypes:Int = 3
	Field AwardDuration:Int = 3
	Field LastAwardWinner:Int = 0
	Field LastAwardType:Int = 0
	Global _instance:TBetty


	Function GetInstance:TBetty()
		if not _instance then _instance = new TBetty
		return _instance
	End Function


	Method Initialize:int()
		InLove = new Float[5]
		LoveSum = 0
		AwardWinner = new Float[5]
		AwardSum = 0.0
		CurrentAwardType = 0
		AwardEndingAtDay = 0
		MaxAwardTypes = 3
		AwardDuration = 3
		LastAwardWinner = 0
		LastAwardType = 0
	End Method
	

	Method AdjustLove(PlayerID:Int, Amount:Float)
		For Local i:Int = 1 To 4
			Self.InLove[i] :-Amount / 4
		Next
		Self.InLove[PlayerID] :+Amount * 5 / 4
		Self.LoveSum = 0
		For Local i:Int = 1 To 4
			Self.LoveSum:+Self.InLove[i]
		Next
	End Method


	Method AdjustAward(PlayerID:Int, Amount:Float)
		For Local i:Int = 1 To 4
			Self.AwardWinner[i] :-Amount / 4
		Next
		Self.AwardWinner[PlayerID] :+Amount * 5 / 4
		Self.AwardSum = 0
		For Local i:Int = 1 To 4
			Self.AwardSum:+Self.AwardWinner[i]
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


	Method GetRealLove:Int(PlayerID:Int)
		If Self.LoveSum < 100 Then Return Ceil(Self.InLove[PlayerID] / 100)
		Return Ceil(Self.InLove[PlayerID] / Self.LoveSum)
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
