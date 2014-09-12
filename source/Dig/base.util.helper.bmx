Rem
	====================================================================
	THelper - various helper functions
	====================================================================

	Class containing various helper functions.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2014 Ronny Otto, digidea.de

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
Import BRL.Reflection
Import BRL.Retro
Import "base.util.input.bmx" 		'Mousemanager
Import "base.util.rectangle.bmx"	'TRectangle
Import "base.util.math.bmx"

'collection of useful functions
Type THelper
	'check whether a checkedObject equals to a limitObject
	'1) is the same object
	'2) is of the same type
	'3) is extended from same type
	Function ObjectsAreEqual:int(checkedObject:object, limit:object)
		'one of both is empty
		if not checkedObject then return FALSE
		if not limit then return FALSE
		'same object
		if checkedObject = limit then return TRUE

		'check if both are strings
		if string(limit) and string(checkedObject)
			return string(limit) = string(checkedObject)
		endif

		'check if classname / type is the same (type-name given as limit )
		if string(limit)<>null
			local typeId:TTypeId = TTypeId.ForName(string(limit))
			'if we haven't got a valid classname
			if not typeId then return FALSE
			'if checked object is same type or does extend from that type
			if TTypeId.ForObject(checkedObject).ExtendsType(typeId) then return TRUE
		endif

		return FALSE
	End Function


	'returns whether the mouse is within the given rectangle coords
	Function MouseIn:int(x:float,y:float,w:float,h:float)
		return IsIn(MouseManager.x, MouseManager.y, x,y,w,h)
	End Function


	'returns whether the mouse is within the given rectangle
	Function MouseInRect:int(rect:TRectangle)
		return IsIn(MouseManager.x, MouseManager.y, rect.position.x,rect.position.y,rect.dimension.x, rect.dimension.y)
	End Function


	'returns whether two pairs of "start-end"-values intersect
	Function DoMeet:int(startA:float, endA:float, startB:float, endB:float)
		'DoMeet - 4 possibilities - but only 2 for not meeting
		' |--A--| .--B--.    or   .--B--. |--A--|
		return  not (Max(startA,endA) < Min(startB,endB) or Min(startA,endA) > Max(startB, endB) )
	End function


	'returns whether the given x,y coordinate is within the given rectangle coords
	Function IsIn:Int(x:Float, y:Float, rectx:Float, recty:Float, rectw:Float, recth:Float)
		If x >= rectx And x<=rectx+rectw And..
		   y >= recty And y<=recty+recth
			Return 1
		Else
			Return 0
		End If
	End Function


	Function GetTweenedPoint:TVec2D(currentPoint:TVec2D, oldPoint:TVec2D, tween:Float, avoidShaking:int=TRUE)
		if avoidShaking
			return new TVec2D.Init(..
				 MathHelper.SteadyTween(oldPoint.x, currentPoint.x, tween),..
				 MathHelper.SteadyTween(oldPoint.y, currentPoint.y, tween)..
			   )
		else
			return new TVec2D.Init(..
				 MathHelper.Tween(oldPoint.x, currentPoint.x, tween),..
				 MathHelper.Tween(oldPoint.y, currentPoint.y, tween)..
			   )
		endif
	End Function



	Global ListTypeID:TTypeId=TTypeId.ForObject(new TList)
	Global MapTypeID:TTypeId=TTypeId.ForObject(new TMap)

	'clones the given object
	'function is calling itself recursively for each property
	'returns the cloned object
	Function CloneObject:object(obj:object)
		'clone code is based on the work of "Azathoth"
		'http://www.blitzbasic.com/codearcs/codearcs.php?code=2132

		'skip cloning nothing
		If obj = Null Then Return Null

		'to access properties we need a TTypeID of the object
		Local objTypeID:TTypeId=TTypeId.ForObject(obj)


		'=== STRINGS ===
		If objTypeID.ExtendsType(StringTypeId) then return String(obj)


		'=== ARRAYS ===
		If objTypeID.ExtendsType(ArrayTypeId)
			'if an array does not contain elements, the reflection
			'cannot recognize which type the array contains (Null[])

			'accessing this "null[]"-arrays would lead to a thrown
			'error - so we need "try" to catch the exception.
			'Thanks to Brucey's persistence.mod (doing it similar)

			'objects name might be TMyType[] - remove the []-part
			Local objTypeName:string = objTypeID.name()[..objTypeID.name().length - 2]
			Local size:Int
			Try
				size = objTypeID.ArrayLength(obj)
			Catch e$
				objTypeName = "Object"
				size = 0
			End Try
			
			'if the object does not contain things in that array, the
			'copy wont need it too
			If size = 0 then return Null

			'create new array
			local clone:object = objTypeID.NewArray(objTypeID.ArrayLength(obj))
			'something failed, return a null object
			If not clone then return Null

			'clone each element of the array
			For Local i:int=0 Until objTypeID.ArrayLength(obj)
				'run recursive clone for arrays, objects and strings
				If objTypeID.ElementType().ExtendsType(ArrayTypeId) or objTypeID.ElementType().ExtendsType(StringTypeId) or objTypeID.ElementType().ExtendsType(ObjectTypeId)
					objTypeID.SetArrayElement(clone, i, CloneObject(objTypeID.GetArrayElement(obj, i)))
				Else
					objTypeID.SetArrayElement(clone, i, objTypeID.GetArrayElement(obj, i))
				EndIf
			Next

			return clone
		EndIf


		'=== LISTS ===
		If objTypeID.ExtendsType(ListTypeID)
			local list:TList = CreateList()
			For local entry:object = EachIn TList(obj)
				list.AddLast(entry)
			Next
			return list
		EndIf
		
		'=== TMAPS ===
		'do maps BEFORE arrays... as maps extend arrays
		If objTypeID.ExtendsType(MapTypeID)
			local map:TMap = CreateMap()
			For local key:string = EachIn TMap(obj).Keys()
				map.Insert(key, TMap(obj).ValueForKey(key))
			Next
			return map
		EndIf	

		'=== OBJECTS ===
		'create a new instance of the objects type
		Local clone:object = New obj

		'loop over all fields of the object
		For Local fld:TField=EachIn objTypeID.EnumFields()
			Local fldId:TTypeId=fld.TypeId()

			'only clone non-null-fields and if not explicitely forbidden
			If fld.Get(obj) And fld.MetaData("NoClone") = Null
				'if explizitely stated, clone referenceable objects by
				'reusing their reference, else deep clone it
				If fld.MetaData("CloneUseReference")
					fld.Set(clone, fld.Get(obj))
				Else
					fld.Set(clone, CloneObject(fld.Get(obj)))
				EndIf
			EndIf
		Next

		'inform the clone that it got cloned
		'call a method "onGotCloned:Int(original:obj)"
		Local mth:TMethod = objTypeID.FindMethod("onGotCloned")
		If mth then mth.Invoke(clone, [obj])

		Return clone
	End Function	
End Type