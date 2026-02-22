Rem
	====================================================================
	LuaEngine Class
	====================================================================

	LuaEngine allows to expose functionality of BlitzMax to Lua without
	much hassle.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2026 Ronny Otto, digidea.de

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
Import Pub.Lua
Import Brl.Retro
Import BRL.Reflection
Import Collections.TreeMap
Import "base.util.luaengine.c"
Import "base.util.logger.bmx"
Import "base.util.longmap.bmx"

Extern
	Function lua_tolightobject:Object( L:Byte Ptr,index:Int )
?debug
	' the debug varant contains additional checks
	Function lua_unboxobject:Object( L:Byte Ptr,index:Int, metaTable:Int)="BBOBJECT lua_unboxobject_debug(BBBYTE*, BBINT, BBINT)"
?not debug
	Function lua_unboxobject:Object( L:Byte Ptr,index:Int, metaTable:Int)="BBOBJECT lua_unboxobject(BBBYTE*, BBINT, BBINT)"
?
	'the "!" at the end tells to use the return value as raw pointer 
	'instead as "object". Omit the "!" if objects are to return!
	Function lua_boxobject:Int( L:Byte Ptr, obj:Object, metaTable:Int)="BBINT lua_boxobject(BBBYTE*, BBObject*, BBINT)!"
	Function lua_pushlightobject:Int( L:Byte Ptr,obj:Object )="BBINT lua_pushlightobject(BBBYTE*,BBObject*)!"
	Function lua_gcobject:Int( L:Byte Ptr )
	Function lua_tobbstring:String( L:Byte Ptr,index:Int )
	Function lua_pushbbstring:Int( L:Byte Ptr,s:String )

	Function Luaengine_bbRefObjectFieldPtr:Byte Ptr( obj:Object, offset:Size_t )
	Function Luaengine_bbRefAssignObject( p:Byte Ptr, obj:Object )
	Function Luaengine_bbRefGetSuperClass:Byte Ptr( obj:Object )
	Function Luaengine_bbRefGetObjectClass:Byte Ptr( obj:Object )
	'Function lua_LowerStringHash:ULong( L:Byte Ptr,index:Int )
	'Function lua_StringHash:ULong( L:Byte Ptr,index:Int )
	Function lua_LowerStringHash:UInt( L:Byte Ptr,index:Int )
	Function lua_StringHash:UInt( L:Byte Ptr,index:Int )
	
	Function strcmp_ascii_nocase:Int(a:Byte Ptr, b:Byte Ptr) = "BBINT strcmp_ascii_nocase(const char*, const char*)!"
End Extern


Type TCStringCaseInsensitiveComparator Implements IComparator<Byte Ptr>
	Method Compare:Int(a:Byte Ptr, b:Byte Ptr)
		Return strcmp_ascii_nocase(a, b)
	End Method
End Type


Type TLuaReflectionType
	Field typeID:TTypeID
	Field children:TTreeMap<Byte Ptr, TLuaReflectionChild>
	
	Method New()
		children = New TTreeMap<Byte Ptr, TLuaReflectionChild>(New TCStringCaseInsensitiveComparator)
	End Method
	
	Method Delete()
		'free children cstrings!
		For local b:Byte Ptr = EachIn children.Keys()
			MemFree(b)
		Next
	End Method
End Type


Type TLuaReflectionChild
	Field _ref:Byte Ptr 'globals, functions, methods
	Field member:TMember
	Field _args:Byte Ptr[10]
	Global _argsSize:Size_T = 10 * SizeOf(Byte Ptr Null)
	
	Method ArgReset()
		For local i:int = 0 until 10
			_args[i] = 0
		Next
	End Method

	Method ArgPush(index:Int, value:Int)
		Local p:Int Ptr = varptr _args[index]
		p[0] = value
	End Method

	Method ArgPush(index:Int, value:UInt)
		Local p:UInt Ptr = varptr _args[index]
		p[0] = value
	End Method

	Method ArgPush(index:Int, value:Long)
		Local p:Long Ptr = varptr _args[index]
		p[0] = value
	End Method

	Method ArgPush(index:Int, value:ULong)
		Local p:ULong Ptr = varptr _args[index]
		p[0] = value
	End Method

	Method ArgPush(index:Int, value:Size_T)
		Local p:Size_T Ptr = varptr _args[index]
		p[0] = value
	End Method

	Method ArgPush(index:Int, value:Float)
		Local p:Float Ptr = varptr _args[index]
		p[0] = value
	End Method
	
	Method ArgPush(index:Int, value:Double)
		Local p:Double Ptr = varptr _args[index]
		p[0] = value
	End Method

	Method ArgPush(index:Int, value:LongInt)
		Local p:LongInt Ptr = varptr _args[index]
		p[0] = value
	End Method

	Method ArgPush(index:Int, value:ULongInt)
		Local p:ULongInt Ptr = varptr _args[index]
		p[0] = value
	End Method

	Method ArgPush(index:Int, value:String)
		Local p:Byte Ptr = varptr _args[index]
		LuaEngine_bbRefAssignObject(p, value)
	End Method
	
	Method ArgPush(index:Int, value:Object, typeid:TTypeId)
		Local p:Byte Ptr = varptr _args[index]
		If value
			If typeid.ExtendsType(PointerTypeId) Or typeid.ExtendsType(FunctionTypeId) Then
?Not ptr64
				(Int Ptr p)[0]=value.ToString().ToInt()
?ptr64
				(Long Ptr p)[0]=value.ToString().ToLong()
?
			EndIf
		EndIf
		Luaengine_bbRefAssignObject(p, value)
	End Method


	Function _CallFunction:Int( p:Byte Ptr, retTypeId:TTypeId, argsPointer:Byte Ptr[], usedArgCount:Int, luaState:Byte Ptr, objMetaTable:Int)
		Local q:Byte Ptr[] = argsPointer 'shorter var name :)

		Select retTypeId
		Case ByteTypeId,ShortTypeId,IntTypeId
			Select usedArgCount
				Case 0
					Local f:Int()=p
					lua_pushinteger(luaState, f() )
				Case 1
					Local f:Int(p0:Byte Ptr)=p
					lua_pushinteger(luaState, f(q[0]) )
				Case 2
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushinteger(luaState, f(q[0], q[1]) )
				Case 3
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushinteger(luaState, f(q[0], q[1], q[2]) )
				Case 4
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushinteger(luaState, f(q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushinteger(luaState, f(q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushinteger(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushinteger(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushinteger(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
	?Not ptr64
		Case UIntTypeId,SizetTypeId
	?ptr64
		Case UIntTypeId
	?
			Select usedArgCount
				Case 0
					Local f:UInt()=p
					lua_pushnumber(luaState, f() )
				Case 1
					Local f:UInt(p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0]) )
				Case 2
					Local f:UInt(p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1]) )
				Case 3
					Local f:UInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2]) )
				Case 4
					Local f:UInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:UInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:UInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:UInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:UInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case LongTypeId
			Select usedArgCount
				Case 0
					Local f:Long()=p
					lua_pushnumber(luaState, f() )
				Case 1
					Local f:Long(p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0]) )
				Case 2
					Local f:Long(p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1]) )
				Case 3
					Local f:Long(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2]) )
				Case 4
					Local f:Long(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:Long(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:Long(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:Long(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:Long(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
	?Not ptr64
		Case ULongTypeId
	?ptr64
		Case ULongTypeId,SizetTypeId
	?
			Select usedArgCount
				Case 0
					Local f:ULong()=p
					lua_pushnumber(luaState, f() )
				Case 1
					Local f:ULong(p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0]) )
				Case 2
					Local f:ULong(p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1]) )
				Case 3
					Local f:ULong(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2]) )
				Case 4
					Local f:ULong(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:ULong(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:ULong(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:ULong(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:ULong(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case FloatTypeId
			Select usedArgCount
				Case 0
					Local f:Float()=p
					lua_pushnumber(luaState, f() )
				Case 1
					Local f:Float(p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0]) )
				Case 2
					Local f:Float(p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1]) )
				Case 3
					Local f:Float(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2]) )
				Case 4
					Local f:Float(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:Float(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:Float(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:Float(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:Float(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case DoubleTypeId
			Select usedArgCount
				Case 0
					Local f:Double()=p
					lua_pushnumber(luaState, f() )
				Case 1
					Local f:Double(p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0]) )
				Case 2
					Local f:Double(p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1]) )
				Case 3
					Local f:Double(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2]) )
				Case 4
					Local f:Double(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:Double(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:Double(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:Double(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:Double(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case VoidTypeId
			Select usedArgCount
				Case 0
					Local f:Int()=p
					f()
				Case 1
					Local f:Int(p0:Byte Ptr)=p
					f(q[0])
				Case 2
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr)=p
					f(q[0], q[1])
				Case 3
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					f(q[0], q[1], q[2])
				Case 4
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					f(q[0], q[1], q[2], q[3])
				Case 5
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					f(q[0], q[1], q[2], q[3], q[4])
				Case 6
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					f(q[0], q[1], q[2], q[3], q[4], q[5])
				Case 7
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					f(q[0], q[1], q[2], q[3], q[4], q[5], q[6])
				Default
					Local f:Int(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7])
			End Select
		Case StringTypeId
			Select usedArgCount
				Case 0
					Local f:String()=p
					lua_pushbbstring(luaState, f() )
				Case 1
					Local f:String(p0:Byte Ptr)=p
					lua_pushbbstring(luaState, f(q[0]) )
				Case 2
					Local f:String(p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushbbstring(luaState, f(q[0], q[1]) )
				Case 3
					Local f:String(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushbbstring(luaState, f(q[0], q[1], q[2]) )
				Case 4
					Local f:String(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushbbstring(luaState, f(q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:String(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushbbstring(luaState, f(q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:String(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushbbstring(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:String(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushbbstring(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:String(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushbbstring(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case LongIntTypeId
			Select usedArgCount
				Case 0
					Local f:LongInt()=p
					lua_pushnumber(luaState, f() )
				Case 1
					Local f:LongInt(p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0]) )
				Case 2
					Local f:LongInt(p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1]) )
				Case 3
					Local f:LongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2]) )
				Case 4
					Local f:LongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:LongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:LongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:LongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:LongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case ULongIntTypeId
			Select usedArgCount
				Case 0
					Local f:ULongInt()=p
					lua_pushnumber(luaState, f() )
				Case 1
					Local f:ULongInt(p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0]) )
				Case 2
					Local f:ULongInt(p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1]) )
				Case 3
					Local f:ULongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2]) )
				Case 4
					Local f:ULongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:ULongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:ULongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:ULongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:ULongInt(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Default
			If retTypeId.ExtendsType(PointerTypeId) Or retTypeId.ExtendsType(FunctionTypeId) Then
	?Not ptr64
				Select usedArgCount
					Case 0
						Local f:Byte Ptr()=p
						lua_pushinteger(luaState, Int f())
					Case 1
						Local f:Byte Ptr(p0:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(q[0]))
					Case 2
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(q[0], q[1]))
					Case 3
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(q[0], q[1], q[2]))
					Case 4
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(q[0], q[1], q[2], q[3]))
					Case 5
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(q[0], q[1], q[2], q[3], q[4]))
					Case 6
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(q[0], q[1], q[2], q[3], q[4], q[5]))
					Case 7
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]))
					Default
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]))
				End Select
	?ptr64
				Select usedArgCount
					Case 0
						Local f:Byte Ptr()=p
						lua_pushinteger(luaState, Long f())
					Case 1
						Local f:Byte Ptr(p0:Byte Ptr)=p
						lua_pushinteger(luaState, Long f(q[0]))
					Case 2
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr)=p
						lua_pushinteger(luaState, Long f(q[0], q[1]))
					Case 3
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
						lua_pushinteger(luaState, Long f(q[0], q[1], q[2]))
					Case 4
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
						lua_pushinteger(luaState, Long f(q[0], q[1], q[2], q[3]))
					Case 5
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
						lua_pushinteger(luaState, Long f(q[0], q[1], q[2], q[3], q[4]))
					Case 6
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
						lua_pushinteger(luaState, Long f(q[0], q[1], q[2], q[3], q[4], q[5]))
					Case 7
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
						lua_pushinteger(luaState, Long f(q[0], q[1], q[2], q[3], q[4], q[5], q[6]))
					Default
						Local f:Byte Ptr(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
						lua_pushinteger(luaState, Long f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]))
				End Select
	?
			Else
				Local result:Object
				Select usedArgCount
					Case 0
						Local f:Object()=p
						result = f()
					Case 1
						Local f:Object(p0:Byte Ptr)=p
						result = f(q[0])
					Case 2
						Local f:Object(p0:Byte Ptr, p1:Byte Ptr)=p
						result = f(q[0], q[1])
					Case 3
						Local f:Object(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
						result = f(q[0], q[1], q[2])
					Case 4
						Local f:Object(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
						result = f(q[0], q[1], q[2], q[3])
					Case 5
						Local f:Object(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
						result = f(q[0], q[1], q[2], q[3], q[4])
					Case 6
						Local f:Object(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
						result = f(q[0], q[1], q[2], q[3], q[4], q[5])
					Case 7
						Local f:Object(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
						result = f(q[0], q[1], q[2], q[3], q[4], q[5], q[6])
					Default
						Local f:Object(p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
						result = f(q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7])
				End Select

				If retTypeId.ExtendsType(ArrayTypeId)
					TLuaEngine.lua_pusharray(luaState, result, objMetaTable, retTypeId)
				Else
					TLuaEngine.lua_pushobject(luaState, result, objMetaTable)
				EndIf
			End If
		End Select
		
		If retTypeId = VoidTypeId
			Return 0 'nothing pushed to the stack
		Else
			Return 1 'pushed 1 element to the stack
		EndIf
	End Function

	Function _CallMethod:Int( p:Byte Ptr, retTypeId:TTypeId, obj:Object, argsPointer:Byte Ptr[], usedArgCount:Int, luaState:Byte Ptr, objMetaTable:Int)
		Local q:Byte Ptr[] = argsPointer 'shorter var name :)

		Select retTypeId
		Case ByteTypeId,ShortTypeId,IntTypeId
			Select usedArgCount
				Case 0
					Local f:Int(m:Object)=p
					lua_pushinteger(luaState, f(obj))
				Case 1
					Local f:Int(m:Object, p0:Byte Ptr)=p
					lua_pushinteger(luaState, f(obj, q[0]) )
				Case 2
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushinteger(luaState, f(obj, q[0], q[1]) )
				Case 3
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushinteger(luaState, f(obj, q[0], q[1], q[2]) )
				Case 4
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushinteger(luaState, f(obj, q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushinteger(luaState, f(obj, q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushinteger(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushinteger(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushinteger(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
	?Not ptr64
		Case UIntTypeId,SizetTypeId
	?ptr64
		Case UIntTypeId
	?
			Select usedArgCount
				Case 0
					Local f:UInt(m:Object)=p
					lua_pushnumber(luaState, f(obj) )
				Case 1
					Local f:UInt(m:Object, p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0]) )
				Case 2
					Local f:UInt(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1]) )
				Case 3
					Local f:UInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2]) )
				Case 4
					Local f:UInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:UInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:UInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:UInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:UInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case LongTypeId
			Select usedArgCount
				Case 0
					Local f:Long(m:Object)=p
					lua_pushnumber(luaState, f(obj) )
				Case 1
					Local f:Long(m:Object, p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0]) )
				Case 2
					Local f:Long(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1]) )
				Case 3
					Local f:Long(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2]) )
				Case 4
					Local f:Long(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:Long(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:Long(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:Long(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:Long(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
	?Not ptr64
		Case ULongTypeId
	?ptr64
		Case ULongTypeId,SizetTypeId
	?
			Select usedArgCount
				Case 0
					Local f:ULong(m:Object)=p
					lua_pushnumber(luaState, f(obj) )
				Case 1
					Local f:ULong(m:Object, p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0]) )
				Case 2
					Local f:ULong(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1]) )
				Case 3
					Local f:ULong(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2]) )
				Case 4
					Local f:ULong(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:ULong(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:ULong(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:ULong(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:ULong(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case FloatTypeId
			Select usedArgCount
				Case 0
					Local f:Float(m:Object)=p
					lua_pushnumber(luaState, f(obj) )
				Case 1
					Local f:Float(m:Object, p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0]) )
				Case 2
					Local f:Float(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1]) )
				Case 3
					Local f:Float(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2]) )
				Case 4
					Local f:Float(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:Float(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:Float(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:Float(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:Float(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case DoubleTypeId
			Select usedArgCount
				Case 0
					Local f:Double(m:Object)=p
					lua_pushnumber(luaState, f(obj) )
				Case 1
					Local f:Double(m:Object, p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0]) )
				Case 2
					Local f:Double(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1]) )
				Case 3
					Local f:Double(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2]) )
				Case 4
					Local f:Double(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:Double(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:Double(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:Double(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:Double(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case LongIntTypeId
			Select usedArgCount
				Case 0
					Local f:LongInt(m:Object)=p
					lua_pushnumber(luaState, f(obj) )
				Case 1
					Local f:LongInt(m:Object, p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0]) )
				Case 2
					Local f:LongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1]) )
				Case 3
					Local f:LongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2]) )
				Case 4
					Local f:LongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:LongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:LongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:LongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:LongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case ULongIntTypeId
			Select usedArgCount
				Case 0
					Local f:ULongInt(m:Object)=p
					lua_pushnumber(luaState, f(obj) )
				Case 1
					Local f:ULongInt(m:Object, p0:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0]) )
				Case 2
					Local f:ULongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1]) )
				Case 3
					Local f:ULongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2]) )
				Case 4
					Local f:ULongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:ULongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:ULongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:ULongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:ULongInt(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushnumber(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Case VoidTypeId
			Select usedArgCount
				Case 0
					Local f:Int(m:Object)=p
					f(obj)
				Case 1
					Local f:Int(m:Object, p0:Byte Ptr)=p
					f(obj, q[0])
				Case 2
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					f(obj, q[0], q[1])
				Case 3
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					f(obj, q[0], q[1], q[2])
				Case 4
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					f(obj, q[0], q[1], q[2], q[3])
				Case 5
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					f(obj, q[0], q[1], q[2], q[3], q[4])
				Case 6
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					f(obj, q[0], q[1], q[2], q[3], q[4], q[5])
				Case 7
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6])
				Default
					Local f:Int(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7])
			End Select
		Case StringTypeId
			Local result:Object
				Select usedArgCount
				Case 0
					Local f:String(m:Object)=p
					lua_pushbbstring(luaState, f(obj) )
				Case 1
					Local f:String(m:Object, p0:Byte Ptr)=p
					lua_pushbbstring(luaState, f(obj, q[0]) )
				Case 2
					Local f:String(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
					lua_pushbbstring(luaState, f(obj, q[0], q[1]) )
				Case 3
					Local f:String(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
					lua_pushbbstring(luaState, f(obj, q[0], q[1], q[2]) )
				Case 4
					Local f:String(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
					lua_pushbbstring(luaState, f(obj, q[0], q[1], q[2], q[3]) )
				Case 5
					Local f:String(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
					lua_pushbbstring(luaState, f(obj, q[0], q[1], q[2], q[3], q[4]) )
				Case 6
					Local f:String(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
					lua_pushbbstring(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5]) )
				Case 7
					Local f:String(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
					lua_pushbbstring(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]) )
				Default
					Local f:String(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
					lua_pushbbstring(luaState, f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]) )
			End Select
		Default
			If retTypeId.ExtendsType(PointerTypeId) Or retTypeId.ExtendsType(FunctionTypeId) Then
	?Not ptr64
				Select usedArgCount
					Case 0
						Local f:Byte Ptr(m:Object)=p
						lua_pushinteger(luaState, Int f(obj))
					Case 1
						Local f:Byte Ptr(m:Object, p0:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(obj, q[0]))
					Case 2
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(obj, q[0], q[1]))
					Case 3
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(obj, q[0], q[1], q[2]))
					Case 4
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(obj, q[0], q[1], q[2], q[3]))
					Case 5
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(obj, q[0], q[1], q[2], q[3], q[4]))
					Case 6
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(obj, q[0], q[1], q[2], q[3], q[4], q[5]))
					Case 7
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]))
					Default
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
						lua_pushinteger(luaState, Int f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]))
				End Select
	?ptr64
				Select usedArgCount
					Case 0
						Local f:Byte Ptr(m:Object)=p
						lua_pushnumber(luaState, Long f(obj))
					Case 1
						Local f:Byte Ptr(m:Object, p0:Byte Ptr)=p
						lua_pushnumber(luaState, Long f(obj, q[0]))
					Case 2
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
						lua_pushnumber(luaState, Long f(obj, q[0], q[1]))
					Case 3
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
						lua_pushnumber(luaState, Long f(obj, q[0], q[1], q[2]))
					Case 4
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
						lua_pushnumber(luaState, Long f(obj, q[0], q[1], q[2], q[3]))
					Case 5
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
						lua_pushnumber(luaState, Long f(obj, q[0], q[1], q[2], q[3], q[4]))
					Case 6
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
						lua_pushnumber(luaState, Long f(obj, q[0], q[1], q[2], q[3], q[4], q[5]))
					Case 7
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
						lua_pushnumber(luaState, Long f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6]))
					Case 8
						Local f:Byte Ptr(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
						lua_pushnumber(luaState, Long f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7]))
				End Select
	?
			Else
				Local result:Object
				Select usedArgCount
					Case 0
						Local f:Object(m:Object)=p
						result = f(obj)
					Case 1
						Local f:Object(m:Object, p0:Byte Ptr)=p
						result = f(obj, q[0])
					Case 2
						Local f:Object(m:Object, p0:Byte Ptr, p1:Byte Ptr)=p
						result = f(obj, q[0], q[1])
					Case 3
						Local f:Object(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr)=p
						result = f(obj, q[0], q[1], q[2])
					Case 4
						Local f:Object(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr)=p
						result = f(obj, q[0], q[1], q[2], q[3])
					Case 5
						Local f:Object(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr)=p
						result = f(obj, q[0], q[1], q[2], q[3], q[4])
					Case 6
						Local f:Object(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr)=p
						result = f(obj, q[0], q[1], q[2], q[3], q[4], q[5])
					Case 7
						Local f:Object(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr)=p
						result = f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6])
					Default
						Local f:Object(m:Object, p0:Byte Ptr, p1:Byte Ptr, p2:Byte Ptr, p3:Byte Ptr, p4:Byte Ptr, p5:Byte Ptr, p6:Byte Ptr, p7:Byte Ptr)=p
						result = f(obj, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7])
				End Select

				If retTypeId.ExtendsType(ArrayTypeId)
					TLuaEngine.lua_pusharray(luaState, result, objMetaTable, retTypeId)
				Else
					TLuaEngine.lua_pushobject(luaState, result, objMetaTable)
				EndIf
			End If
		End Select

		If retTypeId = VoidTypeId
			Return 0 'nothing pushed to the stack
		Else
			Return 1 'pushed 1 element to the stack
		EndIf
	End Function
End Type

Struct SLuaCallArguments
	Field staticarray args_l:Long[10]
	Field staticarray args_d:Double[10]
	Field staticarray args_s:String[10]
	Field staticarray args_o:Object[10]
	Field staticarray args_type:Int[10] '1 = int, 2 = long, 11 = float, 12 = double, 21 = string, 31 = object, 32 = array
	Field length:Int
	

	Method Set(index:Int, value:Int)
		args_l[index] = value
		args_type[index] = 1
		if index >= length Then length = index + 1
	End Method

	Method Set(index:Int, value:Long)
		args_l[index] = value
		args_type[index] = 2
		if index >= length Then length = index + 1
	End Method

	Method Set(index:Int, value:Float)
		args_d[index] = value
		args_type[index] = 11
		if index >= length Then length = index + 1
	End Method

	Method Set(index:Int, value:Double)
		args_d[index] = value
		args_type[index] = 12
		if index >= length Then length = index + 1
	End Method

	Method Set(index:Int, value:String)
		args_s[index] = value
		args_type[index] = 21
		if index >= length Then length = index + 1
	End Method

	Method Set(index:Int, value:Object)
		args_o[index] = value
		args_type[index] = 31
		if index >= length Then length = index + 1
	End Method


	Method SetArray(index:Int, value:Object)
		args_o[index] = value
		args_type[index] = 32
		if index >= length Then length = index + 1
	End Method
	
	
	Method PushArgs(luaState:Byte Ptr, _objMetaTable:Int)
		For local i:int = 0 until length
			Select args_type[i]
				case 1
					lua_pushinteger(luaState, Int(args_l[i]))
				Case 2
					lua_pushnumber(luaState, args_l[i])
				Case 11
					lua_pushnumber(luaState, Float(args_d[i]))
				Case 12
					lua_pushnumber(luaState, args_d[i])
				Case 21
					lua_pushbbstring(luaState, args_s[i])
				Case 31
					TLuaEngine.lua_pushobject(luaState, args_o[i], _objMetaTable)
				Case 32
					TLuaEngine.lua_pusharray(luaState, args_o[i], _objMetaTable)
			End Select
		Next
	End Method
End Struct



Type TLuaEngine
	Field id:Int = 0

	' Pointer to current lua environment
	Field _luaState:Byte Ptr
	' current code
	Field _source:String = ""
	' path to lua script if used
	Field _sourceFile:String = ""
	' uri / path where the code resides or is "executed from"
	Field _currentWorkingDirectory:String = ""
	' reference to currently loaded (and compiled) code
	Field _chunk:Int = 0
	' reference to configured meta table for exposed blitzmax objects
	Field _objMetaTable:Int
	' reference to configured fenv (table)
	Field _functionEnvironmentRef:Int


	' load "all" modules or only some specific ones
	' eg. ["base","table"] or ["all"]
	Field _modulesToLoad:String[] = ["all"]
	' functions/calls to set "nil" before the script is run.
	' eg. ["os"]
	Field _blacklistedFunctions:String[]
	' which elements can get read without "_exposeToLua" metadata?
	Field _whiteListedTypes:TStringMap
	
	'key = class pointer
	'value = TLuaReflectionType
	Field _reflectionTypesCache:TTreeMap<byte ptr, TLuaReflectionType>


	Global lastID:Int = 0
	Global _engines:TLuaEngine[]
	Global _enginesMutex:TMutex = CreateMutex()



	Method New()
		TLuaEngine.lastID :+1
		id = TLuaEngine.lastID

		_whiteListedTypes = New TStringMap
		_whiteListedTypes.Insert("TList", "")
		_whiteListedTypes.Insert("TMap", "")

		CreateLuaInstance()
	End Method
	

	Method Delete()
		CleanupLuaInstance()
	End Method


	Function AddEngine(engine:TLuaEngine)
		LockMutex(_enginesMutex)
		_engines = _engines + [engine]
		UnlockMutex(_enginesMutex)
	End Function
	

	Function RemoveEngine(engine:TLuaEngine)
		LockMutex(_enginesMutex)
		For Local i:Int = 0 until _engines.length
			if _engines[i] = engine
				_engines = _engines[.. i] + _engines[i + 1 ..]
			EndIf
		Next
		UnlockMutex(_enginesMutex)
	End Function


	'find a previously added engine by a given lua state pointer
	Function FindEngine:TLuaEngine(LuaState:Byte Ptr)
		'When "FindEngine()" is used, most lua engines will most probably
		'already exist, so mutexing here would help with a lot of addings
		'and removals of engines while others already "run".
		'
		'What happens if an engine is added while a lua state needs to find 
		'their engine? It will still find "theirs"
		'What happens if an engine is removed while their lua state needs
		'to find it? It won't find it anymore and an error is thrown.
		'In this case removal of an engine should only happen once the
		'interaction stopped (should normally be the case ...same thread?)
		
		'So I (Ronny) removed the mutex protection here for the sake of
		'speed optimisation). This is because we only "execute" a lua
		'engine and its state from one thread 
		
		'LockMutex(_enginesMutex)
		Local result:TLuaEngine
		For local i:int = 0 until _engines.length
			If _engines[i]._luaState = LuaState 
				result = _engines[i]
				exit
			EndIf
		Next
		'if the engine was NOT found, we simply try again after 1 millisecond
		'which should be enough time for a concurrent "add/remove" to have
		'taken place
		If not result
			delay(1)
			For local i:int = 0 until _engines.length
				If _engines[i]._luaState = LuaState 
					result = _engines[i]
					exit
				EndIf
			Next
		EndIf
		'UnLockMutex(_enginesMutex)

		if not result
			TLogger.Log("TLuaEngine", "FindEngine(): engine not found.", LOG_ERROR)
			Throw "FindEngine(): engine not found. Forgot to AddEngine() it?"
		EndIf
		Return result
	End Function


	'register libraries to lua
	'available libs:
	'"base" = luaopen_base       "debug" = luaopen_debug
	'"io" = luaopen_io           "math" = luaopen_math
	'"os" = luaopen_os           "package" = luaopen_package
	'"string"= luaopen_string    "table" = luaopen_table
	Method RegisterLibraries:Int(libnames:String[] = Null)
		If Not libnames Then libnames = _modulesToLoad

		For Local lib:String = EachIn libnames
			Select lib.toLower()
				'registers all libs
				Case "all"      luaL_openlibs(_luaState)
				                Return True
				'register single libs
				Case "base"     lua_register(_luaState, lib, luaopen_base)
				Case "debug"    lua_register(_luaState, lib, luaopen_debug)
				Case "io"       lua_register(_luaState, lib, luaopen_io)
				Case "math"     lua_register(_luaState, lib, luaopen_math)
				Case "os"       lua_register(_luaState, lib, luaopen_os)
				Case "package"  lua_register(_luaState, lib, luaopen_package)
				Case "string"   lua_register(_luaState, lib, luaopen_string)
				Case "table"    lua_register(_luaState, lib, luaopen_table)
			End Select
		Next
		Return True
	End Method



	' Create a new lua instance / state, set the luaengine to act as
	' receiver for "self", "super" requests from lua.
	' So blitzmax objects can be requested from the lua instance and
	' this engine instance intercepts).
	Method CreateLuaInstance:int()
		TLogger.Log("TLuaEngine", "CreateLuaInstance: create Lua state and configure it.", LOG_DEBUG)
		If _luaState
			TLogger.Log("TLuaEngine", "Cleanup previous Lua state first...", LOG_DEBUG)
			CleanupLuaInstance()
		EndIf
		
 		' create a new lua instance
		_luaState = luaL_newstate()

		' === Register Libraries ===
		' register all libraries before configuring fenv and other things
		RegisterLibraries()


		' === Function environment table ===
		
		' stack size should be "0"

		' create function environment table (fenv)
		lua_newtable(_luaState) 'stack +1
		lua_pushvalue(_luaState, -1) 'stack +1
		' fetch fenv reference so we can reuse it later without having
		' to keep the fenv reference on the lua stack
		_functionEnvironmentRef	= luaL_ref(_luaState, LUA_REGISTRYINDEX) 'stack -1

        ' Set __index and other metatable functions
        ' Redirect access to TLuaEngine for "someobj:somemethod()"
        Lua_pushcfunction(_luaState, _HandleIndex)
        Lua_setfield(_luaState, -2, "__index")

		' not in use for now
        'Lua_pushcfunction(_luaState, _HandleSuper)
        'Lua_setfield(_luaState, -2, "__super")

		' activate metamethods __index, __newindex, __eq
		lua_setmetatable(_luaState, -2) 'stack -1


		' === Prepare _objMetaTable ===
		' we could reuse _functionEnvironmentRef but this allows
		' separation of concerns (global functions in fenv and object
		' specific behaviour via _objMetaTable

		' Create and configure a custom metatable for BlitzMax objects
		lua_newtable(_luaState) ' Create a new table to use as the metatable, Stack +1

		' Set the __index handler to redirect method calls to TLuaEngine
		lua_pushcfunction(_luaState, _HandleIndex) ' Push the __index handler function
		lua_setfield(_luaState, -2, "__index")

		' not in use for now
		' Set the __super handler for handling inheritance or other logic
		'lua_pushcfunction(_luaState, _HandleSuper) ' Push the __super handler function
		'lua_setfield(_luaState, -2, "__super")

		' Set the handler when lua wants to write to a property of 
		' an object using that meta table (here BlitzMax objects)
		lua_pushcfunction(_luaState, _HandleNewIndex)
		lua_setfield(_luaState, -2, "__newindex")

		' Set the handler when lua wants to compare objects using that
		' meta table (here BlitzMax objects)
		lua_pushcfunction(_luaState, _HandleEQ)
		lua_setfield(_luaState, -2, "__eq")

		' Set the handler when lua wants to garbage collect objects
		' (the objMetaTable is used for BlitzMax objects)
		lua_pushcfunction(_luaState, lua_gcobject)
		lua_setfield(_luaState, -2, "__gc")


		' Store the metatable in the registry for reuse
		_objMetaTable = luaL_ref(_luaState, LUA_REGISTRYINDEX) ' Stack -1

		TLogger.Log("TLuaEngine", "Lua state and metatables configured successfully.", LOG_DEBUG)
	End Method
	

	Method CleanupLuaInstance()
		if _luaState
			If _functionEnvironmentRef <> 0
				luaL_unref(_luaState, LUA_REGISTRYINDEX, _functionEnvironmentRef)
			EndIf
			If _chunk <> 0
				luaL_unref(_luaState, LUA_REGISTRYINDEX, _chunk)
			EndIf
			If _objMetaTable <> 0
				luaL_unref(_luaState, LUA_REGISTRYINDEX, _objMetaTable)
			EndIf

			lua_close(_luaState)

			_luaState = Null
		endif
		TLogger.Log("TLuaEngine", "CleanupLuaInstance: Cleaned up lua state and references closed.", LOG_DEBUG)
	End Method


	Method BlackListFunctions()
		For Local entry:String = EachIn _blacklistedFunctions
			lua_pushnil(_luaState)
			lua_setglobal(_luaState, entry)
		Next
	EndMethod


	'set and activate a lua source code file
	Method SetSourceFile:Int(sourceFile:String)
		If FileType(sourceFile) <> FILETYPE_FILE
			TLogger.Log("TLuaEngine.SetSourceFile()", "Lua source file ~q"+sourceFile+"~q not found.", LOG_ERROR)
			Return False
		EndIf

		' prepend URI as CURRENT_WORKING_DIR global
		' this is required as we do not load the lua as file
		' but the content of the file (so no file-uri information
		' available for the lua instance)
		_currentWorkingDirectory = ExtractDir(sourceFile)
		_sourceFile = sourceFile

		'prepend cwd as a single line so error offsets are -1
		'Local cwdLine:String = "--" + _currentWorkingDirectory + "       ; CURRENT_WORKING_DIR = ~q" + _currentWorkingDirectory + "~q; " + "package.path = CURRENT_WORKING_DIR .. '/?.lua;' .. package.path .. ';'~n"
		Local cwdLine:String = "CURRENT_WORKING_DIR = ~q" + _currentWorkingDirectory + "~q; " + "package.path = CURRENT_WORKING_DIR .. '/?.lua;' .. package.path .. ';'~n"
		_SetSource(cwdLine + LoadText(sourceFile))
	End Method


	Method SetSource(source:String)
		_currentWorkingDirectory = ""
		_sourceFile = ""

		_SetSource(source)
	End Method


	Method _SetSource(source:String)
		_source = source

		' Remove previously pre-compiled source
		If _chunk
			luaL_unref(_luaState, LUA_REGISTRYINDEX, _chunk)
			_chunk = 0
		EndIf

		' Compile the source code into a chunk
		If luaL_loadstring(_luaState, source) <> 0
			Local errorMessage:String = String.FromCString(lua_tostring(_luaState, -1))
			lua_pop(_luaState, 1)
			TLogger.Log("TLuaEngine.SetSource()", "Failed to compile Lua source: " + errorMessage, LOG_ERROR)
		EndIf

		' Store the compiled chunk in the registry
		_chunk = luaL_ref(_luaState, LUA_REGISTRYINDEX)
	End Method	
	
	
	Method Start()
		If _chunk = 0
			TLogger.Log("TLuaEngine.Start()", "No compiled chunk to execute. Forgot to call SetSource() ?", LOG_ERROR)
		EndIf

		' Push the compiled chunk onto the stack and execute it
		lua_rawgeti(_luaState, LUA_REGISTRYINDEX, _chunk)
	
		If lua_pcall(_luaState, 0, 0, 0) <> 0
			Local errMsg:String = String.FromCString(lua_tostring(_luaState, -1))
			lua_pop(_luaState, 1)
			TLogger.Log("TLuaEngine.Start()", "Failed to execute Lua chunk: " + errMsg, LOG_ERROR)
		EndIf
	End Method

	
	Method DumpError(errorType:String = "Error")
		Local error:String = lua_tobbstring(_luaState, -1)
		' remove error from stack
		lua_pop(_luaState, 1)

		Local split:String[] = error.split("~nstack traceback:~n")
		Local errorMessage:String = split[0]
		Local errorBacktraceLines:String[]
		if split.length > 1 then errorBacktraceLines = split[1].split("~n")
		
		TLogger.Log("TLuaEngine", "#### " + errorType + " (Engine #" + id +") #######################", LOG_ERROR)
		TLogger.Log("TLuaEngine", "Error: " + errorMessage, LOG_ERROR)
		if errorBacktraceLines.length > 0
			TLogger.Log("TLuaEngine", "Backtrace: ", LOG_ERROR)
			For local line:String = EachIn errorBacktraceLines
				Tlogger.Log("TLuaEngine", "    " + line.trim(), LOG_ERROR)
			Next
		EndIf
	End Method

	
	Function _PrintStack(luaState:Byte Ptr)
		Local stack_before:Int = lua_gettop(luaState)
		print("Stack size: " + stack_before)
		''Print stack contents for debug (top 2 elements)
		for Local i:Int = stack_before until 0 step -1
			Local t:Int = lua_type(luaState, i)
			print("  Stack element " + i + " :" + luaL_typename(luaState, i))
			if t = LUA_TSTRING
				print("    Value: " + lua_tostring(luaState, i))
			EndIf
		Next
	End Function

	Method _PrintStack()
		_PrintStack(_luaState)
	End Method
	
	
	Method _GetReflectionType:TLuaReflectionType(obj:Object)
		If Not _reflectionTypesCache Then _reflectionTypesCache = New TTreeMap<byte ptr, TLuaReflectionType>

		Local class:Byte Ptr = Luaengine_bbRefGetObjectClass( obj )
		Local reflectionType:TLuaReflectionType = _reflectionTypesCache[class]
		If not reflectionType 'not cached yet
			reflectionType = New TLuaReflectionType
			_reflectionTypesCache.Put(class, reflectionType)

			reflectionType.typeID = TTypeID.ForObject(obj)
			If reflectionType.typeID
				Local typeID:TTypeID = reflectionType.typeID

				'methods, fields and functions cannot share names
				'except for overloads (for now we do not handle that)

				'parents can define things too ... so we build up a
				'list of functions, methods, fields and constants the parents
				'(and their parents) offer
				Local currentTypeID:TTypeID = typeID
				Local types:TTypeID[]
				Repeat
					types = [currentTypeID] + types
					currentTypeID = currentTypeID.SuperType()
				Until Not currentTypeID.SuperType()
				
				For currentTypeID = EachIn types
					Local typeName:String = currentTypeID.name()
					Local whiteListedType:Int = _whiteListedTypes.Contains(typeName)
					Local exposeType:String
					if not whiteListedType
						exposeType = currentTypeID.MetaData("_exposeToLua")
						'whitelist the type if set to expose everything not just
						'"selected"
						if exposeType <> "selected"
							_whiteListedTypes.Insert(typeName, "" )
						endif
					endif

					For local list:TList = EachIn [currentTypeID.Functions(), currentTypeID.Methods(), currentTypeID.Fields(), currentTypeID.Constants()]
						For Local m:TMember = EachIn list
							'only add non-private etc.
							If m.HasMetaData("_private") or (exposeType = "selected" And Not m.MetaData("_exposeToLua"))
								continue
							EndIf

							Local c:TLuaReflectionChild = New TLuaReflectionChild
							c.member = m
							
							If TFunction(m)
								c._ref = TFunction(m)._ref 
							ElseIf TMethod(m)
								c._ref = TMethod(m)._ref 
							ElseIf TGlobal(m)
								c._ref = TGlobal(m)._ref 
							EndIf
							reflectionType.children.Put(m.Name().ToCString(), c)
						Next
					Next
				Next
			EndIf
		EndIf
		Return reflectionType
	End Method
	
	
	Method _FindTypeChild:TLuaReflectionChild(obj:Object, identPtr:Byte Ptr)
		Return TLuaReflectionChild(_GetReflectionType(obj).children[identPtr])
	End Method


	Method _FindType:TTypeId(obj:Object)
		Return _GetReflectionType(obj).typeID
	End Method
	
	
	'=== LUA BLITZMAX COUPLING ===
	
	Function _HandleIndex:Int(luaState:Byte Ptr)
		' called as soon as Lua requests a property or method of an object
		' which it does not know about (ex. "myobject:themethod()"
		Local engine:TLuaEngine = TLuaEngine.FindEngine(luaState)
		If Not engine Then return 0 '0 = no results pushed on stack / nothing done

		' Defer to engine instance method
		' Leave the result on the stack (or nil if not found)
		Return engine.HandleIndex()
	End Function


	Function _HandleSuper:Int(luaState:Byte Ptr)
		' called as soon as Lua requests a property or method of an object
		' which it does not know about (ex. "myobject:themethod()"
		Local engine:TLuaEngine = TLuaEngine.FindEngine(luaState)

		' Lua will push nil if the global table doesn't resolve the key
		' Leave the result on the stack (or nil if not found)
		Return 0
	End Function


	Function _HandleNewIndex:Int(luaState:Byte Ptr)
		' called as soon as Lua wants to write to a field of an object
		Local engine:TLuaEngine = TLuaEngine.FindEngine(luaState)
		If Not engine Then Return 0 'nothing pushed to the stack

		' Defer to engine instance method
		' Leave the result on the stack (or nil if not found)
		Return engine.HandleNewIndex()
	End Function


	Function _HandleInvoke:Int(luaState:Byte Ptr)
		' called as soon as Lua wants to call a blitzmax method/function
		Local engine:TLuaEngine = FindEngine(luaState)
		If Not engine Then Return 0 'nothing pushed to the stack

		Return engine.HandleInvoke()
	End Function


	Function _HandleEQ:Int(luaState:Byte Ptr)
		' called as soon as Lua wants to compare two (blitzmax) objects
		Local engine:TLuaEngine = TLuaEngine.FindEngine(luaState)
		If Not engine Then Return 0 'nothing pushed to the stack

		Return engine.HandleEQ()
	End Function


	'Implementation with the engine as context
	
	Method HandleIndex:Int()
		'pull blitzmax object (parent of the method)
		Local obj:Object = lua_unboxobject(_luaState, 1, _objMetaTable)
		'Local identHash:UInt = lua_LowerStringHash(_luaState, 2)

		'do not free the identPtr, it is managed by Lua!
		Local identPtrLength:Size_T
		Local identPtr:Byte Ptr = lua_tolstring(_luaState, 2, Varptr identPtrLength)
		If (identPtr = Null or identPtrLength = 0) Then Return 0

		' Check if the object was valid before proceeding
		If Not obj
			' Log error if the object is invalid
			Local ident:String = lua_tostring(_luaState, 2)
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Attempted to access ~q"+ident+"~q (method or property) of an invalid object. Object not exposed? Object name wrong? Lua is case-sensitive!", LOG_ERROR)
			Return 0 'nothing pushed on the stack
		EndIf
		'lua_tostring should be enough for idents (no utf8 methods/field names) 
		'while lua_tobbstring would decode utf8 etc 

		Local child:TLuaReflectionChild = _FindTypeChild(obj, identPtr)
		if child
			'=== CHECK PUSHED OBJECT IS A METHOD or FUNCTION ===
			'thing we have to push is a method/function
			If TMethod(child.member) or TFunction(child.member)
				lua_pushvalue(_luaState, 1)
				lua_pushlightobject(_luaState, child)
				lua_pushcclosure(_luaState, _HandleInvoke, 2)

				Return 1 'pushed 1 element (the closure) to the stack
			EndIf

			'===== CHECK PUSHED OBJECT IS A FIELD / CONSTANT =====
			If TField(child.member)
				Local fld:TField = TField(child.member)
				Select fld.TypeId()
					Case IntTypeId, ShortTypeId, ByteTypeId
						lua_pushinteger(_luaState, fld.GetInt(obj))
					Case LongTypeId
						lua_pushnumber(_luaState, fld.GetLong(obj))
					Case FloatTypeId
						lua_pushnumber(_luaState, fld.GetFloat(obj))
					Case DoubleTypeId
						lua_pushnumber(_luaState, fld.GetDouble(obj))
					Case StringTypeId
						lua_pushbbstring(_luaState, fld.GetString(obj))
					Case ArrayTypeId
						lua_pusharray(_luaState, fld.Get(obj), _objMetaTable)
					Default
						If fld.TypeId() And fld.TypeID().ExtendsType(ArrayTypeId)
							lua_pusharray(_luaState, fld.Get(obj), _objMetaTable)
						Else
							lua_pushobject(_luaState, fld.Get(obj), _objMetaTable)
						EndIf
				End Select
				Return 1 'pushed 1 element to the stack
			EndIf


			'===== CHECK PUSHED OBJECT IS A CONSTANT =====
			If TConstant(child.member)
				Local constant:TConstant = TConstant(child.member)

				Select constant.TypeId() ' BaH - added more types
					Case IntTypeId, ShortTypeId, ByteTypeId
						lua_pushinteger(_luaState, constant.GetInt())
					Case LongTypeId
						lua_pushnumber(_luaState, constant.GetLong())
					Case FloatTypeId
						lua_pushnumber(_luaState, constant.GetFloat())
					Case DoubleTypeId
						lua_pushnumber(_luaState, constant.GetDouble())
					Case StringTypeId
						lua_pushbbstring(_luaState, constant.GetString())
				End Select
				Return 1 'pushed 1 element to the stack
			EndIf
		EndIf

		local objTypeId:TTypeID = _FindType(obj)
		Local ident:String = lua_tostring(_luaState, 2)
		TLogger.Log("TLuaEngine", "[Engine " + id + "] Object ~q" + objTypeId.name() + "~q does not have or expose property ~q" + ident + "~q. Access Failed.", LOG_ERROR)
		Return 1 'nothing pushed to the stack
	End Method



	Method HandleNewIndex:Int( )
		'pull blitzmax object (parent of the field/property)
		Local obj:Object = lua_unboxobject(_luaState, 1, _objMetaTable)
		'Local identHash:UInt = lua_LowerStringHash(_luaState, 2)

		'do not free the identPtr, it is managed by Lua!
		Local identPtrLength:Size_T
		Local identPtr:Byte Ptr = lua_tolstring(_luaState, 2, Varptr identPtrLength)
		If (identPtr = Null or identPtrLength = 0) Then Return 0

		Local passedArgumentCount:Int = lua_gettop(_luaState)

		'=== CHECK OBJ / PROPERTY AND PRIVACY ===

		' Check if the object was valid before proceeding
		If Not obj
			' remove unprocessed arguments
			lua_pop(_luaState, passedArgumentCount)
			' Log error if the object is invalid
			Local ident:String = lua_tostring(_luaState, 2)
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Attempted to set field ~q"+ident+"~q of an invalid object.", LOG_ERROR)
			Return 0 'nothing pushed to the stack
		EndIf

		Local child:TLuaReflectionChild = _FindTypeChild(obj, identPtr)
		If not child
			Local t:TTypeID = _FindType(obj)
			If not t
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Type " + t.name() + " not exposed to Lua.", LOG_ERROR)
			Else
				Local ident:String = lua_tostring(_luaState, 2)
				TLogger.Log("TLuaEngine", "[Engine " + id + "] Attempted to set not exposed field ~q"+t.name()+"."+ident+"~q.", LOG_ERROR)
			EndIf
			Return 0 'nothing pushed to the stack
		EndIf

		Local fld:TField=TField(child.member)
		If Not fld
			' remove unprocessed arguments
			lua_pop(_luaState, passedArgumentCount)
			Local ident:String = lua_tostring(_luaState, 2)
			TLogger.Log("TLuaEngine", "[Engine " + id + "] reflection cache incorrect. Member is not a TField: ~q"+ident+"~q.", LOG_ERROR)
			Return 0 'nothing pushed to the stack
		EndIf
		
		
		'=== SET FIELD VALUE ===
		'PRIVATE...do not allow write to  private functions/methods
		'set to null ?
		If lua_isnil(_luaState, 3)
			Select fld.TypeId()
				Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId, FloatTypeId, DoubleTypeId, ULongTypeId, UIntTypeId, SizetTypeId
					fld.SetByte(obj, 0:Byte)
				Case StringTypeId
					fld.SetString(obj, "")
				Default
					fld.SetObject(obj, null)
			End Select
		Else
			Select fld.TypeId()
				Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId, FloatTypeId, DoubleTypeId, ULongTypeId, UIntTypeId, SizetTypeId
					fld.Set(obj, lua_tonumber(_luaState, 3))
				Case StringTypeId
					fld.Set(obj, lua_tobbstring(_luaState, 3))
				Default
					fld.Set(obj, lua_unboxobject(_luaState, 3, _objMetaTable))
			End Select
		EndIf

		Return 1 'pushed 1 element to the stack
	End Method



	Method HandleInvoke:Int()
		Local obj:Object = lua_unboxobject(_luaState, LUA_GLOBALSINDEX - 1, _objMetaTable)
		Local passedArgumentCount:Int = lua_gettop(_luaState)

		' Check if the object is still valid
		If Not obj
			' remove unprocessed arguments
			lua_pop(_luaState, passedArgumentCount)
			TLogger.Log("TLuaEngine", "[Engine " + id + "] Attempted to call method or read a property of an invalid object. Object garbage collected?", LOG_ERROR)

			Return 0 'nothing pushed to the stack
		EndIf
		
		Local objType:TTypeID
		Local child:TLuaReflectionChild = TLuaReflectionChild(lua_tolightobject(_luaState, LUA_GLOBALSINDEX - 2))

		If Not TFunction(child.member) And Not TMethod(child.member) 
			TLogger.Log("LuaEngine", "[Engine " + id + "] _Invoke() calling failed. No function/method given.", LOG_ERROR)
			Return 0 'nothing pushed to the stack
		EndIf
		If Not obj 
			TLogger.Log("LuaEngine", "[Engine " + id + "] _Invoke() calling ~q" + child.member.name() + "()~q failed. No or invalid parent given.", LOG_ERROR)
			Return 0 'nothing pushed to the stack
		EndIf

		Local func:TFunction = TFunction(child.member)
		Local mth:TMethod = TMethod(child.member)
		Local argTypes:TTypeId[]
		If mth 
			argTypes = mth.ArgTypes()
		ElseIf func
			argTypes = func.ArgTypes()
		EndIf

		'Reflection cannot handle "defaults", so all Lua calls need pass
		'all arguments defined in the function or method
		'ex. Function X:Int(a:int = 1, b:int = 2) still requires 2 passed
		'    arguments 
		'+1 arguments passed:  it might be a lua  method call
		'                      (with the first argument being the 
		'                       instance -> "obj").
		'exact argument count: might still be a lua method call with one
		'                      argument missing!
		'less arguments or more than +2: incorrect usage

		'Called as method or function?
		'-----------------------------
		'ignore first parameter?
		'(in case of calling from Lua as "method": TVT:GetXYZ() the first
		' parameter will be the "TVT" instance)
		Local isLuaMethodCall:Int = False
		if passedArgumentCount > 0
			'this is not needed, as unboxing already handles null object stuff
			rem
			local paramObj:object
			if lua_isnil(_luaState, 1)
				paramObj = null
			elseif lua_isuserdata(_luaState, 1)
				paramObj = lua_unboxobject(_luaState, 1, _objMetaTable)
			EndIf
			endrem
			local paramObj:object = lua_unboxobject(_luaState, 1, _objMetaTable)
		
			'first passed parameter is the same as the parent of the called
			'method/function? Might be a lua method call
			if paramObj = obj
				if passedArgumentCount = argTypes.length + 1
					isLuaMethodCall = True

				'Maybe first param was forgotten but has to be of same
				'type as instance?
				'BlitzMax: Type TTest; Method MyMethod(t:TTest)
				'Lua: TVT:MyMethod()  -> blitzmax sees "TVT" as first arg
				'                        and could think it was called as
				'                        function with "TVT" as argument
				'Lua: TVT.MyMethod()  -> blitzmax sees no argument
				'                        it could correctly fail (wrong arg amount)
				ElseIf passedArgumentCount = argTypes.length
					If not objType Then objType = _FindType(obj)
					If argTypes[0] = objType
						isLuaMethodCall = False
						TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() calling ~q" + objType.name() + "." + child.member.name() + "()~q failed. Call is ambiguous (1st argument same type as instance. Either a method call or a function call with missing 1st parameter. Handled as Lua.Function() call.", LOG_DEBUG)
					EndIf
				EndIf
			EndIf
		Endif
		if isLuaMethodCall then passedArgumentCount :- 1
		

		If passedArgumentCount <> argTypes.length
			If not objType Then objType = _FindType(obj)
			TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() calling ~q" + objType.name() + "." + child.member.name() + "()~q failed. " + passedArgumentCount + " argument(s) passed but " + argTypes.length+" argument(s) required.", LOG_ERROR)
			Return 0 'nothing pushed to the stack
		EndIf

		'ignore first param for lua method calls
		Local luaArgsOffset:Int = 0
		if isLuaMethodCall then luaArgsOffset = 1

		Local invalidArgs:Int = 0

		child.ArgReset()
		If argTypes.length > 0
			For Local i:Int = 0 Until argTypes.length
				Local luaIndex:Int = i + luaArgsOffset + 1  ' Precompute Lua stack index

				Select argTypes[i]
					Case IntTypeId, ShortTypeId, ByteTypeId
						if lua_isboolean(_luaState, luaIndex)
							child.ArgPush(i, int(lua_toboolean(_luaState, luaIndex)))
						else
							?ptr64
								child.ArgPush(i, Long(lua_tointeger(_luaState, luaIndex)))
							?Not ptr64
								child.ArgPush(i, Int(lua_tointeger(_luaState, luaIndex)))
							?
						endif
					Case LongTypeId
						if lua_isboolean(_luaState, luaIndex)
							child.ArgPush(i, Int(lua_toboolean(_luaState, luaIndex)))
						else
							child.ArgPush(i, Long(lua_tonumber(_luaState, luaIndex)))
						endif
					Case FloatTypeId
						child.ArgPush(i, Float(lua_tonumber(_luaState, luaIndex)))
					Case DoubleTypeId
						child.ArgPush(i, Double(lua_tonumber(_luaState, luaIndex)))
					Case StringTypeId
						child.ArgPush(i, lua_tobbstring(_luaState, luaIndex))
					Default
						If lua_isnil(_luaState, luaIndex)
							child.ArgPush(i, Null, Null)
						Else
							Local paramObj:object = lua_unboxobject(_luaState, luaIndex, _objMetaTable)
							If paramObj
								Local paramObjType:TTypeID = _FindType(paramObj)
								
								'valid param type ?
								If paramObjType or paramObjType.ExtendsType(argTypes[i])
									child.ArgPush(i, paramObj, paramObjType)
								'given param does not derive from requested param type (so incompatible)
								Else
									If not objType Then objType = _FindType(obj)
									TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() ~q" + objType.name() + "." + child.member.name()+"()~q - param #"+i+" is invalid (expected ~q"+argTypes[i].name()+"~q, received incompatible ~q"+TTypeID.ForObject(paramObj).name()+"~q).", LOG_DEBUG)
									invalidArgs :+ 1
									child.ArgPush(i, Null, argTypes[i])
								EndIf
							' passed a non-obj
							Else
								If not objType Then objType = _FindType(obj)
								TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() ~q" + objType.name() + "." + child.member.name()+"()~q - param #"+i+" is invalid (expected ~q"+argTypes[i].name()+"~q, received no userdata obj).", LOG_DEBUG)
								invalidArgs :+ 1
								child.ArgPush(i, Null, argTypes[i])
							EndIf
						EndIf
				End Select
			Next

			'stop execution if an argument did not fit
			if invalidArgs > 0
				If not objType Then objType = _FindType(obj)
				TLogger.Log("TLuaEngine", "[Engine " + id + "] _Invoke() failed to call ~q" + objType.name() + "." + child.member.name() + "()~q. " + invalidArgs + " invalid argument(s) passed.", LOG_ERROR)
				Return 0 'nothing pushed to the stack
			EndIf
		EndIf

		Local result:Int
		If func
			result = TLuaReflectionChild._CallFunction(func.FunctionPtr(), func.TypeID().ReturnType(), child._args, argTypes.length, _luaState, _objMetaTable)
			child.ArgReset() 'remove potential refs
		ElseIf mth
			result = TLuaReflectionChild._CallMethod(mth.FunctionPtr(), mth.TypeID().ReturnType(), obj, child._args, argTypes.length, _luaState, _objMetaTable)
			child.ArgReset() 'remove potential refs
		EndIf
		If result
			'TODO: if we allow to return multiple elements, "result" must become a struct...
			Return 1 'pushed 1 element to the stack
		Else
			Return 0 'pushed nothing to the stack
		EndIf
	End Method


	Method HandleEQ:Int()
		Local obj1:Object, obj2:Object

		If Not lua_isnil(_luaState, -1)
			obj1 = lua_unboxobject(_luaState, -1, _objMetaTable)
		EndIf
		If Not lua_isnil(_luaState, 1)
			obj2 = lua_unboxobject(_luaState, 1, _objMetaTable)
		EndIf

		lua_pushboolean(_luaState, obj1 = obj2)

		Return 1 'pushed 1 element to the steck
	End Method


	Method CallLuaFunction:Object(name:String, args:Object[] = Null)
		' Try fetching the function from the global environment first
		' (this avoids "super/self" lookups for functions defined in Lua
		lua_getglobal(_luaState, name)
    
		' If the function isn't in the global environment, check the fenv
		If Not lua_isfunction(_luaState, -1)
			lua_pop(_luaState, 1)  ' Remove non-function value
		
			lua_rawgeti(_luaState, LUA_REGISTRYINDEX, _functionEnvironmentRef)
			lua_getfield(_luaState, -1, name)

			' Function not found in either the global environment or fenv
			If Not lua_isfunction(_luaState, -1)
				lua_pop(_luaState, 1)  ' Remove non-function

				TLogger.Log("TLuaEngine", "[Engine " + id + "] CallLuaFunction(~q" + name + "~q) failed. Unknown function.", LOG_DEBUG)
				Return Null
			EndIf
		EndIf

		Local argCount:Int = 0
		If args
			argCount = args.length

			For Local i:Int = 0 Until args.length
				Local typeId:TTypeId = _FindType(args[i])

'TODO: "args:object[]" sollte primitive wrappen, damit sie als primitive
'      rausgesendet werden, sonst landen sie immer als "strings" im lua

				Select typeId
					Case IntTypeId, ShortTypeId, ByteTypeId
						lua_pushinteger(_luaState, args[i].ToString().ToInt())
					Case LongTypeId
						lua_pushnumber(_luaState, args[i].ToString().ToLong())
					Case FloatTypeId
						lua_pushnumber(_luaState, args[i].ToString().ToFloat())
					Case DoubleTypeId
						lua_pushnumber(_luaState, args[i].ToString().ToDouble())
					Case StringTypeId
						Local s:String = args[i].ToString()
						lua_pushbbstring(_luaState, s)
					Case ArrayTypeId
						Self.lua_pushArray(_luaState, args[i], _objMetaTable)
					Default
						If typeId And typeId.ExtendsType(ArrayTypeId)
							Self.lua_pushArray(_luaState, args[i], _objMetaTable)
						Else
							Self.lua_pushObject(_luaState, args[i], _objMetaTable)
						EndIf
				End Select
			Next
		EndIf



		' (try to) call the function
		' protected call without custom traceback handler
		Local callResult:Int = lua_pcall(_luaState, argCount, 1, 0)

		' The function executed successfully, fetch the result if any
		If callResult = 0

			Local ret:Object
			If Not lua_isnil(_luaState, -1)
				ret = lua_tobbstring(_luaState, -1)
			End If

			' Remove the result from the stack
			lua_pop(_luaState, 1)

			Return ret

		' An error occurred, fetch and print the traceback
		Else
			' Clean up the stack (if error occurs)
			'lua_pop(_luaState, 1)  ' Pop the error message
   			'TODO print error
   			DumpError("CallLuaFunc-Error")
		EndIf
	End Method


	Method CallLuaFunction:Object(name:String, luaCallArguments:SLuaCallArguments var)
		' Try fetching the function from the global environment first
		' (this avoids "super/self" lookups for functions defined in Lua
		lua_getglobal(_luaState, name)
    
		' If the function isn't in the global environment, check the fenv
		If Not lua_isfunction(_luaState, -1)
			lua_pop(_luaState, 1)  ' Remove non-function value
		
			lua_rawgeti(_luaState, LUA_REGISTRYINDEX, _functionEnvironmentRef)
			lua_getfield(_luaState, -1, name)

			' Function not found in either the global environment or fenv
			If Not lua_isfunction(_luaState, -1)
				lua_pop(_luaState, 1)  ' Remove non-function

				TLogger.Log("TLuaEngine", "[Engine " + id + "] CallLuaFunction(~q" + name + "~q) failed. Unknown function.", LOG_DEBUG)
				Return Null
			EndIf
		EndIf

		Local argCount:Int = luaCallArguments.length
		'send all defined arguments to lua
		luaCallArguments.PushArgs(_luaState, _objMetaTable)

		' (try to) call the function
		' protected call without custom traceback handler
		Local callResult:Int = lua_pcall(_luaState, argCount, 1, 0)

		' The function executed successfully, fetch the result if any
		If callResult = 0

			Local ret:Object
			If Not lua_isnil(_luaState, -1)
				ret = lua_tobbstring(_luaState, -1)
			End If

			' Remove the result from the stack
			lua_pop(_luaState, 1)

			Return ret

		' An error occurred, fetch and print the traceback
		Else
			' Clean up the stack (if error occurs)
			'lua_pop(_luaState, 1)  ' Pop the error message
   			'TODO print error
   			DumpError("CallLuaFunc-Error")
		EndIf
	End Method


	'=== CUSTOM LUA FUNCTIONS ===

	' accesses the instance specific objMetaTable reference
	' so must be a method (we manage created meta tables...)
	Function lua_pushobject:Int(luaState:Byte Ptr, obj:Object, metaTable:Int)
		' convert BlitzMax "null"-objects to lua compatible "nil" values
		If obj = Null
			lua_pushnil(luaState)
		Else
			' Box and push the object onto the Lua stack
			lua_boxobject(luaState, obj, metaTable)
		EndIf

		
		Return 0 'lua_gettop(luaState)  ' Return the current top of the stack (optional)
	End Function


	' create a table and load with array contents
	' it requires the meta table to use for objects
	Function lua_pusharray:Int(luaState:Byte Ptr, arr:Object, _objMetaTable:Int, typeID:TTypeID = Null)
		If Not typeId Then typeId = TTypeId.ForObject(arr)
		' for "Null[]" the function ArrayLength(obj) fails with
		' "TypeID is not an array type"
		If typeId.Name() = "Null[]"
			lua_newtable(luaState)
			Return 0
		EndIf

		Local size:Int = typeId.ArrayLength(arr)

		' create and push a new table to Lua
		lua_createtable(luaState, size + 1, 0)


		' Determine the element type and populate the table
		Select typeId.ElementType()
			Case IntTypeId, ShortTypeId, ByteTypeId
				For Local i:Int = 0 Until size
					' the index +1 as lua is not zerobased
					lua_pushinteger(luaState, i + 1)
					lua_pushinteger(luaState, typeId.GetArrayElement(arr, i).ToString().ToInt())
					' Set the key-value pair in the table
					lua_settable(luaState, -3) ' Pops the key and value, sets arr[i+1] = value
				Next
			Case FloatTypeId
				For Local i:Int = 0 Until size
					lua_pushinteger(luaState, i + 1)
					lua_pushnumber(luaState, typeId.GetArrayElement(arr, i).ToString().ToFloat())
					lua_settable(luaState, -3)
				Next
			Case DoubleTypeId, LongTypeId
				For Local i:Int = 0 Until size
					lua_pushinteger(luaState, i + 1)
					lua_pushnumber(luaState, typeId.GetArrayElement(arr, i).ToString().ToDouble())
					lua_settable(luaState, -3)
				Next
			Case StringTypeId
				For Local i:Int = 0 Until size
					lua_pushinteger(luaState, i + 1)
					Local s:String = typeId.GetArrayElement(arr, i).ToString()
					lua_pushlstring(luaState, s, s.Length)
					lua_settable(luaState, -3)
				Next
			Case ArrayTypeId
				For Local i:Int = 0 Until size
					lua_pushinteger(luaState, i + 1)
					Self.lua_pusharray(luaState, typeId.GetArrayElement(arr, i), _objMetaTable)
					lua_settable(luaState, -3)
				Next
			Default
				' For custom objects or other data types
				If typeId And typeId.ElementType().ExtendsType(ArrayTypeId)
					For Local i:Int = 0 Until size
						lua_pushinteger(luaState, i + 1)
						Self.lua_pusharray(luaState, typeId.GetArrayElement(arr, i), _objMetaTable)
						lua_settable(luaState, -3)
					Next
				Else
					For Local i:Int = 0 Until size
						lua_pushinteger(luaState, i + 1)
						Self.lua_pushobject(luaState, typeId.GetArrayElement(arr, i), _objMetaTable)
						lua_settable(luaState, -3)
					Next
				EndIf
		End Select
	End Function


	'=== REGISTER functions ===
	'make available BlitzMax stuff to Lua


	'Once registered, the object can be accessed from within Lua scripts
	'using the @ObjName identifer.
	Method RegisterObject(name:String, Obj:Object)
		'attention: use lua_pushobject so obj usage gets "marked" (GC)
		'and also our meta table is used
		lua_pushobject(_luaState, obj, self._objMetaTable)
		lua_setglobal(_luaState, name)
	End Method


	Method RegisterInt(name:String, value:Int)
		lua_pushinteger(_luaState, value)
		lua_setglobal(_luaState, name)
	End Method


	Method RegisterString(name:String, value:String)
		'attention: use pushbbstring so string usage gets "marked" (GC)
		lua_pushbbstring(_luaState, value)
		lua_setglobal(_luaState, name)
	End Method


	Method RegisterFloat(name:String, value:Float)
		lua_pushnumber(_luaState, value)
		lua_setglobal(_luaState, name)
	End Method


	Method RegisterFunction(name:String, value:Byte Ptr)
		' eg.  Override print with BlitzMax equivalent
		' "value" must be a function pointer to a function defined like
		' Function BlitzMaxPrintFunction:Int(luaState:Int)
		Lua_pushcfunction(_luaState, value)
		Lua_setglobal(_luaState, name)
	End Method
End Type
