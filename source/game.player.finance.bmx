SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"
Import "game.player.financehistory.bmx"
Import "game.player.difficulty.bmx"
Import "game.modifier.base.bmx"
Import "game.gameeventkeys.bmx"


Type TPlayerFinanceCollection
	Field finances:TPlayerFinance[][]
	'adjust if a player starts at a later day
	Field playerStartIndex:int[] =[0,0,0,0]

	Global _instance:TPlayerFinanceCollection


	Method New()
		if finances = null then finances = finances[..0]
	End Method


	Function GetInstance:TPlayerFinanceCollection()
		if not _instance then _instance = new TPlayerFinanceCollection
		return _instance
	End Function


	Method Initialize:int()
		finances = finances[..0]
		playerStartIndex = [0,0,0,0]
	End Method


	Method ResetFinances(playerID:int)
		local playerIndex:int = playerID -1

		if finances.length > playerIndex
			finances[playerIndex] = new TPlayerFinance[0]
		endif

		if not GameConfig.KeepBankruptPlayerFinances
			SetPlayerStartIndex(playerID, 0)
			'reset old finances
			finances[playerIndex] = new TPlayerFinance[0]
		endif
	End Method


	'Get player start day
	Method GetPlayerStartDay:int(playerID:int)
		return GetWorldTime().GetStartDay() + (GetPlayerStartIndex(playerID)-1)
	End Method


	'set player start index by a given day
	Method SetPlayerStartDay:int(playerID:int, day:int)
		if day = -1 then day = GetWorldTime().GetDay()
		return SetPlayerStartIndex(playerID, day - GetWorldTime().GetStartDay() + 1)
	End Method


	'set player start index by a given index
	Method SetPlayerStartIndex:int(playerID:int, index:int)
		if playerID > 0 and playerStartIndex.length >= playerID
			'you cannot set index to "0"
			'(this is limited to "day before start")
			playerStartIndex[playerID -1] = Max(1, index)
			return True
		endif
		return False
	End Method


	'returns offset to a "day zero" started player
	Method GetPlayerStartIndex:int(playerID:int)
		Local index:Int = 1
		if playerID > 0 and playerStartIndex.length >= playerID
			'you cannot use index to "0"
			'(this is limited to "day before start")
			index = MaX(1, playerStartIndex[playerID -1])
		endif
		return index
	End Method


	Method GetTotal:TPlayerFinance(playerID:int, tillDay:int = -1)
		if tillDay = -1 then tillDay = GetWorldTime().GetDay()
		local totalFinance:TPlayerFinance = New TPlayerFinance
		local finance:TPlayerFinance
		'save some processing  by only adding the days a player incarnation
		'played yet
		local playerStartDay:int = GetWorldTime().GetStartDay() + (GetPlayerStartIndex(playerID)-1)
		
		For local day:int = playerStartDay to tillDay
			finance = Get(playerID, day)
			if not finance then continue

			totalFinance.expense_programmeLicences :+ finance.expense_programmeLicences
			totalFinance.expense_stations :+ finance.expense_stations
			totalFinance.expense_scripts :+ finance.expense_scripts
			totalFinance.expense_productionstuff :+ finance.expense_productionstuff
			totalFinance.expense_penalty :+ finance.expense_penalty
			totalFinance.expense_rent :+ finance.expense_rent
			totalFinance.expense_news :+ finance.expense_news
			totalFinance.expense_newsagencies :+ finance.expense_newsagencies
			totalFinance.expense_stationfees :+ finance.expense_stationfees
			totalFinance.expense_misc :+ finance.expense_misc
			totalFinance.expense_creditRepayed :+ finance.expense_creditRepayed
			totalFinance.expense_creditInterest :+ finance.expense_creditInterest
			totalFinance.expense_drawingCreditInterest :+ finance.expense_drawingCreditInterest
			totalFinance.expense_total :+ finance.expense_total

			totalFinance.income_programmeLicences :+ finance.income_programmeLicences
			totalFinance.income_ads :+ finance.income_ads
			totalFinance.income_callerRevenue :+ finance.income_callerRevenue
			totalFinance.income_scripts :+ finance.income_scripts
			totalFinance.income_sponsorshipRevenue :+ finance.income_sponsorshipRevenue
			totalFinance.income_misc :+ finance.income_misc
			totalFinance.income_granted_benefits :+ finance.income_granted_benefits
			totalFinance.income_stations :+ finance.income_stations
			totalFinance.income_creditTaken :+ finance.income_creditTaken
			totalFinance.income_balanceInterest :+ finance.income_balanceInterest
			totalFinance.income_total :+ finance.income_total
		Next
		return totalFinance
	End Method


	Method Get:TPlayerFinance(playerID:int, day:int=-1)
		If day <= 0 Then day = GetWorldTime().GetDay()
		return _Get(playerID, GetArrayIndex(playerID, day, False), day)
	End Method


	Method GetIgnoringStartDay:TPlayerFinance(playerID:int, day:int=-1)
		If day <= 0 Then day = GetWorldTime().GetDay()
		return _Get(playerID, GetArrayIndex(playerID, day, True), day)
	End Method



	Method GetArrayIndex:int(playerID:int, day:int, ignorePlayerStartDay:int = False)
		'create entry if missing entry for player
		if playerStartIndex.length < playerID
			playerStartIndex = playerStartIndex[..playerID]
		endif
		
		local index:int = day - GetWorldTime().GetStartDay() + 1
		local minIndex:int = (not ignorePlayerStartDay) * GetPlayerStartIndex(playerID) 

		'return financials for the day before game start
		if index < minIndex then return 0
		'arr[1] = day0, so add 1
		return index
	End Method


	'day is only used for debug logs
	Method _Get:TPlayerFinance(playerID:int, arrayIndex:int, day:int=-1)
		if playerID <= 0 then return Null

		arrayIndex = Max(0, arrayIndex)

		local playerIndex:int = playerID -1

		'create entry if player misses its finance entry
		if finances.length < playerID
			finances = finances[..playerID]
			finances[playerIndex] = new TPlayerFinance[0]
		endif
		if playerStartIndex.length < playerID
			playerStartIndex = playerStartIndex[..playerID]
		endif

		'if requesting "before start"-finance (index=0)
		If (arrayIndex = 0 And Not finances[playerIndex][0]) Or arrayIndex >= finances[playerIndex].length
			TLogger.Log("TPlayer.GetFinance()", "Adding a new finance to player "+playerID+" for day "+day+ " at index "+arrayIndex, LOG_DEBUG)
			If arrayIndex >= finances[playerIndex].length
				'resize array
				finances[playerIndex] = finances[playerIndex][..arrayIndex+1]
			EndIf

			'print "create finance for player "+playerID+" at arrayIndex="+arrayIndex
			finances[playerIndex][arrayIndex] = New TPlayerFinance.Create(playerID)
			'reuse the money from the day before
			'if arrayIndex 0 - we do not need to take over
			'calling GetFinance(day-1) instead of accessing the array
			'assures that the object is created if needed (recursion)
			If arrayIndex > 0
				if day = -1 then day = GetWorldTime().GetDay()
				local takeOverFromDay:int = day - 1
			
				'print "take over finances: from day " + takeOverFromDay + " to day "+day+"  target arrayIndex: "+arrayIndex+"/" + (finances[playerIndex].length-1)
				finances[playerIndex][arrayIndex].TakeOverFrom( _Get(playerID, arrayIndex-1, takeOverFromDay))
				finances[playerIndex][arrayIndex].day = day
			endif
		EndIf
		Return finances[playerIndex][arrayIndex]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPlayerFinanceCollection:TPlayerFinanceCollection()
	Return TPlayerFinanceCollection.GetInstance()
End Function

Function GetPlayerFinance:TPlayerFinance(playerID:int, day:int=-1)
	Return TPlayerFinanceCollection.GetInstance().Get(playerID, day)
End Function



'holds data of WHAT has been bought, which amount of money was used and so on ...
'contains methods for refreshing stats when paying or selling something
Type TPlayerFinance {_exposeToLua="selected"}
	Field expense_programmeLicences:Long = 0
	Field expense_stations:Long          = 0
	Field expense_scripts:Long           = 0
	Field expense_productionstuff:Long   = 0
	Field expense_penalty:Long           = 0
	Field expense_rent:Long              = 0
	Field expense_news:Long              = 0
	Field expense_newsagencies:Long      = 0
	Field expense_stationfees:Long       = 0
	Field expense_misc:Long              = 0
	Field expense_creditRepayed:Long     = 0	'paid back credit today
	Field expense_creditInterest:Long    = 0	'interest to pay for the current credit
	Field expense_drawingCreditInterest:Long = 0	'interest to pay for having a negative balance
	Field expense_total:Long             = 0

	Field income_programmeLicences:Long  = 0
	Field income_ads:Long                = 0
	Field income_callerRevenue:Long      = 0
	Field income_scripts:Long            = 0
	Field income_sponsorshipRevenue:Long = 0
	Field income_misc:Long               = 0
	Field income_granted_benefits:Long   = 0
	Field income_stations:Long           = 0
	Field income_creditTaken:Long        = 0	'freshly taken credit today
	Field income_balanceInterest:Long    = 0	'interest for money "on the bank"
	Field income_total:Long	             = 0
	Field revenue_before:Long            = 0
	Field revenue_after:Long             = 0
	Field money:Long                     = 0
	Field credit:Int                     = 0
	Field creditMaxToday:Long            = 0
	Field creditMaxYesterday:Long        = 0
	Field creditDaysMax:Long             = 0
	Field playerID:int                   = 0
	Field day:int                        = 0

	Method Create:TPlayerFinance(playerID:int)
		Reset()

		Self.playerID = playerID
		Return Self
	End Method


	Method Reset()
		expense_programmeLicences = 0
		expense_stations = 0
		expense_scripts = 0
		expense_productionstuff = 0
		expense_penalty = 0
		expense_rent = 0
		expense_news = 0
		expense_newsagencies = 0
		expense_stationfees = 0
		expense_misc = 0
		expense_creditRepayed = 0
		expense_creditInterest = 0
		expense_drawingCreditInterest = 0
		expense_total = 0

		income_programmeLicences = 0
		income_ads = 0
		income_callerRevenue = 0
		income_scripts = 0
		income_sponsorshipRevenue = 0
		income_misc = 0
		income_granted_benefits = 0
		income_stations = 0
		income_creditTaken = 0
		income_balanceInterest = 0
		income_total = 0
		revenue_before = 0
		revenue_after = 0
		money = 0
		credit = 0
		creditMaxToday = 0
		creditMaxYesterday = 0
	End Method


	'take the current balance (money and credit) to the next day
	Method TakeOverFrom:Int(fromFinance:TPlayerFinance)
		If Not fromFinance Then Return False
		If fromFinance
			Reset()
			money = fromFinance.money
			revenue_before = fromFinance.money
			revenue_after = fromFinance.money
			credit = fromFinance.credit

			'previous credit is the current maximum of today
			creditMaxToday = fromFinance.credit
			creditMaxYesterday = fromFinance.creditMaxToday
		EndIf
	End Method


	'returns whether the finances allow the given transaction
	Method CanAfford:Int(price:Int) {_exposeToLua}
	'long is currently not supported in BlitzMax-Reflection
	'so we do not expose the long version but the "int" one
		Return (money > 0 And money >= price)
	End Method


	'returns whether the finances allow the given transaction
	Method CanAfford:Int(price:Long)
		Return (money > 0 And money >= price)
	End Method


	Method GetCurrentProfit:Double() {_exposeToLua}
	'long is currently not supported in BlitzMax-Reflection
	'Method GetCurrentProfit:Long() {_exposeToLua}
		return revenue_after - revenue_before
	End Method


	Method GetMoney:Long() {_exposeToLua}
		return money
	End Method


	Method GetCredit:Long() {_exposeToLua}
		return credit
	End Method


	Method GetCreditMaxToday:Long() {_exposeToLua}
		return creditMaxToday
	End Method


	Method GetCreditMaxYesterday:Long() {_exposeToLua}
		return creditMaxYesterday
	End Method


	'daily interest for taken credit
	'you pay the interest for the biggest credit value you had on this
	'day
	Method GetCreditInterest:Long()
		return GetCreditMaxYesterday() * GetPlayerDifficulty(playerID).interestRateCredit
	End Method


	Method ChangeMoney(value:Long, reason:int, reference:TNamedGameObject=null)
		'TLogger.log("TFinancial.ChangeMoney()", "Player "+player.playerID+" changed money by "+value, LOG_DEBUG)
		money			:+ value
		revenue_after	:+ value
		
		'emit event to inform others
		TriggerBaseEvent(GameEventKeys.PlayerFinance_OnChangeMoney, new TData.AddNumber("value", value).AddNumber("playerID", playerID).AddNumber("reason", reason).Add("reference", reference), self) 
	End Method


	Method TransactionFailed:int(value:Long, reason:int, reference:TNamedGameObject=null)
		'emit event to inform others
		TriggerBaseEvent(GameEventKeys.PlayerFinance_OnTransactionFailed, new TData.AddNumber("value", value).AddNumber("playerID", playerID), self)
		return False
	End Method


	Method AddIncome(value:Long, reason:int, reference:TNamedGameObject=null)
		income_total :+ value
		ChangeMoney(value, reason, reference)
	End Method


	Method AddExpense(value:Long, reason:int, reference:TNamedGameObject=null)
		expense_total :+ value
		ChangeMoney(-value, reason, reference)
	End Method


	Method Earn:int(entryType:int, value:long, extra:object=null)
		Select entryType
			case TVTPlayerFinanceEntryType.EARN_SPONSORSHIPREVENUE
				return EarnSponsorshipRevenue(value, extra)
			case TVTPlayerFinanceEntryType.EARN_CALLERREVENUE
				return EarnCallerRevenue(value, extra)
			case TVTPlayerFinanceEntryType.EARN_INFOMERCIALREVENUE
				return EarnInfomercialRevenue(value, extra)
			case TVTPlayerFinanceEntryType.EARN_ADPROFIT
				return EarnAdProfit(value, extra)
			case TVTPlayerFinanceEntryType.EARN_BALANCEINTEREST
				return EarnBalanceInterest(value)
			case TVTPlayerFinanceEntryType.GRANTED_BENEFITS
				return EarnGrantedBenefits(value)
			case TVTPlayerFinanceEntryType.SELL_MISC
				return SellMisc(value)
			default
				TLogger.Log("TFinancial.Earn()", "Unknown entry type used: "+entryType, LOG_DEBUG)
				return False
		End Select
	End Method


	Method Pay:Int(entryType:int, value:long, extra:object=null, forcedPayment:int = False)
		Select entryType
			case TVTPlayerFinanceEntryType.PAY_DRAWINGCREDITINTEREST
				return PayDrawingCreditInterest(value)
			case TVTPlayerFinanceEntryType.PAY_CREDITINTEREST
				return PayCreditInterest(value)
			case TVTPlayerFinanceEntryType.PAY_PROGRAMMELICENCE
				return PayProgrammeLicence(value, extra)
			case TVTPlayerFinanceEntryType.PAY_STATION
				return PayStation(value)
			case TVTPlayerFinanceEntryType.PAY_BROADCASTPERMISSION
				return PayBroadcastPermission(value)
			case TVTPlayerFinanceEntryType.PAY_SCRIPT
				return PayScript(value, extra)
			case TVTPlayerFinanceEntryType.PAY_PRODUCTIONSTUFF
				return PayProductionStuff(value, forcedPayment)
			case TVTPlayerFinanceEntryType.PAY_PENALTY
				return PayPenalty(value, extra)
			case TVTPlayerFinanceEntryType.PAY_RENT
				return PayRent(value, extra)
			case TVTPlayerFinanceEntryType.PAY_NEWS
				return PayNews(value, extra)
			case TVTPlayerFinanceEntryType.PAY_NEWSAGENCIES
				return PayNewsAgencies(value)
			case TVTPlayerFinanceEntryType.PAY_STATIONFEES
				return PayStationFees(value)
			case TVTPlayerFinanceEntryType.PAY_MISC
				return PayMisc(value)
			default
				TLogger.Log("TFinancial.Pay()", "Unknown entry type used: "+entryType, LOG_DEBUG)
				return False
		End Select
	End Method


	Method RepayCredit:Int(value:Long)
		TLogger.Log("TFinancial.RepayCredit()", "Player "+playerID+" repays (a part of his) credit of "+value, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.CREDIT_REPAY, -value, null).AddTo(playerID)

		credit :- value
		expense_creditRepayed :+ value
		expense_total :+ value
		ChangeMoney(-value, TVTPlayerFinanceEntryType.CREDIT_REPAY)
	End Method


	Method TakeCredit:Int(value:Long)
		TLogger.Log("TFinancial.TakeCredit()", "Player "+playerID+" took a credit of "+value, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.CREDIT_TAKE, +value).AddTo(playerID)

		credit :+ value
		'store heighest value
		creditMaxToday = Max(creditMaxToday, credit)

		income_creditTaken :+ value
		income_total :+ value
		ChangeMoney(+value, TVTPlayerFinanceEntryType.CREDIT_TAKE)
	End Method


	'refreshs stats about misc sells
	Method SellMisc:Int(price:Long)
		TLogger.Log("TFinancial.SellMisc()", "Player "+playerID+" sold mics for "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.SELL_MISC, +price).AddTo(playerID)

		income_misc :+ price
		AddIncome(price, TVTPlayerFinanceEntryType.SELL_MISC)
		Return True
	End Method


	Method SellStation:Int(price:Long)
		TLogger.Log("TFinancial.SellStation()", "Player "+playerID+" sold a station for "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.SELL_STATION, +price).AddTo(playerID)

		income_stations :+ price
		AddIncome(price, TVTPlayerFinanceEntryType.SELL_STATION)
		Return True
	End Method
	

	Method SellScript:Int(price:Long, script:object)
		TLogger.Log("TFinancial.SellScript()", "Player "+playerID+" sold a script for "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.SELL_SCRIPT, +price, script).AddTo(playerID)

		income_scripts :+ price
		AddIncome(price, TVTPlayerFinanceEntryType.SELL_SCRIPT, TNamedGameObject(script))
		Return True
	End Method


	'refreshs stats about earned money from adspots
	Method EarnAdProfit:Int(value:Long, contract:object)
		TLogger.Log("TFinancial.EarnAdProfit()", "Player "+playerID+" earned "+value+" with ads", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.EARN_ADPROFIT, +value, contract).AddTo(playerID)

		income_ads :+ value
		AddIncome(value, TVTPlayerFinanceEntryType.EARN_ADPROFIT, TNamedGameObject(contract))
		Return True
	End Method


	'refreshs stats about earned money from adspots sent as infomercial
	Method EarnInfomercialRevenue:Int(value:Long, contract:object)
		TLogger.Log("TFinancial.EarnInfomercialRevenue()", "Player "+playerID+" earned "+value+" with ads", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.EARN_INFOMERCIALREVENUE, +value, contract).AddTo(playerID)

		income_ads :+ value
		AddIncome(value, TVTPlayerFinanceEntryType.EARN_INFOMERCIALREVENUE, TNamedGameObject(contract))
		Return True
	End Method


	'refreshs stats about earned money from sending ad powered shows or call-in
	Method EarnCallerRevenue:Int(value:Long, licence:object)
		TLogger.Log("TFinancial.EarnCallerRevenue()", "Player "+playerID+" earned "+value+" with a call-in-show", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.EARN_CALLERREVENUE, +value, licence).AddTo(playerID)

		income_callerRevenue :+ value
		AddIncome(value, TVTPlayerFinanceEntryType.EARN_CALLERREVENUE, TNamedGameObject(licence))
		Return True
	End Method


	'refreshs stats about earned money from sending ad powered shows or call-in
	Method EarnSponsorshipRevenue:Int(value:Long, licence:object)
		TLogger.Log("TFinancial.EarnSponsorshipRevenue()", "Player "+playerID+" earned "+value+" broadcasting a sponsored programme", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.EARN_SPONSORSHIPREVENUE, +value, licence).AddTo(playerID)

		income_sponsorshipRevenue :+ value
		AddIncome(value, TVTPlayerFinanceEntryType.EARN_SPONSORSHIPREVENUE, TNamedGameObject(licence))
		Return True
	End Method


	'refreshs stats about earned money from selling a movie/programme
	Method SellProgrammeLicence:Int(price:Long, licence:object)
		TLogger.Log("TFinancial.SellLicence()", "Player "+playerID+" earned "+price+" selling a programme licence", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.SELL_PROGRAMMELICENCE, +price, licence).AddTo(playerID)

		income_programmeLicences :+ price
		AddIncome(price, TVTPlayerFinanceEntryType.SELL_PROGRAMMELICENCE, TNamedGameObject(licence))
	End Method


	'refreshs stats about earned money from interest on the current balance
	Method EarnBalanceInterest:Int(value:Long)
		if value = 0 then return False
		
		TLogger.Log("TFinancial.EarnBalanceInterest()", "Player "+playerID+" earned "+value+" on interest of their current balance", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.EARN_BALANCEINTEREST, +value).AddTo(playerID)

		income_balanceInterest :+ value
		AddIncome(value, TVTPlayerFinanceEntryType.EARN_BALANCEINTEREST)
		Return True
	End Method


	'refreshs stats about paid money from drawing credit interest (negative current balance)
	Method PayDrawingCreditInterest:Int(value:Long)
		if value = 0 then return False

		TLogger.Log("TFinancial.PayDrawingCreditInterest()", "Player "+playerID+" paid "+value+" on interest of having a negative current balance", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_DRAWINGCREDITINTEREST, -value).AddTo(playerID)

		expense_drawingCreditInterest :+ value
		AddExpense(value, TVTPlayerFinanceEntryType.PAY_DRAWINGCREDITINTEREST)
		Return True
	End Method


	'pay the bid for an auction programme
	Method PayAuctionBid:Int(price:Long, licence:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayAuctionBid()", "Player "+playerID+" paid a bid of "+price, LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_AUCTIONBID, -price, licence).AddTo(playerID)

			expense_programmeLicences :+ price
			AddExpense(price, TVTPlayerFinanceEntryType.PAY_AUCTIONBID, TNamedGameObject(licence))
			Return True
		Else
			TransactionFailed(price, TVTPlayerFinanceEntryType.PAY_AUCTIONBID, TNamedGameObject(licence))
			Return False
		EndIf
	End Method


	'get the bid back one paid before another player now has bid more
	'for an auction programme
	'ATTENTION: from a financial view this IS NOT CORRECT ... it should add
	'to "income paid_programmeLicence" ...
	Method PayBackAuctionBid:Int(price:Long, licence:object)
		TLogger.Log("TFinancial.PayBackAuctionBid()", "Player "+playerID+" received back "+price+" from an auction", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAYBACK_AUCTIONBID, +price, licence).AddTo(playerID)

		expense_programmeLicences	:- price
		expense_total				:- price
		ChangeMoney(+price, TVTPlayerFinanceEntryType.PAYBACK_AUCTIONBID, TNamedGameObject(licence))
		Return True
	End Method


	'refreshs stats about paid money from buying a movie/programme
	Method PayProgrammeLicence:Int(price:Long, licence:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayProgrammeLicence()", "Player "+playerID+" paid "+price+" for a programmeLicence", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_PROGRAMMELICENCE, -price, licence).AddTo(playerID)

			expense_programmeLicences :+ price
			AddExpense(price, TVTPlayerFinanceEntryType.PAY_PROGRAMMELICENCE, TNamedGameObject(licence))
			Return True
		Else
			TransactionFailed(price, TVTPlayerFinanceEntryType.PAY_PROGRAMMELICENCE, TNamedGameObject(licence))
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying a broadcast permission fee
	Method PayBroadcastPermission:Int(price:Long)
		If canAfford(price)
			TLogger.Log("TFinancial.PayBroadcastPermission()", "Player "+playerID+" paid "+price+" for a broadcasting permission", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_BROADCASTPERMISSION, -price).AddTo(playerID)

			expense_stations :+ price
			AddExpense(price, TVTPlayerFinanceEntryType.PAY_BROADCASTPERMISSION)
			Return True
		Else
			TransactionFailed(price, TVTPlayerFinanceEntryType.PAY_BROADCASTPERMISSION)
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying a station
	Method PayStation:Int(price:Long)
		If canAfford(price)
			TLogger.Log("TFinancial.PayStation()", "Player "+playerID+" paid "+price+" for a broadcasting station", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_STATION, -price).AddTo(playerID)

			expense_stations :+ price
			AddExpense(price, TVTPlayerFinanceEntryType.PAY_STATION)
			Return True
		Else
			TransactionFailed(price, TVTPlayerFinanceEntryType.PAY_STATION)
			Return False
		EndIf
	End Method

	'refreshs stats about paid money from buying a script (own production)
	Method PayScript:Int(price:Long, script:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayScript()", "Player "+playerID+" paid "+price+" for a script", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_SCRIPT, -price, script).AddTo(playerID)

			expense_scripts :+ price
			AddExpense(price, TVTPlayerFinanceEntryType.PAY_SCRIPT, TNamedGameObject(script))
			Return True
		Else
			TransactionFailed(price, TVTPlayerFinanceEntryType.PAY_SCRIPT, TNamedGameObject(script))
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying stuff for own production
	Method PayProductionStuff:Int(price:Long, forcedPayment:int = False)
		If canAfford(price) or forcedPayment
			TLogger.Log("TFinancial.PayProductionStuff()", "Player "+playerID+" paid "+price+" for product stuff", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_PRODUCTIONSTUFF, -price).AddTo(playerID)

			expense_productionstuff :+ price
			AddExpense(price, TVTPlayerFinanceEntryType.PAY_PRODUCTIONSTUFF)
			Return True
		Else
			TransactionFailed(price, TVTPlayerFinanceEntryType.PAY_PRODUCTIONSTUFF)
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from paying a penalty fee (not sent the necessary adspots)
	Method PayPenalty:Int(value:Long, contract:object)
		TLogger.Log("TFinancial.PayPenalty()", "Player "+playerID+" paid a failed contract penalty of "+value, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_PENALTY, -value, contract).AddTo(playerID)

		expense_penalty :+ value
		AddExpense(value, TVTPlayerFinanceEntryType.PAY_PENALTY, TNamedGameObject(contract))
		Return True
	End Method


	'refreshs stats about paid money from paying the rent of rooms
	Method PayRent:Int(price:Long, room:object)
		TLogger.Log("TFinancial.PayRent()", "Player "+playerID+" paid a room rent of "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_RENT, -price, room).AddTo(playerID)

		expense_rent :+ price
		AddExpense(price, TVTPlayerFinanceEntryType.PAY_RENT, TNamedGameObject(room))
		Return True
	End Method


	'refreshs stats about paid money from paying for the sent newsblocks
	Method PayNews:Int(price:Long, news:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayNews()", "Player "+playerID+" paid "+price+" for a news", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_NEWS, -price, news).AddTo(playerID)

			expense_news :+ price
			AddExpense(price, TVTPlayerFinanceEntryType.PAY_NEWS, TNamedGameObject(news))
			Return True
		Else
			TransactionFailed(price, TVTPlayerFinanceEntryType.PAY_NEWS, TNamedGameObject(news))
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from paying the daily costs a newsagency-abonnement
	Method PayNewsAgencies:Int(price:Long)
		TLogger.Log("TFinancial.PayNewsAgencies()", "Player "+playerID+" paid "+price+" for news abonnements", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_NEWSAGENCIES, -price).AddTo(playerID)

		expense_newsagencies :+ price
		AddExpense(price, TVTPlayerFinanceEntryType.PAY_NEWSAGENCIES)
		Return True
	End Method


	'refreshs stats about paid money from paying the fees for the owned stations
	Method PayStationFees:Int(price:Long)
		if price = 0 then return False

		TLogger.Log("TFinancial.PayStationFees()", "Player "+playerID+" paid "+price+" for station fees", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_STATIONFEES, -price).AddTo(playerID)

		expense_stationfees :+ price
		AddExpense(price, TVTPlayerFinanceEntryType.PAY_STATIONFEES)
		Return True
	End Method


	'refreshs stats about paid money from paying interest on the current credit
	Method PayCreditInterest:Int(price:Long)
		if price = 0 then return False

		TLogger.Log("TFinancial.PayCreditInterest()", "Player "+playerID+" paid "+price+" on interest of their credit", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_CREDITINTEREST, -price).AddTo(playerID)

		expense_creditInterest :+ price
		AddExpense(price, TVTPlayerFinanceEntryType.PAY_CREDITINTEREST)
		Return True
	End Method


	'refreshs stats about paid money from paying misc things
	Method PayMisc:Int(price:Long)
		TLogger.Log("TFinancial.PayMisc()", "Player "+playerID+" paid "+price+" for misc", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_MISC, -price).AddTo(playerID)

		expense_misc :+ price
		AddExpense(price, TVTPlayerFinanceEntryType.PAY_MISC)
		Return True
	End Method


	'refreshs stats about money got from 3rd parties
	Method EarnGrantedBenefits:Int(price:Long)
		if price = 0 then return False

		TLogger.Log("TFinancial.EarnGrantedBenefits()", "Player "+playerID+" earned "+price+" of granted benefits", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.GRANTED_BENEFITS, price).AddTo(playerID)

		income_granted_benefits :+ price
		AddIncome(price, TVTPlayerFinanceEntryType.GRANTED_BENEFITS)
		
		Return True
	End Method


	'refreshs stats about paid money from paying misc things
	Method CheatMoney:Int(price:Long)
		TLogger.Log("TFinancial.CheatMoney()", "Player "+playerID+" cheated balance by "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.CHEAT, price).AddTo(playerID)

		if price > 0
			income_misc :+ price
			AddIncome(price, TVTPlayerFinanceEntryType.CHEAT)
		else
			'negate price!
			expense_misc :+ -price
			AddExpense(-price, TVTPlayerFinanceEntryType.CHEAT)
		endif
		
		Return True
	End Method
End Type



'modifier.run is currently invoked directly by awards; not using the update mechanism
Type TGameModifier_Money extends TGameModifierBase
	Function CreateNewInstance:TGameModifier_Money()
		return new TGameModifier_Money
	End Function


	Method Init:TGameModifier_Money(data:TData, extra:TData=null)
		if not super.Init(data, extra) then return null
		
		if data then self.data = data.copy()
		
		return self
	End Method


	Method ToString:string()
		return "TGameModifier_Money ("+GetName()+")"
	End Method


	Method UndoFunc:int(params:TData)
		local playerID:int = GetData().GetInt("playerID", 0)
		if not playerID then return False
		
		local valueChange:Long = GetData().GetInt("value.change", 0)
		if valueChange = 0 then return False

		local finance:TPlayerFinance = GetPlayerFinance(playerID)
		if not finance then return False


		'local valueBackup:Long = GetData().GetInt("value.backup")
		'local value:Long = GetPlayerFinance(playerID).GetMoney()
		'local relative:int = GetData().GetBool("relative")

		'restore
		finance.Pay(TVTPlayerFinanceEntryType.PAY_MISC, valueChange)

		'print "TGameModifier_Money: paid back "+valueChange+" => "+finance.GetMoney()
	
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

		local value:Double = GetData().GetDouble("value", 0.0)
		if value = 0.0 then return False

		local finance:TPlayerFinance = GetPlayerFinance(playerID)
		if not finance then return False


		local valueBackup:Int = finance.GetMoney()
		local relative:Int = GetData().GetBool("relative")

		'backup
		GetData().AddNumber("value.backup", valueBackup)
		GetData().AddNumber("playerID", playerID)

		'adjust
		local valueChange:Long
		if relative
			valueChange = Ceil(valueBackup * value)
		else
			valueChange = value
		endif
		GetData().AddNumber("value.change", valueChange)
		finance.Earn(TVTPlayerFinanceEntryType.SELL_MISC, valueChange)

		'print "TGameModifier_Money: earned "+valueChange+" => "+finance.GetMoney()
	
		return True
	End Method
End Type
	

GetGameModifierManager().RegisterCreateFunction("ModifyChannelMoney", TGameModifier_Money.CreateNewInstance)
