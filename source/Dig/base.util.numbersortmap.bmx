Rem
	====================================================================
	NumberSortMap
	====================================================================


	====================================================================
	LICENCE: zlib/libpng

	Copyright (C) 2014-2015 Manuel Vögele

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
Import Brl.LinkedList


Type TNumberSortMap
	Field Content:TList = CreateList()


	Method Add(_key:String, _value:Float)
		Content.AddLast(TKeyValueNumber.Create(_key, _value))
	End Method


	Method Sort(ascending:Int = true)
		SortList (Content, ascending)
	End Method


	Method NumberAtIndex:Float( index:Int )
		Return TKeyValueNumber(Content.ValueAtIndex(index)).Value
	End Method
End Type



Type TKeyValueNumber
	Field Key:String
	Field Value:Float


	Function Create:TKeyValueNumber(_key:String, _value:Float)
		Local obj:TKeyValueNumber = new TKeyValueNumber
		obj.Key = _key
		obj.Value = _value
		Return obj
	End Function


	Method Compare:Int(other:Object)
		Local s:TKeyValueNumber = TKeyValueNumber(other)
		' Object not a TKeyValueNumber: define greater than any TKeyValueNumber
		If Not s Then Return 1

		'not the best for floats because returned value is int
		If Value < s.Value
			Return -1
		Else If Value > s.Value
			Return 1
		EndIf

		Return Super.Compare(other)
	End Method
End Type
