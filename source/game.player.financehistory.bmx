SuperStrict
Import Brl.LinkedList
Import "Dig/base.util.localization.bmx"
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameconstants.bmx"

'collection holds a list of entries for each player
Type TPlayerFinanceHistoryListCollection
	Field historyLists:TList[]
	Global _instance:TPlayerFinanceHistoryListCollection


	Function GetInstance:TPlayerFinanceHistoryListCollection()
		if not _instance then _instance = new TPlayerFinanceHistoryListCollection
		return _instance
	End Function


	Method Initialize:int()
		historyLists = new TList[0]
	End Method


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

	Method RemoveBeforeTime:int(time:long)
		For Local i:Int = 0 To historyLists.length-1
			Local list:TList = historyLists[i]
			Local toRemove:TPlayerFinanceHistoryEntry[]
			For Local item:TPlayerFinanceHistoryEntry = EachIn list
				If item.worldTime < time
					toRemove:+[item]
				EndIf
			Next
			For local entry:TPlayerFinanceHistoryEntry = EachIn toRemove
				list.Remove(entry)
			Next
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPlayerFinanceHistoryListCollection:TPlayerFinanceHistoryListCollection()
	Return TPlayerFinanceHistoryListCollection.GetInstance()
End Function

Function GetPlayerFinanceHistoryList:TList(player:int)
	Return TPlayerFinanceHistoryListCollection.GetInstance().Get(player)
End Function



Type TPlayerFinanceHistoryEntry
	'the id of this entry (eg. movie, station ...)
	Field typeID:int = 0
	'the specific object (eg. movie)
	Field obj:object
	Field money:Long = 0
	Field worldTime:Long = 0


	Method Init:TPlayerFinanceHistoryEntry(typeID:int, money:Long, obj:object=null, worldTime:Long = -1)
		if worldTime = -1 then worldTime = GetWorldTime().GetTimeGone()
		self.typeID = typeID
		self.obj = obj
		self.money = money
		self.worldTime = worldTime

		Return self
	End Method


	Method AddTo:int(playerID:int)
		local list:TList = TPlayerFinanceHistoryListCollection.GetInstance().Get(playerID)
		list.AddLast(self)
		list.Sort()
	End Method


	Method Compare:int(otherObject:Object)
		if otherObject = self then return 0 'no change

		local other:TPlayerFinanceHistoryEntry = TPlayerFinanceHistoryEntry(otherObject)
		If other
			if other.worldtime > self.worldTime then return 1
			if other.worldtime < self.worldTime then return -1
		EndIf
		Return Super.Compare(otherObject)
	End Method


	Method GetMoney:Long()
		return money
	End Method


	'returns a text describing the history
	Method GetDescription:String()
		Select typeID
			Case TVTPlayerFinanceEntryType.CREDIT_REPAY
				return GetLocale("FINANCES_HISTORY_FOR_CREDITREPAID")
			Case TVTPlayerFinanceEntryType.CREDIT_TAKE
				return GetLocale("FINANCES_HISTORY_FOR_CREDITTAKEN")
			Case TVTPlayerFinanceEntryType.PAY_STATION
				return GetLocale("FINANCES_HISTORY_FOR_STATIONBOUGHT")
			Case TVTPlayerFinanceEntryType.SELL_STATION
				return GetLocale("FINANCES_HISTORY_FOR_STATIONSOLD")
			Case TVTPlayerFinanceEntryType.PAY_STATIONFEES
				return GetLocale("FINANCES_HISTORY_OF_STATIONFEES")
			Case TVTPlayerFinanceEntryType.PAY_BROADCASTPERMISSION
				return GetLocale("FINANCES_HISTORY_OF_BROADCASTPERMISSIONS")
			Case TVTPlayerFinanceEntryType.SELL_MISC, ..
			     TVTPlayerFinanceEntryType.PAY_MISC
				return GetLocale("FINANCES_HISTORY_FOR_MISC")
			case TVTPlayerFinanceEntryType.CHEAT
				return GetLocale("FINANCES_HISTORY_BY_CHEAT")
			Case TVTPlayerFinanceEntryType.GRANTED_BENEFITS
				return GetLocale("FINANCES_HISTORY_OF_GRANTED_BENEFITS")
			Case TVTPlayerFinanceEntryType.SELL_PROGRAMMELICENCE, ..
			     TVTPlayerFinanceEntryType.PAY_PROGRAMMELICENCE
				local title:string = "unknown licence"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_PROGRAMMELICENCE").Replace("%TITLE%", title)
			Case TVTPlayerFinanceEntryType.PAY_AUCTIONBID
				local title:string = "unknown licence"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_AUCTIONBID").Replace("%TITLE%", title)
			Case TVTPlayerFinanceEntryType.PAYBACK_AUCTIONBID
				local title:string = "unknown licence"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_AUCTIONBIDREPAYED").Replace("%TITLE%", title)
			Case TVTPlayerFinanceEntryType.EARN_CALLERREVENUE
				return GetLocale("FINANCES_HISTORY_OF_CALLERREVENUE")
			Case TVTPlayerFinanceEntryType.EARN_INFOMERCIALREVENUE
				return GetLocale("FINANCES_HISTORY_OF_INFOMERCIALREVENUE")
			Case TVTPlayerFinanceEntryType.EARN_ADPROFIT
				local title:string = "unknown contract"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_OF_ADPROFIT").Replace("%TITLE%", title)
			Case TVTPlayerFinanceEntryType.EARN_SPONSORSHIPREVENUE
				return GetLocale("FINANCES_HISTORY_OF_SPONSORSHIPREVENUE")
			Case TVTPlayerFinanceEntryType.PAY_PENALTY
				return GetLocale("FINANCES_HISTORY_OF_PENALTY")
			Case TVTPlayerFinanceEntryType.PAY_SCRIPT, TVTPlayerFinanceEntryType.SELL_SCRIPT
				local title:string = "unknown script"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_SCRIPT").Replace("%TITLE%", title)
			Case TVTPlayerFinanceEntryType.PAY_PRODUCTIONSTUFF
				return GetLocale("FINANCES_HISTORY_FOR_PRODUCTIONSTUFF")
			Case TVTPlayerFinanceEntryType.PAY_RENT
				return GetLocale("FINANCES_HISTORY_FOR_RENT")
			Case TVTPlayerFinanceEntryType.PAY_NEWS
				local title:string = "unknown news"
				if TNamedGameObject(obj) then title = TNamedGameObject(obj).GetTitle()
				return GetLocale("FINANCES_HISTORY_FOR_NEWS").Replace("%TITLE%", title)
			Case TVTPlayerFinanceEntryType.PAY_NEWSAGENCIES
				return GetLocale("FINANCES_HISTORY_FOR_NEWSAGENCY")
			Case TVTPlayerFinanceEntryType.PAY_CREDITINTEREST
				return GetLocale("FINANCES_HISTORY_OF_CREDITINTEREST")
			Case TVTPlayerFinanceEntryType.PAY_DRAWINGCREDITINTEREST
				return GetLocale("FINANCES_HISTORY_OF_DRAWINGCREDITINTEREST")
			Case TVTPlayerFinanceEntryType.EARN_BALANCEINTEREST
				return GetLocale("FINANCES_HISTORY_OF_BALANCEINTEREST")
			Default
				return GetLocale("FINANCES_HISTORY_FOR_SOMETHING")
		End Select
	End Method


	'returns the group a type belongs to
	Method GetTypeGroup:int()
		return TVTPlayerFinanceEntryType.GetGroup(typeID)
	End Method


	Method GetTypeID:int()
		return typeID
	End Method
End Type
