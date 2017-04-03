SuperStrict
Import Brl.Map
Import "Dig/base.util.mersenne.bmx"

Type TGameObjectCollection
	Field entries:TMap = CreateMap()
	Field entriesCount:int = -1
	Field _entriesMapEnumerator:TNodeEnumerator {nosave}

	Method Initialize:TGameObjectCollection()
		entries.Clear()
		entriesCount = -1

		return self
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
		local array:TGameObject[]
		'create a full array containing all elements
		For local obj:TGameObject = EachIn entries.Values()
			array :+ [obj]
		Next
		if array.length = 0 then return Null
		if array.length = 1 then return array[0]

		Return array[(randRange(0, array.length-1))]
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
		'invalidate count
		entriesCount = -1

		return TRUE
	End Method


	Method Remove:int(obj:TGameObject)
		if obj.GetGuid() and entries.Remove(obj.GetGUID())
			'invalidate count
			entriesCount = -1

			return True
		endif

		return False
	End Method


	Method RemoveByGuid:int(guid:string)
		if guid and entries.Remove(guid)
			'invalidate count
			entriesCount = -1

			return True
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



Type TGameObject {_exposeToLua="selected"}
	Field id:Int = 0
	Field GUID:String
	Global LastID:Int = 0

	Method New()
		LastID:+1
		'assign a new id
		id = LastID

		'do NOT generate the GUID here already - as this would
		'call the "TGameObject.GenerateGUID" also for extended types
		'-> defer it to the GetGUID()-getter
	End Method


	Method GenerateGUID:string()
		return "gameobject-"+id
	End Method


	Method SetGUID:Int(GUID:String="")
		if GUID="" then GUID = GenerateGUID()
		self.GUID = GUID
	End Method

	
	Method GetID:Int() {_exposeToLua}
		Return id
	End Method


	Method GetGUID:String() {_exposeToLua}
		if GUID="" then SetGUID()
		Return GUID
	End Method


	'overrideable method for cleanup actions
	Method Remove()
	End Method
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
