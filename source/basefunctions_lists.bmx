SuperStrict

Public

Rem
ObjectList created by Kris Kelly (Perturbatio) Dec 2005
purpose: faster access to a list of objects with less mem usage
it's performance is comparable to a TList when using a small number of strings
but when you are using a large amount, it is much better (and uses less memory).

When invoking the create method, you can specify the StepSize, this is the amount that
the Items Array will be increased by each time it is in danger of running out of space.
It is faster to do it in large blocks than in hundreds of little ones.
EndRem

Type TObjectList
	Field Items:Object[]
	Field _Size:Int = 0 'DO NOT MANUALLY MODIFY THIS!!!
	Field StepSize:Int

	Method AddFirst(val:Object)
		Local i:Int

		'grow Items array by 1
		'Items = Items[..Items.Length + 1]
		_Size:+1
		'resize in bulk
		If Items.Length < _Size Then Items = Items[.._Size+StepSize]


		'shift Items to the rightt, overwriting val
		For i = 1 To _Size-1 'Items.Length - 1
			Items[i] = Items[i - 1]
		Next

		Items[0] = val
		'no need to return anything here since we know it was added at 0
	End Method


	Method AddLast:Int(val:Object)
		'grow Items array by 1
		'Items = Items[..Items.Length + 1]
		_Size:+1
		'resize in bulk
		If Items.Length < _Size Then Items = Items[.._Size+StepSize]

		'set the last index to val
		'Items[Items.Length - 1] = val

		Items[_Size-1] = val

		Return _Size 'Items.Length - 1 'return the index it was added at
	End Method


	'return the entire list as a concatenated string with optional delimiter
	'because base objects have ToString, cannot override with different parameters
	Method ToDelimString:String(Delim:String = "")
		Local result:String=""
		Local i:Int

		For i = 0 To _Size-2
			result:+Items[i].ToString() + Delim
		Next
		result:+ Items[_Size-1].ToString()

		Return result
	End Method


	Method ToString:String()
		Return ToDelimString() 'just call ToDelimString with no parameters
	End Method

	'You could just reference the field _Size (which is what is done throughout the code),
	'but that could result in an unsafe type if you
	Method Count:Int()
		Return _Size
	End Method


	'return the first index where the list contains val, else return -1
	Method Contains:Int(val:Object)
		Local i:Int

		For i = 0 To _Size-1
			If val = Items[i] Then Return i
		Next

		Return -1
	End Method


	Function FromObjectArray:TObjectList(val:Object[])
		Local tempList:TObjectList = TObjectList.Create()

		Try
			tempList.Items = val
		Catch err:String
			RuntimeError("Error when converting from Object Array to TObjectList, error: ~n"+err$)
			Return Null
		End Try

		Return tempList
	End Function

Rem
	Function FromString:TObjectList(val:String, Delim:String)
		Local tempList:TObjectList = TObjectList.Create()
		Local currentChar : String = ""
		Local count : Int = 0
		Local TokenStart : Int = 0
			If Delim.Length <0 Or Delim.Length > 1 Then Return Null

			If Len(Delim)<>1 Then Return Null

			val = Trim(val)

			For count = 0 Until Len(val)
				If val[count..count+1] = delim Then
					tempList.AddLast(val[TokenStart..Count])
					TokenStart = count + 1
				End If
			Next
			tempList.AddLast(val[TokenStart..Count])

		Return tempList
	End Function
EndRem

	'if AutoAddToEnd is true then if the index specified is greater than size, use AddLast
	Method Insert:Int(val:Object, index:Int, AutoAddToEnd:Int = False)
		Local i:Int

		'If index is out of range, Return False
		If index < 0 Then Return False
		If index > _Size Then
			If Not AutoAddToEnd Then
				Return False
			Else
				AddLast(val)
				Return True
			EndIf
		EndIf

		'if the index is equal to Size then addlast
		If index = _Size Then
			AddLast(val)
			Return True
		EndIf

		'resize Items
		'Items = Items[..Items.Length]
		_Size:+1
		'resize in bulk
		If Items.Length < _Size Then Items = Items[.._Size + StepSize]


		'shift Items to the right from index
		For i = _Size-1 To index+1 Step -1
			Items[i] = Items[i - 1]
			'Print "index "+ i + " " + items[i]
		Next

		'then insert val
		Items[index] = val
		Return True
	End Method


	Method RemoveByIndex:Int(index:Int)
		Local i:Int

		'shift Items to the left, overwriting index
		For i = index To _Size - 2
			Items[i] = Items[i + 1]
		Next

		'shrink Items by 1
		'Items = Items[..Items.Length]
		_Size:-1
		'if the length of items is at least (2 *StepSize) larger than Size, resize the array
		'this should help prevent the size from getting out of control but keep it reasonably fast
		If _Size < Items.Length - (StepSize * 2) Then Items = Items[.._Size]
		If _Size < 0 Then _Size = 0
		'null the end one
		Items[_Size] = Null
	End Method


	Method RemoveByObject:Int(val:Object, RemoveAll:Int = False)
		Local i:Int

		i = Contains(val)
		While i > -1

			RemoveByIndex(i)
			If Not RemoveAll Then Exit
			i = Contains(val)

		Wend

		Return True
	End Method


	Method Clear()
		Items = Items[..0]
		_Size = 0
	End Method


	Method ToArray:Object[]()
		Return Items[.._Size-1]
	End Method


	Method ToList(List:TList Var)
		For Local s:Object = EachIn items
			List.AddLast(s)
		Next
	End Method


	Method GetStepSize:Int()
		Return StepSize
	End Method

	Method SetStepSize(val:Int)
		If val < 1 Then val = 1 'don't allow negative values
		StepSize = val
	End Method


	Method Sort()
		'Items[.._Size].Sort() 'sort causes a problem with null objects, so have disabled this just now.
	End Method


	Method Free()
		TObjectList.Destroy(Self)
	End Method

	'returns true if swap occurred
	Method SwapByIndex:Int(FirstIndex:Int, SecondIndex:Int)
		If FirstIndex<0 Or FirstIndex > _Size-1 Or SecondIndex<0 Or SecondIndex > _Size-1 Then Return False 'if out of bounds then return false
		Local tempObject:Object

		tempObject = items[FirstIndex]
		items[FirstIndex] = items[SecondIndex]
		items[SecondIndex] = tempObject
		Return True

	End Method

	'returns true if swap occurred
	Method SwapByVal:Int(FirstObject:Object, SecondObject:Object)
		If FirstObject = Null Or SecondObject=Null Then Return False
		Local tempObject:Object
		Local FirstIndex:Int, SecondIndex:Int

		FirstIndex = Contains(FirstObject)
		SecondIndex = Contains(SecondObject)

		If FirstIndex > -1 And SecondIndex > -1 Then
			tempObject = items[FirstIndex]
			items[FirstIndex] = items[SecondIndex]
			items[SecondIndex] = tempObject
			Return True
		EndIf

		Return False
	End Method


	Function Destroy(List:TObjectList)
		List.Clear()
		List = Null
		GCCollect
	End Function


	Function Create:TObjectList(StepSize:Int = 10)
		Local tempList:TObjectList = New TObjectList
		tempList.StepSize = StepSize
		Return tempList
	End Function
End Type