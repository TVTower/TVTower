SuperStrict
Import Brl.LinkedList
Import "Dig/base.util.localization.bmx"
Import "game.gameobject.bmx"
Import "game.gametime.bmx"

'collection holds a list of entries for each player
Type TPlayerFinanceHistoryListCollection
	Field historyLists:TList[]
	Global _instance:TPlayerFinanceHistoryListCollection


	Function GetInstance:TPlayerFinanceHistoryListCollection()
		if not _instance then _instance = new TPlayerFinanceHistoryListCollection
		return _instance
	End Function


	Method Set:int(playerID:int, historyList:TList)
		if playerID <= 0 then return False
		if playerID > historyLists.length then historyLists = historyLists[.. playerID]
		historyLists[playerID-1] = historyList
	End Method


	Method Get:TList(playerID:int)
		if playerID <= 0 then return null


		'create if slot contains no history yet
		if playerID > historyLists.length then historyLists = historyLists[.. playerID]
		if not historyLists[playerID-1] then historyLists[playerID-1] = CreateList()

		return historyLists[playerID-1]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPlayerFinanceHistoryListCollection:TPlayerFinanceHistoryListCollection()
	Return TPlayerFinanceHistoryListCollection.GetInstance()
End Function



Type TPlayerFinanceHistoryEntry
	'the id of this entry (eg. movie, station ...)
	Field typeID:int = 0
	'the specific object (eg. movie)
	Field obj:object
	Field money:int = 0
	Field gameTime:int = 0

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



	Method Init:TPlayerFinanceHistoryEntry(typeID:int, money:int, obj:object=null, gameTime:int = -1)
		if gameTime = -1 then gameTime = GetGameTime().GetTimeGone()
		self.typeID = typeID
		self.obj = obj
		self.money = money
		self.gameTime = gameTime

		Return self
	End Method


	Method AddTo:int(playerID:int)
		local list:TList = TPlayerFinanceHistoryListCollection.GetInstance().Get(playerID)
		list.AddLast(self)
		list.Sort()
	End Method


	Method Compare:int(otherObject:Object)
		local other:TPlayerFinanceHistoryEntry = TPlayerFinanceHistoryEntry(otherObject)
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
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_PROGRAMMELICENCE").Replace("%TITLE%", title)
			Case TYPE_PAY_AUCTIONBID
				local title:string = "unknown licence"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_AUCTIONBID").Replace("%TITLE%", title)
			Case TYPE_PAYBACK_AUCTIONBID
				local title:string = "unknown licence"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_AUCTIONBIDREPAYED").Replace("%TITLE%", title)
			Case TYPE_EARN_CALLERREVENUE
				return GetLocale("FINANCES_HISTORY_OF_CALLERREVENUE")
			Case TYPE_EARN_INFOMERCIALREVENUE
				return GetLocale("FINANCES_HISTORY_OF_INFOMERCIALREVENUE")
			Case TYPE_EARN_ADPROFIT
				local title:string = "unknown contract"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_OF_ADPROFIT").Replace("%TITLE%", title)
			Case TYPE_EARN_SPONSORSHIPREVENUE
				return GetLocale("FINANCES_HISTORY_OF_SPONSORSHIPREVENUE")
			Case TYPE_PAY_PENALTY
				return GetLocale("FINANCES_HISTORY_OF_PENALTY")
			Case TYPE_PAY_SCRIPT
				local title:string = "unknown script"
'				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_SCRIPT").Replace("%TITLE%", title)
			Case TYPE_PAY_PRODUCTIONSTUFF
				return GetLocale("FINANCES_HISTORY_FOR_PRODUCTIONSTUFF")
			Case TYPE_PAY_RENT
				return GetLocale("FINANCES_HISTORY_FOR_RENT")
			Case TYPE_PAY_NEWS
				local title:string = "unknown news"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
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
