Type TGameObject {_exposeToLua="selected"}
	Field id:Int = 0 	{_exposeToLua}
	Global LastID:Int = 0

	Method New()
		LastID:+1
		'assign a new id
		id = LastID
	End Method


	Method GetID:Int() {_exposeToLua}
		Return id
	End Method


	'overrideable method for cleanup actions
	Method Remove()
	End Method
End Type




Type TOwnedGameObject Extends TGameObject {_exposeToLua="selected"}
	Field owner:Int = 0


	Method SetOwner:Int(owner:Int=0) {_exposeToLua}
		Self.owner = owner
	End Method


	Method GetOwner:Int() {_exposeToLua}
		Return owner
	End Method
End Type


Type TNamedGameObject Extends TOwnedGameObject {_exposeToLua="selected"}

	Method GetTitle:String() abstract
End Type