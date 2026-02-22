SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.logger.bmx"
Import "Dig/base.util.event.bmx"
Import "game.broadcastmaterial.programme.bmx"
Import "game.broadcastmaterial.advertisement.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.world.worldtime.bmx"
Import "game.publicimage.bmx"
Import "Dig/base.gfx.gui.bmx"




Type TBetty
	Field inLove:Int[4]
	Field currentPresent:TBettyPresent[4]

	Field presentHistory:TList[]
	'cached values
	Field _inLoveSum:Int

	Global _eventListeners:TEventListenerBase[]
	Global _instance:TBetty
	Global modKeyPointsAbsolute:TLowerString = New TLowerString.Create("betty::pointsabsolute")
	Global modKeyRawQuality:TLowerString = New TLowerString.Create("betty::rawquality")
	Global modKeyPointsMod:TLowerString = New TLowerString.Create("betty::pointsmod")

	Const LOVE_MAXIMUM:int = 10000


	Method New()
		'=== REGISTER EVENTS ===
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'scan news shows for culture news
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Broadcasting_BeforeFinishAllNewsShowBroadcasts, onBeforeFinishAllNewsShowBroadcasts) ]
		'scan programmes for culture-flag
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Broadcasting_BeforeFinishAllProgrammeBlockBroadcasts, onBeforeFinishAllProgrammeBlockBroadcasts) ]
	End Method


	Function GetInstance:TBetty()
		if not _instance then _instance = new TBetty
		return _instance
	End Function


	Method Initialize:int()
		inLove = new Int[4]
		presentHistory = null
		_inLoveSum = -1
	End Method


	Method ResetLove(playerID:int)
		if playerID < 1 or playerID > inLove.length Then Return
		inLove[playerID-1] = 0

		_inLoveSum = -1
	End Method

	Method BuyPresent:int(playerID:int, present:TBettyPresent)
		if not present then return False
		if currentPresent[playerID-1] then return False
		currentPresent[playerID-1] = present
		TLogger.Log("Betty", "Player "+playerID+" bought Betty a present ~q"+present.GetName()+"~q.", LOG_DEBUG)
		return True
	End Method

	Method SellPresent:int(playerID:int, present:TBettyPresent)
		if not present then return False
		if currentPresent[playerID-1] <> present then return False 
		currentPresent[playerID-1] = null
		TLogger.Log("Betty", "Player "+playerID+" sold a present ~q"+present.GetName()+"~q.", LOG_DEBUG)
		return True
	End Method

	Method GetCurrentPresent:TBettyPresent(playerId:int)
		return currentPresent[playerId-1]
	End Method

	Method GivePresent:int(playerID:int, present:TBettyPresent, time:Long = -1)
		if not present then return TBettyPresent.IGNORE
		if present <> getCurrentPresent(playerID) then return TBettyPresent.IGNORE

		Local acceptResult:int=getAcceptResult(playerID, present, time)
		If acceptResult = TBettyPresent.ACCEPT
			local action:TBettyPresentGivingAction = new TBettyPresentGivingAction.Init(playerID, present, time)

			Local count:Int=getRelevantPresentCount(playerID, present)
			Local adjustValue:Int=present.bettyValue
			adjustValue = adjustValue * present.factor^count

			AdjustLove(playerID, adjustValue)
			GetPresentHistory(playerID).AddLast(action)
			currentPresent[playerID-1] = null
	
			TLogger.Log("Betty", "Player "+playerID+" gave Betty a present ~q"+present.GetName()+"~q.", LOG_DEBUG)
		End If
		return acceptResult

		Function getAcceptResult:int(playerID:int, present:TBettyPresent, time:Long = -1)
			'reject yacht with the same text for now
			If present.index = TBettyPresent.PRESENT_YACHT And GetBetty().GetInLove(playerID) < LOVE_MAXIMUM Then return TBettyPresent.REJECT_ONE_PER_DAY
			If present.index <> TBettyPresent.PRESENT_DINNER And present.index <> TBettyPresent.PRESENT_BOOK Then Return TBettyPresent.ACCEPT

			'current special handling for dinner and script
			If time= -1 Then time = GetWorldTime().GetTimeGone()
			Local today:int = GetWorldTime().GetDaysRun(time)
			For Local list:TList = EachIn GetBetty().presentHistory
				For Local p:TBettyPresentGivingAction = EachIn list
					If present.isSame(p.present) And today = GetWorldTime().GetDaysRun(p.time)
						'if dinner was given today - reject
						If present.index = TBettyPresent.PRESENT_DINNER then return TBettyPresent.REJECT_ONE_PER_DAY
						'if book was given by the same player - reject
						If present.index = TBettyPresent.PRESENT_BOOK And p.playerId = playerID return TBettyPresent.REJECT_ONE_PER_DAY
					End If
				Next
			Next
			return TBettyPresent.ACCEPT
		End Function

		'for presents (in particular dinner) with increasing value count
		'only the players history counts and negative presents reset the counter
		Function getRelevantPresentCount:int(playerID:int, present:TBettyPresent)
			If present.bettyValue < 0 OR present.factor < 1 then Return GetBetty().GetPresentGivenCount(present)
			Local count:Int = 0
			Local hist:TList = GetBetty().getPresentHistory(playerID)
			For Local p:TBettyPresentGivingAction = EachIn hist.reversed()
				If p.present.bettyValue < 0 Then return count
				If present.isSame(p.present) Then count:+ 1
			Next
			return count
		End Function
	End Method


	Method CanGiveMasterKey:Int(playerID:Int)
		Local threshold:Float = 0.15
		Local dinnerCount:Int = 0
		Local bookCount:Int = 0
		Local playerPresents:TList = GetPresentHistory(playerID)
		For Local p:TBettyPresentGivingAction = EachIn playerPresents
			If p.present.index = TBettyPresent.PRESENT_DINNER Then dinnerCount:+ 1
			If p.present.index = TBettyPresent.PRESENT_BOOK Then bookCount:+ 1
			If p.present.bettyValue < 0
				threshold:+0.01
			Else
				threshold:-0.0025
			EndIf
		Next
		Return dinnerCount > 3 And bookCount > 1 And GetInLovePercentage(playerId) >= threshold
	End Method


	'returns (and creates if needed) the present history list of a given playerID
	Method GetPresentHistory:TList(playerID:int)
		if playerID <= 0 then return null
		if presentHistory.length < playerID then presentHistory = presentHistory[.. playerID]

		if not presentHistory[playerID-1] then presentHistory[playerID-1] = CreateList()

		return presentHistory[playerID-1]
	End Method

	Method getPresentGivenCount:int(present:TBettyPresent)
		Local count:int=0
		For Local list:TList = EachIn presentHistory
			For Local p:TBettyPresentGivingAction = EachIn list
				If present.isSame(p.present) Then count:+ 1
			Next
		Next
		Return count
	End Method

	Method GetLoveSummary:string()
		local res:string
		for local i:int = 1 to 4
			res :+ RSet(GetInLove(i),5)+" (Pr: "+RSet(TFunctions.NumberToString(GetInLovePercentage(i)*100,2)+"%",7)+"     Sh: "+RSet(TFunctions.NumberToString(GetInLoveShare(i)*100,2)+"%",7)+")~t"
		Next
		return res
	End Method


	Method AdjustLove(PlayerID:Int, amount:Int, adjustOthersLove:int = True)
		if playerID < 1 or playerID > inLove.length Then Return

		'you cannot subtract more than what is there
		if amount < 0 then amount = - Min(abs(amount), abs(Self.InLove[PlayerID-1]))
		'you cannot add more than what is left to the maximum
		amount = Min(LOVE_MAXIMUM - Self.InLove[PlayerID-1], amount)

		rem
		'according to the Mad TV manual, love can never be bigger than the
		'channel image!
		'It will not be possible to achieve 100% that easily, so we allow
		'love to be 150% of the image)
		'a once "gained love" is subtracted if meanwhile image is lower!

		'we ignore this and allow betty love to be independent of image
		'missions can ensure that a certain channel image is necessary
		if not ignorePublicImage
			local playerImage:TPublicImage = GetPublicImage(PlayerID)
			if playerImage
				local maxAmountImageLimit:int = int(ceil(1.5 * 0.01 * playerImage.GetAverageImage() * LOVE_MAXIMUM))
				maxAmountImageLimit = Min(maxAmountImageLimit, LOVE_MAXIMUM)
				If Self.InLove[PlayerID-1] + amount > maxAmountImageLimit
					amount = Min(amount, maxAmountImageLimit - Self.InLove[PlayerID-1])
				Endif
			endif
		endif
		endrem

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
		TriggerBaseEvent(GameEventKeys.Betty_OnAdjustLove, new TData().addInt("player",PlayerID), Self)
	End Method


	Method GetInLove:Int(PlayerID:Int)
		if playerID < 1 or playerID > inLove.length Then Return 0

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
		if playerID < 1 or playerID > inLove.length Then Return 0

		Return InLove[PlayerID -1] / Float(LOVE_MAXIMUM)
	End Method


	'returns a value how love is shared between players
	Method GetInLoveShare:Float(PlayerID:Int)
		If GetInLoveSum() > 0
			if playerID < 1 or playerID > inLove.length Then Return 0
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
			GetInstance().AdjustLove(newsShow.owner, score, False)
		Next
	End Function


	'betty reacts to broadcasted programmes
	Function onBeforeFinishAllProgrammeBlockBroadcasts:int(triggerEvent:TEventBase)
		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))
		local hour:Int =triggerEvent.GetData().GetInt("hour", -1)

		For local broadcastMaterial:TBroadcastMaterial = Eachin broadcasts
			'only material which ends now ? So a 5block culture would get
			'ignored if ending _after_ award time
			'if broadcastMaterial.currentBlockBroadcasting <> broadcastMaterial.GetBlocks()

			local score:int = CalculateProgrammeScore(broadcastMaterial, hour)
			if score = 0 then continue

			'do not adjust love to other players
			GetInstance().AdjustLove(broadcastMaterial.owner, score, False)
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

			local newsPoints:Float = 15 * news.GetQuality() * TNewsShow.GetNewsSlotWeight(i)
			local newsPointsMod:Float = 1.0

			'jury likes good news - and dislikes the really bad ones
			if news.GetNewsEvent().GetQualityRaw() >= 0.2
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


	Function CalculateProgrammeScore:int(broadcastMaterial:TBroadcastMaterial, hour:Int = -1)
		If Not broadcastMaterial Or broadcastMaterial.owner < 0 Then Return 0
		'not of interest for Betty?
		If broadcastMaterial.SourceHasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORED_BY_BETTY) Then Return 0

		'calculate score:
		'a perfect Betty programme would give 100 points
		'- topicality<1.0 and rawQuality<1.0 reduce points -> GetQuality()
		'- "CallIn/Trash/Infomercials/Erotic" is someting Betty absolutely dislikes
		Local points:Float = 0
		Local pointsMod:Float = 1.0
		If TAdvertisement(broadcastMaterial)
			points = -5
		Else
			Local programme:TProgramme = TProgramme(broadcastMaterial)
			Local tgWomen:Int = programme.data.hasTargetGroup(TVTTargetGroup.WOMEN)
			Local blocks:Int = programme.GetBlocks()
			pointsmod = programme.data.GetModifier(modKeyPointsMod, 1.0)

			'absolute points 100=1%
			points = programme.data.GetModifier(modKeyPointsAbsolute, 0)
			If Not points
				'rawQuality corresponds to programme's raw quality (excluding topicality) -> 0.0 to 1.0
				points = programme.data.GetModifier(modKeyRawQuality, 0)
				'points calculation analogous to programmme.GetQuality()
				If points Then points = 100 * (points * (0.10 + 0.90 * programme.data.GetTopicality()^2))
			EndIf
			If points
				'modifiers determined betty points
			ElseIf (programme.data.GetGenre() = TVTProgrammeGenre.Erotic And Not tgWomen)
				points = -20 * blocks
			ElseIf programme.data.HasSubGenre(TVTProgrammeGenre.Erotic) And Not tgWomen
				points = -10 * blocks
			ElseIf programme.data.HasFlag(TVTProgrammeDataFlag.PAID)
				points = -5 * blocks
			ElseIf programme.data.HasFlag(TVTProgrammeDataFlag.TRASH) 
				points = -3 * blocks
			ElseIf programme.data.HasFlag(TVTProgrammeDataFlag.CULTURE)
				points = 100 * programme.GetQuality()
			EndIf

			If programme.data.HasFlag(TVTProgrammeDataFlag.LIVE) then pointsMod :+ 0.1

			If blocks > 1
				'divide by block count so each block adds some points
				points :/ blocks
				'but longer programmes should get higher total points than a one-block programme
				points :* (1.1^(blocks-1))
			EndIf
		EndIf

		If hour > 0 And hour < 7
			pointsMod:- 0.25
		ElseIf hour > 18
			pointsMod:+ 0.25
		EndIf

		'calculate final score
		return int(round(points * pointsMod))
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
	'index for localization and sprite
	Field index:int
	'price for the player
	Field price:int
	'value for betty
	Field bettyValue:int
	'factor for value adjustment of repeated presents
	Field factor:float

	'index constants for referencing particular presents
	Const PRESENT_DINNER:int = 2
	Const PRESENT_BOOK:int   = 4
	Const PRESENT_YACHT:int  = 10

	'constants indicating the result of the present action
	Const ACCEPT:int=0
	Const IGNORE:int=1
	Const REJECT_ONE_PER_DAY:int=2

	Global presents:TBettyPresent[10]


	Function Initialize()
		'feet spray
		presents[0] = new TBettyPresent.Init(1,                  99, -250, 1.5)
		'dinner
		presents[1] = new TBettyPresent.Init(PRESENT_DINNER,    500,   10, 1.1)
		'nose operation
		presents[2] = new TBettyPresent.Init(3,                1000, -500, 1.5)
		'custom written script / novel
		presents[3] = new TBettyPresent.Init(PRESENT_BOOK,    30000,  100, 0.95)
		'pearl necklace
		presents[4] = new TBettyPresent.Init(5,               60000,  150, 0.80)
		'coat (negative!)
		presents[5] = new TBettyPresent.Init(6,               80000, -500, 1.5)
		'diamond necklace
		presents[6] = new TBettyPresent.Init(7,              100000, -700, 1.5)
		'sports car
		presents[7] = new TBettyPresent.Init(8,              250000,  350, 0.4)
		'ring
		presents[8] = new TBettyPresent.Init(9,              500000,  450, 0.6)
		'boat/yacht
		presents[9] = new TBettyPresent.Init(PRESENT_YACHT, 1000000,    0, 1)
	End Function


	Function GetPresent:TBettyPresent(index:int)
		if not presents[0] then Initialize()
		if index < 0 or index >= presents.length then return Null

		return presents[index]
	End Function


	Method Init:TBettyPresent(index:int, price:int, bettyValue:int, factor:float)
		self.index = index
		self.price = price
		self.bettyValue = bettyValue
		self.factor = factor
		return self
	End Method

	Method IsSame:Int(other:TBettyPresent)
		If Not Other Then Return False
		return self.index = other.index
	End Method

	Method GetName:string()
		return GetLocale("BETTY_PRESENT_"+index)
	End Method

	Method GetSpriteName:string()
		return "gfx_supermarket_present"+index
	End Method
End Type




Type TGUIBettyPresent extends TGuiObject
	Field present:TBettyPresent
	Field sprite:TSprite
	Field beforeOnClickCallback:Int(triggerEvent:TEventBase)

	Method GetClassName:String()
		return "TGUIBettyPresent"
	End Method

	Method Create:TGUIBettyPresent(x:Int, y:Int, present:TBettyPresent)
		Super.CreateBase(New SVec2I(x,y), New SVec2I(121, 91), "")
		
		SetPresent(present)

		'make dragable
		SetOption(GUI_OBJECT_DRAGABLE, True)

		GUIManager.add(Self)

		Return Self
	End Method
	
	
	Method SetPresent(present:TBettyPresent)
		self.present = present
		self.sprite = GetSpriteFromRegistry(present.getSpriteName())
	End Method


	Method UpdateLayout()
	End Method

	'Copied from TGUIGameListItem
	Method DrawContent()
		sprite.draw(int(Self.GetScreenRect().GetX()), int(Self.GetScreenRect().GetY()))
		'hovered
		If isHovered() and not isDragged()
			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.20*oldAlpha
			SetBlend LightBlend
			sprite.draw(int(Self.GetScreenRect().GetX()), int(Self.GetScreenRect().GetY()))
			SetBlend AlphaBlend
			SetAlpha oldAlpha
		EndIf
	End Method

	'Copied and adapted from TGUIListItem
	Method OnClick:Int(triggerEvent:TEventBase) override
		'if desired, run something before this click is handled
		if beforeOnClickCallback 
			'if the callback returns true the event is handled there
			'and we could return from there.
			'ALTERNATIVELY: the callback could remove "button" from the
			'               event data and so it wont continue either
			'               or it could add some other kind of information
			If beforeOnClickCallback(triggerEvent)
				'we handled the click
				triggerEvent.SetAccepted(True)
				Return True
			EndIf
		EndIf

		Super.OnClick(triggerEvent)

		Local data:TData = triggerEvent.GetData()
		If Not data Then Return False

		'only react on clicks with left mouse button
		If data.getInt("button") <> 1 Then Return False

		'we handled the click
		triggerEvent.SetAccepted(True)

		If isDragged()
			Drop(MouseManager.GetClickPosition(1))
		Else
			Drag(MouseManager.GetClickPosition(1))
		EndIf
		'onclick is already emit
		'TriggerBaseEvent(GUIEventKeys.GUIObject_OnClick, Null, Self, triggerEvent.GetReceiver())
		
		Return True
	End Method
End Type


'TODO support database effects, playerID has to be passed in params (owner of context object?)
'modifier.run is currently invoked directly by awards; not using the update mechanism
Type TGameModifier_BettyLove extends TGameModifierBase
	Function CreateNewInstance:TGameModifier_BettyLove()
		Return new TGameModifier_BettyLove
	End Function


	Method Init:TGameModifier_BettyLove(data:TData, extra:TData=null)
		if not super.Init(data, extra) then return null
		
		if data then self.data = data.copy()
		
		return self
	End Method


	Method ToString:string()
		return "TGameModifier_BettyLove ("+GetName()+")"
	End Method


	Method UndoFunc:int(params:TData)
		local playerID:int = GetData().GetInt("playerID", 0)
		if not playerID then return False
		
		local valueChange:Int = GetData().GetInt("value.change", 0)
		if valueChange = 0 then return False

		TBetty.GetInstance().AdjustLove(playerID, valueChange, False)

		return True
	End Method
	

	'override
	Method RunFunc:int(params:TData)
		local playerID:int
		if params
			playerID = params.GetInt("playerID", GetData().GetInt("playerID", 0))
		else
			playerID = GetData().GetInt("playerID", 0)
		endif
		if not playerID then return False

		local value:Int
		If GetData().Has("value")
			value = GetData().GetDouble("value", 0.0)
		Else If GetData().Has("valueMin") And GetData().Has("valueMax")
			Local min:Int = GetData().GetDouble("valueMin", 0.0)
			Local max:Int = GetData().GetDouble("valueMax", 0.0)
			value = RandRange(min, max)
		EndIf
		if value = 0 then return False

		local valueBackup:Int = TBetty.GetInstance().GetInLove(playerID)

		TBetty.GetInstance().AdjustLove(playerID, value, False)

		local valueNew:Int = TBetty.GetInstance().GetInLove(playerID)

		GetData().AddInt("value.change", (valueNew - valueBackup))
		GetData().AddNumber("playerID", playerID)

		return True
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("ModifyBettyLove", TGameModifier_BettyLove.CreateNewInstance)
