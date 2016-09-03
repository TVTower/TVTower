SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"
Import "game.player.financehistory.bmx"

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


	Method ResetFinance(playerID:int)
		local playerIndex:int = playerID -1

		if finances.length > playerIndex
			finances[playerIndex] = new TPlayerFinance[0]
		endif

		SetPlayerStartDay(playerID, 0)
	End Method


	Method SetPlayerStartDay:int(playerID:int, day:int)
		if playerID > 0 and playerStartIndex.length >= playerID
			playerStartIndex[playerID] = Max(0, day)
			return True
		endif
		return False
	End Method


	'returns how many days later than "day zero" a player started
	Method GetPlayerStartDay:int(playerID:int)
		Local playerStartDay:Int = 0
		if playerID > 0 and playerStartIndex.length >= playerID
			playerStartDay = playerStartIndex[playerID -1]
		endif
		return playerStartDay
	End Method


	Method GetTotal:TPlayerFinance(playerID:int)
		local totalFinance:TPlayerFinance = New TPlayerFinance
		local finance:TPlayerFinance
		local playerStartDay:int = GetPlayerStartDay(playerID)

		For local day:int = GetWorldTime().GetStartDay() to GetWorldTime().GetDay()
			finance = Get(playerID, day + playerStartDay)
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


	Method Get:TPlayerFinance(playerID:int, day:int=-1, ignorePlayerStartDay:int = False)
		If day <= 0 Then day = GetWorldTime().GetDay()
		return _Get(playerID, day, ignorePlayerStartDay)
	End Method


	'ignoring the player's start day allows to read finances of older
	'incarnations of the player (before bankruptcies)
	Method _Get:TPlayerFinance(playerID:int, day:int, ignorePlayerStartDay:int = False)
		if playerID <= 0 then return Null

		local playerIndex:int = playerID -1

		'create entry if player misses its finance entry
		if finances.length < playerID
			finances = finances[..playerID]
			finances[playerIndex] = new TPlayerFinance[0]
		endif
		if playerStartIndex.length < playerID
			playerStartIndex = playerStartIndex[..playerID]
		endif

		'subtract start day to get a index starting at 0, add 1 as
		'we also have financials for the day before game start
		Local arrayIndex:Int = day - GetWorldTime().GetStartDay() + 1 - (not ignorePlayerStartDay)*playerStartIndex[playerIndex]

		'if the array is less than allowed: return finance from day 0
		'which is the day before "start"
		If arrayIndex < 0 Then Return _Get(playerID, GetWorldTime().GetStartDay() - 1 + (not ignorePlayerStartDay)*playerStartIndex[playerIndex])


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
				'print "take over finances: from day " + (day-1) + " to day "+day+"  target arrayIndex: "+arrayIndex+"/" + (finances[playerIndex].length-1)
				'print "take over finances: " + (day-1) +" old:" + _Get(playerID, day-1).money
				TPlayerFinance.TakeOverFinances(_Get(playerID, day-1), finances[playerIndex][arrayIndex])
			endif
		EndIf
		Return finances[playerIndex][arrayIndex]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPlayerFinanceCollection:TPlayerFinanceCollection()
	Return TPlayerFinanceCollection.GetInstance()
End Function

Function GetPlayerFinance:TPlayerFinance(playerID:int, day:int=-1, ignorePlayerStartDay:int = False)
	Return TPlayerFinanceCollection.GetInstance().Get(playerID, day, ignorePlayerStartDay)
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
	Field playerID:int                   = 0

	Global creditInterestRate:float      = 0.05 '5% a day
	Global balanceInterestRate:float     = 0.01 '1% a day
	Global drawingCreditRate:float       = 0.03 '3% a day  - rate for having a negative balance

	Method Create:TPlayerFinance(playerID:int) ', startmoney:Long=500000, startcredit:Int = 500000)
'		money = startmoney
'		revenue_before = startmoney
'		revenue_after = startmoney

'		credit = startcredit

		money = 0
		revenue_before = 0
		revenue_after = 0
		credit = 0

		Self.playerID = playerID
		Return Self
	End Method


	'take the current balance (money and credit) to the next day
	Function TakeOverFinances:Int(fromFinance:TPlayerFinance, toFinance:TPlayerFinance Var)
		If Not toFinance Then Return False
		'if the "fromFinance" does not exist yet just assume the same
		'value than of "toFinance" - so no modification would be needed
		'in all other cases:
		If fromFinance
			toFinance = Null
			'create the new financial but give the yesterdays money/credit
			toFinance = New TPlayerFinance.Create(fromFinance.playerID)
			toFinance.money = fromFinance.money
			toFinance.revenue_before = fromFinance.money
			toFinance.revenue_after = fromFinance.money
			toFinance.credit = fromFinance.credit
		EndIf
	End Function


	'returns whether the finances allow the given transaction
	Method CanAfford:Int(price:Long=0) {_exposeToLua}
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

	
	Method GetCreditInterest:Long() 'Taegliche Zinsen
		return GetCredit() * TPlayerFinance.creditInterestRate
	End Method	


	Method ChangeMoney(value:Long, reason:int, reference:TNamedGameObject=null)
		'TLogger.log("TFinancial.ChangeMoney()", "Player "+player.playerID+" changed money by "+value, LOG_DEBUG)
		money			:+ value
		revenue_after	:+ value
		
		'emit event to inform others
		EventManager.triggerEvent( TEventSimple.Create("PlayerFinance.onChangeMoney", new TData.AddNumber("value", value).AddNumber("playerID", playerID).AddNumber("reason", reason).Add("reference", reference), self) )
	End Method


	Method TransactionFailed:int(value:Long, reason:int, reference:TNamedGameObject=null)
		'emit event to inform others
		EventManager.triggerEvent( TEventSimple.Create("PlayerFinance.onTransactionFailed", new TData.AddNumber("value", value).AddNumber("playerID", playerID), self) )
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
		TLogger.Log("TFinancial.EarnBalanceInterest()", "Player "+playerID+" earned "+value+" on interest of their current balance", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.EARN_BALANCEINTEREST, +value).AddTo(playerID)

		income_balanceInterest :+ value
		AddIncome(value, TVTPlayerFinanceEntryType.EARN_BALANCEINTEREST)
		Return True
	End Method


	'refreshs stats about paid money from drawing credit interest (negative current balance)
	Method PayDrawingCreditInterest:Int(value:Long)
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
		TLogger.Log("TFinancial.PayStationFees()", "Player "+playerID+" paid "+price+" for station fees", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TVTPlayerFinanceEntryType.PAY_STATIONFEES, -price).AddTo(playerID)

		expense_stationfees :+ price
		AddExpense(price, TVTPlayerFinanceEntryType.PAY_STATIONFEES)
		Return True
	End Method


	'refreshs stats about paid money from paying interest on the current credit
	Method PayCreditInterest:Int(price:Long)
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


	'refreshs stats about paid money from paying misc things
	Method EarnGrantedBenefits:Int(price:Long)
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

