SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.logger.bmx"
Import "game.world.worldtime.bmx"
Import "game.publicimage.bmx"


	

Type TBetty
	Field inLove:Int[4]
	Field presentHistory:TList[]
	'cached values
	Field _inLoveSum:Int

	Global _instance:TBetty
	Const LOVE_MAXIMUM:int = 10000


	Function GetInstance:TBetty()
		if not _instance then _instance = new TBetty
		return _instance
	End Function


	Method Initialize:int()
		inLove = new Int[4]

		_inLoveSum = -1
	End Method


	Method ResetLove(playerID:int)
		inLove[playerID-1] = 0

		_inLoveSum = -1
	End Method


	Method GivePresent:int(playerID:int, present:TBettyPresent, time:Long = -1)
		if not present then return False
		'TODO: collect times betty got this present
		'      each time decreases "effect" ...

		local action:TBettyPresentGivingAction = new TBettyPresentGivingAction.Init(playerID, present, time)
		GetPresentHistory(playerID).AddLast(action)
		
		AdjustLove(playerID, present.bettyValue)

		TLogger.Log("Betty", "Player "+playerID+" gave Betty a present ~q"+present.GetName()+"~q.", LOG_DEBUG)
		return True
	End Method


	'returns (and creates if needed) the present history list of a given playerID
	Method GetPresentHistory:TList(playerID:int)
		if playerID <= 0 then return null
		if presentHistory.length < playerID then presentHistory = presentHistory[.. playerID]

		if not presentHistory[playerID-1] then presentHistory[playerID-1] = CreateList()

		return presentHistory[playerID-1]
	End Method

	
	Method GetLoveSummary:string()
		local res:string
		for local i:int = 1 to 4
			res :+ RSet(GetInLove(i),5)+" (Pr: "+RSet(MathHelper.NumberToString(GetInLovePercentage(i)*100,2)+"%",7)+"     Sh: "+RSet(MathHelper.NumberToString(GetInLoveShare(i)*100,2)+"%",7)+")~t"
		Next
		return res
	End Method
	

	Method AdjustLove(PlayerID:Int, amount:Int, ignorePublicImage:int = False)
		'you cannot subtract more than what is there
		if amount < 0 then amount = - Min(abs(amount), abs(Self.InLove[PlayerID-1]))
		'you cannot add more than what is left to the maximum
		amount = Min(LOVE_MAXIMUM - Self.InLove[PlayerID-1], amount)

		'according to the Mad TV manual, love can never be bigger than the
		'channel image!
		'It will not be possible to achieve 100% that easily, so we allow
		'love to be 150% of the image)
		'a once "gained love" is subtracted if meanwhile image is lower!
		if not ignorePublicImage
			local playerImage:TPublicImage = GetPublicImage(PlayerID)
			if playerImage
				local maxAmountImageLimit:int = int(ceil(0.01*playerImage.GetAverageImage()  * LOVE_MAXIMUM))
				If Self.InLove[PlayerID-1] + amount > maxAmountImageLimit
					amount = Min(amount, maxAmountImageLimit - Self.InLove[PlayerID-1])
				Endif
			endif
		endif

		'add love
		Self.InLove[PlayerID-1] = Max(0, Self.InLove[PlayerID-1] + amount)

		'if love to a player _increases_ love to others will decrease
		'but if love _decreases_ it wont increase love to others!
		If amount > 0
			local decrease:int = (0.75 * amount) / (Self.InLove.length-1)
			For Local i:Int = 1 to Self.InLove.length
				if i = PlayerID then continue
				Self.InLove[i-1] = Max(0, Self.InLove[i-1] - decrease)
			Next
		EndIf

		'reset cache
		Self._inLoveSum = -1
	End Method


	Method GetInLove:Int(PlayerID:Int)
		Return InLove[PlayerID -1]
	End Method


	Method GetInLoveSum:Int()
		If Self._inLoveSum = -1
			Self._inLoveSum = 0
			For local s:int = EachIn inLove
				Self._inLoveSum :+ s
			Next
		EndIf
		Return Self._inLoveSum
	End Method


	'returns "love progress"
	Method GetInLovePercentage:Float(PlayerID:Int)
		Return InLove[PlayerID -1] / Float(LOVE_MAXIMUM)
	End Method


	'returns a value how love is shared between players
	Method GetInLoveShare:Float(PlayerID:Int)
		If GetInLoveSum() > 0 
			Return Max(0.0, Min(1.0, Self.InLove[PlayerID -1] / Float( GetInLoveSum() )))
		Else
			Return 1.0 / Self.inLove.length
		EndIf
	End Method
End Type

Function GetBetty:TBetty()
	Return TBetty.GetInstance()
End Function




Type TBettyPresentGivingAction
	Field playerID:int = 0
	Field present:TBettyPresent
	Field time:Long


	Method Init:TBettyPresentGivingAction(playerID:int, present:TBettyPresent, time:Long = -1)
		if time = -1 then time = GetWorldTime().GetTimeGone()

		self.time = time
		self.present = present
		self.playerID = playerID

		return self
	End Method
End Type




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

