SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"
Import "game.player.financehistory.bmx"

Type TPlayerFinanceCollection
	Field finances:TPlayerFinance[][]

	Global _instance:TPlayerFinanceCollection


	Method New()
		if finances = null then finances = finances[..0]
	End Method


	Function GetInstance:TPlayerFinanceCollection()
		if not _instance then _instance = new TPlayerFinanceCollection
		return _instance
	End Function


	Method Get:TPlayerFinance(playerID:int, day:int=-1)
		if playerID <= 0 then return Null

		If day <= 0 Then day = GetWorldTime().GetDay()
		'subtract start day to get a index starting at 0 and add 1 day again
		Local arrayIndex:Int = day +1 - GetWorldTime().GetStartDay()
		local playerIndex:int = playerID -1
		'if the array is less than allowed: return finance from day 0
		'which is the day before "start"
		If arrayIndex < 0 Then Return Get(playerID, GetWorldTime().GetStartDay()-1)

		'create entry if player misses its finance entry
		if finances.length < playerID then finances = finances[..playerID]

		If (arrayIndex = 0 And Not finances[playerIndex][0]) Or arrayIndex >= finances[playerIndex].length
			'TLogger.Log("TPlayer.GetFinance()", "Adding a new finance to player "+Self.playerID+" for day "+day+ " at index "+arrayIndex, LOG_DEBUG)
			If arrayIndex >= finances[playerIndex].length
				'resize array
				finances[playerIndex] = finances[playerIndex][..arrayIndex+1]
			EndIf
			finances[playerIndex][arrayIndex] = New TPlayerFinance.Create(playerID)
			'reuse the money from the day before
			'if arrayIndex 0 - we do not need to take over
			'calling GetFinance(day-1) instead of accessing the array
			'assures that the object is created if needed (recursion)
			If arrayIndex > 0 Then TPlayerFinance.TakeOverFinances(Get(playerID, day-1), finances[playerIndex][arrayIndex])
		EndIf
		Return finances[playerIndex][arrayIndex]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPlayerFinanceCollection:TPlayerFinanceCollection()
	Return TPlayerFinanceCollection.GetInstance()
End Function




'holds data of WHAT has been bought, which amount of money was used and so on ...
'contains methods for refreshing stats when paying or selling something
Type TPlayerFinance
	Field expense_programmeLicences:Int	= 0
	Field expense_stations:Int 			= 0
	Field expense_scripts:Int 			= 0
	Field expense_productionstuff:Int	= 0
	Field expense_penalty:Int 			= 0
	Field expense_rent:Int 				= 0
	Field expense_news:Int 				= 0
	Field expense_newsagencies:Int 		= 0
	Field expense_stationfees:Int 		= 0
	Field expense_misc:Int 				= 0
	Field expense_creditRepayed:int		= 0	'paid back credit today
	Field expense_creditInterest:int	= 0	'interest to pay for the current credit
	Field expense_drawingCreditInterest:int	= 0	'interest to pay for having a negative balance
	Field expense_total:Int 			= 0

	Field income_programmeLicences:Int	= 0
	Field income_ads:Int				= 0
	Field income_callerRevenue:Int		= 0
	Field income_sponsorshipRevenue:Int	= 0
	Field income_misc:Int				= 0
	Field income_total:Int				= 0
	Field income_stations:Int			= 0
	Field income_creditTaken:Int		= 0 'freshly taken credit today
	Field income_balanceInterest:int	= 0	'interest for money "on the bank"
	Field revenue_before:Int 			= 0
	Field revenue_after:Int 			= 0
	Field money:Int						= 0
	Field credit:Int 					= 0
	Field ListLink:TLink
	Field playerID:int					= Null

	Global creditInterestRate:float		= 0.05 '5% a day
	Global balanceInterestRate:float	= 0.01 '1% a day
	Global drawingCreditRate:float		= 0.03 '3% a day  - rate for having a negative balance
	Global List:TList					= CreateList()


	Method Create:TPlayerFinance(playerID:int, startmoney:Int=500000, startcredit:Int = 500000)
		money = startmoney
		revenue_before = startmoney
		revenue_after = startmoney

		credit = startcredit
		Self.playerID = playerID
		ListLink = List.AddLast(Self)
		Return Self
	End Method


	'take the current balance (money and credit) to the next day
	Function TakeOverFinances:Int(fromFinance:TPlayerFinance, toFinance:TPlayerFinance Var)
		If Not toFinance Then Return False
		'if the "fromFinance" does not exist yet just assume the same
		'value than of "toFinance" - so no modification would be needed
		'in all other cases:
		If fromFinance
			'remove current finance from financials.list as we create a new one
			toFinance.ListLink.remove()
			toFinance = Null
			'create the new financial but give the yesterdays money/credit
			toFinance = New TPlayerFinance.Create(fromFinance.playerID, fromFinance.money, fromFinance.credit)
		EndIf
	End Function


	'returns whether the finances allow the given transaction
	Method CanAfford:Int(price:Int=0)
		Return (money > 0 And money >= price)
	End Method


	Method GetCurrentProfit:Int()
		return revenue_after - revenue_before
	End Method


	Method ChangeMoney(value:Int)
		'TLogger.log("TFinancial.ChangeMoney()", "Player "+player.playerID+" changed money by "+value, LOG_DEBUG)
		money			:+ value
		revenue_after	:+ value
		'emit event to inform others
		EventManager.triggerEvent( TEventSimple.Create("PlayerFinance.onChangeMoney", new TData.AddNumber("value", value).AddNumber("playerID", playerID)) )
	End Method


	Method TransactionFailed:int(value:int)
		'emit event to inform others
		EventManager.triggerEvent( TEventSimple.Create("PlayerFinance.onTransactionFailed", new TData.AddNumber("value", value).AddNumber("playerID", playerID)) )
		return False
	End Method


	Method AddIncome(value:Int)
		income_total :+ value
		ChangeMoney(value)
	End Method


	Method AddExpense(value:Int)
		expense_total :+ value
		ChangeMoney(-value)
	End Method


	Method RepayCredit:Int(value:Int)
		TLogger.Log("TFinancial.RepayCredit()", "Player "+playerID+" repays (a part of his) credit of "+value, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_CREDIT_REPAY, -value, null).AddTo(playerID)

		credit :- value
		expense_creditRepayed :+ value
		expense_total :+ value
		ChangeMoney(-value)
	End Method


	Method TakeCredit:Int(value:Int)
		TLogger.Log("TFinancial.TakeCredit()", "Player "+playerID+" took a credit of "+value, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_CREDIT_TAKE, +value).AddTo(playerID)

		credit :+ value
		income_creditTaken :+ value
		income_total :+ value
		ChangeMoney(+value)
	End Method


	'refreshs stats about misc sells
	Method SellMisc:Int(price:Int)
		TLogger.Log("TFinancial.SellMisc()", "Player "+playerID+" sold mics for "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_SELL_MISC, +price).AddTo(playerID)

		income_misc :+ price
		AddIncome(price)
		Return True
	End Method


	Method SellStation:Int(price:Int)
		TLogger.Log("TFinancial.SellStation()", "Player "+playerID+" sold a station for "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_SELL_STATION, +price).AddTo(playerID)

		income_stations :+ price
		AddIncome(price)
		Return True
	End Method


	'refreshs stats about earned money from adspots
	Method EarnAdProfit:Int(value:Int, contract:object)
		TLogger.Log("TFinancial.EarnAdProfit()", "Player "+playerID+" earned "+value+" with ads", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_EARN_ADPROFIT, +value, contract).AddTo(playerID)

		income_ads :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from adspots sent as infomercial
	Method EarnInfomercialRevenue:Int(value:Int, contract:object)
		TLogger.Log("TFinancial.EarnInfomercialRevenue()", "Player "+playerID+" earned "+value+" with ads", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_EARN_INFOMERCIALREVENUE, +value, contract).AddTo(playerID)

		income_ads :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from sending ad powered shows or call-in
	Method EarnCallerRevenue:Int(value:Int, licence:object)
		TLogger.Log("TFinancial.EarnCallerRevenue()", "Player "+playerID+" earned "+value+" with a call-in-show", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_EARN_CALLERREVENUE, +value, licence).AddTo(playerID)

		income_callerRevenue :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from sending ad powered shows or call-in
	Method EarnSponsorshipRevenue:Int(value:Int, licence:object)
		TLogger.Log("TFinancial.EarnSponsorshipRevenue()", "Player "+playerID+" earned "+value+" broadcasting a sponsored programme", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_EARN_SPONSORSHIPREVENUE, +value, licence).AddTo(playerID)

		income_sponsorshipRevenue :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from selling a movie/programme
	Method SellProgrammeLicence:Int(price:Int, licence:object)
		TLogger.Log("TFinancial.SellLicence()", "Player "+playerID+" earned "+price+" selling a programme licence", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_SELL_PROGRAMMELICENCE, +price, licence).AddTo(playerID)

		income_programmeLicences :+ price
		AddIncome(price)
	End Method


	'refreshs stats about earned money from interest on the current balance
	Method EarnBalanceInterest:Int(value:Int)
		TLogger.Log("TFinancial.EarnBalanceInterest()", "Player "+playerID+" earned "+value+" on interest of their current balance", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_EARN_BALANCEINTEREST, +value).AddTo(playerID)

		income_balanceInterest :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about paid money from drawing credit interest (negative current balance)
	Method PayDrawingCreditInterest:Int(value:Int)
		TLogger.Log("TFinancial.PayDrawingCreditInterest()", "Player "+playerID+" paid "+value+" on interest of having a negative current balance", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_DRAWINGCREDITINTEREST, -value).AddTo(playerID)

		expense_drawingCreditInterest :+ value
		AddExpense(value)
		Return True
	End Method


	'pay the bid for an auction programme
	Method PayAuctionBid:Int(price:Int, licence:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayAuctionBid()", "Player "+playerID+" paid a bid of "+price, LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_AUCTIONBID, -price, licence).AddTo(playerID)

			expense_programmeLicences :+ price
			AddExpense(price)
			Return True
		Else
			TransactionFailed(price)
			Return False
		EndIf
	End Method


	'get the bid back one paid before another player now has bid more
	'for an auction programme
	'ATTENTION: from a financial view this IS NOT CORRECT ... it should add
	'to "income paid_programmeLicence" ...
	Method PayBackAuctionBid:Int(price:Int, licence:object)
		TLogger.Log("TFinancial.PayBackAuctionBid()", "Player "+playerID+" received back "+price+" from an auction", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAYBACK_AUCTIONBID, +price, licence).AddTo(playerID)

		expense_programmeLicences	:- price
		expense_total				:- price
		ChangeMoney(+price)
		Return True
	End Method


	'refreshs stats about paid money from buying a movie/programme
	Method PayProgrammeLicence:Int(price:Int, licence:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayProgrammeLicence()", "Player "+playerID+" paid "+price+" for a programmeLicence", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_PROGRAMMELICENCE, -price, licence).AddTo(playerID)

			expense_programmeLicences :+ price
			AddExpense(price)
			Return True
		Else
			TransactionFailed(price)
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying a station
	Method PayStation:Int(price:Int)
		If canAfford(price)
			TLogger.Log("TFinancial.PayStation()", "Player "+playerID+" paid "+price+" for a broadcasting station", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_STATION, -price).AddTo(playerID)

			expense_stations :+ price
			AddExpense(price)
			Return True
		Else
			TransactionFailed(price)
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying a script (own production)
	Method PayScript:Int(price:Int, script:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayScript()", "Player "+playerID+" paid "+price+" for a script", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_SCRIPT, -price, script).AddTo(playerID)

			expense_scripts :+ price
			AddExpense(price)
			Return True
		Else
			TransactionFailed(price)
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying stuff for own production
	Method PayProductionStuff:Int(price:Int)
		If canAfford(price)
			TLogger.Log("TFinancial.PayProductionStuff()", "Player "+playerID+" paid "+price+" for product stuff", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_PRODUCTIONSTUFF, -price).AddTo(playerID)

			expense_productionstuff :+ price
			AddExpense(price)
			Return True
		Else
			TransactionFailed(price)
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from paying a penalty fee (not sent the necessary adspots)
	Method PayPenalty:Int(value:Int, contract:object)
		TLogger.Log("TFinancial.PayPenalty()", "Player "+playerID+" paid a failed contract penalty of "+value, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_PENALTY, -value, contract).AddTo(playerID)

		expense_penalty :+ value
		AddExpense(value)
		Return True
	End Method


	'refreshs stats about paid money from paying the rent of rooms
	Method PayRent:Int(price:Int, room:object)
		TLogger.Log("TFinancial.PayRent()", "Player "+playerID+" paid a room rent of "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_RENT, -price, room).AddTo(playerID)

		expense_rent :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying for the sent newsblocks
	Method PayNews:Int(price:Int, news:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayNews()", "Player "+playerID+" paid "+price+" for a news", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_NEWS, -price, news).AddTo(playerID)

			expense_news :+ price
			AddExpense(price)
			Return True
		Else
			TransactionFailed(price)
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from paying the daily costs a newsagency-abonnement
	Method PayNewsAgencies:Int(price:Int)
		TLogger.Log("TFinancial.PayNewsAgencies()", "Player "+playerID+" paid "+price+" for news abonnements", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_NEWSAGENCIES, -price).AddTo(playerID)

		expense_newsagencies :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying the fees for the owned stations
	Method PayStationFees:Int(price:Int)
		TLogger.Log("TFinancial.PayStationFees()", "Player "+playerID+" paid "+price+" for station fees", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_STATIONFEES, -price).AddTo(playerID)

		expense_stationfees :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying interest on the current credit
	Method PayCreditInterest:Int(price:Int)
		TLogger.Log("TFinancial.PayCreditInterest()", "Player "+playerID+" paid "+price+" on interest of their credit", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_CREDITINTEREST, -price).AddTo(playerID)

		expense_creditInterest :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying misc things
	Method PayMisc:Int(price:Int)
		TLogger.Log("TFinancial.PayStationFees()", "Player "+playerID+" paid "+price+" for misc", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistoryEntry.Init(TPlayerFinanceHistoryEntry.TYPE_PAY_MISC, -price).AddTo(playerID)

		expense_misc :+ price
		AddExpense(price)
		Return True
	End Method
End Type

