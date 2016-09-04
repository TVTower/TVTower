Rem
	====================================================================
	class some extended reflection (compared to vanilla)
	====================================================================

	This code is based on the extended version from "grable":
	http://www.blitzmax.com/Community/posts.php?topic=84918

	It got cleaned up a bit to save some LOCs of unneeded code.
	

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
Strict

Rem
bbdoc: BASIC/Reflection

Module BRL.Reflection

ModuleInfo "Version: 1.28"
ModuleInfo "Author: Mark Sibly"
ModuleInfo "License: zlib/libpng"
ModuleInfo "Copyright: Blitz Research Ltd"
ModuleInfo "Modserver: BRL"

ModuleInfo "History: 1.28 [grable]"
ModuleInfo "History: Reverted back to old _Call() before assembly (max 8 arguments) for MacOSX"
ModuleInfo "History: 1.27 [Derron]"
ModuleInfo "History: Fixed MacOSX assembly not compiling"
ModuleInfo "History: 1.26 [Derron]"
ModuleInfo "History: Fixed TFunction.FunctionPtr() accessing supertype of Null"
ModuleInfo "History: 1.25 [grable]"
ModuleInfo "History: Fixed linux version of bbCallMethod"
ModuleInfo "History: Added macos version of bbCallMethod"
ModuleInfo "History: 1.24 [grable]"
ModuleInfo "History: Added linux version of bbCallMethod"
ModuleInfo "History: 1.23 [grable]"
ModuleInfo "History: Added _bbCallMethod() asm function for calling with proper number of arguments"
ModuleInfo "History: Increased maximum argument count to 30"
ModuleInfo "History: 1.22 [grable]"
ModuleInfo "History: Fixed _Call not working with Long/Double return types"
ModuleInfo "History: 1.21 [grable]"
ModuleInfo "History: Fixed _Push not setting bbEmptyArray for Null arrays."
ModuleInfo "History: 1.20 [derron]"
ModuleInfo "History: Fixed typo, and added Null argument to TMethod.Invoke()"
ModuleInfo "History: 1.19 [grable]"
ModuleInfo "History: Fixed TTypeId.PointerType() recursing over root PointerTypeId"
ModuleInfo "History: 1.18 [grable]"
ModuleInfo "History: Added check for NullTypeId in TypeTagForId, also improved error message"
ModuleInfo "History: 1.17 [grable]"
ModuleInfo "History: Fixed missing ElementType for ArrayTypeId"
ModuleInfo "History: 1.16 [gwron]"
ModuleInfo "History: minor adjustments to code (cleanup)."
ModuleInfo "History: 1.15 [brucey]"
ModuleInfo "History: fixed _Assign not setting bbEmptyArray for Null arrays."
ModuleInfo "History: 1.14 [grable]"
ModuleInfo "History: fixed missing call to ReturnType() in TMethod.Invoke()"
ModuleInfo "History: 1.13 [grable]"
ModuleInfo "History: fixed TypeTagForId() regarding pointers"
ModuleInfo "History: fixed _Push and _Assign regarding pointers"
ModuleInfo "History: 1.12 [grable]"
ModuleInfo "History: added TTypeId.ArraySlice() for slicing untyped arrays"
ModuleInfo "History: 1.11 [grable]"
ModuleInfo "History: refixed TMethod overrides, and added same for TFunction"
ModuleInfo "History: 1.10 [grable]"
ModuleInfo "History: fixed bug in FindConstant()"
ModuleInfo "History: added TField.FieldPtr() for direct pointer to instance fields"
ModuleInfo "History: 1.09 [grable]"
ModuleInfo "History: fixed parsing of function pointers with spaces via ForName"
ModuleInfo "History: 1.08 [grable]"
ModuleInfo "History: Added type constants (TConstant and relevant methods to TTypeId)"
ModuleInfo "History: 1.07 [grable]"
ModuleInfo "History: Minor fixes"
ModuleInfo "History: 1.06 [grable]"
ModuleInfo "History: Added function pointer support (FunctionTypeId...)"
ModuleInfo "History: Also did some reworking of TFunction/TMethod and pushed parsing of function metadata over to TypeIdForTag()"
ModuleInfo "History: 1.05 [Otus]"
ModuleInfo "History: Fixed TMethod overrides, Nested arrays (TTypeId.ForName)"
ModuleInfo "History: 1.04 [grable]"
ModuleInfo "History: Added pointer support (PointerTypeId...)"
ModuleInfo "History: 1.03 [blitz-forum]"
ModuleInfo "History: Added support for type functions (TFunction...)"

ModuleInfo "History: 1.02 Release"
ModuleInfo "History: Added Brucey's size fix to GetArrayElement()/SetArrayElement()"
ModuleInfo "History: 1.01 Release"
ModuleInfo "History: Fixed NewArray using temp type name"
End Rem

Import BRL.LinkedList
Import BRL.Map

Import "reflection.cpp"

?Not x86
	Throw "callmethod assembly is x86 only!"
?
?Linux
Import "callmethod.linux.x86.s"
?Win32
Import "callmethod.win32.x86.s"
?MacOS
' disabled until i can figure out what special voodoo macs require
'Import "callmethod.macos.x86.s"
?

Private

?MacOS
Const MAX_CALL_ARGS:Int = 8
?Not MacOS
Const MAX_CALL_ARGS:Int = 30
?

Extern

Function bbObjectNew:Object( class )
Function bbObjectRegisteredTypes:Int Ptr( count Var )

Function bbArrayNew1D:Object( typeTag:Byte Ptr,length )
Function bbArraySlice:Object( typeTag:Byte Ptr,inarr:Object,start:Int,stop:Int )

Function bbRefArrayClass()
Function bbRefStringClass()
Function bbRefObjectClass()

Function bbRefArrayLength( array:Object, dim:Int = 0 )
Function bbRefArrayTypeTag$( array:Object )
Function bbRefArrayDimensions:Int( array:Object )
Function bbRefArrayCreate:Object( typeTag:Byte Ptr,dims:Int[] )
Function bbRefArrayNull:Object()

Function bbRefFieldPtr:Byte Ptr( obj:Object,index )
Function bbRefMethodPtr:Byte Ptr( obj:Object,index )
Function bbRefArrayElementPtr:Byte Ptr( sz,array:Object,index )

Function bbRefGetObject:Object( p:Byte Ptr )
Function bbRefPushObject( p:Byte Ptr,obj:Object )
Function bbRefInitObject( p:Byte Ptr,obj:Object )
Function bbRefAssignObject( p:Byte Ptr,obj:Object )

Function bbRefGetObjectClass( obj:Object )
Function bbRefGetSuperClass( class )

?Not MacOS
Function bbCallMethod:Int( p:Byte Ptr, args:Byte Ptr, sz:Int)
Function bbCallMethod_Float:Float( p:Byte Ptr, args:Byte Ptr, sz:Int) = "bbCallMethod"
Function bbCallMethod_Object:Object( p:Byte Ptr, args:Byte Ptr, sz:Int) = "bbCallMethod"
Function bbCallMethod_Double:Double( p:Byte Ptr, args:Byte Ptr, sz:Int) = "bbCallMethod"
?
End Extern

Type TClass

	Method Compare( with:Object )
		Return _class-TClass( with )._class
	End Method
	
	Method SetClass:TClass( class )
		_class=class
		Return Self
	End Method
	
	Field _class
End Type

Function _Get:Object( p:Byte Ptr,typeId:TTypeId )
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
		If typeid.ExtendsType(PointerTypeId) Or typeid.ExtendsType(FunctionTypeId) Then
			Return String.FromInt( (Int Ptr p)[0] )
		EndIf
		Return bbRefGetObject( p )
	End Select
End Function

Function _Push:Byte Ptr( sp:Byte Ptr,typeId:TTypeId,value:Object )
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
		If typeid.ExtendsType(PointerTypeId) Then
			If value Then
				(Int Ptr sp)[0]=value.ToString().ToInt()
			Else
				(Int Ptr sp)[0]=0
			EndIf
			Return sp+4
		ElseIf typeid.ExtendsType(FunctionTypeId) Then
			If value Then
				(Int Ptr sp)[0]=value.ToString().ToInt()
			Else
				(Int Ptr sp)[0]=Int Byte Ptr NullFunctionError
			EndIf
			Return sp+4
		ElseIf typeId.ExtendsType(ArrayTypeId)
			If Not value Then value = bbRefArrayNull()
		EndIf
		If value
			Local c=typeId._class
			Local t=bbRefGetObjectClass( value )
			While t And t<>c
				t=bbRefGetSuperClass( t )
			Wend
			If Not t Throw "_Push() ERROR"
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
		If Not value value=""
		bbRefAssignObject p,value
	Default
		If typeid.ExtendsType(PointerTypeId) Then
			If value Then
				(Int Ptr p)[0]=value.ToString().ToInt()
			Else
				(Int Ptr p)[0]=0
			EndIf
			Return
		ElseIf typeid.ExtendsType(FunctionTypeId) Then
			If value Then
				(Int Ptr p)[0]=value.ToString().ToInt()
			Else
				(Int Ptr p)[0]=Int Byte Ptr NullFunctionError
			EndIf
			Return
		ElseIf typeId.ExtendsType(ArrayTypeId)
			If Not value Then value = bbRefArrayNull()
		EndIf
		If value
			Local c=typeId._class
			Local t=bbRefGetObjectClass( value )
			While t And t<>c
				t=bbRefGetSuperClass( t )
			Wend
			If Not t Throw "_Assign() ERROR"
		EndIf
		bbRefAssignObject p,value
	End Select
End Function

'
' bmx fallback path for calling methods. for macos
'
?MacOS
Function _Call:Object( callableP:Byte Ptr, retTypeId:TTypeId, obj:Object=Null, args:Object[], argtypes:TTypeId[])
	Assert args.Length = argtypes.Length

	Local q:Int[MAX_CALL_ARGS + 2], sp:Byte Ptr = q
	
	If obj 'method call of an instance
		bbRefPushObject sp,obj
		sp:+4
	EndIf
	
	Local lret:Long
	If retTypeId = LongTypeId Then
		Byte Ptr Ptr(sp)[0] = Byte Ptr Varptr lret
		sp :+ 4
	EndIf

	For Local i:Int = 0 Until args.Length
		If Int Ptr(sp) >= Int Ptr(q)+MAX_CALL_ARGS Then Throw "_Call() ERROR: Exceeded max args #1"
		sp = _Push( sp, argtypes[i], args[i])
	Next
	If Int Ptr(sp) > Int Ptr(q)+MAX_CALL_ARGS Then Throw "_Call() ERROR: Exceeded max args #2"
	
	Select retTypeId
		Case ByteTypeId, ShortTypeId, IntTypeId
			Local f(p0, p1, p2, p3, p4, p5, p6, p7) = callableP
			Return String.FromInt( f( q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7] ) )
		Case LongTypeId
			Local r:Long
			If obj Then
				Local f( p0, r:Long Var, p1,p2,p3,p4,p5,p6,p7) = callableP
				f( q[0], r, q[1],q[2],q[3],q[4],q[5],q[6],q[7] )
			Else
				Local f( r:Long Var, p0, p1,p2,p3,p4,p5,p6,p7) = callableP
				f( r, q[0], q[1],q[2],q[3],q[4],q[5],q[6],q[7] )
			EndIf
			Return String.FromLong(r)
		Case FloatTypeId
			Local f:Float(p0, p1, p2, p3, p4, p5, p6, p7) = callableP
			Return String.FromFloat( f( q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7] ) )
		Case DoubleTypeId
			Local f:Double(p0, p1, p2, p3, p4, p5, p6, p7) = callableP
			Return String.FromDouble( f( q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7] ) )
		Default
			If retTypeId.ExtendsType(PointerTypeId) Or retTypeId.ExtendsType(FunctionTypeId) Then
				Local f:Int(p0, p1, p2, p3, p4, p5, p6, p7) = callableP
				Return String.FromInt( f( q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7] ) )
			Else
				Local f:Object(p0, p1, p2, p3, p4, p5, p6, p7) = callableP
				Return f( q[0],q[1],q[2],q[3],q[4],q[5],q[6],q[7] )
			EndIf
	End Select
End Function
?

'
' asembly path for calling methods. for linux and win32
'
?Not MacOS
Function _Call:Object( callableP:Byte Ptr, retTypeId:TTypeId, obj:Object=Null, args:Object[], argtypes:TTypeId[])
	Assert args.Length = argtypes.Length

	Local q:Int[MAX_CALL_ARGS + 2], sp:Byte Ptr = q
	
	If obj 'method call of an instance
		bbRefPushObject sp,obj
		sp:+4
	EndIf
	
	Local lret:Long
	If retTypeId = LongTypeId Then
		Byte Ptr Ptr(sp)[0] = Byte Ptr Varptr lret
		sp :+ 4
	EndIf

	For Local i:Int = 0 Until args.Length
		If Int Ptr(sp) >= Int Ptr(q)+MAX_CALL_ARGS Then Throw "_Call() ERROR: Exceeded max args #1"
		sp = _Push( sp, argtypes[i], args[i])
	Next
	If Int Ptr(sp) > Int Ptr(q)+MAX_CALL_ARGS Then Throw "_Call() ERROR: Exceeded max args #2"
	
	Local size:Int = sp - Byte Ptr q
	Select retTypeId
		Case ByteTypeId, ShortTypeId, IntTypeId
			Return String.FromInt( bbCallMethod( callableP, q, size) )
		Case LongTypeId
			bbCallMethod( callableP, q, size)
			Return String.FromInt( lret )
		Case FloatTypeId
			Return String.FromFloat( bbCallMethod_Float( callableP, q, size) )
		Case DoubleTypeId
			Return String.FromDouble( bbCallMethod_Double( callableP, q, size) )
		Default
			If retTypeId.ExtendsType(PointerTypeId) Or retTypeId.ExtendsType(FunctionTypeId) Then
				Return String.FromInt( bbCallMethod( callableP, q, size) )
			Else
				Return bbCallMethod_Object( callableP, q, size)
			EndIf
	End Select
End Function
?

Function TypeTagForId$( id:TTypeId )
	If id.ExtendsType( ArrayTypeId )
		Return "[]"+TypeTagForId( id.ElementType() )
	EndIf
	If id.ExtendsType( ObjectTypeId )
		Return ":"+id.Name()
	EndIf
	If id.ExtendsType( PointerTypeId )
		Local t:TTypeId = id.ElementType()
		If t Then Return "*"+TypeTagForId(t)
		Return "*"
	EndIf
	If id.ExtendsType( FunctionTypeId )
		Local s:String
		For Local t:TTypeId = EachIn id._argTypes
			If s Then s :+ ","
			s :+ TypeTagForId(t)
		Next
		s = "(" + s + ")"
		If id._retType Then s :+ TypeTagForId(id._retType)
		Return s
	EndIf
	Select id
		Case ByteTypeId Return "b"
		Case ShortTypeId Return "s"
		Case IntTypeId Return "i"
		Case LongTypeId Return "l"
		Case FloatTypeId Return "f"
		Case DoubleTypeId Return "d"
		Case StringTypeId Return "$"
		Case NullTypeId Return "Null"
	End Select
	Throw "~q" + id.Name() + "~q was unexpected at this time"
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
		Local i=ty.FindLast( "." )
		If i<>-1 ty=ty[i+1..]
		Return TTypeId.ForName( ty )
	EndIf
	If ty.StartsWith( "(" ) Then
		Local t:String[]
		Local idx:Int = ty.FindLast(")")
		If idx > 0 Then
			t = [ ty[1..idx], ty[idx+1..] ]
		Else
			t = [ ty[1..], "" ]
		EndIf
		Local retType:TTypeId=TypeIdForTag( t[1] ), argTypes:TTypeId[]
		If t[0].length>0 Then
			Local i,b,q$=t[0], args:TList=New TList
			#first_loop
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
				Case Asc( "(" )
					Local level:Int = 1
					i:+1
					While i<q.Length
						If q[i] = Asc(",") Then
							If level = 0 Then Continue first_loop
						ElseIf q[i] = Asc(")") Then
							level :- 1
						ElseIf q[i] = Asc("(") Then 
							level :+ 1
						EndIf
						i:+1
					Wend
				Default
					i:+1
				End Select
			Wend
			If b < q.Length Then args.AddLast q[b..]
			
			argTypes=New TTypeId[args.Count()]

			i=0
			For Local s:String = EachIn args
				argTypes[i]=TypeIdForTag( s )
				If Not argTypes[i] Then argTypes[i] = ObjectTypeId
				i:+1
			Next
		EndIf
		If Not retType Then retType = ObjectTypeId
		retType._functionType = Null
		Return retType.FunctionType(argTypes)
	EndIf
	If ty.StartsWith( "*" ) Then
		ty = ty[1..]
		Local id:TTypeId = TypeIdForTag( ty )
		If id Then
			id._pointerType = Null
			id = id.PointerType()
		EndIf
		Return id
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
	Local i=0
	While i<meta.length
		Local e=meta.Find( "=",i )
		If e=-1 Throw "Malformed meta data"
		Local k$=meta[i..e],v$
		i=e+1
		If i<meta.length And meta[i]=Asc("~q")
			i:+1
			Local e=meta.Find( "~q",i )
			If e=-1 Throw "Malformed meta data"
			v=meta[i..e]
			i=e+1
		Else
			Local e=meta.Find( " ",i )
			If e=-1 e=meta.length
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
bbdoc: Primitive pointer type
End Rem
Global PointerTypeId:TTypeId=New TTypeId.Init( "Ptr",4 )

Rem
bbdoc: Primitive function type
End Rem
Global FunctionTypeId:TTypeId=New TTypeId.Init( "Null()",4 )

Rem
bbdoc: Primitive null type
End Rem
Global NullTypeId:TTypeId=New TTypeId.Init( "Null",4 )

' finish setup of array type
ArrayTypeId._ElementType = NullTypeId

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

	Method Init:TField( name$,typeId:TTypeId,meta$,index )
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
	bbdoc: Get pointer field value
	End Rem
	Method GetPointer:Byte Ptr( obj:Object)
		Return Byte Ptr GetString(obj).ToInt()
	EndMethod		
	
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
		
	Rem
	bbdoc: Set pointer field value
	End Rem
	Method SetPointer( obj:Object, value:Byte Ptr)
		SetString(obj, String.FromInt(Int value))
	EndMethod

	Rem
	bbdoc: Get the pointer to the field of an instance
	about: this returns a @{direct pointer to the instance field}
	End Rem
	Method FieldPtr:Byte Ptr( obj:Object)
		Return bbRefFieldPtr( obj, _index)
	EndMethod
	
	Rem
	bbdoc: Invoke function pointer field
	End Rem
	Method Invoke:Object( obj:Object, args:Object[] = Null)
		Return _Call( GetPointer(obj), _typeId.ReturnType(), Null, args, _typeId.ArgTypes())
	EndMethod	
	
	Field _index
	
End Type

Rem
bbdoc: Type method
End Rem
Type TMethod Extends TMember

	Method Init:TMethod( name$,typeId:TTypeId,meta$,selfTypeId:TTypeId,index )
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
		Return Self
	End Method
	
	Rem
	bbdoc: Get method arg types
	End Rem
	Method ArgTypes:TTypeId[]()
		Return _typeId._argTypes
	End Method
		
	Rem
	bbdoc: Get method return type
	End Rem
	Method ReturnType:TTypeId()
		Return _typeId._retType
	End Method

	Rem
	bbdoc: Get method function pointer
	endrem
	Method FunctionPtr:Byte Ptr( obj:Object)
		If _fptr Then Return _fptr
		If _index < 65536 Then
			_fptr = bbRefMethodPtr( obj ,_index)
		EndIf
		Return _fptr
	End Method

	Rem
	bbdoc: Invoke method
	End Rem
	Method Invoke:Object( obj:Object,args:Object[] = Null )
		Return _Call( FunctionPtr(obj), ReturnType(), obj, args, ArgTypes() )
	End Method
	
	Field _selfTypeId:TTypeId,_index
	Field _fptr:Byte Ptr
End Type

Rem
bbdoc: Type function
endrem
Type TFunction Extends TMember
	Method Init:TFunction(name:String, typeId:TTypeId, meta:String, selfTypeId:TTypeId, index:Int)
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
		Return Self
	End Method

	Rem
	bbdoc: Get function arg types
	End Rem
	Method ArgTypes:TTypeId[]()
		Return _typeId._argTypes
	End Method
	
	Rem
	bbdoc: Get function return type
	End Rem
	Method ReturnType:TTypeId()
		Return _typeId._retType
	End Method
		
	Rem
	bbdoc: Get function pointer.
	endrem
	Method FunctionPtr:Byte Ptr( obj:Object)
		If _fptr Then Return _fptr
		If _index < 65536 Then
			If Not obj Then
				_fptr = Byte Ptr Int Ptr(_selfTypeId._class + _index)[0]
			Else
				_fptr = bbRefMethodPtr( obj ,_index)
			EndIf
		EndIf
		Return _fptr
	End Method
	
	Rem
	bbdoc: Invoke type function
	endrem	
	Method Invoke:Object( obj:Object, args:Object[] = Null)
		Return _Call( FunctionPtr(obj), ReturnType(), Null, args, ArgTypes())
	End Method
	
	Field _selfTypeId:TTypeId, _fptr:Byte Ptr, _index:Int
EndType
	
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
	bbdoc: Get pointer type
	End Rem
	Method PointerType:TTypeId()
		If Not _pointerType Then
			_pointerType = New TTypeId.Init( _name + " Ptr", 4)
			_pointerType._elementType = Self
			If _super Then
				_pointerType._super = _super.PointerType()
				_pointerType._TypeTag = TypeTagForId(_pointerType).ToCString()
			Else
				_pointerType._super = PointerTypeId
				_pointerType._TypeTag = "*".ToCString()
			EndIf
		EndIf
		Return _pointerType
	End Method
		
	Rem
	bbdoc: Get function pointer type
	End Rem
	Method FunctionType:TTypeId( args:TTypeId[]=Null)
		If Not _functionType Then
			Local s:String
			For Local t:TTypeId = EachIn args
				If s Then s :+ ","
				s :+ t.Name()
			Next
			_functionType = New TTypeId.Init( _name + "(" + s + ")", 4)
			_functionType._retType = Self
			_functionType._argTypes = args
			If _super Then
				_functionType._super = _super.FunctionType()
			Else
				_functionType._super = FunctionTypeId
			EndIf
		EndIf
		Return _functionType
	End Method
		
	Rem
	bbdoc: Get function return type
	End Rem
	Method ReturnType:TTypeId()
		If Not _retType Then Throw "TypeID is not a function type"
		Return _retType
	End Method
		
	Rem
	bbdoc: Get function argument types
	End Rem
	Method ArgTypes:TTypeId[]()
		If Not _retType Then Throw "TypeID is not a function type"
		Return _argTypes
	End Method		
	
	Rem
	bbdoc: Determine if type extends a type
	End Rem
	Method ExtendsType( typeId:TTypeId )
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
	bbdoc: Get list of methods
	about: Only returns methods declared in this type, not in super types.
	End Rem
	Method Methods:TList()
		Return _methods
	End Method
	
	Rem
	bbdoc: Get ist of functions
	about: Only returns functions declared in this type, not in super types.
	endrem
	Method Functions:TList()
		Return _functions
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
	about: Returns a list of all methods in type hierarchy
	End Rem
	Method EnumMethods:TList( list:TList=Null )
		Function cmp_by_index:Int( a:TMethod, b:TMethod)
			Return a._index - b._index
		EndFunction
		
		If Not list list=New TList
		If _super And _super <> Self Then _super.EnumMethods list
		For Local t:TMethod=EachIn _methods
			list.AddLast t
		Next
		'FIX: remove overridden methods
'		list.Sort()
'		Local prev:TMethod
'		For Local t:TMethod = EachIn list
'			If prev Then
'				If (t._index - prev._index) = 0 Then list.Remove(prev)
'			EndIf
'			prev = t
'		Next
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
	Method NewArray:Object( length, dims:Int[] = Null )
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
	bbdoc: Create a new array slice from another array
	End Rem
	Method ArraySlice:Object( a:Object, start:Int = 0, stop:Int = -1 )
		If Not _elementType Throw "TypeID is not an array type"
		Local tag:Byte Ptr=_elementType._typeTag
		If Not tag
			tag=TypeTagForId( _elementType ).ToCString()
			_elementType._typeTag=tag
		EndIf
		If stop < 0 Then
			stop = bbRefArrayLength( a, 0)
		EndIf
		Return bbArraySlice( tag, a, start, stop)
	End Method
	
	Rem
	bbdoc: Get array length
	End Rem
	Method ArrayLength( array:Object, dim:Int = 0 )
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
	Method GetArrayElement:Object( array:Object,index )
		If Not _elementType Throw "TypeID is not an array type"
		Local p:Byte Ptr=bbRefArrayElementPtr( _elementType._size,array,index )
		Return _Get( p,_elementType )
	End Method
	
	Rem
	bbdoc: Set an array element
	End Rem
	Method SetArrayElement( array:Object,index,value:Object )
		If Not _elementType Throw "TypeID is not an array type"
		Local p:Byte Ptr=bbRefArrayElementPtr( _elementType._size,array,index )
		_Assign p,_elementType,value
	End Method
	
	Rem
	bbdoc: Get Type by name
	End Rem
	Function ForName:TTypeId( name$ )
		_Update
		' arrays
		If name.EndsWith( "[]" )
			name=name[..name.length-2].Trim()
			Local elementType:TTypeId = ForName( name )
			If Not elementType Then Return Null
			Return elementType.ArrayType()
		' pointers
		ElseIf name.EndsWith( "Ptr" )
			name=name[..name.length-4].Trim()
			If Not name Then Return Null
			Local baseType:TTypeId = ForName( name )
			If baseType Then
				' check for valid pointer base types
				Select baseType
					Case ByteTypeId, ShortTypeId, IntTypeId, LongTypeId, FloatTypeId, DoubleTypeId
						Return baseType.PointerType()
					Default
						If baseType.ExtendsType(PointerTypeId) Then Return baseType.PointerType()
				EndSelect
			EndIf
			Return Null
		' function pointers
		ElseIf name.EndsWith( ")" )
			' check if its in the table already
			Local t:TTypeId = TTypeId( _nameMap.ValueForKey( name.ToLower() ) )
			If t Then Return t
			Local i:Int = name.Find("(")
			Local ret:TTypeId = ForName( name[..i].Trim())
			Local typs:TTypeId[]
			If Not ret Then ret = NullTypeId
			If ret Then
				Local params:String = name[i+1..name.Length-1].Trim()
				If params Then
					Local args:String[] = params.Split(",")
					If args.Length >= 1 And args[0] Then
						typs = New TTypeId[args.Length]
						For Local i:Int = 0 Until args.Length
							typs[i] = ForName(args[i].Trim())
							If Not typs[i] Then typs[i] = ObjectTypeId
						Next
					EndIf
				EndIf
				ret._functionType = Null
				Return ret.FunctionType(typs)
			EndIf
		Else
			' regular type name lookup
			Return TTypeId( _nameMap.ValueForKey( name.ToLower() ) )
		EndIf
	End Function	
Rem
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
EndRem

	Rem
	bbdoc: Get Type by object
	End Rem	
	Function ForObject:TTypeId( obj:Object )
		_Update
		Local class=bbRefGetObjectClass( obj )
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
	
	Method Init:TTypeId( name$,size,class=0,supor:TTypeId=Null )
		_name=name
		_size=size
		_class=class
		_super=supor
		_consts=New TList
		_fields=New TList
		_methods=New TList
		_functions=New TList
		_nameMap.Insert _name.ToLower(),Self
		If class _classMap.Insert New TClass.SetClass( class ),Self
		Return Self
	End Method
	
	Method SetClass:TTypeId( class )
		Local debug=(Int Ptr class)[2]
		Local name$=String.FromCString( Byte Ptr( (Int Ptr debug)[1] ) ),meta$
		Local i=name.Find( "{" )
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
		Local count,p:Int Ptr=bbObjectRegisteredTypes( count )
		If count=_count Return
		Local list:TList=New TList
		For Local i=_count Until count
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
		_methods=New TList
		_functions=New TList
		_super=TTypeId( _classMap.ValueForKey( New TClass.SetClass( (Int Ptr _class)[0] ) ) )
		If Not _super _super=ObjectTypeId
		If Not _super._derived _super._derived=New TList
		_super._derived.AddLast Self
		
		Local debug=(Int Ptr _class)[2]
		Local p:Int Ptr=(Int Ptr debug)+2
		
		While p[0]
			Local id$=String.FromCString( Byte Ptr p[1] )
			Local ty$=String.FromCString( Byte Ptr p[2] )
			
			Local meta$
			Local i=ty.Find( "{" )
			If i<>-1
				meta=ty[i+1..ty.length-1]
				ty=ty[..i]
			EndIf

			Select p[0]
				Case 1	'const
					Local tt:TTypeId = TypeIdFortag(ty)
					If tt Then
						_consts.AddLast New TConstant.Init( id, tt, meta, p[3])
					EndIf
					
				Case 3	'field
					Local tt:TTypeId = TypeIdForTag(ty)
					If tt Then
						_fields.AddLast New TField.Init( id, tt, meta, p[3])
					EndIf
					
				Case 6	'method
					Local tt:TTypeId = TypeIdForTag(ty)
					If tt Then			
						_methods.AddLast New TMethod.Init( id, tt, meta, Self, p[3])
					EndIf
					
				Case 7	' function
					Local tt:TTypeId = TypeIdForTag(ty)
					If tt Then
						_functions.AddLast New TFunction.Init(id, tt, meta, Self, p[3])
					EndIf
			EndSelect
			p:+4
		Wend
	End Method
	
	Field _name$
	Field _meta$
	Field _class
	Field _size=4
	Field _consts:TList
	Field _fields:TList
	Field _methods:TList
	Field _functions:TList
	Field _super:TTypeId
	Field _derived:TList
	Field _arrayType:TTypeId
	Field _elementType:TTypeId
	Field _typeTag:Byte Ptr
	Field _pointerType:TTypeId
	Field _functionType:TTypeId, _argTypes:TTypeId[], _retType:TTypeId
	
	Global _count,_nameMap:TMap=New TMap,_classMap:TMap=New TMap
	
End Type