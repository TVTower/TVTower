SuperStrict
Import Brl.Map
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.framework.entity.base.bmx"

Type TGameObjectCollection
	'stores the entries referenced by ID
	Field entriesID:TIntMap = new TIntMap
	'stores the entries referenced by GUID
	Field entries:TMap = new TMap
	Field entriesCount:int = -1
	Field _entriesMapEnumerator:TNodeEnumerator {nosave}

	Method Initialize:TGameObjectCollection()
		'call Remove() for all objects so they can unregister stuff
		'and tidy up in general
		For local o:TGameObject = EachIn entriesID.Values()
			o.Remove()
		Next


		entries.Clear()
		entriesID.Clear()
		entriesCount = -1
		_entriesMapEnumerator = Null

		return self
	End Method


	Method GetByID:TGameObject(ID:Int)
		Return TGameObject(entriesID.ValueForKey(ID))
	End Method


	Method GetByGUID:TGameObject(GUID:String)
		Return TGameObject(entries.ValueForKey(GUID))
	End Method


	Method SearchByPartialGUID:TGameObject(GUID:String)
		'skip searching if there is nothing to search
		if GUID.trim() = "" then return Null

		GUID = GUID.ToLower()

		'find first hit
		For local obj:TGameObject = EachIn entries.Values()
			if obj.GetGUID().ToLower().Find(GUID) >= 0
				return obj
			endif
		Next

		return Null
	End Method


	Method GetRandom:TGameObject()
		if GetCount() = 0 then return Null

		local index:int = randRange(0, GetCount() - 1)
		local pos:int = 0
		For local obj:TGameObject = EachIn entries.Values()
			if pos = index then return obj
			pos :+ 1
		Next
		return Null
	End Method


	Method GetCount:Int()
		if entriesCount >= 0 then return entriesCount

		entriesCount = 0
		For Local base:TGameObject = EachIn entries.Values()
			entriesCount :+1
		Next
		return entriesCount
	End Method


	Method Add:int(obj:TGameObject)
		if not obj then return False

		entries.Insert(obj.GetGUID(), obj)
		entriesID.Insert(obj.GetID(), obj)
		'invalidate count
		entriesCount = -1

		return TRUE
	End Method


	Method Remove:int(obj:TGameObject)
		if obj.GetGuid() and entries.Remove(obj.GetGUID())
			entriesID.Remove(obj.GetID())

			'invalidate count
			entriesCount = -1

			return True
		endif

		return False
	End Method


	Method RemoveByID:int(ID:int)
		if ID > 0
			local entry:TGameObject = TGameObject(entriesID.ValueForKey(ID))
			if entry and entries.Remove(entry)
				entries.Remove(entry.GetGUID())

				'invalidate count
				entriesCount = -1

				return True
			endif
		endif

		return False
	End Method


	Method RemoveByGUID:int(guid:string)
		if guid
			local entry:TGameObject = TGameObject(entries.ValueForKey(guid))
			if entry and entries.Remove(guid)
				entriesID.Remove(entry.GetID())

				'invalidate count
				entriesCount = -1

				return True
			endif
		endif

		return False
	End Method


	'=== ITERATOR ===
	'for "EachIn"-support

	'Set iterator to begin of array
	Method ObjectEnumerator:TGameObjectCollection()
		_entriesMapEnumerator = entries.Values()._enumerator
		'_iteratorPos = 0
		Return Self
	End Method


	'checks if there is another element
	Method HasNext:Int()
		Return _entriesMapEnumerator.HasNext()

		'If _iteratorPos > GetCount() Then Return False
		'Return True
	End Method


	'return next element, and increase position
	Method NextObject:Object()
		Return _entriesMapEnumerator.NextObject()

		'_iteratorPos :+ 1
		'Return Array[Iteration-1]
	End Method
End Type



Type TGameObject Extends TEntityBase {_exposeToLua="selected"}
End Type




Type TOwnedGameObject Extends TGameObject {_exposeToLua="selected"}
	Field owner:Int = 0
	Const OWNER_NOBODY:int = -1
	Const OWNER_VENDOR:int = 0

	Method SetOwner:Int(owner:Int=0) {_exposeToLua}
		Self.owner = owner
	End Method


	Method GetOwner:Int() {_exposeToLua}
		Return owner
	End Method


	Method IsOwner:int(owner:int)
		return self.owner = owner
	End Method


	Method IsOwned:int()
		return owner <> OWNER_NOBODY
	End Method


	Method IsOwnedByNobody:int()
		return owner = OWNER_NOBODY
	End Method


	Method IsOwnedByVendor:int()
		return owner = OWNER_VENDOR
	End Method


	Method IsOwnedByPlayer:int(player:int=-1)
		if player = -1 then return owner > 0
		return owner = player
	End Method
End Type




Type TNamedGameObject Extends TOwnedGameObject {_exposeToLua="selected"}

	Method GetTitle:String() abstract
End Type
