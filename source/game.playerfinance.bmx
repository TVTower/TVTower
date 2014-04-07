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
	Field income_balanceInterest:int	= 0	'interest for money "on the bank"
	Field revenue_before:Int 			= 0
	Field revenue_after:Int 			= 0
	Field money:Int						= 0
	Field credit:Int 					= 0
	Field ListLink:TLink
	Field player:TPlayer				= Null
	Global creditInterestRate:float		= 0.05 '5% a day
	Global balanceInterestRate:float	= 0.01 '1% a day
	Global drawingCreditRate:float		= 0.03 '3% a day  - rate for having a negative balance
	Global List:TList					= CreateList()


	Method Create:TPlayerFinance(player:TPlayer, startmoney:Int=500000, startcredit:Int = 500000)
		money			= startmoney
		revenue_before	= startmoney
		revenue_after	= startmoney

		credit			= startcredit
		Self.player		= player
		ListLink		= List.AddLast(Self)
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
			toFinance = New TPlayerFinance.Create(fromFinance.player, fromFinance.money, fromFinance.credit)
		EndIf
	End Function


	'returns whether the finances allow the given transaction
	Method CanAfford:Int(price:Int=0)
		Return (money > 0 And money >= price)
	End Method


	Method ChangeMoney(value:Int)
		'TDevHelper.log("TFinancial.ChangeMoney()", "Player "+player.playerID+" changed money by "+value, LOG_DEBUG)
		money			:+ value
		revenue_after	:+ value
		'change to event?
		If Game.isGameLeader() And player.isAI() Then player.PlayerKI.CallOnMoneyChanged()
		If player.isActivePlayer() Then Interface.BottomImgDirty = True
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
		TDevHelper.Log("TFinancial.RepayCredit()", "Player "+player.playerID+" repays (a part of his) credit of "+value, LOG_DEBUG)
		credit			:- value
		income_misc		:- value
		income_total	:- value
		expense_misc	:- value
		expense_total	:- value
		ChangeMoney(-value)
	End Method


	Method TakeCredit:Int(value:Int)
		TDevHelper.Log("TFinancial.TakeCredit()", "Player "+player.playerID+" took a credit of "+value, LOG_DEBUG)
		credit			:+ value
		income_misc		:+ value
		income_total	:+ value
		expense_misc	:+ value
		expense_total	:+ value
		ChangeMoney(+value)
	End Method


	'refreshs stats about misc sells
	Method SellMisc:Int(price:Int)
		TDevHelper.Log("TFinancial.SellMisc()", "Player "+player.playerID+" sold mics for "+price, LOG_DEBUG)
		income_misc :+ price
		AddIncome(price)
		Return True
	End Method


	Method SellStation:Int(price:Int)
		TDevHelper.Log("TFinancial.SellStation()", "Player "+player.playerID+" sold a station for "+price, LOG_DEBUG)
		income_stations :+ price
		AddIncome(price)
		Return True
	End Method


	'refreshs stats about earned money from adspots
	Method EarnAdProfit:Int(value:Int)
		TDevHelper.Log("TFinancial.EarnAdProfit()", "Player "+player.playerID+" earned "+value+" with ads", LOG_DEBUG)
		income_ads :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from sending ad powered shows or call-in
	Method EarnCallerRevenue:Int(value:Int)
		TDevHelper.Log("TFinancial.EarnCallerRevenue()", "Player "+player.playerID+" earned "+value+" with a call-in-show", LOG_DEBUG)
		income_callerRevenue :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from sending ad powered shows or call-in
	Method EarnSponsorshipRevenue:Int(value:Int)
		TDevHelper.Log("TFinancial.EarnSponsorshipRevenue()", "Player "+player.playerID+" earned "+value+" broadcasting a sponsored programme", LOG_DEBUG)
		income_sponsorshipRevenue :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from selling a movie/programme
	Method SellProgrammeLicence:Int(price:Int)
		TDevHelper.Log("TFinancial.SellLicence()", "Player "+player.playerID+" earned "+price+" selling a programme licence", LOG_DEBUG)
		income_programmeLicences :+ price
		AddIncome(price)
	End Method


	'refreshs stats about earned money from interest on the current balance
	Method EarnBalanceInterest:Int(value:Int)
		TDevHelper.Log("TFinancial.EarnBalanceInterest()", "Player "+player.playerID+" earned "+value+" on interest of their current balance", LOG_DEBUG)
		income_balanceInterest :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about paid money from drawing credit interest (negative current balance)
	Method PayDrawingCreditInterest:Int(value:Int)
		TDevHelper.Log("TFinancial.PayDrawingCreditInterest()", "Player "+player.playerID+" paid "+value+" on interest of having a negative current balance", LOG_DEBUG)
		expense_drawingCreditInterest :+ value
		AddExpense(value)
		Return True
	End Method


	'pay the bid for an auction programme
	Method PayProgrammeBid:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayProgrammeBid()", "Player "+player.playerID+" paid a bid of "+price, LOG_DEBUG)
			expense_programmeLicences	:+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'get the bid paid before another player bid for an auction programme
	'ATTENTION: from a financial view this IS NOT CORRECT ... it should add
	'to "income paid_programmeLicence" ...
	Method PayBackProgrammeBid:Int(price:Int)
		TDevHelper.Log("TFinancial.PayBackProgrammeBid()", "Player "+player.playerID+" received back "+price+" from an auction", LOG_DEBUG)
		expense_programmeLicences	:- price
		expense_total				:- price
		ChangeMoney(+price)
		Return True
	End Method


	'refreshs stats about paid money from buying a movie/programme
	Method PayProgrammeLicence:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayProgrammeLicence()", "Player "+player.playerID+" paid "+price+" for a programmeLicence", LOG_DEBUG)
			expense_programmeLicences :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying a station
	Method PayStation:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayStation()", "Player "+player.playerID+" paid "+price+" for a broadcasting station", LOG_DEBUG)
			expense_stations :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying a script (own production)
	Method PayScript:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayScript()", "Player "+player.playerID+" paid "+price+" for a script", LOG_DEBUG)
			expense_scripts :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying stuff for own production
	Method PayProductionStuff:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayProductionStuff()", "Player "+player.playerID+" paid "+price+" for product stuff", LOG_DEBUG)
			expense_productionstuff :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from paying a penalty fee (not sent the necessary adspots)
	Method PayPenalty:Int(value:Int)
		TDevHelper.Log("TFinancial.PayPenalty()", "Player "+player.playerID+" paid a failed contract penalty of "+value, LOG_DEBUG)
		expense_penalty :+ value
		AddExpense(value)
		Return True
	End Method


	'refreshs stats about paid money from paying the rent of rooms
	Method PayRent:Int(price:Int)
		TDevHelper.Log("TFinancial.PayRent()", "Player "+player.playerID+" paid a room rent of "+price, LOG_DEBUG)
		expense_rent :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying for the sent newsblocks
	Method PayNews:Int(price:Int)
		If canAfford(price)
			TDevHelper.Log("TFinancial.PayNews()", "Player "+player.playerID+" paid "+price+" for a news", LOG_DEBUG)
			expense_news :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from paying the daily costs a newsagency-abonnement
	Method PayNewsAgencies:Int(price:Int)
		TDevHelper.Log("TFinancial.PayNewsAgencies()", "Player "+player.playerID+" paid "+price+" for news abonnements", LOG_DEBUG)
		expense_newsagencies :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying the fees for the owned stations
	Method PayStationFees:Int(price:Int)
		TDevHelper.Log("TFinancial.PayStationFees()", "Player "+player.playerID+" paid "+price+" for station fees", LOG_DEBUG)
		expense_stationfees :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying interest on the current credit
	Method PayCreditInterest:Int(price:Int)
		TDevHelper.Log("TFinancial.PayCreditInterest()", "Player "+player.playerID+" paid "+price+" on interest of their credit", LOG_DEBUG)
		expense_creditInterest :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying misc things
	Method PayMisc:Int(price:Int)
		TDevHelper.Log("TFinancial.PayStationFees()", "Player "+player.playerID+" paid "+price+" for misc", LOG_DEBUG)
		expense_misc :+ price
		AddExpense(price)
		Return True
	End Method
End Type