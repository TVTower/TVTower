SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.logger.bmx"
Import "Dig/base.util.event.bmx"
Import "game.broadcastmaterial.programme.bmx"
Import "game.broadcastmaterial.advertisement.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.world.worldtime.bmx"
Import "game.publicimage.bmx"




Type TBetty
	Field inLove:Int[4]
	Field presentHistory:TList[]
	'cached values
	Field _inLoveSum:Int

	Global _eventListeners:TEventListenerBase[]
	Global _instance:TBetty
	Const LOVE_MAXIMUM:int = 10000


	Method New()
		'=== REGISTER EVENTS ===
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'scan news shows for culture news
		_eventListeners :+ [ EventManager.registerListenerFunction( "broadcasting.BeforeFinishAllNewsShowBroadcasts", onBeforeFinishAllNewsShowBroadcasts) ]
		'scan programmes for culture-flag
		_eventListeners :+ [ EventManager.registerListenerFunction( "broadcasting.BeforeFinishAllProgrammeBlockBroadcasts", onBeforeFinishAllProgrammeBlockBroadcasts) ]
	End Method


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


	Method AdjustLove(PlayerID:Int, amount:Int, ignorePublicImage:int = False, adjustOthersLove:int = True)
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

		'presents modify the love to others while broadcasts do not
		if adjustOthersLove
			'if love to a player _increases_ love to others will decrease
			'but if love _decreases_ it wont increase love to others!
			If amount > 0
				local decrease:int = (0.75 * amount) / (Self.InLove.length-1)
				For Local i:Int = 1 to Self.InLove.length
					if i = PlayerID then continue
					Self.InLove[i-1] = Max(0, Self.InLove[i-1] - decrease)
				Next
			EndIf
		endif

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


	Function onBeforeFinishAllNewsShowBroadcasts:int(triggerEvent:TEventBase)
		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))
		For local newsShow:TNewsShow = Eachin broadcasts
			local score:int = CalculateNewsShowScore(newsShow)
			if score = 0 then continue

			'do not adjust love to other players
			GetInstance().AdjustLove(newsShow.owner, score, False, False)
		Next
	End Function


	'betty reacts to broadcasted programmes
	Function onBeforeFinishAllProgrammeBlockBroadcasts:int(triggerEvent:TEventBase)
		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))

		For local broadcastMaterial:TBroadcastMaterial = Eachin broadcasts
			'only material which ends now ? So a 5block culture would get
			'ignored if ending _after_ award time
			'if broadcastMaterial.currentBlockBroadcasting <> broadcastMaterial.GetBlocks()

			local score:int = CalculateProgrammeScore(broadcastMaterial)
			if score = 0 then continue

			'do not adjust love to other players
			GetInstance().AdjustLove(broadcastMaterial.owner, score, False, False)
		Next
	End Function


	Function CalculateNewsShowScore:int(newsShow:TNewsShow)
		if not newsShow or newsShow.owner < 0 then return 0


		'calculate score:
		'a perfect culture news would give 25 points
		'taste points)
		'- topicality<1.0 and rawQuality<1.0 reduce points -> GetQuality()
		'- no need to handle multiple slots - each culture news brings
		'  score, no average building needed

		local allPoints:Float = 0.0
		For local i:int = 0 until newsShow.news.length
			local news:TNews = TNews(newsShow.news[i])
			if not news or news.GetGenre() <> TVTNewsGenre.CULTURE then continue
			'not of interest for Betty?
			if news.SourceHasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORED_BY_BETTY) then continue

			local newsPoints:Float = 25 * news.GetQuality() * TNewsShow.GetNewsSlotWeight(i)
			local newsPointsMod:Float = 1.0

			'jury likes good news - and dislikes the really bad ones
			if news.newsEvent.GetQualityRaw() >= 0.2
				newsPointsMod :+ 0.2
			else
				newsPointsMod :- 0.2
			endif

			allPoints :+ Max(0, newsPoints * newsPointsMod)
		Next

		'calculate final score
		'news have only a small influence
		return int(ceil(allPoints))
	End Function


	Function CalculateProgrammeScore:int(broadcastMaterial:TBroadcastMaterial)
		if not broadcastMaterial or broadcastMaterial.owner < 0 then return 0
		'not of interest for Betty?
		if broadcastMaterial.SourceHasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORED_BY_BETTY) then return 0

		'calculate score:
		'a perfect Betty programme would give 100 points
		'- topicality<1.0 and rawQuality<1.0 reduce points -> GetQuality()
		'- "CallIn/Trash/Infomercials" is someting Betty absolutely dislikes

		if TAdvertisement(broadcastMaterial) then return -5
		local programme:TProgramme = TProgramme(broadcastMaterial)
		if programme.data.HasFlag(TVTProgrammeDataFlag.PAID) then return -5
		if programme.data.HasFlag(TVTProgrammeDataFlag.TRASH) then return -3

		'in all other cases: only interested in culture-programmes
		if not programme.data.HasFlag(TVTProgrammeDataFlag.CULTURE) then return 0

		local points:Float = 100 * programme.GetQuality()
		local pointsMod:Float = 1.0
		if programme.data.HasFlag(TVTProgrammeDataFlag.LIVE) then pointsMod :+ 0.1

		'divide by block count so each block adds some points
		points :/ programme.GetBlocks()

		'calculate final score
		return int(ceil(Max(0, points * pointsMod)))
	End Function
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

