SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.event.bmx"
Import "game.gameobject.bmx"
'Import "game.toastmessage.bmx"




Type TArchivedMessageCollection Extends TGameObjectCollection
	Global _eventListeners:TEventListenerBase[] {nosave}
	Global _instance:TArchivedMessageCollection
	Global limitPerPlayer:Int = 100
	Global eventKey_ArchivedMessageCollection_onAdd:TEventKey = EventManager.GetEventKey("ArchivedMessageCollection.onAdd", True)
	Global eventKey_ArchivedMessageCollection_onRemove:TEventKey = EventManager.GetEventKey("ArchivedMessageCollection.onRemove", True)

	Method New()
		'=== REGISTER EVENTS ===
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'disabled: now done manually
		'scan for newly added toast messages
		'_eventListeners :+ [ EventManager.registerListenerFunction( "ToastMessageCollection.onAddMessage", onAddToastMessage) ]
	End Method


	Function GetInstance:TArchivedMessageCollection()
		if not _instance then _instance = new TArchivedMessageCollection
		return _instance
	End Function


	Method Initialize:TArchivedMessageCollection()
		Super.Initialize()
		return self
	End Method


	'override
	Method GetByGUID:TArchivedMessage(GUID:String) override
		return TArchivedMessage(Super.GetByGUID(GUID))
	End Method


	Method GetByID:TArchivedMessage(ID:Int) override
		return TArchivedMessage(Super.GetByID(ID))
	End Method


	Method GetCountByOwner:int(owner:int)
		if owner = -1 then return GetCount()

		local count:int = 0
		For local a:TArchivedMessage = EachIn entries.Values()
			if a.GetOwner() = owner then count :+ 1
		Next
		return count
	End Method


	Method Add:int(obj:TGameObject)
		local message:TArchivedMessage = TArchivedMessage(obj)
		if not message then return False

		'keep count below 100 for each owner
		if message
			if GetCountByOwner(message.GetOwner()) > (limitPerPlayer + 10) then LimitArchive(limitPerPlayer, message.GetOwner())
		endif


		local result:int = Super.Add(obj)
		TriggerBaseEvent(eventKey_ArchivedMessageCollection_onAdd, null, Self, obj)
		return result
	End Method


	Method Remove:int(obj:TGameObject)
		local result:int = Super.Remove(obj)
		TriggerBaseEvent(eventKey_ArchivedMessageCollection_onRemove, null, Self, obj)
		return result
	End Method


	Method RemoveAll:int(owner:int = -1)
		local toRemove:TArchivedMessage[]

		'create a full array containing all elements
		For local a:TArchivedMessage = EachIn entries.Values()
			if owner = -1 or a.GetOwner() = owner then toRemove :+ [a]
		Next


		For local a:TArchivedMessage = EachIn toRemove
			Remove(a)
		Next
	End Method


	Method LimitArchive:int(limitToAmount:int, owner:int = -1)
		if GetCountByOwner(owner) < limitToAmount then return False

		local list:TList = new TList
		'create a full array containing all elements
		For local a:TArchivedMessage = EachIn entries.Values()
			if owner = -1 or a.GetOwner() = owner then list.AddLast(a)
		Next
		list.Sort(False, TArchivedMessage.SortByTime)

		'instead of replacing the tmap with a new one, we remove
		'each entry on its own to keep potential tmap-references intact
		local index:int = 0
		For local a:TArchivedMessage = EachIn list
			index :+ 1
			if index <= limitToAmount then continue

			Remove(a)
		Next
		return index > limitToAmount
	End Method


	rem
	Function onAddToastMessage:int(triggerEvent:TEventBase)
		local toastMessage:TGameToastMessage = TGameToastMessage(triggerEvent.GetReceiver())
		if not toastMessage
			print "ToastMessageCollection.onAddMessage: receiver not of type TGameToastMessage."
			return False
		endif

		local archivedMessage:TArchivedMessage = new TArchivedMessage
		archivedMessage.SetTitle(toastMessage.caption)
		archivedMessage.SetText(toastMessage.text)
		archivedMessage.messageCategory = toastMessage.messageCategory
		archivedMessage.group = toastMessage.messageType 'positive, negative, information ...
		archivedMessage.time = GetWorldTime().GetTimeGone()
		archivedMessage.sourceGUID = toastMessage.GetGUID()
		archivedMessage.SetOwner( toastMessage.GetData().GetInt("playerID", -1) )

		GetInstance().Add(archivedMessage)
	End Function
	endrem
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetArchivedMessageCollection:TArchivedMessageCollection()
	Return TArchivedMessageCollection.GetInstance()
End Function

Function GetArchivedMessage:TArchivedMessage(GUID:string)
	Return TArchivedMessageCollection.GetInstance().GetByGUID(GUID)
End Function

Function GetArchivedMessage:TArchivedMessage(ID:Int)
	Return TArchivedMessageCollection.GetInstance().GetByID(ID)
End Function




Type TArchivedMessage extends TOwnedGameObject
	Field title:string
	Field text:string
	'bitmask containing "read"-state for the players
	Field read:int
	'corresponds to TVTMessageCategory
	Field messageCategory:int
	'positive, information, negative, warning ...
	Field group:int
	Field time:Long
	Field sourceGUID:string

	Method GenerateGUID:string()
		return "archivedmessage-"+id
	End Method


	Method GetTitle:string()
		return title
	End Method


	Method SetTitle:TArchivedMessage(title:string)
		self.title = title
		return self
	End Method


	Method GetText:string()
		return text
	End Method


	Method SetText:TArchivedMessage(text:string)
		self.text = text
		return self
	End Method


	Method IsRead:Int(playerID:Int) {_exposeToLua}
		Return read & int(1^playerID)
	End Method


	Method SetRead(playerID:Int, enable:Int=True)
		If enable
			read :| int(1^playerID)
		Else
			read :& ~int(1^playerID)
		EndIf
	End Method


	'=== SORT FUNCTIONS ===
	'default sort by time
	Method Compare:int(other:object)
		Return SortByTime(self, other)
	End Method

	
	Function SortByGUID:int(o1:Object, o2:Object)
		Local a1:TArchivedMessage = TArchivedMessage(o1)
		Local a2:TArchivedMessage = TArchivedMessage(o2)
		If Not a2 Then Return 1
		If Not a1 Then Return -1
		if a1.GetGUID() = a2.GetGUID()
			'shouldnt happen at all
			return 0
		endif
        If a1.GetGUID() > a2.GetGUID()
			return 1
        elseif a1.GetGUID() < a2.GetGUID()
			return -1
		endif
		return 0
	End Function


	Function SortByTime:Int(o1:Object, o2:Object)
		Local a1:TArchivedMessage = TArchivedMessage(o1)
		Local a2:TArchivedMessage = TArchivedMessage(o2)
		if a1 and a2
			If a1.time > a2.time
				return 1
			elseif a1.time < a2.time
				return -1
			endif
		endif
		return SortByGUID(o1,o2)
	End Function


	Function SortByName:Int(o1:Object, o2:Object)
		Local a1:TArchivedMessage = TArchivedMessage(o1)
		Local a2:TArchivedMessage = TArchivedMessage(o2)
		if a1 and a2
			If a1.GetTitle().ToLower() > a2.GetTitle().ToLower()
				return 1
			elseif a1.GetTitle().ToLower() < a2.GetTitle().ToLower()
				return -1
			endif
		endif
		return SortByTime(o1,o2)
	End Function


	Function SortByGroup:int(o1:object, o2:object)
		Local a1:TArchivedMessage = TArchivedMessage(o1)
		Local a2:TArchivedMessage = TArchivedMessage(o2)
		If a2 and a1
			if a1.group < a2.group
				return -1
			elseif a1.group > a2.group
				return 1
			endif
		Endif
		return SortByTime(o1, o2)
	End Function


	Function SortByCategory:int(o1:object, o2:object)
		Local a1:TArchivedMessage = TArchivedMessage(o1)
		Local a2:TArchivedMessage = TArchivedMessage(o2)
		If a2 and a1
			if a1.messageCategory < a2.messageCategory
				return -1
			elseif a1.messageCategory > a2.messageCategory
				return 1
			endif
		Endif
		return SortByGroup(o1, o2)
	End Function
End Type

