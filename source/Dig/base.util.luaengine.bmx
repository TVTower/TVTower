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

	Copyright (C) 2002-2019 Ronny Otto, digidea.de

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

Rem
	===============================
	ATTENTION =====================
	===============================
	BMXNG-switch is used multiple times (ReturnType() is not the same
	compared to the call in reflectionExtended)
	-> imports
	-> _invoke()

EndRem

?Not bmxng
'using custom to have support for const/function reflection
Import "external/reflectionExtended/reflection.bmx"
'Import BRL.Reflection
?bmxng
'ng has it built-in!
Import BRL.Reflection
?
Import "base.util.logger.bmx"
'from maxlua, modified to define "THREADED"
?bmxng
Import "base.util.luaengine.c"
?Not bmxng
Import "base.util.luaengine.vanillabmx.c"
?

Extern
	Function lua_tolightobject:Object( L:Byte Ptr,index:Int )
	Function lua_unboxobject:Object( L:Byte Ptr,index:Int)
	?bmxng
	Function lua_boxobject:Int( L:Byte Ptr,obj:Object )="BBINT lua_boxobject(BBBYTE*, BBObject*)!"
	Function lua_pushlightobject:Int( L:Byte Ptr,obj:Object )="BBINT lua_pushlightobject(BBBYTE*,BBObject*)!"
	Function lua_gcobject:Int( L:Byte Ptr )="BBINT lua_gcobject(BBBYTE*)"
	?Not bmxng
	Function lua_boxobject( L:Byte Ptr,obj:Object )
	Function lua_pushlightobject( L:Byte Ptr,obj:Object )
	Function lua_gcobject:Int( L:Byte Ptr )
	?
End Extern
'end from maxlua


Type TLuaEngine
	Global list:TList = CreateList()
	Global lastID:Int = 0
	Field id:Int = 0

	'Pointer to current lua environment
	Field _luaState:Byte Ptr
	'current code
	Field _source:String = ""
	'uri / path of the code
	Field _uri:String = ""

	'reference to currently loaded code
	Field _chunk:Int = 0
	'meta table set up finished?
	Field _initDone:Int	= 0
	'for GC ... from MaxLua
	Field _objMetaTable:Int
	'we store other objects in our metatable - we are responsible for
	'them.
	'fenv should be known from Lua itself
	Field _functionEnvironmentRef:Int

	'load "all" modules or only some specific ones
	'eg. ["base","table"] or ["all"]
	Field _modulesToLoad:String[] = ["all"]
	'functions/calls getting "nil"ed before the script is run
	'eg. ["os"]
	Field _blacklistedFunctions:String[]

	'which elements can get read without "_exposeToLua" metadata?
	Field whiteListedTypes:TList = CreateList()
	Field whiteListCreated:Int = False


	Function Create:TLuaEngine(source:String, uri:String="")
		Local obj:TLuaEngine = New TLuaEngine.SetSource(source)
		obj._uri = uri
		'add here so during "RegisterToLua" code could run already
		list.addLast(obj)

		'init fenv and register self
		obj.RegisterToLua()
		obj.lastID :+1
		obj.id = obj.lastID

		obj.GenerateWhiteList()

		Return obj
	End Function


	Method GenerateWhiteList:Int()
		If whiteListCreated Then Return True

		whiteListedTypes.AddLast("TList")
		whiteListedTypes.AddLast("TMap")

		whiteListCreated = True
		Return True
	End Method


	Method Delete()
		luaL_unref(getLuaState(), LUA_REGISTRYINDEX, _functionEnvironmentRef)
		luaL_unref(getLuaState(), LUA_REGISTRYINDEX, _chunk)
	End Method


	Function FindEngine:TLuaEngine(LuaState:Byte Ptr)
		For Local engine:TLuaEngine = EachIn TLuaEngine.list
			If engine._luaState = LuaState Then Return engine
		Next
		TLogger.Log("TLuaEngine", "FindEngine(): engine not found.", LOG_ERROR)
		Return Null
	End Function


	'register libraries to lua
	'available libs:
	'"base" = luaopen_base       "debug" = luaopen_debug
	'"io" = luaopen_io           "math" = luaopen_math
	'"os" = luaopen_os           "package" = luaopen_package
	'"string"= luaopen_string    "table" = luaopen_table
	Function RegisterLibraries:Int(lua_state:Byte Ptr, libnames:String[])
		If Not libnames Then libnames = ["all"]

		For Local lib:String = EachIn libnames
			Select lib.toLower()
				'registers all libs
				Case "all"      luaL_openlibs(lua_state)
				                Return True
				'register single libs
				Case "base"     lua_register(lua_state, lib, luaopen_base)
				Case "debug"    lua_register(lua_state, lib, luaopen_debug)
				Case "io"       lua_register(lua_state, lib, luaopen_io)
				Case "math"     lua_register(lua_state, lib, luaopen_math)
				Case "os"       lua_register(lua_state, lib, luaopen_os)
				Case "package"  lua_register(lua_state, lib, luaopen_package)
				Case "string"   lua_register(lua_state, lib, luaopen_string)
				Case "table"    lua_register(lua_state, lib, luaopen_table)
			End Select
		Next
		Return True
	End Function


	Method GetLuaState:Byte Ptr()
		If Not _luaState
			_luaState = luaL_newstate()
			RegisterLibraries(_luaState, _modulesToLoad)
		EndIf
		Return _luaState
	End Method


	Method GetSource:String()
		Return _source
	End Method


	Method SetSource:TLuaEngine(source:String, uri:String = "")
		'prepend URI as CURRENT_WORKING_DIR global
		Local cwd:String = ExtractDir(uri)
		Local cwdLua:String = ""
		If cwd
			'add a single line so error offsets are -1
			cwdLua :+ "--" + uri + "             ; CURRENT_WORKING_DIR = ~q" + cwd + "~q; " + "package.path = CURRENT_WORKING_DIR .. '/?.lua;' .. package.path .. ';'~n"
			_source = cwdLua + source
		Else
			_source = source
		EndIf
		_uri = uri


		'remove reference of old source
		If _chunk
			luaL_unref(getLuaState(), LUA_REGISTRYINDEX, _chunk)
			_chunk = 0
		EndIf

		Return Self
	End Method


	'we are parent of other registered objects
	Method RegisterToLua:Int()
		'push class block
		If Not lua_pushchunk() Then Return Null

		'set new environment for this lua state, so accesses
		'to unwanted globals gets restricted (os.***)
'		lua_setfenv( GetLuaState(), 1 )

		'create fenv table
		lua_newtable( getLuaState() )

		'save it
		lua_pushvalue(getLuaState(), -1)
		_functionEnvironmentRef	= luaL_ref(getLuaState(), LUA_REGISTRYINDEX)

		'set self/super object
		lua_pushvalue(getLuaState(), -1)
		lua_setfield(getLuaState(), -2, "self")
		lua_pushobject(Self)
		lua_setfield(getLuaState(), -2, "super")
		'set meta indices
		lua_pushcfunction(getLuaState(), IndexSelf)
		lua_setfield(getLuaState(), -2, "__index")
		lua_pushcfunction(getLuaState(), NewIndexSelf)
		lua_setfield(getLuaState(), -2, "__newindex")
		lua_pushcfunction(getLuaState(), CompareObjectsSelf)
		lua_setfield(getLuaState(), -2, "__eq")

		'BlackListLuaModules()

		'set fenv metatable
		lua_pushvalue(getLuaState(), -1)
		lua_setmetatable(getLuaState(), -2)

		'ready!
		lua_setfenv(getLuaState(), -2)
		If lua_pcall(getLuaState(), 0, 0, 0 ) Then DumpError()
	End Method


	Method BlackListFunctions()
		For Local entry:String = EachIn _blacklistedFunctions
			lua_pushnil(getLuaState())
			lua_setglobal(getLuaState(), entry)
		Next
	EndMethod


	Method DumpError()
		TLogger.Log("TLuaEngine", "#### ERROR #######################", LOG_ERROR)
		TLogger.Log("TLuaEngine", "Engine: " + id, LOG_ERROR)
		Tlogger.Log("TLuaEngine", lua_tostring( getLuaState(), -1 ), LOG_ERROR)
	End Method


	Method lua_pushChunk:Int()
		If Not _chunk
			If luaL_loadstring(getLuaState(), _source)
				DumpError()
				lua_pop(getLuaState(), 1)

				Return False
			EndIf
			_chunk=luaL_ref(getLuaState(), LUA_REGISTRYINDEX)
		EndIf
		lua_rawgeti(getLuaState(), LUA_REGISTRYINDEX, _chunk)

		Return True
	End Method


	' create a table and load with array contents
	Method lua_pushArray(obj:Object)
		Local typeId:TTypeId = TTypeId.ForObject(obj)
		'for "Null[]" the function ArrayLength(obj) fails with
		'"TypeID is not an array type"
		If typeId.Name() = "Null[]"
			lua_newtable(getLuaState())
			Return
		EndIf

		Local size:Int = typeId.ArrayLength(obj)

		lua_createtable(getLuaState(), size + 1, 0)

		'lua is not zero based as BlitzMax is... so we have to add one
		'entry at the first pos
'		lua_pushinteger(getLuaState(), 0)
'		lua_pushinteger(getLuaState(), -1)
'		lua_settable(getLuaState(), -3)


		For Local i:Int = 0 Until size
			' the index +1 as not zerobased
			lua_pushinteger(getLuaState(), i+1)
'			lua_pushinteger(getLuaState(), i)

			Select typeId.ElementType()
				Case IntTypeId, ShortTypeId, ByteTypeId
					lua_pushinteger(getLuaState(), typeId.GetArrayElement(obj, i).ToString().ToInt())
				Case FloatTypeId
					lua_pushnumber(getLuaState(), typeId.GetArrayElement(obj, i).ToString().ToFloat())
				Case DoubleTypeId, LongTypeId
					lua_pushnumber(getLuaState(), typeId.GetArrayElement(obj, i).ToString().ToDouble())
				Case StringTypeId
					Local s:String = typeId.GetArrayElement(obj, i).ToString()
					lua_pushlstring(getLuaState(), s, s.length)
				Case ArrayTypeId
					Self.lua_pushArray(typeId.GetArrayElement(obj, i))
				'for everything else, we just push the object...
				Default
					If typeId And typeId.ElementType().ExtendsType(ArrayTypeId)
						Self.lua_pushArray(typeId.GetArrayElement(obj, i))
					Else
						Self.lua_pushObject(typeId.GetArrayElement(obj, i))
					EndIf
			End Select

			lua_settable(getLuaState(), -3)
		Next
	End Method


	'calls getobjmetatable
	Method lua_pushobject(obj:Object)
		'convert BlitzMax "null"-objects to lua compatible "nil" values
		If obj = Null
			lua_pushnil(getLuaState())
		Else
			lua_boxobject(getLuaState(), obj)
			lua_rawgeti(getLuaState(), LUA_REGISTRYINDEX, getObjMetaTable())
			lua_setmetatable(getLuaState(),-2)
		EndIf
	End Method


	'===== CODE FROM MAXLUA ====
	'but added _private / _expose ... checks

	Method getObjMetaTable:Int()
		If Not _initDone
			lua_newtable(getLuaState() )
			lua_pushcfunction(getLuaState(), lua_gcobject)
			lua_setfield(getLuaState(), -2, "__gc")
			lua_pushcfunction(getLuaState(), IndexObject)
			lua_setfield(getLuaState(), -2, "__index")
			lua_pushcfunction(getLuaState(), NewIndexObject)
			lua_setfield(getLuaState(), -2, "__newindex")
			lua_pushcfunction(getLuaState(), CompareObjectsObject)
			lua_setfield(getLuaState(), -2, "__eq")
			_objMetaTable = luaL_ref(getLuaState(), LUA_REGISTRYINDEX)

			_initDone = True
		EndIf
		Return _objMetaTable
	End Method

	'adding a new method/field/func to lua
	Method Index:Int( )
		Local obj:Object = lua_unboxobject(getLuaState(), 1)
		'ignore this "TLuaEngine"-instance, it is passed if Lua scripts
		'call Lua-objects and functions ("toNumber")
		If obj = Self Then Return False

		Local typeId:TTypeId = TTypeId.ForObject(obj)
		'by default allow read access to lists/maps ?!
		Local whiteListedType:Int = whiteListedTypes.contains(typeId.name())
		Local exposeType:String
		if not whiteListedType
			exposeType = typeId.MetaData("_exposeToLua")

			'whitelist the type if set to expose everything not just
			'"selected"
			if exposeType <> "selected"
				whiteListedTypes.AddLast( typeId.name() )
			endif
		endif

		'only expose if type ("parent") is set to get exposed
		If Not whiteListedType And Not exposeType Then Return False

		'===== SKIP PRIVATE THINGS =====
		'each variable/function with an underscore is private
		'eg.: function _myPrivateFunction
		'eg.: field _myPrivateField
		'
		'but lua needs access to global: _G
		Local ident:String = lua_tostring(getLuaState(), 2)
		If ident[0] =  Asc("_") And ident <> "_G" Then Return False

		'===== CHECK PUSHED OBJECT IS A METHOD or FUNCTION =====
		Local callable:TMember = typeId.FindMethod(ident)
		If Not callable Then callable = typeId.FindFunction(ident)

		'thing we have to push is a method/function
		If callable
			'PRIVATE...do not add private functions/methods
			If callable.MetaData("_private")
				If TMethod(callable)
					TLogger.Log("TLuaEngine", "Object "+typeId.name()+" does not expose method ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Else
					TLogger.Log("TLuaEngine", "Object "+typeId.name()+" does not expose function ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				EndIf
				Return False
			EndIf
			'only expose the children with explicit mention
			If exposeType = "selected" And Not callable.MetaData("_exposeToLua")
				If TMethod(callable)
					TLogger.Log("TLuaEngine", "Object "+typeId.name()+" does not expose method ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Else
					TLogger.Log("TLuaEngine", "Object "+typeId.name()+" does not expose function ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				EndIf
				Return False
			EndIf

			lua_pushvalue(getLuaState(), 1)
			lua_pushlightobject(getLuaState(), callable)
			lua_pushcclosure(getLuaState(), Invoke, 2)
			Return True
		EndIf


		'===== CHECK PUSHED OBJECT IS A CONSTANT =====
		Local _constant:TConstant = typeId.FindConstant(ident)
		If _constant
			'PRIVATE...do not add private functions/methods
			If _constant.MetaData("_private")
				TLogger.Log("TLuaEngine", "Object "+typeId.name()+" does not expose constant ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Return False
			EndIf
			'only expose the children with explicit mention
			If exposeType = "selected" And Not _constant.MetaData("_exposeToLua")
				TLogger.Log("TLuaEngine", "Object "+typeId.name()+" does not expose constant ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Return False
			EndIf

			Select _constant.TypeId() ' BaH - added more types
				Case IntTypeId, ShortTypeId, ByteTypeId
					lua_pushinteger(getLuaState(), _constant.GetInt())
				Case LongTypeId
					lua_pushnumber(getLuaState(), _constant.GetLong())
				Case FloatTypeId
					lua_pushnumber(getLuaState(), _constant.GetFloat())
				Case DoubleTypeId
					lua_pushnumber(getLuaState(), _constant.GetDouble())
				Case StringTypeId
					Local t:String = _constant.GetString()
					lua_pushlstring(getLuaState(), t, t.length)
			End Select
			Return True
		EndIf


		'===== CHECK PUSHED OBJECT IS A FIELD =====
		Local fld:TField = typeId.FindField(ident)
		If fld
			'PRIVATE...do not add private functions/methods
			'SELECTED...only expose the children with explicit mention
			If fld.MetaData("_private")
				TLogger.Log("TLuaEngine", "Object "+typeId.name()+" does not expose field ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Return False
			EndIf
			If exposeType = "selected" And Not fld.MetaData("_exposeToLua")
				TLogger.Log("TLuaEngine", "Object "+typeId.name()+" does not expose field ~q" + ident+"~q. Access Failed.", LOG_ERROR)
				Return False
			EndIf

			Select fld.TypeId() ' BaH - added more types
				Case IntTypeId, ShortTypeId, ByteTypeId
					lua_pushinteger(getLuaState(), fld.GetInt(obj))
				Case LongTypeId
					lua_pushnumber(getLuaState(), fld.GetLong(obj))
				Case FloatTypeId
					lua_pushnumber(getLuaState(), fld.GetFloat(obj))
				Case DoubleTypeId
					lua_pushnumber(getLuaState(), fld.GetDouble(obj))
				Case StringTypeId
					Local t:String = fld.GetString(obj)
					lua_pushlstring(getLuaState(), t, t.length)
				Case ArrayTypeId
					lua_pushArray(fld.Get(obj))
				Default
					If fld.TypeId() And fld.TypeID().ExtendsType(ArrayTypeId)
						lua_pushArray(fld.Get(obj))
					Else
						lua_pushobject(fld.Get(obj))
					EndIf
			End Select
			Return True
		EndIf


		TLogger.Log("TLuaEngine", "Object "+typeId.name()+" does not have a property called ~q" + ident+"~q.", LOG_ERROR)
		Return False
	End Method


	Method CompareObjects:Int()
		Local obj1:Object, obj2:Object

		If lua_isnil(getLuaState(), -1)
			TLogger.Log("TLuaEngine", "CompareObjects: param #1 is nil.", LOG_DEBUG)
		Else
			obj1 = lua_unboxobject(getLuaState(), -1)
		EndIf
		If lua_isnil(getLuaState(), 1)
			TLogger.Log("TLuaEngine", "CompareObjects: param #2 is nil.", LOG_DEBUG)
		Else
			obj2 = lua_unboxobject(getLuaState(), 1)
		EndIf

		lua_pushboolean(getLuaState(), obj1 = obj2)
'		lua_pushinteger(getLuaState(), obj1 = obj2)

		Return True
		' obj1 = obj2
	End Method


	Method NewIndex:Int( )
		Local obj:Object = lua_unboxobject(getLuaState(), 1)
		Local typeId:TTypeId = TTypeId.ForObject(obj)

		Local ident:String = lua_tostring(getLuaState(), 2)
		Local mth:TMethod = typeId.FindMethod(ident)
		If mth Then Throw "newIndex ERROR"

		'I do not know how to handle arrays properly (needs metatables
		'and custom userdata)
		If typeId.name().contains("[]")
			TLogger.Log("TLuaEngine", "Arrays are not supported - array type: " + typeId.name() + ".", LOG_ERROR)
			'array index is
			'print lua_tostring(getLuaState(), 2)
			'array value is
			'print lua_tostring(getLuaState(), 3)
			Return True
		EndIf

		'only expose if type set to get exposed
		If Not typeId.MetaData("_exposeToLua")
			TLogger.Log("TLuaEngine", "Type " + typeId.name() + " not exposed to Lua.", LOG_ERROR)
		EndIf
		Local exposeType:String = typeId.MetaData("_exposeToLua")


		Local fld:TField=typeId.FindField(ident)
		If fld
			'PRIVATE...do not allow write to  private functions/methods
			'check could be removed if performance critical
			If fld.MetaData("_private") Then Return True
			'only set values of children with explicit mention
			If exposeType = "selected" And Not fld.MetaData("_exposeToLua") Then Return True
			If fld.MetaData("_exposeToLua")<>"rw"
				TLogger.Log("TLuaEngine", "Object property "+typeId.name()+"."+ident+" is read-only.", LOG_ERROR)
				Return True
			EndIf

			If lua_isnil(getLuaState(), 3)
				?Not bmxng
				Select fld.TypeId()
					Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId, FloatTypeId, DoubleTypeId, StringTypeId
						'SetInt/SetFloat/...all convert to a string
						'"null" is 0/0.0/"" for primitive types in BlitzMax
						fld.SetString(obj, "")
					Default
						fld.Set(obj, Null)
				End Select
				?bmxng
				Select fld.TypeId()
					Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId, FloatTypeId, DoubleTypeId, ULongTypeId, UIntTypeId, SizetTypeId
						fld.SetByte(obj, 0)
					Case StringTypeId
						fld.SetString(obj, "")
					Default
						fld.SetObject(obj, null)
'						fld.Set(obj, object(null))
				End Select
				?
			Else
				Select fld.TypeId()
?Not bmxng
					Case IntTypeId, ShortTypeId, ByteTypeId
						fld.SetInt(obj, lua_tointeger(getLuaState(), 3))
					Case LongTypeId
						fld.SetLong(obj, Long(lua_tonumber(getLuaState(), 3)))
					Case FloatTypeId
						fld.SetFloat(obj, Float(lua_tonumber(getLuaState(), 3)))
					Case DoubleTypeId
						fld.SetDouble(obj, lua_tonumber(getLuaState(), 3))
					Case StringTypeId
						fld.SetString(obj, lua_tostring(getLuaState(), 3))
					Default
						fld.Set(obj, lua_unboxobject(getLuaState(), 3))
?bmxng
					Case IntTypeId, ShortTypeId, ByteTypeId, LongTypeId, FloatTypeId, DoubleTypeId, ULongTypeId, UIntTypeId, SizetTypeId
						fld.Set(obj, lua_tonumber(getLuaState(), 3))
					Case StringTypeId
						fld.Set(obj, lua_tostring(getLuaState(), 3))
					Default
						fld.Set(obj, lua_unboxobject(getLuaState(), 3))
?
				End Select
			EndIf
			Return True
		EndIf
		TLogger.Log("TLuaEngine", "newindex: ident not found " + ident + ".", LOG_ERROR)
	End Method


	'functions so we can push them to lua
	'====================================

	'they get called if a script tries to run a method/func/field
	'from a blitzmax object
	Function IndexObject:Int(fromLuaState:Byte Ptr)
		Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
		If engine And engine.Index() Then Return 1
	End Function

	Function NewIndexObject:Int(fromLuaState:Byte Ptr)
		Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
		If engine And engine.NewIndex() Then Return 1
		Throw "newindexobject ERROR"
	End Function

	Function CompareObjectsObject:Int(fromLuaState:Byte Ptr)
		Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
		If engine Then Return engine.CompareObjects()
	End Function

	Function IndexSelf:Int(fromLuaState:Byte Ptr)
		Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)

		lua_getfield(engine.getLuaState(), 1, "super")
		lua_replace(engine.getLuaState(), 1)
		If engine.Index() Then Return 1

		lua_remove(engine.getLuaState(), 1)
		lua_gettable(engine.getLuaState(), LUA_GLOBALSINDEX)
		Return 1
	End Function

	Function NewIndexSelf:Int(fromLuaState:Byte Ptr)
		'local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
		lua_rawset(fromLuaState, 1)
		Return 1
	End Function

	Function CompareObjectsSelf:Int(fromLuaState:Byte Ptr)
		Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
		Return engine.CompareObjectsObject(fromLuaState)
	End Function

	Function Invoke:Int(fromLuaState:Byte Ptr)
		Local engine:TLuaEngine = TLuaEngine.FindEngine(fromLuaState)
		Return engine._Invoke()
	End Function
	'====================================


	Method _Invoke:Int()
		Local obj:Object = lua_unboxobject(getLuaState(), LUA_GLOBALSINDEX - 1)
		Local funcOrMeth:TMember = TMember(lua_tolightobject(getLuaState(), LUA_GLOBALSINDEX - 2))
		If Not TFunction(funcOrMeth) And Not TMethod(funcOrMeth) Then Throw "LuaEngine._Invoke() failed. No function/method given."
		If Not obj Then Print "LuaEngine._Invoke() failed to run ~q"+funcOrMeth.name()+"~q. Invalid parent given."
		Local func:TFunction = TFunction(funcOrMeth)
		Local mth:TMethod = TMethod(funcOrMeth)
		Local tys:TTypeId[]

		If func Then tys = func.ArgTypes()
		If mth Then tys = mth.ArgTypes()
		Local args:Object[tys.length]

		For Local i:Int = 0 Until args.length
			Select tys[i]
				Case IntTypeId, ShortTypeId, ByteTypeId
					?bmxng
						args[i] = String.FromLong(lua_tointeger(getLuaState(), i + 1))
					?Not bmxng
						args[i] = String.FromInt(lua_tointeger(getLuaState(), i + 1))
					?
				Case LongTypeId
					args[i] = String.FromLong(Long(lua_tonumber(getLuaState(), i + 1)))
				Case FloatTypeId
					args[i] = String.FromFloat(Float(lua_tonumber(getLuaState(), i + 1)))
				Case DoubleTypeId
					args[i] = String.FromDouble(lua_tonumber(getLuaState(), i + 1))
				Case StringTypeId
					args[i] = lua_tostring(getLuaState(), i + 1)
				Default
					If lua_isnil(getLuaState(), i + 1)
						args[i] = Null
					Else
						args[i] = lua_unboxobject(getLuaState(), i + 1)
					EndIf
Rem
					if lua_isnil(getLuaState(), i + 1)
						'print "LUA: "+funcOrMeth.name()+"() got null param #"+i+"."
						args[i] = null
					elseif lua_isuserdata(getLuaState(), i + 1)
						local obj:object = lua_unboxobject(getLuaState(), i + 1)
						'given param derives from requested param type
						if TTypeID.ForObject(obj).ExtendsType(tys[i])
							args[i] = obj
						else
							print "LuaEngine._Invoke(): "+funcOrMeth.name()+"() got broken param #"+i+" (expected ~q"+tys[i].name()+"~q, got ~q"+TTypeID.ForObject(obj).name()+"~q). Falling back to ~qNull~q."
							args[i] = null
						endif
					else
						print "LuaEngine._Invoke(): "+funcOrMeth.name()+"() got broken param #"+i+" (expected ~q"+tys[i].name()+"~q). Falling back to ~qNull~q."
						args[i] = null
					endif
endrem
			End Select
		Next

		Local t:Object
		?Not bmxng
		If func Then t = func.Invoke(obj, args)
		?bmxng
		If func Then t = func.Invoke(args)
		?
		If mth Then t = mth.Invoke(obj, args)
		Local typeId:TTypeId = funcOrMeth.TypeID().ReturnType()

		If Object[](t).length > 0 Then typeId = ArrayTypeId

		Select typeId
			Case IntTypeId, ShortTypeId, ByteTypeId
				lua_pushinteger(getLuaState(), t.ToString().ToInt())
'				lua_pushnumber(getLuaState(), t.ToString().ToLong())
			Case LongTypeId
				lua_pushnumber(getLuaState(), t.ToString().ToLong())
			Case FloatTypeId
				lua_pushnumber(getLuaState(), t.ToString().ToFloat())
			Case DoubleTypeId
				lua_pushnumber(getLuaState(), t.ToString().ToDouble())
			Case StringTypeId
				Local s:String = t.ToString()
				lua_pushlstring(getLuaState(), s, s.length)
			Case ArrayTypeId
				lua_pushArray(t)
			Default
				If typeId And typeId.ExtendsType(ArrayTypeId)
					lua_pushArray(t)
				Else
					lua_pushobject(t)
				EndIf
		End Select
		Return True
	End Method

	'===== END CODE FROM MAXLUA ====


	Method CallLuaFunction:Object(name:String, args:Object[] = Null)
		'push fenv
		lua_rawgeti(getLuaState(), LUA_REGISTRYINDEX, _functionEnvironmentRef)

		lua_getfield(getLuaState(), -1, name)
		'make sure it is a function
		If Not lua_isfunction(getLuaState(), -1)
			lua_pop(getLuaState(), 1)
			Print "CallLuaFunction(~q" + name + "~q) failed. Unknown function."
'		If lua_isnil(getLuaState(), -1)
'			lua_pop(getLuaState(), 2)
			Return Null
		EndIf

		Local argCount:Int = 0
		If args
			argCount = args.length

			For Local i:Int = 0 Until args.length
				Local typeId:TTypeId = TTypeId.ForObject(args[i])
				Select typeId
					Case IntTypeId, ShortTypeId, ByteTypeId
						lua_pushinteger(getLuaState(), args[i].ToString().ToInt())
					Case LongTypeId
						lua_pushnumber(getLuaState(), args[i].ToString().ToLong())
					Case FloatTypeId
						lua_pushnumber(getLuaState(), args[i].ToString().ToFloat())
					Case DoubleTypeId
						lua_pushnumber(getLuaState(), args[i].ToString().ToDouble())
					Case StringTypeId
						Local s:String = args[i].ToString()
						lua_pushlstring(getLuaState(), s, s.length)
					Case ArrayTypeId
						Self.lua_pushArray(args[i])
					Default
						If typeId And typeId.ExtendsType(ArrayTypeId)
							Self.lua_pushArray(args[i])
						Else
							Self.lua_pushObject(args[i])
						EndIf
				End Select
			Next
		EndIf

		Local ret:Object

		'(try to) call the function
		If lua_pcall(getLuaState(), argCount, 1, 0) <> 0
			DumpError()
			lua_pop(getLuaState(), 1)
		Else
			'fetch the results
			If Not lua_isnil(getLuaState(), -1)
				ret = lua_tostring(getLuaState(), -1)
			EndIf

			'pop the returned result
			lua_pop(getLuaState(), 1)
		EndIf


		'pop the _functionEnvironmentRef ?
		lua_pop(getLuaState(), 1)

		Return ret
	End Method


	'Once registered, the object can be accessed from within Lua scripts
	'using the @ObjName identifer.
	Method RegisterBlitzmaxObject(ObjName:String, Obj:Object)
		lua_pushobject(obj)
		lua_setglobal(getLuaState(), ObjName)
	End Method


	Method RegisterInt(name:String, value:Int)
		lua_pushinteger(getLuaState(), value)
		lua_setfield(getLuaState(), LUA_GLOBALSINDEX, name)
	End Method


	Method RegisterFunction(name:String, value:Byte Ptr)
		lua_pushcclosure(getLuaState(), value, 0)
		lua_setfield(getLuaState(), LUA_GLOBALSINDEX, name)
	End Method
End Type