Rem
	====================================================================
	THelper - various helper functions
	====================================================================

	Class containing various helper functions.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

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
?Not bmxng
'using custom to have support for const/function reflection
Import "external/reflectionExtended/reflection.bmx"
'Import BRL.Reflection
?bmxng
'ng has it built-in!
Import BRL.Reflection
?
Import BRL.Retro
Import "base.util.input.bmx" 		'Mousemanager
Import "base.util.rectangle.bmx"	'TRectangle
Import "base.util.mersenne.bmx"
Import "base.util.math.bmx"

'collection of useful functions
Type THelper
	Function ATanFunction:Float(p:Float, modifier:float=1.0)
		local scale:float = 1.0 / (ATan(1.0 * modifier) / 90.0)
		return scale * ATan(p * modifier) / 90.0
	End Function


	'the logistic function is a fast-to-slow-growing function
	'higher values are more likely returning nearly the maximum value
	'http://de.wikipedia.org/wiki/Logistische_Funktion
	'returns a value between 0-maximumValue subtracted by "fZero"
	Function logisticFunction:Float(value:Float, maximumValue:Float, proportionalityFactor:Float = 1.0, fZero:Float=0.5)
		Rem
			formula:
			f(t) =                 1
					G * ------------------------------
						1 + e^(-k*G*t) * (  G        )
										 (----   - 1 )
										 (f(0)       )

			e = euler value ("exp" in coding langugaes)
			G = maximumValue
			k = proportionalityFactor
			t = value
			f(0) = fZero
		End Rem

		return maximumValue * 1.0/(1.0 + exp(-proportionalityFactor*maximumValue*value) * (maximumValue/fZero - 1))
	End Function


	'returns a value between 0-1.0 for a given percentage value (0-1.0)
	Function LogisticalInfluence:Float(percentage:Float, proportionalityFactor:Float= 0.11)
		return 1.0 - logisticFunction(percentage*100, 1.0, proportionalityFactor, 0.001)
	End function
	

	Function LogisticalInfluence_Tangens:Float(percentage:Float, strength:Float=1.0, addRandom:int=True)
		'sinus is there for some "randomness"
		'2.5 = "base strength" so 100% will reach "1.0"
		return Min(1.0, Max(0.0, tanh(percentage*(2.5*strength)) + addRandom * abs(0.03*sin(95*percentage))))
	End Function
	

	'higher strength values have a stronger decrease per percentage
	'higher strength can lead to Value(0.5) > Value(0.7)
	'higher percentages return a higher influence (in 100% = out ~100%)
	'value growth changes at bei 1/strength!!
	'-> we cut "used" percentage" so 100% = 1/strength
	Function LogisticalInfluence_Euler:Float(percentage:Float, strength:Float=1.0, addRandom:int=True)
		'sinus is there for some "randomness"
		return 1 - ( exp(-strength * percentage) + addRandom * abs(0.01 * sin(155*percentage)) )
	End Function


	Function CountMap:int(map:TMap)
		local c:int = 0
		for local o:object = EachIn map.values()
			c :+ 1
		next
		return c
	End Function


	Function ShuffleList:TList(list:TList)
		Local objArr:Object[] = list.ToArray()
		Local j:Int
		Local o:Object
		'loop over all indexes and switch each of them with a random
		'target position
		For Local i:Int = objArr.length-1 To 0 Step -1
			j = RandRange(0, objArr.length-1)
			o = objArr[i]
			objArr[i] = objArr[j]
			objArr[j] = o
		Next
		return new TList.FromArray(objArr)
	End Function
	 

	'returns whether the mouse is within the given rectangle coords
	Function MouseIn:int(x:Int,y:Int, w:Int,h:Int)
		return IsIn(Int(MouseManager.x), Int(MouseManager.y), x,y,w,h)
	End Function


	'returns whether the mouse is within the given rectangle
	Function MouseInRect:int(rect:TRectangle)
		return IsIn(int(MouseManager.x), int(MouseManager.y), int(rect.position.x), int(rect.position.y), int(rect.dimension.x), int(rect.dimension.y))
	End Function


	'returns whether two pairs of "start-end"-values intersect
	Function DoMeet:int(startA:float, endA:float, startB:float, endB:float)
		'DoMeet - 4 possibilities - but only 2 for not meeting
		' |--A--| .--B--.    or   .--B--. |--A--|
		return  not (Max(startA,endA) < Min(startB,endB) or Min(startA,endA) > Max(startB, endB) )
	End function


	'returns whether the given x,y coordinate is within the given rectangle coords
	'checks are done on _int_-base (to avoid floating point inaccuracies)
	Function IsIn:Int(x:Int, y:Int, rectx:Int, recty:Int, rectw:Int, recth:Int)
		If x >= rectx And x<rectx+rectw And..
		   y >= recty And y<recty+recth
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
	Global IntMapTypeID:TTypeId=TTypeId.ForObject(new TIntMap)

	'clones the given object
	'function is calling itself recursively for each property
	'returns the cloned object
	Function CloneObject:object(obj:object, skipFields:string = "")
		'clone code is based on the work of "Azathoth"
		'http://www.blitzbasic.com/codearcs/codearcs.php?code=2132

		skipFields = " " + skipFields.toLower() + " "

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
			local clone:object = objTypeID.NewArray(size)
			'something failed, return a null object
			If not clone then return Null

			'clone each element of the array
			For Local i:int=0 Until size
				'run recursive clone for arrays, objects and strings
				If objTypeID.ElementType().ExtendsType(ArrayTypeId) or objTypeID.ElementType().ExtendsType(StringTypeId) or objTypeID.ElementType().ExtendsType(ObjectTypeId)
					objTypeID.SetArrayElement(clone, i, CloneObject(objTypeID.GetArrayElement(obj, i)))
				Else
					objTypeID.SetArrayElement(clone, i, objTypeID.GetArrayElement(obj, i))
				EndIf
			Next

			return clone
		EndIf


		Local clone:object

		'use the objects specific clone method instead of our
		'generic approach
		'call a method "CloneObject:Int(original:obj)"
		Local mth:TMethod = objTypeID.FindMethod("CloneObject")
		If mth
			clone = objTypeID.NewObject()
			mth.Invoke(clone, [obj])
		Else
		
			'=== LISTS ===
			If objTypeID.ExtendsType(ListTypeID)
				local list:TList = CreateList()
				For local entry:object = EachIn TList(obj)
					list.AddLast( CloneObject(entry) )
				Next
				return list
			EndIf

			
			'=== TMAPS ===
			If objTypeID.ExtendsType(MapTypeID)
				local map:TMap = CreateMap()
				For local key:string = EachIn TMap(obj).Keys()
					map.Insert(key, CloneObject(TMap(obj).ValueForKey(key)) )
				Next
				return map
			EndIf	

			'=== TINTMAPS ===
			If objTypeID.ExtendsType(IntMapTypeID)
				local map:TIntMap = new TIntMap
				For local key:TIntKey = EachIn TMap(obj).Keys()
					map.Insert(key.value, CloneObject(TIntMap(obj).ValueForKey(key.value)) )
				Next
				return map
			EndIf	


			'=== OBJECTS ===
			'create a new instance of the objects type
			'Local clone:object = New obj
			clone = objTypeID.NewObject()

			'loop over all fields of the object
			For Local fld:TField=EachIn objTypeID.EnumFields()
				Local fldId:TTypeId=fld.TypeId()

				'ignore this field (eg. an auto-populated ID-field)
				if skipFields.find(" "+fld.name().toLower()+" ") >= 0 then continue

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
		EndIf

		'inform the clone that it got cloned
		'call a method "onGotCloned:Int(original:obj)"
		mth = objTypeID.FindMethod("onGotCloned")
		If mth then mth.Invoke(clone, [obj])

		Return clone
	End Function


	'assigns field properties of one object to another
	'no deep cloning is done but "references" are copied
	Function TakeOverObjectValues:object(source:object, target:object var, skipFields:string="")
		If source = Null
			target = null
			return null
		EndIf

		skipFields = " " + skipFields.toLower() + " "

		'to access properties we need a TTypeID of the object
		Local srcTypeID:TTypeId=TTypeId.ForObject(source)
		Local tarTypeID:TTypeId=TTypeId.ForObject(target)
		if not srcTypeID or not tarTypeID then return target

		'loop over all fields of the object
		'if the target has the same or compatible field, assign it
		'(reference, no deep clone!)
		Local fldId:TTypeId, tarFldId:TTypeID
		Local tarFld:TField
		For Local fld:TField = EachIn srcTypeID.EnumFields()
			fldId = fld.TypeId()

			'ignore this field (eg. an auto-populated ID-field)
			if skipFields.find(" "+fld.name().toLower()+" ") >= 0 then continue

			tarFld = tarTypeID.FindField( fld.name() )
			if tarFld
				tarFldId = tarfld.TypeId()
				if tarFldID = fldId or tarFldId.ExtendsType(fldId)
					tarFld.Set(target, fld.Get(source))
				endif
			endif
		Next
		Return target
	End Function
End Type