SuperStrict
Import "base.util.longmap.c"

Extern
	Function bmx_map_longmap_clear(root:Byte Ptr Ptr)
	Function bmx_map_longmap_isempty:Int(root:Byte Ptr Ptr)
	Function bmx_map_longmap_insert(key:Long, value:Object, root:Byte Ptr Ptr)
	Function bmx_map_longmap_contains:Int(key:Long, root:Byte Ptr Ptr)
	Function bmx_map_longmap_valueforkey:Object(key:Long, root:Byte Ptr Ptr)
	Function bmx_map_longmap_remove:Int(key:Long, root:Byte Ptr Ptr)
	Function bmx_map_longmap_firstnode:Byte Ptr(root:Byte Ptr)
	Function bmx_map_longmap_nextnode:Byte Ptr(node:Byte Ptr)
	Function bmx_map_longmap_key:Long(node:Byte Ptr)
	Function bmx_map_longmap_value:Object(node:Byte Ptr)
	Function bmx_map_longmap_hasnext:Int(node:Byte Ptr, root:Byte Ptr)
	Function bmx_map_longmap_copy(dst:Byte Ptr Ptr, _root:Byte Ptr)
End Extern

Rem
bbdoc: A key/value (Int/Object) map.
End Rem
Type TLongMap

	Method Delete()
		Clear
	End Method

	Rem
	bbdoc: Clears the map.
	about: Removes all keys and values.
	End Rem
	Method Clear()
?ngcmod
		If Not IsEmpty() Then
			_modCount :+ 1
		End If
?
		bmx_map_longmap_clear(Varptr _root)
	End Method
	
	Rem
	bbdoc: Checks if the map is empty.
	about: #True if @map is empty, otherwise #False.
	End Rem
	Method IsEmpty:Int()
		Return bmx_map_longmap_isempty(Varptr _root)
	End Method
	
	Rem
	bbdoc: Inserts a key/value pair into the map.
	about: If the map already contains @key, its value is overwritten with @value. 
	End Rem
	Method Insert( key:Long,value:Object )
		bmx_map_longmap_insert(key, value, Varptr _root)
?ngcmod
		_modCount :+ 1
?
	End Method

	Rem
	bbdoc: Checks if the map contains @key.
	returns: #True if the map contains @key.
	End Rem
	Method Contains:Int( key:Long )
		Return bmx_map_longmap_contains(key, Varptr _root)
	End Method
	
	Rem
	bbdoc: Finds a value given a @key.
	returns: The value associated with @key.
	about: If the map does not contain @key, a #Null object is returned.
	End Rem
	Method ValueForKey:Object( key:Long )
		Return bmx_map_longmap_valueforkey(key, Varptr _root)
	End Method
	
	Rem
	bbdoc: Remove a key/value pair from the map.
	returns: #True if @key was removed, or #False otherwise.
	End Rem
	Method Remove:Int( key:Long )
?ngcmod
		_modCount :+ 1
?
		Return bmx_map_longmap_remove(key, Varptr _root)
	End Method

	Method _FirstNode:TLongNode()
		If Not IsEmpty() Then
			Local node:TLongNode= New TLongNode
			node._root = _root
			Return node
		Else
			Return Null
		End If
	End Method
	
	Rem
	bbdoc: Gets the map keys.
	returns: An enumeration object
	about: The object returned by #Keys can be used with #EachIn to iterate through the keys in the map.
	End Rem
	Method Keys:TLongMapEnumerator()
		Local nodeenum:TLongNodeEnumerator
		If Not isEmpty() Then
			nodeenum=New TLongKeyEnumerator
			nodeenum._node=_FirstNode()
		Else
			nodeenum=New TLongEmptyEnumerator
		End If
		Local mapenum:TLongMapEnumerator=New TLongMapEnumerator
		mapenum._enumerator=nodeenum
		nodeenum._map = Self
?ngcmod
		nodeenum._expectedModCount = _modCount
?
		Return mapenum
	End Method
	
	Rem
	bbdoc: Get the map values.
	returns: An enumeration object.
	about: The object returned by #Values can be used with #EachIn to iterate through the values in the map.
	End Rem
	Method Values:TLongMapEnumerator()
		Local nodeenum:TLongNodeEnumerator
		If Not isEmpty() Then
			nodeenum=New TLongValueEnumerator
			nodeenum._node=_FirstNode()
		Else
			nodeenum=New TLongEmptyEnumerator
		End If
		Local mapenum:TLongMapEnumerator=New TLongMapEnumerator
		mapenum._enumerator=nodeenum
		nodeenum._map = Self
?ngcmod
		nodeenum._expectedModCount = _modCount
?
		Return mapenum
	End Method
	
	Rem
	bbdoc: Returns a copy the contents of this map.
	End Rem
	Method Copy:TLongMap()
		Local map:TLongMap=New TLongMap
		bmx_map_longmap_copy(Varptr map._root, _root)
		Return map
	End Method
	
	Rem
	bbdoc: Returns a node enumeration object.
	about: The object returned by #ObjectEnumerator can be used with #EachIn to iterate through the nodes in the map.
	End Rem
	Method ObjectEnumerator:TLongNodeEnumerator()
		Local nodeenum:TLongNodeEnumerator
		If Not isEmpty() Then
			nodeenum = New TLongNodeEnumerator
			nodeenum._node=_FirstNode()
			nodeenum._map = Self
		Else
			nodeenum=New TLongEmptyEnumerator
		End If
		Return nodeenum
	End Method

	Rem
	bbdoc: Finds a value given a @key using index syntax.
	returns: The value associated with @key.
	about: If the map does not contain @key, a #Null object is returned.
	End Rem
	Method Operator[]:Object(key:Long)
		Return bmx_map_longmap_valueforkey(key, Varptr _root)
	End Method
	
	Rem
	bbdoc: Inserts a key/value pair into the map using index syntax.
	about: If the map already contains @key, its value is overwritten with @value. 
	End Rem
	Method Operator[]=(key:Long, value:Object)
		bmx_map_longmap_insert(key, value, Varptr _root)
	End Method

	Field _root:Byte Ptr

?ngcmod
	Field _modCount:Int
?

End Type

Type TLongNode
	Field _root:Byte Ptr
	Field _nodePtr:Byte Ptr
	
	Field _nextNode:Byte Ptr
	
	Method key:Long()
		Return bmx_map_longmap_key(_nodePtr)
	End Method
	
	Method Value:Object()
		Return bmx_map_longmap_value(_nodePtr)
	End Method

	Method HasNext:Int()
		Return bmx_map_longmap_hasnext(_nodePtr, _root)
	End Method
	
	Method NextNode:TLongNode()
		If Not _nodePtr Then
			_nodePtr = bmx_map_longmap_firstnode(_root)
		Else
			'_nodePtr = bmx_map_longmap_nextnode(_nodePtr)
			_nodePtr = _nextNode
		End If

		If HasNext() Then
			_nextNode = bmx_map_longmap_nextnode(_nodePtr)
		End If

		Return Self
	End Method
	
	Method Remove()
		
	End Method
	
End Type

Rem
bbdoc: Long holder for key returned by TLongMap.Keys() enumerator.
about: Because a single instance of #TLongKey is used during enumeration, #value changes on each iteration.
End Rem
Type TLongKey
	Rem
	bbdoc: Long key value.
	End Rem
	Field value:Long
End Type

Type TLongNodeEnumerator
	Method HasNext:Int()
		Local has:Int = _node.HasNext()
		If Not has Then
			_map = Null
		End If
		Return has
	End Method
	
	Method NextObject:Object()
?ngcmod
		Assert _expectedModCount = _map._modCount, "TLongMap Concurrent Modification"
?
		Local node:TLongNode=_node
		_node=_node.NextNode()
		Return node
	End Method
	
	'***** PRIVATE *****
		
	Field _node:TLongNode	

	Field _map:TLongMap
?ngcmod
	Field _expectedModCount:Int
?
End Type

Type TLongKeyEnumerator Extends TLongNodeEnumerator
	Field _key:TLongKey = New TLongKey
	Method NextObject:Object() Override
?ngcmod
		Assert _expectedModCount = _map._modCount, "TLongMap Concurrent Modification"
?
		Local node:TLongNode=_node
		_node=_node.NextNode()
		_key.value = node.Key()
		Return _key
	End Method
End Type

Type TLongValueEnumerator Extends TLongNodeEnumerator
	Method NextObject:Object() Override
?ngcmod
		Assert _expectedModCount = _map._modCount, "TLongMap Concurrent Modification"
?
		Local node:TLongNode=_node
		_node=_node.NextNode()
		Return node.Value()
	End Method
End Type

Type TLongMapEnumerator
	Method ObjectEnumerator:TLongNodeEnumerator()
		Return _enumerator
	End Method
	Field _enumerator:TLongNodeEnumerator
End Type

Type TLongEmptyEnumerator Extends TLongNodeEnumerator
	Method HasNext:Int() Override
		_map = Null
		Return False
	End Method
End Type
