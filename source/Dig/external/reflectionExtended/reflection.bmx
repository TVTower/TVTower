Rem
	====================================================================
	class some extended reflection (compared to vanilla)
	====================================================================

	The code in this file was adjusted to be superstrict.
	It is based on the extended version from "grable":
	http://www.blitzmax.com/Community/posts.php?topic=84918

	The licence contains the original author of the reflection code.

	====================================================================
	LICENCE

	Copyright (C) Blitz Research Ltd

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
Import BRL.LinkedList
Import BRL.Map
Import "reflection.cpp"


Private

Extern
	Function bbObjectNew:Object(class:int)
	Function bbObjectRegisteredTypes:Int Ptr(count:int Var)

	Function bbArrayNew1D:Object(typeTag:Byte Ptr, length:int)

	Function bbRefArrayClass()
	Function bbRefStringClass()
	Function bbRefObjectClass()

	Function bbRefArrayLength(array:Object, dim:Int = 0)
	Function bbRefArrayTypeTag$(array:Object)
	Function bbRefArrayDimensions:Int(array:Object)
	Function bbRefArrayCreate:Object(typeTag:Byte Ptr, dims:Int[])

	Function bbRefFieldPtr:Byte Ptr(obj:Object, index:int)
	Function bbRefMethodPtr:Byte Ptr(obj:Object, index:int)
	Function bbRefArrayElementPtr:Byte Ptr(sz:int, array:Object, index:int)

	Function bbRefGetObject:Object(p:Byte Ptr)
	Function bbRefPushObject(p:Byte Ptr, obj:Object)
	Function bbRefInitObject(p:Byte Ptr, obj:Object)
	Function bbRefAssignObject(p:Byte Ptr, obj:Object)

	Function bbRefGetObjectClass(obj:Object)
	Function bbRefGetSuperClass(class:int)
End Extern


Type TClass
	Field _class:int

	Method Compare:int(with:Object)
		Return _class - TClass(with)._class
	End Method

	Method SetClass:TClass(class:int)
		_class = class
		Return Self
	End Method
End Type


Function _Get:Object(p:Byte Ptr, typeId:TTypeId)
	Select typeId
		Case ByteTypeId
			Return String.FromInt( (Byte Ptr p)[0] )
		Case ShortTypeId
			Return String.FromInt( (Short Ptr p)[0] )
		Case IntTypeId
			Return String.FromInt( (Int Ptr p)[0] )
		Case LongTypeId
			Return String.FromLong( (Long Ptr p)[0] )
		Case FloatTypeId
			Return String.FromFloat( (Float Ptr p)[0] )
		Case DoubleTypeId
			Return String.FromDouble( (Double Ptr p)[0] )
		Default
			Return bbRefGetObject(p)
	End Select
End Function


Function _Push:Byte Ptr(sp:Byte Ptr, typeId:TTypeId, value:Object)
	Select typeId
		Case ByteTypeId,ShortTypeId,IntTypeId
			(Int Ptr sp)[0]=value.ToString().ToInt()
			Return sp+4
		Case LongTypeId
			(Long Ptr sp)[0]=value.ToString().ToLong()
			Return sp+8
		Case FloatTypeId
			(Float Ptr sp)[0]=value.ToString().ToFloat()
			Return sp+4
		Case DoubleTypeId
			(Double Ptr sp)[0]=value.ToString().ToDouble()
			Return sp+8
		Case StringTypeId
			If Not value value=""
			bbRefPushObject sp,value
			Return sp+4
		Default
			If value
				Local c:int = typeId._class
				Local t:int = bbRefGetObjectClass(value)
				While t And t<>c
					t = bbRefGetSuperClass(t)
				Wend
				If Not t Throw "ERROR"
			EndIf
			bbRefPushObject sp,value
			Return sp+4
	End Select
End Function

Function _Assign( p:Byte Ptr,typeId:TTypeId,value:Object )
	Select typeId
	Case ByteTypeId
		(Byte Ptr p)[0]=value.ToString().ToInt()
	Case ShortTypeId
		(Short Ptr p)[0]=value.ToString().ToInt()
	Case IntTypeId
		(Int Ptr p)[0]=value.ToString().ToInt()
	Case LongTypeId
		(Long Ptr p)[0]=value.ToString().ToLong()
	Case FloatTypeId
		(Float Ptr p)[0]=value.ToString().ToFloat()
	Case DoubleTypeId
		(Double Ptr p)[0]=value.ToString().ToDouble()
	Case StringTypeId
		If Not value then value=""
		bbRefAssignObject p,value
	Default
		If value
			Local c:int = typeId._class
			Local t:int = bbRefGetObjectClass( value )
			While t And t<>c
				t = bbRefGetSuperClass( t )
			Wend
			If Not t then Throw "ERROR"
		EndIf
		bbRefAssignObject p,value
	End Select
End Function

Function _Call:Object( p:Byte Ptr,typeId:TTypeId,obj:Object,args:Object[],argTypes:TTypeId[], functionCall:int=False )
	Local q:int[10]
	Local sp:Byte Ptr = q

	'only push context and advance by 4 if you have a method-call
	'instead of a function call
	if not functionCall
		bbRefPushObject sp,obj
		sp:+4
	endif

	If typeId=LongTypeId then sp:+8

	For Local i:int = 0 Until args.length
		If Int Ptr(sp)>=Int Ptr(q)+8 Throw "ERROR"
		sp=_Push( sp,argTypes[i],args[i] )
	Next
	If Int Ptr(sp)>Int Ptr(q)+8 Throw "ERROR"
	Select typeId
	Case ByteTypeId,ShortTypeId,IntTypeId
		Local f:Int(p0:int,p1:int,p2:int,p3:int,p4:int,p5:int,p6:int,p7:int) = p
		Return String.FromInt( f( q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7] ) )
	Case LongTypeId
		Throw "TODO"
	Case FloatTypeId
		Local f:Float(p0:int,p1:int,p2:int,p3:int,p4:int,p5:int,p6:int,p7:int) = p
		Return String.FromFloat( f( q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7] ) )
	Case DoubleTypeId
		Local f:Double(p0:int,p1:int,p2:int,p3:int,p4:int,p5:int,p6:int,p7:int) = p
		Return String.FromDouble( f( q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7] ) )
	Default
		Local f:Object(p0:int,p1:int,p2:int,p3:int,p4:int,p5:int,p6:int,p7:int) = p
		Return f( q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7] )
	End Select
End Function

Function TypeTagForId$( id:TTypeId )
	If id.ExtendsType( ArrayTypeId )
		Return "[]"+TypeTagForId( id.ElementType() )
	EndIf
	If id.ExtendsType( ObjectTypeId )
		Return ":"+id.Name()
	EndIf
	Select id
	Case ByteTypeId Return "b"
	Case ShortTypeId Return "s"
	Case IntTypeId Return "i"
	Case LongTypeId Return "l"
	Case FloatTypeId Return "f"
	Case DoubleTypeId Return "d"
	Case StringTypeId Return "$"
	End Select
	Throw "ERROR"
End Function

Function TypeIdForTag:TTypeId( ty$ )
	If ty.StartsWith( "[" )
		Local dims:Int = ty.split(",").length
		ty=ty[ty.Find("]")+1..]
		Local id:TTypeId = TypeIdForTag( ty )
		If id Then
			id._arrayType = Null
			id=id.ArrayType(dims)
		End If
		Return id
	EndIf
	If ty.StartsWith( ":" )
		ty=ty[1..]
		Local i:int = ty.FindLast( "." )
		If i<>-1 then ty=ty[i+1..]
		Return TTypeId.ForName( ty )
	EndIf
	Select ty
	Case "b" Return ByteTypeId
	Case "s" Return ShortTypeId
	Case "i" Return IntTypeId
	Case "l" Return LongTypeId
	Case "f" Return FloatTypeId
	Case "d" Return DoubleTypeId
	Case "$" Return StringTypeId
	End Select
End Function

Function ExtractMetaData$( meta$,key$ )
	If Not key Return meta
	Local i:int = 0
	While i<meta.length
		Local e:int = meta.Find( "=",i )
		If e=-1 then Throw "Malformed meta data"
		Local k$=meta[i..e],v$
		i=e+1
		If i<meta.length And meta[i]=Asc("~q")
			i:+1
			Local e:int = meta.Find( "~q",i )
			If e=-1 Throw "Malformed meta data"
			v=meta[i..e]
			i=e+1
		Else
			Local e:int = meta.Find( " ",i )
			If e=-1 then e=meta.length
			v=meta[i..e]
			i=e
		EndIf
		If k=key Return v
		If i<meta.length And meta[i]=Asc(" ") i:+1
	Wend
End Function

Public

Rem
bbdoc: Primitive byte type
End Rem
Global ByteTypeId:TTypeId=New TTypeId.Init( "Byte",1 )

Rem
bbdoc: Primitive short type
End Rem
Global ShortTypeId:TTypeId=New TTypeId.Init( "Short",2 )

Rem
bbdoc: Primitive int type
End Rem
Global IntTypeId:TTypeId=New TTypeId.Init( "Int",4 )

Rem
bbdoc: Primitive long type
End Rem
Global LongTypeId:TTypeId=New TTypeId.Init( "Long",8 )

Rem
bbdoc: Primitive float type
End Rem
Global FloatTypeId:TTypeId=New TTypeId.Init( "Float",4 )

Rem
bbdoc: Primitive double type
End Rem
Global DoubleTypeId:TTypeId=New TTypeId.Init( "Double",8 )

Rem
bbdoc: Primitive object type
End Rem
Global ObjectTypeId:TTypeId=New TTypeId.Init( "Object",4,bbRefObjectClass() )

Rem
bbdoc: Primitive string type
End Rem
Global StringTypeId:TTypeId=New TTypeId.Init( "String",4,bbRefStringClass(),ObjectTypeId )

Rem
bbdoc: Primitive array type
End Rem
Global ArrayTypeId:TTypeId=New TTypeId.Init( "Null[]",4,bbRefArrayClass(),ObjectTypeId )

Rem
bbdoc: Type member - field or method.
End Rem
Type TMember

	Rem
	bbdoc: Get member name
	End Rem
	Method Name$()
		Return _name
	End Method

	Rem
	bbdoc: Get member type
	End Rem
	Method TypeId:TTypeId()
		Return _typeId
	End Method

	Rem
	bbdoc: Get member meta data
	End Rem
	Method MetaData$( key$="" )
		Return ExtractMetaData( _meta,key )
	End Method

	Field _name$,_typeId:TTypeId,_meta$

End Type

Rem
bbdoc: Type constant
EndRem
Type TConstant Extends TMember
	Method Init:TConstant( name:String, typeId:TTypeId, meta:String, rtti:Int)
		_name = name
		_typeId = typeId
		_meta = meta
		_rtti = Int Ptr(rtti) + 2 ' now points at string: [dd size][db data...]
		Return Self
	EndMethod

	Rem
	bbdoc: Get constant value
	EndRem
	Method GetString:String()
		Return String.FromShorts( Short Ptr(_rtti+1), _rtti[0])
	EndMethod

	Rem
	bbdoc: Get constant value as @Int
	EndRem
	Method GetInt:Int()
		Return GetString().ToInt()
	EndMethod

	Rem
	bbdoc: Get constant value as @Float
	EndRem
	Method GetFloat:Int()
		Return GetString().ToFloat()
	EndMethod

	Rem
	bbdoc: Get constant value as @Long
	EndRem
	Method GetLong:Int()
		Return GetString().ToLong()
	EndMethod

	Rem
	bbdoc: Get constant value as @Double
	EndRem
	Method GetDouble:Int()
		Return GetString().ToDouble()
	EndMethod

	Rem
	bbdoc: Get constant value as @{Byte Ptr}
	EndRem
	Method GetPointer:Byte Ptr()
		Return Byte Ptr GetString().ToInt()
	EndMethod

	Field _rtti:Int Ptr
EndType

Rem
bbdoc: Type field
End Rem
Type TField Extends TMember
	Field _index:int

	Method Init:TField( name$,typeId:TTypeId,meta$,index:int)
		_name=name
		_typeId=typeId
		_meta=meta
		_index=index
		Return Self
	End Method

	Rem
	bbdoc: Get field value
	End Rem
	Method Get:Object( obj:Object )
		Return _Get( bbRefFieldPtr( obj,_index ),_typeId )
	End Method

	Rem
	bbdoc: Get int field value
	End Rem
	Method GetInt:Int( obj:Object )
		Return GetString( obj ).ToInt()
	End Method

	Rem
	bbdoc: Get long field value
	End Rem
	Method GetLong:Long( obj:Object )
		Return GetString( obj ).ToLong()
	End Method

	Rem
	bbdoc: Get float field value
	End Rem
	Method GetFloat:Float( obj:Object )
		Return GetString( obj ).ToFloat()
	End Method

	Rem
	bbdoc: Get double field value
	End Rem
	Method GetDouble:Double( obj:Object )
		Return GetString( obj ).ToDouble()
	End Method

	Rem
	bbdoc: Get string field value
	End Rem
	Method GetString$( obj:Object )
		Return String( Get( obj ) )
	End Method

	Rem
	bbdoc: Set field value
	End Rem
	Method Set( obj:Object,value:Object )
		_Assign bbRefFieldPtr( obj,_index ),_typeId,value
	End Method

	Rem
	bbdoc: Set int field value
	End Rem
	Method SetInt( obj:Object,value:Int )
		SetString obj,String.FromInt( value )
	End Method

	Rem
	bbdoc: Set long field value
	End Rem
	Method SetLong( obj:Object,value:Long )
		SetString obj,String.FromLong( value )
	End Method

	Rem
	bbdoc: Set float field value
	End Rem
	Method SetFloat( obj:Object,value:Float )
		SetString obj,String.FromFloat( value )
	End Method

	Rem
	bbdoc: Set double field value
	End Rem
	Method SetDouble( obj:Object,value:Double )
		SetString obj,String.FromDouble( value )
	End Method

	Rem
	bbdoc: Set string field value
	End Rem
	Method SetString( obj:Object,value$ )
		Set obj,value
	End Method
End Type




Type TFunctionOrMethod Extends TMember
	Field _argTypes:TTypeId[]
	Field _selfTypeId:TTypeId
	Field _fptr:Byte Ptr
	Field _index:Int

	Method Init:TFunctionOrMethod(name:String, typeId:TTypeId, meta:String, selfTypeId:TTypeId, index:Int, argTypes:TTypeId[]) abstract
	Method Invoke:Object( obj:Object, args:Object[] = Null) abstract


	Rem
	bbdoc: Get function or method arg types
	End Rem
	Method ArgTypes:TTypeId[]()
		Return _argTypes
	End Method


	Rem
	bbdoc: Get function pointer.
	endrem
	Method FunctionPtr:Byte Ptr( obj:Object)
		If _fptr Then Return _fptr
		If _index < 65536 Then
			_fptr = bbRefMethodPtr( obj ,_index)
		EndIf
		Return _fptr
	End Method
End Type




Rem
bbdoc: Type function
endrem
Type TFunction Extends TFunctionOrMethod
	Method Init:TFunction(name:String, typeId:TTypeId, meta:String, selfTypeId:TTypeId, index:Int, argTypes:TTypeId[])
		_name=name
		_typeId=typeId
		_meta=meta
		_selfTypeId=selfTypeId
		_index=index
		If _index >= 65536 Then
			_fptr = Byte Ptr(_index)
		Else
			_fptr = Null
		EndIf

		_argTypes=argTypes

		Return Self
	End Method


	Method Invoke:Object( obj:Object, args:Object[] = Null)
		Return _Call( FunctionPtr(obj), _typeId, obj, args, _argTypes, TRUE)
	End Method
EndType



Rem
bbdoc: Type method
End Rem
Type TMethod Extends TFunctionOrMethod
	Method Init:TMethod(name:String, typeId:TTypeId, meta:String, selfTypeId:TTypeId, index:Int, argTypes:TTypeId[])
		_name=name
		_typeId=typeId
		_meta=meta
		_selfTypeId=selfTypeId
		_index=index
		_argTypes=argTypes
		Return Self
	End Method


	Method Invoke:Object( obj:Object, args:Object[] = Null)
		Return _Call( FunctionPtr(obj), _typeId, obj, args, _argTypes, FALSE)
	End Method
End Type




Rem
bbdoc: Type id
End Rem
Type TTypeId

	Rem
	bbdoc: Get name of type
	End Rem
	Method Name$()
		Return _name
	End Method

	Rem
	bbdoc: Get type meta data
	End Rem
	Method MetaData$( key$="" )
		Return ExtractMetaData( _meta,key )
	End Method

	Rem
	bbdoc: Get super type
	End Rem
	Method SuperType:TTypeId()
		Return _super
	End Method

	Rem
	bbdoc: Get array type
	End Rem
	Method ArrayType:TTypeId(dims:Int = 1)
		If Not _arrayType
			Local dim:String
			If dims > 1 Then
				For Local i:Int = 1 Until dims
					dim :+ ","
				Next
			End If
			_arrayType=New TTypeId.Init( _name+"[" + dim + "]",4,bbRefArrayClass() )
			_arrayType._elementType=Self
			If _super
				_arrayType._super=_super.ArrayType()
			Else
				_arrayType._super=ArrayTypeId
			EndIf
		EndIf
		Return _arrayType
	End Method

	Rem
	bbdoc: Get element type
	End Rem
	Method ElementType:TTypeId()
		Return _elementType
	End Method

	Rem
	bbdoc: Determine if type extends a type
	End Rem
	Method ExtendsType:int( typeId:TTypeId )
		If Self=typeId Return True
		If _super Return _super.ExtendsType( typeId )
	End Method

	Rem
	bbdoc: Get list of derived types
	End Rem
	Method DerivedTypes:TList()
		If Not _derived _derived=New TList
		Return _derived
	End Method

	Rem
	bbdoc: Create a new object
	End Rem
	Method NewObject:Object()
		If Not _class Throw "Unable to create new object"
		Return bbObjectNew( _class )
	End Method

	Rem
	bbdoc: Get list of constants
	about: Only returns constants declared in this type, not in super types.
	End Rem
	Method Constants:TList()
		Return _consts
	End Method

	Rem
	bbdoc: Get list of fields
	about: Only returns fields declared in this type, not in super types.
	End Rem
	Method Fields:TList()
		Return _fields
	End Method

	Rem
	bbdoc: Get ist of functions
	about: Only returns functions declared in this type, not in super types.
	endrem
	Method Functions:TList()
		Return _functions
	End Method

	Rem
	bbdoc: Get list of methods
	about: Only returns methods declared in this type, not in super types.
	End Rem
	Method Methods:TList()
		Return _methods
	End Method

	Rem
	bbdoc: Find a field by name
	about: Searchs type hierarchy for field called @name.
	End Rem
	Method FindField:TField( name$ )
		name=name.ToLower()
		For Local t:TField=EachIn _fields
			If t.Name().ToLower()=name Return t
		Next
		If _super Return _super.FindField( name )
	End Method


	Rem
	bbdoc: Find a constant by name
	about: Searchs type hierarchy for constant called @name.
	End Rem
	Method FindConstant:TConstant( name$ )
		name=name.ToLower()
		For Local t:TConstant=EachIn _consts
			If t.Name().ToLower()=name Return t
		Next
		If _super Return _super.FindConstant( name )
	End Method

	Rem
	bbdoc: Find a method by name
	about: Searchs type hierarchy for method called @name.
	End Rem
	Method FindMethod:TMethod( name$ )
		name=name.ToLower()
		For Local t:TMethod=EachIn _methods
			If t.Name().ToLower()=name Return t
		Next
		If _super Return _super.FindMethod( name )
	End Method


	Rem
	bbdoc: Find a function by name
	about: Searches type heirarchy for function called @name
	endrem
	Method FindFunction:TFunction(name:String)
		name = name.ToLower()
		For Local t:TFunction = EachIn _functions
			If t.Name().ToLower() = name Return t
		Next
		If _super Return _super.FindFunction(name)
	End Method

	Rem
	bbdoc: Enumerate all constants
	about: Returns a list of all constants in type hierarchy
	End Rem
	Method EnumConstants:TList( list:TList=Null )
		If Not list list=New TList
		If _super _super.EnumConstants list
		For Local t:TConstant=EachIn _consts
			list.AddLast t
		Next
		Return list
	End Method

	Rem
	bbdoc: Enumerate all fields
	about: Returns a list of all fields in type hierarchy
	End Rem
	Method EnumFields:TList( list:TList=Null )
		If Not list list=New TList
		If _super _super.EnumFields list
		For Local t:TField=EachIn _fields
			list.AddLast t
		Next
		Return list
	End Method

	Rem
	bbdoc: Enumerate all methods
	about: Returns a list of all methods in type hierarchy - TO DO: handle overrides!
	End Rem
	Method EnumMethods:TList( list:TList=Null )
		Function cmp_by_index:Int( a:TMethod, b:TMethod)
			Return a._index - b._index
		EndFunction

		If Not list list=New TList
'		If _super _super.EnumMethods list
		If _super And _super <> Self Then _super.EnumMethods list

		For Local t:TMethod=EachIn _methods
			list.AddLast t
		Next

		'FIX: remove overridden methods
		list.Sort( True, Byte Ptr cmp_by_index)
		Local prev:TMethod
		For Local t:TMethod = EachIn list
			If prev Then
				If (t._index - prev._index) = 0 Then list.Remove(prev)
			EndIf
			prev = t
		Next

		Return list
	End Method


	Rem
	bbdoc: Enumerate all functions
	about: Returns a list of all functions in type hierarchy
	End Rem
	Method EnumFunctions:TList( list:TList=Null )
		Function cmp_by_name:Int( a:TFunction, b:TFunction)
			Return a.Name().Compare(b.Name())
		EndFunction

		If Not list list=New TList
		If _super And _super <> Self Then _super.EnumFunctions list
		For Local t:TFunction=EachIn _functions
			list.AddLast t
		Next

		'FIX: remove overridden functions
		list.Sort( True, Byte Ptr cmp_by_name)
		Local prev:TFunction
		For Local t:TFunction = EachIn list
			If prev Then
				If (t.Name().Compare(prev.Name())) = 0 Then list.Remove(prev)
			EndIf
			prev = t
		Next

		Return list
	End Method

	Rem
	bbdoc: Create a new array
	End Rem
	Method NewArray:Object( length:int, dims:Int[] = Null )
		If Not _elementType Throw "TypeID is not an array type"
		Local tag:Byte Ptr=_elementType._typeTag
		If Not tag
			tag=TypeTagForId( _elementType ).ToCString()
			_elementType._typeTag=tag
		EndIf
		If Not dims Then
			Return bbArrayNew1D( tag,length )
		Else
			Return bbRefArrayCreate( tag, dims )
		End If
	End Method

	Rem
	bbdoc: Get array length
	End Rem
	Method ArrayLength:int( array:Object, dim:Int = 0 )
		If Not _elementType Throw "TypeID is not an array type"
		Return bbRefArrayLength( array, dim )
	End Method

	Rem
	bbdoc: Get the number of dimensions
	End Rem
	Method ArrayDimensions:Int( array:Object )
		If Not _elementType Throw "TypeID is not an array type"
		Return bbRefArrayDimensions( array )
	End Method

	Rem
	bbdoc: Get an array element
	End Rem
	Method GetArrayElement:Object( array:Object,index:int )
		If Not _elementType Throw "TypeID is not an array type"
		Local p:Byte Ptr=bbRefArrayElementPtr( _elementType._size,array,index )
		Return _Get( p,_elementType )
	End Method

	Rem
	bbdoc: Set an array element
	End Rem
	Method SetArrayElement( array:Object,index:int,value:Object )
		If Not _elementType Throw "TypeID is not an array type"
		Local p:Byte Ptr=bbRefArrayElementPtr( _elementType._size,array,index )
		_Assign p,_elementType,value
	End Method

	Rem
	bbdoc: Get Type by name
	End Rem
	Function ForName:TTypeId( name$ )
		_Update
		If name.EndsWith( "]" )
			' TODO
			name=name[..name.length-2]
			Return TTypeId( _nameMap.ValueForKey( name.ToLower() ) ).ArrayType()
		Else
			Return TTypeId( _nameMap.ValueForKey( name.ToLower() ) )
		EndIf
	End Function

	Rem
	bbdoc: Get Type by object
	End Rem
	Function ForObject:TTypeId( obj:Object )
		_Update
		Local class:int= bbRefGetObjectClass(obj)
		If class=ArrayTypeId._class
			If Not bbRefArrayLength( obj ) Return ArrayTypeId
			Return TypeIdForTag( bbRefArrayTypeTag( obj ) ).ArrayType()
		Else
			Return TTypeId( _classMap.ValueForKey( New TClass.SetClass( class ) ) )
		EndIf
	End Function

	Rem
	bbdoc: Get list of all types
	End Rem
	Function EnumTypes:TList()
		_Update
		Local list:TList=New TList
		For Local t:TTypeId=EachIn _nameMap.Values()
			list.AddLast t
		Next
		Return list
	End Function

	'***** PRIVATE *****

	Method Init:TTypeId( name$,size:int,class:int=0,supor:TTypeId=Null )
		_name=name
		_size=size
		_class=class
		_super=supor
		_consts=New TList
		_fields=New TList
		_functions=New TList
		_methods=New TList
		_nameMap.Insert _name.ToLower(),Self
		If class _classMap.Insert New TClass.SetClass( class ),Self
		Return Self
	End Method

	Method SetClass:TTypeId( class:int )
		Local debug:int=(Int Ptr class)[2]
		Local name$=String.FromCString( Byte Ptr( (Int Ptr debug)[1] ) ),meta$
		Local i:int=name.Find( "{" )
		If i<>-1
			meta=name[i+1..name.length-1]
			name=name[..i]
		EndIf
		_name=name
		_meta=meta
		_class=class
		_nameMap.Insert _name.ToLower(),Self
		_classMap.Insert New TClass.SetClass( class ),Self
		Return Self
	End Method

	Function _Update()
		Local count:int,p:Int Ptr=bbObjectRegisteredTypes( count )
		If count=_count Return
		Local list:TList=New TList
		For Local i:int=_count Until count
			Local ty:TTypeId=New TTypeId.SetClass( p[i] )
			list.AddLast ty
		Next
		_count=count
		For Local t:TTypeId=EachIn list
			t._Resolve
		Next
	End Function

	Method _Resolve()
		If _fields Or Not _class Return


		_consts=New TList
		_fields=New TList
		_functions=New TList
		_methods=New TList
		_super=TTypeId( _classMap.ValueForKey( New TClass.SetClass( (Int Ptr _class)[0] ) ) )
		If Not _super _super=ObjectTypeId
		If Not _super._derived _super._derived=New TList
		_super._derived.AddLast Self

		Local debug:int=(Int Ptr _class)[2]
		Local p:Int Ptr=(Int Ptr debug)+2

		While p[0]
			Local id$=String.FromCString( Byte Ptr p[1] )
			Local ty$=String.FromCString( Byte Ptr p[2] )

			Local meta$
			Local i:int=ty.Find( "{" )
			If i<>-1
				meta=ty[i+1..ty.length-1]
				ty=ty[..i]
			EndIf

			Select p[0]
				Case 1	'const
					Local typeId:TTypeId = TypeIdFortag(ty)
					If typeId Then _consts.AddLast(New TConstant.Init(id, typeId, meta, p[3]))
				Case 3	'field
					Local typeId:TTypeId=TypeIdForTag( ty )
					If typeId Then _fields.AddLast(New TField.Init(id, typeId, meta, p[3]))
				Case 6	'method
					Local t$[]=ty.Split( ")" )
					Local retType:TTypeId=TypeIdForTag( t[1] )
					If retType
						Local argTypes:TTypeId[]
						If BuildArgTypes(retType, t, argTypes)
							_methods.AddLast New TMethod.Init( id,retType,meta,Self,p[3],argTypes )
						EndIf
					EndIf
				Case 7	' function
					Local t$[]=ty.Split( ")" )
					Local retType:TTypeId=TypeIdForTag( t[1] )
					If retType
						Local argTypes:TTypeId[]
						If BuildArgTypes(retType, t, argTypes)
							_functions.AddLast(New TFunction.Init(id, retType, meta, Self, p[3], argTypes))
						endif
					EndIf
			End Select
			p:+4
		Wend
	End Method

	Method BuildArgTypes:TTypeId(retType:TTypeId, t:string[], argTypes:TTypeId[] var)
		If t[0].length>1
			Local i:int,b:int,q$=t[0][1..],args:TList=New TList
			While i<q.length
				Select q[i]
				Case Asc( "," )
					args.AddLast q[b..i]
					i:+1
					b=i
				Case Asc( "[" )
					i:+1
					While i<q.length And q[i]=Asc(",")
						i:+1
					Wend
				Default
					i:+1
				End Select
			Wend
			If b<q.length args.AddLast q[b..q.length]

			argTypes=New TTypeId[args.Count()]

			i=0
			For Local arg$=EachIn args
				argTypes[i]=TypeIdForTag( arg )
				If Not argTypes[i] then retType=Null
				i:+1
			Next
		EndIf
		return retType
	End Method


	Field _name$
	Field _meta$
	Field _class:int
	Field _size:int=4
	Field _consts:TList
	Field _fields:TList
	Field _methods:TList
	Field _functions:TList
	Field _super:TTypeId
	Field _derived:TList
	Field _arrayType:TTypeId
	Field _elementType:TTypeId
	Field _typeTag:Byte Ptr

	Global _count:int,_nameMap:TMap=New TMap,_classMap:TMap=New TMap

End Type
