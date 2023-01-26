SuperStrict

Import "base.util.longintmap.c"

Extern
	Function bmx_map_longintmap_clear(root:SavlRoot Ptr Ptr)
	Function bmx_map_longintmap_isempty:Int(root:SavlRoot Ptr)
	Function bmx_map_longintmap_insert(key:Long, value:Int, root:SavlRoot Ptr Ptr)
	Function bmx_map_longintmap_contains:Int(key:Long, root:SavlRoot Ptr)
	Function bmx_map_longintmap_valueforkey:Int(key:Long, root:SavlRoot Ptr)
	Function bmx_map_longintmap_remove:Int(key:Long, root:SavlRoot Ptr)
	Function bmx_map_longintmap_firstnode:SLongIntMapNode Ptr(root:SavlRoot Ptr)
	Function bmx_map_longintmap_nextnode:SLongIntMapNode Ptr(node:SLongIntMapNode Ptr)
	Function bmx_map_longintmap_key:Long(node:SLongIntMapNode Ptr)
	Function bmx_map_longintmap_value:Int(node:SLongIntMapNode Ptr)
	Function bmx_map_longintmap_hasnext:Int(node:SLongIntMapNode Ptr, root:SavlRoot Ptr)
	Function bmx_map_longintmap_copy(dst:SavlRoot Ptr Ptr, _root:SavlRoot Ptr)
End Extern


Struct SavlRoot
	Field left:SavlRoot Ptr
	Field right:SavlRoot Ptr
	Field parent:SavlRoot Ptr
	Field balance:Int
End Struct

Struct SLongIntMapNode
	Field link:SavlRoot
	Field key:Long
	Field value:Int
End Struct

Rem
bbdoc: A key/value (Long/Int) map.
End Rem
Type TLongIntMap

	Method Delete()
		Clear()
	End Method

	Rem
	bbdoc: Clears the map.
	about: Removes all keys and values.
	End Rem
	Method Clear()
		bmx_map_longintmap_clear(Varptr _root)
	End Method
	
	Rem
	bbdoc: Checks if the map is empty.
	about: #True if @map is empty, otherwise #False.
	End Rem
	Method IsEmpty:Int()
		Return bmx_map_longintmap_isempty(_root)
	End Method
	
	Rem
	bbdoc: Inserts a key/value pair into the map.
	about: If the map already contains @key, its value is overwritten with @value. 
	End Rem
	Method Insert( key:Long,value:Int )
		bmx_map_longintmap_insert(key, value, Varptr _root)
	End Method

	Rem
	bbdoc: Checks if the map contains @key.
	returns: #True if the map contains @key.
	End Rem
	Method Contains:Int( key:Long )
		Return bmx_map_longintmap_contains(key, _root)
	End Method
	
	Rem
	bbdoc: Finds a value given a @key.
	returns: The value associated with @key.
	about: If the map does not contain @key, 0 is returned! Use Contains() to check existence!
	End Rem
	Method ValueForKey:Int( key:Long )
		Return bmx_map_longintmap_valueforkey(key, _root)
	End Method
	
	Rem
	bbdoc: Remove a key/value pair from the map.
	returns: #True if @key was removed, or #False otherwise.
	End Rem
	Method Remove:Int( key:Long )
		Return bmx_map_longintmap_remove(key, Varptr _root)
	End Method

	Method _FirstNode:TLongIntNode()
		If Not IsEmpty() Then
			Local node:TLongIntNode= New TLongIntNode
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
	Method Keys:TLongIntMapEnumerator()
		Local nodeenum:TLongIntNodeEnumerator
		If Not isEmpty() Then
			nodeenum=New TLongIntKeyEnumerator
			nodeenum._node=_FirstNode()
		Else
			nodeenum=New TLongIntEmptyEnumerator
		End If
		Local mapenum:TLongIntMapEnumerator=New TLongIntMapEnumerator
		mapenum._enumerator=nodeenum
		Return mapenum
	End Method
	
	Rem
	bbdoc: Get the map values.
	returns: An enumeration object.
	about: The object returned by #Values can be used with #EachIn to iterate through the values in the map.
	End Rem
	Method Values:TLongIntMapEnumerator()
		Local nodeenum:TLongIntNodeEnumerator
		If Not isEmpty() Then
			nodeenum=New TLongIntValueEnumerator
			nodeenum._node=_FirstNode()
		Else
			nodeenum=New TLongIntEmptyEnumerator
		End If
		Local mapenum:TLongIntMapEnumerator=New TLongIntMapEnumerator
		mapenum._enumerator=nodeenum
		Return mapenum
	End Method
	
	Rem
	bbdoc: Returns a copy the contents of this map.
	End Rem
	Method Copy:TLongIntMap()
		Local map:TLongIntMap=New TLongIntMap
		bmx_map_longintmap_copy(Varptr map._root, _root)
		Return map
	End Method
	
	Rem
	bbdoc: Returns a node enumeration object.
	about: The object returned by #ObjectEnumerator can be used with #EachIn to iterate through the nodes in the map.
	End Rem
	Method ObjectEnumerator:TLongIntNodeEnumerator()
		Local nodeenum:TLongIntNodeEnumerator
		If Not isEmpty() Then
			nodeenum = New TLongIntNodeEnumerator
			nodeenum._node=_FirstNode()
		Else
			nodeenum=New TLongIntEmptyEnumerator
		End If
		Return nodeenum
	End Method

	Rem
	bbdoc: Finds a value given a @key using index syntax.
	returns: The value associated with @key.
	about: If the map does not contain @key, a #Null object is returned.
	End Rem
	Method Operator[]:Int(key:Long)
		Return bmx_map_longintmap_valueforkey(key, _root)
	End Method
	
	Rem
	bbdoc: Inserts a key/value pair into the map using index syntax.
	about: If the map already contains @key, its value is overwritten with @value. 
	End Rem
	Method Operator[]=(key:Long, value:Int)
		bmx_map_longintmap_insert(key, value, Varptr _root)
	End Method

	Field _root:SavlRoot Ptr

End Type

Type TLongIntNode
	Field _root:SavlRoot Ptr
	Field _nodePtr:SLongIntMapNode Ptr
	
	Field _nextNode:SLongIntMapNode Ptr
	
	Method Key:Long()
		Return bmx_map_longintmap_key(_nodePtr)
	End Method
	
	Method Value:Int()
		Return bmx_map_longintmap_value(_nodePtr)
	End Method

	Method HasNext:Int()
		Return bmx_map_longintmap_hasnext(_nodePtr, _root)
	End Method
	
	Method NextNode:TLongIntNode()
		If Not _nodePtr Then
			_nodePtr = bmx_map_longintmap_firstnode(_root)
		Else
			_nodePtr = _nextNode
		End If

		If HasNext() Then
			_nextNode = bmx_map_longintmap_nextnode(_nodePtr)
		End If

		Return Self
	End Method
	
	Method Remove()
		
	End Method
	
End Type

Rem
bbdoc: LongInt holder for key returned by TLongIntMap.Keys() enumerator.
about: Because a single instance of #TLongIntKeyValue is used during enumeration, #value changes on each iteration.
End Rem
Type TLongIntKeyValue
	Field key:Long
	Field value:Int
End Type

Type TLongIntNodeEnumerator
	Method HasNext:Int()
		Return _node.HasNext()
	End Method
	
	Method NextObject:Object()
		Local node:TLongIntNode=_node
		_node=_node.NextNode()
		Return node
	End Method
	
	'***** PRIVATE *****
		
	Field _node:TLongIntNode	
End Type

Type TLongIntKeyEnumerator Extends TLongIntNodeEnumerator
	Field _keyValue:TLongIntKeyValue = New TLongIntKeyValue
	Method NextObject:Object() Override
		Local node:TLongIntNode=_node
		_node=_node.NextNode()
		_keyValue.key = node.Key()
		_keyValue.value = node.Value()
		Return _keyValue
	End Method
End Type

Type TLongIntValueEnumerator Extends TLongIntNodeEnumerator
	Field _keyValue:TLongIntKeyValue = New TLongIntKeyValue
	Method NextObject:Object() Override
		Local node:TLongIntNode=_node
		_node=_node.NextNode()
		_keyValue.key = node.Key()
		_keyValue.value = node.Value()
		Return _keyValue
	End Method
End Type

Type TLongIntMapEnumerator
	Method ObjectEnumerator:TLongIntNodeEnumerator()
		Return _enumerator
	End Method
	Field _enumerator:TLongIntNodeEnumerator
End Type

Type TLongIntEmptyEnumerator Extends TLongIntNodeEnumerator
	Method HasNext:Int() Override
		Return False
	End Method
End Type
