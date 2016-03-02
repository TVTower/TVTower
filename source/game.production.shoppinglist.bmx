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


Type TShoppingListFilter
	Field requiredOwners:int[]
	Field forbiddenOwners:int[]
	Field scriptGUID:string

	
	Method DoesFilter:Int(shoppingList:TShoppingList)
		if not shoppingList then return False

		if scriptGUID
			if not shoppingList.script then return False
			if scriptGUID <> shoppingList.GetGUID() then return False
		endif

		'check if owner is one of the owners required for the filter
		'if not, filter failed
		if requiredOwners.length > 0
			local hasOwner:int = False
			for local owner:int = eachin requiredOwners
				if owner = shoppingList.owner then hasOwner = True;exit
			Next
			if not hasOwner then return False
		endif

		'check if owner is one of the forbidden owners
		'if so, filter fails
		if forbiddenOwners.length > 0
			for local owner:int = eachin forbiddenOwners
				if owner = shoppingList.owner then return False
			Next
		endif
	
	End Method
End Type