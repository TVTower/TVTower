SuperStrict


Type TObjectList

	Field version:Int

	Field data:Object[16]
	Field size:Int

	Field dirty:Int

	Method _ensureCapacity(newSize:Int)
		If newSize >= data.length Then
			data = data[.. newSize * 3 / 2 + 1]
		End If
	End Method

	Method Clear()
		For Local i:Int = 0 Until size
			data[i] = Null
		Next
		size = 0
		version :+ 1
		dirty = False
	End Method

	Method IsEmpty:Int()
		Return size = 0
	End Method

	Method AddFirst(value:Object)
		Compact()

		If size Then
			_ensureCapacity(size + 1)
			ArrayCopy(data, 0, data, 1, size)
		End If

		data[0] = value
		size :+ 1
		version :+ 1
	End Method

	Method AddLast(value:Object)
		Compact()

		_ensureCapacity(size + 1)

		data[size] = value
		size :+ 1
		version :+ 1
	End Method

	Method Contains:Int(obj:Object)
		For Local i:Int = 0 Until size
			If data[i] = obj Then
				Return True
			End If
		Next
	End Method

	Method First:Object()
		If size Then
			Compact()

			Return data[0]
		End If
	End Method

	Method Last:Object()
		If size Then
			Compact()

			Return data[size - 1]
		End If
	End Method

	Method RemoveFirst:Object()
		If size Then
			Compact()

			If size Then
				Local value:Object = data[0]
				ArrayCopy(data, 1, data, 0, size - 1)
				size :- 1
				data[size] = Null
				version :+ 1
				Return value
			End If
		End If
	End Method

	Method RemoveLast:Object()
		If size Then
			Compact()

			If size Then
				Local value:Object = data[size - 1]
				size :- 1
				data[size] = Null
				version :+ 1
				Return value
			End If
		End If
	End Method

	Method ValueAtIndex:Object(index:Int)
		Compact()

		Assert index>=0 Else "Object index must be positive"
		If index >= size Then RuntimeError "List index out of range"

		Return data[index]
	End Method

	Method Count:Int()
		Compact()

		Return size
	End Method

	Method Remove:Int(value:Object, removeAll:Int = False, compactOnRemove:Int = True)
		If size Then
			Local modified:Int
			For Local i:Int = 0 Until size
				If data[i] = value Then
					data[i] = Null
					modified = True
					If Not removeAll Then
						Exit
					End If
				End If
			Next

			If modified Then
				dirty = True
				If compactOnRemove Then
					Compact()
				End If

				version :+ 1
			End If

			Return modified
		End If

	End Method

	Method Compact()
		If dirty Then
			Local offset:Int
			For Local i:Int = 0 Until size
				Local value:Object = data[i]

				If value Then
					data[offset] = value
					offset :+ 1
				End If
			Next
			size = offset
			dirty = False
			version :+ 1
		End If
	End Method

	Method Swap(list:TObjectList)

	End Method

	Method Copy:TObjectList()
		Compact()

		Local list:TObjectList = New TObjectList

		For Local i:Int = 0 Until size
			list.AddLast(data[i])
		Next

		Return list
	End Method

	Method Reverse()
		Compact()

		If size Then
			Local leftOffset:Int
			Local rightOffset:Int = size - 1

			While leftOffset < rightOffset
				Local temp:Object = data[leftOffset]
				data[leftOffset] = data[rightOffset]
				data[rightOffset] = temp

				leftOffset :+ 1
				rightOffset :- 1
			Wend

		End If
	End Method

	Method Reversed:TObjectList()
		Compact()

		Local list:TObjectList = New TObjectList

		Local i:Int = size - 1

		While i >= 0
			list.AddLast(data[i])
			i :- 1
		Wend

		Return list
	End Method

	Method _removeAt(index:Int)
		data[index] = Null
		dirty = True
		version :+ 1
	End Method

	Method ObjectEnumerator:TObjectListEnumerator()
		Local enumeration:TObjectListEnumerator=New TObjectListEnumerator
		enumeration.list = Self
		Return enumeration
	End Method

	Method ToArray:Object[]()
		Compact()

		Local arr:Object[] = New Object[size]
		If size Then
			ArrayCopy(data, 0, arr, 0, size)
		End If
		Return arr
	End Method

	Function FromArray:TObjectList(arr:Object[])
		Local list:TObjectList = New TObjectList
		For Local i:Int = 0 Until arr.length
			list.AddLast arr[i]
		Next
		Return list
	End Function

	Method Sort(ascending:Int=True, compareFunc:Int( o1:Object,o2:Object ))
		If size < 2 Then
			Return
		End If

		Local ccsgn:Int = -1
		If ascending Then
			ccsgn = 1
		End If

		Compact()

		_sort(data, 0, size - 1, compareFunc, ccsgn)

	End Method

	Function _sort(data:Object[], low:Int, high:Int, compareFunc:Int( o1:Object,o2:Object ), ccsgn:Int)
		If low < high Then
			Local index:Int = _partition(data, low, high, compareFunc, ccsgn)
			_sort(data, low, index - 1, compareFunc, ccsgn)
			_sort(data, index + 1, high, compareFunc, ccsgn)
		End If
	End Function

	Function _partition:Int(data:Object[], low:Int, high:Int, compareFunc:Int( o1:Object,o2:Object ), ccsgn:Int)
		Local pivot:Object = data[high]
		Local index:Int = low - 1

		For Local n:Int = low Until high
			If compareFunc(data[n], pivot) * ccsgn < 0 Then
				index :+ 1
				Local tmp:Object = data[index]
				data[index] = data[n]
				data[n] = tmp
			End If
		Next

		Local tmp:Object = data[index + 1]
		data[index + 1] = data[high]
		data[high] = tmp

		Return index + 1
	End Function

	Function _CompareObjects:Int( o1:Object,o2:Object )
		Return o1.Compare( o2 )
	End Function

End Type

Type TObjectListEnumerator

	Field list:TObjectList
	Field index:Int = 0
	Field lastVersion:Int

	Method HasNext:Int()
		Local result:Int = index < list.size

		' reached the end of the iteration
		If Not result Then
			list.Compact()
		End If

		Return result
	End Method

	Method NextObject:Object()
		Local value:Object = list.data[index]
		index :+ 1
		lastVersion = list.version
		Return value
	End Method

	Method Remove()
		list._removeAt(index - 1)
		lastVersion = list.version
	End Method

	Method Delete()
		If lastVersion = list.version Then
			list.Compact()
		End If
	End Method

End Type