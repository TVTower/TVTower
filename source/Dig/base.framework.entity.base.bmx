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

	Copyright (C) 2002-now Ronny Otto, digidea.de

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
Import Brl.IntMap
Import Brl.StringMap
Import Brl.Map



Type TEntityCollection
	Field entriesID:TIntMap
	Field entriesGUID:TStringMap {nosave}
	Field entriesCount:int = -1

	Method Initialize:TEntityCollection()
		'call Remove() for all objects so they can unregister stuff
		'and tidy up in general
		If entriesID
			For local e:TEntityBase = EachIn entriesID.Values()
				e.RemoveFromCollection(self)
			Next
		EndIf

		If entriesID 
			entriesID.Clear()
			entriesID = Null
		EndIf
		If entriesGUID 
			entriesGUID.Clear()
			entriesGUID = Null
		EndIf

		entriesCount = -1

		return self
	End Method
	
	
	Method GetEntriesID:TIntMap()
		If not entriesID Then entriesID = new TIntMap
		Return entriesID
	End Method
	

	Method GetEntriesGUID:TStringMap()
		If not entriesGUID 
			entriesGUID = new TStringMap
			For local e:TEntityBase = EachIn GetEntriesID().Values()
				entriesGUID.Insert(e.GetGUID(), e)
			Next
		EndIf
		
		Return entriesGUID
	End Method


	Method GetByGUID:TEntityBase(GUID:String)
		Return TEntityBase(GetEntriesGUID().ValueForKey(GUID))
	End Method


	Method Get:TEntityBase(ID:Int)
		Return TEntityBase(GetEntriesID().ValueForKey(ID))
	End Method


	Method GetCount:Int()
		if entriesCount >= 0 then return entriesCount

		entriesCount = 0
		For Local base:TEntityBase = EachIn GetEntriesID().Values()
			entriesCount :+1
		Next
		return entriesCount
	End Method


	Method Add:int(obj:TEntityBase)
		?debug
		'In debug builds we remove first to ensure consistency.
		'Remove() throws an error if an element existed in 
		'neither none nor both entry-maps.
		Remove(obj)
		?
		
		GetEntriesID().Insert(obj.GetID(), obj)
		GetEntriesGUID().Insert(obj.GetGUID(), obj)
		entriesCount = -1
		return True
	End Method


	Method Remove:int(obj:TEntityBase)
		Local result:Int
		result :+ GetEntriesID().Remove(obj.GetID())
		result :+ GetEntriesGUID().Remove(obj.GetGUID())
		'invalidate count
		entriesCount = -1
	
		If result = 1
			DebugStop
			print "Invalid collection state: entriesID differed to entriesGUID. ID=" + obj.GetID() + "  GUID=~q" + obj.GetGUID()+"~q." 
			'Throw "Invalid collection state: entriesID differed to entriesGUID. ID=" + obj.GetID() + "  GUID=~q" + obj.GetGUID()+"~q." 
		ElseIf result = 0
			Return False
		Else
			Return True
		EndIf
	End Method


	'=== ITERATOR ===
	'The object returned by #ObjectEnumerator can be used with EachIn 
	'to iterate through the elements in the collection.
	Method ObjectEnumerator:TIntNodeEnumerator()
		Return GetEntriesID().Values()._enumerator
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
