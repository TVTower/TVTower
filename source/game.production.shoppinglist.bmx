SuperStrict
Import "game.production.script.bmx"
Import "game.programme.programmeperson.base.bmx"
Import "game.production.productionconcept.bmx"


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
	Field productionConcept:TProductionConcept

	Method Init:TShoppingList(owner:int, script:TScript)
		self.script = script

		SetOwner(owner)
		return self
	End Method


	Method SetProductionConcept(productionConcept:TProductionConcept)
		self.productionConcept = productionConcept
	End Method


	Method CanStartAProduction:int()
		if not productionConcept then return False

		return productionConcept.IsComplete()
	End Method
End Type