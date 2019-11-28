SuperStrict

'FIFO container
'converted from: BMX-NG/brl.mod/collection.mod/queue.mod
'                licence: zlib/libPNG
Type TObjectQueue
	Field initialCapacity:Int

	Field data:Object[]
	Field head:Int
	Field tail:Int
	Field size:Int
	Field full:Int

	Method New()
		Self.initialCapacity = 16
		data = New Object[initialCapacity]
	End Method

Rem
	Method GetIterator:IIterator<T>()
		Return New TQueueIterator<T>(Self)
	End Method
endrem

	'Gets the number of elements contained in the container.
	Method Count:Int()
		Return size
	End Method


	'Returns True if the container is empty, otherwise fFalse.
	Method IsEmpty:Int()
		Return size = 0
	End Method


	'Converts the container to an array.
	'returns: An array of elements.
	Method ToArray:Object[]()
		Local arr:Object[size]

		Local i:Int
		For Local o:Object = EachIn Self
			arr[i] = o
			i :+ 1
		Next

		Return arr
	End Method


	'Removes all elements from the container.
	Method Clear()
		If size Then
			Local index:Int = head
			Repeat
				data[index] = Null
				index :+ 1
				If index = data.length Then
					index = 0
				End If
			Until index = tail

			size = 0
			head = tail
		End If
	End Method


	'Determines whether an element is in the container.
	Method Contains:Int(o:Object)
		If Not size Then
			Return False
		End If

		Local index:Int = head
		Repeat
			If o = data[index] Then
				Return True
			End If
			index :+ 1
			If index = data.length Then
				index = 0
			End If
		Until index = tail

		Return False
	End Method


	'Removes and returns the element at the beginning of the container
	'Similar to the Peek() method, but Peek() does not modify the container.
	Method Dequeue:Object()
		If Not size Then
			Throw "The container is empty"
		End If

		full = False

		Local o:Object = data[head]
		head :+ 1

		size :- 1

		If head = data.length Then
			head = 0
		End If

		Return o
	End Method


	'Adds an element to the end of the container.
	'If Count() already equals the capacity, the capacity of the container
	'is increased by automatically reallocating the internal array, and
	'the existing elements are copied to the new array before the new
	'element is added.
	Method Enqueue(o:Object)
		If full Then
			Resize()
		End If

		If Not full Then
			data[tail] = o
			tail :+ 1

			size :+ 1

			If tail = data.length Then
				tail = 0
			End If

			If tail = head Then
				full = True
			End If
		End If
	End Method


	'Returns the element at the beginning of the container without
	'removing it.
	Method Peek:Object()
		If Not size Then
			Throw "The container is empty"
		End If

		Return data[head]
	End Method


	'Can be used to minimize a collection's memory overhead if no new
	'elements will be added to the collection.
	Method TrimExcess()
		Local temp:Object[]
		If Not size Then
			temp = temp[..initialCapacity]
		Else If size < data.length Then
			temp = temp[..size]
		End If

		Local tempIndex:Int
		Local dataIndex:Int = head
		Repeat
			temp[tempIndex] = data[dataIndex]
			dataIndex :+ 1
			If dataIndex = data.length Then
				dataIndex = 0
			End If
			tempIndex :+ 1
		Until dataIndex = tail

		head = 0
		data = temp
		tail = 0
		full = size > 0
	End Method


	'Tries to remove and return the element at the beginning of the
	'container.
	'returns: True if an element was removed and returned from the
	'         beginning of the container successfully; otherwise, False.
	'When this method returns, if the operation was successful, value
	'contains the element removed. If no element was available to be
	'removed, the value is unspecified.
	Method TryDequeue:Int(value:Object Var)
		If Not size Then
			Return False
		End If

		value = Dequeue()
		Return True
	End Method


	'Tries to return an element from the beginning of the container
	'without removing it.
	'returns: True if an element was returned successfully; otherwise, False.
	'When this method returns, value contains an element from the
	'beginning of the container or an unspecified value if the operation
	'failed.
	Method TryPeek:Int(value:Object Var)
		If Not size Then
			Return False
		End If

		value = data[head]
		Return True
	End Method


	Method Resize()
		Local temp:Object[] = New Object[data.length * 2]
		Local tempIndex:Int
		Local dataIndex:Int = head
		Repeat
			temp[tempIndex] = data[dataIndex]
			dataIndex :+ 1
			If dataIndex = data.length Then
				dataIndex = 0
			End If
			tempIndex :+ 1
		Until dataIndex = tail

		head = 0
		tail = data.length
		data = temp
		full = False
	End Method


	Method ObjectEnumerator:TObjectQueueEnumerator()
		Local enumerator:TObjectQueueEnumerator = New TObjectQueueEnumerator
		enumerator.objectQueue = Self
		enumerator.length = Count()
		Return enumerator
	End Method
End Type




Type TObjectQueueEnumerator
	Field index:Int
	Field length:Int
	Field objectQueue:TObjectQueue

	Method HasNext:Int()
		Return index < length
	End Method


	Method NextObject:Object()
		Local o:Object
		If objectQueue.TryDequeue(o)
			index :+ 1
			Return o
		EndIf
		Return Null
	End Method
End Type