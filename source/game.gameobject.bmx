SuperStrict
Import Brl.Map
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.data.bmx"

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
		if entries.Insert(obj.GetGUID(), obj)
			'invalidate count
			entriesCount = -1

			return TRUE
		endif

		return False
	End Method


	Method Remove:int(obj:TGameObject)
		if obj.GetGuid() and entries.Remove(obj.GetGUID())
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

		'create a new guid
		SetGUID("")
	End Method


	Method GetID:Int() {_exposeToLua}
		Return id
	End Method


	Method GetGUID:String() {_exposeToLua}
		Return GUID
	End Method


	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "gameobject-"+id
		self.GUID = GUID
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




'base effect class (eg. for newsevents, programmedata, adcontractbases)
Type TGameObjectEffect
	Field data:TData
	'constant value of TVTGameObjectEffect (CHANGETREND, TERRORISTATTACK, ...)
	Field effectTypes:int = 0
	Field _customEffectFunc:int(data:TData, params:TData)


	Method ToString:string()
		local name:string = data.GetString("name", "default")
		return "TGameObjectEffect ("+name+")"
	End Method


	Method SetEffectType:TGameObjectEffect(effectType :Int, enable:Int=True)
		If enable
			effectTypes :| effectType
		Else
			effectTypes :& ~effectType
		EndIf
		return self
	End Method


	Method HasEffectType:Int(effectType:Int)
		Return effectTypes & effectType
	End Method


	Method SetData(data:TData)
		self.data = data
	End Method


	Method GetData:TData()
		if not data then data = new TData
		return data
	End Method

	
	'call to handle/emit the effect
	Method Trigger:int(params:TData)
		if _customEffectFunc then return _customEffectFunc(GetData(), params)

		return EffectFunc(params)
	End Method


	'override this function in custom types
	Method EffectFunc:int(params:TData)
		print ToString()
		print "data: "+GetData().ToString()
		print "params: "+params.ToString()
	
		return True
	End Method
End Type



Type TGameObjectEffectCollection
	Field effects:TData
	
	Method GetList:TList(trigger:string)
		if not effects then return Null
		return TList(effects.Get(trigger.ToLower()))
	End Method

	
	'checks if an certain effect type is existent
	Method HasEffectType:int(trigger:string, effectType:int) {_exposeToLua}
		local list:TList = GetList(trigger)
		if not list then return false
		
		For local effect:TGameObjectEffect = eachin list
			if effect.HasEffectType(effectType) then return True
		Next
		return False
	End Method
	

	'checks if an effect was already added before
	Method HasEffect:int(trigger:string, effect:TGameObjectEffect)
		if not effect then return False
		local list:TList = GetList(trigger)
		if not list then return False

		return list.contains(effect)
	End Method


	Method AddEffect:int(trigger:string, effect:TGameObjectEffect)
		'skip if already added
		If HasEffect(trigger, effect) then return False

		'add effect
		local list:TList = GetList(trigger)
		if not list
			list = CreateList()
			if not effects then effects = New TData
			effects.Add(trigger.ToLower(), list)
		else
			'skip if already added
			if list.Contains(effect) then return False
		endif

		list.AddLast(effect)
		
		return True
	End Method


	Method RemoveEffect:int(trigger:String, effect:TGameObjectEffect)
		local l:TList = GetList(trigger)
		if not l then return false

		return l.Remove(effect)
	End Method


	Method RunEffects:int(trigger:string, effectParams:TData)
		local l:TList = GetList(trigger)
		if not l then return 0
		
		For local eff:TGameObjectEffect = eachin l
			eff.Trigger(effectParams)
		Next

		return l.Count()
	End Method
End Type