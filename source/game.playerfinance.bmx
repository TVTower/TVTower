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
		'TLogger.log("TFinancial.ChangeMoney()", "Player "+player.playerID+" changed money by "+value, LOG_DEBUG)
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
		TLogger.Log("TFinancial.RepayCredit()", "Player "+player.playerID+" repays (a part of his) credit of "+value, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_CREDIT_REPAY, -value, null).AddTo(player.playerID)

		credit :- value
		expense_creditRepayed :+ value
		expense_total :+ value
		ChangeMoney(-value)
	End Method


	Method TakeCredit:Int(value:Int)
		TLogger.Log("TFinancial.TakeCredit()", "Player "+player.playerID+" took a credit of "+value, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_CREDIT_TAKE, +value).AddTo(player.playerID)

		credit :+ value
		income_creditTaken :+ value
		income_total :+ value
		ChangeMoney(+value)
	End Method


	'refreshs stats about misc sells
	Method SellMisc:Int(price:Int)
		TLogger.Log("TFinancial.SellMisc()", "Player "+player.playerID+" sold mics for "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_SELL_MISC, +price).AddTo(player.playerID)

		income_misc :+ price
		AddIncome(price)
		Return True
	End Method


	Method SellStation:Int(price:Int)
		TLogger.Log("TFinancial.SellStation()", "Player "+player.playerID+" sold a station for "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_SELL_STATION, +price).AddTo(player.playerID)

		income_stations :+ price
		AddIncome(price)
		Return True
	End Method


	'refreshs stats about earned money from adspots
	Method EarnAdProfit:Int(value:Int, contract:object)
		TLogger.Log("TFinancial.EarnAdProfit()", "Player "+player.playerID+" earned "+value+" with ads", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_EARN_ADPROFIT, +value, contract).AddTo(player.playerID)

		income_ads :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from adspots sent as infomercial
	Method EarnInfomercialRevenue:Int(value:Int, contract:object)
		TLogger.Log("TFinancial.EarnInfomercialRevenue()", "Player "+player.playerID+" earned "+value+" with ads", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_EARN_INFOMERCIALREVENUE, +value, contract).AddTo(player.playerID)

		income_ads :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from sending ad powered shows or call-in
	Method EarnCallerRevenue:Int(value:Int, licence:object)
		TLogger.Log("TFinancial.EarnCallerRevenue()", "Player "+player.playerID+" earned "+value+" with a call-in-show", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_EARN_CALLERREVENUE, +value, licence).AddTo(player.playerID)

		income_callerRevenue :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from sending ad powered shows or call-in
	Method EarnSponsorshipRevenue:Int(value:Int, licence:object)
		TLogger.Log("TFinancial.EarnSponsorshipRevenue()", "Player "+player.playerID+" earned "+value+" broadcasting a sponsored programme", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_EARN_SPONSORSHIPREVENUE, +value, licence).AddTo(player.playerID)

		income_sponsorshipRevenue :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about earned money from selling a movie/programme
	Method SellProgrammeLicence:Int(price:Int, licence:object)
		TLogger.Log("TFinancial.SellLicence()", "Player "+player.playerID+" earned "+price+" selling a programme licence", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_SELL_PROGRAMMELICENCE, +price, licence).AddTo(player.playerID)

		income_programmeLicences :+ price
		AddIncome(price)
	End Method


	'refreshs stats about earned money from interest on the current balance
	Method EarnBalanceInterest:Int(value:Int)
		TLogger.Log("TFinancial.EarnBalanceInterest()", "Player "+player.playerID+" earned "+value+" on interest of their current balance", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_EARN_BALANCEINTEREST, +value).AddTo(player.playerID)

		income_balanceInterest :+ value
		AddIncome(value)
		Return True
	End Method


	'refreshs stats about paid money from drawing credit interest (negative current balance)
	Method PayDrawingCreditInterest:Int(value:Int)
		TLogger.Log("TFinancial.PayDrawingCreditInterest()", "Player "+player.playerID+" paid "+value+" on interest of having a negative current balance", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_DRAWINGCREDITINTEREST, -value).AddTo(player.playerID)

		expense_drawingCreditInterest :+ value
		AddExpense(value)
		Return True
	End Method


	'pay the bid for an auction programme
	Method PayAuctionBid:Int(price:Int, licence:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayAuctionBid()", "Player "+player.playerID+" paid a bid of "+price, LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_AUCTIONBID, -price, licence).AddTo(player.playerID)

			expense_programmeLicences :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'get the bid back one paid before another player now has bid more
	'for an auction programme
	'ATTENTION: from a financial view this IS NOT CORRECT ... it should add
	'to "income paid_programmeLicence" ...
	Method PayBackAuctionBid:Int(price:Int, licence:object)
		TLogger.Log("TFinancial.PayBackAuctionBid()", "Player "+player.playerID+" received back "+price+" from an auction", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAYBACK_AUCTIONBID, +price, licence).AddTo(player.playerID)

		expense_programmeLicences	:- price
		expense_total				:- price
		ChangeMoney(+price)
		Return True
	End Method


	'refreshs stats about paid money from buying a movie/programme
	Method PayProgrammeLicence:Int(price:Int, licence:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayProgrammeLicence()", "Player "+player.playerID+" paid "+price+" for a programmeLicence", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_PROGRAMMELICENCE, -price, licence).AddTo(player.playerID)

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
			TLogger.Log("TFinancial.PayStation()", "Player "+player.playerID+" paid "+price+" for a broadcasting station", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_STATION, -price).AddTo(player.playerID)

			expense_stations :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from buying a script (own production)
	Method PayScript:Int(price:Int, script:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayScript()", "Player "+player.playerID+" paid "+price+" for a script", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_SCRIPT, -price, script).AddTo(player.playerID)

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
			TLogger.Log("TFinancial.PayProductionStuff()", "Player "+player.playerID+" paid "+price+" for product stuff", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_PRODUCTIONSTUFF, -price).AddTo(player.playerID)

			expense_productionstuff :+ price
			AddExpense(price)
			Return True
		Else
			If player.isActivePlayer() Then TError.CreateNotEnoughMoneyError()
			Return False
		EndIf
	End Method


	'refreshs stats about paid money from paying a penalty fee (not sent the necessary adspots)
	Method PayPenalty:Int(value:Int, contract:object)
		TLogger.Log("TFinancial.PayPenalty()", "Player "+player.playerID+" paid a failed contract penalty of "+value, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_PENALTY, -value, contract).AddTo(player.playerID)

		expense_penalty :+ value
		AddExpense(value)
		Return True
	End Method


	'refreshs stats about paid money from paying the rent of rooms
	Method PayRent:Int(price:Int, room:object)
		TLogger.Log("TFinancial.PayRent()", "Player "+player.playerID+" paid a room rent of "+price, LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_RENT, -price, room).AddTo(player.playerID)

		expense_rent :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying for the sent newsblocks
	Method PayNews:Int(price:Int, news:object)
		If canAfford(price)
			TLogger.Log("TFinancial.PayNews()", "Player "+player.playerID+" paid "+price+" for a news", LOG_DEBUG)
			'add this to our history
			new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_NEWS, -price, news).AddTo(player.playerID)

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
		TLogger.Log("TFinancial.PayNewsAgencies()", "Player "+player.playerID+" paid "+price+" for news abonnements", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_NEWSAGENCIES, -price).AddTo(player.playerID)

		expense_newsagencies :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying the fees for the owned stations
	Method PayStationFees:Int(price:Int)
		TLogger.Log("TFinancial.PayStationFees()", "Player "+player.playerID+" paid "+price+" for station fees", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_STATIONFEES, -price).AddTo(player.playerID)

		expense_stationfees :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying interest on the current credit
	Method PayCreditInterest:Int(price:Int)
		TLogger.Log("TFinancial.PayCreditInterest()", "Player "+player.playerID+" paid "+price+" on interest of their credit", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_CREDITINTEREST, -price).AddTo(player.playerID)

		expense_creditInterest :+ price
		AddExpense(price)
		Return True
	End Method


	'refreshs stats about paid money from paying misc things
	Method PayMisc:Int(price:Int)
		TLogger.Log("TFinancial.PayStationFees()", "Player "+player.playerID+" paid "+price+" for misc", LOG_DEBUG)
		'add this to our history
		new TPlayerFinanceHistory.Init(TPlayerFinanceHistory.TYPE_PAY_MISC, -price).AddTo(player.playerID)

		expense_misc :+ price
		AddExpense(price)
		Return True
	End Method
End Type




Type TPlayerFinanceHistory
	'the id of this entry (eg. movie, station ...)
	Field typeID:int = 0
	'the specific object (eg. movie)
	Field obj:object
	Field money:int = 0
	Field gameTime:int = 0
	'a list for each player
	Global list:TList[5]

	Const TYPE_CREDIT_REPAY:int = 11
	Const TYPE_CREDIT_TAKE:int = 12

	Const TYPE_PAY_STATION:int = 21
	Const TYPE_SELL_STATION:int = 22
	Const TYPE_PAY_STATIONFEES:int = 23

	Const TYPE_SELL_MISC:int = 31
	Const TYPE_PAY_MISC:int = 32

	Const TYPE_SELL_PROGRAMMELICENCE:int = 41
	Const TYPE_PAY_PROGRAMMELICENCE:int = 42
	Const TYPE_PAYBACK_AUCTIONBID:int = 43
	Const TYPE_PAY_AUCTIONBID:int = 44

	Const TYPE_EARN_CALLERREVENUE:int = 51
	Const TYPE_EARN_INFOMERCIALREVENUE:int = 52
	Const TYPE_EARN_ADPROFIT:int = 53
	Const TYPE_EARN_SPONSORSHIPREVENUE:int = 54
	Const TYPE_PAY_PENALTY:int = 55

	Const TYPE_PAY_SCRIPT:int = 61
	Const TYPE_PAY_PRODUCTIONSTUFF:int = 62
	Const TYPE_PAY_RENT:int = 63

	Const TYPE_PAY_NEWS:int = 71
	Const TYPE_PAY_NEWSAGENCIES:int = 72

	Const TYPE_PAY_CREDITINTEREST:int = 81
	Const TYPE_PAY_DRAWINGCREDITINTEREST:int = 82
	Const TYPE_EARN_BALANCEINTEREST:int = 83

	Const GROUP_NEWS:int = 1
	Const GROUP_PROGRAMME:int = 2
	Const GROUP_DEFAULT:int = 3
	Const GROUP_PRODUCTION:int = 4
	Const GROUP_STATION:int = 5



	Method Init:TPlayerFinanceHistory(typeID:int, money:int, obj:object=null, gameTime:int = -1)
		if gameTime = -1 then gameTime = Game.GetTimeGone()
		self.typeID = typeID
		self.obj = obj
		self.money = money
		self.gameTime = gameTime

		Return self
	End Method


	Function GetList:TList(playerID:int = -1)
		if playerID = -1 then playerID = Game.GetPlayer().playerID
		if not list[playerID] then list[playerID] = CreateList()
		return list[playerID]
	End function


	Method AddTo:int(playerID:int=-1)
		if playerID = -1 then playerID = Game.GetPlayer().playerID
		if not list[playerID] then list[playerID] = CreateList()

		list[playerID].AddLast(self)

		list[playerID].Sort()
	End Method



	Method Compare:int(otherObject:Object)
		local other:TPlayerFinanceHistory = TPlayerFinanceHistory(otherObject)
		If Not other Return 1
		Return other.gameTime - self.gameTime
	End Method



	Method GetMoney:int()
		return money
	End Method

	'returns a text describing the history
	Method GetDescription:String()
		Select typeID
			Case TYPE_CREDIT_REPAY
				return GetLocale("FINANCES_HISTORY_FOR_CREDITREPAID")
			Case TYPE_CREDIT_TAKE
				return GetLocale("FINANCES_HISTORY_FOR_CREDITTAKEN")
			Case TYPE_PAY_STATION
				return GetLocale("FINANCES_HISTORY_FOR_STATIONBOUGHT")
			Case TYPE_SELL_STATION
				return GetLocale("FINANCES_HISTORY_FOR_STATIONSOLD")
			Case TYPE_PAY_STATIONFEES
				return GetLocale("FINANCES_HISTORY_OF_STATIONFEES")
			Case TYPE_SELL_MISC, TYPE_PAY_MISC
				return GetLocale("FINANCES_HISTORY_FOR_MISC")
			Case TYPE_SELL_PROGRAMMELICENCE, TYPE_PAY_PROGRAMMELICENCE
				local title:string = "unknown licence"
				if TProgrammeLicence(obj) then title = TProgrammeLicence(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_PROGRAMMELICENCE").Replace("%TITLE%", title)
			Case TYPE_PAY_AUCTIONBID
				local title:string = "unknown licence"
				if TProgrammeLicence(obj) then title = TProgrammeLicence(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_AUCTIONBID").Replace("%TITLE%", title)
			Case TYPE_PAYBACK_AUCTIONBID
				local title:string = "unknown licence"
				if TProgrammeLicence(obj) then title = TProgrammeLicence(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_AUCTIONBIDREPAYED").Replace("%TITLE%", title)
			Case TYPE_EARN_CALLERREVENUE
				return GetLocale("FINANCES_HISTORY_OF_CALLERREVENUE")
			Case TYPE_EARN_INFOMERCIALREVENUE
				return GetLocale("FINANCES_HISTORY_OF_INFOMERCIALREVENUE")
			Case TYPE_EARN_ADPROFIT
				local title:string = "unknown contract"
				if TAdContract(obj) then title = TAdContract(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_OF_ADPROFIT").Replace("%TITLE%", title)
			Case TYPE_EARN_SPONSORSHIPREVENUE
				return GetLocale("FINANCES_HISTORY_OF_SPONSORSHIPREVENUE")
			Case TYPE_PAY_PENALTY
				return GetLocale("FINANCES_HISTORY_OF_PENALTY")
			Case TYPE_PAY_SCRIPT
				local title:string = "unknown script"
'				if TAdContract(obj) then title = TAdContract(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_SCRIPT").Replace("%TITLE%", title)
			Case TYPE_PAY_PRODUCTIONSTUFF
				return GetLocale("FINANCES_HISTORY_FOR_PRODUCTIONSTUFF")
			Case TYPE_PAY_RENT
				return GetLocale("FINANCES_HISTORY_FOR_RENT")
			Case TYPE_PAY_NEWS
				local title:string = "unknown news"
				if TNews(obj) then title = TNews(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_NEWS").Replace("%TITLE%", title)
			Case TYPE_PAY_NEWSAGENCIES
				return GetLocale("FINANCES_HISTORY_FOR_NEWSAGENCY")
			Case TYPE_PAY_CREDITINTEREST
				return GetLocale("FINANCES_HISTORY_OF_CREDITINTEREST")
			Case TYPE_PAY_DRAWINGCREDITINTEREST
				return GetLocale("FINANCES_HISTORY_OF_DRAWINGCREDITINTEREST")
			Case TYPE_EARN_BALANCEINTEREST
				return GetLocale("FINANCES_HISTORY_OF_BALANCEINTEREST")
			Default
				return GetLocale("FINANCES_HISTORY_FOR_SOMETHING")
		End Select
	End Method


	'returns the group a type belongs to
	Method GetTypeGroup:int()
		Select typeID
			Case TYPE_CREDIT_REPAY, TYPE_CREDIT_TAKE
				Return GROUP_DEFAULT
			Case TYPE_PAY_STATION, TYPE_SELL_STATION, TYPE_PAY_STATIONFEES
				Return GROUP_STATION
			Case TYPE_SELL_MISC, TYPE_PAY_MISC
				Return GROUP_DEFAULT
			Case TYPE_SELL_PROGRAMMELICENCE, ..
			     TYPE_PAY_PROGRAMMELICENCE, ..
			     TYPE_EARN_CALLERREVENUE, ..
			     TYPE_EARN_INFOMERCIALREVENUE, ..
			     TYPE_EARN_SPONSORSHIPREVENUE, ..
			     TYPE_EARN_ADPROFIT, ..
			     TYPE_PAY_AUCTIONBID, ..
			     TYPE_PAYBACK_AUCTIONBID, ..
				 TYPE_PAY_PENALTY
				Return GROUP_PROGRAMME
			Case TYPE_PAY_SCRIPT, TYPE_PAY_PRODUCTIONSTUFF, TYPE_PAY_RENT
				return GROUP_PRODUCTION
			Case TYPE_PAY_NEWS, TYPE_PAY_NEWSAGENCIES
				return GROUP_NEWS
			Case TYPE_PAY_CREDITINTEREST,..
			     TYPE_PAY_DRAWINGCREDITINTEREST, ..
			     TYPE_EARN_BALANCEINTEREST
				return GROUP_DEFAULT
			Default
				return GROUP_DEFAULT
		End Select
	End Method


	Method GetTypeID:int()
		return typeID
	End Method
End Type

