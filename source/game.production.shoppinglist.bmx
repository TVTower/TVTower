SuperStrict
Import "game.production.script.bmx"
Import "game.programme.programmeperson.base.bmx"


Type TShoppingListCollection Extends TGameObjectCollection
	Global _instance:TShoppingListCollection
	
	'override
	Function GetInstance:TShoppingListCollection()
		if not _instance then _instance = new TShoppingListCollection
		return _instance
	End Function


	Method GetShoppingListsByScript:TShoppingList[](script:TScript)
		local result:TShoppingList[]
		For local sl:TShoppingList = EachIn self
			if sl.script = script then result :+ [sl]
		Next
		return result
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetShoppingListCollection:TShoppingListCollection()
	Return TShoppingListCollection.GetInstance()
End Function




Type TShoppingList extends TOwnedGameObject
	Field script:TScript

	Field directors:TProgrammePersonBase[]
	Field hosts:TProgrammePersonBase[]
	Field reporters:TProgrammePersonBase[]
	Field starActors:TProgrammePersonBase[]
	Field actors:TProgrammePersonBase[]
	Field musicians:TProgrammePersonBase[]

	Field coulisseType1Id:string
	Field coulisseType2Id:string
	Field coulisseType3Id:string


	Method Init:TShoppingList(owner:int, script:TScript)
		self.script = script
		SetOwner(owner)
		return self
	End Method
End Type