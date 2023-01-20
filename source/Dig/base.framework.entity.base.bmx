Rem
	====================================================================
	Basic entity class
	====================================================================

	Entities are objects in your game / app.

	The collection contains various entity-types depending on whether
	the object needs to move or is a static one.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2018 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict
Import Brl.Map



Type TEntityCollection
	Field entriesID:TIntMap
	Field entries:TMap = CreateMap()
	Field entriesCount:int = -1
	Field _entriesMapEnumerator:TNodeEnumerator {nosave}

	Method Initialize:TEntityCollection()
		'call Remove() for all objects so they can unregister stuff
		'and tidy up in general
		For local e:TEntityBase = EachIn entries.Values()
			e.RemoveFromCollection(self)
		Next

		entriesID.Clear()
		entries.Clear()
		entriesCount = -1

		return self
	End Method
	
	
	Method CreateEntriesID()
		If not entriesID 
			entriesID = new TIntMap
		Else
			entriesID.Clear()
		EndIf

		For local e:TEntityBase = EachIn entries.Values()
			entriesID.Insert(e.GetID(), e)
		Next
	End Method


	Method GetByGUID:TEntityBase(GUID:String)
		Return TEntityBase(entries.ValueForKey(GUID))
	End Method


	Method Get:TEntityBase(ID:Int)
		if not entriesID Then CreateEntriesID()

		Return TEntityBase(entriesID.ValueForKey(ID))
	End Method


	Method GetCount:Int()
		if entriesCount >= 0 then return entriesCount

		entriesCount = 0
		For Local base:TEntityBase = EachIn entries.Values()
			entriesCount :+1
		Next
		return entriesCount
	End Method


	Method Add:int(obj:TEntityBase)
		if not entriesID Then CreateEntriesID()
		entriesID.Insert(obj.GetID(), obj)
		entries.Insert(obj.GetGUID(), obj)
		entriesCount = -1
		return True
	End Method


	Method Remove:int(obj:TEntityBase)
		Local objID:Int = obj.GetID()
		if entriesID and entriesID.Remove(objID)
			entries.Remove(obj.GetGUID())
			'invalidate count
			entriesCount = -1
			return True
		ElseIf entries.Remove(obj.GetGUID())
			entriesID.Remove(obj.GetID())
			'invalidate count
			entriesCount = -1
			Return True
		endif

		return False
	End Method


	'=== ITERATOR ===
	'for "EachIn"-support

	'Set iterator to begin of array
	Method ObjectEnumerator:TEntityCollection()
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
		'Return entries.ValueAtIndex(_iteratorPos-1)
	End Method
End Type



Type TEntityBase {_exposeToLua="selected"}
	Field id:Int = 0	{_exposeToLua}
	Field GUID:String	{_exposeToLua}
	Global LastID:Int = 0


	Method New()
		LastID :+ 1
		'assign the new id
		id = LastID

		'create a new guid
		SetGUID("")
	End Method


	Method GetID:Int() {_exposeToLua}
		Return id
	End Method


	Method GetGUID:String() {_exposeToLua}
		if GUID="" then GUID = GenerateGUID()
		Return GUID
	End Method


	Method SetGUID:Int(GUID:String="")
		if GUID="" then GUID = GenerateGUID()
		self.GUID = GUID
	End Method


	Method GenerateGUID:string()
		return "entitybase-"+id
	End Method


	'overrideable method for cleanup actions
	Method Remove:Int()
		Return True
	End Method


	'overrideable method for cleanup actions
	Method RemoveFromCollection:Int(collection:object = null)
		Return True
	End Method
End Type